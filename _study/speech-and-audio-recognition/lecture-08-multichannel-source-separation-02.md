---
layout: default
date: 2026-11-05 15:45:00 +0900
title: "Lecture 8: Multi-channel Source Separation II"
course: "Speech and Audio Recognition"
topic: "Side Lobes, Spatial Covariance, and MVDR Beamforming"
order: 11
major_topic: "Speech and Audio Processing"
keywords:
  - "Beamforming"
  - "Side Lobes"
  - "Covariance Matrix"
  - "MVDR"
  - "MPDR"
  - "Spatial Filtering"
  - "Capon Spectrum"
---

# Lecture 8: Multi-channel Source Separation II

Source PDF: `speech-audio-lecture-08-2.pdf` — *Multi-channel Source Separation 1-2*, 안인규(Inkyu An), 17 slides.

> **핵심:** DAS는 목표 방향의 소리를 정렬해 더하지만, 다른 방향의 소리까지 모두 없애지는 못한다. **MVDR는 목표 음성의 응답을 유지한다는 조건 아래, 관측한 간섭·잡음의 공간적 관계를 이용해 출력 파워를 최소화한다.** 그 관계를 담는 것이 공분산 행렬이다. 간섭 방향에 깊은 null을 만드는 능력에는 센서 잡음 증폭과 방향 오차에 대한 민감성이라는 대가가 따른다.

## 전체 흐름

| 슬라이드 | 주제 | 확인할 관계 |
|---|---|---|
| 1–3 | DAS와 steering vector 복습 | 시간 지연 보상은 주파수별 위상 보상이며, 목표 방향의 합산 이득을 1로 맞춘다. |
| 4–6 | Side lobe와 넓은 main lobe | 다른 방향의 누설과 가까운 두 화자의 구분 실패는 서로 다른 문제다. |
| 7–9 | MVDR·MPDR의 문제 정의와 해 | 목표 응답은 고정하고, 공분산에 맞춰 가중치를 바꾼다. |
| 10–11 | 해의 유도와 출력 파워 | 행렬의 각 원소와 $$\mathbf w^H\mathbf R\mathbf w$$가 실제로 무엇을 계산하는지 확인한다. |
| 12–13 | Null의 수와 steering vector의 관계 | 마이크 수, 선형 독립성, 방향 간 유사도가 억제 가능성을 결정한다. |
| 14–15 | 간섭 억제의 대가 | 깊은 null과 센서 잡음 증폭·모델 오차 사이에 균형이 필요하다. |
| 16–17 | 방향 탐색과 남는 문제 | Capon spectrum으로 DoA를 탐색하되, 정확한 공간 모델이 필요하다. |

아래에서는 far-field 평면파, 동일한 감도의 무지향성 마이크로 이루어진 균일 선형 배열(ULA), 주파수 bin별 narrowband 모델을 기본으로 둔다. 잔향이 강하거나 음원이 배열에 가까우면 단순한 시간차 steering vector만으로는 전달 경로를 충분히 나타내지 못할 수 있다.

## 1. DAS는 목표 방향의 위상을 맞추어 평균한다

[Lecture 8 I의 28번 슬라이드 해설]({{ "/study/speech-and-audio-recognition/lecture-08-multichannel-source-separation-01/#8-beam-pattern-주파수가-높을수록-좁아지는-이유" | relative_url }})에서는 같은 배열도 주파수와 마이크 간격에 따라 방향 응답이 달라지는 모습을 다룬다. 이번 강의는 **그 응답에서 간섭이 남는 이유와, 관측 신호에 맞춰 응답을 바꾸는 방법**으로 이어진다.

기준 마이크에서 $$m$$번째 마이크까지의 추가 도달 시간이 $$\tau_m$$라면, 한 주파수 성분은 $$e^{-j\omega\tau_m}$$만큼 위상이 바뀐다. 이 채널별 위상 관계를 모은 벡터가 steering vector $$\mathbf h$$다.

$$
\tau_m(\theta)=\frac{(m-1)d\sin\theta}{c},\qquad
\mathbf h(\theta,\omega)=\begin{bmatrix}e^{-j\omega\tau_1(\theta)}&\cdots&e^{-j\omega\tau_M(\theta)}\end{bmatrix}^{T}
$$

| 기호 | 의미 | 단위·크기 |
|---|---|---|
| $$M,m$$ | 마이크 수와 마이크 index | 무차원, $$m=1,\ldots,M$$ |
| $$d,c$$ | 마이크 간격과 음속 | $$\mathrm m$$, $$\mathrm{m/s}$$ |
| $$\theta,\omega$$ | broadside 기준 방향과 각주파수 | rad, rad/s; 그림의 방향 축은 degree |
| $$\tau_m$$ | 기준 마이크에 대한 상대 도달 시간 | s |
| $$\mathbf x(t,f)$$ | 같은 frame·주파수에서 모은 복소 마이크 관측값 | $$M\times1$$; 원 신호의 STFT 단위 |
| $$\mathbf h,\mathbf w$$ | steering vector와 beamformer 가중치 | $$M\times1$$; 여기서는 무차원 |
| $$H,*,j$$ | 켤레전치, 복소켤레, $$j^2=-1$$ | 연산·무차원 |
| $$y,\mathbf R,\beta$$ | 출력, 공간 상관 행렬, 출력 평균 파워 | STFT 단위, 그 제곱, 그 제곱 |
| $$T,f$$ | 평균에 사용한 frame 수와 주파수 bin index | 무차원; 물리 주파수는 별도로 Hz로 표시 |

디지털 신호가 정규화 amplitude라면 파워도 그 amplitude의 제곱 단위다. STFT의 scaling을 정의하지 않은 값을 곧바로 음향 세기 $$\mathrm{W/m^2}$$나 확률로 읽지는 않는다.

슬라이드 3의 DAS는 $$\mathbf w_{\mathrm{DAS}}=\mathbf h/M$$, 출력은 $$y=\mathbf w^H\mathbf x$$다. 출력 연산에 켤레전치가 있으므로 실제 곱해지는 계수는 $$e^{+j\omega\tau_m}/M$$가 된다. 목표 신호 $$\mathbf x=\mathbf hS$$를 대입하면 **서로 다른 위상이 정렬되어 원래 기준 신호 $$S$$가 남는다.**

두 마이크의 목표 방향 위상이 $$[1,-j]^T$$라면 관측은 $$[S,-jS]^T$$다. 가중치를 $$[1,-j]^T/2$$로 두면 출력은 $$\{S+j(-jS)\}/2=S$$다. 단순히 두 관측을 더하는 것과 달리, 두 번째 채널의 위상차를 먼저 없앤다.

<details markdown="block">
<summary markdown="span">Derivation: Unit target gain and time alignment</summary>

여기서 steering vector의 각 성분은 크기가 1이므로 $$\mathbf h^H\mathbf h=M$$다. 따라서

$$
\mathbf w_{\mathrm{DAS}}^H\mathbf h
=\frac{\mathbf h^H\mathbf h}{M}=1.
$$

이는 정의한 평면파 모델에서의 정확한 등식이다. 채널별 감쇠까지 포함한 일반 전달 벡터라면 같은 정규화의 matched filter는 $$\mathbf h/(\mathbf h^H\mathbf h)$$이며, 항상 $$M$$으로 나눌 수 있는 것은 아니다.

슬라이드 2의 시간영역 보상도 같은 관계다. $$x_m(t)=s(t-\tau_m)$$이면 $$x_m*\delta(t+\tau_m)=s(t)$$다. 음의 지연, 즉 advance가 필요한 표현은 오프라인 정렬이다. 실시간 구현에서는 모든 채널에 충분한 공통 지연을 추가해 인과적으로 만들며, 기준 출력도 그만큼 늦어진다.

</details>

## 2. Side lobes는 목표 밖의 방향에 남은 작은 통과 구간이다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-04.png" | relative_url }}" alt="Lecture 8 II slide 4: broadside main lobe and smaller side lobes marked by red arrows on a dB beam pattern" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=4" | relative_url }}" target="_blank" rel="noopener">slide 4</a>.</figcaption>
</figure>

