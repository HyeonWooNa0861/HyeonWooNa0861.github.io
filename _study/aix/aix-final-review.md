---
layout: default
date: 2026-06-08 18:13:14 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
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
  <li><a href="{{ "/study/aix/aix-midterm-review/" | relative_url }}">AIX Midterm Review</a></li>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-after-midterm/" | relative_url }}">AIX Quiz Review After Midterm</a></li>
  <li><a href="{{ "/study/aix/robotics-1/" | relative_url }}">Robotics 1</a></li>
  <li><a href="{{ "/study/aix/robotics-2/" | relative_url }}">Robotics 2</a></li>
</ul>

이 자료는 기말고사 대비용 최종 정리본이다. 문제의 중심은 `AIX Quiz Review Before Midterm`, `AIX Midterm Review`, `AIX Quiz Review After Midterm`에 두되, 새로 정리한 `Robotics 1`, `Robotics 2`는 imitation learning과 robotics scaling 파트를 깊게 이해하기 위한 핵심 보강 자료로 사용한다.

핵심 전략은 간단하다. 중간고사 전 범위는 기본 개념과 오답 제거 기준을 빠르게 확인하고, 중간고사 이후 범위는 LLM, 자율주행, imitation learning, robotics scaling을 더 깊게 본다.

> **핵심:** **Linear Regression** $$\hat{y}=w^Tx+b$$, residual은 $$y-\hat{y}$$, loss는 squared residual 중심이다. **Logistic Regression** linear score에 sigmoid를 붙여 class probability로 해석한다.

## 전체 흐름

| 순서 | 범위 | 기말 대비 핵심 질문 |
|---:|---|---|
| 1 | Linear Regression | feature, target, residual, squared loss, gradient update를 구분할 수 있는가? |
| 2 | Logistic Regression | sigmoid를 통해 linear score를 class probability로 바꾸는 이유는 무엇인가? |
| 3 | MLP와 Deep Learning | hidden layer, nonlinearity, backpropagation, generalization의 역할은 무엇인가? |
| 4 | Computer Vision | pixel을 meaning으로 연결한다는 말과 CNN의 장점은 무엇인가? |
| 5 | NLP와 Word2Vec | tokenizer, embedding, Skip-Gram, pre-training, fine-tuning을 구분할 수 있는가? |
| 6 | RNN과 Attention | sequential dependency와 global relationship의 차이는 무엇인가? |
| 7 | Transformer | Q/K/V, self-attention, multi-head attention, positional encoding의 역할은 무엇인가? |
| 8 | LLM | next token prediction, decoder-only Transformer, MoE, decoding 전략을 설명할 수 있는가? |
| 9 | Autonomous Driving | modular stack, error propagation, occupancy, shared world representation을 구분할 수 있는가? |
| 10 | Imitation Learning | behavioral cloning과 DAggER가 state distribution shift를 어떻게 다루는가? |
| 11 | Robotics Scaling | VLA, ego-video, world model, action fine-tuning, physical RL을 하나의 흐름으로 묶을 수 있는가? |

## 0. 우선순위

기말고사 준비에서는 모든 개념을 같은 깊이로 보지 않는다. 다음 순서로 공부한다.

| 우선순위 | 자료 | 공부 방식 |
|---|---|---|
| 1 | After Midterm Quiz Review | 기말 직전 퀴즈 범위이므로 문항별 정답 기준을 거의 그대로 암기한다. |
| 2 | Robotics 1, Robotics 2 | after-midterm의 imitation learning, DAggER, VLA, world model, physical RL 문항을 설명형으로 풀 수 있게 보강한다. |
| 3 | Midterm Review | 이미 출제된 핵심 개념의 오답 제거 기준을 다시 본다. 같은 개념이 기말에 변형될 수 있다. |
| 4 | Before Midterm Quiz Review | 기본 정의와 구조를 빠르게 복습한다. 특히 Transformer 이전 흐름을 잊지 않는다. |
| 5 | 개별 AIX 강의자료 | 헷갈리는 개념을 배경 설명으로 보강한다. 문제 우선순위는 위 자료들이 더 높다. |

