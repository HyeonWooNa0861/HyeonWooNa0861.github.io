---
layout: default
title: "AIX Quiz Review After Midterm"
course: "AIX"
topic: "After Midterm Quiz Review"
order: 2
---

# AIX Quiz Review After Midterm

Source PDFs:

- `aix-quiz-20260521.pdf`
- `aix-quiz-20260602.pdf`
- `aix-quiz-20260604.pdf`
- `aix-quiz-20260605-1.pdf`
- `aix-quiz-20260605-2.pdf`

이 글은 중간고사 이후부터 기말고사 전까지의 AIX Quiz PDF 5개를 시험 대비용으로 다시 정리한 자료다. 원문 선택지를 그대로 나열하기보다, 각 문항이 묻는 개념과 정답을 고르는 기준을 중심으로 재구성했다.

## 전체 흐름

| 회차 | 핵심 주제 | 시험에서 잡아야 할 기준 |
|---|---|---|
| 20260521 | LLM 생성 방식 | next token prediction, MoE, beam search, greedy decoding, decoder-only Transformer |
| 20260602 | 자율주행 기본 구조 | modular stack, perception, uncertainty, error propagation, corner case |
| 20260604 | Tesla End-to-End | occupancy, learned 3D representation, representation-level end-to-end, shared world representation |
| 20260605 (1) | Imitation Learning | expert demonstration, behavioral cloning, state distribution shift, DAggER |
| 20260605 (2) | Robotics Scaling | VLA, ego-video, embodied AI, world model, action fine-tuning, physical RL |

빠르게 복습할 때는 다음 다섯 문장을 먼저 기억하면 된다.

1. LLM은 지금까지의 token을 바탕으로 다음 token을 예측한다.
2. MoE는 모든 expert를 항상 쓰는 것이 아니라, token마다 필요한 expert 일부만 활성화한다.
3. 기존 자율주행 modular stack은 앞단 오류가 뒤 단계로 전파될 수 있다.
4. Tesla식 end-to-end는 카메라에서 조향까지 완전히 직결하는 뜻보다 shared world representation을 학습하는 관점에 가깝다.
5. 로봇 학습에서는 행동이 다음 상태 분포를 바꾸기 때문에 ordinary supervised learning보다 distribution shift 문제가 크다.

## 1. 20260521: LLM 생성과 Decoding

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Next Token Prediction | 이전 token을 바탕으로 다음 token 하나를 예측하고 반복 |
| Q2 | Mixture of Experts | token별로 필요한 expert 일부만 활성화 |
| Q3 | Beam Search | 가능성 높은 \\(k\\)개 경로를 유지 |
| Q4 | Greedy Decoding | 매 step마다 확률이 가장 높은 token 하나 선택 |
| Q5 | LLM Transformer | decoder-only autoregressive Transformer |

<details>
<summary>Q1. Next Token Prediction은 어떻게 이해해야 하는가?</summary>

풀이과정:

Next token prediction은 문장 전체를 한 번에 완성하는 방식이 아니다. 모델은 지금까지 입력된 token sequence를 조건으로 다음 위치에 올 token의 확률분포를 계산한다.

$$
P(x_t \mid x_1, x_2, \dots, x_{t-1})
$$

그 다음 선택된 token을 다시 문맥에 붙이고, 같은 과정을 반복하여 문장을 생성한다.

답변: 지금까지 본 token을 바탕으로 다음 token 하나를 예측하고, 이를 반복해 문장을 생성하는 방식이다.

</details>

<details>
<summary>Q2. Mixture of Experts의 핵심 아이디어는 무엇인가?</summary>

풀이과정:

MoE는 거대한 모델 capacity를 모두 매번 계산하지 않기 위해 사용한다. 입력 token마다 router가 적절한 expert 일부를 고르고, 선택된 expert만 계산에 참여한다.

핵심은 sparse activation이다. 모든 token이 모든 expert를 쓰면 계산량이 커진다. 반대로 token마다 일부 expert만 쓰면 큰 모델의 표현력은 유지하면서 계산 비용을 줄일 수 있다.

답변: token마다 필요한 expert 일부만 활성화해 큰 모델 capacity를 효율적으로 사용하는 방법이다.

</details>

<details>
<summary>Q3. Beam Search를 Best-of-N 관점에서 어떻게 이해하는가?</summary>

풀이과정:

