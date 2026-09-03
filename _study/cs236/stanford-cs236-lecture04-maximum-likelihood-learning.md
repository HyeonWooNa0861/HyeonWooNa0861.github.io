---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 4: Maximum Likelihood Learning"
course: "CS236"
topic: "Maximum Likelihood Learning"
order: 4
major_topic: "Deep Generative Models"
keywords:
  - "Maximum Likelihood"
  - "KL Divergence"
  - "Autoregressive Models"
  - "Stochastic Gradient Descent"
  - "Overfitting"
---

# Stanford CS236 Lecture 4: Maximum Likelihood Learning

Source: [Stanford CS236 Lecture 4](https://www.youtube.com/watch?v=bt3dqcbMLa0){:target="_blank" rel="noopener"}

Source PDF: [cs236_lecture4.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture4.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 4는 이전 강의의 autoregressive model을 마무리하면서 시작한다. RNN은 지금까지의 문맥을 하나의 hidden vector에 압축하기 때문에 long-range dependency와 exploding/vanishing gradient 문제가 생긴다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Autoregressive model 마무리 | RNN, attention, convolution 기반 autoregressive model은 likelihood 계산과 병렬화에서 어떻게 다른가? |
| 2 | Generative model 학습 문제 | 데이터가 어떤 실제 분포 \(P_{\mathrm{data}}\)에서 왔다고 할 때, 모델 \(P_{\theta}\)를 무엇에 가깝게 맞춰야 하는가? |
| 3 | KL divergence | 두 분포의 차이를 compression loss로 해석하면 왜 maximum likelihood가 자연스럽게 나오는가? |
| 4 | Empirical log-likelihood | 알 수 없는 기대값 \(E_{x\sim P_{\mathrm{data}}}[\log P_{\theta}(x)]\)를 훈련 데이터 평균으로 어떻게 근사하는가? |
| 5 | Autoregressive MLE와 SGD | Chain rule factorization의 log-likelihood가 왜 token/pixel별 loss 합으로 분해되는가? |
| 6 | Generalization | 강한 모델이 training data를 외우지 않도록 bias-variance, regularization, validation을 어떻게 써야 하는가? |
| 7 | Conditional generation | 전체 joint distribution이 아니라 \(P_{\theta}(Y\mid X)\)만 학습해도 되는 경우는 무엇인가? |

## 핵심 내용

Lecture 4는 이전 강의의 autoregressive model을 마무리하면서 시작한다. RNN은 지금까지의 문맥을 하나의 hidden vector에 압축하기 때문에 long-range dependency와 exploding/vanishing gradient 문제가 생긴다. Attention은 이전 token들의 hidden vector 전체를 보고, query-key similarity를 softmax로 바꾸어 어느 위치를 참조할지 선택한다. 이때 autoregressive 성질을 유지하려면 미래 token을 보지 못하게 mask가 필요하다. Transformer 계열은 recurrent update 없이 여러 attention layer를 feed-forward로 쌓기 때문에 training time에는 각 위치의 loss를 병렬 평가할 수 있다. 강의는 이것이 modern autoregressive language model이 GPU에서 크게 확장될 수 있었던 핵심 이유라고 정리한다.

이어 학습 문제는 "어떤 분포가 좋은가"라는 질문으로 바뀐다. 데이터는 알 수 없는 실제 분포 \(P_{\mathrm{data}}\)에서 IID로 샘플링되었다고 가정하고, 우리는 모델 family \(\mathcal{M}\) 안에서 하나의 \(P_{\theta}\)를 고른다. 이상적으로는 \(P_{\theta}=P_{\mathrm{data}}\)가 목표지만, 실제로는 데이터가 유한하고 가능한 이미지 공간은 예를 들어 \(2^{784}\)처럼 매우 크며, 계산 자원도 제한되어 있다. 따라서 "가깝다"를 측정하는 기준이 필요하다.

이 강의의 기준은 forward KL divergence다.

$$
D_{\mathrm{KL}}(P_{\mathrm{data}}\Vert P_{\theta})
=
E_{x\sim P_{\mathrm{data}}}
\left[
\log \frac{P_{\mathrm{data}}(x)}{P_{\theta}(x)}
\right].
$$

KL divergence는 항상 0 이상이고 두 분포가 같을 때만 0이지만, 대칭적이지 않다. 강의는 이를 compression 관점으로 설명한다. 실제 데이터가 \(p\)에서 오는데 \(q\)에 맞춘 code로 압축하면 평균적으로 추가 bit가 필요하며, 그 추가 비용이 KL divergence다. 따라서 \(D_{\mathrm{KL}}(P_{\mathrm{data}}\Vert P_{\theta})\)를 줄이는 것은 데이터 구조를 잘 압축하는 모델을 찾는 것과 같다.

식에서 \(E[\log P_{\mathrm{data}}(x)]\)는 \(\theta\)와 무관한 상수이므로, forward KL을 최소화하는 것은 \(E_{x\sim P_{\mathrm{data}}}[\log P_{\theta}(x)]\)를 최대화하는 것과 같다. 하지만 \(P_{\mathrm{data}}\) 자체는 알 수 없으므로, 이 기대값을 훈련 집합 \(D\) 위의 empirical average로 바꾼다.

$$
\max_{\theta}\frac{1}{|D|}\sum_{x\in D}\log P_{\theta}(x).
$$

이것이 maximum likelihood learning이다. Coin toss 예시에서는 \(D=\{H,H,T,H,T\}\)일 때 \(P_{\theta}(H)=\theta\)를 두고 likelihood \(\theta^3(1-\theta)^2\)를 최대화하면 \(\theta=0.6\)이 된다. Autoregressive model에서는

$$
P_{\theta}(x)=\prod_{i=1}^{n}p_{\mathrm{neural}}(x_i\mid x_{<i};\theta_i)
$$

이므로 log-likelihood는 데이터와 위치에 대한 log conditional probability 합으로 바뀐다. 닫힌형 해가 없을 때는 backpropagation과 gradient ascent를 사용하고, 데이터가 크면 전체 gradient 대신 minibatch로 Monte Carlo estimate를 만든다. 이 관점에서 SGD는 전체 empirical objective의 gradient를 샘플 평균으로 근사하는 방법이다.

마지막으로 강의는 likelihood가 전부는 아니라고 강조한다. \(P_{\theta}(x)\approx 0\)인 실제 데이터가 있으면 log-loss가 크게 증가하므로 forward KL은 data support를 넓게 덮으려는 성질을 가진다. 반대로 reverse KL은 model이 만든 샘플 쪽을 더 보게 되어 mode-seeking 성향이 강해질 수 있다. 또 높은 log-likelihood가 항상 더 그럴듯한 sample을 의미하지는 않는다. 모델 family가 너무 약하면 bias가 크고, 너무 강하면 variance와 overfitting이 커진다. 따라서 hypothesis space 제한, weight sharing, regularization, held-out validation이 함께 필요하다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Forward KL | \(D_{\mathrm{KL}}(P_{\mathrm{data}}\Vert P_{\theta})\). 실제 데이터가 가능한 영역을 모델이 낮은 확률로 두면 큰 벌점을 받는다. |
| Maximum Likelihood | 훈련 데이터의 평균 log probability를 최대화하는 학습 원리다. Forward KL 최소화와 같은 최적화 방향을 가진다. |
| Empirical Average | 알 수 없는 \(P_{\mathrm{data}}\) 기대값을 데이터셋 평균으로 대체한 값이다. 데이터가 충분하면 기대값에 가까워진다. |
| Autoregressive Loss | \(P_{\theta}(x)\)가 conditional probability 곱이면 log-likelihood는 conditional log-probability 합으로 분해된다. |
| Stochastic Gradient Descent | 전체 데이터 gradient 대신 샘플 또는 minibatch gradient를 사용해 큰 데이터셋에서 효율적으로 최적화한다. |
| Bias-Variance Tradeoff | 모델 family가 좁으면 underfit, 너무 넓으면 overfit하기 쉬우므로 적절한 복잡도 제어가 필요하다. |
| Conditional Generative Model | \(Y\)를 \(X\)에 조건부로 생성하면 joint \(P(X,Y)\) 전체가 아니라 \(P(Y\mid X)\)만 추정해도 된다. |

## 학습 포인트

- Autoregressive model은 likelihood 계산이 쉽기 때문에 maximum likelihood와 잘 맞는다.
- Transformer의 장점은 이론적 표현력만이 아니라 training loss를 위치별로 병렬 계산할 수 있다는 점이다.
- KL divergence는 "거리"처럼 쓰이지만 대칭이 아니며, 어느 방향으로 쓰는지에 따라 학습된 모델의 성향이 달라진다.
- Forward KL을 최소화하면 실제 데이터가 나올 수 있는 영역에 낮은 확률을 주는 모델을 강하게 벌한다.
- MLE는 \(P_{\mathrm{data}}\)를 직접 알지 못해도 empirical log-likelihood로 실용적인 목적함수를 만든다.
- Overfitting을 막는 방법은 단순히 더 큰 모델을 피하는 것이 아니라, validation과 regularization으로 generalization을 확인하는 것이다.

## 마지막 핵심 정리

Lecture 4의 핵심은 generative model 학습을 "데이터 분포와 모델 분포를 어떤 기준으로 맞출 것인가"로 보는 것이다. Autoregressive model은 \(P_{\theta}(x)\)를 계산할 수 있으므로 \(D_{\mathrm{KL}}(P_{\mathrm{data}}\Vert P_{\theta})\) 최소화가 empirical maximum likelihood로 바뀐다. 이 단순한 전환 덕분에 복잡한 neural generative model도 log-likelihood 합, backpropagation, SGD라는 익숙한 최적화 문제로 다룰 수 있다.

## Study Guide

1. 먼저 \(P_{\mathrm{data}}\), \(P_{\theta}\), model family \(\mathcal{M}\)의 역할을 구분한다.
2. KL divergence 식을 전개해 \(\theta\)와 무관한 항이 왜 사라지는지 직접 써 본다.
3. Coin toss MLE 예시에서 likelihood와 log-likelihood가 같은 \(\theta\)를 고르는 이유를 확인한다.
4. Autoregressive factorization을 log로 바꾸면 곱이 합이 된다는 점을 token-level cross entropy와 연결한다.
5. Forward KL, reverse KL, GAN류 objective가 서로 다른 "분포 비교 방식"이라는 큰 틀을 잡아 둔다.

## 복습 질문

<details>
<summary>1. Forward KL 최소화가 maximum likelihood와 같은 방향이 되는 이유는 무엇인가?</summary>

답변: \(D_{\mathrm{KL}}(P_{\mathrm{data}}\Vert P_{\theta})\)를 전개하면 \(E[\log P_{\mathrm{data}}(x)]-E[\log P_{\theta}(x)]\)가 된다. 첫 항은 \(\theta\)와 무관하므로 KL을 줄이는 것은 두 번째 항, 즉 expected log-likelihood를 키우는 것과 같다.

</details>

<details>
<summary>2. Autoregressive model에서 log-likelihood가 학습하기 쉬운 형태가 되는 이유는 무엇인가?</summary>

답변: Chain rule로 \(P_{\theta}(x)\)를 conditional probability들의 곱으로 쓰고, log를 취하면 곱이 합으로 바뀐다. 따라서 각 위치의 conditional log probability를 더하는 objective가 되며, neural network parameter는 backpropagation으로 최적화할 수 있다.

</details>

<details>
<summary>3. Transformer가 RNN보다 autoregressive 학습에서 실용적으로 유리한 점은 무엇인가?</summary>

답변: RNN은 hidden state를 순차적으로 갱신해야 하지만, transformer/self-attention 구조는 causal mask를 쓰면서도 training time에는 여러 위치의 conditional loss를 병렬로 평가할 수 있다. 이 병렬성이 GPU 활용과 scale-up에 중요하다.

</details>

<details>
<summary>4. Forward KL과 reverse KL은 왜 다른 모델 성향을 만들 수 있는가?</summary>

답변: Forward KL은 실제 데이터 분포가 높은 곳에서 모델 확률이 낮으면 큰 벌점을 주므로 data support를 넓게 덮게 만든다. Reverse KL은 모델이 생성하는 영역을 기준으로 보므로 일부 mode에 확률을 집중하는 mode-seeking 성향이 나타날 수 있다.

</details>

<details>
<summary>5. Maximum likelihood가 높아도 sample quality가 항상 좋다고 말할 수 없는 이유는 무엇인가?</summary>

답변: Likelihood는 데이터 압축과 density estimation 관점의 기준이다. 실제 사람이 보기 좋은 sample인지, mode를 잘 덮었는지, 특정 task에서 유용한지는 다른 평가 기준이 필요할 수 있다. 강의는 이후 GAN처럼 다른 분포 비교 방식이 등장한다고 예고한다.

</details>

## PDF

- [Official Lecture 4 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture4.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=bt3dqcbMLa0){:target="_blank" rel="noopener"}
- [Official slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture4.pdf){:target="_blank" rel="noopener"}
- Local transfer source: `research_files/stanford-cs236-deep-generative-models-2023/slides/lecture04-maximum-likelihood-learning.pdf`
