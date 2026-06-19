---
layout: default
title: "Spatial-Temporal MEC Offloading"
topic: "Joint task offloading and channel allocation with D3QN"
order: 17
---

# Joint Task Offloading and Channel Allocation in Spatial-Temporal Dynamic MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Joint Task Offloading and Channel Allocation in Spatial-Temporal Dynamic for MEC Networks |
| 저자 | Tianyi Shi, Tiankui Zhang, Jonathan Loo, Rong Huang, Yapeng Wang |
| 주제 | MEC, Spatial-Temporal Dynamics, Channel Allocation, D3QN |
| 핵심 방법 | Priority evaluation, grouped knapsack channel allocation, Double Dueling DQN |

## 한 줄 요약

이 논문은 이동성으로 인한 spatial dynamic과 task dependency로 인한 temporal correlation을 함께 고려해, task offloading과 channel allocation을 결합한 long-term delay-energy cost minimization 문제를 다룬다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | MEC에서 사용자 이동성과 task dependency가 왜 함께 문제가 되는가? |
| 2 | 우선순위 | Task dependency를 priority evaluation으로 어떻게 decouple하는가? |
| 3 | Channel allocation | 현재 data load와 channel status를 grouped knapsack으로 어떻게 반영하는가? |
| 4 | Offloading | D3QN이 offloading decision을 어떻게 학습하는가? |

## 1. 문제 배경

Multi-user multi-server MEC에서는 사용자의 이동으로 computing request가 공간적으로 계속 달라진다. 동시에 일부 application은 task 간 dependency가 있어 시간적으로 인접한 task들이 서로 다른 resource availability와 competition을 경험한다.

이 논문은 이런 spatial-temporal dynamic을 단순 noise가 아니라 offloading과 channel allocation decision에 직접 반영해야 할 조건으로 본다.

## 2. 제안 방법

논문은 task dependency를 priority evaluation으로 먼저 완화하고, channel allocation은 grouped knapsack 문제로 구성한다. 이후 D3QN을 사용해 offloading decision을 학습하며, channel allocation 결과를 reward feedback에 포함한다.

| 구성 | 역할 |
|---|---|
| Priority evaluation | task dependency와 temporal correlation 반영 |
| Grouped knapsack | channel allocation을 combinatorial optimization으로 처리 |
| D3QN | offloading decision 학습 |
| Reward feedback | channel allocation 결과를 동적 환경 정보로 반영 |

## 3. 결과 및 해석

제안 방식은 communication resource와 computation resource를 분리해서 최적화하지 않고, offloading과 channel allocation의 상호작용을 학습 과정에 넣는다. 이는 MEC에서 delay-energy trade-off를 더 현실적으로 다루기 위한 설계다.

## 4. 연구 맥락

QECO-Adapt는 dense load와 dropped task에 초점을 두지만, 이 논문은 spatial mobility와 temporal dependency를 강조한다. 두 관점은 상호 보완적이며, 실제 MEC 시스템에서는 부하 집중, 이동성, channel competition이 함께 발생한다.

## 한국어 번역형 해설

이 논문은 MEC 네트워크의 동적 특성을 공간과 시간 두 방향으로 나누어 본다. 사용자가 이동하면 어느 edge server에 요청이 몰리는지가 바뀌고, task dependency가 있으면 이전 task와 다음 task의 resource 경쟁이 서로 영향을 준다.

논문은 먼저 task priority를 평가해 dependency를 다루고, channel allocation을 grouped knapsack 문제로 해결한다. 그 다음 D3QN이 offloading decision을 학습한다. 이때 channel allocation 결과가 reward에 들어가므로, agent는 단순히 계산 위치만 고르는 것이 아니라 통신 resource 상태까지 간접적으로 고려한다.

이 접근은 MEC offloading을 channel allocation과 분리해 보지 않는다는 점에서 중요하다. Dense environment에서는 edge capacity뿐 아니라 wireless channel competition도 delay와 energy를 크게 바꿀 수 있기 때문이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/joint-task-offloading-channel-allocation-spatial-temporal-mec/joint-task-offloading-channel-allocation-spatial-temporal-mec.pdf" | relative_url }}" target="_blank" rel="noopener">Spatial-Temporal MEC Offloading PDF</a></li>
</ul>
