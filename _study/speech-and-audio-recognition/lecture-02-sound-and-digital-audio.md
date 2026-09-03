---
layout: default
date: 2026-09-03 15:19:50 +0900
title: "Speech and Audio Recognition Lecture 2: Digital Signal Processing I"
course: "Speech and Audio Recognition"
topic: "Sound, Sampling, Fourier Analysis, and the DFT"
order: 2
major_topic: "Speech and Audio Processing"
keywords:
  - "Digital Signal Processing"
  - "PCM"
  - "Sampling"
  - "Quantization"
  - "Fourier Series"
  - "Fourier Transform"
  - "DTFS"
  - "DFT"
  - "Nyquist Sampling"
  - "Aliasing"
---

# Speech and Audio Recognition Lecture 2: Digital Signal Processing I

Source PDF: `SpeechAudio_Lecture2.pdf` (locally supplied; not redistributed)

이 글은 국민대학교 안인규 교수의 *Speech And Audio Recognition* 강의 자료 중 *Digital Signal Processing 1*을 바탕으로, 소리가 디지털 표본이 되고 주파수 표현으로 바뀌는 과정을 한 흐름으로 재구성한 학습 노트다. 원본 슬라이드의 그림을 그대로 복제하지 않고 핵심 개념·수식·예시를 설명하며, 표기가 잘못되었거나 전제가 생략된 부분은 별도로 바로잡았다.

> **핵심:** 음성 신호 처리는 연속적인 음압 변화를 무작정 저장하는 일이 아니다. 시간축에서는 sampling, 진폭축에서는 quantization을 수행해 PCM을 만들고, Fourier basis로 신호를 분해해 pitch·harmonic·spectrum처럼 모델이 다루기 쉬운 구조를 드러내는 과정이다.

## 학습 목표

이 강의를 마치면 다음 질문에 답할 수 있어야 한다.

1. 마이크와 ADC는 공기의 압력 변화를 어떻게 PCM sample로 바꾸는가?
2. sample rate, bit depth, channel count는 데이터 크기와 품질에 어떤 영향을 주는가?
3. amplitude와 intensity, sound pressure level의 관계는 무엇인가?
4. Fourier series와 Fourier transform은 각각 어떤 신호를 표현하는가?
5. 연속 주파수가 discrete-time frequency로 옮겨질 때 aliasing이 발생하는 이유는 무엇인가?
6. 유한한 sample sequence에 DFT를 적용할 수 있는 이유는 무엇인가?

## 전체 흐름

```text
Air-pressure variation
        -> microphone and analog waveform
        -> sampling + quantization
        -> PCM sequence
        -> Fourier basis projection
        -> spectrum, harmonics, and frequency-domain features
```

| 단계 | 핵심 표현 | 얻는 것 |
|---|---|---|
| Sound | 연속적인 음압 변화 | 물리적 acoustic signal |
| Recording | microphone voltage | continuous-time analog signal |
| Digitization | sampling + quantization | discrete PCM samples |
| Fourier analysis | sinusoidal or complex exponential bases | frequency components |
| DFT | finite (N)-sample transform | 계산 가능한 discrete spectrum |

### 수식 지도: 무엇이 정의이고 무엇이 유도되는가

원본 PDF 40쪽을 page별로 시각 대조했다. 아래 번호는 파일의 물리적 PDF page index이며, 원본 슬라이드 footer 번호는 중간의 생략된 번호 때문에 일부 구간에서 다를 수 있다.

| 핵심 식 | 원문 위치 | 성격 | 이 글의 검증 위치 |
|---|---|---|---|
| $$f_s=1/T_s$$, $$R=bf_sC$$, quantization level $$2^b$$ | PDF p.7 | 정의에서 나오는 정확한 등식 | Sections 1-2의 단위 계산 |
| $$I=E/(tA)=P/A$$ | PDF p.8 | intensity와 power의 정의 | Section 3.1 |
| $$I\propto p^2$$, pressure decibel의 factor 20 | PDF pp.8-9 | 매질·wave 조건이 붙는 비례식과 그 결과 | Section 3.2 |
| $$x(t)=A\cos(2\pi ft+\phi)$$ | PDF pp.15-17 | sinusoid의 parameterization | Section 5 |
| Euler formula와 세 Fourier-series form | PDF pp.18-25, 28 | 항등식 및 basis 표현 | Sections 5-6 |
| Orthogonality와 $$c_n$$ | PDF pp.26-27 | 정확한 적분 관계 | Section 7 |
| Fourier transform pair | PDF pp.29-31 | Fourier-series 극한과 수렴 조건 | Section 8 |
| DTFS pair와 $$d_k=\sum_r c_{k+rN}$$ | PDF pp.32-35, 39 | discrete orthogonality와 aliasing identity | Section 9 |
| $$N>2K\Longleftrightarrow f_s>2f_{\max}$$ | PDF pp.36-39 | band-limited sampling 조건 | Section 10 |
| DFT/IDFT pair | PDF p.40 | 유한 차원 exact transform | Section 11 |

이 분류에서 “정확하다”는 말은 각 절에 적은 가정과 수학적 영역 안에서 정확하다는 뜻이다. 측정 noise, calibration, finite precision처럼 모델 밖의 오차까지 없다는 뜻은 아니다.

## 1. 소리는 압력의 시간 변화다

소리의 출발점은 공기 분자의 **compression**과 **rarefaction**이다. 진동하는 물체가 주변 공기를 밀고 당기면 평형 압력보다 높은 영역과 낮은 영역이 번갈아 이동한다. 이 변화가 귀나 microphone에 도달하면 우리는 이를 sound wave로 관측한다.

한 지점에서 시간에 따른 압력 편차를 $$p(t)$$라고 하면 waveform은 공간 전체의 움직임을 모두 그린 것이 아니라, **센서 위치에서 측정한 압력 변화의 시간 기록**이다. 따라서 같은 음원이라도 microphone의 위치, 방향, 방의 반사 특성에 따라 waveform이 달라질 수 있다.

