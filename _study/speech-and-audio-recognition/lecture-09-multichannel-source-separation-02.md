---
layout: default
date: 2026-11-17 00:05:01 +0900
last_modified_at: 2026-11-23 16:50:19 +0900
title: "Lecture 9: Multi-channel Source Separation II"
course: "Speech and Audio Recognition"
topic: "Neural Beamforming and Complex Spectral Mapping"
order: 13
major_topic: "Speech and Audio Processing"
keywords:
  - "Neural Beamforming"
  - "Mask Estimation"
  - "Multi-channel ASR"
  - "Beam-TasNet"
  - "TF-GridNet"
  - "SpatialNet"
  - "Complex Spectral Mapping"
---

# Lecture 9: Multi-channel Source Separation II

Source PDF: `speech-audio-lecture-09-2.pdf` — *Multi-channel Source Separation 2-2*, 안인규(Inkyu An), 25 slides.

> **핵심:** 다채널 신경망의 출력은 mask, 공간 필터, 복소 spectrum 중 하나일 수 있다. 초기 방법은 mask로 공분산과 beamformer를 계산했고, 이후 방법은 시간영역 필터나 복소 STFT를 직접 추정했다. 최근 방법은 직접 추정의 표현력과 선형 필터의 낮은 왜곡을 결합한다. 성능표는 **입력 채널 수, 데이터셋, 출력 표현, 후단 ASR, 평가 지표**가 같은 조건인지 먼저 확인한다.

이 글은 각 주파수 bin의 다채널 STFT snapshot을 $$\mathbf x_{t,f}=[X_{1,t,f},\ldots,X_{M,t,f}]^T\in\mathbb C^M$$로 둔다. $$M$$은 마이크 수, $$T$$는 frame 수, $$F$$는 주파수 bin 수, $$C$$ 또는 $$P$$는 분리할 화자 수다. STFT 값과 그 추정치는 원 신호와 STFT 정규화에 따른 amplitude 단위를 가지며, mask와 attention weight는 무차원이다.

슬라이드 2–11은 IPD 같은 공간 특징, mask 기반 beamforming, 인식 loss를 앞단까지 전달하는 학습, MIMO-Speech의 출력 할당을 연결한다. 이후 슬라이드는 시간영역 필터와 직접 complex mapping으로 범위를 넓힌다. 두 범위를 읽을 때는 mask·공간 필터·최종 분리 출력의 역할을 섞지 않는 것이 핵심이다.

## 1. 다채널 ESD에서 신경망이 맡을 수 있는 위치

슬라이드 2의 encoder–separation–decoder(ESD)는 다채널 분리를 네 질문으로 나눈다.

1. **Encoder:** waveform을 그대로 쓸지, STFT의 magnitude·실수부·허수부·채널 간 위상차를 쓸지 정한다.
2. **Mask estimator:** 목표·간섭을 구분하는 시간–주파수 weight를 추정할 수 있다.
3. **Spatial filter:** mask로 공간 통계를 만들거나, 신경망이 필터 계수를 직접 낼 수 있다.
4. **Decoder:** 복소 spectrum 또는 학습된 representation을 waveform으로 되돌린다.

따라서 `deep learning-based`라는 말만으로 출력이 mask인지 waveform인지 알 수 없다. 같은 입력도 mask-derived beamformer, time-domain filter, complex spectral mapping으로 이어질 수 있다. 반대로 IPD를 입력에 쓴다는 사실은 출력 위상을 직접 추정한다는 뜻이 아니다.

### 1.1 IPD는 covariance의 위상과 항상 같지 않다

슬라이드 3의 interchannel phase difference를 이 글에서는

$$
\operatorname{IPD}_{ij,t,f}=\angle\!\left(X_{i,t,f}X_{j,t,f}^{*}\right)
$$

로 쓴다. $$X_j\ne0$$이면 $$\angle(X_i/X_j)$$와 같다. 한편 cross-spectrum 또는 공간 상관 원소는

$$
R_{ij,f}=E_t[X_{i,t,f}X_{j,t,f}^{*}]
$$

다. **$$\angle R_{ij,f}$$는 복소 cross-product를 frame에 걸쳐 평균한 뒤 얻은 위상**이다. 개별 frame IPD나 IPD의 산술평균과 일반적으로 같지 않다. 한 narrowband 점음원이 우세하고 전달함수 비가 구간에서 고정되며 다른 성분이 비상관이라는 조건에서는 두 값이 같은 채널 지연·steering phase를 나타낼 수 있다. 여러 화자·잔향·잡음이 섞이면 그 단순한 등식은 깨진다.

<details markdown="block">
<summary markdown="span">Derivation: When IPD and cross-spectrum phase agree</summary>

한 음원의 모델을 $$X_i=a_iS$$, $$X_j=a_jS$$로 두면

$$
X_iX_j^*=a_ia_j^*\lvert S\rvert^2,
\qquad
R_{ij}=a_ia_j^*E[\lvert S\rvert^2].
$$

$$E[\lvert S\rvert^2]>0$$이므로 두 식의 위상은 모두 $$\angle(a_ia_j^*)$$다. 이는 한 coherent source와 고정된 전달함수라는 조건에서의 정확한 등식이다.

