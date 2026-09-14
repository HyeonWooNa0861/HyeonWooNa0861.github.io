---
layout: post
title: "Neural Thickets: Dense and Diverse Experts Near Pretrained Weights"
nav_title: "Neural Thickets"
date: 2026-09-14 22:40:00 +0900
categories: [Machine Learning, Neural Networks]
tags: [Neural Thickets, RandOpt, Weight Space, Post-Training, Ensemble Learning]
permalink: /posts/neural-thickets/
section: ai-education
---

Source PDF: `Neural Thickets.pdf` (13-slide seminar deck, Yang Ji-Woong, MLPR Laboratory, Kookmin University) — locally supplied; not redistributed. Primary paper: Yulu Gan and Phillip Isola, *Neural Thickets: Diverse Task Experts Are Dense Around Pretrained Weights*, arXiv:2603.12228v1 (2026); <a href="https://arxiv.org/pdf/2603.12228v1" target="_blank" rel="noopener">read the original paper PDF</a>.

> **핵심 메시지:** 큰 사전학습 모델의 가중치 $$\theta$$ 주변에서 무작위 변동을 주면, 특정 과제의 점수를 높이는 모델이 드물지만은 않을 수 있다. 그러나 그 모델들이 **모든 과제에 동시에 강한 일반가라기보다 서로 다른 전문 모델**이라는 점이 중요하다. RandOpt는 이웃을 무작위로 탐색해 좋은 후보를 고르고 투표로 결합한다. 이 결과는 **사전학습의 가치와 선택·앙상블의 가능성**을 보여주지만, 경사 기반 학습의 불필요함이나 낮은 추론 비용을 증명하지는 않는다.

