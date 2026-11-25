---
layout: default
date: 2026-11-19 14:56:38 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Speech and Audio Recognition: Lecture 9 MVDR Beamforming Lab"
course: "Speech and Audio Recognition"
topic: "Direction-Based and Mask-Based Beamforming"
order: 14
major_topic: "Speech and Audio Processing"
keywords:
  - "MVDR Beamforming"
  - "Souden MVDR"
  - "Relative Transfer Function"
  - "Spatial Covariance Matrix"
  - "Time-Frequency Mask"
  - "Multichannel Wiener Filter"
  - "SepFormer"
---

# Speech and Audio Recognition: Lecture 9 MVDR Beamforming Lab

Source Materials: `Lec9_MVDR_lab.ipynb` and its 10-page lab guide.

**빔포머(beamformer)**는 여러 마이크의 녹음을 합쳐, 듣고 싶은 방향의 목소리를 더 또렷하게 만드는 필터입니다. 이 실습에서는 서로 다른 위치에서 두 사람이 동시에 말합니다. 어느 마이크로 들어도 두 사람의 말이 섞여 있는데, 녹음을 여러 개 쓰면 무엇이 달라질까요?

한 사람이 ‘아’라고 하면 그 소리는 가까운 마이크에 먼저, 먼 마이크에는 조금 늦게 도착합니다. 가장 단순한 방법은 두 녹음에서 ‘아’가 시작되는 시점을 맞춘 뒤 더하는 것입니다. 그러면 ‘아’의 파형은 봉우리끼리 겹쳐 보강됩니다. 반면 다른 방향에서 온 목소리는 마이크에 도착하는 시간차가 달라서, 같은 만큼 옮겨도 파형이 꼭 겹치지는 않습니다. 다른 사람의 목소리가 사라지는 게 아니라 **듣고 싶은 쪽이 상대적으로 또렷해집니다.** 이렇게 소리가 오는 방향에 따라 다르게 합치는 처리를 **공간 필터링**이라고 합니다.

이 실습의 **MVDR(Minimum Variance Distortionless Response)**은 각 마이크의 신호를 얼마씩 반영할지 주파수마다 정합니다. 여기에는 조건이 하나 있습니다. 예상한 방향에서 온 목소리는 기준 마이크에서 들리는 크기와 위상을 유지해야 합니다. 왜 이런 조건이 필요할까요? 잡음만 줄이면 된다면 마이크를 전부 꺼도 답이 되기 때문입니다. MVDR은 **듣고 싶은 소리는 유지한다는 조건 안에서** 출력에 남는 잡음의 전력을 최소화합니다. 실제 목소리가 예상과 다르게 도착하면 그 목소리도 달라질 수 있습니다.

목표 목소리가 각 마이크에 어떻게 도착하는지 알아내는 데에는 두 가지 방법을 사용합니다. 첫 번째는 화자의 방향과 마이크 위치로 계산합니다. 두 번째는 녹음에서 목표 목소리나 잡음이 두드러지는 시간·주파수 칸을 골라, 그때 여러 마이크에 소리가 어떻게 나타났는지 살핍니다. 여기서 **마스크**는 목소리에 직접 씌우는 필터가 아닙니다. 어느 칸의 관측을 추정에 더 많이 반영할지 정하는 표입니다.

## 전체 흐름

| 단계 | 입력과 출력 | 확인할 차이 |
|---|---|---|
| 혼합음 생성 | 두 화자와 센서 잡음 → 8채널 파형 | 기준 신호는 마이크 1에서 받은 반향 포함 목표 음성 |
| 관측 통계 | 8채널 STFT → 주파수별 8 × 8 행렬 | 대각은 채널 전력, 비대각은 채널 사이의 크기·위상 관계 |
| 빔포밍 | 조향벡터 또는 마스크 가중 공분산 → 주파수별 필터 | 출력은 어느 경우에도 다채널 혼합음의 가중합 |
| 평가 | 복원 파형 → 음질·인식 지표 | 깨끗한 신호에 대한 일치와 단어 인식은 다른 목표 |
| 오류 실험 | 마스크 문턱값 변경 → SI-SDR 변화 | 선택한 칸의 비율과 통계에 섞인 성분을 구분 |

## 1. 같은 혼합음으로 비교 조건 맞추기

설명자료 1–2쪽의 실습은 16 kHz의 두 음성을 6 × 5 × 3 m 공간에 놓고, 4 cm 간격의 마이크 8개로 받습니다. 실습의 각도 정의에서 목표 화자는 20°, 간섭 화자는 −40°이며 배열 중심으로부터 각각 1 m 떨어져 있습니다. 잔향 시간 RT60은 0.25 s입니다. `image()`는 음원과 각 마이크 사이의 방 임펄스 응답을 구해 원음과 합성곱합니다. 목표 화자 성분 $$s_m$$과 간섭·센서 잡음 성분 $$n_m$$을 더하면 마이크 $$m$$의 혼합음 $$x_m=s_m+n_m$$이 됩니다.