그림의 가로축은 입사 방향, 세로축은 목표 방향의 응답을 0 dB로 정규화한 beam pattern이다. 가운데 0°의 큰 봉우리가 **main lobe**, 양옆 빨간 화살표가 가리키는 작은 봉우리들이 **side lobes**다. 봉우리 사이의 깊은 골은 **null**이다. Main lobe는 보통 목표 방향을 포함하는 두 첫 null 사이의 주된 구간을 뜻한다.

Side lobe는 별도의 소리나 반사파가 아니다. **같은 필터가 목표 밖의 방향에도 0이 아닌 응답을 갖는 현상**이다. 목표 방향의 위상을 맞추어도 다른 모든 방향에서 마이크 신호가 정확히 상쇄되는 것은 아니다. 한 방향에서는 서로 잘 지워져 null이 생기고, 다른 방향에서는 일부가 남아 작은 봉우리를 만든다.

방향을 골라 통과시키는 필터라고 생각하면 이해하기 쉽다. 목표 방향은 큰 통과 구간, side lobe는 원치 않지만 남은 작은 통과 구간이다. 실제로 벽에 구멍이 있거나 소리가 물리적으로 차단되는 것은 아니며, **채널별 복소수 합의 크기**를 방향에 따라 그린 것이다.

### 2.1 `−13 dB`여도 강한 간섭은 남는다

슬라이드의 약 $$-13\ \mathrm{dB}$$는 균일 가중 배열의 첫 side lobe를 설명하는 대표값이지 모든 DAS의 상수가 아니다. 이상적인 동일 감도 ULA에서 주파수·간격이 해당 side lobe를 visible angle 안에 놓고, 마이크 수가 충분히 크면 약 $$-13.26\ \mathrm{dB}$$에 가까워진다. 유한 배열에서는 값이 달라지며, 예를 들어 $$M=5$$이면 약 $$-12.04\ \mathrm{dB}$$다.

응답이 $$-13\ \mathrm{dB}$$라면 그 방향 신호의 amplitude는 약 0.224배, 파워는 약 0.050배다. 약해졌지만 0은 아니다. **입력 간섭이 목표보다 20 dB 강하면, 13 dB 억제한 뒤에도 출력 간섭은 목표보다 약 7 dB 강하다.** 목표 응답이 0 dB이고 두 입력의 기준 파워가 같게 정의되었다는 설명용 계산이다.

### 2.2 Main lobe·side lobe·grating lobe는 구분한다

| 구분 | 방향 응답에서의 의미 | 무엇이 문제인가? |
|---|---|---|
| Main lobe | 목표를 포함하는 주된 봉우리 | 폭이 넓으면 가까운 두 방향을 함께 통과시킨다. |
| Side lobe | 주된 봉우리 밖에 남는 작은 봉우리 | 다른 방향의 강한 간섭이 누설된다. |
| Grating lobe | 서로 다른 방향의 채널별 위상이 같아 생기는 공간적 모호성 | 목표와 비슷한 큰 응답이 반복될 수 있다. 단순한 작은 누설이 아니다. |

균일 가중치를 tapering하면 side lobe를 줄일 수 있지만, 보통 main lobe가 넓어지는 대가가 따른다. 이것은 시간 window가 spectral leakage와 분해능 사이에서 하는 조절과 수학적으로 닮았다. 다만 여기서 유한 구간은 **시간 sample이 아니라 마이크 위치**, 변하는 축은 **시간 주파수가 아니라 공간 위상차**다. Side lobe를 줄였다는 사실만으로 공간 aliasing까지 해결했다고 말할 수는 없다. Grating lobe와 배열 geometry의 관계는 <a href="https://www.mathworks.com/help/phased/ref/plotgratinglobediagram.html" target="_blank" rel="noopener">MathWorks의 grating-lobe 설명</a>에서도 확인할 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: Array response and the origin of side lobes</summary>

주파수 하나를 고정하고 목표 방향을 $$\theta_0$$로 둔다. $$m=0,\ldots,M-1$$로 index를 바꾸면 DAS의 방향 응답은

$$
A(\theta;\theta_0)
=\mathbf w_{\mathrm{DAS}}(\theta_0)^H\mathbf h(\theta)
=\frac{1}{M}\sum_{m=0}^{M-1}e^{-jm\psi},
\qquad
\psi=\frac{\omega d}{c}(\sin\theta-\sin\theta_0).
$$

등비수열의 합을 사용하면

$$
A=e^{-j(M-1)\psi/2}\frac{\sin(M\psi/2)}{M\sin(\psi/2)},\qquad
|A|=\left|\frac{\sin(M\psi/2)}{M\sin(\psi/2)}\right|.
$$

분모가 0이 되는 $$\psi=2\pi k$$에서는 원래 합 또는 극한을 사용하며 응답 크기는 1이다. 그 밖에서 분자가 0이면 null, 두 null 사이에서 합의 크기가 다시 커지면 lobe가 된다. $$\theta=\theta_0$$에서는 $$\psi=0$$이므로 $$A=1$$이다.

예를 들어 $$M=5,d=\lambda/2,\theta_0=0$$인 경우 첫 양의 null은 $$\sin\theta=2/5$$, 즉 약 23.58°다. 첫 side lobe의 최대 amplitude는 약 0.25이므로 $$20\log_{10}(0.25)\approx-12.04\ \mathrm{dB}$$다. 이 예제는 source 그림의 미공개 배열 설정을 복원한 결과가 아니라, 위 식을 확인하기 위한 별도 계산이다.

dB 응답은 $$20\log_{10}\lvert A\rvert=10\log_{10}\lvert A\rvert^2$$다. 파워와 amplitude에 같은 로그 계수를 쓰지 않는다.

</details>

## 3. DAS에서 MVDR로: 목표는 유지하고 간섭에 맞춰 바꾼다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-05.png" | relative_url }}" alt="Lecture 8 II slide 5: two speaker directions inside one broad DAS main lobe" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=5" | relative_url }}" target="_blank" rel="noopener">slide 5</a>.</figcaption>
</figure>

위 그림에서 두 검은 화살표는 서로 다른 화자 방향인데, 둘 다 0 dB 부근의 넓은 봉우리 안에 들어간다. 이때는 side lobe만 낮춰도 두 화자가 함께 남는다. **목표 방향으로 조준하는 것과 두 화자를 분리하는 것은 같은 일이 아니다.** 그림의 각도 축과 큰 봉우리의 폭을 먼저 읽어야 하는 이유다.

DAS는 배열 위치·주파수·조준 방향을 정하면 가중치가 정해진다. 간섭이 어디에 얼마나 강하게 들어오는지는 그 가중치 계산에 반영하지 않는다. 슬라이드 6–7의 질문은 이 고정된 응답을 바꾸어, 목표 방향은 유지하면서 실제 간섭 방향의 응답을 낮출 수 있는가이다.

**MVDR(Minimum Variance Distortionless Response)**는 이를 제약 최적화 문제로 만든다. 여기서 variance는 영평균 신호의 평균 파워에 대응하고, distortionless는 가정한 목표 steering vector에 대한 응답을 보존한다는 뜻이다. 잘못된 방향 모델이나 잔향까지 자동으로 보정한다는 뜻은 아니다.

$$
\min_{\mathbf w}\ \mathbf w^H\mathbf R\mathbf w
\qquad\text{subject to}\qquad
\mathbf w^H\mathbf h_1=1.
$$

$$\mathbf h_1$$은 목표 방향의 steering vector다. 목적함수는 출력을 작게 만들라고 요구하고, 오른쪽 조건은 목표 음성만큼은 지우지 못하게 한다. **조건이 없다면 $$\mathbf w=\mathbf0$$, 즉 모든 소리를 꺼 버리는 무의미한 해가 된다.** 공분산 행렬 $$\mathbf R$$은 어떤 채널 조합에서 파워가 많이 남는지 알려 준다.

