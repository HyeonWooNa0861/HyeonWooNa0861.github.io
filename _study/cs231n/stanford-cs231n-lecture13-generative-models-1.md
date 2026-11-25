---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CS231N Lecture 13: Generative Models 1"
course: "CS231N"
topic: "Generative Models 1"
order: 13
major_topic: "Computer Vision"
keywords:
  - "Generative Models"
  - "Autoregressive Models"
  - "VAE"
  - "GAN"
  - "Latent Variables"
---

# Stanford CS231N Lecture 13: Generative Models 1

Source: [Stanford CS231N Spring 2025 Lecture 13](https://www.youtube.com/watch?v=zbHXQRUNlH0){:target="_blank" rel="noopener"}
Slides: [Official Stanford CS231N 2025 Lecture 13 PDF](https://cs231n.stanford.edu/slides/2025/lecture_13.pdf){:target="_blank" rel="noopener"}

**원본 자료 먼저 보기:** [PDF pp.63–91의 autoencoder에서 VAE로 가는 전개](https://cs231n.stanford.edu/slides/2025/lecture_13.pdf#page=63){:target="_blank" rel="noopener"}에서 p.63의 deterministic encoder $$x\mapsto z$$를 기준선으로 먼저 봅니다. 뒤 슬라이드는 latent distribution을 예측하고 sampled $$z$$를 decoder로 보내는 VAE 구조로 바뀝니다. 아래 4–5절은 posterior 근사, reparameterization, ELBO가 왜 필요한지 이 차이에 연결합니다.

<figure id="cs231n-lecture13-source-p63">
  <a href="{{ "/assets/images/study/cs231n/source-captures/cs231n-lecture13-p63.jpg" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs231n/source-captures/cs231n-lecture13-p63.jpg" | relative_url }}" alt="입력 x를 encoder가 하나의 latent feature z로 바꾸는 deterministic non-variational autoencoder 기준선" loading="lazy"></a>
  <figcaption>Source excerpt: <a href="https://cs231n.stanford.edu/slides/2025/lecture_13.pdf#page=63" target="_blank" rel="noopener">CS231N Lecture 13, PDF p. 63 (printed slide 63)</a>. Click the image to enlarge.</figcaption>
</figure>

> **핵심:** 그럴듯한 사진을 만드는 것과 주어진 사진이 모델에서 얼마나 나올 법한지 계산하는 것은 다른 능력입니다. 픽셀을 순서대로 예측하는 모델은 각 단계의 확률을 합쳐 전체 확률을 계산할 수 있습니다. 변분 오토인코더(VAE)는 직접 계산하기 어려운 값을 대신 학습할 수 있는 하한을 사용합니다.

분류 모델이 주어진 이미지의 class를 묻는다면 생성 모델은 이미지 자체가 어떤 분포에서 나오는지를 다룹니다. Autoregressive model은 pixel이나 token의 순서를 정해 joint probability를 조건부 확률의 곱으로 정확히 계산합니다. VAE는 숨은 변수 $$z$$로 데이터를 설명하지만 $$p(x)$$ 적분이 어려워, 계산 가능한 lower bound를 대신 높입니다.

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Probabilistic modeling | Discriminative와 generative model은 무엇을 모델링합니까? |
| 2 | Model family tree | Explicit·implicit, tractable·approximate의 기준은 무엇입니까? |
| 3 | Autoregressive models | Joint probability를 어떻게 조건부 확률로 분해합니까? |
| 4 | Latent variables | 관측되지 않은 $$z$$가 왜 필요합니까? |
| 5 | VAE and ELBO | 계산 불가능한 likelihood를 어떻게 학습합니까? |

</details>
## 1. 판별 모델과 생성 모델의 확률적 차이

판별 모델은 입력이 주어졌을 때 label의 조건부 분포 $$p(y\mid x)$$를 모델링합니다. 분류 경계를 만드는 데 집중하며 입력 자체가 얼마나 그럴듯한지는 답하지 않습니다. 생성 모델은 데이터 분포 $$p(x)$$, 조건부 생성이면 $$p(x\mid y)$$를 모델링합니다. 학습된 분포에서 새 표본을 뽑거나 데이터 likelihood를 평가하는 것이 목표입니다.

Maximum likelihood 학습은 dataset $$\{x_i\}_{i=1}^{N}$$에 대해

$$
\theta^*=\arg\max_\theta\sum_{i=1}^{N}\log p_\theta(x_i)
$$

를 풉니다. 데이터가 높은 확률을 갖게 parameter를 조정한다는 공통 원리가 이후 모델을 묶습니다.

## 2. 생성 모델의 family tree

**Explicit density** 모델은 $$p_\theta(x)$$ 값을 계산할 수 있습니다. 그중 autoregressive model은 정확한 likelihood를 계산하는 tractable 계열이고, VAE는 likelihood가 직접 계산되지 않아 lower bound를 최적화하는 approximate 계열입니다. **Implicit density** 모델은 확률값보다 sample 생성 절차를 직접 학습합니다. GAN은 다음 강의에서 이 가지로 소개됩니다.

이 구분은 sample 품질 하나만 보는 대신, likelihood 평가 가능성, sampling 속도, latent representation 유무, 학습 안정성이라는 서로 다른 trade-off를 보게 합니다.

## 3. Autoregressive factorization

Chain rule을 사용하면 $$D$$차원 데이터의 joint distribution은

$$
p(x)=\prod_{t=1}^{D}p(x_t\mid x_1,\ldots,x_{t-1})
$$

로 정확히 분해됩니다. RNN이나 causal Transformer가 이전 token에서 다음 token distribution을 예측하면 각 항의 log probability를 더해 exact likelihood를 계산할 수 있습니다. 학습 시 모든 정답 prefix를 알고 있어 병렬 계산이 가능하지만, 생성 시에는 하나를 뽑아 다음 입력으로 넣어야 하므로 순차적입니다.

이미지는 pixel과 RGB subpixel을 일정 순서의 discrete token으로 펼쳐 모델링할 수 있습니다. 그러나 고해상도 이미지는 sequence가 지나치게 깁니다. 강의는 raw pixel 대신 압축되거나 이산화된 token을 autoregressive하게 모델링하는 방향이 계산 문제를 줄이는 연결고리임을 설명합니다.

## 4. Latent variable model

관측 데이터 $$x$$가 관측되지 않은 원인 $$z$$에서 생성된다고 두면

$$
p_\theta(x)=\int p_\theta(x\mid z)p(z)\,dz
$$

입니다. $$z$$는 pose, style, object identity 같은 변동 요인을 압축할 잠재 공간을 제공합니다. 문제는 가능한 모든 $$z$$를 적분하는 marginal likelihood가 일반적인 neural decoder에서 계산 불가능하다는 점입니다.

VAE는 decoder $$p_\theta(x\mid z)$$에 더해 encoder $$q_\phi(z\mid x)$$를 두어 진짜 posterior를 근사합니다. Encoder는 보통 diagonal Gaussian의 mean과 variance를 출력합니다.

<figure id="cs231n-lecture13-source-p89">
  <a href="{{ "/assets/images/study/cs231n/source-captures/cs231n-lecture13-p89.jpg" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs231n/source-captures/cs231n-lecture13-p89.jpg" | relative_url }}" alt="latent z에서 data distribution을 출력하는 VAE decoder와 입력 x에서 latent mean과 covariance를 출력하는 encoder를 비교한 도식" loading="lazy"></a>
  <figcaption>Source excerpt: <a href="https://cs231n.stanford.edu/slides/2025/lecture_13.pdf#page=89" target="_blank" rel="noopener">CS231N Lecture 13, PDF p. 89 (printed slide 89)</a>. Click the image to enlarge.</figcaption>
