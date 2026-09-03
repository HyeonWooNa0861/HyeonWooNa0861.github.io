---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 20:25:45 +0900
title: "Stanford CS236 Lecture 6: Variational Autoencoders II"
course: "CS236"
topic: "Variational Autoencoders"
order: 6
major_topic: "Deep Generative Models"
keywords:
  - "ELBO Optimization"
  - "Variational Inference"
  - "Reparameterization Trick"
  - "Amortized Inference"
  - "Encoder Decoder"
---

# Stanford CS236 Lecture 6: Variational Autoencoders II

Source: [Stanford CS236 Lecture 6](https://www.youtube.com/watch?v=8cO61e_8oPY){:target="_blank" rel="noopener"}

Source PDF: [cs236_lecture6.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture6.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 6은 전 강의에서 만든 ELBO를 실제 VAE 학습 알고리즘으로 바꾸는 강의다. VAE는 $$z\sim N(0,I)$$를 먼저 뽑고, decoder network가 $$p_{\theta}(x\mid z)$$의 mean과 covariance를 만든다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | ELBO 복습 | $$q(z)$$가 posterior에 가까울수록 lower bound가 왜 tight해지는가? |
| 2 | Variational parameters | 데이터마다 다른 $$q(z;\phi_i)$$를 두면 무엇을 최적화하게 되는가? |
| 3 | Stochastic variational inference | ELBO expectation과 gradient를 Monte Carlo로 어떻게 계산하는가? |
| 4 | $$\theta$$ gradient와 $$\phi$$ gradient | Decoder parameter gradient는 쉽지만 variational parameter gradient가 어려운 이유는 무엇인가? |
| 5 | Reparameterization trick | $$z=\mu+\sigma\epsilon$$, $$\epsilon\sim N(0,I)$$로 쓰면 왜 backpropagation이 가능해지는가? |
| 6 | Amortized inference | 데이터마다 $$\phi_i$$를 최적화하지 않고 encoder network가 posterior parameter를 예측하게 하는 이유는 무엇인가? |
| 7 | Autoencoder perspective | VAE objective는 reconstruction term과 prior regularization으로 어떻게 해석되는가? |
| 8 | Research directions | Encoder, decoder, objective를 더 강하게 만드는 대표 방향은 무엇인가? |

### 원문 26페이지 전수 대조

| 공식 PDF 범위 | 대조한 내용 | 수식·증명 판단 |
|---|---|---|
| pp. 1–10 | VAE/ELBO recap, KL gap | pp. 5–8의 ELBO 항등식과 tightness를 아래에서 유도 |
| pp. 11–16 | variational parameters, SVI, Monte Carlo gradient, reparameterization | pp. 13–16의 estimator와 pathwise gradient를 아래에서 대조 |
| pp. 17–21 | amortized inference, reconstruction-minus-KL | p. 20의 목적함수와 encoder 해석을 아래에서 대조 |
| pp. 22–26 | summary와 research directions | 개념·문헌 안내 중심이며 새로운 증명 대상 없음 |

> 위 범위는 공식 PDF 26페이지 전체를 page-scoped text와 page image로 대조한 결과다. Finite-$$K$$ unbiasedness와 variance rate는 작성자 보충임을 해당 절 제목에 명시했다.

### 중요 수식의 페이지-본문 대응표

| 공식 PDF 위치 | 원문의 식·표현 | 이 글의 대응 위치 | 경계 |
|---|---|---|---|
| p. 3 | $$z\sim\mathcal N(0,I)$$, $$p_\theta(x\mid z)=\mathcal N(\mu_\theta(z),\Sigma_\theta(z))$$ | `핵심 내용`의 VAE 생성 과정 | 원문 모델 정의를 notation에 맞춰 재서술 |
| pp. 5–6 | ELBO와 KL non-negativity | `핵심 내용`, `핵심 수식 유도`의 ELBO 분해 | 원문 식을 joint factorization으로 전개한 단계는 작성자 보충 |
| p. 8 | $$\log p_\theta(x)=\mathcal L+D_{\mathrm{KL}}$$ | `핵심 내용`의 ELBO gap | 원문의 정확한 항등식 |
| pp. 10, 12 | 데이터셋 ELBO와 SVI update | `핵심 내용`의 데이터별 $$\phi_i$$와 coordinate update | 원문 학습 절차를 문장으로 재구성 |
| pp. 13–14 | $$K$$-sample Monte Carlo estimate와 $$\nabla_\theta,\nabla_\phi$$ | `Finite-K Monte Carlo gradient estimators` | finite-$$K$$ unbiasedness와 $$K^{-1/2}$$ error rate는 작성자 보충 |
| pp. 15–16 | $$\epsilon\sim\mathcal N(0,I)$$, $$z=\mu+\sigma\epsilon$$ | `핵심 수식 유도`, `Finite-K Monte Carlo gradient estimators` | pathwise total derivative의 두 경로를 펼친 식은 작성자 보충 |
| pp. 17–19 | $$x_i\mapsto\phi_i$$ amortized map과 amortized ELBO | `핵심 내용`의 amortized inference | 원문 개념과 목적함수의 재서술 |
| p. 20 | reconstruction-minus-KL objective | `핵심 내용`, `핵심 수식 유도` | joint factorization에서 나오는 정확한 등식 |

공식 PDF와 강의 영상은 공개 원문 링크이며, 아래의 local transfer source는 페이지 대조를 위한 로컬 audit copy다. 이 글은 슬라이드 문장을 연속 복제하지 않고 모델 정의와 목적함수를 학습용으로 재구성했다. 특히 estimator의 유한 표본 성질, total-derivative 전개, 적용 실패 조건은 슬라이드 원문이 아니라 **작성자 보충**이므로 원문의 주장으로 읽으면 안 된다.

## 핵심 내용

Lecture 6은 전 강의에서 만든 ELBO를 실제 VAE 학습 알고리즘으로 바꾸는 강의다. VAE는 $$z\sim N(0,I)$$를 먼저 뽑고, decoder network가 $$p_{\theta}(x\mid z)$$의 mean과 covariance를 만든다. Marginal $$p_{\theta}(x)$$는 유연하지만 직접 계산이 어렵다. 그래서 임의의 tractable distribution $$q(z;\phi)$$에 대해

$$
\log p_{\theta}(x)
\ge
L(x;\theta,\phi)
=
E_{q(z;\phi)}[\log p_{\theta}(x,z)-\log q(z;\phi)]
$$

를 최적화한다. 이 bound는

$$
\log p_{\theta}(x)
=
L(x;\theta,\phi)
+
D_{\mathrm{KL}}(q(z;\phi)\Vert p_{\theta}(z\mid x))
$$

로 볼 수 있으므로, $$q$$가 true posterior에 가까울수록 ELBO와 log-likelihood의 gap이 작다.

가장 직접적인 variational learning은 데이터 $$x_i$$마다 별도의 variational parameter $$\phi_i$$를 두는 방식이다. 각 데이터는 서로 다른 posterior $$p_{\theta}(z\mid x_i)$$를 가지므로, 이론적으로는 $$\phi_i$$도 따로 있어야 tight한 lower bound를 만들 수 있다. 학습은 $$x_i$$를 하나 뽑고, 먼저 $$\phi_i$$를 조정해 $$L(x_i;\theta,\phi_i)$$를 크게 만든 뒤, 그 bound에 대해 decoder parameter $$\theta$$를 업데이트하는 coordinate-ascent 형태로 생각할 수 있다. 하지만 이 방식은 데이터가 많을 때 매 sample마다 내부 최적화를 해야 하므로 느리고, 새로운 test point가 오면 다시 $$\phi$$를 찾아야 한다.

ELBO 안에는 expectation이 있으므로 일반적으로 Monte Carlo estimate가 필요하다.

$$
L(x;\theta,\phi)
=
E_{q(z;\phi)}[\log p_{\theta}(x,z)-\log q(z;\phi)].
$$

$$\theta$$에 대한 gradient는 상대적으로 쉽다. $$q$$가 $$\theta$$에 의존하지 않는다면 sample $$z_k\sim q(z;\phi)$$를 뽑은 뒤 $$\nabla_{\theta}\log p_{\theta}(x,z_k)$$를 평균하면 된다. 완전히 관측된 $$(x,z)$$에 대한 log probability gradient와 같은 모양이므로 backpropagation으로 처리할 수 있다.

어려운 부분은 $$\phi$$ gradient다. $$\phi$$는 expectation의 integrand뿐 아니라 sample을 뽑는 distribution 자체에도 들어간다. 즉 $$\phi$$를 조금 바꾸면 $$q(z;\phi)$$에서 나온 sample의 위치도 바뀐다. 이 의존성을 일반적으로 미분하려면 REINFORCE 같은 score-function estimator를 쓸 수 있지만 variance가 클 수 있다. VAE에서 Gaussian latent variable을 쓰면 더 낮은 variance의 reparameterization trick을 사용할 수 있다.

Gaussian $$q(z;\phi)=N(\mu,\sigma^2I)$$에서 직접 $$z$$를 뽑는 대신,

$$
\epsilon\sim N(0,I),\qquad z=\mu+\sigma\epsilon
$$

로 쓴다. 이제 randomness는 $$\epsilon$$에 있고, $$\epsilon$$의 분포는 $$\phi=(\mu,\sigma)$$에 의존하지 않는다. 따라서

$$
E_{z\sim q(z;\phi)}[r(z,\phi)]
=
E_{\epsilon\sim N(0,I)}[r(\mu+\sigma\epsilon,\phi)]
$$

처럼 바꾸고, 오른쪽은 deterministic computation graph를 통해 $$\mu$$, $$\sigma$$, decoder parameter로 backpropagation할 수 있다. 이 방법은 continuous latent variable과 reparameterizable distribution에서 잘 작동하지만, categorical $$z$$처럼 discrete variable에는 직접 적용되지 않는다.

마지막 조각은 amortized inference다. 데이터마다 $$\phi_i$$를 따로 두면 정확한 bound를 얻기에는 좋지만 확장성이 떨어진다. VAE는 encoder network $$f_{\phi}(x)$$를 학습해 $$x$$를 입력받고 $$q_{\phi}(z\mid x)$$의 parameter, 예를 들어 mean과 standard deviation을 바로 출력하게 한다. 이렇게 하면 새 데이터가 와도 별도의 최적화 없이 한 번의 feed-forward pass로 approximate posterior를 얻는다. 학습에서는 decoder $$\theta$$와 encoder $$\phi$$를 동시에 업데이트해 ELBO를 최대화한다.

Autoencoder 관점에서는 ELBO가 더 직관적으로 보인다.

$$
L(x;\theta,\phi)
=
E_{q_{\phi}(z\mid x)}[\log p_{\theta}(x\mid z)]
-
D_{\mathrm{KL}}(q_{\phi}(z\mid x)\Vert p(z)).
$$

첫 항은 encoder가 만든 $$z$$로 decoder가 $$x$$를 잘 복원하도록 만드는 reconstruction term이다. 두 번째 항은 encoder가 만든 latent distribution이 prior $$p(z)$$와 너무 멀어지지 않게 하는 regularization이다. 이 regularization 덕분에 generation 단계에서 encoder 없이 $$z\sim p(z)$$를 뽑아도 decoder가 plausible한 $$x$$를 만들 수 있다.

### 핵심 수식 유도: ELBO 분해와 reparameterization

> **근거 위치:** 공식 Lecture 6 PDF p. 8의 ELBO gap, pp. 15–16의 reparameterization과 Monte Carlo gradient, p. 20의 reconstruction-minus-KL 형태. Page-scoped PDF text extraction으로 확인했다.

먼저 joint factorization $$p_\theta(x,z)=p(z)p_\theta(x\mid z)$$을 ELBO에 대입하면 다음 **정확한 항등식**을 얻는다.

$$
\begin{aligned}
\mathcal{L}(x)
&=\mathbb{E}_{q_\phi(z\mid x)}[\log p_\theta(x,z)-\log q_\phi(z\mid x)]\\
&=\mathbb{E}_{q_\phi}[\log p_\theta(x\mid z)]
-D_{\mathrm{KL}}(q_\phi(z\mid x)\Vert p(z)).
\end{aligned}
$$

Gaussian encoder가 $$q_\phi(z\mid x)=\mathcal{N}(\mu_\phi(x),\operatorname{diag}(\sigma_\phi^2(x)))$$이고 $$\sigma_i>0$$일 때,

$$
\epsilon\sim\mathcal{N}(0,I),\qquad
z=\mu_\phi(x)+\sigma_\phi(x)\odot\epsilon
$$

은 $$z$$의 분포를 바꾸지 않는 **reparameterization 항등식**이다. Randomness가 $$\epsilon$$으로 분리되므로, decoder가 미분 가능하고 기대값과 미분을 교환할 regularity가 있으면 $$\nabla_\phi\mathbb{E}_\epsilon[f(g_\phi(\epsilon))]$$를 pathwise backpropagation으로 추정할 수 있다. $$\epsilon$$은 standard normal에서 뽑은 무차원 noise이고, $$\mu,\sigma,z$$는 서로 같은 latent-coordinate 단위를 가진다. Latent coordinate 자체를 무차원으로 정의했다면 이 셋도 무차원이다. $$\phi,\theta$$는 model parameter이며 단위는 parameterization에 따라 정해진다. Discrete $$z$$, $$\sigma_i=0$$, non-differentiable decoder에서는 이 유도가 그대로 적용되지 않는다.

### Finite-$$K$$ Monte Carlo gradient estimators (작성자 보충; 강의 슬라이드 13--16)

$$r_{\theta,\phi}(z)=\log p_\theta(x,z)-\log q_\phi(z\mid x)$$라고 하자. 먼저 $$q_\phi$$가 $$\theta$$에 의존하지 않고 derivative와 expectation을 교환할 수 있으면

$$
\nabla_\theta\mathcal L(x;\theta,\phi)
=\mathbb E_{z\sim q_\phi}\left[\nabla_\theta\log p_\theta(x,z)\right]
$$

이고, reparameterized samples $$z^{(k)}=g_\phi(\epsilon^{(k)},x)$$, $$\epsilon^{(k)}\overset{\mathrm{iid}}\sim p(\epsilon)$$에 대한 estimator는

$$
\widehat g_\theta^{(K)}
=\frac1K\sum_{k=1}^{K}\nabla_\theta\log p_\theta\!\left(x,g_\phi(\epsilon^{(k)},x)\right).
$$

Gaussian case에서 $$p(\epsilon)=\mathcal N(0,I)$$를 쓰면 encoder gradient의 pathwise estimator는

$$
\widehat g_\phi^{(K)}
=\frac1K\sum_{k=1}^{K}
\nabla_\phi r_{\theta,\phi}
\!\left(g_\phi(\epsilon^{(k)},x)\right).
$$

마지막 total derivative는 $$g_\phi$$를 통한 **implicit path**와 $$-\log q_\phi$$가 갖는 **explicit $$\phi$$ dependence**를 모두 포함한다. 이를 펼치면

$$
\nabla_\phi r_{\theta,\phi}(g_\phi(\epsilon,x))
=\left.\nabla_z r_{\theta,\phi}(z)\right|_{z=g_\phi(\epsilon,x)}
\nabla_\phi g_\phi(\epsilon,x)
+\left.\partial_\phi r_{\theta,\phi}(z)\right|_{z=g_\phi(\epsilon,x)}.
$$

Base noise distribution이 $$\phi$$와 무관하고, $$g_\phi$$와 $$r_{\theta,\phi}$$가 거의 모든 $$\epsilon$$에서 미분 가능하며, gradient를 지배하는 적분가능 함수가 존재하면 두 estimator는 각각의 population gradient에 대해 **unbiased**다. 각 per-sample gradient의 second moment가 유한하면 covariance는 $$1/K$$, componentwise standard error는 $$O(K^{-1/2})$$로 줄어든다. 이는 확률적 오차율이지 개별 finite-$$K$$ draw에 대한 deterministic bound가 아니다. Correlated samples에서는 유효 표본 수가 $$K$$보다 작고, heavy-tailed gradient에서는 이 분산식과 central-limit approximation이 실패할 수 있다.

$$K$$와 sample index는 무차원이다. Gradient의 단위는 dimensionless ELBO를 해당 parameter 단위로 나눈 값이며, $$z,\mu,\sigma$$의 좌표 단위는 서로 같아야 한다. Discrete latent variable, parameter-dependent base noise, non-differentiable transform, support가 $$\phi$$에 따라 불연속적으로 바뀌는 distribution에서는 이 pathwise 유도를 그대로 사용할 수 없다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Variational Inference | 계산 불가능한 posterior $$p_{\theta}(z\mid x)$$를 tractable $$q(z;\phi)$$로 근사하는 방법이다. |
| ELBO Gap | $$\log p_{\theta}(x)$$와 ELBO의 차이이며, $$D_{\mathrm{KL}}(q(z;\phi)\Vert p_{\theta}(z\mid x))$$로 표현된다. |
| Stochastic Variational Inference | 데이터와 latent sample을 일부만 뽑아 ELBO와 gradient를 Monte Carlo로 추정해 업데이트한다. |
| Reparameterization Trick | $$z$$ 샘플링을 parameter-free noise $$\epsilon$$과 differentiable transform으로 분리해 $$\phi$$ gradient를 낮은 variance로 계산한다. |
| Amortized Inference | 데이터마다 posterior parameter를 최적화하지 않고 encoder network가 $$q_{\phi}(z\mid x)$$를 바로 출력하게 하는 방식이다. |
| Encoder | 관측 $$x$$를 approximate posterior parameter로 보내는 inference network다. |
| Decoder | Latent $$z$$를 $$p_{\theta}(x\mid z)$$의 parameter로 보내는 generative network다. |

## 학습 포인트

- ELBO는 likelihood 자체가 아니라 likelihood의 lower bound이므로, bound tightness와 optimization을 함께 봐야 한다.
- $$\phi_i$$를 데이터마다 따로 최적화하면 유연하지만, 대규모 데이터와 test-time inference에는 비싸다.
- Reparameterization trick은 "sampling node"를 미분 가능한 deterministic transform으로 바꾸는 기법이다.
- VAE의 encoder는 단순한 feature extractor가 아니라 variational posterior $$q_{\phi}(z\mid x)$$를 parameterize한다.
- Decoder가 너무 강하면 latent code를 무시할 수 있고, tighter ELBO가 항상 더 좋은 sample이나 informative representation을 뜻하지는 않는다.
- 이후 연구 방향은 더 좋은 encoder posterior family, 더 강한 decoder/prior, KL 이외 objective로 확장된다.

## 마지막 핵심 정리

Lecture 6의 핵심은 VAE가 "ELBO를 최적화하는 encoder-decoder generative model"이라는 점이다. Encoder는 $$x$$에서 $$z$$의 approximate posterior를 만들고, decoder는 $$z$$에서 $$x$$를 생성한다. Reparameterization trick은 이 구조를 end-to-end로 학습 가능하게 만들고, amortized inference는 데이터마다 posterior 최적화를 반복하지 않게 해 VAE를 실용적인 deep generative model로 만든다.

## Study Guide

1. $$\log p_{\theta}(x)=\mathrm{ELBO}+\mathrm{KL}$$ 관계를 먼저 외우지 말고, "posterior approximation gap"으로 이해한다.
2. $$\theta$$ gradient와 $$\phi$$ gradient가 왜 난이도가 다른지 sample distribution 의존성으로 설명해 본다.
3. $$z=\mu+\sigma\epsilon$$ 식에서 randomness와 trainable parameter가 분리되는 위치를 표시한다.
4. Amortized inference의 장점과 손실을 함께 정리한다. 빠르고 일반화 가능하지만, 데이터별 자유로운 $$\phi_i$$보다 bound가 느슨할 수 있다.
5. Autoencoder objective와 VAE objective를 비교해 reconstruction term과 KL regularization의 역할을 구분한다.

## 복습 질문

<details markdown="block">
<summary>1. ELBO가 tight해지는 조건은 무엇인가?</summary>

답변: $$q(z;\phi)$$가 true posterior $$p_{\theta}(z\mid x)$$와 같아질 때다. 이때 $$D_{\mathrm{KL}}(q(z;\phi)\Vert p_{\theta}(z\mid x))=0$$이므로 ELBO와 $$\log p_{\theta}(x)$$가 같아진다.

</details>

<details markdown="block">
<summary markdown="span">2. $$\theta$$ gradient보다 $$\phi$$ gradient가 더 까다로운 이유는 무엇인가?</summary>

답변: $$\theta$$는 $$\log p_{\theta}(x,z)$$ 안에만 들어가지만, $$\phi$$는 $$q(z;\phi)$$의 sample distribution 자체를 바꾼다. 따라서 $$\phi$$ 변화가 어떤 $$z$$를 샘플하게 만드는지도 gradient에 반영해야 한다.

</details>

<details markdown="block">
<summary>3. Reparameterization trick은 무엇을 해결하는가?</summary>

답변: $$z\sim q(z;\phi)$$라는 parameter-dependent sampling을 $$\epsilon\sim N(0,I)$$, $$z=\mu+\sigma\epsilon$$라는 parameter-free noise와 differentiable transform으로 바꾼다. 그래서 Monte Carlo sample을 사용하면서도 $$\mu$$, $$\sigma$$, decoder parameter에 대해 backpropagation할 수 있다.

</details>

<details markdown="block">
<summary>4. Amortized inference가 필요한 이유는 무엇인가?</summary>

답변: 데이터마다 별도의 $$\phi_i$$를 최적화하면 training과 test-time inference가 매우 비싸다. Encoder network가 $$x$$에서 posterior parameter를 바로 예측하면 posterior inference 비용이 한 번의 forward pass로 amortized된다.

</details>

<details markdown="block">
<summary>5. VAE objective를 autoencoder 관점으로 보면 두 항은 각각 어떤 역할을 하는가?</summary>

답변: $$E_{q_{\phi}(z\mid x)}[\log p_{\theta}(x\mid z)]$$는 입력을 잘 reconstruct하도록 만드는 항이고, $$D_{\mathrm{KL}}(q_{\phi}(z\mid x)\Vert p(z))$$는 encoder가 만든 latent distribution이 prior와 너무 멀어지지 않게 하는 regularization이다.

</details>

<details markdown="block">
<summary>6. Tighter ELBO가 항상 더 좋은 VAE를 뜻하지 않는 이유는 무엇인가?</summary>

답변: Likelihood와 sample quality가 항상 일치하지 않고, 강력한 decoder는 latent code를 무시하면서도 좋은 reconstruction이나 bound를 만들 수 있다. 따라서 sample quality, latent informativeness, downstream usefulness는 별도로 봐야 한다.

</details>

## PDF

- [Official Lecture 6 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture6.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=8cO61e_8oPY){:target="_blank" rel="noopener"}
- [Official slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture6.pdf){:target="_blank" rel="noopener"}
- Local transfer source: `research_files/stanford-cs236-deep-generative-models-2023/slides/lecture06-variational-autoencoders-ii.pdf`
