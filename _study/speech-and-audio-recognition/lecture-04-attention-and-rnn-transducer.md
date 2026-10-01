---
layout: default
date: 2026-10-01 15:27:08 +0900
last_modified_at: 2026-10-01 16:01:38 +0900
title: "Speech and Audio Recognition Lecture 4: Automatic Speech Recognition II"
course: "Speech and Audio Recognition"
topic: "Attention, LAS, RNN-Transducer, and Language Model Fusion"
order: 5
major_topic: "Speech and Audio Processing"
keywords:
  - "Attention"
  - "Sequence-to-Sequence"
  - "Autoregressive Decoding"
  - "Teacher Forcing"
  - "Cross-Entropy"
  - "Listen Attend and Spell"
  - "RNN-Transducer"
  - "Forward Algorithm"
  - "Streaming ASR"
  - "Beam Search"
  - "Shallow Fusion"
  - "Cold Fusion"
---

# Speech and Audio Recognition Lecture 4: Automatic Speech Recognition II

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture4.pdf</a> — Inkyu An, Kookmin University (48 slides).

[Lecture 3: Automatic Speech Recognition I](/study/speech-and-audio-recognition/lecture-03-automatic-speech-recognition/)에서는 CTC가 정렬을 모르는 음성 프레임과 문자열을 연결하는 과정을 다뤘다. 이번 강의는 **이미 출력한 문자를 다음 예측에 어떻게 반영할 것인가**, 그리고 **음성이 들어오는 동안 전사를 어떻게 갱신할 것인가**로 이어진다. Attention 기반 LAS와 RNN-Transducer는 이 두 질문에 서로 다른 구조로 답한다.

> **핵심:** LAS는 출력 단계마다 입력 전체에 attention을 적용하고 이전 token을 조건으로 다음 token을 생성한다. RNN-T는 음향 시간과 출력 token 수를 별도 축으로 두어, blank이면 시간만 진행하고 token이면 출력 이력만 갱신한다. 학습은 가능한 정렬 경로의 확률을 모두 합하며, streaming 여부는 loss 이름보다 encoder가 미래 음성을 요구하는지에 달려 있다.

아래 페이지 번호는 PDF의 물리적 쪽 번호다. Attention의 수치 예제, cross-entropy의 유도, RNN-T forward 계산과 코드는 **작성자 보충 설명**이다. 원문 표의 조건 누락과 단위 오류는 해당 설명과 마지막 `Source Check`에 기록했다.

## 전체 흐름

| 강의 위치 | 주제 | 이해할 질문 |
|---|---|---|
| pp. 1–2 | CTC 복습 | 음향 문맥과 이전 출력 token의 문맥은 어떻게 다른가? |
| pp. 3–13 | Seq2seq, attention, cross-entropy | 출력마다 필요한 입력을 고르고 확률을 학습하는 방법은 무엇인가? |
| pp. 14–20 | Listen, Attend and Spell | 긴 음성을 줄이고 문자열을 순차적으로 생성하는 과정은 무엇인가? |
| pp. 21–32 | RNN-T 구성과 추론 | blank와 token이 서로 다른 축을 움직이는 이유는 무엇인가? |
| pp. 33–41 | RNN-T 정렬과 학습 | 정답을 만드는 모든 경로를 어떻게 더하는가? |
| p. 42 | Joint network 메모리 | 프레임·token·어휘 수가 메모리를 어떻게 늘리는가? |
| pp. 43–44 | 성능과 구조 비교 | 평가 수치와 streaming 조건을 어떻게 읽어야 하는가? |
| pp. 45–48 | Language model 결합 | Rescoring, shallow, deep, cold fusion은 어디에서 결합하는가? |

### 기호와 단위

| 기호 | 의미 | 단위·성격 |
|---|---|---|
| $$X,x_t$$ | 입력 음성 feature열과 한 프레임 | feature의 scale; 보정되지 않은 Mel 값에 물리 단위를 임의로 붙이지 않음 |
| $$T,t$$ | encoder 출력 프레임 수와 프레임 index | 무차원 정수; 초 단위 시간과 구분 |
| $$y,U,u$$ | 목표 token열, 길이, 이미 출력한 token 수 | 무차원; token은 문자·subword 등 tokenizer에 의해 결정 |
| $$h_t,s_u,g_u,c_u$$ | 음향 state, decoder state, prediction state, attention context | 학습된 무차원 벡터 |
| $$e_{u,t},a_{u,t},q(k)$$ | attention score, attention weight, token 확률 | 무차원; score는 정규화 전 값 |
| $$\epsilon$$ | blank | 출력 문자열에 남지 않는 경로 기호; space와 다름 |
| $$\alpha(t,u)$$ | 특정 lattice 상태까지 오는 경로의 확률 합 | 무차원 |
| $$N,H,V,K$$ | batch 크기, joint hidden 크기, 비blank 어휘 수, beam 폭 | 무차원 정수 |
| $$\mathcal L$$ | 음의 로그 손실 | 자연로그를 쓰면 nats; 물리 단위가 아님 |

## 1. CTC의 다음 과제: 출력 이력 반영

CTC는 입력 $$X$$가 주어졌을 때 프레임별 경로 확률을 곱하고, 같은 목표열로 접히는 경로를 더한다(p. 2).

$$
P_{\mathrm{CTC}}(y\mid X)=\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid X)
$$

이 식의 프레임별 분포는 이전에 선택한 출력 token $$\pi_{<t}$$를 직접 조건으로 받지 않는다. 하지만 encoder가 넓은 음향 구간을 처리할 수 있으므로 **CTC가 음향 문맥을 보지 못한다는 뜻은 아니다**. 외부 언어 모델을 beam search에 넣으면 최종 문장 선택에는 텍스트 문맥도 반영할 수 있다.

강의의 문제 제기는 그 출력 이력을 모델 내부에 넣는 것이다. 예를 들어 앞에서 `hello`를 출력했다면, 다음 token을 선택할 때 음향 feature뿐 아니라 그 prefix도 사용할 수 있다. LAS와 RNN-T는 이전 token을 받는 별도 상태를 유지해 이 조건부 의존성을 학습한다.

## 2. Seq2seq에서 attention이 필요한 이유

### 2.1 하나의 고정 벡터와 입력 state열

슬라이드 pp. 3–5의 **NLP case는 기계번역**이다. 입력 문장의 token열을 $$X=(x_1,\ldots,x_T)$$, 번역 문장의 token열을 $$y=(y_1,\ldots,y_U)$$로 놓는다. 언어마다 어순과 표현 길이가 다르므로 입력의 몇 번째 token을 출력의 같은 위치에 그대로 대응시킬 수 없다. Encoder는 원문을 표현하고 decoder는 번역문을 생성한다. Decoder가 **이미 생성한 번역 prefix를 다음 예측에 다시 사용하는 방식**이 autoregressive generation이다.

기본 encoder–decoder는 길이 $$T$$의 입력을 표현하고 길이 $$U$$의 출력을 생성한다(pp. 3–5). 길이가 다른 것 자체는 오류가 아니다. 어려운 점은 각 출력에 필요한 입력 정보가 서로 다르고, 둘 사이의 정렬이 주어지지 않는다는 것이다.

입력 전체를 마지막 state 하나로 압축하면 긴 문장의 세부 정보를 그 벡터 안에 유지해야 한다. Attention은 encoder의 각 state $$h_1,\ldots,h_T$$를 남겨 두고, 출력 단계마다 필요한 state를 가중합한다. 학습 가능한 soft alignment이므로 특정 source 위치를 사람이 정답으로 지정하지 않아도 된다.

### 2.2 Score → softmax → context

출력 $$y_u$$를 만들기 직전의 decoder state를 $$s_{u-1}$$로 두자. 다음은 pp. 6–11의 수식을 입력 시간 $$t$$와 출력 단계 $$u$$가 구분되도록 정리한 것이다.

$$
e_{u,t}=\operatorname{score}(s_{u-1},h_t)
$$

$$
a_{u,t}=\frac{\exp(e_{u,t})}{\sum_{j=1}^{T}\exp(e_{u,j})},\qquad
c_u=\sum_{t=1}^{T}a_{u,t}h_t
$$

Score는 현재 출력에 대한 입력 state의 관련성을 나타내는 학습된 값이다. Softmax는 이 값을 **같은 출력 단계의 모든 입력 위치**에 걸쳐 정규화한다. 지수값은 양수이고 분모가 그 합이므로 $$a_{u,t}>0$$, $$\sum_t a_{u,t}=1$$이 성립한다. Context $$c_u$$는 그 분포로 입력 state를 가중합한 벡터다. 이것은 softmax와 가중합의 정의에 따른 정확한 관계이며, attention weight가 별도의 단어 출력 확률인 것은 아니다.

