---
layout: default
date: 2026-06-04 13:25:48 +0900
title: "LS22 Shortest Path"
course: "Data Structures"
topic: "Shortest Path"
order: 22
major_topic: "Data Structures & Algorithms"
keywords:
  - "Shortest Path"
  - "Dijkstra Algorithm"
  - "Weighted Graphs"
  - "Relaxation"
  - "Priority Queue"
---

# LS22 Shortest Path

Source PDF: `LS22_shortest_path.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Weighted Graph 복습 | 간선마다 비용이 붙으면 경로의 길이는 어떻게 계산되는가? |
| 2 | Shortest Path Problem | 최단 경로와 최단 거리 값은 무엇을 의미하는가? |
| 3 | 문제의 종류 | 특정 두 정점, 단일 시작점, 모든 정점 쌍 문제는 어떻게 다른가? |
| 4 | SSSP | 시작 정점 하나에서 모든 정점까지의 최단 거리를 어떻게 구하는가? |
| 5 | Dijkstra Setup | \\(S\\), \\(D\\), \\(\text{prev}\\) 배열은 각각 무엇을 저장하는가? |
| 6 | Relaxation | 더 짧은 경로를 발견하면 거리 배열을 어떻게 갱신하는가? |
| 7 | Dijkstra Procedure | 가장 가까운 미확정 정점을 고르고 이웃을 relax하는 반복 구조는 무엇인가? |
| 8 | 예제 흐름 | 거리 배열 \\(D\\)가 단계별로 어떻게 바뀌는가? |
| 9 | minDistVertex | 다음 정점을 고르는 구현 방식에 따라 복잡도가 어떻게 달라지는가? |
| 10 | 알고리즘 선택 | Dijkstra, Bellman-Ford, Floyd-Warshall은 어떤 문제와 연결되는가? |

22강은 가중치 그래프에서 최단 경로를 찾는 문제를 다룬다. 핵심은 경로의 길이를 간선 개수가 아니라 weight의 합으로 계산한다는 점이고, 강의의 중심 알고리즘은 단일 시작점 최단 경로를 푸는 Dijkstra 알고리즘이다.

## 1. Weighted Graph와 경로 비용

가중치 그래프(weighted graph)는 간선마다 비용, 거리, 시간 같은 값이 붙어 있는 그래프다.

$$
G=(V,E),\qquad w:E\to \mathbb{R}
$$

여기서 \\(w(u,v)\\)는 정점 \\(u\\)에서 정점 \\(v\\)로 가는 간선의 weight다.

가중치가 없는 그래프에서는 경로의 길이를 보통 간선 개수로 계산한다. 하지만 가중치 그래프에서는 경로에 포함된 간선 weight의 합이 경로 비용이 된다.

정점열

$$
p=(v_0,v_1,\ldots,v_k)
$$

가 경로라면, 이 경로의 weight는 다음과 같다.

$$
w(p)=\sum_{i=0}^{k-1} w(v_i,v_{i+1})
$$

즉, 최단 경로에서 "짧다"는 말은 정점 수가 적다는 뜻이 아니라 weight 합이 작다는 뜻이다.

| 상황 | 최단 경로에서 weight의 의미 |
|---|---|
| 지도 | 이동 거리 |
| 네트워크 | 통신 비용 또는 지연 시간 |
| 교통 | 이동 시간 또는 혼잡도 |
| 게임 맵 | 이동 비용 |
| 작업 흐름 | 전환 비용 |

## 2. Shortest Path Problem

최단 경로 문제(shortest path problem)의 입력은 가중치가 있는 그래프다.

| 입력 요소 | 의미 |
|---|---|
| \\(V\\) | 정점 집합 |
| \\(E\\) | 간선 집합 |
| \\(w(u,v)\\) | 간선 \\((u,v)\\)의 비용 |

목적은 두 가지로 나눌 수 있다.

| 목적 | 설명 |
|---|---|
| 최단 경로 자체 | 어떤 정점들을 거쳐 가야 하는지 찾음 |
| 최단 거리 값 | 최소 비용이 얼마인지 계산 |

시작 정점 \\(s\\)에서 정점 \\(v\\)까지의 최단 거리 값을 보통 다음처럼 생각할 수 있다.

$$
\delta(s,v)=\min_{p:s\leadsto v} w(p)
$$

여기서 \\(p:s\leadsto v\\)는 \\(s\\)에서 \\(v\\)로 가는 모든 가능한 경로를 뜻한다. 만약 \\(s\\)에서 \\(v\\)로 도달할 수 없다면 최단 거리는 무한대로 둔다.

$$
\delta(s,v)=\infty
$$

## 3. 최단 경로 문제의 종류

강의에서는 최단 경로 문제를 세 가지로 분류한다.

| 문제 | 질문 | 대표 알고리즘 |
|---|---|---|
| 특정 두 정점 사이의 최단 경로 | \\(u\\)에서 \\(v\\)까지 가장 짧은 경로는 무엇인가? | Dijkstra 변형, A* 등 |
| 단일 시작점 최단 경로 | 시작 정점 \\(s\\)에서 모든 정점까지의 최단 거리는 얼마인가? | Dijkstra, Bellman-Ford |
| 모든 정점 쌍 최단 경로 | 모든 \\((u,v)\\) 쌍에 대해 최단 거리는 얼마인가? | Floyd-Warshall |

이번 강의의 초점은 단일 시작점 최단 경로, 즉 Single-Source Shortest Path다.

$$
\text{SSSP}=\text{Single-Source Shortest Path}
$$

SSSP는 시작 정점 \\(s\\)가 주어졌을 때 모든 정점 \\(v\in V\\)에 대해 \\(s\\)에서 \\(v\\)까지의 최단 거리 \\(D[v]\\)를 계산한다.

## 4. Dijkstra 알고리즘의 전제와 직관

Dijkstra 알고리즘은 SSSP를 푸는 대표 알고리즘이다. 핵심 직관은 다음과 같다.

> 현재까지 알려진 거리 중 가장 작은 미확정 정점은 더 이상 짧아질 수 없다고 보고 확정한다.

이 말이 성립하려면 간선 weight가 음수가 아니어야 한다.

$$
w(u,v)\ge 0
$$

만약 음수 간선이 있으면 이미 확정한 정점의 거리가 나중에 더 작아질 수 있다. 그러면 "가장 작은 미확정 거리부터 확정한다"는 Dijkstra의 greedy 선택이 깨진다.

| 조건 | Dijkstra 사용 가능성 |
|---|---|
| 모든 weight가 0 이상 | 사용 가능 |
| 음수 간선 존재 | 일반적으로 사용하면 안 됨 |
| 음수 cycle 존재 | 최단 거리 자체가 정의되지 않을 수 있음 |

음수 간선까지 다뤄야 한다면 Bellman-Ford 알고리즘을 고려한다. 모든 정점 쌍의 최단 거리를 구해야 한다면 Floyd-Warshall 알고리즘이 대표적이다.

## 5. Dijkstra Setup

Dijkstra 알고리즘에서는 다음 값을 관리한다.

| 기호 | 의미 |
|---|---|
| \\(S\\) | 최단 거리가 확정된 정점들의 집합 |
| \\(D[v]\\) | 현재까지 알려진 \\(s\\to v\\) 최단 거리 추정값 |
| \\(\text{prev}[v]\\) | 현재 최단 경로에서 \\(v\\) 바로 이전에 오는 정점 |

초기 상태는 다음과 같다.

$$
S=\emptyset
$$

$$
D[s]=0,\qquad D[v]=\infty\quad(v\ne s)
$$

시작 정점까지의 거리는 0이고, 아직 모르는 정점까지의 거리는 무한대로 둔다. \\(\text{prev}\\) 배열은 최단 거리 값뿐 아니라 실제 경로를 복원할 때 필요하다.

예를 들어 최종적으로

```text
prev[g] = d
prev[d] = b
prev[b] = c
prev[c] = s
```

라면 \\(s\\)에서 \\(g\\)까지의 경로는 거꾸로 따라가서 다음처럼 복원할 수 있다.

```text
s -> c -> b -> d -> g
```

## 6. Relaxation

Relaxation은 Dijkstra 알고리즘의 핵심 갱신 연산이다. 어떤 정점 \\(u\\)를 거쳐 이웃 정점 \\(v\\)로 가는 경로가 현재 알고 있는 \\(v\\)까지의 거리보다 짧으면, \\(D[v]\\)를 더 작은 값으로 바꾼다.

간선 \\((u,v)\\)의 weight를 \\(w(u,v)\\)라고 하자. 그러면 relaxation 조건은 다음과 같다.

$$
D[v] > D[u] + w(u,v)
$$

조건이 참이면 다음처럼 갱신한다.

$$
D[v] = D[u] + w(u,v)
$$

$$
\text{prev}[v]=u
$$

의사코드로 쓰면 다음과 같다.

```text
relax(u, v):
    if D[v] > D[u] + w(u, v):
        D[v] = D[u] + w(u, v)
        prev[v] = u
