---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
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

> **핵심:** Self-attention만으로는 토큰의 순서가 드러나지 않아 positional encoding이 필요합니다. Attention에서는 query가 찾는 정보를 나타내고, key는 관련성을 비교할 기준, value는 그 결과에 따라 모을 내용을 담습니다.

Transformer는 문장 속 단어들이 서로 얼마나 관련 있는지 한꺼번에 비교합니다. `개가 사람을 물었다`와 `사람이 개를 물었다`는 같은 단어를 쓰지만 뜻이 다르므로, 관련도만큼 순서도 알아야 합니다. Positional encoding은 각 토큰에 위치 정보를 더하고, attention은 현재 토큰이 참고할 다른 토큰의 정보를 골라 섞습니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Token과 embedding | 문장을 모델 입력 벡터로 어떻게 바꿉니까? |
| 2 | Positional encoding | Transformer는 token 순서를 어떻게 알 수 있습니까? |
| 3 | Q, K, V | Attention을 검색 문제처럼 보면 무엇이 보입니까? |
| 4 | Scaled dot-product attention | 어떤 token을 얼마나 볼지 어떻게 계산합니까? |
| 5 | Multi-head attention | 여러 attention head를 두는 이유는 무엇입니까? |
| 6 | Feed-forward block | Attention 뒤의 MLP는 어떤 역할을 합니까? |
| 7 | Residual과 normalization | 깊은 Transformer를 안정적으로 학습시키는 장치는 무엇입니까? |
| 8 | Encoder와 decoder | 이해용 구조와 생성용 구조는 어떻게 달라집니까? |

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.6-9 | token embedding + position embedding, encoder 입력 | 입력 표현식과 permutation-equivariance 증명은 도식을 수식화한 보충입니다. |
| p.10-17 | $$Q,K,V$$와 $$\operatorname{softmax}(QK^T/\sqrt{d_k})V$$ | p.12의 원문 식을 p.13-17의 행렬 전개와 연결하고 scaling의 분산 근사를 명시했습니다. |
| p.18-20 | multi-head 구성과 output projection | concat 및 $$W_O$$ 식은 원문 구성도를 표준 표기로 옮긴 정의입니다. |
| p.21-22 | FFN과 encoder output | FFN·residual·layer-normalization 식은 block 도식을 계산식으로 풀어 쓴 보충입니다. |
| p.25-38 | decoder self-attention, cross-attention, autoregressive output | 구조 설명에 해당하며 원문은 별도의 닫힌꼴 증명을 제시하지 않습니다. |

따라서 attention 식은 원문 직접 제시식이고, equivariance·FFN·residual 계산은 구조를 검산하기 위한 저자 보충입니다.

</details>

## 1. Tokenization과 Embedding

Transformer는 글자를 그대로 계산하지 않습니다. 먼저 문장을 처리 단위인 token으로 나누고, 각 token을 정수 번호로 바꾼 뒤 모델이 계산할 수 있는 embedding vector로 변환합니다.

```text
"I love AI" -> ["I", "love", "AI"] -> [12, 845, 91] -> vectors
```

Embedding matrix는 각 token 번호에 대응하는 짧고 밀집된 숫자 벡터를 저장합니다. 학습이 진행되면 비슷한 문맥에 쓰이는 token이 계산에 유용한 관계를 갖도록 이 숫자들이 조정됩니다.

## 2. Positional Encoding

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/transformer-slide-07.png" | relative_url }}" alt="AIX Transformer 강의 7쪽. BOS부터 EOS까지의 token sequence에 position-aware embedding이 결합되는 예시." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf#page=7" | relative_url }}" target="_blank" rel="noopener"><code>2_Overview_TF.pdf</code> p.7</a> — token identity에 순서 정보를 더한 position-aware embedding 원본 예시.</figcaption>
</figure>

그림의 token 상자는 문장 내용이고, 별도의 position-aware embedding은 같은 token이라도 놓인 위치가 다르면 다른 입력 표현이 되게 합니다. Self-attention 자체는 순서를 내장하지 않으므로 이 위치 정보가 없으면 token 배열을 구분할 근거가 사라집니다.

Self-attention 자체는 token 집합을 순서 없이 보는 연산에 가깝습니다. 따라서 Transformer는 token의 위치 정보를 따로 넣어야 합니다.

$$
\mathrm{input\ representation}
= \mathrm{token\ embedding} + \mathrm{positional\ encoding}
$$

