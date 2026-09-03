---
layout: default
date: 2026-06-02 13:12:04 +0900
title: "Machine Learning Basic Exam Review"
course: "Machine Learning Basic"
topic: "Exam Review"
order: 90
major_topic: "Machine Learning Foundations"
keywords:
  - "Linear Algebra"
  - "Matrix Decomposition"
  - "Probability"
  - "Optimization"
  - "Linear Regression"
---

# Machine Learning Basic Exam Review

Source PDFs:

- `machine-learning-basic-lecture-11.pdf`
- `machine-learning-basic-lecture-12.pdf`
- `machine-learning-basic-lecture-13.pdf`
- `machine-learning-basic-lecture-14.pdf`
- `machine-learning-basic-lecture-15.pdf`
- `machine-learning-basic-lecture-16.pdf`
- `machine-learning-basic-lecture-17.pdf`

이 글은 머신러닝기초 11강부터 17강까지의 정리 자료에서 시험 범위에 해당하는 부분만 뽑아 재구성한 시험 대비용 추출본이다. 출제 조건은 확률과 분포 3문제, 최적화 이론 2문제, Model and Data 1문제, 선형회귀 1문제이므로, 아래 내용도 그 배점에 맞추어 정리한다.

> **핵심:** **PMF** \(p_X(x)=P(X=x)\). **PDF** \(P(a<X\le b)=\int_a^b f_X(x)\,dx\).

## 전체 흐름

| 범위 | 예상 문항 수 | 연결 강의 | 공부 우선순위 |
|---|---:|---|---|
| 확률과 분포 | 3 | Lecture 11, 12, 13 | 계산 규칙, Bayes, Gaussian을 가장 먼저 정리 |
| 최적화 이론 | 2 | Lecture 14 | GD update, step size, momentum, mini-batch, Newton, convex 중심 |
| Model and Data | 1 | Lecture 15, 16 | 결정론적 모델과 확률 모델, ERM, MLE, MAP, CV, DGM |
| 선형회귀 | 1 | Lecture 17 | 모델식, 해 구하기, 예측, MLE, MAP |

시험 대비의 큰 흐름은 다음과 같다.

1. 확률분포는 PMF, PDF, CDF를 구분하고 joint, marginal, conditional을 계산할 수 있어야 한다.
2. Bayes 정리는 posterior, likelihood, prior, evidence의 역할을 말로 설명하고 수식으로 계산할 수 있어야 한다.
3. Gaussian은 평균과 분산의 의미, 조건부분포와 주변분포, 확률변수의 합과 분포의 혼합 차이를 구분해야 한다.
4. 최적화는 gradient update를 실제로 한 번 계산할 수 있어야 하며, mini-batch가 full-batch와 어떻게 다른지 알아야 한다.
5. MLE와 MAP는 negative log를 취했을 때 어떤 최적화 문제로 바뀌는지 설명할 수 있어야 한다.
6. 선형회귀는 Gaussian noise 가정에서 squared error가 나오고, Gaussian prior에서 ridge 형태가 나오는 흐름을 잡아야 한다.

메모 반영 기준으로 보면 우선순위는 더 분명하다. 확률의 정의와 조건은 개념적으로 반드시 알아야 하고, 11강, 12강, 13강 확률 PDF에서 각각 1문제씩 나온다고 생각하고 준비한다. 최적화 2문제는 gradient descent update, step size, mini-batch, momentum, Newton method, convex 증명 또는 반례를 중심으로 본다. Model and Data는 결정론적 모델과 확률 모델의 차이, ERM, MLE, cross validation, regularization, MAP, DGM을 한 묶음으로 정리한다. 선형회귀는 모델식에서 시작해 최적해, 예측, MLE, MAP 계산까지 이어서 연습한다.

## 1. 확률과 분포: 3문제 범위

확률과 분포 파트는 가장 넓게 출제된다. 단순 정의 문제보다 joint table에서 주변확률, 조건부확률, 독립성, Bayes 정리를 계산하는 문제가 나올 가능성이 높다.

### 1.1 확률의 조건

확률은 표본공간 \(S\)의 사건 \(A\)에 숫자를 붙이는 함수다. 더 정확히 말하면 사건을 \([0,1]\) 사이의 수로 보내면서, 아래의 기본 구조를 만족하는 함수를 확률이라고 부른다. 따라서 확률의 정의와 조건은 계산보다 먼저 개념적으로 반드시 알아야 한다. 아무 숫자나 붙인다고 확률이 되는 것이 아니라, nonnegativity, normalization, additivity를 만족해야 한다.

| 조건 | 수식 | 의미 |
|---|---|---|
| Nonnegativity | \(P(A)\ge 0\) | 확률은 음수가 될 수 없다. |
| Normalization | \(P(S)=1\) | 전체 표본공간의 확률은 1이다. |
| Additivity | \(P(A\cup B)=P(A)+P(B)\), if \(A\cap B=\emptyset\) | 서로소 사건은 확률을 더한다. |

이 조건에서 다음 성질이 바로 따라온다.

$$
P(A^c)=1-P(A)
$$

$$
A\subseteq B
\quad\Longrightarrow\quad
P(A)\le P(B)
$$

서로소가 아닌 두 사건의 합집합은 교집합을 한 번 빼야 한다.

$$
P(A\cup B)
=P(A)+P(B)-P(A\cap B)
$$

시험에서는 "확률의 세 조건을 쓰라"는 직접 정의형 문제도 가능하고, 이 조건을 사용해 여사건이나 합집합 확률을 계산하는 문제도 가능하다. 확률의 조건은 이후 PMF, PDF, joint distribution이 "정상적인 확률분포인지" 판단하는 기준이 된다.

### 1.2 확률의 예시

동전을 두 번 던지는 실험을 생각하자. 표본공간은 다음과 같다.

$$
S=\{HH,HT,TH,TT\}
$$

앞면이 한 번 이상 나오는 사건을 \(A\)라 하면

$$
A=\{HH,HT,TH\}
$$

공정한 동전이면 각 결과의 확률은 \(\frac{1}{4}\)이므로

$$
P(A)=\frac{3}{4}
$$

이 예시의 핵심은 확률변수로 바꾸는 부분이다. 앞면의 개수를 세는 확률변수 \(X\)를 두면

$$
X(HH)=2,\quad X(HT)=1,\quad X(TH)=1,\quad X(TT)=0
$$

따라서 앞면이 한 번 이상 나온다는 사건은 다음처럼 확률변수의 사건으로 다시 쓸 수 있다.

$$
P(X\ge 1)=P(\{HH,HT,TH\})=\frac{3}{4}
$$

### 1.3 이산확률변수와 PMF

확률변수는 표본공간의 결과를 숫자로 보내는 함수다. 가능한 값이 유한하거나 셀 수 있으면 이산확률변수라고 한다. 즉, 확률이 이미 정의된 표본공간 위에서 어떤 결과들을 숫자 값으로 묶어 보는 함수가 확률변수다.

이산확률변수 \(X\)의 확률분포는 PMF(probability mass function), 즉 확률질량함수로 표현한다. PMF는 "확률변수 \(X\)가 특정 값 \(x\)를 가질 확률"을 알려주는 함수다.

$$
p_X(x)=P(X=x)
$$

표본공간 관점에서 더 정확히 쓰면 다음과 같다.

$$
p_X(x)
=
P(\{\omega\in S:X(\omega)=x\})
$$

즉, PMF는 확률변수 값 \(x\) 하나에 대응되는 원래 실험 결과들을 모두 모은 뒤, 그 결과들의 확률을 더한 값이다. 그래서 서로 다른 표본공간 원소가 같은 확률변수 값을 가질 수 있고, 그 확률들이 하나의 PMF 값으로 합쳐진다.

| 관점 | 의미 |
|---|---|
| 입력 | 확률변수의 가능한 값 \(x\) |
| 출력 | 그 값이 나올 확률 \(P(X=x)\) |
| 사용 대상 | 이산확률변수 |
| 계산 방식 | 해당 값에 대응되는 확률들을 더함 |

PMF는 다음 조건을 만족한다.

$$
p_X(x)\ge 0
$$

$$
\sum_x p_X(x)=1
$$

또한 PMF 값은 실제 확률이므로 항상 0 이상 1 이하이다.

$$
0\le p_X(x)\le 1
$$

예를 들어 동전 두 번 던지기에서 앞면 개수 \(X\)의 PMF는 다음과 같다.

| \(x\) | \(0\) | \(1\) | \(2\) |
|---:|---:|---:|---:|
| \(p_X(x)\) | \(\frac{1}{4}\) | \(\frac{1}{2}\) | \(\frac{1}{4}\) |

여러 값을 포함하는 사건은 PMF를 더해서 계산한다.

