---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 14: Generative Models 2"
course: "CS231N"
topic: "Generative Models 2"
order: 14
major_topic: "Computer Vision"
keywords:
  - "Diffusion Models"
  - "Score Matching"
  - "Denoising"
  - "Sampling"
  - "Generative Models"
---

# Stanford CS231N Lecture 14: Generative Models 2

Source: [Stanford CS231N Spring 2025 Lecture 14](https://www.youtube.com/watch?v=Edr4uZFh4EE){:target="_blank" rel="noopener"}

Official slides: [Lecture 14 PDF](https://cs231n.stanford.edu/slides/2025/lecture_14.pdf){:target="_blank" rel="noopener"}

> **핵심:** GAN은 확률값 대신 discriminator의 학습 신호로 generator를 훈련하고, diffusion은 데이터에 노이즈를 넣은 뒤 그 과정을 되감는 denoiser를 학습한다. 현대 생성 시스템은 VAE, adversarial loss, diffusion/Transformer를 **경쟁 모델이 아니라 조합 가능한 부품**으로 사용한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | GAN objective | Generator와 discriminator는 무엇을 최적화하는가? |
| 2 | GAN trade-offs | 선명한 sample과 불안정한 학습은 왜 함께 나타나는가? |
| 3 | Diffusion and rectified flow | Noise와 data 사이의 vector field를 어떻게 학습하는가? |
| 4 | Conditioning | Text나 class가 생성 방향을 어떻게 바꾸는가? |
| 5 | Latent diffusion | VAE, discriminator, diffusion이 왜 한 pipeline에 들어가는가? |

## 1. GAN: density 대신 두 네트워크의 게임

Generator $$G(z)$$는 known prior에서 뽑은 $$z$$를 데이터 모양의 sample로 바꾸고, discriminator $$D(x)$$는 real과 generated sample을 구분한다. 원래 minimax objective는

$$
\min_G\max_D\;
\mathbb{E}_{x\sim p_{data}}[\log D(x)]
+\mathbb{E}_{z\sim p(z)}[\log(1-D(G(z)))]
$$

이다. Discriminator가 만드는 gradient가 generator에게 “어떻게 더 진짜처럼 보일지” 알려준다. 명시적 $$p(x)$$ 값이나 likelihood를 계산하지 않는 implicit model이라는 점이 VAE·autoregressive model과 다르다.

실전에서는 generator gradient가 약해지는 것을 피하려고 $$-\log D(G(z))$$ 형태의 non-saturating loss를 자주 사용한다. 두 모델을 번갈아 update하므로 한쪽이 지나치게 강해지면 상대가 유용한 신호를 받지 못한다.

## 2. GAN의 장점과 실패 방식

GAN은 pixel별 reconstruction 평균을 강요하지 않으므로 당시 VAE보다 선명한 이미지를 만드는 장점이 있었다. Latent interpolation도 매끄러운 semantic 변화를 보여줄 수 있다. 그러나 objective는 likelihood를 주지 않고, training instability와 mode collapse가 발생할 수 있다. Generator가 데이터의 일부 mode만 재현해도 discriminator를 속일 수 있기 때문이다.

또한 VAE처럼 $$x\to z$$ encoder가 기본 구성에 없다. $$z\to x$$ 생성 경로가 있다는 사실만으로 모든 실제 이미지가 잘 정렬된 latent를 갖는다고 보장할 수 없다.

## 3. Diffusion과 rectified flow

Diffusion의 높은 수준 직관은 clean data와 같은 모양의 Gaussian noise를 준비하고, 중간 noise level의 입력에서 조금 더 clean한 방향을 예측하는 것이다. 학습은 임의의 noise level을 사용하고, 생성은 full noise에서 시작해 network를 반복 호출하며 $$t=1$$에서 $$t=0$$으로 이동한다.

강의가 구체적으로 전개하는 rectified flow에서는 data sample $$x$$, noise sample $$z$$, $$t\sim U[0,1]$$를 뽑고

$$
x_t=(1-t)x+tz,\qquad v=z-x
$$

로 직선 위 중간점과 velocity target을 만든다. Network $$f_\theta(x_t,t)$$는 $$v$$를 mean-squared error로 예측한다. Sampling 때는 noise에서 시작해 예측 velocity의 반대 방향으로 여러 작은 step을 적분해 data 쪽으로 이동한다. GAN의 단일 forward sampling보다 느리지만, 감소 여부를 직접 관찰할 수 있는 regression loss가 있고 큰 model과 data에 안정적으로 scale하기 쉽다는 것이 강의의 비교점이다.

## 4. Conditional generation과 guidance

Class label이나 text embedding $$c$$를 denoiser에 넣으면 $$p(x\mid c)$$를 모델링할 수 있다. Classifier-free guidance는 같은 모델을 조건이 있는 경우와 없는 경우로 학습하고 sampling 시 두 예측의 차이를 키운다. 개념적으로

$$
\widehat{v}_{guided}=\widehat{v}_{uncond}
+s(\widehat{v}_{cond}-\widehat{v}_{uncond})
$$

처럼 조건 방향을 증폭한다. Guidance scale $$s$$를 높이면 prompt 일치도가 커질 수 있지만 다양성이나 자연스러움을 잃을 수 있다.

## 5. Latent diffusion과 현대 생성 pipeline

Pixel 공간의 고해상도 diffusion은 비싸다. Latent diffusion은 VAE encoder로 이미지를 더 작은 spatial latent로 압축하고 그 공간에서 noise를 넣고 제거한 뒤, VAE decoder로 pixel을 복원한다. 이때 VAE reconstruction에 adversarial discriminator loss를 보태면 압축 과정의 시각적 선명도를 개선할 수 있다.

따라서 현대 pipeline은 `VAE encoder/decoder + adversarial perceptual training + diffusion transformer`처럼 여러 계열을 결합한다. 비디오 생성에서는 latent에 시간축이 추가되며, text condition과 spatiotemporal denoising을 함께 처리한다. 강의 말미는 diffusion을 latent variable model/variational bound 관점에서 다시 보고, discrete latent 위 autoregressive model까지 같은 family tree에 재연결한다.

## 핵심 수식 유도

### 작성자 보충: optimal discriminator와 JS divergence

고정 generator의 density를 $$q(x)=p_G(x)$$, data density를 $$p(x)=p_{\mathrm{data}}(x)$$라 쓰면 원래 GAN value function은

$$
V(D,G)=\int\left[p(x)\log D(x)+q(x)\log(1-D(x))\right]dx
$$

다. 각 $$x$$에서 $$D(x)\in(0,1)$$를 독립적으로 최적화할 수 있다고 가정하면 integrand의 미분은

$$
\frac{p(x)}{D(x)}-\frac{q(x)}{1-D(x)}=0
$$

이고, 이를 풀어

$$
D^*(x)=\frac{p(x)}{p(x)+q(x)}
$$

를 얻는다. $$p(x)+q(x)>0$$인 곳에서 두 번째 미분은 음수이므로 maximum이고, 둘 다 0인 곳의 $$D$$ 값은 objective에 영향을 주지 않는다. 이제 $$m=(p+q)/2$$라 두고 $$D^*$$를 대입하면

$$
\begin{aligned}
V(D^*,G)
&=\int p\log\frac{p}{p+q}\,dx
+\int q\log\frac{q}{p+q}\,dx\\
&=D_{\mathrm{KL}}(p\Vert m)+D_{\mathrm{KL}}(q\Vert m)-2\log2\\
&=-\log4+2D_{\mathrm{JS}}(p\Vert q).
\end{aligned}
$$

이는 density가 존재하고 discriminator 함수족이 제한되지 않으며 natural logarithm을 쓴다는 조건의 **정리**다. 실제 alternating SGD, finite-capacity discriminator, support 분리에서는 이 해석이 느슨해질 수 있다. Density는 좌표 부피의 역단위를 가질 수 있지만 density ratio, $$D$$, KL과 JS divergence는 무차원이다.

Classifier guidance의 $$\nabla_x\log p(x\mid y)=\nabla_x\log p(x)+\nabla_x\log p(y\mid x)$$는 Bayes rule의 **항등식**이다. Guidance scale을 1보다 크게 두는 것은 조건 충실도와 다양성을 교환하는 휴리스틱이며 calibrated posterior를 그대로 sampling하는 식은 아니다.

### 작성자 보충: rectified-flow velocity target

공식 슬라이드 42–61쪽의 직선 보간을 $$x_t=(1-t)x+tz$$로 두면 미분으로

$$
\frac{dx_t}{dt}=-x+z=z-x=v
$$

를 얻는다. 따라서 sample별 직선 경로의 속도는 모든 $$t$$에서 같은 $$v$$이며, network가 $$f_\theta(x_t,t)\approx v$$를 예측하도록 학습하는 것은 이 경로의 vector field를 회귀하는 일이다. 생성은 $$t=1$$의 noise에서 $$t=0$$의 data 방향으로 적분하므로 작은 음의 시간 간격 $$\Delta t<0$$에서 Euler step은 $$x\leftarrow x+\Delta t f_\theta(x,t)$$가 되고, 강의의 $$T$$-step 표기에서는 $$x\leftarrow x-f_\theta(x,t)/T$$가 된다. 부호는 **시간을 역방향으로 적분하기 때문**이다.

같은 $$(x_t,t)$$에 여러 $$(x,z)$$ pair가 대응할 수 있을 때 MSE

$$
\mathcal L(f)=\mathbb E\left[\lVert V-f(X_t,t)\rVert_2^2\right]
$$

의 population minimizer는 conditional mean이다. 실제로 $$m(X_t,t)=\mathbb E[V\mid X_t,t]$$라 두고 $$V-f=(V-m)+(m-f)$$로 분해하면 conditional cross term이 0이어서

$$
\mathcal L(f)
=\mathbb E\lVert V-m\rVert_2^2
+\mathbb E\lVert m-f\rVert_2^2
$$

가 된다. 그러므로 $$f^*=m$$이 **MSE 위험의 정확한 최적해**다. 이는 finite network가 그 함수를 정확히 표현하거나 Euler sampling이 오차 없이 분포를 운반한다는 보장은 아니다. $$x,z,v$$는 같은 data 단위를, $$t$$는 무차원을 가지며, 물리적 시간 단위가 아니라 정규화된 경로 parameter다. Curved transport, finite step, distribution shift, model approximation error에서는 직선 sample-level 유도와 실제 생성 궤적이 달라질 수 있다.

## 마지막 핵심 정리

- GAN은 discriminator가 학습한 비교 신호로 generator를 훈련한다.
- Rectified flow는 data-noise 보간점에서 **data와 noise를 잇는 velocity field**를 학습한다.
- Guidance는 조건 일치도와 다양성 사이의 조절 손잡이다.
- Latent diffusion은 압축된 공간에서 계산하고, VAE·GAN·diffusion의 장점을 한 pipeline에 조합한다.

## Study Guide

GAN과 diffusion을 `학습 신호`, `sampling 단계 수`, `density 평가`, `대표 실패` 네 축으로 비교한다. 이어서 latent diffusion에서 encoder, denoiser, decoder가 어느 공간에서 무엇을 입력·출력하는지 그림으로 복원한다.

## 복습 질문

<details markdown="block"><summary>1. GAN을 implicit generative model이라고 부르는 이유는?</summary>

답변: Generator에서 sample을 뽑는 절차는 있지만 임의의 $$x$$에 대한 명시적 probability density를 계산하지 않기 때문이다.
</details>

<details markdown="block"><summary>2. Diffusion의 학습과 생성은 어떻게 다른가?</summary>

답변: 학습에서는 깨끗한 데이터에 선택한 timestep의 noise를 직접 넣어 복원 target을 만든다. 생성에서는 순수 noise에서 시작해 reverse update를 여러 번 반복한다.
</details>

<details markdown="block"><summary>3. Latent diffusion이 계산을 줄이는 원리는?</summary>

답변: VAE encoder가 pixel image를 공간적으로 작은 latent로 압축하고, 가장 비싼 반복 denoising을 그 작은 tensor에서 수행하기 때문이다.
</details>

## 원문 대조 기록

공식 PDF **123쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 8–35쪽 · 영상 00:03:38 | GAN minimax objective와 failure modes | 1–2절 |
| PDF 36–61쪽 · 영상 00:31:40 | rectified-flow training과 reverse-time sampling | 3절 및 작성자 보충 |
| PDF 62–84쪽 | conditional flow와 classifier-free guidance | 4절 |
| PDF 85–106쪽 · 영상 00:52:34 | latent diffusion, DiT, text-to-image/video | 5절 |
| PDF 107–119쪽 · 영상 01:08:37 | generalized diffusion, score, SDE 관점 | 3–5절의 경계 설명 |

GAN·rectified flow·diffusion pipeline은 강의 원문 요약이다. Optimal discriminator/JS 식과 rectified-flow velocity·MSE conditional-mean 유도는 **작성자 보충**이고, guidance scale은 보장식이 아닌 heuristic으로 구분했다.

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=Edr4uZFh4EE){:target="_blank" rel="noopener"}
- [Official Lecture 14 slides](https://cs231n.stanford.edu/slides/2025/lecture_14.pdf){:target="_blank" rel="noopener"}
