---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "General Task Graph Offloading"
topic: "DRL-based offloading and resource allocation for general task graphs in MEC"
order: 33
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "MEC"
  - "task graph offloading"
  - "DRL"
  - "resource allocation"
---

# General Task Graph Offloading

Source PDF: `offloading-and-resource-allocation-with-general-task.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Offloading and Resource Allocation with General Task Graph in Mobile Edge Computing: A Deep Reinforcement Learning Approach |
| 저자 | Jia Yan, Suzhi Bi, Ying-Jun Angela Zhang |
| 핵심 주제 | 일반 DAG task graph를 갖는 모바일 애플리케이션의 오프로딩 및 자원 할당 |
| 방법 | Actor-critic DRL, GNOP 행동 생성, critic의 저복잡도 최적화 평가 |
| 목표 | 모바일 장치의 energy-time cost 최소화 |

## 한 줄 요약

이 논문은 태스크 간 의존성이 일반 DAG로 주어질 때, DRL actor가 오프로딩 후보를 만들고 analytic critic이 각 후보의 energy-time cost를 빠르게 평가하게 하여 조합적 오프로딩 문제를 낮은 복잡도로 푸는 방법을 제안한다.

## 핵심 내용

- 일반 task graph에서는 태스크 의존성 때문에 오프로딩 결정이 강하게 결합된다.
- 목적함수는 모바일 장치의 에너지 소비와 전체 실행 시간을 함께 반영하는 ETC이다.
- Actor는 채널과 엣지 CPU 상태에서 오프로딩 후보를 생성하고, critic은 analytic optimization으로 각 후보의 ETC를 계산한다.
- GNOP 양자화는 DNN 출력 주변의 후보와 noise 기반 후보를 함께 만들어 탐색 다양성을 확보한다.
- One-climb 제약은 행동 공간을 줄이는 실용적 장치이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 일반 task graph | 순차 작업과 달리 무엇이 어려운가? |
| 2 | ETC 목적함수 | 에너지와 실행 시간을 어떻게 함께 최소화하는가? |
| 3 | 고정 offloading 해석 | 오프로딩이 주어지면 CPU 주파수를 어떻게 최적화하는가? |
| 4 | DRL 구조 | Actor가 후보 행동을 만들고 critic이 어떻게 평가하는가? |
| 5 | One-climb 정책 | 행동 공간을 어떻게 줄이는가? |

## 1. 문제 배경

모바일 애플리케이션은 독립적인 단일 태스크가 아니라 여러 구성요소로 이루어진 경우가 많다. 어떤 구성요소의 출력이 다른 구성요소의 입력이 되므로, 오프로딩 결정은 task graph의 의존성과 함께 결정되어야 한다.

이 논문은 단일 AP와 모바일 장치가 있는 MEC 시스템에서, 일반적인 방향성 비순환 그래프 \(G=(M,E)\)로 표현되는 애플리케이션을 고려한다. 각 태스크는 로컬에서 실행되거나 엣지 서버로 오프로딩된다.

## 2. Energy-Time Cost

각 태스크 \(i\)의 오프로딩 결정은 \(a_i\in\{0,1\}\)로 표현된다. \(a_i=0\)이면 로컬 실행, \(a_i=1\)이면 엣지 실행이다. 진입 태스크와 종료 태스크는 로컬에서 실행되도록 강제되어 애플리케이션이 모바일 장치에서 시작하고 끝나게 한다.

논문의 성능 지표는 energy-time cost, 즉 에너지 소비와 전체 실행 시간의 가중합이다.

$$ETC=\beta_e E+\beta_t T,\qquad \beta_t=1-\beta_e.$$

배터리가 중요한 상황에서는 \(\beta_e\)를 크게 두고, 지연이 중요한 상황에서는 \(\beta_t\)를 크게 둘 수 있다.

## 3. 일반 DAG가 어려운 이유

순차 task graph에서는 실행 위치가 로컬에서 엣지로 한 번만 이동하는 one-climb 구조가 자연스럽게 등장할 수 있다. 그러나 일반 DAG에서는 여러 경로가 서로 태스크를 공유하고, 한 경로의 오프로딩 결정이 다른 경로의 준비 시간과 완료 시간에 영향을 준다.

따라서 가능한 오프로딩 행동은 \(2^{M}\)개로 커지고, 채널 상태와 엣지 CPU 주파수가 변할 때마다 기존 최적화 문제를 다시 푸는 방식은 실용적이지 않다.

## 4. 고정된 오프로딩 결정 아래의 자원 할당

논문은 먼저 오프로딩 결정 \(a\)가 주어졌다고 가정한다. 이 경우 남는 문제는 로컬 CPU 주파수 또는 실행 시간을 조정해 ETC를 줄이는 문제이며, 모든 loop-free path의 실행 시간을 이용해 볼록 문제로 단순화할 수 있다.

핵심은 전체 완료 시간이 종료 태스크의 완료 시간이며, 이는 task graph의 모든 경로 중 가장 긴 실행 시간으로 표현될 수 있다는 점이다. 이를 이용해 projected subgradient method로 최적 로컬 CPU 주파수를 구한다.

## 5. Actor-Critic DRL 구조

Actor network는 현재 상태, 즉 무선 채널 이득과 엣지 CPU 주파수를 입력으로 받아 완화된 오프로딩 벡터를 출력한다. 이 연속값은 이진 오프로딩 후보로 양자화되어야 한다.

논문은 Gaussian noise-added order-preserving, 즉 GNOP 양자화를 제안한다. 일부 후보는 DNN 출력의 순서를 보존해 만들고, 나머지는 Gaussian noise를 더한 뒤 양자화해 탐색 다양성을 확보한다.

Critic은 일반적인 value network가 아니다. Actor가 만든 각 후보 오프로딩 행동에 대해, 앞서 도출한 저복잡도 최적화 알고리즘으로 ETC를 직접 계산한다. 이 점이 이 논문의 중요한 설계이다. Critic을 학습시키는 대신 구조적 최적화 해석을 넣어 행동 평가를 더 정확하고 빠르게 만든다.

## 6. One-Climb 정책

복잡도를 더 줄이기 위해 논문은 one-climb 정책을 사용한다. 각 경로에서 태스크 실행 위치가 모바일 장치에서 엣지 서버로 최대 한 번만 이동하도록 후보 행동을 제한한다.

일반 DAG에서 one-climb이 항상 전역 최적을 보장하는 것은 아니지만, 후보 행동 수를 크게 줄이고 실제 성능을 유지하는 휴리스틱으로 사용된다. 논문은 two-time offloading 방식보다 one-climb 방식이 특정 경로의 비용을 줄일 수 있음을 분석한다.

## 7. 실험 결과 해석

실험은 mesh, tree, mesh와 tree가 결합된 일반 task graph를 대상으로 한다. 제안 알고리즘은 최적 성능의 최대 99.1%에 도달하면서, 행동 생성에 필요한 시간을 기존 대표 최적화 방법보다 크게 줄인다.

중요한 점은 단순히 DRL이 최적화를 대체한다는 이야기가 아니라, actor가 행동 후보를 빠르게 만들고 critic이 문제 구조를 이용해 후보를 정확히 평가한다는 hybrid 설계이다.

## 해석 포인트

이 논문의 강점은 "DRL로 모든 것을 학습"하지 않는 데 있다. 학습이 잘하는 부분은 상태에서 유망한 행동 후보를 빠르게 생성하는 것이고, 최적화가 잘하는 부분은 후보 행동의 비용을 정확히 평가하는 것이다. 두 역할을 분리했기 때문에 일반 DAG의 큰 행동 공간을 다루면서도 성능을 유지한다.

## 한계와 향후 과제

One-climb 제한은 복잡도를 줄이지만 모든 일반 DAG에서 최적성을 보장하지는 않는다. 또한 논문 설정은 단일 모바일 장치와 단일 AP를 중심으로 하므로, 다중 사용자 간 경쟁, 서버 큐, 무선 간섭까지 포함하면 행동과 상태 공간이 더 커진다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/offloading-and-resource-allocation-with-general-task/offloading-and-resource-allocation-with-general-task.pdf" | relative_url }}" target="_blank" rel="noopener">Offloading and Resource Allocation with General Task Graph PDF</a></li>
</ul>
