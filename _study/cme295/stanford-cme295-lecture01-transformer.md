---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CME295 Lecture 1: Transformer"
course: "CME295"
topic: "From NLP Fundamentals to Transformer Architecture"
order: 1
major_topic: "Large Language Models"
keywords:
  - "Self-Attention"
  - "QKV Projections"
  - "Multi-Head Attention"
  - "Encoder-Decoder"
  - "Attention Complexity"
---

# Stanford CME295 Lecture 1: Transformer

Source: [Stanford CME295 Autumn 2025 Lecture 1](https://www.youtube.com/watch?v=Ub3GoFaUcds){:target="_blank" rel="noopener"}

**원본 영상 먼저 보기:** [01:32:40의 scaled dot-product attention 설명](https://www.youtube.com/watch?v=Ub3GoFaUcds&t=5560s){:target="_blank" rel="noopener"}에서 query–key 점수, $$\sqrt{d_k}$$ scaling, value 가중합 순서를 먼저 듣습니다. 아래 핵심 개념과 수식 해설은 이 발화의 연산 순서를 행렬 shape와 분산 계산으로 연결합니다.

<figure>
  <a href="{{ '/assets/images/study/cme295/source-captures/lecture-01-attention-01h32m40s.jpg' | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ '/assets/images/study/cme295/source-captures/lecture-01-attention-01h32m40s.jpg' | relative_url }}" alt="입력 토큰에서 Q, K, V를 만들고 scaled dot-product attention을 계산하는 강의 슬라이드" loading="lazy">
  </a>
  <figcaption><a href="https://www.youtube.com/watch?v=Ub3GoFaUcds&t=5560s" target="_blank" rel="noopener">공식 영상 01:32:40</a> — 같은 입력 표현을 서로 다른 가중치 행렬에 통과시켜 Q·K·V를 만들고, 위쪽에서 softmax(QKᵀ/√dₖ)V를 계산하는 흐름입니다.</figcaption>
</figure>

아래 토큰 행은 attention의 입력이고, 가운데 세 열은 동일한 입력에서 역할이 다른 Q·K·V를 분기하는 단계입니다. 위 식은 Q와 K로 관계 점수를 만든 뒤 V를 가중합한다는 뜻이므로, 세 벡터를 각각 독립된 정보처럼 읽으면 안 됩니다.

> **핵심:** ‘긍정 후기인가?’에 답할 때는 정해진 이름표 중 하나를 고릅니다. 반면 ‘후기를 한 문장으로 요약해 줘’에는 새 문장을 만들어야 합니다. 두 경우 모두 모델은 글을 작은 조각(토큰)으로 읽습니다. 트랜스포머는 한 조각을 해석할 때 멀리 떨어진 다른 조각도 직접 참고합니다.

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 수업 목표와 운영 | CME 295는 Transformer와 LLM의 어떤 기초와 응용을 다룹니까? |
| 2 | NLP 작업 분류 | Classification, multi-classification, generation은 입력과 출력 형태가 어떻게 다릅니까? |
| 3 | Tokenization | Word, subword, character tokenization은 OOV, sequence length, 오탈자 처리에서 어떤 trade-off를 갖습니까? |
| 4 | Embedding 학습 | One-hot representation의 한계는 무엇이고 Word2vec proxy task는 무엇을 학습하려고 합니까? |
| 5 | RNN과 LSTM | Sequential hidden state는 문장 표현에 어떤 도움을 주고, 왜 long-range dependency 문제가 생깁니까? |
| 6 | Self-attention | Query, key, value를 사용해 한 토큰을 다른 토큰들의 weighted sum으로 표현하는 과정은 무엇입니까? |
| 7 | Transformer encoder-decoder | Encoder self-attention, decoder masked self-attention, cross-attention은 각각 어떤 정보를 연결합니까? |

</details>
## 핵심 내용

LLM을 이해하려면 먼저 NLP 작업의 입력과 출력을 구분해야 합니다. 텍스트에서 하나의 라벨을 예측하는 classification, 여러 토큰이나 엔티티를 예측하는 multi-classification, 텍스트를 생성하는 generation이 기본 범주입니다. Sentiment extraction, NER, machine translation, question answering, summarization이 각각의 예로 이어집니다. 평가 지표는 accuracy, precision, recall, F1, BLEU, ROUGE, perplexity 등이 있으며, BLEU/ROUGE에는 reference text가 필요합니다. Perplexity는 실제 토큰 시퀀스에 모델이 부여한 확률을 통해 예측의 적합도를 봅니다.

처음에는 이 작업들을 “텍스트를 넣고 답을 받는 일”로 한데 묶기 쉽습니다. 그러나 영화평 한 문장에 `긍정`을 붙이는 일은 출력이 하나인 분류이고, 문장 안의 사람·장소를 각각 찾는 일은 여러 위치를 판정하는 작업이며, 번역은 길이가 정해지지 않은 새 토큰 열을 만드는 생성입니다. 출력 모양이 달라지면 학습 목표와 평가법도 달라지므로, Transformer 구조에 들어가기 전에 먼저 이 구분을 잡습니다.

모델은 글자를 그대로 읽지 못하므로, 먼저 문장을 작은 조각인 **토큰**으로 나누고 각 토큰을 숫자 벡터로 바꿉니다. 단어 전체를 한 토큰으로 쓰면 처음 보는 단어를 처리하기 어렵고, 글자 단위로 너무 잘게 나누면 입력이 길어집니다. Subword 방식은 `playing`을 `play`와 `ing`처럼 자를 수 있어 두 문제 사이를 절충합니다.

One-Hot Encoding은 토큰마다 서로 겹치지 않는 번호표를 주는 방식이라 `고양이`와 `강아지`가 비슷하다는 정보를 담지 못합니다. Word2vec은 주변 단어를 맞히는 연습을 통해 함께 쓰이는 단어의 벡터가 가까워지게 합니다. 강의의 예시 네트워크는 vocabulary 크기 $$v$$의 one-hot 입력을 더 작은 차원 $$d$$로 바꾸고, 다음 단어 예측 오차를 역전파해 이 벡터를 학습합니다. 여기서 **embedding**은 토큰의 뜻과 사용 문맥을 여러 숫자로 압축한 표현입니다.

후반부는 RNN/LSTM의 한계에서 attention과 Transformer로 이어집니다. RNN은 hidden state로 sequence so far를 유지해 word order를 반영하지만 long-range dependency, vanishing gradient, sequential computation 때문에 긴 문맥과 학습 속도에서 문제가 생깁니다. Attention은 예측하려는 출력과 입력의 관련 부분을 직접 연결하는 방식이고, Transformer는 2017년 Attention is All You Need 논문에서 self-attention을 중심으로 제안되었습니다. Query, key, value는 학습되는 projection으로 만들어지며, scaled dot-product attention은 softmax(QK^T / sqrt(d_k))V로 표현됩니다. Transformer는 encoder와 decoder로 구성되고, encoder self-attention은 입력 토큰들이 서로를 보게 하며, decoder의 masked self-attention은 지금까지 생성된 토큰만 보게 하고, cross-attention은 decoder query가 encoder의 key/value를 참조하게 합니다. Position encoding, multi-head attention, FFN, BOS/EOS token, label smoothing도 함께 소개됩니다.

Query, key, value는 이름보다 역할로 읽으면 쉽습니다. 현재 토큰의 query는 “지금 어떤 정보가 필요한가”를 나타내고, 각 토큰의 key는 그 질문과 비교할 표지, value는 선택되었을 때 실제로 가져올 내용입니다. Query와 key가 잘 맞는 토큰에 큰 가중치를 준 뒤 value를 섞기 때문에, 한 단어의 표현이 문장 속 관련 단어를 반영한 표현으로 바뀝니다. 이 직접 연결이 RNN처럼 앞 토큰을 차례로 거치지 않고도 먼 문맥을 참조하게 하는 핵심입니다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Tokenization | 텍스트를 모델이 처리할 수 있는 token 단위로 자르는 과정입니다. 강의에서는 word-level, subword-level, character-level 방식의 장단점을 비교했습니다. |
| Out Of Vocabulary (OOV) | Inference time에 training set에서 보지 못한 token이 나오는 문제입니다. Word-level tokenizer에서 더 자주 발생하고, subword-level은 이를 완화합니다. |
| One-Hot Encoding (OHE) | Vocabulary의 각 token을 하나의 1과 나머지 0으로 표현하는 방식입니다. 모든 vector가 서로 직교해 의미적 유사도를 담기 어렵습니다. |
| Word2vec | 2013년경 소개된 embedding 학습 방식으로, CBOW와 Skip-gram 같은 proxy task를 통해 의미 있는 word representation을 얻습니다. |
| Recurrent Neural Network (RNN) | Token을 순서대로 처리하며 hidden state에 sequence so far를 담는 모델입니다. Word order를 반영하지만 긴 의존성 처리와 학습 속도에 한계가 있습니다. |
| Long Short-Term Memory (LSTM) | RNN의 확장으로 hidden state 외에 cell state를 사용해 중요한 정보를 더 잘 유지하려는 구조입니다. |
| Self-attention | 각 token representation을 같은 sequence 안의 다른 token들과 직접 연결해 context-aware representation으로 만드는 mechanism입니다. |
| Query, Key, Value | Attention에서 query는 어떤 token이 관련 있는지 묻고, key는 similarity 비교 대상이며, value는 weighted sum에 실제로 사용되는 vector입니다. |
| Scaled dot-product attention | 강의 공식은 softmax(QK^T / sqrt(d_k))V입니다. Q와 K의 dot product를 sqrt(d_k)로 나누어 scale을 조정한 뒤 value를 weighted sum합니다. |
| Label smoothing | 정답 label을 완전한 one-hot으로 두지 않고 1 - epsilon과 epsilon/(v - 1) 형태로 부드럽게 만들어 모델이 과도하게 확신하지 않도록 하는 기법입니다. |

## 수식 해설: scaled dot-product attention

Attention은 각 query가 key와 얼마나 관련 있는지 점수화하고, 그 점수를 확률 가중치로 바꿔 value를 합칩니다. 핵심 정의는 $$\operatorname{softmax}(QK^\top/\sqrt{d_k})V$$이며, $$\sqrt{d_k}$$는 차원이 커질 때 dot-product score가 지나치게 커지는 현상을 완화합니다.

<details markdown="block">
<summary markdown="span">Derivation: Attention scaling, label smoothing, and perplexity</summary>

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Perplexity의 확률 기반 의미 | 00:20:43–00:21:06 | 강의 원문은 metric의 의미와 방향을 설명하며, 아래 NLL 등가식은 작성자 보충 유도입니다. |
| Label smoothing target | 01:25:45–01:27:26 | $$1-\varepsilon$$와 $$\varepsilon/(v-1)$$은 강의 원문에 나옵니다. 합·조건·한계 설명은 작성자 보충입니다. |
| Scaled dot-product attention과 $$\sqrt{d_k}$$ | 01:32:24–01:34:26 | 공식과 정규화 직관은 강의 원문이며, 독립·단위분산 가정의 계산은 작성자 보충 유도입니다. |

Token 수를 $$n$$, key/query 차원을 $$d_k$$, value 차원을 $$d_v$$라 하면

$$
Q,K\in\mathbb{R}^{n\times d_k},\qquad
V\in\mathbb{R}^{n\times d_v},
$$

$$
\operatorname{Attention}(Q,K,V)
=\operatorname{softmax}\!\left(\frac{QK^\top}{\sqrt{d_k}}\right)V.
$$

이는 attention의 **정의**입니다. Softmax는 각 query 행의 score $$s_j$$에 대해 $$\alpha_j=e^{s_j}/\sum_\ell e^{s_\ell}$$를 계산하므로 $$\alpha_j\ge0$$, $$\sum_j\alpha_j=1$$이고 출력은 value의 convex combination입니다. 모든 기호는 representation이므로 물리 단위는 없으며 $$n,d_k,d_v$$는 무차원 개수입니다.

왜 $$\sqrt{d_k}$$로 나누는지는 분산으로 확인할 수 있습니다. 한 query와 key의 성분이 서로 독립이고 평균 0, 분산 1이라고 가정하면

$$
q^\top k=\sum_{r=1}^{d_k}q_rk_r,\qquad
\operatorname{Var}(q^\top k)
=\sum_{r=1}^{d_k}\operatorname{Var}(q_rk_r)=d_k.
$$

따라서 $$q^\top k/\sqrt{d_k}$$의 분산은 1이 됩니다. 이는 독립·단위분산 가정 아래의 **정확한 분산 계산**이며, 학습된 성분이 실제로 독립이라는 보장은 아닙니다. Scale이 없고 score magnitude가 커지면 softmax가 포화되어 gradient가 작아질 수 있다는 것이 설계 직관입니다.

Label smoothing의 $$1-\varepsilon$$, $$\varepsilon/(v-1)$$은 합이 1이 되도록 만든 target distribution의 정의입니다. $$0\le\varepsilon\le1$$, vocabulary size $$v>1$$이 필요하며, smoothing이 calibration을 항상 개선한다는 주장은 데이터·모델에 의존하는 경험적 효과이지 이 식만으로 증명되지 않습니다.

Token sequence의 평균 negative log-likelihood가 $$\overline{\mathcal L}=-(1/T)\sum_{t=1}^{T}\log p(x_t\mid x_{<t})$$이면 perplexity는

$$
PPL=e^{\overline{\mathcal L}}
=\left(\prod_{t=1}^{T}\frac{1}{p(x_t\mid x_{<t})}\right)^{1/T}
$$

입니다. 두 번째 등식은 $$\exp(\sum\log a_t/T)=(\prod a_t)^{1/T}$$에서 나옵니다. 이는 동일 tokenizer와 evaluation tokenization에서의 정확한 metric 정의입니다. Tokenizer와 data distribution이 다르면 perplexity를 직접 비교하기 어렵고, 낮은 perplexity가 factuality나 usefulness를 보장하지 않습니다.

</details>

## 학습 포인트

- NLP 작업은 강의에서 classification, multi-classification, generation 세 범주로 정리됩니다.
- BLEU와 ROUGE는 reference 기반 지표이고, perplexity는 모델 출력 확률 기반으로 낮을수록 좋다고 설명됩니다.
- Subword tokenization은 어근을 활용하고 OOV 위험을 낮추지만 sequence length를 늘립니다.
- One-hot encoding은 토큰 간 의미 유사도를 표현하기 어렵기 때문에 learned embedding이 필요합니다.
- Word2vec은 CBOW와 Skip-gram 같은 proxy task로 단어 표현을 학습합니다.
- RNN은 순서를 반영하지만 긴 문맥에서 vanishing gradient와 느린 sequential computation 문제가 있습니다.
- Scaled dot-product attention 공식은 softmax(QK^T / sqrt(d_k))V이며, Q/K/V projection은 학습됩니다.
- Transformer decoder의 masked self-attention은 아직 생성되지 않은 미래 토큰을 보지 않도록 제한합니다.

## 마지막 핵심 정리

이 강의의 핵심은 `NLP 기초에서 Transformer 구조까지`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것입니다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

1. 세 NLP 작업 범주를 입력/출력 형태와 예시 작업으로 구분해 암기합니다.
2. Tokenizer 선택이 OOV, sequence length, inference cost에 어떤 영향을 주는지 비교합니다.
3. One-hot vector가 왜 cosine similarity 관점에서 의미 표현에 부적합한지 설명해 봅니다.
4. RNN/LSTM이 해결하려는 문제와 attention이 등장한 이유를 long-range dependency 관점에서 연결합니다.
5. softmax(QK^T / sqrt(d_k))V의 각 행렬이 무엇을 의미하는지 말로 풀어 씁니다.
6. Encoder self-attention, decoder masked self-attention, cross-attention을 machine translation 예시로 구분합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. 왜 word-level tokenization은 OOV 문제가 크고, subword tokenization은 이를 완화합니까?</summary>

답변: Word-level은 training time에 본 단어 전체가 vocabulary에 있어야 하므로 unseen word가 unknown token이 되기 쉽습니다. Subword는 bear/bears처럼 공통 어근이나 조각을 공유해 unseen word도 더 작은 단위로 표현할 가능성이 높습니다.

</details>

<details markdown="block">
<summary>2. One-hot encoding이 의미 유사도를 표현하기 어려운 이유는 무엇입니까?</summary>

답변: 서로 다른 token의 one-hot vector는 대부분 직교하므로 dot product나 cosine similarity가 의미적 가까움을 반영하지 않습니다. Teddy bear와 soft처럼 관련 있는 단어도 기본적으로 독립적인 축으로 표현됩니다.

</details>

<details markdown="block">
<summary>3. RNN이 긴 sequence에서 어려움을 겪는 주된 이유는 무엇입니까?</summary>

답변: 마지막 예측을 위해 이전 hidden state들이 순차적으로 연결되고, backpropagation through time에서 많은 항을 곱하면서 gradient가 0에 가까워지거나 폭주할 수 있습니다. 이로 인해 long-range dependency를 기억하기 어렵고 계산도 느립니다.

</details>

<details markdown="block">
<summary>4. Self-attention에서 query, key, value는 각각 어떤 역할을 합니까?</summary>

답변: Query는 현재 token이 어떤 다른 token과 관련 있는지 묻는 vector이고, key는 similarity 비교 대상이며, value는 similarity weight를 적용해 실제로 합산되는 vector입니다.

</details>

<details markdown="block">
<summary>5. Transformer decoder에서 masked self-attention이 필요한 이유는 무엇입니까?</summary>

답변: Decoder는 아직 생성되지 않은 미래 token을 알 수 없으므로, 현재 token은 자기 자신과 이전에 생성된 token까지만 attend해야 합니다. Mask는 미래 방향의 attention을 막습니다.

</details>

## 참고자료

- 자료 확인 범위: 공식 Stanford CME295 강의 영상과 영문 전사를 대조했습니다. 공식 슬라이드는 없어 화면에 보이지 않는 내용은 추정하지 않았습니다.

- [강의 영상](https://www.youtube.com/watch?v=Ub3GoFaUcds){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