기준 마이크에서 **목표 대 간섭 화자** 전력비는 0 dB, **목표 대 센서 잡음** 전력비는 20 dB로 각각 맞춥니다. 두 비율에서 분모가 다릅니다. 평가 기준 $$s_r$$은 건조한 원음이 아니라 반향을 포함해 기준 마이크에 도달한 목표 음성입니다. 본문에서 $$r=1$$은 물리적 마이크 번호이며 Python 배열에서는 `ref=0`입니다. `oracle`은 시뮬레이션 덕분에 알고 있는 정답 성분을 사용했다는 뜻입니다.

| 변수 | 크기 | 축과 의미 |
|---|---|---|
| `x_mix`, `s_img`, `n_img` | 8 × 237,440 | 마이크 × 표본. 약 14.84 s |
| `X`, `S`, `N` | 8 × 513 × 929 | 마이크 × 주파수 bin × STFT 프레임 |
| `PhiS`, `PhiN`, `Rx` | 513 × 8 × 8 | 주파수 bin × 마이크 × 마이크 |
| `H`, `W` | 513 × 8 | 주파수 bin × 조향벡터 또는 필터 성분 |
| `mS`, `m_est` | 513 × 929 | 주파수 bin × 프레임, 무차원 |

창 길이는 1,024표본(64 ms), hop은 256표본(16 ms)입니다. 실수 파형의 한쪽 스펙트럼이므로 0 Hz부터 8 kHz까지 513개 bin이 남습니다. 주파수 간격은 15.625 Hz입니다. 프레임 수 929에는 SciPy STFT의 경계 확장이 포함되며, 역변환 뒤에는 파형을 원래 표본 수로 자릅니다.

## 2. 마스크는 공간 통계에 어떤 칸을 넣을지 결정한다

**시간·주파수 마스크(time-frequency mask)**는 STFT의 각 칸에 대응하는 가중치 표입니다. 실습에서는 목표나 간섭이 우세한 관측을 구분합니다. **공간 공분산 행렬(spatial covariance matrix)**은 같은 주파수에서 채널별 에너지와 채널 쌍이 함께 변하는 패턴을 모아 둔 행렬입니다. 그 패턴을 알면 단순히 큰 소리를 찾는 것과 달리, 배열 전체에서 목표 음성이 어떤 모습으로 들어오는지 구분할 수 있습니다.

마스크를 사진의 밝기를 조정하는 덮개보다, **어떤 관측을 평균에 얼마나 반영할지 정하는 채점표**에 가깝게 생각하면 됩니다. 칸 자체는 기준 마이크에서 고르지만, 평균에 넣는 관측은 그 칸의 **8채널 벡터 전체**입니다. 예를 들어 목표에 가까운 두 관측의 가중치가 1과 0.5라면 두 번째도 평균에 참여하되 영향은 절반입니다. 한 bin의 모든 채널을 따로 깎는 연산과는 다릅니다.

주파수 $$f$$, 프레임 $$t$$의 복소 채널 벡터를 $$\mathbf z(t,f)$$, 마스크를 $$m(t,f)$$라 하겠습니다. 마스크 합이 양수일 때 정규화한 표본 2차 모멘트는 다음과 같습니다. 코드에는 0 나눗셈을 피하는 작은 상수가 들어갑니다.

$$
\widehat{\boldsymbol\Phi}(f)=
\frac{\sum_t m(t,f)\mathbf z(t,f)\mathbf z(t,f)^H}
     {\sum_t m(t,f)}.
$$

$$H$$는 켤레전치입니다. 대각 원소에는 해당 마이크 STFT 크기의 제곱이 평균되고, 비대각 원소에는 채널 둘의 복소 곱이 평균됩니다. 단위는 실습의 정규화된 STFT 크기의 제곱입니다. 평균을 빼지 않으므로 엄밀히는 **비중심 2차 모멘트**이며, 이 글에서는 강의에 맞춰 공간 공분산이라고 부릅니다.

설명자료 3쪽 도표는 가로축이 주파수(Hz), 세로축이 전체 고유값 합 중 가장 큰 고유값의 비율입니다. 목표 성분의 곡선은 여러 대역에서 비율이 높지만 항상 1은 아닙니다. 반면 약 4 kHz 위에서 간섭·잡음 곡선이 내려가는 것은 센서별 독립 잡음의 비중이 커지는 구간과 맞습니다. 이 비율만으로 잡음의 정체나 반향의 크기를 단정할 수는 없습니다. 8채널에 전력이 똑같이 분산된 이상적인 백색 센서 잡음이라면 비율은 $$1/8=0.125$$입니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Channel products and frequency-wise averaging</summary>

