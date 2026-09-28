---
layout: default
date: 2026-09-21 00:00:00 +0900
last_modified_at: 2026-09-28 16:29:58 +0900
title: "Speech and Audio Recognition Lecture 2: Spectral Analysis Lab"
course: "Speech and Audio Recognition"
topic: "FFT, STFT, Mel Spectrograms, and Cepstral Features"
order: 3
major_topic: "Speech and Audio Processing"
keywords:
  - "FFT"
  - "STFT"
  - "Spectral Leakage"
  - "Mel Spectrogram"
  - "Cepstrum"
  - "MFCC"
  - "Aliasing"
  - "ASR"
  - "WER"
  - "CTC"
---

# Speech and Audio Recognition Lecture 2: Spectral Analysis Lab

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture2-2.pdf</a> — Inkyu An, Kookmin University (23 pages).

앞선 [Digital Signal Processing I](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)에서 sampling, Fourier basis, DFT의 출발점을 다뤘다. 이 글은 두 번째 강의 PDF의 DFT 실습·STFT·mel·cepstrum을 연결한다. **원문에 없는 FFT 유도, sampling spectrum, rect/sinc 관계와 ASR 연결은 작성자의 보충 설명**으로 구분한다. 강의 슬라이드의 Colab 실습 화면(pp.8, 15, 18, 23)은 결과 그림이 무엇을 검사하는지 설명하되, 별도 notebook의 코드와 실행 결과를 이 글에서 재현했다고 주장하지 않는다.

> **핵심:** FFT는 DFT의 정의를 바꾸지 않고 계산을 재사용한다. STFT는 유한한 시간 창마다 주파수를 계산해 시간 변화를 드러내지만 창 길이와 모양 때문에 시간·주파수 분해능과 spectral leakage가 함께 결정된다. Mel filterbank, log, DCT는 표현을 다시 조직하는 단계이지 인식 정확도를 보장하는 연산이 아니다.

## 전체 흐름

Source Materials: <a href="{{ "/assets/materials/study/speech-spectral-analysis/sar-lec01-public.ipynb" | relative_url }}" download>Notebook</a> · <a href="{{ "/assets/materials/study/speech-spectral-analysis/aliasing-dtfs-n8.html" | relative_url }}" target="_blank" rel="noopener">Aliasing Demo</a>. 노트북은 코드와 저장 그림을 유지하고 실행 계정 메타데이터·설치 로그를 제거한 공개용 사본이다.

| 원문 쪽 | 주제 | 이 글에서 확인할 질문 |
|---|---|---|
| 2–8 | DFT·IDFT, FFT, 실수 신호의 대칭성 | 왜 10/100 Hz 봉우리가 양끝에 반복되며 FFT는 무엇을 줄이나? |
| 9–15 | STFT, window, 복소 스펙트럼, log 표시, iSTFT | 언제 시간 위치를 알 수 있고 언제 원 신호를 복원할 수 있나? |
| 16–18 | Mel scale과 filterbank | 선형 Hz bin을 왜 폭이 다른 band로 묶나? |
| 19–23 | F0, harmonic, formant, cepstrum, MFCC | 주기적 미세 구조와 spectral envelope를 어떻게 분리하나? |

### 기호와 단위

| 기호 | 뜻 | 단위·성격 |
|---|---|---|
| $$f_s,F_0,f,\Delta f$$ | sampling rate, 기본 주파수, 주파수, bin 간격 | Hz |
| $$T_s,T_w,t$$ | sampling 간격, 창 시간 폭, 연속시간 | s |
| $$n,k,m,r,b,q$$ | sample, frequency bin, frame, 내부 합, mel band, quefrency bin의 index | 무차원 정수 |
| $$N,L,H,N_{\mathrm{FFT}}$$ | DFT 길이, 창 길이, hop, FFT 길이 | samples로 센 개수; 수학적으로 무차원 |
| $$w[r]$$ | 시간 창의 가중치 | 무차원 |
| $$H_b[k]$$ | mel 필터의 가중치 | peak 1 정규화는 무차원; Hz 면적 정규화는 Hz 역수의 scale을 포함하므로 구현을 명시 |
| $$x[n],X[k],S[m,k]$$ | 디지털 표본과 변환 계수 | 기본적으로 디지털 진폭 또는 그 합의 scale; V나 Pa로 자동 해석하지 않음 |
| $$\arg S,D_{\mathrm{amp}}$$ | 복소 위상과 기준 대비 로그 진폭비 | rad(각도), dB(무차원 비율의 로그) |

실제 마이크 압력(Pa)이나 전압(V)으로 보정한 $$x[n]$$을 넣으면 변환 계수에도 해당 진폭 단위를 추적할 수 있다. 그렇지 않은 일반 PCM·정규화 배열에서 FFT 숫자 5000은 물리적 음압 5000 Pa를 뜻하지 않는다. 창·FFT의 정규화가 바뀌면 같은 표본의 계수 수치도 달라진다.

## 1. DFT가 계산하는 값과 FFT가 절약하는 계산

### 1.1 정규화와 단위부터 고정하기

PDF p.2의 convention을 따른다. $$x[n]$$은 $$n=0,\ldots,N-1$$의 표본이고, $$N$$은 양의 표본 개수다. 표본화율 $$f_s$$의 단위는 Hz, $$n/f_s$$는 초, $$k$$는 무차원 bin index다. 이 convention에서 $$X[k]$$는 입력 디지털 진폭의 평균화된 복소 계수이며, 입력이 물리 단위로 보정되지 않았다면 계수도 물리량이 아니다.

$$
X[k]=\frac{1}{N}\sum_{n=0}^{N-1}x[n]e^{-j2\pi kn/N},\qquad
x[n]=\sum_{k=0}^{N-1}X[k]e^{j2\pi kn/N}.
$$

왜 역변환이 성립할까? 둘째 식에 첫째 식을 대입하고 합의 순서를 바꾸면 내부에 $$N^{-1}\sum_{k=0}^{N-1}e^{j2\pi k(n-m)/N}$$가 생긴다. $$n=m$$이면 합이 1이고, $$0\le n,m<N$$에서 $$n\ne m$$이면 등비수열의 합이 0이다. 그래서 원래 $$x[n]$$만 남는다. **앞변환에 $$1/N$$을 놓는 선택은 관례**다. 앞변환을 무정규화하고 역변환에 $$1/N$$을 놓아도 같은 신호를 얻지만, 두 식과 그래프의 진폭은 하나의 convention으로 읽어야 한다.

Bin 간격은 $$\Delta f=f_s/N$$ Hz다. $$0\le k\le N/2$$에서는 $$f_k=kf_s/N$$로 읽고, 나머지 bin은 $$f_k=(k-N)f_s/N$$의 음의 주파수로 해석한다(짝수 $$N$$의 Nyquist bin은 별도 경계). 이 해석은 $$e^{-j2\pi(k+N)n/N}=e^{-j2\pi kn/N}$$라는 정확한 주기성에서 나온다.

### 1.2 짝수·홀수 분해로 butterfly가 나온다 — 작성자 보충 유도

PDF p.3은 FFT가 대략 $$O(N\log N)$$이라고만 밝힌다. 왜 그런지 보기 위해 우선 $$N$$이 2의 거듭제곱이라고 가정하고 **무정규화** 합 $$F_N[k]=\sum_{n=0}^{N-1}x[n]W_N^{kn}$$, $$W_N=e^{-j2\pi/N}$$를 계산한다. 최종 $$X[k]=F_N[k]/N$$이므로 p.2의 정의와 일치한다.

$$n=2r$$과 $$n=2r+1$$을 분리하면, 길이 $$N/2$$인 두 DFT $$E[k]$$와 $$O[k]$$를 재사용할 수 있다.

$$
\begin{aligned}
F_N[k]
&=\sum_{r=0}^{N/2-1}x[2r]W_{N/2}^{kr}
 +W_N^k\sum_{r=0}^{N/2-1}x[2r+1]W_{N/2}^{kr}\\
&=E[k]+W_N^kO[k],\\
F_N[k+N/2]&=E[k]-W_N^kO[k]\qquad (0\le k<N/2).
\end{aligned}
$$

마지막 줄은 $$W_N^{k+N/2}=-W_N^k$$에서 나온다. 같은 $$E,O$$로 두 출력을 만드는 결합이 butterfly다. 한 단계의 결합 비용은 $$O(N)$$이고 길이가 절반인 문제 두 개를 푸므로 $$T(N)=2T(N/2)+O(N)=O(N\log_2N)$$이다. 직접 DFT의 $$N$$개 출력마다 $$N$$항을 더하는 $$O(N^2)$$와 비교하자. 이것은 radix-2 설명이며 임의 길이 FFT의 모든 구현이 꼭 이 모양이라는 뜻은 아니다.

예를 들어 $$N=8$$이면 길이 4 DFT 두 개를 결합해 8개 bin을 얻는다. p.2 convention을 유지하려면 마지막에 8로 나누거나 각 재귀 단계에서 일관되게 정규화해야 한다. 무정규화 FFT 출력의 높이를 정규화 DFT 그림의 높이와 직접 비교하면 8배 차이가 난다.

### 1.3 두 sine의 네 봉우리와 켤레대칭

PDF pp.4–8의 신호는 $$x(t)=10\sin(2\pi10t)+3\sin(2\pi100t)$$다. Sampling 조건이 두 성분을 alias 없이 담고 관측 길이가 정수 주기를 포함해 bin에 정확히 맞는다면, p.2 convention에서 양·음의 10 Hz 성분의 magnitude는 각각 5, 100 Hz 성분은 각각 1.5다. 이는 $$\sin\theta=(e^{j\theta}-e^{-j\theta})/(2j)$$에 따른 **진폭 분할**이다. $$f_s=2000$$ Hz인 pp.4–6의 0–2000 Hz 축에서는 1900 Hz가 −100 Hz, 1990 Hz가 −10 Hz bin에 해당한다. 오른쪽 두 봉우리는 새로운 1900/1990 Hz 진동이나 sampling alias가 아니라 **실수 신호의 음의 주파수 표현**이다.

실수 $$x[n]$$에는 $$X[N-k]=X[k]^{*}$$가 성립한다. 실제로 $$X[N-k]$$의 지수를 정리하면 $$e^{+j2\pi kn/N}$$가 되고, $$x[n]$$이 실수이므로 $$X[k]$$의 켤레와 같다. 복소 신호에는 일반적으로 이 대칭이 없다. p.7의 관계를 사용할 때 이 전제를 빼지 않는다. p.8 실습 화면의 5000/1500 높이는 무정규화 FFT의 크기로 읽어야 하며 p.4의 정규화된 5/1.5와 같은 숫자로 비교하지 않는다.

## 2. STFT: 신호가 변하는 때를 보려면

### 2.1 프레임·hop·주파수 bin의 좌표

