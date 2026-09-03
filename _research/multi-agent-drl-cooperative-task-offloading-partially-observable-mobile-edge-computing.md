---
layout: default
date: 2026-08-19 14:02:37 +0900
title: "Cooperative MARL Offloading"
topic: "Cooperative task offloading under partial observability"
order: 68
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Multi-agent reinforcement learning"
  - "Dec-POMDP"
  - "Cooperative task offloading"
  - "Mobile edge computing"
---

# Multi-Agent Deep Reinforcement Learning for Cooperative Task Offloading in Partially Observable Mobile Edge Computing Environment

Source PDF: `multi-agent-drl-cooperative-task-offloading-partially-observable-mobile-edge-computing.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Multi-Agent Deep Reinforcement Learning for Cooperative Task Offloading in Partially Observable Mobile Edge Computing Environment |
| 문서 유형 | Author research idea, 2 pages |
| 저자 | Iman Rahmati |
| 공개 시점 | 2024 |
| 주제 | Cooperative task offloading under partial observability |
| 제안 방향 | Dec-POMDP formulation with candidate MARL methods such as DDPG or D3QN |

## Source Status

이 자료는 완성된 실험 논문이 아니라 저자가 공개한 2쪽 분량의 `Research Idea` 문서다. 문제 정의, 모델링 방향, 후보 알고리즘과 시뮬레이션 계획은 제시하지만 구현 세부사항이나 실험 결과는 포함하지 않는다. 따라서 아래 내용은 검증된 성능 보고가 아니라 연구 제안의 구조와 구현 시 필요한 선택을 해설한 것이다.

## 한 줄 요약

이 연구 아이디어는 device-edge와 edge-edge 오프로딩을 하나의 협력 문제로 묶고, 각 참여자가 전체 상태가 아닌 로컬 관측만 갖는 상황을 Dec-POMDP와 MARL로 다루려 한다.

## 핵심 내용

MEC 참여자는 전체 queue, channel과 자원 상태를 모두 알 수 없고, device-edge와 edge-edge offloading 행동은 서로의 지연과 부하를 바꾼다. 이 연구 아이디어는 이 결합 문제를 Dec-POMDP로 정식화하고, local observation 아래 여러 agent가 공동 목적을 학습하는 MARL 구조를 제안한다.

DDPG나 D3QN 같은 후보는 실제 action이 연속 제어인지 이산 선택인지에 따라 달라지며, reward도 latency뿐 아니라 resource utilization과 coordination cost를 함께 반영해야 한다. 공개 자료에는 구현과 실험 결과가 없으므로, 의의는 부분 관측·이중 오프로딩·협력 학습을 하나의 설계 문제로 묶은 데 있고 성능과 scalability는 검증 과제로 남는다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | 부분 관측 | 각 장치와 엣지 서버가 전체 시스템 상태를 알 수 없다면 무엇을 관측해야 하는가? |
| 2 | 이중 오프로딩 | device-edge와 edge-edge 결정을 어떻게 연결할 것인가? |
| 3 | 협력 학습 | 여러 agent의 행동이 서로의 환경을 바꿀 때 비정상성을 어떻게 줄일 것인가? |
| 4 | 알고리즘 선택 | 연속 제어와 이산 선택 가운데 어떤 action space가 실제 시스템에 맞는가? |
| 5 | 검증 | latency, resource utilization, coordination cost와 scalability를 어떻게 함께 측정할 것인가? |

## 한국어 번역형 해설

### 문제 배경

MEC의 task offloading은 단말이 계산을 로컬에서 수행할지 인근 edge server로 보낼지만 결정하는 단일 단계 문제가 아니다. 특정 edge server에 작업이 몰리면 처음 요청을 받은 서버가 여유 있는 이웃 서버로 작업을 다시 전달할 필요가 있다. 이 문서는 이러한 구조를 두 계층으로 나눈다.

| 하위 문제 | 결정 내용 | 협력이 필요한 이유 |
|---|---|---|
| P1: Device-edge offloading | 단말이 resource-intensive task를 인근 edge server로 보낼지 결정 | channel, device energy, server load가 동시에 변함 |
| P2: Edge-edge offloading | 수신한 task를 이웃 edge server로 재분배할지 결정 | 특정 서버의 병목을 완화하고 유휴 자원을 활용해야 함 |

단일 agent RL에서는 다른 장치와 서버의 정책 변화가 환경 변화처럼 보인다. 여러 agent가 동시에 학습하면 한 agent가 어제 학습한 transition 분포가 다른 agent의 오늘 정책 때문에 달라질 수 있는데, 이것이 multi-agent learning의 비정상성 문제다. 문서는 이 문제를 명시적으로 협력 또는 경쟁 구조로 모델링해야 한다고 본다.

### Dec-POMDP로 보는 이유

제안 문서는 P1과 P2를 decentralized partially observable Markov decision process, 즉 Dec-POMDP로 정식화한다. 전체 시스템 상태를 \(s_t\), agent \(i\)의 로컬 관측을 \(o_t^i\), 공동 행동을 \(a_t=(a_t^1,\ldots,a_t^n)\)라고 보면 각 agent는 전역 상태를 직접 알지 못한 채 자신의 observation history로 행동해야 한다.

이때 핵심은 단순히 agent 수를 늘리는 것이 아니라 무엇을 공유할지 정하는 일이다. 단말은 자신의 queue, channel, battery와 인접 서버 정보를 관측할 수 있고, edge server는 자신의 compute queue, storage, neighbor load와 backhaul 상태를 관측할 수 있다. 모든 원시 상태를 교환하면 중앙집중식 제어와 다르지 않으므로, 실제 구현에서는 load summary나 learned message처럼 제한된 협력 신호가 필요하다.

### 후보 알고리즘 해석

문서는 DDPG와 D3QN을 후보로 제시하지만 하나를 확정하지 않는다. 두 방법의 적합성은 action space 설계에 달려 있다.

| 후보 | 잘 맞는 결정 | 구현 시 주의점 |
|---|---|---|
| DDPG 계열 | transmit power, CPU allocation ratio처럼 연속적인 제어 | 여러 agent의 joint action을 critic이 다루면 차원이 빠르게 증가함 |
| D3QN 계열 | local, nearby edge, neighbor edge처럼 이산적인 목적지 선택 | invalid destination masking과 resource constraint 처리가 필요함 |
| Hybrid MARL | destination은 이산, power와 CPU share는 연속 | discrete policy와 continuous controller의 credit assignment를 분리해야 함 |

연구자의 해석으로는 이 문제는 centralized training with decentralized execution 구조와 잘 맞는다. 학습 중 critic은 여러 agent의 상태와 행동을 사용해 비정상성을 완화하고, 배포 시 각 actor는 로컬 관측과 제한된 메시지만 사용하도록 만들 수 있다. 이는 문서가 제안한 협력 방향을 구현하는 한 가지 확장안이며, 원문이 특정 구조를 확정한 것은 아니다.

### 보상과 평가 설계

연구 아이디어를 실제 실험으로 만들려면 global reward와 local reward 사이의 균형을 먼저 정해야 한다. 모든 agent에 동일한 system reward만 주면 개별 행동의 기여를 구분하기 어렵고, local reward만 주면 server 간 load balancing이 깨질 수 있다.

| 평가 축 | 권장 지표 | 확인하려는 내용 |
|---|---|---|
| Service quality | mean latency, tail latency, deadline success rate | 협력이 사용자 체감 성능을 개선하는가? |
| Resource efficiency | server utilization variance, queue imbalance | edge-edge 재분배가 병목을 줄이는가? |
| Device cost | energy consumption, transmit power | latency 개선이 단말 비용을 과도하게 높이지 않는가? |
| Coordination cost | exchanged bytes, message frequency | 협력 이득이 통신 overhead보다 큰가? |
| Scalability | performance by agent and server count | agent 수 증가에도 학습과 실행이 유지되는가? |

비교군에는 local-only, nearest-edge greedy, independent single-agent DRL, coordination이 없는 MARL, 작은 규모에서의 centralized optimizer를 둘 수 있다. 특히 independent learner와의 비교가 있어야 협력 자체의 효과를 분리할 수 있다.

## 핵심 기여와 해석 포인트

- Offloading을 device-edge 한 단계에 가두지 않고 edge-edge load redistribution까지 연결한다.
- 각 참여자가 전체 상태를 알 수 없다는 실제 MEC 조건을 Dec-POMDP로 드러낸다.
- 성능의 핵심을 특정 DRL architecture보다 coordination, non-stationarity, scalability 문제에 둔다.
- 현재 문서는 연구 설계 단계이므로 DDPG나 D3QN의 우수성, latency 절감률 또는 convergence를 입증한 자료로 인용하면 안 된다.

## 검증 과제와 확장 방향

문서에는 state, action, transition, reward와 constraint가 수학적으로 완성되어 있지 않다. 이를 해결하려면 P1과 P2의 time scale을 구분하고, feasible action masking과 queue stability 조건을 포함한 재현 가능한 simulator를 먼저 정의해야 한다.

Agent 수 증가에 따른 joint action explosion은 parameter sharing, neighborhood-based critic, graph neural network 또는 mean-field approximation으로 완화할 수 있다. 협력 메시지의 신뢰성과 비용은 bandwidth budget, delayed message, packet loss를 포함한 ablation으로 검증해야 한다. 마지막으로 실제 MEC로 확장하려면 mobility와 server failure를 observation noise로만 다루지 말고 robust 또는 constrained MARL의 안전 제약으로 포함할 필요가 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/multi-agent-drl-cooperative-task-offloading-partially-observable-mobile-edge-computing/multi-agent-drl-cooperative-task-offloading-partially-observable-mobile-edge-computing.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://imanrht.github.io/assets/Multi_AgentDRL.pdf" target="_blank" rel="noopener">Author-provided research idea PDF</a></li>
</ul>
