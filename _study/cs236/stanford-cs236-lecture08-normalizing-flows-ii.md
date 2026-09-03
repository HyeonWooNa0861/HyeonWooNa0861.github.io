---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 8: Normalizing Flows II"
course: "CS236"
topic: "Flow Architectures and Tradeoffs"
order: 8
major_topic: "Deep Generative Models"
keywords:
  - "NICE"
  - "RealNVP"
  - "MAF"
  - "IAF"
  - "Parallel WaveNet"
  - "Gaussianization"
---

# Stanford CS236 Lecture 8: Normalizing Flows II

Source: [Stanford CS236 Deep Generative Models 2023 Lecture 8](https://www.youtube.com/watch?v=qgTvgBCOyn8){:target="_blank" rel="noopener"}

Source PDF: [lecture08-normalizing-flows-ii.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture8.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 8은 Lecture 7에서 세운 normalizing flow의 조건을 실제 architecture로 구체화한다. Flow는 simple prior \(p_Z(z)\)에서 시작해 invertible transformation \(x=f_\theta(z)\)를 적용하고, likelihood는 inverse \(z=f_\theta^{-1}(x)\)와 Jacobian determinant로 계산한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Flow recap | Exact likelihood를 얻으려면 inverse map과 Jacobian determinant가 왜 필요할까? |
| 2 | Coupling layer 설계 | 일부 변수를 고정하고 나머지를 변환하면 어떻게 invertibility가 쉬워지는가? |
| 3 | NICE | Additive coupling과 rescaling만으로 어떤 flow를 만들 수 있는가? |
| 4 | RealNVP | Shift-only coupling을 shift-and-scale coupling으로 확장하면 무엇이 좋아지는가? |
| 5 | Autoregressive flow | Continuous autoregressive model은 어떤 의미에서 flow로 해석되는가? |
| 6 | MAF와 IAF | Likelihood evaluation과 sampling 속도 사이의 tradeoff는 어떻게 갈라지는가? |
| 7 | Parallel WaveNet | 느린 teacher와 빠른 student를 결합해 generation을 어떻게 가속하는가? |
| 8 | MintNet과 Gaussianization | Masked convolution과 Gaussianization은 flow 설계를 어떤 방향으로 확장하는가? |

## 핵심 내용

Lecture 8은 Lecture 7에서 세운 normalizing flow의 조건을 실제 architecture로 구체화한다. Flow는 simple prior \(p_Z(z)\)에서 시작해 invertible transformation \(x=f_\theta(z)\)를 적용하고, likelihood는 inverse \(z=f_\theta^{-1}(x)\)와 Jacobian determinant로 계산한다. 따라서 좋은 flow layer는 세 조건을 동시에 만족해야 한다. Forward direction은 sampling에 빨라야 하고, inverse direction은 likelihood evaluation에 빨라야 하며, determinant 계산도 high-dimensional data에서 반복 가능해야 한다.

첫 번째 구체적 설계는 NICE의 additive coupling layer다. 입력 \(z\)를 \(z_{1:d}\)와 \(z_{d+1:n}\)으로 나누고, 앞부분은 그대로 두며 뒷부분만 앞부분의 함수 \(m_\theta(z_{1:d})\)로 shift한다.

$$
x_{1:d}=z_{1:d}, \qquad x_{d+1:n}=z_{d+1:n}+m_\theta(z_{1:d}).
$$

역변환은 같은 shift를 빼면 되므로 간단하다. 중요한 점은 \(m_\theta\) 자체가 복잡한 neural network여도 invertibility가 깨지지 않는다는 것이다. 앞부분이 identity로 보존되기 때문에 inverse에서도 shift 값을 다시 계산할 수 있다. Jacobian은 triangular이고 diagonal이 모두 1이므로 determinant는 1이다. 이 때문에 NICE additive coupling은 volume-preserving transformation이다. 여러 coupling layer 사이에서 variable partition 또는 ordering을 바꾸고, 마지막에 rescaling layer \(x_i=s_i z_i\)를 붙이면 더 유연한 model이 된다.

RealNVP는 NICE의 자연스러운 확장이다. 단순히 shift만 하는 대신, 뒷부분을 shift하고 scale한다.

$$
x_{d+1:n}=z_{d+1:n}\odot \exp(\alpha_\theta(z_{1:d}))+\mu_\theta(z_{1:d}).
$$

Scale을 exponential로 parameterize하는 이유는 scaling factor가 0이 되지 않게 해 invertibility를 보장하기 위해서다. 역변환은 \(x-\mu\)를 한 뒤 \(\exp(-\alpha)\)를 곱하면 된다. Jacobian은 여전히 triangular이고 determinant는 scale factor들의 곱, 즉 \(\exp(\sum_i \alpha_i)\)로 계산된다. NICE와 달리 determinant가 항상 1이 아니므로 RealNVP는 local volume을 늘리거나 줄일 수 있고, 더 표현력이 높다.

강의의 중간부는 continuous autoregressive model이 사실 flow로 볼 수 있음을 보여 준다. Gaussian autoregressive model에서 \(p(x)=\prod_i p(x_i \mid x_{<i})\)이고 각 conditional이 \(\mathcal{N}(\mu_i(x_{<i}), \exp(\alpha_i(x_{<i}))^2)\)라면, sampling은 independent Gaussian noise \(z_i\)를 순서대로 shift-and-scale하여 \(x_i\)를 만드는 과정이다. 이 관점에서는 autoregressive sampler 자체가 \(z\)에서 \(x\)로 가는 invertible transformation이다.

MAF와 IAF는 같은 구조를 어느 방향으로 쓰느냐에 따라 tradeoff가 갈린다. Masked Autoregressive Flow는 \(x\) 전체가 주어졌을 때 모든 \(\mu_i,\alpha_i\)를 MADE 같은 masked network로 병렬 계산할 수 있으므로 likelihood evaluation이 빠르다. 반대로 sampling은 \(x_1,x_2,\ldots\)를 순차적으로 만들어야 하므로 느리다. Inverse Autoregressive Flow는 방향을 뒤집어 \(z\)가 주어졌을 때 output을 병렬로 만들 수 있어 sampling이 빠르지만, 외부 data point의 likelihood를 계산하려면 inverse가 순차적이어서 느리다. 즉 MAF는 density estimation과 MLE training에, IAF는 real-time generation에 더 적합하다.

Parallel WaveNet은 이 tradeoff를 실용적으로 결합한 사례다. 먼저 MAF 또는 autoregressive teacher를 maximum likelihood로 학습한다. Teacher는 좋은 density model이지만 sampling이 느리다. 이후 IAF student를 학습해 teacher distribution을 따라가게 한다. Objective는 student sample \(x \sim s\)에 대해 \(\log s(x)-\log t(x)\)를 평가하는 KL 형태다. 여기서 student는 자기 sample의 latent \(z\)를 알고 있으므로 자기 density를 효율적으로 계산할 수 있고, teacher는 likelihood evaluation이 빠르다. Test time에는 빠른 IAF student만 사용하며, 강의 슬라이드는 원래 WaveNet 대비 큰 sampling speed-up을 강조한다.

후반부의 MintNet은 masked convolution으로 invertible convolutional layer를 만드는 방향을 소개한다. 일반 CNN은 강력하지만 invertible하지 않고 determinant가 비싸다. Mask를 통해 PixelCNN처럼 ordering을 강제하면 Jacobian이 triangular가 되어 determinant가 tractable해진다. Gaussianization flow는 또 다른 관점을 제공한다. Maximum likelihood로 flow를 학습한다는 것은 forward direction에서 Gaussian prior를 data처럼 보이게 하는 것과 같고, inverse direction에서는 data를 Gaussian처럼 보이게 하는 것과 같다. 1차원에서는 data CDF와 Gaussian inverse CDF를 합성하면 Gaussianization이 가능하고, 다차원에서는 dimension-wise Gaussianization과 rotation을 반복해 더 깊은 flow를 만든다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Coupling Layer | 일부 변수는 identity로 두고 나머지를 그 변수들의 함수로 변환해 inverse와 determinant를 쉽게 만드는 layer다. |
| NICE | Additive coupling과 rescaling layer를 조합한 초기 flow model로, coupling 부분은 determinant가 1이다. |
| RealNVP | Additive coupling에 learned scale을 추가해 non-volume-preserving transformation을 가능하게 한 flow model이다. |
| MAF | Masked Autoregressive Flow. Likelihood evaluation은 병렬화하기 쉽지만 sampling은 autoregressive하게 느리다. |
| IAF | Inverse Autoregressive Flow. Sampling은 병렬화하기 쉽지만 외부 data likelihood evaluation은 느리다. |
| Probability Density Distillation | 느린 teacher density model을 빠른 student sampler로 옮기는 학습 절차다. |
| MintNet | Masked convolution을 사용해 invertible neural network와 tractable Jacobian을 만드는 접근이다. |
| Gaussianization Flow | Data를 inverse direction에서 점진적으로 Gaussian prior처럼 바꾸는 관점의 flow 설계다. |

## 학습 포인트

- Flow layer는 "invertible인가", "forward와 inverse가 빠른가", "Jacobian determinant가 tractable한가"를 동시에 평가해야 한다.
- Coupling layer의 강점은 변환을 담당하는 \(m_\theta,\mu_\theta,\alpha_\theta\)가 복잡해도 전체 mapping의 inverse가 단순하다는 점이다.
- NICE는 volume preserving이라 단순하지만, RealNVP는 scaling을 추가해 local volume 변화를 학습할 수 있다.
- MAF와 IAF는 서로 다른 model이라기보다 같은 autoregressive invertible map을 반대 방향으로 사용하는 관점에 가깝다.
- MLE training이 중요하면 MAF처럼 likelihood가 빠른 방향을, deployment sampling이 중요하면 IAF처럼 generation이 빠른 방향을 선호한다.
- Parallel WaveNet은 teacher-student distillation으로 training tractability와 fast inference를 분리한 대표 사례다.

## 마지막 핵심 정리

Lecture 8의 핵심은 normalizing flow가 하나의 수식이 아니라 architecture design problem이라는 점이다. Coupling, autoregressive masking, invertible convolution, Gaussianization은 모두 같은 목표를 가진다. 복잡한 transformation을 만들되, inverse와 Jacobian determinant는 학습 루프 안에서 계산 가능해야 한다.

## Study Guide

1. NICE additive coupling에서 왜 \(m_\theta\)가 arbitrary neural network여도 inverse가 쉬운지 직접 써 본다.
2. RealNVP의 determinant가 scale factor의 곱으로 정리되는 이유를 triangular Jacobian으로 설명한다.
3. MAF와 IAF를 sampling direction, likelihood direction, training suitability, deployment suitability 네 축으로 비교한다.
4. Parallel WaveNet에서 teacher는 왜 MAF가 적합하고 student는 왜 IAF가 적합한지 정리한다.
5. Gaussianization flow를 "data를 prior처럼 보이게 만드는 inverse flow" 관점에서 다시 설명한다.

## 복습 질문

<details>
<summary>1. NICE additive coupling layer가 invertible한 이유는 무엇인가?</summary>

답변: 입력의 앞부분 \(z_{1:d}\)를 그대로 출력 \(x_{1:d}\)로 보존하기 때문이다. 뒷부분은 \(m_\theta(z_{1:d})\)만큼 shift되지만, inverse에서도 \(x_{1:d}=z_{1:d}\)를 알고 있으므로 같은 shift를 다시 계산해 빼면 된다.

</details>

<details>
<summary>2. RealNVP가 NICE보다 표현력이 높은 이유는 무엇인가?</summary>

답변: NICE는 coupling layer가 shift만 수행해 determinant가 1인 volume-preserving transformation이다. RealNVP는 shift에 scale을 추가해 local volume을 늘리거나 줄일 수 있다. 따라서 density의 모양을 바꾸는 자유도가 더 크다.

</details>

<details>
<summary>3. MAF와 IAF의 tradeoff를 설명하라.</summary>

답변: MAF는 data \(x\)가 주어졌을 때 모든 conditional parameter를 병렬 계산할 수 있어 likelihood evaluation과 MLE training에 유리하지만, sampling은 순차적이다. IAF는 latent \(z\)에서 sample을 병렬로 만들 수 있어 generation이 빠르지만, 외부 data point를 latent로 invert하는 과정이 순차적이라 likelihood evaluation이 느리다.

</details>

<details>
<summary>4. Parallel WaveNet에서 density distillation이 가능한 이유는 무엇인가?</summary>

답변: Student IAF는 sample을 빠르게 만들고, 자기가 만든 sample의 latent noise를 알고 있어 자기 density도 계산할 수 있다. Teacher autoregressive model은 likelihood evaluation이 빠르다. 따라서 student sample에 대한 student density와 teacher density를 모두 평가해 KL objective를 최적화할 수 있다.

</details>

<details>
<summary>5. Flow model을 language model에 그대로 적용하기 어려운 이유는 무엇인가?</summary>

답변: Normalizing flow의 change of variables는 continuous random variable의 density에 대한 공식이다. Language token은 discrete random variable이고 probability mass function을 다루므로, continuous invertible map과 Jacobian determinant를 그대로 적용하기 어렵다.

</details>

<details>
<summary>6. Gaussianization flow는 normalizing flow 학습을 어떤 방향에서 해석하는가?</summary>

답변: Forward direction에서는 Gaussian prior sample을 data distribution처럼 보이게 만든다. Inverse direction에서는 실제 data sample을 Gaussian prior처럼 보이게 만든다. Gaussianization flow는 이 inverse 관점에서 각 layer가 data를 점점 더 Gaussian하게 만드는 절차로 이해할 수 있다.

</details>

## PDF

- [Official Lecture 8 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture8.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=qgTvgBCOyn8){:target="_blank" rel="noopener"}
- [Lecture slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture8.pdf){:target="_blank" rel="noopener"}
- [CS236 course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
