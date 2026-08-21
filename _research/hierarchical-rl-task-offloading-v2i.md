---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Hierarchical V2I Offloading"
topic: "Hierarchical reinforcement learning for V2I task offloading"
order: 57
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Hierarchical RL"
  - "V2I"
  - "Task offloading"
  - "Vehicular networks"
---

# Hierarchical Reinforcement Learning Empowered Task Offloading in V2I Networks

Source PDF: `hierarchical-rl-task-offloading-v2i.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Hierarchical Reinforcement Learning Empowered Task Offloading in V2I Networks |
| 출처 | arXiv:2405.11352v1, 2024; current arXiv record withdrawn on 2025-12-04 |
| DOI | 10.48550/arXiv.2405.11352 |
| 저자 | Xinyu You, Haojie Yan, Yuedong Xu, Lifeng Wang, Liangui Dai |
| 주제 | Hierarchical reinforcement learning for V2I task offloading |
| 핵심 방법 | DHVO: GAT-based DAG embedding with parameterized hierarchical DRL |

## Source Status

이 글은 로컬에 보관된 arXiv v1 PDF(2024-05-18)를 기준으로 한 해설이다. 공식 arXiv record는 2025-12-04 v2에서 withdrawn 상태이며, 현재 withdrawn version에는 PDF가 제공되지 않는다. 따라서 아래 내용은 "논문 v1이 주장한 방법과 실험"으로 읽어야 하고, peer-reviewed publication이나 최신 공식 version의 확정 결과로 해석하면 안 된다.

## 한 줄 요약

이 논문 v1은 V2I edge offloading에서 application을 interdependent subtask DAG로 모델링하고, GAT로 dependency를 embedding한 뒤 parameterized hierarchical DRL로 subtask 선택, local/offload 선택, CPU frequency 또는 transmit power 결정을 함께 다루는 DHVO를 제안한다.

## 한국어 번역형 해설

### 문제 배경

Vehicle-to-infrastructure network에서는 차량이 road-side unit에 computation task를 offload해 latency와 energy consumption을 줄일 수 있다. 대상 application은 driving assistance, augmented reality, image processing, speech recognition처럼 deadline이 강하고 계산량이 큰 작업이다. 차량 단말은 local computing capacity와 battery가 제한되어 있으므로, 모든 task를 local에서 실행하면 지연과 에너지가 커진다.

논문 v1이 기존 연구와 다르게 잡은 지점은 두 가지다. 첫째, application을 하나의 atomic task가 아니라 여러 dependent subtask로 이루어진 DAG로 본다. 둘째, offloading action이 discrete decision과 continuous resource parameter를 함께 가진다고 본다. 즉 "어떤 subtask를 실행할지", "local과 edge 중 어디서 실행할지", "local CPU frequency 또는 transmit power를 얼마로 둘지"를 동시에 결정해야 한다.

### 시스템 모델

RSU는 highway를 따라 배치되고, 각 RSU는 coverage length \(L\) 안의 차량을 지원한다. 차량 속도 \(v\)는 시간에 따라 변하며, task가 RSU coverage 안에서 끝나지 않으면 migration cost가 발생할 수 있다.

Application은 DAG \(G=(V,E)\)로 표현된다. Node는 subtask이고 edge는 precedence constraint다. 각 subtask \(i\)는 \(\phi_i=(DI_i,DO_i,C_i)\)로 나타난다. \(DI_i\)는 input data, \(DO_i\)는 output data, \(C_i\)는 required CPU cycles다.

| 실행 방식 | 비용 구성 |
|---|---|
| Local execution | CPU frequency \(f_i\), local execution time, local energy consumption |
| Edge offloading | upload delay, edge execution delay, download delay, transmit energy, edge service fee |
| Migration | RSU handover 전에 task가 끝나지 않을 때 migration fee와 추가 delay 발생 |
| Dependency | subtask는 immediate predecessor가 끝난 뒤 시작 가능 |

Objective는 time, energy, edge service cost를 결합한 TESC를 최소화하는 것이다. Weight는 \(\beta_1,\beta_2,\beta_3\)로 두며 합은 1이다. 논문은 offloading vector \(K\), CPU frequency \(F\), transmit power \(P\)를 함께 최적화해야 하므로 문제가 mixed-integer nonlinear programming이고 nonconvex, NP-hard라고 설명한다.

### 제안 방법: DHVO

DHVO는 graph attention network와 parameterized DRL을 결합한다.

### DAG embedding with GAT

Input node feature에는 input data, output data, required cycles, execution flag, coordinate, remaining task count, 최근 5초 speed vector가 포함된다. GAT는 attention mechanism으로 predecessor/successor dependency의 중요도를 다르게 반영한다. 논문은 task 수가 대체로 20개 이하라는 전제에서 one-layer GAT로도 dependency extraction이 충분하다고 본다.

### Hierarchical hybrid action

Action은 세 계층으로 분해된다.

| 계층 | 결정 |
|---|---|
| Layer 1 | 실행할 subtask \(y_t\) 선택 |
| Layer 2 | local execution 또는 edge offloading \(k_t\) 선택 |
| Layer 3 | local이면 CPU frequency \(f_t\), edge이면 transmit power \(p_t\) 선택 |

Flat DDPG처럼 모든 action을 하나로 묶으면 dependency 때문에 invalid action이 많아지고, penalty 기반 학습은 sample efficiency가 낮아진다. DHVO는 parameterized normalized advantage function 구조를 사용해 discrete action과 continuous parameter를 함께 다룬다. \(Q(s,a_d,a_c)=V(s,a_d)+A(s,a_d,a_c)\) 형태로 discrete value와 continuous advantage를 분리하고, continuous advantage는 positive-definite quadratic form으로 둔다. Discrete action은 \(\epsilon\)-greedy, continuous exploration은 Ornstein-Uhlenbeck noise를 사용한다.

### Learning loop

Algorithm 1은 GNN과 parameterized Q network, target network, replay buffer를 초기화한 뒤 반복한다. Agent는 현재 DAG state에서 hierarchical action \((y_t,k_t=0,f_t)\) 또는 \((y_t,k_t=1,p_t)\)를 고르고, immediate TESC의 음수를 reward로 저장한다. Batch update에서는 target \(z_i=r_i+\gamma\max_{a_d}V'(s_{i+1},a_d)\)를 만들고 MSE loss로 GNN과 parameter network를 함께 갱신한다.

### 실험 설정

Simulation은 real vehicle speed dataset인 CPIPC를 사용하며, 7일 동안 1초 granularity로 수집된 speed trace에서 네 개의 100초 trajectory를 사용한다. 각 episode는 20개 application을 실행하고, 각 application은 8 to 12개 subtask를 가진다. Replay buffer가 500 transition을 넘은 뒤 training을 시작하며 batch size는 256이다.

| 항목 | 값 |
|---|---|
| RSU coverage \(L\) | 200 m |
| Time slot \(\Delta_t\) | 1 s |
| Number of subtasks \(N\) | 8 to 12 |
| Input data \(DI\) | 2.5 to 3.5 MByte |
| Output data \(DO\) | 2.5 to 3.5 MByte |
| Required computation \(C\) | 800 to 1200 Mcycles |
| Bandwidth \(W\) | 2 MHz |
| Max local computing \(f^l_{max}\) | \(10^8\) cycles/s |
| Edge server computing \(f^e\) | \(10^9\) cycles/s |
| Max transmit power \(p^l_{max}\) | 200 mW |
| Resource price \(u_r\) | 0.1 USD/Mcycles |
| Migration price \(u_m\) | 2 USD/Mcycles |
| TESC weights | \((0.33,0.33,0.33)\) |

Neural network setting은 GAT attention heads 2, feature dimension per head 6, parameterized network hidden layer 128, discount factor 0.99, learning rate 0.01, soft update coefficient 0.1, ReLU, Adam, maximum episodes 20이다. Baseline은 ALE, AO, GOE, DQN10이다.

### 핵심 결과

논문 v1은 DHVO neural network가 14 episode 안에 수렴한다고 보고한다. One-batch training time은 1.58초, inference time은 0.0018초로 제시된다. 이 수치는 online decision 자체는 충분히 빠르지만, training은 offline 또는 controller-side update로 보는 것이 자연스럽다는 뜻이다.

결과 해석의 핵심은 migration risk다. GOE처럼 greedy하게 edge offloading을 선호하는 방법은 real speed variation 때문에 RSU coverage를 벗어나 migration penalty를 크게 받을 수 있다. ALE처럼 local execution에 치우친 방법은 migration은 피하지만 local time/energy cost가 커진다. DHVO는 speed vector와 DAG dependency를 state에 넣고, local/edge 및 resource parameter를 함께 선택해 TESC를 낮춘다고 주장한다.

| 실험 축 | 논문 v1의 주장 |
|---|---|
| Required computation 증가 | DHVO가 ALE, AO, GOE, DQN10보다 낮은 TESC를 유지 |
| Input/output data 증가 | data transfer cost가 커져도 DHVO가 offloading/local balance로 overhead를 줄임 |
| Computation price 변화 | price가 올라갈수록 offloading-heavy baseline의 cost가 커지고, DHVO는 상대적으로 완만 |
| Migration price 변화 | AO/GOE가 migration cost에 민감하고, DHVO는 speed-aware decision으로 migration을 줄임 |
| Ablation | DHVO가 PNAF, GDQN2, GDQN5, GDQN10보다 hierarchical hybrid action 처리에서 유리하다고 보고 |

정량 표가 모든 figure 값으로 제공되지는 않기 때문에, 공개 글에서는 정확한 figure reading 없이 논문이 명시한 trend 중심으로 해석한다.

### 논문이 말한 것과 해석을 구분하기

| 구분 | 내용 |
|---|---|
| 논문 v1 주장 | DHVO는 DAG dependency와 hierarchical hybrid action을 함께 처리해 V2I offloading overhead를 줄인다. |
| 근거 | GAT embedding, parameterized DRL, CPIPC speed trace simulation, baseline 비교를 제시한다. |
| 해석 | 핵심 아이디어는 "차량 속도와 DAG dependency를 같이 보면서 migration risk를 줄이는 offloading controller"다. |
| 주의점 | 공식 arXiv record가 withdrawn이므로, 이 결과는 v1 preprint의 주장이지 검증 완료된 최신 publication claim이 아니다. |

### 한계와 해결 방향

가장 큰 한계는 publication status다. 현재 공식 arXiv record는 2025-12-04에 withdrawn 되었고, comments에는 저자 측이 더 이상 development나 submission을 진행하지 않겠다고 밝힌다. 따라서 이 글의 활용 가치는 "아이디어와 모델 구조를 공부하는 reference"에 두어야 한다. 해결 방향은 reproducible code, updated dataset split, peer-reviewed revision, 또는 유사한 published follow-up과의 교차 검증이다.

모델 측면에서는 single-vehicle 중심 simulation과 제한된 traffic/channel parameter가 현실성을 제한한다. 실제 V2I 서비스로 확장하려면 multi-vehicle competition, RSU queueing, handover failure, packet loss, broader mobility trace를 포함해야 한다. 방법적으로는 multi-agent hierarchical RL, uncertainty-aware speed prediction, migration-risk-constrained reward, adaptive option discovery가 자연스러운 확장 방향이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/hierarchical-rl-task-offloading-v2i/hierarchical-rl-task-offloading-v2i.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF v1</a></li>
  <li><a href="https://arxiv.org/abs/2405.11352" target="_blank" rel="noopener">arXiv:2405.11352 official record</a></li>
  <li><a href="https://doi.org/10.48550/arXiv.2405.11352" target="_blank" rel="noopener">DOI: 10.48550/arXiv.2405.11352</a></li>
</ul>
