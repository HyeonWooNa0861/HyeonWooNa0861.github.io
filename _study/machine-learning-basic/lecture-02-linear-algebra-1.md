---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 02 Linear Algebra 1"
course: "Machine Learning Basic"
topic: "Linear Algebra 1"
order: 2
major_topic: "Machine Learning Foundations"
keywords:
  - "Vectors"
  - "Matrices"
  - "Linear Systems"
  - "Vector Spaces"
---

# Lecture 02 Linear Algebra 1

Source PDF: `machine-learning-basic-lecture-02.pdf`

> **핵심:** **REF와 RREF의 차이는** RREF는 pivot이 1이고 pivot 열의 다른 값이 0. **기본 행 연산 3가지는** 행 교환, 행 스케일, 행 더하기.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 벡터와 벡터공간 | 벡터는 단순한 화살표보다 넓은 개념인가? |
| 2 | 선형연립방정식 | 여러 선형 조건의 해는 어떻게 표현되는가? |
| 3 | 행렬 | 행렬은 선형연립방정식을 어떻게 압축해 표현하는가? |
| 4 | 역행렬과 전치 | 행렬 연산의 기본 성질은 무엇인가? |
| 5 | REF/RREF | 기본 행 연산으로 해를 어떻게 구하는가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 수식·알고리즘 | 본문 대응 |
|---:|---|---|
| 2–4 | 벡터 연산과 선형대수 법칙 | 1, 1.1 |
| 5–10 | 선형연립방정식과 $$Ax=b$$ 행렬 표현 | 2, 5 |
| 11–19 | 행렬곡, 항등행렬, 역행렬, 전치행렬의 정의·성질 | 3, 3.1, 4, 4.1 |
| 20–32 | 소거법, REF/RREF, `Minus-1 Trick`, 역행렬·Moore–Penrose 해법 | 5, 6, 6.1, 7.1 |
| 33–35 | fixed-point·Richardson iteration | 7.2 |

페이지 36은 Q&A 마무리이며 새로운 수식을 소개하지 않는다.

## 1. 벡터의 관점

벡터는 덧셈과 스칼라곱이 정의된 대상이다. 기하학적 화살표뿐 아니라 다항식, 오디오 신호도 같은 연산 구조를 가지면 벡터처럼 다룰 수 있다.

머신러닝에서는 대부분 데이터를 $$\mathbb{R}^D$$의 벡터로 표현하므로, 선형대수는 데이터와 모델을 다루는 기본 언어가 된다.

### 1.1 $$\mathbb{R}^n$$ 벡터 연산의 법칙

$$x,y,z\in\mathbb{R}^n$$과 $$a,b\in\mathbb{R}$$에 대해 좌표별 덧셈과 스칼라곱은 다음 법칙을 만족한다.

| 법칙 | 정확한 식 |
|---|---|
| 덧셈 교환·결합 | $$x+y=y+x$$, $$(x+y)+z=x+(y+z)$$ |
| 영벡터·덧셈 역원 | $$x+0=x$$, $$x+(-x)=0$$ |
| 벡터합에 대한 분배 | $$a(x+y)=ax+ay$$ |
| 스칼라합에 대한 분배 | $$(a+b)x=ax+bx$$ |
| 스칼라곱 결합·항등 | $$a(bx)=(ab)x$$, $$1x=x$$ |

이 식들은 반올림을 무시한 실수 벡터공간에서 **정확한 항등식**이다. 부동소수점 계산에서는 결합법칙이 반올림 오차 때문에 수치적으로 정확히 재현되지 않을 수 있다. 벡터 좌표가 서로 다른 물리 단위를 가진다면 덧셈은 같은 좌표·같은 단위끼리만 의미가 있고, 스칼라 $$a$$가 무차원이면 $$ax$$는 $$x$$와 같은 단위를 갖는다.

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

### 3.1 행렬곱의 성분 공식과 차원 조건

