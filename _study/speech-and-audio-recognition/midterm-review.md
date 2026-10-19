---
layout: default
date: 2026-10-15 15:17:14 +0900
last_modified_at: 2026-10-19 14:13:07 +0900
title: "Speech and Audio Recognition: Midterm Review"
course: "Speech and Audio Recognition"
topic: "Digital Signals, ASR, and Self-Supervised Learning"
order: 10
major_topic: "Speech and Audio Processing"
keywords:
  - "Fourier Analysis"
  - "STFT"
  - "Mel Spectrogram"
  - "CTC"
  - "RNN-Transducer"
  - "BPE"
  - "Conformer"
  - "Self-Supervised Learning"
  - "wav2vec 2.0"
  - "HuBERT"
---

# Speech and Audio Recognition: Midterm Review

## Presentation

[View slides (PDF)]({{ "/assets/pdfs/study/speech-and-audio-recognition/sar-midterm-review-slides.pdf" | relative_url }}) · <a href="{{ "/assets/presentations/study/speech-and-audio-recognition/sar-midterm-review-slides.pptx" | relative_url }}" download>Download PowerPoint (PPTX)</a>

64장으로 신호 처리·ASR·Self-Supervised Learning의 핵심 그림과 확률 계산을 정리했다. 같은 신호의 waveform·spectrogram 비교와 phase 보존 조건을 추가하고, CTC Summary부터 wav2vec 2.0 직전까지는 원본 그림과 요약표를 한국어로 풀어 설명한다. Attention·LAS·RNN-T의 학습과 추론, 언어모델 결합, 자기지도학습의 target 구성을 수치 예제와 함께 다룬다. Source Separation은 포함하지 않는다. PDF를 선택하면 본문과 나란히 볼 수 있고, 좁은 화면에서는 모달로 열린다. 상세 유도와 코드 해설은 아래 본문에서 이어진다.

Source PDFs:

- [Lecture 2: Digital Signal Processing I]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02.pdf" | relative_url }})
- [Lecture 2 Lab: FFT, STFT, Mel, and Cepstrum]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }})
- [Lecture 3: Automatic Speech Recognition I]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }})
- [Lecture 4: Automatic Speech Recognition II]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }})
- [Lecture 5: Self-Supervised Learning]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }})

Source Notebooks:

- [SAR Lec01 public notebook]({{ "/assets/materials/study/speech-spectral-analysis/sar-lec01-public.ipynb" | relative_url }}): FFT, STFT, Mel spectrum, cepstrum, and MFCC
- [BPE basics notebook]({{ "/assets/materials/study/speech-asr-lab/01-bpe-basics.ipynb" | relative_url }}): BPE training and tokenization
- [CTC inference notebook]({{ "/assets/materials/study/speech-asr-lab/02-ctc-inference.ipynb" | relative_url }}): CTC greedy and prefix-beam decoding
- [RNN-T inference notebook]({{ "/assets/materials/study/speech-asr-lab/03-rnnt-inference.ipynb" | relative_url }}): RNN-T inference

> **핵심:** 소리를 sample로 바꾸고, 주파수 특징을 만든 뒤, 길이가 다른 음향 frame열과 문자·subword열을 정렬한다. 이어서 정답 전사 없이 음성 표현을 학습하는 방법까지 살펴본다. **어떤 정보를 보존하는지, 확률과 loss를 어떻게 계산하는지, 학습 target을 어디에서 얻는지**를 연결하면 신호 처리·ASR·자기지도 학습의 역할을 구분할 수 있다.

**중간고사 범위는 Source Separation 직전인 Self-Supervised Learning까지다.** Lecture 2–5와 spectral-analysis·BPE/CTC/RNN-T 실습을 포함한다. Lecture 5의 wav2vec 2.0·HuBERT는 범위 안이고, Lecture 6–7의 Source Separation과 DPCL·PIT/uPIT는 범위 밖이다. 별도의 Lecture 1 PDF는 현재 과목 폴더에 없으므로 내용을 추정해 추가하지 않는다.

## 전체 흐름

| 단계 | 입력 | 핵심 연산 | 출력 | 확인할 질문 |
|---|---|---|---|---|
| 디지털화 | 연속 음압 | sampling, quantization | PCM sample열 | 시간·진폭 정보를 어떤 정밀도로 남기는가? |
| 주파수 분석 | 유한 sample열 | DFT/FFT, STFT | complex spectrum | 어느 주파수가 언제 존재하는가? |
| 지각 특징 | power spectrum | Mel filterbank, log, DCT | log-Mel, MFCC | 인식에 유용한 축약과 복원 정보 손실을 어떻게 구분하는가? |
| ASR 정렬 | 음향 frame열 | CTC, attention, RNN-T | token sequence | 길이가 다른 두 sequence를 어떻게 정렬하고 점수화하는가? |
| 표현 사전학습 | transcript 없는 음성 | masking, quantization, pseudo-label prediction | speech representation | 정답 text 없이 어떤 target을 만들 수 있는가? |

신호 처리와 ASR의 흐름은 다음과 같다. 자기지도 학습은 이 과정에서 사용할 음성 표현을 전사 없는 데이터로 먼저 학습하는 방법이다.

```text
air pressure
  -> sampled waveform
  -> complex time-frequency representation
  -> acoustic representation
  -> aligned token sequence
```

## 1. Sound에서 digital signal로

### 1.1 Sampling과 quantization은 서로 다른 축을 이산화한다

Sampling은 시간을 일정 간격으로 관측한다. Sampling rate가 $$f_s$$라면 sample 간격은 $$T_s=1/f_s$$초다. Quantization은 각 시각에서 측정한 진폭을 유한한 level 중 하나로 바꾼다. 따라서 낮은 sampling rate는 빠른 시간 변화를 구분하지 못하게 하고, 낮은 bit depth는 진폭 오차를 키운다.

압축하지 않은 PCM의 payload bit rate는 다음 정확한 계산으로 얻는다.

$$
R=b f_s C
$$

여기서 $$b$$는 bit/sample, $$f_s$$는 samples/s, $$C$$는 channel 수다. 16-bit, 44.1 kHz, stereo라면 $$R=1{,}411{,}200\ \mathrm{bit/s}$$다. 이 값은 header와 codec overhead를 포함하지 않는다.

### 1.2 Amplitude, pressure, intensity, loudness를 섞지 않는다

Sound intensity는 단위 면적을 통과하는 평균 acoustic power다.

$$
I=\frac{E}{tA}=\frac{P}{A}
$$

| 기호 | 의미 | SI 단위 |
|---|---|---|
| $$I$$ | sound intensity | $$\mathrm{W/m^2}$$ |
| $$E$$ | energy | $$\mathrm{J}$$ |
| $$t$$ | 측정 시간 | $$\mathrm{s}$$ |
| $$A$$ | 통과 면적 | $$\mathrm{m^2}$$ |
| $$P=E/t$$ | acoustic power | $$\mathrm{W}$$ |
| $$p$$ | sound pressure | $$\mathrm{Pa}$$ |

