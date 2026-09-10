---
layout: default
date: 2026-09-03 15:19:50 +0900
last_modified_at: 2026-09-10 16:02:00 +0900
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
  - "Harmonics"
  - "Fundamental Frequency"
  - "Missing Fundamental"
  - "Formants"
  - "Phase"
  - "Amplitude-Phase Representation"
  - "Complex Exponential"
  - "Conjugate Symmetry"
  - "Fourier Transform"
  - "CTFS"
  - "DTFS"
  - "DFT"
  - "Nyquist Sampling"
  - "Aliasing"
---

# Speech and Audio Recognition Lecture 2: Digital Signal Processing I

Source PDF: `SpeechAudio_Lecture2.pdf` (locally supplied; not redistributed)

이 글은 국민대학교 안인규 교수의 *Speech And Audio Recognition* 강의 자료 중 *Digital Signal Processing 1*을 바탕으로, 소리가 디지털 표본이 되고 주파수 표현으로 바뀌는 과정을 한 흐름으로 재구성한 학습 노트다. 원본 슬라이드의 그림을 그대로 복제하지 않고 핵심 개념·수식·예시를 설명하며, 표기가 잘못되었거나 전제가 생략된 부분은 별도로 바로잡았다.

> **핵심:** 음성 신호 처리는 연속적인 음압 변화를 무작정 저장하는 일이 아니다. 시간축에서는 sampling, 진폭축에서는 quantization을 수행해 PCM을 만들고, Fourier basis로 신호를 분해해 pitch·harmonic·spectrum처럼 모델이 다루기 쉬운 구조를 드러내는 과정이다.

> **Phase를 배우는 이유:** Frequency는 얼마나 자주, amplitude는 얼마나 크게 진동하는지를 말한다. **Phase는 각 성분이 기준 시각에서 어디에 놓이는지**를 알려 주므로 같은 크기의 frequency 성분들로도 서로 다른 waveform이 만들어지는 이유를 설명한다. Amplitude-phase 변환은 그 정보를 읽기 쉽게 다시 쓰는 것이지 신호를 바꾸는 필수 전처리가 아니다.

## 학습 목표

이 강의를 마치면 다음 질문에 답할 수 있어야 한다.

1. 마이크와 ADC는 공기의 압력 변화를 어떻게 PCM sample로 바꾸는가?
2. sample rate, bit depth, channel count는 데이터 크기와 품질에 어떤 영향을 주는가?
3. amplitude와 intensity, sound pressure level의 관계는 무엇인가?
4. Fourier series와 Fourier transform은 각각 어떤 신호를 표현하는가?
5. 연속 주파수가 discrete-time frequency로 옮겨질 때 aliasing이 발생하는 이유는 무엇인가?
6. 유한한 sample sequence에 DFT를 적용할 수 있는 이유는 무엇인가?
7. harmonic 번호·간격·크기는 각각 무엇을 뜻하며, pitch·timbre·formant와 어떻게 구분되는가?
8. sine-cosine form을 amplitude-phase form으로 바꾸는 이유는 무엇이며, 실제 phase shift·time delay와 무엇이 다른가?
9. complex exponential form에서 음의 주파수가 등장하는 이유와 실수 waveform이 복원되는 조건은 무엇인가?

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

원본 PDF는 40쪽이며 아래 번호는 파일의 물리적 PDF page index다. 원본 슬라이드 footer 번호는 중간의 생략된 번호 때문에 일부 구간에서 다를 수 있다. 이번 정확성 검토의 범위와 정정 근거는 하단 `Source Check`에 구분해 기록했다.

| 핵심 식 | 원문 위치 | 성격 | 이 글의 검증 위치 |
|---|---|---|---|
| $$f_s=1/T_s$$, $$R=bf_sC$$, quantization level $$2^b$$ | PDF p.7 | 정의에서 나오는 정확한 등식 | Sections 1-2의 단위 계산 |
| $$I=E/(tA)=P/A$$ | PDF p.8 | intensity와 power의 정의 | Section 3.1 |
| $$I\propto p^2$$, pressure decibel의 factor 20 | PDF pp.8-9 | 매질·wave 조건이 붙는 비례식과 그 결과 | Section 3.2 |
| $$x(t)=A\cos(2\pi ft+\phi)$$ | PDF pp.15-17 | sinusoid의 parameterization | Section 5 |
| Euler formula와 세 Fourier-series form | PDF pp.18-25, 28 | 항등식 및 basis 표현 | Sections 5-6 |
| Initial phase와 amplitude-phase 변환 | PDF pp.15-17, 22-25 | 같은 sinusoid의 재표현 | Sections 5.2, 6.2.1-6.2.4의 작성자 보충 |
| $$c_n=(a_n-jb_n)/2$$와 conjugate symmetry | PDF pp.18, 21-25 | Euler formula로 얻는 계수 변환 | Sections 6.3.1-6.3.5의 작성자 보충 |
| $$f_n=nf_0$$, harmonic amplitude와 phase | PDF pp.19-24 | 주기 조건에서 나오는 정수배 관계 | Sections 6.4-6.8의 작성자 보충 |
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
R=C\,(b f_s).
$$

여기서 $$b$$는 **각 channel의 sample 하나당 bit 수**, $$f_s$$는 **각 channel의 초당 sample 수**, $$C$$는 무차원 channel 개수다. 한 channel의 rate가 $$b f_s\,[\mathrm{bit/s}]$$이고 동일 rate의 channel $$C$$개를 합치므로 위 식을 얻는다. `per channel`은 두 값의 측정 범위를 설명하는 말이지, $$b$$와 $$f_s$$의 단위에 각각 `/channel`을 붙여 이중으로 나누라는 뜻이 아니다. 파일 header, metadata, block padding, error-correction overhead는 포함하지 않으므로 **전체 파일 크기**에는 작은 차이가 생길 수 있고, compressed codec에는 적용할 수 없다.

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
| $$I_n$$ | Sample-wise intensity (원문 표기) | 물리적 intensity는 $$\mathrm{W/m^2}$$ | 일반적으로 pressure와 particle velocity의 곱이 필요하며, 진행 평면파 조건에서만 $$p_n^2/(\rho c)$$로 계산 |
| $$n$$ | Sample index | 무차원 | discrete-time sequence의 sample 위치 |
| $$T$$ | Sequence length | samples | 원본 슬라이드에서 discrete sequence의 총 sample 수 |

여기서 $$\mathrm{W/m^2}=\mathrm{J/(s\,m^2)}$$이므로 $$E/(tA)$$와 $$P/A$$의 차원이 일치한다. $$I=P/A$$는 해당 면적을 수직으로 통과하는 power의 면적 평균이고, 균일하지 않은 음장에서 한 점의 intensity와 그대로 같다고 볼 수는 없다. PCM 값이 실제 pressure로 calibration되지 않았다면 $$p_n$$은 Pa가 아니라 normalized amplitude나 integer count이고, 이때 $$p_n^2$$도 절대 $$\mathrm{W/m^2}$$가 아닌 **relative intensity proxy**로 해석해야 한다. Calibration된 $$p_n^2$$ 역시 단위가 $$\mathrm{Pa^2}$$일 뿐이다. 다음 절의 wave 조건과 impedance로 변환하거나 particle velocity를 함께 측정해야 물리적 intensity를 구할 수 있다.

> **표기 주의:** 원본 슬라이드는 sequence length를 $$T$$로 적지만, 이 글의 sampling 설명에서는 시간 간격과 혼동을 피하려고 sampling interval은 $$T_s$$, sample 수는 $$N$$으로 구분한다.

Lossless한 균일 매질의 한 방향 진행 평면파에서 acoustic impedance가 같다면 평균 intensity는 sound pressure amplitude의 제곱에 비례한다.

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

Near field, standing wave, strongly reflecting room처럼 pressure와 particle velocity의 위상·비율이 달라지는 곳에서는 $$I=p_{\mathrm{rms}}^2/(\rho c)$$를 그대로 쓰면 안 된다. 이때 특정 방향의 active intensity는 해당 방향 particle velocity를 사용해 $$I=\langle p(t)u(t)\rangle$$에서 계산한다. 예를 들어 이상적인 standing wave의 pressure antinode에서는 pressure가 진동해도 particle velocity가 0이므로 전달 intensity는 0이다. **Pressure 제곱이 크다는 것과 그 방향으로 energy가 흐른다는 것은 다르다.** 원본의 $$I_n\sim p_n^2$$는 calibration과 매질 조건을 생략한 비례 관계 또는 relative-energy proxy로만 읽어야 한다. Pressure·velocity와 plane-wave impedance의 관계는 <a href="https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/50a609ff2cc992401a099bca53801474_MIT6_013S09_chap13.pdf" target="_blank" rel="noopener">MIT OCW: Acoustics, Section 13.1.2</a>를 교차 확인했다.

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

Sound pressure level(SPL)은 별도로 $$L_p=20\log_{10}(p_{\mathrm{rms}}/p_0)$$로 정의한다. 따라서 SPL을 정의하는 데 모든 음장이 진행 평면파일 필요는 없지만, 이를 intensity level $$L_I$$와 같다고 놓으려면 위 제곱 비례 관계와 서로 맞는 기준값이 필요하다. Power ratio와 root-power ratio의 구분은 <a href="https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-8" target="_blank" rel="noopener">NIST Guide to the SI, Chapter 8</a>의 logarithmic quantity 정의와도 일치한다.

두 식을 혼용할 때는 무엇의 비율인지 확인해야 한다.

- power 또는 intensity ratio: $$10\log_{10}$$
- pressure 또는 amplitude ratio: 제곱 관계가 성립할 때 $$20\log_{10}$$

> **주의:** 사람이 지각하는 loudness는 frequency, duration, hearing sensitivity의 영향을 받는다. Decibel은 물리량의 logarithmic ratio이고, 주관적 loudness 자체를 완전히 설명하는 단일 척도는 아니다.

## 4. 왜 frequency domain이 필요한가

PCM waveform은 sampling과 quantization으로 얻은 digital sample을 시간 순서대로 보존하지만 긴 음성에서 구조를 바로 읽기 어렵다. 원래 analog signal까지 손실 없이 보존한다는 뜻은 아니다. 수만 개 sample을 시간 순서대로 보는 것만으로는 다음 특성을 쉽게 알기 어렵다.

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

### 5.2 작성자 보충: amplitude와 frequency만으로는 왜 부족한가?

원본 PDF pp.15-17의 $$x(t)=A\cos(\omega t+\phi)$$에서 순간 angle은 $$\theta(t)=\omega t+\phi$$다. $$t=0$$일 때의 angle $$\theta(0)=\phi$$가 **initial phase**다. $$t$$는 seconds, $$\omega$$는 rad/s, $$\phi$$는 radians로 잰다. $$2\pi$$를 더한 phase는 같은 sinusoid를 나타내므로 phase는 $$2\pi$$를 주기로 해석한다.

진폭을 1로 정규화하고 frequency를 100 Hz로 고정해도

$$
x_1(t)=\cos(2\pi100t),\qquad
x_2(t)=\sin(2\pi100t)
=\cos(2\pi100t-\pi/2)
$$

는 서로 다른 함수다. $$t=0$$에서 $$x_1(0)=1$$이지만 $$x_2(0)=0$$이고, 두 파형의 peak 시각도 다르다. 따라서 **“100 Hz 성분의 amplitude가 1이다”만으로는 sample 값이나 파형의 정렬 상태를 복원할 수 없다.** 같은 기준 시각에 대한 phase까지 필요하다.

Phase가 상수인 sinusoid에서 $$d\theta/dt=\omega$$이므로 initial phase만 바꿔도 frequency는 바뀌지 않는다. 단, $$\phi(t)$$처럼 phase 자체가 시간에 따라 변하면 $$d\theta/dt=\omega+d\phi/dt$$이므로 단순한 고정 phase shift와는 다른 문제가 된다. 이 글의 기본 sinusoid와 harmonic 계산은 **상수 phase와 양의 고정 frequency**를 전제로 한다.

## 6. Fourier series: periodic signal의 분해

주기 $$T_0>0$$인 continuous-time signal은 다음 조건을 만족한다. 이 절에서 fundamental을 말할 때는 $$T_0$$를 **가장 작은 양의 주기**로 정한다. 상수 신호처럼 최소 양의 주기가 없는 경우는 제외한다.

$$
x(t + T_0) = x(t)
$$

Fundamental frequency와 angular frequency는 다음과 같다.

$$
f_0 = \frac{1}{T_0}, \qquad
\omega_0 = \frac{2\pi}{T_0}
$$

$$n\omega_0$$는 $$n$$번째 harmonic의 angular frequency다. Fourier series는 DC component와 fundamental을 포함한 harmonics를 합해 periodic signal을 표현한다. **Fundamental 자체가 first harmonic**이므로, 원본의 “DC + Fundamental + Harmonics”에서 마지막 harmonics는 문맥상 second harmonic 이상의 성분을 뜻한다. 각 coefficient는 0일 수도 있다.

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

같은 frequency의 sine과 cosine을 하나의 amplitude와 phase로 합친 표현이다. DC 항은 기존과 같게 $$A_0=a_0$$로 두며, 아래의 amplitude·phase 변환은 $$n\ge1$$인 진동 성분에 적용한다.

구체적으로 다음과 같이 두자.

$$
a_n\cos\alpha+b_n\sin\alpha=A_n\cos(\alpha-\phi_n).
$$

오른쪽을 전개하면

$$
A_n\cos(\alpha-\phi_n)
=A_n\cos\phi_n\cos\alpha+A_n\sin\phi_n\sin\alpha.
$$

따라서 $$A_n=\sqrt{a_n^2+b_n^2}$$, $$\phi_n=\operatorname{atan2}(b_n,a_n)$$로 선택하면 두 표현이 정확히 같다. $$A_n=0$$이면 phase는 정해지지 않지만 신호에는 영향이 없다.

#### 6.2.1 작성자 보충: 왜 amplitude-phase 형태로 전환하는가?

**전환의 목적은 신호를 고치는 것이 아니라, 이미 있는 정보를 해석하기 쉬운 두 값으로 묶는 것이다.** Sine-cosine form에서 $$a_n,b_n$$는 두 orthogonal basis 방향의 좌표다. Amplitude-phase form에서 $$A_n,\phi_n$$는 그 좌표의 길이와 방향이다. 직교좌표를 극좌표로 바꾸는 것과 같으며, 두 실수로 표현하던 정보를 두 실수로 유지한다.

| Representation | 읽기 쉬운 질문 | 보존하는 정보 |
|---|---|---|
| $$a_n,b_n$$ | cosine·sine basis가 각각 얼마나 필요한가? | 같은 frequency의 두 projection |
| $$A_n,\phi_n$$ | 성분이 얼마나 크고, 기준 시각에 어떻게 정렬되는가? | 동일한 성분의 amplitude와 phase |
| $$c_n$$ | 복소 exponential로 합성·필터링을 어떻게 계산하는가? | 동일한 정보를 묶은 complex coefficient |

Phase 없이 $$A_n\cos(n\omega_0t)$$만 쓰면 모든 성분을 기준 시각에서 같은 cosine 방향에 고정한다. 이런 cosine 합은 $$t=0$$을 기준으로 짝함수이므로, 임의의 sine 성분이나 일반적인 시간 정렬을 표현하지 못한다. **Sine-cosine form에서는 $$b_n$$가 담고 있던 정보를, cosine 하나로 묶은 뒤에는 $$\phi_n$$가 담당한다.**

이 재표현 자체는 필수가 아니다. $$a_n,b_n$$ 또는 $$c_n$$를 그대로 사용해도 정확히 분석·복원할 수 있다. Amplitude spectrum과 phase spectrum을 나눠 읽거나 각 harmonic의 기여와 정렬을 설명할 때 특히 유용하다. 두 표현의 동등성과 waveform을 결정하는 coefficient의 역할은 <a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/3ab918dbe6a0376dbd9216e404fee31b_fourier.pdf" target="_blank" rel="noopener">MIT OCW: Fourier Series Representation of Signals, pp.3-4</a>에서도 확인할 수 있다. 이 글의 cosine·minus-phase convention과 다른 교재의 sine·plus-phase convention을 혼용하지 않아야 한다.

#### 6.2.2 작성자 보충: 변환을 계산하고 atan2의 필요성 확인하기

$$a_n,b_n$$는 실수이고 $$A_n>0$$이라고 하자. 앞의 항등식에서 coefficient를 비교하면

$$
a_n=A_n\cos\phi_n,\qquad b_n=A_n\sin\phi_n.
$$

양쪽을 제곱해 더하면

$$
a_n^2+b_n^2=A_n^2(\cos^2\phi_n+\sin^2\phi_n)=A_n^2.
$$

따라서 nonnegative amplitude를 선택하면

$$
A_n=\sqrt{a_n^2+b_n^2},\qquad
\cos\phi_n=\frac{a_n}{A_n},\qquad
\sin\phi_n=\frac{b_n}{A_n}.
$$

예를 들어 정규화된 신호에서 $$a_n=3,b_n=4$$이면

$$
3\cos\alpha+4\sin\alpha
=5\cos(\alpha-\phi_n),\qquad
\phi_n=\operatorname{atan2}(4,3)
\approx0.9273\ \mathrm{rad}\approx53.13^{\circ}.
$$

$$\alpha=0$$에서 양쪽은 3, $$\alpha=\pi/2$$에서 양쪽은 4다. 오른쪽을 전개하면 모든 $$\alpha$$에서 왼쪽과 같으므로 이것은 근사가 아닌 정확한 항등식이며, 반올림한 angle 값만 근사다.

여기서 $$\arctan(b_n/a_n)$$만 쓰면 사분면 정보를 잃는다. $$a_n=-3,b_n=4$$일 때 올바른 phase는 second quadrant의 $$\operatorname{atan2}(4,-3)\approx2.2143\ \mathrm{rad}$$다. 단순히 $$\arctan(-4/3)\approx-0.9273\ \mathrm{rad}$$를 택하면 cosine·sine coefficient의 부호가 둘 다 뒤집힌다. $$a_n=0$$에서도 나눗셈 대신 두 좌표를 받는 `atan2(y, x)`를 사용해야 한다. $$a_n=b_n=0$$이면 성분 자체가 없으므로 phase에는 물리적 의미를 부여하지 않는다.

