---
layout: default
date: 2026-09-29 15:23:36 +0900
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

앞선 [Digital Signal Processing I](/study/speech-and-audio-recognition/lecture-02-sound-and-digital-audio/)와 [Spectral Analysis Lab](/study/speech-and-audio-recognition/lecture-02-spectral-analysis-lab/)에서 파형을 표본과 spectral feature로 바꿨다. 이번 강의는 그 feature를 문자·단어열로 바꾸는 **automatic speech recognition(ASR)**의 첫 단계를 다룬다. 아래의 슬라이드 번호는 PDF의 물리적 페이지 번호다. 수식의 완전한 유도와 조건, 수치 검산, 원문 표현의 정정은 원본 설명과 구분해 작성자가 보충했다.

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

Connectionist Temporal Classification(CTC)은 token 집합에 별도 기호 **blank** $$\epsilon$$을 추가한다. 이 기호는 공백 문자(space)도 단어 경계도 아니며, 해당 프레임에서 출력 문자 하나를 확정하지 않는 CTC 경로 기호다. 출력 경로 $$\pi=(\pi_1,\ldots,\pi_T)$$를 문장으로 바꾸는 함수 $$\mathcal B$$는 **먼저 연속 중복을 합치고, 다음에 blank를 삭제**한다(pp. 21–22). 순서를 바꾸면 결과가 달라진다.

```text
h h e l l ε l o  →  h e l ε l o  →  hello
l ε l          →  l ε l        →  ll
l l            →  l            →  l
```

따라서 같은 글자 `ll`을 내보내려면 둘 사이에 blank가 필요하다. 프레임 출력 길이 $$T$$는 단순히 $$U$$ 이상이어야 할 뿐 아니라, 정답의 **인접한 동일 token 쌍 수**를 $$R$$이라 하면 최소 $$T\ge U+R$$이어야 유효 CTC 경로가 존재한다. 이는 collapse 규칙에서 곧장 따라오는 필요조건이다.

### 3.1 경로 합과 loss의 차이

정답 $$y$$를 만드는 경로는 하나가 아니다(pp. 23–28). Encoder 출력이 주어졌을 때 CTC는 시간별 token 선택이 조건부 독립이라고 가정하여 한 경로의 확률을 곱하고, 같은 문장으로 접히는 경로를 모두 더한다.

$$
P_{\mathrm{CTC}}(y\mid X)=\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid X)
$$

이 값은 **정답 문장의 확률**이다. 최대로 만들려는 학습 목적과 최소화할 **loss**는 다음처럼 부호와 로그가 다르다.

$$
\mathcal L_{\mathrm{CTC}}(X,y)=-\log P_{\mathrm{CTC}}(y\mid X)
$$

슬라이드 p. 28은 경로 확률을 더하는 대목에 `CTC Loss`라고 쓰지만, 합 자체를 loss로 최소화하면 방향이 반대다. 이는 슬라이드 설명을 보완한 정정이다. 조건부 독립은 $$X$$가 주어졌을 때의 출력 경로에 대한 모델 가정이며, encoder가 음향 문맥을 전혀 이용하지 않는다는 뜻은 아니다.

### 3.2 왜 forward dynamic programming이 필요한가

유효한 정렬 경로를 전부 나열하면 프레임 수와 함께 가능한 조합이 빠르게 늘어난다. CTC는 목표열 사이에 blank를 끼워 넣은 확장열을 만든다(p. 30).

$$
z=(\epsilon,y_1,\epsilon,y_2,\ldots,\epsilon,y_U,\epsilon),\qquad S=2U+1
$$

$$z_s$$는 확장열의 $$s$$번째 기호다. $$\alpha_{t,s}$$를 **시각 $$t$$에 $$z_s$$ 상태로 끝나는 모든 유효 경로의 확률 합**으로 정의한다. 마지막 프레임에 그 상태로 오는 방법은 같은 상태에 머물기, 한 상태 전진하기, 조건부로 두 상태 건너뛰기뿐이므로 앞부분의 합을 재사용할 수 있다. 다음은 pp. 29–32의 그림을 1-based index로 명시한 **작성자 유도**다.

$$
\alpha_{t,s}=p_t(z_s\mid X)\left[\alpha_{t-1,s}+\alpha_{t-1,s-1}+\mathbf{1}[s\ge 3,\ z_s\ne\epsilon,\ z_s\ne z_{s-2}]\alpha_{t-1,s-2}\right]
$$

