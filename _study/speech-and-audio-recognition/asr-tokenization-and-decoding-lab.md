---
layout: default
date: 2026-10-07 10:55:22 +0900
title: "Speech and Audio Recognition: Tokenization and Decoding Lab"
course: "Speech and Audio Recognition"
topic: "BPE, CTC Decoding, and RNN-T Inference"
order: 7
major_topic: "Speech and Audio Processing"
keywords:
  - "Byte Pair Encoding"
  - "Subword Tokenization"
  - "Connectionist Temporal Classification"
  - "Prefix Beam Search"
  - "Shallow Fusion"
  - "Rescoring"
  - "RNN-Transducer"
  - "TorchAudio"
---

# Speech and Audio Recognition: Tokenization and Decoding Lab

Source Notebooks:

- `01_bpe_basics.ipynb`
- `02_ctc_inference.ipynb`
- `03_rnnt_inference.ipynb`

> **핵심:** BPE는 자주 함께 등장하는 기호를 학습된 순서대로 묶어 출력 길이 $$U$$를 줄이는 **tokenization 규칙**이다. CTC는 프레임마다 독립적으로 보이는 경로들을 collapse하고 같은 문자열의 확률을 합쳐 **입력 시간 $$T$$와 출력 길이 $$U$$가 다른 문제**를 푼다. RNN-T는 음향 위치 $$t$$와 출력 위치 $$u$$를 분리하고, blank에서는 시간만 진행하며 일반 token에서는 Predictor 상태만 갱신한다. 세 실습을 연결하면 “어떤 단위로 문장을 표현할 것인가”와 “그 단위를 어떤 경로로 생성할 것인가”가 서로 다른 설계 문제임을 확인할 수 있다.

이 글의 수치는 세 notebook에 저장된 실행 결과를 우선 사용한다. 저장된 전체 CTC·RNN-T 추론은 다시 실행하지 않았으며, 별도로 실행한 것은 BPE 함수와 작은 CTC/RNN-T 합성 검산뿐이다. 따라서 아래에서 **저장 출력**, **새 합성 검산**, **공식 소스 확인**을 구분한다.

## 전체 흐름

| 단계 | 입력과 출력 | 핵심 질문 |
|---|---|---|
| BPE 학습 | 단어 빈도표 → merge 규칙·어휘 | 빈번한 문자 조합을 어떻게 재현 가능하게 subword로 묶는가? |
| BPE 추론 | 새 문장 → token ID열 | 학습한 merge를 다시 학습하지 않고 어떻게 적용하는가? |
| CTC Greedy | 프레임별 확률 $$[T,V]$$ → 문자열 | 반복과 blank를 어떤 순서로 제거해야 하는가? |
| CTC Prefix Beam | 같은 확률표 → prefix 후보 | 같은 문자열로 접히는 여러 경로의 질량을 어떻게 합치는가? |
| LM 결합 | CTC 점수·LM 점수 → 후보 순위 | 탐색 중 결합과 사후 재정렬은 무엇이 다른가? |
| RNN-T Greedy | Encoder $$f_t$$·Predictor $$g_u$$ → token열 | blank와 일반 token이 $$t,u$$를 어떻게 다르게 움직이는가? |

### 기호, shape와 단위

| 기호 | 의미 | 단위·shape |
|---|---|---|
| $$T,t$$ | Encoder 출력 길이와 위치 | 무차원 정수; 원 파형 sample index와 다름 |
| $$U,u$$ | 출력 token 수와 현재 출력 위치 | 무차원 정수 |
| $$V$$ | 출력 어휘 또는 class 수 | 무차원 정수 |
| $$p_t(k)$$ | CTC frame $$t$$에서 class $$k$$의 확률 | 무차원, 각 frame에서 합이 1 |
| $$p_b(\ell),p_{nb}(\ell)$$ | prefix $$\ell$$이 blank/non-blank로 끝나는 경로의 확률 합 | 무차원 |
| $$f_t$$ | RNN-T Encoder의 음향 표현 | 이 checkpoint에서 1024차원 |
| $$g_u$$ | RNN-T Predictor의 출력 이력 표현 | 모델 내부 vector |
| $$z_{t,u}$$ | Joiner가 만든 class logit | 이 checkpoint에서 마지막 축 4097 |
| `▁` | BPE/SentencePiece의 단어 시작 표지 | 출력 문자와 구분되는 경계 기호 |

## 1. BPE: 문자에서 subword로

### 1.1 왜 단어 빈도를 pair count에 곱하는가

Notebook 01은 각 단어를 `['▁'] + list(word)`로 초기화한다. `▁`를 별도 token으로 두면 `low`의 끝과 다음 단어 `new`의 시작이 합쳐지는 일을 막고, 단어 시작에서 자주 나타나는 조합도 `▁ne`, `▁wide`처럼 학습할 수 있다.

Corpus는 단어 종류의 목록이 아니라 출현 횟수를 가진 빈도표다. 단어 $$w$$의 현재 token열을 $$s_w$$, 빈도를 $$c(w)$$라 하면 인접 pair $$q$$의 count는 다음과 같다.

$$
C(q)=\sum_w c(w)\sum_{i=1}^{\lvert s_w\rvert-1}\mathbf 1[(s_{w,i},s_{w,i+1})=q].
$$

