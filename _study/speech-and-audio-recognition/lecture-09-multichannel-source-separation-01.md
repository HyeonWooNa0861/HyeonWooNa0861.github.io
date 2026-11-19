---
layout: default
date: 2026-11-17 00:05:00 +0900
last_modified_at: 2026-11-19 21:03:05 +0900
title: "Lecture 9: Multi-channel Source Separation I"
course: "Speech and Audio Recognition"
topic: "Blind Separation, Spatial Covariance, Multichannel Wiener Filtering, and Mask-based MVDR"
order: 12
major_topic: "Speech and Audio Processing"
keywords:
  - "Blind Source Separation"
  - "ICA"
  - "IVA"
  - "Spatial Covariance"
  - "Multichannel Wiener Filter"
  - "MVDR"
  - "Mask-based Beamforming"
---

# Lecture 9: Multi-channel Source Separation I

Source PDF: `speech-audio-lecture-09-1.pdf` — *Multi-channel Source Separation 2-1*, 안인규(Inkyu An), 24 slides.

> **핵심:** 다채널 분리의 중심 문제는 여러 마이크의 혼합 신호에서 **목표와 잡음의 서로 다른 공간 통계**를 찾는 것이다. ICA·IVA는 독립성을 이용해 demixing matrix를 찾고, MWF와 MVDR는 목표·잡음 공분산으로 선형 공간 필터를 계산한다. Mask 기반 방법은 신경망 출력 자체를 최종 음성으로 쓰는 대신, 각 time-frequency 관측이 공분산 추정에 얼마나 기여할지를 정한다.

## 전체 흐름

| 슬라이드 | 주제 | 확인할 관계 |
|---|---|---|
| 1–4 | 다채널 분리와 공간 필터 복습 | DAS·MVDR·BSS·mask 기반 MVDR는 공간 필터를 얻는 정보가 다르다. |
| 5–6 | Frequency-domain ICA와 IVA | 주파수별 독립 분리는 permutation 문제가 생기며, IVA는 주파수들을 source vector로 묶는다. |
| 7–10 | 혼합 신호 모델 | 관측 벡터는 목표와 잡음의 합이고, 목표의 각 채널은 room impulse response를 거친다. |
| 11–12 | 공간 공분산 | 대각·비대각·coherence·phase·rank가 채널별 파워와 공간 관계를 나타낸다. |
| 13–14 | Multichannel Wiener filter | 기준 마이크의 목표 신호에 대한 MSE를 최소화하면 Wiener–Hopf 식을 얻는다. |
| 15–20 | MVDR와 MWF | Rank-one 목표 공분산으로 DoA 없이 MVDR를 만들고, MWF와의 gain 차이를 해석한다. |
| 21–24 | Mask 기반 ESD | Mask를 가중치로 사용해 목표·잡음 공분산을 추정하고 선형 필터를 계산한다. |

11월 10일 녹화에서 공간 공분산은 **06:34**(11쪽), coherence와 rank는 **25:10**(12쪽)부터 볼 수 있다. 이 두 그림이 필터 설계로 이어지는 부분은 **44:01**의 MWF와 **47:40**의 MVDR다. 녹화 마지막(52:15–53:18)에서는 신경망이 목표와 잡음의 통계를 추정하면 같은 공간 필터를 쓸 수 있다는 연결점을 짚는다. 21–24쪽의 마스크 계산은 11월 10일에는 개요만 소개하고, 11월 12일 녹화 26:50부터 자세히 다룬다.

아래에서는 frame $$t$$와 주파수 bin $$f$$를 고정했을 때 마이크 수를 $$M$$, 복소 관측 벡터를 $$\mathbf x(t,f)\in\mathbb C^{M}$$로 쓴다. 모든 공분산과 필터는 주파수별로 존재한다. 식을 짧게 만들 때만 $$(t,f)$$를 생략한다.

**11월 12일 녹화 앞부분(00:00–09:27):** 00:31부터는 같은 소리가 두 마이크에 다른 시각에 도착하면 왜 크기뿐 아니라 **위상차**를 봐야 하는지 복습한다(관련 PDF 11–12쪽). 05:36부터는 어느 마이크의 목표 신호를 복원할지 정하고(13쪽), 07:48부터는 그 목표에 가장 가까운 출력을 그림에서 찾는다(14쪽). 시각은 이날 녹음 기준이며, 쪽수는 같은 설명을 찾을 수 있는 자료 위치다.

같은 녹화 **12:12**부터는 도래각(DoA)을 직접 주지 않는 MVDR의 목적과 해를 소개하고(15–16쪽), **15:35**부터는 목표 공분산이 rank one일 때 그 행렬에서 마이크 사이의 상대 전달 관계를 얻을 수 있는 이유를 다룬다(17쪽). **21:53**부터는 같은 방향을 선택한 MWF와 MVDR의 출력이 왜 다른지(18쪽), **30:14**부터는 마스크를 이미 구했는데도 왜 공간 필터가 필요한지 설명한다(23–24쪽).

## 1. 같은 출력이라도 공간 필터를 얻는 정보가 다르다

강의의 공통 출력은 마이크별 복소 STFT를 한 값으로 합치는

$$
y(t,f)=\mathbf w(f)^H\mathbf x(t,f)
$$

이다. $$\mathbf x$$와 $$\mathbf w$$는 모두 $$M\times1$$이고, $$y$$는 한 reference 출력의 복소 STFT 값이다. 역 STFT를 거치면 단일 채널 waveform이 된다. 차이는 **$$\mathbf w$$를 무엇으로 계산하는가**에 있다.

| 방법 | 사용하는 정보 | 해결하는 문제와 남는 조건 |
|---|---|---|
| Delay-and-Sum | DoA와 배열 geometry | 목표 방향을 정렬한다. 정확한 DoA와 전달 모델이 필요하다. |
| Steering-vector MVDR | 목표 steering vector와 잡음 공분산 | 목표 응답을 보존하며 잡음 파워를 줄인다. Steering mismatch에 민감하다. |
| ICA·IVA | source 간 통계적 독립성 | DoA 없이 여러 source를 분리한다. 충분한 마이크와 고정된 mixing 조건이 필요하다. |
| Covariance-based MVDR | 목표·잡음 공분산 | 목표 공분산에서 상대 전달 방향을 얻는다. Rank-one 조건과 좋은 공분산 추정이 필요하다. |
| Mask-based MVDR | mask로 가중한 관측의 바깥곱 | 혼합음만 관측할 때 목표·잡음 통계를 추정한다. Mask 누출이 필터 오차로 이어진다. |

