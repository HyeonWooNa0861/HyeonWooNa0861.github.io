---
layout: default
title: "Stanford CS236 Lecture 17: Discrete Latent Variable Models"
course: "CS236"
topic: "Discrete Latent Variable Optimization"
order: 17
major_topic: "Deep Generative Models"
keywords:
  - "Discrete Latent Variables"
  - "Log Derivative Trick"
  - "Control Variates"
  - "NVIL"
  - "Gumbel-Softmax"
  - "Straight-Through Estimator"
---

# Stanford CS236 Lecture 17: Discrete Latent Variable Models

## Source

- Video: [Stanford CS236 Deep Generative Models 2023 Lecture 17](https://www.youtube.com/watch?v=vBv7Mf1zsg8){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture17.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture17.pdf){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Diffusion wrap-up | diffusion model은 SDE/ODE/likelihood 관점에서 어떻게 마무리되는가? |
| 2 | Discrete latent variables | discrete \(z\)가 들어가면 왜 reparameterization trick이 바로 쓰이지 않는가? |
| 3 | Log derivative trick | differentiable path가 없어도 \(\phi\) gradient를 어떻게 만들 수 있는가? |
| 4 | Variance reduction | unbiased estimator가 너무 noisy할 때 control variate는 무엇을 바꾸는가? |
| 5 | NVIL | neural variational inference는 discrete latent variable ELBO를 어떻게 학습하는가? |
| 6 | Gumbel-Softmax | discrete sample을 continuous relaxation으로 바꾸면 어떤 bias-variance tradeoff가 생기는가? |

## 핵심 내용

Lecture 17은 앞부분에서 diffusion model의 SDE/ODE 연결을 마무리한 뒤, discrete latent variable model의 optimization 문제로 넘어간다. 연결점은 "sampling process를 가진 model을 어떻게 미분 가능한 학습 문제로 바꾸는가"다. Diffusion에서는 score model이 reverse SDE와 probability flow ODE를 정의했다. Discrete latent variable에서는 latent state \(z\)가 category, graph, text token, program structure처럼 불연속이기 때문에 continuous reparameterization을 그대로 적용하기 어렵다.

기본 문제는 다음 stochastic optimization이다.

$$
\max_\phi \mathbb{E}_{q_\phi(z)}[f(z)]
$$

VAE에서 decoder parameter \(\theta\)는 expectation 안쪽의 \(\log p_\theta(x,z)\)를 미분하면 되므로 비교적 직접적이다. 그러나 variational distribution parameter \(\phi\)는 sample을 뽑는 분포 \(q_\phi(z)\) 자체를 바꾼다. Continuous latent variable에서는 \(\epsilon\sim p(\epsilon)\), \(z=g_\phi(\epsilon)\)처럼 fixed noise를 differentiable transformation으로 바꾸는 reparameterization trick을 쓴다. 이 방식은 \(f\)가 differentiable이고 \(q_\phi\)가 differentiably reparameterizable할 때 강력하다.

Discrete \(z\)에서는 이 조건이 깨진다. Category를 하나 고르는 과정, argmax, graph edge 선택은 보통 미분 가능한 path를 제공하지 않는다. 이때 가장 일반적인 도구가 log derivative trick이다.

$$
\nabla_\phi \mathbb{E}_{q_\phi(z)}[f(z)]
=
\mathbb{E}_{q_\phi(z)}[f(z)\nabla_\phi \log q_\phi(z)]
$$

이 식은 \(q_\phi(z)\)를 sample하고 probability를 평가할 수 있으면 discrete와 continuous 모두에 적용된다. Reinforcement learning의 policy gradient와 같은 구조다. 문제는 Monte Carlo estimator의 variance가 매우 크다는 점이다. Sample 하나가 받은 reward 또는 objective value \(f(z)\)가 그대로 gradient 크기를 흔들기 때문에 naive estimator는 실제 neural model 학습에 거의 쓰기 어렵다.

Discrete latent variable VAE의 ELBO는 보통

$$
\mathcal{L}(x;\theta,\phi)
=
\mathbb{E}_{q_\phi(z\mid x)}
[\log p_\theta(x,z)-\log q_\phi(z\mid x)]
$$

로 쓴다. 여기서는 expectation 안의 \(f\)도 \(\phi\)에 의존한다. 따라서 gradient에는 \(f(z)\nabla_\phi\log q_\phi(z\mid x)\) 항과 \(\nabla_\phi f(z)\) 항이 함께 나타난다. 첫 항이 high-variance score-function estimator이고, 두 번째 항은 entropy나 variational distribution term에서 직접 생기는 gradient다.

Control variate는 expectation은 유지하면서 variance를 줄인다. 가장 단순한 형태는 constant baseline \(B\)를 빼는 것이다.

$$
\mathbb{E}_{q_\phi(z)}[B\nabla_\phi\log q_\phi(z)]=0
$$

이므로 \(f(z)\) 대신 \(f(z)-B\)를 곱해도 estimator는 unbiased다. 더 일반적으로 expectation을 알거나 계산 가능한 \(h(z)\)를 더해 estimator를 보정할 수 있다. \(h\)가 원래 estimator와 강하게 상관되어 있으면 variance가 크게 줄어든다. 핵심은 mean은 그대로 두고 random fluctuation만 제거하는 것이다.

NVIL은 discrete latent variable을 가진 neural model에 log derivative trick과 learned baseline을 적용한 대표적 방법이다. 입력 \(x\)마다 objective scale이 달라지므로 하나의 constant baseline만으로는 충분하지 않다. NVIL은 global baseline \(B\)와 input-dependent baseline \(h_\psi(x)\)를 함께 사용해

$$
(f-h_\psi(x)-B)\nabla_\phi\log q_\phi(z\mid x)
$$

형태의 estimator를 만든다. Baseline network는 \(f\)를 잘 예측하도록 학습되어 residual variance를 줄인다. 이 방법은 unbiased지만 여전히 tuning과 variance 관리가 중요하다.

다른 길은 discrete variable을 continuous relaxation으로 바꾸는 것이다. Gumbel-Max trick은 categorical distribution에서 exact sample을 만드는 재parameterization이다.

$$
z=\operatorname{onehot}\left(\arg\max_i(g_i+\log \pi_i)\right)
$$

여기서 \(g_i\)는 independent Gumbel noise다. Randomness는 fixed Gumbel noise로 분리되지만, \(\arg\max\)가 non-differentiable이다. Gumbel-Softmax는 \(\arg\max\)를 softmax로 완화한다.

$$
\hat z_i
=
\operatorname{softmax}_i\left(\frac{g_i+\log\pi_i}{\tau}\right)
$$

Temperature \(\tau\)가 작으면 one-hot categorical에 가까워져 bias가 줄지만 gradient variance가 커진다. \(\tau\)가 크면 distribution은 더 smooth하고 uniform에 가까워져 gradient는 안정되지만 discrete sample과 멀어진다. Straight-through estimator는 forward pass에서는 hard discrete sample을 쓰고 backward pass에서는 soft relaxation의 gradient를 흘려보내는 practical compromise다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Discrete latent variable | category, graph, token, program structure처럼 가능한 값이 분리되어 있는 latent variable이다. |
| Reparameterization trick | random source를 fixed noise로 분리하고 \(z=g_\phi(\epsilon)\)로 써서 pathwise gradient를 얻는 방법이다. |
| Log derivative trick | sample path가 미분 불가능해도 \(\nabla_\phi\log q_\phi(z)\)를 사용해 expectation gradient를 추정한다. |
| Score-function estimator | log derivative trick으로 얻는 Monte Carlo gradient estimator다. 일반적이지만 variance가 크다. |
| Control variate | estimator의 expectation을 바꾸지 않으면서 variance를 줄이는 보정항이다. |
| NVIL | discrete latent variable neural model을 log derivative trick과 learned baseline으로 학습하는 variational inference 방법이다. |
| Gumbel-Softmax | categorical sample을 simplex 내부의 differentiable continuous sample로 완화하는 relaxation이다. |

## 학습 포인트

- Discrete latent variable의 어려움은 "sample을 뽑을 수 없다"가 아니라 "sample 선택이 parameter에 대해 differentiable path를 주지 않는다"는 점이다.
- Log derivative trick은 매우 일반적이다. \(f\)가 black-box reward여도, \(q_\phi(z)\)의 log probability를 계산할 수 있으면 gradient estimator를 만들 수 있다.
- Unbiased estimator가 좋은 estimator라는 뜻은 아니다. Variance가 너무 크면 실제 optimization은 느리거나 불안정해진다.
- Baseline은 objective 값을 예측해 gradient scale의 불필요한 흔들림을 줄인다. Baseline을 빼도 expectation이 변하지 않는 이유를 반드시 식으로 확인해야 한다.
- Gumbel-Softmax는 exact discrete optimization이 아니라 relaxation이다. 낮은 temperature는 discrete에 가깝지만 gradient가 불안정하고, 높은 temperature는 안정적이지만 bias가 커진다.
- Straight-through estimator는 실용적이지만 엄밀히 unbiased라고 보기 어렵다. forward의 discrete semantics와 backward의 smooth gradient를 의도적으로 섞는다.

## 마지막 핵심 정리

Lecture 17의 핵심은 discrete latent variable이 generative model에서 매우 자연스럽지만, gradient estimation을 어렵게 만든다는 점이다. Reparameterization trick은 continuous differentiable latent variable에서는 강력하지만 discrete selection에는 바로 적용되지 않는다. Log derivative trick은 일반적인 unbiased gradient를 제공하고, control variate와 NVIL은 그 variance를 줄인다. Gumbel-Softmax는 문제를 continuous relaxation으로 바꾸어 pathwise gradient를 회복하지만 bias-variance tradeoff를 감수한다.

## Study Guide

1. 먼저 stochastic objective \(\mathbb{E}_{q_\phi(z)}[f(z)]\)에서 \(\phi\)가 어디에 들어가는지 표시한다. Sample distribution에 들어가는 parameter와 objective 안쪽에 들어가는 parameter를 구분한다.
2. Reparameterization trick이 성립하는 조건을 적고, categorical variable에서 어떤 조건이 깨지는지 설명한다.
3. Log derivative trick을 한 줄 유도해 본다. \(\nabla q_\phi(z)=q_\phi(z)\nabla\log q_\phi(z)\)가 핵심이다.
4. Baseline을 빼도 unbiased인 이유를 \(\mathbb{E}[\nabla\log q_\phi(z)]=0\)로 확인한다.
5. NVIL을 읽을 때는 estimator 자체와 baseline 학습 objective를 분리한다. Baseline은 gradient mean을 바꾸기 위한 것이 아니라 variance를 줄이기 위한 auxiliary model이다.
6. Gumbel-Max, Gumbel-Softmax, straight-through estimator를 exactness와 differentiability 기준으로 비교한다.

## 복습 질문

<details>
<summary>1. Discrete latent variable에서 reparameterization trick이 어려운 이유는 무엇인가?</summary>

답변: Reparameterization trick은 \(z=g_\phi(\epsilon)\)가 differentiable해야 pathwise gradient를 계산할 수 있다. Discrete category 선택은 보통 argmax나 sampling decision을 포함하고, 이 선택은 parameter에 대해 미분 가능한 연속 경로를 제공하지 않는다.

</details>

<details>
<summary>2. Log derivative trick은 어떤 가정에서 사용할 수 있는가?</summary>

답변: \(q_\phi(z)\)에서 sample을 뽑을 수 있고 \(\log q_\phi(z)\)와 그 gradient를 계산할 수 있으면 사용할 수 있다. \(f(z)\) 자체가 differentiable일 필요는 없어서 black-box reward나 discrete action에도 적용된다.

</details>

<details>
<summary>3. Baseline \(B\)를 빼도 gradient estimator가 unbiased인 이유는 무엇인가?</summary>

답변: \(\mathbb{E}_{q_\phi}[B\nabla_\phi\log q_\phi(z)]=B\nabla_\phi\sum_z q_\phi(z)=B\nabla_\phi 1=0\)이기 때문이다. 따라서 \(f(z)\) 대신 \(f(z)-B\)를 써도 expectation은 같고 variance만 줄일 수 있다.

</details>

<details>
<summary>4. NVIL에서 input-dependent baseline \(h_\psi(x)\)가 필요한 이유는 무엇인가?</summary>

답변: ELBO나 reward의 scale은 입력 \(x\)마다 다를 수 있다. 하나의 global baseline만 쓰면 각 input의 난이도와 objective scale을 반영하지 못한다. \(h_\psi(x)\)는 input별 expected learning signal을 예측해 residual variance를 줄인다.

</details>

<details>
<summary>5. Gumbel-Max와 Gumbel-Softmax의 차이는 무엇인가?</summary>

답변: Gumbel-Max는 Gumbel noise와 \(\arg\max\)를 이용해 exact categorical one-hot sample을 만든다. 하지만 \(\arg\max\)가 non-differentiable이다. Gumbel-Softmax는 \(\arg\max\)를 softmax로 대체해 differentiable sample을 만들지만, categorical distribution의 continuous relaxation이므로 bias가 생긴다.

</details>

<details>
<summary>6. Temperature \(\tau\)는 Gumbel-Softmax에서 어떤 역할을 하는가?</summary>

답변: \(\tau\)가 작을수록 sample은 one-hot categorical에 가까워진다. 이 경우 bias는 줄지만 gradient variance와 불안정성이 커진다. \(\tau\)가 클수록 sample은 더 smooth하고 uniform에 가까워져 gradient는 안정되지만 discrete target과 멀어진다.

</details>

## PDF

- [Official Lecture 17 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture17.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Course Notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 17 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture17.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 17 Video](https://www.youtube.com/watch?v=vBv7Mf1zsg8){:target="_blank" rel="noopener"}