진행 평면파라는 조건에서는 $$I=p_{\mathrm{rms}}^2/(\rho c)$$가 성립한다. 그러나 calibration되지 않은 PCM 값의 제곱은 절대 intensity가 아니라 상대적인 energy proxy다. Standing wave나 near field에서는 pressure와 particle velocity의 관계가 달라지므로 pressure 제곱만으로 전달 intensity를 결정할 수 없다.

### 1.3 Nyquist 조건은 원래 연속 주파수를 구별하는 조건이다

Band limit가 $$f_{\max}$$일 때 임의 phase의 성분을 구별하려면 이 범위에서는 다음 strict condition을 사용한다.

$$
f_s>2f_{\max}
$$

강의 p.38의 예처럼 8 kHz로 7 kHz cosine을 sampling하면 $$8<14$$이므로 조건을 만족하지 않는다. Sample 시각 $$t_n=n/8000$$에서 진폭 1·zero-phase의 7 kHz와 1 kHz cosine은 같은 값을 만든다.

DFT 계산 자체는 실패하지 않는다. DFT는 주어진 sample열을 정확히 변환하지만, 이미 같은 sample이 된 1 kHz와 7 kHz 원신호를 구별할 정보는 없다. 이 문제가 aliasing이다. Bit depth 증가나 FFT 길이 증가는 잃은 구분을 복원하지 못한다.

**Fourier basis는 표본을 주파수 계수로 분석하는 기준이며, aliasing을 막는 필터가 아니다.** 서로 다른 discrete basis의 직교성은 계수 계산을 가능하게 하지만, sampling 후 같은 basis가 된 원래 주파수까지 분리해 주지는 않는다.

작성자 예제로 8 kHz에서 진폭 1·zero-phase인 5 kHz와 3 kHz cosine을 비교하면 첫 다섯 표본은 둘 다 **1, −0.7071, 0, 0.7071, −1**이다. 반면 표본 사이인 0.0625 ms에서는 각각 약 −0.3827과 0.3827로 다르다. **예방은 sampling 전 anti-alias low-pass filter와 보존 대역에 충분한 sampling rate로 한다.** 8 kHz를 유지하면 4 kHz 이상을 충분히 감쇠해야 하며, 5 kHz를 보존하려면 $$f_s>10$$ kHz와 필터 전이 대역을 고려해야 한다. [원본 그림과 8개 표본 DFT 해설]({{ "/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/#fourier-basis-and-aliasing" | relative_url }})에서 계수까지 확인할 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: Nyquist condition from repeated discrete frequencies</summary>

$$n,r$$은 정수, $$f,f_s$$는 Hz다. Discrete-time complex exponential은 sampling rate의 정수배만큼 주파수가 달라도 같다.

$$
e^{j2\pi(f+r f_s)n/f_s}
=e^{j2\pi fn/f_s}e^{j2\pi rn}
=e^{j2\pi fn/f_s}.
$$

실수 cosine에서는 주기성과 짝대칭성에 의해 다음 등식이 성립한다.

$$
\cos(2\pi\cdot7000n/8000)
=\cos(2\pi n-2\pi\cdot1000n/8000)
=\cos(2\pi\cdot1000n/8000).
$$

같은 계산에서 7000·1000을 5000·3000으로 바꾸면 본문의 추가 예제가 된다. Complex exponential의 +5 kHz는 −3 kHz와 같으며, 실수 cosine을 +3 kHz로 표현할 때 일반 phase $$\phi$$는 $$-\phi$$로 바뀐다. 따라서 본문의 같은-phase 비교에는 zero-phase 조건을 두었다.

원래 spectrum이 $$[-f_{\max},f_{\max}]$$에 있고, 다음 복사본이 $$[f_s-f_{\max},f_s+f_{\max}]$$에 생긴다고 하자. 두 구간이 겹치지 않으려면

$$
f_{\max}<f_s-f_{\max}
$$

여야 하므로 $$f_s>2f_{\max}$$를 얻는다. 등호 경계에서는 $$+f_s/2$$와 $$-f_s/2$$가 같은 bin이 된다. 특히 phase가 $$\pi/2$$인 경계 sinusoid는 sample이 모두 0이 될 수 있으므로, 경계 성분을 허용하는 일반적인 복원에는 별도 가정이 필요하다.

</details>

## 2. Fourier 표현에서 STFT와 Mel 특징까지

### 2.1 Fourier coefficient는 basis와의 정렬 정도다

주기 신호는 harmonic basis의 합으로 표현할 수 있다. 다음 convention을 사용하자.

$$
a_n\cos(n\omega_0t)+b_n\sin(n\omega_0t)
=A_n\cos(n\omega_0t-\phi_n).
$$

이때 진폭과 위상은 다음과 같다.

$$
A_n=\sqrt{a_n^2+b_n^2},\qquad
\phi_n=\operatorname{atan2}(b_n,a_n)
$$

이다. 같은 성분의 positive-frequency complex coefficient는 $$c_n=(a_n-jb_n)/2$$이고, real signal에서는 $$c_{-n}=c_n^*=(a_n+jb_n)/2$$다. 따라서 $$a_n,b_n$$와 complex coefficient의 real·imaginary coordinate는 부호와 1/2 scale까지 포함해 변환해야 한다.

Real part가 magnitude이고 imaginary part가 phase인 것은 아니다. 한 complex coefficient의 두 좌표를 함께 사용해 magnitude와 phase를 계산한다. Phase는 각 주파수 성분이 기준 시각에서 어디에 놓이는지를 정하므로, magnitude만 같은 두 spectrum도 다른 waveform을 만들 수 있다.

비주기 신호의 Fourier transform pair는 한 convention에서 다음과 같다.

$$
X(f)=\int_{-\infty}^{\infty}x(t)e^{-j2\pi ft}\,dt,
\qquad
x(t)=\int_{-\infty}^{\infty}X(f)e^{j2\pi ft}\,df.
$$

Forward와 inverse의 부호·정규화는 다른 convention도 가능하다. 두 식을 한 쌍으로 일관되게 사용해야 한다.

### 2.2 CTFS, FT, DTFS, DFT는 신호의 조건이 다르다

| 표현 | 대상 | 주파수 표현 | 핵심 조건 |
|---|---|---|---|
| CTFS | 연속시간 주기 신호 | 기본 주파수의 이산 harmonic | 한 주기에서 적분해 coefficient 계산 |
| FT | 연속시간 비주기 신호 | 연속 주파수 함수 | 절대적분 가능성 또는 generalized transform 조건 |
| DTFS | 이산시간 주기 sequence | 한 주기 안의 유한 coefficient | coefficient가 주파수 index에서 주기적 |
| DFT | 길이 $$N$$인 유한 sample block | $$N$$개 bin | 입력 block을 한 주기의 periodic sequence로 해석 |

연속시간 주기 신호

$$
x(t)=\sum_{k=-\infty}^{\infty}c_k e^{j2\pi k t/T_0}
$$

를 한 주기에서 $$N$$번, 즉 $$t_n=nT_0/N$$에서 sampling하면

$$
x[n]=\sum_{k=-\infty}^{\infty}c_k e^{j2\pi kn/N}
$$

이 된다. 여기서 $$k$$와 $$k+qN$$은 sample 위에서 같은 basis다. 길이 $$N$$ DFT를 $$X[r]=\sum_{n=0}^{N-1}x[n]e^{-j2\pi rn/N}$$로 두면

