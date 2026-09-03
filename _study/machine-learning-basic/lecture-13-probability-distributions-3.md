---
layout: default
date: 2026-05-20 12:30:12 +0900
title: "Lecture 13 Probability Distributions 3"
course: "Machine Learning Basic"
topic: "Probability Distributions 3"
order: 13
major_topic: "Machine Learning Foundations"
keywords:
  - "Multivariate Gaussian"
  - "Exponential Family"
  - "MLE"
  - "Conjugacy"
  - "Distribution Parameters"
---

# Lecture 13 Probability Distributions 3

Source PDF: `machine-learning-basic-lecture-13.pdf`

> **핵심:** **standard normal distribution은** 평균 0, 분산 1인 Gaussian. **multivariate Gaussian의 parameter는** mean vector \(\mu\), covariance matrix \(\Sigma\).

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Gaussian distribution | 정규분포가 왜 머신러닝의 기본 분포인가? |
| 2 | Multivariate Gaussian | 평균 벡터와 공분산 행렬은 분포의 무엇을 정하는가? |
| 3 | Conditional/Marginal Gaussian | 가우시안의 일부 변수만 보거나 일부 변수를 관측하면 어떤 분포가 되는가? |
| 4 | Sum and Mixture | 가우시안 확률변수의 합과 가우시안 분포의 혼합은 왜 다른가? |
| 5 | Linear transformation | 가우시안 확률변수는 선형 변환 후에도 가우시안인가? |
| 6 | Sampling | 표준정규분포 샘플로 원하는 평균과 공분산을 가진 샘플을 어떻게 만드는가? |
| 7 | Change of Variable | 확률변수를 함수로 변환하면 PDF를 어떻게 바꾸어야 하는가? |

13강은 확률분포 중 머신러닝에서 가장 자주 등장하는 Gaussian distribution을 다룬다. 핵심은 정규분포의 공식만 외우는 것이 아니라, 가우시안이 조건부분포, 주변분포, 선형결합, 선형변환에서 어떻게 닫혀 있는지 이해하는 것이다.

## 1. Gaussian Distribution

Gaussian distribution 또는 normal distribution은 실수 공간에서 정의되는 대표적인 연속 확률분포다. 일변수 가우시안은 평균 \(\mu\)와 분산 \(\sigma^2\)로 결정된다.

$$
p(x\mid\mu,\sigma^2)
=\frac{1}{\sqrt{2\pi\sigma^2}}
\exp\left(-\frac{(x-\mu)^2}{2\sigma^2}\right)
$$

각 parameter의 역할은 다음과 같다.

| parameter | 의미 | 분포에 미치는 영향 |
|---|---|---|
| \(\mu\) | 평균 | 분포의 중심을 좌우로 이동시킨다. |
| \(\sigma^2\) | 분산 | 값들이 평균 주변에 얼마나 퍼지는지 정한다. |
| \(\sigma\) | 표준편차 | 분포 폭의 scale로 해석한다. |

평균이 0이고 분산이 1인 가우시안을 표준정규분포라고 한다.

$$
X\sim\mathcal{N}(0,1)
$$

가우시안은 Gaussian process, variational inference, reinforcement learning, signal processing, control theory, statistical analysis뿐 아니라 neural network의 random initialization과 random noise sampling에서도 기본 도구로 쓰인다.

## 2. Multivariate Gaussian

다변수 가우시안 분포는 \(d\)차원 실수 공간에서 정의되는 확률분포다. 확률변수 \(x\in\mathbb{R}^d\)가 평균 \(\mu\), 공분산 \(\Sigma\)를 갖는 다변수 가우시안을 따르면 다음처럼 쓴다.

$$
x\sim\mathcal{N}(\mu,\Sigma)
$$

PDF는 다음과 같다.

$$
p(x\mid\mu,\Sigma)
=\frac{1}{(2\pi)^{d/2}\lvert\Sigma\rvert^{1/2}}
\exp\left(
-\frac{1}{2}(x-\mu)^T\Sigma^{-1}(x-\mu)
\right)
$$

| 항 | 의미 |
|---|---|
| \(\mu\) | 분포의 중심을 나타내는 평균 벡터 |
| \(\Sigma\) | 각 방향의 퍼짐과 변수 사이의 공분산을 담는 행렬 |
| \(\lvert\Sigma\rvert\) | 분포가 차지하는 부피 scale과 관련된 determinant |
| \(\Sigma^{-1}\) | 평균에서 얼마나 멀리 떨어졌는지 측정하는 metric 역할 |

