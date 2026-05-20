---
layout: default
title: "Lecture 13 Probability Distributions 3"
course: "Machine Learning Basic"
topic: "Probability Distributions 3"
order: 13
---

# Lecture 13 Probability Distributions 3

Source PDF: `machine-learning-basic-lecture-13.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Gaussian distribution | 정규분포가 왜 머신러닝의 기본 분포인가? |
| 2 | Multivariate Gaussian | 평균 벡터와 공분산 행렬은 무엇을 정하는가? |
| 3 | Conditional/Marginal | 가우시안의 조건부분포와 주변분포는 어떻게 다뤄지는가? |
| 4 | Linear transformation | 가우시안 확률변수는 선형 변환 후에도 가우시안인가? |
| 5 | Change of variable | 변수 변환 후 분포는 어떻게 계산하는가? |

## 1. Gaussian distribution

Gaussian distribution, 또는 normal distribution은 실수 공간에서 정의되는 대표적인 연속 확률분포다.

평균 `mu`와 분산 `sigma^2`가 분포의 위치와 퍼짐을 결정한다. 평균이 0이고 분산이 1인 경우를 standard normal distribution이라고 한다.

Gaussian은 Gaussian process, variational inference, reinforcement learning, signal processing, control theory, random initialization, noise sampling 등에서 널리 사용된다.

## 2. Multivariate Gaussian

다변수 가우시안은 `n`차원 실수 공간에서 정의된다.

| parameter | 의미 |
|---|---|
| mean vector `mu` | 분포의 중심 |
| covariance matrix `Sigma` | 퍼짐, 방향, 변수 간 상관 구조 |

공분산 행렬의 고유벡터는 분포가 늘어난 방향, 고유값은 그 방향의 분산 크기와 연결된다.

## 3. Conditional and Marginal Distribution

다변수 가우시안에서는 일부 변수만 보는 marginal distribution과, 일부 변수를 관측했을 때의 conditional distribution이 중요하다.

Gaussian의 큰 장점은 marginal과 conditional도 다시 Gaussian 형태가 된다는 점이다. 이 성질은 Gaussian process, Bayesian linear regression 등에서 핵심적으로 쓰인다.

## 4. Gaussian random variables의 합

서로 독립인 Gaussian random variable의 선형 결합은 다시 Gaussian이다.

```text
z = a x + b y
```

이때 평균과 분산은 선형성과 독립성을 이용해 계산된다.

주의할 점은 Gaussian distribution들의 weighted sum, 즉 mixture는 일반적으로 Gaussian이 아니라는 점이다.

```text
p(x) = a p1(x) + (1-a) p2(x)
```

이는 Gaussian mixture model의 기반이다.

## 5. Linear transformation

가우시안 확률변수 `x`에 선형 변환을 적용하면 결과 `y = A x`도 Gaussian이다.

평균은 `A mu`, 공분산은 `A Sigma A^T` 형태로 변환된다.

이 성질은 데이터를 회전, 스케일링, projection할 때 분포가 어떻게 바뀌는지 이해하게 해준다.

## 6. Sampling

표준 정규분포에서 sampling할 수 있다면, 선형 변환을 통해 원하는 평균과 공분산을 가진 Gaussian sample을 만들 수 있다.

```text
z ~ N(0, I)
x = mu + L z
```

여기서 `L L^T = Sigma`가 되도록 잡으면 `x`는 평균 `mu`, 공분산 `Sigma`를 가진다.

## 7. Change of Variable

변수 변환은 확률변수 `x`가 있을 때 `y = u(x)`의 분포를 구하는 문제다.

이산확률변수에서는 같은 `y`를 만드는 모든 `x`의 확률을 더한다.

연속확률변수에서는 CDF를 먼저 계산한 뒤 미분하거나, 가역 변환이면 Jacobian을 이용한다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| standard normal distribution은? | 평균 0, 분산 1인 Gaussian |
| multivariate Gaussian의 parameter는? | mean vector와 covariance matrix |
| Gaussian의 선형 변환 결과는? | 다시 Gaussian |
| Gaussian mixture는 항상 Gaussian인가? | 아니다. |
| 변수 변환에서 Jacobian이 필요한 이유는? | 부피 변화율을 보정하기 위해 |

## 복습 질문

1. 공분산 행렬의 고유값이 큰 방향은 데이터 분포에서 어떤 의미인가?
2. `x`와 `y`가 Gaussian이면 `x+y`는 항상 Gaussian인가? 어떤 조건이 필요한가?
3. `y=x^2`처럼 여러 `x`가 같은 `y`로 가는 변환에서는 확률을 어떻게 모아야 하는가?


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-13.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-13.pdf</a></li>
</ul>
