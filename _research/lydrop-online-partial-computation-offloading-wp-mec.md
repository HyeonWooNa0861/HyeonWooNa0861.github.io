---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "LyDROP"
topic: "Online partial offloading in wireless powered MEC"
order: 24
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "LyDROP"
  - "Partial offloading"
  - "Wireless powered MEC"
  - "Lyapunov optimization"
---

# LyDROP: Online Partial Computation Offloading in WP-MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Online Partial Computation Offloading Optimization in Wireless Powered Mobile Edge Computing Network |
| 저자 | Lu Sun, Rina Liang, Liangtian Wan, Kaihui Liu, Zhaolong Ning, Jie Wang |
| 출처 | IEEE Transactions on Cognitive Communications and Networking, 2026 |
| 주제 | Wireless Powered MEC, Partial Offloading, Lyapunov Optimization, DRL |
| 핵심 방법 | LyDROP |

## 한 줄 요약

LyDROP은 wireless powered MEC에서 binary offloading보다 유연한 partial offloading을 다루기 위해, Lyapunov optimization과 DRL을 결합해 WPT duration, partial offloading decision, transmission time allocation을 함께 최적화한다.

## 핵심 내용

이 논문은 task를 전부 local에서 처리하거나 전부 edge로 보내는 binary offloading의 한계를 다룬다. 어떤 task는 일부만 offload하는 것이 energy와 delay 측면에서 더 좋을 수 있다. 그러나 partial offloading은 선택지가 많아져 optimization이 어려워진다.

LyDROP은 Lyapunov optimization을 사용해 장기 queue와 rate 목표를 frame별 문제로 바꾼다. 이후 DRL과 model-based optimization을 결합해 WPT 시간, offloading 비율, 전송 시간 배분을 결정한다.

핵심은 flexibility와 complexity의 균형이다. Partial offloading은 더 좋은 resource utilization을 만들 수 있지만, action space가 커져 decision latency와 학습 안정성이 문제가 될 수 있다. LyDROP은 이 문제를 online framework로 다루는 대표 사례다.

이 글을 읽을 때는 LyDROP이 단순히 "DRL을 쓴 offloading"이 아니라 wireless powered 환경의 energy harvesting constraint를 함께 다룬다는 점을 잡아야 한다. WPT duration을 길게 잡으면 에너지는 늘지만 task 처리와 전송에 쓸 시간이 줄고, 반대로 WPT를 줄이면 immediate computation은 가능해도 queue 안정성이 나빠질 수 있다. Lyapunov 항은 이 장기 안정성 문제를 단기 decision 안으로 끌어오는 장치다.

또한 partial offloading은 binary offloading보다 항상 우월하다고 단정하면 안 된다. Task가 실제로 분할 가능한 구조인지, edge와 local execution 사이의 synchronization overhead가 얼마나 되는지, transmission time allocation을 얼마나 빠르게 계산할 수 있는지가 함께 맞아야 한다. 따라서 LyDROP의 가치는 partial offloading 자체보다, WPT/queue/offloading ratio를 한 프레임 안에서 함께 조정하는 방식에 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | Binary offloading만으로는 task 특성을 충분히 반영하기 어려운가? |
| 2 | Partial offloading | Task를 어느 비율로 local/edge에 나눌 것인가? |
| 3 | Lyapunov + DRL | Online random environment에서 queue backlog와 computation rate를 어떻게 균형화하는가? |
| 4 | 결과 | Weighted sum computation rate와 queue stability를 동시에 개선하는가? |

## 1. 문제 배경

Wireless powered MEC에서는 device가 wireless power transfer로 에너지를 얻고 task를 처리한다. Binary offloading은 task 전체를 local 또는 edge 중 하나로 보내지만, 실제 task는 일부만 offload하는 것이 더 효율적일 수 있다.

Partial offloading은 유연하지만 decision space가 커진다. Offloading ratio, WPT duration, transmission time allocation이 함께 결정되어야 하므로 online optimization이 어려워진다.

## 2. 제안 방법

LyDROP은 Lyapunov optimization으로 stochastic online problem을 per-frame deterministic problem으로 나누고, model-based optimization과 model-free DRL을 결합한다.

| 변수 | 역할 |
|---|---|
| WPT duration | device energy harvesting 시간 |
| Partial offloading decision | task 중 edge로 보낼 비율 |
| Transmission time allocation | offloaded data 전송 시간 배분 |
| Queue backlog | 안정성과 delay pressure 반영 |

## 3. 결과 및 해석

논문은 LyDROP이 wireless powered MEC의 random channel/task 환경에서 weighted sum computation rate를 높이고 backlog를 줄이는 방향으로 동작한다고 설명한다. Binary offloading보다 decision이 복잡하지만, task 특성을 더 세밀하게 활용할 수 있다는 장점이 있다.

## 4. 연구 맥락

QECO 계열 연구가 binary 또는 discrete action 중심이라면, LyDROP은 partial offloading이라는 더 연속적이고 세밀한 decision space를 다룬다. Dense MEC 확장에서는 partial offloading이 load balancing을 더 부드럽게 만들 가능성이 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/lydrop-online-partial-computation-offloading-wp-mec/lydrop-online-partial-computation-offloading-wp-mec.pdf" | relative_url }}" target="_blank" rel="noopener">LyDROP PDF</a></li>
</ul>
