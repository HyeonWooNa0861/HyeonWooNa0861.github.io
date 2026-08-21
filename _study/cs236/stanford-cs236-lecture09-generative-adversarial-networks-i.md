---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 9: Generative Adversarial Networks I"
course: "CS236"
topic: "Likelihood-Free Generative Learning"
order: 9
major_topic: "Deep Generative Models"
keywords:
  - "GAN"
  - "Discriminator"
  - "Two-Sample Test"
  - "Jensen-Shannon Divergence"
  - "Mode Collapse"
  - "Likelihood-Free Learning"
---

# Stanford CS236 Lecture 9: Generative Adversarial Networks I

Source: [Stanford CS236 Deep Generative Models 2023 Lecture 9](https://www.youtube.com/watch?v=3Zv-gokhLu8){:target="_blank" rel="noopener"}

Source PDF: [lecture09-generative-adversarial-networks-i.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture9.pdf){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Likelihood-based model recap | Autoregressive model, VAE, flow는 어떤 방식으로 likelihood를 다루는가? |
| 2 | Maximum likelihood의 장점 | 왜 MLE는 통계적 효율성과 lossless compression 관점에서 자연스러운 기준인가? |
| 3 | Likelihood와 sample quality의 분리 | High likelihood가 항상 좋은 sample을 의미하지 않는 이유는 무엇인가? |
| 4 | Two-sample test | Density 없이 sample set만 비교해 두 분포가 같은지 어떻게 판단할 수 있는가? |
| 5 | Discriminator | 고차원 sample 차이를 hand-crafted statistic 대신 classifier로 어떻게 학습하는가? |
| 6 | GAN minimax objective | Generator와 discriminator는 같은 objective를 놓고 왜 반대 방향으로 움직이는가? |
| 7 | Jensen-Shannon divergence | Optimal discriminator 아래 GAN objective는 어떤 divergence를 최소화하는가? |
| 8 | Practical challenges | GAN이 강력하지만 학습이 불안정하고 mode collapse가 생기는 이유는 무엇인가? |

## 핵심 내용

Lecture 9는 지금까지의 likelihood-based generative model에서 벗어나 GAN을 도입한다. Autoregressive model은 chain rule로 \(p_\theta(x)\)를 직접 계산하고, VAE는 marginal likelihood가 어려워 ELBO를 최적화하며, normalizing flow는 change of variables로 exact likelihood를 계산한다. 세 계열 모두 궁극적으로 \(D_{KL}(p_{data}\|p_\theta)\)를 줄이거나 likelihood를 높이는 방향으로 학습한다. 강의는 이 기준이 왜 좋은지 먼저 확인한다. 충분한 model capacity와 적절한 조건이 있으면 maximum likelihood estimator는 통계적으로 효율적이고, 높은 likelihood는 lossless compression 관점에서도 좋은 압축률을 의미한다.

하지만 lecture의 핵심 질문은 "likelihood가 sample quality의 충분한 지표인가?"이다. 이상적으로 model family가 data distribution을 정확히 포함하고 optimization이 완벽하다면 high likelihood와 best sample quality는 함께 간다. 그러나 실제 model은 불완전하고 optimization도 제한적이다. 슬라이드는 두 가지 반례를 든다. 하나는 \(0.01p_{data}+0.99p_{noise}\) 같은 mixture다. 대부분의 sample은 noise라 품질이 나쁘지만, data point에 대해서는 \(0.01p_{data}\)만큼의 probability가 남아 있어 high-dimensional setting에서 expected log-likelihood가 크게 나빠지지 않을 수 있다. 반대로 training set을 외워버리는 model은 sample이 매우 그럴듯해 보일 수 있지만, test point에는 거의 probability를 주지 못한다. 이 예시들은 likelihood와 sample quality를 분리해서 생각할 필요를 보여 준다.

GAN은 이 분리를 위해 likelihood-free learning으로 이동한다. Density를 직접 계산하지 않고, data에서 온 sample set \(S_1\)과 model에서 온 sample set \(S_2\)를 비교한다. 통계적으로는 two-sample test의 관점이다. 두 sample set의 mean, variance 같은 statistic을 비교해 \(P=Q\)인지 판단할 수 있지만, 이미지나 음성처럼 고차원 데이터에서는 어떤 statistic을 써야 할지 hand-craft하기 어렵다. Mean만 맞추면 분산이나 모양이 다를 수 있고, mean과 variance를 맞춰도 더 높은 차원의 구조가 틀릴 수 있다.

그래서 GAN은 statistic을 직접 고르는 대신 discriminator \(D_\phi\)를 학습한다. Discriminator는 real sample \(x \sim p_{data}\)에는 1, fake sample \(x \sim p_\theta\)에는 0을 예측하는 binary classifier다. Objective는

$$
\max_{D_\phi} V(p_\theta,D_\phi)
=\mathbb{E}_{x\sim p_{data}}[\log D_\phi(x)]
+\mathbb{E}_{x\sim p_\theta}[\log(1-D_\phi(x))].
$$

Classifier loss가 낮다면 real과 fake가 쉽게 구분되므로 두 sample set은 다르다. Loss가 높다면 classifier가 헷갈리는 것이고, 두 sample set이 비슷하다는 신호가 된다. 중요한 차이는 likelihood가 generative model의 \(p_\theta(x)\)가 아니라 classifier의 binary label likelihood에만 필요하다는 점이다. Generator는 density를 계산할 필요 없이 sample만 만들 수 있으면 된다.

Generator \(G_\theta\)는 simple prior \(z \sim p(z)\)를 받아 \(x=G_\theta(z)\)를 만드는 deterministic neural network다. Flow와 비슷하게 noise를 sample로 바꾸지만, invertible일 필요도 없고 \(z\)와 \(x\)의 차원이 같을 필요도 없다. 이 유연성이 GAN의 큰 장점이다. 전체 학습은 minimax game이다.

$$
\min_G \max_D V(G,D)
=\mathbb{E}_{x\sim p_{data}}[\log D(x)]
+\mathbb{E}_{z\sim p(z)}[\log(1-D(G(z)))].
$$

Discriminator는 real/fake를 잘 구분하려고 \(V\)를 키우고, generator는 discriminator를 속이기 위해 \(V\)를 줄인다. 학습은 보통 real minibatch와 noise minibatch를 뽑고, discriminator를 gradient ascent로 갱신한 뒤 generator를 gradient descent로 갱신하는 alternating optimization으로 진행된다.

이 objective는 이론적으로 Jensen-Shannon divergence와 연결된다. Fixed generator에 대해 optimal discriminator는

$$
D_G^\*(x)=\frac{p_{data}(x)}{p_{data}(x)+p_G(x)}
$$

이다. 이를 objective에 대입하면 \(2D_{JSD}(p_{data},p_G)-\log 4\)가 된다. Jensen-Shannon divergence는 non-negative이고 두 분포가 같을 때 0이므로, 이상적인 조건에서는 GAN도 \(p_G=p_{data}\)를 global optimum으로 갖는다. 따라서 GAN은 목표 자체가 임의적인 것이 아니라, likelihood 대신 two-sample classifier를 통해 다른 divergence를 최적화하는 방식으로 이해할 수 있다.

실전에서는 장점과 문제가 함께 나타난다. 장점은 likelihood evaluation이 필요 없어서 generator architecture가 자유롭고, sampling이 보통 single forward pass라 빠르다는 점이다. 단점은 minimax optimization이 매우 어렵다는 점이다. Discriminator와 generator가 서로 움직이기 때문에 loss가 안정적으로 수렴하지 않고, MLE처럼 명확한 stopping criterion을 잡기 어렵다. 또한 mode collapse가 자주 발생한다. Generator가 data distribution의 모든 mode를 덮지 못하고 한두 mode에 집중해 discriminator를 일시적으로 속이는 현상이다. 강의는 이러한 불안정성 때문에 GAN 학습에는 architecture, loss, regularization, heuristic이 많이 필요하며, 이후 diffusion model이 널리 쓰이게 된 중요한 이유도 더 안정적인 학습 objective에 있다고 설명한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Likelihood-Free Learning | Generative model의 density를 직접 계산하지 않고 sample 비교 기준으로 학습하는 접근이다. |
| Two-Sample Test | 두 sample set이 같은 distribution에서 왔는지 test statistic으로 판단하는 절차다. |
| Discriminator | Real sample과 generated sample을 구분하도록 학습되는 binary classifier이며, GAN의 learned statistic 역할을 한다. |
| Generator | Simple noise \(z\)를 sample \(G_\theta(z)\)로 바꾸는 neural network sampler다. |
| Minimax Objective | Discriminator는 real/fake 구분을 잘하려 하고 generator는 discriminator를 속이려 하는 두 플레이어 게임이다. |
| Jensen-Shannon Divergence | Optimal discriminator를 가정하면 GAN objective가 최소화하는 divergence로 해석된다. |
| Mode Collapse | Generator가 data distribution의 다양한 mode를 모두 덮지 못하고 일부 sample pattern에만 집중하는 현상이다. |

## 학습 포인트

- Maximum likelihood는 강력한 원리지만, high likelihood와 perceptual sample quality가 항상 같은 방향으로 움직이지는 않는다.
- GAN은 density evaluation을 포기하는 대신 "sample이 real처럼 보이는가"를 discriminator가 학습한 statistic으로 측정한다.
- Discriminator의 likelihood는 binary classification likelihood이므로, generator density \(p_G(x)\)를 계산할 필요가 없다.
- GAN generator는 flow처럼 latent noise를 data sample로 바꾸지만, invertibility와 same-dimensional constraint가 없다.
- Optimal discriminator 아래에서는 GAN objective가 Jensen-Shannon divergence로 해석되지만, 실제 neural network와 alternating optimization은 그 이상적 조건을 보장하지 않는다.
- Mode collapse와 loss oscillation은 GAN을 실험적으로 어렵게 만드는 대표 문제다.

## 마지막 핵심 정리

Lecture 9의 핵심은 GAN을 "likelihood를 모르는 generator를 학습시키기 위한 learned two-sample test"로 이해하는 것이다. Discriminator는 real과 fake의 차이를 찾고, generator는 그 차이를 없애려 한다. 이론적으로는 Jensen-Shannon divergence와 연결되지만, 실제 학습은 불안정성과 mode collapse 때문에 많은 주의가 필요하다.

## Study Guide

1. \(0.01p_{data}+0.99p_{noise}\) 예시가 왜 high likelihood와 poor sample quality를 동시에 가질 수 있는지 설명한다.
2. Two-sample test의 hand-crafted statistic이 고차원 데이터에서 부족한 이유를 mean/variance 예시로 정리한다.
3. Discriminator objective를 binary cross-entropy 관점에서 해석하고, generator density가 필요 없는 이유를 확인한다.
4. GAN minimax objective에서 discriminator update와 generator update가 각각 어떤 term을 바꾸는지 구분한다.
5. Optimal discriminator 공식을 통해 \(p_G=p_{data}\)일 때 \(D(x)=1/2\)가 되는 이유를 설명한다.
6. Mode collapse를 KL 기반 MLE의 mode-covering 성향과 대비해 이해한다.

## 복습 질문

<details>
<summary>1. Maximum likelihood가 좋은 학습 기준으로 여겨지는 이유는 무엇인가?</summary>

답변: 적절한 조건과 충분한 model capacity가 있으면 MLE는 true parameter에 효율적으로 수렴하는 통계적 성질을 갖는다. 또한 높은 likelihood는 data를 더 짧게 lossless compression할 수 있다는 의미와 연결되어, 확률 모델을 학습하는 자연스러운 기준이 된다.

</details>

<details>
<summary>2. High likelihood가 항상 좋은 sample quality를 보장하지 않는 이유는 무엇인가?</summary>

답변: 불완전한 model에서는 data point에 일정 probability를 주면서도 대부분의 sampling mass를 noise에 둘 수 있다. 이 경우 test log-likelihood는 크게 나쁘지 않을 수 있지만 실제 sample은 대부분 나쁘다. 반대로 training data를 외우면 sample은 좋아 보여도 unseen test data likelihood는 매우 낮을 수 있다.

</details>

<details>
<summary>3. GAN에서 discriminator는 왜 learned two-sample statistic이라고 볼 수 있는가?</summary>

답변: Two-sample test는 두 sample set의 차이를 statistic으로 측정한다. GAN에서는 이 statistic을 mean이나 variance처럼 사람이 고정하지 않고, real sample과 fake sample을 구분하는 classifier의 loss로 학습한다. Classifier가 잘 구분하면 분포가 다르다는 신호이고, 구분하지 못하면 비슷하다는 신호다.

</details>

<details>
<summary>4. GAN generator가 normalizing flow보다 architecture 제약이 적은 이유는 무엇인가?</summary>

답변: Flow는 likelihood 계산을 위해 mapping이 invertible이고 \(x,z\) 차원이 같아야 하며 Jacobian determinant도 계산해야 한다. GAN은 generator density를 계산하지 않고 sample만 만들면 되므로, \(G_\theta\)가 invertible일 필요도 없고 차원 제약도 훨씬 약하다.

</details>

<details>
<summary>5. Optimal discriminator가 \(D_G^\*(x)=p_{data}(x)/(p_{data}(x)+p_G(x))\)인 직관은 무엇인가?</summary>

답변: 어떤 \(x\)가 real class에서 왔을 posterior probability를 Bayes rule로 계산한 값이다. Data density가 model density보다 크면 real일 확률이 높고, 두 density가 같으면 real과 fake를 구분할 근거가 없어 \(1/2\)가 된다.

</details>

<details>
<summary>6. Mode collapse란 무엇이며 왜 문제가 되는가?</summary>

답변: Generator가 data distribution의 다양한 mode를 모두 생성하지 못하고 일부 pattern만 반복해 만드는 현상이다. 개별 sample은 그럴듯할 수 있지만 distribution 전체를 덮지 못하므로 diversity가 낮고, 실제 data의 여러 유형을 놓친다.

</details>

## PDF

- [Official Lecture 9 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture9.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [Lecture video](https://www.youtube.com/watch?v=3Zv-gokhLu8){:target="_blank" rel="noopener"}
- [Lecture slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture9.pdf){:target="_blank" rel="noopener"}
- [CS236 course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
- [GAN Hacks](https://github.com/soumith/ganhacks){:target="_blank" rel="noopener"}