전체 녹음의 DFT는 성분의 존재를 알려 주지만 그 소리가 **언제** 났는지는 잃는다. PDF pp.9–10은 길이 1024표본의 창을 256표본씩 옮기는 그림으로 STFT를 도입한다. 아래는 창 길이 $$L$$, hop $$H$$, FFT 길이 $$N_{\mathrm{FFT}}\ge L$$, 창 $$w[r]$$에 대한 작성자 표기다.

$$
S[m,k]=\sum_{r=0}^{L-1}x[mH+r]w[r]e^{-j2\pi kr/N_{\mathrm{FFT}}}.
$$

$$m,k,r$$는 무차원 index이고 $$H,L,N_{\mathrm{FFT}}$$는 samples로 센 개수다. $$mH/f_s$$는 프레임 시작 시각(초), $$k f_s/N_{\mathrm{FFT}}$$는 bin 중심(Hz)이며, $$L/f_s$$는 창의 시간 폭(초)이다. $$w$$가 무차원이라면 $$S$$는 입력 디지털 진폭의 가중합이지만, 라이브러리의 STFT scaling/정규화 옵션에 따라 수치 scale이 달라진다. 무패딩·비중심 프레임에서 $$N_{\mathrm{frame}}=1+\lfloor(N_x-L)/H\rfloor$$, $$N_x\ge L$$이다. Center padding, 끝 padding, one-sided 출력은 이 개수와 frequency 행 수를 바꾼다. 실수 입력에 짝수 $$N_{\mathrm{FFT}}$$인 one-sided STFT라면 행 수는 $$N_{\mathrm{FFT}}/2+1$$이다.

창을 길게 하면 가까운 주파수 성분을 가를 시간이 늘지만 급격한 변화의 시각을 넓은 구간에 섞는다. 짧은 창은 반대로 시간 위치는 좁히되 주파수 peak는 넓어진다. $$\Delta f=f_s/N_{\mathrm{FFT}}$$는 **그려지는 bin 간격**이고, zero-padding으로 $$N_{\mathrm{FFT}}$$만 키워 간격을 촘촘히 해도 관측 창 $$L/f_s$$가 제공한 물리적 분해능을 새로 만들지는 않는다. 1024/256 예에서 프레임 중첩률은 $$1-256/1024=75\%$$다. 이것이 모든 신호에 최적인 값이라는 뜻은 아니다.

### 2.2 Rectangular와 Hann: 경계가 만드는 leakage

PDF p.14는 rectangular와 Hann 창의 spectrogram/phase 그림을 비교한다. 유한 프레임을 그대로 잘라내는 것은 $$w[r]=1$$인 rectangular window를 곱하는 것이다. 프레임 양끝 값이 주기적으로 이어지지 않으면 DFT가 가정하는 반복 경계에 점프가 생겨 에너지가 주변 bin으로 퍼진다. 이것이 **spectral leakage**다. Hann 창 $$w[r]=\tfrac12[1-\cos(2\pi r/(L-1))]$$ ($$0\le r<L$$, 대칭형 convention)은 양 끝을 0으로 낮춰 먼 sidelobe를 줄일 수 있지만, main lobe가 넓어지는 절충이 있다. 라이브러리의 periodic Hann은 분모가 $$L$$이므로 끝점과 복원 조건이 달라질 수 있다. 창을 쓴다고 모든 leakage가 사라지지는 않는다.

**왜 sinc가 연결되는가 — 원문 밖의 연속시간 보충:** 중심 0, 폭 $$T_w>0$$초인 연속 rectangular pulse $$r(t)=1$$ ($$\lvert t\rvert\le T_w/2$$)의 Fourier transform은 정의에서 바로 적분된다. $$f$$의 단위는 Hz다.

$$
\begin{aligned}
R(f)&=\int_{-T_w/2}^{T_w/2}e^{-j2\pi ft}\,dt
=\frac{\sin(\pi fT_w)}{\pi f}\\
&=T_w\operatorname{sinc}(fT_w),\qquad
\operatorname{sinc}(u)=\frac{\sin(\pi u)}{\pi u},\quad\operatorname{sinc}(0)=1.
\end{aligned}
$$

$$R$$의 단위는 초다. 첫 영점은 $$f=\pm1/T_w$$이며 짧은 창일수록 중심 lobe가 넓어진다. 시간에서 곱셈은 주파수에서 convolution이므로 원래 spectrum의 한 선도 창의 sinc형 응답만큼 퍼진다. 이 연속 rect–sinc 쌍을 **이산 rectangular window의 정확한 DTFT와 동일시하면 안 된다.** 길이 $$L$$의 이산 창은 기하급수 합으로

$$
W(e^{j\omega})=\sum_{r=0}^{L-1}e^{-j\omega r}
=e^{-j\omega(L-1)/2}\frac{\sin(L\omega/2)}{\sin(\omega/2)}
$$

가 되며, 분모가 0인 점은 연속 극한으로 정의한다. $$\omega$$는 rad/sample로 무차원이고 이 응답은 $$2\pi$$-주기인 Dirichlet-kernel 형태다. 연속 sinc의 직관은 도움이 되지만 이산 식의 주기성과 정확한 영점은 이 식으로 확인한다. MIT의 <a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/b0a5f07216a4153e8f6160178f0ea764_lecture_04.pdf" target="_blank" rel="noopener">Fourier Transform Lecture 4, pp.2–4</a>는 연속 rectangular pulse 적분을 전개한다.

### 2.3 Magnitude·phase·dB와 iSTFT의 경계

PDF pp.11–12의 STFT는 **복소수 행렬**이다. $$\lvert S[m,k]\rvert$$는 magnitude, $$\arg S[m,k]$$는 phase다. 밝기 표시를 위해 log scale을 쓰면 작은 값도 보이기 쉬워지지만, 0의 로그는 정의되지 않으므로 양수 기준값 $$A_{\mathrm{ref}}$$와 floor $$\epsilon>0$$를 둬야 한다.

$$
D_{\mathrm{amp}}[m,k]=20\log_{10}\frac{\max(\lvert S[m,k]\rvert,\epsilon)}{A_{\mathrm{ref}}}\ \mathrm{dB}.
$$

Power $$P=\lvert S\rvert^2$$를 표시한다면 $$10\log_{10}(P/P_{\mathrm{ref}})$$를 쓴다. 동일한 기준 $$P_{\mathrm{ref}}=A_{\mathrm{ref}}^2$$일 때 두 값이 같다. 진폭비 1, 0.1, 0.01은 각각 0, −20, −40 dB가 되어 큰 동적 범위를 짧은 축에 배치한다. 신호 전체에 양의 gain $$g$$를 곱하면 floor에 걸리지 않은 dB 값에는 $$20\log_{10}g$$가 더해진다. Frame별 최대값을 reference로 선택하면 이 공통 offset은 제거되지만 절대 음량 정보도 잃는다. Floor와 clipping도 서로 다른 작은 값을 같게 만들 수 있다. 기준과 floor를 정하지 않은 dB 숫자끼리는 절대값을 비교할 수 없다. Log 변환은 뒤따르는 모델의 선형 경계나 최적화 양상을 바꿀 수 있지만 새 정보를 생성하거나 **분류 성능을 보장하지 않는다.** 어떤 feature가 유용한지는 task·전처리·모델·평가 데이터에서 따로 검증해야 한다.

PDF p.13의 iSTFT 설명은 조건이 생략된 단순화다. 원래 복소 STFT, 창, hop, padding/center convention과 끝 길이를 알고, 각 표본의 창 제곱합 $$\sum_m w^2[n-mH]$$가 0이 아니며 전체 신호가 프레임으로 덮여야 overlap-add 복원이 가능하다. $$\lvert S\rvert$$나 dB 영상만 남으면 phase를 버렸으므로 일반적으로 정확한 원 파형을 복원하지 못한다. 이 조건과 복원식은 <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html" target="_blank" rel="noopener">SciPy STFT documentation</a>의 NOLA 설명과 일치한다.

### STFT 크기가 작아 보이는 이유와 역변환의 검산

**STFT 자체가 값을 항상 작게 만드는 것은 아니다.** 디지털 입력의 진폭, 프레임 길이, 창 이득, FFT 정규화와 색상 범위가 계수의 크기를 결정한다. 짧은 프레임은 전체 녹음 FFT보다 합하는 표본 수가 적고 Hann 창은 표본에 1 이하 가중치를 준다. 반면 무정규화 합은 입력이 −1~1이어도 1보다 클 수 있다. 선형 그림의 많은 bin이 어두운 이유와 dB 값이 음수인 이유도 다르다. 전자는 큰 값이 색상 범위를 지배하기 때문일 수 있고, 후자는 선택한 기준보다 작다는 뜻이다. 음수 dB는 음의 에너지가 아니다.

복원 조건을 식으로 확인하자. 창을 곱한 프레임의 복소 DFT를 올바른 정규화로 역변환하면 $$v_m[r]=x[mH+r]w[r]$$가 된다. 같은 창을 한 번 더 곱해 겹치는 구간을 더하면

$$
\sum_m v_m[n-mH]w[n-mH]
=x[n]\sum_m w^2[n-mH].
$$

따라서 분모가 0이 아니고 해당 표본이 프레임에 포함되어 있으면

$$
x[n]=\frac{\sum_m v_m[n-mH]w[n-mH]}{\sum_m w^2[n-mH]}.
$$

이것이 같은 분석·합성 창을 사용하는 overlap-add 정규화의 도출이다. 끝부분을 버린 프레임, 위상이 사라진 magnitude, 분모가 0인 경계에서는 이 증명을 그대로 적용할 수 없다. Zero-padding 부분과 원 신호 길이도 구분해야 한다.


## 3. Mel spectrogram: 주파수 축을 다시 모으기

PDF p.16의 곡선은 Hz의 같은 차이가 모든 주파수에서 같은 지각 차이로 들리지 않는다는 동기를 준다. 여기서 '사람이 소리를 log-scale로 듣는다'는 말은 **지각적 pitch 척도를 설명하는 근사**이지 loudness까지 같은 공식으로 설명하거나 개인·음량·실험 조건과 무관한 보편 법칙은 아니다. 슬라이드가 제시한 HTK 계열의 한 mel 정의는

$$
m_{\mathrm{HTK}}(f)=2595\log_{10}(1+f/700),\qquad
f=700\left(10^{m/2595}-1\right)
$$

이다. $$f$$는 Hz, $$m$$은 mel-scale 수치다. $$1127\ln(1+f/700)$$ 표기는 $$2595/\ln10\approx1126.994$$를 반올림한 **근사**다. 따라서 두 상수를 수학적으로 정확히 같다고 쓰지 않는다. Mel 척도는 하나가 아니다. <a href="https://librosa.org/doc/main/api/generated/librosa.mel_frequencies.html" target="_blank" rel="noopener">librosa 공식 문서</a>에 따르면 `htk=True`는 위 HTK 공식을, 기본 `htk=False`는 1 kHz 아래 선형·위 로그인 Slaney 방식을 쓴다. 어느 척도인지 선언하지 않은 mel 숫자와 filterbank는 구현 간 완전히 같다고 볼 수 없다.

