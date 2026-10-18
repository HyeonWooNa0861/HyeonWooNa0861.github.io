---
layout: default
date: 2026-10-08 16:17:00 +0900
last_modified_at: 2026-10-18 19:26:41 +0900
title: "Speech and Audio Recognition Lecture 6: Source Separation"
course: "Speech and Audio Recognition"
topic: "Audio Reconstruction, Masking, Loss Functions, and Phase"
order: 8
major_topic: "Speech and Audio Processing"
keywords:
  - "Source Separation"
  - "Speech Enhancement"
  - "Mel Spectrogram"
  - "STFT"
  - "Mask Approximation"
  - "Signal Approximation"
  - "Waveform Loss"
  - "Phase-Sensitive Mask"
  - "SI-SNR"
  - "Permutation Invariant Training"
  - "DCCRN"
  - "Demucs"
  - "Band-Split RNN"
---

# Speech and Audio Recognition Lecture 6: Source Separation

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture6.pdf</a> — Inkyu An, Kookmin University (48 slides).

음성인식은 소리를 문자로 바꾸지만, source separation은 **혼합된 소리에서 다시 들을 수 있는 개별 파형을 복원**한다. 따라서 인식에 충분한 특징과 복원에 충분한 표현은 다르다. [Spectral Analysis Lab](/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/)에서 사용한 log-Mel spectrogram을 분리 모델에 그대로 넣기 전에, 원래 주파수별 크기와 위상을 어떻게 되찾을지 결정해야 한다.

> **핵심:** 마스크는 시간·주파수별로 목표 소리를 얼마나 남길지 추정한다. MA는 **마스크**, SA는 **마스크를 적용한 스펙트럼**, waveform loss는 **복원된 파형**을 정답과 비교한다. 이들은 비교 지점이 다른 학습 목표다. 크기를 정확히 맞혀도 위상이 다르면 파형이 달라지므로, 복원 모델은 크기와 위상 또는 이를 함께 담는 waveform을 다뤄야 한다.

페이지 번호는 원본 PDF의 물리적 쪽 번호다. 아래 유도·작은 수치 예제·그림은 이해를 위한 보충 설명이다. 원문 표기의 정정과 실험 수치의 해석 조건은 마지막 `Source Check`에서 구분한다.

## 전체 흐름

| 원문 | 주제 | 먼저 이해할 질문 |
|---|---|---|
| pp. 2–11 | Denoising, separation, diarization | 소리를 복원하는 일과 활동 구간을 찾는 일은 어떻게 다른가? |
| pp. 12–17 | Encoder–mask–decoder | 어떤 표현을 보존해야 소리로 돌아갈 수 있는가? |
| pp. 18–20 | SNR, SI-SNR, PESQ, STOI | 정답과의 오차, 음량, 음질, 명료도는 같은 기준인가? |
| pp. 21–25 | MA, SA, waveform, PSA, PIT | 학습 오차를 어디서 계산하고 어떤 정답과 비교하는가? |
| pp. 26–28 | 크기와 위상 | 정답 크기만 알면 정답 소리를 만들 수 있는가? |
| pp. 29–32 | DCCRN, MDX-Net, FullSubNet+ | 복소수와 주파수 문맥을 모델에서 어떻게 다루는가? |
| pp. 33–44 | Demucs, hybrid models | 파형과 스펙트럼의 정보를 어떻게 결합하는가? |
| pp. 45–48 | Band-Split RNN | 주파수 대역을 나누면 무엇을 배우기 쉬워지는가? |

## 1. 무엇을 분리하는가

### 1.1 혼합 파형에서 시작한다

한 채널에 목표 음성 $$s[n]$$와 잡음 $$v[n]$$이 더해졌다고 두자.

$$
y[n]=s[n]+v[n]
$$

이는 같은 시각의 sample을 더하는 **가산 혼합 가정**이다. 실제 녹음에는 잔향, 마이크 응답, 비선형 clipping도 있을 수 있다. 잔향이 포함되면 정답이 무향 음성인지, 잔향을 포함한 음성인지도 먼저 정해야 한다.

음악의 여러 source를 분리한다면 다음처럼 쓴다.

$$
y[n]=\sum_{i=1}^{K}s_i[n]
$$

| 문제 | 출력 | 정답의 의미 |
|---|---|---|
| Denoising / speech enhancement | 잡음이 줄어든 음성 파형 | 보존하려는 음성 |
| Speech / music separation | 화자별 파형 또는 vocals·drums·bass 등 stems | 각각의 source |
| Diarization | 누가 언제 말했는지 나타내는 구간·label | 활동 시각과 화자 ID |

Diarization은 개별 source waveform을 반드시 복원하지 않는다. 반대로 separation은 출력 파형을 만들어도 그 화자가 누구인지는 알지 못할 수 있다(pp. 2–4).

### 1.2 주파수를 잘라내는 것만으로는 부족한 이유

일정한 기계음처럼 목표와 주파수 구조가 다른 잡음은 spectral profiling으로 줄일 수 있다. 그러나 두 사람이 같은 순간에 말하면 동일한 시간·주파수 칸에 두 음성 성분이 겹친다(pp. 5–10). 그 칸 전체를 지우면 잡음뿐 아니라 목표 음성도 사라진다.

딥러닝 모델은 한 칸의 에너지만 보지 않고, 주변 시간의 발음 변화, 주파수에 걸친 harmonic 구조, source의 지속성 등을 이용해 목표 성분을 추정한다. 이미 혼합된 성분을 정확히 관측하는 것이 아니라, 데이터에서 학습한 구조로 **분리 가능한 해를 추정**한다. 단일 채널의 모든 혼합이 유일하게 분리되는 것은 아니다.

응용은 통화 잡음 제거, 다화자 회의록의 전처리, 보컬 추출, 영화의 대사·음악·효과음 분리, 로봇의 음성 인터페이스 등이다(p. 11). ASR 전처리에서는 듣기 좋은 소리가 반드시 낮은 WER로 이어지지 않으므로 downstream 인식 성능도 별도로 확인한다. <a href="https://arxiv.org/abs/1811.11517" target="_blank" rel="noopener">음성 향상과 ASR 성능의 관계를 분석한 연구</a>에서도 enhancement 지표의 개선과 인식 오류율을 별개로 평가한다.

## 2. Encoder–mask–decoder를 한 칸씩 따라가기

<figure id="speech-06-p17">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p17.png" | relative_url }}" alt="Encoder 출력과 mask가 곱해진 뒤 decoder로 전달되는 source separation 구조" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=17" | relative_url }}">lecture PDF, p. 17</a>.</figcaption>
</figure>

아래 파이프라인의 긴 우회선은 encoder 표현을 곱셈 지점까지 직접 전달한다. Masking network가 낸 값은 그 표현과 곱해지고 decoder가 파형으로 복원한다. 오른쪽 spectrogram은 처리 전후 표현을 보여 주지만, mask를 곱할 대상이 magnitude인지 복소 STFT인지 학습된 feature인지는 모델 정의를 함께 확인해야 한다. 아래 좌표 그림은 이 원본에서 생략한 복소 STFT의 의미를 보충한다.

### 2.1 STFT는 크기와 위상을 함께 만든다

실제 마이크가 측정한 waveform은 실수값이다. STFT의 허수부는 마이크가 별도의 “허수 소리”를 측정했다는 뜻이 아니다. **같은 소리 구간을 cosine과 sine의 두 기준에 맞춰 읽은 결과**를 실수부와 허수부로 기록한다. 두 값이 있어야 해당 주파수 성분의 크기뿐 아니라 분석 구간 안에서 파동이 어디까지 진행했는지도 구분할 수 있다.

한 칸을 $$Y=a+jb$$라고 쓰면, 실수부 $$a$$와 허수부 $$b$$는 복소평면의 두 좌표다. 크기는 $$\sqrt{a^2+b^2}$$, 위상은 $$\operatorname{atan2}(b,a)$$로 **두 좌표를 함께 사용해** 구한다. 따라서 “실수부는 크기, 허수부는 위상”으로 각각 배정하면 안 된다. 허수부를 버리면 위상뿐 아니라 크기 계산에 필요한 정보도 달라진다.

![복소 STFT 값의 실수 좌표와 허수 좌표, 원점으로부터의 크기와 실수축으로부터의 위상각](/assets/images/study/speech-source-separation/complex-stft-coordinates.svg)

그림의 가로축은 실수부, 세로축은 허수부다. 파란 선의 **길이**가 크기이고, 가로축과 이루는 **각도**가 위상이다. $$Y=0.5+j\sqrt{3}/2$$는 크기 1, 위상 60도다. 허수부를 0으로 바꾸면 $$Y=0.5$$가 되어 크기는 0.5, 위상은 0도로 동시에 바뀐다. 반대로 $$Y=1$$과 $$Y=j$$는 크기가 모두 1이지만 위상은 각각 0도와 90도다. 허수부가 0이어도 음의 실수는 위상 180도를 가진다. 크기가 0인 칸에는 물리적으로 결정된 위상각이 없다.

위상은 **선택한 주파수와 분석 frame의 기준 시각에 대한 각도**다. 모든 위상값을 곧바로 소리의 도착 시간으로 읽을 수는 없다. 시간 지연은 여러 주파수의 위상을 일관된 방식으로 바꿀 때 해석할 수 있으며, 한 bin의 위상만으로 임의의 신호 지연이 유일하게 결정되지는 않는다.

<details markdown="block">
<summary markdown="span">Derivation: STFT coordinates, magnitude, and phase</summary>

STFT encoder의 한 정의는 다음과 같다. FFT 정규화는 구현별로 다를 수 있으며, 분석과 합성에서 같은 관례를 사용해야 한다.

$$
Y_{t,k}=\sum_{r=0}^{L-1}y[tH+r]w[r]e^{-j2\pi kr/N}
$$

$$
Y_{t,k}=\lvert Y_{t,k}\rvert e^{j\phi_{Y,t,k}}
$$

한 칸 $$Y_{t,k}$$는 복소수다. $$\lvert Y_{t,k}\rvert$$는 해당 성분의 크기, $$\phi_{Y,t,k}$$는 해당 분석 frame 안에서의 위상이다. 색으로 표시한 magnitude spectrogram에는 보통 크기만 보이지만, STFT 계산 결과에는 두 정보가 모두 있다(pp. 21–22).

Euler 항등식 $$e^{-j\theta}=\cos\theta-j\sin\theta$$를 위의 STFT 정의에 대입하면

$$
\begin{aligned}
a&=\sum_{r=0}^{L-1}y[tH+r]w[r]\cos(2\pi kr/N),\\
b&=-\sum_{r=0}^{L-1}y[tH+r]w[r]\sin(2\pi kr/N)
\end{aligned}
$$

가 된다. 여기서 허수부의 부호는 분석 지수를 음수로 정한 관례에 따른다. 극좌표로 쓰면 $$a=R\cos\phi$$, $$b=R\sin\phi$$이므로 $$a^2+b^2=R^2(\cos^2\phi+\sin^2\phi)=R^2$$이다. 이것이 크기를 두 좌표의 제곱합으로 계산하는 이유다. $$\operatorname{atan2}(b,a)$$는 두 좌표의 부호를 함께 사용해 사분면을 구분한다. $$\arctan(b/a)$$만 쓰면 $$a=0$$에서 나눌 수 없고 반대 사분면도 구분하지 못한다.

원 신호를 $$x(t-\tau)$$만큼 늦추는 연속시간 Fourier 관례에서는 주파수 $$f$$의 계수에 $$e^{-j2\pi f\tau}$$가 곱해진다. 따라서 지연에 의한 위상 변화는 $$-2\pi f\tau$$다. 이 관계는 전체 신호의 Fourier 변환에 대한 정확한 등식이다. 유한 STFT에서는 frame 위치·window·경계도 함께 달라질 수 있으므로 모든 bin의 변화를 단순한 고정 회전으로만 다뤄서는 안 된다.

</details>

| 기호 | 의미 | 단위·범위 |
|---|---|---|
| $$n,r,t,k$$ | sample, window 내부 sample, frame, frequency-bin index | 무차원 정수 |
| $$f_s$$ | sampling rate | Hz = samples/s |
| $$L,N,H$$ | window 길이, FFT 길이, hop 길이 | sample 수 |
| $$w[r]$$ | analysis window weight | 무차원 |
| $$y,s,v,\hat s$$ | 혼합·정답·잡음·예측 waveform | 보통 정규화된 PCM 값, 무차원; 보정 전에는 Pa가 아님 |
| $$Y,S,V,\hat S$$ | 각 waveform의 복소 STFT | PCM 및 FFT 정규화에 따른 상대 계수; 절대 음압으로 단정하지 않음 |
| $$\phi_Y,\phi_S,\hat\phi$$ | 혼합·정답·예측 위상 | rad |
| $$\hat M,M^\ast$$ | 예측·정답 mask | 무차원; 허용 범위는 mask 정의에 따름 |
| $$\alpha,c,\beta$$ | 투영 계수, 압축 지수, 혼합 가중치 | 무차원 |