Greedy decoding은 매 순간 가장 높은 확률의 token 하나만 고른다. Beam search는 그보다 넓게 본다. 매 step에서 가능성 높은 \\(k\\)개의 후보 sequence를 유지하면서 다음 token을 확장한다.

이 방식은 모든 경우를 끝까지 탐색하지는 않는다. 그러나 하나의 경로만 고르는 것보다 더 좋은 전체 문장을 찾을 가능성을 남긴다.

답변: 가능성이 높은 \\(k\\)개의 경로를 유지해 모든 경우를 보지 않으면서도 더 좋은 전체 문장을 찾을 기회를 남기는 방법이다.

</details>

<details>
<summary>Q4. Greedy Decoding은 무엇인가?</summary>

풀이과정:

Greedy decoding은 가장 단순한 decoding 방식이다. 각 step에서 현재 확률이 가장 높은 token 하나를 선택하고, 선택을 되돌리지 않는다.

장점은 빠르고 저렴하다는 점이다. 단점은 지금 당장 좋아 보이는 선택이 전체 문장 관점에서 최선이라는 보장은 없다는 점이다.

답변: 매 step마다 가장 확률이 높은 token 하나를 고르는 가장 단순하고 저렴한 decoding 방법이다.

</details>

<details>
<summary>Q5. Large Language Model의 Transformer는 어떻게 설명해야 하는가?</summary>

풀이과정:

GPT 계열 LLM은 주로 decoder-only Transformer 구조를 사용한다. 이미 본 token들을 조건으로 다음 token을 예측하는 autoregressive 방식이다.

encoder-only는 BERT처럼 입력 이해에 강한 구조를 설명할 때 더 적절하다. CNN이나 RNN과 동일하다는 설명도 틀리다.

답변: 주로 decoder-only Transformer이며, 이미 본 token들로부터 다음 token을 예측하는 autoregressive 방식이다.

</details>

## 2. 20260602: 자율주행 기본 구조와 Modular Stack

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | End-to-End 이전 구조 | perception, prediction, planning, control로 나뉜 modular stack |
| Q2 | 자율주행이 AI 문제인 이유 | perception과 uncertainty가 큰 문제 |
| Q3 | 초기 ML 적용 영역 | perception |
| Q4 | modular stack 약점 | 앞단 오류가 뒤 단계로 전파 |
| Q5 | corner case 중요성 | unusual case coverage가 안전성에 크게 영향 |

<details>
<summary>Q1. End-to-End 이전 자율주행의 대표 구조는 무엇인가?</summary>

풀이과정:

초기 자율주행 시스템은 하나의 거대한 end-to-end 네트워크보다 여러 모듈로 나뉜 pipeline에 가까웠다.

대표 흐름은 다음과 같다.

$$
\text{Perception} \rightarrow \text{Prediction} \rightarrow \text{Planning} \rightarrow \text{Control}
$$

Perception은 주변 객체와 도로 상황을 인식하고, prediction은 다른 agent의 미래 움직임을 예측한다. planning은 차량이 갈 경로를 만들고, control은 실제 조향과 가감속 명령으로 바꾼다.

답변: perception, prediction, planning, control로 나뉜 modular stack 방식이다.

</details>

<details>
<summary>Q2. 자율주행이 AI 문제로 여겨지는 가장 큰 이유는 무엇인가?</summary>

풀이과정:

자율주행은 단순히 steering angle을 계산하는 제어 문제가 아니다. 실제 도로에서는 사람, 차량, 표지판, 차선, 날씨, 가려짐, 예측 불가능한 행동이 섞인다.

따라서 핵심 난점은 perception과 uncertainty다. 잘 보이지 않는 상황을 해석하고, 불확실한 미래를 고려해야 한다.

답변: 운전이 단순 제어 문제가 아니라 perception과 uncertainty가 큰 문제이기 때문이다.

</details>

<details>
<summary>Q3. 초기 산업용 자율주행에서 machine learning이 먼저 크게 들어간 영역은 어디인가?</summary>

풀이과정:

초기에는 전체 시스템을 end-to-end로 학습하기보다, 센서 입력에서 객체와 환경을 인식하는 perception 영역에 machine learning이 강하게 적용되었다.

이미지나 LiDAR point cloud에서 차선, 보행자, 차량을 찾는 문제는 rule만으로 다루기 어렵고, 데이터 기반 인식 모델의 장점이 크다.