여기서 `blind`는 배열 geometry나 DoA를 직접 주지 않는다는 뜻이다. 아무 정보도 쓰지 않는다는 뜻은 아니다. ICA·IVA는 독립성을, covariance-based MVDR는 데이터가 가진 공간 통계를 사용한다.

## 2. ICA는 bin별로 분리하지만 출력 순서를 고정하지 못한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-05.png" | relative_url }}" alt="Lecture 9 I slide 5: frequency-domain ICA equations and frequency-bin output permutations before and after alignment" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=5" | relative_url }}" target="_blank" rel="noopener">slide 5</a>.</figcaption>
</figure>

주파수영역 ICA는 convolutive mixture를 각 주파수의 instantaneous mixture로 바꿔 다룬다.

$$
\mathbf x(t,f)=\mathbf A(f)\mathbf q(t,f),\qquad
\mathbf y(t,f)=\mathbf W(f)\mathbf x(t,f).
$$

여기서 $$\mathbf q\in\mathbb C^{K}$$는 $$K$$개 source, $$\mathbf A\in\mathbb C^{M\times K}$$는 mixing matrix, $$\mathbf W\in\mathbb C^{K\times M}$$는 demixing matrix다. 강의의 determined 또는 overdetermined 조건 $$M\ge K$$에서는 source 수보다 마이크가 적지 않다.

오른쪽 그림은 세로축이 frequency bin이고, 파랑과 주황이 두 화자다. Bin마다 ICA를 독립적으로 풀면 `output 1`이 어떤 bin에서는 파랑, 다른 bin에서는 주황을 맡을 수 있다. ICA 목적함수는 출력의 독립성만 보므로 **source label을 바꾼 해도 같은 품질의 해**다. 역 STFT 전에 bin별 순서를 맞추지 않으면 한 출력에 두 화자의 주파수 성분이 섞인다. Scale ambiguity도 별도로 남는다.

### 2.1 IVA는 한 source의 주파수들을 한 벡터로 묶는다

IVA(Independent Vector Analysis)는 화자 $$k$$의 모든 주파수 성분을

$$
\mathbf y_k(t)=\begin{bmatrix}Y_k(t,1)&\cdots&Y_k(t,F)\end{bmatrix}^{T}
$$

처럼 한 벡터로 보고, 서로 다른 source vector는 독립이면서 같은 source 안의 주파수들은 함께 변할 수 있게 모델링한다. 따라서 각 bin을 완전히 따로 정렬하는 대신 **주파수 전체에서 같은 source index를 공유하도록 결합**한다.

강의의 “no permutation problem”은 binwise permutation을 모델 안에서 함께 다룬다는 핵심을 압축한 표현이다. 전역적인 출력 순서까지 `speaker A=output 1`로 식별하는 것은 아니며, 최적화 실패나 모델 mismatch가 절대 없다는 보장도 아니다. 또한 `static mixing`은 분석 구간 안에서 전달 경로 $$\mathbf A(f)$$가 충분히 고정되어야 한다는 조건이다. 화자나 마이크가 빠르게 움직이면 이 가정이 깨질 수 있다.

## 3. 관측은 목표와 잡음의 합이다

강의는 마이크에서 관측한 벡터를

$$
\mathbf x(t)=\begin{bmatrix}x_1(t)&\cdots&x_M(t)\end{bmatrix}^{T}
=\mathbf s(t)+\mathbf n(t)
$$

로 둔다. $$\mathbf s$$는 각 마이크에 도달한 **목표 source의 채널별 이미지**, $$\mathbf n$$은 그 밖의 간섭·배경·센서 잡음을 묶은 벡터다. 목표 원신호를 $$S(t)$$, source에서 마이크 $$m$$까지의 room impulse response를 $$a_m(t)$$라 하면

$$
s_m(t)=(a_m*S)(t).
$$

Narrowband STFT 근사에서는 한 bin에서 convolution이 곱셈으로 바뀌어

$$
\mathbf s(t,f)=\mathbf a(f)S(t,f)
$$

가 된다. $$\mathbf a(f)\in\mathbb C^M$$는 source에서 모든 마이크까지의 복소 전달 벡터다. 고정된 room response를 포함할 수 있다는 점이 단순한 자유공간 DoA steering vector와 다르다. 단, 긴 room response가 여러 frame을 강하게 연결하거나 화자가 움직이면 이 한-frame 곱셈 근사가 정확하지 않을 수 있다.

## 4. 공간 공분산은 파워뿐 아니라 채널 사이의 위상도 담는다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-11.png" | relative_url }}" alt="Lecture 9 I slide 11: spatial second-moment magnitude and phase matrices for four microphones, with diagonal power and off-diagonal phase relationships" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=11" | relative_url }}" target="_blank" rel="noopener">slide 11</a>.</figcaption>
</figure>

그림에서 마이크 두 개의 스펙트로그램을 나란히 떠올려 보자. 먼저 두 마이크에서 **같은 프레임, 같은 주파수 칸**을 고른다. 한쪽 계수에 다른 쪽 계수의 복소켤레를 곱하면 두 채널의 위상차가 남는다. 다음 프레임에서도 **주파수 칸은 그대로** 두고 같은 계산을 반복해 복소 곱을 평균한다. 주파수끼리 비교하거나 위상각을 따로 산술평균하는 연산이 아니다. 이를 모든 마이크 쌍에 적용한 공간 행렬은

$$
\mathbf R(f)=E[\mathbf x\mathbf x^H]
\approx\frac1T\sum_{t=1}^{T}\mathbf x(t,f)\mathbf x(t,f)^H,\qquad
R_{ij}=E[X_iX_j^*]
$$

이다. 크기는 $$M\times M$$이고, 행과 열은 frequency가 아니라 microphone index다.

엄밀한 covariance는 평균 $$\boldsymbol\mu=E[\mathbf x]$$를 빼서 $$E[(\mathbf x-\boldsymbol\mu)(\mathbf x-\boldsymbol\mu)^H]$$로 정의한다. 강의의 $$E[\mathbf x\mathbf x^H]$$는 일반적으로 **uncentered second moment 또는 spatial correlation matrix**다. $$E[\mathbf x]=\mathbf0$$이면 covariance와 같아진다. Beamformer의 평균 출력 파워는 평균이 0이 아니어도 이 uncentered matrix로

$$
E[|y|^2]=E[\mathbf w^H\mathbf x\mathbf x^H\mathbf w]
=\mathbf w^H\mathbf R\mathbf w
$$

처럼 계산된다.

### 4.1 대각은 채널별 파워다