PDF p.17의 삼각 filterbank는 STFT의 인접 Hz bin을 mel band별로 가중 합한다. 각 삼각형의 중심은 mel 축에서 정한 간격을 Hz로 되돌려 얻으며, 고주파로 갈수록 일반적으로 Hz 폭이 넓어진다. 필터 $$H_b[k]\ge0$$, 비음수 power $$P[m,k]=\lvert S[m,k]\rvert^2$$를 택한 **한 가지 구현**은

$$
M[m,b]=\sum_k H_b[k]P[m,k],\qquad
L[m,b]=\log\bigl(\max(M[m,b],\epsilon)\bigr)
$$

이다. $$b$$는 band index이고 $$M$$은 power에 filter weight를 곱해 더한 값이다. `log`의 정의역을 위한 $$\epsilon>0$$가 필요하다. Power 대신 magnitude를 쓰거나 triangle을 peak 1로 둘지 면적 정규화할지에 따라 수치가 달라진다. <a href="https://librosa.org/doc/main/api/generated/librosa.feature.melspectrogram.html" target="_blank" rel="noopener">librosa mel-spectrogram 문서</a>의 `power`와 `norm='slaney'`는 서로 다른 선택 축이다. p.18의 원본 Hz spectrogram과 mel 그림은 이런 축·band 변경의 시각적 예이지 정보가 늘었다는 실험 증거는 아니다.

## 4. Cepstrum과 MFCC: 주기와 envelope의 서로 다른 질문

PDF pp.19–20의 $$F_0$$는 유성음의 기본 주파수(Hz), harmonic은 $$hF_0$$ ($$h=1,2,\ldots$$)이다. Pitch는 지각량이고 $$F_0$$와 일대일로 무조건 같지 않다. 성도 공진의 영향으로 spectrum의 완만한 envelope에 나타나는 봉우리를 formant라고 부른다. Harmonic의 **간격**과 formant의 **위치**는 다른 정보다. 제시된 80–450 Hz 범위와 성별 경향은 음성 예시의 거친 범위이며 모든 화자·발화의 진단 기준이 아니다.

PDF p.21은 real cepstrum을 log magnitude spectrum의 역 DFT로 도입한다. 왜 $$1/F_0$$가 나오나? Harmonic peak가 주파수에서 대략 $$F_0$$ Hz마다 반복되므로, 주파수 축의 주기적 변동을 다시 Fourier 분석하면 그 역수인 약 $$1/F_0$$초의 **quefrency**에 구조가 나타난다. $$f_s$$ Hz, $$N_{\mathrm{FFT}}$$점 grid에서는 quefrency bin $$q$$의 시간값이 $$q/f_s$$초다.

$$
c[q]=\frac{1}{N_{\mathrm{FFT}}}\sum_{k=0}^{N_{\mathrm{FFT}}-1}
\log\!\bigl(\max(\lvert S[k]\rvert,\epsilon)\bigr)e^{j2\pi kq/N_{\mathrm{FFT}}}.
$$

**왜 harmonic 간격을 찾을 수 있나? — 작성자 보충 유도.** $$\Delta f=f_s/N_{\mathrm{FFT}}$$ Hz이고 harmonic 간격 $$F_0$$가 정확히 $$P=F_0/\Delta f$$개의 bin에 해당한다고 가정하자. 로그 스펙트럼의 반복 성분을 $$L[k]\approx A\cos(2\pi k/P)$$로 단순화하면, cosine을 두 복소 지수로 나눈 위 역 DFT 합은 직교성 때문에 $$q=N_{\mathrm{FFT}}/P=f_s/F_0$$와 대칭 bin 부근에서 커진다. 따라서 양의 작은 quefrency는 $$q/f_s=1/F_0$$초다. 예를 들어 $$f_s=16000$$ Hz, $$N_{\mathrm{FFT}}=1024$$, $$F_0=250$$ Hz이면 $$P=16$$ bin, $$q=64$$ sample, $$q/f_s=0.004$$ s다. 이 등식은 이상적인 정수 bin 예제의 검산이고 실제 음성의 $$F_0$$와 harmonic peak는 창·잡음·성도 공진 때문에 정확한 격자에 놓이지 않는다.

로그 스펙트럼의 완만한 성도 envelope는 대체로 낮은 quefrency에, 촘촘히 반복되는 harmonic 구조는 그보다 높은 비영점 quefrency에 나타난다. **역 DFT는 로그 크기 스펙트럼의 주기를 분석하는 것이지 원 음성 파형으로 되돌리는 연산이 아니다.** 원 스펙트럼의 phase를 이미 버렸기 때문이다. 이 구조와 저·고 quefrency의 해석은 <a href="https://speechprocessingbook.aalto.fi/representations/melcepstrum/" target="_blank" rel="noopener">Aalto University의 cepstrum 해설</a>과도 대조할 수 있다.

이 식은 원문의 'inverse DFT of log spectrum'을 **역변환에 $$1/N_{\mathrm{FFT}}$$을 두는 NumPy/SciPy 관례**로 쓴 real cepstrum 정의다. 앞의 PDF p.2처럼 **앞변환에 $$1/N$$을 두는 관례와 위치가 달라졌으며**, 전체 계수의 scale만 바뀐다. $$q$$는 무차원 index, $$q/f_s$$는 초다. $$\log X[k]$$처럼 복소수 전체의 로그를 취하는 complex cepstrum과 구분해야 한다. $$q=0$$ 부근에는 완만한 spectral envelope나 평균 수준의 큰 값이 있을 수 있으므로, 유성 구간의 적절한 **비영점 quefrency 범위**에서 peak를 찾는다. 무성음·잡음·여러 음원이 겹친 경우에는 선명한 $$1/F_0$$ peak가 없거나 다른 peak가 더 클 수 있다. p.23 실습 그림의 약 373.7 Hz 주기는 $$1/373.7\approx0.00268$$ s, 즉 2.68 ms라는 검산이 된다.

PDF p.22의 MFCC는 cepstrum과 관련되지만 **log-mel band 값에 DCT를 적용한 계수**다. 앞 절처럼 power mel 값을 쓰기로 정했다면 band $$b=0,\ldots,B-1$$의 log 값 $$L[m,b]$$에 대해 대표적인 DCT-II convention은

$$
C[m,r]=\sum_{b=0}^{B-1}L[m,b]\cos\!\left[\frac{\pi r}{B}\left(b+\frac12\right)\right],
\qquad 0\le r<B.
$$

$$B,r$$는 무차원 band·coefficient 수다. 라이브러리에서는 DCT normalization, $$C_0$$ 포함 여부, coefficient 개수, liftering 등이 달라질 수 있다. DCT는 filterbank 축의 완만한 패턴을 앞쪽 계수로 모으기 쉬우나, 일부 계수만 남기는 순간 정보는 손실된다. **STFT→mel filterbank→log→DCT**라는 원문 순서를 실제 계산으로 읽으려면 STFT 뒤의 magnitude/power 선택, filter 합산, 0 floor를 함께 지정해야 한다.

따라서 **harmonic 간격을 직접 찾는 real cepstrum**과 **mel 축에서 완만한 spectral envelope를 압축하는 MFCC**는 목적도 다르다. Mel 필터가 인접 주파수를 합치고 낮은 차수의 MFCC만 보존하면 세밀한 harmonic 간격은 약해질 수 있다. MFCC 그림의 계수 번호를 Hz나 $$F_0$$로 읽거나 MFCC 하나에서 pitch를 바로 복원해서는 안 된다.

## 5. Sampling aliasing과 sinc 복원은 어디서 이어지는가 — 작성자 보충

이 절의 표본화 유도는 **이번 PDF 23쪽에는 없는 연결 설명**이다. 앞선 강의의 [sampling·aliasing 해설](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)과 함께 읽는다. DFT 오른쪽의 거울 봉우리, sampling aliasing, finite-window leakage를 같은 현상으로 부르면 안 된다.

연속 신호 $$x(t)$$를 $$T_s=1/f_s$$초 간격으로 표본화하면 복소 지수는

$$
e^{j2\pi(f+rf_s)nT_s}
=e^{j2\pi fnT_s}e^{j2\pi rn}
=e^{j2\pi fnT_s},\qquad r,n\in\mathbb{Z}.
$$

따라서 $$f$$와 $$f+rf_s$$는 모든 정수 시각 표본에서 구별되지 않는다. 연속 Fourier spectrum $$X(f)$$가 있고 impulse-train sampling을 분포 의미에서 쓰면, sample train spectrum은 $$X_s(f)=f_s\sum_{r\in\mathbb Z}X(f-rf_s)$$로 복제된다. 원본이 $$\lvert f\rvert<B<f_s/2$$에 제한되면 복제본이 겹치지 않아 이상적인 low-pass로 가운데 사본을 뽑을 수 있다. 겹친 뒤에는 원래 두 성분을 샘플만으로 일반적으로 분리할 수 없다. Sampling과 ideal low-pass sinc 보간의 연결은 <a href="https://ocw.mit.edu/courses/res-6-007-signals-and-systems-spring-2011/4057518e4fe8d9c54ddb2ce64d869f94_MITRES_6_007S11_lec17.pdf" target="_blank" rel="noopener">MIT Signals and Systems Lecture 17</a>의 설명과 대조했다.

주파수 응답이 통과대역에서 1, 그 밖에서 0인 ideal low-pass의 impulse response는 역 Fourier 적분으로 $$h(t)=2B\operatorname{sinc}(2Bt)$$가 된다. $$B=f_s/2$$로 잡고 impulse train의 $$1/f_s$$ 배율을 보정하면 유명한 sinc 보간식 $$x(t)=\sum_n x[n]\operatorname{sinc}(f_st-n)$$를 얻는다. **이는 양쪽으로 무한한 band-limited 신호와 이상적 필터의 수학적 결과**이며, 현실의 유한 녹음·비이상적 anti-alias filter에서 동일한 완전 복원을 보장하지 않는다. 여기의 sinc는 §2에서 rect window의 transform에 등장한 것과 같은 함수지만, 하나는 **windowing의 주파수 응답**, 다른 하나는 **ideal low-pass의 시간 응답**이라는 역할이 다르다.

### Sampling comb and reconstruction gain

복제식의 계수 $$f_s$$도 확인할 수 있다. 표본화 comb $$p(t)=\sum_n\delta(t-nT_s)$$는 주기 $$T_s$$당 단위 면적 impulse 하나를 갖는다. Fourier series의 각 계수는 한 주기 적분에서 $$1/T_s=f_s$$가 되어 $$p(t)=f_s\sum_r e^{j2\pi r f_st}$$이다. 따라서 $$P(f)=f_s\sum_r\delta(f-rf_s)$$이고, $$x_s(t)=x(t)p(t)$$의 Fourier transform은 convolution으로

$$
X_s(f)=X(f)*P(f)=f_s\sum_r X(f-rf_s)
$$

