---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
title: "Linear and Logistic Regression"
course: "AIX"
topic: "Linear and Logistic Regression"
order: 1
major_topic: "Artificial Intelligence"
keywords:
  - "Linear Regression"
  - "Logistic Regression"
  - "Gradient Descent"
  - "Feature Engineering"
  - "Softmax"
---

# Linear and Logistic Regression

Source PDF: `1st_Regression.pdf`

> **핵심:** **residual은 무엇인가** 실제값과 예측값의 차이. **squared error를 쓰는 이유는** 오차 상쇄를 막고 큰 오차를 더 강하게 벌하기 위해.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 지도학습 문제 | 입력 $$x$$와 정답 $$y$$ 사이의 관계를 어떻게 학습하는가? |
| 2 | 선형 모델 | $$\mathrm{score}=w^Tx+b$$는 무엇을 표현하는가? |
| 3 | 잔차와 손실 | residual과 squared error는 왜 학습 목표가 되는가? |
| 4 | 최적화 | closed-form 해와 gradient descent는 어떻게 다른가? |
| 5 | Feature engineering | 선형 모델의 표현력을 어떻게 확장하는가? |
| 6 | Logistic regression | 분류 문제에서 score를 확률로 바꾸는 이유는 무엇인가? |
| 7 | Softmax와 perceptron | 이진 분류를 다중 분류와 신경망으로 어떻게 확장하는가? |

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.4-5, p.9 | $$w^Tx+b$$, residual, squared-error objective | 기호·단위와 residual/loss 구분을 명시했다. |
| p.10-11 | 정상방정식 해와 gradient update | 정상방정식은 가역성 가정까지 정확히 유도했고, 하강 방향은 1차 Taylor **근사**로 보충했다. |
| p.13 | polynomial feature expansion | feature map 표기로 다시 쓴 정의다. |
| p.18-21 | normal CDF, sigmoid, BCE | BCE가 Bernoulli negative log-likelihood가 되는 과정을 보충했다. |
| p.23-25 | softmax와 cross-entropy | 확률 정규화와 one-hot likelihood 유도를 보충했다. |

페이지에 없는 pseudo-inverse·수치 안정화·gradient 계산은 슬라이드 식의 성립 조건과 구현상 실패 지점을 설명하기 위한 보충이다.

## 1. 지도학습과 데이터

지도학습에서는 데이터가 입력 feature $$x$$와 정답 target $$y$$의 쌍으로 주어진다. 모델의 목표는 훈련 데이터에만 맞는 함수를 외우는 것이 아니라, 아직 보지 못한 입력에 대해서도 적절한 $$y$$를 예측하는 함수 $$f(x)$$를 찾는 것이다.

$$
\mathcal{D} = \{(x_1,y_1),(x_2,y_2),\ldots,(x_n,y_n)\}
$$

$$
f(x) \to \hat{y}
$$

이 관점에서 regression은 연속값을 예측하고, classification은 class 또는 class probability를 예측한다.

## 2. 선형 모델

선형 회귀의 기본 형태는 입력 feature의 가중합이다.

$$
\mathrm{score} = w^Tx + b
$$

$$w$$는 각 feature가 예측에 얼마나 영향을 주는지를 나타내고, $$b$$는 전체 기준점을 이동시키는 bias다. 2차원에서는 직선, 고차원에서는 hyperplane으로 볼 수 있다.

| 구성 요소 | 의미 |
|---|---|
| $$x$$ | 입력 feature vector |
| $$w$$ | feature별 가중치 |
| $$b$$ | bias 또는 intercept |
| $$\mathrm{score}$$ | 모델이 만든 선형 예측값 |

분류 문제에서도 같은 선형 score를 사용할 수 있다. 다만 score 자체를 최종 답으로 쓰지 않고, 뒤에서 sigmoid나 softmax 같은 link function을 붙인다.

### 수식의 가정과 기호

