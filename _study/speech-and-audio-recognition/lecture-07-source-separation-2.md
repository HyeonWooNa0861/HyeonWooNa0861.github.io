---
layout: default
date: 2026-10-15 15:18:00 +0900
last_modified_at: 2026-10-29 16:57:43 +0900
title: "Speech and Audio Recognition Lecture 7: Blind Source Separation"
course: "Speech and Audio Recognition"
topic: "Deep Clustering, PIT, Time-Domain Separation, and Unknown Source Counts"
order: 9
major_topic: "Speech and Audio Processing"
keywords:
  - "Blind Source Separation"
  - "Deep Clustering"
  - "Permutation Invariant Training"
  - "TasNet"
  - "Conv-TasNet"
  - "DPRNN"
  - "SepFormer"
  - "TF-GridNet"
  - "MixIT"
  - "Dynamic Mixing"
  - "Speech Separation"
  - "Unknown Speaker Count"
---

# Speech and Audio Recognition Lecture 7: Blind Source Separation

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture7_v2.pdf</a> — Inkyu An, Kookmin University (26 slides).

한 사람이 말하는 구간에서 잡음을 줄이는 문제와 달리, blind source separation(BSS)은 **누가 섞였는지 미리 모르는 혼합음에서 각 source를 복원**한다. 가장 먼저 부딪히는 문제는 출력 순서다. 정답 화자 A·B와 모델 출력 1·2가 있을 때, 출력 1이 항상 A여야 할 이유는 없다. Deep Clustering(DPCL)은 시간–주파수 칸을 화자별로 묶어 이 순서 문제를 피하고, Permutation-Invariant Training(PIT)은 가능한 대응 중 손실이 가장 작은 대응을 선택한다.

> **핵심:** 분리 모델은 `표현 만들기 → source별로 나누기 → 파형으로 복원하기`를 수행한다. DPCL과 PIT는 정답의 이름표 순서가 임의라는 문제를 서로 다른 방식으로 해결한다. TasNet 이후의 모델은 STFT magnitude가 아니라 학습된 waveform 표현에서도 mask를 추정한다. 최근 모델은 장거리 문맥, 계산 효율, 알 수 없는 source 수, 실제 녹음과의 차이를 함께 다룬다.

페이지 번호는 원본 PDF의 물리적 쪽 번호다. 아래 수식·작은 수치 예제·그림 해설은 이해를 위한 보충 설명이다. 슬라이드의 범위를 벗어나거나 조건이 빠진 표현은 마지막 `Source Check`에서 구분한다.

## 전체 흐름

**중간고사 범위는 Source Separation 직전인 Self-Supervised Learning까지이며, 이 7강의 음원 분리는 포함되지 않는다.** 이 개별 노트에는 DPCL·PIT를 포함한 강의 전체 해설을 그대로 보존한다. 범위에 맞춘 복습은 [Midterm Review](/study/speech-and-audio-recognition/midterm-review/)를 따른다.

| 원문 | 주제 | 먼저 이해할 질문 |
|---|---|---|
| pp. 2–6 | Task taxonomy와 ESD | 무엇을 분리하며, 어떤 정보를 출력해야 하는가? |
| pp. 7–12 | 출력 순열, DPCL, PIT | 정답 화자와 출력 번호가 바뀌어도 같은 답인 이유는 무엇인가? |
| pp. 13–19 | TasNet, Conv-TasNet, DPRNN, SepFormer | 파형 표현에서 mask와 긴 문맥을 어떻게 학습하는가? |
| pp. 20–21 | TF-GridNet과 효율화 | 복소 STFT와 시간–주파수 문맥을 어떻게 함께 읽는가? |
| pp. 22–23 | 알 수 없는 source 수 | 출력 개수를 미리 고정할 수 없을 때 무엇을 바꾸어야 하는가? |
| pp. 24–25 | 실제 녹음, DM, MixIT | 깨끗한 단일 source 정답이 없을 때 어떻게 학습하는가? |
| p. 26 | 생성 모델 | 하나의 점 추정 대신 가능한 분리 결과의 분포를 모델링하면 무엇이 달라지는가? |

## 1. Blind source separation의 문제 설정

### 1.1 Denoising, separation, diarization은 출력이 다르다

| Task | Input | Output | 알려진 조건 |
|---|---|---|---|
| Denoising | 목표 음성 + 잡음 | 잡음이 줄어든 목표 음성 | 보존할 종류가 정해짐 |
| Blind source separation | 여러 source의 혼합 | source별 파형 | source의 정체·혼합 과정 정보가 거의 없음 |
| Guided separation | 혼합 | 지정된 종류별 stem | vocals·bass 같은 class가 정해짐 |
| Target separation | 혼합 + reference | reference와 같은 target의 파형 | target을 나타내는 enrollment 정보가 있음 |
| Diarization | 녹음 | 누가 언제 활동했는지 | 파형 복원이 필수는 아님 |

혼합 파형을 다음처럼 쓸 수 있다.

$$
x[n]=\sum_{k=1}^{K}s_k[n]
$$

여기서 $$K$$는 source 수다. Single-channel BSS는 한 개의 관측 $$x$$에서 여러 $$s_k$$를 추정하므로, 관측만으로 해가 항상 유일한 것은 아니다. 모델은 음성의 시간적 지속성, harmonic 구조, 학습 데이터의 통계적 규칙을 이용해 가능한 해를 선택한다.

### 1.2 ESD는 모델 이름이 아니라 공통 계산 구조다

원문 p. 6의 Encoder–Separation–Decoder(ESD)는 특정 architecture 하나가 아니라 분리 모델을 읽는 공통 틀이다.

1. **Encoder:** waveform을 분리에 편리한 표현으로 바꾼다. STFT일 수도 있고, 학습된 1-D convolution 표현일 수도 있다.
2. **Separator:** 각 source에 속할 성분을 추정한다. Mask, complex spectrum 또는 waveform residual을 낼 수 있다.
3. **Decoder:** 분리된 표현을 waveform으로 복원한다. iSTFT나 학습된 transposed convolution이 쓰인다.

원문 p. 7의 여러 decoder 그림은 첫 아이디어를 보여준다. 그러나 source A와 B의 위치가 매번 바뀌면 `output 1 = A`라는 고정 규칙으로 손실을 계산할 수 없다.

## 2. 출력 순서가 학습을 망가뜨리는 이유

두 화자의 정답을 $$s_A,s_B$$, 두 출력을 $$\hat s_1,\hat s_2$$라고 하자. 물리적으로는 다음 두 대응이 모두 같은 분리 결과가 될 수 있다.

$$
(\hat s_1,\hat s_2)\leftrightarrow(s_A,s_B)
$$

$$
(\hat s_1,\hat s_2)\leftrightarrow(s_B,s_A)
$$

학습 데이터마다 임의로 첫 번째 정답 화자가 달라지면, 고정된 output index로 계산한 gradient는 같은 음성을 어떤 때는 1번으로, 어떤 때는 2번으로 보내라고 요구한다. 이 충돌이 **label permutation problem**이다. 해결의 핵심은 화자의 실제 이름을 알아내는 것이 아니라, **출력 순서에 영향을 받지 않는 목적함수**를 만드는 데 있다.

## 3. DPCL: 출력 칸 대신 같은 화자인지를 배운다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-09.png" alt="DPCL이 시간–주파수 칸을 embedding으로 바꾸고 k-means cluster로 source mask를 만드는 과정" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=9" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 9</a>의 왼쪽은 세 화자 혼합, ideal mask, DPCL mask를 비교한다. 오른쪽 계산 흐름은 다음과 같다.

1. 각 시간–주파수(T–F) 칸을 $$D$$차원 embedding $$v_i$$로 바꾼다.
2. 같은 화자에 속한 두 칸의 embedding은 가깝게, 다른 화자의 칸은 멀게 만든다.
3. 추론 시 embedding을 $$K$$개 cluster로 묶는다.
4. Cluster별 binary mask를 mixture magnitude에 적용하고 mixture phase와 iSTFT로 waveform을 만든다.

여기서 중요한 target은 화자 번호 자체가 아니다. 두 칸이 **같은 화자 소속인지**다. 화자 label 1과 2를 서로 바꾸어도 이 관계는 바뀌지 않는다.

### 3.1 Training의 V와 Y는 무엇인가

그림의 Training은 **모델이 예측한 소속 관계와 정답 소속 관계를 비교하는 단계**다. 입력은 혼합음의 spectrogram이고, 학습용 정답은 섞기 전 각 source에서 만든다.

| 기호 | 무엇을 담는가 | 어디서 얻는가 |
| --- | --- | --- |
| $$N=TF$$ | 시간 frame $$T$$와 주파수 bin $$F$$를 펼친 전체 칸 수 | 입력 spectrogram |
| $$V\in\mathbb R^{N\times D}$$ | 각 칸을 나타내는 길이 $$D$$의 embedding. 한 행 $$v_i$$가 한 T–F 칸에 해당한다. | 신경망 출력. 학습 중 network parameter에 따라 바뀐다. |
| $$Y\in\{0,1\}^{N\times K}$$ | 각 칸에서 어느 source가 우세한지 나타내는 one-hot 정답. 한 행에서 해당 source 열만 1이다. | 분리된 정답 source의 크기를 비교해 만든 label |
| $$VV^{\mathsf T}$$ | 모든 두 칸의 embedding 내적. 모델이 표현한 소속 유사도 | $$V$$에서 계산 |
| $$YY^{\mathsf T}$$ | 두 칸의 정답 source가 같으면 1, 다르면 0인 관계표 | $$Y$$에서 계산 |

**$$V$$는 음성 파형도, source별 확률표도 아니다. $$Y$$도 화자의 실제 신원을 알려주는 표가 아니다.** $$Y$$의 A·B는 해당 혼합 안에서 구별하는 임시 source label이며, embedding 차원 $$D$$는 source 수 $$K$$와 같을 필요가 없다. 두 source가 같은 칸에 함께 존재해도 one-hot label은 우세한 하나만 지정한다. 완전한 source spectrum 자체를 정답으로 담는 것은 아니다.

세 칸의 정답이 순서대로 A, B, A라면 다음과 같다.

$$
Y=\begin{bmatrix}1&0\\0&1\\1&0\end{bmatrix},\qquad
YY^{\mathsf T}=\begin{bmatrix}1&0&1\\0&1&0\\1&0&1\end{bmatrix}.
$$