기말에서 특히 강하게 잡아야 할 축은 다음 네 가지다.

| 축 | 핵심 문장 |
|---|---|
| LLM/Transformer | LLM은 decoder-only Transformer가 next token prediction을 반복하는 생성 모델이다. |
| Autonomous Driving | modular stack은 해석 가능하지만 앞단 오류가 뒤로 전파되고, Tesla식 접근은 shared world representation으로 이동한다. |
| Imitation Learning | behavioral cloning은 supervised learning처럼 보이지만 action이 다음 state distribution을 바꾸는 점이 다르다. |
| Robotics Scaling | VLA와 ego-video, world model, action fine-tuning, physical RL은 로봇용 foundation model 흐름으로 연결된다. |

## 핵심 수식 유도 지도

종합 복습에서는 같은 증명을 반복하기보다 아래 논리 사슬을 손으로 재현한다. 상세 계산은 [Linear and Logistic Regression](/study/aix/linear-logistic-regression/), [Multi-Layer Perceptron](/study/aix/multi-layer-perceptron/), [Transformer Architecture Overview](/study/aix/transformer-architecture-overview/), [Large Language Models](/study/aix/large-language-models/), [Robotics 1](/study/aix/robotics-1/)에 있다.

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

여기서 $$T$$는 문맥에 따라 temperature 또는 horizon을 뜻하므로 반드시 주변 정의를 확인한다. 전자는 무차원 양수이고, 후자는 단위 없는 step 수다.

**원문 대응:** after-midterm quiz 5개 PDF는 각 p.1-3에 LLM·autonomous driving·imitation learning·robotics scaling 문항을 제시하지만 별도의 수식 증명은 싣지 않는다. 위 표의 계산 근거는 `1st_Regression.pdf` p.10-25, `02_MLP.pdf` p.11-24, `2_Overview_TF.pdf` p.10-20, `3_Large_Language_Models.pdf` p.17-48, `Robotics_1.pdf` p.9-15에 대응한다. 즉 퀴즈 정답 범위를 넘어선 전개는 각 상세 강의 글에서 원문 직접 제시식과 저자 보충을 구분해 검산한다.

## 1. Linear Regression과 Optimization

Linear Regression은 feature $$x$$로 target $$y$$를 예측하는 지도학습 모델이다. 가장 기본 형태는 다음 선형 score다.

$$
\hat{y}=w^Tx+b
$$

Residual은 실제값과 예측값의 차이다.

$$
residual=y-\hat{y}
$$

대표 loss는 residual의 제곱합이다.

$$
L(w,b)=\sum_i (y_i-\hat{y}_i)^2
$$

시험에서는 이 세 가지를 헷갈리지 않아야 한다.

| 개념 | 한 줄 정리 | 오답 제거 기준 |
|---|---|---|
| feature | 모델의 입력 정보, 보통 $$x$$ | $$y$$를 feature라고 하면 틀림 |
| target | 예측해야 하는 정답, 보통 $$y$$ | $$x$$를 target이라고 하면 틀림 |
| score | $$w^Tx+b$$ 형태의 선형 출력 | weight와 feature의 가중합 구조가 없으면 의심 |
| residual | $$y-\hat{y}$$ | loss와 같은 말이 아님 |
| squared loss | residual을 제곱해 합친 objective | 부호가 상쇄되지 않게 제곱 |
| iterative update | loss를 줄이도록 parameter를 반복 갱신 | closed-form처럼 한 번에 끝나는 방식이 아님 |

Gradient descent는 loss를 줄이기 위해 gradient의 반대 방향으로 이동한다.

$$
\theta \leftarrow \theta-\eta\nabla_\theta L(\theta)
$$

여기서 $$\eta$$는 learning rate다. Gradient는 증가 방향이고, minimization에서는 그 반대 방향으로 움직인다는 점이 중요하다.

## 2. Logistic Regression과 Classification

