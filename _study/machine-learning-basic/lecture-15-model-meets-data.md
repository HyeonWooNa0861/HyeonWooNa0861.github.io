---
layout: default
date: 2026-05-21 12:29:52 +0900
title: "Lecture 15 Model Meets Data"
course: "Machine Learning Basic"
topic: "Model Meets Data"
order: 15
major_topic: "Machine Learning Foundations"
keywords:
  - "Model Fitting"
  - "Empirical Risk"
  - "Training Data"
  - "Loss Functions"
  - "Generalization"
---

# Lecture 15 Model Meets Data

Source PDF: `machine-learning-basic-lecture-15.pdf`

> **핵심:** **데이터 벡터화란** 원본 데이터를 feature vector 또는 feature matrix로 바꾸는 과정. **continuous feature를 평균 0, 분산 1로 맞추는 이유는** scale 차이를 줄이고 gradient 기반 학습을 안정화하기 위해.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 데이터와 모델 | 모델은 어떤 형태의 데이터를 입력으로 받는가? |
| 2 | 데이터 벡터화 | 원본 데이터는 어떻게 feature matrix가 되는가? |
| 3 | 데이터 처리 | data selection, preprocessing, augmentation은 왜 중요한가? |
| 4 | 모델의 두 관점 | deterministic function과 probabilistic model은 어떻게 다른가? |
| 5 | Learning | 좋은 모델과 parameter를 찾는 과정은 어떻게 나뉘는가? |
| 6 | ERM | training data에 대한 평균 손실을 어떻게 최소화하는가? |
| 7 | Generalization | training data를 잘 맞추는 것과 unseen data를 잘 맞추는 것은 왜 다른가? |
| 8 | Regularization | overfitting을 줄이기 위해 objective를 어떻게 바꾸는가? |
| 9 | Cross Validation | validation을 더 안정적으로 하려면 데이터를 어떻게 나누는가? |
| 10 | MLE와 MAP | 확률 모델에서는 likelihood와 prior로 parameter를 어떻게 추정하는가? |

15강은 앞에서 배운 데이터, 모델, 최적화, 확률분포를 하나로 묶는다. 핵심은 “모델을 학습한다”는 말을 수학적으로 어떻게 표현하는지다. 결정론적 모델에서는 empirical risk minimization이 중심이고, 확률적 모델에서는 likelihood와 posterior가 중심이다.

## 1. 데이터와 머신러닝

현대 머신러닝과 인공지능 모델이 작동할 수 있게 된 근본적인 이유 중 하나는 많은 데이터다. 강의에서는 데이터를 컴퓨터가 읽을 수 있는 수치적 형태, 특히 table 형태의 데이터로 가정한다.

원본 데이터는 보통 그대로 모델에 들어가지 않는다. 전문가 지식이나 전처리 알고리즘을 통해 feature로 변환되고, 각 sample은 \(D\)차원의 feature vector가 된다.

$$
x_n\in\mathbb{R}^{D}
$$

\(N\)개의 데이터가 있으면 전체 dataset은 feature matrix로 볼 수 있다.

$$
X\in\mathbb{R}^{N\times D}
$$

여기서 행은 sample, 열은 feature에 대응한다.

| 기호 | 의미 |
|---|---|
| \(N\) | 데이터 sample 수 |
| \(D\) | feature 차원 |
| \(x_n\) | \(n\)번째 sample의 feature vector |
| \(X\) | 전체 feature matrix |

## 2. 데이터의 벡터화

데이터 벡터화는 원본 데이터를 모델이 처리할 수 있는 숫자 벡터로 바꾸는 과정이다.

$$
\text{raw data}
\longrightarrow
\text{feature extraction}
\longrightarrow
x\in\mathbb{R}^{D}
$$

예를 들어 사람 정보를 다루는 table에서 성별, 학위, 우편번호, 나이, 연봉 같은 항목은 바로 모델이 이해할 수 없다. 범주형 값은 encoding해야 하고, 연속형 값은 scale을 맞춰야 하며, 필요 없는 열은 제거하거나 의미 있는 feature로 바꾸어야 한다.