첫째와 셋째 칸은 같은 A이므로 정답 관계값이 1이다. 첫째와 둘째 칸은 서로 다른 source이므로 0이다. 학습은 $$v_1^{\mathsf T}v_3$$를 1에, $$v_1^{\mathsf T}v_2$$를 0에 가깝게 만든다. **$$V$$를 $$Y$$와 원소별로 같게 만드는 것이 아니라, 두 행렬이 나타내는 칸 사이의 관계를 맞춘다.** 단위길이 embedding의 내적은 확률이 아니며 음수가 될 수도 있다.

학습 중에는 $$Y$$를 고정한 채 loss를 embedding과 network까지 역전파한다. 추론 때에는 정답 source가 없으므로 $$Y$$를 만들지 않는다. 혼합음에서 $$V$$를 얻고, k-means가 비슷한 embedding을 묶어 mask를 만든다. 따라서 그림의 Training과 Inference는 같은 계산을 반복하는 두 이름이 아니라 **정답 관계를 배우는 단계와 배운 표현을 분리에 사용하는 단계**다.

<details markdown="block">
<summary markdown="span">Derivation: DPCL affinity loss and its efficient form</summary>

T–F 칸 수를 $$N=TF$$라 하자. $$V\in\mathbb{R}^{N\times D}$$의 $$i$$번째 행은 단위길이 embedding $$v_i$$다. $$Y\in\{0,1\}^{N\times K}$$의 한 행은 그 칸의 dominant source를 나타내는 one-hot label이다.

$$
(YY^\mathsf{T})_{ij}=\begin{cases}
1,& i,j\text{가 같은 source}\;,\\
0,& i,j\text{가 다른 source}\;.
\end{cases}
$$

Embedding affinity는 $$(VV^\mathsf{T})_{ij}=v_i^\mathsf{T}v_j$$다. 따라서 deep clustering loss는

$$
\mathcal{L}_{\mathrm{DC}}=\left\|VV^\mathsf{T}-YY^\mathsf{T}\right\|_F^2
$$

로 쓸 수 있다. 같은 source의 embedding 내적은 1에, 다른 source의 내적은 0에 가까워지도록 학습한다.

$$YY^\mathsf{T}$$는 source label의 열 순열에 불변이다. Permutation matrix $$P$$에 대해 $$Y'=YP$$라고 두면

$$
Y'Y'^\mathsf{T}=YPP^\mathsf{T}Y^\mathsf{T}=YY^\mathsf{T}
$$

이므로 화자 1·2의 label을 바꾸어도 target affinity는 같다.

$$N\times N$$ 행렬을 직접 만들면 메모리가 크다. $$A=VV^\mathsf{T}$$, $$B=YY^\mathsf{T}$$라 두고 Frobenius norm을 trace로 전개하면

$$
\begin{aligned}
\|A-B\|_F^2
&=\operatorname{tr}\!\left((A-B)^\mathsf{T}(A-B)\right)\\
&=\operatorname{tr}(A^\mathsf{T}A)-2\operatorname{tr}(A^\mathsf{T}B)+\operatorname{tr}(B^\mathsf{T}B).
\end{aligned}
$$

Trace의 순환 성질 $$\operatorname{tr}(PQ)=\operatorname{tr}(QP)$$를 각 항에 적용한다. 예를 들어

$$
\operatorname{tr}(VV^\mathsf{T}VV^\mathsf{T})
=\operatorname{tr}(V^\mathsf{T}VV^\mathsf{T}V)
=\|V^\mathsf{T}V\|_F^2
$$

이다. 같은 방식으로 교차항과 label항을 정리하면

$$
\mathcal{L}_{\mathrm{DC}}
=\left\|V^\mathsf{T}V\right\|_F^2
-2\left\|V^\mathsf{T}Y\right\|_F^2
+\left\|Y^\mathsf{T}Y\right\|_F^2
$$

가 되어 더 작은 행렬로 계산할 수 있다. 이 등식은 affinity loss의 의미를 바꾸지 않는다.

</details>

### 3.2 그림의 Cons는 무엇을 제한하는가

DPCL의 장점은 출력 slot을 미리 화자와 연결하지 않는다는 점이다. 원 논문은 두 화자로 학습한 모델을 세 화자 분리에 적용할 수 있음을 보였다. 다만 추론의 k-means에는 $$K$$가 필요하므로, **source 수를 저절로 안다**는 뜻은 아니다. $$K$$를 외부에서 주거나 별도로 추정해야 한다.

9쪽의 Cons는 다음 두 제약을 직접 지적한다. 둘 다 이 그림의 **원형 DPCL pipeline**에 대한 설명이지, 이후 모든 clustering 기반 모델의 불가능성을 뜻하지 않는다.

| 슬라이드의 한계 | 왜 분리 결과에 영향을 주는가 | 개선 방향과 남는 조건 |
| --- | --- | --- |
| k-means not trained end-to-end | Training에서는 embedding affinity를 맞추지만, 추론의 k-means와 최종 복원 파형의 오차까지 하나의 목적함수로 함께 최적화하지 않는다. 좋은 affinity가 곧 가장 좋은 waveform을 보장하지 않는다. | PIT를 이용해 source별 예측을 정답과 직접 대응시키고 복원 loss로 학습할 수 있다. Clustering과 reconstruction을 결합하는 확장도 가능하다. |
| Binary magnitude mask, mixture phase | 한 칸을 0 또는 1로 선택하므로 여러 source가 겹친 칸의 기여를 연속적으로 나누기 어렵다. 크기를 잘 골라도 혼합음 위상은 개별 source의 위상과 다를 수 있다. | Soft mask는 연속적인 비중을 표현하고, complex-spectrum 추정이나 waveform 학습은 위상까지 다룰 수 있다. 단순 soft magnitude mask만으로 위상 문제가 해결되지는 않는다. |

예를 들어 같은 칸의 두 source가 $$S_1=1$$, $$S_2=j$$라면 혼합값은 $$X=1+j$$다. 첫 source를 복원하려고 binary mask 1을 적용해도 $$1+j$$가 남고, 0이면 첫 source까지 사라진다. 더 나아가 실수 soft mask $$m$$도 $$m(1+j)=1$$을 만족할 수 없다. 허수부를 없애려면 $$m=0$$이어야 하지만 그러면 실수부도 0이 되기 때문이다. 반면 complex mask $$M=(1-j)/2$$는 $$MX=1$$을 만족한다. 이 예는 복소 마스크가 항상 정확히 추정된다는 보장이 아니라, **크기만 조절하는 표현과 위상도 바꾸는 표현의 차이**를 보여준다.

그림의 `Cons → PIT`는 직접 분리 학습으로 넘어가는 동기다. **PIT 자체는 출력–정답의 순서 문제를 푸는 loss 계산 방식이지, phase estimator나 source-count estimator가 아니다.** PIT를 적용하더라도 magnitude mask와 mixture phase를 그대로 쓰면 그 복원 제약은 남는다.

## 4. PIT: 가능한 대응 중 가장 잘 맞는 것을 고른다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-10.png" alt="PIT가 여러 source 출력과 정답의 가능한 순열을 비교해 최소 손실 대응을 고르는 과정" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=10" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 10</a>에서 separator의 출력 수는 그대로 유지된다. 달라지는 것은 loss 계산이다. 각 출력과 각 정답의 pairwise cost를 구한 뒤, 한 정답과 한 출력이 한 번씩만 연결되는 대응 중 총비용이 가장 작은 것을 선택한다.

### 4.1 두 화자 수치 예제

행을 정답 A·B, 열을 출력 1·2라고 하자. 작은 cost일수록 잘 맞는다.

$$
C=\begin{bmatrix}
9&1\\
2&8
\end{bmatrix}
$$

- A→1, B→2이면 합은 $$9+8=17$$, 평균은 $$8.5$$다.
- A→2, B→1이면 합은 $$1+2=3$$, 평균은 $$1.5$$다.

PIT는 두 번째 대응을 고르고, 그 대응으로 계산한 loss만 back-propagation한다. 출력 1이 B를, 출력 2가 A를 복원했다면 잘못된 순서가 아니라 **다른 순서의 정답**이다.

<details markdown="block">
<summary markdown="span">Derivation: PIT objective, assignment, and complexity</summary>

정답 source를 $$s_1,\ldots,s_K$$, 출력 source를 $$\hat s_1,\ldots,\hat s_K$$라 하자. Pairwise cost는

$$
C_{ij}=\ell(s_i,\hat s_j)
$$

다. $$S_K$$를 $$K$$개 항목의 모든 permutation 집합이라 하면 PIT objective는

$$
\mathcal{L}_{\mathrm{PIT}}
=\min_{\pi\in S_K}\frac{1}{K}\sum_{i=1}^{K}C_{i,\pi(i)}
$$

다. $$\pi$$는 각 정답을 서로 다른 출력 하나에 연결한다. 행마다 독립적으로 최소값만 고르면 같은 출력을 여러 정답이 함께 선택할 수 있으므로 올바른 one-to-one assignment가 아니다.

모든 순열을 그대로 열거하면 후보가 $$K!$$개다. 그러나 pairwise cost matrix가 만들어진 뒤의 선형 할당 문제는 Hungarian(Kuhn–Munkres) algorithm으로 일반적으로 $$O(K^3)$$에 풀 수 있다. Cost matrix 생성 자체는 각 waveform 비교 길이를 $$L$$이라 할 때 대략 $$O(K^2L)$$의 계산을 요구할 수 있다. 원문 p. 22의 `Hungarian algorithm: K²` 표기는 일반적인 assignment 단계의 시간복잡도가 아니다.

Minimum은 두 permutation의 비용이 같은 지점에서 미분 가능하지 않을 수 있다. 실제 학습에서는 선택된 최소-cost 대응을 고정해 그 branch의 gradient를 사용한다. PIT는 **학습 중 source 순서**를 해결하지만, source 수 $$K$$를 추정하거나 발화 사이에서 동일 인물의 ID를 유지하는 기능은 별도 문제다.

</details>

원문 pp. 11–12의 uPIT는 frame마다 대응을 바꾸지 않고 utterance 전체에서 하나의 permutation을 선택한다. 그래야 한 출력 channel 안에서 화자가 중간에 서로 바뀌는 문제를 줄일 수 있다. 표의 oracle mask·DPCL·PIT 수치는 같은 dataset, metric, reconstruction 조건에서만 비교해야 한다.

### 4.2 DPCL, PIT, uPIT는 같은 종류의 구성요소가 아니다

강의는 DPCL의 한계 다음에 PIT를 소개하지만, 이를 하나의 network가 차례로 block을 추가한 계보로 읽으면 안 된다. DPCL은 **무엇을 예측할지**를 embedding으로 바꾸고, PIT와 uPIT는 **여러 출력과 정답을 어떻게 비교할지**를 바꾼다.