공분산 행렬 \(\Sigma\)의 대각 원소는 각 변수의 분산이고, 비대각 원소는 변수 쌍의 공분산이다. 고유벡터는 분포가 늘어나는 주된 방향을, 고유값은 그 방향으로의 분산 크기를 나타낸다.

## 3. Conditional and Marginal Gaussian

다변수 가우시안의 중요한 장점은 조건부분포와 주변분포가 다시 가우시안이라는 점이다. 두 확률변수 블록 \(x\), \(y\)가 함께 가우시안이라고 하자.

$$
\begin{bmatrix}
x \\
y
\end{bmatrix}
\sim
\mathcal{N}\left(
\begin{bmatrix}
\mu_x \\
\mu_y
\end{bmatrix},
\begin{bmatrix}
\Sigma_{xx} & \Sigma_{xy} \\
\Sigma_{yx} & \Sigma_{yy}
\end{bmatrix}
\right)
$$

여기서 \(\Sigma_{xx}\)는 \(x\) 내부의 공분산, \(\Sigma_{yy}\)는 \(y\) 내부의 공분산, \(\Sigma_{xy}\)와 \(\Sigma_{yx}\)는 두 변수 블록 사이의 공분산이다.

\(y\)를 관측했을 때 \(x\)의 조건부분포는 다음과 같이 다시 가우시안이다.

$$
p(x\mid y)=\mathcal{N}(\mu_{x\mid y},\Sigma_{x\mid y})
$$

조건부 평균은 다음과 같다.

$$
\mu_{x\mid y}
=\mu_x+\Sigma_{xy}\Sigma_{yy}^{-1}(y-\mu_y)
$$

조건부 공분산은 다음과 같다.

$$
\Sigma_{x\mid y}
=\Sigma_{xx}-\Sigma_{xy}\Sigma_{yy}^{-1}\Sigma_{yx}
$$

이 식은 관측한 \(y\)가 평균 \(\mu_y\)에서 얼마나 벗어났는지를 보고 \(x\)에 대한 평균 추정을 조정한다. \(\Sigma_{xy}\)가 크면 \(y\) 관측이 \(x\) 추정에 더 강하게 반영된다.

반대로 \(y\)를 보지 않고 \(x\)만 보면 주변분포가 된다.

$$
p(x)=\int p(x,y)dy=\mathcal{N}(\mu_x,\Sigma_{xx})
$$

주변분포는 함께 있던 변수 중 일부를 적분해서 제거하는 것이다. 가우시안에서는 이 과정을 거쳐도 남은 변수는 여전히 가우시안이다.

## 4. Gaussian Random Variables의 합

가우시안 확률변수 \(x\), \(y\)가 서로 독립이고 다음 분포를 따른다고 하자.

$$
p(x)=\mathcal{N}(x\mid\mu_x,\Sigma_x),
\qquad
p(y)=\mathcal{N}(y\mid\mu_y,\Sigma_y)
$$

그러면 두 확률변수의 합 \(z=x+y\)도 가우시안이다.

$$
p(z)=\mathcal{N}(z\mid\mu_x+\mu_y,\Sigma_x+\Sigma_y)
$$

더 일반적인 선형결합 \(t=ax+by\)도 가우시안이다.

$$
p(t)
=\mathcal{N}(t\mid a\mu_x+b\mu_y,\;a^2\Sigma_x+b^2\Sigma_y)
$$

여기서 분산 또는 공분산이 더해지는 이유는 독립성을 가정했기 때문이다. 독립이 아니면 cross-covariance 항이 추가된다. 따라서 “각각 가우시안이다”만으로 충분한 것이 아니라, joint distribution의 구조가 중요하다.

## 5. Gaussian Sum과 Gaussian Mixture의 차이

강의에서 강조하는 헷갈리는 지점은 가우시안 확률변수의 합과 가우시안 분포의 가중합이 다르다는 것이다.

확률변수의 합은 다음 상황이다.

$$
z=x+y
$$

서로 독립인 가우시안 확률변수들을 더하면 결과 확률변수 \(z\)는 가우시안이 된다.

반면 가우시안 분포의 가중합은 다음 형태다.

$$
p(x)=a p_1(x)+(1-a)p_2(x)
$$

여기서

$$
p_1(x)=\mathcal{N}(x\mid\mu_1,\sigma_1^2),
\qquad
p_2(x)=\mathcal{N}(x\mid\mu_2,\sigma_2^2)
$$

