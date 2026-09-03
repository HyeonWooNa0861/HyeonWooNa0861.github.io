---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 05 Linear Algebra 4"
course: "Machine Learning Basic"
topic: "Linear Algebra 4"
order: 5
major_topic: "Machine Learning Foundations"
keywords:
  - "Basis Changes"
  - "Matrix Equivalence"
  - "Matrix Similarity"
  - "Image and Null Spaces"
  - "Affine Mappings"
---

# Lecture 05 Linear Algebra 4

Source PDF: `machine-learning-basic-lecture-05.pdf`

> **핵심:** **기저 변환에서 바뀌는 것은** 벡터 자체가 아니라 좌표 표현. **similar matrix가 중요한 이유는** 같은 선형 변환의 다른 기저 표현이며 고유값을 공유.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 변환 행렬 | 선형 변환은 기저 선택에 따라 어떻게 표현되는가? |
| 2 | 기저 변환 | 좌표계를 바꾸면 행렬 표현은 어떻게 달라지는가? |
| 3 | 동치와 닮음 | 행렬들이 같은 변환을 다른 좌표에서 표현한다는 뜻은 무엇인가? |
| 4 | 이미지/영 공간 | 선형 변환의 출력 공간과 0으로 가는 공간은 무엇인가? |
| 5 | 아핀 공간과 아핀 변환 | 원점을 지나지 않는 선형 구조는 어떻게 다루는가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 정리·식 | 본문 대응 |
|---:|---|---|
| 2–4 | 변환행렬과 좌표백터 $$y=A_{\Phi}x$$ | 1 |
| 5–8 | 입력·출력 기저 변환 $$\widetilde A=T^{-1}A_{\Phi}S$$ | 2, 8.1 |
| 9–12 | 행렬 동치·닮음 $$\widetilde A=S^{-1}A_{\Phi}S$$ | 3, 8.2 |
| 13–18 | rank, image/null space, Rank–Nullity | 4, 5, 8.3 |
| 19–23 | 아핀 공간 $$x_0+U$$와 아핀 변환 $$\phi(x)=Ax+a$$ | 6, 7 |

페이지 24는 Q&A 마무리이다.

## 1. 변환 행렬의 의미

선형 변환은 기저를 정하면 행렬로 표현된다. 같은 추상적 변환이라도 입력과 출력 공간의 기저를 어떻게 잡느냐에 따라 행렬의 숫자 표현은 달라진다.

중요한 해석은 두 가지다.

| 관점 | 설명 |
|---|---|
| 데이터 변환 | 벡터 자체를 다른 벡터로 보낸다. |
| 좌표 변환 | 같은 벡터를 다른 축 기준의 좌표로 표현한다. |

머신러닝에서는 PCA, whitening, embedding 변환처럼 두 관점이 모두 등장한다.

## 2. 기저 변환

기저가 바뀌면 벡터의 좌표도 바뀐다. 기저 변환 행렬은 한 기저에서 표현된 좌표를 다른 기저의 좌표로 옮기는 역할을 한다.

기저 변환을 이해할 때는 "벡터 자체"와 "좌표 표현"을 구분해야 한다.

같은 벡터 $$x$$라도 기저가 달라지면 좌표 표현이 달라진다.

$$
[x]_B \quad \text{and} \quad [x]_C
$$

## 3. 동치와 닮음

두 행렬이 가역행렬을 이용해 서로 연결되면 같은 선형 구조를 다른 좌표에서 본 것으로 해석할 수 있다.

| 개념 | 형태 | 의미 |
|---|---|---|
| equivalent | $$B = PAQ$$ | 입력/출력 기저가 모두 바뀐 표현 |
| similar | $$B = P^{-1}AP$$ | 같은 공간에서 기저만 바뀐 표현 |

닮은 행렬은 고유값 같은 중요한 성질을 공유한다.

## 4. 이미지 공간과 영 공간

선형 변환 `A`에 대해 두 공간이 중요하다.

| 공간 | 의미 |
|---|---|
| image space / column space | $$Ax$$로 도달 가능한 모든 출력 |
| null space | $$Ax = 0$$을 만족하는 모든 입력 |

영 공간은 항상 0 벡터를 포함한다. 영 공간이 0만 포함하면 변환은 injective하다.

## 5. Rank-Nullity 정리

$$A$$가 $$m \times n$$ 행렬일 때:

$$
\operatorname{rank}(A) + \operatorname{nullity}(A) = n
$$

입력 차원은 "출력으로 살아남는 차원(rank)"과 "0으로 사라지는 차원(nullity)"으로 나뉜다.

정사각행렬에서 $$\operatorname{rank}(A)=n$$이면 injective, surjective, bijective가 서로 동치가 된다.

