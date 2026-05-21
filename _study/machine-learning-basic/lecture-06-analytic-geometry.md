---
layout: default
title: "Lecture 06 Analytic Geometry"
course: "Machine Learning Basic"
topic: "Analytic Geometry"
order: 6
---

# Lecture 06 Analytic Geometry

Source PDF: `machine-learning-basic-lecture-06.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Norm | 벡터의 길이는 어떻게 정의하는가? |
| 2 | Inner Product | 각도와 직교성을 정의하려면 무엇이 필요한가? |
| 3 | SPD Matrix | 내적은 행렬로 어떻게 표현되는가? |
| 4 | Distance and Orthogonality | 거리, 각도, 수직은 내적에 따라 어떻게 달라지는가? |
| 5 | Projection | 부분공간에서 가장 가까운 벡터는 어떻게 찾는가? |
| 6 | Rotation | 길이와 각도를 보존하는 변환은 무엇인가? |

## 1. Norm

Norm은 벡터를 길이로 보내는 함수다.

대표 예시는 다음과 같다.

| 이름 | 직관 |
|---|---|
| Manhattan norm / \(\ell_1\) | 좌표축을 따라 이동한 거리 |
| Euclidean norm / \(\ell_2\) | 직선 거리 |

Norm은 양수성, 스칼라곱에 대한 비례성, 삼각부등식을 만족해야 한다.

## 2. Inner Product

내적은 두 벡터를 받아 실수를 반환하는 함수이며, 길이와 각도를 정의하는 핵심 도구다.

일반적인 내적은 다음 성질을 가진다.

| 성질 | 의미 |
|---|---|
| bilinear | 각 인자에 대해 선형 |
| symmetric | 인자 순서를 바꿔도 값이 같다. |
| positive definite | 0이 아닌 벡터의 자기 내적은 양수 |

우리가 흔히 쓰는 dot product는 내적의 한 예일 뿐이다. 내적이 달라지면 길이, 각도, 수직의 개념도 달라질 수 있다.

## 3. SPD Matrix와 내적

정렬된 기저를 잡으면 내적은 행렬로 표현될 수 있다. 이때 내적에 대응하는 행렬은 symmetric positive definite(SPD) 행렬이다.

| 행렬 | 조건 |
|---|---|
| SPD | symmetric이고 \(x^T A x > 0\) for \(x \ne 0\) |
| SPSD | symmetric이고 \(x^T A x \ge 0\) |

SPD 행렬은 영공간이 0만 포함하고, 대각 원소가 모두 양수라는 성질을 가진다.

## 4. 거리, 각도, 직교성

내적은 norm을 만들고, norm은 거리를 만든다.

$$
d(x,y) = \lVert x-y\rVert
$$

거리 함수는 양수성, 대칭성, 삼각부등식을 만족한다.

두 벡터가 수직이라는 것은 내적이 0이라는 뜻이다.

$$
\langle x,y\rangle = 0
$$

내적이 바뀌면 수직인지 아닌지도 달라질 수 있다.

## 5. Orthogonal Matrix와 Orthonormal Basis

직교행렬은 모든 열벡터가 서로 정규직교인 정사각행렬이다.

$$
A^TA = I
$$

직교행렬은 dot product 기준에서 길이와 각도를 보존한다. 회전 행렬이 대표적인 예다.

정규직교 기저는 서로 수직이고 각 벡터 길이가 1인 기저다. Gram-Schmidt 과정으로 구할 수 있다.

## 6. Projection

Projection은 벡터를 부분공간 위의 가장 가까운 벡터로 보내는 선형 변환이다.

1차원 부분공간에서는 벡터 \(x\)를 방향 벡터 \(u\) 위로 내린 그림자로 이해할 수 있다.

\(m\)차원 부분공간으로의 projection은 least squares와 직접 연결된다. \(Ax=b\)의 해가 없을 때, \(b\)에 가장 가까운 column space 위의 벡터를 찾는 문제가 projection이다.

## 7. Rotation

회전은 길이와 각도를 보존하는 선형 변환이다.

| 특성 | 설명 |
|---|---|
| 거리 보존 | 회전 전후 벡터 사이 거리가 같다. |
| 각도 보존 | 회전 전후 벡터 사이 각도가 같다. |
| 비가환성 | 3차원 회전은 일반적으로 순서가 바뀌면 결과가 달라진다. |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| norm과 inner product의 관계는? | 모든 내적은 norm을 만들지만 모든 norm이 내적에서 오지는 않는다. |
| SPD 행렬의 의미는? | 내적을 표현할 수 있는 symmetric positive definite 행렬 |
| orthogonal matrix의 핵심 성질은? | 길이와 각도 보존, \(A^TA = I\) |
| projection이 least squares와 연결되는 이유는? | column space에서 가장 가까운 벡터를 찾기 때문 |

## 복습 질문

1. dot product가 아닌 내적에서는 수직의 의미가 어떻게 달라질 수 있는가?
2. \(A^TA = I\)이면 왜 \(A^{-1} = A^T\)인가?
3. \(Ax=b\)에 해가 없을 때 projection 관점에서는 무엇을 찾는가?


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-06.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-06.pdf</a></li>
</ul>