$$A\in\mathbb{R}^{m\times n}$$, $$B\in\mathbb{R}^{n\times p}$$일 때만 안쪽 차원 $$n$$이 맞으므로 곱 $$C=AB$$가 정의되고 $$C\in\mathbb{R}^{m\times p}$$다. 각 성분은

$$
C_{ij}=(AB)_{ij}=\sum_{k=1}^{n}A_{ik}B_{kj}
$$

이다. 즉 $$A$$의 $$i$$번째 행과 $$B$$의 $$j$$번째 열의 dot product다. 예를 들어 $$A\in\mathbb{R}^{2\times3}$$, $$B\in\mathbb{R}^{3\times4}$$이면 $$AB\in\mathbb{R}^{2\times4}$$지만, $$BA$$는 안쪽 차원 $$4$$와 $$2$$가 달라 정의되지 않는다. 둘 다 정의되더라도 일반적으로 $$AB\ne BA$$다.

이 식은 정확한 산술에서의 **정확한 정의**다. 물리 단위가 있으면 고정된 $$i,j$$에 대해 모든 항 $$A_{ik}B_{kj}$$의 단위가 서로 같아야 합이 의미가 있다. 선형 사상 합성에서는 $$B$$가 입력 단위를 중간 단위로, $$A$$가 중간 단위를 출력 단위로 보내므로 중간 단위가 소거되는 구조로 읽을 수 있다.

## 4. 역행렬과 전치행렬

정사각행렬 $$A$$에 대해 $$AB = BA = I$$를 만족하는 $$B$$가 있으면 $$B$$를 $$A$$의 역행렬이라 하고 $$A^{-1}$$로 쓴다. 역행렬이 존재하는 행렬은 invertible이라고 한다.

전치행렬은 행과 열을 바꾼 행렬이다.

$$
(A^T)_{ij} = A_{ji}
$$

대칭행렬은 $$A = A^T$$를 만족한다. 대칭행렬의 합은 대칭행렬이지만, 곱은 일반적으로 대칭행렬이 아닐 수 있다.

### 4.1 $$2\times2$$ 역행렬의 조건과 유도

$$
A=\begin{bmatrix}a&b\\c&d\end{bmatrix},
\qquad
\det(A)=ad-bc
$$

라 두자. 다음 행렬을 직접 곱하면

$$
\begin{bmatrix}a&b\\c&d\end{bmatrix}
\begin{bmatrix}d&-b\\-c&a\end{bmatrix}
=(ad-bc)I
$$

이므로 $$ad-bc\ne0$$일 때만 양변을 행렬식으로 나눌 수 있고

$$
A^{-1}=\frac{1}{ad-bc}\begin{bmatrix}d&-b\\-c&a\end{bmatrix}
$$

를 얻는다. 반대로 $$ad-bc=0$$이면 열들이 선형 종속이라 rank가 2보다 작고 역행렬은 존재하지 않는다. 강의의 예시 $$A=\begin{bmatrix}1&2\\3&4\end{bmatrix}$$에서는 $$\det(A)=-2$$이므로

$$
A^{-1}=-\frac12\begin{bmatrix}4&-2\\-3&1\end{bmatrix}.
$$

이는 **정확한 등식**이다. 다만 $$\det(A)$$가 0은 아니어도 매우 작고 행렬이 ill-conditioned이면, 부동소수점으로 계산한 역행렬과 해는 입력 오차에 매우 민감할 수 있다.

## 5. 선형연립방정식 풀이 구조

$$Ax = b$$를 풀 때는 다음 관점이 중요하다.

1. $$Ax = b$$를 만족하는 particular solution을 찾는다.
2. $$Ax = 0$$을 만족하는 homogeneous solution을 찾는다.
3. 전체 해는 particular solution + homogeneous solution으로 표현한다.

즉 해가 하나만 있는지, 무한히 많은지는 $$Ax = 0$$의 해 공간이 얼마나 큰지와 연결된다.

## 6. 기본 행 연산과 REF/RREF

기본 행 연산은 선형연립방정식의 해를 바꾸지 않는 변환이다.

