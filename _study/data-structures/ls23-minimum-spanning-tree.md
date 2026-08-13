---
layout: default
title: "LS23 Minimum Spanning Tree"
course: "Data Structures"
topic: "Minimum Spanning Tree"
order: 23
major_topic: "Data Structures & Algorithms"
keywords:
  - "Minimum Spanning Tree"
  - "Kruskal Algorithm"
  - "Prim Algorithm"
  - "Union-Find"
  - "Weighted Graphs"
---

# LS23 Minimum Spanning Tree

Source PDF: `LS23_minimum_spanning_tree.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Spanning Tree | 모든 정점을 포함하는 트리 형태의 부분 그래프란 무엇인가? |
| 2 | MST Problem | 최소 비용으로 모든 정점을 연결한다는 말은 무엇인가? |
| 3 | MST 특징 | 왜 MST에는 cycle이 없고 간선 수가 \\(\lvert V\rvert-1\\)인가? |
| 4 | Prim's Algorithm | 현재 트리에서 가장 싸게 연결할 수 있는 정점을 어떻게 고르는가? |
| 5 | Prim Setup | \\(S\\), \\(D\\), \\(\text{prev}\\), \\(\text{MST}\\)는 각각 무엇을 저장하는가? |
| 6 | Update Costs | Dijkstra의 relaxation과 Prim의 cost update는 어떻게 다른가? |
| 7 | 예제 흐름 | 강의 예제의 \\(D\\) 배열은 어떤 의미로 갱신되는가? |
| 8 | Pseudocode | MST edge는 언제 추가되고, \\(\text{prev}\\)는 왜 필요한가? |
| 9 | 시간 복잡도 | 배열 스캔과 min-heap 구현은 각각 얼마가 걸리는가? |
| 10 | Dijkstra vs Prim | 두 알고리즘은 비슷해 보이지만 무엇을 최적화하는가? |

23강은 가중치가 있는 무방향 연결 그래프에서 최소 신장 트리(Minimum Spanning Tree, MST)를 찾는 문제를 다룬다. 핵심은 "한 시작점에서의 최단 거리"가 아니라 "모든 정점을 최소 총비용으로 연결하는 트리"를 찾는 것이다. 강의의 중심 알고리즘은 Prim's Algorithm이다.

## 1. Spanning Tree

신장 트리(spanning tree)는 그래프의 모든 정점을 포함하는 트리 형태의 부분 그래프다.

| 단어 | 의미 |
|---|---|
| spanning | 모든 정점을 아우름 |
| tree | 연결되어 있고 cycle이 없는 구조 |
| subgraph | 원래 그래프의 정점과 간선 일부로 만든 그래프 |

그래프 \\(G=(V,E)\\)의 spanning tree를 \\(T=(V,E_T)\\)라고 하면, 정점 집합은 원래 그래프와 같다.

$$
V(T)=V(G)
$$

하지만 간선은 원래 그래프의 간선 중 일부만 사용한다.

$$
E_T\subseteq E
$$

즉, spanning tree는 모든 정점을 빠짐없이 포함하되, cycle이 생기지 않을 만큼만 간선을 고른 구조다.

## 2. Tree 조건과 간선 수

트리는 연결되어 있고 cycle이 없는 그래프다. 정점 수가 \\(\lvert V\rvert\\)인 트리는 항상 \\(\lvert V\rvert-1\\)개의 간선을 가진다.

$$
\lvert E_T\rvert=\lvert V\rvert-1
$$

이 성질은 MST에서도 그대로 적용된다. MST는 spanning tree 중 하나이므로 모든 정점을 포함하고, cycle이 없으며, 간선 수가 \\(\lvert V\rvert-1\\)이다.

| 조건 | 설명 |
|---|---|
| 모든 정점 포함 | 그래프의 모든 정점이 tree 안에 있어야 함 |
| 연결 | tree 안의 어떤 두 정점 사이에도 경로가 있어야 함 |
| cycle 없음 | 한 바퀴 돌아오는 경로가 없어야 함 |
| 간선 수 | 정점이 \\(\lvert V\rvert\\)개이면 간선은 \\(\lvert V\rvert-1\\)개 |

Cycle이 있으면 간선을 하나 제거해도 연결성이 유지될 수 있다. 따라서 최소 비용으로 연결하는 문제에서는 cycle에 들어간 간선이 불필요한 비용이 될 가능성이 있다. MST가 tree여야 하는 이유가 여기서 나온다.

## 3. Minimum Spanning Tree

Minimum Spanning Tree는 모든 spanning tree 중 간선 가중치의 총합이 최소가 되는 트리다.

Spanning tree \\(T\\)의 총 weight는 다음처럼 계산한다.

$$
w(T)=\sum_{(u,v)\in E_T} w(u,v)
$$

MST는 가능한 모든 spanning tree 중 \\(w(T)\\)가 가장 작은 트리다.

$$
T_{\text{MST}}
=
\arg\min_{T:\text{spanning tree}} w(T)
$$

강의의 표현대로 정리하면 MST 문제는 다음과 같다.

> 최소 비용으로 모든 정점을 연결하는 방법을 찾는 문제

## 4. MST Problem의 입력과 출력

MST 문제의 입력은 가중치가 있는 무방향 연결 그래프다.

| 조건 | 이유 |
|---|---|
| 가중치 그래프 | 어떤 연결이 더 싼지 비교해야 함 |
| 무방향 그래프 | MST는 보통 방향 없는 연결 비용 문제로 정의됨 |
| 연결 그래프 | 모든 정점을 하나의 tree로 연결할 수 있어야 함 |

출력은 최소 신장 트리다.

| 출력 요소 | 의미 |
|---|---|
| MST edge set | 선택된 \\(\lvert V\rvert-1\\)개의 간선 |
| total weight | 선택된 간선 weight의 합 |

대표 알고리즘은 Prim과 Kruskal이다. 이번 강의에서는 Prim 알고리즘을 자세히 다룬다.

## 5. MST와 Shortest Path는 다르다

직전 강의의 Dijkstra는 shortest path를 구했다. 이번 강의의 Prim은 MST를 구한다. 둘 다 가중치 그래프에서 greedy하게 정점을 고르기 때문에 모양이 비슷하지만, 목표가 완전히 다르다.

| 구분 | Shortest Path | Minimum Spanning Tree |
|---|---|---|
| 목표 | 시작점에서 각 정점까지의 최단 거리 | 모든 정점을 최소 총비용으로 연결 |
| 관심 대상 | 경로 distance | 선택된 간선들의 총 weight |
| 대표 알고리즘 | Dijkstra | Prim, Kruskal |
| 결과 | 거리 배열과 최단 경로 | 간선 \\(\lvert V\rvert-1\\)개로 된 tree |
| 주의점 | 각 정점까지의 개별 최단 거리 | MST 안의 두 정점 경로가 항상 최단 경로는 아님 |

MST는 전체 연결 비용을 최소화한다. 따라서 MST 위에서 어떤 두 정점 사이를 따라간 경로가 원래 그래프에서의 최단 경로라는 보장은 없다.

## 6. Prim's Algorithm의 직관

Prim's Algorithm은 무향 가중치 그래프의 MST를 찾는 greedy 알고리즘이다. 현재까지 만든 tree를 조금씩 키워 가며, 그 tree에 가장 싸게 붙일 수 있는 정점을 하나씩 추가한다.

직관은 다음과 같다.

> 이미 만든 MST 조각 \\(S\\)와 아직 포함되지 않은 정점들 사이를 잇는 간선 중 가장 싼 연결을 고른다.

여기서 \\(S\\)는 현재 MST에 포함된 정점들의 집합이다.

$$
S\subseteq V
$$

처음에는 시작 정점 하나에서 출발하고, 매 단계마다 정점 하나와 간선 하나를 추가한다. 모든 정점이 \\(S\\)에 들어가면 MST가 완성된다.

## 7. Prim Setup

Prim 알고리즘은 다음 값을 관리한다.

| 기호 | 의미 |
|---|---|
| \\(S\\) | 이미 MST에 포함된 정점들의 집합 |
| \\(D[v]\\) | 현재 tree \\(S\\)와 정점 \\(v\\)를 연결하는 최소 비용 간선의 weight |
| \\(\text{prev}[v]\\) | \\(v\\)를 MST에 붙일 때 사용될 직전 정점 |
| \\(\text{MST}\\) | 최종적으로 선택된 간선들의 집합 |

초기 상태는 다음처럼 둔다.

$$
D[r]=0,\qquad D[v]=\infty\quad(v\ne r)
$$

여기서 \\(r\\)은 시작 정점이다. 시작 정점은 외부에서 연결할 간선이 없으므로 비용을 0으로 둔다.

실제 구현에서는 \\(\text{prev}[r]=\text{NIL}\\)로 두고, 시작 정점 \\(r\\)을 선택할 때는 MST에 간선을 추가하지 않는다. 이후 정점 \\(u\\)를 선택할 때 \\(\text{prev}[u]\\)가 존재하면 간선 \\((\text{prev}[u],u)\\)를 MST에 추가한다.

## 8. Update Costs

Prim의 핵심 갱신은 선택된 정점 \\(u\\)의 이웃 \\(v\\)를 확인하면서, \\(u\\)를 통해 \\(v\\)를 tree에 붙이는 비용이 현재 \\(D[v]\\)보다 작은지 검사하는 것이다.

간선 \\((u,v)\\)의 weight를 \\(w(u,v)\\)라고 하자. Prim의 update 조건은 다음과 같다.

$$
w(u,v)<D[v]
$$

조건이 참이면 다음처럼 갱신한다.

$$
D[v]=w(u,v)
$$

$$
\text{prev}[v]=u
$$

의사코드로 쓰면 다음과 같다.

```text
updateCosts(u, v):
    if w(u, v) < D[v]:
        D[v] = w(u, v)
        prev[v] = u