$$
X[r]=N\sum_{q=-\infty}^{\infty}c_{r+qN}.
$$

즉 CTFS coefficient가 DTFS/DFT의 같은 나머지 class로 **겹쳐 더해지는 것**이 spectral aliasing이다. CTFS가 $$\lvert k\rvert\le K$$에서만 0이 아니고 $$N>2K$$라면 서로 다른 nonzero harmonic이 같은 나머지 class에 겹치지 않아 $$c_k=X[k\bmod N]/N$$으로 회수할 수 있다. 단순히 표본이 $$N$$개라는 사실만으로 가능한 것이 아니라, 한 주기를 균일 sampling했고 원래 harmonic bandwidth가 충분히 제한되었다는 조건이 필요하다.

### 2.3 DFT와 FFT의 관계

DFT는 유한한 $$N$$개 sample을 $$N$$개의 주파수 basis에 투영하는 변환이다. FFT는 **같은 DFT 값**을 부분합 재사용으로 빠르게 계산하는 알고리즘이다. Radix-2 FFT는 짝수·홀수 sample의 두 $$N/2$$-point DFT를 결합해

$$
T(N)=2T(N/2)+O(N)=O(N\log N)
$$

의 계산량을 얻는다. FFT가 frequency resolution이나 입력 정보를 자동으로 늘리는 것은 아니다.

### 2.4 STFT는 시간 위치를 얻는 대신 창의 조건을 갖는다

STFT는 frame마다 window를 곱하고 DFT를 계산한다.

Waveform은 가로축 시간(s)과 세로축 진폭으로 sample 값을 직접 보여 준다. Spectrogram은 가로축 frame 시간(s), 세로축 주파수(Hz), 색으로 magnitude·power·dB 중 선택한 값을 보여 준다. 8 kHz로 표본화한 1초 예제에서 500 Hz tone은 계속 유지되고 1500 Hz tone은 0.4–0.8초에만 켜지므로, 파형에서는 두 진동이 합쳐지지만 spectrogram에서는 500 Hz의 전 구간 띠와 1500 Hz의 제한된 띠로 분리된다. [같은 신호의 전체 파형·확대 파형·power STFT dB 비교]({{ "/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/#waveform-spectrogram-comparison" | relative_url }})에서 축·window 설정과 10 ms linear ramp를 확인할 수 있다.

화면에 그린 magnitude·power spectrogram은 complex STFT의 phase를 보존하지 않는다. $$3+4j$$와 $$3-4j$$는 magnitude 5와 power 25로 같지만 phase는 각각 약 $$+53.13^\circ$$와 $$-53.13^\circ$$다. 파형 $$x[n]$$과 $$-x[n]$$도 magnitude spectrogram은 같고 0이 아닌 coefficient의 phase만 $$\pi$$ rad 다르다. 정확한 iSTFT에는 magnitude 그림이 아니라 complex STFT와 일치하는 window·hop·padding·원 길이, 모든 표본을 덮는 overlap-add 조건이 필요하다.

$$
S[m,k]=\sum_{r=0}^{L-1}x[mH+r]w[r]e^{-j2\pi kr/N_{\mathrm{FFT}}}.
$$

| 기호 | 의미 |
|---|---|
| $$L$$ | window length in samples |
| $$H$$ | hop length in samples |
| $$N_{\mathrm{FFT}}$$ | FFT length |
| $$m$$ | frame index |
| $$k$$ | frequency-bin index |

긴 창은 주파수를 더 세밀하게 나누기 쉽지만 짧은 변화를 넓게 섞는다. 짧은 창은 시간 위치를 더 좁게 보지만 주파수 peak가 넓어진다. Zero-padding으로 $$N_{\mathrm{FFT}}$$만 키우면 표시 bin은 촘촘해져도 관측 시간 $$L/f_s$$가 제공한 물리적 분해능은 늘지 않는다.

예를 들어 1초 길이의 16 kHz 신호에 $$L=400$$, $$H=160$$, $$N_{\mathrm{FFT}}=512$$를 쓰면 창은 25 ms, hop은 10 ms다. Center padding 없이 끝을 버리면 frame 수는

$$
1+\left\lfloor\frac{16000-400}{160}\right\rfloor=98
$$

이고, real input의 one-sided spectrum은 frame마다 $$512/2+1=257$$개 frequency bin을 갖는다. 따라서 구현의 배열 배치에 따라 shape는 `[257, 98]` 또는 `[98, 257]`이다. Center padding을 켜면 frame 수가 달라지므로 그림의 축과 코드 tensor shape를 함께 확인해야 한다.

**Window는 FFT 전에 시간 표본의 기여도를 정한다.** Rectangular window로 임의 구간을 자르면 반복 경계가 매끄럽지 않을 수 있다. Hann window는 가장자리 기여를 낮춰 먼 sidelobe를 줄이지만 main lobe를 넓힌다. 따라서 window는 leakage를 없애는 버튼이 아니라 **어떤 오차를 줄이고 어떤 분해능을 희생할지 정하는 선택**이다. 작성자 예제로 입력 [2, 2, 2, 2, 2]에 대칭 Hann [0, 0.5, 1, 0.5, 0]을 곱하면 [0, 1, 2, 1, 0]이다. 잡음을 식별한 것이 아니라 시간 가중치를 바꾼 결과다. [원본 창 비교와 상세 해설]({{ "/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/#window-purpose" | relative_url }})에서 길이·hop·FFT 길이의 역할을 구분한다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: How the STFT notebook builds tensor shapes and plot axes</summary>

Spectral-analysis notebook의 핵심 연산은 다음 순서다.

```python
frames = np.lib.stride_tricks.as_strided(
    signal,
    shape=(n_frames, frame_size),
    strides=(signal.strides[0] * hop_size, signal.strides[0]),
    writeable=False,
)
windowed = frames * window[None, :]
X = np.fft.rfft(windowed, n=n_fft, axis=1)
mag = np.abs(X).T
phase = np.angle(X).T
```

1. 먼저 `n_frames = 1 + (len(signal) - frame_size) // hop_size`로 tail을 버리는 frame 수를 구한다. 이 구현은 1-D contiguous input, `len(signal) >= frame_size`, 양의 hop, `n_fft >= frame_size`를 전제로 한다. `as_strided` 결과를 `writeable=False`로 둔 이유는 원본 memory를 겹쳐 보는 view를 실수로 수정하지 않기 위해서다.
2. `frames`의 첫 축은 시간 frame, 둘째 축은 한 frame 안의 sample이다. `hop_size`만큼 시작점을 옮기므로 인접 frame은 겹칠 수 있다.
3. `window[None, :]`는 모든 frame에 같은 window를 broadcast한다. 이 곱이 frame 경계의 갑작스러운 절단을 줄인다.
4. `rfft(..., axis=1)`은 각 frame의 sample 축만 변환한다. Real input이므로 output frequency 수는 `n_fft // 2 + 1`이다.
5. `.T` 뒤 `mag`와 `phase`의 shape는 `[frequency_bin, frame]`이다. Transpose만으로 물리 단위가 생기지는 않는다. Notebook은 frequency를 $$f_k=kf_s/N_{\mathrm{FFT}}$$로 만들고, frame time을 $$(mH+L/2)/f_s$$로 두며, `imshow(..., extent=[t_0,t_{M-1},f_0,f_{K-1}], origin="lower")`를 사용해 가로축을 초, 세로축을 Hz로 표시한다. Sample index의 정확한 양끝 중점은 $$(mH+(L-1)/2)/f_s$$이므로 notebook convention과는 반 sample 차이가 있다.
6. `mag`는 `abs(X)`, `phase`는 `angle(X)`에서 따로 읽지만 둘 다 같은 complex array `X`에서 나온다. 둘 중 하나가 다른 하나의 좌표는 아니다.