$$
P(X\ge 1)
=p_X(1)+p_X(2)
=\frac{1}{2}+\frac{1}{4}
=\frac{3}{4}
$$

조금 더 일반적으로 쓰면, 확률변수 \(X\)가 어떤 값들의 집합 \(B\)에 들어갈 확률은 그 값에 해당하는 표본공간 원소들의 확률을 모두 더한 것이다.

$$
P(X\in B)
=
\sum_{x\in B}p_X(x)
$$

따라서 이산확률변수 문제는 "확률변수 값에 해당하는 친구들의 확률의 합"으로 계산한다고 기억하면 된다.

### 1.4 결합 확률 질량함수

두 이산확률변수 \(X\), \(Y\)가 있을 때 joint PMF는 두 변수가 동시에 특정 값을 가질 확률이다.

$$
p_{X,Y}(x,y)=P(X=x,Y=y)
$$

Joint PMF에서 특정 사건의 확률은 해당 칸들을 더해서 구한다.

$$
P((X,Y)\in A)
=
\sum_{(x,y)\in A}
p_{X,Y}(x,y)
$$

예를 들어 joint PMF가 다음과 같다고 하자.

|  | \(Y=0\) | \(Y=1\) | 합 |
|---|---:|---:|---:|
| \(X=0\) | 0.10 | 0.20 | 0.30 |
| \(X=1\) | 0.25 | 0.45 | 0.70 |
| 합 | 0.35 | 0.65 | 1.00 |

이때 \(P(X=1,Y=0)=0.25\)이다. \(X=1\)일 확률은 \(Y\) 값을 모두 더해서 구한다.

$$
P(X=1)
=p_{X,Y}(1,0)+p_{X,Y}(1,1)
=0.25+0.45
=0.70
$$

이처럼 결합분포에서 한 변수를 제거해 얻는 분포를 주변분포(marginal distribution)라고 한다.

$$
p_X(x)=\sum_y p_{X,Y}(x,y)
$$

$$
p_Y(y)=\sum_x p_{X,Y}(x,y)
$$

### 1.5 조건부 확률, 합 법칙, 곱 법칙

조건부 확률은 어떤 사건이 이미 일어났다는 정보 아래에서 다른 사건의 확률을 계산하는 것이다.

$$
P(A\mid B)
=
\frac{P(A\cap B)}{P(B)}
\qquad
P(B)>0
$$

확률변수로 쓰면 다음과 같다.

$$
p_{X\mid Y}(x\mid y)
=
\frac{p_{X,Y}(x,y)}{p_Y(y)}
$$

위 joint table에서 \(P(X=1\mid Y=0)\)은 다음처럼 계산된다.

$$
P(X=1\mid Y=0)
=
\frac{P(X=1,Y=0)}{P(Y=0)}
=
\frac{0.25}{0.35}
=
\frac{5}{7}
$$

곱 법칙(product rule)은 조건부 확률식을 변형한 것이다.

$$
P(A\cap B)
=P(A\mid B)P(B)
$$

확률변수에서는 다음처럼 쓴다.

$$
p_{X,Y}(x,y)
=p_{X\mid Y}(x\mid y)p_Y(y)
$$

합 법칙(sum rule)은 joint distribution에서 필요 없는 변수를 더해서 제거하는 규칙이다.

$$
p_X(x)=\sum_y p_{X,Y}(x,y)
$$

또는 조건부 확률과 곱 법칙을 함께 쓰면 다음과 같다.

$$
p_X(x)
=
\sum_y p_{X\mid Y}(x\mid y)p_Y(y)
$$

이 식은 "가능한 모든 \(Y=y\) 경우를 나누어 \(X=x\)의 확률을 더한다"는 의미다.

### 1.6 연속확률변수, PDF, CDF

연속확률변수는 값이 연속적인 구간 또는 \(d\)차원 실수공간 위에 있는 확률변수다. 연속확률변수에서는 한 점의 확률이 0이다.

$$
P(X=x)=0
$$

따라서 연속확률변수에서는 한 점이 아니라 구간 또는 영역의 확률을 계산한다.

PDF(probability density function), 즉 확률밀도함수는 연속확률변수의 확률이 공간 위에 얼마나 밀집되어 있는지를 나타내는 함수다. PDF 자체는 확률이 아니라 density다.

$$
f_X(x)\ge 0
$$

$$
\int_{-\infty}^{\infty} f_X(x)\,dx=1
$$

구간 확률은 PDF를 적분해서 구한다.

$$
P(a<X\le b)
=
\int_a^b f_X(x)\,dx
$$

중요한 점은 \(f_X(x)\)가 1보다 클 수 있다는 것이다. PDF 값이 1보다 크더라도 면적, 즉 적분한 확률이 1을 넘지 않으면 정상적인 density다.

CDF(cumulative distribution function), 즉 누적분포함수는 확률변수 \(X\)가 어떤 기준값 \(x\) 이하일 확률을 누적해서 보여주는 함수다.

$$
F_X(x)=P(X\le x)
$$

연속확률변수에서 CDF는 PDF를 \(-\infty\)부터 \(x\)까지 적분한 값이다.

$$
F_X(x)
=
\int_{-\infty}^{x}f_X(t)\,dt
$$

반대로 CDF가 미분 가능하면 PDF는 CDF의 미분으로 볼 수 있다.

$$
f_X(x)=\frac{d}{dx}F_X(x)
$$

CDF는 다음 성질을 가진다.

| 성질 | 의미 |
|---|---|
| \(0\le F_X(x)\le 1\) | CDF 값은 확률이므로 0과 1 사이 |
| Non-decreasing | \(x\)가 커질수록 누적확률은 줄어들지 않음 |
| \(\lim_{x\to-\infty}F_X(x)=0\) | 매우 작은 값 이하일 확률은 0으로 감 |
| \(\lim_{x\to\infty}F_X(x)=1\) | 충분히 큰 값 이하일 확률은 1로 감 |

구간 확률은 CDF의 차 또는 PDF의 적분으로 계산한다.

$$
P(a<X\le b)
=F_X(b)-F_X(a)
=\int_a^b f_X(x)\,dx
$$

\(d\)차원 연속확률변수 \(X\in\mathbb{R}^d\)에서는 구간 대신 영역 \(A\) 위에서 적분한다.

$$
P(X\in A)
=
\int_A f_X(x)\,dx
$$

주의할 점은 PDF 값은 확률 자체가 아니라 density라는 것이다. 따라서 \(f_X(x)\) 값은 1보다 클 수 있다. 1보다 클 수 없는 것은 확률값과 CDF 값이다.

PMF, PDF, CDF를 시험용으로 구분하면 다음과 같다.

| 함수 | 정의 | 대상 | 확률 계산 |
|---|---|---|---|
| PMF | \(p_X(x)=P(X=x)\) | 이산확률변수 | 값을 더함: \(P(X\in B)=\sum_{x\in B}p_X(x)\) |
| PDF | \(f_X(x)\) | 연속확률변수 | 구간을 적분: \(P(a<X\le b)=\int_a^b f_X(x)\,dx\) |
| CDF | \(F_X(x)=P(X\le x)\) | 이산과 연속 모두 가능 | 차이를 계산: \(P(a<X\le b)=F_X(b)-F_X(a)\) |

핵심 구분은 이렇다. PMF는 값 하나에 대한 확률이고, PDF는 값 하나의 확률이 아니라 density이며, CDF는 특정 값 이하까지 누적한 확률이다.

### 1.7 독립 확률 변수 판단

두 확률변수 \(X\), \(Y\)가 독립이라는 것은 \(Y\)를 알아도 \(X\)에 대한 확률이 바뀌지 않는다는 뜻이다.

이산확률변수에서는 모든 \(x,y\)에 대해 다음이 성립해야 한다.

$$
p_{X,Y}(x,y)=p_X(x)p_Y(y)
$$

같은 조건을 조건부 확률로 쓰면 다음과 같다.

$$
p_{X\mid Y}(x\mid y)=p_X(x)
$$

독립성 판단에서 가장 흔한 실수는 주변확률만 보고 판단하는 것이다. 반드시 joint PMF의 모든 칸이 marginal product와 일치하는지 확인해야 한다.

예를 들어 위 table에서는

$$
p_{X,Y}(1,1)=0.45
$$

이고

$$
p_X(1)p_Y(1)=0.70\times 0.65=0.455
$$

두 값이 다르므로 \(X\), \(Y\)는 독립이 아니다. 한 칸만 달라도 독립이 아니다.

### 1.8 Bayes 정리와 likelihood

Bayes 정리는 조건부 확률의 방향을 바꾸는 규칙이다. 시험에서는 식을 무조건 외우고, 각 항의 의미까지 말로 설명할 수 있어야 한다.

