---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "DROO"
topic: "Online offloading in wireless powered MEC"
order: 13
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "DROO"
  - "Wireless powered MEC"
  - "Online offloading"
  - "Resource allocation"
---

# DROO: Online Computation Offloading in Wireless Powered MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Deep Reinforcement Learning for Online Computation Offloading in Wireless Powered Mobile-Edge Computing Networks |
| 저자 | Liang Huang, Suzhi Bi, Ying-Jun Angela Zhang |
| 주제 | Wireless Powered MEC, Binary Offloading, Resource Allocation, Deep Reinforcement Learning |
| 핵심 방법 | Deep Reinforcement learning-based Online Offloading, DROO |

## 한 줄 요약

DROO는 wireless powered MEC에서 binary offloading과 wireless resource allocation을 빠르게 결정하기 위해, combinatorial optimization을 매번 직접 풀지 않고 DNN으로 offloading decision을 학습하는 online framework다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 시간변화 channel과 random task 환경에서 왜 기존 최적화 방식이 느린가? |
| 2 | 모델 | Wireless powered MEC에서 offloading과 resource allocation은 어떻게 연결되는가? |
| 3 | DROO | DNN이 binary offloading decision을 어떻게 대체하는가? |
| 4 | 해석 | Near-optimal 성능과 낮은 실행 시간을 동시에 얻을 수 있는가? |

## 1. 문제 배경

Wireless powered MEC에서는 저전력 device가 wireless power transfer로 에너지를 얻고, task를 local에서 처리하거나 MEC server로 offload한다. Channel condition과 task arrival이 변하기 때문에 각 time frame에서 offloading decision과 resource allocation을 빠르게 정해야 한다.

Binary offloading은 각 task가 local 또는 edge 중 하나로 완전히 처리되는 구조다. 사용자 수가 늘어나면 가능한 offloading 조합이 급격히 증가하므로, 매 frame combinatorial optimization을 푸는 방식은 실시간 처리에 적합하지 않다.

## 2. 제안 방법

DROO는 DNN을 이용해 channel state와 queue/resource 상태로부터 offloading decision을 학습한다. 이후 resource allocation은 offloading decision이 주어진 상태에서 계산된다.

| 구성 | 역할 |
|---|---|
| DNN actor | binary offloading decision 후보 생성 |
| Memory/replay | 경험을 저장하고 학습에 활용 |
| Adaptive procedure | 사용자 수와 환경에 따라 algorithm parameter 조정 |
| Optimization layer | 선택된 offloading decision에 따른 resource allocation 계산 |

핵심은 어려운 combinatorial search를 매번 반복하는 대신, DNN inference로 좋은 offloading candidate를 빠르게 얻는 것이다.

## 3. 결과 및 해석

논문은 DROO가 기존 최적화 방식에 가까운 성능을 유지하면서 계산 시간을 크게 줄인다고 보고한다. 특히 30-user network에서 CPU 실행 시간이 0.1초 이하로 제시되어 online decision에 적합함을 강조한다.

다만 DNN은 환경 분포를 경험으로 학습하므로, channel/task distribution이 크게 바뀌면 재학습이나 online adaptation이 필요할 수 있다.

## 4. 연구 맥락

DROO는 QECO 계열 offloading 연구의 중요한 선행 흐름이다. QECO가 QoE와 distributed decision을 강조한다면, DROO는 binary offloading을 빠르게 근사하는 learning-to-optimize 관점을 제공한다.

## 핵심 내용

이 논문은 wireless powered MEC에서 매 순간 최적 offloading 조합을 직접 계산하기 어렵다는 문제를 다룬다. Wireless device는 에너지 수확, task 계산, uplink transmission을 동시에 고려해야 하며, channel condition은 계속 변한다.

DROO는 이 문제를 deep reinforcement learning 기반 online decision framework로 바꾼다. DNN은 현재 상태를 입력으로 받아 offloading decision을 생성하고, system은 그 decision에 맞춰 resource allocation을 계산한다. 기존 방식처럼 모든 가능한 조합을 탐색하지 않으므로 사용자 수가 늘어날 때 계산 시간이 크게 줄어든다.

논문의 핵심은 near-optimal performance와 real-time feasibility의 절충이다. MEC 환경에서는 완벽한 최적해보다 channel coherence time 안에 충분히 좋은 결정을 내리는 것이 더 중요할 수 있다. DROO는 이 관점을 잘 보여주는 대표적인 선행 연구다.

DROO의 핵심은 binary offloading decision을 학습 기반으로 빠르게 생성하면서도, resource allocation은 optimization으로 보정하는 hybrid 구조다. Pure exhaustive search는 user 수가 늘면 action space가 폭발하고, pure learning은 constraint feasibility를 보장하기 어렵다. DROO는 DNN이 유망한 offloading action 후보를 만들고, 이후 resource allocation problem을 풀어 feasible한 decision을 찾는다.

읽을 때는 wireless powered MEC의 특수성을 놓치면 안 된다. Offloading은 energy를 아끼는 선택일 수 있지만, 전송에도 에너지가 필요하고 그 에너지는 WPT로 충전된다. 따라서 computation rate, harvesting time, transmission time이 서로 trade-off를 이룬다. DROO는 이후 LyDROO/LyDROP 같은 안정성 및 partial offloading 확장의 기준점으로 읽을 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/droo-online-computation-offloading-wireless-powered-mec/droo-online-computation-offloading-wireless-powered-mec.pdf" | relative_url }}" target="_blank" rel="noopener">DROO PDF</a></li>
</ul>
