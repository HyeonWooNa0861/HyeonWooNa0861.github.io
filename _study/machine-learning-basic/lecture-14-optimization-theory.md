---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-11-23 16:50:00 +0900
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

> **핵심:** Gradient descent는 $$x_{i+1}=x_i-\gamma_i\nabla f(x_i)$$에 따라 해를 갱신합니다. Step size $$\gamma_i$$가 너무 작으면 한 번에 이동하는 거리가 짧아져 수렴이 느려집니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">학습 순서와 원문 대조 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 최적화의 역할 | 머신러닝에서 좋은 parameter는 어떻게 찾습니까? |
| 2 | Gradient Descent | 해석적 해가 없을 때 수치적으로 최소점을 어떻게 찾습니까? |
| 3 | Step Size | learning rate가 너무 작거나 크면 어떤 일이 생깁니까? |
| 4 | Momentum | zigzag 수렴을 어떻게 완화합니까? |
| 5 | SGD와 Mini-batch | 데이터가 많을 때 gradient 계산 비용을 어떻게 줄입니까? |
| 6 | Newton Method | Hessian을 쓰는 2차 최적화는 어떤 원리입니까? |
| 7 | Convexity | local minimum이 global optimum이 되려면 어떤 조건이 필요합니까? |

14강은 머신러닝 학습을 실제로 가능하게 하는 최적화 방법을 다룹니다. 모델의 parameter를 고른다는 말은 결국 목적 함수 또는 loss function을 작게 만드는 지점을 찾는다는 뜻입니다.

### 원문 수식 추적표

| PDF 페이지 | 중요 최적화식 | 본문 대응 |
|---:|---|---|
| 3–7 | $$\min_x f(x)$$, GD update, 수렴성과 step size | 1–5, 17.1 |
| 8–9 | momentum update | 6 |
| 10–12 | SGD·mini-batch gradient 근사 | 7, 8 |
| 13–14 | 2차 Taylor 근사와 Newton update | 9, 10, 17.2 |
| 15–20 | convex set/function 정의, $$x^2$$·negative entropy 예시, 닫힘 성질 | 11–16, 17.3 |

페이지 21은 convex 함수의 성질을 마무리하며 별도 Q&A 페이지는 없습니다. SGD·mini-batch는 full gradient의 **근사**이고, Newton 식은 local Taylor quadratic model을 풀어 얻는 update로 17절에서 구분합니다.

</details>

## 1. 최적화와 머신러닝

머신러닝 모델을 학습시킨다는 것은 모델 parameter 중 목적 함수의 값이 좋은 parameter를 찾는 일입니다. 최소화 문제로 단순화하면 다음과 같이 쓸 수 있습니다.

$$
\min_{x} f(x),
\qquad
f:\mathbb{R}^{d}\to\mathbb{R}
$$

여기서 $$x$$는 모델 parameter 또는 최적화하려는 변수이고, $$f(x)$$는 loss, risk, negative log-likelihood 같은 목적 함수입니다.

해석적 해를 구할 수 있으면 직접 풀 수 있지만, 실제 머신러닝에서는 함수가 복잡하거나 데이터가 너무 많아 analytic solution을 구하기 어렵습니다. 이때 반복적으로 parameter를 업데이트하는 최적화 알고리즘을 사용합니다.

## 2. Gradient Descent

Gradient descent는 1차 최적화 알고리즘입니다. 현재 위치에서 함수가 가장 빠르게 증가하는 방향은 gradient $$\nabla f(x_i)$$이고, 최소화를 위해서는 그 반대 방향으로 이동합니다.

$$
x_{i+1}=x_i-\gamma_i(\nabla f(x_i))^T
$$

여기서 $$\gamma_i$$는 step size 또는 learning rate입니다. vector를 column vector로 두는 표기에서는 보통 다음처럼 씁니다.

$$
x_{i+1}=x_i-\gamma_i\nabla f(x_i)
$$