## 4. 공분산 행렬은 마이크 사이의 관계를 모은다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-11.png" | relative_url }}" alt="Lecture 8 II slide 11: output power w-H R w, frame-averaged spatial correlation matrix, and a sum of source and sensor-noise terms" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=11" | relative_url }}" target="_blank" rel="noopener">slide 11</a>.</figcaption>
</figure>

그림은 위에서부터 **출력 파워 → 그것을 계산하는 행렬 → 행렬에 음원별 관계가 더해지는 방식**의 순서로 읽는다. 가운데의 $$M\times M$$은 주파수 bin 수가 아니라 **마이크와 마이크의 모든 쌍**이다. 각 주파수 bin마다 별도의 행렬을 만든다.

공분산 행렬(covariance matrix)은 여러 변수의 변동이 어떻게 연결되는지 모은 표다. 이 강의의 변수는 마이크별 복소 STFT 값이다. 한 frame에서 같은 주파수의 관측을 세로로 쌓으면 $$\mathbf x=[X_1,\ldots,X_M]^T$$이고, 강의에서 사용하는 행렬은 다음과 같다.

$$
\mathbf R=E[\mathbf x\mathbf x^H],\qquad
R_{mn}=E[X_mX_n^*].
$$

엄밀한 공분산은 $$\mathbf C=E[(\mathbf x-\boldsymbol\mu)(\mathbf x-\boldsymbol\mu)^H]$$, $$\boldsymbol\mu=E[\mathbf x]$$다. 따라서 **영평균을 가정하면 $$\mathbf C=\mathbf R$$**다. 평균을 빼지 않은 강의의 식은 일반적으로 spatial correlation matrix 또는 비중심 2차 모멘트라고 부르는 편이 정확하다. 아래의 출력 파워 식은 평균이 0이 아니어도 $$\mathbf R=E[\mathbf x\mathbf x^H]$$로 성립한다.

### 4.1 대각은 각 마이크의 파워, 비대각은 채널 사이의 관계다

두 마이크라면

$$
\mathbf R=
\begin{bmatrix}
E[|X_1|^2] & E[X_1X_2^*]\\
E[X_2X_1^*] & E[|X_2|^2]
\end{bmatrix}.
$$

대각 원소는 각 마이크의 평균 파워로, 실수이고 0 이상이다. 비대각 원소는 같은 frame·주파수에서 두 채널이 어떤 복소 관계로 함께 변하는지 담는다. 예를 들어 $$X_2=e^{-j\phi}X_1$$인 한 음원만 있다면 $$R_{12}=E[\lvert X_1\rvert^2]e^{+j\phi}$$다. **크기뿐 아니라 채널 사이의 위상차도 남는다.** 아래쪽 원소는 위쪽 원소의 복소켤레이므로 $$\mathbf R^H=\mathbf R$$인 Hermitian 행렬이 된다.

이 행렬은 마이크 사이의 관계를 적은 기록표처럼 볼 수 있다. 대각 칸은 각 채널의 크기, 짝을 이룬 칸은 두 채널의 결합 관계에 대응한다. 다만 단순한 유사도 점수표는 아니다. **정규화된 상관계수와 달리 원소가 0–1 범위에 있지 않으며, 비대각은 복소수가 될 수 있다.** 거리나 정확도를 평가하는 metric도 아니다.

### 4.2 네 frame으로 직접 계산한다

다음은 계산을 보기 위한 작성자 예제다. 한 주파수 bin에서 네 frame의 관측이 아래와 같다고 하자. 단위는 정규화된 STFT amplitude이며, 이 예제의 값은 모두 실수인 특수한 경우다.

<div class="table-caption">Supplementary table: Four snapshots at one frequency bin.</div>

| Frame | $$X_1$$ | $$X_2$$ | DAS 출력 $$(X_1+X_2)/2$$ |
|---|---|---|---|
| 1 | 2 | 1 | 1.5 |
| 2 | −2 | −1 | −1.5 |
| 3 | 1 | 2 | 1.5 |
| 4 | −1 | −2 | −1.5 |

각 채널의 표본 평균은 0이다. Frame별 바깥곱 $$\mathbf x\mathbf x^H$$를 평균하면

$$
\widehat{\mathbf R}
=\frac14\sum_{t=1}^{4}\mathbf x_t\mathbf x_t^H
=\begin{bmatrix}2.5&2\\2&2.5\end{bmatrix}.
$$

첫 대각 원소 2.5는 $$(4+4+1+1)/4$$, 비대각 원소 2는 $$(2+2+2+2)/4$$다. 두 채널은 각각 파워 2.5를 가지면서 같은 부호로 함께 움직이는 성분도 강하다. DAS 가중치 $$\mathbf w=[0.5,0.5]^T$$를 넣으면 $$\mathbf w^H\widehat{\mathbf R}\mathbf w=2.25$$다. 출력 네 값의 제곱 평균도 모두 $$1.5^2=2.25$$이므로 일치한다.

반대로 $$[0.5,-0.5]^T$$로 빼면 출력 파워는 0.25까지 낮아진다. 그러나 목표 steering vector가 $$[1,1]^T$$라면 목표 응답도 0이 된다. **파워가 작다는 사실만으로 좋은 음성 분리가 된 것은 아니다.** MVDR가 공분산과 목표 응답 조건을 함께 사용하는 이유다.

### 4.3 왜 MVDR에 이 행렬이 필요한가

한 마이크의 파워만 보면 소리가 크다는 사실은 알 수 있지만, 다른 마이크와 어떤 위상 관계로 들어왔는지는 알 수 없다. $$\mathbf R$$은 두 정보를 함께 남긴다. MVDR는 이 관계를 바탕으로 **목표의 위상 패턴은 유지하면서, 강한 간섭의 위상 패턴은 덜 통과시키는 채널 조합**을 찾는다.

실제 추정식은 $$\widehat{\mathbf R}(f)=T^{-1}\sum_t\mathbf x(t,f)\mathbf x(t,f)^H$$다. 녹음 전체에서 평균할지, 짧은 구간마다 갱신할지는 신호가 얼마나 빨리 바뀌는지에 따른다. 너무 짧으면 추정이 불안정하고, 너무 길면 이동한 화자의 오래된 관계까지 섞인다. 이 $$1/T$$ 식은 파워 평균이며, 평균을 추정해 제거한 표본 공분산의 불편추정식 $$1/(T-1)$$과 구분한다.

<details markdown="block">
<summary markdown="span">Derivation: From microphone snapshots to output power</summary>

출력은 복소 스칼라 $$y=\mathbf w^H\mathbf x$$다. 그러므로

$$
|y|^2=(\mathbf w^H\mathbf x)(\mathbf x^H\mathbf w),\qquad
E[|y|^2]=\mathbf w^HE[\mathbf x\mathbf x^H]\mathbf w=\mathbf w^H\mathbf R\mathbf w.
$$

가중치를 고정한 구간의 기대값에 대한 정확한 등식이다. 모든 $$\mathbf w$$에 대해 파워는 0 이상이므로 $$\mathbf R$$은 positive semidefinite다. 영평균일 때는 출력 variance와도 같다.

두 음원과 센서 잡음의 모델을 $$\mathbf x=\mathbf h_1S_1+\mathbf h_2S_2+\mathbf n$$으로 두자. 서로 비상관이고 센서 잡음이 white이면 교차항의 기대값이 사라져

$$
\mathbf R_x
=\sigma_1^2\mathbf h_1\mathbf h_1^H
+\sigma_2^2\mathbf h_2\mathbf h_2^H
+\sigma_n^2\mathbf I
$$

가 된다. $$\sigma_k^2=E[\lvert S_k\rvert^2]$$는 각 음원의 파워, $$\sigma_n^2$$는 마이크당 센서 잡음 파워, $$\mathbf I$$는 $$M\times M$$ 항등행렬이다. 각 $$\mathbf h_k\mathbf h_k^H$$는 한 음원이 마이크들에 남기는 공간 패턴이다. 비상관 가정이 깨지면 생략한 교차항을 포함해야 한다.

