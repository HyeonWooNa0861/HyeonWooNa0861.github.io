---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 12: Energy-Based Models II"
course: "CS236"
topic: "Score Matching, Noise Contrastive Estimation, and Sampling-Free EBM Training"
order: 12
major_topic: "Deep Generative Models"
keywords:
  - "Energy-Based Models"
  - "Score Matching"
  - "Fisher Divergence"
  - "Noise Contrastive Estimation"
  - "Langevin MCMC"
---

# Stanford CS236 Lecture 12: Energy-Based Models II

## Source

- Video: [Stanford CS236 Deep Generative Models Lecture 12](https://www.youtube.com/watch?v=Nci1Bepcy0g){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture12.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 12는 EBM의 가장 큰 병목인 sampling과 likelihood 학습을 우회하는 방법을 다룬다. MCMC를 복습한 뒤 score matching, noise contrastive estimation, adversarial training처럼 model sampling 의존을 줄이는 학습법을 비교한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | EBM recap | \(Z(\theta)\) 때문에 likelihood와 sampling은 왜 어렵지만 ratio와 score는 가능한가? |
| 2 | MCMC sampling | Metropolis-Hastings와 Langevin dynamics는 EBM sample을 어떻게 만든다? |
| 3 | Score function | \(\nabla_x\log p_\theta(x)\)에서 partition function은 왜 사라지는가? |
| 4 | Score matching | data score를 몰라도 Fisher divergence를 어떻게 최적화 가능한 형태로 바꾸는가? |
| 5 | NCE | noise distribution과 binary classifier로 EBM과 partition function을 어떻게 학습하는가? |
| 6 | Adversarial EBM training | variational distribution을 사용하면 EBM likelihood를 어떤 game으로 바꿀 수 있는가? |

## 핵심 내용

Lecture 12는 EBM의 가장 큰 병목인 sampling과 likelihood 학습을 우회하는 방법을 다룬다. 지난 강의의 기본 형태는

$$
p_\theta(x)=\frac{\exp(f_\theta(x))}{Z(\theta)}
$$

였다. \(Z(\theta)\)를 계산하기 어렵기 때문에 likelihood를 직접 평가하기 어렵고, contrastive divergence로 maximum likelihood gradient를 근사하려면 매 training step마다 \(x_{\mathrm{sample}}\sim p_\theta\)를 뽑아야 한다. 그런데 EBM에서 sampling 자체도 어렵다. 이 강의는 먼저 MCMC sampling을 복습한 뒤, sampling 없이 또는 model sampling을 덜 요구하면서 EBM을 학습하는 score matching, noise contrastive estimation, adversarial training을 정리한다.

Metropolis-Hastings MCMC는 현재 상태 \(x_t\)에서 작은 perturbation으로 \(x'\)를 제안한다. \(f_\theta(x')\ge f_\theta(x_t)\)이면 항상 받아들이고, 더 낮은 score라면 \(\exp(f_\theta(x')-f_\theta(x_t))\) 확률로 받아들인다. 이 방식은 detailed balance를 만족하도록 설계되어 충분히 오래 반복하면 target distribution에 수렴할 수 있다. 그러나 high-dimensional image space에서는 많은 iteration이 필요하다.

Langevin MCMC는 더 informed proposal을 만든다.

$$
x_{t+1}=x_t+\epsilon\nabla_x\log p_\theta(x_t)+\sqrt{2\epsilon}z_t,\qquad z_t\sim\mathcal{N}(0,I)
$$

EBM에서는 \(Z(\theta)\)가 \(x\)에 의존하지 않으므로

$$
\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)
$$

가 된다. 즉 score direction을 따라 likelihood가 증가하는 쪽으로 움직이되, Gaussian noise를 섞어 exploration을 유지한다. 이 방법은 단순 random walk보다 낫지만, training inner loop에서 수천 step의 chain을 반복해야 한다면 여전히 비싸다. 따라서 이후 내용의 목표는 "model에서 sample을 뽑지 않고 학습할 수 있는 objective"를 찾는 것이다.

Score matching은 likelihood 자체가 아니라 score function을 맞춘다. Stein score는

$$
s_\theta(x)=\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)
$$

이며 partition function을 포함하지 않는다. 두 분포 \(p,q\)를 비교하는 Fisher divergence는

$$
D_F(p,q)=\frac{1}{2}\mathbb{E}_{x\sim p}\left[\lVert\nabla_x\log p(x)-\nabla_x\log q(x)\rVert_2^2\right]
$$

이다. \(p=p_{\mathrm{data}}\), \(q=p_\theta\)로 두면 data score \(\nabla_x\log p_{\mathrm{data}}(x)\)를 모른다는 문제가 남는다. 강의의 핵심 trick은 integration by parts다. data density가 boundary에서 충분히 빠르게 0으로 간다고 가정하면, unknown data score가 들어간 cross term을 model의 second derivative term으로 바꿀 수 있다. 다변량에서는 Gauss theorem으로 같은 결과를 얻고, 최적화 가능한 score matching loss는 상수항을 제외하면

$$
\mathbb{E}_{x\sim p_{\mathrm{data}}}\left[\frac{1}{2}\lVert\nabla_x f_\theta(x)\rVert_2^2+\mathrm{tr}(\nabla_x^2 f_\theta(x))\right]
$$

가 된다. 이 식은 training data와 model derivative만 필요하므로 EBM sampling이 필요 없다. 단점은 Hessian trace 계산이 크고 복잡한 neural network에서 비싸다는 것이다. 그래서 denoising score matching이나 sliced score matching 같은 scalable approximation이 중요해지며, 다음 diffusion model 강의와 직접 연결된다.

Noise Contrastive Estimation(NCE)은 data와 noise를 구분하는 binary classifier를 학습하되, discriminator를 EBM density 형태로 제한한다. noise distribution \(p_n(x)\)는 sample도 쉽고 likelihood도 계산 가능해야 한다. 이상적인 discriminator는

$$
D^*(x)=\frac{p_{\mathrm{data}}(x)}{p_{\mathrm{data}}(x)+p_n(x)}
$$

이다. 이제 discriminator를

$$
D_{\theta,Z}(x)=\frac{\exp(f_\theta(x))}{\exp(f_\theta(x))+Zp_n(x)}
$$

로 parameterize하고 cross-entropy를 최적화하면, \(f_\theta\)와 함께 \(Z\)도 trainable scalar로 학습된다. 이론적으로 optimal solution에서는 \(p_{\theta,Z}(x)=p_{\mathrm{data}}(x)\)가 되고, 학습된 \(Z\)가 true partition function이 된다. NCE는 GAN과 비슷하게 classifier를 쓰지만, generator를 adversarial하게 업데이트하지 않는다. noise distribution은 고정되어 있으며, EBM에서 sample을 뽑지 않아도 된다. 실제 성능은 \(p_n\)이 data distribution과 충분히 가깝고도 구분 가능해야 한다는 선택 문제에 크게 의존한다.

Flow contrastive estimation은 이 noise distribution 자체를 normalizing flow \(p_{n,\phi}\)로 parameterize해 더 좋은 contrast를 만들려는 확장이다. noise가 data와 너무 멀면 classification이 쉬워져 EBM이 세밀한 구조를 배우기 어렵고, 너무 같으면 구분할 신호가 사라진다. flow를 이용하면 sampling과 likelihood evaluation이 모두 가능하면서 data에 가까운 noise를 학습할 수 있다.

마지막으로 adversarial training for EBMs는 log-likelihood를 variational distribution \(q_\phi(x)\)로 upper bound하여

$$
\max_\theta\min_\phi\ \mathbb{E}_{x\sim p_{\mathrm{data}}}[f_\theta(x)]-\mathbb{E}_{x\sim q_\phi}[f_\theta(x)]-H(q_\phi)
$$

형태의 game을 만든다. \(q_\phi\)는 EBM이 높게 평가하는 negative sample을 제공하고, entropy term은 \(q_\phi\)가 한 점에 collapse하지 않도록 한다. 이 관점은 GAN과 닮았지만, 목적은 deterministic generator를 학습하는 것이 아니라 EBM의 likelihood 학습을 근사하는 데 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | \(\nabla_x\log p_\theta(x)\). EBM에서는 partition function이 사라져 \(\nabla_x f_\theta(x)\)로 계산된다. |
| Metropolis-Hastings MCMC | proposal을 만들고 probability ratio에 따라 accept/reject하여 target distribution을 sampling하는 절차다. |
| Langevin MCMC | score gradient와 Gaussian noise를 결합해 continuous state space에서 더 informed sampling을 수행한다. |
| Fisher divergence | 두 분포의 score field 차이를 평균 제곱으로 측정하는 divergence다. |
| Score matching | Fisher divergence를 최소화해 EBM을 학습하는 방법이며 model sampling이 필요 없다. |
| Noise Contrastive Estimation | data와 tractable noise를 구분하는 classifier를 통해 EBM과 partition function estimate를 함께 학습한다. |
| Flow contrastive estimation | noise distribution을 normalizing flow로 학습해 NCE의 noise 선택 문제를 완화한다. |

## 학습 포인트

- \(\nabla_\theta\log p_\theta(x)\)와 \(\nabla_x\log p_\theta(x)\)를 구분해야 한다. 전자는 learning gradient이고 \(Z(\theta)\)가 문제지만, 후자는 score이고 \(Z(\theta)\)가 \(x\)에 대해 상수라 사라진다.
- Contrastive divergence는 이론적으로 maximum likelihood gradient를 근사하지만, 매번 EBM sample이 필요해 비용이 크다.
- Score matching은 data score를 직접 알 필요가 없어 보이지 않지만, integration by parts를 통해 data score를 제거한다.
- Hessian trace는 score matching의 실제 병목이다. 이 때문에 denoising score matching과 sliced score matching이 diffusion model에서 핵심적인 practical form으로 등장한다.
- NCE는 GAN처럼 cross-entropy classifier를 쓰지만, minimax가 아니라 EBM parameter와 \(Z\)를 직접 학습한다.
- 좋은 NCE noise distribution은 data와 너무 멀지 않아야 한다. 쉬운 classifier는 좋은 density model을 강제하지 못한다.

## 마지막 핵심 정리

Lecture 12의 핵심은 EBM 학습에서 partition function과 model sampling을 피하는 세 가지 길이다. Score matching은 score field를 맞춰 \(Z(\theta)\)를 제거하고, NCE는 tractable noise와 classifier로 \(Z\)까지 추정하며, adversarial EBM training은 negative distribution을 학습해 likelihood objective를 근사한다. 이 중 score matching은 다음 강의의 score-based model과 diffusion model을 이해하는 직접적인 기반이다.

## Study Guide

1. MCMC sampling과 contrastive divergence의 관계를 먼저 정리한다. contrastive divergence가 왜 sampling-free가 아닌지 확인한다.
2. \(Z(\theta)\)가 \(\theta\)에는 의존하지만 \(x\)에는 의존하지 않는다는 점을 이용해 score function 식을 직접 유도한다.
3. Fisher divergence 식에서 data score가 문제로 보이는 이유와 integration by parts가 이를 제거하는 위치를 구분한다.
4. Score matching, NCE, adversarial EBM training을 필요한 외부 객체 기준으로 비교한다: Hessian, noise distribution, variational sampler.
5. Diffusion model을 공부할 때는 denoising score matching이 "score matching의 scalable approximation"이라는 연결고리를 기억한다.

## 복습 질문

<details>
<summary>1. EBM에서 score function이 partition function을 포함하지 않는 이유는 무엇인가?</summary>

답변: \(\log p_\theta(x)=f_\theta(x)-\log Z(\theta)\)이고 \(Z(\theta)\)는 model parameter에는 의존하지만 입력 \(x\)에는 의존하지 않는다. 따라서 \(x\)에 대해 미분하면 \(\nabla_x\log Z(\theta)=0\)이 되어 \(\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)\)만 남는다.

