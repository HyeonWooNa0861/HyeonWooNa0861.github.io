---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "UC Cell-Free Survey"
topic: "Survey of user-centric cell-free massive MIMO"
order: 67
major_topic: "Wireless Networks & Massive MIMO"
keywords:
  - "cell-free massive MIMO"
  - "user-centric networks"
  - "distributed APs"
  - "survey"
---

# User-centric Cell-free Massive MIMO Networks: A Survey of Opportunities, Challenges and Solutions

Source PDF: `user-centric-cell-free-massive-mimo-survey.pdf`

## Paper Information

| Field | Detail |
|---|---|
| Title | User-centric Cell-free Massive MIMO Networks: A Survey of Opportunities, Challenges and Solutions |
| Authors | Hussein A. Ammar, Raviraj Adve, Shahram Shahbazpanahi, Gary Boudreau, Kothapalli Venkata Srinivas |
| Venue | IEEE Communications Surveys & Tutorials 24(1):611-652, 2022 |
| DOI | <a href="https://doi.org/10.1109/COMST.2021.3135119" target="_blank" rel="noopener">10.1109/COMST.2021.3135119</a> |
| Topic | Survey of opportunities, challenges, and solutions for user-centric cell-free massive MIMO |

## 핵심 내용

이 survey는 user-centric cell-free massive MIMO를 future mobile network의 한 축으로 놓고, fronthaul, CSI estimation, serving cluster formation, resource allocation, latency, scalability를 체계적으로 정리한다. Traditional cellular network와의 핵심 차이는 user마다 serving DU(distributed unit) cluster가 정의된다는 점이며, 이 구조는 cell-edge를 제거하고 user를 자신의 serving cluster 중심에 놓는 방식으로 coverage uniformity와 reliability를 높이려 한다.

## 논문 전개

| 단계 | 내용 | 읽을 포인트 |
|---:|---|---|
| 1 | Motivation | Densification과 cell-free 구조가 왜 future 5G/B5G/6G 후보가 되는가? |
| 2 | Architecture | DU, CU, fronthaul, multiple CU, radio stripes, SDN 관리 구조를 정리한다. |
| 3 | Physical-layer challenges | CSI, pilot assignment, channel hardening, favorable propagation, mobility를 다룬다. |
| 4 | Resource allocation | Power, scheduling, serving cluster, spectral/energy efficiency, QoS를 비교한다. |
| 5 | Open problems | Latency, scalability, IRS, machine learning, uRLLC, MEC 결합 방향을 제시한다. |

## 한국어 번역형 해설

### 배경과 범위

논문은 "cell-free"라는 term이 2015년 이후 literature에서 본격적으로 등장했고, publication 수가 빠르게 증가했다는 흐름을 보여준다. Cell-free massive MIMO는 many distributed AP/DU가 users를 공동 서비스해 macro diversity와 interference management를 얻는 구조다. User-centric variant는 여기에 한 가지 practical constraint를 더한다. 모든 DU가 모든 user를 서비스하는 대신, 각 user에게 의미 있는 serving cluster만 구성한다.

Survey의 범위는 매우 넓다. 저자들은 286개 reference를 검토하고, fronthaul capacity, CSI estimation, serving cluster formation, resource allocation, delay, scalability 같은 physical-layer/deployment challenge를 표와 함께 정리한다. 또한 distributed SDN, radio stripes, millimeter wave, IRS, machine learning 같은 enabling technology도 함께 배치한다.

### Architecture: DU, CU, fronthaul

User-centric cell-free network는 DU가 radio access를 담당하고, CU(central unit)가 coordination과 data processing을 담당하는 구조로 설명된다. Single CU deployment는 연구 모델로 단순하지만, dense network에서는 fronthaul capacity와 processing delay가 병목이 될 수 있다. Survey는 multiple CU architecture가 hierarchical design을 통해 fronthaul traffic을 낮추고 local CU processing으로 delay를 줄일 수 있다고 설명한다.

Multiple CU 구조에서는 user가 서로 다른 CU에 속한 DU들로부터 서비스될 수 있기 때문에 coordination protocol이 필요하다. Distributed SDN은 DU-CU assignment, controller load balancing, failure handling을 동적으로 관리할 수 있는 후보로 제시된다. Radio stripes는 DU와 wiring을 deploy하기 쉬운 형태로 묶어 dense deployment를 가능하게 하는 hardware-side 방향으로 소개된다.

### Physical-layer challenges

CSI estimation은 user-centric cell-free에서 반복적으로 등장하는 병목이다. TDD reciprocity를 활용하더라도 pilot contamination, channel aging, mobility가 channel estimate를 흔든다. Survey는 pilot assignment, graph coloring, Hungarian algorithm, tabu search, learning-based assignment 같은 여러 방법을 정리한다. Channel hardening과 favorable propagation은 massive MIMO의 중요한 가정이지만, distributed/user-centric deployment에서는 co-located massive MIMO만큼 항상 강하게 성립하지 않을 수 있으므로 system-level 검증이 필요하다.

Serving cluster formation은 user-centric 구조를 cell-free massive MIMO와 구별하는 핵심이다. Cluster가 너무 크면 fronthaul과 computation load가 커지고, 너무 작으면 macro diversity와 interference mitigation 이득이 줄어든다. 따라서 cluster formation은 large-scale fading, user geometry, QoS, traffic load, mobility를 함께 고려해야 한다.

