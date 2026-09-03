---
layout: default
date: 2026-05-20 12:30:12 +0900
last_modified_at: 2026-09-03 17:14:00 +0900
title: "Lecture 01 Models and Data"
course: "Machine Learning Basic"
topic: "Models and Data"
order: 1
major_topic: "Machine Learning Foundations"
keywords:
  - "Models"
  - "Data"
  - "Features"
  - "Labels"
  - "Prediction"
---

# Lecture 01 Models and Data

Source PDF: `machine-learning-basic-lecture-01.pdf`

> **핵심:** **feature vector란** 원본 데이터를 모델 입력용 수치 벡터로 표현한 것. **preprocessing이 중요한 이유는** 스케일과 품질을 맞춰 학습을 안정화하기 위해.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 데이터 | 머신러닝에서 데이터는 어떤 형태로 다루는가? |
| 2 | 벡터화 | 원본 데이터를 feature vector로 바꾸는 이유는 무엇인가? |
| 3 | 데이터 처리 | selection, preprocessing, augmentation은 왜 중요한가? |
| 4 | 모델 | 모델은 함수인가, 확률분포인가? |
| 5 | 학습 | training, model selection, inference는 어떻게 구분되는가? |

## 1. 데이터와 feature vector

현대 머신러닝 모델이 작동할 수 있었던 핵심 배경은 많은 데이터다. 이 수업에서는 데이터를 컴퓨터가 읽을 수 있는 테이블 형태의 수치 데이터로 가정한다.

원본 데이터는 바로 모델에 넣기 어렵다. 전문가나 전처리 과정이 원본 데이터를 여러 특징값으로 바꾸고, 각 데이터는 $$D$$차원의 feature vector가 된다.

$$N$$개의 데이터가 있고 각 데이터가 $$D$$차원 feature를 가진다면 feature matrix는 다음처럼 표현한다.

$$
X \in \mathbb{R}^{N \times D}
$$

연속적인 수치 feature는 보통 평균이 0, 분산이 1이 되도록 조정한다. 이는 특정 feature의 스케일이 너무 커서 학습을 지배하지 않도록 하기 위한 기본 전처리다.

### 1.1 표준화 공식, 단위, 성립 조건

> **원문 대응과 작성자 보충:** 강의 PDF p.4는 연속형 feature를 평균 0, 분산 1로 조정한다고 설명하지만 계산식과 성립 과정은 제시하지 않는다. 아래 공식, 증명, 실패 조건은 그 원문 메시지를 실제 계산으로 연결한 **작성자 보충 해설**이다.

학습 집합에서 feature $$j$$의 평균과 표준편차를

$$
\mu_j=\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}x_{ij},
\qquad
\sigma_j=\sqrt{\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}(x_{ij}-\mu_j)^2}
$$

로 계산하면 표준화된 값은

$$
z_{ij}=\frac{x_{ij}-\mu_j}{\sigma_j}
$$

이다. 여기서 $$x_{ij}$$는 sample $$i$$의 feature $$j$$, $$N_{\mathrm{train}}$$은 학습 sample 수다. 위 식은 population-style 분모 $$N_{\mathrm{train}}$$을 사용한다. 통계 추정에서 sample standard deviation을 쓰면 분모가 $$N_{\mathrm{train}}-1$$이 될 수 있으므로, 학습과 추론에서 같은 정의를 사용해야 한다.

- **가정:** $$\sigma_j>0$$이고, train·validation·test가 같은 feature 정의와 단위를 사용한다.
- **단위:** $$x_{ij}$$와 $$\mu_j$$는 원 feature의 단위, $$\sigma_j$$도 같은 단위이므로 $$z_{ij}$$는 무차원이다.
- **정확성과 근사:** 저장한 $$\mu_j,\sigma_j$$로 같은 값을 변환한다는 식 자체는 정확하다. 유한 표본의 평균 0·분산 1은 **학습 집합과 선택한 분산 정의에서만** 정확하며, validation/test에서는 일반적으로 근사조차 보장되지 않는다.
- **누수 방지:** validation/test까지 합쳐 $$\mu_j,\sigma_j$$를 구하면 평가 데이터 정보가 학습 전처리에 들어가는 data leakage다. 학습 집합에서만 추정하고 그 값을 나머지 split에 재사용한다.
- **실패 조건:** $$\sigma_j=0$$인 상수 feature에서는 0으로 나누므로 해당 feature를 제거하거나 명시적인 정책을 둬야 한다. 매우 작은 $$\sigma_j$$는 noise를 크게 증폭한다.
- **한계:** 평균과 표준편차는 outlier에 민감하다. heavy-tailed feature에는 median/IQR 기반 robust scaling이 더 적절할 수 있고, binary·categorical·희소 feature에는 표준화를 기계적으로 적용하면 의미나 sparsity가 훼손될 수 있다. 배포 후 분포가 바뀌면 학습 시 통계가 더 이상 대표적이지 않을 수 있다.

#### 평균 0과 분산 1이 되는 이유

