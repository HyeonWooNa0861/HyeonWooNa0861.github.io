---
layout: default
date: 2026-06-01 12:25:13 +0900
title: "LS21 Graph Traversal"
course: "Data Structures"
topic: "Graph Traversal"
order: 21
major_topic: "Data Structures & Algorithms"
keywords:
  - "Graph Traversal"
  - "BFS"
  - "DFS"
  - "Visited Set"
  - "Traversal Order"
---

# LS21 Graph Traversal

Source PDF: `LS21_graph_traversal.pdf`

> **핵심:** **graph traversal** 그래프의 정점을 방문하며 구조를 파악하는 절차. **BFS** queue를 사용해 시작 정점에서 가까운 정점부터 방문.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 그래프 순회 | 모든 정점을 정확히 한 번씩 방문한다는 말은 무엇인가? |
| 2 | 순회의 활용 | 최단 경로, 연결 요소, 네트워크 분석과 어떻게 연결되는가? |
| 3 | 방문 상태 | WHITE, GRAY, BLACK은 각각 어떤 상태를 뜻하는가? |
| 4 | BFS | 가까운 정점부터 level별로 방문하려면 어떤 구조가 필요한가? |
| 5 | BFS 알고리즘 | queue와 거리 \(d\)는 어떤 순서로 갱신되는가? |
| 6 | BFS 복잡도 | 왜 인접 리스트 기준 \(O(\lvert V\rvert+\lvert E\rvert)\)인가? |
| 7 | DFS | 가능한 한 깊게 내려갔다가 되돌아오는 구조는 무엇인가? |
| 8 | DFS 알고리즘 | discovery time, finish time, predecessor는 언제 기록되는가? |
| 9 | DFS edge 분류 | tree, back, forward, cross edge는 어떻게 구분되는가? |
| 10 | BFS vs DFS | 두 순회 방식은 목적과 방문 순서가 어떻게 다른가? |

21강은 그래프 위에서 정점을 방문하는 기본 방법인 BFS와 DFS를 다룬다. 핵심은 단순히 "방문한다"가 아니라, 어떤 순서로 방문하고, 방문 상태를 어떻게 관리하며, 그 결과로 거리, predecessor, discovery/finish time 같은 정보를 얻는지다.

## 1. 그래프 순회란?

그래프 순회(graph traversal)는 그래프에 존재하는 정점들을 방문하는 절차다. 강의에서는 모든 정점을 정확히 한 번씩 방문하는 과정으로 설명한다.

그래프는

$$
G=(V,E)
$$

로 표현되고, \(V\)는 정점 집합, \(E\)는 간선 집합이다. 순회 알고리즘은 이 정점과 간선을 따라가며 그래프의 구조를 파악한다.

그래프 순회는 단독 주제로 끝나지 않고 여러 알고리즘의 기반이 된다.

| 활용 | 순회가 필요한 이유 |
|---|---|
| 최단 경로 | 시작 정점에서 다른 정점까지 얼마나 멀리 있는지 탐색 |
| 연결 요소 찾기 | 그래프가 몇 개의 연결된 덩어리로 나뉘는지 확인 |
| 네트워크 분석 | 영향이나 정보가 어떤 정점으로 확산되는지 추적 |
| cycle 탐지 | 방문 상태를 이용해 되돌아가는 간선을 찾음 |
| 위상 정렬 | DFS finish time을 이용해 의존 순서를 계산 |

대표적인 그래프 순회 기법은 BFS와 DFS다.

| 알고리즘 | 한국어 | 핵심 방향 |
|---|---|---|
| BFS | 너비 우선 탐색 | 가까운 정점부터 level별로 방문 |
| DFS | 깊이 우선 탐색 | 한 경로를 가능한 깊게 따라간 뒤 되돌아옴 |

## 2. 방문 상태: WHITE, GRAY, BLACK

BFS와 DFS는 정점의 방문 상태를 색으로 관리한다. 이 색은 실제 색깔이라기보다 algorithm state를 나타내는 표식이다.

| 색 | 의미 | 직관 |
|---|---|---|
| WHITE | 아직 방문되지 않음 | 발견 전 |
| GRAY | 발견되었지만 아직 처리 완료 전 | queue 안에 있거나 recursion stack에 있음 |
| BLACK | 처리 완료 | 해당 정점 기준 이웃 확인이 끝남 |

