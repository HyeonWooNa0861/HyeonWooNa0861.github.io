---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 19:42:25 +0900
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

### 원문 수식 추적표

| PDF 페이지 | 중요 정의·식 | 본문 대응 |
|---:|---|---|
| 3–9 | 확률론, 확률변수, nonnegativity·normalization·additivity | 1–4, 8.1 |
| 10–14 | PMF, joint PMF와 marginalization | 5, 6, 8.3 |
| 15 | conditional probability, sum rule, product rule | 8.4 |
| 16–20 | 연속확률변수, CDF/PDF, 구간확률, uniform density | 7, 8.2, 8.6 |
| 21–23 | joint CDF/PDF, conditional density와 piecewise 경계 | 7, 8.5, 8.6 |

페이지 24는 Q&A 마무리이다.

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

동전을 두 번 던질 때 앞면의 개수를 세는 확률변수 $$X$$를 생각하면:

$$
X(HH)=2,\quad X(HT)=1,\quad X(TH)=1,\quad X(TT)=0
$$

우리가 계산하는 확률은 보통 $$P(X \ge 1)$$처럼 확률변수 위의 사건에 대한 확률이다.

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

두 확률변수 $$X$$, $$Y$$가 같은 표본공간에 정의되어 있을 때 joint PMF는 다음 확률이다.

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

## 8. 확률식의 유도와 단위

### 8.1 여사건과 합집합 공식

확률 공리에서 $$S=A\cup A^c$$, $$A\cap A^c=\varnothing$$이므로

$$
1=P(S)=P(A)+P(A^c)
$$

이고 $$P(A^c)=1-P(A)$$다. 또한 $$A\cup B$$에서 교집합을 두 번 세지 않도록 빼면

$$
P(A\cup B)=P(A)+P(B)-P(A\cap B)
$$

이다. 두 식은 **정확한 항등식**이며 두 사건이 독립일 필요가 없다.

### 8.2 CDF와 PDF의 연결

연속확률변수 $$X$$가 밀도 $$f_X$$를 가지고 $$F_X$$가 미분 가능한 점에서는

$$
F_X(x)=\int_{-\infty}^{x}f_X(t)\,dt,
\qquad
f_X(x)=\frac{dF_X(x)}{dx}.
$$

미적분학의 기본정리로 얻는 **정확한 관계**다. 모든 분포가 PDF를 가지는 것은 아니며, 점질량이 섞인 분포에서는 CDF가 점프하므로 이 미분식만으로 전체 확률을 복원할 수 없다.

구간 확률은

$$
P(a<X\le b)=F_X(b)-F_X(a)=\int_a^b f_X(x)\,dx
$$

이다. $$X$$의 단위가 meter라면 $$f_X$$의 단위는 $$\mathrm{m}^{-1}$$이고, 적분한 확률·PMF·CDF는 무차원이다. 따라서 PDF 높이가 1을 넘더라도 면적이 $$[0,1]$$이면 문제가 없다.

### 8.3 Joint에서 marginal로

이산형에서는 가능한 $$y$$ 사건들이 서로소이므로

$$
p_X(x)=\sum_y p_{X,Y}(x,y)
$$

이다. 연속형에서는 합이 적분으로 바뀐다. 적분 범위는 지원집합 전체를 포함해야 한다. Density를 지원집합 밖에서 0으로 연장하는 통상적 표기에서는 $$\mathbb{R}$$ 전체에 적분해도 바깥 구간의 기여가 0이므로 같은 결과를 얻는다. 연속형 density를 점확률로 해석해서는 안 된다.

### 8.4 조건부 PMF, 합 법칙과 곱 법칙

이산확률변수에서 $$p_X(x)>0$$이면 conditional PMF는

$$
p_{Y\mid X}(y\mid x)
=P(Y=y\mid X=x)
=\frac{p_{X,Y}(x,y)}{p_X(x)}
$$

로 정의된다. 따라서 joint PMF는 곱 법칙

$$
p_{X,Y}(x,y)=p_{Y\mid X}(y\mid x)p_X(x)
=p_{X\mid Y}(x\mid y)p_Y(y)
$$

으로 복원된다. 다른 변수를 더해 없애는 합 법칙은

$$
p_X(x)=\sum_y p_{X,Y}(x,y)
=\sum_y p_{X\mid Y}(x\mid y)p_Y(y)
$$

이다. 첫 번째 등식은 marginalization, 두 번째 등식은 total probability다. 이 식들은 분모가 양수이고 합이 지원집합 전체를 훑는다는 조건 아래의 **정확한 항등식**이며 독립성을 요구하지 않는다. 독립인 경우에만 $$p_{Y\mid X}(y\mid x)=p_Y(y)$$로 단순해진다. PMF와 확률은 무차원이고, $$p_X(x)=0$$인 조건값에서는 위 비율 정의를 사용할 수 없다.

### 8.5 Joint CDF/PDF, 조건부 밀도와 곱 법칙

원문 마지막 두 슬라이드의 연속형 확장을 정리한다. 두 연속확률변수 $$X,Y$$의 joint CDF는 **정의**로

$$
F_{X,Y}(x,y)=P(X\le x,\,Y\le y)
$$

이다. 결합분포가 joint density를 갖고 필요한 미분이 존재하는 점에서는

