---
layout: default
title: "Lecture 16 Probabilistic Modeling and Model Selection"
course: "Machine Learning Basic"
topic: "Probabilistic Modeling and Model Selection"
order: 16
---

# Lecture 16 Probabilistic Modeling and Model Selection

Source PDF: `machine-learning-basic-lecture-16.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | ERM 복습 | training data에 대한 평균 loss를 최소화한다는 말은 무엇인가? |
| 2 | Regularization과 MAP | penalty를 추가하는 최적화와 prior를 넣는 확률 추정은 어떻게 연결되는가? |
| 3 | 확률적 모델링 | 머신러닝에서 왜 확률분포를 모델의 언어로 쓰는가? |
| 4 | 세 가지 불확실성 | observation, model, prediction 단계의 불확실성은 어떻게 다른가? |
| 5 | 잠재 변수 | 직접 보이지 않는 숨은 요인을 어떻게 모델 안에 넣는가? |
| 6 | Directed Graphical Model | 복잡한 확률 관계를 그래프로 어떻게 표현하는가? |
| 7 | Model Selection | 여러 모델 후보 중 무엇을 기준으로 하나를 고르는가? |
| 8 | Nested Cross Validation | model selection 과정에서 test leakage를 어떻게 막는가? |
| 9 | Occam's razor | Bayesian model comparison은 단순한 모델을 왜 선호할 수 있는가? |

16강은 15강에서 정리한 ERM, regularization, MLE, MAP를 확률적 모델링이라는 더 큰 틀로 확장한다. 핵심은 모델을 단순히 하나의 함수 \\(f_\theta(x)\\)로 보지 않고, 관측의 noise, parameter의 불확실성, 잠재 변수, 모델 후보의 선택까지 확률분포로 표현하는 것이다.

## 1. ERM 복습: 데이터를 잘 설명하는 함수 찾기

지도학습에서는 보통 다음과 같은 학습 데이터를 가진다.

$$
\mathcal{D}
=\{(x_1,y_1),(x_2,y_2),\ldots,(x_N,y_N)\}
$$

목표는 입력 \\(x\\)가 주어졌을 때 출력 \\(y\\)를 잘 예측하는 함수 \\(f(x,\theta)\\)를 찾는 것이다. 여기서 \\(\theta\\)는 모델의 parameter다.

각 sample에 대해 예측값 \\(f(x_i,\theta)\\)와 실제 label \\(y_i\\)가 얼마나 다른지 측정하는 함수를 loss function이라고 한다.

$$
\ell(f(x_i,\theta),y_i)
$$

Training data 전체에 대한 평균 loss는 empirical risk다.

$$
R_{\mathrm{emp}}(\theta,X,Y)
=
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
$$

Empirical Risk Minimization(ERM)은 이 값을 최소화하는 parameter를 찾는 과정이다.

$$
\theta^*
=
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
$$

이때 중요한 가정은 학습 데이터가 i.i.d.라는 것이다. 각 데이터가 같은 data-generating distribution에서 독립적으로 뽑혔다고 볼 수 있어야 training 평균 loss가 unseen data에서의 평균 성능을 어느 정도 대표할 수 있다.

## 2. Regularization: 과적합을 막는 penalty

ERM만 사용하면 모델이 training data의 noise나 우연한 패턴까지 외울 수 있다. 이를 overfitting이라고 한다. Overfitting을 확인하려면 training data와 별도로 validation data를 두고 두 loss를 비교한다.

| 상황 | 해석 |
|---|---|
| training loss 낮음, validation loss 낮음 | 일반화가 비교적 잘 됨 |
| training loss 낮음, validation loss 높음 | training data에 과적합했을 가능성이 큼 |
| training loss 높음, validation loss 높음 | 모델이 너무 단순하거나 학습이 부족할 가능성이 큼 |

Regularization은 objective에 parameter penalty를 추가해 너무 복잡한 해를 피하게 만든다.

$$
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f(x_i,\theta),y_i)
+\lambda\lVert\theta\rVert^2
$$

여기서 \\(\lambda\\)는 regularization strength다. \\(\lambda\\)가 작으면 penalty가 약해서 overfitting을 충분히 막지 못할 수 있고, 너무 크면 모델이 데이터의 실제 패턴도 못 따라가는 underfitting이 생길 수 있다.

## 3. 변수 추정: 확률분포로 예측할 때

예측값을 하나의 숫자로만 내는 것이 아니라 확률분포로 모델링하면 parameter estimation 관점이 필요하다. 데이터가 어떤 확률분포에서 생성되었다고 보고, 그 분포의 parameter \\(\theta\\)를 추정하는 방식이다.

Maximum Likelihood Estimation(MLE)은 관측된 데이터가 가장 그럴듯해지는 parameter를 고른다.

$$
\theta_{\mathrm{MLE}}
=
\arg\max_{\theta}
p(x\mid\theta)
$$

실제 최적화에서는 likelihood를 직접 최대화하기보다 negative log-likelihood를 최소화하는 형태를 자주 쓴다.

$$
L_x(\theta)
=
-\log p(x\mid\theta)
$$

데이터가 여러 개이고 i.i.d.라고 가정하면 likelihood는 곱으로 분해되고, log-likelihood는 합으로 바뀐다.

$$
p(\mathcal{D}\mid\theta)
=
\prod_{n=1}^{N}
p(x_n\mid\theta)
$$

$$
-\log p(\mathcal{D}\mid\theta)
=
-\sum_{n=1}^{N}
\log p(x_n\mid\theta)
$$

곱을 합으로 바꾸면 수치적으로 안정적이고 미분하기도 쉬워진다.

## 4. MAP: Regularization의 확률적 해석

Maximum A Posteriori(MAP)는 likelihood뿐 아니라 parameter에 대한 prior belief까지 사용한다.

$$
p(\theta\mid x)
=
\frac{p(x\mid\theta)p(\theta)}{p(x)}
$$

Parameter \\(\theta\\)를 고르는 문제에서는 \\(p(x)\\)가 \\(\theta\\)에 대해 constant이므로 다음 비례식만 보면 된다.

$$
p(\theta\mid x)
\propto
p(x\mid\theta)p(\theta)
$$

MAP는 posterior를 최대화하는 parameter를 고른다.

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
p(x\mid\theta)p(\theta)
$$

negative log를 취하면 다음 최소화 문제가 된다.

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

여기서 \\(-\log p(\theta)\\)는 regularization penalty처럼 작동한다. 예를 들어 \\(\theta\\)에 zero-mean Gaussian prior를 두면 \\(-\log p(\theta)\\)가 \\(\lVert\theta\rVert^2\\)에 비례하므로 L2 regularization과 같은 형태가 된다.

## 5. 왜 확률적 모델링을 배우는가

강의는 확률적 모델링을 배우는 이유를 하나의 통합 프레임워크로 설명한다. 확률은 모델링, inference, parameter estimation, model selection을 같은 언어로 묶어준다.

| 작업 | 확률적 관점 |
|---|---|
| Modeling | 데이터가 어떤 확률분포에서 생성되는지 가정한다. |
| Inference | 관측된 데이터로부터 보이지 않는 값이나 새로운 예측을 계산한다. |
| Parameter estimation | likelihood, posterior를 이용해 parameter를 추정한다. |
| Model selection | evidence나 validation 성능으로 모델 후보를 비교한다. |

심지어 ERM도 확률 모델과 연결된다. 예를 들어 Gaussian observation noise를 가정하면 squared error minimization이 MLE와 같은 문제가 된다. 따라서 loss를 최소화한다는 결정론적 표현 뒤에도 어떤 noise assumption이나 확률적 해석이 숨어 있을 수 있다.

## 6. 확률이 쓰이는 세 가지 level

머신러닝에서 확률은 크게 세 가지 level에서 쓰인다.

| level | 의미 | 대표 표현 |
|---|---|---|
| Observation uncertainty | 같은 입력에서도 관측값이 noise 때문에 흔들릴 수 있다. | \\(y_n=x_n^T\theta+\epsilon\\) |
| Model uncertainty | 데이터가 부족하면 parameter나 모델 자체에 대한 확신이 낮다. | \\(p(\theta)\\), \\(p(\theta\mid\mathcal{D})\\) |
| Predictive uncertainty | 새 입력에 대해 가능한 출력의 분포를 계산한다. | \\(p(y_*\mid x_*,\mathcal{D})\\) |

Observation uncertainty는 데이터 측정 과정의 noise를 다룬다. Model uncertainty는 parameter를 하나의 점 추정값으로 고정하지 않고 분포로 다룬다. Predictive uncertainty는 이 둘을 반영해 새로운 입력에 대한 예측 분포를 만든다.

## 7. Observation Uncertainty

가장 기본적인 확률적 회귀 모델은 관측값이 참 모델 출력에 noise가 더해진 값이라고 본다.

$$
y_n
=
x_n^T\theta+\epsilon
$$

$$
\epsilon
\sim
\mathcal{N}(0,\sigma^2)
$$

이 경우 조건부 분포는 다음과 같다.

$$
p(y_n\mid x_n,\theta)
=
\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

이 모델에서 \\(\sigma^2\\)는 관측 noise의 크기를 나타낸다. \\(\sigma^2\\)가 작으면 같은 \\(x_n\\)에서 \\(y_n\\)이 모델 예측 주변에 좁게 모인다고 보는 것이고, \\(\sigma^2\\)가 크면 관측값이 더 넓게 흔들릴 수 있다고 보는 것이다.

## 8. Model Uncertainty와 Bayesian Prediction

MLE나 일반적인 ERM은 보통 하나의 parameter \\(\hat{\theta}\\)를 고른다. 그러나 데이터가 적거나 noise가 크면 여러 parameter가 비슷하게 그럴듯할 수 있다. Bayesian 관점에서는 parameter 자체를 확률변수처럼 두고 posterior를 계산한다.

$$
p(\theta\mid\mathcal{D})
$$

새로운 입력 \\(x_*\\)에 대한 예측은 특정 parameter 하나에만 의존하지 않고 가능한 모든 parameter에 대해 평균낸다.

$$
p(y_*\mid x_*,\mathcal{D})
=
\int
p(y_*\mid x_*,\theta)
p(\theta\mid\mathcal{D})
d\theta
$$

이 식은 Bayesian prediction의 핵심이다. \\(\theta\\)가 확실하면 posterior가 좁아져 거의 하나의 모델로 예측하는 것과 비슷해지고, \\(\theta\\)가 불확실하면 여러 가능한 모델의 예측이 함께 반영된다.

실제 딥러닝에서는 이 적분을 정확히 계산하기 어렵기 때문에 다음과 같은 근사를 사용한다.

| 방법 | 직관 |
|---|---|
| Point estimate | \\(p(\theta\mid\mathcal{D})\\)를 하나의 \\(\hat{\theta}\\)로 근사한다. |
| Deep Ensemble | 여러 모델을 학습해 parameter 불확실성을 경험적으로 근사한다. |
| Variational Inference | 다루기 쉬운 분포로 posterior를 근사한다. |

## 9. 잠재 변수

잠재 변수(latent variable)는 직접 관찰하거나 측정할 수 없지만 데이터 생성 과정에 영향을 준다고 보는 숨은 요인이다.

넷플릭스 추천 예시를 생각하면 관측 변수는 사용자가 실제로 클릭한 영상 목록이다.

$$
\text{clicked movies}
=
\{\text{Avengers},\text{Iron Man},\text{Spider-Man}\}
$$

반면 잠재 변수는 사용자의 취향을 설명하는 숨은 요인일 수 있다.

$$
z
=
\text{Marvel fan}
$$

이 \\(z\\)는 데이터에 직접 적혀 있지 않지만, 클릭 패턴을 설명하고 다음에 어떤 영상을 추천할지 예측하는 데 중요하다. 머신러닝에서는 이처럼 보이지 않는 구조를 모델 안에 넣어 관측 데이터를 더 잘 설명하려고 한다.

## 10. 동전 던지기에서의 잠재 변수

동전 던지기에서는 관측값이 앞면인지 뒷면인지다.

$$
x_n\in\{0,1\}
$$

하지만 앞으로 앞면이 얼마나 자주 나올지 예측하려면 숨은 값인 앞면 확률 \\(\mu\\)를 알아야 한다.

$$
\mu
=
P(x=1)
$$

이때 \\(\mu\\)는 직접 관측되는 값이 아니라 관측된 던지기 결과로부터 추정해야 하는 latent variable 또는 parameter로 볼 수 있다. 동전이 공정한지 아닌지, 앞면이 나올 확률이 어느 정도인지가 바로 데이터 뒤의 숨은 규칙이다.

## 11. 잠재 변수를 이용한 예측과 Evidence

잠재 변수 또는 parameter \\(\theta\\)를 명시적으로 두면 예측 분포는 다음처럼 쓴다.

$$
p(y_*\mid x_*,\mathcal{D})
=
\int
p(y_*\mid x_*,\theta)
p(\theta\mid\mathcal{D})
d\theta
$$

계산이 어려우면 posterior 전체를 쓰지 않고 하나의 대표값 \\(\hat{\theta}\\)로 근사하기도 한다.

$$
p(y_*\mid x_*,\mathcal{D})
\approx
p(y_*\mid x_*,\hat{\theta})
$$

Model selection에서는 특정 모델이 데이터를 얼마나 그럴듯하게 설명하는지 보는 evidence가 중요하다.

$$
p(\mathcal{D})
=
\int
p(\mathcal{D}\mid\theta)
p(\theta)
d\theta
$$

Evidence는 가능한 parameter 전체에 대해 likelihood를 prior로 가중 평균한 값이다. 단순히 best parameter 하나에서의 성능만 보는 것이 아니라, 그 모델이 가정하는 parameter 공간 전체가 데이터를 얼마나 자연스럽게 설명하는지를 평가한다.

## 12. Directed Graphical Models

Directed Graphical Model(DGM)은 확률변수들 사이의 조건부 의존 관계를 방향성이 있는 그래프로 표현한 확률 모델이다. 그래프의 node는 확률변수이고, arrow는 조건부 의존 관계를 나타낸다.

세 변수 \\(a,b,c\\)가 fully connected 형태로 의존한다고 하면 joint distribution은 chain rule로 다음처럼 분해할 수 있다.

$$
p(a,b,c)
=
p(c\mid a,b)p(b\mid a)p(a)
$$

그래프가 fully connected가 아니면 joint distribution은 더 단순하게 factorization된다. 예를 들어 \\(x_1,x_2,x_3,x_4,x_5\\)의 관계가 일부 arrow만 가진다면 다음처럼 쓸 수 있다.

$$
p(x_1,x_2,x_3,x_4,x_5)
=
p(x_1)p(x_5)p(x_2\mid x_5)
p(x_3\mid x_1,x_2)
p(x_4\mid x_2)
$$

DGM의 장점은 복잡한 joint distribution을 작은 conditional distribution들의 곱으로 나눌 수 있다는 점이다. 이는 모델을 해석하기 쉽게 만들고, 필요한 계산을 줄여준다.

## 13. DGM 예시: 동전 던지기

동전 던지기에서 앞면이 나올 확률을 \\(\mu\\)라고 하자.

$$
p(x\mid\mu)
=
\operatorname{Ber}(\mu)
$$

\\(N\\)번 독립적으로 동전을 던졌다면 likelihood는 다음처럼 곱으로 분해된다.

$$
p(x_1,\ldots,x_N\mid\mu)
=
\prod_{n=1}^{N}
p(x_n\mid\mu)
$$

그래프로 보면 \\(\mu\\)가 각 관측값 \\(x_1,\ldots,x_N\\)을 생성하는 부모 node가 된다. Bayesian 모델에서는 \\(\mu\\) 자체에도 prior를 둘 수 있다.

$$
p(\mu\mid\alpha)
$$

여기서 \\(\alpha\\)는 prior의 모양을 정하는 hyperparameter다. 이 구조는 “동전의 앞면 확률이 먼저 정해지고, 그 확률에 따라 여러 번의 관측값이 생성된다”는 이야기를 그래프로 표현한 것이다.

## 14. Model Selection

하나의 문제를 풀 때 사용할 수 있는 모델은 여러 가지다.

| 모델 후보 | 특징 |
|---|---|
| Linear model | 단순하고 해석이 쉽지만 복잡한 패턴을 놓칠 수 있다. |
| Quadratic polynomial | 곡선 형태의 관계를 표현할 수 있다. |
| \\(k\\)-th polynomial | \\(k\\)가 커질수록 더 복잡한 함수를 표현할 수 있다. |
| Neural network | 매우 유연하지만 과적합과 해석 문제가 생길 수 있다. |

Model selection은 이 후보들 중 어떤 모델을 사용할지 고르는 과정이다. Training data에 대한 성능만 보면 복잡한 모델이 유리해지기 쉽다. 따라서 validation 성능, cross validation, Bayesian evidence 같은 기준이 필요하다.

## 15. Nested Cross Validation

강의 슬라이드에는 “test data에서 가장 좋은 성능을 내는 모델”이라는 표현이 나온다. 그러나 실제 절차에서는 test data를 model selection에 직접 쓰면 안 된다. Test data는 최종 평가용으로 마지막까지 숨겨두어야 한다.

Nested cross validation의 핵심은 model selection을 위한 validation 절차와 최종 성능 추정을 위한 test 절차를 분리하는 것이다.

1. 전체 labeled data를 outer train/test split으로 나눈다.
2. Outer training data 안에서 다시 inner train/validation split 또는 K-fold CV를 수행한다.
3. Inner validation 성능으로 모델 종류나 hyperparameter를 선택한다.
4. 선택된 모델을 outer training data로 다시 학습한다.
5. Outer test data에서 최종 성능을 평가한다.

이 구조를 쓰면 test data를 보고 모델을 고르는 test leakage를 줄일 수 있다. 특히 모델 후보와 hyperparameter 후보가 많을수록 validation set에 우연히 잘 맞는 선택이 생기기 쉬우므로, 최종 test set을 엄격하게 분리하는 것이 중요하다.

## 16. Occam's Razor

Occam's razor는 어떤 현상을 설명할 때 불필요한 가정을 최소화하고 가능한 단순한 설명을 선택하라는 원칙이다. 머신러닝에서는 이 원칙이 model selection과 regularization에 자연스럽게 연결된다.

단순한 모델은 표현력이 제한되어 underfitting될 수 있지만, 데이터가 많지 않은 상황에서는 복잡한 모델보다 안정적으로 일반화할 수 있다. 반대로 복잡한 모델은 training data를 매우 잘 맞출 수 있지만, noise까지 외우면 unseen data 성능이 떨어질 수 있다.

따라서 좋은 모델 선택은 무조건 단순한 모델을 고르는 것도 아니고, 무조건 복잡한 모델을 고르는 것도 아니다. 데이터가 요구하는 패턴을 설명할 만큼 충분히 유연하되, 불필요하게 복잡하지 않은 모델을 고르는 것이다.

## 17. Bayesian Model Comparison

Bayesian 관점에서는 모델 자체도 확률적으로 비교할 수 있다. 두 모델 \\(M_1\\), \\(M_2\\)가 있을 때 posterior odds는 다음과 같다.

$$
\frac{p(M_1\mid\mathcal{D})}{p(M_2\mid\mathcal{D})}
=
\frac{
\frac{p(\mathcal{D}\mid M_1)p(M_1)}{p(\mathcal{D})}
}{
\frac{p(\mathcal{D}\mid M_2)p(M_2)}{p(\mathcal{D})}
}
$$

공통 분모 \\(p(\mathcal{D})\\)는 약분되어 다음처럼 정리된다.

$$
\frac{p(M_1\mid\mathcal{D})}{p(M_2\mid\mathcal{D})}
=
\frac{
p(M_1)p(\mathcal{D}\mid M_1)
}{
p(M_2)p(\mathcal{D}\mid M_2)
}
$$

여기서 \\(p(M_i)\\)는 모델 prior, \\(p(\mathcal{D}\mid M_i)\\)는 해당 모델의 evidence다.

$$
p(\mathcal{D}\mid M)
=
\int
p(\mathcal{D}\mid\theta,M)
p(\theta\mid M)
d\theta
$$

Evidence는 모델의 fit과 complexity를 동시에 반영한다. 너무 유연한 모델은 많은 데이터 형태를 설명할 수 있지만, 그만큼 prior probability mass가 넓게 퍼진다. 실제 관측 데이터 주변에 충분한 확률 질량을 두지 못하면 evidence가 낮아질 수 있다. 그래서 Bayesian model comparison은 복잡한 모델에 자동으로 complexity penalty를 주는 효과가 있다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| ERM이 최소화하는 값은? | training data 전체의 평균 loss, 즉 empirical risk |
| ERM에서 i.i.d. 가정이 필요한 이유는? | empirical risk가 true risk의 근사로 의미를 가지려면 data가 같은 분포에서 독립적으로 나와야 하기 때문 |
| Regularization과 MAP의 연결은? | MAP objective의 \\(-\log p(\theta)\\)가 penalty처럼 작동한다. |
| MLE와 MAP의 차이는? | MLE는 likelihood만 보고, MAP는 likelihood와 prior를 함께 본다. |
| 확률적 모델링의 장점은? | modeling, inference, parameter estimation, model selection을 하나의 확률 언어로 묶는다. |
| latent variable이란? | 직접 관측되지 않지만 데이터 생성과 예측에 영향을 주는 숨은 변수 |
| DGM의 목적은? | 조건부 의존 관계를 그래프로 표현하고 joint distribution을 factorization하기 위해 |
| Nested CV의 핵심은? | model selection용 validation과 최종 평가용 test를 분리해 test leakage를 막는 것 |
| Occam's razor의 의미는? | 불필요한 가정을 줄이고 데이터 설명에 충분한 가장 단순한 모델을 선호하는 원칙 |
| Bayesian evidence의 역할은? | parameter 전체에 대한 평균 likelihood로 fit과 complexity를 함께 평가한다. |

## 복습 질문

<details>
<summary>1. ERM과 MLE는 어떤 점에서 연결될 수 있는가?</summary>

답변: 특정 noise distribution을 가정하면 MLE가 특정 loss를 최소화하는 ERM과 같은 문제가 될 수 있다. 예를 들어 Gaussian observation noise를 가정하면 negative log-likelihood 안에 squared error가 생기므로, squared error를 최소화하는 선형 회귀는 Gaussian likelihood에서의 MLE로 해석할 수 있다.

</details>

<details>
<summary>2. MAP objective에서 regularization penalty에 해당하는 항은 무엇인가?</summary>

답변: MAP objective는 \\(\text{NLL}-\log p(\theta)\\) 형태다. 여기서 \\(-\log p(\theta)\\)가 parameter prior에서 나온 penalty 역할을 한다. Gaussian prior를 두면 이 항이 \\(\lVert\theta\rVert^2\\)에 비례해 L2 regularization과 연결된다.

</details>

<details>
<summary>3. 머신러닝에서 확률이 쓰이는 세 가지 level을 설명하라.</summary>

답변: 첫째, observation uncertainty는 관측값이 noise 때문에 흔들리는 것을 표현한다. 둘째, model uncertainty는 parameter나 모델에 대한 불확실성을 \\(p(\theta\mid\mathcal{D})\\)처럼 분포로 표현한다. 셋째, predictive uncertainty는 새 입력의 출력 분포 \\(p(y_*\mid x_*,\mathcal{D})\\)를 계산하는 것이다.

</details>

<details>
<summary>4. Latent variable이 필요한 이유를 동전 던지기 예시로 설명하라.</summary>

답변: 동전 던지기에서 우리가 직접 보는 것은 앞면 또는 뒷면의 관측 결과다. 하지만 미래 결과를 예측하려면 앞면이 나올 확률 \\(\mu\\)를 알아야 한다. \\(\mu\\)는 직접 관측되는 값이 아니라 관측 결과 뒤에 숨어 있는 값이므로 latent variable 또는 parameter로 볼 수 있다.

</details>

<details>
<summary>5. Directed Graphical Model을 쓰면 무엇이 좋아지는가?</summary>

답변: DGM은 확률변수 사이의 조건부 의존 관계를 그래프로 표현한다. 이를 통해 복잡한 joint distribution을 작은 conditional distribution들의 곱으로 factorization할 수 있고, 어떤 변수가 어떤 변수에 직접 의존하는지 해석하기 쉬워진다.

</details>

<details>
<summary>6. Nested cross validation에서 test data를 model selection에 쓰면 안 되는 이유는 무엇인가?</summary>

답변: test data를 보고 모델이나 hyperparameter를 고르면 test set에 우연히 잘 맞는 선택을 하게 되어 최종 성능 추정이 낙관적으로 치우친다. Nested CV는 inner validation에서 모델을 고르고 outer test에서 최종 평가를 하므로 test leakage를 줄인다.

</details>

<details>
<summary>7. Bayesian evidence가 복잡한 모델에 penalty를 줄 수 있는 이유는 무엇인가?</summary>

답변: Evidence는 특정 best parameter에서의 성능만 보지 않고, parameter 전체에 대해 likelihood를 prior로 가중 평균한다. 복잡한 모델은 가능한 데이터 형태가 많아 probability mass가 넓게 퍼지므로, 실제 관측 데이터 주변에 충분한 질량을 두지 못하면 evidence가 낮아진다. 그래서 fit이 좋아도 불필요하게 복잡한 모델은 불리해질 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-16.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-16.pdf</a></li>
</ul>
