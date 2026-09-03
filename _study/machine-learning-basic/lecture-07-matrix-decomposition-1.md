---
layout: default
date: 2026-05-20 12:30:12 +0900
title: "Lecture 07 Matrix Decomposition 1"
course: "Machine Learning Basic"
topic: "Matrix Decomposition 1"
order: 7
major_topic: "Machine Learning Foundations"
keywords:
  - "Matrix Decomposition"
  - "LU Decomposition"
  - "Gaussian Elimination"
  - "Matrix Factorization"
  - "Linear Solvers"
---

# Lecture 07 Matrix Decomposition 1

Source PDF: `machine-learning-basic-lecture-07.pdf`

> **핵심:** **determinant의 기하학적 의미는** 부피/면적 변화율. **\(\det(A)=0\)이면** 가역 불가능, full rank 아님.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 행렬식 | 선형 변환이 부피를 얼마나 바꾸는가? |
| 2 | 가역성과 행렬식 | \(\det(A)=0\)은 무엇을 의미하는가? |
| 3 | Trace | 대각합은 어떤 불변량으로 쓰이는가? |
| 4 | 특성 방정식 | 고유값은 어떻게 찾는가? |
| 5 | 고유값과 고유벡터 | 변환 후에도 방향이 유지되는 벡터는 무엇인가? |

## 1. 행렬식 Determinant

행렬식은 정사각행렬에 대해 정의되는 값이다. 선형 변환으로 공간의 부피가 얼마나 변하는지를 나타낸다고 볼 수 있다.

2차원에서는 두 열벡터가 만드는 평행사변형의 넓이와 관련된다. 두 열벡터가 선형 종속이면 넓이는 0이고, 따라서 determinant도 0이다.

## 2. 가역성과 행렬식

정사각행렬 \(A\)에 대해 다음은 동치다.

| 조건 | 의미 |
|---|---|
| \(A\)가 invertible | 역행렬이 존재한다. |
| \(\det(A) \ne 0\) | 부피가 0으로 collapse되지 않는다. |
| \(A\)가 full rank | 열벡터들이 선형 독립이다. |

반대로 \(\det(A)=0\)이면 어떤 방향이 사라져 변환이 정보를 잃는다.

## 3. 행렬식의 주요 성질

| 성질 | 설명 |
|---|---|
| 행/열 하나를 다른 행/열에 더함 | determinant 값은 변하지 않는다. |
| 행/열 하나에 \(c\)를 곱함 | determinant도 \(c\)배 된다. |
| 두 행/열 교환 | determinant 부호가 바뀐다. |
| invertible 행렬 | determinant가 0이 아니다. |

이 성질들은 행 연산과 rank, invertibility를 연결한다.

## 4. Trace

Trace는 정사각행렬의 대각 원소 합이다.

$$
\operatorname{tr}(A) = \sum_i A_{ii}
$$

Trace는 선형성과 cyclic property 같은 중요한 성질을 가진다. 특히 닮은 행렬은 같은 trace를 가진다.

## 5. 고유값과 고유벡터

정사각행렬 \(A\)에 대해 0이 아닌 벡터 \(v\)와 스칼라 \(\lambda\)가 다음을 만족하면:

$$
Av = \lambda v
$$

\(\lambda\)는 eigenvalue, \(v\)는 eigenvector다.

고유벡터는 변환 후에도 방향이 유지되고 길이만 \(\lambda\)배 바뀌는 벡터다.

## 6. 특성 방정식과 고유공간

고유값은 특성 방정식의 해로 찾는다.

$$
\det(A - \lambda I) = 0
$$

고유값 \(\lambda\)에 대한 고유공간은 다음 영공간이다.

$$
\operatorname{Null}(A - \lambda I)
$$

고유스펙트럼은 모든 고유값의 집합이다.

## 7. 기억할 성질

| 행렬 | 고유값/고유벡터 성질 |
|---|---|
| 대칭행렬 | 항상 실수 고유값을 가진다. |
| SPD 행렬 | 항상 양의 실수 고유값을 가진다. |
| 대칭행렬 | 고유벡터를 서로 수직이 되게 만들 수 있다. |
| 서로 다른 고유값의 고유벡터들 | 선형 독립이다. |

행렬식은 고유값들의 곱, trace는 고유값들의 합과 연결된다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| determinant의 기하학적 의미는? | 부피/면적 변화율 |
| \(\det(A)=0\)이면? | 가역 불가능, full rank 아님 |
| eigenvector의 의미는? | 변환 후 방향이 유지되는 0이 아닌 벡터 |
| SPD 행렬의 고유값은? | 양의 실수 |

## Study Guide

행 스케일과 행 교환이 determinant에 미치는 영향을 적용한 뒤 det(A)=0을 non-invertible·rank deficient와 연결한다. eigenvector는 Av=λv를 만족하며 방향이 보존되는 벡터이므로 characteristic equation으로 λ를 구하고 null space에서 v를 찾는 순서를 손으로 반복한다. symmetric matrix의 실수 eigenvalue와 SPD matrix의 양의 eigenvalue 조건을 구분해 암기한다.

## 복습 질문

<details>
<summary>1. 선형 종속인 열벡터를 가진 행렬의 determinant는 왜 0인가?</summary>

답변: 열벡터가 선형 종속이면 행렬이 공간을 더 낮은 차원으로 눌러버린다. 이 경우 변환된 부피가 0이 되므로 determinant도 0이다. 대수적으로는 역행렬이 존재하지 않는 singular matrix다.

</details>

<details>
<summary>2. 닮은 행렬이 같은 고유스펙트럼을 가진다는 말은 어떤 의미인가?</summary>

답변: 닮은 행렬은 같은 선형 변환을 다른 좌표계에서 표현한 것이다. 좌표 표현은 달라도 변환의 본질적인 scale factor인 eigenvalue들의 집합은 같다. 이 eigenvalue들의 모음을 eigen spectrum이라고 볼 수 있다.

</details>

<details>
<summary>3. 고유공간이 \(\operatorname{Null}(A-\lambda I)\)인 이유를 설명해보자.</summary>

답변: eigenvector는 \(Av=\lambda v\)를 만족한다. 이를 옮기면 \((A-\lambda I)v=0\)이므로, 해당 \(\lambda\)에 대한 모든 eigenvector는 \(A-\lambda I\)의 null space에 속한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-07.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-07.pdf</a></li>
</ul>
