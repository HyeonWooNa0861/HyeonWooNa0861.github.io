---
layout: default
title: "Dueling DQN"
topic: "Value and advantage decomposition in deep reinforcement learning"
order: 15
---

# Dueling Network Architectures for Deep Reinforcement Learning

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Dueling Network Architectures for Deep Reinforcement Learning |
| 저자 | Ziyu Wang, Tom Schaul, Matteo Hessel, Hado van Hasselt, Marc Lanctot, Nando de Freitas |
| 발표 | ICML 2016 |
| 주제 | Deep Reinforcement Learning, DQN, Value Function, Advantage Function |
| 핵심 방법 | Dueling Network Architecture |

## 한 줄 요약

Dueling DQN은 Q-value를 state value와 action advantage로 분해해, 비슷한 action이 많은 상태에서도 state의 중요도를 더 안정적으로 학습하게 만드는 network architecture다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 모든 상태에서 action 차이가 명확하지 않을 때 Q-value를 어떻게 더 잘 학습할 수 있는가? |
| 2 | 핵심 구조 | Value stream과 advantage stream을 왜 분리하는가? |
| 3 | 결합 방식 | 두 stream을 어떻게 다시 Q-value로 합치는가? |
| 4 | 결과 | Atari 환경에서 policy evaluation과 성능이 개선되는가? |

## 1. 문제 배경

일부 상태에서는 어떤 action을 선택해도 결과가 크게 다르지 않다. 이런 경우 Q-value를 action별로 모두 독립적으로 추정하면 학습 효율이 떨어질 수 있다. 상태 자체가 좋은지 나쁜지와 특정 action이 평균보다 얼마나 좋은지를 분리해 학습하면 더 안정적인 value estimation이 가능하다.

## 2. 제안 방법

Dueling architecture는 neural network의 마지막 부분을 두 stream으로 나눈다.

| Stream | 의미 |
|---|---|
| Value stream | 상태 \\(s\\) 자체의 가치 \\(V(s)\\) 추정 |
| Advantage stream | 특정 action \\(a\\)가 평균보다 얼마나 좋은지 \\(A(s,a)\\) 추정 |

최종 Q-value는 두 값을 결합해 얻는다. 이때 advantage의 평균을 빼는 방식으로 identifiability 문제를 완화한다.

## 3. 결과 및 해석

논문은 dueling architecture가 Atari domain에서 기존 DQN 대비 성능을 개선할 수 있음을 보인다. 특히 action value가 비슷한 상태가 많은 환경에서 state value를 빠르게 학습하는 장점이 있다.

## 4. 연구 맥락

MEC offloading에서도 많은 action이 비슷한 cost를 가질 수 있다. 예를 들어 부하가 낮은 상태에서는 local과 edge offloading의 차이가 작을 수 있고, 특정 edge 간 차이가 미세할 수 있다. Dueling architecture는 이런 상황에서 state quality와 action-specific advantage를 분리해 학습 안정성을 높인다.

## 한국어 번역형 해설

이 논문은 DQN의 network architecture를 바꾸는 방식으로 reinforcement learning 성능을 개선한다. 핵심 아이디어는 모든 상태에서 action 차이가 중요한 것은 아니라는 점이다. 어떤 상태는 action 선택보다 state 자체가 유리한지 불리한지가 더 중요하다.

Dueling DQN은 value stream과 advantage stream을 분리한다. Value stream은 현재 상태가 전반적으로 좋은지를 보고, advantage stream은 특정 action이 다른 action보다 얼마나 나은지를 본다. 두 stream을 합쳐 Q-value를 만들면 action 간 차이가 작을 때도 state value를 더 효율적으로 배울 수 있다.

QECO 같은 offloading 문제에서 dueling DQN은 edge load 상태의 전반적 위험도와 특정 offloading action의 상대적 이점을 분리해 해석하는 데 도움이 된다. 따라서 단순 game-playing architecture가 아니라 MEC DRL에서도 실용적인 value estimation 구조로 읽을 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/dueling-network-architectures-deep-reinforcement-learning/dueling-network-architectures-deep-reinforcement-learning.pdf" | relative_url }}" target="_blank" rel="noopener">Dueling Network Architectures PDF</a></li>
</ul>
