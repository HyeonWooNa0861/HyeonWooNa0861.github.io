---
layout: default
date: 2026-05-20 12:30:12 +0900
title: "Lecture 14 Optimization Theory"
course: "Machine Learning Basic"
topic: "Optimization Theory"
order: 14
major_topic: "Machine Learning Foundations"
keywords:
  - "Optimization"
  - "Convexity"
  - "Gradient Descent"
  - "Lagrange Multipliers"
  - "Objective Functions"
---

# Lecture 14 Optimization Theory

Source PDF: `machine-learning-basic-lecture-14.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 최적화의 역할 | 머신러닝에서 좋은 parameter는 어떻게 찾는가? |
| 2 | Gradient Descent | 해석적 해가 없을 때 수치적으로 최소점을 어떻게 찾는가? |
| 3 | Step Size | learning rate가 너무 작거나 크면 어떤 일이 생기는가? |
| 4 | Momentum | zigzag 수렴을 어떻게 완화하는가? |
| 5 | SGD와 Mini-batch | 데이터가 많을 때 gradient 계산 비용을 어떻게 줄이는가? |
| 6 | Newton Method | Hessian을 쓰는 2차 최적화는 어떤 원리인가? |
| 7 | Convexity | local minimum이 global optimum이 되려면 어떤 조건이 필요한가? |

14강은 머신러닝 학습을 실제로 가능하게 하는 최적화 방법을 다룬다. 모델의 parameter를 고른다는 말은 결국 목적 함수 또는 loss function을 작게 만드는 지점을 찾는다는 뜻이다.

## 1. 최적화와 머신러닝

머신러닝 모델을 학습시킨다는 것은 모델 parameter 중 목적 함수의 값이 좋은 parameter를 찾는 일이다. 최소화 문제로 단순화하면 다음과 같이 쓸 수 있다.

$$
\min_{x} f(x),
\qquad
f:\mathbb{R}^{d}\to\mathbb{R}
$$

여기서 \\(x\\)는 모델 parameter 또는 최적화하려는 변수이고, \\(f(x)\\)는 loss, risk, negative log-likelihood 같은 목적 함수다.

해석적 해를 구할 수 있으면 직접 풀 수 있지만, 실제 머신러닝에서는 함수가 복잡하거나 데이터가 너무 많아 analytic solution을 구하기 어렵다. 이때 반복적으로 parameter를 업데이트하는 최적화 알고리즘을 사용한다.

## 2. Gradient Descent

Gradient descent는 1차 최적화 알고리즘이다. 현재 위치에서 함수가 가장 빠르게 증가하는 방향은 gradient \\(\nabla f(x_i)\\)이고, 최소화를 위해서는 그 반대 방향으로 이동한다.

$$
x_{i+1}=x_i-\gamma_i(\nabla f(x_i))^T
$$

여기서 \\(\gamma_i\\)는 step size 또는 learning rate다. vector를 column vector로 두는 표기에서는 보통 다음처럼 쓴다.

$$
x_{i+1}=x_i-\gamma_i\nabla f(x_i)
$$

두 식은 gradient를 row vector로 보느냐 column vector로 보느냐의 표기 차이에 가깝다. 핵심은 gradient의 반대 방향으로 이동한다는 점이다.

Gradient descent의 한 step은 다음처럼 해석할 수 있다.

| 구성 | 의미 |
|---|---|
| \\(x_i\\) | 현재 parameter |
| \\(\nabla f(x_i)\\) | 현재 위치에서 함수가 증가하는 방향 |
| \\(-\nabla f(x_i)\\) | 함수를 줄이기 위해 움직일 방향 |
| \\(\gamma_i\\) | 한 번에 얼마나 움직일지 정하는 크기 |

## 3. 수렴성과 Local Minimum

적절한 step size를 사용하면 gradient descent는 함수값을 줄이는 방향으로 이동하며 local minimum 근처로 갈 수 있다.

$$
f(x_0)\ge f(x_1)\ge f(x_2)\ge\cdots
$$

다만 일반적인 non-convex 함수에서는 도착한 minimum이 global optimum이라는 보장은 없다. neural network 학습이 어려운 이유도 여기에 있다. 목적 함수가 복잡하면 local minimum, saddle point, flat region이 존재할 수 있다.

## 4. Step Size

Step size는 gradient descent의 성패를 좌우한다.

| step size | 결과 |
|---|---|
| 너무 작음 | 안정적일 수 있지만 수렴이 매우 느리다. |
| 적절함 | 함수값을 줄이며 local minimum 근처로 이동한다. |
| 너무 큼 | 최소점을 지나치거나 oscillation, divergence가 생긴다. |

강의에서는 간단한 heuristic을 제시한다.

| 상황 | 조정 |
|---|---|
| update 후 함수값이 증가 | update를 멈추고 step size를 줄인다. |
| 함수값이 계속 감소 | step size를 늘리는 것을 고려한다. |

이 아이디어는 backtracking line search와 연결된다. 중요한 것은 learning rate가 단순한 부가 설정이 아니라, 실제 학습 안정성과 속도를 결정하는 핵심 hyperparameter라는 점이다.

## 5. Gradient Descent 예시와 Zigzag

강의 예시의 목적 함수는 타원형 contour를 가진다. 이런 함수에서는 gradient 방향이 매번 valley의 양쪽 벽을 향할 수 있어 경로가 zigzag 모양이 된다.

Zigzag가 생기는 이유는 방향마다 곡률이 다르기 때문이다. 어떤 방향은 가파르고, 어떤 방향은 완만하면 gradient는 가파른 방향 성분에 크게 반응한다. 그래서 실제 minimum이 있는 긴 valley 방향으로 바로 내려가기보다 좌우로 흔들리며 천천히 이동할 수 있다.

이 문제를 줄이기 위해 momentum, adaptive learning rate, second-order method 같은 방법이 등장한다.

## 6. Momentum Gradient Descent

Momentum gradient descent는 이전 update 방향을 현재 update에 일부 반영한다.

$$
x_{i+1}
=x_i-\gamma_i(\nabla f(x_i))^T+\alpha\Delta x_i
$$

여기서 \\(\Delta x_i\\)는 직전 이동량이고, \\(\alpha\\)는 momentum 계수다.

$$
\Delta x_i
=x_i-x_{i-1}
=\alpha\Delta x_{i-1}
-\gamma_{i-1}(\nabla f(x_{i-1}))^T
$$

Momentum의 효과는 다음처럼 이해할 수 있다.

| 상황 | 효과 |
|---|---|
| 같은 방향으로 계속 gradient가 나옴 | update가 누적되어 더 빠르게 이동한다. |
| 좌우로 진동하는 방향 | 반대 방향 update가 서로 일부 상쇄된다. |
| 길고 좁은 valley | zigzag가 줄고 valley 방향 이동이 강화된다. |

직관적으로는 경사면을 내려가는 물체가 관성을 갖는 것과 비슷하다. 다만 momentum이 너무 크면 minimum을 지나쳐 overshooting할 수 있으므로 \\(\alpha\\) 조절이 필요하다.

## 7. Stochastic Gradient Descent

머신러닝 목적 함수는 보통 \\(N\\)개 데이터 각각에 대한 loss의 합으로 구성된다.

$$
L(\theta)=\sum_{n=1}^{N}L_n(\theta)
$$

예를 들어 확률 모델에서는 각 sample의 negative log-likelihood를 더할 수 있다.

$$
L_n(\theta)=-\log p(y_n\mid x_n,\theta)
$$

Full-batch gradient descent는 매 update마다 전체 데이터에 대한 gradient를 계산한다.

$$
\theta_{i+1}
=\theta_i-\gamma_i
\sum_{n=1}^{N}\nabla L_n(\theta_i)
$$

하지만 \\(N\\)이 매우 크면 한 번의 update가 너무 비싸다. Stochastic Gradient Descent(SGD)는 전체 gradient 대신 일부 데이터로 계산한 noisy approximation을 사용한다.

SGD는 한 sample 또는 작은 subset으로 update하므로 정확도는 떨어지지만, 훨씬 자주 parameter를 움직일 수 있다.

## 8. Mini-batch

Mini-batch \\(B\\)는 한 update에 사용하는 데이터 부분집합이다. mini-batch gradient는 전체 gradient를 다음처럼 근사한다.

$$
\sum_{n=1}^{N}\nabla L_n(\theta_i)
\approx
\frac{N}{\lvert B\rvert}
\sum_{n\in B}\nabla L_n(\theta_i)
$$

따라서 mini-batch update는 다음처럼 쓸 수 있다.

$$
\theta_{i+1}
\approx
\theta_i-\gamma_i
\frac{N}{\lvert B\rvert}
\sum_{n\in B}\nabla L_n(\theta_i)
$$

| mini-batch 크기 | 장점 | 단점 |
|---|---|---|
| 큼 | gradient 근사가 정확하고 안정적 | update 하나의 계산 비용이 큼 |
| 작음 | 빠르고 자주 update 가능 | gradient가 noisy하고 수렴이 흔들릴 수 있음 |

작은 mini-batch의 noise는 항상 나쁜 것만은 아니다. local minimum이나 saddle point 근처에서 빠져나오는 데 도움을 줄 수 있다. 반대로 너무 noisy하면 수렴이 불안정해지므로 batch size와 learning rate를 함께 조정해야 한다.

## 9. Newton Method

Newton method는 Hessian을 사용하는 2차 최적화 방법이다. Gradient descent가 1차 미분만 보는 반면, Newton method는 곡률 정보까지 사용한다.

현재 지점 \\(\theta_k\\)에서 gradient와 Hessian을 다음처럼 두자.

$$
g_k=\nabla f(\theta_k),
\qquad
H_k=\nabla^2 f(\theta_k)
$$

목적 함수를 \\(\theta_k\\) 주변에서 2차 Taylor approximation으로 근사하면 다음과 같다.

$$
f(\theta)
\approx
f_k
+g_k^T(\theta-\theta_k)
+\frac{1}{2}(\theta-\theta_k)^TH_k(\theta-\theta_k)
$$

이 2차 근사의 gradient를 0으로 두면

$$
g_k+H_k(\theta-\theta_k)=0
$$

이므로 다음 위치가 나온다.

$$
\theta
=\theta_k-H_k^{-1}g_k
$$

강의의 update는 damping 또는 step size \\(\eta_k\\)를 포함해 다음처럼 쓴다.

$$
\theta_{k+1}
=\theta_k-\eta_k H_k^{-1}g_k
$$

## 10. Newton Method의 장단점

Newton method는 곡률을 반영하므로 잘 맞는 상황에서는 gradient descent보다 훨씬 빠르게 수렴할 수 있다. 특히 목적 함수가 quadratic에 가까우면 한 번의 step이 매우 강력하다.

하지만 실제 머신러닝에서는 다음 문제가 있다.

| 문제 | 설명 |
|---|---|
| Hessian 계산 비용 | parameter 수가 많으면 \\(H_k\\) 자체가 매우 크다. |
| 역행렬 계산 비용 | \\(H_k^{-1}\\) 계산은 비싸고 수치적으로 불안정할 수 있다. |
| non-convex 문제 | Hessian이 positive definite가 아니면 descent direction이 아닐 수 있다. |

그래서 deep learning에서는 순수 Newton method보다 SGD, momentum, Adam 같은 1차 기반 optimizer가 더 자주 쓰인다. 다만 second-order 정보는 quasi-Newton method, natural gradient, curvature-aware method에서 중요한 아이디어로 남아 있다.

## 11. Convexity

일반적인 목적 함수는 다양한 local minimum을 가질 수 있다. 하지만 목적 함수가 convex이면 local minimum이 global optimum이 된다.

Convexity가 중요한 이유는 최적화 문제가 훨씬 예측 가능해지기 때문이다. convex minimization에서는 어느 local minimum에 도달하더라도 그것이 전역 최적해다.

## 12. Convex Set

집합 \\(C\\)가 convex set이라는 말은 집합 안의 임의의 두 점 \\(x\\), \\(y\\)를 잡았을 때, 두 점을 잇는 선분 전체가 다시 집합 안에 있다는 뜻이다.

$$
\lambda x+(1-\lambda)y\in C,
\qquad
0\le\lambda\le 1
$$

직관적으로는 집합 안에서 두 점을 골라 직선을 그었을 때, 그 직선이 집합 밖으로 나가지 않는 모양이다.

## 13. Convex Function

정의역 \\(C\\)가 convex set인 함수 \\(f:C\to\mathbb{R}\\)에 대해, 임의의 \\(x,y\in C\\)와 \\(0\le\lambda\le 1\\)에 대해 다음을 만족하면 \\(f\\)를 convex function이라고 한다.

$$
f(\lambda x+(1-\lambda)y)
\le
\lambda f(x)+(1-\lambda)f(y)
$$

왼쪽은 두 입력을 먼저 섞은 뒤 함수에 넣은 값이고, 오른쪽은 두 함수값을 선형 보간한 값이다. Convex function은 chord가 graph 위에 있거나 같다는 직관으로 이해할 수 있다.

## 14. Convex Function 예시: \\(f(x)=x^2\\)

\\(f(x)=x^2\\)는 convex function이다. 두 점 \\(x_1,x_2\\)와 \\(0\le\lambda\le 1\\)에 대해 확인하면 다음과 같다.

$$
\lambda f(x_1)+(1-\lambda)f(x_2)
-f(\lambda x_1+(1-\lambda)x_2)
$$

$$
=\lambda x_1^2+(1-\lambda)x_2^2
-\left(\lambda x_1+(1-\lambda)x_2\right)^2
$$

$$
=\lambda(1-\lambda)(x_1-x_2)^2
\ge 0
$$

따라서

$$
f(\lambda x_1+(1-\lambda)x_2)
\le
\lambda f(x_1)+(1-\lambda)f(x_2)
$$

가 성립한다.

## 15. Convex Function 예시: Negative Entropy

강의에서는 인공지능에서 중요한 함수인 negative entropy 예시를 든다.

$$
f(x)=x\log x,
\qquad x>0
$$

이 함수가 convex인 이유는 두 번째 미분이 양수이기 때문이다.

$$
f'(x)=\log x+1
$$

$$
f''(x)=\frac{1}{x}>0
\qquad (x>0)
$$

따라서 \\(x>0\\) 구간에서 \\(x\log x\\)는 convex function이다. 정보이론과 머신러닝에서 entropy, cross entropy, KL divergence를 이해할 때 이 형태가 자주 등장한다.

## 16. Convex Function의 성질

Convex function은 다음 성질을 가진다.

| 성질 | 의미 |
|---|---|
| convex 함수의 합 | \\(f_1+f_2\\)도 convex |
| nonnegative weighted sum | \\(\alpha,\beta\ge0\\)이면 \\(\alpha f_1+\beta f_2\\)도 convex |
| local minimum | convex function에서는 local minimum이 global optimum |

예를 들어 \\(f_1\\), \\(f_2\\)가 convex이면

$$
f_1(\lambda x+(1-\lambda)y)
\le
\lambda f_1(x)+(1-\lambda)f_1(y)
$$

$$
f_2(\lambda x+(1-\lambda)y)
\le
\lambda f_2(x)+(1-\lambda)f_2(y)
$$

두 식을 더하면 \\(f_1+f_2\\)도 convex임을 알 수 있다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| gradient descent update는? | \\(x_{i+1}=x_i-\gamma_i\nabla f(x_i)\\) |
| step size가 너무 작으면? | 수렴이 느려진다. |
| step size가 너무 크면? | 최소점을 지나치거나 발산할 수 있다. |
| momentum의 역할은? | 이전 이동 방향을 누적해 zigzag를 줄이고 valley 방향 이동을 강화한다. |
| SGD가 필요한 이유는? | 전체 데이터 gradient 계산 비용을 줄이기 위해 |
| mini-batch의 trade-off는? | 클수록 정확하지만 비싸고, 작을수록 빠르지만 noisy하다. |
| Newton method가 추가로 쓰는 정보는? | Hessian, 즉 2차 곡률 정보 |
| convex set의 정의는? | 두 점을 잇는 선분이 모두 집합 안에 남는 집합 |
| convex function의 장점은? | local minimum이 global optimum이 된다. |
| \\(x\log x\\)가 \\(x>0\\)에서 convex인 이유는? | 두 번째 미분 \\(1/x\\)가 양수이기 때문 |

## 복습 질문

<details>
<summary>1. Gradient descent가 gradient의 반대 방향으로 이동하는 이유는 무엇인가?</summary>

답변: gradient \\(\nabla f(x)\\)는 현재 위치에서 함수가 가장 빠르게 증가하는 방향이다. 최소화를 하려면 함수값을 줄여야 하므로 그 반대 방향인 \\(-\nabla f(x)\\)로 움직인다. step size \\(\gamma\\)는 그 방향으로 얼마나 이동할지 정한다.

</details>

<details>
<summary>2. Gradient descent가 zigzag로 느릴 때 momentum은 어떤 도움을 주는가?</summary>

답변: momentum은 이전 update 방향을 현재 update에 누적한다. 같은 방향으로 계속 움직이는 성분은 강화되고, 좌우로 진동하는 성분은 서로 상쇄된다. 그래서 길고 좁은 valley에서 zigzag를 줄이고 수렴을 빠르게 만들 수 있다.

</details>

<details>
<summary>3. mini-batch가 작으면 gradient가 noisy해지는데도 실제 학습에서 유용할 수 있는 이유는?</summary>

답변: 작은 mini-batch는 계산 비용이 낮아 update를 자주 할 수 있다. 또한 gradient noise가 saddle point나 나쁜 local minimum 근처에서 빠져나오는 데 도움을 줄 수 있다. 다만 너무 작으면 수렴이 불안정해질 수 있어 learning rate와 함께 조절해야 한다.

</details>

<details>
<summary>4. Newton method는 gradient descent와 무엇이 다른가?</summary>

답변: gradient descent는 gradient만 사용해 하강 방향을 정한다. Newton method는 Hessian까지 사용해 목적 함수의 곡률을 반영한다. 2차 Taylor 근사의 최소점을 다음 위치로 삼기 때문에 잘 맞는 경우 빠르지만, Hessian 계산과 역행렬 계산이 비싸다.

</details>

<details>
<summary>5. Convexity가 보장되지 않는 neural network 학습에서는 어떤 어려움이 생기는가?</summary>

답변: non-convex objective에서는 local minimum, saddle point, flat region이 존재할 수 있다. 따라서 찾은 해가 global optimum인지 보장하기 어렵다. initialization, optimizer, learning rate, regularization에 따라 학습 결과가 달라질 수 있다.

</details>

<details>
<summary>6. Convex function에서 local minimum이 global optimum이 되는 이유를 직관적으로 설명하라.</summary>

답변: convex function은 두 점 사이가 위로 볼록하지 않고 하나의 그릇처럼 이어진다. 만약 어떤 local minimum보다 더 낮은 점이 다른 곳에 있다면, 두 점을 잇는 선분 위에서 함수값이 계속 내려가는 방향이 생겨 local minimum이라는 가정과 충돌한다. 그래서 convex function의 local minimum은 전역 최적해다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-14.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-14.pdf</a></li>
</ul>
