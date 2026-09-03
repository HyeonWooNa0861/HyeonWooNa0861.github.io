---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:55:00 +0900
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

> **Preview note:** 이 원본은 외부 PPTX이고 공식 PowerPoint for the web iframe이 제공되지 않아 블로그의 문서 모달에서 직접 미리보기하지 않는다. `Source Slides`를 새 탭에서 열어야 하며, 아래 번호는 PPTX package의 1-based slide 순서를 따른다. 정적 viewer에서는 animation 단계나 equation image가 누락될 수 있다.

> **Source verification scope:** 공식 PPTX 48장을 Office Viewer의 정확한 slide ID로 모두 render해 완성된 layout을 시각 검사했고, formula object와 embedded equation media도 함께 대조했다. Slide 41의 staged animation은 OOXML animation state와 완성 상태를 보여 주는 slide 45를 교차 확인했다.

> **핵심:** Lecture 16은 score-based model과 diffusion model을 하나의 관점으로 묶는다. Density $$p(x)$$ 자체보다 시간별 score field를 학습하고, noise에서 출발한 reverse process로 sample을 만드는 것이 핵심이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Score-based recap | score function만 학습해도 왜 sample을 만들 수 있는가? |
| 2 | Discrete-time diffusion | Gaussian noise를 조금씩 넣는 forward process를 어떻게 뒤집는가? |
| 3 | Hierarchical VAE view | DDPM은 어떤 의미에서 encoder가 고정된 hierarchical VAE인가? |
| 4 | SDE view | 무한히 많은 noise level을 연속시간 stochastic process로 보면 무엇이 달라지는가? |
| 5 | ODE view | reverse SDE와 같은 marginal을 갖는 deterministic flow는 likelihood와 sampling에 어떤 장점을 주는가? |
| 6 | Practical generation | distillation, latent diffusion, guidance는 diffusion model을 어떻게 실용화하는가? |

### 원본 수식 위치

| 원본 PPTX | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| slides 3--7 | Score matching, denoising objective, NCSN recap | 세 score-matching 절에서 원문 식과 작성자 보충 유도를 구분한다. |
| slides 10--20 | Forward Gaussian chain, DDPM reverse model, hierarchical-VAE ELBO | DDPM 절에서 exact Gaussian identities, ELBO, practical noise-prediction objective를 구분한다. |
| slides 23--31 | Forward/reverse SDE, probability-flow ODE, likelihood | SDE/ODE 절에서 exact-score 결과와 learned-score·numerical-solver 근사를 구분한다. |
| slides 34--37 | Parallel ODE, distillation, latent diffusion | 실용화 절에서 algorithmic approximation과 latent-space modeling의 범위를 설명한다. |
| slides 40--46 | Conditional score, classifier guidance, classifier-free guidance | guidance 절에서 Bayes identity, slide 41 animation 상태, CFG extrapolation을 구분한다. |

## 핵심 내용

Lecture 16은 score-based model과 diffusion model을 하나의 관점으로 묶는다. Score-based model의 기본 아이디어는 density $$p(x)$$ 자체를 직접 정규화해 표현하지 않고, score function

$$
s_\theta(x,t)\approx\nabla_x\log p_t(x)
$$

을 학습하는 것이다. Score는 현재 $$x$$에서 probability density가 증가하는 방향을 알려주는 vector field다. Energy-based model 강의에서 보았듯이 score에는 partition function이 사라진다. 따라서 정규화 상수를 계산하지 못해도, score field를 따라 Langevin dynamics를 실행하면 새로운 sample을 만들 수 있다.

초기 score matching은 high-dimensional data에서 계산 비용이 컸다. Denoising score matching은 여기에 noise를 추가한다. 깨끗한 data에 여러 수준의 Gaussian noise를 넣고, model이 noise-perturbed distribution의 score를 맞추도록 훈련한다. Noise Conditional Score Network는 noise level을 조건으로 받아 여러 noise scale의 score를 하나의 network가 예측하게 한다. Sampling에서는 큰 noise에서 시작해 작은 noise로 내려오며 annealed Langevin dynamics를 수행한다. 즉 generation은 "무작위 noise를 조금씩 denoise하는 절차"로 해석된다.

Diffusion model은 이 절차를 더 구조화한다. Forward process는 data $$x_0$$에 Gaussian noise를 단계적으로 추가해 $$x_1,\ldots,x_T$$를 만든다. 설계가 Gaussian이므로 임의의 time step $$t$$에서 $$q(x_t\mid x_0)$$를 닫힌 형태로 sampling할 수 있다. Reverse process는 $$x_T$$에서 출발해 $$x_{t-1}$$을 복원하는 learned decoder다. 이때 true reverse transition은 모르기 때문에 neural network가 variational approximation을 학습한다.

Hierarchical VAE 관점에서는 $$x_1,\ldots,x_T$$가 latent variables이고, forward noising process가 encoder $$q$$다. 중요한 차이는 이 encoder가 학습되지 않는다는 점이다. Encoder는 미리 정한 Gaussian corruption이고, model이 학습하는 것은 decoder, 즉 denoising 방향이다. DDPM의 ELBO를 전개하면 각 단계에서 added noise를 맞추는 denoising objective가 나오며, 이는 denoising score matching과 같은 핵심 구조를 갖는다. 실전 구현에서는 U-Net이 image와 time step을 입력받아 noise 또는 score를 예측한다.