슬라이드 11에서 같은 대각 칸이 크기 그림에서는 **1.05**, 위상 그림에서는 **0°**다. 같은 마이크를 자기 자신과 비교하면 위상차는 사라지지만 파워는 사라지지 않는다. $$R_{ii}=E[\lvert X_i\rvert^2]$$이므로 1.05는 그 주파수에서의 평균 파워이고, 양의 실수인 그 값의 각도가 0°다. 파워 자체가 0이면 위상은 정의되지 않는다. 파워의 단위는 STFT 스케일에 따른 진폭의 제곱이며, 별도 보정 없이 $$\mathrm{W/m^2}$$로 읽지 않는다.

### 4.2 비대각은 정규화되지 않은 복소 관계다

$$R_{ij}=E[X_iX_j^*]$$는 두 채널의 cross-power를 나타낸다. 크기 $$\lvert R_{ij}\rvert$$는 함께 움직이는 성분의 세기, 각도 $$\angle R_{ij}$$는 평균 복소 위상 관계를 담는다. 그러나 $$R_{ij}$$ 자체는 0–1 similarity가 아니다. 채널 파워가 커지면 함께 커지고, 복소수일 수 있다.

행렬은 Hermitian이므로 $$R_{ji}=R_{ij}^*$$다. 따라서 magnitude 행렬은 주대각선에 대해 대칭이고, phase 행렬은 위·아래 삼각형의 부호가 반대다. Slide 11의 $$+21^\circ$$와 $$-21^\circ$$가 짝을 이루는 이유다.

### 4.3 위상에서 시간차를 읽을 때는 부호 조건을 고정한다

Forward Fourier convention을 $$X(\omega)=\int x(t)e^{-j\omega t}\,dt$$로 두고, $$i$$번째 마이크가 $$x_i(t)=S(t-\tau_i)$$를 받는다고 하자. 그러면

$$
X_i(\omega)=S(\omega)e^{-j\omega\tau_i}
$$

이고

$$
R_{ij}=E[X_iX_j^*]
=P_S e^{j\omega(\tau_j-\tau_i)},\qquad
\angle R_{ij}=\omega(\tau_j-\tau_i)\pmod{2\pi}.
$$

즉 강의의 부호는 **$$R_{ij}=E[X_iX_j^*]$$, 음의 지수 Fourier transform, $$\tau_i$$를 source가 마이크 $$i$$에 도달하는 지연으로 정의한 조건**에서 성립한다. Cross term 순서를 $$E[X_i^*X_j]$$로 바꾸거나 Fourier 부호를 바꾸면 위상 부호도 뒤집힌다. 또한 phase는 $$2\pi$$마다 감기므로 단일 주파수만으로 큰 시간차를 유일하게 정할 수 없다.

Slide 11의 $$d=4\ \mathrm{cm}$$, $$\theta=30^\circ$$, $$f=1\ \mathrm{kHz}$$와 음속 $$c=343\ \mathrm{m/s}$$를 사용하면 인접 마이크 시간차는

$$
\Delta\tau=\frac{d\sin\theta}{c}\approx58.31\ \mu\mathrm s
$$

이고, 위상차는 $$2\pi f\Delta\tau\approx20.99^\circ$$다. 슬라이드 11에서 **30°는 소리가 오는 방향**, **21°는 1 kHz 성분을 두 마이크에서 비교한 위상차**다.

같은 식에 2 kHz를 넣어 보면 두 각도의 차이가 드러난다. 도래각을 30°로 유지하면 두 마이크 사이의 시간차는 그대로다. 그 시간 동안 2 kHz 성분은 두 배만큼 진동하므로 위상차만 약 42°로 바뀐다.

<details markdown="block">
<summary markdown="span">Derivation: Matrix shape, Hermitian symmetry, and positive semidefiniteness</summary>

$$\mathbf x\in\mathbb C^{M\times1}$$이면 $$\mathbf x\mathbf x^H\in\mathbb C^{M\times M}$$다. 각 원소는 $$X_iX_j^*$$이고

$$
(\mathbf x\mathbf x^H)^H=\mathbf x\mathbf x^H.
$$

기댓값도 Hermitian 성질을 보존한다. 임의의 $$\mathbf z$$에 대해

$$
\mathbf z^H\mathbf R\mathbf z
=E[\mathbf z^H\mathbf x\mathbf x^H\mathbf z]
=E[|\mathbf x^H\mathbf z|^2]\ge0
$$

이므로 $$\mathbf R$$은 positive semidefinite다. 역행렬을 쓰려면 positive definite이거나, rank 부족을 보완하는 regularization이 필요하다.

</details>

## 5. Coherence는 채널 파워를 제거한 정규화 관계다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-12.png" | relative_url }}" alt="Lecture 9 I slide 12: target, diffuse-noise, and sensor-noise coherence patterns with eigenvalue distributions and the coherence formula" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=12" | relative_url }}" target="_blank" rel="noopener">slide 12</a>.</figcaption>
</figure>

두 채널의 complex coherence를

$$
\gamma_{ij}(f)=\frac{\Phi_{ij}(f)}
{\sqrt{\Phi_{ii}(f)\Phi_{jj}(f)}}
$$

로 정의한다. 분모는 두 채널의 파워 scale을 제거한다. $$\Phi_{ii}\Phi_{jj}>0$$이면 Cauchy–Schwarz 부등식에 따라 $$\lvert\gamma_{ij}\rvert\le1$$이다. 한 채널 파워가 0이면 이 정규화는 정의되지 않는다.

- $$\lvert\gamma_{ij}\rvert=1$$: 한 주파수에서 두 채널이 고정된 복소 gain 관계로 완전히 연결된 경우다.
- $$\lvert\gamma_{ij}\rvert\approx0$$: 선형 cross relation이 약한 경우다. 두 신호 사이에 어떤 관계도 전혀 없다는 보편적 증명은 아니다.
- $$\angle\gamma_{ij}=\angle\Phi_{ij}$$: 양의 실수 분모로 나누므로 phase 관계는 보존된다.

Slide 11처럼 대각이 1.05이고 비대각 magnitude가 1.00이면 $$\lvert\gamma_{ij}\rvert=1/1.05\approx0.952$$다. Off-diagonal이 1.00이라는 사실과 normalized coherence가 1이라는 주장은 다르다.

슬라이드 12의 확산 잡음은 한 방향에서만 오지 않는다. 방향마다 두 마이크 사이의 도달 시간차가 달라서, 채널 간 복소 곱을 평균하면 서로 다른 위상 성분이 일부 상쇄된다. 그림에서 가까운 마이크 쌍의 coherence 크기가 상대적으로 큰 이유다. 이 경향은 주파수와 마이크 간격에 따라 달라지며, 거리가 멀수록 언제나 작아진다는 법칙은 아니다.

