---
layout: default
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

## 전체 흐름

| 문항 | 예상 유형 | 핵심 범위 | 답안에서 보여야 하는 것 |
|---:|---|---|---|
| 1 | OX 및 객관식 | sorting, hashing, graph 전반 | 정의, 시간복잡도, 장단점, 반례를 빠르게 판단 |
| 2 | 주관식 | heap sort | buildHeap, swap root-last, heap size 감소, siftDown 추적 |
| 3 | 주관식 및 서술형 | graph representation, BFS, DFS | adjacency matrix/list 작성, queue/stack/색/distance/time 추적 |
| 4 | 주관식 및 서술형 | shortest path | Dijkstra의 \\(D\\), \\(S\\), \\(\text{prev}\\), relaxation 표 작성 |

중간고사 솔루션에서 배울 점은 단순하다. 정답만 쓰는 것이 아니라, 왜 그 답이 되는지 한 줄 근거를 붙여야 한다. 특히 서술형은 최종 결과보다 중간 상태 표가 채점의 핵심이 될 수 있다.

## 1. OX 및 객관식 대비

1번은 범위가 넓게 나올 수 있다. 외울 때는 알고리즘 이름만 보지 말고, "어떤 조건에서 맞는 말인가"를 같이 외워야 한다.

### Sorting 핵심 판별표

| 알고리즘 | 평균 시간 | 최악 시간 | 공간 | Stable | 핵심 포인트 |
|---|---|---|---|---|---|
| Bubble sort | \\(O(n^2)\\) | \\(O(n^2)\\) | \\(O(1)\\) | 보통 stable | 인접 원소를 비교하며 큰 값을 뒤로 보냄 |
| Selection sort | \\(O(n^2)\\) | \\(O(n^2)\\) | \\(O(1)\\) | 보통 unstable | 매번 최솟값/최댓값을 선택, swap 수가 적음 |
| Insertion sort | \\(O(n^2)\\) | \\(O(n^2)\\) | \\(O(1)\\) | stable | 거의 정렬된 배열에서 \\(O(n)\\)에 가까움 |
| Merge sort | \\(O(n\log n)\\) | \\(O(n\log n)\\) | \\(O(n)\\) | 구현에 따라 stable | divide, conquer, merge |
| Quick sort | \\(O(n\log n)\\) | \\(O(n^2)\\) | 평균 \\(O(\log n)\\) | 보통 unstable | pivot 선택이 성능을 좌우 |
| Heap sort | \\(O(n\log n)\\) | \\(O(n\log n)\\) | \\(O(1)\\) | unstable | max heap으로 최댓값을 오른쪽부터 확정 |

객관식에서 자주 흔들리는 지점은 다음이다.

| 헷갈리는 문장 | 판별 |
|---|---|
| "Merge sort는 항상 in-place다." | 거짓. 일반적인 merge sort는 추가 배열 \\(O(n)\\)을 사용한다. |
| "Quick sort는 항상 \\(O(n\log n)\\)이다." | 거짓. pivot이 계속 나쁘게 잡히면 최악 \\(O(n^2)\\)이다. |
| "Heap sort는 최악 시간도 \\(O(n\log n)\\)이다." | 참. buildHeap \\(O(n)\\), removeMax 반복 \\(O(n\log n)\\)이다. |
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
| Linear probing | \\(h_i(k)=(h(k)+i)\bmod m\\) | 구현은 쉽지만 primary clustering |
| Constant step | \\(h_i(k)=(h(k)+ic)\bmod m\\) | \\(c\\)와 \\(m\\)이 서로소여야 전체 슬롯 방문 가능 |
| Quadratic probing | \\(h_i(k)=(h(k)+i^2)\bmod m\\) | primary clustering 완화, secondary clustering 가능 |
| Double hashing | \\(h_i(k)=(h(k)+i h_2(k))\bmod m\\) | key마다 probe sequence가 달라 clustering 완화 |

Load factor는 closed hashing 성능을 좌우한다.

$$
\alpha=\frac{s}{m}
$$

여기서 \\(s\\)는 저장된 item 수, \\(m\\)은 table size다. \\(\alpha\\)가 1에 가까워질수록 빈 슬롯을 찾기 어려워지고 probe 횟수가 급격히 증가한다.

### Graph 핵심 판별표

