---
layout: default
date: 2026-06-03 19:46:42 +0900
title: "Machine Learning Basic Final Assignment"
course: "Machine Learning Basic"
topic: "Final Assignment"
---

# Machine Learning Basic Final Assignment

Source PDF: `machine-learning-basic-final-assignment.pdf`

이 글은 `기말과제.pdf`를 평가 대비형 과제 자료로 다시 작성한 것이다. 단순 정답만 적지 않고, 각 문항이 어떤 개념을 묻는지, 풀이를 어떻게 시작해야 하는지, 어떤 변형 문제가 나올 수 있는지까지 함께 정리한다.

## 전체 흐름

| 문항 | 핵심 주제 | 평가 대비 학습 목표 |
|---:|---|---|
| 1 | Bayes 정리, 조건부 확률, 이항분포 | 검사 결과를 본 뒤 posterior를 계산하고, 조건부 확률을 이항분포 문제로 확장 |
| 2 | Gradient descent | Gradient를 구하고 step size를 적용해 parameter를 한 번 update |
| 3 | Convex function | 정의로 convex를 증명하거나 반례로 non-convex를 판단 |
| 4 | Polynomial regression, MLE, predictive distribution | Feature matrix를 만들고 MLE 해와 예측분포를 계산 |

이 과제형 자료의 핵심은 다음 네 가지다.

1. 확률 문제는 Bayes 정리의 분모, 즉 evidence를 정확히 계산해야 한다.
2. 최적화 문제는 gradient 부호와 row/column convention을 헷갈리지 않아야 한다.
3. Convex 판정은 "느낌"이 아니라 정의 또는 반례로 써야 한다.
4. 선형회귀 문제는 \\(\Phi\\) 행렬을 정확히 만든 뒤 MLE와 예측분포까지 이어야 한다.

## 1. Bayes 정리와 조건부 이항분포

### 출제 의도

이 문제는 "검사에서 양성"이라는 관측 정보를 얻은 뒤, 실제 불량일 확률을 Bayes 정리로 갱신하는 문제다. 이후 그 posterior를 새로운 성공확률로 보고 이항분포의 기대값과 exact probability를 계산하게 만든다.

정리해야 할 개념은 다음과 같다.

| 개념 | 의미 |
|---|---|
| Prior | 검사 전 불량률 \\(P(D)\\) |
| Likelihood | 실제 불량일 때 양성이 나올 확률 \\(P(T=+\mid D)\\) |
| False positive rate | 실제 불량이 아닐 때 양성이 나올 확률 \\(P(T=+\mid D^c)\\) |
| Evidence | 양성 결과 자체의 전체 확률 \\(P(T=+)\\) |
| Posterior | 양성 결과를 본 뒤 실제 불량일 확률 \\(P(D\mid T=+)\\) |

### 원문 문제 재구성

어떤 공장에서 생산되는 부품의 불량 여부를 \\(D\\), 검사 결과를 \\(T\\)라고 하자.

$$
P(D)=0.08
$$

검사기는 다음을 만족한다.

$$
P(T=+\mid D)=0.85,
\qquad
P(T=+\mid D^c)=0.12
$$

<details>
<summary>1-1. 양성 판정을 받은 부품이 실제 불량일 확률 \\(P(D\mid T=+)\\)를 구하라.</summary>

풀이과정:

Bayes 정리를 바로 쓴다.

$$
P(D\mid T=+)
=
\frac{P(T=+\mid D)P(D)}{P(T=+)}
$$

분모는 전체 확률 법칙으로 계산한다.

$$
P(T=+)
=
P(T=+\mid D)P(D)
+
P(T=+\mid D^c)P(D^c)
$$

값을 대입하면

$$
P(T=+)
=
0.85\cdot 0.08
+
0.12\cdot 0.92
=
0.1784
$$

따라서