뒤의 `librosa.stft` 예제는 `center=True`를 사용하므로 양끝 padding이 포함된다. 앞의 수동 함수가 tail을 버리는 frame 수 공식과 결과 shape가 다른 이유는 FFT 자체가 아니라 framing policy다.

</details>

### 2.5 Log-Mel은 두 번의 서로 다른 압축을 포함한다

Mel spectrogram의 전형적인 계산은 다음 두 단계다.

$$
M[m,b]=\sum_k H_b[k]\lvert S[m,k]\rvert^2,
\qquad
L[m,b]=\log(\max(M[m,b],\epsilon)).
$$

첫 식은 여러 Hz bin을 Mel band로 가중 합해 주파수축을 줄인다. 둘째 식은 값의 dynamic range를 줄인다. **주파수 집계와 log 압축은 같은 연산이 아니다.** Mel feature는 ASR에서 유용할 수 있지만, 여러 spectrum이 같은 band sum을 만들 수 있으므로 원래 complex STFT를 일반적으로 유일하게 복원할 수 없다.

**Window는 시간 가중치, Mel은 주파수 집계, log는 값의 scale 변환이다.** Mel을 쓰는 목적은 세부 Hz bin을 모두 따로 다루기보다 지각적 주파수 간격에 따른 대역별 패턴을 특징으로 표현하는 데 있다. 예제의 257 power bins를 80 bands로 줄인 뒤 log를 취해도 80개 값이다. 단일 필터의 가중치 [0.5, 1, 0.5]와 power [1, 4, 9]의 내적은 9이며, log는 이 집계값에 나중에 적용한다. Phase는 이미 magnitude/power를 취할 때 사라지고, Mel은 주파수 세부 구조를 추가로 줄일 수 있다. [Mel 원본 그림·계산·정보 손실의 증명]({{ "/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/#mel-purpose" | relative_url }})에서 확인할 수 있다.

MFCC는 log-Mel 값에 DCT를 적용해 spectral envelope를 낮은 차수에 모은다. Harmonic 간격과 vocal-tract envelope를 분리해 읽는 데 유용하지만, phase와 세밀한 bin 정보를 복원하는 표현은 아니다.

<details markdown="block">
<summary markdown="span">Figure Analysis: Reading waveform, spectrum, spectrogram, and Mel panels</summary>

1. Waveform은 가로축이 시간, 세로축이 sample amplitude다. 큰 진폭만으로 특정 주파수를 확정하지 않는다.
2. Magnitude spectrum은 분석 구간 전체의 주파수 성분 크기를 보여 주지만, 시간별 발생 위치를 직접 표시하지 않는다. 복소 계수 전체의 가역성과는 다른 문제다.
3. Spectrogram은 가로축 시간, 세로축 frequency, 색으로 magnitude·power·dB 중 하나를 나타낸다. Colorbar의 기준과 log 여부를 먼저 확인한다.
4. Mel spectrogram은 세로축을 Mel band로 바꾼다. 고주파에서 여러 Hz bin이 넓은 band로 합쳐질 수 있다.
5. Phase map은 magnitude가 거의 0인 곳에서 불안정하다. 강한 magnitude가 있는 영역과 함께 해석한다.

Notebook 그림을 읽을 때는 `sampling rate`, `n_fft`, `win_length`, `hop_length`, `center`, window 종류, power 지수와 dB reference를 먼저 기록한다. 설정이 다르면 같은 음원도 다른 shape와 색 범위를 갖는다.

</details>

## 3. ASR 평가와 CTC 정렬

### 3.1 WER는 정답 길이로 정규화한 편집 거리다

Word error rate(WER)는 정답 단어열을 예측 단어열로 바꾸는 최소 치환·삭제·삽입 횟수를 정답 단어 수로 나눈 값이다.

$$
\mathrm{WER}=\frac{S+D+I}{N}
$$

여기서 $$S$$는 substitution, $$D$$는 deletion, $$I$$는 insertion, $$N$$은 정답 단어 수다. 네 값은 모두 단어 수이며 WER는 무차원이다. 삽입이 많으면 $$S+D+I>N$$이 될 수 있으므로 WER는 1을 넘을 수 있다. $$N=0$$인 빈 정답에서는 식이 정의되지 않으므로 평가 규칙을 따로 정해야 한다.

### 3.2 음향 frame과 문자 수는 같지 않다

음성 feature는 $$T$$개의 frame을 만들고 정답은 $$U$$개의 token을 가진다. 보통 $$T>U$$이며 어느 frame이 어느 token에 대응하는지 정답에 없다. CTC는 blank $$\epsilon$$을 추가하고, 경로에서 **연속 중복을 먼저 합친 뒤 blank를 제거**한다.

```text
l ε l  -> ll
l l    -> l
```

따라서 정답에 연속된 같은 token이 있으면 두 token 사이를 분리할 blank frame이 필요하다.

### 3.3 Frame 확률, path 확률, sequence 확률, loss를 구분한다

Encoder logit은 softmax를 거쳐 frame별 token 분포가 된다.

$$
p_t(k\mid X)=\frac{e^{\ell_{t,k}}}{\sum_j e^{\ell_{t,j}}}.
$$

경로 하나의 확률은 frame별 선택 확률의 곱이다. 같은 정답으로 collapse되는 서로 다른 경로는 서로 배타적이므로 더한다.

$$
P_{\mathrm{CTC}}(y\mid X)
=\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid X),
\qquad
\mathcal L_{\mathrm{CTC}}=-\log P_{\mathrm{CTC}}(y\mid X).
$$

정답 확률이 커질수록 loss는 작아진다. 경로 확률의 합 자체를 최소화하는 것이 아니다.

### 3.4 Forward DP는 확률이 생기는 과정을 숨기지 않는다

<figure id="source-ctc-review">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-03-p35.png" | relative_url }}" alt="네 frame의 forward probability를 합산한 원본 CTC lattice" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf#page=35" | relative_url }}">lecture PDF, p. 35</a>.</figcaption>
</figure>

가로축은 네 frame, 세로축은 blank를 끼운 정답 상태다. 마지막 `b`와 마지막 blank에 도착한 확률 0.2835와 0.1308을 합하면 정답 `ab`의 확률 0.4143이다. 중간 상태의 값은 그 상태로 끝나는 여러 경로의 누적 합이다. 아래의 더 작은 보강 예제도 같은 규칙으로 계산된다.

원본 그림 오른쪽의 합산식에 적힌 `0.1038`은 `0.1308`의 오기다. Trellis의 마지막 blank 값과 일치하는 계산은 `0.2835 + 0.1308 = 0.4143`이다.

