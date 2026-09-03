---
layout: default
date: 2026-08-21 09:57:18 +0900
title: "PACC"
topic: "Partition-aware connected components on Hadoop and Spark"
order: 76
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "Connected components"
  - "Graph partitioning"
  - "Edge filtering"
  - "Graph sketching"
  - "Hadoop"
  - "Spark"
---

# PACC: Large Scale Connected Component Computation on Hadoop and Spark

Source PDF: [Local source PDF]({{ "/assets/pdfs/research/pacc-large-scale-connected-component-computation/pacc-large-scale-connected-component-computation.pdf" | relative_url }})

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | PACC: Large scale connected component computation on Hadoop and Spark |
| 출처 | PLOS ONE 15(3), 2020 |
| DOI | 10.1371/journal.pone.0229936 |
| 저자 | Ha-Myung Park, Namyong Park, Sung-Hyon Myaeng, U Kang |
| 핵심 방법 | Partition-aware computation, edge filtering, graph sketching |
| 목표 | Commodity cluster에서 중간 데이터와 load imbalance를 줄이는 대규모 connected-components 계산 |

## 한 줄 요약

PACC는 graph를 partition 단위로 다루고 불필요한 edge를 제거하며 작은 sketch를 먼저 계산해, Hadoop과 Spark에서 connected-components의 통신량과 worker 간 부하 편차를 함께 줄인다.

## 핵심 내용

분산 connected-components 계산에서는 iteration 수뿐 아니라 star operation이 만드는 intermediate edge, worker 간 load imbalance와 반복 통신이 병목이 된다. PACC는 graph를 partition 단위로 처리해 edge 집중을 완화하고, 연결성에 더 이상 영향을 주지 않는 edge를 걸러 다음 round의 입력을 줄인다.

또한 원 graph의 작은 sketch에서 component 정보를 먼저 계산해 본 계산을 단순화하며, 이 원리를 Hadoop과 Spark 환경에서 평가한다. 핵심 의의는 수렴 알고리즘 하나만 바꾸는 대신 partition-aware computation, edge filtering과 sketching을 결합해 commodity cluster의 통신량과 부하 편차를 함께 줄인 데 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Alternating algorithm | 기존 star operation은 왜 edge를 한 node에 집중시키는가? |
| 2 | Partition-aware operations | Component 정보를 유지하면서 edge를 여러 partition에 분산할 수 있는가? |
| 3 | Edge filtering | 다음 round에 영향을 주지 않는 edge를 언제 제거할 수 있는가? |
| 4 | Sketching | 원 graph보다 작은 graph에서 component를 먼저 찾을 수 있는가? |
| 5 | Hadoop and Spark | 같은 원리가 서로 다른 distributed engine에서도 유효한가? |

## 한국어 번역형 해설

### 문제: 수렴보다 먼저 intermediate data가 병목이 된다

Connected-components는 같은 연결 성분에 속한 모든 vertex에 동일한 representative를 부여하는 문제다. 단일 machine에서는 Union-Find로 효율적으로 풀 수 있지만, graph가 distributed storage에 놓이면 매 round의 shuffle, disk I/O와 worker별 edge 수가 실행 시간을 결정한다.

기존 alternating algorithm의 large-star와 small-star는 graph를 빠르게 수렴시키지만, edge가 작은 ID의 node로 집중될 수 있다. 이 현상은 특정 worker에 과도한 data와 computation을 몰아 load imbalance를 만든다. PACC는 component label만 보는 대신 edge가 어느 partition에서 처리되는지도 알고리즘에 포함한다.

### Partition-aware large-star와 small-star

PACC-base는 node를 \(\rho\)개 partition에 배정하고, 각 partition이 담당하는 edge를 유지한 채 두 star operation을 수행한다. PA-large-star는 큰 neighbor를 local minimum 쪽으로 연결하고, PA-small-star는 작은 neighbor와 현재 node를 local minimum 쪽으로 연결한다.