### 2.2 모델은 mask를 만들고 decoder가 파형을 만든다

가장 단순한 magnitude-mask 모델에서는 다음 계산을 한다.

$$
\hat M=f_{\theta}(F(Y)),\qquad
\hat A=\hat M\odot\lvert Y\rvert
$$

$$
\hat S=\hat A e^{j\phi_Y},\qquad
\hat s=\operatorname{iSTFT}(\hat S)
$$

$$F(Y)$$는 network에 넣을 특징이다. $$\odot$$는 같은 위치끼리 곱하는 element-wise product다. $$\hat A$$는 **크기 추정치**이며, 복소 스펙트럼 $$\hat S$$와 구분한다. iSTFT에는 크기만이 아니라 복소 계수 또는 크기와 위상 쌍이 필요하다.

예를 들어 $$\lvert Y_{t,k}\rvert=10$$인 칸에 $$\hat M_{t,k}=0.6$$을 적용하면 추정 크기는 6이다. 그 값을 혼합 위상 $$\phi_Y$$와 결합하고, 다른 모든 칸과 함께 iSTFT로 합성한다. 한 칸이 특정 음성 sample 하나에 대응하는 것은 아니다. 각 주파수 성분이 frame 안의 여러 sample에 기여하고, 인접 frame도 overlap-add로 겹쳐진다.

이 기본 모델은 **혼합 위상을 그대로 사용**한다. 복소 mask 모델은 $$\hat M\in\mathbb C$$를 예측해 $$\hat S=\hat M\odot Y$$로 위상도 바꿀 수 있다. Waveform encoder–decoder는 STFT 대신 학습된 latent representation을 사용한다. 따라서 모든 분리 모델을 “STFT 크기에 0–1 mask를 곱하는 모델”로 묶을 수 없다(pp. 12–17).

### 2.3 마스크 학습이 항상 분류는 아니다

Binary mask는 한 칸을 남길지 지울지 이진 결정하므로 classification으로 학습할 수 있다. Continuous mask는 0.37, 0.82처럼 연속값을 추정하므로 보통 regression이다. 학습의 핵심은 “어떤 class인가”만이 아니라 **어떤 값을 곱해야 목표 source가 복원되는가**에 있다.

| Mask | 한 가지 정의 | 의미·주의점 |
|---|---|---|
| IBM | $$M^\ast=\mathbf 1[\lvert S\rvert^2>\lvert V\rvert^2]$$ | 목표가 더 큰 칸을 남기는 예; threshold는 변경 가능 |
| IRM | $$M^\ast=\sqrt{\frac{\lvert S\rvert^2}{\lvert S\rvert^2+\lvert V\rvert^2}}$$ | source별 power로 만든 bounded ratio의 한 관례 |
| Ideal amplitude mask | $$M^\ast=\frac{\lvert S\rvert}{\lvert Y\rvert}$$ | 혼합 크기를 정답 크기로 바꾸는 비율; 1보다 클 수 있음 |
| Complex ratio mask | $$M^\ast=\frac{S}{Y}$$ | 복소 나눗셈으로 크기와 위상을 함께 보정 |

분모가 0인 칸은 별도로 처리하거나 작은 $$\varepsilon$$을 사용해야 한다. IRM은 문헌마다 power나 지수 관례가 다르며, 위 표의 IRM과 ideal amplitude mask는 일반적으로 같은 값이 아니다. 혼합에서 위상 상쇄가 일어나면 $$\lvert Y\rvert<\lvert S\rvert$$이므로 목표를 복원하려면 1보다 큰 mask가 필요할 수 있다. Sigmoid로 0–1만 허용한 모델에는 표현 범위의 제약이 생긴다.

## 3. Mel spectrogram은 어디서 정보를 잃는가

### 3.1 주파수 축의 압축과 로그 압축은 다르다

한 frame에서 linear-frequency power를 $$p_k=\lvert Y_k\rvert^2$$로 두면 Mel power는 filter-bank 행렬 $$W$$로 계산한다.

$$
q_b=\sum_{k=0}^{F-1}W_{b,k}p_k,\qquad q=Wp
$$

$$
z_b=10\log_{10}\left(\frac{\max(q_b,\varepsilon)}{q_{\mathrm{ref}}}\right)
$$

$$b$$는 Mel-band index, $$W_{b,k}$$는 무차원 filter weight다. $$q_{\mathrm{ref}}>0$$는 기준 power다. 흔히 FFT bin 수 $$F$$보다 Mel band 수 $$B$$가 적다. 예를 들어 $$N=512$$인 실수 신호의 one-sided STFT는 257 bins인데, 이를 80 Mel bands로 줄이면 여러 주파수 성분이 하나의 band 값에 합쳐진다.

세 변환을 구분해야 한다.

1. **Phase discard:** magnitude 또는 power만 남기면 원래 위상을 직접 알 수 없다.
2. **Frequency aggregation:** $$B<F$$인 Mel filter bank는 서로 다른 주파수 분포를 같은 band 값으로 보낼 수 있다.
3. **Dynamic-range compression:** 양수에 로그만 적용하고 기준을 알고 있으면 역변환할 수 있다. 그러나 floor, clipping, quantization, frame별 normalization을 함께 쓰면 추가 정보가 사라질 수 있다.

따라서 “로그를 씌웠기 때문에 무조건 복원 불가능하다”는 설명은 정확하지 않다. **원래 bin을 합치는 변환과 위상을 버리는 변환**이 직접적인 복원 문제를 만든다.

### 3.2 서로 다른 입력이 같은 출력이 되는 작은 증명

Mel band 안의 합계가 같아도, 그 합계를 만든 세부 주파수의 배치는 다를 수 있다. **합계만 저장하면 원래 배치를 선택할 정보가 부족하다.** 다음 계산은 모델 성능이 아니라 표현 자체의 비유일성을 확인한다.

<details markdown="block">
<summary markdown="span">Derivation: why Mel aggregation is not uniquely invertible</summary>

주파수 세 칸을 두 band로 합치는 설명용 행렬을 만들자. 실제 Mel filter의 정확한 모양을 재현한 것이 아니라, 차원 축소의 비유일성을 보여 주는 예다.

$$
W=\begin{bmatrix}1&1&0\\0&1&1\end{bmatrix},\qquad
p=\begin{bmatrix}1\\0\\1\end{bmatrix},\qquad
p'=\begin{bmatrix}0\\1\\0\end{bmatrix}
$$

$$
Wp=\begin{bmatrix}1\\1\end{bmatrix}=Wp'
$$

첫 입력은 양끝의 주파수에 power가 있고, 둘째 입력은 가운데에만 power가 있다. 둘은 다른 소리를 나타낼 수 있지만 두 band의 합만 보면 구별할 수 없다.

일반적으로 $$\operatorname{rank}(W)\le B<F$$이므로 0이 아닌 null-space vector $$d$$가 존재한다.

$$
Wd=0\quad\Longrightarrow\quad W(p+d)=Wp
$$

비음수 power 조건을 만족하는 서로 다른 입력이 남을 수 있어, Mel 값만으로 원래 power를 항상 유일하게 복구할 수는 없다. librosa의 `mel_to_stft` 함수도 이를 <a href="https://librosa.org/doc/0.10.2/generated/librosa.feature.inverse.mel_to_stft.html" target="_blank" rel="noopener">근사적인 STFT magnitude 복원</a>으로 정의한다.

</details>

### 3.3 인식에 유용한 표현이 복원에는 부족할 수 있다

ASR은 특정 waveform을 재현하기보다 어떤 phoneme·word인지 알아내는 것이 목적이다. 주파수의 세부 차이를 줄인 log-Mel 특징이 그 목적에는 유용할 수 있다. 반면 denoising과 separation은 목표 파형의 주파수별 크기와 시간 구조를 다시 만들어야 한다.

이 때문에 **단순 mask–iSTFT 경로에서는 linear-frequency STFT나 학습된 waveform representation을 선택하는 이유가 강하다.** Mel mask를 예측해도 80-band 값을 257-bin 복소 스펙트럼으로 바꾸는 별도 단계가 필요하다.

다만 Mel 사용 자체가 금지되는 것은 아니다. Mel을 mask network의 입력 특징으로 쓰면서 원래 $$Y$$를 복원 경로에 보존할 수 있고, generative decoder가 Mel을 조건으로 waveform을 합성할 수도 있다. 전자는 원래 스펙트럼을 유지하고, 후자는 학습한 prior로 빠진 정보를 추정한다. Mel만으로 원래 파형이 수학적으로 유일하게 결정된다는 뜻은 아니다.

## 4. MA·SA·Waveform: 같은 출력의 어디를 비교하는가

<figure id="speech-06-p23">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p23.png" | relative_url }}" alt="하나의 마스킹 경로에서 MA SA waveform loss의 세 비교 위치" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=23" | relative_url }}">lecture PDF, p. 23</a>.</figcaption>
</figure>

빨간 1은 예측 mask와 정답 mask, 2는 mask를 적용한 spectrum과 정답 spectrum, 3은 iSTFT로 복원한 파형과 정답 파형의 비교다. 세 번호는 학습을 반드시 1, 2, 3 순서로 끝내야 한다는 뜻이 아니다. 같은 모델 출력에 어느 공간의 오차를 주느냐가 다르다. 아래 보강 그림은 이 세 위치를 분리해 확대했으며 원문의 처리 순서를 대체하지 않는다.

원문 p. 23의 번호 ①②③은 **loss를 계산할 수 있는 위치**다. MA를 먼저 학습하고, 그다음 SA, 마지막으로 waveform을 반드시 순차 수행하라는 뜻이 아니다. 모델은 하나를 선택하거나 여러 loss를 가중합해 한 번에 학습할 수 있다.

![혼합 신호에서 mask, masked magnitude, reconstructed waveform으로 이어지는 경로와 MA·SA·Waveform의 비교 위치](/assets/images/study/speech-source-separation/loss-comparison-pipeline.svg)

그림을 왼쪽에서 오른쪽으로 읽으면 **입력과 출력의 처리 순서**이고, 각 비교 지점에서 정답으로 이어지는 선은 **학습 오차를 재는 위치**다. MA는 network가 낸 비율을 검사하고, SA는 그 비율을 곱한 결과를 검사한다. Waveform loss는 iSTFT 뒤 실제 sample을 검사한다. 정답 쪽 선은 학습할 때만 필요하며, 추론 때 모델이 정답을 입력으로 받는다는 뜻이 아니다.

### 4.1 MA — 예측 mask와 정답 mask를 비교한다

$$
L_{\mathrm{MA}}=\sum_{t,k}\left(\hat M_{t,k}-M^\ast_{t,k}\right)^2
$$

이는 squared-error objective의 **정의**다. 정답 $$M^\ast$$는 IBM, IRM 등 선택한 mask 관례로 만들어야 한다. MA는 최종 소리 대신 중간 표현을 맞힌다.

두 칸의 혼합 크기가 $$(2,10)$$, 정답 크기가 $$(1,5)$$이고 위상 차이를 잠시 제외하자. 여기서는 ideal amplitude mask를 써 $$M^\ast=(0.5,0.5)$$로 둔다. 예측 $$\hat M=(0.6,0.6)$$이면

$$
L_{\mathrm{MA}}=(0.6-0.5)^2+(0.6-0.5)^2=0.02
$$

두 칸의 mask 오차는 같아서 동일하게 벌점을 받는다. 그러나 실제 크기 오차는 첫 칸 0.2, 둘째 칸 1.0으로 다르다. **같은 mask 오차가 같은 소리 오차를 뜻하지 않는 것**이 MA의 핵심 한계다.

### 4.2 SA — mask를 적용한 크기를 정답 크기와 비교한다

Magnitude signal approximation은 다음처럼 정의한다.

$$
L_{\mathrm{SA}}=\sum_{t,k}\left(\hat M_{t,k}\lvert Y_{t,k}\rvert-\lvert S_{t,k}\rvert\right)^2
$$

같은 예측을 사용하면 추정 크기는 $$(1.2,6)$$이다.

$$
L_{\mathrm{SA}}=(1.2-1)^2+(6-5)^2=0.04+1=1.04
$$

둘째 칸이 더 큰 벌점을 받는다. 두 loss의 숫자 크기를 직접 비교해 “1.04이므로 나쁘다”라고 말할 수는 없다. **서로 다른 단위와 스케일의 objective**이기 때문이다. 봐야 할 것은 각 칸을 학습시키는 가중치가 어떻게 달라지는지다.

큰 혼합 성분에서는 같은 비율 오차도 큰 크기 오차가 된다. SA가 큰 성분을 더 강하게 반영하는 이유는 별도의 규칙을 덧붙였기 때문이 아니라, **mask를 혼합 크기에 곱한 뒤 오차를 계산하기 때문**이다.

<details markdown="block">
<summary markdown="span">Derivation: weighted MA identity and loss gradients</summary>

