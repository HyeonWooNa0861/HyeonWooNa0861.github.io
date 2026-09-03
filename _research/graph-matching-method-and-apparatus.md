---
layout: default
date: 2026-08-21 09:57:18 +0900
title: "Graph Matching Patent"
topic: "Symmetry-breaking node ordering for duplicate-free subgraph matching"
order: 75
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "Graph matching"
  - "Subgraph isomorphism"
  - "Symmetry breaking"
  - "Node ordering"
  - "VF2"
---

# Graph Matching Method and Apparatus

Source PDF: [Official patent PDF](https://patentimages.storage.googleapis.com/85/ec/97/d3f3e6eda9823c/KR101747854B1.pdf){:target="_blank" rel="noopener"}

## 문서 정보

| 항목 | 내용 |
|---|---|
| 원제 | 그래프 매칭 방법 및 장치 |
| 영문명 | METHOD AND APPARATUS FOR MATCHING GRAPH |
| 문서번호 | KR101747854B1 (Google Patents publication number; 국내 등록번호 10-1747854) |
| 출원번호 | KR1020160139185A |
| 출원일 | 2016-10-25 |
| 등록일 | 2017-06-09 |
| 공고·공개일 | 2017-06-15 |
| 발명자 | 서동민, 유석종, 이민호, 강유, 박하명 |
| 원권리자 | 한국과학기술정보연구원(KISTI) |

## 한 줄 요약

이 특허는 data graph의 node numbering과 query graph의 priority constraint를 결합해, 같은 subgraph가 node permutation만 바뀐 채 반복 탐색되는 일을 줄이는 graph matching 방법과 장치를 정의한다.

## 핵심 내용

대칭 구조를 가진 query graph에서는 node permutation만 다른 동일 subgraph가 반복 탐색될 수 있고, 결과 생성 뒤의 deduplication만으로는 불필요한 backtracking 비용을 줄일 수 없다. 이 특허는 data graph node에 비교 가능한 번호를 부여하고 query graph의 automorphism에서 priority constraint를 구성해 중복을 탐색 과정에서 차단한다.

Partial match가 정해진 priority를 어기면 branch를 즉시 중단하므로 동일 구조의 반복 생성과 끝까지 진행할 필요가 없는 탐색을 함께 줄인다. 핵심 의의는 graph symmetry를 사후 정리 문제가 아니라 early pruning 규칙으로 바꾸고, 이를 processor·memory·storage로 구성된 장치 수준까지 구체화한 데 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Duplicate matches | VF2식 순차 대응에서 같은 구조가 왜 여러 번 나타나는가? |
| 2 | Data-node numbering | Data graph의 후보 node에 어떤 비교 가능한 순서를 부여하는가? |
| 3 | Query priority | Query automorphism에서 하나의 canonical order를 어떻게 고르는가? |
| 4 | Early pruning | Partial match가 priority를 위반할 때 어떻게 즉시 탐색을 중단하는가? |
| 5 | Apparatus | Algorithm을 processor, memory, storage와 network interface로 어떻게 구성하는가? |

## 한국어 해설

### 문제: Graph automorphism이 만드는 중복 탐색

Subgraph matching은 query graph와 동형인 부분 구조를 data graph에서 찾는다. Query가 대칭 구조를 가지면 여러 node permutation이 사실상 같은 match를 표현할 수 있다. 단순한 backtracking은 이 permutation을 각각 탐색하고, 마지막에 동일 결과를 filtering할 수 있다.

특허가 지적하는 VF2 계열의 병목은 바로 이 중복이다. Search가 끝난 뒤 결과를 정리하기보다, data node에 비교 가능한 번호를 부여하고 query node 사이에 priority를 만들어 search 중간에 불가능하거나 중복인 branch를 제거한다.

### 1단계: Data graph node numbering

Data graph의 모든 node를 degree 기준으로 정렬한다. 가장 작은 degree의 node에 $$n$$을 부여하고, 번호가 없는 node 중 다음 후보에 $$n+1$$을 반복해 부여한다. 같은 degree의 후보가 둘 이상이면 명세서는 하나를 선택해 번호를 부여할 수 있다고 설명한다.

이 번호는 matching 순서 자체가 아니라, query node가 대응된 data node 사이의 대소 관계를 검사하기 위한 값이다. 따라서 query priority가 $$N(a)<N(b)$$라면, $$a$$와 $$b$$에 대응된 data-node number가 같은 관계를 만족해야 한다.

### 2단계: Query graph priority

Query graph node로 만들 수 있는 permutation을 생성하고, 서로 동형인 graph를 clustering한다. 기준 cluster와 기준 graph를 선택한 뒤, 기준 graph의 $$m$$번째 node가 같은 cluster의 다른 graph에 있는 $$m$$번째 node보다 작다는 조건을 만든다. 조건에 맞지 않는 permutation을 제거하고 $$m+1$$로 이동한다.

기준 graph만 남을 때까지 반복하면 query node 사이의 priority constraint가 완성된다. 현대 graph-algorithm 용어로는 automorphism orbit에서 대표 순서를 정하는 symmetry-breaking constraint로 해석할 수 있다.

### 3단계: Priority-aware matching

Matching은 query node를 data node에 대응시키면서 priority를 즉시 검사한다. 예를 들어 $$p<q<r$$인데 partial mapping의 data-node number가 $$q<r$$을 위반하면, 아직 매칭하지 않은 다음 query node를 시도할 필요 없이 해당 branch를 종료한다.

```text
data node numbering
        +
query symmetry priority
        ↓
partial mapping comparison
        ↓
violation: prune / satisfied: continue
```

중복 결과를 생성한 뒤 제거하는 비용과, 끝까지 진행할 필요가 없는 search branch의 비용을 모두 줄이려는 구조다.

## 청구 범위의 구조

18개 청구항은 크게 두 묶음으로 나뉜다.

| 범위 | 내용 |
|---|---|
| 청구항 1–9 | Matching method, data-node numbering, query priority generation |
| 청구항 10–18 | Processor, network interface, memory와 storage를 포함한 apparatus 및 각 operation |

독립항 1은 전체 method를, 독립항 10은 같은 logic을 수행하는 apparatus를 중심으로 한다. 나머지 항은 degree ordering, 반복 종료, permutation clustering과 priority-based deletion을 구체화한다.

## 관련 논문과 연결

아래 연결은 특허의 직접 인용 관계가 아니라, 해결하는 문제와 최적화 층을 기준으로 한 개념적 비교다.

[Efficient Subgraph Matching on Billion Node Graphs]({{ "/research/efficient-subgraph-matching-billion-node-graphs/" | relative_url }})는 structure index 대신 STwig exploration과 query planning으로 search space를 줄인다. 이 특허가 한 query 내부의 symmetry와 duplicate branch를 줄이는 관점이라면, STwig 연구는 distributed data access와 join cost를 줄이는 관점이다.

[SEED]({{ "/research/seed-scalable-distributed-subgraph-enumeration/" | relative_url }})는 join unit과 bushy plan을 최적화하고 clique match를 압축한다. 세 연구를 함께 보면 canonical ordering, search pruning, distributed join planning이 서로 다른 층에서 같은 목표인 intermediate-result reduction을 수행한다.

## 의의와 확장 방향

특허의 장점은 graph symmetry를 post-processing 문제가 아니라 search constraint로 다룬다는 점이다. Chemistry, bioinformatics, image processing과 social-network analysis처럼 반복되는 graph pattern이 많은 분야에서 동일 match의 permutation을 줄이는 기본 원리로 활용할 수 있다.

다만 query node의 모든 permutation과 isomorphism cluster를 직접 생성하면 query가 커질수록 factorial growth가 발생할 수 있다. 이를 해결하려면 nauty/Traces류 canonical labeling, automorphism-group orbit partition 또는 constraint propagation으로 priority를 직접 생성할 수 있다. Degree만으로 data-node order를 만들 때 tie가 많아지는 문제는 label frequency, neighborhood signature와 candidate selectivity를 결합해 보완할 수 있다. Distributed 환경에서는 이 symmetry constraint를 STwig·clique join plan에 주입해 intermediate match가 network로 이동하기 전에 제거하는 방향으로 확장할 수 있다.

## Source Integrity Note

공개 PDF에는 비표준 embedded attachment object `STOC`가 포함되어 있었다. Local research archive에서는 해당 attachment만 제거한 안전본으로 본문과 도면을 검토했으며, 블로그에는 PDF 사본을 두지 않고 공식 patent record와 공식 PDF를 연결한다.

## 참고자료

<ul>
  <li><a href="https://patents.google.com/patent/KR101747854B1/ko" target="_blank" rel="noopener">Google Patents record</a></li>
  <li><a href="https://patentimages.storage.googleapis.com/85/ec/97/d3f3e6eda9823c/KR101747854B1.pdf" target="_blank" rel="noopener">Official patent PDF</a></li>
</ul>
