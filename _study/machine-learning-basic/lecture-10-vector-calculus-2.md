---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 10 Vector Calculus 2"
course: "Machine Learning Basic"
topic: "Vector Calculus 2"
order: 10
major_topic: "Machine Learning Foundations"
keywords:
  - "Hessian"
  - "Taylor Expansion"
  - "Optimization"
  - "Gradient Descent"
  - "Multivariable Calculus"
---

# Lecture 10 Vector Calculus 2

Source PDF: `machine-learning-basic-lecture-10.pdf`

> **핵심:** **backpropagation의 수학적 기반은** chain rule. **automatic differentiation의 두 흐름은** forward pass와 backward pass.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Gradient 복습 | 다변수 함수의 미분을 어떻게 정리하는가? |
| 2 | Backpropagation | 신경망 parameter의 gradient는 어떻게 계산되는가? |
| 3 | Automatic Differentiation | 계산 그래프를 따라 미분을 자동화하는 방식은 무엇인가? |
| 4 | Higher-order derivatives | Hessian은 함수의 어떤 정보를 담는가? |
| 5 | Multivariate Taylor | 다변수 함수도 Taylor 근사로 볼 수 있는가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 수식·알고리즘 | 본문 대응 |
|---:|---|---|
| 3–6 | 편미분과 gradient 복습 | 1 |
| 7–10 | 신경망 계산 그래프의 backpropagation·chain rule | 2, 7.1 |
| 11–15 | forward/reverse automatic differentiation | 3, 7.1 |
| 16–17 | 고계도 미분과 Hessian $$H_{ij}=\partial^2f/(\partial x_i\partial x_j)$$ | 4 |
| 18–23 | 1·2차 다변수 Taylor 근사 | 5, 7.2 |

페이지 24는 Q&A 마무리이다.

## 1. Gradient 복습

입력이 `n`차원이고 출력이 1차원인 함수에서 각 입력 변수에 대한 편미분을 모은 것이 gradient다.

머신러닝에서는 loss가 parameter에 대해 얼마나 민감하게 변하는지를 gradient로 계산하고, 이를 이용해 parameter를 업데이트한다.

## 2. Backpropagation

신경망은 여러 아핀 변환과 비선형 함수가 합성된 함수다.

```text
x -> A x + b -> nonlinear activation -> output
```

신경망을 학습한다는 것은 주어진 $$(x,y)$$에서 모델 출력이 $$y$$에 가까워지도록 $$A$$, $$b$$ 같은 parameter를 조정하는 것이다.

loss에 대한 parameter gradient는 합성 함수의 chain rule을 통해 계산된다. 이 계산을 효율적으로 뒤에서 앞으로 전파하는 과정이 backpropagation이다.

## 3. Automatic Differentiation

Automatic differentiation은 계산 그래프의 각 연산에 대해 미분값을 저장하고 chain rule로 전체 미분을 계산하는 방법이다.

| 단계 | 의미 |
|---|---|
| Forward pass | 입력부터 출력까지 함수값을 계산 |
| Backward pass | 출력의 미분 정보를 입력/parameter 방향으로 전달 |

Backpropagation은 neural network에 적용된 automatic differentiation의 대표 사례다.

## 4. Higher-order derivatives

1차 미분은 gradient이고, 2차 미분은 곡률 정보를 준다.

Hessian matrix는 다변수 함수의 모든 2차 편미분을 모은 행렬이다.

$$
\nabla^2_{x,y} f(x,y) =
\begin{bmatrix}
\frac{\partial^2 f}{\partial x^2} &
\frac{\partial^2 f}{\partial x\partial y} \\
\frac{\partial^2 f}{\partial y\partial x} &
\frac{\partial^2 f}{\partial y^2}
\end{bmatrix}
$$

Hessian은 점 근처에서 함수가 얼마나 휘어 있는지 나타낸다. 최적화에서는 Newton method, convexity 판별, local minimum 분석에 사용된다.

## 5. 다변수 Taylor series

1변수 Taylor series처럼 다변수 함수도 기준점 주변에서 근사할 수 있다.

