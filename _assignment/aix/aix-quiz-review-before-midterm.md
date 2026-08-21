---
layout: default
date: 2026-06-07 19:19:57 +0900
title: "AIX Quiz Review Before Midterm"
course: "AIX"
topic: "Before Midterm Quiz Review"
order: 1
---

# AIX Quiz Review Before Midterm

Source Images:

- `aix-pre-midterm-001.png` ~ `aix-pre-midterm-024.png`

이 글은 중간고사 전 AIX Quiz 이미지 자료를 시험 대비용으로 다시 정리한 자료다. 원문 선택지를 그대로 옮기기보다, 문항이 묻는 개념과 정답을 고르는 기준을 중심으로 재구성했다.

## 전체 흐름

| 구간 | 핵심 주제 | 시험에서 잡아야 할 기준 |
|---|---|---|
| 1 | Linear Regression | feature와 target, linear score, residual, squared loss, iterative update |
| 2 | Logistic Regression | sigmoid, probability, classification loss, decision boundary |
| 3 | MLP와 Deep Learning | hidden layer, nonlinearity, generalization, data-computation-algorithm |
| 4 | Computer Vision | pixel을 meaning으로 연결, visual reasoning, 3D representation |
| 5 | NLP와 Word2Vec | tokenizer, embedding, skip-gram, pre-training, fine-tuning |
| 6 | RNN과 Attention | sequential dependency, hidden state, global relationship |
| 7 | Transformer | token embedding, self-attention, multi-head attention, positional encoding |
| 8 | Self-Supervised Learning | data 자체의 supervision, transferable representation, diffusion |

빠르게 복습할 때는 다음 문장을 먼저 기억하면 된다.

1. Linear regression은 \\(x\\)를 feature, \\(y\\)를 target으로 보고 \\(\hat{y}=w^Tx+b\\) 형태의 선형 점수를 학습한다.
2. Logistic regression은 linear score 위에 sigmoid를 붙여 class probability로 해석한다.
3. MLP는 hidden layer와 nonlinearity 덕분에 single perceptron보다 복잡한 패턴을 표현할 수 있다.
4. RNN은 순차적으로 hidden state를 갱신하고, attention은 token 사이의 관계를 더 직접적이고 전역적으로 본다.
5. Transformer는 token embedding, self-attention, multi-head attention, positional encoding을 결합한다.

## 1. Linear Regression

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | 데이터셋 구성 | \\(x\\): features, \\(y\\): target |
| Q2 | linear score 식 | \\(score=w^Tx+b\\) |
| Q3 | residual 정의 | \\(residual=y-\hat{y}\\) |
| Q4 | loss objective | squared sum of residual |
| Q5 | iterative update | loss를 줄이도록 parameter를 반복적으로 update |

<details>
<summary>Linear regression에서 feature와 target은 어떻게 구분하는가?</summary>

풀이과정:

Linear regression에서 입력 변수는 feature이고, 예측하고 싶은 값은 target이다. 관례적으로 feature vector를 \\(x\\), target value를 \\(y\\)로 둔다.

답변: \\(x\\)는 features, \\(y\\)는 target이다.

</details>

<details>
<summary>Linear regression의 선형 score 식은 무엇인가?</summary>

풀이과정:

Linear regression은 feature vector \\(x\\)에 weight vector \\(w\\)를 곱하고 bias \\(b\\)를 더해 예측값을 만든다.

$$
\hat{y}=score=w^Tx+b
$$

곱셈만 있거나, \\(w+x+b\\)처럼 vector의 가중합 구조가 사라진 식은 linear regression의 표준 형태가 아니다.

답변: \\(score=w^Tx+b\\)이다.

</details>

<details>
<summary>Residual과 squared loss는 어떻게 연결되는가?</summary>

풀이과정:

Residual은 실제 값과 예측값의 차이다.

$$
residual = y-\hat{y}
$$