벡터화의 목적은 단순히 숫자로 바꾸는 것이 아니라, 모델이 학습할 수 있는 정보 구조를 만드는 것이다.

## 3. 정규화와 Feature Scale

연속적인 수치값을 가지는 feature는 보통 평균이 0이고 분산이 1이 되도록 조정한다.

$$
x_{\mathrm{normalized}}
=\frac{x-\mu}{\sigma}
$$

이 처리를 standardization 또는 z-score normalization이라고 부른다.

| 정규화 전 문제 | 정규화 후 효과 |
|---|---|
| feature마다 scale이 다름 | 특정 feature가 loss나 gradient를 과도하게 지배하는 것을 줄임 |
| optimization contour가 길게 늘어남 | gradient descent가 더 안정적으로 이동하기 쉬움 |
| learning rate 조절이 어려움 | 하나의 learning rate가 여러 feature에 더 균형 있게 작동 |

정규화는 모델 성능뿐 아니라 최적화 안정성에도 직접적인 영향을 준다.

## 4. 데이터 처리의 중요성

최신 인공지능 모델은 단순히 데이터 양만 늘리는 데 한계를 맞고 있다. 그래서 좋은 데이터를 고르고, 잘 정리하고, 필요한 경우 늘리는 과정이 중요해졌다.

| 방향 | 의미 | 예 |
|---|---|---|
| Data selection | 학습에 도움이 되는 데이터를 고른다. | 중복, 저품질, 잘못된 label 제거 |
| Data preprocessing | 모델이 다루기 좋게 데이터를 정리한다. | 결측치 처리, scaling, encoding, noise 제거 |
| Data augmentation | 데이터 양과 다양성을 늘린다. | 이미지 변형, 문장 paraphrase, 생성 모델 활용 |

좋은 model architecture라도 입력 데이터가 편향되거나 noisy하면 일반화 성능이 떨어질 수 있다. 그래서 “모델이 데이터를 만난다”는 것은 데이터의 품질, 표현, 분포가 학습 결과를 결정한다는 뜻이기도 하다.

## 5. 모델이란?

모델은 입력을 받아 예측, 분포, 결정 같은 출력을 내는 함수다. 지도학습에서는 보통 다음과 같은 dataset을 가진다.

$$
\mathcal{D}
=\{(x_1,y_1),(x_2,y_2),\ldots,(x_N,y_N)\}
$$

우리가 모델을 통해 알고 싶은 것은 관측하지 않은 새로운 \(x\)에 대한 \(y\)다. 즉, training data 안의 sample을 외우는 것이 아니라 unseen data에 대해 좋은 예측을 하는 것이 목표다.

## 6. 결정론적 함수로서의 모델

결정론적 모델은 입력 \(x\)에 대해 하나의 예측값을 출력한다.

$$
\hat{y}=f_\theta(x)
$$

예를 들어 선형 회귀는 다음과 같은 함수로 볼 수 있다.

$$
f_\theta(x)=\theta^T x+\theta_0
$$

여기서 \(\theta\)는 feature별 가중치이고, \(\theta_0\)는 bias 또는 intercept다. 이 관점에서 학습은 training data를 잘 설명하는 함수 \(f_\theta\)를 찾는 과정이다.

## 7. 확률분포로서의 모델

확률적 모델은 하나의 예측값만 출력하지 않고, 예측에 대한 불확실성까지 분포로 표현한다.

$$
p(y\mid x,\theta)
$$

예를 들어 회귀 문제에서 관측값이 noise를 가진다고 보면 다음처럼 모델링할 수 있다.

$$
y=f_\theta(x)+\epsilon
$$

$$
\epsilon\sim\mathcal{N}(0,\sigma^2)
$$

그러면 \(y\)는 다음 분포를 따른다.

$$
p(y\mid x,\theta)
=\mathcal{N}(y\mid f_\theta(x),\sigma^2)
$$

