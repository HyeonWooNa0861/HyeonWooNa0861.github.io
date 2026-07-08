---
layout: default
title: "Human-Level Control with DQN"
topic: "Deep Q-network for Atari control"
order: 16
---

# Human-Level Control through Deep Reinforcement Learning

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Human-level control through deep reinforcement learning |
| 저자 | Volodymyr Mnih et al. |
| 발표 | Nature 2015 |
| 주제 | Deep Reinforcement Learning, DQN, Atari, Experience Replay |
| 핵심 방법 | Deep Q-Network |

## 한 줄 요약

이 논문은 raw pixel observation을 입력으로 받아 Atari game control policy를 학습하는 Deep Q-Network를 제안해, deep learning과 reinforcement learning을 결합한 대표적 전환점을 만든 연구다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 고차원 sensory input에서 직접 control policy를 학습할 수 있는가? |
| 2 | DQN 구조 | CNN이 action-value function을 어떻게 근사하는가? |
| 3 | 안정화 | Experience replay와 target network는 왜 필요한가? |
| 4 | 결과 | 여러 Atari 게임에서 human-level control에 도달하는가? |

## 1. 문제 배경

Reinforcement learning은 누적 보상을 최대화하는 policy를 학습하지만, neural network 같은 nonlinear function approximator를 함께 쓰면 학습이 불안정해질 수 있다. 특히 raw pixel처럼 고차원 입력을 그대로 사용하는 경우 representation learning과 control learning을 동시에 해결해야 한다.

## 2. 제안 방법

DQN은 convolutional neural network로 Q-function을 근사한다. 입력은 최근 frame stack이고, 출력은 각 action의 Q-value다.

| 구성 | 역할 |
|---|---|
| CNN feature extractor | pixel observation에서 state representation 학습 |
| Q-value output | 가능한 action별 expected return 추정 |
| Experience replay | correlated sample을 완화하고 data efficiency 향상 |
| Target network | target value의 급격한 변화를 줄여 학습 안정화 |

## 3. 결과 및 해석

논문은 동일한 architecture와 hyperparameter로 다양한 Atari 게임을 학습해, 여러 게임에서 기존 알고리즘보다 높은 성능을 보였다. 중요한 점은 game-specific feature engineering 없이 raw pixel 기반으로 policy를 학습했다는 것이다.

## 4. 연구 맥락

QECO, DROO, LyDROO 같은 MEC offloading 연구에서 DQN 계열을 사용하는 배경에는 이 논문이 있다. MEC 상태는 pixel은 아니지만 channel, queue, energy, deadline 등 고차원 상태를 action value로 연결해야 한다는 점에서 DQN의 function approximation 관점이 이어진다.

## 핵심 내용

이 논문은 deep reinforcement learning의 대표적 출발점으로 볼 수 있다. 기존 RL은 사람이 설계한 feature를 사용하거나 작은 state space에 머무는 경우가 많았지만, DQN은 raw pixel에서 직접 action value를 학습한다.

핵심 안정화 장치는 experience replay와 target network다. Replay buffer는 연속된 경험의 상관관계를 줄이고, target network는 target Q-value가 매 step 크게 흔들리는 문제를 줄인다. 이 두 요소가 없으면 nonlinear network와 bootstrapping이 결합된 Q-learning은 쉽게 불안정해질 수 있다.

MEC 연구에서 DQN을 사용할 때도 같은 논리가 적용된다. Offloading agent는 현재 상태에서 local 처리, edge offloading, server 선택 등의 action value를 추정해야 한다. 따라서 DQN의 구조와 안정화 장치는 이후 MEC DRL 논문들의 기반으로 이해할 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/human-level-control-deep-reinforcement-learning/human-level-control-deep-reinforcement-learning.pdf" | relative_url }}" target="_blank" rel="noopener">Human-Level Control through Deep Reinforcement Learning PDF</a></li>
</ul>
