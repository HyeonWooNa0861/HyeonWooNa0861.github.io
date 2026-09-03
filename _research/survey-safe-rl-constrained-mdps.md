---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Safe RL and CMDPs"
topic: "Safe RL, constrained MDPs, and multi-agent safety"
order: 63
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "safe RL"
  - "constrained MDP"
  - "multi-agent safety"
  - "CMDP"
---

# A Survey of Safe Reinforcement Learning and Constrained MDPs: A Technical Survey on Single-Agent and Multi-Agent Safety

Source PDF: `survey-safe-rl-constrained-mdps.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | A Survey of Safe Reinforcement Learning and Constrained MDPs: A Technical Survey on Single-Agent and Multi-Agent Safety |
| 출처 | arXiv:2505.17342 (submitted 2025-05-22, v2 revised 2026-04-29) |
| 주제 | Safe RL, constrained MDPs, and multi-agent safety |
| 핵심 방법 | CMDP formulation, constrained optimization, safety shields, risk-sensitive methods, and SafeMARL taxonomy |

## 한 줄 요약

이 survey는 SafeRL을 CMDP 기반 제약 최적화 문제로 정식화하고, 이를 single-agent algorithm에서 SafeMARL의 centralized/decentralized/competitive safety 문제까지 확장해 읽을 수 있는 기술 지도를 제공한다.

## 핵심 내용

Safe RL은 cumulative reward를 높이는 동시에 collision, resource budget이나 dosage limit 같은 cost constraint를 만족해야 한다. 이 survey는 이를 CMDP의 reward return과 constraint cost로 분리하고, expected cost·chance constraint·risk measure·temporal logic처럼 서로 다른 safety semantics를 비교한다.

Lagrangian actor-critic, CPO, safety layer와 shielding에서 출발해 centralized·decentralized·competitive SafeMARL까지 방법군을 확장한다. 핵심 의의는 단일 benchmark 순위를 제시하는 것이 아니라, 관측 범위와 agent 상호작용에 따라 어떤 보장과 비용이 필요한지 선택할 기술 지도를 제공한 데 있으며 partial observability와 zero-violation은 여전히 주요 과제다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Foundations | MDP와 CMDP에서 reward return과 cost constraint를 어떻게 분리하는가? |
| 2 | Constraint types | expected cost, chance constraint, risk measure, temporal logic은 무엇이 다른가? |
| 3 | Algorithms | Lagrangian actor-critic, CPO, safety layer, shielding은 어떤 보장을 제공하는가? |
| 4 | SafeMARL | centralized MACPO, decentralized $$\kappa$$-hop learning, competitive equilibrium은 어디서 어려워지는가? |
| 5 | Open problems | zero-violation, partial observability, decentralized/competitive/non-stationary safety를 어떻게 풀 것인가? |

## 한국어 번역형 해설

### 초록과 문제의식

논문은 Safe Reinforcement Learning을 "training과 deployment 동안 safety constraint를 명시적으로 다루는 RL"로 놓고 시작한다. 기본 목표는 cumulative reward를 최대화하면서도 unsafe event probability, resource budget, collision, dosage limit 같은 constraint를 만족하는 policy를 찾는 것이다. 이를 위한 공통 언어가 Constrained Markov Decision Process(CMDP)다.

Survey의 범위는 single-agent SafeRL에 머물지 않는다. 저자들은 CMDP의 정의와 theorem, Lagrangian/linear programming/policy gradient 기반 풀이를 정리한 뒤, CPO와 safety shield 같은 state-of-the-art method를 비교한다. 이어서 multi-agent setting에서는 global constraint, local observation, joint action, competitive objective가 겹치기 때문에 SafeRL 문제가 훨씬 어려워진다고 설명한다.

### CMDP 정식화

기본 MDP는 $$M=(S,A,P,r,\gamma)$$로 쓰며, CMDP는 여기에 cost function $$c^{(i)}(s,a)$$, $$i=1,\ldots,m$$과 threshold $$d_i$$를 추가한다. Policy $$\pi$$의 reward return을 $$J(\pi)$$, $$i$$번째 cost return을 $$J_c^{(i)}(\pi)$$로 두면 SafeRL objective는 다음 형태가 된다.

$$
\max_\pi J(\pi)\quad\text{subject to}\quad J_c^{(i)}(\pi)\le d_i,\ \forall i.
$$

이 정식화는 reward optimization과 safety satisfaction을 명시적으로 분리한다. Penalty reward 하나로 합치면 weight tuning에 따라 constraint를 놓칠 수 있지만, CMDP는 feasible policy set $$\Pi_{\mathrm{safe}}$$ 안에서 reward를 최적화한다는 해석을 제공한다.

Lagrangian 관점에서는 multiplier $$\lambda=(\lambda_1,\ldots,\lambda_m)\ge0$$를 두고

$$
L(\pi,\lambda)=J(\pi)-\sum_i \lambda_i\bigl(J_c^{(i)}(\pi)-d_i\bigr)
$$

를 최적화한다. Constraint가 위반되면 $$\lambda_i$$를 키워 cost penalty를 강화하고, slack이 있으면 penalty를 낮춘다. 논문은 이를 primal-dual update와 occupancy measure 기반 linear programming으로 연결하며, finite CMDP에서는 stationary optimal policy가 존재하고 필요한 경우 deterministic policies 사이의 randomization이 필요할 수 있다고 정리한다.

### 방법군 비교

| 방법군 | 핵심 아이디어 | 강점 | 주의점 |
|---|---|---|---|
| Lagrangian actor-critic | Reward objective에 cost penalty를 붙이고 $$\lambda$$를 online update | 구현이 단순하고 PPO/TRPO/DQN 계열에 붙이기 쉽다 | Convergence 전에는 constraint violation이 발생할 수 있고 $$\lambda$$ tuning이 어렵다 |
| CPO / PCPO | Trust region 안에서 reward improvement와 cost constraint를 동시에 만족하는 update를 계산 | 각 iteration에서 near-constraint satisfaction 보장을 목표로 한다 | Constrained subproblem, cost critic, second-order approximation이 필요해 계산이 무겁다 |
| Safety layer / action correction | Proposed action을 QP, filter, shield로 검사해 가장 가까운 safe action으로 보정 | Immediate violation을 줄이거나 0으로 만들 수 있다 | Dynamics model, learned safety predictor, formal specification 등 외부 안전 모델이 필요하다 |
| Formal shielding | LTL 또는 automata specification에서 unsafe state-action을 pre-compute | Specification에 대한 provable safety가 가능하다 | Abstraction 품질과 state explosion에 의존한다 |
| Risk-sensitive / distributional RL | CVaR, VaR, variance 같은 tail-risk measure를 objective 또는 constraint에 포함 | 평균 cost가 놓치는 rare but severe event를 다룬다 | 고전적 CMDP의 선형 구조를 벗어나는 경우가 많아 전용 알고리즘이 필요하다 |

Survey가 강조하는 관점은 "하나의 SafeRL algorithm이 모든 안전 요구를 대체하지 않는다"는 점이다. Instantaneous constraint, expected cumulative cost, failure probability, risk measure, temporal logic은 서로 다른 failure mode를 잡는다. 따라서 적용 domain의 안전 요구가 어떤 수학적 형태인지 먼저 정해야 한다.

### SafeMARL로 확장될 때의 변화

Multi-agent setting에서는 $$N$$개의 agent가 각자 action $$a_i\in A_i$$를 고르고, joint action $$\mathbf{a}=(a_1,\ldots,a_N)$$이 transition $$P(s'\mid s,\mathbf{a})$$를 만든다. Cooperative SafeMARL에서는 team reward와 global cost를 정의해 하나의 큰 CMDP처럼 풀 수 있지만, joint action space가 agent 수에 따라 빠르게 커진다.

Survey는 세 접근을 구분한다.

- **Centralized training with global constraints**: MACPO처럼 centralized critic이 global reward/cost를 추정하고 joint policy 또는 coordinated update를 수행한다. Team reward의 monotonic improvement와 safety constraint satisfaction을 목표로 하지만 scalability와 central-state access가 병목이다.
- **Decentralized Safe Learning with Coordination**: 각 agent가 $$\kappa$$-hop neighborhood 안의 제한된 정보로 local surrogate constrained problem을 푸는 방향이다. Collision avoidance처럼 global constraint가 additively separable하지 않은 경우 local cost 설계가 핵심 난점이다.
- **Competitive/general-sum SafeMARL**: agent들이 common reward를 공유하지 않을 때는 CPO 같은 single-objective update가 바로 적용되지 않는다. Constrained Nash equilibrium, constrained correlated equilibrium, Stackelberg-style safe RL 같은 game-theoretic solution concept가 필요하다.

### 실험, benchmark, 핵심 수치

이 논문은 새로운 실험 수치를 제시하는 empirical paper가 아니라 survey다. 따라서 "실험 설정"의 핵심은 algorithm/library/benchmark taxonomy다. 논문은 대표 method 표에서 Lagrangian actor-critic, CPO, Lyapunov-based optimization, Reward Constrained DQN, Safe DDPG/TD3, model-based safe RL, safety layer, LTL shielding, MACPO, scalable decentralized SafeMARL, Stackelberg-style SafeMARL, shielded MARL을 비교한다.

재현 가능한 연구 도구로는 OmniSafe, Safe Policy Optimization(SafePO), Safety Starter Agents, Safe-Control-Gym을 언급하고, benchmark로는 Safety-Gymnasium, legacy OpenAI Safety Gym, AI Safety Gridworlds, SafeLife, SMARTS, Highway-env를 분류한다. Open problem은 총 다섯 개이며, 그중 P3-P5 세 개가 SafeMARL에 직접 초점을 둔다.

| Open problem | 범위 | 핵심 난점 |
|---|---|---|
| P1 Zero-violation safe exploration | Single-agent | 초기 학습 중 단 한 번의 catastrophic violation도 허용하지 않는 exploration |
| P2 Safety under partial observability | Single-agent | true safety state를 모르는 POMDP에서 belief 또는 chance constraint로 safety 보장 |
| P3 Decentralized SafeMARL | Multi-agent | central authority 없이 local observation과 제한 통신만으로 global safety 유지 |
| P4 Competitive SafeMARL | Multi-agent | self-interested agents 사이에서 constrained equilibrium 정의와 계산 |
| P5 Non-stationary multi-agent safety | Multi-agent | agent population, dynamics, rules가 변해도 transition 중 safety 유지 |

### 논문 주장과 해석의 경계

논문이 직접 주장하는 것은 SafeRL을 CMDP라는 공통 틀로 설명할 수 있고, CPO/Lagrangian/shielding/risk-sensitive method를 constraint type과 guarantee 수준에 따라 비교해야 한다는 점이다. 또한 SafeMARL은 아직 초기 단계이며, centralized MACPO와 shielding은 가능성을 보였지만 decentralized, competitive, non-stationary scenario에는 일반적 해법이 부족하다고 본다.

내 해석은 이 survey를 "알고리즘 카탈로그"보다 "safety requirement를 수학적 형태로 고르는 guide"로 읽는 편이 더 유용하다는 것이다. 같은 SafeRL이라도 autonomous driving의 collision, healthcare의 dosage limit, finance의 CVaR, temporal logic specification은 서로 다른 constraint family에 속하므로, benchmark 성능보다 먼저 constraint semantics를 고정해야 한다.

### 한계와 확장 방향

한계는 survey의 넓은 범위 자체에서 온다. 각 알고리즘의 implementation detail, benchmark별 failure mode, cost signal 설계의 실전 문제는 깊게 다루기 어렵다. 또한 일부 표는 rapidly changing open-source ecosystem을 정리하므로, library maintenance 상태나 benchmark API 변화는 별도 확인이 필요하다.

확장 방향은 명확하다. 첫째, method taxonomy와 함께 "어떤 safety metric이 어떤 violation을 놓치는지"를 benchmark별 failure catalog로 연결해야 한다. 둘째, SafeMARL에서는 centralized result를 decentralized protocol로 옮길 때 필요한 communication budget, local observability, constraint factorization 조건을 표준화해야 한다. 셋째, non-stationary setting에서는 robust safe RL, runtime monitoring, meta-learned safety critic을 결합해 policy가 더 이상 안전하지 않은 순간을 빠르게 감지하고 안전한 fallback으로 이동하는 절차가 필요하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/survey-safe-rl-constrained-mdps/survey-safe-rl-constrained-mdps.pdf" | relative_url }}" target="_blank" rel="noopener">survey-safe-rl-constrained-mdps.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2505.17342" target="_blank" rel="noopener">arXiv:2505.17342</a></li>
</ul>
