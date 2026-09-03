---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 11: Large Scale Distributed Training"
course: "CS231N"
topic: "Large-Scale Distributed Training"
order: 11
major_topic: "Computer Vision"
keywords:
  - "Distributed Training"
  - "Data Parallelism"
  - "Model Parallelism"
  - "Batch Size"
  - "Training Systems"
---

# Stanford CS231N Lecture 11: Large Scale Distributed Training

Source: [Stanford CS231N Spring 2025 Lecture 11](https://www.youtube.com/watch?v=9MvD-XsowsE){:target="_blank" rel="noopener"}

Official slides: [Lecture 11 PDF](https://cs231n.stanford.edu/slides/2025/lecture_11.pdf){:target="_blank" rel="noopener"}

> **핵심:** 대규모 학습은 GPU 수를 늘리는 문제가 아니라 **연산, 메모리, 통신을 서로 다른 병렬화 축으로 분해하는 시스템 설계 문제**다. 가장 느린 데이터 이동 경로가 전체 처리량을 결정한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | GPU anatomy | Tensor core와 HBM은 어떤 역할을 하는가? |
| 2 | Cluster hierarchy | 장치 내부와 장치 사이 대역폭은 왜 다른가? |
| 3 | Data parallelism | 여러 replica의 gradient를 어떻게 같게 만드는가? |
| 4 | FSDP and HSDP | Parameter memory와 통신 topology를 어떻게 함께 맞추는가? |
| 5 | Pipeline parallelism | 층을 나누면서 idle time을 어떻게 줄이는가? |
| 6 | Tensor parallelism | 하나의 행렬 연산을 여러 장치가 어떻게 나누는가? |

## 1. GPU는 빠른 연산기와 계층적 메모리의 조합이다

강의는 H100을 예로 들어 GPU core 주변에 80GB HBM이 있고, core 내부에도 더 작고 빠른 메모리가 계층적으로 배치됨을 설명한다. 데이터가 tensor core까지 도달하지 못하면 이론상 FLOPS가 높아도 실제 kernel은 느리다. 즉 성능은 연산 횟수뿐 아니라 메모리 대역폭과 데이터 재사용에 달려 있다.

Tensor core는 작은 행렬 곱을 대량 병렬 수행하며, 보통 16-bit 입력과 32-bit 누산을 결합한 mixed precision을 사용한다. 낮은 정밀도는 처리량과 메모리 효율을 높이고 높은 정밀도의 누산은 수치 오차를 줄인다. 모델 코드가 이런 행렬 곱 형태를 충분히 만들지 못하면 hardware peak 성능을 활용할 수 없다.

## 2. 한 장치에서 수만 장치로 확대할 때 생기는 비대칭

한 GPU는 자기 HBM과 매우 빠르게 통신하지만, 서버 안 GPU 간 연결과 서버·rack 간 network는 상대적으로 느리다. 강의의 Llama 3 405B 사례는 8-GPU 서버, rack, 3,072-GPU pod, 총 24,576-GPU cluster라는 계층을 보여준다. 이 수치는 모델 규모보다도 **통신 topology를 의식한 배치**가 필수임을 드러낸다.

따라서 자주 통신해야 하는 병렬 작업은 가능한 빠른 연결 안에 묶고, 느린 경계를 넘는 통신량은 줄여야 한다. GPU와 TPU의 세부 구조는 달라도 대규모 행렬 연산과 계층적 interconnect를 활용한다는 시스템 관점은 같다.

## 3. Data parallelism: 샘플을 나누고 gradient를 합친다

전체 mini-batch 크기를 $$N$$, GPU 수를 $$M$$이라 하면 각 GPU가 약 $$N/M$$개 샘플을 처리한다. 모든 GPU는 같은 parameter $$\theta$$를 보유하고 서로 다른 샘플에서 local gradient $$g_m$$을 계산한다. 동기식 update에 쓰는 평균 gradient는

$$
g=\frac{1}{M}\sum_{m=1}^{M}g_m
$$

이다. All-reduce가 이 합산 결과를 모든 GPU에 배포하므로 각 replica가 동일한 update를 수행한다. Forward pass는 통신 없이 병렬화되지만 backward pass에는 gradient 통신이 생긴다. 뒤쪽 layer의 gradient가 준비되는 즉시 all-reduce를 시작해 앞쪽 layer의 backward 계산과 겹치면 통신 일부를 숨길 수 있다.

Data parallelism은 구현이 단순하고 처리량을 잘 늘리지만 각 장치가 전체 모델·activation·optimizer state를 보유해야 한다. 모델 하나가 GPU 메모리에 들어가지 않으면 다른 축의 병렬화가 필요하다.

## 4. FSDP와 HSDP: data parallelism의 memory를 분할한다

Fully Sharded Data Parallelism(FSDP)은 batch만 나누는 데서 더 나아가 각 parameter에 하나의 owner GPU를 정한다. Forward에서 layer를 계산하기 직전에 shard를 모아 전체 weight를 잠시 복원하고, 계산 뒤 다시 버린다. Backward에서도 필요한 weight를 다시 모으며, gradient는 reduce-scatter해 각 owner가 자기 shard만 update한다. 다음 layer weight를 미리 가져오는 prefetch로 통신과 계산을 겹칠 수 있다.

그 결과 모든 GPU가 model 전체를 상시 보관하지 않아도 되지만, 한 forward-backward 동안 weight를 반복 전송하므로 통신량이 커진다. 강의의 예에서는 100B parameter가 800GB를 차지해도 80 GPU에 shard하면 GPU당 parameter memory가 약 10GB가 된다. 다만 이후에는 activation memory가 다음 병목이 되어 checkpointing이 필요하다.

Hybrid Sharded Data Parallelism(HSDP)은 GPU를 2차원 grid로 보고, 빠른 연결의 작은 group 안에서는 FSDP를, group 사이에서는 일반 data parallelism을 적용한다. 통신이 많은 weight gathering은 보통 8-GPU server 같은 빠른 intra-node group에 가두고, 느린 inter-node 경계에서는 gradient 동기화만 수행한다. 즉 sharding 범위를 무조건 키우는 대신 cluster topology에 맞춰 memory 절감과 통신 비용을 절충한다.

## 5. Pipeline parallelism: layer를 단계로 나눈다

Pipeline parallelism은 연속된 layer 묶음을 여러 GPU에 배치한다. 하나의 batch만 통과시키면 다른 stage가 기다리는 **pipeline bubble**이 크다. Batch를 micro-batch로 쪼개 서로 다른 micro-batch가 각 stage에서 동시에 계산되게 하면 utilization이 높아진다.

그러나 stage 경계에서 activation과 gradient를 전송해야 하고, stage별 계산량이 불균형하면 가장 느린 stage가 병목이 된다. Activation checkpointing은 중간 activation 일부를 저장하지 않고 backward 때 재계산해 메모리를 줄이는 대신 추가 연산을 지불하는 선택이다.

## 6. Tensor parallelism: 한 layer의 행렬 곱을 나눈다

선형층 $$Y=XW$$에서 $$W$$를 열 방향으로 나누면 여러 GPU가 $$Y$$의 서로 다른 feature slice를 계산한다. 행 방향 분할에서는 partial result를 합치는 통신이 필요하다. Attention의 여러 head나 MLP의 큰 행렬을 이런 방식으로 나눌 수 있다.

Tensor parallelism은 단일 layer조차 한 GPU에 들어가지 않을 때 유용하지만 layer마다 통신이 자주 발생한다. 그래서 보통 빠른 intra-server 연결 안에서 사용하고, data/pipeline parallelism과 조합한 다차원 병렬화를 구성한다.

## 핵심 수식 유도

### 작성자 보충: data-parallel gradient 평균

Global batch $$B$$를 $$N$$개 worker의 disjoint batch $$B_n$$로 나누고 크기가 같다면

$$
\frac1{|B|}\sum_{x\in B}\nabla\ell(x)=\frac1N\sum_{n=1}^{N}\left(\frac1{|B_n|}\sum_{x\in B_n}\nabla\ell(x)\right).
$$

All-reduce 평균이 single-device global-batch gradient와 같은 이유를 보이는 **항등식**이다. Worker batch 크기가 다르면 sample-count weighted average가 필요하다. Gradient와 loss의 단위는 parameterization을 따르고 $$N$$은 무차원이다. 통신 지연, stale gradient, BatchNorm local statistics, floating-point reduction order 때문에 실제 trajectory는 완전히 같지 않을 수 있다.

## 마지막 핵심 정리

- GPU 성능은 **tensor core 처리량과 메모리 공급 능력**을 함께 봐야 한다.
- Data parallelism은 batch를, pipeline parallelism은 layer를, tensor parallelism은 layer 내부 연산을 나눈다.
- FSDP는 parameter·gradient·optimizer state를 shard하고, HSDP는 빠른 연결 안의 sharding과 group 간 replication을 조합한다.
- All-reduce, activation 전송, partial-result 합산이 각각의 대표 통신 비용이다.
- 실제 대규모 학습은 한 기법의 승부가 아니라 장치 메모리와 network topology에 맞춘 조합이다.

## Study Guide

각 병렬화 방식에 대해 “무엇을 복제하고, 무엇을 분할하며, 언제 통신하는가”를 표로 직접 그려 본다. 모델이 한 GPU에는 들어가지만 batch가 작은 경우와, layer 하나도 들어가지 않는 경우를 구분해 적합한 방식을 선택해 본다.

## 복습 질문

<details markdown="block"><summary>1. Data parallelism의 all-reduce는 왜 필요한가?</summary>

답변: 각 GPU가 서로 다른 샘플에서 gradient를 계산하므로 그대로 update하면 replica가 달라진다. 평균 gradient를 모두에게 공유해야 단일 큰 batch와 같은 동기식 update가 된다.
</details>

<details markdown="block"><summary>2. Pipeline bubble은 무엇이며 어떻게 줄이는가?</summary>

답변: 일부 stage가 입력이나 gradient를 기다리며 쉬는 시간이다. Batch를 micro-batch로 나누어 여러 stage가 서로 다른 micro-batch를 동시에 처리하면 줄일 수 있다.
</details>

<details markdown="block"><summary>3. Tensor parallelism을 빠른 장치 간 연결 안에 두는 이유는?</summary>

답변: layer마다 activation 또는 partial result를 자주 교환하므로 통신 빈도가 높기 때문이다. 느린 rack 간 network를 반복해서 넘으면 연산 이득이 사라진다.
</details>

## 원문 대조 기록

공식 PDF **148쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 4–29쪽 | H100 구조와 cluster hierarchy | 1–2절 |
| PDF 30–70쪽 · 영상 00:28:35, 00:41:17 | data parallelism, FSDP, HSDP | 3–4절 |
| PDF 71–102쪽 · 영상 00:53:29 | activation checkpointing과 memory/compute trade-off | 5절 |
| PDF 103–113쪽 · 영상 00:58:10 | HFU와 MFU | 시스템 지표로 대조; 별도 수식 증명 대상 아님 |
| PDF 114–145쪽 | context, pipeline, tensor parallelism | 5–6절 |

병렬화 동작과 수치는 강의 원문 요약이다. Global-batch gradient와 all-reduce 평균의 동치, unequal batch caveat는 **작성자 보충**이다.

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=9MvD-XsowsE){:target="_blank" rel="noopener"}
- [Official Lecture 11 slides](https://cs231n.stanford.edu/slides/2025/lecture_11.pdf){:target="_blank" rel="noopener"}
