---
layout: default
date: 2026-09-29 15:23:36 +0900
last_modified_at: 2026-10-02 12:36:56 +0900
title: "Speech and Audio Recognition Lecture 3: Automatic Speech Recognition I"
course: "Speech and Audio Recognition"
topic: "ASR Evaluation, CTC, Encoders, and Language Models"
order: 4
major_topic: "Speech and Audio Processing"
keywords:
  - "Automatic Speech Recognition"
  - "WER"
  - "CER"
  - "CTC"
  - "Forward Algorithm"
  - "Beam Search"
  - "Deep Speech 2"
  - "Conformer"
  - "Subword Tokenization"
  - "Language Model"
---

# Speech and Audio Recognition Lecture 3: Automatic Speech Recognition I

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture3.pdf</a> — Inkyu An, Kookmin University (51 slides).

앞선 [Digital Signal Processing I](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)와 [Spectral Analysis Lab](/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/)에서 파형을 표본과 spectral feature로 바꿨다. 이번 강의는 그 feature를 문자·단어열로 바꾸는 **automatic speech recognition(ASR)**의 첫 단계를 다룬다. 아래의 슬라이드 번호는 PDF의 물리적 페이지 번호다. 강의에 없는 유도와 수치 예제는 해당 위치에서 출처를 구분한다.

> **음성 프레임 수와 정답 글자 수가 다르고 둘의 정렬도 주어지지 않는다.** CTC는 여러 프레임별 경로를 하나의 텍스트로 접는 규칙을 정의하고, 같은 정답으로 접히는 경로의 확률을 모두 더해 학습한다. 평가에는 WER/CER을, 실제 문장 선택에는 greedy 또는 beam decoding과 필요시 언어 모델을 사용한다.

## 전체 흐름

| 단계 | 강의 위치 | 해결할 질문 |
|---|---|---|
| ASR와 평가 | pp. 2–9 | 음성 전사를 어떻게 측정하고 어떤 데이터에서 평가하는가? |
| 정렬 문제 | pp. 10–22 | 프레임마다 나온 반복·공백을 어떻게 가변 길이 문장으로 바꾸는가? |
| CTC 학습 | pp. 23–35 | 정답 정렬을 모를 때 모든 유효 경로의 확률을 어떻게 효율적으로 더하는가? |
| CTC 추론 | pp. 36–41 | 가장 가능성 높은 프레임 경로와 가장 가능성 높은 문장은 왜 다를 수 있는가? |
| Encoder 설계 | pp. 42–48 | 음성의 지역·전역 문맥을 어떻게 표현하고 계산량을 줄이는가? |
| 언어 모델 | pp. 49–51 | 음향적으로 비슷한 단어 중 문맥에 맞는 전사를 어떻게 고르는가? |

## 1. ASR 과제와 오류율

ASR은 입력 음성 $$X$$에서 텍스트 $$y$$를 예측하는 작업이다. 강의 첫 장은 오디오를 `Hello world`로 바꾸는 예를 든다(pp. 2–3). 슬라이드의 `SST`는 통상 쓰는 약어인 **STT (speech-to-text)**의 오기로 보는 것이 타당하다. ASR은 시스템/과제를, STT는 음성에서 문자로의 변환을 강조하는 표현이다.

### 1.1 WER와 CER의 정의

Word error rate(WER)는 정답 단어열을 예측 단어열로 바꾸는 **최소 편집 횟수**를 정답 단어 수로 나눈 값이다(pp. 3–6).

$$
\mathrm{WER}=\frac{S+D+I}{N}
$$

| 기호 | 의미 | 단위 |
|---|---|---|
| $$S$$ | 치환된 단어 수 | words |
| $$D$$ | 정답에는 있지만 예측에서 빠진 단어 수 | words |
| $$I$$ | 예측에 추가된 단어 수 | words |
| $$N$$ | 정답 단어 수 | words |
| $$\mathrm{WER}$$ | 단어별 정규화된 편집 거리 | 무차원 |

**작성자 보충 — 편집 거리를 구하는 이유와 유도.** 문장 길이가 다르면 위치별 1:1 비교가 성립하지 않는다. 정답의 앞 $$i$$개 단어를 예측의 앞 $$j$$개 단어로 바꾸는 최소 비용을 $$D_{i,j}$$라고 두면, 마지막 연산은 삭제·삽입·일치/치환 중 하나뿐이다. 따라서 다음 정확한 동적 계획법 관계가 나온다.

$$
D_{i,j}=\min\left\{D_{i-1,j}+1,\;D_{i,j-1}+1,\;D_{i-1,j-1}+\mathbf{1}[r_i\ne h_j]\right\}
$$

초기값은 $$D_{i,0}=i$$, $$D_{0,j}=j$$다. 최종 경로를 역추적해 $$S,D,I$$를 얻고 $$D_{N,M}/N$$을 계산한다. 강의 예시(pp. 3–6)에서 `brown → brow`는 치환, `an`은 삽입, `a`는 삭제로 맞출 수 있다. 정답은 9단어이므로 $$\mathrm{WER}=3/9=1/3$$이다. 같은 편집 원리를 문자 단위에 적용하면 **CER**이지만, 분모도 정답 문자 수로 바뀐다.

WER은 비율이지만 상한이 1은 아니다. 삽입 단어가 많으면 $$S+D+I>N$$이 가능하다. 반면 $$N=0$$이면 분모가 0이므로 WER은 정의되지 않는다. 빈 정답의 처리 방식은 평가 프로토콜에서 별도로 정해야 한다. 슬라이드 p. 6의 `D > S > I`는 의미 손실에 관한 직관적 예시이지 WER 공식의 가중치가 아니다. 실제 세 오류의 영향은 발화와 용도에 따라 달라진다.

### 1.2 데이터셋과 평가 조건

강의는 낭독 음성 예로 Wall Street Journal(WSJ)과 LibriSpeech를 소개한다(pp. 7–8). WSJ 슬라이드는 학습 약 73시간, 평가 약 8시간을, LibriSpeech 슬라이드는 학습 960시간과 clean/other 평가 조건을 제시한다. `clean`과 `other`의 WER은 서로 다른 난도의 평가 집합에서 측정하므로 **모델·전처리·디코더·학습 자료·평가 split이 같은지** 확인하지 않은 숫자를 모델의 보편적 성능으로 비교할 수 없다. 슬라이드의 WER 수치는 퍼센트 단위다. Audacity는 녹음과 파형·스펙트로그램을 확인하는 도구로 짧게 소개된다(p. 9).

## 2. 음성 feature에서 텍스트까지: 왜 정렬이 문제인가

전통적인 ASR의 한 구성은 acoustic model이 feature에서 음소 점수를 만들고, 발음 사전(lexicon)이 단어와 음소열을 연결하며, language model이 단어열의 문맥 적합성을 평가하는 것이다(pp. 10–11). 강의의 HMM/GMM과 n-gram은 이 역할을 설명하는 예이지 모든 과거·현재 ASR 시스템이 반드시 같은 부품을 사용한다는 뜻은 아니다.

