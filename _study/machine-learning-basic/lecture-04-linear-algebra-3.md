---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 04 Linear Algebra 3"
course: "Machine Learning Basic"
topic: "Linear Algebra 3"
order: 4
major_topic: "Machine Learning Foundations"
keywords:
  - "Ordered Bases"
  - "Coordinate Vectors"
  - "Change of Coordinates"
  - "Linear Maps"
  - "Rank-Nullity"
---

# Lecture 04 Linear Algebra 3

Source PDF: `machine-learning-basic-lecture-04.pdf`

> **핵심:** **기저의 조건은** span하면서 선형 독립. **차원이란** 기저 벡터의 개수.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 선형 독립 판별 | REF의 pivot column은 무엇을 알려주는가? |
| 2 | 생성 집합과 span | 벡터들이 공간 전체를 만들 수 있는가? |
| 3 | 기저와 차원 | 최소 생성 집합과 최대 독립 집합은 어떻게 연결되는가? |
| 4 | 랭크 | 행렬의 독립적인 정보량은 어떻게 측정하는가? |
| 5 | 선형 사상과 좌표 | 행렬은 선형 변환을 어떻게 표현하는가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 정리·식 | 본문 대응 |
|---:|---|---|
| 2–6 | 선형 독립 정의, REF pivot 판정, 계수행렬 논증 | 1, 1.1 |
| 7–13 | span, basis, dimension의 정의와 기저 탐색 | 2, 3 |
| 14–16 | rank와 null/image space 관계 | 4, 7 |
| 17–20 | 선형 사상, 단사·전사·동형사상 | 5 |
| 21–25 | 좌표의 유일성과 변환행렬 $$A_{\Phi}(i,j)=\alpha_{ij}$$ | 6, 6.1, 6.2 |

페이지 26–27은 Q&A·마무리로, 새로운 수식 항목은 없다.

## 1. REF로 선형 독립 확인

벡터들을 열로 모아 행렬을 만들고 REF로 바꾸면 pivot column을 확인할 수 있다.

| 열 종류 | 의미 |
|---|---|
| pivot column | 이전 pivot column들과 선형 독립 |
| non-pivot column | 앞의 pivot column들의 선형 조합으로 표현 가능 |

따라서 모든 열이 pivot column이면 해당 벡터 집합은 선형 독립이다.

### 1.1 강의의 REF 예시

강의는 다음 다섯 벡터를 열로 모은다.

$$
v_1=\begin{bmatrix}-2\\4\\1\\1\end{bmatrix},\quad
v_2=\begin{bmatrix}4\\-8\\-2\\-2\end{bmatrix},\quad
v_3=\begin{bmatrix}-2\\3\\1\\0\end{bmatrix},\quad
v_4=\begin{bmatrix}-1\\-3\\-1\\-3\end{bmatrix},\quad
v_5=\begin{bmatrix}4\\1\\1\\4\end{bmatrix}.
$$

$$[v_1\ v_2\ v_3\ v_4\ v_5]$$를 REF로 만들면 pivot은 1, 3, 4열에 생긴다. 따라서 전체 다섯 벡터는 종속이고, 원래 행렬에서 대응하는 $$\{v_1,v_3,v_4\}$$가 column space의 기저다. 특히 $$v_2=-2v_1$$은 종속성을 즉시 보여준다.

행 연산은 pivot **위치**를 찾는 데 쓰지만 column space 자체는 보존하지 않는다. 따라서 기저는 REF의 열이 아니라 반드시 **원래 행렬의 pivot 대응 열**에서 골라야 한다. 정확한 산술에서는 이 판정이 정확하지만, 수치 데이터에서는 pivot을 0으로 판단하는 tolerance에 따라 numerical rank가 달라질 수 있다.

## 2. 생성 집합과 span

벡터 집합 $$A$$의 선형 조합으로 벡터공간 $$V$$의 모든 원소를 만들 수 있으면 $$A$$는 $$V$$의 생성 집합이다.

$$
\operatorname{span}(A) = V
$$

