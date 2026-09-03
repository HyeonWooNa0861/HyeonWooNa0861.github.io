---
layout: default
date: 2026-08-19 15:27:32 +0900
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

> **핵심:** Lecture 5는 autoregressive model의 장단점을 정리한 뒤 latent variable model로 넘어간다. Autoregressive model은 chain rule 덕분에 likelihood 평가와 MLE 학습이 쉽다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Autoregressive model 복습 | Likelihood 계산은 쉽지만 순서 선택, sequential generation, feature learning 한계가 왜 남는가? |
| 2 | Latent variable motivation | 관측된 \(x\) 뒤에 있는 pose, style, digit identity 같은 숨은 요인을 \(z\)로 모델링하면 무엇이 좋아지는가? |
| 3 | Mixture of Gaussians | Categorical latent variable 하나로 여러 Gaussian component를 섞으면 왜 더 유연한 분포가 되는가? |
| 4 | VAE model family | Continuous \(z\sim N(0,I)\)와 neural decoder \(p_{\theta}(x\mid z)\)가 어떻게 infinite mixture처럼 동작하는가? |
| 5 | Marginal likelihood 난점 | \(p_{\theta}(x)=\sum_z p_{\theta}(x,z)\) 또는 \(\int p_{\theta}(x,z)dz\)가 왜 학습 병목이 되는가? |
| 6 | Monte Carlo와 importance sampling | Uniform sampling은 왜 variance가 크고, \(q(z)\)로 중요한 completion을 더 자주 뽑아야 하는가? |
| 7 | ELBO 도입 | Jensen's inequality로 log marginal likelihood의 계산 가능한 lower bound를 어떻게 만드는가? |

## 핵심 내용

Lecture 5는 autoregressive model의 장단점을 정리한 뒤 latent variable model로 넘어간다. Autoregressive model은 chain rule 덕분에 likelihood 평가와 MLE 학습이 쉽다. 그러나 ordering을 정해야 하고, generation이 순차적이며, 데이터의 숨은 feature를 직접 얻는 구조는 아니다. 이미지 데이터처럼 pose, hair color, digit style 등 다양한 변동 요인이 섞인 경우, 관측된 pixel \(x\)만으로 모든 분포를 직접 모델링하기보다 숨은 변수 \(z\)를 도입하면 모델이 더 자연스러워진다.

Latent variable model의 기본 생각은 joint distribution \(p(x,z)\)를 만들고, 우리가 보는 데이터 \(x\)는 \(z\)에 조건부로 생성되었다고 보는 것이다. \(z\)가 잘 선택되면 \(p(x\mid z)\)는 \(p(x)\)보다 단순해질 수 있고, 반대로 \(p(z\mid x)\)를 추론하면 unlabeled data에서 representation을 얻을 수 있다. 다만 \(z\)가 실제로 "눈 색", "글씨체", "숫자 종류"처럼 사람이 해석 가능한 의미를 갖는다는 보장은 없다. 강의는 이 점을 unsupervised learning의 본질적 어려움으로 강조한다.

가장 단순한 예시는 mixture of Gaussians다. 여기서는

$$
z\sim \mathrm{Categorical}(1,\ldots,K),\qquad
p(x\mid z=k)=N(\mu_k,\Sigma_k)
$$

로 둔다. 먼저 component \(k\)를 뽑고, 그 component의 Gaussian에서 \(x\)를 샘플링한다. 하나의 Gaussian으로는 Old Faithful geyser 데이터처럼 두 cluster가 있는 분포를 잘 표현하지 못하지만, 여러 Gaussian을 섞으면 각 component가 다른 평균과 공분산을 갖기 때문에 훨씬 유연한 marginal distribution \(p(x)=\sum_k p(z=k)p(x\mid z=k)\)을 만들 수 있다. Posterior \(p(z\mid x)\)는 각 데이터가 어느 component에서 왔는지에 대한 soft clustering 역할을 한다.

VAE는 이 아이디어를 deep latent variable model로 확장한다. 단순한 prior \(z\sim N(0,I)\)를 샘플링하고, neural network \(\mu_{\theta}(z)\), \(\Sigma_{\theta}(z)\)가 \(p_{\theta}(x\mid z)=N(\mu_{\theta}(z),\Sigma_{\theta}(z))\)의 parameter를 만든다. Component index가 \(1,\ldots,K\)처럼 유한하지 않고 continuous \(z\) 공간 전체를 움직이므로, VAE의 marginal \(p_{\theta}(x)\)는 infinite mixture of Gaussians처럼 생각할 수 있다. 복잡성은 Gaussian 자체가 아니라 \(z\mapsto(\mu_{\theta}(z),\Sigma_{\theta}(z))\)를 만드는 neural decoder에 들어간다.

