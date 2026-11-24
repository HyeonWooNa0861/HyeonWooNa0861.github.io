---
layout: default
date: 2026-11-25 01:02:29 +0900
title: "Lecture 10: Sound Source Localization"
course: "Speech and Audio Recognition"
topic: "TDOA, GCC-PHAT, SRP, MVDR, MUSIC, and SELD"
order: 16
major_topic: "Speech and Audio Processing"
keywords:
  - "Sound Source Localization"
  - "Direction of Arrival"
  - "GCC-PHAT"
  - "SRP-PHAT"
  - "MVDR"
  - "MUSIC"
  - "SELD"
---

# Lecture 10: Sound Source Localization

Source PDF: `speech-audio-lecture-10-sound-source-localization.pdf` — *Sound Source Localization*, 안인규(Inkyu An), 30 slides.

> **핵심:** Sound Source Localization(SSL)은 여러 마이크에 같은 소리가 도착하는 **시간차와 위상차**를 이용해 음원이 온 방향, 즉 DoA(Direction of Arrival)를 찾는 과정입니다. GCC-PHAT은 마이크 쌍의 지연을 찾고, SRP는 여러 후보 방향으로 빔포머를 돌려 출력 전력을 비교합니다. MVDR와 MUSIC은 공분산 행렬을 이용해 가까운 방향을 더 날카롭게 구분하지만, 더 정확한 공간 통계와 행렬 계산이 필요합니다.

Lecture 8에서는 목표 방향을 알고 있다고 가정해 beamformer를 만들었고, Lecture 9에서는 DNN mask로 공간 통계를 추정했습니다. 그렇다면 **필터가 사용할 방향을 마이크 녹음만으로 어떻게 알아낼 수 있을까요?** 이번 강의는 도착 시간차로 방향을 계산하는 방법부터 방향별 전력을 비교하는 방법, 공분산의 signal·noise subspace를 이용하는 방법까지 이 빈칸을 채웁니다.

## 1. SSL은 무엇을 찾는가

**DoA는 소리가 마이크 배열에 들어오는 방향입니다.** 마이크가 여러 개면 같은 파면이 각 마이크에 도착하는 시각이 조금씩 다릅니다. SSL은 이 차이를 가장 잘 설명하는 후보 방향을 찾습니다.

후보 방향을 $$\theta$$, 그 방향이 관측과 얼마나 잘 맞는지를 나타내는 점수를 $$P(\theta)$$라고 쓰면 기본 문제는 다음과 같습니다.

$$
\widehat\theta=\arg\max_{\theta} P(\theta).
$$

이 식에서 중요한 것은 $$P(\theta)$$의 정의입니다. 두 마이크의 시간차를 직접 비교할 수도 있고, 후보 방향으로 빔포밍한 출력 전력을 쓸 수도 있으며, 공분산의 signal/noise subspace를 비교할 수도 있습니다. GCC-PHAT, SRP, MVDR, MUSIC은 서로 다른 점수 설계입니다.

### 1.1 두 마이크의 시간차가 방향으로 바뀌는 과정

간격이 $$d$$인 두 마이크에 far-field 평면파가 들어온다고 가정하겠습니다. 강의의 각도 기준에서는 두 마이크 사이의 경로 차이가 $$d\sin\theta$$이므로 TDOA(Time Difference of Arrival)는

$$
\tau_{12}=\frac{d\sin\theta}{c},
\qquad
\theta=\arcsin\!\left(\frac{c\tau_{12}}{d}\right)
$$

입니다. $$c$$는 음속입니다. 이 관계는 Lecture 8의 steering vector에 들어간 지연과 같습니다. 즉, Lecture 8에서는 지연을 **알고 필터를 만들었고**, 이번 강의에서는 녹음으로부터 그 지연을 **추정합니다**.

**작은 수치 예제:** $$d=0.08\ \mathrm{m}$$, $$c=343\ \mathrm{m/s}$$, $$\theta=30^\circ$$이면

$$
\tau_{12}=\frac{0.08\sin30^\circ}{343}
\approx116.6\ \mu\mathrm{s}.
$$

