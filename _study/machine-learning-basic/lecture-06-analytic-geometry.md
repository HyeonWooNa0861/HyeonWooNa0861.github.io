---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
title: "Lecture 06 Analytic Geometry"
course: "Machine Learning Basic"
topic: "Analytic Geometry"
order: 6
major_topic: "Machine Learning Foundations"
keywords:
  - "Analytic Geometry"
  - "Norms"
  - "Angles"
  - "Distances"
  - "Orthogonal Projections"
---

# Lecture 06 Analytic Geometry

Source PDF: `machine-learning-basic-lecture-06.pdf`

> **핵심:** **norm과 inner product의 관계는** 모든 내적은 norm을 만들지만 모든 norm이 내적에서 오지는 않는다. **SPD 행렬의 의미는** 내적을 표현할 수 있는 symmetric positive definite 행렬.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Norm | 벡터의 길이는 어떻게 정의하는가? |
| 2 | Inner Product | 각도와 직교성을 정의하려면 무엇이 필요한가? |
| 3 | SPD Matrix | 내적은 행렬로 어떻게 표현되는가? |
| 4 | Distance and Orthogonality | 거리, 각도, 수직은 내적에 따라 어떻게 달라지는가? |
| 5 | Orthogonal Projection | 부분공간에서 가장 가까운 벡터는 어떻게 찾는가? |
| 6 | Rotation | 길이와 각도를 보존하는 변환은 무엇인가? |

### 원문 수식 추적표

| PDF 페이지 | 중요 정의·식 | 본문 대응 |
|---:|---|---|
| 2–6 | norm 공리, inner product·bilinear form | 1, 2 |
| 7–12 | Cauchy–Schwarz, $$\langle x,y\rangle_A=x^TAy$$, SPD 조건 | 2, 3, 8.1 |
| 13–18 | 거리, 각도 $$\cos\omega=\langle x,y\rangle/(\lVert x\rVert\lVert y\rVert)$$, 직교성 | 4, 8.1 |
| 19–23 | 직교행렬·정규직교기저·투영의 정의 | 5, 6, 8.4 |
| 24–31 | 1차원·다차원 직교투영 $$P=B(B^TB)^{-1}B^T$$ | 6, 8.2, 8.3 |
| 32–36 | 2차원·3차원·$$n$$차원 rotation matrix와 보존 성질 | 7, 7.1, 8.4 |

페이지 37은 Q&A 마무리이다.

## 1. Norm

Norm은 벡터를 길이로 보내는 함수다.

대표 예시는 다음과 같다.

| 이름 | 직관 |
|---|---|
| Manhattan norm / $$\ell_1$$ | 좌표축을 따라 이동한 거리 |
| Euclidean norm / $$\ell_2$$ | 직선 거리 |

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
| SPD | symmetric이고 $$x^T A x > 0$$ for $$x \ne 0$$ |
| SPSD | symmetric이고 $$x^T A x \ge 0$$ |

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

내적이 주어진 유한차원 공간에서 부분공간으로의 **orthogonal projection**은 벡터를 그 부분공간 위의 유일한 가장 가까운 벡터로 보낸다. 일반적인 projection은 직교가 아닐 수 있으므로 이 nearest-point 성질을 보장하지 않는다.

1차원 부분공간에서는 벡터 $$x$$를 방향 벡터 $$u$$ 위로 내린 그림자로 이해할 수 있다.

$$m$$차원 부분공간으로의 orthogonal projection은 least squares와 직접 연결된다. $$Ax=b$$의 해가 없을 때, $$b$$에 가장 가까운 column space 위의 벡터를 찾는 문제가 orthogonal projection이다.

## 7. Rotation

회전은 길이와 각도를 보존하는 선형 변환이다.

| 특성 | 설명 |
|---|---|
| 거리 보존 | 회전 전후 벡터 사이 거리가 같다. |
| 각도 보존 | 회전 전후 벡터 사이 각도가 같다. |
| 비가환성 | 3차원 회전은 일반적으로 순서가 바뀌면 결과가 달라진다. |

### 7.1 좌표계와 회전 방향 관례