가 된다. 복제본이 겹치지 않는 조건에서 원래 크기를 되찾으려면 가운데 대역을 선택하는 필터의 이득을 $$T_s$$로 둔다. 그때

$$
h_{\mathrm{rec}}(t)
=T_s\int_{-f_s/2}^{f_s/2}e^{j2\pi ft}\,df
=T_sf_s\operatorname{sinc}(f_st)
=\operatorname{sinc}(f_st).
$$

마지막으로 $$x_s*h_{\mathrm{rec}}$$에서 각각의 impulse가 이동된 sinc 하나를 만들므로 $$x(t)=\sum_n x(nT_s)\operatorname{sinc}(f_st-n)$$이다. **시간에서 잘라낸 rect는 주파수에서 sinc형 누설을 만들고, 주파수의 이상적 rect 통과대역은 시간에서 sinc 보간 커널을 만든다.** 둘 다 Fourier 쌍이지만 sampling aliasing을 이미 겪은 표본의 정보를 창 함수가 되살린다는 뜻은 아니다.


### N=8 시각화: 같은 sample과 서로 다른 중간 궤적

<a href="{{ "/assets/materials/study/speech-spectral-analysis/aliasing-dtfs-n8.html" | relative_url }}" target="_blank" rel="noopener">N=8 회전 시각화 열기</a>. 이 HTML의 파라미터는 $$F_0=1$$ Hz, $$f_s=8$$ Hz, $$T_s=0.125$$ s, $$N=8$$이며 $$k=1$$과 $$k=9=1+N$$을 비교한다. Script의 각도는 $$a_1=2\pi\cdot1\cdot t$$, $$a_9=2\pi\cdot9\cdot t$$다. 실제 **표본 순간** $$t_n=n/8$$ s, $$n=0,\ldots,7$$에서는 차이가 $$a_9-a_1=2\pi n$$이므로 8개 표본의 복소 위치가 모두 같다. 반대로 HTML의 초기 화면 $$t=0.0625$$ s는 **표본 사이**다. 이때 차이는 $$2\pi\cdot8\cdot0.0625=\pi$$ rad, 즉 180°라 두 위치는 다르다. 화면의 spiral·trail은 지나간 회전을 표시하는 시각적 흔적이지 진폭 감쇠를 뜻하지 않는다. 두 벡터의 반지름은 시간에 따라 줄어드는 모델이 아니다.

## 6. Notebook Code and Figures

이 원고는 `SAR_Lec01.ipynb`의 **0부터 10까지 모든 코드 셀**을 읽고, 노트북에 이미 저장된 그림 15장을 확인하여 작성한 해설이다. 여기 적은 수치와 그림은 **원본 노트북의 저장 결과**이며, 이 검토를 위해 코드를 다시 실행하거나 음원을 새로 분석하지 않았다. 아래의 개선 코드는 별도의 제안으로, 원본 출력이나 재실행 결과로 취급하지 않는다.

> **핵심:** 전체 신호의 FFT는 어떤 주파수 성분이 있는지 보여주지만 *언제* 나타나는지는 잃는다. STFT는 짧은 구간마다 FFT를 수행해 시간–주파수 지도를 만든다. 이후 로그 dB 표현은 큰 값과 작은 값을 함께 보이게 하고, mel 필터뱅크와 MFCC는 주파수 정보를 음성 처리에 쓰기 좋은 특징으로 바꾼다. 이때 **FFT 정규화, 창 길이, dB 기준값, 시간축 정렬**이 다르면 그림의 숫자를 직접 비교할 수 없다.

### Notebook Map

| 셀 | 입력과 연산 | 결과의 역할 |
|---|---|---|
| 0–1 | 합성 정현파 생성 → 전체 FFT | 알려진 주파수와 DFT 계수의 크기 확인 |
| 2–4 | 예제 WAV 다운로드·패키지 설치·재생 | 이후 셀의 파일·환경 의존성 준비 |
| 5–7 | WAV 로드 → 파형·평균제곱·RMS·전체 FFT | 음성의 시간축 변화와 전체 주파수 분포 확인 |
| 8–9 | 직접 구현한 STFT, 직사각/Hann 창, 요약값 | 시간–주파수 표현 및 창·스케일의 영향 확인 |
| 10 | librosa STFT → mel power → MFCC; 전체 신호 cepstrum | 서로 다른 특징 표현의 목적·한계 비교 |

표기에서 `L = len(y)`는 `librosa.load` 이후의 표본 수이고, `sr`은 로드된 파형의 초당 표본 수다. 원본 코드가 실제 표본 수를 출력하지 않으므로 `L`을 추정 숫자로 바꾸지 않는다. 저장된 파형 그림에서 재생 길이는 약 18초대로 보이지만, 정확한 길이는 `L / sr`로 계산해야 한다.

### Cells 0–1: A Known Signal and Its FFT

**Cell 0 — 시간축과 합성파.** `fs=1000 Hz`, `T=1 s`, `N=fsT=1000`이고 `endpoint=False`이므로 `t[n]=n/1000 s` (`n=0,…,999`)다. 두 성분을 더해 `f[n]=10 sin(2π·10t[n])+3 sin(2π·100t[n])`을 만든다. 10 Hz는 0.1초를 한 주기로 하는 큰 진폭 성분이고, 100 Hz는 그 위에 얹힌 0.01초 주기의 작은 진폭 성분이다. 1초 동안 각각 정확히 10회·100회 진동하므로 이 예에서는 두 성분이 DFT bin에 정확히 놓인다. `f`와 `t`의 배열 shape는 모두 `(1000,)`이다.

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-00-01.png" | relative_url }}" alt="10 Hz의 큰 변화에 100 Hz의 작은 진동이 겹친 합성 파형의 첫 0.2초" loading="lazy">

저장된 그림은 전체 1초가 아닌 `xlim(0, 0.2)`의 **첫 0.2초만** 보인다. 따라서 큰 물결은 2주기, 빠른 물결은 20주기 정도이며, 세로축은 합성 신호의 임의 진폭 단위이지 음압 Pa가 아니다.

**Cell 1 — 전체 신호 FFT.** `np.fft.fft(f)`는 복소수 `(1000,)` 배열 `X`를 만든다. `np.fft.fftfreq(1000, d=1/1000)` 역시 `(1000,)`이고 bin 간격은 `fs/N=1 Hz`; 양·음 주파수를 모두 포함한다. 실수 정현파 `A sin(2πkn/N)`의 미정규화 DFT는 부호가 반대인 두 bin에 크기 `AN/2`씩 놓인다. 따라서 이 경우 저장된 막대의 피크는 **±10 Hz에서 5000, ±100 Hz에서 1500**이다. 이는 원래 파형의 진폭 10·3 자체가 아니며, 단일 측면의 비DC 진폭으로 되돌리려면 각 크기에 `2/N`을 곱해야 한다.

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-01-01.png" | relative_url }}" alt="합성파의 양측 FFT 스펙트럼: ±10 Hz에서 5000, ±100 Hz에서 1500" loading="lazy">

이 그림은 `−200~200 Hz`만 확대한 **양측 원시 DFT magnitude**다. 음의 주파수에 보이는 대칭 피크는 독립적인 추가 소리가 아니라 실수 신호 DFT의 켤레대칭 표현이다. 원본에서 `np.abs(X)`만 표시했으므로 위상은 별도 확인할 수 없다. <a href="https://numpy.org/doc/stable/reference/generated/numpy.fft.fftfreq.html" target="_blank" rel="noopener">NumPy의 FFT 주파수축 설명</a>은 bin 순서와 음의 주파수 구간을 확인할 수 있는 근거다.

### Cells 2–4: Audio and Environment Dependencies

**Cell 2**의 `!wget`은 <a href="https://mairlab-km.github.io/assets/courses/speech-audio-recognition-2025fall/materials/harvard.wav" target="_blank" rel="noopener">강의 예제 WAV</a>를 현재 작업 디렉터리에 `harvard.wav`라는 이름으로 저장한다. 저장된 출력 로그에는 HTTP 200과 약 3.1 MB 다운로드가 기록되어 있다. 이것은 과거 실행의 기록이지, 지금 파일이 로컬에 존재한다는 증거는 아니다. 네트워크, 원격 파일의 지속 제공, 쓰기 가능한 작업 디렉터리에 의존한다.

**Cell 3**은 `!pip install librosa`와 `!pip install pysoundfile`을 실행한다. 저장된 로그에는 당시 `librosa 0.11.0`과 `soundfile 0.13.1`이 이미 설치되어 있었는데, 별도로 오래된 이름의 `pysoundfile 0.9.0.post1`을 추가 설치한 사실이 보인다. 재현 가능한 실습에는 호환되는 패키지 버전을 명시하고, 이미 충족된 의존성을 중복 설치할 필요가 있는지 검토해야 한다. 이 셀은 실행 환경을 변경하고 네트워크를 사용하므로 노트북을 검토할 때 무심코 실행해서는 안 된다.

**Cell 4**는 `IPython.display.Audio('harvard.wav')`로 파일을 재생하려 한다. 셀 2가 선행되어야 하고 파일 경로가 달라지면 실패한다. 원본 노트북의 **저장 출력**은 Colab에서 다시 열라는 안내문뿐이며, 실제 오디오 데이터가 MIME 출력으로 삽입된 것은 아니다. 따라서 저장된 노트북만 읽어서는 청취 결과를 재현할 수 없다.

### Cells 5–7: Waveform, Power, and Whole-Recording FFT

**Cell 5 — 로드와 시간 파형.** `librosa.load('harvard.wav')`는 당시 버전의 기본값으로 **mono**, **`sr=22050 Hz`**, **`float32`** 파형 `y`를 반환한다. 원 WAV가 다른 sample rate라면 22050 Hz로 재표본화된다. 원본 녹음의 rate를 그대로 확인한 결과로 `sr`을 해석해서는 안 된다. `y.shape=(L,)`, 시간축도 `(L,)`이다. <a href="https://librosa.org/doc/0.11.0/generated/librosa.load.html" target="_blank" rel="noopener">librosa 0.11.0 <code>load</code> 문서</a>는 이 기본값과 `sr=None`을 사용한 원래 rate 보존을 명시한다.

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-05-01.png" | relative_url }}" alt="약 18초대 음성 파일의 전체 시간 파형과 발화 사이의 저진폭 구간" loading="lazy">

저장된 그림에서 발화와 낮은 진폭의 공백, 몇 차례 큰 과도 피크를 구별할 수 있다. **세로축은 로드된 디지털 진폭**이고 Pa 또는 dB SPL이 아니다. 원본 `np.linspace(0, L/sr, num=L)`는 마지막 표본에 실제 시각 `(L−1)/sr`이 아니라 `L/sr`을 붙여 축을 표본 하나(`1/sr≈45.35 μs`)만큼 늘린다. 정확한 표본 시각은 `np.arange(L)/sr`이다. 이 차이는 그림에서 거의 안 보이지만, 표본·프레임 좌표를 정밀하게 맞출 때는 바로잡아야 한다.

