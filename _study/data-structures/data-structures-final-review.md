---
layout: default
date: 2026-06-09 18:22:09 +0900
last_modified_at: 2026-09-03 19:42:12 +0900
title: "Data Structures Final Review"
course: "Data Structures"
topic: "Final Exam Review"
order: 24
major_topic: "Data Structures & Algorithms"
keywords:
  - "Stacks"
  - "Trees"
  - "Sorting"
  - "Graphs"
  - "Shortest Paths"
---

# Data Structures Final Review

Source PDFs:

- `ds-midterm-sol.pdf`
- `LS13_sorting.pdf`
- `LS14_merge_sort.pdf`
- `LS15_quick_sort_R1.pdf`
- `LS16_priority_queue_and_heap.pdf`
- `LS17_heap_sort.pdf`
- `LS18_hash_search.pdf`
- `LS19_hash_search_2.pdf`
- `LS20_graph.pdf`
- `LS21_graph_traversal.pdf`
- `LS22_shortest_path.pdf`
- `LS23_minimum_spanning_tree.pdf`

이 자료는 업로드된 중간고사 솔루션의 문제 유형을 참고해 자료구조 기말고사 범위를 시험 대비용으로 재구성한 것이다. 중간고사와 마찬가지로 1번은 OX 및 객관식, 2-4번은 주관식 및 서술형으로 보고 준비한다.

이번 범위의 중심은 sorting, hashing, graph이며, 서술형은 heap sort, 그래프 표현 및 순회, 최단 경로를 직접 추적하고 설명하는 능력이 중요하다.

> **핵심:** **Sorting** 알고리즘별 시간복잡도, stable 여부, in-place 여부를 조건과 함께 외운다. **Heap sort** max heap을 만든 뒤 root와 마지막 원소를 바꾸며 오른쪽 sorted area를 키운다.

## 전체 흐름

| 문항 | 예상 유형 | 핵심 범위 | 답안에서 보여야 하는 것 |
|---:|---|---|---|
| 1 | OX 및 객관식 | sorting, hashing, graph 전반 | 정의, 시간복잡도, 장단점, 반례를 빠르게 판단 |
| 2 | 주관식 | heap sort | buildHeap, swap root-last, heap size 감소, siftDown 추적 |
| 3 | 주관식 및 서술형 | graph representation, BFS, DFS | adjacency matrix/list 작성, queue/stack/색/distance/time 추적 |
| 4 | 주관식 및 서술형 | shortest path | Dijkstra의 $$D$$, $$S$$, $$\text{prev}$$, relaxation 표 작성 |

중간고사 솔루션에서 배울 점은 단순하다. 정답만 쓰는 것이 아니라, 왜 그 답이 되는지 한 줄 근거를 붙여야 한다. 특히 서술형은 최종 결과보다 중간 상태 표가 채점의 핵심이 될 수 있다.

## 1. OX 및 객관식 대비

1번은 범위가 넓게 나올 수 있다. 외울 때는 알고리즘 이름만 보지 말고, "어떤 조건에서 맞는 말인가"를 같이 외워야 한다.

### Sorting 핵심 판별표

| 알고리즘 | 평균 시간 | 최악 시간 | 공간 | Stable | 핵심 포인트 |
|---|---|---|---|---|---|
| Bubble sort | $$O(n^2)$$ | $$O(n^2)$$ | $$O(1)$$ | 보통 stable | 인접 원소를 비교하며 큰 값을 뒤로 보냄 |
| Selection sort | $$O(n^2)$$ | $$O(n^2)$$ | $$O(1)$$ | 보통 unstable | 매번 최솟값/최댓값을 선택, swap 수가 적음 |
| Insertion sort | $$O(n^2)$$ | $$O(n^2)$$ | $$O(1)$$ | stable | 거의 정렬된 배열에서 $$O(n)$$에 가까움 |
| Merge sort | $$O(n\log n)$$ | $$O(n\log n)$$ | $$O(n)$$ | 구현에 따라 stable | divide, conquer, merge |
| Quick sort | $$O(n\log n)$$ | $$O(n^2)$$ | 평균 $$O(\log n)$$ | 보통 unstable | pivot 선택이 성능을 좌우 |
| Heap sort | $$O(n\log n)$$ | $$O(n\log n)$$ | $$O(1)$$ | unstable | max heap으로 최댓값을 오른쪽부터 확정 |

객관식에서 자주 흔들리는 지점은 다음이다.

| 헷갈리는 문장 | 판별 |
|---|---|
| "Merge sort는 항상 in-place다." | 거짓. 일반적인 merge sort는 추가 배열 $$O(n)$$을 사용한다. |
| "Quick sort는 항상 $$O(n\log n)$$이다." | 거짓. pivot이 계속 나쁘게 잡히면 최악 $$O(n^2)$$이다. |
| "Heap sort는 최악 시간도 $$O(n\log n)$$이다." | 참. buildHeap $$O(n)$$, removeMax 반복 $$O(n\log n)$$이다. |
| "Insertion sort는 거의 정렬된 데이터에서 유리하다." | 참. 이동할 거리가 짧으면 거의 선형 시간으로 동작한다. |
| "Stable sort는 같은 key의 상대 순서를 유지한다." | 참. stable의 정의다. |

### Hashing 핵심 판별표