부호를 확인하는 가장 안전한 방법은 다음처럼 **먼저 cosine 덧셈 정리를 전개하는 것**이다.

| Convention | Coefficient relation | Phase |
|---|---|---|
| $$A\cos(\omega t-\phi)$$ | $$a=A\cos\phi,\ b=A\sin\phi$$ | $$\phi=\operatorname{atan2}(b,a)$$ |
| $$A\cos(\omega t+\delta)$$ | $$a=A\cos\delta,\ b=-A\sin\delta$$ | $$\delta=\operatorname{atan2}(-b,a)$$ |

두 angle은 $$\delta\equiv-\phi\pmod{2\pi}$$로 대응한다. Plus-phase convention과 `atan2`의 사분면 문제는 <a href="https://pordlabs.ucsd.edu/sgille/sioc221a_f20/lecture14_notes.pdf" target="_blank" rel="noopener">UCSD SIOC 221A lecture notes, p.2</a>를 참고했다.

#### 6.2.3 작성자 보충: 실제 phase shift와 time delay는 무엇이 다른가?

앞의 $$3\cos\alpha+4\sin\alpha=5\cos(\alpha-\phi)$$는 **같은 함수를 다시 쓴 것**이므로 새로운 지연을 가하지 않는다. 반면 실제로 입력을 $$y(t)=x(t-\tau)$$로 바꾸는 연산은 모든 사건을 $$\tau>0$$ seconds만큼 늦춘다. 한 sinusoid에 적용하면

$$
x(t)=A\cos(\omega t+\delta),\qquad
y(t)=A\cos(\omega t+\delta-\omega\tau).
$$

즉 plus-phase 기준의 변화량은 $$\Delta\delta=-\omega\tau=-2\pi f\tau$$ radians다. Minus-phase form에서는 같은 지연이 $$\phi\mapsto\phi+\omega\tau$$로 나타난다. **기호 앞의 부호가 다를 뿐, 두 표현은 같은 지연을 뜻한다.**

1000 Hz의 zero-phase cosine을 0.25 ms 늦추면

$$
\omega\tau=2\pi\times1000\times0.00025=\frac{\pi}{2},\qquad
y(t)=A\cos(2\pi1000t-\pi/2)=A\sin(2\pi1000t).
$$

Peak가 0.25 ms 늦게 나타나며 amplitude와 frequency는 변하지 않는다. 단일 주파수에서는 phase가 $$2\pi$$ 단위로 같아지므로 phase만으로 지연을 구하면 주기 정수배의 모호성이 남는다.

여러 harmonic으로 된 신호 전체를 같은 $$\tau$$만큼 지연하려면 각 harmonic에 $$-n\omega_0\tau$$의 plus-phase 변화를 줘야 한다. **모든 harmonic의 phase에 같은 angle을 더하는 것은 일반적으로 전체 waveform의 단순한 시간 이동이 아니다.** 예를 들어 위의 0.25 ms 지연은 1000 Hz에는 $$-\pi/2$$, 2000 Hz에는 $$-\pi$$를 요구한다.

Fourier transform으로도 이를 직접 유도할 수 있다. 적분이 정의되는 신호에서 $$u=t-\tau$$로 치환하면

$$
\begin{aligned}
Y(f)&=\int_{-\infty}^{\infty}x(t-\tau)e^{-j2\pi ft}\,dt\\
&=\int_{-\infty}^{\infty}x(u)e^{-j2\pi f(u+\tau)}\,du\\
&=e^{-j2\pi f\tau}X(f).
\end{aligned}
$$

곱해지는 복소수의 크기가 1이므로 $$\lvert Y(f)\rvert=\lvert X(f)\rvert$$이고, phase는 주파수에 비례해 변한다. $$X(f)=0$$인 곳에서는 phase가 정의되지 않는다. 이 time-shift 성질은 <a href="https://www.seas.upenn.edu/~ese2240/slides/300_fourier_transforms.pdf" target="_blank" rel="noopener">University of Pennsylvania: Fourier Transforms, p.63</a>와 같은 convention이다. 위 적분 증명의 적용 조건을 만족하지 않는 이상적 periodic tone은 Fourier-series coefficient에 동일한 시간 이동을 대입해 확인하면 된다.

#### 6.2.4 작성자 보충: 복원·신호 합산에서 phase를 보존하는 이유

Fourier 합성은 같은 시각의 component 값을 더하는 작업이다. 따라서 amplitude만 같아도 phase가 다르면 합산 결과가 달라진다. **같은 frequency·같은 amplitude**의 두 성분에 대해 삼각함수 합 공식은

$$
A\cos\theta+A\cos(\theta+\Delta)
=2A\cos(\Delta/2)\cos(\theta+\Delta/2)
$$

를 준다. 여기서 $$\Delta$$는 두 성분 사이의 상대 phase(rad), $$\theta=\omega t+\delta$$다. $$\Delta=0$$이면 같은 값끼리 더해져 amplitude가 $$2A$$가 되고, $$\Delta=\pi$$이면 한 성분의 peak가 다른 성분의 trough와 겹쳐 합이 0이 된다. 서로 다른 frequency는 상대 phase가 시간에 따라 변하므로 이 고정 상쇄 조건을 그대로 적용할 수 없다.

이 식을 도입하는 이유는 **각 입력의 amplitude를 더하는 것과 실제 합성파의 amplitude를 구하는 것이 다름**을 계산으로 확인하기 위해서다. 유도할 때 두 angle의 중간값 $$\beta=\theta+\Delta/2$$, 반간격 $$\gamma=\Delta/2$$를 두면

$$
\begin{aligned}
\cos\theta+\cos(\theta+\Delta)
&=\cos(\beta-\gamma)+\cos(\beta+\gamma)\\
&=(\cos\beta\cos\gamma+\sin\beta\sin\gamma)
+(\cos\beta\cos\gamma-\sin\beta\sin\gamma)\\
&=2\cos\beta\cos\gamma.
\end{aligned}
$$

Sine 항이 상쇄되므로 앞의 합성식이 나오며, nonnegative peak amplitude는 $$2A\lvert\cos(\Delta/2)\rvert$$다. 예를 들어 $$\Delta=\pi/2$$이면 각 입력 amplitude가 $$A$$여도 합성파의 amplitude는 $$\sqrt{2}A$$이지 $$2A$$가 아니다. 여기서는 $$A\ge0$$를 사용한다.

이는 두 microphone 신호를 합하거나 direct sound와 delayed reflection이 섞일 때 정렬이 중요한 이유를 설명하는 단순 모델이다. 실제로는 amplitude 차이·여러 지연·noise가 있어 완전 상쇄가 보장되지는 않는다. Broadband 신호를 같은 시간에 맞추려면 한 주파수의 phase만 조절하는 대신 앞 절의 frequency-dependent delay 관계를 고려해야 한다.

정확한 waveform 복원에는 원래 complex coefficient를 유지하거나 동등한 amplitude와 phase를 함께 사용해야 한다. Magnitude만 남기면 Section 5.2의 cosine과 sine처럼 서로 다른 waveform이 같은 magnitude 설명을 갖기 때문에 일반적으로 원 신호를 유일하게 정할 수 없다. Recognition용 feature에서는 필요에 따라 magnitude 중심의 표현을 선택할 수 있지만, 이것이 원본 waveform까지 정확히 복원할 수 있다는 뜻은 아니다.

> **정리:** Phase를 다른 형태로 쓰는 이유는 **해석과 계산을 쉽게 하기 위해서**, phase 정보를 보존하는 이유는 **성분의 정렬과 waveform을 잃지 않기 위해서**, 실제 phase·delay를 조절하는 이유는 **정렬·합산 같은 별도의 처리 목적을 달성하기 위해서**다. 세 가지를 같은 “phase 전환”으로 섞어 이해하지 않는다.

### 6.3 Complex exponential form

$$
x(t) = \sum_{n=-\infty}^{\infty} c_n e^{jn\omega_0 t}
$$

세 형태는 서로 다른 신호가 아니라 **같은 periodic signal을 표현하는 세 가지 표기법**이다. Complex form은 positive frequency와 negative frequency를 함께 다루며 algebra를 단순화한다.

Real-valued $$x(t)$$에서는 Euler formula로 cosine과 sine을 positive/negative exponential 쌍으로 바꿀 수 있으며, coefficient는 $$c_{-n}=c_n^*$$라는 conjugate symmetry를 갖는다. Fourier series가 점별로 원 신호에 수렴하려면 단순히 “주기적”이라는 조건만으로는 부족하다. Piecewise smooth 같은 표준 충분조건 아래에서는 연속점에서 $$x(t)$$로, jump에서는 좌우 극한의 평균으로 수렴한다.

#### 6.3.1 작성자 보충: exponential인데 왜 커지지 않고 진동하는가?

> **핵심:** $$e^{jn\omega_0t}$$는 크기가 지수적으로 증가하는 신호가 아니라 **복소 평면에서 일정한 속도로 회전하는 길이 1의 basis**다. $$c_n$$가 각 basis의 크기와 초기 방향을 정한다. 실수 음성 신호는 반대 방향으로 도는 conjugate pair를 더해 표현한다.

실수 exponent를 갖는 $$e^{at}$$와 달리, 여기서는 exponent가 순허수다. Section 5.1의 Euler formula와 $$\cos^2\theta+\sin^2\theta=1$$에서

$$
e^{j\theta}=\cos\theta+j\sin\theta,\qquad
\lvert e^{j\theta}\rvert
=\sqrt{\cos^2\theta+\sin^2\theta}=1
$$

을 얻는다. $$\theta=n\omega_0t$$이므로 amplitude는 일정하고 angle만 변한다. $$n>0$$은 반시계 방향, $$n<0$$은 시계 방향 회전에 대응하며 $$n=0$$이면 $$e^0=1$$인 DC basis다.

여기서 $$j^2=-1$$이고 $$j,n$$은 무차원, $$\omega_0$$는 rad/s, $$t$$는 seconds다. Exponential basis는 무차원이므로 $$c_n$$는 원래 $$x(t)$$와 같은 amplitude 단위를 갖는다. 입력이 음압이면 $$c_n$$의 실수부·허수부도 Pa 단위를 가지며, 둘은 계산용 좌표이지 별도의 “허수 음압”을 센서가 측정한다는 뜻이 아니다.

#### 6.3.2 작성자 보충: sine-cosine form에서 complex 계수를 유도하기

실수 신호의 한 positive harmonic $$n\ge1$$을 고르고 $$\theta=n\omega_0t$$로 두자. Euler formula에 $$\theta$$와 $$-\theta$$를 대입한 식을 더하고 빼면

$$
\cos\theta=\frac{e^{j\theta}+e^{-j\theta}}{2},\qquad
\sin\theta=\frac{e^{j\theta}-e^{-j\theta}}{2j}
$$

다. 이를 같은 frequency의 cosine·sine 합에 대입하고 $$1/j=-j$$를 사용하면

$$
\begin{aligned}
a_n\cos\theta+b_n\sin\theta
&=\frac{a_n}{2}(e^{j\theta}+e^{-j\theta})
+\frac{b_n}{2j}(e^{j\theta}-e^{-j\theta})\\
&=\frac{a_n-jb_n}{2}e^{j\theta}
+\frac{a_n+jb_n}{2}e^{-j\theta}.
\end{aligned}
$$

따라서 계수의 정확한 대응은 다음과 같다.

| Index | Complex coefficient | Meaning |
|---|---|---|
| $$0$$ | $$c_0=a_0/2$$ | 원래 신호의 평균값인 DC |
| $$n>0$$ | $$c_n=(a_n-jb_n)/2$$ | positive-frequency basis의 계수 |
| $$-n<0$$ | $$c_{-n}=(a_n+jb_n)/2$$ | negative-frequency basis의 계수 |

모든 harmonic에 이 치환을 적용하고 DC를 포함해 한 합으로 묶은 것이 $$x(t)=\sum_{n=-\infty}^{\infty}c_ne^{jn\omega_0t}$$다. **성분이나 정보를 새로 추가한 것이 아니라 같은 sine·cosine 성분을 다른 basis로 나눈 것이다.** 유한 합에서는 대수적 항등식이고, 무한 Fourier series의 원 신호에 대한 수렴은 앞서 적은 조건을 별도로 따른다.

같은 계수 변환과 conjugate symmetry는 <a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/3ab918dbe6a0376dbd9216e404fee31b_fourier.pdf" target="_blank" rel="noopener">MIT OCW: Fourier Series Representation of Signals, p.4, Eqs. (7)-(10)</a>에도 제시되어 있다. 원본 강의 PDF p.21의 summation index는 $$n$$인데 coefficient가 $$c_k$$로 쓰인 부분은 이 글에서 $$c_n$$로 일치시켰다.

#### 6.3.3 작성자 보충: 음의 주파수가 있어야 실수 신호가 되는 이유

$$a_n,b_n$$가 실수이면 $$c_{-n}=c_n^*$$다. 별표 $$*$$는 complex conjugate로, 허수부의 부호를 뒤집는 연산이다. Positive-frequency 항을 $$z=c_ne^{jn\omega_0t}$$라고 두면 반대편 항은 정확히 $$z^*$$이므로

$$
c_ne^{jn\omega_0t}+c_{-n}e^{-jn\omega_0t}
=z+z^*=2\operatorname{Re}(z).
$$

허수부가 서로 상쇄되어 실수 성분만 남는다. $$c_0$$도 실수이므로 전체 합이 실수 waveform을 이룬다. 반면 positive-frequency 항만 남기면 일반적으로 원래의 실수 waveform이 아니라 complex-valued 표현이 된다.

**음의 주파수는 시간이 거꾸로 흐르거나 사람이 음의 pitch를 듣는다는 뜻이 아니다.** 복소 평면의 반대 회전을 구분하는 수학적 좌표다. Real-valued 신호에서 양·음 주파수 coefficient는 독립적인 두 정보가 아니며 conjugate symmetry로 연결된다. 일반적인 complex-valued 신호는 이 대칭을 반드시 만족하지 않는다.

#### 6.3.4 작성자 보충: amplitude·phase와 연결하고 숫자로 복원하기

Section 6.2의 minus-phase convention에서 $$a_n=A_n\cos\phi_n$$, $$b_n=A_n\sin\phi_n$$이므로

$$
c_n=\frac{A_n}{2}(\cos\phi_n-j\sin\phi_n)
=\frac{A_n}{2}e^{-j\phi_n},\qquad n>0.
$$

따라서 nonzero harmonic의 inverse 관계는

$$
A_n=2\lvert c_n\rvert,\qquad
\phi_n\equiv-\arg(c_n)\pmod{2\pi}
$$

다. $$\arg(c_n)$$는 complex coefficient의 angle(rad)이며, $$c_n=0$$일 때는 정의되지 않는다. **실수 cosine 하나가 양·음 주파수 쌍으로 나뉘므로 각 쪽의 크기는 peak amplitude의 절반이다.** 이 factor 2는 $$n>0$$의 two-sided Fourier-series coefficient와 one-sided peak amplitude 사이의 관계이며 DC에는 적용하지 않는다. 다른 FFT normalization이나 power spectrum에 그대로 붙여서도 안 된다.

앞의 $$3\cos\alpha+4\sin\alpha$$ 예에서는 $$c_n=1.5-2j$$, $$c_{-n}=1.5+2j$$이고 $$\lvert c_n\rvert=2.5$$다. 다시 합성하면

$$
\begin{aligned}
(1.5-2j)e^{j\alpha}+(1.5+2j)e^{-j\alpha}
&=2\operatorname{Re}\bigl((1.5-2j)(\cos\alpha+j\sin\alpha)\bigr)\\
&=3\cos\alpha+4\sin\alpha.
\end{aligned}
$$

즉 amplitude는 $$2\times2.5=5$$이고 minus-phase는 $$-\arg(1.5-2j)\approx0.9273$$ rad로 Section 6.2와 일치한다. “Amplitude 5가 2.5로 줄었다”가 아니라 **같은 waveform을 두 회전 basis에 나누어 표현했다**고 읽어야 한다.

#### 6.3.5 작성자 보충: 굳이 complex form을 사용하는 계산상의 이유

Sine·cosine 표기로도 계산할 수 있지만 complex exponential은 여러 연산을 같은 형태로 유지한다. 먼저 basis 하나를 미분하면

$$
\frac{d}{dt}e^{jn\omega_0t}
=jn\omega_0e^{jn\omega_0t}
$$

이므로 basis 자체는 그대로이고 coefficient에 $$jn\omega_0$$만 곱해진다. Sine을 미분하면 cosine으로 바뀌고 cosine을 미분하면 부호가 붙은 sine으로 바뀌는 관계를 이 한 식으로 묶는다. 전체 무한 series를 항별로 미분하려면 추가 수렴·매끄러움 조건이 필요하며, 여기서는 개별 basis 또는 유한 합에 대한 정확한 연산을 먼저 확인한 것이다.

시간 이동도 exponential의 곱셈 법칙으로 간단해진다.

$$
c_ne^{jn\omega_0(t-\tau)}
=\bigl(c_ne^{-jn\omega_0\tau}\bigr)e^{jn\omega_0t}.
$$

따라서 지연된 신호의 coefficient는 $$c'_n=c_ne^{-jn\omega_0\tau}$$다. 크기는 그대로이고 angle만 변한다는 Section 6.2의 결과가 coefficient의 곱셈 하나로 정리된다. $$c'_n$$의 prime은 새 coefficient를 구분하는 표기이며 시간 미분 표시가 아니다.