확률적 모델은 데이터 관측 error, noise, 데이터 부족으로 인한 모델 불확실성을 함께 다룰 수 있다. 12, 13강에서 배운 Gaussian distribution이 여기서 자연스럽게 연결된다.

## 8. 머신러닝이란?

강의는 learning을 다음처럼 정리한다.

> 수많은 모델과 그 모델의 parameter 중 unseen data에 대해 좋은 예측을 주는 모델과 parameter를 찾는 과정

머신러닝 과정은 크게 세 단계로 나눌 수 있다.

| 단계 | 설명 | 대표 기준 |
|---|---|---|
| Training / Parameter estimation | 주어진 training data로 parameter를 찾는다. | training loss, likelihood |
| Hyperparameter tuning / Model selection | 모델 구조나 hyperparameter를 고른다. | validation score |
| Prediction / Inference | 학습된 모델로 새 입력에 대한 결과를 낸다. | test 또는 deployment 성능 |

결정론적 모델에서는 보통 ERM을 사용하고, 확률적 모델에서는 MLE나 MAP 같은 parameter estimation을 사용한다.

## 9. Empirical Risk Minimization

학습 단계에서 필요한 것은 모델이 데이터를 얼마나 잘 맞추는지 판단할 metric이다. 이를 loss function이라고 한다.

$$
\ell(f(x_i,\theta),y_i)
$$

Training data 전체에 대한 평균 loss를 empirical risk라고 한다.

$$
R_{\mathrm{emp}}(\theta,X,Y)
=\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
$$

Empirical Risk Minimization(ERM)은 empirical risk를 최소화하는 parameter를 찾는 것이다.

$$
\theta^*
=\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
$$

ERM이 의미 있으려면 training data가 i.i.d. sample이라는 가정이 중요하다. 즉, 각 sample이 같은 data-generating distribution에서 독립적으로 나왔다고 보아야 training 평균 loss가 실제 위험의 근사로 작동한다.

## 10. ERM 예시: 선형 회귀와 최소제곱

선형 회귀에서 모델을 다음처럼 두자.

$$
f(x,\theta)=\theta^T x+\theta_0
$$

Squared error loss를 사용하면

$$
\ell(f(x_i,\theta),y_i)
=\left(y_i-f(x_i,\theta)\right)^2
$$

이고, ERM은 다음 문제가 된다.

$$
\theta^*
=\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\left(y_i-\theta^T x_i-\theta_0\right)^2
$$

행렬 형태로 쓰면 최소제곱 문제와 연결된다.

$$
\theta^*
=\arg\min_{\theta}
\frac{1}{N}\lVert y-\tilde{X}\theta\rVert^2
$$

여기서 \(\tilde{X}\)는 bias 항을 포함하도록 feature matrix에 1로 된 열을 추가한 행렬로 볼 수 있다. 따라서 선형 회귀의 최소제곱법은 ERM의 대표적인 예다.

## 11. 우리가 진짜 원하는 것: Generalization

우리가 진짜 원하는 것은 training data를 잘 맞추는 모델이 아니라 새로운 데이터에 잘 맞는 모델이다.

$$
R_{\mathrm{true}}(f)
=\mathbb{E}_{x,y}\left[\ell(y,f(x))\right]
$$

하지만 실제로는 전체 data-generating distribution을 모르기 때문에 \(R_{\mathrm{true}}\)를 직접 계산할 수 없다. 그래서 training data로 \(R_{\mathrm{emp}}\)를 최소화하되, validation data로 unseen data 성능을 추정한다.

| 상황 | 해석 |
|---|---|
| training error 낮음, validation error 낮음 | 일반화가 잘 됨 |
| training error 낮음, validation error 높음 | overfitting 가능성 |
| training error 높음, validation error 높음 | underfitting 가능성 |

Overfitting은 모델이 training data의 noise나 우연한 패턴까지 외운 상태다. Underfitting은 모델이 너무 단순하거나 학습이 부족해서 training data조차 잘 설명하지 못하는 상태다.

