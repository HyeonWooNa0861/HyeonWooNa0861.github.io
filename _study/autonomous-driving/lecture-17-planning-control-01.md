---
layout: default
date: 2026-11-18 00:00:04 +0900
title: "Lecture 17: Planning and Control I"
course: "Autonomous Driving"
topic: "Route, Behavior, and Motion Planning"
order: 17
major_topic: "Autonomous Systems"
keywords:
  - "Planning"
  - "Control"
  - "Route Planning"
  - "Behavior Planning"
  - "Motion Planning"
  - "Dijkstra"
  - "A*"
  - "Finite-State Machine"
---

# Lecture 17: Planning and Control I

Source PDF: [lecture-17-planning-control-01.pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf" | relative_url }})

센서가 주변을 인식하고 prediction이 다른 차량의 미래를 예측해도, 자율주행차는 아직 움직이지 않는다. **Planning은 목적지까지 무엇을 할지 결정하고, control은 그 결정을 차량이 실제로 따르게 한다.** 이 강의는 planning을 route, behavior, motion의 세 수준으로 나누어 설명한다.

> **핵심:** Route planning은 도로망에서 큰 경로를 찾는다. Behavior planning은 정지·차선 변경 같은 행동을 선택한다. Motion planning은 그 행동을 충돌 없이 실행할 세부 path와 trajectory를 만든다. Control은 trajectory를 steering·throttle·brake 명령으로 바꾼다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–15 | Planning and control overview | 인식·예측 결과가 차량 명령으로 바뀌는 경계는 어디인가? |
| 16–23 | Route planning | 도로망을 그래프로 바꾸고 최단 경로를 어떻게 찾는가? |
| 24–30 | Behavior planning | 상황별 행동 전환을 어떻게 명시하는가? |
| 31–34 | Motion planning and summary | 선택한 행동을 실제 경로와 시간 궤적으로 어떻게 구체화하는가? |
| 35–36 | Next topic and questions | 모듈형 planning을 신경망 하나로 연결하면 무엇이 달라지는가? |

페이지는 PDF의 1-based 쪽수다. 아래 수치 예제와 최적화 식은 슬라이드의 개념을 검산하기 위한 보충 설명이다.

## 1. Planning과 control의 경계

<figure class="study-source-figure" id="adc-17-p12">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p12-planning-overview.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p12-planning-overview.jpg" | relative_url }}" alt="Perception과 prediction의 출력에서 안전한 path 또는 trajectory를 만드는 planning 흐름을 보인 강의 12쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=12" | relative_url }}">lecture PDF, p. 12</a>.</figcaption>
</figure>

12쪽은 planning의 입력이 raw sensor 자체가 아니라, 앞 단계가 정리한 **ego state, 장애물, 지도, 다른 actor의 예측**임을 보여 준다. 출력은 안전하게 움직일 path 또는 trajectory다. 13–14쪽의 control은 이 목표와 현재 차량 상태를 비교하여 steering, acceleration, brake 같은 actuator command를 계산한다.

다만 15쪽처럼 실제 시스템에서는 planning이 직접 actuator command를 내도록 구성할 수도 있다. 따라서 planning과 control의 경계는 절대적인 부품 구분이 아니다. 중요한 구분은 다음과 같다.

- **Planning:** 앞으로 따라야 할 목표 행동이나 궤적을 정한다.
- **Control:** 현재 상태와 목표의 오차를 줄이도록 차량 입력을 계산한다.
- **Combined planning and control:** 하나의 모델이 목표 선택과 차량 입력을 함께 계산한다.

### Route, path, trajectory, command는 서로 다르다

