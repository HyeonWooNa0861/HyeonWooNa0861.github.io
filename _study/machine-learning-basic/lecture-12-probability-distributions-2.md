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
| 1 | 독립 | 두 확률변수의 결합분포는 언제 곱으로 분리되는가? |
| 2 | Bayes' Theorem | 관측 후 믿음은 어떻게 갱신되는가? |
| 3 | Bayesian ML | prior, likelihood, posterior는 무엇인가? |
| 4 | 기대값과 분산 | 분포를 대표하는 통계량은 무엇인가? |
| 5 | 공분산과 상관관계 | 두 변수의 관계는 어떻게 수치화되는가? |

## 1. 독립 확률변수

두 확률변수 \\(X\\), \\(Y\\)가 독립이면 결합분포가 각 주변분포의 곱으로 분해된다.

$$
p(x,y) = p(x)p(y)
$$

연속확률변수도 joint PDF가 두 marginal PDF의 곱으로 분해되면 독립이다.

IID는 independent and identically distributed의 약자다. 서로 독립이고 같은 분포를 따르는 확률변수들의 집합을 뜻한다.

## 2. Bayes' Theorem

Bayes' theorem은 조건부 확률을 뒤집어 계산하는 규칙이다.

$$
P(Y=y\mid X=x)
= \frac{P(X=x\mid Y=y)P(Y=y)}{P(X=x)}
$$

이 정리는 관측 데이터가 들어왔을 때 기존 믿음을 어떻게 갱신할지 설명한다.

## 3. Bayesian Machine Learning

Bayesian ML에서는 모델 parameter 자체를 확률변수로 본다.

| 개념 | 의미 |
|---|---|
| prior | 데이터를 보기 전 parameter에 대한 믿음 |
| likelihood | parameter가 주어졌을 때 데이터가 나올 가능성 |
| posterior | 데이터를 본 후 parameter에 대한 믿음 |
| predictive distribution | 새 입력에 대한 예측값의 분포 |

이 관점에서는 하나의 parameter estimate만 찾는 것이 아니라 uncertainty까지 함께 모델링한다.

$$
P(\theta\mid X)
= \frac{P(X\mid\theta)p(\theta)}{p(X)}
$$

## 4. 기대값, 평균, 분산

기대값은 확률변수 함수의 평균적인 값을 의미한다.

$$
\mathbb{E}[g(X)]
$$

\\(g(x)=x\\)인 경우를 평균이라고 한다.

분산은 확률변수가 평균 주변에서 얼마나 퍼져 있는지 측정한다.

$$
\operatorname{Var}(X)
= \mathbb{E}\left[(X-\mathbb{E}[X])^2\right]
$$

## 5. 공분산과 상관관계

공분산은 두 확률변수가 함께 어떻게 변하는지 측정한다.

$$
\operatorname{Cov}(X,Y)
= \mathbb{E}\left[(X-\mathbb{E}[X])(Y-\mathbb{E}[Y])\right]
$$

상관관계는 공분산을 각 변수의 표준편차로 정규화한 값이다.

| 값 | 해석 |
|---|---|
| 양수 | 한 변수가 커질 때 다른 변수도 커지는 경향 |
| 음수 | 한 변수가 커질 때 다른 변수는 작아지는 경향 |
| 0 근처 | 선형 관계가 약함 |

## 6. 다변수 확률변수

다변수 확률변수에서는 평균은 벡터, 공분산은 행렬이 된다.

$$
\text{mean vector} = \mathbb{E}[X]
$$

$$
\text{covariance matrix}
= \mathbb{E}\left[(X-\mu)(X-\mu)^T\right]
$$

공분산 행렬은 feature 간 관계와 데이터 분포의 방향성을 담는다. PCA와 Gaussian model에서 매우 중요하다.

## 7. 기대값의 성질

| 성질 | 의미 |
|---|---|
| 선형성 | \\(\mathbb{E}[aX+bY] = a\mathbb{E}[X]+b\mathbb{E}[Y]\\) |
| 독립이면 곱의 기대값 분리 | \\(\mathbb{E}[XY] = \mathbb{E}[X]\mathbb{E}[Y]\\) |
| total variance | 조건부 분산과 조건부 평균의 분산으로 전체 분산 분해 |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 독립의 정의는? | joint distribution이 marginal들의 곱으로 분해 |
| Bayes theorem의 구성요소는? | prior, likelihood, evidence, posterior |
| 분산은 무엇을 측정하는가? | 평균 주변의 퍼짐 |
| covariance matrix는 무엇을 담는가? | 변수 간 함께 변하는 정도 |

## 복습 질문

<details>
<summary>1. 독립이면 상관관계는 0인가? 반대로 상관관계가 0이면 항상 독립인가?</summary>

답변: 독립이면 일반적으로 covariance와 correlation은 0이다. 하지만 correlation이 0이라고 해서 항상 독립은 아니다. correlation은 선형 관계만 측정하므로 비선형 의존성이 남아 있을 수 있다.

</details>

<details>
<summary>2. Bayesian ML에서 posterior는 언제 prior와 달라지는가?</summary>

답변: 데이터를 관측하고 likelihood가 prior에 정보를 추가할 때 posterior가 prior와 달라진다. 데이터가 많고 likelihood가 강하면 posterior는 데이터가 지지하는 parameter 근처로 이동한다. 데이터가 거의 정보가 없으면 posterior는 prior와 비슷하게 남을 수 있다.

</details>

<details>
<summary>3. 공분산 행렬의 대각 원소와 비대각 원소는 각각 무엇을 뜻하는가?</summary>

답변: 대각 원소는 각 변수 자신의 분산이다. 비대각 원소는 서로 다른 두 변수가 함께 어떻게 변하는지를 나타내는 covariance다. 양수면 같이 증가하는 경향, 음수면 반대로 움직이는 경향을 뜻한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-12.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-12.pdf</a></li>
</ul>