다음 Section 7에서는 basis와 conjugate basis의 곱이 $$e^{j(n-m)\omega_0t}$$로 합쳐지는 성질을 이용해 orthogonality와 coefficient 추출을 증명한다. 이후 sampling하면 $$e^{jn\omega_0t}$$가 discrete index의 $$e^{j2\pi kn/N}$$로 이어진다. **Complex form은 amplitude와 phase를 함께 보존하면서 미분·시간 이동·projection·DFT를 같은 exponential 계산으로 연결하는 공통 표기**다. 새로운 물리적 가정을 추가하거나 원본 audio를 complex-valued로 바꿔 저장해야 한다는 요구가 아니다.

### 6.4 작성자 보충: harmonic, overtone, partial의 번호와 단위

> **핵심:** Harmonic은 단순히 “높은 소리”가 아니라, fundamental frequency $$f_0$$의 정수배 $$nf_0$$에 놓이는 sinusoidal component다. **가로 위치는 frequency, 세로 크기는 amplitude, 시작 각도는 phase**이며 서로 다른 정보다.

원본 PDF pp.19-24는 정수배 주파수와 amplitude-phase form을 소개한다. 아래 용어 정리·계산·음성 연결은 그 부분을 이해하기 위한 작성자 보충이며 원본의 추가 슬라이드는 아니다.

$$f_0=100\ \mathrm{Hz}$$인 harmonic series를 예로 들면 다음과 같다.

| Component | Frequency | Harmonic number | Overtone name |
|---|---|---|---|
| DC | $$0\ \mathrm{Hz}$$ | 진동하지 않는 평균값 | 해당 없음 |
| Fundamental | $$100\ \mathrm{Hz}$$ | First harmonic | 해당 없음 |
| Second harmonic | $$200\ \mathrm{Hz}$$ | Second harmonic | First overtone |
| Third harmonic | $$300\ \mathrm{Hz}$$ | Third harmonic | Second overtone |
| Fourth harmonic | $$400\ \mathrm{Hz}$$ | Fourth harmonic | Third overtone |

이 overtone 번호는 fundamental부터 연속된 harmonic series를 기준으로 한다. **Partial**은 소리를 구성하는 개별 sinusoidal component를 가리키는 더 넓은 말이다. Inharmonic sound의 partial은 정수배가 아닐 수 있고, 성분이 빠진 소리에서 “관측된 두 번째 partial”을 반드시 second harmonic이라고 부를 수도 없다. 따라서 실측 spectrum에서는 순서만 세지 말고 $$f/f_0$$를 확인해야 한다. Harmonic series의 기본 번호 대응은 <a href="https://courses.physics.illinois.edu/phys406/sp2017/Lecture_Notes/P406POM_Lecture_Notes/P406POM_Lect6.pdf" target="_blank" rel="noopener">UIUC Physics 406 lecture notes, p.2</a>를 참고했다.

| Symbol | Meaning | Unit / domain |
|---|---|---|
| $$t$$ | 관측 시각 | $$\mathrm{s}$$ |
| $$T_0$$ | waveform의 최소 양의 반복 주기 | $$\mathrm{s}$$ |
| $$f_0=1/T_0$$ | fundamental frequency | $$\mathrm{Hz}=\mathrm{s}^{-1}$$ |
| $$n$$ | harmonic index | 무차원 양의 정수 |
| $$f_n=nf_0$$ | $$n$$번째 harmonic frequency | $$\mathrm{Hz}$$ |
| $$\omega_n=2\pi f_n$$ | angular frequency | $$\mathrm{rad/s}$$ |
| $$A_n$$ | cosine component의 peak amplitude | $$x(t)$$와 같은 단위: 음압이면 Pa, 전압이면 V, 정규화 waveform이면 무차원 |
| $$\phi_n$$ | Section 6.2의 minus-sign convention에 따른 phase | $$\mathrm{rad}$$ |
| $$c_n$$ | complex Fourier-series coefficient | $$x(t)$$와 같은 amplitude 단위 |

$$nf_0t$$는 “반복 횟수”로 무차원이며, $$2\pi nf_0t$$는 그에 대응하는 phase다. **Harmonic 번호 $$n$$은 Hz 단위의 측정값이 아니다.**

### 6.5 작성자 보충: 왜 정수배인가?

먼저 한 complex exponential이 $$T_0$$ 후에 같은 값으로 돌아오는 조건을 보자. $$u(t)=e^{j2\pi ft}$$라 하면

$$
u(t+T_0)=u(t)e^{j2\pi fT_0}.
$$

따라서 $$u(t+T_0)=u(t)$$이려면 한 주기 동안 회전한 각도가 정수 번의 완전한 회전이어야 한다.

$$
e^{j2\pi fT_0}=1
\quad\Longleftrightarrow\quad
fT_0=n,\quad n\in\mathbb{Z}
\quad\Longleftrightarrow\quad
f=\frac{n}{T_0}=nf_0.
$$

Cosine으로 확인해도

$$
\begin{aligned}
\cos(2\pi nf_0(t+T_0)-\phi_n)
&=\cos(2\pi nf_0t+2\pi n-\phi_n)\\
&=\cos(2\pi nf_0t-\phi_n)
\end{aligned}
$$

이므로 같은 값이다. **한 번의 전체 반복 동안 first harmonic은 1회, second harmonic은 2회, third harmonic은 3회 진동한다.** Section 7의 orthogonality는 이 grid 위의 성분들을 서로 분리하는 근거다. 이 회전 조건만으로 모든 periodic function의 Fourier-series 수렴까지 증명한 것은 아니다.

반대로 같은 grid의 sinusoid들을 합하면 $$T_0$$는 합성파의 한 주기가 된다. 다만 반드시 *최소* 주기인 것은 아니다. 예를 들어 200 Hz와 400 Hz만 존재하면 100 Hz grid로도 표시할 수 있지만 실제 fundamental은 200 Hz다. 정수 index의 유한한 집합 $$S$$에만 nonzero coefficient가 있으면

$$
f_{\mathrm{fund}}=\gcd(S)f_{\mathrm{grid}}.
$$

이유는 모든 성분이 다시 정렬되는 조건이 $$n f_{\mathrm{grid}}T\in\mathbb{Z}$$이기 때문이다. $$d=\gcd(S)$$로 두면 $$T=1/(d f_{\mathrm{grid}})$$는 모든 조건을 만족한다. 또한 Bézout identity로 $$d$$는 $$S$$의 index들의 정수 선형 결합이므로 어떤 공통 주기에서도 $$d f_{\mathrm{grid}}T$$는 양의 정수여야 한다. 따라서 이보다 작은 양의 공통 주기는 없다. 여기서는 서로 다른 frequency에 실제로 존재하는 성분만 세며, DC는 제외한다.

### 6.6 작성자 보충: 세 harmonic을 더하면 무엇이 달라지는가?

$$t$$를 seconds로 재고 amplitude를 무차원으로 정규화한 다음 신호를 보자.

$$
x(t)=\cos(2\pi100t)
+0.5\cos(2\pi200t)
+0.25\cos(2\pi300t).
$$

| Component | Frequency | Peak amplitude | Phase |
|---|---|---|---|
| First harmonic | 100 Hz | 1 | 0 rad |
| Second harmonic | 200 Hz | 0.5 | 0 rad |
| Third harmonic | 300 Hz | 0.25 | 0 rad |

이상적인 **one-sided peak-amplitude line spectrum**에는 100, 200, 300 Hz 위치에 높이 1, 0.5, 0.25인 선을 그린다. 이는 power spectrum이나 dB spectrum이 아니다. Section 6.3의 two-sided complex coefficient로 그리면 $$\cos\theta=(e^{j\theta}+e^{-j\theta})/2$$이므로 각 amplitude가 positive/negative frequency에 절반씩 나뉜다. 즉 $$c_{\pm1}=0.5$$, $$c_{\pm2}=0.25$$, $$c_{\pm3}=0.125$$다.

시간축에서는 같은 시각의 값을 **세로로 더한다.** $$t=0$$에서는 $$x(0)=1+0.5+0.25=1.75$$다. $$t=5\ \mathrm{ms}$$에서는

$$
x(0.005)=\cos\pi+0.5\cos2\pi+0.25\cos3\pi
=-1+0.5-0.25=-0.75.
$$

$$t=10\ \mathrm{ms}$$가 지나면 세 성분 모두 처음 상태로 돌아가고, 전체 waveform의 최소 주기도 10 ms다. **Harmonic을 더한다고 frequency를 100+200+300=600 Hz로 합치는 것은 아니다.** 합성 신호는 세 frequency를 동시에 포함한다.

Amplitude를 바꾸면 각 frequency의 기여도가 바뀌어 한 주기 안의 굴곡과 음색에 영향을 준다. Frequency와 amplitude를 고정하고 phase만 바꿔도 성분의 정렬 시점과 waveform 모양은 달라질 수 있지만 magnitude line spectrum은 같다. 위상 변화가 청각적으로 얼마나 들리는지는 자극과 조건에 달려 있다. **Timbre를 harmonic amplitude 하나로 완전히 설명할 수는 없다.** 실제 소리의 attack·decay, noise, 시간에 따른 변화도 함께 고려해야 한다.

### 6.7 작성자 보충: 기본음이 없으면 fundamental도 없어지는가?

**Spectrum의 $$f_0$$ 성분이 0인 것과 waveform의 반복 주기가 사라지는 것은 다르다.** 앞 예제에서 100 Hz 항만 제거하자.

$$
y(t)=0.5\cos(2\pi200t)+0.25\cos(2\pi300t).
$$

반복 주기 $$T$$가 되려면 $$200T=m$$, $$300T=n$$이 모두 정수여야 한다. 따라서 $$3m=2n$$이고 가장 작은 양의 해는 $$m=2,n=3$$이다.

$$
T_0=\frac{2}{200}=\frac{3}{300}=0.01\ \mathrm{s},
\qquad f_0=100\ \mathrm{Hz}.
$$

100 Hz의 spectral line은 없어도 200 Hz와 300 Hz 성분이 10 ms마다 함께 정렬된다. 이런 harmonic complex tone에서 청자는 실제 $$f_0$$ 성분이 없는데도 그에 대응하는 pitch를 지각할 수 있다. 이를 **missing fundamental** 현상이라고 한다. 이는 위의 주기 계산에서 자동으로 증명되는 청각 법칙이 아니라 실험적으로 알려진 지각 현상이다. 성분 구성·주파수 대역·청취 조건에 따라 pitch의 명료도는 달라진다. <a href="https://open.lib.umn.edu/sensationandperception/chapter/pitch-perception/" target="_blank" rel="noopener">University of Minnesota: Pitch Perception</a>에서 물리적 frequency와 pitch의 관계를 함께 설명한다.

따라서 fundamental을 추정할 때 **가장 낮은 peak**나 **가장 큰 peak** 하나를 그대로 정답으로 삼으면 안 된다. 다만 200 Hz와 400 Hz만 남는 경우는 실제 반복 주파수가 200 Hz이므로, 아무 harmonic subset에나 100 Hz missing fundamental이라는 해석을 붙여서도 안 된다.

### 6.8 작성자 보충: 음성의 harmonic, formant, DFT bin은 서로 다르다

Voiced speech를 짧은 구간에서 거의 주기적이라고 근사하면 vocal-fold excitation이 harmonic series를 만들고, vocal tract의 공명이 그 성분들의 상대적 크기를 바꾼다고 볼 수 있다. **Harmonic은 excitation의 반복에 따른 선 구조이고, formant는 vocal tract filter의 공명 대역이다.** <a href="https://icm.music.cs.cmu.edu/icm-online/icm-text-2nd-ed.pdf" target="_blank" rel="noopener">CMU: Introduction to Computer Music, Chapter 9, pp.159-160</a>의 source-filter 설명을 이 구분에 참고했다.

| Concept | Determines / describes | Not the same as |
|---|---|---|
| Fundamental $$f_0$$ | 이상적 주기 신호의 반복률(물리량); voiced speech의 지각 pitch를 알려 주는 주요 단서 | pitch 자체 또는 항상 가장 크거나 낮은 관측 peak |
| Harmonic $$nf_0$$ | excitation의 정수배 frequency 성분 | formant의 번호 |
| Formant $$F_1,F_2,\ldots$$ | vocal tract의 공명과 spectral envelope의 봉우리 | 반드시 $$f_0$$의 정수배인 frequency |
| DFT bin $$k f_s/N$$ | 유한 sample 구간을 분석하는 frequency grid | 실제 음원에 존재하는 harmonic |

예를 들어 $$f_0=100\ \mathrm{Hz}$$이고 한 formant가 550 Hz 부근에 있다면, 공명은 500 Hz·600 Hz 등의 인접 harmonic을 대역폭에 따라 강조한다. 이상적인 선형·시간불변 filter 모델에서는 이것만으로 새로운 550 Hz harmonic을 만들어 내지 않는다. 입 모양을 바꾸면 주로 formant pattern이, vocal-fold 반복률을 바꾸면 주로 harmonic 간격이 바뀐다는 것이 source-filter 모델의 유용한 출발점이다. 실제 발성의 상호작용까지 완전히 독립이라는 뜻은 아니다.

**왜 filter는 harmonic 위치보다 크기·phase를 바꾸는가?** 이를 도출하기 위해 짧은 voiced 구간의 excitation을 유한한 Fourier 합 $$s(t)=\sum_{n=-K}^{K}s_ne^{jn\omega_0t}$$로 모델링하고, vocal tract를 impulse response $$h_{\mathrm{VT}}(\tau)$$인 linear time-invariant(LTI) filter로 근사하자. $$K$$는 무차원 정수 cutoff, $$\tau$$는 seconds다. 이 예에서는 입력·출력을 무차원으로 정규화하여 $$h_{\mathrm{VT}}$$의 단위는 $$\mathrm{s}^{-1}$$, frequency response $$H_{\mathrm{VT}}$$는 무차원 gain이 된다. 실제 측정계에서는 입출력 물리량에 맞는 단위를 별도로 적용해야 한다.

$$h_{\mathrm{VT}}$$가 절대적분 가능하다고 가정하면 convolution에 유한 합을 대입해

$$
\begin{aligned}
y(t)
&=\int_{-\infty}^{\infty}h_{\mathrm{VT}}(\tau)s(t-\tau)\,d\tau\\
&=\sum_{n=-K}^{K}s_ne^{jn\omega_0t}
\int_{-\infty}^{\infty}h_{\mathrm{VT}}(\tau)e^{-jn\omega_0\tau}\,d\tau\\
&=\sum_{n=-K}^{K}s_nH_{\mathrm{VT}}(nf_0)e^{jn\omega_0t}
\end{aligned}
$$

를 얻는다. 마지막 줄에서는 $$H_{\mathrm{VT}}(f)=\int h_{\mathrm{VT}}(\tau)e^{-j2\pi f\tau}\,d\tau$$라는 Fourier-transform 정의를 사용했다. 따라서 출력의 $$n$$번째 Fourier-series coefficient는

$$
y_n=H_{\mathrm{VT}}(nf_0)s_n.
$$

즉 **기존 harmonic의 complex coefficient에 filter response가 곱해지고, basis의 frequency $$nf_0$$는 그대로다.** 550 Hz 부근 공명은 $$H_{\mathrm{VT}}(500)$$와 $$H_{\mathrm{VT}}(600)$$의 크기·phase에 반영된다. 입력에 없는 550 Hz 성분을 선형·시간불변 filter가 새로 만들어 내는 것은 아니다. 이 유도는 짧은 구간을 정상적인 LTI 응답으로 근사한 결과이며, 급격한 발성 변화·초기 transient·비선형 효과까지 정확히 설명하는 모델은 아니다.

또한 harmonic 간격 $$f_0$$와 DFT bin 간격은 구별해야 한다. Sample rate $$f_s$$로 $$N$$개를 관측하면 DFT의 periodic extension 길이는 $$T_{\mathrm{obs}}=N/f_s$$이고, Section 11의 basis에서 $$k$$와 $$k+1$$의 frequency 차이는

$$
\Delta f_{\mathrm{bin}}
=\frac{(k+1)f_s}{N}-\frac{kf_s}{N}
=\frac{f_s}{N}=\frac{1}{T_{\mathrm{obs}}}.
$$

$$f_s=16{,}000\ \mathrm{sample/s}$$, $$N=400\ \mathrm{sample}$$이면 $$T_{\mathrm{obs}}=25\ \mathrm{ms}$$, $$\Delta f_{\mathrm{bin}}=40\ \mathrm{Hz}$$다. $$f_0=100\ \mathrm{Hz}$$인 harmonic은 100 Hz 간격이므로 모든 harmonic이 DFT bin에 정확히 맞지는 않는다. 유한 window에서는 leakage까지 고려해야 하며, bin 간격만으로 두 tone의 실제 분리 능력을 단정해서도 안 된다.

이 설명은 정확한 periodic signal 또는 짧은 voiced frame의 근사에 적용한다. Whisper·무성 마찰음·transient처럼 noise나 비주기성이 지배적인 구간의 peak를 모두 harmonic으로 부르면 안 된다.

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

> **핵심:** Fourier transform은 비주기 신호를 연속적인 frequency의 complex exponential로 분석하는 표현이다. 강의는 **주기 $$P$$를 늘려 주파수 간격을 줄이고, Fourier series의 합을 적분으로 바꾸는 방법**으로 정의와 역변환을 연결한다. 이때 $$c_n$$을 그대로 $$X(\omega)$$로 바꾸면 안 된다. 계수에 들어 있던 $$1/P$$가 frequency 간격과 결합하는 과정이 핵심이다.

아래는 원본 PDF pp.29–31의 전개를 단계별로 풀어 쓴 해설이다. Physical page와 slide footer가 다르므로 함께 적었다. 원문에 명시된 정의·극한 방향과, 작성자가 추가한 중간 계산·수렴 검증·예제를 구분한다.