이 식은 **입력 표현의 정의**입니다. 두 벡터가 같은 $$d_{\mathrm{model}}$$ 차원을 가져야 원소별 덧셈이 가능하며, embedding 값은 학습된 무차원 representation입니다.

위치 정보가 없을 때 순서를 구분하기 어려운 이유는 permutation으로 확인할 수 있습니다. Token 행을 바꾸는 permutation matrix를 $$P$$라 하고 $$X'=PX$$라 두면 $$Q'=PQ$$, $$K'=PK$$, $$V'=PV$$입니다. 따라서

<details markdown="block">
<summary markdown="span">Derivation: Permutation equivariance without position signals</summary>

$$
Q'K'^T=P(QK^T)P^T,
\qquad
\operatorname{Attention}(PX)=P\operatorname{Attention}(X)
$$

가 되어 입력 순서를 바꾸면 출력도 같은 방식으로 재배열될 뿐, 절대 위치 자체는 생기지 않습니다. 이는 positional signal과 위치 의존 mask가 없는 self-attention의 **정확한 equivariance 성질**입니다. Causal mask나 relative position bias가 들어가면 이 단순 관계는 더 이상 그대로 성립하지 않습니다.

</details>

| 방식 | 설명 |
|---|---|
| Sinusoidal position | 고정된 sin/cos 함수를 사용합니다. |
| Learned position | 위치 embedding도 parameter로 학습합니다. |
| Relative position | token 사이의 상대적 거리를 반영합니다. |

위치 정보가 있어야 "dog bites man"과 "man bites dog"처럼 같은 token이라도 순서가 다른 문장을 구분할 수 있습니다.

## 3. Query, Key, Value

Attention은 검색 과정처럼 이해할 수 있습니다.

| 요소 | 검색 비유 | Transformer에서의 의미 |
|---|---|---|
| Query | 내가 찾는 질문 | 현재 token이 필요한 정보 |
| Key | 문서의 색인 | 각 token이 가진 비교용 표지 |
| Value | 실제 문서 내용 | attention 후 가져올 정보 |

각 token embedding은 서로 다른 선형 변환을 거쳐 query, key, value vector가 됩니다.

$$
Q = XW_Q,\qquad K = XW_K,\qquad V = XW_V
$$

$$X\in\mathbb{R}^{n\times d_{\mathrm{model}}}$$에서 $$n$$은 token 수, $$Q,K\in\mathbb{R}^{n\times d_k}$$, $$V\in\mathbb{R}^{n\times d_v}$$입니다. 모든 항은 학습 representation이라 보통 물리 단위가 없는 수치입니다.

## 4. Scaled Dot-Product Attention

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/transformer-slide-13.png" | relative_url }}" alt="AIX Transformer Architecture 강의 슬라이드 13쪽. 위치 정보가 더해진 token embedding에서 Wq, Wk, Wv를 거쳐 Q, K, V와 attention 출력으로 이어지는 예시." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf#page=13" | relative_url }}" target="_blank" rel="noopener"><code>2_Overview_TF.pdf</code> p.13</a> — position-aware embedding에서 Q, K, V를 만들고 attention을 계산하는 원본 예시.</figcaption>
</figure>

그림은 아래에서 위로 읽습니다. 문장 token과 특수 token `[BOS]`, `[EOS]`가 position-aware embedding matrix를 이루고, 같은 입력이 서로 다른 projection $$W_Q,W_K,W_V$$를 거쳐 $$Q,K,V$$가 됩니다. $$QK^T$$는 token 쌍의 score 행렬을 만들며, softmax 후의 각 행은 한 query가 모든 value를 어떤 비율로 합칠지 나타냅니다. 원본의 빈 사각형은 수치가 채워진 계산 결과가 아니므로 임의의 attention weight로 해석하지 않습니다.

Attention score는 query와 key의 dot product로 계산합니다.

$$
\mathrm{score} = \frac{QK^T}{\sqrt{d_k}}
$$

$$
\mathrm{attention}
= \operatorname{softmax}(\mathrm{score})V
$$

한 query $$q_i$$가 모든 key와 만드는 score와 weight를 펼치면 다음과 같습니다.

$$
s_{ij}=\frac{q_i^Tk_j}{\sqrt{d_k}},\qquad
\alpha_{ij}=\frac{e^{s_{ij}}}{\sum_{\ell=1}^{n}e^{s_{i\ell}}},\qquad
o_i=\sum_{j=1}^{n}\alpha_{ij}v_j
$$

