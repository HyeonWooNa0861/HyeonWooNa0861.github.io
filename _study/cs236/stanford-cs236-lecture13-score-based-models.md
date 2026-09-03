---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:55:00 +0900
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

> **Preview note:** 이 원본은 외부 PPTX이고 공식 PowerPoint for the web iframe이 제공되지 않아 블로그의 문서 모달에서 직접 미리보기하지 않는다. `Source Slides`를 새 탭에서 열어야 하며, 아래 번호는 PPTX package의 1-based slide 순서를 따른다. 정적 viewer에서는 animation 단계나 equation image가 누락될 수 있다.

> **핵심:** Lecture 13은 score-based model의 출발점을 정리한다. 지금까지의 generative model은 크게 세 가지 표현으로 나눌 수 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Distribution representation recap | density, sampling process, score는 각각 어떤 generative model family를 만드는가? |
| 2 | Score function | $$\nabla_x\log p(x)$$는 density 대신 무엇을 표현하며, 왜 normalization 제약에서 자유로운가? |
| 3 | Direct score modeling | EBM처럼 energy를 만들지 않고 vector field 자체를 모델링할 수 있는가? |
| 4 | Denoising score matching | Gaussian noise를 더하면 score estimation이 왜 denoising 문제로 바뀌는가? |
| 5 | Sliced score matching | high-dimensional Jacobian trace 비용을 random projection으로 어떻게 줄이는가? |
| 6 | Langevin sampling | score만 알고 있을 때 $$\epsilon$$-step update와 noise로 sample을 어떻게 만드는가? |
| 7 | Practical failure modes | manifold, low-density region, mode mixing 문제는 왜 다음 diffusion 설계로 이어지는가? |

### 원본 수식 위치

| 원본 PPTX | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| slides 8--17 | Score 정의, EBM score, Fisher·implicit score matching | `Vanilla Fisher score matching`에서 정의와 작성자 보충 integration-by-parts 유도를 구분한다. |
| slides 18--24 | Gaussian perturbation과 denoising score matching | `denoising target`에서 conditional target과 perturbed marginal score의 정확한 동치를 유도한다. |
| slides 26--27 | Tweedie 공식 | `Tweedie 공식과 sliced objective`에서 정확한 Gaussian identity와 조건을 설명한다. |
| slides 28--31 | Sliced Fisher divergence와 Jacobian-vector product | 같은 절에서 random-projection identity와 Monte Carlo 근사를 구분한다. |
| slides 34--35 | Langevin update | `핵심 내용`에서 sampling 식과 step-size/mixing 실패 조건을 설명한다. |
| slides 39--43 | Manifold, low-density, disjoint-mode 실패 사례 | `핵심 내용`과 마지막 정리에서 수식이 적용되기 어려운 영역을 설명한다. |

## 핵심 내용

Lecture 13은 score-based model의 출발점을 정리한다. 지금까지의 generative model은 크게 세 가지 표현으로 나눌 수 있다. Autoregressive model, normalizing flow, VAE, EBM은 $$p_\theta(x)$$ 또는 그 근사를 직접 다룬다. GAN은 density 대신 $$z\sim p(z)$$, $$x=g_\theta(z)$$라는 sampling process를 다룬다. 이번 강의의 세 번째 표현은 score function이다.

$$
s_p(x)=\nabla_x\log p(x)
$$

여기서 gradient는 parameter가 아니라 input $$x$$에 대한 미분이다. Score는 각 위치에서 log density가 가장 빠르게 증가하는 방향을 주는 vector field다. Density가 scalar surface라면 score는 그 surface의 방향장이다. 중요한 점은 score가 normalization constant에 둔감하다는 것이다. EBM에서 $$p_\theta(x)=\exp(f_\theta(x))/Z(\theta)$$이면 $$\log Z(\theta)$$는 $$x$$에 대해 상수이므로 $$\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)$$가 된다. 따라서 score는 $$Z(\theta)$$를 계산하지 않고도 쓸 수 있다.

Score-based model은 여기서 한 걸음 더 간다. EBM은 scalar energy를 먼저 만들고 그 gradient를 score로 쓴다. 반면 score-based model은 $$s_\theta(x)$$라는 vector-valued neural network를 직접 학습한다. 이 vector field가 어떤 scalar potential의 gradient인지 반드시 보장하지 않아도 된다. 이상적으로는