span은 "이 벡터들로 만들 수 있는 모든 방향과 위치"를 뜻한다. 머신러닝에서는 feature들이 어떤 공간을 span하는지가 모델 표현력과 연결된다.

## 3. 기저와 차원

기저는 공간을 만들기에 충분하면서도 중복이 없는 벡터 집합이다.

동치 관점은 다음과 같다.

| 관점 | 설명 |
|---|---|
| 최소 생성 집합 | 하나라도 빼면 공간 전체를 만들 수 없다. |
| 최대 선형 독립 집합 | 더 넣으면 선형 종속이 된다. |
| 유일한 좌표 표현 | 모든 벡터가 기저에 대해 유일한 선형 조합을 가진다. |

벡터공간의 차원은 기저 벡터의 개수다.

## 4. 랭크 Rank

행렬 `A`의 rank는 선형 독립인 열의 개수다. 이는 선형 독립인 행의 개수와도 같다.

| 개념 | 의미 |
|---|---|
| column rank | 독립인 열의 수 |
| row rank | 독립인 행의 수 |
| full rank | $$\operatorname{rank}(A) = \min(m,n)$$ |

중요한 성질:

| 성질 | 의미 |
|---|---|
| $$A$$가 정사각행렬일 때 invertible iff $$\operatorname{rank}(A)=n$$ | full rank면 역행렬 존재 |
| $$Ax=b$$ 해 존재 iff $$\operatorname{rank}(A)=\operatorname{rank}([A\mid b])$$ | augmented matrix rank로 consistency 확인 |
| $$Ax=0$$ 해 공간 차원은 $$n-\operatorname{rank}(A)$$ | null space 차원 |

## 5. 선형 사상

선형 사상은 덧셈과 스칼라곱 구조를 보존하는 함수다.

$$
T(x+y) = T(x) + T(y)
$$

$$
T(ax) = aT(x)
$$

| 용어 | 의미 |
|---|---|
| injective | 서로 다른 입력이 서로 다른 출력으로 간다. |
| surjective | 공역의 모든 원소가 어떤 입력의 출력이다. |
| bijective | injective이면서 surjective |
| isomorphism | 선형이고 bijective인 사상 |

유한 차원 벡터공간에서는 차원이 같으면 서로 동형인 구조로 볼 수 있다.

## 6. 좌표와 변환 행렬

기저가 주어지면 벡터는 기저 벡터들의 선형 조합 계수로 표현된다. 이 계수 벡터가 좌표 벡터다.

선형 변환도 기저를 고르면 행렬로 표현된다. 즉 행렬은 추상적인 선형 사상을 좌표계 위에서 계산 가능하게 만든 표현이다.

### 6.1 정렬된 기저에서 좌표 구하기

정렬된 기저 $$B=(b_1,\ldots,b_n)$$에 대해

$$
x=\alpha_1b_1+\cdots+\alpha_nb_n
$$

이면 $$[x]_B=[\alpha_1,\ldots,\alpha_n]^T$$다. **정렬**이 중요하다. 같은 기저 벡터라도 순서를 바꾸면 좌표 성분의 순서가 바뀐다.

강의의 좌표 예시에서

$$
x=\begin{bmatrix}2\\3\end{bmatrix},\qquad
E=\left(e_1,e_2\right),\qquad
B=\left(\begin{bmatrix}1\\-1\end{bmatrix},\begin{bmatrix}1\\1\end{bmatrix}\right)
$$

이므로 $$[x]_E=[2,3]^T$$다. 다른 기저에서는

$$
\alpha_1\begin{bmatrix}1\\-1\end{bmatrix}
+\alpha_2\begin{bmatrix}1\\1\end{bmatrix}
=\begin{bmatrix}2\\3\end{bmatrix}
$$

를 풀어 $$\alpha_1=-\tfrac12$$, $$\alpha_2=\tfrac52$$를 얻는다. 따라서

$$
[x]_B=\begin{bmatrix}-\tfrac12\\ \tfrac52\end{bmatrix}.
$$

벡터 $$x$$는 그대로이고 좌표 tuple만 달라진다.

#### 좌표가 유일한 이유와 좌표 벡터 독립성의 동치