## 12. Regularization

Regularization은 모델이 training data에 과적합되는 것을 막기 위해 objective에 penalty를 추가하는 방법이다.

$$
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
+\lambda\Omega(\theta)
$$

대표적으로 L2 regularization은 다음 형태를 가진다.

$$
\Omega(\theta)=\lVert\theta\rVert^2
$$

따라서 objective는 다음처럼 된다.

$$
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
+\lambda\lVert\theta\rVert^2
$$

| regularization | penalty | 효과 |
|---|---|---|
| L2 | \(\lVert\theta\rVert_2^2\) | 큰 parameter를 부드럽게 억제 |
| L1 | \(\lVert\theta\rVert_1\) | 일부 parameter를 0으로 만들어 sparse solution 유도 |

\(\lambda\)는 regularization strength다. 너무 작으면 overfitting을 충분히 막지 못하고, 너무 크면 underfitting이 생길 수 있다.

## 13. Cross Validation

Validation set 하나만 사용하면 데이터 분할에 따라 성능 추정이 흔들릴 수 있다. Cross validation은 데이터를 여러 fold로 나누어 검증을 반복하는 방법이다.

K-fold cross validation은 다음 절차로 진행된다.

1. 데이터를 \(K\)개 fold로 나눈다.
2. \(K-1\)개 fold로 학습한다.
3. 남은 1개 fold로 validation score를 계산한다.
4. validation fold를 바꿔가며 \(K\)번 반복한다.
5. \(K\)개의 validation score 평균을 model selection에 사용한다.

데이터가 많지 않을 때 cross validation은 hyperparameter tuning과 model selection을 더 안정적으로 해준다. 다만 학습을 여러 번 해야 하므로 계산 비용은 증가한다.

## 14. Maximum Likelihood Estimation

예측값이 확률분포로 모델링되어 있으면 parameter estimation을 likelihood 관점에서 할 수 있다.

$$
p(x\mid\theta)
$$

Maximum Likelihood Estimation(MLE)은 관측된 데이터가 가장 그럴듯해지는 parameter를 찾는 방법이다.

$$
\theta_{\mathrm{MLE}}
=\arg\max_{\theta}p(\mathcal{D}\mid\theta)
$$

i.i.d. 가정에서는 전체 likelihood가 각 sample likelihood의 곱으로 분해된다.

$$
p(\mathcal{D}\mid\theta)
=\prod_{n=1}^{N}p(y_n\mid x_n,\theta)
$$

곱은 계산하기 불편하고 underflow가 생기기 쉬우므로 log를 취한다.

$$
\log p(\mathcal{D}\mid\theta)
=\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

log는 단조 증가 함수이므로 likelihood를 최대화하는 parameter와 log-likelihood를 최대화하는 parameter는 같다. 실제 최적화에서는 negative log-likelihood를 최소화한다.

$$
\mathcal{L}(\theta)
=-\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

## 15. 변수 추정 예시: Gaussian Observation Error

관측 오차가 Gaussian이라고 하자.

$$
\epsilon_n\sim\mathcal{N}(0,\sigma^2)
$$

선형 모델에서는 다음처럼 쓸 수 있다.

$$
y_n=x_n^T\theta+\epsilon_n
$$

따라서 likelihood는

$$
p(y_n\mid x_n,\theta)
=\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

이다. Gaussian PDF를 풀어 쓰면

$$
p(y_n\mid x_n,\theta)
=
\frac{1}{\sqrt{2\pi\sigma^2}}
\exp\left(
-\frac{(y_n-x_n^T\theta)^2}{2\sigma^2}
\right)
$$

전체 negative log-likelihood는 다음과 같다.

$$
\mathcal{L}(\theta)
=-\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

이를 전개하면

$$
\mathcal{L}(\theta)
=
\sum_{n=1}^{N}
\frac{(y_n-x_n^T\theta)^2}{2\sigma^2}
-\sum_{n=1}^{N}
\log\frac{1}{\sqrt{2\pi\sigma^2}}
$$