$$
s_\theta(x)\approx \nabla_x\log p_{\mathrm{data}}(x)
$$

가 되게 만들고, training criterion은 Fisher divergence처럼 score field의 차이를 줄이는 방식으로 잡는다. 그러나 vanilla score matching은 deep high-dimensional model에서 계산 비용이 크다. 원래 score matching loss를 integration by parts로 변형하면 data score를 제거할 수 있지만, model score의 Jacobian trace 또는 second derivative 항이 남는다. Image처럼 차원이 큰 입력에서는 이 항을 직접 계산하고 역전파하는 것이 부담스럽다.

Denoising score matching은 이 병목을 practical하게 푸는 첫 번째 방법이다. Clean data $$x$$에 Gaussian noise를 더해 $$\tilde{x}=x+\sigma\epsilon$$을 만들고, clean data distribution이 아니라 noise-perturbed distribution의 score를 학습한다. Gaussian perturbation에서는 conditional perturbation kernel의 score가

$$
\nabla_{\tilde{x}}\log q_\sigma(\tilde{x}\mid x)=-\frac{\tilde{x}-x}{\sigma^2}
$$

처럼 noisy point를 원래 sample 방향으로 끌어당긴다. 그래서 score estimation은 "어떤 noise가 더해졌는지 예측하고 제거하는" denoising 문제와 연결된다. 이 방식은 Jacobian trace 없이 supervised regression처럼 학습할 수 있어 image model에 적합하다. 단점은 목표가 clean data score가 아니라 noise-perturbed data score라는 점이다. $$\sigma$$가 작으면 원래 분포에 가깝지만 추정 variance가 커지고, $$\sigma$$가 크면 학습은 쉬워지지만 분포가 너무 흐려진다.

Sliced score matching은 두 번째 scalable alternative다. 전체 vector field를 모든 좌표에서 직접 비교하지 않고, random direction $$v$$로 projection한 1D score만 비교한다. 여러 random projection에서 projected score가 맞으면 전체 vector field도 가까워진다는 직관을 사용한다. 이 방식도 integration by parts로 data score를 제거할 수 있고, Jacobian-vector product를 사용해 full trace보다 훨씬 싸게 계산한다. Denoising score matching보다 조금 느릴 수 있지만, noise-perturbed distribution이 아니라 true data score를 직접 겨냥한다는 장점이 있다.

학습한 score를 sample로 바꾸는 기본 절차는 Langevin dynamics다.

$$
x_{t+1}=x_t+\epsilon s_\theta(x_t)+\sqrt{2\epsilon}z_t,\qquad z_t\sim\mathcal{N}(0,I)
$$

첫 항은 score 방향으로 log probability가 높은 곳을 향하게 하고, noise 항은 distribution 전체를 탐색하게 한다. 이론적으로 step size를 작게 하고 충분히 오래 돌리면 target distribution으로 수렴할 수 있다. 하지만 강의는 이 단순한 조합이 실제 image generation에서는 바로 성공하지 않는 이유도 강조한다. Real data는 저차원 manifold 위에 놓일 수 있어 clean density score가 잘 정의되지 않거나 폭주할 수 있다. Training sample은 high-density region에 몰려 있으므로 low-density region의 score는 부정확하다. 또한 분리된 mode 사이를 Langevin chain이 잘 이동하지 못하면 mixture weight가 제대로 반영되지 않는다. 이 세 문제는 다음 강의에서 multi-scale noise와 annealing으로 해결된다.

### Vanilla Fisher score matching에서 implicit objective까지 (작성자 보충)

> **Source mapping:** Official Lecture 13 PPTX slides 15--17의 score field 비교, Fisher divergence, score-matching 계산식에 대응한다. Exact Office Viewer slide ID로 전체 44개 슬라이드를 열어 시각 감사했으며, 해당 formula/media object와 XML을 교차 확인했다. Static viewer capture에서 드러나지 않는 animation 단계는 package object와 XML을 기준으로 확인했다.

