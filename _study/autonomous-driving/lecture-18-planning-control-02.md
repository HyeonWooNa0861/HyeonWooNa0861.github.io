---
layout: default
date: 2026-11-18 00:00:05 +0900
last_modified_at: 2026-11-23 16:50:00 +0900
title: "Lecture 18: Planning and Control II"
course: "Autonomous Driving"
topic: "End-to-End, Open-Loop, and Closed-Loop Learning"
order: 18
major_topic: "Autonomous Systems"
keywords:
  - "End-to-End Driving"
  - "Behavior Cloning"
  - "Open-Loop Learning"
  - "Closed-Loop Learning"
  - "Distribution Shift"
  - "Reinforcement Learning"
  - "Actor-Critic"
---

# Lecture 18: Planning and Control II

Source PDF: [lecture-18-planning-control-02.pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf" | relative_url }})

모듈형 자율주행은 perception, prediction, planning, control을 각각 설계한다. 이 구조는 중간 결과를 검사하기 쉽지만, 각 단계의 작은 오류와 지연이 다음 단계로 전달된다. **End-to-end driving은 sensor 입력에서 actuator command까지를 하나의 학습 문제로 연결한다.** 이 강의는 같은 목표를 open-loop behavior cloning과 closed-loop reinforcement learning으로 학습할 때 무엇이 달라지는지 설명한다.

> **핵심:** Open-loop는 전문가가 기록한 상태와 행동을 모방한다. 학습은 쉽지만 모델이 만든 실수 상태를 데이터에서 보지 못할 수 있다. Closed-loop는 모델의 행동이 다음 상태와 보상으로 돌아오는 상호작용을 학습한다. Train–inference 차이는 줄일 수 있지만, 실제 도로에서 안전하게 시행착오를 수집하기 어렵다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–12 | Modular and end-to-end pipelines | 모듈별 목표를 잘 풀어도 전체 주행이 실패할 수 있는 이유는 무엇인가? |
| 13–23 | Open-loop learning | 전문가 행동 모방은 어떻게 학습하며 distribution shift는 왜 생기는가? |
| 24–33 | Closed-loop learning | 환경 피드백과 reward로 정책을 어떻게 개선하는가? |
| 34–37 | Comparison and summary | 두 학습 방식의 장단점과 적용 조건은 무엇인가? |

페이지는 PDF의 1-based 쪽수다. 수치 예제와 수식은 슬라이드 개념을 검산하기 위한 보충 설명이다.

## 1. Modular pipeline이 남기는 문제

<figure class="study-source-figure" id="adc-18-p07">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p07-modular-pipeline.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p07-modular-pipeline.jpg" | relative_url }}" alt="Maps와 sensors에서 perception, prediction, planning, control을 차례로 거쳐 steering gas brake를 출력하는 강의 7쪽 modular pipeline" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=7" | relative_url }}">lecture PDF, p. 7</a>.</figcaption>
</figure>

7쪽 위 그림은 `Maps/Sensors`, `Perception`, `Prediction`, `Planning`, `Control`의 순차 구조다. 아래 그림은 planning 안에서도 route, behavior, motion을 나눈다. 각 모듈은 자체 목표를 가진다.

- Object detection: AP
- Tracking: MOTA
- Prediction: ADE, FDE
- Planning and control: 충돌, 경로 이탈, 승차감, 진행률 같은 주행 결과

8쪽의 문제의식은 **중간 지표의 개선이 최종 주행 목적을 자동으로 보장하지 않는다**는 점이다. AP가 높아도 planning에 중요한 먼 보행자를 놓치면 위험할 수 있다. 평균 FDE가 낮아도 드물지만 위험한 회전 가능성을 제거하면 planning이 잘못된 결정을 할 수 있다.

### Error propagation, latency, uncertainty

9–11쪽은 모듈형 구조의 세 병목을 정리한다.

1. **Error propagation:** 앞 단계의 오류가 뒤 단계 입력 자체를 바꾼다.
2. **Latency:** 모듈별 계산과 데이터 전달 시간이 누적된다.
3. **Uncertainty propagation:** 객체 위치나 미래 예측의 불확실성을 다음 단계가 같은 의미로 사용하기 어렵다.

예를 들어 perception이 보행자 위치를 실제보다 0.5 m 오른쪽으로 추정하고 prediction이 그 위치에서 미래 경로를 계산하면, planning은 이미 이동된 분포를 입력으로 받는다. 각 단계가 독립적인 point estimate만 넘기면 “0.5 m가 얼마나 불확실한가”도 사라질 수 있다.

## 2. End-to-end pipeline: 입력과 최종 행동을 직접 연결한다

<figure class="study-source-figure" id="adc-18-p12">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p12-end-to-end-pipeline.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p12-end-to-end-pipeline.jpg" | relative_url }}" alt="Maps와 sensors 입력을 neural network가 직접 받아 steering gas brake actuator command를 출력하는 강의 12쪽 end-to-end pipeline" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=12" | relative_url }}">lecture PDF, p. 12</a>.</figcaption>
</figure>

End-to-end는 sensor 정보에서 actuator command까지 직접 함수를 학습한다.

$$
\mathbf{u}_t=\pi_\theta(\mathbf{o}_t)
$$

$$\mathbf{o}_t$$는 camera image와 차량 상태 같은 observation, $$\mathbf{u}_t$$는 steering·acceleration·brake 같은 action이다. 모듈 경계를 없애면 최종 행동 loss가 network 전체를 조정할 수 있다. 그러나 중간 표현이 명시되지 않으므로 왜 특정 steering을 선택했는지 분석하기는 더 어렵다.

End-to-end가 반드시 “지도도 없고 중간 feature도 없는 하나의 CNN”을 뜻하지는 않는다. 학습 가능한 전체 경로가 최종 driving objective에 연결된다는 뜻에 가깝다. Auxiliary task, map feature, safety layer를 함께 쓰는 hybrid 설계도 가능하다.

## 3. Open-loop learning: 전문가 행동을 모방한다

<figure class="study-source-figure" id="adc-18-p16">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p16-behavior-cloning.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p16-behavior-cloning.jpg" | relative_url }}" alt="전문가 주행 데이터의 observation으로 model prediction을 만들고 expert action과 차이를 계산하는 강의 16쪽 behavior cloning" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>.</figcaption>
</figure>

Open-loop behavior cloning은 세 단계로 이해할 수 있다.

1. 전문가가 주행하며 observation과 action 쌍을 기록한다.
2. 모델이 같은 observation에서 action을 예측한다.
3. 예측과 전문가 action의 차이를 줄이도록 supervised learning을 수행한다.

“Open-loop”라는 말은 학습 중 모델의 출력이 다음 학습 observation을 만들지 않는다는 뜻이다. 모델이 steering을 틀려도 기록된 다음 frame은 전문가가 실제로 운전한 frame이다.

### NVIDIA end-to-end steering 사례

17–22쪽은 NVIDIA의 [End to End Learning for Self-Driving Cars](https://arxiv.org/abs/1604.07316){: target="_blank" rel="noopener"}를 사례로 든다. 논문의 문제의식은 lane marking, road edge, steering rule을 각각 사람이 설계하지 않고, front camera image에서 steering command를 직접 학습할 수 있는지 확인하는 것이었다.

- **Input:** 세 camera가 기록한 road image와 recorded steering wheel angle
- **Training:** 좌·우 camera image를 사용해 차선 중심에서 벗어난 상황을 보강하고, frame별 steering MSE를 최소화
- **Inference:** center camera image에서 steering command를 계산
- **Scope:** 이 강의가 다루는 모델은 steering을 학습하며, throttle과 brake를 학습 목표에 포함하지 않는다.

<figure class="study-source-figure" id="adc-18-p20">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p20-training-pipeline.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p20-training-pipeline.jpg" | relative_url }}" alt="Left center right camera image에 shift와 rotation을 적용하고 CNN steering 출력과 recorded angle 차이를 역전파하는 강의 20쪽 NVIDIA training pipeline" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=20" | relative_url }}">lecture PDF, p. 20</a>.</figcaption>
</figure>

왼쪽·오른쪽 camera는 단순히 시야를 넓히는 입력이 아니다. 차량이 중심에서 벗어났을 때 어느 방향으로 복구해야 하는지에 해당하는 shifted view를 만든다. 그림의 `Adjust for shift and rotation`은 image 위치 변화에 맞춰 원하는 steering label도 조정해야 함을 뜻한다.

### Steering MSE 수치 예제

전문가 steering이 $$[0.10,-0.05,0.20]$$ rad이고 예측이 $$[0.08,0.00,0.17]$$ rad라고 하자.

$$
\mathrm{MSE}=\frac{(0.08-0.10)^2+(0+0.05)^2+(0.17-0.20)^2}{3}
=0.00127\ \mathrm{rad^2}
$$

이 loss는 각 frame의 steering 차이를 줄인다. 그러나 0.00127이라는 작은 offline loss만으로 closed-loop에서 차선을 유지한다고 보장할 수는 없다. 작은 오차가 차량 위치를 바꾸면 다음 입력 image도 달라지기 때문이다.

<details markdown="block">
<summary markdown="span">Derivation: Steering MSE and its gradient</summary>

Batch 크기를 $$N$$, 전문가 steering을 $$y_i$$, 모델 출력을 $$\hat y_i$$라고 하면

$$
L(\theta)=\frac{1}{N}\sum_{i=1}^{N}(\hat y_i-y_i)^2,
\qquad \hat y_i=\pi_\theta(o_i)
$$

이다. 출력에 대한 gradient는

$$
\frac{\partial L}{\partial \hat y_i}
=\frac{2}{N}(\hat y_i-y_i)
$$

다. 예측이 전문가보다 오른쪽으로 크면 양의 gradient가 생기고, gradient descent는 출력을 줄이는 방향으로 parameter를 조정한다. 이 유도는 frame별 imitation error를 줄이는 과정이다. 시간에 따라 누적되는 차량 위치 오차는 loss에 직접 들어 있지 않다.

</details>

## 4. Distribution shift: 한 번의 오차가 다음 입력을 바꾼다

<figure class="study-source-figure" id="adc-18-p23">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p23-distribution-shift.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p23-distribution-shift.jpg" | relative_url }}" alt="전문가 데이터로 direct supervision을 받지만 training과 inference 사이 distribution shift가 발생함을 정리한 강의 23쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=23" | relative_url }}">lecture PDF, p. 23</a>.</figcaption>
</figure>