Logistic Regression은 linear score를 버리지 않는다. 먼저 score를 계산한다.

$$
z=w^Tx+b
$$

그 다음 sigmoid를 적용해 0과 1 사이의 probability로 바꾼다.

$$
\sigma(z)=\frac{1}{1+e^{-z}}
$$

$$
P(y=1\mid x)=\sigma(w^Tx+b)
$$

시험에서 logistic regression을 설명할 때는 다음 문장을 잡으면 된다.

> linear score 위에 probability link function을 붙여 classification probability로 해석한다.

| 비교 | Linear Regression | Logistic Regression |
|---|---|---|
| 출력 | 실수 예측값 | class probability |
| 기본 식 | $$\hat{y}=w^Tx+b$$ | $$P(y=1\mid x)=\sigma(w^Tx+b)$$ |
| 대표 목적 | squared residual 감소 | observed label이 most likely 하도록 학습 |
| decision boundary | 회귀에서는 직접 경계가 핵심이 아님 | $$w^Tx+b=0$$이면 기본적으로 선형 경계 |

다중 class에서는 softmax를 사용한다. Softmax는 여러 class score를 합이 1인 확률 분포로 바꾼다.

$$
p_k=\frac{\exp(z_k)}{\sum_j \exp(z_j)}
$$

## 3. MLP와 Deep Learning

Single perceptron은 기본적으로 선형 경계를 만든다. XOR처럼 선형 분리가 안 되는 문제는 하나의 직선으로 해결할 수 없다. MLP는 hidden layer와 nonlinear activation을 추가해 더 복잡한 패턴을 표현한다.

| 개념 | 핵심 역할 |
|---|---|
| hidden layer | 입력과 출력 사이의 중간 표현을 만든다. |
| activation | 선형 변환 사이에 비선형성을 부여한다. |
| ReLU | 양수 구간 gradient가 일정해 sigmoid보다 vanishing gradient 문제가 덜하다. |
| backpropagation | chain rule로 각 parameter의 gradient를 효율적으로 계산한다. |
| gradient descent | 계산된 gradient로 parameter를 업데이트한다. |

Backpropagation과 gradient descent는 같은 말이 아니다.

| 용어 | 역할 |
|---|---|
| backpropagation | gradient를 계산하는 방법 |
| gradient descent | gradient를 이용해 parameter를 갱신하는 최적화 방법 |

Good learning은 training loss를 낮추는 것만이 아니다. 충분한 expressivity를 가지면서도 regularization과 bias-variance 균형을 통해 unseen data에서 generalize해야 한다.

Deep learning의 발전은 한 가지 요소로 설명하지 않는다.

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

Computer Vision의 high-level 목표는 pixel을 meaning으로 연결하는 것이다. 단순히 이미지 크기를 줄이거나 GPU로 빠르게 계산하는 것이 목표가 아니다.

| 개념 | 시험 기준 |
|---|---|
| pixel-to-meaning | 이미지의 raw pixel을 object, scene, relation, meaning으로 해석 |
| feature engineering | 사람이 유용한 feature를 직접 설계 |
| learned feature | deep learning이 데이터에서 feature를 학습 |
| CNN | local connectivity와 weight sharing으로 이미지 패턴을 효율적으로 학습 |
| AlexNet | CNN 기반 딥러닝이 전통적 CV를 넘어선 전환점 |
| visual reasoning | 객체, 관계, 언어, 문맥을 함께 이해하는 structured understanding |

CNN의 장점은 fully-connected layer처럼 모든 pixel을 독립 weight로 연결하지 않는다는 점이다. 가까운 pixel들이 만드는 local pattern을 convolution으로 보고, 같은 filter를 여러 위치에 공유한다.

최근 vision에서는 classification만이 아니라 generation과 3D understanding도 중요해진다.

| 주제 | 핵심 정리 |
|---|---|
| diffusion models | 최근 image/video generation의 대표적 주류 |
| 3D vision | geometry, pose, spatial relationship을 다루며 point cloud, voxel, mesh 등 representation이 다양 |