| 표현 | 담는 정보 | 예시 |
|---|---|---|
| Route | 어떤 도로 구간을 어떤 순서로 지날지 | 캠퍼스에서 고속도로 진입로까지의 도로열 |
| Path | 차량이 지나갈 공간상의 곡선 | 차선 중심에서 장애물을 피해 휘는 선 |
| Trajectory | 시간까지 붙은 path | 2초 후 $$(x,y)$$와 속도, 3초 후 $$(x,y)$$와 속도 |
| Control command | 차량 구동기에 보낼 입력 | steering $$-0.08$$ rad, acceleration $$0.5\,\mathrm{m/s^2}$$ |

같은 path라도 천천히 또는 빠르게 통과할 수 있으므로 trajectory는 다를 수 있다. 같은 trajectory도 차량 동역학과 노면 상태가 다르면 필요한 command가 달라진다.

## 2. Route planning: 도로를 weighted digraph로 바꾼다

18–20쪽은 목적지까지의 큰 경로를 찾기 위해 도로망을 **방향성과 가중치를 가진 그래프**로 표현한다.

<figure class="study-source-figure" id="adc-17-p20">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p20-weighted-digraph.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p20-weighted-digraph.jpg" | relative_url }}" alt="도로 지점을 node, 진행 방향을 directed edge, 길이나 시간을 weight로 표현한 강의 20쪽 weighted digraph" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=20" | relative_url }}">lecture PDF, p. 20</a>.</figcaption>
</figure>

- **Node:** 교차로, 도로 연결점, waypoint 같은 지점
- **Directed edge:** 허용된 진행 방향
- **Weight:** 거리, 예상 소요 시간, 통행 비용처럼 최소화할 값

20쪽 그래프에서 $$s$$에서 $$t$$로 가는 두 경로를 비교할 수 있다.

$$
s\rightarrow a\rightarrow t: 2+1=3
$$

$$
s\rightarrow b\rightarrow c\rightarrow d\rightarrow t:
1+0.5+2.5+1=5
$$

따라서 표시된 edge만 사용하면 첫 경로의 비용이 더 작다. $$c\rightarrow s$$의 비용 1.1은 화살표가 $$s\rightarrow c$$가 아니라 **$$c$$에서 $$s$$로 향한다**는 점도 중요하다. 도로의 일방통행처럼 방향이 다르면 같은 두 node 사이에서도 이용 가능성이 달라진다.

### Dijkstra와 A*의 차이

21–23쪽은 두 최단 경로 알고리즘을 비교한다.

| Algorithm | 우선 탐색 기준 | 최단 경로 조건 | 특징 |
|---|---|---|---|
| Dijkstra | 시작점에서 누적 비용 $$g(n)$$ | 모든 edge weight가 음수가 아님 | 목적지 방향을 몰라도 확정 비용이 작은 node부터 넓게 탐색 |
| A* | $$f(n)=g(n)+h(n)$$ | Admissible heuristic과 올바른 graph-search 종료·재탐색 조건에서 최적성 유지 | 남은 비용 추정 $$h(n)$$으로 목적지 쪽 탐색을 우선 |

<figure class="study-source-figure" id="adc-17-p23">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p23-a-star.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p23-a-star.jpg" | relative_url }}" alt="장애물이 있는 grid에서 시작점 누적 거리와 목적지까지 남은 거리로 A star 탐색 방향을 정하는 강의 23쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=23" | relative_url }}">lecture PDF, p. 23</a>.</figcaption>
</figure>

그림의 빨간 직사각형은 통과할 수 없는 장애물이고, 초록 선은 탐색으로 찾은 경로다. A*의 $$h(n)$$은 장애물을 무시한 직선거리처럼 빠르게 계산할 수 있는 **남은 비용의 하한 추정치**를 사용할 수 있다. 직선거리가 실제 이동 비용보다 작거나 같다면, 목적지를 향하는 정보는 주되 최적 경로를 성급히 버리지 않는다. Graph search에서 heuristic이 consistent하지 않다면 더 작은 $$g$$를 발견한 node를 다시 열어야 한다. 재탐색하지 않는 구현은 consistent heuristic을 요구한다.