$$\lvert Y\rvert>0$$에서 ideal amplitude mask를 $$M^\ast=\lvert S\rvert/\lvert Y\rvert$$로 두면 한 칸에서 다음 정확한 등식이 성립한다.

$$
\left(\hat M\lvert Y\rvert-\lvert S\rvert\right)^2
=\lvert Y\rvert^2(\hat M-M^\ast)^2
$$

SA는 이 조건에서 **혼합 크기의 제곱을 가중치로 둔 MA**다. 앞 예제의 가중치는 4와 100이다. IRM을 정답 mask로 선택했다면 이 등식을 그대로 적용할 수 없다.

미분에서도 차이가 드러난다.

$$
\frac{\partial L_{\mathrm{MA}}}{\partial\hat M}=2(\hat M-M^\ast)
$$

$$
\frac{\partial L_{\mathrm{SA}}}{\partial\hat M}
=2\lvert Y\rvert\left(\hat M\lvert Y\rvert-\lvert S\rvert\right)
$$

두 칸의 MA gradient는 각각 0.2이고, SA gradient는 각각 0.8과 20이다. 정답 스펙트럼 크기 오차를 더 직접 반영하지만, 큰 성분이 학습을 지배하거나 약한 음성 성분이 덜 반영될 수 있다. SA가 모든 데이터·모델·metric에서 MA보다 낫다는 보장은 없다. MA와 SA의 정의 및 비교는 <a href="https://www.jonathanleroux.org/pdf/Weninger2014GlobalSIP12.pdf" target="_blank" rel="noopener">Weninger et al.의 signal approximation 연구</a>에서 자세히 다룬다.

</details>

### 4.3 Waveform loss — 소리로 복원한 다음 비교한다

복원된 $$\hat s$$와 clean waveform $$s$$를 sample 단위로 비교한다.

$$
L_{\mathrm{wave},1}=\sum_n\lvert\hat s[n]-s[n]\rvert
$$

또는

$$
L_{\mathrm{wave},2}=\sum_n(\hat s[n]-s[n])^2
$$

정답 $$(1,-1)$$에 대해 예측 $$(0.8,-0.8)$$은 L1 오차 0.4, squared L2 오차 0.08이다. 이 비교에는 원칙적으로 같은 길이, sample rate, 시간 정렬이 필요하다. 출력이 지연된 경우 정렬하지 않은 loss는 실제 소리와 별개로 큰 오차를 낼 수 있다.

학습 중 iSTFT가 미분 가능하면 파형 오차를 mask network까지 전달한다. Mask를 조금 바꿨을 때 최종 sample이 얼마나 바뀌는지 추적하기 때문에, **어느 mask 값을 바꾸면 파형 오차가 줄어드는지**도 계산할 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: waveform loss backpropagation through iSTFT</summary>

합성 연산을 $$D$$, mask 적용을 $$G$$라고 두면 chain rule은 다음과 같다.

$$
\hat s=D(G(\hat M,Y))
$$

$$
\frac{\partial L}{\partial\hat M}
=\left(\frac{\partial G}{\partial\hat M}\right)^{\top}
\left(\frac{\partial D}{\partial G}\right)^{\top}
\frac{\partial L}{\partial\hat s}
$$

여기서 복소수는 실수부·허수부를 쌓은 실수 vector로 생각하면 일반적인 Jacobian chain rule로 읽을 수 있다. Network parameter에는 $$\partial\hat M/\partial\theta$$를 한 번 더 곱한다. Loss가 커졌다는 정보만 전달되는 것이 아니라 **어느 mask 값을 바꾸면 어느 sample의 오차가 줄어드는지**가 전달된다.

</details>

다만 waveform loss를 쓰는 것만으로 위상을 독립적으로 예측할 수 있게 되지는 않는다. **Real nonnegative mask와 고정된 혼합 위상을 사용하는 모델은 위상 예측 자유도가 없다.** 위상 오차의 영향이 waveform loss에 나타나고 mask가 이를 고려해 바뀔 수는 있지만, 임의의 clean phase로 회전하려면 complex mask, phase predictor, 또는 waveform decoder가 필요하다.

### 4.4 학습 시 정답과 추론 시 입력을 구분한다

학습에서는 noisy/mixture $$y$$와 대응하는 clean $$s$$가 있어 $$S$$, $$M^\ast$$, loss를 계산할 수 있다. 추론에서는 $$y$$만 있고 정답 $$s$$는 없다. Network가 만든 mask와 decoder만 실행한다.

| Objective | 학습에서 비교하는 것 | 정답이 필요한 위치 | 중요한 조건 |
|---|---|---|---|
| MA | $$\hat M$$ 대 $$M^\ast$$ | mask target 생성 | 어떤 mask 정의를 쓰는지 명시 |
| Magnitude SA | $$\hat M\lvert Y\rvert$$ 대 $$\lvert S\rvert$$ | clean STFT magnitude | 위상 차이는 직접 비교하지 않음 |
| Waveform | $$\hat s$$ 대 $$s$$ | 복원 뒤 clean samples | decoder의 미분 가능성·시간 정렬 |
| Negative SI-SNR | 예측의 target 방향 성분 대 나머지 성분 | clean waveform | gain에는 불변; absolute level은 별도 확인 |

## 5. SNR과 SI-SNR: 신호·오차·음량을 구분하기

### 5.1 SNR은 목표 에너지와 오차 에너지의 비율이다

정답 $$s$$가 0이 아닌 유한 길이 waveform이고 $$e=\hat s-s$$라고 두자. p. 19에서 쓰는 reconstruction SNR은

$$
\operatorname{SNR}(\hat s,s)
=10\log_{10}\frac{\lVert s\rVert_2^2}{\lVert s-\hat s\rVert_2^2}
$$

이다. 같은 길이의 신호에서 평균 power의 비율을 만들면 양쪽의 sample 수가 약분되어 squared norm 비율이 된다. **Power ratio에는 $$10\log_{10}$$를 사용**한다. 같은 impedance 등의 조건에서 amplitude ratio로 표현할 때는 제곱 관계 때문에 $$20\log_{10}$$가 나온다.

$$s=(1,-1)$$, $$\hat s=(0.8,-0.8)$$이면 정답 에너지 2, 오차 에너지 0.08이다.

$$
\operatorname{SNR}=10\log_{10}(25)\approx13.98\ \mathrm{dB}
$$

파형 모양은 같지만 gain이 0.8이므로 SNR은 유한하다. 오차가 정확히 0이면 수학적으로 $$+\infty$$이며, 구현에서는 $$\varepsilon$$을 넣어 수치 발산을 막는다. 무음 정답의 분모·분자 문제도 따로 다뤄야 한다.

### 5.2 SI-SNR은 gain을 제거한 뒤 나머지 왜곡을 잰다

흔히 DC offset을 제거한 $$s$$와 $$\hat s$$를 사용한다. Gain이 달라도 같은 파형 모양이면 좋은 점수를 주기 위해 먼저 가장 가까운 scaled target $$\alpha s$$를 찾는다.

예측이 정답의 0.8배라면 음량은 작지만 파형 모양은 같다. SI-SNR은 정답도 0.8배로 맞춰 비교하여 **음량 차이와 나머지 왜곡을 분리**한다. 이때 예측에 이미 들어 있는 정답 방향 성분을 target으로, 그 방향으로 설명되지 않는 부분을 residual로 나눈다.

<details markdown="block">
<summary markdown="span">Derivation: least-squares projection and SI-SNR scale invariance</summary>

$$
\alpha^\ast=\arg\min_{\alpha}\lVert\hat s-\alpha s\rVert_2^2
$$

제곱식을 펼치고 미분하면

$$
\lVert\hat s-\alpha s\rVert_2^2
=\lVert\hat s\rVert_2^2-2\alpha\langle\hat s,s\rangle
+\alpha^2\lVert s\rVert_2^2
$$

$$
\frac{d}{d\alpha}= -2\langle\hat s,s\rangle
+2\alpha\lVert s\rVert_2^2=0
$$

$$
\alpha=\frac{\langle\hat s,s\rangle}{\lVert s\rVert_2^2}
$$

가 된다. $$s\ne0$$이므로 이계도함수는 양수이고, 이 해가 최솟값을 준다. 또한

$$
s_{\mathrm{target}}=\alpha s,\qquad
e_{\mathrm{noise}}=\hat s-\alpha s
$$

$$
\langle e_{\mathrm{noise}},s\rangle=0
$$

이다. 즉, **예측 $$\hat s$$를 정답 $$s$$가 생성하는 방향으로 투영**하고, 남은 직교 성분을 오차로 본다. $$s$$의 방향을 $$\hat s$$의 방향으로 회전하는 것이 아니다.

$$
\mathrm{SI\! -\! SNR}(\hat s,s)
=10\log_{10}\frac{\lVert\alpha s\rVert_2^2}
{\lVert\hat s-\alpha s\rVert_2^2}
$$

$$\hat s'=g\hat s$$, $$g\ne0$$이라고 하면 $$\alpha'=g\alpha$$가 되고, 분자와 분모가 모두 $$g^2$$배가 된다. 따라서 그 비율은 변하지 않으며 scale-invariant 성질을 가진다. 앞의 $$\hat s=0.8s$$ 예에서는 residual이 0이므로, 이상적인 식에서 SI-SNR은 $$+\infty$$가 된다.

이 성질은 gain 차이를 무시하고 분리 정확도를 비교할 때 유용하지만, 출력 음량이 정확하다는 뜻은 아니다. 임의의 실수 gain을 허용하는 투영은 극성 반전도 구분하지 않는다. 무음, 완전한 직교, 유한 정밀도에서는 별도 처리가 필요하며, 정규화 방식과 $$\varepsilon$$도 구현 조건으로 기록해야 한다.

</details>

<a href="https://arxiv.org/abs/1811.02508" target="_blank" rel="noopener">Le Roux et al.의 SI-SDR 논문</a>은 scale-invariant 투영과 기존 SDR의 차이를 다룬다. 위와 같은 단순 투영에서는 SI-SNR과 SI-SDR이 같은 형태가 되지만, 이름만 보고 구현의 demeaning이나 alignment 조건까지 같다고 판단해서는 안 된다.

### 5.3 Metric을 loss로 사용할 때는 부호를 반대로 둔다

SNR과 SI-SNR은 클수록 좋은 지표다. Optimizer가 작은 loss를 찾도록 하려면, 예를 들어

$$
L_{\mathrm{SI-SNR}}=-\mathrm{SI\! -\! SNR}(\hat s,s)
$$

로 정의할 수 있다(p. 25). SI-SNR이 10 dB에서 15 dB로 좋아지면 loss는 −10에서 −15로 감소한다. Loss가 음수여도 최소화 방향이 올바르면 문제가 없다.

PESQ는 지각적 음질을, STOI는 음성 명료도를 평가한다(pp. 18–20). PESQ의 raw score와 MOS-LQO, narrowband와 wideband는 척도가 서로 다르다. p. 20에 제시된 범위를 모든 variant에 공통인 고정 상한으로 해석해서는 안 된다. STOI도 백분율 표기와 0–1 표기를 구분해야 한다. 두 지표 모두 SNR을 단순히 다른 말로 표현한 것이 아니며, 범용 미분 가능 training loss로 그대로 사용할 수 있는 것도 아니다.

## 6. 정답의 크기와 위상을 따로 결정할 수 있는가

<figure id="speech-06-p27">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p27.png" | relative_url }}" alt="입력 SNR에 따른 magnitude phase 조합의 PESQ 곡선과 세 문장 oracle 결과표" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=27" | relative_url }}">lecture PDF, p. 27</a>.</figcaption>
</figure>

왼쪽의 clean 기준선과 ‘정답 magnitude + noisy phase’ 곡선 사이 간격은 크기만 맞혀도 파형이 완전히 복원되지는 않음을 보여 준다. 가로축은 입력 SNR, 세로축은 해당 실험의 PESQ다. 오른쪽 표는 제한된 문장과 설정의 oracle 비교이므로 전체 데이터셋 성능으로 일반화하지 않는다. 아래 벡터 예제는 이 관찰을 복소 오차의 수식으로 설명하기 위한 보강이다.

### 6.1 위상은 파동이 합쳐지는 결과를 바꾼다

가산 혼합과 STFT의 선형성에 따라 $$Y=S+V$$이다. 그러나 일반적으로 $$\lvert Y\rvert\ne\lvert S\rvert+\lvert V\rvert$$이다.

두 소리가 같은 주파수에 있어도 파동이 맞물리는 위치에 따라 더 커지거나 작아진다. 크기만 합하면 이 강화·상쇄를 설명할 수 없다. **혼합 크기는 각 source의 크기와 두 source의 위상 차이에 함께 의존한다.**

<details markdown="block">
<summary markdown="span">Derivation: the phase cross term in an additive mixture</summary>

$$
\begin{aligned}
\lvert Y\rvert^2
&=(S+V)(S^\ast+V^\ast)\\
&=\lvert S\rvert^2+\lvert V\rvert^2+2\operatorname{Re}(SV^\ast)\\
&=\lvert S\rvert^2+\lvert V\rvert^2
+2\lvert S\rvert\lvert V\rvert\cos(\phi_S-\phi_V)
\end{aligned}
$$

