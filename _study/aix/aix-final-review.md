---
layout: default
date: 2026-06-08 18:13:14 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "AIX Final Review"
course: "AIX"
topic: "Final Exam Preparation Materials"
order: 12
major_topic: "Artificial Intelligence"
keywords:
  - "Optimization"
  - "Deep Learning"
  - "Self-Attention"
  - "Autonomous Driving"
  - "Robot Learning"
---

# AIX Final Review

Source Materials:

<ul>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-before-midterm/" | relative_url }}">AIX Quiz Review Before Midterm</a></li>
  <li><a href="{{ "/study/aix/aix-midterm-review/" | relative_url }}">AIX: Midterm Review</a></li>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-after-midterm/" | relative_url }}">AIX Quiz Review After Midterm</a></li>
  <li><a href="{{ "/study/aix/robotics-1/" | relative_url }}">Robotics 1</a></li>
  <li><a href="{{ "/study/aix/robotics-2/" | relative_url }}">Robotics 2</a></li>
</ul>

이 글에서는 같은 ‘예측’도 무엇을 맞히느냐에 따라 어떻게 달라지는지 살펴봅니다. 회귀 모델은 숫자를, 언어 모델은 이어질 글 조각을, 모방학습을 한 로봇은 다음 행동을 예측합니다.

언어 모델은 방금 고른 단어를 읽고 다음 단어를 고릅니다. 로봇도 방금 취한 행동 때문에 다음에 보게 될 장면이 달라집니다. 한 번 잘 맞히는 능력과 여러 번 연속해서 잘 선택하는 능력이 왜 다른지 연결해 볼 수 있습니다.

> **핵심:** 먼저 모델이 무엇을 입력받고 어떤 답을 내야 하는지 정합니다. 그다음 예측이 틀렸을 때의 영향을 봅니다. 집값을 높게 예측하면 오차 하나가 남지만, 로봇이 핸들을 잘못 돌리면 다음에 카메라에 잡히는 도로부터 달라집니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 범위 | 기말 대비 핵심 질문 |
|---:|---|---|
| 1 | Linear Regression | feature, target, residual, squared loss, gradient update를 구분할 수 있습니까? |
| 2 | Logistic Regression | sigmoid를 통해 linear score를 class probability로 바꾸는 이유는 무엇입니까? |
| 3 | MLP와 Deep Learning | hidden layer, nonlinearity, backpropagation, generalization의 역할은 무엇입니까? |
| 4 | Computer Vision | pixel을 meaning으로 연결한다는 말과 CNN의 장점은 무엇입니까? |
| 5 | NLP와 Word2Vec | tokenizer, embedding, Skip-Gram, pre-training, fine-tuning을 구분할 수 있습니까? |
| 6 | RNN과 Attention | sequential dependency와 global relationship의 차이는 무엇입니까? |
| 7 | Transformer | Q/K/V, self-attention, multi-head attention, positional encoding의 역할은 무엇입니까? |
| 8 | LLM | next token prediction, decoder-only Transformer, MoE, decoding 전략을 설명할 수 있습니까? |
| 9 | Autonomous Driving | modular stack, error propagation, occupancy, shared world representation을 구분할 수 있습니까? |
| 10 | Imitation Learning | behavioral cloning과 DAggER가 state distribution shift를 어떻게 다룹니까? |
| 11 | Robotics Scaling | VLA, ego-video, world model, action fine-tuning, physical RL을 하나의 흐름으로 묶을 수 있습니까? |

</details>

## 0. 우선순위

기말고사 준비에서는 모든 개념을 같은 깊이로 보지 않습니다. 다음 순서로 공부합니다.

| 우선순위 | 자료 | 공부 방식 |
|---|---|---|
| 1 | After Midterm Quiz Review | 기말 직전 퀴즈 범위이므로 문항별 정답 기준을 거의 그대로 암기합니다. |
| 2 | Robotics 1, Robotics 2 | after-midterm의 imitation learning, DAggER, VLA, world model, physical RL 문항을 설명형으로 풀 수 있게 보강합니다. |
| 3 | Midterm Review | 이미 출제된 핵심 개념의 오답 제거 기준을 다시 봅니다. 같은 개념이 기말에 변형될 수 있습니다. |
| 4 | Before Midterm Quiz Review | 기본 정의와 구조를 빠르게 복습합니다. 특히 Transformer 이전 흐름을 잊지 않습니다. |
| 5 | 개별 AIX 강의자료 | 헷갈리는 개념을 배경 설명으로 보강합니다. 문제 우선순위는 위 자료들이 더 높습니다. |

기말에서 특히 강하게 잡아야 할 축은 다음 네 가지입니다.

| 축 | 핵심 문장 |
|---|---|
| LLM/Transformer | GPT 계열 모델은 지금까지 쓴 글을 보고 다음 글 조각 하나를 골라 붙입니다. |
| Autonomous Driving | 보행자를 보지 못하면 경로 계획도 그 사람을 피할 수 없습니다. 인식과 계획을 나누더라도 오류는 이어집니다. |
| Imitation Learning | 전문가의 행동을 따라 배워도, 한 번 실수하면 시범에 없던 장면에서 다음 행동을 골라야 합니다. |
| Robotics Scaling | 사람의 영상에서 물체가 움직이는 법을 배울 수 있지만, 로봇 팔을 얼마나 움직일지는 행동 데이터로 따로 익혀야 합니다. |

## 핵심 수식 유도 지도

회귀식은 오차가 왜 줄어드는지, 신경망의 식은 어느 매개변수가 오차에 얼마나 영향을 주는지 설명합니다. 아래 표에서 필요한 식만 찾아볼 수 있습니다. 상세 계산은 [Linear and Logistic Regression](/study/aix/linear-logistic-regression/), [Multi-Layer Perceptron](/study/aix/multi-layer-perceptron/), [Transformer Architecture Overview](/study/aix/transformer-architecture-overview/), [Large Language Models](/study/aix/large-language-models/), [Robotics 1](/study/aix/robotics-1/)에 있습니다.