연속시간 관점은 discrete noise level을 무한히 촘촘하게 만든다. Forward process는 stochastic differential equation으로 data distribution을 simple noise distribution으로 보낸다. Reverse-time SDE는 그 과정을 거꾸로 따라가며, 이 reverse dynamics에는 시간별 score $$\nabla_x\log p_t(x)$$가 필요하다. 따라서 학습된 score model 하나가 reverse SDE sampling의 핵심 구성요소가 된다. Predictor-corrector sampling은 numerical SDE solver로 한 걸음 예측하고, score-based MCMC로 local correction을 수행하는 방식이다.

같은 score model은 ODE 관점에서도 사용된다. 특정 probability flow ODE는 reverse SDE와 같은 marginal distribution을 갖지만 trajectory는 deterministic이다. 이 ODE는 continuous-time normalizing flow처럼 볼 수 있어 change-of-variables로 likelihood를 평가할 수 있다. 또한 stochastic sampling보다 큰 step을 취하는 DDIM류 sampler나 exponential integrator, progressive distillation 같은 기법으로 sampling step을 크게 줄일 수 있다.

마지막 실용화 축은 latent diffusion과 controllable generation이다. Latent diffusion은 pixel space 대신 pretrained autoencoder의 latent space에서 diffusion을 수행한다. 차원이 낮아져 sampling이 빨라지고, image뿐 아니라 다른 modality에도 적용하기 쉬워진다. Conditional generation에서는 text caption, class label, stroke, layout 같은 조건을 score model에 넣는다. Classifier guidance는 별도 classifier의 gradient를 generation 방향에 더하고, classifier-free guidance는 conditional model과 unconditional model을 함께 학습한 뒤 두 예측을 조합해 조건을 더 강하게 반영한다.

### Score matching: Fisher divergence에서 implicit objective까지 (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slide 3의 explicit/implicit score-matching 식과 formula object를 대조했다. 아래 유도 기준은 [Hyvärinen (2005)](https://www.jmlr.org/papers/volume6/hyvarinen05a/hyvarinen05a.pdf){:target="_blank" rel="noopener"}의 표준 score matching objective다.

Data density를 $$p(x)$$, model score를 $$s_\theta(x)$$, data score를 $$s_p(x)=\nabla_x\log p(x)$$라 하자. 두 score의 Fisher divergence는

$$
J_{\mathrm F}(\theta)
=\frac12\int p(x)
\left\lVert s_\theta(x)-s_p(x)\right\rVert_2^2dx
$$

로 정의한다. 이는 **정의**이며 $$p(x)$$의 score를 직접 알아야 하므로 그대로는 계산하기 어렵다. 제곱을 전개하면

$$
J_{\mathrm F}(\theta)
=\frac12\mathbb E_p\left[\lVert s_\theta(x)\rVert_2^2\right]
-\mathbb E_p\left[s_\theta(x)^{\top}\nabla_x\log p(x)\right]
+C_p,
$$

여기서 $$C_p=\frac12\mathbb E_p[\lVert\nabla_x\log p(x)\rVert_2^2]$$는 $$\theta$$와 무관하다. 교차항은 $$p\nabla\log p=\nabla p$$를 이용해 좌표별로

$$
-\int s_{\theta,i}(x)\,\partial_i p(x)dx
=-\left[p(x)s_{\theta,i}(x)\right]_{\partial\Omega}
+\int p(x)\,\partial_i s_{\theta,i}(x)dx
$$

가 된다. 경계항이 0이면 모든 좌표를 합해

$$
J_{\mathrm F}(\theta)
=\mathbb E_p\left[
\frac12\lVert s_\theta(x)\rVert_2^2
+\nabla_x\!\cdot s_\theta(x)
\right]+C_p
$$

라는 **정확한 등식**을 얻는다. 따라서 $$C_p$$를 버린 implicit objective

$$
J_{\mathrm{ISM}}(\theta)
=\mathbb E_p\left[
\frac12\lVert s_\theta(x)\rVert_2^2
+\nabla_x\!\cdot s_\theta(x)
\right]
$$

는 Fisher divergence와 같은 minimizer를 갖는다.

성립 조건은 $$p$$와 $$s_\theta$$의 필요한 편미분이 존재하고 적분 가능하며, support $$\Omega$$의 경계 또는 무한대에서 $$p(x)s_{\theta,i}(x)\to0$$인 것이다. 이 경계 조건이 깨지면 버린 surface term이 남으므로 위 목적은 더 이상 Fisher divergence와 상수 차이만 나지 않는다.

**Slide 표기 주의:** slide 3의 implicit 식에는 표준 Hyvärinen 식 바깥에 추가 $$\frac12$$가 표시되어 있다. 이는 원래 Fisher divergence와의 위 등식을 그대로 나타낸 표준식과 맞지 않아 **source typo 가능성이 높다**. 전체 objective에 곱해진 양의 상수라면 minimizer는 바뀌지 않지만, 등식의 normalization은 달라지므로 이 글에서는 Hyvärinen의 표준 convention을 따른다.

### Denoising score matching: marginal과 conditional target의 동치 (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slide 4의 denoising score-matching 식과 formula object를 대조했다.

Gaussian corruption을 $$q_\sigma(\tilde x\mid x)=\mathcal N(x,\sigma^2I)$$라 하고 perturbed marginal을

$$
q_\sigma(\tilde x)
=\int p_{\mathrm{data}}(x)q_\sigma(\tilde x\mid x)dx
$$