이 식은 이 notebook이 사용하는 **pair-frequency 정의**다. 예를 들어 `newer`가 6회 등장하면 그 안의 각 인접 pair는 1이 아니라 6을 기여한다. 빈도를 무시하면 드물게 등장한 단어와 많이 등장한 단어가 같은 영향력을 갖게 되어 많이 쓰이는 pair의 통계가 왜곡된다. 이 Greedy 선택이 전체 merge 예산에서 token 수를 전역 최적화한다는 뜻은 아니다. 또한 `aaa`의 `(a,a)`처럼 후보 pair가 겹치면 count는 2여도 왼쪽부터 겹치지 않게 적용한 실제 감소량은 1일 수 있다.

코드는 최대 count만 고른 뒤, 동률이면 pair tuple의 사전순으로 결정한다.

```python
pair = min(counts, key=lambda p: (-counts[p], p))
```

`Counter.most_common(1)`의 내부 순서에 기대지 않고 count의 내림차순과 pair의 오름차순을 명시했기 때문에 같은 입력에서 merge 순서가 결정적이다. 새 합성 검산에서 `{'ab': 2, 'ac': 2}`는 `('▁', 'a')`를 첫 규칙으로 골랐다. `aaa`에 `(a,a)`를 적용할 때는 왼쪽부터 겹치지 않게 병합해 `aa | a`가 되며, 한 번의 단계에서 겹치는 두 `aa`를 동시에 만들지 않는다.

### 1.2 저장된 merge 이력 읽기

초기 어휘는 `▁`와 corpus에 등장한 문자 10개를 합친 $$V=11$$이다. 모든 단어의 `▁`까지 빈도로 가중한 초기 token 수는 149개다. 저장 출력의 첫 12회 merge는 다음 흐름을 보인다.

| 단계 | 선택 pair | 가중 count | 새 token | $$V$$ | 가중 corpus token 수 |
|---:|---|---:|---|---:|---:|
| 1 | `w + e` | 12 | `we` | 12 | 137 |
| 2 | `n + e` | 11 | `ne` | 13 | 126 |
| 3 | `▁ + ne` | 11 | `▁ne` | 14 | 115 |
| 4 | `l + o` | 9 | `lo` | 15 | 106 |
| 5 | `▁ + lo` | 9 | `▁lo` | 16 | 97 |
| 6 | `we + r` | 8 | `wer` | 17 | 89 |
| 7–10 | `d+e`, `i+de`, `w+ide`, `▁+wide` | 7씩 | `de`, `ide`, `wide`, `▁wide` | 21 | 61 |
| 11 | `s + t` | 6 | `st` | 22 | 55 |
| 12 | `▁ne + wer` | 6 | `▁newer` | 23 | 49 |

첫 단계의 `we`는 corpus 전체에서 가중 12회 등장하고 서로 겹치지 않으므로 token 수를 149에서 137로 정확히 12 줄인다. 이 corpus의 표시된 merge들은 count만큼 실제 감소했지만, 자기 자신과 겹칠 수 있는 일반 pair에서는 count와 한 단계의 감소량이 다를 수 있다.

![Merge 횟수가 늘수록 어휘 크기 V는 증가하고 예제 문장의 token 수 U는 감소하는 두 선 그래프]({{ "/assets/images/study/speech-asr-lab/bpe-vocabulary-and-token-count.png" | relative_url }})

저장된 그래프에서 merge 예산이 0, 4, 8, 12, 20으로 늘 때 $$V$$는 11, 15, 19, 23, 31로 증가하고, 문장 `newer lower widest`의 $$U$$는 19, 14, 9, 5, 3으로 감소한다. 이 감소는 **이 예제 문장과 이 corpus에 대한 결과**다. Merge를 늘리면 어휘 table과 embedding/output layer는 커질 수 있고, 다른 문장의 길이가 같은 비율로 줄어든다는 보장은 없다.

### 1.3 추론에서는 merge를 다시 세지 않는다

학습이 끝난 뒤 `encode_bpe`는 새 문장의 pair 빈도를 계산하지 않는다. 각 단어를 다시 문자로 나눈 다음, 저장된 merge를 학습 순서대로 한 번씩 적용한다. 12회 merge에서 저장된 결과는 다음과 같다.

```text
Text   : newer lower widest
Tokens : ▁newer | ▁lo | wer | ▁wide | st
IDs    : 22 | 15 | 16 | 20 | 21
Decode : newer lower widest
```

Token ID는 이 `vocab` list 안의 위치일 뿐이다. 다른 tokenizer가 우연히 $$V=23$$이어도 ID 22가 `▁newer`라는 보장은 없다. 모델의 embedding과 output class 순서는 tokenizer 파일과 함께 고정되어야 한다.

학습하지 않은 **단어**와 **문자**도 구분해야 한다. 새 단어라도 모든 문자가 초기 문자 집합에 있으면 학습된 subword와 문자 조합으로 표현할 수 있다. 반면 학습 문자 집합에 없는 문자는 이 교육용 구현에 `<unk>`나 byte fallback이 없으므로 `ValueError`가 난다. 새 합성 검산에서도 `ab`만 학습한 tokenizer에 `az`를 넣으면 이 경계가 확인됐다.

## 2. CTC: frame path를 문자열로 접기

### 2.1 Collapse 순서는 왜 반복 병합 다음 blank 제거인가

