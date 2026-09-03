---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 09 Vector Calculus"
course: "Machine Learning Basic"
topic: "Vector Calculus"
order: 9
major_topic: "Machine Learning Foundations"
keywords:
  - "Vector Calculus"
  - "Gradients"
  - "Partial Derivatives"
  - "Jacobian"
  - "Chain Rule"
---

# Lecture 09 Vector Calculus

Source PDF: `machine-learning-basic-lecture-09.pdf`

> **핵심:** **gradient가 중요한 이유는** loss를 줄이는 update 방향을 계산하기 위해. **Taylor series의 역할은** 복잡한 함수를 기준점 근처에서 근사.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 미분의 필요성 | 에러를 줄이는 방향은 어떻게 계산하는가? |
| 2 | Taylor series | 복잡한 함수를 다항식으로 어떻게 근사하는가? |
| 3 | 편미분과 gradient | 다변수 함수에서 각 입력의 영향은 어떻게 측정하는가? |
| 4 | Chain rule | 합성 함수의 미분은 어떻게 계산하는가? |
| 5 | Jacobian과 행렬 미분 | 벡터 출력 함수의 미분은 어떤 행렬로 표현되는가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 수식 | 본문 대응 |
|---:|---|---|
| 3–6 | 함수, 평균변화율, 극한으로서의 미분, 유한 Taylor polynomial | 1, 2, 7.1 |
| 7–10 | Taylor series·Maclaurin series, 미분 규칙과 scalar chain rule | 2, 4, 7.1 |
| 11–18 | 편미분, gradient, 다변수 chain rule, Jacobian | 3–5, 7.2, 7.3 |
| 19–22 | 행렬 chain rule과 핵심 행렬 미분 항등식 | 6, 7.3–7.5 |

페이지 23은 Q&A 마무리이다. Taylor 전개는 수렴반경 안의 무한급수와 유한 차수 근소 근사를 구분해 7.1에서 해석한다.

## 1. 왜 벡터 미적분학이 필요한가?

머신러닝 모델은 데이터를 보고 prediction error를 계산한 뒤, error를 줄이는 방향으로 parameter를 업데이트한다.

에러를 가장 빠르게 증가시키는 방향은 gradient이고, 에러를 줄이려면 그 반대 방향으로 움직인다.

$$
f:\mathbb{R}^D \to \mathbb{R}, \qquad x \mapsto f(x)
$$

따라서 gradient 계산은 학습 알고리즘의 핵심이다.

## 2. 미분과 Taylor series

미분은 한 점 근처에서 함수값이 얼마나 빠르게 변하는지 측정한다.

Taylor series는 복잡한 함수를 기준점 주변의 다항식으로 근사하는 방법이다.

| 차수 | 의미 |
|---|---|
| 0차 | 함수값만 사용 |
| 1차 | 함수값 + 기울기 사용 |
| 2차 | 함수값 + 기울기 + 곡률 사용 |

최적화에서 1차 근사는 gradient descent, 2차 근사는 Newton method와 연결된다.

## 3. 편미분과 Gradient

다변수 함수 $$f(x_1,\ldots,x_n)$$에서 한 변수만 움직이고 나머지는 고정해 미분한 것을 편미분이라고 한다.

모든 편미분을 모은 것이 gradient다. 이 글에서는 scalar 함수의 gradient를 일관되게 $$n\times1$$ **열벡터**로 둔다.

$$
\nabla_x f =
\begin{bmatrix}
\frac{\partial f}{\partial x_1} \\
\vdots \\
\frac{\partial f}{\partial x_n}
\end{bmatrix}
$$

강의에서는 미분의 차원을 헷갈리지 않도록 첫 번째 차원을 함수 차원, 두 번째 차원을 입력 차원으로 두는 관점을 강조한다.

## 4. 미분 규칙

기본 규칙은 1변수와 다변수 모두에서 중요하다.

| 규칙 | 용도 |
|---|---|
| 곱셈 규칙 | 두 함수의 곱 미분 |
| 합 규칙 | 여러 항의 합 미분 |
| 연쇄 법칙 | 합성 함수 미분 |

딥러닝의 backpropagation은 큰 계산 그래프에 연쇄 법칙을 반복 적용하는 과정이다.

## 5. Jacobian Matrix

입력도 벡터이고 출력도 벡터인 함수에서는 미분 결과가 행렬이 된다. 이를 Jacobian matrix라고 한다.

$$
f:\mathbb{R}^n \to \mathbb{R}^m
$$

$$
J \in \mathbb{R}^{m \times n}, \qquad
J_{ij} = \frac{\partial f_i}{\partial x_j}
$$