### 1.1 Microphone의 역할

Microphone은 acoustic pressure를 전기 신호로 바꾸는 transducer다. diaphragm이 압력 변화에 따라 움직이고, 이 운동이 voltage 또는 current 변화로 변환된다. 이 단계의 출력은 시간과 진폭이 연속적인 analog signal이다.

### 1.2 ADC가 하는 두 가지 일

Analog-to-digital converter는 두 축을 이산화한다.

- **Sampling:** 연속 시간축에서 일정한 간격으로 값을 읽는다.
- **Quantization:** 연속 진폭값을 제한된 수의 digital level 중 하나로 대응시킨다.

Sampling interval을 $$T_s$$, sample rate를 $$f_s$$라고 하면 다음 관계가 성립한다.

$$
f_s = \frac{1}{T_s}
$$

이 관계는 **정의에서 바로 나오는 정확한 등식**이다. 일정한 간격 $$T_s\ \mathrm{s/sample}$$마다 한 번씩 읽으면 1초 동안 읽는 횟수는 그 역수이므로

$$
f_s\ [\mathrm{sample/s}]
\times T_s\ [\mathrm{s/sample}]=1.
$$

따라서 $$f_s=1/T_s$$다. 불규칙 sampling에서는 하나의 고정 $$T_s$$가 없으므로 이 식을 그대로 적용하지 않고 각 timestamp를 사용해야 한다.

Sample rate가 높을수록 시간축을 더 촘촘하게 관측한다. Bit depth가 $$b$$이면 이상적인 quantization level 수는 $$2^b$$다. Bit depth가 커질수록 한 sample의 진폭을 더 세밀하게 표현할 수 있지만, 저장량도 함께 증가한다.

$$2^b$$ 역시 정의에 따른 정확한 개수다. 각 bit가 0 또는 1의 두 상태를 독립적으로 가지므로 multiplication principle에 따라 가능한 $$b$$-bit word는 $$2\times\cdots\times2=2^b$$개다. 다만 실제 ADC의 effective number of bits는 noise와 nonlinearity 때문에 nominal $$b$$보다 낮을 수 있으므로, $$2^b$$는 가능한 code 수이지 실제 유효 정밀도의 경험적 보장은 아니다.

## 2. PCM과 digital audio의 크기

Pulse-code modulation(PCM)은 각 sampling 시점의 quantized amplitude를 binary word로 기록한다. 압축하지 않은 PCM의 초당 bit 수는 다음과 같다.

$$
R = b f_s C
$$

- $$R$$: bit rate in bits per second
- $$b$$: bit depth in bits per sample
- $$f_s$$: sample rate in samples per second
- $$C$$: channel count

이 식도 codec의 경험식이 아니라 **uncompressed interleaved PCM의 정확한 payload rate**다. 한 channel에서 sample 하나가 $$b$$ bit이고, channel마다 초당 $$f_s$$개 sample을 만들며, channel이 $$C$$개이므로

$$
R=
\underbrace{b}_{\mathrm{bit/sample/channel}}
\underbrace{f_s}_{\mathrm{sample/s/channel}}
\underbrace{C}_{\mathrm{channel}}
\quad[\mathrm{bit/s}].
$$

여기서 $$b,C$$는 무차원 개수다. 파일 header, metadata, block padding, error-correction overhead는 포함하지 않으므로 **전체 파일 크기**에는 작은 차이가 생길 수 있고, compressed codec에는 적용할 수 없다.

예를 들어 CD 품질로 자주 언급되는 44.1 kHz, 16-bit, stereo PCM은 다음 bit rate를 갖는다.

$$
R = 16 \times 44{,}100 \times 2 = 1{,}411{,}200\ \mathrm{bit/s}
$$

이는 약 1.4112 Mbps다. 1분의 raw PCM 크기를 byte 단위로 근사하면 다음과 같다.

$$
\frac{1{,}411{,}200 \times 60}{8}
= 10{,}584{,}000\ \mathrm{bytes}
$$

이 식은 **uncompressed PCM**에 대한 식이다. MP3나 Opus처럼 perceptual coding을 사용하는 형식에는 파일의 목표 bit rate와 codec 설정이 별도로 적용된다.

### 2.1 Audio format을 구분하는 기준

| 범주 | 예시 | 특징 |
|---|---|---|
| Uncompressed | WAV, AIFF의 PCM payload | sample을 직접 저장해 크기가 크고 처리가 단순하다. |
| Lossless compressed | FLAC, ALAC | 복원 후 PCM이 원본과 동일하다. |
| Lossy compressed | MP3, AAC, Opus | perceptual redundancy를 제거해 크기를 줄이며 원본과 완전히 같지는 않다. |

Container와 codec은 같은 개념이 아니다. WAV는 주로 PCM을 담지만 container이고, codec은 신호를 어떤 방식으로 encode/decode하는지를 정의한다.

## 3. Amplitude, intensity, loudness

Waveform amplitude가 커 보인다는 것과 사람이 느끼는 loudness가 정확히 같은 뜻은 아니다. 강의에서는 먼저 물리적인 intensity를 다음과 같이 정의한다.

$$
I = \frac{E}{tA} = \frac{P}{A}
$$

### 3.1 Intensity 식의 명칭과 단위

`Properties of Waveforms: Intensity` 슬라이드에 등장하는 기호를 SI 단위까지 펼치면 다음과 같다.