**Cell 6 — 전체 파일의 평균제곱과 RMS.** 저장된 콘솔 출력은 `Power: 0.00314394`, `RMS: 0.056070846`이다. 코드의 정확한 계산은 `mean(y**2)`와 그 제곱근이다. 이는 **표본 진폭의 평균제곱 및 실효값**이지, 마이크 보정·임피던스·음압 기준 없이 물리적 전력 W 또는 SPL을 말하지 않는다. 전체 파일에 조용한 구간도 포함되므로, 이 한 수치로 각 발화 구간의 크기를 설명할 수도 없다. 반올림하면 `0.056070846²≈0.00314394`로 두 저장 결과가 서로 부합한다.

**Cell 7 — 전체 음성 FFT.** `np.fft.fft(y)`는 `complex` shape `(L,)`, `fftfreq(L, d=1/sr)`는 Hz shape `(L,)`을 만든다. bin 간격은 `sr/L Hz`이며, 최대 표시 범위는 대략 `−sr/2`에서 `+sr/2`이다. 파형 전체를 하나의 직사각 구간으로 본 비정규화 양측 magnitude이므로 `L`과 신호 길이에 따라 값이 달라지고, 언제 어떤 음소가 나왔는지는 알려주지 않는다.

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-07-01.png" | relative_url }}" alt="전체 음성 파일의 양측 FFT 막대가 0 Hz 주위에 조밀하게 겹친 그림" loading="lazy">

저장된 `stem` 그림은 수많은 bin이 겹쳐 중앙이 빽빽하다. 한 번의 FFT는 **전체 구간의 총합**이므로 이 그래프에서 시간별 pitch·formant를 읽거나 가장 큰 막대 하나를 음성 전체의 fundamental이라고 단정할 수 없다. 더 작은 분석 구간이 필요한 이유가 다음 STFT 셀이다.

### Cells 8–9: A Hand-Written STFT and Window Comparison

**Cell 8 — 분할, 창, rFFT.** 직접 만든 `stft(signal, fs, frame_size, hop_size, window, n_fft)`은 매 hop마다 길이 512 표본의 프레임을 잡고, 끝에서 512 표본이 안 되는 조각은 버린다. `frame_size=512`, `hop_size=256`, `n_fft=1024`, `fs=sr=22050 Hz`이므로 한 프레임은 약 **23.22 ms**, 시작 간격은 **11.61 ms**다. 실제 관측창은 512 표본이고 1024-point FFT까지 나머지는 0으로 채워진다. `rfft` 결과는 프레임당 `1024/2+1=513`개의 0~11025 Hz 비음수 bin이고, bin 간격은 `sr/1024≈21.53 Hz`다. **0 채움은 촘촘한 주파수 눈금을 제공할 뿐, 512 표본 관측창이 가진 두 근접 성분의 실제 분리력을 두 배로 높이지 않는다.** <a href="https://librosa.org/doc/0.11.0/generated/librosa.stft.html" target="_blank" rel="noopener">librosa STFT 문서의 <code>n_fft</code>, <code>win_length</code>, <code>hop_length</code> 설명</a>도 창 길이·zero padding·시간–주파수 trade-off를 구분한다.

`n_frames=1+floor((L−512)/256)` (`L≥512`)이며, 함수는 `as_strided`로 만든 `(n_frames,512)` view에 창을 곱한 뒤 `rfft`를 수행한다. 반환값 순서는 문서 문자열의 `mag` 하나가 아니라 **`X.T, mag, phase, f, tt` 다섯 개**다. 앞의 세 배열은 모두 `(513,n_frames)`, `f`는 `(513,)`, 프레임 중심 시각 `tt`는 `(n_frames,)`이다. `tt[j]=(256j+256)/sr`; 이는 중앙 *경계*를 잡는 흔한 관례이며 실제 첫째·마지막 표본의 중점 `(512−1)/2`와는 0.5표본 차이가 난다. 입력 길이가 창보다 짧거나 hop·FFT·창 shape가 잘못되면 현재 구현은 안전한 오류 메시지를 보장하지 않는다.

직사각 창은 프레임 모든 표본에 동일 가중치를 주고, `np.hanning(512)`은 양끝을 0으로 줄이는 **대칭 Hann** 창이다. 뒤의 librosa `window='hann'`은 통상 FFT용 **주기 Hann**을 만들므로, 두 셀은 창 모양도 완전히 같지 않다. Hann은 프레임 경계 불연속에 따른 leakage를 줄이는 대신 주엽을 넓히고 원시 peak magnitude를 낮출 수 있다. 원본은 창 이득을 보정하지 않으므로 두 선형 컬러바의 높이 차이를 곧바로 음원의 진폭 변화라고 해석하면 안 된다. <a href="https://numpy.org/doc/stable/reference/generated/numpy.hanning.html" target="_blank" rel="noopener">NumPy <code>hanning</code> 정의</a>와 <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.get_window.html" target="_blank" rel="noopener">SciPy <code>get_window</code>의 periodic/symmetric 구분</a>이 이 차이의 근거다.

**저장 그림 8-1 — 직사각 창의 선형 크기.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-01.png" | relative_url }}" alt="직사각 창 STFT의 원시 선형 magnitude, 낮은 주파수에 강한 에너지가 모인 그림" loading="lazy">

대부분 어두워 보이는 이유는 **한 장의 선형 색상 범위를 강한 bin이 지배**하기 때문이다. 색상값은 정규화하지 않은 `abs(rfft)`이지 파형 진폭이나 전력 W가 아니다. 수직 줄은 짧은 발음·과도 변화, 낮은 쪽의 띠는 주로 유성 성분의 구조를 시사하지만, 그림 하나로 음소·F0를 확정하지 않는다.

**저장 그림 8-2 — 직사각 창의 위상.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-02.png" | relative_url }}" alt="직사각 창 STFT 각도를 −π에서 π 라디안 색으로 표시한 위상 그림" loading="lazy">

각 픽셀은 `angle(X)`의 **라디안** 값이다. 크기가 거의 0인 bin에서는 위상 변화가 특히 불안정하거나 해석 가치가 낮아, 촘촘한 색무늬를 발음 특징으로 곧장 읽어서는 안 된다. 색의 양끝은 위상이 감긴 `−π~π` 범위를 뜻한다.

**저장 그림 8-3 — 직사각 창의 로그 크기.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-03.png" | relative_url }}" alt="직사각 창 STFT의 20 log10 원시 magnitude: 선형 그림에서 안 보이던 약한 패턴이 드러남" loading="lazy">

코드는 `20 log10(mag+10⁻¹²)`을 쓴다. 매우 작은 값의 `−∞`를 피하는 바닥값은 있지만, **기준 진폭 1에 대한 원시 FFT 계수의 상대 dB**일 뿐 최대치를 0 dB로 맞추지 않는다. 따라서 양수 dB도 가능하고, 이 그림의 숫자를 뒤의 librosa `ref=np.max` 그림의 0~-80 dB와 직접 비교할 수 없다. 로그를 취하면서 약한 마찰·고주파 성분과 공백의 대비가 선형 그림보다 보인다.

**저장 그림 8-4 — Hann 창의 선형 크기.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-04.png" | relative_url }}" alt="대칭 Hann 창을 적용한 STFT 원시 선형 magnitude" loading="lazy">

직사각 버전과 같은 음원·프레임 길이·hop·FFT 길이지만 창만 다르다. 저장 그림의 컬러바 최고 눈금은 직사각 쪽 약 220, Hann 쪽 약 130으로 서로 다르다. 이 그림이 자동 색상 범위를 사용하고 창 이득도 다르므로 **같은 색을 같은 값으로 비교할 수 없다**.

**저장 그림 8-5 — Hann 창의 위상.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-05.png" | relative_url }}" alt="대칭 Hann 창 STFT의 위상 색 지도; 저크기 영역은 해석에 주의가 필요" loading="lazy">

직사각 위상과 색 패턴이 다른 것은 창이 복소 계수를 바꾸기 때문이다. 크게 보이는 무늬 차이가 신호 자체의 시간 변화를 뜻하지는 않는다. 저크기 bin의 위상은 두 창 모두 신뢰하기 어렵다.

**저장 그림 8-6 — Hann 창의 로그 크기.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-08-06.png" | relative_url }}" alt="Hann 창 STFT의 기준 1 원시 dB 지도, 진폭 범위와 바닥값이 직사각 창과 다름" loading="lazy">

이 그림도 `20 log10(abs(X)+10⁻¹²)`이며, **색상 범위가 그림마다 자동으로 달라진다.** 두 창의 누설 차이를 공정하게 비교하려면 공통 dB 기준, 공통 `vmin/vmax`, 창 이득 보정 여부를 먼저 정해야 한다. 또한 세 그림 함수의 `imshow(extent=[tt[0],tt[-1],f[0],f[-1]])`는 시간·주파수의 **bin 중심을 이미지 바깥 경계처럼 사용**해 양끝 좌표에 작은 오프셋이 생긴다. 학습용 개략도에는 충분하지만 정확한 frame/bin 위치를 읽는 용도로는 축 경계를 별도로 계산해야 한다.

**Cell 9 — 세 통계 표현식.** `np.max(mag_rec)`, `np.min(mag_rec)`, `np.mean(mag_rec)`을 연속 입력했지만, Jupyter 저장 출력에는 **마지막 식의 `np.float32(0.22712438)`만** 표시된다. 이것은 직사각 창의 모든 bin·프레임에 대한 **평균 magnitude**로, 전력이나 RMS가 아니다. 최대·최소의 실제 숫자는 이 저장 출력에 없으므로 추측하지 않는다.

### Cell 10: Librosa STFT, Mel Spectrum, Cepstrum, and MFCC

마지막 셀은 직접 만든 STFT와 다른 설정을 사용한다. `n_fft=2048`, `win_length=1024`, `hop_length=512`, `n_mels=128`, `n_mfcc=13`이다. 22050 Hz에서 창의 실제 길이는 **약 46.44 ms**, hop은 **약 23.22 ms**, FFT 눈금은 **약 10.77 Hz**다. `center=True`이므로 신호 양끝에 기본적으로 0을 채워 `t`번째 프레임을 `y[t·512]` 주위에 정렬한다. 1024표본 Hann 창은 2048표본 FFT 프레임의 가운데에 0으로 채워진다. 따라서 이 셀과 셀 8은 `n_fft`만 다른 실험이 아니라 **창 길이·hop·center 처리·창 정의가 모두 다른 계산**이다. <a href="https://librosa.org/doc/0.11.0/generated/librosa.stft.html" target="_blank" rel="noopener">librosa 0.11.0 <code>stft</code> API</a>에서 이 정렬 및 zero-padding을 확인할 수 있다.

