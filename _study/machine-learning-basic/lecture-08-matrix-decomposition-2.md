---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
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

> **핵심:** 행렬 분해는 큰 계산을 다루기 쉬운 여러 단계로 나눕니다. Cholesky는 연립방정식을 빠르게 풀고, SVD는 데이터에서 영향이 큰 방향만 남겨 압축하거나 잡음을 줄이는 데 사용합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">학습 순서와 원문 대조 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Cholesky 분해 | SPD 행렬은 어떻게 삼각행렬 곱으로 나뉩니까? |
| 2 | 대각화 | 행렬을 대각행렬과 닮은 형태로 바꾸면 무엇이 쉬워집니까? |
| 3 | 고유분해 | 고유벡터가 기저를 이루면 행렬을 어떻게 분해합니까? |
| 4 | SVD | 정사각행렬이 아니어도 행렬을 어떻게 분해할 수 있습니까? |
| 5 | SVD 활용 | 추천 시스템과 low-rank approximation은 왜 SVD를 씁니까? |

### 원문 수식 추적표

| PDF 페이지 | 중요 분해식 | 본문 대응 |
|---:|---|---|
| 2–4 | determinant·eigenvalue 복습 | 2, 3 |
| 5 | Cholesky $$A=LL^T$$ | 1, 7.1 |
| 6–8 | 대각화 $$A=PDP^{-1}$$와 $$A^k=PD^kP^{-1}$$ | 2, 3, 7.2 |
| 9–13 | SVD $$A=U\Sigma V^T$$, $$A^TA$$·$$AA^T$$의 고유값 관계 | 4, 5, 7.3 |
| 14–16 | 추천 행렬과 truncated SVD $$A_k=\sum_{i=1}^k\sigma_i u_iv_i^T$$ | 6, 7.4 |

페이지 17은 Q&A 마무리입니다.

</details>

## 1. Cholesky 분해

행렬 분해는 큰 계산 하나를 더 다루기 쉬운 계산 여러 개로 바꾸는 도구입니다. Cholesky 분해에서는 대칭 양의 정부호 행렬을 삼각행렬과 그 전치의 곱으로 바꿉니다. 삼각행렬은 위나 아래가 0으로 채워져 있어, 연립방정식을 한 변수씩 순서대로 풀 수 있습니다.

SPD 행렬은 양의 대각 원소를 가지는 하삼각행렬 $$L$$을 이용해 분해할 수 있습니다.

$$
A = LL^T
$$

이 분해는 SPD 시스템을 효율적으로 풀 때 유용합니다. 역행렬을 직접 구하는 대신 삼각행렬 시스템을 순차적으로 풀 수 있습니다.

## 2. 대각화와 고유분해

행렬 $$A$$가 어떤 대각행렬 $$D$$와 닮았으면 $$A$$는 diagonalizable하다고 합니다.

$$
A = PDP^{-1}
$$

여기서 $$P$$는 고유벡터들을 열로 모은 행렬이고, $$D$$는 대응하는 고유값을 대각 원소로 가진 행렬입니다.

대각화가 유용한 이유:

| 계산 | 대각행렬에서 쉬운 이유 |
|---|---|
| 행렬 거듭제곱 | 대각 원소만 거듭제곱하면 됩니다. |
| 행렬식 | 대각 원소 곱 |
| 역행렬 | 대각 원소 역수 |

## 3. 대각화 가능 조건

$$A$$가 $$n$$개의 선형 독립인 고유벡터를 가지면 대각화 가능합니다.

대칭행렬은 항상 대각화 가능합니다. 머신러닝에서 covariance matrix처럼 대칭행렬이 자주 등장하므로 이 성질은 PCA와 직접 연결됩니다.

## 4. SVD

SVD는 행렬이 데이터를 어떻게 늘리고, 방향을 바꾸고, 다시 놓는지를 세 단계로 나눠 보여 줍니다. $$V^T$$가 입력의 기준 방향을 정렬하고, $$\Sigma$$가 각 방향을 늘리거나 줄이며, $$U$$가 결과를 출력 공간의 방향으로 놓습니다. 큰 singular value가 붙은 방향일수록 출력에 미치는 영향이 큽니다.

SVD(Singular Value Decomposition)는 $$m \times n$$ 행렬에도 적용할 수 있는 강력한 행렬 분해입니다.

$$
A = U\Sigma V^T
$$

| 요소 | 의미 |
|---|---|
| $$U$$ | left singular vectors |
| $$\Sigma$$ | singular values를 담은 대각형 행렬 |
| $$V$$ | right singular vectors |

