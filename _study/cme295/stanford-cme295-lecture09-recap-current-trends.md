---
layout: default
date: 2026-08-12 10:07:20 +0900
title: "Stanford CME295 Lecture 9: Recap & Current Trends"
course: "CME295"
topic: "CME295 Full Review, 2025 LLM Trends, and Future Study Directions"
order: 9
major_topic: "Large Language Models"
keywords:
  - "Current Trends"
  - "Scaling"
  - "Agents"
  - "Multimodal LLMs"
  - "Inference Optimization"
---

# Stanford CME295 Lecture 9: Recap & Current Trends

Source: [Stanford CME295 Autumn 2025 Lecture 9](https://www.youtube.com/watch?v=Q86qzJ1K1Ss){:target="_blank" rel="noopener"}

> **핵심:** 마지막 강의는 세 부분으로 구성된다. 첫 부분은 전체 수업 복습으로, tokenization과 word2vec에서 시작해 RNN의 long-range dependency 한계, self-attention, transformer encoder와 decoder, RoPE, grouped query attention, pre-norm, BERT, GPT, T5, mixture of experts, temperature sampling까지 이어진다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 초기 NLP와 transformer 도입 | tokenization, word2vec, RNN의 한계는 어떻게 self-attention과 transformer로 이어졌는가? |
| 2 | 현대 LLM 아키텍처와 decoding | RoPE, grouped query attention, pre-norm, MoE, temperature sampling은 각각 어떤 문제를 다루는가? |
| 3 | 학습과 효율화 | scaling law, FlashAttention, data/model parallelism은 큰 LLM 학습의 어떤 병목을 해결하는가? |
| 4 | alignment와 reasoning | SFT, preference tuning, reward model, PPO, GRPO는 LLM 행동을 어떻게 바꾸는가? |
| 5 | RAG, tools, evaluation 복습 | 외부 지식, 외부 행동, 출력 평가를 위해 각각 어떤 기술이 사용되었는가? |
| 6 | 멀티모달과 diffusion LLM | Transformer가 image로 확장되고 diffusion이 text로 들어오는 양방향 흐름은 무엇을 보여 주는가? |
| 7 | 앞으로의 연구와 사용 | data, architecture, hardware, agent reliability, safety에서 남아 있는 핵심 과제는 무엇인가? |

## 핵심 내용

마지막 강의는 세 부분으로 구성된다. 첫 부분은 전체 수업 복습으로, tokenization과 word2vec에서 시작해 RNN의 long-range dependency 한계, self-attention, transformer encoder와 decoder, RoPE, grouped query attention, pre-norm, BERT, GPT, T5, mixture of experts, temperature sampling까지 이어진다. 이어 scaling law 관점에서 parameter 수와 token 수의 균형, 100B parameter 모델에는 최소 2T token 정도가 필요하다는 rule of thumb, FlashAttention의 HBM과 SRAM 최적화, data parallelism과 model parallelism을 복습한다.

강의는 LLM 학습 과정을 pre-training, SFT, preference tuning으로 다시 정리한다. preference tuning에서는 LLM을 policy처럼 보고 reward model과 Bradley-Terry formulation을 사용하며, reward hacking을 막기 위해 base model 또는 이전 RL iteration에서 너무 멀어지지 않도록 한다. Reasoning model에서는 chain of thought 또는 hidden reasoning chain을 만들도록 RL을 사용하고, PPO와 달리 GRPO는 value model 없이 여러 completion의 상대 reward로 advantage를 계산한다. GRPO Done Right와 DAPO는 length bias를 줄이는 extension으로 언급된다. 이어 RAG, tool calling, agentic workflow, LLM-as-a-Judge, 주요 benchmark가 final exam 범위로 묶여 복습된다.

두 번째와 세 번째 부분은 2025년 트렌드와 수업 이후의 방향이다. Transformer는 Vision Transformer, VLM, LLaVA, Llama 3식 cross-attention, diffusion transformer처럼 non-text 영역으로 확장되었고, 반대로 image diffusion의 아이디어는 text generation에 들어와 masked diffusion model 또는 diffusion-based LLM으로 연구되고 있다. LLaDA, Google I/O의 experimental text diffusion model, Inception이 예시로 언급되며, diffusion LLM은 autoregressive decoding보다 훨씬 적은 forward pass로 긴 출력과 fill-in-the-middle task에서 속도 이점을 줄 수 있지만 frontier autoregressive model 수준으로 따라잡는 작업은 진행 중이다. 마지막으로 DeepSeek OCR, 2D RoPE, Muon과 MuonClip, RMSNorm, data curation, mid-training, model collapse, small language models, hardware specialization, AI-assisted coding, ChatGPT Atlas, continuous learning, hallucination, personalization, interpretability, safety, 그리고 arXiv, NeurIPS, HuggingFace trending papers, X, YouTube, company blogs로 최신 흐름을 따라가는 방법이 소개된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Self-attention | query와 key의 유사도를 softmax로 가중치화하고 value의 weighted average를 만드는 transformer의 핵심 연산이다. |
| RoPE | Rotary position embeddings. query와 key를 회전시켜 attention에서 token 간 상대 위치 정보를 반영한다. |
| Grouped Query Attention | attention head마다 key와 value projection을 모두 따로 두지 않고 grouping해 계산과 메모리 부담을 줄이는 방법으로 복습된다. |
| FlashAttention | GPU의 HBM과 SRAM 구조를 활용해 memory movement를 줄이고, 일부 값을 저장하지 않고 필요할 때 재계산해 attention을 빠르게 계산하는 exact method다. |
| Bradley-Terry formulation | 두 output의 reward score 차이로 한 output이 다른 output보다 선호될 확률을 모델링해 reward model 학습에 쓰인다. |
| GRPO | Group Relative Policy Optimization. value model 없이 같은 query의 여러 completion reward를 비교해 relative advantage를 만드는 RL 알고리즘이다. |
| Vision Transformer | 이미지를 patch로 나누어 vector token으로 만들고 transformer encoder를 통과시켜 CLS embedding으로 image classification을 수행하는 모델이다. |
| VLM | Vision-language model. image token과 text token을 함께 처리하거나 cross-attention으로 연결해 이미지에 대한 질문에 답할 수 있는 모델이다. |
| Masked Diffusion Model | text diffusion에서 noise의 analogue를 mask token으로 보고, 완전히 또는 부분적으로 masked된 sequence를 점진적으로 unmask하는 모델 계열이다. |
| Model collapse | LLM generated text가 다양성이 낮아 training data distribution을 바꾸고 학습 품질을 떨어뜨릴 수 있다는 문제로 소개된다. |

## 학습 포인트

- Self-attention은 query, key, value를 사용해 모든 token이 서로 attend하게 하며, 강의는 softmax(QK^T / sqrt(k))V 공식을 복습한다.
- BERT는 encoder-only로 embedding과 classification에 적합하고, GPT는 decoder-only autoregressive text generation에 적합하며, T5는 encoder-decoder 구조다.
- Scaling law 논의에서는 많은 당시 모델이 dataset size에 비해 너무 큰 undertrained 상태였고, parameter 수의 약 20배 token으로 학습하라는 rule of thumb이 제시된다.
- FlashAttention은 HBM read/write를 줄이고 SRAM에서 block 단위 계산을 수행해 정확한 attention 결과를 더 빠르게 얻는다.
- Preference tuning은 reward model과 RL을 사용하지만 reward hacking을 막기 위해 SFT base model과 이전 RL iteration에서 너무 멀어지지 않게 한다.
- GRPO는 value model을 유지하지 않고 같은 prompt의 여러 completion rewards를 상대 비교해 reasoning task, 특히 verifiable reward가 있는 math/coding에 쓰인다.
- Vision Transformer는 image patch를 token처럼 만들고 transformer encoder의 CLS embedding으로 classification을 수행한다.
- Diffusion-based LLM은 text의 discrete token 문제를 mask token으로 다루며, autoregressive decoding보다 적은 diffusion step으로 긴 출력을 빠르게 만들 수 있다는 가능성을 보여 준다.

## 마지막 핵심 정리

이 강의의 핵심은 `CME295 전체 복습, 2025년 LLM 트렌드, 앞으로의 학습 방향`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. Lecture 1부터 8까지를 architecture, training, alignment, reasoning, external systems, evaluation이라는 축으로 다시 묶어 본다.
2. PPO와 GRPO를 value model 필요 여부, reward source, advantage 계산 방식, reasoning task 적합성으로 비교한다.
3. RAG, tool calling, LLM-as-a-Judge가 각각 knowledge cutoff, external action, free-form output evaluation 문제를 어떻게 다루는지 연결한다.
4. Vision Transformer와 diffusion LLM을 transformer가 text 밖으로 나간 사례와 diffusion이 text 안으로 들어온 사례로 대비한다.
5. 최신 LLM 논문을 읽을 때 architecture, data, optimizer, normalization, inference cost, safety benchmark 중 어떤 축의 기여인지 먼저 표시한다.

## 복습 질문

<details>
<summary>1. word2vec 표현의 한계가 transformer로 이어지는 이유는 무엇인가?</summary>

답변: word2vec은 같은 단어에 같은 표현을 주므로 문맥에 따라 의미가 달라지는 문제를 충분히 다루지 못한다. RNN은 순차 처리로 문맥을 반영하지만 long-range dependency가 약했고, self-attention은 token 사이의 직접 연결로 이를 보완했다.

</details>

<details>
<summary>2. FlashAttention이 더 많은 재계산을 하면서도 빨라질 수 있는 이유는 무엇인가?</summary>

답변: 병목이 계산량만이 아니라 HBM 같은 큰 느린 메모리와의 read/write이기 때문이다. 일부 중간 결과를 저장하지 않고 SRAM에서 block 단위로 계산하며 필요할 때 재계산하면 memory movement를 줄여 전체 runtime을 줄일 수 있다.

</details>

<details>
<summary>3. GRPO가 PPO보다 reasoning model 학습에 매력적인 이유는 무엇인가?</summary>

답변: GRPO는 value model을 따로 학습하고 유지하지 않아도 되고, math나 coding처럼 정답을 검증할 수 있는 task에서는 reward model 없이 verifiable reward를 사용할 수 있다.

</details>

<details>
<summary>4. Vision Transformer가 convolutional neural network와 대비되는 점은 무엇인가?</summary>

답변: CNN은 sliding window와 같은 강한 vision inductive bias를 갖지만, ViT는 image patch들이 self-attention으로 서로 attend하게 하며 상대적으로 낮은 inductive bias를 갖는다. 충분한 image data가 있으면 이 방식이 잘 동작할 수 있다고 설명된다.

</details>

<details>
<summary>5. Diffusion-based LLM이 autoregressive LLM보다 빠를 수 있는 핵심 이유는 무엇인가?</summary>

답변: autoregressive LLM은 출력 token 수만큼 순차 forward pass가 필요하지만, diffusion LLM은 정해진 수의 diffusion step으로 여러 mask token을 점진적으로 채울 수 있어 긴 출력에서 forward pass 수가 더 적을 수 있다.

</details>

<details>
<summary>6. 강의가 최신 LLM 흐름을 따라가기 위해 제안한 자료원은 무엇인가?</summary>

답변: arXiv, NeurIPS 같은 학회, HuggingFace trending papers, X/Twitter 커뮤니티, Yannic Kilcher와 Andrej Karpathy의 YouTube 자료, company blogs, 그리고 수업 study guide가 언급된다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=Q86qzJ1K1Ss){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
