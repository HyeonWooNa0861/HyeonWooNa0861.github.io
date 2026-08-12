---
layout: default
title: "Linear and Logistic Regression"
course: "AIX"
topic: "Linear and Logistic Regression"
order: 1
---

# Linear and Logistic Regression

Source PDF: `1st_Regression.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 지도학습 문제 | 입력 \\(x\\)와 정답 \\(y\\) 사이의 관계를 어떻게 학습하는가? |
| 2 | 선형 모델 | \\(\mathrm{score}=w^Tx+b\\)는 무엇을 표현하는가? |
| 3 | 잔차와 손실 | residual과 squared error는 왜 학습 목표가 되는가? |
| 4 | 최적화 | closed-form 해와 gradient descent는 어떻게 다른가? |
| 5 | Feature engineering | 선형 모델의 표현력을 어떻게 확장하는가? |
| 6 | Logistic regression | 분류 문제에서 score를 확률로 바꾸는 이유는 무엇인가? |
| 7 | Softmax와 perceptron | 이진 분류를 다중 분류와 신경망으로 어떻게 확장하는가? |

## 1. 지도학습과 데이터

지도학습에서는 데이터가 입력 feature \\(x\\)와 정답 target \\(y\\)의 쌍으로 주어진다. 모델의 목표는 훈련 데이터에만 맞는 함수를 외우는 것이 아니라, 아직 보지 못한 입력에 대해서도 적절한 \\(y\\)를 예측하는 함수 \\(f(x)\\)를 찾는 것이다.

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

\\(w\\)는 각 feature가 예측에 얼마나 영향을 주는지를 나타내고, \\(b\\)는 전체 기준점을 이동시키는 bias다. 2차원에서는 직선, 고차원에서는 hyperplane으로 볼 수 있다.

| 구성 요소 | 의미 |
|---|---|
| \\(x\\) | 입력 feature vector |
| \\(w\\) | feature별 가중치 |
| \\(b\\) | bias 또는 intercept |
| \\(\mathrm{score}\\) | 모델이 만든 선형 예측값 |

분류 문제에서도 같은 선형 score를 사용할 수 있다. 다만 score 자체를 최종 답으로 쓰지 않고, 뒤에서 sigmoid나 softmax 같은 link function을 붙인다.

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

학습은 손실 함수가 작아지도록 \\(w\\), \\(b\\)를 고르는 과정이다.

## 4. Closed-form과 Gradient Descent

선형 회귀는 특정 조건에서 pseudo-inverse를 이용해 한 번에 최적해를 구할 수 있다.

$$
w^\ast = (X^TX)^{-1}X^Ty
$$

이 방식은 작은 문제에서는 명확하지만, 행렬 역행렬 계산이 무겁고 대규모 데이터나 딥러닝 구조에는 잘 맞지 않는다.

반대로 gradient descent는 손실의 기울기를 따라 조금씩 parameter를 갱신한다.

$$
w \leftarrow w - \eta\frac{\partial L}{\partial w}
$$

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

예를 들어 \\(x\\), \\(x^2\\), \\(x^3\\) 같은 feature를 추가하면 모델은 parameter에 대해서는 여전히 선형이지만, 원래 입력 \\(x\\)에 대해서는 비선형 곡선을 표현할 수 있다.

다만 feature를 너무 많이 만들면 훈련 데이터에는 잘 맞지만 새 데이터에는 약한 overfitting이 생긴다.

## 6. Logistic Regression

분류에서는 예측값을 class probability로 해석하고 싶다. 하지만 선형 score는 음수나 1보다 큰 값이 될 수 있어 확률로 바로 쓸 수 없다.

Logistic regression은 선형 score를 sigmoid 함수에 통과시켜 \\(0\\)과 \\(1\\) 사이의 확률로 만든다.

$$
z = w^Tx + b
$$

$$
p = \sigma(z) = \frac{1}{1+\exp(-z)}
$$

| 값 | 의미 |
|---|---|
| \\(z\\) | 선형 score |
| \\(p\\) | \\(P(y=1\mid x)\\) |
| \\(p \ge 0.5\\) | class 1로 분류 |
| \\(p < 0.5\\) | class 0으로 분류 |

Logistic regression의 decision boundary는 여전히 \\(w^Tx + b = 0\\)인 선형 경계다. 달라지는 점은 score를 확률로 해석하고, classification에 맞는 손실 함수를 사용한다는 것이다.

## 7. Binary Cross-Entropy

Logistic regression은 관측된 label이 가장 그럴듯해지도록 parameter를 고른다. 이를 negative log-likelihood 관점으로 쓰면 binary cross-entropy가 된다.

$$
L = -\left[y\log p + (1-y)\log(1-p)\right]
$$

정답이 \\(1\\)이면 \\(p\\)가 커질수록 손실이 작아지고, 정답이 \\(0\\)이면 \\(p\\)가 작아질수록 손실이 작아진다. 따라서 squared error보다 classification의 확률적 해석에 더 자연스럽다.

## 8. Softmax와 Perceptron으로의 연결

Class가 3개 이상이면 각 class마다 score를 만들고 softmax로 확률 벡터를 만든다.

$$
z = Wx + b
$$

$$
p_i = \frac{\exp(z_i)}{\sum_j \exp(z_j)}
$$

Softmax의 핵심은 모든 class probability의 합이 \\(1\\)이 되도록 score를 정규화한다는 것이다.

Perceptron은 선형 score 뒤에 step function을 붙인 초기 신경망 단위로 볼 수 있다. Logistic regression은 step function 대신 sigmoid를 사용하여 미분 가능한 확률 모델로 만든다. 이후 MLP는 이런 단위를 여러 층으로 쌓고 비선형성을 추가해 표현력을 확장한다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| residual은 무엇인가? | 실제값과 예측값의 차이 |
| squared error를 쓰는 이유는? | 오차 상쇄를 막고 큰 오차를 더 강하게 벌하기 위해 |
| closed-form과 gradient descent의 차이는? | 한 번의 행렬 계산 vs 반복적인 기울기 기반 갱신 |
| logistic regression이 확률을 만드는 방식은? | 선형 score를 sigmoid에 통과시킨다. |
| softmax는 왜 필요한가? | 다중 class score를 확률 분포로 바꾸기 위해 |

## 복습 질문

<details>
<summary>1. 선형 회귀의 decision boundary와 logistic regression의 decision boundary는 어떤 점에서 같은가?</summary>

답변: 둘 다 입력 feature의 선형 결합을 기반으로 한다. logistic regression은 그 선형 점수에 sigmoid를 적용하지만, class를 나누는 경계는 보통 \\(w^Tx+b=0\\) 같은 선형 초평면으로 결정된다. 따라서 feature 공간에서는 선형 decision boundary를 가진다.

</details>

<details>
<summary>2. Feature engineering이 underfitting과 overfitting에 각각 어떤 영향을 줄 수 있는가?</summary>

답변: 적절한 feature를 추가하면 단순한 모델도 데이터의 중요한 패턴을 표현할 수 있어 underfitting을 줄인다. 하지만 불필요하거나 너무 많은 feature를 넣으면 학습 데이터의 우연한 패턴까지 맞춰 overfitting이 커질 수 있다. 따라서 feature는 표현력과 일반화 사이의 균형이 필요하다.

</details>

<details>
<summary>3. Binary cross-entropy가 classification에 자연스러운 이유는 무엇인가?</summary>

답변: binary classification에서는 label을 Bernoulli 확률변수로 볼 수 있다. 모델이 예측한 확률이 실제 label에 높은 likelihood를 주도록 학습하면 negative log-likelihood가 binary cross-entropy 형태가 된다. 그래서 확률적 분류 모델의 목적 함수로 자연스럽다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/1st_Regression.pdf" | relative_url }}" target="_blank" rel="noopener">1st_Regression.pdf</a></li>
</ul>