아래 유도에서는 $$X\in\mathbb{R}^{n\times d}$$, $$w\in\mathbb{R}^{d}$$, $$y\in\mathbb{R}^{n}$$이고 각 행이 한 sample이라고 둔다. Bias는 $$X$$에 값이 1인 열을 추가해 $$w$$에 포함할 수 있다. Feature가 정규화된 수치라면 기호는 무차원으로 취급할 수 있지만, 물리량을 그대로 쓰면 $$w_j$$의 단위는 `target 단위 / feature j 단위`, $$b$$와 예측값의 단위는 target과 같다.

## 3. Residual과 손실 함수

선형 회귀에서 residual은 실제값과 예측값의 차이다.

$$
\mathrm{residual} = y - \hat{y}
$$

단순 residual을 그대로 더하면 양수와 음수가 상쇄될 수 있다. 그래서 보통 residual을 제곱하여 오차 크기를 양수로 만들고, 큰 오차에 더 큰 penalty를 준다.

$$
L(w,b) = \sum_i (y_i-\hat{y}_i)^2
$$

| 손실 형태 | 특징 |
|---|---|
| residual 합 | 부호가 달라 상쇄될 수 있다. |
| absolute error | 오차 크기를 직접 반영하지만 미분이 까다로운 지점이 있다. |
| squared error | 미분이 쉽고 큰 오차를 강하게 벌한다. |

학습은 손실 함수가 작아지도록 $$w$$, $$b$$를 고르는 과정이다.

## 4. Closed-form과 Gradient Descent

선형 회귀는 특정 조건에서 pseudo-inverse를 이용해 한 번에 최적해를 구할 수 있다.

$$
w^\ast = (X^TX)^{-1}X^Ty
$$

이 식은 항상 쓸 수 있는 정의가 아니라, squared loss의 **정확한 정상방정식 해**다. 유도 편의를 위해 $$1/2$$를 붙인 목적함수를 두면 다음과 같다.

$$
L(w)=\frac{1}{2}\lVert Xw-y\rVert_2^2
$$

1. $$L(w)=\frac12(Xw-y)^T(Xw-y)$$로 전개한다.
2. $$w$$로 미분하면 $$\nabla_wL=X^T(Xw-y)$$다.
3. 최소점에서 gradient를 0으로 두면 $$X^TXw=X^Ty$$라는 normal equation을 얻는다.
4. $$X^TX$$가 가역이면 양변에 $$(X^TX)^{-1}$$을 곱해 $$w^\ast=(X^TX)^{-1}X^Ty$$를 얻는다.

$$X$$의 열이 선형 종속이면 $$X^TX$$가 역행렬을 갖지 않으므로 Moore-Penrose pseudo-inverse $$w^\ast=X^+y$$ 또는 regularization을 사용한다. 실제 구현에서는 수치 불안정을 줄이기 위해 역행렬을 직접 계산하기보다 QR·SVD나 선형시스템 풀이를 사용한다.

반대로 gradient descent는 손실의 기울기를 따라 조금씩 parameter를 갱신한다.

$$
w \leftarrow w - \eta\frac{\partial L}{\partial w}
$$

왜 빼는지는 1차 Taylor 근사로 확인할 수 있다.

$$
L(w+\Delta w)\approx L(w)+\nabla L(w)^T\Delta w
$$

작은 양수 $$\eta$$에 대해 $$\Delta w=-\eta\nabla L(w)$$로 두면 1차 변화량은 $$-\eta\lVert\nabla L(w)\rVert_2^2\le 0$$가 된다. 따라서 충분히 작은 step에서는 loss가 감소한다. 이는 **국소 근사**이므로 $$\eta$$가 너무 크거나 함수가 매끄럽지 않은 지점에서는 실제 loss가 증가할 수 있다. 여기서 $$\eta$$는 learning rate이며 parameter와 같은 단위를 만들도록 gradient의 역단위를 보정한다.

| 방식 | 장점 | 한계 |
|---|---|---|
| Closed-form | 해석적으로 명확하고 반복 학습이 필요 없다. | 큰 행렬 계산이 부담스럽다. |
| Gradient descent | 대규모 모델과 딥러닝에 자연스럽게 확장된다. | learning rate와 반복 횟수 설정이 필요하다. |

딥러닝에서 말하는 training은 대부분 gradient 기반 최적화로 이해할 수 있다.

## 5. Feature Engineering과 표현력