```

여기서 중요한 점은 \\(D[u]+w(u,v)\\)가 아니라 \\(w(u,v)\\)만 비교한다는 것이다. Prim은 시작점에서 \\(v\\)까지의 누적 거리를 구하는 알고리즘이 아니라, 현재 tree에 \\(v\\)를 붙이는 가장 싼 간선을 찾는 알고리즘이기 때문이다.

## 9. Prim Procedure

Prim 알고리즘의 반복 구조는 다음과 같다.

| 단계 | 설명 |
|---|---|
| 1 | \\(V-S\\) 중 \\(D[u]\\)가 가장 작은 정점 \\(u\\)를 선택한다. |
| 2 | \\(u\\)를 \\(S\\)에 추가한다. |
| 3 | \\(\text{prev}[u]\\)가 있으면 간선 \\((\text{prev}[u],u)\\)를 MST에 추가한다. |
| 4 | \\(u\\)의 이웃 \\(v\\)에 대해 \\(w(u,v)<D[v]\\)이면 \\(D[v]\\)와 \\(\text{prev}[v]\\)를 갱신한다. |

모든 정점이 \\(S\\)에 들어가면 반복을 멈춘다. 이때 선택된 정점은 \\(\lvert V\rvert\\)개이고, 시작 정점을 제외한 각 정점마다 하나의 간선이 선택되므로 MST의 간선 수는 \\(\lvert V\rvert-1\\)개가 된다.

정리한 pseudocode는 다음과 같다.

```text
function Prim(G, r):
    S = empty set
    MST = empty set
    initialize D with infinity
    initialize prev with NIL
    D[r] = 0

    while S != V:
        u = minNode(V - S, D)
        add u to S

        if prev[u] is not NIL:
            add edge (prev[u], u) to MST

        for v in G.neighbors(u):
            if v is not in S and w(u, v) < D[v]:
                D[v] = w(u, v)
                prev[v] = u

    return MST