| 기호 | 명칭 | SI 단위 | 이 식에서의 의미 |
|---|---|---|---|
| $$I$$ | Sound intensity | $$\mathrm{W/m^2}$$ | 단위 면적을 통과하는 평균 acoustic power |
| $$E$$ | Energy | $$\mathrm{J}$$ | 시간 $$t$$ 동안 전달된 acoustic energy |
| $$t$$ | Time interval | $$\mathrm{s}$$ | energy를 측정한 시간 구간 |
| $$A$$ | Area | $$\mathrm{m^2}$$ | wave energy가 통과하는 면적 |
| $$P=E/t$$ | Acoustic power | $$\mathrm{W}=\mathrm{J/s}$$ | 단위 시간당 전달되는 energy |
| $$\Delta p$$ | Sound-pressure amplitude | $$\mathrm{Pa}$$ | equilibrium pressure에서 벗어난 pressure 진폭 |
| $$p_n$$ | Pressure sample | calibrated signal은 $$\mathrm{Pa}$$ | discrete-time pressure waveform의 $$n$$번째 sample |
| $$I_n$$ | Sample-wise intensity | calibrated signal은 $$\mathrm{W/m^2}$$ | $$p_n^2$$에 비례하는 $$n$$번째 intensity |
| $$n$$ | Sample index | 무차원 | discrete-time sequence의 sample 위치 |
| $$T$$ | Sequence length | samples | 원본 슬라이드에서 discrete sequence의 총 sample 수 |

여기서 $$\mathrm{W/m^2}=\mathrm{J/(s\,m^2)}$$이므로 $$E/(tA)$$와 $$P/A$$의 차원이 일치한다. PCM 값이 실제 pressure로 calibration되지 않았다면 $$p_n$$은 Pa가 아니라 normalized amplitude나 integer count이고, 이때 $$p_n^2$$도 절대 $$\mathrm{W/m^2}$$가 아닌 **relative intensity proxy**로 해석해야 한다.

> **표기 주의:** 원본 슬라이드는 sequence length를 $$T$$로 적지만, 이 글의 sampling 설명에서는 시간 간격과 혼동을 피하려고 sampling interval은 $$T_s$$, sample 수는 $$N$$으로 구분한다.

같은 매질과 acoustic impedance를 가정하면 intensity는 sound pressure amplitude의 제곱에 비례한다.

$$
I \propto (\Delta p)^2
$$

### 3.2 작성자 보충: pressure 제곱과 intensity의 관계

위 비례식은 모든 음장에 무조건 성립하는 항등식이 아니다. **lossless한 균일 매질을 진행하는 평면파의 시간 평균**이라는 조건에서 acoustic particle velocity $$u(t)$$와 pressure $$p(t)$$는 $$p(t)=\rho c u(t)$$를 만족하고, instantaneous intensity는 $$i(t)=p(t)u(t)$$다. 따라서

$$
i(t)=\frac{p^2(t)}{\rho c},\qquad
I=\langle i(t)\rangle
=\frac{p_{\mathrm{rms}}^2}{\rho c}.
$$

여기서 $$\rho\,[\mathrm{kg/m^3}]$$는 매질 밀도, $$c\,[\mathrm{m/s}]$$는 sound speed, $$\rho c\,[\mathrm{Pa\,s/m}]$$는 characteristic acoustic impedance, $$u\,[\mathrm{m/s}]$$는 particle velocity, $$p_{\mathrm{rms}}\,[\mathrm{Pa}]$$는 RMS pressure다. 같은 매질에서는 $$\rho c$$가 일정하므로 $$I\propto p_{\mathrm{rms}}^2$$가 된다.

Near field, standing wave, strongly reflecting room처럼 pressure와 particle velocity의 위상·비율이 달라지는 곳에서는 $$I=p_{\mathrm{rms}}^2/(\rho c)$$를 그대로 쓰면 안 된다. 이때 active intensity는 일반적으로 $$I=\langle p(t)u(t)\rangle$$에서 계산한다. 원본의 $$I_n\sim p_n^2$$는 calibration과 매질 조건을 생략한 **비례 관계 또는 relative-energy proxy**이지 sample별 절대 intensity의 보편적 증명이 아니다.

따라서 pressure ratio를 decibel로 바꿀 때 계수가 20이 된다.

$$
L_I = 10\log_{10}\frac{I}{I_0}
= 20\log_{10}\frac{p}{p_0}
$$

두 번째 등호는 $$I/I_0=(p/p_0)^2$$가 성립할 때만 정확하다. 이 조건을 대입하고 로그 법칙 $$\log(a^2)=2\log a$$를 쓰면

$$
10\log_{10}\frac{I}{I_0}
=10\log_{10}\left(\frac{p}{p_0}\right)^2
=20\log_{10}\frac{p}{p_0}.
$$

로그의 입력은 무차원 양수여야 하므로 $$I,I_0>0$$, RMS amplitude에는 $$p,p_0>0$$을 사용한다. 부호가 바뀌는 instantaneous pressure를 그대로 로그에 넣는 식이 아니다.

두 식을 혼용할 때는 무엇의 비율인지 확인해야 한다.

- power 또는 intensity ratio: $$10\log_{10}$$
- pressure 또는 amplitude ratio: 제곱 관계가 성립할 때 $$20\log_{10}$$

> **주의:** 사람이 지각하는 loudness는 frequency, duration, hearing sensitivity의 영향을 받는다. Decibel은 물리량의 logarithmic ratio이고, 주관적 loudness 자체를 완전히 설명하는 단일 척도는 아니다.

## 4. 왜 frequency domain이 필요한가

PCM waveform은 신호를 정확히 보존하지만 긴 음성에서 구조를 바로 읽기 어렵다. 수만 개 sample을 시간 순서대로 보는 것만으로는 다음 특성을 쉽게 알기 어렵다.

- 반복 주기와 fundamental frequency
- harmonic structure
- 특정 frequency band의 energy
- 시간에 따라 변하는 spectral pattern

Fourier analysis는 복잡한 신호를 서로 다른 frequency의 sinusoid 합으로 표현한다. 이는 정보를 버리는 압축이 아니라, 같은 신호를 다른 basis에서 바라보는 **좌표 변환**이다.

