---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Safe RL Survey"
topic: "Safe reinforcement learning taxonomy"
order: 49
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "Safe RL"
  - "Constrained MDPs"
  - "Risk sensitivity"
  - "Safety taxonomy"
---

# A Comprehensive Survey on Safe Reinforcement Learning

Source PDF: `comprehensive-survey-safe-reinforcement-learning.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | A Comprehensive Survey on Safe Reinforcement Learning |
| 저자 | Javier García, Fernando Fernández |
| 출처 | Journal of Machine Learning Research 16(42), 2015 |
| 주제 | Safe reinforcement learning taxonomy |
| 핵심 방법 | Optimization-criterion modification and exploration-process modification taxonomy |
| 페이지 | 1437-1480 |

## 한 줄 요약

이 survey는 safe RL을 return objective 자체를 risk-aware하게 바꾸는 접근과 exploration process를 안전하게 바꾸는 접근으로 나누어, 안전 제약이 RL 문제 정의와 학습 과정에 들어가는 방식을 정리한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Definition | safe RL에서 safety와 risk는 무엇을 의미하는가? |
| 2 | Optimization criteria | worst-case, risk-sensitive, constrained objective는 무엇을 바꾸는가? |
| 3 | Exploration process | demonstration, teacher advice, risk metric은 탐색 위험을 어떻게 줄이는가? |
| 4 | Evaluation boundary | 위험을 variance, worst outcome, error state 중 무엇으로 볼 것인가? |
| 5 | Open problems | 초기 학습 단계의 위험과 long-term risk를 동시에 어떻게 다룰 것인가? |
| 6 | Modern extension | deep RL, offline RL, shielding, distribution shift로 어떻게 확장할 수 있는가? |

## 한국어 번역형 해설

### 초록과 문제의식

일반적인 RL은 policy가 장기 return을 최대화하도록 학습한다. 하지만 expensive robotic platform, 실제 제어 시스템, 사람이 개입되는 환경에서는 학습 중의 실패도 비용이 크다. 안전은 deployment 이후의 성능 문제가 아니라 learning process 자체의 제약이 된다. 이 survey는 safe reinforcement learning을 “learning 또는 deployment process 동안 reasonable system performance를 보장하거나 safety constraint를 존중하는 것이 중요한 문제에서 expected return을 maximize하는 policy를 학습하는 과정”으로 정의한다.

논문이 강조하는 점은 safety와 risk가 RL 문헌에서 하나의 의미로만 쓰이지 않는다는 것이다. 어떤 연구에서는 catastrophic physical damage를 피하는 것이 safety이고, 다른 연구에서는 stochastic environment에서 rare but large negative outcome을 피하는 것이 risk다. 또 어떤 경우에는 error state에 들어갈 probability나 return variance가 위험 지표가 된다. 따라서 safe RL을 읽을 때는 먼저 “무엇을 위험으로 정의했는가”를 확인해야 한다.

### 제안 방법 또는 분석 구조

Survey의 taxonomy는 두 축으로 구성된다. 첫 번째 축은 optimization criterion을 바꾸는 접근이다. 표준 discounted return \(R=\sum_{t=0}^{\infty}\gamma^t r_t\)의 expectation만 최대화하는 대신, worst-case return, risk-sensitive objective, constrained criterion, VaR나 return density 같은 다른 기준을 목적함수에 포함한다.

두 번째 축은 exploration process를 바꾸는 접근이다. Agent가 위험한 state를 직접 경험하며 배우게 두지 않고, initial knowledge, finite demonstrations, teacher advice, risk-directed exploration을 통해 탐색 경로를 제한하거나 안내한다. 이 축의 관심사는 최적 policy의 최종 안전성뿐 아니라, 학습 중 agent가 얼마나 위험한 시행착오를 겪는가다.

핵심 분류는 다음처럼 정리할 수 있다.

| 축 | 대표 접근 | 핵심 아이디어 | 주의점 |
|---|---|---|---|
| Optimization criterion | Worst-case | 최악의 return 또는 model uncertainty에 대해 보수적으로 최적화 | 지나치게 pessimistic해 long-term utility를 잃을 수 있다 |
| Optimization criterion | Risk-sensitive | risk sensitivity parameter \(\beta\)로 risk-averse 또는 risk-seeking 성향을 조절 | risk metric 선택에 따라 실제 safety와 어긋날 수 있다 |
| Optimization criterion | Constrained | return을 최대화하되 safety-related measure를 bound 안에 둔다 | constraint를 어떤 관측량으로 둘지 명확해야 한다 |
| Exploration process | Demonstrations | teacher의 finite examples로 offline safe policy를 유도한다 | demonstration 품질과 coverage에 의존한다 |
| Exploration process | Teacher advice | 학습 중 teacher가 action 또는 information을 제공한다 | teacher availability와 subjective monitoring에 의존한다 |
| Exploration process | Risk-directed exploration | risk metric을 이용해 위험한 탐색을 회피한다 | 초기에는 risk function 자체가 부정확할 수 있다 |

### 비교와 결과 해석

이 논문은 새 benchmark 실험을 제시하는 empirical paper가 아니라, 기존 safe RL literature를 개념적으로 비교하는 survey다. 따라서 “어느 알고리즘이 수치적으로 최고인가”보다 “각 방법이 어떤 risk definition을 사용하고 어떤 failure mode를 놓치는가”가 읽기의 중심이다.

예를 들어 return variance를 위험으로 보면, 낮은 variance policy가 반드시 안전하다고 말할 수 없다. Survey는 stochastic transition 때문에 error state에 들어갈 수 있는 grid-world류 예를 통해, long-term return variance와 실제 catastrophic state 방문 위험이 어긋날 수 있음을 설명한다. Worst-case criterion은 rare large negative outcome을 피하는 데 유리하지만 지나치게 보수적일 수 있고, teacher advice는 early learning risk를 줄이는 데 유용하지만 teacher의 품질과 개입 가능성에 기대야 한다.

Risk-sensitive criterion에서는 \(\beta\)가 중요한 해석 변수다. 논문은 \(\beta>0\)을 risk aversion, \(\beta<0\)을 risk-seeking preference, \(\beta=0\)을 risk neutrality로 설명한다. 이 notation은 후속 문헌이나 구현마다 부호 convention이 달라질 수 있으므로, 논문의 definition을 기준으로 읽는 것이 안전하다.

### 논문 주장과 해석의 경계

논문이 주장하는 것은 safe RL 연구를 두 큰 경향, 즉 optimization criterion modification과 exploration process modification으로 체계화할 수 있다는 점이다. 이 taxonomy는 2015년까지의 문헌을 정리한 것이므로, 이후 deep RL 기반 safe exploration, neural policy verification, large-scale offline RL까지 직접 포괄한다고 읽으면 안 된다.

작성자 관점에서 이 survey의 가치는 safe RL 논문을 읽을 때 질문 순서를 제공한다는 데 있다. 첫째, 위험은 physical damage, return variance, worst outcome, constraint violation, error state probability 중 무엇인가. 둘째, 안전성은 objective에 들어갔는가, exploration에 들어갔는가. 셋째, 위험을 early learning stage에서 피하는가, 아니면 risk function이 충분히 학습된 뒤에야 피하는가.

### 한계와 확장 방향

가장 큰 한계는 출판 시점이다. 2015년 survey이므로 deep RL 이후의 neural policy, high-dimensional continuous control, offline dataset shift, model-based shielding, formal verification, multi-agent safety 문제는 충분히 반영되지 않는다. 이 한계는 해결 방향도 분명하게 만든다. 기존 taxonomy 위에 modern safe RL을 다시 올리면, shielding은 exploration process modification의 강한 safety filter로, constrained policy optimization은 criterion modification의 현대적 구현으로, offline RL safety는 dataset support와 distribution shift를 다루는 별도 축으로 확장할 수 있다.

또 하나의 과제는 early risk와 long-term risk를 동시에 다루는 것이다. Risk function이 학습된 뒤 위험을 피하는 방법은 초반 시행착오를 막지 못할 수 있고, teacher advice는 초반에는 강하지만 human monitoring과 subjective judgment에 의존한다. 실용적인 확장 방향은 prior knowledge, demonstrations, runtime shields, uncertainty-aware constraints를 결합해 초기 탐색을 제한하고, 충분한 data가 쌓인 뒤에는 learned risk model과 constrained optimization으로 정책을 정교화하는 것이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/comprehensive-survey-safe-reinforcement-learning/comprehensive-survey-safe-reinforcement-learning.pdf" | relative_url }}" target="_blank" rel="noopener">comprehensive-survey-safe-reinforcement-learning.pdf</a></li>
  <li><a href="https://www.jmlr.org/papers/v16/garcia15a.html" target="_blank" rel="noopener">JMLR 16(42):1437-1480</a></li>
</ul>