`cov(Z, mask)`의 핵심은 `ft,mft,nft->fmn`입니다. $$m,n$$은 여기서 마이크 첨자입니다. `Z`의 둘째 항에 켤레를 취해 마이크 $$m,n$$ 사이 곱을 만들고, 출력 첨자에 없는 프레임 $$t$$를 합산합니다. 주파수별 마스크 합으로 나누므로 다른 주파수 bin의 관측이 섞이지 않습니다. 마스크가 없으면 모두 1로 놓습니다. 정답 공분산은 `cov(S)`와 `cov(N)`이고, 혼합 공분산은 `cov(X)`입니다. `cov(X, mS)`는 정답 마스크를 써도 정답 목표 신호 자체를 관측한 공분산이 아닙니다.

작성자 예시로 한 주파수에 두 마이크와 두 프레임만 두겠습니다. 관측이 $$[1,j]^{\top}$$와 $$[1,-j]^{\top}$$이고 가중치가 3과 1이면, 첫 행 둘째 열의 곱은 각각 $$-j$$와 $$j$$입니다. 가중 평균은 $$-j/2$$, 반대쪽 원소는 그 켤레인 $$j/2$$입니다. 같은 가중치로 섞으면 두 곱이 상쇄됩니다. 가중치가 마이크 간 위상 관계 추정에 영향을 주는 이유입니다. 설명자료 2쪽의 `einsum`은 이 계산을 모든 bin과 채널 쌍에서 수행합니다.

</details>

## 3. 도달 방향과 실제 전달 패턴은 다르다

방향 기반 필터는 목표 방향에서 평면파가 들어온다고 놓고, 마이크에 도달하는 시간차를 복소 위상으로 바꿉니다. 간격 $$d$$는 m, 음속 $$c=343\,\mathrm{m/s}$$, 지연 $$\tau_m$$은 s, $$f$$는 Hz입니다. 코드의 마이크 1 기준 조향벡터 성분은 $$h_m(f,\theta)=\exp(-j2\pi f\tau_m)$$, 지연은 $$\tau_m=(m-1)d\sin\theta/c$$입니다. DAS는 $$\mathbf h/M$$으로 위상을 맞춘 뒤 평균합니다. MPDR은 혼합 공분산 $$\mathbf R_x$$로 출력 전력을 줄이고, oracle MVDR은 정답 잡음 공분산 $$\boldsymbol\Phi_N$$으로 잡음 전력을 줄입니다.

실제 방에서는 직접음 외에 반사음도 들어옵니다. **상대 전달함수(RTF)** $$\tilde a_m=a_m/a_r$$는 마이크 $$m$$의 전달함수를 기준 마이크의 전달함수로 나눈 무차원 복소 비율입니다. $$a_r\ne0$$이고 한 bin에서 하나의 전달벡터로 표현할 수 있다면 $$\mathbf s=\tilde{\mathbf a}s_r$$입니다. 이때 공분산이 $$\phi_r\tilde{\mathbf a}\tilde{\mathbf a}^{H}$$이고 $$\phi_r=\mathbb E[\lvert s_r\rvert^2]$$이므로, 모든 열이 같은 벡터에 비례합니다. 따라서 목표가 있는 bin에서 rank 1이고 주 고유벡터를 기준 마이크 값으로 나누면 RTF를 얻습니다. 실제 자료의 `rtf(PhiS_or)`는 이 조건이 근사일 때의 추정값입니다.

<details markdown="block">
<summary markdown="span">Reading the figure: phase wrapping and interchannel phase difference</summary>

설명자료 5쪽 위 그림은 마이크 8의 마이크 1 대비 위상을 그립니다. 가로축은 주파수(Hz), 세로축은 위상(rad)입니다. 주황 선의 중간 점프는 위상을 $$[-\pi,\pi]$$ 범위로 표시한 결과입니다. 전달 지연이 갑자기 바뀐 것은 아닙니다. 파란 점이 선에서 벗어나는 정도가 실제 관측에서 자유음장 가정과 달라진 부분입니다. 반향을 줄이면 직선에 가까워질 수 있지만, 1 m의 유한 거리와 평면파 가정 차이도 남으므로 완전히 겹친다고 보장하지 않습니다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/mvdr-steering-phase-wrap.svg" | relative_url }}" width="648" height="274" alt="마이크 8을 마이크 1과 비교한 위상차는 약 1.79 kHz와 5.37 kHz에서 −π 부근에서 +π 부근으로 돌아온다." loading="lazy">
  <figcaption>보충 그림: 실습의 조향벡터 함수로 계산한 평면파 예측값. 반향이 있는 방에서 측정한 값은 아닙니다.</figcaption>
