---
layout: default
title: "Multi-Layer Perceptron"
course: "AIX"
topic: "MLP와 일반화"
order: 2
---

# Multi-Layer Perceptron

Source PDF: `02_MLP.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Feed-forward network | 입력이 출력까지 한 방향으로 흐르는 구조는 무엇인가? |
| 2 | Activation | 비선형 함수가 없으면 왜 깊은 모델이 의미가 약해지는가? |
| 3 | Perceptron | 선형 score와 activation을 결합한 기본 단위는 무엇인가? |
| 4 | XOR 문제 | 단일 perceptron의 한계는 어디서 드러나는가? |
| 5 | MLP | hidden layer가 decision boundary를 어떻게 바꾸는가? |
| 6 | Backpropagation | 여러 층의 parameter gradient를 어떻게 효율적으로 구하는가? |
| 7 | Generalization | 학습 오차와 테스트 오차의 차이를 어떻게 관리하는가? |
| 8 | Regularization | 모델이 훈련 데이터에만 맞는 것을 어떻게 줄이는가? |

## 1. Feed-forward Neural Network

Feed-forward neural network는 입력이 hidden layer를 지나 output layer로 한 방향으로 흐르는 신경망이다.

```text
input x -> hidden layers -> output o
```

각 layer는 보통 선형 변환과 activation function의 조합으로 구성된다.

$$
h = \phi(Wx+b)
$$

| Layer | 역할 |
|---|---|
| Input layer | 숫자 벡터 형태의 입력을 받는다. |
| Hidden layer | 입력을 여러 단계의 feature representation으로 변환한다. |
| Output layer | classification score, probability, regression value 등을 출력한다. |

## 2. Activation과 비선형성

Activation function은 신경망에 비선형성을 넣는다. 비선형성이 없다면 여러 선형 layer를 쌓아도 결국 하나의 선형 변환으로 합쳐진다.

$$
W_2(W_1x+b_1)+b_2
= (W_2W_1)x + (W_2b_1+b_2)
$$

따라서 MLP의 표현력은 선형 변환을 여러 번 하는 데서만 나오지 않고, 각 층 사이에 들어가는 비선형 activation에서 나온다.

| Activation | 특징 |
|---|---|
| Sigmoid | `0`부터 `1` 사이로 압축한다. 확률 해석에 유용하다. |
| Tanh | `-1`부터 `1` 사이로 압축한다. |
| ReLU | `max(0, x)`로 단순하고 깊은 모델에서 자주 쓰인다. |
| Leaky ReLU | 음수 영역에도 작은 기울기를 남긴다. |

## 3. Perceptron

Perceptron은 선형 score와 step activation을 결합한 초기 신경망 모델이다.

$$
z = w^Tx + b
$$

$$
\mathrm{output} = \operatorname{step}(z)
$$

학습 과정에서는 잘못 분류된 예제를 기준으로 weight를 갱신한다. 직관적으로는 decision boundary를 오분류된 데이터가 줄어드는 방향으로 움직이는 것이다.

단일 perceptron은 선형 분리 가능한 문제에는 사용할 수 있지만, 선형 경계 하나로 나눌 수 없는 문제에는 한계가 있다.

## 4. XOR 문제와 단일 Layer의 한계

XOR 문제는 단일 직선으로 두 class를 분리할 수 없는 대표적인 예다.

| x1 | x2 | XOR |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

이 패턴은 하나의 선형 boundary로 나눌 수 없다. Minsky와 Papert가 지적한 perceptron의 한계는 이후 hidden layer와 비선형 activation의 필요성을 설명하는 중요한 역사적 장면이 된다.

## 5. Multi-Layer Perceptron

MLP는 perceptron 구조를 여러 층으로 확장한 모델이다.

```text
x -> Linear -> Activation -> Linear -> Activation -> Output
```

Hidden layer가 들어가면 모델은 입력 공간을 여러 단계로 변환한 뒤 분류 또는 회귀를 수행할 수 있다. 이때 각 hidden unit은 하나의 단순 경계를 만들고, 여러 unit과 layer가 결합되면서 복잡한 decision boundary를 형성한다.

| 모델 | 표현력 |
|---|---|
| Linear model | 하나의 선형 경계 또는 선형 함수 |
| Single perceptron | 선형 분리 가능한 class |
| MLP | 비선형 경계와 복잡한 함수 |

## 6. Backpropagation

Backpropagation은 chain rule을 이용해 신경망의 모든 parameter에 대한 gradient를 효율적으로 계산하는 방법이다.

Forward pass에서는 입력에서 출력까지 값을 계산한다.

```text
x -> h1 -> h2 -> y_hat -> loss
```

Backward pass에서는 loss에서 입력 방향으로 gradient를 전달한다.

$$
\frac{\partial L}{\partial W_2},\quad
\frac{\partial L}{\partial b_2},\quad
\frac{\partial L}{\partial W_1},\quad
\frac{\partial L}{\partial b_1}
$$

각 layer는 자신의 local derivative만 알면 되고, 전체 gradient는 chain rule로 연결된다. 이 구조 덕분에 깊은 네트워크를 사람이 직접 미분하지 않고도 학습할 수 있다.

## 7. Cross Validation과 일반화

모델이 훈련 데이터에만 잘 맞는지, 새 데이터에도 잘 맞는지를 확인하려면 validation이 필요하다.

K-fold cross validation은 데이터를 `K`개의 fold로 나누고, 각 fold를 한 번씩 validation set으로 사용한다.

| 단계 | 설명 |
|---|---|
| Split | 데이터를 `K`개 fold로 나눈다. |
| Train | `K-1`개 fold로 학습한다. |
| Validate | 남은 1개 fold로 평가한다. |
| Average | `K`번의 평가 결과를 평균낸다. |

데이터가 많지 않을 때 성능 추정의 안정성을 높이는 데 유용하다.

## 8. Expressivity와 Generalization

표현력이 높은 모델은 더 복잡한 패턴을 학습할 수 있다. 하지만 표현력이 너무 크고 regularization이 부족하면 훈련 데이터의 noise까지 외워 overfitting이 생긴다.

| 상태 | 특징 | 대응 |
|---|---|---|
| High bias | 모델이 너무 단순해 underfitting | 모델 크기 증가, feature 개선 |
| High variance | 모델이 데이터 변화에 민감해 overfitting | regularization, 데이터 증가, early stopping |
| Good fit | 훈련/검증 성능이 모두 안정적 | 현재 설정 유지 |

Generalization gap은 training error와 test error의 차이다. gap이 크면 훈련 데이터에 과하게 맞았을 가능성이 높다.

## 9. Regularization

Regularization은 모델이 지나치게 큰 weight나 복잡한 패턴에 의존하지 않도록 제한한다.

| 기법 | 설명 |
|---|---|
| L1 regularization | 일부 weight를 0에 가깝게 만들어 sparsity를 유도한다. |
| L2 regularization | weight 크기를 부드럽게 줄여 과적합을 완화한다. |
| Elastic Net | L1과 L2를 함께 사용한다. |
| Early stopping | validation loss가 악화되기 전에 학습을 멈춘다. |

핵심은 훈련 손실을 무조건 낮추는 것이 아니라, unseen data에서 안정적으로 동작하는 모델을 만드는 것이다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| activation이 필요한 이유는? | 선형 layer만 쌓으면 결국 하나의 선형 변환이 되기 때문 |
| XOR 문제가 중요한 이유는? | 단일 perceptron의 선형 분리 한계를 보여주기 때문 |
| backpropagation의 핵심 원리는? | chain rule을 반복 적용해 gradient를 계산한다. |
| generalization gap은 무엇인가? | training error와 test error의 차이 |
| L1과 L2의 차이는? | L1은 sparsity, L2는 weight shrinkage를 유도한다. |

## 복습 질문

<details>
<summary>1. ReLU 계열 activation이 깊은 신경망에서 자주 쓰이는 이유는 무엇인가?</summary>

답변: ReLU는 양수 구간에서 gradient가 사라지지 않아 sigmoid나 tanh보다 깊은 네트워크 학습이 안정적인 편이다. 계산도 단순하고 sparse activation을 만들어 효율적이다. 다만 음수 구간에서 gradient가 0이 되는 dying ReLU 문제는 주의해야 한다.

</details>

<details>
<summary>2. MLP가 XOR 문제를 풀 수 있는 이유를 hidden layer 관점에서 설명하라.</summary>

답변: XOR은 입력 공간에서 하나의 직선으로 분리되지 않는다. hidden layer는 입력을 비선형 변환해 새로운 표현 공간을 만들고, 그 공간에서는 XOR 패턴을 선형적으로 나눌 수 있게 한다. 즉 hidden unit들이 여러 경계 조각을 만들어 비선형 decision boundary를 형성한다.

</details>

<details>
<summary>3. Validation loss가 올라가고 training loss가 계속 내려가면 어떤 문제가 의심되는가?</summary>

답변: overfitting이 의심된다. 모델이 training data에는 점점 더 잘 맞지만, unseen data를 대표하는 validation data에서는 성능이 나빠지는 상황이다. regularization, early stopping, data augmentation, 모델 크기 조정 등을 고려할 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/02_MLP.pdf" | relative_url }}" target="_blank" rel="noopener">02_MLP.pdf</a></li>
</ul>