두 식은 gradient를 row vector로 보느냐 column vector로 보느냐의 표기 차이에 가깝습니다. 핵심은 gradient의 반대 방향으로 이동한다는 점입니다.

Gradient descent의 한 step은 다음처럼 해석할 수 있습니다.

| 구성 | 의미 |
|---|---|
| $$x_i$$ | 현재 parameter |
| $$\nabla f(x_i)$$ | 현재 위치에서 함수가 증가하는 방향 |
| $$-\nabla f(x_i)$$ | 함수를 줄이기 위해 움직일 방향 |
| $$\gamma_i$$ | 한 번에 얼마나 움직일지 정하는 크기 |

## 3. 수렴성과 Local Minimum

적절한 step size를 사용하면 gradient descent는 함수값을 줄이는 방향으로 이동하며 local minimum 근처로 갈 수 있습니다.

$$
f(x_0)\ge f(x_1)\ge f(x_2)\ge\cdots
$$

다만 일반적인 non-convex 함수에서는 도착한 minimum이 global optimum이라는 보장은 없습니다. neural network 학습이 어려운 이유도 여기에 있습니다. 목적 함수가 복잡하면 local minimum, saddle point, flat region이 존재할 수 있습니다.

## 4. Step Size

Step size는 gradient descent의 성패를 좌우합니다.

| step size | 결과 |
|---|---|
| 너무 작음 | 안정적일 수 있지만 수렴이 매우 느립니다. |
| 적절함 | 함수값을 줄이며 local minimum 근처로 이동합니다. |
| 너무 큼 | 최소점을 지나치거나 oscillation, divergence가 생깁니다. |

강의에서는 간단한 heuristic을 제시합니다.

| 상황 | 조정 |
|---|---|
| update 후 함수값이 증가 | update를 멈추고 step size를 줄입니다. |
| 함수값이 계속 감소 | step size를 늘리는 것을 고려합니다. |

이 아이디어는 backtracking line search와 연결됩니다. 중요한 것은 learning rate가 단순한 부가 설정이 아니라, 실제 학습 안정성과 속도를 결정하는 핵심 hyperparameter라는 점입니다.

## 5. Gradient Descent 예시와 Zigzag

강의 예시의 목적 함수는 타원형 contour를 가집니다. 이런 함수에서는 gradient 방향이 매번 valley의 양쪽 벽을 향할 수 있어 경로가 zigzag 모양이 됩니다.

<a href="{{ "/assets/images/study/machine-learning-basic/source-captures/lecture-14-page-06.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/machine-learning-basic/source-captures/lecture-14-page-06.png" | relative_url }}" alt="원본 강의 슬라이드의 타원형 등고선과 경사하강 경로" loading="lazy"></a>

*원본 강의 PDF p. 6. 오른쪽 등고선은 $$x_2$$ 방향 곡률이 큰 이차함수이고, 주황 경로는 초기점에서 최소점 부근으로 이동하는 gradient descent 반복입니다. <a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-14.pdf#page=6" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 6</a>*

등고선의 짧은 축 방향에서는 gradient 성분이 커서 한 번의 update가 계곡 반대편까지 넘어갑니다. 긴 축 방향 이동은 상대적으로 작아서 좌우 진동은 빠르지만 최소점으로 향하는 진행은 느려집니다.

Zigzag가 생기는 이유는 방향마다 곡률이 다르기 때문입니다. 어떤 방향은 가파르고, 어떤 방향은 완만하면 gradient는 가파른 방향 성분에 크게 반응합니다. 그래서 실제 minimum이 있는 긴 valley 방향으로 바로 내려가기보다 좌우로 흔들리며 천천히 이동할 수 있습니다.

이 문제를 줄이기 위해 momentum, adaptive learning rate, second-order method 같은 방법이 등장합니다.

## 6. Momentum Gradient Descent

Momentum gradient descent는 이전 update 방향을 현재 update에 일부 반영합니다.

$$
x_{i+1}
=x_i-\gamma_i(\nabla f(x_i))^T+\alpha\Delta x_i
$$

