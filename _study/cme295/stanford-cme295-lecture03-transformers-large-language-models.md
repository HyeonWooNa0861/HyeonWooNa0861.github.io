---
layout: default
title: "Stanford CME295 Lecture 3: Transformers & Large Language Models"
course: "CME295"
topic: "LLM Definitions, MoE, Decoding, Prompting, and Inference Optimization"
order: 3
---

# Stanford CME295 Lecture 3: Transformers & Large Language Models

Source: [Stanford CME295 Autumn 2025 Lecture 3](https://www.youtube.com/watch?v=Q5baLehv5So){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | LLM 정의 | Language model과 large language model은 probability, parameter, data, compute 관점에서 어떻게 정의되는가? |
| 2 | Decoder-only backbone | 왜 현재 LLM 정의에서는 BERT가 제외되고 GPT-style decoder-only 모델이 중심이 되는가? |
| 3 | Mixture of Experts | Gate/router는 sparse MoE에서 어떤 expert를 선택하고, 왜 FFN 위치가 중요하게 다뤄지는가? |
| 4 | Next-token decoding | Greedy decoding, beam search, sampling은 next token probability distribution을 어떻게 다르게 사용하는가? |
| 5 | Sampling controls | Top-k, top-p, temperature는 sampling 후보와 분포 shape를 어떻게 바꾸는가? |
| 6 | Prompting and context | Context length, prompt 구조, zero-shot/few-shot, chain of thought는 모델 행동을 어떻게 좌우하는가? |
| 7 | Inference efficiency | KV cache, PagedAttention, multi-latent attention, speculative decoding은 어떤 redundancy나 memory bottleneck을 줄이는가? |

## 핵심 내용

세 번째 강의는 LLM을 본격적으로 정의하면서 시작한다. Language model은 token sequence에 probability를 assign하고 next token probability를 예측하는 모델이며, LLM은 model size, pre-training data, compute가 모두 큰 language model로 설명된다. 강의에서는 현대 LLM이 보통 최소 billion 단위 parameter, hundreds of billions 또는 trillions of tokens 규모의 data, 많은 GPU compute를 필요로 한다고 말한다. 현재 정의에서 BERT는 text를 생성하지 않는 encoder-only 모델이므로 LLM으로 보지 않고, LLM은 text-to-text를 수행하는 decoder-only 모델로 둔다. GPT, LLaMA, Gemma, DeepSeek, Mistral, Qwen 등이 예로 나오며, modern day LLM의 90% 이상이 decoder-only라고 설명한다.

그 다음은 mixture of experts(MoE)와 generation 방법이다. MoE는 모든 parameter를 매 forward pass에 활성화하지 않고, gate/router G가 input x에 대해 어떤 expert E_i를 사용할지 정하는 구조다. Dense MoE는 모든 expert output에 weight를 두고, sparse MoE는 top-k expert만 선택해 FLOPS를 줄인다. 현대 LLM에서는 MoE를 주로 FFN 위치에 넣는데, FFN은 d_model에서 더 큰 d_FF로 갔다가 다시 d_model로 돌아가며 많은 parameter와 operation을 차지하기 때문이다. Expert는 token level로 routing될 수 있고, routing collapse를 막기 위해 expert별 token fraction f_i와 average routing probability p_i가 uniform에 가까워지도록 auxiliary loss를 더한다. Noisy gating도 언급된다. 이어서 next token 선택 방식으로 greedy decoding, beam search, sampling을 비교한다. Beam search는 k개의 path를 유지하고 sequence log probability를 token log probability의 합으로 보지만 짧은 sequence를 선호하는 문제가 있어 보정항이 필요하고, translation 같은 작업에 더 자주 쓰인다고 한다. Sampling은 probability distribution에서 token을 뽑는 방식이며 top-k, top-p, temperature가 소개된다. Temperature T는 softmax에서 logits를 T로 나누는 hyperparameter이고, low temperature는 spiky distribution, high temperature는 uniform에 가까운 distribution을 만든다. T=0은 이론적으로 deterministic하지만 실제 GPU 연산 순서 때문에 non-determinism이 생길 수 있다는 설명도 있다. Guided decoding은 JSON 같은 형식을 위해 invalid next token을 generation 중에 필터링하고, finite state machine이나 context grammar가 관련 키워드로 언급된다.

후반부는 prompting과 inference efficiency를 다룬다. Context length, context size, window size는 입력 token 수를 뜻하며 현대 LLM은 tens of thousands, hundreds of thousands, millions of tokens까지 처리할 수 있지만, needle-in-a-haystack류 실험에서 context rot처럼 긴 context에서 retrieval capability가 떨어질 수 있다고 설명한다. Prompt는 context, instructions, inputs, constraints로 볼 수 있고, in-context learning은 weight를 바꾸지 않고 context 안의 지식과 예시로 모델 행동을 유도한다. Zero-shot과 few-shot을 비교하고, chain of thought는 답 전에 rationale을 만들게 해 성능과 debugging 가능성을 높일 수 있지만 token 수와 latency를 늘린다고 한다. Self-consistency는 여러 번 sampling한 답에서 majority voting을 하는 방식이다. 마지막으로 inference 최적화에서는 KV cache로 과거 token의 key/value를 저장해 재계산을 피하고, training에서는 teacher forcing 때문에 이 개념이 나오지 않는다고 설명한다. GQA는 cache를 줄이는 데 재사용되고, PagedAttention/vLLM은 cache memory를 fixed-size block으로 관리해 fragmentation을 줄인다. DeepSeek V2의 multi-latent attention은 key/value projection을 lower-dimensional latent space로 factorize하고 cache representation을 key/value 및 head 사이에 공유해 compact하게 만든다. Speculative decoding은 작은 draft model이 여러 token을 제안하고 큰 target model이 acceptance-rejection으로 target distribution을 맞추며, multi-token prediction은 같은 model 안의 multiple heads를 draft처럼 활용한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Large Language Model (LLM) | Token sequence에 probability를 assign하고 next token을 예측하는 text-to-text language model 중 parameter, training tokens, compute 규모가 큰 모델이다. |
| Mixture of Experts (MoE) | Input x에 대해 gate/router G가 expert E_i의 output을 얼마나 사용할지 정하는 구조다. Sparse MoE는 top-k expert만 활성화한다. |
| FLOPS | Floating-point operations의 약자로 forward pass 등에 필요한 연산량을 나타내는 단위다. Sparse MoE는 dense MoE보다 FLOPS를 낮출 수 있다. |
| Routing collapse | MoE training에서 router가 일부 expert만 계속 선택하고 다른 expert는 거의 쓰지 않는 현상이다. Auxiliary loss나 noisy gating으로 완화할 수 있다. |
| Beam search | Beam width k개의 가장 가능성 높은 generation path를 유지하며 sequence probability가 높은 출력을 찾는 decoding 방식이다. |
| Top-k and Top-p sampling | Top-k는 확률이 가장 높은 k개 token에서 sampling하고, top-p는 누적 확률이 threshold p를 넘는 상위 token 집합에서 sampling한다. |
| Temperature | Softmax에서 logit을 T로 나누어 분포를 조절하는 hyperparameter다. 낮으면 가장 높은 token에 집중되고, 높으면 더 uniform해져 창의성이 커진다. |
| Guided decoding | JSON처럼 특정 형식이 필요할 때 generation 중 invalid next token을 필터링하는 방식이다. FSM과 context grammar가 관련 접근으로 언급된다. |
| KV cache | Autoregressive decoding에서 이전 token들의 key/value representation을 저장해 다음 token 계산 때 재사용하는 cache다. |
| Speculative decoding | 작은 draft model이 여러 token을 빠르게 제안하고 큰 target model이 acceptance-rejection으로 검증해 target distribution과 맞추는 inference 가속 방식이다. |

## 학습 포인트

- LLM은 token sequence에 probability를 assign하고 next token probability를 예측하는 language model이면서 parameter, data, compute 규모가 큰 text-to-text model이다.
- 강의의 현재 정의에서 BERT는 text를 생성하지 않으므로 LLM이 아니며, 현대 LLM은 대부분 decoder-only다.
- MoE는 router/gate가 expert를 선택해 active parameters와 FLOPS를 줄이면서 total capacity를 키우는 방식이다.
- Sparse MoE는 top-k expert만 활성화하고, routing collapse를 막기 위해 f_i와 p_i를 균등하게 만드는 auxiliary loss를 사용할 수 있다.
- Greedy decoding은 deterministic하고 다양성이 낮으며, beam search는 여러 path를 유지하지만 계산이 크고 짧은 sequence 선호 문제가 있다.
- Sampling은 top-k, top-p, temperature로 후보와 확률분포를 조절하며, low temperature는 spiky, high temperature는 uniform에 가까운 분포를 만든다.
- Context length가 커져도 context rot과 distractor 때문에 관련 정보 검색 성능이 자동으로 보장되지는 않는다.
- KV cache, GQA, PagedAttention, multi-latent attention, speculative decoding, multi-token prediction은 inference cost와 memory bottleneck을 줄이기 위한 기법들이다.

## 마지막 핵심 정리

이 강의의 핵심은 `LLM 정의, MoE, decoding, prompting, inference optimization`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. LLM의 정의를 language model, large, decoder-only, text-to-text 조건으로 분해해 설명한다.
2. MoE의 dense/sparse 차이, gate/router, active parameters, routing collapse를 하나의 그림으로 정리한다.
3. Greedy, beam search, sampling, top-k, top-p, temperature를 inference-time 전략으로 묶어 비교한다.
4. Context length가 길어질수록 self-attention complexity와 context rot 문제가 왜 함께 중요해지는지 복습한다.
5. Prompt를 context, instructions, inputs, constraints로 나누고 zero-shot/few-shot/COT/self-consistency의 trade-off를 정리한다.
6. KV cache부터 speculative decoding까지 inference optimization 기법들이 정확한 계산, memory management, approximate acceleration 중 어디에 속하는지 구분한다.

## 복습 질문

<details>
<summary>1. 강의의 현재 정의에서 BERT가 LLM으로 분류되지 않는 이유는 무엇인가?</summary>

답변: BERT는 encoder-only 모델로 text를 생성하지 않는다. 강의에서는 현재 LLM을 text-to-text를 수행하고 parameter, training data, compute가 큰 decoder-only language model로 정의한다.

</details>

<details>
<summary>2. Sparse MoE가 dense MoE와 다른 점은 무엇인가?</summary>

답변: Dense MoE는 모든 expert output에 weight를 둘 수 있지만, sparse MoE는 top-k expert만 선택해 계산한다. 그래서 total parameter capacity를 키우면서 forward pass의 active parameter와 FLOPS를 제한할 수 있다.

</details>

<details>
<summary>3. Temperature가 next-token sampling에 미치는 영향은 무엇인가?</summary>

답변: Softmax에서 logits를 T로 나누므로 T가 낮으면 가장 높은 logit token에 확률이 몰리는 spiky distribution이 되고, T가 높으면 확률이 더 uniform해져 낮은 확률 token도 뽑힐 가능성이 커진다.

</details>

<details>
<summary>4. Context length가 커지면 retrieval 문제가 자동으로 해결되는가?</summary>

답변: 아니다. 강의는 context rot과 needle-in-a-haystack 실험을 언급하며, context가 길어지고 distractor가 많아질수록 답이 context 안에 있어도 grounding/retrieval capability가 떨어질 수 있다고 설명한다.

</details>

<details>
<summary>5. KV cache는 왜 training보다 inference에서 중요하게 등장하는가?</summary>

답변: Inference에서는 autoregressive decoding으로 매 token마다 이전 token들의 key/value를 다시 참조하므로 저장해 재사용하면 중복 계산을 줄일 수 있다. Training에서는 teacher forcing으로 입력 전체를 한 번에 넣기 때문에 같은 의미의 KV caching 문제가 생기지 않는다.

</details>

<details>
<summary>6. Speculative decoding은 어떻게 큰 LLM의 generation을 빠르게 만드는가?</summary>

답변: 작은 draft model이 여러 token을 빠르게 생성하고, 큰 target model이 그 token들을 한 번의 forward pass로 평가한다. Acceptance-rejection 규칙을 통해 target distribution을 유지하면서 여러 token만큼 진행할 수 있다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=Q5baLehv5So){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