| Source | 강의의 전개 | 이 글의 대응 |
|---|---|---|
| PDF p.29 (footer 32) | Fourier coefficient, $$P\to\infty$$, forward transform | Sections 8.1–8.3 |
| PDF p.30 (footer 33) | $$1/P=\Delta\omega/(2\pi)$$, 합에서 적분, inverse transform | Sections 8.4–8.5 |
| PDF p.31 (footer 35) | Hz convention의 forward/inverse pair | Section 8.6; inverse 적분 변수 오기 정정 |

### 8.1 왜 주기를 늘리는가: 대상 신호와 기호

Fourier series는 한 주기 이후에도 같은 waveform이 반복된다는 모델이다. 반면 하나의 짧은 소리나 유한한 관측 구간을 분석할 때는 그 반복을 실제 신호의 성질로 가정하고 싶지 않다. **원래 파형을 늘이는 것이 아니라, 복제된 파형 사이의 간격을 늘려 반복 모델의 영향을 멀리 보내는 것**이 강의 극한의 의미다. 시간 sampling을 수행하는 과정도 아니다.

먼저 유도를 명확히 하기 위해 다음 충분조건을 둔다. 신호 $$x(t)$$는 유한 구간 밖에서 0이고, 유한 개의 매끄러운 조각과 jump로 이루어진 piecewise $$C^1$$ 함수라고 하자. 각 조각은 끝점까지 유한한 함수값과 미분값을 갖는다고 가정한다. Rectangular pulse도 이 범위에 포함된다. 이것은 모든 Fourier-transform 대상의 필요조건이 아니라, 이번 유도와 점별 역변환을 확인하기 쉬운 범위다.

| Symbol | 의미 | 단위 |
|---|---|---|
| $$t,u,v$$ | 시간과 시간 적분의 보조 변수 | s |
| $$x(t)$$, $$x_P(t)$$ | 원래 신호, 주기 $$P$$인 반복 모델 | 입력 amplitude 단위; 예: V |
| $$T_0,P$$ | 신호가 놓인 구간 길이, 반복 모델의 주기 | s |
| $$f,\Delta f$$ | frequency와 frequency 간격 | Hz |
| $$\omega,\omega_0,\omega_n,\Delta\omega,\Omega$$ | angular frequency, 기본 간격, grid 값, 간격, 적분 cutoff | rad/s |
| $$n,N$$ | harmonic index, 유한 합의 cutoff index | 무차원 정수 |
| $$j$$ | $$j^2=-1$$인 허수 단위; 원문 $$i$$와 동일 | 무차원 |
| $$c_n^{(P)}$$ | 주기 $$P$$ 모델의 Fourier-series coefficient | 입력과 동일; 예: V |
| $$X_\omega(\omega),X_f(f)$$ | angular-frequency/Hz 좌표의 complex spectrum | 입력 단위 × s; 예: V·s |
| $$\theta_X(\omega)$$ | spectrum의 phase angle | rad |
| $$x_\Omega(t),K_\Omega(v)$$ | cutoff inverse 신호, 그 합성 kernel | 각각 입력 단위, $$\mathrm{s}^{-1}$$ |

각도 rad는 SI 차원상 무차원이지만 Hz와 구분하기 위해 표시한다. 따라서 $$\omega t$$와 $$2\pi ft$$는 지수 함수에 넣을 수 있는 무차원 angle이다. 아래 첨자 $$\omega,f$$는 서로 다른 변환을 뜻하는 것이 아니라, 원문의 두 $$X$$가 어떤 좌표를 사용하는지 구분하는 보조 표기다.

### 8.2 Fourier transform의 정의와 음의 지수의 의미

각 frequency에서 분석하는 **forward transform의 정의**는 다음과 같다.

$$
X_\omega(\omega)
=\int_{-\infty}^{\infty}x(t)e^{-j\omega t}\,dt.
$$

Euler formula를 대입하면 무엇을 계산하는지 드러난다.

$$
X_\omega(\omega)
=\int_{-\infty}^{\infty}x(t)\cos(\omega t)\,dt
-j\int_{-\infty}^{\infty}x(t)\sin(\omega t)\,dt.
$$

이는 cosine과 sine 방향에 얼마나 맞물리는지를 동시에 측정한 complex 값이다. **음의 부호는 분석 basis의 complex conjugate에서 나오며**, Section 7의 coefficient 추출과 같은 방향이다. 합성에서는 반대로 $$e^{+j\omega t}$$를 사용한다. 부호를 반대로 정의하는 관례도 가능하지만 forward와 inverse를 한 쌍으로 바꿔야 한다.

$$X_\omega(\omega)\ne0$$인 곳에서는

$$
X_\omega(\omega)
=\lvert X_\omega(\omega)\rvert e^{j\theta_X(\omega)}
$$

로 magnitude와 phase를 읽을 수 있다. 값이 0이면 phase는 정해지지 않는다. Spectrum은 amplitude만 보관하지 않으며, phase를 버리면 일반적으로 원래 waveform을 유일하게 복원할 수 없다.

**정의의 존재 조건과 복원 조건은 다르다.** 절대적분 가능한 $$x$$, 즉 $$\int_{-\infty}^{\infty}\lvert x(t)\rvert\,dt<\infty$$이면 위 적분은 각 $$\omega$$에서 존재한다. 그러나 이것만으로 아무 점에서나 아무 방식의 inverse 적분이 성립한다고 결론 내릴 수는 없다. 유한 에너지 $$L^2$$ 신호의 변환은 평균제곱 의미로 확장할 수 있고, 무한히 지속되는 constant나 sinusoid는 Dirac delta를 쓰는 distribution 해석이 필요하다. 따라서 원문의 “any signal”은 조건 없는 보통 적분의 존재 명제로 읽지 않는다.

### 8.3 강의 p.29: Fourier coefficient에서 연속 spectrum으로

원래 신호가 $$[-T_0/2,T_0/2]$$ 밖에서는 0이라고 하고, $$P>T_0$$를 택한다. $$[-P/2,P/2]$$의 신호를 반복해 $$x_P$$를 만든다. 고정된 유한 시간 구간은 $$P$$를 충분히 크게 잡으면 중심 복사본에 포함되므로, 그 구간에서는 $$x_P(t)=x(t)$$다.

강의의 frequency grid와 계수는 다음과 같다.

$$
\omega_0=\Delta\omega=\frac{2\pi}{P},
\qquad \omega_n=n\Delta\omega,
\qquad \Delta f=\frac{1}{P}.
$$

$$
c_n^{(P)}
=\frac{1}{P}\int_{-P/2}^{P/2}
x(t)e^{-j\omega_n t}\,dt.
$$

적분 구간 밖의 $$x$$가 0이므로 이 예에서는 적분을 실수축 전체로 넓혀도 값이 같다. 따라서 **유한한 $$P$$에서도 정확히**

$$
\boxed{
c_n^{(P)}
=\frac{1}{P}X_\omega(\omega_n)
=\frac{\Delta\omega}{2\pi}X_\omega(\omega_n)
}
$$

이다. 즉 $$X_\omega(\omega_n)=Pc_n^{(P)}$$이며, transform이 계수 $$c_n^{(P)}$$ 자체의 극한이라는 뜻은 아니다. 원래 신호가 유한 support를 갖지 않으면 먼저

$$
X_{\omega,P}(\omega)
=\int_{-P/2}^{P/2}x(t)e^{-j\omega t}\,dt
$$

를 정의해 같은 관계를 얻고, $$P\to\infty$$에서 $$X_{\omega,P}\to X_\omega$$가 성립하는 조건까지 따로 확인해야 한다.

**왜 scaling을 반드시 남겨야 하는가?** 반복 사이의 빈 구간이 길어질수록 한 주기의 평균적인 coefficient는 작아진다. 동시에 frequency grid는 촘촘해져 합성에 참여하는 항이 많아진다. 예를 들어 $$P=0.1\ \mathrm{s}$$이면 $$\Delta f=10\ \mathrm{Hz}$$, $$P=1\ \mathrm{s}$$이면 $$\Delta f=1\ \mathrm{Hz}$$다. 고정된 frequency 대역의 항 수는 약 10배가 되고, 같은 spectrum 값에 대응하는 각 coefficient는 1/10로 작아진다.

따라서 $$X_\omega$$는 **연속 spectrum의 밀도에 해당하는 값**이지, 각 frequency에서 독립적으로 존재하는 sinusoid 한 개의 peak amplitude가 아니다. 엄밀히는 inverse 측도 $$d\omega/(2\pi)$$와 결합한다. 좁은 대역의 합성 기여는

$$
\frac{1}{2\pi}X_\omega(\omega)e^{j\omega t}\Delta\omega
$$

처럼 대역폭을 곱해 계산한다. 단위도 V·s에 $$d\omega$$의 $$\mathrm{s}^{-1}$$를 곱하면 원래 V가 되어 맞는다. 이 값은 power spectral density와도 구별한다.

### 8.4 강의 p.30: 합성식에 대입하면 왜 역변환이 나오는가?

Section 7의 Fourier-series 합성에 방금 구한 계수를 대입한다. 불연속점에서는 series가 양쪽 극한의 평균으로 수렴한다는 조건을 유지한다.

$$
\begin{aligned}
x_P(t)
&=\sum_{n=-\infty}^{\infty}
c_n^{(P)}e^{j\omega_n t}\\
&=\frac{1}{2\pi}
\sum_{n=-\infty}^{\infty}
X_\omega(\omega_n)e^{j\omega_n t}\Delta\omega.
\end{aligned}
$$

두 번째 줄에서 각 항은 **함수값 × frequency 구간 폭**이다. 이것이 강의의 합에서 적분으로 넘어가는 화살표에 생략된 Riemann-sum 구조다. 유한 cutoff $$\Omega>0$$를 고정하고 $$N=\lfloor\Omega/\Delta\omega\rfloor$$로 잡으면, $$P\to\infty$$에서

$$
\frac{1}{2\pi}\sum_{n=-N}^{N}
X_\omega(\omega_n)e^{j\omega_n t}\Delta\omega
\longrightarrow
\frac{1}{2\pi}\int_{-\Omega}^{\Omega}
X_\omega(\omega)e^{j\omega t}\,d\omega.
$$

유한 frequency 구간에서는 연속인 integrand의 Riemann sum이다. 이후 $$\Omega\to\infty$$에서 신호가 복원된다는 것이 **Fourier inversion theorem**의 내용이다. 무한합과 두 극한을 조건 없이 교환해도 된다는 뜻이 아니므로, 다음 절에서 복원 부분을 별도로 확인한다.

연속점에서 사용하는 angular-frequency transform pair는

$$
\boxed{
X_\omega(\omega)=\int_{-\infty}^{\infty}
x(t)e^{-j\omega t}\,dt
}
$$

$$
\boxed{
x(t)=\frac{1}{2\pi}
\lim_{\Omega\to\infty}\int_{-\Omega}^{\Omega}
X_\omega(\omega)e^{j\omega t}\,d\omega
}
$$

이다. 일반적으로 적는 무한구간 inverse 식은 이 문맥에서 symmetric cutoff 극한을 뜻한다. $$X_\omega$$까지 절대적분 가능하면 통상적인 절대수렴 적분으로 읽을 수 있다. **$$1/(2\pi)$$는 임의의 보정이 아니라 $$1/P=\Delta\omega/(2\pi)$$에서 남은 정규화다.**

### 8.5 작성자 보충: 역변환이 원래 신호를 복원하는 이유

앞 절의 “합이 적분으로 바뀐다”만으로는 복원 증명이 끝나지 않는다. 이번 유한 support·piecewise $$C^1$$ 범위에서, cutoff inverse를 $$x_\Omega(t)$$라고 두고 forward 정의를 다시 대입하자.

$$
\begin{aligned}
x_\Omega(t)
&=\frac{1}{2\pi}\int_{-\Omega}^{\Omega}
X_\omega(\omega)e^{j\omega t}\,d\omega\\
&=\int_{-\infty}^{\infty}x(u)
\left[\frac{1}{2\pi}\int_{-\Omega}^{\Omega}
e^{j\omega(t-u)}\,d\omega\right]du.
\end{aligned}
$$

유한 $$\Omega$$와 $$x\in L^1$$에서는 이중 적분의 절댓값이 적분 가능하므로 적분 순서를 바꿀 수 있다. 대괄호는 $$v=t-u\ne0$$일 때 직접 계산된다.

$$
\begin{aligned}
K_\Omega(v)
&=\frac{1}{2\pi}
\left.\frac{e^{j\omega v}}{jv}\right|_{-\Omega}^{\Omega}\\
&=\frac{e^{j\Omega v}-e^{-j\Omega v}}{2\pi jv}
=\frac{\sin(\Omega v)}{\pi v}.
\end{aligned}
$$

$$v=0$$에서는 연속 연장으로 $$K_\Omega(0)=\Omega/\pi$$다. 따라서 inverse는 이 sinc형 kernel로 신호를 합치는 연산이다.

$$
x_\Omega(t)
=\int_{-\infty}^{\infty}
x(t-v)\frac{\sin(\Omega v)}{\pi v}\,dv.
$$

Kernel은 even이므로 양·음 시간 지연을 묶으면

$$
x_\Omega(t)
=\frac{1}{\pi}\int_0^\infty
\bigl[x(t-v)+x(t+v)\bigr]
\frac{\sin(\Omega v)}{v}\,dv.
$$

이제 복원되는 값이 보인다. $$v\to0^+$$에서 대괄호는 $$x(t^-)+x(t^+)$$로 간다. 앞의 piecewise-smooth 가정 아래에서는 작은 $$v$$ 구간에서 이 상수와의 차이가 $$O(v)$$이므로 $$v$$로 나눈 나머지도 적분 가능하다. 원점에서 떨어진 부분 역시 적분 가능한 진동항이 되어 frequency가 커질수록 기여가 0으로 간다. 이 단계는 Riemann–Lebesgue lemma 또는 조각별 적분에 대한 표준 진동적분 논증을 사용한다.

남는 상수 항에는 Dirichlet integral

$$
\int_0^\infty\frac{\sin z}{z}\,dz=\frac{\pi}{2}
$$

가 적용된다. 이 적분도 절대수렴이 아니라 improper 적분이다. 결론은

$$
\boxed{
\lim_{\Omega\to\infty}x_\Omega(t)
=\frac{x(t^-)+x(t^+)}{2}
}
$$

이다. **연속점에서는 $$x(t)$$를, jump에서는 양쪽 극한의 평균을 복원한다.** 적분은 한 점의 값만 바꾸어도 변하지 않으므로, jump에 임의로 지정한 그 한 점의 값까지 알아낼 수는 없다.

이 절은 kernel 계산과 복원 논리를 연결한 증명 개요이며, 사용한 진동적분 정리 자체를 모두 증명한 것은 아니다. 또한 sinc kernel을 보통 함수처럼 점별로 Dirac delta와 같다고 두거나, 수렴 조건 없이 무한 이중 적분의 순서를 바꾸는 증명은 사용하지 않는다.

Cutoff에서 sinc형 kernel을 얻는 직접 계산은 <a href="https://ocw.mit.edu/courses/18-103-fourier-analysis-fall-2013/d95e4644254e96ffe92a970c5ed65b0e_MIT18_103F13_fourierint1.pdf" target="_blank" rel="noopener">MIT 18.103: Fourier Integrals, p.5</a>에서도 확인할 수 있다. 해당 자료의 pp.4–6은 더 넓은 적분 가능 함수 범위에서 Fejér 가중치를 쓰는 별도의 복원 증명으로 이어진다. 이를 이번 piecewise-smooth 신호의 가중치 없는 cutoff 증명과 같은 방식이라고 혼동하지 않는다.

주기 확장의 극한 전개와 piecewise-smooth 함수의 jump 복원 조건은 <a href="https://people.tamu.edu/~f-narcowich/m414/s04w/m414w_ln14.html" target="_blank" rel="noopener">Texas A&amp;M Math 414, Lecture 14</a>와 대조했다. 그 자료는 양방향에 $$1/\sqrt{2\pi}$$를 두는 unitary convention을 사용하므로, 이 글의 forward 정의로 정규화를 환산해 비교해야 한다.

### 8.6 강의 p.31: Hz convention과 적분 변수 정정

Hz로 적은 forward 정의는

$$
X_f(f)=\int_{-\infty}^{\infty}
x(t)e^{-j2\pi ft}\,dt
=X_\omega(2\pi f)
$$

다. $$\omega=2\pi f$$를 angular-frequency inverse에 치환하면 $$d\omega=2\pi\,df$$이므로

$$
\begin{aligned}
x(t)
&=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(\omega)e^{j\omega t}\,d\omega\\
&=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(2\pi f)e^{j2\pi ft}\,2\pi\,df\\
&=\int_{-\infty}^{\infty}
X_f(f)e^{j2\pi ft}\,df.
\end{aligned}
$$

여기서도 필요하면 symmetric cutoff 극한으로 읽는다. $$1/(2\pi)$$가 사라지는 이유는 **적분 변수 변환의 Jacobian $$2\pi$$와 상쇄되기 때문**이다. Spectrum을 잘못해서 추가로 $$2\pi$$배 하는 것이 아니다.

**원본 정정 — PDF p.31 (footer 35):** Hz inverse 식의 마지막 적분 변수가 $$dt$$로 적혀 있지만, frequency를 합성해 고정된 시간 $$t$$의 값을 구하는 식이므로 올바른 변수는 $$df$$다. 화면에서 확인한 원문 오기이며 OCR 문제나 정규화 관례 차이가 아니다. 위 정정은 강의자의 공식 정정문이 아니라 작성자의 검산 결과다.

### 8.7 작성자 예제: rectangular pulse로 정의·정규화·복원을 검산하기

높이 $$B$$, 폭 $$\tau>0$$인 centered pulse를 생각하자. $$B$$는 입력 amplitude 단위, $$\tau$$는 seconds다.

$$
x(t)=
\begin{cases}
B,&\lvert t\rvert<\tau/2,\\
0,&\lvert t\rvert>\tau/2.
\end{cases}
$$