| 연산 | 설명 |
|---|---|
| 행 교환 | 두 행의 순서를 바꾼다. |
| 행 스케일 | 한 행에 0이 아닌 실수를 곱한다. |
| 행 더하기 | 한 행에 다른 행의 배수를 더한다. |

REF(Row Echelon Form)는 pivot이 아래 행으로 갈수록 오른쪽에 위치하는 형태다. RREF(Reduced Row Echelon Form)는 REF이면서 모든 pivot이 1이고, pivot 열에서 pivot만 0이 아닌 형태다.

### 6.1 PDF slide 32의 `Minus-1 Trick` 해석

슬라이드의 증강행렬은 마지막 행이 $$[0\ 0\ 0\ 0\ 0\mid a+1]$$로 줄어든다. 따라서 원래 비동차 연립방정식이 일관되려면 반드시 $$a=-1$$이어야 한다. 이때 RREF는

$$
\begin{bmatrix}
1&-2&0&0&-2\\
0&0&1&0&1\\
0&0&0&1&-2\\
0&0&0&0&0
\end{bmatrix}
$$

이고 pivot 변수는 $$x_1,x_3,x_4$$, 자유변수는 $$x_2,x_5$$다. $$x_2=\lambda_1$$, $$x_5=\lambda_2$$로 놓으면 slide 32의 해는

$$
x=
\begin{bmatrix}2\\0\\-1\\1\\0\end{bmatrix}
+\lambda_1\begin{bmatrix}2\\1\\0\\0\\0\end{bmatrix}
+\lambda_2\begin{bmatrix}2\\0\\-1\\2\\1\end{bmatrix},
\qquad \lambda_1,\lambda_2\in\mathbb{R}.
$$

첫 벡터는 $$a=-1$$일 때의 particular solution이고 뒤의 두 벡터는 영공간의 기저다. $$a\ne-1$$이면 마지막 식이 $$0=a+1\ne0$$이 되어 해가 없다. 이 구분은 정확한 산술에서의 결론이며, 측정 데이터에서는 작은 잔차를 0으로 볼 tolerance를 별도로 정해야 한다.

## 7. 계산 방법의 현실적 주의점

역행렬을 직접 계산해 $$x = A^{-1}b$$로 푸는 방식은 이론적으로 명확하지만 계산량이 크고 수치적으로 불안정할 수 있다. 그래서 실제 계산에서는 행 연산, Moore-Penrose inverse, iterative methods 같은 방법도 중요하다.

### 7.1 Normal equation과 Moore-Penrose inverse의 정확한 범위

$$A\in\mathbb{R}^{m\times n}$$, $$b\in\mathbb{R}^m$$에서 least-squares 목적함수 $$\lVert Ax-b\rVert_2^2$$의 일차 조건은

$$
A^T(Ax-b)=0
\iff A^TAx=A^Tb
$$

이다. $$A$$가 full column rank, 즉 $$\operatorname{rank}(A)=n$$이면 $$A^TA$$가 가역이고 유일한 최소제곱해는

$$
x_{\mathrm{LS}}=(A^TA)^{-1}A^Tb=A^{\dagger}b
$$

다. 여기서 $$A^{\dagger}$$는 Moore-Penrose pseudoinverse다.

- $$Ax=b\Rightarrow A^TAx=A^Tb$$는 항상 성립하지만, 역방향은 **$$b\in\operatorname{Col}(A)$$인 일관된 계에서만** 원래 방정식의 해를 뜻한다.
- 계가 불일관이면 $$x_{\mathrm{LS}}$$는 $$Ax=b$$의 정확한 해가 아니라 잔차 norm을 최소화하는 근사해다.
- full column rank가 아니면 $$(A^TA)^{-1}$$가 존재하지 않는다. 그러나 $$A^{\dagger}$$ 자체는 모든 행렬에 정의되며, $$A^{\dagger}b$$는 최소제곱해들 중 Euclidean norm이 최소인 해를 선택한다.
- normal equation은 condition number를 대략 제곱하므로 실제 계산에서는 역행렬을 명시적으로 만들기보다 QR 또는 SVD 기반 solver가 보통 더 안정적이다.

