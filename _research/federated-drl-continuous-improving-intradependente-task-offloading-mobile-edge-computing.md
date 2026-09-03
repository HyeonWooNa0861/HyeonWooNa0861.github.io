---
layout: default
date: 2026-08-19 14:02:37 +0900
title: "Federated DRL Offloading"
topic: "Federated learning for dependency-aware MEC offloading"
order: 69
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Federated reinforcement learning"
  - "Task call graph"
  - "Dependency-aware offloading"
  - "Mobile edge computing"
---

# Federated Deep Reinforcement Learning for Continuous Improving Intradependente Task Offloading in Mobile Edge Computing Network

Source PDF: `federated-drl-continuous-improving-intradependente-task-offloading-mobile-edge-computing.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Federated Deep Reinforcement Learning for Continuous Improving Intradependente Task Offloading in Mobile Edge Computing Network |
| 문서 유형 | Author research idea, 2 pages |
| 저자 | Iman Rahmati |
| 공개 시점 | 2024 |
| 주제 | Federated learning for dependency-aware MEC offloading |
| 제안 방향 | Task call graph representation with federated Actor-Critic or federated D3QN |

## Source Status

이 자료는 구현과 실험을 완료한 논문이 아니라 저자가 공개한 2쪽 분량의 `Research Idea` 문서다. 원제의 `Intradependente` 표기는 출처에 적힌 형태를 그대로 보존했다. 아래 해설은 federated DRL과 task dependency를 결합하려는 연구 설계를 정리하며, 성능이나 privacy가 검증되었다고 해석하지 않는다.

## 한 줄 요약

이 연구 아이디어는 task call graph로 작업 내부 종속성을 표현하고, 여러 MEC 장치가 원시 데이터를 공유하지 않은 채 federated DRL 모델을 공동 개선하는 오프로딩 구조를 제안한다.

## 핵심 내용

서로 의존하는 subtask를 독립 작업처럼 offload하면 precedence, critical path와 중간 데이터 전송 비용을 놓치게 된다. 이 연구 아이디어는 task call graph로 내부 종속성을 표현하고, 각 장치가 local observation과 trajectory로 Actor-Critic 또는 D3QN 계열 policy를 학습하는 구조를 제안한다.

로컬 model update를 federated aggregation으로 결합하면 원시 task data를 중앙에 모으지 않으면서 여러 장치의 경험을 global policy에 반영할 수 있다. 다만 공개 자료는 2쪽의 연구 제안으로 graph encoder, aggregation, reward와 실험 결과를 제시하지 않으므로, 의의는 지속 적응형 오프로딩의 설계 방향에 있고 성능·privacy 효과는 향후 검증 대상이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Task dependency | 서로 선후관계가 있는 subtask를 독립 작업처럼 다루면 무엇이 깨지는가? |
| 2 | Local learning | 각 장치는 어떤 경험으로 자신의 offloading policy를 학습하는가? |
| 3 | Federated aggregation | 서로 다른 로컬 업데이트를 어떻게 하나의 global policy로 결합하는가? |
| 4 | Continuous improvement | 새 장치와 새로운 workload가 들어올 때 모델을 어떻게 지속적으로 갱신하는가? |
| 5 | Validation | latency 이득, 통신 비용, heterogeneity와 privacy risk를 어떻게 함께 평가하는가? |

## 한국어 번역형 해설

### 독립 작업 가정의 문제

많은 offloading 모델은 각 task를 서로 독립적인 원자 단위로 본다. 그러나 실제 application은 하나의 함수가 다른 함수의 출력을 기다리거나, 여러 branch가 합쳐진 뒤 다음 stage가 실행되는 구조를 가진다. 선행 subtask의 실행 위치가 바뀌면 후속 subtask의 시작 시각뿐 아니라 intermediate data transmission cost도 달라진다.

문서는 이를 task call graph로 표현할 것을 제안한다. Node는 subtask, directed edge는 호출 또는 precedence relation, node feature는 computation demand와 input size, edge feature는 intermediate data size로 구성할 수 있다. 이 표현을 사용하면 offloading decision은 개별 task의 local/edge 선택이 아니라 graph 전체의 critical path와 communication cut을 고려하는 문제가 된다.

### Federated DRL 구조

각 mobile device 또는 edge entity는 자신의 local observation과 trajectory로 DRL policy를 학습한다. 일정한 round마다 model update를 aggregation server로 보내고, 서버는 이를 결합한 global model을 참여자에게 다시 배포한다. 원시 task data와 trajectory를 중앙에 모으지 않는다는 점이 centralized training과의 차이다.

| 구성 요소 | 역할 | 설계 질문 |
|---|---|---|
| Local agent | 자신의 channel, queue, task graph로 policy update 수행 | 장치별 observation과 action space가 같은가? |
| Aggregation server | local model update를 global model로 결합 | sample 수, staleness, device reliability를 어떻게 가중하는가? |
| Global policy | 공통 offloading knowledge 제공 | 서로 다른 hardware와 workload에도 하나의 policy가 유효한가? |
| Personalization layer | 장치별 특성에 맞게 global model 조정 | global convergence와 local performance를 어떻게 균형화하는가? |

문서가 제시한 후보는 federated Actor-Critic과 federated D3QN이다. Actor-Critic은 policy와 value estimation을 분리해 stochastic 또는 hybrid decision으로 확장하기 좋고, D3QN은 discrete offloading destination을 다루면서 value와 advantage를 분리하고 overestimation을 줄이는 데 적합하다. 다만 문서는 구체적인 aggregation rule이나 graph encoder를 확정하지 않는다.

### 지속적 개선의 의미

이 아이디어에서 `continuous improving`은 새 장치가 참여할 때마다 모든 경험을 중앙에 다시 모으는 것이 아니라, 각 장치가 축적한 local experience를 이용해 global offloading model을 반복적으로 보완한다는 의미에 가깝다. 이를 실제 continual learning으로 만들려면 다음 문제가 추가된다.

- 오래된 workload를 잊는 catastrophic forgetting을 어떻게 막을 것인가?
- 장치별 non-IID task distribution이 global model을 한쪽으로 치우치게 하지 않는가?
- 느리거나 간헐적으로 연결되는 client의 stale update를 언제 수용할 것인가?
- 새로운 task graph 크기와 구조가 training distribution을 벗어나도 policy가 작동하는가?

### Privacy와 통신 비용을 함께 보기

원시 데이터를 보내지 않는 federated learning은 data locality를 높이지만 privacy를 자동으로 보장하지는 않는다. Gradient나 model update에서도 정보가 추론될 수 있고, malicious client가 poisoned update를 보낼 수도 있다. 따라서 문서가 말하는 privacy-preserving 방향을 실제 시스템 주장으로 만들려면 secure aggregation, differential privacy, robust aggregation과 threat model이 필요하다.

또한 model update 전송은 MEC wireless resource를 사용한다. Offloading latency를 줄이기 위한 학습이 지나치게 많은 aggregation traffic을 만들면 순이익이 사라질 수 있으므로, 통신 round와 model compression도 목적함수에 들어가야 한다.

### 평가 설계

| 평가 축 | 권장 지표 | 필요한 비교군 |
|---|---|---|
| Offloading quality | makespan, mean latency, deadline success, energy | local-only, edge-only, graph heuristic |
| Dependency handling | critical-path delay, intermediate transfer volume | dependency-unaware DRL |
| Learning quality | convergence round, return, adaptation after new client | centralized DRL, independent DRL |
| Federation cost | bytes per round, active clients, wall-clock time | fixed-period and adaptive aggregation |
| Heterogeneity | performance by device class and workload skew | FedAvg, heterogeneity-aware aggregation |
| Privacy and robustness | attack success, utility under protection | no protection, secure or robust variants |

## 핵심 기여와 해석 포인트

- Offloading model에 task call graph를 도입해 task 내부 종속성을 명시적으로 다루려 한다.
- 여러 장치의 경험을 global policy로 결합하면서 원시 데이터의 중앙 수집을 피하는 방향을 제안한다.
- 새 장치가 들어오는 MEC 환경을 일회성 학습이 아니라 지속적 model improvement 문제로 본다.
- 현재 자료에는 aggregation algorithm, graph encoding, reward, 실험 결과가 없으므로 특정 federated DRL 기법의 우수성을 입증한 논문으로 인용하면 안 된다.

## 검증 과제와 확장 방향

첫 번째 과제는 task graph와 policy network의 연결 방식이다. Graph neural network 또는 DAG sequence encoder를 사용해 graph size가 달라도 공유 가능한 representation을 만들고, precedence constraint를 action mask로 적용하면 잘못된 실행 순서를 줄일 수 있다.

두 번째 과제는 non-IID와 system heterogeneity다. FedProx, clustered federation 또는 personalized head를 비교하고, client sampling과 asynchronous aggregation으로 느린 장치의 영향을 측정해야 한다. 세 번째는 privacy와 poisoning이다. Secure aggregation과 robust aggregation을 별도 layer로 적용하되 정확도와 통신량 손실을 함께 보고해야 한다. 이러한 검증을 통과하면 inter-edge collaboration과 multi-cluster federation으로 확장할 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/federated-drl-continuous-improving-intradependente-task-offloading-mobile-edge-computing/federated-drl-continuous-improving-intradependente-task-offloading-mobile-edge-computing.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://imanrht.github.io/assets/FederatedDRL.pdf" target="_blank" rel="noopener">Author-provided research idea PDF</a></li>
</ul>