</figure>

파란 선을 왼쪽부터 따라가 보겠습니다. 20° 방향에서 오는 소리는 마이크 8에 마이크 1보다 약 279 µs 늦게 도착합니다. 시간차는 일정하지만 주파수가 높을수록 그 시간에 더 많은 주기를 지나므로 위상은 계속 내려갑니다. 약 1.79 kHz에서 선이 위로 돌아오는 것은 **−π와 +π가 같은 각도**이기 때문입니다. 마이크의 위치나 소리의 방향이 바뀐 것이 아닙니다.

**채널 간 위상차(IPD, Interchannel Phase Difference)**는 같은 시간·주파수 칸에서 두 채널의 위상을 뺀 각도입니다. 예를 들어 마이크 8에서 마이크 1의 위상을 빼려면 $$\angle(X_8X_1^*)$$를 계산합니다. 설명자료 5쪽의 파란 점은 혼합음의 순간 IPD가 아니라 목표 공분산에서 추정한 **RTF의 위상**입니다. 목표 한 화자의 전달 패턴이 고정돼 있고 그 화자가 우세할 때 두 종류의 위상 정보가 가까워집니다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Minimum variance with a fixed target response</summary>

양의 정부호인 공분산 $$\mathbf R$$에 대해 $$\mathbf w^H\mathbf R\mathbf w$$를 최소화하되 $$\mathbf w^H\mathbf h=1$$을 만족시킵니다. $$\mathbf v=\mathbf R^{1/2}\mathbf w$$, $$\mathbf b=\mathbf R^{-1/2}\mathbf h$$로 바꾸면 출력 전력은 $$\lVert\mathbf v\rVert^2$$이고 조건은 $$\mathbf v^H\mathbf b=1$$입니다. Cauchy–Schwarz 부등식에서 $$1\le\lVert\mathbf v\rVert^2\lVert\mathbf b\rVert^2$$이며, $$\mathbf v=\mathbf b/(\mathbf b^H\mathbf b)$$에서 하한에 도달합니다. 원래 변수로 돌아오면

$$
\mathbf w=\frac{\mathbf R^{-1}\mathbf h}{\mathbf h^H\mathbf R^{-1}\mathbf h}.
$$

코드는 역행렬 대신 `solve`를 쓰고, 작은 고유값이 있는 bin에서 불안정해지는 것을 줄이기 위해 $$\epsilon\operatorname{Tr}(\mathbf R)\mathbf I/M$$을 더합니다. $$\epsilon=10^{-3}$$은 무차원입니다. 공분산이 완전히 0이면 이 로딩만으로는 역을 보장하지 못합니다. 또한 이 제약은 **지정한** $$\mathbf h$$의 응답만 1로 만듭니다. 실제 목표 벡터가 다르면 실제 목표 신호의 크기나 위상은 변할 수 있습니다.

</details>

## 4. 마스크 기반 Souden MVDR과 MWF

설명자료 5쪽 아래의 가로축은 시간(s), 세로축은 주파수(kHz)입니다. 왼쪽 혼합음 그림은 로그 진폭, 가운데 IBM과 오른쪽 IRM의 밝기는 정규화된 마스크 값입니다. 흰 칸이 무조건 큰 소리를 뜻하지 않습니다. 목표와 간섭이 모두 작아도 목표 비중이 크면 마스크가 밝을 수 있습니다.

- **IBM(Ideal Binary Mask):** 기준 마이크에서 $$\lvert S_r\rvert>\lvert N_r\rvert$$면 1, 아니면 0입니다.
- **IRM(Ideal Ratio Mask):** 목표 진폭 제곱을 $$\lvert S_r\rvert^2+\lvert N_r\rvert^2$$로 나눕니다. 둘 다 0인 경우는 코드의 작은 상수로 처리합니다. 두 마스크 모두 기본 실험의 잡음 쪽 가중치는 $$1-m_S$$입니다.

그림의 마스크들은 소리를 바로 지우는 지우개가 아닙니다. 목표 음성이 강한 칸에 큰 비중을 주어 마이크들이 그 목소리를 어떻게 받았는지 추정하고, 잡음 쪽에서도 같은 일을 합니다. Souden MVDR과 다채널 위너 필터(MWF)는 이렇게 얻은 두 통계로 마이크를 얼마씩 섞을지 정합니다. 아래 식의 $$\mathbf u_r$$는 기준 마이크를 고르는 벡터입니다. 두 행렬 $$\boldsymbol\Phi_S,\boldsymbol\Phi_N$$은 각각 목표와 잡음의 추정 통계이며, 식에서는 수치 계산을 안정시키는 작은 항을 생략했습니다.