BFS에서는 GRAY 정점이 queue에 들어가 있는 정점이라고 보면 된다. DFS에서는 GRAY 정점이 현재 recursion path 위에 있는 정점이라고 보면 된다.

BLACK이 되었다는 것은 그 정점에서 확인해야 할 인접 정점들을 모두 확인했다는 뜻이다.

## 3. BFS의 핵심 아이디어

BFS(Breadth-First Search)는 시작 정점에서 가까운 정점부터 먼 정점 순서로 방문한다. 여기서 거리는 간선 개수 기준의 거리다.

시작 정점 \(s\)의 거리는 0이다.

$$
s.d=0
$$

시작 정점과 간선 하나로 연결된 정점들은 거리 1, 그다음 level의 정점들은 거리 2가 된다.

$$
v.d=u.d+1
$$

BFS는 이 level 순서를 지키기 위해 queue를 사용한다. 먼저 발견된 정점이 먼저 처리되는 FIFO 구조 덕분에 가까운 정점들이 먼저 확장된다.

| 자료구조 | BFS에서의 역할 |
|---|---|
| queue \(Q\) | 발견했지만 아직 이웃을 모두 확인하지 않은 정점을 저장 |
| distance \(d\) | 시작 정점으로부터의 간선 수 |
| color | 방문 전, 발견됨, 완료 상태를 구분 |

## 4. BFS 알고리즘

강의의 BFS 의사코드는 다음 흐름으로 정리할 수 있다.

```text
BFS(G, s)
    for each vertex u in G.V - {s}
        u.color = WHITE
        u.d = infinity

    s.color = GRAY
    s.d = 0

    Q = empty queue
    Enqueue(Q, s)

    while Q is not empty
        u = Dequeue(Q)
        for each v in G.Adj[u]
            if v.color == WHITE
                v.color = GRAY
                v.d = u.d + 1
                Enqueue(Q, v)
        u.color = BLACK
```

핵심은 정점을 발견하는 순간 WHITE에서 GRAY로 바꾸고 queue에 넣는다는 점이다. 이렇게 해야 같은 정점이 여러 번 queue에 들어가는 것을 막을 수 있다.

\(u\)의 이웃 \(v\)를 처음 발견하면 \(v.d=u.d+1\)로 갱신한다. 이것이 BFS가 unweighted graph에서 최단 거리, 즉 최소 간선 수를 구할 수 있는 이유다.

## 5. BFS에서 queue가 만드는 level 순서

BFS는 queue의 head에서 정점을 하나 꺼내고, 그 정점의 WHITE 이웃들을 queue 뒤에 넣는다. 따라서 이미 queue에 있던 같은 level 정점들이 먼저 처리되고, 그다음 level 정점들이 나중에 처리된다.

예를 들어 시작 정점 \(s\)에서 출발하면 다음 순서로 level이 만들어진다.

| level | 의미 |
|---|---|
| 0 | 시작 정점 \(s\) |
| 1 | \(s\)와 간선 하나로 연결된 정점 |
| 2 | level 1 정점을 거쳐 도달하는 미방문 정점 |
| 3 | level 2 정점을 거쳐 도달하는 미방문 정점 |

그래서 BFS의 거리값 \(d\)는 unweighted graph에서 시작 정점으로부터의 shortest path length와 같다.

단, 가중치가 있는 그래프에서는 단순 BFS가 최단 비용 경로를 보장하지 않는다. 간선 개수가 적어도 weight 합이 클 수 있기 때문이다. 가중치 최단 경로는 이후 Dijkstra 같은 알고리즘이 필요하다.

## 6. BFS의 시간 복잡도

BFS는 초기화에서 모든 정점을 한 번씩 본다.

$$
O(\lvert V\rvert)
$$

순회 과정에서는 각 정점이 한 번 GRAY가 되고, 한 번 queue에서 빠져 BLACK이 된다. 따라서 정점 처리 비용은 \(O(\lvert V\rvert)\)이다.

간선은 인접 리스트를 따라 확인된다.

| 그래프 종류 | 간선 확인 횟수 |
|---|---|
| 무향 그래프 | 간선 하나가 양쪽 정점 리스트에 나타나므로 약 \(2\lvert E\rvert\)번 |
| 유향 그래프 | 각 directed edge가 한 번씩 나타나므로 \(\lvert E\rvert\)번 |