그래프는 정점과 간선의 집합이다.

$$
G=(V,E)
$$

| 개념 | 핵심 정의 | 시험 포인트 |
|---|---|---|
| Undirected graph | 간선에 방향이 없음 | \\((u,v)\\)와 \\((v,u)\\)를 같은 관계로 봄 |
| Directed graph | 간선에 방향이 있음 | in-degree, out-degree 구분 |
| Weighted graph | 간선에 weight가 있음 | 경로 길이는 weight 합 |
| Path | 간선을 따라 이어지는 정점열 | 반복 정점이 없으면 simple path |
| Cycle | 시작과 끝이 같은 path | DFS back edge와 cycle detection 연결 |
| Tree | 연결되고 cycle이 없는 graph | 정점 \\(\lvert V\rvert\\)개면 간선 \\(\lvert V\rvert-1\\)개 |
| Connected component | 무향 그래프의 연결된 덩어리 | BFS/DFS로 찾을 수 있음 |
| SCC | 유향 그래프에서 서로 도달 가능한 정점 집합 | connected component와 다름 |

그래프 표현은 인접 행렬과 인접 리스트를 비교해서 외운다.

| 표현 | 공간 | 간선 존재 확인 | 모든 이웃 순회 | 유리한 경우 |
|---|---|---|---|---|
| Adjacency matrix | \\(O(\lvert V\rvert^2)\\) | \\(O(1)\\) | 한 행 스캔 \\(O(\lvert V\rvert)\\) | dense graph, 간선 존재 확인이 잦을 때 |
| Adjacency list | \\(O(\lvert V\rvert+\lvert E\rvert)\\) | \\(O(\deg(v))\\) | \\(O(\deg(v))\\) | sparse graph, BFS/DFS/Dijkstra |

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
| parent | \\(\left\lfloor (i-1)/2 \right\rfloor\\) |
| left child | \\(2i+1\\) |
| right child | \\(2i+2\\) |

1-indexed array를 쓰는 문제라면 left child는 \\(2i\\), right child는 \\(2i+1\\)이다. 시험에서 배열 index 기준을 먼저 확인해야 한다.

### 답안 표 템플릿

| 단계 | heap size | 수행 | 배열 상태 | sorted area |
|---:|---:|---|---|---|
| 0 | \\(n\\) | buildHeap 완료 | 문제 배열을 max heap으로 변환 | 없음 |
| 1 | \\(n-1\\) | root와 last swap 후 siftDown | 갱신된 배열 | 오른쪽 1개 |
| 2 | \\(n-2\\) | root와 last swap 후 siftDown | 갱신된 배열 | 오른쪽 2개 |

채점에서 중요한 설명은 다음이다.

| 질문 | 답 |
|---|---|
| buildHeap 시간은 왜 \\(O(n)\\)인가? | 대부분의 노드는 리프 근처에 있어 siftDown 거리가 짧기 때문이다. |
| 전체 heap sort 시간은? | buildHeap \\(O(n)\\) + removeMax \\(n\\)번 \\(O(\log n)\\)이므로 \\(O(n\log n)\\) |
| 추가 공간은? | 배열 내부에서 swap하므로 일반 구현은 \\(O(1)\\) |
| stable한가? | 일반적인 heap sort는 stable하지 않다. |

## 3. Graph Representation 및 Traversal 대비

그래프 서술형은 주어진 그래프를 저장 구조로 바꾸거나, BFS/DFS를 직접 추적하는 형태가 자연스럽다.

### Graph Representation

정점이 \\(A,B,C,D\\)이고 간선이 주어지면 먼저 방향성과 weight를 확인한다.

| 조건 | 인접 행렬 작성법 |
|---|---|
| 무향 그래프 | \\(M[u][v]\\)와 \\(M[v][u]\\)를 같이 표시 |
| 유향 그래프 | 방향 그대로 \\(M[u][v]\\)만 표시 |
| 가중치 그래프 | 간선이 있으면 weight, 없으면 \\(0\\), \\(\infty\\), 또는 blank 등 문제 지시를 따름 |

인접 리스트는 각 정점 옆에 이웃을 나열한다.

```text
A: B, C
B: D
C: D
D:
```