반대로 두 frame의 cross-product가 각각 $$4e^{j60^\circ}$$와 $$e^{-j60^\circ}$$라면 IPD 산술평균은 $$0^\circ$$지만, 복소 평균의 위상은 약 $$46.1^\circ$$다. 큰 magnitude의 frame이 cross-spectrum에 더 큰 영향을 주기 때문이다. 또한 $$X_iX_j^*$$와 $$X_jX_i^*$$는 서로 켤레이므로 index 순서를 바꾸면 부호도 바뀐다.

</details>

## 2. Mask-based beamforming은 분류와 선형 필터를 분리한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-05.png" | relative_url }}" alt="Lecture 9 II slide 5: shared BLSTM estimates per-channel speech and noise masks, a median combines masks, and speech and noise PSD matrices feed a GEV beamformer and ASR" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=5" | relative_url }}" target="_blank" rel="noopener">slide 5</a>.</figcaption>
</figure>

Heymann·Drude·Haeb-Umbach의 ICASSP 2016 방법은 채널마다 같은 BLSTM을 적용해 speech mask $$m^S_{t,f}$$와 noise mask $$m^N_{t,f}$$를 추정한다. 공유 가중치를 쓰므로 network parameter 자체는 특정 마이크 번호에 묶이지 않는다. 채널별 mask의 median을 취한 뒤, **모든 마이크의 복소 관측 $$\mathbf x_{t,f}$$**로 speech/noise PSD 행렬을 만든다.

$$
\widehat{\boldsymbol\Phi}^{S}_{f}
=\frac{\sum_t m^{S}_{t,f}\mathbf x_{t,f}\mathbf x_{t,f}^{H}}
{\sum_t m^{S}_{t,f}},
\qquad
\widehat{\boldsymbol\Phi}^{N}_{f}
=\frac{\sum_t m^{N}_{t,f}\mathbf x_{t,f}\mathbf x_{t,f}^{H}}
{\sum_t m^{N}_{t,f}}.
$$

입력 $$\mathbf x_{t,f}$$는 $$M\times1$$, outer product와 각 PSD는 $$M\times M$$, mask는 scalar다. 분모가 0이면 정의되지 않으므로 실제 구현은 작은 안정화 값이나 frame 선택 규칙이 필요하다. Mask 값은 신호를 바로 복원하는 출력이 아니라 **어떤 frame을 speech/noise 통계에 크게 반영할지 정하는 weight**다.

슬라이드의 GEV beamformer는 다음 generalized Rayleigh quotient를 최대화한다.

$$
\mathbf w_{\mathrm{GEV},f}
=\arg\max_{\mathbf w\ne\mathbf0}
\frac{\mathbf w^H\boldsymbol\Phi^S_f\mathbf w}
{\mathbf w^H\boldsymbol\Phi^N_f\mathbf w}.
$$

이는 출력 speech-to-noise power ratio를 크게 하는 generalized eigenvector 문제다. Scale이 정해지지 않으므로 post-filter 또는 normalization이 함께 필요하다. DNN은 filter coefficient를 직접 회귀하지 않고, filter가 사용할 통계를 만든다. 원 논문의 핵심 기여도 **마이크 수·기하를 network 입력 구조에 고정하지 않고 mask로 CPSD를 추정하는 방식**에 있다.

<details markdown="block">
<summary markdown="span">Derivation: From a mask to the GEV eigenproblem</summary>

분모가 양수인 구간에서 $$\mathbf w^H\boldsymbol\Phi^N\mathbf w=1$$로 scale을 고정하면, Lagrangian은

$$
\mathcal L=\mathbf w^H\boldsymbol\Phi^S\mathbf w
-\lambda(\mathbf w^H\boldsymbol\Phi^N\mathbf w-1)
$$

이다. 복소 벡터에 대해 $$\mathbf w^*$$로 미분하면

$$
\boldsymbol\Phi^S\mathbf w
=\lambda\boldsymbol\Phi^N\mathbf w
$$

를 얻는다. 가장 큰 generalized eigenvalue의 eigenvector가 quotient를 최대화한다. $$\boldsymbol\Phi^N$$이 singular하면 generalized eigenproblem도 불안정할 수 있어 PSD 추정 구간과 loading이 중요하다.

</details>

## 3. Differentiable MVDR는 ASR loss를 mask까지 전달한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-07.png" | relative_url }}" alt="Lecture 9 II slide 7: multichannel end-to-end ASR architecture with speech and noise mask BLSTMs, PSD matrices, channel attention, and the differentiable Souden MVDR filter formula" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=7" | relative_url }}" target="_blank" rel="noopener">slide 7</a>.</figcaption>
</figure>

Ochiai 등 ICML 2017은 mask estimation, PSD, beamforming, feature extraction, attention-based ASR를 하나의 계산 그래프로 묶었다. 필터는 강의 표기의 Souden 형태다.

$$
\mathbf g_f
=\frac{(\boldsymbol\Phi_f^N)^{-1}\boldsymbol\Phi_f^S}
{\operatorname{Tr}((\boldsymbol\Phi_f^N)^{-1}\boldsymbol\Phi_f^S)}\mathbf u.
$$

$$\mathbf u\in\mathbb R^M$$는 기준 채널 선택 vector다. One-hot이면 특정 reference microphone을 고르고, 논문의 channel attention은 soft weight로 선택을 학습한다. 출력 $$\widehat X_{t,f}=\mathbf g_f^H\mathbf x_{t,f}$$는 reference-channel target image에 맞춘 scalar complex STFT다.