Big-O에서는 상수 2를 무시하므로 전체 순회 비용은 다음과 같다.

$$
O(\lvert V\rvert+\lvert E\rvert)
$$

이 복잡도는 인접 리스트 표현을 기준으로 한다. 인접 행렬을 쓰면 한 정점의 이웃을 찾기 위해 행 전체를 보아야 하므로 비용 해석이 달라진다.

## 7. DFS의 핵심 아이디어

DFS(Depth-First Search)는 현재 정점에서 갈 수 있는 정점이 있으면 가능한 한 깊게 내려간다. 더 이상 갈 WHITE 이웃이 없으면 이전 정점으로 되돌아온다.

이 구조는 backtracking을 기반으로 한다.

| 개념 | DFS에서의 의미 |
|---|---|
| 깊게 내려감 | WHITE 이웃을 발견하면 즉시 재귀 호출 |
| 되돌아옴 | 더 이상 방문할 이웃이 없으면 현재 정점을 완료 |
| recursion stack | 현재 탐색 중인 경로를 저장 |
| predecessor \(\pi\) | DFS tree에서 부모 정점 |

BFS가 queue를 사용해 level 순서를 유지한다면, DFS는 recursion 또는 stack을 사용해 한 경로를 끝까지 따라간다.

## 8. DFS 알고리즘

DFS는 전체 그래프를 대상으로 실행된다. 그래프가 disconnected일 수 있으므로 모든 정점을 확인하면서 WHITE 정점이 보이면 새 DFS tree를 시작한다.

```text
DFS(G)
    for each vertex u in G.V
        u.color = WHITE
        u.pi = NIL

    time = 0

    for each vertex u in G.V
        if u.color == WHITE
            DFS-Visit(G, u)
```

실제 깊이 탐색은 `DFS-Visit`에서 수행된다.

```text
DFS-Visit(G, u)
    time = time + 1
    u.d = time
    u.color = GRAY

    for each vertex v in G.Adj[u]
        if v.color == WHITE
            v.pi = u
            DFS-Visit(G, v)

    u.color = BLACK
    time = time + 1
    u.f = time
```

여기서 \(u.d\)는 discovery time, \(u.f\)는 finish time이다.

| 값 | 기록 시점 | 의미 |
|---|---|---|
| \(u.d\) | 정점 \(u\)를 처음 발견했을 때 | discovery time |
| \(u.f\) | \(u\)의 모든 이웃 처리가 끝났을 때 | finish time |
| \(u.\pi\) | \(u\)를 처음 발견하게 한 정점 | predecessor |

항상 다음 관계가 성립한다.

$$
u.d < u.f
$$

## 9. DFS의 discovery/finish time

DFS에서 GRAY 정점은 현재 recursion stack 위에 있는 정점이다. BLACK이 되는 순간은 그 정점의 모든 outgoing edge를 확인한 뒤다.

따라서 DFS time interval \([u.d,u.f]\)는 정점 \(u\)가 recursion stack에 머문 시간 구간처럼 볼 수 있다.

DFS tree에서 부모와 자식 사이의 time interval은 포함 관계를 가진다. 예를 들어 \(v\)가 \(u\)의 descendant라면 다음이 성립한다.

$$
u.d < v.d < v.f < u.f
$$

반대로 서로 다른 DFS subtree에 속한 두 정점의 interval은 겹치지 않는다. 이 discovery/finish time은 edge 분류, cycle 탐지, topological sort 같은 알고리즘의 핵심 재료가 된다.

## 10. DFS edge 분류

DFS는 directed graph에서 간선을 여러 종류로 분류할 수 있다. 강의에서는 back edge, forward edge, cross edge를 그림으로 보여준다. 여기에 DFS tree를 만드는 tree edge까지 함께 정리하면 다음과 같다.

| edge 종류 | 의미 |
|---|---|
| tree edge | WHITE 정점을 처음 발견하게 만든 간선 |
| back edge | 정점에서 자신의 ancestor로 향하는 간선 |
| forward edge | ancestor에서 descendant로 향하지만 tree edge는 아닌 간선 |
| cross edge | 서로 다른 DFS subtree 또는 ancestor-descendant 관계가 아닌 정점 사이의 간선 |