$$
\mathbf G=\boldsymbol\Phi_N^{-1}\boldsymbol\Phi_S,
\qquad
\mathbf w_{\mathrm{Souden}}=\frac{\mathbf G\mathbf u_r}{\operatorname{Tr}(\mathbf G)},
\qquad
\mathbf w_{\mathrm{MWF}}=(\boldsymbol\Phi_S+\boldsymbol\Phi_N)^{-1}\boldsymbol\Phi_S\mathbf u_r .
$$

`souden()`의 `G[:, :, ref]`는 주파수마다 $$\mathbf G$$의 기준 마이크 **열**을 골라냅니다. 명시적인 방향 각도는 없지만 목표 관측의 채널 간 패턴이 통계에 들어 있습니다. `apply()`는 가중치의 켤레와 모든 마이크 STFT를 곱해 채널 축을 합산합니다. 출력 $$y(t,f)=\mathbf w(f)^H\mathbf x(t,f)$$는 STFT의 513 × 929 배열이며, iSTFT를 적용하면 하나의 파형이 됩니다.

두 마이크에 목표 목소리가 똑같이 들어오지만 서로 독립인 잡음의 전력은 1과 4인 예를 보겠습니다. 두 녹음을 반씩 섞으면 출력 잡음 전력은 1.25입니다. MVDR은 잡음이 작은 마이크를 80%, 큰 마이크를 20% 반영해 이를 0.8로 낮춥니다. 두 비율의 합은 여전히 100%이므로 목표 목소리의 크기는 유지됩니다. 이 한 화자 예에서 MWF는 잡음을 더 줄이는 대신 목표 음성까지 약하게 만들 수 있습니다.

<details markdown="block">
<summary markdown="span">Derivation: Rank-one Souden identity and the Wiener gain</summary>

$$\boldsymbol\Phi_S=\phi_r\tilde{\mathbf a}\tilde{\mathbf a}^H$$, $$\tilde a_r=1$$, $$\phi_r>0$$이고 $$\boldsymbol\Phi_N$$이 양의 정부호인 bin을 가정합니다. 로딩을 쓰지 않거나 두 식에 같은 잡음 행렬을 사용한다고 하겠습니다. $$\mathbf b=\boldsymbol\Phi_N^{-1}\tilde{\mathbf a}$$, $$q=\tilde{\mathbf a}^H\mathbf b>0$$로 두면 $$\mathbf G\mathbf u_r=\phi_r\mathbf b$$, $$\operatorname{Tr}(\mathbf G)=\phi_r q=\lambda$$입니다. 따라서 Souden 필터는 $$\mathbf b/q$$이며 RTF를 조향벡터로 사용한 MVDR과 같습니다.

또한 $$\boldsymbol\Phi_N\mathbf b=\tilde{\mathbf a}$$이고 $$\boldsymbol\Phi_S\mathbf b=\phi_r q\tilde{\mathbf a}$$이므로

$$
(\boldsymbol\Phi_S+\boldsymbol\Phi_N)\mathbf b=(1+\lambda)\tilde{\mathbf a}.
$$

MWF 식의 우변에는 $$\boldsymbol\Phi_S\mathbf u_r=\phi_r\tilde{\mathbf a}$$가 있습니다. 앞 등식에 대입하면 $$\mathbf w_{\mathrm{MWF}}=\phi_r\mathbf b/(1+\lambda)=\lambda\mathbf w_{\mathrm{Souden}}/(1+\lambda)$$를 얻습니다. 이 경우 MWF는 MVDR 출력에 실수 Wiener 이득을 한 번 더 곱합니다. 실습의 별도 rank-1 검산은 로딩 없이 각각 상대 차이 $$5.4\times10^{-14}$$, $$1.3\times10^{-12}$$를 기록했습니다. 일반적인 마스크 공분산이나 두 함수의 서로 다른 로딩까지 포함한 항등식이 아닙니다.

본문 예시에서 $$\tilde{\mathbf a}=[1,1]^{\top}$$이면 $$\mathbf b=[1,1/4]^{\top}$$, $$q=5/4$$입니다. MVDR의 출력 잡음 전력은 $$0.8^2+4(0.2)^2=0.8$$이고 단순 평균은 $$0.5^2+4(0.5)^2=1.25$$입니다. 여기에 $$\phi_r=2$$를 놓으면 $$\lambda=2.5$$이므로 MWF의 추가 이득은 $$5/7$$입니다.

</details>

<details markdown="block">
<summary markdown="span">Reading the directional response at different frequencies</summary>

설명자료 6쪽 그림은 1 kHz와 2 kHz에서 자유음장 신호의 입사각을 바꾸며 $$\lvert\mathbf w^H\mathbf h(\theta)\rvert^2$$를 비교합니다. −40°와 20°의 점선부터 보면 각 필터의 상대 억제 방향을 찾기 쉽습니다. **각 곡선은 자기 최대값을 0 dB로 정규화합니다.** 20°에서 0 dB 근처라는 사실은 그 방향의 상대 응답이 크다는 뜻이지, 실제 방에서 목표 응답이 정확히 1이라는 검증은 아닙니다.