답변: 인식, 즉 perception 영역이다.

</details>

<details>
<summary>Q4. Modular autonomous driving stack의 대표적 약점은 무엇인가?</summary>

풀이과정:

modular stack은 각 단계가 분명해 해석하기 쉽지만, 앞단 모듈의 작은 실수가 뒤 단계로 전달될 수 있다.

예를 들어 perception이 보행자를 잘못 인식하면 prediction과 planning도 잘못된 입력을 바탕으로 계산한다. 따라서 최종 주행 결과가 나빠질 수 있다.

답변: 앞단 모듈의 작은 실수가 뒤 단계로 전파되어 전체 주행 결과가 나빠질 수 있다.

</details>

<details>
<summary>Q5. Autonomous driving에서 corner case가 중요한 이유는 무엇인가?</summary>

풀이과정:

자율주행 안전성은 평균 상황에서의 정확도만으로 판단하기 어렵다. 실제 사고 위험은 unusual case, rare case, edge case에서 크게 드러날 수 있다.

따라서 모델이 평범한 상황을 잘 처리하는지뿐 아니라 드문 상황을 얼마나 잘 coverage하는지가 중요하다.

답변: 안전성은 평균 정확도뿐 아니라 unusual case를 얼마나 잘 coverage하는지에 크게 좌우되기 때문이다.

</details>

## 3. 20260604: Tesla End-to-End와 World Representation

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Tesla End-to-End 변화 | object list에서 occupancy 중심 world representation으로 전환 |
| Q2 | Tesla architecture | multi-camera image/video 기반 learned 3D representation |
| Q3 | Tesla end-to-end 표현 | representation-level end-to-end |
| Q4 | occupancy 장점 | geometry, free space, semantics를 함께 다룸 |
| Q5 | shared world representation 이유 | manually stitched intermediate interface 의존 감소, 여러 task가 표현 공유 |

<details>
<summary>Q1. Tesla End-to-End 이야기에서 가장 중요한 변화는 무엇인가?</summary>

풀이과정:

핵심은 단순히 object list를 더 잘 만드는 것이 아니다. 기존 객체 목록 중심의 인식 결과를 넘어서, 주행 가능한 공간과 장면 구조를 함께 표현하는 occupancy 중심 world representation으로 관점이 이동한 것이다.

object list는 "무엇이 있는가"에 강하지만, free space와 geometry를 충분히 표현하기 어렵다. occupancy 표현은 주행 공간 자체를 모델이 이해하도록 돕는다.

답변: object list에서 occupancy 중심 world representation으로 관점을 바꾼 것이다.

</details>

<details>
<summary>Q2. Tesla architecture를 가장 쉽게 설명하면?</summary>

풀이과정:

Tesla식 접근은 multi-camera image/video를 입력으로 사용해 장면의 learned 3D representation을 만든다. 즉 2D 이미지를 단순 분류하는 데서 멈추지 않고, 주행에 필요한 3D world state를 학습 표현으로 구성한다.

답변: 멀티카메라 이미지/비디오를 바탕으로 learned 3D representation을 만드는 구조다.

</details>

<details>
<summary>Q3. Tesla의 “end-to-end”를 어떻게 표현해야 하는가?</summary>

풀이과정:

Tesla의 end-to-end를 "카메라에서 steering까지 아무 중간 표현 없이 바로 예측"으로만 이해하면 지나치게 강한 표현이다. 더 적절한 표현은 world state를 하나의 unified latent form으로 학습하는 representation-level end-to-end다.

즉 perception, prediction, planning의 경계를 완전히 없앤다기보다, 여러 task가 공유할 수 있는 표현을 학습하는 방향에 가깝다.

답변: world state를 하나의 unified latent form으로 학습하는 representation-level end-to-end다.

</details>

<details>
<summary>Q4. Occupancy가 object-list 방식보다 좋은 점은 무엇인가?</summary>

풀이과정:

object list는 알려진 object class를 검출하는 데 초점이 있다. 하지만 주행에는 object 이름뿐 아니라 geometry, free space, semantics가 중요하다.

occupancy는 특정 객체 이름이 없어도 공간이 차 있는지, 비어 있는지, 주행 가능한지 등을 planning과 더 직접적으로 연결할 수 있다.

답변: geometry, free space, semantics를 함께 다뤄 planning으로 연결하기 좋다.

</details>

