---
layout: default
title: "Large Language Models"
course: "AIX"
topic: "Decoder-only LLM과 생성"
order: 6
---

# Large Language Models

Source PDF: `3_Large_Language_Models.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | LLM 정의 | 큰 언어 모델에서 "large"는 무엇이 큰 것인가? |
| 2 | Decoder-only Transformer | 왜 생성형 LLM은 decoder-only 구조를 많이 쓰는가? |
| 3 | Scaling | parameter, data, compute는 어떻게 함께 커져야 하는가? |
| 4 | Mixture of Experts | 모든 token이 모든 parameter를 쓰지 않게 하면 무엇이 좋아지는가? |
| 5 | Next-token prediction | LLM pretraining의 핵심 objective는 무엇인가? |
| 6 | Decoding | greedy, beam search, sampling은 어떻게 다른가? |
| 7 | Temperature | logit 분포를 조절하면 출력이 어떻게 달라지는가? |
| 8 | Cross-entropy | 한 token 예측 손실은 어떻게 계산되는가? |

## 1. LLM이란?

Language model은 token sequence에 확률을 부여하고 다음 token을 예측하는 모델이다. LLM은 이 모델이 대규모 parameter, 대규모 text data, 대규모 compute로 학습된 경우를 말한다.

$$
P(\mathrm{token}_t \mid \mathrm{token}_1,\ldots,\mathrm{token}_{t-1})
$$

| 요소 | 의미 |
|---|---|
| Parameter scale | 모델이 저장할 수 있는 패턴과 함수의 용량 |
| Data scale | 다양한 언어, 지식, 형식, task를 접하는 범위 |
| Compute scale | 큰 모델이 데이터를 실제로 흡수할 수 있게 하는 계산량 |

중요한 점은 세 요소가 함께 커져야 한다는 것이다. parameter만 커지고 데이터나 compute가 부족하면 성능이 제대로 나오기 어렵다.

## 2. Decoder-only Transformer

GPT 계열 LLM은 decoder-only Transformer를 사용한다. 이 구조는 이전 token만 보고 다음 token을 예측하는 autoregressive 생성에 잘 맞는다.

```text
[BOS], token_1, token_2 -> predict token_3
```

Decoder-only 모델은 masked self-attention을 사용하여 각 위치가 미래 token을 볼 수 없게 한다. 학습 objective와 inference 방식이 모두 "지금까지의 문맥으로 다음 token 예측"이라는 한 가지 인터페이스에 맞춰져 있어 확장성이 좋다.

| 구조 | 강점 |
|---|---|
| Encoder-only | 입력 이해, 분류, embedding, retrieval |
| Encoder-Decoder | source-to-target 변환, 번역, 요약 |
| Decoder-only | 열린 생성, 대화, 코드, tool call 형식 생성 |

## 3. Scaling의 의미

Scaling은 단순히 모델을 크게 만드는 것이 아니다. 모델 크기, 훈련 데이터, 계산량의 균형을 맞추는 문제다.

| Scale 축 | 너무 작을 때 문제 |
|---|---|
| Parameter | 복잡한 패턴을 담을 capacity가 부족하다. |
| Data | 모델이 다양한 분포를 학습하지 못하고 overfitting될 수 있다. |
| Compute | 충분히 학습하지 못해 parameter를 활용하지 못한다. |

좋은 LLM은 큰 capacity가 충분한 데이터와 compute를 통해 실제 성능으로 이어질 때 만들어진다.

## 4. Mixture of Experts

Dense model에서는 모든 token이 모든 feed-forward parameter를 사용한다. Mixture of Experts는 여러 expert 중 일부만 선택해 token을 처리하게 하여 전체 capacity와 token당 compute를 분리한다.

```text
token -> router -> top-k experts -> weighted output
```

| 방식 | 설명 |
|---|---|
| Dense MoE | 모든 expert 출력을 가중 평균한다. compute 절약 효과는 작다. |
| Sparse MoE | router가 top-k expert만 선택한다. scale에서 효율적이다. |

Sparse MoE는 모델 전체 parameter는 매우 크게 만들면서도, 각 token이 실제로 사용하는 parameter는 제한할 수 있다.

## 5. Routing과 Load Balancing

MoE에서 router는 token마다 어떤 expert를 쓸지 정한다. 문제는 router가 특정 expert만 계속 고르면 다른 expert가 학습되지 않고, 인기 expert는 병목이 된다는 점이다.

이를 줄이기 위해 load balancing loss를 추가한다.

| 문제 | 결과 | 대응 |
|---|---|---|
| 한 expert에 token 집중 | throughput 병목, specialization 실패 | auxiliary load balancing |
| 잘못된 routing | quality 저하 | router 학습 안정화 |
| expert 미사용 | parameter 낭비 | routing 확률 분산 유도 |

잘 학습된 expert는 code, multilingual text, punctuation-heavy region처럼 서로 다른 패턴에 특화될 수 있다.

## 6. Next-Token Prediction

LLM pretraining의 기본 objective는 다음 token 예측이다.

```text
input:  [BOS], A, cute, teddy, bear, is
target: A,     cute, teddy, bear, is, reading
```

한 문장은 여러 위치의 training target을 동시에 만든다. 학습 시에는 모든 위치의 다음 token을 병렬로 예측할 수 있지만, inference 시에는 생성된 token을 다시 입력에 붙여 한 step씩 진행한다.

## 7. Decoding 방법

모델은 각 step마다 vocabulary 전체에 대한 probability distribution을 만든다. Decoding은 이 분포에서 실제 다음 token을 고르는 방법이다.

| 방법 | 설명 | 장점 | 한계 |
|---|---|---|---|
| Greedy decoding | 매 step 가장 확률 높은 token 선택 | 빠르고 결정적 | 다양성이 낮고 전체 최적이 아닐 수 있음 |
| Beam search | 확률 높은 `k`개 partial sequence 유지 | 구조적 생성에 유리 | compute 증가, 창의성 부족 |
| Sampling | 확률 분포에서 token 샘플링 | 다양하고 자연스러운 생성 | 일관성 관리가 필요 |
| Top-k | 상위 `k`개 token에서만 sampling | 낮은 확률 noise 제거 | `k` 설정에 민감 |
| Top-p | 누적 확률 `p`까지의 최소 token 집합에서 sampling | 문맥별 후보 수 조절 | `p` 설정에 민감 |

## 8. Temperature

Temperature는 softmax 전에 logit을 조절해 분포의 날카로움을 바꾼다.

$$
\operatorname{softmax}\left(\frac{\mathrm{logits}}{T}\right)
$$

| Temperature | 효과 |
|---|---|
| 낮음 | 높은 확률 token에 더 집중, 안정적이고 반복적 |
| 높음 | 낮은 확률 token도 선택될 가능성 증가, 다양하지만 불안정 |

정확한 형식, 사실성, 도구 호출이 중요한 task에서는 낮은 temperature가 유리하고, brainstorming이나 creative writing에서는 조금 높은 temperature가 유리할 수 있다.

## 9. Cross-Entropy Loss

한 위치에서 모델은 vocabulary 전체에 대한 logit을 만들고 softmax로 확률을 계산한다. 정답 token의 확률이 높을수록 loss가 작아진다.

$$
L = -\log P(\mathrm{correct\ token}\mid\mathrm{context})
$$

전체 sequence loss는 여러 위치의 cross-entropy를 평균하거나 합산한다. 이 단순한 objective가 대규모 데이터와 모델에서 다양한 언어 능력으로 확장된다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Decoder-only 모델이 생성에 적합한 이유는? | 이전 token으로 다음 token을 예측하는 autoregressive 구조와 맞기 때문 |
| MoE의 핵심 장점은? | 전체 capacity를 키우면서 token당 compute를 제한할 수 있다. |
| Load balancing loss가 필요한 이유는? | router가 일부 expert에만 token을 몰아주는 현상을 막기 위해 |
| Greedy와 sampling의 차이는? | 최고 확률 token만 선택 vs 확률 분포에서 무작위 선택 |
| Temperature가 낮아지면? | 출력이 더 결정적이고 보수적으로 변한다. |

## 복습 질문

1. LLM scaling에서 parameter, data, compute 중 하나만 키우면 왜 충분하지 않은가?
2. Sparse MoE가 dense model보다 효율적인 이유를 token당 compute 관점에서 설명하라.
3. Top-k sampling과 top-p sampling의 차이를 예시로 설명하라.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/3_Large_Language_Models.pdf" | relative_url }}" target="_blank" rel="noopener">3_Large_Language_Models.pdf</a></li>
</ul>