**작성자 계산 예시.** 세 입력의 score가 $$(\log 1,\log 2,\log 1)$$이면 지수값은 $$(1,2,1)$$이고 attention weight는 $$(0.25,0.5,0.25)$$다. Encoder state가 $$h_1=(1,0)$$, $$h_2=(0,2)$$, $$h_3=(1,1)$$이면 다음 context를 얻는다.

$$
c_u=0.25(1,0)+0.5(0,2)+0.25(1,1)=(0.5,1.25)
$$

다음 token을 만들 때 decoder state가 달라지면 score와 가중치도 다시 계산된다. 따라서 입력을 항상 동일한 비율로 평균하는 연산과 다르다. 실제 구현에서는 큰 score의 지수값이 overflow하지 않도록 모든 score에서 최대값을 빼고 softmax를 계산한다. 공통 상수를 빼도 분자·분모에 같은 배수가 생겨 비율은 유지된다.

### 2.3 Score 함수의 세 형태

| 형태 | 수식 | 조건과 의미 |
|---|---|---|
| Dot product | $$s^{\top}h$$ | 두 벡터 차원이 같아야 하며 같은 좌표계에서 내적 |
| Bilinear | $$s^{\top}Wh$$ | $$W$$가 두 state를 연결하는 투영을 학습; 서로 다른 차원도 연결 가능 |
| Additive / MLP | $$v^{\top}\tanh(W_s s+W_h h+b)$$ | 두 state를 공통 hidden 공간으로 옮겨 비선형 score 계산 |

슬라이드 p. 10의 MLP는 두 벡터를 이어 붙인 뒤 행렬을 곱하는 형태다. $$W[s;h]=W_s s+W_h h$$로 블록을 나누면 위 additive 형태와 연결된다. Bahdanau 원 논문은 이전 decoder state와 source annotation을 사용하는 additive attention을 정의한다. 이 절은 encoder와 decoder 사이의 **cross-attention**이며, Transformer의 입력끼리 비교하는 self-attention과 구분해야 한다.

### 2.4 Attention 그림을 읽는 법

슬라이드 p. 11의 heatmap은 가로축이 source token, 세로축이 target token이다. 밝은 칸은 해당 출력 단계에서 그 입력 위치의 가중치가 높다는 뜻이다. 대각선 근처의 밝은 부분은 대체로 순서가 맞는 정렬을, 대각선에서 벗어난 부분은 어순 변화에 따라 다른 source 위치를 참고하는 모습을 보여 준다.

음성에서는 가로축이 encoder의 음향 프레임이 된다. 문자는 소리가 지속되는 여러 프레임을 참고할 수 있다. 다만 attention weight는 학습된 정보 결합 계수이며, **밝은 칸 하나가 모델 판단의 유일한 원인임을 증명하지는 않는다**. 일반 full attention도 시간 순서를 반드시 단조롭게 강제하지 않는다.

## 3. Autoregressive generation과 cross-entropy 학습

### 3.1 Autoregressive의 의미

**Autoregressive decoder는 앞에서 생성한 출력열을 조건으로 다음 출력의 분포를 계산한다.** 기계번역의 첫 token은 원문과 시작 상태를 보고 예측하고, 두 번째는 원문과 첫 출력 token을, 세 번째는 원문과 앞의 두 출력 token을 함께 본다. $$y_{<u}=(y_1,\ldots,y_{u-1})$$는 출력 단계 $$u$$ 이전의 prefix다. $$\theta$$는 모델이 학습한 파라미터이며, $$q_u(k)$$는 그 prefix에서 token $$k$$를 낼 확률이다.

$$
q_u(k)=P_{\theta}(y_u=k\mid y_{<u},X)
$$

여기서 생성한 token이 다음 계산의 입력으로 되돌아온다. 이름에 `regressive`가 들어가지만 반드시 연속값을 예측하는 선형 회귀를 사용한다는 뜻은 아니다. 이 강의의 decoder는 vocabulary 위의 확률 분포를 만드는 신경망이다. RNN만 가능한 방식도 아니며, causal target mask를 쓰는 Transformer decoder도 같은 출력 조건을 구현할 수 있다.

$$X$$는 기계번역에서는 원문 token열, LAS에서는 음향 feature열이다. **Target prefix만 과거로 제한한다는 것과 encoder가 미래 음향을 보지 않는다는 것은 서로 다른 조건**이다. 입력 문장을 전부 읽은 offline 번역이나 전체 음성을 읽는 LAS도 출력은 autoregressive하게 생성할 수 있다.

### 3.2 문장 확률의 곱은 어디에서 나오는가

조건부 확률의 정의에서 시작하면 이전 출력에 조건화하는 이유가 드러난다. 나눗셈으로 조건부 확률을 정의하는 각 단계에서 $$P(y_{<u}\mid X)>0$$을 가정한다. 아래 두 번째 token 식에는 $$P(y_1\mid X)>0$$, 세 번째 token 식에는 $$P(y_1,y_2\mid X)>0$$이 필요하다. 확률이 0인 prefix의 완성 경로도 확률이 0이며, 그 prefix에는 아래 나눗셈 유도를 그대로 적용하지 않는다.

$$
P(y_2\mid y_1,X)=\frac{P(y_1,y_2\mid X)}{P(y_1\mid X)}
$$

분모를 이항하면 두 token의 결합 확률을 얻는다. 세 번째 token에도 같은 정의를 적용한다.

$$
P(y_1,y_2\mid X)=P(y_1\mid X)P(y_2\mid y_1,X)
$$

$$
P(y_1,y_2,y_3\mid X)=P(y_1,y_2\mid X)P(y_3\mid y_1,y_2,X)
$$

이를 반복하고 문장 끝 기호 $$y_{U+1}=\mathrm{EOS}$$를 포함하면 확률의 chain rule을 얻는다. 다음 유도는 **작성자 보충 설명**이며, 슬라이드 pp. 3–5, 12–13의 decoder를 연결하는 관계다.

$$
P(y,\mathrm{EOS}\mid X)=\prod_{u=1}^{U+1}P(y_u\mid y_{<u},X)
$$

Chain rule 자체는 독립성 가정 없이 성립하는 확률 항등식이다. 신경망은 각 조건부 분포를 학습된 $$P_{\theta}$$로 근사한다. 이전 출력을 조건에서 제거한 $$\prod_u P(y_u\mid X)$$는 다른 모델링 가정이며, 출력끼리 독립으로 처리한다. 또한 autoregressive가 바로 앞 token 하나만 보는 1차 Markov 모델이라는 뜻도 아니다. 원칙적으로 전체 prefix를 조건으로 두되 실제로 보존하는 정보는 decoder 구조와 context 길이에 달려 있다.

### 3.3 기계번역 예시를 단계별로 읽기

다음은 **작성자가 구성한 예시**다. 원문 `I am a student`를 번역하고, 설명을 위해 출력 token을 단어 단위 `나는`, `학생이다`로 정했다고 하자. 실제 모델에서는 tokenizer에 따라 더 작은 subword로 나뉠 수 있다.

| 단계 | Decoder가 사용하는 출력 prefix | 예시에서 선택한 token | 해당 조건부 확률 |
|---|---|---|---:|
| 1 | 없음; 시작 기호 BOS | `나는` | 0.9 |
| 2 | `나는` | `학생이다` | 0.8 |
| 3 | `나는 학생이다` | EOS | 0.95 |

모든 단계는 동일한 원문 $$X$$도 함께 사용한다. 각 숫자는 **그 단계의 prefix가 주어졌을 때 선택한 token의 확률**이지 전체 문장의 확률이 아니다. 종료까지 포함한 이 번역 경로의 확률은 다음과 같다.

$$
P_{\theta}(\text{나는, 학생이다, EOS}\mid X)=0.9\times0.8\times0.95=0.684
$$

첫 token을 `저는`으로 생성했다면 두 번째 단계의 조건도 `저는`으로 바뀐다. 위의 0.8은 `나는` prefix에서의 값이므로 그 다른 경로에 그대로 재사용할 수 없다. 이것이 생성된 출력이 다음 예측에 영향을 주는 구체적인 의미다. Token 선택에는 greedy, sampling, beam search 등을 사용할 수 있다. **Autoregressive는 분포의 조건 관계이고 greedy는 그 분포에서 무엇을 선택할지 정하는 방법**이다.

