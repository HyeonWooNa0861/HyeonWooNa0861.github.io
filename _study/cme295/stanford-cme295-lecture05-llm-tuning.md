---
layout: default
date: 2026-08-12 10:07:20 +0900
title: "Stanford CME295 Lecture 5: LLM tuning"
course: "CME295"
topic: "Preference tuning, RLHF, PPO, Best-of-N, DPO"
order: 5
major_topic: "Large Language Models"
keywords:
  - "Instruction Tuning"
  - "SFT"
  - "RLHF"
  - "DPO"
  - "Preference Data"
---

# Stanford CME295 Lecture 5: LLM tuning

Source: [Stanford CME295 Autumn 2025 Lecture 5](https://www.youtube.com/watch?v=PmW_TMQ3l0I){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 지난 강의 복습 | Pre-training, SFT, LoRA를 거친 모델이 아직 human preference와 맞지 않을 수 있는 이유는 무엇인가? |
| 2 | Preference data | Pointwise, pairwise, listwise preference 중 왜 pairwise 방식이 많이 쓰이는가? |
| 3 | RL 기본 대응 | RL의 state, action, policy, reward는 LLM generation에서 각각 무엇에 해당하는가? |
| 4 | Reward model | Bradley-Terry formulation은 winning response와 losing response의 score 차이를 어떻게 학습 loss로 바꾸는가? |
| 5 | PPO와 KL | Reward를 높이면서 base model에서 너무 멀어지지 않으려면 advantage, value function, KL divergence가 왜 필요한가? |
| 6 | Best-of-N | RL training을 생략하고 reward model만 inference에 쓰면 어떤 비용 문제가 생기는가? |
| 7 | DPO | Direct Preference Optimization은 reward model과 RL loop를 어떻게 supervised preference loss로 대체하는가? |

## 핵심 내용

5강은 pre-training과 SFT 이후의 preference tuning을 중심으로 진행된다. SFT model은 assistant처럼 동작할 수 있지만 tone, friendliness, safety 같은 human preference와 완전히 맞지 않을 수 있다. 이를 위해 prompt에 대한 winning response와 losing response를 모은 preference pair를 만들고, pointwise/listwise보다 pairwise preference data가 일반적으로 다루기 쉽다고 설명한다. Pair는 positive temperature로 여러 completion을 sampling하거나, 로그에서 나쁜 응답을 찾아 좋은 응답으로 rewrite하는 방식으로 만들 수 있으며, rating은 human, LLM-as-a-judge, BLEU/ROUGE 같은 metric으로 얻을 수 있다.

강의의 중심은 RLHF이다. 전통적인 RL의 agent, state, action, policy, reward를 LLM에 대응시키면 agent는 LLM, state는 지금까지의 input, action은 next token, policy는 next-token probability distribution, reward는 completion에 대한 preference signal이다. RLHF는 먼저 preference pair로 reward model을 학습하고, 그 frozen reward model을 사용해 SFT model의 policy를 더 높은 reward 쪽으로 조정한다. Reward model 학습에는 Bradley-Terry formulation이 쓰이며, P(yi > yj) = exp(ri) / (exp(ri) + exp(rj)) = sigma(ri - rj), loss는 -E log sigma(r_w - r_l) 형태로 설명된다.

후반부는 PPO, Best-of-N, DPO의 trade-off를 비교한다. PPO는 advantage를 maximize하면서 base/reference model과 너무 멀어지지 않도록 KL divergence나 clipping을 사용하지만, policy, value function, reward model, base model 등 많은 model component와 hyperparameter가 필요하고 reward hacking, instability, exploration 문제가 있다. Best-of-N은 RL training을 건너뛰고 inference에서 여러 completion을 reward model로 score해 최고를 고르지만 latency와 cost가 커진다. DPO는 Direct Preference Optimization으로, reward model 없이 preference pair에 대한 supervised loss를 직접 최적화해 policy와 reference model 두 개만 쓰지만, 강의에서는 PPO가 보통 더 높은 성능을 줄 수 있고 DPO에는 distribution shift 문제가 있다고 정리한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Preference pair | 같은 prompt에 대해 선호되는 winning response와 덜 선호되는 losing response를 묶은 학습 단위. |
| RLHF | Reinforcement Learning from Human Feedback. Human preference data로 reward model을 학습한 뒤, 그 reward를 사용해 LLM policy를 tuning하는 절차. |
| Policy pi_theta(a|s) | RL에서 state가 주어졌을 때 action의 확률분포를 뜻하며, LLM에서는 input prefix가 주어졌을 때 next token distribution에 해당한다. |
| Bradley-Terry formulation | 두 output score ri, rj로 한 output이 다른 output보다 선호될 확률을 exp(ri)/(exp(ri)+exp(rj)) 또는 sigma(ri-rj)로 표현하는 방식. |
| Reward model | Prompt와 completion을 입력받아 그 completion이 얼마나 좋은지 scalar score를 내는 모델. 강의에서는 decoder-only LLM에 classification head를 붙이거나 BERT/CLS 기반으로 만들 수 있다고 한다. |
| KL divergence | 두 probability distribution이 얼마나 다른지 재는 비대칭 measure. 강의에서는 sum p_i log(p_i/q_i)이고 항상 0 이상이며 P=Q일 때 0이라고 설명한다. |
| Advantage | 출력이 기대 baseline보다 얼마나 좋은지를 나타내는 quantity. PPO에서는 reward와 value function을 사용해 추정한다고 설명된다. |
| PPO-Clip | Current policy와 old policy의 probability ratio를 clipping해 positive/negative advantage에 대한 policy update가 너무 커지지 않게 하는 PPO variant. |
| Best-of-N | 하나의 prompt에 대해 N개 completion을 만들고 reward model로 score한 뒤 최고 score의 completion을 반환하는 inference-time 방법. |
| DPO | Direct Preference Optimization. Reward model 없이 preference pair와 reference model을 사용해 policy를 직접 supervised objective로 preference tune하는 방법. |

## 학습 포인트

- Preference tuning은 SFT 이후 모델을 human preference, tone, friendliness, safety 같은 기준에 더 맞추는 단계다.
- Pairwise preference data는 같은 prompt에 대해 더 선호되는 response와 덜 선호되는 response를 비교하는 형태이며, binary scale이 자주 쓰인다.
- RLHF에서 Human Feedback은 reward model을 학습시키는 preference labels가 human ratings에서 온다는 뜻이다.
- Reward model은 pairwise loss로 학습되지만 inference에서는 prompt와 하나의 response를 입력받아 pointwise score를 출력한다.
- Bradley-Terry formulation은 P(yi > yj)를 sigma(ri - rj)로 표현하고, winning score가 losing score보다 높아지도록 학습한다.
- PPO는 advantage를 maximize하면서 clipping 또는 KL penalty로 policy update가 너무 커지지 않도록 한다.
- Reward hacking은 imperfect reward를 과도하게 optimize해서 실제 objective를 놓치는 현상으로 설명된다.
- DPO는 preference pairs를 직접 supervised loss로 학습하므로 단순하지만, PPO와 비교해 성능과 distribution shift trade-off가 있다.

## 마지막 핵심 정리

이 강의의 핵심은 `Preference tuning, RLHF, PPO, Best-of-N, DPO`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. Preference tuning이 SFT와 다르게 negative signal을 줄 수 있다는 점을 teddy bear 예시로 설명해 본다.
2. Bradley-Terry probability와 -E log sigma(r_w-r_l) loss가 어떻게 연결되는지 단계별로 다시 써 본다.
3. Reward model은 pairwise로 학습되지만 pointwise로 score한다는 문장을 예시와 함께 외운다.
4. PPO에서 old policy, reference/base model, reward model, value function이 각각 어떤 역할인지 구분한다.
5. RLHF, Best-of-N, DPO를 training cost, inference cost, model component 수, stability 관점에서 비교한다.

## 복습 질문

<details>
<summary>1. Preference tuning은 SFT 이후 어떤 문제를 해결하려는가?</summary>

답변: SFT model이 task를 수행할 수 있어도 tone, safety, friendliness 등 human preference와 맞지 않는 출력을 할 수 있으므로, 선호되는 출력 쪽으로 policy를 조정한다.

</details>

<details>
<summary>2. RLHF의 두 단계는 무엇인가?</summary>

답변: 먼저 preference pair로 reward model을 학습해 good/bad output을 구분하고, 이후 그 reward model을 사용해 LLM policy를 reinforcement learning으로 tuning한다.

</details>

<details>
<summary>3. Bradley-Terry formulation에서 winning response의 score는 어떤 방향으로 학습되는가?</summary>

답변: Winning response의 reward score r_w가 losing response의 r_l보다 커져 sigma(r_w-r_l)가 1에 가까워지도록 학습된다.

</details>

<details>
<summary>4. PPO에서 KL divergence 또는 clipping을 쓰는 이유는 무엇인가?</summary>

답변: Reward를 높이는 방향으로 update하되, SFT/base model이나 직전 policy에서 너무 멀어져 지식 손실, reward hacking, instability가 생기지 않도록 제한하기 위해서다.

</details>

<details>
<summary>5. DPO가 RLHF보다 단순한 이유는 무엇인가?</summary>

답변: Reward model과 value function을 별도로 학습하거나 on-policy RL loop를 돌리지 않고, preference pair와 reference model을 사용해 policy loss를 직접 최적화하기 때문이다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=PmW_TMQ3l0I){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
