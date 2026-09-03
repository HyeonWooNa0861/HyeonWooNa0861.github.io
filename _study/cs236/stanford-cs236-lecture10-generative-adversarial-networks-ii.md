---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:55:00 +0900
title: "Stanford CS236 Lecture 10: Generative Adversarial Networks II"
course: "CS236"
topic: "f-GANs, Wasserstein GANs, BiGANs, and Cycle-Consistent Translation"
order: 10
major_topic: "Deep Generative Models"
keywords:
  - "f-GAN"
  - "Wasserstein GAN"
  - "BiGAN"
  - "CycleGAN"
  - "Likelihood-Free Learning"
---

# Stanford CS236 Lecture 10: Generative Adversarial Networks II

## Source

- Video: [Stanford CS236 Deep Generative Models Lecture 10](https://www.youtube.com/watch?v=M3Fkvu78ZXc){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture10.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture10.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 10은 GAN을 단순한 이미지 생성 기법이 아니라 `samples only` 조건에서 분포를 비교하는 방법으로 확장한다. 지난 강의의 기본 GAN은 generator $$G_\theta$$가 prior $$p(z)$$의 sample을 data space로 보내고, discriminator $$D_\phi$$가 real sample과 fake sample을 구분하는 minimax game이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | GAN recap | 기존 GAN objective는 왜 likelihood-free이고, 최적 discriminator는 어떤 divergence를 암시하는가? |
| 2 | f-divergence | KL, reverse KL, Jensen-Shannon divergence를 하나의 일반식으로 어떻게 묶는가? |
| 3 | f-GAN | Fenchel conjugate를 쓰면 density ratio 없이 f-divergence 하한을 어떻게 만들 수 있는가? |
| 4 | Wasserstein GAN | support가 어긋난 분포에서는 왜 f-divergence보다 smoother distance가 필요한가? |
| 5 | BiGAN | GAN generator의 latent variable을 real data에서 어떻게 추론할 수 있는가? |
| 6 | CycleGAN and variants | paired data 없이 domain translation을 학습하려면 어떤 constraint가 필요한가? |

### 원본 수식 위치

| 원본 PDF | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| p. 2 | 기본 GAN minimax objective와 Jensen--Shannon 해석 | `핵심 내용`의 recap; 원문 objective이며 별도 증명이 필요한 정의가 아니다. |
| pp. 5--10 | f-divergence, Fenchel conjugate, variational lower bound | `핵심 수식 유도`에서 원문 식과 작성자 보충 유도를 구분한다. |
| pp. 12--14 | Support mismatch, Wasserstein primal·dual, WGAN objective | `Wasserstein-1의 primal과 dual`에서 정의, duality 증명 개요, neural critic 근사를 구분한다. |
| pp. 16--19 | BiGAN의 encoder·generator joint two-sample objective | `핵심 내용`과 `핵심 개념`에서 원문 모델 정의로 설명한다. |
| pp. 20--24 | CycleGAN adversarial/cycle loss와 AlignFlow의 exact cycle consistency | `핵심 내용`에서 원문 제약식과 architecture 결과를 설명한다. |

## 핵심 내용

Lecture 10은 GAN을 단순한 이미지 생성 기법이 아니라 `samples only` 조건에서 분포를 비교하는 방법으로 확장한다. 지난 강의의 기본 GAN은 generator $$G_\theta$$가 prior $$p(z)$$의 sample을 data space로 보내고, discriminator $$D_\phi$$가 real sample과 fake sample을 구분하는 minimax game이다. 최적 discriminator가 주어졌다고 가정하면 이 objective는 data distribution과 model distribution 사이의 Jensen-Shannon divergence를 shift와 scale만 다르게 최소화하는 형태로 해석된다. 중요한 점은 likelihood를 계산하지 않아도 된다는 것이다. 모델은 $$p_\theta(x)$$를 직접 평가하지 않고 sample만 만들 수 있으면 된다.

강의의 첫 확장은 f-divergence다. 두 density $$p,q$$에 대해

$$
D_f(p,q)=\mathbb{E}_{x\sim q}\left[f\left(\frac{p(x)}{q(x)}\right)\right]
$$

로 정의하며, $$f$$는 convex이고 $$f(1)=0$$인 함수다. $$f(u)=u\log u$$를 택하면 KL divergence, $$f(u)=-\log u$$를 택하면 reverse KL, 적절한 다른 $$f$$를 택하면 Jensen-Shannon divergence나 total variation 같은 다양한 기준이 나온다. Jensen's inequality 때문에 $$D_f(p,q)\ge 0$$이고 $$p=q$$이면 0이 된다. 문제는 식 안에 $$p(x)/q(x)$$가 들어간다는 점이다. data distribution의 likelihood는 알 수 없고, likelihood-free 모델에서는 model likelihood도 알 수 없다.

f-GAN은 이 density ratio 문제를 Fenchel conjugate로 우회한다. $$f^*(t)=\sup_u(ut-f(u))$$를 쓰면 convex $$f$$에 대해 $$f=f^{**}$$가 되고, f-divergence는 다음과 같은 variational lower bound로 바뀐다.

$$
D_f(p,q)\ge \sup_{T\in\mathcal{T}}\left(\mathbb{E}_{x\sim p}[T(x)]-\mathbb{E}_{x\sim q}[f^*(T(x))]\right)
$$

여기서 $$T$$는 discriminator 또는 critic 역할을 하는 함수다. $$p=p_{\mathrm{data}}$$, $$q=p_G$$로 두면 data sample과 generator sample에 대한 expectation만 남는다. 그래서 f-GAN objective는 $$G_\theta$$가 divergence estimate를 낮추고, $$T_\phi$$가 하한을 조이는 minimax problem이 된다. 단, 실제 neural network $$T_\phi$$는 모든 함수 공간을 표현하지 못하므로 이것은 정확한 divergence 최소화가 아니라 discriminator family에 제한된 근사다.

두 번째 확장은 Wasserstein GAN이다. f-divergence는 두 분포의 support가 겹치지 않을 때 학습 신호가 나빠질 수 있다. 예를 들어 모든 질량이 0에 있는 $$p$$와 모든 질량이 $$\theta$$에 있는 $$q_\theta$$를 비교하면 KL은 $$\theta\ne 0$$에서 무한대, Jensen-Shannon은 상수처럼 행동할 수 있다. 이때 $$\theta=0.5$$가 $$\theta=10$$보다 낫다는 부드러운 신호가 잘 드러나지 않는다. Wasserstein distance는 probability mass를 옮기는 비용으로 거리를 정의하므로 이 예에서는 $$D_W(p,q_\theta)=\lvert\theta\rvert$$처럼 더 연속적인 학습 신호를 준다.

WGAN은 Kantorovich-Rubinstein duality를 사용해

$$
D_W(p,q)=\sup_{\lVert f\rVert_L\le 1}\mathbb{E}_{x\sim p}[f(x)]-\mathbb{E}_{x\sim q}[f(x)]
$$

를 최적화한다. critic $$f$$는 1-Lipschitz 함수여야 하며, 실제 구현에서는 weight clipping이나 gradient penalty로 이를 근사한다. 강의가 강조하는 장점은 더 안정적인 training signal과 mode collapse 완화다. 다만 Lipschitz constraint를 완벽히 만족시키는 것은 어렵고, 실제 WGAN critic도 정확한 Wasserstein distance 계산이라기보다 좋은 근사 목적함수로 이해해야 한다.

마지막 부분은 GAN을 representation learning과 domain translation으로 확장한다. 일반 GAN은 $$z\mapsto x$$ 방향의 generator만 있으므로 real $$x$$에 대응하는 $$z$$를 직접 얻기 어렵다. BiGAN은 encoder $$E:x\mapsto z$$를 추가하고, discriminator가 $$(G(z),z)$$와 $$(x,E(x))$$의 pair를 구분하게 한다. 훈련 후에는 $$G$$로 sample을 만들고 $$E$$로 real data의 latent representation을 얻을 수 있다.

CycleGAN은 paired example 없이 domain $$X$$와 $$Y$$ 사이를 번역하기 위해 $$G:X\to Y$$, $$F:Y\to X$$ 두 mapping과 두 discriminator를 둔다. adversarial loss만 쓰면 입력의 의미를 보존하지 못할 수 있으므로 $$F(G(X))\approx X$$, $$G(F(Y))\approx Y$$라는 cycle consistency를 추가한다. AlignFlow는 $$G$$를 flow model로 두어 $$F=G^{-1}$$를 얻고 exact cycle consistency를 만족시키는 관점이며, StarGAN은 여러 domain을 하나의 조건부 generator로 다루는 확장이다.

### 핵심 수식 유도: f-divergence의 variational lower bound

> **Source mapping:** Official Lecture 10 PDF pp. 7, 9--10의 f-divergence variational objective에 대응한다. 아래 Fenchel 부등식 전개는 작성자가 보충한 유도다.

$$f$$가 convex이고 $$f(1)=0$$이며 $$p$$가 $$q$$에 대해 절대연속이라고 가정한다. Fenchel conjugate 정의에서 $$f(u)+f^*(t)\ge tu$$이므로, $$u=p(x)/q(x)$$와 판별함수 $$T(x)$$를 대입해

$$
\begin{aligned}
D_f(p,q)
&=\mathbb{E}_{q}\left[f\left(\frac pq\right)\right]\\
&\ge \mathbb{E}_{p}[T(x)]-\mathbb{E}_{q}[f^*(T(x))]
\end{aligned}
$$

을 얻는다. 이는 **하한**이다. $$f$$가 $$p/q$$에서 미분 가능하고 함수족이 $$T^*(x)=f'(p/q)$$를 표현하면 tight해진다. 일반적인 비미분 convex $$f$$에서는 $$T^*(x)\in\partial f(p/q)$$인 subgradient를 선택할 수 있어야 한다. Continuous 공간의 $$p,q$$는 좌표 부피의 역단위를 갖는 density일 수 있지만 비율 $$p/q$$, $$T$$, divergence는 무차원이다. Neural discriminator가 제한되거나 support가 어긋나면 bound가 느슨해져 실제 학습을 원래 f-divergence의 정확한 최소화로 해석할 수 없다.

### Wasserstein-1의 primal과 dual (작성자 보충; 강의 슬라이드 13--14의 식 전개)

> **Source mapping:** Official Lecture 10 PDF p. 13의 primal Earth-Mover 정의와 p. 14의 Kantorovich--Rubinstein dual/WGAN objective에 대응한다.

먼저 $$d(x,y)=\lVert x-y\rVert_1$$를 data space의 ground metric으로 두고, $$\Pi(p,q)$$를 첫 번째 marginal이 $$p$$이고 두 번째 marginal이 $$q$$인 모든 coupling의 집합으로 정의한다. 강의의 Earth-Mover **primal 정의**는

$$
W_1(p,q)
=\inf_{\gamma\in\Pi(p,q)}
\mathbb E_{(x,y)\sim\gamma}[d(x,y)]
$$

이다. 즉 $$\gamma$$가 어느 $$x$$의 질량을 어느 $$y$$로 보낼지 정하고, 그중 평균 운송비가 가장 작은 계획을 고른다. 이것은 정의이므로 exact하며, $$p,q$$가 유한한 first moment를 가져야 값이 유한하다.

**Dual로 가는 증명 개요.** Transport 제약에 potential $$\varphi(x),\psi(y)$$를 붙여 선형계획 dual을 만들면

$$
W_1(p,q)
=\sup_{\varphi(x)+\psi(y)\le d(x,y)}
\left(\mathbb E_p[\varphi(x)]+\mathbb E_q[\psi(y)]\right)
$$

을 얻는다. Ground cost가 metric이면 triangle inequality를 이용한 $$c$$-transform으로 최적 potential을 $$\psi=-\varphi$$로 잡을 수 있고, 제약은 $$\varphi(x)-\varphi(y)\le d(x,y)$$가 된다. $$x,y$$를 바꾼 식까지 합치면 $$\lvert\varphi(x)-\varphi(y)\rvert\le d(x,y)$$, 즉 $$\varphi$$가 1-Lipschitz라는 조건이다. 따라서 Kantorovich--Rubinstein duality는

$$
W_1(p,q)
=\sup_{\lVert\varphi\rVert_L\le1}
\left(\mathbb E_p[\varphi(x)]-\mathbb E_q[\varphi(x)]\right)
$$

로 이어진다. 이 등식 자체는 Polish metric space와 유한 first moment 같은 표준 조건 아래 exact하지만, 위 문단은 functional-analytic 세부를 생략한 **증명 개요**다.

좌표 $$x$$와 metric $$d$$의 단위가 $$U$$이면 $$W_1$$과 critic $$\varphi$$의 출력도 $$U$$이고 Lipschitz 비율은 무차원이다. 좌표별 단위가 다르면 정규화 없이 $$\ell_1$$ 비용을 더하는 것부터 의미가 불분명하다. Neural critic, weight clipping, sampled-line gradient penalty는 1-Lipschitz 함수 전체의 supremum을 푸는 **근사**일 뿐이다. Ground cost가 metric이 아니거나 first moment가 무한하면 metric 해석이 깨지고, 유한 표본의 empirical Wasserstein 값은 고차원에서 sample complexity가 나쁘며, support 사이 경로에서만 검사한 gradient penalty는 전역 Lipschitz 조건을 보장하지 않는다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| f-divergence | convex 함수 $$f$$로 density ratio를 scoring하는 분포 차이 척도다. $$f$$ 선택에 따라 KL, reverse KL, JS divergence 등이 된다. |
| Fenchel conjugate | $$f^*(t)=\sup_u(ut-f(u))$$. f-divergence를 sample expectation 기반 lower bound로 바꾸는 도구다. |
| f-GAN | 선택한 f-divergence를 GAN-like minimax objective로 근사하는 framework다. |
| Wasserstein distance | probability mass를 옮기는 최소 비용으로 분포 차이를 재는 거리다. support가 달라도 부드러운 신호를 줄 수 있다. |
| Lipschitz critic | WGAN에서 critic이 너무 급격히 변하지 않도록 제한된 함수다. weight clipping 또는 gradient penalty로 근사한다. |
| BiGAN | generator와 encoder를 함께 학습해 sample 생성과 latent representation 추론을 동시에 가능하게 한다. |
| Cycle consistency | $$X\to Y\to X$$ 또는 $$Y\to X\to Y$$로 돌아왔을 때 원본이 복원되어야 한다는 constraint다. |

## 학습 포인트

- GAN은 likelihood-free two-sample test로 볼 수 있으며, discriminator는 real/fake classification을 통해 density ratio 정보를 간접적으로 학습한다.
- f-GAN의 핵심은 "원하는 f-divergence를 먼저 고르고, 그에 맞는 GAN-like objective를 만든다"는 방향이다.
- f-GAN lower bound는 discriminator가 충분히 강하고 최적으로 학습될 때 tight해진다. 실제 학습에서는 bound를 최소화한다는 점 때문에 근사 오차를 항상 염두에 둬야 한다.
- Wasserstein distance는 분포 support가 겹치지 않아도 거리가 연속적으로 변하므로 generator에게 더 유용한 gradient를 줄 수 있다.
- BiGAN의 discriminator는 image만 보지 않고 $$(x,z)$$ pair를 본다. 이 때문에 encoder의 latent가 generator prior와 호환되도록 학습된다.
- CycleGAN의 cycle consistency는 unpaired translation에서 content preservation을 강제하는 핵심 장치다.

## 마지막 핵심 정리

Lecture 10의 핵심은 GAN을 "특정 모델"이 아니라 "sample만으로 분포를 비교하는 학습 원리"로 보는 것이다. f-GAN은 어떤 divergence를 근사할지 선택할 수 있게 하고, WGAN은 support mismatch에서 더 좋은 학습 신호를 주며, BiGAN과 CycleGAN은 같은 adversarial idea를 representation inference와 domain translation으로 확장한다.

## Study Guide

1. 기본 GAN objective가 최적 discriminator 아래에서 Jensen-Shannon divergence와 연결되는 이유를 먼저 복습한다.
2. $$D_f(p,q)$$ 정의에서 expectation 기준이 $$q$$이고 ratio가 $$p/q$$라는 점을 확인한다. KL과 reverse KL은 $$f$$ 선택과 인자 순서가 함께 바뀐다.
3. Fenchel conjugate derivation은 모든 세부 증명보다 "density ratio가 expectation 밖으로 선형화되고, sample expectation 두 개로 바뀐다"는 흐름을 잡는 것이 중요하다.
4. WGAN은 cross-entropy discriminator가 아니라 real sample에는 높은 값, fake sample에는 낮은 값을 주는 critic을 학습한다는 차이를 기억한다.
5. BiGAN과 CycleGAN은 GAN의 discriminator 입력을 바꾸거나 consistency loss를 추가해 downstream 목적을 확장한 사례로 정리한다.

## 복습 질문

<details markdown="block">
<summary>1. f-GAN은 왜 likelihood-free training으로 볼 수 있는가?</summary>

답변: Fenchel conjugate를 사용하면 f-divergence의 lower bound가 data sample에 대한 $$T(x)$$ expectation과 model sample에 대한 $$f^*(T(x))$$ expectation으로 바뀐다. 따라서 $$p_{\mathrm{data}}(x)$$나 $$p_G(x)$$ 값을 직접 계산하지 않고 sample만으로 objective를 추정할 수 있다.

</details>

<details markdown="block">
<summary>2. f-GAN에서 discriminator가 최적이 아니면 어떤 문제가 생기는가?</summary>

답변: discriminator family가 충분히 넓지 않거나 최적화가 덜 되면 lower bound가 true f-divergence에 tight하지 않다. 그러면 generator는 실제 divergence가 아니라 부정확한 하한을 최소화할 수 있고, 학습 방향이 원하는 분포 일치와 어긋날 수 있다.

</details>

<details markdown="block">
<summary>3. Wasserstein distance가 disjoint support 상황에서 더 유리한 이유는 무엇인가?</summary>

답변: KL이나 JS divergence는 support가 겹치지 않을 때 무한대나 상수처럼 변해 gradient signal이 약할 수 있다. Wasserstein distance는 probability mass를 얼마나 멀리 옮겨야 하는지 측정하므로, model distribution이 data distribution에 가까워지는 정도를 더 연속적으로 반영한다.

</details>

<details markdown="block">
<summary>4. WGAN에서 Lipschitz constraint가 필요한 이유는 무엇인가?</summary>

답변: Kantorovich-Rubinstein duality의 supremum은 1-Lipschitz 함수 집합 위에서 정의된다. constraint가 없으면 critic이 특정 지점에서 값을 arbitrarily 크게 만들어 objective가 폭주할 수 있으므로, weight clipping이나 gradient penalty로 critic의 변화율을 제한한다.

</details>

<details markdown="block">
<summary>5. BiGAN은 VAE의 encoder와 어떤 점이 비슷하고 다른가?</summary>

답변: 둘 다 real data $$x$$를 latent representation $$z$$로 보내는 encoder를 둔다는 점은 비슷하다. 하지만 VAE는 ELBO와 KL term으로 probabilistic posterior를 맞추고, BiGAN은 $$(x,z)$$ pair를 discriminator가 구분하지 못하도록 adversarial two-sample objective로 encoder를 학습한다.

</details>

<details markdown="block">
<summary>6. CycleGAN에서 cycle consistency가 없으면 어떤 문제가 생길 수 있는가?</summary>

답변: adversarial loss만 있으면 $$G(X)$$가 domain $$Y$$처럼 보이기만 하면 되므로 원본 $$X$$의 content를 보존하지 않아도 된다. cycle consistency는 $$F(G(X))\approx X$$를 요구해 translation이 입력 의미를 유지하도록 압력을 준다.

</details>

## PDF

- [Official Lecture 10 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture10.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 10 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture10.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 10 Video](https://www.youtube.com/watch?v=M3Fkvu78ZXc){:target="_blank" rel="noopener"}