$$x\in\Omega\subseteq\mathbb R^d$$, data density를 $$p(x)$$, 그 정확한 score를 $$s_p(x)=\nabla_x\log p(x)$$, 학습 가능한 vector field를 $$s_\theta(x)\in\mathbb R^d$$라 하자. Vanilla Fisher score-matching objective는 두 score field의 평균 제곱 거리를 측정한다.

$$
\mathcal J_{\mathrm F}(\theta)
=\frac12\mathbb E_{x\sim p}
\left[\left\lVert s_\theta(x)-s_p(x)\right\rVert_2^2\right].
$$

제곱을 전개하면

$$
\begin{aligned}
\mathcal J_{\mathrm F}(\theta)
&=\frac12\int_\Omega p(x)\left\lVert s_\theta(x)\right\rVert_2^2dx
-\int_\Omega p(x)s_\theta(x)^{\top}\nabla_x\log p(x)dx
+C_p \\
&=\frac12\int_\Omega p(x)\left\lVert s_\theta(x)\right\rVert_2^2dx
-\sum_{i=1}^d\int_\Omega s_{\theta,i}(x)\,\partial_{x_i}p(x)dx
+C_p,
\end{aligned}
$$

여기서

$$
C_p=\frac12\mathbb E_{x\sim p}\left[\left\lVert s_p(x)\right\rVert_2^2\right]
$$

는 $$\theta$$와 무관하다. 두 번째 등식은 $$p\nabla_x\log p=\nabla_xp$$를 사용한다. 이제 divergence theorem, 즉 다변수 integration by parts를 적용하면 cross term은

$$
\begin{aligned}
-\int_\Omega s_\theta(x)^{\top}\nabla_xp(x)dx
&=-\int_{\partial\Omega}p(x)s_\theta(x)^{\top}n(x)dS \\
&\quad+\int_\Omega p(x)\,\nabla_x\!\cdot s_\theta(x)dx,
\end{aligned}
$$

가 된다. $$n(x)$$는 경계의 바깥쪽 단위 법선이다. 따라서 경계항

$$
B_\theta
=\int_{\partial\Omega}p(x)s_\theta(x)^{\top}n(x)dS
$$

가 0이면, $$\theta$$와 무관한 $$C_p$$를 제외한 implicit score-matching objective는

$$
\boxed{
\mathcal J_{\mathrm{SM}}(\theta)
=\mathbb E_{x\sim p}
\left[
\frac12\left\lVert s_\theta(x)\right\rVert_2^2
+\nabla_x\!\cdot s_\theta(x)
\right]
}
$$

이다. 좌표로 쓰면 $$\nabla_x\!\cdot s_\theta=\sum_{i=1}^d\partial s_{\theta,i}/\partial x_i$$이므로 data score $$s_p$$는 사라지지만, model Jacobian의 trace를 계산해야 한다.

이 등가는 다음과 같은 충분조건 아래에서 **정확하다**. $$p$$는 미분 가능하고, $$s_\theta$$는 좌표별로 연속 미분 가능하며, 위 적분들이 유한하고 미분·적분 교환이 허용되어야 한다. $$\Omega=\mathbb R^d$$이면 $$R\to\infty$$에서

$$
\int_{\partial B_R}p(x)s_\theta(x)^{\top}n(x)dS\longrightarrow0
$$

일 만큼 density와 vector field의 곱이 충분히 빨리 감소하면 된다. 유계 영역에서는 $$p(x)s_\theta(x)^{\top}n(x)=0$$ 같은 zero-flux 경계조건이면 충분하다. 이 조건이 깨지면 누락한 $$-B_\theta$$가 $$\theta$$에 의존하므로 두 objective는 동등하지 않다.

모든 좌표가 공통 단위 $$U$$를 갖도록 정규화했다고 보면 $$p$$의 단위는 $$U^{-d}$$, $$s_p$$와 $$s_\theta$$의 단위는 $$U^{-1}$$, divergence와 objective의 단위는 $$U^{-2}$$다. 서로 다른 물리 단위의 좌표를 그대로 Euclidean norm에 더하려면 별도의 무차원화 또는 metric이 필요하다. 위 변형은 population density와 매끄러운 field에 대한 **정확한 항등식**이지만, 유한 표본·제한된 network·수치 최적화로 얻은 $$s_\theta\approx s_p$$는 **학습된 근사**다. 또한 임의의 $$s_\theta$$가 반드시 어떤 scalar energy의 gradient일 필요는 없다.