$$
P(Y\mid X)
=
\frac{P(X\mid Y)P(Y)}{P(X)}
$$

각 항의 의미는 다음과 같다.

| 항 | 이름 | 해석 |
|---|---|---|
| \(P(Y\mid X)\) | posterior | 증거 \(X\)를 본 뒤 \(Y\)에 대한 갱신된 믿음 |
| \(P(X\mid Y)\) | likelihood | \(Y\)라고 가정했을 때 관측 \(X\)가 얼마나 그럴듯한가 |
| \(P(Y)\) | prior | 증거를 보기 전 \(Y\)에 대한 믿음 |
| \(P(X)\) | evidence | 관측 \(X\) 자체가 나타날 전체 확률 |

분모 \(P(X)\)는 posterior 전체가 합이 1이 되도록 정규화한다. 가능한 원인 \(Y=y_i\)가 여러 개라면 evidence는 다음처럼 계산한다.

$$
P(X)
=
\sum_i P(X\mid Y=y_i)P(Y=y_i)
$$

Parameter estimation에서는 같은 구조를 \(\theta\)와 데이터 \(\mathcal{D}\)에 대해 쓴다.

$$
p(\theta\mid\mathcal{D})
=
\frac{
p(\mathcal{D}\mid\theta)p(\theta)
}{
p(\mathcal{D})
}
$$

즉,

$$
\text{posterior}
\propto
\text{likelihood}\times\text{prior}
$$

likelihood는 \(p(\mathcal{D}\mid\theta)\)다. 말로는 "parameter가 \(\theta\)라고 가정했을 때, 지금 관측한 데이터가 얼마나 그럴듯한가"를 나타낸다. 데이터는 고정되어 있고, \(\theta\)를 바꾸어 가며 비교한다는 점이 중요하다.

### 1.9 Prior distribution과 posterior distribution

Prior distribution은 데이터를 보기 전 parameter에 대해 갖는 믿음이다.

$$
p(\theta)
$$

Posterior distribution은 데이터를 본 뒤 Bayes 정리로 갱신된 parameter의 분포다.

$$
p(\theta\mid\mathcal{D})
$$

MAP는 posterior가 가장 큰 parameter 하나를 고르는 방법이다.

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
p(\theta\mid\mathcal{D})
$$

Evidence \(p(\mathcal{D})\)는 \(\theta\)에 대해 constant이므로, MAP에서는 다음을 최대화해도 같은 해를 얻는다.

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
p(\mathcal{D}\mid\theta)p(\theta)
$$

이 차이가 MLE와 MAP를 가른다.

$$
\theta_{\mathrm{MLE}}
=
\arg\max_{\theta}
p(\mathcal{D}\mid\theta)
$$

MLE는 likelihood만 본다. MAP는 likelihood와 prior를 함께 본다.

### 1.10 기대값 계산과 성질

기대값은 확률변수의 평균적인 값을 의미한다. 이산확률변수에서는 다음과 같다.

$$
\mathbb{E}[X]
=
\sum_x x p_X(x)
$$

연속확률변수에서는 적분을 사용한다.

$$
\mathbb{E}[X]
=
\int x f_X(x)\,dx
$$

시험 제외로 표시되어 있더라도 중요한 성질은 같이 기억해두면 다른 수식 이해에 도움이 된다.

$$
\mathbb{E}[aX+b]
=
a\mathbb{E}[X]+b
$$

$$
\mathbb{E}[X+Y]
=
\mathbb{E}[X]+\mathbb{E}[Y]
$$

두 번째 식은 \(X\), \(Y\)가 독립이 아니어도 성립한다. 독립성이 필요해지는 대표적인 곳은 곱의 기대값이다.

$$
X\perp Y
\quad\Longrightarrow\quad
\mathbb{E}[XY]=\mathbb{E}[X]\mathbb{E}[Y]
$$

### 1.11 Gaussian distribution

Gaussian distribution 또는 normal distribution은 평균 \(\mu\), 분산 \(\sigma^2\)로 결정되는 대표적인 연속확률분포다. 이 PDF 공식은 중요도가 높으므로 반드시 외워야 한다.

$$
X\sim\mathcal{N}(\mu,\sigma^2)
$$

PDF는 다음과 같다.

$$
p(x\mid\mu,\sigma^2)
=
\frac{1}{\sqrt{2\pi\sigma^2}}
\exp\left(
-\frac{(x-\mu)^2}{2\sigma^2}
\right)
$$

평균 \(\mu\)는 분포의 중심을 정하고, 분산 \(\sigma^2\)는 평균 주변으로 얼마나 퍼져 있는지를 정한다. 표준정규분포는 다음과 같다.

$$
\mathcal{N}(0,1)
$$

다변수 Gaussian은 평균 벡터 \(\mu\)와 공분산 행렬 \(\Sigma\)로 결정된다.

$$
x\sim\mathcal{N}(\mu,\Sigma)
$$

공분산 행렬의 대각 원소는 각 변수의 분산, 비대각 원소는 변수 사이의 공분산이다.

### 1.12 Gaussian의 조건부분포와 주변분포

다변수 Gaussian의 중요한 성질은 일부 변수를 보거나 일부 변수를 조건으로 걸어도 다시 Gaussian이 된다는 점이다.

두 변수 블록 \(x\), \(y\)가 함께 Gaussian이라고 하자.

$$
\begin{bmatrix}
x\\
y
\end{bmatrix}
\sim
\mathcal{N}\left(
\begin{bmatrix}
\mu_x\\
\mu_y
\end{bmatrix},
\begin{bmatrix}
\Sigma_{xx} & \Sigma_{xy}\\
\Sigma_{yx} & \Sigma_{yy}
\end{bmatrix}
\right)
$$

\(y\)를 관측하지 않고 \(x\)만 보면 주변분포가 된다.

$$
p(x)=\mathcal{N}(\mu_x,\Sigma_{xx})
$$

\(y\)를 관측한 뒤 \(x\)의 분포를 보면 조건부분포가 된다.

$$
p(x\mid y)=
\mathcal{N}(\mu_{x\mid y},\Sigma_{x\mid y})
$$

조건부 평균은 관측된 \(y\)가 평균 \(\mu_y\)에서 얼마나 벗어났는지에 따라 \(x\)의 평균을 조정한다.

$$
\mu_{x\mid y}
=
\mu_x+\Sigma_{xy}\Sigma_{yy}^{-1}(y-\mu_y)
$$

조건부 공분산은 다음과 같다.

$$
\Sigma_{x\mid y}
=
\Sigma_{xx}
-\Sigma_{xy}\Sigma_{yy}^{-1}\Sigma_{yx}
$$

시험에서 이 식 전체를 외우라는 형태보다는 "주변분포와 조건부분포가 무엇이고, Gaussian에서는 둘 다 다시 Gaussian이다"를 묻는 문제가 더 가능성이 높다.

### 1.13 확률변수의 합과 분포의 합은 다르다

강의에서 강조된 핵심 구분이다.

첫 번째는 확률변수를 더하는 경우다.

$$
Z=X+Y
$$

\(X\), \(Y\)가 서로 독립이고

$$
X\sim\mathcal{N}(\mu_X,\sigma_X^2),
\qquad
Y\sim\mathcal{N}(\mu_Y,\sigma_Y^2)
$$

라면

$$
Z\sim
\mathcal{N}(\mu_X+\mu_Y,\sigma_X^2+\sigma_Y^2)
$$

두 번째는 분포 자체를 가중합하는 경우다.

$$
p(x)=a p_1(x)+(1-a)p_2(x)
$$

이것은 mixture distribution이다. \(p_1\), \(p_2\)가 각각 Gaussian이어도 \(p(x)\)는 일반적으로 하나의 Gaussian이 아니다. 두 봉우리를 가진 분포가 될 수도 있다.

따라서 "Gaussian random variable의 합"과 "Gaussian distribution의 mixture"를 반드시 구분해야 한다.

Gaussian이 보장되지 않는 조건도 같이 정리해야 한다.

| 상황 | Gaussian 보장 여부 | 이유 |
|---|---|---|
| Joint Gaussian의 선형결합 | 보장 | joint Gaussian은 선형결합에 닫혀 있다. |
| 서로 독립인 Gaussian 확률변수의 합 | 보장 | 독립이면 평균과 분산을 더해 Gaussian이 된다. |
| 각각의 marginal만 Gaussian임 | 보장되지 않음 | 두 변수가 joint Gaussian이라는 정보가 없으면 합이 Gaussian이라고 할 수 없다. |
| Gaussian mixture | 보장되지 않음 | density를 더한 mixture는 일반적으로 하나의 Gaussian이 아니다. |
| Nonlinear transformation | 보장되지 않음 | 선형변환과 달리 일반 nonlinear 함수는 Gaussian을 보존하지 않는다. |