전문가 dataset에는 차선 중심을 안정적으로 달리는 상태가 많다. 모델이 작은 steering 오차로 차선 오른쪽에 가까워지면, 그 상태의 image는 전문가 분포에서 드물 수 있다. 낯선 입력에서 다시 오차가 커지고 차량은 더 멀리 벗어난다. 이것이 **distribution shift와 compounding error**다.

비유하면 정답 동작만 보고 걷는 법을 배운 사람이 한 번 비틀거린 뒤의 복구 동작을 배우지 못한 상태와 비슷하다. 핵심은 모델이 “평소 운전”을 전혀 배우지 못했다는 것이 아니라, **자신의 실수로 도달하는 상태와 복구 행동이 학습 데이터에 부족하다**는 점이다.

슬라이드의 “sample efficiency가 높다”는 표현은 이 강의가 비교하는 **online closed-loop 시행착오**에 비해, 기록된 전문가 label로 직접 supervised update를 많이 할 수 있다는 뜻이다. 같은 데이터 수·비용·환경을 엄밀히 고정한 모든 학습 방식보다 항상 우수하다는 보편 명제가 아니다.

## 5. Closed-loop learning: 행동 결과를 다시 학습 입력으로 받는다

<figure class="study-source-figure" id="adc-18-p28">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p28-closed-loop-rl.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p28-closed-loop-rl.jpg" | relative_url }}" alt="모델 action이 environment에 들어가고 다음 observation과 reward가 다시 모델로 돌아오는 강의 28쪽 reinforcement learning loop" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=28" | relative_url }}">lecture PDF, p. 28</a>.</figcaption>
</figure>

