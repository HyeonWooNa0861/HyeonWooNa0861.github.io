---
layout: default
title: "Stanford CS236 Lecture 13: Score-Based Models"
course: "CS236"
topic: "Score Functions, Denoising Score Matching, Sliced Score Matching, and Langevin Sampling"
order: 13
major_topic: "Deep Generative Models"
keywords:
  - "Score-Based Models"
  - "Score Matching"
  - "Denoising Score Matching"
  - "Sliced Score Matching"
  - "Langevin Dynamics"
---

# Stanford CS236 Lecture 13: Score-Based Models

## Source

- Video: [Stanford CS236 Lecture 13](https://www.youtube.com/watch?v=8G-OsDs1RLI){:target="_blank" rel="noopener"}
- Source Slides: [lecture 13.pptx](https://deepgenerativemodels.github.io/assets/slides/lecture%2013.pptx){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Distribution representation recap | density, sampling process, score는 각각 어떤 generative model family를 만드는가? |
| 2 | Score function | \(\nabla_x\log p(x)\)는 density 대신 무엇을 표현하며, 왜 normalization 제약에서 자유로운가? |
| 3 | Direct score modeling | EBM처럼 energy를 만들지 않고 vector field 자체를 모델링할 수 있는가? |
| 4 | Denoising score matching | Gaussian noise를 더하면 score estimation이 왜 denoising 문제로 바뀌는가? |
| 5 | Sliced score matching | high-dimensional Jacobian trace 비용을 random projection으로 어떻게 줄이는가? |
| 6 | Langevin sampling | score만 알고 있을 때 \(\epsilon\)-step update와 noise로 sample을 어떻게 만드는가? |
| 7 | Practical failure modes | manifold, low-density region, mode mixing 문제는 왜 다음 diffusion 설계로 이어지는가? |

## 핵심 내용

Lecture 13은 score-based model의 출발점을 정리한다. 지금까지의 generative model은 크게 세 가지 표현으로 나눌 수 있다. Autoregressive model, normalizing flow, VAE, EBM은 \(p_\theta(x)\) 또는 그 근사를 직접 다룬다. GAN은 density 대신 \(z\sim p(z)\), \(x=g_\theta(z)\)라는 sampling process를 다룬다. 이번 강의의 세 번째 표현은 score function이다.

$$
s_p(x)=\nabla_x\log p(x)
$$

여기서 gradient는 parameter가 아니라 input \(x\)에 대한 미분이다. Score는 각 위치에서 log density가 가장 빠르게 증가하는 방향을 주는 vector field다. Density가 scalar surface라면 score는 그 surface의 방향장이다. 중요한 점은 score가 normalization constant에 둔감하다는 것이다. EBM에서 \(p_\theta(x)=\exp(f_\theta(x))/Z(\theta)\)이면 \(\log Z(\theta)\)는 \(x\)에 대해 상수이므로 \(\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)\)가 된다. 따라서 score는 \(Z(\theta)\)를 계산하지 않고도 쓸 수 있다.

Score-based model은 여기서 한 걸음 더 간다. EBM은 scalar energy를 먼저 만들고 그 gradient를 score로 쓴다. 반면 score-based model은 \(s_\theta(x)\)라는 vector-valued neural network를 직접 학습한다. 이 vector field가 어떤 scalar potential의 gradient인지 반드시 보장하지 않아도 된다. 이상적으로는

$$
s_\theta(x)\approx \nabla_x\log p_{\mathrm{data}}(x)
$$

가 되게 만들고, training criterion은 Fisher divergence처럼 score field의 차이를 줄이는 방식으로 잡는다. 그러나 vanilla score matching은 deep high-dimensional model에서 계산 비용이 크다. 원래 score matching loss를 integration by parts로 변형하면 data score를 제거할 수 있지만, model score의 Jacobian trace 또는 second derivative 항이 남는다. Image처럼 차원이 큰 입력에서는 이 항을 직접 계산하고 역전파하는 것이 부담스럽다.

Denoising score matching은 이 병목을 practical하게 푸는 첫 번째 방법이다. Clean data \(x\)에 Gaussian noise를 더해 \(\tilde{x}=x+\sigma\epsilon\)을 만들고, clean data distribution이 아니라 noise-perturbed distribution의 score를 학습한다. Gaussian perturbation에서는 conditional perturbation kernel의 score가

$$
\nabla_{\tilde{x}}\log q_\sigma(\tilde{x}\mid x)=-\frac{\tilde{x}-x}{\sigma^2}
$$

처럼 noisy point를 원래 sample 방향으로 끌어당긴다. 그래서 score estimation은 "어떤 noise가 더해졌는지 예측하고 제거하는" denoising 문제와 연결된다. 이 방식은 Jacobian trace 없이 supervised regression처럼 학습할 수 있어 image model에 적합하다. 단점은 목표가 clean data score가 아니라 noise-perturbed data score라는 점이다. \(\sigma\)가 작으면 원래 분포에 가깝지만 추정 variance가 커지고, \(\sigma\)가 크면 학습은 쉬워지지만 분포가 너무 흐려진다.

Sliced score matching은 두 번째 scalable alternative다. 전체 vector field를 모든 좌표에서 직접 비교하지 않고, random direction \(v\)로 projection한 1D score만 비교한다. 여러 random projection에서 projected score가 맞으면 전체 vector field도 가까워진다는 직관을 사용한다. 이 방식도 integration by parts로 data score를 제거할 수 있고, Jacobian-vector product를 사용해 full trace보다 훨씬 싸게 계산한다. Denoising score matching보다 조금 느릴 수 있지만, noise-perturbed distribution이 아니라 true data score를 직접 겨냥한다는 장점이 있다.

학습한 score를 sample로 바꾸는 기본 절차는 Langevin dynamics다.

$$
x_{t+1}=x_t+\epsilon s_\theta(x_t)+\sqrt{2\epsilon}z_t,\qquad z_t\sim\mathcal{N}(0,I)
$$

첫 항은 score 방향으로 log probability가 높은 곳을 향하게 하고, noise 항은 distribution 전체를 탐색하게 한다. 이론적으로 step size를 작게 하고 충분히 오래 돌리면 target distribution으로 수렴할 수 있다. 하지만 강의는 이 단순한 조합이 실제 image generation에서는 바로 성공하지 않는 이유도 강조한다. Real data는 저차원 manifold 위에 놓일 수 있어 clean density score가 잘 정의되지 않거나 폭주할 수 있다. Training sample은 high-density region에 몰려 있으므로 low-density region의 score는 부정확하다. 또한 분리된 mode 사이를 Langevin chain이 잘 이동하지 못하면 mixture weight가 제대로 반영되지 않는다. 이 세 문제는 다음 강의에서 multi-scale noise와 annealing으로 해결된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | \(\nabla_x\log p(x)\). 입력 위치에서 log density가 증가하는 방향과 크기를 주는 vector field다. |
| Score-based model | Density나 energy 대신 \(s_\theta(x)\) 자체를 vector-valued neural network로 parameterize하는 model family다. |
| Fisher divergence | 두 분포의 score field 차이를 평균 제곱으로 측정하는 divergence다. Score matching의 기본 목적함수다. |
| Denoising score matching | Noisy sample에서 추가된 noise를 예측하는 문제로 score estimation을 바꾸어 scalable training을 가능하게 한다. |
| Tweedie's formula | Optimal denoising direction이 perturbed density의 score와 연결된다는 결과로, denoising과 score matching의 등가성을 설명한다. |
| Sliced score matching | Random projection 방향에서 score를 비교해 high-dimensional Jacobian trace 계산을 줄이는 방법이다. |
| Langevin dynamics | Score gradient를 따라가면서 Gaussian noise를 더해 target distribution에서 sample을 얻는 MCMC 절차다. |
| Manifold hypothesis | Image 같은 real data가 ambient space 전체가 아니라 훨씬 낮은 차원의 구조 위에 놓인다는 가정이다. |

## 학습 포인트

- Score의 gradient는 \(\theta\)가 아니라 \(x\)에 대한 미분이다. Parameter update gradient와 혼동하면 EBM과 score model의 장점이 흐려진다.
- Score field는 normalization constant를 보지 않으므로 \(Z(\theta)\)가 어려운 EBM과 자연스럽게 맞물린다.
- Direct score modeling은 "valid density를 명시적으로 정의하는가"보다 "sampling에 필요한 방향장을 잘 학습하는가"에 초점을 둔다.
- Denoising score matching은 score estimation을 denoising regression으로 바꾸기 때문에 deep image architecture와 잘 맞는다.
- Sliced score matching은 true score를 겨냥하지만 random projection과 derivative 계산이 필요해 denoising 방식보다 느릴 수 있다.
- Langevin dynamics는 score만으로 sampling할 수 있게 하지만, clean data score를 바로 쓰면 manifold와 low-density region에서 실패하기 쉽다.

## 마지막 핵심 정리

Lecture 13의 핵심은 generative model을 density나 sampler가 아니라 score field로 표현할 수 있다는 점이다. Score는 normalization 문제를 피하고, denoising 또는 sliced score matching으로 학습할 수 있으며, Langevin dynamics와 결합하면 sample을 만들 수 있다. 그러나 clean score를 한 번에 학습하고 sampling하는 방식은 manifold, low-density region, slow mixing 문제를 남긴다. 이 한계가 multi-scale noise와 diffusion model로 이어진다.

## Study Guide

1. 먼저 \(p_\theta(x)\), \(g_\theta(z)\), \(s_\theta(x)\)가 각각 어떤 model family의 중심 객체인지 비교한다.
2. EBM에서 \(\nabla_x\log Z(\theta)=0\)이 되는 이유를 직접 써 보고, score가 partition function을 피하는 위치를 확인한다.
3. Vanilla score matching의 문제가 "data score를 모른다"에서 끝나지 않고 "Jacobian trace가 비싸다"로 이어지는 흐름을 정리한다.
4. Denoising score matching과 sliced score matching을 target distribution, 계산 비용, 장점 기준으로 비교한다.
5. Langevin dynamics update에서 gradient term과 noise term의 역할을 분리한다.
6. 다음 강의를 읽기 전에 단일 noise scale이 왜 clean sample generation과 accurate score estimation 사이의 tradeoff를 만드는지 생각해 본다.

## 복습 질문

<details>
<summary>1. Score-based model이 density model과 다른 점은 무엇인가?</summary>

답변: Density model은 각 \(x\)에 probability density 또는 mass를 할당하고 normalization을 맞춰야 한다. Score-based model은 \(x\)에서 \(\nabla_x\log p(x)\)에 해당하는 vector field를 직접 모델링한다. 따라서 likelihood 값을 바로 주지는 않지만, score matching과 Langevin dynamics를 통해 학습과 sampling을 수행할 수 있다.

</details>

<details>
<summary>2. EBM에서 score가 partition function을 제거하는 이유는 무엇인가?</summary>

답변: \(\log p_\theta(x)=f_\theta(x)-\log Z(\theta)\)이고 \(Z(\theta)\)는 입력 \(x\)가 아니라 parameter \(\theta\)에 의존한다. \(x\)에 대해 미분하면 \(\nabla_x\log Z(\theta)=0\)이므로 score는 \(\nabla_x f_\theta(x)\)만 남는다.

</details>

<details>
<summary>3. Denoising score matching이 scalable한 이유는 무엇인가?</summary>

답변: Vanilla score matching은 high-dimensional input에서 Jacobian trace나 second derivative 계산이 비싸다. Denoising score matching은 noisy sample을 clean sample 방향으로 복원하는 regression 문제로 바뀌어, 일반적인 neural network training처럼 loss를 계산하고 역전파할 수 있다.

</details>

<details>
<summary>4. Sliced score matching은 어떤 비용을 줄이는가?</summary>

답변: 전체 좌표의 score field와 Jacobian trace를 직접 계산하는 대신 random direction으로 projection한 1D score를 비교한다. Autodiff에서 Jacobian-vector product를 활용할 수 있어 full trace 계산보다 비용이 낮다.

</details>

<details>
<summary>5. Langevin dynamics에서 noise term이 필요한 이유는 무엇인가?</summary>

답변: Score 방향만 따르면 단순한 optimization처럼 local high-density region으로 이동하는 절차가 된다. Sampling은 분포 전체의 확률 질량을 반영해야 하므로 Gaussian noise를 더해 exploration과 mode 이동 가능성을 유지한다.

</details>

<details>
<summary>6. Clean data score만으로 image generation을 하기 어려운 이유는 무엇인가?</summary>

답변: Real image data는 저차원 manifold에 놓일 수 있어 ambient space 전체에서 score가 안정적으로 정의되지 않는다. 또 training data가 거의 없는 low-density region에서는 score 추정이 부정확하고, 분리된 mode 사이의 Langevin mixing도 느리다. 그래서 다음 단계에서는 여러 noise level을 사용해 score를 더 안정적으로 학습한다.

</details>

## Slides

- [Official Lecture 13 slide deck](https://deepgenerativemodels.github.io/assets/slides/lecture%2013.pptx){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 13 Slides](https://deepgenerativemodels.github.io/assets/slides/lecture%2013.pptx){:target="_blank" rel="noopener"}
- [CS236 Lecture 13 Video](https://www.youtube.com/watch?v=8G-OsDs1RLI){:target="_blank" rel="noopener"}
- [A Connection Between Score Matching and Denoising Autoencoders](https://www.iro.umontreal.ca/~vincentp/Publications/smdae_techreport.pdf){:target="_blank" rel="noopener"}
