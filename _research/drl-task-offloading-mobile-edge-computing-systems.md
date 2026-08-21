---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "DRL Task Offloading"
topic: "Distributed task offloading with LSTM, dueling DQN, and double DQN"
order: 14
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "MEC"
  - "Task offloading"
  - "LSTM"
  - "Dueling DQN"
  - "Double DQN"
---

# Deep Reinforcement Learning for Task Offloading in MEC Systems

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Deep Reinforcement Learning for Task Offloading in Mobile Edge Computing Systems |
| 저자 | Ming Tang, Vincent W. S. Wong |
| 주제 | MEC, Task Offloading, Edge Load Dynamics, LSTM, Dueling DQN, Double DQN |
| 핵심 방법 | Model-free distributed DRL offloading algorithm |

## 한 줄 요약

이 논문은 edge load dynamics와 deadline-sensitive task를 고려해, 각 mobile device가 다른 device의 task model이나 decision을 알지 못해도 offloading 여부와 대상 edge node를 결정하도록 하는 distributed DRL offloading 방법을 제안한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 많은 device가 edge node로 offload할 때 왜 delay와 dropped task가 증가하는가? |
| 2 | 모델 | Non-divisible, delay-sensitive task와 edge load dynamics를 어떻게 반영하는가? |
| 3 | DRL 구조 | LSTM, dueling DQN, double DQN은 각각 어떤 문제를 보완하는가? |
| 4 | 결과 | 분산 decision으로 dropped task와 average delay를 줄일 수 있는가? |

## 1. 문제 배경

MEC 시스템에서 edge node는 제한된 processing capacity를 가진다. 많은 mobile device가 동시에 task를 offload하면 queue가 길어지고, deadline이 지난 task는 drop될 수 있다.

중앙 controller가 모든 정보를 알고 최적 결정을 내리면 좋지만, 실제 환경에서는 각 device가 다른 device의 task model이나 offloading decision을 알기 어렵다. 따라서 각 device가 local observation을 바탕으로 분산적으로 결정하는 구조가 필요하다.

## 2. 제안 방법

논문은 task offloading을 expected long-term cost minimization 문제로 정의하고, model-free DRL 기반 distributed algorithm을 제안한다.

| 구성 | 역할 |
|---|---|
| LSTM | edge load와 task state의 시간적 변화를 기억 |
| Dueling DQN | state value와 action advantage를 분리해 value estimation 개선 |
| Double DQN | Q-value overestimation 감소 |
| Distributed decision | 각 device가 독립적으로 offloading decision 수행 |

이 구성은 uncertainty가 큰 edge load dynamics를 학습 기반으로 다루기 위한 조합이다.

## 3. 결과 및 해석

시뮬레이션 결과는 제안 방식이 기존 알고리즘보다 dropped task ratio와 average delay를 줄일 수 있음을 보여준다. 중요한 점은 edge node의 processing capacity를 더 잘 활용한다는 것이다. 단순히 offload를 줄이는 것이 아니라 어느 edge node로 보낼지까지 학습해 congestion을 완화한다.

## 4. 연구 맥락

QECO 논문과 QECO-Adapt는 이 연구의 구조적 영향을 직접적으로 받는다. LSTM, dueling DQN, double DQN을 함께 사용하는 offloading model은 deadline, energy, edge load가 결합된 MEC 문제에서 기본적인 DRL 설계 사례로 볼 수 있다.

## 핵심 내용

이 논문은 edge node가 과부하될 때 발생하는 delay와 task drop 문제를 중심으로 한다. Mobile device는 task를 local에서 처리할지, 특정 edge node로 offload할지 결정해야 하지만 다른 device의 상태를 알기 어렵다. 따라서 완전한 중앙 최적화보다 분산 학습 구조가 현실적이다.

제안 알고리즘은 LSTM으로 시간적 load 변화를 반영하고, dueling DQN으로 state 자체의 가치와 action별 이점을 분리하며, double DQN으로 Q-value 과대평가를 줄인다. 이 조합은 단순 DQN보다 MEC의 동적 환경에 더 적합한 value estimation을 제공한다.

결론적으로 이 연구는 QECO 계열 논문의 핵심 선행 배경이다. 특히 dropped task와 average delay를 줄이는 목적은 dense MEC 환경에서 QECO-Adapt가 다시 다루는 문제와 직접 연결된다.

이 논문이 다루는 offloading은 단일 사용자의 local/edge binary choice보다 복잡하다. Edge node가 여러 개이고 각 node의 load가 시간에 따라 변하므로, 어떤 edge로 보내는지가 task completion에 직접 영향을 준다. LSTM은 이런 load dynamics를 state representation에 반영하고, dueling/double DQN은 action value 추정의 안정성을 보완한다.

읽을 때 주의할 점은 distributed DRL이 global optimum을 보장한다는 뜻은 아니라는 것이다. 각 device가 local observation으로 decision을 내리기 때문에 정보가 제한되고, 다른 device의 action과 환경 변화가 non-stationarity를 만든다. 그럼에도 중앙 controller 없이 delay와 dropped task를 줄일 수 있다는 점이 이 연구의 실용적 의미다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/drl-task-offloading-mobile-edge-computing-systems/drl-task-offloading-mobile-edge-computing-systems.pdf" | relative_url }}" target="_blank" rel="noopener">DRL Task Offloading in MEC Systems PDF</a></li>
</ul>
