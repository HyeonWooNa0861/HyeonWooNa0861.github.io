---
layout: default
date: 2026-10-15 15:17:14 +0900
title: "Speech and Audio Recognition: Midterm Review"
course: "Speech and Audio Recognition"
topic: "Digital Signals, ASR, Self-Supervised Learning, and Source Separation"
order: 10
major_topic: "Speech and Audio Processing"
keywords:
  - "Fourier Analysis"
  - "STFT"
  - "Mel Spectrogram"
  - "CTC"
  - "RNN-Transducer"
  - "Self-Supervised Learning"
  - "Source Separation"
  - "Permutation Invariant Training"
  - "TasNet"
  - "MixIT"
---

# Speech and Audio Recognition: Midterm Review

Source PDFs:

- [Lecture 2: Digital Signal Processing I]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02.pdf" | relative_url }})
- [Lecture 2 Lab: FFT, STFT, Mel, and Cepstrum]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }})
- [Lecture 3: Automatic Speech Recognition I]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }})
- [Lecture 4: Automatic Speech Recognition II]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }})
- [Lecture 5: Self-Supervised Learning]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }})
- [Lecture 6: Source Separation I]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf" | relative_url }})
- [Lecture 7: Source Separation II]({{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf" | relative_url }})

Source Notebooks:

- [SAR Lec01 public notebook]({{ "/assets/materials/study/speech-spectral-analysis/sar-lec01-public.ipynb" | relative_url }}): FFT, STFT, Mel spectrum, cepstrum, and MFCC
- [BPE basics notebook]({{ "/assets/materials/study/speech-asr-lab/01-bpe-basics.ipynb" | relative_url }}): BPE training and tokenization
- [CTC inference notebook]({{ "/assets/materials/study/speech-asr-lab/02-ctc-inference.ipynb" | relative_url }}): CTC greedy and prefix-beam decoding
- [RNN-T inference notebook]({{ "/assets/materials/study/speech-asr-lab/03-rnnt-inference.ipynb" | relative_url }}): RNN-T inference

> **핵심:** 이 범위는 소리를 숫자로 바꾸는 단계에서 시작해, 주파수 특징을 만들고, 음성을 문자로 정렬하며, label이 없는 음성에서 표현을 학습하고, 마지막에는 섞인 소리를 다시 분리하는 과정으로 이어진다. 각 단계의 질문은 다르지만 공통 원리는 같다. **입력에서 어떤 정보를 보존할지, 어떤 확률 또는 loss를 계산할지, 출력이 실제로 무엇을 뜻하는지**를 분리해서 확인해야 한다.

이 글은 현재 확보된 Lecture 2–7 원문과 spectral-analysis·ASR 실습을 종합한다. 별도의 Lecture 1 PDF는 현재 과목 폴더에 없으므로, Lecture 1의 독립 범위를 추정해서 채우지 않는다. 각 강의의 전체 유도·그림·코드 해설은 연결된 개별 노트에서 확인할 수 있다.

## 전체 흐름

| 단계 | 입력 | 핵심 연산 | 출력 | 확인할 질문 |
|---|---|---|---|---|
| 디지털화 | 연속 음압 | sampling, quantization | PCM sample열 | 시간·진폭 정보를 어떤 정밀도로 남기는가? |
| 주파수 분석 | 유한 sample열 | DFT/FFT, STFT | complex spectrum | 어느 주파수가 언제 존재하는가? |
| 지각 특징 | power spectrum | Mel filterbank, log, DCT | log-Mel, MFCC | 인식에 유용한 축약과 복원 정보 손실을 어떻게 구분하는가? |
| ASR 정렬 | 음향 frame열 | CTC, attention, RNN-T | token sequence | 길이가 다른 두 sequence를 어떻게 정렬하고 점수화하는가? |
| 표현 사전학습 | transcript 없는 음성 | masking, quantization, pseudo-label prediction | speech representation | 정답 text 없이 어떤 target을 만들 수 있는가? |
| Source separation | 혼합 음원 | mask/estimate, PIT, decoder | source별 waveform | 출력 순서가 없는 여러 source를 어떻게 복원하는가? |

이 흐름을 한 줄로 연결하면 다음과 같다.

```text
air pressure
  -> sampled waveform
  -> complex time-frequency representation
  -> acoustic representation
  -> aligned token sequence or separated waveforms
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

8 kHz로 7 kHz cosine을 sampling하면 $$8<14$$이므로 조건을 만족하지 않는다. Sample 시각 $$t_n=n/8000$$에서 zero-phase 7 kHz cosine은 1 kHz cosine과 같은 값을 만든다.

$$
\cos(2\pi\cdot7000n/8000)
=\cos(2\pi n-2\pi\cdot1000n/8000)
=\cos(2\pi\cdot1000n/8000)
$$

DFT 계산 자체는 실패하지 않는다. DFT는 주어진 sample열을 정확히 변환하지만, 이미 같은 sample이 된 1 kHz와 7 kHz 원신호를 구별할 정보는 없다. 이 문제가 aliasing이다. Bit depth 증가나 FFT 길이 증가는 잃은 구분을 복원하지 못한다.

<details markdown="block">
<summary markdown="span">Derivation: Nyquist condition from repeated discrete frequencies</summary>

Discrete-time complex exponential은 sampling rate의 정수배만큼 주파수가 달라도 같다.

$$
e^{j2\pi(f+r f_s)n/f_s}
=e^{j2\pi fn/f_s}e^{j2\pi rn}
=e^{j2\pi fn/f_s}.
$$

원래 spectrum이 $$[-f_{\max},f_{\max}]$$에 있고, 다음 복사본이 $$[f_s-f_{\max},f_s+f_{\max}]$$에 생긴다고 하자. 두 구간이 겹치지 않으려면

$$
f_{\max}<f_s-f_{\max}
$$

여야 하므로 $$f_s>2f_{\max}$$를 얻는다. 등호 경계에서는 $$+f_s/2$$와 $$-f_s/2$$가 같은 bin이 된다. 특히 phase가 $$\pi/2$$인 경계 sinusoid는 sample이 모두 0이 될 수 있으므로, 경계 성분을 허용하는 일반적인 복원에는 별도 가정이 필요하다.

</details>

## 2. Fourier 표현에서 STFT와 Mel 특징까지

### 2.1 Fourier coefficient는 basis와의 정렬 정도다

주기 신호는 harmonic basis의 합으로 표현할 수 있다. 이 글처럼 $$a_n\cos(n\omega_0t)+b_n\sin(n\omega_0t)=A_n\cos(n\omega_0t-\phi_n)$$ convention을 쓰면

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

Rectangular window는 경계 discontinuity 때문에 큰 sidelobe를 만든다. Hann window는 먼 sidelobe를 낮추지만 main lobe를 넓힌다. 따라서 window는 leakage를 없애는 버튼이 아니라 **어떤 오차를 줄이고 어떤 분해능을 희생할지 정하는 선택**이다.

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

MFCC는 log-Mel 값에 DCT를 적용해 spectral envelope를 낮은 차수에 모은다. Harmonic 간격과 vocal-tract envelope를 분리해 읽는 데 유용하지만, phase와 세밀한 bin 정보를 복원하는 표현은 아니다.

<details markdown="block">
<summary markdown="span">Figure Analysis: Reading waveform, spectrum, spectrogram, and Mel panels</summary>

1. Waveform은 가로축이 시간, 세로축이 sample amplitude다. 큰 진폭만으로 특정 주파수를 확정하지 않는다.
2. Spectrum은 분석 구간 전체의 주파수 성분을 보여 준다. 시간 위치는 읽을 수 없다.
3. Spectrogram은 가로축 시간, 세로축 frequency, 색으로 magnitude·power·dB 중 하나를 나타낸다. Colorbar의 기준과 log 여부를 먼저 확인한다.
4. Mel spectrogram은 세로축을 Mel band로 바꾼다. 고주파에서 여러 Hz bin이 넓은 band로 합쳐질 수 있다.
5. Phase map은 magnitude가 거의 0인 곳에서 불안정하다. 강한 magnitude가 있는 영역과 함께 해석한다.

Notebook 그림을 읽을 때는 `sampling rate`, `n_fft`, `win_length`, `hop_length`, `center`, window 종류, power 지수와 dB reference를 먼저 기록한다. 설정이 다르면 같은 음원도 다른 shape와 색 범위를 갖는다.

</details>

## 3. ASR의 정렬 문제와 CTC

### 3.1 음향 frame과 문자 수는 같지 않다

음성 feature는 $$T$$개의 frame을 만들고 정답은 $$U$$개의 token을 가진다. 보통 $$T>U$$이며 어느 frame이 어느 token에 대응하는지 정답에 없다. CTC는 blank $$\epsilon$$을 추가하고, 경로에서 **연속 중복을 먼저 합친 뒤 blank를 제거**한다.

```text
l ε l  -> ll
l l    -> l
```

따라서 정답에 연속된 같은 token이 있으면 두 token 사이를 분리할 blank frame이 필요하다.

### 3.2 Frame 확률, path 확률, sequence 확률, loss를 구분한다

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

### 3.3 Forward DP는 확률이 생기는 과정을 숨기지 않는다

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

### 3.4 Greedy와 beam search의 차이

Greedy decoding은 각 frame에서 가장 큰 token을 선택한 경로 하나를 collapse한다. 그러나 가장 확률이 큰 경로가 가장 확률이 큰 문자열일 필요는 없다. 한 문자열은 여러 경로의 확률을 합치기 때문이다.

Prefix beam search는 문자열 prefix마다 blank로 끝난 확률과 non-blank로 끝난 확률을 분리해 누적한다. Beam 폭이 유한하면 낮은 후보를 버리므로 근사 탐색이다. 외부 language model을 결합하면 음향 점수와 문장 점수의 scale, length bonus를 함께 확인해야 한다.

## 4. Tokenization, LAS, RNN-T, and Conformer

### 4.1 BPE는 출력 단위를 학습한다

BPE는 corpus에서 자주 인접한 token pair를 반복해서 합친다. Training에서 얻은 merge 순서를 저장하고, inference에서는 새 문장에 같은 순서를 적용한다. 새 문장을 볼 때 pair 빈도를 다시 세어 merge 규칙을 바꾸지 않는다.

Character보다 긴 subword는 출력 길이 $$U$$를 줄일 수 있다. 그러나 vocabulary $$V$$가 커져 output softmax와 joint logit 비용이 늘 수 있다. 따라서 subword는 항상 계산량을 줄인다는 단일 결론보다 $$T$$, $$U$$, $$V$$를 함께 봐야 한다.

### 4.2 CTC, LAS, RNN-T는 정렬과 출력 이력을 다르게 처리한다

| 기준 | CTC | LAS | RNN-T |
|---|---|---|---|
| 출력 이력 | 기본 frame 분포에 직접 조건화하지 않음 | 이전 token을 조건으로 생성 | Prediction network가 prefix를 표현 |
| 정렬 | collapse되는 frame 경로 합 | 출력마다 입력에 attention | 시간·token lattice 경로 합 |
| 진행 기호 | blank 제거 | EOS로 종료 | blank는 시간 진행, token은 출력 진행 |
| Streaming | encoder·decoder 지연 조건에 따름 | full attention·bidirectional listener면 offline | causal/chunk encoder일 때 가능 |

LAS의 autoregressive 확률은 다음처럼 이전 정답 또는 생성 prefix에 조건화된다.

$$
P(y\mid X)=\prod_{u=1}^{U+1}P(y_u\mid y_{<u},X).
$$

학습에서는 teacher forcing으로 정답 prefix를 사용할 수 있지만, 추론에서는 모델이 방금 생성한 prefix를 사용한다. 이 차이는 error accumulation의 원인이 될 수 있다.

RNN-T의 상태 $$(t,u)$$에서 blank를 선택하면 $$(t+1,u)$$로 가고, 다음 token을 선택하면 $$(t,u+1)$$로 간다. 같은 acoustic frame에서 여러 token을 낼 수 있다. RNN-T의 blank는 CTC처럼 collapse할 기호가 아니라 **시간축을 진행시키는 전이**다.

### 4.3 Deep Speech 2와 Conformer를 구조 역할로 비교한다

Deep Speech 2는 convolution으로 local acoustic pattern과 시간 길이를 처리하고 recurrent layer로 긴 문맥을 모델링한 뒤 CTC로 정렬한다. Conformer는 self-attention의 넓은 문맥과 convolution module의 local pattern 처리를 한 block 안에서 결합한다.

Conformer의 subsampling은 입력 frame 수를 줄여 이후 attention의 시간축 비용을 낮춘다. 예를 들어 stride 2를 두 번 적용하면 길이는 대략 $$T/4$$가 된다. 실제 출력 길이는 kernel, padding과 홀수 길이 처리에 따라 달라진다. Convolution module은 짧은 음향 패턴과 위치 인접성을 처리하지만, 그것만으로 streaming을 보장하지 않는다. Attention context와 convolution padding이 미래 frame을 보는지 확인해야 한다.

## 5. Self-supervised speech representation learning

### 5.1 Self-supervision은 입력에서 target을 만든다

Supervised ASR은 waveform과 transcript 쌍이 필요하다. Self-supervised learning은 transcript가 없는 음성에서도 입력 일부를 가리고 나머지 문맥으로 target을 예측하게 만든다. 이때 source-separation mask와 masked prediction을 같은 연산으로 이해하면 안 된다. 전자는 신호를 복원하기 위한 곱셈 mask일 수 있고, 후자는 representation의 일부를 학습 입력에서 감추는 훈련 절차다.

### 5.2 wav2vec 2.0

wav2vec 2.0의 흐름은 다음과 같다.

1. CNN feature encoder가 waveform을 latent sequence $$z_t$$로 바꾼다.
2. 일부 latent position을 가려 Transformer가 contextual vector $$c_t$$를 만든다.
3. 원래 $$z_t$$는 product quantizer를 거쳐 discrete code의 결합인 $$q_t$$를 만든다.
4. 가린 위치에서 $$c_t$$가 정답 $$q_t$$를 distractor와 구별하도록 contrastive loss를 계산한다.
5. Codebook 사용이 한쪽으로 무너지는 것을 줄이기 위해 diversity objective를 함께 둔다.

Contrastive target은 waveform sample이나 text token이 아니라 **가린 위치에 대응하는 quantized latent vector**다. Fine-tuning에서는 CTC output을 붙여 labeled ASR에 적응시킬 수 있다.

### 5.3 HuBERT

HuBERT는 MFCC 같은 기존 feature를 offline clustering해 pseudo-label $$y_t$$를 만든다. 가린 구간의 cluster label을 문맥에서 맞히고, 학습한 representation으로 다시 clustering해 target을 개선할 수 있다. wav2vec 2.0의 online learned codebook과 HuBERT의 offline cluster target은 같은 것이 아니다.

| 기준 | wav2vec 2.0 | HuBERT |
|---|---|---|
| Target 생성 | learned product quantization | offline clustering label |
| 주요 loss | contrastive classification + diversity | masked cluster classification |
| Collapse 관리 | codebook diversity가 중요 | target cluster 품질·분포가 중요 |
| Downstream | labeled data로 CTC 등 fine-tuning | labeled data로 ASR 등 fine-tuning |

## 6. Source Separation I: representation, loss, and phase

### 6.1 Encoder–separator–decoder

혼합 파형이 $$y[n]=\sum_{i=1}^{K}s_i[n]$$라고 하자. Encoder는 raw waveform 또는 STFT를 feature로 바꾸고, separator는 source별 mask나 직접 추정값을 만들며, decoder는 waveform으로 복원한다. 모든 separator가 mask를 출력하지는 않는다. Waveform model은 latent feature를 변환해 직접 waveform을 만들 수도 있다.

### 6.2 MA, SA, waveform loss는 비교 위치가 다르다

| Objective | 비교하는 값 | 의미 |
|---|---|---|
| Mask approximation | 예측 mask와 target mask | 비율 추정 자체를 맞춘다. |
| Signal approximation | mask를 mixture magnitude에 적용한 값과 clean magnitude | 실제 spectrum 크기 오차를 반영한다. |
| Waveform loss | iSTFT 또는 decoder 뒤 파형과 clean waveform | phase·overlap-add까지 포함한 최종 출력을 비교한다. |

같은 mask 오차라도 mixture magnitude가 큰 bin에서는 SA 오차가 더 커진다. 이는 큰 성분에 집중할 수 있다는 장점과 약한 성분이 덜 반영될 수 있다는 절충을 함께 만든다. 강의의 MA, SA, waveform 소개 순서가 세 loss를 반드시 순차로 적용하는 pipeline이라는 뜻은 아니다.

### 6.3 Magnitude가 맞아도 waveform은 틀릴 수 있다

한 complex bin의 정답이 $$S=Ae^{j\phi_S}$$이고 mixture phase를 고정한 추정이 $$\hat S=\hat A e^{j\phi_Y}$$라면 complex squared error는

$$
\lvert S-\hat S\rvert^2
=A^2+\hat A^2-2A\hat A\cos(\phi_S-\phi_Y)
$$

이다. $$\hat A=A$$여도 phase 차이가 0이 아니면 오차가 남는다. 고정 phase에서 error를 최소화하는 magnitude는 제약을 무시하면 $$A\cos(\phi_S-\phi_Y)$$다. 이 결과가 phase-sensitive target의 cosine 항을 설명한다.

![복소 STFT 한 bin에서 real 좌표와 imaginary 좌표가 함께 magnitude와 phase를 정하는 기하](/assets/images/study/speech-source-separation/complex-stft-coordinates.svg)

그림은 원점에서 점까지의 길이가 magnitude, 양의 real axis에서 잰 각도가 phase라는 뜻이다. Imaginary coordinate만 0으로 만들면 점을 실수축에 투영하므로 phase만 잃는 것이 아니라 이 예에서는 magnitude도 1에서 0.5로 바뀐다. 따라서 `real=magnitude`, `imaginary=phase`로 일대일 대응시키면 안 된다.

<details markdown="block">
<summary markdown="span">Derivation: Magnitude target under a fixed phase</summary>

$$\Delta\phi=\phi_S-\phi_Y$$로 놓고 $$\hat A$$에 대해 미분한다.

$$
E(\hat A)=A^2+\hat A^2-2A\hat A\cos\Delta\phi
$$

$$
\frac{dE}{d\hat A}=2\hat A-2A\cos\Delta\phi.
$$

따라서 unconstrained optimum은 $$\hat A^*=A\cos\Delta\phi$$다. Nonnegative magnitude만 허용하면 $$\max(0,A\cos\Delta\phi)$$ 같은 제약이 추가된다. 이는 mixture phase를 고정한 조건의 projection 결과다. Phase까지 예측할 수 있는 모델의 최적해와 같지 않다.

</details>

### 6.4 DCCRN과 FullSubNet+

DCCRN은 complex STFT의 real·imaginary 경로가 convolution과 recurrent processing에서 서로 결합되게 한다. Complex representation을 사용한다는 사실만으로 phase가 정확히 복원되는 것은 아니다. Network output, mask 적용과 loss를 함께 확인해야 한다.

FullSubNet+은 같은 noisy STFT에서 magnitude, real, imaginary 표현을 받아 full-band 문맥과 중심 주파수 주변의 sub-band 문맥을 결합한다. Full-band는 harmonic과 넓은 spectral pattern을 전달하고, sub-band는 특정 bin 주변의 시간 변화를 추적한다. Network의 최종 두 좌표는 압축된 complex mask 표현이다. 추론에서는 이를 안정화 범위 안에서 역압축한 뒤 보존된 noisy STFT에 complex multiplication하고 iSTFT로 복원한다.

<details markdown="block">
<summary markdown="span">Figure Analysis: FullSubNet+ from three input views to a complex mask</summary>

Lecture 6의 구조도는 왼쪽에서 오른쪽으로 읽는다.

1. Magnitude, real, imaginary는 서로 다른 녹음이 아니라 같은 noisy STFT의 세 표현이다.
2. 각 MulCA block은 내부 feature에서 주파수별 중요도를 조절한다. 이것은 최종 noise-removal mask가 아니다.
3. Full-band extractor는 모든 frequency의 문맥을 각 중심 bin에 전달한다.
4. Magnitude의 local unfold는 중심 bin과 주변 bin을 묶는다.
5. Concat 뒤 sub-band sequence model이 시간 변화를 처리한다.
6. 두 output은 complex mask의 real·imaginary 좌표다.
7. 역압축한 mask를 noisy STFT에 complex multiplication하고 iSTFT를 수행한다.

그림은 정보 경로를 보여 주지만 특정 metric 향상의 원인까지 단독으로 증명하지 않는다. Ablation과 동일 평가 조건을 함께 확인해야 한다.

</details>

### 6.5 SI-SNR은 전체 gain을 분리한 뒤 남은 왜곡을 잰다

Target $$s$$와 estimate $$\hat s$$의 평균 제거본을 $$\tilde s=s-\bar s$$, $$\tilde{\hat s}=\hat s-\overline{\hat s}$$로 두자. Estimate를 target 방향으로 projection한 성분과 orthogonal error로 나눈다.

$$
s_{\mathrm{target}}
=\frac{\langle\tilde{\hat s},\tilde s\rangle}{\lVert\tilde s\rVert_2^2}\tilde s,
\qquad
e_{\mathrm{noise}}=\tilde{\hat s}-s_{\mathrm{target}}
$$

$$
\mathrm{SI\text{-}SNR}
=10\log_{10}
\frac{\lVert s_{\mathrm{target}}\rVert_2^2}
{\lVert e_{\mathrm{noise}}\rVert_2^2}.
$$

작성자 검산으로 영평균 target $$s=[1,-1,1,-1]$$과 영평균 estimate $$\hat s=[2.5,-1.5,1.5,-2.5]$$를 두자. Projection coefficient는 2, target 성분은 `[2, -2, 2, -2]`, error는 `[0.5, 0.5, -0.5, -0.5]`다. Energy ratio는 $$16/1=16$$이므로 SI-SNR은 약 12.041 dB다. $$\hat s$$ 전체를 3배 해도 target과 error energy가 모두 9배가 되어 ratio 16은 유지된다. 이 scale invariance는 출력 gain 차이를 평가에서 제거한다는 뜻이며, 실제 음량 보존이 중요하지 않다는 뜻은 아니다.

평균 제거를 metric 안에서 수행하는지, 입력 전처리에서 수행하는지는 구현마다 다를 수 있다. 수치를 비교할 때는 demeaning 여부, epsilon 처리, segment 길이와 permutation 선택 조건을 함께 기록한다.

## 7. Source Separation II: output permutation and model lineage

### 7.1 Blind source separation의 두 난점

Blind source separation은 mixing process와 source identity를 거의 모르는 상태에서 여러 source를 추정한다. 첫째, network output slot 1이 어느 화자여야 하는지 고정할 수 없다. 둘째, 실제 환경에서는 source 수 $$K$$가 알려지지 않거나 시간에 따라 바뀔 수 있다.

Lecture 7의 첫 ESD 그림은 encoder 하나와 여러 mask·decoder를 놓는다. 다음 그림의 “Are these the same answer?”가 핵심이다. 정답 source의 집합은 같아도 output 순서가 다르면 slot별 loss는 큰 오차로 계산될 수 있다.

### 7.2 DPCL은 output slot 대신 affinity를 학습한다

Deep Clustering(DPCL)은 각 time-frequency bin $$i$$를 embedding $$v_i$$로 바꾸고, 두 bin이 같은 source인지 나타내는 affinity를 맞춘다. One-hot source assignment를 $$Y$$, embedding matrix를 $$V$$라 하면 대표 loss는

$$
\mathcal L_{\mathrm{DPCL}}
=\left\lVert VV^{\top}-YY^{\top}\right\rVert_F^2.
$$

$$V$$의 한 행은 **모델이 한 T–F bin에서 예측한 embedding**, $$Y$$의 한 행은 **분리된 정답 source에서 얻은 우세 source의 one-hot label**이다. $$V$$는 source 확률이나 waveform이 아니며, embedding 차원과 source 수가 같을 필요도 없다. 학습은 $$V=Y$$를 요구하지 않는다. $$VV^{\top}$$와 $$YY^{\top}$$라는 bin 사이의 관계를 맞춘다.

$$YY^{\top}$$는 두 bin이 같은 source면 1, 다르면 0이다. 예를 들어 세 bin의 정답이 A, B, A이면 첫째–셋째 관계는 1, 첫째–둘째 관계는 0이다. Source label의 열 순서를 바꿔도 이 affinity matrix는 같으므로 permutation 문제를 피한다. 학습 때는 고정된 $$Y$$로 network를 감독하지만, inference에는 $$Y$$가 없다. 예측 embedding을 k-means로 묶고 cluster별 binary mask를 만든다. 이때 cluster 수 $$K$$는 외부에서 주거나 별도로 추정해야 하므로 DPCL만으로 unknown speaker count 문제가 자동 해결되지는 않는다.

7강 9쪽의 한계는 두 가지다. **별도의 k-means 단계** 때문에 affinity 학습과 최종 waveform 복원이 하나의 end-to-end 목적함수로 연결되지 않는다. **Binary magnitude mask와 mixture phase**는 겹친 source의 연속적 기여와 source별 위상을 충분히 표현하지 못한다. 직접 reconstruction loss, soft/complex mask, waveform 모델은 서로 다른 부분을 개선하는 방향이다. PIT는 출력 순서 문제를 처리할 뿐이므로, PIT를 쓴다는 사실만으로 위상이나 source 수 문제까지 해결되지는 않는다. 행렬 예제와 complex-mask 반례는 [Lecture 7의 DPCL 해설](/study/speech-and-audio-recognition/lecture-07-source-separation-2/#3-dpcl-출력-칸-대신-같은-화자인지를-배운다)에서 확인할 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: Why the DPCL affinity target ignores speaker order</summary>

Source 순서를 바꾸는 permutation matrix를 $$P$$라고 하자. One-hot label을 $$Y'=YP$$로 다시 쓰면

$$
Y'Y'^{\top}=YPP^{\top}Y^{\top}=YY^{\top}
$$

이다. $$PP^{\top}=I$$이므로 speaker A와 B의 열 이름을 바꿔도 두 bin의 same-source 관계는 변하지 않는다. 따라서 affinity target은 output label 순서에 불변이다.

반면 embedding의 회전도 pairwise inner product를 유지할 수 있다. $$V'=VQ$$이고 $$QQ^{\top}=I$$이면 $$V'V'^{\top}=VV^{\top}$$다. DPCL이 요구하는 것은 embedding coordinate의 절대 방향이 아니라 같은 source bin이 가까운 affinity 구조를 갖는 것이다.

</details>

### 7.3 PIT는 가장 잘 맞는 permutation으로 loss를 계산한다

Permutation-Invariant Training(PIT)은 $$K$$개 예측과 $$K$$개 정답의 모든 대응 중 loss가 가장 작은 것을 선택한다.

$$
\mathcal L_{\mathrm{PIT}}
=\min_{\pi\in S_K}\sum_{i=1}^{K}\ell(\hat s_i,s_{\pi(i)}).
$$

두 화자 예에서 pairwise loss가 다음과 같다고 하자.

| Prediction | Source A | Source B |
|---|---:|---:|
| $$\hat s_1$$ | 9 | 1 |
| $$\hat s_2$$ | 2 | 8 |

고정 순서 A/B의 loss는 $$9+8=17$$이지만, 순서를 바꾸면 $$1+2=3$$이다. PIT는 3을 선택해 backpropagation한다. Output 1이 항상 특정 speaker identity를 뜻하지 않아도 separation을 학습할 수 있다.

![PIT가 source별 출력 순서의 가능한 대응을 비교하고 가장 작은 loss의 permutation을 선택하는 과정](/assets/images/study/speech-and-audio-recognition/lecture-07/slide-10.png)

그림은 아래에서 위로 `mixture -> encoder -> source별 mask -> decoder -> 여러 출력`을 먼저 읽고, 오른쪽 후보 순열을 그다음 읽는다. 오른쪽의 여러 줄은 network를 여러 번 실행한다는 뜻이 아니라 **한 번 얻은 출력과 정답의 대응을 바꿔 loss를 비교한다는 뜻**이다. 선택된 대응에서만 gradient가 계산되므로 출력 slot의 이름을 미리 고정할 필요가 없다.

모든 permutation 열거는 $$K!$$개이지만, pairwise assignment cost가 분리 가능한 경우 Hungarian algorithm 등으로 최소 matching을 다항 시간에 구할 수 있다. 일반적인 Hungarian algorithm의 표준 복잡도는 $$O(K^3)$$다. Network forward 비용과 waveform loss 계산 비용은 별도다.

### 7.4 TasNet에서 dual-path Transformer까지

| Model | Representation | Separator의 핵심 | 확인할 조건 |
|---|---|---|---|
| TasNet | learned 1-D encoder | deep recurrent separator | 짧은 learned basis와 고정 source 수 |
| Conv-TasNet | learned 1-D encoder | dilated temporal convolution network | receptive field, normalization, causal variant |
| DPRNN | learned 1-D encoder | chunk 내부와 chunk 사이의 dual-path RNN | 표준 논문 모델의 양방향 처리와 streaming variant 구분 |
| SepFormer | learned 1-D encoder | dual-path Transformer | 긴 문맥, PIT, compute·latency |
| TF-GridNet | complex STFT | frequency·time·attention 축을 교차 처리 | complex estimate와 phase 처리 |

Time-domain 계열의 성과가 STFT 자체의 표현 한계를 증명한 것은 아니다. 당시 비교 대상에는 **고정 mixture phase와 magnitude mask**라는 제약이 있었다. TF-GridNet처럼 complex STFT를 직접 추정하는 후속 방법은 STFT domain에서도 phase를 함께 다룬다.

Dual-path의 핵심은 긴 sequence를 겹치는 chunk로 나누는 것이다. Intra-chunk module은 짧은 구간 내부를 처리하고, inter-chunk module은 같은 chunk 위치를 여러 구간에 걸쳐 연결한다. 이 구조는 문맥 경로를 짧게 만들지만, 표준 DPRNN 논문의 bidirectional block을 그대로 사용하면 미래 chunk가 필요하다. 별도 causal design 없이 `streaming-ready`라고 단정하지 않는다.

<details markdown="block">
<summary markdown="span">Figure Analysis: Reading the Lecture 7 model lineage</summary>

Lecture 7의 계보 표는 왼쪽의 domain과 오른쪽의 separator를 분리해 읽는다.

- TasNet 계열은 STFT를 없앤 것이 아니라 학습 가능한 1-D analysis/synthesis basis를 사용한다.
- Conv-TasNet은 separator를 RNN에서 dilated TCN으로 바꾼다.
- DPRNN은 긴 latent sequence를 chunk로 나누고 두 방향의 recurrence를 교대로 적용한다.
- SepFormer는 같은 dual-path 틀에서 recurrent block을 Transformer block으로 바꾼다.
- TF-GridNet은 complex STFT domain으로 돌아와 frequency 내부, 시간 방향, cross-frame 문맥을 함께 처리한다.

표의 SI-SNRi·SDRi 수치는 metric, dataset, sampling rate, dynamic mixing 여부가 섞여 있다. 세대 순서를 이해하는 데는 사용할 수 있지만, 숫자만으로 절대 순위를 만들면 안 된다.

</details>

### 7.5 Unknown speaker count와 real-world gap

고정 출력 $$N$$인 separator는 실제 source 수 $$K$$가 다를 때 빈 output, source 복제 또는 여러 source의 합을 만들 수 있다. 대응 방향은 다음과 같다.

1. 최대 output 수를 두고 쓰지 않는 output을 silence로 학습한다.
2. 한 source와 나머지를 반복 분리한다.
3. Source-count head가 decoder 또는 attractor 수를 고른다.

Lecture 7의 “every model has fixed outputs”는 앞에서 비교한 고정-output 계열의 범위로 읽어야 한다. Recursive extraction과 attractor 기반 방법까지 포함한 모든 separation model의 보편 명제가 아니다.

Clean anechoic mixture에서 높은 점수를 얻어도 reverberation, ambient noise, microphone response가 달라지면 성능이 크게 떨어질 수 있다. Dynamic mixing은 clean source의 pair, gain, shift를 학습 중 다시 조합해 mixture 다양성을 늘린다. 이는 data augmentation이며 model 구조와 구분한다.

### 7.6 MixIT는 clean source 없이 mixture를 target으로 쓴다

Mixture Invariant Training(MixIT)은 두 실제 mixture $$x_1,x_2$$를 더한 mixture-of-mixtures $$\bar x=x_1+x_2$$를 network에 넣는다. Network가 $$M$$개 신호 $$\hat s_m$$을 출력하면, 각 출력을 두 그룹으로 나누어 원래 mixture 두 개를 가장 잘 재구성하는 assignment를 고른다.

$$
\mathcal L_{\mathrm{MixIT}}
=\min_{A\in\mathcal A}\sum_{i=1}^{2}
\ell\left(x_i,\sum_{m=1}^{M}A_{im}\hat s_m\right).
$$

각 output은 한 mixture group에 배정된다. Clean source가 없어도 $$x_1,x_2$$는 관측 가능한 target이다. 그러나 한 실제 source를 여러 output으로 쪼개도 두 mixture 재구성이 가능할 수 있어 over-separation 위험이 있다.

![Dynamic Mixing과 MixIT가 각각 clean source 또는 원래 mixture를 target으로 사용해 separation 출력을 대응시키는 과정](/assets/images/study/speech-and-audio-recognition/lecture-07/slide-25.png)

위쪽 PIT/DM 경로에서는 개별 clean source가 정답이므로 출력 순열만 바꾼다. 아래쪽 MixIT 경로에서는 개별 clean source를 모르므로 여러 출력을 파란 점선 그룹처럼 다시 더해 $$x_1$$과 $$x_2$$를 복원한다. `permutation`은 일대일 대응이고 `remix assignment`는 여러 출력을 한 관측 mixture에 묶을 수 있다는 차이가 핵심이다.

### 7.7 Efficiency와 generative separation은 서로 다른 질문이다

WSJ0-2mix 같은 정형 benchmark의 점수가 높아진 뒤에는 최고 점수만이 아니라 parameter 수, MACs, 긴 발화의 memory, noise·reverberation에서의 일반화가 중요해진다. Lecture 7은 TIGER를 band-split과 multi-scale attention으로 계산량을 줄이는 방향, SepMamba를 self-attention 대신 state-space block으로 긴 sequence를 선형 시간에 처리하려는 방향으로 소개한다. 강의 슬라이드의 절감률은 해당 논문의 비교 설정에 묶인 수치이므로 다른 sampling rate·dataset·metric에 그대로 옮기지 않는다.

Generative separation은 mixture $$x$$에서 하나의 point estimate만 회귀하는 대신 조건부 분포

$$
p(s_1,\ldots,s_K\mid x)
$$

를 학습하고 diffusion, score-based model 또는 flow matching으로 sample을 생성하려 한다. 여러 plausible source가 가능한 ill-posed 문제에서 자연스러운 세부를 복원할 여지가 있지만, 생성된 세부가 실제 mixture에 존재했다는 보장은 없다. 따라서 청감상의 자연스러움과 **mixture에 대한 충실성**을 분리해 평가해야 하며, sampling step에 따른 latency도 확인해야 한다. 이 계열의 상세 구조와 개별 연구는 [Lecture 7: Blind Source Separation](/study/speech-and-audio-recognition/lecture-07-source-separation-2/)에서 이어서 확인한다.

## 8. 같은 단어가 다른 연산을 뜻하는 경우

### 8.1 Masking 세 종류

| 맥락 | 가리는 대상 | 목적 | 최종 출력에 적용하는가? |
|---|---|---|---|
| wav2vec 2.0 / HuBERT | latent time span | 문맥 예측 학습 | 입력 corruption이며 waveform mask가 아님 |
| Magnitude/complex separation | STFT 또는 latent feature | source 성분 추정 | mixture representation에 곱할 수 있음 |
| Attention mask | 허용하지 않을 위치의 score | future/padding 접근 제한 | probability 계산 전 score 제한 |

### 8.2 Blank 두 종류

CTC blank는 frame path를 collapse할 때 제거된다. RNN-T blank는 출력 prefix를 유지하며 acoustic time을 진행시킨다. 둘 다 전사에 남지 않지만 상태 전이 규칙은 다르다.

### 8.3 Phase와 imaginary part

Imaginary part는 phase 그 자체가 아니다. Complex value $$a+jb$$의 phase는 $$\operatorname{atan2}(b,a)$$다. Real·imaginary 두 좌표는 magnitude와 phase를 함께 결정한다.

## 9. 문제를 푸는 순서

### 9.1 Signal과 spectrum 문제

1. 시간 단위와 sampling rate를 확인한다.
2. 연속/이산, 주기/비주기, finite/infinite 중 어떤 모델인지 정한다.
3. Fourier convention과 normalization을 기록한다.
4. Nyquist 조건을 최고 주파수에 대입한다.
5. DFT bin은 $$k f_s/N$$과 음의 주파수 wrap을 함께 읽는다.
6. Magnitude와 phase가 모두 필요한 복원 문제인지 확인한다.

### 9.2 CTC forward 문제

1. 정답 사이에 blank를 넣어 확장열 $$z$$를 만든다.
2. 첫 frame에서는 첫 blank와 첫 label만 초기화한다.
3. Stay, 한 칸 전진, 허용된 두 칸 skip을 구분한다.
4. 이전 경로 합에 현재 frame 확률을 곱한다.
5. 마지막 label과 마지막 blank 상태를 더한다.
6. 음의 로그를 취해 loss로 바꾼다.

### 9.3 Separation loss 문제

1. Network input이 waveform, magnitude, complex STFT, learned feature 중 무엇인지 정한다.
2. Output이 mask인지 직접 source estimate인지 확인한다.
3. Mask라면 범위, 압축, 역압축과 실제 곱셈 위치를 확인한다.
4. Loss가 mask, spectrum, waveform 중 어디에서 계산되는지 표시한다.
5. Mixture phase를 고정하는지 phase를 예측하는지 확인한다.
6. 여러 source라면 assignment를 고정하는지 PIT/MixIT를 쓰는지 확인한다.

## 10. 자주 생기는 오해

| 오해 | 정확한 해석 |
|---|---|
| FFT는 DFT보다 정확한 transform이다. | FFT는 같은 DFT를 더 적은 계산으로 구한다. |
| Log를 씌우면 작은 값이 분류 가능해진다. | Dynamic range는 줄지만 분류 성능은 task와 model에서 검증해야 한다. |
| Mel scale은 log amplitude다. | Mel은 frequency-axis mapping이고 log amplitude는 별도 값 변환이다. |
| CTC DP 값은 반복 계산하며 수렴한다. | 고정 확률표의 유효 경로 합을 유한 격자에서 정확히 계산한다. |
| Blank는 silence다. | CTC/RNN-T의 정렬 기호이며 실제 무음과 일대일 대응하지 않는다. |
| Complex network의 imaginary channel이 phase다. | Phase는 real·imaginary 좌표를 함께 사용해 계산한다. |
| PIT가 speaker identity를 학습한다. | 현재 example의 output과 reference 사이 최적 permutation을 선택한다. |
| DPRNN이면 항상 streaming이다. | 표준 bidirectional 구성은 미래 문맥을 사용하며 causal variant가 따로 필요하다. |
| Time-domain model은 STFT가 열등함을 증명했다. | 비교 당시 mask·phase 제약과 model 조건을 함께 봐야 한다. |
| MixIT에는 target이 없다. | Clean source 대신 원래 mixture들을 reconstruction target으로 사용한다. |

## 마지막 핵심 정리

- Sampling은 시간축, quantization은 진폭축을 이산화한다. Nyquist 위반 뒤에는 원주파수 구분을 사후 처리로 되찾을 수 없다.
- DFT는 변환 정의, FFT는 계산 알고리즘이다. STFT는 시간 위치를 얻지만 window·hop·phase·overlap-add 조건을 함께 관리해야 한다.
- Mel filterbank의 주파수 집계와 log의 값 압축은 별도 연산이며, ASR feature와 waveform 복원 표현의 목적도 다르다.
- CTC는 frame 확률을 곱해 path 확률을 만들고, 같은 전사로 collapse되는 path를 더한다. Forward DP는 이 합을 재사용한다.
- LAS는 이전 token과 attention context로 다음 token을 생성하고, RNN-T는 acoustic time과 output prefix를 두 축으로 분리한다.
- wav2vec 2.0과 HuBERT는 transcript 없이 target을 만들지만 target 생성 방식이 다르다.
- Separation에서는 representation, mask/estimate, loss 위치, phase, output permutation을 하나의 경로로 연결해 봐야 한다.
- DPCL은 same-source affinity를, PIT는 최적 output-reference 대응을, MixIT는 mixture reconstruction assignment를 사용한다.

## Study Guide

### 1차 회독: 전체 연결

1. [Digital Signal Processing I](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)에서 sampling, Fourier, Nyquist를 확인한다.
2. [Spectral Analysis Lab](/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/)에서 FFT, STFT, Mel, notebook 그림을 연결한다.
3. [Automatic Speech Recognition I](/study/speech-and-audio-recognition/lecture-03-automatic-speech-recognition/)에서 CTC 확률과 forward table을 직접 계산한다.
4. [Automatic Speech Recognition II](/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/)에서 LAS와 RNN-T의 상태 전이를 비교한다.
5. [Self-Supervised Learning](/study/speech-and-audio-recognition/lecture-05-self-supervised-learning/)에서 wav2vec 2.0과 HuBERT target을 구분한다.
6. [Source Separation I](/study/speech-and-audio-recognition/lecture-06-source-separation/)에서 mask, loss, phase, DCCRN·FullSubNet+를 읽는다.
7. [Blind Source Separation](/study/speech-and-audio-recognition/lecture-07-source-separation-2/)에서 DPCL, PIT, TasNet 계보, unknown $$K$$, MixIT를 읽는다.

### 2차 회독: 직접 계산

- 7 kHz와 1 kHz가 8 kHz sampling에서 같은 표본을 만드는지 다섯 sample로 계산한다.
- 8-point DFT의 bin frequency와 음의 frequency bin을 표시한다.
- STFT의 입력 길이, window, hop, padding으로 frame 수와 output shape를 계산한다.
- CTC `AB` 예제의 다섯 path와 forward table을 모두 계산한다.
- PIT의 두 permutation loss를 비교한다.
- 같은 magnitude, 다른 phase인 두 complex bin의 squared error를 계산한다.

### 3차 회독: 비교표 없이 설명

다음 쌍을 한 문단씩 설명한다: DFT/FFT, spectrum/spectrogram, Mel/log, CTC blank/RNN-T blank, CTC/LAS/RNN-T, wav2vec 2.0/HuBERT, MA/SA/waveform loss, DPCL/PIT/MixIT.

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

<details markdown="block">
<summary>7. MA, SA, waveform loss는 왜 한 pipeline의 세 단계가 아닌가?</summary>

답변: 세 용어는 주로 loss를 계산하는 비교 지점을 가리킨다. MA는 mask, SA는 mask 적용 뒤 spectrum, waveform loss는 decoder 뒤 파형을 정답과 비교한다. 한 model이 하나 또는 여러 loss를 선택할 수 있으며, 강의의 소개 순서만으로 모두 순차 적용한다고 결론낼 수 없다.

</details>

<details markdown="block">
<summary>8. DPCL과 PIT는 permutation 문제를 어떻게 다르게 푸는가?</summary>

답변: DPCL은 time-frequency bin 사이의 same-source affinity를 학습해 speaker label 순서 자체를 없애고, inference에서 clustering한다. PIT는 source별 output을 직접 만들되 reference와의 가능한 대응 중 loss가 가장 작은 assignment를 선택한다.

</details>

<details markdown="block">
<summary>9. MixIT가 clean source 없이 학습할 수 있는 이유와 위험은 무엇인가?</summary>

답변: 두 실제 mixture를 더한 입력을 분리하고, output들을 두 그룹으로 다시 합쳐 원래 mixture 두 개를 복원하도록 학습한다. 원래 mixture가 target 역할을 하므로 clean source가 필요 없다. 그러나 실제 source 하나를 여러 output으로 쪼개도 reconstruction이 가능해 over-separation이 생길 수 있다.

</details>

<details markdown="block">
<summary>10. Standard DPRNN을 곧바로 streaming model이라고 부를 수 없는 이유는 무엇인가?</summary>

답변: Streaming 여부는 dual-path라는 이름이 아니라 각 block이 미래 chunk를 보는지에 달려 있다. 표준 DPRNN 논문의 bidirectional recurrent 처리에는 미래 문맥이 포함된다. Causal recurrent block, 제한된 chunk context와 latency 조건을 별도로 정해야 streaming 구성이 된다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2: Digital Signal Processing I</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2 Lab: FFT, STFT, Mel, and Cepstrum</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 3: Automatic Speech Recognition I</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 4: Automatic Speech Recognition II</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 5: Self-Supervised Learning</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 6: Source Separation I</a></li>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 7: Source Separation II</a></li>
</ul>

## Detailed Notes

- [Digital Signal Processing I](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)
- [Spectral Analysis Lab](/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/)
- [Automatic Speech Recognition I](/study/speech-and-audio-recognition/lecture-03-automatic-speech-recognition/)
- [Automatic Speech Recognition II](/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/)
- [Self-Supervised Learning](/study/speech-and-audio-recognition/lecture-05-self-supervised-learning/)
- [Tokenization and Decoding Lab](/study/speech-and-audio-recognition/asr-tokenization-and-decoding-lab/)
- [Source Separation I](/study/speech-and-audio-recognition/lecture-06-source-separation/)
- [Blind Source Separation](/study/speech-and-audio-recognition/lecture-07-source-separation-2/)

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
- <a href="https://arxiv.org/abs/2006.11477" target="_blank" rel="noopener">Baevski et al.: wav2vec 2.0</a>
- <a href="https://arxiv.org/abs/2106.07447" target="_blank" rel="noopener">Hsu et al.: HuBERT</a>
- <a href="https://arxiv.org/abs/1508.04306" target="_blank" rel="noopener">Hershey et al.: Deep Clustering</a>
- <a href="https://arxiv.org/abs/1607.00325" target="_blank" rel="noopener">Yu et al.: Permutation Invariant Training</a>
- <a href="https://arxiv.org/abs/1809.07454" target="_blank" rel="noopener">Luo and Mesgarani: Conv-TasNet</a>
- <a href="https://arxiv.org/abs/1910.06379" target="_blank" rel="noopener">Luo et al.: Dual-Path RNN</a>
- <a href="https://arxiv.org/abs/2010.13154" target="_blank" rel="noopener">Subakan et al.: SepFormer</a>
- <a href="https://arxiv.org/abs/2006.12701" target="_blank" rel="noopener">Wisdom et al.: MixIT</a>
