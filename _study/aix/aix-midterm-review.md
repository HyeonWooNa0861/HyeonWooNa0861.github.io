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

이 자료는 AIX 중간고사 정답지를 바탕으로 주요 개념을 시험 복습용으로 재정리한 문서다. 문항 순서를 그대로 따라가기보다, 같은 개념을 묻는 문제들을 묶어 “왜 그 답이 되는지”를 빠르게 확인할 수 있도록 구성했다. 또한 비슷한 용어가 혼용되기 쉬운 지점을 따로 정리해, 정답 선지와 오답 선지를 구분하는 기준까지 함께 확인할 수 있게 했다.

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

## 복습 기준

| 관점 | 확인할 내용 |
|---|---|
| 정답 기준 | 문항이 요구하는 핵심 정의나 역할을 먼저 확인한다. |
| 혼동 포인트 | 비슷해 보이는 개념이 실제로는 어떤 기준으로 갈리는지 비교한다. |
| 오답 제거 | 선택지가 완전히 틀렸는지, 다른 개념에는 맞지만 현재 문항에는 맞지 않는지 구분한다. |
| 추가 개념 | 정답을 이해하기 위해 필요한 배경 개념을 짧게 보강한다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| residual vs loss | residual은 개별 예측 오차이고, loss는 오차를 모아 학습 목표로 만든 값이다. | residual 자체보다 squared residual sum이 objective function으로 더 자주 쓰인다. |
| score vs prediction | score는 모델이 계산한 선형 출력이고, regression에서는 보통 예측값으로 직접 사용된다. | classification에서는 score를 그대로 class probability로 해석하면 안 된다. |
| gradient vs update direction | gradient는 loss가 증가하는 방향이고, 학습은 보통 그 반대 방향으로 이동한다. | “gradient 방향으로 간다”는 표현은 최소화 문제에서는 부정확할 수 있다. |
| closed-form vs iterative update | closed-form은 한 번에 해를 구하고, iterative update는 반복적으로 parameter를 고친다. | Gradient Descent는 closed-form 방식이 아니라 반복 최적화 방식이다. |
| feature vs target | feature는 입력 정보이고 target은 맞혀야 하는 정답이다. | \\(x\\)와 \\(y\\)를 바꿔 적은 선택지는 기본 구성 오류다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| linear regression vs logistic regression | 둘 다 \\(w^Tx+b\\)를 쓰지만, logistic regression은 sigmoid를 붙여 확률로 해석한다. | logistic regression이 완전히 다른 비선형 구조를 쓰는 것은 아니다. |
| sigmoid vs softmax | sigmoid는 주로 binary probability, softmax는 여러 class score를 확률 분포로 바꾼다. | softmax의 출력 합은 1이고, sigmoid는 각 값을 독립적으로 0과 1 사이로 압축한다. |
| probability vs decision boundary | probability는 class에 속할 가능성이고, decision boundary는 class를 나누는 경계다. | probability function이 있어도 feature가 선형이면 decision boundary는 선형일 수 있다. |
| likelihood vs probability | probability는 특정 사건의 가능성이고, likelihood는 parameter 관점에서 관측 label을 얼마나 잘 설명하는지 본다. | “observed label이 most likely”라는 표현은 parameter 선택 기준이다. |
| classification loss vs residual loss | regression은 residual 제곱을 많이 쓰고, classification은 likelihood나 cross-entropy 계열을 쓴다. | logistic regression에 squared residual을 그대로 연결하는 선택지는 조심해야 한다. |

## 3. MLP와 Deep Learning

### 핵심 정리

Single perceptron은 선형 분리 가능한 문제에는 적합하지만, XOR처럼 선형 경계 하나로 나눌 수 없는 문제에는 한계가 있다. MLP는 hidden layer와 nonlinear activation을 추가해 더 복잡한 패턴을 표현한다.