경계점 값은 transform에 영향을 주지 않는다. 정의에 직접 대입하면 $$\omega\ne0$$에서

$$
\begin{aligned}
X_\omega(\omega)
&=B\int_{-\tau/2}^{\tau/2}e^{-j\omega t}\,dt\\
&=\frac{B}{-j\omega}
\left(e^{-j\omega\tau/2}-e^{j\omega\tau/2}\right)\\
&=\frac{2B\sin(\omega\tau/2)}{\omega}\\
&=B\tau\,\operatorname{sinc}(\omega\tau/2).
\end{aligned}
$$

이 예에서는 $$\operatorname{sinc}(z)=\sin z/z$$이고 $$\operatorname{sinc}(0)=1$$로 정의한다. Library가 쓰는 normalized sinc $$\sin(\pi z)/(\pi z)$$와 섞지 않는다. $$\omega=0$$의 값은 극한 또는 원래 적분으로

$$
X_\omega(0)=\int x(t)\,dt=B\tau
$$

가 되어 pulse의 면적과 일치한다. Hz convention에서는

$$
X_f(f)=B\tau\,\operatorname{sinc}(\pi f\tau).
$$

$$B=1\ \mathrm{V}$$, $$\tau=2\ \mathrm{ms}$$라면 다음과 같이 검산한다.

| Check | 결과 | 해석 |
|---|---|---|
| $$X_f(0)$$ | $$0.002\ \mathrm{V\,s}$$ | pulse 면적; peak amplitude 1 V와 단위부터 다름 |
| $$X_f(250\ \mathrm{Hz})$$ | $$0.004/\pi\approx0.00127324\ \mathrm{V\,s}$$ | $$\pi f\tau=\pi/2$$를 직접 대입 |
| 첫 양의 zero | $$f=1/\tau=500\ \mathrm{Hz}$$ | 시간 폭이 짧을수록 첫 zero가 멀어짐 |
| angular-frequency zero | $$\omega=2\pi/\tau=1000\pi\ \mathrm{rad/s}$$ | Hz zero와 같은 위치를 다른 좌표로 표시 |
| inverse의 $$t=\pm\tau/2$$ | $$B/2=0.5\ \mathrm{V}$$ | jump에서의 평균값 복원 |

시간 중심에서도 inverse 정규화를 독립적으로 확인할 수 있다.

$$
\begin{aligned}
x(0)
&=\frac{1}{2\pi}\lim_{\Omega\to\infty}
\int_{-\Omega}^{\Omega}
\frac{2B\sin(\omega\tau/2)}{\omega}\,d\omega\\
&=\frac{2B}{\pi}\int_0^\infty\frac{\sin z}{z}\,dz
=B.
\end{aligned}
$$

마지막 치환은 $$z=\omega\tau/2$$다. $$1/(2\pi)$$를 빠뜨리면 1 V 대신 $$2\pi$$ V로 복원되므로 정규화 오류를 바로 잡을 수 있다.

이 pulse는 시간에 제한되어 있지만 spectrum은 무한 frequency까지 퍼진다. 따라서 **시간 제한과 대역 제한은 같은 조건이 아니다.** 실제 speech frame의 DFT가 유한 개의 coefficient를 내는 이유는 continuous Fourier transform의 정의가 유한해서가 아니라, Section 11에서 다루는 sampling과 유한 sample 수 때문이다.

Transform pair·spectrum 단위와 rectangular-pulse 적분은 <a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/b0a5f07216a4153e8f6160178f0ea764_lecture_04.pdf" target="_blank" rel="noopener">MIT 2.161 Lecture 4</a>의 Sections 1, 1.1–1.2 (PDF pp.2–4, printed pp.4–1–4–3)와 대조했다. 위 2 ms 수치 검산과 cutoff kernel 전개는 이 글의 보충 계산이다.

### 8.8 복습 시 연결할 결론

강의의 유도는 **Fourier-series coefficient → 주파수 간격을 분리한 spectrum → Riemann sum → inverse integral**이다. 정의 식은 분석 방법을 정하고, inversion theorem은 그 분석으로 신호를 되찾을 수 있는 조건을 설명한다. 단순한 표기 변환과 증명을 구별해서 복습해야 한다.

주기 신호는 discrete harmonic coefficient, 이번 비주기 연속시간 신호는 continuous spectrum으로 표현한다. 다음 절의 DTFS는 시간을 sampling한 **다른 단계**다. $$P\to\infty$$ 자체가 시간을 이산화하거나 DFT를 만드는 것은 아니다.

### 8.9 양방향 분석: signal에서 frequency로, frequency에서 signal로

강의 그림의 **Original signal ↔ Frequency**를 이 절에서는 **S ↔ F**라는 방향 이름으로 부른다. S는 시간 신호 $$x(t)$$, F는 주파수 표현 $$X_\omega(\omega)$$다. 여기서 F는 frequency 변수 한 개의 값이 아니라 **주파수별 complex 값을 모은 표현 전체**이며, S도 Laplace transform의 complex 변수 $$s$$가 아니다.

| Direction | 무엇을 고정하는가? | 무엇을 합치는가? |
|---|---|---|
| S → F: analysis | 분석할 frequency $$\omega$$ 하나 | 모든 시간 $$t$$에서 신호와 basis가 맞물리는 정도 |
| F → S: synthesis | 복원할 시간 $$t$$ 하나 | 모든 frequency $$\omega$$의 magnitude·phase를 반영한 기여 |

#### S → F: 신호에서 주파수 성분을 추출하기

$$
(\mathcal{F}x)(\omega)
=X_\omega(\omega)
=\int_{-\infty}^{\infty}x(t)e^{-j\omega t}\,dt.
$$

$$\mathcal{F}$$는 Fourier analysis라는 **연산자**다. 신호의 어느 한 시각을 frequency로 치환하는 함수가 아니라, 전체 시간축의 정보를 하나의 frequency coefficient로 모으는 연산이다.

왜 $$e^{-j\omega t}$$를 곱하는지는 Section 7의 유한 주기에서 가장 분명하다. $$n$$번째 성분에 $$m$$번째 basis의 conjugate를 곱하면

$$
e^{j\omega_n t}e^{-j\omega_m t}
=e^{j(\omega_n-\omega_m)t}.
$$

같은 harmonic이면 1이 되어 한 주기 동안 누적되고, 다른 harmonic이면 한 주기 적분에서 회전 성분이 상쇄된다. 이것이 **원하는 basis 방향의 coefficient를 꺼내는 projection**이다. 연속 frequency로 넘어갈 때는 Section 8.3처럼 계수의 간격 scaling을 분리한다. 무한 시간의 complex exponential을 보통의 유한 norm 벡터라고 가정하거나, 모든 비주기 입력에서 다른 frequency가 유한 시간 안에 정확히 상쇄된다고 말하는 것은 아니다.

따라서 S → F를 “크기 그래프를 만드는 과정”으로만 이해하면 부족하다. 음의 지수에 포함된 cosine·sine 비교가 **magnitude와 phase를 함께 계산**한다.

#### F → S: 주파수 성분으로 시간 신호를 합성하기

$$
(\mathcal{F}^{-1}X_\omega)(t)
=x(t)
=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(\omega)e^{j\omega t}\,d\omega.
$$

$$\mathcal{F}^{-1}$$는 synthesis 연산자다. 입력은 숫자 하나가 아니라 frequency 전체에 정의된 complex spectrum이다. 각 basis에 해당 complex weight를 곱한 뒤 모두 더해 시간 $$t$$에서의 값을 만든다. 조건부 수렴인 경우에는 Section 8.4–8.5의 symmetric cutoff 극한으로 읽는다.

**첫 번째 왕복 S → F → S**는 Section 8.5에서 이미 증명 개요를 전개했다. Forward 정의를 inverse에 넣으면 sinc형 kernel이 나오고, 이번 piecewise-smooth 조건에서 연속점의 원래 값 또는 jump 양쪽의 평균이 복원된다. 즉 조건을 명시한 의미에서

$$
\mathcal{F}^{-1}(\mathcal{F}x)=x
$$

다. 이는 정의식에 단순히 “inverse”라는 이름을 붙였기 때문에 참인 것이 아니라, kernel의 극한을 확인했기 때문에 성립하는 결과다.

#### F → S → F도 원래 spectrum으로 돌아오는가?

두 번째 왕복도 확인해야 한다. 이번 계산은 **매끄럽고 함수와 모든 도함수가 다항식의 역수보다 빠르게 감소하는 spectrum**을 가정한다. 이런 함수의 모임을 Schwartz class라고 하며 Gaussian이 대표적인 예다. 이 충분조건에서는 forward/inverse를 모두 통상적인 적분으로 다룰 수 있다. Rectangular pulse의 느리게 감소하는 spectrum은 이 추가 가정에 포함되지 않으며, 그 예에는 앞 절의 cutoff 해석을 사용한다.

합성한 신호를 다시 분석하되, 먼저 시간 적분을 $$[-R,R]$$로 제한하자. $$R>0$$은 관측 반구간 길이 [s], $$\nu$$는 다시 확인하려는 angular frequency [rad/s], $$Y_R(\nu)$$는 이 유한 시간 분석 결과 [입력 단위 × s]다.

$$
\begin{aligned}
Y_R(\nu)
&=\int_{-R}^{R}x(t)e^{-j\nu t}\,dt\\
&=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(\omega)
\left[\int_{-R}^{R}e^{j(\omega-\nu)t}\,dt\right]d\omega\\
&=\int_{-\infty}^{\infty}X_\omega(\omega)
\frac{\sin\!\left(R(\omega-\nu)\right)}
{\pi(\omega-\nu)}\,d\omega.
\end{aligned}
$$

두 번째 줄은 유한 $$R$$와 절대적분 가능한 spectrum 때문에 적분 순서를 바꿀 수 있다. 세 번째 줄은 exponential을 시간에 대해 직접 적분한 결과이며, $$\omega=\nu$$에서는 분수의 연속 극한이 $$R/\pi$$다.

이번에는 **frequency 축에서 $$\nu$$ 주변을 모으는 sinc형 kernel**이 생겼다. Section 8.5의 시간축 복원 논리를 frequency 축에 적용하면, 매끄러운 $$X_\omega$$에 대해

$$
\lim_{R\to\infty}Y_R(\nu)=X_\omega(\nu)
$$

가 된다. 따라서 이 조건에서는

$$
\boxed{
\mathcal{F}\bigl(\mathcal{F}^{-1}X_\omega\bigr)
=X_\omega
}
$$

도 성립한다. 정리하면 **S → F → S에서는 시간축 kernel이 신호를 되찾고, F → S → F에서는 frequency 축 kernel이 spectrum을 되찾는다.** 시간과 frequency가 맡는 역할이 서로 바뀌지만 정규화와 conjugate 부호는 일관된다. Schwartz class에서의 역변환 조건은 <a href="https://ocw.mit.edu/courses/18-103-fourier-analysis-fall-2013/d95e4644254e96ffe92a970c5ed65b0e_MIT18_103F13_fourierint1.pdf" target="_blank" rel="noopener">MIT 18.103: Fourier Integrals, Theorem 1</a>과도 대조할 수 있다.

#### 왕복 과정에서 보존해야 하는 정보

이 왕복은 **중간 spectrum을 바꾸지 않을 때**의 이야기다. Magnitude만 남기거나, phase를 0으로 만들거나, 일부 frequency를 제거하면 다른 신호를 합성하는 연산이 된다. Fourier 변환 자체가 정보를 버린 것이 아니라 중간 처리가 정보를 바꾼 것이다.

실수 음성을 합성하려면 양·음 frequency도 맞아야 한다. $$X_\omega(-\omega)=X_\omega(\omega)^*$$라는 conjugate symmetry가 있으면

$$
\begin{aligned}
x(t)^*
&=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(\omega)^*e^{-j\omega t}\,d\omega\\
&=\frac{1}{2\pi}\int_{-\infty}^{\infty}
X_\omega(-\nu)^*e^{j\nu t}\,d\nu
=x(t).
\end{aligned}
$$

두 번째 줄은 $$\nu=-\omega$$ 치환이다. 따라서 복원 신호가 실수가 된다. 임의의 complex spectrum을 넣으면 complex 신호가 나올 수 있으며, 이는 역변환의 오류가 아니다.

Section 8.7의 예에 적용하면 **1 V·2 ms pulse → 0 Hz 값이 0.002 V·s인 sinc spectrum → 원래 pulse**라는 왕복이다. 이 0 Hz 값은 시간 신호의 면적이며 spectrum의 면적을 뜻하지 않는다. Fourier transform을 새로운 음성을 생성하는 과정이나 단순한 단위 변환으로 보지 않고, **같은 정보를 다른 basis에서 분석하고 다시 합성하는 과정**으로 이해하면 phase·정규화·양음 frequency의 필요성이 함께 연결된다.

## 9. Discrete-Time Fourier Series

> **CTFS → DTFS가 가능한 이유:** 주기 신호를 한 주기당 정수 개의 간격으로 sampling하면 표본열도 주기적이다. 이 표본 위치에서는 harmonic index가 $$N$$만큼 다른 exponential들이 같은 값을 가지므로, 무한한 CTFS 항을 **서로 다른 $$N$$개 basis와 그 계수**로 묶을 수 있다. DTFS가 표본을 정확히 표현한다는 사실과, 그 표본으로 원래 연속 신호를 복원할 수 있다는 사실은 별개다.

원본 PDF pp.32–36 (footer 36–40)은 CTFS의 sampling, basis 반복, 계수의 aliasing 합과 Riemann-sum 비교를 차례로 보여 준다. PDF p.39 (footer 43)는 Nyquist 조건과 유한 녹음의 주기 확장을 연결한다. 아래는 이 흐름에서 생략된 조건·증명과 작성자의 검산을 보강한 설명이다.

### 9.1 Sampling이 시간 주기성을 유지하는 조건

목적은 연속적인 한 주기를 $$N$$개의 값으로 관측하고, 그 값들을 컴퓨터에서 계산 가능한 frequency coefficient로 표현하는 것이다. **시간축을 sampling하는 것**이지, Section 8처럼 주기 $$P$$를 무한히 늘리는 과정이 아니다. CTFS의 harmonic index는 sampling 전부터 이미 이산적이다.

강의와 같이 $$x(t+P)=x(t)$$인 신호에 대해

$$
T=\frac{P}{N},\qquad N\in\mathbb{Z}_{>0},
\qquad x[n]:=x(nT)
$$

로 정의한다. 그러면

$$
x[n+N]=x((n+N)T)
=x(nT+NT)=x(nT+P)=x(nT)=x[n].
$$

따라서 $$N$$은 표본열의 한 주기다. 더 짧은 주기가 존재할 수 있으므로 항상 **최소 주기**라는 뜻은 아니다.

| Symbol | 의미 | 단위 |
|---|---|---|
| $$t,P,T$$ | 연속 시간, 신호 주기, sample 사이의 시간 간격 | s |
| $$N,n,m,k,\ell,r$$ | 주기당 표본 수와 정수 index | 무차원; $$N>0$$ |
| $$f_s=1/T$$ | sampling rate | Hz, samples/s |
| $$\omega_0=2\pi/P$$ | 연속시간 기본 angular frequency | rad/s |
| $$\Omega_\ell=\ell\omega_0T$$ | 표본당 phase 증가량 | rad/sample |
| $$c_\ell,d_k$$ | CTFS 계수, DTFS 계수 | 입력 amplitude와 동일; 예: V |

**주기적인 연속 신호를 아무 간격으로 sampling해도 표본열이 주기적인 것은 아니다.** 일반적으로 $$T/P=a/b$$가 서로소 양의 정수 $$a,b$$의 비이면 $$bT=aP$$이므로 $$x[n+b]=x[n]$$다. 강의의 $$T/P=1/N$$은 그중 한 연속 주기에 정확히 $$N$$개 표본이 대응하는 경우다. 일반적인 $$a/b$$에서는 harmonic index가 $$a\ell\bmod b$$로 대응하므로 아래의 $$k+rN$$ 식을 그대로 쓰지 않는다. 무리수 비의 반례로 $$T/P=\sqrt{2}$$일 때 $$e^{j2\pi t/P}$$의 표본은 $$e^{j2\pi\sqrt{2}n}$$이며, 주기 $$M>0$$가 있으려면 $$M\sqrt{2}$$가 정수여야 하므로 불가능하다.

### 9.2 CTFS에 sampling 시각을 대입하면 무엇이 바뀌는가?

이제 CTFS가 실제 sample 위치의 신호값을 나타낸다고 가정하자. 예를 들어 **유한한 harmonic 합으로 이루어진 신호**, 또는 절대합 가능한 계수의 급수로 정의된 연속 주기 신호이면 아래 대입·재배열이 정당하다. 임의의 $$L^2$$ 등식만으로는 특정 점의 값까지 정해지지 않으므로 그대로 sampling했다고 주장하지 않는다.

$$
\begin{aligned}
x(t)&=\sum_{\ell=-\infty}^{\infty}c_\ell e^{j\ell\omega_0t},\\
x[n]&=\sum_{\ell=-\infty}^{\infty}c_\ell e^{j\ell\omega_0nT}\\
&=\sum_{\ell=-\infty}^{\infty}c_\ell
e^{j2\pi\ell n/N}.
\end{aligned}
$$

마지막 줄은 $$\omega_0T=(2\pi/P)(P/N)=2\pi/N$$를 대입한 **정확한 등식**이다. $$c_\ell$$가 아직 DTFS 계수로 바뀐 것은 아니다. 같은 basis를 만드는 항들을 묶는 단계가 남아 있다.

정수 $$n,r$$에 대해

$$
e^{j2\pi(\ell+rN)n/N}
=e^{j2\pi\ell n/N}e^{j2\pi rn}
=e^{j2\pi\ell n/N}.
$$