문제에서 방문 순서가 중요하면 adjacency list의 이웃 순서를 그대로 따라야 한다. 같은 그래프라도 이웃을 확인하는 순서가 다르면 BFS/DFS 방문 순서가 달라질 수 있다.

### BFS 추적

BFS는 queue를 사용한다. 시작 정점 \\(s\\)의 거리는 0이고, 처음 발견한 이웃은 거리 \\(u.d+1\\)을 갖는다.

| 상태 | 의미 |
|---|---|
| WHITE | 아직 발견되지 않음 |
| GRAY | 발견되었고 queue에 들어 있음 |
| BLACK | 이웃 확인까지 완료 |

BFS 답안 표는 다음 형태로 쓰면 좋다.

| 단계 | dequeue | 새로 발견한 정점 | queue | distance 갱신 |
|---:|---|---|---|---|
| 0 | - | 시작 정점 \\(s\\) | \\([s]\\) | \\(d[s]=0\\) |
| 1 | \\(s\\) | \\(s\\)의 WHITE 이웃 | 갱신된 queue | \\(d[v]=d[s]+1\\) |

BFS는 unweighted graph에서 시작 정점으로부터의 최단 간선 수를 구한다. 가중치가 있는 그래프의 최소 비용 문제에는 Dijkstra가 필요하다.

### DFS 추적

DFS는 가능한 한 깊게 내려갔다가 되돌아온다. recursive DFS에서는 discovery time과 finish time을 기록할 수 있다.

| 값 | 기록 시점 |
|---|---|
| \\(u.d\\) | 정점 \\(u\\)를 처음 발견했을 때 |
| \\(u.f\\) | \\(u\\)의 모든 이웃 처리가 끝났을 때 |
| \\(u.\pi\\) | \\(u\\)를 처음 발견하게 한 predecessor |

Directed graph의 DFS edge 분류는 꼭 구분해야 한다.

| edge 종류 | 검사 시점/관계 | 핵심 판별 |
|---|---|---|
| Tree edge | WHITE 정점을 처음 발견 | DFS tree의 부모-자식 간선 |
| Back edge | GRAY ancestor로 향함 | directed graph에서 cycle 존재와 연결 |
| Forward edge | BLACK descendant로 향하지만 tree edge 아님 | ancestor에서 descendant로 가는 non-tree edge |
| Cross edge | ancestor-descendant 관계가 아님 | 서로 다른 subtree 또는 이미 끝난 영역으로 감 |

## 4. Shortest Path 대비

최단 경로 문제는 LS22의 Dijkstra가 중심이다. 답안에서는 최종 거리만 쓰지 말고, \\(S\\), \\(D\\), \\(\text{prev}\\)가 어떻게 바뀌는지 보여야 한다.

### Dijkstra 전제

Dijkstra는 모든 edge weight가 음수가 아닐 때 사용한다.

$$
w(u,v)\ge 0
$$

음수 간선이 있으면 이미 확정한 정점의 거리가 나중에 더 작아질 수 있으므로 Dijkstra의 greedy 선택이 깨질 수 있다.

### 상태 변수

| 기호 | 의미 |
|---|---|
| \\(S\\) | 최단 거리가 확정된 정점 집합 |
| \\(D[v]\\) | 현재까지 알려진 시작 정점에서 \\(v\\)까지의 최단 거리 추정값 |
| \\(\text{prev}[v]\\) | 현재 최단 경로에서 \\(v\\) 바로 앞 정점 |

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

| 단계 | 선택 정점 \\(u\\) | 확정 집합 \\(S\\) | Relax한 간선 | \\(D\\) 변화 | \\(\text{prev}\\) 변화 |
|---:|---|---|---|---|---|
| 초기 | - | \\(\emptyset\\) | - | \\(D[s]=0\\), 나머지 \\(\infty\\) | 모두 NIL |
| 1 | 최소 \\(D\\) 정점 | \\(S\cup\{u\}\\) | \\((u,v)\\)들 | 더 짧으면 갱신 | 갱신된 \\(v\\)의 predecessor |

최단 경로 자체를 묻는다면 \\(\text{prev}\\)를 거꾸로 따라간다.

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
| 갱신 | \\(d[v]=d[u]+1\\) | \\(D[v]=D[u]+w(u,v)\\) |

## 5. MST는 어디까지 볼 것인가