핵심은 edge가 하나의 대표 node로만 몰리지 않도록 partition별 subproblem을 보존하는 것이다. 이 구성은 connected-components의 정확성을 유지하면서 worker가 담당하는 input 크기를 균등하게 만들고, 각 round가 생성하는 graph가 원 input보다 커지지 않도록 설계된다.

### Edge filtering

PACC-ef는 이후 component 판정에 더 이상 필요한 정보가 없는 edge를 round 사이에서 제거한다. 두 endpoint가 이미 같은 representative로 수렴했거나 partition-local 처리에서 중복된 edge는 다음 shuffle 대상으로 남겨둘 이유가 없다.

Filtering은 알고리즘의 worst-case work만 바꾸는 기법이 아니라, 실제 system cost를 직접 줄인다. Round가 진행될수록 읽고 쓰고 전송해야 할 graph가 작아져, HDFS 기반 MapReduce와 in-memory RDD 기반 Spark 모두에서 이득을 얻는다.

### Sketching

PACC는 degree가 높은 node를 중심으로 graph 일부를 먼저 sampling해 작은 sketch를 만든다. Sketch에서 얻은 component 정보를 원 graph에 반영하면 많은 vertex와 edge가 이미 압축된 상태에서 본 계산을 시작할 수 있다.

Sketching은 정확도를 포기하는 approximation이 아니다. 작은 graph에서 얻은 안전한 연결 정보를 원 graph를 축약하는 데 사용하고, 남은 edge에 대해 정확한 connected-components 계산을 계속한다. 따라서 최종 component 결과는 유지하면서 초기 data volume을 줄인다.

### 실험 결과

논문은 Hadoop과 Spark 구현을 모두 비교한다. PACC는 당시의 MapReduce·Spark 기반 비교 알고리즘보다 2.9배에서 10.7배 빨랐고, Twitter와 YahooWeb에서는 sketching을 포함한 구성이 PACC-ef보다 최대 3.3배 빨랐다.

| 관찰 | 원문 보고 결과 |
|---|---:|
| 기존 distributed 방법 대비 | 2.9–10.7× faster |
| Sketching의 추가 개선 | up to 3.3× |
| Round별 graph 크기 | Input size 이하로 유지 |
| 구현 환경 | Hadoop and Spark |

## UniCon과의 연결

[UniCon]({{ "/research/unicon-unified-star-operation-connected-components/" | relative_url }})은 PACC가 다룬 partition-aware processing과 edge filtering을 이어받아, alternating algorithm의 두 star operation 자체를 하나의 UniStar로 통합한다. PACC가 각 round의 data distribution과 input 크기를 안정화한다면, UniCon은 필요한 distributed operation 수까지 줄이는 방향으로 발전한다.

## 의의와 확장 방향

PACC의 의의는 graph algorithm과 distributed data layout을 분리하지 않았다는 데 있다. Partitioning, filtering과 sketching을 하나의 pipeline으로 묶어 algorithmic convergence뿐 아니라 shuffle volume, skew와 memory pressure를 함께 제어한다. 공개 구현은 Hadoop과 Spark에서 이 설계를 재현하고 후속 알고리즘과 비교할 수 있는 기반을 제공한다.

Static graph 중심의 batch 처리라는 조건은 dynamic connectivity로 확장할 수 있다. Edge update가 들어온 partition만 다시 계산하는 incremental component maintenance, hub를 분산하는 skew-aware partitioning, cloud object storage의 read 비용까지 포함한 cost model을 결합하면 현대 data platform에 더 잘 맞는다. UniCon식 operation fusion을 함께 적용하면 round 수와 round당 data size를 동시에 줄이는 후속 설계도 가능하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/pacc-large-scale-connected-component-computation/pacc-large-scale-connected-component-computation.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0229936" target="_blank" rel="noopener">PLOS ONE</a></li>
  <li><a href="https://doi.org/10.1371/journal.pone.0229936" target="_blank" rel="noopener">DOI: 10.1371/journal.pone.0229936</a></li>
  <li><a href="https://github.com/kmudmlab/PACC" target="_blank" rel="noopener">Official code and data repository</a></li>
</ul>