### 핵심 수식 유도: denoising target이 perturbed score를 주는 이유

> **Source mapping:** Official Lecture 13 PPTX slides 18--23의 denoising score-matching 식에 대응한다. Exact Office Viewer slide ID로 전체 44개 슬라이드를 열어 시각 감사했으며, 해당 formula/media object와 XML을 교차 확인했다. Static viewer capture에서 드러나지 않는 animation 단계는 package object와 XML을 기준으로 확인했다.

Gaussian corruption $$q_\sigma(\tilde x\mid x)=\mathcal N(x,\sigma^2I)$$에서 log-density를 $$\tilde x$$로 미분하면

$$
\nabla_{\tilde x}\log q_\sigma(\tilde x\mid x)
=-\frac{\tilde x-x}{\sigma^2}
$$

이라는 **정확한 등식**을 얻는다. 또한 미분과 적분 교환이 가능하고 $$q_\sigma(\tilde x)>0$$이면

$$
\mathbb E\!\left[\nabla_{\tilde x}\log q_\sigma(\tilde x\mid x)\mid\tilde x\right]
=\nabla_{\tilde x}\log q_\sigma(\tilde x).
$$

따라서 conditional target을 squared-error로 회귀한 population optimum은 noisy marginal의 score다. $$x,\tilde x,\sigma$$는 같은 좌표 단위이고 score는 역단위다. 유한 데이터·제한된 network에서는 근사일 뿐이며, $$\sigma$$가 너무 작으면 manifold 근처 score가 불안정하고 너무 크면 원분포의 세부 구조가 사라진다.

### Tweedie 공식과 sliced objective (작성자 보충; 강의의 denoising/sliced 식 전개)

> **Source mapping:** Official Lecture 13 PPTX slides 26--27의 Tweedie 공식과 slides 28--31의 sliced score-matching objective에 대응한다. Exact Office Viewer slide ID로 전체 44개 슬라이드를 열어 시각 감사했으며, 해당 formula/media object와 XML을 교차 확인했다. Static viewer capture에서 드러나지 않는 animation 단계는 package object와 XML을 기준으로 확인했다.

Gaussian observation $$Y=X+\varepsilon$$, $$\varepsilon\sim\mathcal N(0,\sigma^2I)$$에서 noisy marginal을 $$p_Y$$라 두면 Tweedie의 공식은

$$
\mathbb E[X\mid Y=y]
=y+\sigma^2\nabla_y\log p_Y(y)
$$

이다. **증명 개요**는 Gaussian kernel을 미분하는 한 줄에서 시작한다.

$$
\begin{aligned}
\nabla_y p_Y(y)
&=\int p_X(x)\nabla_y\mathcal N(y;x,\sigma^2I)dx\\
&=\int p_X(x)\mathcal N(y;x,\sigma^2I)
\frac{x-y}{\sigma^2}dx\\
&=p_Y(y)\frac{\mathbb E[X\mid Y=y]-y}{\sigma^2}.
\end{aligned}
$$

$$p_Y(y)>0$$인 곳에서 나누면 위 공식이 나온다. Gaussian additive noise, finite posterior mean, 미분과 적분 교환을 가정한 **정확한 항등식**이며, learned score를 넣은 denoiser는 model/estimation error를 가진 **근사**다. $$x,y,\sigma$$의 단위가 $$U$$이면 score는 $$U^{-1}$$이고 $$\sigma^2s(y)$$는 $$U$$라 posterior-mean correction과 단위가 맞는다. Noise가 Gaussian이 아니면 이 단순한 $$\sigma^2$$ 보정식은 일반적으로 성립하지 않는다.

Sliced score matching에서는 $$v$$를 $$\mathbb E[vv^{\top}]=I$$인 Gaussian 또는 Rademacher direction으로 뽑고, **sliced Fisher divergence**를