$$A^T$$의 shape는 $$n\times m$$, $$A^TA$$는 $$n\times n$$, $$A^Tb$$는 $$n\times1$$이다. 물리 단위가 있는 모델에서는 각 항의 단위가 맞아야 하며, feature별 단위 차이가 큰 경우 scaling 없이 normal equation을 풀면 수치 상태가 나빠질 수 있다.

### 7.2 Fixed-point iteration과 Richardson iteration

연립방정식 $$Ax=b$$를 반복법으로 풀려면 해 $$x^*$$가 고정점이 되도록 $$x=G(x)$$로 바꾼다. Richardson iteration은 가장 단순한 예로

$$
x_{k+1}=x_k+\omega(b-Ax_k)
$$

이다. 즉 $$G(x)=(I-\omega A)x+\omega b$$다. $$\omega\ne0$$이면

$$
x^*=G(x^*)
\iff
\omega(b-Ax^*)=0
\iff
Ax^*=b
$$

이므로 이 반복의 고정점과 원래 선형계의 해가 정확히 일치한다. 잔차를 $$r_k=b-Ax_k$$라 하면 $$x_{k+1}=x_k+\omega r_k$$이고, 해가 존재해 $$Ax^*=b$$라 둘 때 오차 $$e_k=x_k-x^*$$는

$$
e_{k+1}
=x_k+\omega(b-Ax_k)-x^*
=(I-\omega A)e_k
$$

를 만족한다. 따라서

$$
e_k=(I-\omega A)^ke_0.
$$

모든 초기값에서 수렴할 충분하고 유한차원에서는 표준적인 필요충분 조건은 반복행렬의 spectral radius가

$$
\rho(I-\omega A)<1
$$

인 것이다. 특히 $$A$$가 symmetric positive definite이고 고유값이 $$0<\lambda_{\min}\le\lambda_i\le\lambda_{\max}$$이면

$$
0<\omega<\frac{2}{\lambda_{\max}}
$$

에서 각 고유방향의 배율 $$\lvert1-\omega\lambda_i\rvert<1$$이므로 정확한 산술에서 수렴한다. 최악 방향의 수축률을 최소화하는 상수 step은 $$\omega^*=2/(\lambda_{\min}+\lambda_{\max})$$다.

- **실패 조건:** $$\rho(I-\omega A)>1$$이면 어떤 오차 성분은 커져 발산하고, $$\rho=1$$이면 일반적으로 수렴을 보장하지 못한다. SPD인데 $$\omega\ge2/\lambda_{\max}$$이면 가장 큰 고유값 방향이 진동하거나 발산한다.
- **비대칭·비정규 행렬:** 고유값 조건이 장기 수렴을 판정하더라도 non-normal 행렬에서는 초기에 오차가 크게 증폭될 수 있다. 행렬이 singular하거나 계가 불일관하면 원래의 유일해 수렴이라는 해석도 성립하지 않는다.
- **단위:** $$Ax$$와 $$b$$의 단위가 같아야 잔차를 뺄 수 있고, $$\omega r_k$$가 $$x_k$$와 같은 단위가 되도록 $$\omega$$는 `미지수 단위/잔차 단위`를 가져야 한다. 추상적으로 무차원화한 계에서는 $$\omega$$도 무차원이다.
- **정확성과 수치 오차:** 위 오차식은 exact arithmetic에서 정확하다. 부동소수점에서는 매 step의 반올림과 stopping tolerance 때문에 계산된 수렴은 근사적이다.

## 8. 핵심 식의 유도와 성립 조건

### 8.1 전체 해가 `특수해 + 영공간`이 되는 이유

이 명제는 **정확한 등식**이다. $$A\in\mathbb{R}^{m\times n}$$, $$b\in\mathbb{R}^m$$이고 $$Ax=b$$가 적어도 하나의 해 $$x_p$$를 가진다고 가정한다.