Linear regression의 대표적인 objective는 residual을 제곱해 모두 더한 값이다.

$$
L(w,b)=\sum_i (y_i-\hat{y}_i)^2
$$

제곱하는 이유는 양수/음수 오차가 서로 상쇄되지 않게 하고, 큰 오차를 더 크게 벌주기 위해서다.

답변: residual은 \\(y-\hat{y}\\)이고, loss는 squared sum of residual을 사용한다.

</details>

<details>
<summary>Iterative update는 무엇인가?</summary>

풀이과정:

Iterative update는 closed-form처럼 한 번에 답을 구하는 방식이 아니다. 현재 parameter에서 loss가 줄어드는 방향으로 \\(w\\), \\(b\\)를 조금씩 반복 갱신하는 방식이다.

Deep learning의 training도 기본적으로 이 아이디어를 따른다.

답변: loss를 줄이도록 parameter를 반복적으로 업데이트하는 방식이다.

</details>

## 2. Logistic Regression

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | classification에 도입하는 이유 | 출력을 0과 1 사이 class probability처럼 해석 |
| Q2 | sigmoid/logistic curve 역할 | score를 probability로 변환 |
| Q3 | architecture 비교 | linear score 위에 probability link function 사용 |
| Q4 | training intuition | observed labels가 most likely 하도록 parameter 선택 |
| Q5 | decision boundary | linear regression보다 classification loss/probability를 더해도 boundary는 선형 |

<details>
<summary>Classification에서 logistic regression을 쓰는 이유는 무엇인가?</summary>

풀이과정:

Linear regression의 score는 아무 실수값이나 될 수 있다. classification에서는 출력이 class probability처럼 해석되기를 원한다. Logistic regression은 sigmoid를 사용해 score를 0과 1 사이 값으로 바꾼다.

$$
P(y=1\mid x)=\sigma(w^Tx+b)
$$

답변: 출력값을 class probability처럼 0과 1 사이로 해석하기 위해서다.

</details>

<details>
<summary>Sigmoid function은 어떤 역할을 하는가?</summary>

풀이과정:

Sigmoid는 선형 score를 확률로 바꾸는 link function이다.

$$
\sigma(z)=\frac{1}{1+e^{-z}}
$$

여기서 \\(z=w^Tx+b\\)다. 따라서 logistic regression은 linear score를 버리는 것이 아니라, 그 위에 probability 변환을 붙인다.

답변: score를 probability로 바꿔 class probability로 해석할 수 있게 한다.

</details>

<details>
<summary>Training logistic regression의 high-level intuition은 무엇인가?</summary>

풀이과정:

Logistic regression은 관측된 label이 가장 그럴듯하게 나오도록 parameter를 고른다. 즉 positive sample에는 높은 probability를, negative sample에는 낮은 probability를 주도록 학습한다.

이 관점은 likelihood maximization 또는 cross-entropy loss minimization으로 연결된다.

답변: observed labels가 most likely 하도록 parameter를 고르는 것이다.

</details>

<details>
<summary>Logistic regression의 decision boundary는 어떻게 이해해야 하는가?</summary>

풀이과정:

Logistic regression은 probability와 classification용 loss를 사용하지만, 원래 feature 공간에서의 decision boundary는 보통 선형이다.

Binary classification에서 기준을 \\(P(y=1\mid x)=0.5\\)로 두면, 이는 \\(w^Tx+b=0\\)과 대응된다.

답변: 확률 해석과 classification loss를 더하지만, 기본 decision boundary는 여전히 linear하다.

</details>

## 3. MLP와 Deep Learning

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | MLP가 perceptron보다 강한 이유 | hidden layer와 nonlinearity |
| Q2 | good learning | expressivity, regularization, bias-variance, unseen data generalization |
| Q3 | deep learning 도약 조건 | data, computation, algorithms가 함께 맞물림 |

<details>
<summary>MLP가 single perceptron보다 강한 이유는 무엇인가?</summary>