## 5. Sinusoid와 complex exponential

가장 기본적인 sinusoid는 다음과 같다.

$$
x(t) = A\cos(2\pi ft + \phi)
$$

- $$A$$: amplitude
- $$f$$: frequency in hertz
- $$\phi$$: initial phase

Angular frequency $$\omega$$를 사용하면 $$\omega = 2\pi f$$이고 다음처럼 쓸 수 있다.

$$
x(t) = A\cos(\omega t + \phi)
$$

Radian은 원의 반지름과 arc length의 비로 정의된다. 한 바퀴는 $$2\pi$$ rad이며, 1 rad는 약 $$57.3^{\circ}$$다.

Euler formula는 sinusoid와 complex exponential을 연결한다.

$$
e^{j\theta} = \cos\theta + j\sin\theta
$$

복소 평면에서 $$e^{j\theta}$$는 unit circle 위의 회전이고, real-axis projection은 cosine, imaginary-axis projection은 sine이다. 이 표현을 쓰면 differentiation, integration, phase shift를 exponential의 곱으로 다룰 수 있어 Fourier 전개가 간결해진다.

### 5.1 작성자 보충: Euler formula의 증명 개요

Euler formula는 경험식이 아니라 complex exponential의 power series에서 얻는 **항등식**이다. 모든 실수 $$\theta$$에 대해 절대수렴하는 급수를 사용하면

$$
e^{j\theta}
=\sum_{k=0}^{\infty}\frac{(j\theta)^k}{k!}.
$$

$$j^{2m}=(-1)^m$$, $$j^{2m+1}=j(-1)^m$$이므로 짝수 차수와 홀수 차수를 분리할 수 있다.

$$
\begin{aligned}
e^{j\theta}
&=\sum_{m=0}^{\infty}\frac{(-1)^m\theta^{2m}}{(2m)!}
+j\sum_{m=0}^{\infty}\frac{(-1)^m\theta^{2m+1}}{(2m+1)!}\\
&=\cos\theta+j\sin\theta.
\end{aligned}
$$

여기서 $$j^2=-1$$, $$\theta$$는 radian으로 잰 무차원 angle이다. 이 증명은 exponential, sine, cosine을 각각 해당 power series로 정의하거나 그 급수 전개를 이미 증명했다는 전제에 의존한다.

## 6. Fourier series: periodic signal의 분해

주기 $$T_0$$인 continuous-time signal은 다음 조건을 만족한다.

$$
x(t + T_0) = x(t)
$$

Fundamental frequency와 angular frequency는 다음과 같다.

$$
f_0 = \frac{1}{T_0}, \qquad
\omega_0 = \frac{2\pi}{T_0}
$$

$$n\omega_0$$는 fundamental의 정수배 harmonic이다. Fourier series는 DC component, fundamental, harmonics를 합해 periodic signal을 표현한다.

### 6.1 Sine-cosine form

$$
x(t) = \frac{a_0}{2}
+ \sum_{n=1}^{\infty}
\left[a_n\cos(n\omega_0 t) + b_n\sin(n\omega_0 t)\right]
$$

이 형태는 각 harmonic에 cosine 성분과 sine 성분이 얼마나 포함되는지 직접 보여준다.

### 6.2 Amplitude-phase form

$$
x(t) = \frac{A_0}{2}
+ \sum_{n=1}^{\infty} A_n\cos(n\omega_0 t - \phi_n)
$$

같은 frequency의 sine과 cosine을 하나의 amplitude와 phase로 합친 표현이다.

구체적으로 $$a_n\cos\alpha+b_n\sin\alpha=A_n\cos(\alpha-\phi_n)$$라 두고 오른쪽을 전개하면

$$
A_n\cos(\alpha-\phi_n)
=A_n\cos\phi_n\cos\alpha+A_n\sin\phi_n\sin\alpha.
$$

따라서 $$A_n=\sqrt{a_n^2+b_n^2}$$, $$\phi_n=\operatorname{atan2}(b_n,a_n)$$로 선택하면 두 표현이 정확히 같다. $$A_n=0$$이면 phase는 정해지지 않지만 신호에는 영향이 없다.

### 6.3 Complex exponential form

$$
x(t) = \sum_{n=-\infty}^{\infty} c_n e^{jn\omega_0 t}
$$

세 형태는 서로 다른 신호가 아니라 **같은 periodic signal을 표현하는 세 가지 표기법**이다. Complex form은 positive frequency와 negative frequency를 함께 다루며 algebra를 단순화한다.

Real-valued $$x(t)$$에서는 Euler formula로 cosine과 sine을 positive/negative exponential 쌍으로 바꿀 수 있으며, coefficient는 $$c_{-n}=c_n^*$$라는 conjugate symmetry를 갖는다. Fourier series가 점별로 원 신호에 수렴하려면 단순히 “주기적”이라는 조건만으로는 부족하다. Piecewise smooth 같은 표준 충분조건 아래에서는 연속점에서 $$x(t)$$로, jump에서는 좌우 극한의 평균으로 수렴한다.

## 7. Orthogonal basis와 Fourier coefficient

Fourier coefficient는 임의로 선택하는 숫자가 아니라 신호를 특정 frequency basis에 projection한 값이다. Basis를 다음처럼 두자.

$$
\phi_n(t) = e^{jn\omega_0 t}
$$

한 주기 $$P$$에서 complex inner product는 conjugate를 포함한다.

$$
\langle \phi_n, \phi_m \rangle
= \int_0^P \phi_n(t)\phi_m^{*}(t)\,dt
$$

그 결과는 다음과 같다.

| 조건 | Inner product |
|---|---|
| $$n=m$$ | $$P$$ |
| $$n\ne m$$ | $$0$$ |