</figure>

원본 p.89에서 decoder는 $$z$$를 받아 관측 분포의 평균 $$\mu_{x\mid z}$$를 내고, encoder는 반대 방향으로 $$x$$를 받아 latent Gaussian의 $$\mu_{z\mid x}$$와 $$\Sigma_{z\mid x}$$를 냅니다. 두 network를 함께 학습하는 이유는 직접 계산하기 어려운 true posterior $$p_\theta(z\mid x)$$를 $$q_\phi(z\mid x)$$로 근사해, decoder 학습에 필요한 latent를 각 입력에서 얻기 위해서입니다. 즉 deterministic autoencoder의 하나의 코드 점이 **분포의 parameter**로 바뀌는 지점이 VAE의 구조적 차이입니다.

## 5. ELBO와 reparameterization trick

VAE의 evidence lower bound는

$$
\log p_\theta(x)\ge
\mathbb{E}_{q_\phi(z\mid x)}[\log p_\theta(x\mid z)]
-D_{KL}(q_\phi(z\mid x)\|p(z))
$$

입니다. 첫 항은 latent가 입력을 재구성할 정보를 담도록 하고, KL 항은 각 입력의 posterior가 prior $$p(z)$$에서 지나치게 벗어나지 않게 합니다. KL이 없다면 encoder가 각 입력을 서로 떨어진 코드에 외워 prior sampling이 무의미해질 수 있습니다.