DFS edge 분류는 "간선 \((u,v)\)를 검사하는 순간 \(v\)가 어떤 상태인가"와 "DFS tree에서 \(u\), \(v\)가 어떤 관계인가"로 이해하면 쉽다.

| edge 종류 | 검사 시점의 \(v\) 상태 | DFS tree 관계 | discovery/finish time 관계 |
|---|---|---|---|
| tree edge | WHITE | \(u\)가 \(v\)를 처음 발견 | \(u.d < v.d < v.f < u.f\) |
| back edge | GRAY | \(v\)가 \(u\)의 ancestor | \(v.d < u.d < u.f < v.f\) |
| forward edge | BLACK | \(v\)가 \(u\)의 descendant이지만 tree edge는 아님 | \(u.d < v.d < v.f < u.f\) |
| cross edge | BLACK | ancestor-descendant 관계가 아님 | 두 time interval이 서로 겹치지 않음 |

### Back Edge

Back edge는 현재 정점 \(u\)에서 DFS tree의 ancestor \(v\)로 돌아가는 간선이다.

```text
ancestor v
   |
   ...
   |
current u  --back edge-->  v
```

DFS 중 \(u\)에서 이웃 \(v\)를 보았는데 \(v\)가 아직 BLACK이 아니라 GRAY라면, \(v\)는 현재 recursion stack 위에 있다. 즉, \(v\)는 \(u\)의 ancestor다.

그래서 back edge의 time interval은 ancestor interval이 descendant interval을 감싼다.

$$
v.d < u.d < u.f < v.f
$$

특히 directed graph에서 back edge는 cycle 존재와 연결된다. 이미 \(v\)에서 \(u\)까지 내려온 tree path가 있고, 다시 \(u\to v\)로 돌아가는 edge가 있으므로 directed cycle이 만들어진다.

### Forward Edge

Forward edge는 ancestor에서 descendant로 향하지만, 그 descendant를 처음 발견하게 만든 tree edge는 아닌 간선이다.

```text
ancestor u  --forward edge-->  descendant v
```

예를 들어 \(u\)에서 다른 경로를 통해 이미 \(v\)를 발견했고, 이후 \(u\)의 adjacency list를 보다가 \(v\)로 가는 추가 간선을 확인하면 forward edge가 될 수 있다.

Forward edge도 ancestor-descendant 관계이므로 time interval은 tree edge와 같은 포함 관계를 가진다.

$$
u.d < v.d < v.f < u.f
$$

차이는 \(v\)를 처음 발견하게 만든 간선이면 tree edge이고, 이미 DFS tree 안에 descendant로 들어간 뒤 발견된 추가 간선이면 forward edge라는 점이다.

### Cross Edge

Cross edge는 서로 ancestor-descendant 관계가 아닌 정점 사이의 간선이다. 보통 서로 다른 DFS subtree 사이를 잇거나, 이미 탐색이 끝난 정점으로 향하는 간선으로 나타난다.

```text
subtree A의 u  --cross edge-->  subtree B의 v
```

Cross edge에서는 두 정점의 DFS time interval이 포함 관계를 만들지 않는다. 한쪽 정점의 탐색이 완전히 끝난 뒤 다른 정점의 탐색이 시작된 형태로 볼 수 있다.

$$
v.d < v.f < u.d < u.f
\quad\text{or}\quad
u.d < u.f < v.d < v.f
$$

단, 실제 DFS에서 \((u,v)\)를 검사하는 시점에는 \(u\)가 GRAY이므로, 이미 끝난 \(v\)를 보는 경우가 cross edge로 자주 나타난다.

### 무향 그래프에서의 주의점

무향 그래프에서는 같은 간선이 양쪽 adjacency list에 모두 나타난다. 그래서 DFS edge 분류가 directed graph처럼 네 종류로 깔끔하게 나뉘지 않는다. 표준 DFS 관점에서는 무향 그래프의 간선은 보통 tree edge 또는 back edge로만 나타난다고 이해하면 된다. Forward edge와 cross edge는 directed graph에서 특히 의미가 크다.

## 11. DFS의 시간 복잡도

DFS도 초기화에서 모든 정점을 한 번씩 본다.

$$
O(\lvert V\rvert)
$$

