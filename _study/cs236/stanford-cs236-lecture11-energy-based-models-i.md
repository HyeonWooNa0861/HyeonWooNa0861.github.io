---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:55:00 +0900
title: "Stanford CS236 Lecture 11: Energy-Based Models I"
course: "CS236"
topic: "Partition Functions, Product of Experts, RBMs, and Contrastive Divergence"
order: 11
major_topic: "Deep Generative Models"
keywords:
  - "Energy-Based Models"
  - "Partition Function"
  - "Product of Experts"
  - "Restricted Boltzmann Machine"
  - "Contrastive Divergence"
---

# Stanford CS236 Lecture 11: Energy-Based Models I

## Source

- Video: [Stanford CS236 Deep Generative Models Lecture 11](https://www.youtube.com/watch?v=m61KiAMCJ5Q){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture11.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture11.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 11은 energy-based model(EBM)을 통해 생성 모델의 design space를 다시 정리한다. Autoregressive model은 chain rule로 joint probability를 조건부들의 곱으로 만들기 때문에 likelihood 계산과 sampling이 명확하지만 순서와 factorization 구조가 들어간다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Motivation | autoregressive, flow, VAE, GAN은 각각 어떤 제약과 장단점을 갖는가? |
| 2 | Normalization | probability distribution에서 non-negativity보다 sum-to-one 조건이 왜 어려운가? |
| 3 | EBM definition | 임의의 neural network $$f_\theta(x)$$를 probability model로 바꾸려면 무엇을 나눠야 하는가? |
| 4 | Applications | $$Z(\theta)$$를 몰라도 relative comparison으로 해결 가능한 문제는 무엇인가? |
| 5 | Model examples | Ising model, Product of Experts, RBM, Deep Boltzmann Machine은 EBM 관점에서 어떻게 연결되는가? |
| 6 | Learning and sampling | contrastive divergence와 MCMC는 partition function 문제를 어떻게 근사하는가? |

### 원본 수식 위치

| 원본 PDF | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| pp. 5--10 | 확률 정규화 조건, EBM과 partition function 정의 | `핵심 내용`에서 원문 정의와 계산 난점을 설명한다. |
| pp. 11--16 | Partition function이 소거되는 ratio, Ising·Product of Experts·RBM | `핵심 내용`과 `핵심 개념`에서 원문 모델 예시로 설명한다. |
| p. 20 | RBM partition function의 지수적 상태 합 | `핵심 내용`의 curse-of-dimensionality 설명에 대응한다. |
| p. 23 | Log-likelihood gradient와 contrastive-divergence 근사 | `partition function gradient`에서 정확한 등식과 짧은-chain 근사를 구분한다. |
| pp. 24--25 | Symmetric Metropolis--Hastings와 Langevin MCMC | `MH detailed balance`와 `Langevin stationary distribution`에서 각각 정확 조건과 이산화 근사를 구분한다. |

## 핵심 내용

Lecture 11은 energy-based model(EBM)을 통해 생성 모델의 design space를 다시 정리한다. Autoregressive model은 chain rule로 joint probability를 조건부들의 곱으로 만들기 때문에 likelihood 계산과 sampling이 명확하지만 순서와 factorization 구조가 들어간다. Normalizing flow는 invertible mapping과 Jacobian determinant를 통해 likelihood를 계산하지만 invertibility 제약을 받는다. VAE는 latent variable을 통해 유연성을 얻지만 likelihood는 approximate lower bound로 다룬다. GAN은 sample generator를 마음대로 설계할 수 있지만 likelihood가 없고 minimax training이 불안정하다. EBM은 이 사이에서 "임의의 scoring function을 probability distribution으로 정규화하자"는 접근이다.

확률분포가 되려면 두 조건이 필요하다. 첫째, $$p(x)\ge 0$$이어야 한다. 이는 $$f_\theta(x)^2$$, $$\exp(f_\theta(x))$$, $$\lvert f_\theta(x)\rvert$$, softplus처럼 출력 변환을 붙이면 쉽게 만족시킬 수 있다. 둘째, 모든 가능한 $$x$$에 대해 합 또는 적분이 1이어야 한다. 이 sum-to-one 조건이 핵심 난점이다. Gaussian, exponential distribution, exponential family처럼 단순한 함수족은 normalization constant를 closed form으로 알 수 있지만, high-dimensional image나 text를 arbitrary neural network로 scoring하면 전체 공간에 대한 적분을 계산하기 어렵다.

EBM은 다음과 같이 정의된다.

$$
p_\theta(x)=\frac{\exp(f_\theta(x))}{Z(\theta)},\qquad
Z(\theta)=\int \exp(f_\theta(x))dx
$$

$$\exp(f_\theta(x))$$는 unnormalized probability이고 $$Z(\theta)$$는 partition function 또는 normalization constant다. 물리학 관점에서는 $$-f_\theta(x)$$가 energy이며, 낮은 energy 또는 높은 $$f_\theta(x)$$를 가진 configuration이 더 likely하다. 이 형식의 장점은 $$f_\theta$$에 거의 어떤 neural network든 넣을 수 있다는 flexibility다. 단점은 그 대가로 sampling, likelihood evaluation, likelihood-based learning이 어려워진다는 것이다.

그럼에도 EBM이 유용한 이유는 $$Z(\theta)$$가 많은 비교 문제에서 사라지기 때문이다. 두 점 $$x,x'$$의 probability ratio는

$$
\frac{p_\theta(x)}{p_\theta(x')}=\exp(f_\theta(x)-f_\theta(x'))
$$

이므로 partition function이 cancel된다. 따라서 anomaly detection, denoising, object recognition, sequence labeling, image restoration처럼 "어느 configuration이 더 그럴듯한가"를 묻는 문제에서는 절대 likelihood보다 상대 score가 중요하다. Ising model 예시는 corrupted image $$x$$에서 clean image $$y$$를 복원할 때 pixel fidelity term과 neighboring pixel smoothness term을 더한 energy로 $$p(y,x)$$를 정의하고, $$p(y\mid x)$$를 최대화하는 $$y$$를 찾는 방식이다.

Product of Experts도 EBM의 중요한 예다. 여러 모델 $$q_{\theta_1}(x), r_{\theta_2}(x), t_{\theta_3}(x)$$를 곱하면 각 모델이 동시에 높게 평가하는 영역에 probability mass가 모인다. 혼합 모델이 OR처럼 작동한다면 product는 AND처럼 작동한다. 하나의 expert가 거의 불가능하다고 보는 영역은 product에서도 낮은 probability가 된다. 하지만 곱한 결과는 normalized distribution이 아니므로 다시 partition function으로 나눠야 하며, 이 지점에서 EBM 형태가 나타난다.

Restricted Boltzmann Machine(RBM)은 visible variable $$x\in\{0,1\}^n$$과 latent variable $$z\in\{0,1\}^m$$를 가진 energy-based latent variable model이다.

$$
p_{W,b,c}(x,z)=\frac{1}{Z}\exp(x^{\top}Wz+b^{\top}x+c^{\top}z)
$$

"restricted"라는 이름은 visible-visible 또는 hidden-hidden interaction이 없고, visible과 hidden 사이의 interaction만 $$W$$로 표현한다는 뜻이다. RBM을 여러 층으로 쌓은 Deep Boltzmann Machine은 초기 deep learning에서 supervised network를 사전학습하는 데 쓰인 역사적 의미가 있다. 강의는 이 예시를 통해 partition function 계산이 왜 어려운지 보여 준다. binary $$x,z$$만 있어도 $$Z(W,b,c)$$는 모든 visible-hidden configuration을 합해야 하므로 $$2^n\cdot 2^m$$ 규모로 커진다.

학습의 직관은 training point의 unnormalized score를 올리는 것만으로는 충분하지 않다는 데 있다. $$f_\theta(x_{\mathrm{train}})$$을 올려도 다른 모든 $$x$$의 score가 더 크게 올라가면 normalized probability는 오히려 좋아지지 않을 수 있다. 그래서 maximum likelihood gradient는 data point의 energy gradient를 올리는 항과 model이 생성할 법한 sample의 energy gradient를 내리는 항을 함께 가진다.

$$
\nabla_\theta \log p_\theta(x_{\mathrm{train}})
=\nabla_\theta f_\theta(x_{\mathrm{train}})
-\mathbb{E}_{x\sim p_\theta}[\nabla_\theta f_\theta(x)]
$$

Contrastive divergence는 model expectation을 sample $$x_{\mathrm{sample}}\sim p_\theta$$로 Monte Carlo 근사해 $$\nabla_\theta f_\theta(x_{\mathrm{train}})-\nabla_\theta f_\theta(x_{\mathrm{sample}})$$ 방향으로 학습한다. 남는 문제는 model에서 어떻게 sample을 얻는가다. 강의는 Metropolis-Hastings MCMC와 Langevin MCMC를 소개한다. MCMC는 현재 sample을 조금 perturb하고 더 likely하면 받아들이며, 덜 likely해도 일정 확률로 받아들여 탐색성을 유지한다. Langevin 방식은 $$\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)$$를 이용해 더 informed proposal을 만들지만, high-dimensional space에서는 여전히 많은 step이 필요하다.

