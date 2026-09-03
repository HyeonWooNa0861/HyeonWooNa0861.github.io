---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 15: Evaluation of Generative Models"
course: "CS236"
topic: "Likelihood, Compression, Sample Quality, Representation Metrics, and Prompt-Based Evaluation"
order: 15
major_topic: "Deep Generative Models"
keywords:
  - "Evaluation"
  - "Likelihood"
  - "Compression"
  - "FID"
  - "KID"
  - "Representation Learning"
  - "Prompting"
---

# Stanford CS236 Lecture 15: Evaluation of Generative Models

## Source

- Video: [Stanford CS236 Lecture 15](https://www.youtube.com/watch?v=MJt_ahtO-to){:target="_blank" rel="noopener"}
- Source PDF: [lecture15.pdf](https://deepgenerativemodels.github.io/assets/slides/lecture15.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 15는 새로운 model family가 아니라 "좋은 generative model이란 무엇인가"를 다룬다. Discriminative model은 task가 비교적 명확하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Mid-quarter recap | 지금까지의 model family와 training objective는 어떤 평가 질문으로 이어지는가? |
| 2 | Task-first evaluation | Generative model은 density, compression, sampling, representation 중 무엇을 위해 쓰는가? |
| 3 | Likelihood and compression | Test log-likelihood와 code length는 왜 같은 관점으로 볼 수 있는가? |
| 4 | Approximate density evaluation | KDE와 AIS는 likelihood가 직접 tractable하지 않을 때 무엇을 근사하는가? |
| 5 | Sample quality metrics | Human evaluation, Inception Score, FID, KID는 sample의 어떤 측면을 본다? |
| 6 | Text-to-image evaluation | Quality, alignment, bias, robustness는 왜 하나의 metric으로 합치기 어려운가? |
| 7 | Latent and prompting evaluation | Representation learning과 LLM prompting은 어떤 downstream/task metric을 요구하는가? |

## 핵심 내용

Lecture 15는 새로운 model family가 아니라 "좋은 generative model이란 무엇인가"를 다룬다. Discriminative model은 task가 비교적 명확하다. Classifier라면 held-out data에서 top-1 accuracy, top-5 accuracy, cross-entropy loss처럼 목적에 맞는 metric을 계산하면 된다. Generative model은 다르다. 같은 model이라도 density estimation, compression, image generation, representation learning, inverse problem, language model prompting 등 사용 목적이 다르면 좋은 모델의 의미가 바뀐다. 따라서 강의의 첫 원칙은 metric을 먼저 고르는 것이 아니라 task를 먼저 고르는 것이다.

Density estimation을 목표로 한다면 가장 자연스러운 metric은 test log-likelihood다.

$$
\mathbb{E}_{x\sim p_{\mathrm{data}}}[\log p_\theta(x)]
$$

Train/validation/test split을 만들고, training set으로 model을 학습하고, validation set으로 hyperparameter를 고른 뒤, test set에서 average log-likelihood를 평가한다. 이 관점은 compression과도 연결된다. Shannon coding 관점에서 probability가 높은 data point에는 짧은 code를, 낮은 data point에는 긴 code를 주면 평균 code length는 대략 \(-\log p_\theta(x)\)에 비례한다. 즉 maximum likelihood는 data를 잘 압축하는 model을 찾는 것과 같다. Language model에서 perplexity가 널리 쓰이는 이유도 여기에 있다. 다만 compression을 잘한다고 사용자가 원하는 semantic quality를 항상 잘 잡는 것은 아니다. Pixel-level likelihood는 배경 noise나 local statistics에 민감할 수 있고, 시각적으로 중요한 bit와 중요하지 않은 bit를 구분하지 않는다.

모든 model이 likelihood를 직접 제공하는 것은 아니다. Autoregressive model과 normalizing flow는 likelihood 계산이 비교적 직접적이고, VAE는 ELBO를 likelihood lower bound로 쓴다. GAN이나 일부 EBM, score-based model에서는 density evaluation이 어렵다. Sample만 있을 때 density를 추정하는 단순한 방법은 kernel density estimation이다.

$$
\hat{p}(x)=\frac{1}{n}\sum_{i=1}^{n}K_\sigma(x-x^{(i)})
$$

Bandwidth \(\sigma\)가 작으면 training sample 근처에만 spike가 생기고, 너무 크면 distribution이 지나치게 smooth해진다. Cross-validation으로 bandwidth를 고를 수 있지만, high-dimensional data에서는 KDE가 급격히 불안정해진다. Latent variable model의 likelihood를 더 정교하게 추정하려면 importance sampling이나 annealed importance sampling(AIS)을 쓸 수 있다. 단순히 \(z\sim p(z)\)에서 \(p_\theta(x\mid z)\)를 평균내면 posterior \(p(z\mid x)\)와 proposal이 멀어 variance가 커진다. AIS는 prior와 posterior 사이의 intermediate distributions를 만들어 normalizing constant ratio를 더 안정적으로 추정한다. 단, unbiased likelihood estimate가 log-likelihood의 unbiased estimate를 의미하지는 않는다.

Sampling quality가 목표라면 likelihood만으로 부족하다. Human evaluation은 여전히 강한 기준이다. 사람이 real/fake를 구분하기 어려운지, 얼마나 짧은 시간에 판단할 수 있는지, sample이 자연스럽고 다양한지 직접 볼 수 있기 때문이다. HYPE 계열 평가는 human response time이나 unlimited-time fooling rate로 quality를 측정한다. 그러나 human evaluation은 비싸고, 재현성이 낮고, evaluator bias가 들어가며, model이 training data를 외운 경우 generalization을 충분히 잡아내지 못할 수 있다.

자동 sample metric의 대표는 Inception Score, FID, KID다. Inception Score는 pretrained classifier의 예측을 사용한다. 개별 generated sample에 대해 classifier가 확신하면 sharpness가 높고, generated samples 전체의 marginal label distribution이 넓으면 diversity가 높다. 둘이 모두 높을수록 점수가 좋다. 하지만 real data와 직접 비교하지 않고, label 내부의 다양성을 놓칠 수 있다. FID는 generated samples와 test samples를 pretrained network feature space로 보내고, 각각 Gaussian을 fit한 뒤 두 Gaussian의 Wasserstein-2 distance를 계산한다.

$$
\mathrm{FID}=\lVert\mu_T-\mu_G\rVert_2^2+\mathrm{Tr}\left(\Sigma_T+\Sigma_G-2(\Sigma_T\Sigma_G)^{1/2}\right)
$$

낮을수록 좋지만, feature extractor와 Gaussian approximation에 의존한다. KID는 같은 feature space에서 MMD를 계산한다.

$$
\mathrm{MMD}(p,q)=\mathbb{E}_{x,x'\sim p}[K(x,x')]+\mathbb{E}_{y,y'\sim q}[K(y,y')]-2\mathbb{E}_{x\sim p,y\sim q}[K(x,y)]
$$