CTC 경로 $$\pi=(\pi_1,\ldots,\pi_T)$$를 문자열로 바꾸는 함수 $$\mathcal B$$는 먼저 **인접한 동일 class를 하나로 병합**하고, 그 다음 blank를 제거한다. 순서를 바꾸면 `a blank a`가 `aa`가 아니라 `a`로 잘못 접힌다.

Notebook의 합성 확률표에서 frame별 argmax는 다음과 같다.

```text
a, a, blank, a, b, b
```

반복을 먼저 합치면 `a, blank, a, b`, blank를 제거하면 최종 문자열은 `aab`다. 선택된 여섯 frame의 확률은 0.8 다섯 개와 0.85 하나다. 이를 곱하면 이 단일 best path의 확률이 나온다.

$$
\begin{aligned}
P(\pi\mid X)&=0.8^5\times0.85\\
&=0.278528.
\end{aligned}
$$

그러나 문자열 `aab`의 CTC 확률은 이 경로 하나가 아니라 `aab`로 collapse되는 **모든 경로의 확률 합**이다.

$$
P_{\mathrm{CTC}}(y\mid x)=\sum_{\pi:\mathcal B(\pi)=y}\prod_{t=1}^{T}p_t(\pi_t\mid x).
$$

이 식은 CTC 모델이 정의하는 정확한 marginal이다. Beam pruning을 적용한 구현에서는 일부 prefix가 중간에 제거되므로 계산된 값이 근사가 된다.

### 2.2 같은 sample의 실제 저장 출력

Notebook은 SRI International과 Lab41이 공개한 VOiCES corpus의 `Lab41-SRI-VOiCES-src-sp0307-ch127535-sg0042.wav` 16 kHz 영어 sample을 사용한다. 이 파일은 PyTorch의 tutorial-assets에서 배포되며, VOiCES 공식 README가 밝힌 라이선스는 <a href="https://creativecommons.org/licenses/by/4.0/" target="_blank" rel="noopener">CC BY 4.0</a>이다. 저장 출력의 선택 구간은 약 3.40초다. 파형은 먼저 stereo channel 평균으로 mono화하고, 선택한 시작점부터 최대 12초를 자른 뒤 16 kHz가 아니면 resample한다.

![CTC notebook에서 사용한 3.40초 음성의 시간축 파형]({{ "/assets/images/study/speech-asr-lab/ctc-input-waveform.png" | relative_url }})

이 전처리의 이유는 다음과 같다.

- **Mono 평균:** bundle 입력을 한 channel 파형으로 맞춘다. 두 channel의 위상이 반대라면 단순 평균이 일부 성분을 상쇄할 수 있으므로 일반적인 다채널 beamforming을 대신하는 방법은 아니다.
- **구간 제한:** 긴 파일이 CPU Colab에서 지나치게 오래 걸리거나 큰 중간 tensor를 만들지 않게 한다. 0.5초 미만, NaN/inf, 완전 무음은 조기에 거부한다.
- **16 kHz resampling:** checkpoint가 학습된 시간 scale과 convolution stride를 맞춘다. Sample rate 숫자만 바꾸고 표본을 변환하지 않으면 발화 속도와 주파수축이 잘못 해석된다.
- **`eval()`·`torch.inference_mode()`:** dropout을 끄고 gradient graph를 만들지 않아 저장 추론을 재현 가능한 inference 경로로 제한한다.

`WAV2VEC2_ASR_BASE_960H`의 저장 출력 shape는 다음과 같다.

```text
logits: [B, T, V] = [1, 169, 29]
```

여기서 $$B=1$$, $$T=169$$는 Encoder 출력 frame 수, $$V=29$$는 blank `-`, 단어 경계 `|`, 영문 대문자와 apostrophe로 이루어진 class 수다. 원 파형은 약 54,400 samples지만 출력은 169 frame이므로, heatmap의 가로 index를 raw sample 또는 millisecond로 직접 읽으면 안 된다.

![169개 Encoder frame과 29개 CTC class의 확률 heatmap. 대부분의 frame에서 blank가 높고 문자 위치에 좁은 밝은 열이 나타난다]({{ "/assets/images/study/speech-asr-lab/ctc-frame-probabilities.png" | relative_url }})

Heatmap의 맨 아래 blank 행은 긴 구간에서 거의 1에 가깝다. 문자 행의 밝은 spike가 발화 구간에 드물게 나타나며, 같은 문자나 `|`가 연속 argmax가 되어도 collapse 뒤에는 하나만 남는다. 저장된 blank argmax 비율은 0.592였고 Greedy transcript는 다음과 같다.

```text
I HAD THAT CURIOSITY BESIDE ME AT THIS MOMENT
```

이 결과는 notebook에 저장된 TorchAudio 2.8 CPU 실행 결과다. 이번 글 작성 과정에서 360 MB checkpoint를 다시 내려받거나 전체 음성을 재추론하지 않았다.

### 2.3 Greedy best path와 best 문자열은 다를 수 있다

Greedy는 각 frame의 최대 class를 이어 가장 확률이 큰 **단일 경로**를 고른다. 하지만 문자열 확률은 같은 문자열로 접히는 경로의 합이므로 best path의 문자열이 가장 큰 marginal을 가질 필요는 없다.

새로 실행한 2-frame 합성 반례에서 각 frame의 확률을 `blank=0.6`, `a=0.4`로 두었다.