이 식의 matrix solve, 곱, trace, normalization은 미분 가능하다. 따라서 ASR loss의 gradient가 beamformer와 mask network까지 전달된다. 이는 mask가 이상적인 binary mask를 그대로 재현해야 한다는 학습 목표와 다르다. **최종 ASR에 유용한 PSD와 beamformed feature를 만드는 방향**으로 mask가 바뀔 수 있다.

작은 예로 ASR loss가 특정 자음 구간의 오류를 크게 만든다면, 그 구간을 speech PSD에서 더 잘 보존하는 mask 변화가 gradient를 받을 수 있다. 다만 end-to-end 학습이 waveform 품질이나 perceptual quality를 자동 보장하지는 않는다. 학습 objective가 ASR이면 평가도 WER/CER와 신호 지표를 나누어 봐야 한다.

<details markdown="block">
<summary markdown="span">Derivation: Why the trace normalization fixes scale</summary>

$$\mathbf A=(\boldsymbol\Phi^N)^{-1}\boldsymbol\Phi^S$$라 두면 $$\mathbf g=\mathbf A\mathbf u/\operatorname{Tr}(\mathbf A)$$다. Speech PSD가 $$\boldsymbol\Phi^S=\sigma_s^2\mathbf h\mathbf h^H$$인 rank-one 모델이고 $$\mathbf u$$가 reference channel을 고르면

$$
\mathbf A\mathbf u
=\sigma_s^2\mathbf R_n^{-1}\mathbf h\,h_r^*,
\qquad
\operatorname{Tr}(\mathbf A)
=\sigma_s^2\mathbf h^H\mathbf R_n^{-1}\mathbf h.
$$

따라서 $$\mathbf g$$는 steering-vector MVDR에 reference-channel transfer $$h_r^*$$를 곱한 형태가 된다. 이 해석은 rank-one target PSD와 invertible noise PSD 조건에 의존한다. 일반적인 reverberant full-rank speech PSD에서는 단순 steering vector 공식과 완전히 같다고 둘 수 없다.

</details>

## 4. MIMO-Speech는 화자별 beamforming과 ASR의 순서를 PIT로 맞춘다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-09.png" | relative_url }}" alt="Lecture 9 II slide 9: MIMO-Speech masking network creates speaker-specific masks, MVDR filtering produces enhanced streams, and CTC permutation invariant training aligns them to two ASR outputs" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=9" | relative_url }}" target="_blank" rel="noopener">slide 9</a>.</figcaption>
</figure>

다화자 분리에는 출력 순서가 없다. 두 output stream이 각각 화자 A/B를 내더라도 network가 A를 첫 번째로 고정할 이유가 없다. MIMO-Speech는 화자별 mask로 화자별 PSD와 MVDR 출력을 만들고, CTC loss가 가장 작은 output–transcript permutation을 선택한다.

화자가 $$C$$명일 때 permutation 집합을 $$\mathcal P_C$$라 하면 핵심 기준은

$$
\mathcal L_{\mathrm{PIT}}
=\min_{\pi\in\mathcal P_C}
\sum_{c=1}^{C}\mathcal L_{\mathrm{CTC}}(\widehat{\mathbf y}_c,\mathbf l_{\pi(c)}).
$$

입력은 $$M$$채널 mixture, mask network 출력은 noise와 화자별 mask, beamformer 출력은 $$C$$개의 복소 STFT, ASR 출력은 $$C$$개의 token sequence다. PIT는 beamformer가 아니라 **출력과 정답의 할당 규칙**이다. Mask estimation, spatial filtering, ASR decoding과 같은 종류의 모델 블록으로 혼동하면 안 된다.

슬라이드 11의 spatialized WSJ1-2mix 2화자 표에서 dev WER는 1채널 ASR 34.98%, BeamformIt 26.61%, MIMO-Speech with curriculum learning 12.59%다. Eval은 각각 29.43%, 21.75%, 7.55%다. 이는 같은 표 안의 조건에서 다채널 분리와 joint ASR의 이점을 보여 준다. 다른 데이터셋·후단 recognizer의 WER와 직접 순위를 매길 수는 없다.

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=10" | relative_url }}" target="_blank" rel="noopener">10쪽의 두 화자 그림</a>은 왼쪽의 혼합음, 오른쪽 위의 화자별 마스크, 오른쪽 아래의 분리된 음성 순서로 읽는다. 위 칸의 색은 **공분산 추정에 얼마나 반영할지 정한 가중치**이고, 아래 칸은 **공간 필터를 적용한 뒤 남은 음성**이다. 위쪽 마스크에서 음절 윤곽이 또렷하지 않아도 아래쪽 두 출력의 시간·주파수 패턴은 다를 수 있다. 그림만으로 인식 정확도까지 알 수는 없다.

그 차이를 평가할 때 쓰는 값이 **WER(단어 오류율)**다. 최종 전사에서 틀리거나 빠지거나 추가된 단어 수를 기준 전사의 단어 수와 비교한다. 반면 학습할 때는 완성된 문자열의 WER를 그대로 역전파하지 않는다. 이 모델에서는 CTC가 프레임별 점수로부터 정답 전사에 맞는 정렬들의 확률을 합산하므로, 두 출력에 어느 전사를 대응시킬지 비교하고 인식 오류의 학습 신호를 앞단에 전달할 수 있다.

