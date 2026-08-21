---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Reward Shaping"
topic: "Potential-based reward shaping theory"
order: 60
major_topic: "Reinforcement Learning"
keywords:
  - "reward shaping"
  - "policy invariance"
  - "potential-based rewards"
  - "MDP"
---

# Policy Invariance under Reward Transformations: Theory and Application to Reward Shaping

Source PDF: `policy-invariance-reward-transformations-shaping.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Policy Invariance under Reward Transformations: Theory and Application to Reward Shaping |
| 출처 | International Conference on Machine Learning, 1999 |
| 주제 | Potential-based reward shaping theory |
| 핵심 방법 | Potential-based reward transformation that preserves optimal policies |

## 한 줄 요약

이 논문은 reward shaping이 학습 속도를 높일 수 있지만 최적 policy를 바꾸면 위험하다는 문제를 다루고, policy invariance를 보장하는 potential-based shaping 조건을 제시한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Reward shaping | 보조 reward는 왜 유용하면서 위험한가? |
| 2 | Policy invariance | 최적 policy를 보존한다는 것은 무엇인가? |
| 3 | Potential function | state potential 차이가 shaping reward가 되는 이유는 무엇인가? |
| 4 | Application | RL 설계에서 보조 reward를 어떻게 안전하게 넣는가? |

## 한국어 번역형 해설

### 초록과 문제의식

Reward shaping은 sparse reward 문제에서 매우 유용하다. Agent가 목표에 도달하기 전까지 거의 보상을 받지 못하면 exploration이 비효율적이므로, 설계자는 중간 보상을 추가해 학습을 빠르게 만들고 싶어진다. 그러나 이 논문의 출발점은 바로 그 보조 reward가 원래 MDP의 최적 policy를 바꿀 수 있다는 위험이다.

저자들은 reward transformation이 어떤 조건에서 policy invariance를 보장하는지 묻는다. 여기서 policy invariance란 원래 reward \(R\)로 정의된 MDP의 optimal policy가, shaping reward \(F\)를 더한 \(R'=R+F\)에서도 optimal로 유지된다는 뜻이다. 논문 주장은 potential-based shaping이 이 조건을 만족하는 핵심 형식이며, 일정한 가정 아래에서는 이런 형식이 사실상 필요한 조건이라는 것이다.

### 방법: potential-based shaping

Discounted MDP에서 논문이 제시하는 대표적 shaping reward는 다음 꼴이다.

$$
F(s,a,s') = \gamma \Phi(s') - \Phi(s)
$$

여기서 \(\Phi:S\rightarrow \mathbb{R}\)는 state potential function이고, \(\gamma\)는 discount factor다. 이 보상은 transition마다 현재 state와 다음 state의 potential 차이를 더하는 방식이다. 직관적으로는 목적지에 가까운 state에 높은 potential을 주고, transition이 potential을 높이면 보상을 주는 구조다.

Undiscounted absorbing-state 설정에서는 다음과 같은 차이형 보상을 사용하며, terminal 또는 absorbing state의 potential 정규화가 중요해진다.

$$
F(s,a,s') = \Phi(s') - \Phi(s)
$$

이 형식의 중요한 성질은 return 전체에서 shaping reward가 telescope처럼 정리된다는 점이다. 따라서 action을 비교할 때 원래 \(Q\)-value의 순서가 보존되고, optimal action 집합이 바뀌지 않는다. 저자들의 theorem은 finite-state 조건과 regularity 조건 아래에서 potential-based shaping이 optimal policy 보존을 위한 충분조건이며, 강한 의미의 일관성을 모든 MDP에 보장하려면 사실상 필요한 조건임을 보인다.

### 왜 임의의 shaping은 위험한가

논문은 shaping reward가 reward cycle을 만들면 agent가 원래 목적과 다른 행동에 끌릴 수 있다고 설명한다. 대표 사례는 Randløv와 Alstrøm의 bicycle task다. Goal 쪽으로 진행하면 reward를 주지만 goal에서 멀어지는 움직임을 충분히 벌하지 않으면, agent는 출발점 근처에서 작은 원을 돌며 계속 progress reward를 얻는 policy를 학습할 수 있다. 이는 원래 목표에 도달하는 policy가 아니다.

이 사례는 reward shaping을 objective rewriting과 구분해야 함을 보여준다. Potential-based shaping은 학습 속도를 높이기 위한 보조 신호지만, 임의의 dense reward는 원래 objective 자체를 바꿀 수 있다. 연구자의 해석으로는, reward를 추가할 때 "좋아 보이는 중간 행동"을 보상하는 것과 "최적 policy 순서를 보존하는 potential 차이"를 구분하는 것이 이 논문의 가장 실용적인 메시지다.

### 실험과 응용 예시

논문은 grid-world와 subgoal이 있는 grid-world에서 potential-style shaping이 Sarsa 학습을 빠르게 할 수 있음을 보인다. 각 실험은 여러 독립 run 평균으로 보고되며, 원문은 이 section의 결과가 40 independent runs 평균이라고 설명한다. 기본 grid-world에서는 goal까지의 거리나 예상 step 수를 근거로 potential을 만들고, subgoal grid-world에서는 순서대로 방문해야 하는 flag 또는 subgoal 정보를 potential에 반영한다.

핵심은 수치 그 자체보다 설계 방식이다. Potential \(\Phi\)는 expert knowledge, distance-to-goal heuristic, subgoal progress 같은 정보를 사용할 수 있지만, shaping reward는 여전히 \(\gamma\Phi(s')-\Phi(s)\) 또는 그에 대응하는 absorbing-state 차이형 구조를 따라야 한다. 그래야 학습은 빨라질 수 있으면서도 원래 MDP의 optimal policy는 보존된다.

### 결론과 해석 포인트

이 논문은 reward engineering에 대해 명확한 안전 기준을 제공한다. 어떤 논문이 cost term이나 reward bonus를 추가할 때, 그것이 potential-based shaping인지 아니면 새로운 objective를 정의하는 reweighting인지 먼저 구분해야 한다. 전자는 policy invariance 보장을 기대할 수 있지만, 후자는 원래 문제와 다른 최적해를 의도적으로 또는 비의도적으로 만들 수 있다.

특히 modern RL에서 learned reward, auxiliary reward, curriculum reward, safety penalty를 함께 쓰는 경우 이 구분이 중요하다. 논문이 보장하는 것은 "보조 reward를 아무렇게나 넣어도 된다"가 아니라, potential 차이 구조를 만족할 때 optimal policy 보존을 증명할 수 있다는 제한된 주장이다.

### 한계와 확장 방향

가장 큰 한계는 좋은 potential function \(\Phi\)를 찾는 일이 쉽지 않다는 점이다. 논문은 finite-state MDP와 특정 regularity 조건에서 이론을 전개하며, function approximation, partially observable setting, learned potential, non-stationary objective가 결합된 현대 DRL 환경은 추가 검증이 필요하다.

해결 방향은 shaping reward를 설계할 때 세 가지를 명시하는 것이다. 첫째, shaping term이 \(F(s,a,s')=\gamma\Phi(s')-\Phi(s)\) 형태인지 확인한다. 둘째, terminal 또는 absorbing state의 potential normalization을 점검한다. 셋째, learned potential을 쓰는 경우에는 ablation과 off-policy evaluation으로 optimal policy 순서가 바뀌지 않았는지 확인한다. 이 절차를 통과하지 못한 reward 추가는 policy-invariant shaping이 아니라 새로운 objective 설계로 보고 해석해야 한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/policy-invariance-reward-transformations-shaping/policy-invariance-reward-transformations-shaping.pdf" | relative_url }}" target="_blank" rel="noopener">policy-invariance-reward-transformations-shaping.pdf</a></li>
  <li><a href="https://robotics.stanford.edu/~ang/papers.html" target="_blank" rel="noopener">Andrew Ng Publications: Policy invariance under reward transformations</a></li>
  <li><a href="https://robotics.stanford.edu/~ang/papers/shaping-icml99.pdf" target="_blank" rel="noopener">Stanford PDF: shaping-icml99.pdf</a></li>
  <li><a href="https://icml.cc/Conferences/1999/accepted.html" target="_blank" rel="noopener">ICML 1999 Accepted Papers</a></li>
</ul>