</details>

## 5. MVDR와 MPDR는 어떤 공분산을 사용하는지가 다르다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-08.png" | relative_url }}" alt="Lecture 8 II slide 8: constrained beamformer with a preserved target direction and a reduced interferer response; Rx for MPDR and Rn for MVDR" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=8" | relative_url }}" target="_blank" rel="noopener">slide 8</a>.</figcaption>
</figure>

오른쪽 파란 상자는 같은 최적화 모양에도 두 종류의 $$\mathbf R$$이 있음을 구분한다. **이 강의에서는 MPDR를 목표까지 들어 있는 혼합 신호의 $$\mathbf R_x$$, MVDR를 목표를 제외한 간섭·잡음의 $$\mathbf R_n$$**으로 구분한다. 문헌에 따라 명칭이 겹쳐 쓰이기도 하므로 이름뿐 아니라 실제 식에 넣는 행렬을 확인해야 한다.

| 방법 | 목적함수에 사용하는 관계 | 그대로 남는 조건 |
|---|---|---|
| DAS | 신호의 공분산을 사용하지 않음 | 배열 구조·주파수·조준 방향을 알아야 한다. |
| MPDR | $$\mathbf R_x=E[\mathbf x\mathbf x^H]$$ | 목표 응답 제약이 정확해야 한다. |
| MVDR | $$\mathbf R_n=E[\mathbf n\mathbf n^H]$$ | 목표를 제외한 간섭·잡음 통계를 추정해야 한다. |

목표 steering vector가 정확하고 목표와 잡음이 비상관이면 두 최적해는 같아질 수 있다. 목표 파워 항은 $$\mathbf w^H\mathbf h_1=1$$ 때문에 상수로 고정되므로, 그것을 포함해 최소화해도 남은 부분을 최소화하는 가중치는 변하지 않기 때문이다. **현실의 추정 오차까지 고려하면 두 방식을 무조건 같은 것으로 취급할 수는 없다.** 특히 잘못 지정한 목표 방향은 보존 제약의 보호를 받지 못한다.

## 6. MVDR 가중치는 무엇을 계산하는가

$$\mathbf R$$이 Hermitian positive-definite이고 목표 벡터가 0이 아니면, 단위 목표 응답에 대한 해는 다음과 같다.

$$
\boxed{\mathbf w_{\mathrm{MVDR}}=
\frac{\mathbf R_n^{-1}\mathbf h_1}
{\mathbf h_1^H\mathbf R_n^{-1}\mathbf h_1}}
$$

먼저 $$\mathbf R_n^{-1}\mathbf h_1$$은 간섭·잡음이 강하게 나타나는 공간 조합을 덜 사용하는 방향으로 가중치를 조절한다. 그 결과 목표 응답의 크기도 달라질 수 있으므로, 분모로 나누어 **목표 응답을 다시 1로 맞춘다.** 역행렬 자체가 음성을 분리하는 마법의 연산인 것은 아니다. 통계와 목표 방향을 함께 넣어야 한다.

실제 계산에서는 역행렬을 명시적으로 만들기보다 $$\mathbf R_n\mathbf u=\mathbf h_1$$을 풀고 $$\mathbf w=\mathbf u/(\mathbf h_1^H\mathbf u)$$로 정규화하는 방식을 사용할 수 있다. 이때 $$\mathbf R_n$$과 $$\mathbf h_1$$은 모두 같은 주파수 bin에 해당해야 한다. 정규화된 해의 형태는 <a href="https://www.mathworks.com/help/phased/ref/mvdrweights.html" target="_blank" rel="noopener">MathWorks의 MVDR weights 공식 문서</a>와 같다.

### 6.1 방향성이 없는 잡음만 있으면 DAS가 나온다

각 마이크에 같은 파워의 비상관 잡음만 있다면 $$\mathbf R_n=\sigma_n^2\mathbf I$$다. 특정 방향을 더 억제할 근거가 없으므로 위 해는 $$\mathbf h_1/(\mathbf h_1^H\mathbf h_1)=\mathbf h_1/M$$, 즉 DAS로 줄어든다. **DAS와 MVDR는 무관한 두 계산이 아니라, 공간 잡음 관계가 단순할 때 연결되는 방법**이다.

### 6.2 공분산 추정이 나쁘면 해도 불안정하다

평균에 사용한 snapshot이 $$T<M$$이면 표본 행렬의 rank는 최대 $$T$$라서 역행렬이 존재하지 않는다. $$T\ge M$$이어도 관측이 서로 종속적이면 특이하거나 수치적으로 불안정할 수 있다. 흔한 안정화는 $$\widehat{\mathbf R}_\delta=\widehat{\mathbf R}+\delta\mathbf I$$라는 **diagonal loading**이다. $$\delta>0$$은 파워와 같은 단위이며, 모든 공간 방향에 최소한의 잡음 비용을 부여한다.

Loading이 커지면 불안정한 null에 덜 집착하지만 세밀한 간섭 억제도 줄어든다. 마이크 위치·gain/phase 보정과 steering 오차를 함께 점검해야 한다. 행렬에 작은 수를 더했다는 이유만으로 모델 오차까지 해결된 것은 아니다. 음성용 구현에서 noise PSD와 diagonal loading을 다루는 예는 <a href="https://docs.pytorch.org/audio/main/generated/torchaudio.transforms.SoudenMVDR.html" target="_blank" rel="noopener">TorchAudio의 SoudenMVDR 문서</a>에 있다. Souden 방식의 구체적인 가중치 구성은 여기서 유도한 steering-vector 식과 동일한 표기라고 가정하지 않는다.

<details markdown="block">
<summary markdown="span">Derivation: The constrained minimum and complex target gain</summary>

슬라이드 10처럼 우선 목표 응답을 1로 둔다. 실수 목적함수를 만드는 Lagrangian은

$$
\mathcal L=
\mathbf w^H\mathbf R\mathbf w
+\lambda^*(\mathbf w^H\mathbf h_1-1)
+\lambda(\mathbf h_1^H\mathbf w-1).
$$

$$\mathbf w$$와 $$\mathbf w^*$$를 독립 변수로 다루어 미분하면

$$
\frac{\partial\mathcal L}{\partial\mathbf w^*}
=\mathbf R\mathbf w+\lambda^*\mathbf h_1=\mathbf0,
\qquad
\mathbf w=-\lambda^*\mathbf R^{-1}\mathbf h_1.
$$

$$D=\mathbf h_1^H\mathbf R^{-1}\mathbf h_1$$로 두면 positive-definite 조건에서 $$D$$는 양의 실수다. 제약식은 $$-\lambda D=1$$이므로 $$\lambda=-1/D$$, 따라서 정규화된 해가 나온다. 목적함수가 엄밀히 볼록하므로 이 stationary point는 유일한 최소다.

슬라이드 9의 일반 목표 응답 $$\mathbf w^H\mathbf h_1=b_0$$에서는

$$
\mathbf w=\frac{\mathbf R^{-1}\mathbf h_1}{D}b_0^*.
$$

$$b_0$$는 무차원 복소 응답이다. 가중치에 $$b_0^*$$를 곱해야 켤레전치한 출력에서 $$b_0$$가 된다. 예를 들어 $$\mathbf R=\operatorname{diag}(2,1)$$, $$\mathbf h_1=[1,j]^T$$, $$b_0=j$$이면 $$D=1.5$$이고 $$\mathbf w=[-j/3,2/3]^T$$다. 실제로 $$\mathbf w^H\mathbf h_1=j/3+2j/3=j$$다.

또한 $$\mathbf R_x=\sigma_s^2\mathbf h_1\mathbf h_1^H+\mathbf R_n$$인 이상적인 경우, 가능한 모든 가중치에서

