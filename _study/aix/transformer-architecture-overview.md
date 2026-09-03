---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
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

> **핵심:** **positional encoding이 필요한 이유는** self-attention만으로는 순서 정보를 알기 어렵기 때문. **Q, K, V의 역할은** query는 찾는 정보, key는 비교 기준, value는 가져올 내용.

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

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.6-9 | token embedding + position embedding, encoder 입력 | 입력 표현식과 permutation-equivariance 증명은 도식을 수식화한 보충이다. |
| p.10-17 | $$Q,K,V$$와 $$\operatorname{softmax}(QK^T/\sqrt{d_k})V$$ | p.12의 원문 식을 p.13-17의 행렬 전개와 연결하고 scaling의 분산 근사를 명시했다. |
| p.18-20 | multi-head 구성과 output projection | concat 및 $$W_O$$ 식은 원문 구성도를 표준 표기로 옮긴 정의다. |
| p.21-22 | FFN과 encoder output | FFN·residual·layer-normalization 식은 block 도식을 계산식으로 풀어 쓴 보충이다. |
| p.25-38 | decoder self-attention, cross-attention, autoregressive output | 구조 설명에 해당하며 원문은 별도의 닫힌꼴 증명을 제시하지 않는다. |

따라서 attention 식은 원문 직접 제시식이고, equivariance·FFN·residual 계산은 구조를 검산하기 위한 저자 보충이다.

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

이 식은 **입력 표현의 정의**다. 두 벡터가 같은 $$d_{\mathrm{model}}$$ 차원을 가져야 원소별 덧셈이 가능하며, embedding 값은 학습된 무차원 representation이다.

위치 정보가 없을 때 순서를 구분하기 어려운 이유는 permutation으로 확인할 수 있다. Token 행을 바꾸는 permutation matrix를 $$P$$라 하고 $$X'=PX$$라 두면 $$Q'=PQ$$, $$K'=PK$$, $$V'=PV$$다. 따라서

$$
Q'K'^T=P(QK^T)P^T,
\qquad
\operatorname{Attention}(PX)=P\operatorname{Attention}(X)
$$

가 되어 입력 순서를 바꾸면 출력도 같은 방식으로 재배열될 뿐, 절대 위치 자체는 생기지 않는다. 이는 positional signal과 위치 의존 mask가 없는 self-attention의 **정확한 equivariance 성질**이다. Causal mask나 relative position bias가 들어가면 이 단순 관계는 더 이상 그대로 성립하지 않는다.

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

$$X\in\mathbb{R}^{n\times d_{\mathrm{model}}}$$에서 $$n$$은 token 수, $$Q,K\in\mathbb{R}^{n\times d_k}$$, $$V\in\mathbb{R}^{n\times d_v}$$다. 모든 항은 학습 representation이라 보통 물리 단위가 없는 수치다.

## 4. Scaled Dot-Product Attention

Attention score는 query와 key의 dot product로 계산한다.

$$
\mathrm{score} = \frac{QK^T}{\sqrt{d_k}}
$$

$$
\mathrm{attention}
= \operatorname{softmax}(\mathrm{score})V
$$

한 query $$q_i$$가 모든 key와 만드는 score와 weight를 펼치면 다음과 같다.

$$
s_{ij}=\frac{q_i^Tk_j}{\sqrt{d_k}},\qquad
\alpha_{ij}=\frac{e^{s_{ij}}}{\sum_{\ell=1}^{n}e^{s_{i\ell}}},\qquad
o_i=\sum_{j=1}^{n}\alpha_{ij}v_j
$$

이는 scaled dot-product attention의 **정의**다. Softmax 때문에 $$\alpha_{ij}>0$$, $$\sum_j\alpha_{ij}=1$$이므로 $$o_i$$는 value들의 가중합이다. Masked 위치는 softmax 전에 score를 $$-\infty$$로 보내 weight를 0으로 만든다.

$$\sqrt{d_k}$$ scaling은 다음 통계적 근사로 설명할 수 있다.

1. $$q_{ir}$$, $$k_{jr}$$의 각 성분이 서로 독립이고 평균 0, 분산 1이라고 가정한다.
2. Dot product는 $$q_i^Tk_j=\sum_{r=1}^{d_k}q_{ir}k_{jr}$$다.
3. 각 곱의 분산을 약 1로 보면 합의 분산은 약 $$d_k$$, 표준편차는 $$\sqrt{d_k}$$다.
4. $$\sqrt{d_k}$$로 나누면 score 분산이 약 1로 유지되어 softmax가 차원 증가만으로 포화되는 현상을 줄인다.

이 설명은 learned query와 key가 실제로 독립·단위분산이라는 증명이 아니라 초기화 규모를 이해하기 위한 **근사적 분산 분석**이다. 성분 상관이나 scale이 크면 정규화 후에도 score가 과도하게 커질 수 있고, 매우 날카로운 softmax에서는 작은 score 차이에도 gradient가 작아질 수 있다.

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

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| positional encoding이 필요한 이유는? | self-attention만으로는 순서 정보를 알기 어렵기 때문 |
| Q, K, V의 역할은? | query는 찾는 정보, key는 비교 기준, value는 가져올 내용 |
| scaling을 하는 이유는? | softmax가 과도하게 날카로워지는 것을 막기 위해 |
| multi-head attention의 장점은? | 여러 관계를 서로 다른 subspace에서 병렬로 학습 |
| decoder mask의 목적은? | 미래 token을 보는 정보 누수를 막기 위해 |

## Study Guide

짧은 token 행렬을 놓고 QKᵀ 계산, √d_k scaling, softmax, V의 weighted sum을 차례로 손으로 따라간다. attention은 token 사이 정보를 섞고 FFN은 각 위치의 표현을 변환한다는 역할 차이, positional encoding과 causal mask가 해결하는 문제가 서로 다르다는 점을 분리해 기억한다. block diagram에는 multi-head, residual, layer normalization까지 표시해 encoder와 decoder의 정보 흐름을 재현한다.

## 복습 질문

<details markdown="block">
<summary>1. Attention을 검색 엔진에 비유하면 query, key, value는 각각 무엇인가?</summary>

답변: query는 검색어, key는 각 문서의 색인 또는 제목, value는 실제 문서 내용에 해당한다. query와 key의 유사도가 높을수록 해당 value를 더 많이 가져온다. Transformer에서는 이 과정을 token 표현 사이에서 수행한다.

</details>

<details markdown="block">
<summary>2. Attention sublayer와 FFN sublayer의 역할 차이를 설명하라.</summary>

답변: attention sublayer는 token들 사이의 관계를 계산해 문맥 정보를 섞는다. FFN sublayer는 각 token 위치에서 독립적으로 비선형 변환을 적용해 표현력을 높인다. 즉 attention은 token 간 상호작용, FFN은 위치별 feature 변환에 가깝다.

</details>

<details markdown="block">
<summary>3. Encoder-only 모델과 decoder-only 모델의 attention mask 차이를 설명하라.</summary>

답변: encoder-only 모델은 보통 입력 전체를 동시에 볼 수 있어 양방향 attention을 사용한다. decoder-only 모델은 다음 token 예측을 위해 미래 token을 보면 안 되므로 causal mask를 사용한다. 이 차이가 이해 중심 모델과 생성 중심 모델의 학습 방식 차이를 만든다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf" | relative_url }}" target="_blank" rel="noopener">2_Overview_TF.pdf</a></li>
</ul>