## 5. FaSNet은 시간영역의 adaptive filter를 직접 예측한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-12.png" | relative_url }}" alt="Lecture 9 II slide 12: FaSNet first denoises a reference microphone and then uses the reference representation to estimate filters for all channels before summing filtered signals" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=12" | relative_url }}" target="_blank" rel="noopener">slide 12</a>.</figcaption>
</figure>

FaSNet은 STFT mask와 PSD를 거치지 않고, frame마다 마이크별 시간영역 FIR filter $$w_m(\tau)$$를 예측해 filter-and-sum을 수행한다.

$$
\widehat s_r(t)=\sum_{m=1}^{M}\sum_{\tau=0}^{L-1}w_m(t,\tau)x_m(t-\tau).
$$

입력은 $$M\times T$$ waveform, frame별 filter는 대략 $$M\times L$$ coefficient, 출력은 한 target waveform이다. 첫 단계는 reference channel에서 target clue를 만들고, 둘째 단계는 그 clue와 다른 채널의 관계를 이용해 나머지 filter를 정한다. 고정 지연만 보상하는 DAS와 달리 filter가 내용과 frame에 따라 바뀐다.

저자들이 해결하려 한 문제는 큰 future context를 요구하는 기존 neural beamformer의 latency다. 두 단계 설계는 selected reference를 먼저 안정화하고 나머지 채널을 조건부 처리한다. 그러나 low-latency는 zero-latency가 아니며, frame 길이·filter 길이·network look-ahead가 실제 지연을 결정한다.

## 6. Beam-TasNet은 DNN 출력을 통계로 쓰고 mixture를 다시 필터링한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-13.png" | relative_url }}" alt="Lecture 9 II slide 13: MC-Conv-TasNet estimates multichannel source images, their covariance matrices determine an MVDR filter, and the filter is applied to the original multichannel mixture" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=13" | relative_url }}" target="_blank" rel="noopener">slide 13</a>.</figcaption>
</figure>

Beam-TasNet의 중요한 연결은 파란 화살표다. MC-Conv-TasNet이 모든 마이크의 화자 $$k$$ source image $$\widehat{\mathbf z}_{k,t}$$를 추정하지만, 최종 waveform으로 그대로 내지 않는다. STFT domain에서

$$
\widehat{\boldsymbol\Phi}_{S,k}
=\frac1T\sum_t\widehat{\mathbf z}_{k,t}\widehat{\mathbf z}_{k,t}^{H},
\qquad
\widehat{\boldsymbol\Phi}_{N,k}
=\frac1T\sum_t(\mathbf x_t-\widehat{\mathbf z}_{k,t})
(\mathbf x_t-\widehat{\mathbf z}_{k,t})^H
$$

를 만든 뒤, 그 통계로 구한 MVDR를 원 mixture $$\mathbf x$$에 적용한다. 모든 마이크의 source image가 필요한 이유는 $$M\times M$$ 공간 PSD를 만들기 위해서다. 화자별 channel output의 permutation도 맞아야 outer product가 한 화자의 공간 이미지를 나타낸다.

이 설계는 DNN의 비선형 추정 오차를 평균된 통계로 바꾸고, 마지막 출력은 mixture의 선형 결합으로 제한한다. 따라서 ASR에 해로운 artificial distortion을 줄일 가능성이 있다. 그러나 averaging이 systematic source leakage까지 자동으로 없애지는 않으며, 잘못된 $$\widehat{\mathbf z}_k$$는 PSD와 filter를 함께 오염시킨다.

슬라이드 13의 12.7 dB/21.8%는 DNN source estimate, 17.2 dB/14.0%는 **Chen 등의 Interspeech 2022 non-causal MIMSO Beam-TasNet 재구현에서 그 추정으로 만든 MVDR output**이다. 원 ICASSP 2020 표의 수치가 아니다. 같은 row 안에서 두 출력을 비교하면 SDR은 4.5 dB 높고 WER는 7.8%p 낮다. 다른 논문의 수치와 직접 합치지 않는다. 후속 Beam-Guided TasNet은 MVDR 출력을 다시 DNN에 넣는 반복 구조로, 같은 실험 보고에서 baseline보다 4.1 dB 높은 21.5 dB SDR을 제시한다.

## 7. 출력 자유도가 커질수록 위상 수정 범위도 커진다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-16.png" | relative_url }}" alt="Lecture 9 II slide 16: four output families from a real mask through mask-derived and learned linear filters to nonlinear direct mapping, with increasing output freedom and decreasing linear distortion guarantees" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=16" | relative_url }}" target="_blank" rel="noopener">slide 16</a>.</figcaption>
</figure>

이 슬라이드는 방법을 연대순으로 나열한 표가 아니라 **network output의 자유도**를 비교한다.

| 출력 종류 | 실제 연산 | 위상 자유도 | 남는 조건 |
|---|---|---|---|
| Non-negative real magnitude mask | $$\widehat S=m\lvert X_r\rvert e^{j\angle X_r}$$, $$m\ge0$$ | 기준 mixture phase를 유지 | 정답 magnitude mask를 써도 phase mismatch가 남는다. |
| Mask-derived spatial filter | mask → PSD → $$\mathbf w_f^H\mathbf x_{t,f}$$ | 다채널 선형 결합이 위상을 바꿀 수 있음 | 한 bin에서 구간 동안 같은 filter를 쓰는 경우가 많다. |
| Learned filter | $$\sum_\tau\mathbf w(t,\tau)^H\mathbf x(t-\tau)$$ | time-varying·multi-frame 선형 결합 | 선형 filter 범위 안에서만 출력한다. |
| Direct mapping | $$\widehat S=f_\theta(\mathbf x)$$ | target complex spectrum을 직접 추정 | 비선형 artifact와 일반화 실패 가능성을 별도 평가해야 한다. |

