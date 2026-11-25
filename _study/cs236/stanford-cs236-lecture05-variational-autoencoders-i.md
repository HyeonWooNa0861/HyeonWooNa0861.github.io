---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CS236 Lecture 5: Variational Autoencoders I"
course: "CS236"
topic: "Variational Autoencoders"
order: 5
major_topic: "Deep Generative Models"
keywords:
  - "Latent Variable Models"
  - "Mixture Models"
  - "Variational Autoencoder"
  - "Importance Sampling"
  - "ELBO"
---

# Stanford CS236 Lecture 5: Variational Autoencoders I

Source: [Stanford CS236 Lecture 5](https://www.youtube.com/watch?v=MAGBUh77bNg){:target="_blank" rel="noopener"}

Source PDF: [cs236_lecture5.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf){:target="_blank" rel="noopener"}

> **핵심:** 같은 숫자 3도 기울기와 굵기가 다릅니다. VAE는 이런 보이지 않는 생성 요인을 latent variable에 담고, 그 값을 바꾸어 서로 다른 이미지를 만드는 방법을 배웁니다.

같은 숫자 `3` 이미지도 굵기와 기울기가 다릅니다. 이처럼 관측값 $$x$$ 뒤의 숨은 요인을 $$z$$로 두면 생성 과정을 간결하게 설명할 수 있지만, 가능한 모든 $$z$$를 합산하거나 적분해 $$p_\theta(x)$$를 구하는 계산이 어렵습니다. VAE는 이 병목을 풀기 위해 실제 posterior를 대신할 분포 $$q_\phi(z\mid x)$$를 도입합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">학습 순서와 원문 대조 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Autoregressive model 복습 | Likelihood 계산은 쉽지만 순서 선택, sequential generation, feature learning 한계가 왜 남습니까? |
| 2 | Latent variable motivation | 관측된 $$x$$ 뒤에 있는 pose, style, digit identity 같은 숨은 요인을 $$z$$로 모델링하면 무엇이 좋아집니까? |
| 3 | Mixture of Gaussians | Categorical latent variable 하나로 여러 Gaussian component를 섞으면 왜 더 유연한 분포가 됩니까? |
| 4 | VAE model family | Continuous $$z\sim N(0,I)$$와 neural decoder $$p_{\theta}(x\mid z)$$가 어떻게 infinite mixture처럼 동작합니까? |
| 5 | Marginal likelihood 난점 | $$p_{\theta}(x)=\sum_z p_{\theta}(x,z)$$ 또는 $$\int p_{\theta}(x,z)dz$$가 왜 학습 병목이 됩니까? |
| 6 | Monte Carlo와 importance sampling | Uniform sampling은 왜 variance가 크고, $$q(z)$$로 중요한 completion을 더 자주 뽑아야 합니까? |
| 7 | ELBO 도입 | Jensen's inequality로 log marginal likelihood의 계산 가능한 lower bound를 어떻게 만듭니까? |

### 강의 자료 범위

| 공식 PDF 범위 | 대조한 내용 | 수식·증명 판단 |
|---|---|---|
| pp. 1–8 | autoregressive recap, latent variables, Gaussian example | p. 8의 Gaussian parameterization은 모델 정의; 별도 증명 대상 없음 |
| pp. 9–14 | graphical model, mixture of Gaussians, VAE family | p. 12의 mixture와 p. 13의 VAE density를 본문에 명시 |
| pp. 15–20 | marginalization, naive Monte Carlo, importance sampling | pp. 15–19의 evidence 식과 p. 20의 log bias를 아래에서 유도 |
| pp. 21–29 | Jensen, ELBO, KL gap, posterior approximation | pp. 21–25의 bound와 equality condition을 아래에서 유도; pp. 26–29는 해석·요약 |

> Delta-method 오차와 finite-variance 조건은 강의 자료의 식이 성립하는 범위를 설명하는 보충 해설입니다.

</details>

## 원본 그림 해설

### 잠재변수 그래프와 혼합 성분의 posterior

<figure>
  <a href="{{ "/assets/images/study/cs236/source-captures/lecture-05-source-05-excerpt.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs236/source-captures/lecture-05-source-05-excerpt.png" | relative_url }}" alt="CS236 Lecture 5, p. 5: 관측 이미지와 관측되지 않은 잠재요인의 그래프. 원본 발췌." loading="lazy"></a>
  <figcaption><a href="https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf#page=5" target="_blank" rel="noopener">Original p. 5</a> — 관측 이미지와 관측되지 않은 잠재요인의 그래프. 필요한 영역만 발췌했습니다. 이미지를 누르면 확대됩니다.</figcaption>
</figure>

[Lecture 5 PDF p. 5](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf#page=5){:target="_blank" rel="noopener"}

원본에서 채워진 원 $$x$$는 관측한 이미지이고 빈 원 $$z$$는 관측되지 않은 요인입니다. 오른쪽의 pose·eye color 같은 변수는 잠재요인이 관측 이미지에 영향을 주는 개념적 모델을 보여 줍니다. 실제 학습에서 각 latent 좌표가 이런 의미와 자동으로 일대일 대응한다는 보장은 없습니다. 생성은 $$p(x\mid z)$$, 이미지를 보고 요인을 추론하는 방향은 $$p(z\mid x)$$로 구분합니다.

<figure>
  <a href="{{ "/assets/images/study/cs236/source-captures/lecture-05-source-10-excerpt.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs236/source-captures/lecture-05-source-10-excerpt.png" | relative_url }}" alt="CS236 Lecture 5, p. 10: 세 Gaussian mixture 성분과 관측점의 분포. 원본 발췌." loading="lazy"></a>
  <figcaption><a href="https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf#page=10" target="_blank" rel="noopener">Original p. 10</a> — 세 Gaussian mixture 성분과 관측점의 분포. 필요한 영역만 발췌했습니다. 이미지를 누르면 확대됩니다.</figcaption>
</figure>

[PDF p.10](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf#page=10){:target="_blank" rel="noopener"}의 주황·초록·붉은 점 무리는 Gaussian mixture의 성분과 연결됩니다. 타원은 성분의 위치와 퍼짐을 읽는 단서이고, 성분이 겹치는 곳에서는 한 점의 소속을 확정하기보다 $$P(z=i\mid x)$$로 비교합니다. 이 posterior를 계산하는 문제가 뒤의 variational inference로 이어집니다.

## 핵심 내용

같은 숫자 3을 쓴 이미지도 글씨 굵기와 기울기가 다릅니다. VAE는 픽셀을 바로 외우는 대신, 이런 보이지 않는 생성 요인을 latent variable $$z$$에 담고 $$z$$에서 이미지를 만드는 방법을 배웁니다.

Lecture 5는 autoregressive model의 장단점을 정리한 뒤 latent variable model로 넘어갑니다. Autoregressive model은 chain rule 덕분에 likelihood 평가와 MLE 학습이 쉽습니다. 그러나 ordering을 정해야 하고, generation이 순차적이며, 데이터의 숨은 feature를 직접 얻는 구조는 아닙니다. 이미지 데이터처럼 pose, hair color, digit style 등 다양한 변동 요인이 섞인 경우, 관측된 pixel $$x$$만으로 모든 분포를 직접 모델링하기보다 숨은 변수 $$z$$를 도입하면 모델이 더 자연스러워집니다.

Latent variable model의 기본 생각은 joint distribution $$p(x,z)$$를 만들고, 우리가 보는 데이터 $$x$$는 $$z$$에 조건부로 생성되었다고 보는 것입니다. $$z$$가 잘 선택되면 $$p(x\mid z)$$는 $$p(x)$$보다 단순해질 수 있고, 반대로 $$p(z\mid x)$$를 추론하면 unlabeled data에서 representation을 얻을 수 있습니다. 다만 $$z$$가 실제로 "눈 색", "글씨체", "숫자 종류"처럼 사람이 해석 가능한 의미를 갖는다는 보장은 없습니다. 강의는 이 점을 unsupervised learning의 본질적 어려움으로 강조합니다.

가장 단순한 예시는 mixture of Gaussians입니다. 여기서는

$$
z\sim \mathrm{Categorical}(1,\ldots,K),\qquad
p(x\mid z=k)=N(\mu_k,\Sigma_k)
$$

로 둡니다. 먼저 component $$k$$를 뽑고, 그 component의 Gaussian에서 $$x$$를 샘플링합니다. 하나의 Gaussian으로는 Old Faithful geyser 데이터처럼 두 cluster가 있는 분포를 잘 표현하지 못하지만, 여러 Gaussian을 섞으면 각 component가 다른 평균과 공분산을 갖기 때문에 훨씬 유연한 marginal distribution $$p(x)=\sum_k p(z=k)p(x\mid z=k)$$을 만들 수 있습니다. Posterior $$p(z\mid x)$$는 각 데이터가 어느 component에서 왔는지에 대한 soft clustering 역할을 합니다.

VAE는 이 아이디어를 deep latent variable model로 확장합니다. 단순한 prior $$z\sim N(0,I)$$를 샘플링하고, neural network $$\mu_{\theta}(z)$$, $$\Sigma_{\theta}(z)$$가 $$p_{\theta}(x\mid z)=N(\mu_{\theta}(z),\Sigma_{\theta}(z))$$의 parameter를 만듭니다. Component index가 $$1,\ldots,K$$처럼 유한하지 않고 continuous $$z$$ 공간 전체를 움직이므로, VAE의 marginal $$p_{\theta}(x)$$는 infinite mixture of Gaussians처럼 생각할 수 있습니다. 복잡성은 Gaussian 자체가 아니라 $$z\mapsto(\mu_{\theta}(z),\Sigma_{\theta}(z))$$를 만드는 neural decoder에 들어갑니다.

문제는 학습입니다. $$z$$가 관측되지 않으면 likelihood는

$$
p_{\theta}(x)=\sum_z p_{\theta}(x,z)
\quad \text{or} \quad
p_{\theta}(x)=\int p_{\theta}(x,z)dz
$$

처럼 latent variable을 모두 합산 또는 적분해야 합니다. Binary latent feature가 30개만 있어도 $$2^{30}$$개의 조합을 봐야 하므로 직접 계산은 어렵습니다. Naive Monte Carlo로 $$z$$를 uniform하게 뽑으면 이론적으로는 unbiased estimate가 될 수 있지만, 대부분의 $$z$$가 관측 $$x$$와 맞지 않는 completion이어서 $$p_{\theta}(x,z)$$가 거의 0이 됩니다. 따라서 variance가 너무 커 실용적이지 않습니다.

Importance sampling은 임의의 proposal distribution $$q(z)$$를 도입해

$$
p_{\theta}(x)=E_{z\sim q(z)}
\left[
\frac{p_{\theta}(x,z)}{q(z)}
\right]
$$

로 씁니다. 좋은 $$q$$는 $$x$$를 잘 설명할 가능성이 높은 $$z$$, 즉 posterior $$p(z\mid x)$$에 가까운 completion을 자주 뽑아야 합니다. 하지만 학습 목적은 $$p_{\theta}(x)$$가 아니라 $$\log p_{\theta}(x)$$입니다. Log를 sample average 바깥에 두면 unbiasedness가 깨지고, Jensen's inequality를 적용하면 계산 가능한 lower bound가 나옵니다.

$$
\log p_{\theta}(x)
\ge
E_{z\sim q(z)}
\left[
\log \frac{p_{\theta}(x,z)}{q(z)}
\right].
$$

이 값이 Evidence Lower Bound, ELBO입니다. 전개하면 $$E_q[\log p_{\theta}(x,z)] + H(q)$$가 되며, $$q(z)=p_{\theta}(z\mid x)$$이면 bound는 정확히 $$\log p_{\theta}(x)$$와 같아집니다. Posterior가 계산 불가능할 때는 tractable family $$q(z;\phi)$$를 정하고, 이를 true posterior에 가깝게 맞추는 variational inference 문제가 됩니다.

<details markdown="block">
<summary markdown="span">Derivation: Finite-sample importance sampling and logarithmic bias</summary>

> **Source mapping:** Official Lecture 5 PDF p. 19의 finite-sample importance estimator와 unbiasedness, p. 20의 log-likelihood estimator와 expectation/log 불일치에 대응합니다. Finite-variance 조건과 delta-method 오차식은 작성자 보충입니다.

Weight를 $$w(z)=p_\theta(x,z)/q(z)$$로 두고 $$z^{(1)},\ldots,z^{(K)}\overset{\mathrm{iid}}\sim q$$를 뽑으면 evidence의 finite-sample estimator는

$$
\widehat p_K(x)
=\frac1K\sum_{k=1}^{K}w\!\left(z^{(k)}\right)
=\frac1K\sum_{k=1}^{K}\frac{p_\theta(x,z^{(k)})}{q(z^{(k)})}
$$

입니다. $$p_\theta(x,z)>0$$인 곳에서 $$q(z)>0$$이고 $$\mathbb E_q[\lvert w\rvert]<\infty$$이면

$$
\mathbb E_q[\widehat p_K(x)]
=\frac1K\sum_{k=1}^{K}\mathbb E_q[w(z^{(k)})]
=\int p_\theta(x,z)\,dz
=p_\theta(x).
$$

따라서 $$\widehat p_K$$는 $$p_\theta(x)$$의 **unbiased Monte Carlo estimator**입니다. 이 결론은 i.i.d. sampling과 support coverage에 의존합니다. 더 나아가 $$\operatorname{Var}_q(w)<\infty$$이면

$$
\operatorname{Var}(\widehat p_K)=\frac{\operatorname{Var}_q(w)}{K},
$$

즉 standard error는 $$K^{-1/2}$$ 비율로 감소합니다. $$q(z)=p_\theta(z\mid x)$$이면 $$w(z)=p_\theta(x)$$가 상수여서 variance가 0입니다. 반대로 $$q$$가 중요한 posterior 영역을 거의 방문하지 않거나 weight의 second moment가 무한하면 estimator는 형식상 unbiased여도 finite-$$K$$에서 매우 불안정합니다.

Training에 필요한 natural-log likelihood를 plug-in으로 추정하면

$$
\widehat\ell_K(x)=\log\widehat p_K(x)
$$

입니다. 이것은 sample을 고정한 계산값으로는 정확한 log 변환이지만, $$\widehat p_K>0$$ almost surely이고 log expectation이 존재할 때 $$\log$$가 concave이므로 **log-likelihood에 대한 unbiased estimator가 아닙니다**.

$$
\mathbb E[\widehat\ell_K(x)]
\le \log\mathbb E[\widehat p_K(x)]
=\log p_\theta(x).
$$

Weight가 양수이고 variance가 작을 때 second-order delta method는 bias와 variance를

$$
\mathbb E[\widehat\ell_K]-\log p_\theta(x)
\approx-\frac{\operatorname{Var}_q(w)}{2Kp_\theta(x)^2},
\qquad
\operatorname{Var}(\widehat\ell_K)
\approx\frac{\operatorname{Var}_q(w)}{Kp_\theta(x)^2}
$$

로 줍니다. 두 식은 finite-$$K$$ **근사**이며 exact identity가 아닙니다. 적절한 적분가능성과 $$p_\theta(x)>0$$ 아래에서 $$K\to\infty$$이면 law of large numbers와 continuity로 $$\widehat\ell_K\to\log p_\theta(x)$$가 되지만, finite $$K$$에서는 Jensen gap이 남습니다. 모든 sampled weight가 0이면 $$\log\widehat p_K=-\infty$$이고, heavy-tailed weight에서는 위 delta approximation도 실패할 수 있습니다. $$K$$와 sample index는 무차원입니다. Discrete probability mass에서는 weight와 evidence가 무차원입니다. Continuous $$z$$에서 numerator와 proposal density는 같은 latent reference measure를 사용해야 하며, $$w=p(x,z)/q(z)$$는 $$x$$에 대한 marginal density의 단위를 남깁니다. 따라서 continuous log-density의 수치는 고정된 $$x$$ reference measure와 unit convention 아래에서만 비교합니다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Constructing the ELBO with Jensen's inequality</summary>

> **근거 위치:** 공식 Lecture 5 PDF pp. 21–23의 Jensen/ELBO 전개와 p. 25의 $$\log p=\mathrm{ELBO}+\mathrm{KL}$$ 분해.

이는 **하한(bound)** 이며 등식은 특정 조건에서만 성립합니다. $$q(z\mid x)>0$$ whenever $$p_\theta(x,z)>0$$이고 관련 기대값이 유한하다고 가정합니다.

$$
\begin{aligned}
\log p_\theta(x)
&=\log\int q(z\mid x)\frac{p_\theta(x,z)}{q(z\mid x)}\,dz\\
&=\log\mathbb{E}_{q(z\mid x)}\left[\frac{p_\theta(x,z)}{q(z\mid x)}\right]\\
&\ge \mathbb{E}_{q(z\mid x)}\left[\log p_\theta(x,z)-\log q(z\mid x)\right]
=\mathcal{L}(x).
\end{aligned}
$$

마지막 부등식은 concave $$\log$$에 대한 Jensen 부등식입니다. 더 정확히는

$$
\log p_\theta(x)-\mathcal{L}(x)
=D_{\mathrm{KL}}\!\left(q(z\mid x)\Vert p_\theta(z\mid x)\right)\ge 0.
$$

따라서 $$q$$가 true posterior와 같을 때만 bound가 tight합니다. $$x$$는 관측값, $$z$$는 latent variable, $$q$$는 variational posterior, $$\theta$$는 generative parameter이며 모두 물리 단위가 없는 확률모형 기호입니다. Variational family가 posterior를 표현하지 못하면 inference gap이 남고, 높은 ELBO가 곧 좋은 perceptual sample을 보장하지도 않습니다.

</details>

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Latent Variable | 데이터에는 관측되지 않지만 $$x$$의 변동 요인을 설명하기 위해 모델에 넣는 hidden random variable입니다. |
| Mixture Model | 단순한 component distribution들을 latent variable로 섞어 복잡한 marginal distribution을 만듭니다. |
| VAE Decoder | $$z$$를 입력으로 받아 $$p_{\theta}(x\mid z)$$의 parameter를 출력하는 neural network입니다. |
| Marginal Likelihood | 관측 $$x$$의 probability. Latent $$z$$를 모두 합산 또는 적분해야 하므로 VAE에서는 계산이 어렵습니다. |
| Importance Sampling | $$q(z)$$에서 샘플을 뽑고 $$p_{\theta}(x,z)/q(z)$$로 보정해 expectation을 추정하는 방법입니다. |
| Jensen's Inequality | Concave log 때문에 $$\log E[f(z)]\ge E[\log f(z)]$$가 되어 ELBO를 만듭니다. |
| ELBO | Log evidence $$\log p_{\theta}(x)$$의 lower bound. Likelihood 대신 최적화 가능한 대리 목적함수입니다. |

## 학습 포인트

<details markdown="block">
<summary markdown="span">추가 학습 포인트 보기</summary>

- Latent variable은 모델을 유연하게 만들지만, posterior inference와 marginal likelihood 계산을 어렵게 만듭니다.
- Mixture of Gaussians는 VAE를 이해하기 위한 shallow prototype입니다.
- VAE는 finite mixture component를 continuous latent space로 바꾼 infinite mixture 관점으로 볼 수 있습니다.
- $$z$$가 사람이 이해 가능한 feature가 되는지는 MLE만으로 보장되지 않습니다.
- Uniform Monte Carlo는 대부분 의미 없는 completion을 뽑기 때문에 variance가 커집니다.
- ELBO는 "log-likelihood를 직접 못 계산하니 lower bound를 최적화한다"는 VAE 학습의 출발점입니다.

</details>

## 마지막 핵심 정리

Lecture 5의 핵심은 VAE를 "simple prior + neural conditional + hard posterior inference"로 이해하는 것입니다. Latent variable을 넣으면 $$p(x\mid z)$$는 단순해지고 $$p(x)$$는 유연해지지만, $$z$$를 보지 못하기 때문에 likelihood 계산이 어려워집니다. ELBO는 이 난점을 Jensen's inequality와 proposal distribution $$q$$로 우회하는 첫 번째 도구입니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 방법 보기</summary>

1. Autoregressive model과 latent variable model을 likelihood 계산, generation 속도, representation learning 관점에서 비교합니다.
2. Mixture of Gaussians에서 $$z$$, $$p(z)$$, $$p(x\mid z)$$, $$p(z\mid x)$$가 각각 무엇을 의미하는지 그림 없이 설명해 봅니다.
3. VAE가 "infinite mixture"처럼 보이는 이유를 finite mixture와 나란히 써 봅니다.
4. Naive Monte Carlo, importance sampling, ELBO가 차례로 등장하는 이유를 variance와 log-likelihood 관점으로 연결합니다.
5. $$q(z)$$가 true posterior에 가까울수록 ELBO가 tight해진다는 문장을 식으로 확인합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Latent variable model을 쓰면 어떤 장점이 생깁니까?</summary>

답변: 관측 데이터의 복잡한 변동을 숨은 요인 $$z$$로 나누어 $$p(x\mid z)$$를 더 단순하게 만들 수 있습니다. 또한 $$p(z\mid x)$$를 추론하면 clustering이나 representation learning처럼 unlabeled data에서 feature를 얻는 데 쓸 수 있습니다.

</details>

<details markdown="block">
<summary>2. Mixture of Gaussians가 하나의 Gaussian보다 유연한 이유는 무엇입니까?</summary>

답변: 각 component가 다른 평균과 공분산을 갖고, marginal $$p(x)$$가 이 component들의 weighted sum이 되기 때문입니다. 하나의 bell shape로는 표현하기 어려운 multi-modal density를 여러 component 조합으로 표현할 수 있습니다.

</details>

<details markdown="block">
<summary>3. VAE를 infinite mixture로 볼 수 있는 이유는 무엇입니까?</summary>

답변: Mixture of Gaussians에서는 $$z$$가 유한한 component index지만, VAE에서는 $$z$$가 continuous Gaussian prior에서 나옵니다. 각 $$z$$마다 decoder가 다른 Gaussian parameter를 만들기 때문에 연속적으로 많은 component를 섞는 것처럼 볼 수 있습니다.

</details>

<details markdown="block">
<summary>4. Naive Monte Carlo가 partially observed likelihood 계산에서 잘 작동하지 않는 이유는 무엇입니까?</summary>

답변: 대부분의 latent completion은 관측 $$x$$와 잘 맞지 않아 $$p_{\theta}(x,z)$$가 매우 작습니다. 드물게 중요한 $$z$$를 뽑아야 likelihood에 의미 있는 기여가 생기는데, uniform sampling은 그런 $$z$$를 거의 맞히지 못해 variance가 커집니다.

</details>

<details markdown="block">
<summary>5. ELBO가 lower bound가 되는 핵심 수학적 이유는 무엇입니까?</summary>

답변: $$\log$$가 concave function이므로 Jensen's inequality에 의해 $$\log E_q[f(z)]\ge E_q[\log f(z)]$$가 성립합니다. $$f(z)=p_{\theta}(x,z)/q(z)$$로 두면 오른쪽이 ELBO가 됩니다.

</details>

<details markdown="block">
<summary>6. ELBO가 true log-likelihood와 같아지는 조건은 무엇입니까?</summary>

답변: $$q(z)$$가 generative model의 true posterior $$p_{\theta}(z\mid x)$$와 같을 때입니다. 이 경우 Jensen bound가 tight해지고, $$\log p_{\theta}(x)=\mathrm{ELBO}$$가 됩니다.

</details>

## PDF

- [Official Lecture 5 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=MAGBUh77bNg){:target="_blank" rel="noopener"}
- [Official slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf){:target="_blank" rel="noopener"}