즉, "Gaussian이다"가 자동으로 유지되는 대표 조건은 joint Gaussian의 선형변환 또는 독립 Gaussian의 합이다. 그 외에는 반례가 가능하다고 생각해야 한다.

### 1.14 변수변환과 선형변환

변수변환은 확률변수 \(X\)를 다른 함수 \(Y=g(X)\)로 바꾸었을 때, \(Y\)의 분포를 구하는 과정이다. 일대일 변환에서는 density의 면적이 보존되도록 Jacobian 보정이 들어간다.

$$
p_Y(y)
=
p_X(g^{-1}(y))
\left\lvert
\frac{d}{dy}g^{-1}(y)
\right\rvert
$$

변수변환 자체는 기말 범위에서 제외될 수 있지만, Gaussian의 선형변환 공식은 중요도가 높으므로 외워두는 편이 안전하다.

$$
X\sim\mathcal{N}(\mu,\Sigma),
\qquad
Y=AX+b
$$

이면

$$
Y\sim
\mathcal{N}(A\mu+b,A\Sigma A^T)
$$

일변수에서는 다음처럼 단순화된다.

$$
X\sim\mathcal{N}(\mu,\sigma^2),
\qquad
Y=aX+b
$$

$$
Y\sim
\mathcal{N}(a\mu+b,a^2\sigma^2)
$$

평균은 선형적으로 변하지만, 분산은 scale의 제곱이 곱해진다.

## 2. 최적화 이론: 2문제 범위

최적화 이론은 학습 과정에서 parameter를 어떻게 움직이는지 묻는 범위다. 시험에서는 SGD, mini-batch, convex function의 정의와 차이를 정확히 쓰는 것이 중요하다.

### 2.1 Gradient Descent의 기본 형태

최적화 문제는 보통 다음과 같이 쓴다.

$$
\min_{\theta} L(\theta)
$$

Gradient \(\nabla_\theta L(\theta)\)는 현재 위치에서 loss가 가장 빠르게 증가하는 방향이다. 최소화를 위해서는 그 반대 방향으로 이동한다.

$$
\theta_{t+1}
=
\theta_t-\eta\nabla_\theta L(\theta_t)
$$

여기서 \(\eta\)는 learning rate 또는 step size다.

| learning rate | 결과 |
|---|---|
| 너무 작음 | 안정적이지만 수렴이 느리다. |
| 적절함 | loss를 줄이며 최소점 근처로 간다. |
| 너무 큼 | 최소점을 지나치거나 발산할 수 있다. |

### 2.2 확률적 경사 하강법

전체 loss가 \(N\)개 데이터 loss의 합이라고 하자.

$$
L(\theta)
=
\sum_{n=1}^{N}L_n(\theta)
$$

Full-batch gradient descent는 매번 전체 데이터를 사용한다.

$$
\theta_{t+1}
=
\theta_t
-\eta
\sum_{n=1}^{N}
\nabla_\theta L_n(\theta_t)
$$

SGD(stochastic gradient descent)는 전체 데이터 대신 한 개 또는 일부 sample로 gradient를 근사한다.

한 sample \(i\)만 쓰는 경우:

$$
\theta_{t+1}
=
\theta_t
-\eta\nabla_\theta L_i(\theta_t)
$$

SGD의 장점은 update가 빠르고 자주 일어난다는 것이다. 단점은 gradient가 noisy해서 경로가 흔들릴 수 있다는 것이다. 이 noise는 수렴을 불안정하게 만들 수도 있지만, saddle point나 나쁜 local region을 빠져나오는 데 도움을 줄 수도 있다.

### 2.3 Mini-batch

Mini-batch는 한 번의 update에 사용하는 데이터 부분집합 \(B\)다. Mini-batch gradient는 다음과 같다.

$$
g_B(\theta_t)
=
\frac{1}{\lvert B\rvert}
\sum_{n\in B}
\nabla_\theta L_n(\theta_t)
$$

Update는 다음처럼 쓴다.

$$
\theta_{t+1}
=
\theta_t-\eta g_B(\theta_t)
$$

강의처럼 전체 gradient의 합을 근사하는 표기를 쓰면 다음과 같다.

$$
\sum_{n=1}^{N}\nabla_\theta L_n(\theta_t)
\approx
\frac{N}{\lvert B\rvert}
\sum_{n\in B}
\nabla_\theta L_n(\theta_t)
$$

세 방식의 차이는 다음과 같다.

| 방식 | 한 update에 쓰는 데이터 | 장점 | 단점 |
|---|---:|---|---|
| Full-batch GD | 전체 데이터 | gradient가 안정적 | update 비용이 큼 |
| SGD | 1개 sample | 빠르고 자주 update | noise가 큼 |
| Mini-batch SGD | 일부 sample | 속도와 안정성의 절충 | batch size 조절 필요 |

시험에서는 mini-batch가 단순히 "데이터를 작게 나눔"이 아니라, 전체 gradient를 일부 sample 평균으로 근사하는 방법이라는 점을 써야 한다.

Batch size에 따른 직관도 기억해야 한다.

| mini-batch 크기 | 해석 |
|---|---|
| 큼 | 전체 데이터를 더 잘 대표하므로 gradient가 안정적이다. 대신 update 하나가 비싸다. |
| 작음 | 계산은 빠르지만 gradient noise가 커진다. 항상 나쁜 것은 아니며, 적당한 noise는 탐색에 도움이 될 수 있다. |

### 2.4 Momentum Gradient Descent

Momentum gradient descent는 현재 gradient뿐 아니라 이전 update 방향을 함께 사용한다. 기본 gradient descent가 매 순간의 경사만 보고 움직인다면, momentum은 이전에 움직이던 방향에 관성을 더한다.

$$
\Delta\theta_t
=
-\eta\nabla_\theta L(\theta_t)
+\alpha\Delta\theta_{t-1}
$$

$$
\theta_{t+1}
=
\theta_t+\Delta\theta_t
$$

여기서 \(\alpha\)는 momentum coefficient다.

Momentum의 핵심 효과는 다음과 같다.

| 상황 | Momentum 효과 |
|---|---|
| 같은 방향 gradient가 반복됨 | update가 누적되어 더 빠르게 이동 |
| 좌우로 진동하는 방향 | 반대 방향 update가 일부 상쇄 |
| 길고 좁은 valley | zigzag를 줄이고 valley 방향 이동을 강화 |

시험에서 자세한 유도까지 요구하지 않더라도, momentum이 "이전 update를 반영해 zigzag를 줄이고 수렴을 빠르게 하는 방법"이라는 점은 알아두어야 한다.

### 2.5 Newton-Raphson Method

Newton method 또는 Newton-Raphson method는 gradient뿐 아니라 Hessian, 즉 2차 미분 정보를 사용한다. 현재 위치 \(\theta_t\) 근처에서 목적함수를 2차 Taylor approximation으로 근사한 뒤, 그 근사의 최소점을 다음 위치로 선택한다.

Gradient와 Hessian을 다음처럼 두자.

$$
g_t=\nabla f(\theta_t),
\qquad
H_t=\nabla^2 f(\theta_t)
$$

Newton update는 다음과 같다.

$$
\theta_{t+1}
=
\theta_t-H_t^{-1}g_t
$$

Step size 또는 damping을 넣으면 다음처럼 쓸 수 있다.

$$
\theta_{t+1}
=
\theta_t-\eta H_t^{-1}g_t
$$

Gradient descent는 기울기 방향만 보고 움직인다. Newton method는 Hessian으로 곡률까지 반영하므로 적절한 조건에서는 빠르게 수렴할 수 있다. 대신 Hessian 계산과 inverse가 비싸고, Hessian이 invertible하지 않거나 positive definite가 아니면 update가 불안정할 수 있다.

| 방법 | 사용하는 정보 | 장점 | 단점 |
|---|---|---|---|
| Gradient Descent | 1차 미분 | 단순하고 큰 모델에 적용 가능 | 수렴이 느릴 수 있음 |
| Newton Method | 1차 미분과 2차 미분 | 곡률을 반영해 빠르게 이동 가능 | Hessian 계산과 inverse가 비쌈 |

### 2.6 Convex function

함수 \(f\)가 convex라는 것은 두 점을 잇는 직선 위의 함수값이 양 끝 함수값을 선형 보간한 값보다 크지 않다는 뜻이다.

$$
f(\lambda x+(1-\lambda)y)
\le
\lambda f(x)+(1-\lambda)f(y)
$$

여기서

$$
0\le\lambda\le 1
$$

직관적으로 convex function은 그릇 모양이다. 중요한 성질은 local minimum이 global minimum이라는 것이다.