$$
\mathcal J_{\mathrm{SF}}(\theta)
=\frac12\mathbb E_{x\sim p,\,v}
\left[\left(v^{\top}s_\theta(x)-v^{\top}\nabla_x\log p(x)\right)^2\right]
$$

로 정의한다. Boundary term이 사라질 만큼 $$p$$와 $$s_\theta$$가 매끄럽고 integrable하다고 가정해 integration by parts를 적용하면, $$\theta$$와 무관한 상수를 제외한 **정확히 동등한 implicit objective**는

$$
\mathcal J_{\mathrm{SSM}}(\theta)
=\mathbb E_{x,v}
\left[v^{\top}\nabla_xs_\theta(x)v
+\frac12\left(v^{\top}s_\theta(x)\right)^2\right].
$$

첫 항은 Jacobian-vector product 한 번으로 계산할 수 있어 full Jacobian trace를 만들지 않는다. Monte Carlo로 적은 $$v$$만 쓰는 것은 unbiased stochastic estimate지만 variance가 있고, boundary decay가 깨지거나 vector field가 미분 불가능하면 implicit 등가성이 실패한다. $$v$$는 무차원으로 두며 objective의 단위는 $$U^{-2}$$다. Direction covariance가 identity가 아니면 원래 Fisher geometry가 아니라 그 covariance로 가중된 metric을 학습한다.

### Disjoint-support mixture에서 mode weight가 score에서 사라지는 이유 (작성자 보충)

> **Source mapping:** Official Lecture 13 PPTX slides 42--43의 two-mode disjoint-support mixture와 Langevin slow-mixing 식에 대응한다. Exact Office Viewer slide ID로 전체 44개 슬라이드를 열어 시각 감사했으며, 해당 formula/media object와 XML을 교차 확인했다. Static viewer capture에서 드러나지 않는 animation 단계는 package object와 XML을 기준으로 확인했다.

정규화된 두 density $$p_1,p_2$$와 무차원 mixture weight $$0<\pi<1$$에 대해

$$
p(x)=\pi p_1(x)+(1-\pi)p_2(x)
$$

라 하자. 두 support $$\Omega_1=\operatorname{supp}(p_1)$$, $$\Omega_2=\operatorname{supp}(p_2)$$가 서로 겹치지 않고, 각 support의 내부에서는 해당 component density가 양수라고 가정한다. 그러면 $$x\in\operatorname{int}(\Omega_1)$$인 곳에는 $$p_2(x)=0$$인 근방이 있으므로

$$
\log p(x)=\log\pi+\log p_1(x),
$$

반대로 $$x\in\operatorname{int}(\Omega_2)$$에서는

$$
\log p(x)=\log(1-\pi)+\log p_2(x).
$$

따라서 각 support 내부의 score는 정확히

$$
\nabla_x\log p(x)
=\begin{cases}
\nabla_x\log p_1(x), & x\in\operatorname{int}(\Omega_1),\\
\nabla_x\log p_2(x), & x\in\operatorname{int}(\Omega_2).
\end{cases}
$$

이다. $$\pi$$와 $$1-\pi$$는 $$x$$에 대해 상수이므로 $$\nabla_x\log\pi=\nabla_x\log(1-\pi)=0$$이다. 즉, disconnected component 안에서 density 전체를 상수배해도 local log-density derivative는 변하지 않는다. 이 식은 disjoint support의 매끄러운 내부에서 성립하는 **정확한 등식**이다.

이 결론에는 중요한 경계가 있다. Support boundary에서 density가 0이 되거나 불연속이면 $$\log p$$와 score가 정의되지 않거나 발산할 수 있다. 두 component가 겹치는 영역에서는 posterior responsibility

$$
r_1(x)=\frac{\pi p_1(x)}{p(x)},
\qquad
r_2(x)=\frac{(1-\pi)p_2(x)}{p(x)}
$$

를 사용해

$$
\nabla_x\log p(x)
=r_1(x)\nabla_x\log p_1(x)
+r_2(x)\nabla_x\log p_2(x)
$$

가 되므로 score가 일반적으로 $$\pi$$에 의존한다. 따라서 mixture weight가 사라진다는 주장은 **서로 분리된 support의 내부**로 한정해야 한다.

