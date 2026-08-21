---
layout: default
date: 2026-08-12 10:07:20 +0900
title: "Stanford CME295 Lecture 2: Transformer-Based Models & Tricks"
course: "CME295"
topic: "Transformer Variants, Positional Information, Attention Optimization, and BERT Models"
order: 2
major_topic: "Large Language Models"
keywords:
  - "RoPE"
  - "RMSNorm"
  - "GQA"
  - "BERT"
  - "Position Embeddings"
---

# Stanford CME295 Lecture 2: Transformer-Based Models & Tricks

Source: [Stanford CME295 Autumn 2025 Lecture 2](https://www.youtube.com/watch?v=yT84Y5zCnaA){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Attention map과 multi-head | 각 head는 Q/K/V projection을 어떻게 다르게 학습하고 attention map으로 무엇을 해석할 수 있는가? |
| 2 | Position embedding | Learned position embedding과 sinusoidal position embedding은 어떤 장단점을 갖는가? |
| 3 | Relative position methods | T5 relative position bias, ALiBi, RoPE는 위치 정보를 attention 계산에 어떻게 넣는가? |
| 4 | Normalization 변화 | Post-norm에서 pre-norm으로, LayerNorm에서 RMSNorm으로 바뀐 이유는 무엇인가? |
| 5 | Attention efficiency | Sliding window attention, MQA, GQA는 O(n^2) 계산량 또는 KV cache 메모리를 어떻게 줄이는가? |
| 6 | Transformer model families | Encoder-decoder, encoder-only, decoder-only 모델은 어떤 task와 objective에 대응하는가? |
| 7 | BERT training | BERT의 MLM, NSP, CLS/SEP/segment embedding은 classification representation을 어떻게 학습시키는가? |
| 8 | BERT variants | DistilBERT와 RoBERTa는 BERT의 어떤 비용 또는 objective 문제를 바꾸려 했는가? |

## 핵심 내용

두 번째 강의는 Lecture 1의 self-attention과 Transformer 구조를 복습한 뒤, 원래 Transformer에서 변형되어 온 핵심 구성요소를 다룬다. 먼저 position embedding을 설명한다. Self-attention은 모든 token을 직접 연결하므로 RNN처럼 순서가 자연스럽게 들어오지 않는다. 원 논문은 position별 embedding을 input token embedding에 더하는 방식을 사용했고, learned embedding과 sinusoidal embedding을 모두 시험했다. Sinusoidal 방식은 omega_i = 10000^{-2i/d_model} 형태의 frequency를 사용해 sine/cosine 값을 만들며, position m과 n의 dot product가 relative distance에 의존하도록 한다. 이후 T5의 relative position bias, ALiBi의 deterministic linear bias, RoPE(Rotary Position Embeddings)가 소개된다. RoPE는 query와 key를 position에 따른 각도로 회전시켜 QK^T 안에서 relative distance가 직접 반영되게 하며, 현대 모델에서 많이 쓰인다고 설명한다.

다음으로 normalization과 attention 변형을 다룬다. 원 Transformer의 add and norm은 post-norm 형태였지만 현대 모델은 sublayer 앞에서 normalization을 수행하는 pre-norm을 주로 사용한다고 설명한다. 또한 LayerNorm은 mean/std와 gamma, beta를 쓰지만, RMSNorm은 root mean square로 x를 normalize하고 gamma만 학습해 비슷한 convergence 특성을 더 적은 parameter로 얻는다고 한다. Attention은 sequence length n에 대해 O(n^2) complexity를 갖기 때문에 LongFormer와 sliding window attention처럼 local attention을 쓰거나, 일부 layer에서 local/global attention을 섞는 방식이 소개된다. Mistral은 sliding window attention 예시로 나오며, KV cache 메모리를 줄이기 위해 key/value projection을 head 사이에 공유하는 MQA와 GQA도 설명된다. MQA는 모든 head가 같은 K/V projection을 공유하고, GQA는 group 단위로 K/V를 공유한다.

후반부는 Transformer 기반 모델 계열을 세 갈래로 정리한다. Encoder-decoder 계열에는 T5가 있으며, T5는 Transfer Text-to-Text Transformer의 약자로 mT5, ByT5 같은 변형과 span corruption objective, sentinel token, teacher forcing을 사용한다. Encoder-only 계열에서는 BERT를 깊게 다룬다. BERT는 Bidirectional Encoder Representations from Transformers이고, decoder를 제거한 encoder-only 구조로 모든 token이 양방향으로 attend할 수 있어 classification에 적합하다. CLS token은 전체 입력의 bidirectional 정보를 담는 placeholder로 classification head에 연결되고, SEP token은 두 문장을 구분한다. Pre-training은 MLM(Masked Language Model)과 NSP(Next Sentence Prediction)로 구성되며, MLM은 선택 token의 80%를 [MASK]로 바꾸고 10%는 그대로 두며 10%는 random word로 바꾼다. Fine-tuning에서는 CLS token 또는 token-level embedding 위에 linear layer를 붙인다. 마지막에는 BERT base가 약 110M parameter와 512 context length 한계를 갖는다고 언급하고, DistilBERT는 distillation과 layer 수 감소로 더 작고 빠르게 만들며, RoBERTa는 NSP를 제거하고 dynamic masking과 더 크고 다양한 data strategy를 사용했다고 설명한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Attention map | 특정 query token이 다른 key token들과 갖는 attention weight를 시각화한 것이다. 강의에서는 its가 law, application과 강하게 연결되는 예를 들었다. |
| Sinusoidal position embedding | Position m과 dimension i에 대해 sine/cosine 값을 계산해 position embedding을 만드는 방식이다. 강의에서는 omega_i = 10000^{-2i/d_model} 형태를 소개했다. |
| Relative position bias | Attention softmax 내부에 position 차이에 따른 bias를 더하는 방식이다. T5는 m - n 거리를 bucketize하고 bias term을 학습한다고 설명됐다. |
| ALiBi | Attention with Linear Bias로 소개되며, learned bias 대신 relative distance에 대한 deterministic formula를 attention에 넣는 방법이다. |
| RoPE | Rotary Position Embeddings의 약자다. Query와 key vector를 position에 따른 angle로 회전시켜 QK^T가 relative distance에 의존하게 한다. |
| RMSNorm | Root Mean Square Normalization이다. LayerNorm과 달리 mean subtraction과 beta 없이 root mean square로 normalize하고 gamma만 학습한다. |
| Sliding window attention | 각 token이 전체 sequence가 아니라 주변 window의 token에만 attend하도록 제한하는 local attention 방식이다. |
| Grouped Query Attention (GQA) | Query projection은 head별로 유지하되 key/value projection을 group 단위로 공유하는 방식이다. KV cache memory 절약과 관련해 설명됐다. |
| Span corruption | T5의 training objective다. 입력 문장의 일부 span을 sentinel token으로 대체하고 decoder가 빠진 span들을 순서대로 복원한다. |
| Masked Language Model (MLM) | BERT pre-training objective다. 선택된 token을 80%는 [MASK], 10%는 그대로, 10%는 random word로 처리하고 원래 token을 예측하게 한다. |

## 학습 포인트

- Position information은 Transformer에서 별도로 주입되어야 하며, learned embedding은 training set의 max position에 제한된다.
- Sinusoidal position embedding은 sine/cosine을 사용해 position dot product가 relative distance의 함수가 되도록 설계된다.
- RoPE는 query와 key를 position-dependent angle로 회전시켜 attention formula 안에 relative distance를 직접 반영한다.
- 현대 모델은 원 Transformer의 post-norm보다 pre-norm을 많이 쓰고, LayerNorm 대신 RMSNorm을 쓰기도 한다.
- Self-attention은 sequence length n에 대해 O(n^2)이므로 sliding window/local attention 같은 근사가 사용된다.
- MQA와 GQA는 key/value projection을 head 사이에 공유해 KV cache memory를 줄이는 attention 변형이다.
- T5는 encoder-decoder 구조와 span corruption, sentinel token을 사용한다.
- BERT는 encoder-only 구조이며 MLM과 NSP pre-training 후 CLS token 또는 token-level embedding 위에서 fine-tuning된다.

## 마지막 핵심 정리

이 강의의 핵심은 `Transformer 변형, 위치 정보, attention 최적화, BERT 계열`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. Position embedding 방법들을 input에 더하는 방식과 attention 내부에 넣는 방식으로 나눠 비교한다.
2. RoPE가 왜 query/key 회전과 relative distance를 연결하는지 QK^T 관점에서 설명한다.
3. LayerNorm, RMSNorm, pre-norm, post-norm의 차이를 식의 위치와 학습 parameter 관점에서 정리한다.
4. Sliding window attention, MQA, GQA가 각각 계산량 또는 메모리의 어느 부분을 줄이는지 구분한다.
5. T5, BERT, GPT-style decoder-only 모델을 encoder-decoder, encoder-only, decoder-only로 분류한다.
6. BERT의 MLM/NSP, WordPiece, CLS/SEP/PAD, segment embedding, fine-tuning 절차를 순서대로 복습한다.

## 복습 질문

<details>
<summary>1. Learned position embedding의 한계는 무엇인가?</summary>

답변: Training set에서 본 최대 position까지만 embedding을 학습할 수 있고, training data의 position bias를 embedding이 그대로 학습할 수 있다. 더 긴 sequence의 position은 직접 학습되지 않는다.

</details>

<details>
<summary>2. RoPE가 attention 계산에 위치 정보를 넣는 방식은 무엇인가?</summary>

답변: Query와 key vector를 각각 자신의 position에 따른 angle로 회전한다. 그 결과 QK^T의 값이 두 position의 relative distance에 의존하게 되어 attention layer 안에서 위치 정보가 직접 반영된다.

</details>

<details>
<summary>3. RMSNorm은 LayerNorm과 무엇이 다른가?</summary>

답변: LayerNorm은 activation에서 mean을 빼고 standard deviation으로 나눈 뒤 gamma와 beta를 학습한다. RMSNorm은 root mean square로 normalize하고 gamma만 학습해 더 적은 parameter로 비슷한 convergence 특성을 노린다.

</details>

<details>
<summary>4. GQA와 MQA는 왜 KV cache와 관련이 있는가?</summary>

답변: Decoding 때 이전 token들의 key/value를 계속 재사용해야 하므로 KV cache가 커진다. GQA와 MQA는 key/value projection을 여러 head 사이에서 공유해 저장해야 할 key/value 수를 줄인다.

</details>

<details>
<summary>5. BERT의 CLS token은 fine-tuning에서 어떻게 사용되는가?</summary>

답변: CLS token은 sequence 맨 앞에 놓이고 encoder self-attention을 거친 뒤 전체 입력의 bidirectional 정보를 담는 embedding으로 사용된다. Sentiment classification 같은 sentence-level task에서는 그 embedding 위에 classification layer를 붙인다.

</details>

<details>
<summary>6. RoBERTa는 BERT와 비교해 어떤 pre-training 선택을 바꾸었는가?</summary>

답변: 강의에 따르면 RoBERTa는 NSP objective를 제거해도 성능 저하가 거의 없다는 점을 보였고, dynamic masking과 더 크고 다양한 data strategy를 추가했다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=yT84Y5zCnaA){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
