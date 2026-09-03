---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "GNRL Offloading"
topic: "Graph neural reinforcement learning for MEC offloading"
order: 56
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Graph neural RL"
  - "MEC offloading"
  - "Task dependency"
  - "Resource allocation"
---

# Offloading Strategy Based on Graph Neural Reinforcement Learning in Mobile Edge Computing

Source PDF: `graph-neural-rl-offloading-mec.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Offloading Strategy Based on Graph Neural Reinforcement Learning in Mobile Edge Computing |
| 출처 | Electronics 13(12):2387, 2024 |
| DOI | 10.3390/ELECTRONICS13122387 |
| 저자 | Tao Wang, Xue Ouyang, Dingmi Sun, Yimin Chen, Hao Li |
| 주제 | Graph neural reinforcement learning for MEC offloading |
| 핵심 방법 | M-GNRL: GraphSAGE-style graph representation combined with DQN-based offloading |

## 한 줄 요약

이 논문은 mobile device와 base station의 동적 연결 구조를 graph로 유지하고, GraphSAGE 방식의 node aggregation과 DQN 기반 decision을 결합해 MEC offloading의 weighted time-energy cost를 줄이는 M-GNRL 방법을 제안한다.

## 핵심 내용

- **문제:** device mobility와 base-station load 변화가 만드는 동적 MEC topology를 단순 state vector만으로 표현하기 어렵다.
- **방법:** M-GNRL은 adjacency-list graph update, GraphSAGE-style aggregation, edge-feature-aware DQN을 결합해 local 또는 offloading target을 선택한다.
- **결과:** 논문은 M-GNRL이 GNN-A2C보다 system cost를 약 15.6% 낮추고, 더 높은 stable cumulative reward 범위에 도달했다고 보고한다.
- **의의:** MEC offloading을 고정 vector control이 아니라 topology가 계속 변하는 dynamic graph control로 다룬 접근이다.

## 한국어 번역형 해설

### 문제 배경

MEC에서는 mobile device가 가까운 base station이나 edge server로 task를 offload해 local energy와 execution delay를 줄인다. 하지만 device mobility 때문에 "어떤 device가 어떤 base station과 연결되는가", "base station끼리 어떤 relay 관계를 갖는가", "현재 resource load가 어떤가"가 time slot마다 바뀐다.

논문은 기존 DRL이 이 graph relationship을 충분히 표현하지 못한다고 본다. State vector에 device와 base station feature를 단순히 붙이면 topology 변화, service coverage 변화, indirect connection을 놓치기 쉽다. M-GNRL은 MEC topology를 graph로 보존하고, graph representation을 DQN의 observation/action selection에 넣는 방식으로 이 문제를 다룬다.

### 시스템 모델

논문은 mobile device $$N(t)$$, base station $$M(t)$$, service range $$K_m$$, time slot 기반 task arrival을 정의한다. 각 device는 time slot마다 하나의 task $$T_{a_n}(t)=[D_n(t),C_n(t)]$$를 가진다. $$D_n(t)$$는 data size이고 $$C_n(t)$$는 required CPU cycles다.

Base station은 directly connected station과 indirectly connected station으로 나뉜다. Direct offloading은 device가 coverage 안의 base station으로 바로 task를 보내는 경우이고, indirect offloading은 다른 base station을 통해 forwarding되는 경우를 포함한다.

| 비용 구성 | 설명 |
|---|---|
| Local execution | local CPU frequency에 따른 execution time과 energy |
| Direct offloading | uplink transmission, base station execution, edge-side resource use |
| Indirect offloading | forwarding delay와 추가 transmission energy 포함 |
| Resource scheduling | base station residual resource, task priority, deadline, load factor 반영 |
| Objective | time cost와 energy cost의 weighted sum 최소화 |

논문은 $$\alpha+\beta=1$$인 weight로 energy와 time을 결합해 system cost $$U_n(t)$$를 만들고, 한 task가 local 또는 하나의 offloading target만 선택하도록 제한한다. 또한 base station resource limit과 maximum execution time $$4\tau$$ 조건을 둔다.

### 제안 방법: M-GNRL

M-GNRL은 graph neural network와 reinforcement learning을 분리하지 않고, graph embedding을 RL observation과 action mapping에 직접 사용한다.

### Graph update

MEC structural graph는 node와 edge가 계속 바뀌는 dynamic graph다. 논문은 adjacency list 기반 update algorithm을 사용해 node addition, node deletion, edge addition, edge deletion, edge weight change를 반영한다. 이렇게 하면 time slot마다 전체 graph를 처음부터 다시 만드는 대신, 변화 set $$C(v_{t+n})$$, $$C(e_{t+n})$$만 반영해 topology를 유지할 수 있다.

### GraphSAGE-style aggregation

Node feature는 주변 base station과 device feature를 sampling aggregation으로 모은다. 논문은 attention 기반 복잡한 aggregation보다 parameter sharing이 가능한 GraphSAGE 계열 방식을 사용해 parameter 수와 training complexity를 줄이는 데 초점을 둔다. Aggregated feature는 concatenation 함수와 nonlinear transform을 거쳐 offloading decision에 들어간다.

### DQN offloading

State에는 task size, required CPU cycles, deadline, priority, base station load, remaining resource 등이 포함된다. Action은 graph edge feature와 연결되어 어느 base station으로 offload할지 또는 local로 실행할지를 선택한다. Reward는 system cost를 낮추는 방향으로 설계되고, replay buffer를 이용해 DQN 방식으로 학습한다.

이 구조의 요지는 "graph는 현재 MEC topology를 설명하고, DQN은 그 topology 위에서 long-term cost를 줄이는 action을 고른다"는 것이다.

### 실험 설정

Simulation은 4 km by 4 km 영역에서 device와 base station을 배치하고, base station service coverage를 0.5 km로 둔다. Dataset record는 device, base station, connection 세 종류로 구성된다.

| Record | 포함 feature |
|---|---|
| Device | ID, task data size, CPU cycles, deadline, priority, local CPU frequency, time slot |
| Base station | ID, computing capacity, power, load, residual resource, service range, time slot |
| Connection | base station ID, device 또는 다른 BS ID, transmission rate, physical distance, time slot |

주요 parameter는 다음과 같다.

| 항목 | 값 |
|---|---|
| Bandwidth $$B$$ | 4 MHz |
| Time slot sequence length $$T$$ | 80 |
| Environment coefficient $$\theta$$ | 0.5 to 1 |
| BS service range $$K_m$$ | 0.5 to 4 km |
| Task data size $$D_n(t)$$ | 800 to 2000 kbytes |
| Required cycles $$C_n(t)$$ | 1000 to 2500 Mcycles |
| Local CPU $$f_n^{local}$$ | 0.5 to 1.5 GHz |
| BS capacity $$F_m$$ | 4 to 11 GHz |
| Episodes | 1000, 1200, 1400 |
| Replay pool | 1500 tuples |
| Learning rate | 0.001 |

Baseline은 LOCAL, RANDOM, GNN-A2C, Coop-UEC다. LOCAL과 RANDOM은 lower reference에 가깝고, GNN-A2C와 Coop-UEC는 graph 또는 cooperative edge offloading과 비교하기 위한 stronger baseline이다.

### 핵심 결과

Discount factor 실험에서는 $$\gamma=0.97$$일 때 평균 reward가 가장 좋게 나타난다. Convergence comparison에서 GNN-A2C는 약 920 iteration 이후 안정화되고 reward가 0.66 to 0.78 범위에 머문다. Coop-UEC는 약 1050 episode 이후 0.35 to 0.44 범위다. M-GNRL은 약 950 iteration 이후 0.82 to 0.97 범위의 더 높은 cumulative reward에 도달한다.

System cost 측면에서도 M-GNRL의 개선이 강조된다. 논문은 GNN-A2C가 Coop-UEC 대비 system cost를 약 22.8% 줄이고, M-GNRL이 다시 GNN-A2C 대비 약 15.6% 낮춘다고 보고한다. 이 수치는 graph topology뿐 아니라 edge feature를 DQN architecture에 넣는 설계가 cost minimization에 기여한다는 논문 측 근거다.

| 비교 | 논문 결과의 의미 |
|---|---|
| M-GNRL vs LOCAL/RANDOM | local-only 또는 random offloading보다 낮은 system cost |
| M-GNRL vs Coop-UEC | graph state와 edge feature를 쓰는 쪽이 더 높은 reward와 낮은 cost |
| M-GNRL vs GNN-A2C | GNN-A2C가 조금 더 빠르게 안정화될 수 있지만, M-GNRL이 더 높은 stable reward에 도달 |
| $$\alpha,\beta$$ weight study | time 또는 energy 한쪽만 극단적으로 보면 system cost가 불안정해져 균형 weight가 필요 |

### 논문이 말한 것과 해석을 구분하기

| 구분 | 내용 |
|---|---|
| 논문 주장 | M-GNRL은 dynamic MEC topology에서 graph information을 활용해 task execution cost와 loss rate를 줄인다. |
| 근거 | adjacency list graph update, GraphSAGE-style aggregation, edge-feature-aware DQN, baseline 대비 reward/cost 개선 실험을 제시한다. |
| 해석 | 이 방법은 mobility로 graph가 바뀌는 MEC를 "continuous vector control"보다 "dynamic graph control"로 보는 접근이다. |
| 주의점 | 실험은 synthetic topology와 parameter range에 기반하므로, 실제 cellular trace와 production scheduler에서 같은 폭의 개선이 보장되지는 않는다. |

### 한계와 해결 방향

논문 결론은 실제 환경 검증이 아직 부족하다는 점을 남긴다. Simulation은 controlled parameter range에서 graph update와 offloading policy를 검증하지만, real-world MEC에서는 channel fluctuation, handover failure, workload burst, base station scheduling policy가 함께 작동한다. 해결 방향은 real mobility/network trace 기반 replay, online graph update overhead 측정, production constraint를 반영한 reward shaping이다.

또한 DQN 기반 discrete action은 offloading target 선택에는 맞지만, bandwidth, CPU frequency, transmit power 같은 continuous resource control은 별도 확장이 필요하다. 이를 해결하려면 hierarchical RL, parameterized action RL, 또는 graph policy와 convex resource allocator를 결합하는 hybrid controller가 자연스러운 확장이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/graph-neural-rl-offloading-mec/graph-neural-rl-offloading-mec.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://doi.org/10.3390/ELECTRONICS13122387" target="_blank" rel="noopener">DOI: 10.3390/ELECTRONICS13122387</a></li>
  <li><a href="https://www.mdpi.com/2079-9292/13/12/2387" target="_blank" rel="noopener">Official MDPI page</a></li>
</ul>