$$
\mathbf w^H\mathbf R_x\mathbf w
=\sigma_s^2|\mathbf w^H\mathbf h_1|^2
+\mathbf w^H\mathbf R_n\mathbf w
=\sigma_s^2+\mathbf w^H\mathbf R_n\mathbf w.
$$

상수 항을 더해도 최소화 지점은 바뀌지 않는다. 이것이 정확한 목표 제약 아래 MPDR와 MVDR가 같은 해를 갖는 이유다.

</details>

## 7. 간섭 방향의 null은 파워 최소화에서 생긴다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-14.png" | relative_url }}" alt="Lecture 8 II slide 14: fixed target power, interference response, and sensor-noise cost; low-noise and high-noise patterns show different null depths" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=14" | relative_url }}" target="_blank" rel="noopener">slide 14</a>.</figcaption>
</figure>

먼저 위 식의 세 항을 읽는다. 목표 응답이 1이면 첫 목표 파워 항은 고정된다. 남은 두 항은 **간섭이 출력에 남긴 파워**와 **가중치 때문에 센서 잡음이 출력에 남긴 파워**다.

$$
\beta=\sigma_1^2
+\sigma_2^2|\mathbf w^H\mathbf h_2|^2
+\sigma_n^2\|\mathbf w\|^2.
$$

14번 슬라이드는 앞서 나온 목표 보존 조건, 공분산, null을 **하나의 식과 두 beam pattern으로 종합한다.** 아래 그림은 다음 순서로 읽으면 된다.

1. **초록 점선부터 본다.** 가로축은 방향, 세로축은 응답 파워의 dB다. 목표 방향 0°에서는 회색 DAS와 파란 MVDR 모두 0 dB다. 서로 다른 필터라도 목표 응답은 1로 유지한다.
2. **빨간 점선에서 두 곡선을 비교한다.** 약 20°의 speaker 2가 간섭이다. DAS는 고정된 패턴이므로 이 방향의 응답을 특별히 낮추지 못한다. MVDR는 관측한 공간 통계에 맞춰 패턴을 바꾸어 간섭 방향에 더 깊은 골을 만든다. 목표와 간섭이 같은 넓은 main lobe에 가까이 있어도, 단순 평균과 다른 가중치로 구분하려는 것이다.
3. **왼쪽과 오른쪽의 잡음 조건을 비교한다.** 센서 잡음 파워가 왼쪽은 $$\sigma_n^2=0.01$$, 오른쪽은 $$\sigma_n^2=10$$이다. 원문에 표시된 간섭 방향의 MVDR 응답은 각각 약 −66 dB와 −15 dB다. 같은 목표 응답을 보존해도, 센서 잡음이 클 때는 깊은 null을 만드는 가중치의 비용이 더 커진다.

이 dB 값은 **그 방향 신호에 대한 필터의 파워 응답**이다. 최종 출력 SNR이나 음성 품질 점수가 아니며, −66 dB를 완전한 0으로 읽을 수도 없다. 또한 원문의 표시값이지, 생성 설정이 모두 제공된 실험 결과를 독립적으로 재현한 수치는 아니다.

잡음이 커지면 $$\|\mathbf w\|^2$$의 비용이 커져, 간섭을 완벽히 지우기 위해 큰 가중치를 쓰는 선택이 덜 유리하다. 따라서 슬라이드의 `0: null`은 억제 방향을 설명하는 말로 읽어야 한다. **일반적인 유한 잡음 MVDR가 간섭 응답을 항상 정확히 0으로 만든다는 뜻은 아니다.**

### 7.1 두 마이크의 가중치를 실제로 비교한다

다음은 source 그래프와 별개의 작성자 예제다. 한 주파수에서 목표와 간섭의 steering vector를 $$\mathbf h_1=[1,1]^T$$, $$\mathbf h_2=[1,-j]^T$$로 두자. 간섭 파워는 9, 마이크당 독립 센서 잡음 파워는 1이다. 그러면 $$\mathbf R_n=9\mathbf h_2\mathbf h_2^H+\mathbf I$$다.

<div class="table-caption">Supplementary table: Unit target gain with different interference–noise tradeoffs.</div>

| 가중치 $$\mathbf w$$ | 목표 응답 | 간섭 파워 | 센서 잡음 파워 | 둘의 합 |
|---|---|---|---|---|
| DAS: $$[0.5,0.5]^T$$ | 1 | 4.5 | 0.5 | 5.0 |
| MVDR: $$[0.5-0.45j,0.5+0.45j]^T$$ | 1 | 0.045 | 0.905 | 0.95 |
| 정확한 null: $$[0.5-0.5j,0.5+0.5j]^T$$ | 1 | 0 | 1.0 | 1.0 |

MVDR는 DAS보다 간섭을 크게 줄이지만 정확한 null을 택하지는 않는다. **간섭을 0.045만큼 남기는 대신 잡음을 더 줄여, 전체 비용 0.95를 달성하는 편이 1.0보다 낫기 때문**이다. 여기서 비교한 것은 같은 목표 응답 아래의 파워이며, 실제 음성 데이터의 품질 점수나 인식 정확도가 아니다.

<details markdown="block">
<summary markdown="span">Derivation: Checking the two-microphone optimum</summary>

이 예제에서 $$\mathbf R_n=\begin{bmatrix}10&9j\\-9j&10\end{bmatrix}$$이고, 앞의 MVDR 식을 적용하면 표의 해가 나온다. 해를 포함하는 한 변수 표현 $$\mathbf w=[0.5-aj,0.5+aj]^T$$를 사용해 계산을 확인할 수 있다.

$$
\mathbf w^H\mathbf h_1=1,\qquad
|\mathbf w^H\mathbf h_2|^2=2(0.5-a)^2,\qquad
\|\mathbf w\|^2=0.5+2a^2.
$$

따라서 간섭·잡음 비용은 $$J(a)=18(0.5-a)^2+0.5+2a^2$$다. $$J'(a)=40a-18=0$$에서 $$a=0.45$$, $$J''(a)=40>0$$이다. $$a=0.5$$인 정확한 null보다 비용이 낮다. 전체 복소 가중치 공간의 최적성은 앞 절의 positive-definite 제약 최적화 해로 확인된다.

</details>

## 8. 마이크 수와 방향의 구분 가능성이 null을 제한한다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-12.png" | relative_url }}" alt="Lecture 8 II slide 12: polynomial roots on a complex unit circle, a preserved target, and a root moved toward the interferer direction" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=12" | relative_url }}" target="_blank" rel="noopener">slide 12</a>.</figcaption>
</figure>

왼쪽과 오른쪽 원은 실제 방의 배치도가 아니라 $$z=e^{-j\phi}$$라는 **복소 공간 위상**을 그린 것이다. 파란 ×는 다항식의 영점, 초록 별은 목표, 빨간 원은 간섭 방향에 대응한다. 오른쪽 그림은 고정 DAS와 달리 간섭 방향에 영점을 놓도록 가중치를 조정하는 관계를 보여 준다. 다른 영점도 함께 움직일 수 있으며, MVDR가 늘 정확한 영점을 강제한다는 뜻은 아니다.

ULA의 한 주파수 응답은 최대 $$M-1$$차 다항식으로 쓸 수 있다. 그 다항식의 서로 다른 복소 영점은 최대 $$M-1$$개다. 슬라이드의 `roots(제곱근)`에서 **root는 제곱근이 아니라 다항식의 근·영점**이다.

여기서 영점 개수와 실제 각도 개수를 무조건 같게 세면 안 된다. 물리 방향으로 실현되는 단위원 위의 영점만 방향 null이 되며, 공간 aliasing이 있으면 여러 방향이 같은 $$z$$로 대응할 수 있다. 예를 들어 $$d=\lambda$$이면 −30°와 +30°는 인접 마이크 위상차가 $$2\pi$$만큼 달라 같은 steering vector가 된다. 하나를 보존하면서 다른 하나만 지우는 것은 이 배열 관측만으로 불가능하다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-13.png" | relative_url }}" alt="Lecture 8 II slide 13: one target constraint, K minus one null constraints, M weights, and similarity rho cases from orthogonal to indistinguishable steering vectors" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=13" | relative_url }}" target="_blank" rel="noopener">slide 13</a>.</figcaption>
</figure>