정사각 대칭행렬의 경우 SVD는 고유분해와 매우 비슷해집니다.

## 5. SVD 계산 관점

SVD는 $$A^TA$$와 $$AA^T$$의 고유값/고유벡터와 연결됩니다.

| 대상 | 연결 |
|---|---|
| $$A^TA$$ | right singular vectors |
| $$AA^T$$ | left singular vectors |
| 고유값 | singular value의 제곱과 연결 |

$$A^TA$$와 $$AA^T$$는 같은 non-zero eigenvalue를 공유합니다.

## 6. SVD의 활용

<a href="{{ "/assets/images/study/machine-learning-basic/source-captures/lecture-08-page-15.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/machine-learning-basic/source-captures/lecture-08-page-15.png" | relative_url }}" alt="원본 강의 슬라이드의 SVD rank-k 근사식" loading="lazy"></a>

*원본 강의 PDF p. 15. 원행렬 $$A$$를 $$r$$개의 rank-1 행렬 $$\sigma_i u_i v_i^T$$의 합으로 쓴 뒤, 앞의 $$k$$개만 남겨 $$\hat A(k)$$를 만드는 식입니다. <a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-08.pdf#page=15" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 15</a>*

singular value를 큰 순서로 정렬하면 앞쪽 항이 행렬의 큰 변화 방향을 담습니다. $$k<r$$로 절단하면 저장량과 계산량을 줄이는 대신 뒤쪽 성분을 버리므로 근사 오차가 생깁니다.

| 활용 | 설명 |
|---|---|
| 추천 시스템 | 사용자-아이템 행렬을 잠재요인으로 분해 |
| 데이터 근사 | 큰 행렬을 낮은 rank 행렬로 근사 |
| 차원 축소 | 중요한 singular value 방향만 남김 |
| 노이즈 제거 | 작은 singular value 성분 제거 |

Rank-$$k$$ approximation은 큰 데이터 행렬을 중요한 $$k$$개의 성분만으로 근사합니다. PCA의 핵심 아이디어도 이와 연결됩니다.

## 7. 분해식의 유도와 조건

Cholesky는 symmetric positive definite 행렬에서만 실수 대각 원소를 양수로 고정해 유일해집니다. SVD는 $$A^TA$$의 고유벡터를 오른쪽 singular vector로 사용하며, rank-$$k$$ 절단의 최적성은 선택한 norm 조건 아래에서 성립합니다.

<details markdown="block">
<summary markdown="span">Derivation: Cholesky construction, SVD, and rank-k approximation</summary>

### 7.1 Cholesky 분해의 구성, 존재와 유일성

이 절은 원문이 제시한 $$A=LL^T$$를 단계별로 확인하기 위한 **보충 증명 개요**입니다. $$A\in\mathbb{R}^{n\times n}$$가 symmetric positive definite(SPD), 즉 $$A=A^T$$이고 모든 $$x\ne0$$에 대해 $$x^TAx>0$$라고 가정합니다. $$L$$은 양의 대각 원소를 갖는 하삼각행렬로 둡니다.

$$A=LL^T$$의 $$(i,j)$$ 원소를 앞에서부터 맞추면 다음 재귀식을 얻습니다.

$$
L_{jj}=\sqrt{A_{jj}-\sum_{k=1}^{j-1}L_{jk}^{2}},
$$

$$
L_{ij}=\frac{A_{ij}-\sum_{k=1}^{j-1}L_{ik}L_{jk}}{L_{jj}}
\qquad(i>j).
$$

SPD 조건 때문에 매 단계의 제곱근 안은 양수입니다. 첫 열을 분리해

$$
A=
\begin{bmatrix}
a_{11}&r^T\\
r&B
\end{bmatrix}
$$

로 쓰면 $$a_{11}>0$$이고 첫 pivot은 $$L_{11}=\sqrt{a_{11}}$$입니다. 첫 열을 제거한 Schur complement $$B-rr^T/a_{11}$$도 SPD이므로 같은 논리를 $$(n-1)\times(n-1)$$ 행렬에 반복할 수 있습니다. 이것이 위 재귀식이 끝까지 진행되어 **존재**함을 보이는 귀납적 핵심입니다.

양의 대각을 갖는 두 분해 $$A=LL^T=\widetilde L\widetilde L^T$$가 있다고 하겠습니다. $$Q=L^{-1}\widetilde L$$은 하삼각행렬이면서 $$QQ^T=I$$인 직교행렬이고 대각이 양수입니다. 이런 행렬은 $$I$$뿐이므로 $$L=\widetilde L$$이며 **유일성**이 따릅니다.

