---
layout: default
title: "SEED"
topic: "Cost-based distributed enumeration of arbitrary graph patterns"
order: 77
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "Subgraph enumeration"
  - "Distributed graph processing"
  - "Star-clique storage"
  - "Bushy join"
  - "Query optimization"
---

# SEED: Scalable Distributed Subgraph Enumeration

Source PDF: [Local source PDF]({{ "/assets/pdfs/research/seed-scalable-distributed-subgraph-enumeration/seed-scalable-distributed-subgraph-enumeration.pdf" | relative_url }})

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | Scalable Distributed Subgraph Enumeration |
| 출처 | Proceedings of the VLDB Endowment 10(3), 2016 |
| DOI | 10.14778/3021924.3021937 |
| 저자 | Longbin Lai, Lu Qin, Xuemin Lin, Ying Zhang, Lijun Chang, Shiyu Yang |
| 핵심 방법 | Star-clique-preserved storage, join units, cost model, bushy-plan optimization |
| 목표 | Billion-edge graph에서 arbitrary pattern의 모든 match를 확장성 있게 열거 |

## 한 줄 요약

SEED는 data graph를 star와 clique 정보가 보존되는 형태로 분산 저장하고, query를 비용이 낮은 join unit으로 분해한 뒤 dynamic programming으로 bushy join plan을 찾아 중간 결과와 통신량을 줄인다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | General patterns | Triangle 전용 알고리즘을 arbitrary subgraph로 어떻게 확장하는가? |
| 2 | Storage | Star와 clique match를 local access만으로 생성할 수 있는가? |
| 3 | Join units | Query를 어떤 단위로 분해해야 intermediate result가 작아지는가? |
| 4 | Cost model | Power-law graph에서 join 순서를 어떻게 예측하는가? |
| 5 | Compression | Clique가 만드는 대량의 match를 compact하게 전달할 수 있는가? |

## 한국어 번역형 해설

### 문제: Enumeration 비용은 match 수보다 더 커질 수 있다

Subgraph enumeration은 query graph와 동형인 모든 subgraph를 data graph에서 찾는다. Triangle처럼 pattern이 하나로 고정되면 전용 방향성이나 partition 규칙을 설계할 수 있지만, arbitrary query는 edge, star, path와 clique가 서로 다른 비율로 섞인다.

Query edge를 하나씩 join하면 중간 결과가 폭발할 수 있고, 각 worker가 remote adjacency를 반복해서 읽으면 network cost가 커진다. SEED는 storage layout, query decomposition과 distributed join order를 하나의 최적화 문제로 묶는다.

### Star-clique-preserved storage

SEED의 저장 방식은 vertex 중심 star와 그 neighbor 사이의 clique 관계를 local partition에서 복원할 수 있도록 graph를 배치한다. Query가 star나 clique를 포함하면 해당 unit의 후보 match를 여러 worker 사이에서 edge 단위로 다시 조립하지 않고 local computation으로 만들 수 있다.

이 접근은 단순 replication과 다르다. 어떤 구조를 보존해야 이후 join이 작아지는지를 기준으로 data를 배치하고, unit 생성 단계의 network access를 줄인다.

### Star와 clique join unit

Query는 여러 join unit으로 분해된다. Star unit은 하나의 중심 node와 incident edge를 묶고, clique unit은 서로 완전히 연결된 query node 집합을 묶는다. 큰 unit은 한 번에 더 많은 constraint를 검사해 candidate를 줄이지만, local enumeration 비용과 저장 요구가 커질 수 있다.

SEED는 서로 겹치는 unit도 허용한다. Unit 사이에 공유 node가 많으면 join key가 강해지고 intermediate result가 줄어들 수 있기 때문이다. 따라서 query decomposition은 edge를 빠짐없이 덮는 문제를 넘어, 전체 distributed plan의 비용을 결정한다.

### Power-law cost model과 bushy join

Real-world graph의 degree distribution을 반영한 cost model은 각 unit의 예상 match 수와 join 결과 크기를 추정한다. Dynamic programming은 이 추정값을 사용해 left-deep plan에 제한되지 않는 bushy join tree를 찾는다.

Bushy plan에서는 서로 선택도가 높은 작은 subplan을 먼저 결합할 수 있다. 결과적으로 큰 candidate table이 모든 후속 단계로 전달되는 일을 피하고, worker 간 network traffic과 memory pressure를 낮춘다.

### Clique compression

Clique는 하나의 dense neighborhood에서 조합적으로 많은 match를 만든다. SEED는 공통 구조를 반복 materialize하지 않고 압축된 표현으로 유지한 뒤, 필요한 join 단계에서만 펼친다. 이 방식은 output 자체가 큰 query에서도 중간 표현의 중복을 줄인다.

### 실험 결과

SEED는 수십억 edge 규모의 graph와 여러 query pattern에서 기존 distributed subgraph-enumeration 방법보다 대체로 한 order 이상 빠른 결과를 보고한다. 일부 query와 dataset 조합에서는 20배, 30배를 넘고 전체 비교 범위에서는 50배 이상의 차이도 나타난다.

| 관찰 | 원문 보고 결과 |
|---|---:|
| Data scale | Billions of edges |
| 전반적 성능 향상 | More than one order of magnitude in major comparisons |
| 선택 query의 향상 | Over 20×–30× |
| 일부 비교의 최대 격차 | Over 50× |

## PTE 및 graph matching과의 연결

아래 연결은 참고문헌 일치 여부가 아니라, 문제 범위와 중간 결과 축소 전략을 기준으로 한 개념적 비교다.

[PTE]({{ "/research/pte-enumerating-trillion-triangles-distributed-systems/" | relative_url }})는 하나의 3-node clique에 대해 partition, direction과 loading schedule을 정교하게 최적화한다. SEED는 clique를 하나의 join unit으로 포함하면서 arbitrary pattern까지 범위를 넓힌다.

[Graph Matching Method and Apparatus]({{ "/research/graph-matching-method-and-apparatus/" | relative_url }})가 query automorphism에서 중복 search branch를 제거한다면, SEED는 distributed join plan에서 중복 intermediate structure를 줄인다. Symmetry-breaking constraint를 unit 생성 단계에 적용하면 두 접근을 결합할 수 있다.

## 의의와 확장 방향

SEED의 핵심 가치는 subgraph enumeration을 단일 traversal kernel이 아니라 distributed query optimization으로 본 데 있다. Storage, decomposition, cardinality estimation, join ordering과 compression을 함께 설계해 generality와 scale을 동시에 확보한다.

Power-law 기반 추정은 graph domain이나 query가 달라질 때 오차가 커질 수 있다. Sampling과 runtime feedback으로 cardinality를 갱신하는 adaptive optimizer, skew가 큰 unit을 세분화하는 work stealing, symmetry constraint를 이용한 candidate deduplication으로 보완할 수 있다. Dynamic graph에서는 변경된 partition과 관련 unit만 재계산하는 incremental view maintenance로 확장할 수 있다.

## Source Availability Note

원문은 CC BY-NC-ND 4.0 조건으로 제공된다. 이 블로그의 local PDF는 원문을 변경하지 않은 사본이며, 저자와 공식 출처를 함께 표시한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/seed-scalable-distributed-subgraph-enumeration/seed-scalable-distributed-subgraph-enumeration.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://www.vldb.org/pvldb/vol10/p217-lai.pdf" target="_blank" rel="noopener">Official PVLDB PDF</a></li>
  <li><a href="https://doi.org/10.14778/3021924.3021937" target="_blank" rel="noopener">DOI: 10.14778/3021924.3021937</a></li>
</ul>
