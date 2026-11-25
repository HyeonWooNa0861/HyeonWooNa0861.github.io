---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
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

> **핵심:** Bag-of-Words는 단어의 순서와 긴 문맥을 충분히 담지 못합니다. RNN은 순차 정보를 처리하지만 장기 의존성에 약할 수 있으며, LSTM은 gate를 사용해 정보를 더 오래 유지하도록 설계되었습니다.

문장을 단어 개수만으로 표현하면 `개가 사람을 물었다`와 `사람이 개를 물었다`가 비슷해 보일 수 있습니다. 자연어 처리에는 어떤 단어가 나왔는지뿐 아니라 순서와 문맥도 필요합니다. RNN은 앞에서 읽은 내용을 hidden state에 이어 전달하고, Transformer는 필요한 앞뒤 단어를 attention으로 직접 찾아 이 관계를 표현합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | NLP의 목표 | 언어를 숫자로 바꾼 뒤 어떤 문제를 풉니까? |
| 2 | Count-based model | 단어 빈도와 n-gram은 무엇을 잘하고 못합니까? |
| 3 | Word embedding | 단어를 dense vector로 표현하면 무엇이 달라집니까? |
| 4 | RNN/LSTM | 순차 정보를 hidden state로 처리하는 방식의 장단점은 무엇입니까? |
| 5 | Seq2Seq와 attention | 입력 전체를 한 벡터에 압축하는 한계를 어떻게 완화했습니까? |
| 6 | Transformer | recurrence 없이 attention만으로 sequence를 처리하는 이유는 무엇입니까? |
| 7 | Encoder/decoder 계열 | BERT, GPT 같은 구조는 어떤 차이를 갖습니까? |
| 8 | Transfer learning | 사전학습된 언어 모델을 왜 다양한 task에 재사용합니까? |

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.13-15 | tokenization과 one-hot/learned embedding | 내적·cosine 식은 p.15의 좌표 예시를 일반 표기로 옮긴 보충입니다. |
| p.21-30 | recurrent state의 순차 전달 | $$h_t=f(h_{t-1},x_t)$$는 반복 도식을 요약한 상태 갱신 정의이며 원문 직접 제시식은 아닙니다. |
| p.35-38 | attention의 역사, $$Q,K,V$$, scaled dot-product attention | p.38의 원문 식을 query별 weight와 value 합으로 펼쳤습니다. |
| p.39-44 | MHA·FFN·position·encoder/decoder parameter | 구조와 차원 설명이며 별도의 증명식은 제시되지 않습니다. |

특히 p.15의 유사도 숫자는 설명용 예시이므로, 본문은 이를 항상 성립하는 등식으로 취급하지 않습니다.

</details>

## 1. NLP의 기본 문제

자연어 처리(Natural Language Processing)는 사람이 쓰는 문장을 숫자 표현으로 바꾸고, 그 숫자로 문서 분류·문장 생성·검색·번역·요약 같은 문제를 푸는 분야입니다.

```text
text -> tokens -> vectors -> model -> output
```

언어는 순서와 문맥이 중요합니다. 같은 단어라도 주변 단어에 따라 의미가 달라지고, 문장 전체 구조가 의도와 정보를 결정합니다.

## 2. Count-based 접근과 n-gram

초기 NLP에서는 단어가 몇 번 나왔는지와 어떤 단어들이 함께 등장했는지를 많이 사용했습니다. 함께 등장하는 관계를 **동시 출현(co-occurrence)**이라고 합니다.

| 방법 | 설명 |
|---|---|
| Bag-of-Words | 문서를 단어 빈도 벡터로 표현합니다. |
| TF-IDF | 자주 나오지만 문서 구분에 덜 중요한 단어의 영향은 줄입니다. |
| n-gram | 연속된 `n`개의 token 패턴을 사용합니다. |

이 방식은 단순하고 해석하기 쉽지만, 단어 순서와 긴 문맥을 충분히 반영하기 어렵습니다. 또한 어휘 목록이 커지면 벡터 길이는 길어지는데 대부분의 값은 0인 **희소 벡터(sparse vector)**가 됩니다.