### 8.1 Null이 중요한 이유: 간섭의 크기가 아니라 통과 경로를 없앤다

13번 슬라이드의 핵심은 $$\mathbf w^H\mathbf h_1=1$$과 $$\mathbf w^H\mathbf h_k=0$$을 **동시에** 만족시키는 데 있다. 앞의 1은 목표 음성을 그대로 남긴다는 뜻이고, 뒤의 0은 해당 간섭의 채널별 패턴을 합산했을 때 상쇄한다는 뜻이다. 단순히 모든 입력의 볼륨을 낮추는 것과 다르다.

간섭 하나의 관측이 $$\mathbf h_2N$$이면 출력에 남는 양은 $$(\mathbf w^H\mathbf h_2)N$$이다. 따라서 이상적인 null에서는 간섭이 강한지 약한지와 관계없이 그 성분의 기여가 0이 된다. 이것이 작은 side lobe로 일부만 감쇠하는 것과의 차이다. 단, 정확한 steering과 선형 관측 모델에서의 관계이며, 마이크 포화·추정 오차·잔향이 있어도 무조건 제거된다는 보장은 아니다.

작성자 수치 예제로 $$\mathbf h_1=[1,1]^T$$, $$\mathbf h_2=[1,-1]^T$$를 생각하자. 목표 성분이 $$S=2$$, 간섭 성분이 $$N=3$$인 한 주파수·한 frame에서 두 마이크 값은 $$\mathbf x=[S+N,S-N]^T=[5,-1]^T$$다. $$\mathbf w=[0.5,0.5]^T$$로 평균하면 $$y=(5-1)/2=2$$다. 목표는 $$0.5\times2+0.5\times2=2$$로 보존되고, 간섭은 $$0.5\times3+0.5\times(-3)=0$$으로 상쇄된다. **마이크별 입력은 둘 다 혼합음이지만, 목표와 간섭의 공간 패턴이 다르므로 출력에서 다르게 취급할 수 있다.**

이 예제의 두 steering vector는 직교하므로 DAS 자체가 간섭에 null을 가진다. 일반적인 간섭은 그런 좋은 위치에 있지 않으므로, MVDR는 공분산을 보고 응답을 더 낮추는 가중치를 찾는다. 다만 앞 절의 유한 잡음 예제처럼 최적해가 반드시 exact null인 것은 아니다.

### 8.2 목표 보존에 쓴 자유도만큼 null의 수가 제한된다

슬라이드 맨 위는 **목표 하나 보존 + 간섭 $$K-1$$개에 null**이라는 총 $$K$$개 복소 선형 조건을 센다. 마이크 $$M$$개의 복소 가중치 중 목표 응답을 유지하는 조건 하나를 정하면, 나머지 독립된 방향에 쓸 수 있는 자유도는 최대 $$M-1$$개다. 일반적인 독립 조건을 만족시키려면 $$K\le M$$이어야 한다. 또한 steering vector들이 선형 독립이어야 한다. 단순히 마이크 개수만 늘렸다고 구분 불가능한 방향이 자동으로 분리되는 것은 아니다.

아래의 유사도는 $$\rho=\lvert\mathbf h_2^H\mathbf h_1\rvert/M$$다. 각 벡터의 norm이 $$\sqrt M$$인 현재 모델에서 $$0\le\rho\le1$$이며 무차원이다. $$\rho=0$$이면 직교, $$\rho=1$$이면 두 벡터가 선형 종속이다. 중간값이면 두 벡터는 직교하지 않아도 구분할 수 있다. **직교는 내적이 0이라는 강한 조건이고, 선형 독립은 한 벡터를 다른 벡터의 상수배로 만들 수 없다는 조건**이다.

<details markdown="block">
<summary markdown="span">Derivation: Polynomial zeros and independent constraints</summary>

$$m=0,\ldots,M-1$$과 $$z=e^{-j\omega d\sin\theta/c}$$를 쓰면

$$
A(\theta)=\sum_{m=0}^{M-1}w_m^*z^m=P(z).
$$

목표 응답이 1이므로 이 다항식은 영다항식이 아니다. 대수학의 기본정리에 따라 차수가 최대 $$M-1$$이면 중복도를 포함한 근은 그 수를 넘을 수 없다. 모든 근이 단위원 위 또는 visible angle에 대응하는 것은 아니다.

선형 조건으로도 확인할 수 있다. $$\mathbf H=[\mathbf h_1,\ldots,\mathbf h_K]$$이면 $$\mathbf H^H\mathbf w=[1,0,\ldots,0]^T$$다. $$K\le M$$이고 $$\mathbf H$$가 column full rank이면 모든 이러한 목표 응답에 대해 해가 존재한다. 알려진 독립 방향을 정확히 지우는 이상적 선형 필터의 조건이며, 비선형 분리 모델 전체에 대한 화자 수 상한은 아니다.

</details>

## 9. 깊은 null의 대가: 비슷한 두 방향을 억지로 분리할 때

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-15.png" | relative_url }}" alt="Lecture 8 II slide 15: closer interferers distort the beam pattern and increase weight norm; vector projections illustrate why sensor noise grows" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=15" | relative_url }}" target="_blank" rel="noopener">slide 15</a>.</figcaption>
</figure>

**14번은 센서 잡음의 크기를 바꿔 억제 깊이를 비교했다면, 15번은 간섭 방향이 목표에 가까워질 때 억제의 대가가 커지는 이유를 보여 준다.** 핵심 tradeoff는 목표 음성을 보존한 채 간섭을 더 깊게 지우려는 선택과, 센서 잡음 증폭·패턴 왜곡·방향 오차 민감도 사이에 있다.

왼쪽 그래프는 목표를 0°에 고정하고 간섭을 20°·10°·5°로 가까이 옮긴다. 파랑·주황·빨강 곡선과 같은 색의 세로 점선을 함께 보면, 낮추려는 간섭 방향과 null의 위치가 어떻게 연결되는지 보인다. 빨간 5° 경우에는 목표 바로 옆 응답을 급격히 낮추면서 다른 방향의 봉우리가 0 dB보다 높아진다. **목표 방향 0 dB를 유지하는 것과 모든 방향의 gain을 0 dB 이하로 제한하는 것은 다르다.**

오른쪽 도식은 간섭에 직교하면서 목표와의 내적은 1이어야 하는 가중치를 보여 준다. 두 방향 벡터가 거의 평행하면, 간섭을 제외하고 남긴 목표 성분은 매우 작다. 그 작은 성분으로 목표 응답 1을 만들려면 큰 계수를 곱해야 한다. 그림의 긴 빨간 $$\mathbf w$$가 그 상황에 대응한다. 이는 복소 벡터 공간의 관계를 2차원으로 단순화한 도식이지 실제 마이크의 물리적 방향 벡터를 그대로 그린 것은 아니다.

이상적인 **정확한 간섭 null**을 만족하는 최소 norm 해에서는

$$
\frac{\|\mathbf w_{\mathrm{null}}\|^2}{\|\mathbf w_{\mathrm{DAS}}\|^2}
=\frac{1}{1-\rho^2}.
$$

슬라이드에 표시된 유사도를 위 식에 대입하면 차이가 분명해진다. 아래 값은 **동일 파워의 비상관 센서 잡음과 정확한 null을 가정한 최소 norm 해의 검산**이다. 주어진 각도에서 유사도를 새로 계산한 결과나 모든 MVDR의 측정 성능은 아니다.

<div class="table-caption">Supplementary table: White sensor-noise cost relative to DAS at the same unit target gain.</div>

