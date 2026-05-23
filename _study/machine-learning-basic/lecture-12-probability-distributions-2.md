---
layout: default
title: "Lecture 12 Probability Distributions 2"
course: "Machine Learning Basic"
topic: "Probability Distributions 2"
order: 12
---

# Lecture 12 Probability Distributions 2

Source PDF: `machine-learning-basic-lecture-12.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 독립 확률변수 | joint distribution이 언제 marginal distribution들의 곱으로 분리되는가? |
| 2 | IID | 머신러닝 데이터가 서로 독립이고 같은 분포에서 왔다고 가정한다는 말은 무엇인가? |
| 3 | Bayes' Theorem | 관측한 증거를 이용해 원인이나 parameter에 대한 믿음을 어떻게 갱신하는가? |
| 4 | Bayesian ML | prior, likelihood, posterior, predictive distribution은 어떻게 연결되는가? |
| 5 | 기대값과 분산 | 확률분포의 대표값과 퍼짐은 어떻게 계산하는가? |
| 6 | 공분산과 상관관계 | 두 확률변수가 함께 움직이는 정도를 어떻게 수치화하는가? |
| 7 | 기대값의 성질 | 독립성, 선형성, total variance는 계산을 어떻게 단순화하는가? |

12강은 11강의 확률변수, PMF/PDF, joint distribution, conditional distribution을 바탕으로 한다. 핵심은 확률분포를 단순히 정의하는 데서 끝나지 않고, 머신러닝에서 실제로 계산하고 싶은 값인 `likelihood`, `posterior`, `expectation`, `variance`, `covariance`로 이어지는 것이다.

## 1. 독립 확률변수

두 확률변수 `X`, `Y`가 독립이라는 말은 `Y`를 알게 되어도 `X`에 대한 확률적 믿음이 바뀌지 않는다는 뜻이다. 이산확률변수에서는 다음 조건으로 표현한다.

```text
P(X = x, Y = y) = P(X = x) P(Y = y)
```

즉, joint PMF가 두 marginal PMF의 곱으로 분해되면 독립이다. 같은 내용을 조건부 확률로 쓰면 다음과 같다.

```text
P(X = x | Y = y) = P(X = x)
```

`Y = y`라는 정보를 알고 있어도 `X = x`의 확률이 그대로라면, `Y`는 `X`를 예측하는 데 정보를 주지 못한다.

연속확률변수에서는 PMF 대신 PDF를 사용한다.

```text
f_XY(x, y) = f_X(x) f_Y(y)
```

독립성은 단순히 두 사건이 동시에 일어날 가능성이 작거나 크다는 문제가 아니다. 중요한 것은 결합분포가 주변분포의 곱으로 정확히 분해되는지다.

## 2. 독립성 예시: 성별과 안경 착용 여부

강의에서는 성별과 안경 착용 여부의 joint probability table을 통해 독립 여부를 확인한다.

### 독립인 경우

|  | 착용 | 미착용 | 합 |
|---|---:|---:|---:|
| 남성 | 0.18 | 0.42 | 0.60 |
| 여성 | 0.12 | 0.28 | 0.40 |
| 합 | 0.30 | 0.70 | 1.00 |

남성이면서 안경을 착용할 확률은 `0.18`이다. 주변확률의 곱을 계산하면 다음과 같다.

```text
P(남성) P(착용) = 0.60 * 0.30 = 0.18
```

다른 칸도 모두 같은 방식으로 맞는다.

```text
P(남성, 미착용) = 0.60 * 0.70 = 0.42
P(여성, 착용) = 0.40 * 0.30 = 0.12
P(여성, 미착용) = 0.40 * 0.70 = 0.28
```

따라서 이 표에서는 성별과 안경 착용 여부가 독립이다.

### 독립이 아닌 경우

|  | 착용 | 미착용 | 합 |
|---|---:|---:|---:|
| 남성 | 0.25 | 0.35 | 0.60 |
| 여성 | 0.05 | 0.35 | 0.40 |
| 합 | 0.30 | 0.70 | 1.00 |

주변확률은 이전 표와 같지만, 남성이면서 안경을 착용할 확률은 `0.25`다.

```text
P(남성) P(착용) = 0.60 * 0.30 = 0.18
P(남성, 착용) = 0.25
```

두 값이 다르므로 독립이 아니다. 이 예시는 주변확률만 보고 독립성을 판단할 수 없고, joint probability를 직접 확인해야 한다는 점을 보여준다.

## 3. IID의 의미

`IID`는 `independent and identically distributed`의 약자다. 여러 확률변수 `X_1, X_2, ..., X_n`이 있을 때 다음 두 조건을 모두 만족한다는 뜻이다.

| 조건 | 의미 |
|---|---|
| independent | 각 표본이 서로 영향을 주지 않는다. |
| identically distributed | 모든 표본이 같은 확률분포를 따른다. |

IID라면 결합분포가 각 표본의 확률을 모두 곱한 형태로 정리된다.

```text
P(X_1 = x_1, ..., X_n = x_n) = product_i p_X(x_i)
```

연속확률변수에서도 같은 방식으로 joint PDF가 각 PDF의 곱으로 분해된다.

```text
f(x_1, ..., x_n) = product_i f_X(x_i)
```

머신러닝에서 `training data가 IID sample이다`라고 말할 때는 보통 모든 데이터가 같은 데이터 생성 과정에서 나왔고, 한 데이터가 다른 데이터의 값을 직접 결정하지 않는다고 가정한다. 이 가정 덕분에 likelihood를 곱 형태로 쓸 수 있다.

## 4. Bayes' Theorem

Bayes' theorem은 조건부 확률을 뒤집어 계산하는 규칙이다. 이산확률변수에서는 다음과 같다.

```text
P(Y = y | X = x)
= P(X = x | Y = y) P(Y = y) / P(X = x)
```

각 항의 의미는 다음과 같다.

| 항 | 이름 | 의미 |
|---|---|---|
| `P(Y = y \| X = x)` | posterior | 증거 `X = x`를 본 뒤 `Y = y`일 확률 |
| `P(X = x \| Y = y)` | likelihood | `Y = y`라고 가정했을 때 증거 `X = x`가 관측될 가능성 |
| `P(Y = y)` | prior | 증거를 보기 전 `Y = y`에 대한 믿음 |
| `P(X = x)` | evidence | 증거 `X = x` 자체가 나타날 전체 확률 |

분모 `P(X = x)`는 posterior가 전체적으로 합이 1이 되도록 정규화하는 역할을 한다. 이산적인 경우에는 가능한 모든 `y_i`에 대해 다음처럼 계산할 수 있다.

```text
P(X = x) = sum_i P(X = x | Y = y_i) P(Y = y_i)
```

연속확률변수에서는 합 대신 적분을 쓴다.

```text
f_{Y|X}(y | x)
= f_{X|Y}(x | y) f_Y(y) / f_X(x)
```

그리고 evidence는 다음처럼 적분으로 계산한다.

```text
f_X(x) = integral f_{X|Y}(x | y') f_Y(y') dy'
```

핵심은 `원인 -> 결과` 방향의 확률을 알고 있을 때, 관측된 결과로부터 원인에 대한 확률을 갱신할 수 있다는 점이다.

## 5. Bayes' Theorem 예시: 췌장암 데이터

강의의 췌장암 예시는 base rate가 왜 중요한지 보여준다.

|  | 암 Yes | 암 No | 합 |
|---|---:|---:|---:|
| 증상 Yes | 1 | 10 | 11 |
| 증상 No | 0 | 99,989 | 99,989 |
| 합 | 1 | 99,999 | 100,000 |

증상이 있을 때 암일 확률은 다음과 같이 계산된다.

```text
P(Cancer | Symptom)
= P(Symptom | Cancer) P(Cancer) / P(Symptom)
```

여기서 표를 읽으면 다음과 같다.

```text
P(Symptom | Cancer) = 1
P(Cancer) = 1 / 100000
P(Symptom | not Cancer) = 10 / 99999
P(not Cancer) = 99999 / 100000
```

따라서

```text
P(Cancer | Symptom)
= (1 * 0.00001) / (1 * 0.00001 + (10 / 99999) * 0.99999)
= 1 / 11
```

증상이 암 환자에게 항상 나타난다고 해도, 암 자체가 매우 드물고 암이 아닌 사람에게도 증상이 나타날 수 있으면 posterior는 생각보다 작을 수 있다. 이것이 prior와 evidence를 무시하면 안 되는 이유다.

## 6. Bayesian Machine Learning

Bayesian machine learning에서는 모델 parameter `theta`를 하나의 고정된 미지수로만 보지 않고, 확률변수처럼 다룬다. 데이터를 보기 전에는 parameter에 대한 믿음인 prior distribution을 둔다.

```text
p(theta)
```

데이터 `X = {x_i}_{i=1}^n`이 parameter `theta`를 가진 모델에서 생성되었다고 가정하면, 조건부 확률 `P(X | theta)`를 likelihood라고 부른다.

데이터가 IID라고 가정하면 likelihood는 다음처럼 곱으로 분해된다.

```text
x_1, ..., x_n iid~ P(. | theta)
P(X | theta) = product_i P(x_i | theta)
```

Bayes' theorem을 parameter에 적용하면 posterior distribution을 얻는다.

```text
P(theta | X) = P(X | theta) p(theta) / p(X)
```

각 항은 다음처럼 읽으면 된다.

| 개념 | 의미 | 직관 |
|---|---|---|
| prior `p(theta)` | 데이터를 보기 전 parameter에 대한 믿음 | 어떤 parameter가 그럴듯한가? |
| likelihood `P(X \| theta)` | parameter가 주어졌을 때 현재 데이터가 나올 가능성 | 이 parameter가 데이터를 잘 설명하는가? |
| posterior `P(theta \| X)` | 데이터를 본 뒤 parameter에 대한 믿음 | 데이터까지 반영하면 어떤 parameter가 그럴듯한가? |
| evidence `p(X)` | 데이터가 나타날 전체 확률 | posterior를 정규화하는 값 |

일반적인 point estimate 방식은 가장 좋은 parameter 하나를 찾는 데 집중한다. Bayesian 관점은 가능한 parameter들의 분포를 유지하므로, 예측의 불확실성까지 표현할 수 있다.

새로운 입력 `x_*`가 들어왔을 때의 예측도 하나의 값이 아니라 분포로 계산한다.

```text
P(F(x_*) | X)
= integral P(F(x_*, theta) | theta) P(theta | X) dtheta
```

즉, 하나의 parameter만 골라 예측하는 것이 아니라 posterior가 그럴듯하다고 보는 여러 parameter의 예측을 평균적으로 반영한다.

## 7. 기대값, 평균, 분산

기대값은 확률변수에 어떤 함수 `g`를 적용했을 때의 평균적인 값을 뜻한다.

이산확률변수에서는 다음과 같이 계산한다.

```text
E[g(X)] = sum_x g(x) p_X(x)
```

연속확률변수에서는 합 대신 적분을 사용한다.

```text
E[g(X)] = integral g(x) f_X(x) dx
```

`g(x) = x`인 경우를 평균이라고 부른다.

```text
E[X]
```

분산은 확률변수가 평균 주변에서 얼마나 퍼져 있는지를 나타낸다.

```text
Var(X) = E[(X - E[X])^2]
```

계산할 때는 다음 등가식을 자주 사용한다.

```text
Var(X) = E[X^2] - E[X]^2
```

분산이 크면 값들이 평균에서 멀리 흩어져 있고, 분산이 작으면 평균 근처에 몰려 있다.

## 8. 기대값 예시: 주사위

공정한 주사위를 굴릴 때 각 눈이 나올 확률은 `1/6`이다.

```text
E[X] = sum_{i=1}^6 (1/6)i
     = (1/6)(1+2+3+4+5+6)
     = 3.5