</details>

## 5. SepFormer 출력은 마스크 추정에만 사용한다

정답 음원으로 만든 IBM과 IRM은 실제 녹음에서 바로 얻을 수 없습니다. 실습은 16 kHz 단일 채널용 SepFormer에 마이크 1 혼합음을 넣어 두 음성 후보를 얻습니다. 이 중 $$s_r$$과 **절대 상관**이 큰 후보를 고릅니다. 입력 방향은 필요 없지만, **정답을 사용해 출력 순서를 맞춘 실험**입니다. 실제 시스템에서는 화자 등록 음성, 방향 추적 등 별도의 목표 지정 방법이 필요합니다.

선택한 후보 $$\mathbf e$$는 부호를 포함한 투영 계수 $$g=\mathbf e^{\top}\mathbf x_r/(\mathbf e^{\top}\mathbf e)$$로 혼합음에 맞춥니다. 이는 제곱 오차 $$\lVert\mathbf x_r-g\mathbf e\rVert^2$$를 최소화하는 한 스칼라이며, 분모가 양수인 후보에 적용합니다. 그 파형의 STFT $$\widehat S_r$$를 구하고 $$\widehat N_r=X_r-\widehat S_r$$를 잔여로 정의합니다. 잔여에는 간섭뿐 아니라 분리 오차도 남습니다. 두 진폭 제곱의 비율로 $$\widehat m_S$$를 만든 뒤, oracle 실험과 같은 `cov → souden/mwf` 경로에 넣습니다.

노트북 Step 5의 회색조 그림은 왼쪽 oracle IRM과 오른쪽 추정 마스크를 시간·주파수별로 비교합니다. 추정 마스크가 다르게 표시된 칸은 평균에 반영되는 비중이 바뀐 곳입니다. 고정한 필터의 **출력 연산**은 다채널 입력의 선형 결합입니다. 다만 입력에 따라 DNN과 공분산으로 필터를 다시 구하므로 처리 전체가 선형인 것은 아닙니다. 한 구간의 마스크 오류가 평균에서 약해질 수는 있어도, 반복되는 편향이나 조향 오차에 의한 왜곡까지 사라지지는 않습니다.

## 6. 결과는 음질과 인식으로 나눠 읽는다

설명자료 7–8쪽은 같은 혼합음의 비교입니다. 왼쪽 막대는 **높을수록 좋은** SI-SDR(dB), 오른쪽은 **낮을수록 좋은** WER(%)입니다. 회색은 마이크 1 혼합음, 파랑은 주로 방향 기반, 초록은 oracle 마스크, 주황은 추정 마스크 활용, 빨강은 DNN 파형을 직접 사용한 경우입니다. 아래는 저장된 결과에서 비교 기준이 되는 행만 골라 정리했습니다. 전체 노트북은 재실행하지 않았습니다.

| Method | SI-SDR (dB) | PESQ | STOI | WER (%) |
|---|---:|---:|---:|---:|
| Mixture (mic 1) | −0.16 | 1.11 | 0.66 | 30.6 |
| MPDR, mixture covariance | 4.53 | 1.24 | 0.80 | 16.7 |
| DoA MVDR, oracle noise covariance | 7.90 | 1.59 | 0.91 | 5.6 |
| Souden MVDR, oracle IRM | 10.33 | 1.71 | 0.93 | 11.1 |
| SepFormer waveform | 0.67 | 1.25 | 0.80 | 27.8 |
| DoA MVDR, estimated noise covariance | 5.92 | 1.38 | 0.85 | 19.4 |
| Souden MVDR, estimated mask | 7.73 | 1.60 | 0.91 | 5.6 |
| MWF, estimated mask | 7.35 | 1.35 | 0.88 | 13.9 |

<details markdown="block">
<summary markdown="span">Evaluation metrics and the limits of a single mixture</summary>

SI-SDR은 평균을 제거한 추정 파형을 기준 $$s_r$$에 투영하고, 그 투영 전력과 나머지 오차 전력의 비를 dB로 표시합니다. 전체 이득을 맞출 수 있어도 반향, 위상, 대역별 크기가 다르면 오차가 남습니다. 따라서 SepFormer 출력의 낮은 점수를 반향 제거 하나의 결과로 단정할 수 없습니다. PESQ는 wideband 지각 품질 점수, STOI는 기준에 대한 명료도 지표입니다. WER의 기준 문장은 사람이 작성한 전사가 아니라 **건조한 목표 원음을 Whisper로 인식한 결과**입니다. 정규화 후 36단어라 오류 한 건이 $$100/36\approx2.78$$%p입니다.

