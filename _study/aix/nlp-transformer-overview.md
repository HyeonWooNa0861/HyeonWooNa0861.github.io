---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
title: "NLP and Transformer Overview"
course: "AIX"
topic: "NLP History and Transformers"
order: 4
major_topic: "Artificial Intelligence"
keywords:
  - "NLP"
  - "Word Embeddings"
  - "Seq2Seq Attention"
  - "Transformer"
  - "Transfer Learning"
---

# NLP and Transformer Overview

Source PDF: `4_NLP_Transformer.pdf`

> **핵심:** **Bag-of-Words의 한계는** 순서와 긴 문맥을 잘 반영하지 못한다. **LSTM이 RNN보다 나은 점은** gate로 장기 기억을 더 안정적으로 유지한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | NLP의 목표 | 언어를 숫자로 바꾼 뒤 어떤 문제를 푸는가? |
| 2 | Count-based model | 단어 빈도와 n-gram은 무엇을 잘하고 못하는가? |
| 3 | Word embedding | 단어를 dense vector로 표현하면 무엇이 달라지는가? |
| 4 | RNN/LSTM | 순차 정보를 hidden state로 처리하는 방식의 장단점은 무엇인가? |
| 5 | Seq2Seq와 attention | 입력 전체를 한 벡터에 압축하는 한계를 어떻게 완화했는가? |
| 6 | Transformer | recurrence 없이 attention만으로 sequence를 처리하는 이유는 무엇인가? |
| 7 | Encoder/decoder 계열 | BERT, GPT 같은 구조는 어떤 차이를 갖는가? |
| 8 | Transfer learning | 사전학습된 언어 모델을 왜 다양한 task에 재사용하는가? |

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.13-15 | tokenization과 one-hot/learned embedding | 내적·cosine 식은 p.15의 좌표 예시를 일반 표기로 옮긴 보충이다. |
| p.21-30 | recurrent state의 순차 전달 | $$h_t=f(h_{t-1},x_t)$$는 반복 도식을 요약한 상태 갱신 정의이며 원문 직접 제시식은 아니다. |
| p.35-38 | attention의 역사, $$Q,K,V$$, scaled dot-product attention | p.38의 원문 식을 query별 weight와 value 합으로 펼쳤다. |
| p.39-44 | MHA·FFN·position·encoder/decoder parameter | 구조와 차원 설명이며 별도의 증명식은 제시되지 않는다. |

특히 p.15의 유사도 숫자는 설명용 예시이므로, 본문은 이를 항상 성립하는 등식으로 취급하지 않는다.

## 1. NLP의 기본 문제

Natural Language Processing은 사람이 쓰는 언어를 컴퓨터가 처리할 수 있는 표현으로 바꾸고, 그 표현으로 분류, 생성, 검색, 번역, 요약 같은 문제를 푸는 분야다.

```text
text -> tokens -> vectors -> model -> output
```

언어는 순서와 문맥이 중요하다. 같은 단어라도 주변 단어에 따라 의미가 달라지고, 문장 전체 구조가 의도와 정보를 결정한다.

## 2. Count-based 접근과 n-gram

초기 NLP에서는 단어의 빈도와 co-occurrence를 많이 사용했다.

| 방법 | 설명 |
|---|---|
| Bag-of-Words | 문서를 단어 빈도 벡터로 표현한다. |
| TF-IDF | 자주 나오지만 문서 구분에 덜 중요한 단어의 영향은 줄인다. |
| n-gram | 연속된 `n`개의 token 패턴을 사용한다. |

이 방식은 단순하고 해석하기 쉽지만, 단어 순서와 긴 문맥을 충분히 반영하기 어렵다. 또한 vocabulary가 커지면 vector가 매우 sparse해진다.

## 3. Word Embedding

Word embedding은 단어를 dense vector로 표현한다. 비슷한 문맥에서 등장하는 단어는 비슷한 vector를 갖도록 학습된다.

```text
king, queen, man, woman -> vectors in R^d
```

Embedding의 장점은 sparse one-hot vector보다 의미적 유사성을 더 잘 반영한다는 것이다. 단어 사이의 거리와 방향이 어느 정도 의미 관계를 담을 수 있다.

| 표현 | 특징 |
|---|---|
| One-hot | 단어 간 유사성을 표현하지 못한다. |
| Count vector | 빈도 기반 정보는 담지만 sparse하다. |
| Dense embedding | 문맥 기반 의미 유사성을 담는다. |