## 3. Word Embedding

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/nlp-transformer-slide-15.png" | relative_url }}" alt="AIX NLP 강의 15쪽. 서로 직교하는 one-hot token vector와 의미 관계를 거리와 방향으로 담는 learned embedding 비교." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/4_NLP_Transformer.pdf#page=15" | relative_url }}" target="_blank" rel="noopener"><code>4_NLP_Transformer.pdf</code> p.15</a> — one-hot representation과 learned embedding의 기하학적 차이를 보여주는 원본 그림.</figcaption>
</figure>

왼쪽 one-hot 공간에서는 서로 다른 token이 모두 직교해 `teddy bear–book`과 `teddy bear–soft`의 관계를 똑같이 0으로 취급합니다. 오른쪽 learned embedding은 학습된 방향과 거리에 차이를 만들어, 문맥상 가까운 token의 관계를 연속값으로 표현합니다.

Word embedding은 단어를 dense vector로 표현합니다. 비슷한 문맥에서 등장하는 단어는 비슷한 vector를 갖도록 학습됩니다.

```text
king, queen, man, woman -> vectors in R^d
```

Embedding의 장점은 sparse one-hot vector보다 의미적 유사성을 더 잘 반영한다는 것입니다. 단어 사이의 거리와 방향이 어느 정도 의미 관계를 담을 수 있습니다.

| 표현 | 특징 |
|---|---|
| One-hot | 단어 간 유사성을 표현하지 못합니다. |
| Count vector | 빈도 기반 정보는 담지만 sparse합니다. |
| Dense embedding | 문맥 기반 의미 유사성을 담습니다. |

슬라이드의 vector 내적은 embedding 유사도의 직관을 다음처럼 표현합니다.

$$
\langle e_i,e_j\rangle=e_i^Te_j
$$

One-hot vector끼리는 서로 다른 token이면 직교하므로 내적이 0입니다. Learned embedding은 좌표를 학습하므로 관련 단어의 내적이 커질 수 있습니다. 다만 슬라이드의 $$\langle\text{teddy bear},\text{soft}\rangle\approx1$$ 같은 값은 **설명용 예시**이지 항상 성립하는 정리가 아닙니다. Dot product는 vector 크기에도 영향을 받으므로 방향만 비교하려면 $$\frac{e_i^Te_j}{\lVert e_i\rVert_2\lVert e_j\rVert_2}$$인 cosine similarity를 사용하며, zero vector에는 정의되지 않습니다. Embedding과 similarity는 모두 무차원입니다.

## 4. RNN과 LSTM

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/nlp-transformer-slide-30.png" | relative_url }}" alt="AIX NLP 강의 30쪽. 이전 단어가 흐리게 남고 현재 입력 is로 다음 단어 reading을 예측하는 recurrent cell." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/4_NLP_Transformer.pdf#page=30" | relative_url }}" target="_blank" rel="noopener"><code>4_NLP_Transformer.pdf</code> p.30</a> — 이전 문맥과 현재 token을 hidden state에서 결합해 다음 token을 내는 RNN 원본 장면.</figcaption>
</figure>

그림의 흐린 앞 token들은 이전 step을 통해 hidden state에 축적된 문맥이고, 아래의 `is`는 현재 입력, 위의 `reading`은 현재 step의 출력입니다. 동일한 cell을 시간 순서대로 반복하므로 문맥을 전달할 수 있지만, step 사이 의존성 때문에 병렬 처리가 어렵습니다.

RNN은 sequence를 왼쪽에서 오른쪽으로 읽으며 hidden state를 갱신합니다.

$$
h_t = f(x_t, h_{t-1})
$$

이 식은 recurrent cell의 **상태 갱신 정의**입니다. $$t$$는 단위 없는 token step, $$x_t$$는 현재 token representation, $$h_t$$는 hidden state이며 보통 모두 무차원 vector입니다. 같은 함수 $$f$$와 parameter를 모든 step에서 공유하기 때문에 이전 정보가 전달됩니다. 하지만 backpropagation에서는 여러 step의 Jacobian이 곱해지므로 그 크기가 반복해서 1보다 작으면 gradient가 사라지고, 1보다 크면 폭발할 수 있습니다.

LSTM과 GRU는 gate 구조를 사용해 어떤 정보를 기억하고 버릴지 조절합니다. 덕분에 단순 RNN보다 긴 의존성을 더 잘 다룰 수 있지만, 순차 처리 특성 때문에 병렬화가 어렵습니다.