| 근사 | 포함 정보 |
|---|---|
| 1차 Taylor | 함수값 + gradient |
| 2차 Taylor | 함수값 + gradient + Hessian |

2차 근사는 함수의 곡률까지 반영하므로 단순 gradient보다 더 풍부한 지역 정보를 담는다.

## 6. 머신러닝 관점

| 개념 | 머신러닝 연결 |
|---|---|
| Backpropagation | neural network parameter gradient 계산 |
| Automatic differentiation | PyTorch, TensorFlow의 autograd |
| Hessian | loss landscape의 곡률 |
| Taylor approximation | 최적화 알고리즘의 근사 기반 |

## 7. Backpropagation과 2차 근사의 유도

### 7.1 작은 계산 그래프의 역전파

$$z=Ax+b$$, $$h=\phi(z)$$, $$L=\ell(h)$$라 하자. 모두 미분 가능하다는 가정 아래 chain rule은 **정확한 항등식**으로

$$
\frac{\partial L}{\partial z}
=\frac{\partial L}{\partial h}\odot\phi'(z)
$$

을 준다. $$\delta=\partial L/\partial z$$로 놓으면 성분식 $$z_i=\sum_jA_{ij}x_j+b_i$$에서

$$
\frac{\partial L}{\partial A_{ij}}=\delta_i x_j,
\qquad
\nabla_A L=\delta x^T,
\qquad
\nabla_bL=\delta,
\qquad
\nabla_xL=A^T\delta
$$

를 얻는다. activation이 ReLU처럼 일부 점에서 미분 불가능하면 구현은 subgradient convention을 사용하며, 그 점에서 고전적 미분값이 유일하다고 말할 수 없다.

원문 슬라이드의 automatic differentiation 예제는 다음 scalar 계산 그래프다.

$$
\begin{aligned}
a&=x^2, & b&=\exp(a), & c&=a+b,\\
d&=\sqrt{c}, & e&=\cos(c), & f&=d+e.
\end{aligned}
$$

즉

$$
f(x)=\sqrt{x^2+\exp(x^2)}
+\cos\left(x^2+\exp(x^2)\right).
$$

Forward pass는 $$x\to a$$ 뒤에 $$a\to b$$와 $$a\to c$$로 갈라지고, $$a,b\to c$$에서 합쳐진 뒤 $$c\to d$$와 $$c\to e$$로 다시 갈라져 $$d,e\to f$$에서 합쳐진다. 모든 중간값은 scalar이며, $$\exp$$와 $$\cos$$의 입력은 무차원이라고 가정한다.

Backward pass에서는 adjoint $$\bar v=\partial f/\partial v$$를 출력부터 계산한다. 한 노드로 들어오는 여러 경로의 기여는 반드시 **더한다**.

$$
\bar f=1,
\qquad
\bar d=1,
\qquad
\bar e=1,
$$

$$
\bar c
=\bar d\frac{\partial d}{\partial c}
+\bar e\frac{\partial e}{\partial c}
=\frac{1}{2\sqrt c}-\sin(c),
$$

$$
\bar b=\bar c,
\qquad
\bar a
=\bar c\frac{\partial c}{\partial a}
+\bar b\frac{\partial b}{\partial a}
=\bar c\left(1+\exp(a)\right),
$$

$$
\frac{df}{dx}=\bar x
=\bar a\frac{\partial a}{\partial x}
=2x\left(\frac{1}{2\sqrt c}-\sin(c)\right)
\left(1+\exp(a)\right).
$$

$$a=x^2$$, $$c=x^2+\exp(x^2)$$를 대입하면 원문의 최종 계산과 같은

$$
\frac{df}{dx}
=2x\left(
\frac{1}{2\sqrt{x^2+\exp(x^2)}}
-\sin\left(x^2+\exp(x^2)\right)
\right)
\left(1+\exp(x^2)\right)
$$