풀이과정:

Single perceptron은 기본적으로 하나의 선형 결정 경계를 만든다. MLP는 hidden layer와 nonlinear activation을 사용하므로, 단일 선형 모델이 표현하지 못하는 복잡한 패턴을 표현할 수 있다.

답변: hidden layer와 nonlinearity가 있어 single perceptron이 표현하지 못하는 패턴을 표현할 수 있기 때문이다.

</details>

<details>
<summary>Good learning은 단순히 training loss를 낮추는 것인가?</summary>

풀이과정:

좋은 학습은 training set을 외우는 것이 아니다. 모델이 충분한 표현력(expressivity)을 가지되, regularization과 bias-variance 균형을 통해 unseen data에서도 잘 일반화해야 한다.

따라서 hidden layer 수를 무조건 늘리거나 training loss만 낮추는 설명은 부족하다.

답변: expressivity, regularization, bias-variance를 균형 있게 다뤄 unseen data에서도 generalize해야 한다.

</details>

<details>
<summary>Deep learning의 큰 도약을 가능하게 한 조합은 무엇인가?</summary>

풀이과정:

Deep learning은 data만 많거나, computation만 좋거나, algorithm만 좋아서 발전한 것이 아니다. 대규모 데이터, GPU/TPU 같은 계산 자원, 학습 알고리즘과 모델 구조가 함께 맞물리며 발전했다.

답변: Data, Computation, Algorithms가 함께 맞물려야 한다.

</details>

## 4. Computer Vision과 Visual Reasoning

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Computer Vision의 high-level 목표 | pixel을 meaning으로 연결 |
| Q2 | visual reasoning 중요성 | 객체 간 관계, 언어, 문맥까지 연결한 structured/compositional understanding |
| Q3 | image/video generation 주류 모델 | diffusion models |
| Q4 | 3D Vision이 어려운 이유 | geometry, pose, spatial relationship과 다양한 representation |

<details>
<summary>Computer Vision의 high-level 목표는 무엇인가?</summary>

풀이과정:

Computer Vision은 단순히 픽셀 수를 줄이거나 GPU 성능을 높이는 분야가 아니다. 핵심은 pixel data를 object, scene, relation, meaning으로 해석하는 것이다.

답변: 픽셀을 의미로 연결하는 것이다.

</details>

<details>
<summary>Visual reasoning이 중요해진 이유는 무엇인가?</summary>

풀이과정:

단순 image classification은 이미지 하나에 label을 붙이는 데 초점이 있다. 하지만 최근 모델은 객체 간 관계, 장면 구조, 언어적 설명, 문맥까지 이해해야 한다.

예를 들어 "사람이 컵을 잡고 있다"는 것은 사람, 컵, 손, 동작, 위치 관계를 함께 이해해야 한다.

답변: 객체 간 관계, 언어, 문맥까지 연결한 structured/compositional understanding이 중요해졌기 때문이다.

</details>

<details>
<summary>최근 image/video generation의 대표적 주류 모델은 무엇인가?</summary>

풀이과정:

최근 image/video generation에서 대표적으로 쓰이는 모델 계열은 diffusion models다. Noise를 점진적으로 제거하면서 데이터를 생성하는 방식으로 이해하면 된다.

답변: Diffusion models다.

</details>

<details>
<summary>3D Vision이 여전히 어려운 이유는 무엇인가?</summary>

풀이과정:

3D Vision은 단순한 2D classification과 다르다. geometry, pose, spatial relationship을 다루며, 데이터 표현도 point clouds, voxels, meshes 등으로 다양하다.

표현 형식이 다양하다는 것은 모델 입력과 학습 방식도 더 복잡해진다는 뜻이다.

답변: geometry, pose, spatial relationship을 다루고 data format/representation이 다양하기 때문이다.

</details>

