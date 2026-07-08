---
layout: default
title: "QECO"
topic: "QoE-oriented computation offloading with DRL"
order: 25
---

# QECO: QoE-Oriented Computation Offloading with DRL

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | QECO: A QoE-Oriented Computation Offloading Algorithm Based on Deep Reinforcement Learning for Mobile Edge Computing |
| 저자 | Iman Rahmaty, Hamed Shah-Mansouri, Ali Movaghar |
| 출처 | IEEE Transactions on Network Science and Engineering, 2025 |
| 주제 | MEC, QoE, Computation Offloading, D3QN, LSTM |
| 핵심 방법 | Distributed QoE-oriented Computation Offloading, QECO |

## 한 줄 요약

QECO는 mobile device가 다른 device의 decision을 알 필요 없이 자신의 long-term QoE를 최대화하도록, D3QN/LSTM 기반 분산 computation offloading decision을 학습하는 알고리즘이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | Strict deadline과 energy constraint가 QoE에 어떤 영향을 주는가? |
| 2 | MDP | Computation offloading 문제를 사용자별 long-term QoE maximization으로 어떻게 모델링하는가? |
| 3 | QECO 구조 | D3QN과 LSTM은 offloading decision에서 어떤 역할을 하는가? |
| 4 | 결과 | Completed task, delay, energy, QoE가 기존 방법보다 개선되는가? |

## 1. 문제 배경

MEC에서 task offloading은 사용자 QoE를 높이는 핵심 수단이다. 하지만 task deadline이 엄격하고 energy budget이 제한되면 단순히 edge로 보내는 것이 항상 좋은 선택은 아니다. Edge load와 channel state가 변하면 delay가 증가하고 task가 deadline을 넘길 수 있다.

## 2. 제안 방법

QECO는 computation offloading을 MDP로 정식화하고, 각 mobile device가 분산적으로 decision을 내리게 한다.

| 구성 | 역할 |
|---|---|
| QoE reward | completed task, delay, energy를 통합한 사용자 경험 지표 |
| LSTM | edge load와 task state의 시간적 패턴 반영 |
| Dueling DQN | state value와 action advantage 분리 |
| Double DQN | overestimation bias 감소 |
| Distributed execution | 다른 device decision을 직접 알지 않아도 action 선택 |

## 3. 결과 및 해석

논문은 QECO가 기존 방법보다 completed task 수를 늘리고, delay와 energy consumption을 줄이며, 평균 QoE를 크게 개선한다고 보고한다. 이는 QoE를 단일 목적함수로 명시하고 DRL agent가 장기 보상을 학습하게 한 결과로 해석된다.

## 4. 연구 맥락

QECO-Adapt는 이 QECO를 기반으로 dense MEC 조건에서 load-adaptive control을 추가한 확장으로 볼 수 있다. 따라서 QECO 원 논문은 QECO-Adapt의 baseline, reward structure, network architecture를 이해하는 핵심 자료다.

## 핵심 내용

QECO는 MEC offloading을 단순 delay minimization 문제가 아니라 사용자 QoE maximization 문제로 재정의한다. 사용자는 task가 완료되기를 원하지만, 동시에 delay와 energy consumption도 낮아야 한다. 이 요소들을 하나의 reward로 묶어 long-term QoE를 최대화하도록 학습한다.

알고리즘 구조는 LSTM, dueling DQN, double DQN을 결합한다. LSTM은 시간적으로 변하는 edge load와 task arrival을 기억하고, dueling DQN은 상태 가치와 action 이점을 분리하며, double DQN은 Q-value 과대평가를 줄인다.

이 논문은 QECO-Adapt의 직접적인 출발점이다. QECO-Adapt가 추가한 effective load, adaptive energy weight, gating logic은 QECO의 기본 구조를 유지하면서 dense condition에서 약점을 보완하려는 시도로 이해할 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/qeco-qoe-oriented-computation-offloading/qeco-qoe-oriented-computation-offloading.pdf" | relative_url }}" target="_blank" rel="noopener">QECO PDF</a></li>
</ul>