Closed-loop에서는 모델이 낸 action이 환경 상태를 바꾸고, 다음 observation과 reward가 다시 모델에 돌아온다.

$$
s_t\xrightarrow{a_t\sim\pi_\theta(\cdot\mid s_t)}
(r_t,s_{t+1})
$$

정책 $$\pi_\theta$$는 누적 reward를 크게 만드는 action을 학습한다.

$$
J(\theta)=\mathbb E_{\pi_\theta}
\left[\sum_{t=0}^{T}\gamma^t r_t\right]
$$

28쪽은 reward 예로 주행 거리를 든다. 실제 reward는 충돌, 차선 이탈, 조향 변화, 진행률 등을 함께 반영할 수 있다. 무엇을 reward로 두는지가 곧 문제 정의다. 잘못 설계하면 모델이 숫자만 높이고 원하는 운전을 하지 않는 reward hacking이 생길 수 있다.

**수치 예제:** discount factor $$\gamma=0.9$$이고 세 step reward가 $$[1,1,-5]$$라면 return은

$$
G_0=1+0.9(1)+0.9^2(-5)=-2.15
$$

이다. 첫 두 step에서 전진했어도 세 번째 충돌 penalty가 크므로 전체 행동열의 평가는 음수가 된다. Reward는 한 frame의 steering 정답 대신 **행동이 만든 장기 결과**를 평가한다.