로 정의한다. 학습하려는 것은 깨끗한 $$p_{\mathrm{data}}$$의 score가 아니라 **noise가 섞인 marginal $$q_\sigma$$의 score**다. 미분과 적분을 교환할 수 있으면

$$
\begin{aligned}
\nabla_{\tilde x}\log q_\sigma(\tilde x)
&=\frac{1}{q_\sigma(\tilde x)}
\int p_{\mathrm{data}}(x)\nabla_{\tilde x}q_\sigma(\tilde x\mid x)dx \\
&=\mathbb E\left[
\nabla_{\tilde x}\log q_\sigma(\tilde x\mid X)
\mid \tilde X=\tilde x
\right].
\end{aligned}
$$

즉 conditional score의 posterior 평균이 marginal score다. $$A=\nabla_{\tilde x}\log q_\sigma(\tilde x\mid X)$$와 $$m(\tilde X)=\mathbb E[A\mid\tilde X]$$라 두면 conditional variance decomposition으로

$$
\mathbb E\left[\lVert s_\theta(\tilde X)-A\rVert_2^2\right]
=\mathbb E\left[\lVert s_\theta(\tilde X)-m(\tilde X)\rVert_2^2\right]
+\mathbb E\left[\lVert A-m(\tilde X)\rVert_2^2\right].
$$

마지막 항은 $$\theta$$와 무관하므로

$$
\frac12\mathbb E_{\tilde X\sim q_\sigma}
\left[\lVert s_\theta(\tilde X)-\nabla_{\tilde x}\log q_\sigma(\tilde X)\rVert_2^2\right]
$$

와

$$
\frac12\mathbb E_{X\sim p_{\mathrm{data}},\,\tilde X\sim q_\sigma(\cdot\mid X)}
\left[\lVert s_\theta(\tilde X)-\nabla_{\tilde x}\log q_\sigma(\tilde X\mid X)\rVert_2^2\right]
$$

는 상수 차이만 나는 **동일 minimizer의 정확한 목적함수**다. Gaussian에서는

$$
\nabla_{\tilde x}\log q_\sigma(\tilde x\mid x)
=-\frac{\tilde x-x}{\sigma^2}
=-\frac{z}{\sigma},
\qquad \tilde x=x+\sigma z,\quad z\sim\mathcal N(0,I).
$$

**Slide 표기 주의:** slide 4의 marginal expectation label이 $$p_{\mathrm{data}}$$로 읽히는 부분은 perturbed sample에 대한 기대값이라면 $$q_\sigma$$가 정확하다. 깨끗한 data expectation과 corrupted conditional expectation을 함께 쓴 두 번째 식과 혼동하지 않아야 한다.

### NCSN multiscale objective와 noise 표기의 경계 (작성자 보충)