## 5. NLP, Tokenizer, Word2Vec

NLP에서 text는 바로 model에 들어가지 않는다. 먼저 tokenizer가 문장을 token으로 나누고 vocabulary 항목에 대응시킨다.

| 개념 | 역할 |
|---|---|
| tokenizer | 문장을 token으로 나누고 vocabulary index로 대응 |
| one-hot | vocabulary size 차원의 sparse vector |
| learned embedding | 의미 관계를 담을 수 있는 dense vector |
| subword | rare word와 OOV 문제를 줄이는 부분 단어 단위 |

Word2Vec은 단어 의미를 사람이 직접 입력하는 방식이 아니다. Proxy task를 학습하는 얕은 신경망을 만들고, hidden layer의 병목 표현을 embedding으로 사용한다.

Skip-Gram은 중심 단어를 보고 주변 context 단어를 예측한다.

$$
\text{center word}\rightarrow\text{context words}
$$

Pre-training과 fine-tuning도 반드시 구분해야 한다.

| 단계 | 의미 |
|---|---|
| pre-training | 큰 데이터로 일반적인 base representation을 학습 |
| fine-tuning | pretrained model을 특정 task에 맞게 조정 |
| task-specific era | task마다 별도 모델을 from scratch로 학습 |

## 6. RNN과 Attention

RNN은 sequence를 시간 순서대로 처리한다.

$$
h_t=f(x_t,h_{t-1})
$$

현재 hidden state가 이전 hidden state에 의존하므로 sequential dependency가 생긴다. 이 구조는 순서 데이터에 적합하지만, 먼 과거 정보가 뒤쪽까지 전달되기 어렵고 병렬 처리에 불리하다.

Attention은 token 사이의 관계를 직접 계산한다. 긴 문장이나 긴 대화에서 필요한 이전 token을 직접 참조할 수 있으므로 global relationship을 더 잘 본다.

| 비교 | RNN | Attention |
|---|---|---|
| 계산 구조 | 현재 입력과 이전 hidden state로 update | token-to-token 관계를 직접 계산 |
| 장점 | 구조가 비교적 단순하고 sequence 처리 직관적 | global relationship과 긴 문맥에 강함 |
| 약점 | long dependency와 병렬 처리에 불리 | 모든 관계 계산으로 비용이 커질 수 있음 |
| 시험 키워드 | sequential dependency, hidden state | global relationship, direct reference |

## 7. Transformer와 Self-Attention

Transformer는 token embedding, self-attention, multi-head attention, positional encoding을 결합한다.

Self-attention의 핵심 식은 다음과 같다.

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

Q와 K는 dot product를 해야 하므로 차원이 같아야 한다. V는 관련도 점수 계산이 아니라 최종 출력 표현을 만들 때 사용된다.

시험에서는 다음 오답을 조심한다.

| 오답 유형 | 왜 틀렸는가 |
|---|---|
| self-attention이 tokenization을 대신한다 | tokenization은 전처리, self-attention은 모델 내부 연산이다. |
| self-attention만으로 순서를 완벽히 안다 | 순서 정보를 위해 positional encoding이 필요하다. |
| multi-head attention은 token 수를 줄인다 | 여러 관계 패턴을 병렬로 보는 것이 핵심이다. |
| Q/K/V가 모두 같은 역할이다 | Q/K는 관련도 계산, V는 정보 출력에 쓰인다. |

## 8. LLM, MoE, Decoding

LLM은 지금까지의 token을 조건으로 다음 token 하나를 예측하고, 이를 반복해 문장을 생성한다.

$$
P(x_t\mid x_1,x_2,\ldots,x_{t-1})
$$

GPT 계열 LLM은 주로 decoder-only Transformer이며, autoregressive generation을 수행한다.

| 개념 | 핵심 설명 |
|---|---|
| next token prediction | 이전 token sequence를 보고 다음 token 확률분포를 계산 |
| autoregressive generation | 생성한 token을 다시 문맥에 붙이고 반복 |
| decoder-only Transformer | causal attention으로 이전 token만 참고하며 다음 token 예측 |
| cross-entropy loss | 정답 token 확률을 높이도록 학습 |