$$
P(D\mid T=+)
=
\frac{0.85\cdot 0.08}{0.1784}
=
\frac{0.068}{0.1784}
=
\frac{85}{223}
\approx
0.3812
$$

답변: \\(P(D\mid T=+)=\frac{85}{223}\approx 0.3812\\)이다.

</details>

<details>
<summary>1-2. 양성 판정을 받은 서로 독립인 30개 부품 중 실제 불량품 수의 기대값을 구하라.</summary>

풀이과정:

양성 판정을 받았다는 조건 아래에서 각 부품이 실제 불량일 확률은

$$
p=P(D\mid T=+)=\frac{85}{223}
$$

이다.

서로 독립인 30개 부품 중 실제 불량품 수를 \\(X\\)라고 하면

$$
X\sim\operatorname{Binomial}(30,p)
$$

이항분포의 기대값은 \\(np\\)다.

$$
\mathbb{E}[X]
=
30\cdot\frac{85}{223}
=
\frac{2550}{223}
\approx
11.435
$$

답변: 실제 불량품 수의 기대값은 \\(\frac{2550}{223}\approx 11.435\\)개다.

</details>

<details>
<summary>1-3. 양성 판정을 받은 서로 독립인 3개 부품 중 정확히 2개가 실제 불량일 확률을 구하라.</summary>

풀이과정:

각 부품이 실제 불량일 조건부 확률은

$$
p=\frac{85}{223}
$$

이고, 실제 불량이 아닐 확률은

$$
1-p=\frac{138}{223}
$$

정확히 2개가 불량일 확률은 이항분포 PMF를 사용한다.

$$
P(X=2)
=
\binom{3}{2}
\left(\frac{85}{223}\right)^2
\left(\frac{138}{223}\right)
$$

$$
P(X=2)\approx 0.2697
$$

답변: 정확히 2개가 실제 불량일 확률은 \\(\binom{3}{2}(85/223)^2(138/223)\approx 0.2697\\)이다.

</details>

### 관련 변형 문제

<details>
<summary>변형 1. 음성 판정을 받은 부품이 실제 불량일 확률 \\(P(D\mid T=-)\\)를 구하라.</summary>

풀이과정:

먼저 음성 likelihood를 구한다.

$$
P(T=-\mid D)=1-0.85=0.15
$$

$$
P(T=-\mid D^c)=1-0.12=0.88
$$

Bayes 정리를 적용한다.

$$
P(D\mid T=-)
=
\frac{P(T=-\mid D)P(D)}
{P(T=-\mid D)P(D)+P(T=-\mid D^c)P(D^c)}
$$

값을 대입하면

$$
P(D\mid T=-)
=
\frac{0.15\cdot 0.08}
{0.15\cdot 0.08+0.88\cdot 0.92}
\approx
0.0146
$$

답변: \\(P(D\mid T=-)\approx 0.0146\\)이다. 음성 판정 후에는 실제 불량일 확률이 매우 작아진다.

</details>

<details>
<summary>변형 2. 양성 판정을 받은 3개 부품 중 적어도 1개가 실제 불량일 확률을 구하라.</summary>

풀이과정:

\\(p=P(D\mid T=+)=85/223\\)라고 두면, 3개 중 적어도 1개가 불량일 확률은 여사건을 이용한다.

$$
P(X\ge 1)
=
1-P(X=0)
$$

$$
P(X=0)
=
\left(1-\frac{85}{223}\right)^3
=
\left(\frac{138}{223}\right)^3
$$

따라서

$$
P(X\ge 1)
=
1-\left(\frac{138}{223}\right)^3
\approx
0.7630
$$

답변: 적어도 1개가 실제 불량일 확률은 약 \\(0.7630\\)이다.

</details>

### 실수 포인트

