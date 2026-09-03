---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "Energy-Aware MEC"
topic: "Energy-aware multi-agent DRL for mobile edge computation offloading"
order: 32
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Energy-aware offloading"
  - "Multi-server MEC"
  - "Multi-agent DRL"
  - "Computation offloading"
---

# Energy-Aware Multi-Server MEC

Source PDF: `energy-aware-multi-server-mobile-edge-computing.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Energy-Aware Multi-Server Mobile Edge Computing: A Deep Reinforcement Learning Approach |
| 핵심 주제 | 다중 MEC 서버 환경에서 에너지 제약 사용자들의 오프로딩 선택 |
| 방법 | 서버별 DQN agent를 둔 multi-agent deep reinforcement learning |
| 목표 | 평균 task completion time과 system lifetime 사이의 균형 |

## 한 줄 요약

이 논문은 여러 MEC 서버가 있는 환경에서 각 서버가 자신에게 연결된 사용자 중 누구를 오프로딩시킬지 학습하게 하여, 작업 완료 시간을 줄이면서도 배터리 고갈로 인한 system lifetime 감소를 완화하려는 multi-agent DRL 접근이다.

## 핵심 내용

- MEC에서 오프로딩은 에너지 절감 수단이지만, 무선 자원과 서버 큐를 고려하지 않으면 완료 시간이 늘 수 있다.
- 이 논문은 서버마다 DQN agent를 두어 local user pool 안에서 offloading user를 선택하게 한다.
- 관측값은 queue length, energy level, mean waiting time, uplink SNR처럼 실제 의사결정에 직접 필요한 상태로 구성된다.
- 보상은 offloaded bits per energy이므로, 처리량과 에너지 효율을 동시에 압축해 표현한다.
- 결과의 핵심은 특정 greedy 목적 하나만 최적화하지 않고, 완료 시간과 lifetime의 균형을 학습한다는 점이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | MEC 에너지 문제 | 모든 사용자가 오프로딩하면 항상 좋은가? |
| 2 | 시스템 모델 | 사용자 에너지, task queue, uplink 상태를 어떻게 모델링하는가? |
| 3 | Multi-agent DQN | 서버별 agent는 무엇을 관찰하고 선택하는가? |
| 4 | 보상 설계 | 완료 시간과 lifetime trade-off를 어떻게 반영하는가? |
| 5 | 결과 | greedy baseline보다 어떤 균형이 나은가? |

## 1. 문제 배경

MEC는 사용자 장치의 계산 부담을 줄일 수 있지만, 모든 사용자가 동시에 서버로 작업을 보내면 무선 자원과 서버 큐가 병목이 된다. 반대로 로컬 계산을 많이 시키면 작업은 빠르게 처리될 수 있어도 사용자 에너지가 빨리 줄어 system lifetime이 짧아진다.

논문은 이 trade-off를 명시적으로 다룬다. 핵심 지표는 task completion time과 system lifetime이다. system lifetime은 모든 사용자 중 하나라도 에너지가 고갈되기 전까지 시스템이 지속되는 시간으로 정의된다.

## 2. 시스템 모델

네트워크에는 \(N\)개의 MEC server와 \(K\)명의 user가 있다. 시간은 slot 단위로 진행되며, 각 사용자는 Poisson process에 따라 계산 task를 받는다. 사용자는 각 slot에서 idle, local computation, offloading 중 하나의 상태로 동작한다.

사용자 \(j\)의 에너지 \(E_j(t)\)는 local computation, offloading, standby energy에 의해 줄어든다. 한 사용자의 에너지가 0 이하가 되면 episode가 종료되며, 이것이 system lifetime을 결정한다.

## 3. Local computation과 offloading

Local computation에서는 현재 에너지에서 가능한 최대 CPU frequency를 계산하고, 그 범위 안에서 queue의 앞쪽 task부터 처리한다. Offloading에서는 사용자가 연결된 MEC server로 전송 가능한 최대 bit 수를 uplink rate로 계산하고, 마찬가지로 queue 앞쪽 task를 서버로 보낸다.

이 구조는 "task 하나를 보낼지 말지"의 정적 결정이 아니라, 시간에 따라 queue, energy, SNR이 계속 변하는 온라인 제어 문제를 만든다.

## 4. Multi-Agent DQN 구조

논문은 각 MEC server에 DQN agent를 배치한다. 각 agent는 자신에게 연결된 사용자들의 queue length, energy level, mean task waiting time, uplink SNR을 관찰한다. 행동은 해당 slot에서 어떤 사용자를 offloading user로 선택할지이다.

선택된 사용자는 서버로 task를 offload하고, 나머지 사용자는 에너지가 충분하면 local computation을 수행한다. 이 설계는 중앙 집중식 전역 제어가 아니라 서버별 부분 관측 기반 의사결정에 가깝다.

## 5. 보상 설계

Agent의 reward는 선택된 사용자가 offloading으로 처리한 bit 수를 offloading에 소비한 energy로 나눈 energy efficiency 형태이다. 이 보상은 단순히 많은 task를 처리하는 정책보다, 에너지 대비 효율적인 offloading을 선호하게 만든다.

따라서 정책은 평균 완료 시간을 줄이고 싶다는 목표와, 특정 사용자의 배터리를 지나치게 빨리 소모하지 않아야 한다는 목표 사이에서 균형을 학습한다.

## 6. 실험 결과 해석

논문은 10m \(\times\) 10m network area, FDMA, 여러 MEC server와 user를 둔 시뮬레이션을 사용한다. DQN은 2-layer neural network를 사용하고, \(\epsilon\)-greedy exploration과 replay buffer로 학습된다.

비교 기준선은 average queue waiting time이 큰 사용자를 고르는 Time-Greedy Agent와 energy level이 낮은 사용자를 고르는 Energy-Greedy Agent이다. 제안 방법은 두 기준선보다 task computation time과 system lifetime 사이에서 더 나은 trade-off를 보인다.

## 해석 포인트

이 논문은 "에너지가 낮은 사용자를 우선 보호할 것인가, 큐가 긴 사용자를 우선 처리할 것인가"라는 충돌을 DRL로 다룬다. Time-Greedy와 Energy-Greedy는 각각 한쪽 지표에 치우친 기준선이고, 제안 방법은 관측 상태와 reward를 통해 두 지표의 중간 정책을 찾는다.

## 한계와 향후 과제

각 서버의 agent가 부분 관측만 사용하므로, 서버 간 간섭이나 사용자 이동성이 커지는 환경에서는 coordination 문제가 더 중요해질 수 있다. 또한 reward가 energy efficiency에 집중되어 있어, 지연 민감 애플리케이션의 deadline violation 같은 제약은 별도 확장이 필요하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/energy-aware-multi-server-mobile-edge-computing/energy-aware-multi-server-mobile-edge-computing.pdf" | relative_url }}" target="_blank" rel="noopener">Energy-Aware Multi-Server Mobile Edge Computing PDF</a></li>
</ul>