이 절은 **오른손 좌표계**, **열벡터**, 원점에 고정된 축 주위로 벡터를 능동적으로 회전시키는 active rotation을 사용한다. 양의 각도는 회전축의 양의 방향에서 원점을 바라볼 때 반시계 방향인 오른손 법칙을 따른다. Passive coordinate rotation을 쓰면 같은 기하 변화의 행렬은 전치, 즉 역행렬이 되므로 관례를 섞으면 부호가 뒤집힌다.

2차원 회전은

$$
R(\theta)=
\begin{bmatrix}
\cos\theta&-\sin\theta\\
\sin\theta&\cos\theta
\end{bmatrix}
$$

이다. 기저벡터 $$e_1$$이 $$(\cos\theta,\sin\theta)^T$$로, $$e_2$$가 $$(-\sin\theta,\cos\theta)^T$$로 가므로 두 상을 열로 놓으면 이 행렬을 얻는다. $$R^TR=I$$와 $$\det R=1$$이므로 길이와 방향을 보존한다.

3차원 좌표축 회전은 같은 관례에서

$$
R_x(\theta)=
\begin{bmatrix}
1&0&0\\
0&\cos\theta&-\sin\theta\\
0&\sin\theta&\cos\theta
\end{bmatrix},
$$

$$
R_y(\theta)=
\begin{bmatrix}
\cos\theta&0&\sin\theta\\
0&1&0\\
-\sin\theta&0&\cos\theta
\end{bmatrix},
\qquad
R_z(\theta)=
\begin{bmatrix}
\cos\theta&-\sin\theta&0\\
\sin\theta&\cos\theta&0\\
0&0&1
\end{bmatrix}.
$$

고정한 축 성분은 그대로 두고 그 축에 수직인 좌표평면에서 2차원 회전을 수행한 것이다. 예를 들어 먼저 각도 $$\alpha$$로 $$x$$축 회전, 다음 각도 $$\beta$$로 $$z$$축 회전을 적용하면 열벡터 $$v$$에는 $$R_z(\beta)R_x(\alpha)v$$가 작용한다. 일반적으로 $$R_z(\beta)R_x(\alpha)\ne R_x(\alpha)R_z(\beta)$$이므로 순서를 명시해야 한다.

같은 생각은 $$\mathbb{R}^{n}$$의 임의 좌표평면 $$(i,j)$$ 회전으로 확장된다. $$R_{ij}^{(n)}(\theta)$$는 항등행렬에서 $$i,j$$ 행·열이 만나는 $$2\times2$$ block만

$$
\begin{bmatrix}
\cos\theta&-\sin\theta\\
\sin\theta&\cos\theta
\end{bmatrix}
$$

로 바꾼 행렬이다. 따라서 좌표는

$$
x_i'=\cos\theta\,x_i-\sin\theta\,x_j,
\qquad
x_j'=\sin\theta\,x_i+\cos\theta\,x_j
$$

로 변하고 $$k\notin\{i,j\}$$인 나머지 좌표는 $$x_k'=x_k$$로 유지된다. 이 coordinate-plane rotation들을 합성하면 일반적인 proper orthogonal transformation을 구성할 수 있지만, 합성 순서와 각도 표현은 유일하지 않을 수 있다.

단위벡터 $$u=(u_1,u_2,u_3)^T$$인 임의 축 주위 회전은 Rodrigues 공식

$$
R_u(\theta)
=\cos\theta I+(1-\cos\theta)uu^T+\sin\theta[u]_{\times},
$$

$$
[u]_{\times}=
\begin{bmatrix}
0&-u_3&u_2\\
u_3&0&-u_1\\
-u_2&u_1&0
\end{bmatrix}
$$

로 쓸 수 있다. $$[u]_{\times}v=u\times v$$이고, $$v$$를 축 방향 $$uu^Tv$$와 수직 방향으로 분해하면 축 방향은 유지되고 수직 평면에서 cosine·sine 성분이 회전하므로 위 식이 나온다.