`S_complex`와 `S_mag=abs(S_complex)`의 shape는 `(1025, 1+floor(L/512))`이다. `S_db=librosa.amplitude_to_db(S_mag, ref=np.max)`는 각 amplitude를 **이 스펙트로그램의 최대 amplitude**와 비교해 `20 log10` 변환한다. 기본 `top_db=80`이 적용되어 최고가 0 dB, 가장 낮은 표시값은 −80 dB가 된다. 이는 교정된 dB SPL 또는 절대 음량이 아니다. <a href="https://librosa.org/doc/0.11.0/generated/librosa.amplitude_to_db.html" target="_blank" rel="noopener">librosa <code>amplitude_to_db</code> 문서</a>가 기준값과 절단 범위를 명시한다.

`M=librosa.feature.melspectrogram(y=y, sr=sr, ..., power=2.0)`은 같은 STFT 설정에서 magnitude를 **제곱한 power**를 128개 mel 필터로 합친다. shape는 `(128, 1+floor(L/512))`이다. 당시 기본은 `fmin=0`, `fmax=sr/2`, `htk=False`, `norm='slaney'`이며, mel bin은 Hz bin과 1:1 대응하지 않는다. `M_db=librosa.power_to_db(M, ref=np.max)`는 power에 `10 log10`을 적용하고 0~-80 dB로 자른다. 여기서 `S_db`와 `M_db`는 각각 **자기 배열의 서로 다른 최댓값**을 기준으로 삼으므로 동일한 0 dB가 동일한 물리 에너지를 뜻하지 않는다. <a href="https://librosa.org/doc/0.11.0/generated/librosa.feature.melspectrogram.html" target="_blank" rel="noopener">librosa <code>melspectrogram</code> 문서</a>와 <a href="https://librosa.org/doc/0.11.0/generated/librosa.power_to_db.html" target="_blank" rel="noopener">librosa <code>power_to_db</code> 문서</a>가 변환 순서와 기본값을 보여준다.

`mfcc=librosa.feature.mfcc(S=M_db, n_mfcc=13)`의 `S`는 **이미 log-power mel spectrogram**이다. 이 전달 방식은 API와 맞다. 기본 DCT-II·직교 정규화가 mel 축 정보를 13개 계수로 모으므로 shape는 `(13, 1+floor(L/512))`이다. MFCC는 새로운 Hz 주파수축이 아니라 **계수 번호 × 시간**의 행렬이며, 정확한 음소 라벨이나 pitch 값 자체가 아니다. <a href="https://librosa.org/doc/0.11.0/generated/librosa.feature.mfcc.html" target="_blank" rel="noopener">librosa <code>mfcc</code> 문서</a>는 `S`의 입력 의미와 DCT 기본값을 명시한다.

별도의 **real cepstrum** 계산은 전체 파일 `N=L`에 `np.hanning(N)`을 곱하고, `scipy.fft.rfft` → `ln(max(abs(Y),10⁻¹²))` → `scipy.fft.irfft`를 적용한다. 이는 MFCC와 달리 멜 필터·프레임별 DCT를 쓰지 않는다. 독립변수 **quefrency**는 `q/sr` 초이며, 스펙트럼의 주기적인 harmonic 간격이 있으면 역로그스펙트럼에서 관련 지연에 봉우리가 나타날 수 있다. 원본은 `fmin=50`, `fmax=400 Hz`에 대응하는 정수 지연 범위에서 가장 큰 양의 cepstral 값을 골라 `sr/q_peak`를 제목에 넣는다. 저장 제목의 **약 373.7 Hz는 전체 약 18초 음성에서 한 번 고른 피치 *후보***다. 무성 구간·침묵·서로 다른 발화자를 구분하지 않았고, 프레임별 F0 추정이나 진실값 검증도 없으므로 '음성의 피치가 373.7 Hz'라고 말하면 과장이다. `qmin=int(sr/fmax)`는 올림이 아니고 `qmax`는 슬라이스 끝에서 빠지므로 50~400 Hz의 **정확한 포함 범위**도 아니다. 또한 `N`이 홀수면 `irfft`의 기본 출력 길이는 `N−1`이다. 정확한 길이를 보존하려면 `irfft(log_mag, n=N)`을 명시한다. <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.fft.irfft.html" target="_blank" rel="noopener">SciPy <code>irfft</code> 문서</a>가 기본 길이 `2(m−1)`과 홀수 길이 주의를 설명한다.

**저장 그림 10-1 — 다시 그린 전체 파형.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-10-01.png" | relative_url }}" alt="librosa waveshow로 표시한 음성의 전체 파형과 발화 사이의 침묵" loading="lazy">

셀 5와 **같은 `y`**를 `librosa.display.waveshow`로 다시 그렸다. 큰 파형 변화는 발화·과도 사건의 시점을 찾는 데 도움이 되지만, 파형만으로 주파수 성분의 배치를 바로 알 수는 없다.

**저장 그림 10-2 — 선형 Hz축의 상대 dB 스펙트로그램.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-10-02.png" | relative_url }}" alt="최대 STFT amplitude를 0 dB로 둔 시간-선형 Hz 주파수 스펙트로그램" loading="lazy">

가로축은 시간, 세로축은 **선형 Hz**, 밝기는 해당 STFT bin의 **최대치 대비 dB**다. 유성 부분 아래쪽의 층상 띠는 harmonic 구조, 높게 뻗는 짧은 줄은 빠른 변화나 넓은 주파수 대역의 성분을 보여준다. 검은 영역은 완전한 0이 아니라 `top_db=80` 때문에 **최대치보다 80 dB 이상 낮은 값이 한 색으로 잘린 영역**일 수 있다.

**저장 그림 10-3 — mel 축의 상대 dB 스펙트로그램.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-10-03.png" | relative_url }}" alt="128개 mel power band를 자체 최대값 기준 0~-80 dB로 표시한 그림" loading="lazy">

입력은 시간–주파수 power를 mel 필터로 집계한 것으로, 바로 앞 그림을 단순히 세로로 늘이거나 색만 바꾼 그림이 아니다. 세로축 눈금은 Hz로 표기되지만 간격은 **mel scale에 따라 비선형**이다. 낮은 주파수의 구조를 더 세밀히, 높은 주파수는 상대적으로 압축해 볼 수 있다. 두 그림은 기준 배열도 다르므로 같은 주황색을 같은 절대 에너지로 해석하면 안 된다.

**저장 그림 10-4 — 전체 파일 real cepstrum.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-10-04.png" | relative_url }}" alt="0~20 ms quefrency의 전체 파일 real cepstrum과 제목에 표시된 373.7 Hz 피치 후보" loading="lazy">

가로축은 **quefrency 초**이며 0~20 ms만 표시했다. 373.7 Hz 후보에 해당하는 주기는 대략 `1/373.7≈2.68 ms`지만, 그림에는 선택 위치를 수직선으로 표시하지 않았다. 따라서 제목 숫자가 곡선의 어떤 봉우리에서 왔는지 이 저장 그림만으로 명확히 검산하기 어렵다. 0 근처의 큰 구조와 뒤쪽의 작은 진동이 함께 보여도 전체 음성에 하나의 pitch가 존재한다는 증거는 아니다.

**저장 그림 10-5 — 13개 MFCC.**

<img src="{{ "/assets/images/study/speech-spectral-analysis/cell-10-05.png" | relative_url }}" alt="시간에 따른 13개 MFCC 계수 행을 보여주는 색 지도, 첫 계수의 큰 음수값이 색 범위를 지배" loading="lazy">

가로축은 시간, 세로축은 주파수가 아닌 **계수 index**다. 저장 그림에는 index 숫자 눈금이 없어 어느 줄이 몇 번째 계수인지 바로 확인하기 어렵다. 가장 아래쪽의 큰 음수 계수가 색상 범위를 지배하여 나머지 계수 대비가 약하게 보인다. 계수 간 직접 시각 비교가 필요하다면 축 눈금과 공통 또는 계수별 색상 정책을 명시해야 하지만, 이는 **개선 제안**이지 원본 결과가 아니다.

### Source Check and Safe Reproduction

원본의 계산을 이해하기 위해 꼭 필요한 보정과, 결과 해석에서 지켜야 할 경계를 분리한다.

| 위치 | 원본에서 확인된 사실 | 안전한 해석·개선 |
|---|---|---|
| 1·7 | FFT 계수에 정규화 없음 | 진폭과 원시 magnitude를 구분하고 양측/단측 기준을 밝힌다. |
| 5 | 시간축을 endpoint 포함 `linspace`로 그림 | 표본 시각은 `np.arange(len(y))/sr`를 쓴다. |
| 6 | `power=mean(y²)`라고 출력 | 전력 W가 아니라 디지털 진폭의 평균제곱으로 명명한다. |
| 8 | 직접 만든 STFT에 입력 검증 없음 | 양의 `fs`, `frame_size`, `hop_size`, `n_fft≥frame_size`, 맞는 창 길이 및 입력 길이를 확인한다. |
| 8·10 | raw dB와 max-relative dB를 혼용 | 같은 기준·창 보정·색상 범위를 정한 뒤에만 수치를 비교한다. |
| 9 | 식 세 개 중 마지막 평균만 출력됨 | 필요하면 세 통계를 명시적으로 출력한다. |
| 10 | whole-record cepstrum을 `peak≈373.7 Hz`로 표시 | 검증되지 않은 전체 파일 피치 후보로만 취급하고, 프레임별 유성 구간에서 별도 평가한다. |
| 10 | `irfft(log_mag)` 길이가 암묵적 | 홀수 `N`도 보존하도록 `irfft(log_mag, n=N)`으로 지정한다. |

다음 코드는 **원본을 실행한 결과가 아닌 안전한 재작성 예시**다. 음원 파일과 `librosa`, `numpy`, `scipy`가 준비되어 있고 `y`가 1차원 실수 배열이라는 전제가 필요하다. `sliding_window_view`는 프레임을 뽑는 view를 만들며, 이후 `window` 곱셈과 FFT에서 배열이 생성된다. 출력은 원본 `as_strided` 함수처럼 `(frequency, frame)`으로 맞추지만, 잘못된 길이·hop을 먼저 거부한다.

