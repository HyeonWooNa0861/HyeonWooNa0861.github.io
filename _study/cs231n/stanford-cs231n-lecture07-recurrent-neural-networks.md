---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 7: Recurrent Neural Networks"
course: "CS231N"
topic: "Recurrent Neural Networks"
order: 7
major_topic: "Computer Vision"
keywords:
  - "RNN"
  - "LSTM"
  - "Sequence Modeling"
  - "Vanishing Gradients"
  - "Captioning"
---

# Stanford CS231N Lecture 7: Recurrent Neural Networks

Source: [Stanford CS231N Spring 2025 Lecture 7](https://www.youtube.com/watch?v=kG2lAPBF7zA){:target="_blank" rel="noopener"}

Official slides: [Lecture 7 PDF](https://cs231n.stanford.edu/slides/2025/lecture_7.pdf){:target="_blank" rel="noopener"}

> **핵심:** RNN은 같은 transition function을 시간축에 반복 적용해 가변 길이 시퀀스를 처리한다. 이 공유 구조는 강력하지만 긴 경로에서 같은 Jacobian을 반복 곱하므로 vanishing/exploding gradient가 생기며, LSTM은 additive cell-state path와 gate로 장기 정보 흐름을 개선한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Sequence modeling | 고정 길이 입출력을 어떻게 가변 길이로 확장하는가? |
| 2 | Vanilla RNN | hidden state는 과거 정보를 어떻게 요약하는가? |
| 3 | Language modeling | 다음 token 분포를 어떻게 학습하고 생성하는가? |
| 4 | Image captioning | 이미지 feature와 단어 시퀀스를 어떻게 연결하는가? |
| 5 | BPTT | 시간축에서 gradient를 어떻게 계산하는가? |
| 6 | LSTM | 장기 의존성의 gradient 문제를 어떻게 완화하는가? |

## 1. 시퀀스 문제의 형태

RNN은 하나의 입력을 하나의 출력으로 바꾸는 분류를 넘어 여러 입출력 길이를 다룬다.

| 형태 | 예시 |
|---|---|
| one-to-many | 이미지 한 장에서 caption token 생성 |
| many-to-one | 비디오 frame sequence의 action classification |
| many-to-many | 매 시점 labeling 또는 sequence translation |

중요한 것은 시퀀스 길이마다 별도 모델을 두지 않고 같은 파라미터를 모든 시점에 공유한다는 점이다.

## 2. Vanilla RNN

시점 $$t$$의 입력 $$x_t$$와 이전 hidden state $$h_{t-1}$$로 새 상태를 계산한다.

$$
h_t=\tanh(W_{hh}h_{t-1}+W_{xh}x_t+b_h)
$$

출력이 필요하면

$$
y_t=W_{hy}h_t+b_y
$$

를 사용한다. $$h_t$$는 지금까지 본 prefix의 고정 길이 요약이다. 시간축으로 펼친 그림에는 cell이 여러 개 보이지만 모두 같은 $$W_{hh},W_{xh}$$를 공유한다.

초기 상태 $$h_0$$는 0, 학습 가능한 벡터, 또는 다른 encoder의 출력으로 둘 수 있다. 이미지 captioning에서는 CNN image feature가 초기 상태나 첫 입력으로 들어갈 수 있다.

## 3. Character-level language model

각 문자나 token을 one-hot vector로 표현하고, hidden state에서 vocabulary logits을 만든 뒤 softmax로 다음 token 분포를 예측한다. 정답 다음 token의 cross-entropy를 모든 시점에서 합한다.

$$
L=\sum_{t=1}^{T}-\log p(x_{t+1}\mid x_{\le t})
$$

훈련 때는 실제 이전 token을 다음 입력으로 주는 teacher forcing을 사용할 수 있다. 생성 때는 모델이 뽑은 token을 다시 입력하며 종료 token이나 길이 제한까지 반복한다. 확률 최댓값만 고르는 greedy decoding은 단조로울 수 있고, 분포에서 sampling하면 다양한 결과를 얻지만 오류도 늘 수 있다.

## 4. Image captioning

CNN은 이미지를 spatial 또는 global feature vector로 인코딩하고 RNN은 이를 조건으로 문장을 생성한다. 시작 token에서 출발해 각 시점의 단어 분포를 예측하고, 종료 token에서 멈춘다.

이 구조는 이미지 한 장을 고정 길이 벡터로 압축하면 세부 위치 정보가 손실될 수 있다는 한계가 있다. 다음 강의의 attention은 각 단어를 생성할 때 image feature의 다른 위치를 직접 선택해 이 병목을 완화한다.

## 5. Backpropagation Through Time

RNN을 시간축으로 펼치면 일반 feedforward graph가 된다. 각 시점 손실에서 오는 gradient는 공유 파라미터에 누적된다. 이를 BPTT라고 한다.

긴 시퀀스의 gradient에는 반복 행렬곱이 포함된다.

$$
\frac{\partial h_t}{\partial h_k}
=\prod_{j=k+1}^{t}\frac{\partial h_j}{\partial h_{j-1}}
$$

Jacobian의 크기가 반복해서 1보다 작으면 vanishing, 크면 exploding gradient가 된다. Gradient clipping은 전체 norm이 임계값을 넘을 때 비례 축소해 폭주를 제어하지만, 사라진 gradient를 복구하지는 않는다.

아주 긴 시퀀스는 일정 구간만 펼쳐 업데이트하는 truncated BPTT로 계산과 메모리를 제한할 수 있다. 이는 먼 과거까지 정확히 gradient를 전달하는 능력과 비용 사이의 절충이다.

## 6. LSTM

LSTM은 hidden state와 별도로 cell state $$c_t$$를 유지한다. 한 번의 affine transform 결과를 네 부분으로 나누어 gate와 candidate를 만든다.

$$
\begin{aligned}
i_t&=\sigma(W_i[h_{t-1},x_t]+b_i)\\
f_t&=\sigma(W_f[h_{t-1},x_t]+b_f)\\
o_t&=\sigma(W_o[h_{t-1},x_t]+b_o)\\
g_t&=\tanh(W_g[h_{t-1},x_t]+b_g)\\
c_t&=f_t\odot c_{t-1}+i_t\odot g_t\\
h_t&=o_t\odot\tanh(c_t)
\end{aligned}
$$

- forget gate $$f_t$$: 이전 기억을 얼마나 유지할지 결정한다.
- input gate $$i_t$$: 새 candidate를 얼마나 기록할지 결정한다.
- output gate $$o_t$$: cell 정보를 hidden output에 얼마나 노출할지 결정한다.

Cell update가 곱셈만이 아니라 덧셈 경로를 포함해 gradient가 더 직접 흐를 수 있다. 그러나 LSTM도 긴 시퀀스 계산을 순차적으로 해야 하고 모든 장기 의존성을 완벽히 해결하지는 않는다.

## 7. RNN의 계산적 한계

$$h_t$$는 $$h_{t-1}$$가 준비되어야 계산할 수 있어 시간축 병렬화가 어렵다. 멀리 떨어진 token 사이 정보가 많은 recurrent step을 통과해야 한다. 이 두 한계가 모든 token 쌍을 직접 연결하는 self-attention으로 넘어가는 동기가 된다.

## 핵심 수식 유도

### 작성자 보충: 반복 Jacobian과 gradient 안정성

Vanilla RNN의 먼 시점 gradient는 chain rule로 Jacobian 곱 $$\partial h_t/\partial h_k=\prod_{j=k+1}^{t}J_j$$이 된다. 모든 step에서 하나의 상수 $$0\le\rho<1$$에 대해 $$\lVert J_j\rVert_2\le\rho$$라는 **uniform bound**가 있으면 submultiplicativity로

$$
\left\lVert\frac{\partial h_t}{\partial h_k}\right\rVert_2
\le\prod_{j=k+1}^{t}\lVert J_j\rVert_2
\le\rho^{t-k}\longrightarrow0
$$

이므로 vanishing이 증명된다. 반대로 각 $$\lVert J_j\rVert_2>1$$이라는 사실만으로는 expanding 방향이 step마다 달라질 수 있어 explosion이 증명되지 않는다. 예를 들어 모든 step의 최소 singular value가 하나의 $$\gamma>1$$ 이상이면 $$\lVert(\prod_jJ_j)v\rVert_2\ge\gamma^{t-k}\lVert v\rVert_2$$가 되어 폭주하는 충분조건을 얻는다. 실제 RNN에서는 product가 유지하는 방향과 activation derivative가 핵심이며, 이 설명은 norm bound에 근거한 **증명 개요**다. LSTM에서는 gate의 간접 의존 경로를 잠시 고정해 본 direct cell path에서 cell update $$c_t=f_t\odot c_{t-1}+i_t\odot g_t$$로부터 $$\partial c_t/\partial c_{t-1}=f_t$$가 생긴다. Gate와 hidden state는 보통 무차원 activation이다. $$f_t$$가 장기간 0에 가깝거나 gate가 saturation되면 LSTM도 긴 기억을 보장하지 않는다.

## 마지막 핵심 정리

- RNN은 같은 transition을 시간에 공유하며 hidden state로 prefix를 요약한다.
- Language model은 $$p(x_{t+1}\mid x_{\le t})$$를 매 시점 학습한다.
- BPTT의 반복 Jacobian 곱이 vanishing/exploding gradient를 만든다.
- LSTM의 gate와 additive cell path는 장기 정보와 gradient 흐름을 개선한다.
- 순차 계산과 고정 길이 상태 병목은 attention이 해결하려는 핵심 문제다.

## Study Guide

1. one-to-many, many-to-one, many-to-many의 computational graph를 그린다.
2. RNN이 시간축에서 parameter sharing을 한다는 점과 gradient 합산을 연결한다.
3. teacher forcing 훈련과 autoregressive 생성의 입력 차이를 설명한다.
4. LSTM 각 gate가 읽기·쓰기·유지 중 어떤 역할인지 수식에서 추적한다.

## 복습 질문

<details markdown="block"><summary>1. 펼친 RNN의 여러 cell은 서로 다른 파라미터를 갖는가?</summary>

답변: 아니다. 그림에서는 시점별 cell로 보이지만 동일한 transition weight를 모든 시점에 공유한다.
</details>

<details markdown="block"><summary>2. gradient clipping은 무엇을 해결하고 무엇을 해결하지 못하는가?</summary>

답변: 너무 큰 gradient norm을 제한해 exploding gradient를 막지만, 이미 0에 가까워진 vanishing gradient를 되살리지는 못한다.
</details>

<details markdown="block"><summary>3. LSTM cell state가 vanilla RNN보다 gradient 전달에 유리한 이유는?</summary>

답변: cell update에 $$f_t\odot c_{t-1}$$와 새 정보의 덧셈 경로가 있어, 적절한 forget gate에서는 반복 비선형 변환보다 gradient가 직접 흐를 수 있기 때문이다.
</details>

## 원문 대조 기록

공식 PDF **124쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 23–49쪽 | vanilla RNN update와 sequence task | 1–4절 |
| PDF 50–58쪽 · 영상 00:28:11 | BPTT와 truncated BPTT | 5절 |
| PDF 59–95쪽 | character LM, captioning, sequence applications | 2–4절 |
| PDF 96–124쪽 · 영상 00:58:34 | LSTM gates와 gradient flow | 6–7절 |

RNN/LSTM 식은 강의 원문 요약이고, uniform Jacobian bound와 singular-value 충분조건을 사용한 안정성 논증은 **작성자 보충**이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 7](https://www.youtube.com/watch?v=kG2lAPBF7zA){:target="_blank" rel="noopener"}
- [Official Lecture 7 slides](https://cs231n.stanford.edu/slides/2025/lecture_7.pdf){:target="_blank" rel="noopener"}
