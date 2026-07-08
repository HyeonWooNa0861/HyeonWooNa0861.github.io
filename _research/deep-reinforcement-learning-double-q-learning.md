---
layout: default
title: "Double DQN"
topic: "Overestimation reduction in deep Q-learning"
order: 12
---

# Deep Reinforcement Learning with Double Q-learning

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Deep Reinforcement Learning with Double Q-learning |
| 저자 | Hado van Hasselt, Arthur Guez, David Silver |
| 발표 | AAAI 2016 |
| 주제 | Reinforcement Learning, Q-learning, DQN, Overestimation Bias |
| 핵심 방법 | Double DQN |

## 한 줄 요약

Double DQN은 DQN의 target 계산에서 action selection과 action evaluation을 분리해 Q-value overestimation을 줄이고, Atari domain에서 더 안정적인 성능을 얻는 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | Q-learning의 max 연산은 왜 action value를 과대평가할 수 있는가? |
| 2 | DQN 한계 | Deep function approximation에서도 overestimation이 실제로 발생하는가? |
| 3 | Double Q-learning | selection과 evaluation을 분리하면 무엇이 달라지는가? |
| 4 | 결과 | overestimation 감소가 성능 개선으로 이어지는가? |

## 1. 문제 배경

Q-learning은 다음 상태에서 가능한 action value 중 최대값을 target으로 사용한다. 문제는 value estimate에 noise가 있을 때 max 연산이 우연히 높게 추정된 action을 고르기 쉽다는 점이다. 이로 인해 실제보다 큰 Q-value가 학습되고, policy가 불안정해질 수 있다.

## 2. 제안 방법

Double DQN은 online network로 다음 action을 선택하고, target network로 그 action의 value를 평가한다.

| 방식 | Target 계산 관점 |
|---|---|
| DQN | target network의 Q-value 중 max를 바로 사용 |
| Double DQN | online network가 argmax action 선택, target network가 해당 action 평가 |

이 분리는 같은 estimator가 선택과 평가를 동시에 수행하면서 생기는 positive bias를 줄인다.

## 3. 결과 및 해석

논문은 Atari 2600 domain에서 DQN이 일부 게임에서 Q-value를 실제 return보다 크게 추정한다는 것을 보이고, Double DQN이 이 overestimation을 완화한다고 보고한다. 중요한 점은 단순히 value scale이 낮아진 것이 아니라, 여러 게임에서 policy performance도 함께 개선되었다는 것이다.

## 4. 연구 맥락

QECO 및 MEC offloading 연구에서 DQN 계열을 사용할 때 target overestimation은 불안정한 action 선택으로 이어질 수 있다. Deadline, queue, energy cost가 얽힌 환경에서는 잘못 과대평가된 offloading action이 dropped task 누적으로 연결될 수 있으므로 Double DQN은 안정성 측면에서 중요하다.

## 핵심 내용

이 논문은 DQN이 강력하지만 Q-learning의 오래된 문제인 overestimation bias를 그대로 가질 수 있음을 보여준다. Max 연산은 여러 추정값 중 가장 큰 값을 고르기 때문에, 실제로 좋은 action이 아니라 우연히 높게 추정된 action을 target으로 삼을 수 있다.

Double DQN은 이 문제를 줄이기 위해 action을 고르는 network와 그 action의 값을 평가하는 network를 분리한다. Online network는 다음 상태에서 어떤 action이 좋아 보이는지 고르고, target network는 그 action의 Q-value를 계산한다. 이렇게 하면 같은 오차가 선택과 평가에 동시에 반영되는 정도가 줄어든다.

논문의 핵심은 이 아이디어가 tabular setting을 넘어 deep neural network function approximation에서도 작동한다는 점이다. MEC offloading처럼 action value가 queue state와 channel state에 따라 크게 변하는 문제에서도 이 원리는 안정적인 target 추정의 기본 장치로 볼 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/deep-reinforcement-learning-double-q-learning/deep-reinforcement-learning-double-q-learning.pdf" | relative_url }}" target="_blank" rel="noopener">Deep Reinforcement Learning with Double Q-learning PDF</a></li>
</ul>
