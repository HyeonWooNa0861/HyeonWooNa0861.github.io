---
layout: default
title: "AIX Midterm Review"
course: "AIX"
topic: "중간고사 핵심 개념 복습"
order: 9
---

# AIX Midterm Review

Source Images:

- `aix-midterm-answer-sheet-1.png`
- `aix-midterm-answer-sheet-2.png`

이 자료는 AIX 중간고사 정답지를 바탕으로 주요 개념을 시험 복습용으로 재정리한 문서다. 문항 순서를 그대로 따라가기보다, 같은 개념을 묻는 문제들을 묶어 “왜 그 답이 되는지”를 빠르게 확인할 수 있도록 구성했다.

## 전체 흐름

| 구간 | 핵심 주제 | 시험에서 잡아야 할 기준 |
|---|---|---|
| 1 | Regression과 Optimization | linear score, residual, squared loss, gradient descent |
| 2 | Logistic Regression과 Classification | sigmoid, probability, decision boundary, softmax |
| 3 | MLP와 Deep Learning | hidden layer, nonlinearity, generalization, XOR |
| 4 | Computer Vision | pixel-to-meaning, CNN, feature engineering, visual reasoning |
| 5 | NLP와 Word2Vec | tokenization, embedding, skip-gram, task-specific NLP |
| 6 | RNN과 Attention | sequential dependency, hidden state, global relationship |
| 7 | Transformer | self-attention, Q/K/V, positional encoding, multi-head attention |
| 8 | Modern AI | self-supervised learning, pre-training, fine-tuning, diffusion |

## 1. Regression과 Optimization

### 핵심 정리

Linear Regression은 입력 feature \\(x\\)를 이용해 target \\(y\\)를 예측하는 지도학습 모델이다. 예측값은 보통 다음 선형 점수로 표현한다.

$$
\hat{y}=w^Tx+b
$$

예측값과 실제값의 차이는 residual이며, 시험에서는 다음 정의를 기준으로 잡으면 된다.

$$
residual=y-\hat{y}
$$

Linear Regression의 학습 목표는 residual을 작게 만드는 것이며, 대표적인 objective function은 residual의 제곱합이다. Gradient Descent는 loss가 줄어드는 방향, 즉 gradient의 반대 방향으로 parameter를 반복적으로 갱신한다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q13 | \\(score=w^Tx+b\\) | 선형 모델은 weight와 feature의 내적에 bias를 더한다. |
| Q28 | Squared Sum of Residual | 회귀 문제의 대표 loss는 오차의 제곱합이다. |
| Q34 | \\(Residual=y-\hat{y}\\) | 실제값에서 예측값을 뺀 차이를 residual로 본다. |
| Q38 | \\(x\\): features, \\(y\\): target | 입력 변수는 feature, 예측 대상은 target이다. |
| Q49 | loss를 줄이도록 parameter를 반복 update | iterative update는 한 번에 닫힌 해를 구하는 방식이 아니라 반복 갱신이다. |
| Q24 | loss 감소 방향, gradient의 반대 방향 | gradient는 증가 방향이므로 loss 최소화에는 반대 방향을 쓴다. |

## 2. Logistic Regression과 Classification

### 핵심 정리

Logistic Regression은 Linear Regression의 선형 점수 구조를 버리지 않는다. 대신 선형 score 위에 sigmoid function을 적용하여 출력값을 class probability로 해석한다.

$$
z=w^Tx+b
$$

$$
\sigma(z)=\frac{1}{1+e^{-z}}
$$

sigmoid를 통과한 값은 0과 1 사이의 확률로 해석할 수 있으므로 binary classification에 적합하다. 다중 class 문제에서는 여러 class score를 softmax에 넣어 합이 1인 확률 분포로 바꾼다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q2 | 출력값을 0과 1 사이의 class probability로 해석 | logistic regression은 classification 결과를 확률처럼 다루기 위해 도입된다. |
| Q10 | decision boundary는 여전히 linear | feature가 그대로라면 score가 선형이므로 결정 경계도 선형이다. |
| Q15 | score를 probability로 바꾼다 | sigmoid function의 핵심 역할이다. |
| Q27 | observed labels가 most likely 하도록 parameter 선택 | logistic regression은 관측 label의 likelihood를 높이는 방향으로 학습한다. |
| Q31 | linear score 위에 probability link function 추가 | 구조는 linear score에 sigmoid를 결합한 형태다. |
| Q47 | 여러 class score를 확률 분포로 변환 | softmax는 class별 score 합을 1인 확률 분포로 정규화한다. |