| 경로 | 경로 확률 | Collapse 결과 |
|---|---:|---|
| `blank, blank` | 0.36 | 빈 문자열 |
| `blank, a` | 0.24 | `a` |
| `a, blank` | 0.24 | `a` |
| `a, a` | 0.16 | `a` |

Greedy best path는 `blank, blank`이고 결과는 빈 문자열이지만, 문자열 `a`의 합산 확률은 $$0.24+0.24+0.16=0.64$$다. 이것이 path가 아니라 prefix별 확률 질량을 모아야 하는 직접적인 이유다.

## 3. Prefix Beam Search의 확률 장부

### 3.1 `pb`와 `pnb`를 분리하는 이유

Prefix $$\ell$$에 대해 두 질량을 둔다.

- $$p_b(\ell)$$: $$\ell$$로 collapse되고 현재 frame이 blank인 경로의 확률 합
- $$p_{nb}(\ell)$$: $$\ell$$로 collapse되고 현재 frame이 일반 token인 경로의 확률 합

이전 frame의 두 질량을 합친 값을 $$p_{tot}(\ell)=p_b(\ell)+p_{nb}(\ell)$$라 하자. 현재 blank 확률이 $$p_t(\epsilon)$$이면 prefix를 유지하는 blank 전이는

$$
p_b^{(t)}(\ell)\mathrel{+}=p_{tot}^{(t-1)}(\ell)p_t(\epsilon)
$$

이다. 일반 token $$c$$가 prefix의 마지막 token과 다르면

$$
p_{nb}^{(t)}(\ell c)\mathrel{+}=p_{tot}^{(t-1)}(\ell)p_t(c)
$$

로 확장한다. 반면 $$c$$가 마지막 token과 같으면 두 경우를 갈라야 한다.

$$
\begin{aligned}
p_{nb}^{(t)}(\ell)&\mathrel{+}=p_{nb}^{(t-1)}(\ell)p_t(c),\\
p_{nb}^{(t)}(\ell c)&\mathrel{+}=p_b^{(t-1)}(\ell)p_t(c).
\end{aligned}
$$

첫 줄은 `a → a`처럼 연속 반복이 collapse되어 같은 prefix에 머무는 경우다. 둘째 줄은 `a → blank → a`처럼 blank로 분리된 새 `a`를 추가하는 경우다. 하나의 총확률만 저장하면 “직전 경로가 blank였는가”를 잃어 두 전이를 구별할 수 없다.

Notebook은 underflow를 피하려고 이 계산을 log domain에서 수행하며, 합에는 `np.logaddexp`를 사용한다. 새 합성 검산에서는 $$T=3,V=3$$ 확률표의 27개 경로를 전부 열거해 얻은 9개 문자열 질량과 notebook 점화식을 비교했고, 오차 $$10^{-12}$$ 이내에서 모두 일치했다. 이 검산은 pruning이 없는 작은 경우의 알고리즘 확인이며 실제 169-frame 추론을 재실행한 것이 아니다.

### 3.2 Beam은 어디에서 근사가 되는가

각 frame에서 만들 수 있는 prefix를 전부 보존하면 위 점화식은 정확하지만 후보 수가 빠르게 증가한다. Notebook은 점수 상위 `beam_size`개만 남긴다. 한 번 제거된 prefix의 후속 경로는 다시 나타나지 않으므로 저장되는 `ctc_logp`는 일반적으로 근사값이다.

`beam_size=1`도 frame별 argmax Greedy와 항상 같지 않다. Greedy는 경로 하나를 고르는 반면 prefix beam은 같은 prefix의 `pb/pnb` 질량을 합한 뒤 하나를 남기기 때문이다. 두 방법의 “1개”가 가리키는 대상이 다르다.

## 4. 문자 bigram LM, Shallow Fusion과 Rescoring

### 4.1 결합 점수의 의미

Notebook의 작은 문자 bigram LM은 문장 의미를 이해하는 모델이 아니다. BOS에서 시작해 직전 문자만 조건으로 다음 문자 또는 EOS의 count를 세고 add-$$k$$ smoothing을 적용한다.

$$
P_{LM}(c\mid d)=\frac{N(d,c)+k}{N(d)+kM},\qquad k=0.5.
$$

여기서 $$M$$은 blank를 제외한 CTC 문자 수와 EOS 하나를 합친 outcome 수다. Blank는 문자열의 문자가 아니므로 LM에 입력하지 않는다. 최종 후보에만 EOS 확률을 한 번 더한다.

CTC와 LM의 결합 점수는

$$
S(y)=\log P_{CTC}(y\mid x)+\alpha\log P_{LM}(y)+\beta\lvert y\rvert
$$

이다. 이는 확률론적 posterior 그 자체라기보다 decoder의 **순위 점수**다. $$\alpha$$와 $$\beta$$는 validation data에서 조정하는 hyperparameter이며, 큰 $$\alpha$$가 항상 더 정확하지 않다.

합성 `CAT`/`COT` 예제에서 음향 분포만 보면 `COT`가 0.55로 `CAT`의 0.45보다 높다. 저장 출력은 다음을 보여 준다.

| $$\alpha$$ | 1위 | CTC logp | LM logp | 결합 점수 |
|---:|---|---:|---:|---:|
| 0 | `COT` | -0.597837 | -3.776728 | -0.597837 |
| 1 | `CAT` | -0.798508 | -0.407561 | -1.206069 |