## 6. 아핀 공간

아핀 공간은 부분공간을 어떤 기준점만큼 평행이동한 공간이다.

$$
x_0 + U
$$

여기서 $$U$$는 direction space, $$x_0$$는 support point다. 원점을 지나지 않을 수 있으므로 일반적으로 벡터공간은 아니다.

같은 방향공간을 가진 support point는 유일하지 않다. $$a\in x_0+U$$이면 $$a=x_0+u_0$$인 $$u_0\in U$$가 있으므로

$$
a+U=x_0+u_0+U=x_0+U.
$$

반대로 $$(x_0+U)\cap(y_0+U)\ne\varnothing$$이면 교점 $$z=x_0+u_1=y_0+u_2$$에서 $$y_0-x_0=u_1-u_2\in U$$이므로 두 affine subset은 같다. 따라서 같은 $$U$$의 두 평행이동은 서로 같거나 서로소다. 이는 **정확한 집합 관계**다.

**작성자 보충 · source p20 정리의 증명:** 두 affine subset을

$$
L=x_0+U,
\qquad
\widetilde L=\widetilde x_0+\widetilde U
$$

로 쓰자. 여기서 $$U,\widetilde U$$는 같은 vector space $$V$$의 linear subspace이고 $$x_0,\widetilde x_0\in V$$다. 그러면

$$
L\subseteq\widetilde L
\iff
U\subseteq\widetilde U
\quad\text{and}\quad
x_0-\widetilde x_0\in\widetilde U.
$$

**정방향.** $$L\subseteq\widetilde L$$이면 $$x_0\in L$$이므로 $$x_0=\widetilde x_0+\widetilde u_0$$인 $$\widetilde u_0\in\widetilde U$$가 존재한다. 따라서 $$x_0-\widetilde x_0\in\widetilde U$$다. 임의의 $$u\in U$$에 대해 $$x_0+u\in L\subseteq\widetilde L$$이므로 $$x_0+u-\widetilde x_0\in\widetilde U$$다. 여기서 이미 $$x_0-\widetilde x_0\in\widetilde U$$이고 $$\widetilde U$$가 뺄셈에 닫혀 있으므로

$$
u=(x_0+u-\widetilde x_0)-(x_0-\widetilde x_0)\in\widetilde U.
$$

모든 $$u\in U$$에 대해 성립하므로 $$U\subseteq\widetilde U$$다.

**역방향.** 이제 $$U\subseteq\widetilde U$$와 $$x_0-\widetilde x_0\in\widetilde U$$를 가정한다. 임의의 $$x=x_0+u\in L$$에 대해

$$
x=\widetilde x_0+\bigl((x_0-\widetilde x_0)+u\bigr).
$$

괄호 안은 $$u\in U\subseteq\widetilde U$$와 부분공간의 덧셈 닫힘성 때문에 $$\widetilde U$$에 속한다. 따라서 $$x\in\widetilde L$$이고 $$L\subseteq\widetilde L$$다. 이는 근사가 아닌 **정확한 동치**다. 두 support point와 direction vector는 같은 affine ambient space에서 뺄 수 있어야 하며, 물리량을 나타내면 $$x_0,\widetilde x_0,u$$의 대응 좌표 단위가 같아야 한다. 단위가 다른 좌표 표현끼리는 먼저 같은 좌표계와 단위로 변환해야 이 차와 포함 관계가 의미를 갖는다.

부분집합 $$A\subseteq V$$가 비어 있지 않을 때, $$A$$가 affine subset이라는 조건은 모든 $$x,y\in A$$와 $$t\in\mathbb{R}$$에 대해

$$
(1-t)x+ty\in A
$$

인 것과 동치다. $$A=x_0+U$$이면 두 점의 affine combination은 $$x_0+(1-t)u_1+tu_2\in x_0+U$$라서 닫혀 있다. 반대로 이 닫힘 조건을 만족하면 한 점 $$x_0\in A$$를 고정해 $$U=A-x_0$$라 둘 때 $$U$$가 덧셈과 스칼라곱에 닫힌 부분공간임을 확인할 수 있고 $$A=x_0+U$$를 얻는다. 여기서 계수의 합 $$(1-t)+t=1$$이므로 원점을 따로 선택하지 않아도 점들의 affine 관계가 보존된다.

| 차원 | 아핀 공간 예 |
|---|---|
| 1차원 | 선 |
| 2차원 | 평면 |
| $$n-1$$차원 | hyperplane |

## 7. 아핀 변환

아핀 변환은 선형 변환에 평행이동을 더한 형태다.

$$
f(x) = Ax + a
$$

신경망의 layer $$Wx + b$$도 기본적으로 아핀 변환 뒤에 비선형 함수를 적용하는 구조로 볼 수 있다.