위에서 정의한 **같은 학습 집합**과 population-style 분모를 사용하면 다음은 근사가 아니라 정확한 항등식이다. 먼저 표준화된 feature의 학습 집합 평균은

$$
\begin{aligned}
\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}z_{ij}
&=\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}
\frac{x_{ij}-\mu_j}{\sigma_j} \\
&=\frac{1}{\sigma_j}
\left(
\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}x_{ij}-\mu_j
\right) \\
&=\frac{\mu_j-\mu_j}{\sigma_j}=0.
\end{aligned}
$$

평균이 0이므로 population variance는 두 번째 moment와 같고,

$$
\begin{aligned}
\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}(z_{ij}-0)^2
&=\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}
\frac{(x_{ij}-\mu_j)^2}{\sigma_j^2} \\
&=\frac{1}{\sigma_j^2}
\left(
\frac{1}{N_{\mathrm{train}}}\sum_{i=1}^{N_{\mathrm{train}}}(x_{ij}-\mu_j)^2
\right) \\
&=\frac{\sigma_j^2}{\sigma_j^2}=1.
\end{aligned}
$$

이 증명은 $$\sigma_j>0$$, 동일한 학습 표본, 동일한 분모 정의를 전제로 한다. Training에서 계산한 $$\mu_j,\sigma_j$$를 validation/test에 적용하면 그 split의 평균 0과 분산 1은 보장되지 않는다. 또한 표본 표준편차처럼 분모 $$N_{\mathrm{train}}-1$$을 사용한다면 분산 검산도 같은 분모로 해야 정확히 1이 된다.

## 2. 데이터 처리의 세 방향

| 개념 | 의미 |
|---|---|
| Data selection | 학습에 유용한 데이터를 잘 고른다. |
| Data preprocessing | 모델이 다루기 좋게 데이터를 정리하고 변환한다. |
| Data augmentation | 생성 모델 등을 이용해 데이터 양과 다양성을 늘린다. |

강의의 메시지는 단순히 데이터를 많이 모으는 시대에서, 좋은 데이터를 잘 고르고 잘 가공하는 시대로 넘어가고 있다는 것이다.

## 3. 모델이란?

모델은 입력을 받아 예측, 분포, 결정 같은 출력을 내는 함수로 볼 수 있다.

지도학습에서는 보통 입력 `x`와 정답 `y`가 있는 데이터셋을 두고, 임의의 새 `x`에 대한 `y`를 잘 예측하는 모델을 찾는다.

| 관점 | 설명 | 예 |
|---|---|---|
| 결정론적 함수 | 입력 `x`에 대해 하나의 예측값 `y`를 출력 | Linear Regression |
| 확률분포 | 예측값뿐 아니라 불확실성까지 분포로 출력 | Gaussian model |

확률적 모델은 데이터 noise, 데이터 부족, 모델 불확실성 등을 함께 표현할 수 있다.

### 3.1 데이터셋 표기와 선형 모델의 shape·단위

> **원문 대응:** 강의 PDF p.3은 각 표본을 $$x_n$$으로, p.4는 전체 feature matrix를 $$X\in\mathbb{R}^{N\times D}$$로 둔다. p.6은 지도학습 데이터셋 $$\{(x_1,y_1),\ldots,(x_N,y_N)\}$$을 제시하고, p.7은 scalar-output affine model $$f:\mathbb{R}^{D}\to\mathbb{R}$$, $$f(x)=\theta^Tx+\theta_0$$을 예로 든다. 아래의 $$K$$-output matrix 표기는 이 원문 식을 batch와 다중 출력으로 확장한 **작성자 보충 해설**이다.

원문의 scalar 식은 성분별로 쓰면

$$
f(x)=\theta^Tx+\theta_0
=\sum_{j=1}^{D}\theta_jx_j+\theta_0.
$$

이는 학습으로 증명되는 명제가 아니라 모델을 정하는 **정의이자 정확한 대수 항등식**이다. 엄밀히는 상수항 $$\theta_0$$이 있으므로 affine model이며, 관례적으로 linear regression이라고 부른다. 각 항을 더하려면 $$[\theta_j]=[y]/[x_j]$$, $$[\theta_0]=[y]$$여야 한다. 이 형태는 feature의 선형 결합만 표현하므로 강한 비선형 관계, 분포 이동, 빠진 설명 변수에서는 데이터가 많아도 구조적 오차가 남을 수 있다.

지도학습 데이터셋을 명확히 쓰면

$$
\mathcal{D}=\{(x_i,y_i)\}_{i=1}^{N},
\qquad
x_i\in\mathbb{R}^{D},
\quad
y_i\in\mathbb{R}^{K}
$$

이다. $$N$$은 sample 수, $$D$$는 입력 feature 수, $$K$$는 출력 성분 수다. Sample을 행으로 쌓으면

$$
X=\begin{bmatrix}
x_1^T\\
\vdots\\
x_N^T
\end{bmatrix}\in\mathbb{R}^{N\times D},
\qquad
Y=\begin{bmatrix}
y_1^T\\
\vdots\\
y_N^T
\end{bmatrix}\in\mathbb{R}^{N\times K}.
$$