해싱은 key를 table index로 바꾸는 방식이다.

$$
k \to h(k) \to HT[h(k)]
$$

좋은 해시 함수는 key를 슬롯에 가능한 균등하게 분포시킨다. 하지만 서로 다른 key가 같은 slot으로 갈 수 있으므로 collision resolution이 필요하다.

| 구분 | 다른 이름 | 저장 위치 | 장점 | 주의점 |
|---|---|---|---|---|
| Open hashing | Separate chaining | 테이블 슬롯 밖의 linked list | 삭제가 쉽고 load factor에 덜 민감 | 포인터 메모리와 캐시 효율 문제 |
| Closed hashing | Open addressing | 테이블 내부 슬롯 | 외부 구조가 적고 캐시 친화적 | load factor와 deletion marker가 중요 |

Closed hashing의 probing은 다음처럼 구분한다.

| 방법 | 식 | 특징 |
|---|---|---|
| Linear probing | $$h_i(k)=(h(k)+i)\bmod m$$ | 구현은 쉽지만 primary clustering |
| Constant step | $$h_i(k)=(h(k)+ic)\bmod m$$ | $$c$$와 $$m$$이 서로소여야 전체 슬롯 방문 가능 |
| Quadratic probing | $$h_i(k)=(h(k)+i^2)\bmod m$$ | primary clustering 완화, secondary clustering 가능 |
| Double hashing | $$h_i(k)=(h(k)+i h_2(k))\bmod m$$ | key마다 probe sequence가 달라 clustering 완화 |

Load factor는 closed hashing 성능을 좌우한다.

$$
\alpha=\frac{s}{m}
$$

여기서 $$s$$는 저장된 item 수, $$m$$은 table size다. $$\alpha$$가 1에 가까워질수록 빈 슬롯을 찾기 어려워지고 probe 횟수가 급격히 증가한다.

### 빈 슬롯 탐색 확률의 정확한 유도

> **전제와 분류:** $$m$$개 슬롯 중 $$s<m$$개가 점유되어 있고, probing이 슬롯을 중복 없이 균등한 무작위 순서로 방문한다고 가정한다. 다음 식은 이 유한 테이블 모형에서 정확하며, 독립 시행을 가정한 기하분포 식은 큰 $$m$$에서의 근사다.

빈 슬롯 수를 $$e=m-s$$, 처음 빈 슬롯을 만날 때까지의 probe 수를 $$X$$라 두면

$$
P(X=1)=\frac{e}{m},
\qquad
P(X=2)=\frac{s}{m}\frac{e}{m-1}.
$$

일반적으로 앞의 $$i-1$$개가 점유되고 $$i$$번째가 비어야 하므로, $$1\le i\le s+1$$에서

$$
P(X=i)
=\left(\prod_{j=0}^{i-2}\frac{s-j}{m-j}\right)
\frac{e}{m-i+1}.
$$

따라서 유한 테이블의 정확한 기대값은

$$
\mathbb{E}[X]
=\sum_{i=1}^{s+1}iP(X=i)
=\frac{m+1}{e+1}
=\frac{m+1}{m-s+1}.
$$

$$m$$이 크고 $$\alpha=s/m<1$$를 고정하면 각 초기 probe의 점유 확률을 거의 $$\alpha$$로 볼 수 있다. 이때

$$
P(X=i)\approx\alpha^{i-1}(1-\alpha),
\qquad
\mathbb{E}[X]\approx\frac{1}{1-\alpha}.
$$

$$X$$의 단위는 `회`이며 나머지 기호는 슬롯 개수 또는 무차원 비율이다. Linear probing의 primary clustering, 반복되는 quadratic probe sequence, tombstone, 비균등 hashing에서는 균등·무중복 가정이 깨지므로 이 근사를 그대로 적용할 수 없다.

### Graph 핵심 판별표

그래프는 정점과 간선의 집합이다.

$$
G=(V,E)
$$

| 개념 | 핵심 정의 | 시험 포인트 |
|---|---|---|
| Undirected graph | 간선에 방향이 없음 | $$(u,v)$$와 $$(v,u)$$를 같은 관계로 봄 |
| Directed graph | 간선에 방향이 있음 | in-degree, out-degree 구분 |
| Weighted graph | 간선에 weight가 있음 | 경로 길이는 weight 합 |
| Path | 간선을 따라 이어지는 정점열 | 반복 정점이 없으면 simple path |
| Cycle | 시작과 끝이 같은 path | DFS back edge와 cycle detection 연결 |
| Tree | 연결되고 cycle이 없는 graph | 정점 $$\lvert V\rvert$$개면 간선 $$\lvert V\rvert-1$$개 |
| Connected component | 무향 그래프의 연결된 덩어리 | BFS/DFS로 찾을 수 있음 |
| SCC | 유향 그래프에서 서로 도달 가능한 정점 집합 | connected component와 다름 |

그래프 표현은 인접 행렬과 인접 리스트를 비교해서 외운다.

| 표현 | 공간 | 간선 존재 확인 | 모든 이웃 순회 | 유리한 경우 |
|---|---|---|---|---|
| Adjacency matrix | $$O(\lvert V\rvert^2)$$ | $$O(1)$$ | 한 행 스캔 $$O(\lvert V\rvert)$$ | dense graph, 간선 존재 확인이 잦을 때 |
| Adjacency list | $$O(\lvert V\rvert+\lvert E\rvert)$$ | $$O(\deg(v))$$ | $$O(\deg(v))$$ | sparse graph, BFS/DFS/Dijkstra |