## 5. Seq2Seq와 Attention

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/nlp-transformer-slide-38.png" | relative_url }}" alt="AIX NLP and Transformer 강의 슬라이드 38쪽. scaled dot-product attention 식과 Q, K, V에서 시작하는 attention 및 multi-head attention 블록을 나란히 보여준다." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/4_NLP_Transformer.pdf#page=38" | relative_url }}" target="_blank" rel="noopener"><code>4_NLP_Transformer.pdf</code> p.38</a> — scaled dot-product attention과 multi-head attention을 연결한 원본 슬라이드.</figcaption>
</figure>

왼쪽 식은 $$QK^T$$로 query와 key의 관련도를 구하고, $$\sqrt{d_k}$$로 scale한 뒤 softmax weight를 value $$V$$에 적용합니다. 가운데 구조도는 아래에서 위로 `MatMul`, `Scale`, 선택적 `Mask`, `SoftMax`, `MatMul` 순서입니다. 오른쪽에서는 같은 계산을 여러 head가 서로 다른 projection에서 수행하고, 결과를 `Concat`한 뒤 `Linear` layer로 합칩니다. 따라서 attention은 token을 없애는 연산이 아니라, token 사이 관련도에 따라 value 정보를 다시 조합하는 연산입니다.

Seq2Seq 모델은 encoder가 입력 문장을 읽어 하나의 context vector로 압축하고, decoder가 그 vector를 바탕으로 출력 문장을 생성합니다.

```text
source sentence -> encoder -> context vector -> decoder -> target sentence
```

문제는 긴 문장을 하나의 vector에 모두 넣기 어렵다는 점입니다. Attention은 decoder가 매 step마다 encoder의 여러 hidden state를 직접 참고하도록 하여 이 병목을 줄입니다.

| 구성 | 역할 |
|---|---|
| Query | 현재 decoder가 찾고 싶은 정보 |
| Key | encoder token이 가진 검색용 표지 |
| Value | 실제로 가져올 정보 |
| Attention weight | 어떤 token을 얼마나 참고할지 |

슬라이드의 scaled dot-product attention을 한 query 기준으로 펼치면 다음과 같습니다.

$$
s_{ij}=\frac{q_i^Tk_j}{\sqrt{d_k}},\qquad
\alpha_{ij}=\frac{e^{s_{ij}}}{\sum_{\ell}e^{s_{i\ell}}},\qquad
o_i=\sum_j\alpha_{ij}v_j
$$

첫 식은 query-key 유사도, 둘째 식은 합이 1인 weight의 **정의**, 셋째 식은 value weighted sum의 **정확한 등식**입니다. $$q_i,k_j,v_j$$는 무차원 representation이고 $$d_k$$는 key dimension입니다. 각 성분이 독립·평균 0·분산 1이라는 근사 가정에서는 $$q_i^Tk_j$$의 분산이 약 $$d_k$$이므로 $$\sqrt{d_k}$$로 나누면 score scale을 약 1로 유지합니다. 실제 learned vector는 독립이 아닐 수 있으므로 이는 scaling을 설명하는 **근사적 분산 논리**입니다. Mask가 잘못되면 미래 token이나 padding을 참고할 수 있고, 큰 score는 softmax를 포화시켜 gradient를 약하게 만들 수 있습니다.

## 6. Transformer의 등장

Transformer는 recurrence를 제거하고 self-attention을 중심으로 sequence를 처리합니다.

```text
tokens -> embeddings + positions -> self-attention -> feed-forward -> output
```

Self-attention은 문장 안의 각 token이 다른 모든 token을 직접 참고하게 합니다. 멀리 떨어진 단어 사이의 관계도 recurrent step을 여러 번 지나지 않고 한 번의 attention 계산으로 연결할 수 있습니다.

| 장점 | 설명 |
|---|---|
| Long-range dependency | 멀리 떨어진 token 관계를 직접 모델링합니다. |
| Parallelization | RNN보다 학습 병렬화가 쉽습니다. |
| Flexible context | 각 token이 필요한 문맥을 동적으로 선택합니다. |

## 7. Encoder-only, Decoder-only, Encoder-Decoder

