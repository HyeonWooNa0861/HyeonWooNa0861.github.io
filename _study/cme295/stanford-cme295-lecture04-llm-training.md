---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-09-03 19:58:44 +0900
title: "Stanford CME295 Lecture 4: LLM Training"
course: "CME295"
topic: "LLM Pretraining, Training Optimization, Supervised Fine-Tuning, and LoRA"
order: 4
major_topic: "Large Language Models"
keywords:
  - "Pretraining"
  - "Data Curation"
  - "Tokenization"
  - "Distributed Training"
  - "Loss Scaling"
---

# Stanford CME295 Lecture 4: LLM Training

Source: [Stanford CME295 Autumn 2025 Lecture 4](https://www.youtube.com/watch?v=VlA_jt_3Qc4){:target="_blank" rel="noopener"}

> **원문 확인 범위:** 공식 Stanford CME295 강의 영상과 timestamp가 포함된 English transcript를 대조했다. 로컬 CME295 아카이브에는 공식 slide deck 파일이 없으므로 아래 위치는 영상 발화를 기준으로 하며, 보이지 않는 slide나 frame의 내용을 추정하지 않는다.

> **핵심:** 4강은 전통적인 작업별 모델 학습에서 전이학습 기반 LLM 학습으로 넘어가는 흐름을 설명한다. 사전학습은 거대한 텍스트와 코드 말뭉치에서 다음 토큰을 예측하도록 학습하는 가장 비싼 단계이며, Common Crawl, Wikipedia, Reddit, GitHub, Stack Overflow 같은 출처가 언급된다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 강의 3 복습 | Mixture of Experts, decoding 방법, KV cache가 LLM inference에서 어떤 역할을 했는가? |
| 2 | 전이학습과 사전학습 | 왜 작업마다 새 모델을 처음부터 학습하지 않고 pre-trained model을 tuning하는가? |
| 3 | 스케일링과 compute | FLOPs, FLOPS, token 수, parameter 수, Chinchilla law는 사전학습 설계에 어떤 기준을 주는가? |
| 4 | 분산 학습 | Forward/backward/optimizer state가 GPU 메모리를 압박할 때 data parallelism, ZeRO, model parallelism은 무엇을 나누는가? |
| 5 | FlashAttention | HBM과 SRAM의 read/write 병목을 줄이면 attention을 근사 없이 어떻게 더 빠르게 계산할 수 있는가? |
| 6 | 정밀도와 quantization | FP32, FP16, BF16, mixed precision, quantization은 메모리와 속도를 어떻게 바꾸는가? |
| 7 | SFT와 LoRA | Pre-trained autocomplete model을 assistant로 바꾸려면 어떤 supervised data와 parameter-efficient tuning이 필요한가? |

## 핵심 내용

4강은 전통적인 작업별 모델 학습에서 전이학습 기반 LLM 학습으로 넘어가는 흐름을 설명한다. 사전학습은 거대한 텍스트와 코드 말뭉치에서 다음 토큰을 예측하도록 학습하는 가장 비싼 단계이며, Common Crawl, Wikipedia, Reddit, GitHub, Stack Overflow 같은 출처가 언급된다. 데이터 규모는 수천억에서 수십조 토큰까지 갈 수 있고, GPT-3는 300B 토큰, Llama 3는 15T 토큰으로 예시화된다. 강의는 FLOPs와 FLOPS를 구분하고, 학습 비용이 토큰 수와 파라미터 수에 대략 비례하며, Chinchilla law처럼 고정 compute에서 파라미터 수와 학습 토큰 수의 균형이 중요하다고 설명한다.

이후에는 실제 대규모 학습을 가능하게 하는 시스템 기법이 이어진다. forward pass의 activation, backward pass의 gradient, Adam의 first/second moment optimizer state가 GPU 메모리를 차지하므로 data parallelism, ZeRO 1/2/3, expert/tensor/pipeline parallelism 같은 분산 기법이 필요하다. FlashAttention은 HBM과 SRAM의 속도 차이를 이용해 attention 계산의 HBM read/write를 줄이고, tiling과 recomputation으로 exact attention을 더 빠르고 메모리 효율적으로 만든다.

마지막 부분은 사전학습 모델을 유용한 assistant로 만드는 SFT와 instruction tuning을 다룬다. SFT는 입력에는 loss를 걸지 않고 출력 토큰 예측을 학습하며, story writing, list generation, explanation, code, math, safety refusal 같은 고품질 instruction data를 사용한다. 데이터 규모는 pre-training보다 훨씬 작고, 평가와 prompt distribution 관리가 어렵다. 이어서 LoRA는 frozen pre-trained weight W0에 낮은 rank의 BA 업데이트만 학습하는 방식으로 fine-tuning 비용을 줄이며, QLoRA는 frozen weight를 NF4로 quantize하고 A/B는 BF16으로 학습해 큰 VRAM 절감을 얻는 방법으로 소개된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Transfer learning | 새 작업마다 처음부터 학습하지 않고 pre-trained model을 시작점으로 삼아 특정 task에 맞게 tuning하는 패러다임. |
| Pre-training | 대규모 text/code corpus에서 다음 토큰을 예측하도록 LLM을 학습해 language와 code 구조를 배우게 하는 단계. |
| FLOPs / FLOPS | FLOPs는 floating point 연산량이고, FLOPS는 초당 floating point 연산 속도다. 강의는 두 표기가 논문에서 혼동될 수 있다고 지적한다. |
| Chinchilla law | 고정 compute에서 parameter 수와 training token 수의 균형을 잡아야 하며, token 수가 model size의 약 20배일 때 optimal하다고 소개된 관계. |
| ZeRO | Zero Redundancy Optimization. Data parallel setup에서 optimizer state, gradient, parameter를 GPU들에 partition해 redundancy를 줄이는 방법. |
| FlashAttention | Attention 계산을 block 단위로 SRAM에서 처리해 HBM read/write를 줄이는 IO-aware exact attention 최적화. |
| Mixed precision training | Weights는 FP32처럼 높은 precision으로 유지하고 forward/backward 계산은 FP16 같은 낮은 precision으로 수행해 memory와 speed를 개선하는 학습법. |
| SFT / Instruction tuning | Supervised Fine Tuning. 입력 instruction에 대해서 원하는 assistant response를 출력하도록 학습하며, 입력 구간에는 loss를 걸지 않는다고 설명된다. |
| LoRA | Pre-trained weight W0는 freeze하고 low-rank product BA만 학습하는 parameter-efficient fine-tuning 기법. |
| QLoRA / NF4 | Frozen base weights를 NF4 같은 quantized format으로 저장하고 LoRA matrices는 BF16으로 학습해 fine-tuning memory footprint를 크게 낮추는 방식. |

## 수식 해설: pre-training loss와 LoRA

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Next-token pre-training과 SFT masking | 00:10:36–00:10:55, 01:07:00–01:08:31 | Next-token objective와 response 구간 loss는 강의 원문이며, NLL·chain-rule 표기는 작성자 보충 유도다. |
| Chinchilla scaling rule | 00:19:23–00:19:51 | 약 $$20N$$ token이라는 경험적 규칙은 강의 원문이다. $$C\approx kND$$와 적용 한계는 작성자 보충이다. |
| FlashAttention과 online softmax | 00:38:35–00:51:40 | Tiling, exactness, iterative correction, recomputation은 강의 원문이며, 강의가 생략했다고 밝힌 recurrence는 아래 작성자 보충이다. |
| LoRA low-rank update | 01:37:56–01:42:33 | Frozen weight에 low-rank 곱을 더하는 구조는 강의 원문이며, shape·parameter 비율 계산은 작성자 보충이다. |

Next-token pre-training은 sequence $$x_{1:T}$$의 negative log-likelihood를 최소화한다.

$$
\mathcal{L}_{\mathrm{NLL}}
=-\sum_{t=1}^{T}\log p_\theta(x_t\mid x_{<t}).
$$

이는 autoregressive chain rule $$\log p_\theta(x_{1:T})=\sum_t\log p_\theta(x_t\mid x_{<t})$$에 음수를 붙인 **정확한 maximum-likelihood objective**다. $$T,t$$는 무차원 token count/index이고 loss는 nats이며, 밑 2 로그를 쓰면 bits가 된다. SFT에서 prompt token을 masking하면 같은 합을 response position에만 적용한다. Data가 실제 target distribution의 유한 sample이라는 점과 optimization이 global optimum에 도달하지 않을 수 있다는 점은 별도 한계다.

LoRA는 frozen weight $$W_0\in\mathbb{R}^{d_{out}\times d_{in}}$$에

$$
W=W_0+\Delta W,
\qquad
\Delta W=BA,
$$

$$
B\in\mathbb{R}^{d_{out}\times r},\qquad
A\in\mathbb{R}^{r\times d_{in}}
$$

을 더하는 parameterization이다. Full update는 $$d_{out}d_{in}$$개를 학습하지만 LoRA는 $$r(d_{out}+d_{in})$$개만 학습하므로 감소 비율은

$$
\frac{r(d_{out}+d_{in})}{d_{out}d_{in}}.
$$

이는 정확한 parameter count다. $$r<\min(d_{out},d_{in})$$이어야 low-rank 절감이 의미 있고, 필요한 update가 작은 rank로 잘 근사된다는 것은 task-dependent assumption이다.

Training compute가 parameter 수 $$N$$과 token 수 $$D$$에 대략 비례한다는 $$C\approx kND$$, 그리고 $$D\approx20N$$ 같은 Chinchilla rule은 측정된 regime의 **empirical scaling relation**이다. 상수 $$k$$, optimal ratio는 architecture, optimizer, data quality, hardware accounting에 따라 달라지므로 대수적으로 증명되는 보편 법칙으로 취급하지 않는다.

FlashAttention의 exactness는 softmax 한 행을 block별로 합치는 recurrence로 확인할 수 있다. 지금까지 본 score의 running maximum, exponential sum, value numerator를 각각 $$m,\ell,u$$라 하고 초기값을 $$m=-\infty,\ell=0,u=0$$으로 둔다. 새 block의 score/value를 $$(s_j,v_j)$$라 하고 $$m_B=\max_j s_j$$라 하면

$$
m'=\max(m,m_B),
$$

$$
\ell'=e^{m-m'}\ell+\sum_{j\in B}e^{s_j-m'},
\qquad
u'=e^{m-m'}u+\sum_{j\in B}e^{s_j-m'}v_j.
$$

마지막 output은 $$u'/\ell'$$다. 이전 항에 $$e^{m-m'}$$를 곱하면 모든 항이 새 maximum $$m'$$ 기준으로 다시 scale되므로, block을 모두 처리한 뒤 $$u/\ell=\sum_j e^{s_j}v_j/\sum_j e^{s_j}$$가 된다. 따라서 real arithmetic에서는 vanilla softmax attention과 같은 결과를 내면서 전체 score matrix를 HBM에 materialize하지 않을 수 있다. 이는 00:46:33–00:48:53에서 강의가 “slide에 식을 넣지 않았다”고 명시한 부분의 **작성자 보충 유도**다. 한 행에 unmasked finite score가 하나 이상 있어 $$\ell>0$$이어야 한다. 실제 floating-point에서는 reduction 순서와 rounding이 달라 bitwise equality는 보장되지 않으며, dropout·mask·causal block 경계도 kernel에서 같은 의미로 적용해야 한다.

## 학습 포인트

- Pre-training은 거대한 text/code 데이터로 next token prediction을 학습하는 LLM training의 가장 비용 큰 단계다.
- Common Crawl은 인터넷 페이지, Wikipedia, Reddit, code source 등 다양한 데이터를 포함하는 대표적인 pre-training source로 설명된다.
- GPT-3는 300B tokens, Llama 3는 15T tokens로 예시되며, 데이터 규모는 수천억에서 수십조 토큰까지 간다.
- FLOPs는 floating operations의 양, FLOPS는 floating point operations per second라는 compute speed를 뜻한다.
- Chinchilla law는 training set size가 model size의 약 20배일 때 compute를 더 optimal하게 쓴다는 관찰로 설명된다.
- ZeRO는 optimizer state, gradient, parameter redundancy를 sharding해 GPU별 memory load를 줄이지만 communication cost를 늘린다.
- FlashAttention은 tiling과 SRAM 활용으로 HBM IO를 줄이는 exact attention 기법이며, recomputation으로 activation memory도 줄인다.
- LoRA는 W0를 freeze하고 low-rank matrices A와 B만 학습하며, QLoRA는 NF4와 double quantization으로 추가 VRAM 절감을 노린다.

## 마지막 핵심 정리

이 강의의 핵심은 `LLM 사전학습, 학습 최적화, 지도 미세조정과 LoRA`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. Pre-training, SFT, preference tuning이 각각 무엇을 학습시키는지 한 문장씩 구분해 정리한다.
2. FLOPs와 FLOPS의 차이를 말로 설명하고, 왜 GPU spec과 LLM training cost discussion에서 둘 다 등장하는지 확인한다.
3. Forward pass, backward pass, optimizer update에서 저장해야 하는 activation, gradient, optimizer state를 표로 정리한다.
4. Data parallelism, ZeRO, model parallelism이 각각 data, state, layer/tensor/expert 중 무엇을 나누는지 비교한다.
5. LoRA 식 W = W0 + BA의 각 항이 freeze되는지 학습되는지, rank R이 parameter 수를 어떻게 줄이는지 직접 계산해 본다.

## 복습 질문

<details markdown="block">
<summary>1. Pre-training 데이터 규모와 목적은 무엇인가?</summary>

답변: 거대한 text/code corpus에서 next token prediction을 학습해 language와 code 구조를 배우는 단계이며, 강의에서는 수천억에서 수십조 token 규모를 언급한다.

</details>

<details markdown="block">
<summary>2. ZeRO 1, 2, 3의 핵심 아이디어는 무엇인가?</summary>

답변: Data parallelism에서 중복 저장되는 optimizer state, gradient, parameter를 단계적으로 partition해 GPU별 memory load를 줄이는 것이다.

</details>

<details markdown="block">
<summary>3. FlashAttention은 attention 계산을 근사하는가?</summary>

답변: 아니다. 강의에서는 exact computation이며 HBM과 SRAM 사이의 IO를 줄이는 tiling과 recomputation 전략이라고 설명한다.

</details>

<details markdown="block">
<summary>4. SFT에서 입력 instruction 구간에는 왜 loss를 걸지 않는가?</summary>

답변: 모델이 사용자 입력을 그대로 따라 쓰게 하려는 것이 아니라, 그 입력에 조건화된 이후의 output token을 예측하도록 학습하기 때문이다.

</details>

<details markdown="block">
<summary>5. LoRA가 fine-tuning 비용을 줄이는 방식은 무엇인가?</summary>

답변: 기존 weight W0를 freeze하고 작은 rank R을 가진 matrices A와 B만 학습해 task-specific update를 표현하므로 학습 parameter 수가 크게 줄어든다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=VlA_jt_3Qc4){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