KID는 더 principled한 two-sample test로 볼 수 있고 unbiased estimator를 쓸 수 있지만, pairwise comparison 때문에 계산 비용이 더 크다.

Text-to-image model은 image quality만 보아서는 부족하다. Caption과 image의 alignment, aesthetic quality, robustness, originality, toxicity, bias, spatial reasoning까지 함께 평가해야 한다. HEIM은 이런 다면 평가를 한 benchmark로 묶으려는 시도로 소개된다. Latent representation learning에서는 downstream task가 중요하다. Clustering이면 homogeneity, completeness, V-measure나 normalized mutual information을 볼 수 있고, reconstruction/compression이면 MSE, PSNR, SSIM을 볼 수 있다. Disentanglement는 independent하고 interpretable한 latent factor를 원하는 목표지만, 순수 unsupervised setting에서는 어떤 inductive bias나 supervision 없이 식별하기 어렵다는 점을 기억해야 한다. 마지막으로 LLM은 next-token generative model이지만 자연어 prompt로 task를 지정할 수 있으므로, HELM이나 BigBench처럼 task suite와 metric suite를 함께 설계하는 평가가 필요하다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Task-first evaluation | Generative model의 좋고 나쁨은 사용 목적에 따라 달라지므로, metric보다 task 정의가 먼저다. |
| Test log-likelihood | Held-out data에 model이 부여하는 평균 log probability로 density estimation 성능을 평가한다. |
| Compression view | \(-\log p_\theta(x)\)가 code length와 연결되므로 likelihood maximization은 평균 code length minimization으로 해석된다. |
| KDE | Sample 주변에 kernel을 놓아 density를 추정하는 nonparametric 방법이다. High-dimensional data에서는 신뢰성이 낮다. |
| AIS | Intermediate distributions를 거쳐 latent variable model의 likelihood 또는 normalizing constant ratio를 추정하는 방법이다. |
| Inception Score | Generated sample의 classifier confidence와 predicted label diversity를 결합한 sample quality metric이다. |
| FID | Pretrained feature space에서 real/generated feature Gaussian 사이의 distance를 측정한다. 낮을수록 좋다. |
| KID | Feature space에서 MMD를 사용해 real/generated sample distributions를 비교하는 metric이다. |
| Disentanglement | Latent dimension이 독립적이고 해석 가능한 data factor를 반영하도록 만드는 representation goal이다. |

## 학습 포인트

- Generative model 평가에서 "좋은 sample"과 "높은 likelihood"는 같은 말이 아니다. 목적이 다르면 metric도 달라진다.
- Likelihood는 density estimation과 compression에는 자연스럽지만 perceptual quality나 semantic alignment를 완전히 대변하지 않는다.
- KDE는 sample-only density estimation의 직관을 주지만, high-dimensional image/text에서는 bandwidth와 curse of dimensionality 문제가 크다.
- Human evaluation은 강력하지만 비용, bias, reproducibility, memorization detection 문제가 있다.
- Inception Score는 generated samples만 보고, FID와 KID는 real/generated samples를 feature space에서 비교한다.
- Text-to-image와 LLM 평가는 단일 숫자보다 scenario와 metric matrix가 더 중요하다.
- Representation learning 평가는 downstream task, clustering, reconstruction, disentanglement처럼 사용 목적별로 나누어야 한다.