**수치 예제:** 어느 node에서 지금까지 비용이 $$g=4.0$$이고 목적지까지 직선거리 추정이 $$h=2.5$$라면 $$f=6.5$$다. 다른 node가 $$g=3.5$$, $$h=4.0$$이면 $$f=7.5$$다. A*는 첫 node를 먼저 살핀다. 이는 첫 node가 최종 경로에 반드시 포함된다는 뜻이 아니라, 현재 정보로 더 유망하다는 뜻이다.

<details markdown="block">
<summary markdown="span">Derivation: Why does Dijkstra finalize the shortest distance?</summary>

출발점 $$s$$에서 node $$v$$까지 알려진 최소 비용을 $$d(v)$$라고 하자. 아직 확정되지 않은 node 중 $$d(u)$$가 가장 작은 $$u$$를 고른다. 모든 edge weight가 0 이상이면, 다른 미확정 node를 거쳐 $$u$$에 도달하는 새 경로는 그 node까지의 비용보다 작아질 수 없다.

만약 $$u$$로 더 짧은 미발견 경로가 있다고 가정하면, 그 경로에서 확정 집합을 처음 벗어나는 node $$x$$가 존재한다. $$x$$까지의 실제 경로 비용은 $$u$$까지의 더 짧은 비용 이하이고, relaxation 뒤에는 $$d(x)$$도 그 값 이하가 된다. 그런데 $$u$$를 최소 $$d$$로 골랐다는 사실과 모순된다. 따라서 $$u$$의 비용을 확정할 수 있다.

음수 edge가 있으면 나중에 돌아온 경로가 비용을 더 낮출 수 있어 이 논리가 깨진다. 도로의 거리·시간은 보통 음수가 아니므로 route planning의 기본 모델과 잘 맞는다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: When does A* preserve the shortest path?</summary>

유한한 그래프와 음수가 아닌 edge weight를 가정한다. $$h(n)$$이 실제 남은 최저 비용 $$h^*(n)$$을 넘지 않는 admissible heuristic이라고 하자.

$$
0\le h(n)\le h^*(n)
$$

최적 경로에서 아직 확정되지 않은 frontier node $$n$$에 최적 prefix 비용 $$g^*(n)$$이 발견되어 있다면

$$
f(n)=g^*(n)+h(n)\le g^*(n)+h^*(n)=C^*
$$

이다. 여기서 $$C^*$$는 최적 경로의 전체 비용이다. 그러므로 goal을 priority queue에서 꺼낼 때 종료하면, 비용이 $$C^*$$보다 큰 goal보다 최적 경로의 frontier 후보가 먼저 처리된다. Consistent heuristic이면 node를 확정한 뒤 다시 열 필요가 없다. Admissible하지만 inconsistent한 heuristic은 더 작은 $$g$$가 발견될 때 node를 다시 여는 구현이 필요하다.

</details>

## 3. Behavior planning: 지금 할 행동을 상태로 표현한다

Route만 알면 어느 교차로를 통과할지는 알 수 있지만, **앞 차량을 따를지, 정지선에서 멈출지, 차선을 바꿀지**는 결정되지 않는다. 25쪽은 behavior planning을 route와 주변 인식 결과를 받아 중간 수준의 행동을 고르는 단계로 정의한다.

26쪽의 finite-state machine(FSM)은 다음 세 요소로 행동을 명시한다.

1. **State:** 현재 행동 모드
2. **Transition condition:** 다른 상태로 넘어갈 조건
3. **Action:** 해당 상태에서 수행할 제어 목표

<figure class="study-source-figure" id="adc-17-p27">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p27-vehicle-fsm.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p27-vehicle-fsm.jpg" | relative_url }}" alt="Decelerate to Stop, Stop, Track Speed 상태와 속도 위치 정지시간 조건을 연결한 강의 27쪽 차량 FSM" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=27" | relative_url }}">lecture PDF, p. 27</a>.</figcaption>
</figure>