여기서 $$\Delta x_i$$는 직전 이동량이고, $$\alpha$$는 momentum 계수입니다.

$$
\Delta x_i
=x_i-x_{i-1}
=\alpha\Delta x_{i-1}
-\gamma_{i-1}(\nabla f(x_{i-1}))^T
$$

Momentum의 효과는 다음처럼 이해할 수 있습니다.

| 상황 | 효과 |
|---|---|
| 같은 방향으로 계속 gradient가 나옴 | update가 누적되어 더 빠르게 이동합니다. |
| 좌우로 진동하는 방향 | 반대 방향 update가 서로 일부 상쇄됩니다. |
| 길고 좁은 valley | zigzag가 줄고 valley 방향 이동이 강화됩니다. |

직관적으로는 경사면을 내려가는 물체가 관성을 갖는 것과 비슷합니다. 다만 momentum이 너무 크면 minimum을 지나쳐 overshooting할 수 있으므로 $$\alpha$$ 조절이 필요합니다.

## 7. Stochastic Gradient Descent

머신러닝 목적 함수는 보통 $$N$$개 데이터 각각에 대한 loss의 합으로 구성됩니다.

$$
L(\theta)=\sum_{n=1}^{N}L_n(\theta)
$$

예를 들어 확률 모델에서는 각 sample의 negative log-likelihood를 더할 수 있습니다.

$$
L_n(\theta)=-\log p(y_n\mid x_n,\theta)
$$

Full-batch gradient descent는 매 update마다 전체 데이터에 대한 gradient를 계산합니다.

$$
\theta_{i+1}
=\theta_i-\gamma_i
\sum_{n=1}^{N}\nabla L_n(\theta_i)
$$

하지만 $$N$$이 매우 크면 한 번의 update가 너무 비쌉니다. Stochastic Gradient Descent(SGD)는 전체 gradient 대신 일부 데이터로 계산한 noisy approximation을 사용합니다.

SGD는 한 sample 또는 작은 subset으로 update하므로 정확도는 떨어지지만, 훨씬 자주 parameter를 움직일 수 있습니다.

## 8. Mini-batch

Mini-batch $$B$$는 한 update에 사용하는 데이터 부분집합입니다. mini-batch gradient는 전체 gradient를 다음처럼 근사합니다.

$$
\sum_{n=1}^{N}\nabla L_n(\theta_i)
\approx
\frac{N}{\lvert B\rvert}
\sum_{n\in B}\nabla L_n(\theta_i)
$$

따라서 mini-batch update는 다음처럼 쓸 수 있습니다.

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

작은 mini-batch의 noise는 항상 나쁜 것만은 아닙니다. local minimum이나 saddle point 근처에서 빠져나오는 데 도움을 줄 수 있습니다. 반대로 너무 noisy하면 수렴이 불안정해지므로 batch size와 learning rate를 함께 조정해야 합니다.

## 9. Newton Method

Newton method는 Hessian을 사용하는 2차 최적화 방법입니다. Gradient descent가 1차 미분만 보는 반면, Newton method는 곡률 정보까지 사용합니다.

현재 지점 $$\theta_k$$에서 gradient와 Hessian을 다음처럼 두겠습니다.

$$
g_k=\nabla f(\theta_k),
\qquad
H_k=\nabla^2 f(\theta_k)
$$

목적 함수를 $$\theta_k$$ 주변에서 2차 Taylor approximation으로 근사하면 다음과 같습니다.

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

이므로 다음 위치가 나옵니다.

$$
\theta
=\theta_k-H_k^{-1}g_k
$$

강의의 update는 damping 또는 step size $$\eta_k$$를 포함해 다음처럼 씁니다.

$$
\theta_{k+1}
=\theta_k-\eta_k H_k^{-1}g_k
$$

## 10. Newton Method의 장단점