<details markdown="block">
<summary markdown="span">Derivation: Model equations and their assumptions</summary>

| 수식 | 성격과 유도 핵심 | 가정·실패 조건 |
|---|---|---|
| $$w^*=(X^TX)^{-1}X^Ty$$ | squared loss를 미분해 $$X^T(Xw-y)=0$$으로 둔 **정확한 정상방정식 해** | $$X^TX$$가 가역이어야 하며, 아니면 pseudo-inverse·regularization이 필요 |
| $$\theta\leftarrow\theta-\eta\nabla L$$ | 1차 Taylor 근사에서 변화량이 $$-\eta\lVert\nabla L\rVert^2$$가 되는 하강 방향 | 국소 근사이므로 $$\eta$$가 크면 loss가 증가할 수 있음 |
| $$L_{\mathrm{BCE}}=-y\log p-(1-y)\log(1-p)$$ | Bernoulli likelihood $$p^y(1-p)^{1-y}$$의 negative log라는 **정확한 등식** | $$y\in\{0,1\}$$, $$0<p<1$$; 구현은 logit 기반 안정화 필요 |
| $$\delta_1=(W_2^T\delta_2)\odot\phi'(z_1)$$ | 합성 함수에 chain rule을 역순 적용한 backpropagation 등식 | ReLU의 0에서는 subgradient가 필요하고 포화 activation은 gradient를 약화 |
| $$\operatorname{softmax}(QK^T/\sqrt{d_k})V$$ | softmax weight의 합이 1이고 output은 value weighted sum이라는 **정의** | $$\sqrt{d_k}$$ 근거는 성분 독립·단위분산을 둔 근사적 분산 분석 |
| $$p_i(T)=e^{z_i/T}/\sum_j e^{z_j/T}$$ | $$p_i/p_j=e^{(z_i-z_j)/T}$$라서 $$T$$가 logit 간격의 효과를 조절 | $$T>0$$; $$T=0$$은 정의되지 않으며 능력 자체를 바꾸지 않음 |
| $$-\log p_c$$ | categorical likelihood에 음의 로그를 취한 one-hot cross-entropy | Label smoothing이면 $$-\sum_i y_i\log p_i$$를 사용 |
| $$T\epsilon$$ 대 $$O(T^2\epsilon)$$ | 전자는 step 오류 기대합, 후자는 $$\sum_{t=1}^{T}O(t\epsilon)$$인 **보수적 compounding-error 상한** | 정확한 관측 등식이 아니며 bounded cost와 단순화된 오류율 가정 필요 |

여기서 $$T$$는 문맥에 따라 temperature 또는 horizon을 뜻하므로 반드시 주변 정의를 확인합니다. 전자는 무차원 양수이고, 후자는 단위 없는 step 수입니다.

</details>

**원문 대응:** after-midterm quiz 5개 PDF는 각 p.1-3에 LLM·autonomous driving·imitation learning·robotics scaling 문항을 제시하지만 별도의 수식 증명은 싣지 않습니다. 위 표의 계산 근거는 `1st_Regression.pdf` p.10-25, `02_MLP.pdf` p.11-24, `2_Overview_TF.pdf` p.10-20, `3_Large_Language_Models.pdf` p.17-48, `Robotics_1.pdf` p.9-15에 대응합니다. 즉 퀴즈 정답 범위를 넘어선 전개는 각 상세 강의 글에서 원문 직접 제시식과 저자 보충을 구분해 검산합니다.

## 1. Linear Regression과 Optimization

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/linear-regression-slide-08.png" | relative_url }}" alt="AIX Regression 원본 슬라이드 8쪽. residual 합과 squared residual sum 비교." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/1st_Regression.pdf#page=8" | relative_url }}" target="_blank" rel="noopener"><code>1st_Regression.pdf</code> p.8</a> — 오차 부호 상쇄를 피하려 squared loss를 쓰는 출발점.</figcaption>
</figure>

그림의 첫 식은 오차를 그대로 더합니다. 예를 들어 한 값을 2만큼 높게, 다른 값을 2만큼 낮게 예측하면 두 번 다 틀렸는데도 합은 0입니다. 둘째 식처럼 제곱해서 더하면 4와 4를 더한 8이 남습니다. 이 값을 줄여야 두 예측이 실제 값에 가까워집니다.

선형 회귀(linear regression)는 관측한 값으로 다른 수치를 예측합니다. 예를 들어 집의 면적으로 집값을 추정한다면 면적은 입력 특성(feature), 실제 거래 가격은 맞히려는 값(target)입니다. 입력을 $$x$$, 예측값을 $$\hat y$$라고 쓰면 다음과 같습니다.

$$
\hat{y}=w^Tx+b
$$

Residual은 실제값과 예측값의 차이입니다.

$$
residual=y-\hat{y}
$$

대표 loss는 residual의 제곱합입니다.

$$
L(w,b)=\sum_i (y_i-\hat{y}_i)^2
$$

시험에서는 이 세 가지를 헷갈리지 않아야 합니다.

| 개념 | 한 줄 정리 | 오답 제거 기준 |
|---|---|---|
| feature | 모델의 입력 정보, 보통 $$x$$ | $$y$$를 feature라고 하면 틀림 |
| target | 예측해야 하는 정답, 보통 $$y$$ | $$x$$를 target이라고 하면 틀림 |
| score | $$w^Tx+b$$ 형태의 선형 출력 | weight와 feature의 가중합 구조가 없으면 의심 |
| residual | $$y-\hat{y}$$ | loss와 같은 말이 아님 |
| squared loss | residual을 제곱해 합친 objective | 부호가 상쇄되지 않게 제곱 |
| iterative update | loss를 줄이도록 parameter를 반복 갱신 | closed-form처럼 한 번에 끝나는 방식이 아님 |