16 kHz 녹음에서는 약 $$1.87$$ sample에 해당합니다. 지연이 정수 sample보다 작을 수 있으므로 실제 추정에서는 주파수영역 위상이나 보간이 필요합니다. 또한 $$\lvert c\tau_{12}/d\rvert>1$$이면 이 배열 모델로 설명할 수 없는 지연입니다.

<details markdown="block">
<summary markdown="span">Derivation: Why the path difference is converted into a time delay</summary>

Far-field에서는 음원까지의 거리가 마이크 간격보다 충분히 커서 두 마이크에 도달하는 파면을 평행하게 볼 수 있습니다. 마이크를 잇는 축에 파의 진행 방향을 투영하면 추가로 이동한 거리가 $$d\sin\theta$$가 됩니다. 거리와 시간은 $$\Delta\ell=c\tau$$로 연결되므로

$$
c\tau_{12}=d\sin\theta
$$

를 얻습니다. 각도를 배열의 broadside가 아니라 endfire에서 재면 $$\sin$$ 대신 $$\cos$$가 나타날 수 있습니다. 식을 사용할 때는 각도 기준과 마이크 순서에 따른 지연 부호를 함께 확인해야 합니다.

</details>

## 2. GCC-PHAT은 두 신호가 가장 잘 맞는 지연을 찾는다

두 마이크 신호의 cross-correlation은 한 신호를 시간축에서 옮겨 가며 다른 신호와 얼마나 닮았는지 측정합니다. 강의의 Fourier 부호와 채널 순서에서는

$$
r_{12}(\tau)=\int X_1^*(\omega)X_2(\omega)e^{j\omega\tau}\,d\omega
$$

로 씁니다. 최대값이 나타나는 지연을 두 마이크의 TDOA 후보로 봅니다.

일반 cross-correlation은 에너지가 큰 주파수 성분의 영향을 많이 받습니다. **PHAT(Phase Transform)은 cross-spectrum의 크기를 1로 정규화하고 위상 관계에 집중합니다.**

$$
r_{12}^{\mathrm{PHAT}}(\tau)
=\int
\frac{X_1^*(\omega)X_2(\omega)}
{\left|X_1^*(\omega)X_2(\omega)\right|}
e^{j\omega\tau}\,d\omega,
\qquad
\widehat\tau_{12}=\arg\max_\tau r_{12}^{\mathrm{PHAT}}(\tau).
$$

쉽게 말하면 여러 주파수가 “이 정도 지연이 맞다”고 가리키는 위치를 모으는 과정입니다. 특정 주파수의 크기가 매우 크더라도 혼자 결과를 지배하기 어렵기 때문에 peak가 더 뾰족해질 수 있습니다. 다만 PHAT이 잔향을 없애는 것은 아닙니다. Cross-spectrum이 거의 0인 bin에서는 나눗셈이 불안정하므로 구현에서는 작은 $$\varepsilon$$을 분모에 더하거나 신뢰할 bin만 사용합니다.

<details markdown="block">
<summary markdown="span">Derivation: Why a time shift appears as phase alignment</summary>

$$x_2(t)=x_1(t-\tau_0)$$이면 Fourier shift 성질에 따라 $$X_2(\omega)=X_1(\omega)e^{-j\omega\tau_0}$$입니다. 따라서

$$
\frac{X_1^*(\omega)X_2(\omega)}{|X_1^*(\omega)X_2(\omega)|}
=e^{-j\omega\tau_0}.
$$

여기에 $$e^{j\omega\tau}$$를 곱해 모든 주파수를 더하면 $$\tau=\tau_0$$에서 위상이 맞아 큰 peak가 생깁니다. 실제 신호에는 잡음·잔향·여러 음원이 있으므로 완전한 impulse가 아니라 폭과 side lobe를 가진 peak가 나타납니다.

</details>

## 3. SRP는 후보 방향마다 “그쪽을 들었을 때의 전력”을 비교한다

TDOA를 한 번 구해 각도로 바꾸는 대신, 가능한 모든 $$\theta$$로 빔포머를 조향하고 출력 전력을 비교할 수 있습니다. 후보 방향의 필터를 $$\mathbf w(\theta)$$, 다채널 관측을 $$\mathbf x(t)$$라고 두면

