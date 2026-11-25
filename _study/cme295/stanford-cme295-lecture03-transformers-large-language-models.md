---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CME295 Lecture 3: Transformers & Large Language Models"
course: "CME295"
topic: "LLM Definitions, MoE, Decoding, Prompting, and Inference Optimization"
order: 3
major_topic: "Large Language Models"
keywords:
  - "Decoder-Only Models"
  - "Scaling"
  - "In-Context Learning"
  - "Instruction Tuning"
  - "GPT"
---

# Stanford CME295 Lecture 3: Transformers & Large Language Models

Source: [Stanford CME295 Autumn 2025 Lecture 3](https://www.youtube.com/watch?v=Q5baLehv5So){:target="_blank" rel="noopener"}

**원본 영상 먼저 보기:** [00:18:50의 token별 MoE routing 구조](https://www.youtube.com/watch?v=Q5baLehv5So&t=1130s){:target="_blank" rel="noopener"}에서 gate가 입력 token을 일부 FFN expert에만 보내는 구조를 먼저 확인합니다. 아래 MoE 절은 이 sparse routing이 한 expert로 쏠릴 때 생기는 routing collapse와 load-balancing auxiliary loss를 처리 순서대로 연결합니다.

<figure>
  <a href="{{ '/assets/images/study/cme295/source-captures/lecture-03-moe-routing-00h18m50s.jpg' | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ '/assets/images/study/cme295/source-captures/lecture-03-moe-routing-00h18m50s.jpg' | relative_url }}" alt="입력 token x를 gate G가 여러 FFN expert 중 하나로 보내는 MoE routing 구조" loading="lazy">
  </a>
  <figcaption><a href="https://www.youtube.com/watch?v=Q5baLehv5So&t=1130s" target="_blank" rel="noopener">공식 영상 00:18:50</a> — 각 token의 입력 x를 gate G가 평가하고, 선택된 FFN₂만 통과시켜 출력 ŷ에 반영하는 sparse MoE routing 구조입니다.</figcaption>
</figure>

실선은 gate가 만든 routing score의 흐름이고, 점선은 입력이 각 expert 후보와 연결될 수 있음을 나타냅니다. 초록 체크가 선택된 경로이며 빨간 표시는 계산에서 제외된 expert입니다. 이 선택이 token마다 달라져야 모델 용량을 나눠 쓸 수 있습니다. gate가 계속 같은 expert만 고르면 그 경로에 계산과 학습 신호가 몰리는 routing collapse가 생기므로, 아래 auxiliary loss가 expert별 선택 빈도와 평균 routing probability를 함께 균형화합니다.

> **핵심:** 언어 모델은 지금까지 쓴 문장 뒤에 어떤 글 조각이 이어질지 후보별 확률을 냅니다. 같은 확률표에서도 매번 가장 유력한 후보를 고를지, 확률에 따라 뽑을지에 따라 다른 문장이 나옵니다. 답을 생성하는 속도는 이미 읽은 부분의 계산을 얼마나 재사용하는지에도 달려 있습니다.

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | LLM 정의 | Language model과 large language model은 probability, parameter, data, compute 관점에서 어떻게 정의됩니까? |
| 2 | Decoder-only backbone | 왜 현재 LLM 정의에서는 BERT가 제외되고 GPT-style decoder-only 모델이 중심이 됩니까? |
| 3 | Mixture of Experts | Gate/router는 sparse MoE에서 어떤 expert를 선택하고, 왜 FFN 위치가 중요하게 다뤄집니까? |
| 4 | Next-token decoding | Greedy decoding, beam search, sampling은 next token probability distribution을 어떻게 다르게 사용합니까? |
| 5 | Sampling controls | Top-k, top-p, temperature는 sampling 후보와 분포 shape를 어떻게 바꿉니까? |
| 6 | Prompting and context | Context length, prompt 구조, zero-shot/few-shot, chain of thought는 모델 행동을 어떻게 좌우합니까? |
| 7 | Inference efficiency | KV cache, PagedAttention, multi-latent attention, speculative decoding은 어떤 redundancy나 memory bottleneck을 줄입니까? |

</details>
## 핵심 내용

언어 모델은 토큰 시퀀스에 확률을 부여하고 다음 토큰의 분포를 예측합니다. 이 강의에서 LLM은 모델 크기, 사전학습 데이터, 계산 자원이 모두 큰 언어 모델을 뜻하며, 보통 최소 수십억 개의 parameter와 수천억~수조 token의 데이터, 많은 GPU 계산 자원을 전제로 합니다. 강의는 텍스트를 생성하지 않는 encoder-only BERT를 여기서의 LLM 정의에서 제외하고, text-to-text를 수행하는 decoder-only 구조에 초점을 맞춥니다. GPT, LLaMA, Gemma, DeepSeek, Mistral, Qwen이 예로 나오며, 현대 LLM의 90% 이상이 decoder-only라는 강의 설명도 함께 제시됩니다.

다음 토큰 예측은 휴대전화 자동완성과 비슷하지만 한 번으로 끝나지 않습니다. 현재 문장 뒤의 후보 확률을 계산해 토큰 하나를 고르고, 그 토큰을 입력 뒤에 붙여 다시 다음 후보를 계산합니다. 이 반복이 문장 전체를 만듭니다. Decoder-only 모델이 `이전 토큰만 보는 mask`를 쓰는 이유도 아직 생성하지 않은 미래 정답을 미리 보지 않은 채 이 과정을 학습하기 위해서입니다.

그 다음은 mixture of experts(MoE)와 generation 방법입니다. MoE는 큰 모델의 모든 계산부를 매번 사용하지 않고, 각 토큰에 맞는 일부 **expert**만 고릅니다. Router는 토큰을 어느 expert로 보낼지 결정합니다. Sparse MoE가 상위 $$k$$개 expert만 고르는 이유는 모델의 전체 파라미터 수를 늘리면서도 한 토큰의 실제 계산량은 제한하기 위해서입니다. 다만 router가 몇 개 expert만 계속 고르면 나머지가 학습되지 않으므로, 선택이 한쪽으로 몰리는 routing collapse를 보조 loss로 완화합니다. FFN이 많은 파라미터와 연산을 차지하기 때문에 현대 LLM은 이 위치에 MoE를 주로 넣습니다.

모델이 다음 토큰의 확률을 만든 뒤에는 실제 토큰을 고르는 규칙이 필요합니다. Greedy decoding은 매번 가장 높은 확률 하나를 고릅니다. Beam search는 가능성 높은 문장 후보 $$k$$개를 함께 유지합니다. Sampling은 확률에 따라 토큰을 뽑아 다양한 출력을 만듭니다. Top-k는 후보 개수를, top-p는 후보들의 누적 확률을 제한하고, temperature는 분포가 한 후보에 얼마나 집중되는지를 조절합니다. Guided decoding은 JSON처럼 정해진 형식에서 지금 선택하면 문법이 깨지는 토큰을 제외합니다. 정확한 점수식과 beam의 길이 편향은 아래 수식 해설에서 다룹니다.

MoE와 decoding도 적용 시점이 다릅니다. MoE는 모델 내부에서 이번 토큰을 어느 계산 경로로 보낼지 정해 큰 모델의 일부만 사용하게 합니다. Greedy·beam·sampling은 모델이 이미 만든 확률분포에서 실제 출력 토큰을 어떻게 고를지 정합니다. 따라서 MoE가 같은 모델이라도 temperature나 top-p를 바꾸면 문장 선택 양상은 달라질 수 있습니다.

후반부는 prompting과 inference efficiency를 다룹니다. Context length, context size, window size는 입력 token 수를 뜻하며 현대 LLM은 tens of thousands, hundreds of thousands, millions of tokens까지 처리할 수 있지만, needle-in-a-haystack류 실험에서 context rot처럼 긴 context에서 retrieval capability가 떨어질 수 있다고 설명합니다. Prompt는 context, instructions, inputs, constraints로 볼 수 있고, in-context learning은 weight를 바꾸지 않고 context 안의 지식과 예시로 모델 행동을 유도합니다. Zero-shot과 few-shot을 비교하고, chain of thought는 답 전에 rationale을 만들게 해 성능과 debugging 가능성을 높일 수 있지만 token 수와 latency를 늘린다고 합니다. Self-consistency는 여러 번 sampling한 답에서 majority voting을 하는 방식입니다. 마지막으로 inference 최적화에서는 KV cache로 과거 token의 key/value를 저장해 재계산을 피하고, training에서는 teacher forcing 때문에 이 개념이 나오지 않는다고 설명합니다. GQA는 cache를 줄이는 데 재사용되고, PagedAttention/vLLM은 cache memory를 fixed-size block으로 관리해 fragmentation을 줄입니다. DeepSeek V2의 multi-latent attention은 key/value projection을 lower-dimensional latent space로 factorize하고 cache representation을 key/value 및 head 사이에 공유해 compact하게 만듭니다. Speculative decoding은 작은 draft model이 여러 token을 제안하고 큰 target model이 acceptance-rejection으로 target distribution을 맞추며, multi-token prediction은 같은 model 안의 multiple heads를 draft처럼 활용합니다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Large Language Model (LLM) | Token sequence에 probability를 assign하고 next token을 예측하는 text-to-text language model 중 parameter, training tokens, compute 규모가 큰 모델입니다. |
| Mixture of Experts (MoE) | Input x에 대해 gate/router G가 expert E_i의 output을 얼마나 사용할지 정하는 구조입니다. Sparse MoE는 top-k expert만 활성화합니다. |
| FLOPs | Floating-point operation count로, forward pass 등에 필요한 부동소수점 연산 횟수를 뜻합니다. 연산 처리율은 FLOP/s 또는 FLOPS로 구분합니다. Sparse MoE는 dense MoE보다 FLOPs를 낮출 수 있습니다. |
| Routing collapse | MoE training에서 router가 일부 expert만 계속 선택하고 다른 expert는 거의 쓰지 않는 현상입니다. Auxiliary loss나 noisy gating으로 완화할 수 있습니다. |
| Beam search | Beam width k개의 가장 가능성 높은 generation path를 유지하며 sequence probability가 높은 출력을 찾는 decoding 방식입니다. |
| Top-k and Top-p sampling | Top-k는 확률이 가장 높은 k개 token에서 sampling하고, top-p는 누적 확률이 threshold p를 넘는 상위 token 집합에서 sampling합니다. |
| Temperature | Softmax에서 logit을 T로 나누어 분포를 조절하는 hyperparameter입니다. 낮으면 가장 높은 token에 집중되고, 높으면 더 uniform해져 창의성이 커집니다. |
| Guided decoding | JSON처럼 특정 형식이 필요할 때 generation 중 invalid next token을 필터링하는 방식입니다. FSM과 context grammar가 관련 접근으로 언급됩니다. |
| KV cache | Autoregressive decoding에서 이전 token들의 key/value representation을 저장해 다음 token 계산 때 재사용하는 cache입니다. |
| Speculative decoding | 작은 draft model이 여러 token을 빠르게 제안하고 큰 target model이 acceptance-rejection으로 검증해 target distribution과 맞추는 inference 가속 방식입니다. |

## 수식 해설: generation, MoE, cache

Autoregressive generation은 이전 token을 조건으로 다음 token 확률을 곱하고, temperature는 그 분포의 집중도를 조절합니다. MoE routing은 선택된 expert만 계산하고, KV cache와 speculative decoding은 이미 계산한 정보를 재사용해 target model의 분포를 유지하면서 추론 비용을 줄입니다.

<details markdown="block">
<summary markdown="span">Derivation: Sequence probability, routing, cache, and speculative acceptance</summary>

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Dense/sparse MoE와 routing | 00:10:59–00:14:16, 00:20:38–00:24:02, 00:26:20–00:27:18 | Weighted expert 합, auxiliary loss, gate probability는 강의 원문입니다. Auxiliary-loss의 보장 한계는 작성자 보충입니다. |
| Autoregressive sequence probability | 00:43:51–00:44:53 | Token log-probability 합과 probability 곱은 강의 원문이며, 조건부 chain-rule 표기는 작성자 보충입니다. |
| Temperature softmax 극한 | 00:52:31–00:59:52 | Softmax 식과 저온·고온 전개는 강의 원문이며, odds 식과 $$\tau=0$$ 조건은 작성자 보충입니다. |
| KV cache | 01:28:38–01:30:16 | K/V 재사용은 강의 원문이며, byte 단위 용량식과 PagedAttention 경계는 작성자 보충입니다. |
| Speculative decoding acceptance | 01:41:34–01:45:29 | Draft/target과 acceptance-rejection 흐름은 강의 원문이며, 아래 acceptance 확률·residual distribution과 marginal 확인은 작성자 보충입니다. |

Autoregressive model의 chain rule은

$$
p(y_{1:T}\mid x)=\prod_{t=1}^{T}p(y_t\mid x,y_{<t}),
\qquad
\log p(y_{1:T}\mid x)=\sum_{t=1}^{T}\log p(y_t\mid x,y_{<t})
$$

입니다. 이는 확률의 **정확한 chain rule**이고 $$T,t$$는 무차원 token count/index입니다. 각 log probability는 보통 0 이하라 긴 sequence가 불리해집니다. $$T^{-\alpha}\sum_t\log p_t$$ 같은 length normalization은 이를 조절하는 heuristic이며 보편적으로 최적인 $$\alpha$$는 없습니다.

Temperature $$\tau>0$$의 softmax는

$$
p_i(\tau)=\frac{e^{z_i/\tau}}{\sum_j e^{z_j/\tau}}.
$$

두 token의 odds는 $$p_i/p_j=e^{(z_i-z_j)/\tau}$$이므로 $$\tau$$가 작을수록 logit 차이가 확대되고, $$\tau\to\infty$$이면 유한 logit에서 uniform distribution으로 갑니다. $$\tau=0$$은 식에 넣을 수 없으며 argmax limit로 구현합니다. 더 높은 temperature가 반드시 더 창의적이라는 말은 경험적 해석입니다.

Dense MoE는 $$y=\sum_{i=1}^{E}G_i(x)E_i(x)$$, $$G_i\ge0$$, $$\sum_iG_i=1$$로 정의할 수 있고 sparse top-$$k$$는 선택된 expert만 계산합니다. Switch-style $$L_{aux}=E\sum_i f_ip_i$$는 token fraction $$f_i$$와 mean routing probability $$p_i$$를 고르게 만들려는 **auxiliary heuristic**입니다. 완전 균형이나 더 높은 task quality를 보장하는 theorem은 아닙니다.

단순 dense layout의 KV cache는

$$
M_{KV}=2LTh_{kv}d_hb
$$

byte입니다. $$L$$은 layer 수, $$T$$는 cached token 수, $$h_{kv}$$는 KV head 수, $$d_h$$는 head dimension, $$b$$는 element당 byte이고 2는 K/V입니다. GQA/MQA는 $$h_{kv}$$를 줄입니다. PagedAttention은 fragmentation을 줄이지만 tensor 원소 수 자체를 자동으로 줄이는 식은 아닙니다.

Speculative decoding의 한 token을 보겠습니다. Draft distribution을 $$q(x)$$, target distribution을 $$p(x)$$라 하고 $$x\sim q$$를 제안하면

$$
a(x)=\min\!\left(1,\frac{p(x)}{q(x)}\right)
$$

확률로 accept합니다. Reject되면 residual distribution

$$
r(x)=\frac{[p(x)-q(x)]_+}{\sum_z[p(z)-q(z)]_+},
\qquad [u]_+=\max(u,0)
$$

에서 다시 뽑습니다. Draft에서 accept되어 $$x$$가 나올 질량은 $$q(x)a(x)=\min(p(x),q(x))$$입니다. 전체 reject 확률은 $$1-\sum_z\min(p(z),q(z))=\sum_z[p(z)-q(z)]_+$$이므로 residual 경로의 질량을 더하면 $$\min(p,q)+[p-q]_+=p$$가 되어 target marginal을 복원합니다. 이는 이상적인 categorical distribution과 정확한 확률 계산을 가정한 **작성자 보충 유도**입니다. $$p=q$$이면 reject 확률이 0이라 residual 분모도 0이지만 그 branch 자체를 실행하지 않습니다. $$q(x)=0$$인 token은 draft에서 제안되지 않으며 residual에서 처리되고, 여러 token block에서는 첫 rejection 이후의 token을 버리고 그 위치부터 target-consistent generation을 이어야 합니다. 모든 draft token을 accept한 뒤 target에서 한 token을 더 sampling하는 단계까지 포함해야 표준 speculative decoding 절차가 완성됩니다.

</details>

## 학습 포인트

- LLM은 token sequence에 probability를 assign하고 next token probability를 예측하는 language model이면서 parameter, data, compute 규모가 큰 text-to-text model입니다.
- 강의의 현재 정의에서 BERT는 text를 생성하지 않으므로 LLM이 아니며, 현대 LLM은 대부분 decoder-only입니다.
- MoE는 router/gate가 expert를 선택해 active parameters와 FLOPs를 줄이면서 total capacity를 키우는 방식입니다.
- Sparse MoE는 top-k expert만 활성화하고, routing collapse를 막기 위해 f_i와 p_i를 균등하게 만드는 auxiliary loss를 사용할 수 있습니다.
- Greedy decoding은 deterministic하고 다양성이 낮으며, beam search는 여러 path를 유지하지만 계산이 크고 짧은 sequence 선호 문제가 있습니다.
- Sampling은 top-k, top-p, temperature로 후보와 확률분포를 조절하며, low temperature는 spiky, high temperature는 uniform에 가까운 분포를 만듭니다.
- Context length가 커져도 context rot과 distractor 때문에 관련 정보 검색 성능이 자동으로 보장되지는 않습니다.
- KV cache, GQA, PagedAttention, multi-latent attention, speculative decoding, multi-token prediction은 inference cost와 memory bottleneck을 줄이기 위한 기법들입니다.

## 마지막 핵심 정리

이 강의의 핵심은 `LLM 정의, MoE, decoding, prompting, inference optimization`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것입니다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

1. LLM의 정의를 language model, large, decoder-only, text-to-text 조건으로 분해해 설명합니다.
2. MoE의 dense/sparse 차이, gate/router, active parameters, routing collapse를 하나의 그림으로 정리합니다.
3. Greedy, beam search, sampling, top-k, top-p, temperature를 inference-time 전략으로 묶어 비교합니다.
4. Context length가 길어질수록 self-attention complexity와 context rot 문제가 왜 함께 중요해지는지 복습합니다.
5. Prompt를 context, instructions, inputs, constraints로 나누고 zero-shot/few-shot/COT/self-consistency의 trade-off를 정리합니다.
6. KV cache부터 speculative decoding까지 inference optimization 기법들이 정확한 계산, memory management, approximate acceleration 중 어디에 속하는지 구분합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. 강의의 현재 정의에서 BERT가 LLM으로 분류되지 않는 이유는 무엇입니까?</summary>

답변: BERT는 encoder-only 모델로 text를 생성하지 않습니다. 강의에서는 현재 LLM을 text-to-text를 수행하고 parameter, training data, compute가 큰 decoder-only language model로 정의합니다.

</details>

<details markdown="block">
<summary>2. Sparse MoE가 dense MoE와 다른 점은 무엇입니까?</summary>

답변: Dense MoE는 모든 expert output에 weight를 둘 수 있지만, sparse MoE는 top-k expert만 선택해 계산합니다. 그래서 total parameter capacity를 키우면서 forward pass의 active parameter와 FLOPs를 제한할 수 있습니다.

</details>

<details markdown="block">
<summary>3. Temperature가 next-token sampling에 미치는 영향은 무엇입니까?</summary>

답변: Softmax에서 logits를 T로 나누므로 T가 낮으면 가장 높은 logit token에 확률이 몰리는 spiky distribution이 되고, T가 높으면 확률이 더 uniform해져 낮은 확률 token도 뽑힐 가능성이 커집니다.

</details>

<details markdown="block">
<summary>4. Context length가 커지면 retrieval 문제가 자동으로 해결됩니까?</summary>

답변: 아닙니다. 강의는 context rot과 needle-in-a-haystack 실험을 언급하며, context가 길어지고 distractor가 많아질수록 답이 context 안에 있어도 grounding/retrieval capability가 떨어질 수 있다고 설명합니다.

</details>

<details markdown="block">
<summary>5. KV cache는 왜 training보다 inference에서 중요하게 등장합니까?</summary>

답변: Inference에서는 autoregressive decoding으로 매 token마다 이전 token들의 key/value를 다시 참조하므로 저장해 재사용하면 중복 계산을 줄일 수 있습니다. Training에서는 teacher forcing으로 입력 전체를 한 번에 넣기 때문에 같은 의미의 KV caching 문제가 생기지 않습니다.

</details>

<details markdown="block">
<summary>6. Speculative decoding은 어떻게 큰 LLM의 generation을 빠르게 만듭니까?</summary>

답변: 작은 draft model이 여러 token을 빠르게 생성하고, 큰 target model이 그 token들을 한 번의 forward pass로 평가합니다. Acceptance-rejection 규칙을 통해 target distribution을 유지하면서 여러 token만큼 진행할 수 있습니다.

</details>

## 참고자료

- 자료 확인 범위: 공식 Stanford CME295 강의 영상과 영문 전사를 대조했습니다. 공식 슬라이드는 없어 화면에 보이지 않는 내용은 추정하지 않았습니다.

- [강의 영상](https://www.youtube.com/watch?v=Q5baLehv5So){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