### 5.1 혼합 공분산이 목표와 잡음의 합이 되는 조건

$$\mathbf x=\mathbf s+\mathbf n$$을 대입하면

$$
\begin{aligned}
\mathbf R_x
&=E[(\mathbf s+\mathbf n)(\mathbf s+\mathbf n)^H]\\
&=\boldsymbol\Phi_S+\boldsymbol\Phi_N
+E[\mathbf s\mathbf n^H]+E[\mathbf n\mathbf s^H].
\end{aligned}
$$

따라서 $$E[\mathbf s\mathbf n^H]=\mathbf0$$인 **uncorrelated 조건**에서만

$$
\mathbf R_x=\boldsymbol\Phi_S+\boldsymbol\Phi_N
$$

로 단순히 더해진다. 여기서는 평균을 빼지 않은 행렬을 썼으므로, 비상관이라는 말은 **평균을 뺀 뒤에만** 교차항이 0이라는 뜻으로 읽으면 안 된다. 예를 들어 목표와 잡음이 독립이면 교차항은 두 평균 벡터의 외적이다. 둘 중 하나의 평균이 0이어야 이 항도 0이 된다(두 평균이 모두 0인 경우 포함). 기댓값에서 교차항이 사라져도 유한한 프레임으로 추정한 값은 정확히 0이 아닐 수 있다.

### 5.2 목표 공분산이 rank one이 되는 정확한 조건

한 주파수에서

$$
\mathbf s(t,f)=\mathbf a(f)S(t,f)
$$

이고 분석 구간 동안 $$\mathbf a(f)$$가 고정되어 있으면

$$
\boldsymbol\Phi_S
=E[\mathbf s\mathbf s^H]
=E[|S|^2]\mathbf a\mathbf a^H
=\sigma_S^2\mathbf a\mathbf a^H.
$$

$$\sigma_S^2>0$$이고 $$\mathbf a\ne\mathbf0$$이면 rank는 1이다. 모든 snapshot이 복소 공간에서 같은 한 방향 $$\mathbf a$$ 위에 놓이고 scalar $$S(t,f)$$만 변하기 때문이다.

슬라이드 12의 히트맵은 **마이크 두 개가 얼마나 일관되게 함께 변하는지**, 고윳값 그림은 **서로 다른 채널 패턴에 파워가 얼마나 나뉘는지** 보여 준다.

**보충 예제:** 그림의 차이를 두 마이크로 단순화해 보자. 두 마이크에 똑같은 목표 신호가 들어오고 각각의 파워가 1이라면, 목표 공분산은 네 칸이 모두 1이어서 고윳값은 2와 0이다. 두 마이크의 합에는 목표가 남고 차에는 아무것도 남지 않는다. 반대로 각 마이크에 평균이 0이고 파워가 1인 비상관 센서 잡음만 있다면 대각만 1이고 비대각은 0이다. 고윳값은 1과 1이다. **비대각이 0이라는 말은 잡음 파워나 행렬의 rank가 0이라는 뜻이 아니다.** 여러 방향에서 오는 확산 잡음도 파워가 여러 패턴에 나뉠 수 있지만, 그 고윳값들이 모두 같아야 하는 것은 아니다.

Rank one은 자동으로 성립하지 않는다. 여러 독립 목표가 하나의 $$\boldsymbol\Phi_S$$에 포함되거나, 화자·마이크가 움직이거나, 전달 경로가 구간 안에서 변하거나, narrowband multiplicative model로 설명되지 않는 reverberant 성분이 크면 rank가 올라갈 수 있다. 반대로 고정된 reverberant transfer function은 $$\mathbf a(f)$$에 포함될 수 있다.

## 6. MWF는 기준 마이크의 목표에 대한 MSE를 최소화한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-13.png" | relative_url }}" alt="Lecture 9 I slide 13: multichannel Wiener filter block diagram, MSE objective, normal equation, and closed-form solution" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=13" | relative_url }}" target="_blank" rel="noopener">slide 13</a>.</figcaption>
</figure>

MWF(Multichannel Wiener Filter)는 출력 $$y=\mathbf w^H\mathbf x$$가 reference microphone $$r$$에서의 목표 $$s_r$$와 평균적으로 가장 가까워지게 한다.

여기서 $$M$$은 **입력으로 쓰는 마이크의 수**, $$r$$은 **복원 기준으로 삼는 마이크의 번호**다. 기준을 하나 골라도 필터는 모든 마이크를 쓴다. 복원하려는 것은 기준 마이크에 녹음된 혼합음 전체가 아니라, 그 위치에 도달한 목표 음성 성분이다.

$$
J(\mathbf w)=E[|s_r-\mathbf w^H\mathbf x|^2].
$$

$$\mathbf u_r=[0,\ldots,0,1,0,\ldots,0]^T$$를 reference channel 선택 벡터라 하면 $$s_r=\mathbf u_r^T\mathbf s$$다. Target과 noise가 uncorrelated일 때 cross-correlation vector는

$$
\mathbf p=E[\mathbf x s_r^*]
=E[(\mathbf s+\mathbf n)\mathbf s^H]\mathbf u_r
=\boldsymbol\Phi_S\mathbf u_r.
$$

정규방정식과 해는

$$
\mathbf R_x\mathbf w=\mathbf p,\qquad
\mathbf w_{\mathrm{MWF}}
=\mathbf R_x^{-1}\boldsymbol\Phi_S\mathbf u_r
=(\boldsymbol\Phi_S+\boldsymbol\Phi_N)^{-1}
\boldsymbol\Phi_S\mathbf u_r.
$$

MWF는 target distortion과 residual noise를 하나의 MSE 안에서 함께 조절한다. 단일 채널이면 $$H=\Phi_S/(\Phi_S+\Phi_N)$$인 Wiener gain으로 줄어든다. 낮은 SNR에서는 잡음을 더 줄이기 위해 목표 gain도 1보다 작게 만들 수 있다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-14.png" | relative_url }}" alt="14쪽 오른쪽: 초록색 목표에서 파란 출력 평면에 수선을 내리면, 파란 화살표의 끝이 최적 출력이고 빨간 점선이 남은 오차다." loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=14" | relative_url }}" target="_blank" rel="noopener">slide 14</a>.</figcaption>
</figure>