```python
import numpy as np
from numpy.lib.stride_tricks import sliding_window_view
from scipy.fft import rfft, irfft

def checked_stft(y, sr, frame_size=512, hop_size=256, n_fft=1024, window=None):
    y = np.asarray(y)
    if y.ndim != 1 or not np.issubdtype(y.dtype, np.number) or not np.isrealobj(y):
        raise ValueError("y must be a one-dimensional real signal")
    if not np.isfinite(y).all():
        raise ValueError("y must contain only finite samples")
    if not isinstance(frame_size, (int, np.integer)) or frame_size <= 0:
        raise ValueError("frame_size must be a positive integer")
    if not isinstance(hop_size, (int, np.integer)) or hop_size <= 0:
        raise ValueError("hop_size must be a positive integer")
    if not isinstance(n_fft, (int, np.integer)) or n_fft < frame_size:
        raise ValueError("n_fft must be an integer >= frame_size")
    if not np.isscalar(sr) or not np.isfinite(sr) or sr <= 0:
        raise ValueError("sr must be positive and finite")
    if len(y) < frame_size:
        raise ValueError("signal must contain at least one full frame")

    if window is None:
        weights = np.ones(frame_size)
    else:
        weights = np.asarray(window)
        if weights.shape != (frame_size,) or not np.isrealobj(weights) or not np.isfinite(weights).all():
            raise ValueError("window must have frame_size finite real weights")

    frames = sliding_window_view(y, frame_size)[::hop_size]
    X = np.fft.rfft(frames * weights, n=n_fft, axis=1).T
    freq_hz = np.fft.rfftfreq(n_fft, d=1 / sr)
    frame_time_s = (np.arange(X.shape[1]) * hop_size + frame_size / 2) / sr
    return X, freq_hz, frame_time_s

# 원본 셀 5 시간축의 표본 위치를 정확히 표시하려면:
sample_time_s = np.arange(len(y)) / sr

# 원본 셀 8과 다르게 최대값 기준의 상대 dB로 통일하려면:
X, freq_hz, frame_time_s = checked_stft(y, sr, window=np.hanning(512))
mag = np.abs(X)
reference = max(float(np.max(mag)), 1e-12)
relative_db = 20 * np.log10(np.maximum(mag, 1e-12) / reference)
relative_db = np.maximum(relative_db, -80.0)

# 원본 셀 10의 real cepstrum 길이와 주파수 탐색 경계를 명시하려면:
N = len(y)
log_mag = np.log(np.maximum(np.abs(rfft(y * np.hanning(N))), 1e-12))
cepstrum = irfft(log_mag, n=N)
fmin_hz, fmax_hz = 50.0, 400.0
qmin = max(1, int(np.ceil(sr / fmax_hz)))
qmax = min(N - 1, int(np.floor(sr / fmin_hz)))
if qmin > qmax:
    raise ValueError("no quefrency sample falls in the requested pitch range")
q_peak = qmin + int(np.argmax(cepstrum[qmin:qmax + 1]))
pitch_candidate_hz = sr / q_peak  # 전체 신호 후보일 뿐, 검증된 F0가 아님
```

이 코드는 API 기본값과 관측 단위를 드러내기 위한 **설명용 코드**이며, 여기서 새 `relative_db`·`pitch_candidate_hz`의 숫자를 구해 원본 저장 그림을 대체했다고 주장하지 않는다. 특히 상대 dB 비교를 실제로 하려면 직사각/Hann 창의 에너지 또는 coherent gain, 프레임 정렬, 공통 색상 범위를 한 번 더 맞춰야 한다. 분석 목적이 시간별 음높이라면 긴 파일 전체가 아닌 **유성 프레임별** 후보와 무성 판정을 함께 다뤄야 한다.

### Study Guide

1. **FFT 피크 크기와 파형 진폭을 구분한다.** 셀 1의 5000/1500은 원시 DFT 계수이며, `2/N`을 곱해야 양의 주파수에서 합성파 진폭 10/3과 이어진다.
2. **시간 정보를 보존하려면 프레임으로 나눈다.** 셀 7의 전체 FFT는 음성 구간을 섞는다. 셀 8·10의 STFT는 창 길이와 hop으로 시간·주파수의 관찰 범위를 정한다.
3. **창 길이와 FFT 길이를 분리한다.** 셀 8의 관측창 512와 FFT 1024, 셀 10의 관측창 1024와 FFT 2048은 모두 0 채움을 포함한다. 눈금 간격만으로 실제 분해능을 주장하지 않는다.
4. **dB 기준을 먼저 확인한다.** 셀 8은 원시 FFT magnitude 기준 1, 셀 10은 각 배열의 최고값 기준 0 dB다. mel은 power이므로 `10 log10`, magnitude는 `20 log10`을 쓴다.
5. **특징의 축을 구분한다.** 선형 스펙트로그램은 Hz, mel 스펙트로그램은 mel 간격의 필터 출력, MFCC는 계수 번호, cepstrum은 quefrency 초가 세로 또는 가로축을 이룬다. 이들은 같은 그림을 다른 색으로 칠한 것이 아니다.

### References

- <a href="https://mairlab-km.github.io/assets/courses/speech-audio-recognition-2025fall/materials/harvard.wav" target="_blank" rel="noopener">Course sample: harvard.wav</a> — 노트북 셀 2가 참조하는 강의 예제 음원.
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.load.html" target="_blank" rel="noopener">librosa 0.11.0: load</a>
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.stft.html" target="_blank" rel="noopener">librosa 0.11.0: stft</a>
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.feature.melspectrogram.html" target="_blank" rel="noopener">librosa 0.11.0: melspectrogram</a>
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.feature.mfcc.html" target="_blank" rel="noopener">librosa 0.11.0: mfcc</a>
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.amplitude_to_db.html" target="_blank" rel="noopener">librosa 0.11.0: amplitude_to_db</a>
- <a href="https://librosa.org/doc/0.11.0/generated/librosa.power_to_db.html" target="_blank" rel="noopener">librosa 0.11.0: power_to_db</a>
- <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.fft.irfft.html" target="_blank" rel="noopener">SciPy: irfft</a>
- <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.get_window.html" target="_blank" rel="noopener">SciPy: get_window</a>
- <a href="https://numpy.org/doc/stable/reference/generated/numpy.hanning.html" target="_blank" rel="noopener">NumPy: hanning</a>

## Source Check

노트북의 원본 코드 11셀과 저장 그림 15개를 대조했다. 합성 신호로 FFT 정규화·radix-2 분해·Dirichlet 응답·dB·N=8 aliasing을 검산했으며, 보강한 `checked_stft`는 개별 프레임 FFT와의 일치 및 잘못된 입력 6종의 거부를 확인했다. 이는 원본 WAV 실습의 전체 재실행이나 피치 추정 정확도 검증을 대신하지 않는다.

원문 PDF 23쪽 전체와 제공된 N=8 HTML의 설명·script를 시각·수식 대조했다. 아래는 **확인된 오류**와 **생략된 조건**을 구분한 것이다. 실습 화면의 실행 코드·데이터 생성 조건은 PDF에 없으므로 그래프의 세부 표본 수까지 단정하지 않는다.

| 위치 | 판정 | 본문의 처리 |
|---|---|---|
| PDF p.2 vs p.3 | 수식 불일치 | p.2는 forward DFT에 $$1/N$$을 두지만 p.3의 $$X=Mx$$ 행렬 원소에는 그 계수가 없다. p.2 convention이라면 $$M_{a,b}=N^{-1}e^{-j2\pi(a-1)(b-1)/N}$$로 써야 한다. 행렬이 무정규화 convention이면 p.2와 다른 정의임을 밝혀야 한다. |
| PDF pp.4–8 | 관례 차이 | p.4의 5/1.5와 p.8의 5000/1500은 정규화 차이로 읽고, 오른쪽 높은 주파수 봉우리는 실수 DFT의 음수 bin으로 해석한다. Aliasing이라고 부르지 않는다. |
| PDF p.7 | 전제 생략 | $$X[N-k]=X[k]^{*}$$에는 실수 입력이 필요하다. |
| PDF pp.9–14 | 조건 생략 | STFT의 frame 수는 padding·center 선택에, iSTFT 복원은 복소 phase와 overlap/window 조건에 의존한다. Rectangular와 Hann 모두 leakage·분해능 절충이 있다. |
| PDF p.16 | 단순화·상수 근사 | 'log-scale 지각'은 mel의 동기 설명이다. $$2595\log_{10}$$과 $$1127\ln$$은 반올림으로 거의 같으며 HTK와 Slaney 척도는 다르다. |
| PDF pp.21–22 | 표기·구현 조건 생략 | Real cepstrum은 $$\log\lvert X\rvert$$의 inverse DFT다. MFCC에는 magnitude/power, mel filter 합산, log floor, DCT convention을 지정해야 한다. |
| N=8 HTML 설명 | **확인된 범위 오류** | $$-N/2<k<N/2$$는 $$N=8$$에서 정수 $$-3,\ldots,3$$의 **7개**만 포함하므로 8개 bin의 유일 대표 범위가 아니다. 한 convention은 $$-4\le k<4$$이고, Nyquist 경계 bin은 $$+4$$와 $$-4$$가 같은 나머지류다. 반면 원 신호에 $$\lvert f\rvert<f_s/2$$를 요구하는 strict bandlimit는 별개의 복원 조건이다. |
| N=8 HTML 초기 화면·script | 해석 주의 | $$t=0.0625$$ s에는 두 회전 위치가 다르며, 동일성은 $$t=n/8$$ s의 8개 sample에서 성립한다. Spiral은 회전 표식이지 감쇠가 아니다. |


## 7. ASR: 음향 특징에서 전사까지 — 작성자 보충

이 절은 Lecture 2-2 PDF의 23쪽에 없는 후속 개념이다. 앞 절의 mel·MFCC가 음성을 수치 특징으로 바꾸는 방법이라면, 자동 음성 인식(ASR)은 시간에 따라 들어온 특징에서 단어 또는 subword의 순서를 추정한다. 아래 WER 정의와 CTC·attention 모델 설명은 각각 NIST의 평가 자료, CTC 원 논문, Listen, Attend and Spell 원 논문에 근거한 별도 보충이며 강의 슬라이드의 주장으로 표시하지 않는다.

### 7.1 WER과 S·D·I·N의 관계

WER(Word Error Rate)은 정답 전사(reference)와 인식 결과(hypothesis)를 **단어 단위로 정렬**한 뒤 필요한 편집 횟수를 정답 단어 수로 나눈 값이다. S는 다른 단어로 바뀐 substitution, D는 빠진 deletion, I는 추가된 insertion, N은 정답 단어 수다. N이 0보다 클 때 정의는

$$
\mathrm{WER}=\frac{S+D+I}{N}
=\frac{S}{N}+\frac{D}{N}+\frac{I}{N}.
$$

따라서 ‘SDIN’은 독립적인 성능 점수나 경험적 상관계수가 아니라 **같은 정렬에서 WER을 구성하는 네 개의 수**로 읽어야 한다. 정답과 일치한 단어 수를 C, 결과 단어 수를 H라 하면 같은 정렬에서 $$N=C+S+D$$, $$H=C+S+I=N-D+I$$다. S는 길이를 바꾸지 않고, D는 결과를 짧게, I는 길게 만든다. 하지만 WER 값 하나만으로 S·D·I의 분배는 역산할 수 없다. N이 고정되어 있을 때 오류 하나는 WER에 $$1/N$$을 더하므로 짧은 문장일수록 한 오류의 비율이 크다.

예를 들어 reference가 “I like green apples”, hypothesis가 “I love apples today”라면 한 정렬에서 like→love는 S=1, green의 누락은 D=1, today의 추가는 I=1, N=4다. 그러므로 WER은 $$3/4=0.75$$, 즉 75%다. 삽입이 많으면 WER은 100%를 넘을 수도 있다. S·D·I 사이에 항상 일정한 **통계적 상관관계**가 있는 것은 아니다. 출력 길이·발음 혼동·문장 정규화·정렬 방식에 따라 분해가 달라지므로, 모델을 비교할 때는 같은 데이터·단어 분할·정규화·평가 절차에서 WER과 S/N·D/N·I/N을 함께 본다.