## 5. NLP, Tokenizer, Word2Vec

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Task-specific NLP era | task마다 별도 모델을 from scratch로 학습 |
| Q2 | Tokenizer 역할 | 문장을 token으로 나누고 vocabulary 항목에 대응 |
| Q3 | Word2Vec 구조 | proxy task를 학습하는 얕은 신경망, hidden layer를 embedding으로 사용 |
| Q4 | Skip-Gram | 한 단어를 보고 주변 context 단어를 맞힘 |
| Q5 | Pre-training | 큰 데이터로 base를 만들고 일반적 특징을 학습 |
| Q6 | Fine-tuning | pretrained model을 특정 task 목적에 맞게 미세 조정 |

<details>
<summary>Task-specific NLP era는 어떤 방식이었는가?</summary>

풀이과정:

pre-trained foundation model을 하나 만들어 여러 task에 재사용하는 방식이 일반화되기 전에는, 각 task마다 별도의 모델을 처음부터 학습하는 방식이 흔했다.

답변: 각 task마다 별도의 모델을 from scratch로 학습하는 방식이 일반적이었다.

</details>

<details>
<summary>Tokenizer는 어떤 역할을 하는가?</summary>

풀이과정:

Tokenizer는 문장을 token 단위로 나누고, 각 token을 vocabulary의 항목으로 대응시킨다. naive하게 보면 vocabulary size 차원의 one-hot vector로 표현할 수도 있다.

답변: 문장을 token으로 나누고, 각 token을 vocabulary 항목으로 대응시킨다.

</details>

<details>
<summary>Word2Vec은 어떻게 embedding을 배우는가?</summary>

풀이과정:

Word2Vec은 사람이 단어 의미를 직접 써 넣는 방식이 아니다. proxy task를 학습하는 얕은 신경망을 만들고, 가운데의 좁은 hidden layer를 단어 embedding으로 사용한다.

이때 중요한 것은 task 자체보다 task를 풀면서 생긴 dense representation이다.

답변: proxy task를 학습하는 얕은 신경망을 만들고, hidden layer를 embedding으로 사용한다.

</details>

<details>
<summary>Skip-Gram은 어떤 proxy task인가?</summary>

풀이과정:

Skip-Gram은 중심 단어를 보고 주변 context 단어를 예측하는 task다. 예를 들어 "king"이라는 단어가 나오면 주변에 어떤 단어들이 함께 등장할지 맞히도록 학습한다.

답변: 한 단어를 보고 주변 context 단어들을 맞히는 task다.

</details>

<details>
<summary>Pre-training과 Fine-tuning은 어떻게 구분하는가?</summary>

풀이과정:

Pre-training은 큰 데이터로 base model을 만들고 언어의 일반적인 특징을 배우게 하는 단계다. Fine-tuning은 그 pretrained model을 바탕으로 특정 task 목적에 맞게 미세 조정하는 단계다.

답변: pre-training은 일반적 base를 만드는 단계이고, fine-tuning은 특정 task에 맞게 조정하는 단계다.

</details>

## 6. RNN과 Attention 비교

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | RNN 정의 | 시간 순서에 따라 연결되며 sequence를 처리 |
| Q2 | RNN 핵심 특징 | sequential data에 적합 |
| Q3 | RNN이 attention보다 단순한 이유 | 현재 입력과 이전 hidden state로 update, 모든 token pair를 한 번에 보지 않음 |
| Q4 | RNN의 대표 문제 | 먼 과거 정보 처리 어려움, 병렬 처리 불리 |
| Q5 | sequential dependency 원인 | 현재 hidden state가 이전 hidden state에 의존 |
| Q6 | attention 장점 | token 사이 global relationship을 더 직접적으로 봄 |

<details>
<summary>RNN은 어떤 모델인가?</summary>

풀이과정:

RNN은 sequence를 시간 순서대로 처리하는 모델이다. 현재 시점의 입력과 이전 시점의 hidden state를 이용해 새로운 hidden state를 만든다.