딥러닝 기반 구성에서는 음성의 spectrogram 또는 Mel spectrogram을 시간순 feature $$X=(x_1,\ldots,x_T)$$로 만들고, encoder가 각 시점의 분포 $$p_t(k\mid X)$$를 출력한다(pp. 12–18). $$T$$는 encoder 출력 프레임 수, $$k$$는 vocabulary 안의 token이다. 예를 들어 $$X\in\mathbb{R}^{T\times F}$$라면 $$F$$는 프레임당 feature 수이고 $$O\in[0,1]^{T\times \lvert\mathcal V'\rvert}$$의 각 행은 token 분포다. 이 표기는 슬라이드의 시간 index와 어휘 index가 같은 기호로 보이는 혼동을 피하기 위한 **작성자 보충**이다.

정답 문장 $$y=(y_1,\ldots,y_U)$$는 대체로 $$U<T$$이며 각 글자가 어느 프레임에서 나왔는지 정답에 표시되어 있지 않다. 슬라이드 p. 16의 `Hello`와 `World`는 서로 다른 프레임 구간에 걸친다. 단순히 프레임마다 argmax를 적용하면 `h h e l l l …`처럼 같은 소리가 지속되는 동안 동일 문자가 여러 번 나온다. 그렇다고 연속된 글자를 모두 합치면 `hello`의 두 `l`을 구별할 수 없고, 말 사이의 무음도 표현하기 어렵다(pp. 17–22).

## 3. CTC의 blank, 경로, 학습 목표

Connectionist Temporal Classification(CTC)은 token 집합에 별도 기호 **blank** $$\epsilon$$을 추가한다. 이 기호는 공백 문자(space)나 단어 경계가 아니고, 음향적으로 무음임을 확정하는 표지도 아니다. 한 출력 프레임을 차지하되 최종 전사에는 남지 않는 CTC 경로 기호다. 출력 경로 $$\pi=(\pi_1,\ldots,\pi_T)$$를 문장으로 바꾸는 함수 $$\mathcal B$$는 **먼저 연속 중복을 합치고, 다음에 blank를 삭제**한다(pp. 21–22). 순서를 바꾸면 결과가 달라진다.

```text
h h e l l ε l o  →  h e l ε l o  →  hello
l ε l          →  l ε l        →  ll
l l            →  l            →  l
```

따라서 같은 글자 `ll`을 내보내려면 둘 사이에 blank가 필요하다. 프레임 출력 길이 $$T$$는 단순히 $$U$$ 이상이어야 할 뿐 아니라, 정답의 **인접한 동일 token 쌍 수**를 $$R$$이라 하면 최소 $$T\ge U+R$$이어야 유효 CTC 경로가 존재한다. 이는 collapse 규칙에서 곧장 따라오는 필요조건이다.

슬라이드 p. 23의 다섯 경로를 **중복 병합 → blank 삭제** 순서로 직접 접으면 결과가 갈린다.

| 프레임 경로 | 중복 병합 후 | blank 삭제 후 |
|---|---|---|
| `h ε e l ε l ε o o o` | `h ε e l ε l ε o` | **`hello`** |
| `h ε e l l l ε l o o` | `h ε e l ε l o` | **`hello`** |
| `ε h h h e l ε l o o` | `ε h e l ε l o` | **`hello`** |
| `h ε e l ε l ε l o o` | `h ε e l ε l ε l o` | `helllo` |
| `ε h h h e l ε l ε ε` | `ε h e l ε l ε` | `hell` |

첫 세 경로는 동일한 정답을 만들지만 네 번째는 blank로 분리된 `l`이 셋이고, 다섯 번째는 `o`가 없다. **유효 경로**란 음향적으로 그럴듯한 경로 전체가 아니라, collapse 결과가 목표 전사와 정확히 같은 경로다.

### 3.1 경로 합과 loss의 차이

정답 $$y$$를 만드는 경로는 하나가 아니다(pp. 23–28). Encoder의 매 출력 프레임에서 softmax는 blank를 포함한 token별 확률 분포를 낸다. 각 프레임의 확률은 1로 합해지지만, 이 값 하나가 문장 전체의 확률은 아니다. CTC는 $$X$$가 주어졌을 때 경로의 프레임별 출력을 조건부 독립으로 분해한다. 따라서 한 경로에서는 각 프레임에서 선택한 token 확률을 **곱하고**, 같은 문장으로 접히는 서로 다른 경로들의 확률은 **더한다**.

**프레임 확률은 어디에서 오는가?** Encoder가 음성의 특징을 표현하면 출력층이 각 token에 실수 점수인 logit $$\ell_{t,k}$$를 부여한다. Softmax는 이 점수를 다음 분포로 바꾼다. $$\mathcal V'=\mathcal V\cup\{\epsilon\}$$는 blank를 포함한 어휘이며, logit과 확률은 무차원이다.

$$
p_t(k\mid X)=\frac{\exp(\ell_{t,k})}{\sum_{j\in\mathcal V'}\exp(\ell_{t,j})}
$$

예를 들어 순서를 `ε, A, B`로 두고 logit이 $$(0,\ln 3,0)$$이라면 지수값은 $$(1,3,1)$$이다. 합인 5로 나누면 분포는 $$(0.2,0.6,0.2)$$가 된다. **CTC가 `A`의 확률 0.6을 새로 만드는 것이 아니라, 신경망의 출력 점수가 0.6으로 정규화된 것이다.** 이 숫자는 설명을 위한 구성 예이며 실제 음성에서 측정한 결과가 아니다. 모델이 특정 음성에 왜 그 점수를 주는지는 학습된 가중치와 입력 특징에 달려 있고, CTC 정의만으로는 결정되지 않는다.

Forward DP를 한 번 계산하는 동안에는 이 프레임별 확률표를 고정한다. 목표 전사 `AB`는 **어떤 경로를 합할지** 정할 뿐, 확률표를 `A`와 `B`만으로 다시 정규화하지 않는다. 다른 token이나 잘못된 순서에 배정된 확률도 모델 분포에 남아 있으므로 정답 전사의 확률은 보통 1보다 작다. 이 구분은 [CTC 원 논문의 출력 분포와 경로 합 정의](https://www.cs.toronto.edu/~graves/icml_2006.pdf){:target="_blank" rel="noopener"}에 따른다.

$$
P_{\mathrm{CTC}}(y\mid X)=\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid X)
$$

예컨대 슬라이드 pp. 24–27의 확률 그림에서는 한 열이 한 시각의 분포이고, 경로 한 개는 각 열에서 token 한 칸씩 선택한다. 원문에 표시된 세 경로의 곱은 각각 약 0.00123, 0.00112, 0.00001이다. 이 숫자를 단순히 최대값 하나로 대체하지 않고, 같은 전사로 접히는 나머지 경로까지 합한 값이 **정답 전사의 확률**이다. 최대로 만들려는 이 확률과 최소화할 **loss**는 다음처럼 부호와 로그가 다르다.

$$
\mathcal L_{\mathrm{CTC}}(X,y)=-\log P_{\mathrm{CTC}}(y\mid X)
$$

슬라이드 p. 28은 경로 확률을 더하는 대목에 `CTC Loss`라고 쓰지만, 합 자체를 loss로 최소화하면 방향이 반대다. **높은 정답 확률 → 작은 음의 로그 손실**이라는 관계가 정확하다. 조건부 독립은 $$X$$가 주어졌을 때의 출력 경로에 대한 모델 가정이며, encoder가 음향 문맥을 전혀 이용하지 않는다는 뜻은 아니다.

### 3.2 왜 forward dynamic programming이 필요한가

유효한 정렬 경로를 전부 나열하면 프레임 수와 함께 가능한 조합이 빠르게 늘어난다. CTC는 목표열 사이에 blank를 끼워 넣은 확장열을 만든다(p. 30).

$$
z=(\epsilon,y_1,\epsilon,y_2,\ldots,\epsilon,y_U,\epsilon),\qquad S=2U+1
$$

$$z_s$$는 확장열의 $$s$$번째 기호다. $$\alpha_{t,s}$$를 **시각 $$t$$까지의 허용된 부분 경로 중 $$s$$번째 상태로 끝나는 경로들의 확률 합**으로 정의한다. $$p_t(z_s\mid X)$$가 현재 프레임 하나의 출력 확률이라면, $$\alpha_{t,s}$$는 그곳에 도달하기까지의 프레임들을 모두 반영한다. 아직 정답을 완성하지 않은 중간 상태도 이 합에 포함되며, 최종 두 상태에서만 완성된 전사의 확률을 읽는다.

상태는 token 종류만 나타내는 것이 아니라 **정답의 어디까지 진행했는지**도 나타낸다. 목표가 `AB`일 때 세 blank 상태의 차이는 다음과 같다.

| 상태 | 지금까지의 collapse 결과 | 현재 출력 |
|---|---|---|
| $$s=1$$ | 빈 문자열 | 첫 `A` 이전의 blank |
| $$s=2$$ | `A` | 첫 `A` 또는 그 연속 반복 |
| $$s=3$$ | `A` | `A` 다음의 blank |
| $$s=4$$ | `AB` | `B` 또는 그 연속 반복 |
| $$s=5$$ | `AB` | `B` 다음의 blank |

세 blank 상태는 같은 프레임 확률 $$p_t(\epsilon\mid X)$$를 쓰지만 서로 다른 부분 경로를 담는다. 따라서 상태마다 별도의 blank 출력 확률이 있는 것도, 같은 경로를 세 번 세는 것도 아니다. 마지막 프레임에 한 상태로 오는 방법은 같은 상태에 머물기, 한 상태 전진하기, 조건부로 두 상태 건너뛰기뿐이다. 다음은 pp. 29–32의 그림을 1-based index로 명시한 **작성자 유도**다.

$$
\alpha_{t,s}=p_t(z_s\mid X)\left[\alpha_{t-1,s}+\alpha_{t-1,s-1}+\mathbf{1}[s\ge 3,\ z_s\ne\epsilon,\ z_s\ne z_{s-2}]\alpha_{t-1,s-2}\right]
$$

유효 범위 밖의 $$\alpha$$는 0으로 둔다. 처음에는 $$\alpha_{1,1}=p_1(\epsilon\mid X)$$, $$\alpha_{1,2}=p_1(y_1\mid X)$$이고 나머지는 0이다. 두 칸 건너뛰기는 도착 기호가 blank가 아니고 두 칸 앞의 기호와 다를 때만 허용한다. 같은 글자의 두 상태를 blank 없이 건너뛰면 실제 collapse 결과는 글자 하나인데 반복 글자 정답의 경로로 잘못 셀 수 있다. 끝에서는 마지막 label 상태와 마지막 blank 상태를 합한다.

$$
P_{\mathrm{CTC}}(y\mid X)=\alpha_{T,S-1}+\alpha_{T,S}
$$

이 유도는 유효 경로가 마지막 시각에 두 상태 중 하나에서만 종료되고, 각 종료 상태의 바로 전 전이가 위 세 경우로 완전히 분할된다는 사실에 기초한다. 같은 상태로 끝나는 이전 경로들은 이후에 동일한 전이 선택지를 가지므로, 이전 경로의 개별 목록 대신 그 **확률 합 하나**만 다음 프레임에 전달해도 된다. 상태 $$S=2U+1$$개와 시각 $$T$$개를 한 번씩 계산하므로 시간 복잡도는 $$O(TU)$$다. 실제 구현은 매우 작은 확률의 곱에서 수치 underflow가 생기지 않게 log-domain 또는 scaling을 쓴다.

### 3.3 경로별 계산과 forward DP가 만나는 예

다음은 계산 과정을 한눈에 보기 위한 **작성자 예제**다. 세 프레임에서 token 분포를 아래처럼 정하고 정답을 `AB`로 둔다. 각 열의 합은 1이다. 확률은 모델이 각 시각에 내놓은 값이라는 가정이지, 문장을 미리 나눈 확률이 아니다.

| Token | $$t=1$$ | $$t=2$$ | $$t=3$$ |
|---|---:|---:|---:|
| $$\epsilon$$ | 0.2 | 0.3 | 0.2 |
| $$A$$ | 0.6 | 0.3 | 0.2 |
| $$B$$ | 0.2 | 0.4 | 0.6 |

총 $$3^3=27$$개 경로 가운데 `AB`로 접히는 것은 다음 다섯 개뿐이다. `AAB`와 `ABB`는 각각 붙어 있는 중복을 하나로 합치고, blank가 든 경로는 중복 처리 후 blank를 지운다.

| 유효 경로 | collapse 과정 | 프레임 확률의 곱 |
|---|---|---:|
| `εAB` | `εAB → AB` | $$0.2\cdot0.3\cdot0.6=0.036$$ |
| `AεB` | `AεB → AB` | $$0.6\cdot0.3\cdot0.6=0.108$$ |
| `AAB` | `AAB → AB` | $$0.6\cdot0.3\cdot0.6=0.108$$ |
| `ABε` | `ABε → AB` | $$0.6\cdot0.4\cdot0.2=0.048$$ |
| `ABB` | `ABB → AB` | $$0.6\cdot0.4\cdot0.6=0.144$$ |

예컨대 `AεA`는 두 `A` 사이가 분리되어 `AA`로 접히므로 이 표에 포함되지 않는다. 반면 `AAε`는 `A` 하나로 접힌다. 이 차이가 반복 token 사이에 blank 상태를 두는 이유다. 다섯 경로가 서로 겹치지 않으므로,

$$
P_{\mathrm{CTC}}(AB\mid X)=0.036+0.108+0.108+0.048+0.144=0.444,
\qquad
\mathcal L_{\mathrm{CTC}}=-\ln(0.444)\approx0.81193.
$$

경로를 열거하지 않아도 같은 값이 나오는지 forward DP로 확인할 수 있다. 확장열 $$z=(\epsilon,A,\epsilon,B,\epsilon)$$에 대해 각 상태에서 끝나는 **누적 확률 합**은 다음과 같다. `—`는 아직 도달할 수 없는 상태다.

| 상태 $$z_s$$ | $$t=1$$ | $$t=2$$ | $$t=3$$ |
|---|---:|---:|---:|
| $$s=1:\epsilon$$ | 0.2 | 0.06 | 0.012 |
| $$s=2:A$$ | 0.6 | 0.24 | 0.060 |
| $$s=3:\epsilon$$ | — | 0.18 | 0.084 |
| $$s=4:B$$ | — | 0.24 | **0.396** |
| $$s=5:\epsilon$$ | — | — | **0.048** |

**첫 프레임: 출력 확률을 시작 상태에 놓는다.** `ε`로 시작하는 부분 경로의 확률은 0.2, `A`로 시작하는 부분 경로의 확률은 0.6이다. 첫 프레임에 `B`가 나오는 확률도 모델에는 0.2가 있지만, `B`로 시작한 경로는 나중에 앞에 `A`를 끼워 넣어 `AB`가 될 수 없다. 따라서 목표 `AB`의 DP에는 들어오지 않는다. 시작 열의 합이 0.8인 이유이며, 남은 0.2를 없애거나 다른 칸에 나누어 주지 않는다.

**둘째 프레임의 `A`: 두 경로가 한 칸에 모인다.** $$s=2$$로 오는 경로는 `εA`와 `AA`다. 각각의 확률과 합을 먼저 경로 단위로 쓰면 다음과 같다.

$$
\begin{aligned}
\alpha_{2,2}
&=\underbrace{0.2\times0.3}_{\epsilon A}
+\underbrace{0.6\times0.3}_{AA}\\
&=(0.2+0.6)\times0.3\\
&=0.24.
\end{aligned}
$$

곱셈은 **앞의 경로가 나오고 현재 `A`도 나오는 사건**의 확률을 계산한다. 덧셈은 **`εA` 또는 `AA` 중 하나가 나오는 사건**의 확률을 계산한다. 두 경로는 첫 프레임 출력이 달라 겹치지 않는다. 공통된 현재 확률 0.3을 묶어 쓰면 DP 식이 된다. 두 경로의 평균을 내거나 가장 큰 경로 하나만 고르는 연산이 아니다.

같은 방식으로 둘째 프레임의 나머지 칸도 계산된다. 가운데 blank에는 `Aε`가, `B`에는 `AB`가 들어간다. 끝 blank는 아직 `A`와 `B`를 모두 출력하지 못했으므로 도달할 수 없다.

| $$t=2$$의 상태 | 들어오는 부분 경로 | 계산 | 누적 확률 |
|---|---|---|---:|
| $$s=1:\epsilon$$ | `εε` | $$0.2\times0.3$$ | 0.06 |
| $$s=2:A$$ | `εA`, `AA` | $$(0.2+0.6)\times0.3$$ | 0.24 |
| $$s=3:\epsilon$$ | `Aε` | $$0.6\times0.3$$ | 0.18 |
| $$s=4:B$$ | `AB` | $$0.6\times0.4$$ | 0.24 |
| $$s=5:\epsilon$$ | 없음 | $$0$$ | 0 |

**셋째 프레임의 `B`: 이전 칸 안의 경로까지 이어 붙인다.** 앞의 `A` 칸에 있던 `εA`, `AA`는 `εAB`, `AAB`가 된다. 가운데 blank 칸의 `Aε`는 `AεB`가 되고, `B` 칸의 `AB`는 `ABB`가 된다. 어느 칸에서 왔든 새로 붙이는 token은 `B`이므로 현재 확률 0.6은 공통이다.

| 이전 상태 | 이전 칸에 들어 있던 확률 합 | 이번에 만든 경로 | 마지막 `B`에 보태는 값 |
|---|---|---|---:|
| $$s=2:A$$에서 skip | $$0.06+0.18=0.24$$ | `εAB`, `AAB` | $$0.24\times0.6=0.144$$ |
| $$s=3:\epsilon$$에서 전진 | $$0.18$$ | `AεB` | $$0.18\times0.6=0.108$$ |
| $$s=4:B$$에서 stay | $$0.24$$ | `ABB` | $$0.24\times0.6=0.144$$ |

세 기여를 합하면 다음 값이 나온다.

$$
\begin{aligned}
\alpha_{3,4}
&=0.6\bigl(\alpha_{2,2}+\alpha_{2,3}+\alpha_{2,4}\bigr)\\
&=0.6(0.24+0.18+0.24)\\
&=0.396.
\end{aligned}
$$

경로별로 풀면 네 경로의 기여를 확인할 수 있다.

$$
\begin{aligned}
0.396&=(0.036+0.108)\\
&\quad+0.108+0.144.
\end{aligned}
$$

DP의 0.24는 이미 두 경로의 합이므로, 이 칸에서 `B`로 가는 화살표 하나가 경로 하나만을 뜻하지 않는다. 끝 blank에는 `ABε` 하나가 들어가서 $$\alpha_{3,5}=0.24\times0.2=0.048$$이다. **두 종료 상태의 합 $$0.396+0.048=0.444$$가 경로 열거와 정확히 같다.** 아래 그림의 파란 칸은 이 두 종료 상태이며, 그림 하단의 곱은 이전 칸의 확률 합이 마지막 `B`에 보태는 양이다.

<figure>
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/ctc-forward-ab-trellis.svg" | relative_url }}" alt="정답 AB의 CTC forward 계산. 마지막 B에는 A 칸의 0.24 곱하기 0.6, 가운데 blank 칸의 0.18 곱하기 0.6, B 칸의 0.24 곱하기 0.6이 들어와 0.396이 된다. 끝 blank의 0.048을 더하면 0.444다." loading="lazy">
  <figcaption>CTC forward trellis — 화살표는 확률을 전달하는 전이이며, 한 화살표에 여러 부분 경로의 확률 합이 실릴 수 있다.</figcaption>
</figure>

**왜 마지막 두 칸이면 계산이 끝나는가?** 마지막 프레임까지 읽은 뒤 `AB`로 접히는 경로는 `B`에서 끝나거나 `B` 뒤의 blank에서 끝난다. 다른 칸의 $$0.012,0.060,0.084$$는 각각 빈 문자열, `A`, `A`까지만 만든 부분 경로다. 세 프레임을 모두 썼으므로 여기에 `B`를 추가할 기회가 없다. 목표 전사의 확률에 넣지 않는 이유다. 종료 두 칸은 서로 겹치지 않고, `AB`를 만드는 경로는 하나도 빠짐없이 이 둘에 들어간다.

이 결과는 반복 계산이 어느 값에 가까워지는 **수렴**이 아니다. 각 칸이 해당 부분 경로들의 곱을 정확히 더한다면, 다음 칸도 분배법칙으로 그 정확한 합을 이어받는다. 시작 칸은 한 프레임의 확률이므로 이 성질이 처음부터 성립하며, 이를 $$t=1,2,\ldots,T$$에 적용하면 마지막 합도 정확하다. Forward DP는 경로를 빠짐없이, 중복 없이 묶어 계산하는 유한한 합산 절차다.

또한 DP 표는 프레임별 softmax 분포가 아니므로 매 열을 다시 합해서 1로 만들지 않는다. 셋째 열의 합은 다음과 같다.

$$
\begin{aligned}
\sum_{s=1}^{5}\alpha_{3,s}&=0.012+0.060+0.084\\
&\quad+0.396+0.048\\
&=0.600.
\end{aligned}
$$

이 가운데 0.444만 정답 `AB`의 확률이고 0.156은 아직 `A` 이전 또는 `A`까지만 간 경로의 확률이다. 나머지 0.400은 `B`로 시작하거나 `AεA`처럼 목표를 벗어난 경로에 있다. **정답 경로 0.444와 그 밖의 경로 0.556을 모두 합하면 1**이다. 이 짧은 예제에서는 27개 경로를 직접 나열해 이를 검산할 수 있다.

정답 확률을 높이는 **학습**은 별개의 반복이다. 한 번의 학습 단계는 `모델 출력 → 고정된 확률표의 DP → 음의 로그 손실 → 역전파 → 가중치 갱신`으로 진행된다. 갱신된 모델이 다음 단계에서 새 확률표를 만들면 정답 경로들의 합도 달라진다. 학습은 그 합을 높이는 방향을 찾지만, 매 단계의 손실 감소나 정답 확률이 1에 도달하는 것을 보장하지 않는다. DP 칸의 값 역시 시간이 흐를수록 증가해야 하는 값이 아니다. 예제에서 `A` 칸은 0.6 → 0.24 → 0.060으로 줄어들어도 계산은 올바르다.

### 3.4 슬라이드 예제의 수치 검산

pp. 33–35는 목표 `ab`, 확장열 $$(\epsilon,a,\epsilon,b,\epsilon)$$, 네 프레임을 사용한다. 각 열의 세 확률은 1로 합해진다.

| Token | $$t=1$$ | $$t=2$$ | $$t=3$$ | $$t=4$$ |
|---|---:|---:|---:|---:|
| $$\epsilon$$ | 0.6 | 0.2 | 0.3 | 0.4 |
| $$a$$ | 0.3 | 0.5 | 0.2 | 0.1 |
| $$b$$ | 0.1 | 0.3 | 0.5 | 0.5 |

슬라이드 p. 34의 확률 흐름을 위 forward 식으로 채우면 다음 표가 된다. 첫 프레임에는 앞의 두 상태만 열려 있고, 각 다음 칸은 허용된 이전 칸의 **합에 현재 token 확률을 곱한 값**이다.

| 상태 $$z_s$$ | $$t=1$$ | $$t=2$$ | $$t=3$$ | $$t=4$$ |
|---|---:|---:|---:|---:|
| $$s=1:\epsilon$$ | 0.6 | 0.12 | 0.036 | 0.0144 |
| $$s=2:a$$ | 0.3 | 0.45 | 0.114 | 0.0150 |
| $$s=3:\epsilon$$ | — | 0.06 | 0.153 | 0.1068 |
| $$s=4:b$$ | — | 0.09 | 0.300 | **0.2835** |
| $$s=5:\epsilon$$ | — | — | 0.027 | **0.1308** |

예를 들어 둘째 프레임의 $$a$$ 상태는 시작 blank 또는 시작 $$a$$에서 도달한다. 따라서 $$\alpha_{2,2}=(0.6+0.3)\times0.5=0.45$$다. $$t=3$$의 가운데 blank는 앞의 $$a$$와 같은 blank에서 들어오므로 $$(0.45+0.06)\times0.3=0.153$$이다. 마지막 프레임의 $$b$$ 상태에는 머물기·한 칸 전진·두 칸 건너뛰기가 모두 가능하다.

$$
\alpha_{4,4}=(0.300+0.153+0.114)\times0.5=0.2835
$$

마지막 blank 상태는 다음과 같다.

$$
\begin{aligned}
\alpha_{4,5}&=(0.300+0.027)\times0.4\\
&=0.1308.
\end{aligned}
$$

두 종료 상태를 더하면 **$$P_{\mathrm{CTC}}(ab\mid X)=0.4143$$**으로 슬라이드 p. 35의 결과와 일치하고, 이 예제의 손실은 $$-\ln(0.4143)\approx0.88116$$이다. 확률표 → 유효 경로 합 → 음의 로그 손실이라는 순서를 뒤집지 않아야 한다. 이 검산은 원문 표의 전이가 수식과 같은지 확인하는 것이며 일반 데이터에서의 모델 성능을 뜻하지 않는다.

## 4. CTC decoding: 프레임 경로와 문장 확률은 다르다

Greedy decoding은 매 프레임 가장 큰 확률의 token 하나씩을 택한 뒤 $$\mathcal B$$를 적용한다. 빠르지만 $$\mathcal B(\arg\max_\pi P(\pi\mid X))$$가 반드시 $$\arg\max_y P_{\mathrm{CTC}}(y\mid X)$$는 아니다(pp. 36–38). 서로 다른 경로 여럿이 같은 문장에 확률을 보탤 수 있기 때문이다.

**작성자 보충 — 정규화된 반례.** 두 프레임 모두 $$(p(\epsilon),p(a),p(b))=(0.5,0.4,0.1)$$이라고 하자. 가장 높은 개별 경로는 $$(\epsilon,\epsilon)$$이고 그 확률은 0.25라서 greedy 결과는 빈 문자열이다. 그러나 `a`를 만드는 경로 $$(a,a),(a,\epsilon),(\epsilon,a)$$의 합은 $$0.16+0.20+0.20=0.56$$이다. 경로 최빈값과 문장 최빈값이 실제로 다르다. 슬라이드 p. 37의 수치는 개념도용 부분 예시여서 완전한 정규화 분포로 읽지 않았다.

Beam search는 시각마다 후보 전사 prefix를 확장하고, **같은 전사로 접히는 경로의 확률을 합친 다음** 상위 후보만 남긴다(pp. 38–41). 단순 경로 beam이라면 `AAB`와 `ABB`를 별개 경로로 보유하지만, CTC prefix beam은 두 경로가 같은 `AB`에 기여한다는 사실을 반영한다. 같은 prefix 안에서도 마지막 프레임이 blank인 확률 $$p_b$$와 non-blank인 확률 $$p_{nb}$$를 따로 저장한다. 마지막 글자가 `A`일 때 `AA`가 이어지면 출력은 여전히 `A`지만, `AεA`는 새 `A`가 추가되어 `AA`가 되기 때문이다.

한 프레임을 갱신할 때 blank는 기존 $$p_b+p_{nb}$$에 새 blank 확률을 곱해 **같은 prefix의 $$p_b$$**로 보낸다. 다른 글자 $$c$$를 붙이면 같은 합에 $$p_t(c)$$를 곱해 **확장 prefix의 $$p_{nb}$$**로 보낸다. 다만 $$c$$가 현재 prefix의 마지막 글자와 같다면, 직전 non-blank에서 이어지는 경로는 **기존 prefix에 머무르고**, 직전 blank에서 오는 경로만 반복 글자가 추가된 prefix로 간다. 이 분기 덕분에 반복 글자를 잃지 않고 같은 전사의 경로 확률을 모을 수 있다. 각 프레임에서 $$p_b+p_{nb}$$가 큰 상위 $$K$$개 prefix만 유지하는 것이 beam의 절단 단계다.

$$K$$가 작으면 이른 시점에 버린 prefix를 나중에 회복하지 못하고, $$K$$가 커지면 후보별 갱신과 선택 비용이 증가한다. **유한 beam은 근사**이며 $$K=1$$인 prefix beam도 경로 단위의 프레임별 greedy와 일반적으로 같은 알고리즘은 아니다. 언어 모델을 결합할 수 있지만 점수 가중치와 어휘 제약에 따라 결과가 바뀐다. 탐색을 정확히 하더라도 음향 모델의 확률이 잘못되었다면 전사 자체의 정답을 보장하지 않는다.

CTC의 장점은 **프레임-문자 정렬을 주석으로 주지 않아도 학습**할 수 있고, forward DP로 유효 정렬의 확률을 효율적으로 합산한다는 점이다. 반면 기본 CTC의 경로 확률은 $$X$$를 조건으로 프레임별 출력을 곱하므로 출력 token 사이의 언어적 의존성을 직접 표현하지 않는다. 반복 token에는 blank 프레임이 필요하고, 시간축을 너무 줄이면 유효 경로 자체가 사라진다. 외부 언어 모델이나 더 풍부한 decoder가 추론을 보완할 수 있지만 계산량과 지연 비용도 늘어난다.

슬라이드는 CTC가 streamable하다고 요약한다(p. 36). 다만 **실시간 처리 가능 여부는 encoder와 decoder가 미래 프레임을 요구하는지에 달려 있다.** 양방향 encoder나 긴 look-ahead를 쓰면 CTC loss를 사용하더라도 전체 발화를 기다려야 할 수 있다. CTC trellis의 높은 확률 경로는 학습 중 명시 정렬 없이 얻는 *추정 정렬*이지, 사람이 확정한 음소 경계가 아니다.

## 5. Encoder: Deep Speech 2와 Conformer

강의 p. 42의 Deep Speech 2 도식은 spectrogram → 1D/2D convolution → recurrent/GRU 층 → fully connected 출력 → CTC라는 흐름을 보여 준다. 입력단의 1D convolution은 **시간축**, 2D convolution은 **시간·주파수축**의 인접 패턴을 먼저 추출하고, recurrent 층은 시점에 걸친 문맥을 누적한다. 원 논문에는 양방향 RNN 구성뿐 아니라 미래 문맥을 제한하는 단방향 RNN과 lookahead convolution 구성도 있으므로, 강의의 양방향 그림 하나를 전체 모델의 유일한 형태로 보아서는 안 된다. 학습에는 CTC로 정렬되지 않은 전사를 사용하고, 추론에는 언어 모델을 결합한 beam search를 사용한다.

슬라이드는 학습 자료 약 11,900시간, 약 3,500만 parameter, 16 GPU에서 3–5일의 학습을 소개한다. 이 수치는 **원 논문의 특정 시스템과 당시 조건**의 값으로, 오늘날 ASR의 보편적 요구량이 아니다. 같은 슬라이드의 WER 비교는 다음과 같다.

| Evaluation set | Deep Speech 1 | Deep Speech 2 | Human |
|---|---:|---:|---:|
| WSJ’92 | 4.94% | 3.60% | 5.03% |
| WSJ’93 | 6.94% | 4.98% | 8.08% |
| LibriSpeech test-clean | 7.89% | 5.33% | 5.83% |
| LibriSpeech test-other | 21.74% | 13.25% | 12.69% |

이 표에서는 DS2가 첫 세 평가 조건의 표시된 human WER보다 낮지만, `test-other`에서는 높다. 따라서 p. 42의 `super human quality on clean sets`를 모든 음성 조건에서 인간보다 우수하다는 주장으로 확대하지 않는다. 위 수치는 **강의 슬라이드 표의 전사**이며 재현 실험 결과는 아니다.

Conformer의 차이는 **서로 다른 범위의 문맥을 한 encoder 블록에서 처리한다**는 데 있다(pp. 43–45). Self-attention은 멀리 떨어진 시각 사이의 관계에 내용 기반으로 가중치를 주고, convolution은 인접 프레임에 반복적으로 나타나는 짧은 음향 패턴을 공유 필터로 잡는다. 음소의 시작·전이처럼 가까운 시각의 구조를 국소 필터로 다루면서 발화 전반의 문맥을 attention으로 연결하므로 둘 중 하나만 둔 encoder와 역할이 다르다. 원 논문의 비교 실험도 convolution 모듈의 설계와 위치가 정확도에 영향을 준다고 보고하지만, 모든 설정에서 같은 향상 폭을 보장하는 결과는 아니다.

한 블록은 **half-step feed-forward → 상대 위치를 반영한 multi-head self-attention → convolution module → half-step feed-forward → 최종 LayerNorm** 순서다. 두 feed-forward 층은 각각 출력에 $$\tfrac12$$ 배 잔차 기여를 더하는 macaron 형태다. Convolution module 내부에서는 먼저 LayerNorm 후 pointwise convolution으로 채널을 두 배로 펼치고, GLU gate가 그 절반을 걸러 필요한 feature를 선택한다. 이어 **1D depthwise convolution**이 채널마다 인접 시간 프레임을 훑고, BatchNorm·Swish를 거쳐 마지막 pointwise convolution이 채널을 다시 섞는다. Dropout과 잔차 연결을 포함한 이 흐름은 단순한 표준 convolution 한 층이 아니다.

1D kernel 폭 $$K$$, 입력 채널 $$C_{\mathrm{in}}$$, 출력 채널 $$C_{\mathrm{out}}$$에서 bias를 빼면 일반 convolution은 $$K C_{\mathrm{in}}C_{\mathrm{out}}$$개, depthwise 뒤 pointwise를 한 번 적용한 분리 convolution은 $$K C_{\mathrm{in}}+C_{\mathrm{in}}C_{\mathrm{out}}$$개 parameter를 쓴다. 이는 **두 기본 연산을 비교한 식**이지 GLU와 두 번의 pointwise 층을 포함하는 Conformer convolution module 전체의 parameter 수가 아니다. 실제 속도·정확도는 구현과 하드웨어에도 좌우된다.

### 핵심 구조 비교

| 모델 | Encoder의 중심 | 원 논문의 전사 방식 |
|---|---|---|
| Deep Speech 2 | Convolution 뒤에 recurrent/GRU 층을 쌓아 시간 문맥을 누적 | **CTC 학습**, 언어 모델을 결합한 beam decoding |
| Conformer | 상대 위치 self-attention, 국소 depthwise convolution, 두 half-step feed-forward 층을 한 블록에 결합 | **Transducer 학습**, 단일 LSTM decoder |

강의 p. 43의 그림은 Conformer의 encoder 구조를 강조한다. 원 논문의 전체 ASR 실험은 위 표처럼 Transducer를 사용했으므로, Conformer 자체를 CTC 전용 모델이라고 부르지 않는다.

## 6. Subword tokenization과 시간 축 축소

글자 단위로 길고 반복된 정답을 내면 CTC의 유효 경로가 적어지거나, encoder 시간축이 지나치게 짧을 때 경로가 아예 없어질 수 있다. 반대로 단어 하나를 token 하나로 두면 출력열은 짧지만, 단어 종류가 매우 많아지고 학습에서 보지 못한 단어를 그대로 나타내기 어렵다. **Subword는 글자보다 긴 빈출 조각을 학습하되 필요하면 더 작은 단위로 분해하여, 글자열의 긴 출력과 단어 어휘의 희소성 사이를 조절한다.** 그래서 목표 token 수를 줄이고 반복되는 철자 문맥을 공유할 수 있지만, 언제나 정확도가 오른다는 뜻은 아니다. 적절한 어휘 크기와 분할은 언어, 학습 말뭉치, ASR 구조와 decoder에 따라 달라진다(p. 46).

### 6.1 BPE는 무엇을 학습하고 어떻게 적용하는가

슬라이드 p. 47의 Byte Pair Encoding(BPE)은 문자 vocabulary에서 시작해 **학습 말뭉치에서 가장 빈번한 인접 symbol 쌍**을 새 symbol로 합치는 과정을 정해진 병합 횟수 또는 목표 vocabulary 크기까지 반복한다. 여기서 빈도는 서로 다른 단어 종류를 한 번씩 세는 값이 아니다. 같은 단어가 말뭉치에 여러 번 나오면 그 횟수만큼 그 단어 내부의 인접 쌍 빈도에 가중치를 준다. 또한 Sennrich 등의 word-segmentation 방식은 먼저 공백·구두점 규칙으로 pretokenization한 뒤, **단어 경계를 가로지르는 쌍은 세지 않고** 단어 끝 표지를 사용해 원래 경계를 복원한다. 각 병합의 순서가 곧 merge rank이며, 먼저 학습된 쌍일수록 높은 우선순위를 갖는다.

**작성자 보충 — 빈도 가중 병합 예제.** 계산을 재현할 수 있도록 초기 base alphabet에는 `l, o, w, e, r, s, t`와 경계 symbol `</w>`가 미리 등록되어 있고, pretokenization한 병합 학습 말뭉치에는 `low`가 5회, `lower`가 2회 있다고 가정한다. 각 단어 뒤에는 `</w>`를 별도 token으로 붙이고, 단어 사이 쌍은 만들지 않는다. 첫 단계에서 `(l, o)`와 `(o, w)`는 모두 7회로 동률이다. 이 예제에서는 동률이면 왼쪽에서 더 먼저 나타나는 쌍을 고른다고 명시적으로 정한다. 실제 구현은 자체적인 결정적 tie-breaking 규칙을 사용해야 같은 merge table을 재현할 수 있다.

```text
학습 vocabulary(빈도 포함)
5 × l o w </w>
2 × l o w e r </w>

1순위: (l, o), 빈도 7  →  lo
5 × lo w </w>
2 × lo w e r </w>

2순위: (lo, w), 빈도 7  →  low
5 × low </w>
2 × low e r </w>
```

두 번 병합한 뒤 symbol vocabulary에는 기존 문자와 함께 `lo`, `low`가 추가된다. 슬라이드의 `aaabdaaabac`도 같은 원리로 `aa → Z`, `ab → Y`, `ZY → X`를 순서대로 적용하여 `ZabdZabac → ZYdZYac → XdXac`로 압축한다. 다만 슬라이드의 단일 문자열 예제와 달리, 실제 말뭉치 학습에서는 위처럼 **단어별 출현 빈도를 반영한 전체 쌍 통계**가 병합 순서를 정한다.

추론할 때는 새 입력만 보고 BPE를 다시 학습하지 않는다. 학습 때 저장한 merge rank를 그대로 적용한다. 예를 들어 위 두 병합만 배운 tokenizer에 처음 보는 `lowest`가 들어오면 `l o w e s t </w>`에서 `(l, o)`를 먼저 합치고 `(lo, w)`를 합쳐 `low e s t </w>`를 얻는다. `lowest` 전체가 학습 vocabulary에 없더라도 이미 배운 `low`와 남은 기본 symbol로 표현하는 것이다. 입력마다 병합 통계를 다시 계산하면 같은 문자열의 분할이 주변 입력에 따라 달라지고, 학습 때 사용한 ASR 출력 label 집합과도 일치하지 않는다.

### 6.2 어휘 크기와 ASR decoding의 절충

병합을 많이 할수록 vocabulary는 커지고 자주 등장하는 구간은 더 긴 token 하나가 되므로 목표열 길이 $$U$$는 대체로 짧아진다. CTC에서는 짧아진 $$U$$와 줄어든 반복 label 수가 유효 경로에 필요한 최소 출력 frame 수를 낮출 수 있다. 그러나 CTC prefix beam 자체는 token 수 $$U$$가 아니라 encoder 출력 frame $$T$$를 한 칸씩 진행하므로, tokenization만 바꿨다고 beam의 시간 단계 수 $$T$$가 자동으로 줄어드는 것은 아니다. 반면 acoustic model의 마지막 층은 blank를 포함한 각 token의 logit을 내야 하므로, vocabulary가 커지면 각 frame에서 계산·저장할 logit 차원도 커진다. 드문 긴 subword는 학습 신호가 적어 추정이 불안정할 수도 있다.

병합을 적게 하면 출력층은 작고 희귀 단어를 작은 단위로 조합하기 쉽지만, 한 발화를 표현하는 token 수가 늘어난다. CTC beam에서 후보 prefix를 확장하는 label 단위도 문자, subword, 단어 중 무엇을 쓰는지에 따라 달라지므로, 같은 $$T$$와 beam width라도 frame마다 고려할 vocabulary와 prefix 집합의 비용은 같지 않다. Subword beam은 단어 중간 조각도 후보로 유지하며, 단어 경계 복원과 외부 언어 모델 결합 시에는 ASR token과 LM의 점수 단위가 어떻게 대응하는지도 정해야 한다. Token 수 감소가 직접 decoding step 감소로 이어지는 설명은 LAS나 RNN-T처럼 출력 token 단계가 있는 decoder에 해당하며, frame별 CTC 전체에 일반화할 수 없다. 따라서 **큰 vocabulary는 짧은 정답열, 작은 vocabulary는 작은 출력층**이라는 절충을 검증 집합의 오류율·속도·메모리로 함께 선택해야 한다.

### 6.3 문자 BPE와 byte-level BPE의 범위

이름에 `Byte`가 들어가지만 Sennrich 등의 NLP 적용은 원래 압축 알고리즘을 변형해 **Unicode 문자와 문자열**을 기본 symbol로 병합한다. 이 방식은 자연스러운 문자 경계를 유지하지만, tokenizer의 초기 문자 vocabulary에 없는 문자가 추론에 나타나면 별도 unknown 처리나 fallback이 필요할 수 있다. 반면 byte-level BPE는 UTF-8 텍스트를 byte 단위 symbol로 시작한다. 256개 byte를 모두 기본 vocabulary에 포함하면 임의의 유효 byte열을 분해해 표현할 수 있지만, 한 글자가 여러 byte token으로 길어질 수 있고 정규화·pretokenization·special token·vocabulary filtering 같은 전체 pipeline의 다른 단계까지 자동으로 해결되는 것은 아니다.

따라서 **모든 BPE가 보편적으로 OOV-free라고 단정할 수는 없다.** Sennrich 등의 문자 BPE 논문도 미지 문자가 unknown일 수 있고 joint BPE에서는 한 언어 쪽에만 나타난 segment가 다른 쪽에서 unknown이 되는 예외를 명시한다. 기본 단위가 입력을 완전히 덮는지, 학습된 symbol vocabulary를 inference에서도 동일하게 쓰는지, unknown fallback이 무엇인지까지 확인해야 한다. WordPiece와 Unigram은 강의에서 함께 열거되지만(pp. 46–47), **동일한 병합 규칙의 다른 이름이 아니다.** 이 슬라이드는 둘의 학습 목적식까지 설명하지 않으므로 여기서 BPE와 동치라고 두지 않는다.

Temporal subsampling은 stride convolution, 2-D convolution+projection, frame stacking+projection 등으로 encoder가 처리할 프레임 수를 줄이는 방법이다(p. 48). 긴 음성에서 이후 층의 연산량과 메모리를 줄이지만, 지나치면 짧은 음소나 가까운 반복을 구별할 시간 해상도도 잃는다. **CTC를 출력 목표로 쓰는 모델**이라면 축소 후 길이 $$T'$$가 최소한 $$T'\ge U+R$$을 만족해야 유효 경로가 남는다. 이 조건을 앞의 Conformer 원 논문 Transducer 실험에 그대로 적용해서는 안 된다.

Conformer 원 논문의 입력단은 이 일반 선택지 가운데 구체적인 한 구현이다. 25 ms 분석 창에서 10 ms 간격으로 얻은 80채널 filterbank feature를 **3×3 CNN 두 층, 각 층의 시간 stride 2**에 통과시켜 시간축을 대략 4배 줄인다. 그래서 encoder 블록에 들어가는 출력 간격은 약 **40 ms**다. 여기서 40 ms는 새 프레임의 **간격**이지 40 ms 길이의 분석 창을 뜻하지 않는다. Padding 등에 따라 실제 출력 프레임 수의 반올림 방식은 달라질 수 있다. 축소 결과는 선형 투영과 dropout을 거쳐 여러 Conformer 블록으로 들어간다.

이 **입력단 subsampling CNN**과 블록 안의 **1D depthwise convolution**은 위치와 목적이 다르다. 앞의 것은 시간축 길이를 줄이고, 뒤의 것은 이미 줄어든 시퀀스에서 국소 음향 패턴을 모델링한다. 강의 p. 48은 일반적인 축소 방식을 비교하고, p. 43은 Conformer의 10 ms → 40 ms 입력 흐름을 보여 준다.

## 7. 언어 모델을 언제 결합하는가

CTC 출력은 음향 증거에 강하지만 문장 맥락의 제약을 직접 모델링하지 않는다. p. 49는 `let's go two/to/too a movie`에서 음향 점수만으로는 `two`가 높아도 언어 모델이 `to`에 더 높은 문장 점수를 줄 수 있음을 보여 준다. 문맥이 후보를 **바꿀 수 있다**는 예이지, 슬라이드의 서로 다른 모델 점수 0.21과 0.6을 그대로 비교하라는 뜻은 아니다.

**작성자 보충 — 결합 점수.** 후보 문장 $$y$$의 CTC와 외부 언어 모델 점수를 비교 가능한 로그 영역으로 옮겨, 검증 집합에서 조정한 가중치 $$\lambda$$와 길이 보정 $$\beta$$를 쓸 수 있다.

$$
\operatorname{score}(y)=\log P_{\mathrm{CTC}}(y\mid X)+\lambda\log P_{\mathrm{LM}}(y)+\beta\,\lvert y\rvert
$$

여기서 $$\lambda,\beta$$는 무차원 하이퍼파라미터이고 $$\lvert y\rvert$$는 보정 단위로 정한 token 수다. **이것은 원문 p. 49의 수치에서 유일하게 도출되는 식이 아니라, 실무적으로 쓰는 결합 방식의 한 예**다. $$\lambda$$를 과도하게 키우면 실제 음향 증거가 약한 그럴듯한 문장을 선택할 수 있으므로 평가 split에서 조정해야 한다.

- **Second-pass rescoring:** 먼저 ASR beam이 후보 N개를 만든 다음, 별도로 학습한 LM으로 이 후보들을 다시 순위화한다. LM이 보지 못한 후보를 새로 만들지는 못한다(pp. 50–51).
- **Shallow fusion:** Beam search 중 후보 prefix를 확장할 때마다 LM 점수를 함께 반영한다. 문맥이 후보 유지·제거 자체에 영향을 주지만, LM 평가를 여러 번 해야 한다(p. 51).

슬라이드 p. 51의 `large/light model (ASR)`는 어느 모듈의 크기를 지칭하는지 도식만으로 확정하기 어렵다. 여기서는 크기에 관한 권장 사항을 일반 법칙으로 옮기지 않고, **결합 시점과 후보 집합의 차이**만 설명한다.

## Source Check

| 원문 위치 | 확인 사항 | 이 글의 처리 |
|---|---|---|
| pp. 2, 4–6 | `SST`는 통상 `STT`; `D > S > I`는 평가식의 가중치가 아님 | 약어를 바로잡고 오류의 의미 영향은 조건부로 설명 |
| pp. 17–22 | 시간 index와 vocabulary index가 겹쳐 보이고, 반복 글자는 blank가 필요 | $$T,U,\mathcal V',\mathcal B$$를 분리해 정의 |
| p. 28 | 경로 확률 합에 `CTC Loss` 표기 | 합은 $$P_{\mathrm{CTC}}$$, 최소화할 loss는 $$-\log P_{\mathrm{CTC}}$$로 구분 |
| pp. 29–35 | 전이 조건·초기값과 누적 확률의 의미 설명이 부족 | Softmax 출력과 상태별 경로 합을 구분하고, 부분 경로의 확장·분배법칙·두 종료 상태를 직접 검산 |
| pp. 36–41 | `streamable`, greedy 및 beam 비교는 추가 조건이 필요 | 미래 문맥 조건, 정규화된 반례, prefix별 확률 병합을 명시 |
| p. 42 | `super human`을 모든 평가 집합으로 일반화할 수 없고 WSJ’92 Human 값은 5.03% | 슬라이드 이미지의 네 평가 행을 다시 대조해 표기 |
| pp. 43–48 | Conformer의 시간축 축소와 블록 내부 convolution은 별개 | 원 논문의 4배 입력 축소와 Transducer 사용을 구분 |
| pp. 46–47 | BPE의 빈도 계산, 학습·추론 구분과 OOV 조건은 슬라이드에 생략 | Sennrich 등의 원 논문과 공식 구현을 대조해 빈도 가중 병합, 고정 merge rank, 문자·byte 변형과 예외를 명시 |
| p. 51 | `large/light model (ASR)`의 지칭 대상이 불명확 | 규모 권장에 대한 단정 없이 두 결합 절차만 설명 |

이 해설은 강의 PDF 51쪽의 텍스트·도식·수식과 위 전이 예제를 대상으로 한다. 오디오 실험이나 모델 학습 결과를 제시하는 글은 아니다.

## 마지막 핵심 정리

ASR의 어려움은 오디오가 길고 텍스트가 짧다는 사실 자체보다 **정답 정렬을 모른 채 학습해야 한다**는 데 있다. CTC는 blank와 collapse 규칙으로 가능한 정렬을 정의한다. 각 경로에서는 프레임 확률을 곱하고, 같은 전사의 경로끼리는 더한다. Forward DP는 그 합을 중복 계산 없이 구하며, **정답 전사의 확률에 음의 로그를 취한 값이 CTC loss**다. 짧은 예제의 경로 합 $$0.444$$와 DP 종료 상태 합 $$0.396+0.048$$은 일치한다. 추론에서는 경로별 greedy보다 문장별 확률을 모으는 prefix beam search가 적합할 수 있으며, 외부 LM은 beam 도중 또는 후보 생성 후에 문맥 정보를 보탠다. Deep Speech 2는 recurrent encoder와 CTC의 조합이고, Conformer 원 논문은 국소 convolution과 전역 attention을 함께 쓰는 encoder에 Transducer decoder를 연결했다. 입력단 subsampling은 연산량과 시간 해상도를 동시에 바꾼다.

## Study Guide

먼저 WER 예제를 직접 정렬해 평가 단위를 익힌다. 이어 pp. 20–23의 반복 문자와 blank 경로를 손으로 접어 본다. 3.3절에서는 둘째 프레임의 `A` 칸에 `εA`와 `AA`를 넣어 0.24를 만든 뒤, 두 경로에 `B`를 붙여 마지막 칸에 전달되는 0.144를 계산한다. 나머지 두 전이를 더하면 마지막 `B`의 0.396, 끝 blank를 더하면 전사 확률 0.444가 나온다. 다음으로 pp. 33–35의 0.4143을 같은 recurrence로 재계산하면 forward DP의 세 전이와 loss의 부호가 분명해진다. p. 43의 입력 축소와 p. 44의 블록 내부 convolution을 구별하고, p. 51의 두 언어 모델 결합 도식에서 **LM을 언제 호출하는지** 표시하면 학습·추론·평가가 서로 섞이지 않는다.

## 복습 질문

<details markdown="block">
<summary>1. WER이 100%를 넘을 수 있는가?</summary>

답변: 가능하다. 분자는 치환·삭제·삽입의 총 횟수이고 분모는 정답 단어 수다. 예측에 불필요한 단어가 많이 삽입되면 분자가 분모보다 커진다. 정답 단어가 0개라면 WER은 정의되지 않으므로 별도 평가 규칙이 필요하다.

</details>

<details markdown="block">
<summary>2. CTC에서 blank를 먼저 없앤 뒤 연속 문자를 합치면 왜 안 되는가?</summary>

답변: 경로 `l ε l`의 blank를 먼저 없애면 `ll`이 되고, 그 다음 중복 병합으로 `l` 하나가 된다. CTC는 먼저 연속 중복을 병합해 `l ε l`을 유지하고, 그 다음 blank를 삭제해 `ll`을 얻는다.

</details>

<details markdown="block">
<summary>3. 목표가 `ab`인 슬라이드 예제에서 왜 마지막 두 상태를 더하는가?</summary>

답변: 확장열은 `ε,a,ε,b,ε`이다. 네 번째 프레임에 목표 `ab`를 완성하는 경로는 마지막 `b`에서 끝나거나 뒤따르는 blank에서 끝난다. 두 집합은 겹치지 않으므로 확률을 더해 `0.2835+0.1308=0.4143`을 얻는다.

각 칸은 현재 token 하나의 확률이 아니라, 그 상태까지 온 부분 경로들의 확률 곱을 모두 더한 값이다. 매 프레임에 허용된 이전 칸을 합하고 현재 token 확률을 곱하면 경로들을 정확히 한 프레임 연장한다. 이 과정을 네 프레임에 적용한 결과가 0.4143이며, 값을 반복해 0.4143으로 수렴시키는 것은 아니다.

</details>

<details markdown="block">
<summary>4. CTC를 쓰면 모든 ASR 모델이 스트리밍으로 동작하는가?</summary>

답변: 아니다. CTC는 프레임별 출력에 적용할 수 있지만 encoder가 양방향 문맥이나 미래 프레임을 요구하면 해당 출력은 아직 계산할 수 없다. 실제 지연 시간은 encoder의 look-ahead, subsampling, decoder 구현에 따라 달라진다.

</details>

<details markdown="block">
<summary>5. Second-pass rescoring과 shallow fusion은 무엇이 다른가?</summary>

답변: Rescoring은 ASR이 만든 후보 목록이 고정된 뒤 LM이 순위를 바꾼다. Shallow fusion은 beam search가 진행되는 동안 LM 점수를 합쳐 어떤 후보를 다음 시각까지 남길지도 바꾼다. 두 방식 모두 음향 점수와 LM 점수의 상대 가중치를 검증해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-03.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture3.pdf — Automatic Speech Recognition I (51 slides)</a></li>
</ul>

## References

<ul>
  <li><a href="https://www.cs.toronto.edu/~graves/icml_2006.pdf" target="_blank" rel="noopener">Graves et al., Connectionist Temporal Classification (ICML 2006)</a> — CTC 경로 합과 forward–backward 학습의 원 논문.</li>
  <li><a href="https://arxiv.org/pdf/1408.2873" target="_blank" rel="noopener">Hannun et al., First-Pass Large Vocabulary Continuous Speech Recognition using Bi-Directional Recurrent DNNs (2014)</a> — CTC prefix beam에서 blank/non-blank 종료 확률을 분리하는 절차.</li>
  <li><a href="https://proceedings.mlr.press/v48/amodei16.pdf" target="_blank" rel="noopener">Amodei et al., Deep Speech 2 (ICML 2016)</a> — convolution·recurrent encoder, CTC 학습, LM beam decoding.</li>
  <li><a href="https://www.interspeech2020.org/uploadfile/pdf/Thu-3-10-9.pdf" target="_blank" rel="noopener">Gulati et al., Conformer (Interspeech 2020)</a> — encoder 블록, 입력단 4배 subsampling, Transducer 실험.</li>
  <li><a href="https://arxiv.org/abs/1508.07909" target="_blank" rel="noopener">Sennrich, Haddow, and Birch, Neural Machine Translation of Rare Words with Subword Units (ACL 2016)</a> — 문자 기반 BPE의 빈도 가중 병합, 단어 경계, 추론 시 학습된 병합 적용과 OOV 조건.</li>
  <li><a href="https://github.com/rsennrich/subword-nmt" target="_blank" rel="noopener">Sennrich et al., subword-nmt official implementation</a> — 학습한 code를 재사용하는 절차와 문자 BPE·byte-level BPE 구현 차이.</li>
</ul>
