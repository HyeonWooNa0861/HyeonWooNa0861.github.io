---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 7: Normalizing Flows I"
course: "CS236"
topic: "Normalizing Flow Foundations"
order: 7
major_topic: "Deep Generative Models"
keywords:
  - "Normalizing Flows"
  - "Change of Variables"
  - "VAE"
  - "Jacobian Determinant"
  - "Planar Flow"
---

# Stanford CS236 Lecture 7: Normalizing Flows I

Source: [Stanford CS236 Deep Generative Models 2023 Lecture 7](https://www.youtube.com/watch?v=m6dKKRsZwBQ){:target="_blank" rel="noopener"}

Source PDF: [lecture07-normalizing-flows-i.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture7.pdf){:target="_blank" rel="noopener"}

> **핵심:** 이 강의는 먼저 VAE를 autoencoder로 다시 해석하면서 시작한다. VAE의 encoder \(q_\phi(z \mid x)\)는 입력 \(x\)를 latent variable distribution으로 보내고, decoder \(p_\theta(x \mid z)\)는 그 latent sample에서 원래 입력이 얼마나 잘 설명되는지 평가한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | VAE의 autoencoder 해석 | ELBO의 reconstruction term과 KL term은 왜 생성 모델을 만들기 위한 두 압력인가? |
| 2 | 단순 prior에서 복잡한 데이터로 | Gaussian처럼 다루기 쉬운 분포를 어떻게 multimodal data distribution으로 바꿀 수 있는가? |
| 3 | 1차원 change of variables | \(X=f(Z)\)일 때 왜 단순히 inverse point의 density만 보면 안 되는가? |
| 4 | 벡터 변수와 determinant | 선형 변환과 비선형 변환에서 volume correction은 어떻게 Jacobian determinant로 표현되는가? |
| 5 | Normalizing flow 정의 | VAE와 비슷한 latent variable model이면서 exact likelihood를 갖기 위한 조건은 무엇인가? |
| 6 | Flow composition과 학습 | 여러 invertible transformation을 쌓으면 likelihood, sampling, representation inference가 어떻게 연결되는가? |
| 7 | 효율적인 Jacobian 구조 | \(O(n^3)\) determinant 계산을 피하려면 어떤 transformation 구조가 필요한가? |
| 8 | Planar flow 예시 | 간단한 residual 형태의 변환은 어떤 장점과 invertibility 제약을 갖는가? |

## 핵심 내용

이 강의는 먼저 VAE를 autoencoder로 다시 해석하면서 시작한다. VAE의 encoder \(q_\phi(z \mid x)\)는 입력 \(x\)를 latent variable distribution으로 보내고, decoder \(p_\theta(x \mid z)\)는 그 latent sample에서 원래 입력이 얼마나 잘 설명되는지 평가한다. 이때 reconstruction term은 입력을 잘 복원하도록 만들고, KL term은 encoder가 만들어내는 latent distribution이 prior \(p(z)\)와 크게 멀어지지 않도록 압박한다. 따라서 VAE는 단순한 autoencoder가 아니라, generation time에 \(x\) 없이 prior에서 \(z\)를 뽑아 decoder에 넣을 수 있도록 latent space를 regularize한 stochastic autoencoder로 볼 수 있다.

하지만 VAE에는 근본적인 계산 문제가 남는다. \(p_\theta(x)=\int p_\theta(x,z)dz\)를 정확히 계산하려면 주어진 \(x\)를 만들 수 있는 모든 \(z\)를 고려해야 한다. VAE는 encoder를 사용해 이 posterior를 근사하지만, likelihood 자체는 ELBO라는 lower bound로 다룬다. Normalizing flow는 여기서 다른 선택을 한다. \(z\)에서 \(x\)로 가는 mapping을 stochastic decoder가 아니라 deterministic하고 invertible한 함수 \(x=f_\theta(z)\)로 설계한다. 그러면 어떤 \(x\)가 들어와도 대응되는 \(z=f_\theta^{-1}(x)\)가 하나로 정해지고, posterior enumeration이 사라진다.

핵심 수학은 change of variables formula다. 1차원에서 \(X=f(Z)\), \(h=f^{-1}\)라면 density는

$$
p_X(x)=p_Z(h(x))\left|h'(x)\right|.
$$

강의는 \(Z \sim U[0,2]\), \(X=4Z\) 예시로 단순 치환이 왜 틀리는지 보여 준다. \(p_Z(1)=1/2\)만 보면 \(p_X(4)=1/2\)처럼 보이지만, 실제 \(X\)는 \([0,8]\)에서 uniform이므로 \(1/8\)이어야 한다. 빠진 항은 transformation이 길이를 4배 늘렸다는 volume correction이다. \(X=\exp(Z)\) 예시에서는 inverse가 \(\log x\)이고 derivative가 \(1/x\)이므로, 단순 uniform prior도 변환 뒤에는 다른 모양의 density가 된다.

벡터 변수에서는 길이 대신 부피가 바뀐다. 선형 변환 \(X=AZ\)는 unit hypercube를 parallelotope로 보내고, 부피 변화는 \(|\det(A)|\)로 주어진다. 비선형 함수에서는 한 점 근방을 선형화한 Jacobian이 같은 역할을 한다. 따라서 general change of variables는

$$
p_X(x;\theta)=p_Z(f_\theta^{-1}(x))\left|\det\frac{\partial f_\theta^{-1}(x)}{\partial x}\right|
$$

또는 forward Jacobian을 사용해 같은 내용을 표현한다. 이 식 때문에 flow는 exact likelihood를 계산할 수 있지만, 동시에 \(x\)와 \(z\)가 continuous이고 같은 차원을 가져야 한다. VAE처럼 압축된 latent representation을 얻는 대신, tractable likelihood와 exact inverse를 얻는 tradeoff가 생긴다.

Flow라는 이름은 invertible transformation을 여러 개 합성할 수 있다는 데서 온다. \(z_0\)를 Gaussian 같은 simple prior에서 뽑고, \(z_m=f_{\theta_m}(z_{m-1})\)를 반복해 마지막 \(z_M=x\)를 만든다. Sampling은 forward direction \(z \rightarrow x\), likelihood evaluation은 inverse direction \(x \rightarrow z\)로 진행된다. 각 layer의 Jacobian determinant를 계산할 수 있으면 전체 determinant는 layer별 determinant의 곱으로 정리되므로, deep transformation을 쌓아도 likelihood를 추적할 수 있다.

가장 큰 병목은 Jacobian determinant 계산이다. 일반적인 \(n \times n\) matrix determinant는 \(O(n^3)\)이고, image처럼 차원이 큰 데이터에서는 매 training step마다 계산하기 어렵다. 그래서 flow model의 설계 핵심은 expressive한 변환을 만들면서도 Jacobian에 triangular, diagonal, low-rank update 같은 계산하기 쉬운 구조를 강제로 주는 것이다. 강의는 triangular Jacobian을 예로 들어, \(x_i=f_i(z_{\le i})\)처럼 각 출력이 이전 입력에만 의존하면 determinant가 diagonal entry의 곱이 되어 \(O(n)\)에 계산된다고 설명한다.

마지막으로 planar flow는 \(x=z+u h(w^\top z+b)\) 형태의 간단한 invertible transformation 예시로 소개된다. Matrix determinant lemma를 쓰면 determinant가 \(1+h'(w^\top z+b)u^\top w\)처럼 작게 계산된다. 다만 이 변환이 항상 invertible한 것은 아니므로, activation과 parameter에 제약을 둬야 한다. 이 예시는 이후 강의에서 다룰 coupling layer, autoregressive flow, invertible convolution처럼 "표현력과 Jacobian tractability를 동시에 설계한다"는 흐름의 출발점이다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Variational Autoencoder | Encoder가 latent distribution을 만들고 decoder가 reconstruction likelihood를 평가하는 stochastic autoencoder 관점의 latent variable model이다. |
| KL Regularization | Encoder posterior가 prior와 맞도록 만들어, generation time에 prior sample을 decoder 입력으로 쓸 수 있게 한다. |
| Normalizing Flow | Simple prior를 invertible deterministic transformation으로 complex data distribution에 매핑하는 generative model이다. |
| Change of Variables | Inverse point의 density에 derivative 또는 Jacobian determinant 기반 volume correction을 곱해 transformed density를 계산한다. |
| Jacobian Determinant | Local volume expansion 또는 contraction을 나타내며, flow likelihood의 핵심 correction term이다. |
| Triangular Jacobian | Determinant를 diagonal product로 계산할 수 있어 high-dimensional flow 학습을 가능하게 하는 구조다. |
| Planar Flow | \(x=z+u h(w^\top z+b)\) 형태의 단순 flow layer로, low-rank Jacobian 구조를 활용한다. |

## 학습 포인트

- VAE의 reconstruction term만 보면 stochastic autoencoder이지만, KL term이 있어야 prior sampling으로 새로운 데이터를 생성할 수 있다.
- Normalizing flow는 VAE의 intractable marginal likelihood 문제를 "decoder를 invertible deterministic mapping으로 제한"하는 방식으로 해결한다.
- \(p_Z(f^{-1}(x))\)만으로는 transformed density가 되지 않는다. 변환이 공간을 얼마나 늘리거나 줄였는지 반드시 보정해야 한다.
- Flow는 exact likelihood, exact latent inference, direct sampling을 모두 제공하지만, continuous same-dimensional \(x,z\)라는 제약을 갖는다.
- 실제 flow architecture의 성패는 neural network 표현력보다 Jacobian determinant를 빠르게 계산할 수 있는 구조 설계에 크게 달려 있다.

## 마지막 핵심 정리

Lecture 7의 핵심은 "복잡한 분포를 직접 만들지 말고, 단순한 분포를 invertible map으로 변형하자"는 아이디어다. 이때 change of variables formula가 likelihood를 제공하고, Jacobian determinant가 변환의 volume correction을 담당한다. Flow는 VAE보다 제한적인 mapping을 쓰는 대신 exact likelihood를 얻는다.

## Study Guide

1. VAE의 ELBO를 reconstruction term과 KL regularization으로 나누어, 왜 generation time에는 encoder가 필요 없는지 설명해 본다.
2. \(Z \sim U[0,2]\), \(X=4Z\) 예시를 직접 계산해 change of variables의 derivative term이 왜 필요한지 확인한다.
3. 1차원 derivative correction과 다차원 Jacobian determinant correction을 같은 volume 보존 관점에서 연결한다.
4. Flow에서 \(x\)와 \(z\)가 같은 차원이어야 하는 이유를 invertibility 조건으로 설명한다.
5. Triangular Jacobian이 왜 determinant 계산을 \(O(n)\)으로 줄이는지 matrix 구조를 그려 본다.

## 복습 질문

<details>
<summary>1. VAE가 일반 autoencoder와 다른 핵심 이유는 무엇인가?</summary>

답변: 일반 autoencoder는 입력을 deterministic code로 압축하고 다시 복원하는 데 초점이 있다. VAE는 \(q_\phi(z \mid x)\)라는 stochastic encoder를 사용하고, KL term으로 latent distribution을 prior와 맞춘다. 그래서 학습 후에는 입력 \(x\) 없이 prior에서 \(z\)를 샘플링해 decoder로 새로운 데이터를 생성할 수 있다.

</details>

<details>
<summary>2. Normalizing flow가 VAE의 marginal likelihood 문제를 피하는 방식은 무엇인가?</summary>

답변: VAE는 하나의 \(x\)를 만들 수 있는 여러 \(z\)를 적분해야 하므로 \(p_\theta(x)\)가 intractable하다. Flow는 \(x=f_\theta(z)\)를 deterministic하고 invertible하게 만들어, 각 \(x\)에 대응되는 \(z=f_\theta^{-1}(x)\)가 하나뿐이게 한다. 따라서 posterior enumeration 없이 change of variables로 exact likelihood를 계산한다.

</details>

<details>
<summary>3. Change of variables에서 Jacobian determinant는 어떤 의미를 갖는가?</summary>

답변: Jacobian determinant는 변환이 특정 점 주변의 작은 부피를 얼마나 늘리거나 줄이는지 나타낸다. Density는 전체 probability mass가 보존되도록 부피 변화에 반대로 보정되어야 하므로, transformed density 계산에는 inverse Jacobian determinant 또는 forward Jacobian determinant의 역수가 들어간다.

</details>

<details>
<summary>4. Flow model의 장점과 제약을 함께 설명하라.</summary>

답변: 장점은 exact likelihood evaluation, prior에서 직접 sampling, inverse mapping을 통한 latent representation 계산이 모두 가능하다는 점이다. 제약은 \(x\)와 \(z\)가 continuous이고 같은 차원이어야 하며, invertible하면서도 Jacobian determinant가 tractable한 transformation만 쓸 수 있다는 점이다.

</details>

<details>
<summary>5. Triangular Jacobian이 flow 설계에서 중요한 이유는 무엇인가?</summary>

답변: 일반 determinant 계산은 \(O(n^3)\)이라 큰 데이터에서 비싸다. Jacobian이 triangular이면 determinant가 diagonal element의 곱이 되므로 훨씬 빠르게 계산된다. 따라서 autoregressive dependency나 coupling 구조는 표현력을 유지하면서 likelihood 계산을 가능하게 하는 핵심 설계가 된다.

</details>

## PDF

- [Official Lecture 7 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture7.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=m6dKKRsZwBQ){:target="_blank" rel="noopener"}
- [Lecture slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture7.pdf){:target="_blank" rel="noopener"}
- [CS236 course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