이 글은 위 13쪽 세미나 자료 전체를 읽고, 그 근거인 [Gan–Isola 원 논문](https://arxiv.org/abs/2603.12228){:target="_blank" rel="noopener"}의 정의·그림·실험 조건을 대조하여 쓴 독자적 한국어 해설이다. 원문 문장, 그림, PDF는 공개 저장소에 복제하지 않는다. 세미나 슬라이드에 없는 원 논문의 추가 결과는 별도로 표시하고, 설명을 위해 새로 든 수치 예제는 실제 실험으로 오해하지 않도록 구분한다.

## Reading Map

| Slides | Question | This article |
|---|---|---|
| 1–4 | 왜 사전학습 가중치 주변을 탐색하는가? | 1: 문제와 탐색 공간 |
| 5–6 | 작은 모델과 큰 모델의 이웃은 어떻게 다른가? | 2: 밀도 정의·측정·그림 해석 |
| 7–8 | 이웃 모델들은 일반가인가 전문 모델인가? | 3: 순위 상관과 스펙트럼 불일치 |
| 9 | 사전학습이 왜 이 구조를 만들 수 있는가? | 4: 1차원 신호 실험의 세 체제 |
| 10 | RandOpt는 무엇을 계산하는가? | 5: 무작위 후보·선택·투표 |
| 11–12 | 무엇과 어떻게 비교했는가? | 6: 실험·FLOPs·추론 비용 |
| 13 | 무엇이 결론이고 어디까지가 한계인가? | 7: 해석·한계·Source Check |

## 1. A Needle or a Thicket?

신경망의 가중치를 한 벡터 $$\theta\in\mathbb R^d$$로 모으자. 보통 downstream task에 적응하려면 이 점에서 출발해 gradient descent, PPO, GRPO 또는 Evolution Strategies(ES)처럼 **연속적인 탐색**을 한다. 아무것도 학습하지 않은 임의의 $$d$$차원 벡터를 한 번 뽑아 유용한 언어모델을 얻을 가능성이 극히 낮다는 직관은 여전히 맞다. 논문의 질문은 다른 것이다. **이미 강하게 사전학습한 $$\theta$$의 작은 이웃**에서도 같은 희소성을 가정해야 할까?

슬라이드 3의 건초더미와 덤불 그림은 이 차이를 표현한다. 작은 모델이나 미학습 모델 주변에는 과제 점수를 올리는 가중치가 희소하지만, 큰 사전학습 모델 주변에는 여러 방향으로 과제별 개선점이 있을 수 있다. 여기서 ‘dense’는 전체 $$\mathbb R^d$$의 부피에서 좋은 모델이 많다는 뜻이 아니다. **선택한 기준 모델, 잡음 분포, 잡음 크기, 과제, 점수 기준에 대한 적중 확률**이 높다는 경험적 주장이다. 그림의 공간적 비유를 수학적 보편 정리로 읽지 않아야 한다.

또한 사전학습 목표가 낮은 손실을 갖는 점과, 각 후속 과제의 정확도가 그 점에서 최대라는 것은 다르다. 여러 과제를 절충한 기준점은 한 과제만 보는 방향으로 움직이면 좋아지고 다른 과제에서는 나빠질 수 있다. 따라서 **한 개의 평균적인 기준 모델 근처에 여러 종류의 전문가가 공존한다**는 가설을 밀도와 다양성 두 축으로 검사한다.

이 글의 핵심 기호는 다음처럼 고정한다. 정확도·확률·순위·개수는 SI 물리 단위를 갖지 않는다. 가중치 좌표와 잡음의 숫자 크기는 선택한 모델의 매개변수 표현에 의존한다.

| Symbol | Meaning | Unit / domain |
|---|---|---|
| $$\theta,d$$ | 기준 매개변수 벡터, 매개변수 차원 | $$\theta\in\mathbb R^d$$; 좌표계 의존, $$d$$는 무차원 개수 |
| $$s,m$$ | 과제 점수, 절대 점수 차이 | 정확도라면 0–1의 무차원 비율 및 그 차이 |
| $$\epsilon,\sigma$$ | Gaussian 잡음 벡터, 잡음 표준편차 | $$\epsilon\in\mathbb R^d$$; $$\sigma$$는 가중치 좌표 척도 |
| $$N,K,M$$ | 평가 후보 수, 선택 후보 수, 과제 수 | 양의 정수, 무차원; $$1\le K\le N$$ |
| $$P,C$$ | 과제별 후보 percentile-rank 행렬, 그 열 상관행렬 | $$P\in[0,1]^{N\times M}$$, $$C\in[-1,1]^{M\times M}$$; 무차원 |
| $$\delta,\mathcal D$$ | 개선 후보 확률, spectral discordance | 무차원; $$0\le\delta\le1$$, $$0\le\mathcal D\le M/(M-1)$$ ($$M>1$$) |

## 2. How Dense Are Improving Solutions?

### 2.1 The probability being measured

어떤 과제의 평가 점수를 $$s(\theta)$$라 하자. 논문은 기준 가중치에 등방성 Gaussian 잡음 $$\epsilon\sim\mathcal N(0,\sigma^2 I_d)$$를 더한다. 개선 폭 $$m$$ 이상인 후보를 얻을 확률을 **solution density의 정의**로 둔다(원 논문 §2.1, 식 1; 슬라이드 6).

$$
\delta(m)=\Pr_{\epsilon\sim\mathcal N(0,\sigma^2 I_d)}\!\left[s(\theta+\epsilon)\ge s(\theta)+m\right].
$$

여기서 $$d$$는 매개변수 개수, $$I_d$$는 단위행렬, $$\sigma$$는 가중치 교란의 표준편차, $$m$$은 점수의 **절대 차이**다. 점수가 0–1 정확도라면 $$m=0.05$$는 5 **퍼센트포인트** 상승을 뜻한다. $$\sigma$$와 가중치 좌표계를 바꾸면 $$\delta$$도 달라지므로, ‘이웃에 좋은 해가 많다’는 말만으로 수치를 옮겨 쓸 수 없다. 원 논문의 밀도 실험에서는 $$\sigma=0.005$$를 사용한다.

슬라이드 6과 논문 Figure 3의 범례는 ‘기준 모델 점수의 90%, 95%, 103%’ 같은 **상대 임계치**를 쓴다. 위 정의와 연결하려면 기준 점수 $$s_0=s(\theta)$$가 주어졌을 때 $$s(\theta+\epsilon)\ge r s_0$$를 검사하는 것으로 읽고, $$m=(r-1)s_0$$라고 변환하면 된다. 기준 정확도가 60%이면 105% 임계치는 63% 정확도, 즉 3 퍼센트포인트 상승이지 105 퍼센트포인트 상승이 아니다. $$s_0=0$$인 과제에는 이런 상대 비율이 의미를 잃으므로 절대 임계치를 따로 정해야 한다.

유한한 후보 $$N$$개로 측정하는 값은 확률 자체가 아니라 **표본 비율**이다. 설명용 예로 독립 잡음 1,000개 중 200개가 임계치를 넘었다면 $$\widehat\delta=200/1000=0.20$$이다. 독립 Bernoulli 시행이라는 단순 가정에서 표준오차의 플러그인 추정치는 $$\sqrt{0.2(1-0.2)/1000}\simeq0.013$$이다. 이는 논문의 실험 수치가 아니라 ‘밀도’라는 표현을 확률로 읽기 위한 검산이다.

### 2.2 What the figures do and do not show

슬라이드 5의 정확도 지형은 원 논문 Figure 2의 Qwen2.5 계열 0.5B–32B 모델을 비교한다. 각 모델에 1,000개 교란을 주고 **무작위 2차원 투영**으로 표현했다. 색은 기준 정확도에 대한 상대 변화이고, 별은 그 표본 안의 최고 후보, 점선 원은 평균 교란 거리다. 큰 모델의 따뜻한 영역이 늘어나는 패턴은 유의미하지만, 그림의 연속된 붉은 면 전체를 실제로 평가한 것은 아니다. 투영·시각화는 고차원 전체의 매끄러운 지형이나 모든 방향의 성질을 증명하지 않는다.

슬라이드 6의 Figure 3(a)는 같은 논문의 GSM8K·Countdown에 대한 여러 임계치에서, Qwen2.5 Instruct 계열의 모델 크기가 커질수록 관측한 적중 비율이 증가하는 결과다. **관측 범위의 scaling trend**이지 모든 아키텍처·학습 단계·잡음 크기에 대한 단조 법칙은 아니다. 특히 90%나 95%처럼 기준보다 낮은 임계치를 넘는 사건과 105%처럼 실제 개선을 요구하는 사건을 구분해야 한다. ‘기준점과 비슷한 후보가 많다’는 사실만으로 ‘뚜렷하게 개선하는 후보가 많다’고 결론낼 수 없다.

## 3. Are Nearby Models Generalists or Specialists?

### 3.1 Why one-task accuracy is insufficient

한 후보가 GSM8K에서 좋아졌을 때 MATH, 코드, 화학에서도 함께 좋아진다면 **일반가 가설**에 가깝다. 반대로 수학에서는 상위권이고 코드에서는 하위권인 후보가 반복된다면 **전문화 가설**을 지지한다. 슬라이드 7의 H1/H2는 이 대비를 설명하기 위한 가설이지, 모든 개별 perturbation이 정확히 그 목록대로 변한다는 주장이 아니다.

원 논문은 $$N=500$$개의 무작위 교란을 **7개 과제·4개 영역**에서 평가한다: 수학의 Countdown, GSM8K, MATH-500, OlympiadBench; 코드의 MBPP; 글쓰기의 ROCStories; 화학의 USPTO. 각 과제에서 후보들의 성능을 percentile rank로 바꿔 $$N\times M$$ 행렬 $$P$$를 만든다. $$M=7$$은 과제 수다. 두 과제 열의 Pearson 상관 $$C_{jk}$$가 크면 후보 순위가 비슷하고, 0 부근이면 순위가 거의 무관하다. percentile rank의 Pearson 상관이므로 원점수의 크기가 아니라 **후보의 순위 구조**를 비교한다.

### 3.2 Spectral discordance and its bound

원 논문 §2.2 식 2의 **정의**는 대각 원소를 제외한 평균 상관을 1에서 뺀 것이다.

$$
\mathcal D=1-\frac{1}{M(M-1)}\sum_{j\ne k} C_{jk}.
$$

모든 과제 순위가 같으면 모든 비대각 상관이 1이므로 $$\mathcal D=0$$이다. 서로 무관하면 평균 상관이 0이어서 $$\mathcal D=1$$이다. **1이 최대값이라는 뜻은 아니다.** 상관행렬 $$C$$가 양의 준정부호이므로 $$\mathbf 1^{\top}C\mathbf 1\ge0$$이고, 대각선의 합이 $$M$$임을 이용하면

$$
0\le M+\sum_{j\ne k}C_{jk}
=M+M(M-1)\overline C,
\qquad \overline C\ge-\frac{1}{M-1}.
$$

따라서 $$0\le\mathcal D\le M/(M-1)$$이다(원 논문 Appendix H). 일곱 과제면 상한은 $$7/6\simeq1.17$$이다. 두 과제의 순위가 정반대인 경우에는 $$M=2$$이고 $$\mathcal D=2$$가 가능하다. 이 검산으로 ‘$$\mathcal D\to1$$이면 전문가’라는 슬라이드의 표현은 **무상관에 가까운 순위**를 가리키는 직관으로만 읽어야 한다. 음의 상관까지 생기면 1을 넘을 수 있다.

슬라이드 7의 Figure 3(b)는 모델 크기가 커질수록 이 측정값이 올라간 결과다. 슬라이드 8의 Figure 4(a) 왼쪽은 **그 500개 분석 전체가 아니라 예시로 그린 100개 seed**의 7과제 percentile 스펙트럼이다. 들쭉날쭉한 선은 후보마다 강점 과제가 다름을 보인다. 오른쪽은 7차원 성능 벡터를 PCA로 2차원에 나타내고 K-means로 군집을 표시한 것이다. 군집 그림은 구조를 보는 보조 증거이지, 참된 전문가 유형의 수나 인과적 생성 메커니즘을 증명하지 않는다. 슬라이드 5의 RGB 합성 역시 여러 과제의 패턴이 같은 회색으로만 보이지 않는다는 직관적 시각화다.

## 4. Why Might Pretraining Create a Thicket?

슬라이드 9와 원 논문 §3의 단순화 실험은 ‘큰 LLM만의 우연인가?’를 묻는다. MLP가 앞선 값의 짧은 문맥 $$y_{\mathrm{ctx}}$$에서 다음 값 $$y_{\mathrm{next}}$$를 예측하도록 사전학습한다. 원 논문은 사인파, 선형, harmonic, sigmoid, 톱니·사각파 등 다양한 1차원 신호를 학습 분포로 섞고, 선형 시험 신호의 이어지는 부분을 자기회귀적으로 생성한다. 이 실험의 1,000개 Gaussian 교란에는 $$\sigma=0.002$$가 쓰였다. 밀도 그래프의 $$0.005$$와 서로 다른 실험 설정이다.

세 가지 사전학습 조건을 나누면 결과의 이유가 더 잘 보인다.

| Regime | Pretraining | Observation on a linear test signal | Interpretation |
|---|---|---|---|
| Needle | 없음 | 초기점 주변 변동이 원하는 선형 연장을 잘 찾지 못함 | 좋은 표현 자체를 먼저 학습해야 함 |
| Thicket | 여러 신호 유형의 혼합 | 주변 후보가 여러 형태의 연장을 만들고, 일부가 시험 신호에 잘 맞음 | 다양하게 준비된 표현에서 선택의 여지가 생김 |
| Plateau | 선형 신호 중심 | 기준 모델이 이미 거의 맞음 | 더 나은 후보를 찾을 여지가 작음 |

이는 **통제된 toy experiment**다. 혼합 사전학습이 다양한 기능을 근처에 둘 수 있다는 설명에는 도움이 되지만, 실제 LLM에서 같은 메커니즘만 작동함을 입증하지는 않는다. 반대로 plateau는 해가 드물다는 뜻이 아니다. **기준 점수가 천장에 가까워 개선 폭 $$m>0$$을 만족시키기 어렵다**는 다른 상황이다. 따라서 $$\delta(m)$$가 낮을 때 미학습·작은 모델의 실패와 이미 충분히 잘하는 모델의 천장 효과를 혼동하면 안 된다.

## 5. RandOpt: Guess, Select, Then Vote

밀도만 높으면 좋은 후보 하나를 쉽게 얻을 수 있다. 다양성까지 있다면 후보 여러 개의 오류가 달라 **앙상블의 추가 이익**을 기대할 수 있다. RandOpt는 이 두 관찰을 이용한다(슬라이드 10; 원 논문 §4, 식 3–5).

먼저 기본 가중치 $$\theta$$와 잡음 크기 후보 집합 $$\Sigma$$를 정한다. 각 seed $$s_i$$에 표준 Gaussian 벡터 $$\epsilon(s_i)$$와 크기 $$\sigma_i\in\Sigma$$를 대응시키고 다음 후보를 **정의**한다.

$$
\theta_i=\theta+\sigma_i\epsilon(s_i),\qquad i=1,\ldots,N.
$$

여기서 seed는 거대한 가중치 벡터를 재현할 수 있는 식별자이고, $$N$$은 평가할 후보 수다. 논문의 Algorithm 1은 크기들을 후보에 배정해 각각 $$D_{\mathrm{train}}$$에서 점수 $$v_i=s_{D_{\mathrm{train}}}(\theta_i)$$를 얻은 뒤, **점수 상위 $$K$$개 후보의 index**를 선택한다.

$$
I_{\mathrm{top}}=\operatorname{TopK}_{i\in\{1,\ldots,N\}} v_i.
$$

시험 입력 $$x$$에서는 고른 $$K$$개가 각각 답을 생성하고, 분류·정수 답처럼 동일성을 비교할 수 있을 때 최빈 답을 낸다. 원 논문 식 5의 결정적 표현을 따라 쓰면

$$
\widehat y(x)=\operatorname{mode}\!\left(\left\{\operatorname*{argmax}_{y} f_{\theta_i}(y\mid x):i\in I_{\mathrm{top}}\right\}\right).
$$

이는 **각 모델의 출력에 투표**하는 것이지 $$K$$개 가중치를 평균해 한 모델로 만드는 식이 아니다. 실제 생성 설정에는 decoding과 정답 파싱 규칙이 필요하고, 동률도 결정해야 한다. 창작 글·분자 구조처럼 출력이 복잡하면 단순 문자열 다수결이 적합하지 않다. 또한 후보를 골랐던 $$D_{\mathrm{train}}$$에서 다시 평가한 점수는 일반화 증거가 아니므로, 독립 시험 집합을 분리해야 한다.

**계산의 위치**가 핵심이다. RandOpt는 후보 사이의 gradient·순차적 파라미터 갱신이 없어 개별 후보 평가를 병렬화할 수 있다. 그러나 $$N$$개 모델을 평가하는 총 연산량이 0이 되는 것은 아니다. 충분한 병렬 장치가 있어야 순차 단계 수가 $$O(1)$$인 이점이 실제 wall-clock 감소로 이어진다. 추론에서는 대체로 $$K$$개의 생성이 필요하므로 한 모델보다 계산·메모리·지연 비용이 높을 수 있다.

## 6. What Was Actually Compared?

슬라이드 11과 원 논문 §5.1은 Qwen, Llama, OLMo3의 약 0.5B–8B base·instruct 모델을 수학(Countdown, GSM8K, MATH-500, OlympiadBench), 코드(MBPP), 글쓰기(ROCStories), 화학(USPTO) 과제에서 비교한다. 기준 모델, test-time majority vote(TT-MV), PPO, GRPO, ES 등이 비교군이다. 논문 Figure 6의 점 하나는 특정 **모델·과제 조합의 정확도**를 뜻하고, 대각선 위는 세로축 RandOpt 정확도가 가로축 비교군보다 높다는 뜻이다. 산점도 점들의 크기·모양·색도 조건을 구분하므로 모든 점을 한 데이터셋의 반복 측정으로 보면 안 된다.

비교군의 **post-training FLOPs를 맞추었다**는 것은 시험 때의 비용까지 같다는 뜻이 아니다. Figure 6의 RandOpt는 $$K=50$$ 모델의 투표를 사용한다. PPO/GRPO의 가운데 그래프는 일반적인 **1-pass** 결과이고, 오른쪽 ES+TT-MV는 50개 시험 표본의 투표를 사용한다. 그래서 ‘RandOpt가 항상 PPO/GRPO보다 효율적이다’라는 식의 총비용 결론은 그래프만으로 낼 수 없다. 논문도 RandOpt 자체를 우월한 정답으로 권하기보다, 강한 사전학습 이웃을 조사하는 **probe**로 제시한다. 그 한 조건의 사례로 논문은 200개 GH200 장치에서 OLMo-3-7B-Instruct의 Countdown 과제에 $$N=2000,K=50$$을 적용해 3.2분, 정확도 70%를 보고한다. 이 수치는 같은 장치 수가 없을 때의 재현 시간이나 모든 과제의 속도가 아니다.

**원 논문에서 슬라이드 범위를 넘어서는 보충 결과**도 해석에 중요하다. 논문 §6은 $$N$$, $$K/N$$, 모델 크기 변화에 따른 성능을 살핀다. Countdown의 특정 Qwen2.5-3B-Instruct 조건에서는 $$N$$이 커질수록 더 작은 선택 비율이 유리해지는 구간이 보이나, 이를 모든 과제에 일반화하지 않는다. §7의 proof of concept는 상위 50개 모델의 생성 결과를 단일 모델에 증류해 GSM8K에서 1.5B 모델의 경우 76.4% 앙상블 대비 74.9% 증류, 3B에서는 87.1% 대비 84.3%를 보고한다. 증류는 시험 비용을 줄이지만 추가 학습이 들어가므로 순수한 ‘gradient-free RandOpt’와 비용 조건이 달라진다.

또한 논문 §8은 점수 상승이 **새로운 추론 능력만**을 뜻하는지 직접 검사한다. Qwen2.5-3B-Instruct의 GSM8K 1,319문항 분해에서 RandOpt $$K=50$$의 최종 86.7%에는, 기준 모델의 실제 답이 틀렸으나 바로잡힌 부분과 답은 맞았지만 엄격한 정답 형식 때문에 오답 처리되던 부분이 모두 기여했다. 원 논문 Figure 9는 각각 12.3, 19.0 퍼센트포인트에 해당하는 구성을 제시한다. 따라서 ‘전문성’은 benchmark 점수로 정의된 것이지 인간처럼 독립된 지식·추론 능력을 가진 개체라는 뜻이 아니다.

## 7. What This Changes—and What It Does Not

**세미나의 세 결론**은 다음처럼 정리할 수 있다. 첫째, 충분히 학습된 큰 모델의 정해진 Gaussian 이웃에서는 과제 점수가 좋은 후보의 관측 빈도가 높아진다. 둘째, 그 후보들은 서로 다른 과제에 강점을 보여 선택 후 결합할 여지를 만든다. 셋째, RandOpt처럼 **무작위 탐색 → 점수 기반 선택 → 앙상블**만으로도 해당 조건의 사후학습 기준선에 경쟁적일 수 있다. 이는 사전학습이 단일 해뿐 아니라 **적응하기 쉬운 이웃**을 만들 수 있다는 해석을 뒷받침한다.

그러나 논문의 결론은 어디까지나 측정한 모델·잡음·과제·예산에 묶인다. 작은 모델이나 미학습 모델에서는 RandOpt가 잘 작동하지 않는다. 큰 모델도 시험 과제의 천장에 가까우면 개선 폭이 포화될 수 있다. Gaussian 이웃만으로 극적으로 새로운 능력에 도달할 수 있는지, 왜 그런 이웃이 생기는지, 구조화된 출력을 어떻게 투표할지는 열려 있다. $$K$$회 시험 생성 비용과 후보 $$N$$개 평가 비용을 구분해야 하며, 증류를 더하면 다시 순차적 학습이 들어간다. **‘사전학습이 전부다’ 또는 ‘경사 하강이 필요 없다’는 보편적 결론은 아니다.**

### Source Check

- **Slides 5–6 — Projection:** 2차원 색 지형은 1,000개 가중치 교란의 무작위 투영에 기반한 시각화다. 전체 고차원 이웃의 모든 점을 측정한 지도가 아니다. 근거: 원 논문 Figure 2 caption, §2.1.
- **Slide 6 — Threshold:** 식의 $$m$$은 절대 점수 차이; 그래프 범례의 임계치는 기준 점수에 대한 비율이다. $$m=(r-1)s(\theta)$$로 연결해야 한다. 근거: 원 논문 식 1, Figure 3 caption; 위의 대입 검산.
- **Slide 7 — Discordance:** ‘$$\mathcal D\to1$$ = specialists’는 직관적 축약이다. $$\mathcal D=1$$은 평균 상관 0, 이론 상한은 7과제에서 $$7/6$$이다. 근거: 원 논문 식 2, Appendix H; 양의 준정부호 검산.
- **Slides 7–8 — Sample count:** 다양성 전체 분석은 500개 교란, Figure 4 왼쪽에 **그린 선**은 100개 seed다. 두 표본 수를 혼동하지 않는다. 근거: 원 논문 §2.2, Figure 4 caption.
- **Slide 9 — Causal scope:** 혼합 신호 실험은 thicket 발생의 한 설명 사례이지 LLM에서 동일 원인이라는 인과 증명이 아니다. 선형 신호만 학습한 경우는 needle이 아니라 plateau다. 근거: 원 논문 §3, Figure 5, §11.
- **Slide 10 — Selection data:** ‘validation/task performance’라는 축약은 데이터 누수의 근거가 아니다. 원 알고리즘은 $$D_{\mathrm{train}}$$에서 후보를 고르고 별도 test 성능을 보고한다. 근거: 원 논문 §4, Algorithm 1.
- **Slides 11–12 — Compute:** 동등하게 맞춘 비용은 **training FLOPs**다. Figure 6의 RandOpt $$K=50$$과 PPO/GRPO 1-pass는 추론 비용이 동일하지 않다. ES+TT-MV는 50-pass 비교다. 근거: 원 논문 §5.1, Figure 6 caption.
- **Slide 13 — Reasoning and format:** 점수 향상 전부를 새 reasoning 학습으로 간주하지 않는다. 원 논문은 정답 형식 수정과 실제 오답 수정의 혼합을 측정한다. 근거: 원 논문 §8, Figure 9.

검토 범위는 슬라이드 1–13 전 페이지의 텍스트·그림·수식과 원 논문 v1의 본문, Figure 1–9, Appendix H의 지표 경계 증명이다. 위 정정은 원본 파일 자체를 바꾸지 않은 **해석상의 정정·조건 명시**다. 논문의 모든 benchmark를 재실행하거나 그림의 개별 점을 재추출하지는 않았으므로, 보고된 성능을 독립 재현 결과로 제시하지 않는다.

## Key Takeaways

- **밀도** $$\delta(m)$$는 특정 이웃 분포에서 점수 임계치를 넘는 확률이다. 기준 가중치·$$\sigma$$·과제·임계치를 빼고는 의미가 고정되지 않는다.
- **다양성** $$\mathcal D$$는 과제별 후보 순위 상관으로 측정한다. 일곱 과제에서 이론 범위는 $$0\le\mathcal D\le7/6$$이며, 1은 절대 최대가 아니다.
- **RandOpt**의 훈련 단계는 $$N$$개 후보 평가와 상위 $$K$$개 선택이고, 추론 단계는 $$K$$개 예측의 투표다. 병렬 가능성과 낮은 총비용은 다른 주장이다.
- **해석의 경계:** 성능의 일부는 답 형식 개선일 수 있다. 사전학습된 표현의 효용을 보여주는 실험으로 읽되, 모든 새로운 능력이 가까운 이웃에 이미 있다고 단정하지 않는다.

## References

- Source PDF: `Neural Thickets.pdf` (Yang Ji-Woong seminar slides, 13 pages; locally stored as `neural-thickets.pdf`) — locally supplied; not redistributed. Slides and embedded figures are not published here.
- <a href="https://arxiv.org/abs/2603.12228" target="_blank" rel="noopener">Gan and Isola, Neural Thickets: Diverse Task Experts Are Dense Around Pretrained Weights, arXiv:2603.12228v1</a> — primary paper; <a href="https://arxiv.org/pdf/2603.12228v1" target="_blank" rel="noopener">read the version-pinned original PDF</a>. The locally downloaded PDF is for private study; no PDF is bundled with this post.
- <a href="https://thickets.mit.edu/" target="_blank" rel="noopener">MIT Neural Thickets project page</a> — authors’ figures, explanation, and RandOpt overview.
- <a href="https://github.com/sunrainyg/RandOpt" target="_blank" rel="noopener">Official RandOpt codebase</a> — implementation reference; this post does not claim an independent reproduction.