여기서 $$S^\ast$$와 $$V^\ast$$는 복소켤레이며, 목표 mask $$M^\ast$$의 별표와는 뜻이 다르다.

</details>

크기가 같은 두 성분도 위상이 같으면 서로 강화하고, 반대 위상이면 서로 상쇄한다. 예를 들어 $$S=1$$, $$V=-0.8$$이면 $$Y=0.2$$가 되므로 정답 크기 1을 복원하는 amplitude mask는 5가 된다. 0–1 범위의 mask로는 이 bin의 크기를 정확히 복원할 수 없다.

따라서 혼합 신호의 크기에서 목표 크기를 추정할 때도 위상이 관여한다. **Phase는 파형 복원의 마지막 단계에서 덧붙이기만 하는 정보가 아니다.**

### 6.2 정답 크기를 맞혀도 위상이 다르면 오차가 남는다

한 bin에서 정답을 $$S=Ae^{j\phi_S}$$, 예측을 $$\hat S=ae^{j\hat\phi}$$라고 하고 $$A,a\ge0$$으로 둔다. $$\Delta=\phi_S-\hat\phi$$는 두 위상의 차이다.

크기가 같다는 것은 복소평면에서 원점까지의 거리가 같다는 뜻이지, 같은 위치에 있다는 뜻은 아니다. **위상이 다르면 두 점 사이의 거리가 남고, 합성되는 파동도 달라진다.** 정답과 예측의 크기가 모두 1이어도 위상 차이가 60도면 complex squared error는 1이다.

<details markdown="block">
<summary markdown="span">Derivation: separating magnitude error and phase error</summary>

$$
\begin{aligned}
\lvert S-\hat S\rvert^2
&=A^2+a^2-2Aa\cos\Delta\\
&=(A-a)^2+2Aa(1-\cos\Delta)
\end{aligned}
$$

첫 번째 항은 magnitude mismatch, 두 번째 항은 phase mismatch의 기여분이다. 위상 오차의 크기는 $$Aa$$에도 의존하므로, phase 오차만 독립적인 수치로 보아서는 파형에 미치는 영향을 결정할 수 없다.

크기가 정확한 $$a=A$$인 경우에도

$$
\lvert S-\hat S\rvert^2=2A^2(1-\cos\Delta)
$$

가 남는다. $$\Delta=0$$이면 0, $$60^\circ$$이면 $$A^2$$, $$180^\circ$$이면 $$4A^2$$이다. 이것이 **같은 magnitude spectrogram이 같은 waveform을 뜻하지 않는** 이유다. 이 식은 한 bin에서 성립하는 정확한 관계이며, overlap된 STFT 전체의 waveform loss와 단순히 동치라는 뜻은 아니다.

</details>

### 6.3 혼합 위상이 고정되면 정답 크기를 출력하는 것이 최적이 아닐 수 있다

예측 위상을 $$\hat\phi=\phi_Y$$로 고정하고, 모델이 예측할 수 있는 값을 크기 $$a$$로만 제한한다.

위상을 고정한 모델은 정답 점을 향해 자유롭게 움직이지 못하고, **고정된 방향에서 크기만 바꿀 수 있다.** 그 방향 위에서 정답에 가장 가까운 위치를 선택하면 정답 크기보다 작은 값이 최적일 수 있다. 작아진 출력이 반드시 나쁜 예측은 아니며, 모델이 허용한 방향의 제약을 먼저 봐야 한다.

<details markdown="block">
<summary markdown="span">Derivation: optimal magnitude under a fixed phase</summary>

$$
\begin{aligned}
\lvert ae^{j\phi_Y}-Ae^{j\phi_S}\rvert^2
&=a^2-2aA\cos\Delta+A^2\\
&=(a-A\cos\Delta)^2+A^2\sin^2\Delta
\end{aligned}
$$

가 된다. 두 번째 항은 $$a$$를 바꾸어도 줄일 수 없다. 제약이 없는 실수 계수에서는 $$a^\ast=A\cos\Delta$$이고, **0 이상인 크기**로 제한하면

$$
a^\ast=\max(0,A\cos\Delta)
$$

가 최솟값을 준다. Mask를 0–1로 제한하면 $$a\le\lvert Y\rvert$$이므로 그 상한에서도 clip해야 한다. 음수 mask를 허용하면 계수의 부호가 위상을 $$\pi$$만큼 반전하므로, 0 이상인 magnitude를 다루는 경우와 구분해야 한다.

</details>

![정답 spectrum의 방향과 고정된 예측 위상. 정답 크기 1을 그대로 사용하는 것보다 투영한 크기 0.5가 복소 오차를 줄이는 60도 예시](/assets/images/study/speech-source-separation/magnitude-phase-geometry.svg)

그림에서 정답은 가로축 밖에 있지만, 위상이 0도로 고정된 예측은 가로축 위에만 놓인다. 정답에서 가로축으로 내린 투영점은 크기 0.5다. **가로축 위에서의 최적 예측도 세로 방향 오차를 없애지는 못한다.** 위상까지 바꿀 수 있는 모델은 정답 점 자체에 접근할 수 있다.

예를 들어 $$A=1$$, $$\phi_S=60^\circ$$, $$\phi_Y=0$$인 경우를 생각해 보자. 정답은 $$S=0.5+j\sqrt{3}/2$$이다.

| 출력 | 크기 오차의 제곱 | 복소 오차의 제곱 |
|---|---|---|
| $$\hat S=1$$ | 0 | 1 |
| $$\hat S=0.5$$ | 0.25 | 0.75 |
| $$\hat S=S$$ | 0 | 0 |

Magnitude만 비교하면 첫 번째 출력이 정답이지만, 고정 위상에서 복소 오차를 줄이려면 두 번째 출력이 더 낫다. 세 번째 출력은 위상도 정확하므로 오차가 0이다. **정답 magnitude에 가까워지는 것과 고정된 위상에서 정답에 가까운 소리를 만드는 것은 서로 다른 최적화 문제**다.

### 6.4 Phase-sensitive SA에서 cosine을 사용하는 이유

위의 완전제곱식에서 고정 위상의 복소 오차를 최소화하는 가변 부분은 다음과 같다.

$$
L_{\mathrm{PSA}}=\sum_{t,k}\left(
\hat M_{t,k}\lvert Y_{t,k}\rvert
-\lvert S_{t,k}\rvert\cos(\phi_{S,t,k}-\phi_{Y,t,k})
\right)^2
$$

이 식이 p. 24의 phase-sensitive signal approximation을 설명한다. Target은 clean spectrum을 mixture phase 방향으로 투영한 값이며, 단순히 "위상이 좋지 않으므로 음량을 적당히 줄인다"는 heuristic이 아니다. 이 projection target의 학습 효과는 <a href="https://www.erdogan.org/publications/erdogan15icassp.pdf" target="_blank" rel="noopener">Erdogan et al.의 phase-sensitive filtering 연구</a>에서 제안되었다.

$$\cos\Delta<0$$이면 projection target은 음수가 된다. Nonnegative mask로는 이 target을 완전히 표현할 수 없으므로 clipping 등의 처리를 명시해야 한다. 또한 iSTFT에 따른 frame 중첩과 STFT consistency를 포함한 전체 최적화는 이 bin 단위 유도만으로 완결되지 않는다.

### 6.5 Spectrogram 그림만으로 판단할 수 없는 이유

Magnitude의 색상 패턴이 선명해 보여도 위상이 일관되지 않으면 복원된 sample열은 달라진다. 특히 인접 frame은 서로 겹쳐 더해지므로, 임의로 만든 복소 STFT가 어떤 waveform의 STFT와 완전히 일치한다고 보장할 수 없다.

$$
\operatorname{STFT}(\operatorname{iSTFT}(\hat S))\ne\hat S
$$

가 될 수 있다. Magnitude constraint와 복원 가능한 STFT constraint를 반복적으로 맞추어 가는 것이 <a href="https://librosa.org/doc/main/generated/librosa.griffinlim.html" target="_blank" rel="noopener">Griffin–Lim</a>의 기본 발상이다. Magnitude만으로 원래 phase를 반드시 복구한다는 보장은 없다.

원문 p. 27의 oracle 비교에서는 정답 magnitude에 mixture phase를 결합해도 clean 신호와 같은 품질이 나오지 않는다. 반대로 정답 phase만 사용해도 mixture magnitude의 잡음이 남는다. 세 문장에 제시된 수치만으로 보편적인 성능 순위를 결론내리지 말고, **크기와 위상이 모두 필요하다**는 구조를 읽어야 한다. Griffin–Lim의 지각 metric과 SI-SDR 결과가 크게 다르면 지연, 시간 정렬, 극성, metric 구현도 확인해야 한다.

## 7. 압축 loss와 복원 정보의 손실은 서로 다른 문제다

### 7.1 Power-law는 큰 성분과 작은 성분의 가중치를 바꾼다

p. 24는 magnitude에 $$0<c<1$$인 압축을 적용해 loss를 계산하는 방법을 소개한다.

$$
L_{\mathrm{mag}}=\sum_{t,k}
\left(\lvert S_{t,k}\rvert^c-\lvert\hat S_{t,k}\rvert^c\right)^2
$$

$$c\approx0.3$$은 원자료에서 다룬 실험 설정이며, 이론으로부터 유일하게 결정되는 상수가 아니다. 크기를 기준값으로 정규화하면 단위에 의존하지 않는 비교가 가능하다.

작은 성분의 상대적 중요도가 커지는 이유는 압축 함수의 변화율로 확인할 수 있다.

큰 성분은 이미 큰 절대 오차를 만들기 쉽다. Power-law 압축은 큰 수의 증가 폭을 줄여, 작은 성분의 차이도 학습에서 상대적으로 더 반영되도록 한다. 예를 들어 1과 100을 각각 0.3제곱하면 약 1과 3.98이 된다. 이것은 **loss에서의 가중 효과**이지 원래 spectrum을 Mel band로 합치는 연산이 아니다.

<details markdown="block">
<summary markdown="span">Derivation: local error weighting in a compressed loss</summary>

정답 magnitude $$A>0$$ 부근에서 $$a=A+\delta$$라고 하면 Taylor 1차 근사는 다음과 같다.

$$
a^c-A^c\approx cA^{c-1}\delta
$$

이다. 따라서

$$
(a^c-A^c)^2\approx c^2A^{2c-2}\delta^2
$$

가 된다. $$2c-2<0$$이므로 작은 absolute error가 같다면 $$A$$가 작을수록 상대적으로 더 큰 가중치가 적용된다. 다만 이는 $$\delta$$가 충분히 작을 때 성립하는 국소 근사다. 0 부근에서는 미분이 불안정해질 수 있으므로 floor 등의 처리가 필요하다.

</details>

예를 들어 $$1^c=1$$이고 $$100^{0.3}\approx3.98$$이므로, 100배의 차이가 압축 후에는 약 4배로 줄어든다. **Loss 내부의 압축은 오차를 평가하는 방식을 바꾸는 연산**이며, 여러 주파수 bin을 Mel band로 합쳐 복원 정보를 잃는 연산과는 다르다.

### 7.2 압축한 magnitude에 phase를 결합해 비교한다

보조 표현을

$$
C_c(S)=\lvert S\rvert^c e^{j\phi_S}
$$

로 정의하고,

$$
L_{\mathrm{complex}}=\sum_{t,k}
\left\lvert C_c(S_{t,k})-C_c(\hat S_{t,k})\right\rvert^2
$$

$$
L=(1-\beta)L_{\mathrm{mag}}+\beta L_{\mathrm{complex}},\qquad 0\le\beta\le1
$$

로 둔다. $$\beta=0$$이면 magnitude만 비교하고, $$\beta=1$$이면 phase를 포함한 복소 비교를 수행한다. 이 $$C_c$$는 loss 계산을 위한 표현이며, iSTFT에 그대로 입력하는 일반적인 STFT 계수가 아니다.

정답과 예측이 같을 때 두 loss가 모두 0이 되도록 **양쪽 magnitude에 같은 지수 $$c$$를 사용한다**. 원문 p. 24의 복소 loss는 한쪽 지수가 2로 인쇄되어 있는데, 이를 그대로 옮기면 이 성질이 깨지므로 여기서는 수정했다.

<a href="https://arxiv.org/abs/2009.12286" target="_blank" rel="noopener">Braun and Tashev (2020)</a>의 비교는 magnitude-only objective와 phase-aware objective의 조합을 특정 enhancement 모델에서 평가한 결과다. 그림에서 가장 좋았던 $$\beta$$를 다른 model과 dataset에도 보편적으로 적용되는 값으로 사용해서는 안 된다. Fixed mixture phase를 사용하는 경우에도 complex loss는 magnitude를 조정하는 학습에 영향을 주지만, 이것이 phase predictor를 추가했다는 뜻은 아니다.

