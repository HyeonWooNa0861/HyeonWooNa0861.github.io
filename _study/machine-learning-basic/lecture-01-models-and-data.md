---
layout: default
title: "Lecture 01 Models and Data"
course: "Machine Learning Basic"
topic: "Models and Data"
order: 1
---

# Lecture 01 Models and Data

Source PDF: `machine-learning-basic-lecture-01.pdf`

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

원본 데이터는 바로 모델에 넣기 어렵다. 전문가나 전처리 과정이 원본 데이터를 여러 특징값으로 바꾸고, 각 데이터는 \\(D\\)차원의 feature vector가 된다.

\\(N\\)개의 데이터가 있고 각 데이터가 \\(D\\)차원 feature를 가진다면 feature matrix는 다음처럼 표현한다.

$$
X \in \mathbb{R}^{N \times D}
$$

연속적인 수치 feature는 보통 평균이 0, 분산이 1이 되도록 조정한다. 이는 특정 feature의 스케일이 너무 커서 학습을 지배하지 않도록 하기 위한 기본 전처리다.

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

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| feature vector란? | 원본 데이터를 모델 입력용 수치 벡터로 표현한 것 |
| preprocessing이 중요한 이유는? | 스케일과 품질을 맞춰 학습을 안정화하기 위해 |
| 결정론적 모델과 확률적 모델의 차이는? | 하나의 예측값 출력 vs 불확실성을 포함한 분포 출력 |
| learning의 세 단계는? | training, model selection, inference |

## 복습 질문

1. 평균 0, 분산 1로 feature를 조정하는 이유는 무엇인가?
2. ERM은 어떤 종류의 모델 학습을 설명할 때 자연스러운가?
3. 확률분포로서의 모델이 필요한 상황은 어떤 경우인가?


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-01.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-01.pdf</a></li>
</ul>