예를 들어 기준 microphone의 mixture가 $$X_r=2e^{j30^\circ}$$이고 target이 $$S=e^{-j20^\circ}$$라면, non-negative real magnitude mask $$m=0.5$$는 magnitude를 1로 맞춰도 출력 위상은 $$30^\circ$$다. Signed real phase-sensitive mask는 음수일 때 $$\pi$$만큼 뒤집을 수 있지만 임의의 target phase를 자유롭게 정하지는 못한다. Complex mask 또는 direct complex estimate는 $$-20^\circ$$를 낼 수 있다. 이 추가 자유도가 항상 더 좋은 결과를 보장하지는 않는다. 학습 데이터 밖에서 위상을 잘못 바꾸면 선형 distortionless filter보다 ASR가 나빠질 수 있다.

## 8. TF-GridNet은 복소 스펙트럼을 직접 추정하고 beamformer와도 결합한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-18.png" | relative_url }}" alt="Lecture 9 II slide 18: TF-GridNet block with intra-frame full-band, sub-band temporal, and cross-frame self-attention modules, mapping real and imaginary multichannel inputs to target complex spectra" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=18" | relative_url }}" target="_blank" rel="noopener">slide 18</a>.</figcaption>
</figure>

TF-GridNet은 모든 마이크 STFT의 real/imaginary part를 쌓은 $$2M\times T\times F$$ 입력에서 reference microphone target의 real/imaginary part를 직접 추정한다. 한 block은 세 축의 관계를 나눈다.

- **Intra-frame full-band module:** 한 frame 안에서 주파수 bin 사이의 전역 관계를 본다.
- **Sub-band temporal module:** 한 주파수 주변의 sub-band feature를 시간축으로 처리한다. 고정 bin에서 채널 관계가 시간에 걸쳐 유지되는 공간 단서를 사용할 수 있다.
- **Cross-frame self-attention:** 멀리 떨어진 frame끼리 직접 정보를 교환한다.

DasFormer도 시간축과 주파수축 attention을 번갈아 적용하지만, 같은 모델의 단순한 이름 변경은 아니다. TF-GridNet은 full/sub-band module과 cross-frame attention의 구체적 결합, complex spectral mapping, 이후 multi-frame Wiener filter 결합을 제안한다.

TF-GridNet의 2-DNN 구성은 $$\mathrm{DNN}_1\rightarrow\mathrm{MCMFWF}\rightarrow\mathrm{DNN}_2$$다. MCMFWF는 DNN1 추정을 이용해 몇 개의 인접 frame을 포함한 multichannel Wiener filter를 만들고, 선형 filter 출력을 DNN2가 다시 보정한다. 6채널 SMS-WSJ의 슬라이드 19 표에서 1-stage DNN1은 SI-SDR 19.9 dB, WER 7.27%이고, DNN1+MCMFWF+DNN2는 22.8 dB, 6.76%다. 같은 표의 unprocessed는 −5.5 dB, 78.40%, oracle direct-path WER는 6.28%다. **2-stage 개선에는 beamformer와 두 번째 DNN이 함께 들어가므로 2.9 dB 전체를 beamformer 하나의 효과로 분리해 주장할 수 없다.**

## 9. SpatialNet은 공간 처리를 narrow-band와 cross-band로 나눈다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-20.png" | relative_url }}" alt="Lecture 9 II slide 20: SpatialNet maps multichannel complex STFTs through repeated cross-band and narrow-band blocks to multiple enhanced complex spectra, with detailed block modules" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=20" | relative_url }}" target="_blank" rel="noopener">slide 20</a>.</figcaption>
</figure>

이 글의 axis 순서로 SpatialNet 입력은 모든 마이크의 real/imaginary STFT를 쌓은 $$2M\times T\times F$$ tensor다. 반복되는 cross-band와 narrow-band block 뒤에는 각 화자의 complex STFT에 해당하는 $$2P\times T\times F$$ 출력이 나온다. 논문 그림의 $$F\times(T\times2M)$$ 표기는 같은 축을 연산에 맞게 재배열한 것이다. 명시적인 mask나 고전 beamformer가 최종 block으로 붙지 않는 end-to-end complex mapping이다.

- **Narrow-band block:** 주파수 bin마다 독립적으로 시간축 sequence를 처리한다. MHSA는 frame 사이 공간 feature의 유사성을, T-ConvFFN은 이웃 frame의 temporal filtering을 학습한다.
- **Cross-band block:** frame마다 독립적으로 주파수축을 처리한다. Full-band linear layer는 모든 주파수의 관계를, frequency convolution은 인접 bin의 국소 관계를 학습한다.

고전 beamforming과의 연결은 해석의 도움이지 계산의 동일성은 아니다. Narrow-band block이 명시적인 covariance를 계산하는 것은 아니고, cross-band block이 물리 TDOA estimator를 직접 출력하는 것도 아니다. 원 논문의 novelty는 **narrow-band spatial clustering/filtering과 cross-band spatial relation을 분리한 뒤 반복적으로 결합**한 설계다.