$$
y(\theta,t)=\mathbf w(\theta)^H\mathbf x(t),
\qquad
\beta(\theta)=E[|y(\theta,t)|^2]
$$

입니다. 공간 공분산 $$\mathbf R=E[\mathbf x\mathbf x^H]$$를 사용하면

$$
\beta(\theta)=\mathbf w(\theta)^H\mathbf R\mathbf w(\theta)
$$

로 정리됩니다. **SRP(Steered Response Power)는 이 값을 방향별로 그린 뒤 peak를 찾는 방법입니다.**

### 3.1 DAS 기반 SRP

DAS 필터 $$\mathbf w=\mathbf h(\theta)/M$$을 넣으면

$$
\beta_{\mathrm{DAS}}(\theta)
=\frac{\mathbf h(\theta)^H\mathbf R\mathbf h(\theta)}{M^2}
$$

가 됩니다. 이는 모든 마이크 쌍의 상관값을 후보 방향의 지연에 맞춰 더한 것과 같습니다. 각 마이크 쌍에 PHAT weighting을 적용한 방법이 SRP-PHAT입니다.

DAS의 main lobe 안에 가까운 두 음원이 함께 들어가면 두 peak가 하나로 뭉칠 수 있습니다. 강의에서는 두 음원이 약 $$15^\circ$$ 떨어진 예에서 DAS가 하나의 넓은 peak를 보이는 점을 강조했습니다. 마이크 수와 배열 aperture가 작거나 파장이 길수록 이 문제가 커집니다.

## 4. MVDR spectrum은 왜 더 뾰족한가

후보 방향마다 MVDR 필터를 만들면

$$
\mathbf w_{\mathrm{MVDR}}(\theta)
=\frac{\mathbf R^{-1}\mathbf h(\theta)}
{\mathbf h(\theta)^H\mathbf R^{-1}\mathbf h(\theta)}
$$

입니다. 이 필터를 SRP의 출력 전력 식에 넣으면

$$
\beta_{\mathrm{MVDR}}(\theta)
=\frac{1}{\mathbf h(\theta)^H\mathbf R^{-1}\mathbf h(\theta)}
$$

를 얻습니다. 이를 Capon spectrum이라고도 합니다.

**DAS는 후보 방향 주변의 소리도 main lobe 안에 있으면 크게 통과시킵니다. MVDR는 후보 방향의 gain을 1로 유지하면서 관측된 다른 강한 방향에 null을 놓을 수 있습니다.** 따라서 실제 음원 방향에서 조금만 벗어나도 출력 전력이 빠르게 낮아지고 peak가 날카로워집니다.

이 장점에는 비용이 있습니다. 각 후보 방향에서 $$\mathbf R^{-1}$$이 필요하고, 공분산 추정이 불안정하면 spectrum도 크게 흔들립니다.

<details markdown="block">
<summary markdown="span">Derivation: From the MVDR filter to the Capon spectrum</summary>

$$q=\mathbf h^H\mathbf R^{-1}\mathbf h$$라고 두겠습니다. 공분산 $$\mathbf R$$이 Hermitian positive definite이면 $$q$$는 양의 실수입니다. MVDR 출력 전력은

$$
\begin{aligned}
\mathbf w^H\mathbf R\mathbf w
&=\frac{(\mathbf R^{-1}\mathbf h)^H\mathbf R(\mathbf R^{-1}\mathbf h)}{q^2}\\
&=\frac{\mathbf h^H\mathbf R^{-1}\mathbf R\mathbf R^{-1}\mathbf h}{q^2}\\
&=\frac{q}{q^2}=\frac1q.
\end{aligned}
$$

여기서는 $$\mathbf R^H=\mathbf R$$이므로 $$(\mathbf R^{-1})^H=\mathbf R^{-1}$$이라는 성질을 사용했습니다.

</details>

### 4.1 공분산 역행렬에는 충분한 frame이 필요하다

표본 공분산은

$$
\widehat{\mathbf R}=\frac1T\sum_{t=1}^{T}\mathbf x(t)\mathbf x(t)^H
$$

입니다. 각 outer product의 rank는 최대 1이므로

$$
\operatorname{rank}(\widehat{\mathbf R})\le \min(T,M)
$$