### 3.4 학습과 추론에서 무엇을 다시 입력하는가

기본적인 teacher forcing은 정답 prefix로 다음 정답 token을 예측하도록 학습한다. 위 번역의 decoder 입력과 정답을 한 칸 어긋나게 배치하면 다음과 같다.

```text
Decoder input: BOS    나는      학생이다
Target:        나는   학생이다  EOS
```

두 번째 위치의 decoder 입력에 있는 `나는`은 첫 위치의 정답이다. **현재 예측해야 하는 `학생이다`나 그 뒤의 EOS를 현재 출력의 조건으로 보여 주는 방식은 아니다.** Transformer decoder에서 여러 위치를 한 번에 계산할 때는 causal mask로 이후 target 위치를 가려 이 조건을 유지한다. 따라서 학습 계산을 병렬화할 수 있다는 사실과 확률 분해가 autoregressive하다는 사실은 충돌하지 않는다. RNN decoder는 hidden state의 시간 의존성 때문에 teacher forcing을 해도 recurrent 계산이 순차적이다.

추론에는 정답 prefix가 없으므로 실제로 생성한 token을 다시 입력한다. 앞에서 잘못 선택한 token은 이후 조건을 바꾸며 오류가 이어질 수 있다. 이 학습·추론 입력의 차이를 exposure bias라고 부른다. 원래 LAS는 이 차이를 줄이는 방법으로 정답 대신 모델에서 뽑은 이전 token을 일부 사용하는 학습도 실험한다. 학습 예시를 먼저 이해한 뒤 이 보완 기법을 읽으면 무엇을 바꾸려는지 분명해진다.

### 3.5 Autoregressive와 attention은 같은 개념인가

두 연산은 담당하는 질문이 다르다. **Autoregressive 조건은 “어떤 출력을 이미 만들었는가”, cross-attention은 “그 prefix에서 다음 출력을 만들 때 원문의 어디를 참고할 것인가”**를 처리한다. Decoder는 이전 출력으로 상태를 갱신하고 그 상태에 맞춰 원문 state의 attention weight를 다시 계산한다.

고정된 encoder 벡터 하나만 사용하는 decoder도 이전 출력을 조건으로 다음 token을 내면 autoregressive다. 반대로 attention을 쓴다는 사실만으로 출력이 autoregressive라고 결론 낼 수는 없다. 기본 LAS에서는 두 기능을 함께 사용하고, RNN-T에서는 prediction network가 이전 출력 prefix를 반영하면서 별도의 시간·token lattice를 따른다. 이들의 출력 이력 조건과 정렬 처리 방법을 따로 보아야 한다.

### 3.6 One-hot 정답에서는 왜 음의 로그 하나가 남는가

정답 분포 $$p(k)$$와 예측 분포 $$q(k)$$의 cross-entropy는 다음으로 정의한다. $$q(k)>0$$인 조건에서 쓰며, 정답 확률이 양수인 위치의 $$q(k)=0$$이면 손실은 무한대로 해석한다.

$$
H(p,q)=-\sum_{k\in\mathcal V}p(k)\log q(k)
$$

정답 token이 $$k^*$$이면 one-hot 분포는 그 위치에서만 1이다. 따라서 나머지 항은 0이 되고 $$H(p,q)=-\log q(k^*)$$가 된다. 문장 전체에서는 각 출력 단계의 음의 로그를 더한다.

$$
\mathcal L_{\mathrm{CE}}=-\sum_{u=1}^{U+1}\log P(y_u^*\mid y_{<u}^*,X)
$$

슬라이드 p. 13은 vocabulary를 `cat, dog, bird`, 첫 분포를 $$(0.1,0.7,0.2)$$로 제시한다. 정답은 표와 one-hot $$(0,1,0)$$에 따라 **dog**이며, 본문의 `dot`는 오기다. 자연로그를 사용한 손실은 다음과 같다.

$$
-\log 0.7\approx0.356675
$$

세 출력 단계의 정답을 `dog, cat, bird`로 두면, 슬라이드의 각 정답 확률은 $$0.7,0.9,0.8$$이다. 이는 **슬라이드 숫자를 이용해 작성자가 구성한 목표열 예시**다. 그 문장 prefix의 조건부 확률 곱은 $$0.504$$이고, EOS를 제외한 해당 세 단계 손실 합은 $$-\log 0.504\approx0.685179$$다. 이 세 값만으로 종료까지 포함한 전체 문장 확률을 계산했다고 보아서는 안 된다.

### 3.7 어떤 확률을 높이도록 학습하는가

Logit을 $$z_k$$, $$q(k)=\exp(z_k)/\sum_j\exp(z_j)$$로 놓으면 one-hot 손실을 다음처럼 변형할 수 있다. 아래는 **작성자 유도**다.

$$
\mathcal L=\log\left(\sum_j\exp(z_j)\right)-z_{k^*}
$$

$$
\frac{\partial\mathcal L}{\partial z_k}=q(k)-\mathbf1[k=k^*]
$$

첫 분포의 gradient는 $$(0.1,-0.3,0.2)$$다. Gradient descent는 정답 `dog`의 logit을 높이고 다른 logit을 낮추는 방향으로 움직인다. 이 gradient가 출력층과 decoder, attention을 거쳐 encoder까지 전달되므로 어떤 음향 표현과 정렬이 정답 예측에 유용한지도 학습된다. 실제 파라미터 변화는 learning rate와 각 층의 Jacobian에도 의존한다.

### 3.8 “분포가 다를수록 커진다”의 정확한 의미

Cross-entropy는 일반적인 대칭 거리도 아니고, 임의의 분포 사이 거리 순서를 그대로 따르는 값도 아니다. 정의를 전개하면 다음 정확한 관계를 얻는다.

$$
H(p,q)=H(p)+D_{\mathrm{KL}}(p\lVert q),\qquad
D_{\mathrm{KL}}(p\lVert q)=\sum_k p(k)\log\frac{p(k)}{q(k)}
$$

고정된 정답 분포 $$p$$에서는 $$H(p)$$가 상수이고 KL divergence가 0 이상이므로 $$q=p$$일 때 최소다. 양의 분포의 경우, $$-\log$$의 볼록성에 Jensen 부등식을 적용하면 비음수성도 확인할 수 있다.

$$
D_{\mathrm{KL}}(p\lVert q)=-\sum_kp(k)\log\frac{q(k)}{p(k)}\ge-\log\sum_kq(k)=0
$$

0인 확률은 해당 항의 극한으로 처리한다.

One-hot 정답에서는 정답 위치의 확률만 손실을 결정한다. 예측 $$(0.1,0.7,0.2)$$와 $$(0.2,0.7,0.1)$$는 서로 다른 분포지만 `dog`에 대한 cross-entropy가 같다. 따라서 원문의 표현은 **정답에 주는 확률이 작아질수록 음의 로그 손실이 커진다**로 읽는 것이 정확하다.

## 4. LAS: Listen, Attend and Spell

### 4.1 세 모듈의 연결

LAS는 음성을 바로 문자열로 만드는 attention 기반 encoder–decoder다(pp. 14–17).

1. **Listener:** 음성 feature열을 음향 state열로 바꾼다.
2. **Attend:** 현재 출력 단계에서 관련 있는 음향 state를 가중합한다.
3. **Speller:** 이전 문자와 decoder state, context를 사용해 다음 문자 분포를 만든다.

Listener가 음성을 한 번 표현하고, Speller는 출력을 하나씩 만든다. Attend는 매 출력 단계에 다시 계산된다. EOS는 출력 종료를 나타내며 CTC/RNN-T의 blank와 역할이 다르다.

### 4.2 Pyramidal BLSTM이 길이를 줄이는 과정

원래 LAS의 Listener는 아래쪽 BLSTM 위에 세 pyramidal BLSTM 층을 둔다. 각 pyramidal 층은 아래층의 인접한 두 시간 state를 이어 붙여 하나의 입력으로 받는다. 짝수 길이일 때의 구조를 단순화하면 다음과 같다.

$$
z_i^{(\ell)}=\left[h_{2i-1}^{(\ell-1)};h_{2i}^{(\ell-1)}\right],\qquad
h_i^{(\ell)}=\operatorname{BLSTM}_{\ell}\left(z_{1:L_{\ell}}^{(\ell)}\right)_i
$$