연속시간에서는 $$e^{j2\pi rNt/P}$$가 모든 $$t$$에서 1인 것은 아니지만, sample 위치 $$t=nP/N$$에서는 1이다. **표본 사이에서 달랐던 파형을 표본값만으로는 구별하지 못하게 되는 것**이다. 따라서 서로 다른 basis는 $$k=0,\ldots,N-1$$의 $$N$$개로 대표할 수 있다.

### 9.3 왜 모든 N-periodic 표본열을 정확히 표현하는가?

한 주기의 표본열은 $$N$$개의 complex 수로 이루어진 벡터다. $$\phi_k[n]=e^{j2\pi kn/N}$$라고 하면 한 주기에서

$$
\sum_{n=0}^{N-1}\phi_k[n]\phi_m[n]^*
=\sum_{n=0}^{N-1}e^{j2\pi(k-m)n/N}
=\begin{cases}
N,&k\equiv m\pmod N,\\
0,&k\not\equiv m\pmod N.
\end{cases}
$$

다른 나머지일 때 공비 $$q=e^{j2\pi(k-m)/N}\ne1$$인 geometric series를 계산하면

$$
\sum_{n=0}^{N-1}q^n
=\frac{1-q^N}{1-q}=0,
\qquad q^N=e^{j2\pi(k-m)}=1
$$

이기 때문이다. 같은 나머지이면 $$N$$개 항이 모두 1이다.

따라서 이 $$N$$개 벡터는 서로 직교하고 0이 아니므로 독립이며, $$N$$차원 공간 전체의 basis가 된다. **원래 신호가 band-limited인지와 관계없이 모든 N-periodic 표본열에 DTFS가 존재한다.** CTFS에서 얻지 않은 표본열도 마찬가지다.

Synthesis 식에 $$\phi_m[n]^*$$를 곱하고 한 주기에서 합하면 $$m$$번째 항만 $$Nd_m$$으로 남는다. 이로부터 analysis와 synthesis는

$$
\boxed{d_k=\frac{1}{N}\sum_{n=0}^{N-1}
x[n]e^{-j2\pi kn/N}}
$$

$$
\boxed{x[n]=\sum_{k=0}^{N-1}d_k e^{j2\pi kn/N}}
$$

가 된다. $$1/N$$은 basis의 제곱 norm $$N$$으로 나누는 정규화다. 적분을 근사해서 얻어야만 성립하는 계수가 아니다. 표본의 복원은 Section 11.1의 유한 이중합 검산으로도 확인할 수 있다. 유한 basis와 계수의 주기성은 <a href="https://ocw.mit.edu/courses/res-6-007-signals-and-systems-spring-2011/cf3874410d609d71d6036e7572525222_MITRES_6_007S11_lec10.pdf" target="_blank" rel="noopener">MIT Signals and Systems, Lecture 10, PDF pp.1–2</a>와 대조했다.

### 9.4 CTFS coefficient가 DTFS coefficient로 합쳐지는 과정

Section 9.2의 수렴 조건 아래 모든 정수 $$\ell$$을 유일하게 $$\ell=k+rN$$, $$0\le k<N$$로 분해한다. 같은 나머지의 항을 묶으면

$$
\begin{aligned}
x[n]
&=\sum_{k=0}^{N-1}\sum_{r=-\infty}^{\infty}
c_{k+rN}e^{j2\pi(k+rN)n/N}\\
&=\sum_{k=0}^{N-1}
\left(\sum_{r=-\infty}^{\infty}c_{k+rN}\right)
e^{j2\pi kn/N}.
\end{aligned}
$$

방금 증명한 DTFS 계수의 유일성 때문에

$$
\boxed{d_k=\sum_{r=-\infty}^{\infty}c_{k+rN}}
$$

이다. 무한합의 순서를 바꾸는 충분조건으로 $$\sum_\ell\lvert c_\ell\rvert<\infty$$를 사용했다. CTFS가 조건부로만 수렴하거나 sample이 jump에 놓인 경우에는 급수의 수렴값과 실제 지정한 표본값부터 확인해야 하며, 이 재배열을 무조건 적용하지 않는다. 반면 유한 표본열 자체의 DTFS 계산에는 이런 무한급수 조건이 필요 없다.

물리적인 frequency 차이는 $$rN/P=rf_s$$이고, 표본당 phase 차이는 $$2\pi r$$다. 즉 sample rate의 정수배만큼 떨어진 성분들이 하나의 계수에 **complex 값으로 더해진다**. Magnitude끼리만 합치는 것이 아니며 phase에 따라 상쇄될 수도 있다.

같은 재배열 유도는 <a href="https://ocw.mit.edu/courses/hst-582j-biomedical-signal-and-image-processing-spring-2007/c8dc8096a9d75f8f30b4b97354b48437_ch1_adc.pdf" target="_blank" rel="noopener">MIT HST.582J, Section 1.A.2.3, equations 1.A.21–1.A.26 (PDF p.16, printed p.15)</a>에서도 확인할 수 있다. 해당 절은 홀수 $$N$$의 centered index를 쓰며, 이 글은 짝수·홀수에 모두 쓸 수 있는 $$0,\ldots,N-1$$ 대표 index를 사용했다.

### 9.5 강의의 Riemann sum: 어떤 등호만 근사인가?

원본 PDF p.35 (footer 39)는 CTFS 적분을 직사각형 합으로 **근사**한 뒤 DTFS 식과 연결한다. 비교할 integrand를 $$g_k(t)=x(t)e^{-j2\pi kt/P}$$라고 두면

$$
\begin{aligned}
c_k
&=\frac{1}{P}\int_0^P g_k(t)\,dt\\
&\approx\frac{T}{P}\sum_{n=0}^{N-1}g_k(nT)\\
&=\frac{1}{N}\sum_{n=0}^{N-1}x[n]e^{-j2\pi kn/N}
=d_k.
\end{aligned}
$$

**근사인 것은 적분을 유한 합으로 바꾼 줄뿐이다.** $$T/P=1/N$$와 마지막 DTFS 정의는 정확하다. 고정된 $$k,P$$에 대해 $$g_k$$가 Riemann 적분 가능하고 $$N\to\infty$$, $$T=P/N\to0$$이면 근사 합이 적분으로 수렴한다. 특정 유한 $$N$$에서 오차가 작다는 보장과는 다르다.

앞 절의 더 강한 급수 조건이 성립하면 이 오차를 정확히

$$
d_k-c_k=\sum_{r\ne0}c_{k+rN},
\qquad
\lvert d_k-c_k\rvert
\le\sum_{r\ne0}\lvert c_{k+rN}\rvert
$$

로 읽을 수 있다. Alias가 없으면 적분 근사가 우연히 좋아서가 아니라 **다른 harmonic이 같은 basis에 들어오지 않아서** 계수가 정확히 일치한다. Alias가 있어도 DTFS 자체는 표본열을 정확히 표현한다.

### 9.6 DTFS 존재와 원래 연속 신호의 복원은 다른 조건이다

CTFS가 $$\lvert\ell\rvert\le K$$에서만 nonzero인 low-pass band-limited 신호이고 $$N>2K$$이면 이 범위의 index들이 서로 다른 나머지를 갖는다. 이 조건의 증명과 $$f_s>2f_{\max}$$와의 관계는 Section 10.1에서 이어진다.

여기서 강의의 $$d_k=c_k$$는 index 범위를 붙여 읽어야 한다. $$d$$를 $$d_{k+N}=d_k$$로 주기 확장하고, $$[\ell]_N$$을 $$0,\ldots,N-1$$ 안의 나머지라고 정의하면 원래 대역 안에서

$$
d_{[\ell]_N}=c_\ell,\qquad -K\le\ell\le K
$$

가 정확하다. 예를 들어 $$N=8$$에서 음의 harmonic $$\ell=-1$$은 $$d_7$$에 들어간다. 이때 $$d_7=c_{-1}$$이지, 반드시 $$d_7=c_7$$인 것은 아니다. **DTFS의 계수는 N주기지만 원래 CTFS 계수가 N주기라는 뜻은 아니다.**

원본 PDF p.39 (footer 43)의 축약된 $$d_k=c_k$$는 이렇게 원래 대역의 signed index 또는 그에 대응하는 bin으로 해석한다. 이를 $$0,\ldots,N-1$$의 모든 raw index에 조건 없이 적용하지 않는다. 짝수 $$N$$에서 $$+N/2$$와 $$-N/2$$도 같은 bin이므로 strict Nyquist 조건에서 경계를 제외한다.

### 9.7 8개 표본으로 직접 검산하기

작성자 예제로 $$P=1\ \mathrm{ms}$$, $$N=8$$, $$T=0.125\ \mathrm{ms}$$, $$f_s=8\ \mathrm{kHz}$$를 사용하자. 시간 $$t$$는 seconds, 진폭 단위는 V다.

$$
x(t)=\cos(2\pi\,1000t),\qquad
x[n]=\cos(2\pi n/8).
$$

Euler formula로 $$c_1=c_{-1}=1/2$$, 나머지는 0이다. 따라서 $$d_1=d_7=1/2$$이고

$$
x[n]=\tfrac12 e^{j2\pi n/8}
+\tfrac12 e^{j2\pi7n/8}
=\cos(2\pi n/8).
$$

이는 $$N=8>2K=2$$인 alias-free 예다. 원래 1 kHz low-pass 성분을 구별할 수 있다.

같은 신호에 7 kHz 성분을 더하면

$$
y(t)=\cos(2\pi\,1000t)
+0.4\cos(2\pi\,7000t).
$$

원래 CTFS에는 $$c_{\pm1}=0.5$$, $$c_{\pm7}=0.2$$가 있다. 표본에서는 $$7\equiv-1\pmod8$$, $$-7\equiv1\pmod8$$이므로

$$
d_1=c_1+c_{-7}=0.7,\qquad
d_7=c_{-1}+c_7=0.7.
$$

다른 계수는 0이고, DTFS가 복원하는 표본은 정확히

$$
y[n]=0.7e^{j2\pi n/8}+0.7e^{-j2\pi n/8}
=1.4\cos(2\pi n/8)
$$

이다. 원래 두 주파수의 혼합과 1 kHz·1.4 V 단일 cosine은 **모든 sample에서 같지만 연속시간 신호로는 다르다.** 따라서 “DTFS 역합으로 sample이 정확히 복원됐다”는 검사만으로 aliasing이 없었다고 결론 내릴 수 없다.

정리하면 **CTFS의 sampling → 표본열의 주기성 → basis의 modulo-N 동일성 → DTFS의 정확한 계수**가 변환을 가능하게 한다. Nyquist 조건은 그다음에 원래 harmonic들을 구별하기 위한 조건이다. 실제 녹음의 유한 $$N$$개 표본이 본래 주기적이지 않더라도, 이를 한 주기로 확장하면 Section 11의 DFT를 적용할 수 있다. 이때 주기성은 원래 녹음의 성질이 아니라 분석 모델이다.

## 10. Nyquist sampling과 aliasing

> **“is not satisfied”의 의미:** DTFS 계산에 실패했다는 말이 아니라, **표본만으로 원래 연속시간의 frequency를 구별할 조건이 충족되지 않았다**는 뜻이다. 강의의 7 kHz 신호를 8 kHz로 sampling한 경우에는 $$8<2\times7=14$$이므로 조건을 위반한다. 그 결과 7 kHz와 1 kHz cosine이 같은 표본을 만든다.

원본 PDF p.36 (footer 40)은 Nyquist 부등식을 제시하고, pp.37–38 (footers 41–42)은 **“What if the Nyquist sampling condition is not satisfied?”**라고 묻는다. p.37은 0과 $$\pm f_s$$를 중심으로 반복되는 spectrum을, p.38은 1 kHz·7 kHz cosine의 8 kHz sampling과 이미지 moire를 보여 준다. 아래의 중간 계산·경계 반례·해결 방법은 이 화면을 이해하기 위한 작성자 보강이다. p.37 그림만으로 최고 frequency의 수치를 추정하지 않고, 수치 검산에는 p.38에 명시된 값을 사용한다.

| Symbol | 의미 | 단위 |
|---|---|---|
| $$P,T,N$$ | 연속 주기, sample 간격, 한 주기의 표본 수; $$P=NT$$ | s, s, 무차원 |
| $$K,f_{\max}=K/P$$ | 최고 nonzero harmonic index와 그 frequency | 무차원, Hz |
| $$f_s=1/T$$ | sampling rate | Hz, samples/s |
| $$f_s/2$$ | 주어진 sample rate의 **Nyquist frequency** | Hz |
| $$2f_{\max}$$ | 주어진 low-pass 신호의 **Nyquist rate** | Hz |
| $$f_a$$ | 표본과 같은 discrete basis를 갖는 대표 alias frequency | Hz |

**Nyquist frequency와 Nyquist rate를 바꿔 읽지 않는다.** 8 kHz sampling의 Nyquist frequency는 4 kHz이고, 7 kHz 성분까지 보존하려는 신호의 Nyquist rate는 14 kHz다. 여기서는 강의처럼 경계의 sinusoid까지 구별하기 위해 strict inequality를 사용한다.

### 10.1 작성자 보충: Nyquist 부등식의 유도와 경계

CTFS가 $$\lvert k\rvert\le K$$에서만 nonzero인 band-limited periodic signal이라고 하자. Sampling 뒤에는 $$k$$와 $$k+rN$$이 같은 discrete basis가 된다. 대역 안의 임의의 서로 다른 두 index $$k_1,k_2$$는 $$N>2K$$일 때

$$
0<\lvert k_1-k_2\rvert\le2K<N
$$

을 만족하므로 차이가 $$N$$의 0이 아닌 정수배가 될 수 없다. 따라서 모든 index가 서로 다른 나머지로 남고 aliasing이 없다. 반대로 $$-K,\ldots,K$$의 **모든 계수를 제한 없이 구분하려면** $$2K+1$$개 index를 담을 최소 $$N\ge2K+1$$개의 나머지가 필요하다. $$N,K$$가 정수이므로 이는 $$N>2K$$와 같다. 알려진 sparse band 구조 등 추가 정보를 사용하는 별도 복원 문제까지 이 조건이 항상 필요하다는 뜻은 아니다.

또한 $$f_{\max}=K/P$$, $$f_s=1/T=N/P$$이므로

$$
N>2K
\quad\Longleftrightarrow\quad
\frac{N}{P}>2\frac{K}{P}
\quad\Longleftrightarrow\quad
\boxed{f_s>2f_{\max}}.
$$

이 조건은 원래 신호가 해당 low-pass 대역에 있다는 가정 아래 harmonic들을 구별하게 한다. “어떤 frequency의 신호도 표본만으로 알아낸다”는 조건이 아니다.

Nyquist 조건과 alias frequency의 주기성은 <a href="https://ocw.mit.edu/courses/hst-582j-biomedical-signal-and-image-processing-spring-2007/c8dc8096a9d75f8f30b4b97354b48437_ch1_adc.pdf" target="_blank" rel="noopener">MIT HST.582J, Analog-to-Digital Conversion, PDF pp.3–5</a>의 대역 제한·sampling theorem 및 aliasing 설명과 대조했다.

#### p.37의 spectrum 그림은 왜 겹칠 수 있는가?

Sampling한 exponential에서는 정수 $$r,n$$에 대해

$$
e^{j2\pi(f+rf_s)n/f_s}
=e^{j2\pi fn/f_s}e^{j2\pi rn}
=e^{j2\pi fn/f_s}
$$

이므로 frequency가 $$f_s$$만큼 달라도 같은 basis다. 이것이 p.37에서 spectrum의 복사본이 $$f_s$$ 간격으로 반복되는 이유다. 원래 대역의 바깥 경계가 $$[-f_{\max},f_{\max}]$$라면 오른쪽 복사본의 경계는 $$[f_s-f_{\max},f_s+f_{\max}]$$다. 두 대역 사이에 간격이 있으려면

$$
f_{\max}<f_s-f_{\max}
\quad\Longleftrightarrow\quad f_s>2f_{\max}
$$

여야 한다. $$f_s<2f_{\max}$$이면 이 대역 구간들이 겹쳐, 같은 표본 frequency에 서로 다른 연속시간 성분이 들어올 수 있다. 주기 신호의 경우 이 겹침은 Section 9.4의 $$d_k=\sum_r c_{k+rN}$$라는 **complex 계수의 합**으로 나타난다. 그림의 magnitude 높이만 더하는 과정으로 이해하면 phase 상쇄를 놓친다.

대역의 경계 구간이 겹친다는 사실이 모든 sparse 신호에서 nonzero 성분이 반드시 충돌한다는 뜻은 아니다. 핵심은 **그 대역 안의 임의의 신호를 추가 정보 없이 유일하게 복원한다는 보장이 사라진다**는 것이다.

#### 왜 등호에서는 주의해야 하는가?

$$f_s=2f_{\max}$$라면 최고 frequency는 표본 사이에서 정확히 반 바퀴씩 진행한다. 진폭 $$A$$, phase $$\phi$$인 sinusoid를 sampling하면

$$
\begin{aligned}
x(t)&=A\cos(2\pi(f_s/2)t+\phi),\\
x[n]&=A\cos(\pi n+\phi)
=A(-1)^n\cos\phi.
\end{aligned}
$$

$$\sin(\pi n)=0$$이므로 sine 방향의 성분이 사라진다. 특히 $$\phi=\pi/2$$이면 **연속시간에서는 0이 아닌 신호인데 모든 표본이 0**이다. $$A$$와 $$\phi$$도 표본에 남은 곱 $$A\cos\phi$$만으로 각각 결정할 수 없다. CTFS 관점에서는 $$+N/2$$와 $$-N/2$$가 같은 bin이 되는 경계 충돌이다.

이 반례 때문에 임의 phase의 경계 sinusoid를 포함하는 이 글의 신호 범위에서는 strict inequality를 쓴다. 다른 교재의 등호 허용 여부는 대역 경계에 성분이 없는지, 어떤 함수 공간·복원 의미를 쓰는지 등 가정과 함께 비교해야 한다.

### 10.2 p.38: 1 kHz는 조건을 만족하고 7 kHz는 왜 만족하지 않는가?