26쪽의 “offline 학습 데이터 사용 X”는 슬라이드가 소개하는 **환경과 직접 상호작용하는 online RL 설정**의 설명이다. Closed-loop learning 전체의 불변 정의는 아니다. Offline RL이나 recorded log를 사용한 policy learning도 존재하며, closed-loop simulator 평가와 offline training도 함께 사용할 수 있다.

### Learning to Drive in a Day

30–32쪽은 [Learning to Drive in a Day](https://arxiv.org/abs/1807.00412){: target="_blank" rel="noopener"}를 소개한다. 이 연구는 monocular image를 입력으로 받고, 사람이 steering label을 계속 제공하는 대신 **안전 운전자가 개입하지 않고 이동한 거리**를 reward로 사용해 policy를 개선했다. 문제의식은 실제 차량에서 연속 제어 policy를 짧은 상호작용으로 배울 수 있는지 확인하는 것이었다.

연구의 novelty는 camera 기반 실제 차량 제어를 model-free deep RL로 online 학습한 점에 있다. 그러나 “하루”라는 이름을 모든 도로·날씨·차종에서 일반 운전을 완성했다는 뜻으로 읽으면 안 된다. 논문이 검증한 환경과 task 범위 안에서 해석해야 한다.

## 6. Actor–critic: 행동하는 모델과 평가하는 모델을 나눈다

<figure class="study-source-figure" id="adc-18-p32">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p32-actor-critic.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p32-actor-critic.jpg" | relative_url }}" alt="Camera와 speed measurement를 state vector로 만들고 actor가 steering speed command를, critic이 state action Q value를 계산하는 강의 32쪽 actor critic network" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=32" | relative_url }}">lecture PDF, p. 32</a>.</figcaption>
</figure>

그림에서 convolution layer는 camera image를 state feature로 바꾼다. Speed와 steering measurement도 state에 들어간다.

- **Actor:** 현재 state에서 steering과 speed command를 만든다.
- **Critic:** state와 action을 함께 보고 앞으로 받을 return을 $$Q(s,a)$$로 평가한다.

비유하면 actor는 운전대를 잡는 운전자, critic은 현재 조작이 장기적으로 좋은지 점수를 주는 코치다. 코치가 직접 운전하지는 않지만, 어떤 action을 더 자주 선택할지 학습 신호를 준다.

<details markdown="block">
<summary markdown="span">Derivation: Bellman target and actor update</summary>

Critic은 한 step 뒤의 평가를 이용해 target을 만든다.

종료 여부를 $$d_t\in\{0,1\}$$로 두면 Bellman target은

$$
y_t=r_t+\gamma(1-d_t)Q_{\bar\phi}
\left(s_{t+1},\pi_{\bar\theta}(s_{t+1})\right)
$$

이다. 계속 상태에서는 $$d_t=0$$이므로 다음 상태의 평가를 더한다. Episode가 끝나는 terminal transition에서는 $$d_t=1$$이므로 $$y_t=r_t$$다.

Critic parameter $$\phi$$는

$$
L_Q(\phi)=
\left(Q_\phi(s_t,a_t)-y_t\right)^2
$$

를 줄이도록 학습한다. Deterministic actor의 직관적인 update는 critic이 높은 값을 주는 action 방향으로 출력을 움직이는 것이다.

$$
\nabla_\theta J
\approx
\mathbb E\left[
\nabla_a Q_\phi(s,a)\vert_{a=\pi_\theta(s)}
\nabla_\theta\pi_\theta(s)
\right]
$$

Critic이 부정확하면 actor도 잘못된 방향으로 학습할 수 있다. Replay buffer, target network, exploration noise 같은 안정화 장치가 사용되는 이유다. 슬라이드는 actor–critic 구조를 강조하며, 특정 algorithm의 모든 구현 세부를 고정하지 않는다.

</details>

## 7. Open-loop와 closed-loop의 trade-off

<figure class="study-source-figure" id="adc-18-p33">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-18/p33-closed-loop-tradeoff.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-18/p33-closed-loop-tradeoff.jpg" | relative_url }}" alt="Closed-loop learning은 training과 inference distribution gap이 작지만 실제 도로 시행착오가 어렵다고 정리한 강의 33쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf#page=33" | relative_url }}">lecture PDF, p. 33</a>.</figcaption>
</figure>