선형 모델은 입력이 그대로일 때 직선 또는 평면 형태만 표현한다. 데이터가 곡선 패턴을 가진다면 단순 선형 모델은 underfitting이 될 수 있다.

이때 원래 feature를 다항식, 상호작용항, 도메인 feature 등으로 바꾸면 선형 모델도 더 복잡한 함수를 표현할 수 있다.

```text
raw x -> feature map phi(x) -> linear model
```

예를 들어 $$x$$, $$x^2$$, $$x^3$$ 같은 feature를 추가하면 모델은 parameter에 대해서는 여전히 선형이지만, 원래 입력 $$x$$에 대해서는 비선형 곡선을 표현할 수 있다.

$$
\hat y=\sum_{j=0}^{M}w_jx^j=w^T\phi(x),
\qquad
\phi(x)=[1,x,x^2,\ldots,x^M]^T
$$

이 식은 **feature map의 정의**다. $$x$$에는 비선형이지만 $$w_j$$에는 선형이므로 같은 least-squares 유도를 적용할 수 있다. 단, 큰 차수에서는 feature scale과 다중공선성 때문에 수치적으로 불안정하고 overfitting이 커질 수 있다.

다만 feature를 너무 많이 만들면 훈련 데이터에는 잘 맞지만 새 데이터에는 약한 overfitting이 생긴다.

## 6. Logistic Regression

분류에서는 예측값을 class probability로 해석하고 싶다. 하지만 선형 score는 음수나 1보다 큰 값이 될 수 있어 확률로 바로 쓸 수 없다.

Logistic regression은 선형 score를 sigmoid 함수에 통과시켜 $$0$$과 $$1$$ 사이의 확률로 만든다.

강의에는 확률 link의 역사적 비교로 표준정규 CDF인 probit도 등장한다.

$$
\Phi(z)=\frac{1}{\sqrt{2\pi}}\int_{-\infty}^{z}e^{-t^2/2}\,dt
$$

$$t$$와 $$z$$는 표준화된 무차원 score다. $$\Phi$$는 **정의**이며 elementary function만으로 닫힌꼴 적분값을 갖지 않는다. Logistic regression은 계산과 미분이 간단한 sigmoid를 link로 사용한다.

$$
z = w^Tx + b
$$

$$
p = \sigma(z) = \frac{1}{1+\exp(-z)}
$$

| 값 | 의미 |
|---|---|
| $$z$$ | 선형 score |
| $$p$$ | $$P(y=1\mid x)$$ |
| $$p \ge 0.5$$ | class 1로 분류 |
| $$p < 0.5$$ | class 0으로 분류 |

Logistic regression의 decision boundary는 여전히 $$w^Tx + b = 0$$인 선형 경계다. 달라지는 점은 score를 확률로 해석하고, classification에 맞는 손실 함수를 사용한다는 것이다.

## 7. Binary Cross-Entropy

Logistic regression은 관측된 label이 가장 그럴듯해지도록 parameter를 고른다. 이를 negative log-likelihood 관점으로 쓰면 binary cross-entropy가 된다.

$$
L = -\left[y\log p + (1-y)\log(1-p)\right]
$$

이 식은 Bernoulli negative log-likelihood에서 정확히 나온다. $$y\in\{0,1\}$$, $$0<p<1$$이라고 두면 한 sample의 likelihood는

$$
P(y\mid x)=p^y(1-p)^{1-y}
$$

이고, 곱을 합으로 바꾸기 위해 음의 로그를 취하면

$$
-\log P(y\mid x)=-y\log p-(1-y)\log(1-p)=L
$$

가 된다. 또한 $$p=\sigma(z)$$, $$\frac{dp}{dz}=p(1-p)$$를 대입하면

$$
\frac{\partial L}{\partial z}
=\left(-\frac{y}{p}+\frac{1-y}{1-p}\right)p(1-p)
=p-y
$$

로 단순해진다. 따라서 잘못된 확률과 정답의 차이가 linear score로 바로 역전파된다. $$p=0$$ 또는 $$1$$에서는 로그가 발산하므로 구현은 보통 logit 기반의 수치적으로 안정한 BCE를 사용한다.

## 8. Softmax와 Perceptron으로의 연결