이 한 예에서 추정 마스크 Souden MVDR은 DNN 파형을 그대로 쓰는 것보다 두 지표 모두 나았습니다. 반면 oracle IRM은 추정 마스크보다 SI-SDR은 높지만 WER은 더 높습니다. 방향 기반 oracle과 oracle 마스크 방식도 **서로 다른 정답 정보**를 사용하므로 차이 전체를 반향이나 RTF 추정 하나로 돌릴 수 없습니다. 결과는 한 방·한 혼합음의 관찰이지 모델 순위나 통계적으로 검증된 차이가 아닙니다. 노트북 Step 6의 비교 청취에서는 두 지표가 갈리는 출력들의 목표 발음과 남은 간섭을 따로 듣는 편이 유용합니다.

</details>

## 7. 마스크 문턱값을 바꾸면 무엇이 달라지나

국소 SNR은 한 칸의 목표·잡음 진폭 비를 dB로 표현한 값입니다. 0이 아닌 진폭에서 $$20\log_{10}(\lvert S_r\rvert/\lvert N_r\rvert)=10\log_{10}(\lvert S_r\rvert^2/\lvert N_r\rvert^2)$$입니다. 예를 들어 목표 진폭이 잡음의 두 배면 전력은 네 배이고 두 식 모두 약 6.02 dB입니다. 이 값으로 만드는 문턱값 실험은 정답 분리 성분이 있는 시뮬레이션에서만 가능합니다.

설명자료 9쪽의 두 그래프는 세로축이 SI-SDR(dB), 가로축이 각 마스크의 문턱값(dB)입니다. 점 위 비율은 전체 시간·주파수 칸 중 선택된 비율이며, **모든 주파수에 같은 수의 프레임이 남는다는 뜻은 아닙니다.**

<details markdown="block">
<summary markdown="span">Experiment: varying speech and noise mask thresholds</summary>

| 실험 | 바꾸는 조건 | 저장 결과를 읽는 방법 |
|---|---|---|
| A. 목표 마스크 | $$m_S=\mathbb 1[\mathrm{SNR}>\theta_S]$$, 잡음 쪽은 $$\mathrm{SNR}<0$$으로 고정 | 문턱값을 높이면 깨끗한 목표 칸만 남습니다. 이 예에서는 약 1–4%를 쓰는 지점에서도 성능이 유지됐습니다. |
| B. 잡음 마스크 | $$m_N=\mathbb 1[\mathrm{SNR}<\theta_N]$$, 목표 쪽은 $$\mathrm{SNR}>0$$으로 고정 | 문턱값을 올릴수록 목표가 우세한 칸도 잡음 통계에 포함됩니다. 60 dB에서는 거의 전체를 골라 $$\widehat{\boldsymbol\Phi}_N\approx\mathbf R_x$$가 되며 SI-SDR이 약 7.7 dB로 내려갔습니다. |

A와 B는 한쪽을 고정하고 다른 쪽을 독립적으로 바꿉니다. 따라서 두 마스크가 빈틈없이 서로 보완된다는 보장은 없습니다. A에서 적은 샘플로 충분했다는 관찰은 이 혼합음에 한정됩니다. 너무 적게 고르면 일부 bin의 공분산이 불안정하거나 0이 될 수 있습니다. B에서는 잘못 선택한 칸이 목표를 억제해야 할 성분처럼 학습시키는 효과를 낼 수 있습니다. 다만 **정확한 조향과 완전한 rank-1 목표 성분**만 잡음 공분산에 들어오면, 제약 때문에 그 성분의 출력 전력은 일정합니다. 실제 자기 상쇄는 목표 응답 오차, 더 복잡한 잔향이나 불완전한 통계 추정과 함께 해석해야 합니다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: When target leakage can change the optimum</summary>

정확한 목표 RTF $$\tilde{\mathbf a}$$에 대해 $$\mathbf w^H\tilde{\mathbf a}=1$$이면, 잡음 공분산에 $$\beta\tilde{\mathbf a}\tilde{\mathbf a}^H$$를 추가해도 모든 가능한 필터의 목적 함수에 $$\beta\lvert\mathbf w^H\tilde{\mathbf a}\rvert^2=\beta$$만 더해집니다. 따라서 최적 필터는 그대로입니다. 반대로 제약에 쓴 벡터와 실제 목표 벡터가 다르면 이 항은 필터마다 달라집니다. 실제 목표 성분을 줄여 출력 전력을 내릴 수 있으므로, “정답 방향을 유지한다”는 설계 조건과 실제 보존은 별개입니다. 이 검산은 이상화된 제약에 대한 설명이며, 실습의 주파수별 통계 오차를 원인별로 분해한 ablation은 아닙니다.

</details>

## 마지막 핵심 정리