## 3. MLP와 Deep Learning

### 핵심 정리

Single perceptron은 선형 분리 가능한 문제에는 적합하지만, XOR처럼 선형 경계 하나로 나눌 수 없는 문제에는 한계가 있다. MLP는 hidden layer와 nonlinear activation을 추가해 더 복잡한 패턴을 표현한다.

Deep Learning의 성능 향상은 한 가지 요소만으로 설명하기 어렵다. 시험에서는 Data, Computation, Algorithms가 함께 맞물려야 큰 도약이 가능하다는 관점을 기억하면 된다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q8 | hidden layer와 nonlinearity | MLP는 단일 perceptron이 표현하지 못하는 복잡한 패턴을 표현한다. |
| Q18 | ReLU는 양수 구간 gradient가 일정 | sigmoid보다 vanishing gradient 문제가 덜하다. |
| Q43 | XOR은 linearly separable하지 않다 | 하나의 직선 결정 경계로 XOR 구조를 나눌 수 없다. |
| Q44 | Data, Computation, Algorithms | 딥러닝 발전은 데이터, 연산 자원, 알고리즘의 결합으로 설명된다. |
| Q50 | expressivity, regularization, bias-variance 균형 | 좋은 학습은 training set 암기가 아니라 unseen data generalization을 목표로 한다. |

## 4. Computer Vision

### 핵심 정리

Computer Vision의 high-level 목표는 pixel을 의미로 연결하는 것이다. 단순히 pixel 수를 줄이거나 GPU 성능을 높이는 것이 아니라, 이미지 속 객체와 관계를 해석하는 것이 핵심이다.

CNN은 local connectivity와 weight sharing을 통해 이미지의 국소 패턴을 효율적으로 학습한다. AlexNet이 ImageNet Challenge에서 중요한 의미를 가진 것도 CNN 기반 딥러닝 모델이 기존 수작업 feature 기반 접근보다 뛰어난 성능을 보였기 때문이다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q11 | CNN 기반 모델이 전통적 방법보다 우수한 성능 | AlexNet은 딥러닝 기반 컴퓨터 비전의 전환점으로 이해하면 된다. |
| Q21 | local connectivity와 weight sharing | convolution layer가 fully-connected layer보다 이미지 패턴을 효율적으로 학습하는 이유다. |
| Q22 | 사람이 유용한 입력 변수를 설계 | feature engineering은 모델 성능을 높이기 위해 사람이 feature를 설계하는 과정이다. |
| Q25 | pixel을 meaning으로 연결 | Computer Vision의 핵심 목표다. |
| Q29 | structured/compositional understanding | 최근 visual reasoning은 객체, 언어, 문맥 관계를 함께 이해하는 방향으로 중요해졌다. |
| Q46 | hand-designed feature 의존 | SIFT 같은 전통적 방법은 task마다 feature를 별도로 설계해야 하는 한계가 있다. |

## 5. NLP, Tokenizer, Word2Vec

### 핵심 정리

Tokenizer는 문장을 token 단위로 나누고, 각 token을 vocabulary 항목으로 대응시키는 과정이다. 단어를 바로 모델이 이해하는 것은 아니므로, token은 embedding vector로 변환된다.

Word2Vec은 단어 의미를 사람이 직접 규칙으로 입력하지 않는다. 대신 proxy task를 학습하는 얕은 신경망을 만들고, hidden layer의 병목 표현을 embedding으로 활용한다. Skip-Gram은 한 단어를 보고 주변 context 단어를 맞히는 방식이다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q5 | 한 단어를 보고 주변 context 단어 예측 | Skip-Gram의 기본 proxy task다. |
| Q6 | 문장을 token으로 나누고 vocabulary에 대응 | Tokenizer의 핵심 역할이다. |
| Q16 | subword pattern으로 OOV 문제 감소 | 접두사, 접미사, 부분 단어를 활용해 rare word 문제를 줄인다. |
| Q35 | proxy task와 hidden layer embedding | Word2Vec은 task를 통해 의미 있는 embedding을 얻는다. |
| Q37 | task마다 별도 모델을 from scratch로 학습 | task-specific NLP era의 일반적 특징이다. |
| Q41 | 의미 관계를 반영한 dense vector | learned embedding은 one-hot보다 의미적 유사성을 더 잘 담을 수 있다. |