Newton method는 곡률을 반영하므로 잘 맞는 상황에서는 gradient descent보다 훨씬 빠르게 수렴할 수 있습니다. 특히 목적 함수가 quadratic에 가까우면 한 번의 step이 매우 강력합니다.

하지만 실제 머신러닝에서는 다음 문제가 있습니다.

| 문제 | 설명 |
|---|---|
| Hessian 계산 비용 | parameter 수가 많으면 $$H_k$$ 자체가 매우 큽니다. |
| 역행렬 계산 비용 | $$H_k^{-1}$$ 계산은 비싸고 수치적으로 불안정할 수 있습니다. |
| non-convex 문제 | Hessian이 positive definite가 아니면 descent direction이 아닐 수 있습니다. |

그래서 deep learning에서는 순수 Newton method보다 SGD, momentum, Adam 같은 1차 기반 optimizer가 더 자주 쓰입니다. 다만 second-order 정보는 quasi-Newton method, natural gradient, curvature-aware method에서 중요한 아이디어로 남아 있습니다.

## 11. Convexity

일반적인 목적 함수는 다양한 local minimum을 가질 수 있습니다. 하지만 목적 함수가 convex이면 local minimum이 global optimum이 됩니다.

Convexity가 중요한 이유는 최적화 문제가 훨씬 예측 가능해지기 때문입니다. convex minimization에서는 어느 local minimum에 도달하더라도 그것이 전역 최적해입니다.

## 12. Convex Set

집합 $$C$$가 convex set이라는 말은 집합 안의 임의의 두 점 $$x$$, $$y$$를 잡았을 때, 두 점을 잇는 선분 전체가 다시 집합 안에 있다는 뜻입니다.

$$
\lambda x+(1-\lambda)y\in C,
\qquad
0\le\lambda\le 1
$$

직관적으로는 집합 안에서 두 점을 골라 직선을 그었을 때, 그 직선이 집합 밖으로 나가지 않는 모양입니다.

## 13. Convex Function

정의역 $$C$$가 convex set인 함수 $$f:C\to\mathbb{R}$$에 대해, 임의의 $$x,y\in C$$와 $$0\le\lambda\le 1$$에 대해 다음을 만족하면 $$f$$를 convex function이라고 합니다.

$$
f(\lambda x+(1-\lambda)y)
\le
\lambda f(x)+(1-\lambda)f(y)
$$

왼쪽은 두 입력을 먼저 섞은 뒤 함수에 넣은 값이고, 오른쪽은 두 함수값을 선형 보간한 값입니다. Convex function은 chord가 graph 위에 있거나 같다는 직관으로 이해할 수 있습니다.

## 14. Convex Function 예시: $$f(x)=x^2$$

$$f(x)=x^2$$는 convex function입니다. 두 점 $$x_1,x_2$$와 $$0\le\lambda\le 1$$에 대해 확인하면 다음과 같습니다.

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

가 성립합니다.

## 15. Convex Function 예시: Negative Entropy

강의에서는 인공지능에서 중요한 함수인 negative entropy 예시를 듭니다.

$$
f(x)=x\log x,
\qquad x>0
$$

이 함수가 convex인 이유는 두 번째 미분이 양수이기 때문입니다.

$$
f'(x)=\log x+1
$$

$$
f''(x)=\frac{1}{x}>0
\qquad (x>0)
$$

따라서 $$x>0$$ 구간에서 $$x\log x$$는 convex function입니다. 정보이론과 머신러닝에서 entropy, cross entropy, KL divergence를 이해할 때 이 형태가 자주 등장합니다.

## 16. Convex Function의 성질

Convex function은 다음 성질을 가집니다.

| 성질 | 의미 |
|---|---|
| convex 함수의 합 | $$f_1+f_2$$도 convex |
| nonnegative weighted sum | $$\alpha,\beta\ge0$$이면 $$\alpha f_1+\beta f_2$$도 convex |
| local minimum | convex function에서는 local minimum이 global optimum |

예를 들어 $$f_1$$, $$f_2$$가 convex이면

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