그림은 정지선 접근 상황을 다음 순서로 표현한다.

- `Decelerate to Stop`: 속도가 0이 되고 정지 위치에 도달할 때까지 감속한다.
- `Stop`: 3초 미만이면 정지 상태를 유지한다.
- `Track Speed`: 3초가 지났고 교통이 없으면 주행을 재개한다.
- 다시 접근 상태가 감지되면 감속 상태로 돌아간다.

27쪽은 개념을 설명하는 교육용 FSM이다. `Velocity >= 0` self-loop와 `Velocity == 0 && Position == At` 전이가 동시에 참일 수 있고, `StopTime >= 3 sec`인데 교통이 남아 있을 때의 대기 조건도 별도로 적혀 있지 않다. 실제 구현에는 guard 우선순위, 상호 배타 조건, traffic이 사라질 때까지 `Stop`을 유지하는 규칙이 필요하다.

비유하면 FSM은 **상황별 운전 지침을 여러 장의 카드로 나누고, 카드 교체 조건을 화살표에 적은 구조**다. 각 순간에 한 카드가 활성화되어 있으므로 동작을 추적하기 쉽다.

### FSM의 장점과 한계

- 상태와 전환 조건이 명시되어 해석과 검증이 쉽다.
- 작은 행동 집합에서는 안전 규칙을 직접 반영하기 쉽다.
- 상황이 늘면 상태와 전환 수가 빠르게 증가한다.
- 조건 경계에서 상태가 반복 전환되지 않도록 hysteresis나 최소 유지 시간이 필요할 수 있다.
- 인식 불확실성을 단순한 참·거짓 조건으로 줄이면 애매한 상황을 충분히 표현하지 못할 수 있다.
- FSM은 행동 전환 구조이며, 차량의 물리 동역학이나 충돌 안전을 스스로 증명하지 않는다.

<figure class="study-source-figure" id="adc-17-p30">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p30-darpa-fsm.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p30-darpa-fsm.jpg" | relative_url }}" alt="Forward Drive를 중심으로 U turn, 교차로, 정지표지, 주차 등 여러 행동 상태가 연결된 강의 30쪽 DARPA Challenge FSM" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=30" | relative_url }}">lecture PDF, p. 30</a>.</figcaption>
</figure>

30쪽의 DARPA 예시는 단순한 3-state FSM이 실제 임무에서 `UTURN`, `CROSS_INTERSECTION`, `STOP_SIGN_WAIT`, `PARKING_NAVIGATE` 등으로 커지는 모습을 보여 준다. 이 그림의 핵심은 특정 상태 이름을 외우는 것이 아니라, **현실의 예외가 늘수록 상태 전환 설계가 복잡해진다는 점**이다.

## 4. Motion planning: 행동을 움직일 수 있는 trajectory로 바꾼다

<figure class="study-source-figure" id="adc-17-p32">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-17/p32-motion-planning.jpg" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-17/p32-motion-planning.jpg" | relative_url }}" alt="주변 차량을 피하며 세부 path와 시간에 따른 trajectory를 만드는 motion planning 목표를 설명한 강의 32쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf#page=32" | relative_url }}">lecture PDF, p. 32</a>.</figcaption>
</figure>

32쪽은 motion planning을 low-level planning으로 부른다. Route가 정한 도로와 behavior가 정한 행동을 만족하면서, 차량이 실제로 따라갈 수 있는 세부 path와 trajectory를 만든다. 그림에서는 빨간 ego vehicle이 앞뒤 차량과 충돌하지 않도록 옆으로 이동하는 곡선을 만든다.

일반적인 최적화 형태는 다음처럼 정리할 수 있다.

$$
\min_{\mathbf{x}_{0:T},\mathbf{u}_{0:T-1}}
J_{\text{progress}}+\lambda_1J_{\text{comfort}}+\lambda_2J_{\text{tracking}}
$$

subject to