슬라이드 p.38 (footer 42)의 위·아래 그래프는 **서로 다른 두 analog cosine**을 각각 8 kHz로 sampling한 비교다. Section 9.7에서 작성자가 두 성분을 더한 혼합 신호와 구분한다. 시간 $$t$$의 단위는 s이며 아래 식은 그래프처럼 정규화된 unit amplitude와 zero phase를 사용한다.

| Signal | 조건에 대입 | 한 주기의 평균 sample 수 | 판정 |
|---|---|---|---|
| 1 kHz cosine | $$8>2\times1$$, kHz 기준 | $$f_s/f=8$$ | 이 low-pass 대역에서는 만족 |
| 7 kHz cosine | $$8<2\times7=14$$, kHz 기준 | $$f_s/f=8/7\approx1.14$$ | 만족하지 않음 |

**“8 kHz가 7 kHz보다 큰데 왜 부족한가?”** 비교 대상은 $$f_{\max}$$가 아니라 $$2f_{\max}$$다. 7 kHz의 주기는 약 $$142.86\ \mu\mathrm{s}$$인데 sample 간격은 $$125\ \mu\mathrm{s}$$다. 한 주기에서 약 1.14번만 관측하므로 빠른 회전과 반대 방향의 느린 회전이 같은 위치에 잡힌다. “주기당 두 표본보다 많아야 한다”는 말의 정확한 근거는 앞 절의 basis 충돌과 아래 등식이지, 점 몇 개를 선으로 연결하는 직관만은 아니다.

#### 동일한 표본이 되는 것을 식으로 증명하기

$$t_n=n/8000$$에서 두 표본열은

$$
\begin{aligned}
x_1[n]
&=\cos(2\pi\cdot1000\,n/8000)
=\cos(\pi n/4),\\
x_7[n]
&=\cos(2\pi\cdot7000\,n/8000)\\
&=\cos(2\pi n-\pi n/4)
=\cos(\pi n/4)
=x_1[n].
\end{aligned}
$$

마지막 두 등호는 정수 $$n$$에 대한 $$2\pi$$ 주기성과 cosine의 짝대칭성에서 나온 **정확한 등식**이다. Complex exponential에서는 7 kHz가 먼저 **−1 kHz**에 대응한다.

$$
e^{j2\pi(7000)n/8000}
=e^{-j2\pi(1000)n/8000}.
$$

실수 zero-phase cosine은 양·음 frequency 쌍이므로 결과가 +1 kHz cosine과 같다. 일반 phase에서는 부호까지 따라가야 한다.

$$
\cos(2\pi\cdot7000\,n/8000+\phi)
=\cos(2\pi\cdot1000\,n/8000-\phi).
$$

따라서 “어떤 phase의 7 kHz 신호든 같은 phase의 1 kHz 신호가 된다”라고 쓰면 틀린다. Sine 성분에서는 부호 반전도 생길 수 있다.

일반적으로 정수 $$r$$을 골라

$$
f_a=f-rf_s,\qquad -f_s/2\le f_a<f_s/2
$$

에 놓으면 같은 표본 basis의 대표 frequency를 얻는다. 여기서는 $$f_a=7000-8000=-1000\ \mathrm{Hz}$$다. 실수 cosine의 양의 frequency 표시는 $$\lvert f_a\rvert=1000\ \mathrm{Hz}$$이며, 복원할 때는 phase도 함께 바꿔야 한다.

#### 표본은 맞는데 원래 소리는 왜 복원할 수 없는가?

처음 다섯 표본은 두 신호 모두

$$
1,\quad \frac{\sqrt2}{2},\quad 0,\quad
-\frac{\sqrt2}{2},\quad -1
$$

이다. 반면 sample 사이인 $$t=1/16000\ \mathrm{s}$$에서는

$$
x_1(t)=\cos(\pi/8)\approx0.9239,\qquad
x_7(t)=\cos(7\pi/8)\approx-0.9239
$$

로 서로 다르다. **표본값을 정확히 맞춘다는 사실은 표본 사이의 원래 파형까지 맞췄다는 증거가 아니다.** 관측값만 받은 알고리즘은 두 입력을 구별할 수 없다. 4 kHz 미만의 원 신호라는 low-pass 가정을 사용하면 1 kHz로 해석하지만, 실제 입력이 7 kHz였다면 그 가정이 깨진 것이다. 슬라이드 오른쪽의 연결선도 두 표본열이 같다는 시각화이지 7 kHz 원파형 복원의 증명이 아니다.

### 10.3 p.38: Spatial aliasing과 moire pattern

슬라이드 아래의 줄무늬·건물 사진은 같은 현상의 공간축 예다. 수평 방향으로만 변하는 밝기 pattern을 $$I(u)=I_0+B\cos(2\pi\nu u)$$라고 하자. $$u$$는 mm, $$\nu$$는 cycles/mm, $$\Delta u$$는 pixel 간격(mm/pixel)이며 $$I_0,B$$는 동일한 밝기 단위다. 공간 sampling rate를 $$\nu_s=1/\Delta u$$ (pixels/mm)라고 하면

$$
I[m]=I_0+B\cos(2\pi\nu m/\nu_s).
$$

$$\nu$$와 $$\nu+r\nu_s$$는 동일한 표본 basis를 만든다. 시간축의 $$f_s>2f_{\max}$$에 대응하는 조건은 이 1차원 방향에서 $$\nu_s>2\nu_{\max}$$다. 실제 2차원 영상은 두 축의 공간 frequency와 pixel 격자를 함께 확인해야 한다.

촘촘한 원무늬가 이 조건을 벗어나면 더 느린 밝기 변화로 접혀 **원래 장면에는 없던 넓은 줄무늬, 즉 moire**처럼 보일 수 있다. 사진의 정확한 pixel 간격이나 무늬 frequency는 슬라이드에 주어지지 않았으므로 수치 위반량까지 단정하지 않는다. 이 식은 현상을 설명하는 단순화된 작성자 모델이다.

### 10.4 조건을 만족시키려면 무엇을 바꿔야 하는가?

보존할 신호와 관측 장치 중 무엇을 바꿀 것인지 나눠 생각한다.

1. **7 kHz 성분까지 보존하려면 sampling rate를 높인다.** 이 예에서는 이상적인 조건으로 14 kHz를 넘어야 한다. 예를 들어 16 kHz이면 7 kHz가 Nyquist frequency 8 kHz 안에 들어간다. 실제 rate는 filter의 transition band와 필요한 감쇠량까지 확인해 정한다.
2. **8 kHz를 유지한다면 ADC 전에 대역을 제한한다.** Analog anti-aliasing low-pass filter로 4 kHz 경계 이전에 transition을 확보하고, alias를 유발할 대역 밖 성분을 충분히 감쇠한다. 이 경우 보존하는 대상은 **필터를 거친 신호**이며, 7 kHz 원성분을 보존한 것이 아니다. 비이상적 필터에서는 잔여 alias 오차를 허용 수준으로 관리한다.
3. **이미 8 kHz로 취득한 표본을 단순히 늘려도 잃은 구분은 돌아오지 않는다.** 보간·zero-padding·FFT 크기 증가·사후 digital low-pass filtering은 같은 입력 표본을 받으므로 원래 1 kHz인지 7 kHz인지 판별할 수 없다. 반면 더 높은 rate의 기존 digital signal을 낮출 때는 **downsampling 전에 digital low-pass filter**를 적용할 수 있다.
4. **이미지도 낮은 해상도로 줄이기 전에 filter를 적용한다.** 시간축 downsampling과 같은 원리다. 촬영 단계에서 이미 발생한 moire와 후속 resize 과정에서 새로 생기는 aliasing은 구분해야 한다.

이것은 amplitude 단계 수를 늘리는 **quantization**이나 유한 분석 구간의 **spectral leakage**와 다른 문제다. Aliasing은 sampling에서 frequency 구분이 사라지는 것이므로, bit depth를 늘리거나 window만 바꾸는 방법으로 해결하지 않는다.

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
| Harmonics and formants | voiced excitation의 반복률과 vocal tract의 공명을 구분한다. |
| DFT | 짧은 frame의 spectrum을 계산한다. |
| Nyquist condition | 보존 가능한 frequency band를 결정한다. |
| Aliasing | 복구 불가능한 frequency ambiguity를 설명한다. |

Speech는 시간에 따라 빠르게 변하므로 전체 utterance에 한 번만 DFT를 적용하면 변화 시점을 잃는다. 일반적인 다음 단계는 waveform을 짧은 overlapping frame으로 나누고 각 frame에 window와 DFT를 적용하는 것이다. 이 과정이 spectrogram과 STFT로 이어진다.

## 마지막 핵심 정리

1. **Digitization은 두 단계다.** Sampling은 시간을, quantization은 amplitude를 이산화한다.
2. **PCM bit rate는 $$b f_s C$$다.** 더 높은 precision과 더 많은 channel은 저장량을 증가시킨다.
3. **Fourier analysis는 basis change다.** Time-domain signal을 frequency-domain component로 분해한다.
4. **Fourier series의 discrete 계수는 주파수 간격을 분리하면 continuous spectrum으로 이어진다.** Section 8의 관계 $$c_n^{(P)}=X_\omega(\omega_n)/P$$가 inverse의 정규화를 결정한다. 주기 신호의 보통 Fourier series와 비주기 신호의 transform을 먼저 구별하며, 일반화된 변환에는 별도의 수렴·distribution 해석이 필요하다.
5. **CTFS를 sampling하면 modulo-N으로 같은 basis의 계수들이 합쳐져 DTFS가 된다.** DTFS는 표본열을 정확히 표현하지만, 원래 연속 신호까지 구별하려면 별도의 alias-free 조건이 필요하다.
6. **Nyquist condition은 구분 가능성의 조건이다.** 위반 후에는 sample만으로 원래 frequency를 알아낼 수 없다.
7. **DFT는 finite samples의 periodic extension을 분석한다.** Normalization과 windowing convention을 함께 확인해야 한다.
8. **Harmonic은 $$nf_0$$ 성분이며 fundamental이 first harmonic이다.** Harmonic 간격, formant 위치, DFT bin 간격은 서로 다른 양이다. $$f_0$$ 성분이 없어도 반복 주기와 그에 대응하는 pitch가 남을 수 있다.
9. **Amplitude-phase 변환은 같은 신호의 재표현이다.** Phase 정보를 없애는 것도, 실제 delay를 새로 가하는 것도 아니다. 정확한 복원에는 amplitude뿐 아니라 phase 또는 그와 동등한 complex coefficient가 필요하다.
10. **Complex exponential form은 두 회전 방향으로 실수 sinusoid를 표현한다.** $$c_{-n}=c_n^*$$이면 허수부가 상쇄되며, $$n>0$$에서 one-sided peak amplitude는 $$2\lvert c_n\rvert$$다. DC는 $$c_0=a_0/2$$로 별도 취급한다.

## Study Guide

이 글은 **digitization → Fourier representation → discrete-time periodicity → DFT** 순서로 복습하면 가장 잘 연결된다. 먼저 sampling과 quantization이 서로 다른 축을 이산화한다는 점을 고정한 뒤, Fourier series의 orthogonal projection이 DTFS와 DFT로 어떻게 이어지는지 식을 따라가면 된다.

시험 대비에서는 다음 열 항목을 직접 설명하고 계산할 수 있는지 확인한다.

1. $$R=b f_s C$$로 uncompressed PCM bit rate를 계산한다.
2. intensity ratio에는 $$10\log_{10}$$, pressure ratio에는 조건부로 $$20\log_{10}$$을 쓰는 이유를 설명한다.
3. Fourier series, Fourier transform, DTFS, DFT의 신호 범위와 frequency 축 차이를 구분한다.
4. $$e^{j2\pi(k+N)n/N}=e^{j2\pi kn/N}$$에서 aliasing의 주기성을 유도한다.
5. 슬라이드의 7 kHz·8 kHz 예에 Nyquist 부등식을 대입하고 1 kHz와 표본이 같아지는 것을 증명한다. 경계 phase 반례와 anti-aliasing filter의 적용 시점을 설명하며 spectral leakage와 구분한다.
6. 100·200·300 Hz harmonic의 번호·합성파·주기를 계산하고, 100 Hz 항을 없앤 경우와 200·400 Hz만 남긴 경우를 비교한다.
7. $$3\cos\alpha+4\sin\alpha$$를 amplitude-phase form으로 바꾸고, plus/minus 부호 convention 및 실제 time delay와의 차이를 설명한다.
8. 같은 예제를 $$c_n,c_{-n}$$로 바꿔 실수 신호를 다시 합성하고, complex coefficient의 크기와 peak amplitude의 factor 2를 설명한다.
9. $$1/P=\Delta\omega/(2\pi)$$를 합성식에 대입해 inverse transform을 유도하고, Hz로 치환할 때 $$df$$가 나오는 이유와 rectangular pulse의 면적·첫 zero·jump 복원을 검산한다.
10. $$T=P/N$$의 sampling에서 시간 주기성과 basis의 modulo-N 동일성을 증명하고, CTFS 계수의 적분 근사와 DTFS의 정확한 정의를 구분한다. 음의 harmonic이 어느 bin으로 들어가는지도 설명한다.

헷갈리기 쉬운 핵심은 **aliasing과 leakage를 같은 현상으로 보지 않는 것**이다. Aliasing은 sampling 전에 제거하지 못한 대역이 겹쳐 원래 frequency를 복구할 수 없는 현상이고, leakage는 유한 구간의 경계 불연속 때문에 DFT energy가 이웃 bin으로 퍼지는 현상이다.

## 복습 질문

<details markdown="block">
<summary>1. Sampling과 quantization은 각각 어떤 축을 이산화하는가?</summary>

답변: Sampling은 연속 시간축을 discrete time index로 바꾸고, quantization은 연속 amplitude를 유한한 digital level로 대응시킨다.
</details>

<details markdown="block">
<summary>2. 48 kHz, 24-bit, stereo PCM의 raw bit rate는 얼마인가?</summary>

답변: Bit depth, sample rate와 channel 수를 곱한다.

$$
24\times48{,}000\times2=2{,}304{,}000\ \mathrm{bit/s}.
$$

즉 약 2.304 Mbps다.
</details>

<details markdown="block">
<summary>3. Pressure ratio에 20 log를 사용하는 이유는 무엇인가?</summary>

답변: 같은 acoustic impedance의 진행 평면파에서 평균 intensity는 RMS pressure의 제곱에 비례한다. 양의 RMS pressure와 기준값을 사용하면

$$
10\log_{10}(p_{\mathrm{rms}}^2/p_0^2)
=20\log_{10}(p_{\mathrm{rms}}/p_0)
$$

가 되기 때문이다. 순간적인 음압은 음수가 될 수 있으므로 그 값을 그대로 log에 넣지 않는다. SPL 자체는 이 pressure ratio의 정의이며, 임의의 음장에서 intensity level과 항상 같은 값이라는 뜻은 아니다.
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

<details markdown="block">
<summary>7. Fundamental이 120 Hz이면 third harmonic과 first overtone은 각각 몇 Hz인가?</summary>

답변: Third harmonic은 $$3\times120=360\ \mathrm{Hz}$$다. 연속된 harmonic series에서 first overtone은 second harmonic이므로 $$2\times120=240\ \mathrm{Hz}$$다. Fundamental은 overtone이 아니라 first harmonic이다.
</details>

<details markdown="block">
<summary>8. 200 Hz와 300 Hz만 있는 합성파의 fundamental을 200 Hz로 정하면 왜 틀리는가?</summary>

답변: 두 성분이 함께 반복되는 최소 시간은 10 ms이므로 fundamental은 100 Hz다. 100 Hz spectral component는 없지만 waveform의 주기성은 남는다. 반면 200 Hz와 400 Hz만 있다면 최소 주기는 5 ms이고 fundamental은 200 Hz다.
</details>

<details markdown="block">
<summary>9. 550 Hz formant와 40 Hz DFT bin 간격이 있으면 fundamental도 둘 중 하나인가?</summary>

답변: 아니다. Formant는 vocal tract의 공명, DFT bin 간격은 관측 길이로 정해진 분석 grid다. Voiced excitation의 harmonic 간격이 100 Hz일 수 있으며 세 값은 서로 모순되지 않는다. Fundamental 추정에는 harmonic 구조나 시간축 반복성을 확인해야 한다.
</details>

<details markdown="block">
<summary>10. Sine-cosine form을 amplitude-phase form으로 바꾸면 실제 신호도 지연되는가?</summary>

답변: 아니다. 두 식은 모든 시각에서 같은 값을 갖는 항등적 재표현이다. Amplitude는 성분의 크기를, phase는 기준 시각의 정렬을 읽기 쉽게 나타낸다. 실제 지연은 별도로 $$y(t)=x(t-\tau)$$를 적용하는 연산이다.
</details>

<details markdown="block">
<summary>11. 1000 Hz cosine을 0.25 ms 지연하면 phase와 frequency는 어떻게 달라지는가?</summary>

답변: Plus-phase 기준으로

$$
\Delta\delta=-2\pi\times1000\times0.00025=-\pi/2\ \mathrm{rad}.
$$

Frequency는 1000 Hz 그대로이고 peak만 0.25 ms 늦어진다. 같은 지연을 2000 Hz에 적용하면 phase 변화는 $$-\pi$$ rad이므로 모든 frequency에 같은 angle을 주는 처리와 구별해야 한다.
</details>

<details markdown="block">
<summary>12. Magnitude spectrum이 같으면 waveform도 반드시 같은가?</summary>

답변: 아니다. 같은 frequency와 amplitude를 가진 cosine과 sine도 phase가 달라 서로 다른 waveform이다. 원래 파형을 일반적으로 유일하게 복원하려면 phase 또는 동등한 complex coefficient를 함께 보존해야 한다.
</details>

<details markdown="block">
<summary>13. Complex exponential form에 음의 주파수가 들어가는 이유는 무엇인가?</summary>