이는 scaled dot-product attention의 **정의**입니다. Softmax 때문에 $$\alpha_{ij}>0$$, $$\sum_j\alpha_{ij}=1$$이므로 $$o_i$$는 value들의 가중합입니다. Masked 위치는 softmax 전에 score를 $$-\infty$$로 보내 weight를 0으로 만듭니다.

$$\sqrt{d_k}$$ scaling은 다음 통계적 근사로 설명할 수 있습니다.

<details markdown="block">
<summary markdown="span">Derivation: Scaled dot-product variance</summary>

1. $$q_{ir}$$, $$k_{jr}$$의 각 성분이 서로 독립이고 평균 0, 분산 1이라고 가정합니다.
2. Dot product는 $$q_i^Tk_j=\sum_{r=1}^{d_k}q_{ir}k_{jr}$$입니다.
3. 각 곱의 분산을 약 1로 보면 합의 분산은 약 $$d_k$$, 표준편차는 $$\sqrt{d_k}$$입니다.
4. $$\sqrt{d_k}$$로 나누면 score 분산이 약 1로 유지되어 softmax가 차원 증가만으로 포화되는 현상을 줄입니다.

이 설명은 learned query와 key가 실제로 독립·단위분산이라는 증명이 아니라 초기화 규모를 이해하기 위한 **근사적 분산 분석**입니다. 성분 상관이나 scale이 크면 정규화 후에도 score가 과도하게 커질 수 있고, 매우 날카로운 softmax에서는 작은 score 차이에도 gradient가 작아질 수 있습니다.

</details>

| 단계 | 설명 |
|---|---|
| Dot product | query와 key의 유사도를 계산합니다. |
| Scaling | 값의 크기를 안정화합니다. |
| Softmax | 참고 비율을 확률처럼 정규화합니다. |
| Weighted sum | value를 attention weight로 합칩니다. |

## 5. Multi-Head Attention

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/transformer-slide-19.png" | relative_url }}" alt="AIX Transformer 강의 19쪽. position-aware embedding 행렬에서 Wq, Wk, Wv로 Q K V를 만들고 scaled dot-product attention을 계산한다." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf#page=19" | relative_url }}" target="_blank" rel="noopener"><code>2_Overview_TF.pdf</code> p.19</a> — embedding에서 Q·K·V projection을 거쳐 attention output을 만드는 원본 계산 흐름.</figcaption>
</figure>

아래 token 행렬이 세 projection $$W_Q,W_K,W_V$$를 지나 서로 다른 Q, K, V가 됩니다. 여러 head는 이 projection 묶음을 독립적으로 두어, 같은 문장에서 서로 다른 관계를 동시에 탐색합니다.

하나의 attention head만 있으면 token 관계를 한 가지 관점으로만 봅니다. Multi-head attention은 여러 head가 서로 다른 projection을 통해 다양한 관계를 학습하게 합니다.

$$
\mathrm{head}_i = \operatorname{Attention}(Q_i,K_i,V_i)
$$

$$
\operatorname{MultiHead}
= \operatorname{concat}(\mathrm{head}_1,\ldots,\mathrm{head}_h)W_O
$$

어떤 head는 문법적 관계를, 다른 head는 의미적 관계나 긴 거리 의존성을 볼 수 있습니다. 중요한 점은 head를 나눔으로써 한 번의 attention block 안에서 여러 종류의 상호작용을 병렬로 계산한다는 것입니다.

## 6. Feed-Forward Network

Attention이 token 사이의 정보를 섞는 역할이라면, feed-forward network는 각 token 위치에서 representation을 비선형 변환합니다.

$$
\operatorname{FFN}(x)
= W_2\phi(W_1x+b_1)+b_2
$$

Transformer block은 보통 attention sublayer와 FFN sublayer로 구성됩니다. Attention이 context를 모으고, FFN이 각 token representation을 더 풍부하게 가공합니다.

## 7. Residual Connection과 Layer Normalization

깊은 Transformer를 안정적으로 학습하기 위해 residual connection과 normalization을 사용합니다.

$$
x = x + \operatorname{Attention}(\operatorname{LN}(x))
$$

$$
x = x + \operatorname{FFN}(\operatorname{LN}(x))
$$

| 장치 | 역할 |
|---|---|
| Residual connection | gradient 흐름을 돕고 원래 정보를 보존합니다. |
| Layer normalization | activation scale을 안정화합니다. |
| Dropout | 일부 연결을 무작위로 끊어 overfitting을 줄입니다. |