## 2. Heap Sort 서술형 대비

Heap sort 문제는 "결과 배열만" 쓰면 부족할 수 있다. 중간고사 솔루션처럼 상태 변화를 표로 보여야 한다.

### 핵심 과정

Max heap 기준 heap sort는 다음 순서로 진행한다.

1. 배열 전체를 max heap으로 만든다.
2. 루트, 즉 최댓값을 heap 영역의 마지막 원소와 swap한다.
3. heap size를 1 줄인다.
4. 루트에서 siftDown을 수행한다.
5. heap size가 1이 될 때까지 반복한다.

영역은 이렇게 나누어 생각한다.

```text
[ heap area ][ sorted area ]
```

처음에는 전체가 heap area다. 매 반복마다 최댓값이 오른쪽 sorted area의 맨 앞에 고정된다.

### 배열 인덱스 공식

0-indexed array heap에서는 다음 공식을 쓴다.

| 관계 | 공식 |
|---|---|
| parent | $$\left\lfloor (i-1)/2 \right\rfloor$$ |
| left child | $$2i+1$$ |
| right child | $$2i+2$$ |

1-indexed array를 쓰는 문제라면 left child는 $$2i$$, right child는 $$2i+1$$이다. 시험에서 배열 index 기준을 먼저 확인해야 한다.

### 답안 표 템플릿

| 단계 | heap size | 수행 | 배열 상태 | sorted area |
|---:|---:|---|---|---|
| 0 | $$n$$ | buildHeap 완료 | 문제 배열을 max heap으로 변환 | 없음 |
| 1 | $$n-1$$ | root와 last swap 후 siftDown | 갱신된 배열 | 오른쪽 1개 |
| 2 | $$n-2$$ | root와 last swap 후 siftDown | 갱신된 배열 | 오른쪽 2개 |

채점에서 중요한 설명은 다음이다.

| 질문 | 답 |
|---|---|
| buildHeap 시간은 왜 $$O(n)$$인가? | 대부분의 노드는 리프 근처에 있어 siftDown 거리가 짧기 때문이다. |
| 전체 heap sort 시간은? | buildHeap $$O(n)$$ + removeMax $$n$$번 $$O(\log n)$$이므로 $$O(n\log n)$$ |
| 추가 공간은? | 배열 내부에서 swap하므로 일반 구현은 $$O(1)$$ |
| stable한가? | 일반적인 heap sort는 stable하지 않다. |

### buildHeap이 선형 시간인 이유

> **전제와 분류:** 완전 이진 heap에 원소가 $$n$$개 있고, 높이 $$h$$인 노드의 `siftDown` 비용이 최대 $$ch$$라고 하자. $$c>0$$은 비교·교환 한 레벨의 상수 비용이므로 단위는 `연산/레벨`이다.

높이가 $$h$$인 노드 수는 완전 이진 트리의 마지막 레벨에서 위로 올라갈수록 절반씩 줄어들므로 다음 상계가 성립한다.

$$
N_h\le\left\lceil\frac{n}{2^{h+1}}\right\rceil,
\qquad
0\le h\le\lfloor\log_2 n\rfloor.
$$

리프는 $$h=0$$이라 실제 `siftDown` 비용이 0이다. 내부 노드만 합하면, $$H=\lfloor\log_2 n\rfloor$$에 대해

$$
\begin{aligned}
T(n)
&\le c\sum_{h=1}^{H}h
\left\lceil\frac{n}{2^{h+1}}\right\rceil \\
&\le c\sum_{h=1}^{H}h
\left(\frac{n}{2^{h+1}}+1\right) \\
&\le \frac{cn}{2}\sum_{h=1}^{\infty}\frac{h}{2^h}
+c\sum_{h=1}^{H}h \\
&=cn+O((\log n)^2).
\end{aligned}
$$

여기서 $$\sum_{h=1}^{\infty}h/2^h=2$$이고, $$(\log n)^2=O(n)$$이므로 $$T(n)=O(n)$$이다. 반대로 표준 bottom-up buildHeap은 $$\lfloor n/2\rfloor$$개의 내부 노드 각각에 대해 `siftDown` 호출의 상수 오버헤드를 수행하므로 일반적인 RAM 모형에서 $$\Omega(n)$$이다. 따라서 $$T(n)=\Theta(n)$$이다. 핵심은 모든 노드가 $$\log n$$만큼 내려가는 것이 아니라, 많은 노드가 높이 0 또는 1 근처에 있어 전체 비용이 수렴하는 가중합이 된다는 점이다.

## 3. Graph Representation 및 Traversal 대비

그래프 서술형은 주어진 그래프를 저장 구조로 바꾸거나, BFS/DFS를 직접 추적하는 형태가 자연스럽다.

### Graph Representation

정점이 $$A,B,C,D$$이고 간선이 주어지면 먼저 방향성과 weight를 확인한다.