| 개념 | 의미 |
|---|---|
| Local minimum | 근처 점들보다 함수값이 작은 지점 |
| Global minimum | 전체 영역에서 함수값이 가장 작은 지점 |
| Convex function | local minimum이 global minimum이 되는 구조 |

미분 가능한 convex function에서 \(\nabla f(x^*)=0\)이면 \(x^*\)는 global minimum이다. 반대로 non-convex function에서는 gradient가 0이어도 local minimum, saddle point, local maximum일 수 있다.

2차 함수

$$
f(x)=x^TAx+b^Tx+c
$$

에서 \(A\)가 positive semidefinite이면 convex다.

Convex를 증명해야 한다면 정의를 그대로 사용한다.

1. 임의의 두 점 \(x,y\)와 \(0\le\lambda\le 1\)를 둔다.
2. \(f(\lambda x+(1-\lambda)y)\)를 전개한다.
3. 이것이 \(\lambda f(x)+(1-\lambda)f(y)\)보다 작거나 같음을 보인다.

Convex가 아님을 보이면 한 쌍의 반례만 찾으면 된다. 즉, 어떤 \(x,y,\lambda\)에 대해

$$
f(\lambda x+(1-\lambda)y)
>
\lambda f(x)+(1-\lambda)f(y)
$$

가 성립하면 convex가 아니다. 시험에서 "성립하지 않는 예시를 보이라"는 형태로 나오면 이 반례 전략을 쓰면 된다.

## 3. Model and Data: 1문제 범위

이 범위는 "모델과 데이터가 만났을 때 parameter를 어떻게 추정하는가"를 묻는다. 핵심은 결정론적 모델과 확률 모델의 차이, ERM, MLE, MAP, cross validation, regularization, DGM을 하나의 흐름으로 연결하는 것이다.

### 3.1 결정론적 함수와 확률분포로서의 모델

결정론적 함수로서의 모델은 입력 \(x\)가 주어지면 하나의 예측값을 출력한다.

$$
\hat{y}=f_\theta(x)
$$

예를 들어 선형 모델은 다음처럼 쓸 수 있다.

$$
f_\theta(x)=\theta^Tx+\theta_0
$$

반면 확률분포로서의 모델은 하나의 값만 예측하지 않고, 출력이 어떤 분포를 따르는지 표현한다.

$$
p(y\mid x,\theta)
$$

회귀 문제에서 observation noise를 고려하면 다음처럼 쓸 수 있다.

$$
y=f_\theta(x)+\epsilon,
\qquad
\epsilon\sim\mathcal{N}(0,\sigma^2)
$$

그러면

$$
p(y\mid x,\theta)
=
\mathcal{N}(y\mid f_\theta(x),\sigma^2)
$$

이다.

| 관점 | 출력 | 장점 |
|---|---|---|
| 결정론적 모델 | 하나의 예측값 \(\hat{y}\) | 단순하고 loss 기반 학습과 연결이 쉽다. |
| 확률 모델 | 예측 분포 \(p(y\mid x,\theta)\) | noise와 불확실성을 표현하고 likelihood, posterior와 연결된다. |

### 3.2 ERM

Empirical Risk Minimization(ERM)은 training data에 대한 평균 loss를 최소화하는 방식이다.

$$
R_{\mathrm{emp}}(\theta)
=
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f_\theta(x_i),y_i)
$$

ERM은 다음 parameter를 찾는다.

$$
\theta^*
=
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f_\theta(x_i),y_i)
$$

ERM은 결정론적 모델의 학습 원리로 이해할 수 있지만, 확률 모델과도 연결된다. 예를 들어 Gaussian observation noise를 가정하면 MLE의 negative log-likelihood가 squared error loss가 되므로, 선형회귀의 최소제곱은 ERM이면서 MLE다.

### 3.3 변수 추정

확률적 모델에서는 데이터가 어떤 분포에서 생성되었다고 가정하고, 그 분포의 parameter \(\theta\)를 추정한다.

관측 데이터가

$$
\mathcal{D}
=
\{(x_1,y_1),\ldots,(x_N,y_N)\}
$$

라고 하자. 모델은 보통 조건부분포로 표현한다.

$$
p(y\mid x,\theta)
$$

i.i.d. 가정 아래 likelihood는 sample likelihood의 곱으로 분해된다.

$$
p(\mathcal{D}\mid\theta)
=
\prod_{n=1}^{N}
p(y_n\mid x_n,\theta)
$$

MLE는 이 likelihood를 최대화한다.

$$
\theta_{\mathrm{MLE}}
=
\arg\max_{\theta}
p(\mathcal{D}\mid\theta)
$$

Log는 단조 증가 함수이므로 같은 해를 다음처럼 구할 수 있다.

$$
\theta_{\mathrm{MLE}}
=
\arg\max_{\theta}
\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

실제 최적화에서는 negative log-likelihood를 최소화한다.

$$
\theta_{\mathrm{MLE}}
=
\arg\min_{\theta}
-
\sum_{n=1}^{N}
\log p(y_n\mid x_n,\theta)
$$

### 3.4 MAP

MAP는 likelihood에 prior를 추가한다.

$$
p(\theta\mid\mathcal{D})
=
\frac{
p(\mathcal{D}\mid\theta)p(\theta)
}{
p(\mathcal{D})
}
$$

\(p(\mathcal{D})\)는 \(\theta\)에 대해 constant이므로

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
p(\mathcal{D}\mid\theta)p(\theta)
$$

Log를 취하면 곱이 합으로 바뀐다.

$$
\theta_{\mathrm{MAP}}
=
\arg\max_{\theta}
\left[
\log p(\mathcal{D}\mid\theta)
+
\log p(\theta)
\right]
$$

Negative log를 취하면 최소화 문제다.

$$
\theta_{\mathrm{MAP}}
=
\arg\min_{\theta}
\left[
-\log p(\mathcal{D}\mid\theta)
-\log p(\theta)
\right]
$$

따라서 MAP objective는 다음 구조를 가진다.

$$
\text{MAP objective}
=
\text{NLL}
-\log p(\theta)
$$

여기서 \(-\log p(\theta)\)가 regularization penalty처럼 작동한다. Zero-mean Gaussian prior를 두면 L2 regularization과 연결된다.

$$
p(\theta)
\propto
\exp\left(
-\frac{\lVert\theta\rVert^2}{2\tau^2}
\right)
$$

따라서

$$
-\log p(\theta)
=
\frac{1}{2\tau^2}\lVert\theta\rVert^2
+\mathrm{const}
$$

### 3.5 Regularization

Regularization은 training data에 너무 과하게 맞는 parameter를 피하기 위해 objective에 penalty를 더하는 방법이다.

$$
\arg\min_{\theta}
\frac{1}{N}
\sum_{i=1}^{N}
\ell(f_\theta(x_i),y_i)
+
\lambda\Omega(\theta)
$$

대표적으로 L2 regularization은 다음과 같다.

$$
\Omega(\theta)=\lVert\theta\rVert_2^2
$$

L1 regularization은 다음과 같다.

$$
\Omega(\theta)=\lVert\theta\rVert_1
$$

공통점은 둘 다 복잡하거나 큰 parameter를 억제해 overfitting을 줄이려는 목적을 가진다는 것이다. 차이점은 L2는 parameter를 부드럽게 작게 만들고, L1은 일부 parameter를 정확히 0으로 만들어 sparse solution을 유도할 수 있다는 점이다.

MAP와 regularization의 연결도 중요하다. MAP의 negative log objective에서 \(-\log p(\theta)\)가 penalty 역할을 한다. Gaussian prior는 L2 penalty와 연결되고, Laplace prior는 L1 penalty와 연결된다.

### 3.6 Cross Validation과 validation loss 해석

Cross validation은 모델 선택 또는 hyperparameter 선택을 더 안정적으로 하기 위해 training data를 여러 fold로 나누어 반복 검증하는 방법이다.

K-fold cross validation의 기본 절차는 다음과 같다.

1. 데이터를 \(K\)개의 fold로 나눈다.
2. \(K-1\)개 fold로 학습하고 남은 1개 fold로 validation loss를 계산한다.
3. validation fold를 바꾸어 \(K\)번 반복한다.
4. \(K\)개의 validation score 평균으로 모델을 비교한다.

Training loss와 validation loss의 조합은 다음처럼 해석한다.

| training loss | validation loss | 해석 | 대응 |
|---|---|---|---|
| 낮음 | 낮음 | 학습과 일반화가 모두 비교적 잘 됨 | 좋은 후보 |
| 낮음 | 높음 | training data에 과적합 | regularization, 모델 단순화, 데이터 보강 |
| 높음 | 높음 | 모델이 패턴을 충분히 못 잡음 | 모델 복잡도 증가, feature 개선, 학습 개선 |
| 높음 | 낮음 | 일반적이지 않은 상황 | 데이터 분리나 metric을 다시 확인 |