- **성립 조건:** $$\lVert u\rVert_2=1$$이어야 한다. 그렇지 않으면 먼저 정규화한다.
- **단위:** $$\theta$$는 삼각함수에 넣을 때 radian의 무차원 각도이고, $$R$$은 같은 물리 공간 안에서는 무차원이다. 회전된 벡터는 원래 벡터와 같은 단위를 갖는다.
- **한계:** 이 행렬들은 원점 통과 축 주위의 순수 회전이다. 원점을 지나지 않는 축이나 점 $$c$$ 주위 회전은 $$c+R(x-c)$$라는 affine 변환이 필요하다. Reflection까지 포함하는 일반 orthogonal matrix는 determinant가 $$-1$$일 수 있으므로, $$Q^TQ=I$$만으로 반드시 회전이라고 할 수 없고 proper rotation에는 $$\det Q=1$$도 필요하다.
- **정확성과 근사:** 실수 삼각함수의 수학적 식은 정확하다. 부동소수점 구현에서는 $$R^TR\approx I$$이며 반복 합성 시 drift가 누적될 수 있어 재직교화가 필요할 수 있다.

## 8. 핵심 기하식의 유도

### 8.1 내적에서 각도식이 나오는 이유

실수 내적공간에서 $$x,y\ne0$$라 하자. Cauchy-Schwarz 부등식 $$\lvert x^Ty\rvert\le\lVert x\rVert_2\lVert y\rVert_2$$ 때문에 다음 비율은 $$[-1,1]$$ 안에 있다.

$$
\cos\theta=\frac{x^Ty}{\lVert x\rVert_2\lVert y\rVert_2}
$$

이는 Euclidean inner product에 대한 **정의**다. 분모가 0인 영벡터에는 각도를 정의할 수 없다. 일반 SPD metric $$A$$에서는 $$x^Ty$$ 대신 $$x^TAy$$, norm 대신 $$\sqrt{x^TAx}$$를 사용한다.

### 8.2 1차원 직교투영 공식

$$u\ne0$$가 만드는 직선 위의 점을 $$\hat{x}=\alpha u$$라 두고, 잔차 $$r=x-\alpha u$$가 $$u$$와 직교하도록 선택한다.

$$
u^Tr=0
\iff u^T(x-\alpha u)=0
\iff \alpha=\frac{u^Tx}{u^Tu}
$$

따라서 $$\operatorname{proj}_u(x)=\frac{u^Tx}{u^Tu}u$$다. 이는 **정확한 등식**이고 $$u\ne0$$가 필요하다. 이 잔차 직교 조건은 $$\lVert x-\alpha u\rVert_2^2$$ 최소화의 일차 조건이므로 least squares로 이어진다.

### 8.3 다차원 부분공간으로의 직교투영

$$m$$차원 부분공간 $$U\subseteq\mathbb{R}^n$$의 정렬된 기저를 $$b_1,\ldots,b_m$$이라 하고

$$
B=\begin{bmatrix}b_1&\cdots&b_m\end{bmatrix}\in\mathbb{R}^{n\times m},
\qquad
\lambda\in\mathbb{R}^m
$$

로 둔다. 투영점은 $$\widehat x=B\lambda$$이고 잔차 $$r=x-B\lambda$$는 $$U$$의 모든 기저 벡터와 직교해야 한다. 이 $$m$$개 조건을 쌓으면

$$
B^T(x-B\lambda)=0.
$$

따라서 normal equation은

$$
B^TB\lambda=B^Tx.
$$

$$b_1,\ldots,b_m$$이 기저이므로 $$B$$는 full column rank이고, 모든 $$z\ne0$$에 대해 $$z^TB^TBz=\lVert Bz\rVert_2^2>0$$이다. 즉 $$B^TB$$는 SPD이고 가역이므로

$$
\lambda=(B^TB)^{-1}B^Tx,
$$

$$
\widehat x=B\lambda=B(B^TB)^{-1}B^Tx,
\qquad
P_U=B(B^TB)^{-1}B^T.
$$

이 식은 Euclidean dot product와 full-column-rank $$B$$ 아래에서 **정확한 직교투영 공식**이다. $$x\in\mathbb{R}^n$$, $$B^Tx\in\mathbb{R}^m$$, $$P_U\in\mathbb{R}^{n\times n}$$이며, $$P_U^T=P_U$$와 $$P_U^2=P_U$$를 만족한다.

기저가 정규직교이면 $$B^TB=I_m$$이므로

$$
\lambda=B^Tx,
\qquad
P_U=BB^T,
\qquad
\widehat x=BB^Tx
$$

로 단순해진다.