Class가 3개 이상이면 각 class마다 score를 만들고 softmax로 확률 벡터를 만든다.

$$
z = Wx + b
$$

$$
p_i = \frac{\exp(z_i)}{\sum_j \exp(z_j)}
$$

Softmax는 **확률분포의 정의**이며 $$z_i$$는 class $$i$$의 무차원 logit이다. 모든 항이 양수이고

$$
\sum_i p_i
=\frac{\sum_i e^{z_i}}{\sum_j e^{z_j}}
=1
$$

이므로 정상화된 categorical distribution이 된다. One-hot label $$y_i$$에 대한 multiclass cross-entropy는 Bernoulli와 같은 negative log-likelihood 원리로

$$
L=-\sum_i y_i\log p_i=-\log p_c
$$

가 된다. 여기서 $$c$$는 정답 class다. 모든 logit에 같은 상수를 더해도 확률은 같지만, 매우 큰 logit은 overflow를 만들 수 있으므로 계산할 때 $$\max_j z_j$$를 빼는 log-sum-exp 안정화를 사용한다.

Perceptron은 선형 score 뒤에 step function을 붙인 초기 신경망 단위로 볼 수 있다. Logistic regression은 step function 대신 sigmoid를 사용하여 미분 가능한 확률 모델로 만든다. 이후 MLP는 이런 단위를 여러 층으로 쌓고 비선형성을 추가해 표현력을 확장한다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| residual은 무엇인가? | 실제값과 예측값의 차이 |
| squared error를 쓰는 이유는? | 오차 상쇄를 막고 큰 오차를 더 강하게 벌하기 위해 |
| closed-form과 gradient descent의 차이는? | 한 번의 행렬 계산 vs 반복적인 기울기 기반 갱신 |
| logistic regression이 확률을 만드는 방식은? | 선형 score를 sigmoid에 통과시킨다. |
| softmax는 왜 필요한가? | 다중 class score를 확률 분포로 바꾸기 위해 |

## Study Guide

선형 회귀에서는 예측값 → residual → squared error 순으로 손계산하고, closed-form 해와 gradient descent가 같은 목적함수를 다른 방식으로 푼다는 점을 비교한다. 분류로 넘어가면 linear score 자체와 sigmoid를 지난 확률을 구분하고, binary cross-entropy가 오답 확률을 어떻게 벌하는지 확인한다. 시험 전에는 binary sigmoid와 multiclass softmax의 출력·손실 역할을 한 표로 대비한다.

## 복습 질문

<details markdown="block">
<summary>1. 선형 회귀의 decision boundary와 logistic regression의 decision boundary는 어떤 점에서 같은가?</summary>

답변: 둘 다 입력 feature의 선형 결합을 기반으로 한다. logistic regression은 그 선형 점수에 sigmoid를 적용하지만, class를 나누는 경계는 보통 $$w^Tx+b=0$$ 같은 선형 초평면으로 결정된다. 따라서 feature 공간에서는 선형 decision boundary를 가진다.

</details>

<details markdown="block">
<summary>2. Feature engineering이 underfitting과 overfitting에 각각 어떤 영향을 줄 수 있는가?</summary>

답변: 적절한 feature를 추가하면 단순한 모델도 데이터의 중요한 패턴을 표현할 수 있어 underfitting을 줄인다. 하지만 불필요하거나 너무 많은 feature를 넣으면 학습 데이터의 우연한 패턴까지 맞춰 overfitting이 커질 수 있다. 따라서 feature는 표현력과 일반화 사이의 균형이 필요하다.

</details>

<details markdown="block">
<summary>3. Binary cross-entropy가 classification에 자연스러운 이유는 무엇인가?</summary>

답변: binary classification에서는 label을 Bernoulli 확률변수로 볼 수 있다. 모델이 예측한 확률이 실제 label에 높은 likelihood를 주도록 학습하면 negative log-likelihood가 binary cross-entropy 형태가 된다. 그래서 확률적 분류 모델의 목적 함수로 자연스럽다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/1st_Regression.pdf" | relative_url }}" target="_blank" rel="noopener">1st_Regression.pdf</a></li>
</ul>