이는 구조의 **정의**이지 임의 신호를 손실 없이 복구하는 항등식이 아니다. 연결한 벡터를 recurrent layer가 새 표현으로 변환한다. 시간 길이는 층마다 절반이므로 세 층 뒤에는 $$T/2^3=T/8$$이다. 예를 들어 800프레임은 $$800\to400\to200\to100$$으로 줄어든다. 홀수 길이는 구현의 padding·길이 처리에 따라 정해야 한다.

슬라이드 p. 16의 그림은 두 번 줄여 4배 축소를 보여 주지만, 원 논문의 세 pyramidal 층은 8배 축소한다. 프레임 수를 줄이면 반복 계산과 attention이 보는 위치 수가 함께 줄어든다. 다만 너무 강한 축소는 짧은 소리의 구분을 어렵게 할 수 있으므로 속도만 보고 결정하지 않는다. “RNN은 긴 입력을 처리할 수 없다”는 절대적인 제한보다, **길수록 계산과 최적화 부담이 커진다**는 설명이 적절하다.

### 4.3 Greedy와 beam decoding

Greedy는 현재 prefix에서 가장 큰 확률을 가진 token을 하나 선택하고 EOS까지 반복한다. 그러나 현재 최선이 전체 문장 최선이라는 보장은 없다.

**작성자 예시.** 첫 선택에서 `a`가 0.6, `b`가 0.4이고, 이후 가장 좋은 종료 확률이 각각 0.2와 0.9라고 하자. `a`로 시작하는 완성 경로는 $$0.6\times0.2=0.12$$, `b`로 시작하는 경로는 $$0.4\times0.9=0.36$$이다. Greedy는 첫 단계에서 `b` 경로를 잃는다. 여기의 숫자는 두 경로의 비교를 위한 조건부 확률이며 전체 가능한 문장을 열거한 분포가 아니다.

Beam search는 각 prefix를 확장하고 누적 log probability가 높은 $$K$$개를 남긴다. EOS가 나온 후보와 진행 중 후보의 처리, 길이 보정, 외부 LM 사용 여부도 결과에 영향을 준다. Beam 폭이 유한하면 가지를 버리므로 전역 최대 문장을 정확히 찾는 알고리즘은 아니다.

### 4.4 기본 LAS가 streaming에 불리한 이유

원래 LAS는 양방향 Listener와 입력 전체에 대한 attention을 사용한다. 현재 음향 state를 만들거나 어느 위치를 볼지 결정하는 데 아직 들어오지 않은 음성을 필요로 하므로 그 구성은 offline이다. **Attention이라는 연산 자체가 반드시 offline인 것은 아니다.** 온라인 정렬·제한된 context·chunk 구조로 바꾸면 지연 조건도 달라진다.

## 5. RNN-Transducer: 음향 시간과 출력 이력을 분리

### 5.1 Encoder, prediction, joint network

RNN-T는 음향 상태와 출력 prefix를 별도로 표현한다(p. 21).

$$
h_t=\operatorname{Encoder}(X)_t,\qquad
g_u=\operatorname{Prediction}(y_1,\ldots,y_u)
$$

$$
p(k\mid t,u)=\operatorname{softmax}\left(\operatorname{Joint}(h_t,g_u)\right)_k
$$

첫 prefix $$u=0$$에는 아직 출력한 token이 없으며 초기 state 또는 시작 기호를 사용한다. Joint network는 두 표현을 결합해 $$\mathcal V\cup\{\epsilon\}$$ 위의 분포를 만든다. Joint의 구체적인 투영·비선형 구조는 구현에 따라 다르며, 모든 RNN-T가 하나의 동일한 행렬식을 사용하지는 않는다.

Prediction network는 학습 전사의 prefix에서 문맥을 배우지만 음향 encoder와 함께 ASR 목적식으로 학습되는 구성 요소다. 대규모 별도 text corpus로 학습한 외부 LM과 완전히 같은 데이터·역할이라고 보아서는 안 된다.

### 5.2 Blank와 token의 서로 다른 이동

상태 $$(t,u)$$는 음향 시간 index $$t$$에 있고 이미 $$u$$개의 token을 출력했다는 뜻이다. Encoder frame이 $$0,\ldots,T-1$$일 때 다음 두 전이를 사용한다.

| 선택 | 다음 상태 | 갱신되는 정보 |
|---|---|---|
| Blank $$\epsilon$$ | $$(t+1,u)$$ | 다음 음향 프레임으로 이동; 출력 prefix 유지 |
| Non-blank token $$k$$ | $$(t,u+1)$$ | 현재 프레임에서 token 추가; prediction state 갱신 |

Token을 냈다고 반드시 다음 음향 프레임으로 넘어가지 않는다. 따라서 **같은 frame에서 여러 token을 낼 수 있다**. 실제 decoder는 끝없이 token을 내는 상황을 막는 symbol limit 등 구현 조건을 두기도 한다. Blank는 무음의 판정이 아니라 시간 진행을 나타내는 경로 선택이다.

CTC는 프레임마다 기호 하나를 낸 뒤 연속 반복을 병합한다. RNN-T는 token 전이마다 token을 그대로 추가하므로 `a, a`라는 두 non-blank 전이는 `aa`가 된다. CTC의 collapse 규칙을 RNN-T에 적용해 둘을 하나로 합치면 잘못된 전사가 된다.

### 5.3 원문의 `cat` 추론 그림

슬라이드 pp. 22–32는 같은 전이를 한 단계씩 추가한다. p. 24의 blank는 첫 프레임에서 다음 프레임으로 이동한다. p. 25에서 `c`를 내면 prefix가 `c`가 되고, p. 27의 blank는 음향 시간을 다시 진행시킨다. 이어 `a`, `t`가 출력되면서 prediction state가 각각 `ca`, `cat`을 반영한다. p. 32의 남은 blank들은 출력열을 유지한 채 마지막 음향 프레임까지 진행한다.

그림에서 가로로 움직이는 화살표는 시간 진행, 세로로 움직이는 화살표는 출력 증가다. 두 축을 한 개의 “다음 단계”로 합치면 blank가 prediction state를 바꾼다거나 token이 항상 시간을 넘긴다는 오해가 생긴다.

### 5.4 Streaming의 실제 조건

RNN-T의 출력 이력은 이미 생성한 prefix만 쓰므로 미래 token이 필요 없다. 하지만 encoder가 양방향이고 발화 전체를 읽어야 한다면 현재 $$h_t$$에도 미래 음향이 필요하다. 따라서 streaming RNN-T에는 **causal encoder 또는 지연이 제한된 chunk encoder**가 필요하다. Graves의 원래 transducer 논문은 양방향 transcription network도 사용하므로, RNN-T라는 이름만으로 streaming을 보장할 수 없다.

## 6. RNN-T 학습: 모든 정렬 경로의 확률 합

### 6.1 목표열을 고정하면 lattice가 생긴다

학습에서는 정답 token열 $$y=(y_1,\ldots,y_U)$$를 알고 있지만 어느 음향 frame에서 각 token이 나오는지는 모른다(pp. 33–41). 목표열에 대해 가능한 전이는 blank 또는 **그 prefix 다음의 정답 token**이다. 다른 token은 다른 전사를 만드는 경로여서 이 목표열의 확률 합에 포함하지 않는다.

각 상태의 blank 확률과 다음 정답 token 확률을 다음처럼 정의한다.

$$
b_{t,u}=p(\epsilon\mid t,u),\qquad
\ell_{t,u}=p(y_{u+1}\mid t,u)
$$

$$\ell_{t,u}$$는 $$u<U$$일 때만 사용한다. 각 값은 vocabulary 전체 softmax에서 해당 항목을 고른 것이다. 어휘가 둘 이상이면 $$b_{t,u}+\ell_{t,u}$$가 1일 필요는 없다. 남은 확률은 현재 목표열과 다른 문장으로 향한다.

RNN-T는 유효 정렬 집합 $$\mathcal A_T(y)$$의 경로 확률을 더한다. 같은 blank/token 경로 안에서는 방문 상태의 전이 확률을 곱한다.

$$
P(y\mid X)=\sum_{a\in\mathcal A_T(y)}\prod_{(t,u,k)\in a}p(k\mid t,u),\qquad
\mathcal L_{\mathrm{RNNT}}=-\log P(y\mid X)
$$

여기서는 입력 프레임을 모두 진행한 $$t=T$$를 종료 상태로 정의하므로 마지막 시간 전이도 blank다. Graves 원 논문의 1-based 표기는 마지막 blank를 forward 값 뒤에 별도로 곱한다. **종료를 forward 상태 안에 넣는지 밖에 두는지만 다른 convention**이며, 마지막 blank를 두 번 곱하거나 생략하면 실제 확률이 바뀐다.

