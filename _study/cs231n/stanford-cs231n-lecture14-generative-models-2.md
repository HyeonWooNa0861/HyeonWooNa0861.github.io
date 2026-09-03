---
layout: default
date: 2026-07-16 16:07:00 +0900
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

Generator \(G(z)\)는 known prior에서 뽑은 \(z\)를 데이터 모양의 sample로 바꾸고, discriminator \(D(x)\)는 real과 generated sample을 구분한다. 원래 minimax objective는

$$
\min_G\max_D\;
\mathbb{E}_{x\sim p_{data}}[\log D(x)]
+\mathbb{E}_{z\sim p(z)}[\log(1-D(G(z)))]
$$

이다. Discriminator가 만드는 gradient가 generator에게 “어떻게 더 진짜처럼 보일지” 알려준다. 명시적 \(p(x)\) 값이나 likelihood를 계산하지 않는 implicit model이라는 점이 VAE·autoregressive model과 다르다.

실전에서는 generator gradient가 약해지는 것을 피하려고 \(-\log D(G(z))\) 형태의 non-saturating loss를 자주 사용한다. 두 모델을 번갈아 update하므로 한쪽이 지나치게 강해지면 상대가 유용한 신호를 받지 못한다.

## 2. GAN의 장점과 실패 방식

GAN은 pixel별 reconstruction 평균을 강요하지 않으므로 당시 VAE보다 선명한 이미지를 만드는 장점이 있었다. Latent interpolation도 매끄러운 semantic 변화를 보여줄 수 있다. 그러나 objective는 likelihood를 주지 않고, training instability와 mode collapse가 발생할 수 있다. Generator가 데이터의 일부 mode만 재현해도 discriminator를 속일 수 있기 때문이다.

또한 VAE처럼 \(x\to z\) encoder가 기본 구성에 없다. \(z\to x\) 생성 경로가 있다는 사실만으로 모든 실제 이미지가 잘 정렬된 latent를 갖는다고 보장할 수 없다.

## 3. Diffusion과 rectified flow

Diffusion의 높은 수준 직관은 clean data와 같은 모양의 Gaussian noise를 준비하고, 중간 noise level의 입력에서 조금 더 clean한 방향을 예측하는 것이다. 학습은 임의의 noise level을 사용하고, 생성은 full noise에서 시작해 network를 반복 호출하며 \(t=1\)에서 \(t=0\)으로 이동한다.

강의가 구체적으로 전개하는 rectified flow에서는 data sample \(x\), noise sample \(z\), \(t\sim U[0,1]\)를 뽑고

$$
x_t=(1-t)x+tz,\qquad v=z-x
$$

로 직선 위 중간점과 velocity target을 만든다. Network \(f_\theta(x_t,t)\)는 \(v\)를 mean-squared error로 예측한다. Sampling 때는 noise에서 시작해 예측 velocity의 반대 방향으로 여러 작은 step을 적분해 data 쪽으로 이동한다. GAN의 단일 forward sampling보다 느리지만, 감소 여부를 직접 관찰할 수 있는 regression loss가 있고 큰 model과 data에 안정적으로 scale하기 쉽다는 것이 강의의 비교점이다.

## 4. Conditional generation과 guidance

Class label이나 text embedding \(c\)를 denoiser에 넣으면 \(p(x\mid c)\)를 모델링할 수 있다. Classifier-free guidance는 같은 모델을 조건이 있는 경우와 없는 경우로 학습하고 sampling 시 두 예측의 차이를 키운다. 개념적으로

$$
\widehat{v}_{guided}=\widehat{v}_{uncond}
+s(\widehat{v}_{cond}-\widehat{v}_{uncond})
$$

처럼 조건 방향을 증폭한다. Guidance scale \(s\)를 높이면 prompt 일치도가 커질 수 있지만 다양성이나 자연스러움을 잃을 수 있다.

## 5. Latent diffusion과 현대 생성 pipeline

Pixel 공간의 고해상도 diffusion은 비싸다. Latent diffusion은 VAE encoder로 이미지를 더 작은 spatial latent로 압축하고 그 공간에서 noise를 넣고 제거한 뒤, VAE decoder로 pixel을 복원한다. 이때 VAE reconstruction에 adversarial discriminator loss를 보태면 압축 과정의 시각적 선명도를 개선할 수 있다.

따라서 현대 pipeline은 `VAE encoder/decoder + adversarial perceptual training + diffusion transformer`처럼 여러 계열을 결합한다. 비디오 생성에서는 latent에 시간축이 추가되며, text condition과 spatiotemporal denoising을 함께 처리한다. 강의 말미는 diffusion을 latent variable model/variational bound 관점에서 다시 보고, discrete latent 위 autoregressive model까지 같은 family tree에 재연결한다.

## 마지막 핵심 정리

- GAN은 discriminator가 학습한 비교 신호로 generator를 훈련한다.
- Rectified flow는 data-noise 보간점에서 **data와 noise를 잇는 velocity field**를 학습한다.
- Guidance는 조건 일치도와 다양성 사이의 조절 손잡이다.
- Latent diffusion은 압축된 공간에서 계산하고, VAE·GAN·diffusion의 장점을 한 pipeline에 조합한다.

## Study Guide

GAN과 diffusion을 `학습 신호`, `sampling 단계 수`, `density 평가`, `대표 실패` 네 축으로 비교한다. 이어서 latent diffusion에서 encoder, denoiser, decoder가 어느 공간에서 무엇을 입력·출력하는지 그림으로 복원한다.

## 복습 질문

<details><summary>1. GAN을 implicit generative model이라고 부르는 이유는?</summary>

답변: Generator에서 sample을 뽑는 절차는 있지만 임의의 \(x\)에 대한 명시적 probability density를 계산하지 않기 때문이다.
</details>

<details><summary>2. Diffusion의 학습과 생성은 어떻게 다른가?</summary>

답변: 학습에서는 깨끗한 데이터에 선택한 timestep의 noise를 직접 넣어 복원 target을 만든다. 생성에서는 순수 noise에서 시작해 reverse update를 여러 번 반복한다.
</details>

<details><summary>3. Latent diffusion이 계산을 줄이는 원리는?</summary>

답변: VAE encoder가 pixel image를 공간적으로 작은 latent로 압축하고, 가장 비싼 반복 denoising을 그 작은 tensor에서 수행하기 때문이다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=Edr4uZFh4EE){:target="_blank" rel="noopener"}