Gradient descent는 loss를 줄이기 위해 gradient의 반대 방향으로 이동합니다.

$$
\theta \leftarrow \theta-\eta\nabla_\theta L(\theta)
$$

여기서 $$\eta$$는 learning rate입니다. Gradient는 증가 방향이고, minimization에서는 그 반대 방향으로 움직인다는 점이 중요합니다.

## 2. Logistic Regression과 Classification

Logistic Regression은 linear score를 버리지 않습니다. 먼저 score를 계산합니다.

$$
z=w^Tx+b
$$

그 다음 sigmoid를 적용해 0과 1 사이의 probability로 바꿉니다.

$$
\sigma(z)=\frac{1}{1+e^{-z}}
$$

$$
P(y=1\mid x)=\sigma(w^Tx+b)
$$

시험에서 logistic regression을 설명할 때는 다음 문장을 잡으면 됩니다.

> 점수가 0이면 두 결과를 반반으로 봅니다. 점수가 커질수록 결과가 1일 확률이 높아지지만, 확률이 1을 넘지는 않습니다. 이 변환을 하는 함수가 시그모이드(sigmoid)입니다.

| 비교 | Linear Regression | Logistic Regression |
|---|---|---|
| 출력 | 실수 예측값 | class probability |
| 기본 식 | $$\hat{y}=w^Tx+b$$ | $$P(y=1\mid x)=\sigma(w^Tx+b)$$ |
| 대표 목적 | squared residual 감소 | observed label이 most likely 하도록 학습 |
| decision boundary | 회귀에서는 직접 경계가 핵심이 아님 | $$w^Tx+b=0$$이면 기본적으로 선형 경계 |

다중 class에서는 softmax를 사용합니다. Softmax는 여러 class score를 합이 1인 확률 분포로 바꿉니다.

$$
p_k=\frac{\exp(z_k)}{\sum_j \exp(z_j)}
$$

## 3. MLP와 Deep Learning

Single perceptron은 기본적으로 선형 경계를 만듭니다. XOR처럼 선형 분리가 안 되는 문제는 하나의 직선으로 해결할 수 없습니다. MLP는 hidden layer와 nonlinear activation을 추가해 더 복잡한 패턴을 표현합니다.

| 개념 | 핵심 역할 |
|---|---|
| hidden layer | 입력과 출력 사이의 중간 표현을 만듭니다. |
| activation | 선형 변환 사이에 비선형성을 부여합니다. |
| ReLU | 양수 구간 gradient가 일정해 sigmoid보다 vanishing gradient 문제가 덜합니다. |
| backpropagation | chain rule로 각 parameter의 gradient를 효율적으로 계산합니다. |
| gradient descent | 계산된 gradient로 parameter를 업데이트합니다. |

Backpropagation과 gradient descent는 같은 말이 아닙니다.

| 용어 | 역할 |
|---|---|
| backpropagation | gradient를 계산하는 방법 |
| gradient descent | gradient를 이용해 parameter를 갱신하는 최적화 방법 |

훈련에 사용한 사진을 모두 맞혀도 처음 보는 사진을 틀릴 수 있습니다. 목표는 훈련 오차만 줄이는 것이 아니라 새 입력에서도 잘 맞히는 것, 즉 일반화입니다. 모델이 너무 단순하면 반복되는 특징을 놓치고, 너무 복잡하면 우연한 차이까지 외울 수 있습니다.

Deep learning의 발전은 한 가지 요소로 설명하지 않습니다.

$$
\text{Deep Learning Progress}
\approx
\text{Data}
+
\text{Computation}
+
\text{Algorithms}
$$

## 4. Computer Vision

사진 파일에는 각 위치의 밝기나 색이 숫자로 들어 있습니다. 컴퓨터 비전의 목표는 이 숫자를 보고 ‘횡단보도 위에 사람이 있다’처럼 무엇이 어디에 있는지 알아내는 것입니다.

| 개념 | 시험 기준 |
|---|---|
| pixel-to-meaning | 이미지의 raw pixel을 object, scene, relation, meaning으로 해석 |
| feature engineering | 사람이 유용한 feature를 직접 설계 |
| learned feature | deep learning이 데이터에서 feature를 학습 |
| CNN | local connectivity와 weight sharing으로 이미지 패턴을 효율적으로 학습 |
| AlexNet | CNN 기반 딥러닝이 전통적 CV를 넘어선 전환점 |
| visual reasoning | 객체, 관계, 언어, 문맥을 함께 이해하는 structured understanding |

사진 왼쪽과 오른쪽에 있는 모서리를 찾는 데 서로 다른 규칙이 필요할까요? CNN은 이웃한 픽셀 몇 개를 보고 모서리 같은 특징을 찾은 뒤, 같은 검출 규칙(필터)을 다른 위치에도 적용합니다. 이 덕분에 위치마다 규칙을 처음부터 배울 필요가 없습니다.

최근 vision에서는 classification만이 아니라 generation과 3D understanding도 중요해집니다.

| 주제 | 핵심 정리 |
|---|---|
| diffusion models | 최근 image/video generation의 대표적 주류 |
| 3D vision | geometry, pose, spatial relationship을 다루며 point cloud, voxel, mesh 등 representation이 다양 |

## 5. NLP, Tokenizer, Word2Vec

NLP에서 text는 바로 model에 들어가지 않습니다. 먼저 tokenizer가 문장을 token으로 나누고 vocabulary 항목에 대응시킵니다.