유효 범위 밖의 $$\alpha$$는 0으로 둔다. 처음에는 $$\alpha_{1,1}=p_1(\epsilon\mid X)$$, $$\alpha_{1,2}=p_1(y_1\mid X)$$이고 나머지는 0이다. 두 칸 건너뛰기는 도착 기호가 blank가 아니고 두 칸 앞의 기호와 다를 때만 허용한다. 이 조건이 없다면 `ll`을 blank 없이 한 글자로 잘못 합치거나, 불필요한 blank 상태를 뛰어넘는 경로를 허용한다. 끝에서는 마지막 label 상태와 마지막 blank 상태를 합한다.

$$
P_{\mathrm{CTC}}(y\mid X)=\alpha_{T,S-1}+\alpha_{T,S}
$$

이 유도는 유효 경로가 마지막 시각에 두 상태 중 하나에서만 종료되고, 각 종료 상태의 바로 전 전이가 위 세 경우로 완전히 분할된다는 사실에 기초한다. 상태 $$S=2U+1$$개와 시각 $$T$$개를 한 번씩 계산하므로 시간 복잡도는 $$O(TU)$$다. 실제 구현은 매우 작은 확률의 곱에서 수치 underflow가 생기지 않게 log-domain 또는 scaling을 쓴다.

### 3.3 슬라이드 예제의 수치 검산

pp. 33–35는 목표 `ab`, 확장열 $$(\epsilon,a,\epsilon,b,\epsilon)$$, 네 프레임을 사용한다. 각 열의 세 확률은 1로 합해진다.

| Token | $$t=1$$ | $$t=2$$ | $$t=3$$ | $$t=4$$ |
|---|---:|---:|---:|---:|
| $$\epsilon$$ | 0.6 | 0.2 | 0.3 | 0.4 |
| $$a$$ | 0.3 | 0.5 | 0.2 | 0.1 |
| $$b$$ | 0.1 | 0.3 | 0.5 | 0.5 |

예를 들어 둘째 프레임의 $$a$$ 상태는 시작 blank 또는 시작 $$a$$에서 도달한다. 따라서 $$\alpha_{2,2}=(0.6+0.3)\times0.5=0.45$$다. 마지막 프레임의 $$b$$ 상태에는 머물기·한 칸 전진·두 칸 건너뛰기가 모두 가능하다.

$$
\alpha_{4,4}=(0.300+0.153+0.114)\times0.5=0.2835
$$

마지막 blank 상태는 $$\alpha_{4,5}=(0.300+0.027)\times0.4=0.1308$$이다. 두 종료 상태를 더하면 **$$P_{\mathrm{CTC}}(ab\mid X)=0.4143$$**으로 슬라이드 p. 35의 결과와 일치한다. 이 검산은 원문 표의 전이가 수식과 같은지 확인하는 것이며 일반 데이터에서의 모델 성능을 뜻하지 않는다.

## 4. CTC decoding: 프레임 경로와 문장 확률은 다르다

Greedy decoding은 매 프레임 가장 큰 확률의 token 하나씩을 택한 뒤 $$\mathcal B$$를 적용한다. 빠르지만 $$\mathcal B(\arg\max_\pi P(\pi\mid X))$$가 반드시 $$\arg\max_y P_{\mathrm{CTC}}(y\mid X)$$는 아니다(pp. 36–38). 서로 다른 경로 여럿이 같은 문장에 확률을 보탤 수 있기 때문이다.

**작성자 보충 — 정규화된 반례.** 두 프레임 모두 $$(p(\epsilon),p(a),p(b))=(0.5,0.4,0.1)$$이라고 하자. 가장 높은 개별 경로는 $$(\epsilon,\epsilon)$$이고 그 확률은 0.25라서 greedy 결과는 빈 문자열이다. 그러나 `a`를 만드는 경로 $$(a,a),(a,\epsilon),(\epsilon,a)$$의 합은 $$0.16+0.20+0.20=0.56$$이다. 경로 최빈값과 문장 최빈값이 실제로 다르다. 슬라이드 p. 37의 수치는 개념도용 부분 예시여서 완전한 정규화 분포로 읽지 않았다.

Beam search는 시각마다 후보 prefix를 확장하고, 같은 출력으로 접히는 경로의 점수를 합친 뒤, beam size만큼 후보를 남긴다(pp. 38–41). Beam size 1은 보통 greedy에 가깝고, 넓힐수록 좋은 후보를 더 보존하지만 메모리·계산 비용이 늘어난다. **유한 beam은 근사**이고, 전체 경로 합을 정확하게 계산한다고 해서 acoustic model의 인식 결과가 항상 정답이 되는 것도 아니다.