```

강의 slide의 pseudocode는 \\(S=\{r\}\\)로 시작하는 표기가 나오지만, 계산 흐름은 위처럼 \\(D[r]=0\\)에서 시작해 가장 작은 \\(D\\) 값을 가진 정점을 고르고 이웃 비용을 갱신하는 방식으로 이해하면 된다. 핵심은 root에는 incoming edge가 없고, 나머지 정점들은 \\(\text{prev}\\)가 가리키는 간선으로 MST에 들어온다는 점이다.

## 10. 강의 예제의 \\(D\\) 배열 해석

강의 예제는 정점 \\(1,2,3,4,5,6\\)에 대해 Prim 알고리즘이 진행되면서 \\(D\\) 배열이 어떻게 바뀌는지 보여준다.

여기서 \\(D[i]\\)는 시작 정점 \\(1\\)에서 \\(i\\)까지의 최단 거리가 아니다. \\(D[i]\\)는 현재 MST 정점 집합 \\(S\\)와 정점 \\(i\\)를 연결하는 가장 싼 간선의 weight다.

| 단계 | \\(D[1]\\) | \\(D[2]\\) | \\(D[3]\\) | \\(D[4]\\) | \\(D[5]\\) | \\(D[6]\\) | 핵심 변화 |
|---|---|---|---|---|---|---|---|
| Init | 0 | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | 시작 정점만 0 |
| 1 | 0 | 10 | \\(\infty\\) | 20 | \\(\infty\\) | 2 | 정점 1의 이웃 비용 갱신 |
| 2 | 0 | 10 | \\(\infty\\) | 10 | 3 | 2 | 정점 6을 통해 4, 5 비용 갱신 |
| 3 | 0 | 10 | 15 | 10 | 3 | 2 | 정점 5를 통해 3 비용 갱신 |
| 4 | 0 | 10 | 3 | 5 | 3 | 2 | 정점 2를 통해 3, 4 비용 감소 |
| 5 | 0 | 10 | 3 | 5 | 3 | 2 | 추가 감소 없음 |
| 6 | 0 | 10 | 3 | 5 | 3 | 2 | 모든 정점 포함 |

최종 \\(D\\) 값은 각 정점이 MST에 붙을 때 사용된 연결 비용으로 볼 수 있다. Root인 정점 1의 값은 0이고, 나머지 정점의 final \\(D\\) 값을 더하면 MST의 총 weight를 얻는다.

$$
0+10+3+5+3+2=23
$$

따라서 예제의 MST 총 weight는 23이다.

단, 같은 최소 비용 간선이 여러 개 있거나 \\(D\\) 값이 tie가 되는 경우 선택 순서가 달라질 수 있다. 이때 MST가 하나로 고정되지 않을 수 있지만, 선택 규칙이 올바르면 최소 총 weight를 갖는 spanning tree가 만들어진다.

## 11. Prim과 Dijkstra의 결정적 차이

Prim과 Dijkstra는 표면적으로 매우 비슷하다.

| 공통점 | 설명 |
|---|---|
| Greedy | 매 단계에서 가장 작은 \\(D\\) 값을 가진 미확정 정점을 선택 |
| 집합 \\(S\\) 사용 | 이미 확정된 정점 집합을 관리 |
| 배열 \\(D\\) 사용 | 다음 선택 기준이 되는 값을 저장 |
| \\(\text{prev}\\) 사용 | 선택된 구조를 복원하기 위해 이전 정점을 저장 |
| 구현 방식 | table scan 또는 min-heap 사용 가능 |

하지만 \\(D\\) 배열의 의미가 다르다.

| 알고리즘 | \\(D[v]\\)의 의미 | 갱신 조건 |
|---|---|---|
| Dijkstra | 시작 정점에서 \\(v\\)까지의 최단 거리 추정값 | \\(D[v] > D[u] + w(u,v)\\) |
| Prim | 현재 tree \\(S\\)와 \\(v\\)를 연결하는 최소 간선 비용 | \\(D[v] > w(u,v)\\) |

Dijkstra는 누적 거리 \\(D[u]+w(u,v)\\)를 본다. Prim은 현재 tree에 붙이는 edge 하나의 비용 \\(w(u,v)\\)만 본다.

이 차이를 놓치면 Prim을 Dijkstra처럼 계산하게 된다. MST 문제에서는 시작점에서 멀리 떨어져 있는지가 중요한 것이 아니라, 현재까지 만든 tree에 싸게 붙을 수 있는지가 중요하다.

## 12. 시간 복잡도

Prim의 시간 복잡도는 Dijkstra와 같은 방식으로 분석할 수 있다. 핵심은 `minNode(V - S, D)`를 어떻게 구현하느냐다.

### 방법 1: Distance Table 선형 스캔

매 단계마다 아직 \\(S\\)에 들어가지 않은 정점 중 \\(D\\) 값이 가장 작은 정점을 찾기 위해 배열 전체를 훑는다.

정점 선택은 \\(\lvert V\rvert\\)번 일어나고, 각 선택마다 \\(O(\lvert V\rvert)\\)가 든다.

$$
O(\lvert V\rvert^2)
$$

또한 간선마다 update가 발생할 수 있으므로 \\(O(\lvert E\rvert)\\)가 더해진다.

$$
O(\lvert V\rvert^2+\lvert E\rvert)
$$

강의에서는 이를 다음처럼 정리한다.

$$
O(\lvert V\rvert^2)
$$

### 방법 2: Min-Heap 사용

Min-heap, 즉 priority queue를 쓰면 \\(D\\) 값이 가장 작은 정점을 빠르게 꺼낼 수 있다.

| 연산 | 의미 | 비용 |
|---|---|---|
| `buildHeap` | 초기 heap 구성 | \\(O(\lvert V\rvert)\\) |
| `extract-min` | 최소 \\(D\\) 정점 선택 | \\(O(\log\lvert V\rvert)\\) |
| heap update | 더 작은 연결 비용 발견 시 key 감소 | \\(O(\log\lvert V\rvert)\\) |

각 정점에 대해 `extract-min`이 한 번씩 필요하다.

$$
O(\lvert V\rvert\log\lvert V\rvert)
$$

각 간선에 대해 update가 발생할 수 있다.

$$
O(\lvert E\rvert\log\lvert V\rvert)
$$

따라서 전체 복잡도는 다음과 같다.

$$
O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)
$$

## 13. Kruskal은 어디에 위치하는가?

강의에서는 MST의 대표 알고리즘으로 Prim과 Kruskal을 언급한다. 다만 이번 자료에서 절차와 예제, 복잡도까지 자세히 다루는 알고리즘은 Prim이다.

두 알고리즘의 큰 방향만 비교하면 다음과 같다.

| 알고리즘 | 출발 방식 | 선택 기준 |
|---|---|---|
| Prim | 한 정점에서 tree를 키움 | 현재 tree에 가장 싸게 붙는 정점 선택 |
| Kruskal | 간선들을 weight 순서로 봄 | cycle을 만들지 않는 가장 싼 간선 선택 |

Prim은 tree 하나를 계속 확장하는 방식이고, Kruskal은 여러 작은 component를 간선으로 합쳐 가는 방식이다. 둘 다 MST를 찾는 greedy 알고리즘이다.

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| spanning tree | 모든 정점을 포함하는 tree 형태의 부분 그래프 |
| MST | spanning tree 중 간선 weight 총합이 최소인 tree |
| MST 입력 | 가중치가 있는 무방향 연결 그래프 |
| MST edge 수 | \\(\lvert V\rvert-1\\) |
| MST cycle | cycle이 없음 |
| Prim | 현재 tree에 가장 싸게 붙는 정점을 반복 선택하는 greedy 알고리즘 |
| \\(S\\) | MST에 포함된 정점 집합 |
| \\(D[v]\\) | tree \\(S\\)와 \\(v\\)를 연결하는 최소 edge weight |
| \\(\text{prev}[v]\\) | \\(v\\)가 MST에 들어올 때 연결되는 이전 정점 |
| Prim update | \\(w(u,v)<D[v]\\)이면 \\(D[v]\leftarrow w(u,v)\\) |
| table scan complexity | \\(O(\lvert V\rvert^2+\lvert E\rvert)=O(\lvert V\rvert^2)\\) |
| min-heap complexity | \\(O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)\\) |

## Study Guide

첫 번째로 spanning tree의 조건을 확실히 잡아야 한다. 모든 정점을 포함해야 하고, 연결되어 있어야 하며, cycle이 없어야 한다. 정점이 \\(\lvert V\rvert\\)개라면 간선은 \\(\lvert V\rvert-1\\)개다.

두 번째로 MST는 shortest path가 아니라는 점을 반복해서 확인해야 한다. MST는 모든 정점을 연결하는 전체 비용을 최소화한다. 특정 두 정점 사이의 최단 거리와는 목표가 다르다.

세 번째로 Prim의 \\(D[v]\\) 의미를 외워야 한다. Dijkstra의 \\(D[v]\\)는 시작점부터의 누적 거리지만, Prim의 \\(D[v]\\)는 현재 MST 정점 집합 \\(S\\)에 \\(v\\)를 붙이는 최소 간선 비용이다.

네 번째로 갱신식을 구분해야 한다. Dijkstra는 \\(D[u]+w(u,v)\\)를 비교하고, Prim은 \\(w(u,v)\\)만 비교한다.

| 시험 대비 포인트 | 확인할 내용 |
|---|---|
| Spanning tree 정의 | 모든 정점 포함, 연결, cycle 없음 |
| MST 정의 | spanning tree 중 total weight 최소 |
| MST 간선 수 | \\(\lvert V\rvert-1\\) |
| Prim의 \\(S\\) | 이미 MST에 포함된 정점 집합 |
| Prim의 \\(D[v]\\) | 현재 tree와 \\(v\\)를 잇는 최소 edge weight |
| Update 조건 | \\(w(u,v)<D[v]\\) |
| Dijkstra와 차이 | 누적 거리 vs 연결 edge 비용 |
| 복잡도 | table scan과 min-heap 방식 구분 |

## 복습 질문

<details>
<summary>1. Spanning tree는 무엇인가?</summary>

답변: 그래프의 모든 정점을 포함하는 tree 형태의 부분 그래프다. 모든 정점을 포함해야 하고, 연결되어 있어야 하며, cycle이 없어야 한다.

</details>

<details>
<summary>2. 정점이 \\(\lvert V\rvert\\)개인 spanning tree의 간선 수는 몇 개인가?</summary>

답변: \\(\lvert V\rvert-1\\)개다. Tree는 cycle 없이 모든 정점을 연결하는 최소 간선 구조이므로 정점 수보다 하나 적은 간선을 가진다.

</details>

<details>
<summary>3. Minimum Spanning Tree는 무엇인가?</summary>

답변: 가능한 모든 spanning tree 중에서 선택된 간선 weight의 총합이 최소가 되는 tree다. 즉, 최소 비용으로 모든 정점을 연결하는 방법이다.

</details>

<details>
<summary>4. MST 문제의 입력 그래프는 어떤 조건을 가져야 하는가?</summary>

답변: 일반적으로 가중치가 있는 무방향 연결 그래프가 입력이다. Weight가 있어야 비용을 비교할 수 있고, 연결 그래프여야 모든 정점을 하나의 spanning tree로 묶을 수 있다.

</details>

<details>
<summary>5. Prim 알고리즘에서 \\(S\\)는 무엇을 의미하는가?</summary>

답변: \\(S\\)는 이미 MST에 포함된 정점들의 집합이다. 알고리즘은 \\(S\\)를 조금씩 키우면서 모든 정점이 포함될 때까지 가장 싼 연결을 선택한다.

</details>

<details>
<summary>6. Prim 알고리즘에서 \\(D[v]\\)는 무엇을 의미하는가?</summary>

답변: \\(D[v]\\)는 현재 MST 정점 집합 \\(S\\)와 정점 \\(v\\)를 연결하는 최소 비용 간선의 weight다. 시작점에서 \\(v\\)까지의 누적 거리가 아니다.

</details>

<details>
<summary>7. Prim의 update 조건을 써보라.</summary>

답변: 선택된 정점 \\(u\\)의 이웃 \\(v\\)에 대해 \\(w(u,v)<D[v]\\)이면 \\(D[v]=w(u,v)\\)로 갱신하고, \\(\text{prev}[v]=u\\)로 저장한다.

</details>

<details>
<summary>8. Prim과 Dijkstra의 가장 중요한 차이는 무엇인가?</summary>

답변: Dijkstra의 \\(D[v]\\)는 시작 정점에서 \\(v\\)까지의 누적 최단 거리 추정값이고, 갱신식은 \\(D[u]+w(u,v)\\)를 사용한다. Prim의 \\(D[v]\\)는 현재 tree에 \\(v\\)를 붙이는 edge 하나의 최소 비용이고, 갱신식은 \\(w(u,v)\\)만 사용한다.

</details>

<details>
<summary>9. Prim에서 \\(\text{prev}\\) 배열은 왜 필요한가?</summary>

답변: \\(D[v]\\)만 저장하면 비용은 알 수 있지만 실제로 어떤 간선이 MST에 들어가는지 알 수 없다. \\(\text{prev}[v]\\)를 저장하면 정점 \\(v\\)가 MST에 들어올 때 선택된 간선 \\((\text{prev}[v],v)\\)를 복원할 수 있다.

</details>

<details>
<summary>10. Distance table을 선형 스캔하는 Prim의 시간 복잡도는?</summary>

답변: 매 단계마다 \\(D\\) 배열에서 최소 값을 찾기 위해 \\(O(\lvert V\rvert)\\)가 들고, 이를 \\(\lvert V\rvert\\)번 반복하므로 \\(O(\lvert V\rvert^2)\\)가 든다. 간선 update 비용 \\(O(\lvert E\rvert)\\)까지 포함하면 \\(O(\lvert V\rvert^2+\lvert E\rvert)\\), 보통 \\(O(\lvert V\rvert^2)\\)로 정리한다.

</details>

<details>
<summary>11. Min-heap을 쓰는 Prim의 시간 복잡도는?</summary>

답변: 정점마다 `extract-min`이 일어나고 간선마다 heap update가 일어날 수 있으므로 \\(O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)\\)로 정리한다.

</details>

<details>
<summary>12. MST 안의 두 정점 사이 경로는 항상 원래 그래프의 최단 경로인가?</summary>

답변: 아니다. MST는 모든 정점을 연결하는 총비용을 최소화하는 구조이지, 특정 두 정점 사이의 최단 경로를 보장하는 구조가 아니다. 특정 시작점 기준 최단 거리가 필요하면 Dijkstra 같은 shortest path 알고리즘을 사용해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS23_minimum_spanning_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS23_minimum_spanning_tree.pdf</a></li>
</ul>