Decoding 방식도 구분해야 한다.

| 방식 | 핵심 | 장점 | 한계 |
|---|---|---|---|
| greedy decoding | 매 step 가장 확률 높은 token 하나 선택 | 빠르고 단순 | 전체 문장 최적 보장 없음 |
| beam search | 가능성 높은 $$k$$개 후보 sequence 유지 | greedy보다 좋은 전체 후보 탐색 가능 | 비용 증가, 다양성 제한 가능 |

Mixture of Experts는 큰 모델 capacity를 효율적으로 쓰는 방식이다. 모든 token이 모든 expert를 쓰는 것이 아니라, router가 token마다 필요한 expert 일부만 활성화한다.

| 개념 | 시험 기준 |
|---|---|
| expert | 특정 계산을 담당하는 sub-network |
| router | token마다 사용할 expert를 선택 |
| sparse activation | 모든 expert가 아니라 일부 expert만 활성화 |
| 장점 | 모델 capacity는 키우면서 계산 비용을 상대적으로 줄임 |

## 9. Autonomous Driving

자율주행은 단순 제어 문제가 아니라 perception과 uncertainty가 큰 AI 문제다. 도로에는 차량, 보행자, 차선, 신호, 날씨, 가려짐, corner case가 섞여 있다.

전통적 구조는 modular stack이다.

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

Modular stack의 장점은 해석 가능성과 모듈별 개발이다. 하지만 앞단 오류가 뒤 단계로 전파될 수 있다. Perception에서 보행자를 놓치면 prediction, planning, control도 잘못된 입력을 바탕으로 동작한다.

Tesla식 전환에서 핵심은 object list에서 occupancy/shared world representation으로 이동한 것이다.

| 표현 | 특징 |
|---|---|
| object list | 알려진 object class를 검출하고 목록화 |
| occupancy | 공간이 차 있는지, 비어 있는지, 주행 가능한지 표현 |
| shared world representation | 여러 task가 공유하는 unified latent world state |
| representation-level end-to-end | 카메라에서 조향까지 단순 직결이 아니라 world representation을 통합적으로 학습 |

Occupancy는 object 이름만이 아니라 geometry, free space, semantics를 함께 다뤄 planning과 연결하기 좋다.

## 10. Imitation Learning과 DAggER

Imitation learning은 expert demonstration을 사용해 비싸고 위험한 trial-and-error를 줄인다. 특히 실제 로봇에서는 시행착오가 비용과 안전 문제를 만들기 때문에 expert trajectory가 중요하다.

Behavioral Cloning은 expert trajectory를 supervised learning 문제로 바꾼다.

$$
o\rightarrow a
$$

즉 observation을 입력으로 받고 expert action을 label로 삼아 policy를 학습한다.

하지만 imitation learning은 ordinary supervised learning과 다르다. Policy가 선택한 action이 다음 state를 바꾸고, 이 때문에 미래 입력 분포 자체가 달라진다.

| 문제 | 설명 |
|---|---|
| covariate shift | 학습 때 본 state와 실행 중 방문하는 state 분포가 달라짐 |
| compounding error | 작은 행동 오류가 다음 state를 바꾸고 이후 오류가 누적됨 |
| state distribution shift | learner의 action 때문에 test-time state distribution이 expert data와 달라짐 |

DAggER는 이 문제를 줄이기 위해 learner가 실제로 방문한 state를 모으고, 그 state에 expert label을 다시 붙여 dataset에 aggregate한 뒤 retrain한다.

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

Robotics 1은 이 파트를 가장 직접적으로 보강한다. 특히 behavioral cloning의 한계가 "모델이 약해서"가 아니라 expert distribution 밖 recovery data가 부족해서 생긴다는 점을 잡아야 한다.