| 조건 | 인접 행렬 작성법 |
|---|---|
| 무향 그래프 | $$M[u][v]$$와 $$M[v][u]$$를 같이 표시 |
| 유향 그래프 | 방향 그대로 $$M[u][v]$$만 표시 |
| 가중치 그래프 | 간선이 있으면 weight, 없으면 $$0$$, $$\infty$$, 또는 blank 등 문제 지시를 따름 |

인접 리스트는 각 정점 옆에 이웃을 나열한다.

```text
A: B, C
B: D
C: D
D:
```

문제에서 방문 순서가 중요하면 adjacency list의 이웃 순서를 그대로 따라야 한다. 같은 그래프라도 이웃을 확인하는 순서가 다르면 BFS/DFS 방문 순서가 달라질 수 있다.

### BFS 추적

BFS는 queue를 사용한다. 시작 정점 $$s$$의 거리는 0이고, 처음 발견한 이웃은 거리 $$u.d+1$$을 갖는다.

| 상태 | 의미 |
|---|---|
| WHITE | 아직 발견되지 않음 |
| GRAY | 발견되었고 queue에 들어 있음 |
| BLACK | 이웃 확인까지 완료 |

BFS 답안 표는 다음 형태로 쓰면 좋다.

| 단계 | dequeue | 새로 발견한 정점 | queue | distance 갱신 |
|---:|---|---|---|---|
| 0 | - | 시작 정점 $$s$$ | $$[s]$$ | $$d[s]=0$$ |
| 1 | $$s$$ | $$s$$의 WHITE 이웃 | 갱신된 queue | $$d[v]=d[s]+1$$ |

BFS는 unweighted graph에서 시작 정점으로부터의 최단 간선 수를 구한다. 가중치가 있는 그래프의 최소 비용 문제에는 Dijkstra가 필요하다.

### DFS 추적

DFS는 가능한 한 깊게 내려갔다가 되돌아온다. recursive DFS에서는 discovery time과 finish time을 기록할 수 있다.

| 값 | 기록 시점 |
|---|---|
| $$u.d$$ | 정점 $$u$$를 처음 발견했을 때 |
| $$u.f$$ | $$u$$의 모든 이웃 처리가 끝났을 때 |
| $$u.\pi$$ | $$u$$를 처음 발견하게 한 predecessor |

Directed graph의 DFS edge 분류는 꼭 구분해야 한다.

| edge 종류 | 검사 시점/관계 | 핵심 판별 |
|---|---|---|
| Tree edge | WHITE 정점을 처음 발견 | DFS tree의 부모-자식 간선 |
| Back edge | GRAY ancestor로 향함 | directed graph에서 cycle 존재와 연결 |
| Forward edge | BLACK descendant로 향하지만 tree edge 아님 | ancestor에서 descendant로 가는 non-tree edge |
| Cross edge | ancestor-descendant 관계가 아님 | 서로 다른 subtree 또는 이미 끝난 영역으로 감 |

## 4. Shortest Path 대비

최단 경로 문제는 LS22의 Dijkstra가 중심이다. 답안에서는 최종 거리만 쓰지 말고, $$S$$, $$D$$, $$\text{prev}$$가 어떻게 바뀌는지 보여야 한다.

### Dijkstra 전제

Dijkstra는 모든 edge weight가 음수가 아닐 때 사용한다.

$$
w(u,v)\ge 0
$$

음수 간선이 있으면 이미 확정한 정점의 거리가 나중에 더 작아질 수 있으므로 Dijkstra의 greedy 선택이 깨질 수 있다.

### 상태 변수

| 기호 | 의미 |
|---|---|
| $$S$$ | 최단 거리가 확정된 정점 집합 |
| $$D[v]$$ | 현재까지 알려진 시작 정점에서 $$v$$까지의 최단 거리 추정값 |
| $$\text{prev}[v]$$ | 현재 최단 경로에서 $$v$$ 바로 앞 정점 |

초기화는 다음과 같다.

$$
D[s]=0,\qquad D[v]=\infty\quad(v\ne s)
$$

Relaxation 조건은 다음이다.

$$
D[v] > D[u] + w(u,v)
$$

조건이 참이면 다음처럼 갱신한다.

$$
D[v]=D[u]+w(u,v)
$$

$$
\text{prev}[v]=u
$$

### 답안 표 템플릿

| 단계 | 선택 정점 $$u$$ | 확정 집합 $$S$$ | Relax한 간선 | $$D$$ 변화 | $$\text{prev}$$ 변화 |
|---:|---|---|---|---|---|
| 초기 | - | $$\emptyset$$ | - | $$D[s]=0$$, 나머지 $$\infty$$ | 모두 NIL |
| 1 | 최소 $$D$$ 정점 | $$S\cup\{u\}$$ | $$(u,v)$$들 | 더 짧으면 갱신 | 갱신된 $$v$$의 predecessor |

최단 경로 자체를 묻는다면 $$\text{prev}$$를 거꾸로 따라간다.

```text
target -> prev[target] -> ... -> source
```

그다음 순서를 뒤집어 source에서 target까지의 path로 쓴다.

### BFS와 Dijkstra 비교

| 항목 | BFS | Dijkstra |
|---|---|---|
| 그래프 | unweighted graph | nonnegative weighted graph |
| 거리 의미 | 간선 개수 | weight 합 |
| 선택 구조 | queue | minDistVertex 또는 min-heap |
| 갱신 | $$d[v]=d[u]+1$$ | $$D[v]=D[u]+w(u,v)$$ |