모델 선택에서 가장 중요한 것은 test data를 보고 모델을 고르지 않는 것이다. Validation data는 모델 선택용이고, test data는 최종 평가용이다.

### 3.7 Directed Graphical Models

Directed Graphical Model(DGM)은 확률변수 사이의 조건부 의존 관계를 방향 그래프로 표현한 모델이다.

| 구성 | 의미 |
|---|---|
| Node | 확률변수 |
| Arrow | 조건부 의존 관계 |
| Parent | 어떤 변수의 분포를 조건짓는 변수 |
| Factorization | joint distribution을 작은 conditional distribution의 곱으로 분해 |

세 변수 \(a,b,c\)가 chain rule로 연결되면 다음처럼 쓸 수 있다.

$$
p(a,b,c)
=
p(c\mid a,b)p(b\mid a)p(a)
$$

그래프 구조가 더 단순하면 joint distribution도 더 단순하게 분해된다.

$$
p(x_1,x_2,x_3,x_4,x_5)
=
p(x_1)p(x_5)
p(x_2\mid x_5)
p(x_3\mid x_1,x_2)
p(x_4\mid x_2)
$$

DGM의 시험 포인트는 그래프를 예쁘게 그리는 것이 아니라, "복잡한 joint distribution을 조건부 분포의 곱으로 나누어 표현한다"는 점이다.

## 4. 선형회귀: 1문제 범위

선형회귀는 MLE와 MAP의 대표 예시다. Gaussian noise를 가정하면 MLE가 squared error 최소화가 되고, Gaussian prior를 추가하면 MAP가 ridge regression 형태가 된다.

### 4.1 선형회귀 모델

학습 데이터는 다음과 같다.

$$
\mathcal{D}
=
\{(x_1,y_1),\ldots,(x_N,y_N)\}
$$

선형회귀는 관측값이 선형 함수와 noise의 합이라고 본다.

$$
y_n=x_n^T\theta+\epsilon_n
$$

Gaussian observation noise를 가정한다.

$$
\epsilon_n\sim\mathcal{N}(0,\sigma^2)
$$

그러면 조건부 분포는 다음과 같다.

$$
p(y_n\mid x_n,\theta)
=
\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

Basis function을 쓰면 \(x_n\) 대신 \(\phi(x_n)\)를 사용한다.

$$
p(y_n\mid x_n,\theta)
=
\mathcal{N}(y_n\mid \phi(x_n)^T\theta,\sigma^2)
$$

### 4.2 선형회귀 MLE

i.i.d. 가정 아래 전체 likelihood는 곱이다.

$$
p(Y\mid X,\theta)
=
\prod_{n=1}^{N}
\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)
$$

MLE는 likelihood를 최대화한다.

$$
\theta_{\mathrm{ML}}
=
\arg\max_{\theta}
p(Y\mid X,\theta)
$$

Negative log-likelihood를 쓰면 다음 objective가 나온다.

$$
L(\theta)
=
\frac{1}{2\sigma^2}
\sum_{n=1}^{N}
(y_n-x_n^T\theta)^2
+\mathrm{const}
$$

상수항과 양의 배율은 minimizer를 바꾸지 않는다. 따라서 Gaussian noise에서 선형회귀 MLE는 squared error 최소화와 같다.

$$
\theta_{\mathrm{ML}}
=
\arg\min_{\theta}
\lVert y-X\theta\rVert^2
$$

행렬 형태에서

$$
J(\theta)
=
(y-X\theta)^T(y-X\theta)
$$

를 미분하면

$$
\nabla_\theta J(\theta)
=
-2X^Ty+2X^TX\theta
$$

최적점에서는 gradient가 0이다.

$$
X^TX\theta=X^Ty
$$

이를 normal equation이라고 한다. \(X^TX\)가 invertible이면

$$
\theta_{\mathrm{ML}}
=
(X^TX)^{-1}X^Ty
$$

이다.

Basis expansion을 쓰면 \(X\) 대신 \(\Phi\)를 넣는다.

$$
\theta_{\mathrm{ML}}
=
(\Phi^T\Phi)^{-1}\Phi^Ty
$$

### 4.3 선형회귀 MAP

MAP에서는 parameter에 prior를 둔다. 대표적으로 zero-mean Gaussian prior를 사용한다.

$$
p(\theta)
=
\mathcal{N}(\theta\mid 0,b^2I)
$$

Likelihood는 Gaussian observation model에서 그대로 온다.

$$
p(Y\mid X,\theta)
=
\prod_{n=1}^{N}
\mathcal{N}(y_n\mid \phi(x_n)^T\theta,\sigma^2)
$$

MAP objective는 다음과 같다.

$$
\theta_{\mathrm{MAP}}
=
\arg\min_{\theta}
\left[
\frac{1}{2\sigma^2}
\lVert y-\Phi\theta\rVert^2
+
\frac{1}{2b^2}
\lVert\theta\rVert^2
\right]
$$

양의 상수 \(\sigma^2\)를 곱해도 minimizer는 바뀌지 않으므로 다음처럼 볼 수 있다.

$$
\theta_{\mathrm{MAP}}
=
\arg\min_{\theta}
\left[
\lVert y-\Phi\theta\rVert^2
+
\frac{\sigma^2}{b^2}
\lVert\theta\rVert^2
\right]
$$

Closed-form solution은 다음과 같다.

$$
\theta_{\mathrm{MAP}}
=
\left(
\Phi^T\Phi
+
\frac{\sigma^2}{b^2}I
\right)^{-1}
\Phi^Ty
$$

이 식은 ridge regression과 같은 형태다. Prior variance \(b^2\)가 작으면 parameter가 0 근처에 있어야 한다는 믿음이 강해져 regularization이 강해진다. Observation noise variance \(\sigma^2\)가 크면 데이터 자체를 덜 신뢰하게 되어 prior의 영향이 상대적으로 커진다.

### 4.4 최적해로 예측하기

MLE 또는 MAP로 parameter \(\hat{\theta}\)를 구했다면 새 입력 \(x_*\)에 대한 점 예측은 다음과 같다.

$$
\hat{y}_*
=
x_*^T\hat{\theta}
$$

Basis function을 쓰는 경우에는 다음과 같다.

$$
\hat{y}_*
=
\phi(x_*)^T\hat{\theta}
$$

확률 모델로 보면 예측값 하나만 내는 것이 아니라 예측 분포를 쓸 수 있다.

$$
p(y_*\mid x_*,\hat{\theta})
=
\mathcal{N}(y_*\mid x_*^T\hat{\theta},\sigma^2)
$$

Basis function을 쓰면 다음과 같다.

$$
p(y_*\mid x_*,\hat{\theta})
=
\mathcal{N}(y_*\mid \phi(x_*)^T\hat{\theta},\sigma^2)
$$

따라서 선형회귀 문제는 다음 순서로 답안을 구성하면 안정적이다.

1. 모델식 \(y=x^T\theta+\epsilon\) 또는 \(y=\phi(x)^T\theta+\epsilon\)을 쓴다.
2. Gaussian noise 가정으로 likelihood를 세운다.
3. MLE는 NLL을 최소화해 normal equation과 closed-form solution을 얻는다.
4. MAP는 Gaussian prior를 추가해 L2 penalty가 들어간 solution을 얻는다.
5. 구한 \(\hat{\theta}\)로 새 입력의 점 예측 또는 예측 분포를 쓴다.

## 5. 출제 배분에 맞춘 7문제 모의 구성

아래 7문제는 사용자가 정리한 출제 조건을 그대로 반영한 예상 구성이다.

<details>
<summary>1. Joint PMF table에서 marginal probability와 conditional probability를 계산하라.</summary>

답변: 먼저 joint PMF의 행 또는 열을 더해 marginal probability를 구한다. 예를 들어 \(p_X(x)=\sum_y p_{X,Y}(x,y)\), \(p_Y(y)=\sum_x p_{X,Y}(x,y)\)이다. 조건부 확률은 \(p_{X\mid Y}(x\mid y)=p_{X,Y}(x,y)/p_Y(y)\)로 계산한다. 분모가 조건으로 주어진 사건의 주변확률이라는 점을 확인한다.

</details>

<details>
<summary>2. Bayes 정리를 이용해 posterior를 계산하고 likelihood와 prior를 구분하라.</summary>

답변: Bayes 정리는 \(P(Y\mid X)=P(X\mid Y)P(Y)/P(X)\)이다. \(P(X\mid Y)\)는 likelihood, \(P(Y)\)는 prior, \(P(Y\mid X)\)는 posterior다. Evidence는 \(P(X)=\sum_i P(X\mid Y=y_i)P(Y=y_i)\)로 구하며 posterior를 정규화한다.