슬라이드의 vector 내적은 embedding 유사도의 직관을 다음처럼 표현한다.

$$
\langle e_i,e_j\rangle=e_i^Te_j
$$

One-hot vector끼리는 서로 다른 token이면 직교하므로 내적이 0이다. Learned embedding은 좌표를 학습하므로 관련 단어의 내적이 커질 수 있다. 다만 슬라이드의 $$\langle\text{teddy bear},\text{soft}\rangle\approx1$$ 같은 값은 **설명용 예시**이지 항상 성립하는 정리가 아니다. Dot product는 vector 크기에도 영향을 받으므로 방향만 비교하려면 $$\frac{e_i^Te_j}{\lVert e_i\rVert_2\lVert e_j\rVert_2}$$인 cosine similarity를 사용하며, zero vector에는 정의되지 않는다. Embedding과 similarity는 모두 무차원이다.

## 4. RNN과 LSTM

RNN은 sequence를 왼쪽에서 오른쪽으로 읽으며 hidden state를 갱신한다.

$$
h_t = f(x_t, h_{t-1})
$$

이 식은 recurrent cell의 **상태 갱신 정의**다. $$t$$는 단위 없는 token step, $$x_t$$는 현재 token representation, $$h_t$$는 hidden state이며 보통 모두 무차원 vector다. 같은 함수 $$f$$와 parameter를 모든 step에서 공유하기 때문에 이전 정보가 전달된다. 하지만 backpropagation에서는 여러 step의 Jacobian이 곱해지므로 그 크기가 반복해서 1보다 작으면 gradient가 사라지고, 1보다 크면 폭발할 수 있다.

LSTM과 GRU는 gate 구조를 사용해 어떤 정보를 기억하고 버릴지 조절한다. 덕분에 단순 RNN보다 긴 의존성을 더 잘 다룰 수 있지만, 순차 처리 특성 때문에 병렬화가 어렵다.

## 5. Seq2Seq와 Attention

Seq2Seq 모델은 encoder가 입력 문장을 읽어 하나의 context vector로 압축하고, decoder가 그 vector를 바탕으로 출력 문장을 생성한다.

```text
source sentence -> encoder -> context vector -> decoder -> target sentence
```

문제는 긴 문장을 하나의 vector에 모두 넣기 어렵다는 점이다. Attention은 decoder가 매 step마다 encoder의 여러 hidden state를 직접 참고하도록 하여 이 병목을 줄인다.

| 구성 | 역할 |
|---|---|
| Query | 현재 decoder가 찾고 싶은 정보 |
| Key | encoder token이 가진 검색용 표지 |
| Value | 실제로 가져올 정보 |
| Attention weight | 어떤 token을 얼마나 참고할지 |

슬라이드의 scaled dot-product attention을 한 query 기준으로 펼치면 다음과 같다.

$$
s_{ij}=\frac{q_i^Tk_j}{\sqrt{d_k}},\qquad
\alpha_{ij}=\frac{e^{s_{ij}}}{\sum_{\ell}e^{s_{i\ell}}},\qquad
o_i=\sum_j\alpha_{ij}v_j
$$

첫 식은 query-key 유사도, 둘째 식은 합이 1인 weight의 **정의**, 셋째 식은 value weighted sum의 **정확한 등식**이다. $$q_i,k_j,v_j$$는 무차원 representation이고 $$d_k$$는 key dimension이다. 각 성분이 독립·평균 0·분산 1이라는 근사 가정에서는 $$q_i^Tk_j$$의 분산이 약 $$d_k$$이므로 $$\sqrt{d_k}$$로 나누면 score scale을 약 1로 유지한다. 실제 learned vector는 독립이 아닐 수 있으므로 이는 scaling을 설명하는 **근사적 분산 논리**다. Mask가 잘못되면 미래 token이나 padding을 참고할 수 있고, 큰 score는 softmax를 포화시켜 gradient를 약하게 만들 수 있다.

## 6. Transformer의 등장

Transformer는 recurrence를 제거하고 self-attention을 중심으로 sequence를 처리한다.

```text
tokens -> embeddings + positions -> self-attention -> feed-forward -> output
```

Self-attention은 문장 안의 각 token이 다른 모든 token을 직접 참고하게 한다. 멀리 떨어진 단어 사이의 관계도 recurrent step을 여러 번 지나지 않고 한 번의 attention 계산으로 연결할 수 있다.