이면 \(p(x)\)는 일반적으로 하나의 가우시안이 아니다. 두 봉우리를 가진 bimodal distribution이 될 수도 있다. 이 아이디어가 Gaussian mixture model의 기본이다.

## 6. Linear Transformation

가우시안 확률변수는 선형 변환에 대해 닫혀 있다. 즉,

$$
x\sim\mathcal{N}(\mu,\Sigma)
$$

이고

$$
y=Ax
$$

라면 \(y\)도 가우시안이다.

평균은 다음처럼 변환된다.

$$
\mathbb{E}[Ax]=A\mathbb{E}[x]=A\mu
$$

공분산은 다음처럼 변환된다.

$$
\operatorname{Var}(Ax)
=A\operatorname{Var}(x)A^T
=A\Sigma A^T
$$

따라서

$$
p(y)=\mathcal{N}(y\mid A\mu,A\Sigma A^T)
$$

선형 변환은 분포를 이동시키는 것이 아니라, 평균 벡터와 공분산 구조를 행렬 \(A\)에 맞게 회전, 스케일링, shearing, projection하는 과정으로 볼 수 있다.

## 7. Linear Transformation 예시

강의 예시에서는 다음 가우시안 확률변수를 사용한다.

$$
\begin{bmatrix}
x_1 \\
x_2
\end{bmatrix}
\sim
\mathcal{N}\left(
\begin{bmatrix}
1 \\
2
\end{bmatrix},
\begin{bmatrix}
2 & 1 \\
1 & 1
\end{bmatrix}
\right)
$$

그리고 선형변환 행렬을 다음처럼 둔다.

$$
A=
\begin{bmatrix}
1 & 2 \\
3 & 4
\end{bmatrix}
$$

\(y=Ax\)의 평균은

$$
A\mu_x
=
\begin{bmatrix}
1 & 2 \\
3 & 4
\end{bmatrix}
\begin{bmatrix}
1 \\
2
\end{bmatrix}
=
\begin{bmatrix}
5 \\
11
\end{bmatrix}
$$

이다. 공분산은

$$
A\Sigma_x A^T
=
\begin{bmatrix}
1 & 2 \\
3 & 4
\end{bmatrix}
\begin{bmatrix}
2 & 1 \\
1 & 1
\end{bmatrix}
\begin{bmatrix}
1 & 3 \\
2 & 4
\end{bmatrix}
=
\begin{bmatrix}
10 & 24 \\
24 & 58
\end{bmatrix}
$$

가 된다. 변환 후 분포는 중심이 \([5,11]^T\)로 이동하고, 공분산도 \(A\)의 방향과 scale에 맞게 바뀐다.

## 8. Sampling

표준정규분포에서 샘플링할 수 있다고 하자.

$$
z\sim\mathcal{N}(0,I)
$$

목표는 원하는 평균 \(\mu\)와 공분산 \(\Sigma\)를 가진 샘플을 만드는 것이다.

$$
y\sim\mathcal{N}(\mu,\Sigma)
$$

선형 변환 성질을 이용하면 다음과 같이 만들 수 있다.

$$
y=\mu+Lz
$$

여기서 \(L\)은 다음을 만족하는 행렬이다.

$$
LL^T=\Sigma
$$

그러면 평균은

$$
\mathbb{E}[y]=\mu+L\mathbb{E}[z]=\mu
$$

이고, 공분산은

$$
\operatorname{Var}(y)=L\operatorname{Var}(z)L^T=LIL^T=LL^T=\Sigma
$$

가 된다. 실제로는 \(\Sigma\)의 Cholesky decomposition이나 eigen decomposition을 이용해 \(L\)을 구한다.

## 9. Change of Variable

변수 변환은 확률변수 \(x\)가 있을 때 새로운 확률변수

$$
y=u(x)
$$

의 분포를 구하는 문제다.

이산확률변수라면 같은 \(y\)를 만드는 모든 \(x\)의 확률을 더한다. 예를 들어 \(x\in\{-2,-1,0,1,2\}\)가 각각 \(\frac{1}{5}\)의 확률을 갖고 \(y=x^2\)라면 다음과 같다.

| \(y\) | 가능한 \(x\) | 확률 |
|---|---|---|
| 0 | 0 | \(\frac{1}{5}\) |
| 1 | -1, 1 | \(\frac{2}{5}\) |
| 4 | -2, 2 | \(\frac{2}{5}\) |

즉, 변환이 many-to-one이면 preimage에 해당하는 확률들을 모아야 한다.

연속확률변수에서는 CDF를 먼저 구한 뒤 미분하는 방식이 기본이다. \(Y=u(X)\)라면