## 8. Waveform loss와 spectral loss를 결합한다

### 8.1 하나의 window로는 포착하지 못하는 차이가 있다

짧은 STFT window는 순간적인 변화를 포착하기 쉽고, 긴 window는 세밀한 주파수 차이를 보기 쉽다. Waveform L1과 여러 resolution의 STFT loss를 결합하면 sample 오차와 시간·주파수 구조를 동시에 학습 목표로 삼을 수 있다(p. 25).

대표적인 multi-resolution STFT objective의 한 예에서는 resolution $$r$$마다 magnitude $$A_r$$와 $$\hat A_r$$를 계산한다.

같은 예측 파형을 여러 window 길이로 분석하면, 짧은 구간에서 잘 맞는지와 세밀한 주파수 구조까지 맞는지를 함께 확인할 수 있다. **서로 다른 소리를 순차 생성하는 것이 아니라 같은 출력에 여러 검사를 적용한다.**

<details markdown="block">
<summary markdown="span">Derivation: waveform and multi-resolution spectral objectives</summary>

$$
L_{\mathrm{sc},r}
=\frac{\lVert A_r-\hat A_r\rVert_F}{\lVert A_r\rVert_F+\varepsilon}
$$

$$
L_{\mathrm{log},r}
=\frac{1}{T_rF_r}\sum_{t,k}
\left\lvert\log(A_{r,t,k}+\varepsilon)
-\log(\hat A_{r,t,k}+\varepsilon)\right\rvert
$$

$$
L_{\mathrm{total}}=L_{\mathrm{wave},1}
+\lambda\frac{1}{R}\sum_{r=1}^{R}
\left(L_{\mathrm{sc},r}+L_{\mathrm{log},r}\right)
$$

$$\lVert\cdot\rVert_F$$는 matrix의 모든 원소를 제곱해 더한 뒤 제곱근을 취하는 Frobenius norm이고, $$T_r,F_r$$는 frame과 bin의 수이며, $$\lambda$$는 가중치다. 이는 사용할 수 있는 objective의 한 예일 뿐이며, 구현에 따라 sum과 mean, log 처리 방식이 달라진다.

</details>

Spectral convergence는 전체적인 relative magnitude error를 측정하고, log term은 dynamic range를 압축한 차이를 측정한다. 이 magnitude 항들은 phase를 직접 비교하지 않지만, 별도의 waveform 항은 시간 파형을 비교한다. 각 항이 phase를 어떤 방식으로 반영하는지 구분해서 보아야 한다.

### 8.2 여러 source의 순서를 PIT로 맞춘다

두 화자의 음성을 분리할 때 network의 출력 1이 화자 A, 출력 2가 화자 B가 된다는 보장은 없다. 반대 순서로 올바른 파형이 출력되어도 고정된 대응 관계로 비교하면 부당하게 큰 loss가 발생한다.

Permutation invariant training은 output과 target의 가능한 대응마다 loss를 계산하고, 그중 가장 작은 대응을 선택한다.

$$
L_{\mathrm{PIT}}
=\min_{\pi\in\mathfrak S_K}\sum_{i=1}^{K}
\ell(s_i,\hat s_{\pi(i)})
$$

$$\mathfrak S_K$$는 $$K$$개 source의 모든 permutation 집합이다. Source가 두 개라면 두 가지 대응만 비교하면 된다.

| Target과 output 사이의 loss | Output 1 | Output 2 |
|---|---|---|
| Source A | 9 | 1 |
| Source B | 2 | 8 |

고정된 순서의 합은 $$9+8=17$$이고, 대응을 바꾼 합은 $$1+2=3$$이므로 loss는 3을 선택한다. 선택된 대응의 loss로부터 gradient를 계산한다. 여기서 사용한 값은 설명을 위한 pairwise loss이며, 실제 음성을 측정한 평가 결과가 아니다.

Utterance-level PIT는 발화 전체에 하나의 대응을 적용해 frame마다 output 화자가 바뀌는 문제를 줄인다. PIT가 다루는 대상은 source의 **출력 순서**이며, 각 waveform 내부의 시간 순서나 sample alignment가 아니다.

## 9. Spectrogram을 다루는 모델

### 9.1 DCCRN — 복소 연산을 network에 포함한다

<figure id="speech-06-p29">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p29.png" | relative_url }}" alt="DCCRN의 복소 convolution 블록과 STFT encoder LSTM decoder mask iSTFT 전체 경로를 보여 주는 강의 슬라이드" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=29" | relative_url }}">lecture PDF, p. 29</a>.</figcaption>
</figure>

왼쪽 복소 convolution은 실수·허수 입력을 교차 결합한다. 가운데 모델은 빨간 입력 파형을 Conv-STFT, complex encoder, LSTM, decoder, complex mask, Conv-iSTFT 순으로 처리해 파란 출력 파형을 만든다. 오른쪽의 빨강·파랑 곡선은 spectrogram이 아니라 시간 파형이고, 아래 표는 PESQ 비교다. 파형이 매끈해 보인다는 이유만으로 품질 향상을 판정하지 않는다.

Magnitude만 처리하는 모델은 spectrum의 각 점이 원점에서 얼마나 떨어져 있는지 주로 다룬다. DCCRN은 **그 점의 실수 좌표와 허수 좌표를 함께 보존하고, 두 좌표가 섞이는 방식도 복소수 곱에 맞춘다.** 위상각을 별도의 정답 숫자로 입력하지 않아도 두 좌표로부터 위상을 계산할 수 있다.

입력 STFT의 실수부와 허수부는 실제 신호 분석값이지만, network 내부의 중간 feature는 **학습된 복소 특징**이다. 중간 feature의 허수부 하나가 특정 소리의 도착 시간이나 실제 음압을 직접 의미한다고 단정할 수는 없다. 마지막 복소 mask나 spectrum을 어떻게 만들고 waveform으로 합성하는지까지 연결해야 물리적 출력이 정해진다.

슬라이드 p. 29의 두 코드 줄에서 `out_real`은 실수 입력만으로, `out_imag`는 허수 입력만으로 만들어지지 않는다. **두 출력 모두 두 입력을 사용한다.** 실수 출력에서 허수 입력의 결과를 빼고, 허수 출력에서는 두 교차 결과를 더한다. 이 결합을 통해 한쪽 좌표를 바꿀 때 다른 쪽 좌표와의 관계도 학습에 반영된다.

<details markdown="block">
<summary markdown="span">Derivation: complex convolution and shared real-valued kernels</summary>

STFT를 $$X=X_r+jX_i$$, convolution kernel을 $$W=W_r+jW_i$$라고 두자. 복소수의 곱을 전개하면

$$
\begin{aligned}
W\ast X&=W_r\ast X_r+jW_r\ast X_i+jW_i\ast X_r+j^2W_i\ast X_i\\
&=(W_r\ast X_r-W_i\ast X_i)\\
&\quad+j(W_r\ast X_i+W_i\ast X_r)
\end{aligned}
$$

가 된다. Convolution의 선형성과 $$j^2=-1$$을 사용한 정확한 항등식이다. 여기서 $$\ast$$는 convolution 기호이며 복소켤레가 아니다. p. 29의 코드는 이 연산을 두 개의 실수 tensor로 구현한 형태다.

~~~python
# Bias-free convolution operators illustrate the complex product.
out_real = conv_real(x_real) - conv_imag(x_imag)
out_imag = conv_real(x_imag) + conv_imag(x_real)
~~~

각 `conv_real`과 `conv_imag` 연산은 같은 kernel을 반복해서 사용한다. 따라서 서로 다른 네 개의 임의 kernel을 사용하는 일반적인 2-channel convolution과는 weight의 결합 방식이 다르다. Bias를 사용할 때도 단순히 두 번 더하지 말고 복소 bias의 정의에 맞추어야 한다.

</details>

한 위치만 보는 설명용 kernel을 $$W=j$$로 두면 $$WX=-X_i+jX_r$$이다. $$X=1$$은 $$j$$가 된다. **길이는 1로 유지되고 방향만 90도 회전**한다. 실제 DCCRN의 여러 위치를 합치는 convolution은 이 한 점 회전보다 복잡하지만, 허수 kernel이 크기와 위상의 결합을 처리할 수 있는 이유를 이 계산에서 볼 수 있다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: a one-point complex convolution check</summary>

다음 코드는 학습된 DCCRN이 아니라 kernel 크기 1, bias 0인 복소 선형 연산의 검산이다. 각 scalar를 한 원소 tensor로 생각하면 슬라이드의 두 convolution 결과와 같은 곱셈 규칙을 확인할 수 있다.

~~~python
import math

x_real, x_imag = 1.0, 0.0
w_real, w_imag = 0.0, 1.0

out_real = w_real * x_real - w_imag * x_imag
out_imag = w_real * x_imag + w_imag * x_real
magnitude = math.hypot(out_real, out_imag)
phase_degrees = math.degrees(math.atan2(out_imag, out_real))

print(out_real, out_imag, magnitude, phase_degrees)
# 0.0 1.0 1.0 90.0
~~~

`out_real`과 `out_imag`는 출력 좌표다. `hypot`는 두 좌표의 제곱합에 제곱근을 취하므로 크기 1을 반환한다. `atan2`는 좌표의 방향을 rad로 계산하며, `degrees`가 이를 90도로 바꾼다. 허수 출력 1을 “위상 1 rad”로 읽어서는 안 된다. **좌표를 먼저 얻고, 그 좌표 쌍에서 각도를 계산한다.**

일반적인 batch 입력을 `[batch, channel, frequency, frame]`으로 저장한다면 실수 tensor와 허수 tensor의 shape는 서로 같아야 한다. Kernel, stride, padding은 출력 shape를 결정하므로 같은 곱셈 규칙을 써도 원본 STFT와 shape가 그대로 같다는 보장은 없다. 실제 모델에서는 decoder가 mask의 bin/frame 크기를 복원하고, 그 mask를 보존된 입력 STFT에 적용한다.

</details>

슬라이드 p. 29의 왼쪽 그림은 두 좌표가 convolution·normalization·activation을 거쳐 복소 feature로 바뀌는 **block 내부**를 보여 준다. 오른쪽은 noisy waveform에서 STFT, encoder, LSTM, decoder, mask 적용, iSTFT로 이어지는 **전체 경로**다. Encoder는 인접 시간·주파수 구조를, recurrent block은 시간 문맥을 처리한다. Skip connection은 encoder의 세부 특징을 decoder에 전달한다. 마지막에 입력 spectrum을 다시 사용하는 선은 원래 정보를 보존한 채 추정 mask를 적용한다는 뜻이다. 이것을 마지막 kernel의 단순 역연산으로 읽으면 안 된다.

<a href="https://www.isca-archive.org/interspeech_2020/hu20g_interspeech.pdf" target="_blank" rel="noopener">DCCRN</a>은 encoder–decoder와 recurrent 처리에 complex representation을 도입하고 complex mask 등을 사용해 위상을 다룬다. Real/imag 값을 입력했다는 사실만으로 phase가 정확히 복원되는 것은 아니므로, output 정의와 loss도 함께 확인해야 한다.

### 9.2 MDX-Net — 시간·주파수의 local structure와 전체 문맥을 함께 사용한다

p. 30의 TFC는 time-frequency convolution으로 인접한 구조를 처리하고, TDF는 time-distributed fully connected 연산으로 각 frame에서 주파수 방향의 관계를 처리한다. 이 <a href="https://archives.ismir.net/ismir2020/paper/000046.pdf" target="_blank" rel="noopener">TFC-TDF 구조</a>에서는 U-Net의 encoder가 넓은 문맥을 받아들이고 skip connection이 세부 정보를 decoder로 전달한다.

Source별로 학습한 model이나 stream의 결과를 mixer에서 결합하는 <a href="https://mdx-workshop.github.io/proceedings/mkim.pdf" target="_blank" rel="noopener">MDX-Net</a> 계열 구조에서는 vocals, drums 등에 특화된 추정과 여러 추정의 통합을 구분해 생각할 수 있다. TFC-TDF와 MDX-Net은 같은 이름의 단일 모델이 아니라 별도의 모델 계열이다. 슬라이드의 구조는 소개된 MDX 계열 모델에 해당하며, 모든 music separator가 source별 독립 network를 사용하는 것은 아니다.

### 9.3 FullSubNet+ — 전체 대역과 좁은 대역의 문맥을 함께 사용한다

<figure id="speech-06-p31">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p31.png" | relative_url }}" alt="Magnitude real imaginary 입력이 MulCA와 full-band extractor 및 sub-band model을 거쳐 복소 mask 두 성분을 출력하는 FullSubNet+ 구조" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=31" | relative_url }}">lecture PDF, p. 31</a>.</figcaption>
</figure>

왼쪽의 magnitude, real, imaginary 세 입력은 각각 MulCA와 full-band extractor를 지난다. 중심 bin 주변 magnitude는 `Unfold`로 모으고, 세 full-band 특징과 이어 붙여 sub-band LSTM에 보낸다. 오른쪽의 두 출력은 complex mask의 real·imaginary 성분이다.

