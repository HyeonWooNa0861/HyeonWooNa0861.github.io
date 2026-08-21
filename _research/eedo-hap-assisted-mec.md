---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "EEDO HAP-MEC"
topic: "Online dynamic offloading and resource allocation in HAP-assisted MEC"
order: 23
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "HAP-assisted MEC"
  - "Dynamic offloading"
  - "Resource allocation"
  - "Energy efficiency"
---

# Online Dynamic Multi-User Offloading for HAP-Assisted MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Online Dynamic Multi-User Computation Offloading and Resource Allocation for HAP-Assisted MEC: An Energy Efficient Approach |
| 저자 | Sihan Chen, Wanchun Jiang |
| 출처 | Journal of Cloud Computing, 2024 |
| DOI | `10.1186/s13677-024-00645-5` |
| 주제 | HAP-assisted MEC, Online Offloading, Resource Allocation, Energy Efficiency |
| 핵심 방법 | Energy Efficient Dynamic Offloading, EEDO |

## 한 줄 요약

이 논문은 지상 통신 인프라가 부족한 지역에서 HAP-assisted MEC를 이용해 AI service를 제공하는 상황을 다루며, stochastic optimization 기반 EEDO algorithm으로 energy consumption을 줄이고 system stability를 유지한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 지상 인프라가 부족한 환경에서 aerial edge node가 왜 필요한가? |
| 2 | 모델 | HAP-assisted MEC에서 GD task arrival과 wireless quality randomness를 어떻게 다루는가? |
| 3 | EEDO | Long-term dynamic problem을 어떤 deterministic subproblem으로 나누는가? |
| 4 | 결과 | Energy consumption을 줄이면서 system stability를 유지하는가? |

## 1. 문제 배경

Mobile computing은 중앙 cloud에서 edge computing으로 이동하고 있다. 그러나 지상 통신 인프라가 부족한 지역에서는 ground device가 가까운 edge resource를 활용하기 어렵다. High Altitude Platform(HAP)은 aerial edge node로서 이런 지역에 computing service를 제공할 수 있다.

## 2. 제안 방법

논문은 HAP-assisted MEC에서 computation offloading과 resource allocation을 함께 최적화한다. Task arrival과 wireless communication quality의 randomness를 고려해 long-term dynamic optimization 문제를 deterministic subproblem으로 변환하고 병렬적으로 해결한다.

| 구성 | 역할 |
|---|---|
| HAP | aerial edge computing node |
| GD | ground device, task source |
| Stochastic optimization | random task/channel 환경을 online 문제로 처리 |
| EEDO | energy efficient dynamic offloading decision 생성 |

## 3. 결과 및 해석

EEDO는 system stability를 유지하면서 energy consumption을 줄이는 것을 목표로 한다. 이 논문은 MEC가 지상 기지국 중심 구조를 넘어 aerial edge computing으로 확장될 때 offloading/resource allocation 문제가 어떻게 바뀌는지 보여준다.

## 4. 연구 맥락

QECO-Adapt가 dense terrestrial MEC를 다룬다면, 이 연구는 infrastructure-limited environment에서 aerial MEC의 역할을 강조한다. Offloading decision의 목적 함수도 QoE나 delay뿐 아니라 energy efficiency와 service coverage로 확장된다.

## 핵심 내용

이 논문은 지상 통신 인프라가 충분하지 않은 환경에서 MEC를 어떻게 제공할 것인지 다룬다. HAP는 높은 고도에서 넓은 지역을 커버할 수 있으므로, ground device가 AI task나 computing task를 offload할 수 있는 aerial edge node가 된다.

문제는 task arrival과 channel quality가 계속 변한다는 점이다. 논문은 stochastic optimization을 사용해 장기 문제를 다루고, 이를 여러 subproblem으로 나누어 online EEDO algorithm으로 해결한다. 목표는 에너지 소비를 줄이면서 시스템 안정성을 유지하는 것이다.

이 연구는 MEC offloading이 지상 edge server에만 제한되지 않는다는 점에서 중요하다. 재난 지역, 농촌, 해상, 산악 지역처럼 인프라가 약한 환경에서는 HAP-assisted MEC가 practical deployment option이 될 수 있다.

EEDO의 핵심은 HAP를 단순한 더 높은 위치의 edge server로 보지 않는다는 점이다. HAP는 coverage 측면에서는 유리하지만, wireless link와 onboard computing resource, energy constraint가 함께 얽힌다. 따라서 offloading decision은 "HAP로 보낼 것인가"만이 아니라 언제, 얼마나, 어떤 resource와 함께 보낼 것인가의 문제로 확장된다.

이 연구는 queue stability와 online decision 관점에서도 읽을 가치가 있다. Random channel과 task arrival을 완전히 예측하기 어렵기 때문에, 매 slot의 최적 선택보다 장기 평균 성능과 안정성을 함께 보는 구조가 필요하다. QECO-Adapt처럼 dense stress를 다루는 연구와 연결하면, HAP-MEC에서는 load뿐 아니라 aerial link variability까지 control target이 된다는 차이가 드러난다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/eedo-hap-assisted-mec/eedo-hap-assisted-mec.pdf" | relative_url }}" target="_blank" rel="noopener">EEDO HAP-Assisted MEC PDF</a></li>
</ul>
