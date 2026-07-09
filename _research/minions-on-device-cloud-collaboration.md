---
layout: default
title: "Minions"
topic: "On-device small LM and cloud frontier model collaboration"
order: 37
---

# Minions

Source URL: `https://www.together.ai/blog/minions`

## 자료 정보

| 항목 | 내용 |
|---|---|
| 원문 | Minions: embracing small LMs, shifting compute on-device, and cutting cloud costs in the process |
| 출처 | Together AI Research Blog |
| 공개일 | 2025-02-25 |
| 저자 | Avanika Narayan, Dan Biderman, Sabri Eyuboglu, Avner May, Scott Linderman, James Zou, Christopher Ré |
| 연결 축 | QECO-Adapt의 edge/cloud split motivation 확장 |

## 한 줄 요약

Minions는 긴 context를 전부 cloud frontier model에 보내지 않고, local small LM이 context를 읽고 필요한 중간 결과만 cloud model과 주고받게 하여 비용을 줄이는 on-device/cloud 협업 프로토콜이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 배경 | 왜 모든 context를 cloud model에 보내면 비싼가? |
| 2 | Minion | local LM과 cloud model의 단순 대화는 어디서 한계가 있는가? |
| 3 | Minions | decomposition-execution-aggregation loop는 무엇을 바꾸는가? |
| 4 | 비용-정확도 | local compute를 더 쓰면 cloud 비용을 얼마나 줄일 수 있는가? |
| 5 | QECO-Adapt 연결 | MEC offloading 연구의 broader motivation으로 어떻게 쓸 수 있는가? |

## 1. 문제 배경

Together AI 글은 consumer device의 local compute가 빠르게 늘고 있지만, 어려운 reasoning task는 여전히 cloud frontier model에 의존하는 상황에서 출발한다. 긴 문서 전체를 cloud에 보내면 토큰 비용이 커지고, privacy나 latency 측면에서도 부담이 생긴다.

Minions의 기본 질문은 큰 모델을 작은 모델로 완전히 대체하자는 것이 아니다. 대신 local small LM과 cloud frontier model이 협업하면 cloud API 비용을 얼마나 줄이면서 품질을 유지할 수 있는지를 묻는다.

## 2. 대상 작업

원문은 긴 domain-specific document에서 정보를 검색하고 통합해야 하는 세 과제를 예로 든다.

| 작업 | 특징 |
|---|---|
| FinanceBench | 100페이지 규모 10-K report 기반 financial analysis |
| LongHealth | 환자 기록 기반 medical reasoning |
| QAsper | scientific paper 기반 question answering |

공통점은 context가 길고, 그중 일부 정보만 최종 답변에 필요하다는 점이다. 이 구조는 local model이 긴 context를 먼저 읽고 필터링할 여지를 만든다.

## 3. Minion: 단순 협업의 한계

첫 시도인 Minion은 on-device LM이 긴 데이터를 읽고 cloud model과 자유롭게 대화하는 방식이다. 이 방식은 긴 문서 전체를 cloud로 보내지 않기 때문에 비용을 크게 줄일 수 있지만, 품질 손실이 남는다.

원문은 한계로 두 가지를 든다. 첫째, 작은 모델은 context가 길어질수록 성능이 떨어진다. 둘째, 복잡하고 여러 단계로 된 instruction을 안정적으로 따르기 어렵다. 또한 단순 back-and-forth 대화는 local hardware의 batching 효율을 잘 쓰지 못한다.

## 4. Minions 프로토콜

Minions는 decomposition-execution-aggregation loop를 사용한다.

| 단계 | 역할 |
|---|---|
| Decompose | remote LM이 task를 작은 single-step subtask로 나누고, context chunking/decomposition code를 생성한다. |
| Execute | local LM이 context chunk 위에서 subtask를 병렬 실행하고, 관련성이 높은 출력만 remote LM에 보낸다. |
| Aggregate | remote LM이 local output을 결합해 답을 만들거나 추가 round를 요청한다. |

