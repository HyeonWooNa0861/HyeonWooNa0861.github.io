---
layout: default
date: 2026-05-20 12:30:12 +0900
title: "Lecture 11 Probability Distributions 1"
course: "Machine Learning Basic"
topic: "Probability Distributions 1"
order: 11
major_topic: "Machine Learning Foundations"
keywords:
  - "Probability"
  - "Random Variables"
  - "Distributions"
  - "Expectation"
  - "Variance"
---

# Lecture 11 Probability Distributions 1

Source PDF: `machine-learning-basic-lecture-11.pdf`

> **핵심:** **확률변수란** 표본공간 결과를 수치로 보내는 함수. **PMF는 언제 쓰는가** 이산확률변수.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 확률론의 필요성 | 불확실성을 어떻게 수량화하는가? |
| 2 | 표본공간과 사건 | 확률을 정의하려면 어떤 집합이 필요한가? |
| 3 | 확률변수 | 실험 결과를 수치로 바꾸는 함수는 무엇인가? |
| 4 | 이산확률변수 | PMF와 joint PMF는 무엇인가? |
| 5 | 연속확률변수 | CDF와 PDF는 어떻게 확률을 표현하는가? |

## 1. 확률론이 필요한 이유

확률론은 불확실성을 수량적으로 다루는 이론이다. 머신러닝, 데이터 분석, Bayesian AI, LLM, diffusion model 등에서 핵심 기반이 된다.

확률은 단순한 참/거짓을 넘어서 어떤 명제가 얼마나 그럴듯한지를 일관된 수치로 표현한다.

## 2. 표본공간, 사건공간, 확률

| 개념 | 의미 |
|---|---|
| 표본공간 | 실험에서 나올 수 있는 모든 결과의 집합 |
| 사건 | 확률을 계산하고 싶은 결과들의 집합 |
| 확률 | 사건이 일어날 가능성 또는 믿음의 정도 |

예를 들어 동전을 두 번 던지는 실험에서 표본공간은 `{HH, HT, TH, TT}`이다. "앞면이 한 번 이상 나온다"는 사건은 `{HH, HT, TH}`이다.

## 3. 확률변수

확률변수는 표본공간의 결과를 수치로 대응시키는 함수다.

동전을 두 번 던질 때 앞면의 개수를 세는 확률변수 \(X\)를 생각하면:

$$
X(HH)=2,\quad X(HT)=1,\quad X(TH)=1,\quad X(TT)=0
$$

우리가 계산하는 확률은 보통 \(P(X \ge 1)\)처럼 확률변수 위의 사건에 대한 확률이다.

## 4. 확률 함수의 조건

확률은 아무 숫자나 붙이면 되는 것이 아니라 다음 조건을 만족해야 한다.

| 조건 | 의미 |
|---|---|
| nonnegative | 확률은 음수가 될 수 없다. |
| normalization | 전체 표본공간의 확률은 1이다. |
| additivity | 서로소 사건들의 합집합 확률은 확률의 합이다. |

이 조건들로부터 여사건, 포함관계, 합집합 확률 같은 기본 성질이 따라온다.

## 5. 이산확률변수와 PMF

이산확률변수는 가능한 값이 유한하거나 셀 수 있는 경우다. 이때 확률은 PMF(probability mass function)로 표현한다.

$$
p_X(x) = P(X=x)
$$

여러 값으로 이루어진 사건의 확률은 해당 값들의 PMF를 더해서 구한다.

## 6. Joint PMF

두 확률변수 \(X\), \(Y\)가 같은 표본공간에 정의되어 있을 때 joint PMF는 다음 확률이다.

$$
p_{X,Y}(x,y) = P(X=x, Y=y)
$$

이는 두 조건을 동시에 만족할 확률이다. 이후 조건부 확률, 합 법칙, 곱 법칙의 기반이 된다.

## 7. 연속확률변수와 CDF/PDF

연속확률변수는 값이 연속 공간 위에 있는 경우다. 이 경우 특정 점 하나의 확률은 0이다.

따라서 구간 확률을 계산해야 하며 CDF를 사용한다.

$$
F_X(x) = P(X \le x)
$$

PDF는 CDF의 변화율로 이해할 수 있고, 구간 확률은 PDF를 적분해 구한다.

주의할 점: PDF 값은 1보다 클 수 있다. 1보다 클 수 없는 것은 확률과 CDF 값이다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 확률변수란? | 표본공간 결과를 수치로 보내는 함수 |
| PMF는 언제 쓰는가? | 이산확률변수 |
| PDF에서 한 점의 확률은? | 연속확률변수에서는 0 |
| PDF 값이 1보다 클 수 있는가? | 가능하다. 면적이 확률이다. |

## Study Guide

sample space와 event를 적은 뒤 random variable이 결과를 숫자로 보내는 함수임을 먼저 확인한다. 이산 변수는 PMF 합, 연속 변수는 PDF 적분으로 normalization을 검산하고 joint distribution에서 marginal을 구해 본다. PDF 값 자체는 1보다 클 수 있고 한 점의 확률은 0이라는 두 문장을 가장 우선적으로 점검한다.

## 복습 질문

<details>
<summary>1. 동전 두 번 던지기에서 \(P(X \ge 1)\)은 어떤 사건의 확률인가?</summary>

답변: \(X\)가 앞면의 개수라면 \(X\ge 1\)은 두 번 중 적어도 한 번 앞면이 나오는 사건이다. 표본공간이 \(HH, HT, TH, TT\)라면 해당 사건은 \(HH, HT, TH\)이다.

</details>

<details>
<summary>2. Joint PMF는 단순히 두 PMF를 곱한 것인가? 언제 곱할 수 있는가?</summary>

답변: 일반적으로 joint PMF는 두 확률변수의 결합확률을 나타내며 단순 곱이 아니다. 두 확률변수가 독립일 때에만 \(p_{X,Y}(x,y)=p_X(x)p_Y(y)\)로 분해할 수 있다.

</details>

<details>
<summary>3. 연속확률변수에서 "정확히 2시"에 도착할 확률이 0인 이유는 무엇인가?</summary>

답변: 연속확률변수에서는 한 점의 길이가 0이므로 그 점에 해당하는 확률도 0이다. 확률은 보통 구간의 면적, 즉 density를 적분한 값으로 계산한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-11.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-11.pdf</a></li>
</ul>