## 5. MST는 어디까지 볼 것인가

사용자가 지정한 서술형 중심은 최단 경로까지다. 다만 그래프 객관식에서 Prim과 Dijkstra 비교가 나올 수 있으므로 최소한 다음만 확인한다.

| 비교 | Dijkstra | Prim |
|---|---|---|
| 목적 | 시작 정점에서 각 정점까지의 최단 거리 | 모든 정점을 최소 총비용으로 연결하는 MST |
| $$D[v]$$ 의미 | 시작점에서 $$v$$까지의 현재 최단 거리 | 현재 tree에 $$v$$를 붙이는 최소 edge cost |
| 갱신 기준 | $$D[u]+w(u,v)<D[v]$$ | $$w(u,v)<D[v]$$ |
| 결과 | shortest path tree | minimum spanning tree |

즉 두 알고리즘은 표와 변수 이름이 비슷해도 최적화하는 값이 다르다.

## 핵심 수식 증명 빠른 참조

> **분류:** 시험 답안에 필요한 **증명 개요 모음**이다. 각 알고리즘의 자료구조와 입력 조건이 달라지면 결론도 달라질 수 있다.

아래의 $$n,m,s,\lvert V\rvert,\lvert E\rvert,i,k$$는 모두 무차원 개수다. 그래프 weight, Dijkstra 거리, Prim key와 MST total은 한 문제 안에서 서로 더하고 비교할 수 있는 같은 단위 $$U$$를 사용한다. 원문 슬라이드가 결론만 제시한 유도는 **작성자 보충**으로 표시한다.

| 빠른 참조 범위 | 원문 PDF 페이지 | 원문과 보충의 경계 |
|---|---|---|
| 시험 형식 | `ds-midterm-sol.pdf` pp.1–7 | 중간고사 문항 형식을 기말 범위에 적용한 구성은 작성자 재구성 |
| Sorting·heap | `LS13_sorting.pdf` pp.8–36, `LS14_merge_sort.pdf` pp.52–55, `LS15_quick_sort_R1.pdf` pp.12–70, `LS17_heap_sort.pdf` pp.21–29·53–54 | 원문은 알고리즘별 횟수·복잡도를 제시하며, 합과 점화식의 전개는 작성자 보충 |
| Hashing | `LS18_hash_search.pdf` pp.9–23, `LS19_hash_search_2.pdf` pp.17–39 | probe·load factor 식은 원문, gcd 조건과 확률 모형의 한계 설명은 작성자 보충 |
| Graph traversal | `LS20_graph.pdf` pp.38–49, `LS21_graph_traversal.pdf` pp.17–18·38 | 표현별 저장량과 순회 복잡도는 원문, 항목 수를 합산한 증명은 작성자 보충 |
| Dijkstra·Prim | `LS22_shortest_path.pdf` pp.11·24–25, `LS23_minimum_spanning_tree.pdf` pp.8–9·16–28 | 절차·갱신식·복잡도는 원문, greedy 선택의 교환·귀납 증명은 작성자 보충 |

### Sorting의 합과 점화식

> **작성자 보충 · 분류:** 다음은 입력 크기를 정확히 반으로 나누거나, 한 단계의 비교 비용이 입력 크기에 비례한다는 명시된 조건 아래의 **정확한 합·점화식과 점근적 결론**이다.

Bubble·selection sort가 길이 $$n-1,n-2,\ldots,1$$ 구간을 차례로 확인하는 최악 경우의 비교 합은 정확히

$$
\sum_{j=1}^{n-1}j=\frac{n(n-1)}{2}=\Theta(n^2)
$$

이다. Merge sort는 $$n=2^q$$이고 각 merge level의 비용이 $$cn$$이라고 단순화하면

$$
T(n)=2T(n/2)+cn
$$

이며, level이 $$\log_2 n$$개이므로 $$T(n)=cn\log_2 n+\Theta(n)=\Theta(n\log n)$$이다. Quick sort는 pivot이 매번 한쪽 끝이면

$$
T(n)=T(n-1)+cn=\Theta(n^2),
$$

분할이 계속 일정 비율로 균형을 이루면 $$\Theta(n\log n)$$이다. 무작위 pivot의 평균 $$\Theta(n\log n)$$은 pivot rank가 충분히 고르게 선택된다는 확률 가정에 의존하며, 이미 정렬된 입력이라는 사실만으로 모든 구현이 최악이 되는 것은 아니다. Heap sort의 반복 삭제 비용은

$$
\sum_{k=2}^{n}\Theta(\log k)=\Theta(\log(n!))=\Theta(n\log n)
$$

이고 bottom-up `buildHeap`의 $$\Theta(n)$$을 더해도 전체는 $$\Theta(n\log n)$$이다. 직관적으로 quadratic sort는 줄어드는 선형 구간을 모두 훑고, divide-and-conquer sort는 선형 작업을 로그 개 level에서 반복한다. 조기 종료, pivot 규칙, 보조 배열 재사용 같은 구현 조건이 달라지면 best case와 공간 비용은 별도로 다시 계산해야 한다.

### Hash probing과 load factor

> **작성자 보충 · 분류:** probe 식과 $$\alpha$$는 **정의**, 방문 슬롯 수 결론은 **정확한 정수 성질**, 평균 probe 수는 아래 확률 모형 안에서만 성립하는 **모형 기반 근사**다.

