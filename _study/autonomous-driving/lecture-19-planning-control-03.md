---
layout: default
date: 2026-11-25 00:00:07 +0900
last_modified_at: 2026-11-25 02:29:00 +0900
title: "Lecture 19: Planning and Control III"
course: "Autonomous Driving"
topic: "End-to-End Interpretable Neural Motion Planning"
order: 19
major_topic: "Autonomous Systems"
keywords:
  - "Interpretable Planning"
  - "Neural Motion Planner"
  - "Cost Volume"
  - "Trajectory Sampling"
  - "Max-Margin Loss"
  - "Multi-Task Learning"
  - "LiDAR"
  - "HD Map"
---

# Lecture 19: Planning and Control III

Source Materials: [Planning & Control III lecture material](https://ecampus.kookmin.ac.kr/mod/ubfile/view.php?id=2007540){: target="_blank" rel="noopener"}

Lecture 18에서 다룬 end-to-end model은 sensor 입력을 steering이나 acceleration 같은 actuator command로 바로 바꿉니다. 구조는 간단하지만 사고가 났을 때 “무엇을 보고 이 명령을 냈는가”를 확인하기 어렵습니다. 이번 강의는 이 black-box 문제를 줄이기 위해 **학습 가능한 model 안에 사람이 읽을 수 있는 중간 결과를 남기는 방법**을 설명합니다.

> **핵심:** Neural Motion Planner는 LiDAR와 HD map을 받아 주변 actor의 미래 위치와 ego vehicle의 space-time cost volume을 함께 예측합니다. 그다음 물리적으로 실행 가능한 trajectory 후보만 평가하고, 누적 cost가 가장 낮은 후보를 선택합니다. 따라서 최종 경로뿐 아니라 주변 객체 예측과 위치별 선호도를 함께 살펴볼 수 있습니다.

## 1. 왜 actuator command만으로는 부족합니까?

Actuator command는 “지금 어떻게 움직일 것인가”를 알려 주지만, 판단 근거를 보여 주지는 않습니다. 같은 steering command도 여러 이유로 나올 수 있습니다.

- 앞 차량을 피하려고 왼쪽으로 움직일 수 있습니다.
- 차선 중심으로 복귀하려고 왼쪽으로 움직일 수 있습니다.
- 잘못된 객체 인식 때문에 왼쪽으로 움직였을 수도 있습니다.

실제 도로에서는 결과만 맞는 것보다 **왜 그 결과가 나왔는지 조사할 수 있는 구조**가 중요합니다. 신뢰성 검토, 사고 원인 분석, 규제 대응에는 model이 본 주변 actor와 후보 위치의 위험도를 확인할 수 있어야 합니다.

End-to-End Interpretable Neural Motion Planner는 이 문제를 multi-task learning으로 다룹니다. 하나의 backbone이 입력을 처리한 뒤 두 종류의 중간 결과를 만듭니다.

1. **Perception output:** 주변 actor의 현재·미래 bounding box
2. **Planning output:** 미래 시각별 위치의 선호도를 나타내는 cost volume

최종 trajectory는 이 결과를 후처리하여 구합니다. 즉, neural network가 actuator command를 바로 내는 대신 **검사 가능한 판단 재료**를 먼저 냅니다.

## 2. 입력은 왜 LiDAR 10개 sweep과 HD map입니까?

### LiDAR history: 한 장면이 아니라 움직임을 읽는다

현재 LiDAR 한 frame만 보면 객체가 어디에 있는지는 알 수 있지만, 어느 방향으로 움직이는지는 모호합니다. Model은 연속된 10개 sweep을 현재 ego coordinate에 맞춘 뒤 voxel로 변환합니다. 과거 sweep을 현재 좌표계에 맞추는 이유는 ego vehicle의 이동과 주변 actor의 이동을 구분하기 위해서입니다.

각 sweep의 voxel 높이 축 크기를 $$Z$$, BEV의 세로·가로를 $$H,W$$라고 하면 LiDAR 입력은 다음과 같이 표현할 수 있습니다.

$$
\mathbf X_{\mathrm{LiDAR}}\in\mathbb R^{H\times W\times 10Z}
$$

여기서 `10Z`는 10개 sweep의 높이 정보를 channel 방향으로 이어 붙였다는 뜻입니다. 시간 정보가 사라진 것이 아니라, 각 시간의 voxel이 서로 다른 channel에 놓입니다.

### HD map: 교통 규칙을 공간 정보로 넣는다

LiDAR만으로는 차선 경계가 실선인지, 교차로인지, 신호등과 정지선이 어디인지 완전히 알기 어렵습니다. HD map을 road, lane, boundary, intersection 같은 $$M$$개 raster channel로 바꾸고 LiDAR feature와 결합합니다.

$$
\mathbf X
=\operatorname{concat}(\mathbf X_{\mathrm{LiDAR}},\mathbf X_{\mathrm{map}})
\in\mathbb R^{H\times W\times(10Z+M)}
$$

쉽게 말하면 LiDAR는 **지금 주변에 무엇이 있는지**, HD map은 **그 공간에서 어떤 이동이 허용되는지** 알려 줍니다. 두 입력을 같은 BEV grid에 정렬하므로 convolution이 같은 위치의 sensor 정보와 map 정보를 함께 읽을 수 있습니다.

## 3. Backbone과 두 head는 무엇을 계산합니까?

Backbone은 PIXOR 계열의 2D convolution과 feature pyramid 구조를 사용합니다. BEV에서 넓은 도로 맥락과 작은 actor를 함께 보려면 여러 해상도의 feature가 필요하기 때문입니다.

### Perception head

BEV의 각 anchor는 “이 위치와 방향에 차량이 있을 수 있다”는 미리 정한 후보 box입니다. Perception head는 anchor마다 다음 값을 예측합니다.

- 차량이 존재할 classification score
- 위치·크기·heading의 regression offset
- 미래 timestep별 box 변화

따라서 현재 detection뿐 아니라 주변 actor의 motion forecast도 얻습니다. `Anchor` 자체는 정답이나 prediction이 아닙니다. **Prediction을 시작할 기준 후보**이며, classification과 regression을 거쳐 실제 box prediction으로 바뀝니다.

### Cost volume head

Cost volume은 다음 shape을 가집니다.

$$
\mathbf C\in\mathbb R^{H\times W\times T}
$$

$$C_t(x,y)$$는 미래 시각 $$t$$에 ego vehicle이 위치 $$(x,y)$$를 지날 때의 학습된 cost입니다. Cost가 낮을수록 model이 더 좋은 위치로 평가한다는 뜻입니다. 각 channel은 서로 다른 미래 시각을 담당하므로, 같은 위치도 “1초 뒤에는 괜찮지만 3초 뒤에는 위험한 곳”으로 표현할 수 있습니다.

Cost volume은 하나의 정답 경로만 출력하지 않습니다. 여러 위치의 상대적 선호도를 남기므로 직진과 차선 변경처럼 가능한 선택이 여러 개인 상황도 표현할 수 있습니다.

## 4. Cost volume에서 trajectory를 어떻게 고릅니까?

각 시각의 비용 지도에서 가장 낮은 칸(argmin)을 하나씩 고르면 어떻게 될까요? 강의에서는 1초 뒤의 최저점이 차량 앞에 있는데 2초 뒤의 최저점은 오히려 뒤에 있는 경우를 듭니다. **두 칸 모두 그 시각의 최저점이지만, 그 사이를 1초 만에 주행할 수 있다는 뜻은 아닙니다.** 두 번째 칸을 고를 때 첫 번째 칸에서의 속도와 진행 방향을 고려하지 않았기 때문입니다.

차량에는 steering angle, 속도, 가속도, 회전 반경 같은 물리적 제한이 있습니다. 따라서 이 model은 순서를 바꿉니다.

1. Steering과 acceleration 조건으로 **실행 가능한 trajectory 후보**를 먼저 만듭니다.
2. 같은 후보를 따라가며 1초 뒤 위치의 비용은 1초 지도에서, 2초 뒤 위치의 비용은 2초 지도에서 읽습니다. 매번 가장 싼 칸을 다시 고르지 않습니다.
3. 모든 timestep의 cost를 더합니다.
4. 누적 cost가 가장 낮은 후보를 선택합니다.

후보 trajectory $$s=(s_1,\ldots,s_T)$$의 점수는 다음과 같습니다.

$$
J(s)=\sum_{t=1}^{T} C_t(s_t),
\qquad
s^*=\arg\min_{s\in\mathcal S_{\mathrm{feasible}}}J(s)
$$

$$\mathcal S_{\mathrm{feasible}}$$는 차량이 실제로 실행할 수 있도록 sampling한 후보 집합입니다. 이 제약이 있으므로 선택된 점들의 연결은 처음부터 차량 운동 범위 안에 있습니다.

### 누적 cost 수치 예제

계산을 위한 보충 예제로, 세 시각에서 두 후보가 받는 비용을 비교해 보겠습니다.

| Candidate | $$t=1$$ | $$t=2$$ | $$t=3$$ | Total |
|---|---:|---:|---:|---:|
| A: straight | 0.2 | 0.4 | 1.8 | 2.4 |
| B: gentle left | 0.4 | 0.5 | 0.6 | 1.5 |

Candidate A는 처음 두 시각에는 더 좋아 보이지만, 마지막 위치의 cost가 큽니다. 전체 planning horizon을 합치면 B의 cost가 더 낮으므로 B를 선택합니다. 이 예제는 planner가 현재 위치의 최솟값만 보는 것이 아니라 **경로 전체의 미래 결과를 비교한다**는 뜻입니다.

<details markdown="block">
<summary markdown="span">Supplement: 논문에서 feasible trajectory를 만드는 방법</summary>

강의자료는 steering angle과 등가속도 조건으로 trajectory가 결정된다고 설명합니다. 원 논문은 여기에 straight line, circle, clothoid curve를 사용합니다. Clothoid는 이동 거리와 함께 curvature가 선형으로 변하므로 steering을 갑자기 꺾지 않는 경로를 표현하기 좋습니다. Path와 longitudinal velocity profile을 결합하면 각 timestep의 2D 위치를 얻습니다.

이 보충은 후보를 만드는 한 구현을 설명합니다. Cost volume에서 후보를 평가하는 핵심 원리는 특정 curve 종류에만 묶이지 않습니다.

</details>

## 5. 정답 cost volume 없이 어떻게 학습합니까?

Training data에는 사람이 실제로 운전한 ground-truth trajectory가 있지만, 모든 grid 위치의 정답 cost는 없습니다. “이 pixel의 cost는 0.7이어야 한다”는 label을 직접 만들기 어렵기 때문입니다.

강의에서는 운전자가 직진한 장면에 좌회전 후보도 생성된 경우를 예로 듭니다. 여기서 좌회전은 **차량이 할 수 없는 동작**이 아니라 **그 장면에서 운전자가 선택하지 않은 비교 경로**입니다. 이런 후보를 *sampled negative*라고 합니다. 추론할 때 가장 싼 경로를 고르므로, 학습할 때는 사람이 실제로 주행한 경로의 비용이 비교 경로보다 일정한 차이만큼 낮아지도록 합니다.

$$
J(s_{\mathrm{human}})+m_i
\le J(s_{\mathrm{negative},i})
$$

$$m_i$$는 두 경로의 거리나 교통 규칙 위반 정도에 따라 커지는 margin입니다. 위험하거나 사람의 경로에서 멀리 떨어진 negative trajectory에는 더 큰 차이를 요구합니다.

직관적인 hinge loss는 다음과 같이 쓸 수 있습니다.

$$
L_i=
\left[
J(s_{\mathrm{human}})-J(s_{\mathrm{negative},i})+m_i
\right]_+
$$

여기서 $$[z]_+=\max(0,z)$$입니다. Negative trajectory가 이미 충분히 높은 cost를 받으면 loss는 0입니다. 두 cost가 너무 비슷하거나 negative가 오히려 더 낮으면 loss가 생깁니다.

### Max-margin 수치 예제

Human trajectory cost가 $$0.6$$, negative trajectory cost가 $$1.1$$, 필요한 margin이 $$0.8$$이라고 하겠습니다.

$$
L=[0.6-1.1+0.8]_+=0.3
$$

현재 cost 차이는 $$0.5$$이므로 요구한 $$0.8$$보다 작습니다. Model은 human cost를 낮추거나 negative cost를 높이는 방향으로 학습합니다. Negative cost가 $$1.6$$이면

$$
L=[0.6-1.6+0.8]_+=0
$$

이므로 이미 margin을 만족합니다.

<details markdown="block">
<summary markdown="span">Derivation: timestep별 max-margin loss가 필요한 이유</summary>

Human trajectory의 timestep별 위치를 $$\hat s_t$$, negative trajectory $$i$$의 위치를 $$s_{i,t}$$라고 하겠습니다. Cost volume에서 읽은 값은 각각 $$\hat c_t=C_t(\hat s_t)$$와 $$c_{i,t}=C_t(s_{i,t})$$입니다.

원 논문의 planning loss는 다음 관계를 timestep별로 검사합니다.

$$
L_{\mathrm{planning}}
=\max_i\sum_{t=1}^{T}
\left[
\hat c_t-c_{i,t}+d_{i,t}+\gamma_{i,t}
\right]_+
$$

- $$d_{i,t}$$: negative 위치와 human 위치 사이의 거리
- $$\gamma_{i,t}$$: 충돌·신호 위반 같은 rule violation penalty
- $$\max_i$$: 현재 후보 중 가장 구분하기 어려운 hard negative에 집중

Hinge를 합계 바깥이 아니라 timestep마다 적용하면 특정 시각의 큰 차이가 다른 시각의 잘못된 순위를 가려 버리는 일을 줄일 수 있습니다. 각 시각에서 human 위치가 적절히 낮은 cost를 받도록 요구하는 구조입니다.

</details>

## 6. Perception loss와 planning loss를 함께 쓰는 이유

전체 objective는 다음처럼 정리할 수 있습니다.

$$
L=L_{\mathrm{perception}}+\beta L_{\mathrm{planning}}
$$

Perception loss는 주변 actor의 classification과 localization·future motion을 학습합니다. Planning loss는 human trajectory와 negative trajectory의 cost 순위를 학습합니다. 두 loss가 같은 backbone을 업데이트하므로 feature는 “객체를 잘 찾는 것”과 “안전한 경로를 고르는 것”을 함께 지원합니다.

이 구조의 장점은 planning의 결과를 검사할 단서가 남는다는 점입니다.

- Perception box가 틀렸는지 확인할 수 있습니다.
- 특정 timestep의 cost map이 위험 위치를 낮게 평가했는지 볼 수 있습니다.
- Feasible sampler에 필요한 회피 trajectory가 있었는지 확인할 수 있습니다.

다만 **intermediate output이 보인다고 해서 판단이 완전히 설명되는 것은 아닙니다.** Cost volume 내부의 값은 학습된 점수이며 인간이 직접 정의한 안전 규칙과 같지 않습니다. Candidate sampler가 좋은 경로를 만들지 못하면 cost head가 올바르게 평가해도 그 경로를 선택할 수 없습니다. Perception, learned cost, sampling을 따로 검사해야 하는 이유입니다.

## 7. Lecture 18과 어떻게 이어집니까?

| Lecture 18 | Lecture 19 |
|---|---|
| Sensor에서 actuator command를 직접 예측 | Sensor에서 interpretable intermediate output을 예측 |
| Open-loop와 closed-loop 학습 방식 비교 | 학습한 cost로 feasible trajectory를 평가하는 구조 |
| Black-box와 distribution shift가 주요 문제 | Perception·cost volume으로 판단 근거를 일부 드러냄 |
| 최종 action loss 또는 reward가 중심 | Perception loss와 max-margin planning loss를 결합 |

이번 방법은 전통적인 modular pipeline으로 완전히 돌아가는 것이 아닙니다. Perception과 planning을 하나의 multi-task network에서 함께 학습하므로 planning loss가 shared feature에 영향을 줍니다. 동시에 bounding box와 cost volume을 남겨 modular system의 해석 가능성을 일부 가져옵니다. **End-to-end 최적화와 중간 결과 검사의 절충**으로 이해하면 됩니다.

## 마지막 핵심 정리

- Direct actuator command는 간단하지만 판단 근거를 조사하기 어렵습니다.
- Neural Motion Planner는 LiDAR 10개 sweep과 rasterized HD map을 같은 BEV grid에서 처리합니다.
- Perception head는 actor의 현재·미래 box를, cost volume head는 미래 위치별 cost를 예측합니다.
- Timestep별 최저 pixel을 바로 연결하지 않고, 먼저 feasible trajectory를 sampling한 뒤 누적 cost를 비교합니다.
- Ground-truth cost volume은 없으므로 human trajectory가 negative trajectory보다 낮은 cost를 받도록 max-margin loss를 사용합니다.
- Intermediate output은 분석 단서를 주지만 완전한 설명이나 안전 보증은 아닙니다. Perception, learned cost, candidate sampling을 각각 검증해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">강의에서 다시 들을 세 구간</summary>

| 본편 시각 | 다시 들을 질문 | 관련 자료 쪽 |
|---|---|---|
| 30:50–33:28 | 각 시각의 최저점을 이으면 왜 차가 따라가지 못할까요? | 20–22 |
| 34:14–39:45 | 조향각과 가속도로 만든 후보 하나의 비용은 어떻게 계산할까요? | 23–25 |
| 44:25–50:24 | 정답 비용표 없이도 운전자의 경로와 다른 후보의 순위를 어떻게 학습할까요? | 26–28 |

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">1. End-to-end model에 interpretable intermediate output이 필요한 이유는 무엇입니까?</summary>

답변: Actuator command만으로는 model이 어떤 actor와 위치를 근거로 판단했는지 확인하기 어렵습니다. Future box와 cost volume을 남기면 perception 오류, 위치별 평가, trajectory 선택 과정을 나누어 조사할 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">2. Timestep별 argmin pixel을 바로 연결하면 왜 문제가 됩니까?</summary>

답변: 각 점을 독립적으로 고르면 차량의 속도·가속도·조향 제한을 무시한 급격한 이동이 생길 수 있습니다. 먼저 물리적으로 실행 가능한 trajectory를 sampling하고 그 경로의 누적 cost를 비교해야 합니다.

</details>

<details markdown="block">
<summary markdown="span">3. Cost volume의 ground truth가 없는데도 학습할 수 있는 이유는 무엇입니까?</summary>

답변: 각 pixel의 절대 정답 cost는 없어도 사람이 주행한 trajectory와 sampled negative trajectory는 비교할 수 있습니다. Max-margin loss는 human trajectory의 cost가 negative보다 충분히 낮아지도록 상대적 순위를 학습합니다.

</details>

<details markdown="block">
<summary markdown="span">4. Perception head와 planning head를 함께 학습하면 무엇이 달라집니까?</summary>

답변: Shared backbone은 actor를 찾고 미래 위치를 예측하는 feature와, 안전한 trajectory를 구분하는 feature를 함께 학습합니다. Planning objective가 perception과 분리된 후처리에만 머물지 않고 backbone까지 영향을 줄 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">5. Intermediate output이 있으면 model은 완전히 설명 가능합니까?</summary>

답변: 아닙니다. Intermediate output은 오류를 추적할 단서를 늘리지만 learned cost의 모든 내부 근거를 설명하지는 않습니다. Candidate sampler의 coverage와 sensor·map 입력 오류도 별도로 확인해야 합니다.

</details>

## References

- Zeng et al., [End-To-End Interpretable Neural Motion Planner](https://openaccess.thecvf.com/content_CVPR_2019/html/Zeng_End-To-End_Interpretable_Neural_Motion_Planner_CVPR_2019_paper.html){: target="_blank" rel="noopener"}, CVPR 2019.
- [Official demo video](https://youtu.be/sOPgdIMUC0Y?t=1430){: target="_blank" rel="noopener"}