## 6. RNN과 Attention

### 핵심 정리

RNN은 sequential data를 시간 순서대로 처리하며, 현재 시점의 hidden state가 이전 hidden state에 의존한다. 이 구조는 순서 정보를 다루는 데 적합하지만, 긴 sequence에서는 앞부분 정보가 희미해지고 병렬 처리가 어렵다.

Attention은 token, feature, patch 사이의 관계를 더 직접적으로 연결한다. 따라서 RNN보다 global relationship을 더 잘 볼 수 있고, 긴 문맥에서 이전 정보를 다시 참고하기 쉽다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q1 | sequential data를 시간 순서대로 다루는 모델 | RNN의 기본 정의다. |
| Q3 | 앞부분 정보가 압축되며 영향이 희미해짐 | 긴 sequence에서 RNN이 갖는 대표적 한계다. |
| Q7 | 먼 과거 정보 처리와 병렬 처리에 불리 | RNN은 순차 계산 구조이므로 긴 의존성과 병렬화가 어렵다. |
| Q17 | token/feature/patch를 유연하게 연결 | Attention의 global 관계 모델링 장점이다. |
| Q20 | 현재 token과 이전 hidden state로 업데이트 | RNN이 attention보다 계산 구조가 단순할 수 있는 이유다. |
| Q32 | 현재 hidden state가 이전 hidden state에 의존 | sequential dependency의 원인이다. |
| Q33 | 필요한 이전 부분을 직접 참고 | 긴 대화에서 attention이 유리한 이유다. |
| Q36 | 시간적 순서를 따라 연결되며 sequence 처리 | RNN의 고수준 정의다. |
| Q39 | token 사이 global relationship을 더 잘 봄 | attention이 RNN보다 강한 부분이다. |
| Q45 | current input과 previous hidden state만 사용 | RNN의 계산 구조가 상대적으로 단순한 이유다. |

## 7. Transformer와 Self-Attention

### 핵심 정리

Transformer는 입력 문장을 token으로 나누고, 각 token을 embedding vector로 표현한다. Self-attention은 각 token이 자신과 관련 있는 다른 token들을 참고하여 자신의 표현을 갱신하는 방식이다.

Q, K, V는 self-attention에서 서로 다른 역할을 한다. Query와 Key의 내적은 어떤 token이 서로 관련 있는지 점수화하고, Value는 그 관계를 바탕으로 출력 표현을 만들 때 사용된다.

Transformer는 self-attention만으로는 token 순서를 알기 어렵기 때문에 positional encoding을 더한다. Multi-head attention은 여러 head가 서로 다른 관계나 패턴을 병렬로 보게 해준다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q19 | Q와 K의 내적으로 관계를 구하고 V로 출력 구성 | Q/K/V의 기본 역할이다. |
| Q26 | Q와 K의 차원이 같아야 dot product 가능 | 내적 계산에는 같은 차원의 vector가 필요하다. |
| Q30 | 각 단어가 관련 단어를 참고해 표현 생성 | self-attention의 가장 쉬운 설명이다. |
| Q40 | self-attention만으로 token 순서를 알기 어렵다 | positional encoding이 필요한 이유다. |

## 8. Modern AI 흐름

### 핵심 정리

Self-Supervised Learning은 사람이 직접 label을 많이 붙이지 않아도 데이터 자체에서 supervision을 만들어 transferable representation을 학습하는 방식이다. Pre-training은 큰 데이터로 base model을 만들고 일반적인 특징을 학습하는 단계이며, fine-tuning은 이 모델을 특정 task에 맞게 미세 조정하는 단계다.

최근 image/video generation에서 대표적인 주류 모델은 diffusion models이다. 3D Vision은 point clouds, voxels, meshes처럼 representation 형식이 다양해 다루기 어렵다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q4 | 데이터 자체에서 supervision 생성 | self-supervised learning의 목적이다. |
| Q9 | point clouds, voxels, meshes 등 format 다양 | 3D Vision이 어려운 이유다. |
| Q23 | 큰 데이터로 base model을 만들고 일반 특징 학습 | pre-training의 핵심이다. |
| Q42 | Diffusion models | 최근 image/video generation의 대표적 주류 모델이다. |
| Q48 | pre-trained model을 특정 task에 맞게 조정 | fine-tuning의 정의다. |