<figure id="speech-06-p32">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p32.png" | relative_url }}" alt="FullSubNet+ 제목과 아이디어 문장 아래에 with reverb와 without reverb 성능을 나눈 비교표" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=32" | relative_url }}">lecture PDF, p. 32</a>.</figcaption>
</figure>

표는 with reverb와 without reverb를 나누고 WB-PESQ, NB-PESQ, STOI, SI-SDR를 비교한다. FullSubNet과 FullSubNet+의 행을 비교할 때는 같은 reverberation 조건과 같은 지표의 열을 맞춘다. 한 열의 개선이 모든 조건에서 같은 정도의 개선을 뜻하지는 않는다. 상단의 ‘2-component phase’는 아래에서 구분하는 real·imaginary 표현과 연결해 읽고, 실제 모델의 연결은 p.31 구조도를 기준으로 확인한다.

모든 frequency를 함께 보는 full-band branch는 발화 전체의 harmonic과 넓은 spectral pattern을 처리할 수 있다. Sub-band branch는 특정 주파수 주변의 변화를 시간 방향으로 추적한다. 두 branch를 함께 사용해 넓은 구조와 국소적인 noise pattern을 나누어 처리한다(pp. 31–32).

<a href="https://arxiv.org/abs/2203.12188" target="_blank" rel="noopener">FullSubNet+</a>는 magnitude, real, imaginary representation과 channel attention, full-band 및 sub-band 처리를 결합한다. Real/imaginary는 **위상각 자체를 두 값으로 나눈 것이 아니다**. 두 값으로부터 $$\operatorname{atan2}(X_i,X_r)$$를 이용해 phase를 구할 수 있으며, 크기 정보도 함께 포함한다.

비교표를 읽을 때는 with/without reverb 조건, WB/NB-PESQ 구분, STOI의 표시 척도를 맞추어야 한다. FullSubNet과 FullSubNet+의 모델명·버전을 구분하고, 표의 연도만으로 같은 모델이라고 판단해서는 안 된다.

**문제의식은 복소 mask를 예측하면서 입력에서는 위상 관련 좌표를 버린다는 불일치다.** 기존 FullSubNet은 magnitude를 입력받아 complex ideal ratio mask(cIRM)를 추정한다. FullSubNet+는 real·imaginary 입력을 추가하고, 주파수별 중요도를 조절하는 MulCA와 full-band TCN을 결합한다. 따라서 새로움은 단순히 “mask를 사용한다”가 아니라, **mask를 결정할 때 어떤 정보를 함께 보고 얼마나 효율적으로 처리하는가**에 있다. 다음 설명은 <a href="https://arxiv.org/html/2203.12188v2" target="_blank" rel="noopener">ICASSP 2022 논문 v2</a>의 구조와 실험을 기준으로 한다.

#### 그림의 세 입력에서 두 출력까지

슬라이드 p. 31의 위쪽 세 입력은 서로 다른 녹음이 아니다. **같은 noisy STFT의 magnitude, real, imaginary 표현**이다. 세 입력을 왼쪽에서 오른쪽으로 따라가면 다음 순서가 된다.

| 그림의 위치 | 들어오는 값과 나오는 값 | 이 단계가 필요한 이유 |
| --- | --- | --- |
| 세 개의 MulCA | 각 표현에서 주파수별 가중치를 계산하고 원래 표현에 곱함 | 주파수마다 같은 비중을 주지 않고 서로 다른 시간 범위의 패턴을 반영 |
| 세 개의 full-band extractor | 전체 주파수 정보를 처리해 각각의 spectral embedding을 생성 | 한 bin만으로는 구별하기 어려운 harmonic과 넓은 대역의 관계를 전달 |
| magnitude 쪽 Unfold | 중심 bin 주변의 이웃 bin들을 하나의 묶음으로 만듦 | 좁은 주파수 구간의 시간 변화를 직접 추적할 정보 제공 |
| Concat | local magnitude 묶음과 세 full-band 특징을 결합 | 국소 변화와 전역 문맥을 같은 sub-band 모델에 전달 |
| 두 LSTM과 Linear | 시간 흐름을 처리해 mask의 real·imaginary 두 성분을 출력 | 목표 성분을 복원할 크기 조정과 회전을 함께 추정 |

MulCA의 가중치와 최종 복소 mask는 역할이 다르다. **MulCA는 내부 특징의 중요도를 조절하며, 최종 mask는 입력 STFT에 적용해 소리를 복원한다.** 그림의 모든 곱셈을 noise 제거용 mask로 읽으면 두 단계가 섞인다. Full-band의 LSTM을 TCN으로 바꿨더라도 sub-band에는 LSTM이 남아 있으므로 전체 모델을 convolution-only 구조라고 부를 수 없다.

<details markdown="block">
<summary markdown="span">Figure Analysis: Full-Band and Sub-Band Tensor Flow</summary>

한 발화의 입력을 주파수 bin 수 $$F$$, frame 수 $$T$$인 행렬로 생각하면 magnitude·real·imaginary는 모두 $$F\times T$$다. 각 full-band branch의 출력도 주파수와 frame 위치에 대응한다. 중심 bin $$f$$에서는 세 branch에서 그 위치의 특징을 하나씩 가져온다.

별도의 local magnitude 경로는 중심 양옆 $$n$$개씩, 총 $$2n+1$$개 bin을 묶는다. 여기에 세 full-band 특징을 붙이면 각 frame의 특징 수는 $$2n+4$$개다. 논문의 $$n=15$$ 설정에서는 31개의 local magnitude 값과 3개의 full-band 값이 합쳐져 34개가 된다. 주파수 경계의 이웃은 논문에서 circular 처리한다.

MulCA는 시간 방향의 서로 다른 kernel 크기를 사용하는 depthwise convolution과 pooling으로 주파수별 가중치를 만든다. 같은 frequency channel의 가중치는 시간축에 걸쳐 적용된다. 여기서 channel은 입체음향의 좌·우 채널이 아니라 **주파수 bin에 대응하는 특징 축**이다.

TCN의 dilated convolution은 간격을 둔 시간 위치를 참조해 문맥 범위를 넓힌다. 그림의 residual 경로는 입력 특징을 변환 결과에 더한다. Sub-band의 LSTM은 결합된 특징의 시간 순서를 처리한다. 논문의 실험은 16 ms hop에서 2 frame, 즉 32 ms look-ahead를 사용하므로 “미래 frame을 전혀 보지 않는 지연 0 모델”로 해석하면 안 된다.

</details>

#### 왜 mask가 두 성분이어야 하는가

Noisy STFT를 $$Y$$, 목표 STFT를 $$S$$라고 쓰자. 이상적인 복소 mask는 $$M=S/Y$$이며, 예측 mask를 곱한 $$\hat S=\hat M Y$$를 iSTFT에 넣는다. 실수 mask 하나는 주로 혼합 신호의 크기를 조정하지만, 복소 mask는 **크기와 방향을 함께 바꿀 수 있다**. 예를 들어 $$Y=1+j$$에서 목표가 $$S=1$$이면 $$M=0.5-0.5j$$를 곱해야 한다. 크기를 줄이는 동시에 위상을 $$-\pi/4$$만큼 돌려 허수 성분을 없애는 것이다.

<details markdown="block">
<summary markdown="span">Derivation: Complex Ratio Mask and Stable Compression</summary>

$$Y=Y_r+jY_i$$, $$S=S_r+jS_i$$로 놓고 분모의 켤레복소수를 곱한다. $$Y\ne0$$일 때 다음과 같다.

$$
M=\frac{S}{Y}=\frac{(S_r+jS_i)(Y_r-jY_i)}{Y_r^2+Y_i^2}.
$$

따라서 두 정답 좌표는

$$
M_r=\frac{Y_rS_r+Y_iS_i}{Y_r^2+Y_i^2},\qquad
M_i=\frac{Y_rS_i-Y_iS_r}{Y_r^2+Y_i^2}.
$$

복원에서는 두 mask 성분이 두 STFT 좌표에 함께 작용한다.

$$
\hat S_r=\hat M_rY_r-\hat M_iY_i,\qquad
\hat S_i=\hat M_rY_i+\hat M_iY_r.
$$

즉 $$M_r$$를 magnitude, $$M_i$$를 phase 자체라고 해석할 수 없다. 예시에서는 $$\hat S_r=0.5\cdot1-(-0.5)\cdot1=1$$, $$\hat S_i=(-0.5)\cdot1+0.5\cdot1=0$$이다.

실제 구현은 분모에 작은 양수 $$\varepsilon$$를 더해 0 근처의 나눗셈을 안정화한다. 원래 mask 값은 음수이거나 1보다 클 수 있다. 따라서 이것은 각 bin이 speech일 확률을 예측하는 0–1 분류 출력이 아니다.

<a href="https://github.com/RookieJunChen/FullSubNet-plus/blob/b115416d6e2a983c3724fc77d0cdc3d8896a2855/speech_enhance/audio_zen/acoustics/mask.py" target="_blank" rel="noopener">공식 구현의 mask 함수</a>는 각 성분을 기본값 $$K=10$$, $$C=0.1$$로 압축한다.

$$
q=K\frac{1-e^{-Cm}}{1+e^{-Cm}}=10\tanh(0.05m).
$$

모델이 학습하는 압축 좌표와 실제 STFT에 곱할 mask를 구분해야 한다. 역변환은 기본값에서

$$
m=10\log\frac{10+q}{10-q}
$$

이며, 구현은 역변환 전에 $$q$$를 $$[-9.9,9.9]$$로 제한한다. 정답 계산의 $$\varepsilon$$, 압축 전 clipping, 역변환 전 clipping 때문에 극단적인 값까지 이상적 나눗셈과 정확히 같다고 볼 수는 없다.

</details>

<a href="https://github.com/RookieJunChen/FullSubNet-plus/blob/b115416d6e2a983c3724fc77d0cdc3d8896a2855/speech_enhance/fullsubnet_plus/inferencer.py" target="_blank" rel="noopener">공식 추론 코드</a>에서도 network의 두 출력을 역압축한 다음 **보존한 noisy STFT**에 복소 곱셈하고 iSTFT로 돌아온다. Full-band 특징에 mask를 곱하는 것이 아니다. 학습 때만 clean target으로 정답 cIRM를 만들며, 추론 때 clean target은 입력되지 않는다. 이 설명은 코드 경로를 대조한 것이며 모델 학습이나 논문 benchmark를 재실행한 결과는 아니다.

#### 표가 뒷받침하는 범위

슬라이드 p. 32와 논문 Table 1의 DNS synthetic test에서는 with/without reverb 조건을 나눠 읽어야 한다. Without reverb의 WB-PESQ는 FullSubNet 2.813, FullSubNet+ 2.982다. 두 모델의 look-ahead는 모두 32 ms다. 이 비교는 해당 데이터와 평가 조건에서의 결과이지 모든 잡음에서의 우월성을 증명하지 않는다. With reverb의 목표는 마이크에서 관측한 reverberant speech를 복원하는 것이므로 이 결과만으로 dereverberation 성능을 주장할 수도 없다.

논문 Table 3은 phase-related 입력과 MulCA를 제거한 ablation을 제시한다. Without reverb의 WB-PESQ는 전체 모델 2.982, phase-related 입력 제거 2.955, MulCA 제거 2.960이다. 각 구성의 기여를 살펴볼 근거는 되지만 두 효과가 독립적으로 단순 합산된다는 의미는 아니다. 슬라이드 표의 연도와 제목이 다르게 보이더라도 모델명과 인용한 논문 버전을 기준으로 구분한다.

### 9.4 DCCRN과 FullSubNet 계열은 같은 문제를 다른 축에서 푼다

원문 p. 29의 DCCRN과 pp. 31–32의 FullSubNet+는 모두 noisy STFT에서 목표 음성을 복원하지만, 강조점이 다르다. 다음 표는 architecture, 예측 target, mask 적용, loss를 한 과정으로 섞지 않기 위한 비교다.

