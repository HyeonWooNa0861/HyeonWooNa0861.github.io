---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
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

> **핵심:** **determinant의 기하학적 의미는** 부피/면적 변화율. **$$\det(A)=0$$이면** 가역 불가능, full rank 아님.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 행렬식 | 선형 변환이 부피를 얼마나 바꾸는가? |
| 2 | 가역성과 행렬식 | $$\det(A)=0$$은 무엇을 의미하는가? |
| 3 | Trace | 대각합은 어떤 불변량으로 쓰이는가? |
| 4 | 특성 방정식 | 고유값은 어떻게 찾는가? |
| 5 | 고유값과 고유벡터 | 변환 후에도 방향이 유지되는 벡터는 무엇인가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 정리·식 | 본문 대응 |
|---:|---|---|
| 3–13 | determinant 정의·Laplace 전개·성질과 $$\det(A)\ne0\Leftrightarrow\operatorname{rk}(A)=n$$ | 1–3, 8.1 |
| 14–15 | trace의 정의와 cyclic invariance | 4, 8.3 |
| 16–19 | 특성방정식 $$\det(A-\lambda I)=0$$, eigenspace | 5, 6, 8.2 |
| 20–23 | 고유값·고유벡터 계산과 고유벡터 기저 조건 | 5–7 |
| 24–25 | $$\det(A)=\prod_i\lambda_i$$, $$\operatorname{tr}(A)=\sum_i\lambda_i$$ | 7, 8.3 |

페이지 26은 Q&A 마무리이다.

## 1. 행렬식 Determinant

행렬식은 정사각행렬에 대해 정의되는 값이다. 선형 변환으로 공간의 부피가 얼마나 변하는지를 나타낸다고 볼 수 있다.

2차원에서는 두 열벡터가 만드는 평행사변형의 넓이와 관련된다. 두 열벡터가 선형 종속이면 넓이는 0이고, 따라서 determinant도 0이다.

## 2. 가역성과 행렬식

정사각행렬 $$A$$에 대해 다음은 동치다.

| 조건 | 의미 |
|---|---|
| $$A$$가 invertible | 역행렬이 존재한다. |
| $$\det(A) \ne 0$$ | 부피가 0으로 collapse되지 않는다. |
| $$A$$가 full rank | 열벡터들이 선형 독립이다. |

반대로 $$\det(A)=0$$이면 어떤 방향이 사라져 변환이 정보를 잃는다.

## 3. 행렬식의 주요 성질

| 성질 | 설명 |
|---|---|
| 행/열 하나를 다른 행/열에 더함 | determinant 값은 변하지 않는다. |
| 행/열 하나에 $$c$$를 곱함 | determinant도 $$c$$배 된다. |
| 두 행/열 교환 | determinant 부호가 바뀐다. |
| invertible 행렬 | determinant가 0이 아니다. |

이 성질들은 행 연산과 rank, invertibility를 연결한다.

원문 슬라이드의 cofactor 전개를 정확히 쓰면 다음과 같다. $$A_{r,c}$$는 $$A$$에서 $$r$$번째 행과 $$c$$번째 열을 제거한 $$(n-1)\times(n-1)$$ 소행렬이다. 고정한 열 또는 행은 어느 것이어도 되며, 두 식은 모두 **정확한 항등식**이다.

$$
\det(A)=\sum_{k=1}^{n}(-1)^{k+j}a_{kj}\det(A_{k,j})
\qquad\text{(column }j\text{ expansion)}
$$

$$
\det(A)=\sum_{k=1}^{n}(-1)^{j+k}a_{jk}\det(A_{j,k})
\qquad\text{(row }j\text{ expansion)}
$$

부호는 체스판 모양 $$(-1)^{r+c}$$를 따른다. 따라서 0이 많은 행이나 열을 고르면 계산량이 줄지만, 행렬이 커지면 cofactor 전개는 비효율적이어서 수치 계산에는 보통 elimination 계열을 쓴다.

원문의 예제