| Robotics 1 활용 지점 | Final Review에서 연결되는 개념 |
|---|---|
| Why imitation became attractive | physical robot에서 RL trial-and-error가 비싸고 느림 |
| Behavioral cloning | expert trajectory를 observation-to-action supervised learning으로 변환 |
| Covariate shift | learner action이 다음 state distribution을 바꿈 |
| Error growth | independent error보다 sequential error가 더 크게 누적 가능 |
| DAggER | learner-visited state에 expert label을 붙여 aggregate/retrain |
| Remaining bottleneck | task-specific imitation의 한계가 foundation model, world model, VLA로 이어짐 |

## 11. Robotics Scaling과 VLA

로보틱스는 AI scaling의 다음 frontier로 설명된다. LLM에서 대규모 데이터와 foundation model이 성능 향상을 만들었듯이, 로봇도 대규모 비디오, world model, action data, physical RL을 결합하는 방향으로 이동한다.

VLA는 Vision-Language-Action이다.

| 구성 | 의미 |
|---|---|
| Vision | 이미지나 비디오로 장면을 인식 |
| Language | 자연어 지시나 목표를 이해 |
| Action | 실제 로봇 행동을 출력 |

Ego-video나 internet-scale video는 embodied AI에서 중요하다. 이유는 완벽한 action label이 있어서가 아니라, 사람이 물리 세계와 상호작용하는 dynamics와 affordance 단서를 많이 담고 있기 때문이다.

| 흐름 | 설명 |
|---|---|
| world model | 물리 세계의 상태 변화와 상호작용을 학습 |
| action fine-tuning | vision/language 기반 모델을 robot action에 맞게 조정 |
| physical RL | 실제 환경에서 시행착오를 통해 행동 성능 보정 |

기말에서는 이 흐름을 하나의 문장으로 정리하면 좋다.

> 로보틱스는 pre-trained world/foundation model 위에 action 적응과 실제 환경 학습을 더하는 방향으로 scaling된다.

Robotics 2는 이 문장을 세 단계로 더 구체화한다.

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

| 주제 | 반드시 기억할 문장 |
|---|---|
| Linear Regression | $$\hat{y}=w^Tx+b$$, residual은 $$y-\hat{y}$$, loss는 squared residual 중심이다. |
| Logistic Regression | linear score에 sigmoid를 붙여 class probability로 해석한다. |
| MLP | hidden layer와 nonlinearity가 복잡한 패턴 표현을 가능하게 한다. |
| Backpropagation | chain rule로 gradient를 계산하고, gradient descent가 parameter를 갱신한다. |
| Computer Vision | pixel을 meaning으로 연결하는 것이 목표다. |
| NLP | tokenizer는 token 분리, embedding은 dense representation이다. |
| Word2Vec | proxy task를 학습하며 hidden layer를 embedding으로 사용한다. |
| RNN | sequence를 순서대로 처리하고 이전 hidden state에 의존한다. |
| Attention | token 사이 global relationship을 직접 계산한다. |
| Transformer | Q/K/V attention, multi-head, positional encoding을 결합한다. |
| LLM | decoder-only Transformer가 next token prediction을 반복한다. |
| MoE | token마다 필요한 expert 일부만 활성화한다. |
| Autonomous Driving | modular stack은 error propagation이 있고, occupancy는 world representation을 강화한다. |
| Imitation Learning | action이 다음 state distribution을 바꾸므로 ordinary supervised learning과 다르다. |
| Robotics | VLA, ego-video, world model, action fine-tuning, physical RL이 scaling 흐름을 만든다. |

## Study Guide

먼저 `After Midterm Quiz Review`를 외운다. 20260521부터 20260605까지의 퀴즈는 기말 직전 범위이므로, 문항별 핵심 정답 키워드를 먼저 잡는 것이 효율적이다.

그다음 `Robotics 1`, `Robotics 2`를 읽어 after-midterm quiz의 로보틱스 문항을 설명형으로 바꿔 말해 본다. `Robotics 1`은 behavioral cloning과 DAggER, `Robotics 2`는 VLA, world model, data engine, physical RL을 보강한다.