정답 `AB`를 $$z=(\epsilon,A,\epsilon,B,\epsilon)$$으로 확장한다. $$\alpha_{t,s}$$는 frame $$t$$까지 처리하고 상태 $$s$$에서 끝나는 **유효 부분 경로 확률의 합**이다. 각 칸은 이전의 stay, 한 칸 전진, 조건부 두 칸 건너뛰기에서 들어온 합에 현재 frame 확률을 곱한다.

세 frame의 분포를 다음처럼 두자.

| Token | $$t=1$$ | $$t=2$$ | $$t=3$$ |
|---|---:|---:|---:|
| $$\epsilon$$ | 0.2 | 0.3 | 0.2 |
| $$A$$ | 0.6 | 0.3 | 0.2 |
| $$B$$ | 0.2 | 0.4 | 0.6 |

`AB`로 collapse되는 경로는 `εAB`, `AεB`, `AAB`, `ABε`, `ABB`다. 확률을 더하면

$$
0.036+0.108+0.108+0.048+0.144=0.444
$$

이고 loss는 $$-\ln0.444\approx0.81193$$이다. Forward DP의 마지막 `B` 상태는 0.396, 마지막 blank 상태는 0.048이며 둘의 합도 0.444다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/ctc-forward-ab-trellis.svg" | relative_url }}" alt="정답 AB의 CTC forward trellis. 세 frame과 epsilon, A, epsilon, B, epsilon의 다섯 상태가 표시되며 마지막 B 상태 0.396과 마지막 blank 상태 0.048을 더해 정답 확률 0.444를 얻는다." loading="lazy">
  <figcaption>가로축은 frame, 세로축은 blank가 삽입된 정답 상태다. 마지막 열만 보는 것이 아니라 각 칸에서 들어오는 경로 합에 현재 frame 확률을 곱하는 순서로 읽는다.</figcaption>
</figure>

그림에서 $$t=3$$의 `B` 칸으로는 `A`에서 두 칸 건너오는 경로, 가운데 blank에서 한 칸 전진하는 경로, 이전 `B`에 머무는 경로가 들어온다. 세 기여가 각각 0.144, 0.108, 0.144이고 합이 0.396이다. 끝 blank의 0.048은 이미 `B`를 출력한 뒤 blank를 낸 별도 경로다. 두 terminal state를 더해야 `AB`를 만드는 다섯 경로가 모두 포함된다.

<details markdown="block">
<summary markdown="span">Derivation: Why the CTC forward recurrence gives the path sum</summary>

도착 상태가 blank가 아니고 두 칸 앞 token과 다를 때만 skip을 허용하면 recurrence는 다음과 같다.

$$
\alpha_{t,s}=p_t(z_s\mid X)
\left[
\alpha_{t-1,s}+\alpha_{t-1,s-1}
+\mathbf 1[s\ge3,\ z_s\ne\epsilon,\ z_s\ne z_{s-2}]\alpha_{t-1,s-2}
\right].
$$

1-based state index에서 초기값은 $$\alpha_{1,1}=p_1(\epsilon\mid X)$$, $$\alpha_{1,2}=p_1(y_1\mid X)$$이며 나머지는 0이다. 유효 범위를 벗어난 $$\alpha$$도 0으로 둔다.

같은 상태에 모인 이전 경로들은 이후에 같은 전이 선택지를 가진다. 따라서 경로 목록 대신 확률 합 하나만 보관해도 된다. 덧셈은 서로 다른 이전 경로 중 하나가 발생할 확률을 모으고, 현재 token 확률과의 곱셈은 그 경로 뒤에 현재 선택을 붙인다.

두 칸 건너뛰기를 반복 label에 허용하면 `AA`의 두 `A`를 blank 없이 연결하게 된다. 그러나 CTC collapse는 붙어 있는 같은 token을 하나로 합치므로 잘못된 경로다. 이 제한이 반복 label의 의미를 보존한다.

마지막에는 $$\alpha_{T,S-1}+\alpha_{T,S}$$를 읽는다. 마지막 label에서 끝나거나 그 뒤 blank에서 끝나는 두 경우가 모두 정답을 완성하기 때문이다. 이 계산은 반복 갱신이 어떤 극한에 수렴하는 과정이 아니라, 유한한 $$T\times S$$ 격자에서 모든 유효 경로를 정확히 묶는 계산이다.

</details>

### 3.5 Greedy와 beam search의 차이

**Greedy는 현재 후보 하나에서 최선의 token을 고르고, beam search는 여러 후보를 누적 점수로 비교한다.** 둘 다 학습 이후의 디코딩 방식이다. 작성자 두-token 예제에서 첫 선택 `A` 0.6, `B` 0.4에 대해 다음 최선의 확률이 각각 0.51과 0.9라면, greedy의 `AC`는 **0.306**, 두 후보를 유지한 beam의 `BC`는 **0.36**이다. 이 예제는 두 token 뒤 EOS 확률 1, 외부 LM·길이 보정 없음으로 고정한다. [전체 조건부 분포와 선택 과정]({{ "/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/#autoregressive-greedy-beam" | relative_url }})에서 비교할 수 있다.

**CTC에서는 가장 좋은 경로 하나와 경로 확률의 합이 가장 큰 문자열도 다르다.** 두 frame 모두 `(blank, a, b) = (0.5, 0.4, 0.1)`이면 greedy는 `blank,blank` 0.25를 골라 빈 문자열을 낸다. 하지만 `a`의 확률은 `a,a` 0.16, `a,blank` 0.20, `blank,a` 0.20의 합인 **0.56**이다. 한 경로 안에서는 곱하고, 같은 출력으로 접히는 경로끼리는 더한다. 이 합산은 일반적인 후보 유지와 별개의 연산이다.

CTC prefix beam search는 문자열 prefix마다 blank/non-blank 종료 확률을 분리해 합산한 뒤 상위 후보를 남긴다. 유한 beam은 근사이며, prefix beam의 폭 1도 프레임별 greedy와 일반적으로 같지 않다. 외부 LM을 결합하면 음향 점수와 문장 점수의 scale, length bonus를 함께 확인한다. [강의 p.40의 경로 병합 그림과 계산 표]({{ "/study/speech-and-audio-recognition/lecture-03-automatic-speech-recognition/#speech-03-p40" | relative_url }})는 이 차이를 보여 준다.

## 4. Tokenization, LAS, RNN-T, and Conformer

### 4.1 BPE는 출력 단위를 학습한다

BPE는 corpus에서 자주 인접한 token pair를 반복해서 합친다. Training에서 얻은 merge 순서를 저장하고, inference에서는 새 문장에 같은 순서를 적용한다. 새 문장을 볼 때 pair 빈도를 다시 세어 merge 규칙을 바꾸지 않는다.

Character보다 긴 subword는 출력 길이 $$U$$를 줄일 수 있다. 그러나 vocabulary $$V$$가 커져 output softmax와 joint logit 비용이 늘 수 있다. 따라서 subword는 항상 계산량을 줄인다는 단일 결론보다 $$T$$, $$U$$, $$V$$를 함께 봐야 한다.