아핀 공간의 affine frame을 support point $$p_0$$와 direction space의 기저 $$(v_1,\ldots,v_k)$$로 잡으면 모든 점은

$$
p=p_0+\sum_{i=1}^{k}\alpha_i v_i
$$

로 **유일하게** 표현된다. 존재는 $$p-p_0\in U=\operatorname{span}(v_1,\ldots,v_k)$$에서, 유일성은 두 표현을 뺀 뒤 $$v_i$$의 선형 독립성을 적용해 얻는다. 기저가 종속이면 좌표는 유일하지 않는다.

동일한 내용을 $$(k+1)$$개 점 $$p_0,p_1,\ldots,p_k$$로 쓰려면 $$v_i=p_i-p_0$$가 선형 독립이라고 가정한다. 그러면

$$
p=\sum_{i=0}^{k}\lambda_i p_i,
\qquad
\sum_{i=0}^{k}\lambda_i=1
$$

인 affine coordinates가 유일하다. 실제로 $$\alpha_i=\lambda_i$$ $$(i\ge1)$$, $$\lambda_0=1-\sum_{i=1}^{k}\alpha_i$$로 놓으면 앞의 support-point 표현과 정확히 같아진다. 따라서 점들이 affinely independent라는 조건이 좌표 유일성을 보장하고, 이 조건이 깨지면 서로 다른 $$\lambda$$ tuple이 같은 점을 나타낼 수 있다.

아핀 변환의 합성도 다시 아핀이다. $$f(x)=Ax+a$$와 $$g(y)=By+b$$이면

$$
(g\circ f)(x)=B(Ax+a)+b=(BA)x+(Ba+b).
$$

따라서 선형부는 $$BA$$, 평행이동부는 $$Ba+b$$이며 합성 순서를 바꾸면 일반적으로 달라진다. $$x$$의 단위를 $$U_x$$, 중간 출력을 $$U_y$$, 최종 출력을 $$U_z$$라 하면 $$A$$는 `중간 출력/입력`, $$B$$는 `최종 출력/중간 출력`, $$a$$는 $$U_y$$, $$b$$는 $$U_z$$ 단위를 가져야 한다. 위 식은 호환되는 affine space 사이에서의 **정확한 등식**이다.

## 8. 핵심 식의 유도와 증명

### 8.1 입력·출력 기저가 모두 바뀌는 일반 정리

$$\Phi:V\to W$$가 선형이고, 정의역의 옛·새 정렬 기저를 $$B,\widetilde B$$, 공역의 옛·새 정렬 기저를 $$C,\widetilde C$$라 하자. 다음 행렬을 정의한다.

$$
A=[\Phi]_{C\leftarrow B},\qquad
\widetilde A=[\Phi]_{\widetilde C\leftarrow\widetilde B},
$$

$$
[x]_B=S[x]_{\widetilde B},\qquad
[y]_C=T[y]_{\widetilde C}.
$$

즉 $$S$$의 $$j$$번째 열은 $$[\widetilde b_j]_B$$이고, $$T$$의 $$k$$번째 열은 $$[\widetilde c_k]_C$$다. 두 집합이 기저이므로 $$S\in\mathbb{R}^{n\times n}$$과 $$T\in\mathbb{R}^{m\times m}$$는 가역이다. 이때 일반적인 기저 변환 정리는

$$
\boxed{\widetilde A=T^{-1}AS}
$$

이다.

**좌표 사슬을 이용한 증명.** 임의의 $$x\in V$$에 대해 옛 출력 좌표를 두 경로로 계산하면

$$
T[\Phi(x)]_{\widetilde C}
=[\Phi(x)]_C
=A[x]_B
=AS[x]_{\widetilde B}.
$$

왼쪽에서 $$T^{-1}$$를 곱하면

$$
[\Phi(x)]_{\widetilde C}=T^{-1}AS[x]_{\widetilde B}.
$$

모든 좌표 벡터에 대해 성립하므로 $$\widetilde A=T^{-1}AS$$다. 이는 근사가 아닌 **정확한 정리**이며, $$B,\widetilde B,C,\widetilde C$$가 각각 실제 기저여서 $$S,T$$가 가역이라는 조건이 필요하다.

원소 수준에서도 같은 결론을 얻는다. $$\widetilde b_j=\sum_i s_{ij}b_i$$, $$\widetilde c_k=\sum_l t_{lk}c_l$$라 두면 $$T\widetilde A=AS$$가 되어 위 식과 같다. 이 일반 정리는 정의역과 공역의 차원이 달라도 적용되며, 단순한 similarity보다 넓다.