입니다. 따라서 $$T<M$$이면 $$M\times M$$ 행렬이 full rank가 될 수 없어 역행렬이 없습니다. $$T\ge M$$은 필요조건일 뿐 충분조건은 아닙니다. Frame들이 비슷하거나 마이크 채널이 선형 종속이면 여전히 singular할 수 있습니다.

작은 eigenvalue $$\widehat\lambda_i$$의 오차는 역행렬에서 $$1/\widehat\lambda_i$$로 확대됩니다. 그래서 실제 구현은

$$
\widehat{\mathbf R}_{\varepsilon}
=\widehat{\mathbf R}+\varepsilon\mathbf I
$$

처럼 diagonal loading을 사용합니다. Frame을 많이 모으면 통계는 안정되지만, 그 사이 음원이 움직이면 하나의 고정된 $$\mathbf R$$이라는 가정이 깨집니다. 즉, **추정 안정성과 시간 변화 추적 사이에 trade-off가 있습니다.**

## 5. MUSIC은 작은 noise eigenvalue 쪽에서 음원 방향을 찾는다

MUSIC(Multiple Signal Classification)은 covariance의 eigendecomposition을 사용합니다. 좁은 주파수 대역에서 서로 비상관인 음원이 $$K$$개이고 마이크 잡음이 spatially white라고 가정하면

$$
\mathbf R
=\sum_{k=1}^{K}\sigma_k^2\mathbf h(\theta_k)\mathbf h(\theta_k)^H
+\sigma_n^2\mathbf I.
$$

음원 $$K$$개는 큰 eigenvalue $$K$$개를 만듭니다. 나머지 $$M-K$$개 eigenvector는 noise subspace $$\mathbf U_N$$을 이룹니다. Hermitian 행렬의 eigenvector는 orthonormal basis를 만들기 때문에 signal subspace와 noise subspace는 서로 직교합니다.

여기서 **직교(orthogonal)**란 두 복소 벡터의 Hermitian inner product가 0이라는 뜻입니다. 실제 음원 방향의 steering vector는 signal subspace에 있으므로

$$
\mathbf U_N^H\mathbf h(\theta_k)=\mathbf0
$$

가 됩니다. MUSIC은 후보 $$\theta$$를 바꿔 가며 이 값이 0에 가까워지는 위치를 찾습니다.

$$
P_{\mathrm{MUSIC}}(\theta)
=\frac{1}{\mathbf h(\theta)^H\mathbf U_N\mathbf U_N^H\mathbf h(\theta)}.
$$

분모는 steering vector를 noise subspace에 투영한 길이의 제곱입니다. 실제 음원 방향에서는 이 길이가 작아지고, 역수를 취한 pseudo-spectrum에는 큰 peak가 생깁니다. 이 높이는 실제 음원 power가 아닙니다. **Peak의 위치만 DoA로 해석합니다.**

강의에서는 signal eigenvector로부터 개별 steering vector를 바로 복원하려 하면 여러 source의 선형결합이 나타난다는 점을 먼저 설명했습니다. MUSIC은 그 조합의 계수를 직접 풀기보다, noise subspace와 직교하는 후보 방향을 찾습니다.

<details markdown="block">
<summary markdown="span">Derivation: Why source steering vectors are orthogonal to the noise subspace</summary>

$$\mathbf H=[\mathbf h(\theta_1),\ldots,\mathbf h(\theta_K)]$$이고 source covariance가 양의 diagonal matrix $$\mathbf S$$라고 하겠습니다. Noise eigenvector $$\mathbf u$$가 eigenvalue $$\sigma_n^2$$를 만족하면

$$
\mathbf R\mathbf u
=(\mathbf H\mathbf S\mathbf H^H+\sigma_n^2\mathbf I)\mathbf u
=\sigma_n^2\mathbf u.
$$

따라서 $$\mathbf H\mathbf S\mathbf H^H\mathbf u=\mathbf0$$입니다. 왼쪽에서 $$\mathbf u^H$$를 곱하면

$$
\mathbf u^H\mathbf H\mathbf S\mathbf H^H\mathbf u
=\sum_{k=1}^{K}\sigma_k^2
|\mathbf h(\theta_k)^H\mathbf u|^2=0.
$$