실패 조건도 함께 기억해야 합니다.

| 입력 상태 | 표준 Cholesky에서 생기는 문제 |
|---|---|
| 비대칭 | $$LL^T$$가 항상 대칭이므로 같은 형태로 표현할 수 없습니다. |
| indefinite | 어떤 단계에서 제곱근 안이 음수가 됩니다. |
| positive semidefinite이지만 not definite | pivot이 0일 수 있어 나눗셈이 중단되고, 양의 대각을 갖는 유일한 factor도 보장되지 않습니다. |
| 부동소수점 오차가 큰 nearly singular SPD | 이론상 양수인 pivot이 수치적으로 0 또는 음수처럼 보일 수 있습니다. |

식은 **정확한 분해**이며 근사가 아닙니다. 직관적으로 SPD가 모든 방향에 양의 에너지를 주기 때문에 각 단계에서 양의 pivot을 꺼낼 수 있습니다. 단위가 있는 행렬이라면 각 합 $$\sum_kL_{ik}L_{jk}$$의 단위가 $$A_{ij}$$와 같아야 하며, 그렇지 않은 항을 더하는 모델은 Cholesky 이전에 이미 단위 호환성이 깨집니다.

### 7.2 고유분해식 $$A=PDP^{-1}$$

선형 독립인 고유벡터 $$v_1,\ldots,v_n$$을 열로 모아 $$P=[v_1\ \cdots\ v_n]$$, 고유값을 $$D=\operatorname{diag}(\lambda_1,\ldots,\lambda_n)$$에 놓으면

$$
AP=[Av_1\ \cdots\ Av_n]=[\lambda_1v_1\ \cdots\ \lambda_nv_n]=PD.
$$

$$P$$가 가역이므로 오른쪽에 $$P^{-1}$$를 곱해 $$A=PDP^{-1}$$를 얻습니다. 이는 **정확한 등식**이며 독립 고유벡터가 $$n$$개 있어야 합니다.

### 7.3 $$A^TA$$에서 SVD가 나오는 과정

실수행렬 $$A\in\mathbb{R}^{m\times n}$$에 대해 $$A^TA$$는 대칭 positive semidefinite입니다. 따라서 직교정규 고유벡터 $$v_i$$와 음이 아닌 고유값 $$\lambda_i$$가 존재합니다.

1. $$A^TAv_i=\lambda_iv_i$$에서 $$\sigma_i=\sqrt{\lambda_i}\ge0$$로 둡니다.
2. $$\sigma_i>0$$이면 $$u_i=Av_i/\sigma_i$$로 둡니다.
3. $$u_i^Tu_j=v_i^TA^TAv_j/(\sigma_i\sigma_j)=\delta_{ij}$$라서 $$u_i$$들도 직교정규입니다.
4. $$Av_i=\sigma_i u_i$$를 모든 열에 모으면 $$AV=U\Sigma$$, 따라서 $$A=U\Sigma V^T$$입니다.

0 singular value에 해당하는 $$u_i$$는 직교기저로 보완합니다. singular value는 행렬 원소의 출력/입력 단위 비율을 가지며 $$U,V$$는 무차원 좌표변환입니다.

### 7.4 Rank-$$k$$ 근사의 보장 범위

$$r=\operatorname{rank}(A)$$이고 정수 $$0\le k<r$$라 하겠습니다. 상위 $$k$$개 항만 남긴 $$A_k=\sum_{i=1}^k\sigma_i u_iv_i^T$$는 Frobenius norm과 spectral norm에서 최적 **rank at most $$k$$** 근사라는 **Eckart-Young-Mirsky 정리**를 따릅니다. $$k=0$$일 때는 빈 합을 $$A_0=0$$으로 정의합니다. $$k\ge r$$이면 $$A_k=A$$로 둘 수 있어 두 norm의 최소 오차가 모두 0입니다. “작은 singular value는 항상 노이즈”는 정리가 아니라 응용상의 **휴리스틱**입니다. 약한 신호가 작은 singular value 방향에 놓이면 제거가 오히려 중요한 정보를 잃을 수 있습니다.

원문에는 rank-$$k$$ 근사식만 제시되어 있으므로 다음은 정리의 **보충 증명 개요**입니다. $$\sigma_1\ge\cdots\ge\sigma_r>0$$라 하고 $$B$$를 임의의 $$\operatorname{rank}(B)\le k$$ 행렬이라 하겠습니다. 아래의 $$\sigma_{k+1}$$ 식은 앞서 정한 $$0\le k<r$$ 범위에서 사용합니다.

