---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
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

**원본 영상 먼저 보기:** [00:29:55의 Bradley–Terry와 reward-model 설명](https://www.youtube.com/watch?v=PmW_TMQ3l0I&t=1795s){:target="_blank" rel="noopener"}에서 선호·비선호 응답의 reward 차이를 pairwise probability로 바꾸는 과정을 먼저 듣습니다. 아래 RLHF 절은 preference pair→reward model→policy optimization 흐름과 식의 가정을 연결합니다.

<figure>
  <a href="{{ '/assets/images/study/cme295/source-captures/lecture-05-bradley-terry-00h29m55s.jpg' | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ '/assets/images/study/cme295/source-captures/lecture-05-bradley-terry-00h29m55s.jpg' | relative_url }}" alt="두 응답의 reward 차이를 선호 확률로 바꾸는 Bradley-Terry 공식 강의 슬라이드" loading="lazy">
  </a>
  <figcaption><a href="https://www.youtube.com/watch?v=PmW_TMQ3l0I&t=1795s" target="_blank" rel="noopener">공식 영상 00:29:55</a> — 응답 yᵢ가 yⱼ보다 선호될 확률을 두 reward의 지수 비율 또는 reward 차이의 sigmoid로 표현합니다.</figcaption>
</figure>

분모는 두 응답의 상대적인 경쟁을 정규화하고, 마지막 표현은 절대 reward가 아니라 차이 $$r_i-r_j$$만 중요하다는 사실을 드러냅니다. 차이가 0이면 선호 확률은 0.5이고, 선호 응답의 reward가 더 커질수록 확률은 1에 가까워집니다.

> **핵심:** 같은 질문에 둘 다 사실인 답을 썼어도 하나가 더 읽기 쉬울 수 있습니다. 이런 차이는 모범 답 하나를 따라 쓰는 연습만으로 전달하기 어렵습니다. 사람이 두 답 중 어느 쪽을 선호했는지 모은 뒤, 선호를 점수로 배워 모델을 조정하거나(RLHF), 두 답을 직접 비교해 조정할 수 있습니다(DPO).

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 지난 강의 복습 | Pre-training, SFT, LoRA를 거친 모델이 아직 human preference와 맞지 않을 수 있는 이유는 무엇입니까? |
| 2 | Preference data | Pointwise, pairwise, listwise preference 중 왜 pairwise 방식이 많이 쓰입니까? |
| 3 | RL 기본 대응 | RL의 state, action, policy, reward는 LLM generation에서 각각 무엇에 해당합니까? |
| 4 | Reward model | Bradley-Terry formulation은 winning response와 losing response의 score 차이를 어떻게 학습 loss로 바꿉니까? |
| 5 | PPO와 KL | Reward를 높이면서 base model에서 너무 멀어지지 않으려면 advantage, value function, KL divergence가 왜 필요합니까? |
| 6 | Best-of-N | RL training을 생략하고 reward model만 inference에 쓰면 어떤 비용 문제가 생깁니까? |
| 7 | DPO | Direct Preference Optimization은 reward model과 RL loop를 어떻게 supervised preference loss로 대체합니까? |

</details>
## 핵심 내용

SFT를 마친 모델도 어조·친절함·안전성에 대한 사람의 선호와 어긋날 수 있습니다. Preference tuning은 같은 prompt에 대한 선호 응답과 비선호 응답을 비교해 이 차이를 학습합니다. 강의는 pointwise·pairwise·listwise 중 pairwise data가 비교적 다루기 쉽다고 설명합니다. 선호 쌍은 양의 temperature로 여러 completion을 sampling하거나 기존 로그의 나쁜 응답을 다시 쓰는 방식으로 만들 수 있습니다. 평가는 사람, LLM-as-a-Judge 또는 BLEU/ROUGE 같은 지표를 활용할 수 있습니다.

여기서 선호는 사실 정답을 다시 외우게 하는 신호와 다릅니다. 두 응답이 모두 사실을 포함해도 하나는 질문을 직접 해결하고 근거를 분명히 밝히는 반면, 다른 하나는 장황하거나 위험한 지시를 그대로 따를 수 있습니다. 사람은 같은 prompt에 대한 두 답 중 더 나은 쪽을 고르고, preference tuning은 그 비교를 모델의 출력 확률에 반영합니다. 그래서 SFT가 “이 질문에는 이런 답이 있다”를 보여 준다면, 선호학습은 “가능한 답들 중 어떤 답이 더 바람직한가”를 가르칩니다.

강의의 중심은 RLHF입니다. LLM이 문장을 만드는 일을 강화학습의 말로 바꾸면, **state**는 지금까지 읽고 생성한 토큰, **action**은 다음에 고를 토큰, **policy**는 다음 토큰별 확률, **reward**는 완성된 답에 대한 선호 점수입니다. 먼저 reward model이 선호 응답과 비선호 응답을 비교해 점수 매기는 법을 배웁니다. 그 뒤 이 reward model은 고정하고, LLM이 더 높은 점수의 답을 만들도록 출력 확률을 조정합니다. Bradley–Terry 식은 두 점수의 차이를 `어느 답을 더 선호할 확률`로 바꾸며, 정확한 식과 loss는 아래 상세 유도에서 다룹니다.

한 응답은 여러 토큰으로 이루어지지만 보상은 대개 완성된 응답에 매겨집니다. Reward model은 선호 쌍을 보고 각 완성본에 점수를 주는 법을 배우고, policy는 높은 점수를 받을 문장을 만들도록 토큰 확률을 조정합니다. 이때 reward만 무작정 높이면 문장이 원래 언어 모델의 자연스러운 분포에서 벗어날 수 있어, 뒤의 KL penalty가 기준 모델과의 거리를 함께 제한합니다.

후반부는 PPO, Best-of-N, DPO의 trade-off를 비교합니다. PPO는 방금 사용한 policy와 비교해 한 번의 학습으로 토큰 확률이 너무 크게 바뀌지 않게 제한합니다. 별도의 KL penalty는 모델이 원래 SFT/reference model의 말하기 분포에서 지나치게 멀어지지 않게 합니다. 두 제한의 비교 대상이 다르므로 PPO clipping만으로 reference model과 가까움이 보장되지는 않습니다.

Best-of-N은 모델을 다시 학습하지 않고 답을 여러 개 만든 뒤 가장 높은 점수 하나를 고릅니다. 구현은 단순하지만 답을 $$N$$번 생성하므로 시간과 비용이 늘어납니다. DPO는 별도 reward model과 온라인 RL 반복 없이 선호 쌍으로 policy를 직접 학습합니다. 구성은 단순해지지만 선호 데이터와 실제 생성 분포가 달라지는 문제는 남습니다. PPO에는 policy, value function, reward model, reference model 등 구성요소가 많고 reward hacking과 학습 불안정성도 관리해야 합니다.

**Supplementary table — 선호 신호가 policy에 도달하는 경로**

<div markdown="block" role="region" aria-label="Preference tuning signal path comparison" tabindex="0" style="overflow-x: auto;">

| 방법 | 선호 데이터의 사용 경로 | 별도 reward model | Policy를 바꾸는 시점 |
|---|---|---|---|
| RLHF with PPO | Preference pair → reward model → sampled completion reward → PPO update | 필요 | Training 중 online sampling과 policy update |
| Best-of-N | Preference pair → reward model → $$N$$개 completion scoring | 필요 | Policy weight는 바꾸지 않고 inference 결과만 선택 |
| DPO | Preference pair → policy/reference log-probability 차이의 supervised loss | 불필요 | Offline preference training에서 직접 update |
{: .reference-candidate-table style="min-width: 44rem;" }

</div>

표는 강의의 계산 경로를 비교한 작성자 보충입니다. `reward model 불필요`는 DPO가 선호 데이터나 reference policy 없이 동작한다는 뜻이 아닙니다. 이 표의 Best-of-N은 강의에서 다룬 **학습된 preference scorer를 쓰는 설정**이라 reward model을 `필요`로 표시했습니다. 일반적인 Best-of-N은 과제에 따라 규칙 기반 점수나 verifier로 후보를 고를 수도 있으며, 어떤 scorer를 쓰든 생성 횟수만큼 inference 비용이 늘어납니다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Preference pair | 같은 prompt에 대해 선호되는 winning response와 덜 선호되는 losing response를 묶은 학습 단위. |
| RLHF | Reinforcement Learning from Human Feedback. Human preference data로 reward model을 학습한 뒤, 그 reward를 사용해 LLM policy를 tuning하는 절차. |
| Policy $$\pi_\theta(a \mid s)$$ | RL에서 state가 주어졌을 때 action의 확률분포를 뜻하며, LLM에서는 input prefix가 주어졌을 때 next token distribution에 해당합니다. |
| Bradley-Terry formulation | 두 output score ri, rj로 한 output이 다른 output보다 선호될 확률을 exp(ri)/(exp(ri)+exp(rj)) 또는 sigma(ri-rj)로 표현하는 방식. |
| Reward model | Prompt와 completion을 입력받아 그 completion이 얼마나 좋은지 scalar score를 내는 모델. 강의에서는 decoder-only LLM에 classification head를 붙이거나 BERT/CLS 기반으로 만들 수 있다고 합니다. |
| KL divergence | 두 probability distribution이 얼마나 다른지 재는 비대칭 measure. 강의에서는 sum p_i log(p_i/q_i)이고 항상 0 이상이며 P=Q일 때 0이라고 설명합니다. |
| Advantage | 출력이 기대 baseline보다 얼마나 좋은지를 나타내는 quantity. PPO에서는 reward와 value function을 사용해 추정한다고 설명됩니다. |
| PPO-Clip | Current policy와 old policy의 probability ratio를 clipping해 positive/negative advantage에 대한 policy update가 너무 커지지 않게 하는 PPO variant. |
| Best-of-N | 하나의 prompt에 대해 N개 completion을 만들고 reward model로 score한 뒤 최고 score의 completion을 반환하는 inference-time 방법. |
| DPO | Direct Preference Optimization. Reward model 없이 preference pair와 reference model을 사용해 policy를 직접 supervised objective로 preference tune하는 방법. |

## 수식 해설: preference probability, KL, PPO와 DPO

Preference tuning은 winner와 loser의 reward 차이를 선호 확률로 바꾸고, reference policy에서 과도하게 멀어지지 않도록 update를 제한합니다. PPO는 sampling policy 대비 ratio를 clip하고, DPO는 reward-policy 관계를 직접 pairwise classification loss로 바꿉니다.

<details markdown="block">
<summary markdown="span">Derivation: Bradley-Terry, KL, PPO clipping, and DPO</summary>

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Bradley-Terry와 reward-model loss | 00:29:55–00:37:11 | Pairwise probability와 likelihood 전개는 강의 원문이며, logistic 대수식과 modeling assumption 표시는 작성자 보충입니다. |
| KL divergence | 00:55:14–00:57:28 | 정의와 non-negativity·equality 조건은 강의 원문에서 다루며, 아래 log inequality 증명은 작성자 보충 유도입니다. |
| PPO clipping과 KL penalty | 01:03:48–01:14:03 | Ratio·clipping·KL penalty의 역할은 강의 원문이며, 보장 범위와 민감도는 작성자 보충입니다. |
| DPO relation | 01:29:56–01:40:29 | Optimal policy에서 direct preference objective로 가는 흐름은 강의 원문이며, reward-policy 식의 가정과 상수 소거 설명은 작성자 보충입니다. |

Winning/losing response의 scalar reward를 $$r_w,r_l$$라 하면 Bradley-Terry model은

$$
P(y_w\succ y_l)
=\frac{e^{r_w}}{e^{r_w}+e^{r_l}}
=\frac{1}{1+e^{-(r_w-r_l)}}
=\sigma(r_w-r_l)
$$

로 **정의**합니다. 두 번째 등식은 분자·분모를 $$e^{r_w}$$로 나눈 정확한 대수 변형입니다. 관측 label이 win이면 binary cross-entropy는 $$-\log\sigma(r_w-r_l)$$이고, 이를 dataset에서 평균낸 것이 reward-model loss입니다. Reward는 무차원 score이며 score 차이만 probability를 결정합니다. 실제 사람 선호가 이 logistic model을 따른다는 것은 modeling assumption입니다.

Discrete distribution $$P,Q$$에서 $$S=\{i:p_i>0\}$$라 두고 $$i\in S\Rightarrow q_i>0$$라 하면

$$
D_{KL}(P\|Q)=\sum_i p_i\log\frac{p_i}{q_i}\ge0.
$$

증명 개요는 $$\log x\le x-1$$을 쓰는 것입니다.

$$
-D_{KL}(P\|Q)
=\sum_{i\in S} p_i\log\frac{q_i}{p_i}
\le\sum_{i\in S} p_i\left(\frac{q_i}{p_i}-1\right)
=\sum_{i\in S}q_i-1\le0.
$$

마지막 부등식은 $$\sum_{i\in S}p_i=1$$, $$\sum_{i\in S}q_i\le1$$에서 나옵니다. 따라서 KL은 음수가 아니며, equality가 성립하려면 $$Q$$의 질량도 모두 $$S$$에 있고 $$q_i=p_i$$여야 하므로 $$P=Q$$입니다. KL은 비대칭이고 distance metric은 아닙니다.

PPO에서 old policy 대비 ratio는

$$
r_t(\theta)=\frac{\pi_\theta(a_t\mid s_t)}{\pi_{old}(a_t\mid s_t)}
$$

이고 clipped surrogate는

$$
L^{clip}=\mathbb{E}_t\left[
\min\left(r_tA_t,
\operatorname{clip}(r_t,1-\varepsilon,1+\varepsilon)A_t\right)
\right].
$$

Ratio는 exact importance ratio지만 clipping은 큰 update의 이득을 제한하려는 **optimization heuristic**입니다. Monotonic improvement를 보장하는 증명이 아니며 $$\varepsilon$$, advantage error와 sampling distribution에 민감합니다.

DPO는 KL-regularized reward optimum의 관계

$$
r(x,y)=\beta\log\frac{\pi_\theta(y\mid x)}{\pi_{ref}(y\mid x)}+C(x),
\qquad \beta>0
$$

를 Bradley-Terry model에 대입합니다. 같은 prompt $$x$$의 winner와 loser를 빼면 $$C(x)$$가 소거되어

$$
r(x,y_w)-r(x,y_l)
=\beta\left[
\log\frac{\pi_\theta(y_w\mid x)}{\pi_{ref}(y_w\mid x)}
-\log\frac{\pi_\theta(y_l\mid x)}{\pi_{ref}(y_l\mid x)}
\right]
=\beta\Delta_\theta
$$

가 됩니다. 따라서 dataset $$\mathcal D$$에 대한 explicit DPO loss는

$$
\mathcal L_{DPO}(\theta)
=-\mathbb E_{(x,y_w,y_l)\sim\mathcal D}
\left[\log\sigma(\beta\Delta_\theta)\right].
$$

이는 01:34:47–01:38:21의 optimal-policy 재배열과 Bradley-Terry substitution을 식으로 적은 **작성자 보충 유도**입니다. Log-ratio가 유한하려면 관측 response에 대해 policy와 reference probability가 양수여야 합니다. $$\beta$$가 KL 제약과 loss의 선호 강도를 연결하는 convention은 논문 표기마다 역수 형태로 나타날 수 있으므로 식을 섞지 않아야 합니다. 이 유도는 reward-policy relation과 pairwise logistic preference model을 가정하며, arbitrary distribution shift에서 PPO와 동등하다는 보장은 아닙니다.

</details>

## 학습 포인트

- Preference tuning은 SFT 이후 모델을 human preference, tone, friendliness, safety 같은 기준에 더 맞추는 단계입니다.
- Pairwise preference data는 같은 prompt에 대해 더 선호되는 response와 덜 선호되는 response를 비교하는 형태이며, binary scale이 자주 쓰입니다.
- RLHF에서 Human Feedback은 reward model을 학습시키는 preference labels가 human ratings에서 온다는 뜻입니다.
- Reward model은 pairwise loss로 학습되지만 inference에서는 prompt와 하나의 response를 입력받아 pointwise score를 출력합니다.
- Bradley-Terry formulation은 P(yi > yj)를 sigma(ri - rj)로 표현하고, winning score가 losing score보다 높아지도록 학습합니다.
- PPO clipping의 기준은 sampling에 사용한 old policy입니다. RLHF의 별도 KL penalty는 고정 reference/SFT policy와 비교합니다. 두 장치가 안정성을 돕지만 큰 update나 reward hacking을 완전히 막는 보장은 아닙니다.
- Reward hacking은 imperfect reward를 과도하게 optimize해서 실제 objective를 놓치는 현상으로 설명됩니다.
- DPO는 preference pairs를 직접 supervised loss로 학습하므로 단순하지만, PPO와 비교해 성능과 distribution shift trade-off가 있습니다.

## 마지막 핵심 정리

이 강의의 핵심은 `Preference tuning, RLHF, PPO, Best-of-N, DPO`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것입니다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

1. Preference tuning이 SFT와 다르게 negative signal을 줄 수 있다는 점을 teddy bear 예시로 설명해 봅니다.
2. Bradley-Terry probability와 -E log sigma(r_w-r_l) loss가 어떻게 연결되는지 단계별로 다시 써 봅니다.
3. Reward model은 pairwise로 학습되지만 pointwise로 score한다는 문장을 예시와 함께 외웁니다.
4. PPO에서 old policy, reference/base model, reward model, value function이 각각 어떤 역할인지 구분합니다.
5. RLHF, Best-of-N, DPO를 training cost, inference cost, model component 수, stability 관점에서 비교합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Preference tuning은 SFT 이후 어떤 문제를 해결하려고 합니까?</summary>

답변: SFT model이 task를 수행할 수 있어도 tone, safety, friendliness 등 human preference와 맞지 않는 출력을 할 수 있으므로, 선호되는 출력 쪽으로 policy를 조정합니다.

</details>

<details markdown="block">
<summary>2. RLHF의 두 단계는 무엇입니까?</summary>

답변: 먼저 preference pair로 reward model을 학습해 good/bad output을 구분하고, 이후 그 reward model을 사용해 LLM policy를 reinforcement learning으로 tuning합니다.

</details>

<details markdown="block">
<summary>3. Bradley-Terry formulation에서 winning response의 score는 어떤 방향으로 학습됩니까?</summary>

답변: Winning response의 reward score r_w가 losing response의 r_l보다 커져 sigma(r_w-r_l)가 1에 가까워지도록 학습됩니다.

</details>

<details markdown="block">
<summary>4. PPO에서 KL divergence 또는 clipping을 쓰는 이유는 무엇입니까?</summary>

답변: Clipping은 current policy와 sampling에 사용한 old policy의 확률비를 기준으로 큰 변화의 목적함수상 이득을 제한합니다. 별도의 KL penalty는 current policy가 고정 reference/SFT policy에서 멀어지는 데 비용을 부과합니다. 비교 대상이 다르므로 둘은 대체 가능한 같은 장치가 아니며, 어느 쪽도 지식 손실이나 reward hacking을 완전히 막는 보장은 아닙니다.

</details>

<details markdown="block">
<summary>5. DPO가 RLHF보다 단순한 이유는 무엇입니까?</summary>

답변: Reward model과 value function을 별도로 학습하거나 on-policy RL loop를 돌리지 않고, preference pair와 reference model을 사용해 policy loss를 직접 최적화하기 때문입니다.

</details>

## 참고자료

- 자료 확인 범위: 공식 Stanford CME295 강의 영상과 영문 전사를 대조했습니다. 공식 슬라이드는 없어 화면에 보이지 않는 내용은 추정하지 않았습니다.

- [강의 영상](https://www.youtube.com/watch?v=PmW_TMQ3l0I){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