Deep Learning의 성능 향상은 한 가지 요소만으로 설명하기 어렵다. 시험에서는 Data, Computation, Algorithms가 함께 맞물려야 큰 도약이 가능하다는 관점을 기억하면 된다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q8 | hidden layer와 nonlinearity | MLP는 단일 perceptron이 표현하지 못하는 복잡한 패턴을 표현한다. |
| Q12 | chain rule로 각 parameter gradient 계산 | backpropagation은 합성 함수의 gradient를 효율적으로 구한다. |
| Q18 | ReLU는 양수 구간 gradient가 일정 | sigmoid보다 vanishing gradient 문제가 덜하다. |
| Q43 | XOR은 linearly separable하지 않다 | 하나의 직선 결정 경계로 XOR 구조를 나눌 수 없다. |
| Q44 | Data, Computation, Algorithms | 딥러닝 발전은 데이터, 연산 자원, 알고리즘의 결합으로 설명된다. |
| Q50 | expressivity, regularization, bias-variance 균형 | 좋은 학습은 training set 암기가 아니라 unseen data generalization을 목표로 한다. |

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| single perceptron vs MLP | single perceptron은 선형 경계 중심이고, MLP는 hidden layer와 nonlinearity로 복잡한 경계를 만든다. | XOR 문제는 MLP가 왜 필요한지 보여주는 대표 사례다. |
| activation vs hidden layer | hidden layer는 중간 표현을 만들고, activation은 비선형성을 부여한다. | hidden layer만 여러 개 있어도 activation이 없으면 선형 변환의 반복이 된다. |
| ReLU vs sigmoid | ReLU는 양수 영역에서 gradient가 일정하고, sigmoid는 포화 구간에서 gradient가 작아진다. | vanishing gradient 완화 이유를 묻는 문제에서는 ReLU의 gradient 특성을 잡아야 한다. |
| backpropagation vs gradient descent | backpropagation은 gradient 계산법이고, gradient descent는 그 gradient로 parameter를 갱신하는 최적화 방법이다. | 두 용어를 모두 “학습”이라고만 외우면 오답 선택지에 흔들리기 쉽다. |
| overfitting vs generalization | overfitting은 training set에 과하게 맞는 것이고, generalization은 unseen data에서도 잘 맞는 것이다. | good learning은 training loss만 낮추는 것이 아니라 bias-variance와 regularization까지 고려한다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| pixel compression vs semantic understanding | pixel 수를 줄이는 것은 압축이고, Computer Vision의 목표는 의미 해석이다. | “저장 공간 절약” 같은 선택지는 high-level objective와 거리가 멀다. |
| CNN vs fully-connected layer | CNN은 local connectivity와 weight sharing으로 공간 패턴을 효율적으로 학습한다. | fully-connected layer와 달리 모든 pixel을 독립 weight로 연결하지 않는다. |
| hand-designed feature vs learned feature | 전통적 CV는 사람이 feature를 설계하고, deep learning은 데이터에서 feature를 학습한다. | SIFT 한계와 AlexNet 의의를 함께 연결해서 이해하면 좋다. |
| classification vs visual reasoning | classification은 label 예측 중심이고, visual reasoning은 객체 관계와 문맥 구조까지 본다. | 최근 visual reasoning의 중요성은 structured understanding과 연결된다. |
| 2D vision vs 3D vision | 2D 이미지는 grid 구조가 비교적 명확하지만, 3D는 point cloud, voxel, mesh 등 표현이 다양하다. | 3D Vision이 어려운 이유는 “이미 해결됐다”가 아니라 representation 다양성이다. |

## 5. NLP, Tokenizer, Word2Vec

### 핵심 정리

Tokenizer는 문장을 token 단위로 나누고, 각 token을 vocabulary 항목으로 대응시키는 과정이다. 단어를 바로 모델이 이해하는 것은 아니므로, token은 embedding vector로 변환된다.

Word2Vec은 단어 의미를 사람이 직접 규칙으로 입력하지 않는다. 대신 proxy task를 학습하는 얕은 신경망을 만들고, hidden layer의 병목 표현을 embedding으로 활용한다. Skip-Gram은 한 단어를 보고 주변 context 단어를 맞히는 방식이다.

### 관련 문항