1. 방향 기반 필터는 **알려진 배열과 방향**, 마스크 기반 필터는 **관측에서 가중 추정한 공간 통계**로 목표와 간섭을 구분합니다.
2. 마스크 한 장은 기준 마이크에서 만들어도 공간 공분산은 모든 채널로 추정합니다. 필터를 적용하는 대상 역시 원래의 다채널 혼합음입니다.
3. rank-1 조건에서 Souden은 RTF-MVDR과 같고 MWF는 여기에 Wiener 이득을 곱한 형태입니다. 실제 표본 공분산에 이 등식이 무조건 성립하는 것은 아닙니다.
4. 이 실습의 추정 마스크는 목표 화자 선택에 정답을 사용합니다. WER과 SI-SDR을 함께 보되 단일 예의 수치를 일반화하지 않습니다.

## Study Guide

[Lecture 8-2의 MVDR](/study/speech-and-audio-recognition/lecture-08-multichannel-source-separation-02/)에서는 목표 응답을 왜 고정하는지 설명합니다. [Lecture 9-1의 공간 공분산](/study/speech-and-audio-recognition/lecture-09-multichannel-source-separation-01/)과 실습 코드를 함께 보면 각 함수의 역할이 구분됩니다. `cov()`는 마이크 사이의 통계를 구하고, `souden()`은 그 통계로 가중치를 정하며, `apply()`는 가중치를 녹음에 적용해 소리를 합칩니다. [Lecture 9-2의 DNN 결합 방식](/study/speech-and-audio-recognition/lecture-09-multichannel-source-separation-02/)은 Step 5에서 분리기의 파형과 별도의 다채널 출력을 비교하는 이유를 설명합니다.

## 복습 질문

<details markdown="block">
<summary>1. 기준 마이크의 마스크 하나로 어떻게 8채널 정보를 얻습니까?</summary>

답변: 마스크는 각 시간·주파수 칸에서 스칼라 가중치 하나만 제공합니다. 외적은 관측 벡터의 8채널 전체에서 계산하므로 결과에는 마이크 64쌍의 통계가 남습니다.

</details>

<details markdown="block">
<summary>2. DoA MVDR의 목표 응답이 1이어도 음성이 달라질 수 있습니까?</summary>

답변: 1이라는 조건은 지정한 조향벡터에만 적용됩니다. 실제 목표의 전달벡터가 반향이나 거리 때문에 다르면 실제 목표 응답은 1이 아닐 수 있습니다. 정규화 beam pattern의 0 dB만으로도 그 차이를 확인할 수 없습니다.

</details>

<details markdown="block">
<summary>3. 추정 마스크 방식이 방향 없이 작동한다면 목표 화자도 자동으로 정해집니까?</summary>

답변: 아닙니다. Souden 필터에는 각도가 들어가지 않지만, 이 실습은 SepFormer의 두 후보 중 목표에 해당하는 출력을 정답과 비교해 먼저 고릅니다. 실제 시스템에는 별도의 목표 선택 규칙이 필요합니다.

</details>

<details markdown="block">
<summary>4. 잡음 마스크 문턱값을 높일수록 왜 항상 더 좋은 것은 아닙니까?</summary>

답변: 관측을 늘리면 분산은 줄어들 수 있지만 목표가 우세한 칸도 포함되어 잡음 통계의 편향이 커질 수 있습니다. 반대쪽 극단에서 너무 적은 관측으로 행렬을 만들면 추정이 불안정합니다. 관측 개수와 순도를 같이 봐야 합니다.

</details>

## Lecture Transcript

<a href="{{ "/assets/transcripts/study/speech-and-audio-recognition/lecture-09-mvdr-lab-2026-11-19-transcript.html" | relative_url }}" target="_blank" rel="noopener">Lecture 9 MVDR lab transcript · 2026-11-19</a> — 강의 종료까지 분리한 강의 전용 음원의 자동 전사입니다. 전문 용어·수식·화자 귀속은 전 구간 직접 청취로 교정되지 않았습니다.

## Source Materials

- <a href="https://ecampus.kookmin.ac.kr/mod/ubfile/view.php?id=2005510" target="_blank" rel="noopener">Lecture 9 MVDR lab notebook — KMU eCampus</a>
- <a href="https://ecampus.kookmin.ac.kr/mod/ubfile/view.php?id=2005511" target="_blank" rel="noopener">Lecture 9 lab guide — KMU eCampus</a>
- <a href="https://huggingface.co/speechbrain/sepformer-whamr16k" target="_blank" rel="noopener">SpeechBrain SepFormer model card (WHAMR!, 16 kHz)</a>
- <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html" target="_blank" rel="noopener">SciPy STFT reference</a>

실습 원문 두 건은 eCampus 수강자 로그인이 필요합니다.