### 6.2 Forward DP를 유도하기

$$\alpha(t,u)$$를 $$(t,u)$$에 도달한 유효 부분 경로의 확률 합으로 정의한다. 시작 상태는 $$\alpha(0,0)=1$$이고 나머지는 0으로 초기화한다. $$t<T$$에서 다음 관계로 합을 전달한다.

$$
\alpha(t+1,u)\mathrel{+}=\alpha(t,u)b_{t,u}
$$

$$
\alpha(t,u+1)\mathrel{+}=\alpha(t,u)\ell_{t,u}\qquad(u<U)
$$

이 식은 경험식이 아니라 **경로의 마지막 전이를 두 종류로 분할한 정확한 DP**다. Blank 뒤에는 prefix가 같고, token 뒤에는 정답 prefix가 한 칸 늘어난다. 같은 $$(t,u)$$에 도달한 모든 경로는 동일한 음향 state와 목표 prefix state를 사용하므로 앞으로의 선택지도 같다. 개별 경로를 저장하는 대신 확률 합 하나를 재사용할 수 있다.

두 전이는 $$t$$ 또는 $$u$$를 증가시키므로 이 lattice에는 역방향 순환이 없다. 같은 frame의 token 전이를 반영하려면 $$u$$도 작은 값부터 큰 값으로 계산한다. $$t=T$$에서는 더 이상 encoder state가 없으므로 새 token을 내지 않으며, 목표가 미완성인 $$u<U$$의 종료 경로는 버린다. 완성된 확률은 $$P(y\mid X)=\alpha(T,U)$$다.

DP가 방문하는 상태 수는 $$O(T(U+1))$$이다. 이 수치는 **필요한 joint 확률이 이미 계산되어 있을 때의 forward 합산 비용**이다. Vocabulary softmax와 joint hidden 계산까지 공짜라는 뜻은 아니다. 실제 학습은 아주 작은 확률을 반복해서 곱하므로 log-domain의 log-sum-exp, scaling 또는 안정적인 전용 loss kernel을 사용한다.

### 6.3 숫자와 그림으로 계산하기

다음은 **작성자가 구성한 검산 예시**다. Encoder frame은 두 개($$T=2$$), 목표는 `a` 한 개($$U=1$$)이며 vocabulary는 `a`와 blank다.

| 상태 | $$p(a)$$ | $$p(\epsilon)$$ |
|---|---:|---:|
| $$(0,0)$$ | 0.5 | 0.5 |
| $$(0,1)$$ | 0.4 | 0.6 |
| $$(1,0)$$ | 0.7 | 0.3 |
| $$(1,1)$$ | 0.2 | 0.8 |

이미 `a`를 낸 $$u=1$$에서는 또 `a`를 내면 `aa`가 되므로, 목표 `a`의 합에는 blank만 허용된다.

![RNN-T lattice for target a with two acoustic frames; token transitions move upward and blank transitions move right.]({{ "/assets/images/study/speech-and-audio-recognition/rnnt-forward-lattice.svg" | relative_url }})

가능한 완성 경로는 `a ε ε`와 `ε a ε` 두 개다. 같은 목표에 해당하는 서로 배타적인 경로이므로 합한다.

$$
P(a\epsilon\epsilon)=0.5\times0.6\times0.8=0.24
$$

$$
P(\epsilon a\epsilon)=0.5\times0.7\times0.8=0.28
$$

$$
P(a\mid X)=0.24+0.28=0.52,\qquad
\mathcal L=-\log0.52\approx0.653926
$$

DP에서도 $$\alpha(0,1)=0.5$$, $$\alpha(1,0)=0.5$$다. 두 길이 만나는 $$(1,1)$$의 합은 $$0.5\times0.6+0.5\times0.7=0.65$$이고 마지막 blank를 곱하면 $$\alpha(2,1)=0.65\times0.8=0.52$$다. 중간의 0.65는 아직 마지막 프레임을 진행하지 않은 상태의 합이지 완성된 전사 확률은 아니다.

### 6.4 계산 코드의 각 단계

다음 코드는 위 예시만 계산하는 설명용 Python이며 학습 가능한 RNN-T 구현은 아니다.

```python
import math

T, U = 2, 1
blank = [[0.5, 0.6], [0.3, 0.8]]
label = [[0.5], [0.7]]  # 각 prefix에서 다음 정답 a의 확률
alpha = [[0.0] * (U + 1) for _ in range(T + 1)]
alpha[0][0] = 1.0

for t in range(T):
    for u in range(U + 1):
        alpha[t + 1][u] += alpha[t][u] * blank[t][u]
        if u < U:
            alpha[t][u + 1] += alpha[t][u] * label[t][u]

probability = alpha[T][U]
loss = -math.log(probability)
assert math.isclose(probability, 0.52)
print(f"P={probability:.6f}, loss={loss:.6f}")
# P=0.520000, loss=0.653926
```

`alpha`는 경로 목록이 아니라 상태별 합을 저장한다. 첫 갱신은 blank에 의한 가로 전이, 두 번째 갱신은 token에 의한 세로 전이다. 마지막 줄이 $$u=U$$인 상태만 읽기 때문에 blank 두 번만 내고 목표 `a`를 내지 못한 경로는 결과에서 제외된다. 긴 실제 음성에는 이 단순 확률 공간 코드를 그대로 사용하면 underflow가 생길 수 있다.

### 6.5 추론과 학습의 차이

학습 DP의 세로축은 **주어진 정답 prefix**다. 추론에서는 정답이 없으므로 여러 후보 prefix마다 prediction state와 점수가 달라진다. Greedy RNN-T는 현재 상태의 가장 큰 분포 항을 선택하고 blank일 때만 시간을 넘긴다. Beam search는 여러 prefix를 유지하고 필요하면 같은 prefix에 도달한 경로를 합친다. 따라서 학습 lattice 전체를 계산하는 알고리즘과 추론의 beam search를 동일한 절차로 보아서는 안 된다.

## 7. Joint network가 메모리를 많이 쓰는 이유

### 7.1 세 축의 조합

음향 encoder 출력은 대체로 $$N\times T$$개이고 prediction state는 $$N\times(U+1)$$개다. 그런데 dense joint 계산은 **음향 프레임마다 모든 목표 prefix와 결합**한다. Hidden 크기가 $$H$$, blank를 제외한 어휘 수가 $$V$$라면 full grid의 전형적인 tensor 크기는 다음과 같다.

$$
M_{\mathrm{hidden}}=N T (U+1)H d,\qquad
M_{\mathrm{logits}}=N T (U+1)(V+1)d
$$

$$d$$는 값 하나의 byte 수이며 fp32에서는 4 bytes다. 이 식은 해당 tensor를 모두 materialize한다는 **할당 크기 계산**이다. 구현이 joint/loss를 fuse하거나 일부만 계산하면 실제 peak memory는 달라진다.

### 7.2 슬라이드 p. 42의 수치 재계산

원문은 개략 계산에서 $$U+1$$ 대신 $$U$$를, blank 포함 어휘 수 대신 제시한 $$V$$를 사용한다. 아래는 **그 원문 곱셈을 그대로 검산한 값**이며 정확한 전체 학습 메모리라는 뜻은 아니다.

| 설정 | 원문의 곱셈 | Decimal GB | GiB |
|---|---|---:|---:|
| 문자, hidden | $$32\times800\times450\times640\times4$$ | 29.4912 | 27.466 |
| 문자, logits | $$32\times800\times450\times28\times4$$ | 1.29024 | 1.202 |
| Subword, hidden | $$32\times200\times150\times640\times4$$ | 2.4576 | 2.289 |
| Subword, logits | $$32\times200\times150\times1024\times4$$ | 3.93216 | 3.662 |

$$1\,\mathrm{GB}=10^9$$ bytes, $$1\,\mathrm{GiB}=2^{30}$$ bytes다. 원문의 `Gb`는 bit를 뜻하므로 여기서는 **GB**로 바로잡는다. 첫 hidden 곱셈은 29,491,200,000 bytes다.

Subsampling은 $$T$$를, subword는 보통 $$U$$를 줄일 수 있다. 하지만 subword vocabulary가 커지면 $$V$$가 늘어 logits의 메모리는 증가할 수도 있다. 위 예시가 바로 그 경우다. Hidden tensor는 크게 줄지만 logits는 약 1.29 GB에서 3.93 GB로 늘어난다. 두 효과를 함께 봐야 tokenizer·stride가 실제 자원을 얼마나 줄이는지 알 수 있다.