| 문항 | 정답 기준 | 해설 |
|---:|---|---|
| Q5 | 한 단어를 보고 주변 context 단어 예측 | Skip-Gram의 기본 proxy task다. |
| Q6 | 문장을 token으로 나누고 vocabulary에 대응 | Tokenizer의 핵심 역할이다. |
| Q14 | 생성 텍스트와 참조 텍스트의 n-gram 일치 | BLEU score는 번역 품질 평가에서 n-gram overlap을 활용한다. |
| Q16 | subword pattern으로 OOV 문제 감소 | 접두사, 접미사, 부분 단어를 활용해 rare word 문제를 줄인다. |
| Q35 | proxy task와 hidden layer embedding | Word2Vec은 task를 통해 의미 있는 embedding을 얻는다. |
| Q37 | task마다 별도 모델을 from scratch로 학습 | task-specific NLP era의 일반적 특징이다. |
| Q41 | 의미 관계를 반영한 dense vector | learned embedding은 one-hot보다 의미적 유사성을 더 잘 담을 수 있다. |

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| tokenizer vs embedding | tokenizer는 문장을 token으로 나누고, embedding은 token을 dense vector로 바꾼다. | tokenizer가 의미 벡터를 직접 학습한다고 보면 안 된다. |
| one-hot vs learned embedding | one-hot은 vocabulary index 표현이고, learned embedding은 의미 관계를 반영할 수 있는 dense vector다. | one-hot은 dictionary size 차원의 희소 벡터로 이해하면 된다. |
| Skip-Gram vs CBOW | Skip-Gram은 중심 단어로 주변 단어를 예측하고, CBOW는 주변 단어로 중심 단어를 예측한다. | 중간고사 문항은 Skip-Gram을 묻기 때문에 “한 단어 -> 주변 context”가 정답 기준이다. |
| Word2Vec proxy task vs final task | Word2Vec은 proxy task 자체가 최종 목표가 아니라 좋은 embedding을 얻기 위한 학습 문제다. | hidden layer 병목 표현을 embedding으로 쓴다는 점을 기억한다. |
| BLEU score vs model training loss | BLEU는 생성 결과 평가 지표이고, training loss는 모델 parameter를 학습하기 위한 objective다. | n-gram 일치도는 BLEU와 연결되고, gradient update와는 직접 같은 개념이 아니다. |
| task-specific NLP vs pre-trained NLP | task-specific 시대는 task마다 별도 모델을 학습하고, pre-trained 시대는 큰 base model을 여러 task에 재사용한다. | “모든 task를 하나의 pre-trained model로 바로 해결”은 task-specific 시대 설명이 아니다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| RNN sequential dependency vs attention global relation | RNN은 hidden state를 순차 갱신하고, attention은 token 간 관계를 직접 계산한다. | attention이 무조건 순서를 없애는 것이 아니라, 관계 계산 방식이 더 전역적이라는 뜻이다. |
| hidden state vs attention score | hidden state는 RNN의 누적 상태이고, attention score는 token 간 관련도를 나타내는 값이다. | “attention score를 먼저 계산해야 RNN이 동작한다”는 설명은 RNN 정의와 맞지 않는다. |
| long sequence problem vs unordered input | RNN의 문제는 순서를 못 쓰는 것이 아니라, 순서대로 처리하기 때문에 먼 정보와 병렬 처리에 약하다는 점이다. | “RNN은 순서를 무시한다”는 선택지는 반대 개념이다. |
| local dependency vs global dependency | local dependency는 가까운 정보 중심이고, global dependency는 멀리 떨어진 정보까지 연결한다. | 긴 문맥에서 attention의 장점은 필요한 과거 정보를 직접 참조할 수 있다는 점이다. |
| computation simplicity vs expressive relation | RNN은 계산 구조가 단순할 수 있지만, 모든 token-to-token 관계를 한 번에 비교하지 않는다. | “단순하다”는 말이 “더 강력하다”는 뜻은 아니다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| self-attention vs tokenization | tokenization은 입력을 token으로 나누는 전처리이고, self-attention은 token 간 관계를 계산하는 모델 내부 연산이다. | self-attention이 tokenization을 대신한다는 설명은 틀리다. |
| Q/K/V 역할 | Q와 K는 관련도 점수 계산에 쓰이고, V는 가중합을 통해 출력 표현을 만든다. | Q와 K의 dot product를 계산하려면 두 vector 차원이 같아야 한다. |
| attention score vs value output | attention score는 어느 token을 얼마나 참고할지 정하고, value output은 실제로 가져오는 정보다. | 관련도 계산과 최종 표현 생성을 구분해야 한다. |
| self-attention vs positional encoding | self-attention은 관계를 보고, positional encoding은 순서와 위치 정보를 보강한다. | self-attention만으로 token 순서를 자연스럽게 알 수 있다는 선택지는 주의한다. |
| single-head vs multi-head attention | single-head는 한 관점의 관계를 보고, multi-head는 여러 관계 패턴을 병렬로 본다. | multi-head가 token 수를 줄이거나 positional encoding을 없애는 것은 아니다. |
| efficient matrix computation | attention은 Q/K/V를 행렬로 묶어 병렬 연산하기 좋다. | 계산이 없는 것이 아니라, 행렬 연산으로 잘 표현된다는 점이 중요하다. |

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

### 혼동 포인트와 추가 개념

| 비교 항목 | 구분 기준 | 시험에서 주의할 점 |
|---|---|---|
| supervised learning vs self-supervised learning | supervised learning은 사람이 준 label을 쓰고, self-supervised learning은 데이터 자체에서 학습 신호를 만든다. | self-supervised learning이 label 없이 아무 목표도 없이 학습한다는 뜻은 아니다. |
| pre-training vs fine-tuning | pre-training은 큰 데이터로 일반 표현을 배우고, fine-tuning은 특정 task에 맞게 조정한다. | fine-tuning을 “처음부터 다시 학습”으로 설명하면 틀리다. |
| base model vs task-specific model | base model은 여러 task로 전이될 수 있는 일반 표현을 갖고, task-specific model은 특정 task 중심이다. | pre-training 이후에도 task 적응 과정이 필요할 수 있다. |
| diffusion model vs classical ML model | diffusion model은 image/video generation에서 주류로 쓰이고, linear regression이나 k-means는 생성 모델 대표 답이 아니다. | “최근 image/video generation의 대표 주류”라는 문항 조건을 확인해야 한다. |
| representation vs final prediction | representation은 데이터의 의미 구조를 담은 중간 표현이고, final prediction은 특정 task의 결과다. | self-supervised learning의 장점은 transferable representation에 있다. |

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