각 항은 0 이상이고 $$\sigma_k^2>0$$이므로 모든 항이 0이어야 합니다. 즉, $$\mathbf h(\theta_k)^H\mathbf u=0$$입니다. 이 유도는 source들이 비상관이고 steering vector들이 독립이라는 가정에 의존합니다.

</details>

## 6. DAS, MVDR, MUSIC을 같은 기준으로 비교하기

세 방법은 모두 후보 steering vector $$\mathbf h(\theta)$$와 관측 공분산 $$\mathbf R$$에서 출발하지만, 방향 점수를 만드는 방식이 다릅니다.

| 방법 | 방향 점수 | 필요한 계산 | 읽는 방법 | 주된 제약 |
|---|---|---|---|---|
| DAS-SRP | $$\mathbf h^H\mathbf R\mathbf h/M^2$$ | 곱셈과 합 | 출력 전력이 큰 방향 | Main lobe가 넓어 가까운 음원이 합쳐질 수 있습니다. |
| MVDR/Capon | $$1/(\mathbf h^H\mathbf R^{-1}\mathbf h)$$ | 공분산 역행렬 | 날카로운 power-spectrum peak | 적은 frame, model mismatch, 작은 eigenvalue에 민감합니다. |
| MUSIC | $$1/(\mathbf h^H\mathbf U_N\mathbf U_N^H\mathbf h)$$ | Eigendecomposition과 source 수 $$K$$ | Pseudo-spectrum peak 위치 | $$K<M$$, 비상관 source, white noise, 정확한 steering model이 필요합니다. |

쉽게 비유하면 DAS는 후보 방향을 향한 **넓은 손전등**으로 에너지를 확인합니다. MVDR는 관측된 간섭에 맞춰 빛이 새는 방향을 눌러 **더 좁은 탐색광**을 만듭니다. MUSIC은 직접 밝기를 재기보다 “잡음 공간과 가장 맞지 않는 방향”을 찾습니다. 이 비유는 해석을 돕기 위한 것이며, 실제 계산은 위의 power와 projection 식입니다.

## 7. PDF 후반부가 확장하는 범위

강의자료 후반부는 기본적인 DAS·MVDR·MUSIC 비교를 실제 음성 환경과 학습 모델로 확장합니다. 아래 내용은 강사의 직접 강조로 해석하지 않고 **자료가 제시한 후속 구조**로 정리합니다.

### 7.1 MUSIC의 한계와 wideband speech

- **Coherent source:** 직접음과 벽 반사음처럼 같은 신호가 두 방향에서 오면 source covariance의 rank가 방향 수만큼 증가하지 않을 수 있습니다. 두 방향인데도 하나의 signal eigenvector만 나타나 MUSIC이 두 peak를 찾지 못할 수 있습니다. Spatial smoothing은 이를 완화하는 방법입니다.
- **Source 수 $$K$$:** Noise subspace의 크기를 정하려면 source 수를 알아야 합니다. Eigenvalue gap, AIC, MDL 같은 기준이 후보가 되지만 잘못된 $$K$$는 잘못된 subspace를 만듭니다.
- **Wideband speech:** Speech는 넓은 주파수 대역을 사용하므로 frequency bin마다 $$\mathbf R(f)$$와 $$\mathbf h(\theta,f)$$를 계산하고 spectrum을 결합해야 합니다. 저주파에서는 peak가 넓고, 고주파에서는 마이크 간격이 반파장보다 크면 spatial aliasing이 생길 수 있습니다.

### 7.2 Learning-based SSL

학습 기반 방법은 GCC-PHAT feature를 입력하고 각 방향의 likelihood를 출력할 수 있습니다. 고전 방법처럼 방향별 공간 spectrum을 만들지만, 점수의 모양을 데이터에서 학습합니다. 임계값을 넘는 peak의 수를 source 수로, peak 위치를 DoA로 해석할 수 있습니다.

이 방식은 학습 데이터에서 본 방·배열·잡음 조건을 활용할 수 있지만, 보지 못한 환경으로 일반화되는지는 별도로 평가해야 합니다. “신경망을 썼다”는 이유만으로 reverberation이나 array mismatch가 사라지지는 않습니다.