| 실수 | 고치는 방법 |
|---|---|
| \\(P(D\mid T=+)\\)를 \\(P(T=+\mid D)\\)와 같다고 착각 | Bayes 정리로 방향을 반드시 바꾼다. |
| 분모 \\(P(T=+)\\)를 빼먹음 | 전체 확률 법칙으로 evidence를 계산한다. |
| 30개 기대값에서 \\(0.08\\)을 그대로 사용 | 양성 판정을 받은 조건이 있으므로 posterior \\(85/223\\)를 사용한다. |
| 정확히 2개 확률에서 조합 \\(\binom{3}{2}\\)를 빼먹음 | 이항분포 PMF는 \\(\binom{n}{k}p^k(1-p)^{n-k}\\)다. |

## 2. Gradient Descent Update

### 출제 의도

이 문제는 gradient를 직접 구하고, 주어진 step size로 parameter를 한 번 update할 수 있는지 확인한다. 특히 강의 표기처럼 \\(\nabla_\theta f(\theta)\\)를 row vector로 정의했을 때, update에서는 transpose를 붙여 column vector로 맞추는 점이 중요하다.

### 원문 문제 재구성

다음 함수를 생각한다.

$$
f(\theta_1,\theta_2)
=
(\theta_1-1)^2
+2(\theta_2+1)^2
+\theta_1\theta_2
$$

Step size는

$$
\eta=\frac{1}{5}
$$

이고, update rule은 다음과 같다.

$$
\theta^{(k+1)}
=
\theta^{(k)}
-
\eta
\left(
\nabla_\theta f(\theta^{(k)})
\right)^T
$$

먼저 gradient는 다음과 같다.

$$
\nabla_\theta f(\theta)
=
\begin{bmatrix}
2(\theta_1-1)+\theta_2
&
4(\theta_2+1)+\theta_1
\end{bmatrix}
$$

<details>
<summary>2-1. \\(\theta^{(0)}=\begin{bmatrix}0\\0\end{bmatrix}\\)일 때 한 번 update한 결과를 구하라.</summary>

풀이과정:

초기점에서 gradient를 계산한다.

$$
\nabla_\theta f(\theta^{(0)})
=
\begin{bmatrix}
-2 & 4
\end{bmatrix}
$$

Update rule에 대입한다.

$$
\theta^{(1)}
=
\begin{bmatrix}
0\\
0
\end{bmatrix}
-
\frac{1}{5}
\begin{bmatrix}
-2\\
4
\end{bmatrix}
=
\begin{bmatrix}
\frac{2}{5}\\
-\frac{4}{5}
\end{bmatrix}
$$

답변: \\(\theta^{(1)}=\begin{bmatrix}2/5\\-4/5\end{bmatrix}\\)이다.

</details>

<details>
<summary>2-2. \\(\theta^{(0)}=\begin{bmatrix}2\\-1\end{bmatrix}\\)일 때 한 번 update한 결과를 구하라.</summary>

풀이과정:

초기점에서 gradient를 계산한다.

$$
\nabla_\theta f(\theta^{(0)})
=
\begin{bmatrix}
2(2-1)+(-1) & 4(-1+1)+2
\end{bmatrix}
=
\begin{bmatrix}
1 & 2
\end{bmatrix}
$$

Update rule에 대입한다.

$$
\theta^{(1)}
=
\begin{bmatrix}
2\\
-1
\end{bmatrix}
-
\frac{1}{5}
\begin{bmatrix}
1\\
2
\end{bmatrix}
=
\begin{bmatrix}
\frac{9}{5}\\
-\frac{7}{5}
\end{bmatrix}
$$

답변: \\(\theta^{(1)}=\begin{bmatrix}9/5\\-7/5\end{bmatrix}\\)이다.

</details>

### 관련 변형 문제

<details>
<summary>변형 1. 이 함수의 stationary point와 global minimum 여부를 판단하라.</summary>

풀이과정:

Stationary point는 gradient가 0인 지점이다.

$$
2(\theta_1-1)+\theta_2=0
$$

