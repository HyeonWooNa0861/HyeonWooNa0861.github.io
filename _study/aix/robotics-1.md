---
layout: default
title: "Robotics 1"
course: "AIX"
topic: "Imitation Learning and DAggER"
order: 9
major_topic: "Artificial Intelligence"
keywords:
  - "Imitation Learning"
  - "Behavioral Cloning"
  - "Covariate Shift"
  - "DAggER"
  - "Robot Control"
---

# Robotics 1

Source PDF: `Robotics_1.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Imitation Learning | 왜 초기 robot learning은 expert demonstration에 의존했는가? |
| 2 | Autonomous Driving Example | 관측과 human steering action을 짝지으면 무엇을 학습하는가? |
| 3 | RL의 비용 | 왜 physical robot에서 pure RL은 비싸고 느린가? |
| 4 | Supervised Learning과 차이 | robot action은 왜 미래 input distribution을 바꾸는가? |
| 5 | Behavioral Cloning | expert trajectory를 policy로 바꾸는 가장 단순한 방법은 무엇인가? |
| 6 | Distribution Shift | expert state에서만 배운 policy는 왜 drift 후 회복하지 못하는가? |
| 7 | Error Growth | 독립 오류와 sequential 오류는 왜 \\(T\epsilon\\), \\(O(T^2\epsilon)\\)처럼 달라지는가? |
| 8 | DAggER | learner가 방문한 state에 expert label을 붙이면 무엇이 좋아지는가? |
| 9 | Generality | SuperTuxKart, Super Mario 예시는 어떤 공통 문제를 보여주는가? |
| 10 | Remaining Bottleneck | 왜 modern robotics는 foundation model, world model, VLA로 이동하는가? |

Robotics 1은 imitation learning이 왜 매력적인지에서 시작해, behavioral cloning의 한계와 DAggER의 해결 전략을 정리한다. 핵심은 robot learning을 단순한 supervised learning으로 보면 안 된다는 점이다. 로봇의 action은 다음 state를 바꾸고, 다음 state는 다시 policy의 입력이 된다.

## 1. 왜 Imitation Learning인가?

초기 robot learning은 human demonstration을 많이 사용했다. 이유는 physical robot에서 trial-and-error가 비싸고 느리며 위험할 수 있기 때문이다.

| 학습 방식 | 장점 | 한계 |
|---|---|---|
| Pure reinforcement learning | 직접 시행착오로 policy를 개선할 수 있음 | 실제 로봇에서는 trial 수가 너무 많고 안전 문제가 큼 |
| Imitation learning | expert behavior를 바로 policy 학습에 사용 | expert data 분포를 벗어나면 취약할 수 있음 |

Imitation learning의 역사적 목표는 단순하다.

> Expert behavior를 autonomous policy로 변환한다.

자율주행 예시는 이 직관을 잘 보여준다. 카메라 observation과 사람이 조향한 steering action을 짝으로 모으면, control 문제를 observation-to-action supervised mapping으로 바꿀 수 있다.

$$
o_t \rightarrow a_t
$$

여기서 \\(o_t\\)는 observation, \\(a_t\\)는 expert action이다.

## 2. Imitation은 Ordinary Supervised Learning이 아니다

겉으로 보면 imitation learning은 supervised learning과 비슷하다. 입력 observation이 있고, 정답 action이 있기 때문이다.

하지만 결정적인 차이가 있다.

| 일반 supervised learning | robot imitation learning |
|---|---|
| 예측이 다음 test input distribution을 바꾸지 않는 경우가 많음 | action이 environment를 바꾸고 다음 state를 만든다. |
| sample들이 비교적 독립적으로 취급됨 | sequential decision이므로 error가 이후 state에 누적됨 |
| train/test distribution mismatch가 있어도 입력은 외부에서 주어짐 | learned policy가 자기 자신의 state distribution을 유도함 |

로봇은 잘못된 action을 하면 다음 observation 자체가 바뀐다. 작은 steering error 하나가 trajectory를 expert path에서 벗어나게 만들고, 그 뒤에는 training data에 없던 state를 계속 만나게 된다.

이 때문에 imitation learning에서는 covariate shift와 compounding error가 핵심 문제가 된다.

## 3. Behavioral Cloning

Behavioral Cloning은 expert trajectory를 모아서 supervised learning으로 policy를 학습하는 방법이다.

```text
expert trajectories -> dataset of (observation, action) -> supervised policy
```

정책은 다음처럼 볼 수 있다.

$$
\pi_\theta(a\mid o)
$$

또는 deterministic하게 쓰면

$$
a=\pi_\theta(o)
$$

학습 목표는 expert가 어떤 observation에서 선택한 action을 policy가 따라 하도록 만드는 것이다.

| 구성 | 의미 |
|---|---|
| observation \\(o\\) | 카메라 이미지, game screen, robot sensor state 등 |
| expert action \\(a^*\\) | 사람 또는 expert controller가 선택한 행동 |
| policy \\(\pi_\theta\\) | observation을 action으로 바꾸는 learned model |

Behavioral cloning은 expert state distribution 위에서는 잘 작동할 수 있다. 하지만 expert가 거의 방문하지 않은 state에서는 recovery behavior를 배우지 못한다.

## 4. Behavioral Cloning의 실패 원인

강의는 failure post-mortem을 단순히 “모델이 약했다” 또는 “같은 expert distribution의 data가 부족했다”로 보지 않는다. 진짜 문제는 missing data distribution이다.

> 필요한 data는 expert trajectory 위의 더 많은 data가 아니라, learner가 drift한 뒤 회복하는 state-action data다.

예를 들어 자율주행 imitation에서 expert는 차선을 잘 유지하므로 도로 중앙 근처 state가 많다. 그런데 learner가 살짝 오른쪽으로 밀려나면, training set에는 “오른쪽으로 치우친 상태에서 왼쪽으로 복구하는 action”이 부족할 수 있다.

| 상황 | 문제 |
|---|---|
| expert trajectory 근처 | behavioral cloning이 action을 잘 따라 할 수 있음 |
| learner가 drift한 state | expert data에 없어서 policy output이 불안정 |
| off-distribution state 지속 | 다음 action이 더 큰 drift를 만들 수 있음 |

이런 식으로 작은 실수가 cascading errors를 만든다.

## 5. Covariate Shift와 Error Growth

Supervised learning은 train example과 test example이 같은 distribution에서 나온다고 가정하는 경우가 많다. Sequential decision-making에서는 learned policy가 자기 자신의 state distribution을 만든다.

이를 다음처럼 구분할 수 있다.

| 분포 | 의미 |
|---|---|
| expert state distribution | expert demonstration이 방문한 state들의 분포 |
| learner state distribution | learned policy가 실행 중 실제로 방문하는 state들의 분포 |

Behavioral cloning은 주로 expert state distribution에서 학습한다. 하지만 test-time에는 learner state distribution에서 행동해야 한다.

강의는 error growth를 다음 직관으로 설명한다.

| 오류 상황 | 누적 규모 |
|---|---|
| independent prediction errors | horizon \\(T\\)에서 대략 \\(T\epsilon\\) |
| correlated sequential errors | drift가 다음 입력을 바꾸므로 \\(O(T^2\epsilon)\\)처럼 커질 수 있음 |

여기서 \\(\epsilon\\)은 한 step에서 policy가 실수할 확률 또는 error rate의 직관적 표현이다. 중요한 것은 sequential setting에서는 error가 독립적으로 끝나지 않고 다음 입력을 나쁘게 만든다는 점이다.

## 6. DAggER의 핵심 아이디어

DAggER는 Dataset Aggregation의 약자다. 핵심은 data collection process를 바꾸는 것이다.

Behavioral cloning은 expert가 방문한 state에 대해서만 label을 갖는다. DAggER는 learner가 실제로 방문한 state를 모으고, 그 state에 대해 expert가 올바른 action을 다시 label한다.

```text
train initial policy
-> roll out learner
-> collect learner-visited states
-> ask expert for labels
-> aggregate dataset
-> retrain policy
```

이 과정을 반복하면 policy는 expert trajectory 근처뿐 아니라 자기 자신이 실제로 만들어내는 state distribution 위에서도 더 나은 action을 배우게 된다.

## 7. DAggER Step by Step

### Step 1: Start Like Behavioral Cloning

첫 policy는 expert demonstration으로 학습한다.

$$
D_0=\{(o_i,a_i^*)\}
$$

이 초기 policy는 baseline controller 역할을 한다.

### Step 2: Roll Out the Learner

Learner가 직접 action을 선택하며 environment 안에서 움직인다. 이때 learner가 방문하는 state들은 expert trajectory와 다를 수 있다.

중요한 점은 이 state들이 바로 test-time에 실제로 나타날 가능성이 큰 state라는 것이다.

### Step 3: Aggregate and Retrain

Learner가 방문한 state에 expert action label을 붙인다.

$$
D_{i+1}=D_i\cup\{(o,a^*_{\text{expert}})\}
$$

그 다음 aggregated dataset으로 policy를 다시 학습한다. 강의에서는 \\(\beta_i\\)가 decay하면서 policy가 점점 자기 자신의 state distribution에 직접 훈련된다고 설명한다.

## 8. DAggER가 고친 것

DAggER의 역사적 가치는 network architecture를 바꾼 것이 아니라 data collection을 바꾼 데 있다.

| 방법 | 학습 분포 | 회복 행동 |
|---|---|---|
| Behavioral Cloning | expert가 방문한 state 중심 | expert가 drift하지 않으면 부족 |
| DAggER | learner가 실제 방문한 state까지 포함 | drift state에 expert correction을 붙여 학습 |

즉 DAggER는 sequential error growth를 줄인다. Learner가 실패하는 곳을 data로 다시 가져와 label을 붙이고 학습하기 때문이다.

## 9. Game-Like Control 예시

SuperTuxKart 예시는 learner가 직접 운전하고, 실패하고, expert correction을 받고, 다시 좋아지는 과정을 직관적으로 보여준다.

Super Mario 예시는 DAggER가 한 domain에만 묶인 기법이 아니라는 점을 보여준다. Action이 future input을 바꾸는 sequential prediction task라면 같은 covariate shift 문제가 나타날 수 있다.

| 예시 | 보여주는 점 |
|---|---|
| SuperTuxKart | learner drives, fails, gets labels, improves |
| Super Mario | sequential prediction이면 domain이 달라도 distribution shift가 생김 |

## 10. 남은 한계와 Robotics 2로의 연결

DAggER는 task-specific imitation을 더 robust하게 만들었지만, 여전히 expert correction과 narrow task data에 의존한다.

| 한계 | 설명 |
|---|---|
| expert correction 비용 | learner state마다 expert label이 필요함 |
| narrow task data | 특정 task나 environment에 과하게 묶일 수 있음 |
| generalization 부족 | 새로운 object, instruction, embodiment로 전이하기 어려움 |

이 한계가 modern robotics의 foundation model, world model, VLA-style generalization으로 이어진다. Robotics 2는 바로 이 전환을 다룬다.

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| imitation learning | expert demonstration을 policy 학습에 사용하는 방식 |
| behavioral cloning | expert trajectory를 observation-to-action supervised learning으로 학습 |
| covariate shift | train distribution과 test-time learner state distribution이 달라지는 문제 |
| compounding error | 작은 action error가 다음 state를 바꾸고 이후 오류를 누적시키는 현상 |
| DAggER | learner가 방문한 state에 expert label을 붙여 dataset을 aggregate하고 retrain |
| DAggER의 가치 | architecture보다 data collection process를 바꿔 sequential error를 줄임 |
| 남은 한계 | expert correction과 narrow task data 의존 |

## Study Guide

Robotics 1은 behavioral cloning과 DAggER의 차이를 중심으로 읽어야 한다. 단순히 “expert를 따라 한다”로 끝내지 말고, learner action이 다음 state distribution을 바꾼다는 점을 계속 붙잡아야 한다.

시험에서는 supervised learning과 imitation learning의 차이를 묻는 선택지가 중요하다. 정답은 보통 “현재 action이 다음 state와 미래 input distribution을 바꾼다”는 방향이다.

| 시험 포인트 | 확인할 내용 |
|---|---|
| imitation learning이 매력적인 이유 | physical robot에서 trial-and-error가 비싸고 느림 |
| behavioral cloning 정의 | expert trajectory를 supervised observation-to-action mapping으로 학습 |
| BC의 한계 | expert distribution 밖 recovery behavior 부족 |
| covariate shift | learner가 자기 state distribution을 유도 |
| error growth | sequential error는 cascading되어 더 크게 누적 가능 |
| DAggER | learner-visited states + expert labels + aggregate/retrain |

## 복습 질문

<details>
<summary>1. Physical robot에서 imitation learning이 매력적인 이유는 무엇인가?</summary>

답변: 실제 로봇에서 pure reinforcement learning은 많은 trial-and-error를 요구하므로 비용이 크고 느리며 위험할 수 있다. Imitation learning은 expert demonstration을 사용해 초기에 훨씬 sample-efficient하게 policy를 학습할 수 있다.

</details>

<details>
<summary>2. Behavioral cloning은 무엇인가?</summary>

답변: Expert trajectory에서 observation과 expert action 쌍을 모아 supervised learning으로 policy를 학습하는 방법이다. 즉 observation을 입력으로 받고 expert action을 label로 사용한다.

</details>

<details>
<summary>3. Imitation learning이 ordinary supervised learning과 다른 이유는 무엇인가?</summary>

답변: Ordinary supervised learning에서는 model prediction이 다음 input distribution을 바꾸지 않는 경우가 많다. 반면 robotics에서는 policy의 action이 다음 state를 바꾸고, 그 state가 다시 다음 input이 되므로 error가 future distribution을 바꾼다.

</details>

<details>
<summary>4. Behavioral cloning이 drift state에서 취약한 이유는 무엇인가?</summary>

답변: Behavioral cloning은 expert가 방문한 state distribution 위에서 주로 학습한다. Expert는 보통 안정적인 trajectory를 유지하므로, learner가 실수로 벗어난 state와 그 state에서의 recovery action data가 부족하다.

</details>

<details>
<summary>5. DAggER의 핵심 절차는 무엇인가?</summary>

답변: 초기 policy를 expert demonstration으로 학습하고, learner를 roll out해 learner가 방문한 state를 모은다. 그 state에 expert action label을 붙이고 dataset에 aggregate한 뒤 policy를 retrain한다.

</details>

<details>
<summary>6. DAggER가 바꾼 것은 model architecture인가 data collection인가?</summary>

답변: DAggER의 핵심은 data collection process를 바꾼 것이다. Learner가 실제로 방문하는 on-policy state를 모아 expert label을 붙이기 때문에 sequential error growth를 줄일 수 있다.

</details>

<details>
<summary>7. DAggER 이후에도 남는 bottleneck은 무엇인가?</summary>

답변: DAggER는 expert correction과 narrow task data에 여전히 의존한다. 이 한계 때문에 modern robotics는 foundation model, world model, VLA-style generalization으로 이동한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/Robotics_1.pdf" | relative_url }}" target="_blank" rel="noopener">Robotics_1.pdf</a></li>
</ul>
