---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 17: Robot Learning"
course: "CS231N"
topic: "Robot Learning"
order: 17
major_topic: "Computer Vision"
keywords:
  - "Robot Learning"
  - "Imitation Learning"
  - "Reinforcement Learning"
  - "Control"
  - "Embodied AI"
---

# Stanford CS231N Lecture 17: Robot Learning

Source: [Stanford CS231N Spring 2025 Lecture 17](https://www.youtube.com/watch?v=XSfmOH_xVSU){:target="_blank" rel="noopener"}

> **핵심:** Robot learning은 perception의 출력에 action을 붙이는 문제가 아니다. Action이 다음 observation을 바꾸는 **closed loop**에서 reward, dynamics, demonstration, planning을 함께 다뤄야 하며, 최근 foundation policy도 이 상호작용 data의 한계를 벗어날 수 없다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Sequential decision making | State, action, reward, transition은 어떻게 연결되는가? |
| 2 | Reinforcement learning | Delayed reward와 exploration을 어떻게 다루는가? |
| 3 | Model-based planning | 미래 state를 예측해 action을 고를 수 있는가? |
| 4 | Imitation and diffusion policy | Multimodal demonstration을 어떤 action distribution으로 학습하는가? |
| 5 | VLA foundation models | RT-1, RT-2, RT-X, OpenVLA는 무엇을 generalize하려 하는가? |

## 1. Perception-action loop

Agent는 state 또는 observation \(s_t\)를 받아 action \(a_t\)를 선택하고, environment는 다음 state \(s_{t+1}\)와 reward \(r_t\)를 돌려준다. 목표는 한 번의 정답이 아니라 시간에 걸친 discounted return

$$
G_t=\sum_{k=0}^{\infty}\gamma^k r_{t+k}
$$

을 크게 하는 policy \(\pi(a\mid s)\)를 찾는 것이다. Cart-pole, game pixel, board game, chatbot, cloth folding 사례는 state와 action의 형태가 달라도 이 구조로 표현됨을 보여준다.

Robot에서는 완전한 physical state를 직접 알기 어렵고 camera·touch 등 noisy observation만 받는다. 또한 action이 object pose와 다음 camera view까지 바꾸므로 perception error와 control error가 누적된다. 때로는 물체를 건드리는 action 자체가 숨은 속성을 알아내는 active perception이 된다.

## 2. Reinforcement learning의 힘과 비용

Model-free RL은 interaction에서 얻은 reward로 value나 policy를 학습한다. Action value는

$$
Q^\pi(s,a)=\mathbb{E}_\pi[G_t\mid s_t=s,a_t=a]
$$

처럼 현재 선택의 장기 결과를 요약한다. 높은 \(Q\)의 action을 고르기만 하면 exploitation은 되지만, 아직 모르는 행동을 시도하는 exploration도 필요하다.

Supervised learning과 달리 data distribution이 policy에 따라 바뀌고, 같은 action의 결과도 stochastic하며, reward가 성공 끝에 늦게 올 수 있다. Physical robot에서 대규모 trial-and-error는 느리고 위험하며 장비를 마모시킨다. Simulation은 scale을 돕지만 dynamics와 appearance 차이로 sim-to-real gap이 생긴다.

## 3. Dynamics model과 model-predictive control

Model-based 접근은 forward model

$$
\widehat{s}_{t+1}=f_\theta(s_t,a_t)
$$

을 학습해 후보 action sequence의 결과를 상상한다. 현재 state에서 목표에 가까워지는 sequence를 찾고 첫 action만 실행한 뒤 새 observation에서 다시 계획하는 방식이 model-predictive control이다. 매 step 재계획하면 model error와 외부 변화에 대응할 수 있다.

Pixel dynamics는 raw image를 직접 예측할 수 있지만 불필요한 appearance까지 맞춰야 한다. Object/keypoint/latent representation은 planning에 필요한 구조만 보존해 더 효율적일 수 있다. 어떤 state representation을 쓸지가 dynamics accuracy와 action optimization 난도를 함께 결정한다.

## 4. Imitation learning과 distribution shift

Behavior cloning은 expert demonstration의 \((s,a)\) pair로 supervised policy를 학습한다. Reward 설계나 위험한 exploration 없이 복잡한 manipulation을 배울 수 있다. 그러나 학습 data에 없는 state에서 작은 실수가 나면 다음 state가 더 멀어지고 오류가 누적된다.

이를 줄이려면 실행 중 방문하는 state에서 expert label을 더 모으거나, diverse demonstration과 corrective data를 수집하고, imitation으로 초기화한 뒤 RL 또는 planning으로 보완할 수 있다. 강의의 deformable-object manipulation 사례는 perception과 learned dynamics, planning을 결합하는 이유를 보여준다.

단순 regression policy는 같은 관찰에서 여러 유효한 행동이 가능한 demonstration을 평균내 어색한 action을 만들 수 있다. Energy-based implicit behavior cloning은 observation-action pair에 score를 주고 inference에서 좋은 action을 찾으며, **diffusion policy**는 generative diffusion model을 policy function class로 사용해 multimodal action distribution을 표현한다. 강의는 butter spreading, scrambled eggs, potato peeling, book sliding처럼 fine-grained manipulation을 demonstration에서 빠르게 학습한 사례를 보여주되, 신뢰성과 초기 조건 generalization에는 반복적인 data collection이 필요하다고 선을 긋는다.

## 5. Robot foundation policy와 world model

최근 robot foundation model은 image, language instruction, proprioception을 받아 action token이나 trajectory를 출력하려 한다. Vision-language pretraining의 지식은 task 이해를 돕지만 정확한 contact dynamics와 embodiment별 control은 robot interaction data가 필요하다. Language model처럼 web에서 사실상 무한 data를 얻기 어려운 것이 핵심 bottleneck이다.

강의는 이 흐름을 2022년 12월 공개된 **RT-1**에서 시작해 **RT-2, RT-X, OpenVLA**로 이어지는 계보로 정리한다. 이들은 observation과 language task specification에서 action을 내는 Vision-Language-Action(VLA) policy라는 공통 목표를 가지며, 한 task 전용 policy보다 넓은 상황에서 매끄럽고 instruction-consistent한 trajectory를 생성하려 한다. 이어지는 공통 pipeline 설명에서는 academia와 자체 수집 data를 여러 embodiment에 걸쳐 모아 pretraining의 연료로 사용한다. 강의는 이 네 모델의 architecture를 각각 비교하기보다 역사적 전개와 generalization 목표를 중심으로 소개한다.

Generalization은 새로운 object뿐 아니라 새로운 task, scene, robot body까지 포함한다. 강의는 foundation policy, predictive world model, scalable robot data, post-training과 evaluation platform이 함께 발전해야 한다고 정리한다. “Foundation”이라는 이름은 범용성을 보장하는 결과가 아니라 넓은 data와 adaptation을 요구하는 목표다. Broad generalization을 주장하려면 성공 영상만이 아니라 정량적이고 재현 가능한 평가 근거가 필요하다.

## 마지막 핵심 정리

- Robot learning은 action이 다음 data를 만드는 closed-loop 학습이다.
- RL은 reward에서 행동을 발견하지만 exploration, delayed credit, physical data cost가 크다.
- Model-based planning은 dynamics로 미래를 예측하고 매 step 재계획한다.
- Imitation은 expert data를 활용하지만 learner가 만든 state에서 distribution shift가 생긴다.
- Diffusion policy는 multimodal demonstration의 여러 유효한 action mode를 생성 분포로 표현한다.
- RT-1에서 RT-2·RT-X·OpenVLA로 이어지는 VLA 흐름은 image와 instruction을 다양한 embodiment의 action으로 연결하려 한다.
- Foundation robotics의 핵심 제한은 모델 크기보다 **다양하고 신뢰할 수 있는 interaction data**다.

## Study Guide

하나의 manipulation task를 골라 state, observation, action, reward를 직접 정의한다. 같은 task를 RL, model-based planning, behavior cloning으로 풀 때 필요한 data와 실패 방식을 비교하고, foundation policy가 재사용할 부분과 embodiment-specific 부분을 나눈다.

## 복습 질문

<details><summary>1. Robot learning에서 data가 i.i.d.가 아닌 이유는?</summary>

답변: 현재 policy의 action이 다음 state와 앞으로 관측할 data distribution을 바꾸기 때문이다. Policy가 달라지면 수집되는 학습 data도 달라진다.
</details>

<details><summary>2. Model-predictive control이 첫 action만 실행하는 이유는?</summary>

답변: Learned dynamics는 완벽하지 않고 실제 환경도 변한다. 새 observation을 받은 뒤 다시 계획하면 누적 model error를 줄일 수 있다.
</details>

<details><summary>3. Behavior cloning의 작은 오류가 커지는 이유는?</summary>

답변: 한 번 expert trajectory에서 벗어나면 training에 거의 없던 state를 만나고, 그곳의 잘못된 action이 더 큰 distribution shift를 만들기 때문이다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=XSfmOH_xVSU){:target="_blank" rel="noopener"}
