---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
title: "Large Language Models"
course: "AIX"
topic: "Decoder-Only LLMs and Generation"
order: 6
major_topic: "Artificial Intelligence"
keywords:
  - "Decoder-Only Transformer"
  - "Mixture of Experts"
  - "Next-Token Prediction"
  - "Decoding"
  - "Temperature"
---

# Large Language Models

Source PDF: `3_Large_Language_Models.pdf`

> **핵심:** **Decoder-only 모델이 생성에 적합한 이유는** 이전 token으로 다음 token을 예측하는 autoregressive 구조와 맞기 때문. **MoE의 핵심 장점은** 전체 capacity를 키우면서 token당 compute를 제한할 수 있다.

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

### 수식 원문 대응

| 원문 페이지 | 수식·도식 | 이 글의 보충 범위 |
|---:|---|---|
| p.17 | MoE weighted output | 원문 합을 router softmax와 top-$$k$$ 정규화까지 확장해 정의했다. |
| p.18-20 | routing collapse와 $$\alpha N\sum_i f_iP_i$$ | p.19의 직접 제시식을 균등 배분·완전 붕괴 극한으로 검산했다. |
| p.21-42 | next-token prediction, decoding, teacher forcing | 조건부확률과 sequence loss 표기는 원문 과정을 수식화한 보충이다. |
| p.45-47 | temperature softmax | 확률비 등식으로 분포가 날카로워지는 이유를 정확히 전개했다. |
| p.48 | one-step cross-entropy | one-hot categorical likelihood에서 $$-\log p_c$$가 나오는 과정을 보충했다. |

Scaling에 관한 설명은 수학적 보장이 아니라 p.5-7의 경험적 관찰이며, 본문에서도 등식과 구분한다.

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

이는 수학적으로 보장되는 등식이 아니라 여러 모델과 학습 run에서 관찰된 **경험적 scaling 경향**이다. Data 품질, optimization, architecture, evaluation distribution이 달라지면 parameter·token·compute 증가가 같은 폭의 성능 향상으로 이어지지 않을 수 있다.

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

Dense MoE의 weighted output은 다음처럼 정의할 수 있다.

$$
y(x)=\sum_{i=1}^{N}g_i(x)E_i(x),
\qquad
g_i(x)=\frac{e^{r_i(x)}}{\sum_{j=1}^{N}e^{r_j(x)}}
$$

$$N$$은 expert 수, $$r_i$$는 router logit, $$g_i$$는 합이 1인 무차원 routing weight, $$E_i(x)$$는 expert output이다. Sparse top-$$k$$에서는 선택 집합 $$S_k(x)$$ 밖의 weight를 0으로 만들고 선택된 weight를 다시 정규화한다. 이 식은 **MoE 출력의 정의**이며, 특정 expert가 의미 영역 하나와 정확히 대응한다는 보장은 없다. Router가 한 expert에 몰리면 계산 병목과 미학습 expert가 생기므로 별도의 load-balancing objective가 필요하다.

## 5. Routing과 Load Balancing

MoE에서 router는 token마다 어떤 expert를 쓸지 정한다. 문제는 router가 특정 expert만 계속 고르면 다른 expert가 학습되지 않고, 인기 expert는 병목이 된다는 점이다.

이를 줄이기 위해 load balancing loss를 추가한다.

원본 슬라이드는 batch 안의 token 배정 비율과 router 확률을 함께 사용하는 다음 보조 목적함수를 제시한다.

$$
L_{\mathrm{balance}}
=\alpha N\sum_{i=1}^{N} f_i P_i
$$

| 기호 | 명칭과 의미 | 단위 |
|---|---|---|
| $$L_{\mathrm{balance}}$$ | 전체 학습 loss에 더하는 load-balancing auxiliary loss | 무차원 |
| $$\alpha$$ | 보조 loss의 상대적 세기를 정하는 hyperparameter | 무차원 |
| $$N$$ | expert 수 | 무차원 개수 |
| $$f_i$$ | batch token 중 실제로 expert $$i$$에 배정된 비율 | 무차원 |
| $$P_i$$ | batch에서 expert $$i$$가 받은 평균 routing probability | 무차원 |

Batch의 token 수를 $$T$$, token $$x$$에 대한 router probability를 $$p_i(x)$$라고 하면 top-1 routing에서는 보통 다음처럼 해석한다.

$$
f_i=\frac{1}{T}\sum_{x=1}^{T}
\mathbf{1}\!\left[\operatorname*{arg\,max}_{j}p_j(x)=i\right],
\qquad
P_i=\frac{1}{T}\sum_{x=1}^{T}p_i(x).
$$

각 token에서 모든 expert에 대한 router probability가 softmax로 정규화되어 $$\sum_i p_i(x)=1$$이라고 가정하면, $$\sum_i f_i=\sum_i P_i=1$$이다. 이상적으로 두 분포가 모두 균등하면 $$f_i=P_i=1/N$$이므로

$$
L_{\mathrm{balance}}
=\alpha N\left(N\cdot\frac{1}{N^2}\right)
=\alpha.
$$

반대로 모든 token이 expert $$k$$로 배정되고 각 token에서 $$p_k(x)\to1$$인 완전 붕괴 극한에서는 $$f_k=1$$, $$P_k\to1$$이므로 $$L_{\mathrm{balance}}\to\alpha N$$이다. 유한한 softmax logit에서는 $$P_k=1$$에 정확히 도달하지 않지만 그 극한에 가까워질 수 있다. 즉 이 항은 실제 선택 빈도와 router가 주는 확률이 같은 expert에 함께 집중될수록 더 큰 penalty를 만들어, task loss가 허용하는 범위에서 여러 expert를 사용하도록 gradient를 제공한다.