Jacobian은 입력 변화가 출력 각 성분에 어떤 영향을 주는지 담는다.

## 6. 행렬 미분

머신러닝 loss는 벡터와 행렬로 표현되는 경우가 많다. 따라서 $$x^TAx$$, $$\lVert Ax-b\rVert^2$$ 같은 식의 미분 공식이 자주 쓰인다.

공식만 외우기보다 차원 검사를 함께 해야 한다. 미분 결과가 parameter와 같은 shape인지 확인하면 실수를 줄일 수 있다.

## 7. 핵심 미분식의 유도

### 7.1 미분의 극한 정의와 일반 Taylor 전개

원문에서 1변수 미분은 평균 변화율의 극한이라는 **정의**로 시작한다. 유한한 $$h$$에 대한 차분몫은 평균 변화율이고, 극한이 존재할 때만 미분값이 된다.

$$
f'(x)=\frac{df}{dx}
:=\lim_{h\to0}\frac{f(x+h)-f(x)}{h}.
$$

좌극한과 우극한이 다르거나 극한이 발산하면 그 점에서 미분 불가능하다. 따라서 ReLU의 0처럼 꺾인 점에 적용할 때는 고전적 미분 대신 별도로 정한 subgradient convention을 구분해야 한다.

$$f$$가 $$x_0$$와 $$x$$를 포함하는 구간에서 $$n+1$$회 연속 미분 가능하면 $$n$$차 Taylor 다항식은

$$
T_n(x)=\sum_{k=0}^{n}\frac{f^{(k)}(x_0)}{k!}(x-x_0)^k
$$

이고, 어떤 $$\xi$$가 $$x_0$$와 $$x$$ 사이에 존재하여

$$
f(x)=T_n(x)+R_n(x),
\qquad
R_n(x)=\frac{f^{(n+1)}(\xi)}{(n+1)!}(x-x_0)^{n+1}
$$

로 쓸 수 있다. 앞 식의 유한합과 나머지항은 조건 아래 **정확한 등식**이고, $$f(x)\approx T_n(x)$$라고 나머지를 버릴 때만 **근사**다. $$x$$가 $$x_0$$에서 멀거나 고계도 미분이 크면 오차가 커질 수 있다. 무한 Taylor 급수 $$\sum_{k=0}^{\infty}f^{(k)}(x_0)(x-x_0)^k/k!$$가 함수 자체와 같으려면 단순히 무한번 미분 가능하다는 것만으로는 부족하고, 나머지항이 0으로 수렴해야 한다. $$x_0=0$$이면 Maclaurin 급수다.

### 7.2 1차 Taylor 근사와 gradient 방향

$$f:\mathbb{R}^n\to\mathbb{R}$$가 $$x$$ 근방에서 미분 가능하면 작은 $$\Delta x$$에 대해

$$
f(x+\Delta x)=f(x)+\nabla f(x)^T\Delta x+o(\lVert\Delta x\rVert)
$$

이다. 첫 두 항만 쓰는 것은 **1차 근사**이며 $$\Delta x$$가 커지거나 곡률이 크면 오차가 커진다. $$\lVert\Delta x\rVert_2=\varepsilon$$로 고정하면 Cauchy-Schwarz 부등식으로 $$\nabla f^T\Delta x\le\varepsilon\lVert\nabla f\rVert_2$$이고, 등호는 $$\Delta x$$가 gradient와 같은 방향일 때 성립한다. 따라서 gradient는 국소적으로 가장 빠른 증가 방향이다.

### 7.3 Chain rule의 행렬 형태

$$g:\mathbb{R}^n\to\mathbb{R}^m$$, $$f:\mathbb{R}^m\to\mathbb{R}^p$$가 미분 가능하면 작은 변화는 $$\Delta g\approx J_g\Delta x$$, $$\Delta f\approx J_f\Delta g$$이므로

$$
J_{f\circ g}(x)=J_f(g(x))J_g(x)
$$

이다. 이는 미분 가능성 아래의 **정확한 미분 항등식**이며 행렬곱 순서를 바꾸면 안 된다.

### 7.4 자주 쓰는 이차식 미분

$$q(x)=x^TAx=\sum_{i,j}x_iA_{ij}x_j$$를 성분별로 미분하면

$$
\frac{\partial q}{\partial x_k}=\sum_jA_{kj}x_j+\sum_i x_iA_{ik},
\qquad
\nabla q=(A+A^T)x.
$$

$$A$$가 대칭일 때만 $$2Ax$$로 단순화된다. 또한 $$L(x)=\lVert Ax-b\rVert_2^2=(Ax-b)^T(Ax-b)$$이므로