$$
h_t = f(x_t, h_{t-1})
$$

답변: 시간적 순서를 따라 연결되며 sequence를 처리하는 모델이다.

</details>

<details>
<summary>RNN이 attention보다 계산 구조가 단순하다고 볼 수 있는 이유는 무엇인가?</summary>

풀이과정:

RNN은 모든 token-to-token 관계를 한 번에 계산하지 않는다. 현재 token과 이전 hidden state를 이용해 다음 hidden state를 갱신한다.

반면 attention은 token 사이의 관계를 행렬 형태로 계산하므로 global relationship을 직접 다루지만 계산 구조는 더 크다.

답변: 현재 입력과 이전 hidden state만 이용해 update하며, attention처럼 모든 token-to-token 관계를 한꺼번에 계산하지 않기 때문이다.

</details>

<details>
<summary>RNN의 대표적 문제점은 무엇인가?</summary>

풀이과정:

RNN은 정보가 순서대로 전달된다. 따라서 먼 과거 정보가 뒤쪽 token까지 전달되기 어렵고, token을 순차적으로 처리하기 때문에 병렬 처리에도 불리하다.

답변: 정보가 순서대로 전달되어 먼 과거 정보를 다루기 어렵고 병렬 처리에도 불리하다.

</details>

<details>
<summary>Attention이 RNN보다 global relationship을 더 잘 볼 수 있는 이유는 무엇인가?</summary>

풀이과정:

Attention은 각 token이 다른 token들과의 관계를 직접 계산할 수 있다. 긴 문장이나 긴 대화에서 앞부분 정보가 뒤에서 다시 중요해질 때, 필요한 이전 부분을 직접 참조할 수 있다.

답변: token/feature/patch 사이를 더 유연하고 전역적으로 연결할 수 있기 때문이다.

</details>

## 7. Transformer와 Self-Attention

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Transformer 텍스트 입력 | tokenize 후 learned embedding으로 표현 |
| Q2 | Self-attention | 각 token이 관련 있는 다른 token들을 참고 |
| Q3 | Multi-head attention | 여러 head가 서로 다른 관계나 패턴을 병렬로 봄 |
| Q4 | Positional encoding | token의 순서와 상대적 위치 정보를 알려 줌 |
| Q5 | matrix computation | attention은 행렬 연산으로 표현되어 병렬 계산에 유리 |

<details>
<summary>Transformer에서 텍스트 입력은 어떻게 처리되는가?</summary>

풀이과정:

Transformer는 문장을 숫자 변환 없이 바로 attention에 넣지 않는다. 먼저 텍스트를 token으로 나누고, 각 token을 learned embedding vector로 바꾼다.

답변: 텍스트를 tokenize하고, 각 token을 learned embedding으로 표현한다.

</details>

<details>
<summary>Self-attention을 가장 쉽게 설명하면?</summary>

풀이과정:

Self-attention은 한 문장 안의 각 token이 다른 token들과의 관련성을 보고 자기 표현을 새로 만드는 방식이다. 모든 단어를 똑같이 평균내는 것이 아니라 중요한 단어에 더 큰 weight를 둔다.

답변: 각 token이 다른 token들 중 자신과 관련 있는 정보를 더 참고해서 자신의 표현을 만든다.

</details>

<details>
<summary>Multi-head attention의 장점은 무엇인가?</summary>

풀이과정:

하나의 attention head만 있으면 하나의 관계 관점에 치우칠 수 있다. Multi-head attention은 여러 head가 서로 다른 관계나 패턴을 병렬로 보게 한다.

예를 들어 어떤 head는 문법 관계를, 다른 head는 의미 관계를, 또 다른 head는 위치 관계를 볼 수 있다.

답변: 여러 head가 서로 다른 관계나 패턴을 병렬로 볼 수 있게 해 준다.

</details>

<details>
<summary>Positional encoding이 필요한 이유는 무엇인가?</summary>