두 식을 더하면 $$f_1+f_2$$도 convex임을 알 수 있습니다.

## 17. 최적화식의 보강 증명

Gradient descent의 감소 보장은 smoothness와 충분히 작은 step size가 필요하고, Newton update는 local quadratic approximation의 stationary point에서 나옵니다. Convex 함수에서는 선분 조건과 1차 최적성 조건 때문에 local minimum이 global minimum이 됩니다.

<details markdown="block">
<summary markdown="span">Derivation: Descent conditions, Newton updates, and convex optimality</summary>

### 17.1 Gradient descent가 내려가는 조건

$$f$$의 gradient가 $$L$$-Lipschitz라고 가정하면 descent lemma로

$$
f(x+s)\le f(x)+\nabla f(x)^Ts+\frac{L}{2}\lVert s\rVert_2^2
$$

입니다. $$s=-\alpha\nabla f(x)$$를 대입하면

$$
f(x-\alpha\nabla f(x))
\le f(x)-\alpha\left(1-\frac{L\alpha}{2}\right)\lVert\nabla f(x)\rVert_2^2.
$$

따라서 $$0<\alpha<2/L$$이면 stationary point가 아닌 곳에서 상계가 감소합니다. 이는 해당 smoothness 가정 아래의 **정확한 보장**이지, 모든 함수와 모든 step size에서 loss가 감소한다는 경험 법칙이 아닙니다.

### 17.2 Newton update 재유도

2회 미분 가능하고 현재 Hessian $$H_k$$가 가역이라고 하겠습니다. 2차 Taylor **근사**

$$
q(s)=f(\theta_k)+g_k^Ts+\frac12s^TH_ks
$$

의 gradient는 $$g_k+H_ks$$입니다. 이를 0으로 두면 $$s=-H_k^{-1}g_k$$, 즉 $$\theta_{k+1}=\theta_k-H_k^{-1}g_k$$입니다. $$H_k$$가 positive definite일 때만 이 stationary point가 이차 근사의 최소점이며, indefinite Hessian이면 하강 방향을 보장하지 않습니다.

### 17.3 Convex local minimum은 global minimum

$$x^*$$가 local minimum인데 더 낮은 점 $$y$$가 있다고 가정하겠습니다. 충분히 작은 $$t\in(0,1)$$에 대해 $$z_t=(1-t)x^*+ty$$는 $$x^*$$ 근방에 있습니다. Convexity로

$$
f(z_t)\le(1-t)f(x^*)+tf(y)<f(x^*)
$$

이므로 local minimum 정의와 모순입니다. 따라서 모든 local minimum은 global minimum입니다. 정의역이 convex이고 함수가 convex라는 조건이 모두 필요합니다.

$$\alpha$$는 parameter 단위/gradient 단위를 가져 update의 차원을 맞춥니다. loss가 무차원이고 parameter가 $$u$$ 단위라면 gradient는 $$u^{-1}$$, Hessian은 $$u^{-2}$$ 단위입니다. 딥러닝의 learning rate는 구현상 숫자로 취급되지만 feature scaling에 민감한 이유가 여기에 있습니다.

</details>

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| gradient descent update는 무엇입니까? | $$x_{i+1}=x_i-\gamma_i\nabla f(x_i)$$ |
| step size가 너무 작으면 어떻게 됩니까? | 수렴이 느려집니다. |
| step size가 너무 크면 어떻게 됩니까? | 최소점을 지나치거나 발산할 수 있습니다. |
| momentum의 역할은 무엇입니까? | 이전 이동 방향을 누적해 zigzag를 줄이고 valley 방향 이동을 강화합니다. |
| SGD가 필요한 이유는 무엇입니까? | 전체 데이터 gradient 계산 비용을 줄이기 위해 |
| mini-batch의 trade-off는 무엇입니까? | 클수록 정확하지만 비싸고, 작을수록 빠르지만 noisy합니다. |
| Newton method가 추가로 쓰는 정보는 무엇입니까? | Hessian, 즉 2차 곡률 정보 |
| convex set의 정의는 무엇입니까? | 두 점을 잇는 선분이 모두 집합 안에 남는 집합 |
| convex function의 장점은 무엇입니까? | local minimum이 global optimum이 됩니다. |
| $$x\log x$$가 $$x>0$$에서 convex인 이유는 무엇입니까? | 두 번째 미분 $$1/x$$가 양수이기 때문 |