DFS-Visit 과정에서는 각 정점이 WHITE에서 GRAY, BLACK으로 한 번씩만 변한다. 각 adjacency list도 한 번씩 순회한다.

| 그래프 종류 | 간선 확인 횟수 |
|---|---|
| 무향 그래프 | 각 간선이 양쪽 리스트에 있어 \(2\lvert E\rvert\)번 확인 |
| 유향 그래프 | 각 directed edge를 한 번씩 확인 |

따라서 인접 리스트 기준 DFS의 전체 시간 복잡도는 다음과 같다.

$$
O(\lvert V\rvert+\lvert E\rvert)
$$

공간 복잡도는 그래프 저장 공간을 제외하면 recursion stack에 의해 최악의 경우 \(O(\lvert V\rvert)\)가 필요할 수 있다.

## 12. BFS와 DFS 비교

| 기준 | BFS | DFS |
|---|---|---|
| 핵심 방향 | 가까운 정점부터 level별 탐색 | 한 경로를 가능한 깊게 탐색 |
| 주요 자료구조 | queue | recursion 또는 stack |
| 방문 상태 | WHITE, GRAY, BLACK | WHITE, GRAY, BLACK |
| 대표 기록값 | 거리 \(d\) | discovery \(d\), finish \(f\), predecessor \(\pi\) |
| unweighted shortest path | 가능 | 일반적으로 보장하지 않음 |
| 주요 활용 | 최단 간선 수, 연결 요소, level structure | cycle 탐지, topological sort, SCC, edge classification |
| 시간 복잡도 | \(O(\lvert V\rvert+\lvert E\rvert)\) | \(O(\lvert V\rvert+\lvert E\rvert)\) |

BFS는 거리와 level을 알고 싶을 때 강하다. DFS는 그래프의 깊은 구조, 의존 관계, cycle, finish order를 알고 싶을 때 강하다.

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| graph traversal | 그래프의 정점을 방문하며 구조를 파악하는 절차 |
| BFS | queue를 사용해 시작 정점에서 가까운 정점부터 방문 |
| BFS distance | unweighted graph에서 시작 정점으로부터의 최단 간선 수 |
| DFS | recursion/backtracking으로 가능한 깊게 내려가는 탐색 |
| DFS discovery time | 정점을 처음 발견한 시각 |
| DFS finish time | 정점의 모든 이웃 처리가 끝난 시각 |
| back edge | DFS tree의 descendant에서 ancestor로 돌아가는 간선 |
| forward edge | ancestor에서 descendant로 가지만 tree edge는 아닌 간선 |
| cross edge | ancestor-descendant 관계가 아닌 정점 사이의 간선 |
| WHITE | 아직 발견되지 않은 정점 |
| GRAY | 발견되었지만 아직 완료되지 않은 정점 |
| BLACK | 이웃 처리가 끝난 정점 |
| complexity | 인접 리스트 기준 BFS와 DFS 모두 \(O(\lvert V\rvert+\lvert E\rvert)\) |

## Study Guide

먼저 BFS와 DFS의 차이를 "자료구조"로 기억하면 좋다. BFS는 queue, DFS는 recursion 또는 stack이다. 이 차이가 곧 방문 순서의 차이를 만든다.

두 번째로 색의 의미를 정확히 잡아야 한다. WHITE는 미발견, GRAY는 발견되었지만 처리 중, BLACK은 완료다. BFS에서는 GRAY가 queue 안의 정점이고, DFS에서는 GRAY가 recursion stack 위의 정점이다.

세 번째로 복잡도 \(O(\lvert V\rvert+\lvert E\rvert)\)의 이유를 설명할 수 있어야 한다. 모든 정점은 한 번 방문되고, 인접 리스트의 모든 간선 항목은 전체적으로 한 번씩 확인되기 때문이다.

| 시험 대비 포인트 | 확인할 내용 |
|---|---|
| BFS 방문 순서 | level 순서, queue 사용 |
| BFS 거리값 | \(v.d=u.d+1\), unweighted shortest path |
| DFS 방문 순서 | 깊게 내려간 뒤 backtracking |
| DFS time | discovery time과 finish time의 기록 시점 |
| color state | WHITE, GRAY, BLACK의 정확한 의미 |
| complexity | 정점과 간선을 각각 몇 번 보는지 |
| edge classification | tree, back, forward, cross edge의 DFS tree 관계와 time interval |