### 7.3 Localization에서 separation으로

PDF는 DoA를 speech separation에 쓰는 세 흐름을 연결합니다.

1. **DoA로 speaker별 beamformer를 만듭니다.** LCMV는 한 speaker 방향의 gain을 1로 두고 다른 speaker 방향에는 0의 null 제약을 둘 수 있습니다.
2. **DoA를 DNN의 입력 feature로 줍니다.** Target 방향에서 예상한 phase difference와 실제 IPD가 비슷한 시간–주파수 bin을 골라 target mask 추정을 돕습니다.
3. **Localization과 separation을 함께 수행합니다.** Cone of Silence는 선택한 각도와 window 안의 source만 출력하도록 학습하고, 각도 구간을 줄여 가며 source 위치와 분리를 함께 좁힙니다.

이때 DoA 오차가 작아도 문제가 될 수 있습니다. 좁은 beam이나 null을 사용하는 필터는 target 방향이 $$1^\circ$$–$$2^\circ$$만 틀려도 target을 간섭으로 보고 억제할 수 있습니다. Reverberant room에서는 target 자체도 하나의 이상적인 평면파가 아니므로 diagonal loading이나 noise-only covariance처럼 mismatch에 덜 민감한 설계가 필요합니다.

### 7.4 SELD는 “무엇이, 언제, 어디서” 나는지 함께 찾는다

SELD(Sound Event Localization and Detection)는 음성뿐 아니라 일반 sound event로 범위를 넓힙니다.

- SED branch는 frame마다 어떤 class가 활성화되었는지 찾습니다.
- DoA branch는 활성 event의 방향을 찾습니다.
- ACCDOA는 class별 vector 하나에 activity와 방향을 함께 담습니다. Vector 길이는 activity, 방향은 DoA를 나타냅니다.
- Multi-ACCDOA는 같은 class의 소리가 동시에 여러 곳에서 나는 경우를 위해 class마다 여러 track을 둡니다.

즉, SELD의 출력은 단순한 각도 하나가 아닙니다. Event class, 활성 시각, 공간 방향을 함께 연결해야 합니다.

## 마지막 핵심 정리

1. 마이크 간 **시간차**는 배열 geometry를 통해 DoA로 바뀝니다.
2. GCC-PHAT은 cross-spectrum의 크기를 정규화하고 위상 정렬이 가장 잘 맞는 지연을 찾습니다.
3. SRP는 후보 방향마다 빔포밍 출력 전력을 계산합니다.
4. MVDR는 다른 강한 방향을 억제해 DAS보다 날카로운 peak를 만들 수 있지만 안정적인 $$\mathbf R^{-1}$$이 필요합니다.
5. MUSIC은 source steering vector가 noise subspace와 직교한다는 성질을 사용합니다. Spectrum 높이가 power라는 뜻은 아닙니다.
6. 높은 해상도에는 충분한 frame, 정확한 steering model, source 수와 noise 가정이 필요합니다.

## Study Guide

먼저 **TDOA → steering vector → 방향별 점수**의 흐름을 이해합니다. 다음으로 DAS와 MVDR를 “출력 전력을 만드는 서로 다른 필터”로 비교합니다. 마지막으로 MUSIC을 “noise subspace에 투영된 길이를 최소화하는 방향 탐색”으로 읽으면 됩니다.

헷갈리기 쉬운 구분은 세 가지입니다.

- GCC-PHAT의 출력은 **마이크 쌍의 지연**이고, SRP·MVDR·MUSIC의 출력은 **방향별 점수**입니다.
- MVDR spectrum은 출력 power로 해석할 수 있지만 MUSIC은 **pseudo-spectrum**입니다.
- Orthogonal은 “각도가 직각으로 보인다”는 뜻이 아니라 복소 inner product가 0이라는 뜻입니다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Why can a two-microphone TDOA determine a direction?</summary>

답변: Far-field와 알려진 array geometry를 가정하면 경로 차이가 $$d\sin\theta$$이고 시간차는 이를 음속으로 나눈 값입니다. 따라서 허용 범위 안의 $$\tau$$를 각도로 역변환할 수 있습니다. 다만 3차원 위치 전체나 front–back ambiguity까지 두 마이크만으로 항상 해결되는 것은 아닙니다.