$$B=(b_1,\ldots,b_n)$$가 기저이면 좌표는 존재할 뿐 아니라 유일하다. 실제로

$$
x=\sum_{i=1}^{n}\alpha_i b_i
=\sum_{i=1}^{n}\beta_i b_i
$$

라는 두 표현이 있다고 하자. 두 식을 빼면

$$
\sum_{i=1}^{n}(\alpha_i-\beta_i)b_i=0
$$

이고, 기저 벡터들의 선형 독립성 때문에 모든 $$\alpha_i-\beta_i=0$$이다. 따라서 $$\alpha_i=\beta_i$$이고 $$[x]_B$$는 유일하다. 이 결론은 **정확한 정리**이며, $$B$$가 단순 생성 집합이 아니라 선형 독립인 기저라는 조건이 핵심이다. 종속인 생성 집합에서는 같은 벡터가 여러 계수 tuple을 가질 수 있다.

또한 좌표 사상 $$x\mapsto[x]_B$$는 선형이고 가역이므로, 임의의 벡터들 $$x_1,\ldots,x_r\in V$$에 대해

$$
\{x_1,\ldots,x_r\}\text{ is linearly independent}
\iff
\{[x_1]_B,\ldots,[x_r]_B\}\text{ is linearly independent}.
$$

증명은 계수를 그대로 비교하면 된다.

$$
\sum_{j=1}^{r}c_jx_j=0
\iff
\left[\sum_{j=1}^{r}c_jx_j\right]_B=[0]_B
\iff
\sum_{j=1}^{r}c_j[x_j]_B=0.
$$

양쪽에서 0을 만드는 계수해가 완전히 같으므로 한쪽이 자명한 해만 가지는 것과 다른 쪽이 자명한 해만 가지는 것이 동치다. 좌표는 추상 공간에서는 무차원 계수지만, 단위가 있는 서로 다른 기저를 비교할 때에는 각 좌표가 `벡터 단위/기저 벡터 단위`를 가질 수 있다.

### 6.2 변환 행렬의 열 구성과 작용

$$V$$의 정렬된 기저를 $$B=(b_1,\ldots,b_n)$$, $$W$$의 정렬된 기저를 $$C=(c_1,\ldots,c_m)$$라 하고 선형 사상을 $$\Phi:V\to W$$라 하자. 각 입력 기저 벡터의 상을 출력 기저로 전개해

$$
\Phi(b_j)=\sum_{i=1}^{m}\alpha_{ij}c_i
$$

로 쓰면 변환 행렬은

$$
[\Phi]_{C\leftarrow B}
=\begin{bmatrix}[\Phi(b_1)]_C&\cdots&[\Phi(b_n)]_C\end{bmatrix}
=(\alpha_{ij})\in\mathbb{R}^{m\times n}.
$$

즉 **$$j$$번째 열은 $$\Phi(b_j)$$의 $$C$$-좌표**다. 모든 $$x\in V$$에 대해

$$
[\Phi(x)]_C=[\Phi]_{C\leftarrow B}[x]_B
$$

가 정확히 성립한다.

강의의 예에서는

$$
\Phi(b_1)=c_1-c_2+3c_3-c_4,\quad
\Phi(b_2)=2c_1+c_2+7c_3+2c_4,
$$

$$
\Phi(b_3)=3c_2+c_3+4c_4
$$

이므로

$$
[\Phi]_{C\leftarrow B}=
\begin{bmatrix}
1&2&0\\-1&1&3\\3&7&1\\-1&2&4
\end{bmatrix}.
$$

$$x=3b_1+2b_2+4b_3$$이면

$$
[\Phi(x)]_C=
\begin{bmatrix}
1&2&0\\-1&1&3\\3&7&1\\-1&2&4
\end{bmatrix}
\begin{bmatrix}3\\2\\4\end{bmatrix}
=\begin{bmatrix}7\\11\\27\\17\end{bmatrix}.
$$

여기서 좌표 벡터와 행렬은 추상 공간에서는 무차원이다. 물리량을 나타내면 행렬의 $$i,j$$ 원소는 출력 좌표 $$i$$의 단위/입력 좌표 $$j$$의 단위를 가져야 합이 의미가 있다.