1. 임의의 다른 해를 $$x$$라 두면 $$Ax=b$$이고 $$Ax_p=b$$다.
2. 두 식을 빼면 $$A(x-x_p)=0$$이다.
3. 따라서 $$z=x-x_p$$는 $$A$$의 영공간 원소이며, $$x=x_p+z$$로 쓸 수 있다.
4. 반대로 $$Az=0$$인 모든 $$z$$에 대해 $$A(x_p+z)=Ax_p+Az=b$$이므로 실제 해가 된다.

결론적으로 해 집합은 $$x_p+\operatorname{Null}(A)$$이다. 해가 없으면 $$x_p$$ 자체가 존재하지 않아 이 표현을 사용할 수 없고, 영공간이 $$\{0\}$$이면 해는 유일하다.

### 8.2 기본 행 연산이 해를 보존하는 이유

각 기본 행 연산은 가역인 elementary matrix $$E$$를 왼쪽에서 곱하는 것과 같다. 따라서

$$
Ax=b \iff EAx=Eb
$$

이다. 오른쪽에서 왼쪽으로도 돌아올 수 있는 이유는 $$E^{-1}$$가 존재하기 때문이다. 행 스케일에서 0을 곱하면 가역성이 깨져 정보를 잃으므로 반드시 0이 아닌 수를 사용해야 한다.

### 8.3 기호와 단위

| 기호 | 의미 | 크기·단위 |
|---|---|---|
| $$A$$ | 계수행렬 또는 선형변환 | $$m\times n$$; 일반 선형대수에서는 무차원 |
| $$x,x_p,z$$ | 미지 벡터, 특수해, 영공간 벡터 | $$n\times1$$; 데이터 문맥의 단위를 따름 |
| $$b$$ | 목표 벡터 | $$m\times1$$; 출력 문맥의 단위를 따름 |
| $$E$$ | 기본 행 연산 행렬 | $$m\times m$$; 무차원 |

행렬식의 단위는 열에 담긴 물리량의 곱이므로 실제 물리 모델에서는 무조건 무차원이라고 가정하면 안 된다. 이 강의의 추상 선형대수 계산에서는 수치와 형상만 추적한다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| REF와 RREF의 차이는? | RREF는 pivot이 1이고 pivot 열의 다른 값이 0 |
| 기본 행 연산 3가지는? | 행 교환, 행 스케일, 행 더하기 |
| 전체 해 구조는? | particular solution + homogeneous solution |
| 역행렬 풀이의 한계는? | 계산량과 수치 불안정성 |

## Study Guide

Ax=b를 augmented matrix로 만든 뒤 세 기본 행 연산으로 REF, RREF까지 줄이며 pivot과 free variable을 표시한다. 해는 particular solution과 homogeneous solution의 합으로 쓰고, inverse multiplication을 모든 선형계의 기본 풀이로 오해하지 않는다. 계산 전후 matrix·vector shape를 확인하는 습관과 역행렬의 비용·수치 불안정성이 시험 포인트다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. $$Ax=b$$가 해를 가지려면 $$b$$는 어떤 공간에 있어야 하는가?</summary>

답변: $$b$$는 $$A$$의 column space 안에 있어야 한다. $$Ax$$는 $$A$$의 열벡터들의 선형 결합이므로, 만들 수 있는 모든 $$b$$는 column space에 속한다.

</details>

<details markdown="block">
<summary>2. RREF에서 free variable은 언제 생기는가?</summary>

답변: pivot이 없는 column이 있을 때 free variable이 생긴다. 이 변수는 다른 pivot variable에 의해 고정되지 않으므로 여러 값을 가질 수 있고, 해가 무한히 많아지는 원인이 된다.

</details>

<details markdown="block">
<summary>3. 행렬곱이 교환법칙을 만족하지 않는다는 것은 모델 계산에서 어떤 주의점을 주는가?</summary>

답변: $$AB$$와 $$BA$$는 일반적으로 다르며, 심지어 한쪽만 정의될 수도 있다. 따라서 선형 변환을 합성할 때 순서가 의미를 바꾸고, neural network의 layer 순서도 임의로 바꿀 수 없다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-02.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-02.pdf</a></li>
</ul>