## 복습 질문

<details>
<summary>1. BFS가 queue를 사용하는 이유는 무엇인가?</summary>

답변: BFS는 시작 정점에서 가까운 정점부터 level 순서로 방문해야 한다. Queue는 먼저 발견된 정점을 먼저 처리하는 FIFO 구조이므로, 같은 level의 정점들이 먼저 처리되고 그다음 level 정점들이 뒤따라 처리된다.

</details>

<details>
<summary>2. BFS에서 정점을 발견하자마자 GRAY로 바꾸는 이유는?</summary>

답변: 같은 정점이 여러 이웃을 통해 반복해서 queue에 들어가는 것을 막기 위해서다. WHITE인 정점만 처음 발견된 것이므로, 발견 순간 GRAY로 바꾸고 queue에 넣어야 중복 방문을 피할 수 있다.

</details>

<details>
<summary>3. BFS의 \(v.d=u.d+1\)은 무엇을 의미하는가?</summary>

답변: 정점 \(u\)에서 이웃 \(v\)를 처음 발견했다면, \(v\)는 시작 정점에서 \(u\)까지의 거리보다 간선 하나 더 먼 level에 있다. 따라서 \(v.d=u.d+1\)로 설정한다. Unweighted graph에서는 이 값이 시작 정점으로부터의 최단 간선 수가 된다.

</details>

<details>
<summary>4. DFS에서 discovery time과 finish time은 각각 언제 기록되는가?</summary>

답변: discovery time \(u.d\)는 정점 \(u\)를 처음 발견해 GRAY로 만들 때 기록한다. finish time \(u.f\)는 \(u\)의 모든 인접 정점 처리가 끝나고 \(u\)를 BLACK으로 만들 때 기록한다.

</details>

<details>
<summary>5. DFS에서 GRAY 정점은 어떤 의미인가?</summary>

답변: DFS에서 GRAY 정점은 현재 recursion stack 위에 있는 정점이다. 아직 그 정점의 모든 이웃 처리가 끝나지 않았으므로 탐색이 진행 중인 상태다.

</details>

<details>
<summary>6. BFS와 DFS의 시간 복잡도가 둘 다 \(O(\lvert V\rvert+\lvert E\rvert)\)인 이유는?</summary>

답변: 두 알고리즘 모두 모든 정점을 한 번씩 발견하고 처리한다. 또한 인접 리스트를 기준으로 각 간선 항목을 전체적으로 한 번씩 확인한다. 무향 그래프에서는 한 간선이 두 리스트에 나타나지만 \(2\lvert E\rvert\)는 Big-O에서 \(O(\lvert E\rvert)\)로 정리된다.

</details>

<details>
<summary>7. Directed graph에서 back edge가 cycle과 관련되는 이유는?</summary>

답변: Back edge는 현재 정점에서 DFS tree의 ancestor로 향하는 간선이다. 현재 정점까지 내려온 tree path와 ancestor로 돌아가는 back edge를 합치면 directed cycle이 만들어진다. 따라서 DFS 중 back edge 발견은 cycle 존재의 중요한 신호다.

</details>

<details>
<summary>8. Unweighted shortest path를 찾을 때 DFS보다 BFS가 적합한 이유는?</summary>

답변: BFS는 시작 정점에서 거리 0, 1, 2 순서로 level별 탐색을 하므로 어떤 정점을 처음 발견하는 순간의 거리값이 최단 간선 수다. DFS는 한 경로를 깊게 따라가기 때문에 먼저 발견한 경로가 최단 경로라는 보장이 없다.

</details>

<details>
<summary>9. Forward edge와 cross edge는 어떻게 구분하는가?</summary>

답변: Forward edge는 \(u\)에서 descendant \(v\)로 향하지만 tree edge는 아닌 간선이다. 따라서 \(u.d < v.d < v.f < u.f\)처럼 \(v\)의 time interval이 \(u\) 안에 포함된다. Cross edge는 ancestor-descendant 관계가 아닌 정점 사이의 간선이므로 두 정점의 time interval이 서로 겹치지 않는다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS21_graph_traversal.pdf" | relative_url }}" target="_blank" rel="noopener">LS21_graph_traversal.pdf</a></li>
</ul>