</details>

<details>
<summary>3. Gaussian 확률변수의 합과 Gaussian mixture의 차이를 설명하라.</summary>

답변: 확률변수의 합은 \(Z=X+Y\)처럼 random variable을 더하는 것이다. 독립 Gaussian \(X,Y\)의 합은 다시 Gaussian이고 평균과 분산이 더해진다. 반면 Gaussian mixture는 \(p(x)=a p_1(x)+(1-a)p_2(x)\)처럼 density를 가중합한 분포다. 각 성분이 Gaussian이어도 mixture 전체는 일반적으로 하나의 Gaussian이 아니다.

</details>

<details>
<summary>4. Gradient descent update, step size, mini-batch, momentum을 설명하라.</summary>

답변: 기본 gradient descent는 \(\theta_{t+1}=\theta_t-\eta\nabla_\theta L(\theta_t)\)이다. Step size \(\eta\)가 너무 작으면 느리고, 너무 크면 overshooting이나 발산이 생긴다. Mini-batch는 \(g_B(\theta_t)=\frac{1}{\lvert B\rvert}\sum_{n\in B}\nabla_\theta L_n(\theta_t)\)로 일부 데이터의 평균 gradient를 계산해 update한다. Batch가 크면 안정적이고, 작으면 noisy하지만 빠르다. Momentum은 이전 update \(\Delta\theta_{t-1}\)를 현재 update에 반영해 zigzag를 줄인다.

</details>

<details>
<summary>5. Newton method와 convex function의 정의, 증명 또는 반례 방법을 설명하라.</summary>

답변: Newton method는 \(\theta_{t+1}=\theta_t-H_t^{-1}g_t\)처럼 gradient와 Hessian을 함께 사용한다. 곡률을 반영하므로 빠르게 수렴할 수 있지만 Hessian 계산과 inverse가 비싸다. Convex function은 \(f(\lambda x+(1-\lambda)y)\le \lambda f(x)+(1-\lambda)f(y)\), \(0\le\lambda\le 1\)을 만족하는 함수다. Convex를 증명하려면 정의를 전개해 부등식을 보이고, convex가 아님을 보이려면 이 부등식을 깨는 \(x,y,\lambda\) 반례 하나를 제시하면 된다.

</details>

<details>
<summary>6. Model and Data에서 ERM, MLE, MAP, CV, regularization, DGM을 연결해 설명하라.</summary>

답변: 결정론적 모델은 \(\hat{y}=f_\theta(x)\)처럼 하나의 예측값을 내고, 확률 모델은 \(p(y\mid x,\theta)\)처럼 예측 분포를 낸다. ERM은 training 평균 loss를 최소화한다. MLE는 \(\theta_{\mathrm{MLE}}=\arg\max_\theta p(\mathcal{D}\mid\theta)\)로 likelihood를 최대화하고, MAP는 \(\theta_{\mathrm{MAP}}=\arg\max_\theta p(\mathcal{D}\mid\theta)p(\theta)\)로 prior까지 반영한다. Negative log를 취하면 prior 항이 regularization penalty처럼 작동한다. Cross validation은 validation loss로 모델을 고르는 절차이며, DGM은 joint distribution을 조건부 분포의 곱으로 factorization한다.

</details>

<details>
<summary>7. 선형회귀에서 MLE와 MAP objective를 각각 유도하라.</summary>

답변: Gaussian noise \(\epsilon\sim\mathcal{N}(0,\sigma^2)\)를 가정하면 \(p(y_n\mid x_n,\theta)=\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)\)이다. Negative log-likelihood는 \(\frac{1}{2\sigma^2}\lVert y-X\theta\rVert^2+\mathrm{const}\)이므로 MLE는 squared error를 최소화한다. Gaussian prior \(p(\theta)=\mathcal{N}(0,b^2I)\)를 추가하면 MAP objective는 \(\frac{1}{2\sigma^2}\lVert y-\Phi\theta\rVert^2+\frac{1}{2b^2}\lVert\theta\rVert^2\)가 된다.

</details>

## 마지막 핵심 정리

| 범위 | 반드시 기억할 식 | 한 줄 해석 |
|---|---|---|
| PMF | \(p_X(x)=P(X=x)\) | 이산확률변수에서 값 하나의 확률 |
| PDF | \(P(a<X\le b)=\int_a^b f_X(x)\,dx\) | 연속확률변수에서 구간 확률을 만드는 density |
| CDF | \(F_X(x)=P(X\le x)\) | 기준값 이하의 누적확률 |
| Joint PMF | \(p_{X,Y}(x,y)=P(X=x,Y=y)\) | 두 확률변수의 동시 확률 |
| Marginalization | \(p_X(x)=\sum_y p_{X,Y}(x,y)\) | 필요 없는 변수를 더해서 제거 |
| Conditional | \(p_{X\mid Y}(x\mid y)=p_{X,Y}(x,y)/p_Y(y)\) | 조건으로 주어진 사건의 확률로 나눔 |
| Independence | \(p_{X,Y}(x,y)=p_X(x)p_Y(y)\) | joint가 marginal product로 분해 |
| Bayes | posterior \(\propto\) likelihood \(\times\) prior | 관측 후 믿음을 갱신 |
| Expectation | \(\mathbb{E}[X]=\sum_x xp_X(x)\) | 확률가중평균 |
| Gaussian transform | \(AX+b\sim\mathcal{N}(A\mu+b,A\Sigma A^T)\) | Gaussian은 선형변환 후에도 Gaussian |
| SGD | \(\theta_{t+1}=\theta_t-\eta\nabla_\theta L_i(\theta_t)\) | 일부 sample로 빠르게 update |
| Mini-batch | \(g_B=\frac{1}{\lvert B\rvert}\sum_{n\in B}\nabla_\theta L_n\) | 전체 gradient를 subset 평균으로 근사 |
| Momentum | \(\Delta\theta_t=-\eta\nabla L(\theta_t)+\alpha\Delta\theta_{t-1}\) | 이전 update를 반영해 zigzag 완화 |
| Newton | \(\theta_{t+1}=\theta_t-H_t^{-1}g_t\) | Hessian으로 곡률까지 반영 |
| Convex | \(f(\lambda x+(1-\lambda)y)\le\lambda f(x)+(1-\lambda)f(y)\) | local minimum이 global minimum |
| ERM | \(\arg\min_\theta \frac{1}{N}\sum_i \ell(f_\theta(x_i),y_i)\) | training 평균 loss 최소화 |
| MLE | \(\arg\max_\theta p(\mathcal{D}\mid\theta)\) | 데이터를 가장 그럴듯하게 하는 parameter |
| MAP | \(\arg\max_\theta p(\mathcal{D}\mid\theta)p(\theta)\) | likelihood에 prior를 추가 |
| Cross validation | validation loss 평균 비교 | 모델 선택을 더 안정적으로 수행 |
| Regularization | loss \(+\lambda\Omega(\theta)\) | 큰 parameter나 복잡한 해를 억제 |
| Linear MLE | \((X^TX)^{-1}X^Ty\) | Gaussian noise에서 최소제곱 해 |
| Linear MAP | \((\Phi^T\Phi+\frac{\sigma^2}{b^2}I)^{-1}\Phi^Ty\) | Gaussian prior가 L2 penalty를 만든 해 |
| Linear prediction | \(\hat{y}_*=x_*^T\hat{\theta}\) | 구한 parameter로 새 입력 예측 |

## Study Guide

1. 먼저 확률과 분포 파트를 계산 중심으로 공부한다. Joint PMF table 하나를 놓고 marginal, conditional, independence, Bayes를 모두 계산할 수 있으면 3문제 중 상당 부분을 커버할 수 있다.
2. Bayes 정리는 이름을 외우는 것보다 posterior, likelihood, prior, evidence의 역할을 말로 설명하는 연습이 중요하다. 특히 MAP에서 log를 취하면 prior가 penalty로 추가되는 흐름을 연결한다.
3. Gaussian은 PDF 공식보다 성질이 중요하다. 주변분포와 조건부분포가 다시 Gaussian이라는 점, 확률변수의 합과 mixture가 다르다는 점, 선형변환에서 평균과 공분산이 어떻게 바뀌는지 정리한다.
4. 최적화는 update 식을 직접 쓸 수 있어야 한다. Full-batch, SGD, mini-batch의 차이는 "얼마나 많은 데이터로 gradient를 계산하는가"와 "noise와 비용의 trade-off"로 정리한다. Momentum은 이전 update 반영, Newton은 Hessian 반영으로 구분한다.
5. Convex function은 정의식과 local minimum/global minimum 관계를 함께 암기한다. 증명 문제는 정의를 전개하고, 반례 문제는 정의 부등식을 깨는 점 두 개와 \(\lambda\)를 제시한다.
6. Model and Data는 결정론적 모델과 확률 모델, ERM과 MLE의 연결, validation loss 해석, regularization과 MAP의 연결을 한 흐름으로 정리한다.
7. 선형회귀는 Gaussian noise에서 squared error가 나오고, Gaussian prior에서 L2 penalty가 나오는 두 문장을 중심으로 유도식을 붙인다. 마지막에는 구한 \(\hat{\theta}\)로 \(\hat{y}_*=x_*^T\hat{\theta}\)를 예측한다.
헷갈리기 쉬운 부분은 다음처럼 구분한다.