$$
A=
\begin{bmatrix}
1&2&3\\
3&1&2\\
0&0&1
\end{bmatrix}
$$

를 첫 번째 행으로 전개하면

$$
\begin{aligned}
\det(A)
&=1\begin{vmatrix}1&2\\0&1\end{vmatrix}
-2\begin{vmatrix}3&2\\0&1\end{vmatrix}
+3\begin{vmatrix}3&1\\0&0\end{vmatrix}\\
&=1(1-0)-2(3-0)+3(0-0)=-5.
\end{aligned}
$$

세 번째 행으로 전개하면 0인 두 항이 사라져 $$\det(A)=1\begin{vmatrix}1&2\\3&1\end{vmatrix}=1(1-6)=-5$$다. 같은 determinant를 얻으며, 0이 많은 행을 선택하는 직관도 확인된다.

## 4. Trace

Trace는 정사각행렬의 대각 원소 합이다.

$$
\operatorname{tr}(A) = \sum_i A_{ii}
$$

Trace는 선형성과 cyclic property 같은 중요한 성질을 가진다. 특히 닮은 행렬은 같은 trace를 가진다.

원문에서 사용한 trace 항등식은 다음과 같다. 합과 곱의 크기가 정의되고 trace를 취하는 최종 곱이 정사각행렬이라는 조건 아래 모두 **정확한 등식**이다.

$$
\begin{aligned}
\operatorname{tr}(A+B)&=\operatorname{tr}(A)+\operatorname{tr}(B),\\
\operatorname{tr}(\alpha A)&=\alpha\operatorname{tr}(A),\\
\operatorname{tr}(I_n)&=n,\\
\operatorname{tr}(AB)&=\operatorname{tr}(BA),\\
\operatorname{tr}(AKL)&=\operatorname{tr}(KLA)=\operatorname{tr}(LAK),\\
\operatorname{tr}(xy^T)&=\operatorname{tr}(y^Tx)=y^Tx.
\end{aligned}
$$

마지막 식에서 $$x,y\in\mathbb{R}^n$$이고 $$y^Tx$$는 $$1\times1$$ scalar다. cyclic property는 인자의 **순환 이동**만 허용하며, 일반적으로 $$\operatorname{tr}(AKL)=\operatorname{tr}(ALK)$$는 아니다. 또한 $$B=S^{-1}AS$$인 닮은 행렬이면

$$
\operatorname{tr}(B)=\operatorname{tr}(S^{-1}AS)
=\operatorname{tr}(ASS^{-1})=\operatorname{tr}(A).
$$

Trace를 대각 원소의 단순 합으로 보는 것보다, 좌표계를 바꾸어도 유지되는 scalar 요약량으로 보면 이 항등식들의 쓰임이 분명해진다.

## 5. 고유값과 고유벡터

정사각행렬 $$A$$에 대해 0이 아닌 벡터 $$v$$와 스칼라 $$\lambda$$가 다음을 만족하면:

$$
Av = \lambda v
$$

$$\lambda$$는 eigenvalue, $$v$$는 eigenvector다.

고유벡터는 변환 후에도 같은 직선 위에 남으며 길이는 $$\lvert\lambda\rvert$$배 바뀐다. $$\lambda>0$$이면 방향이 유지되고, $$\lambda<0$$이면 방향이 반대로 뒤집히며, $$\lambda=0$$이면 0벡터로 눌린다.

## 6. 특성 방정식과 고유공간

고유값은 특성 방정식의 해로 찾는다.

$$
\det(A - \lambda I) = 0
$$

고유값 $$\lambda$$에 대한 고유공간은 다음 영공간이다.

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

## 8. 핵심 성질의 증명

### 8.1 $$\det(A)=0$$과 비가역성

정사각행렬 $$A$$에 대해 다음은 **정확한 동치**다.