무작위 sampling node를 그대로 두면 encoder로 gradient를 보내기 어렵습니다. 그래서 $$\epsilon\sim\mathcal{N}(0,I)$$를 별도로 뽑고

$$
z=\mu_\phi(x)+\sigma_\phi(x)\odot\epsilon
$$

으로 재작성합니다. 무작위성은 $$\epsilon$$에, 학습 가능한 경로는 $$\mu,\sigma$$에 남습니다.

## 핵심 수식 유도

VAE는 계산하기 어려운 marginal log-likelihood 대신 reconstruction expectation에서 posterior-prior KL을 뺀 ELBO를 최대화합니다. ELBO와 실제 log-likelihood의 차이는 approximate posterior와 true posterior 사이의 KL입니다.

<details markdown="block">
<summary markdown="span">Derivation: ELBO and its posterior gap</summary>

### 작성자 보충: ELBO의 전체 유도와 gap

고정된 관측 $$x$$에 대해 $$q_\phi(z\mid x)$$가 필요한 support를 덮고, density ratio와 아래 expectation이 적분 가능하다고 가정하겠습니다. Marginal likelihood에 $$q_\phi(z\mid x)$$를 곱하고 나누면

$$
\begin{aligned}
\log p_\theta(x)
&=\log\int p_\theta(x,z)\,dz\\
&=\log\int q_\phi(z\mid x)
\frac{p_\theta(x,z)}{q_\phi(z\mid x)}\,dz\\
&=\log\mathbb E_{q_\phi(z\mid x)}
\left[\frac{p_\theta(x,z)}{q_\phi(z\mid x)}\right].
\end{aligned}
$$

Logarithm은 concave이므로 Jensen 부등식으로

$$
\begin{aligned}
\log p_\theta(x)
&\ge
\mathbb E_q\left[
\log p_\theta(x,z)-\log q_\phi(z\mid x)
\right]\\
&=\mathbb E_q[\log p_\theta(x\mid z)]
+\mathbb E_q[\log p(z)-\log q_\phi(z\mid x)]\\
&=\mathbb E_q[\log p_\theta(x\mid z)]
-D_{\mathrm{KL}}(q_\phi(z\mid x)\Vert p(z))\\
&\equiv\mathcal L_{\mathrm{ELBO}}(x).
\end{aligned}
$$

즉 reconstruction expectation에서 prior와 approximate posterior 사이의 KL을 뺀 값이 **정확한 lower bound**입니다. Bayes rule을 사용하면 동일한 관계를

$$
\boxed{
\log p_\theta(x)
=\mathcal L_{\mathrm{ELBO}}(x)
+D_{\mathrm{KL}}
\left(q_\phi(z\mid x)\Vert p_\theta(z\mid x)\right)
}
$$

