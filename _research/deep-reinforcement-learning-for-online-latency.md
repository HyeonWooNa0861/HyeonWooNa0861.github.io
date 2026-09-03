---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "DECENT"
topic: "Latency-aware online workload offloading and resource management in MEC"
order: 31
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "DECENT"
  - "MEC"
  - "Online offloading"
  - "Latency optimization"
---

# DECENT

Source PDF: `deep-reinforcement-learning-for-online-latency.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Deep Reinforcement Learning for Online Latency-Aware Workload Offloading in Mobile Edge Computing |
| 핵심 주제 | MEC에서 작업 도착 즉시 오프로딩 서버와 컴퓨팅 자원 할당을 함께 결정하는 DRL |
| 방법 | Advantage Actor-Critic 기반 DECENT |
| 목표 | 모든 작업의 누적 가중 응답 시간 최소화 |

## 한 줄 요약

DECENT는 MEC 서버 선택과 컴퓨팅 자원 할당을 별도 문제로 보지 않고, 통신 큐와 컴퓨팅 큐의 대기 시간, 작업 우선순위까지 상태로 넣어 실시간 의사결정을 학습하는 A2C 기반 오프로딩 알고리즘이다.

## 핵심 내용

- MEC 오프로딩에서는 네트워크 거리만이 아니라 통신 큐, 컴퓨팅 큐, 남은 CPU 자원, 작업 우선순위를 함께 봐야 한다.
- DECENT는 서버 선택과 자원 할당을 하나의 행동으로 묶어 A2C로 학습한다.
- 보상을 가중 응답 시간의 음수로 두어, 우선순위가 높은 작업의 지연을 더 적극적으로 줄인다.
- nearest server와 largest server 기준선은 각각 컴퓨팅 병목과 네트워크 병목을 놓칠 수 있다.
- 이 논문의 가치는 MEC의 온라인 의사결정을 "현재 작업만 빠르게 처리"가 아니라 "미래 작업까지 고려한 누적 지연 최소화" 문제로 본 데 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | MEC 오프로딩 문제 | 가장 가까운 서버가 항상 빠른가? |
| 2 | 지연 모델 | 네트워크 지연과 컴퓨팅 지연을 어떻게 합산하는가? |
| 3 | MDP 정식화 | 도착 작업마다 어떤 상태, 행동, 보상을 정의하는가? |
| 4 | DECENT | A2C로 서버 선택과 자원 할당을 어떻게 학습하는가? |
| 5 | 시뮬레이션 | nearest server, largest server 기준선보다 무엇이 나은가? |

## 1. 문제 배경

MEC는 IoT 작업을 원격 클라우드가 아니라 네트워크 엣지의 서버로 보내 응답 시간을 줄이려는 구조이다. 그러나 서버의 위치만 보고 가장 가까운 MEC 서버를 고르면, 그 서버의 컴퓨팅 큐가 길거나 남은 CPU 자원이 부족할 때 오히려 지연이 커질 수 있다.

이 논문은 작업이 오프로딩된다는 전제 아래, 각 작업을 어느 MEC 서버로 보낼지와 해당 작업에 얼마만큼의 컴퓨팅 자원을 줄지를 동시에 결정한다. 기존 연구와의 차이는 통신 큐 대기 시간, 컴퓨팅 큐 대기 시간, 작업 우선순위를 모두 고려한다는 점이다.

## 2. 지연 모델

작업 \(i\)를 MEC 서버 \(k\)에 보낼 때 응답 시간은 네트워크 지연과 컴퓨팅 지연의 합이다.

$$T_{ik}=T^{net}_{ik}+T^{comp}_{ik}.$$

네트워크 지연은 전송 시간, E2E 지연, 통신 큐 대기 시간으로 구성된다.

$$T^{net}_{ik}=\frac{l_i}{w_k}+T^{e2e}_{ik}+\sum_{j\in I_{ik}}\frac{l_j}{w_k}.$$

컴퓨팅 지연은 실행 시간과 컴퓨팅 큐 대기 시간을 포함한다.

$$T^{comp}_{ik}=\frac{\mu l_i}{r_{ik}}+\sum_{j\in I_{ik}}\frac{\mu l_j}{r_{jk}}.$$

여기서 \(l_i\)는 작업 크기, \(w_k\)는 경로 용량, \(r_{ik}\)는 작업에 할당된 컴퓨팅 자원, \(\mu\)는 작업 크기를 CPU cycle로 바꾸는 계수이다.

## 3. 최적화 문제

논문의 목적함수는 작업 우선순위 \(\eta_i\)를 곱한 가중 응답 시간의 합을 최소화하는 것이다.

$$\min_{\{r_{ik},x_{ik}\}}\sum_{i\in I}\eta_i\sum_{k\in K}x_{ik}\left(T^{comp}_{ik}+T^{net}_{ik}\right).$$

\(x_{ik}\)는 작업 \(i\)가 서버 \(k\)로 오프로딩되는지를 나타내는 이진 변수이고, 각 작업은 정확히 하나의 MEC 서버로만 보내진다. 이 문제는 미래 작업 도착을 알기 어렵고, 전체 문제 자체도 NP-hard이므로 실시간 최적화로 직접 풀기 어렵다.

## 4. DECENT의 MDP 구성

DECENT는 문제를 MDP로 바꾼다. 상태에는 새 작업의 크기와 가중치, 각 MEC 서버의 남은 컴퓨팅 자원, 컴퓨팅 큐 workload, 통신 큐 대기 시간이 들어간다. 행동은 목적지 MEC 서버 선택 \(x_{ik}\)와 컴퓨팅 자원 할당 \(r_{ik}\)의 조합이다.

보상은 가중 응답 시간의 음수로 둔다.

$$r_i=-\eta_i\sum_{k\in K}x_{ik}\left(T^{comp}_{ik}+T^{net}_{ik}\right).$$

따라서 정책은 즉시 지연만 줄이는 것이 아니라, 할인된 누적 보상을 통해 미래 작업의 성능까지 반영하도록 학습된다.

## 5. A2C 기반 학습

DECENT는 actor network와 critic network를 둔다. Actor는 현재 상태에서 행동 분포를 출력하고, critic은 상태 가치를 추정해 advantage를 계산한다.

$$A(s_i,a_i)=r_i+\gamma V_\upsilon(s_{i+1})-V_\upsilon(s_i).$$

논문은 actor와 critic 모두 128개 neuron을 가진 hidden layer를 사용하며, 학습 중에는 \(\epsilon\)-greedy 방식으로 탐색한다. 학습이 끝나면 도착 작업마다 actor가 서버와 자원량을 실시간으로 결정한다.

## 6. 실험 결과 해석

시뮬레이션은 1개 BS와 4개 MEC 서버를 두고 수행된다. 기준선은 가장 가까운 서버를 고르는 nearest server와 남은 컴퓨팅 자원이 가장 큰 서버를 고르는 largest server이다.

결과적으로 DECENT는 작업 도착률이 증가해도 평균 가중 응답 시간을 낮게 유지한다. 특히 작업 가중치가 큰 class에 더 낮은 지연을 제공하므로, 단순한 부하 분산이 아니라 우선순위 기반 자원 배분을 학습했다는 점이 중요하다.

## 해석 포인트

DECENT의 핵심은 DRL을 썼다는 사실보다 상태 설계에 있다. 큐 대기 시간과 작업 우선순위가 빠지면, 정책은 가까운 서버나 큰 서버를 고르는 휴리스틱과 크게 달라지기 어렵다. 반대로 이 정보가 상태에 들어가면 정책은 지연의 원인이 네트워크인지 컴퓨팅인지, 그리고 해당 작업이 얼마나 급한지를 구분할 수 있다.

## 한계와 향후 과제

시뮬레이션 기반 검증이므로 실제 MEC 환경에서의 상태 관측 지연, 예측 오차, 서버 간 제어 오버헤드는 추가 검증이 필요하다. 또한 모든 작업이 이미 오프로딩 대상이라고 가정하므로, 로컬 실행과 오프로딩 여부를 함께 결정하는 문제까지 확장하면 정책 공간이 더 커진다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/deep-reinforcement-learning-for-online-latency/deep-reinforcement-learning-for-online-latency.pdf" | relative_url }}" target="_blank" rel="noopener">Deep Reinforcement Learning for Online Latency-Aware Workload Offloading in Mobile Edge Computing PDF</a></li>
</ul>