$$
4(\theta_2+1)+\theta_1=0
$$

정리하면

$$
2\theta_1+\theta_2-2=0
$$

$$
\theta_1+4\theta_2+4=0
$$

첫 번째 식에서 \\(\theta_2=2-2\theta_1\\)이고, 이를 두 번째 식에 넣으면

$$
\theta_1+4(2-2\theta_1)+4=0
$$

$$
-7\theta_1+12=0
$$

따라서

$$
\theta_1=\frac{12}{7},
\qquad
\theta_2=-\frac{10}{7}
$$

Hessian은

$$
H=
\begin{bmatrix}
2 & 1\\
1 & 4
\end{bmatrix}
$$

이고, leading principal minors가 \\(2>0\\), \\(\det(H)=7>0\\)이므로 positive definite다. 따라서 함수는 strictly convex이고 stationary point는 global minimum이다.

답변: stationary point는 \\(\left(\frac{12}{7},-\frac{10}{7}\right)^T\\)이고, Hessian이 positive definite이므로 global minimum이다.

</details>

<details>
<summary>변형 2. Newton method를 \\(\theta^{(0)}=\begin{bmatrix}0\\0\end{bmatrix}\\)에서 한 번 적용하면 어디로 가는가?</summary>

풀이과정:

Newton update는

$$
\theta^{(1)}
=
\theta^{(0)}-H^{-1}g_0
$$

이다. 여기서

$$
H=
\begin{bmatrix}
2 & 1\\
1 & 4
\end{bmatrix},
\qquad
g_0=
\begin{bmatrix}
-2\\
4
\end{bmatrix}
$$

이다.

Hessian의 inverse는

$$
H^{-1}
=
\frac{1}{7}
\begin{bmatrix}
4 & -1\\
-1 & 2
\end{bmatrix}
$$

따라서

$$
H^{-1}g_0
=
\frac{1}{7}
\begin{bmatrix}
-12\\
10
\end{bmatrix}
$$

이므로

$$
\theta^{(1)}
=
\begin{bmatrix}
0\\
0
\end{bmatrix}
-
\begin{bmatrix}
-12/7\\
10/7
\end{bmatrix}
=
\begin{bmatrix}
12/7\\
-10/7
\end{bmatrix}
$$

답변: Newton method는 한 번에 \\(\begin{bmatrix}12/7\\-10/7\end{bmatrix}\\)로 이동한다. 이 함수가 2차 convex 함수이기 때문이다.

</details>

### 실수 포인트

| 실수 | 고치는 방법 |
|---|---|
| Gradient 방향으로 더함 | 최소화는 gradient의 반대 방향으로 이동한다. |
| Row vector를 그대로 빼서 차원이 어긋남 | 문제의 update처럼 transpose를 붙여 column vector로 맞춘다. |
| \\(\theta_1\theta_2\\) 미분을 빼먹음 | \\(\partial/\partial\theta_1\\)에서는 \\(\theta_2\\), \\(\partial/\partial\theta_2\\)에서는 \\(\theta_1\\)가 나온다. |
| Step size를 곱하지 않음 | \\(\eta=1/5\\)를 gradient 전체에 곱한다. |

## 3. Convex Function 판정

### 출제 의도

이 문제는 convex의 정의를 정확히 알고 있는지 본다. Convex임을 보일 때는 정의 또는 알려진 부등식을 사용하고, convex가 아님을 보일 때는 정의를 깨는 반례를 제시하면 된다.

Convex 정의는 다음과 같다.

$$
f(\lambda x+(1-\lambda)y)
\le
\lambda f(x)+(1-\lambda)f(y)
$$

$$
0\le\lambda\le 1
$$

<details>
<summary>3-1. \\(f(x)=\lvert x\rvert\\), \\(x\in\mathbb{R}\\)가 convex인지 판단하라.</summary>

풀이과정:

임의의 \\(x,y\in\mathbb{R}\\), \\(0\le\lambda\le 1\\)에 대해

$$
\left\lvert
\lambda x+(1-\lambda)y
\right\rvert
\le
\lvert\lambda x\rvert+\lvert(1-\lambda)y\rvert
$$

이다. \\(\lambda\\), \\(1-\lambda\\)가 0 이상이므로

$$
\lvert\lambda x\rvert+\lvert(1-\lambda)y\rvert
=
\lambda\lvert x\rvert+(1-\lambda)\lvert y\rvert
$$

따라서

$$
f(\lambda x+(1-\lambda)y)
\le
\lambda f(x)+(1-\lambda)f(y)
$$

답변: \\(f(x)=\lvert x\rvert\\)는 convex이다.

</details>

<details>
<summary>3-2. \\(g(x)=\sin x\\), \\(x\in\mathbb{R}\\)가 convex인지 판단하라.</summary>

풀이과정:

Convex가 아님을 보이기 위해 반례를 잡는다.

$$
x=0,
\qquad
y=\pi,
\qquad
\lambda=\frac{1}{2}
$$

왼쪽은

$$
g\left(\frac{\pi}{2}\right)=1
$$

오른쪽은

$$
\frac{1}{2}g(0)+\frac{1}{2}g(\pi)=0
$$

Convex라면 \\(1\le 0\\)이어야 하는데 이는 거짓이다.

답변: \\(g(x)=\sin x\\)는 \\(\mathbb{R}\\) 전체에서 convex가 아니다.

</details>

### 관련 변형 문제

<details>
<summary>변형 1. \\(g(x)=\sin x\\)는 구간 \\([\pi,2\pi]\\)에서 convex인가?</summary>

풀이과정:

1차원에서 두 번 미분 가능한 함수는 두 번째 미분으로 convex를 판단할 수 있다.

$$
g''(x)=-\sin x
$$

구간 \\([\pi,2\pi]\\)에서는 \\(\sin x\le 0\\)이므로

$$
g''(x)=-\sin x\ge 0
$$

따라서 이 구간에서는 convex다.

답변: \\(g(x)=\sin x\\)는 \\([\pi,2\pi]\\)에서 convex이다. Convex 여부는 domain에 따라 달라질 수 있다.

</details>

<details>
<summary>변형 2. 2번의 함수 \\(f(\theta_1,\theta_2)\\)는 convex인가?</summary>

풀이과정:

2번 함수의 Hessian은

$$
H=
\begin{bmatrix}
2 & 1\\
1 & 4
\end{bmatrix}
$$

이다. Leading principal minors는

$$
2>0,
\qquad
\det(H)=2\cdot 4-1\cdot 1=7>0
$$

이므로 Hessian은 positive definite다. 따라서 함수는 strictly convex다.

답변: 2번의 함수는 strictly convex이다.

</details>

### 실수 포인트

| 실수 | 고치는 방법 |
|---|---|
| 그래프 모양만 보고 판단 | 시험 답안에는 정의, 반례, 또는 2차 미분/Hessian 근거를 쓴다. |
| Non-convex 증명에 여러 점을 찾으려 함 | 정의를 깨는 반례 하나면 충분하다. |
| \\(\sin x\\)를 항상 non-convex라고 외움 | Domain에 따라 convex일 수 있다. |
| \\(\lvert x\rvert\\)가 미분 불가능하므로 convex가 아니라고 착각 | Convex는 모든 점에서 미분 가능할 필요가 없다. |

## 4. Polynomial Regression MLE와 예측분포

### 출제 의도

이 문제는 선형회귀를 단순한 직선 fitting이 아니라 basis function을 사용한 확률적 회귀 모델로 이해하고 있는지 묻는다. 핵심은 \\(\phi(x)\\), \\(\Phi\\), Gaussian likelihood, MLE, predictive distribution의 연결이다.

### 원문 문제 재구성