Score는 각 연결 성분 안의 density 모양만 알려 주는 local derivative다. 서로 떨어진 성분마다 더한 상수 $$\log\pi$$와 $$\log(1-\pi)$$의 상대 차이를 미분만으로 복원할 수 없으므로, score alone은 mode mass $$\pi:(1-\pi)$$를 식별하지 못한다. 더구나 두 support 사이가 zero-density gap이면 local Langevin chain은 그 구간의 유효한 score 정보를 얻지 못하고 mode를 건너기 어렵다. 결국 초기화와 유한 시간 mixing에 따라 표본 비율이 결정되어 true mixture mass를 재현하지 못할 수 있다. 좌표 단위가 $$U$$이면 $$p,p_1,p_2$$는 $$U^{-d}$$, score는 $$U^{-1}$$이고 $$\pi,r_1,r_2$$는 무차원이다. 실제 neural score와 유한-step Langevin 결과는 이 population 분석에 대한 **학습·수치 근사**다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | $$\nabla_x\log p(x)$$. 입력 위치에서 log density가 증가하는 방향과 크기를 주는 vector field다. |
| Score-based model | Density나 energy 대신 $$s_\theta(x)$$ 자체를 vector-valued neural network로 parameterize하는 model family다. |
| Fisher divergence | 두 분포의 score field 차이를 평균 제곱으로 측정하는 divergence다. Score matching의 기본 목적함수다. |
| Denoising score matching | Noisy sample에서 추가된 noise를 예측하는 문제로 score estimation을 바꾸어 scalable training을 가능하게 한다. |
| Tweedie's formula | Optimal denoising direction이 perturbed density의 score와 연결된다는 결과로, denoising과 score matching의 등가성을 설명한다. |
| Sliced score matching | Random projection 방향에서 score를 비교해 high-dimensional Jacobian trace 계산을 줄이는 방법이다. |
| Langevin dynamics | Score gradient를 따라가면서 Gaussian noise를 더해 target distribution에서 sample을 얻는 MCMC 절차다. |
| Manifold hypothesis | Image 같은 real data가 ambient space 전체가 아니라 훨씬 낮은 차원의 구조 위에 놓인다는 가정이다. |

## 학습 포인트

- Score의 gradient는 $$\theta$$가 아니라 $$x$$에 대한 미분이다. Parameter update gradient와 혼동하면 EBM과 score model의 장점이 흐려진다.
- Score field는 normalization constant를 보지 않으므로 $$Z(\theta)$$가 어려운 EBM과 자연스럽게 맞물린다.
- Direct score modeling은 "valid density를 명시적으로 정의하는가"보다 "sampling에 필요한 방향장을 잘 학습하는가"에 초점을 둔다.
- Denoising score matching은 score estimation을 denoising regression으로 바꾸기 때문에 deep image architecture와 잘 맞는다.
- Sliced score matching은 true score를 겨냥하지만 random projection과 derivative 계산이 필요해 denoising 방식보다 느릴 수 있다.
- Langevin dynamics는 score만으로 sampling할 수 있게 하지만, clean data score를 바로 쓰면 manifold와 low-density region에서 실패하기 쉽다.

## 마지막 핵심 정리

Lecture 13의 핵심은 generative model을 density나 sampler가 아니라 score field로 표현할 수 있다는 점이다. Score는 normalization 문제를 피하고, denoising 또는 sliced score matching으로 학습할 수 있으며, Langevin dynamics와 결합하면 sample을 만들 수 있다. 그러나 clean score를 한 번에 학습하고 sampling하는 방식은 manifold, low-density region, slow mixing 문제를 남긴다. 이 한계가 multi-scale noise와 diffusion model로 이어진다.

## Study Guide

1. 먼저 $$p_\theta(x)$$, $$g_\theta(z)$$, $$s_\theta(x)$$가 각각 어떤 model family의 중심 객체인지 비교한다.
2. EBM에서 $$\nabla_x\log Z(\theta)=0$$이 되는 이유를 직접 써 보고, score가 partition function을 피하는 위치를 확인한다.
3. Vanilla score matching의 문제가 "data score를 모른다"에서 끝나지 않고 "Jacobian trace가 비싸다"로 이어지는 흐름을 정리한다.
4. Denoising score matching과 sliced score matching을 target distribution, 계산 비용, 장점 기준으로 비교한다.
5. Langevin dynamics update에서 gradient term과 noise term의 역할을 분리한다.
6. 다음 강의를 읽기 전에 단일 noise scale이 왜 clean sample generation과 accurate score estimation 사이의 tradeoff를 만드는지 생각해 본다.