## 전체 정답 체크리스트

| 문항 | 핵심 정답 |
|---:|---|
| 1 | sequential data를 시간 순서대로 다루는 모델 |
| 2 | 출력값을 0과 1 사이의 class probability로 해석 |
| 3 | 정보가 압축되면서 먼 과거의 영향이 희미해짐 |
| 4 | 데이터 자체에서 supervision을 만들고 transferable representation을 학습 |
| 5 | 한 단어를 보고 주변 context 단어를 맞히는 task |
| 6 | 문장을 token으로 나누고 vocabulary에 대응 |
| 7 | 먼 과거 정보 처리와 병렬 처리에 불리 |
| 8 | hidden layer와 nonlinearity가 복잡한 pattern을 표현 |
| 9 | point clouds, voxels, meshes처럼 data format이 다양 |
| 10 | decision boundary는 여전히 linear |
| 11 | CNN 기반 모델이 전통적 방법보다 우수한 성능 |
| 12 | 각 parameter의 gradient를 구하기 위해 chain rule 필요 |
| 13 | \\(score=w^Tx+b\\) |
| 14 | 생성 텍스트와 참조 텍스트 간 n-gram 일치도 |
| 15 | score를 probability로 바꿔 class probability로 해석 |
| 16 | subword pattern으로 OOV 문제 감소 |
| 17 | token/feature/patch 사이를 유연하게 연결 |
| 18 | ReLU는 양수 영역 gradient가 일정 |
| 19 | Q/K 내적으로 관련도 계산, V로 출력 구성 |
| 20 | 현재 token과 이전 hidden state로 update |
| 21 | local connectivity와 weight sharing |
| 22 | 사람이 유용한 입력 변수를 설계 |
| 23 | 큰 데이터로 base를 만들고 일반 특징을 학습 |
| 24 | loss가 줄어드는 방향, gradient의 반대 방향 |
| 25 | pixel을 meaning으로 연결 |
| 26 | Q와 K의 내적을 위해 두 vector 차원이 같아야 함 |
| 27 | observed labels가 most likely 하도록 parameter 선택 |
| 28 | Squared Sum of Residual |
| 29 | 객체, 언어, 문맥을 연결한 structured understanding |
| 30 | 각 단어가 관련 단어를 참고해 표현 생성 |
| 31 | linear score 위에 probability link function 추가 |
| 32 | 현재 hidden state가 이전 hidden state에 의존 |
| 33 | 필요한 이전 부분을 직접 참고 |
| 34 | \\(Residual=y-\hat{y}\\) |
| 35 | proxy task를 학습한 hidden layer를 embedding으로 사용 |
| 36 | 시간적 순서를 따라 연결되며 sequence를 처리 |
| 37 | task마다 별도 모델을 from scratch로 학습 |
| 38 | \\(x\\): features, \\(y\\): target |
| 39 | token 사이 global relationship을 더 잘 봄 |
| 40 | self-attention만으로 token 순서를 알기 어려움 |
| 41 | 의미 관계를 반영한 dense vector |
| 42 | Diffusion models |
| 43 | XOR은 linearly separable하지 않음 |
| 44 | Data, Computation, Algorithms의 결합 |
| 45 | current input과 previous hidden state만 사용해 다음 상태 update |
| 46 | 사람이 설계한 feature에 의존 |
| 47 | 여러 class score를 합이 1인 확률 분포로 변환 |
| 48 | pre-trained model을 특정 task에 맞게 조정 |
| 49 | loss를 줄이도록 parameter를 반복 update |
| 50 | expressivity, regularization, bias-variance 균형으로 generalize |

## Source Images

<ul>
  <li><a href="{{ "/assets/images/study/aix/midterm/aix-midterm-answer-sheet-1.png" | relative_url }}" target="_blank" rel="noopener">AIX Midterm Answer Sheet 1</a></li>
  <li><a href="{{ "/assets/images/study/aix/midterm/aix-midterm-answer-sheet-2.png" | relative_url }}" target="_blank" rel="noopener">AIX Midterm Answer Sheet 2</a></li>
</ul>