Constant-step probing

$$
h_i(k)=(h(k)+ic)\bmod m
$$

은 $$i=0,1,\ldots$$에서 $$m/\gcd(c,m)$$개의 서로 다른 residue를 돈 뒤 반복한다. 두 index가 같은 슬롯이면 $$(i-j)c\equiv0\pmod m$$이고, 가장 작은 양의 반복 길이가 $$m/\gcd(c,m)$$이기 때문이다. 따라서 모든 $$m$$개 슬롯을 방문할 필요충분조건은 $$\gcd(c,m)=1$$이다.

Load factor는 정확한 정의

$$
\alpha=\frac{s}{m},\qquad 0\le\alpha\le1
$$

이며 무차원이다. 각 probe가 독립적으로 균일한 슬롯을 보고 빈 슬롯일 확률이 $$1-\alpha$$라고 근사하면

$$
P(X=i)\approx\alpha^{i-1}(1-\alpha),\qquad
E[X]\approx\frac{1}{1-\alpha}.
$$

그래서 $$\alpha\to1$$이면 예상 probe 수가 급증한다는 직관을 얻는다. 그러나 linear probing의 primary clustering은 probe들을 독립으로 만들지 않으므로 이 기하분포 식을 정확한 성능 보장으로 쓰면 안 된다. 삭제 marker, table fullness, $$c$$와 $$m$$의 공약수, hash 분포가 나쁘면 빈 슬롯이 있어도 탐색이 길어지거나 일부 슬롯에 도달하지 못한다.

### Graph representation의 저장량

> **작성자 보충 · 분류:** 표준 adjacency matrix/list 배치에 대한 **정확한 저장 항목 수와 점근적 결론**이다.

Adjacency matrix는 모든 ordered pair $$(u,v)$$에 한 칸을 두므로 정확히 $$\lvert V\rvert^2$$칸, 즉 $$\Theta(\lvert V\rvert^2)$$ 공간을 사용한다. Adjacency list는 정점별 header $$\lvert V\rvert$$개와 유향 그래프에서 adjacency entry $$\lvert E\rvert$$개, 무향 그래프에서 $$2\lvert E\rvert$$개를 저장하므로 두 경우 모두 $$\Theta(\lvert V\rvert+\lvert E\rvert)$$다. 따라서 한 정점 $$v$$의 list를 훑는 비용은 $$\Theta(\deg(v))$$이고, 모든 list 길이의 합은 유향에서 $$\lvert E\rvert$$, 무향에서 $$2\lvert E\rvert$$다.

직관적으로 matrix는 존재하지 않는 간선 자리까지 예약하고, list는 실제 간선만 저장한다. 이 결론은 hash set, bit matrix, 압축 sparse format 같은 추가 표현의 상수·탐색 비용에는 그대로 적용되지 않는다. Weighted matrix에서 0이 유효한 weight일 수 있으므로 "간선 없음"을 0으로 둘지 $$\infty$$로 둘지는 문제 정의를 따라야 한다.

### Prim 중요 수식

> **작성자 보충 · 분류:** 연결된 유한 무향 가중 그래프를 가정한 **정의·정확한 등식과 증명 링크**다.

Prim의 key 갱신은 누적 거리가 아니라 한 간선의 비용을 비교한다.

$$
D[v]\leftarrow\min\{D[v],w(u,v)\}.
$$

Root $$r$$의 key를 0으로 두고 나머지 각 정점이 선택될 때의 확정 key를 합하면, 선택 간선이 정확히 $$\lvert V\rvert-1$$개이므로

$$
w(T)=\sum_{e\in E_T}w(e)
=\sum_{v\in V-\{r\}}D[v].
$$

간선 수 귀납 증명과 cut-property 교환 논증은 [LS23 Minimum Spanning Tree]({{ "/study/data-structures/ls23-minimum-spanning-tree/" | relative_url }})의 `Tree 조건과 간선 수`, `Prim의 선택이 안전한 이유`에서 확인할 수 있다. 배열 scan 구현은 $$\Theta(\lvert V\rvert^2)$$, adjacency list와 binary min-heap 구현은 $$O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)$$이다. 그래프가 disconnected이면 하나의 spanning tree와 위의 유한 total이 존재하지 않고 minimum spanning forest 문제로 바뀐다.

### buildHeap은 왜 $$\Theta(n)$$인가

앞의 `buildHeap이 선형 시간인 이유` 절에서 높이별 노드 수를 ceiling을 포함한 상계로 세고, 레벨당 상수 비용까지 합해 $$T(n)=O(n)$$임을 보였다. 표준 Floyd bottom-up 구현은 $$\lfloor n/2\rfloor$$개 내부 노드에서 `siftDown` 호출의 상수 오버헤드를 수행하므로 $$\Omega(n)$$이고, 두 경계를 합치면 $$T(n)=\Theta(n)$$이다. 이는 빈 힙에 원소를 하나씩 삽입하는 방식에 대한 결론이 아니다.

### BFS/DFS는 왜 $$\Theta(\lvert V\rvert+\lvert E\rvert)$$인가