그다음 `Midterm Review`의 전체 정답 체크리스트를 빠르게 훑는다. 이미 중간고사에서 다룬 기본 개념이라도, 기말에서는 LLM과 자율주행, 로보틱스 개념을 이해하기 위한 기반으로 다시 등장할 수 있다.

마지막으로 `Before Midterm Quiz Review`에서 기본 정의를 보강한다. 특히 logistic regression, MLP, RNN, attention, Transformer는 뒤쪽 범위의 언어모델과 로봇 foundation model을 이해하는 뼈대다.

| 공부 순서 | 할 일 |
|---:|---|
| 1 | After-midterm 5개 quiz의 핵심 정답 키워드를 암기한다. |
| 2 | Robotics 1/2로 imitation learning, DAggER, VLA, WAM, physical RL을 보강한다. |
| 3 | LLM, 자율주행, imitation learning, robotics scaling을 설명형 문장으로 말해 본다. |
| 4 | Midterm Review의 오답 제거 기준을 보고 헷갈리는 선택지를 제거하는 연습을 한다. |
| 5 | Before-midterm의 기본 ML/CV/NLP/Transformer 정의를 빠르게 복습한다. |
| 6 | 복습 질문을 닫은 상태로 먼저 답하고, 펼쳐서 답변을 확인한다. |

## 복습 질문

<details markdown="block">
<summary>1. Linear regression에서 feature와 target은 무엇인가?</summary>

답변: Feature는 모델의 입력 정보이고 보통 $$x$$로 둔다. Target은 예측해야 하는 정답이고 보통 $$y$$로 둔다.

</details>

<details markdown="block">
<summary>2. Logistic regression은 왜 classification에 적합한가?</summary>

답변: Linear score $$w^Tx+b$$를 sigmoid에 넣어 0과 1 사이 값으로 바꾸므로 binary class probability로 해석할 수 있기 때문이다.

</details>

<details markdown="block">
<summary>3. MLP가 single perceptron보다 강한 이유는 무엇인가?</summary>

답변: Hidden layer와 nonlinear activation을 사용하므로 single perceptron이 만들 수 없는 복잡한 비선형 패턴을 표현할 수 있기 때문이다.

</details>

<details markdown="block">
<summary>4. Backpropagation과 gradient descent는 어떻게 다른가?</summary>

답변: Backpropagation은 chain rule로 gradient를 계산하는 방법이고, gradient descent는 그 gradient를 이용해 parameter를 갱신하는 최적화 방법이다.

</details>

<details markdown="block">
<summary>5. Computer Vision의 high-level 목표는 무엇인가?</summary>

답변: Raw pixel을 object, scene, relation, meaning으로 해석하는 것이다. 단순 압축이나 저장 효율이 핵심 목표가 아니다.

</details>

<details markdown="block">
<summary>6. CNN이 이미지 처리에 적합한 이유는 무엇인가?</summary>

답변: Local connectivity와 weight sharing을 통해 이미지의 국소 패턴을 효율적으로 학습할 수 있기 때문이다.

</details>

<details markdown="block">
<summary>7. Tokenizer와 embedding은 어떻게 다른가?</summary>

답변: Tokenizer는 문장을 token으로 나누고 vocabulary 항목에 대응시키는 과정이다. Embedding은 token을 의미 관계를 담을 수 있는 dense vector로 바꾸는 표현이다.

</details>

<details markdown="block">
<summary>8. Skip-Gram은 어떤 task인가?</summary>

답변: 중심 단어 하나를 보고 주변 context 단어를 예측하는 Word2Vec의 proxy task다.

</details>

<details markdown="block">
<summary>9. RNN이 긴 sequence에서 어려움을 겪는 이유는 무엇인가?</summary>

답변: 정보가 hidden state를 따라 순차적으로 전달되므로 먼 과거 정보가 뒤쪽까지 유지되기 어렵고, 순차 계산 때문에 병렬 처리에도 불리하기 때문이다.

</details>

<details markdown="block">
<summary>10. Attention이 RNN보다 global relationship을 잘 보는 이유는 무엇인가?</summary>