로 쓸 수 있습니다. KL은 음수가 아니므로 inequality가 따르고, $$q_\phi(z\mid x)=p_\theta(z\mid x)$$일 때만 bound가 tight합니다. 첫 expectation identity에는 joint density가 $$q$$에 대해 절대연속인 shared-support 조건이 필요하고, gap 표현에는 $$q$$가 true posterior에 대해 절대연속이어야 KL이 유한합니다. Continuous density의 log는 선택한 base measure에 의존하지만 density ratio, KL과 ELBO gap은 무차원입니다.

Gaussian encoder에서 $$z=\mu+\sigma\odot\epsilon$$, $$\epsilon\sim\mathcal N(0,I)$$로 쓰는 것은 분포를 보존하는 reparameterization입니다. 표준화 latent 좌표에서는 $$z,\mu,\sigma,\epsilon$$을 무차원으로 둡니다. Variational family가 좁으면 posterior를 덮지 못해 bound가 느슨하고, decoder가 너무 강하면 KL collapse로 latent가 무시될 수 있습니다. Monte Carlo sample 수가 적으면 reconstruction expectation의 gradient variance도 커집니다.

</details>

## 마지막 핵심 정리

- Generative model의 공통 목표는 데이터 분포를 학습하는 것입니다.
- Autoregressive model은 **exact likelihood를 제공하는 대신 느린 sequential sampling**을 감수합니다.
- VAE는 latent marginalization을 ELBO로 우회합니다.
- Reconstruction과 KL은 각각 정보 보존과 sample 가능한 latent 공간을 담당합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

먼저 family tree를 직접 그리고 `density 계산 가능 여부 → likelihood 정확성 → sampling 방식`을 표시합니다. VAE는 encoder/decoder의 입력과 출력, ELBO 두 항이 서로 반대 방향으로 작용하는 이유, reparameterization이 gradient path를 만드는 과정을 순서대로 복원합니다.

</details>

## 복습 질문

<details markdown="block"><summary>1. Autoregressive model이 exact likelihood를 계산할 수 있는 이유는 무엇입니까?</summary>

답변: Chain rule로 joint probability를 정규화된 조건부 분포들의 곱으로 정확히 분해하고, 각 조건부 확률을 모델이 직접 출력하기 때문입니다.
</details>

<details markdown="block"><summary>2. VAE가 ELBO를 사용하는 이유는 무엇입니까?</summary>

답변: 모든 latent $$z$$를 적분한 $$p(x)$$와 진짜 posterior가 계산 불가능하기 때문입니다. 근사 posterior를 도입해 계산 가능한 lower bound를 최대화합니다.
</details>

<details markdown="block"><summary>3. Reparameterization trick은 무엇을 분리합니까?</summary>

답변: 무작위 sampling을 parameter와 독립인 $$\epsilon$$으로 옮기고, $$z=\mu+\sigma\odot\epsilon$$의 결정적 경로를 통해 encoder parameter로 gradient가 흐르게 합니다.
</details>

## 원문 대조 기록

<details markdown="block">
<summary markdown="span">출처 대조 내역 보기</summary>

공식 PDF **116쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했습니다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 13–47쪽 | discriminative/generative 구분과 model taxonomy | 1–2절 |
| PDF 48–62쪽 · 영상 00:35:14 | maximum likelihood와 autoregressive factorization | 1절, 3절 |
| PDF 63–91쪽 | autoencoder, latent variable, approximate posterior | 4–5절 |
| PDF 92–112쪽 · 영상 01:09:09, 01:09:53 | ELBO와 reparameterization | 5절 및 작성자 보충 |

Model family와 VAE 구성은 강의 원문 요약입니다. ELBO equality/gap, support 조건, Gaussian reparameterization의 한계는 **작성자 보충**입니다.

</details>
## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=zbHXQRUNlH0){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 13 PDF](https://cs231n.stanford.edu/slides/2025/lecture_13.pdf){:target="_blank" rel="noopener"}
