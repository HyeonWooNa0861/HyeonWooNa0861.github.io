---
layout: default
date: 2026-08-21 09:57:18 +0900
title: "PTE"
topic: "Pre-partitioned distributed enumeration of trillion-scale graph triangles"
order: 74
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "Triangle enumeration"
  - "Pre-partitioning"
  - "MapReduce"
  - "Graph mining"
  - "ClueWeb12"
---

# PTE: Enumerating Trillion Triangles On Distributed Systems

Source PDF: [Official KDD PDF](https://www.kdd.org/kdd2016/papers/files/rfp0276-parkA.pdf){:target="_blank" rel="noopener"}

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | PTE: Enumerating Trillion Triangles On Distributed Systems |
| 출처 | KDD 2016 |
| DOI | 10.1145/2939672.2939757 |
| 저자 | Ha-Myung Park, Sung-Hyon Myaeng, U Kang |
| 핵심 방법 | Pre-partitioning, color-direction pruning, scheduled edge-set loading |
| 목표 | Shuffle, total work, network read를 동시에 줄이는 exact triangle enumeration |

## 한 줄 요약

PTE는 graph를 color pair별 edge set으로 먼저 저장한 뒤 필요한 set만 읽고 triangle을 열거해, ClueWeb12의 63억 vertex와 720억 edge에서 3조 개가 넘는 triangle을 처리한다.

## 핵심 내용

Triangle enumeration은 개수만 세는 것이 아니라 모든 vertex triple을 식별해야 하므로, 대규모 graph에서 반복 shuffle, 중복 intersection과 edge-set read가 계산보다 큰 병목이 될 수 있다. PTE는 graph를 color pair별 edge set으로 미리 분할해 저장하고 각 subproblem에 필요한 set만 읽는 방식으로 실행 구조를 바꾼다.

PTECD는 color-direction 규칙으로 중복 계산을 줄이고, PTESC는 제한된 memory에서 관련 subproblem을 연속 배치해 network read를 줄인다. 이 결합은 worst-case optimal한 total work를 지향하면서 ClueWeb12의 trillion-scale triangle output까지 처리했으며, 계산·저장·스케줄링을 함께 최적화한 것이 핵심 의의다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Triangle enumeration | Counting이 아니라 모든 triangle을 찾는 문제는 왜 더 어려운가? |
| 2 | Pre-partitioning | 매 round마다 같은 edge를 shuffle하지 않으려면 어떻게 저장해야 하는가? |
| 3 | Color direction | Triangle type별 중복 intersection을 어떻게 제거하는가? |
| 4 | Scheduling | 제한된 memory에서 edge set read를 어떻게 최소화하는가? |
| 5 | Scale | Trillion-scale output이 있는 graph를 실제로 처리할 수 있는가? |

## 한국어 번역형 해설

### Enumeration은 counting과 다르다

Triangle enumeration은 undirected simple graph $$G=(V,E)$$에서 서로 완전히 연결된 vertex triple을 하나씩 찾아 local function에 전달하는 문제다. 단순한 triangle count보다 결과 하나하나를 식별해야 하므로 computation과 I/O 부담이 크다. 논문은 degree와 vertex ID로 total order를 만들고 $$u\prec v\prec n$$인 triangle을 한 방향으로만 표현해 중복 출력을 막는다.

기존 MapReduce 알고리즘은 vertex color 조합별 subproblem을 만들 때 edge를 여러 reducer로 반복 전송한다. CTTP는 한 round의 크기를 제한해 out-of-space를 피하지만, 전체적으로는 동일한 edge를 여러 번 shuffle하고 매 round 전체 data를 다시 읽는다.

### PTEBASE: 먼저 나누고 나중에 계산하기

PTEBASE는 graph partitioning과 subgraph generation을 분리한다. Vertex를 $$\rho$$개 color로 hash하고, color pair $$(i,j)$$에 해당하는 edge set $$E_{ij}$$를 HDFS나 RDD 같은 distributed storage에 한 번 저장한다. 이후 각 subproblem은 필요한 edge set만 직접 읽는다.

이 구조에서 shuffle은 최초 partition 단계의 $$O(\lvert E\rvert)$$로 줄어든다. Network read는 남아 있지만 shuffle처럼 sender의 collect·spill, transfer, receiver의 merge·sort를 모두 요구하지 않으므로 비용 구조가 다르다.

### PTECD: Color-direction으로 중복 계산 제거

PTECD는 edge $$(u,v)$$의 vertex color 순서를 color-direction으로 사용한다. Type-3 triangle을 찾을 때 pivot, port, starboard edge가 들어갈 color-direction을 미리 알 수 있으므로, 관계없는 neighbor set은 intersection 대상에서 제외한다.

Type-1 triangle도 특정 color 조합에서 한 번만 계산하도록 배치한다. 결과적으로 PTEBASE가 같은 triangle 후보를 여러 번 검사하는 문제를 줄이고, worst-case optimal한 $$O(\lvert E\rvert^{3/2})$$ total work에 도달한다.

### PTESC: Edge-set loading 순서 최적화

PTESC는 subproblem 사이에서 memory에 남겨둘 edge set과 다음에 읽을 set을 scheduling한다. 한 번에 유지하는 edge set 수를 제한하면서 관련 subproblem을 연속 배치해 network read를 줄인다. 논문이 제시한 주요 bound는 다음과 같다.

| 비용 | PTE bound |
|---|---:|
| Shuffled data | $$O(\lvert E\rvert)$$ |
| Network read | $$O(\lvert E\rvert^{3/2}/\sqrt{M})$$ |
| Total work | $$O(\lvert E\rvert^{3/2})$$ |

여기서 $$M$$은 machine 하나가 사용할 수 있는 memory다.

### 실험 결과

PTE의 세 단계 가운데 PTESC가 가장 강한 구성이다. Real-world graph에서 기존 distributed algorithm보다 최대 47배 빨랐고, 이전 비교군이 실패한 ClueWeb12까지 처리했다.

| 관찰 | 원문 보고 결과 |
|---|---:|
| ClueWeb12 vertex | 6.3 billion |
| ClueWeb12 edge | 72 billion |
| Enumerated triangles | more than 3 trillion |
| 기존 distributed algorithm 대비 | up to 47× faster |
| ClueWeb12 전체 triangle 저장 추정량 | about 70 TB |

알고리즘은 모든 triangle을 memory에 보관하는 대신 `enum(·)` local callback을 호출하도록 정의한다. 따라서 output을 저장할지, aggregate할지, streaming 후 버릴지는 응용이 결정해야 한다.

## 관련 연구와 연결

아래 연결은 직접 참고문헌 매칭이 아니라, triangle 전용 최적화와 일반 subgraph enumeration을 비교하기 위한 개념적 연결이다.

[SEED]({{ "/research/seed-scalable-distributed-subgraph-enumeration/" | relative_url }})는 triangle 하나가 아니라 arbitrary pattern graph의 모든 match를 distributed join으로 찾는다. PTE가 고정된 3-node clique의 구조를 극단적으로 최적화한다면, SEED는 star와 clique join unit, bushy plan, compression을 이용해 더 일반적인 subgraph enumeration으로 확장한다.

## 의의와 확장 방향

PTE의 중요한 통찰은 연산 kernel만 빠르게 만드는 것으로는 충분하지 않다는 점이다. Graph partition을 재사용 가능한 physical layout으로 먼저 만들고, color-direction과 scheduling을 그 layout에 맞추어 함께 설계해야 shuffle, work와 read를 동시에 낮출 수 있다.

고정된 hash partition은 hub와 community가 강한 graph에서 edge-set skew를 만들 수 있다. Degree-aware coloring, adaptive repartitioning과 straggler detection을 추가하면 tail latency를 줄일 수 있다. Streaming graph에는 변경된 color pair의 edge set만 갱신하고 affected triangle만 재계산하는 incremental enumeration을 결합할 수 있다. Output이 수십 TB에 이르는 경우에는 approximate counting이 아니라도 streaming aggregation, compressed motif index 또는 downstream feature extraction을 callback에 직접 연결하는 방식이 실용적이다.

## Source Availability Note

KDD PDF의 저작권 고지는 server 재게시에는 별도 허가가 필요하다고 명시한다. 따라서 이 블로그는 PDF 사본을 호스팅하지 않고 KDD의 공식 공개 PDF와 DOI만 연결한다.

## 참고자료

<ul>
  <li><a href="https://www.kdd.org/kdd2016/papers/files/rfp0276-parkA.pdf" target="_blank" rel="noopener">Official KDD PDF</a></li>
  <li><a href="https://doi.org/10.1145/2939672.2939757" target="_blank" rel="noopener">DOI: 10.1145/2939672.2939757</a></li>
</ul>
