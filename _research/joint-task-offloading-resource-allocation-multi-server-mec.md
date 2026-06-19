---
layout: default
title: "JTORA"
topic: "Joint task offloading and resource allocation in multi-server MEC"
order: 18
---

# Joint Task Offloading and Resource Allocation for Multi-Server MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Joint Task Offloading and Resource Allocation for Multi-Server Mobile-Edge Computing Networks |
| 저자 | Tuyen X. Tran, Dario Pompili |
| arXiv | `1705.00704` |
| 주제 | Multi-server MEC, Task Offloading, Resource Allocation, MINLP |
| 핵심 방법 | JTORA decomposition, convex/quasi-convex optimization |

## 한 줄 요약

JTORA는 multi-cell MEC에서 task offloading decision, uplink transmission power, MEC computing resource allocation을 함께 최적화해 task completion time과 energy consumption을 줄이는 문제를 다룬다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | Multi-server MEC에서 offloading과 resource allocation은 왜 분리하기 어려운가? |
| 2 | 문제 정식화 | Task offloading gain을 completion time과 energy reduction으로 어떻게 정의하는가? |
| 3 | 분해 | NP-hard MINLP를 어떤 하위 문제로 나누는가? |
| 4 | 결과 | 분해 기반 접근이 large-scale network에서 실용적인가? |

## 1. 문제 배경

MEC server가 여러 base station에 배치되면 사용자는 가까운 edge resource를 활용할 수 있다. 그러나 어떤 task를 어느 server에 offload할지, uplink power를 어떻게 조절할지, 각 MEC server의 computing resource를 어떻게 나눌지는 서로 연결되어 있다.

## 2. 제안 방법

논문은 Joint Task Offloading and Resource Allocation(JTORA)을 MINLP로 정식화한다. 직접 최적해를 구하기 어렵기 때문에, resource allocation 문제와 task offloading 문제로 분해한다.

| 하위 문제 | 역할 |
|---|---|
| Resource Allocation | offloading decision이 주어진 상태에서 power와 computing resource 최적화 |
| Task Offloading | resource allocation의 optimal-value function을 이용해 offloading 결정 |
| Convex/quasi-convex optimization | RA 문제를 tractable하게 해결 |

## 3. 결과 및 해석

JTORA의 의미는 MEC offloading gain을 단순 delay만이 아니라 energy reduction과 함께 본다는 데 있다. 또한 offloading decision만 학습하거나 최적화하는 것이 아니라, resource allocation과 함께 풀어야 실제 성능이 나온다는 점을 보여준다.

## 4. 연구 맥락

QECO 계열 연구는 DRL 기반 online/distributed decision에 초점을 둔다. JTORA는 그 이전 단계에서 MEC offloading problem을 최적화 문제로 엄밀하게 정식화한 기준점으로 볼 수 있다.

## 한국어 번역형 해설

이 논문은 multi-server MEC에서 task offloading과 resource allocation을 하나의 결합 문제로 다룬다. 사용자가 edge로 task를 보내더라도 uplink power가 부족하거나 MEC server resource가 부족하면 실제 gain은 줄어든다.

JTORA는 offloading decision, transmission power, computing resource를 함께 최적화한다. 이 문제는 integer decision과 continuous resource가 섞인 MINLP이므로 그대로 풀기 어렵다. 논문은 문제를 resource allocation과 task offloading으로 분해해 계산 가능하게 만든다.

이 연구는 DRL 논문들과 달리 학습 기반 방법 자체를 강조하지는 않지만, MEC offloading에서 무엇을 최적화해야 하는지 명확한 기준을 제공한다. 이후 DRL 기반 방법은 이런 최적화 문제를 online, distributed, scalable하게 근사하는 방향으로 발전한다고 볼 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/joint-task-offloading-resource-allocation-multi-server-mec/joint-task-offloading-resource-allocation-multi-server-mec.pdf" | relative_url }}" target="_blank" rel="noopener">JTORA PDF</a></li>
</ul>