> **Source mapping:** 48-slide visual audit에서 official Lecture 16의 NCSN/annealed Langevin recap 구간과 수식 object를 대조했다. 표기는 [NCSN](https://arxiv.org/pdf/1907.05600){:target="_blank" rel="noopener"}의 multiscale denoising objective를 따른다.

Noise scale $$\sigma_1>\cdots>\sigma_L>0$$마다 corrupted sample $$\tilde x=x+\sigma_i z$$를 만들면 NCSN loss의 한 convention은

$$
\mathcal L_{\mathrm{NCSN}}(\theta)
=\frac{1}{2L}\sum_{i=1}^{L}\lambda(\sigma_i)
\mathbb E_{x,z}\left[
\left\lVert
s_\theta(x+\sigma_i z,\sigma_i)+\frac{z}{\sigma_i}
\right\rVert_2^2
\right].
$$

Target score의 전형적 크기가 $$1/\sigma_i$$에 비례하므로 $$\lambda(\sigma_i)=\sigma_i^2$$를 쓰면 작은 noise level만 과도하게 지배하는 현상을 완화한다. 이는 scale 간 균형을 위한 **설계 선택**이지 유일하게 증명되는 weight는 아니다.

$$
\epsilon_\theta^{\mathrm{NCSN}}(\tilde x,\sigma)
:=\sigma s_\theta(\tilde x,\sigma)
\approx-z.
$$

따라서 이 정의의 NCSN $$\epsilon_\theta^{\mathrm{NCSN}}$$는 **$$-z$$를 예측**한다. 반면 DDPM의 일반적인 $$\epsilon_\theta^{\mathrm{DDPM}}$$는 forward reparameterization에 더해진 **$$+\epsilon$$를 예측**하며

$$
s_\theta(x_t,t)
\approx-\frac{\epsilon_\theta^{\mathrm{DDPM}}(x_t,t)}{\sqrt{1-\bar\alpha_t}}
$$

로 연결된다. 이름이 같은 $$\epsilon_\theta$$라도 sign과 scale convention을 확인하지 않고 두 식을 그대로 바꾸어 쓰면 안 된다.

| 기호 | 의미 | 단위 |
|---|---|---|
| $$x,\tilde x,\sigma$$ | clean sample, perturbed sample, noise standard deviation | $$U$$ |
| $$z$$ | standard Gaussian noise | 무차원 |
| $$s_\theta$$ | score with respect to $$x$$ | $$U^{-1}$$ |
| raw squared score error | $$\lVert s_\theta+z/\sigma\rVert_2^2$$ | $$U^{-2}$$ |
| $$\lambda(\sigma)=\sigma^2$$ | scale-balancing weight | $$U^2$$ |
| weighted loss term | weight times squared score error | 무차원 |

### DDPM joint, hierarchical-VAE ELBO, Gaussian KL (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slides 11, 14, 18--20의 forward marginal, reverse Gaussian, hierarchical-VAE ELBO, noise prediction과 ancestral update를 formula/media object와 대조했다. 유도는 [DDPM](https://arxiv.org/pdf/2006.11239){:target="_blank" rel="noopener"}의 notation을 따른다.

Forward Markov chain과 learned reverse joint는 각각

$$
q(x_{1:T}\mid x_0)
=\prod_{t=1}^{T}q(x_t\mid x_{t-1}),
$$

$$
p_\theta(x_{0:T})
=p(x_T)\prod_{t=1}^{T}p_\theta(x_{t-1}\mid x_t)
$$

로 **정확히 factorize**된다.

Slide 14가 명시하는 learned reverse transition은

$$
p_\theta(x_{t-1}\mid x_t)
=\mathcal N\left(
x_{t-1};\mu_\theta(x_t,t),\sigma_t^2I
\right)
$$

인 Gaussian distribution이다. 즉 network는 reverse mean을 예측하고, $$\sigma_t^2$$는 고정 schedule 또는 별도 variance parameterization으로 정한다. 이 Gaussian 가정이 아래 KL-to-MSE reduction의 핵심 조건이다.

Jensen inequality로 negative log-likelihood의 upper bound를 만들면

$$
-\log p_\theta(x_0)
\le
\mathbb E_{q(x_{1:T}\mid x_0)}
\left[-\log\frac{p_\theta(x_{0:T})}{q(x_{1:T}\mid x_0)}\right].
$$

Bayes rule로 forward posterior를 정리하면 이 hierarchical-VAE ELBO는

$$
\begin{aligned}
\mathcal L_{\mathrm{VLB}}
={}&D_{\mathrm{KL}}\left(q(x_T\mid x_0)\mathbin\Vert p(x_T)\right) \\
&+\sum_{t=2}^{T}
\mathbb E_q\left[
D_{\mathrm{KL}}\left(
q(x_{t-1}\mid x_t,x_0)
\mathbin\Vert
p_\theta(x_{t-1}\mid x_t)
\right)
\right] \\
&-\mathbb E_q\left[\log p_\theta(x_0\mid x_1)\right]
\end{aligned}
$$

로 분해된다. 첫 항은 terminal prior matching, 합은 step별 denoising, 마지막 항은 reconstruction 항이다.

Forward transition을 $$q(x_t\mid x_{t-1})=\mathcal N(\sqrt{\alpha_t}x_{t-1},\beta_tI)$$, $$\alpha_t=1-\beta_t$$, $$\bar\alpha_t=\prod_{s=1}^{t}\alpha_s$$로 두면 Gaussian 합성으로 slide 11의 closed-form marginal

$$
q(x_t\mid x_0)
=\mathcal N\left(
x_t;\sqrt{\bar\alpha_t}x_0,
(1-\bar\alpha_t)I
\right)
$$

을 얻는다. 이 distribution을 standard Gaussian으로 reparameterize하면

$$
x_t=\sqrt{\bar\alpha_t}x_0+\sqrt{1-\bar\alpha_t}\,\epsilon,
\qquad \epsilon\sim\mathcal N(0,I)
$$

이라는 **정확한 reparameterization**을 얻는다. True posterior mean과 model mean을 같은 noise parameterization으로 쓰면

$$
\tilde\mu_t(x_t,x_0)
=\frac{1}{\sqrt{\alpha_t}}
\left(x_t-\frac{\beta_t}{\sqrt{1-\bar\alpha_t}}\epsilon\right),
$$

$$
\mu_\theta(x_t,t)
=\frac{1}{\sqrt{\alpha_t}}
\left(x_t-\frac{\beta_t}{\sqrt{1-\bar\alpha_t}}
\epsilon_\theta(x_t,t)\right).
$$

Slide 20의 ancestral sampling update는 이 mean에 Gaussian noise를 더한

$$
x_{t-1}
=\frac{1}{\sqrt{\alpha_t}}
\left(
x_t-\frac{\beta_t}{\sqrt{1-\bar\alpha_t}}
\epsilon_\theta(x_t,t)
\right)
+\sigma_t z,
\qquad z\sim\mathcal N(0,I)
$$

이다. 앞 괄호가 바로 $$\mu_\theta(x_t,t)$$이므로 $$\sigma_t z$$를 더하는 것은

$$
x_{t-1}\sim
\mathcal N\left(\mu_\theta(x_t,t),\sigma_t^2I\right)
$$

에서 실제로 한 sample을 뽑는 것과 같다. 마지막 denoising step에서는 구현 convention에 따라 $$z=0$$으로 두어 추가 random noise를 생략한다. 이 update는 learned mean이 정확하다는 항등식이 아니라, 지정한 reverse Gaussian에서 표본화하는 **ancestral sampling rule**이다.

Reverse variance를 $$\sigma_t^2I$$로 고정하면 같은 covariance를 가진 Gaussian 사이 KL은

$$
\begin{aligned}
D_{\mathrm{KL}}
&=\frac{1}{2\sigma_t^2}
\left\lVert\tilde\mu_t-\mu_\theta\right\rVert_2^2+C_t \\
&=\frac{\beta_t^2}
{2\sigma_t^2\alpha_t(1-\bar\alpha_t)}
\left\lVert\epsilon-\epsilon_\theta(x_t,t)\right\rVert_2^2+C_t.
\end{aligned}
$$

여기서 $$C_t$$는 학습되는 mean과 무관한 항이다. 따라서 exact VLB에는 time-dependent weight가 남는다. DDPM의 widely used simple objective

$$
\mathcal L_{\mathrm{simple}}
=\mathbb E_{t,x_0,\epsilon}
\left[
\left\lVert\epsilon-\epsilon_\theta(x_t,t)\right\rVert_2^2
\right]
$$

는 이 weight를 제거해 모든 time step의 noise-prediction error를 비슷하게 취급하는 **대리 목적함수**다. 그러므로 $$\mathcal L_{\mathrm{simple}}$$는 일반적으로 exact ELBO와 동일한 수치가 아니며, weight 제거는 sample quality와 optimization을 위한 empirical design choice다.

$$t,T,\alpha_t,\beta_t,\bar\alpha_t$$는 무차원이고, 표준화된 image와 $$\epsilon$$도 무차원이다. 원자료의 physical scale을 유지한다면 $$x_t$$와 $$\epsilon_\theta$$의 scale convention을 맞춰야 한다. Non-Gaussian corruption, learned forward process, 서로 다른 reverse covariance를 쓰면 위 KL-to-MSE 단순화가 그대로 성립하지 않는다.

### Continuous DSM과 backward Euler--Maruyama 부호 (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slides 24--25의 continuous-time SDE와 reverse process를 formula object와 대조했다. 이론적 기준은 [Score-SDE](https://arxiv.org/pdf/2011.13456){:target="_blank" rel="noopener"}다.

강의의 drift-free toy case를 일반적인 scalar diffusion coefficient로 쓰면

$$
dX_t=g(t)dW_t,
\qquad
X_t\mid X_0=x_0
\sim\mathcal N\left(x_0,v(t)I\right),
\qquad
v(t)=\int_0^t g(\tau)^2d\tau.
$$

따라서 conditional score는

$$
\nabla_{x_t}\log p_{0t}(x_t\mid x_0)
=-\frac{x_t-x_0}{v(t)}
$$

이고, discrete noise-level 합을 연속화한 DSM objective는

$$
\mathcal L_{\mathrm{SDE}}(\theta)
=\frac12\mathbb E_{t\sim\rho}
\left[
\lambda(t)
\mathbb E_{x_0,x_t\mid x_0}
\left[
\left\lVert
s_\theta(x_t,t)
-\nabla_{x_t}\log p_{0t}(x_t\mid x_0)
\right\rVert_2^2
\right]
\right]
$$

가 된다. 이는 선택한 time sampling density $$\rho(t)$$와 weight $$\lambda(t)$$에 의존하는 **학습 목적함수 정의**다.

일반 forward SDE

$$
dX_t=f(X_t,t)dt+g(t)dW_t
$$

의 reverse-time SDE를 $$t:T\to0$$으로 적분하면

$$
dX_t=
\left[f(X_t,t)-g(t)^2\nabla_x\log p_t(X_t)\right]dt
+g(t)d\bar W_t.
$$

Backward step의 양의 크기를 $$\Delta t=t_k-t_{k-1}>0$$로 정의하면 $$dt=-\Delta t$$이므로 Euler--Maruyama update는

$$
X_{k-1}=X_k
-\left[f(X_k,t_k)-g(t_k)^2s_\theta(X_k,t_k)\right]\Delta t
+g(t_k)\sqrt{\Delta t}\,z_k,
\qquad z_k\sim\mathcal N(0,I).
$$

반대로 signed step $$h=t_{k-1}-t_k<0$$를 쓰면 drift 항은 $$+[f-g^2s]h$$, noise 크기는 $$g\sqrt{-h}$$다. 두 표기는 같은 update이며, **$$\Delta t$$를 양수로 정의했는지 signed increment로 정의했는지** 밝히지 않으면 score 항의 부호가 반대로 보인다. Exact score를 learned score로 바꾸고 finite step을 쓰면 model error와 discretization error가 함께 생긴다.

$$x$$의 단위가 $$U$$이고 time 단위가 $$T_0$$이면 $$f$$는 $$U/T_0$$, $$g$$는 $$U/\sqrt{T_0}$$, score는 $$U^{-1}$$, $$v(t)$$는 $$U^2$$다.

### Probability-flow ODE: same marginal과 invertibility (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slides 29--31의 probability-flow ODE와 likelihood를 formula/media object와 대조했다. Same-marginal 구성은 [Score-SDE](https://arxiv.org/pdf/2011.13456){:target="_blank" rel="noopener"}, ODE flow와 instantaneous change of variables는 [Neural ODE](https://arxiv.org/pdf/1806.07366){:target="_blank" rel="noopener"}를 따른다.

Forward SDE의 Fokker--Planck equation은 scalar $$g(t)$$일 때

$$
\begin{aligned}
\partial_t p_t(x)
&=-\nabla_x\!\cdot\left(f(x,t)p_t(x)\right)
+\frac12g(t)^2\Delta_xp_t(x) \\
&=-\nabla_x\!\cdot\left[
\left(f(x,t)-\frac12g(t)^2\nabla_x\log p_t(x)\right)p_t(x)
\right].
\end{aligned}
$$

두 번째 줄은 $$p_t\nabla\log p_t=\nabla p_t$$를 쓴 **정확한 등식**이다. 따라서 velocity를

$$
v(x,t)=f(x,t)-\frac12g(t)^2\nabla_x\log p_t(x)
$$

로 둔 ODE $$dX_t/dt=v(X_t,t)$$의 continuity equation이 같은 $$p_t$$를 만족한다. 즉 **exact score, 같은 initial density, 필요한 smoothness와 적분 가능성** 아래에서 SDE와 ODE는 각 time의 marginal density가 같다. Sample path와 transition law까지 같은 것은 아니다. Learned $$s_\theta$$를 넣으면 ODE 자체의 density는 잘 정의될 수 있어도 target SDE marginal과의 일치는 근사다.

Invertibility는 단지 deterministic이라는 말만으로 보장되지 않는다. 각 compact set에서 $$v(x,t)$$가 $$x$$에 대해 locally Lipschitz이고 $$t$$에 대해 연속이며, 관심 interval에서 solution이 finite하고 blow-up하지 않아 global existence가 성립한다고 하자. 그러면 initial value problem의 solution이 유일하므로 flow map $$\Phi_{s,t}(x_s)=x_t$$가 존재한다. 같은 trajectory를 terminal state에서 backward ODE로 유일하게 풀면

$$
\Phi_{t,s}\left(\Phi_{s,t}(x)\right)=x,
\qquad
\Phi_{s,t}\left(\Phi_{t,s}(y)\right)=y
$$

가 되어 $$\Phi_{s,t}^{-1}=\Phi_{t,s}$$다. Velocity가 non-Lipschitz라 trajectory가 갈라지거나, finite-time blow-up으로 solution이 interval 끝까지 존재하지 않으면 이 proof가 깨진다.

ODE-flow density를 $$p_t^\theta$$라 하면 instantaneous change of variables는

$$
\frac{d}{dt}\log p_t^\theta(X_t)
=-\nabla_x\!\cdot v_\theta(X_t,t)
$$

이고 따라서

$$
\log p_\theta(x_0)
=\log p_T(x_T)
+\int_0^T\nabla_x\!\cdot v_\theta(X_t,t)dt.
$$

이 등식은 exact numerical integration과 regular ODE flow를 가정한 **현재 learned flow density에 대한 항등식**이다. Score error는 change-of-variables 자체가 아니라 learned density와 data density의 mismatch를 만든다.

### Hutchinson trace estimator와 bits/dim (작성자 보충)

Divergence $$\nabla_x\!\cdot v=\operatorname{tr}(J_v)$$를 full Jacobian 없이 구하기 위해 mean zero와 identity covariance를 만족하는 random vector $$\xi$$를 쓴다.

$$
\mathbb E[\xi]=0,
\qquad
\mathbb E[\xi\xi^{\top}]=I.
$$

Jacobian $$J_v$$의 trace가 유한하고 기대값 교환이 가능하면

$$
\begin{aligned}
\mathbb E_\xi\left[\xi^{\top}J_v\xi\right]
&=\mathbb E_\xi\left[\operatorname{tr}(\xi^{\top}J_v\xi)\right] \\
&=\operatorname{tr}\left(J_v\mathbb E_\xi[\xi\xi^{\top}]\right) \\
&=\operatorname{tr}(J_v).
\end{aligned}
$$

따라서 Gaussian 또는 Rademacher $$\xi$$를 사용한 $$\xi^{\top}J_v\xi$$는 **unbiased stochastic estimator**다. 표본 하나의 값은 exact trace가 아니며 variance가 클 수 있다. 또한 automatic differentiation이 반환하는 Jacobian-vector product와 ODE solver tolerance의 numerical error가 추가된다.

Image likelihood의 bits per dimension은 discrete observation $$x\in\{0,\ldots,255\}^{D}$$에 대해

$$
\operatorname{bpd}(x)
=-\frac{1}{D}\log_2 P(x)
=-\frac{1}{D\log 2}\log P(x)
$$

로 정의한다. 이는 dimension 하나를 encode하는 평균 bit 수이므로 **낮을수록 더 높은 likelihood**다. Continuous density $$p(y)$$를 평가할 때는 discrete pixel에 uniform dequantization 등을 적용해 probability mass와 density를 연결해야 한다. $$[0,255]$$와 $$[0,1]$$ 사이 rescaling은 Jacobian constant를 바꾸므로, dequantization·색상 channel·scale convention이 다른 bpd는 직접 비교할 수 없다. Continuous density 값을 보정 없이 discrete $$P(x)$$로 해석하면 bpd 결론이 틀어진다.

### Sampling speed claim의 성격

> **Source mapping:** 48-slide visual audit 중 slide 34의 ParaDDPM iteration/error display와 slide 37의 latent VAE diagram·KL relation을 확인했다.

ParaDDPM은 전체 reverse trajectory $$\mathbf X=(x_0,\ldots,x_T)$$를 순차적으로 한 번에 확정하는 대신, 현재 trajectory에서 reverse update operator $$\mathcal F$$를 병렬 평가하는 fixed-point iteration으로 정리할 수 있다.

$$
\mathbf X^{(k+1)}=\mathcal F\left(\mathbf X^{(k)}\right),
\qquad
\mathbf X^{\star}=\mathcal F\left(\mathbf X^{\star}\right).
$$

Slide 34가 직접 표시하는 per-point convergence error는

$$
\left\lVert x_i^{(k+1)}-x_i^{(k)}\right\rVert_2^2
$$

이다. 현재 parallel window의 각 $$x_i$$가 이전 iteration보다 얼마나 변했는지를 재고, 구현이 정한 threshold 조건을 만족한 point 또는 window를 다음 구간으로 진행시키는 신호로 사용한다. $$x_i$$의 단위가 $$U$$라면 이 제곱 오차와 threshold의 단위는 $$U^2$$이고, image state를 미리 무차원으로 정규화했을 때만 둘을 무차원으로 해석할 수 있다.

이 값이 작다는 것은 fixed-point equation의 successive iterates가 더 이상 크게 달라지지 않는다는 **algorithmic stopping diagnostic**이다. 그러나 작은 successive difference만으로 임의의 denoiser가 contraction이라는 사실, global convergence 또는 sample quality가 보장되지는 않는다. 구현에서 relative residual이나 window 평균으로 다시 정규화할 수 있지만, 그것은 slide의 위 식과 구분해야 하며 normalization을 바꾸면 threshold의 의미와 수치도 함께 바뀐다.

Slide 37의 latent VAE는 encoder $$q_\phi(z\mid x)$$와 prior $$p(z)$$ 사이 KL regularization을 포함한다.

$$
\mathcal L_{\mathrm{VAE}}
=\mathbb E_{q_\phi(z\mid x)}
\left[-\log p_\psi(x\mid z)\right]
+D_{\mathrm{KL}}\left(
q_\phi(z\mid x)\mathbin\Vert p(z)
\right).
$$

첫 항은 reconstruction, 두 번째 항은 latent distribution을 prior에 맞추는 항이다. Latent diffusion은 이 VAE가 만든 $$z$$ space에서 diffusion을 수행한다. 이 KL은 앞의 **DDPM hierarchical-VAE ELBO**에 등장하는 step별 reverse-process KL과 역할·대상이 같지 않으므로, 둘은 “variational bound에 KL이 들어간다”는 구조만 교차 참조해야 한다.

Lecture 16이 소개하는 DDIM의 **10--50배 sampling speedup**은 선택한 model, dataset, quality target, baseline step 수와 hardware에 의존하는 **empirical claim**이다. Algebraic identity로 모든 설정에서 보장되는 배수가 아니다. DDIM은 같은 training objective를 재사용하면서 non-Markovian deterministic 또는 low-noise sampling path를 선택해 step 수를 줄이는 algorithmic construction이다.

Progressive distillation의 **두 step을 한 step으로 합치는 2-to-1 절차**도 teacher의 두 update를 student의 한 update가 모사하도록 학습하는 algorithmic rule이다. 한 round가 nominal step count를 절반으로 줄인다는 것은 절차상 맞지만, quality 보존이나 wall-clock 정확히 2배 향상은 증명된 항등식이 아니다. Distillation error는 round마다 누적될 수 있고 실제 속도는 network evaluation, solver overhead와 batch size에 좌우된다.

### Classifier-free guidance의 Bayes 전개와 convention (작성자 보충)

> **Source mapping:** 48-slide visual audit 중 official Lecture 16 slides 40, 45--46의 conditional denoising과 CFG 식을 completed layout, embedded equation media와 formula object로 대조했다. Slide 41의 staged animation은 OOXML과 completed slide 45를 함께 확인했다. CFG convention의 원 출처는 [Classifier-Free Diffusion Guidance](https://arxiv.org/pdf/2207.12598){:target="_blank" rel="noopener"}다.

Slide 40의 conditional denoising objective를 DDPM noise-prediction notation으로 쓰면

$$
\mathcal L_{\mathrm{cond}}(\theta)
=\mathbb E_{(x,y)\sim p_{\mathrm{data}}}
\left[
\mathbb E_{\epsilon\sim\mathcal N(0,I)}
\left[
\mathbb E_{t\sim\operatorname{Unif}\{1,\ldots,T\}}
\left[
\left\lVert
\epsilon-
\epsilon_\theta\left(
\sqrt{\bar\alpha_t}x
+\sqrt{1-\bar\alpha_t}\epsilon,
t,y
\right)
\right\rVert_2^2
\right]
\right]
\right].
$$

Condition $$y$$는 network input $$\epsilon_\theta(x_t,t,y)$$를 바꾸지만, forward corruption $$\epsilon\sim\mathcal N(0,I)$$와 target $$\epsilon$$ 자체를 바꾸지 않는다. 즉 class/text condition마다 다른 Gaussian noise target을 만드는 것이 아니라, 같은 noisy input에서 condition에 맞는 reverse direction을 예측하게 한다. 조건 drop을 사용하는 CFG training에서는 일부 sample의 $$y$$를 null condition으로 바꾸지만 Gaussian target은 그대로다.

Bayes rule은

$$
\log p(x\mid y)
=\log p(y\mid x)+\log p(x)-\log p(y)
$$

이고 $$y$$를 고정한 채 $$x$$로 미분하면

$$
\begin{aligned}
\nabla_x\log p(x\mid y)
&=\nabla_x\log p(y\mid x)
+\nabla_x\log p(x)
-\nabla_x\log p(y) \\
&=\nabla_x\log p(y\mid x)
+\nabla_x\log p(x),
\end{aligned}
$$

이다. 마지막 등식에서 $$p(y)$$는 $$x$$의 함수가 아니므로

$$
\nabla_x\log p(y)=0
$$

을 명시적으로 사용했다. Conditional score를 $$s_c=\nabla_x\log p(x\mid y)$$, unconditional score를 $$s_u=\nabla_x\log p(x)$$라 하면

$$
\nabla_x\log p(y\mid x)=s_c-s_u.
$$

강의 convention은

$$
s_{\mathrm{CFG}}
=(1+w)s_c-ws_u
=s_c+w(s_c-s_u),
\qquad w\ge0.
$$

따라서 이 convention에서 $$w=0$$이 true conditional prediction이고 $$w>0$$은 classifier direction을 더 강조한다. 반면 흔히 쓰는 다른 표기

$$
s_{\mathrm{CFG}}=s_u+\gamma(s_c-s_u)
$$

에서는 $$\gamma=0$$이 unconditional, $$\gamma=1$$이 conditional이며 두 convention은 $$\gamma=1+w$$로 대응한다. 이 **parameterization boundary**를 밝히지 않고 숫자만 비교하면 guidance strength를 잘못 해석한다. 위 Bayes 등식은 exact score에 대한 항등식이지만 neural predictions의 선형 조합은 근사다. 큰 guidance는 condition fidelity를 높일 수 있으나 diversity 감소, saturation, off-manifold artifact와 numerical stiffness를 유발할 수 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | $$\nabla_x\log p_t(x)$$. 현재 위치에서 density가 커지는 방향을 나타낸다. |
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

1. Score function이 density 자체와 어떻게 다른지 먼저 정리한다. 특히 $$\nabla_x\log p_t(x)$$가 정규화 상수를 제거한다는 점을 확인한다.
2. DDPM forward process와 reverse process를 분리해서 그린다. Forward는 fixed Gaussian corruption이고, reverse만 learned decoder다.
3. DDPM ELBO가 noise prediction 또는 denoising objective로 단순화되는 이유를 VAE 관점에서 추적한다.
4. Discrete-time diffusion, SDE, ODE를 같은 score model의 세 가지 사용 방식으로 비교한다.
5. Sampling speedup을 공부할 때는 DDIM, numerical solver, progressive distillation, latent diffusion이 각각 어느 비용을 줄이는지 구분한다.
6. Conditional generation에서는 classifier guidance와 classifier-free guidance의 차이를 조건 신호의 출처 기준으로 정리한다.

## 복습 질문

<details markdown="block">
<summary>1. Score-based model이 density를 직접 정규화하지 않아도 sample을 만들 수 있는 이유는 무엇인가?</summary>

답변: score function은 현재 위치에서 density가 증가하는 방향을 알려준다. 이 vector field를 따라 Langevin dynamics나 reverse diffusion sampler를 실행하면 simple noise에서 data manifold 쪽으로 이동할 수 있다. 정규화 상수는 $$x$$에 대한 gradient에서 사라지므로 score 학습에는 직접 필요하지 않다.

</details>

<details markdown="block">
<summary>2. DDPM을 hierarchical VAE로 볼 때 encoder와 decoder는 각각 무엇인가?</summary>

답변: Encoder는 data에 Gaussian noise를 단계적으로 추가하는 fixed forward process $$q$$다. Decoder는 $$x_t$$에서 $$x_{t-1}$$을 복원하는 learned reverse transition이다. Latent variables는 intermediate noisy states $$x_1,\ldots,x_T$$로 볼 수 있다.

</details>

<details markdown="block">
<summary>3. DDPM의 ELBO와 denoising score matching은 어떻게 연결되는가?</summary>

답변: Gaussian forward process를 사용하면 ELBO의 단계별 reconstruction 항이 각 time step에서 추가된 noise를 예측하는 denoising loss로 단순화된다. 이 denoising objective는 noise-perturbed distribution의 score를 학습하는 denoising score matching과 같은 정보를 사용한다.

</details>

<details markdown="block">
<summary>4. Reverse SDE에서 score model이 필요한 이유는 무엇인가?</summary>

답변: Forward SDE는 data를 noise로 보내지만, 이를 시간 반대로 뒤집으려면 각 시점의 분포 $$p_t(x)$$가 어떤 방향으로 증가하는지 알아야 한다. Reverse-time dynamics의 drift에는 $$\nabla_x\log p_t(x)$$가 들어가므로, 시간 조건 score model이 reverse sampling을 정의한다.

</details>

<details markdown="block">
<summary>5. Probability flow ODE가 diffusion model에 주는 장점은 무엇인가?</summary>

답변: Probability flow ODE는 reverse SDE와 같은 marginal distribution을 갖는 deterministic dynamics다. 그래서 continuous normalizing flow처럼 change-of-variables를 이용한 likelihood 평가가 가능하고, stochastic sampler보다 큰 numerical step을 사용하는 빠른 sampling 전략과 연결된다.

</details>

<details markdown="block">
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
- [Hyvärinen, Estimation of Non-Normalized Statistical Models by Score Matching (2005)](https://www.jmlr.org/papers/volume6/hyvarinen05a/hyvarinen05a.pdf){:target="_blank" rel="noopener"}
- [Song and Ermon, Generative Modeling by Estimating Gradients of the Data Distribution (NCSN)](https://arxiv.org/pdf/1907.05600){:target="_blank" rel="noopener"}
- [Ho, Jain, and Abbeel, Denoising Diffusion Probabilistic Models (DDPM)](https://arxiv.org/pdf/2006.11239){:target="_blank" rel="noopener"}
- [Song et al., Score-Based Generative Modeling through Stochastic Differential Equations](https://arxiv.org/pdf/2011.13456){:target="_blank" rel="noopener"}
- [Chen et al., Neural Ordinary Differential Equations](https://arxiv.org/pdf/1806.07366){:target="_blank" rel="noopener"}
- [Ho and Salimans, Classifier-Free Diffusion Guidance](https://arxiv.org/pdf/2207.12598){:target="_blank" rel="noopener"}