“Gradient를 저장하므로 두 배”라는 슬라이드 설명은 대략적인 부담을 보여 준다. 실제 학습 peak에는 저장된 activation, backward kernel, 파라미터·optimizer state, padding, dtype, recomputation 등이 관여한다. 따라서 추정값에 2를 곱해 GPU 요구량을 확정하지 말고 구현에서 측정해야 한다.

## 8. CTC, LAS, RNN-T를 비교하는 기준

### 8.1 CTC와 LAS가 정렬을 처리하는 방식

CTC와 LAS는 모두 음성과 전사만으로 학습할 수 있고, 각 문자가 어느 프레임에 대응하는지를 정답으로 지정하지 않는다. 차이는 그 미지의 정렬과 출력 이력을 모델 안에서 처리하는 위치다.

CTC는 encoder 프레임마다 문자·subword·blank의 분포를 만든다. 정답 문자열로 collapse되는 여러 단조 정렬 경로의 확률을 더한 뒤 그 합에 음의 로그를 취한다. LAS는 출력 단계마다 encoder state에 attention을 적용하고, 정답 prefix에서 다음 token을 예측하도록 cross-entropy를 학습한다. 표준 LAS의 soft attention은 가중합으로 context를 만드는 연산이지, CTC의 이산 정렬 경로를 열거해 합산하는 loss가 아니다.

$$
\mathcal L_{\mathrm{CTC}}=-\log\left[\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid X)\right]
$$

$$
\mathcal L_{\mathrm{LAS}}=-\sum_{u=1}^{U+1}\log P_{\theta}(y_u^*\mid y_{<u}^*,X)
$$

CTC의 합은 정렬 경로에 대한 합이고, LAS의 합은 문장 확률의 곱에 로그를 적용한 출력 단계별 손실의 합이다. 둘 다 합 기호가 있다는 이유로 같은 학습 계산이라고 볼 수 없다. LAS는 정답 prefix를 직접 조건으로 쓰지만, 기본 CTC 프레임 분포에는 이전에 선택한 출력 token이 직접 들어가지 않는다. CTC encoder가 넓은 음향 문맥을 보거나 별도의 LM을 decoder에 결합할 수 있다는 사실은 이 차이와 별개다.

출력 종료도 다르다. CTC의 blank는 프레임 경로를 문자열로 바꿀 때 제거되는 기호이며, 기본 CTC는 입력 프레임을 처리한 뒤 collapse 결과를 얻는다. LAS의 EOS는 decoder가 문장을 끝내는 출력 token이다. **작성자 예시로** 문자열 `aa`를 보면 CTC에는 `a, blank, a`처럼 같은 글자 두 개를 구분할 중간 blank가 필요하다. 문자 단위 LAS는 `a`, `a`, EOS를 차례로 생성하면 되며 반복 병합을 하지 않는다. 이 차이는 서로 다른 loss·출력 규칙의 결과이지 어느 방식의 정확도가 항상 더 높다는 근거는 아니다.

### 8.2 RNN-T를 포함한 구조와 streaming 조건

| 항목 | CTC | 기본 LAS | RNN-T |
|---|---|---|---|
| 출력 이력 | 경로 분포에 이전 선택 token을 직접 조건화하지 않음 | 이전 token을 조건으로 다음 token 생성 | Prediction network가 prefix 표현 |
| 정렬 처리 | 프레임 경로 합과 collapse | 출력마다 입력 state에 attention | 시간·token lattice의 경로 합 |
| 학습 목적 | 정답으로 collapse되는 경로들의 확률 합 최대화 | 정답 prefix에서 다음 token 확률 최대화 | 정답을 만드는 blank/token 경로들의 확률 합 최대화 |
| Blank / 종료 | 반복 병합 후 blank 제거 | EOS로 출력 종료; 기본 LAS에는 CTC blank가 없음 | Blank는 시간 진행, token은 prefix 진행 |
| Streaming | Encoder와 decoder의 지연 조건에 따름 | 양방향 encoder·full attention이면 offline | Causal/chunk encoder일 때 가능 |
| 추론의 순차 의존 | Greedy frame 선택은 출력 이력 계산이 없음 | Token별 decoder state 갱신 | Blank/token 선택별 상태 진행 |

외부 LM과 decoder를 붙이면 실제 시스템의 동작은 표의 기본 모델보다 복잡해진다. 예를 들어 CTC에 LM을 결합하면 문장 후보의 점수에는 이전 단어가 영향을 준다.

### 8.3 계산량 표에서 무엇을 생략했는가

슬라이드 pp. 19, 20, 44의 `enc`, `dec`, `T`, `bs`는 계산 차이를 보여 주는 약식 표기이며 vocabulary·attention·종료 조건 등이 충분히 정의되지 않았다. 이를 보편적인 복잡도 공식으로 그대로 옮길 수는 없다.

Encoder 이후 프레임 수를 $$T$$, 출력 길이를 $$U$$라고 고정하면, standard LAS의 full attention은 각 token마다 모든 프레임을 비교해 적어도 score 계산에 $$O(UT)$$의 위치 조합을 사용한다. Beam 폭 $$K$$와 어휘 크기 $$V$$까지 고려하면 후보 확장·LM 호출·prefix merging 비용도 추가된다. RNN-T greedy의 경로는 $$T$$번의 blank와 생성한 $$U$$번의 token 전이로 이루어지므로 joint/prediction 호출도 대체로 그 진행에 맞춰 반복된다. Training의 dense $$T(U+1)$$ grid와 inference의 한 경로를 혼동하지 않는 것이 먼저다.

### 8.4 WER 표는 같은 조건의 순위표가 아니다

원문 pp. 18, 43에는 서로 다른 연구의 수치가 모여 있다. 아래는 원 논문의 표로 확인한 **LibriSpeech test-clean / test-other WER(%)**와 중요한 조건이다.

| 결과 | Test-clean | Test-other | 출처·조건 |
|---|---:|---:|---|
| Human reference | 5.83 | 12.69 | Deep Speech 2 Table 13의 사람 전사 평가 |
| Deep Speech 2 | 5.33 | 13.25 | Deep Speech 2 Table 13; 슬라이드의 5.15/12.73과 다름 |
| LAS, no SpecAugment, no LM | 4.1 | 12.5 | SpecAugment Table 3, LibriSpeech 960h |
| LAS, no SpecAugment, with LM | 3.2 | 9.8 | 같은 Table 3; 슬라이드의 LAS 행에 해당 |
| Conformer-L Transducer, no LM | 2.1 | 4.3 | Conformer Table 2, LibriSpeech 960h |

슬라이드의 `RNN-t 2020` 2.1/4.3은 RNN-T라는 loss의 일반 성능이 아니라 **특정 Conformer-L Transducer** 결과다. 또한 LAS의 `without SpecAugment`는 LM까지 없다는 뜻이 아니다. Encoder, 학습 설정, augmentation, decoding, 외부 LM과 평가 split을 맞추지 않은 채 숫자만으로 구조의 우열을 증명할 수 없다. 이 표의 근거는 <a href="https://arxiv.org/abs/1512.02595" target="_blank" rel="noopener">Deep Speech 2</a>, <a href="https://arxiv.org/abs/1904.08779" target="_blank" rel="noopener">SpecAugment</a>, <a href="https://arxiv.org/abs/2005.08100" target="_blank" rel="noopener">Conformer</a> 원 논문이다.

## 9. 외부 language model을 결합하는 방법

### 9.1 음향 점수와 문장 점수

언어 모델은 앞 token을 바탕으로 다음 token의 확률을 모델링한다(pp. 45–46). Causal LM의 문장 확률은 다음처럼 분해된다.

$$
P_{\mathrm{LM}}(y)=\prod_{u=1}^{U}P_{\mathrm{LM}}(y_u\mid y_{<u})
$$

N-gram은 제한된 길이의 history를 사용하고 smoothing으로 희소한 조합을 처리한다. Neural LM은 학습된 상태로 더 긴 문맥을 표현할 수 있다. ASR decoder도 전사 데이터에서 텍스트 규칙을 배우지만 외부 LM은 별도 텍스트 corpus를 활용할 수 있다.