이 식은 보편적으로 증명되는 최적성 정리가 아니라 **의도적으로 설계한 무차원 auxiliary objective**다. $$f_i$$는 discrete assignment라 직접 미분하기 어렵고, 구현에서는 주로 differentiable한 $$P_i$$ 경로가 router를 움직인다. Batch가 작으면 $$f_i$$ 추정의 분산이 커질 수 있고, top-$$k$$ routing·capacity limit·token dropping을 쓰면 $$f_i$$의 정의와 정규화가 달라진다. 또한 $$\alpha$$가 너무 크면 실제 언어 모델링보다 균등 배분을 과도하게 우선해 유용한 expert specialization을 방해할 수 있다.

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
p_i(T)=\frac{\exp(z_i/T)}{\sum_j\exp(z_j/T)},\qquad T>0
$$

$$z_i$$는 token $$i$$의 무차원 logit, $$T$$는 무차원 temperature다. 두 token의 확률비를 계산하면

$$
\frac{p_i(T)}{p_j(T)}
=\exp\left(\frac{z_i-z_j}{T}\right)
$$

이다. 따라서 $$z_i>z_j$$일 때 $$T$$가 작아지면 확률비가 커지고 분포가 날카로워지며, $$T$$가 커지면 비가 1에 가까워져 평평해진다. 이는 softmax 정의에서 나온 **정확한 등식**이다. $$T=0$$ 대입은 정의되지 않으며 구현에서는 greedy/argmax로 별도 처리한다. Temperature는 logit의 순위를 바꾸지 않고 상대 간격만 재조정하므로 지식이나 추론 능력을 새로 만들지는 않는다.

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

정답 token을 $$c$$, one-hot target을 $$y_i$$, softmax 확률을 $$p_i$$라고 두면 categorical likelihood는 $$P(y\mid x)=\prod_i p_i^{y_i}=p_c$$다. 음의 로그를 취하면

$$
-\log P(y\mid x)
=-\sum_i y_i\log p_i
=-\log p_c
$$

가 되어 슬라이드의 one-step loss를 얻는다. 이 식은 one-hot categorical target을 가정한 **정확한 negative log-likelihood 등식**이다. 전체 sequence에서는 teacher forcing으로 각 위치 $$t$$의 정답 prefix를 주고 $$L_{\mathrm{seq}}=\sum_t-\log p(y_t\mid y_{<t})$$를 계산한다. Padding 위치는 mask해야 하며, label smoothing을 쓰면 target이 one-hot이 아니므로 마지막 $$-\log p_c$$ 형태는 그대로 성립하지 않는다. 확률이 0에 가까우면 로그 손실이 발산하므로 구현은 log-softmax로 안정하게 계산한다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Decoder-only 모델이 생성에 적합한 이유는? | 이전 token으로 다음 token을 예측하는 autoregressive 구조와 맞기 때문 |
| MoE의 핵심 장점은? | 전체 capacity를 키우면서 token당 compute를 제한할 수 있다. |
| Load balancing loss가 필요한 이유는? | router가 일부 expert에만 token을 몰아주는 현상을 막기 위해 |
| Greedy와 sampling의 차이는? | 최고 확률 token만 선택 vs 확률 분포에서 무작위 선택 |
| Temperature가 낮아지면? | 출력이 더 결정적이고 보수적으로 변한다. |

## Study Guide

decoder-only causal generation에서 next-token probability와 cross-entropy가 연결되는 과정을 먼저 식과 함께 확인한다. MoE는 dense/sparse 여부, top-k routing, load balancing을 한 묶음으로 비교해야 token당 compute를 줄이면서 capacity를 키우는 이유가 보인다. 추론 파트는 같은 logits에 greedy, sampling, temperature를 적용했을 때 선택이 어떻게 달라지는지 작은 확률표로 재현한다.

## 복습 질문

<details markdown="block">
<summary>1. LLM scaling에서 parameter, data, compute 중 하나만 키우면 왜 충분하지 않은가?</summary>

답변: parameter가 커도 데이터가 부족하면 overfitting이나 학습 부족이 생기고, 데이터가 많아도 compute가 부족하면 충분히 학습할 수 없다. compute만 늘려도 모델 용량이나 데이터 품질이 받쳐주지 않으면 성능 향상이 제한된다. LLM scaling은 세 요소의 균형이 중요하다.

</details>

<details markdown="block">
<summary>2. Sparse MoE가 dense model보다 효율적인 이유를 token당 compute 관점에서 설명하라.</summary>

답변: dense model은 모든 token이 모든 parameter 경로를 통과한다. Sparse MoE는 많은 expert parameter를 가지고 있어도 token마다 일부 expert만 활성화한다. 그래서 전체 parameter 수는 크게 늘리면서도 token당 실제 계산량은 제한할 수 있다.

</details>

<details markdown="block">
<summary>3. Top-k sampling과 top-p sampling의 차이를 예시로 설명하라.</summary>

답변: top-k는 확률이 높은 상위 $$k$$개 token만 후보로 남긴다. top-p는 누적 확률이 $$p$$에 도달할 때까지 후보를 남기므로 후보 개수가 상황에 따라 달라진다. 예를 들어 분포가 뾰족하면 top-p 후보는 적고, 분포가 평평하면 더 많은 token이 포함될 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/3_Large_Language_Models.pdf" | relative_url }}" target="_blank" rel="noopener">3_Large_Language_Models.pdf</a></li>
</ul>
