---
layout: default
date: 2026-06-19 18:09:01 +0900
title: "FedAgg"
topic: "End-edge-cloud federated learning for larger model training"
order: 10
major_topic: "Federated & Distributed Learning"
keywords:
  - "Federated learning"
  - "End-edge-cloud"
  - "Model training"
  - "Agglomerative aggregation"
---

# Agglomerative Federated Learning: End-Edge-Cloud Collaboration

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Agglomerative Federated Learning: Empowering Larger Model Training via End-Edge-Cloud Collaboration |
| 저자 | Zhiyuan Wu, Sheng Sun, Yuwei Wang, Min Liu, Bo Gao, Quyang Pan, Tianliu He, Xuefeng Jiang |
| 주제 | Federated Learning, End-Edge-Cloud Collaboration, Hierarchical FL, Online Distillation |
| 핵심 방법 | FedAgg, Bridge Sample Based Online Distillation Protocol |

## 한 줄 요약

FedAgg는 end-edge-cloud 계층에서 각 장치가 동일한 모델 크기를 가질 필요가 없도록, bridge sample 기반 online distillation을 이용해 더 큰 상위 모델과 작은 하위 모델이 지식을 교환하게 만드는 federated learning framework다.

## 핵심 내용

이 논문은 end device, edge server, cloud가 함께 AI 모델을 학습하는 상황에서 기존 federated learning의 한계를 다룬다. 기존 계층형 FL은 여러 계층을 사용하더라도 같은 모델 구조를 공유하는 경우가 많아, 최종 모델 크기가 가장 약한 장치에 맞춰지는 문제가 있었다.

FedAgg는 이 제약을 완화하기 위해 계층마다 다른 크기의 모델을 허용한다. 작은 end model은 local data를 이용해 학습하고, edge와 cloud는 더 큰 모델을 사용해 넓은 표현력을 가진다. 서로 다른 모델 사이의 직접 parameter averaging은 어렵기 때문에, 논문은 bridge sample을 만들고 각 모델의 출력을 비교하며 online distillation을 수행한다.

이 방식의 핵심은 privacy와 flexibility를 동시에 유지하는 것이다. 원본 데이터는 device 밖으로 나가지 않지만, 모델이 생성한 지식은 bridge sample response 형태로 계층 간에 전달된다. 따라서 FedAgg는 EECC 환경에서 상위 node의 계산 능력을 활용하면서도 FL의 기본 목적을 유지하려는 설계로 이해할 수 있다.

FedAgg를 읽을 때는 일반적인 federated averaging과 distillation 기반 협업의 차이를 분명히 해야 한다. FedAvg는 같은 architecture의 parameter를 평균하는 방식이므로, end device가 작은 모델밖에 학습하지 못하면 전체 federation도 그 모델 크기에 묶인다. FedAgg는 서로 다른 크기의 모델을 허용하고, bridge sample에 대한 output response를 통해 지식을 맞춘다.

이 접근은 edge-cloud collaboration에서 중요한 의미를 가진다. Edge와 cloud는 end device보다 큰 모델을 다룰 수 있으므로, 상위 계층의 capacity를 활용하면 전체 성능을 높일 수 있다. 하지만 bridge sample이 data distribution을 충분히 대표하지 못하면 distillation이 잘못된 방향으로 진행될 수 있다. 따라서 FedAgg의 성패는 계층 구조 자체뿐 아니라 bridge sample의 품질과 non-IID 상황에서의 robustness에 달려 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 기존 hierarchical federated learning은 가장 약한 end device의 모델 크기에 묶이는가? |
| 2 | 핵심 제안 | end, edge, cloud가 서로 다른 크기의 모델을 학습할 수 있는가? |
| 3 | 지식 전달 | Bridge sample이 parent-child node 사이의 distillation을 어떻게 가능하게 하는가? |
| 4 | 결과 해석 | 큰 모델의 일반화 능력과 FL의 privacy constraint를 동시에 만족하는가? |

## 1. 문제 배경

Federated Learning은 원본 데이터를 중앙 서버로 모으지 않고 각 device에서 학습을 수행한다. 그러나 end device는 계산 능력과 메모리가 제한되어 있어 큰 모델을 직접 학습하기 어렵다. Hierarchical Federated Learning은 end-edge-cloud 계층 구조를 이용하지만, 기존 방식은 모든 node가 같은 model architecture를 가진다고 가정하는 경우가 많다.

이 가정은 전체 학습 모델의 크기를 가장 약한 end device 수준으로 제한한다. Edge와 cloud는 더 큰 모델을 처리할 수 있는데도, 단일 구조를 강제하면 상위 계층의 계산 자원을 충분히 활용하지 못한다.

## 2. 제안 방법

FedAgg는 end, edge, cloud가 계층별로 다른 크기의 모델을 가질 수 있게 한다. 핵심은 모델 parameter를 단순 평균하는 대신, parent-child node 사이에서 생성된 bridge sample을 통해 서로의 출력을 distillation하는 것이다.

| 구성 | 역할 |
|---|---|
| End node | 제한된 자원에서 작은 모델을 학습 |
| Edge node | 여러 end node의 지식을 모으고 더 큰 모델 학습 |
| Cloud node | 가장 큰 모델을 사용해 전체 generalization 강화 |
| BSBODP | Bridge sample을 이용해 서로 다른 크기의 모델 간 지식 전달 |

이 구조는 모델 크기가 다른 상황에서도 FL의 privacy constraint를 유지하면서 계층 간 knowledge transfer를 수행한다.

## 3. 결과 및 해석

논문은 FedAgg가 기존 HFL 방식보다 평균 정확도를 높일 수 있다고 보고한다. 중요한 해석은 성능 개선이 단순히 cloud 모델을 크게 만든 데서만 나오지 않는다는 점이다. Bridge sample 기반 distillation이 end-edge-cloud 사이의 표현 차이를 연결하기 때문에, 하위 device의 제약과 상위 node의 모델 확장성이 함께 다뤄진다.

다만 bridge sample 생성과 distillation 품질이 전체 성능에 직접 영향을 주므로, 데이터 분포가 매우 비균질하거나 bridge sample이 실제 task distribution을 잘 대표하지 못하면 성능이 흔들릴 수 있다.

## 4. 연구 맥락

QECO-Adapt 관점에서 이 논문은 edge-cloud 협업 구조를 학습 문제에 적용한 사례로 볼 수 있다. Task offloading은 계산 task를 어디에서 처리할지 결정하고, FedAgg는 model training knowledge를 어떤 계층에서 어떻게 교환할지 다룬다. 둘 다 edge 환경에서 자원 차이를 숨기기보다 계층별 capability 차이를 모델링한다는 공통점이 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/agglomerative-federated-learning-end-edge-cloud-collaboration/agglomerative-federated-learning-end-edge-cloud-collaboration.pdf" | relative_url }}" target="_blank" rel="noopener">Agglomerative Federated Learning PDF</a></li>
</ul>