Transformer는 사용 목적에 따라 구조가 나뉩니다.

| 구조 | 대표 예 | 주 용도 |
|---|---|---|
| Encoder-only | BERT 계열 | 문장 이해, 분류, retrieval, token classification |
| Decoder-only | GPT 계열 | next-token generation, 대화, 코드 생성 |
| Encoder-Decoder | T5, original Transformer | 번역, 요약, text-to-text 변환 |

Encoder-only는 입력 전체 representation을 풍부하게 만들고, decoder-only는 이전 token을 바탕으로 다음 token을 생성합니다. Encoder-decoder는 source를 이해한 뒤 target sequence를 생성하는 task에 적합합니다.

## 8. Transfer Learning

현대 NLP에서는 대규모 corpus로 먼저 언어 모델을 pretrain하고, 이후 특정 task에 fine-tuning하거나 prompt로 재사용합니다.

| 단계 | 설명 |
|---|---|
| Pretraining | 대규모 text에서 일반 언어 지식과 패턴을 학습합니다. |
| Fine-tuning | 특정 task 데이터로 모델을 조정합니다. |
| Prompting | 모델 parameter를 크게 바꾸지 않고 입력 지시문으로 동작을 유도합니다. |

Transfer learning은 label이 적은 task에서도 강한 성능을 가능하게 합니다. 모델은 이미 문법, 의미, 세계 지식 일부를 representation에 담고 있기 때문입니다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Bag-of-Words의 한계는 무엇입니까? | 순서와 긴 문맥을 잘 반영하지 못합니다. |
| LSTM이 RNN보다 나은 점은 무엇입니까? | gate로 장기 기억을 더 안정적으로 유지합니다. |
| Attention이 Seq2Seq에서 해결한 병목은 무엇입니까? | 입력 전체를 하나의 context vector에 압축하는 문제 |
| Transformer가 병렬화에 유리한 이유는 무엇입니까? | recurrence 없이 self-attention으로 token 관계를 계산하기 때문 |
| Encoder-only와 decoder-only의 차이는 무엇입니까? | 이해 중심 representation vs autoregressive generation |

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

BoW·n-gram → embedding → RNN/LSTM → Seq2Seq attention → Transformer 순서로 각 단계가 바로 앞 병목을 어떻게 줄였는지 연결합니다. Seq2Seq의 context bottleneck을 푸는 attention과 recurrence 자체를 없앤 self-attention을 같은 개념으로 뭉뚱그리지 않는 것이 중요합니다. 시험에서는 encoder-only, decoder-only, encoder-decoder의 문맥 가시성과 pretraining·fine-tuning·prompting의 재사용 방식을 함께 비교합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Word embedding이 one-hot vector보다 의미 표현에 유리한 이유는 무엇입니까?</summary>

답변: one-hot vector는 단어 간 거리가 모두 비슷해 의미적 유사성을 표현하지 못합니다. word embedding은 단어를 연속 벡터 공간에 배치해 비슷한 문맥에서 쓰이는 단어가 가까워지도록 학습합니다. 그래서 similarity, analogy, downstream task에 더 유용합니다.

</details>

<details markdown="block">
<summary>2. Self-attention의 query, key, value를 검색 과정에 비유하면 각각 어떤 역할을 합니까?</summary>

답변: query는 현재 token이 찾고 싶은 정보, key는 각 token이 가진 검색용 색인, value는 실제로 가져올 내용에 해당합니다. query와 key의 유사도를 계산해 어떤 token을 얼마나 참고할지 정하고, 그 가중치로 value들을 합쳐 현재 token의 표현을 만듭니다.

</details>

<details markdown="block">
<summary>3. BERT와 GPT의 구조 차이는 task 적합성에 어떻게 영향을 줍니까?</summary>

답변: BERT는 encoder-only 구조로 양방향 문맥을 보므로 문장 이해, 분류, 추출형 QA에 강합니다. GPT는 decoder-only 구조와 causal mask를 사용해 이전 token을 바탕으로 다음 token을 생성합니다. 그래서 자연어 생성과 autoregressive completion에 적합합니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/4_NLP_Transformer.pdf" | relative_url }}" target="_blank" rel="noopener">4_NLP_Transformer.pdf</a></li>
</ul>