| 기준 | Open-loop behavior cloning | Closed-loop RL |
|---|---|---|
| Supervision | 전문가 action | 환경 reward와 다음 state |
| 데이터 생성 | 전문가가 기록한 고정 dataset | 현재 policy가 환경과 상호작용 |
| 강점 | 직접 label로 안정적인 supervised update, dataset 재사용 | 모델이 실제로 방문하는 state와 장기 결과를 학습 |
| 주요 병목 | Distribution shift, 복구 상태 부족 | 안전한 exploration, reward 설계, 많은 interaction |
| 평가 주의 | 낮은 offline error가 안전 주행을 보장하지 않음 | 높은 simulator reward가 실제 도로 성능을 보장하지 않음 |

33쪽의 “training과 inference 사이 distribution gap이 작다”는 같은 환경에서 현재 policy가 만든 상태를 학습한다는 직관이다. **Sim-to-real gap, 날씨 변화, sensor 차이, 새로운 도로까지 자동으로 해결한다는 뜻은 아니다.** 실제 도로에서 시행착오가 위험하므로 simulator, safety driver, constrained policy, offline pretraining 같은 보호 장치가 필요하다.

두 방식은 반드시 하나만 선택하는 경쟁 관계가 아니다. 전문가 데이터로 behavior cloning을 먼저 수행하고, simulator의 closed loop에서 복구 행동을 강화한 뒤, safety layer를 둔 제한적 real-world fine-tuning을 할 수 있다. 중요한 것은 각 단계가 줄이는 gap과 새로 만드는 위험을 구분하는 일이다.

## 마지막 핵심 정리

- **Modular pipeline은 해석하기 쉽지만 error, latency, uncertainty 전달을 관리해야 한다.**
- End-to-end는 observation에서 actuator command까지 최종 driving objective로 연결한다.
- Open-loop behavior cloning은 전문가 action을 직접 학습하지만, 모델이 만든 복구 상태가 dataset에 부족할 수 있다.
- NVIDIA 사례는 camera image에서 **steering**을 학습한다. Throttle과 brake는 해당 학습 목표에 포함되지 않는다.
- Closed-loop RL은 action이 만든 다음 state와 reward를 학습한다. Reward 설계와 안전한 exploration이 핵심 병목이다.
- Actor는 action을 만들고 critic은 state–action의 장기 return을 평가한다.
- Closed-loop가 distribution gap을 줄인다는 설명은 같은 상호작용 환경의 직관이다. Sim-to-real과 환경 변화를 자동으로 없애지는 않는다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