학습 데이터가 다음과 같다.

$$
(x_1,y_1)=(-1,2),
\qquad
(x_2,y_2)=(0,1),
\qquad
(x_3,y_3)=(1,2)
$$

2차 다항식 feature vector를 다음처럼 둔다.

$$
\phi(x)=
\begin{bmatrix}
1\\
x\\
x^2
\end{bmatrix}
$$

확률적 회귀 모델은 다음과 같다.

$$
y_n\mid x_n,\theta
\sim
\mathcal{N}(\phi(x_n)^T\theta,0.2)
$$

여기서 두 번째 parameter \\(0.2\\)는 Gaussian observation variance로 해석한다.

<details>
<summary>4-1. MLE \\(\theta_{\mathrm{ML}}\\)을 구하라.</summary>

풀이과정:

먼저 feature matrix를 만든다.

$$
\Phi
=
\begin{bmatrix}
1 & -1 & 1\\
1 & 0 & 0\\
1 & 1 & 1
\end{bmatrix}
$$

Target vector는

$$
y
=
\begin{bmatrix}
2\\
1\\
2
\end{bmatrix}
$$

Gaussian observation model에서 MLE는 squared error를 최소화한다.

$$
\theta_{\mathrm{ML}}
=
(\Phi^T\Phi)^{-1}\Phi^Ty
$$

이 데이터는 3개의 점을 2차 다항식으로 정확히 지나므로, 연립방정식으로도 풀 수 있다.

$$
\theta_0-\theta_1+\theta_2=2
$$

$$
\theta_0=1
$$

$$
\theta_0+\theta_1+\theta_2=2
$$

두 번째 식에서 \\(\theta_0=1\\)이다. 첫 번째와 세 번째 식을 더하면

$$
2\theta_0+2\theta_2=4
$$

이므로 \\(\theta_2=1\\)이다. 그러면 \\(\theta_1=0\\)이다.

$$
\theta_{\mathrm{ML}}
=
\begin{bmatrix}
1\\
0\\
1
\end{bmatrix}
$$

답변: \\(\theta_{\mathrm{ML}}=\begin{bmatrix}1&0&1\end{bmatrix}^T\\)이다.

</details>

<details>
<summary>4-2. 새로운 입력 \\(x_*=2\\)에 대한 출력 \\(y_*\\)의 예측분포를 구하라.</summary>

풀이과정:

새 입력의 feature vector는

$$
\phi(2)
=
\begin{bmatrix}
1\\
2\\
4
\end{bmatrix}
$$

이다. 예측 평균은

$$
\phi(2)^T\theta_{\mathrm{ML}}
=
\begin{bmatrix}
1 & 2 & 4
\end{bmatrix}
\begin{bmatrix}
1\\
0\\
1
\end{bmatrix}
=
5
$$

Observation variance는 모델에서 \\(0.2\\)로 주어졌다.

$$
y_*\mid x_*=2,\theta_{\mathrm{ML}}
\sim
\mathcal{N}(5,0.2)
$$

답변: 예측분포는 \\(y_*\mid x_*=2,\theta_{\mathrm{ML}}\sim\mathcal{N}(5,0.2)\\)이고, 점 예측은 \\(\hat{y}_*=5\\)이다.

</details>

### 관련 변형 문제

<details>
<summary>변형 1. 같은 데이터에서 \\(x_*=3\\)의 점 예측은 무엇인가?</summary>

풀이과정:

Feature vector는

$$
\phi(3)
=
\begin{bmatrix}
1\\
3\\
9
\end{bmatrix}
$$

이다. \\(\theta_{\mathrm{ML}}=(1,0,1)^T\\)이므로

$$
\hat{y}_*
=
\phi(3)^T\theta_{\mathrm{ML}}
=
1+0+9
=
10
$$

답변: \\(x_*=3\\)에서 점 예측은 \\(10\\)이다.

</details>

