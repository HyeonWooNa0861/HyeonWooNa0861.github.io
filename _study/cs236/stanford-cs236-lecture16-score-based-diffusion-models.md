---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 16: Score-Based Diffusion Models"
course: "CS236"
topic: "Score-Based Diffusion Models"
order: 16
major_topic: "Deep Generative Models"
keywords:
  - "Diffusion Models"
  - "Score Matching"
  - "DDPM"
  - "Stochastic Differential Equations"
  - "Probability Flow ODE"
  - "Classifier-Free Guidance"
---

# Stanford CS236 Lecture 16: Score-Based Diffusion Models

## Source

- Video: [Stanford CS236 Deep Generative Models 2023 Lecture 16](https://www.youtube.com/watch?v=VsllsC2JMGY){:target="_blank" rel="noopener"}
- Source Slides: [lecture16-2023-comp.pptx](https://deepgenerativemodels.github.io/assets/slides/lecture16-2023-comp.pptx){:target="_blank" rel="noopener"}

> **핵심:** Lecture 16은 score-based model과 diffusion model을 하나의 관점으로 묶는다. Density \(p(x)\) 자체보다 시간별 score field를 학습하고, noise에서 출발한 reverse process로 sample을 만드는 것이 핵심이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Score-based recap | score function만 학습해도 왜 sample을 만들 수 있는가? |
| 2 | Discrete-time diffusion | Gaussian noise를 조금씩 넣는 forward process를 어떻게 뒤집는가? |
| 3 | Hierarchical VAE view | DDPM은 어떤 의미에서 encoder가 고정된 hierarchical VAE인가? |
| 4 | SDE view | 무한히 많은 noise level을 연속시간 stochastic process로 보면 무엇이 달라지는가? |
| 5 | ODE view | reverse SDE와 같은 marginal을 갖는 deterministic flow는 likelihood와 sampling에 어떤 장점을 주는가? |
| 6 | Practical generation | distillation, latent diffusion, guidance는 diffusion model을 어떻게 실용화하는가? |

## 핵심 내용

Lecture 16은 score-based model과 diffusion model을 하나의 관점으로 묶는다. Score-based model의 기본 아이디어는 density \(p(x)\) 자체를 직접 정규화해 표현하지 않고, score function

$$
s_\theta(x,t)\approx\nabla_x\log p_t(x)
$$

을 학습하는 것이다. Score는 현재 \(x\)에서 probability density가 증가하는 방향을 알려주는 vector field다. Energy-based model 강의에서 보았듯이 score에는 partition function이 사라진다. 따라서 정규화 상수를 계산하지 못해도, score field를 따라 Langevin dynamics를 실행하면 새로운 sample을 만들 수 있다.

초기 score matching은 high-dimensional data에서 계산 비용이 컸다. Denoising score matching은 여기에 noise를 추가한다. 깨끗한 data에 여러 수준의 Gaussian noise를 넣고, model이 noise-perturbed distribution의 score를 맞추도록 훈련한다. Noise Conditional Score Network는 noise level을 조건으로 받아 여러 noise scale의 score를 하나의 network가 예측하게 한다. Sampling에서는 큰 noise에서 시작해 작은 noise로 내려오며 annealed Langevin dynamics를 수행한다. 즉 generation은 "무작위 noise를 조금씩 denoise하는 절차"로 해석된다.

Diffusion model은 이 절차를 더 구조화한다. Forward process는 data \(x_0\)에 Gaussian noise를 단계적으로 추가해 \(x_1,\ldots,x_T\)를 만든다. 설계가 Gaussian이므로 임의의 time step \(t\)에서 \(q(x_t\mid x_0)\)를 닫힌 형태로 sampling할 수 있다. Reverse process는 \(x_T\)에서 출발해 \(x_{t-1}\)을 복원하는 learned decoder다. 이때 true reverse transition은 모르기 때문에 neural network가 variational approximation을 학습한다.

Hierarchical VAE 관점에서는 \(x_1,\ldots,x_T\)가 latent variables이고, forward noising process가 encoder \(q\)다. 중요한 차이는 이 encoder가 학습되지 않는다는 점이다. Encoder는 미리 정한 Gaussian corruption이고, model이 학습하는 것은 decoder, 즉 denoising 방향이다. DDPM의 ELBO를 전개하면 각 단계에서 added noise를 맞추는 denoising objective가 나오며, 이는 denoising score matching과 같은 핵심 구조를 갖는다. 실전 구현에서는 U-Net이 image와 time step을 입력받아 noise 또는 score를 예측한다.

연속시간 관점은 discrete noise level을 무한히 촘촘하게 만든다. Forward process는 stochastic differential equation으로 data distribution을 simple noise distribution으로 보낸다. Reverse-time SDE는 그 과정을 거꾸로 따라가며, 이 reverse dynamics에는 시간별 score \(\nabla_x\log p_t(x)\)가 필요하다. 따라서 학습된 score model 하나가 reverse SDE sampling의 핵심 구성요소가 된다. Predictor-corrector sampling은 numerical SDE solver로 한 걸음 예측하고, score-based MCMC로 local correction을 수행하는 방식이다.

같은 score model은 ODE 관점에서도 사용된다. 특정 probability flow ODE는 reverse SDE와 같은 marginal distribution을 갖지만 trajectory는 deterministic이다. 이 ODE는 continuous-time normalizing flow처럼 볼 수 있어 change-of-variables로 likelihood를 평가할 수 있다. 또한 stochastic sampling보다 큰 step을 취하는 DDIM류 sampler나 exponential integrator, progressive distillation 같은 기법으로 sampling step을 크게 줄일 수 있다.

마지막 실용화 축은 latent diffusion과 controllable generation이다. Latent diffusion은 pixel space 대신 pretrained autoencoder의 latent space에서 diffusion을 수행한다. 차원이 낮아져 sampling이 빨라지고, image뿐 아니라 다른 modality에도 적용하기 쉬워진다. Conditional generation에서는 text caption, class label, stroke, layout 같은 조건을 score model에 넣는다. Classifier guidance는 별도 classifier의 gradient를 generation 방향에 더하고, classifier-free guidance는 conditional model과 unconditional model을 함께 학습한 뒤 두 예측을 조합해 조건을 더 강하게 반영한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | \(\nabla_x\log p_t(x)\). 현재 위치에서 density가 커지는 방향을 나타낸다. |
| Denoising score matching | noise가 섞인 data의 score를 denoising task로 학습하는 scalable score matching 방식이다. |
| DDPM | Gaussian forward noising process와 learned reverse denoising process로 구성된 discrete-time diffusion model이다. |
| Hierarchical VAE view | diffusion chain의 intermediate states를 latent variables로 보고, fixed encoder와 learned decoder를 갖는 VAE로 해석한다. |
| Reverse SDE | forward diffusion을 시간 반대로 실행하는 stochastic process이며, drift에 score function이 들어간다. |
| Probability flow ODE | reverse SDE와 같은 marginal을 갖는 deterministic flow로, likelihood 평가와 빠른 sampling에 연결된다. |
| Classifier-free guidance | conditional/unconditional 예측을 조합해 별도 classifier 없이 조건 반영 강도를 조절하는 방법이다. |

## 학습 포인트

- Diffusion model은 갑자기 등장한 별도 family가 아니라 denoising score matching을 단계적 generative process로 조직한 모델이다.
- DDPM의 forward process는 학습 대상이 아니다. 미리 정한 noising schedule이 encoder 역할을 하고, neural network는 reverse denoising만 학습한다.
- ELBO 관점과 score matching 관점은 같은 training signal을 다른 언어로 설명한다. VAE는 variational bound를 강조하고, score-based view는 denoising vector field를 강조한다.
- SDE formulation은 noise level을 연속화해 이론과 sampler 설계를 통합한다. 같은 score model을 reverse SDE, predictor-corrector, probability flow ODE에서 재사용할 수 있다.
- ODE 관점은 diffusion model을 normalizing flow와 연결한다. Sampling이 deterministic해지고 likelihood 계산이 가능하지만, numerical integration 비용과 approximation tradeoff가 남는다.
- Latent diffusion과 guidance는 diffusion을 실제 application으로 밀어 올린 핵심 장치다. 전자는 비용을 낮추고, 후자는 사용자의 조건을 generation에 반영한다.

## 마지막 핵심 정리

Lecture 16의 중심 메시지는 diffusion model이 score-based generative modeling의 실용적 구현이라는 점이다. Discrete-time DDPM은 fixed Gaussian encoder를 가진 hierarchical VAE로 볼 수 있고, 그 training objective는 denoising score matching과 연결된다. Continuous-time SDE는 score model이 reverse dynamics를 정의하게 만들고, probability flow ODE는 likelihood와 빠른 sampling의 길을 연다. 실전에서는 U-Net denoiser, latent space modeling, distillation, classifier-free guidance가 이 이론을 scalable image generation system으로 만든다.

## Study Guide

1. Score function이 density 자체와 어떻게 다른지 먼저 정리한다. 특히 \(\nabla_x\log p_t(x)\)가 정규화 상수를 제거한다는 점을 확인한다.
2. DDPM forward process와 reverse process를 분리해서 그린다. Forward는 fixed Gaussian corruption이고, reverse만 learned decoder다.
3. DDPM ELBO가 noise prediction 또는 denoising objective로 단순화되는 이유를 VAE 관점에서 추적한다.
4. Discrete-time diffusion, SDE, ODE를 같은 score model의 세 가지 사용 방식으로 비교한다.
5. Sampling speedup을 공부할 때는 DDIM, numerical solver, progressive distillation, latent diffusion이 각각 어느 비용을 줄이는지 구분한다.
6. Conditional generation에서는 classifier guidance와 classifier-free guidance의 차이를 조건 신호의 출처 기준으로 정리한다.

## 복습 질문

<details>
<summary>1. Score-based model이 density를 직접 정규화하지 않아도 sample을 만들 수 있는 이유는 무엇인가?</summary>

답변: score function은 현재 위치에서 density가 증가하는 방향을 알려준다. 이 vector field를 따라 Langevin dynamics나 reverse diffusion sampler를 실행하면 simple noise에서 data manifold 쪽으로 이동할 수 있다. 정규화 상수는 \(x\)에 대한 gradient에서 사라지므로 score 학습에는 직접 필요하지 않다.

</details>

<details>
<summary>2. DDPM을 hierarchical VAE로 볼 때 encoder와 decoder는 각각 무엇인가?</summary>

답변: Encoder는 data에 Gaussian noise를 단계적으로 추가하는 fixed forward process \(q\)다. Decoder는 \(x_t\)에서 \(x_{t-1}\)을 복원하는 learned reverse transition이다. Latent variables는 intermediate noisy states \(x_1,\ldots,x_T\)로 볼 수 있다.

</details>

<details>
<summary>3. DDPM의 ELBO와 denoising score matching은 어떻게 연결되는가?</summary>

답변: Gaussian forward process를 사용하면 ELBO의 단계별 reconstruction 항이 각 time step에서 추가된 noise를 예측하는 denoising loss로 단순화된다. 이 denoising objective는 noise-perturbed distribution의 score를 학습하는 denoising score matching과 같은 정보를 사용한다.

</details>

<details>
<summary>4. Reverse SDE에서 score model이 필요한 이유는 무엇인가?</summary>

답변: Forward SDE는 data를 noise로 보내지만, 이를 시간 반대로 뒤집으려면 각 시점의 분포 \(p_t(x)\)가 어떤 방향으로 증가하는지 알아야 한다. Reverse-time dynamics의 drift에는 \(\nabla_x\log p_t(x)\)가 들어가므로, 시간 조건 score model이 reverse sampling을 정의한다.

</details>

<details>
<summary>5. Probability flow ODE가 diffusion model에 주는 장점은 무엇인가?</summary>

답변: Probability flow ODE는 reverse SDE와 같은 marginal distribution을 갖는 deterministic dynamics다. 그래서 continuous normalizing flow처럼 change-of-variables를 이용한 likelihood 평가가 가능하고, stochastic sampler보다 큰 numerical step을 사용하는 빠른 sampling 전략과 연결된다.

</details>

<details>
<summary>6. Classifier-free guidance가 classifier guidance와 다른 점은 무엇인가?</summary>

답변: Classifier guidance는 별도로 학습한 classifier의 gradient를 사용해 조건 방향을 더한다. Classifier-free guidance는 diffusion model 자체를 conditional과 unconditional mode로 함께 학습하고, sampling 중 두 예측을 조합해 조건 반영 강도를 조절한다.

</details>

## Slides

- [Official Lecture 16 slide deck](https://deepgenerativemodels.github.io/assets/slides/lecture16-2023-comp.pptx){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Course Notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 16 Slides](https://deepgenerativemodels.github.io/assets/slides/lecture16-2023-comp.pptx){:target="_blank" rel="noopener"}
- [CS236 Lecture 16 Video](https://www.youtube.com/watch?v=VsllsC2JMGY){:target="_blank" rel="noopener"}
