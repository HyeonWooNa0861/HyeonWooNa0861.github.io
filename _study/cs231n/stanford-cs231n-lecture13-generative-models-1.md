---
layout: default
date: 2026-07-16 16:07:00 +0900
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

> **핵심:** 생성 모델의 여러 이름은 결국 데이터 분포 \(p(x)\)를 **직접 계산할 수 있는가**, **근사하는가**, 아니면 **표본만 생성하는가**의 차이다. 1부는 tractable likelihood의 autoregressive model과 latent variable likelihood를 lower bound로 학습하는 VAE를 연결한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Probabilistic modeling | Discriminative와 generative model은 무엇을 모델링하는가? |
| 2 | Model family tree | Explicit·implicit, tractable·approximate의 기준은? |
| 3 | Autoregressive models | Joint probability를 어떻게 조건부 확률로 분해하는가? |
| 4 | Latent variables | 관측되지 않은 \(z\)가 왜 필요한가? |
| 5 | VAE and ELBO | 계산 불가능한 likelihood를 어떻게 학습하는가? |

## 1. 판별 모델과 생성 모델의 확률적 차이

판별 모델은 입력이 주어졌을 때 label의 조건부 분포 \(p(y\mid x)\)를 모델링한다. 분류 경계를 만드는 데 집중하며 입력 자체가 얼마나 그럴듯한지는 답하지 않는다. 생성 모델은 데이터 분포 \(p(x)\), 조건부 생성이면 \(p(x\mid y)\)를 모델링한다. 학습된 분포에서 새 표본을 뽑거나 데이터 likelihood를 평가하는 것이 목표다.

Maximum likelihood 학습은 dataset \(\{x_i\}_{i=1}^{N}\)에 대해

$$
\theta^*=\arg\max_\theta\sum_{i=1}^{N}\log p_\theta(x_i)
$$

를 푼다. 데이터가 높은 확률을 갖게 parameter를 조정한다는 공통 원리가 이후 모델을 묶는다.

## 2. 생성 모델의 family tree

**Explicit density** 모델은 \(p_\theta(x)\) 값을 계산할 수 있다. 그중 autoregressive model은 정확한 likelihood를 계산하는 tractable 계열이고, VAE는 likelihood가 직접 계산되지 않아 lower bound를 최적화하는 approximate 계열이다. **Implicit density** 모델은 확률값보다 sample 생성 절차를 직접 학습한다. GAN은 다음 강의에서 이 가지로 소개된다.

이 구분은 sample 품질 하나만 보는 대신, likelihood 평가 가능성, sampling 속도, latent representation 유무, 학습 안정성이라는 서로 다른 trade-off를 보게 한다.

## 3. Autoregressive factorization

Chain rule을 사용하면 \(D\)차원 데이터의 joint distribution은

$$
p(x)=\prod_{t=1}^{D}p(x_t\mid x_1,\ldots,x_{t-1})
$$

로 정확히 분해된다. RNN이나 causal Transformer가 이전 token에서 다음 token distribution을 예측하면 각 항의 log probability를 더해 exact likelihood를 계산할 수 있다. 학습 시 모든 정답 prefix를 알고 있어 병렬 계산이 가능하지만, 생성 시에는 하나를 뽑아 다음 입력으로 넣어야 하므로 순차적이다.

이미지는 pixel과 RGB subpixel을 일정 순서의 discrete token으로 펼쳐 모델링할 수 있다. 그러나 고해상도 이미지는 sequence가 지나치게 길다. 강의는 raw pixel 대신 압축되거나 이산화된 token을 autoregressive하게 모델링하는 방향이 계산 문제를 줄이는 연결고리임을 설명한다.

## 4. Latent variable model

관측 데이터 \(x\)가 관측되지 않은 원인 \(z\)에서 생성된다고 두면

$$
p_\theta(x)=\int p_\theta(x\mid z)p(z)\,dz
$$

이다. \(z\)는 pose, style, object identity 같은 변동 요인을 압축할 잠재 공간을 제공한다. 문제는 가능한 모든 \(z\)를 적분하는 marginal likelihood가 일반적인 neural decoder에서 계산 불가능하다는 점이다.

VAE는 decoder \(p_\theta(x\mid z)\)에 더해 encoder \(q_\phi(z\mid x)\)를 두어 진짜 posterior를 근사한다. Encoder는 보통 diagonal Gaussian의 mean과 variance를 출력한다.

## 5. ELBO와 reparameterization trick

VAE의 evidence lower bound는

$$
\log p_\theta(x)\ge
\mathbb{E}_{q_\phi(z\mid x)}[\log p_\theta(x\mid z)]
-D_{KL}(q_\phi(z\mid x)\|p(z))
$$

이다. 첫 항은 latent가 입력을 재구성할 정보를 담도록 하고, KL 항은 각 입력의 posterior가 prior \(p(z)\)에서 지나치게 벗어나지 않게 한다. KL이 없다면 encoder가 각 입력을 서로 떨어진 코드에 외워 prior sampling이 무의미해질 수 있다.

무작위 sampling node를 그대로 두면 encoder로 gradient를 보내기 어렵다. 그래서 \(\epsilon\sim\mathcal{N}(0,I)\)를 별도로 뽑고

$$
z=\mu_\phi(x)+\sigma_\phi(x)\odot\epsilon
$$

으로 재작성한다. 무작위성은 \(\epsilon\)에, 학습 가능한 경로는 \(\mu,\sigma\)에 남는다.

## 마지막 핵심 정리

- Generative model의 공통 목표는 데이터 분포를 학습하는 것이다.
- Autoregressive model은 **exact likelihood를 제공하는 대신 느린 sequential sampling**을 감수한다.
- VAE는 latent marginalization을 ELBO로 우회한다.
- Reconstruction과 KL은 각각 정보 보존과 sample 가능한 latent 공간을 담당한다.

## Study Guide

먼저 family tree를 직접 그리고 `density 계산 가능 여부 → likelihood 정확성 → sampling 방식`을 표시한다. VAE는 encoder/decoder의 입력과 출력, ELBO 두 항이 서로 반대 방향으로 작용하는 이유, reparameterization이 gradient path를 만드는 과정을 순서대로 복원한다.

## 복습 질문

<details><summary>1. Autoregressive model이 exact likelihood를 계산할 수 있는 이유는?</summary>

답변: Chain rule로 joint probability를 정규화된 조건부 분포들의 곱으로 정확히 분해하고, 각 조건부 확률을 모델이 직접 출력하기 때문이다.
</details>

<details><summary>2. VAE가 ELBO를 사용하는 이유는?</summary>

답변: 모든 latent \(z\)를 적분한 \(p(x)\)와 진짜 posterior가 계산 불가능하기 때문이다. 근사 posterior를 도입해 계산 가능한 lower bound를 최대화한다.
</details>

<details><summary>3. Reparameterization trick은 무엇을 분리하는가?</summary>

답변: 무작위 sampling을 parameter와 독립인 \(\epsilon\)으로 옮기고, \(z=\mu+\sigma\odot\epsilon\)의 결정적 경로를 통해 encoder parameter로 gradient가 흐르게 한다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=zbHXQRUNlH0){:target="_blank" rel="noopener"}