## 7. 랭크 관련 식의 증명 개요

### 7.1 Rank-Nullity 정리

$$A:\mathbb{R}^n\to\mathbb{R}^m$$에 대해

$$
\dim\operatorname{Im}(A)+\dim\operatorname{Null}(A)=n
$$

은 **정리이자 정확한 등식**이다. 증명은 다음 기저 구성으로 확인할 수 있다.

1. 영공간의 기저를 $$z_1,\ldots,z_k$$라 둔다. 그러면 $$k=\operatorname{nullity}(A)$$다.
2. 이를 정의역 전체의 기저 $$z_1,\ldots,z_k,v_{k+1},\ldots,v_n$$로 확장한다.
3. $$Av_{k+1},\ldots,Av_n$$은 이미지 공간을 생성한다. 임의의 $$x$$를 위 기저로 전개하면 영공간 성분은 $$A$$를 통과하며 사라지기 때문이다.
4. 이 벡터들은 선형 독립이다. $$\sum c_iAv_i=0$$이면 $$\sum c_iv_i$$가 영공간에 속하는데, 확장된 기저의 독립성 때문에 모든 $$c_i=0$$이다.
5. 따라서 이미지 공간의 차원은 $$n-k$$, 즉 rank는 $$n-k$$다.

### 7.2 해 존재 조건의 이유

$$Ax=b$$가 풀린다는 것은 $$b$$가 $$A$$의 열벡터 선형 조합이라는 뜻이다. 증강열 $$b$$를 붙였을 때 rank가 늘지 않는 것과 같으므로

$$
Ax=b\text{ has a solution}\iff\operatorname{rank}(A)=\operatorname{rank}([A\mid b])
$$

이다. 이는 **정확한 동치**이며 수치 계산에서 rank를 tolerance로 판정하면 거의 종속인 열 때문에 결론이 달라질 수 있다.

여기서 $$n,m,k$$는 차원 수로 무차원 정수이고, rank와 nullity도 단위가 없는 개수다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 기저의 조건은? | span하면서 선형 독립 |
| 차원이란? | 기저 벡터의 개수 |
| rank-nullity 핵심은? | null space 차원은 $$n-\operatorname{rank}(A)$$ |
| 선형 사상의 조건은? | 덧셈과 스칼라곱 보존 |

## Study Guide

기저 문제는 먼저 span을 확인하고 그다음 linear independence를 검사하며, 기저 벡터 수를 dimension으로 연결한다. rank-nullity 식에 matrix의 column 수와 rank를 대입해 null space dimension을 계산하고 Ax=b의 consistency는 augmented rank로 판단한다. 선형 사상의 injective·surjective 여부를 null space와 image space에 연결해 외우면 용어 혼동이 줄어든다.

## 복습 질문

<details markdown="block">
<summary>1. 모든 열이 pivot column이면 왜 선형 독립인가?</summary>

답변: 모든 열이 pivot column이면 각 열이 이전 열들의 선형 결합으로 표현되지 않는다. 따라서 $$Ax=0$$의 해가 trivial solution $$x=0$$뿐이고, 열벡터들이 선형 독립이다.

</details>

<details markdown="block">
<summary>2. 기저가 바뀌면 벡터 자체가 바뀌는가, 좌표 표현이 바뀌는가?</summary>

답변: 벡터 자체가 바뀌는 것이 아니라 그 벡터를 표현하는 좌표가 바뀐다. 같은 대상이라도 어떤 basis를 기준으로 보느냐에 따라 coordinate vector가 달라진다.

</details>

<details markdown="block">
<summary markdown="span">3. $$\operatorname{rank}(A) < n$$이면 $$Ax=0$$은 어떤 해를 가지는가?</summary>

답변: column 수 $$n$$보다 rank가 작으면 nullity가 양수다. 따라서 $$Ax=0$$은 $$x=0$$ 외에도 non-trivial solution을 가지며, null space에 자유도가 존재한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-04.pdf</a></li>
</ul>