<details>
<summary>Q5. Shared world representation을 쓰려는 이유는 무엇인가?</summary>

풀이과정:

기존 modular stack은 perception, prediction, planning 사이에 사람이 설계한 intermediate interface가 많다. 이 interface들이 늘어나면 정보 손실이나 오류 전파가 생길 수 있다.

shared world representation은 여러 task가 같은 장면 표현을 공유하게 하여 수작업으로 이어 붙인 중간 표현에 덜 의존하게 한다.

답변: manually stitched intermediate interfaces에 덜 의존하고, 여러 task가 같은 representation을 공유하기 위해서다.

</details>

## 4. 20260605 (1): Imitation Learning과 DAggER

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | Imitation learning 매력 | expert demonstration으로 비싼 trial-and-error를 줄임 |
| Q2 | Behavioral Cloning | expert trajectory를 observation-to-action supervised learning으로 학습 |
| Q3 | ordinary supervised learning과 차이 | 현재 행동이 다음 state와 미래 입력 분포를 바꿈 |
| Q4 | DAggER | learner 방문 상태를 모으고 expert label을 다시 붙여 aggregate/retrain |

<details>
<summary>Q1. 로봇 학습에서 imitation learning이 매력적인 이유는 무엇인가?</summary>

풀이과정:

실제 로봇에서 trial-and-error는 비싸고 느리며 위험할 수 있다. 강화학습처럼 수많은 시도를 실제 환경에서 반복하기 어렵다.

imitation learning은 expert demonstration을 활용해 처음부터 좋은 행동 분포를 학습하게 해 준다. 따라서 시행착오 비용을 줄일 수 있다.

답변: expert demonstration을 바로 사용할 수 있어 비싸고 느린 trial-and-error를 줄일 수 있기 때문이다.

</details>

<details>
<summary>Q2. Behavioral Cloning은 어떻게 설명해야 하는가?</summary>

풀이과정:

Behavioral Cloning은 expert가 보여 준 trajectory를 데이터셋으로 보고, observation에서 action을 예측하는 supervised learning 문제로 바꾼다.

$$
\pi(a \mid o)
$$

즉 입력은 observation이고 label은 expert action이다. reward만 보고 배우는 RL과는 다르다.

답변: expert trajectory를 observation-to-action supervised learning으로 배우는 방법이다.

</details>

<details>
<summary>Q3. Imitation learning이 ordinary supervised learning과 다른 이유는 무엇인가?</summary>

풀이과정:

일반 supervised learning에서는 모델의 예측이 다음 입력 데이터 분포를 바꾸지 않는 경우가 많다. 하지만 robot policy는 현재 action으로 환경을 바꾼다.

잘못된 action 하나가 다음 state를 바꾸고, 그 결과 학습 때 보지 못한 입력 분포로 들어갈 수 있다. 이것이 covariate shift 또는 compounding error 문제다.

답변: 현재 행동이 다음 state를 바꾸어 미래 입력 분포 자체가 달라질 수 있기 때문이다.

</details>

<details>
<summary>Q4. DAggER의 핵심 아이디어는 무엇인가?</summary>

풀이과정:

DAggER는 Dataset Aggregation의 약자다. 단순히 expert demonstration만 더 모으는 것이 아니라, learner가 실제로 방문한 state를 모은 뒤 그 state에 대해 expert가 다시 label을 달아준다.

그렇게 모은 데이터를 기존 데이터와 합쳐 다시 학습한다. 이 과정은 learner가 test-time에 마주칠 state distribution에 더 가까운 데이터를 만들기 위한 방법이다.

답변: learner가 방문한 state를 모으고, expert label을 다시 붙인 뒤 aggregate/retrain하는 방법이다.

</details>

## 5. 20260605 (2): Robotics Scaling, VLA, Embodied AI

### 핵심 정답 키워드

| 문항 | 문제 유형 | 정답 키워드 |
|---:|---|---|
| Q1 | AI scaling frontier | 언어모델의 대규모 학습 흐름이 로보틱스로 이어질 수 있음 |
| Q2 | VLA | vision과 language 이해를 바탕으로 action을 출력하는 robot backbone |
| Q3 | ego-video 중요성 | physical interaction, dynamics, affordance 단서 |
| Q4 | world model + action + physical RL | pre-trained 기반 모델 위에 action 적응과 실제 환경 학습을 더함 |

<details>
<summary>Q1. 로보틱스를 AI scaling frontier로 보는 이유는 무엇인가?</summary>