이 orthogonality는 다음 적분으로 직접 확인할 수 있다. $$\omega_0=2\pi/P$$이고 $$q=n-m$$라 두면

$$
\langle\phi_n,\phi_m\rangle
=\int_0^P e^{jq\omega_0t}\,dt.
$$

$$q=0$$, 즉 $$n=m$$이면 integrand가 1이므로 결과는 $$P$$다. $$q\ne0$$이면

$$
\int_0^P e^{jq\omega_0t}\,dt
=\left.\frac{e^{jq\omega_0t}}{jq\omega_0}\right|_0^P
=\frac{e^{j2\pi q}-1}{jq\omega_0}=0.
$$

서로 다른 harmonic basis는 한 주기 동안 orthogonal하다. 따라서 $$n$$번째 coefficient는 해당 basis와의 inner product로 분리할 수 있다.

$$
c_n = \frac{1}{P}\int_{-P/2}^{P/2}
x(t)e^{-jn\omega_0 t}\,dt
$$

Coefficient 식도 orthogonality에서 나온다. Series에 $$e^{-jm\omega_0t}$$를 곱해 한 주기 적분하면

$$
\int_P x(t)e^{-jm\omega_0t}\,dt
=\sum_n c_n\int_P e^{j(n-m)\omega_0t}\,dt
=Pc_m.
$$

따라서 양변을 $$P$$로 나누면 $$c_m$$을 얻는다. 적분과 무한합의 순서를 바꿀 수 있는 수렴 조건이 필요하며, 위 식의 $$\int_P$$는 길이가 $$P$$인 임의의 한 주기 구간을 뜻한다.

### 원본 표기 정정

원본의 orthogonality slide는 $$n=m$$과 $$n\ne m$$에 해당하는 결과가 서로 뒤바뀌어 있다. 올바른 관계는 **같은 basis의 inner product가 $$P$$, 서로 다른 basis의 inner product가 0**이다. 또한 두 번째 basis에는 complex conjugate가 적용되므로 exponent의 부호가 음수가 되어야 한다.

## 8. Fourier series에서 Fourier transform으로

Fourier series는 periodic signal의 frequency를 $$n\omega_0$$라는 discrete grid에서 표현한다. Period $$P$$가 커지면 fundamental spacing은 다음처럼 작아진다.

$$
\Delta\omega = \frac{2\pi}{P}
$$

$$P\to\infty$$이면 frequency grid가 연속적으로 가까워지고, 합은 적분으로 이어진다. Angular-frequency convention은 다음과 같다.

### 8.1 작성자 보충: Fourier series 합이 적분으로 바뀌는 과정

유한 구간 $$[-P/2,P/2]$$의 신호를 주기 $$P$$로 반복했다고 생각하면 $$\omega_n=n\Delta\omega$$, $$\Delta\omega=2\pi/P$$이고 coefficient는

$$
c_n=\frac{1}{P}\int_{-P/2}^{P/2}x(t)e^{-j\omega_nt}\,dt
=\frac{\Delta\omega}{2\pi}X_P(\omega_n)
$$

로 쓸 수 있다. 여기서 $$X_P(\omega)=\int_{-P/2}^{P/2}x(t)e^{-j\omega t}\,dt$$다. 이를 synthesis 식에 넣으면

$$
x_P(t)=\frac{1}{2\pi}
\sum_{n=-\infty}^{\infty}
X_P(\omega_n)e^{j\omega_nt}\,\Delta\omega.
$$

오른쪽은 frequency 축의 Riemann sum이다. $$P\to\infty$$에서 $$\Delta\omega\to0$$, $$X_P\to X$$가 적절한 의미로 성립하면

$$
x(t)=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X(\omega)e^{j\omega t}\,d\omega
$$

가 된다. 이것은 “무한 주기”를 단순 대입한 대수 항등식이 아니라 **수렴 조건을 전제로 한 극한 유도**다. 예를 들어 $$x\in L^1$$이면 transform 적분은 정의되지만 inverse가 모든 점에서 곧바로 성립한다고 보장되지는 않으며, 추가 정칙성 또는 $$L^2$$ 해석이 필요할 수 있다.

$$
X(\omega)=\int_{-\infty}^{\infty}x(t)e^{-j\omega t}\,dt
$$

$$
x(t)=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X(\omega)e^{j\omega t}\,d\omega
$$

Ordinary frequency $$f$$를 쓰는 convention은 다음과 같다.

$$
X(f)=\int_{-\infty}^{\infty}x(t)e^{-j2\pi ft}\,dt
$$

$$
x(t)=\int_{-\infty}^{\infty}X(f)e^{j2\pi ft}\,df
$$

두 convention은 모두 맞지만 $$2\pi$$의 위치가 다르다. 계산 중 $$\omega$$와 $$f$$ 표기를 섞지 않는 것이 중요하다.

## 9. Discrete-Time Fourier Series

주기 $$P$$인 continuous-time signal을 간격 $$T$$로 sampling하고 한 주기에 $$N$$개 sample이 있다고 하자.

$$
P = NT, \qquad x[n+N]=x[n]
$$

이 절에서 $$T\,[\mathrm{s/sample}]$$는 sampling interval, $$P\,[\mathrm{s}]$$는 continuous period, $$N\,[\mathrm{sample}]$$은 한 주기의 sample 수이며 $$n,k,r$$는 무차원 정수 index다. $$d_k,c_k$$는 입력 신호와 같은 amplitude 단위를 갖는다.

Discrete-time complex exponential은 frequency index $$k$$에 대해서도 $$N$$주기로 반복된다.

$$
e^{j2\pi(k+N)n/N}=e^{j2\pi kn/N}
$$

왼쪽 exponent를 분리하면

$$
e^{j2\pi(k+N)n/N}
=e^{j2\pi kn/N}e^{j2\pi n}
=e^{j2\pi kn/N}
$$