</details>

<details>
<summary>2. Langevin MCMC에서 noise를 추가하는 이유는 무엇인가?</summary>

답변: gradient만 따르면 local maximum을 찾는 optimization이 되기 쉽다. Sampling은 distribution 전체를 탐색해야 하므로 Gaussian noise를 넣어 주변을 탐색하고, 확률 질량이 있는 여러 영역을 방문할 수 있게 한다.

</details>

<details>
<summary>3. Score matching이 data score를 모르는 문제를 어떻게 해결하는가?</summary>

답변: Fisher divergence를 전개하면 data score가 들어간 cross term이 생긴다. Integration by parts와 boundary decay 가정을 사용하면 이 항을 model log-density의 second derivative expectation으로 바꿀 수 있고, 최종 loss는 data sample과 model derivative만으로 계산된다.

</details>

<details>
<summary>4. Score matching의 practical bottleneck은 무엇인가?</summary>

답변: 다변량 score matching loss에는 \(\mathrm{tr}(\nabla_x^2 f_\theta(x))\), 즉 Hessian trace가 들어간다. 큰 neural network와 high-dimensional input에서는 이 값을 정확히 계산하기 위해 많은 autodiff 연산이 필요하므로 비용이 크다.

</details>

<details>
<summary>5. NCE는 GAN과 어떤 점이 같고 어떤 점이 다른가?</summary>

답변: 둘 다 real sample과 다른 sample을 구분하는 binary classifier와 cross-entropy loss를 사용한다. 하지만 GAN은 generator와 discriminator의 minimax training이고 fake sample은 generator에서 오며, NCE는 fixed 또는 tractable noise distribution을 사용하고 discriminator 자체를 EBM density 형태로 제한해 \(f_\theta\)와 \(Z\)를 학습한다.

</details>

<details>
<summary>6. NCE에서 noise distribution이 data와 너무 멀면 왜 문제가 되는가?</summary>

답변: classification task가 너무 쉬워져 classifier가 data distribution의 섬세한 구조를 배울 필요가 줄어든다. NCE는 discriminator가 data와 noise의 density ratio를 학습하도록 압력을 주는 방법이므로, noise는 sampling과 likelihood 계산이 가능하면서도 data에 충분히 가까워야 한다.

</details>

## PDF

- [Official Lecture 12 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 12 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 12 Video](https://www.youtube.com/watch?v=Nci1Bepcy0g){:target="_blank" rel="noopener"}
- [How to Train Your Energy-Based Models](https://arxiv.org/abs/2101.03288){:target="_blank" rel="noopener"}