## 10. Narrow-band attention은 화자별 frame 묶음을 학습한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-22.png" | relative_url }}" alt="Lecture 9 II slide 22: SpatialNet attention maps show different heads attending to non-speech frames or block-like frame groups dominated by each speaker at one frequency" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=22" | relative_url }}" target="_blank" rel="noopener">slide 22</a>.</figcaption>
</figure>

그림은 위에서 speaker 1, speaker 2, mixture spectrogram을 보여 준 뒤 아래에 attention map을 둔다. 아래 map의 세로축은 query frame, 가로축은 key frame이다. 밝은 칸일수록 해당 query가 그 key를 크게 참조한다.

왼쪽 head는 비음성 구간에 강한 attention을 보이고, 오른쪽 head는 speaker 1과 speaker 2가 우세한 frame 구간별로 block 구조를 만든다. 저자들은 이를 **spatial feature가 비슷한 frame의 speaker clustering**으로 해석한다. 이는 attention map과 same-position/cross-language 실험이 뒷받침하는 해석이지만, 각 attention head가 항상 사람에게 동일한 의미로 고정된다는 보장은 아니다.

MHSA의 한 head에서 $$Q,K,V\in\mathbb R^{T\times d}$$라면

$$
\operatorname{Attention}(Q,K,V)
=\operatorname{softmax}\!\left(\frac{QK^T}{\sqrt d}\right)V.
$$

한 주파수 bin에서 attention matrix는 $$T\times T$$다. Speaker가 우세한 frame들의 채널별 complex pattern이 비슷하면 query–key score가 커질 수 있다. 그러나 이 수식만으로 화자 분리가 증명되는 것은 아니다. 학습 loss와 데이터가 그 similarity를 유용한 clustering으로 만들도록 해야 한다.

## 11. Cross-band 처리는 지연이 주파수에 만드는 위상 기울기를 활용할 수 있다

두 마이크 사이 직접경로 지연을 $$\tau$$, Fourier 부호를 $$X(f)=\int x(t)e^{-j2\pi ft}dt$$로 두면 $$x_2(t)=x_1(t-\tau)$$에서

$$
X_2(f)=X_1(f)e^{-j2\pi f\tau},
\qquad
\angle(X_2X_1^*)=-2\pi f\tau\pmod{2\pi}.
$$

Unwrapped phase는 주파수에 대해 기울기 $$-2\pi\tau$$인 직선이다. 예를 들어 $$\tau=0.25\,\mathrm{ms}$$면 1 kHz에서 위상차는 $$-\pi/2$$, 2 kHz에서 $$-\pi$$다. 이 선형 관계는 full-band layer가 여러 bin을 함께 볼 이유를 제공한다.

다만 실제 STFT의 wrapped phase는 $$[-\pi,\pi)$$에서 꺾이고, reverberation·여러 화자·noise는 한 직선을 흩뜨린다. Frequency convolution이 다루는 인접-bin 상관에는 STFT window의 spectral leakage뿐 아니라 speech spectrum의 국소 구조도 섞일 수 있다. 따라서 cross-band block이 오직 TDOA만 학습한다고 단정하지 않는다.

<details markdown="block">
<summary markdown="span">Derivation: Phase slope, wrapping, and delay ambiguity</summary>

시간 이동 성질에서

$$
\mathcal F\{x(t-\tau)\}
=\int x(t-\tau)e^{-j2\pi ft}dt
=e^{-j2\pi f\tau}X(f).
$$

따라서 두 채널의 cross-product phase가 $$-2\pi f\tau$$다. DFT bin $$k$$의 주파수가 $$f_k=kf_s/N$$이면 인접 bin의 unwrapped phase 증가는

$$
\Delta\phi=-2\pi\frac{f_s}{N}\tau.
$$

예를 들어 $$f_s=16\,\mathrm{kHz}$$, $$N=512$$, $$\tau=0.25\,\mathrm{ms}$$면 $$\Delta f=31.25\,\mathrm{Hz}$$이고 $$\Delta\phi\approx-0.0491\,\mathrm{rad}$$다. 관측 위상은 modulo $$2\pi$$이므로 충분한 주파수 범위와 물리적으로 가능한 delay 범위가 없으면 여러 delay가 비슷하게 보일 수 있다.

</details>

## 12. 성능표는 같은 설정 안에서만 비교한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-24.png" | relative_url }}" alt="Lecture 9 II slide 24: SpatialNet performance table reports SI-SDR, SDR, NB-PESQ, eSTOI, and WER for 2-channel and 6-channel SMS-WSJ systems" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=24" | relative_url }}" target="_blank" rel="noopener">slide 24</a>.</figcaption>
</figure>

SpatialNet 최종 논문의 Table III는 2채널과 6채널 SMS-WSJ를 분리한다. 강의 슬라이드에 삽입된 이전 표 이미지는 `TABLE IV`로 표시되므로 version별 번호가 다르지만 수치는 같다. 6채널에서 TFGridNet은 SI-SDR 22.8 dB, WER 6.76%, SpatialNet-large는 25.1 dB, 6.70%다. 따라서 같은 표에서는 SpatialNet-large가 SI-SDR 2.3 dB 높고 WER는 0.06%p 낮다. **신호 품질 차이는 크지만 WER 차이는 매우 작다.** 이를 “ASR가 크게 개선됐다”고 읽으면 안 된다.