## 복습 질문

<details markdown="block">
<summary>1. Score-based model이 density model과 다른 점은 무엇인가?</summary>

답변: Density model은 각 $$x$$에 probability density 또는 mass를 할당하고 normalization을 맞춰야 한다. Score-based model은 $$x$$에서 $$\nabla_x\log p(x)$$에 해당하는 vector field를 직접 모델링한다. 따라서 likelihood 값을 바로 주지는 않지만, score matching과 Langevin dynamics를 통해 학습과 sampling을 수행할 수 있다.

</details>

<details markdown="block">
<summary>2. EBM에서 score가 partition function을 제거하는 이유는 무엇인가?</summary>

답변: $$\log p_\theta(x)=f_\theta(x)-\log Z(\theta)$$이고 $$Z(\theta)$$는 입력 $$x$$가 아니라 parameter $$\theta$$에 의존한다. $$x$$에 대해 미분하면 $$\nabla_x\log Z(\theta)=0$$이므로 score는 $$\nabla_x f_\theta(x)$$만 남는다.

</details>

<details markdown="block">
<summary>3. Denoising score matching이 scalable한 이유는 무엇인가?</summary>

답변: Vanilla score matching은 high-dimensional input에서 Jacobian trace나 second derivative 계산이 비싸다. Denoising score matching은 noisy sample을 clean sample 방향으로 복원하는 regression 문제로 바뀌어, 일반적인 neural network training처럼 loss를 계산하고 역전파할 수 있다.

</details>

<details markdown="block">
<summary>4. Sliced score matching은 어떤 비용을 줄이는가?</summary>

답변: 전체 좌표의 score field와 Jacobian trace를 직접 계산하는 대신 random direction으로 projection한 1D score를 비교한다. Autodiff에서 Jacobian-vector product를 활용할 수 있어 full trace 계산보다 비용이 낮다.

</details>

<details markdown="block">
<summary>5. Langevin dynamics에서 noise term이 필요한 이유는 무엇인가?</summary>

답변: Score 방향만 따르면 단순한 optimization처럼 local high-density region으로 이동하는 절차가 된다. Sampling은 분포 전체의 확률 질량을 반영해야 하므로 Gaussian noise를 더해 exploration과 mode 이동 가능성을 유지한다.

</details>

<details markdown="block">
<summary>6. Clean data score만으로 image generation을 하기 어려운 이유는 무엇인가?</summary>

답변: Real image data는 저차원 manifold에 놓일 수 있어 ambient space 전체에서 score가 안정적으로 정의되지 않는다. 또 training data가 거의 없는 low-density region에서는 score 추정이 부정확하고, 분리된 mode 사이의 Langevin mixing도 느리다. 그래서 다음 단계에서는 여러 noise level을 사용해 score를 더 안정적으로 학습한다.

</details>

## Slides

- [Official Lecture 13 slide deck](https://deepgenerativemodels.github.io/assets/slides/lecture%2013.pptx){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 13 Slides](https://deepgenerativemodels.github.io/assets/slides/lecture%2013.pptx){:target="_blank" rel="noopener"}
- [CS236 Lecture 13 Video](https://www.youtube.com/watch?v=8G-OsDs1RLI){:target="_blank" rel="noopener"}
- [Estimation of Non-Normalized Statistical Models by Score Matching (Hyvärinen, 2005)](https://www.jmlr.org/papers/volume6/hyvarinen05a/hyvarinen05a.pdf){:target="_blank" rel="noopener"}
- [Generative Modeling by Estimating Gradients of the Data Distribution (NCSN)](https://arxiv.org/pdf/1907.05600){:target="_blank" rel="noopener"}
- [A Connection Between Score Matching and Denoising Autoencoders (Neural Computation DOI)](https://doi.org/10.1162/NECO_a_00142){:target="_blank" rel="noopener"}