> **작성자 보충:** $$B$$의 열이 종속이면 $$(B^TB)^{-1}$$는 존재하지 않고 좌표 $$\lambda$$는 유일하지 않다. 그래도 부분공간 위의 투영점은 유일하며 Moore-Penrose inverse로 $$P_U=BB^{\dagger}$$라 쓸 수 있다. 수치 계산에서는 normal equation이 condition number를 악화시키므로 QR/SVD가 더 안정적이고, 계산 결과의 직교성·멱등성은 반올림 때문에 근사적으로만 성립할 수 있다.

$$B$$의 열과 $$x$$가 같은 물리 단위를 가지면 $$\lambda$$와 $$P_U$$는 무차원이고 $$\widehat x$$는 $$x$$와 같은 단위를 갖는다. 열마다 서로 다른 단위나 의미를 갖는 feature matrix라면 dot product 자체가 scale에 의존하므로 먼저 metric 또는 scaling을 정의해야 한다.

### 8.4 Orthogonal matrix가 길이를 보존하는 이유

$$Q^TQ=I$$이면

$$
\lVert Qx\rVert_2^2=(Qx)^T(Qx)=x^TQ^TQx=x^Tx=\lVert x\rVert_2^2.
$$

같은 계산으로 $$(Qx)^T(Qy)=x^Ty$$이므로 각도도 보존된다. 수치 계산에서는 반올림 때문에 $$Q^TQ\approx I$$만 성립할 수 있으며 이때 보존도 근사적이다.

| 기호 | 의미 | 단위 |
|---|---|---|
| $$x,y,u$$ | 벡터 | 각 좌표의 물리 단위; 추상 예제에서는 무차원 |
| $$\theta$$ | 두 벡터 사이 각도 | rad 또는 degree |
| $$A$$ | SPD metric matrix | $$x^TAy$$가 원하는 단위를 갖도록 결정 |
| $$Q$$ | 직교 변환 | 같은 단위 공간에서는 무차원 |
| $$\alpha$$ | 투영 계수 | $$x$$ 단위/$$u$$ 단위 |

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| norm과 inner product의 관계는? | 모든 내적은 norm을 만들지만 모든 norm이 내적에서 오지는 않는다. |
| SPD 행렬의 의미는? | 내적을 표현할 수 있는 symmetric positive definite 행렬 |
| orthogonal matrix의 핵심 성질은? | 길이와 각도 보존, $$A^TA = I$$ |
| orthogonal projection이 least squares와 연결되는 이유는? | column space에서 가장 가까운 벡터를 찾기 때문 |

## Study Guide

inner product에서 norm, distance, angle을 차례로 계산해 각 정의가 앞 개념에 의존하는 흐름을 잡는다. SPD 조건 xᵀAx>0과 orthogonal 조건 AᵀA=I를 섞지 말고, 후자가 길이와 각도를 보존함을 직접 계산한다. orthogonal projection은 column space에서 가장 가까운 점을 찾는 절차로 재현해 least squares와의 연결까지 확인한다.

## 복습 질문

<details markdown="block">
<summary>1. dot product가 아닌 내적에서는 수직의 의미가 어떻게 달라질 수 있는가?</summary>

답변: 수직은 내적값이 0이라는 조건으로 정의된다. 내적이 바뀌면 길이와 각도를 재는 방식이 달라지므로, 같은 두 벡터도 어떤 inner product를 쓰느냐에 따라 orthogonal 여부가 달라질 수 있다.

</details>

<details markdown="block">
<summary markdown="span">2. $$A^TA = I$$이면 왜 $$A^{-1} = A^T$$인가?</summary>

답변: $$A^TA=I$$는 $$A^T$$가 $$A$$의 left inverse라는 뜻이다. 정사각 orthogonal matrix에서는 left inverse와 inverse가 같으므로 $$A^{-1}=A^T$$가 된다. 기하적으로는 길이와 각도를 보존하는 변환이다.

</details>

<details markdown="block">
<summary markdown="span">3. $$Ax=b$$에 해가 없을 때 projection 관점에서는 무엇을 찾는가?</summary>

답변: $$b$$가 column space 밖에 있으면 정확한 해는 없다. 이때는 $$b$$를 column space 위로 orthogonal projection한 점을 찾고, $$Ax$$가 그 projection과 일치하도록 하는 least squares 해를 구한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-06.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-06.pdf</a></li>
</ul>