핵심은 cloud model이 긴 context 전체를 직접 읽지 않는다는 점이다. 대신 local side에서 context를 읽고, cloud side는 decomposition과 aggregation이라는 더 높은 수준의 reasoning 역할을 맡는다.

## 5. 비용-정확도 관점

원문은 단순 Minion이 cloud 비용의 3.3%만 사용하면서 cloud-only 성능의 87%를 유지했다고 설명한다. 개선된 Minions는 remote-only solution 대비 97.9% accuracy를 달성하면서 비용은 17.5% 수준으로 줄였다고 제시한다.

이 결과는 local compute를 더 쓰면 cloud 호출량을 줄일 수 있지만, protocol 설계가 중요하다는 점을 보여준다. 단순히 작은 모델에게 긴 문서를 읽기만 시키는 것이 아니라, 작은 단위 작업으로 나누고 병렬 실행한 뒤 cloud가 최종 집계하는 구조가 필요하다.

## QECO-Adapt와의 연결

Minions는 MEC offloading 논문은 아니지만, QECO-Adapt와 비교할 수 있는 broader motivation을 제공한다. 두 자료 모두 "계산을 어디서 수행할 것인가"를 다룬다.

| 비교 축 | QECO-Adapt | Minions |
|---|---|---|
| 로컬 주체 | UE/mobile device | Consumer device의 local small LM |
| 원격 주체 | AP/channel/resource를 거친 edge server | Cloud frontier model |
| 핵심 병목 | edge backlog, delay, energy, dropped task | cloud token cost, long-context cost, local model 한계 |
| 제어 방식 | load-adaptive reward/cost reweighting과 offloading gating | decomposition-execution-aggregation communication protocol |
| 공통 질문 | 어떤 계산을 로컬에 남기고, 어떤 계산을 원격으로 보낼 것인가? | 어떤 context 처리와 reasoning을 local/cloud에 나눌 것인가? |

QECO-Adapt의 UE -> AP -> channel/resource -> edge server 구조는 통신 지연, edge load, energy를 중심으로 offloading을 결정한다. Minions는 network/MEC 수식은 없지만, local small model이 긴 context 처리라는 계산을 담당하고 cloud model은 고난도 reasoning과 aggregation을 담당한다는 split framing을 제공한다.

따라서 QECO-Adapt 후속 설명에서는 Minions를 "AI workload도 점점 local-edge-cloud split 문제로 이동한다"는 motivation 자료로 활용할 수 있다.

## 핵심 내용

- Minions는 local small LM과 cloud frontier model의 협업으로 long-context task의 cloud 비용을 줄이는 프로토콜이다.
- 단순 local/cloud 대화 방식은 long context와 multi-step instruction에서 한계를 보인다.
- Minions는 remote LM이 task를 분해하고, local LM이 context chunk에서 subtask를 병렬 실행하고, remote LM이 결과를 집계한다.
- 원문은 Minions가 remote-only 대비 97.9% accuracy와 17.5% cost를 달성했다고 설명한다.
- MEC/QECO-Adapt 관점에서는 "계산을 어디서 수행할 것인가"라는 edge/cloud split motivation을 넓히는 참고자료가 된다.

## 해석 포인트

Minions를 MEC 연구에 연결할 때 주의할 점은, 이것이 직접적인 task offloading 최적화 논문은 아니라는 점이다. 그러나 local device와 cloud model 사이의 역할 분담, communication round, cost-accuracy trade-off는 MEC offloading의 큰 문제의식과 잘 맞는다.

## 참고자료

<ul>
  <li><a href="https://www.together.ai/blog/minions" target="_blank" rel="noopener">Together AI Blog: Minions</a></li>
  <li><a href="https://arxiv.org/abs/2502.15964" target="_blank" rel="noopener">Minions: Cost-efficient Collaboration Between On-device and Cloud Language Models paper</a></li>
</ul>
