---
layout: default
title: "Lecture 09 Vector Calculus"
course: "Machine Learning Basic"
topic: "Vector Calculus"
order: 9
---

# Lecture 09 Vector Calculus

Source PDF: `machine-learning-basic-lecture-09.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 미분의 필요성 | 에러를 줄이는 방향은 어떻게 계산하는가? |
| 2 | Taylor series | 복잡한 함수를 다항식으로 어떻게 근사하는가? |
| 3 | 편미분과 gradient | 다변수 함수에서 각 입력의 영향은 어떻게 측정하는가? |
| 4 | Chain rule | 합성 함수의 미분은 어떻게 계산하는가? |
| 5 | Jacobian과 행렬 미분 | 벡터 출력 함수의 미분은 어떤 행렬로 표현되는가? |

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

다변수 함수 \\(f(x_1,\ldots,x_n)\\)에서 한 변수만 움직이고 나머지는 고정해 미분한 것을 편미분이라고 한다.

모든 편미분을 모은 것이 gradient다.

$$
\nabla_x f = \frac{df}{dx} =
\left[
\frac{\partial f}{\partial x_1},
\ldots,
\frac{\partial f}{\partial x_n}
\right]
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

머신러닝 loss는 벡터와 행렬로 표현되는 경우가 많다. 따라서 \\(x^TAx\\), \\(\lVert Ax-b\rVert^2\\) 같은 식의 미분 공식이 자주 쓰인다.

공식만 외우기보다 차원 검사를 함께 해야 한다. 미분 결과가 parameter와 같은 shape인지 확인하면 실수를 줄일 수 있다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| gradient가 중요한 이유는? | loss를 줄이는 update 방향을 계산하기 위해 |
| Taylor series의 역할은? | 복잡한 함수를 기준점 근처에서 근사 |
| Jacobian의 shape은? | \\(f:\mathbb{R}^n \to \mathbb{R}^m\\)이면 \\(m \times n\\) |
| chain rule이 중요한 이유는? | 합성 함수와 신경망 미분의 기반 |

## 복습 질문

<details>
<summary>1. gradient는 함수값을 가장 빠르게 증가시키는 방향인가, 감소시키는 방향인가?</summary>

답변: gradient는 함수값이 가장 빠르게 증가하는 방향이다. 최소화 문제에서는 그 반대 방향인 negative gradient 방향으로 이동한다. 이것이 gradient descent의 기본 아이디어다.

</details>

<details>
<summary>2. 1차 Taylor 근사와 2차 Taylor 근사는 최적화에서 각각 어떤 알고리즘과 연결되는가?</summary>

답변: 1차 Taylor 근사는 gradient 정보를 사용하므로 gradient descent 같은 1차 최적화와 연결된다. 2차 Taylor 근사는 곡률 정보인 Hessian까지 사용하므로 Newton method 같은 2차 최적화와 연결된다.

</details>

<details>
<summary>3. Jacobian에서 행과 열은 각각 무엇에 대응하는가?</summary>

답변: \\(f:\mathbb{R}^n\to\mathbb{R}^m\\)이면 Jacobian은 보통 \\(m\times n\\) 행렬이다. 행은 출력 성분 \\(f_i\\), 열은 입력 변수 \\(x_j\\)에 대응하며, 원소는 \\(\partial f_i/\partial x_j\\)이다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-09.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-09.pdf</a></li>
</ul>
