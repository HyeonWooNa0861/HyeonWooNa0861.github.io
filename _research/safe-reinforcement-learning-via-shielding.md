---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Shielded RL"
topic: "Formal-methods shielding for safe reinforcement learning"
order: 62
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "safe RL"
  - "shielding"
  - "formal methods"
  - "runtime safety"
---

# Safe Reinforcement Learning via Shielding

Source PDF: `safe-reinforcement-learning-via-shielding.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Safe Reinforcement Learning via Shielding |
| 출처 | AAAI Conference on Artificial Intelligence, 2018 |
| 주제 | Formal-methods shielding for safe reinforcement learning |
| 핵심 방법 | Reactive synthesis로 만든 preemptive/post-posed shield가 unsafe action을 차단하거나 교정 |

## 한 줄 요약

이 논문은 reward penalty만으로 안전을 학습하게 두지 않고, temporal logic safety specification과 MDP abstraction에서 합성한 shield를 RL loop에 붙여 학습 중과 실행 중의 unsafe action을 막는 구조를 제안한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Safety specification | "나쁜 일이 일어나지 않음"을 LTL safety fragment와 safety automaton으로 어떻게 표현하는가? |
| 2 | Environment abstraction | 실제 MDP를 전부 알지 못해도 unsafe action을 미리 판단할 coarse abstraction을 어떻게 쓰는가? |
| 3 | Shield synthesis | specification automaton과 abstraction의 product safety game에서 winning region을 어떻게 계산하는가? |
| 4 | RL integration | preemptive shield와 post-posed shield가 learning/convergence와 어떻게 공존하는가? |
| 5 | Experiments | grid world, self-driving car, Seaquest, water tank에서 safety와 reward learning이 어떻게 달라지는가? |

## 한국어 번역형 해설

### 초록과 문제의식

저자들의 출발점은 명확하다. RL algorithm은 장기 reward를 maximize하는 policy를 찾을 수 있지만, 학습 도중 또는 배포 후 실행 도중에 safety property를 반드시 만족한다는 보장은 없다. 특히 physical system, autonomous driving, robotics처럼 한 번의 violation이 비용이 큰 환경에서는 "unsafe state를 경험하고 나서 penalty로 배우는" 방식 자체가 허용되지 않는다.

논문은 안전을 reward shaping 안에 묻지 않고 별도 control layer로 분리한다. 사용자가 지켜야 할 조건을 temporal logic, 특히 safety fragment로 쓰고, 이 specification과 환경 dynamics의 conservative abstraction에서 reactive system인 shield를 합성한다. Shield는 learning algorithm의 내부 구조를 바꾸지 않으며, agent가 안전한 한 자유롭게 행동하게 두되 violation으로 이어질 수 있는 action만 막는 minimum interference를 목표로 한다.

### 방법, 수식, 알고리즘

기본 RL 환경은 MDP \(M=(S,s_I,A,P,R)\)로 놓는다. Agent는 상태 \(s_t\)에서 action \(a_t\in A\)를 선택하고, 환경은 \(P(s_t,a_t,s_{t+1})\)에 따라 다음 상태와 보상 \(R(s_t,a_t,s_{t+1})\)을 만든다. Safety specification \(\phi_s=(Q,q_0,\Sigma,\delta,F)\)는 safe state 집합 \(F\)를 가진 automaton으로 다루며, trace가 항상 \(F\) 안에 머물 때 안전하다고 본다.

핵심 계산은 specification automaton과 MDP abstraction \(\phi^M=(Q_M,q_{0,M},A\times L,\delta_M,F_M)\)을 product safety game으로 바꾸는 단계다. Game에서 environment player는 다음 observation label \(l\in L\)을 고르고, system player는 action을 고른다. Safety game solving으로 winning region \(W\)를 계산하면, shield는 어떤 다음 observation이 와도 \(W\) 안에 남는 action만 허용한다. 이 때문에 shield는 correctness를 보장하면서도, abstraction 관점에서 error state로 이어질 수 있는 action만 disable한다.

두 배치가 구분된다.

- **Preemptive shielding**: shield가 agent 앞에 놓이며, 각 step에서 safe action set을 출력한다. 형식적으로 output alphabet은 \(\Sigma_O=2^A\)이고, learner는 그 집합 안에서만 action을 고른다.
- **Post-posed shielding**: shield가 agent 뒤에 놓이며, agent가 고른 action을 통과시키되 unsafe하면 안전한 action으로 교체한다. Agent가 action ranking \(rank_t\)를 제공하면 shield는 ranking 안에서 가장 앞에 있는 safe action을 택하고, ranking 전체가 unsafe할 때만 ranking 밖의 safe action을 선택한다.

논문은 convergence도 별도로 논의한다. Shield와 MDP의 joint behavior를 product MDP \(M'\)로 만들 수 있으면, standard MDP에서 converge하는 learning algorithm은 shield가 있는 경우에도 converge할 수 있다. Post-posed shield에서는 ranking 안에 safe action이 없을 때 대신 실행되는 safe action distribution이 시간에 따라 고정되어야 product MDP로 볼 수 있다는 조건이 붙는다.

### 예시: water tank shield

논문에서 가장 직관적인 예시는 hot water storage tank다. Tank level은 0과 100 liter 사이에 있어야 하고, inflow valve는 mode change 후 최소 3초 동안 같은 상태를 유지해야 한다. Abstraction은 action set \(A=\{\mathit{open},\mathit{closed}\}\)와 label set \(L=\{\mathit{level}<1,\ 1\le\mathit{level}\le99,\ \mathit{level}>99\}\)를 사용한다.

합성된 shield는 level이 너무 낮아지면 최소 level 4에 도달할 때까지 valve open을 강제하고, level이 93보다 높을 때는 valve open을 막는다. 후자는 valve가 최소 3 time step 동안 열려 있어야 하고, 그동안 inflow가 최대 2 liter/second이며 outflow가 0일 수 있기 때문이다. 즉 shield는 overflow가 실제로 발생한 뒤 막는 것이 아니라, specification과 abstraction으로 "피할 수 없게 되는 상태"를 미리 피한다.

### 실험 설정과 핵심 결과

저자들은 네 domain에서 shielded RL을 시험했다.

| Domain | 설정 | 핵심 관찰 |
|---|---|---|
| Grid world | 9x9 및 15x9 grid, tabular Q-learning, wall/opponent collision 방지와 9x9의 bomb 체류 제한 | Unshielded version만 negative reward를 경험했고, shielded version은 safe할 뿐 아니라 더 빠르게 학습했다. 9x9 shield는 2초, 15x9 shield는 0.6초에 합성되었다. |
| Self-driving car | 480x480 pixel 환경, step당 3 pixel 이동, 최대 7.5 degree turn, DQN과 Boltzmann exploration | Preemptive/post-posed shield는 모두 2초 안에 합성되었다. Unshielded agent는 reward가 증가해도 simulation 끝에서 crash를 경험했지만, shielded version without punishment는 더 빨리 학습하고 crash하지 않았다. |
| Atari 2600 Seaquest | OpenAI Gym/ALE 기반 Seaquest, submarine이 diver를 구조하고 oxygen이 떨어지기 전에 surface로 올라가야 함 | Shield는 oxygen 상태, depth, collected divers를 보고 "surface해야 하는 경우"와 "diver가 없는데 surface하면 안 되는 경우"를 구분했다. Shielding은 성능을 바꾸지 않으면서 safety property violation을 막았다. |
| Water tank | Q-learning과 SARSA, tank dry/overflow 방지와 3-step valve mode constraint | Post-posed shield는 \(\phi_s^1\land\phi_s^2\)에서 1초 미만에 합성되었다. Shielded/unshielded 모두 optimal policy에는 도달하지만, shielded implementation이 훨씬 짧은 시간에 도달했다. |

### 논문 주장과 해석의 경계

논문이 직접 주장하는 것은 세 가지다. 첫째, shield는 monitored input-output behavior, environment abstraction, correctness specification에만 의존하며 learning algorithm 내부에는 의존하지 않는다. 둘째, 합성된 shield는 correctness와 minimal interference를 만족한다. 셋째, 실험에서는 shielded agent가 unshielded agent만큼 또는 그 이상으로 수행했고, 많은 경우 learning performance도 개선했다.

해석할 때는 "shielding이 모든 안전 문제를 자동으로 해결한다"로 읽으면 안 된다. 이 방법은 unsafe action을 판단할 수 있는 abstraction이 주어졌을 때 강하다. 따라서 실제 적용에서는 abstraction이 안전 조건에 대해 충분히 conservative한지, 그리고 abstraction mismatch가 감지될 때 어떤 fallback을 둘지가 함께 설계되어야 한다.

### 한계와 확장 방향

가장 큰 한계는 approximate model 또는 abstraction 요구다. 어떤 state에서 어떤 action이 unsafe한지 전혀 알 수 없다면 shield도 action을 차단할 근거가 없다. 저자들은 이 요구가 불가피하다고 보지만, 현실 시스템에서는 abstraction이 너무 거칠면 과도하게 보수적이고, 너무 세밀하면 synthesis cost가 커진다.

실용적인 확장 방향은 세 가지다. 첫째, learned dynamics model의 uncertainty를 abstraction에 반영해 high-confidence safe set과 recheck-needed 영역을 나누는 방식이다. 둘째, shield가 개입한 state-action을 logging해 abstraction을 반복 개선하는 runtime assurance loop다. 셋째, multi-agent 또는 continuous-control domain에서는 symbolic shield와 barrier function, model predictive safety certification을 결합해 discrete specification과 continuous dynamics 사이의 간극을 줄일 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/safe-reinforcement-learning-via-shielding/safe-reinforcement-learning-via-shielding.pdf" | relative_url }}" target="_blank" rel="noopener">safe-reinforcement-learning-via-shielding.pdf</a></li>
  <li><a href="https://doi.org/10.1609/AAAI.V32I1.11797" target="_blank" rel="noopener">DOI: 10.1609/AAAI.V32I1.11797</a></li>
  <li><a href="https://github.com/safe-rl/safe-rl-shielding" target="_blank" rel="noopener">Official experiment repository</a></li>
</ul>