$$
\mathbf{x}_{t+1}=f(\mathbf{x}_t,\mathbf{u}_t),
\quad \mathbf{x}_t\in\mathcal X_{\text{safe}},
\quad \mathbf{u}_t\in\mathcal U.
$$

여기서 $$\mathbf{x}_t$$는 위치·방향·속도 같은 차량 상태, $$\mathbf{u}_t$$는 steering·acceleration 같은 입력이다. 목적함수는 진행, 승차감, 경로 추종을 함께 평가한다. 제약식은 차량 동역학, 충돌 회피, 조향·가속 한계를 나타낸다. 이 식은 슬라이드의 “수학적 최적화”를 일반형으로 풀어 쓴 보충 설명이며, 강의가 특정 solver 하나를 지정한 것은 아니다.

**수치 예제:** 두 후보 trajectory가 모두 20 m 전진한다고 하자. 후보 A의 최대 횡가속도가 $$1.2\,\mathrm{m/s^2}$$이고 장애물 최소 거리가 2.0 m, 후보 B는 각각 $$2.8\,\mathrm{m/s^2}$$와 0.4 m라면, B가 더 짧아 보여도 안전거리 제약 1.0 m를 위반한다. 목적함수 점수를 비교하기 전에 B를 제외해야 한다. **안전 constraint와 편안함 cost는 같은 역할이 아니다.**

<details markdown="block">
<summary markdown="span">Derivation: From path curvature to lateral acceleration</summary>

차량이 곡률 $$\kappa$$인 path를 속도 $$v$$로 따라가면 원운동 관계에서 횡가속도는

$$
a_{\mathrm{lat}}=v^2\kappa
$$

다. 반지름 $$R$$인 원에서는 $$\kappa=1/R$$이므로 $$a_{\mathrm{lat}}=v^2/R$$와 같다. 곡률이 같은 path라도 속도가 두 배가 되면 횡가속도는 네 배가 된다. 따라서 공간상의 path만 정해서는 승차감과 동역학 한계를 판단할 수 없다. 시간과 속도가 붙은 trajectory가 필요한 이유다.

예를 들어 $$R=25$$ m, $$v=10\,\mathrm{m/s}$$이면 $$a_{\mathrm{lat}}=4\,\mathrm{m/s^2}$$다. 같은 곡선을 $$v=5\,\mathrm{m/s}$$로 지나면 $$1\,\mathrm{m/s^2}$$로 줄어든다.

</details>

## 5. 세 planning 수준의 연결

| Level | 핵심 입력 | 핵심 출력 | 실패 예시 |
|---|---|---|---|
| Route | 목적지, road graph | 도로·waypoint 순서 | 막힌 도로를 선택하거나 일방통행을 거슬러 계획 |
| Behavior | Route, perception, prediction | 정지·추종·차선 변경 같은 mode | 접근 차량이 있는데 교차로 진입을 선택 |
| Motion | Behavior 목표, free space, 차량 상태 | 충돌 없는 path와 time trajectory | 기하학적으로는 가능하지만 급격한 조향이 필요한 궤적 |
| Control | 목표 trajectory, 현재 차량 상태 | actuator command | 추종 오차가 커서 차선을 벗어남 |

각 수준은 앞 수준의 출력을 그대로 믿기만 해서는 안 된다. Route가 있어도 현재 도로가 막혔으면 다시 계획해야 한다. Behavior가 차선 변경을 택해도 motion planner가 안전한 궤적을 찾지 못하면 행동을 보류하거나 다른 행동을 요청해야 한다. Planning은 단방향 목록보다 **실패를 상위 수준에 되돌리는 반복 과정**으로 이해하는 편이 정확하다.

## 마지막 핵심 정리