| 방법 | 예측 target | 추론과 복원 | 학습에서 바꾸는 부분 | 관계 |
|---|---|---|---|---|
| [Deep Clustering](https://arxiv.org/abs/1508.04306){:target="_blank" rel="noopener"} | 각 T–F 칸의 embedding과 같은-source affinity | Embedding을 k-means로 묶어 binary magnitude mask를 만들고, mixture phase와 iSTFT로 복원 | Affinity loss가 source label 열의 순열에 불변 | Fixed output slot 대신 clustering을 택한 대안이다. PIT의 초기 architecture가 아니다. |
| [PIT](https://arxiv.org/abs/1607.00325){:target="_blank" rel="noopener"} | 정답 source 집합은 고정되어 있다. Model은 source별 spectrum·mask·waveform을 예측하며, output index와 target source의 대응만 순열로 선택한다 | 적용한 separator와 decoder의 출력 경로를 유지 | 가능한 output–target 대응 중 선택한 reconstruction loss가 가장 작은 순열로 역전파 | Architecture와 독립적으로 붙일 수 있는 training criterion이다. |
| [uPIT](https://arxiv.org/abs/1703.06284){:target="_blank" rel="noopener"} | PIT와 같은 source별 출력 | 발화 전체에서 한 output channel의 source가 유지되도록 복원 | Frame마다 다른 대응을 고르지 않고 utterance 전체 loss로 하나의 순열 선택 | PIT의 직접적인 utterance-level 확장이다. Source count 추정이나 speaker ID tracking은 추가하지 않는다. |
{: .reference-candidate-table}

따라서 `DPCL → PIT`는 강의의 문제 해결 비교 순서이며 직접 상속 관계가 아니다. 반면 PIT에서 uPIT로의 변화는 순열을 고르는 범위를 frame에서 utterance로 넓힌 직접 확장이다. 어떤 spectrum·waveform loss를 최소화할지는 PIT와 별도로 정해야 한다.

## 5. TasNet 계열: STFT 밖에서도 mask를 만들 수 있다

### 5.1 공통 뼈대

TasNet 계열은 waveform 조각을 학습된 basis의 coefficient로 바꾸고, 그 latent representation에서 source별 mask를 만든다.

$$
W=\operatorname{Encoder}(x),\qquad
D_k=M_k\odot W,\qquad
\hat s_k=\operatorname{Decoder}(D_k)
$$

여기서 $$M_k$$는 source $$k$$의 mask다. **Time-domain model도 masking을 버린 것이 아니다.** Mask를 적용하는 대상이 STFT magnitude에서 학습된 waveform basis coefficient로 이동했다.

Mask activation과 학습 target은 model version별로 다르다. 다음 표는 원 논문에서 사용한 대표 configuration을 구분한다.

| Model | Mask가 적용되는 대상 | 대표 mask 출력 | 무엇을 직접 최적화하는가? |
|---|---|---|---|
| TasNet | Nonnegative learned mixture weights | Source축 softmax, source masks의 합이 1 | Mask 정답을 직접 맞추지 않고, decoder 뒤 waveform의 SI-SNR을 PIT로 최대화 |
| Conv-TasNet | Learned encoder feature | 논문의 최종 실험은 sigmoid, 각 값 $$[0,1]$$; softmax도 비교 | Decoder 뒤 waveform SI-SNR + utterance PIT |
| DPRNN-TasNet | Conv-TasNet 계열 learned feature | $$C$$개 masking matrices; 논문은 separator 교체에 초점을 두며 하나의 보편 범위를 새로 정의하지 않음 | Decoder 뒤 waveform SI-SNR + uPIT |
| SepFormer | ReLU encoder feature | 마지막 ReLU의 nonnegative mask, 상한 1은 강제하지 않음 | Decoder 뒤 waveform SI-SNR + uPIT, 논문 설정은 30 dB clipping |
{: .reference-candidate-table}

따라서 `mask는 항상 확률이고 source별 합이 1`이라고 일반화하면 안 된다. 또한 mask를 사용한다고 해서 ideal mask label로 mask 자체를 직접 감독하는 것도 아니다. 위 모델들은 mask를 거쳐 복원한 waveform이 정답과 잘 맞도록 end-to-end로 학습한다.

<details markdown="block">
<summary markdown="span">Derivation: learned basis separation as an analysis–mask–synthesis system</summary>

Encoder의 filter를 $$u_m[r]$$, frame index를 $$t$$, window 길이를 $$B$$ samples, hop을 $$H$$ samples라 하면 한 구현의 coefficient는

$$
W_{m,t}=g\!\left(\sum_{r=0}^{B-1}x[tH+r]u_m[r]\right)
$$

처럼 쓸 수 있다. $$g$$는 ReLU 같은 비선형 함수다. Separator가 $$M_{k,m,t}$$를 예측하면

$$
D_{k,m,t}=M_{k,m,t}W_{m,t}
$$

이고 decoder basis $$b_m[r]$$로 overlap-add한다.

$$
\hat s_k[tH+r]\mathrel{+}=\sum_m D_{k,m,t}b_m[r]
$$

STFT도 고정된 sine·cosine analysis basis와 inverse transform을 사용한다. TasNet의 차이는 analysis·synthesis basis를 task loss로 학습한다는 점이다. 이 표현이 복소수가 아니라는 이유만으로 위상이 사라졌다고 단정할 수는 없다. Decoder가 waveform의 sample 위치까지 복원하도록 학습되므로 시간 구조는 latent coefficient와 basis에 함께 담긴다.

</details>

### 5.2 TasNet과 Conv-TasNet

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-13.png" alt="TasNet 원본 슬라이드의 학습 가능한 basis, latent vector, recurrent separator, source별 mask와 decoder" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=13" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 13</a>의 TasNet은 왼쪽 waveform 조각을 오른쪽의 학습 가능한 basis로 표현한다. 그림의 $$N$$은 basis 개수이며, 가운데 recurrent separator는 이 coefficient의 시간 변화를 읽어 source별 mask를 만든다. Masked coefficient를 decoder로 합성하면 각 source의 파형이 나온다. **LSTM-TasNet은 이 separator가 LSTM인 구성**을 뜻하며, BLSTM-TasNet은 양방향 문맥을 쓰는 구성이므로 둘의 수치를 구분해야 한다.

짧은 waveform window는 미세한 시간 구조를 다룰 수 있지만 같은 길이의 발화에서 처리할 frame 수를 늘린다. Recurrent separator는 앞 상태를 계산해야 다음 상태를 계산하므로 긴 sequence의 학습·처리가 부담스럽다. Conv-TasNet은 이 separator를 dilated temporal convolutional network(TCN)로 바꾸었다.

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-14.png" alt="Conv-TasNet의 waveform encoder, dilated TCN separator, source별 mask와 decoder 구조" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=14" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 14</a>를 왼쪽에서 오른쪽으로 읽으면 다음과 같다.

1. 짧은 waveform segment를 1-D convolution encoder가 latent feature로 바꾼다.
2. Bottleneck과 반복된 dilated convolution block이 여러 시간 범위의 문맥을 읽는다.
3. Source별 mask를 latent mixture에 곱한다.
4. Linear decoder가 각 masked representation을 waveform으로 합성한다.

TasNet과 Conv-TasNet의 관계는 직접적이다. Conv-TasNet은 TasNet의 learned analysis–mask–synthesis 틀을 유지하면서 recurrent separator를 convolutional TCN으로 바꾸고 긴 입력을 효율적으로 처리한다. 반면 PIT는 두 architecture가 함께 사용할 수 있는 **순열 불변 학습 규칙**이다. `PIT → TasNet → Conv-TasNet`을 세 architecture의 직렬 발전으로 읽지 않는다. Architecture는 latent 표현과 separator를 정하고, PIT는 복원된 source와 정답의 대응을 정하며, SI-SNR은 선택된 대응의 waveform 품질을 측정한다.

Dilation이 1, 2, 4처럼 커지면 kernel 크기를 무작정 늘리지 않아도 더 먼 frame을 연결한다. 깊은 TCN은 local pattern과 넓은 receptive field를 동시에 갖는다. 다만 실제 receptive field, causal 여부, latency는 kernel·dilation·반복 수·padding 설정에 달려 있다.

원문 pp. 14–15의 성능 표가 보여주는 요점은 learned time-domain representation이 당시 fixed STFT magnitude-mask baseline을 넘어설 수 있었다는 것이다. 이것은 **STFT라는 표현 전체가 원리적으로 열등하다는 증명**이 아니다. 비교한 oracle은 fixed magnitude mask와 mixture phase라는 제약을 가진다. 이후 TF-GridNet처럼 complex spectrum을 직접 추정하는 모델은 STFT domain에서도 높은 성능을 보인다.

### 5.3 성능 차이는 같은 causality 설정끼리 읽는다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-19.png" alt="TasNet, Conv-TasNet, DPRNN, SepFormer 성능을 비교하는 원본 표로 일부 행의 causal 설정과 지표는 아래에서 정정" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=19" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 19</a>는 왼쪽부터 표현, separator, parameter 수, 개선 점수, causal variant를 나열한다. 그러나 **TasNet-BLSTM의 23.6M과 10.8 dB는 같은 configuration의 값이 아니다.** Causal variant가 존재한다는 오른쪽 표기도 그 행의 점수가 causal 실험이라는 뜻은 아니다. 아래 표는 <a href="https://arxiv.org/pdf/1809.07454" target="_blank" rel="noopener">Conv-TasNet 원 논문 Table IV</a>의 WSJ0-2mix, 8 kHz, 두 화자 결과에서 설정을 분리한 것이다. SI-SNRi는 혼합음 대비 SI-SNR 개선량이며 높을수록 좋다. M은 백만 parameters다.

| Context | Model | Parameters | SI-SNRi (dB) |
|---|---|---|---|
| Non-causal | BLSTM-TasNet | 23.6M | 13.2 |
| Non-causal | Conv-TasNet, gLN | 5.1M | 15.3 |
| Causal | LSTM-TasNet | 32.0M | 10.8 |
| Causal | Conv-TasNet, cLN | 5.1M | 10.6 |
{: .reference-candidate-table}

Non-causal은 미래 입력도 참조하고, causal은 현재·과거 입력만 참조하는 설정이다. gLN(global layer normalization)은 발화의 시간·채널 정보를 함께 사용하고 cLN(cumulative layer normalization)은 현재까지의 통계만 사용한다. Causal convolution만 적용해도 gLN이 미래 통계를 읽으면 전체 모델은 causal이 아니므로 두 조건을 함께 확인해야 한다.

비인과 비교에서 개선량 차이는 $$15.3-13.2=2.1\,\mathrm{dB}$$다. SI-SNR은 에너지 비의 로그이므로 2.1 dB를 정확도 2.1% 상승으로 읽지 않는다. 반면 인과 비교는 $$10.6-10.8=-0.2\,\mathrm{dB}$$다. **Conv-TasNet의 기여는 언제나 더 높은 점수가 아니라, 작은 모델과 효율적인 문맥 처리로 경쟁력 있는 분리를 구현한 데도 있다.**

차이를 만드는 설계는 서로 연결된다. Dilated convolution은 넓은 시간 범위를 읽고, residual·skip connection은 여러 깊이의 정보를 전달한다. 시간 위치별 연산을 병렬화할 수 있어 recurrent 상태를 순서대로 갱신하는 부담도 줄인다. 짧은 encoder window와 normalization도 결과에 영향을 준다. 이 표만으로 2.1 dB 전부를 convolution 하나의 효과라고 분해할 수는 없다. 두 모델 전체 configuration의 비교이지, 다른 요소를 모두 고정한 단일 요인 실험은 아니기 때문이다.

## 6. 긴 문맥을 다루는 DPRNN과 SepFormer

### 6.1 DPRNN: 긴 sequence를 두 개의 짧은 축으로 나눈다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-16.png" alt="DPRNN이 encoded sequence를 겹치는 chunk로 나누고 intra-chunk와 inter-chunk RNN을 교대로 적용하는 구조" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=16" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 16</a>의 위쪽 `A. Segmentation`은 왼쪽의 긴 직사각형을 겹치는 조각으로 나눈 뒤 오른쪽의 입체 tensor로 쌓는 과정이다. **위쪽 가로 길이 $$L$$은 시간 frame 수, 세로 길이 $$N$$은 각 frame의 feature 채널 수다.** $$N$$을 전체 시간 길이나 화자 수로 읽으면 아래 RNN 축도 반대로 이해하게 된다.

| 기호 | 원본 그림에서의 의미 | 단위·구별 |
|---|---|---|
| $$N$$ | Encoder feature 채널 수 | 채널 개수, 무차원. 이 절에서는 DPCL의 $$N=TF$$와 다른 뜻이다. |
| $$L$$ | Encoded sequence 전체의 시간 길이 | Frame 개수, 초나 waveform sample 수가 아니다. |
| $$K$$ | 한 chunk의 시간 길이. 그림 오른쪽 가로 길이 $$2P$$에 해당 | Frame 개수, 이 절에서는 앞 절의 source 수 $$K$$와 구분한다. |
| $$P$$ | 다음 chunk 시작점까지 이동하는 hop | Frame 개수. 원 논문의 50% overlap은 $$P=K/2$$다. |
| $$S$$ | 쌓아 놓은 chunk 개수 | 개수, 무차원 |
| $$C$$ | 이 절에서 별도로 쓰는 출력 source 수 | 화자 개수. $$N$$이나 chunk 길이 $$K$$와 무관하다. |
{: .reference-candidate-table}

Segmentation 전 shape는 $$N\times L$$, 후 shape는 $$N\times K\times S$$다. Frame마다 $$N$$개 값을 가진다는 사실은 그대로이며, 긴 시간축만 `chunk 내부 위치`와 `chunk 번호`로 나누었다. 화자를 chunk별로 나누는 작업도, 주파수 bin을 새로 만드는 변환도 아니다.

Chunking의 목적은 **짧은 구간의 세부 패턴과 먼 구간의 문맥을 둘 다 보면서, 한 recurrent chain의 길이를 줄이는 것**이다. 짧은 음성 조각만 독립적으로 분리하면 다른 구간의 같은 화자 정보를 놓칠 수 있다. 반대로 전체 발화를 하나의 긴 RNN으로 읽으면 순차 의존이 길어진다. DPRNN은 두 축을 번갈아 읽어 이 두 요구를 결합한다. Overlap은 인접 chunk가 경계의 frame을 공유하게 하며, 마지막 overlap-add는 같은 시간 위치의 출력을 다시 결합한다.

### 6.2 RNN 축을 바꾸는 기준: chunk 안과 chunk 사이

아래는 **원본 그림을 읽기 위한 Supplementary table**이다. 설명용으로 $$L=8$$ frames, $$K=4$$ frames, $$P=2$$ frames를 택했다. 숫자는 feature 값이 아니라 원래 frame의 번호다. 실제 논문의 경계 padding을 생략하고 내부의 세 chunk만 표시한다.

| Chunk | 내부 위치 1 | 내부 위치 2 | 내부 위치 3 | 내부 위치 4 |
|---|---|---|---|---|
| 1 | Frame 1 | Frame 2 | Frame 3 | Frame 4 |
| 2 | Frame 3 | Frame 4 | Frame 5 | Frame 6 |
| 3 | Frame 5 | Frame 6 | Frame 7 | Frame 8 |

1. **Intra-chunk RNN은 표의 한 행을 읽는다.** Chunk 1에서는 1·2·3·4번 frame을 순서대로 처리한다. 다른 chunk에도 같은 RNN을 적용한다. 고정하는 것은 chunk 번호이고, 움직이는 것은 내부 위치인 $$K$$축이다. 각 step의 입력은 scalar가 아니라 $$N$$개 feature를 가진 vector다.
2. **Inter-chunk RNN은 intra 처리 뒤 표의 한 열을 읽는다.** 내부 위치 1을 고정하면 chunk 1·2·3에 대응하는 원래 1·3·5번 위치를 연결한다. 고정하는 것은 chunk 내부 위치이고, 움직이는 것은 chunk 번호인 $$S$$축이다. 이때 입력은 이미 intra RNN이 주변 문맥을 반영한 feature이므로 원래 frame 1·3·5의 값만 따로 읽는 것과 다르다.
3. **다음 block에서 두 방향의 정보가 다시 섞인다.** 원본 아래 `B. DPRNN block`의 두 RNN 상자는 서로 다른 주파수를 보는 것이 아니라 같은 tensor를 다른 시간 조직으로 읽는다. FC는 hidden feature를 원래 feature 차원으로 되돌리고, normalization과 residual addition은 shape를 유지하며 block을 연결한다.

따라서 축 전환의 기준은 임의의 회전이 아니라 **고정한 index와 순회할 index의 교환**이다. Intra는 구간 내부의 세부 구조, inter는 구간 사이의 긴 연결을 담당한다. $$N$$ 채널축 자체를 RNN의 시간축으로 바꾸지 않는다.

예를 들어 $$L=32{,}000$$ frames에서 $$K=250$$, $$P=125$$를 쓰면 원 논문의 padding 규칙에서 $$S=257$$ chunks다. 한 RNN이 32,000 steps를 읽는 대신 intra는 250 steps, inter는 257 steps를 읽는다. 이는 길이 비교를 위한 작성자 계산이며 새로운 분리 성능 실험은 아니다. **한 chain이 짧아졌다는 뜻이지, 전체 frame 계산량이나 memory가 제곱근으로 줄었다는 뜻은 아니다.**

> **정정:** 원 논문의 표준 DPRNN은 bidirectional RNN을 포함하므로 기본형을 곧바로 streaming-ready 또는 causal이라고 부를 수 없다. 실시간 처리를 하려면 causal inter-chunk path, 제한된 look-ahead, state 관리 등 별도 설계가 필요하다.

또한 원문 p. 16의 `2 ms chunks`는 encoder window와 DPRNN chunk를 섞은 표현이다. 16 kHz noisy-reverberant 실험에서 2 ms는 32-sample encoder window이고 DPRNN chunk는 100 encoded frames다. WSJ0-2mix의 18.8 dB SI-SNR improvement 설정은 2-sample encoder window와 250-frame chunk를 사용한다. Sample/window 길이와 encoded-frame chunk 길이는 서로 다른 단위다.

<details markdown="block">
<summary markdown="span">Derivation: why dual-path shortens the recurrent path</summary>

원 논문 §II의 표기로 feature를 $$W\in\mathbb R^{N\times L}$$라 하자. $$K$$ frames씩 잘라 $$P=K/2$$ frames 이동하면 각 chunk는 $$N\times K$$, 전체 tensor는 $$N\times K\times S$$다. 논문의 앞뒤 padding을 포함한 chunk 수는

$$
S=\left\lceil\frac{2L}{K}\right\rceil+1
$$

이다. 이는 해당 padding 규칙의 등식이다. 경계를 제외한 규모 비교에는 $$S\approx2L/K$$를 쓸 수 있다. Intra는 $$S$$개 chunk 각각에서 길이 $$K$$를, inter는 $$K$$개 내부 위치 각각에서 길이 $$S$$를 처리한다. 각 RNN의 input feature 차원은 $$N$$이다.

긴 쪽 chain을 줄이려면 두 길이를 비슷하게 잡는다. 반올림·padding 상수를 생략한 근사에서

$$
K\approx S\approx\frac{2L}{K}
\quad\Longrightarrow\quad
K^2\approx2L
\quad\Longrightarrow\quad
K\approx\sqrt{2L}
$$

이다. 예시에서는 $$2L/K=64{,}000/250=256$$이므로 $$S=257$$이고, 균형점은 $$\sqrt{64{,}000}\approx253$$ frames다. Chunk 250과 chunk 수 257은 비슷한 규모다.

이 근사는 chain 길이에 대한 설명이다. 한 block에는 intra의 $$S$$개 chain과 inter의 $$K$$개 chain이 있으므로 각각 $$KS$$개 step을 처리한다. Hidden 크기를 고정해도 $$KS\approx2L$$이지 $$\sqrt L$$이 아니다. 실제 연산량·메모리·지연에는 overlap, hidden 크기, block 수와 병렬화가 추가된다. 다른 hop·padding을 쓰면 chunk 개수 식도 다시 계산해야 한다.

근거: <a href="https://arxiv.org/pdf/1910.06379" target="_blank" rel="noopener">DPRNN 원 논문 §II-A–B와 Figure 1</a>.

</details>

### 6.3 SepFormer: dual-path 틀에서 RNN을 self-attention으로 바꾼다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-17.png" alt="SepFormer가 intra-transformer와 inter-transformer를 반복하여 짧은 구간과 전체 발화 문맥을 결합하는 구조" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=17" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 17</a>에서 encoder와 decoder의 뼈대는 Conv-TasNet 계열과 비슷하다. Separator 안에서 RNN 대신 두 종류의 Transformer block을 사용한다.

- Intra-Transformer는 chunk 내부 frame의 관계를 읽는다.
- Inter-Transformer는 여러 chunk에 걸친 관계를 읽는다.
- 반복 block 뒤에서 source별 mask를 만들고 decoder로 waveform을 복원한다.

Self-attention은 두 위치가 멀어도 한 attention layer에서 직접 연결할 수 있다. 반면 계산량과 memory가 sequence 길이에 민감하고, 표준 bidirectional attention은 미래 frame도 본다. 따라서 SepFormer도 별도의 causal mask·chunk schedule 없이 기본적으로 실시간 streaming model이라고 볼 수 없다.

원문 p. 18의 22.3 dB SI-SNR improvement는 dynamic mixing을 사용한 특정 WSJ0-2mix 조건의 보고값이다. 다른 dataset, sample rate, speaker 수, data augmentation 또는 metric의 절대값과 직접 순위를 만들지 않는다.

## 7. TF-GridNet: 복소 STFT를 시간과 주파수 양쪽에서 읽는다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-20.png" alt="TF-GridNet이 complex STFT 입력을 intra-frame full-band, sub-band temporal, cross-frame attention으로 처리하는 구조" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=20" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 20</a>의 TF-GridNet은 waveform latent mask가 아니라 complex STFT의 real·imaginary channel을 입력으로 받고, source의 complex spectrum을 직접 추정하는 **complex spectral mapping** 계열이다.

한 TF-GridNet block은 다음 세 방향을 결합한다.

1. **Intra-frame full-band:** 같은 frame 안에서 여러 frequency bin의 관계를 읽는다. Harmonic과 formant처럼 주파수축 구조를 연결한다.
2. **Sub-band temporal:** 한 주파수 부근이 시간에 따라 이어지는 모양을 읽는다. 발음의 지속성과 modulation을 포착한다.
3. **Cross-frame attention:** 멀리 떨어진 frame 사이의 문맥을 직접 결합한다.

출력은 source $$k$$의 real·imaginary spectrum $$\hat S_k^{(r)},\hat S_k^{(i)}$$로 조립되고 iSTFT를 거친다.

$$
\hat S_k(t,f)=\hat S_k^{(r)}(t,f)+j\hat S_k^{(i)}(t,f)
$$

따라서 magnitude만 고친 뒤 mixture phase를 재사용하는 방식보다 phase를 수정할 자유도가 크다. 원문에 제시된 23.5 dB SI-SDR improvement도 해당 논문의 특정 WSJ0-2mix 설정에서 DM 없이 보고된 값이다. Conv-TasNet·SepFormer의 다른 표와 비교하려면 dataset split과 metric 구현을 먼저 맞춰야 한다.

### 7.1 STFT로 돌아왔다는 말의 의미

그림 위 `Before`는 mixture magnitude에 실수 mask를 곱하고 mixture phase를 그대로 사용하는 경로다. `Now`는 source의 real·imaginary 값을 함께 예측하는 경로다. **포기했던 STFT를 다시 쓸 수 있게 만든 것이 아니라, STFT 위에서 허용하는 출력과 문맥 모델을 넓힌 변화**다. 역변환 조건을 갖춘 복소 STFT는 waveform의 시간·위상 구조를 담을 수 있다. Magnitude만 남기는 처리와 복소 STFT 자체를 같은 정보 손실로 취급하지 않는다.

원본 아래 구조도는 가운데 아래에서 위로 읽는다. Intra-frame full-band가 한 frame의 주파수 관계를 연결하고, sub-band temporal이 시간 변화를 읽은 뒤, cross-frame attention이 먼 frame 문맥을 결합한다. 세 연산은 입력 표현만 STFT로 바꾼 것이 아니라 **주파수 구조와 긴 시간 문맥을 함께 학습**하도록 설계되었다. Real·imaginary 출력 모두가 magnitude와 phase에 영향을 주므로 `실수부=크기, 허수부=위상`으로 나누어 해석하지 않는다.

### 7.2 Mask 추정이 병목이 되는 두 가지 이유

첫째는 **어떤 값을 내야 하는지 어려운 추정 문제**다. 한 T–F 칸에 여러 화자가 함께 있으면 mixture 하나만 보고 각 source의 기여를 알아야 한다. 잘못된 mask는 다른 화자를 남기거나 목표 화자까지 지운다. 둘째는 **정확한 mask를 알아도 표현이 허용하지 않는 출력**이다. Mixture phase를 고정한 실수 magnitude mask는 해당 칸의 크기만 조절하며, 다른 방향의 source complex coefficient를 만들 수 없다.

3.2절의 작성자 예제 $$S_A=1$$, $$S_B=j$$, $$X=1+j$$를 다시 보자. 정답 A의 크기는 1이고 혼합의 크기는 $$\sqrt2$$이므로 magnitude를 정확히 맞추는 mask는 $$m=1/\sqrt2$$다. 그래도 출력은 약 $$0.707+0.707j$$이며, 크기는 1이지만 정답 $$1+0j$$와 달리 위상이 45°다. Complex mask $$M=(1-j)/2$$ 또는 직접 mapping은 $$1+0j$$를 표현할 수 있다. 이는 특정 neural network가 반드시 그 값을 맞힌다는 보장이 아니라 **가능한 출력 집합의 차이**다.

<details markdown="block">
<summary markdown="span">Derivation: fixed-phase masks and complex spectral mapping</summary>

한 T–F 칸을 고정하고 선형 혼합 $$X=S_A+S_B$$를 가정한다. $$j^2=-1$$이며 이 예제의 coefficient는 정규화한 무차원 값이다. $$m\ge0$$인 magnitude mask의 복원식은

$$
\hat S_A=m\lvert X\rvert e^{j\arg X}=mX
$$

이다. $$X=1+j$$이면 $$\lvert X\rvert=\sqrt2$$, $$\arg X=\pi/4$$다. 크기를 1로 맞춘 결과는

$$
m=\frac1{\sqrt2},\qquad
\hat S_A=\frac{1+j}{\sqrt2}\ne1.
$$

더 일반적으로 어떤 실수 $$m$$도 $$m(1+j)=1$$을 만족하지 않는다. 실수부에서는 $$m=1$$, 허수부에서는 $$m=0$$이 필요해 모순이다. 반면 $$X\ne0$$일 때 이상적인 complex ratio mask는

$$
M=\frac{S_A}{X}=\frac1{1+j}=\frac{1-j}{2},\qquad
MX=\frac{(1-j)(1+j)}2=1
$$

이다. 출력이 $$\hat S=a+jb$$라면 magnitude와 phase는 각각 $$\sqrt{a^2+b^2}$$, $$\operatorname{atan2}(b,a)$$이며 둘 다 $$a,b$$를 사용한다. $$\hat S=0$$에서는 phase가 정의되지 않는다.

Complex ratio mask도 모든 입력에서 안정적인 것은 아니다. $$S_A=1$$, $$S_B=-0.99$$이면 $$X=0.01$$이고 $$M=100$$이 필요하다. $$X=0$$이면서 $$S_A\ne0$$이면 유한한 곱셈 mask로 복원할 수 없다. Direct mapping은 이 나눗셈을 강제하지 않지만, 다른 칸·frame의 문맥과 학습된 prior로 부족한 정보를 추정해야 한다. 관측 하나만으로 임의의 source가 유일하게 결정되는 것은 아니다.

</details>

따라서 `masking이 병목`이라는 말을 모든 mask의 실패로 확대하면 안 된다. Learned-feature mask, complex mask, magnitude mask는 출력 제약이 서로 다르다. <a href="https://arxiv.org/pdf/2211.12433" target="_blank" rel="noopener">TF-GridNet 원 논문</a>의 결과는 complex mapping과 시간·주파수 문맥 설계의 효과를 해당 실험에서 확인한 것이지, 모든 masking 모델에 대한 불가능성 증명은 아니다.

## 8. 정확도만큼 중요한 효율

원문 p. 21은 SepReformer, TIGER, SepMamba처럼 계산량과 긴 sequence 처리를 개선하려는 흐름을 묶는다. 모델 비교에서 parameter 수 하나만 보면 부족하다.

| 기준 | 묻는 질문 |
|---|---|
| Parameters | 저장·전송해야 할 weight가 얼마나 큰가? |
| MACs / FLOPs | 한 길이의 입력에 연산이 얼마나 필요한가? |
| Peak memory | 긴 입력과 intermediate activation을 처리할 수 있는가? |
| Real-time factor | 1초 audio를 1초보다 빨리 처리하는가? |
| Algorithmic latency | 출력 전에 미래 입력을 얼마나 기다리는가? |
| Quality | 같은 dataset·speaker 수·metric에서 분리가 얼마나 정확한가? |

TIGER 논문의 비교 설정에서 TIGER-large는 0.82M parameters와 15.27 GMAC/s, 재구현한 TF-GridNet은 14.43M과 323.75 GMAC/s로 보고된다. 이 두 행에서 계산한 감소율은 각각 94.3%, 95.3%다. 이 비율을 모든 TF-GridNet variant, 입력 길이, 장치, implementation의 속도 향상으로 그대로 읽을 수는 없다.

SepMamba는 SepFormer의 attention block 하나만 바꾼 구조가 아니다. Raw-waveform U-Net의 multi-scale stage에 주로 bidirectional Mamba layer를 배치해 Transformer attention 없이 긴 문맥을 모델링한다. 기본 bidirectional configuration은 미래 문맥을 사용하며 causal variant는 별도 구성이다. SepReformer-L+DM의 25.4 dB SI-SNR improvement도 synthetic WSJ0-2mix 조건의 보고값이다. 이를 benchmark의 수학적 포화로 단정하기보다, 정확도와 함께 효율·real-world generalization을 평가할 필요가 커졌다는 신호로 읽는다.

## 9. Source 수를 모를 때

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-22.png" alt="출력이 두 개인 separator에 한 명, 두 명, 세 명 입력이 들어올 때 빈 출력 또는 병합이 생기는 speaker-count 원본 도식" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=22" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 22</a>는 위에서 아래로 입력 화자를 한 명·두 명·세 명으로 바꾸면서 separator 출력은 둘로 고정한다. 한 명이면 두 번째 출력을 어떻게 처리할지 정해야 하고, 세 명이면 세 개의 개별 파형을 두 slot에 모두 담을 수 없다. 그림의 마지막 `B+C merged`는 이 불일치를 설명하는 예시이며 모델이 반드시 B와 C를 합친다는 법칙은 아니다.

**이 그림의 $$N=2$$는 output 개수로, DPRNN Segmentation 그림의 feature 채널 $$N$$과 뜻이 다르다.** 여기서 source 수를 $$K$$라 할 때, 현실의 $$K$$는 알려져 있지 않고 시간에 따라 바뀔 수 있다. 이 $$K$$는 6절의 chunk length $$K$$와 다른 기호이며, 그 절에서 $$C$$로 구분한 output-source count와 같은 역할이다. 다음 세 가지를 구분해야 한다.

- PIT, TasNet, Conv-TasNet, DPRNN, SepFormer의 대표적인 benchmark 구성은 **정해진 출력 수**를 사용한다.
- DPCL은 clustering 수를 추론 때 바꿀 수 있어 고정 output slot의 예외다. 하지만 k-means에 사용할 $$K$$는 여전히 주거나 추정해야 한다.
- “모든 분리 모델이 fixed output”이라고 일반화할 수 없다. Recursive, attractor, query-based, generative formulation도 존재한다.

### 9.1 두 화자는 DPRNN의 구조적 상한이 아니다

16쪽의 `2 speakers tried`는 원 DPRNN 논문이 두 화자 WSJ0-2mix에서 실험했다는 뜻이다. Encoder feature가 $$N$$개라는 사실이나 intra/inter라는 두 경로는 source가 두 명이어야 한다는 조건이 아니다. 출력 mask·decoder를 세 source에 맞추고 세 화자 데이터와 PIT로 학습하면 세 출력 구성을 설계할 수 있다. **이미 학습된 두 출력 모델이 자동으로 세 화자를 분리한다는 뜻은 아니다.**

실제로 <a href="https://arxiv.org/pdf/1809.07454" target="_blank" rel="noopener">Conv-TasNet Table V</a>는 별도의 세 화자 WSJ0-3mix 실험을 보고한다. 이후 <a href="https://arxiv.org/abs/2011.12022" target="_blank" rel="noopener">Multi-Decoder DPRNN</a>은 source-count head와 여러 decoder를 이용해 최대 다섯 화자를 평가했다. 이는 원 DPRNN이 같은 설정에서 다섯 화자를 검증했다는 뜻은 아니다. 화자 수가 늘수록 중첩 모호성과 계산 부담도 커지므로 출력 수 변경만으로 품질이 유지된다고 보장할 수 없다.

### 9.2 출력 수를 정하거나 유동적으로 생성한다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-23.png" alt="최대 출력 수, recursive one-and-rest, source-count prediction으로 알 수 없는 source 수를 다루는 세 접근" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=23" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 23</a>의 세 접근을 비교하면 다음과 같다.

| 접근 | 동작 | 장점 | 주의점 |
|---|---|---|---|
| Maximum outputs + silence | 최대 $$K_{\max}$$개를 내고 남는 출력을 silence로 학습 | 한 번의 forward pass | 최대값 고정, silence 판정 필요 |
| Recursive one-and-rest | source 하나와 나머지 mixture를 예측하고 나머지를 다시 분리 | 출력 수를 유동적으로 늘릴 수 있음 | Residual 오차가 후속 단계로 전파될 수 있음. 정지 조건과 반복 안정성 점검 필요 |
| Count then separate | Source-count head가 $$K$$를 예측하고 해당 decoder를 선택 | 여러 $$K$$에 최적화된 head 사용 가능 | Count가 틀리면 separation 단계도 틀림 |

그림 오른쪽의 count-and-select 구조는 Zhu, Yeh, Hasegawa-Johnson의 Multi-Decoder DPRNN이다. MulCat backbone에 count head와 source 수별 decoder head를 둔다. Source 수마다 별도 model을 고르는 Nachmani 등의 접근과는 구분한다.

가운데 OR-PIT 그림은 첫 단계에서 한 화자와 `나머지 화자가 섞인 파형`을 함께 예측하고, 다음 단계가 그 **예측 residual**을 입력으로 받는 흐름이다. 단순히 각 source의 개수를 세 번으로 늘리는 fixed-slot 구조와 달리, 이전 단계의 결과가 다음 입력을 바꾼다. <a href="https://arxiv.org/abs/1904.03065" target="_blank" rel="noopener">원 논문</a>은 두·세 화자 학습과 학습에 없던 네 화자 조건의 일반화도 확인한다. 이 결과가 무제한 화자 수나 모든 실제 녹음에서의 정지 정확성을 보장하지는 않는다.

### 9.3 오차 전파와 화자 수 불일치는 다른 문제다

다음은 오차 전파를 보기 위한 **작성자 수치 예제**다. 한 시점의 값이 $$A=2$$, $$B=3$$, $$C=5$$여서 혼합 $$x=10$$이라고 하자. 첫 추정이 A에 B의 10%를 잘못 섞어 $$\hat A=2.3$$이면, 뺄셈형 residual은 $$10-2.3=7.7$$이다. 정답 나머지 $$B+C=8$$보다 0.3 작으며, 다음 단계는 이미 일부 B가 사라진 입력을 받는다. 실제 OR-PIT은 나머지 파형도 신경망으로 직접 예측하므로 이 뺄셈식이 구현 자체는 아니다. 공통점은 **첫 단계 residual의 누락·누출이 다음 입력에 들어간다**는 의존 관계다.

<details markdown="block">
<summary markdown="span">Derivation: residual error propagation in recursive separation</summary>

선형 혼합 $$x=A+B+C$$에서 첫 source 추정이 $$\hat A=A+e$$라고 하자. 뺄셈형 residual을 정의하면 정확한 항등식으로

$$
r=x-\hat A=B+C-e
$$

다. $$e=0.1B$$라면 $$r=0.9B+C$$이며, $$B=3$$인 수치 예제에서는 B의 기여가 3에서 2.7로 줄어든다. 반대로 $$e$$가 A의 누락을 나타내면 residual에 A가 남아 중복 추출될 수 있다.

Residual을 직접 예측하는 모델에서는 $$\hat r=B+C+e_r$$로 오차를 정의한다. 다음 분리기 $$F$$는 정답 $$B+C$$가 아닌 $$\hat r$$를 받는다. 이후 오차의 크기와 부호는 $$F$$와 입력에 따라 달라지므로, 단계마다 같은 양이 더해진다거나 반드시 단조 증가한다고 결론내릴 수 없다. 정지 오판·누출·누락을 단계별로 평가해야 한다.

</details>

세 명 이상에서 겪는 어려움도 나누어 봐야 한다. 두 출력에 세 정답을 담지 못하는 것은 **출력 수 불일치**, 동시에 말하는 신호를 구분하기 어려운 것은 **분리의 모호성**, 반복 residual이 다음 입력을 손상시키는 것은 **재귀 오차 전파**다. Fixed-output DPRNN을 한 번 실행하는 것에 재귀 누적이 자동으로 생기지는 않는다. One-and-rest의 반복 안정성과 종료 기준을 개선하거나, 한 번에 여러 출력을 예측하는 구성을 비교해 어느 실패인지 확인해야 한다.

PIT의 모든 순열 열거는 $$K!$$이지만, pairwise cost 이후 Hungarian assignment의 일반적 계산량은 $$O(K^3)$$이다. Source 수가 커질수록 cost matrix 생성, assignment, separator 자체가 모두 커질 수 있으므로 이 세 부분을 구분한다.

### 9.4 Open Problem은 무엇을 풀도록 문제를 다시 정하는가

목표는 단순히 `두 화자 점수를 더 높인다`에서 **알 수 없는 수의 source를 실제 녹음에서 빠짐없이 복원한다**로 넓어진다. 입력은 noise·reverberation을 포함할 수 있는 mixture다. 출력은 추정 source 수와 그에 대응하는 파형 집합이며, recursive 방식이면 source 수 대신 종료 판정이 이 역할을 맡을 수도 있다.

평가도 함께 바뀐다. Source 수가 맞은 사례의 SI-SDR만 볼 것이 아니라, count가 틀린 경우, 누락·중복·한 화자의 과분할·여러 화자의 병합을 포함해야 한다. 긴 녹음에서는 구간 사이 source identity가 유지되는지도 별도로 확인한다. 실제 clean target을 얻기 어렵다는 supervision 문제는 다음 절의 DM·MixIT로 이어지지만, DM이나 MixIT 자체가 source counting까지 자동 해결하지는 않는다.

## 10. Synthetic mixture에서 실제 녹음으로

### 10.1 왜 benchmark 점수가 실제 환경을 보장하지 않는가

WSJ0-2mix 같은 dataset은 깨끗한 single-speaker utterance를 정해진 규칙으로 섞어 mixture와 exact source target을 만든다. 실제 회의·통화·거리 녹음에는 다음 차이가 있다.

- Room impulse response와 reverberation
- 마이크 주파수 응답·비선형 distortion·clipping
- 화자 위치와 음량의 시간 변화
- 겹침 비율과 source 수 변화
- Clean source를 따로 녹음할 수 없다는 supervision 문제

따라서 synthetic test의 SI-SDR improvement만으로 real-world robustness를 결론내리지 않는다. 원문 p. 24의 WHAM!, WHAMR!, LibriMix, LRS2-2Mix, REAL-M 같은 dataset은 noise, reverberation, audiovisual cue 또는 실제 녹음 조건을 단계적으로 추가한다.

### 10.2 Dynamic Mixing은 조합을 늘리지만 clean source가 필요하다

<img src="/assets/images/study/speech-and-audio-recognition/lecture-07/slide-25.png" alt="왼쪽 Dynamic Mixing와 MixIT 설명 및 오른쪽 PIT permutation과 MixIT remix의 비교도" loading="lazy">

<a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf#page=25" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 25</a>의 왼쪽 Dynamic Mixing(DM)은 미리 저장한 제한된 mixture만 반복하지 않는다. 학습 중 서로 다른 clean utterance를 뽑고, 구간·gain·상대 위치를 바꾸어 새 mixture를 만든다.

$$
x=a_1s_1+a_2s_2
$$

조합 수가 매우 커지고 overfitting을 줄일 수 있지만, $$s_1,s_2$$를 clean하게 가지고 있어야 한다. “Infinite mixtures”는 수학적으로 무한한 dataset이라는 뜻보다, 학습 중 on-the-fly로 매우 많은 조합을 생성한다는 의미로 읽는 편이 정확하다.

### 10.3 MixIT는 clean component 대신 mixture 두 개를 target으로 쓴다

MixIT(Mixture Invariant Training)는 clean single source가 없는 두 mixture $$x_1,x_2$$를 다시 더한다.

$$
\bar x=x_1+x_2
$$

Model이 $$M$$개 latent output $$\hat s_1,\ldots,\hat s_M$$을 만들면, 이 출력들을 두 그룹으로 나누어 각각 $$x_1,x_2$$를 가장 잘 재구성하는 assignment를 찾는다. 예를 들어 출력이 $$[1,2,4]$$이고 target mixture가 $$[3,4]$$인 scalar toy example에서는 첫 두 출력을 합쳐 3을, 마지막 출력을 4에 배정하면 reconstruction error가 0이다. 각 latent output의 clean 정답은 필요하지 않다.

<details markdown="block">
<summary markdown="span">Derivation: MixIT assignment objective</summary>

Binary assignment matrix를 $$A\in\{0,1\}^{2\times M}$$라 하자. 각 model output은 두 target mixture 중 하나에 한 번 배정되므로

$$
\sum_{i=1}^{2}A_{im}=1
$$

이다. Grouped reconstruction은

$$
\hat x_i=\sum_{m=1}^{M}A_{im}\hat s_m
$$

이고 loss는

$$
\mathcal{L}_{\mathrm{MixIT}}
=\min_A\sum_{i=1}^{2}\ell(x_i,\hat x_i)
$$

다. Supervision target은 clean component가 아니라 원래의 두 mixture다. Model이 한 실제 source를 여러 출력으로 과도하게 쪼개도 다시 그룹화해 mixture를 맞출 수 있으므로 **over-separation**이 발생할 수 있다. 가능한 assignment 수가 출력 수와 함께 빠르게 늘어나는 계산 문제도 있다.

</details>

## 11. Generative separation은 무엇을 바꾸는가

일반적인 discriminative separator는 mixture $$x$$에 대해 하나의 예측 $$\hat s_{1:K}$$를 낸다. 생성 모델은 가능한 clean source 조합의 conditional distribution을 근사하려 한다.

$$
p(s_1,\ldots,s_K\mid x)
$$

DiffSep과 EDSep은 diffusion/score-based 과정을 이용해 noisy state에서 source estimate를 반복적으로 정제한다. 원문 p. 26의 왼쪽 pipeline은 EDSep만의 novelty 그림이 아니라 EDSep이 DiffSep에서 이어받아 background로 설명하는 SDE 기반 분리 흐름이다. EDSep의 고유 기여는 denoiser·training objective와 stochastic sampler이며, 논문은 30 prediction steps를 사용한다. 저자들도 당시 최고 discriminative separator와의 성능 차이가 남는다고 구분한다.

원문 p. 26의 Geneses는 2026년 preprint로 소개된 흐름이며, latent flow matching으로 enhancement와 separation을 결합한다. 실험 범위는 simulated two-speaker LibriTTS-R의 noise-only와 complex-degradation 조건이다. Complex degradation에서는 비교 mask baseline보다 강한 결과를 보였지만, noise-only의 일부 WER·spectral/cepstral metric에서는 열세였고 content change 또는 drop 위험도 보고한다. 하나의 표로 모든 환경의 우월성을 일반화하지 않는다.

생성 모델의 장점은 심한 degradation에서 한 개의 점 추정에 묶이지 않고, 학습한 speech prior를 이용해 지각적으로 자연스러운 후보를 만들 가능성이 있다는 점이다. 동시에 생성된 세부가 실제 source에 존재했다는 보장은 없다. Identity drift, content change·drop, 반복 sampling 비용을 확인해야 하며, perceptual quality와 source fidelity를 따로 평가한다. 이 trade-off는 model·objective·dataset에 따라 달라진다.

<details markdown="block">
<summary markdown="span">Derivation: point estimate and conditional distribution</summary>

Squared waveform loss로 하나의 출력만 학습한다고 가정하자. $$\mu(x)=\mathbb{E}[S\mid X=x]$$라 두면 조건부 squared error는 다음처럼 분해된다.

$$
\begin{aligned}
\mathbb{E}[\|S-f(x)\|_2^2\mid x]
&=\mathbb{E}[\|S-\mu(x)+\mu(x)-f(x)\|_2^2\mid x]\\
&=\mathbb{E}[\|S-\mu(x)\|_2^2\mid x]+\|\mu(x)-f(x)\|_2^2.
\end{aligned}
$$

교차항은 $$\mathbb{E}[S-\mu(x)\mid x]=0$$이므로 사라진다. 첫 항은 $$f$$와 무관하고, 두 번째 항은 $$f(x)=\mu(x)$$일 때 최소다. 따라서 이상적인 무한용량 조건에서

$$
f^\ast(x)=\arg\min_f\mathbb{E}\!\left[\left\|S-f(X)\right\|_2^2\mid X=x\right]
=\mathbb{E}[S\mid X=x]
$$

가능한 source 조합이 여러 개인 상황에서 평균은 어느 실제 해와도 다를 수 있다. Generative model은 $$p(S\mid X=x)$$ 자체를 근사해 여러 plausible sample을 표현하려 한다. 그러나 “그럴듯함”은 “실제 녹음의 정확한 원인”과 같지 않다. Mixture consistency, speaker identity, ASR 성능 같은 조건을 추가로 검증해야 한다.

</details>

## 모델 흐름을 한 표로 정리하기

아래 표에는 architecture와 training rule이 함께 나오므로 첫 열의 역할부터 구분한다. PIT·uPIT는 독립 network가 아니며, 다른 separator의 출력과 정답을 연결하는 규칙이다.

| Method 또는 rule | Representation | Separation mechanism | Permutation handling | 핵심 한계 |
|---|---|---|---|---|
| DPCL | STFT T–F embedding | k-means → binary masks | Affinity target 자체가 순서 불변 | $$K$$ 필요, clustering 분리, mixture phase |
| PIT / uPIT | Model에 따라 다름 | 여러 output | 최소-cost assignment | 보통 출력 수 고정, ID 지속성 별도 |
| TasNet | Learned waveform basis | Latent masks + recurrent separator | PIT | 긴 sequence 계산 |
| Conv-TasNet | Learned waveform basis | Dilated TCN masks | PIT | Receptive field·causality 설정 의존 |
| DPRNN | Learned waveform basis | Intra/inter chunk RNN masks | PIT | 표준형 bidirectional, chunk 계산 |
| SepFormer | Learned waveform basis | Intra/inter Transformer masks | PIT | Attention memory, 표준형 offline |
| TF-GridNet | Complex STFT | Complex spectral mapping | PIT 계열 assignment | 계산량·memory, 구현 복잡성 |
| MixIT | Waveform 또는 learned representation | 여러 latent outputs의 regrouping | Mixture-level assignment | Over-separation, assignment 비용 |
{: .reference-candidate-table}

## 마지막 핵심 정리

- **BSS의 첫 난점은 출력 순서다.** 같은 source set도 output index가 바뀔 수 있다.
- **DPCL은 화자 번호가 아니라 T–F 칸 사이의 같은-source 관계를 배운다.** 추론 때 clustering 수를 바꿀 수 있지만 $$K$$는 여전히 필요하다.
- **PIT는 one-to-one 대응 중 최소 손실을 선택한다.** 모든 순열 열거는 $$K!$$, 일반 Hungarian assignment는 $$O(K^3)$$이다.
- **DPCL과 PIT는 대안이고, uPIT는 PIT의 utterance-level 확장이다.** PIT·uPIT는 architecture가 아니라 output–target 대응을 정하는 training criterion이다.
- **Time-domain separation도 mask를 쓴다.** 적용 대상이 STFT magnitude에서 학습된 waveform basis로 이동한다.
- **Conv-TasNet은 recurrent separator를 TCN으로 바꾼다.** 같은 WSJ0-2mix 표에서 비인과 SI-SNRi는 13.2 대 15.3 dB지만, 인과 비교는 10.8 대 10.6 dB다. 설정과 효율을 함께 읽는다.
- **DPRNN 그림의 N은 feature, L은 전체 frames다.** Intra는 chunk 내부 K축, inter는 chunk 사이 S축을 읽는다. 두 경로가 화자 두 명을 뜻하지 않는다.
- **DPRNN과 SepFormer는 기본형이 자동으로 streaming-ready인 것은 아니다.** Bidirectional recurrence나 full attention의 미래 참조를 확인해야 한다.
- **TF-GridNet은 complex STFT를 직접 추정한다.** Time-domain model의 성공은 STFT 자체의 원리적 한계를 뜻하지 않는다.
- **두 화자 benchmark는 화자 수의 구조적 상한이 아니다.** Unknown count와 재귀 residual의 오차 전파는 별도로 해결·평가해야 한다.
- **실제 환경에서는 source 수, reverberation, clean target 부재가 함께 문제다.** DM과 MixIT는 같은 해결책이 아니다.
- **생성 모델은 가능한 해의 분포를 다루지만 실제 source 충실도를 자동으로 보장하지 않는다.**

## Study Guide

먼저 2절의 permutation problem을 이해한 뒤 3절의 DPCL affinity와 4절의 PIT 수치 예제를 비교한다. DPCL은 output slot을 없애고 embedding cluster를 만들며, PIT는 output slot을 유지한 채 정답 대응을 바꾼다.

그다음 5–7절에서 `representation → context model → separation output → decoder` 순서로 각 그림을 읽는다. Architecture 이름보다 mask가 적용되는 대상, phase 수정 가능 여부, 미래 frame 참조 여부를 먼저 확인하면 모델 차이가 선명해진다. 마지막으로 9–11절에서 고정된 $$K$$와 synthetic supervision이라는 benchmark 가정이 현실에서 어떻게 깨지는지 살펴본다.

## 복습 질문

<details markdown="block">
<summary>1. 두 화자의 출력 순서가 바뀌면 분리 결과가 틀린 것인가?</summary>

답변: 아니다. 두 출력에 같은 source set이 복원되었다면 순서는 임의일 수 있다. 문제는 고정 label 순서로 loss를 계산할 때 올바른 예측에도 큰 오차를 주는 것이다. DPCL은 affinity로, PIT는 최소-cost assignment로 이를 해결한다.

</details>

<details markdown="block">
<summary markdown="span">2. DPCL에서 화자 label을 바꾸어도 loss가 같은 이유는 무엇인가?</summary>

답변: Target이 label 자체가 아니라 $$YY^\mathsf{T}$$이기 때문이다. Label의 열을 permutation matrix $$P$$로 바꾸어도 $$YPP^\mathsf{T}Y^\mathsf{T}=YY^\mathsf{T}$$다.

</details>

<details markdown="block">
<summary>3. DPCL은 source 수를 자동으로 찾는가?</summary>

답변: 원형 DPCL은 추론 때 cluster 수를 바꿀 수 있지만 k-means에 사용할 $$K$$가 필요하다. 두 화자로 학습한 embedding이 세 화자로 일반화될 수 있다는 것과 source 수를 자동 추정한다는 것은 다르다.

</details>

<details markdown="block">
<summary markdown="span">4. PIT cost가 $$[[9,1],[2,8]]$$이면 어떤 대응을 고르는가?</summary>

답변: A→2, B→1을 고른다. 합은 $$1+2=3$$이고 평균은 $$1.5$$다. 반대 대응의 합 17, 평균 8.5보다 작다.

</details>

<details markdown="block">
<summary markdown="span">5. PIT의 복잡도를 무조건 $$K!$$이라고 해야 하는가?</summary>

답변: 모든 permutation을 직접 열거하면 $$K!$$이다. Pairwise cost로 선형 assignment를 구성할 수 있으면 Hungarian algorithm의 일반 시간복잡도는 $$O(K^3)$$이다. Cost matrix 생성 비용과 separator 계산도 별도로 센다.

</details>

<details markdown="block">
<summary>6. Conv-TasNet은 STFT를 쓰지 않으므로 masking도 하지 않는가?</summary>

답변: 아니다. Learned waveform encoder가 만든 latent coefficient에 source별 mask를 곱한다. Masking의 대상 표현이 바뀐 것이다.

</details>

<details markdown="block">
<summary>7. DPRNN과 SepFormer가 자동으로 실시간 모델이 아닌 이유는 무엇인가?</summary>

답변: 표준 DPRNN은 bidirectional RNN을, 표준 SepFormer는 양방향 self-attention을 사용해 미래 frame을 참조할 수 있다. Streaming에는 causal path, 제한된 look-ahead, state와 chunk boundary 처리가 추가로 필요하다.

</details>

<details markdown="block">
<summary>8. Time-domain model이 oracle magnitude mask를 넘으면 STFT가 열등하다는 뜻인가?</summary>

답변: 아니다. 그 oracle은 보통 mixture phase를 고정하고 magnitude mask만 바꾸는 제한된 조건이다. Complex spectral mapping은 STFT domain에서도 real·imaginary 값을 직접 추정해 phase를 수정할 수 있다.

</details>

<details markdown="block">
<summary>9. Dynamic Mixing과 MixIT의 supervision 차이는 무엇인가?</summary>

답변: DM은 clean source를 알고 이를 여러 방식으로 다시 섞는다. MixIT는 clean component 대신 두 mixture를 알고, model의 latent outputs을 두 그룹으로 묶어 원래 mixture를 복원하도록 학습한다.

</details>

<details markdown="block">
<summary>10. 생성 분리 모델의 결과가 더 자연스러우면 실제 source에도 더 충실한가?</summary>

답변: 반드시 그렇지 않다. Speech prior가 plausible detail을 만들 수 있지만 실제 mixture의 원인과 다른 detail일 수 있다. Perceptual quality와 mixture consistency, identity, intelligibility를 함께 평가해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-07-v2.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture7_v2.pdf — Source Separation 2</a></li>
</ul>

## References

<ul>
  <li><a href="https://github.com/yandexdataschool/speech_course" target="_blank" rel="noopener">Yandex Data School Speech Course</a> — source course linked by the lecture.</li>
  <li><a href="https://github.com/markovka17/dla" target="_blank" rel="noopener">Deep Learning for Audio</a> — source course linked by the lecture.</li>
  <li><a href="https://arxiv.org/abs/1508.04306" target="_blank" rel="noopener">Hershey et al.: Deep Clustering</a> — affinity-based embeddings and clustering.</li>
  <li><a href="https://arxiv.org/abs/1607.00325" target="_blank" rel="noopener">Yu et al.: Permutation Invariant Training</a> — minimum-permutation training objective.</li>
  <li><a href="https://arxiv.org/abs/1703.06284" target="_blank" rel="noopener">Kolbæk et al.: Utterance-Level Permutation Invariant Training</a> — utterance-level assignment.</li>
  <li><a href="https://arxiv.org/abs/1711.00541" target="_blank" rel="noopener">Luo and Mesgarani: TasNet</a> — learned time-domain audio representation.</li>
  <li><a href="https://arxiv.org/abs/1809.07454" target="_blank" rel="noopener">Luo and Mesgarani: Conv-TasNet</a> — convolutional time-domain separation network.</li>
  <li><a href="https://arxiv.org/abs/1910.06379" target="_blank" rel="noopener">Luo, Chen, and Yoshioka: Dual-Path RNN</a> — intra/inter-chunk sequence modeling.</li>
  <li><a href="https://arxiv.org/abs/2010.13154" target="_blank" rel="noopener">Subakan et al.: SepFormer</a> — dual-path Transformer separation.</li>
  <li><a href="https://arxiv.org/abs/2211.12433" target="_blank" rel="noopener">Wang et al.: TF-GridNet</a> — integrated full-band, sub-band, and attention modeling.</li>
  <li><a href="https://arxiv.org/abs/2410.01469" target="_blank" rel="noopener">Xu et al.: TIGER</a> — efficient time-frequency speech separation.</li>
  <li><a href="https://proceedings.neurips.cc/paper_files/paper/2024/file/5d7c739c8e0383d02bb0addf8f29cd19-Paper-Conference.pdf" target="_blank" rel="noopener">Shin et al.: Separate and Reconstruct</a> — SepReformer and its WSJ0-2mix evaluation.</li>
  <li><a href="https://arxiv.org/abs/2410.20997" target="_blank" rel="noopener">Avenstrup et al.: SepMamba</a> — U-Net-based bidirectional state-space separation and causal variants.</li>
  <li><a href="https://arxiv.org/abs/2011.12022" target="_blank" rel="noopener">Zhu, Yeh, and Hasegawa-Johnson: Multi-Decoder DPRNN — High Accuracy Source Counting and Separation</a> — source-count head and multiple decoder heads.</li>
  <li><a href="https://arxiv.org/abs/1904.03065" target="_blank" rel="noopener">Takahashi et al.: Recursive Speech Separation for Unknown Number of Speakers</a> — one-and-rest PIT and recursive residual prediction.</li>
  <li><a href="https://proceedings.mlr.press/v119/nachmani20a.html" target="_blank" rel="noopener">Nachmani et al.: Voice Separation with an Unknown Number of Multiple Speakers</a> — selecting among source-count-specific separation models.</li>
  <li><a href="https://arxiv.org/abs/2006.12701" target="_blank" rel="noopener">Wisdom et al.: Unsupervised Sound Separation Using Mixture Invariant Training</a> — MixIT objective.</li>
  <li><a href="https://arxiv.org/abs/2106.00847" target="_blank" rel="noopener">Wisdom et al.: Sparse Mixture Invariant Training</a> — over-separation and assignment complexity.</li>
  <li><a href="https://arxiv.org/abs/2210.17327" target="_blank" rel="noopener">Scheibler et al.: Diffusion-Based Generative Speech Source Separation</a> — DiffSep.</li>
  <li><a href="https://arxiv.org/abs/2501.15965" target="_blank" rel="noopener">EDSep: Efficient Diffusion-Based Speech Separation</a> — efficient diffusion separation.</li>
  <li><a href="https://arxiv.org/abs/2601.18456" target="_blank" rel="noopener">Geneses preprint</a> — generative separation trend cited by the lecture; treated as a 2026 preprint rather than an established benchmark.</li>
</ul>

## Source Check

- 원본 PDF 26쪽을 모두 시각 확인하고, 추출 텍스트는 페이지 탐색 보조로만 사용했다.
- 원문 p. 9의 DPCL 설명은 affinity loss의 label-permutation 불변성과 효율적 전개를 원 논문에 맞춰 보충했다.
- 원문 p. 22의 Hungarian `K²` 표기는 일반적인 linear assignment의 시간복잡도 $$O(K^3)$$으로 정정했다. Pairwise cost 생성과 모든 순열 열거 비용은 별도로 구분했다.
- “모든 모델은 고정 출력 수”라는 해석은 대표적인 PIT/time-domain benchmark 구성으로 범위를 제한했다. DPCL은 추론 cluster 수를 바꿀 수 있지만 $$K$$를 주거나 추정해야 한다.
- DPRNN 기본형을 streaming-ready로 일반화하지 않았다. 원 논문의 bidirectional path와 causal variant의 조건을 구분했다.
- Time-domain model과 oracle magnitude mask의 비교는 fixed magnitude-mask와 mixture-phase 제약에 대한 결과로 해석했다. STFT 표현 자체의 원리적 한계로 확대하지 않았다.
- 원문 p. 19의 수치 표는 causal/noncausal configuration과 SI-SNRi/SDRi가 섞여 있다. 5.3절에서 Conv-TasNet Table IV의 네 행을 설정별로 분리해 재작성하고, TasNet-BLSTM의 23.6M/13.2와 causal LSTM의 32.0M/10.8을 정정했다. Representation, objective, decoder, separator가 세대별로 함께 달라졌음을 구분했다.
- 16쪽 그림의 $$N$$은 feature 차원, $$L$$은 전체 시간 frames다. 기존 해설에서 시간 길이를 $$N$$으로 적은 혼동을 바로잡고, chunk 길이 $$K$$·hop $$P$$·chunk 수 $$S$$를 원 논문에 맞췄다. 22쪽의 output 수 $$N$$과도 구분했다. 제곱근 규모는 recurrent chain 길이에 관한 근사이지 전체 FLOPs의 주장이 아니다.
- 원 DPRNN의 두 화자 실험 범위와 구조적 상한을 분리했다. OR-PIT의 learned residual과 설명용 뺄셈 residual을 구분하고, 재귀 오차가 언제나 단조 누적된다고 일반화하지 않았다.
- 원문 p. 21의 TIGER 감소율, SepMamba의 bidirectional 기본형, SepReformer 25.4 dB는 각각의 비교 configuration과 dataset 범위 안에서만 해석했다.
- 원문 p. 26의 diffusion pipeline은 EDSep 고유 novelty로 오인하지 않도록 DiffSep 계열 background와 EDSep의 denoiser·sampler 기여를 분리했다.
- 모델 성능 수치는 dataset, speaker 수, augmentation, metric 조건이 같은 경우에만 직접 비교하도록 구분했다.
- 공개 글은 원문 PDF와 논문을 설명·검증한 독립 해설이며, 원본 슬라이드의 표·문장을 장문 전재하지 않았다.