발견 즉시 방문 표시하면 각 정점은 한 번만 자료구조에 들어간다. 인접 리스트 길이의 합은 유향 그래프에서 $$\lvert E\rvert$$, 무향 그래프에서 $$2\lvert E\rvert$$이므로 정점 비용과 간선 비용을 더해 $$\Theta(\lvert V\rvert+\lvert E\rvert)$$다. 인접 행렬을 쓰면 각 행 전체를 검사해 $$\Theta(\lvert V\rvert^2)$$가 된다.

### Dijkstra 확정 규칙은 언제 맞는가

모든 간선이 음이 아니라고 하자. 최소 추정 거리의 미확정 정점 $$u$$까지 가는 **실제 최단경로**를 고르고, 그 경로가 확정 집합을 처음 벗어나는 간선을 $$(x,y)$$라 둔다. 최단경로의 prefix도 최단이므로 $$\delta(s,y)=\delta(s,x)+w(x,y)$$이고, $$x$$를 확정할 때의 relaxation과 $$D[x]=\delta(s,x)$$로부터 $$D[y]\le\delta(s,y)$$다. 거리 label은 실제로 발견된 경로 길이이므로 반대 부등식도 성립해 $$D[y]=\delta(s,y)$$다. 남은 suffix의 간선이 음이 아니어서 $$D[y]\le\delta(s,u)$$이고, 최소 $$D$$ 선택과 $$\delta(s,u)\le D[u]$$를 합치면 $$D[u]=\delta(s,u)$$가 된다. 음수 간선에서는 suffix 부등식이 깨지므로 사용할 수 없다.

## 마지막 핵심 정리

| 범위 | 반드시 남길 문장 |
|---|---|
| Sorting | 알고리즘별 시간복잡도, stable 여부, in-place 여부를 조건과 함께 외운다. |
| Heap sort | max heap을 만든 뒤 root와 마지막 원소를 바꾸며 오른쪽 sorted area를 키운다. |
| Hashing | collision resolution은 separate chaining과 open addressing으로 나뉜다. |
| Load factor | closed hashing에서는 $$\alpha$$가 커질수록 probe 비용이 급격히 증가한다. |
| Graph representation | matrix는 간선 확인이 빠르고, list는 sparse graph 순회에 효율적이다. |
| BFS | queue를 사용하며 unweighted shortest path distance를 구할 수 있다. |
| DFS | discovery/finish time과 edge classification을 추적한다. |
| Dijkstra | nonnegative weight graph에서 $$D$$, $$S$$, $$\text{prev}$$를 relaxation으로 갱신한다. |

## Study Guide

1. 먼저 1번 대비표를 보며 OX 문장에 붙일 한 줄 근거를 암기한다.
2. Heap sort는 배열 하나를 직접 골라 buildHeap 이후 root-last swap과 siftDown을 2회 이상 손으로 추적한다.
3. Graph representation은 같은 그래프를 adjacency matrix와 adjacency list로 각각 바꿔 본다.
4. BFS는 queue와 distance, DFS는 discovery/finish time과 edge type을 따로 연습한다.
5. Dijkstra는 매 단계마다 "가장 작은 미확정 $$D$$"를 고르고, relaxation으로 $$D$$와 $$\text{prev}$$를 갱신하는 표를 작성한다.
6. 시험 답안에는 최종 답만 쓰지 말고, 중간고사 솔루션처럼 판단 근거나 상태 변화 표를 함께 남긴다.

## 복습 질문

<details markdown="block">
<summary>1. Heap sort에서 buildHeap 이후 가장 먼저 하는 일은 무엇인가?</summary>

답변: Max heap의 root에는 현재 heap 영역의 최댓값이 있다. 따라서 root와 heap 영역의 마지막 원소를 swap하고, heap size를 1 줄여 오른쪽 끝을 sorted area로 확정한다. 그 뒤 루트에서 siftDown을 수행해 남은 heap 영역의 heap property를 복구한다.

</details>

<details markdown="block">
<summary markdown="span">2. buildHeap이 $$O(n\log n)$$이 아니라 $$O(n)$$인 이유는?</summary>

답변: 모든 노드가 높이 $$\log n$$만큼 내려가는 것이 아니기 때문이다. 대부분의 노드는 리프 근처에 있어 siftDown할 거리가 짧고, 루트 근처처럼 오래 내려갈 수 있는 노드는 수가 적다. 각 노드의 높이 합을 계산하면 전체 비용은 $$O(n)$$이 된다.

</details>

<details markdown="block">
<summary markdown="span">3. Merge sort와 heap sort는 둘 다 $$O(n\log n)$$인데 어떤 차이가 있는가?</summary>

답변: Merge sort는 일반적으로 추가 배열 $$O(n)$$을 사용하고 stable하게 구현하기 쉽다. Heap sort는 추가 공간 $$O(1)$$로 in-place 정렬이 가능하지만 일반 구현은 stable하지 않고, 실제 캐시 효율은 quick sort보다 떨어질 수 있다.

</details>

<details markdown="block">
<summary>4. Open hashing과 closed hashing을 어떻게 구분하는가?</summary>

답변: Open hashing은 separate chaining처럼 테이블 슬롯 밖에 linked list를 붙여 충돌을 처리한다. Closed hashing은 open addressing처럼 모든 item을 테이블 내부 슬롯에 저장하고, 충돌이 나면 probing으로 다른 빈 슬롯을 찾는다. 이름 때문에 open addressing과 open hashing을 혼동하지 않아야 한다.

