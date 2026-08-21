---
layout: default
date: 2026-05-20 13:52:05 +0900
title: "Transformer Architecture Overview"
course: "AIX"
topic: "Transformer Architecture Overview"
order: 5
major_topic: "Artificial Intelligence"
keywords:
  - "Tokenization"
  - "Positional Encoding"
  - "QKV Attention"
  - "Multi-Head Attention"
  - "Layer Normalization"
---

# Transformer Architecture Overview

Source PDF: `2_Overview_TF.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Token과 embedding | 문장을 모델 입력 벡터로 어떻게 바꾸는가? |
| 2 | Positional encoding | Transformer는 token 순서를 어떻게 알 수 있는가? |
| 3 | Q, K, V | Attention을 검색 문제처럼 보면 무엇이 보이는가? |
| 4 | Scaled dot-product attention | 어떤 token을 얼마나 볼지 어떻게 계산하는가? |
| 5 | Multi-head attention | 여러 attention head를 두는 이유는 무엇인가? |
| 6 | Feed-forward block | Attention 뒤의 MLP는 어떤 역할을 하는가? |
| 7 | Residual과 normalization | 깊은 Transformer를 안정적으로 학습시키는 장치는 무엇인가? |
| 8 | Encoder와 decoder | 이해용 구조와 생성용 구조는 어떻게 달라지는가? |

## 1. Tokenization과 Embedding

Transformer는 raw text를 그대로 받지 않는다. 먼저 text를 token으로 나누고, 각 token을 정수 id로 바꾼 뒤 embedding vector로 변환한다.

```text
"I love AI" -> ["I", "love", "AI"] -> [12, 845, 91] -> vectors
```

Embedding matrix는 각 token id에 대응하는 dense vector를 저장한다. 학습이 진행되면서 token vector는 문맥적, 의미적 패턴을 반영하도록 조정된다.

## 2. Positional Encoding

Self-attention 자체는 token 집합을 순서 없이 보는 연산에 가깝다. 따라서 Transformer는 token의 위치 정보를 따로 넣어야 한다.

$$
\mathrm{input\ representation}
= \mathrm{token\ embedding} + \mathrm{positional\ encoding}
$$

| 방식 | 설명 |
|---|---|
| Sinusoidal position | 고정된 sin/cos 함수를 사용한다. |
| Learned position | 위치 embedding도 parameter로 학습한다. |
| Relative position | token 사이의 상대적 거리를 반영한다. |

위치 정보가 있어야 "dog bites man"과 "man bites dog"처럼 같은 token이라도 순서가 다른 문장을 구분할 수 있다.

## 3. Query, Key, Value

Attention은 검색 과정처럼 이해할 수 있다.

| 요소 | 검색 비유 | Transformer에서의 의미 |
|---|---|---|
| Query | 내가 찾는 질문 | 현재 token이 필요한 정보 |
| Key | 문서의 색인 | 각 token이 가진 비교용 표지 |
| Value | 실제 문서 내용 | attention 후 가져올 정보 |

각 token embedding은 서로 다른 선형 변환을 거쳐 query, key, value vector가 된다.

$$
Q = XW_Q,\qquad K = XW_K,\qquad V = XW_V
$$

## 4. Scaled Dot-Product Attention

Attention score는 query와 key의 dot product로 계산한다.

$$
\mathrm{score} = \frac{QK^T}{\sqrt{d_k}}
$$

$$
\mathrm{attention}
= \operatorname{softmax}(\mathrm{score})V
$$

\\(\sqrt{d_k}\\)로 나누는 이유는 차원이 커질수록 dot product 값이 커져 softmax가 너무 날카로워지는 것을 막기 위해서다.

| 단계 | 설명 |
|---|---|
| Dot product | query와 key의 유사도를 계산한다. |
| Scaling | 값의 크기를 안정화한다. |
| Softmax | 참고 비율을 확률처럼 정규화한다. |
| Weighted sum | value를 attention weight로 합친다. |

## 5. Multi-Head Attention

하나의 attention head만 있으면 token 관계를 한 가지 관점으로만 본다. Multi-head attention은 여러 head가 서로 다른 projection을 통해 다양한 관계를 학습하게 한다.

$$
\mathrm{head}_i = \operatorname{Attention}(Q_i,K_i,V_i)
$$

$$
\operatorname{MultiHead}
= \operatorname{concat}(\mathrm{head}_1,\ldots,\mathrm{head}_h)W_O
$$

어떤 head는 문법적 관계를, 다른 head는 의미적 관계나 긴 거리 의존성을 볼 수 있다. 중요한 점은 head를 나눔으로써 한 번의 attention block 안에서 여러 종류의 상호작용을 병렬로 계산한다는 것이다.

## 6. Feed-Forward Network

Attention이 token 사이의 정보를 섞는 역할이라면, feed-forward network는 각 token 위치에서 representation을 비선형 변환한다.

$$
\operatorname{FFN}(x)
= W_2\phi(W_1x+b_1)+b_2
$$

Transformer block은 보통 attention sublayer와 FFN sublayer로 구성된다. Attention이 context를 모으고, FFN이 각 token representation을 더 풍부하게 가공한다.

## 7. Residual Connection과 Layer Normalization

깊은 Transformer를 안정적으로 학습하기 위해 residual connection과 normalization을 사용한다.

$$
x = x + \operatorname{Attention}(\operatorname{LN}(x))
$$

$$
x = x + \operatorname{FFN}(\operatorname{LN}(x))
$$

| 장치 | 역할 |
|---|---|
| Residual connection | gradient 흐름을 돕고 원래 정보를 보존한다. |
| Layer normalization | activation scale을 안정화한다. |
| Dropout | 일부 연결을 무작위로 끊어 overfitting을 줄인다. |

이 구성은 layer가 많아져도 학습이 무너지지 않도록 돕는다.

## 8. Encoder와 Decoder

Transformer encoder는 입력 전체를 양방향으로 보며 representation을 만든다. Decoder는 autoregressive generation을 위해 미래 token을 보지 못하도록 mask를 사용한다.

| 구조 | Attention | 사용 예 |
|---|---|---|
| Encoder | bidirectional self-attention | 분류, 검색, 이해 |
| Decoder | masked self-attention | next-token generation |
| Encoder-Decoder | encoder self-attention + decoder cross-attention | 번역, 요약 |

Decoder의 mask는 현재 위치에서 미래 정답을 미리 보는 정보 누수를 막는다.

## 9. 전체 흐름 예시

Transformer 한 block의 흐름은 다음처럼 정리할 수 있다.

```text
tokens
-> embeddings + positions
-> multi-head self-attention
-> residual + normalization
-> feed-forward network
-> residual + normalization
-> next block or output head
```

이 구조가 반복되면서 모델은 token의 local meaning과 global context를 함께 반영한 representation을 만든다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| positional encoding이 필요한 이유는? | self-attention만으로는 순서 정보를 알기 어렵기 때문 |
| Q, K, V의 역할은? | query는 찾는 정보, key는 비교 기준, value는 가져올 내용 |
| scaling을 하는 이유는? | softmax가 과도하게 날카로워지는 것을 막기 위해 |
| multi-head attention의 장점은? | 여러 관계를 서로 다른 subspace에서 병렬로 학습 |
| decoder mask의 목적은? | 미래 token을 보는 정보 누수를 막기 위해 |

## 복습 질문

<details>
<summary>1. Attention을 검색 엔진에 비유하면 query, key, value는 각각 무엇인가?</summary>

답변: query는 검색어, key는 각 문서의 색인 또는 제목, value는 실제 문서 내용에 해당한다. query와 key의 유사도가 높을수록 해당 value를 더 많이 가져온다. Transformer에서는 이 과정을 token 표현 사이에서 수행한다.

</details>

<details>
<summary>2. Attention sublayer와 FFN sublayer의 역할 차이를 설명하라.</summary>

답변: attention sublayer는 token들 사이의 관계를 계산해 문맥 정보를 섞는다. FFN sublayer는 각 token 위치에서 독립적으로 비선형 변환을 적용해 표현력을 높인다. 즉 attention은 token 간 상호작용, FFN은 위치별 feature 변환에 가깝다.

</details>

<details>
<summary>3. Encoder-only 모델과 decoder-only 모델의 attention mask 차이를 설명하라.</summary>

답변: encoder-only 모델은 보통 입력 전체를 동시에 볼 수 있어 양방향 attention을 사용한다. decoder-only 모델은 다음 token 예측을 위해 미래 token을 보면 안 되므로 causal mask를 사용한다. 이 차이가 이해 중심 모델과 생성 중심 모델의 학습 방식 차이를 만든다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf" | relative_url }}" target="_blank" rel="noopener">2_Overview_TF.pdf</a></li>
</ul>