## Study Guide

<details markdown="block">
<summary markdown="span">학습 방법 보기</summary>

간단한 convex function에서 gradient descent를 여러 step size로 실행해 느린 수렴과 overshoot·발산을 비교합니다. batch, SGD, mini-batch는 gradient 비용과 noise의 trade-off로, momentum과 Newton method는 누적 방향과 Hessian 사용 여부로 구분합니다. convex set의 선분 조건과 convex function의 local minimum=global optimum 성질은 2차 미분 예제와 함께 검산합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Gradient descent가 gradient의 반대 방향으로 이동하는 이유는 무엇입니까?</summary>

답변: gradient $$\nabla f(x)$$는 현재 위치에서 함수가 가장 빠르게 증가하는 방향입니다. 최소화를 하려면 함수값을 줄여야 하므로 그 반대 방향인 $$-\nabla f(x)$$로 움직입니다. step size $$\gamma$$는 그 방향으로 얼마나 이동할지 정합니다.

</details>

<details markdown="block">
<summary>2. Gradient descent가 zigzag로 느릴 때 momentum은 어떤 도움을 줍니까?</summary>

답변: momentum은 이전 update 방향을 현재 update에 누적합니다. 같은 방향으로 계속 움직이는 성분은 강화되고, 좌우로 진동하는 성분은 서로 상쇄됩니다. 그래서 길고 좁은 valley에서 zigzag를 줄이고 수렴을 빠르게 만들 수 있습니다.

</details>

<details markdown="block">
<summary>3. mini-batch가 작으면 gradient가 noisy해지는데도 실제 학습에서 유용할 수 있는 이유는 무엇입니까?</summary>

답변: 작은 mini-batch는 계산 비용이 낮아 update를 자주 할 수 있습니다. 또한 gradient noise가 saddle point나 나쁜 local minimum 근처에서 빠져나오는 데 도움을 줄 수 있습니다. 다만 너무 작으면 수렴이 불안정해질 수 있어 learning rate와 함께 조절해야 합니다.

</details>

<details markdown="block">
<summary>4. Newton method는 gradient descent와 무엇이 다릅니까?</summary>

답변: gradient descent는 gradient만 사용해 하강 방향을 정합니다. Newton method는 Hessian까지 사용해 목적 함수의 곡률을 반영합니다. 2차 Taylor 근사의 최소점을 다음 위치로 삼기 때문에 잘 맞는 경우 빠르지만, Hessian 계산과 역행렬 계산이 비쌉니다.

</details>

<details markdown="block">
<summary>5. Convexity가 보장되지 않는 neural network 학습에서는 어떤 어려움이 생깁니까?</summary>

답변: non-convex objective에서는 local minimum, saddle point, flat region이 존재할 수 있습니다. 따라서 찾은 해가 global optimum인지 보장하기 어렵습니다. initialization, optimizer, learning rate, regularization에 따라 학습 결과가 달라질 수 있습니다.

</details>

<details markdown="block">
<summary>6. Convex function에서는 왜 local minimum이 global optimum이 됩니까?</summary>

답변: convex function은 두 점 사이가 위로 볼록하지 않고 하나의 그릇처럼 이어집니다. 만약 어떤 local minimum보다 더 낮은 점이 다른 곳에 있다면, 두 점을 잇는 선분 위에서 함수값이 계속 내려가는 방향이 생겨 local minimum이라는 가정과 충돌합니다. 그래서 convex function의 local minimum은 전역 최적해입니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-14.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-14.pdf</a></li>
</ul>