를 얻는다. 이는 chain rule로 얻은 **정확한 derivative**다. $$c=x^2+\exp(x^2)>0$$이므로 이 예제에서는 square-root derivative의 분모가 0이 되지 않는다. 직관적으로 reverse mode는 각 중간값이 최종 출력에 미치는 민감도를 한 번 저장해 공유 경로에서 재사용한다.

### 7.2 다변수 2차 Taylor 근사

$$f$$가 기준점 $$x$$ 근방에서 2회 연속 미분 가능하면 $$\Delta\to0$$일 때

$$
f(x+\Delta)
= f(x)+\nabla f(x)^T\Delta+
\frac12\Delta^T\nabla^2f(x)\Delta
+o(\lVert\Delta\rVert^2)
$$

이다. 따라서 작은 $$\Delta$$에서 little-o 나머지를 버린 식이 **2차 근사**다. $$C^2$$ 조건만으로 나머지를 일반적으로 “3차항” 또는 $$O(\lVert\Delta\rVert^3)$$라고 단정할 수는 없다. 그런 3차 오차 경계를 쓰려면 선분 근방에서 3계 도함수가 존재하고 bounded하다는 등의 더 강한 조건이 필요하다. Hessian이 양의 정부호이면 이 이차 근사는 그 점 근방에서 그릇 모양이지만, 실제 함수 전체의 전역 convexity까지 보장하지는 않는다.

| 기호 | 의미 | 크기·단위 |
|---|---|---|
| $$A,b$$ | weight matrix, bias | 출력/입력 단위, 출력 단위 |
| $$x,z,h$$ | 입력, pre-activation, activation | layer 정의에 따른 단위 |
| $$L$$ | scalar loss | loss가 정한 단위, 흔히 무차원 |
| $$\delta$$ | $$\partial L/\partial z$$ | loss 단위/$$z$$ 단위 |
| $$(\nabla^2f)_{ij}$$ | Hessian의 $$(i,j)$$ 성분 | 함수값 단위/$$(x_i\text{ 단위}\times x_j\text{ 단위})$$. 모든 입력 단위가 같을 때만 이를 `함수값 단위/입력 단위²`로 줄여 쓸 수 있다. |

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| backpropagation의 수학적 기반은? | chain rule |
| automatic differentiation의 두 흐름은? | forward pass와 backward pass |
| Hessian은 무엇을 나타내는가? | 함수의 2차 미분, 곡률 |
| 2차 Taylor 근사가 1차보다 더 담는 정보는? | 곡률 정보 |

## Study Guide

작은 계산 graph에서 forward value를 저장하고 output에서 input 방향으로 local derivative를 곱해 backpropagation을 재현한다. automatic differentiation은 수치미분이 아니라 연산 graph와 chain rule을 이용한다는 점을 먼저 구분한다. Hessian과 2차 Taylor 항은 curvature를 추가하므로 1차 gradient 정보와 무엇이 달라지는지 식의 shape까지 확인한다.

## 복습 질문

<details markdown="block">
<summary>1. 신경망에서 parameter gradient가 필요한 이유는 무엇인가?</summary>

답변: parameter gradient는 loss를 줄이기 위해 각 parameter를 어느 방향으로 얼마나 바꿔야 하는지 알려준다. gradient가 없으면 수많은 parameter를 체계적으로 업데이트하기 어렵다.

</details>

<details markdown="block">
<summary>2. Backpropagation과 automatic differentiation은 어떤 관계인가?</summary>

답변: automatic differentiation은 계산 그래프의 chain rule을 체계적으로 적용해 미분을 계산하는 일반 방법이다. backpropagation은 neural network 학습에서 loss의 gradient를 뒤에서 앞으로 전파하는 reverse-mode automatic differentiation의 대표적인 형태다.

</details>

<details markdown="block">
<summary>3. Hessian이 positive definite이면 그 점 근처의 함수 모양은 어떻게 해석할 수 있는가?</summary>

답변: Hessian이 positive definite이면 모든 방향으로 곡률이 양수라는 뜻이다. 그 점 주변에서 함수는 bowl shape처럼 위로 볼록하며, gradient가 0이라면 local minimum으로 해석할 수 있다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-10.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-10.pdf</a></li>
</ul>