### 4.2 Attention은 출력 단계마다 필요한 입력 위치를 다시 고른다

LAS의 attention은 encoder state $$h_1,\ldots,h_T$$를 한 벡터로 고정하지 않는다. 출력 단계 $$u$$마다 이전 decoder state $$s_{u-1}$$와 각 입력 state의 관련도를 계산한다.

$$
e_{u,t}=\operatorname{score}(s_{u-1},h_t),\qquad
a_{u,t}=\frac{\exp(e_{u,t})}{\sum_{j=1}^{T}\exp(e_{u,j})}
$$

$$
c_u=\sum_{t=1}^{T}a_{u,t}h_t
$$

같은 출력 단계에서 $$\sum_t a_{u,t}=1$$이며, $$c_u$$는 입력 state의 가중합이다. Attention weight는 입력 위치를 결합하는 계수이지 다음 단어의 출력 확률이 아니다. LAS decoder는 이 context와 출력 prefix를 사용해 다음 token을 예측한다.

### 4.3 CTC, LAS, RNN-T는 정렬과 출력 이력을 다르게 처리한다

세 방법의 공통 문제는 **긴 음향 frame열과 짧은 전사열 사이의 정렬을 시간별 정답 없이 학습하는 것**이다. CTC는 정답 전사가 되는 frame 경로를 합한다. LAS는 이전 출력과 attention context로 다음 token을 만들고, RNN-T는 출력 이력을 조건으로 삼으면서 시간·출력 두 축의 정렬 경로를 합한다. 이는 CTC를 LAS가, LAS를 RNN-T가 차례로 대체했다는 뜻이 아니라 같은 문제를 서로 다른 확률 모델로 푸는 관계다.

| 기준 | CTC | LAS | RNN-T |
|---|---|---|---|
| 출력 이력 | 기본 frame 분포에 직접 조건화하지 않음 | 이전 token을 조건으로 생성 | Prediction network가 prefix를 표현 |
| 정렬 | collapse되는 frame 경로 합 | 출력마다 입력에 attention | 시간·token lattice 경로 합 |
| 진행 기호 | blank 제거 | EOS로 종료 | blank는 시간 진행, token은 출력 진행 |
| Streaming | encoder·decoder 지연 조건에 따름 | full attention·bidirectional listener면 offline | causal/chunk encoder일 때 가능 |
{: .reference-candidate-table}

<a href="{{ "/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/#speech-04-p15" | relative_url }}">LAS 원본 그림</a>에서는 Listener가 음향 표현을 만들고, Attend가 현재 출력에 필요한 입력을 모으며, Speller가 이전 token을 받아 다음 token을 낸다. <a href="{{ "/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/#speech-04-p37" | relative_url }}">RNN-T lattice</a>에서는 같은 출력 prefix를 유지하며 시간을 넘기는 경로와 새 token을 내는 경로를 구분해 읽는다. 두 그림 모두 출력 이력을 쓰지만, 정렬을 표현하는 방식은 다르다.

LAS의 autoregressive 확률은 다음처럼 이전 정답 또는 생성 prefix에 조건화된다.

$$
P(y\mid X)=\prod_{u=1}^{U+1}P(y_u\mid y_{<u},X).
$$

학습에서는 teacher forcing으로 정답 prefix를 사용할 수 있지만, 추론에서는 모델이 방금 생성한 prefix를 사용한다. 이 차이는 error accumulation의 원인이 될 수 있다.

RNN-T의 상태 $$(t,u)$$에서 blank를 선택하면 $$(t+1,u)$$로 가고, 다음 token을 선택하면 $$(t,u+1)$$로 간다. 같은 acoustic frame에서 여러 token을 낼 수 있다. RNN-T의 blank는 CTC처럼 collapse할 기호가 아니라 **시간축을 진행시키는 전이**다.

### 4.4 Deep Speech 2와 Conformer를 구조 역할로 비교한다

Deep Speech 2는 convolution으로 local acoustic pattern과 시간 길이를 처리하고 recurrent layer로 긴 문맥을 모델링한 뒤 CTC로 정렬한다. 핵심은 **음향 표현을 만드는 신경망과 CTC 정렬 학습을 결합해 음성에서 전사로 이어지는 인식기를 학습한다**는 데 있다. CTC가 학습 목표라면 convolution·recurrent layer는 그 목표에 필요한 표현을 만드는 구조다.

Conformer의 문제의식은 넓은 문맥을 연결하는 self-attention과 가까운 시간 구간의 패턴을 처리하는 convolution이 서로 다른 강점을 가진다는 것이다. 두 연산을 한 encoder block에 결합해 장거리 관계와 국소 음향 패턴을 함께 다룬다. <a href="{{ "/study/speech-and-audio-recognition/lecture-03-automatic-speech-recognition/#speech-03-p44" | relative_url }}">원본 convolution module 그림</a>은 채널을 섞는 pointwise 연산과 시간축 이웃을 처리하는 depthwise convolution을 구분해 읽는다. 이 구조 설명만으로 모든 데이터에서 성능이 높다고 결론내릴 수는 없다.

Conformer의 subsampling은 입력 frame 수를 줄여 이후 attention의 시간축 비용을 낮춘다. 예를 들어 stride 2를 두 번 적용하면 길이는 대략 $$T/4$$가 된다. 실제 출력 길이는 kernel, padding과 홀수 길이 처리에 따라 달라진다. Convolution module은 짧은 음향 패턴과 위치 인접성을 처리하지만, 그것만으로 streaming을 보장하지 않는다. Attention context와 convolution padding이 미래 frame을 보는지 확인해야 한다.

따라서 **Conformer와 CTC는 양자택일 대상이 아니다.** Conformer는 encoder 구조이고 CTC는 정렬·학습 목표다. Conformer 원 논문의 ASR 구성은 encoder를 LSTM decoder 기반 transducer와 결합한다. 다른 학습 목표와의 결합 가능성까지 원 논문의 실험 결과로 간주해서는 안 된다.

## 5. Self-supervised speech representation learning

### 5.1 Self-supervision은 입력에서 target을 만든다

Supervised ASR은 waveform과 transcript 쌍이 필요하다. Self-supervised learning은 transcript가 없는 음성에서도 입력 일부를 가리고 나머지 문맥으로 target을 예측하게 만든다. 여기서 masking은 입력 표현의 일부를 감추어 문맥으로 target을 예측하게 하는 훈련 절차다.

### 5.2 wav2vec 2.0

wav2vec 2.0의 흐름은 다음과 같다.

1. CNN feature encoder가 waveform을 latent sequence $$z_t$$로 바꾼다.
2. 일부 latent position을 가려 Transformer가 contextual vector $$c_t$$를 만든다.
3. 원래 $$z_t$$는 product quantizer를 거쳐 discrete code의 결합인 $$q_t$$를 만든다.
4. 가린 위치에서 $$c_t$$가 정답 $$q_t$$를 distractor와 구별하도록 contrastive loss를 계산한다.
5. Codebook 사용이 한쪽으로 무너지는 것을 줄이기 위해 diversity objective를 함께 둔다.

Contrastive target은 waveform sample이나 text token이 아니라 **가린 위치에 대응하는 quantized latent vector**다. Fine-tuning에서는 CTC output을 붙여 labeled ASR에 적응시킬 수 있다.