1. $$A$$가 가역이면 $$1=\det(I)=\det(AA^{-1})=\det(A)\det(A^{-1})$$이므로 $$\det(A)\ne0$$다.
2. $$\det(A)=0$$이면 열벡터들이 선형 종속이어서 어떤 $$x\ne0$$에 대해 $$Ax=0$$이다.
3. 서로 다른 $$0$$과 $$x$$가 같은 출력 0으로 가므로 $$A$$는 injective가 아니고 역행렬이 없다.

기하적으로는 적어도 한 독립 방향이 눌려 부피 scale이 0이 되는 상황이다.

### 8.2 특성방정식의 유도

고유벡터의 **정의** $$Av=\lambda v$$, $$v\ne0$$에서 $$(A-\lambda I)v=0$$을 얻는다. 0이 아닌 해가 있으려면 $$A-\lambda I$$가 비가역이어야 하므로

$$
\det(A-\lambda I)=0
$$

이다. 이 식의 근은 후보 고유값이고, 각 근마다 영공간을 풀어 고유벡터를 구한다.

### 8.3 Trace와 determinant의 고유값 표현

대각화 가능한 경우 $$A=PDP^{-1}$$, $$D=\operatorname{diag}(\lambda_1,\ldots,\lambda_n)$$다. 곱셈법칙과 cyclic trace 성질을 쓰면

$$
\det(A)=\prod_{i=1}^n\lambda_i,
\qquad
\operatorname{tr}(A)=\sum_{i=1}^n\lambda_i.
$$

일반 정사각행렬에도 대수적 중복도를 포함하면 같은 결론이 성립하지만, 완전한 증명에는 Schur 분해 또는 특성다항식 계수 이론이 필요하다. 행렬 원소가 물리 단위를 가지면 determinant는 열 단위의 곱을 가지며, trace는 대각 원소들의 단위가 같을 때만 물리적으로 해석할 수 있다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| determinant의 기하학적 의미는? | 부피/면적 변화율 |
| $$\det(A)=0$$이면? | 가역 불가능, full rank 아님 |
| eigenvector의 의미는? | 변환 후 방향이 유지되는 0이 아닌 벡터 |
| SPD 행렬의 고유값은? | 양의 실수 |

## Study Guide

행 스케일과 행 교환이 determinant에 미치는 영향을 적용한 뒤 det(A)=0을 non-invertible·rank deficient와 연결한다. eigenvector는 Av=λv를 만족하며 방향이 보존되는 벡터이므로 characteristic equation으로 λ를 구하고 null space에서 v를 찾는 순서를 손으로 반복한다. symmetric matrix의 실수 eigenvalue와 SPD matrix의 양의 eigenvalue 조건을 구분해 암기한다.

## 복습 질문

<details markdown="block">
<summary>1. 선형 종속인 열벡터를 가진 행렬의 determinant는 왜 0인가?</summary>

답변: 열벡터가 선형 종속이면 행렬이 공간을 더 낮은 차원으로 눌러버린다. 이 경우 변환된 부피가 0이 되므로 determinant도 0이다. 대수적으로는 역행렬이 존재하지 않는 singular matrix다.

</details>

<details markdown="block">
<summary>2. 닮은 행렬이 같은 고유스펙트럼을 가진다는 말은 어떤 의미인가?</summary>

답변: 닮은 행렬은 같은 선형 변환을 다른 좌표계에서 표현한 것이다. 좌표 표현은 달라도 변환의 본질적인 scale factor인 eigenvalue들의 집합은 같다. 이 eigenvalue들의 모음을 eigen spectrum이라고 볼 수 있다.

</details>

<details markdown="block">
<summary markdown="span">3. 고유공간이 $$\operatorname{Null}(A-\lambda I)$$인 이유를 설명해보자.</summary>

답변: eigenvector는 $$Av=\lambda v$$를 만족한다. 이를 옮기면 $$(A-\lambda I)v=0$$이므로, 해당 $$\lambda$$에 대한 모든 eigenvector는 $$A-\lambda I$$의 null space에 속한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-07.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-07.pdf</a></li>
</ul>