$$
f_{X,Y}(x,y)
=\frac{\partial^2}{\partial x\,\partial y}F_{X,Y}(x,y),
$$

$$
F_{X,Y}(x,y)
=\int_{-\infty}^{x}\int_{-\infty}^{y}
f_{X,Y}(u,v)\,dv\,du.
$$

두 식은 joint distribution이 절대연속이라는 가정 아래의 **정확한 관계**다. 점질량이나 singular component가 섞이면 CDF는 여전히 정의되지만 하나의 joint PDF와 혼합미분만으로 전체 분포를 나타낼 수 없다.

유효한 joint PDF는 $$f_{X,Y}(x,y)\ge0$$이고

$$
\int_{\mathbb{R}}\int_{\mathbb{R}}f_{X,Y}(x,y)\,dy\,dx=1
$$

을 만족해야 한다. 개별 density 높이가 아니라 영역 위의 이중적분이 그 영역의 확률이다.

연속형 합 법칙, 즉 marginalization은 다른 변수를 그 지원집합 전체에서 적분하는 것이다.

$$
f_X(x)=\int_{\mathbb{R}}f_{X,Y}(x,y)\,dy,
\qquad
f_Y(y)=\int_{\mathbb{R}}f_{X,Y}(x,y)\,dx.
$$

$$f_X(x)>0$$인 점에서는 conditional density를

$$
f_{Y\mid X}(y\mid x)
=\frac{f_{X,Y}(x,y)}{f_X(x)}
$$

로 정의하고, 이를 다시 쓰면 연속형 곱 법칙

$$
f_{X,Y}(x,y)=f_{Y\mid X}(y\mid x)f_X(x)
$$

을 얻는다. 이는 독립성을 요구하지 않는 **정확한 항등식**이다. 독립일 때만 conditional density가 marginal과 같아져 $$f_{X,Y}(x,y)=f_X(x)f_Y(y)$$로 단순화된다.

| 양 | 단위 |
|---|---|
| $$F_{X,Y}(x,y)$$, 확률 | 무차원 |
| $$f_X(x)$$ | $$X$$ 단위의 역수 |
| $$f_Y(y)$$, $$f_{Y\mid X}(y\mid x)$$ | $$Y$$ 단위의 역수 |
| $$f_{X,Y}(x,y)$$ | `X 단위의 역수 × Y 단위의 역수` |

따라서 joint density를 $$y$$에 대해 적분하면 $$Y$$의 역단위가 소거되어 $$f_X$$의 단위가 남는다. $$f_X(x)=0$$인 점에서는 위 비율로 conditional density를 정의할 수 없으며, density 값 자체를 점확률로 읽는 해석도 실패한다.

### 8.6 구간 균등분포의 piecewise PDF와 CDF

$$X\sim\operatorname{Uniform}(a,b)$$, $$a<b$$라 하자. 전체 면적이 1이어야 하므로 상수 높이 $$c$$는 $$c(b-a)=1$$에서 $$c=1/(b-a)$$다. 따라서

$$
f_X(x)=
\begin{cases}
0,&x<a,\\
\dfrac{1}{b-a},&a\le x\le b,\\
0,&x>b,
\end{cases}
$$

이고 이를 $$-\infty$$부터 적분하면

$$
F_X(x)=
\begin{cases}
0,&x<a,\\
\dfrac{x-a}{b-a},&a\le x\le b,\\
1,&x>b.
\end{cases}
$$

예를 들어 $$X\sim\operatorname{Uniform}(2,4)$$이면 $$f_X(x)=1/2$$가 1보다 작지만, 더 좁은 $$\operatorname{Uniform}(0,1/2)$$에서는 $$f_X(x)=2>1$$이다. 두 경우 모두 면적은 정확히 1이다. $$X$$의 단위가 second이면 $$a,b,x$$는 second, PDF는 $$\mathrm{s}^{-1}$$, CDF와 구간확률은 무차원이다. 끝점 하나의 포함 여부는 연속분포의 확률을 바꾸지 않지만, 위 piecewise 표기는 CDF의 연속성을 명확히 보이기 위해 닫힌 구간으로 썼다.

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

<details markdown="block">
<summary markdown="span">1. 동전 두 번 던지기에서 $$P(X \ge 1)$$은 어떤 사건의 확률인가?</summary>

답변: $$X$$가 앞면의 개수라면 $$X\ge 1$$은 두 번 중 적어도 한 번 앞면이 나오는 사건이다. 표본공간이 $$HH, HT, TH, TT$$라면 해당 사건은 $$HH, HT, TH$$이다.

</details>

<details markdown="block">
<summary>2. Joint PMF는 단순히 두 PMF를 곱한 것인가? 언제 곱할 수 있는가?</summary>

답변: 일반적으로 joint PMF는 두 확률변수의 결합확률을 나타내며 단순 곱이 아니다. 두 확률변수가 독립일 때에만 $$p_{X,Y}(x,y)=p_X(x)p_Y(y)$$로 분해할 수 있다.

</details>

<details markdown="block">
<summary>3. 연속확률변수에서 "정확히 2시"에 도착할 확률이 0인 이유는 무엇인가?</summary>

답변: 연속확률변수에서는 한 점의 길이가 0이므로 그 점에 해당하는 확률도 0이다. 확률은 보통 구간의 면적, 즉 density를 적분한 값으로 계산한다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-11.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-11.pdf</a></li>
</ul>