오른쪽의 파란 평면은 마이크가 놓인 바닥이 아니다. **마이크 신호들을 서로 다른 가중치로 합쳐 만들 수 있는 모든 출력**을 뜻한다. 초록색 목표의 끝에서 평면에 수선을 내리면 파란 화살표의 끝, 즉 목표에 가장 가까운 출력에 닿는다. 빨간 점선은 그래도 남는 오차다. 오차에 평면을 따라가는 성분이 남아 있다면 가중치를 바꿔 그만큼 더 줄일 수 있다. 그래서 최적점에서는 오차가 평면에 수직이다. 여기서 거리는 공간상의 미터가 아니라 신호 사이의 평균제곱오차로 비교한다. 왼쪽의 미분값을 0으로 놓는 계산도 바로 이 출력을 찾는다.

<details markdown="block">
<summary markdown="span">Derivation: MWF normal equation and orthogonality principle</summary>

오차를 $$e=s_r-\mathbf w^H\mathbf x$$라 두고 전개하면

$$
J(\mathbf w)
=E[|s_r|^2]-\mathbf w^H\mathbf p-\mathbf p^H\mathbf w
+\mathbf w^H\mathbf R_x\mathbf w.
$$

Complex vector에 대한 Wirtinger derivative를 사용하면

$$
\frac{\partial J}{\partial\mathbf w^*}
=-\mathbf p+\mathbf R_x\mathbf w.
$$

이를 0으로 두면 $$\mathbf R_x\mathbf w=\mathbf p$$다. 같은 조건은

$$
E[\mathbf x e^*]
=E[\mathbf x s_r^*]-E[\mathbf x\mathbf x^H]\mathbf w
=\mathbf p-\mathbf R_x\mathbf w
=\mathbf0
$$

로도 쓸 수 있다. 최적 오차가 관측으로 만들 수 있는 모든 선형 방향과 직교한다는 orthogonality principle이다. $$\mathbf R_x$$가 singular이면 inverse 해가 유일하지 않으므로 pseudo-inverse, loading 또는 더 많은 유효 snapshot이 필요하다.

</details>

## 7. MVDR는 목표 gain을 고정한 뒤 잡음만 최소화한다

Lecture 8의 steering-vector MVDR는

$$
\min_{\mathbf w}\ \mathbf w^H\boldsymbol\Phi_N\mathbf w
\qquad\text{subject to}\qquad
\mathbf w^H\mathbf h=b_0
$$

였다. 목표 방향의 응답을 고정한 뒤 출력 잡음 파워를 최소화한다. 문제는 실제 방에서 정확한 DoA와 steering vector를 얻기 어렵다는 점이다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-16.png" | relative_url }}" alt="Lecture 9 I slide 16: covariance-based Souden MVDR objective, distortionless target path, minimized noise path, and trace-normalized solution" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=16" | relative_url }}" target="_blank" rel="noopener">slide 16</a>.</figcaption>
</figure>

Souden 형태는 목표 공분산이 rank one일 때 DoA steering vector를 직접 계산하지 않고

$$
\mathbf w_{\mathrm{MVDR}}
=\frac{\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S}
{\operatorname{Tr}(\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S)}
\mathbf u_r
$$

를 사용한다. 필요한 공간 방향이 $$\boldsymbol\Phi_S$$ 안에 들어 있기 때문이다. `DoA-free`는 **DoA를 각도로 명시하지 않는다**는 뜻이며, 목표의 공간 정보가 필요 없다는 뜻이 아니다.

Rank-one 모델 $$\boldsymbol\Phi_S=\sigma_S^2\mathbf a\mathbf a^H$$를 대입하고 $$\widetilde{\mathbf a}=\mathbf a/a_r$$로 reference microphone에 대해 정규화하면

$$
\mathbf w_{\mathrm{MVDR}}
=\frac{\boldsymbol\Phi_N^{-1}\widetilde{\mathbf a}}
{\widetilde{\mathbf a}^H\boldsymbol\Phi_N^{-1}\widetilde{\mathbf a}}.
$$

따라서 $$\mathbf w^H\widetilde{\mathbf a}=1$$이고, $$\mathbf w^H\mathbf a=a_r$$다. 목표 $$\mathbf s=\mathbf aS$$에 적용하면 $$\mathbf w^H\mathbf s=a_rS=s_r$$이므로 reference microphone의 목표가 보존된다. $$a_r\ne0$$이어야 이 정규화가 가능하다.

<details markdown="block">
<summary markdown="span">Derivation: Trace-normalized covariance MVDR equals relative-transfer-vector MVDR</summary>

분자는

$$
\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S\mathbf u_r
=\sigma_S^2\boldsymbol\Phi_N^{-1}\mathbf a\mathbf a^H\mathbf u_r
=\sigma_S^2 a_r^*\boldsymbol\Phi_N^{-1}\mathbf a
$$

이고, 분모는 trace의 cyclic property로

$$
\operatorname{Tr}(\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S)
=\sigma_S^2\operatorname{Tr}(\boldsymbol\Phi_N^{-1}\mathbf a\mathbf a^H)
=\sigma_S^2\mathbf a^H\boldsymbol\Phi_N^{-1}\mathbf a
$$

이다. 두 식을 나누면

$$
\mathbf w
=\frac{a_r^*\boldsymbol\Phi_N^{-1}\mathbf a}
{\mathbf a^H\boldsymbol\Phi_N^{-1}\mathbf a}
=\frac{\boldsymbol\Phi_N^{-1}(\mathbf a/a_r)}
{(\mathbf a/a_r)^H\boldsymbol\Phi_N^{-1}(\mathbf a/a_r)}.
$$

Trace-normalized 식 자체는 일반적인 positive-semidefinite $$\boldsymbol\Phi_S$$에도 계산할 수 있다. 다만 위 식이 reference microphone의 목표를 왜곡 없이 보존하는 MVDR 제약과 동치이고, 하나의 relative transfer vector를 DoA 대신 사용한다고 해석할 수 있는 것은 single rank-one target와 invertible noise covariance 조건에서다. $$\boldsymbol\Phi_S$$가 higher rank이면 같은 하나의 distortionless steering constraint로 해석할 수 없다.

</details>

## 8. MWF와 MVDR는 rank-one 조건에서 같은 방향, 다른 gain을 가진다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-18.png" | relative_url }}" alt="Lecture 9 I slide 18: rank-one MWF and MVDR share a spatial direction, while a Wiener post-filter changes gain by lambda over one plus lambda" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=18" | relative_url }}" target="_blank" rel="noopener">slide 18</a>.</figcaption>
</figure>

$$
\lambda=\operatorname{Tr}(\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S)
$$

라 두면 rank-one target에서

$$
\mathbf w_{\mathrm{MVDR}}
=\frac{\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S}{\lambda}\mathbf u_r,\qquad
\mathbf w_{\mathrm{MWF}}
=\frac{\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S}{1+\lambda}\mathbf u_r.
$$