이 구성은 layer가 많아져도 학습이 무너지지 않도록 돕습니다.

## 8. Encoder와 Decoder

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/transformer-slide-27.png" | relative_url }}" alt="AIX Transformer 강의 27쪽. encoder의 encoded embedding과 BOS token을 받아 decoder self-attention이 시작되는 구조." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf#page=27" | relative_url }}" target="_blank" rel="noopener"><code>2_Overview_TF.pdf</code> p.27</a> — encoder 표현과 생성 시작 token이 decoder로 들어가는 원본 구조도.</figcaption>
</figure>

왼쪽 encoder는 입력 문장을 encoded embedding으로 만들고, 오른쪽 decoder는 `[BOS]`에서 출력을 시작합니다. Decoder의 self-attention은 이미 생성된 위치만 보고, encoder 정보는 cross-attention을 통해 참조합니다.

Transformer encoder는 입력 전체를 양방향으로 보며 representation을 만듭니다. Decoder는 autoregressive generation을 위해 미래 token을 보지 못하도록 mask를 사용합니다.

| 구조 | Attention | 사용 예 |
|---|---|---|
| Encoder | bidirectional self-attention | 분류, 검색, 이해 |
| Decoder | masked self-attention | next-token generation |
| Encoder-Decoder | encoder self-attention + decoder cross-attention | 번역, 요약 |

Decoder의 mask는 현재 위치에서 미래 정답을 미리 보는 정보 누수를 막습니다.

## 9. 전체 흐름 예시

Transformer 한 block의 흐름은 다음처럼 정리할 수 있습니다.

```text
tokens
-> embeddings + positions
-> multi-head self-attention
-> residual + normalization
-> feed-forward network
-> residual + normalization
-> next block or output head
```

이 구조가 반복되면서 모델은 token의 local meaning과 global context를 함께 반영한 representation을 만듭니다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| positional encoding이 필요한 이유는 무엇입니까? | self-attention만으로는 순서 정보를 알기 어렵기 때문 |
| Q, K, V의 역할은 무엇입니까? | query는 찾는 정보, key는 비교 기준, value는 가져올 내용 |
| scaling을 하는 이유는 무엇입니까? | softmax가 과도하게 날카로워지는 것을 막기 위해 |
| multi-head attention의 장점은 무엇입니까? | 여러 관계를 서로 다른 subspace에서 병렬로 학습 |
| decoder mask의 목적은 무엇입니까? | 미래 token을 보는 정보 누수를 막기 위해 |

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

짧은 token 행렬을 놓고 QKᵀ 계산, √d_k scaling, softmax, V의 weighted sum을 차례로 손으로 따라갑니다. attention은 token 사이 정보를 섞고 FFN은 각 위치의 표현을 변환한다는 역할 차이, positional encoding과 causal mask가 해결하는 문제가 서로 다르다는 점을 분리해 기억합니다. block diagram에는 multi-head, residual, layer normalization까지 표시해 encoder와 decoder의 정보 흐름을 재현합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Attention을 검색 엔진에 비유하면 query, key, value는 각각 무엇입니까?</summary>

답변: query는 검색어, key는 각 문서의 색인 또는 제목, value는 실제 문서 내용에 해당합니다. query와 key의 유사도가 높을수록 해당 value를 더 많이 가져옵니다. Transformer에서는 이 과정을 token 표현 사이에서 수행합니다.

</details>

<details markdown="block">
<summary>2. Attention sublayer와 FFN sublayer는 각각 어떤 역할을 합니까?</summary>

답변: attention sublayer는 token들 사이의 관계를 계산해 문맥 정보를 섞습니다. FFN sublayer는 각 token 위치에서 독립적으로 비선형 변환을 적용해 표현력을 높입니다. 즉 attention은 token 간 상호작용, FFN은 위치별 feature 변환에 가깝습니다.

</details>

<details markdown="block">
<summary>3. Encoder-only 모델과 decoder-only 모델의 attention mask에는 어떤 차이가 있습니까?</summary>

답변: encoder-only 모델은 보통 입력 전체를 동시에 볼 수 있어 양방향 attention을 사용합니다. decoder-only 모델은 다음 token 예측을 위해 미래 token을 보면 안 되므로 causal mask를 사용합니다. 이 차이가 이해 중심 모델과 생성 중심 모델의 학습 방식 차이를 만듭니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/2_Overview_TF.pdf" | relative_url }}" target="_blank" rel="noopener">2_Overview_TF.pdf</a></li>
</ul>