슬라이드는 CTC가 streamable하다고 요약한다(p. 36). 다만 **실시간 처리 가능 여부는 encoder와 decoder가 미래 프레임을 요구하는지에 달려 있다.** 양방향 encoder나 긴 look-ahead를 쓰면 CTC loss를 사용하더라도 전체 발화를 기다려야 할 수 있다. CTC trellis의 높은 확률 경로는 학습 중 명시 정렬 없이 얻는 *추정 정렬*이지, 사람이 확정한 음소 경계가 아니다.

## 5. Encoder: Deep Speech 2와 Conformer

강의 p. 42의 Deep Speech 2 도식은 spectrogram → convolution → bidirectional recurrent layers → CTC 출력이라는 흐름을 보여 준다. 원문은 학습 자료 약 11,900시간, 약 3,500만 parameter, 16 GPU에서 3–5일의 학습을 소개한다. 이 수치는 **원 논문의 특정 시스템과 당시 조건**의 값으로, 오늘날 ASR의 보편적 요구량이 아니다. 같은 슬라이드의 WER 비교는 다음과 같다.

| Evaluation set | Deep Speech 1 | Deep Speech 2 | Human |
|---|---:|---:|---:|
| WSJ’92 | 4.94% | 3.60% | 5.00% |
| WSJ’93 | 6.94% | 4.98% | 8.08% |
| LibriSpeech test-clean | 7.89% | 5.33% | 5.83% |
| LibriSpeech test-other | 21.74% | 13.25% | 12.69% |

이 표에서는 DS2가 첫 세 평가 조건의 표시된 human WER보다 낮지만, `test-other`에서는 높다. 따라서 p. 42의 `super human quality on clean sets`를 모든 음성 조건에서 인간보다 우수하다는 주장으로 확대하지 않는다. 위 수치는 **강의 슬라이드 표의 전사**이며 재현 실험 결과는 아니다.

Conformer는 convolution의 지역 패턴 처리와 self-attention의 넓은 문맥 처리를 결합한다(pp. 43–45). 그림의 한 block은 half-step feed-forward → multi-head self-attention → convolution module → half-step feed-forward 순으로 잔차 연결을 사용한다. Convolution module 안에는 pointwise convolution, GLU, 1-D depthwise convolution, batch normalization, Swish, 또 하나의 pointwise convolution이 있다. **Depthwise**는 채널마다 시간 방향 filter를 적용하고, **pointwise**는 채널을 섞는다. 1-D kernel 폭 $$K$$, 입력 채널 $$C_{\mathrm{in}}$$, 출력 채널 $$C_{\mathrm{out}}$$라면 bias를 제외한 parameter 수는 일반 convolution에서 $$K C_{\mathrm{in}}C_{\mathrm{out}}$$, depthwise+pointwise에서 $$K C_{\mathrm{in}}+C_{\mathrm{in}}C_{\mathrm{out}}$$다. 이 비교는 구조상 정확한 count이며 실제 속도 개선 폭은 구현·하드웨어에 따라 다르다.

## 6. Subword tokenization과 시간 축 축소

글자 단위로 길고 반복된 정답을 내면 CTC의 유효 경로가 적어지거나, encoder 시간축이 지나치게 짧을 때 경로가 아예 없어질 수 있다. Subword는 빈번한 문자 묶음을 하나의 token으로 만들므로 목표 token 수를 줄이고 문맥 있는 단위를 표현할 수 있다(p. 46). 다만 subword가 언제나 정확도를 올린다는 뜻은 아니다. 어휘 크기, 언어, 학습 데이터, decoder에 따라 결과가 달라진다.

슬라이드 p. 47의 Byte Pair Encoding(BPE)은 문자 vocabulary에서 시작해 **가장 빈번한 인접 token 쌍**을 새 token으로 합치는 과정을 목표 vocabulary 크기에 도달할 때까지 반복한다. 자료의 `aaabdaaabac` 예시는 `aa → Z`, `ab → Y`, `ZY → X`를 순서대로 적용하여 `ZabdZabac → ZYdZYac → XdXac`로 압축한다. `low/lowest/newer` 그림도 `lo`를 새 token으로 만드는 예다. WordPiece와 Unigram은 함께 열거되지만(pp. 46–47), **동일한 병합 규칙의 다른 이름이 아니다.** 이 슬라이드는 둘의 학습 목적식까지 설명하지 않으므로 여기서 BPE와 동치라고 두지 않는다.