</details>

<details markdown="block">
<summary>5. Linear probing에서 primary clustering이 생기는 이유는?</summary>

답변: 충돌이 나면 연속된 다음 슬롯을 검사하므로 점유된 슬롯들이 긴 덩어리로 뭉친다. 어떤 key가 그 덩어리 안으로 해싱되면 결국 덩어리 뒤의 빈 슬롯으로 밀려나고, 그 슬롯이 채워지면서 cluster가 더 길어진다.

</details>

<details markdown="block">
<summary>6. Adjacency matrix와 adjacency list 중 BFS/DFS에 보통 list가 유리한 이유는?</summary>

답변: BFS/DFS는 각 정점의 이웃을 순회한다. Adjacency list는 실제 존재하는 edge만 따라가므로 전체 비용이 $$O(\lvert V\rvert+\lvert E\rvert)$$이다. Sparse graph에서는 $$\lvert E\rvert$$가 $$\lvert V\rvert^2$$보다 훨씬 작기 때문에 matrix보다 효율적이다.

</details>

<details markdown="block">
<summary>7. BFS에서 정점을 발견하자마자 GRAY로 바꾸는 이유는?</summary>

답변: 같은 정점이 여러 부모를 통해 다시 발견되어 queue에 중복 삽입되는 것을 막기 위해서다. WHITE은 아직 발견 전, GRAY는 발견되었지만 처리 중, BLACK은 이웃 확인까지 끝난 상태다.

</details>

<details markdown="block">
<summary>8. BFS가 unweighted graph에서 shortest path를 구할 수 있는 이유는?</summary>

답변: BFS는 queue를 사용해 시작 정점에서 가까운 level부터 순서대로 확장한다. 처음 발견된 정점은 가장 적은 간선 수로 도달한 것이므로, $$d[v]=d[u]+1$$이 unweighted shortest path distance가 된다.

</details>

<details markdown="block">
<summary>9. DFS에서 back edge가 cycle과 연결되는 이유는?</summary>

답변: DFS 중 GRAY 정점은 현재 recursion stack 위에 있는 ancestor다. 어떤 정점 $$u$$에서 GRAY ancestor $$v$$로 가는 edge가 있으면, DFS tree path $$v\leadsto u$$와 edge $$(u,v)$$가 합쳐져 cycle을 만든다.

</details>

<details markdown="block">
<summary>10. Dijkstra에서 relaxation 조건은 무엇인가?</summary>

답변: 정점 $$u$$를 거쳐 $$v$$로 가는 비용이 현재 $$D[v]$$보다 작으면 갱신한다. 조건은 $$D[v] > D[u]+w(u,v)$$이고, 참이면 $$D[v]=D[u]+w(u,v)$$, $$\text{prev}[v]=u$$로 바꾼다.

</details>

<details markdown="block">
<summary>11. Dijkstra가 음수 간선에서 문제가 되는 이유는?</summary>

답변: Dijkstra는 가장 작은 미확정 거리 $$D[u]$$를 가진 정점을 확정하면 그 값이 더 이상 줄어들지 않는다고 가정한다. 음수 간선이 있으면 나중에 다른 경로를 통해 이미 확정한 정점의 거리가 더 작아질 수 있으므로 이 greedy 선택이 깨진다.

</details>

<details markdown="block">
<summary markdown="span">12. Dijkstra와 Prim의 $$D[v]$$는 왜 다르게 해석해야 하는가?</summary>

답변: Dijkstra의 $$D[v]$$는 시작 정점에서 $$v$$까지의 현재 최단 거리 추정값이다. Prim의 $$D[v]$$는 현재 MST 집합에 $$v$$를 연결하는 가장 싼 간선 비용이다. 그래서 Dijkstra는 $$D[u]+w(u,v)$$로 갱신하고, Prim은 $$w(u,v)$$ 자체로 갱신한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/ds-midterm-sol.pdf" | relative_url }}" target="_blank" rel="noopener">ds-midterm-sol.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS13_sorting.pdf" | relative_url }}" target="_blank" rel="noopener">LS13_sorting.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS14_merge_sort.pdf" | relative_url }}" target="_blank" rel="noopener">LS14_merge_sort.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS15_quick_sort_R1.pdf" | relative_url }}" target="_blank" rel="noopener">LS15_quick_sort_R1.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS16_priority_queue_and_heap.pdf" | relative_url }}" target="_blank" rel="noopener">LS16_priority_queue_and_heap.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS17_heap_sort.pdf" | relative_url }}" target="_blank" rel="noopener">LS17_heap_sort.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS18_hash_search.pdf" | relative_url }}" target="_blank" rel="noopener">LS18_hash_search.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS19_hash_search_2.pdf" | relative_url }}" target="_blank" rel="noopener">LS19_hash_search_2.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS20_graph.pdf" | relative_url }}" target="_blank" rel="noopener">LS20_graph.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS21_graph_traversal.pdf" | relative_url }}" target="_blank" rel="noopener">LS21_graph_traversal.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS22_shortest_path.pdf" | relative_url }}" target="_blank" rel="noopener">LS22_shortest_path.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS23_minimum_spanning_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS23_minimum_spanning_tree.pdf</a></li>
</ul>