`CAT`를 20회, `COT`를 1회 본 작은 LM 때문에 $$\alpha=1$$에서는 `CAT`가 올라온다. 이것은 LM이 음향 증거를 “수정했다”기보다 두 score의 상대 scale을 바꾼 결과다. Corpus가 test domain과 다르면 같은 작용이 오히려 오류를 만들 수 있다.

### 4.2 Shallow Fusion과 Rescoring의 탐색 범위

Shallow Fusion은 **각 frame에서 beam을 자르기 전** 결합 점수로 prefix를 순위화한다. 따라서 음향 점수만으로는 일찍 탈락할 prefix를 LM이 살릴 수 있다. Notebook은 prefix 전체 LM score를 cache하며, blank나 collapse되는 반복으로 prefix가 그대로이면 같은 LM score를 재사용한다. 동일 문자열의 blank 위치마다 LM 점수를 다시 더하지 않는다.

Rescoring은 먼저 음향 CTC beam으로 얻은 N-best를 고정한 뒤 같은 식으로 순서만 바꾼다. 후보 목록 밖의 문장을 새로 만들 수 없다. 저장된 실제 음성 결과에서는 Greedy, Prefix Beam, Prefix Beam+LM, Rescoring이 모두 다음 문장을 1위로 냈다.

```text
I HAD THAT CURIOSITY BESIDE ME AT THIS MOMENT
```

Prefix Beam+LM의 저장된 1위는 근사 CTC logp -0.167698, LM logp -132.995641, $$\alpha=0.3$$ 결합 점수 -40.066391이었다. 세 출력이 같다는 사실은 결합 코드가 작동하지 않았다는 뜻이 아니라, 이 sample과 이 beam 안에서는 기존 1위의 우위가 유지됐다는 뜻이다.

## 5. RNN-T: 두 축에서 움직이는 Greedy 경로

### 5.1 CTC와 다른 상태 전이

RNN-T는 음향 Encoder 표현 $$f_t$$와 이미 출력한 token열을 요약한 Predictor 표현 $$g_u$$를 Joiner에 넣는다.

$$
z_{t,u}=\operatorname{Join}(f_t,g_u),\qquad
p(k\mid t,u)=\operatorname{softmax}(z_{t,u})_k.
$$

Greedy는 한 격자점에서 가장 높은 class를 고른다.

- blank이면 $$(t,u)\to(t+1,u)$$: 다음 음향 위치로 가되 Predictor 상태는 유지한다.
- 일반 token이면 $$(t,u)\to(t,u+1)$$: 같은 음향 위치에서 token을 출력하고 Predictor 상태를 갱신한다.

![blank에서는 오른쪽으로, c a t token에서는 위로 이동하는 합성 RNN-T 경로]({{ "/assets/images/study/speech-asr-lab/rnnt-synthetic-path.png" | relative_url }})

합성 `cat` 경로는 $$(0,0)$$에서 blank, $$(1,0)$$에서 `c`, $$(1,1)$$에서 blank, $$(2,1)$$에서 `a`, $$(2,2)$$에서 `t`를 낸다. 같은 $$t=2$$에서 `a`, `t` 두 token을 연속 출력할 수 있는 이유는 첫 token 뒤에 $$g_u$$가 바뀌어 같은 $$f_t$$와 결합한 다음 분포가 달라지기 때문이다.

새 합성 검산에서도 한 음향 위치에서 `a`, `a`, blank를 차례로 선택하면 이동은 $$(0,0)\to(0,1)\to(0,2)\to(1,2)$$가 되고 출력은 `aa`였다. CTC의 반복 collapse를 적용하면 실제 출력 하나를 지우게 된다.

### 5.2 전용 tokenizer와 blank 4096

`EMFORMER_RNNT_BASE_LIBRISPEECH`는 자체 SentencePiece model을 사용한다. 저장 출력에서 일반 BPE piece 수는 4096개이고 유효 ID는 0–4095다. Joiner는 여기에 별도 blank class를 더해 4097개를 출력하며, 이 checkpoint의 blank ID가 4096이다.

```text
we are learning speech recognition
→ ▁we | ▁are | ▁lear | ning | ▁speech | ▁recogn | ition
→ 80 | 192 | 1204 | 680 | 2556 | 2084 | 565
```

4096을 SentencePiece의 일반 token처럼 decode하면 범위를 벗어난 class를 어휘에 넣는 셈이다. 공식 token processor는 RNN-T hypothesis 맨 앞의 seed token 하나를 제외한 뒤 일반 piece를 문자열로 바꾼다. Notebook의 `decode_emitted`가 `[BLANK] + emitted`를 전달하는 이유가 여기에 있다. **이 시작 방식과 blank 번호는 이 bundle에 종속적**이며 다른 RNN-T checkpoint에 그대로 일반화하면 안 된다.

### 5.3 특징 추출 shape와 실제 저장 경로

RNN-T notebook도 같은 3.40초 sample을 독립적으로 준비한다.

![RNN-T notebook에 저장된 입력 음성 파형]({{ "/assets/images/study/speech-asr-lab/rnnt-input-waveform.png" | relative_url }})