사용자가 지정한 서술형 중심은 최단 경로까지다. 다만 그래프 객관식에서 Prim과 Dijkstra 비교가 나올 수 있으므로 최소한 다음만 확인한다.

| 비교 | Dijkstra | Prim |
|---|---|---|
| 목적 | 시작 정점에서 각 정점까지의 최단 거리 | 모든 정점을 최소 총비용으로 연결하는 MST |
| \\(D[v]\\) 의미 | 시작점에서 \\(v\\)까지의 현재 최단 거리 | 현재 tree에 \\(v\\)를 붙이는 최소 edge cost |
| 갱신 기준 | \\(D[u]+w(u,v)<D[v]\\) | \\(w(u,v)<D[v]\\) |
| 결과 | shortest path tree | minimum spanning tree |

즉 두 알고리즘은 표와 변수 이름이 비슷해도 최적화하는 값이 다르다.

## 마지막 핵심 정리

| 범위 | 반드시 남길 문장 |
|---|---|
| Sorting | 알고리즘별 시간복잡도, stable 여부, in-place 여부를 조건과 함께 외운다. |
| Heap sort | max heap을 만든 뒤 root와 마지막 원소를 바꾸며 오른쪽 sorted area를 키운다. |
| Hashing | collision resolution은 separate chaining과 open addressing으로 나뉜다. |
| Load factor | closed hashing에서는 \\(\alpha\\)가 커질수록 probe 비용이 급격히 증가한다. |
| Graph representation | matrix는 간선 확인이 빠르고, list는 sparse graph 순회에 효율적이다. |
| BFS | queue를 사용하며 unweighted shortest path distance를 구할 수 있다. |
| DFS | discovery/finish time과 edge classification을 추적한다. |
| Dijkstra | nonnegative weight graph에서 \\(D\\), \\(S\\), \\(\text{prev}\\)를 relaxation으로 갱신한다. |

## Study Guide

1. 먼저 1번 대비표를 보며 OX 문장에 붙일 한 줄 근거를 암기한다.
2. Heap sort는 배열 하나를 직접 골라 buildHeap 이후 root-last swap과 siftDown을 2회 이상 손으로 추적한다.
3. Graph representation은 같은 그래프를 adjacency matrix와 adjacency list로 각각 바꿔 본다.
4. BFS는 queue와 distance, DFS는 discovery/finish time과 edge type을 따로 연습한다.
5. Dijkstra는 매 단계마다 "가장 작은 미확정 \\(D\\)"를 고르고, relaxation으로 \\(D\\)와 \\(\text{prev}\\)를 갱신하는 표를 작성한다.
6. 시험 답안에는 최종 답만 쓰지 말고, 중간고사 솔루션처럼 판단 근거나 상태 변화 표를 함께 남긴다.

## 복습 질문

<details>
<summary>1. Heap sort에서 buildHeap 이후 가장 먼저 하는 일은 무엇인가?</summary>

답변: Max heap의 root에는 현재 heap 영역의 최댓값이 있다. 따라서 root와 heap 영역의 마지막 원소를 swap하고, heap size를 1 줄여 오른쪽 끝을 sorted area로 확정한다. 그 뒤 루트에서 siftDown을 수행해 남은 heap 영역의 heap property를 복구한다.

</details>

<details>
<summary>2. buildHeap이 \\(O(n\log n)\\)이 아니라 \\(O(n)\\)인 이유는?</summary>

답변: 모든 노드가 높이 \\(\log n\\)만큼 내려가는 것이 아니기 때문이다. 대부분의 노드는 리프 근처에 있어 siftDown할 거리가 짧고, 루트 근처처럼 오래 내려갈 수 있는 노드는 수가 적다. 각 노드의 높이 합을 계산하면 전체 비용은 \\(O(n)\\)이 된다.

</details>

<details>
<summary>3. Merge sort와 heap sort는 둘 다 \\(O(n\log n)\\)인데 어떤 차이가 있는가?</summary>

답변: Merge sort는 일반적으로 추가 배열 \\(O(n)\\)을 사용하고 stable하게 구현하기 쉽다. Heap sort는 추가 공간 \\(O(1)\\)로 in-place 정렬이 가능하지만 일반 구현은 stable하지 않고, 실제 캐시 효율은 quick sort보다 떨어질 수 있다.

</details>