답변: Attention은 각 token이 다른 token들과의 관련도를 직접 계산해 필요한 정보를 바로 참조할 수 있기 때문이다.

</details>

<details markdown="block">
<summary>11. Transformer에서 Q, K, V의 역할은 무엇인가?</summary>

답변: Q와 K는 dot product로 token 간 관련도 점수를 계산하는 데 쓰이고, V는 그 attention weight를 바탕으로 실제 출력 정보를 만드는 데 쓰인다.

</details>

<details markdown="block">
<summary>12. Positional encoding이 필요한 이유는 무엇인가?</summary>

답변: Self-attention 자체는 token 사이 관계를 보지만 순서 정보를 충분히 담지 못하므로, token의 위치와 순서를 모델에 알려 주기 위해 positional encoding을 더한다.

</details>

<details markdown="block">
<summary>13. LLM의 next token prediction은 무엇인가?</summary>

답변: 지금까지 생성되거나 입력된 token sequence를 조건으로 다음 token의 확률분포를 예측하고, 선택된 token을 다시 문맥에 붙여 반복 생성하는 방식이다.

</details>

<details markdown="block">
<summary>14. Greedy decoding과 beam search는 어떻게 다른가?</summary>

답변: Greedy decoding은 매 step에서 확률이 가장 높은 token 하나만 고른다. Beam search는 가능성 높은 $$k$$개의 후보 sequence를 유지하며 더 넓게 탐색한다.

</details>

<details markdown="block">
<summary>15. MoE의 핵심 아이디어는 무엇인가?</summary>

답변: 모든 token이 모든 expert를 사용하는 것이 아니라, router가 token마다 필요한 expert 일부만 선택해 sparse하게 활성화하는 것이다.

</details>

<details markdown="block">
<summary>16. Modular autonomous driving stack의 약점은 무엇인가?</summary>

답변: Perception, prediction, planning, control이 단계별로 나뉘어 있어 해석은 쉽지만, 앞단의 오류가 뒤 단계로 전파되어 최종 주행 결과를 나쁘게 만들 수 있다.

</details>

<details markdown="block">
<summary>17. Tesla식 end-to-end에서 occupancy가 중요한 이유는 무엇인가?</summary>

답변: Occupancy는 object list보다 geometry, free space, semantics를 함께 표현할 수 있어 planning에 필요한 world representation을 더 잘 제공하기 때문이다.

</details>

<details markdown="block">
<summary>18. Behavioral cloning이 ordinary supervised learning과 다른 이유는 무엇인가?</summary>

답변: Robot policy의 action은 다음 state를 바꾸고, 그 결과 미래 입력 분포 자체가 달라질 수 있다. 일반 supervised learning보다 covariate shift와 compounding error 문제가 크다.

</details>

<details markdown="block">
<summary>19. DAggER는 무엇을 해결하려는 방법인가?</summary>

답변: Learner가 실제로 방문한 state를 모으고 expert label을 붙여 dataset에 aggregate한 뒤 retrain함으로써 state distribution shift와 compounding error를 줄이려는 방법이다.

</details>

<details markdown="block">
<summary>20. VLA는 무엇인가?</summary>

답변: Vision-Language-Action의 약자로, 이미지나 비디오를 보고 언어 지시를 이해한 뒤 실제 로봇 action을 출력하는 로봇용 backbone이다.

</details>

## Source Materials

<ul>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-before-midterm/" | relative_url }}">AIX Quiz Review Before Midterm</a></li>
  <li><a href="{{ "/study/aix/aix-midterm-review/" | relative_url }}">AIX Midterm Review</a></li>
  <li><a href="{{ "/assignment/aix/aix-quiz-review-after-midterm/" | relative_url }}">AIX Quiz Review After Midterm</a></li>
  <li><a href="{{ "/study/aix/robotics-1/" | relative_url }}">Robotics 1</a></li>
  <li><a href="{{ "/study/aix/robotics-2/" | relative_url }}">Robotics 2</a></li>
</ul>