두 번째 항은 \(\theta\)와 무관한 constant다. 따라서 Gaussian observation error에서 MLE는 squared error를 최소화하는 것과 같은 parameter를 선택한다.

$$
\theta_{\mathrm{MLE}}
=
\arg\min_{\theta}
\sum_{n=1}^{N}
(y_n-x_n^T\theta)^2
$$

이 결과는 확률 모델과 ERM이 어떻게 연결되는지 보여준다. squared error는 단순히 임의로 고른 loss가 아니라 Gaussian noise assumption에서 자연스럽게 나온다.

## 16. MAP와 Regularization

Maximum A Posteriori(MAP)는 likelihood뿐 아니라 parameter prior까지 고려한다.

$$
p(\theta\mid x)
=
\frac{p(x\mid\theta)p(\theta)}{p(x)}
$$

\(p(x)\)는 \(\theta\)에 대해 constant이므로 MAP 추정에서는 다음을 최대화하면 된다.

$$
p(\theta\mid x)
\propto
p(x\mid\theta)p(\theta)
$$

따라서

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
p(x\mid\theta)p(\theta)
$$

negative log를 취하면 최대화 문제는 최소화 문제로 바뀐다.

$$
\theta_{\mathrm{MAP}}
=
\arg\min_{\theta}
\left[
-\log p(x\mid\theta)
-\log p(\theta)
\right]
$$

즉,

$$
\text{MAP objective}
=
\text{NLL}
-\log p(\theta)
$$

이 식에서 \(-\log p(\theta)\)가 regularization penalty처럼 작동한다.

## 17. Gaussian Prior와 L2 Regularization

parameter에 zero-mean Gaussian prior를 둔다고 하자.

$$
p(\theta)
=
\mathcal{N}(\theta\mid 0,\tau^2 I)
$$

그러면

$$
p(\theta)
\propto
\exp\left(
-\frac{\lVert\theta\rVert^2}{2\tau^2}
\right)
$$

이고 negative log prior는 다음과 같다.

$$
-\log p(\theta)
=
\frac{1}{2\tau^2}\lVert\theta\rVert^2
+\mathrm{constant}
$$

따라서 MAP objective는 다음 형태가 된다.

$$
\text{NLL}
+\lambda\lVert\theta\rVert^2
$$

즉, Gaussian prior는 L2 regularization과 대응된다. prior가 parameter를 0 근처에 두고 싶어하는 믿음이라면, L2 penalty는 parameter가 지나치게 커지는 것을 막는 최적화 항이다. 같은 현상을 확률 관점과 최적화 관점에서 다르게 보는 셈이다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 데이터 벡터화란? | 원본 데이터를 feature vector 또는 feature matrix로 바꾸는 과정 |
| continuous feature를 평균 0, 분산 1로 맞추는 이유는? | scale 차이를 줄이고 gradient 기반 학습을 안정화하기 위해 |
| deterministic model과 probabilistic model의 차이는? | 전자는 예측값 하나, 후자는 예측 분포와 불확실성까지 출력 |
| learning의 세 단계는? | training/parameter estimation, hyperparameter tuning/model selection, prediction/inference |
| ERM이 최소화하는 것은? | training data에 대한 평균 loss, 즉 empirical risk |
| 우리가 진짜 원하는 성능은? | training data가 아니라 unseen data에 대한 generalization |
| regularization의 목적은? | overfitting을 줄이고 단순한 해를 선호하기 위해 |
| cross validation의 목적은? | validation 성능 추정을 더 안정적으로 하기 위해 |
| MLE는 무엇을 최대화하는가? | 관측 데이터 likelihood |
| Gaussian error에서 MLE는 어떤 loss와 연결되는가? | squared error |
| MAP와 regularization의 연결은? | prior의 negative log가 regularization penalty처럼 작동 |
| Gaussian prior와 L2 regularization의 관계는? | zero-mean Gaussian prior의 negative log가 \(\lVert\theta\rVert^2\)에 비례 |