<a href="{{ "/study/speech-and-audio-recognition/lecture-05-self-supervised-learning/#speech-05-p31" | relative_url }}">원본 학습 그림</a>의 갈림길이 중요하다. CNN 출력에서 한 경로는 가려진 채 Transformer로 들어가고, 다른 경로는 가리지 않은 특징으로 정답 target을 만든다. 문맥 표현 $$c_t$$가 같은 위치의 $$q_t$$를 다른 후보보다 잘 골라야 하므로, 정답 전사 없이도 주변 음성에서 유용한 정보를 학습할 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: wav2vec 2.0 contrastive objective</summary>

가린 위치 $$t$$의 context $$c_t$$, 같은 위치의 positive target $$q_t$$, distractor를 포함한 후보 집합 $$Q_t$$를 둔다. Cosine similarity와 temperature $$\kappa$$를 사용한 masked-position loss는 다음과 같다.

$$
\mathcal L_m(t)=-\log
\frac{\exp(\left(\operatorname{sim}(c_t,q_t)/\kappa\right))}
{\sum_{\tilde q\in Q_t}\exp(\left(\operatorname{sim}(c_t,\tilde q)/\kappa\right))}
$$

Positive similarity가 distractor보다 커질수록 분수의 값이 1에 가까워지고 loss가 작아진다. Product quantizer가 $$G$$개 codebook에서 각각 $$V$$개 entry 중 하나를 고르면 가능한 조합의 상한은 $$V^G$$다. Diversity term은 일부 entry만 계속 선택되는 collapse를 줄이지만, 모든 조합의 사용이나 음소와의 일대일 대응을 보장하지 않는다.

</details>

### 5.3 HuBERT

HuBERT는 MFCC 같은 기존 feature를 offline clustering해 pseudo-label $$y_t$$를 만든다. 가린 구간의 cluster label을 문맥에서 맞히고, 학습한 representation으로 다시 clustering해 target을 개선할 수 있다. wav2vec 2.0의 online learned codebook과 HuBERT의 offline cluster target은 같은 것이 아니다.

<a href="{{ "/study/speech-and-audio-recognition/lecture-05-self-supervised-learning/#speech-05-p46" | relative_url }}">HuBERT 원본 그림</a>에서는 clustering으로 만든 label 경로와 가린 입력을 처리하는 경로를 나누어 읽는다. 가령 정답이 cluster 17이라면 masked classifier가 17에 높은 확률을 주도록 학습한다. 17이 특정 글자나 정확한 음소 이름을 뜻할 필요는 없다. 이런 pseudo-label을 문맥으로 예측하는 동안 음향·언어적 구조를 표현에 담도록 유도하는 것이 핵심이다.

| 기준 | wav2vec 2.0 | HuBERT |
|---|---|---|
| Target 생성 | learned product quantization | offline clustering label |
| 주요 loss | contrastive classification + diversity | masked cluster classification |
| Collapse 관리 | codebook diversity가 중요 | target cluster 품질·분포가 중요 |
| Downstream | labeled data로 CTC 등 fine-tuning | labeled data로 ASR 등 fine-tuning |
{: .reference-candidate-table}

### 5.4 사전학습 논문과 ASR 구조는 어떻게 이어지는가

wav2vec 2.0과 HuBERT는 모두 **전사 라벨 부족**을 다룬다. wav2vec 2.0은 함께 학습하는 quantizer의 target을 후보 사이에서 구별하고, HuBERT는 별도로 만든 cluster label을 예측한다. 공통점은 가린 음성의 문맥을 학습한다는 것이며, 차이는 정답을 만드는 방법과 loss에 있다. HuBERT를 wav2vec 2.0의 모든 구성 요소를 그대로 둔 개선판으로 읽으면 이 차이가 사라진다.

그 뒤 ASR fine-tuning에서는 음향 표현을 실제 전사 token에 연결해야 한다. 이때 CTC 같은 목표를 사용할 수 있다. 반면 Conformer는 표현을 계산하는 encoder의 설계에 관한 선택이다. **사전학습은 무엇으로 먼저 배울지, encoder는 정보를 어떻게 처리할지, ASR 목표는 전사와 어떻게 정렬할지**를 정한다. 서로 관련되지만 같은 축의 경쟁 방법은 아니다.

## 6. 혼동하기 쉬운 기호와 표현

### 6.1 Masked prediction과 attention mask

Masked prediction은 입력 표현의 일부를 감추고 그 위치의 target을 예측하도록 학습한다. Attention mask는 padding이나 미래 위치를 보지 못하도록 attention score를 제한한다. 전자는 학습 문제를 만드는 방법이고, 후자는 정보 접근 범위를 정하는 방법이다.

### 6.2 Blank 두 종류

CTC blank는 frame path를 collapse할 때 제거된다. RNN-T blank는 출력 prefix를 유지하며 acoustic time을 진행시킨다. 둘 다 전사에 남지 않지만 상태 전이 규칙은 다르다.

### 6.3 Phase와 imaginary part

Imaginary part는 phase 그 자체가 아니다. Complex value $$a+jb$$의 phase는 $$\operatorname{atan2}(b,a)$$다. Real·imaginary 두 좌표는 magnitude와 phase를 함께 결정한다.

## 7. 문제를 푸는 순서

### 7.1 Signal과 spectrum 문제

1. 시간 단위와 sampling rate를 확인한다.
2. 연속/이산, 주기/비주기, finite/infinite 중 어떤 모델인지 정한다.
3. Fourier convention과 normalization을 기록한다.
4. Nyquist 조건을 최고 주파수에 대입한다.
5. DFT bin은 $$k f_s/N$$과 음의 주파수 wrap을 함께 읽는다.
6. Magnitude와 phase가 모두 필요한 복원 문제인지 확인한다.

### 7.2 CTC forward 문제

1. 정답 사이에 blank를 넣어 확장열 $$z$$를 만든다.
2. 첫 frame에서는 첫 blank와 첫 label만 초기화한다.
3. Stay, 한 칸 전진, 허용된 두 칸 skip을 구분한다.
4. 이전 경로 합에 현재 frame 확률을 곱한다.
5. 마지막 label과 마지막 blank 상태를 더한다.
6. 음의 로그를 취해 loss로 바꾼다.

## 8. 자주 생기는 오해

| 오해 | 정확한 해석 |
|---|---|
| FFT는 DFT보다 정확한 transform이다. | FFT는 같은 DFT를 더 적은 계산으로 구한다. |
| Log를 씌우면 작은 값이 분류 가능해진다. | Dynamic range는 줄지만 분류 성능은 task와 model에서 검증해야 한다. |
| Mel scale은 log amplitude다. | Mel은 frequency-axis mapping이고 log amplitude는 별도 값 변환이다. |
| CTC DP 값은 반복 계산하며 수렴한다. | 고정 확률표의 유효 경로 합을 유한 격자에서 정확히 계산한다. |
| Blank는 silence다. | CTC/RNN-T의 정렬 기호이며 실제 무음과 일대일 대응하지 않는다. |
| Complex spectrum의 imaginary part가 phase다. | Phase는 real·imaginary 좌표를 함께 사용해 계산한다. |