따라서

$$
\mathbf w_{\mathrm{MWF}}
=\frac{\lambda}{1+\lambda}\mathbf w_{\mathrm{MVDR}}.
$$

두 필터는 같은 spatial direction을 사용한다. MVDR는 reference target gain을 1로 고정하지만, MWF는 bin별 Wiener post-filter gain $$\lambda/(1+\lambda)$$를 추가한다. 이 gain은 MVDR 출력의 target과 noise를 함께 줄이는 MSE 해다. $$\lambda$$가 작을수록 더 강하게 감쇠하므로 절대 noise power는 줄지만 target distortion은 커지고, 항상 더 좋은 음질을 보장하지 않는다. Rank-one·uncorrelated·정확한 covariance 조건에서 $$\lambda$$는 MVDR 출력 target-to-noise power ratio와 같다.

11월 12일 **24:31**의 음성인식 예에서 중요한 것은 잡음이 가장 작은 출력과 **말을 가장 잘 알아볼 수 있는 출력**이 같지 않을 수 있다는 점이다. 추가 감쇠가 약한 말소리까지 줄이면 잡음이 덜 들려도 단어를 구별할 단서가 약해질 수 있다. 이 설명만으로 어느 필터의 단어 오류율이 더 낮다고 정할 수는 없다.

### 8.1 두 마이크 수치 예제

예를 들어, 다음 값을 사용해 식의 관계를 확인하자.

$$
\mathbf a=\begin{bmatrix}1\\0.8\end{bmatrix},\qquad
\boldsymbol\Phi_S=2\mathbf a\mathbf a^T,\qquad
\boldsymbol\Phi_N=\begin{bmatrix}1&0\\0&2\end{bmatrix},\qquad r=1
$$

을 사용하자. 그러면 $$\lambda=2.64$$이고

$$
\mathbf w_{\mathrm{MVDR}}
=\begin{bmatrix}0.757576\\0.303030\end{bmatrix},\qquad
\mathbf w_{\mathrm{MWF}}
=\begin{bmatrix}0.549451\\0.219780\end{bmatrix}.
$$

MVDR는 $$\mathbf w_{\mathrm{MVDR}}^T\mathbf a=1$$로 목표를 보존한다. 출력 잡음 파워는 약 0.757576, 출력 목표 파워는 2이므로 비는 2.64다. MWF의 목표 gain은 $$2.64/3.64\approx0.725275$$다. 두 weight의 성분 비는 같고 전체 gain만 다르다. 이 숫자는 강의의 성능 측정값이 아니라 식의 관계를 직접 확인한 예제다.

<details markdown="block">
<summary markdown="span">Derivation: Woodbury identity gives the MWF–MVDR gain relation</summary>

$$\boldsymbol\Phi_S=\sigma_S^2\mathbf a\mathbf a^H$$와 $$\mathbf R_x=\boldsymbol\Phi_N+\boldsymbol\Phi_S$$를 사용한다. Woodbury identity로

$$
(\boldsymbol\Phi_N+\sigma_S^2\mathbf a\mathbf a^H)^{-1}
=\boldsymbol\Phi_N^{-1}
-\frac{\sigma_S^2\boldsymbol\Phi_N^{-1}\mathbf a\mathbf a^H\boldsymbol\Phi_N^{-1}}
{1+\sigma_S^2\mathbf a^H\boldsymbol\Phi_N^{-1}\mathbf a}.
$$

오른쪽에 $$\boldsymbol\Phi_S\mathbf u_r$$를 곱하고 $$\lambda=\sigma_S^2\mathbf a^H\boldsymbol\Phi_N^{-1}\mathbf a$$를 사용하면

$$
\mathbf w_{\mathrm{MWF}}
=\frac{\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S}{1+\lambda}\mathbf u_r.
$$

Souden MVDR 식과 비교하면 gain 관계를 얻는다. 이 단순한 scalar 관계는 $$\boldsymbol\Phi_S$$가 rank one일 때의 결과다.

</details>

## 9. Mask 기반 ESD는 혼합 관측에서 공분산을 추정한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-21.png" | relative_url }}" alt="Lecture 9 I slide 21: multichannel encoder-separation-decoder flow from audio through STFT features, mask estimation, spatial filtering, and inverse STFT" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=21" | relative_url }}" target="_blank" rel="noopener">slide 21</a>.</figcaption>
</figure>

슬라이드의 ESD(Encoder–Separation–Decoder)는 아래 순서로 읽는다.

1. **Encoder:** 다채널 waveform을 STFT로 바꾸고 magnitude, phase 차이(IPD) 같은 feature를 만든다.
2. **Mask estimation model:** 각 time-frequency bin이 목표 또는 잡음 통계에 얼마나 기여할지 예측한다.
3. **Masking and covariance estimation:** 혼합 관측의 바깥곱에 mask weight를 적용한다.
4. **Compute spatial filter:** 추정한 $$\boldsymbol\Phi_S,\boldsymbol\Phi_N$$로 MWF 또는 MVDR weight를 계산한다.
5. **Separation and decoder:** 같은 spatial filter를 혼합 STFT에 적용하고 inverse STFT로 waveform을 복원한다.

그림의 왼쪽 skip path는 원래 복소 관측 $$\mathbf x$$가 최종 공간 필터 입력으로 다시 사용된다는 뜻이다. Feature나 mask만으로 waveform을 직접 합성하는 흐름과 다르다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-1/slide-23.png" | relative_url }}" alt="Lecture 9 I slide 23: speech and noise masks weight multichannel outer products to estimate target and noise covariance matrices" loading="lazy">
  <figcaption>Source: Lecture 9 I, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf#page=23" | relative_url }}" target="_blank" rel="noopener">slide 23</a>.</figcaption>
</figure>

Mask 기반 공분산은

$$
\widehat{\boldsymbol\Phi}_S(f)
=\frac{\sum_t m_S(t,f)\mathbf x(t,f)\mathbf x(t,f)^H}
{\sum_t m_S(t,f)},
$$

$$
\widehat{\boldsymbol\Phi}_N(f)
=\frac{\sum_t m_N(t,f)\mathbf x(t,f)\mathbf x(t,f)^H}
{\sum_t m_N(t,f)}
$$

처럼 계산한다. Mask는 **frame의 바깥곱에 주는 scalar weight**다. 채널별 phase를 없애지 않으므로 $$\mathbf x\mathbf x^H$$의 공간 관계가 남는다. 최종 출력도 여전히 $$y=\mathbf w^H\mathbf x$$인 선형 공간 필터다. 신경망은 필터 자체를 직접 출력하지 않을 수 있다.