$$
\nabla_xL=2A^T(Ax-b).
$$

$$x$$가 물리 단위를 가지면 gradient 성분의 단위는 `함수값 단위 / 해당 입력 단위`다. Jacobian 원소도 `출력 단위 / 입력 단위`이며 무조건 무차원은 아니다.

### 7.5 Determinant와 inverse의 행렬 미분

다음은 원문 마지막 공식표의 핵심 두 식을 differential로 유도한 **보충 해설**이다. $$X\in\mathbb{R}^{n\times n}$$가 가역이고 실수 행렬이며, scalar 함수의 gradient는 $$dg=\operatorname{tr}((\nabla_Xg)^T dX)$$를 만족하는 Frobenius inner-product convention으로 정의한다.

Jacobi 공식에서

$$
d\det(X)=\det(X)\operatorname{tr}(X^{-1}dX)
=\operatorname{tr}\left((\det(X)X^{-T})^T dX\right)
$$

이므로

$$
\nabla_X\det(X)=\det(X)X^{-T}.
$$

이는 가역행렬에서의 **정확한 미분 항등식**이다. $$\det(X)=0$$인 점에서도 determinant 자체는 미분 가능하지만 위의 inverse 표현은 사용할 수 없고, cofactor로 만든 adjugate 표현을 써야 한다.

Inverse는 항등식 $$XX^{-1}=I$$를 미분하여 유도한다.

$$
(dX)X^{-1}+X\,d(X^{-1})=0.
$$

왼쪽에 $$X^{-1}$$를 곱하면

$$
d(X^{-1})=-X^{-1}(dX)X^{-1}.
$$

성분별로는

$$
\frac{\partial(X^{-1})_{ij}}{\partial X_{k\ell}}
=-(X^{-1})_{ik}(X^{-1})_{\ell j}.
$$

이 식도 $$X$$가 가역인 열린 영역에서만 성립한다. singular 또는 매우 ill-conditioned한 행렬 근처에서는 inverse가 정의되지 않거나 작은 입력 변화가 큰 derivative를 만들어 수치 해석이 불안정하다. $$X$$의 원소가 단위 $$U$$를 가지면 $$X^{-1}$$은 $$U^{-1}$$, determinant는 $$U^n$$인 동종 단위 행렬에서 위 식들의 단위도 각각 호환된다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| gradient가 중요한 이유는? | loss를 줄이는 update 방향을 계산하기 위해 |
| Taylor series의 역할은? | 복잡한 함수를 기준점 근처에서 근사 |
| Jacobian의 shape은? | $$f:\mathbb{R}^n \to \mathbb{R}^m$$이면 $$m \times n$$ |
| chain rule이 중요한 이유는? | 합성 함수와 신경망 미분의 기반 |

## Study Guide

scalar, vector, matrix 출력에 따라 derivative와 Jacobian shape를 먼저 적고 계산을 시작한다. 합성 함수 하나를 계산 graph로 풀어 chain rule을 적용한 뒤, 같은 흐름이 neural network gradient로 이어짐을 확인한다. Taylor 0·1·2차 근사가 함수값·gradient·curvature를 어디까지 포함하는지 구분하는 문제가 시험 우선순위다.

## 복습 질문

<details markdown="block">
<summary>1. gradient는 함수값을 가장 빠르게 증가시키는 방향인가, 감소시키는 방향인가?</summary>

답변: gradient는 함수값이 가장 빠르게 증가하는 방향이다. 최소화 문제에서는 그 반대 방향인 negative gradient 방향으로 이동한다. 이것이 gradient descent의 기본 아이디어다.

</details>

<details markdown="block">
<summary>2. 1차 Taylor 근사와 2차 Taylor 근사는 최적화에서 각각 어떤 알고리즘과 연결되는가?</summary>

답변: 1차 Taylor 근사는 gradient 정보를 사용하므로 gradient descent 같은 1차 최적화와 연결된다. 2차 Taylor 근사는 곡률 정보인 Hessian까지 사용하므로 Newton method 같은 2차 최적화와 연결된다.

</details>

<details markdown="block">
<summary>3. Jacobian에서 행과 열은 각각 무엇에 대응하는가?</summary>

답변: $$f:\mathbb{R}^n\to\mathbb{R}^m$$이면 Jacobian은 보통 $$m\times n$$ 행렬이다. 행은 출력 성분 $$f_i$$, 열은 입력 변수 $$x_j$$에 대응하며, 원소는 $$\partial f_i/\partial x_j$$이다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-09.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-09.pdf</a></li>
</ul>