```

분산은 다음처럼 계산한다.

```text
E[X^2] = (1/6)(1^2+2^2+3^2+4^2+5^2+6^2)
       = 91/6

Var(X) = E[X^2] - E[X]^2
       = 91/6 - 49/4
       = 35/12
```

만약 `6`이 나올 확률이 `1/2`이고, `1`부터 `5`까지는 각각 `1/10`이라면 평균은 다음과 같다.

```text
E[X] = (1/2) * 6 + sum_{i=1}^5 (1/10)i
     = 3 + (1/10)(1+2+3+4+5)
     = 4.5
```

확률분포가 달라지면 가능한 값은 같아도 기대값이 달라진다.

## 9. 공분산과 상관관계

공분산은 두 확률변수 `X`, `Y`가 평균을 기준으로 함께 어떻게 움직이는지를 측정한다.

```text
Cov(X, Y) = E[(X - E[X])(Y - E[Y])]
```

연속확률변수에서는 joint PDF를 이용해 다음처럼 쓸 수 있다.

```text
Cov(X, Y)
= integral integral (x - E[X])(y - E[Y]) f_XY(x, y) dx dy
```

공분산의 부호는 다음처럼 해석한다.

| 공분산 | 해석 |
|---|---|
| 양수 | `X`가 평균보다 클 때 `Y`도 평균보다 큰 경향 |
| 음수 | `X`가 평균보다 클 때 `Y`는 평균보다 작은 경향 |
| 0 근처 | 선형적으로 함께 움직이는 경향이 약함 |

공분산은 단위의 영향을 받는다. 그래서 두 변수의 표준편차로 나누어 정규화한 값이 상관관계다.

```text
corr(X, Y) = Cov(X, Y) / sqrt(Var(X) Var(Y))
```

상관관계는 항상 `-1`과 `1` 사이에 있다.

| 상관관계 | 해석 |
|---|---|
| `1`에 가까움 | 강한 양의 선형 관계 |
| `-1`에 가까움 | 강한 음의 선형 관계 |
| `0`에 가까움 | 선형 관계가 약함 |

주의할 점은 `correlation = 0`이 항상 독립을 의미하지는 않는다는 것이다. 상관관계는 선형 관계만 측정하므로 비선형 의존성은 남아 있을 수 있다. 반대로 독립이면 일반적으로 공분산과 상관관계는 0이 된다.

## 10. 다변수 확률변수의 평균과 공분산 행렬

다변수 확률변수는 여러 확률변수를 하나의 벡터로 묶은 것이다.

```text
X = [X_1, ..., X_d]^T
```

평균도 벡터가 된다.

```text
E[X] = [E[X_1], ..., E[X_d]]^T
```

공분산은 행렬로 표현된다.

```text
Cov(X) = E[(X - E[X])(X - E[X])^T]
```

공분산 행렬의 구조는 다음과 같다.

```text
Cov(X) =
[ Var(X_1)        ...  Cov(X_1, X_d)
  ...
  Cov(X_d, X_1)   ...  Var(X_d)      ]