마스크가 약한 음절 하나를 놓쳤다고 생각해 보자. 마스크를 최종 출력에 직접 곱하면 그 음절도 함께 약해진다. 반면 **공분산을 구할 때만 마스크를 쓰면**, 놓친 칸이 최종 입력에서 지워지지는 않는다. 같은 주파수의 다른 프레임에서 목표 화자가 충분히 강하고 마이크 사이의 전달 관계가 일정하다면, 남은 관측으로 목표의 공간 패턴을 추정해 원래 혼합음에 필터를 적용할 수 있다. 11월 12일 **31:01–32:35**에 강조한 차이다. 표본이 너무 적거나 다른 화자가 우세하면 이 이점은 보장되지 않는다.

### 9.1 두 snapshot의 mask 계산

한 주파수에서

$$
\mathbf x_1=\begin{bmatrix}1\\1\end{bmatrix},\qquad
\mathbf x_2=\begin{bmatrix}1\\-1\end{bmatrix}
$$

이고, speech mask가 $$(0.9,0.1)$$, noise mask가 $$(0.1,0.9)$$라고 하자. 각 mask 합은 1이므로

$$
\widehat{\boldsymbol\Phi}_S
=\begin{bmatrix}1&0.8\\0.8&1\end{bmatrix},\qquad
\widehat{\boldsymbol\Phi}_N
=\begin{bmatrix}1&-0.8\\-0.8&1\end{bmatrix}.
$$

두 행렬의 대각 파워는 같지만 비대각 부호가 다르다. 첫 패턴은 두 마이크가 같은 부호로, 둘째는 반대 부호로 움직이는 snapshot을 더 크게 반영한다. Mask가 단순한 음량 gate를 넘어 공간 필터에 필요한 채널 관계를 나누는 이유다. 두 행렬의 eigenvalue는 각각 0.2와 1.8로 양수이며, mask가 완전한 0/1이 아니어서 둘 다 rank 2다.

### 9.2 Mask 누출은 target cancellation을 만들 수 있다

Noise mask가 목표 음성이 강한 frame에 큰 weight를 주면 $$\widehat{\boldsymbol\Phi}_N$$ 안에 목표 방향이 들어간다. MVDR는 그 방향을 잡음으로 보고 낮추려 하므로 목표가 손상될 수 있다. 반대로 지나치게 많은 frame을 제외하면 유효 snapshot이 줄어 공분산이 불안정해진다. 따라서 보수적 mask는 누출을 줄이지만, 표본 수와 행렬 conditioning이라는 대가도 함께 본다.

Slide 23의 “soft masks $$m\in[0,1]$$ (IRM, PSM)”은 범위를 한데 묶은 단순화다. IRM과 sigmoid로 제한한 mask는 보통 0–1 범위를 쓰지만, 표준 phase-sensitive mask

$$
m_{\mathrm{PSM}}=\frac{|S|}{|X|}\cos(\angle S-\angle X)
$$

는 음수가 될 수 있고 $$\lvert X\rvert$$가 작으면 1을 넘을 수도 있다. 실제 시스템은 PSM을 truncate하거나 bounded parameterization을 사용할 수 있다. 공분산 weight로 음수 mask를 그대로 쓰면 positive-semidefinite 성질이 깨질 수 있으므로, **학습 target mask의 정의와 covariance weight의 허용 범위를 구분해야 한다.**

## 10. ICA·IVA, MWF·MVDR, mask 기반 방법의 연결

| 축 | ICA·IVA | MWF | MVDR | Mask 기반 MVDR |
|---|---|---|---|---|
| 필요한 핵심 정보 | source 독립성 | $$\mathbf R_x$$와 목표 cross-statistic | 목표 방향과 $$\boldsymbol\Phi_N$$ | mask로 추정한 $$\boldsymbol\Phi_S,\boldsymbol\Phi_N$$ |
| 목적 | 출력 source 간 독립성 | reference target MSE 최소화 | target distortionless 조건 아래 noise 최소화 | 혼합음만으로 MVDR 통계를 추정 |
| 목표 gain | scale ambiguity가 남을 수 있음 | SNR에 따라 감쇠 가능 | reference target 보존 | mask와 rank-one 추정이 정확할 때 보존 |
| 주요 실패 조건 | source dependence, 움직이는 mixing, bin alignment | covariance mismatch, 낮은 rank, 목표 통계 오류 | steering·covariance mismatch | mask leakage, 짧은 snapshot, unseen room·array |

이 방법들은 하나의 단순한 교체 순서가 아니다. ICA·IVA는 독립성을 직접 최적화하는 BSS이고, MWF·MVDR는 주어진 2차 통계로 선형 필터를 계산한다. Mask 모델은 MVDR를 대체하지 않고 **MVDR가 요구하는 통계를 혼합음에서 추정하는 구성 요소**로 결합될 수 있다. 다음 강의의 end-to-end 방법은 이 경계를 더 학습 가능한 구조로 옮긴다.

## 마지막 핵심 정리

| 개념 | 남겨야 할 결론 |
|---|---|
| Frequency-domain ICA | Bin별 독립 분리는 source order가 자유로워 permutation 문제가 생긴다. |
| IVA | 같은 source의 주파수들을 한 vector로 결합해 binwise permutation을 함께 다룬다. 전역 출력 label은 여전히 임의다. |
| $$E[\mathbf x\mathbf x^H]$$ | 평균을 빼지 않은 2차 모멘트다. 영평균이면 covariance와 같고, 출력 평균 파워를 직접 계산한다. |
| 대각·비대각 | 대각은 채널별 파워, 비대각은 정규화되지 않은 복소 cross-power다. Phase 부호는 Fourier와 cross-term convention에 의존한다. |
| Coherence | 채널 파워를 제거한 정규화 관계다. Magnitude는 0–1이지만 원래 비대각 원소는 그렇지 않다. |
| Rank-one target | $$\mathbf s=\mathbf aS$$와 고정 $$\mathbf a$$에서 성립한다. 여러 source·움직임·모델 mismatch는 rank를 높일 수 있다. |
| MWF | Reference target MSE를 최소화해 목표 distortion과 noise를 함께 줄인다. |
| MVDR | Target gain을 고정한 뒤 noise power를 최소화한다. Rank-one target covariance로 DoA 없이 같은 방향을 얻을 수 있다. |
| Mask-based MVDR | Mask는 공분산의 frame weight다. Noise mask의 speech leakage는 target cancellation을 일으킬 수 있다. |

## Study Guide