<details>
<summary>4. Open hashing과 closed hashing을 어떻게 구분하는가?</summary>

답변: Open hashing은 separate chaining처럼 테이블 슬롯 밖에 linked list를 붙여 충돌을 처리한다. Closed hashing은 open addressing처럼 모든 item을 테이블 내부 슬롯에 저장하고, 충돌이 나면 probing으로 다른 빈 슬롯을 찾는다. 이름 때문에 open addressing과 open hashing을 혼동하지 않아야 한다.

</details>

<details>
<summary>5. Linear probing에서 primary clustering이 생기는 이유는?</summary>

답변: 충돌이 나면 연속된 다음 슬롯을 검사하므로 점유된 슬롯들이 긴 덩어리로 뭉친다. 어떤 key가 그 덩어리 안으로 해싱되면 결국 덩어리 뒤의 빈 슬롯으로 밀려나고, 그 슬롯이 채워지면서 cluster가 더 길어진다.

</details>

<details>
<summary>6. Adjacency matrix와 adjacency list 중 BFS/DFS에 보통 list가 유리한 이유는?</summary>

답변: BFS/DFS는 각 정점의 이웃을 순회한다. Adjacency list는 실제 존재하는 edge만 따라가므로 전체 비용이 \\(O(\lvert V\rvert+\lvert E\rvert)\\)이다. Sparse graph에서는 \\(\lvert E\rvert\\)가 \\(\lvert V\rvert^2\\)보다 훨씬 작기 때문에 matrix보다 효율적이다.

</details>

<details>
<summary>7. BFS에서 정점을 발견하자마자 GRAY로 바꾸는 이유는?</summary>

답변: 같은 정점이 여러 부모를 통해 다시 발견되어 queue에 중복 삽입되는 것을 막기 위해서다. WHITE은 아직 발견 전, GRAY는 발견되었지만 처리 중, BLACK은 이웃 확인까지 끝난 상태다.

</details>

<details>
<summary>8. BFS가 unweighted graph에서 shortest path를 구할 수 있는 이유는?</summary>

답변: BFS는 queue를 사용해 시작 정점에서 가까운 level부터 순서대로 확장한다. 처음 발견된 정점은 가장 적은 간선 수로 도달한 것이므로, \\(d[v]=d[u]+1\\)이 unweighted shortest path distance가 된다.

</details>

<details>
<summary>9. DFS에서 back edge가 cycle과 연결되는 이유는?</summary>

답변: DFS 중 GRAY 정점은 현재 recursion stack 위에 있는 ancestor다. 어떤 정점 \\(u\\)에서 GRAY ancestor \\(v\\)로 가는 edge가 있으면, DFS tree path \\(v\leadsto u\\)와 edge \\((u,v)\\)가 합쳐져 cycle을 만든다.

</details>

<details>
<summary>10. Dijkstra에서 relaxation 조건은 무엇인가?</summary>

답변: 정점 \\(u\\)를 거쳐 \\(v\\)로 가는 비용이 현재 \\(D[v]\\)보다 작으면 갱신한다. 조건은 \\(D[v] > D[u]+w(u,v)\\)이고, 참이면 \\(D[v]=D[u]+w(u,v)\\), \\(\text{prev}[v]=u\\)로 바꾼다.

</details>

<details>
<summary>11. Dijkstra가 음수 간선에서 문제가 되는 이유는?</summary>

답변: Dijkstra는 가장 작은 미확정 거리 \\(D[u]\\)를 가진 정점을 확정하면 그 값이 더 이상 줄어들지 않는다고 가정한다. 음수 간선이 있으면 나중에 다른 경로를 통해 이미 확정한 정점의 거리가 더 작아질 수 있으므로 이 greedy 선택이 깨진다.

</details>

<details>
<summary>12. Dijkstra와 Prim의 \\(D[v]\\)는 왜 다르게 해석해야 하는가?</summary>

답변: Dijkstra의 \\(D[v]\\)는 시작 정점에서 \\(v\\)까지의 현재 최단 거리 추정값이다. Prim의 \\(D[v]\\)는 현재 MST 집합에 \\(v\\)를 연결하는 가장 싼 간선 비용이다. 그래서 Dijkstra는 \\(D[u]+w(u,v)\\)로 갱신하고, Prim은 \\(w(u,v)\\) 자체로 갱신한다.

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
