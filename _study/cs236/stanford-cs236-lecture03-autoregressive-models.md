---
layout: default
title: "Stanford CS236 Lecture 3: Autoregressive Models"
course: "CS236"
topic: "Autoregressive Factorization and Neural Density Models"
order: 3
major_topic: "Deep Generative Models"
keywords:
  - "Autoregressive Models"
  - "Chain Rule"
  - "NADE"
  - "MADE"
  - "PixelCNN"
---

# Stanford CS236 Lecture 3: Autoregressive Models

## Source

- Video: [Stanford CS236 Lecture 3](https://www.youtube.com/watch?v=tRArbBf-AbI){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture3.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture3.pdf){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Autoregressive factorization | Chain rule로 \(p(x_1,\ldots,x_n)\)을 어떻게 순차 조건부의 곱으로 바꾸는가? |
| 2 | FVSBN | Logistic regression conditional만으로 joint distribution을 만들면 어떤 한계가 생기는가? |
| 3 | NADE와 RNADE | Weight tying과 neural hidden layer는 parameter 수와 표현력을 어떻게 바꾸는가? |
| 4 | Autoencoder와의 차이 | Reconstruction model이 언제 generative model이 되지 못하는가? |
| 5 | MADE | Masked autoencoder는 future variable을 보지 못하게 하여 autoregressive 구조를 어떻게 보존하는가? |
| 6 | RNN과 Transformer | Sequence history를 hidden state 또는 attention으로 다루는 방식은 어떤 trade-off를 갖는가? |
| 7 | 이미지·음성 응용 | PixelRNN, PixelCNN, WaveNet, PixelDefend는 같은 원리를 어떻게 적용하는가? |

## 핵심 내용

3강은 첫 번째 실제 모델군인 autoregressive model을 다룬다. 핵심 아이디어는 단순하다. 어떤 joint distribution도 chain rule에 의해 순서가 있는 조건부 확률들의 곱으로 쓸 수 있다.

$$
p(x_1,\ldots,x_n)=\prod_{i=1}^{n}p(x_i \mid x_{<i})
$$

여기서 \(x_{<i}\)는 선택한 ordering에서 \(x_i\)보다 앞에 있는 변수들을 뜻한다. 이미지라면 왼쪽 위에서 오른쪽 아래로 가는 raster scan ordering을 쓸 수 있고, 텍스트라면 왼쪽에서 오른쪽으로 token을 나열하는 자연스러운 ordering을 쓸 수 있다. Chain rule 자체는 어떤 ordering에도 성립하지만, 모델링 난이도는 ordering에 크게 영향을 받는다.

Autoregressive model은 고차원 joint distribution을 "다음 변수 예측" 문제들의 묶음으로 바꾼다. Binarized MNIST 예시에서 \(28 \times 28=784\)개의 binary pixel을 한 번에 모델링하면 \(2^{784}\) 규모의 state space가 생긴다. Autoregressive 관점에서는 첫 pixel을 뽑고, 그다음 pixel은 첫 pixel을 조건으로, 세 번째 pixel은 앞의 두 pixel을 조건으로 뽑는다. 생성 절차와 확률 계산 절차가 같은 factorization에서 나온다는 점이 장점이다.

가장 단순한 형태가 Fully Visible Sigmoid Belief Network(FVSBN)다. 각 조건부 \(p(X_i=1 \mid x_{<i})\)를 logistic regression으로 parameterize한다.

$$
\hat{x}_i=\sigma(\alpha_{0i}+\sum_{j<i}\alpha_{ji}x_j)
$$

이 모델은 full table보다 훨씬 작지만, 각 pixel마다 별도의 logistic regression을 두므로 parameter 수가 대략 \(n^2/2\)로 커진다. 또한 logistic regression의 표현력이 부족하면 복잡한 image dependency를 잡지 못한다. 강의의 Caltech silhouette 예시는 단순 logistic conditional이 실제 모양 구조를 충분히 만들기 어렵다는 점을 보여 준다.

NADE(Neural Autoregressive Density Estimation)는 이 조건부를 더 강한 neural network로 바꾼다. 단순히 선형 결합을 sigmoid에 넣는 대신, 이전 변수들에서 hidden representation \(h_i\)를 만들고 그 위에서 \(x_i\)의 Bernoulli parameter를 예측한다. 중요한 개선은 weight tying이다. 각 \(i\)마다 완전히 독립된 network를 쓰지 않고, 큰 weight matrix의 prefix를 공유한다. 이렇게 하면 parameter 수를 \(n\)에 대해 선형 수준으로 줄이고, likelihood 평가에서도 계산을 재사용할 수 있다.

Discrete variable이 binary가 아니면 Bernoulli 대신 categorical distribution을 출력하면 된다. Pixel intensity처럼 \(K\)개 값을 가지는 변수는 softmax가 \(K\)차원 probability vector를 만든다. Continuous variable에서는 output이 Gaussian이나 mixture of Gaussians의 mean, variance 같은 density parameter가 된다. RNADE는 이런 연속형 conditional density를 autoregressive 방식으로 parameterize하는 예다.

강의 중간의 중요한 구분은 autoencoder와 autoregressive model의 차이다. Autoencoder는 \(x\)를 encoding한 뒤 \(x\)를 reconstruction하도록 학습하지만, 일반적인 autoencoder는 \(p(x)\)라는 valid distribution을 정의하지 않는다. Decoder에 무엇을 넣어 sampling할지 명확하지 않기 때문이다. Autoregressive generative model이 되려면 \(x_i\)를 예측할 때 \(x_i\) 자신이나 미래 변수 \(x_{>i}\)를 볼 수 없어야 한다.

MADE(Masked Autoencoder for Distribution Estimation)는 이 제약을 mask로 강제한다. Hidden unit마다 어떤 prefix까지 볼 수 있는지 index를 부여하고, 그 index를 넘는 연결을 0으로 만든다. 마지막 layer에서는 output \(x_i\)가 오직 \(x_{<i}\)에만 의존하게 한다. 이렇게 하면 autoencoder처럼 한 번의 forward pass로 모든 conditional parameter를 계산할 수 있어 training likelihood evaluation이 빠르다. 하지만 generation은 여전히 \(x_1, x_2,\ldots\)를 순서대로 뽑아야 하므로 autoregressive sequentiality는 남는다.

RNN은 긴 history \(x_{1:t}\)를 hidden state \(h_t\)로 요약하는 방식이다. Parameter 수는 sequence length에 직접 비례하지 않고, 같은 transition matrix를 반복해 사용한다. Character-level RNN은 Shakespeare나 Wikipedia 같은 데이터를 한 글자씩 생성하면서 단어, 문법, 괄호 구조까지 일부 학습할 수 있음을 보여 준다. 그러나 모든 과거 정보를 하나의 hidden vector에 압축해야 하고, likelihood 평가와 generation이 순차적이며, vanishing/exploding gradient 문제가 있다.

Attention과 transformer는 이 병목을 줄이기 위해 등장한다. Attention은 현재 query가 과거 key 중 어느 부분을 참고해야 하는지 softmax distribution으로 정하고, value의 weighted sum으로 context summary를 만든다. Generative transformer는 RNN recursion을 self-attention으로 바꾸어 training을 parallelize하지만, autoregressive 구조를 지키려면 masked self-attention으로 미래 token을 보지 못하게 해야 한다.

이미지와 음성 응용도 같은 틀이다. PixelRNN은 image pixel을 raster order로 예측하고, RGB channel도 red, green, blue 순서로 factorize한다. PixelCNN은 masked convolution을 사용해 같은 autoregressive order를 유지하면서 training을 더 병렬화한다. PixelDefend는 clean image distribution을 PixelCNN으로 학습한 뒤 adversarial input의 likelihood가 낮은지 확인하는 응용이다. WaveNet은 dilated convolution으로 receptive field를 넓혀 speech signal을 autoregressive하게 생성한다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Autoregressive model | Joint distribution을 정해진 ordering의 조건부 확률 곱으로 표현하는 생성 모델이다. |
| Ordering | 어떤 변수를 먼저 생성할지 정하는 순서다. Chain rule은 항상 성립하지만 좋은 ordering은 모델링 난이도를 낮춘다. |
| FVSBN | Binary variable 조건부를 logistic regression으로 모델링하는 초기 autoregressive model이다. |
| NADE | Neural hidden layer와 weight tying으로 조건부 분포를 더 유연하고 효율적으로 parameterize한다. |
| MADE | Mask를 사용해 autoencoder가 future variable을 보지 못하게 만들어 valid autoregressive model로 바꾼다. |
| RNN | Hidden state를 반복 갱신해 arbitrary-length sequence의 history를 요약하는 autoregressive architecture다. |
| Masked self-attention | Transformer가 training 중 미래 token을 보지 못하게 해 autoregressive factorization을 지키는 장치다. |
| PixelCNN | Masked convolution으로 image pixel conditional을 병렬적으로 계산하는 autoregressive image model이다. |

## 학습 포인트

- Autoregressive model의 강점은 likelihood 계산과 sampling 절차가 명확하다는 점이다.
- 단점은 ordering이 필요하고, 실제 generation은 순차적이라는 점이다.
- FVSBN은 chain rule을 logistic regression 조건부로 구현하지만 표현력이 약하고 parameter가 \(O(n^2)\)로 늘어난다.
- NADE는 neural conditional과 weight sharing으로 표현력과 효율성을 모두 개선한다.
- MADE의 mask는 "training에서 cheating을 막는" 구조적 제약이다. 이 제약 없이는 reconstruction loss가 generative likelihood와 달라질 수 있다.
- RNN은 extreme weight sharing으로 arbitrary length sequence를 다루지만, hidden state bottleneck과 sequential evaluation 때문에 transformer 이전 시대의 한계를 갖는다.
- PixelCNN과 WaveNet은 autoregressive factorization이 텍스트뿐 아니라 이미지와 음성에도 적용된다는 것을 보여 준다.

## 마지막 핵심 정리

Autoregressive model은 고차원 분포를 순차 예측 문제로 바꾸는 가장 직접적인 방법이다. 이 방식은 \(p(x)\)를 명시적으로 계산할 수 있고 sampling도 chain rule 순서대로 진행할 수 있어 이해하기 쉽다. 그러나 모든 변수에 ordering을 부여해야 하며, generation은 본질적으로 순차적이다. FVSBN, NADE, MADE, RNN, Transformer, PixelCNN은 모두 이 trade-off 위에서 조건부 분포를 얼마나 강하고 효율적으로 parameterize할지에 대한 서로 다른 답이다.

## Study Guide

1. 먼저 chain rule 식을 외우고, likelihood evaluation과 sampling이 같은 factorization을 어떻게 반대로 사용하는지 확인한다.
2. FVSBN과 NADE를 parameter count, 표현력, 계산 재사용 관점에서 비교한다.
3. Autoencoder가 reconstruction은 잘해도 왜 곧바로 generative model이 아닌지 설명해 본다.
4. MADE의 mask가 training time parallelism과 autoregressive validity를 동시에 어떻게 제공하는지 그림 없이 말로 설명한다.
5. RNN, Transformer, PixelCNN을 모두 "다음 variable conditional을 어떻게 계산하는가"라는 하나의 질문으로 묶어 본다.

## 복습 질문

<details>
<summary>1. Autoregressive factorization이 생성 모델에 유용한 이유는 무엇인가?</summary>

답변: Joint distribution을 한 번에 표현하지 않고, 각 변수를 이전 변수들에 조건부로 예측하는 작은 문제들의 곱으로 바꾼다. 따라서 likelihood는 조건부 확률을 곱하거나 log-probability를 더해 계산하고, sampling은 같은 순서로 변수를 하나씩 뽑으면 된다.

</details>

<details>
<summary>2. FVSBN이 full joint table보다 낫지만 충분하지 않은 이유는 무엇인가?</summary>

답변: Full table의 exponential parameter 수를 피하지만, 각 pixel 조건부를 별도의 logistic regression으로 두면 parameter가 대략 \(O(n^2)\)로 커지고 표현력이 선형 조건부에 제한된다. 복잡한 이미지 구조를 만들기에는 약하다.

</details>

<details>
<summary>3. NADE에서 weight tying이 중요한 이유는 무엇인가?</summary>

답변: 모든 조건부 예측 문제를 완전히 별도의 network로 풀면 parameter와 계산 비용이 커진다. Weight tying은 같은 feature extractor를 여러 conditional에서 공유해 parameter 수를 줄이고, 앞서 계산한 matrix-vector product를 재사용하게 한다.

</details>

<details>
<summary>4. 일반 autoencoder가 generative model이 아닌 이유는 무엇인가?</summary>

답변: Autoencoder는 입력 \(x\)를 encoding하고 reconstruction하도록 학습하지만, 새로운 \(x\)를 만들기 위해 decoder에 넣을 latent input의 확률분포를 정의하지 않는다. 따라서 valid \(p(x)\)나 명확한 sampling procedure가 없다.

</details>

<details>
<summary>5. MADE의 mask는 무엇을 막고 무엇을 가능하게 하는가?</summary>

답변: Mask는 \(x_i\)를 예측할 때 \(x_i\) 자신이나 미래 변수 \(x_{>i}\)를 보지 못하게 막는다. 그 결과 autoencoder 형태를 유지하면서도 autoregressive factorization에 맞는 조건부들을 한 번의 forward pass로 계산할 수 있다.

</details>

<details>
<summary>6. RNN이 autoregressive model에 자연스럽지만 state-of-the-art language model에서 밀려난 핵심 이유는 무엇인가?</summary>

답변: RNN은 history를 하나의 hidden state로 요약하므로 긴 문맥에서 정보 병목이 생기고, likelihood evaluation도 time step 순서대로 unroll해야 해서 병렬화가 어렵다. Transformer는 masked self-attention으로 autoregressive 조건을 지키면서 training 병렬성을 크게 높인다.

</details>

## PDF

- [Official Lecture 3 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture3.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 course website](https://deepgenerativemodels.github.io/){:target="_blank" rel="noopener"}
- [Official video](https://www.youtube.com/watch?v=tRArbBf-AbI){:target="_blank" rel="noopener"}
- [Official slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture3.pdf){:target="_blank" rel="noopener"}
- [Official course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