문제는 학습이다. \(z\)가 관측되지 않으면 likelihood는

$$
p_{\theta}(x)=\sum_z p_{\theta}(x,z)
\quad \text{or} \quad
p_{\theta}(x)=\int p_{\theta}(x,z)dz
$$

처럼 latent variable을 모두 합산 또는 적분해야 한다. Binary latent feature가 30개만 있어도 \(2^{30}\)개의 조합을 봐야 하므로 직접 계산은 어렵다. Naive Monte Carlo로 \(z\)를 uniform하게 뽑으면 이론적으로는 unbiased estimate가 될 수 있지만, 대부분의 \(z\)가 관측 \(x\)와 맞지 않는 completion이어서 \(p_{\theta}(x,z)\)가 거의 0이 된다. 따라서 variance가 너무 커 실용적이지 않다.

Importance sampling은 임의의 proposal distribution \(q(z)\)를 도입해

$$
p_{\theta}(x)=E_{z\sim q(z)}
\left[
\frac{p_{\theta}(x,z)}{q(z)}
\right]
$$

로 쓴다. 좋은 \(q\)는 \(x\)를 잘 설명할 가능성이 높은 \(z\), 즉 posterior \(p(z\mid x)\)에 가까운 completion을 자주 뽑아야 한다. 하지만 학습 목적은 \(p_{\theta}(x)\)가 아니라 \(\log p_{\theta}(x)\)다. Log를 sample average 바깥에 두면 unbiasedness가 깨지고, Jensen's inequality를 적용하면 계산 가능한 lower bound가 나온다.

$$
\log p_{\theta}(x)
\ge
E_{z\sim q(z)}
\left[
\log \frac{p_{\theta}(x,z)}{q(z)}
\right].
$$

이 값이 Evidence Lower Bound, ELBO다. 전개하면 \(E_q[\log p_{\theta}(x,z)] + H(q)\)가 되며, \(q(z)=p_{\theta}(z\mid x)\)이면 bound는 정확히 \(\log p_{\theta}(x)\)와 같아진다. Posterior가 계산 불가능할 때는 tractable family \(q(z;\phi)\)를 정하고, 이를 true posterior에 가깝게 맞추는 variational inference 문제가 된다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Latent Variable | 데이터에는 관측되지 않지만 \(x\)의 변동 요인을 설명하기 위해 모델에 넣는 hidden random variable이다. |
| Mixture Model | 단순한 component distribution들을 latent variable로 섞어 복잡한 marginal distribution을 만든다. |
| VAE Decoder | \(z\)를 입력으로 받아 \(p_{\theta}(x\mid z)\)의 parameter를 출력하는 neural network다. |
| Marginal Likelihood | 관측 \(x\)의 probability. Latent \(z\)를 모두 합산 또는 적분해야 하므로 VAE에서는 계산이 어렵다. |
| Importance Sampling | \(q(z)\)에서 샘플을 뽑고 \(p_{\theta}(x,z)/q(z)\)로 보정해 expectation을 추정하는 방법이다. |
| Jensen's Inequality | Concave log 때문에 \(\log E[f(z)]\ge E[\log f(z)]\)가 되어 ELBO를 만든다. |
| ELBO | Log evidence \(\log p_{\theta}(x)\)의 lower bound. Likelihood 대신 최적화 가능한 대리 목적함수다. |

## 학습 포인트

- Latent variable은 모델을 유연하게 만들지만, posterior inference와 marginal likelihood 계산을 어렵게 만든다.
- Mixture of Gaussians는 VAE를 이해하기 위한 shallow prototype이다.
- VAE는 finite mixture component를 continuous latent space로 바꾼 infinite mixture 관점으로 볼 수 있다.
- \(z\)가 사람이 이해 가능한 feature가 되는지는 MLE만으로 보장되지 않는다.
- Uniform Monte Carlo는 대부분 의미 없는 completion을 뽑기 때문에 variance가 커진다.
- ELBO는 "log-likelihood를 직접 못 계산하니 lower bound를 최적화한다"는 VAE 학습의 출발점이다.