풀이과정:

Self-attention은 모든 token 사이의 관계를 계산하지만, 그 자체만으로는 token의 순서 정보가 충분하지 않을 수 있다. 따라서 모델이 token의 순서와 상대적 위치를 이해하도록 position information을 더한다.

답변: 모델이 token의 순서와 상대적 위치를 이해하도록 돕기 위해서다.

</details>

<details>
<summary>Attention이 efficient computations with matrices와 연결되는 이유는 무엇인가?</summary>

풀이과정:

Attention은 query, key, value를 행렬로 묶어 계산할 수 있다. 이 구조는 GPU에서 병렬 계산하기에 유리하다.

$$
\text{Attention}(Q,K,V)=\operatorname{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V
$$

답변: attention은 행렬 연산으로 잘 표현되어 병렬 계산에 유리하기 때문이다.

</details>

## 8. Self-Supervised Learning과 Modern Vision

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Self-Supervised Learning objective | 데이터 자체에서 supervision을 만들고 transferable representation을 학습 |
| Q2 | Image/video generation | diffusion models |
| Q3 | 3D Vision | geometry, pose, spatial relationship, 다양한 representation |

<details>
<summary>Self-Supervised Learning의 objective는 무엇인가?</summary>

풀이과정:

Self-supervised learning은 사람 label을 최대한 많이 수집하는 방식이 아니다. 데이터 자체에서 예측 문제를 만들어 supervision으로 사용하고, 다른 task로 옮겨 쓸 수 있는 transferable representation을 배우는 것이 목표다.

답변: 데이터 자체에서 supervision을 만들고 transferable representation을 배우는 것이다.

</details>

<details>
<summary>Modern vision 범위에서 diffusion과 3D vision은 어떻게 정리하는가?</summary>

풀이과정:

최근 image/video generation의 대표적 주류는 diffusion models다. 3D vision은 point clouds, voxels, meshes처럼 표현 방식이 다양하고, geometry와 pose, spatial relationship을 함께 다뤄야 하므로 어렵다.

답변: 생성 모델은 diffusion models가 대표적이고, 3D vision은 다양한 representation과 공간 관계 때문에 어렵다.

</details>

## 마지막 핵심 정리

| 구분 | 꼭 기억할 문장 |
|---|---|
| Linear Regression | \\(\hat{y}=w^Tx+b\\), residual은 \\(y-\hat{y}\\), loss는 squared residual 중심이다. |
| Logistic Regression | linear score를 sigmoid로 probability로 바꿔 classification에 사용한다. |
| MLP | hidden layer와 nonlinearity가 복잡한 패턴 표현을 가능하게 한다. |
| Computer Vision | pixel을 meaning으로 연결하는 것이 high-level 목표다. |
| Word2Vec | proxy task를 풀며 hidden layer를 embedding으로 사용한다. |
| Pre-training | 큰 데이터로 일반적 base representation을 만든다. |
| RNN | sequence를 순서대로 처리하며 hidden state에 의존한다. |
| Attention | token 사이 global relationship을 직접 계산한다. |
| Transformer | token embedding, self-attention, multi-head attention, positional encoding을 결합한다. |

## Source Images

<ul>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-001.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 001</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-002.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 002</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-003.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 003</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-004.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 004</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-005.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 005</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-006.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 006</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-007.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 007</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-008.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 008</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-009.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 009</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-010.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 010</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-011.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 011</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-012.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 012</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-013.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 013</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-014.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 014</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-015.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 015</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-016.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 016</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-017.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 017</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-018.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 018</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-019.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 019</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-020.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 020</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-021.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 021</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-022.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 022</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-023.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 023</a></li>
  <li><a href="{{ "/assets/images/assignment/aix/pre-midterm/aix-pre-midterm-024.png" | relative_url }}" target="_blank" rel="noopener">AIX Pre-Midterm Quiz Image 024</a></li>
</ul>
