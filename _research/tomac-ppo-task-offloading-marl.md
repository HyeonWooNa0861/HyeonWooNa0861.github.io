---
layout: default
title: "TOMAC-PPO"
topic: "Multi-agent PPO for MEC task offloading and resource allocation"
order: 65
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "TOMAC-PPO"
  - "MARL"
  - "MEC"
  - "resource allocation"
  - "task offloading"
---

# A Task Offloading and Resource Allocation Strategy Based on Multi-Agent Reinforcement Learning in Mobile Edge Computing

Source PDF: `tomac-ppo-task-offloading-marl.pdf`

## Paper Information

| Field | Detail |
|---|---|
| Title | A Task Offloading and Resource Allocation Strategy Based on Multi-Agent Reinforcement Learning in Mobile Edge Computing |
| Authors | Guiwen Jiang, Rongxi Huang, Zhiming Bao, Gaocai Wang |
| Venue | Future Internet 16(9):333, 2024 |
| DOI | <a href="https://doi.org/10.3390/FI16090333" target="_blank" rel="noopener">10.3390/FI16090333</a> |
| Topic | Multi-agent reinforcement learning for MEC task offloading and resource allocation |

## 핵심 내용

이 논문은 cloud-edge collaborative MEC 환경에서 task offloading, resource scheduling, delay, energy, task drop을 하나의 joint optimization 문제로 묶고, edge server들을 agent로 둔 task-oriented multi-agent reinforcement learning 전략인 TOMAC-PPO를 제안한다. 단순히 "PPO를 MEC에 적용했다"는 수준이 아니라, task queue, wireless/wired transmission, node failure, delayed reward, task priority까지 포함해 offloading decision이 실제 service cost에 미치는 영향을 모델링한 점이 핵심이다.

## 논문 전개

| 단계 | 내용 | 읽을 포인트 |
|---:|---|---|
| 1 | MEC 문제 설정 | IoT device 증가, local computing 한계, edge/cloud 협업 필요성을 배경으로 둔다. |
| 2 | System model | User layer, edge layer, cloud layer와 queue, delay, energy, packet drop을 정의한다. |
| 3 | Task-oriented MARL | 동일한 time slot 대신 task event 중심의 dynamic/parallel slot으로 MDP를 구성한다. |
| 4 | TOMAC-PPO | Actor-Critic 기반 multi-agent PPO에 Transformer memory/prediction을 결합한다. |
| 5 | Experiments | TOMAC-A2C, TO-A3C, CCP, LC와 average cost, delay, energy, drop rate를 비교한다. |

## 한국어 번역형 해설

### 배경과 문제의식

저자들은 IoT device가 2025년에 309억 개 규모로 증가하고, 생성 데이터가 175 zettabytes를 넘을 수 있다는 전망을 출발점으로 삼는다. 이런 환경에서 모든 task를 device local이나 cloud로만 처리하면 latency와 energy cost가 커지고, edge server를 쓰더라도 단일 agent나 centralized decision만으로는 user mobility, edge failure, queue congestion, delayed reward를 충분히 반영하기 어렵다.

논문의 문제의식은 다음 세 가지로 정리된다.

- 기존 single-agent RL offloading은 전체 decision space가 커질수록 robustness와 convergence가 약해진다.
- Edge node는 다른 node의 상태를 즉시 완전하게 알기 어렵기 때문에 information synchronization과 delayed reward 처리가 필요하다.
- Task마다 latency, energy, loss tolerance가 다르므로 모든 task를 같은 reward로 다루면 service quality를 잘못 최적화할 수 있다.

### 모델과 기호

System model은 user, edge, cloud의 3계층으로 구성된다. User는 이동하며 task를 생성하고, edge node는 wireless base station과 edge server를 포함하며, cloud는 edge에서 감당하기 어려운 computation을 처리한다. Queue model은 user-side queue/cache/compute/transmission queue와 edge-side wired transmission/compute/buffer/result queue를 나누어 task가 어디에서 지연되는지 추적한다.

Task drop은 active queue management로 표현된다. Queue threshold `th_min`, `th_max`와 random drop probability `p_drop`을 두어, congestion이 커질수록 task가 버려질 수 있음을 모델에 반영한다. Wireless link는 bandwidth `B`, service radius `r`, bandwidth weight `bf_{i,j}`, transmit power `P`, channel gain `G_{i,j}`, Gaussian noise `\sigma^2`를 사용하고, wired edge-cloud path는 `C_fiber`, `V_fiber`, line fault probability `p_fiber`, repair time `T_repair`를 사용한다.

Task class도 reward를 바꾼다. High-priority task는 energy term을 제외해 `\phi_2=0`으로 두고, critical task는 drop만 보도록 `\phi_1=\phi_2=0`으로 둔다. Low-priority task는 delay term을 제외해 `\phi_1=0`으로 두며, routine task는 delay, energy, drop을 모두 고려한다. 이 분류는 "무엇을 빠르게 처리할 것인가"와 "무엇을 버리지 않을 것인가"를 reward level에서 분리한다.

### TOMAC-PPO의 방법