```

Relaxation은 "새로 발견한 우회 경로가 기존 경로보다 좋은가?"를 검사하는 과정이다. 값이 줄어드는 경우에만 \\(D\\)와 \\(\text{prev}\\)를 바꾼다.

## 7. Dijkstra Procedure

Dijkstra 알고리즘의 반복 구조는 다음 세 단계다.

| 단계 | 설명 |
|---|---|
| 1 | \\(V-S\\) 중 \\(D[u]\\)가 가장 작은 정점 \\(u\\)를 선택한다. |
| 2 | \\(u\\)를 \\(S\\)에 추가하여 최단 거리를 확정한다. |
| 3 | \\(u\\)의 모든 이웃 \\(v\\)에 대해 relaxation을 수행한다. |

모든 정점이 \\(S\\)에 들어갈 때까지 반복한다.

강의의 pseudocode를 정리하면 다음과 같다.

```text
function Dijkstra(G, s):
    S = empty set
    initialize D with infinity
    initialize prev
    D[s] = 0

    while S != V:
        u = minDistVertex(V - S, D)
        add u to S

        for v in G.neighbors(u):
            if v is not in S and D[u] + w(u, v) < D[v]:
                D[v] = D[u] + w(u, v)
                prev[v] = u
```

구현에 따라 \\(s\\)를 먼저 확정하고 시작하거나, 위처럼 \\(S=\emptyset\\)에서 시작해 첫 번째 `minDistVertex`가 \\(s\\)를 고르게 만들 수 있다. 중요한 것은 \\(D[s]=0\\), 나머지는 \\(\infty\\)로 두고, 가장 작은 거리 추정값을 가진 미확정 정점부터 처리한다는 점이다.

## 8. 왜 가장 작은 \\(D[u]\\)를 확정할 수 있는가?

Dijkstra는 greedy 알고리즘이다. 매 순간 가장 좋아 보이는 선택, 즉 \\(D\\) 값이 가장 작은 미확정 정점을 확정한다.

이 선택이 맞는 이유는 간단히 말하면 다음과 같다.

1. \\(u\\)는 아직 확정되지 않은 정점 중 \\(D[u]\\)가 가장 작다.
2. 다른 미확정 정점을 거쳐 \\(u\\)로 돌아오는 더 짧은 경로가 있으려면, 먼저 그 다른 정점까지 도달해야 한다.
3. 그런데 그 다른 정점의 현재 거리 추정값은 \\(D[u]\\) 이상이다.
4. 간선 weight가 음수가 아니므로 거기서 \\(u\\)로 더 이동하면 비용은 줄어들 수 없다.

따라서 \\(u\\)의 거리는 더 이상 작아질 수 없고, \\(S\\)에 넣어 확정해도 된다.

이 논리는 음수 간선이 있을 때 깨진다. 음수 간선은 이동했는데 비용이 줄어드는 효과를 만들 수 있기 때문이다.

## 9. 강의 예제의 거리 배열 흐름

강의 예제에서는 시작 정점 \\(s\\)에서 \\(a,b,c,d,e,f,g\\)까지의 거리 배열 \\(D\\)가 단계적으로 갱신된다.

| 단계 | 확정 또는 갱신 후 \\(D[s]\\) | \\(D[a]\\) | \\(D[b]\\) | \\(D[c]\\) | \\(D[d]\\) | \\(D[e]\\) | \\(D[f]\\) | \\(D[g]\\) | 핵심 변화 |
|---|---|---|---|---|---|---|---|---|---|
| Init | 0 | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | \\(\infty\\) | 시작 정점만 0 |
| 1 | 0 | 8 | \\(\infty\\) | 9 | \\(\infty\\) | 11 | \\(\infty\\) | \\(\infty\\) | \\(s\\)의 이웃 갱신 |
| 2 | 0 | 8 | 18 | 9 | \\(\infty\\) | 11 | \\(\infty\\) | \\(\infty\\) | \\(a\\)를 거쳐 \\(b\\) 발견 |
| 3 | 0 | 8 | 10 | 9 | \\(\infty\\) | 11 | \\(\infty\\) | \\(\infty\\) | \\(c\\)를 거쳐 \\(b\\)가 18에서 10으로 감소 |
| 4 | 0 | 8 | 10 | 9 | 12 | 11 | \\(\infty\\) | \\(\infty\\) | \\(b\\)를 거쳐 \\(d\\) 발견 |
| 5 | 0 | 8 | 10 | 9 | 12 | 11 | 19 | 19 | \\(e\\)를 거쳐 \\(f,g\\) 발견 |
| 6 | 0 | 8 | 10 | 9 | 12 | 11 | 19 | 16 | \\(d\\)를 거쳐 \\(g\\)가 19에서 16으로 감소 |
| 7 | 0 | 8 | 10 | 9 | 12 | 11 | 19 | 16 | 추가 감소 없음 |
| 8 | 0 | 8 | 10 | 9 | 12 | 11 | 19 | 16 | 모든 정점 확정 |

최종 최단 거리 값은 다음과 같다.

| 정점 | 최단 거리 |
|---|---|
| \\(s\\) | 0 |
| \\(a\\) | 8 |
| \\(b\\) | 10 |
| \\(c\\) | 9 |
| \\(d\\) | 12 |
| \\(e\\) | 11 |
| \\(f\\) | 19 |
| \\(g\\) | 16 |

예제에서 중요한 장면은 두 번이다.

첫째, \\(b\\)의 값이 18에서 10으로 줄어든다. 이는 처음 발견한 경로보다 \\(c\\)를 거치는 경로가 더 짧다는 뜻이다.

둘째, \\(g\\)의 값이 19에서 16으로 줄어든다. 최단 경로 알고리즘에서는 정점을 처음 발견했다고 해서 그 값이 최종값인 것은 아니다. Dijkstra에서는 \\(S\\)에 들어가 확정되기 전까지 더 짧은 경로가 나오면 계속 갱신될 수 있다.

## 10. minDistVertex 구현과 시간 복잡도

Dijkstra에서 가장 중요한 구현 포인트는 `minDistVertex(V - S, D)`다. 즉, 아직 확정되지 않은 정점 중 \\(D\\) 값이 가장 작은 정점을 어떻게 고를 것인가가 전체 시간 복잡도를 크게 바꾼다.

### 방법 1: Distance Table 선형 스캔

가장 단순한 방법은 매 단계마다 거리 배열 \\(D\\) 전체를 훑는 것이다.

```text
for each unvisited vertex v:
    pick v with minimum D[v]