이다. 정수 $$n$$에 대해 $$e^{j2\pi n}=1$$이기 때문이다. 따라서 이 등식은 근사가 아니라 discrete index에서의 **정확한 항등식**이다.

따라서 서로 구별되는 basis는 한 주기당 $$N$$개뿐이다. DTFS synthesis와 analysis 식은 다음과 같다.

$$
x[n]=\sum_{k=0}^{N-1}d_k e^{j2\pi kn/N}
$$

$$
d_k=\frac{1}{N}\sum_{n=0}^{N-1}
x[n]e^{-j2\pi kn/N}
$$

### 9.1 작성자 보충: DTFS coefficient의 유도

Synthesis 식 양변에 $$e^{-j2\pi mn/N}$$을 곱하고 $$n=0,\ldots,N-1$$에 대해 합하면 discrete orthogonality

$$
\sum_{n=0}^{N-1}e^{j2\pi(k-m)n/N}
=\begin{cases}
N,&k\equiv m\pmod N,\\
0,&k\not\equiv m\pmod N
\end{cases}
$$

때문에 $$m$$번째 항만 남는다. 다른 항의 합이 0인 이유는 공비 $$q=e^{j2\pi(k-m)/N}\ne1$$인 geometric series에서

$$
\sum_{n=0}^{N-1}q^n=\frac{1-q^N}{1-q}=0
$$

이고 $$q^N=e^{j2\pi(k-m)}=1$$이기 때문이다. 따라서

$$
\sum_{n=0}^{N-1}x[n]e^{-j2\pi mn/N}=Nd_m,
$$

양변을 $$N$$으로 나누면 analysis 식을 얻는다. 여기서는 $$N$$이 양의 정수이고 모든 index를 한 period에서 합한다.

Continuous Fourier-series coefficient $$c_k$$와 sampled signal의 coefficient $$d_k$$ 사이에는 다음 관계가 있다.

$$
d_k=\sum_{r=-\infty}^{\infty}c_{k+rN}
$$

이 aliasing 합도 basis periodicity에서 유도된다. Sampled CTFS를 쓰면

$$
x[n]=x(nT)
=\sum_{\ell=-\infty}^{\infty}c_\ell e^{j2\pi\ell n/N}.
$$

모든 integer $$\ell$$은 유일하게 $$\ell=k+rN$$, $$0\le k<N$$로 쓸 수 있다. 같은 나머지를 갖는 항을 묶으면

$$
\begin{aligned}
x[n]
&=\sum_{k=0}^{N-1}\sum_{r=-\infty}^{\infty}
c_{k+rN}e^{j2\pi(k+rN)n/N}\\
&=\sum_{k=0}^{N-1}
\left(\sum_r c_{k+rN}\right)e^{j2\pi kn/N},
\end{aligned}
$$

이므로 DTFS coefficient는 $$d_k=\sum_r c_{k+rN}$$다. 무한합의 재배열이 정당화될 정도의 coefficient 수렴성이 필요하다. 이 식은 alias 성분이 서로 더해진다는 정확한 관계이며, 각 alias의 크기가 작을 것이라는 보장은 없다.

즉 $$N$$만큼 떨어진 continuous frequency 성분들이 같은 discrete frequency bin에 더해질 수 있다. 이것이 frequency-domain에서 본 aliasing의 핵심이다.

## 10. Nyquist sampling과 aliasing

원 신호의 가장 높은 harmonic index가 $$K$$라면 aliasing 없이 구분하기 위한 조건은 다음처럼 정리된다.

$$
N > 2K
$$

Frequency 단위로 쓰면 더 익숙한 Nyquist condition이 된다.

$$
f_s > 2f_{\max}
$$

### 10.1 작성자 보충: Nyquist 부등식의 유도와 경계

CTFS가 $$\lvert k\rvert\le K$$에서만 nonzero인 band-limited periodic signal이라고 하자. Sampling 뒤에는 $$k$$와 $$k+rN$$이 같은 discrete basis가 된다. 가장 높은 positive index $$K$$와 가장 낮은 negative index $$-K$$가 서로 다른 나머지로 남으려면 한 period의 unique index 폭 $$N$$이 전체 occupied width $$2K$$보다 커야 하므로 $$N>2K$$다.

또한 $$f_{\max}=K/P$$, $$f_s=1/T=N/P$$이므로

$$
N>2K
\quad\Longleftrightarrow\quad
\frac{N}{P}>2\frac{K}{P}
\quad\Longleftrightarrow\quad
f_s>2f_{\max}.
$$

이는 엄격히 band-limited한 신호와 이상적 reconstruction을 가정한 theorem의 조건이다. 등호 $$f_s=2f_{\max}$$에서는 Nyquist-frequency sinusoid의 phase에 따라 sample이 모두 0이 되는 등 모호성이 생길 수 있어 이 글은 안전하게 strict inequality를 쓴다. 실제 speech, finite-duration signal, nonideal filter에는 무한히 날카로운 band limit가 없으므로 transition band와 guard margin이 필요하다.

이 조건을 만족하면 sampling으로 복제된 spectrum이 관심 대역에서 겹치지 않는다. 실제 시스템에서는 이상적인 brick-wall filter를 만들 수 없으므로 $$2f_{\max}$$보다 충분히 높은 sample rate와 anti-aliasing filter의 transition band를 함께 고려한다.

### 10.2 1 kHz와 7 kHz가 같아지는 예

Sample rate가 8 kHz일 때 1 kHz cosine과 7 kHz cosine을 같은 sampling time에서 관측하면 동일한 sample sequence가 만들어질 수 있다.

$$
7\ \mathrm{kHz} = 8\ \mathrm{kHz} - 1\ \mathrm{kHz}
$$