## 마지막 핵심 정리

- Sampling은 시간축, quantization은 진폭축을 이산화한다. Nyquist 위반 뒤에는 원주파수 구분을 사후 처리로 되찾을 수 없다.
- DFT는 변환 정의, FFT는 계산 알고리즘이다. STFT는 시간 위치를 얻지만 window·hop·phase·overlap-add 조건을 함께 관리해야 한다.
- Mel filterbank의 주파수 집계와 log의 값 압축은 별도 연산이며, ASR feature와 waveform 복원 표현의 목적도 다르다.
- CTC는 frame 확률을 곱해 path 확률을 만들고, 같은 전사로 collapse되는 path를 더한다. Forward DP는 이 합을 재사용한다.
- LAS는 이전 token과 attention context로 다음 token을 생성하고, RNN-T는 acoustic time과 output prefix를 두 축으로 분리한다.
- Deep Speech 2와 Conformer는 음향 표현을 만드는 구조로 비교한다. Conformer의 국소·전역 문맥 결합은 CTC나 RNN-T의 정렬 규칙과 별도 역할이다.
- wav2vec 2.0과 HuBERT는 transcript 없이 target을 만들지만, learned quantization과 offline clustering이라는 target 생성 방식이 다르다.

## Study Guide

- **신호 처리:** Sampling과 quantization의 축을 구분하고, Nyquist 위반 예제·DFT bin·STFT shape를 직접 계산한다.
- **ASR:** WER의 $$S,D,I,N$$을 세고, CTC `AB` 경로 합과 forward table을 계산한다. Attention context, LAS의 autoregression, RNN-T의 blank/token 전이를 말로 설명한다.
- **표현 학습:** wav2vec 2.0의 masked context·quantized target·contrastive loss와 HuBERT의 offline cluster target을 구분한다.
- **비교 연습:** DFT/FFT, spectrum/spectrogram, Mel/log, CTC blank/RNN-T blank, CTC/LAS/RNN-T, Deep Speech 2/Conformer를 각각 한 문단으로 설명한다.

## 복습 질문

<details markdown="block">
<summary>1. 8 kHz sampling에서 7 kHz 성분이 1 kHz로 보이는 이유는 무엇인가?</summary>

답변: Discrete-time complex exponential은 sampling rate의 정수배만큼 떨어진 주파수를 같은 sample로 만든다. 7 kHz는 8 kHz를 한 번 빼면 −1 kHz이며, real zero-phase cosine에서는 −1 kHz와 +1 kHz가 같은 표본열을 만든다. DFT가 틀린 것이 아니라 sampling 전에 원주파수 구분이 사라진 것이다.

</details>

<details markdown="block">
<summary>2. FFT와 STFT는 무엇이 다른가?</summary>

답변: FFT는 한 유한 sequence의 DFT를 빠르게 계산하는 알고리즘이다. STFT는 긴 신호를 겹치는 짧은 frame으로 나누고 각 frame에서 DFT를 계산하는 분석 방법이다. STFT 구현 안에서 FFT를 사용할 수 있지만 두 용어는 같은 개념이 아니다.

</details>

<details markdown="block">
<summary>3. Mel spectrogram을 waveform 복원에 바로 쓰기 어려운 이유는 무엇인가?</summary>

답변: Mel filterbank는 여러 Hz bin의 power를 band별로 합치고, log를 적용하면 값의 dynamic range도 압축된다. 이 과정은 phase를 포함하지 않으며 서로 다른 spectrum이 같은 Mel 값이 될 수 있다. 따라서 별도의 phase·decoder·원래 spectrum 경로 없이 원 waveform을 유일하게 복원할 수 없다.

</details>

<details markdown="block">
<summary>4. CTC forward DP의 덧셈과 곱셈은 각각 무엇을 뜻하는가?</summary>

답변: 덧셈은 같은 상태에 도달하는 서로 배타적인 이전 경로의 확률을 모은다. 곱셈은 그 부분 경로 뒤에 현재 frame의 token 선택이 이어질 확률을 계산한다. 마지막 label과 blank 상태의 합이 정답 sequence 확률이고, 음의 로그가 CTC loss다.

</details>

<details markdown="block">
<summary>5. LAS와 RNN-T에서 autoregressive 정보는 어디에 들어가는가?</summary>

답변: LAS decoder는 이전 token과 attention context를 사용해 다음 token을 예측한다. RNN-T prediction network는 출력 prefix를 표현하고 joint network가 acoustic encoder state와 결합한다. RNN-T에서 token 전이는 prefix를 늘리고 blank 전이는 acoustic time을 늘린다.

</details>

<details markdown="block">
<summary>6. wav2vec 2.0과 HuBERT의 target은 어떻게 다른가?</summary>

답변: wav2vec 2.0은 learned product quantizer가 만든 quantized latent vector를 contrastive target으로 사용한다. HuBERT는 offline clustering이 만든 discrete pseudo-label을 가린 위치에서 예측한다. 둘 다 masked prediction이지만 target 생성과 loss가 다르다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2: Digital Signal Processing I</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2 Lab: FFT, STFT, Mel, and Cepstrum</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 3: Automatic Speech Recognition I</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 4: Automatic Speech Recognition II</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 5: Self-Supervised Learning</a></li>
</ul>

## Notebooks and Interactive Material

<ul>
  <li><a href="{{ "/assets/materials/study/speech-spectral-analysis/sar-lec01-public.ipynb" | relative_url }}" download>SAR Lec01 public notebook</a> — FFT, STFT, Mel, cepstrum, and MFCC.</li>
  <li><a href="{{ "/assets/materials/study/speech-spectral-analysis/aliasing-dtfs-n8.html" | relative_url }}" target="_blank" rel="noopener">N=8 aliasing and DTFS demo</a> — sampled points and continuous paths.</li>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/01-bpe-basics.ipynb" | relative_url }}" download>BPE basics notebook</a></li>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/02-ctc-inference.ipynb" | relative_url }}" download>CTC inference notebook</a></li>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/03-rnnt-inference.ipynb" | relative_url }}" download>RNN-T inference notebook</a></li>
</ul>

## References

- <a href="https://www.cs.toronto.edu/~graves/icml_2006.pdf" target="_blank" rel="noopener">Graves et al.: Connectionist Temporal Classification</a>
- <a href="https://proceedings.mlr.press/v48/amodei16.html" target="_blank" rel="noopener">Amodei et al.: Deep Speech 2</a>
- <a href="https://arxiv.org/abs/1508.01211" target="_blank" rel="noopener">Chan et al.: Listen, Attend and Spell</a>
- <a href="https://arxiv.org/abs/1211.3711" target="_blank" rel="noopener">Graves: Sequence Transduction with Recurrent Neural Networks</a>
- <a href="https://arxiv.org/abs/2005.08100" target="_blank" rel="noopener">Gulati et al.: Conformer</a>
- <a href="https://arxiv.org/abs/2006.11477" target="_blank" rel="noopener">Baevski et al.: wav2vec 2.0</a>
- <a href="https://arxiv.org/abs/2106.07447" target="_blank" rel="noopener">Hsu et al.: HuBERT</a>