$$
F_Y(y)=P(Y\le y)
$$

를 먼저 계산하고,

$$
f_Y(y)=\frac{d}{dy}F_Y(y)
$$

로 PDF를 얻는다.

## 10. Continuous Change of Variable 예시

강의 예시는 다음과 같다.

$$
f_X(x)=3x^2,\qquad 0\le x\le 1
$$

그리고

$$
y=x^2
$$

라고 하자. \(0\le y\le 1\)에서 CDF는 다음처럼 계산된다.

$$
F_Y(y)
=P(Y\le y)
=P(X^2\le y)
=P(X\le\sqrt{y})
$$

\(X\)의 support가 \([0,1]\)이므로

$$
F_Y(y)
=\int_0^{\sqrt{y}}3x^2dx
=x^3\bigg|_0^{\sqrt{y}}
=y^{3/2}
$$

따라서 PDF는

$$
f_Y(y)
=\frac{d}{dy}F_Y(y)
=\frac{3}{2}y^{1/2},
\qquad 0\le y\le 1
$$

이다.

## 11. Change of Variable Technique

\(y=u(x)\)이고 \(u\)가 가역함수라고 하자. 이때는 CDF를 거치지 않고 Jacobian으로 density를 바로 바꿀 수 있다.

일변수에서는 다음과 같다.

$$
f_Y(y)
=f_X(u^{-1}(y))
\left\lvert
\frac{d}{dy}u^{-1}(y)
\right\rvert
$$

다변수에서는 derivative가 Jacobian matrix가 되고, 부피 변화율을 determinant로 보정한다.

$$
f_Y(y)
=f_X(u^{-1}(y))
\left\lvert
\det\left(
\frac{\partial}{\partial y}u^{-1}(y)
\right)
\right\rvert
$$

Jacobian 보정이 필요한 이유는 변수 변환이 길이, 면적, 부피를 늘리거나 줄이기 때문이다. density는 확률 자체가 아니라 단위 부피당 확률이므로, 좌표계가 바뀌면 부피 변화율을 함께 보정해야 한다.

## 12. 변수 변환으로 보는 가우시안 선형 변환

표준 2차원 가우시안

$$
x=
\begin{bmatrix}
x_1 \\
x_2
\end{bmatrix}
$$

가 다음 PDF를 따른다고 하자.

$$
f_X(x)
=\frac{1}{2\pi}
\exp\left(-\frac{1}{2}x^Tx\right)
$$

선형변환 \(y=Ax\)를 적용하고

$$
A=
\begin{bmatrix}
a & b \\
c & d
\end{bmatrix}
$$

라고 하자. \(x=A^{-1}y\)이므로

$$
f_X(A^{-1}y)
=\frac{1}{2\pi}
\exp\left(
-\frac{1}{2}y^TA^{-T}A^{-1}y
\right)
$$

Jacobian 보정은 다음과 같다.

$$
\left\lvert\det(A^{-1})\right\rvert
=\frac{1}{\lvert ad-bc\rvert}
$$

따라서

$$
f_Y(y)
=
\frac{1}{2\pi}
\exp\left(
-\frac{1}{2}y^TA^{-T}A^{-1}y
\right)
\frac{1}{\lvert ad-bc\rvert}
$$

이 식은 선형변환된 가우시안의 PDF를 변수 변환 관점에서 다시 본 것이다. \(A\)가 공간을 크게 늘리면 density는 그만큼 작아지고, 공간을 압축하면 density는 커진다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| standard normal distribution은? | 평균 0, 분산 1인 Gaussian |
| multivariate Gaussian의 parameter는? | mean vector \(\mu\), covariance matrix \(\Sigma\) |
| Gaussian의 marginal distribution은? | 다시 Gaussian이며 해당 block의 평균과 공분산을 사용한다. |
| Gaussian의 conditional distribution은? | 다시 Gaussian이며 \(\mu_{x\mid y}\), \(\Sigma_{x\mid y}\) 공식으로 계산한다. |
| 독립 Gaussian 확률변수의 선형결합은? | 다시 Gaussian |
| Gaussian mixture는 항상 Gaussian인가? | 아니다. 여러 봉우리를 가질 수 있다. |
| \(y=Ax\)에서 평균과 공분산은? | 평균 \(A\mu\), 공분산 \(A\Sigma A^T\) |
| sampling에서 \(y=\mu+Lz\)를 쓰는 이유는? | \(LL^T=\Sigma\)가 되게 하여 원하는 공분산을 만들기 위해 |
| 변수 변환에서 Jacobian이 필요한 이유는? | 좌표 변환에 따른 길이, 면적, 부피 변화율을 density에 반영하기 위해 |