| 원문의 비교 경우 | 대입한 $$\rho$$ | DAS 대비 출력 센서 잡음 파워 | 증가량 |
|---|---|---|---|
| 간섭 20°의 표시 유사도 | 0.25 | 약 1.07배 | 약 0.28 dB |
| 간섭 5°의 표시 유사도 | 0.94 | 약 8.59배 | 약 9.34 dB |

원본의 `ρ=0.94`, `8.1×`는 반올림된 표시값끼리 정확히 일치하지 않으므로, 여기서는 입력값을 고정해 계산했다. 유한 잡음 MVDR에서는 앞 절처럼 null의 깊이를 완화할 수 있어 이 배율을 그대로 적용하지 않는다.

그림 아래 세 문장은 이 대가를 나누어 정리한다.

- **Noise amplified:** 목표와 간섭의 작은 차이를 크게 증폭하면, 채널마다 들어온 센서 잡음도 함께 커진다.
- **Pattern distorted:** 목표와 간섭의 두 조건을 맞추는 동안 다른 방향의 gain이 커질 수 있다. 그 방향에 별도 간섭이 있으면 더 크게 통과할 수 있다.
- **Narrow null misses on small errors:** 특정 방향의 좁은 골을 깊게 만들어도 실제 간섭이 조금 움직이거나 steering 추정이 틀리면 골을 벗어난다. 계산상 null이 깊다는 사실만으로 실제 환경의 안정성이 보장되지는 않는다.

따라서 선택 기준은 가장 깊은 골이 아니라 **실제 오차와 센서 잡음까지 포함해 낮은 출력 간섭·잡음 파워를 유지하는가**이다. 14번의 목표 보존 제약은 유지하되, 15번의 대가를 감당할 수 있는 억제 깊이를 택해야 한다.

대응 방법도 이 대가와 연결된다. Diagonal loading은 큰 가중치를 억제하고, 위치·위상 calibration과 더 정확한 steering 모델은 방향 불일치를 줄인다. 불확실한 방향 범위를 보존하는 robust beamforming도 확장 방향이 될 수 있다. 다만 서로 거의 구분되지 않는 관측 자체를 어떤 설정 하나로 완전히 복구할 수 있는 것은 아니다.

<details markdown="block">
<summary markdown="span">Derivation: Why exact nulling amplifies white sensor noise</summary>

$$\|\mathbf h_1\|^2=\|\mathbf h_2\|^2=M$$인 서로 독립인 두 벡터를 사용한다. 간섭을 제거하는 공간으로 목표를 투영하면

$$
\mathbf p=\left(\mathbf I-\frac{\mathbf h_2\mathbf h_2^H}{M}\right)\mathbf h_1,
\qquad
\|\mathbf p\|^2=M-\frac{|\mathbf h_2^H\mathbf h_1|^2}{M}
=M(1-\rho^2).
$$

최소 norm 가중치는 이 남은 목표 방향을 사용해 $$\mathbf w=\mathbf p/\|\mathbf p\|^2$$로 정규화한다. 그러면 $$\mathbf w^H\mathbf h_1=1$$, $$\mathbf w^H\mathbf h_2=0$$이고

$$
\|\mathbf w\|^2=\frac{1}{M(1-\rho^2)},\qquad
\|\mathbf w_{\mathrm{DAS}}\|^2=\frac1M.
$$

센서 잡음 공분산이 $$\sigma_n^2\mathbf I$$이면 출력 잡음 파워는 $$\sigma_n^2\|\mathbf w\|^2$$이므로 같은 비율로 증가한다. $$\rho=0$$에서는 추가 비용이 없고, $$\rho\to1$$이면 필요한 norm이 발산한다. $$\rho=1$$에서는 보존 조건과 null 조건이 양립하지 않아 해 자체가 없다.

</details>

## 10. 조준 방향을 바꾸어 스캔하면 DoA를 추정할 수 있다

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-08-2/slide-16.png" | relative_url }}" alt="Lecture 8 II slide 16: DAS and MVDR spatial power scans, with a broad DAS peak and two resolved peaks in the example Capon spectrum" loading="lazy">
  <figcaption>Source: Lecture 8 II, <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf#page=16" | relative_url }}" target="_blank" rel="noopener">slide 16</a>.</figcaption>
</figure>

이 그림은 앞 절의 **한 필터에 여러 입사 방향을 넣어 보는 beam pattern**과 다르게 읽는다. 이번에는 같은 녹음의 공분산을 고정하고, 후보 방향 $$\theta$$마다 새로운 필터 $$\mathbf w(\theta)$$를 만든 뒤 그 출력 파워를 그린다. 그 공간 파워 스펙트럼의 peak를 DoA(direction of arrival) 후보로 삼는다.

혼합 신호의 공분산 $$\mathbf R_x$$로 정의하면

$$
P_{\mathrm{DAS}}(\theta)
=\frac{\mathbf h(\theta)^H\mathbf R_x\mathbf h(\theta)}{M^2},\qquad
P_{\mathrm{Capon}}(\theta)
=\frac{1}{\mathbf h(\theta)^H\mathbf R_x^{-1}\mathbf h(\theta)}.
$$

첫 식은 DAS 출력 파워다. 둘째는 각 후보 방향의 응답을 1로 유지하면서 달성 가능한 최소 출력 파워이며, Capon spectrum이라고 부른다. 원본은 이를 `MVDR` 곡선으로 표시한다. 실제 음원이 있는 방향을 보존하도록 강제하면 그 신호를 지우기 어려워 파워가 높게 남고, 음원이 없는 후보 방향에서는 다른 성분을 더 낮출 수 있다는 관계다.

원문 예제에서 검정 DAS는 두 가까운 방향을 하나의 큰 봉우리로, 빨강 MVDR/Capon은 두 peak로 보여 준다. **이 예제는 적응형 공간 필터의 분해능 이점을 보여 주지만 모든 두 화자를 항상 분해한다는 보장은 아니다.** 주파수, 배열 aperture, snapshot 수, 음원 간 상관, steering 정확도와 loading에 따라 결과가 달라진다. 넓은 대역의 음성은 주파수별 결과를 적절히 결합해야 하며, 이 한 bin 식만으로 전체 광대역 알고리즘이 완성되는 것은 아니다.

<details markdown="block">
<summary markdown="span">Derivation: Minimum output power and the Capon spectrum</summary>

$$\mathbf R=\mathbf R_x$$와 단위 목표 응답을 사용하고 $$D=\mathbf h^H\mathbf R_x^{-1}\mathbf h$$라 두면

$$
\mathbf w^H\mathbf R_x\mathbf w
=\frac{\mathbf h^H\mathbf R_x^{-1}\mathbf R_x\mathbf R_x^{-1}\mathbf h}{D^2}
=\frac{D}{D^2}=\frac1D.
$$

$$\mathbf R_x$$가 positive-definite이므로 $$D$$는 양의 실수다. 이것이 Capon 식이다. Loading한 행렬 $$\mathbf R_\delta$$를 쓰면 $$1/(\mathbf h^H\mathbf R_\delta^{-1}\mathbf h)$$는 loading을 포함한 목적함수의 최소값이다. 그 값과 원래 $$\mathbf R_x$$로 측정한 출력 파워를 혼동하지 않는다.

</details>

## 11. 남는 문제는 목표 방향과 공간 통계를 어떻게 얻는가이다

슬라이드 17은 시간영역 채널별 convolution과 주파수영역의 $$\mathbf w^H\mathbf x$$가 연결된다는 점을 되짚는다. 구현에서는 주파수별 가중 합을 만들고 역변환으로 waveform을 복원한다. 앞의 STFT 강의에서 다룬 window·hop·합성 조건도 함께 만족해야 한다.

이 강의의 MVDR는 $$\mathbf h_1$$과 $$\mathbf R_n$$을 이미 알거나 추정할 수 있다고 둔다. 실제 녹음에서는 움직이는 화자, 잡음, 잔향 때문에 방향·공분산 추정이 어렵다. 마지막 슬라이드는 이 지점에서 BSS와 DNN-based beamforming으로 다음 문제를 연결한다. **목표를 왜곡하지 않는 필터를 계산하는 문제와, 그 계산에 필요한 목표·잡음 정보를 얻는 문제는 구분해야 한다.**

