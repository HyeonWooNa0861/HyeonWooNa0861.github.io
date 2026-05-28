---
layout: default
title: "Lecture 17 Linear Regression"
course: "Machine Learning Basic"
topic: "Linear Regression"
order: 17
---

# Lecture 17 Linear Regression

Source PDF: `machine-learning-basic-lecture-17.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 회귀 문제 | 독립 변수와 종속 변수 사이의 관계를 어떻게 모델링하는가? |
| 2 | Noise model | 관측값에 noise가 있다는 가정은 수식으로 어떻게 들어가는가? |
| 3 | Linear regression | \\(f(x)=\theta^Tx\\)는 어떤 의미의 선형 모델인가? |
| 4 | MLE | Gaussian noise 가정에서 왜 squared error가 나오는가? |
| 5 | Closed-form solution | \\(\theta_{\mathrm{ML}}\\)은 어떤 normal equation으로 구하는가? |
| 6 | Basis expansion | \\(\phi(x)\\)를 쓰면 선형 회귀가 어떻게 비선형 회귀로 확장되는가? |
| 7 | RMSE | 학습 objective와 평가 metric은 어떻게 다른가? |
| 8 | Overfitting | 다항식 차수가 커질 때 왜 training error와 test error가 갈라지는가? |
| 9 | MAP | prior를 넣으면 큰 parameter를 어떻게 억제하는가? |
| 10 | MLE vs MAP | MAP 추정은 ridge regression과 어떻게 연결되는가? |

17강은 선형 회귀를 단순한 최소제곱 공식으로 외우는 데서 멈추지 않고, 확률 모델에서 MLE로 유도한 뒤 MAP로 regularization까지 연결한다. 핵심 흐름은 Gaussian observation noise에서 squared error가 나오고, Gaussian prior에서 L2 penalty가 나온다는 것이다.

## 1. 회귀란?

회귀(regression)는 하나의 종속 변수 \\(y\\)와 하나 이상의 독립 변수 \\(x\\) 사이의 관계를 수학적 모델로 추정하고 예측하는 분석 기법이다.

| 용어 | 의미 |
|---|---|
| 독립 변수 \\(x\\) | 원인 값, 입력 feature |
| 종속 변수 \\(y\\) | 결과 값, 관측 target |
| 회귀 모델 | \\(x\\)를 이용해 \\(y\\)를 예측하는 함수 또는 확률분포 |

우리가 원하는 것은 training data를 지나가는 예쁜 곡선을 그리는 것만이 아니다. 관측하지 않은 새 입력 \\(x'\\)에 대해 \\(y'\\)를 잘 예측하는 함수 \\(f\\)를 찾는 것이 목표다.

## 2. 문제 구성과 Noise

회귀 문제에서는 관측값에 noise가 포함되어 있다고 본다. 즉, 실제 관측 \\(y\\)는 함수값 \\(f(x)\\)에 noise \\(\epsilon\\)이 더해진 값이다.

$$
y=f(x)+\epsilon
$$

강의에서는 이 noise가 평균 0, 분산 \\(\sigma^2\\)인 Gaussian distribution을 따른다고 가정한다.

$$
\epsilon\sim\mathcal{N}(0,\sigma^2)
$$

이 가정은 "같은 \\(x\\)를 관측해도 측정 오차, 환경 차이, 설명하지 못한 요인 때문에 \\(y\\)가 조금씩 흔들릴 수 있다"는 뜻이다.

선형 회귀는 함수 \\(f\\)를 parameter \\(\theta\\)에 대해 선형인 형태로 둔다.

$$
f(x)=\theta^T x
$$

더 일반적으로 basis function \\(\phi(x)\\)를 쓰면 다음처럼 표현할 수 있다.

$$
f(x)=\theta^T\phi(x)
$$

여기서 중요한 점은 \\(x\\)에 대해서는 비선형일 수 있어도 \\(\theta\\)에 대해서는 선형이라는 것이다.

## 3. 학습 데이터와 확률 모델

학습 데이터는 다음처럼 주어진다.

$$
\mathcal{D}
=
\{(x_1,y_1),\ldots,(x_N,y_N)\}
$$

선형 회귀의 Gaussian observation model은 각 sample에 대해 다음과 같이 쓸 수 있다.

$$
p(y_n\mid x_n,\theta)
=
\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

데이터가 i.i.d.라고 가정하면 전체 likelihood는 sample별 likelihood의 곱이 된다.

$$
P(Y\mid X,\theta)
=
P(y_1,\ldots,y_N\mid x_1,\ldots,x_N,\theta)
$$

$$
P(Y\mid X,\theta)
=
\prod_{n=1}^{N}
P(y_n\mid x_n,\theta)
=
\prod_{n=1}^{N}
\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

MLE는 이 likelihood를 최대화하는 parameter를 찾는다.

$$
\theta_{\mathrm{ML}}
=
\arg\max_{\theta}
P(Y\mid X,\theta)
$$

찾은 \\(\theta^*\\)를 예측에 사용하면 새 입력 \\(x'\\)에 대한 예측 분포는 다음과 같다.

$$
P(y'\mid x',\theta^*)
=
\mathcal{N}(y'\mid {x'}^T\theta^*,\sigma^2)
$$

## 4. 선형 회귀 MLE

MLE는 likelihood 최대화 문제지만, 실제 계산에서는 negative log-likelihood를 최소화하는 문제로 바꾼다.

$$
\theta_{\mathrm{ML}}
=
\arg\min_{\theta}
-\log P(Y\mid X,\theta)
$$

i.i.d. 가정을 사용하면 곱은 log 안에서 합으로 바뀐다.

$$
\theta_{\mathrm{ML}}
=
\arg\min_{\theta}
-
\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

Gaussian density의 log를 쓰면 다음 항이 나온다.

$$
\log p(y_n\mid x_n,\theta)
=
-
\frac{1}{2\sigma^2}
(y_n-x_n^T\theta)^2
+\mathrm{const}
$$

따라서 negative log-likelihood는 squared error 합과 같은 형태가 된다.

$$
L(\theta)
=
-\log P(Y\mid X,\theta)
=
\frac{1}{2\sigma^2}
\sum_{n=1}^{N}
(y_n-x_n^T\theta)^2
+\mathrm{const}
$$

즉, Gaussian noise를 가정한 선형 회귀의 MLE는 squared error를 최소화하는 문제와 같다.

## 5. 행렬 형태의 NLL

각 sample을 행으로 쌓아 feature matrix를 만들자.

$$
X=
\begin{bmatrix}
x_1^T\\
\vdots\\
x_N^T
\end{bmatrix},
\qquad
y=
\begin{bmatrix}
y_1\\
\vdots\\
y_N
\end{bmatrix}
$$

그러면 전체 예측값은 \\(X\theta\\)이고 residual vector는 다음과 같다.

$$
y-X\theta
$$

NLL은 행렬 형태로 다음처럼 쓸 수 있다.

$$
L(\theta)
=
\frac{1}{2\sigma^2}
(y-X\theta)^T(y-X\theta)
+\mathrm{const}
$$

또는 norm으로 쓰면

$$
L(\theta)
=
\frac{1}{2\sigma^2}
\lVert y-X\theta\rVert^2
+\mathrm{const}
$$

상수항과 양의 배율 \\(\frac{1}{2\sigma^2}\\)은 minimizer를 바꾸지 않으므로, 결국 다음 문제와 같은 해를 가진다.

$$
\theta_{\mathrm{ML}}
=
\arg\min_{\theta}
\lVert y-X\theta\rVert^2
$$

## 6. 최적해 구하기

NLL에서 상수와 양의 배율을 제외하고 squared error만 생각하면 다음 objective를 최소화하면 된다.

$$
J(\theta)
=
(y-X\theta)^T(y-X\theta)
$$

전개하면

$$
J(\theta)
=
y^Ty
-2y^TX\theta
+\theta^TX^TX\theta
$$

gradient를 0으로 두면 normal equation이 나온다.

$$
\frac{dJ}{d\theta}=0
\quad\Longleftrightarrow\quad
X^TX\theta=X^Ty
$$

\\(X^TX\\)가 invertible이면 closed-form solution은 다음과 같다.

$$
\theta_{\mathrm{ML}}
=
(X^TX)^{-1}X^Ty
$$

이 식은 선형 회귀의 대표적인 normal equation이다. 다만 \\(X^TX\\)가 invertible이려면 \\(X\\)의 column들이 충분히 독립적이어야 한다.

## 7. 선형 회귀를 넘어서: Basis Function

선형 회귀는 \\(x\\) 자체에 대해서만 직선을 그리는 모델로 끝나지 않는다. 입력을 basis function \\(\phi(x)\\)로 변환하면 \\(x\\)에 대해서는 비선형인 함수를 만들 수 있다.

$$
p(y\mid x,\theta)
=
\mathcal{N}(y\mid\phi(x)^T\theta,\sigma^2)
$$

관측 모델은 다음처럼 쓸 수 있다.

$$
y
=
\phi(x)^T\theta+\epsilon
=
\sum_{k=1}^{K}
\theta_k\phi_k(x)
+\epsilon
$$

이때 모델은 \\(\phi_k(x)\\) 때문에 \\(x\\)에 대해서는 비선형일 수 있지만, parameter \\(\theta_k\\)에 대해서는 여전히 선형이다. 그래서 basis expansion 후에도 같은 선형 회귀 공식이 적용된다.

## 8. 다항식으로의 확장

다항 회귀에서는 다음 basis vector를 사용할 수 있다.

$$
\phi(x)
=
\begin{bmatrix}
1\\
x\\
x^2\\
\vdots\\
x^{K-1}
\end{bmatrix}
\in
\mathbb{R}^{K}
$$

모든 sample에 대해 \\(\phi(x_n)^T\\)를 행으로 쌓으면 feature matrix \\(\Phi\\)가 된다.

$$
\Phi
=
\begin{bmatrix}
\phi(x_1)^T\\
\vdots\\
\phi(x_N)^T
\end{bmatrix}
\in
\mathbb{R}^{N\times K}
$$

그러면 NLL은 다음처럼 바뀐다.

$$
-\log p(Y\mid X,\theta)
=
\frac{1}{2\sigma^2}
(y-\Phi\theta)^T(y-\Phi\theta)
+\mathrm{const}
$$

MLE 해는

$$
\theta_{\mathrm{ML}}
=
(\Phi^T\Phi)^{-1}\Phi^T y
$$

이다. 단, \\(\Phi^T\Phi\\)가 invertible이려면 \\(\Phi\\)가 full column rank여야 한다.

$$
\operatorname{rank}(\Phi)=K
$$

즉, feature 수 \\(K\\)가 너무 많거나 feature column들이 선형 종속이면 closed-form inverse가 존재하지 않을 수 있다.

## 9. 평가: MSE와 RMSE

학습할 때는 평균 squared error를 최소화하는 형태로 objective를 둔다.

$$
\frac{1}{N}
\sum_{n=1}^{N}
\left(
y_n-\phi(x_n)^T\theta
\right)^2
$$

평가할 때는 Root Mean Square Error(RMSE)를 자주 사용한다.

$$
\mathrm{RMSE}
=
\sqrt{
\frac{1}{N}
\lVert y-\Phi\theta\rVert^2
}
$$

sample별로 풀어 쓰면 다음과 같다.

$$
\mathrm{RMSE}
=
\sqrt{
\frac{1}{N}
\sum_{n=1}^{N}
\left(
y_n-\phi(x_n)^T\theta
\right)^2
}
$$

MSE는 squared error의 평균이고, RMSE는 그 제곱근이다. RMSE는 단위가 \\(y\\)와 같아 해석하기 쉽다.

## 10. 과적합

다항식 차수가 커지면 모델은 training data를 매우 유연하게 맞출 수 있다. 그러나 너무 높은 차수는 training data의 noise까지 따라가면서 test error를 크게 만들 수 있다.

강의 슬라이드의 그림은 다항식 차수 \\(M\\)이 커질수록 training error는 계속 낮아질 수 있지만, test error는 어느 순간부터 급격히 증가할 수 있음을 보여준다.

| 모델 복잡도 | 현상 |
|---|---|
| 너무 낮음 | underfitting, 데이터의 패턴을 충분히 표현하지 못함 |
| 적절함 | training과 test 모두에서 안정적 |
| 너무 높음 | overfitting, training noise까지 따라감 |

다항식 feature 수가 \\(K\\)일 때, 보통 \\(K\le N\\)이고 \\(\Phi\\)가 full column rank이면 unique solution을 기대할 수 있다. 반대로 feature 수가 sample 수보다 많거나 rank가 부족하면 \\(\Phi^T\Phi\\)가 singular해지고, 유일해가 존재하지 않을 수 있다.

이 경우에는 선형 방정식을 푸는 다른 방법이 필요하고, 해가 무한히 많아질 수도 있다.

## 11. MAP로 과적합 줄이기

과적합이 일어나는 경우에는 parameter 값이 매우 커지는 현상이 자주 나타난다. 큰 계수는 다항식 곡선을 심하게 흔들리게 만들 수 있기 때문이다.

MAP는 parameter prior를 넣어 큰 parameter에 낮은 확률을 부여한다.

$$
p(\theta\mid X,Y)
=
\frac{
P(Y\mid X,\theta)p(\theta)
}{
p(Y\mid X)
}
$$

log를 취하면 다음처럼 likelihood와 prior가 더해진다.

$$
\log p(\theta\mid X,Y)
=
\log p(Y\mid X,\theta)
+\log p(\theta)
+\mathrm{const}
$$

MAP는 posterior를 최대화하는 parameter를 고른다. negative log 관점에서는 다음을 최소화한다.

$$
\theta_{\mathrm{MAP}}
\in
\arg\min_{\theta}
\left[
-\log p(Y\mid X,\theta)
-\log p(\theta)
\right]
$$

즉, MLE objective에 prior에서 온 penalty가 추가된다.

## 12. Gaussian Prior와 MAP 해

강의에서는 Gaussian prior를 둔다.

$$
p(\theta)
=
\mathcal{N}(0,b^2I)
$$

그러면 negative log posterior는 다음 형태가 된다.

$$
-\log p(\theta\mid X,Y)
=
\frac{1}{2\sigma^2}
(y-\Phi\theta)^T(y-\Phi\theta)
+
\frac{1}{2b^2}
\theta^T\theta
+\mathrm{const}
$$

두 번째 항 \\(\frac{1}{2b^2}\theta^T\theta\\)가 큰 parameter를 억제하는 L2 penalty다.

gradient를 0으로 두면

$$
\theta^T
\left(
\Phi^T\Phi+\frac{\sigma^2}{b^2}I
\right)
=
y^T\Phi
$$

이고, column vector 형태의 해는 다음과 같다.

$$
\theta_{\mathrm{MAP}}
=
\left(
\Phi^T\Phi+\frac{\sigma^2}{b^2}I
\right)^{-1}
\Phi^Ty
$$

여기서

$$
\lambda=\frac{\sigma^2}{b^2}
$$

라고 두면

$$
\theta_{\mathrm{MAP}}
=
(\Phi^T\Phi+\lambda I)^{-1}\Phi^Ty
$$

이 식은 ridge regression의 해와 같은 형태다. \\(\lambda I\\)가 더해지면 \\(\Phi^T\Phi\\)가 singular하거나 condition이 나쁜 경우에도 더 안정적인 해를 얻을 수 있다.

## 13. MLE와 MAP 차이

MLE와 MAP의 차이는 prior를 쓰는지 여부다.

| 구분 | MLE | MAP |
|---|---|---|
| 목적 | likelihood 최대화 | posterior 최대화 |
| 사용하는 정보 | 데이터 likelihood | likelihood + prior |
| objective | NLL | NLL + prior penalty |
| 선형 회귀 해 | \\((\Phi^T\Phi)^{-1}\Phi^Ty\\) | \\((\Phi^T\Phi+\lambda I)^{-1}\Phi^Ty\\) |
| 과적합 대응 | 직접적인 억제 없음 | 큰 parameter를 penalty로 억제 |

MLE는 training data를 가장 그럴듯하게 만드는 parameter를 찾는다. 데이터가 충분하고 모델이 적절하면 강력하지만, 복잡한 feature를 많이 쓰면 overfitting될 수 있다.

MAP는 prior를 통해 parameter가 너무 커지는 것을 막는다. Gaussian prior를 쓰면 결과적으로 L2 regularization과 같은 역할을 하며, 더 부드러운 곡선을 선택하는 경향이 생긴다.

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| 회귀 | \\(x\\)로 연속적인 \\(y\\)를 예측하는 문제 |
| Gaussian noise | \\(y=f(x)+\epsilon\\), \\(\epsilon\sim\mathcal{N}(0,\sigma^2)\\) |
| 선형 회귀 | \\(f(x)=\theta^Tx\\) 또는 \\(f(x)=\theta^T\phi(x)\\) |
| MLE | Gaussian noise에서 squared error 최소화로 연결 |
| Normal equation | \\(\theta_{\mathrm{ML}}=(X^TX)^{-1}X^Ty\\) |
| 다항 회귀 | \\(\phi(x)=[1,x,x^2,\ldots,x^{K-1}]^T\\)로 feature 확장 |
| RMSE | MSE의 제곱근, \\(y\\)와 같은 단위 |
| Overfitting | 높은 차수의 다항식이 training noise까지 따라가는 현상 |
| MAP | likelihood에 prior를 곱해 posterior를 최대화 |
| Gaussian prior | L2 penalty를 만들고 ridge regression 해로 연결 |

## Study Guide

먼저 회귀 문제를 \\(y=f(x)+\epsilon\\)으로 보는 관점을 잡아야 한다. 그다음 Gaussian noise 가정에서 likelihood를 쓰고, negative log를 취하면 squared error가 나온다는 흐름을 이해한다.

두 번째로 normal equation을 외우기 전에 행렬 모양을 확인해야 한다. \\(X\\) 또는 \\(\Phi\\)는 sample을 행으로 쌓은 matrix이고, \\(y\\)는 target vector다. 따라서 \\(\Phi^T\Phi\\)는 parameter 차원 \\(K\times K\\) matrix가 된다.

마지막으로 MLE와 MAP의 차이를 regularization 관점으로 연결한다. Gaussian prior는 큰 \\(\theta\\)에 낮은 prior probability를 주고, negative log를 취하면 \\(\theta^T\theta\\) penalty가 된다.

| 시험 대비 포인트 | 확인할 내용 |
|---|---|
| Gaussian noise에서 MLE | NLL이 squared error로 바뀌는 이유 |
| Closed-form solution | \\((X^TX)^{-1}X^Ty\\) 또는 \\((\Phi^T\Phi)^{-1}\Phi^Ty\\) |
| Rank condition | \\(\Phi^T\Phi\\)가 invertible하려면 \\(\operatorname{rank}(\Phi)=K\\) |
| RMSE | MSE와 RMSE의 차이와 해석 |
| Overfitting | 차수가 커질수록 training error와 test error가 다르게 움직이는 이유 |
| MAP | prior의 negative log가 regularization penalty가 되는 과정 |

## 복습 질문

<details>
<summary>1. Gaussian noise를 가정하면 선형 회귀 MLE가 왜 squared error 최소화가 되는가?</summary>

답변: \\(p(y_n\mid x_n,\theta)=\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)\\)라고 두면 log likelihood 안에 \\(-(y_n-x_n^T\theta)^2/(2\sigma^2)\\)가 생긴다. likelihood를 최대화하는 것은 negative log-likelihood를 최소화하는 것과 같고, 상수항을 제외하면 squared error 합을 최소화하는 문제가 된다.

</details>

<details>
<summary>2. Normal equation \\(X^TX\theta=X^Ty\\)는 어디서 나오는가?</summary>

답변: squared error \\(J(\theta)=(y-X\theta)^T(y-X\theta)\\)를 \\(\theta\\)에 대해 미분하고 gradient를 0으로 두면 나온다. \\(X^TX\\)가 invertible이면 \\(\theta_{\mathrm{ML}}=(X^TX)^{-1}X^Ty\\)가 된다.

</details>

<details>
<summary>3. \\(f(x)=\theta^T\phi(x)\\)가 비선형 회귀로 확장될 수 있는 이유는?</summary>

답변: \\(\phi(x)\\)가 \\([1,x,x^2,\ldots]^T\\)처럼 비선형 feature를 만들면 모델은 원래 입력 \\(x\\)에 대해 곡선을 표현할 수 있다. 하지만 parameter \\(\theta\\)에 대해서는 여전히 선형이므로 선형 회귀의 MLE 공식을 그대로 사용할 수 있다.

</details>

<details>
<summary>4. \\(\Phi^T\Phi\\)가 invertible하려면 어떤 조건이 필요한가?</summary>

답변: feature matrix \\(\Phi\\in\mathbb{R}^{N\times K}\\)가 full column rank여야 한다. 즉, \\(\operatorname{rank}(\Phi)=K\\)가 되어야 한다. feature 수가 너무 많거나 column들이 선형 종속이면 \\(\Phi^T\Phi\\)가 singular해져 inverse가 존재하지 않을 수 있다.

</details>

<details>
<summary>5. MSE와 RMSE의 차이는 무엇인가?</summary>

답변: MSE는 squared error의 평균이고, RMSE는 MSE의 제곱근이다. RMSE는 원래 target \\(y\\)와 같은 단위를 가지므로 예측 오차를 해석하기 더 쉽다.

</details>

<details>
<summary>6. 다항식 차수가 너무 커지면 왜 과적합이 발생할 수 있는가?</summary>

답변: 높은 차수의 다항식은 매우 복잡한 곡선을 만들 수 있어 training data의 noise까지 따라갈 수 있다. 그 결과 training error는 낮아지지만 unseen data에 대한 test error는 커질 수 있다.

</details>

<details>
<summary>7. Gaussian prior가 L2 regularization으로 이어지는 이유는?</summary>

답변: \\(p(\theta)=\mathcal{N}(0,b^2I)\\)이면 \\(-\log p(\theta)\\)가 \\(\theta^T\theta/(2b^2)\\)에 비례한다. MAP objective는 NLL에 \\(-\log p(\theta)\\)를 더한 형태이므로, 결과적으로 L2 penalty가 추가된다.

</details>

<details>
<summary>8. MLE와 MAP의 가장 중요한 차이는 무엇인가?</summary>

답변: MLE는 데이터 likelihood만 최대화한다. MAP는 likelihood에 parameter prior를 곱한 posterior를 최대화한다. 그래서 MAP는 데이터 적합도뿐 아니라 parameter가 prior 관점에서 얼마나 그럴듯한지도 함께 본다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-17.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-17.pdf</a></li>
</ul>