Temporal subsampling은 stride convolution, 2-D convolution+projection, frame stacking+projection으로 encoder 프레임 수를 줄이는 방법이다(p. 48). 예컨대 stride가 시간을 두 배 줄이면 이후 층의 시간축 연산은 줄지만, **CTC 출력 길이 $$T'$$가 목표 token 수와 반복 token의 최소 조건 $$T'\ge U+R$$을 만족해야 한다.** `10 ms`, `20 ms`, `40 ms`가 표시된 원문 그림은 가능한 시간 해상도의 개념도이지 모든 모델의 고정 축소율을 뜻하지 않는다. 지나친 subsampling은 짧은 음소와 반복 token을 구별할 여지를 없앨 수 있다.

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
| pp. 29–35 | 전이 조건·초기값의 텍스트 설명이 부족 | 확장열, skip 조건, 양쪽 종료 상태, 예제 0.4143을 검산 |
| pp. 36–38 | `streamable`, greedy 비교는 추가 조건이 필요 | 미래 문맥 조건과 정규화된 반례를 명시 |
| p. 42 | `super human`을 모든 평가 집합으로 일반화할 수 없음 | 슬라이드의 네 평가 행을 같은 표에서 비교 |
| p. 51 | `large/light model (ASR)`의 지칭 대상이 불명확 | 규모 권장에 대한 단정 없이 두 결합 절차만 설명 |

이 해설은 강의 PDF 51쪽의 텍스트·도식·수식과 위 전이 예제를 대상으로 한다. 오디오 실험이나 모델 학습 결과를 제시하는 글은 아니다.

## 시험 포인트

1. WER의 $$S,D,I,N$$을 설명하고, 예측 문장과 정답 문장을 최소 편집으로 정렬할 수 있어야 한다.
2. CTC의 blank가 왜 필요한지, **중복 병합 후 blank 삭제** 순서로 `ll` 같은 반복 글자를 직접 decode할 수 있어야 한다.
3. `가장 높은 경로`와 `가장 높은 문장`을 구분하고 greedy보다 beam search가 필요한 이유를 설명할 수 있어야 한다.
4. 확장열의 forward 상태, skip 조건, 두 종료 상태의 합을 사용해 짧은 CTC 예제를 계산할 수 있어야 한다.
5. Conformer의 attention/conv 역할과 rescoring/shallow fusion의 LM 적용 시점을 비교할 수 있어야 한다.

## 마지막 핵심 정리

ASR의 어려움은 오디오가 길고 텍스트가 짧다는 사실 자체보다 **정답 정렬을 모른 채 학습해야 한다**는 데 있다. CTC는 blank와 collapse 규칙으로 가능한 정렬을 정의하고, forward DP로 그 확률을 효율적으로 합한다. 이 확률의 negative log가 학습 loss다. 추론에서는 경로별 greedy보다 문장별 확률을 모으는 beam search가 적합할 수 있으며, 외부 LM은 beam 도중 또는 후보 생성 후에 문맥 정보를 보탠다. Encoder 구조와 subsampling은 연산량을 바꾸지만 시간축의 정보와 CTC의 유효 경로 조건을 함께 지켜야 한다.

## Study Guide

먼저 WER 예제를 직접 정렬해 보며 평가 단위를 익힌다. 이어 pp. 20–22의 반복 문자 문제를 손으로 decode하고, p. 30의 확장열에서 `stay/advance/skip` 세 전이를 추적한다. 마지막으로 pp. 33–35의 0.4143을 직접 재계산한 뒤, p. 51의 두 언어 모델 결합 도식에서 **LM을 언제 호출하는지** 표시하면 학습·추론·평가가 서로 섞이지 않는다.

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
  <li><a href="https://arxiv.org/abs/1512.02595" target="_blank" rel="noopener">Amodei et al., Deep Speech 2 (2015/2016)</a> — 강의의 encoder·평가 사례와 관련된 원 논문.</li>
  <li><a href="https://arxiv.org/abs/2005.08100" target="_blank" rel="noopener">Gulati et al., Conformer (Interspeech 2020)</a> — attention과 convolution 결합 구조의 원 논문.</li>
</ul>