답변: 실수 sinusoid를 복소 평면의 반대 회전 쌍으로 표현하기 때문이다. Real-valued 신호에서는 $$c_{-n}=c_n^*$$이고 두 항의 허수부가 상쇄되어 실수 waveform이 된다. 음의 pitch나 역방향 시간을 뜻하지 않는다.
</details>

<details markdown="block">
<summary markdown="span">14. $$3\cos\alpha+4\sin\alpha$$의 positive-frequency coefficient는 무엇이며, amplitude가 5인 이유는 무엇인가?</summary>

답변: $$c_n=(3-4j)/2=1.5-2j$$이고 $$\lvert c_n\rvert=2.5$$다. Negative-frequency coefficient $$1.5+2j$$와 함께 하나의 실수 sinusoid를 이루므로 peak amplitude는 $$2\lvert c_n\rvert=5$$다. 이 배수는 DC에는 적용하지 않는다.
</details>

<details markdown="block">
<summary>15. 주기를 무한히 늘릴 때 Fourier coefficient를 그대로 spectrum으로 바꾸면 왜 틀리는가?</summary>

답변: 유한 support 신호의 반복 모델에서는 $$c_n^{(P)}=X_\omega(\omega_n)/P$$다. 주기를 늘리면 각 계수는 작아지고 frequency grid의 항 수는 증가한다. 계수의 $$1/P$$를 $$\Delta\omega/(2\pi)$$로 바꿔 합에 남겨야 올바른 적분과 정규화가 나온다.
</details>

<details markdown="block">
<summary>16. Forward에서는 시간, inverse에서는 frequency를 적분하는 이유는 무엇인가?</summary>

답변: Forward는 하나의 frequency를 고정하고 전체 시간의 신호가 그 basis에 얼마나 맞는지 계산한다. Inverse는 하나의 시간 $$t$$를 고정하고 모든 frequency의 기여를 합친다. 따라서 Hz inverse의 적분 변수는 $$df$$이며 $$dt$$가 아니다.
</details>

<details markdown="block">
<summary>17. 높이 1 V, 폭 2 ms pulse의 zero-frequency spectrum과 jump 복원값은 무엇인가?</summary>

답변: Zero-frequency spectrum은 면적 $$1\times0.002=0.002\ \mathrm{V\,s}$$다. 첫 양의 spectral zero는 500 Hz이고, jump에서는 symmetric inverse가 양쪽 극한의 평균인 0.5 V를 복원한다. Spectrum 값과 waveform amplitude를 같은 단위로 읽지 않는다.
</details>

<details markdown="block">
<summary>18. Signal → frequency → signal과 frequency → signal → frequency는 각각 왜 원래 표현으로 돌아오는가?</summary>

답변: 첫 왕복은 시간축의 sinc형 kernel로 신호를, 두 번째 왕복은 frequency 축의 sinc형 kernel로 spectrum을 복원한다. 둘 다 적분 순서와 극한을 허용하는 조건이 필요하다. Magnitude만 남기거나 frequency를 삭제하는 중간 처리를 하면 원래 표현을 보존하는 왕복이 아니며, 실수 신호 합성에는 conjugate symmetry도 유지해야 한다.
</details>

<details markdown="block">
<summary>19. Nyquist 조건을 만족하지 못해도 DTFS를 계산하고 표본을 정확히 복원할 수 있는가?</summary>

답변: 그렇다. 모든 N-periodic 표본열은 N개의 직교 exponential basis로 정확히 표현된다. Nyquist 조건은 그 표현의 존재 조건이 아니라, 별도의 대역 가정 아래 원래 연속시간 harmonic들을 구별하기 위한 조건이다. Section 9.7의 1 kHz·7 kHz 혼합처럼 서로 다른 연속 신호가 같은 표본과 DTFS를 가질 수 있다.
</details>

<details markdown="block">
<summary>20. CTFS 적분을 Riemann sum으로 바꾼 근사와 DTFS 계수의 정확한 등식은 어떻게 다른가?</summary>

답변: 고정된 harmonic의 CTFS 적분을 유한 표본 합으로 계산하는 것은 일반적으로 근사다. 같은 유한 합은 DTFS 계수 자체의 정확한 정의이며, 정규화 1/N은 discrete basis의 직교성으로 증명된다. 충분한 급수 수렴 조건 아래 두 계수의 차이는 같은 나머지로 겹친 다른 CTFS 계수들의 합이다.
</details>

<details markdown="block">
<summary>21. N=8의 alias-free low-pass 신호에서 음의 harmonic −1은 어느 DTFS bin에 들어가는가?</summary>

답변: −1과 7은 modulo 8에서 같으므로 bin 7에 들어간다. 따라서 이 경우 $$d_7=c_{-1}$$이며, 모든 raw index에서 $$d_k=c_k$$라고 읽으면 안 된다. DTFS 계수의 주기성과 원래 CTFS 계수의 index를 구분한다.
</details>

<details markdown="block">
<summary>22. 슬라이드의 7 kHz 신호는 8 kHz로 sampling할 때 왜 Nyquist 조건을 만족하지 않는가?</summary>

답변: 비교 대상은 7 kHz 자체가 아니라 그 두 배인 14 kHz다. Sampling rate 8 kHz의 Nyquist frequency는 4 kHz이므로 7 kHz는 대역 밖이다. Section 10.2의 계산처럼 모든 정수 표본 위치에서 $$x_7[n]=x_1[n]$$이므로 zero-phase 1 kHz cosine과 구별할 수 없다. 원래 7 kHz까지 보존하려면 14 kHz보다 높은 rate를 사용하고, 8 kHz를 유지하려면 ADC 전에 대역 밖 성분을 감쇠해 보존할 신호 범위 자체를 제한해야 한다.
</details>

<details markdown="block">
<summary>23. 최고 frequency의 정확히 두 배로 sampling하거나, 나중에 표본 수를 늘리면 항상 복원할 수 있는가?</summary>

답변: 아니다. 경계에서 phase가 π/2인 cosine은 $$x[n]=A\cos(\pi n+\pi/2)=0$$이 되어 0 신호와 구별되지 않는다. 이미 같은 표본으로 겹친 두 입력은 동일한 보간·FFT 처리에도 같은 결과를 내므로, 사후 표본 수 증가만으로 원신호 구분이 돌아오지 않는다. 대역 가정과 sampling 전 filter가 필요한 이유다.
</details>

## Source Check

2026-09-08 검토에서는 **원본 PDF 40쪽의 추출 텍스트와 이 포스트 전체**를 대조하고, 아래 오류 관련 수식·문구가 있는 물리적 PDF pp.8-9, 20-21, 25-28을 원본 화면으로 재확인했다. 원문을 그대로 따랐는지와 실제로 맞는지는 별개로 판단했다. 표의 page는 물리적 PDF 번호이고 괄호 안은 슬라이드 footer다.

2026-09-10에는 **Fourier transform에 해당하는 PDF pp.29–31 (footer 32, 33, 35)**를 화면과 텍스트로 다시 확인했다. Section 8에 강의의 유도 흐름, 누락된 scaling과 적분 단계, 복원 조건과 검산을 보강했다. Section 8.9에서는 signal → frequency와 frequency → signal의 역할 및 두 방향의 왕복을 별도 유도하고, 원문에 생략된 조건을 명시했다. 이어서 **PDF pp.32–36, 39 (footer 36–40, 43)**도 화면과 대조해 Section 9의 CTFS→DTFS 연결을 보강했다. 이번 추가 검토를 다른 과목의 전수 검증으로 확대하지 않는다.

| Location | Classification | 확인 내용과 조치 |
|---|---|---|
| PDF p.8 (8), Section 3 | 생략된 물리 조건 | $$I_n\sim p_n^2$$를 보편적 intensity 식으로 사용하지 않는다. 일반적인 전달 intensity는 pressure와 particle velocity의 곱이며, 진행 평면파에서만 impedance를 사용해 pressure 제곱으로 환산한다. Section 3.2의 유도·standing-wave 반례와 MIT Acoustics 근거를 제시했다. |
| PDF p.9 (9), Section 3 | 개념 오류 | Loudness를 단순한 dB intensity와 동일시하지 않는다. 물리적 pressure/intensity level과 지각 속성을 구분하고 SPL의 정의·조건을 설명했다. |
| PDF p.20 (20), Section 6 | 모호한 수렴 조건 | Absolutely integrable의 영역과 수렴 의미가 생략되어 있다. 한 주기 적분 가능성과 점별 복원 가능성을 구분하고 piecewise-smooth 충분조건을 명시했다. 원저자의 의도를 단정해 오류로 분류하지 않는다. |
| PDF p.21 (21), Section 6.3.2 | 첨자 오류 | 합의 index가 $$n$$인데 coefficient는 $$c_k$$로 표기되어 있어 $$c_n$$로 통일했다. Euler formula에서 계수 대응을 직접 유도했다. |
| PDF p.25 (27), p.28 (31), Section 6 | 정규화 불일치 | 같은 계수로 동치라고 소개하는 sine-cosine 식의 DC가 $$a_0$$로 적혀 있다. 이 글의 convention에서는 $$a_0/2$$로 통일하고 $$c_0=a_0/2$$를 명시했다. 다른 DC 정의 자체가 틀린 것이 아니라 동치 표현 사이의 일관성이 문제다. |
| PDF p.26 (28), Section 7 | 수식 오류 | Orthogonality의 두 경우가 뒤바뀌고 conjugate 전개의 부호가 일치하지 않는다. $$n=m$$이면 $$P$$, 다르면 0임을 직접 적분으로 확인했다. |
| PDF pp.29–30 (32–33), Sections 8.2–8.5 | 가정·중간 단계 생략 | “any signal”을 조건 없는 일반 적분 명제로 읽지 않는다. 주기 확장과 $$c_n^{(P)}=X_\omega(\omega_n)/P$$, Riemann sum, symmetric cutoff 복원과 jump의 평균값을 구분해 유도했다. |
| PDF p.31 (35), Section 8.6 | 적분 변수 오류 | Hz inverse 식 끝의 $$dt$$를 $$df$$로 정정했다. 원문 화면 및 $$d\omega=2\pi\,df$$ 치환으로 확인했다. Forward/inverse 정규화 관례 차이와 구분한다. |
| PDF pp.32–35 (36–39), Sections 9.1–9.5 | 가정·근사 범위 보완 | $$P=NT$$의 sampling 주기 조건과 CTFS 급수의 점별 대입·재배열 조건을 명시했다. CTFS 적분의 Riemann-sum 근사와 DTFS 계수의 정확한 정의를 구분하고 N개 직교 basis의 완전성을 설명했다. p.35의 discrete period를 P라고 쓴 문구는 표본 주기 N과 구분한다. |
| PDF pp.36, 39 (40, 43), Sections 9.6–9.7 | 계수 index 범위 생략 | Nyquist 조건 아래의 계수 동일성은 원래 대역의 signed harmonic과 대응하는 modulo-N bin 사이의 관계다. N=8에서 $$d_7=c_{-1}$$인 예로 모든 raw index에 $$d_k=c_k$$를 적용하면 안 됨을 설명했다. |
| Post, Section 2 | 해설의 단위 오류 | 기존 단위식에서 `/channel`을 두 번 나누는 표기를 수정했다. 한 channel의 bit rate를 구한 뒤 channel 수를 곱하는 순서로 재작성했다. |
| Post, Sections 3.1 and 4 | 해설의 과도한 일반화 | 음압 calibration만으로 intensity 단위가 확보된다는 표기와 PCM이 원래 신호를 정확히 보존한다는 문구를 수정했다. Pressure 제곱의 단위 및 analog-to-digital 손실을 구분했다. |
| Post, Section 10.1 | 증명 논리 보완 | 최고·최저 index만 비교하는 설명 대신 대역 안의 모든 index 쌍의 차이와 나머지 개수로 alias-free 조건을 증명했다. |
| PDF pp.37–38 (41–42), Section 10 | 질문·예제 해설 보완 | “is not satisfied”는 조건 위반을 묻는 문구다. 화면의 1 kHz·7 kHz 및 8 kHz 값을 확인하고, 7 kHz에 대해 $$8<14$$인 조건 위반과 표본 동일성·phase 반전을 직접 계산했다. p.37 개념도의 폭과 moire 사진에는 수치가 없어 대역폭·pixel 간격을 추정하지 않았다. 원문 오류 판정이 아니라 생략된 설명의 보강이다. |

Phase 부호·`atan2`, complex coefficient의 factor 2, harmonic 주기, source-filter의 LTI 가정, DTFS/DFT의 정규화도 정의·재계산과 대조했다. **이 검토는 현재 Speech Lecture 2에 한정되며 다른 과목이나 모든 원문 페이지의 시각적 전수 검증 완료를 의미하지 않는다.** 원본 PDF는 수정하지 않았고, 위 내용은 강의자가 발행한 공식 정정문이 아니라 작성자의 검토·정정 기록이다.

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

### Supplementary References

2026-09-10 보완: Fourier transform 부분은 원문 pp.29–31의 전개 순서에 맞춰 정의·주기 극한·역변환을 연결했다. 작성자의 cutoff kernel 증명 개요와 rectangular-pulse 계산을 덧붙이고, 원문 inverse 식의 적분 변수 오기를 기록했다. 이어지는 CTFS→DTFS 부분에는 sampling 조건, 직교 basis와 aliasing 계수, 적분 근사의 적용 범위 및 signed-index 대응을 추가했다. 로컬 강의 폴더의 별도 보강 Markdown에도 반영하며, 원본 PDF와 공개 URL은 보존한다.

2026-09-08 보완: 원본 PDF pp.19-24의 harmonic 설명에 용어·단위, 정수배 조건의 유도, 합성파 계산, missing fundamental 및 speech source-filter 연결을 추가했다. PDF pp.15-17, 22-25의 phase 설명에는 amplitude-phase 재표현의 목적, `atan2`·부호 convention, 실제 지연의 유도와 복원·상쇄 예제를 보충했다. PDF pp.18, 21-25의 exponential form에는 Euler formula로부터의 계수 유도, 음의 주파수·conjugate symmetry, factor 2와 복원 예제, 미분·지연 연산의 의미를 추가했다. 원본 PDF와 기존 공개 URL은 변경하지 않았다.

<ul>
  <li><a href="https://courses.physics.illinois.edu/phys406/sp2017/Lecture_Notes/P406POM_Lecture_Notes/P406POM_Lect6.pdf" target="_blank" rel="noopener">UIUC Physics 406: Harmonics and Overtones</a> — harmonic series의 fundamental·harmonic·overtone 번호 대응, p.2.</li>
  <li><a href="https://ocw.mit.edu/courses/res-6-007-signals-and-systems-spring-2011/cf3874410d609d71d6036e7572525222_MITRES_6_007S11_lec10.pdf" target="_blank" rel="noopener">MIT Signals and Systems: Discrete-Time Fourier Series</a> — PDF pp.1–2의 유한 exponential basis와 계수 주기성.</li>
  <li><a href="https://ocw.mit.edu/courses/hst-582j-biomedical-signal-and-image-processing-spring-2007/c8dc8096a9d75f8f30b4b97354b48437_ch1_adc.pdf" target="_blank" rel="noopener">MIT HST.582J: Aliasing of a Periodic Signal</a> — Section 1.A.2.3, PDF p.16 (printed p.15)의 CTFS sampling과 계수 재배열 유도.</li>
  <li><a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/b0a5f07216a4153e8f6160178f0ea764_lecture_04.pdf" target="_blank" rel="noopener">MIT 2.161 Lecture 4: Fourier Transform</a> — angular-frequency pair와 spectrum 단위, convention 비교 및 rectangular-pulse 적분, Sections 1–1.2.</li>
  <li><a href="https://people.tamu.edu/~f-narcowich/m414/s04w/m414w_ln14.html" target="_blank" rel="noopener">Texas A&amp;M Math 414: Fourier Series and Fourier Transforms</a> — 주기 확장의 Riemann-sum 전개와 piecewise-smooth inversion theorem; unitary 정규화는 이 글의 convention으로 환산해 비교.</li>
  <li><a href="https://open.lib.umn.edu/sensationandperception/chapter/pitch-perception/" target="_blank" rel="noopener">University of Minnesota: Pitch Perception</a> — harmonic complex tone과 missing fundamental의 지각.</li>
  <li><a href="https://icm.music.cs.cmu.edu/icm-online/icm-text-2nd-ed.pdf" target="_blank" rel="noopener">CMU: Introduction to Computer Music</a> — Chapter 9, pp.159-160의 voiced excitation·harmonic spectrum·formant filter.</li>
  <li><a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/3ab918dbe6a0376dbd9216e404fee31b_fourier.pdf" target="_blank" rel="noopener">MIT OCW: Fourier Series Representation of Signals</a> — pp.3-4의 amplitude-phase 재표현, complex coefficient와 conjugate symmetry.</li>
  <li><a href="https://pordlabs.ucsd.edu/sgille/sioc221a_f20/lecture14_notes.pdf" target="_blank" rel="noopener">UCSD SIOC 221A: Phase and Quadrant Conventions</a> — p.2의 plus-phase convention과 atan2.</li>
  <li><a href="https://www.seas.upenn.edu/~ese2240/slides/300_fourier_transforms.pdf" target="_blank" rel="noopener">University of Pennsylvania: Fourier Transforms</a> — p.63의 time-shift 성질.</li>
  <li><a href="https://ocw.mit.edu/courses/6-013-electromagnetics-and-applications-spring-2009/50a609ff2cc992401a099bca53801474_MIT6_013S09_chap13.pdf" target="_blank" rel="noopener">MIT OCW: Acoustics</a> — Section 13.1.2의 acoustic pressure, particle velocity와 impedance.</li>
  <li><a href="https://www.nist.gov/pml/special-publication-811/nist-guide-si-chapter-8" target="_blank" rel="noopener">NIST Guide to the SI: Chapter 8</a> — logarithmic quantity와 power/field ratio.</li>
</ul>
