---
layout: default
title: "Stanford CME295 Lecture 1: Transformer"
course: "CME295"
topic: "From NLP Fundamentals to Transformer Architecture"
order: 1
---

# Stanford CME295 Lecture 1: Transformer

Source: [Stanford CME295 Autumn 2025 Lecture 1](https://www.youtube.com/watch?v=Ub3GoFaUcds){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 수업 목표와 운영 | CME 295는 Transformer와 LLM의 어떤 기초와 응용을 다루는가? |
| 2 | NLP 작업 분류 | Classification, multi-classification, generation은 입력과 출력 형태가 어떻게 다른가? |
| 3 | Tokenization | Word, subword, character tokenization은 OOV, sequence length, 오탈자 처리에서 어떤 trade-off를 갖는가? |
| 4 | Embedding 학습 | One-hot representation의 한계는 무엇이고 Word2vec proxy task는 무엇을 학습하려는가? |
| 5 | RNN과 LSTM | Sequential hidden state는 문장 표현에 어떤 도움을 주고, 왜 long-range dependency 문제가 생기는가? |
| 6 | Self-attention | Query, key, value를 사용해 한 토큰을 다른 토큰들의 weighted sum으로 표현하는 과정은 무엇인가? |
| 7 | Transformer encoder-decoder | Encoder self-attention, decoder masked self-attention, cross-attention은 각각 어떤 정보를 연결하는가? |

## 핵심 내용

첫 강의는 CME 295의 목표와 운영 방식을 소개한 뒤, LLM을 이해하기 위한 기본 NLP 문제들을 분류한다. 텍스트 입력에서 하나의 라벨을 예측하는 classification, 여러 토큰이나 엔티티를 예측하는 multi-classification, 텍스트를 입력받아 텍스트를 생성하는 generation을 구분하고, sentiment extraction, NER, machine translation, question answering, summarization 같은 예를 든다. 평가 지표로는 accuracy, precision, recall, F1, BLEU, ROUGE, perplexity를 소개하며, 특히 BLEU/ROUGE는 reference text가 필요하고 perplexity는 모델 출력 확률에서 모델이 얼마나 놀라는지를 본다고 설명한다.

그 다음 텍스트를 모델 입력으로 만들기 위한 tokenization과 representation을 다룬다. word-level, subword-level, character-level tokenizer의 장단점을 비교하며, word-level은 Out Of Vocabulary 위험이 크고 subword는 어근을 활용하지만 sequence length가 길어지며, character-level은 오탈자에 강하지만 sequence가 매우 길어진다고 설명한다. One-Hot Encoding은 모든 토큰 벡터가 서로 직교하므로 의미적 유사도를 담기 어렵고, Word2vec은 Continuous Bag of Words와 Skip-gram 같은 proxy task를 통해 의미 있는 embedding을 학습한다. 예시 네트워크에서는 vocabulary size v의 one-hot input을 더 작은 hidden dimension d로 투영하고, cross-entropy loss와 backpropagation으로 다음 단어 예측을 학습한 뒤 hidden representation을 word representation으로 사용한다.

후반부는 RNN/LSTM의 한계에서 attention과 Transformer로 이어진다. RNN은 hidden state로 sequence so far를 유지해 word order를 반영하지만 long-range dependency, vanishing gradient, sequential computation 때문에 긴 문맥과 학습 속도에서 문제가 생긴다. Attention은 예측하려는 출력과 입력의 관련 부분을 직접 연결하는 방식이고, Transformer는 2017년 Attention is All You Need 논문에서 self-attention을 중심으로 제안되었다. Query, key, value는 학습되는 projection으로 만들어지며, scaled dot-product attention은 softmax(QK^T / sqrt(d_k))V로 표현된다. Transformer는 encoder와 decoder로 구성되고, encoder self-attention은 입력 토큰들이 서로를 보게 하며, decoder의 masked self-attention은 지금까지 생성된 토큰만 보게 하고, cross-attention은 decoder query가 encoder의 key/value를 참조하게 한다. Position encoding, multi-head attention, FFN, BOS/EOS token, label smoothing도 함께 소개된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Tokenization | 텍스트를 모델이 처리할 수 있는 token 단위로 자르는 과정이다. 강의에서는 word-level, subword-level, character-level 방식의 장단점을 비교했다. |
| Out Of Vocabulary (OOV) | Inference time에 training set에서 보지 못한 token이 나오는 문제다. Word-level tokenizer에서 더 자주 발생하고, subword-level은 이를 완화한다. |
| One-Hot Encoding (OHE) | Vocabulary의 각 token을 하나의 1과 나머지 0으로 표현하는 방식이다. 모든 vector가 서로 직교해 의미적 유사도를 담기 어렵다. |
| Word2vec | 2013년경 소개된 embedding 학습 방식으로, CBOW와 Skip-gram 같은 proxy task를 통해 의미 있는 word representation을 얻는다. |
| Recurrent Neural Network (RNN) | Token을 순서대로 처리하며 hidden state에 sequence so far를 담는 모델이다. Word order를 반영하지만 긴 의존성 처리와 학습 속도에 한계가 있다. |
| Long Short-Term Memory (LSTM) | RNN의 확장으로 hidden state 외에 cell state를 사용해 중요한 정보를 더 잘 유지하려는 구조다. |
| Self-attention | 각 token representation을 같은 sequence 안의 다른 token들과 직접 연결해 context-aware representation으로 만드는 mechanism이다. |
| Query, Key, Value | Attention에서 query는 어떤 token이 관련 있는지 묻고, key는 similarity 비교 대상이며, value는 weighted sum에 실제로 사용되는 vector다. |
| Scaled dot-product attention | 강의 공식은 softmax(QK^T / sqrt(d_k))V이다. Q와 K의 dot product를 sqrt(d_k)로 나누어 scale을 조정한 뒤 value를 weighted sum한다. |
| Label smoothing | 정답 label을 완전한 one-hot으로 두지 않고 1 - epsilon과 epsilon/(v - 1) 형태로 부드럽게 만들어 모델이 과도하게 확신하지 않도록 하는 기법이다. |

## 학습 포인트

- NLP 작업은 강의에서 classification, multi-classification, generation 세 범주로 정리된다.
- BLEU와 ROUGE는 reference 기반 지표이고, perplexity는 모델 출력 확률 기반으로 낮을수록 좋다고 설명된다.
- Subword tokenization은 어근을 활용하고 OOV 위험을 낮추지만 sequence length를 늘린다.
- One-hot encoding은 토큰 간 의미 유사도를 표현하기 어렵기 때문에 learned embedding이 필요하다.
- Word2vec은 CBOW와 Skip-gram 같은 proxy task로 단어 표현을 학습한다.
- RNN은 순서를 반영하지만 긴 문맥에서 vanishing gradient와 느린 sequential computation 문제가 있다.
- Scaled dot-product attention 공식은 softmax(QK^T / sqrt(d_k))V이며, Q/K/V projection은 학습된다.
- Transformer decoder의 masked self-attention은 아직 생성되지 않은 미래 토큰을 보지 않도록 제한한다.

## 마지막 핵심 정리

이 강의의 핵심은 `NLP 기초에서 Transformer 구조까지`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. 세 NLP 작업 범주를 입력/출력 형태와 예시 작업으로 구분해 암기한다.
2. Tokenizer 선택이 OOV, sequence length, inference cost에 어떤 영향을 주는지 비교한다.
3. One-hot vector가 왜 cosine similarity 관점에서 의미 표현에 부적합한지 설명해 본다.
4. RNN/LSTM이 해결하려는 문제와 attention이 등장한 이유를 long-range dependency 관점에서 연결한다.
5. softmax(QK^T / sqrt(d_k))V의 각 행렬이 무엇을 의미하는지 말로 풀어 쓴다.
6. Encoder self-attention, decoder masked self-attention, cross-attention을 machine translation 예시로 구분한다.

## 복습 질문

<details>
<summary>1. 왜 word-level tokenization은 OOV 문제가 크고, subword tokenization은 이를 완화하는가?</summary>

답변: Word-level은 training time에 본 단어 전체가 vocabulary에 있어야 하므로 unseen word가 unknown token이 되기 쉽다. Subword는 bear/bears처럼 공통 어근이나 조각을 공유해 unseen word도 더 작은 단위로 표현할 가능성이 높다.

</details>

<details>
<summary>2. One-hot encoding이 의미 유사도를 표현하기 어려운 이유는 무엇인가?</summary>

답변: 서로 다른 token의 one-hot vector는 대부분 직교하므로 dot product나 cosine similarity가 의미적 가까움을 반영하지 않는다. Teddy bear와 soft처럼 관련 있는 단어도 기본적으로 독립적인 축으로 표현된다.

</details>

<details>
<summary>3. RNN이 긴 sequence에서 어려움을 겪는 주된 이유는 무엇인가?</summary>

답변: 마지막 예측을 위해 이전 hidden state들이 순차적으로 연결되고, backpropagation through time에서 많은 항을 곱하면서 gradient가 0에 가까워지거나 폭주할 수 있다. 이로 인해 long-range dependency를 기억하기 어렵고 계산도 느리다.

</details>

<details>
<summary>4. Self-attention에서 query, key, value는 각각 어떤 역할을 하는가?</summary>

답변: Query는 현재 token이 어떤 다른 token과 관련 있는지 묻는 vector이고, key는 similarity 비교 대상이며, value는 similarity weight를 적용해 실제로 합산되는 vector다.

</details>

<details>
<summary>5. Transformer decoder에서 masked self-attention이 필요한 이유는 무엇인가?</summary>

답변: Decoder는 아직 생성되지 않은 미래 token을 알 수 없으므로, 현재 token은 자기 자신과 이전에 생성된 token까지만 attend해야 한다. Mask는 미래 방향의 attention을 막는다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=Ub3GoFaUcds){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
