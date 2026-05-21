---
layout: default
title: "Lecture 15 Model Meets Data"
course: "Machine Learning Basic"
topic: "Model Meets Data"
order: 15
---

# Lecture 15 Model Meets Data

Source PDF: `machine-learning-basic-lecture-15.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 데이터와 모델 | 모델은 어떤 형태의 데이터를 입력으로 받는가? |
| 2 | 데이터 벡터화 | 원본 데이터를 어떻게 feature vector로 바꾸는가? |
| 3 | 데이터 처리 | data selection, preprocessing, augmentation은 왜 중요한가? |
| 4 | 모델의 의미 | 모델을 deterministic function 또는 probability distribution으로 볼 수 있는가? |
| 5 | Learning | 좋은 parameter와 model은 어떤 절차로 찾는가? |
| 6 | ERM | 학습 데이터에 대한 평균 손실을 어떻게 최소화하는가? |
| 7 | Generalization | 학습 데이터를 잘 맞추는 것과 unseen data를 잘 맞추는 것은 왜 다른가? |
| 8 | Regularization | overfitting을 어떻게 줄이는가? |
| 9 | MLE와 MAP | 확률 모델에서는 parameter를 어떻게 추정하는가? |

## 1. 데이터와 머신러닝

현대 머신러닝과 인공지능 모델이 강력해진 근본 원인 중 하나는 많은 데이터다.

강의에서는 데이터를 컴퓨터가 읽을 수 있는 수치적 형태, 특히 table 형태의 feature matrix로 생각한다.

\\(N\\)개의 데이터가 있고, 각 데이터는 \\(D\\)차원의 feature로 표현된다.

원본 데이터는 그대로 모델에 들어가기 어렵다. 전문가나 전처리 알고리즘이 원본 데이터를 특징값(feature)으로 변환하고, 각 sample을 D차원 vector로 표현한다.

## 2. 데이터의 벡터화와 정규화

데이터 벡터화는 원본 데이터를 모델이 처리할 수 있는 feature vector로 바꾸는 과정이다.

$$
\text{raw data}
\to \text{feature extraction}
\to x \in \mathbb{R}^D
$$

연속적인 수치값을 가지는 feature는 보통 평균이 0, 분산이 1이 되도록 조정한다.

$$
x_{\text{normalized}} = \frac{x-\mu}{\sigma}
$$

이 normalization은 feature scale 차이 때문에 특정 feature가 학습을 지배하는 문제를 줄이고, gradient 기반 학습을 더 안정적으로 만든다.

## 3. 데이터 처리의 중요성

최근 큰 모델들은 단순히 데이터 양을 늘리는 것만으로는 한계에 부딪히고 있다. 그래서 데이터의 질과 구성 방식이 중요해진다.

| 방향 | 의미 |
|---|---|
| Data selection | 학습에 도움이 되는 데이터를 잘 고르는 것 |
| Data preprocessing | 결측치, scale, noise, encoding 등을 정리하는 것 |
| Data augmentation | 기존 데이터를 변형하거나 생성 모델로 보강하는 것 |

즉, 모델 성능은 model architecture뿐 아니라 어떤 데이터를 어떻게 넣는지에 크게 좌우된다.

## 4. 모델이란?

모델은 입력을 받아 예측, 분포, 결정을 출력하는 함수로 볼 수 있다.

지도학습에서는 보통 다음과 같은 dataset을 가진다.

$$
\{(x_1,y_1),(x_2,y_2),\ldots,(x_N,y_N)\}
$$

우리가 알고 싶은 것은 관측하지 않은 임의의 \\(x\\)에 대한 \\(y\\)값이다.

## 5. 결정론적 함수로서의 모델

결정론적 모델은 입력 \\(x\\)에 대해 하나의 예측값을 출력한다.

$$
f:\mathbb{R}^D \to \mathbb{R}
$$

예를 들어 선형 회귀는 다음과 같은 함수로 볼 수 있다.

$$
f(x)=\theta^T x+\theta_0
$$

이 관점에서는 기존 데이터셋을 잘 설명하는 함수 \\(f\\)를 찾는 것이 학습이다.

## 6. 확률분포로서의 모델

확률적 모델은 단순한 예측값 하나가 아니라 예측의 불확실성까지 표현한다.

$$
p(y \mid x,\theta)
$$

예를 들어 회귀 문제에서 관측값이 noise를 가진다고 보면 다음처럼 모델링할 수 있다.

$$
y = f_\theta(x) + \epsilon
$$

$$
\epsilon \sim \mathcal{N}(0,\sigma^2)
$$

이 경우 모델은 \\(\hat{y}\\) 하나가 아니라 \\(y\\)가 나올 확률분포를 제공한다. 데이터 관측 error, noise, 데이터 부족으로 인한 불확실성을 함께 다룰 수 있다.

## 7. 머신러닝의 세 단계

강의는 learning을 다음처럼 정리한다.

```text
많은 모델과 parameter 중
unseen data에 좋은 예측을 주는 모델과 parameter를 찾는 과정
```

머신러닝 과정은 크게 세 단계로 볼 수 있다.

| 단계 | 설명 |
|---|---|
| Training / Parameter estimation | 주어진 training data로 parameter를 찾음 |
| Hyperparameter tuning / Model selection | validation 성능으로 model family나 hyperparameter 선택 |
| Prediction / Inference | 학습된 모델로 새로운 입력에 대해 예측 |

결정론적 모델에서는 보통 empirical risk minimization을 사용하고, 확률적 모델에서는 likelihood 기반 parameter estimation을 사용한다.

## 8. Empirical Risk Minimization

학습 단계에서는 모델이 데이터를 얼마나 잘 맞추는지 측정하는 지표가 필요하다. 이를 loss function이라고 한다.

$$
\operatorname{loss}(f(x_i,\theta),y_i)
$$

Training data 전체에 대한 평균 loss를 empirical risk라고 한다.

$$
R_{\mathrm{emp}}(\theta,X,Y)
= \frac{1}{N}\sum_{i=1}^{N}\operatorname{loss}(f(x_i,\theta),y_i)
$$

Empirical Risk Minimization(ERM)은 이 값을 최소화하는 parameter를 찾는 것이다.

$$
\theta^*
= \arg\min_{\theta}
\frac{1}{N}\sum_{i=1}^{N}\operatorname{loss}(f(\theta,x_i),y_i)
$$

여기에는 보통 training data가 i.i.d. sample이라는 가정이 들어간다. 즉 각 데이터가 같은 분포에서 독립적으로 샘플링되었다고 보는 것이다.

## 9. ERM 예시: 선형 회귀와 최소제곱

선형 회귀에서 squared error loss를 쓰면 ERM은 최소제곱법이 된다.

$$
f(x,\theta)=\theta^T x+\theta_0
$$

$$
\operatorname{loss}(f(x_i,\theta),y_i)
= (y_i-f(x_i,\theta))^2
$$

$$
\theta^*
= \arg\min_{\theta}
\frac{1}{N}\sum_{i=1}^{N}(y_i-\theta^T x_i-\theta_0)^2
$$

즉, 선형 회귀의 최소제곱법은 ERM의 대표적인 예다.

## 10. 우리가 진짜 원하는 것: Generalization

우리가 원하는 것은 training data를 외우는 모델이 아니라 새로운 데이터에 잘 맞는 모델이다.

$$
R_{\mathrm{true}}(f)
= \mathbb{E}_{x,y}\operatorname{loss}(y,f(x))
$$

모델이 training data에만 지나치게 맞춰지면 overfitting이 발생한다. 그래서 training error뿐 아니라 validation error를 함께 봐야 한다.

| 상황 | 해석 |
|---|---|
| training error 낮음, validation error 낮음 | 일반화가 잘 됨 |
| training error 낮음, validation error 높음 | overfitting 가능성 |
| training error 높음, validation error 높음 | underfitting 가능성 |

## 11. Regularization

Regularization은 overfitting을 줄이기 위해 loss에 penalty를 추가하는 방법이다.

$$
\arg\min_{\theta}
\frac{1}{N}\sum_{i=1}^{N}\operatorname{loss}(f(x_i,\theta),y_i)
+
\lambda\lVert\theta\rVert^2
$$

대표적인 penalty는 parameter 크기를 제한하는 방식이다.

| 방식 | penalty |
|---|---|
| L2 regularization | squared L2 norm |
| L1 regularization | L1 norm |

Regularization은 모델이 training data에 너무 복잡하게 맞춰지는 것을 막고, 더 단순하고 일반화 가능한 해를 선호하게 만든다.

## 12. Cross Validation

Validation set 하나만 쓰면 데이터 분할에 따라 성능 추정이 흔들릴 수 있다. Cross validation은 데이터를 여러 fold로 나누어 검증을 반복한다.

```text
1. 데이터를 K개 fold로 나눔
2. K-1개 fold로 학습
3. 남은 1개 fold로 검증
4. 검증 fold를 바꿔가며 반복
5. 평균 validation score 계산
```

데이터가 많지 않을 때 model selection과 hyperparameter tuning을 더 안정적으로 할 수 있다.

## 13. Maximum Likelihood Estimation

예측값이 확률분포로 모델링되어 있으면 parameter estimation을 likelihood 관점에서 할 수 있다.

$$
p(x\mid\theta)
$$

negative log-likelihood는 다음처럼 쓴다.

$$
\mathcal{L}_x(\theta) = -\log p(x\mid\theta)
$$

관측 오차가 가우시안이라고 두면 regression likelihood는 다음처럼 적는다.

$$
\epsilon_n \sim \mathcal{N}(0,\sigma^2)
$$

$$
p(y_n\mid x_n,\theta)
= \mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

i.i.d. 가정에서는 전체 likelihood가 각 sample likelihood의 곱으로 분해된다.

$$
p(y\mid X,\theta)
= \prod_{n=1}^{N}p(y_n\mid x_n,\theta)
$$

실제 최적화에서는 negative log-likelihood를 최소화한다.

$$
\mathcal{L}(\theta)
= -\sum_{n=1}^{N}\log p(y_n\mid x_n,\theta)
$$

## 14. MAP와 Regularization

Maximum A Posteriori(MAP)는 parameter의 prior까지 고려한다.

$$
p(\theta\mid x)
= \frac{p(x\mid\theta)p(\theta)}{p(x)}
$$

Bayes rule에 의해 다음과 같다.

$$
p(\theta\mid x) \propto p(x\mid\theta)p(\theta)
$$

negative log를 취하면 다음 형태가 된다.

$$
-\log p(x\mid\theta)-\log p(\theta)
= \mathrm{NLL}-\log p(\theta)
$$

따라서 ERM에서 regularization을 추가하는 것은 확률 모델 관점에서 prior를 넣는 것과 연결된다. 예를 들어 Gaussian prior는 L2 regularization과 대응된다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 데이터 벡터화란? | 원본 데이터를 feature vector로 바꾸는 과정 |
| continuous feature를 평균 0, 분산 1로 맞추는 이유는? | scale 차이를 줄이고 학습을 안정화하기 위해 |
| deterministic model과 probabilistic model의 차이는? | 전자는 예측값 하나, 후자는 예측 분포와 불확실성까지 출력 |
| ERM이 최소화하는 것은? | training data에 대한 평균 loss, empirical risk |
| 우리가 진짜 원하는 성능은? | training data가 아니라 unseen data에 대한 generalization |
| regularization의 목적은? | overfitting을 줄이고 단순한 해를 선호하기 위해 |
| MLE는 무엇을 최대화하는가? | 관측 데이터 likelihood |
| MAP와 regularization의 연결은? | prior의 negative log가 regularization penalty처럼 작동 |

## 복습 질문

1. Training error가 낮은데 validation error가 높다면 어떤 문제가 의심되는가?
2. ERM에서 i.i.d. 가정이 왜 중요한가?
3. Squared error를 쓰는 선형 회귀가 ERM의 예가 되는 이유를 설명하라.
4. MLE에서 likelihood 곱 대신 log-likelihood 합을 쓰는 이유는 무엇인가?
5. Gaussian prior와 L2 regularization이 어떻게 연결되는지 설명하라.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-15.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-15.pdf</a></li>
</ul>