1. $$A=U\Sigma V^T$$에서 직교행렬은 norm을 보존하므로 오차는 singular-vector 좌표계에서 비교해도 같습니다.
2. spectral norm의 경우 $$\operatorname{span}(v_1,\ldots,v_{k+1})$$는 $$(k+1)$$차원이지만 $$B$$의 rank는 최대 $$k$$입니다. 따라서 이 공간 안에 $$Bx=0$$인 단위벡터 $$x$$가 존재하고,

$$
\lVert A-B\rVert_2\ge\lVert(A-B)x\rVert_2
=\lVert Ax\rVert_2\ge\sigma_{k+1}.
$$

3. $$A_k$$는 이 하한을 정확히 달성하여 $$\lVert A-A_k\rVert_2=\sigma_{k+1}$$입니다.
4. Frobenius norm에서는 $$B$$의 열공간으로의 직교투영을 $$P_B$$라 하면 $$P_BB=B$$이므로

$$
\lVert A-B\rVert_F^2
=\lVert(I-P_B)A\rVert_F^2+\lVert P_BA-B\rVert_F^2
\ge\lVert(I-P_B)A\rVert_F^2.
$$

5. $$k$$차원 부분공간이 포착할 수 있는 제곱 에너지는 상위 $$k$$개 left singular direction에서 최대입니다. 따라서 남는 에너지는 적어도 $$\sum_{i>k}\sigma_i^2$$이고, $$B=A_k$$가 다시 등호를 달성합니다.

결론은

$$
\min_{\operatorname{rank}(B)\le k}\lVert A-B\rVert_2=\sigma_{k+1},
\qquad
\min_{\operatorname{rank}(B)\le k}\lVert A-B\rVert_F
=\left(\sum_{i>k}\sigma_i^2\right)^{1/2}
$$

입니다. 이 보장은 두 norm에 대한 전역 최적성이지, downstream prediction error나 의미 보존까지 보장하는 것은 아닙니다.

</details>

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Cholesky 분해가 가능한 행렬은 무엇입니까? | SPD 행렬 |
| 대각화 가능 조건은 무엇입니까? | 선형 독립인 고유벡터가 충분히 있음 |
| SVD가 고유분해보다 일반적인 이유는 무엇입니까? | $$m \times n$$ 행렬에도 적용 가능 |
| SVD의 대표 활용은 무엇입니까? | 추천 시스템, low-rank approximation, 차원 축소 |

## Study Guide

<details markdown="block">
<summary markdown="span">학습 방법 보기</summary>

SPD 여부를 먼저 확인해야 Cholesky를 적용할 수 있고, eigen-decomposition은 충분한 독립 eigenvector가 있을 때 가능하다는 전제부터 점검합니다. SVD는 직사각 행렬에도 적용되므로 AᵀA에서 right singular vector, AAᵀ에서 left singular vector를 찾는 계산 연결을 재현합니다. singular value를 큰 순서로 남기는 low-rank approximation이 차원 축소·추천·노이즈 제거에 쓰이는 이유를 설명합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. 대칭행렬이 PCA에서 중요한 이유는 무엇입니까?</summary>

답변: PCA에서 covariance matrix는 대칭행렬입니다. 대칭행렬은 orthogonal eigenvector basis를 가지므로 서로 직교하는 principal direction을 안정적으로 얻을 수 있습니다. 각 eigenvalue는 그 방향의 분산 크기를 나타냅니다.

</details>

<details markdown="block">
<summary markdown="span">2. $$A = U\Sigma V^T$$에서 singular value가 큰 방향은 어떤 의미입니까?</summary>

답변: singular value는 해당 singular vector 방향으로 데이터나 변환이 얼마나 큰 에너지를 가지는지 나타냅니다. 값이 큰 방향은 정보량이나 분산이 큰 주요 방향이고, 작은 방향은 상대적으로 덜 중요한 성분으로 볼 수 있습니다.

</details>

<details markdown="block">
<summary>3. low-rank approximation은 왜 데이터 압축으로 해석될 수 있습니까?</summary>

답변: 큰 singular value에 해당하는 상위 $$k$$개 성분만 남기면 원래 행렬의 주요 구조를 보존하면서 저장해야 할 정보량을 줄일 수 있습니다. 작은 singular value 성분은 노이즈나 세부 정보로 보고 버리기 때문에 압축으로 해석됩니다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-08.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-08.pdf</a></li>
</ul>