### Resource allocation과 QoS

Survey는 resource allocation을 power control, scheduling, beamforming, user association, cluster selection이 결합된 문제로 본다. Min-rate maximization은 fairness를 강하게 밀어 올리지만, feasibility와 iteration cost가 문제가 될 수 있다. Sum-rate maximization은 throughput에는 유리하지만 cell-edge 제거라는 user-centric 목표와 충돌할 수 있다. Energy efficiency는 단순히 transmit power만 볼 수 없고, dense DU deployment가 만드는 circuit power와 fronthaul power까지 고려해야 한다.

논문은 distributed approaches도 중요하게 다룬다. Game theory, interference pricing, auction, decomposition, PZF/PPZF, federated learning, DU-distributed/CU-distributed control 같은 방법이 scalability를 위해 검토된다. 특히 CU-distributed approach는 multiple CU의 중요성을 보여주는 방향으로 제시되며, centralized-only optimization이 large-scale deployment에서 그대로 유지되기 어렵다는 점을 시사한다.

### Latency, reliability, scalability

Survey가 명확히 짚는 공백은 latency다. uRLLC에서는 delay가 핵심 metric이지만, user-centric cell-free literature에서 delay-aware study는 상대적으로 부족하다고 평가한다. 관련 방향으로는 delay-aware BS discontinuous transmission, energy-harvesting user scheduling, queue state information(QSI)과 energy state information(ESI)을 포함한 MDP, HARQ-IR, finite blocklength coding, punctured scheduling, MEC 결합이 언급된다.

Synchronization도 deployment risk다. 여러 DU와 여러 CU가 동시에 user를 서비스하면 signal delivery delay와 inter-DU carrier frequency offset이 생긴다. OFDM cyclic prefix나 precision time protocol 같은 quasi-synchronization assumption이 사용될 수 있지만, user mobility와 multi-CU boundary에서는 timing, phase, data synchronization error가 rate와 reliability를 흔들 수 있다.

Scalability는 단순히 "더 많은 DU를 배치할 수 있는가"가 아니라, fronthaul load, CSI overhead, optimization iteration, controller failure, cluster re-formation을 포함한다. Survey는 scalability를 우선순위로 삼는 distributed resource allocation scheme이 아직 충분하지 않다고 보고, IRS-aided network와 machine learning을 후보 technology로 배치한다.

### 논문 주장과 읽기 해석

| 구분 | 내용 |
|---|---|
| 논문 주장 | User-centric cell-free massive MIMO는 cell-edge를 제거하고 macro diversity, connectivity, interference management를 개선할 수 있다. |
| 논문 주장 | Small-cell 대비 median 및 95%-likely spectral efficiency가 크게 개선된 prior result가 있으며, 일부 study는 uncorrelated/correlated shadow fading에서 five-fold 및 ten-fold improvement를 보고한다. |
| 논문 주장 | Fronthaul, CSI, serving cluster, resource allocation, delay, scalability가 deployment의 주요 challenge다. |
| 읽기 해석 | User-centric design의 의의는 cell-free ideal을 줄이는 것이 아니라, useful cooperation만 남겨 practical deployment로 옮기는 데 있다. |
| 읽기 해석 | 이 survey는 특정 algorithm의 우열보다 research map을 제공하는 글이므로, 개별 성능 수치는 각 reference의 model assumption을 함께 확인해야 한다. |

### 한계와 확장 방향

첫째, survey 시점상 이후의 6G-native AI-RAN, semantic communication, integrated sensing and communication, foundation-model-based network control까지 포괄하지는 못한다. 하지만 논문이 제시한 fronthaul, CSI, cluster formation, scalability 축은 여전히 후속 연구를 배치하는 기준점으로 유효하다.

둘째, multiple CU deployment는 practical하지만 protocol detail이 충분히 정리되어 있지 않다. 확장 방향은 distributed SDN controller, CU failure recovery, DU-CU reassignment, inter-CU handover를 포함한 management-plane design으로 이어진다.

셋째, latency와 mobility는 survey가 직접 부족하다고 지적한 영역이다. High-mobility user에서는 channel aging, pilot redesign, frequent serving-cluster reconstruction, synchronization이 함께 발생한다. uRLLC나 vehicular service를 목표로 할 때는 queue-aware scheduling, short-packet reliability, MEC offloading, HARQ policy를 cluster design과 함께 최적화해야 한다.

넷째, energy efficiency는 dense DU의 transmit power 절감과 circuit/fronthaul power 증가가 동시에 나타나는 trade-off다. 해결 방향은 AP sleep mode, energy harvesting, traffic-aware DU activation, area energy efficiency metric을 함께 사용하는 것이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/user-centric-cell-free-massive-mimo-survey/user-centric-cell-free-massive-mimo-survey.pdf" | relative_url }}" target="_blank" rel="noopener">user-centric-cell-free-massive-mimo-survey.pdf</a></li>
  <li><a href="https://doi.org/10.1109/COMST.2021.3135119" target="_blank" rel="noopener">DOI: 10.1109/COMST.2021.3135119</a></li>
</ul>