### 7.2 DL 기반 ASR의 encode와 decode

**Encode:** 파형을 짧은 시간 프레임으로 나누고 log-mel spectrum 같은 음향 특징을 계산하거나, 모델이 파형에서 특징을 직접 학습한다. Encoder는 길이 T의 입력 특징열 $$x_{1:T}$$를 앞뒤 음향 문맥을 반영한 표현 $$h_t=f_\theta(x_{1:T})_t$$로 바꾼다. $$t$$는 frame index, $$\theta$$는 학습 파라미터이며 모두 무차원이다. 입력 프레임 수 T와 출력 token 수 U는 보통 다르므로 **어느 프레임이 어느 글자인지**를 처리하는 decode 방식이 필요하다.

**CTC decode:** CTC head는 각 encoder 시점에서 token 집합 V와 blank(∅)의 확률 $$p_t(k)$$를 낸다. 길이 T의 경로 $$\pi$$에서 연속된 같은 기호를 먼저 하나로 합치고 blank를 지우는 함수 $$\mathcal{B}$$를 적용하면 출력열 $$y$$를 얻는다. 예컨대 “a, a, ∅, a”는 “aa”가 되지만 “a, a, a”는 “a”가 된다. Blank는 **이 프레임에서 새 token을 내지 않음**이지 공백 문자나 반드시 무음이라는 뜻이 아니다. 반복되는 같은 글자를 분리할 때도 필요하다.

$$
P(y\mid x)=\sum_{\pi:\mathcal{B}(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid x),
\qquad L_{\mathrm{CTC}}=-\log P(y\mid x).
$$

이 식은 가능한 frame-to-token 정렬 경로의 확률을 모두 더하므로 정답 글자의 정확한 시간 경계가 없어도 학습할 수 있다. CTC head의 시점별 출력은 **encoder 표현이 주어졌을 때** 조건부 독립으로 모델링하지만 encoder 자체는 넓은 시간 문맥을 볼 수 있다. 추론에서는 매 시점의 최댓값을 고르는 greedy 경로 또는 여러 접두 경로를 모으는 beam search를 사용할 수 있다. Greedy 경로의 전사 결과가 항상 가장 확률 높은 **전사열**은 아니다.

**Attention encoder–decoder:** 다른 계열은 encoder 표현을 보면서 decoder가 이전 출력 $$y_{<u}$$에 조건부로 다음 token을 생성한다. 예를 들어 Listen, Attend and Spell은 attention으로 음향 구간을 참고하고 시작·종료 기호를 사용해 글자를 순차 출력한다. 이 방식은 앞서 생성한 글자에 의존하며, **CTC blank가 필수는 아니다.** CTC와 attention은 같은 ASR 목적을 풀지만 정렬·출력 확률의 가정과 decode 절차가 다르다.

## 마지막 핵심 정리

**FFT는 DFT를 빠르게 계산하고, STFT는 창을 움직여 시간 위치를 얻으며, mel·MFCC는 spectrum을 목적에 맞게 재표현한다.** 주파수 peak를 읽을 때는 정규화·표본화율·창 길이·창 함수·dB 기준을 먼저 확인한다. DFT의 ±주파수 대칭, sampling aliasing, window leakage는 서로 다른 원인이다. Rectangular window의 sinc형 확산과 ideal low-pass의 sinc 보간도 같은 함수가 서로 다른 축에서 쓰인 예다.

ASR에서는 인코딩된 음향 특징을 글자열로 디코딩한다. WER은 S·D·I의 합을 정답 단어 수 N으로 나눈 값이며, CTC blank는 frame-to-token 정렬에 쓰는 기호이지 모든 ASR 모델의 필수 기호가 아니다.

## Study Guide

1. PDF pp.2–8을 읽으며 $$1/N$$ 위치를 고정하고, sine 하나가 양·음 bin으로 나뉘는 이유를 직접 전개한다. Radix-2 butterfly에서 같은 길이 $$N/2$$ 계산이 두 출력에 재사용되는 곳을 찾는다.
2. pp.9–15에서는 창 $$L$$과 hop $$H$$를 표본 수에서 초로 환산하고, magnitude·phase·power·dB가 무엇을 버리고 무엇을 남기는지 적는다. iSTFT를 말할 때는 복원 조건을 동반한다.
3. pp.16–23에서는 HTK/Slaney 척도, filterbank의 power 합, log floor, cepstrum의 quefrency, MFCC의 DCT를 순서대로 설명한다. 실제 학습 성능은 별도 평가 문제다.
4. 시각화에서 초기 0.0625초와 8개의 표본 순간을 번갈아 본다. 7개 정수만 포함하는 strict 범위 오류를 찾아 대표 bin과 bandlimit를 구분한다.
5. ASR 보충에서는 한 문장을 직접 단어 단위로 정렬해 S·D·I·N과 WER을 계산하고, CTC 경로의 반복 병합과 blank 제거 순서를 확인한다.

## 복습 질문

<details markdown="block">
<summary>1. FFT가 DFT의 출력 자체를 바꾸는가?</summary>

답변: 아니다. 짝수·홀수 항을 길이 $$N/2$$인 두 DFT로 재사용해 radix-2에서는 $$O(N^2)$$ 직접 계산을 $$O(N\log N)$$으로 줄인다. 정규화 convention을 같게 맞추면 수학적 출력은 동일하다.

</details>

<details markdown="block">
<summary>2. 10 Hz 실수 sine의 DFT에 1990 Hz 봉우리가 있으면 1990 Hz 소리가 실제로 있었다는 뜻인가?</summary>

답변: $$f_s=2000$$ Hz로 표시한 DFT에서 1990 Hz bin은 −10 Hz를 주기적으로 나타낸 것이다. 실수 신호의 켤레대칭을 반영한 결과이지 독립된 소리나 그 자체로 sampling aliasing 증거가 아니다.

</details>

<details markdown="block">
<summary>3. STFT magnitude spectrogram을 저장했다면 iSTFT로 원 파형을 정확히 되살릴 수 있는가?</summary>

답변: 일반적으로 아니다. Magnitude만 저장하면 복소 phase가 빠진다. 정확한 복원에는 복소 STFT와 일치하는 창·hop·padding·길이, 표본마다 0이 아닌 overlap-add 정규화가 필요하다.

</details>

<details markdown="block">
<summary>4. FFT 길이를 zero-padding으로 두 배로 만들면 두 가까운 음의 물리적 분해능도 두 배가 되는가?</summary>

답변: 아니다. Bin 간격 $$f_s/N_{\mathrm{FFT}}$$은 반이 되지만 관측 시간 $$L/f_s$$는 그대로다. Spectrum 곡선을 더 촘촘히 샘플링할 뿐 짧은 창이 담지 못한 구별 정보를 만들지 않는다.

</details>

<details markdown="block">
<summary>5. MFCC와 real cepstrum의 마지막 변환은 같은가?</summary>

답변: 아니다. Real cepstrum은 log magnitude spectrum에 inverse DFT를 적용해 quefrency를 본다. MFCC는 mel band 값을 log로 바꾼 뒤 DCT를 적용한다. 둘 다 spectrum의 구조를 다시 분해하지만 입력 축과 변환이 다르다.

</details>

<details markdown="block">
<summary>6. N=8에서 strict 범위 −4&lt;k&lt;4가 8개 DFT bin의 대표값인가?</summary>

답변: 아니다. 정수는 −3부터 3까지 일곱 개다. $$-4\le k<4$$처럼 한쪽 경계를 포함해야 여덟 나머지류를 대표한다. 원 신호의 strict Nyquist bandlimit $$\lvert f\rvert<f_s/2$$는 bin index 집합의 정의와 다른 조건이다.

</details>

<details markdown="block">
<summary>7. WER이 같으면 substitution, deletion, insertion의 구성도 같은가?</summary>

답변: 아니다. WER은 $$(S+D+I)/N$$이므로 오류의 합과 정답 단어 수만으로 결정된다. 서로 다른 S·D·I 조합이 같은 WER을 만들 수 있다. 결과 길이도 $$H=N-D+I$$로 달라질 수 있다.

</details>

<details markdown="block">
<summary>8. CTC blank는 무음 또는 띄어쓰기이며 모든 ASR decoder에 필요한가?</summary>

답변: 아니다. Blank는 CTC 경로의 해당 시점에서 새 token을 내지 않는 기호다. 연속 반복 기호를 합친 뒤 blank를 제거하므로 같은 글자를 연속 출력할 때 두 글자 사이의 blank가 구분을 만든다. Attention encoder–decoder에는 CTC blank가 필수가 아니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-02-2.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture2-2.pdf</a> — DFT, STFT, mel, MFCC 원문 슬라이드.</li>
</ul>

## References

- <a href="https://speechprocessingbook.aalto.fi/representations/melcepstrum/" target="_blank" rel="noopener">Aalto University: Cepstrum, Mel-Cepstrum and MFCC</a> — harmonic 간격과 quefrency 및 mel-DCT의 구분.
- <a href="https://trec.nist.gov/pubs/trec9/sdrt9_slides/tsld017.htm" target="_blank" rel="noopener">NIST: ASR Metrics</a> — WER의 편집 오류 합과 reference 단어 수 정의.
- <a href="https://www.cs.toronto.edu/~graves/icml_2006.pdf" target="_blank" rel="noopener">Graves et al. (2006): Connectionist Temporal Classification</a> — blank, 경로 합, decoding.
- <a href="https://research.google/pubs/listen-attend-and-spell-a-neural-network-for-large-vocabulary-conversational-speech-recognition/" target="_blank" rel="noopener">Chan et al. (2016): Listen, Attend and Spell</a> — attention encoder–decoder ASR.

- <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.stft.html" target="_blank" rel="noopener">SciPy STFT documentation</a> — window, one-sided output, NOLA/iSTFT 조건.
- <a href="https://librosa.org/doc/main/api/generated/librosa.mel_frequencies.html" target="_blank" rel="noopener">librosa mel frequencies</a> 및 <a href="https://librosa.org/doc/main/api/generated/librosa.feature.melspectrogram.html" target="_blank" rel="noopener">mel spectrogram</a> — HTK/Slaney 척도와 filterbank 옵션.
- <a href="https://ocw.mit.edu/courses/2-161-signal-processing-continuous-and-discrete-fall-2008/b0a5f07216a4153e8f6160178f0ea764_lecture_04.pdf" target="_blank" rel="noopener">MIT 2.161 Lecture 4</a> — 연속 rectangular pulse의 sinc spectrum.
- <a href="https://ocw.mit.edu/courses/res-6-007-signals-and-systems-spring-2011/4057518e4fe8d9c54ddb2ce64d869f94_MITRES_6_007S11_lec17.pdf" target="_blank" rel="noopener">MIT Signals and Systems Lecture 17</a> — sampling spectrum과 sinc interpolation.