</details>

<details markdown="block">
<summary markdown="span">2. Why does PHAT use phase rather than raw cross-spectrum magnitude?</summary>

답변: Raw cross-correlation은 에너지가 큰 주파수가 결과를 지배할 수 있습니다. PHAT은 각 bin의 크기를 정규화해 주파수별 phase alignment를 모읍니다. 그래서 지연 peak가 날카로워질 수 있지만, 낮은 SNR bin의 불안정성과 reverberation은 별도로 처리해야 합니다.

</details>

<details markdown="block">
<summary markdown="span">3. Why can MVDR separate two peaks that DAS merges?</summary>

답변: DAS의 beam pattern은 array geometry로 정해져 가까운 두 방향이 같은 main lobe 안에 들어갈 수 있습니다. MVDR는 관측 공분산에 맞춰 후보 방향의 gain은 유지하고 다른 강한 방향에는 null을 만들 수 있어, 후보가 실제 음원에서 벗어났을 때 power가 더 빠르게 감소합니다.

</details>

<details markdown="block">
<summary markdown="span">4. Is $$T\ge M$$ sufficient for an invertible sample covariance?</summary>

답변: 아닙니다. $$T\ge M$$이면 full rank가 가능해질 뿐입니다. Frame 벡터들이 충분히 독립적이지 않거나 채널이 선형 종속이면 여전히 singular할 수 있습니다. 작은 eigenvalue가 부정확하면 역행렬도 불안정하므로 diagonal loading을 사용합니다.

</details>

<details markdown="block">
<summary markdown="span">5. Why does MUSIC take a reciprocal?</summary>

답변: 실제 source 방향의 steering vector는 noise subspace와 직교하므로 projection energy가 0에 가까워집니다. 이 작은 값을 분모에 두면 source 방향이 큰 peak로 보입니다. Peak 위치가 DoA이며 높이는 source power가 아닙니다.

</details>

<details markdown="block">
<summary markdown="span">6. What breaks MUSIC in a strongly reverberant room?</summary>

답변: 같은 source의 직접음과 반사음은 서로 coherent할 수 있습니다. 방향은 여러 개인데 signal covariance rank가 그 수만큼 늘지 않으면 signal/noise subspace 분리가 예상과 달라집니다. Steering mismatch와 colored noise도 직교 조건을 흐립니다.

</details>

## Source Materials

- <a href="https://ecampus.kookmin.ac.kr/mod/ubfile/view.php?id=2008131" target="_blank" rel="noopener">Kookmin University eCampus: Sound Source Localization lecture material</a> — 수강 권한이 필요한 강의자료입니다.
- 2026-11-24 수업 녹음은 PDF와 용어·수식이 일치하는 DoA, GCC-PHAT, SRP, MVDR, MUSIC 기본 설명에만 사용했습니다. 강의자료 후반의 MUSIC 한계·학습 기반 SSL·separation·SELD는 PDF에 근거한 후속 범위입니다.

## References

- 안인규(Inkyu An), *Sound Source Localization*, Speech and Audio Recognition, slides 1–30, 2026-11-24. 본문의 작은 수치 예제와 상세 유도는 이해를 위한 보충 해설입니다.
- Charles H. Knapp and G. Clifford Carter, <a href="https://doi.org/10.1109/TASSP.1976.1162830" target="_blank" rel="noopener">The Generalized Correlation Method for Estimation of Time Delay</a>, *IEEE Transactions on Acoustics, Speech, and Signal Processing*, 1976.
- Jack Capon, <a href="https://doi.org/10.1109/PROC.1969.7278" target="_blank" rel="noopener">High-Resolution Frequency-Wavenumber Spectrum Analysis</a>, *Proceedings of the IEEE*, 1969.
- Ralph O. Schmidt, <a href="https://doi.org/10.1109/TAP.1986.1143830" target="_blank" rel="noopener">Multiple Emitter Location and Signal Parameter Estimation</a>, *IEEE Transactions on Antennas and Propagation*, 1986.