```

| 위치 | 의미 |
|---|---|
| 대각 원소 | 각 변수 자신의 분산 |
| 비대각 원소 | 서로 다른 두 변수의 공분산 |

공분산 행렬은 feature들이 어떤 방향으로 퍼져 있는지, 어떤 feature들이 함께 변하는지를 담는다. Gaussian model, PCA, whitening, Mahalanobis distance 같은 내용에서 계속 등장한다.

## 11. 기대값의 성질

기대값은 선형성을 가진다.

```text
E[aX + bY] = aE[X] + bE[Y]
```

이 성질은 `X`, `Y`가 독립이 아니어도 성립한다. 선형성은 기대값 계산에서 가장 자주 쓰이는 성질이다.

만약 `X`, `Y`가 독립이라면 곱의 기대값도 분리된다.

```text
E[XY] = E[X]E[Y]
```

분산은 다음 식으로 계산할 수 있다.

```text
Var(X) = E[X^2] - E[X]^2
```

또한 전체 분산 법칙은 다음과 같다.

```text
Var(Y) = E[Var(Y | X)] + Var(E[Y | X])
```

이 식은 전체 변동을 두 부분으로 나눈다.

| 항 | 의미 |
|---|---|
| `E[Var(Y \| X)]` | `X`가 고정되었을 때 남는 평균적인 내부 변동 |
| `Var(E[Y \| X])` | `X` 값에 따라 조건부 평균이 달라지는 변동 |

예를 들어 데이터를 여러 그룹으로 나누면, 전체 분산은 그룹 내부에서 생기는 분산과 그룹 평균들 사이의 분산으로 나눠 볼 수 있다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 독립의 정의는? | joint distribution이 marginal distribution들의 곱으로 분해되는 것 |
| IID는 무엇인가? | 서로 독립이고 같은 분포를 따르는 확률변수들의 집합 |
| Bayes theorem의 분모는 무엇을 하는가? | evidence로서 posterior를 정규화하며 가능한 원인을 모두 고려한다. |
| likelihood는 무엇인가? | parameter나 원인이 주어졌을 때 관측 데이터가 나올 조건부 확률 |
| posterior는 무엇인가? | 데이터를 본 뒤 parameter나 원인에 대해 갱신된 믿음 |
| 분산의 계산식은? | `Var(X) = E[(X-E[X])^2] = E[X^2] - E[X]^2` |
| covariance matrix의 대각/비대각 원소는? | 대각은 분산, 비대각은 변수 쌍의 공분산 |
| 상관관계가 0이면 독립인가? | 항상 그렇지는 않다. 선형 관계가 없다는 뜻에 가깝다. |
| total variance는 무엇을 분해하는가? | 전체 분산을 조건부 내부 분산과 조건부 평균의 분산으로 분해한다. |

## 복습 질문

1. `P(X, Y) = P(X)P(Y)`와 `P(X | Y) = P(X)`는 왜 같은 독립성의 표현인가?
2. 췌장암 예시에서 `P(Symptom | Cancer) = 1`인데도 `P(Cancer | Symptom)`이 `1/11`인 이유는 무엇인가?
3. Bayesian ML에서 prior가 강하고 데이터가 적으면 posterior는 어떤 모양이 되기 쉬운가?
4. `E[aX+bY] = aE[X]+bE[Y]`는 독립이 필요할까?
5. 공분산이 0인데도 두 변수가 독립이 아닐 수 있는 예시는 어떤 형태일까?
6. 공분산 행렬의 비대각 원소가 모두 0이면 feature들이 어떤 관계라고 해석할 수 있는가?

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-12.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-12.pdf</a></li>
</ul>