공식 bundle의 feature extractor는 16 kHz 파형에 400-sample FFT window, 160-sample hop, 80 Mel band를 적용하고, piecewise log, 학습 시의 global mean·inverse standard deviation, 오른쪽 context padding을 함께 적용한다. 이 순서를 checkpoint와 맞추지 않으면 입력 분포와 시간축 길이가 달라진다.

저장 shape는 다음과 같다.

```text
features           : [345, 80]
Encoder output f_t : [1, 85, 1024]
```

345는 오른쪽 padding이 포함된 Mel frame 축이고, 85는 Emformer transcriber 뒤의 실제 탐색 축이다. Notebook과 TorchAudio 2.8의 공식 non-streaming decoder 모두 transcribe 결과의 `enc_out.shape[1]`을 탐색한다. 이 실행은 전체 crop을 한 번에 처리한 **offline full-context inference**이며 streaming demo가 아니다.

![85개 Encoder 위치에서 9개 BPE token을 출력한 pretrained RNN-T Greedy 경로]({{ "/assets/images/study/speech-asr-lab/rnnt-saved-inference-path.png" | relative_url }})

저장 결과는 85개 Encoder 위치에서 blank 결정 85회와 일반 token 결정 9회를 내려 총 94개 decision을 기록한다. 출력은 다음 9개 piece다.

```text
▁i | ▁have | ▁that | ▁curiosity | ▁beside | ▁me | ▁at | ▁this | ▁moment
```

최종 transcript는 `i have that curiosity beside me at this moment`다. 일반 token은 $$t=23,27,33,48,60,67,73,77,81$$에서 하나씩 나왔고, 저장 실행에서는 같은 $$t$$의 다중 방출이 없었다. 그래프의 수직 이동이 모두 한 칸인 것은 이 sample의 관찰 결과일 뿐, RNN-T가 한 frame에 하나만 출력한다는 제약이 아니다. 합성 `cat` 예제가 그 반례다.

Predictor 호출 수도 control flow를 검산한다. 시작 blank seed에 1회, 일반 token 9개에 각각 1회 호출해 총 10회다. Blank 85회에는 Predictor를 호출하지 않는다. 대신 Joiner는 각 decision마다 현재 $$f_t,g_u$$를 사용하며, token이 나올 때만 새 $$g_{u+1}$$를 계산한다.

### 5.4 무한 방출을 막는 한도

Token을 출력하면 $$t$$가 증가하지 않으므로 잘못된 모델 출력이나 구현 오류가 계속 non-blank를 선택하면 같은 frame에서 무한 loop가 가능하다. Notebook은 `max_symbols_per_frame=30`을 두고 31번째 non-blank 선택 전에 오류로 중단한다. 강제로 blank를 삽입해 완성된 전사처럼 보이게 하지 않는 점이 중요하다. 이 한도는 model probability를 바꾸는 decoding 규칙이 아니라 **불완전한 결과를 명시적으로 실패시키는 안전 장치**다.

## 6. Source Check: 저장 코드와 TorchAudio 2.8 대조

| 확인 항목 | Notebook 동작 | 공식 2.8 대조 결과 |
|---|---|---|
| Wav2Vec2 sample rate·labels | 16 kHz, 29 class, blank 0 | Bundle source의 16 kHz·29-way head와 일치 |
| CTC Greedy collapse | 인접 반복 병합 후 blank 제거 | 공식 Wav2Vec2 tutorial의 `unique_consecutive` 후 blank 제거와 일치 |
| RNN-T feature extractor | Mel → piecewise log → global normalization → right padding | `rnnt_pipeline.py`의 non-streaming pipeline과 일치 |
| RNN-T output classes | SentencePiece 4096 + blank 4096 | Bundle의 `num_symbols=4097`, `_blank=4096`과 일치 |
| 초기 Predictor 상태 | blank를 seed로 `predict` 1회 | 공식 `RNNTBeamSearch._init_b_hypos`와 일치 |
| Blank 전이 | Predictor state를 갱신하지 않고 다음 $$t$$로 이동 | 공식 decoder가 blank hypothesis에 기존 predictor output/state를 유지하는 방식과 일치 |
| Token 전이 | 같은 $$t$$에서 token을 붙이고 `predict` 갱신 | 공식 `_gen_new_hypos`와 일치 |
| Non-streaming 길이 | `enc.shape[1]` 전체 탐색 | 공식 `forward`가 `transcribe` 뒤 `_search`, `_search`가 `enc_out.shape[1]`을 사용하는 방식과 일치 |
| Token 후처리 | 앞 seed를 제외한 piece를 decode | 공식 token processor가 `tokens[1:]`을 처리하는 방식과 일치 |

TorchAudio 2.8 문서는 프로젝트가 maintenance 단계로 전환되며 일부 API가 2.9에서 제거될 예정임을 명시한다. Notebook이 `torch==2.8.0`, `torchaudio==2.8.0`, `torchvision==0.23.0`을 함께 고정한 이유는 이 실습이 검증한 bundle·내부 객체 shape를 유지하기 위해서다. 다만 `token_processor.sp_model`과 `decoder.model`에 직접 접근하는 부분은 2.8 구현에 의존하므로 최신 버전으로 올릴 때는 공개 bundle 사용법과 source를 다시 확인해야 한다.

세 notebook의 모든 코드 셀과 저장 출력을 대조한 결과, 이번 공개본에 적용할 필수 코드 정정은 없었다. 확인된 경계는 다음과 같다.