| 방법 | 해결하려는 문제 | Network가 내는 값과 학습 | 적용과 복원 | 관계 |
|---|---|---|---|---|
| [DCCRN](https://www.isca-archive.org/interspeech_2020/hu20g_interspeech.pdf){:target="_blank" rel="noopener"} | Magnitude만으로는 위상 관련 좌표를 충분히 다루기 어려움 | Complex encoder–recurrent–decoder가 real·imaginary 특징을 교차 결합한다. 강의 그림의 경로에서는 최종 complex mask를 추정한다. | 예측 mask를 noisy complex STFT에 적용하고 iSTFT로 waveform을 만든다. Architecture가 표현 범위를 정하고, 선택한 spectrum·waveform loss가 학습 비교 위치를 정한다. | Complex 연산을 network 내부까지 일관되게 가져가는 별도 설계다. |
| [FullSubNet](https://arxiv.org/abs/2010.15508){:target="_blank" rel="noopener"} | 전체 대역의 전역 문맥과 한 frequency 주변의 국소 문맥을 함께 써야 함 | Noisy magnitude에서 full-band 특징과 sub-band 이웃을 결합해 compressed cIRM 두 성분을 감독 학습한다. | Network 출력을 역압축한 뒤 noisy complex STFT에 곱하고 iSTFT한다. | FullSubNet+가 직접 확장하는 기반 모델이다. |
| [FullSubNet+](https://arxiv.org/abs/2203.12188){:target="_blank" rel="noopener"} | Complex mask를 예측하면서 입력은 magnitude만 쓰는 불일치를 줄이고 full-band 처리를 효율화해야 함 | Magnitude·real·imaginary 입력, MulCA, TCN full-band branch와 LSTM sub-band model로 compressed cIRM을 예측한다. | FullSubNet처럼 역압축한 complex mask를 보존된 noisy STFT에 적용하고 iSTFT한다. | FullSubNet의 직접 확장이다. DCCRN의 직접 후속이라고 볼 근거는 없다. |
{: .reference-candidate-table}

세 방법의 공통점은 complex STFT 복원 경로지만, **DCCRN은 complex-valued network 연산**, **FullSubNet 계열은 full-band와 sub-band 문맥 결합**에 무게를 둔다. MA·SA·waveform loss는 이 architecture들의 이름이 아니라 어느 값에서 정답과 비교할지 정하는 목적함수다. PIT도 여러 source의 출력 순서를 맞추는 학습 규칙이므로, 단일 target enhancement architecture의 다음 block처럼 연결하지 않는다.

## 10. Waveform 및 hybrid 모델

### 10.1 Demucs Denoiser — 학습된 encoder로 파형을 복원한다

pp. 33–40은 CNN encoder, 2계층 LSTM, transposed-convolution decoder, skip connection으로 구성된 waveform 모델을 보여 준다. 고정 STFT의 주파수 bin을 사용하는 대신 CNN이 sample열에서 latent features를 학습한다. LSTM은 이 특징의 시간 문맥을 처리하고 decoder는 다시 파형으로 복원한다.

Skip connection은 세밀한 시간 정보를 encoder에서 decoder로 전달한다. Transposed convolution은 축소된 시간축을 확장하는 학습된 합성 연산이며, 원래 encoder의 수학적으로 엄밀한 역함수라고 보장할 수 없다.

그림 중앙의 LSTM은 general pipeline에서 "masking"에 해당하는 처리 위치에 그려져 있다. 그러나 **Demucs Denoiser가 항상 명시적인 element-wise mask를 예측한다고 해석하는 것은 부정확하다**. Latent sequence를 변환하는 encoder–recurrent–decoder 구조로 이해해야 한다.

작은 구간을 차례로 encode하고 문맥을 처리한 뒤 decode하는 그림은 시간 처리 흐름을 설명한 도식이다. 실제 causal/streaming 가능 여부는 look-ahead, LSTM 방향, convolution padding 등에 따라 달라진다.

원문 p. 41의 SDR 표는 음악 분리용 Demucs v2의 MUSDB18 결과이며, speech denoiser의 PESQ/STOI 결과가 아니다. 모델 이름이 비슷하더라도 task와 metric이 다른 표를 그대로 비교해서는 안 된다.

### 10.2 Hybrid Transformer Demucs — 두 표현 사이에서 정보를 교환한다

<figure id="speech-06-p43">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p43.png" | relative_url }}" alt="STFT와 waveform 두 branch 사이의 self attention 및 cross attention" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=43" | relative_url }}">lecture PDF, p. 43</a>.</figcaption>
</figure>

왼쪽의 STFT branch와 waveform branch는 각각 encoder와 decoder를 가지며 중앙에서 정보를 주고받는다. 오른쪽은 각 branch 안의 self-attention과 서로 다른 branch를 연결하는 cross-attention을 구분해 펼친 것이다. Spectrogram의 시간·주파수 격자를 sequence로 바꾸는 단계도 보인다. 두 입력 표현의 장점을 결합하는 구조이지 ‘위상은 waveform branch에만 있다’는 뜻은 아니다.

Spectrogram branch는 harmonic, 주파수 대역, 음색 구조를 파악하기 쉽다. Waveform branch는 sample열의 시간 구조를 보존한다. Hybrid Transformer Demucs는 두 branch를 Transformer로 연결해 서로 다른 표현의 정보를 결합하고 source를 추정한다(pp. 42–43). 이 dual-domain 구조의 이전 단계인 <a href="https://arxiv.org/abs/2111.03600" target="_blank" rel="noopener">Hybrid Demucs</a>도 waveform과 spectrogram branch를 함께 사용한다.

Waveform에 phase 각도가 명시적으로 저장되는 것은 아니지만, waveform이 정해지면 STFT의 phase도 계산할 수 있다. 이런 의미에서 시간 영역 branch도 phase를 포함한 복원 정보를 다룬다. Spectrogram branch가 complex representation을 사용한다면 그쪽에도 phase 정보가 있다. 따라서 "주파수 영역에는 phase가 없고 시간 영역에만 phase가 있다"고 단순하게 이분해서는 안 된다.

p. 43의 feature scaling을 $$x\in\mathbb R^{T\times D}$$와 channel별 계수 $$\gamma\in\mathbb R^D$$로 나타내면

$$
x'=x\operatorname{diag}(\gamma),\qquad
x'_{t,d}=x_{t,d}\gamma_d
$$

이다. 이는 feature별 scale을 조정하는 연산이며, 물리적인 source waveform이나 위상을 직접 회전하는 연산이 아니다. 실제 layer에서는 이 연산이 residual branch 등 어느 위치에 적용되는지도 확인해야 한다.

p. 44의 표는 2021년 Hybrid Demucs v3 결과이고, 주석의 HT Demucs는 2022년 v4를 가리킨다. 같은 표제 아래에 있어도 version을 구분하고 training data, 추가 data, SDR 계산 방식을 맞추어 평가해야 한다.

### 10.3 Band-Split RNN — 넓은 주파수 관계를 처리하기 전에 대역을 구조화한다

<figure id="speech-06-p46">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/source-captures/speech-06-p46.png" | relative_url }}" alt="Band split sequence band modeling 및 복소 mask 출력을 연결한 BSRNN" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf#page=46" | relative_url }}">lecture PDF, p. 46</a>.</figcaption>
</figure>

왼쪽은 전체 흐름이고 오른쪽은 각 블록의 내부다. 주파수 대역을 나눈 특징을 시간 방향 RNN과 대역 방향 RNN으로 처리한 뒤 대역별 MLP가 mask를 만든다. 마지막 merge는 대역들을 원래 주파수 축 순서로 붙여 복소 mask를 구성한다. 대역 분할은 여러 주파수를 영구적으로 한 값으로 압축하는 Mel 집계와 목적이 다르다.

pp. 45–48의 <a href="https://arxiv.org/abs/2209.15174" target="_blank" rel="noopener">Band-Split RNN</a>은 complex spectrogram을 주파수 band로 나누고 band별 특징을 만든 뒤, dual-path RNN으로 시간 방향과 band 방향을 번갈아 처리한다.

1. **Band split:** 복소 STFT의 주파수축을 여러 대역으로 나눈다.
2. **Band embedding:** 각 대역의 real/imaginary 값을 feature로 변환한다.
3. **Temporal path:** 같은 band의 시간 변화를 추적한다.
4. **Band path:** 같은 시간 위치에서 서로 다른 band의 관계를 활용한다.
5. **Mask estimation:** Band별 MLP로 complex mask를 만들고 원래 STFT에 적용한 뒤 iSTFT로 복원한다.

Mel과의 차이는 "둘 다 band를 만든다"는 사실만으로 판단할 수 없다. BSRNN은 원래 주파수 bin의 대응 관계를 유지하면서 band별 mask를 원래 STFT에 적용한다. 반면 Mel power는 여러 bin을 band sum으로 집계한다. 학습된 내부 embedding은 압축될 수 있지만, **mask를 적용할 원래 spectrum이 복원 경로에 남아 있다**는 점이 중요하다.

Supervised training은 paired mixture/source를 사용한다. Semi-supervised finetuning은 추가 데이터를 활용하는 별도 단계이므로 초기 model의 결과와 동일하게 취급해서는 안 된다. Parameter 수 역시 source별 model, ensemble, channel, version에 따라 달라지므로 "약 37M 대 약 80M"이라는 수치만으로 속도, memory, 품질을 결론내릴 수 없다.

| 계열 | 주요 표현 | 학습 목적 |
|---|---|---|
| Magnitude mask | STFT magnitude와 보존된 mixture phase | 단순한 복원 경로 구성 |
| DCCRN | Complex STFT | Real/imaginary의 관계를 model에 반영 |
| MDX 계열 | Time-frequency features와 여러 stream | 인접 시간 구조·주파수 구조·source 특화 추정을 결합 |
| FullSubNet+ | Full-band와 sub-band의 complex features | 넓은 구조와 국소 문맥을 함께 활용 |
| Demucs Denoiser | Learned waveform representation | 시간 영역에서 직접 enhancement 수행 |
| Hybrid Transformer Demucs | Waveform과 spectrogram | 두 표현 사이에서 정보 교환 |
| Band-Split RNN | Band별 complex STFT features | 시간 방향과 대역 방향을 나누어 처리 |
{: .reference-candidate-table}

## 11. 작은 계산으로 loss와 phase 확인하기

다음 코드는 음성 model을 학습하지 않고 한 bin과 두 bin의 예시를 다시 계산한다. `cmath.rect`는 크기와 각도로 복소수를 만들고, `abs`는 복소수의 크기를 반환한다. 각도는 rad 단위로 전달한다.

계산에서 확인할 질문은 두 가지다. 첫째, 같은 mask 오차가 다른 크기 오차를 만드는가? 둘째, 위상을 고정했을 때 정답 magnitude를 그대로 쓰는 것이 항상 최적인가? 아래 예제의 결과는 각각 **MA 0.02 대 SA 1.04**, **complex error 1 대 0.75**다. 앞의 두 값은 loss 정의가 다르므로 품질 순위로 비교하지 않고, 뒤의 두 값은 같은 기준에서 비교한다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: mask losses and fixed-phase reconstruction</summary>

~~~python
import cmath
import math

mixture_magnitude = [2.0, 10.0]
clean_magnitude = [1.0, 5.0]
target_mask = [0.5, 0.5]
predicted_mask = [0.6, 0.6]

ma = sum((m - target) ** 2
         for m, target in zip(predicted_mask, target_mask))
sa = sum((m * noisy - clean) ** 2
         for m, noisy, clean in zip(
             predicted_mask, mixture_magnitude, clean_magnitude))

clean_bin = cmath.rect(1.0, math.pi / 3)
same_magnitude = cmath.rect(1.0, 0.0)
projected_magnitude = cmath.rect(0.5, 0.0)

print(round(ma, 2), round(sa, 2))
print(round(abs(same_magnitude - clean_bin) ** 2, 2))
print(round(abs(projected_magnitude - clean_bin) ** 2, 2))
# 0.02 1.04
# 1.0
# 0.75
~~~

`zip`은 같은 bin의 예측과 정답을 짝짓는다. MA의 항은 비율 차이를 제곱하고, SA의 항은 `m * noisy`로 실제 크기 추정치를 만든 뒤 정답 크기와 비교한다. `cmath.rect(1.0, math.pi / 3)`은 크기 1, 위상 60도인 정답 점이다. 뒤의 두 예측은 위상이 0도라는 같은 제약 아래 크기만 다르게 선택한다. 복소수 차이에 `abs`를 적용하면 두 좌표의 거리이며, 이를 제곱한 값이 complex squared error다.

</details>

처음 두 숫자는 서로 다른 loss의 값이므로 직접적인 품질 순위가 아니다. 뒤의 두 숫자는 같은 complex squared error로 비교한 결과다. 고정된 0도 위상에서는 크기를 0.5로 투영했을 때 오차가 더 작다는 것을 확인할 수 있다.

이 예시에는 STFT overlap, 실제 audio, model inference가 포함되어 있지 않다. 실제 음성을 평가할 때는 STFT·iSTFT의 window와 hop, tensor shape, source pairing, gain, alignment 조건을 맞추어야 한다.

## Source Check

| 위치 | 잘못 해석하기 쉬운 지점 | 본문에서의 처리 |
|---|---|---|
| pp. 14–16 | Encoder 후보인 Mel과 STFT가 같은 수준으로 invertible해 보임 | Phase discard, band aggregation, log/floor를 구분하고 Mel의 비유일성을 증명 |
| p. 19 | $$\alpha$$ 설명이 "정답을 예측 방향으로 투영한다"는 뜻으로 읽힐 수 있음 | 예측을 정답의 span으로 투영하는 식에서 유도 |
| p. 20, p. 27 | PESQ 범위와 WB score를 하나의 척도로 해석할 수 있음 | NB/WB, raw/MOS-LQO, 구현 조건을 구분 |
| p. 23 | MA→SA→waveform이 반드시 순차적으로 학습해야 하는 단계처럼 보임 | 같은 pipeline에서 서로 다른 비교 위치로 설명 |
| pp. 23–25 | Waveform loss를 사용하면 phase를 자유롭게 학습할 수 있는 것처럼 보임 | Fixed-phase mask의 표현 범위를 명시 |
| p. 24 | 압축 complex loss에서 정답 쪽 지수는 $$c$$, 예측 쪽 지수는 2로 표기됨 | 양쪽 지수를 $$c$$로 맞추고 정답과 예측이 같으면 loss=0인지 확인 |
| p. 27 | Oracle 세 문장의 수치가 일반적인 성능 보장처럼 보임 | Source code와 재현 조건은 미확인. 수치의 독립 재현을 주장하지 않고 구조적 결론만 사용 |
| pp. 31–32 | FullSubNet과 FullSubNet+의 표기 | 모델명·버전을 구분하고 표의 연도만으로 같은 모델이라고 판단하지 않음 |
| p. 41 | Denoiser 제목 아래에 music Demucs v2 결과표가 있음 | Speech enhancement와 MUSDB18 music separation을 분리해 설명 |
| p. 44 | HT Demucs 제목 아래의 표가 Hybrid Demucs v3 결과임 | v3 표와 v4 주석을 구분하고 version을 혼합하지 않음 |

## 마지막 핵심 정리

- **복원에는 분류에 편리한 특징 이상의 정보가 필요하다.** Mel의 주파수 집계와 phase discard는 원래 waveform을 유일하게 복원하는 데 필요한 정보를 줄인다.
- **MA·SA·waveform은 비교 위치가 다르다.** MA는 mask를, SA는 mask 적용 후의 spectrum을, waveform loss는 decoder 이후의 sample을 비교한다.
- **SA는 특정 조건에서 weighted MA가 된다.** Ideal amplitude mask를 사용하면 weight는 $$\lvert Y\rvert^2$$이다. 정의가 다른 IRM에 같은 등식을 적용해서는 안 된다.
- **정답 magnitude만으로 정답 waveform을 만들 수 없다.** Complex error는 magnitude error뿐 아니라 phase 차이와 각 성분의 크기에도 의존한다.
- **PSA의 cosine은 투영에서 나온다.** Clean spectrum을 고정된 mixture phase 방향으로 투영한 값을 target으로 사용한다.
- **Loss와 model의 표현 범위를 맞추어야 한다.** Waveform loss가 phase의 영향을 측정하더라도 fixed-phase mask에 독립적인 phase 예측 능력이 생기지는 않는다.
- **음량과 source 순서를 따로 다루어야 한다.** SI-SNR은 gain을 무시한 shape error를, PIT는 source 대응의 순열 문제를 다룬다.
- **DCCRN과 FullSubNet 계열은 같은 계보가 아니다.** DCCRN은 complex-valued network 연산을, FullSubNet은 full/sub-band 문맥 결합을 강조하며, FullSubNet+가 FullSubNet을 직접 확장한다.

## Study Guide

먼저 2절에서 한 bin에 mask를 적용하는 과정을 따라가고, 4절에서 같은 수치가 MA와 SA에서 어떻게 다르게 비교되는지 계산한다. 이어서 6절의 complex error 전개와 60도 예시를 읽으면 PSA가 단순한 magnitude target과 다른 이유를 이해할 수 있다. 마지막으로 5절의 SI-SNR과 8절의 PIT를 읽으며 각각 무엇에 대한 불변성을 다루는지 구분한다.

모델을 비교할 때는 입력 표현, 원래 complex spectrum이 보존되는 위치, output이 real mask·complex mask·waveform 중 무엇인지, loss를 어느 위치에 적용하는지를 차례로 확인한다. 그림 중앙에 masking이라고 적혀 있어도 구현이 명시적인 mask를 예측한다고 단정할 수는 없다.

## 복습 질문

<details markdown="block">
<summary>1. Log-Mel에서 원래 소리를 복원하기 어려운 이유는 log 변환뿐인가?</summary>

답변: 아니다. 양수 값에 log만 적용했고 기준값을 알고 있다면 역변환할 수 있다. 핵심 문제는 phase를 제거하고, 많은 FFT bin을 소수의 Mel band로 합쳐 서로 다른 입력을 같은 값으로 만드는 데 있다. Floor, clipping, normalization도 추가적인 정보 손실을 일으킬 수 있다.

</details>

<details markdown="block">
<summary>2. MA·SA·Waveform을 순서대로 모두 학습해야 하는가?</summary>

답변: 반드시 그렇지는 않다. 같은 inference pipeline에서 mask, masked spectrum, decoder 이후의 waveform 중 어느 위치를 target과 비교하는지가 다를 뿐이다. 하나를 선택하거나 여러 loss를 결합할 수 있다.

</details>

<details markdown="block">
<summary markdown="span">3. 두 bin의 mask 오차가 같은데도 SA penalty가 다른 이유는 무엇인가?</summary>

답변: Mask 오차에 mixture magnitude를 곱한 값이 spectrum error가 되기 때문이다. Ideal amplitude mask를 target으로 사용하는 조건에서 squared error는 $$\lvert Y\rvert^2(\hat M-M^\ast)^2$$가 된다. 크기가 큰 bin일수록 같은 mask 오차에서도 더 큰 spectrum 오차가 발생한다.

</details>

<details markdown="block">
<summary>4. Waveform loss를 사용하면 mixture phase를 자유롭게 수정할 수 있는가?</summary>

답변: Loss만 바꾸어서는 model output의 자유도가 늘어나지 않는다. Nonnegative real mask와 fixed mixture phase를 사용하는 model은 magnitude만 바꿀 수 있다. Phase의 영향은 loss에 반영되지만, 독립적으로 phase를 보정하려면 complex mask, phase predictor, waveform decoder 등이 필요하다.

</details>

<details markdown="block">
<summary markdown="span">5. 정답 magnitude가 1이고 phase 차이가 60도일 때, 같은 magnitude를 출력해도 complex error는 얼마인가?</summary>

답변: $$2(1-\cos60^\circ)=1$$이다. Magnitude error는 0이지만 phase error가 남는다. Fixed 예측 phase에서 magnitude를 0.5로 줄이면 complex error는 0.75가 되지만, phase 자체가 정확해진 것은 아니다.

</details>

<details markdown="block">
<summary markdown="span">6. PSA target에 $$\cos(\phi_S-\phi_Y)$$가 곱해지는 이유는 무엇인가?</summary>

답변: Clean complex spectrum을 fixed mixture phase 방향으로 투영하기 때문이다. Bin의 error는

$$
(a-A\cos\Delta)^2+A^2\sin^2\Delta
$$

가 되고, 뒤의 항은 magnitude $$a$$를 바꾸어도 줄일 수 없다. 따라서 조정 가능한 앞의 항을 최소화하는 target이 $$A\cos\Delta$$가 된다. Nonnegative constraint나 mask 상한이 있으면 허용 범위로 clip한다.

</details>

<details markdown="block">
<summary>7. SI-SNR이 좋아도 출력 음량이 정확하다고 할 수 없는 이유는 무엇인가?</summary>

답변: Prediction 전체를 0이 아닌 gain으로 scale하면 projected target과 residual도 같은 gain으로 scale되어 energy ratio가 변하지 않기 때문이다. 절대 gain을 평가하려면 SNR이나 waveform loss 등도 함께 확인해야 한다.

</details>

<details markdown="block">
<summary>8. PIT는 음성의 시간 순서를 바꾸는가?</summary>

답변: 아니다. Output source와 target source의 대응만 바꾼다. Waveform 내부의 sample 순서는 유지한다. Utterance-level PIT는 발화 전체에서 하나의 source 대응을 선택한다.

</details>

<details markdown="block">
<summary>9. Band-Split RNN도 대역을 나누므로 Mel과 같은 정보 손실이 발생하는가?</summary>

답변: 같다고 볼 수 없다. Mel에서는 band sum으로 집계한 값만으로 original bin을 일반적으로 유일하게 복원할 수 없다. BSRNN은 band별 특징을 학습하면서도 bin 대응 관계와 mask를 적용할 original STFT를 보존한다. 내부 feature가 압축되더라도 복원 경로에 남는 정보는 별도로 판단해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-06.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture6.pdf — Source Separation 1</a></li>
</ul>

## References

<ul>
  <li><a href="https://github.com/yandexdataschool/speech_course" target="_blank" rel="noopener">Yandex Data School Speech Course</a> — source course linked by the lecture.</li>
  <li><a href="https://github.com/markovka17/dla" target="_blank" rel="noopener">Deep Learning for Audio</a> — source course linked by the lecture.</li>
  <li><a href="https://librosa.org/doc/0.10.2/generated/librosa.feature.inverse.mel_to_stft.html" target="_blank" rel="noopener">librosa: mel_to_stft</a> — approximate magnitude reconstruction.</li>
  <li><a href="https://librosa.org/doc/main/generated/librosa.griffinlim.html" target="_blank" rel="noopener">librosa: griffinlim</a> — iterative magnitude-based phase reconstruction.</li>
  <li><a href="https://arxiv.org/abs/1811.02508" target="_blank" rel="noopener">Le Roux et al.: SDR — Half-baked or Well Done?</a> — scale-invariant projection and evaluation.</li>
  <li><a href="https://arxiv.org/abs/2009.12286" target="_blank" rel="noopener">Braun and Tashev: A Consolidated View of Loss Functions for Supervised Deep Learning-Based Speech Enhancement</a> — magnitude, complex, and compressed losses.</li>
  <li><a href="https://www.jonathanleroux.org/pdf/Weninger2014GlobalSIP12.pdf" target="_blank" rel="noopener">Weninger et al.: Discriminatively Trained Recurrent Neural Networks for Single-Channel Speech Separation</a> — mask approximation and signal approximation objectives.</li>
  <li><a href="https://www.erdogan.org/publications/erdogan15icassp.pdf" target="_blank" rel="noopener">Erdogan et al.: Phase-Sensitive and Recognition-Boosted Speech Separation Using Deep Recurrent Neural Networks</a> — phase-sensitive filtering targets.</li>
  <li><a href="https://arxiv.org/abs/1809.07454" target="_blank" rel="noopener">Luo and Mesgarani: Conv-TasNet</a> — learned waveform representation and SI-SNR.</li>
  <li><a href="https://arxiv.org/abs/1811.11517" target="_blank" rel="noopener">Chai, Du, and Lee: Acoustics-Guided Evaluation (AGE) — A New Measure for Estimating Performance of Speech Enhancement Algorithms for Robust ASR</a> — enhancement evaluation for robust ASR.</li>
  <li><a href="https://arxiv.org/abs/1703.06284" target="_blank" rel="noopener">Kolbæk et al.: Utterance-Level Permutation Invariant Training</a> — source-output correspondence.</li>
  <li><a href="https://www.isca-archive.org/interspeech_2020/hu20g_interspeech.pdf" target="_blank" rel="noopener">Hu et al.: DCCRN — Deep Complex Convolution Recurrent Network for Phase-Aware Speech Enhancement</a> — complex-valued speech enhancement.</li>
  <li><a href="https://archives.ismir.net/ismir2020/paper/000046.pdf" target="_blank" rel="noopener">Choi et al.: Investigating U-Nets with Various Intermediate Blocks for Spectrogram-Based Singing Voice Separation</a> — TFC-TDF architecture for music source separation.</li>
  <li><a href="https://mdx-workshop.github.io/proceedings/mkim.pdf" target="_blank" rel="noopener">Kim et al.: KUIELab-MDX-Net — A Two-Stream Neural Network for Music Demixing</a> — MDX-Net source-specific streams and mixing.</li>
  <li><a href="https://arxiv.org/abs/2010.15508" target="_blank" rel="noopener">Hao et al.: FullSubNet</a> — full-band and sub-band fusion for real-time speech enhancement.</li>
  <li><a href="https://arxiv.org/abs/2203.12188" target="_blank" rel="noopener">Chen et al.: FullSubNet+ — Channel Attention FullSubNet with Complex Spectrograms for Speech Enhancement</a> — full-band and sub-band complex modeling.</li>
  <li><a href="https://arxiv.org/abs/2006.12847" target="_blank" rel="noopener">Défossez et al.: Real-Time Speech Enhancement in the Waveform Domain</a> — Demucs Denoiser.</li>
  <li><a href="https://arxiv.org/abs/2111.03600" target="_blank" rel="noopener">Défossez: Hybrid Spectrogram and Waveform Source Separation</a> — Hybrid Demucs v3.</li>
  <li><a href="https://arxiv.org/abs/2211.08553" target="_blank" rel="noopener">Rouard et al.: Hybrid Transformers for Music Source Separation</a> — dual-domain music separation.</li>
  <li><a href="https://arxiv.org/abs/2209.15174" target="_blank" rel="noopener">Luo and Yu: Music Source Separation with Band-Split RNN</a> — band-wise complex spectrogram modeling.</li>
</ul>