> **작성자 보충:** 유한 정밀도에서 거의 종속인 기저는 $$S^{-1}$$ 또는 $$T^{-1}$$ 계산을 불안정하게 만든다. 실제 구현에서는 inverse를 명시적으로 만들기보다 선형계를 풀고 condition number를 확인한다.

### 8.2 닮음 변환식은 어디서 오는가?

기저 $$B$$ 좌표를 표준 좌표로 보내는 가역행렬을 $$P$$라 두면 $$x=P[x]_B$$다. 표준 좌표에서 변환이 $$A$$일 때

$$
[Ax]_B=P^{-1}Ax=P^{-1}AP[x]_B
$$

이므로 새 기저에서의 행렬은 $$B=P^{-1}AP$$다. 이는 **정확한 등식**이며 $$P$$가 가역이어야 한다.

닮은 행렬이 같은 고유값을 갖는 것도 직접 보인다.

$$
\det(B-\lambda I)
=\det\!\left(P^{-1}(A-\lambda I)P\right)
=\det(P^{-1})\det(A-\lambda I)\det(P)
=\det(A-\lambda I)
$$

따라서 특성다항식이 같다. 이 결론은 고유벡터의 좌표가 같다는 뜻은 아니며, 고유벡터는 $$P^{-1}$$에 따라 좌표가 바뀐다.

닮음은 일반 정리의 특수한 경우다. $$V=W$$이고 입력·출력에 같은 옛 기저와 같은 새 기저를 사용하면 $$S=T=P$$이므로 $$\widetilde A=P^{-1}AP$$가 된다. 반면 입력과 출력 기저가 독립적으로 바뀌는 일반 상황에서는 $$T^{-1}AS$$이지, 임의로 similarity 식을 사용할 수 없다.

### 8.3 Rank-Nullity와 정보 손실

정의역이 $$n$$차원이면 $$\operatorname{rank}(A)+\operatorname{nullity}(A)=n$$이다. 영공간 방향 $$z$$는 $$Az=0$$이므로 $$A(x+z)=Ax$$가 되어 서로 다른 입력을 구분하지 못한다. 따라서 nullity는 사라지는 독립 방향의 수이고 rank는 출력에 남는 독립 방향의 수다.

$$A,P$$와 좌표 벡터는 추상 계산에서 무차원이다. 실제 데이터 변환에서 $$A$$의 원소는 출력 단위/입력 단위를 가질 수 있고, bias $$a$$는 출력과 같은 단위를 가져야 $$Ax+a$$가 성립한다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 기저 변환에서 바뀌는 것은? | 벡터 자체가 아니라 좌표 표현 |
| similar matrix가 중요한 이유는? | 같은 선형 변환의 다른 기저 표현이며 고유값을 공유 |
| image space는 무엇인가? | $$Ax$$로 만들 수 있는 출력 전체 |
| affine mapping의 형태는? | $$Ax + a$$ |

## Study Guide

같은 vector를 두 basis에서 좌표로 표현해 vector 자체와 coordinate tuple이 다르다는 점부터 확인한다. similar matrices는 같은 linear map의 다른 basis 표현이므로 eigenvalue를 공유하고, image/null space는 Ax가 만들 수 있는 출력과 0으로 보내는 입력으로 대비한다. 마지막에는 linear mapping Ax와 affine mapping Ax+a가 원점 보존 여부에서 갈리는 이유를 예제로 검산한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. $$Ax=0$$의 해 공간이 크다는 것은 변환 $$A$$가 어떤 정보를 잃는다는 뜻인가?</summary>

답변: null space가 크다는 것은 서로 다른 입력 방향들이 $$A$$를 거친 뒤 0 또는 같은 출력으로 collapse될 수 있다는 뜻이다. 즉 변환이 입력의 일부 방향 정보를 구분하지 못한다.

</details>

<details markdown="block">
<summary>2. 신경망의 bias term은 왜 아핀 변환 관점에서 자연스러운가?</summary>

답변: 선형 변환 $$Ax$$는 원점을 반드시 원점으로 보낸다. 그러나 실제 모델은 decision boundary나 activation을 원점에서 이동시켜야 할 때가 많다. $$Ax+a$$ 같은 아핀 변환은 이 이동을 bias term으로 표현한다.

</details>

<details markdown="block">
<summary>3. 닮은 행렬이 고유값을 공유하는 이유를 좌표 변환 관점으로 설명해보자.</summary>

답변: 닮은 행렬은 같은 선형 변환을 다른 basis에서 표현한 것이다. 좌표 표현은 달라지지만 변환 자체의 stretch factor인 eigenvalue는 변하지 않는다. 그래서 $$B=P^{-1}AP$$는 $$A$$와 같은 고유값을 가진다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-05.pdf</a></li>
</ul>
