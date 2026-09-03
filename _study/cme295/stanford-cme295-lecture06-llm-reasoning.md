---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-09-03 19:58:44 +0900
title: "Stanford CME295 Lecture 6: LLM Reasoning"
course: "CME295"
topic: "Reasoning Models, Benchmarks, GRPO, and the DeepSeek R1 Training Pipeline"
order: 6
major_topic: "Large Language Models"
keywords:
  - "Chain-of-Thought"
  - "Self-Consistency"
  - "Reasoning Traces"
  - "Tool Use"
  - "Test-Time Compute"
---

# Stanford CME295 Lecture 6: LLM Reasoning

Source: [Stanford CME295 Autumn 2025 Lecture 6](https://www.youtube.com/watch?v=k5Fh-UgTuCo){:target="_blank" rel="noopener"}

> **원문 확인 범위:** 공식 Stanford CME295 강의 영상과 timestamp가 포함된 English transcript를 대조했다. 로컬 CME295 아카이브에는 공식 slide deck 파일이 없으므로 아래 위치는 영상 발화를 기준으로 하며, 보이지 않는 slide나 frame의 내용을 추정하지 않는다.

> **핵심:** 6강은 preference tuning과 RLHF를 바탕으로 reasoning model을 다룬다. 강의는 reasoning을 주로 math나 coding problem처럼 multi-step reasoning process가 필요한 문제를 푸는 능력으로 정의한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | RLHF 복습 | PPO, KL penalty, reward model, SFT reference model은 reasoning training의 어떤 배경이 되는가? |
| 2 | Reasoning 정의 | 단순 지식 질문과 multi-step reasoning problem은 어떻게 다른가? |
| 3 | Reasoning model의 출력 | Vanilla LLM의 answer-only 출력과 reasoning chain plus answer 출력은 무엇이 다른가? |
| 4 | Benchmark와 pass@k | Coding/math benchmark에서 pass@k, temperature, consensus@k는 성능 평가를 어떻게 바꾸는가? |
| 5 | RL로 reasoning 학습 | 왜 reasoning chain SFT보다 verifiable reward를 이용한 RL이 자연스러운 출발점이 되는가? |
| 6 | GRPO | GRPO는 PPO의 value function을 없애고 group-relative advantage를 어떻게 계산하는가? |
| 7 | GRPO 개선 | Output length 증가 문제에서 DAPO, Dr. GRPO, asymmetric epsilon은 어떤 수정 방향을 제시하는가? |
| 8 | DeepSeek R1 pipeline | R1-Zero와 R1은 SFT, RL, cold-start data, rejection sampling, distillation을 어떻게 조합하는가? |

## 핵심 내용

6강은 preference tuning과 RLHF를 바탕으로 reasoning model을 다룬다. 강의는 reasoning을 주로 math나 coding problem처럼 multi-step reasoning process가 필요한 문제를 푸는 능력으로 정의한다. Vanilla LLM은 code/debugging, essay, poem generation에는 강하지만 limited reasoning, static knowledge cutoff, action 부재, free-form text 평가 어려움 같은 약점이 있다고 설명한다. Reasoning model은 바로 answer를 내기보다 reasoning chain을 먼저 생성하고 answer를 내며, chain-of-thought를 큰 규모로 확장한 아이디어와 연결된다. 더 많은 reasoning token은 더 많은 forward pass, 즉 더 많은 compute budget을 뜻한다고 설명된다.

이후에는 reasoning 평가와 학습 방법을 정리한다. Coding benchmark로 HumanEval, CodeForces, SWE-bench가, math benchmark로 AIME와 GSM 8K가 언급된다. pass@k는 k번 시도 중 적어도 하나가 성공할 확률을 추정하는 metric이며, n개 sample 중 c개가 성공했을 때 1 - C(n-c, k) / C(n, k)로 유도된다. Temperature는 낮으면 diverse하지 않고 높으면 token quality가 흔들릴 수 있어 benchmark마다 명시되어야 하며, consensus@k와 self-consistency도 관련 metric으로 소개된다.

강의의 핵심 학습 알고리즘은 GRPO이다. Reasoning chain을 사람이 대량 작성하기 어렵고, code/math는 test case나 ground truth answer로 verifiable reward를 만들 수 있기 때문에 SFT보다 RL이 자연스럽다고 설명한다. GRPO는 PPO처럼 advantage를 maximize하고 old/reference model에서 너무 멀어지지 않게 하지만, value function을 학습하지 않고 같은 prompt에서 여러 completion을 sampling해 group reward의 mean/std와 비교해 advantage를 만든다. DeepSeek R1-Zero는 SFT 없이 pre-trained base model에 verifiable reward와 formatting reward를 적용해 reasoning performance를 올렸고, R1은 cold-start SFT, RL, rejection sampling 기반 SFT, final RL을 결합해 language mixing과 syntax 문제를 줄이고 reasoning/non-reasoning 능력을 함께 맞춘 pipeline으로 설명된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Reasoning model | 질문에 바로 답하지 않고 reasoning chain을 생성한 뒤 answer를 내도록 학습된 LLM. 강의에서는 reasoning plus answer가 출력이라고 설명한다. |
| Chain of thought | 모델이 blanket answer를 내기 전에 문제를 단계별로 풀도록 유도하는 방법. 강의에서는 in-context examples로 reasoning을 보이게 하는 방식으로 복습된다. |
| Compute budget | 모델이 response를 생성하는 데 쓸 수 있는 reasoning/generation budget. 더 많은 token generation은 더 많은 forward pass와 compute를 뜻한다. |
| pass@k | k번 시도 중 적어도 하나가 성공할 확률을 추정하는 metric. 강의에서는 1 - C(n-c,k)/C(n,k)로 유도한다. |
| Consensus@k | 여러 generation 중 가장 많이 나온 answer를 선택하는 metric 또는 방식이며, self-consistency와 관련이 있다고 설명된다. |
| Verifiable reward | Code가 test cases를 통과하는지, math answer가 ground truth와 같은지처럼 model 없이 correctness를 확인할 수 있는 reward signal. |
| GRPO | Group Relative Policy Optimization. 같은 prompt에 대한 여러 completion reward를 group average와 standard deviation으로 normalize해 advantage를 만들고 policy를 학습한다. |
| DAPO / Dr. GRPO | GRPO의 output length 관련 incentive를 다루는 수정 방향. DAPO는 token-level contribution을 equalize하고, Dr. GRPO는 해당 factor를 제거한다고 설명된다. |
| DeepSeek R1-Zero / R1 | R1-Zero는 pre-trained base model에서 바로 RL을 적용한 proof-of-concept이고, R1은 cold-start SFT와 여러 RL/SFT 단계를 섞은 full pipeline이다. |
| Distillation for reasoning | R1 같은 teacher model이 reasoning tokens를 포함한 sample responses를 offline으로 만들고, smaller student model이 그 full sequence를 SFT로 맞추는 방식. |

## 수식 해설: pass@k와 group-relative advantage

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| pass@k estimator | 00:32:17–00:44:29 | At-least-one-pass 정의와 without-replacement 식은 강의 원문이며, complement-counting 전개와 독립 시행 비교는 작성자 보충이다. |
| GRPO relative advantage | 00:58:49–01:07:42 | Group reward를 평균·표준편차로 정규화하는 방식은 강의 원문이며, 퇴화 조건과 절대 품질 한계는 작성자 보충이다. |
| GRPO/PPO objective와 length bias | 01:11:49–01:27:38 | Clipping·KL·normalization과 bias 논의는 강의 원문이며, 아래 수식 해설은 Lecture 5의 유도와 연결한 작성자 보충이다. |

$$n$$개 sample 중 correct가 $$c$$개이고, 중복 없이 $$k$$개를 고른다고 하자. 전체 선택 수는 $$\binom{n}{k}$$, 모두 incorrect일 선택 수는 $$\binom{n-c}{k}$$이므로 complement counting으로

$$
\widehat{\operatorname{pass@k}}
=1-\frac{\binom{n-c}{k}}{\binom{n}{k}}
$$

를 얻는다. 이는 $$0\le k\le n$$인 finite sample에서의 **정확한 조합론적 estimator**다. $$n-c<k$$이면 실패 조합이 없어 값은 1이다. 각 시도를 독립적으로 새로 sampling하고 단일 성공확률이 $$p$$라고 가정하는 population reliability는

$$
P(\text{at least one pass})=1-(1-p)^k
$$

이며, 이는 위의 without-replacement estimator와 가정이 다르다. 상관된 decoding, 중복 answer, test contamination이 있으면 독립식은 실제 reliability를 과대평가할 수 있다.

GRPO가 같은 prompt의 $$G$$개 completion reward $$R_i$$를 표준화할 때 대표 형태는

$$
\bar R=\frac1G\sum_{i=1}^{G}R_i,\qquad
s_R=\sqrt{\frac1G\sum_{i=1}^{G}(R_i-\bar R)^2},\qquad
A_i=\frac{R_i-\bar R}{s_R+\varepsilon}.
$$

이는 group 안에서 mean 0에 가까운 상대 score를 만드는 **정의**이고 물리 단위는 없다. $$s_R=0$$이면 모든 reward가 같아 상대 학습 신호가 없으며 $$\varepsilon$$은 수치 안정화용이다. Advantage가 unbiased하다는 보장이나 group 밖의 절대 quality 보장은 없다.

Completion $$o_i=(o_{i,1},\ldots,o_{i,T_i})$$에 대해 old policy와 current policy의 token ratio를

$$
\rho_{i,t}(\theta)
=\frac{\pi_\theta(o_{i,t}\mid q,o_{i,<t})}
{\pi_{old}(o_{i,t}\mid q,o_{i,<t})}
$$

라 두면, 강의가 설명한 대표적인 GRPO clipped/KL objective는 다음처럼 쓸 수 있다.

$$
J_{GRPO}(\theta)=\mathbb E\!\left[
\frac1G\sum_{i=1}^{G}\frac1{T_i}\sum_{t=1}^{T_i}
\left\{
\min\!\left(\rho_{i,t}A_i,
\operatorname{clip}(\rho_{i,t},1-\epsilon,1+\epsilon)A_i\right)
-\beta\widehat D_{KL,i,t}
\right\}\right].
$$

여기서 $$\epsilon>0$$, $$\beta\ge0$$이고, 한 가지 sampled-token KL estimator는

$$
\widehat D_{KL,i,t}
=\frac{\pi_{ref}(o_{i,t}\mid\cdot)}{\pi_\theta(o_{i,t}\mid\cdot)}
-\log\frac{\pi_{ref}(o_{i,t}\mid\cdot)}{\pi_\theta(o_{i,t}\mid\cdot)}-1\ge0
$$

이다. 마지막 부등식은 $$x-\log x-1\ge0$$에서 온다. 이 세부식은 01:11:49–01:20:35의 ratio·clipping·explicit KL 설명을 완전한 표기로 옮긴 **작성자 보충**이며, 구현마다 KL estimator와 normalization 위치가 다를 수 있다. Importance ratio 분모와 log-ratio가 유한하려면 sampled token에서 관련 probability가 양수여야 한다.

기본식의 $$T_i^{-1}$$는 각 completion을 먼저 평균내므로 동일한 negative advantage에서도 긴 오답의 token당 penalty가 더 작아질 수 있다. 강의 01:21:14–01:25:50의 비교처럼 DAPO식 token-level normalization은 batch/group의 전체 유효 token에 공통 denominator를 사용해 token 기여를 맞추고, Dr.GRPO식 수정은 response별 $$T_i^{-1}$$ factor를 고정 상수 denominator로 대체하거나 제거하는 방향이다. 어느 방식도 길이 bias 제거와 성능 향상을 보편적으로 보장하지 않는다. Reasoning token을 늘리면 항상 정확도가 오른다는 주장도 empirical trend이지 증명이 아니다.

## 학습 포인트

- Reasoning은 강의에서 math/coding problem처럼 multi-step process로 문제를 푸는 능력으로 정의된다.
- Reasoning model은 answer 전에 reasoning chain을 생성하며, 사용자가 보는 thought summary는 raw reasoning chain이 아니라 summary라고 설명된다.
- Reasoning tokens도 output tokens에 포함되어 charge되므로, reasoning ability와 token budget 사이에 효율성 문제가 있다.
- pass@k는 n개 생성 중 c개가 correct일 때 1 - C(n-c, k) / C(n, k)로 추정되며, pass@1은 successful attempt 비율로 단순화된다.
- Reasoning task는 code test cases나 math ground truth answer 같은 verifiable reward가 있어서 reward model 없이 RL을 적용할 수 있다.
- GRPO는 같은 prompt에서 여러 completion을 만들고 reward를 group mean/std와 비교해 advantage를 계산하므로 value function을 학습하지 않는다.
- 기본 GRPO objective의 output length normalization은 long bad outputs를 상대적으로 덜 벌주는 incentive를 만들 수 있어 output length 증가 문제와 연결된다.
- DeepSeek R1-Zero는 RL-only proof-of-concept이고, R1은 cold-start SFT, RL, reasoning/non-reasoning SFT, final RL을 결합한 full reasoning pipeline이다.

## 마지막 핵심 정리

이 강의의 핵심은 `Reasoning model, benchmark, GRPO, DeepSeek R1 계열 학습 파이프라인`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. Reasoning model이 vanilla LLM과 다른 출력 구조를 'question -> reasoning chain -> answer'로 그려 본다.
2. pass@k 유도에서 'at least one correct = 1 - all incorrect' 전환과 sampling without replacement를 직접 계산한다.
3. PPO와 GRPO를 reward, value function, advantage, KL/reference model, train되는 model 수 관점에서 비교한다.
4. GRPO에서 같은 prompt에 대해 여러 completion을 sampling하는 이유와 (reward - mean) / std normalization의 의미를 정리한다.
5. DeepSeek R1-Zero와 R1의 차이를 cold-start SFT 유무, language consistency reward, rejection sampling, final RL 단계로 구분한다.
6. Reasoning token length가 성능 증가와 비용 증가를 동시에 만들 수 있다는 점을 GRPO length issue와 연결해 설명한다.

## 복습 질문

<details markdown="block">
<summary>1. 강의에서 reasoning은 어떻게 정의되는가?</summary>

답변: Math나 coding 문제처럼 여러 단계로 문제를 분해하고 해결해야 하는 능력으로 설명되며, 단순 지식 recall과 구분된다.

</details>

<details markdown="block">
<summary>2. pass@k 공식은 무엇을 추정하는가?</summary>

답변: k개 attempt 중 적어도 하나가 성공할 확률을 추정한다. n개 sample 중 c개가 성공이면 강의에서는 1 - C(n-c,k)/C(n,k)로 유도한다.

</details>

<details markdown="block">
<summary>3. Reasoning training에서 reward model 없이 RL이 가능한 이유는 무엇인가?</summary>

답변: Coding은 test cases, math는 ground truth answer 비교처럼 correctness를 직접 검증할 수 있는 verifiable reward가 있기 때문이다.

</details>

<details markdown="block">
<summary>4. GRPO가 PPO와 가장 크게 다른 점은 무엇인가?</summary>

답변: PPO는 value function을 학습해 advantage를 추정하지만, GRPO는 같은 prompt의 여러 completion reward를 group과 비교해 advantage를 만들기 때문에 value function을 학습하지 않는다.

</details>

<details markdown="block">
<summary>5. DeepSeek R1-Zero의 문제와 R1의 보완 방식은 무엇인가?</summary>

답변: R1-Zero는 RL-only로 reasoning performance를 올렸지만 language mixing과 syntax 문제가 있었다. R1은 human-rewritten cold-start CoT SFT, language consistency reward, rejection sampling 기반 SFT, final RL을 추가해 보완한다.

</details>

<details markdown="block">
<summary>6. Reasoning distillation은 강의에서 어떻게 설명되는가?</summary>

답변: 큰 teacher model인 R1이 thinking tokens를 포함한 responses를 생성하고, 작은 student model이 그 전체 sequence를 SFT로 맞추도록 학습하는 방식이다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=k5Fh-UgTuCo){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