## Study Guide

standard Gaussian에서 multivariate Gaussian으로 확장하며 mean vector와 covariance block의 shape를 먼저 확인한다. marginal·conditional Gaussian 공식을 block별로 적용하고, y=Ax에서 평균 Aμ와 공분산 AΣAᵀ를 직접 계산한다. sampling은 z에서 y=μ+Lz로 옮기는 과정, density 변환은 Jacobian으로 부피 변화를 보정하는 과정이라는 차이를 분리한다.

## 복습 질문

<details>
<summary>1. 공분산 행렬 \(\Sigma\)의 고유값이 큰 방향은 데이터 분포에서 어떤 의미인가?</summary>

답변: 고유값이 큰 방향은 데이터가 그 방향으로 많이 퍼져 있다는 뜻이다. 다변수 가우시안의 등고선은 공분산 행렬의 고유벡터 방향으로 늘어나며, 고유값이 클수록 해당 축의 분산이 크다. PCA에서는 이런 방향이 principal component가 된다.

</details>

<details>
<summary>2. \(x\)와 \(y\)가 Gaussian이면 \(x+y\)는 항상 Gaussian인가?</summary>

답변: 독립인 Gaussian random variable들의 선형 결합은 Gaussian이다. 더 일반적으로 joint Gaussian인 변수들의 선형 결합도 Gaussian이다. 하지만 각각의 marginal distribution이 Gaussian이라는 사실만으로 항상 합이 Gaussian이라고 단정할 수는 없다. joint distribution의 구조가 중요하다.

</details>

<details>
<summary>3. 가우시안 확률변수의 합과 가우시안 mixture는 왜 다른가?</summary>

답변: 확률변수의 합은 \(z=x+y\)처럼 두 random variable을 더해 새로운 random variable을 만드는 것이다. 독립 Gaussian이라면 결과도 Gaussian이다. 반면 mixture는 \(p(x)=a p_1(x)+(1-a)p_2(x)\)처럼 여러 분포 중 하나에서 샘플이 왔다고 보는 모델이다. mixture는 여러 봉우리를 가질 수 있어 일반적으로 하나의 Gaussian이 아니다.

</details>

<details>
<summary>4. \(y=Ax\), \(x\sim\mathcal{N}(\mu,\Sigma)\)일 때 \(y\)의 평균과 공분산은 어떻게 되는가?</summary>

답변: 평균은 \(\mathbb{E}[y]=\mathbb{E}[Ax]=A\mu\)이고, 공분산은 \(\operatorname{Var}(y)=\operatorname{Var}(Ax)=A\Sigma A^T\)이다. 따라서 \(y\sim\mathcal{N}(A\mu,A\Sigma A^T)\)이다.

</details>

<details>
<summary>5. 표준정규 샘플 \(z\sim\mathcal{N}(0,I)\)로 \(\mathcal{N}(\mu,\Sigma)\) 샘플을 만들려면 어떻게 해야 하는가?</summary>

답변: \(LL^T=\Sigma\)를 만족하는 행렬 \(L\)을 구한 뒤 \(y=\mu+Lz\)로 변환한다. 그러면 평균은 \(\mu\), 공분산은 \(LIL^T=LL^T=\Sigma\)가 된다. \(L\)은 보통 Cholesky decomposition으로 구한다.

</details>

<details>
<summary>6. \(y=x^2\)처럼 여러 \(x\)가 같은 \(y\)로 가는 변환에서는 확률을 어떻게 모아야 하는가?</summary>

답변: 같은 \(y\)를 만드는 모든 \(x\)의 확률 기여를 더해야 한다. 이산형이면 preimage들의 확률을 합한다. 연속형이면 CDF를 먼저 계산해 미분하거나, 각 branch의 inverse transform과 Jacobian 보정을 모두 더한다.

</details>

<details>
<summary>7. 변수 변환 공식에서 determinant의 절댓값은 왜 들어가는가?</summary>

답변: determinant는 변환이 부피를 얼마나 늘리거나 줄이는지 나타낸다. PDF는 단위 부피당 확률이므로, 좌표 변환으로 부피가 변하면 density도 반대로 조정되어야 전체 확률이 보존된다. 절댓값을 쓰는 이유는 부피 scale은 방향 전환 여부와 무관하게 양수여야 하기 때문이다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-13.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-13.pdf</a></li>
</ul>
