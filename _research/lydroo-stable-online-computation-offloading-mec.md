---
layout: default
title: "LyDROO"
topic: "Lyapunov-guided DRL for stable online computation offloading"
order: 22
---

# LyDROO: Stable Online Computation Offloading in MEC

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Lyapunov-Guided Deep Reinforcement Learning for Stable Online Computation Offloading in Mobile-Edge Computing Networks |
| 저자 | Suzhi Bi, Liang Huang, Hui Wang, Ying-Jun Angela Zhang |
| 출처 | IEEE Transactions on Wireless Communications, 2021 |
| 주제 | MEC, Lyapunov Optimization, DRL, Queue Stability, Online Offloading |
| 핵심 방법 | LyDROO |

## 한 줄 요약

LyDROO는 stochastic MEC offloading 문제에서 장기 queue stability와 average power constraint를 보장하기 위해 Lyapunov optimization으로 per-frame subproblem을 만들고, DRL로 binary offloading decision을 빠르게 근사하는 framework다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | Online offloading에서 throughput, queue stability, power constraint를 동시에 만족할 수 있는가? |
| 2 | Lyapunov | 장기 stochastic problem을 per-frame deterministic problem으로 어떻게 분해하는가? |
| 3 | DRL | 각 frame의 binary offloading decision을 어떻게 빠르게 얻는가? |
| 4 | 안정성 | Queue stability 보장이 DRL framework와 어떻게 결합되는가? |

## 1. 문제 배경

MEC 환경에서는 channel condition과 task arrival이 time-varying stochastic process로 나타난다. 각 frame에서 미래 정보를 알 수 없으므로, online algorithm은 현재 상태만 보고 offloading과 resource allocation을 결정해야 한다.

목표는 network data processing capability를 높이면서 long-term data queue stability와 average power constraint를 만족하는 것이다.

## 2. 제안 방법

LyDROO는 Lyapunov optimization과 DRL을 결합한다.

| 구성 | 역할 |
|---|---|
| Lyapunov optimization | 장기 stochastic MINLP를 per-frame deterministic MINLP로 decouple |
| DRL/DNN | binary offloading decision을 빠르게 생성 |
| Resource allocation | offloading decision에 따른 continuous resource 최적화 |
| Queue-aware control | data backlog를 안정성 조건에 반영 |

이 구조는 DROO의 learning speed 장점에 Lyapunov 기반 안정성 관점을 추가한다.

## 3. 결과 및 해석

논문은 LyDROO가 queue stability를 고려하면서 높은 processing capability를 달성할 수 있음을 보인다. 단순 DRL이 reward maximization에 집중해 backlog 안정성을 놓칠 수 있는 반면, Lyapunov term은 queue pressure를 decision에 직접 반영한다.

## 4. 연구 맥락

QECO-Adapt는 dropped task와 dense load 문제를 다루며, LyDROO는 queue stability 보장 관점에서 중요한 비교 축이다. 두 연구 모두 online MEC 환경에서 단기 reward보다 장기 안정성이 중요하다는 문제의식을 공유한다.

## 핵심 내용

이 논문은 online computation offloading에서 성능만 높이는 것이 아니라 queue가 안정적으로 유지되어야 한다는 점을 강조한다. Task가 계속 도착하는 상황에서 처리량이 순간적으로 높아도 backlog가 계속 증가하면 시스템은 결국 불안정해진다.

LyDROO는 Lyapunov optimization으로 장기 제약을 frame별 문제로 바꾼다. 이렇게 하면 미래 channel과 task arrival을 몰라도 현재 queue와 channel 상태를 기준으로 decision을 내릴 수 있다. 이후 DRL은 binary offloading decision을 빠르게 생성하는 역할을 한다.

핵심은 이론적 안정성 도구와 learning-based approximation을 결합했다는 점이다. MEC 연구에서 단순히 reward가 높은 policy보다 queue stability와 power constraint를 함께 만족하는 policy가 중요하다는 것을 보여주는 논문이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/lydroo-stable-online-computation-offloading-mec/lydroo-stable-online-computation-offloading-mec.pdf" | relative_url }}" target="_blank" rel="noopener">LyDROO PDF</a></li>
</ul>