다중 출력 선형 모델을 열벡터 관례로 쓰면

$$
\widehat y_i=W^Tx_i+b,
\qquad
W\in\mathbb{R}^{D\times K},
\quad
b\in\mathbb{R}^{K},
\quad
\widehat y_i\in\mathbb{R}^{K},
$$

이며 전체 데이터에는

$$
\widehat Y=XW+\mathbf{1}_Nb^T\in\mathbb{R}^{N\times K}
$$

가 된다. 여기서 $$\mathbf{1}_N\in\mathbb{R}^{N}$$은 모든 성분이 1인 벡터다. $$K=1$$이면 $$W$$를 $$w\in\mathbb{R}^{D}$$로 쓰고 $$\widehat y_i=w^Tx_i+b$$인 scalar regression으로 줄어든다. 이는 선택한 행·열 관례 아래의 **정확한 shape 관계**다.

단위도 합보다 먼저 맞아야 한다. 출력 성분 $$k$$의 단위를 $$U_{y_k}$$, feature $$j$$의 단위를 $$U_{x_j}$$라 하면 $$W_{jk}$$는 $$U_{y_k}/U_{x_j}$$, $$b_k$$는 $$U_{y_k}$$여야 한다. 그래야 모든 $$W_{jk}x_{ij}$$와 $$b_k$$를 같은 단위로 더할 수 있다. 입력을 표준화하면 feature 좌표는 무차원이 되지만, 출력 단위와 bias의 호환성은 여전히 확인해야 한다. Classification에서 $$\widehat y$$가 logit이면 보통 무차원이며, 물리량을 예측하는 regression에서는 단위 검사가 특히 중요하다.

## 4. 머신러닝이란?

Learning은 많은 모델과 그 모델의 parameter 중에서 unseen data에 좋은 예측을 주는 모델과 parameter를 찾는 과정이다.

학습 과정은 세 단계로 나눌 수 있다.

| 단계 | 의미 |
|---|---|
| Training / Parameter estimation | 데이터에 맞는 parameter를 찾는다. |
| Hyperparameter tuning / Model selection | 모델 구조나 학습 설정을 고른다. |
| Prediction / Inference | 학습된 모델로 새 입력에 대한 결과를 낸다. |

결정론적 모델에서는 보통 ERM(Empirical Risk Minimization) 관점으로 training을 설명하고, 확률적 모델에서는 parameter estimation 관점으로 설명한다.

## 5. 앞으로 필요한 수학

ERM과 parameter estimation을 이해하려면 다음 수학이 필요하다.

| 수학 | 머신러닝에서의 역할 |
|---|---|
| Linear Algebra | 데이터, 모델, 변환, 차원 축소를 행렬과 벡터로 표현 |
| Probability Theory | 불확실성, likelihood, Bayesian modeling 표현 |
| Vector Calculus and Optimization | loss를 줄이는 방향과 parameter update 계산 |

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| feature vector란? | 원본 데이터를 모델 입력용 수치 벡터로 표현한 것 |
| preprocessing이 중요한 이유는? | 스케일과 품질을 맞춰 학습을 안정화하기 위해 |
| 결정론적 모델과 확률적 모델의 차이는? | 하나의 예측값 출력 vs 불확실성을 포함한 분포 출력 |
| learning의 세 단계는? | training, model selection, inference |

## Study Guide

raw data를 feature vector로 바꾸고 preprocessing한 뒤 model training, hyperparameter selection, inference로 이어지는 전체 pipeline을 먼저 그린다. 결정론적 모델의 단일 출력과 확률적 모델의 분포 출력은 불확실성 표현 여부로 구분한다. 마지막에는 linear algebra, probability, calculus가 각각 표현·불확실성·최적화에 쓰이는 위치를 pipeline에 표시한다.

## 복습 질문

<details markdown="block">
<summary>1. 평균 0, 분산 1로 feature를 조정하는 이유는 무엇인가?</summary>

답변: feature마다 scale이 다르면 큰 값을 가진 feature가 학습을 과하게 지배할 수 있다. 평균 0, 분산 1로 맞추면 feature 간 scale 차이를 줄이고 gradient 기반 최적화를 더 안정적으로 만든다.

</details>

<details markdown="block">
<summary>2. ERM은 어떤 종류의 모델 학습을 설명할 때 자연스러운가?</summary>

답변: ERM은 training data에서 관측한 평균 loss를 최소화하는 관점이므로 결정론적 예측 함수 학습을 설명할 때 자연스럽다. 예를 들어 선형 회귀에서 squared error를 최소화하는 과정은 ERM의 대표적인 예다.

</details>

<details markdown="block">
<summary>3. 확률분포로서의 모델이 필요한 상황은 어떤 경우인가?</summary>

답변: 예측값 하나만으로 부족하고 불확실성을 함께 다뤄야 할 때 필요하다. 관측 noise가 있거나 데이터가 부족하거나 여러 가능한 결과가 존재하는 문제에서는 $$p(y\mid x,\theta)$$처럼 출력 분포를 모델링하는 편이 더 적절하다.

</details>


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-01.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-01.pdf</a></li>
</ul>