```

정점 하나를 확정할 때마다 \\(O(\lvert V\rvert)\\)의 탐색이 필요하고, 이 과정을 \\(\lvert V\rvert\\)번 반복한다.

$$
O(\lvert V\rvert^2)
$$

또한 relaxation은 간선마다 일어날 수 있으므로 \\(O(\lvert E\rvert)\\)가 더해진다.

$$
O(\lvert V\rvert^2+\lvert E\rvert)
$$

일반적으로 \\(\lvert E\rvert\le \lvert V\rvert^2\\)로 볼 수 있으므로 강의에서는 다음처럼 정리한다.

$$
O(\lvert V\rvert^2)
$$

### 방법 2: Min-Heap 사용

표준 구현에서는 min-heap, 즉 priority queue를 사용한다. Heap에는 아직 확정되지 않은 정점들을 넣고, key를 \\(D[v]\\)로 둔다.

| 연산 | 의미 | 비용 |
|---|---|---|
| `extract-min` | \\(D\\)가 가장 작은 정점 꺼내기 | \\(O(\log\lvert V\rvert)\\) |
| `decrease-key` 또는 heap update | relaxation으로 줄어든 \\(D[v]\\) 반영 | \\(O(\log\lvert V\rvert)\\) |
| `buildHeap` | 초기 heap 구성 | \\(O(\lvert V\rvert)\\) |

각 정점에 대해 `extract-min`이 한 번씩 일어난다.

$$
O(\lvert V\rvert\log\lvert V\rvert)
$$

각 간선 relaxation 과정에서 heap update가 필요할 수 있다.

$$
O(\lvert E\rvert\log\lvert V\rvert)
$$

따라서 전체 시간 복잡도는 다음과 같다.

$$
O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)
$$

## 11. Dijkstra와 BFS의 관계

직전 강의에서 BFS는 unweighted graph의 최단 경로를 구할 수 있다고 했다. LS22의 Dijkstra는 이를 가중치 그래프로 확장한 느낌으로 이해할 수 있다.

| 알고리즘 | 그래프 조건 | 거리 기준 | 다음 정점 선택 |
|---|---|---|---|
| BFS | unweighted graph | 간선 개수 | queue의 front |
| Dijkstra | nonnegative weighted graph | weight 합 | \\(D\\)가 가장 작은 미확정 정점 |

BFS는 모든 간선 weight가 1인 특수한 최단 경로 문제로 볼 수 있다. 모든 간선 비용이 같기 때문에 queue만으로 level 순서를 보장할 수 있다.

하지만 간선마다 weight가 다르면 level 순서가 최단 비용 순서와 다를 수 있다. 그래서 Dijkstra는 queue 대신 distance table 또는 priority queue를 이용해 현재 가장 비용이 작은 정점을 직접 선택한다.

## 12. 알고리즘 선택 정리

강의에서 언급한 대표 알고리즘들을 문제 유형 기준으로 정리하면 다음과 같다.

| 알고리즘 | 주로 푸는 문제 | 특징 |
|---|---|---|
| Dijkstra | 단일 시작점 최단 경로 | nonnegative weight에서 빠르고 대표적 |
| Bellman-Ford | 단일 시작점 최단 경로 | 음수 간선을 다룰 수 있고 음수 cycle 탐지도 가능 |
| Floyd-Warshall | 모든 정점 쌍 최단 경로 | DP 기반, 모든 \\((u,v)\\) 거리 계산 |

이번 강의에서 자세히 다루는 것은 Dijkstra다. Bellman-Ford와 Floyd-Warshall은 "문제 분류와 대표 알고리즘"으로 기억하면 충분하다.

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| shortest path | weight 합이 최소가 되는 경로 |
| shortest distance | 최단 경로의 비용 값 |
| SSSP | 하나의 시작 정점에서 모든 정점까지의 최단 거리 계산 |
| ASP | 모든 정점 쌍 사이의 최단 거리 계산 |
| \\(S\\) | 최단 거리가 확정된 정점 집합 |
| \\(D[v]\\) | 현재까지 알려진 \\(s\\to v\\) 최단 거리 추정값 |
| \\(\text{prev}[v]\\) | 최단 경로 복원을 위한 이전 정점 |
| relaxation | 더 짧은 경로를 찾으면 \\(D[v]\\)와 \\(\text{prev}[v]\\)를 갱신하는 연산 |
| Dijkstra | 가장 작은 미확정 거리 정점을 반복적으로 확정하는 greedy 알고리즘 |
| Dijkstra 조건 | 간선 weight가 음수가 아니어야 함 |
| table scan complexity | \\(O(\lvert V\rvert^2+\lvert E\rvert)=O(\lvert V\rvert^2)\\) |
| min-heap complexity | \\(O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)\\) |

## Study Guide

첫 번째로 최단 경로의 기준을 정확히 잡아야 한다. LS21의 BFS에서는 간선 개수 기준으로 최단 거리를 구했지만, LS22의 weighted graph에서는 간선 weight의 합이 기준이다.

두 번째로 relaxation을 반드시 손으로 계산할 수 있어야 한다. Dijkstra의 모든 갱신은 \\(D[v] > D[u] + w(u,v)\\)인지 확인하는 데서 출발한다. 이 조건이 참이면 \\(D[v]\\)를 줄이고 \\(\text{prev}[v]\\)를 \\(u\\)로 바꾼다.

세 번째로 \\(S\\)의 의미를 헷갈리지 않아야 한다. \\(S\\)에 들어간 정점은 최단 거리가 확정된 정점이다. 반대로 아직 \\(S\\)에 없는 정점은 거리 값이 더 줄어들 수 있다.

네 번째로 복잡도는 `minDistVertex` 구현 방식과 연결해서 외우는 것이 좋다. 배열을 매번 스캔하면 \\(O(\lvert V\rvert^2)\\), min-heap을 쓰면 \\(O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)\\)다.

| 시험 대비 포인트 | 확인할 내용 |
|---|---|
| 경로 비용 | 경로에 포함된 edge weight의 합 |
| SSSP 정의 | 시작 정점 하나에서 모든 정점까지의 최단 거리 |
| Dijkstra 초기화 | \\(D[s]=0\\), 나머지는 \\(\infty\\) |
| relaxation 조건 | \\(D[v] > D[u] + w(u,v)\\) |
| 확정 집합 \\(S\\) | \\(S\\)에 들어가면 최단 거리 확정 |
| 음수 간선 주의 | Dijkstra의 greedy 확정 논리가 깨질 수 있음 |
| 복잡도 비교 | table scan vs min-heap |
| 경로 복원 | \\(\text{prev}\\) 배열을 목적지에서 시작점 방향으로 역추적 |

## 복습 질문

<details>
<summary>1. Weighted graph에서 경로의 길이는 어떻게 계산하는가?</summary>

답변: 경로에 포함된 모든 간선 weight의 합으로 계산한다. 경로 \\(p=(v_0,v_1,\ldots,v_k)\\)의 비용은 \\(w(p)=\sum_{i=0}^{k-1}w(v_i,v_{i+1})\\)이다.

</details>

<details>
<summary>2. Single-Source Shortest Path는 어떤 문제인가?</summary>

답변: 하나의 시작 정점 \\(s\\)가 주어졌을 때, \\(s\\)에서 그래프의 모든 정점 \\(v\\)까지의 최단 거리 \\(D[v]\\)를 계산하는 문제다.

</details>

<details>
<summary>3. Dijkstra에서 \\(D[v]\\)와 \\(\text{prev}[v]\\)는 각각 무엇을 의미하는가?</summary>

답변: \\(D[v]\\)는 현재까지 알려진 \\(s\\to v\\) 최단 거리 추정값이다. \\(\text{prev}[v]\\)는 현재 최단 경로에서 \\(v\\) 바로 이전에 오는 정점이며, 최종 경로를 복원할 때 사용한다.

</details>

<details>
<summary>4. Relaxation 조건과 갱신식을 써보라.</summary>

답변: 간선 \\((u,v)\\)에 대해 \\(D[v] > D[u] + w(u,v)\\)이면 더 짧은 경로를 찾은 것이다. 이때 \\(D[v]=D[u]+w(u,v)\\)로 갱신하고, \\(\text{prev}[v]=u\\)로 저장한다.

</details>

<details>
<summary>5. Dijkstra에서 \\(S\\)에 들어간 정점은 어떤 의미인가?</summary>

답변: \\(S\\)는 최단 거리가 확정된 정점들의 집합이다. 정점 \\(u\\)가 \\(S\\)에 들어갔다는 것은 현재 \\(D[u]\\)가 실제 최단 거리 \\(\delta(s,u)\\)와 같다고 확정했다는 뜻이다.

</details>

<details>
<summary>6. Dijkstra가 음수 간선에서 문제가 될 수 있는 이유는?</summary>

답변: Dijkstra는 가장 작은 거리 추정값을 가진 미확정 정점을 확정해도 이후 더 짧아지지 않는다는 greedy 논리에 의존한다. 음수 간선이 있으면 나중에 다른 경로를 통해 이미 확정한 정점의 거리가 더 작아질 수 있으므로 이 논리가 깨진다.

</details>

<details>
<summary>7. Distance table을 선형 스캔하는 Dijkstra의 시간 복잡도는?</summary>

답변: 매 단계마다 미확정 정점 중 최소 \\(D\\) 값을 찾기 위해 \\(O(\lvert V\rvert)\\) 스캔을 하고, 이를 \\(\lvert V\rvert\\)번 반복하므로 \\(O(\lvert V\rvert^2)\\)가 든다. Relaxation 비용 \\(O(\lvert E\rvert)\\)를 더해 \\(O(\lvert V\rvert^2+\lvert E\rvert)\\)이고, 보통 \\(O(\lvert V\rvert^2)\\)로 정리한다.

</details>

<details>
<summary>8. Min-heap을 쓰는 Dijkstra의 시간 복잡도는?</summary>

답변: 각 정점에 대해 `extract-min`이 필요하므로 \\(O(\lvert V\rvert\log\lvert V\rvert)\\), 각 간선 relaxation에서 heap update가 발생할 수 있으므로 \\(O(\lvert E\rvert\log\lvert V\rvert)\\)가 든다. 따라서 전체는 \\(O((\lvert V\rvert+\lvert E\rvert)\log\lvert V\rvert)\\)이다.

</details>

<details>
<summary>9. BFS와 Dijkstra의 차이는 무엇인가?</summary>

답변: BFS는 unweighted graph에서 간선 개수 기준 최단 거리를 구하고, queue로 level 순서를 유지한다. Dijkstra는 nonnegative weighted graph에서 weight 합 기준 최단 거리를 구하고, 거리 추정값 \\(D\\)가 가장 작은 미확정 정점을 선택한다.

</details>

<details>
<summary>10. 최단 경로 자체를 복원하려면 어떤 배열이 필요한가?</summary>

답변: \\(\text{prev}\\) 배열이 필요하다. 목적지 정점에서 시작해 \\(\text{prev}\\)를 반복해서 따라가면 시작 정점까지 거꾸로 도달할 수 있고, 이 순서를 뒤집으면 최단 경로가 된다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS22_shortest_path.pdf" | relative_url }}" target="_blank" rel="noopener">LS22_shortest_path.pdf</a></li>
</ul>
