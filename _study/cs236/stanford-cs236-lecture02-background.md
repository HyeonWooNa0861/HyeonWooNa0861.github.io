---
layout: default
date: 2026-08-19 15:27:32 +0900
title: "Stanford CS236 Lecture 2: Background"
course: "CS236"
topic: "Probability, Graphical Models, and Neural Parameterizations"
order: 2
major_topic: "Deep Generative Models"
keywords:
  - "Curse of Dimensionality"
  - "Bayesian Networks"
  - "Generative Models"
  - "Discriminative Models"
  - "Logistic Regression"
---

# Stanford CS236 Lecture 2: Background

## Source

- Video: [Stanford CS236 Lecture 2](https://www.youtube.com/watch?v=rNEujZmD2Tg){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture2.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture2.pdf){:target="_blank" rel="noopener"}

> **핵심:** 2강은 앞으로 사용할 확률 배경을 압축해서 정리한다. 생성 모델을 학습한다는 것은 관측 데이터가 어떤 unknown data distribution \(p_{\mathrm{data}}\)에서 샘플되었다고 보고, 그 분포를 근사하는 model family \(\{p_{\theta}(x)\}\) 안의 한 분포를 찾는 일이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 생성 모델 학습 문제 | 데이터 분포 \(p_{\mathrm{data}}\)와 모델 분포 \(p_{\theta}\)를 어떻게 연결하는가? |
| 2 | 차원의 저주 | 고차원 joint distribution을 table로 표현하면 왜 불가능해지는가? |
| 3 | 독립성과 조건부 독립성 | independence assumption은 parameter 수를 줄이지만 어떤 표현력을 잃는가? |
| 4 | Bayesian network | DAG와 local CPD는 joint distribution을 어떻게 compact하게 표현하는가? |
| 5 | Generative vs discriminative | \(p(Y, X)\)를 모델링하는 것과 \(p(Y \mid X)\)만 모델링하는 것은 무엇이 다른가? |
| 6 | Neural parameterization | Logistic regression과 neural network는 table 대신 어떤 functional form을 가정하는가? |
| 7 | Continuous variables | density, Gaussian mixture, VAE preview는 같은 확률적 틀을 어떻게 확장하는가? |

## 핵심 내용

2강은 앞으로 사용할 확률 배경을 압축해서 정리한다. 생성 모델을 학습한다는 것은 관측 데이터가 어떤 unknown data distribution \(p_{\mathrm{data}}\)에서 샘플되었다고 보고, 그 분포를 근사하는 model family \(\{p_{\theta}(x)\}\) 안의 한 분포를 찾는 일이다. 여기에는 세 구성요소가 필요하다. 첫째, 데이터 sample이 있어야 한다. 둘째, 가능한 분포들의 집합인 model family를 정해야 한다. 셋째, \(p_{\mathrm{data}}\)와 \(p_{\theta}\)가 얼마나 가까운지 재는 loss 또는 divergence를 정해야 한다.

가장 먼저 부딪히는 문제는 representation이다. Bernoulli random variable 하나는 parameter 하나로 충분하고, categorical random variable은 가능한 outcome마다 probability를 주면 된다. 하지만 이미지의 한 pixel 색상만 해도 RGB channel이 각각 0부터 255까지 값을 가지면 \(256^3 - 1\)개의 자유도가 필요하다. 흑백 이미지가 \(n\)개의 binary pixel로 구성되면 가능한 image state는 \(2^n\)개이고, 완전한 joint distribution은 \(2^n - 1\)개의 parameter가 필요하다. 이 exponential growth가 차원의 저주다.

독립성 가정은 이 문제를 줄이는 가장 단순한 방법이다. \(X_1,\ldots,X_n\)이 서로 독립이면 joint distribution은 \(p(x_1)\cdots p(x_n)\)으로 분해되고 binary 변수에서는 \(n\)개 parameter만 필요하다. 그러나 image pixel을 완전히 독립으로 생성하면 주변 pixel과 object shape의 구조가 사라진다. 표현은 쉬워지지만 모델은 거의 쓸모없어진다.

더 유연한 도구가 chain rule과 conditional independence다. Chain rule은 어떤 joint distribution도 조건부 확률들의 곱으로 쓸 수 있게 해 준다.

$$
p(x_1,\ldots,x_n)=p(x_1)p(x_2 \mid x_1)\cdots p(x_n \mid x_1,\ldots,x_{n-1})
$$

하지만 chain rule 자체만으로는 parameter 수가 줄지 않는다. 절약은 조건부 독립성을 추가할 때 생긴다. 예를 들어 \(X_{i+1}\)이 \(X_i\)만 알면 더 과거와 독립이라고 가정하면, \(p(x_{i+1} \mid x_1,\ldots,x_i)\)가 \(p(x_{i+1} \mid x_i)\)로 줄어든다. 이것은 Markov assumption의 직관이며, 더 일반적인 형태가 Bayesian network다.

Bayesian network는 directed acyclic graph와 각 node의 conditional probability distribution으로 joint distribution을 표현한다. 각 변수 \(X_i\)는 parent set \(Pa(i)\)만 조건으로 갖고, joint는 \(\prod_i p(x_i \mid x_{Pa(i)})\)로 정의된다. DAG가 있으면 topological ordering이 존재하므로 chain rule과 맞는 valid distribution이 된다. 이 구조는 전역 joint를 작은 local CPD의 곱으로 바꾸지만, parent가 많아질수록 다시 비용이 커진다.

이 배경 위에서 강의는 generative model과 discriminative model을 비교한다. Spam classification 예시에서 generative model은 \(p(Y, X)=p(Y)p(X \mid Y)\)를 학습하고 Bayes rule로 \(p(Y \mid X)\)를 계산한다. Naive Bayes는 \(Y\)가 주어지면 단어 feature \(X_i\)들이 조건부 독립이라고 가정한다. 반대로 discriminative model은 \(p(Y \mid X)\)만 직접 모델링한다. Logistic regression은 입력 feature의 선형 결합을 sigmoid에 넣어 확률을 만든다.

Discriminative model은 \(p(X)\)를 모델링하지 않기 때문에 prediction에는 효율적이다. 예를 들어 "bank"와 "account"가 항상 같이 등장할 때 Naive Bayes는 독립 가정 때문에 evidence를 이중 계산할 수 있지만, logistic regression은 한 coefficient를 0에 가깝게 두어 중복을 줄일 수 있다. 대신 discriminative model은 입력 자체를 이해하지 않는다. 입력 feature가 일부 missing이면 \(p(X)\)를 모르기 때문에 자연스럽게 imputation하거나 anomaly를 평가하기 어렵다.

마지막 부분은 table 대신 functional parameterization을 쓰는 방법이다. Logistic regression은 \(p(Y=1 \mid x)=\sigma(\alpha_0+\sum_i \alpha_i x_i)\)처럼 단순한 함수 형태를 가정한다. Neural model은 먼저 \(h=f(Ax+b)\) 같은 nonlinear feature를 만들고 그 위에 classifier를 얹어 더 풍부한 관계를 표현한다. 앞으로 CS236의 deep generative model은 chain rule, graphical model notation, neural network parameterization을 섞어서 고차원 분포를 다룬다.

Continuous variable도 같은 원리가 적용된다. Table은 불가능하므로 Gaussian, uniform, mixture density 같은 함수형 density를 쓴다. 예를 들어 latent variable \(Z\)를 먼저 뽑고 \(X \mid Z\)를 Gaussian으로 두면 mixture of Gaussians가 된다. VAE도 큰 틀에서는 \(Z \rightarrow X\) 형태의 Bayesian network로 볼 수 있고, \(X \mid Z=z\)의 Gaussian mean과 variance를 neural network가 출력한다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| \(p_{\mathrm{data}}\) | 실제 data-generating process를 나타내는 unknown distribution이다. 우리는 sample만 관측한다. |
| Model family | \(\theta\)로 parameterized된 후보 분포들의 집합이다. 학습은 이 집합 안에서 좋은 \(p_{\theta}\)를 찾는 일이다. |
| Curse of dimensionality | 변수 수가 늘면 가능한 state와 full joint table 크기가 exponential하게 증가하는 문제다. |
| Conditional independence | 어떤 변수를 알면 다른 변수들이 더 이상 추가 정보를 주지 않는다는 가정이다. Compact representation의 핵심 도구다. |
| Bayesian network | DAG와 node별 CPD로 joint distribution을 factorize하는 probabilistic graphical model이다. |
| Naive Bayes | Label \(Y\)가 주어지면 feature들이 조건부 독립이라고 가정하는 generative classifier다. |
| Logistic regression | \(p(Y \mid X)\)를 table이 아니라 sigmoid를 통과한 선형 함수로 parameterize하는 discriminative model이다. |
| Neural parameterization | 입력을 nonlinear feature로 변환한 뒤 확률분포의 parameter를 출력해 더 유연한 조건부 분포를 만든다. |

## 학습 포인트

- Chain rule은 항상 맞지만, 그 자체로 compact representation을 주지는 않는다.
- Parameter savings는 independence 또는 functional form 같은 modeling assumption에서 나온다.
- Bayesian network는 graph가 표현하는 조건부 독립성 덕분에 joint distribution을 local factor의 곱으로 바꾼다.
- Generative model은 \(X\)와 \(Y\)의 full relationship을 모델링하므로 missing data와 anomaly reasoning에 강하지만 더 어려운 문제를 푼다.
- Discriminative model은 필요한 \(p(Y \mid X)\)만 직접 학습하므로 prediction에는 간결하지만 \(p(X)\)에 대한 질문에는 답하지 못한다.
- Neural network는 조건부 확률표를 직접 저장하지 않고, 입력 configuration을 probability parameter로 보내는 함수를 학습한다.

## 마지막 핵심 정리

2강의 핵심은 고차원 확률분포를 다루려면 반드시 가정이 필요하다는 점이다. Full joint table은 정확하지만 불가능하고, 완전 독립은 싸지만 너무 약하다. Bayesian network는 조건부 독립성으로, logistic regression과 neural network는 functional form으로 복잡도를 줄인다. 이후 deep generative model은 이 선택들을 조합해 tractable하면서도 표현력 있는 \(p_{\theta}(x)\)를 만든다.

## Study Guide

1. \(2^n - 1\) parameter 문제가 왜 이미지와 언어에서 즉시 터지는지 먼저 계산해 본다.
2. Independence, Markov assumption, Bayesian network를 "어떤 조건부를 얼마나 줄이는가"라는 기준으로 비교한다.
3. Naive Bayes와 logistic regression을 spam classification 예시로 다시 그려 본다.
4. Generative와 discriminative의 차이를 성능 우열이 아니라 "어떤 확률을 모델링하는가"로 정리한다.
5. Continuous variable 예시는 이후 VAE와 flow를 이해하기 위한 예고편으로 둔다. Gaussian assumption이 neural network를 써도 완전히 사라지지 않는다는 점을 기억한다.

## 복습 질문

<details>
<summary>1. Chain rule만 사용하면 왜 차원의 저주가 해결되지 않는가?</summary>

답변: Chain rule은 joint distribution을 조건부 확률들의 곱으로 정확히 분해하지만, 뒤쪽 조건부는 여전히 많은 이전 변수 조합에 대해 값을 가져야 한다. 아무 가정도 추가하지 않았으므로 full joint table과 같은 수준의 자유도가 남는다.

</details>

<details>
<summary>2. Bayesian network가 valid probability distribution을 정의하는 이유는 무엇인가?</summary>

답변: Bayesian network의 graph는 DAG이므로 topological ordering이 존재한다. 이 ordering에 따라 chain rule을 적용하고, parent가 아닌 변수들을 조건부 독립성으로 제거하면 node별 CPD의 곱이 되며, 이는 정상적인 joint distribution이다.

</details>

<details>
<summary>3. Naive Bayes와 logistic regression은 spam classification에서 무엇을 다르게 가정하는가?</summary>

답변: Naive Bayes는 label이 주어지면 단어 feature들이 조건부 독립이라고 가정하고 \(p(Y, X)\)를 모델링한다. Logistic regression은 \(p(Y \mid X)\)만 직접 모델링하며, feature 간 독립을 직접 가정하지 않고 선형 결합과 sigmoid라는 functional form을 가정한다.

</details>

<details>
<summary>4. Discriminative model이 missing input을 자연스럽게 처리하기 어려운 이유는 무엇인가?</summary>

답변: Discriminative model은 보통 \(p(Y \mid X)\)만 학습하고 \(p(X)\) 또는 feature 간 관계를 모델링하지 않는다. 따라서 일부 \(X_i\)가 관측되지 않았을 때 그 값을 주변 feature로부터 추론하거나 marginalize할 구조가 없다.

</details>

<details>
<summary>5. Neural parameterization은 conditional probability table을 어떻게 대체하는가?</summary>

답변: 가능한 모든 입력 조합에 대해 table entry를 저장하는 대신, neural network가 입력 feature를 받아 조건부 분포의 parameter를 출력한다. 이 방식은 완전한 자유도는 포기하지만 훨씬 적은 parameter로 복잡한 관계를 근사한다.

</details>

<details>
<summary>6. VAE preview에서 neural network를 써도 Gaussian 가정이 남는다는 말은 무슨 뜻인가?</summary>

답변: \(X \mid Z=z\)의 mean과 variance는 neural network가 출력할 수 있지만, 조건부 분포 자체를 Gaussian으로 두면 그 형태적 가정은 유지된다. Neural network는 parameter를 유연하게 만들 뿐, 선택한 density family의 제약을 완전히 없애지는 않는다.

</details>

## PDF

- [Official Lecture 2 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture2.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 course website](https://deepgenerativemodels.github.io/){:target="_blank" rel="noopener"}
- [Official video](https://www.youtube.com/watch?v=rNEujZmD2Tg){:target="_blank" rel="noopener"}
- [Official slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture2.pdf){:target="_blank" rel="noopener"}
- [Official course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