<details>
<summary>변형 2. Gaussian prior \\(\theta\sim\mathcal{N}(0,I)\\)를 추가하면 MAP objective는 어떻게 쓰는가?</summary>

풀이과정:

Likelihood는

$$
y_n\mid x_n,\theta
\sim
\mathcal{N}(\phi(x_n)^T\theta,\sigma^2)
$$

이고, 여기서는 \\(\sigma^2=0.2\\)다. Prior는

$$
\theta\sim\mathcal{N}(0,I)
$$

이므로 \\(b^2=1\\)이다. MAP objective는

$$
\theta_{\mathrm{MAP}}
=
\arg\min_\theta
\left[
\frac{1}{2\sigma^2}
\lVert y-\Phi\theta\rVert^2
+
\frac{1}{2b^2}
\lVert\theta\rVert^2
\right]
$$

상수 배율을 정리하면 ridge 형태다.

$$
\theta_{\mathrm{MAP}}
=
\arg\min_\theta
\left[
\lVert y-\Phi\theta\rVert^2
+
\frac{\sigma^2}{b^2}\lVert\theta\rVert^2
\right]
$$

따라서 이 문제에서는

$$
\theta_{\mathrm{MAP}}
=
\arg\min_\theta
\left[
\lVert y-\Phi\theta\rVert^2
+
0.2\lVert\theta\rVert^2
\right]
$$

답변: Gaussian prior를 추가하면 MLE의 squared error objective에 \\(0.2\lVert\theta\rVert^2\\) penalty가 붙은 ridge 형태가 된다.

</details>

### 실수 포인트

| 실수 | 고치는 방법 |
|---|---|
| \\(\phi(x)\\)를 행으로 쓸지 열로 쓸지 혼동 | \\(\phi(x)\\)는 column vector, \\(\phi(x)^T\\)가 design matrix의 row다. |
| \\(\Phi\\) 행렬의 세 번째 열 \\(x^2\\)를 빠뜨림 | 2차 다항식이므로 \\([1,x,x^2]^T\\)를 쓴다. |
| MLE에서 variance \\(0.2\\) 때문에 해가 바뀐다고 착각 | positive constant scaling은 minimizer를 바꾸지 않는다. |
| 예측분포에서 variance를 빼먹음 | 평균뿐 아니라 \\(\mathcal{N}(\text{mean},0.2)\\) 형태까지 써야 한다. |

## 마지막 핵심 정리

| 문제 유형 | 바로 써야 할 식 | 체크 포인트 |
|---|---|---|
| Bayes posterior | \\(P(D\mid T)=P(T\mid D)P(D)/P(T)\\) | 분모 \\(P(T)\\)를 전체 확률 법칙으로 계산 |
| 조건부 이항분포 | \\(X\sim\operatorname{Binomial}(n,P(D\mid T=+))\\) | prior \\(P(D)\\)가 아니라 posterior를 성공확률로 사용 |
| GD update | \\(\theta^+=\theta-\eta(\nabla f(\theta))^T\\) | gradient 부호와 transpose 확인 |
| Convex 증명 | \\(f(\lambda x+(1-\lambda)y)\le\lambda f(x)+(1-\lambda)f(y)\\) | 증명은 정의, 반례는 한 쌍이면 충분 |
| Polynomial MLE | \\(\theta_{\mathrm{ML}}=(\Phi^T\Phi)^{-1}\Phi^Ty\\) | \\(\Phi\\)를 정확히 구성 |
| 예측분포 | \\(y_*\mid x_*,\theta\sim\mathcal{N}(\phi(x_*)^T\theta,\sigma^2)\\) | 평균과 variance를 모두 작성 |

## Study Guide