### 핵심 수식 유도: partition function gradient

> **Source mapping:** Official Lecture 11 PDF p. 23의 log-likelihood gradient 및 contrastive-divergence 근사에 대응한다.

$$Z(\theta)=\int e^{f_\theta(x)}dx$$가 유한하고 미분과 적분을 교환할 수 있다고 가정한다. EBM log-likelihood의 gradient는 다음 **정확한 등식**이다.

$$
\begin{aligned}
\nabla_\theta\log p_\theta(x)
&=\nabla_\theta f_\theta(x)-\nabla_\theta\log Z(\theta),\\
\nabla_\theta\log Z
&=\frac1Z\int e^{f_\theta(x')}\nabla_\theta f_\theta(x')dx'\\
&=\mathbb{E}_{x'\sim p_\theta}[\nabla_\theta f_\theta(x')].
\end{aligned}
$$

Positive phase는 data의 score를 올리고 negative phase는 model이 높게 평가한 영역을 내린다. 표준화 좌표와 고정 reference measure를 쓰는 ML 표기에서는 $$f_\theta$$와 log-density 차이를 무차원으로 취급한다. Continuous density 자체는 좌표 부피의 역단위를 가질 수 있다. Contrastive divergence는 마지막 expectation을 짧은 MCMC chain으로 바꾸는 **편향된 근사**이므로 chain이 mixing하지 않으면 MLE gradient가 아니다.