TOMAC-PPO는 edge server를 agent로 보고, 각 agent가 local observation과 synchronization message를 바탕으로 offloading/scheduling action을 선택하게 한다. Markov decision process는 fixed time slot 대신 task arrival과 processing event를 중심으로 구성된다. 이 설계는 병렬 task 처리와 delayed reward를 더 직접적으로 반영하려는 선택이다.

Policy update는 PPO의 clipped objective `L^{CLIP}(\theta)`를 사용한다. 논문은 policy network를 gradient ascent로 갱신하고, value network와 target network update ratio `\sigma`를 함께 둔다. Algorithm 1의 주요 input은 training round `e_max`, pruning parameter `\varsigma`, learning rate `\alpha`, discount factor `\gamma`, target update ratio `\sigma`이며, output은 각 agent의 policy `\pi(a|s;\theta^j)`이다. 저자들은 알고리즘 복잡도를 agent 수 `n`과 training round `e_max`에 대해 `O(n e_max)`로 제시한다.

Transformer는 network state의 memory와 prediction을 보강하는 역할로 결합된다. 여기서 논문 주장은 Transformer가 PPO 자체를 대체한다는 뜻이 아니라, partial observation과 synchronization delay가 있는 MEC 상태를 더 잘 요약하기 위한 auxiliary sequence modeling 장치라는 쪽에 가깝다.

### 실험과 결과

실험은 Python 기반 simulation과 real location data를 사용해 user longitude/latitude, CPU frequency, task type distribution을 반영한다. Baseline은 TOMAC-A2C, TO-A3C, CCP(cloud computing priority), LC(local computing)이며, metric은 average cost, service delay, energy consumption, task drop rate다. Task type probability는 `[0.2, 0.2, 0.2, 0.4]`로 설정된다.

논문이 강조하는 결과는 고부하와 failure rate가 증가하는 상황에서 TOMAC-PPO가 cost와 drop을 줄인다는 점이다. 같은 network load에서 average cost는 비교 scheme 대비 19.4%에서 66.6%까지 감소했다고 보고된다. 50명 user scenario에서 일부 baseline의 critical task drop rate가 62.5%까지 올라갈 때, TOMAC-PPO는 5.5% 수준으로 유지된다는 결과도 제시된다. Network failure rate가 커지면 edge path가 사실상 끊겨 local computing과 유사한 regime으로 수렴하기 때문에, 논문 결과는 "모든 장애 상황에서 무조건 우월"이 아니라 "edge가 부분적으로 살아 있는 고부하 환경에서 scheduling과 offloading 조합이 효과적"이라는 범위로 읽어야 한다.

### 논문 주장과 읽기 해석

| 구분 | 내용 |
|---|---|
| 논문 주장 | Task-oriented MARL과 PPO update가 MEC offloading의 convergence와 service cost를 개선한다. |
| 논문 주장 | Task priority별 reward 설계가 delay, energy, drop의 중요도를 다르게 반영한다. |
| 논문 주장 | Transformer를 결합한 TOMAC-PPO는 고부하와 link failure가 있는 환경에서 drop rate와 average cost를 낮춘다. |
| 읽기 해석 | 실험은 simulation 중심이므로 실제 carrier-grade MEC scheduler의 signaling overhead와 운영 제약은 별도로 검증해야 한다. |
| 읽기 해석 | 이 논문은 "centralized global optimizer"보다 "edge-local agent 간 synchronization"이 필요한 시나리오를 잘 보여준다. |

### 한계와 확장 방향

첫째, multi-agent system은 network scale이 커질수록 communication overhead와 non-stationarity가 커진다. 논문은 information synchronization protocol로 이 문제를 줄이려 하지만, large-scale MEC에서는 stale state가 남을 수 있다. 확장 방향은 graph neural network 기반 neighborhood communication, event-triggered synchronization, stale information-aware policy update를 결합하는 것이다.

둘째, simulation network가 비교적 단순하다. 실제 deployment에서는 UAV, connected vehicle, multi-operator edge, heterogeneous accelerator, cost-aware cloud billing이 함께 들어온다. 따라서 ns-3, OMNeT++, Simu5G 같은 network simulator나 trace-driven digital twin으로 failure, mobility, handover, backhaul congestion을 재검증할 필요가 있다.

셋째, reward 설계가 task priority를 반영하지만 safety constraint를 엄밀한 hard constraint로 보장하지는 않는다. Critical task에는 constrained RL, safe exploration, admission control을 함께 붙여 drop bound나 deadline violation probability를 직접 제한하는 확장이 자연스럽다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/tomac-ppo-task-offloading-marl/tomac-ppo-task-offloading-marl.pdf" | relative_url }}" target="_blank" rel="noopener">tomac-ppo-task-offloading-marl.pdf</a></li>
  <li><a href="https://doi.org/10.3390/FI16090333" target="_blank" rel="noopener">DOI: 10.3390/FI16090333</a></li>
  <li><a href="https://www.mdpi.com/1999-5903/16/9/333" target="_blank" rel="noopener">Publisher page: Future Internet 16(9):333</a></li>
</ul>
