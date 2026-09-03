---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Semantic QoE Offloading"
topic: "QoE-driven semantic-aware edge offloading"
order: 61
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "semantic-aware offloading"
  - "QoE"
  - "MEC"
  - "multi-task offloading"
---

# QoE-Driven Multi-Task Offloading for Semantic-Aware Edge Computing Systems

Source PDF: `qoe-driven-multi-task-offloading-semantic.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | QoE-Driven Multi-Task Offloading for Semantic-Aware Edge Computing Systems |
| 출처 | IEEE Transactions on Network Science and Engineering, 2026 |
| 주제 | QoE-driven semantic-aware edge offloading |
| 핵심 방법 | Multi-task offloading policy using semantic-aware QoE objectives |

## 한 줄 요약

이 논문은 edge computing에서 task를 단순 bit 단위 workload가 아니라 semantic value와 QoE에 연결된 작업으로 보고, multi-task offloading 결정을 다룬다.

## 핵심 내용

기존 MEC offloading은 전송 bit와 latency를 중심으로 보지만, semantic task에서는 압축 정도가 통신량뿐 아니라 task accuracy와 사용자 만족도까지 바꾼다. 이 논문은 여러 UE의 semantic extraction factor, offloading choice, channel allocation, transmit power와 GPU frequency를 하나의 QoE 최적화 문제로 묶는다.

MAPPO는 사용자 간 resource contention이 있는 joint decision을 학습하며, 실험에서 semantic-unaware 접근보다 높은 QoE를 보고한다. 핵심 의의는 의미 보존과 시스템 자원 배분을 연결한 데 있고, 실제 서비스 적용에서는 QoE 함수와 사용자 선호를 task별로 보정하고 단말 inference 비용까지 검증해야 한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Semantic edge | semantic-aware computing은 offloading 목적을 어떻게 바꾸는가? |
| 2 | Multi-task | 여러 task의 QoE와 resource contention을 어떻게 함께 보는가? |
| 3 | Policy | offloading decision이 latency, accuracy, semantic utility를 어떻게 균형화하는가? |
| 4 | Evaluation | QoE 중심 지표는 기존 latency-only 기준과 무엇이 다른가? |

## 한국어 번역형 해설

### 초록과 문제의식

이 논문은 MEC offloading을 단순히 "얼마나 많은 bit를 edge server로 보낼 것인가"의 문제가 아니라, semantic extraction, task accuracy, latency, energy가 함께 결정하는 QoE 최적화 문제로 본다. Uplink bandwidth가 제한된 환경에서 여러 UE가 동시에 task를 offload하면 network congestion이 생기고, 전송 지연과 task performance가 모두 악화될 수 있다.

저자들은 semantic-aware multi-task offloading framework를 제안한다. 핵심 변수는 semantic extraction factor $$\mu_n$$이며, 이는 UE $$n$$의 raw data를 얼마나 강하게 semantic representation으로 압축할지 조절한다. 논문 주장은 $$\mu_n$$, offloading choice, channel allocation, transmit power, GPU frequency를 함께 최적화해야 execution latency, energy consumption, task performance를 균형 있게 개선할 수 있다는 것이다.

### 시스템 구조와 QoE 목적함수

System architecture는 여러 UE가 local execution과 task offloading 중 선택하는 형태다. Text와 image input은 각각 semantic encoder를 거쳐 압축된 representation으로 바뀌고, edge server 또는 receiver 쪽에서 semantic decoder, information fusion, task-specific execution이 수행된다. 지원 task는 text classification, image classification, visual question answering(VQA)이다.

QoE metric은 execution latency, execution energy consumption, task performance의 세 요소로 구성된다. 서로 다른 task는 metric scale이 다르므로, 논문은 logistic function을 이용해 각 요소를 정규화하고 user preference weight를 반영한다. 즉 latency-sensitive user, accuracy-sensitive user, battery-constrained user가 서로 다른 QoE weight를 가질 수 있다.

최적화 변수는 $$\{\rho,p,f,x,\mu\}=\{\rho_n,p_n,f_n,x_{k,n},\mu_n\}$$로 요약된다. $$\rho_n$$은 offloading decision, $$p_n$$은 transmit power, $$f_n$$은 local GPU frequency, $$x_{k,n}$$은 UE $$n$$의 sub-channel $$k$$ 할당 여부, $$\mu_n$$은 semantic extraction factor다. 제약 조건에는 offloading choice, channel selection, UE당 최대 하나의 sub-channel, channel당 최대 하나의 UE, 최대 transmit power, 최대 GPU frequency, latency bound, battery capacity, minimum task accuracy가 포함된다.

### $$\mu_n$$ trade-off와 그림 해석

이 글에서 $$\mu_n$$은 "클수록 항상 좋다"거나 "작을수록 항상 빠르다"는 단일 방향 변수가 아니다. 원문의 semantic extraction factor 그림은 $$\mu_n$$이 extraction overhead, transmitted data, task accuracy 사이의 trade-off를 바꾼다는 점을 보여준다. 더 강한 semantic extraction은 전송해야 할 data volume을 줄일 수 있지만, semantic extraction 자체의 계산 overhead와 task accuracy 변화가 함께 발생한다.

따라서 논문은 $$\mu_n$$을 고정 hyperparameter로 두지 않고 action space에 포함한다. Semantic-aware MAPPO는 각 UE의 task type, channel condition, queue, energy constraint, accuracy requirement를 관측한 뒤 $$\mu_n$$과 resource allocation을 동시에 선택한다. 연구자의 해석으로는, 이 논문에서 semantic awareness의 실질적 의미는 "semantic compression을 적용했다"가 아니라, $$\mu_n$$이 QoE objective 안에서 동적으로 조절된다는 데 있다.

### MAPPO 정식화

문제 $$P0$$는 binary offloading variable과 nonconvex logistic QoE 때문에 nonconvex MINLP가 된다. 저자들은 이를 MDP $$\langle S,A,R,\gamma\rangle$$로 재정식화하고 semantic-aware MAPPO로 푼다. UE $$n$$의 action은 $$a_n=\{\rho_n,p_n,f_n,\mu_n,x_{k,n}\}$$이며, reward는 모든 UE의 QoE 합을 중심으로 latency, energy consumption, task accuracy constraint 위반에 대한 normalized penalty를 포함한다. 전체 timestep reward는 $$r_t=\sum_{n=1}^{N}r_n$$으로 정의된다.

MAPPO를 선택한 이유는 multi-agent setting에서 discrete decision과 continuous resource variable을 함께 다루면서 PPO의 clipped surrogate objective로 policy update를 안정화할 수 있기 때문이다. 논문은 A3C와 MADDPG의 한계도 비교한다. A3C는 high variance와 불안정한 update를 낳을 수 있고, MADDPG는 deterministic policy와 centralized action-value critic에 의존해 hyperparameter와 high-dimensional observation에 민감할 수 있다는 설명이다.

### 실험 설정과 주요 결과

실험은 SST-2 text classification, CIFAR-10 image classification, VQAv2 VQA를 사용한다. Text semantic extraction에는 BERT 기반 text embedding, image semantic extraction에는 Vision Transformer(ViT), VQA에는 BERT와 ViT 및 cross-modal fusion 구조를 사용한다. 계산량은 text classification 3.72 GFLOPs, image classification 8.43 GFLOPs, VQA 8.31 GFLOPs로 보고된다. Training 설정은 AdamW, learning rate $$3\times10^{-5}$$, batch size 50, weight decay $$1\times10^{-4}$$이며, 실험 platform은 NVIDIA RTX 4090과 Intel i9-13900K다.

주요 결과는 semantic-aware MAPPO가 semantic-unaware approach 대비 사용자 QoE를 12.68% 향상시킨다는 것이다. Bandwidth가 증가하면 QoE가 개선되고, noise power가 커지거나 user 수가 늘어나면 congestion과 channel degradation 때문에 QoE가 낮아지는 경향이 나타난다. 그럼에도 semantic-aware MAPPO는 D3QN, local execution, semantic-unaware baselines보다 높은 QoE를 유지한다.

또한 user preference figure는 QoE weight가 달라질 때 policy가 latency, energy, accuracy의 균형을 다르게 잡을 수 있음을 보여준다. 예를 들어 지연 가중치가 커지면 더 빠른 execution을 선호하고, accuracy 가중치가 커지면 더 높은 task performance를 위해 semantic extraction과 resource allocation을 다르게 선택한다. 이는 논문이 주장하는 personalized QoE 확장 가능성의 근거다.

### 한계와 확장 방향

이 논문의 한계는 QoE metric이 task와 user preference 설계에 의존한다는 점이다. Logistic normalization과 weight choice가 실제 사용자 만족을 얼마나 잘 반영하는지는 서비스별 calibration이 필요하다. 또한 semantic model training과 MAPPO simulation은 고성능 GPU platform에서 수행되므로, resource-constrained UE에 바로 배포하려면 model size, inference latency, battery impact를 별도로 검증해야 한다.

해결 및 확장 방향은 비교적 명확하다. 첫째, user feedback과 online telemetry를 이용해 QoE weight와 logistic normalization parameter를 서비스별로 보정해야 한다. 둘째, $$\mu_n$$ 선택은 channel uncertainty와 task drift에 robust하도록 online adaptation 또는 safe exploration과 결합할 수 있다. 셋째, 제한된 device에서는 pruning, quantization, knowledge distillation을 적용해 semantic encoder를 경량화하고, $$\mu_n$$ 범위를 device capability에 맞게 제한하는 deployment profile을 둘 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/qoe-driven-multi-task-offloading-semantic/qoe-driven-multi-task-offloading-semantic.pdf" | relative_url }}" target="_blank" rel="noopener">qoe-driven-multi-task-offloading-semantic.pdf</a></li>
  <li><a href="https://doi.org/10.1109/tnse.2026.3662899" target="_blank" rel="noopener">DOI: 10.1109/tnse.2026.3662899</a></li>
</ul>