### MH acceptance와 Langevin 정상성 (작성자 보충; 강의 sampling 식의 조건 명시)

> **Source mapping:** Official Lecture 11 PDF p. 24의 symmetric random-walk MCMC acceptance와 p. 25의 unadjusted Langevin update에 대응한다. 일반 proposal ratio, Fokker--Planck 정상성, MALA 설명은 작성자 보충이다.

현재 상태 $$x$$에서 proposal $$x'\sim q(x'\mid x)$$를 뽑는 Metropolis--Hastings의 **정확한 acceptance probability**는

$$
\alpha(x,x')=\min\left\{1,
\frac{p_\theta(x')q(x\mid x')}{p_\theta(x)q(x'\mid x)}
\right\}
=\min\left\{1,
e^{f_\theta(x')-f_\theta(x)}
\frac{q(x\mid x')}{q(x'\mid x)}
\right\}.
$$

대칭 proposal에서만 $$q$$ 비율이 사라져 강의의 $$\min\{1,e^{f_\theta(x')-f_\theta(x)}\}$$가 된다. 이 선택은 $$p_\theta(x)T(x,x')=p_\theta(x')T(x',x)$$라는 detailed balance를 만족시키므로 $$p_\theta$$가 stationary distribution이다. 다만 stationary라는 사실은 임의의 초기값에서 유한 시간 안에 잘 섞인다는 뜻이 아니다. Irreducibility와 aperiodicity가 깨지거나 mode 사이 energy barrier가 크면 chain은 한 mode에 머물 수 있다.

Continuous state의 overdamped Langevin SDE는

$$
dX_t=\nabla_x\log p_\theta(X_t)dt+\sqrt2\,dW_t
=\nabla_x f_\theta(X_t)dt+\sqrt2\,dW_t.
$$

밀도 $$\rho_t$$의 Fokker--Planck equation은

$$
\partial_t\rho_t
=-\nabla\!\cdot(\rho_t\nabla\log p_\theta)+\Delta\rho_t.
$$

여기에 $$\rho_t=p_\theta$$를 넣으면 두 항이 $$-\Delta p_\theta+\Delta p_\theta=0$$으로 상쇄되므로 $$p_\theta$$가 stationary라는 것을 확인할 수 있다. 이는 매끄럽고 양의 density, 적절한 boundary decay와 non-explosion을 가정한 **정확한 연속시간 결과**다. Euler--Maruyama update

$$
X_{k+1}=X_k+\epsilon\nabla_x\log p_\theta(X_k)+\sqrt{2\epsilon}\,Z_k
$$

는 unadjusted Langevin algorithm이라는 **수치 근사**이며, 고정된 유한 $$\epsilon$$에서는 일반적으로 정확한 $$p_\theta$$를 stationary distribution으로 갖지 않는다. MH correction을 붙인 MALA는 이 이산화 bias를 교정할 수 있지만 mixing 자체를 보장하지는 않는다.

$$x$$의 단위가 $$U$$이면 score는 $$U^{-1}$$이고 이 SDE convention에서 $$t$$와 $$\epsilon$$은 $$U^2$$, Brownian increment는 $$U$$다. 실제 ML에서는 좌표를 표준화해 모두 무차원으로 취급한다. Step size가 크면 discretization bias나 발산이 생기고, 너무 작으면 이동이 느리며, ill-conditioned density와 분리된 mode에서는 매우 긴 chain도 mixing하지 못할 수 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Partition function | unnormalized probability 전체를 합하거나 적분한 값 $$Z(\theta)$$. EBM을 normalized probability로 만들지만 계산이 어렵다. |
| Energy function | $$-f_\theta(x)$$로 해석되는 score. 낮은 energy 또는 높은 $$f_\theta(x)$$가 높은 probability에 대응한다. |
| Relative comparison | $$Z(\theta)$$가 cancel되는 ratio나 argmax 문제. EBM이 practical task에 쓰일 수 있는 핵심 이유다. |
| Product of Experts | 여러 expert density를 곱해 모두가 동의하는 영역을 강조하는 ensemble 방식이다. |
| RBM | visible-hidden bipartite 구조를 가진 energy-based latent variable model이다. |
| Contrastive divergence | data sample을 올리고 model sample을 내리는 방식으로 log-likelihood gradient를 근사한다. |
| Langevin MCMC | score direction과 Gaussian noise를 섞어 EBM sample을 점진적으로 만드는 MCMC 계열 방법이다. |

## 학습 포인트

- EBM의 flexibility는 $$f_\theta$$ 선택의 자유에서 오지만, 그 자유는 $$Z(\theta)$$ 계산 불가능성과 맞교환된다.
- Softmax도 작은 finite label space에서는 EBM처럼 볼 수 있다. 차이는 label 수가 작아 partition function을 정확히 계산할 수 있다는 점이다.
- Partition function을 모르면 likelihood 값은 알 수 없지만, 두 point의 상대 likelihood와 $$x$$에 대한 score gradient는 계산할 수 있다.
- Product of Experts는 mixture보다 더 강한 intersection effect를 만들며, 개념 조합이나 제약 결합에 적합한 해석을 준다.
- Contrastive divergence는 maximum likelihood gradient의 model expectation을 sample로 대체한다. 따라서 좋은 sampling procedure가 학습 품질을 좌우한다.
- MCMC는 이론적으로 target distribution으로 수렴할 수 있지만, 고차원에서는 convergence가 느려 학습 inner loop에 넣기 어렵다.

## 마지막 핵심 정리

Lecture 11의 핵심은 EBM이 "임의의 neural network score를 확률분포로 만들 수 있지만, partition function 때문에 likelihood와 sampling이 어려워진다"는 tradeoff를 이해하는 것이다. EBM은 절대 확률 대신 상대 비교, score gradient, contrastive learning을 이용할 때 실용성이 생기며, 다음 강의의 score matching과 diffusion model 논의로 이어진다.

## Study Guide

1. Autoregressive, flow, VAE, GAN, EBM을 likelihood 계산 가능성, sampling 방식, architecture 제약으로 비교한다.
2. $$Z(\theta)$$가 likelihood에는 필요하지만 ratio에는 cancel되는 이유를 수식으로 직접 확인한다.
3. Product of Experts와 mixture model을 AND/OR 관점으로 비교해 본다.
4. RBM에서 $$Z(W,b,c)$$ 계산이 $$2^n\cdot 2^m$$ 규모가 되는 이유를 visible-hidden binary configuration 수로 설명할 수 있어야 한다.
5. Contrastive divergence가 "positive sample 대 negative sample" 학습처럼 보이지만 실제로는 log partition gradient의 Monte Carlo approximation이라는 점을 연결한다.

## 복습 질문

<details markdown="block">
<summary>1. EBM에서 non-negativity보다 normalization이 더 어려운 이유는 무엇인가?</summary>

답변: non-negativity는 exponential, square, absolute value 같은 출력 변환으로 쉽게 만족시킬 수 있다. 그러나 normalization은 모든 가능한 $$x$$에 대한 합이나 적분이 1이 되도록 해야 하며, arbitrary neural network와 high-dimensional input에서는 이 전체 공간 적분이 닫힌형태로 계산되지 않고 차원에 따라 폭발한다.

</details>

<details markdown="block">
<summary>2. EBM에서 두 sample의 probability ratio는 왜 계산 가능한가?</summary>

답변: $$p_\theta(x)=\exp(f_\theta(x))/Z(\theta)$$이므로 $$p_\theta(x)/p_\theta(x')$$를 만들면 같은 $$Z(\theta)$$가 분자와 분모에서 cancel된다. 따라서 절대 likelihood는 몰라도 어느 쪽이 더 likely한지는 $$f_\theta(x)-f_\theta(x')$$로 비교할 수 있다.

</details>

<details markdown="block">
<summary>3. Product of Experts가 mixture model과 다른 직관은 무엇인가?</summary>

답변: mixture는 하나의 component가 높은 probability를 주면 전체 probability도 어느 정도 높아지는 OR 성격을 갖는다. Product of Experts는 모든 expert가 동시에 높은 값을 줘야 product가 커지므로 AND 성격을 갖고, 여러 조건의 intersection을 강조한다.

</details>

<details markdown="block">
<summary>4. RBM이 "restricted"라고 불리는 이유는 무엇인가?</summary>

답변: visible variable끼리의 interaction과 hidden variable끼리의 interaction이 없고, visible-hidden 사이의 interaction만 $$W$$로 표현하기 때문이다. 즉 energy에는 $$x_i z_j$$ 항은 있지만 $$x_i x_j$$나 $$z_i z_j$$ 항은 없다.

</details>

<details markdown="block">
<summary>5. Contrastive divergence는 maximum likelihood gradient를 어떻게 근사하는가?</summary>

답변: maximum likelihood gradient에는 data point의 score를 올리는 $$\nabla_\theta f_\theta(x_{\mathrm{train}})$$ 항과 model distribution 전체에 대한 expectation을 내리는 항이 있다. Contrastive divergence는 이 expectation을 model sample 하나 또는 여러 개로 근사해 data sample은 올리고 model sample은 내리는 update를 만든다.

</details>

<details markdown="block">
<summary>6. Langevin MCMC가 단순 random perturbation보다 informed proposal인 이유는 무엇인가?</summary>

답변: 단순 perturbation은 무작위로 주변을 탐색하지만 Langevin MCMC는 $$\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)$$ 방향을 사용해 probability가 증가할 가능성이 큰 방향으로 이동한다. 여기에 noise를 추가해 local optimum에 갇히지 않고 sampling distribution을 탐색한다.

</details>

## PDF

- [Official Lecture 11 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture11.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 11 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture11.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 11 Video](https://www.youtube.com/watch?v=m61KiAMCJ5Q){:target="_blank" rel="noopener"}
