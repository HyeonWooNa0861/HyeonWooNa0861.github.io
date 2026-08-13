---
layout: default
title: "Lecture 08 Matrix Decomposition 2"
course: "Machine Learning Basic"
topic: "Matrix Decomposition 2"
order: 8
major_topic: "Machine Learning Foundations"
keywords:
  - "Matrix Decomposition"
  - "Eigen Decomposition"
  - "SVD"
  - "Principal Components"
  - "Low-Rank Approximation"
---

# Lecture 08 Matrix Decomposition 2

Source PDF: `machine-learning-basic-lecture-08.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Cholesky 분해 | SPD 행렬은 어떻게 삼각행렬 곱으로 나뉘는가? |
| 2 | 대각화 | 행렬을 대각행렬과 닮은 형태로 바꾸면 무엇이 쉬워지는가? |
| 3 | 고유분해 | 고유벡터가 기저를 이루면 행렬을 어떻게 분해하는가? |
| 4 | SVD | 정사각행렬이 아니어도 행렬을 어떻게 분해할 수 있는가? |
| 5 | SVD 활용 | 추천 시스템과 low-rank approximation은 왜 SVD를 쓰는가? |

## 1. Cholesky 분해

SPD 행렬은 양의 대각 원소를 가지는 하삼각행렬 \\(L\\)을 이용해 분해할 수 있다.

$$
A = LL^T
$$

이 분해는 SPD 시스템을 효율적으로 풀 때 유용하다. 역행렬을 직접 구하는 대신 삼각행렬 시스템을 순차적으로 풀 수 있다.

## 2. 대각화와 고유분해

행렬 \\(A\\)가 어떤 대각행렬 \\(D\\)와 닮았으면 \\(A\\)는 diagonalizable하다고 한다.

$$
A = PDP^{-1}
$$

여기서 \\(P\\)는 고유벡터들을 열로 모은 행렬이고, \\(D\\)는 대응하는 고유값을 대각 원소로 가진 행렬이다.

대각화가 유용한 이유:

| 계산 | 대각행렬에서 쉬운 이유 |
|---|---|
| 행렬 거듭제곱 | 대각 원소만 거듭제곱하면 된다. |
| 행렬식 | 대각 원소 곱 |
| 역행렬 | 대각 원소 역수 |

## 3. 대각화 가능 조건

\\(A\\)가 \\(n\\)개의 선형 독립인 고유벡터를 가지면 대각화 가능하다.

대칭행렬은 항상 대각화 가능하다. 머신러닝에서 covariance matrix처럼 대칭행렬이 자주 등장하므로 이 성질은 PCA와 직접 연결된다.

## 4. SVD

SVD(Singular Value Decomposition)는 \\(m \times n\\) 행렬에도 적용할 수 있는 강력한 행렬 분해다.

$$
A = U\Sigma V^T
$$

| 요소 | 의미 |
|---|---|
| \\(U\\) | left singular vectors |
| \\(\Sigma\\) | singular values를 담은 대각형 행렬 |
| \\(V\\) | right singular vectors |

정사각 대칭행렬의 경우 SVD는 고유분해와 매우 비슷해진다.

## 5. SVD 계산 관점

SVD는 \\(A^TA\\)와 \\(AA^T\\)의 고유값/고유벡터와 연결된다.

| 대상 | 연결 |
|---|---|
| \\(A^TA\\) | right singular vectors |
| \\(AA^T\\) | left singular vectors |
| 고유값 | singular value의 제곱과 연결 |

\\(A^TA\\)와 \\(AA^T\\)는 같은 non-zero eigenvalue를 공유한다.

## 6. SVD의 활용

| 활용 | 설명 |
|---|---|
| 추천 시스템 | 사용자-아이템 행렬을 잠재요인으로 분해 |
| 데이터 근사 | 큰 행렬을 낮은 rank 행렬로 근사 |
| 차원 축소 | 중요한 singular value 방향만 남김 |
| 노이즈 제거 | 작은 singular value 성분 제거 |

Rank-\\(k\\) approximation은 큰 데이터 행렬을 중요한 \\(k\\)개의 성분만으로 근사한다. PCA의 핵심 아이디어도 이와 연결된다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Cholesky 분해가 가능한 행렬은? | SPD 행렬 |
| 대각화 가능 조건은? | 선형 독립인 고유벡터가 충분히 있음 |
| SVD가 고유분해보다 일반적인 이유는? | \\(m \times n\\) 행렬에도 적용 가능 |
| SVD의 대표 활용은? | 추천 시스템, low-rank approximation, 차원 축소 |

## 복습 질문

<details>
<summary>1. 대칭행렬이 PCA에서 중요한 이유는 무엇인가?</summary>

답변: PCA에서 covariance matrix는 대칭행렬이다. 대칭행렬은 orthogonal eigenvector basis를 가지므로 서로 직교하는 principal direction을 안정적으로 얻을 수 있다. 각 eigenvalue는 그 방향의 분산 크기를 나타낸다.

</details>

<details>
<summary>2. \\(A = U\Sigma V^T\\)에서 singular value가 큰 방향은 어떤 의미인가?</summary>

답변: singular value는 해당 singular vector 방향으로 데이터나 변환이 얼마나 큰 에너지를 가지는지 나타낸다. 값이 큰 방향은 정보량이나 분산이 큰 주요 방향이고, 작은 방향은 상대적으로 덜 중요한 성분으로 볼 수 있다.

</details>

<details>
<summary>3. low-rank approximation은 왜 데이터 압축으로 해석될 수 있는가?</summary>

답변: 큰 singular value에 해당하는 상위 \\(k\\)개 성분만 남기면 원래 행렬의 주요 구조를 보존하면서 저장해야 할 정보량을 줄일 수 있다. 작은 singular value 성분은 노이즈나 세부 정보로 보고 버리기 때문에 압축으로 해석된다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-08.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-08.pdf</a></li>
</ul>