풀이과정:

언어모델은 대규모 데이터와 모델 scale을 통해 성능이 크게 향상되었다. 로보틱스에서도 비슷하게 대규모 데이터, foundation model, 범용 표현 학습이 중요해지고 있다.

따라서 로보틱스는 언어모델과 완전히 무관한 문제가 아니라, 대규모 학습의 흐름이 이어질 수 있는 다음 frontier로 볼 수 있다.

답변: 언어모델에서 성공한 대규모 학습의 흐름이 로보틱스에도 이어질 수 있다고 보기 때문이다.

</details>

<details>
<summary>Q2. VLA는 어떻게 이해해야 하는가?</summary>

풀이과정:

VLA는 Vision-Language-Action의 약자다. 이미지를 보고, 언어 지시를 이해하고, 실제 행동을 출력하는 구조를 말한다.

핵심은 vision과 language를 따로 처리하는 데서 끝나지 않고, action까지 연결한다는 점이다.

답변: vision과 language 이해를 바탕으로 action을 출력하는 로봇용 backbone이다.

</details>

<details>
<summary>Q3. 인터넷 규모의 video나 ego-video가 embodied AI에서 중요한 이유는 무엇인가?</summary>

풀이과정:

ego-video와 대규모 비디오는 사람이 물리 세계와 상호작용하는 장면을 많이 담고 있다. 여기에는 물체를 잡고, 움직이고, 놓고, 여는 과정에서 생기는 dynamics와 affordance 단서가 포함된다.

모든 비디오에 정답 action label이 완벽히 붙어 있기 때문이 아니다. 중요한 것은 물리 세계의 상호작용 패턴을 대규모로 관찰할 수 있다는 점이다.

답변: 물리 세계의 상호작용, dynamics, affordance에 대한 단서를 대규모로 담고 있기 때문이다.

</details>

<details>
<summary>Q4. World modeling, action fine-tuning, physical RL을 하나의 흐름으로 묶으면?</summary>

풀이과정:

로보틱스에서는 먼저 대규모 비디오 기반 world model이나 foundation model을 통해 일반적인 세계 이해를 만들 수 있다. 이후 실제 robot action 데이터에 맞춰 fine-tuning하고, 마지막으로 physical RL을 통해 실제 환경에서 성능을 조정할 수 있다.

핵심은 rule engineering만 늘리는 것이 아니라, pre-training된 기반 모델 위에 action 적응과 실제 환경 학습을 더한다는 점이다.

답변: 로보틱스도 pre-training된 기반 모델 위에 action 적응과 실제 환경 학습을 더해 발전할 수 있다는 설명이 적절하다.

</details>

## 마지막 핵심 정리

| 구분 | 꼭 기억할 문장 |
|---|---|
| LLM | 다음 token 예측을 반복해 문장을 생성한다. |
| MoE | token별로 필요한 expert만 켜서 큰 모델을 효율적으로 쓴다. |
| Beam vs Greedy | beam은 여러 후보 경로를 유지하고, greedy는 매 순간 하나만 고른다. |
| Modular Driving | 단계별 구조는 해석 가능하지만 앞단 오류가 뒤로 전파될 수 있다. |
| Tesla Representation | object list보다 occupancy/shared world representation이 중요하다. |
| Imitation Learning | expert 행동을 따라 배우지만 state distribution shift를 조심해야 한다. |
| DAggER | learner가 방문한 state에 expert label을 다시 붙여 데이터 분포를 보정한다. |
| VLA | vision과 language를 action으로 연결하는 로봇용 backbone이다. |

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/assignment/aix/aix-quiz-20260521.pdf" | relative_url }}" target="_blank" rel="noopener">AIX Quiz 20260521 PDF</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/aix/aix-quiz-20260602.pdf" | relative_url }}" target="_blank" rel="noopener">AIX Quiz 20260602 PDF</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/aix/aix-quiz-20260604.pdf" | relative_url }}" target="_blank" rel="noopener">AIX Quiz 20260604 PDF</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/aix/aix-quiz-20260605-1.pdf" | relative_url }}" target="_blank" rel="noopener">AIX Quiz 20260605 (1) PDF</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/aix/aix-quiz-20260605-2.pdf" | relative_url }}" target="_blank" rel="noopener">AIX Quiz 20260605 (2) PDF</a></li>
</ul>