## 마지막 핵심 정리

Lecture 15의 핵심은 generative model evaluation에 보편적인 단일 정답이 없다는 점이다. Density를 원하면 likelihood와 compression이 자연스럽고, sample을 원하면 human evaluation과 FID/KID 같은 feature-space metric이 필요하며, representation이나 prompting을 원하면 downstream task 중심 metric이 필요하다. Model family를 비교할 때는 먼저 "무엇을 잘해야 하는가"를 고정한 뒤 metric을 선택해야 한다.

## Study Guide

1. 지금까지 배운 model family를 likelihood tractable 여부로 분류한다: autoregressive, flow, VAE, EBM, GAN, score-based model.
2. Evaluation target을 density, compression, sampling, representation, prompting으로 나누고 각 target에 맞는 metric을 하나씩 연결한다.
3. Likelihood가 높은 image model이 perceptually 좋은 sample을 보장하지 않는 이유를 bit-level compression 관점에서 설명해 본다.
4. Inception Score, FID, KID를 "real data를 비교하는가", "classifier label을 쓰는가", "feature distribution을 어떻게 비교하는가"로 구분한다.
5. Text-to-image model을 평가할 때 quality와 alignment를 별도 축으로 두는 이유를 예시로 정리한다.
6. Disentanglement metric을 읽을 때는 어떤 latent factor supervision 또는 inductive bias가 숨어 있는지 확인한다.

## 복습 질문

<details>
<summary>1. Generative model 평가에서 task-first 접근이 필요한 이유는 무엇인가?</summary>

답변: Generative model은 density estimation, compression, sample generation, representation learning, prompting 등 서로 다른 목적으로 쓰인다. 같은 model도 목적에 따라 좋고 나쁨이 달라지므로, 먼저 어떤 task를 잘해야 하는지 정한 뒤 그 task에 맞는 metric을 선택해야 한다.

</details>

<details>
<summary>2. Likelihood와 compression은 어떻게 연결되는가?</summary>

답변: Probability가 높은 data point에 짧은 code를 주고 낮은 data point에 긴 code를 주면 평균 code length는 대략 \(-\log p_\theta(x)\)에 비례한다. 따라서 average log-likelihood를 높이는 것은 평균 code length를 줄이는 compression objective로 해석할 수 있다.

</details>

<details>
<summary>3. KDE가 high-dimensional generative model 평가에 약한 이유는 무엇인가?</summary>

답변: KDE는 sample 주변에 kernel을 놓아 density를 추정하지만, 차원이 커지면 sample이 공간을 충분히 덮지 못한다. Bandwidth가 작으면 spike가 생기고, 크면 너무 smooth해지며, cross-validation으로 골라도 image 같은 high-dimensional data에서는 신뢰도가 낮다.

</details>

<details>
<summary>4. Inception Score의 주요 한계는 무엇인가?</summary>

답변: Inception Score는 generated samples에 대한 classifier confidence와 predicted label diversity만 본다. Real data distribution과 직접 비교하지 않고, class label 내부의 mode collapse나 pretrained classifier가 보지 못하는 품질 문제를 놓칠 수 있다.

</details>

<details>
<summary>5. FID와 KID는 어떤 공통점과 차이가 있는가?</summary>

답변: 둘 다 pretrained classifier의 feature space에서 real samples와 generated samples를 비교한다. FID는 feature distribution을 Gaussian으로 근사하고 closed-form Wasserstein distance를 계산해 낮을수록 좋다. KID는 MMD 기반 two-sample statistic을 사용하며 더 principled한 unbiased estimator를 쓸 수 있지만 pairwise comparison 비용이 크다.

</details>

<details>
<summary>6. Text-to-image model을 FID 하나로 평가하기 어려운 이유는 무엇인가?</summary>

답변: Text-to-image model은 image realism뿐 아니라 prompt alignment, object relation, bias, toxicity, robustness, originality, aesthetic quality도 중요하다. FID는 feature distribution 유사도만 보므로 caption을 제대로 따랐는지나 안전성 문제를 충분히 평가하지 못한다.

</details>

## PDF

- [Official Lecture 15 slide PDF](https://deepgenerativemodels.github.io/assets/slides/lecture15.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 15 Slides](https://deepgenerativemodels.github.io/assets/slides/lecture15.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 15 Video](https://www.youtube.com/watch?v=MJt_ahtO-to){:target="_blank" rel="noopener"}
- [HEIM: Holistic Evaluation of Text-to-Image Models](https://arxiv.org/abs/2311.04287){:target="_blank" rel="noopener"}
- [HELM: Holistic Evaluation of Language Models](https://crfm.stanford.edu/helm/){:target="_blank" rel="noopener"}
