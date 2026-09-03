---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 3: Regularization and Optimization"
course: "CS231N"
topic: "Regularization and Optimization"
order: 3
major_topic: "Computer Vision"
keywords:
  - "Regularization"
  - "Optimization"
  - "Gradient Descent"
  - "Learning Rate"
  - "Overfitting"
---

# Stanford CS231N Lecture 3: Regularization and Optimization

Source: [Stanford CS231N Spring 2025 Lecture 3](https://www.youtube.com/watch?v=dyNGd06MWn4){:target="_blank" rel="noopener"}

> **핵심:** 정규화는 훈련 오차가 아니라 보지 못한 데이터의 오차를 줄이기 위한 설계이고, 최적화는 그 목적함수의 지형을 기울기로 탐색하는 과정이다. 좋은 결과는 optimizer 이름 하나보다 학습률, 스케줄, 초기화, 데이터 표현의 조합에서 나온다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Regularization | 왜 데이터 손실만 최소화하면 충분하지 않은가? |
| 2 | Optimization | 해석적 해가 없는 고차원 손실을 어떻게 낮추는가? |
| 3 | SGD and momentum | noisy gradient와 ravine을 어떻게 통과하는가? |
| 4 | Adaptive methods | 좌표별 gradient scale 차이를 어떻게 보정하는가? |
| 5 | Learning-rate schedule | 학습 단계마다 보폭을 왜 바꾸는가? |

## 1. 데이터 손실과 정규화

훈련 목적함수는 보통 데이터 손실과 정규화 항을 결합한다.

$$
L(W)=\frac{1}{N}\sum_{i=1}^{N}L_i(W)+\lambda R(W)
$$

데이터 손실은 현재 훈련 예제를 맞추게 하고, 정규화는 여러 해 가운데 더 단순하거나 안정적인 해를 선호하게 한다. \(\lambda\)가 너무 작으면 과적합, 너무 크면 데이터 신호를 충분히 학습하지 못하는 underfitting이 생길 수 있다.

### 주요 정규화 방식

| 방식 | 형태 또는 작동 | 유도하는 성질 |
|---|---|---|
| L2 | \(R(W)=\sum_k W_k^2\) | 큰 가중치를 전반적으로 억제하고 여러 특징을 분산 활용 |
| L1 | \(R(W)=\sum_k \lvert W_k\rvert\) | 일부 가중치를 정확히 0에 가깝게 만들어 sparsity 유도 |
| Elastic net | L1과 L2 결합 | sparsity와 부드러운 억제를 함께 사용 |
| Dropout | 훈련 중 activation 일부를 무작위 제거 | 특정 경로의 공동 적응을 줄임 |
| Data augmentation | 의미를 보존하는 입력 변환 | 모델이 원하는 invariance를 데이터로 주입 |

컴퓨터 비전에서 crop, flip, color jitter 같은 augmentation은 실제로 가능한 관측 변화를 학습 분포에 포함한다. 무조건 강한 변환이 좋은 것은 아니며 레이블 의미를 보존해야 한다.

## 2. 수치 미분과 해석적 gradient

수치 미분은 작은 \(h\)를 사용해 gradient를 근사한다.

$$
\frac{df}{dx}\approx\frac{f(x+h)-f(x-h)}{2h}
$$

구현이 단순하지만 파라미터마다 순전파를 반복해야 해 매우 느리다. 실제 학습에는 backpropagation으로 얻은 해석적 gradient를 사용하고, 수치 미분은 작은 모델의 **gradient check**에 쓴다. 두 값은 상대 오차로 비교하되, ReLU처럼 미분 불가능한 지점과 부동소수점 오차를 주의한다.

## 3. Gradient descent와 mini-batch SGD

기본 갱신은 다음과 같다.

$$
W_{t+1}=W_t-\eta\nabla_W L(W_t)
$$

전체 데이터의 gradient는 정확하지만 비싸다. mini-batch SGD는 일부 샘플로 gradient를 근사해 더 자주 갱신한다. batch가 작으면 noise가 크고, 크면 계산 효율은 좋아질 수 있지만 메모리와 한 번의 갱신 비용이 증가한다.

학습률 \(\eta\)가 너무 크면 손실이 발산하거나 최소점을 지나치고, 너무 작으면 진전이 느리며 나쁜 지형에 오래 머문다. 따라서 loss curve와 train/validation accuracy를 함께 관찰해야 한다.

## 4. Momentum and Nesterov momentum

SGD는 방향마다 곡률이 다른 ravine에서 좌우로 진동할 수 있다. Momentum은 이전 gradient의 누적 방향을 속도 \(v\)에 저장한다.

$$
v_{t+1}=\rho v_t-\eta\nabla L(W_t),
\qquad W_{t+1}=W_t+v_{t+1}
$$

일관된 방향은 가속하고 부호가 자주 바뀌는 방향은 상쇄한다. Nesterov momentum은 현재 위치가 아니라 momentum으로 미리 이동한 지점의 gradient를 보아 보정 시점을 앞당긴다.

## 5. Per-parameter adaptive optimization

AdaGrad는 gradient 제곱을 누적해 자주 큰 gradient가 나온 좌표의 유효 학습률을 줄인다. 희소 특징에는 유리하지만 누적값이 계속 커져 학습이 너무 일찍 멈출 수 있다.

RMSProp은 제곱 gradient의 지수 이동평균을 사용해 이 문제를 완화한다. Adam은 momentum에 해당하는 1차 모멘트와 RMSProp에 해당하는 2차 모멘트를 함께 추적하고, 초기 평균이 0에 치우치는 현상을 bias correction으로 보정한다.

$$
m_t=\beta_1m_{t-1}+(1-\beta_1)g_t,
\quad
v_t=\beta_2v_{t-1}+(1-\beta_2)g_t^2
$$

AdamW는 L2 항을 gradient에 섞기보다 weight decay를 파라미터 갱신에서 분리한다. 강의는 Adam/AdamW를 실용적인 시작점으로 제시하지만, 최종 선택은 validation 결과로 해야 한다.

## 6. Learning-rate schedules

- **Step decay:** 정한 시점마다 학습률을 일정 비율로 낮춘다.
- **Cosine decay:** 부드러운 cosine 곡선으로 끝을 향해 줄인다.
- **Warmup:** 초반의 불안정한 큰 갱신을 막기 위해 작은 값에서 시작한다.

초반에는 넓은 영역을 탐색하고 후반에는 세밀하게 수렴해야 하므로 고정 학습률보다 schedule이 유리할 수 있다. 큰 batch나 깊은 모델에서는 warmup이 특히 안정성을 높인다.

## 마지막 핵심 정리

- 정규화는 **일반화할 해의 선호도**를 목적함수에 넣는다.
- mini-batch gradient는 계산 효율과 noise 사이의 절충이다.
- Momentum은 방향을 누적하고, Adam은 좌표별 scale까지 조정한다.
- AdamW는 adaptive optimizer에서 weight decay를 분리한다.
- optimizer보다 먼저 학습률과 loss curve가 합리적인지 확인해야 한다.

## Study Guide

1. data loss와 regularization loss의 역할을 분리해 설명한다.
2. SGD, momentum, RMSProp, Adam의 상태 변수가 무엇인지 비교한다.
3. `loss 폭증`, `초기 정체`, `후반 진동`을 각각 학습률 관점에서 진단한다.
4. train 성능과 validation 성능의 간격으로 과적합 여부를 판단한다.

## 복습 질문

<details><summary>1. 정규화가 훈련 손실을 오히려 높일 수 있는데도 사용하는 이유는 무엇인가?</summary>

답변: 목표가 훈련 예제 암기가 아니라 보지 못한 데이터에서의 낮은 오차이기 때문이다. 정규화는 훈련 적합도를 조금 양보하고 일반화 가능한 해를 선호한다.
</details>

<details><summary>2. momentum이 ravine에서 진동을 줄이는 원리는 무엇인가?</summary>

답변: 반복해서 같은 부호를 갖는 진행 방향은 속도에 누적되고, 부호가 번갈아 바뀌는 가파른 방향은 서로 상쇄되기 때문이다.
</details>

<details><summary>3. AdamW와 Adam에 L2 regularization을 넣는 방식의 차이는 무엇인가?</summary>

답변: AdamW는 weight decay를 adaptive gradient 계산과 분리해 파라미터에 직접 적용한다. 따라서 좌표별 gradient scaling이 정규화 강도를 의도치 않게 바꾸는 문제를 줄인다.
</details>

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 3](https://www.youtube.com/watch?v=dyNGd06MWn4){:target="_blank" rel="noopener"}
