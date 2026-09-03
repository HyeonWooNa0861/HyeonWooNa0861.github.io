---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
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
Slides: [Official Stanford CS231N 2025 Lecture 3 PDF](https://cs231n.stanford.edu/slides/2025/lecture_3.pdf){:target="_blank" rel="noopener"}

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

데이터 손실은 현재 훈련 예제를 맞추게 하고, 정규화는 여러 해 가운데 더 단순하거나 안정적인 해를 선호하게 한다. $$\lambda$$가 너무 작으면 과적합, 너무 크면 데이터 신호를 충분히 학습하지 못하는 underfitting이 생길 수 있다.

### 주요 정규화 방식

| 방식 | 형태 또는 작동 | 유도하는 성질 |
|---|---|---|
| L2 | $$R(W)=\sum_k W_k^2$$ | 큰 가중치를 전반적으로 억제하고 여러 특징을 분산 활용 |
| L1 | $$R(W)=\sum_k \lvert W_k\rvert$$ | 일부 가중치를 정확히 0에 가깝게 만들어 sparsity 유도 |
| Elastic net | L1과 L2 결합 | sparsity와 부드러운 억제를 함께 사용 |
| Dropout | 훈련 중 activation 일부를 무작위 제거 | 특정 경로의 공동 적응을 줄임 |
| Data augmentation | 의미를 보존하는 입력 변환 | 모델이 원하는 invariance를 데이터로 주입 |

컴퓨터 비전에서 crop, flip, color jitter 같은 augmentation은 실제로 가능한 관측 변화를 학습 분포에 포함한다. 무조건 강한 변환이 좋은 것은 아니며 레이블 의미를 보존해야 한다.

## 2. 수치 미분과 해석적 gradient

수치 미분은 작은 $$h$$를 사용해 gradient를 근사한다.

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

학습률 $$\eta$$가 너무 크면 손실이 발산하거나 최소점을 지나치고, 너무 작으면 진전이 느리며 나쁜 지형에 오래 머문다. 따라서 loss curve와 train/validation accuracy를 함께 관찰해야 한다.

## 4. Momentum and Nesterov momentum

SGD는 방향마다 곡률이 다른 ravine에서 좌우로 진동할 수 있다. Momentum은 이전 gradient의 누적 방향을 속도 $$v$$에 저장한다.

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

## 핵심 수식 유도

### 작성자 보충: Adam의 bias correction과 parameter update

Adam은 $$m_0=v_0=0$$에서 시작해 현재 gradient $$g_t=\nabla_WL(W_t)$$의 elementwise 1차·2차 moment를

$$
\begin{aligned}
m_t&=\beta_1m_{t-1}+(1-\beta_1)g_t,\\
v_t&=\beta_2v_{t-1}+(1-\beta_2)g_t^2,
\end{aligned}
$$

로 누적한다. 여기서 $$0\le\beta_1,\beta_2<1$$이고 제곱은 elementwise 연산이다. 초기에 gradient의 평균이 시간에 따라 거의 일정하다고 보면

$$
\mathbb E[m_t]=(1-\beta_1^t)\mathbb E[g_t],
\qquad
\mathbb E[v_t]=(1-\beta_2^t)\mathbb E[g_t^2]
$$

가 된다. 0으로 초기화한 이동평균이 초반에 작게 치우치는 정확한 원인이 $$1-\beta_1^t$$와 $$1-\beta_2^t$$이므로 이를 나누어

$$
\widehat m_t=\frac{m_t}{1-\beta_1^t},
\qquad
\widehat v_t=\frac{v_t}{1-\beta_2^t}
$$

로 보정한다. Adam의 parameter update는

$$
W_{t+1}
=W_t-\eta\frac{\widehat m_t}{\sqrt{\widehat v_t}+\epsilon},
\qquad \epsilon>0,
$$

이며 나눗셈, 제곱근, 덧셈도 parameter별 elementwise 연산이다. Recurrence와 bias-correction 식은 위 초기값 아래의 **정확한 정의**이고, 일정한 moment를 가정한 기대값 계산은 초기 bias를 설명하는 근사다. $$m_t$$는 gradient와 같은 `loss/weight` 단위, $$v_t$$는 그 제곱 단위, $$\epsilon$$은 $$\sqrt{v_t}$$와 같은 단위를 가진다. 따라서 fraction은 무차원이고 $$\eta$$는 update가 $$W$$와 같은 단위를 갖도록 정한다. $$\epsilon$$이 지나치게 크면 adaptive scaling이 약해지고, 너무 작으면 $$v_t\approx0$$인 좌표에서 update가 불안정하다. Nonstationary gradient에서는 bias correction이 moment 추정의 정확성이나 수렴을 보장하지 않는다.

### 작성자 보충: L2 penalty와 weight decay

L2 regularization $$L(W)=L_{\mathrm{data}}(W)+\lambda\lVert W\rVert_2^2$$은 **목적함수 정의**이며 gradient는 $$\nabla_WL=\nabla_WL_{\mathrm{data}}+2\lambda W$$다. 따라서 gradient descent는 data gradient가 없을 때 $$W\leftarrow(1-2\eta\lambda)W$$가 되어 weight decay로 보인다. $$\eta,\lambda$$는 이 표현에서 곱이 무차원이 되도록 정해진 hyperparameter다. Adam과 결합한 decoupled weight decay는 일반 L2 penalty와 정확히 같지 않으며, $$\eta\lambda$$가 너무 크면 유용한 weight도 급격히 사라진다.

### 작성자 보충: Taylor 근사에서 Newton step까지

공식 슬라이드 88–94쪽은 first-order update를 넘어 curvature를 쓰는 second-order optimization을 소개한다. 현재 점 $$w$$ 주변에서 두 번 미분 가능한 scalar loss를 2차 Taylor 근사하면

$$
L(w+\Delta)
\approx L(w)+g^\top\Delta+\frac12\Delta^\top H\Delta,
\qquad
g=\nabla L(w),\quad H=\nabla^2L(w)
$$

이다. 이 quadratic surrogate를 $$\Delta$$로 미분하면

$$
\nabla_{\Delta}\widetilde L=g+H\Delta.
$$

따라서 $$H$$가 invertible이고 이 근사의 stationary point를 택할 수 있을 때

$$
g+H\Delta^*=0
\quad\Longrightarrow\quad
\boxed{\Delta^*=-H^{-1}g},
\qquad
w_{t+1}=w_t-H^{-1}g
$$

를 얻는다. 이는 **2차 Taylor 근사의 stationary-point 해**이며, 원래 비선형 loss의 전역 최솟값을 보장하는 식은 아니다. $$H\succ0$$이면 surrogate가 strictly convex라서 이 stationary point가 유일한 local minimizer지만, Hessian이 singular하거나 indefinite이면 inverse가 없거나 descent direction이 아닐 수 있어 damping·trust region 같은 보완이 필요하다. Parameter $$w$$의 단위를 `weight`, loss 단위를 `loss`라 하면 $$g$$는 `loss/weight`, $$H$$는 `loss/weight²`, $$H^{-1}g$$는 `weight` 단위이므로 update와 차원이 맞는다. Deep network에서는 Hessian 저장·역산 비용이 parameter 수에 대해 매우 커 실제 대규모 학습에서 그대로 쓰기 어렵다는 것이 강의의 실무적 결론이다.

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

<details markdown="block"><summary>1. 정규화가 훈련 손실을 오히려 높일 수 있는데도 사용하는 이유는 무엇인가?</summary>

답변: 목표가 훈련 예제 암기가 아니라 보지 못한 데이터에서의 낮은 오차이기 때문이다. 정규화는 훈련 적합도를 조금 양보하고 일반화 가능한 해를 선호한다.
</details>

<details markdown="block"><summary>2. momentum이 ravine에서 진동을 줄이는 원리는 무엇인가?</summary>

답변: 반복해서 같은 부호를 갖는 진행 방향은 속도에 누적되고, 부호가 번갈아 바뀌는 가파른 방향은 서로 상쇄되기 때문이다.
</details>

<details markdown="block"><summary>3. AdamW와 Adam에 L2 regularization을 넣는 방식의 차이는 무엇인가?</summary>

답변: AdamW는 weight decay를 adaptive gradient 계산과 분리해 파라미터에 직접 적용한다. 따라서 좌표별 gradient scaling이 정규화 강도를 의도치 않게 바꾸는 문제를 줄인다.
</details>

## 원문 대조 기록

공식 PDF **119쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 14–35쪽 · 영상 00:00:05 | data loss, regularization, L1/L2 | 1절 |
| PDF 36–55쪽 · 영상 00:31:23 | numerical/analytic gradient와 gradient check | 2절 |
| PDF 56–87쪽 · 영상 00:43:06, 00:53:46 | SGD, momentum, RMSProp, Adam, schedule | 3–6절 |
| PDF 88–94쪽 · 영상 01:04:51 | Taylor expansion과 second-order update | Newton step 작성자 보충 |
| PDF 95–119쪽 | momentum·Nesterov·AdaGrad appendix | 기존 optimizer 설명 대조 |

Optimizer 정의와 장단점은 강의 원문 요약이다. Adam bias correction, L2/decoupled decay 비교, Newton step 유도는 강의 식의 전제를 명시해 확장한 **작성자 보충**이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 3](https://www.youtube.com/watch?v=dyNGd06MWn4){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 3 PDF](https://cs231n.stanford.edu/slides/2025/lecture_3.pdf){:target="_blank" rel="noopener"}