슬라이드 p. 45의 `two`/`to`/`too` 예에서 음향 점수만 보면 `two`가 0.21로 `to`의 0.19보다 높다. 제시된 LM 점수 0.01과 0.6을 같은 가중치로 곱하는 **예시적 결합**을 하면 각각 0.0021과 0.114가 되어 `to` 후보가 높아진다. 실제 decoder 점수는 아래처럼 가중치와 길이 보정을 포함할 수 있으며, 슬라이드의 숫자는 실제 데이터에서 측정한 성능 결과로 제시된 것이 아니다.

### 9.2 Second-pass rescoring

첫 ASR 검색으로 $$\mathcal N$$이라는 N-best 후보 집합을 만든 뒤, LM 점수를 추가해 그 안에서 문장을 다시 고른다(p. 47).

$$
\hat y=\mathop{\mathrm{argmax}}_{y\in\mathcal N}\left[\log P_{\mathrm{ASR}}(y\mid X)+\lambda\log P_{\mathrm{LM}}(y)+\beta\lvert y\rvert\right]
$$

이는 **점수 결합을 정의한 목적식**이며, 이렇게 결합하면 항상 WER이 줄어든다는 수학적 보장은 없다. $$\lambda$$는 LM 가중치, $$\beta$$는 선택적인 길이 보정 계수다. 별도 정규화 없이 이 점수를 새로운 확률 분포라고 부르지도 않는다.

Rescoring은 완성된 후보를 평가하므로 상대적으로 큰 LM을 사용할 여지가 있다. 하지만 정답 후보가 첫 검색에서 이미 탈락했다면 점수만 바꿔 복구할 수 없다.

### 9.3 Shallow fusion

Shallow fusion은 **beam을 확장하는 도중** ASR과 LM의 log score를 더한다. LM이 중간 prefix 선택에 영향을 주므로, rescoring보다 앞에서 유용한 후보를 남길 수 있다. 모델 내부 state를 합치는 방식은 아니며 ASR과 LM을 각각 학습한 뒤 inference에서 결합할 수 있다.

Token마다 LM을 평가해야 하므로 모델 크기와 호출 비용이 지연에 영향을 준다. 슬라이드 p. 47의 큰 모델·작은 모델 조언은 이 **LM 계산 비용**을 중심으로 읽어야 하며, 괄호의 `ASR`를 LM 크기의 구분과 혼동하지 않는다. 어느 조합이 유리한지는 후보 수·실제 latency·accuracy를 측정해 판단한다.

### 9.4 Deep fusion과 cold fusion

| 방법 | 결합 시점 | 학습 관계 | 결합되는 정보 |
|---|---|---|---|
| Rescoring | 첫 검색이 끝난 뒤 | 별도 학습 가능 | 완성 후보 점수 |
| Shallow fusion | Beam search 중 | 별도 학습 가능 | ASR/LM log score |
| Deep fusion | Decoder 출력 계산 내부 | ASR와 LM을 독립 사전학습한 뒤 결합부 학습·fine-tuning | Decoder/LM state와 gate 등 |
| Cold fusion | ASR 학습 초기부터 | 사전학습 LM을 고정하고 ASR·fusion 구조를 학습 | LM 표현을 학습 중 지속적으로 사용 |

슬라이드 p. 48의 Deep Fusion 그림은 따로 학습한 두 모델을 연결하고, Cold Fusion 그림은 미리 학습한 LM과 함께 ASR을 학습하는 차이를 보여 준다. 원 논문들의 구체적인 gate와 projection은 다를 수 있다. 따라서 점수 하나를 더하는 shallow fusion의 수식을 deep/cold fusion의 전체 정의로 사용할 수 없다. 원문의 deep/cold 표현은 LAS 같은 attention decoder에 직접 연결되며, RNN-T에 적용할 때는 prediction/joint 구조에 맞는 구현을 별도로 정해야 한다.

Deep Fusion의 근거 논문은 <a href="https://arxiv.org/abs/1503.03535" target="_blank" rel="noopener">On Using Monolingual Corpora in Neural Machine Translation</a>, Cold Fusion의 근거는 <a href="https://arxiv.org/abs/1708.06426" target="_blank" rel="noopener">Cold Fusion: Training Seq2Seq Models Together with Language Models</a>이다.

### 9.5 BERT와 causal LM을 같은 방식으로 붙일 수 있는가

슬라이드는 neural LM 예로 BERT, GPT, LLaMA를 나열한다. 하지만 기본 BERT는 양쪽 문맥을 사용하는 masked language model이고, 그대로 다음 token의 $$P(y_u\mid y_{<u})$$를 제공하는 left-to-right LM과 같지 않다. GPT 계열 같은 causal LM은 prefix의 다음 token 점수를 바로 사용하는 방식에 더 직접적으로 맞는다.

BERT는 완성 후보의 masked-token 점수 등을 이용한 rescoring처럼 다른 방식으로 활용할 수 있다. 이 경우 점수의 정의, tokenization과 계산 비용을 따로 명시해야 하며 causal 문장 likelihood와 동일하다고 부를 수 없다. 모델 이름 목록보다 **decoder가 요구하는 조건부 확률을 실제 모델이 제공하는가**를 먼저 확인한다.

## 마지막 핵심 정리

- Attention은 출력별 score를 입력 위치에 걸쳐 정규화하고 state를 가중합한다. 입력 정렬에 대한 soft weight와 출력 token 분포는 다르다.
- Autoregressive는 이전 출력 prefix를 조건으로 다음 token을 생성하는 방식이다. Attention은 참고할 입력 위치를 고르는 별도 연산이다. 기본 teacher forcing 학습은 정답 prefix, 추론은 생성 prefix를 사용한다. One-hot cross-entropy는 정답 token 확률의 음의 로그다.
- LAS의 원래 세 pyramidal 층은 음향 시간을 8배 줄인다. 기본 양방향 encoder와 full attention 구성은 offline이다.
- RNN-T는 blank로 시간 축, token으로 출력 축을 진행한다. CTC의 반복 병합 규칙을 적용하지 않는다.
- RNN-T loss는 모든 유효 정렬의 확률 합에 음의 로그를 취한다. Forward DP와 경로 열거 예시는 모두 $$P(a\mid X)=0.52$$로 일치한다.
- Dense joint의 메모리는 $$T(U+1)$$와 hidden·어휘 크기에 함께 비례한다. Subword는 token 수와 vocabulary 크기를 동시에 바꾼다.
- LM 결합은 검색 후 재평가, 검색 중 점수 결합, 모델 state 결합을 구분한다. 성능 수치는 데이터·LM·decoder 조건과 함께 읽는다.

## Study Guide

먼저 Section 2의 attention을 score, weight, context 세 값으로 구분하고 Section 3의 확률 분포와 손실을 계산한다. 그다음 LAS의 encoder 시간 길이가 어떻게 줄어드는지 확인한 뒤, RNN-T 그림에서 각 화살표가 어느 축을 바꾸는지 따라간다. Forward 계산은 두 경로를 직접 곱해 더한 결과와 DP를 대조하면 가장 분명하다. 마지막으로 메모리 표와 LM 비교 표를 읽어 학습 비용·추론 비용·언어 문맥을 연결한다.

## 복습 질문

<details markdown="block">
<summary>1. Attention weight와 다음 token의 확률은 무엇이 다른가?</summary>

답변: Attention weight는 하나의 출력 단계에서 **입력 위치**에 걸쳐 합이 1이 되도록 정규화한 값이다. 다음 token 확률은 **출력 어휘**에 걸쳐 정규화한다. Context를 만든 attention weight 하나를 그대로 특정 단어의 예측 확률로 읽을 수 없다.

</details>

<details markdown="block">
<summary markdown="span">2. 정답이 dog일 때 $$(0.1,0.7,0.2)$$의 cross-entropy는 왜 세 로그의 합이 아닌가?</summary>

답변: One-hot 정답은 dog 위치에서만 1이므로 나머지 항의 계수가 0이다. 손실은 $$-\log0.7\approx0.356675$$다. 정답 확률이 작아질수록 손실은 커진다.

</details>

<details markdown="block">
<summary>3. Teacher forcing과 inference의 prefix는 어떻게 다른가?</summary>

답변: Teacher forcing은 정답 prefix를, inference는 모델이 실제 생성한 prefix를 입력한다. 추론 오류는 다음 조건부 예측에도 영향을 줄 수 있다. Attention도 해당 decoder state에 따라 다시 계산된다.

</details>

<details markdown="block">
<summary>4. LAS의 8배 subsampling은 어디에서 나오는가?</summary>