또한 $$\mathbf w(t,f)$$는 여러 마이크의 복소 신호를 결합하는 공간 필터다. 단일 채널 magnitude에 0–1 mask를 곱하는 연산과 같지 않다. 신경망이 mask를 예측해 공분산 추정에 사용할 수는 있지만, 그것은 가중치 계산에 필요한 통계를 얻는 별도의 단계다.

## 마지막 핵심 정리

**14번 그림으로 돌아오면 MVDR의 선택이 보인다.** 초록 점선에서는 목표를 유지하고, 빨간 점선에서는 간섭을 낮춘다. 다만 왼쪽처럼 센서 잡음이 작을 때와 오른쪽처럼 클 때의 최적 패턴은 다르다. 목표 보존이라는 조건은 같아도, 공분산이 달라지면 간섭 억제와 잡음 증폭 사이의 균형도 달라지기 때문이다. **Null은 목표가 아니라 억제 수단이며, 최종 기준은 목표 응답을 유지하면서 남는 간섭·잡음의 합을 줄이는 것이다.**

15번은 이 선택의 대가를 설명한다. 목표와 간섭의 공간 패턴이 비슷할수록 두 성분을 다르게 처리하는 가중치가 커지고, 센서 잡음·다른 방향의 gain·방향 오차에 더 민감해질 수 있다. **13번의 null 가능 조건, 14번의 최적화 기준, 15번의 실제 대가는 함께 읽어야 한다.**

| 개념 | 남겨야 할 결론 |
|---|---|
| Side lobe | 목표 밖에서도 채널 합이 완전히 상쇄되지 않아 누설이 남는다. `−13 dB`는 조건부 대표값이다. |
| 공분산·공간 상관 행렬 | 대각은 마이크별 파워, 비대각은 채널 간 복소 관계다. 영평균일 때 $$E[\mathbf x\mathbf x^H]$$가 covariance와 같다. |
| MVDR | 목표 응답은 1로 보존하고 간섭·잡음 파워를 최소화한다. 목표 제약 없는 최소화는 분리가 아니다. |
| MVDR와 MPDR | 각각 $$\mathbf R_n$$과 $$\mathbf R_x$$를 사용한다. 정확한 목표 제약 아래 같아질 수 있지만 추정 오차까지 같지는 않다. |
| Null | $$\mathbf w^H\mathbf h_k=0$$이면 그 간섭의 출력 기여가 상쇄된다. 목표 보존과 독립된 공간 조건·충분한 자유도가 필요하며, 깊은 null에는 잡음·오차 민감도의 대가가 따른다. |
| Capon scan | 후보 방향마다 필터를 다시 만들어 공간 파워를 비교한다. 한 필터의 beam pattern과는 다른 그래프다. |

## Study Guide

먼저 슬라이드 4–5에서 **다른 방향의 누설**과 **같은 main lobe 안의 두 화자**를 구분한다. 이어 슬라이드 11의 행렬을 네 frame 예제로 계산하고, 출력 파워가 실제 sample 제곱 평균과 일치하는지 확인한다. 그다음 목표 제약과 공분산을 MVDR 식에 연결하면 각 항의 역할이 분명해진다.

슬라이드 13에서는 $$\mathbf w^H\mathbf h_1=1$$과 $$\mathbf w^H\mathbf h_2=0$$을 두 마이크 예제에 직접 대입해, 같은 가중치가 목표와 간섭에 어떻게 다르게 작용하는지 확인한다. 이어 슬라이드 14–15는 “간섭을 더 지울수록 무조건 좋다”는 해석을 경계하며 읽는다. 목표 응답, 간섭 파워, 센서 잡음 파워를 따로 계산해야 한다. 마지막으로 슬라이드 16에서는 입사 방향만 바꾸는지, 필터 자체를 후보 방향마다 다시 만드는지부터 확인한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Side lobe가 −13 dB이면 간섭이 없어진 것인가?</summary>

답변: 아니다. 해당 방향의 파워가 약 5% 남는다. 간섭이 목표보다 20 dB 강했다면 목표 응답 0 dB 기준으로 억제 후에도 약 7 dB 강하다. Side lobe의 높이도 마이크 수·가중치·배열 조건에 따라 달라진다.

</details>

<details markdown="block">
<summary markdown="span">2. 공분산 행렬의 비대각 원소가 필요한 이유는 무엇인가?</summary>

답변: 대각만으로는 마이크별 파워만 알 수 있다. 비대각의 $$E[X_mX_n^*]$$는 두 채널 사이의 함께 변하는 정도와 복소 위상 관계를 남긴다. MVDR는 이 공간 관계와 목표 steering vector를 함께 사용해 채널 조합을 정한다.

</details>

<details markdown="block">
<summary markdown="span">3. 목표 응답 제약을 없애면 왜 문제가 되는가?</summary>

답변: 가중치를 모두 0으로 두면 출력 파워도 0이 되어 최소가 된다. 목표 음성까지 없애므로 분리 결과로는 쓸모가 없다. $$\mathbf w^H\mathbf h_1=1$$이 목표가 남아야 한다는 조건이다.

</details>

<details markdown="block">
<summary markdown="span">4. MVDR가 간섭 방향에 정확한 null을 만들지 않을 수 있는 이유는 무엇인가?</summary>

답변: 목적은 간섭 응답 하나를 0으로 강제하는 것이 아니라 목표를 유지하면서 전체 간섭·잡음 파워를 최소화하는 것이다. 정확한 null에 큰 가중치가 필요하면 센서 잡음 비용이 커져, 일부 간섭을 남기는 해가 더 낮은 전체 비용을 가질 수 있다.

</details>

<details markdown="block">
<summary markdown="span">5. 두 steering vector가 직교하지 않으면 분리할 수 없는가?</summary>

답변: 아니다. 선형 독립이면 한 방향을 보존하고 다른 방향을 null로 만드는 선형 조건은 풀 수 있다. 다만 두 벡터가 비슷할수록 큰 가중치와 잡음 증폭이 필요하다. 선형 종속인 경우에는 그 두 조건이 충돌한다.

</details>

<details markdown="block">
<summary markdown="span">6. 공분산 행렬이 특이하면 MVDR 식에 무엇이 필요한가?</summary>

답변: 존재하지 않는 역행렬을 그대로 사용할 수 없다. 충분하고 유효한 snapshot을 확보하고 모델을 점검해야 한다. Diagonal loading은 행렬을 안정화하는 한 방법이며, loading의 크기는 파워 단위와 억제–강인성의 균형을 고려해 정한다.

</details>

## PDF

- <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-08-2.pdf" | relative_url }}" target="_blank" rel="noopener">speech-audio-lecture-08-2.pdf</a>

## References

- 안인규(Inkyu An), *Multi-channel Source Separation 1-2*, Speech and Audio Recognition, slides 1–17. 그림은 위 첨부 원문의 해당 슬라이드다. 별도로 표시한 작은 수치 예제와 상세 유도는 이해를 위한 보충 해설이다.
- <a href="https://www.mathworks.com/help/phased/ref/mvdrweights.html" target="_blank" rel="noopener">MathWorks: MVDR weights</a> — spatial covariance와 unit-gain 가중치의 정규화.
- <a href="https://www.mathworks.com/help/phased/ref/plotgratinglobediagram.html" target="_blank" rel="noopener">MathWorks: Grating-lobe diagram</a> — 배열 geometry와 spatial aliasing.
- <a href="https://docs.pytorch.org/audio/main/generated/torchaudio.transforms.SoudenMVDR.html" target="_blank" rel="noopener">TorchAudio: SoudenMVDR</a> — 음성·잡음 PSD를 구분하는 구현과 noise PSD의 diagonal loading.