Discrete-time frequency는 sample rate를 기준으로 periodic하기 때문에 7 kHz 성분이 1 kHz 위치로 접혀 보인다. Sample만 본 뒤에는 어느 continuous frequency가 원래 신호였는지 복원할 수 없다.

### 10.3 Spatial aliasing과 moire pattern

Aliasing은 audio에만 생기지 않는다. Camera sensor가 공간의 고주파 pattern을 충분히 촘촘하게 sampling하지 못하면 moire pattern이 나타난다. 시간축 sampling과 이미지의 공간축 sampling은 같은 원리로 설명할 수 있다.

## 11. Finite signal과 DFT

실제 recording은 무한히 길지 않다. $$N$$개의 finite sample을 분석할 때는 그 구간이 주기적으로 반복된다고 해석해 DTFS를 적용할 수 있다. 이것이 DFT의 기본 관점이다.

강의 자료가 사용하는 normalization convention은 forward transform에 $$1/N$$을 둔다.

$$
X[k]=\frac{1}{N}\sum_{n=0}^{N-1}
x[n]e^{-j2\pi kn/N}
$$

$$
x[n]=\sum_{k=0}^{N-1}
X[k]e^{j2\pi kn/N}
$$

### 11.1 작성자 보충: DFT와 inverse DFT가 서로 복원되는 이유

두 식은 유한 길이 sequence에 대한 **정확한 선형 변환 쌍**이다. Forward 식을 inverse 식에 대입하면

$$
\begin{aligned}
\hat{x}[n]
&=\sum_{k=0}^{N-1}
\left(\frac{1}{N}\sum_{m=0}^{N-1}
x[m]e^{-j2\pi km/N}\right)e^{j2\pi kn/N}\\
&=\frac{1}{N}\sum_{m=0}^{N-1}x[m]
\sum_{k=0}^{N-1}e^{j2\pi k(n-m)/N}.
\end{aligned}
$$

안쪽 합은 discrete orthogonality에 의해 $$n\equiv m\pmod N$$이면 $$N$$, 아니면 0이다. $$n,m\in\{0,\ldots,N-1\}$$에서는 오직 $$n=m$$인 항만 남으므로 $$\hat{x}[n]=x[n]$$이다. 이 증명은 arithmetic가 정확하다고 가정한다. 실제 floating-point FFT에서는 round-off error가 작게 남을 수 있으며, normalization factor를 forward와 inverse 양쪽에서 일관되게 사용해야 한다.

다른 교재와 library는 $$1/N$$을 inverse transform에 두거나 양쪽에 $$1/\sqrt{N}$$을 나눠 둘 수 있다. 구현 결과를 비교할 때는 반드시 normalization convention을 확인해야 한다.

### 11.2 DFT가 암묵적으로 만드는 가정

- 관측한 $$N$$개 sample이 한 period를 이룬다.
- 시작과 끝이 부드럽게 이어지지 않으면 artificial discontinuity가 생긴다.
- 이 discontinuity는 energy가 인접 frequency bin으로 퍼지는 spectral leakage를 만든다.
- 실제 speech analysis에서는 window function과 short-time analysis가 필요하다.

Windowing과 short-time Fourier transform은 다음 강의에서 이어질 기반 개념이다. 여기서는 **DFT가 finite sequence를 periodic extension으로 해석한다**는 점을 먼저 확실히 이해하면 된다.

## 12. Speech processing으로 이어지는 연결

이번 강의의 수학은 speech model 앞단의 feature extraction과 직접 연결된다.

| 이번 강의 개념 | 이후 speech processing에서의 역할 |
|---|---|
| Sampling | waveform을 model input sequence로 만든다. |
| Quantization | 저장·전송 정밀도와 quantization noise를 결정한다. |
| Fourier basis | frequency 성분을 분리하는 기준을 제공한다. |
| DFT | 짧은 frame의 spectrum을 계산한다. |
| Nyquist condition | 보존 가능한 frequency band를 결정한다. |
| Aliasing | 복구 불가능한 frequency ambiguity를 설명한다. |

Speech는 시간에 따라 빠르게 변하므로 전체 utterance에 한 번만 DFT를 적용하면 변화 시점을 잃는다. 일반적인 다음 단계는 waveform을 짧은 overlapping frame으로 나누고 각 frame에 window와 DFT를 적용하는 것이다. 이 과정이 spectrogram과 STFT로 이어진다.

## 마지막 핵심 정리

1. **Digitization은 두 단계다.** Sampling은 시간을, quantization은 amplitude를 이산화한다.
2. **PCM bit rate는 $$b f_s C$$다.** 더 높은 precision과 더 많은 channel은 저장량을 증가시킨다.
3. **Fourier analysis는 basis change다.** Time-domain signal을 frequency-domain component로 분해한다.
4. **Periodic continuous signal에는 Fourier series, aperiodic signal에는 Fourier transform을 사용한다.**
5. **Discrete time에서는 frequency도 periodic하다.** $$k$$와 $$k+N$$ basis가 같아 aliasing이 발생한다.
6. **Nyquist condition은 구분 가능성의 조건이다.** 위반 후에는 sample만으로 원래 frequency를 알아낼 수 없다.
7. **DFT는 finite samples의 periodic extension을 분석한다.** Normalization과 windowing convention을 함께 확인해야 한다.

## Study Guide

이 글은 **digitization → Fourier representation → discrete-time periodicity → DFT** 순서로 복습하면 가장 잘 연결된다. 먼저 sampling과 quantization이 서로 다른 축을 이산화한다는 점을 고정한 뒤, Fourier series의 orthogonal projection이 DTFS와 DFT로 어떻게 이어지는지 식을 따라가면 된다.

시험 대비에서는 다음 다섯 항목을 직접 설명하고 계산할 수 있는지 확인한다.

