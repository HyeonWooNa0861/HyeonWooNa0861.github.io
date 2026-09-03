---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Task-Graph DRL Offloading"
topic: "DRL offloading for dependent task graphs"
order: 64
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "task graph offloading"
  - "DRL"
  - "MEC"
  - "dependent tasks"
---

# Task Graph offloading via Deep Reinforcement Learning in Mobile Edge Computing

Source PDF: `task-graph-offloading-drl-mec.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Task Graph offloading via Deep Reinforcement Learning in Mobile Edge Computing |
| 출처 | Future Generation Computer Systems, 2024 |
| 주제 | DRL offloading for dependent task graphs |
| 핵심 방법 | SATA-DRL: event-driven ready-task scheduling with DQN under time-varying ECD capability |

## 한 줄 요약

이 논문은 MEC에서 dependent task graph를 여러 ECD에 배치할 때, 시간에 따라 변하는 edge computing capability를 DQN 기반 SATA-DRL이 관찰·학습해 average makespan과 deadline violation을 줄이는 방법을 제안한다.

## 핵심 내용

Mobile application이 dependent task DAG로 구성되면 각 task의 실행 위치뿐 아니라 precedence와 ECD 사이의 intermediate-data transfer가 전체 makespan을 결정한다. 이 논문은 시간에 따라 변하는 edge computing capability 아래 task graph scheduling을 MDP로 만들고, ready-task queue와 ECD 상태를 관찰해 배치 대상을 고르는 SATA-DRL을 제안한다.

DQN은 makespan 감소와 deadline violation penalty를 반영한 경험으로 scheduling policy를 학습한다. Simulation에서 SATA-DRL은 비교 heuristic과 DRL baseline보다 낮은 average makespan과 deadline violation을 보였으며, 고정 분석 모델 대신 환경 변화를 online decision에 반영했다는 점이 핵심이다. 실제 MEC로 확장하려면 mobility, wireless variation과 failure를 포함한 검증이 필요하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | MEC task graph | Application을 DAG와 dummy task로 모델링하면 offloading decision이 어떻게 scheduling problem이 되는가? |
| 2 | Optimization problem | Average makespan 최소화와 deadline constraint를 어떤 변수로 표현하는가? |
| 3 | MDP design | Ready-task queue, ECD 상태, action vector, reward \(r=U-D-P\)를 어떻게 정의하는가? |
| 4 | SATA-DRL | Event-driven SATA와 DQN training loop가 어떻게 결합되는가? |
| 5 | Simulation | CloudSim/EdgeCloudSim/ElasticSim 기반 평가에서 makespan과 deadline violation이 어떻게 비교되는가? |

## 한국어 번역형 해설

### 초록과 문제의식

MEC의 기본 동기는 모바일 기기의 제한된 계산 능력을 network edge의 ECD(edge computing device)로 보완하는 것이다. 하지만 실제 mobile application은 하나의 독립 task가 아니라 gesture recognition, mobile healthcare, augmented reality처럼 여러 dependent task로 구성된 task graph인 경우가 많다. 선행 task가 끝나야 후속 task를 실행할 수 있고, task를 다른 ECD에 배치하면 중간 데이터 전송 지연이 추가된다.

기존 task graph offloading 연구는 heuristic이나 approximation method에 많이 의존했다. 이들은 특정 analytical model이나 expert knowledge가 맞을 때는 빠르게 feasible solution을 찾지만, ECD의 idle computing capability가 시간에 따라 변하는 MEC 환경에는 충분히 적응하지 못한다. 저자들은 이 변화를 deadline violation의 주요 원인으로 보고, task graph scheduling을 MDP로 바꾼 뒤 DQN 기반 SATA-DRL로 scheduling strategy를 학습한다.

### Task graph와 최적화 문제

Application \(n\)은 \(\{r_n,d_n,G_n\}\)으로 표현된다. \(r_n\)은 offloading request time, \(d_n\)은 deadline, \(G_n=(V_n,E_n)\)은 task graph다. Task \(v_{ni}\)는 workload \(\rho_{ni}\)를 가지며, 두 dummy task \(v_{n0}\), \(v_{nI}\)는 각각 application input과 result return을 표현하고 workload는 0으로 둔다. Directed edge \(\epsilon_{nij}\)는 \(v_{ni}\)의 output data가 child task \(v_{nj}\)로 전달되어야 함을 나타낸다.

각 task의 scheduling strategy는 binary vector \(\mathbf{x}_{ni}=(x_{ni}^0,\ldots,x_{ni}^M)\)로 쓰며, 하나의 실제 task는 하나의 ECD에만 배치된다. Completion time \(F(\mathbf{x}_{ni})\), communication time \(T(\mathbf{x}_{ni},\mathbf{x}_{nj})\), application makespan \(\Psi_n\)을 계산한 뒤, 목표는 모든 MU application의 average makespan을 최소화하는 것이다.

저자들은 이 문제를 multiprocessor scheduling problem으로 줄일 수 있으므로 NP-hard하다고 설명한다. 또한 ECD capability가 동적으로 변하므로 static heuristic만으로는 backlog와 deadline violation을 피하기 어렵다. 이 지점에서 DRL은 "정확한 analytical model 없이 environment와 상호작용하며 sequential decision을 학습"하는 도구로 들어온다.

### MDP 설계

SATA는 event-driven 방식으로 동작한다. Application arrival event 또는 task completion event가 발생하면, 각 application의 topological/priority list \(\xi_n\)에서 실행 가능한 ready task를 골라 ready queue \(Q^r\)에 넣는다. Priority는 모든 task가 maximum processing capability를 갖는 ECD에 병렬 실행된다고 가정해 추정한 latest completion time \(F^{lct}_{ni}\)의 ascending order로 정한다. Agent가 \(Q^r\)에서 task 하나를 꺼내는 순간이 MDP time step \(\tau\)가 된다.

State는 MEC system의 계산 지연과 전송 지연을 요약하는 vector다. 원문은 \(s_\tau=(\hat{\hat{B}}, B^m_n, \hat{\hat{\delta}}, w_r, w_m)\) 형태로 설명한다. 여기서 \(\hat{\hat{B}}\)는 ECD 간 transmission rate의 합, \(B^m_n\)은 MU와 covering ECD 사이의 transmission rate, \(\hat{\hat{\delta}}\)는 ECD processing capacity의 합, \(w_r\)는 ready queue \(Q^r\)의 total workload, \(w_m\)은 모든 ECD computing queue의 total workload다. 이 값들은 decision controller가 수집하는 real-time status information에서 관찰 가능하다고 둔다.

Action은 현재 ready task를 어느 ECD에 배치할지 고르는 vector \(a_\tau=(a^0,a^1,\ldots,a^M)\)다. Dummy task를 제외한 task는 network 안의 ECD 중 하나에 scheduling될 수 있고, 각 \(a^m\)은 binary variable이다. Reward는

\[
r=U-D-P
\]

로 정의된다. \(U\)는 utility function, \(D\)는 duration factor, \(P\)는 penalty factor이며, 실험에서는 각각의 weight \(\beta=0.6\), \(\psi=5\), \(\eta=40\)을 사용한다. Reward design의 의도는 단순히 task 하나의 execution time만 보지 않고, system utility, task duration, deadline penalty를 함께 반영하는 것이다.

### SATA-DRL 알고리즘

SATA-DRL은 ready task를 꺼내 state와 reward를 DQN에 전달하고, DQN이 선택한 action에 따라 target ECD에 task를 배치한다. DQN은 prediction network와 target network, experience pool을 사용한다. Transition은 \((s_\tau,a_\tau,r_{\tau+1},s_{\tau+1})\)로 저장되며, mini-batch sampling과 SGD로 prediction network를 갱신한다.

실험 설정에서 두 neural network는 같은 구조의 fully connected network이고 layer node 수는 128, 64, 32, 16, 5다. 앞의 네 layer activation은 linear, 마지막 layer는 softmax이며, optimizer는 Adam, learning rate는 0.0006이다. Experience pool size는 200000, batch size는 64, target Q-value discount factor는 \(\gamma=0.95\)로 설정한다.

### 실험 설정과 핵심 결과

평가는 CloudSim을 EdgeCloudSim과 ElasticSim 요소로 확장해 수행한다. Simulator에는 4개의 ECD가 있고, 각 MU에 해당하는 0-th edge computing device의 processing capability는 1000 MIPS다. 각 ECD의 processing capability level은 \(\{6000,5500,5000,4500,4000\}\) MIPS이며, task가 완료될 때마다 Markov chain transition probability matrix에 따라 상태가 변한다. ECD 간 transmission rate는 440 Mbps, MU와 covering ECD 사이의 rate는 \(10^3\) Mbps다. \(\hat{\delta}=6000\) MIPS, \(\hat{B}=10^3\) Mbps로 둔다.

Task graph는 scientific workflow dataset 중 25개 node를 포함하는 Montage workflow를 사용한다. Application arrival은 Poisson distribution parameter \(\lambda\in\{5,7,9\}\)로 생성하고, 각 application deadline은 \(d_n=r_n+6\cdot MS_n\)으로 설정한다. 여기서 \(MS_n\)은 task들이 maximum average processing capability \(5000=(6000\times4+1000)/6\)을 갖는 서로 다른 ECD에 배치되고 transfer data가 무시된다고 가정해 계산한 basic makespan이다.

| 평가 항목 | 설정 | 관찰 |
|---|---|---|
| RL convergence | Episode당 10개 application, \(\lambda=\{5,7,9\}\) | 초반 reward는 낮지만 episode가 늘수록 증가하고, \(\lambda=9\) 조건의 Fig. 5(c)에서 600 episode 이후 비교적 안정화된다. |
| Average makespan | Zhang's PCP, OnDoc, DTO-CED, Dueling DQN, SATA-DRL 비교 | Fig. 6에서 SATA-DRL이 다섯 알고리즘 중 가장 낮은 makespan을 보인다. Zhang's PCP는 arrival rate가 커질수록 makespan이 증가하는데, 단일 application task 중심으로 결정해 새 application이 busy ECD queue에 쌓이기 때문이다. |
| Deadline violation | 전체 application 중 deadline을 놓친 비율 \(\lvert\vec{N}\rvert/\lvert N\rvert\times100\%\) | Fig. 7에서 SATA-DRL의 deadline violation rate가 다른 알고리즘보다 훨씬 낮다. 저자들은 SATA-DRL이 environment variation을 학습해 computing resource를 더 신중히 orchestrate하기 때문이라고 해석한다. |
| DRL baseline 비교 | 같은 MDP state/action/reward를 쓰는 Dueling DQN과 비교 | SATA-DRL이 average makespan과 deadline violation 모두에서 Dueling DQN보다 우수하며, 이 설정에서는 classic DQN 방식이 더 좋은 task graph offloading 성능을 냈다고 결론낸다. |

### 논문 주장과 해석의 경계

논문이 직접 주장하는 것은 SATA-DRL이 time-varying ECD capability를 고려하는 fine-grained task graph offloading 문제를 MDP로 모델링하고, 기존 heuristic 및 Dueling DQN 대비 average makespan과 deadline violation을 줄였다는 점이다. 또한 task dependency를 ready queue와 latest completion time priority로 풀어, dependent task를 independent job allocation처럼 다루지 않는다.

해석상 중요한 점은 "DRL이 항상 heuristic보다 낫다"가 아니라, 이 논문이 다룬 조건에서는 environment variation을 반복적으로 관찰하는 DRL이 static analytical heuristic보다 적응적이었다는 것이다. 특히 SATA-DRL의 장점은 task graph dependency와 ECD capability transition을 함께 보는 데서 나오며, arrival distribution, workflow type, ECD 수가 바뀌면 재학습과 재평가가 필요하다.

### 한계와 확장 방향

첫 번째 한계는 state representation이 aggregate feature 중심이라는 점이다. \(\hat{\hat{B}}\), \(\hat{\hat{\delta}}\), \(w_r\), \(w_m\)은 system load를 압축하지만, graph topology의 세부 구조나 task별 critical path 정보를 충분히 표현하지 못할 수 있다. 확장 방향은 DAG encoder나 graph neural network를 사용해 task dependency를 직접 embedding하고, DQN action head와 결합하는 것이다.

두 번째 한계는 simulation 기반 검증이다. CloudSim/EdgeCloudSim/ElasticSim 조합과 Montage workflow, 정해진 Markov transition matrix에서는 결과가 분명하지만, 실제 MEC에서는 wireless channel, ECD queue, mobility, failure, multi-tenant interference가 더 복잡하다. 해결 방향은 trace-driven simulation과 online adaptation을 결합하고, deadline miss가 증가할 때 heuristic fallback이나 safe scheduling guard를 두는 것이다.

세 번째 한계는 reward weight \(\beta,\psi,\eta\)와 deadline multiplier \(6\cdot MS_n\) 같은 설정값에 대한 민감도다. 확장 연구에서는 multi-objective RL, constrained RL, 또는 Pareto-front analysis를 도입해 makespan, deadline violation, energy consumption, fairness 사이의 trade-off를 명시적으로 다룰 필요가 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/task-graph-offloading-drl-mec/task-graph-offloading-drl-mec.pdf" | relative_url }}" target="_blank" rel="noopener">task-graph-offloading-drl-mec.pdf</a></li>
  <li><a href="https://doi.org/10.1016/J.FUTURE.2024.04.034" target="_blank" rel="noopener">DOI: 10.1016/J.FUTURE.2024.04.034</a></li>
</ul>