- **Planning은 행동과 궤적을 정하고 control은 차량 입력을 계산한다.** 두 기능을 하나의 모델로 합칠 수도 있다.
- **Route는 도로 순서, path는 공간 곡선, trajectory는 시간이 붙은 path, command는 구동기 입력**이다.
- 도로망은 node, directed edge, nonnegative weight를 가진 graph로 표현할 수 있다.
- Dijkstra는 누적 비용 $$g$$를, A*는 $$f=g+h$$를 사용한다. A*의 $$h$$는 실제 남은 거리가 아니라 하한을 주는 heuristic이다.
- FSM은 행동 전환을 명시하지만, guard의 완전성·우선순위와 물리적 안전을 별도로 검증해야 한다.
- Motion planning은 차량 동역학과 안전 제약을 만족하면서 진행·승차감·추종 cost를 조정한다.

## Study Guide

| 다시 볼 부분 | 확인할 내용 |
|---|---|
| pp. 12–15 | Planning output과 control command의 경계 |
| pp. 18–23 | Directed road graph, edge weight, Dijkstra와 A* 조건 |
| pp. 25–30 | Behavior state, transition guard, FSM의 불완전 조건 |
| pp. 31–32 | Path와 trajectory 차이, optimization의 cost와 constraint |

복습할 때는 **route, behavior, motion, control**의 입력과 출력을 먼저 한 줄씩 적는다. 그다음 20쪽 graph의 두 경로 비용을 계산하고, 27쪽 FSM에서 동시에 참이 될 수 있는 guard를 찾는다. 마지막으로 같은 path에서 속도에 따라 횡가속도가 달라지는 이유를 확인한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Route, path, trajectory, control command는 어떻게 다른가?</summary>

답변: Route는 지날 도로 구간의 순서, path는 공간상의 곡선, trajectory는 각 위치에 시간·속도가 붙은 경로다. Control command는 목표 trajectory를 따라가도록 구동기에 보내는 steering·acceleration·brake 값이다.

</details>

<details markdown="block">
<summary markdown="span">2. 강의 20쪽 graph에서 가장 짧은 표시 경로는 무엇인가?</summary>

답변: $$s\rightarrow a\rightarrow t$$이며 비용은 $$2+1=3$$이다. $$s\rightarrow b\rightarrow c\rightarrow d\rightarrow t$$는 $$1+0.5+2.5+1=5$$다. $$c\rightarrow s$$의 edge는 방향이 반대이므로 $$s\rightarrow c$$로 사용할 수 없다.

</details>

<details markdown="block">
<summary markdown="span">3. A* heuristic이 실제 남은 비용보다 크면 무엇이 문제인가?</summary>

답변: 최적 경로 위 node의 $$f=g+h$$가 과대평가되어 더 비싼 goal보다 뒤로 밀릴 수 있다. Goal을 먼저 꺼냈을 때 종료하면 최적 경로를 놓칠 수 있다. Admissible heuristic과 올바른 재탐색·종료 조건이 필요한 이유다.

</details>

<details markdown="block">
<summary markdown="span">4. 27쪽 FSM을 그대로 안전 제어기로 사용할 수 없는 이유는 무엇인가?</summary>

답변: 동시에 참인 guard의 우선순위와 traffic이 남았을 때의 대기 조건이 완전하게 적혀 있지 않다. FSM은 behavior 전환을 설명하지만 차량 동역학, 충돌 회피, sensor uncertainty를 별도로 검증해야 한다.

</details>

<details markdown="block">
<summary markdown="span">5. 같은 path에서도 trajectory가 필요한 이유는 무엇인가?</summary>

답변: 속도가 붙어야 동역학과 승차감을 판단할 수 있기 때문이다. 곡률이 $$\kappa$$인 path의 횡가속도는 $$a_{\mathrm{lat}}=v^2\kappa$$이므로, 같은 곡선에서도 속도가 두 배면 횡가속도는 네 배가 된다.

</details>

## PDF

[Open the original lecture PDF]({{ "/assets/pdfs/study/autonomous-driving/lecture-17-planning-control-01.pdf" | relative_url }})