## Study Guide

원자료를 vectorize·standardize한 뒤 train/validation/test 역할을 분리하고, ERM이 training loss를 낮춰도 generalization을 보장하지 않는 이유를 먼저 확인한다. Gaussian observation error의 likelihood에 negative log를 취해 squared error가 나오는 과정을 재현하고, Gaussian prior가 L2 penalty로 바뀌는 MAP 연결까지 이어 간다. cross validation은 model selection용이며 test set을 반복 선택에 쓰면 leakage가 생긴다는 점을 우선 점검한다.

## 복습 질문

<details>
<summary>1. Training error가 낮은데 validation error가 높다면 어떤 문제가 의심되는가?</summary>

답변: overfitting이 의심된다. 모델이 training data에는 잘 맞지만 unseen data를 대표하는 validation data에는 일반화하지 못하는 상황이다. regularization, early stopping, 데이터 보강, 모델 복잡도 조절을 고려할 수 있다.

</details>

<details>
<summary>2. ERM에서 i.i.d. 가정이 왜 중요한가?</summary>

답변: training data가 같은 분포에서 독립적으로 뽑혔다고 볼 수 있어야 empirical risk가 true risk의 근사로 의미를 가진다. 데이터가 편향되어 있거나 sample들이 강하게 의존적이면 training 평균 loss가 실제 unseen data 성능을 잘 대표하지 못한다.

</details>

<details>
<summary>3. Squared error를 쓰는 선형 회귀가 ERM의 예가 되는 이유를 설명하라.</summary>

답변: 선형 회귀는 \(f(x,\theta)=\theta^Tx+\theta_0\) 같은 함수로 예측하고, squared error로 예측값과 실제값의 차이를 측정한다. training data 전체에 대한 평균 squared error를 최소화하는 parameter를 찾으므로 ERM의 한 예다.

</details>

<details>
<summary>4. MLE에서 likelihood 곱 대신 log-likelihood 합을 쓰는 이유는 무엇인가?</summary>

답변: i.i.d. sample의 likelihood는 확률들의 곱으로 표현된다. 곱은 수치적으로 매우 작아져 underflow가 생기기 쉽고 미분도 불편하다. log를 취하면 곱이 합으로 바뀌어 계산과 최적화가 쉬워지며, log는 단조 증가 함수라 최댓값 위치가 유지된다.

</details>

<details>
<summary>5. Gaussian observation error에서 squared error가 나오는 이유는 무엇인가?</summary>

답변: \(p(y_n\mid x_n,\theta)=\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)\)로 두면 negative log-likelihood 안에 \((y_n-x_n^T\theta)^2/(2\sigma^2)\)가 생긴다. \(\theta\)와 무관한 constant를 제외하면 squared error 합을 최소화하는 문제가 된다.

</details>

<details>
<summary>6. Gaussian prior와 L2 regularization이 어떻게 연결되는지 설명하라.</summary>

답변: parameter에 zero-mean Gaussian prior를 두면 \(-\log p(\theta)\)가 \(\lVert\theta\rVert^2\)에 비례한다. MAP objective는 NLL에 \(-\log p(\theta)\)를 더한 형태이므로, 결과적으로 \(\lambda\lVert\theta\rVert^2\) 같은 L2 penalty가 생긴다.

</details>

<details>
<summary>7. Cross validation은 validation set 하나만 쓰는 것과 비교해 어떤 장점이 있는가?</summary>

답변: validation set 하나만 쓰면 특정 split에 따라 성능 평가가 흔들릴 수 있다. Cross validation은 validation fold를 바꿔가며 여러 번 평가하므로 model selection과 hyperparameter tuning에서 더 안정적인 성능 추정치를 얻을 수 있다. 대신 여러 번 학습해야 하므로 계산 비용은 증가한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-15.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-15.pdf</a></li>
</ul>
