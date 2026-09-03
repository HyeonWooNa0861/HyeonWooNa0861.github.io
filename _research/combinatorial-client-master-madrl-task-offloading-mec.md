---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "CCM-MADRL"
topic: "Multiagent task offloading in mobile edge computing"
order: 11
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "MEC"
  - "Multi-agent DRL"
  - "Task offloading"
  - "Resource allocation"
---

# Combinatorial Client-Master MADRL for Task Offloading in MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Combinatorial Client-Master Multiagent Deep Reinforcement Learning for Task Offloading in Mobile Edge Computing |
| 저자 | Tesfay Zemuy Gebrekidan, Sebastian Stein, Timothy J. Norman |
| 주제 | Mobile Edge Computing, Task Offloading, Multiagent DRL, Resource Constraints |
| 핵심 방법 | Client-master 구조의 heterogeneous multiagent DRL |

## 한 줄 요약

이 논문은 MEC task offloading에서 사용자 단말과 master agent가 서로 다른 역할을 수행하도록 구성해, 사용자와 서버의 다양한 resource constraint를 함께 다루는 combinatorial multiagent DRL 구조를 제안한다.

## 핵심 내용

이 논문은 MEC task offloading이 단순히 각 사용자 단말의 선택 문제가 아니라는 점에서 출발한다. 여러 사용자가 동시에 offload하면 서버 저장공간, 처리 능력, 통신 resource가 함께 제한되며, 한 사용자의 결정이 다른 사용자의 성능에도 영향을 준다.

제안된 CCM-MADRL은 client agent와 master agent를 분리한다. Client는 자신의 task와 단말 상태를 바탕으로 판단하고, master는 여러 client의 결정을 모아 서버 측 제약을 만족하는 방향으로 조정한다. 이는 multiagent 구조를 단순 복제하지 않고 MEC 시스템의 계층적 역할에 맞춘 것이다.

핵심 기여는 resource constraint를 reward penalty로만 처리하지 않고, 의사결정 구조 속에 넣었다는 점이다. 이 접근은 dense MEC나 server bottleneck이 큰 상황에서 특히 중요하다. 반면 master agent가 너무 많은 정보를 요구하면 scalability와 통신 비용 문제가 발생할 수 있으므로, 실제 배포에서는 coordination cost를 함께 평가해야 한다.

Client-master 구조의 해석 포인트는 MEC의 제약이 계층적이라는 점이다. User device는 자신의 battery, task size, latency requirement를 중심으로 판단하지만, MEC server는 여러 사용자의 task를 동시에 받아 storage와 computation resource를 나눠야 한다. 두 관점을 하나의 homogeneous agent로 처리하면 제약의 위치가 흐려질 수 있다.

이 논문은 multiagent DRL을 "여러 agent가 같은 일을 나눠 하는 방식"이 아니라 "서로 다른 역할을 가진 agent들이 조합 decision을 만드는 방식"으로 사용한다. QECO-Adapt처럼 dense condition을 다루는 연구에서는 dropped task가 단순 policy 미숙이 아니라 resource bottleneck의 결과일 수 있으므로, client-master coordination은 중요한 비교 축이 된다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 단일 agent 또는 동질 multiagent DRL만으로 MEC offloading 제약을 처리하기 어려운가? |
| 2 | 구조 | client agent와 master agent는 각각 어떤 의사결정을 맡는가? |
| 3 | 제약 처리 | UD와 MEC server의 이질적인 resource constraint를 어떻게 반영하는가? |
| 4 | 해석 | reward penalty 중심 방식보다 구조적 역할 분리가 어떤 장점을 주는가? |

## 1. 문제 배경

MEC에서는 사용자 단말이 계산 집약적 task를 edge server로 offload할 수 있다. 그러나 offloading decision은 단말의 energy, latency, storage, server capacity, network condition 등 여러 제약을 동시에 고려해야 한다.

기존 DRL 기반 offloading 연구는 단말 측 제약에 집중하거나, server resource가 충분하다고 가정하는 경우가 많다. 또한 multiagent DRL을 쓰더라도 agent가 모두 같은 역할과 제약을 갖는 homogeneous 구조가 많아, 실제 MEC 시스템의 client-server 비대칭성을 충분히 반영하기 어렵다.

## 2. 제안 방법

논문은 client-master 구조를 제안한다. Client agent는 개별 user device 관점에서 task offloading 후보를 만들고, master agent는 server side resource constraint와 전체 system state를 고려해 조합적 결정을 조정한다.

| 구성 | 역할 |
|---|---|
| Client agents | 사용자별 task 상태와 단말 제약을 반영 |
| Master agent | MEC server resource constraint와 전체 조합 검토 |
| Combinatorial action | 여러 사용자 offloading decision을 하나의 resource allocation 문제로 처리 |
| MADRL training | 동적 환경에서 반복 경험을 통해 policy 학습 |

이 구조는 모든 제약을 reward penalty로만 밀어 넣기보다, agent 역할을 분리해 constraint handling을 모델 구조 안에 반영한다.

## 3. 결과 및 해석

논문은 제안 방식이 heterogeneous constraint를 더 직접적으로 다룰 수 있음을 강조한다. 특히 MEC server의 storage/resource constraint가 실제 병목으로 작동하는 상황에서는 단말 agent만으로는 충분한 조정이 어렵다.

다만 client-master 구조는 centralized coordination 성격을 일부 포함하므로, 완전한 분산 환경에서는 communication overhead나 master bottleneck을 함께 검토해야 한다.

## 4. 연구 맥락

QECO-Adapt와 비교하면, 이 논문은 offloading action의 agent 구조 자체를 다루고 QECO는 개별 device의 QoE 중심 decision을 강화한다. Dense MEC 환경에서는 server resource constraint와 dropped task가 중요하므로, client-master coordination은 QECO-Adapt의 load-aware control과 함께 읽을 가치가 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/combinatorial-client-master-madrl-task-offloading-mec/combinatorial-client-master-madrl-task-offloading-mec.pdf" | relative_url }}" target="_blank" rel="noopener">Combinatorial Client-Master MADRL PDF</a></li>
</ul>