1. 먼저 원문 문제 1번의 Bayes posterior를 손으로 다시 계산한다. \\(P(T=+)\\)를 직접 구할 수 있으면 이후 기대값과 이항분포 계산은 훨씬 쉽다.
2. 2번은 gradient를 먼저 일반식으로 구한 뒤 초기값을 대입한다. 초기값부터 대입하면 \\(\theta_1\theta_2\\) 미분을 놓치기 쉽다.
3. Convex 문제는 두 가지 답안 패턴을 외운다. Convex임을 보일 때는 정의를 전개하고, non-convex임을 보일 때는 반례를 제시한다.
4. 회귀 문제는 항상 \\(\phi(x)\\), \\(\Phi\\), \\(y\\), \\(\theta\\)의 차원을 먼저 확인한다. 차원이 맞으면 MLE와 예측분포는 거의 자동으로 따라온다.
5. 변형 문제는 시험 직전 확인용이다. 음성 posterior, 적어도 1개 확률, stationary point, Newton update, MAP objective를 다시 풀어보면 기존 exam review의 주요 범위와 연결된다.

## 복습 질문

<details>
<summary>1. Bayes 정리에서 evidence \\(P(T=+)\\)는 왜 필요한가?</summary>

답변: Evidence는 양성 결과가 전체적으로 나타날 확률이며, posterior가 확률분포가 되도록 정규화한다. 이 문제에서는 \\(P(T=+)=P(T=+\mid D)P(D)+P(T=+\mid D^c)P(D^c)\\)로 계산한다.

</details>

<details>
<summary>2. 양성 판정을 받은 여러 부품의 실제 불량 개수를 왜 이항분포로 모델링할 수 있는가?</summary>

답변: 양성 판정을 받은 각 부품이 실제 불량일 확률을 \\(p=P(D\mid T=+)\\)로 보고, 부품들이 서로 독립이라고 가정하기 때문이다. 그러면 실제 불량 개수 \\(X\\)는 \\(\operatorname{Binomial}(n,p)\\)를 따른다.

</details>

<details>
<summary>3. Gradient descent update에서 가장 자주 나는 부호 실수는 무엇인가?</summary>

답변: 최소화 문제인데 gradient 방향으로 더하는 실수다. Gradient는 증가 방향이므로 최소화를 위해서는 \\(\theta^+=\theta-\eta\nabla f(\theta)\\)처럼 반대 방향으로 움직여야 한다.

</details>

<details>
<summary>4. Convex가 아님을 보이는 가장 짧은 방법은 무엇인가?</summary>

답변: Convex 정의를 깨는 반례 하나를 찾으면 된다. 즉, 어떤 \\(x,y,\lambda\\)에 대해 \\(f(\lambda x+(1-\lambda)y)>\lambda f(x)+(1-\lambda)f(y)\\)가 성립하면 convex가 아니다.

</details>

<details>
<summary>5. Polynomial regression에서 \\(\Phi\\) 행렬은 어떻게 만드는가?</summary>

답변: 각 데이터 \\(x_n\\)에 대해 \\(\phi(x_n)^T\\)를 한 행으로 쌓는다. 이 문제의 \\(\phi(x)=[1,x,x^2]^T\\)이므로 \\(x=-1,0,1\\)을 넣어 \\(\Phi=\begin{bmatrix}1&-1&1\\1&0&0\\1&1&1\end{bmatrix}\\)를 만든다.

</details>

<details>
<summary>6. MLE 해를 구한 뒤 예측분포를 쓸 때 빠뜨리면 안 되는 것은 무엇인가?</summary>

답변: 예측 평균뿐 아니라 observation variance를 함께 써야 한다. 이 문제에서는 \\(\phi(2)^T\theta_{\mathrm{ML}}=5\\)이고 variance가 \\(0.2\\)이므로 \\(y_*\mid x_*=2,\theta_{\mathrm{ML}}\sim\mathcal{N}(5,0.2)\\)다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/assignment/machine-learning-basic/machine-learning-basic-final-assignment.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-final-assignment.pdf</a></li>
</ul>