답변: 세 pyramidal BLSTM 층이 각각 인접 시간 state 두 개를 이어 붙여 시간 길이를 절반으로 만든다. 따라서 총 2×2×2=8배다. 슬라이드의 단순화한 두 층 그림은 4배이며, 원래 모델의 층 수와 구분한다.

</details>

<details markdown="block">
<summary>5. RNN-T가 같은 frame에서 a를 두 번 내면 어떻게 되는가?</summary>

답변: 두 token 전이는 prefix를 두 번 늘리므로 `aa`가 된다. Token을 낼 때 시간은 유지되고 prediction state만 갱신된다. CTC처럼 연속 반복을 하나로 병합하지 않는다.

</details>

<details markdown="block">
<summary markdown="span">6. 예시의 중간 forward 값 0.65를 왜 최종 $$P(a\mid X)$$로 쓰지 않는가?</summary>

답변: 0.65는 마지막 frame의 상태에 도달한 확률 합이다. 이 글의 종료 convention에서는 그 frame에서 마지막 blank를 내고 시간을 끝까지 진행해야 하므로 0.8을 추가로 곱한다. 최종 확률은 0.52, 손실은 약 0.653926이다.

</details>

<details markdown="block">
<summary>7. RNN-T 또는 CTC를 사용하면 항상 streaming인가?</summary>

답변: 아니다. Encoder가 미래 음성을 요구하면 온라인으로 현재 state를 완성할 수 없다. Streaming에는 causal encoder 또는 지연이 제한된 chunk encoder와 이에 맞는 decoder가 필요하다.

</details>

<details markdown="block">
<summary>8. Subword로 바꾸면 joint 메모리가 반드시 줄어드는가?</summary>

답변: Token 길이 U가 줄어 hidden grid는 작아질 수 있지만 vocabulary V가 커져 logits grid는 커질 수도 있다. 원문 예시에서도 hidden은 약 29.49→2.46 GB로 줄고 logits는 약 1.29→3.93 GB로 늘어난다. 정확한 tensor는 empty prefix와 blank 차원도 포함한다.

</details>

<details markdown="block">
<summary>9. Rescoring과 shallow fusion은 정답 후보가 탈락하는 시점에 어떤 차이가 있는가?</summary>

답변: Rescoring은 첫 검색이 만든 후보 안에서만 선택하므로 이미 탈락한 정답을 복구할 수 없다. Shallow fusion은 검색 중 LM 점수가 prefix 유지에 영향을 준다. 둘 다 유한한 검색과 점수 설정 때문에 정답을 보장하지는 않는다.

</details>

<details markdown="block">
<summary>10. Deep fusion과 cold fusion의 학습 순서는 어떻게 다른가?</summary>

답변: Deep fusion은 독립적으로 사전학습한 ASR decoder와 LM을 나중에 결합한다. Cold fusion은 미리 학습해 고정한 LM과 함께 ASR·fusion 구조를 초기부터 학습한다. 두 방법 모두 단순히 최종 log score만 더하는 shallow fusion과 구분된다.

</details>

<details markdown="block">
<summary>11. Autoregressive이면 반드시 RNN 또는 greedy decoder인가?</summary>

답변: 아니다. Autoregressive는 다음 token의 확률이 앞의 출력 prefix를 조건으로 한다는 뜻이다. RNN과 causal-masked Transformer는 그 관계를 구현하는 서로 다른 구조이며, greedy·sampling·beam search는 조건부 분포에서 출력 후보를 고르는 서로 다른 방법이다. Teacher forcing과 causal mask를 쓰면 Transformer 학습은 여러 위치를 병렬로 계산하면서도 각 위치가 미래 정답을 보지 않게 할 수 있다.

</details>

## Source Check

48쪽 전체를 시각적으로 대조하고 attention·loss·전이·메모리 수치를 확인했다. 아래 보충·정정은 원저자의 공식 정정문이 아니라 원 논문 및 직접 계산에 따른 검토다.

| 위치 | 원문 표현 | 본문의 처리·근거 |
|---|---|---|
| pp. 3–5, 12–13 | NLP 기계번역의 decoder와 이전 출력 사용 | Autoregressive의 정의, chain rule 유도, 번역 수치 예시, teacher forcing·causal mask와 attention의 역할 구분 보충 |
| p. 13 | 정답 `dot`, 분포 차이와 CE의 포괄적 설명 | Vocabulary와 one-hot에 맞게 `dog`로 정정. 고정 정답의 CE–KL 관계와 수치로 조건 설명 |
| p. 16 | RNN의 긴 입력 처리, 4× 그림과 8× 설명 | 계산·최적화 부담으로 설명. 원 LAS의 세 pBLSTM 층과 단순 그림의 두 층 구분 |
| pp. 18, 43 | DS2 5.15/12.73, LAS 3.2/9.8, RNN-T 2.1/4.3 | DS2 원문 Table 13의 5.33/13.25로 정정. LAS의 LM 사용과 Conformer-L Transducer 조건 명시 |
| pp. 19, 20, 44 | Streaming yes/no, CTC context=no, 약식 복잡도 | Encoder 지연·출력 prefix·외부 LM을 구분; 비용을 정의 없이 보편식으로 쓰지 않음 |
| pp. 33–41 | 그림 중심의 RNN-T 학습 | Blank/token 전이와 종료 convention, 경로 합·forward DP·독립 수치 검산 보충 |
| p. 42 | 메모리 `Gb`, gradient 때문에 두 배 | Bytes·GB·GiB 재계산; empty prefix/blank 차원과 실제 peak 조건 설명 |
| pp. 45–48 | BERT/GPT/LM 예시, fusion 도식 | Causal 점수와 masked LM 구분; deep/cold 학습 순서를 원 논문과 대조 |

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture Slides: Automatic Speech Recognition II — Inkyu An</a></li>
</ul>

## References

<ul>
  <li><a href="https://github.com/yandexdataschool/speech_course" target="_blank" rel="noopener">Yandex Data School Speech Course</a> and <a href="https://github.com/markovka17/dla" target="_blank" rel="noopener">DLA Course Materials</a> — lecture source collections.</li>
  <li><a href="https://lena-voita.github.io/nlp_course/seq2seq_and_attention.html" target="_blank" rel="noopener">Lena Voita: Seq2seq and Attention</a> — course source used by the lecture figures.</li>
  <li><a href="https://arxiv.org/abs/1409.3215" target="_blank" rel="noopener">Sequence to Sequence Learning with Neural Networks</a> — encoder–decoder and sequence probability.</li>
  <li><a href="https://arxiv.org/abs/1706.03762" target="_blank" rel="noopener">Attention Is All You Need</a> — shifted decoder targets and causal masking preserve autoregressive conditioning during parallel training.</li>
  <li><a href="https://www.cs.toronto.edu/~graves/icml_2006.pdf" target="_blank" rel="noopener">Connectionist Temporal Classification (ICML 2006)</a> — framewise path probabilities, blank and alignment marginalization.</li>
  <li><a href="https://arxiv.org/abs/1409.0473" target="_blank" rel="noopener">Neural Machine Translation by Jointly Learning to Align and Translate</a> — additive attention and source context.</li>
  <li><a href="https://arxiv.org/abs/1508.01211" target="_blank" rel="noopener">Listen, Attend and Spell</a> — pyramidal Listener, Speller, training and decoding.</li>
  <li><a href="https://arxiv.org/abs/1211.3711" target="_blank" rel="noopener">Sequence Transduction with Recurrent Neural Networks</a> — RNN-T lattice, forward–backward and alignment marginalization.</li>
  <li><a href="https://arxiv.org/abs/1512.02595" target="_blank" rel="noopener">Deep Speech 2</a> — Table 13 evaluation and human reference.</li>
  <li><a href="https://arxiv.org/abs/1904.08779" target="_blank" rel="noopener">SpecAugment</a> — Table 3 LAS baselines and LM conditions.</li>
  <li><a href="https://arxiv.org/abs/2005.08100" target="_blank" rel="noopener">Conformer</a> — Conformer-L Transducer evaluation.</li>
  <li><a href="https://arxiv.org/abs/1503.03535" target="_blank" rel="noopener">On Using Monolingual Corpora in Neural Machine Translation</a> — shallow and deep fusion.</li>
  <li><a href="https://arxiv.org/abs/1708.06426" target="_blank" rel="noopener">Cold Fusion: Training Seq2Seq Models Together with Language Models</a> — training with a fixed pretrained LM.</li>
  <li><a href="https://arxiv.org/abs/1810.04805" target="_blank" rel="noopener">BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding</a> — bidirectional masked language modeling.</li>
</ul>
