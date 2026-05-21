---
layout: default
title: "Lecture 14 Optimization Theory"
course: "Machine Learning Basic"
topic: "Optimization Theory"
order: 14
---

# Lecture 14 Optimization Theory

Source PDF: `machine-learning-basic-lecture-14.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 최적화의 역할 | 좋은 parameter는 어떻게 찾는가? |
| 2 | Gradient Descent | 해석적 해가 없을 때 수치적으로 어떻게 최소점을 찾는가? |
| 3 | Step size | 너무 작거나 큰 learning rate는 어떤 문제를 만드는가? |
| 4 | Momentum and SGD | 느린 수렴과 큰 데이터 비용을 어떻게 완화하는가? |
| 5 | Newton Method | Hessian을 쓰는 2차 최적화는 무엇인가? |
| 6 | Convexity | 전역 최적해를 보장하려면 어떤 조건이 필요한가? |

## 1. 최적화와 머신러닝

머신러닝 모델을 학습시킨다는 것은 모델 parameter 중 목적 함수 값이 좋은 parameter를 찾는 일이다.

$$
\min_x f(x), \qquad f:\mathbb{R}^d \to \mathbb{R}
$$

목적 함수의 해석적 해를 구할 수 없거나 계산하기 어려울 때 최적화 알고리즘을 사용한다.

## 2. Gradient Descent

Gradient descent는 1차 최적화 알고리즘이다. 현재 위치에서 gradient의 반대 방향으로 이동한다.

$$
x_{i+1} = x_i - \gamma_i(\nabla f(x_i))^T
$$

여기서 \\(\gamma_i\\)는 step size 또는 learning rate다.

gradient는 함수가 가장 빠르게 증가하는 방향이므로, 최소화를 위해서는 그 반대 방향으로 간다.

## 3. Step Size

Step size는 경사 하강법에서 매우 중요하다.

| step size | 결과 |
|---|---|
| 너무 작음 | 수렴이 매우 느리다. |
| 적절함 | 안정적으로 local minimum 근처로 간다. |
| 너무 큼 | 최소점을 지나치거나 발산할 수 있다. |

간단한 heuristic은 업데이트 후 함수값이 증가하면 step size를 줄이고, 함수값이 안정적으로 감소하면 step size를 늘리는 것이다.

## 4. Momentum Gradient Descent

Momentum은 이전에 움직이던 방향을 유지하면서 update하는 방법이다.

$$
x_{i+1}=x_i-\gamma_i(\nabla f(x_i))^T+\alpha\Delta x_i
$$

$$
\Delta x_i=x_i-x_{i-1}
=\alpha\Delta x_{i-1}-\gamma_{i-1}(\nabla f(x_{i-1}))^T
$$

지그재그로 느리게 내려가는 상황에서 이전 이동 방향을 누적해 더 빠르고 안정적인 이동을 돕는다.

직관적으로는 공이 경사면을 내려가며 관성을 가지는 것과 비슷하다.

## 5. Stochastic Gradient Descent와 Mini-batch

머신러닝 목적 함수는 보통 \\(N\\)개 데이터의 loss 합으로 구성된다.

$$
L(\theta)=\sum_{n=1}^{N}L_n(\theta)
$$

\\(N\\)이 매우 크면 전체 gradient 계산이 비싸다. SGD는 일부 데이터만 사용해 gradient의 noisy approximation을 계산한다.

Mini-batch는 한 번의 update에 사용하는 데이터 부분집합이다.

$$
\theta_{i+1}
\approx \theta_i-\gamma_i\frac{N}{\lvert B\rvert}
\sum_{n\in B}\nabla L_n(\theta_i)^T
$$

| mini-batch 크기 | 장점 | 단점 |
|---|---|---|
| 큼 | gradient 근사가 정확 | 계산 비용 큼 |
| 작음 | 빠르고 저렴 | noisy하지만 나쁜 local minimum 탈출에 도움 가능 |

## 6. Newton Method

Newton method는 Hessian을 사용하는 2차 최적화 방법이다.

$$
\theta_{k+1} = \theta_k-\eta_k H_k^{-1}g_k
$$

2차 Taylor approximation으로 목적 함수를 근사하고, 그 근사의 최소점을 다음 위치로 선택한다.

| 방법 | 사용하는 정보 |
|---|---|
| Gradient Descent | gradient |
| Newton Method | gradient + Hessian |

Newton method는 곡률 정보를 쓰므로 빠를 수 있지만 Hessian 계산과 역행렬 계산 비용이 크다.

## 7. Convexity

일반적인 목적 함수는 여러 local minimum을 가질 수 있다. 하지만 convex function이면 local minimum이 global optimum이 된다.

Convex set은 두 점을 이은 선분이 모두 집합 안에 남는 집합이다.

$$
\lambda x + (1-\lambda)y \in C
$$

Convex function은 두 점 사이의 함수값이 선형 보간보다 아래에 있는 함수다.

$$
f(\lambda x+(1-\lambda)y)
\le \lambda f(x)+(1-\lambda)f(y)
$$

중요한 성질:

| 성질 | 의미 |
|---|---|
| convex 함수의 합 | convex |
| 양수배 | convex 유지 |
| global optimum | convex minimization에서 핵심 장점 |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| gradient descent update는? | \\(x_{i+1}=x_i-\gamma_i(\nabla f(x_i))^T\\) |
| step size가 너무 크면? | 발산하거나 수렴 실패 |
| SGD가 필요한 이유는? | 전체 데이터 gradient 계산 비용을 줄이기 위해 |
| Newton method가 추가로 쓰는 정보는? | Hessian |
| convex function의 장점은? | local minimum이 global optimum |

## 복습 질문

<details>
<summary>1. Gradient descent가 zigzag로 느릴 때 momentum은 어떤 도움을 주는가?</summary>

답변: momentum은 이전 update 방향을 누적해 현재 update에 반영한다. 같은 방향으로 계속 움직이는 성분은 강화하고, 좌우로 진동하는 성분은 상대적으로 줄인다. 그래서 좁고 긴 valley에서 zigzag를 완화하고 수렴을 빠르게 만들 수 있다.

</details>

<details>
<summary>2. mini-batch가 작으면 gradient가 noisy해지는데도 실제 학습에서 유용할 수 있는 이유는?</summary>

답변: 작은 mini-batch는 계산 비용이 낮아 update를 자주 할 수 있다. gradient noise가 local minimum이나 saddle point에서 빠져나오는 데 도움을 줄 수도 있다. 다만 너무 작으면 수렴이 불안정해질 수 있어 batch size 조절이 필요하다.

</details>

<details>
<summary>3. Convexity가 보장되지 않는 neural network 학습에서는 어떤 어려움이 생기는가?</summary>

답변: non-convex objective에서는 local minimum, saddle point, flat region이 존재할 수 있다. 따라서 찾은 해가 global optimum인지 보장하기 어렵고, initialization, optimizer, learning rate, regularization에 따라 학습 결과가 달라질 수 있다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-14.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-14.pdf</a></li>
</ul>