Oracle direct-path의 SI-SDR·SDR가 $$\infty$$인 이유는 평가 target 자체이기 때문이다. WER 6.31%는 recognizer의 oracle acoustic input에서도 남는 오류를 뜻한다. SpatialNet-large 6.70%가 가깝다는 사실은 해당 recognizer·dataset 조건에서의 결과이지 모든 ASR에서의 상한을 뜻하지 않는다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-09-2/slide-25.png" | relative_url }}" alt="Lecture 9 II slide 25: SpatialNet SDR drops sharply when two speakers share one position, while cross-language training changes SpatialNet performance only slightly" loading="lazy">
  <figcaption>Source: Lecture 9 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf#page=25" | relative_url }}" target="_blank" rel="noopener">slide 25</a>.</figcaption>
</figure>

6채널 SMS-WSJ-Plus의 same-position 실험에서 SpatialNet-small SDR은 다른 위치 15.1 dB에서 같은 위치 1.8 dB로 떨어진다. 공간 패턴이 같아지면 분리가 무너진다는 결과는 model이 공간 정보를 실제로 활용한다는 강한 증거다. 동시에 **동일 위치·유사 steering vector가 명확한 실패 조건**임을 보여 준다.

강의 슬라이드의 cross-language 그래프에서는 영어 test에 영어로 학습한 SpatialNet-small이 15.1 dB, 중국어로 학습한 model이 14.6 dB다. SpatialNet 공개본 version에 따라 15.2/14.4 dB로 보고된 표도 있으므로 이 문단의 수치는 **강의 슬라이드에 표시된 값**으로 한정한다. 작은 감소는 특정 언어의 spectrum보다 공간 단서에 크게 의존한다는 저자 해석을 지지한다. 다만 “언어·화자와 완전히 무관하다”는 증명은 아니다. 비교한 언어·simulation 조건 밖의 실제 방, 이동 화자, array mismatch는 별도 검증이 필요하다.

## 마지막 핵심 정리

| 방법 | Network가 예측하는 것 | 고전 공간 처리와의 관계 | 핵심 한계 |
|---|---|---|---|
| Heymann GEV | Speech/noise mask | Mask-weighted PSD로 GEV 계산 | Mask·PSD 오류, scale normalization 필요 |
| Ochiai neural beamformer | Mask와 reference-channel attention | Differentiable Souden MVDR | ASR objective가 음질을 보장하지 않음 |
| MIMO-Speech | 화자별 mask와 ASR stream | 화자별 MVDR, CTC-PIT로 할당 | 알려진 화자 수와 permutation 비용 |
| FaSNet | 시간영역 adaptive filter | Learned filter-and-sum | Frame·filter context에 따른 latency |
| Beam-TasNet | 다채널 source image | DNN 통계로 MVDR, mixture를 최종 filtering | Source-image 오류가 PSD에 남음 |
| TF-GridNet | Target complex spectrum | MCMFWF와 2-DNN 결합 가능 | 직접 mapping의 artifact, 계산량 |
| SpatialNet | 화자별 complex STFT | Narrow/cross-band 연산으로 공간 관계를 학습 | 같은 위치의 화자에서 급격한 성능 저하 |

핵심 계보는 “beamformer에서 DNN으로 완전히 교체”가 아니다. **Mask로 통계를 얻는 방법, filter를 직접 예측하는 방법, complex spectrum을 직접 추정하는 방법이 서로 다른 축으로 발전했고, 최신 시스템은 이들을 다시 결합한다.** 또한 IPD는 frame별 상대 위상이고 covariance phase는 complex averaging 뒤의 위상이다. 단일 coherent source 조건에서 연결되지만 일반적인 혼합에서는 같은 값으로 둘 수 없다.

## Study Guide

먼저 슬라이드 5와 7을 비교한다. 둘 다 mask → PSD → filter 흐름이지만, Heymann 방법은 mask와 beamformer를 별도로 학습하고 Ochiai 방법은 ASR loss를 끝까지 역전파한다. 다음으로 슬라이드 13에서 DNN output과 최종 output이 다르다는 점을 확인한다. Beam-TasNet은 source image를 통계에 쓰고 실제 mixture를 MVDR로 필터링한다.

그다음 슬라이드 16의 네 출력 표현을 작은 복소수 예제로 비교한다. Real mask가 magnitude만 바꾸는 이유, spatial filter가 채널 위상을 합성하는 방식, direct mapping이 target phase까지 낼 수 있는 이유를 구분한다. 마지막으로 슬라이드 20–25를 읽으며 SpatialNet의 두 축이 실제 tensor의 어느 dimension을 처리하는지 확인한다. 성능표에서는 채널 수와 dataset을 고정한 행만 직접 비교한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. When do IPD and covariance phase agree?</summary>

답변: 한 coherent narrowband source가 우세하고 채널 전달함수 비가 고정되면 frame별 $$X_iX_j^*$$와 평균 $$E[X_iX_j^*]$$의 위상은 같은 steering phase를 나타낸다. 여러 음원·잔향·잡음이 섞이면 covariance는 magnitude까지 포함한 복소 평균이므로 개별 IPD나 그 산술평균과 일반적으로 다르다.

</details>

<details markdown="block">
<summary markdown="span">2. Why is the predicted mask used for statistics?</summary>

답변: 이 mask의 역할은 speech/noise PSD를 추정할 frame의 weight를 정하는 것이다. PSD는 모든 마이크의 complex snapshot으로 만들고, GEV나 MVDR가 그 공간 관계를 이용해 선형 filter를 계산한다. 따라서 mask는 통계 추정용 중간 출력이다.

