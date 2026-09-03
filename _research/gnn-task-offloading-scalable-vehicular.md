---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "GNN Vehicular Offloading"
topic: "Scalable vehicular edge offloading with GNNs"
order: 55
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Vehicular edge computing"
  - "GNN"
  - "Task offloading"
  - "Scalability"
---

# Graph Neural Network-Based Task Offloading and Resource Allocation for Scalable Vehicular Networks

Source PDF: `gnn-task-offloading-scalable-vehicular.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Graph Neural Network-Based Task Offloading and Resource Allocation for Scalable Vehicular Networks |
| 출처 | IET Communications, 2025 |
| DOI | 10.1049/CMU2.70064 |
| 저자 | Menghan Shao, Rongqing Zhang, Liuqing Yang |
| 주제 | Scalable vehicular edge offloading with GNNs |
| 핵심 방법 | G-TORA: graph neural network assisted task offloading and resource allocation |

## 한 줄 요약

이 논문은 차량 수가 계속 바뀌는 vehicular edge network에서 fixed-size neural network 대신 graph neural network를 사용해 task vehicle과 service vehicle의 관계를 직접 표현하고, genetic algorithm으로 만든 label을 통해 빠른 online offloading decision을 학습한다.

## 핵심 내용

- **문제:** 차량 수가 변하는 vehicular network에서는 fixed-size neural network가 topology 변화와 service vehicle 관계를 일반화하기 어렵다.
- **방법:** G-TORA는 genetic algorithm으로 offline label을 만들고, task vehicle·service vehicle·wireless link를 graph로 표현한 GNN을 online surrogate로 사용한다.
- **결과:** GNN inference는 0.03초 미만이었고, 10개 task vehicle 조건에서 processing delay가 MLP보다 약 26%, OMAB보다 약 41% 낮았다.
- **의의:** 비싼 optimization은 offline으로 옮기고 graph-size 변화에 대응하는 GNN으로 online total delay를 낮춘다는 점이 핵심이다.

## 한국어 번역형 해설

### 문제 배경

지능형 차량은 image processing, navigation, cooperative perception처럼 계산량이 큰 task를 처리해야 하지만 onboard computing resource는 제한적이다. Cloud로 모두 보내면 backhaul과 long-distance delay가 커지고, road-side infrastructure만으로 처리하면 deployment cost와 coverage 문제가 생긴다. 논문은 근처 차량의 idle computing resource를 service vehicle로 활용하는 vehicular edge offloading을 대상으로 삼는다.

핵심 난점은 network size가 고정되어 있지 않다는 점이다. 기존 MLP나 DRL 모델은 입력 dimension을 맞추기 위해 padding이나 masking을 써야 하고, 차량 수가 늘어나면 generalization이 약해진다. 논문은 이 문제를 graph representation으로 바꾸어 task vehicle, service vehicle, wireless link를 node와 edge feature로 직접 넣는다.

### 시스템 모델

하나의 base station이 one-way road 구간을 관리하고, time slot마다 task vehicle과 service vehicle 상태를 수집한다. 각 time slot \(t\)에서 graph는 \(G_t=(V_t,E_t)\)로 표현된다. \(M_t\)개의 task vehicle과 \(N_t\)개의 service vehicle이 node가 되고, edge는 vehicle-to-vehicle communication state를 담는다.

| 요소 | 의미 |
|---|---|
| Task profile | \(\langle d_i,c_i,f_i\rangle\): task data size, required CPU cycles, local computing capacity |
| Service vehicle | \(f_j\): 제공 가능한 computing capacity |
| Edge feature | task vehicle과 service vehicle 사이의 transmission rate |
| Communication model | bandwidth, transmit power, channel gain, noise power를 사용한 Shannon rate |
| Offloading delay | transmission delay와 service vehicle execution delay의 합 |
| Return delay | output data가 input보다 작다는 가정으로 무시 |

Decision variable \(x_{i,j}^t\)는 task \(i\)가 local에서 실행되는지, 또는 service vehicle \(j\)에 offload되는지를 나타내는 binary assignment다. 목적은 response delay를 최소화하는 것이다. 각 task는 local 또는 하나의 service vehicle을 선택해야 하고, service vehicle resource capacity를 넘을 수 없다. 논문은 이 문제가 combinatorial offloading과 resource allocation이 결합된 NP-hard 문제라고 설명한다.

### 제안 방법: G-TORA

G-TORA는 세 단계로 구성된다.

1. Offline data preparation: 여러 network instance를 만들고 genetic algorithm으로 offloading label을 생성한다.
2. Supervised GNN training: graph instance와 GA label을 이용해 GNN을 학습한다.
3. Online inference: base station이 현재 graph를 입력하면 GNN이 빠르게 offloading decision을 출력한다.

Genetic algorithm은 chromosome으로 offloading assignment를 encoding하고, response delay의 inverse를 fitness로 사용한다. Roulette selection, crossover, mutation을 통해 label quality를 높인다. GA는 느리지만 offline label generator로 사용되므로, online stage에서는 GNN inference만 수행한다.

GNN은 task node feature \((d_i,c_i)\), service node feature \(f_j\), edge feature인 transmission rate를 사용한다. 두 개의 graph convolution layer로 second-order neighborhood 정보를 모으고, MLP가 최종 offloading probability를 만든다. Training loss는 GA label과 GNN prediction 사이의 cross-entropy이며, optimizer는 Adam이다.

### 실험 설정

논문은 Python 3.8과 PyTorch로 구현하고, Intel i7-12700F CPU와 RTX 3060 Ti GPU 환경에서 실험한다.

| 항목 | 값 |
|---|---|
| Task size | 10, 20, 50, 100 MB |
| Required computation | \([1,2]\times10^9\) cycles |
| Service vehicle capacity | 3 to 5 GHz |
| Communication distance | 20 to 500 m |
| V2V bandwidth | 10 MHz |
| Transmit power | 100 mW |
| GNN layers | 2 |
| Node embedding dimension | 256 |
| MLP hidden dimension | 128 |
| Training epochs | 3000 |
| Initial learning rate | \(10^{-3}\) |

Baseline은 GA, hill climbing, MLP, OMAB이다. GA는 solution quality가 높지만 online inference가 느린 reference에 가깝고, MLP는 graph structure를 쓰지 않는 neural baseline이다. OMAB는 매우 빠르지만 offloading quality가 낮은 lightweight baseline으로 읽을 수 있다.

### 핵심 결과

Training loss에서 GNN은 약 0.2 부근으로 수렴하며 MLP보다 낮은 loss를 보인다. 이는 graph structure를 넣는 것이 label을 모방하는 데 도움이 된다는 실험적 근거다.

Task vehicle 수를 5개에서 10개로 늘리고 service vehicle을 4개로 고정한 실험에서, GA는 가장 낮은 processing delay를 보이지만 inference delay가 크다. GNN은 processing delay만 보면 GA보다 뒤지지만, online inference가 0.03초 미만으로 매우 짧아 total delay에서 유리해진다.

| 비교 지점 | 결과 해석 |
|---|---|
| 10 task vehicles | GNN processing delay는 GA보다 약 17% 높고 hill climbing보다 약 1% 높음 |
| GNN vs MLP | GNN processing delay가 MLP보다 약 26% 낮음 |
| GNN vs OMAB | GNN processing delay가 OMAB보다 약 41% 낮음 |
| GA inference delay | 5 vehicles에서 14.664초, 10 vehicles에서 31.016초 |
| Hill climbing inference delay | 1.226초에서 7.929초까지 증가 |
| GNN inference delay | 0.03초 미만 |

Transmission power를 0.5 W에서 1 W로 높이면 GNN total delay는 1.135초에서 0.780초로 감소한다. Service vehicle computing capacity를 3 GHz에서 7 GHz로 높이면 GNN total delay는 0.923초에서 0.817초로 감소한다. 즉 성능 향상은 단순히 model architecture만이 아니라 communication rate와 compute resource 조건에도 민감하다.

### 논문이 말한 것과 해석을 구분하기

| 구분 | 내용 |
|---|---|
| 논문 주장 | G-TORA는 variable-size vehicular network에서 scalable offloading/resource allocation을 제공한다. |
| 근거 | GNN이 graph size 변화에 대응하고, GA/CH보다 훨씬 낮은 online inference delay를 보인다. |
| 해석 | 이 방법은 "offline에서 비싼 optimization으로 좋은 label을 만들고, online에서는 GNN surrogate로 빠르게 실행"하는 구조다. |
| 주의점 | Supervised label이 GA quality와 sampling coverage에 묶이므로, unseen traffic distribution에서 label bias가 남을 수 있다. |

### 한계와 해결 방향

첫째, training data와 GA label을 많이 필요로 한다. 실제 deployment에서는 모든 topology를 미리 sampling하기 어렵기 때문에 semi-supervised learning, imitation learning과 online fine-tuning, 혹은 reward 기반 self-training을 결합하는 방식이 필요하다.

둘째, time slot 내부의 communication state가 비교적 정적으로 처리된다. 고속 이동성에서는 link prediction error가 커지므로 temporal GNN, mobility-aware edge feature, uncertainty-aware resource allocation으로 확장해야 한다.

셋째, 논문은 response delay 중심으로 평가한다. 실제 서비스 홍보 관점에서는 low-latency cooperative perception, AR navigation, fleet analytics 같은 응용을 붙일 수 있지만, 연구적으로는 deadline miss ratio, reliability, fairness, multi-hop cooperation까지 확장해야 서비스 품질을 더 설득력 있게 보여줄 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/gnn-task-offloading-scalable-vehicular/gnn-task-offloading-scalable-vehicular.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://doi.org/10.1049/CMU2.70064" target="_blank" rel="noopener">DOI: 10.1049/CMU2.70064</a></li>
  <li><a href="https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/cmu2.70064" target="_blank" rel="noopener">Official IET Communications page</a></li>
</ul>