| 다시 볼 부분 | 확인할 내용 |
|---|---|
| pp. 7–12 | Modular pipeline의 중간 목표와 end-to-end 입출력 |
| pp. 16–23 | Behavior cloning, steering MSE, shifted camera, distribution shift |
| pp. 26–28 | Online closed-loop interaction, policy, reward, return |
| pp. 30–33 | Learning to Drive in a Day, actor–critic, 실제 도로 exploration trade-off |

복습할 때는 같은 camera frame이 open-loop와 closed-loop에서 어떻게 다르게 사용되는지 먼저 설명한다. 이어서 MSE는 **전문가 action과 한 frame의 차이**, return은 **action 이후 장기 결과**를 평가한다는 차이를 수치 예제로 확인한다.

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">1. 모듈별 metric이 좋아도 최종 주행이 실패할 수 있는 이유는 무엇인가?</summary>

답변: 각 metric은 해당 모듈의 평균 목표를 측정하지만, planning에 중요한 희귀 객체나 위험한 미래를 놓치는 비용을 그대로 나타내지 않을 수 있다. 앞 단계의 작은 오류가 다음 단계 입력을 바꾸고 지연과 불확실성도 누적된다.

</details>

<details markdown="block">
<summary markdown="span">2. Open-loop에서 model action이 다음 학습 observation을 만들지 않는다는 말은 무엇인가?</summary>

답변: Dataset의 다음 frame은 전문가가 실제로 운전해 기록한 frame이다. 모델이 현재 frame에서 잘못 조향해도 그 결과 상태가 학습 sequence에 나타나지 않으므로, 모델 자신의 실수 상태와 복구 행동이 부족할 수 있다.

</details>

<details markdown="block">
<summary markdown="span">3. Camera shift augmentation에서 image와 steering label을 함께 바꾸는 이유는 무엇인가?</summary>

답변: 옆 camera나 이동된 image는 차량이 차선 중심에서 벗어난 관측을 나타낸다. 이 상태에서 원래 steering label을 그대로 쓰면 복구 방향과 맞지 않을 수 있으므로, 위치 변화에 대응하는 desired steering으로 label도 보정해야 한다.

</details>

<details markdown="block">
<summary markdown="span">4. Steering MSE가 낮아도 closed-loop 주행을 보장하지 않는 이유는 무엇인가?</summary>

답변: MSE는 기록된 frame에서 전문가 steering과의 차이를 측정한다. 작은 steering 오차가 차량 위치와 다음 image를 바꾸면 학습 분포 밖으로 이동할 수 있으며, 이후 오차가 누적될 수 있다.

</details>

<details markdown="block">
<summary markdown="span">5. Actor와 critic은 무엇을 각각 계산하는가?</summary>

답변: Actor는 state에서 steering·speed 같은 action을 만든다. Critic은 state와 action을 받아 앞으로의 discounted return을 $$Q(s,a)$$로 평가한다. Actor는 critic이 더 높은 값을 주는 action 방향으로 개선된다.

</details>

<details markdown="block">
<summary markdown="span">6. Closed-loop 학습이 모든 distribution gap을 제거하는가?</summary>

답변: 아니다. 현재 policy가 같은 환경에서 방문하는 상태를 학습하므로 train–inference 차이를 줄일 수 있다. 그러나 simulator와 실제 차량의 차이, 새로운 날씨·도로·sensor의 변화는 별도 gap이며 안전한 검증이 필요하다.

</details>

## References

- Bojarski et al., [End to End Learning for Self-Driving Cars](https://arxiv.org/abs/1604.07316){: target="_blank" rel="noopener"}
- Kendall et al., [Learning to Drive in a Day](https://arxiv.org/abs/1807.00412){: target="_blank" rel="noopener"}

## PDF

[Open the original lecture PDF]({{ "/assets/pdfs/study/autonomous-driving/lecture-18-planning-control-02.pdf" | relative_url }})