1. $$R=b f_s C$$로 uncompressed PCM bit rate를 계산한다.
2. intensity ratio에는 $$10\log_{10}$$, pressure ratio에는 조건부로 $$20\log_{10}$$을 쓰는 이유를 설명한다.
3. Fourier series, Fourier transform, DTFS, DFT의 신호 범위와 frequency 축 차이를 구분한다.
4. $$e^{j2\pi(k+N)n/N}=e^{j2\pi kn/N}$$에서 aliasing의 주기성을 유도한다.
5. Nyquist condition, anti-aliasing filter, spectral leakage가 서로 해결하는 문제가 다름을 구분한다.

헷갈리기 쉬운 핵심은 **aliasing과 leakage를 같은 현상으로 보지 않는 것**이다. Aliasing은 sampling 전에 제거하지 못한 대역이 겹쳐 원래 frequency를 복구할 수 없는 현상이고, leakage는 유한 구간의 경계 불연속 때문에 DFT energy가 이웃 bin으로 퍼지는 현상이다.

## 복습 질문

<details markdown="block">
<summary>1. Sampling과 quantization은 각각 어떤 축을 이산화하는가?</summary>

답변: Sampling은 연속 시간축을 discrete time index로 바꾸고, quantization은 연속 amplitude를 유한한 digital level로 대응시킨다.
</details>

<details markdown="block">
<summary>2. 48 kHz, 24-bit, stereo PCM의 raw bit rate는 얼마인가?</summary>

답변: $$24\times48{,}000\times2=2{,}304{,}000\ \mathrm{bit/s}$$, 즉 약 2.304 Mbps다.
</details>

<details markdown="block">
<summary>3. Pressure ratio에 20 log를 사용하는 이유는 무엇인가?</summary>

답변: 같은 매질에서 intensity가 pressure amplitude의 제곱에 비례하므로, $$10\log_{10}(p^2/p_0^2)=20\log_{10}(p/p_0)$$가 되기 때문이다.
</details>

<details markdown="block">
<summary>4. Fourier coefficient를 projection으로 볼 수 있는 이유는 무엇인가?</summary>

답변: 서로 다른 complex exponential basis가 한 주기에서 orthogonal하므로, 신호와 원하는 basis의 inner product가 그 방향의 성분만 분리하기 때문이다.
</details>

<details markdown="block">
<summary>5. 8 kHz sampling에서 7 kHz가 1 kHz처럼 보일 수 있는 이유는 무엇인가?</summary>

답변: Discrete-time frequency는 sample rate를 주기로 반복되며 $$7\ \mathrm{kHz}=8\ \mathrm{kHz}-1\ \mathrm{kHz}$$이므로 두 cosine이 같은 sampling point에서 동일한 값을 만들 수 있다.
</details>

<details markdown="block">
<summary>6. DFT normalization이 library마다 달라도 transform 자체가 틀렸다고 할 수 없는 이유는 무엇인가?</summary>

답변: Forward와 inverse transform 사이에 $$1/N$$ factor를 어디에 배치할지는 convention이다. 두 식을 일관되게 사용하면 같은 신호를 복원한다.
</details>

## Source Materials

원본 PDF는 로컬로 제공된 수업자료이며 재배포 근거가 확인되지 않아 첨부하지 않는다. 아래에는 슬라이드가 명시한 공개 출처와 강의 맥락을 확인할 수 있는 자료를 빠짐없이 정리했다.

<ul>
  <li><a href="https://github.com/yandexdataschool/speech_course" target="_blank" rel="noopener">Yandex Data School Speech Course</a></li>
  <li><a href="https://github.com/markovka17/dla" target="_blank" rel="noopener">Deep Learning for Audio Materials</a></li>
  <li><a href="https://mairlab.kookmin.ac.kr/" target="_blank" rel="noopener">Kookmin University MAIR Lab</a></li>
  <li><a href="https://pudding.cool/2018/02/waveforms" target="_blank" rel="noopener">What Does Music Look Like?</a></li>
  <li><a href="https://theory.labster.com/sound-waves-dbs/" target="_blank" rel="noopener">Sound Waves and Decibels</a></li>
  <li><a href="https://is.muni.cz/el/1433/jaro2012/PA190/um/Slides_02.pdf" target="_blank" rel="noopener">Audio Signal Processing Slides</a></li>
  <li><a href="https://github.com/yandexdataschool/speech_course/tree/2022/week_02" target="_blank" rel="noopener">Speech Course Week 2 Materials</a></li>
  <li><a href="https://decibelpro.app/blog/how-many-decibels-does-a-human-speak-normally/" target="_blank" rel="noopener">Human Voice Decibel Reference</a></li>
  <li><a href="https://en.wikipedia.org/wiki/Audio_file_format" target="_blank" rel="noopener">Audio File Format</a></li>
  <li><a href="https://angeloyeo.github.io/2019/06/23/Fourier_Series_en.html" target="_blank" rel="noopener">Fourier Series Visual Explanation</a></li>
  <li><a href="https://en.wikipedia.org/wiki/Fourier_series" target="_blank" rel="noopener">Fourier Series</a></li>
  <li><a href="https://commons.wikimedia.org/wiki/File:Fourier_transform_time_and_frequency_domains.gif" target="_blank" rel="noopener">Fourier Transform: Time and Frequency Domains</a></li>
  <li><a href="https://ru.dsplib.org/content/dft/dft.html" target="_blank" rel="noopener">Discrete Fourier Transform Reference</a></li>
  <li><a href="https://www.youtube.com/watch?v=nreiTseFZQ0" target="_blank" rel="noopener">Aliasing Demonstration</a></li>
  <li><a href="https://en.wikipedia.org/wiki/Moir%C3%A9_pattern" target="_blank" rel="noopener">Moire Pattern</a></li>
  <li><a href="https://www.adobe.com/creativecloud/photography/discover/anti-aliasing.html" target="_blank" rel="noopener">Adobe Anti-Aliasing Guide</a></li>
</ul>