| 헷갈리는 쌍 | 구분 |
|---|---|
| PMF와 PDF | PMF는 확률값, PDF는 density이며 구간 적분이 확률 |
| Conditional과 joint | conditional은 joint를 조건 사건의 marginal로 나눈 값 |
| Likelihood와 posterior | likelihood는 parameter를 가정했을 때 데이터의 그럴듯함, posterior는 데이터를 본 뒤 parameter의 분포 |
| MLE와 MAP | MLE는 prior 없음, MAP는 prior 있음 |
| Random variable sum과 mixture | 확률변수를 더하는 것과 density를 가중합하는 것은 다름 |
| SGD와 mini-batch | SGD는 보통 한 sample 또는 stochastic 근사, mini-batch는 작은 sample 묶음 |

## 복습 질문

<details>
<summary>1. 확률의 세 조건은 무엇인가?</summary>

답변: Nonnegativity \(P(A)\ge 0\), normalization \(P(S)=1\), additivity \(P(A\cup B)=P(A)+P(B)\) for disjoint events이다. 여기서 여사건 확률 \(P(A^c)=1-P(A)\), 일반 합집합 확률 \(P(A\cup B)=P(A)+P(B)-P(A\cap B)\)가 따라온다.

</details>

<details>
<summary>2. Joint PMF에서 marginal PMF는 어떻게 구하는가?</summary>

답변: 관심 없는 변수를 가능한 모든 값에 대해 더한다. 즉, \(p_X(x)=\sum_y p_{X,Y}(x,y)\), \(p_Y(y)=\sum_x p_{X,Y}(x,y)\)이다. Joint table에서는 행합 또는 열합이 marginal probability다.

</details>

<details>
<summary>3. 독립 확률변수인지 판단하는 기준은 무엇인가?</summary>

답변: 모든 \(x,y\)에 대해 \(p_{X,Y}(x,y)=p_X(x)p_Y(y)\)가 성립해야 한다. 조건부 확률로는 \(p_{X\mid Y}(x\mid y)=p_X(x)\)가 성립해야 한다. 한 칸이라도 다르면 독립이 아니다.

</details>

<details>
<summary>4. CDF와 PDF의 관계는 무엇인가?</summary>

답변: CDF는 \(F_X(x)=P(X\le x)\)이고, PDF는 CDF의 미분 \(f_X(x)=dF_X(x)/dx\)로 볼 수 있다. 구간 확률은 \(P(a<X\le b)=F_X(b)-F_X(a)=\int_a^b f_X(x)\,dx\)이다.

</details>

<details>
<summary>5. Bayes 정리에서 likelihood와 prior는 각각 무엇인가?</summary>

답변: \(P(Y\mid X)=P(X\mid Y)P(Y)/P(X)\)에서 \(P(X\mid Y)\)가 likelihood, \(P(Y)\)가 prior다. Parameter notation에서는 \(p(\mathcal{D}\mid\theta)\)가 likelihood, \(p(\theta)\)가 prior다.

</details>

<details>
<summary>6. Gaussian random variable의 선형변환 결과는 어떻게 되는가?</summary>

답변: \(X\sim\mathcal{N}(\mu,\Sigma)\), \(Y=AX+b\)이면 \(Y\sim\mathcal{N}(A\mu+b,A\Sigma A^T)\)이다. 일변수에서는 \(Y=aX+b\)일 때 평균은 \(a\mu+b\), 분산은 \(a^2\sigma^2\)가 된다.

</details>

<details>
<summary>7. Mini-batch SGD에서 batch size가 작으면 어떤 장단점이 있는가?</summary>

답변: Batch size가 작으면 한 update의 계산 비용이 작고 자주 parameter를 움직일 수 있다. 대신 gradient noise가 커져 수렴 경로가 흔들릴 수 있다. 적당한 noise는 saddle point를 벗어나는 데 도움을 줄 수도 있지만, 너무 크면 수렴이 불안정해진다.

</details>

<details>
<summary>8. Convex function에서 local minimum이 중요한 이유는 무엇인가?</summary>

답변: Convex function에서는 local minimum이 곧 global minimum이다. 따라서 non-convex 문제와 달리 "근처에서만 좋은 해"와 "전체에서 가장 좋은 해"가 분리되지 않는다. 미분 가능한 convex function에서 gradient가 0인 점은 global optimum으로 해석할 수 있다.

</details>

<details>
<summary>9. Newton method는 gradient descent와 무엇이 다른가?</summary>

답변: Gradient descent는 \(\theta_{t+1}=\theta_t-\eta\nabla f(\theta_t)\)처럼 1차 미분만 사용한다. Newton method는 \(\theta_{t+1}=\theta_t-H_t^{-1}g_t\)처럼 gradient \(g_t\)와 Hessian \(H_t\)를 함께 사용한다. 곡률 정보를 반영하므로 빠를 수 있지만 Hessian 계산과 inverse 비용이 크다.

</details>

<details>
<summary>10. Training loss와 validation loss 조합은 어떻게 해석하는가?</summary>

답변: training loss와 validation loss가 모두 낮으면 좋은 후보로 볼 수 있다. Training loss는 낮지만 validation loss가 높으면 overfitting 가능성이 크다. 둘 다 높으면 underfitting 또는 학습 부족일 수 있다. Training loss가 높은데 validation loss가 낮다면 데이터 분리, metric, 구현을 다시 확인해야 한다.

</details>

<details>
<summary>11. DGM은 무엇을 표현하고 왜 쓰는가?</summary>

답변: Directed Graphical Model은 node로 확률변수를, arrow로 조건부 의존 관계를 표현한다. DGM을 쓰면 복잡한 joint distribution을 작은 conditional distribution들의 곱으로 factorization할 수 있다. 예를 들어 \(p(x_1,x_2,x_3)=p(x_1)p(x_2\mid x_1)p(x_3\mid x_2)\)처럼 구조를 드러낼 수 있다.

</details>

<details>
<summary>12. MAP에서 log를 취하면 prior가 왜 추가 항처럼 보이는가?</summary>

답변: MAP는 \(p(\mathcal{D}\mid\theta)p(\theta)\)를 최대화한다. Log를 취하면 곱이 \(\log p(\mathcal{D}\mid\theta)+\log p(\theta)\)라는 합으로 바뀐다. Negative log minimization으로 바꾸면 \(-\log p(\mathcal{D}\mid\theta)-\log p(\theta)\)가 되어, \(-\log p(\theta)\)가 regularization penalty처럼 추가된다.

</details>

<details>
<summary>13. 선형회귀 MLE에서 squared error가 나오는 이유는 무엇인가?</summary>

답변: 관측 noise를 \(\epsilon\sim\mathcal{N}(0,\sigma^2)\)로 가정하면 \(p(y_n\mid x_n,\theta)=\mathcal{N}(y_n\mid x_n^T\theta,\sigma^2)\)이다. Gaussian density의 negative log를 취하면 \((y_n-x_n^T\theta)^2/(2\sigma^2)\) 항이 나오므로, 전체 NLL 최소화는 squared error 합 최소화와 같은 문제가 된다.

</details>

<details>
<summary>14. PMF, PDF, CDF의 정의와 차이를 설명하라.</summary>

답변: PMF는 이산확률변수에서 \(p_X(x)=P(X=x)\)로 정의되며, 값 하나의 확률을 직접 준다. PDF는 연속확률변수에서 쓰는 확률밀도함수로, \(f_X(x)\) 자체는 확률이 아니라 density이고 구간 확률은 \(\int_a^b f_X(x)\,dx\)로 구한다. CDF는 \(F_X(x)=P(X\le x)\)로 정의되는 누적분포함수이며, 기준값 \(x\) 이하의 확률을 나타낸다. 연속확률변수에서는 \(F_X(x)=\int_{-\infty}^{x}f_X(t)\,dt\)이고, 미분 가능하면 \(f_X(x)=dF_X(x)/dx\)이다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-11.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-11.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-12.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-12.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-13.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-13.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-14.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-14.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-15.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-15.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-16.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-16.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-17.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-17.pdf</a></li>
</ul>