| 개념 | 역할 |
|---|---|
| tokenizer | 문장을 token으로 나누고 vocabulary index로 대응 |
| one-hot | vocabulary size 차원의 sparse vector |
| learned embedding | 의미 관계를 담을 수 있는 dense vector |
| subword | rare word와 OOV 문제를 줄이는 부분 단어 단위 |

사람이 모든 단어의 뜻을 숫자로 지정하기는 어렵습니다. Word2Vec은 대신 문장에서 어떤 단어들이 함께 나오는지를 학습합니다. 비슷한 문맥에서 쓰이는 단어는 비슷한 예측을 해야 하므로, 학습 후 각 단어를 나타내는 숫자 목록(임베딩)에 쓰임의 차이가 반영됩니다.

Skip-Gram은 중심 단어를 보고 주변 context 단어를 예측합니다.

$$
\text{center word}\rightarrow\text{context words}
$$

Pre-training과 fine-tuning도 반드시 구분해야 합니다.

| 단계 | 의미 |
|---|---|
| pre-training | 큰 데이터로 일반적인 base representation을 학습 |
| fine-tuning | pretrained model을 특정 task에 맞게 조정 |
| task-specific era | task마다 별도 모델을 from scratch로 학습 |

## 6. RNN과 Attention

RNN은 sequence를 시간 순서대로 처리합니다.

$$
h_t=f(x_t,h_{t-1})
$$

여기서 $$h_t$$는 지금까지 읽은 내용을 다음 단계로 넘기는 값입니다. 세 번째 단어를 처리하려면 두 번째 단어를 읽고 남긴 값이 먼저 필요합니다. 긴 문장일수록 첫 단어의 정보가 마지막까지 여러 단계를 거쳐야 합니다.

어텐션(attention)은 지금 해석하는 단어와 관련된 다른 단어를 직접 참조합니다. 예컨대 ‘수진이가 책을 샀고 그것을 읽었다’에서 ‘그것’을 이해하려면 바로 앞 단어보다 멀리 있는 ‘책’이 더 중요합니다.

| 비교 | RNN | Attention |
|---|---|---|
| 계산 구조 | 현재 입력과 이전 hidden state로 update | token-to-token 관계를 직접 계산 |
| 장점 | 구조가 비교적 단순하고 sequence 처리 직관적 | global relationship과 긴 문맥에 강함 |
| 약점 | long dependency와 병렬 처리에 불리 | 모든 관계 계산으로 비용이 커질 수 있음 |
| 시험 키워드 | sequential dependency, hidden state | global relationship, direct reference |

## 7. Transformer와 Self-Attention

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/transformer-slide-13.png" | relative_url }}" alt="AIX Transformer 원본 슬라이드 13쪽. position-aware embedding에서 Q K V를 만들고 attention을 계산하는 예시." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf#page=13" | relative_url }}" target="_blank" rel="noopener"><code>2_Overview_TF.pdf</code> p.13</a> — token 표현이 Q·K·V로 나뉘어 관계 점수와 value 조합을 만드는 과정.</figcaption>
</figure>

그림은 단어 하나를 해석할 때 다른 단어들의 정보를 얼마나 가져오는지 보여 줍니다. 먼저 현재 단어가 찾는 정보(Q)를 각 단어의 표지(K)와 비교합니다. 그런 다음 관련도가 높은 단어의 내용(V)에 더 큰 비중을 주어 합칩니다. 관련도를 정하는 값과 실제로 가져오는 값이 다르다는 점이 핵심입니다.

Transformer는 token embedding, self-attention, multi-head attention, positional encoding을 결합합니다.

Self-attention의 핵심 식은 다음과 같습니다.

