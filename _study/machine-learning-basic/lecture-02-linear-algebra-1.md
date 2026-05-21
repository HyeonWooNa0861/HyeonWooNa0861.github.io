---
layout: default
title: "Lecture 02 Linear Algebra 1"
course: "Machine Learning Basic"
topic: "Linear Algebra 1"
order: 2
---

# Lecture 02 Linear Algebra 1

Source PDF: `machine-learning-basic-lecture-02.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 벡터와 벡터공간 | 벡터는 단순한 화살표보다 넓은 개념인가? |
| 2 | 선형연립방정식 | 여러 선형 조건의 해는 어떻게 표현되는가? |
| 3 | 행렬 | 행렬은 선형연립방정식을 어떻게 압축해 표현하는가? |
| 4 | 역행렬과 전치 | 행렬 연산의 기본 성질은 무엇인가? |
| 5 | REF/RREF | 기본 행 연산으로 해를 어떻게 구하는가? |

## 1. 벡터의 관점

벡터는 덧셈과 스칼라곱이 정의된 대상이다. 기하학적 화살표뿐 아니라 다항식, 오디오 신호도 같은 연산 구조를 가지면 벡터처럼 다룰 수 있다.

머신러닝에서는 대부분 데이터를 \\(\mathbb{R}^D\\)의 벡터로 표현하므로, 선형대수는 데이터와 모델을 다루는 기본 언어가 된다.

## 2. 선형연립방정식

많은 문제는 선형연립방정식으로 표현할 수 있다.

$$
Ax = b
$$

해의 형태는 세 가지로 나뉜다.

| 경우 | 의미 |
|---|---|
| 유일한 해 | 조건들이 한 점에서 만난다. |
| 무한히 많은 해 | 조건들이 선이나 평면처럼 겹친다. |
| 해 없음 | 조건들이 서로 모순된다. |

기하학적으로 2차원에서는 두 직선이 한 점에서 만나거나, 같은 직선이거나, 평행해서 만나지 않는 경우로 이해할 수 있다.

## 3. 행렬과 기본 연산

행렬은 선형연립방정식을 체계적으로 표현하는 도구다.

| 형태 | 이름 |
|---|---|
| `(m, n)` | `m`행 `n`열 행렬 |
| `(1, n)` | 행 벡터 |
| `(m, 1)` | 열 벡터 |

행렬에는 덧셈, 곱셈, 항등행렬, 결합법칙, 분배법칙 등이 있다. 단, 행렬곱은 일반적으로 교환법칙이 성립하지 않는다.

## 4. 역행렬과 전치행렬

정사각행렬 \\(A\\)에 대해 \\(AB = BA = I\\)를 만족하는 \\(B\\)가 있으면 \\(B\\)를 \\(A\\)의 역행렬이라 하고 \\(A^{-1}\\)로 쓴다. 역행렬이 존재하는 행렬은 invertible이라고 한다.

전치행렬은 행과 열을 바꾼 행렬이다.

$$
(A^T)_{ij} = A_{ji}
$$

대칭행렬은 \\(A = A^T\\)를 만족한다. 대칭행렬의 합은 대칭행렬이지만, 곱은 일반적으로 대칭행렬이 아닐 수 있다.

## 5. 선형연립방정식 풀이 구조

\\(Ax = b\\)를 풀 때는 다음 관점이 중요하다.

1. \\(Ax = b\\)를 만족하는 particular solution을 찾는다.
2. \\(Ax = 0\\)을 만족하는 homogeneous solution을 찾는다.
3. 전체 해는 particular solution + homogeneous solution으로 표현한다.

즉 해가 하나만 있는지, 무한히 많은지는 \\(Ax = 0\\)의 해 공간이 얼마나 큰지와 연결된다.

## 6. 기본 행 연산과 REF/RREF

기본 행 연산은 선형연립방정식의 해를 바꾸지 않는 변환이다.

| 연산 | 설명 |
|---|---|
| 행 교환 | 두 행의 순서를 바꾼다. |
| 행 스케일 | 한 행에 0이 아닌 실수를 곱한다. |
| 행 더하기 | 한 행에 다른 행의 배수를 더한다. |

REF(Row Echelon Form)는 pivot이 아래 행으로 갈수록 오른쪽에 위치하는 형태다. RREF(Reduced Row Echelon Form)는 REF이면서 모든 pivot이 1이고, pivot 열에서 pivot만 0이 아닌 형태다.

## 7. 계산 방법의 현실적 주의점

역행렬을 직접 계산해 \\(x = A^{-1}b\\)로 푸는 방식은 이론적으로 명확하지만 계산량이 크고 수치적으로 불안정할 수 있다. 그래서 실제 계산에서는 행 연산, Moore-Penrose inverse, iterative methods 같은 방법도 중요하다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| REF와 RREF의 차이는? | RREF는 pivot이 1이고 pivot 열의 다른 값이 0 |
| 기본 행 연산 3가지는? | 행 교환, 행 스케일, 행 더하기 |
| 전체 해 구조는? | particular solution + homogeneous solution |
| 역행렬 풀이의 한계는? | 계산량과 수치 불안정성 |

## 복습 질문

<details>
<summary>1. \\(Ax=b\\)가 해를 가지려면 \\(b\\)는 어떤 공간에 있어야 하는가?</summary>

답변: \\(b\\)는 \\(A\\)의 column space 안에 있어야 한다. \\(Ax\\)는 \\(A\\)의 열벡터들의 선형 결합이므로, 만들 수 있는 모든 \\(b\\)는 column space에 속한다.

</details>

<details>
<summary>2. RREF에서 free variable은 언제 생기는가?</summary>

답변: pivot이 없는 column이 있을 때 free variable이 생긴다. 이 변수는 다른 pivot variable에 의해 고정되지 않으므로 여러 값을 가질 수 있고, 해가 무한히 많아지는 원인이 된다.

</details>

<details>
<summary>3. 행렬곱이 교환법칙을 만족하지 않는다는 것은 모델 계산에서 어떤 주의점을 주는가?</summary>

답변: \\(AB\\)와 \\(BA\\)는 일반적으로 다르며, 심지어 한쪽만 정의될 수도 있다. 따라서 선형 변환을 합성할 때 순서가 의미를 바꾸고, neural network의 layer 순서도 임의로 바꿀 수 없다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-02.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-02.pdf</a></li>
</ul>