</details>

<details markdown="block">
<summary markdown="span">3. Why can an ASR-trained mask differ from an ideal binary mask?</summary>

답변: 최종 loss가 mask 오차가 아니라 ASR 오차이기 때문이다. Gradient는 beamformer와 PSD 계산을 통과해, 정확한 mask 모양보다 transcript 인식에 유리한 공간 통계를 만드는 방향으로 mask network를 바꿀 수 있다.

</details>

<details markdown="block">
<summary markdown="span">4. Is PIT a spatial filter?</summary>

답변: 아니다. PIT는 순서가 없는 여러 output과 여러 정답을 어떤 permutation으로 짝지을지 정하는 loss 규칙이다. MIMO-Speech에서는 화자별 mask·MVDR·ASR stream 위에 적용된다.

</details>

<details markdown="block">
<summary markdown="span">5. Why does Beam-TasNet filter the mixture?</summary>

답변: DNN source image는 speech/interference PSD를 추정하는 데 사용한다. 최종 출력은 원 mixture의 선형 결합으로 만들어 비선형 DNN artifact를 줄이고 ASR 친화적인 출력을 얻으려 한다. 다만 source-image bias가 PSD에 들어가면 filter도 틀릴 수 있다.

</details>

<details markdown="block">
<summary markdown="span">6. How do real masking and complex mapping differ?</summary>

답변: Non-negative real magnitude mask는 기준 mixture의 phase를 유지하고 magnitude만 바꾼다. Signed real mask는 부호로 $$\pi$$ 반전을 만들 수 있지만 임의 위상을 정하지는 못한다. Complex spectral mapping은 real/imaginary target을 직접 예측해 magnitude와 phase를 모두 바꿀 수 있다. 자유도가 큰 대신 비선형 distortion과 일반화 실패를 더 직접 관리해야 한다.

</details>

<details markdown="block">
<summary markdown="span">7. Which axes do SpatialNet blocks process?</summary>

답변: Narrow-band block은 각 주파수 bin을 따로 두고 시간축 frame을 처리한다. Cross-band block은 각 frame을 따로 두고 주파수축 bin을 처리한다. 두 block을 반복해 시간축 공간 pattern과 주파수축 phase·spectrum 관계를 결합한다.

</details>

<details markdown="block">
<summary markdown="span">8. Why are the reported SI-SDR scores condition-specific?</summary>

답변: 두 값은 6채널 SMS-WSJ의 특정 table·학습·평가 설정에서 나온 SI-SDR다. 다른 채널 수, 실제 방, 이동 화자, dataset, recognizer에서는 결과가 달라질 수 있다. 같은 표의 WER 차이도 6.70%와 6.76%로 작다.

</details>

## PDF

- <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-09-2.pdf" | relative_url }}" target="_blank" rel="noopener">speech-audio-lecture-09-2.pdf</a>

## References

- 안인규(Inkyu An), *Multi-channel Source Separation 2-2*, Speech and Audio Recognition, slides 1–25. 그림은 위 첨부 원문의 해당 슬라이드다. 별도로 표시한 수치 예제와 유도는 이해를 위한 보충 해설이다.
- <a href="https://arxiv.org/abs/1905.07497" target="_blank" rel="noopener">Bahmaninezhad et al., A Comprehensive Study of Speech Separation: Spectrogram vs Waveform Separation</a> — waveform/spectrum과 다채널 feature 비교.
- <a href="https://ris.uni-paderborn.de/record/11812" target="_blank" rel="noopener">Heymann, Drude, and Haeb-Umbach, Neural Network Based Spectral Mask Estimation for Acoustic Beamforming</a> — mask-derived speech/noise CPSD와 GEV beamforming.
- <a href="https://proceedings.mlr.press/v70/ochiai17a.html" target="_blank" rel="noopener">Ochiai et al., Multichannel End-to-end Speech Recognition</a> — differentiable neural beamformer와 joint ASR optimization.
- <a href="https://arxiv.org/abs/1910.06522" target="_blank" rel="noopener">Chang et al., MIMO-Speech</a> — multi-channel multi-speaker separation·recognition과 PIT.
- <a href="https://arxiv.org/abs/1909.13387" target="_blank" rel="noopener">Luo et al., FaSNet</a> — low-latency time-domain adaptive filter-and-sum.
- <a href="https://ieeexplore.ieee.org/document/9053575/" target="_blank" rel="noopener">Ochiai et al., Beam-TasNet</a> — TasNet source estimates, spatial covariance, and MVDR.
- <a href="https://arxiv.org/abs/2102.02998" target="_blank" rel="noopener">Chen et al., Beam-Guided TasNet</a> — iterative DNN–MVDR refinement.
- <a href="https://arxiv.org/abs/2302.10657" target="_blank" rel="noopener">Wang et al., DasFormer</a> — alternating time- and frequency-axis spectrogram attention.
- <a href="https://arxiv.org/abs/2211.12433" target="_blank" rel="noopener">Wang et al., TF-GridNet</a> — full/sub-band modeling, complex spectral mapping, and MCMFWF.
- <a href="https://arxiv.org/abs/2307.16516" target="_blank" rel="noopener">Quan and Li, SpatialNet</a> — narrow-band/cross-band spatial modeling and Tables II–IV.