- 저장된 설치·다운로드 메시지와 CPU inference 시간은 환경 기록이지 모델 정확도의 증거가 아니다.
- BPE는 교육용 최소 구현이며 Unicode normalization, `<unk>`, byte fallback을 제공하지 않는다.
- CTC의 작은 LM과 beam은 원리 관찰용이며 production decoder의 lexicon, pruning 최적화, word-level LM을 대체하지 않는다.
- RNN-T Greedy는 공식 beam decoder의 동작 원리를 한 경로로 펼친 것이며 beam search 결과와 같다고 보장하지 않는다.
- 실제 full-model 수치는 notebook의 저장 출력이며 이번 검토에서 checkpoint·audio를 다시 실행하지 않았다.

## 마지막 핵심 정리

| 구분 | BPE | CTC | RNN-T |
|---|---|---|---|
| 해결하는 문제 | 문자열을 token 단위로 분할 | 정렬 없는 frame 경로를 문자열로 합산 | 음향 시간과 출력 이력을 함께 조건화 |
| 핵심 상태 | merge 순서·vocab | prefix별 `pb`, `pnb` | $$t,u$$와 Predictor state |
| blank의 역할 | 없음 | 반복을 분리하고 출력에서 제거 | 시간축만 진행 |
| 반복 token | 학습 규칙대로 병합 | 인접 반복은 collapse | 실제 반복 출력으로 보존 |
| LM 결합 | tokenizer와 별개 | beam 중 fusion 또는 N-best rescoring | Predictor가 내부 출력 문맥을 이미 사용하며 외부 LM 결합은 별도 설계 |
| 모델 종속 정보 | token↔ID mapping | label 순서·blank ID | SentencePiece·blank ID·feature pipeline |

BPE의 $$V\uparrow,U\downarrow$$는 표현 단위의 trade-off다. CTC의 핵심은 가장 좋은 frame path 하나가 아니라 같은 문자열을 만드는 경로 질량의 합이다. RNN-T의 핵심은 blank와 token이 서로 다른 축을 움직이고, token을 낼 때만 출력 이력 상태가 바뀐다는 점이다. Tokenizer, class 순서, blank ID, 전처리 pipeline은 checkpoint와 한 묶음으로 다뤄야 한다.

## Study Guide

1. 먼저 BPE 표에서 **가중 count → merge 적용 → $$V,U$$ 변화**를 손으로 따라간다. 새 단어와 새 문자의 차이를 설명할 수 있어야 한다.
2. CTC에서는 `a a blank a`와 `a blank a`를 직접 collapse해 **반복 병합과 blank 제거의 순서**를 고정한다.
3. 2-frame 반례의 4개 경로를 더해 **best path와 best 문자열의 차이**를 숫자로 확인한다.
4. Prefix beam의 동일 token 전이 두 줄을 비교해 `pb/pnb`가 왜 필요한지 설명한다.
5. Shallow Fusion은 pruning 전, Rescoring은 N-best 생성 후라는 **개입 시점**을 구분한다.
6. RNN-T trace에서 오른쪽 이동은 blank, 위 이동은 token으로 읽고, Predictor가 호출되는 행만 찾는다.
7. 마지막으로 `4096 pieces + blank ID 4096 = 4097 output classes`를 확인해 tokenizer 어휘와 model class 축을 혼동하지 않는다.

## 복습 질문

<details markdown="block">
<summary>1. BPE에서 단어 빈도를 pair count에 곱하지 않으면 무엇이 달라지는가?</summary>

답변: 단어 종류마다 한 표만 주는 셈이 되어 실제 corpus에서 많이 등장한 단어의 token 절감 효과가 반영되지 않는다. Notebook의 `newer: 6` 안에 있는 pair는 6회의 관측을 기여해야 하며, 그래야 merge count와 가중 corpus token 감소량이 대응한다.

</details>

<details markdown="block">
<summary>2. 학습에 없던 단어는 처리할 수 있지만 학습에 없던 문자는 실패할 수 있는 이유는?</summary>

답변: 새 단어도 기존 문자와 subword의 조합으로 분해할 수 있다. 하지만 이 교육용 구현은 초기 문자 집합 밖의 문자를 나타낼 `<unk>`나 byte fallback이 없으므로 어떤 token ID열도 만들 수 없다.

</details>

<details markdown="block">
<summary>3. CTC에서 blank를 먼저 제거한 뒤 반복 문자를 합치면 왜 틀리는가?</summary>

답변: `a blank a`에서 blank를 먼저 지우면 `a a`가 되고 반복 병합으로 `a`가 된다. 올바른 순서는 반복 병합 후 blank 제거이므로 두 `a` 사이의 blank가 반복을 분리해 `aa`가 된다.

</details>

<details markdown="block">
<summary>4. Frame별 blank 확률이 각각 0.6, a 확률이 각각 0.4인 2-frame 예제에서 왜 a가 빈 문자열보다 높은가?</summary>

답변: Greedy path `blank, blank`의 확률은 0.36이다. `a`로 접히는 `blank,a`, `a,blank`, `a,a`의 확률은 각각 0.24, 0.24, 0.16이므로 합은 0.64다. CTC는 문자열별로 경로를 합산한다.

</details>

<details markdown="block">
<summary>5. Prefix beam에서 같은 token을 다시 볼 때 pb와 pnb가 왜 필요한가?</summary>