| 장점 | 설명 |
|---|---|
| Long-range dependency | 멀리 떨어진 token 관계를 직접 모델링한다. |
| Parallelization | RNN보다 학습 병렬화가 쉽다. |
| Flexible context | 각 token이 필요한 문맥을 동적으로 선택한다. |

## 7. Encoder-only, Decoder-only, Encoder-Decoder

Transformer는 사용 목적에 따라 구조가 나뉜다.

| 구조 | 대표 예 | 주 용도 |
|---|---|---|
| Encoder-only | BERT 계열 | 문장 이해, 분류, retrieval, token classification |
| Decoder-only | GPT 계열 | next-token generation, 대화, 코드 생성 |
| Encoder-Decoder | T5, original Transformer | 번역, 요약, text-to-text 변환 |

Encoder-only는 입력 전체 representation을 풍부하게 만들고, decoder-only는 이전 token을 바탕으로 다음 token을 생성한다. Encoder-decoder는 source를 이해한 뒤 target sequence를 생성하는 task에 적합하다.

## 8. Transfer Learning

현대 NLP에서는 대규모 corpus로 먼저 언어 모델을 pretrain하고, 이후 특정 task에 fine-tuning하거나 prompt로 재사용한다.

| 단계 | 설명 |
|---|---|
| Pretraining | 대규모 text에서 일반 언어 지식과 패턴을 학습한다. |
| Fine-tuning | 특정 task 데이터로 모델을 조정한다. |
| Prompting | 모델 parameter를 크게 바꾸지 않고 입력 지시문으로 동작을 유도한다. |

Transfer learning은 label이 적은 task에서도 강한 성능을 가능하게 한다. 모델은 이미 문법, 의미, 세계 지식 일부를 representation에 담고 있기 때문이다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Bag-of-Words의 한계는? | 순서와 긴 문맥을 잘 반영하지 못한다. |
| LSTM이 RNN보다 나은 점은? | gate로 장기 기억을 더 안정적으로 유지한다. |
| Attention이 Seq2Seq에서 해결한 병목은? | 입력 전체를 하나의 context vector에 압축하는 문제 |
| Transformer가 병렬화에 유리한 이유는? | recurrence 없이 self-attention으로 token 관계를 계산하기 때문 |
| Encoder-only와 decoder-only의 차이는? | 이해 중심 representation vs autoregressive generation |

## Study Guide

BoW·n-gram → embedding → RNN/LSTM → Seq2Seq attention → Transformer 순서로 각 단계가 바로 앞 병목을 어떻게 줄였는지 연결한다. Seq2Seq의 context bottleneck을 푸는 attention과 recurrence 자체를 없앤 self-attention을 같은 개념으로 뭉뚱그리지 않는 것이 중요하다. 시험에서는 encoder-only, decoder-only, encoder-decoder의 문맥 가시성과 pretraining·fine-tuning·prompting의 재사용 방식을 함께 비교한다.

## 복습 질문

<details markdown="block">
<summary>1. Word embedding이 one-hot vector보다 의미 표현에 유리한 이유는 무엇인가?</summary>

답변: one-hot vector는 단어 간 거리가 모두 비슷해 의미적 유사성을 표현하지 못한다. word embedding은 단어를 연속 벡터 공간에 배치해 비슷한 문맥에서 쓰이는 단어가 가까워지도록 학습한다. 그래서 similarity, analogy, downstream task에 더 유용하다.

</details>

<details markdown="block">
<summary>2. Self-attention에서 query, key, value를 검색 과정에 비유해 설명하라.</summary>

답변: query는 현재 token이 찾고 싶은 정보, key는 각 token이 가진 검색용 색인, value는 실제로 가져올 내용에 해당한다. query와 key의 유사도를 계산해 어떤 token을 얼마나 참고할지 정하고, 그 가중치로 value들을 합쳐 현재 token의 표현을 만든다.

</details>

<details markdown="block">
<summary>3. BERT와 GPT의 task 적합성이 다른 이유를 구조 관점에서 설명하라.</summary>

답변: BERT는 encoder-only 구조로 양방향 문맥을 보므로 문장 이해, 분류, 추출형 QA에 강하다. GPT는 decoder-only 구조와 causal mask를 사용해 이전 token을 바탕으로 다음 token을 생성한다. 그래서 자연어 생성과 autoregressive completion에 적합하다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/4_NLP_Transformer.pdf" | relative_url }}" target="_blank" rel="noopener">4_NLP_Transformer.pdf</a></li>
</ul>