$$
\text{Attention}(Q,K,V)
=
\operatorname{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V
$$

| 구성 | 역할 |
|---|---|
| Query $$Q$$ | 현재 token이 무엇을 찾는지 나타냄 |
| Key $$K$$ | 각 token이 어떤 정보를 갖는지 비교 기준 제공 |
| Value $$V$$ | attention weight로 실제 가져오는 정보 |
| $$QK^T$$ | token 간 관련도 점수 계산 |
| softmax | 관련도 점수를 attention weight로 정규화 |
| positional encoding | self-attention만으로 부족한 순서 정보를 보강 |
| multi-head attention | 여러 head가 서로 다른 관계나 패턴을 병렬로 봄 |

Q와 K는 dot product를 해야 하므로 차원이 같아야 합니다. V는 관련도 점수 계산이 아니라 최종 출력 표현을 만들 때 사용됩니다.

시험에서는 다음 오답을 조심합니다.

| 오답 유형 | 왜 틀렸습니까 |
|---|---|
| self-attention이 tokenization을 대신합니다 | tokenization은 전처리, self-attention은 모델 내부 연산입니다. |
| self-attention만으로 순서를 완벽히 압니다 | 순서 정보를 위해 positional encoding이 필요합니다. |
| multi-head attention은 token 수를 줄입니다 | 여러 관계 패턴을 병렬로 보는 것이 핵심입니다. |
| Q/K/V가 모두 같은 역할입니다 | Q/K는 관련도 계산, V는 정보 출력에 쓰입니다. |

## 8. LLM, MoE, Decoding

LLM은 지금까지의 token을 조건으로 다음 token 하나를 예측하고, 이를 반복해 문장을 생성합니다.

$$
P(x_t\mid x_1,x_2,\ldots,x_{t-1})
$$

GPT 계열 LLM은 주로 decoder-only Transformer이며, autoregressive generation을 수행합니다.

| 개념 | 핵심 설명 |
|---|---|
| next token prediction | 이전 token sequence를 보고 다음 token 확률분포를 계산 |
| autoregressive generation | 생성한 token을 다시 문맥에 붙이고 반복 |
| decoder-only Transformer | causal attention으로 이전 token만 참고하며 다음 token 예측 |
| cross-entropy loss | 정답 token 확률을 높이도록 학습 |

Decoding 방식도 구분해야 합니다.

| 방식 | 핵심 | 장점 | 한계 |
|---|---|---|---|
| greedy decoding | 매 step 가장 확률 높은 token 하나 선택 | 빠르고 단순 | 전체 문장 최적 보장 없음 |
| beam search | 가능성 높은 $$k$$개 후보 sequence 유지 | greedy보다 좋은 전체 후보 탐색 가능 | 비용 증가, 다양성 제한 가능 |

모델 안에 계산을 나누어 맡는 작은 신경망(expert)을 여러 개 두고, 단어 조각마다 그중 일부만 골라 쓸 수 있습니다. 어떤 신경망을 쓸지 정하는 부분이 라우터(router)입니다. 이런 MoE 방식은 매번 모든 신경망을 실행하지 않고도 모델에 더 많은 매개변수를 담을 수 있습니다.

| 개념 | 시험 기준 |
|---|---|
| expert | 특정 계산을 담당하는 sub-network |
| router | token마다 사용할 expert를 선택 |
| sparse activation | 모든 expert가 아니라 일부 expert만 활성화 |
| 장점 | 모델 capacity는 키우면서 계산 비용을 상대적으로 줄임 |

## 9. Autonomous Driving

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/autonomous-driving-2-slide-26.png" | relative_url }}" alt="AIX Autonomous Driving 2 원본 슬라이드 26쪽. 공유 world representation에서 여러 queryable task output이 갈라지는 구조." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf#page=26" | relative_url }}" target="_blank" rel="noopener"><code>Autonomous_Driving_2.pdf</code> p.26</a> — multi-camera와 temporal feature를 공유 world representation으로 통합하는 중심 구조.</figcaption>
</figure>

그림 가운데로 들어오는 선은 여러 카메라와 여러 시각에 관측한 정보를 나타냅니다. 이 관측으로 도로 주변의 상태를 한 번 추정해 두면, 서로 다른 기능이 같은 표현에서 ‘어디에 장애물이 있는가?’, ‘어느 공간이 비어 있는가?’에 필요한 정보를 꺼낼 수 있습니다.

자율주행은 단순 제어 문제가 아니라 perception과 uncertainty가 큰 AI 문제입니다. 도로에는 차량, 보행자, 차선, 신호, 날씨, 가려짐, corner case가 섞여 있습니다.

전통적 구조는 modular stack입니다.

$$
\text{Perception}
\rightarrow
\text{Prediction}
\rightarrow
\text{Planning}
\rightarrow
\text{Control}
$$

| 모듈 | 역할 |
|---|---|
| perception | 주변 객체, 차선, 도로 구조 인식 |
| prediction | 다른 agent의 미래 움직임 예측 |
| planning | ego vehicle의 경로와 행동 계획 |
| control | 조향, 가감속 등 실제 제어 명령 생성 |

Modular stack의 장점은 해석 가능성과 모듈별 개발입니다. 하지만 앞단 오류가 뒤 단계로 전파될 수 있습니다. Perception에서 보행자를 놓치면 prediction, planning, control도 잘못된 입력을 바탕으로 동작합니다.

Tesla식 전환에서 핵심은 object list에서 occupancy/shared world representation으로 이동한 것입니다.

| 표현 | 특징 |
|---|---|
| object list | 알려진 object class를 검출하고 목록화 |
| occupancy | 공간이 차 있는지, 비어 있는지, 주행 가능한지 표현 |
| shared world representation | 여러 task가 공유하는 unified latent world state |
| representation-level end-to-end | 카메라에서 조향까지 단순 직결이 아니라 world representation을 통합적으로 학습 |

Occupancy는 object 이름만이 아니라 geometry, free space, semantics를 함께 다뤄 planning과 연결하기 좋습니다.

## 10. Imitation Learning과 DAggER

Imitation learning은 expert demonstration을 사용해 비싸고 위험한 trial-and-error를 줄입니다. 특히 실제 로봇에서는 시행착오가 비용과 안전 문제를 만들기 때문에 expert trajectory가 중요합니다.

행동 복제(behavioral cloning)에서는 전문가가 본 장면과 그때 취한 행동을 한 쌍으로 저장합니다. 예를 들어 카메라 영상이 입력이고, 운전자가 그 순간 선택한 조향각이 정답입니다.

$$
o\rightarrow a
$$

즉 observation을 입력으로 받고 expert action을 label로 삼아 policy를 학습합니다.

사진을 잘못 분류해도 다음 사진은 바뀌지 않습니다. 반면 차가 왼쪽으로 조금 치우치면 다음 영상에는 차선이 평소와 다른 위치에 잡힙니다. 차선 중앙을 달리는 시범만 보았다면, 이제 필요한 것은 훈련 때 거의 보지 못한 복귀 동작입니다.

| 문제 | 설명 |
|---|---|
| covariate shift | 학습 때 본 state와 실행 중 방문하는 state 분포가 달라짐 |
| compounding error | 작은 행동 오류가 다음 state를 바꾸고 이후 오류가 누적됨 |
| state distribution shift | learner의 action 때문에 test-time state distribution이 expert data와 달라짐 |

DAggER는 모델이 실제로 마주친 장면을 학습에 다시 씁니다. 차가 왼쪽으로 치우친 장면을 저장하고, 그 장면에서 어떻게 조향해야 할지 전문가에게 묻습니다. 그 답을 기존 시범에 추가해 학습하면, 중앙을 유지하는 행동뿐 아니라 벗어났을 때 돌아오는 행동도 익힐 수 있습니다.

$$
\text{run learner}
\rightarrow
\text{collect states}
\rightarrow
\text{ask expert labels}
\rightarrow
\text{aggregate data}
\rightarrow
\text{retrain}
$$

따라서 정상 주행 시범을 더 많이 모으는 일과, 실제 실수가 일어난 장면에 복귀 방법을 붙이는 일은 서로 다릅니다.

| Robotics 1 활용 지점 | Final Review에서 연결되는 개념 |
|---|---|
| Why imitation became attractive | physical robot에서 RL trial-and-error가 비싸고 느림 |
| Behavioral cloning | expert trajectory를 observation-to-action supervised learning으로 변환 |
| Covariate shift | learner action이 다음 state distribution을 바꿈 |
| Error growth | independent error보다 sequential error가 더 크게 누적 가능 |
| DAggER | learner-visited state에 expert label을 붙여 aggregate/retrain |
| Remaining bottleneck | task-specific imitation의 한계가 foundation model, world model, VLA로 이어짐 |

## 11. Robotics Scaling과 VLA

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/robotics-2-slide-33.png" | relative_url }}" alt="AIX Robotics 2 원본 슬라이드 33쪽. robot pretraining data 규모별 validation loss 곡선과 최적 loss 추세." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/Robotics_2.pdf#page=33" | relative_url }}" target="_blank" rel="noopener"><code>Robotics_2.pdf</code> p.33</a> — 사전학습 데이터 시간이 커질수록 validation loss가 낮아지는 scaling 근거.</figcaption>
</figure>

왼쪽 곡선은 더 큰 dataset이 같은 training step에서 낮은 loss를 보이는지 비교하고, 오른쪽은 각 규모의 최적점을 요약합니다. Robotics scaling은 모델 크기만 키우는 주장이 아니라 다양한 행동 데이터의 시간과 범위를 함께 늘리는 전략입니다.

로보틱스는 AI scaling의 다음 frontier로 설명됩니다. LLM에서 대규모 데이터와 foundation model이 성능 향상을 만들었듯이, 로봇도 대규모 비디오, world model, action data, physical RL을 결합하는 방향으로 이동합니다.

VLA는 Vision-Language-Action입니다.

| 구성 | 의미 |
|---|---|
| Vision | 이미지나 비디오로 장면을 인식 |
| Language | 자연어 지시나 목표를 이해 |
| Action | 실제 로봇 행동을 출력 |

사람 시점의 영상에는 손잡이를 당겼더니 서랍이 열리는 모습이 담길 수 있습니다. 영상만으로도 어떤 동작이 가능한지, 그 뒤 물체가 어떻게 움직이는지 배울 단서가 생깁니다. 다만 영상에는 로봇 관절을 몇 도 움직이라는 정답이 없습니다. 장면 이해와 실제 동작 학습을 구분하는 이유입니다.

| 흐름 | 설명 |
|---|---|
| world model | 물리 세계의 상태 변화와 상호작용을 학습 |
| action fine-tuning | vision/language 기반 모델을 robot action에 맞게 조정 |
| physical RL | 실제 환경에서 시행착오를 통해 행동 성능 보정 |

기말에서는 이 흐름을 하나의 문장으로 정리하면 좋습니다.

> 로보틱스는 pre-trained world/foundation model 위에 action 적응과 실제 환경 학습을 더하는 방향으로 scaling됩니다.

Robotics 2는 이 문장을 세 단계로 더 구체화합니다.

| Robotics 2 활용 지점 | Final Review에서 연결되는 개념 |
|---|---|
| LLM-to-robotics parallel | pre-training, action fine-tuning, physical RL의 대응 관계 |
| VLA | vision-language-action을 연결하는 robot backbone |
| Video pre-training | internet video와 ego-video가 dynamics, contact, affordance 단서를 제공 |
| WAM | 단순 action mapping보다 world modeling을 first-class로 둠 |
| Data engines | teleoperation, autonomous rollout, ego-video의 trade-off |
| Physical RL | teleoperation imitation을 넘어서는 surpassing phase |
| Real2Sim2Real | digital twins/cousins로 training universe를 확장 |

## 12. 오답 제거 기준

| 문항 유형 | 정답 방향 | 흔한 오답 |
|---|---|---|
| Linear regression | $$x$$는 feature, $$y$$는 target | $$x$$와 $$y$$ 역할을 뒤집음 |
| Logistic regression | score를 sigmoid로 probability화 | linear score를 버린다고 설명 |
| MLP | hidden layer와 nonlinearity | layer만 많으면 비선형이라고 착각 |
| Backpropagation | chain rule로 gradient 계산 | parameter update 자체와 혼동 |
| Computer Vision | pixel-to-meaning | 이미지 압축이나 저장 효율로 설명 |
| CNN | local connectivity, weight sharing | 모든 pixel을 독립 fully-connected로 연결 |
| Word2Vec | proxy task와 hidden embedding | 사람이 의미를 직접 넣는다고 설명 |
| RNN | 이전 hidden state에 의존 | 순서를 무시한다고 설명 |
| Attention | global relationship 직접 계산 | tokenization을 대신한다고 설명 |
| Transformer | Q/K/V와 positional encoding | self-attention만으로 순서 정보를 완전히 해결 |
| LLM | next token prediction 반복 | 문장 전체를 한 번에 완성한다고 설명 |
| MoE | token별 일부 expert 활성화 | 모든 expert를 항상 사용 |
| Modular driving | error propagation 가능 | 모듈 분리라 오류 전파가 없다고 설명 |
| Tesla end-to-end | representation-level end-to-end | 카메라에서 steering까지 무조건 직접 연결만 의미 |
| Behavioral cloning | observation-to-action supervised learning | reward만 보고 학습한다고 설명 |
| DAggER | learner state에 expert label 추가 | expert demonstration만 단순히 더 모음 |
| VLA | vision/language에서 action까지 연결 | vision-language 이해에서 끝난다고 설명 |

## 마지막 핵심 정리

| 주제 | 무엇을 기억하면 좋을까요? |
|---|---|
| 선형 회귀 | 실제 값과 예측값의 차이를 제곱합니다. 너무 높게 예측한 오차와 너무 낮게 예측한 오차가 서로 지워지지 않습니다. |
| 로지스틱 회귀 | 선형 점수를 두 결과 중 하나일 확률로 바꿉니다. |
| 다층 퍼셉트론(MLP) | 중간 층의 비선형 함수 덕분에 직선 하나로 나눌 수 없는 사례도 구분할 수 있습니다. |
| 역전파와 경사 하강법 | 역전파는 각 가중치가 오차에 미치는 영향을 계산합니다. 경사 하강법은 그 계산 결과로 가중치를 바꿉니다. |
| 컴퓨터 비전 | 픽셀의 밝기와 색에서 사람이 어디에 있고 무엇을 하는지 같은 정보를 읽습니다. |
| 자연어 처리 | 토크나이저는 문장을 조각으로 나누고, 임베딩은 각 조각을 계산에 쓸 수 있는 숫자 목록으로 나타냅니다. |
| Word2Vec | 단어가 함께 등장하는 패턴으로 단어의 표현을 배웁니다. |
| 순환 신경망(RNN) | 앞부분을 읽고 남긴 값을 받아서 다음 단어를 처리합니다. |
| 어텐션 | 현재 단어를 해석하는 데 도움이 되는 다른 단어에서 정보를 더 많이 가져옵니다. |
| 트랜스포머 | 어텐션으로 여러 관계를 함께 살피고, 위치 정보로 단어의 순서를 구별합니다. |
| GPT 계열 언어 모델 | 지금까지의 문맥에서 다음 조각을 예측하고, 고른 조각을 새 문맥에 넣습니다. |
| MoE | 여러 신경망 중 입력 조각마다 일부만 골라 계산합니다. |
| 자율주행 | 인식 오류는 경로 계획에도 영향을 줍니다. 공간의 점유 여부를 알면 물체 이름을 몰라도 장애물이 있는 칸을 파악할 수 있습니다. |
| 모방학습 | 시범을 벗어난 뒤에는 원래 경로로 돌아오는 행동이 필요합니다. DAggER는 그런 장면도 학습 자료에 넣습니다. |
| 로봇 학습 | 영상에서 장면의 변화를 배우는 일과, 자기 몸으로 그 변화를 만들어 내는 행동을 배우는 일은 다릅니다. |

## Study Guide

먼저 `After Midterm Quiz Review`를 외웁니다. 20260521부터 20260605까지의 퀴즈는 기말 직전 범위이므로, 문항별 핵심 정답 키워드를 먼저 잡는 것이 효율적입니다.

그다음 `Robotics 1`, `Robotics 2`를 읽어 after-midterm quiz의 로보틱스 문항을 설명형으로 바꿔 말해 봅니다. `Robotics 1`은 behavioral cloning과 DAggER, `Robotics 2`는 VLA, world model, data engine, physical RL을 보강합니다.

그다음 `Midterm Review`의 전체 정답 체크리스트를 빠르게 훑습니다. 이미 중간고사에서 다룬 기본 개념이라도, 기말에서는 LLM과 자율주행, 로보틱스 개념을 이해하기 위한 기반으로 다시 등장할 수 있습니다.

마지막으로 `Before Midterm Quiz Review`에서 기본 정의를 보강합니다. 특히 logistic regression, MLP, RNN, attention, Transformer는 뒤쪽 범위의 언어모델과 로봇 foundation model을 이해하는 뼈대입니다.

| 공부 순서 | 할 일 |
|---:|---|
| 1 | After-midterm 5개 quiz의 핵심 정답 키워드를 암기합니다. |
| 2 | Robotics 1/2로 imitation learning, DAggER, VLA, WAM, physical RL을 보강합니다. |
| 3 | LLM, 자율주행, imitation learning, robotics scaling을 설명형 문장으로 말해 봅니다. |
| 4 | Midterm Review의 오답 제거 기준을 보고 헷갈리는 선택지를 제거하는 연습을 합니다. |
| 5 | Before-midterm의 기본 ML/CV/NLP/Transformer 정의를 빠르게 복습합니다. |
| 6 | 복습 질문을 닫은 상태로 먼저 답하고, 펼쳐서 답변을 확인합니다. |

## 복습 질문

<details markdown="block">
<summary>1. Linear regression에서 feature와 target은 무엇입니까?</summary>

답변: Feature는 모델의 입력 정보이고 보통 $$x$$로 둡니다. Target은 예측해야 하는 정답이고 보통 $$y$$로 둡니다.

</details>

<details markdown="block">
<summary>2. Logistic regression은 왜 classification에 적합합니까?</summary>

답변: Linear score $$w^Tx+b$$를 sigmoid에 넣어 0과 1 사이 값으로 바꾸므로 binary class probability로 해석할 수 있기 때문입니다.

</details>

<details markdown="block">
<summary>3. MLP가 single perceptron보다 강한 이유는 무엇입니까?</summary>

답변: Hidden layer와 nonlinear activation을 사용하므로 single perceptron이 만들 수 없는 복잡한 비선형 패턴을 표현할 수 있기 때문입니다.

</details>

<details markdown="block">
<summary>4. Backpropagation과 gradient descent는 어떻게 다릅니까?</summary>

답변: Backpropagation은 chain rule로 gradient를 계산하는 방법이고, gradient descent는 그 gradient를 이용해 parameter를 갱신하는 최적화 방법입니다.

</details>

<details markdown="block">
<summary>5. Computer Vision의 high-level 목표는 무엇입니까?</summary>

답변: 밝기와 색으로 기록된 픽셀에서 ‘보행자가 횡단보도를 건넌다’처럼 물체와 장면의 관계를 알아내는 것입니다.

</details>

<details markdown="block">
<summary>6. CNN이 이미지 처리에 적합한 이유는 무엇입니까?</summary>

답변: 모서리를 찾는 규칙은 사진 왼쪽에서도 오른쪽에서도 쓸 수 있습니다. CNN은 가까운 픽셀을 묶어 보고 같은 필터를 여러 위치에서 쓰므로 위치마다 별도의 규칙을 배울 필요가 없습니다.

</details>

<details markdown="block">
<summary>7. Tokenizer와 embedding은 어떻게 다릅니까?</summary>

답변: Tokenizer는 문장을 token으로 나누고 vocabulary 항목에 대응시키는 과정입니다. Embedding은 token을 의미 관계를 담을 수 있는 dense vector로 바꾸는 표현입니다.

</details>

<details markdown="block">
<summary>8. Skip-Gram은 어떤 task입니까?</summary>

답변: 중심 단어 하나를 보고 주변 context 단어를 예측하는 Word2Vec의 proxy task입니다.

</details>

<details markdown="block">
<summary>9. RNN이 긴 sequence에서 어려움을 겪는 이유는 무엇입니까?</summary>

답변: 정보가 hidden state를 따라 순차적으로 전달되므로 먼 과거 정보가 뒤쪽까지 유지되기 어렵고, 순차 계산 때문에 병렬 처리에도 불리하기 때문입니다.

</details>

<details markdown="block">
<summary>10. Attention이 RNN보다 global relationship을 잘 보는 이유는 무엇입니까?</summary>

답변: Attention은 각 token이 다른 token들과의 관련도를 직접 계산해 필요한 정보를 바로 참조할 수 있기 때문입니다.

</details>

<details markdown="block">
<summary>11. Transformer에서 Q, K, V의 역할은 무엇입니까?</summary>

답변: Q와 K는 dot product로 token 간 관련도 점수를 계산하는 데 쓰이고, V는 그 attention weight를 바탕으로 실제 출력 정보를 만드는 데 쓰입니다.

</details>

<details markdown="block">
<summary>12. Positional encoding이 필요한 이유는 무엇입니까?</summary>

답변: Self-attention 자체는 token 사이 관계를 보지만 순서 정보를 충분히 담지 못하므로, token의 위치와 순서를 모델에 알려 주기 위해 positional encoding을 더합니다.

</details>

<details markdown="block">
<summary>13. LLM의 next token prediction은 무엇입니까?</summary>

답변: 지금까지 생성되거나 입력된 token sequence를 조건으로 다음 token의 확률분포를 예측하고, 선택된 token을 다시 문맥에 붙여 반복 생성하는 방식입니다.

</details>

<details markdown="block">
<summary>14. Greedy decoding과 beam search는 어떻게 다릅니까?</summary>

답변: Greedy decoding은 매 step에서 확률이 가장 높은 token 하나만 고릅니다. Beam search는 가능성 높은 $$k$$개의 후보 sequence를 유지하며 더 넓게 탐색합니다.

</details>

<details markdown="block">
<summary>15. MoE의 핵심 아이디어는 무엇입니까?</summary>

답변: 모든 token이 모든 expert를 사용하는 것이 아니라, router가 token마다 필요한 expert 일부만 선택해 sparse하게 활성화하는 것입니다.

</details>

<details markdown="block">
<summary>16. Modular autonomous driving stack의 약점은 무엇입니까?</summary>

답변: Perception, prediction, planning, control이 단계별로 나뉘어 있어 해석은 쉽지만, 앞단의 오류가 뒤 단계로 전파되어 최종 주행 결과를 나쁘게 만들 수 있습니다.

</details>

<details markdown="block">
<summary>17. Tesla식 end-to-end에서 occupancy가 중요한 이유는 무엇입니까?</summary>

답변: 물체의 이름을 정확히 몰라도 앞쪽 공간이 막혀 있다는 정보는 경로 계획에 유용합니다. 점유 여부를 공간별로 표시하면 알려진 물체 목록에 없는 장애물도 나타낼 수 있습니다.

</details>

<details markdown="block">
<summary>18. Behavioral cloning이 ordinary supervised learning과 다른 이유는 무엇입니까?</summary>

답변: Robot policy의 action은 다음 state를 바꾸고, 그 결과 미래 입력 분포 자체가 달라질 수 있습니다. 일반 supervised learning보다 covariate shift와 compounding error 문제가 큽니다.

</details>

<details markdown="block">
<summary>19. DAggER는 무엇을 해결하려는 방법입니까?</summary>

답변: 모델이 실수한 뒤에 보는 장면은 전문가의 시범에 없을 수 있습니다. DAggER는 모델이 실제로 방문한 장면에서 전문가라면 어떤 행동을 할지 받아 학습 자료에 더합니다. 같은 실수가 다음 실수로 이어지는 것을 줄이려는 방법입니다.

</details>

<details markdown="block">
<summary>20. VLA는 무엇입니까?</summary>

답변: Vision-Language-Action의 약자로, 이미지나 비디오를 보고 언어 지시를 이해한 뒤 실제 로봇 action을 출력하는 로봇용 backbone입니다.

</details>

## Source Materials

<ul>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-before-midterm/" | relative_url }}">AIX Quiz Review Before Midterm</a></li>
  <li><a href="{{ "/study/aix/aix-midterm-review/" | relative_url }}">AIX: Midterm Review</a></li>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-after-midterm/" | relative_url }}">AIX Quiz Review After Midterm</a></li>
  <li><a href="{{ "/study/aix/robotics-1/" | relative_url }}">Robotics 1</a></li>
  <li><a href="{{ "/study/aix/robotics-2/" | relative_url }}">Robotics 2</a></li>
</ul>