답변: 직전이 non-blank인 `a → a`는 collapse되어 기존 prefix `a`에 머물지만, 직전이 blank인 `a → blank → a`는 새 token을 붙여 `aa`가 된다. 직전 종료 상태를 나누지 않으면 두 확률을 올바른 prefix에 배분할 수 없다.

</details>

<details markdown="block">
<summary>6. Shallow Fusion과 Rescoring이 같은 점수식을 써도 결과가 달라질 수 있는 이유는?</summary>

답변: Shallow Fusion은 탐색 중 beam pruning 전에 LM 점수를 사용해 후보의 생존 자체를 바꾼다. Rescoring은 음향 decoder가 이미 만든 N-best 안에서만 순서를 바꾸므로 탈락한 문장을 복구할 수 없다.

</details>

<details markdown="block">
<summary>7. RNN-T에서 blank가 나왔을 때 Predictor를 갱신하면 왜 잘못인가?</summary>

답변: Blank는 출력 token을 추가하지 않으므로 출력 이력 $$u$$와 그 상태 $$g_u$$가 그대로여야 한다. Predictor를 갱신하면 실제로 출력하지 않은 기호가 이력에 들어간 것과 같은 다른 조건부 분포를 만들게 된다.

</details>

<details markdown="block">
<summary>8. 저장된 RNN-T 경로에 같은 t의 다중 token이 없는데도 한 frame에서 여러 token이 가능하다고 말할 수 있는 근거는?</summary>

답변: RNN-T의 token 전이는 $$t$$를 유지하고 $$u$$만 늘린다. 합성 `cat` 경로는 같은 $$t=2$$에서 `a`와 `t`를 연속 출력하며, 새 합성 검산도 `a,a,blank`로 $$(0,0)\to(0,1)\to(0,2)\to(1,2)$$를 확인했다. 실제 sample에서 관찰되지 않았다는 사실은 구조적 불가능을 뜻하지 않는다.

</details>

<details markdown="block">
<summary>9. RNN-T의 blank 4096을 SentencePiece에 직접 넘기면 안 되는 이유는?</summary>

답변: SentencePiece의 일반 어휘는 4096개로 ID 0–4095만 가진다. 4096은 Joiner에 별도로 추가된 blank class이며 문자열 piece가 아니다. 출력 이력의 seed와 시간 진행에는 쓰지만 최종 text에는 decode하지 않는다.

</details>

## References

- <a href="https://docs.pytorch.org/audio/2.8/tutorials/speech_recognition_pipeline_tutorial.html" target="_blank" rel="noopener">TorchAudio 2.8 — Speech Recognition with Wav2Vec2</a>
- <a href="https://docs.pytorch.org/audio/2.8/tutorials/asr_inference_with_ctc_decoder_tutorial.html" target="_blank" rel="noopener">TorchAudio 2.8 — ASR Inference with CTC Decoder</a>
- <a href="https://docs.pytorch.org/audio/2.8/generated/torchaudio.pipelines.RNNTBundle.html" target="_blank" rel="noopener">TorchAudio 2.8 — RNNTBundle</a>
- <a href="https://docs.pytorch.org/audio/2.8/generated/torchaudio.models.RNNT.html" target="_blank" rel="noopener">TorchAudio 2.8 — RNNT model API</a>
- <a href="https://raw.githubusercontent.com/pytorch/audio/v2.8.0/src/torchaudio/pipelines/rnnt_pipeline.py" target="_blank" rel="noopener">TorchAudio v2.8.0 source — RNN-T bundle, feature extractor, token processor</a>
- <a href="https://raw.githubusercontent.com/pytorch/audio/v2.8.0/src/torchaudio/models/rnnt_decoder.py" target="_blank" rel="noopener">TorchAudio v2.8.0 source — RNN-T beam decoder</a>
- <a href="https://raw.githubusercontent.com/pytorch/audio/v2.8.0/src/torchaudio/pipelines/_wav2vec2/impl.py" target="_blank" rel="noopener">TorchAudio v2.8.0 source — Wav2Vec2 bundle definitions</a>
- <a href="https://github.com/IQTLabs/voices/blob/master/Lab41-SRI-VOiCES_README.md#licensing" target="_blank" rel="noopener">SRI International and Lab41 — VOiCES corpus licensing notice</a>
- <a href="https://download.pytorch.org/torchaudio/tutorial-assets/Lab41-SRI-VOiCES-src-sp0307-ch127535-sg0042.wav" target="_blank" rel="noopener">PyTorch tutorial sample — Lab41-SRI-VOiCES-src-sp0307-ch127535-sg0042.wav</a> (<a href="https://creativecommons.org/licenses/by/4.0/" target="_blank" rel="noopener">CC BY 4.0</a>)

## Notebooks

<ul>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/01-bpe-basics.ipynb" | relative_url }}" download>01-bpe-basics.ipynb</a> — BPE merge, encoding, and vocabulary/token-count lab</li>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/02-ctc-inference.ipynb" | relative_url }}" download>02-ctc-inference.ipynb</a> — CTC Greedy, Prefix Beam Search, Shallow Fusion, and Rescoring lab</li>
  <li><a href="{{ "/assets/materials/study/speech-asr-lab/03-rnnt-inference.ipynb" | relative_url }}" download>03-rnnt-inference.ipynb</a> — RNN-T synthetic and pretrained Greedy trace lab</li>
</ul>