먼저 slide 11의 행렬을 읽으며 대각과 비대각을 구분한다. 표시된 $$4\ \mathrm{cm}$$, $$30^\circ$$, $$1\ \mathrm{kHz}$$로 인접 위상차 $$21^\circ$$를 계산하고, Fourier 부호나 cross term 순서를 바꾸면 왜 부호가 뒤집히는지 확인한다. 이어 slide 12에서 raw off-diagonal과 coherence를 구분하고, $$\mathbf R_x=\boldsymbol\Phi_S+\boldsymbol\Phi_N$$에 cross term이 사라지는 조건을 직접 전개한다.

다음으로 slide 13–18을 연속해서 본다. MWF의 정답은 reference target이고, MVDR의 정답은 target gain 제약이다. 두 목적함수가 다른데도 rank-one 조건에서 spatial direction이 같은 이유를 trace 식과 Woodbury 식으로 확인한다. 마지막으로 slide 21–23에서 mask가 최종 waveform에 직접 곱해지는지, 공분산 추정에 weight로 쓰이는지 구분한다. 이 강의에서는 후자가 핵심이다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Can $$E[\mathbf x\mathbf x^H]$$ always be called a covariance matrix?</summary>

답변: 엄밀히는 아니다. 평균을 빼지 않은 uncentered second moment다. $$E[\mathbf x]=\mathbf0$$이면 covariance와 같다. Beamformer 출력의 평균 제곱은 uncentered matrix로 바로 계산된다.

</details>

<details markdown="block">
<summary markdown="span">2. Does the phase of $$R_{ij}$$ always give the time-delay sign in the same way?</summary>

답변: 아니다. $$R_{ij}=E[X_iX_j^*]$$, forward transform의 음의 지수, $$x_i(t)=S(t-\tau_i)$$를 함께 사용할 때 $$\angle R_{ij}=\omega(\tau_j-\tau_i)$$다. Fourier 부호나 cross term 순서를 바꾸면 부호가 반대가 된다. Phase wrapping도 고려해야 한다.

</details>

<details markdown="block">
<summary markdown="span">3. Why do the target and noise covariance matrices add?</summary>

답변: $$\mathbf x=\mathbf s+\mathbf n$$을 바깥곱하면 목표·잡음 항 외에 두 cross term도 생긴다. $$E[\mathbf s\mathbf n^H]=\mathbf0$$인 uncorrelated 조건에서만 cross term이 사라져 $$\mathbf R_x=\boldsymbol\Phi_S+\boldsymbol\Phi_N$$가 된다.

</details>

<details markdown="block">
<summary markdown="span">4. What conditions make the target covariance rank one?</summary>

답변: 한 주파수에서 모든 frame의 목표 벡터가 고정된 전달 벡터 $$\mathbf a$$와 scalar source $$S(t,f)$$의 곱이어야 한다. Source power가 양수이고 $$\mathbf a\ne\mathbf0$$이면 $$\boldsymbol\Phi_S=\sigma_S^2\mathbf a\mathbf a^H$$의 rank가 1이다. 여러 목표, 움직임, 시간에 따라 변하는 전달 경로는 이 조건을 깰 수 있다.

</details>

<details markdown="block">
<summary markdown="span">5. What is the main difference between MWF and MVDR?</summary>

답변: MWF는 reference target과 출력의 MSE를 줄여 distortion과 noise를 함께 조절한다. MVDR는 target gain을 먼저 고정하고 남은 noise power만 최소화한다. Rank-one target에서는 같은 spatial direction을 쓰지만 MWF에 $$\lambda/(1+\lambda)$$ gain이 추가된다.

</details>

<details markdown="block">
<summary markdown="span">6. Does DoA-free covariance-based MVDR require no spatial information?</summary>

답변: 아니다. 목표의 상대 전달 방향은 rank-one $$\boldsymbol\Phi_S$$의 주된 eigenspace 안에 들어 있다. 각도로 된 DoA와 이상적 steering vector를 직접 계산하지 않을 뿐, 정확한 목표·잡음 공간 통계가 필요하다.

</details>

<details markdown="block">
<summary markdown="span">7. Is the mask multiplied directly into the final output in mask-based beamforming?</summary>

답변: 이 강의의 핵심 구조에서는 mask를 $$\mathbf x\mathbf x^H$$의 frame weight로 사용해 $$\boldsymbol\Phi_S$$와 $$\boldsymbol\Phi_N$$를 추정한다. 그다음 계산한 $$\mathbf w$$를 원래 복소 혼합 관측에 적용한다. 최종 연산은 $$y=\mathbf w^H\mathbf x$$다.

</details>

<details markdown="block">
<summary markdown="span">8. Are all soft masks bounded between zero and one?</summary>

답변: 아니다. IRM이나 sigmoid 출력은 보통 0–1이지만, 표준 PSM은 phase cosine과 magnitude ratio 때문에 음수이거나 1보다 클 수 있다. Truncation한 PSM과 원래 PSM을 구분해야 하며, 공분산의 nonnegative weight로 쓸 mask의 범위도 별도로 정해야 한다.

</details>

## PDF

- <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-1.pdf" | relative_url }}" target="_blank" rel="noopener">speech-audio-lecture-09-1.pdf</a>

## References

- 안인규(Inkyu An), *Multi-channel Source Separation 2-1*, Speech and Audio Recognition, slides 1–24. 본문의 작은 수치 예제와 상세 유도는 이해를 위한 보충 해설이다.
- Mehrez Souden, Jacob Benesty, and Sofiène Affes, <a href="https://doi.org/10.1109/TASL.2009.2025790" target="_blank" rel="noopener">On Optimal Frequency-Domain Multichannel Linear Filtering for Noise Reduction</a>, *IEEE/ACM Transactions on Audio, Speech, and Language Processing*, 2010.
- Atsuo Hiroe, <a href="https://doi.org/10.1007/11679363_75" target="_blank" rel="noopener">Solution of Permutation Problem in Frequency Domain ICA, Using Multivariate Probability Density Functions</a>, ICA 2006.
- Jahn Heymann, Lukas Drude, and Reinhold Haeb-Umbach, <a href="https://groups.uni-paderborn.de/nt/pubs/2016/icassp_2016_heymann_paper.pdf" target="_blank" rel="noopener">Neural Network Based Spectral Mask Estimation for Acoustic Beamforming</a>, ICASSP 2016.
- Hakan Erdogan, John R. Hershey, Jonathan Le Roux, and Shinji Watanabe, <a href="https://doi.org/10.1109/ICASSP.2015.7178068" target="_blank" rel="noopener">Phase-Sensitive and Recognition-Boosted Speech Separation Using Deep Recurrent Neural Networks</a>, ICASSP 2015.