## 마지막 핵심 정리

Lecture 5의 핵심은 VAE를 "simple prior + neural conditional + hard posterior inference"로 이해하는 것이다. Latent variable을 넣으면 \(p(x\mid z)\)는 단순해지고 \(p(x)\)는 유연해지지만, \(z\)를 보지 못하기 때문에 likelihood 계산이 어려워진다. ELBO는 이 난점을 Jensen's inequality와 proposal distribution \(q\)로 우회하는 첫 번째 도구다.

## Study Guide

1. Autoregressive model과 latent variable model을 likelihood 계산, generation 속도, representation learning 관점에서 비교한다.
2. Mixture of Gaussians에서 \(z\), \(p(z)\), \(p(x\mid z)\), \(p(z\mid x)\)가 각각 무엇을 의미하는지 그림 없이 설명해 본다.
3. VAE가 "infinite mixture"처럼 보이는 이유를 finite mixture와 나란히 써 본다.
4. Naive Monte Carlo, importance sampling, ELBO가 차례로 등장하는 이유를 variance와 log-likelihood 관점으로 연결한다.
5. \(q(z)\)가 true posterior에 가까울수록 ELBO가 tight해진다는 문장을 식으로 확인한다.

## 복습 질문

<details>
<summary>1. Latent variable model을 쓰면 어떤 장점이 생기는가?</summary>

답변: 관측 데이터의 복잡한 변동을 숨은 요인 \(z\)로 나누어 \(p(x\mid z)\)를 더 단순하게 만들 수 있다. 또한 \(p(z\mid x)\)를 추론하면 clustering이나 representation learning처럼 unlabeled data에서 feature를 얻는 데 쓸 수 있다.

</details>

<details>
<summary>2. Mixture of Gaussians가 하나의 Gaussian보다 유연한 이유는 무엇인가?</summary>

답변: 각 component가 다른 평균과 공분산을 갖고, marginal \(p(x)\)가 이 component들의 weighted sum이 되기 때문이다. 하나의 bell shape로는 표현하기 어려운 multi-modal density를 여러 component 조합으로 표현할 수 있다.

</details>

<details>
<summary>3. VAE를 infinite mixture로 볼 수 있는 이유는 무엇인가?</summary>

답변: Mixture of Gaussians에서는 \(z\)가 유한한 component index지만, VAE에서는 \(z\)가 continuous Gaussian prior에서 나온다. 각 \(z\)마다 decoder가 다른 Gaussian parameter를 만들기 때문에 연속적으로 많은 component를 섞는 것처럼 볼 수 있다.

</details>

<details>
<summary>4. Naive Monte Carlo가 partially observed likelihood 계산에서 잘 작동하지 않는 이유는 무엇인가?</summary>

답변: 대부분의 latent completion은 관측 \(x\)와 잘 맞지 않아 \(p_{\theta}(x,z)\)가 매우 작다. 드물게 중요한 \(z\)를 뽑아야 likelihood에 의미 있는 기여가 생기는데, uniform sampling은 그런 \(z\)를 거의 맞히지 못해 variance가 커진다.

</details>

<details>
<summary>5. ELBO가 lower bound가 되는 핵심 수학적 이유는 무엇인가?</summary>

답변: \(\log\)가 concave function이므로 Jensen's inequality에 의해 \(\log E_q[f(z)]\ge E_q[\log f(z)]\)가 성립한다. \(f(z)=p_{\theta}(x,z)/q(z)\)로 두면 오른쪽이 ELBO가 된다.

</details>

<details>
<summary>6. ELBO가 true log-likelihood와 같아지는 조건은 무엇인가?</summary>

답변: \(q(z)\)가 generative model의 true posterior \(p_{\theta}(z\mid x)\)와 같을 때다. 이 경우 Jensen bound가 tight해지고, \(\log p_{\theta}(x)=\mathrm{ELBO}\)가 된다.

</details>

## PDF

- [Official Lecture 5 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=MAGBUh77bNg){:target="_blank" rel="noopener"}
- [Official slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture5.pdf){:target="_blank" rel="noopener"}
- Local transfer source: `research_files/stanford-cs236-deep-generative-models-2023/slides/lecture05-variational-autoencoders-i.pdf`
