---
layout: default
date: 2026-11-18 00:00:00 +0900
last_modified_at: 2026-11-23 16:50:00 +0900
title: "Lecture 12: Graph Basics"
course: "Algorithms"
topic: "Graph Definitions, Representations, DFS, and BFS"
order: 12
major_topic: "Data Structures & Algorithms"
keywords:
  - "Graph"
  - "Adjacency Matrix"
  - "Adjacency List"
  - "Depth-First Search"
  - "Breadth-First Search"
  - "Graph Traversal"
---

# Lecture 12: Graph Basics

Source PDF: [lecture-12-graph-basics.pdf](/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf)

그래프는 객체를 정점으로, 객체 사이의 관계를 간선으로 바꾸어 표현합니다. 이 강의는 그래프의 기본 용어를 정의한 뒤, 같은 그래프를 인접 행렬과 인접 리스트로 저장하는 방법을 비교하고, DFS와 BFS가 저장된 연결 관계를 어떤 순서로 방문하는지 설명합니다.

> **핵심:** 그래프 문제는 먼저 정점과 간선이 무엇인지 정하고, 방향·가중치·연결성에 맞는 표현을 선택해야 합니다. DFS는 한 경로를 끝까지 따라가고, BFS는 시작점과의 거리가 같은 정점을 한 층씩 방문합니다. 두 탐색 모두 `visited`가 있어야 사이클에서 무한 반복하지 않습니다.

## 전체 흐름

| PDF 쪽 | 원문 범위 | 핵심 질문 |
|---|---|---|
| 1–4 | 표지, 목차, Graph Definition | 그래프는 어떤 대상을 정점과 간선으로 바꿉니까? |
| 5–9 | 기본 용어와 그래프 종류 | 경로·사이클·연결·방향·가중치는 어떻게 구분합니까? |
| 10–13 | Graph in AI | 지식, 이웃 정보, 도로를 그래프로 표현하는 이유는 무엇입니까? |
| 14–17 | Adjacency Matrix | 간선 확인이 빠른 대신 어떤 공간을 사용합니까? |
| 18–22 | Adjacency List | 실제 이웃만 저장하면 무엇이 달라집니까? |
| 23–28 | Graph Traversal과 DFS | 한 갈래를 깊게 탐색하고 되돌아오는 과정을 어떻게 구현합니까? |
| 29–31 | BFS | 시작점에서 가까운 순서를 큐로 어떻게 보장합니까? |
| 32–35 | 요약, 다음 강의, 질문 | Graph Basics가 Disjoint Set과 MST로 어떻게 이어집니까? |

## 1. Graph: 관계를 정점과 간선으로 바꾼다

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=5" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/graph-definition.jpg" | relative_url }}" alt="그래프 G를 정점 집합 V와 간선 집합 E로 정의하고 가중치가 표시된 예를 제시한 강의 원본 5쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 5. 원은 정점, 두 원을 잇는 선은 간선이며 숫자는 간선의 가중치입니다.</figcaption>
</figure>

그래프는 다음 순서쌍으로 정의합니다.

$$
G=(V,E).
$$

$$V$$는 정점(vertex 또는 node)의 집합이고, $$E$$는 간선(edge)의 집합입니다. 예를 들어 도로망에서는 교차로를 정점, 두 교차로를 잇는 도로를 간선으로 둘 수 있습니다. 소셜 네트워크에서는 사용자가 정점, 친구 관계가 간선입니다. 그림의 간선 옆 숫자는 거리·비용·시간처럼 연결의 크기를 나타내는 가중치입니다.

방향이 없는 그래프에서 서로 다른 정점 $$u,v$$를 잇는 간선은 보통 $$\{u,v\}$$로 씁니다. 방향 그래프에서는 출발점과 도착점이 중요하므로 $$(u,v)$$로 쓰고, $$u\to v$$와 $$v\to u$$를 서로 다른 간선으로 취급합니다. 간선 하나로 직접 연결된 두 정점은 **인접한다**고 말합니다.

### 1.1 Subgraph

부분 그래프 $$G'=(V',E')$$는 원래 그래프에서 정점과 간선을 골라 만듭니다.

$$
V'\subseteq V,\qquad E'\subseteq E.
$$

단, $$E'$$에 간선 $$\{u,v\}$$를 넣었다면 두 끝점 $$u,v$$도 $$V'$$에 포함되어야 합니다. 단순히 간선만 골라 놓고 그 끝점을 빼면 그래프가 완성되지 않습니다. 도로망에서 특정 구역의 교차로와 그 사이 도로만 남기는 경우가 부분 그래프의 예입니다.

### 1.2 Path, cycle, simple path

경로(path)는 연속한 두 정점이 간선으로 연결된 정점열입니다. 다음 그래프에서 간선이 존재한다고 하겠습니다.

```text
0 -- 1 -- 4
 \       /
   -- 2 --
```

`0 → 1 → 4 → 2`는 경로입니다. 시작 정점으로 되돌아오는 `0 → 1 → 4 → 2 → 0`은 사이클(cycle)입니다. **단순 경로(simple path)는 정점을 반복하지 않는 경로**입니다. 원문의 “사이클을 포함하지 않는 경로”는 이를 직관적으로 표현한 말이며, 엄밀하게는 정점 중복 여부로 판별하는 편이 안전합니다.

### 1.3 Connected graph와 complete graph

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=8" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/connected-complete.jpg" | relative_url }}" alt="연결 그래프와 완전 그래프 정의 및 세 그래프 분류 문제를 담은 강의 원본 8쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 8. 직접 간선이 없어도 경로가 있으면 연결된 것이고, 모든 쌍에 직접 간선이 있어야 완전 그래프입니다.</figcaption>
</figure>

- **연결 그래프(connected graph):** 임의의 두 정점 사이에 경로가 있습니다.
- **완전 그래프(complete graph):** 서로 다른 모든 정점 쌍 사이에 간선이 직접 있습니다.

완전 그래프는 항상 연결 그래프지만, 연결 그래프가 항상 완전 그래프인 것은 아닙니다. 8쪽의 세 그림을 왼쪽부터 분류하면 다음과 같습니다.

1. 첫 그래프는 모든 정점이 경로로 이어지므로 연결 그래프지만, 모든 쌍이 직접 연결되지는 않아 완전 그래프가 아닙니다.
2. 둘째 그래프는 위쪽 두 정점이 아래쪽 정점들과 이어지지 않아 연결 그래프가 아닙니다.
3. 셋째 그래프는 다섯 정점의 모든 쌍에 간선이 있는 완전 그래프 $$K_5$$이며, 따라서 연결 그래프이기도 합니다.

정점이 $$N$$개인 무방향 완전 그래프의 간선 수는 서로 다른 두 정점을 고르는 방법 수와 같습니다.

$$
\lvert E\rvert=\binom{N}{2}=\frac{N(N-1)}{2}.
$$

<details markdown="block">
<summary markdown="span">Derivation: Why an undirected complete graph has N(N-1)/2 edges</summary>

각 정점은 나머지 $$N-1$$개 정점과 연결됩니다. 이를 모든 정점에 대해 세면 $$N(N-1)$$이지만, 간선 $$\{u,v\}$$를 $$u$$에서 한 번, $$v$$에서 한 번 중복해 셉니다. 따라서 2로 나누어 $$N(N-1)/2$$가 됩니다. $$N=5$$이면 $$5\cdot4/2=10$$으로, 원문 오른쪽의 $$K_5$$가 가진 간선 수와 일치합니다.

</details>

### 1.4 Weighted graph와 directed graph

가중치 그래프는 간선마다 비용, 거리, 시간 같은 값 $$w(u,v)$$를 둡니다. 방향 그래프는 이동 가능 방향까지 포함합니다. 둘을 결합한 weighted digraph에서는 $$(u,v)$$와 $$(v,u)$$의 존재 여부와 가중치가 각각 다를 수 있습니다.

예를 들어 A에서 B까지 5분, B에서 A까지 8분이 걸리는 일방통행 도로가 있다면 `A → B`의 가중치는 5, `B → A`의 가중치는 8입니다. 두 방향을 하나의 무방향 간선으로 합치면 정보가 사라집니다.

## 2. Graph in AI: 관계 자체가 입력 정보다

강의는 지식 그래프, 그래프 신경망, 자율주행용 도로 그래프를 예로 듭니다. 공통점은 개별 객체의 특성만으로는 충분하지 않고, **객체 사이의 연결 관계가 예측에 필요한 정보**라는 점입니다.

- **Knowledge graph:** 사람·장소·작품 같은 개체를 정점으로, `작성했다`, `위치한다`, `소속된다` 같은 관계를 방향 있는 간선으로 표현합니다.
- **Graph neural network:** 한 정점의 표현을 만들 때 이웃 정점의 특성을 모아 반영합니다. 12쪽 그림은 중심 정점에서 일정 hop 안의 이웃을 표본화하고, 이웃 정보를 집계해 예측에 사용하는 흐름을 보여줍니다.
- **Road graph extraction:** 카메라나 지도에서 도로의 분기점과 연결을 추출해 자율주행 경로 계획에 사용할 구조를 만듭니다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=13" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/road-graph.jpg" | relative_url }}" alt="도로 영상에서 자율주행용 road graph를 추출하는 AI 응용을 보여주는 강의 원본 13쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 13. 픽셀 전체가 아니라 주행 가능한 도로의 연결 구조를 그래프로 요약합니다.</figcaption>
</figure>

도로 영상은 픽셀의 격자지만, 경로 계획이 묻는 것은 “어느 차선에서 어느 차선으로 이동할 수 있는가”입니다. 따라서 분기점이나 차선 중심을 정점으로, 이동 가능한 구간을 간선으로 바꾸면 탐색 알고리즘이 사용할 수 있습니다. 그래프 표현은 원본 영상을 대체하는 것이 아니라 **연결성 질문에 맞는 구조를 추가로 만드는 과정**입니다.

## 3. Adjacency Matrix

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=15" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/adjacency-matrix.jpg" | relative_url }}" alt="정점 수 N인 그래프를 N 곱하기 N 인접 행렬로 표현하는 정의와 예시를 담은 강의 원본 15쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 15. 행 i는 출발 정점, 열 j는 도착 정점으로 읽습니다.</figcaption>
</figure>

정점이 $$N=\lvert V\rvert$$개이면 인접 행렬 $$A$$는 $$N\times N$$입니다. 비가중 그래프에서는 다음처럼 정의합니다.

$$
A[i][j]=
\begin{cases}
1, & i\text{에서 }j\text{로 가는 간선이 있으면},\\
0, & \text{그렇지 않으면}.
\end{cases}
$$

무방향 그래프에서는 $$A[i][j]=A[j][i]$$이므로 행렬이 대칭입니다. Self-loop가 없는 단순 그래프라면 대각선 $$A[i][i]$$는 0입니다. 방향 그래프에서는 대칭일 필요가 없습니다. 가중치 그래프는 1 대신 가중치를 저장하되, **간선이 없음**과 **가중치 0**을 구분해야 합니다. 상황에 따라 `None`, 무한대, 별도 boolean 행렬을 사용합니다.

### 3.1 숫자 예제

방향 간선 `0 → 1`, `0 → 2`, `2 → 1`이 있는 그래프의 인접 행렬은 다음과 같습니다.

$$
A=
\begin{bmatrix}
0&1&1\\
0&0&0\\
0&1&0
\end{bmatrix}.
$$

`A[0][2]=1`은 `0 → 2`가 있음을 뜻합니다. `A[2][0]=0`이므로 반대 방향 `2 → 0`은 없습니다. 행과 열을 뒤집어 읽으면 방향까지 반대로 해석하게 됩니다.

## 4. Adjacency List

인접 리스트는 정점마다 실제로 연결된 이웃만 저장합니다. Python에서는 `graph[u]`가 정점 `u`의 이웃 리스트가 되도록 2차원 리스트로 구현할 수 있습니다. 가중치 그래프에서는 `(neighbor, weight)` 쌍을 저장합니다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=20" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/weighted-adjacency-list.jpg" | relative_url }}" alt="가중치 무방향 그래프를 인접 리스트의 이웃과 가중치 쌍으로 표현한 강의 원본 20쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 20. 무방향 간선은 양쪽 정점의 리스트에 한 번씩 나타납니다.</figcaption>
</figure>

원문 그림에서 정점 0은 `(1,5)`, `(2,3)`, `(3,2)`를 가집니다. 이는 0과 1 사이 가중치가 5, 0과 2 사이가 3, 0과 3 사이가 2라는 뜻입니다. 무방향 간선 `0—1`은 0의 리스트에 `(1,5)`, 1의 리스트에 `(0,5)`로 두 번 저장됩니다. 간선 자체가 두 개인 것은 아닙니다.

### 4.1 Matrix와 list 중 무엇을 고를까

정점 수를 $$N=\lvert V\rvert$$, 간선 수를 $$M=\lvert E\rvert$$, 정점 $$u$$의 차수를 $$\deg(u)$$라고 하겠습니다.

| 연산/비용 | Adjacency matrix | Adjacency list |
|---|---:|---:|
| 저장 공간 | $$\Theta(N^2)$$ | $$\Theta(N+M)$$ |
| 특정 간선 $$(u,v)$$ 확인 | $$\Theta(1)$$ | 일반 리스트에서 $$O(\deg(u))$$ |
| 정점 $$u$$의 모든 이웃 순회 | $$\Theta(N)$$ | $$\Theta(\deg(u))$$ |
| 희소 그래프 | 사용하지 않는 0이 많음 | 실제 연결만 저장해 유리 |
| 조밀 그래프 | 단순하고 직접 조회가 빠름 | 간선 수가 이미 $$\Theta(N^2)$$ |

무방향 인접 리스트는 각 간선을 양쪽에 저장하므로 항목 수가 $$2M$$이지만, 점근 표기는 여전히 $$\Theta(N+M)$$입니다. “행렬이 항상 나쁘다”거나 “리스트가 항상 빠르다”가 아니라, 자주 수행할 연산과 그래프 밀도에 따라 선택해야 합니다.

<details markdown="block">
<summary markdown="span">Derivation: Why adjacency-list traversal costs Theta(N + M)</summary>

모든 정점을 한 번 초기화하거나 확인하는 데 $$\Theta(N)$$이 듭니다. 각 정점의 이웃 리스트를 모두 훑으면 방향 그래프에서는 전체 항목 수가 M, 무방향 그래프에서는 2M입니다. 상수 2는 점근 표기에서 사라지므로 둘 다 $$\Theta(M)$$입니다. 합치면 $$\Theta(N+M)$$입니다.

인접 행렬에서는 각 정점마다 길이 N인 행 전체를 확인해야 하므로 $$N\cdot N=\Theta(N^2)$$입니다. 간선이 적어도 행의 0을 건너뛸 수 없기 때문입니다.

</details>

## 5. Graph Traversal

그래프 순회는 시작 정점에서 간선을 따라 정점을 방문하는 작업입니다. 다만 시작점에서 도달할 수 없는 정점까지 자동으로 방문되지는 않습니다. 그래프가 연결되어 있으면 한 번의 DFS/BFS로 모든 정점을 방문하지만, 연결되지 않았다면 **시작점이 속한 연결 요소만** 방문합니다. 전체 그래프를 순회하려면 아직 방문하지 않은 정점을 찾아 탐색을 다시 시작해야 합니다.

사이클이 있는 그래프에서는 `visited`가 필수입니다. `0—1—4—0`에서 방문 표시가 없으면 0, 1, 4, 0, 1, 4를 계속 반복합니다. 방문 표시의 시점은 구현 효율에도 영향을 줍니다.

## 6. DFS: 한 경로를 끝까지 따라간다

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=25" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/dfs-traversal.jpg" | relative_url }}" alt="0에서 출발해 한 경로를 깊게 방문하고 이전 정점으로 되돌아오는 DFS 순서를 나타낸 강의 원본 25쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 25. 실선 화살표는 깊게 진행하는 과정, 점선 화살표는 되돌아가 다음 갈래를 찾는 과정을 보여줍니다.</figcaption>
</figure>

DFS(depth-first search)는 현재 정점에서 아직 방문하지 않은 이웃 하나를 골라 계속 깊게 이동합니다. 더 갈 곳이 없으면 직전 정점으로 되돌아와 남은 이웃을 찾습니다. 재귀 호출의 call stack이 이 되돌아갈 위치를 기억하므로 재귀로 자연스럽게 구현할 수 있고, 명시적인 stack으로 같은 동작을 만들 수도 있습니다.

원문 27쪽의 그래프를 다음과 같이 저장했다고 하겠습니다.

```python
graph = [
    [1, 2, 3],
    [0, 4],
    [0, 4],
    [0, 4],
    [1, 2, 3],
]
```

이웃을 리스트 순서대로 읽는 재귀 DFS를 0에서 시작하면 방문 순서는 `0, 1, 4, 2, 3`입니다. 1에서 4로 내려간 뒤, 4의 다음 미방문 이웃 2와 3을 차례로 방문하기 때문입니다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=27" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/dfs-recursive-code.jpg" | relative_url }}" alt="재귀 DFS 코드와 다섯 정점 그래프의 인접 리스트를 제시한 강의 원본 27쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 27. 이웃 순서가 바뀌면 방문 순서도 바뀌지만, 도달 가능한 정점 집합은 같습니다.</figcaption>
</figure>

<details markdown="block">
<summary markdown="span">Code Walkthrough: Recursive and iterative DFS</summary>

원문의 `n`은 정점 수이며 실행 전 `n = len(graph)`로 정할 수 있습니다. 방문 순서를 확인할 수 있도록 결과 리스트를 반환하는 코드로 쓰면 다음과 같습니다.

~~~python
def recursive_dfs(graph, start):
    visited = [False] * len(graph)
    order = []

    def visit(v):
        visited[v] = True
        order.append(v)
        for neighbor in graph[v]:
            if not visited[neighbor]:
                visit(neighbor)

    visit(start)
    return order


def iterative_dfs(graph, start):
    visited = [False] * len(graph)
    order = []
    stack = [start]

    while stack:
        v = stack.pop()
        if visited[v]:
            continue
        visited[v] = True
        order.append(v)
        # 첫 이웃을 먼저 방문하려면 LIFO 특성 때문에 역순으로 push한다.
        for neighbor in reversed(graph[v]):
            if not visited[neighbor]:
                stack.append(neighbor)
    return order
~~~

원문 28쪽처럼 pop할 때 방문 처리하면 같은 정점이 stack에 여러 번 들어갈 수 있습니다. 정답은 유지되지만 불필요한 항목이 생깁니다. Push할 때 바로 방문 처리하는 구현도 가능하나, 재귀 DFS와 같은 순서를 원한다면 이웃을 넣는 순서까지 함께 관리해야 합니다.

</details>

## 7. BFS: 같은 거리의 정점을 한 층씩 방문한다

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=29" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/bfs-levels.jpg" | relative_url }}" alt="시작 정점 0에서 거리 1인 정점 1, 2, 3을 먼저 방문하고 거리 2인 정점 4를 방문하는 BFS 강의 원본 29쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 29. Level은 시작점에서 지나야 하는 최소 간선 수입니다.</figcaption>
</figure>

BFS(breadth-first search)는 먼저 발견된 정점을 먼저 처리하는 queue를 사용합니다. 시작점 0을 넣고 꺼내면 1, 2, 3을 이 순서로 발견해 queue 뒤에 넣습니다. 이 세 정점을 모두 처리한 뒤에야 그 다음 층의 정점 4가 처리됩니다.

위 그래프에서 0을 시작점으로 두면 다음과 같습니다.

| Queue 처리 | 새로 발견한 정점 | Queue 상태 | 확정되는 level |
|---|---|---|---:|
| 시작 | 0 | `[0]` | 0 |
| 0을 꺼냄 | 1, 2, 3 | `[1, 2, 3]` | 1 |
| 1을 꺼냄 | 4 | `[2, 3, 4]` | 2 |
| 2, 3을 꺼냄 | 없음 | `[4]` | 변화 없음 |
| 4를 꺼냄 | 없음 | `[]` | 종료 |

방문 순서는 `0, 1, 2, 3, 4`입니다. 비가중 그래프에서는 level이 시작점으로부터의 최단 간선 수이므로 BFS로 최단 거리를 구할 수 있습니다. 가중치가 서로 다르면 간선 수가 적은 경로가 비용까지 최소라는 보장이 없으므로, 음수가 없는 가중치에는 보통 Dijkstra 알고리즘을 사용합니다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf#page=31" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-12/bfs-code.jpg" | relative_url }}" alt="deque를 사용한 BFS 코드에서 시작 정점과 발견한 이웃을 방문 처리하는 강의 원본 31쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 31. 첫 방문 표시는 `visited[v]`가 아니라 아직 정의된 시작점 `visited[start]`에 해야 합니다.</figcaption>
</figure>

원문 코드의 `visited[v] = True`는 `v`가 첫 `popleft()` 전에 정의되지 않아 그대로 실행하면 `NameError`가 납니다. 의도는 `visited[start] = True`입니다. 이웃도 queue에 넣는 순간 방문 처리해야 다른 정점이 같은 이웃을 다시 enqueue하지 않습니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Corrected BFS with distances</summary>

~~~python
from collections import deque


def bfs(graph, start):
    visited = [False] * len(graph)
    distance = [-1] * len(graph)
    order = []
    queue = deque([start])
    visited[start] = True
    distance[start] = 0

    while queue:
        v = queue.popleft()
        order.append(v)
        for neighbor in graph[v]:
            if not visited[neighbor]:
                visited[neighbor] = True
                distance[neighbor] = distance[v] + 1
                queue.append(neighbor)

    return order, distance
~~~

원문 그래프에서 `bfs(graph, 0)`은 방문 순서 `[0, 1, 2, 3, 4]`, 거리 `[0, 1, 1, 1, 2]`를 반환합니다. 시작점에서 도달할 수 없는 정점은 거리 -1로 남습니다.

</details>

<details markdown="block">
<summary markdown="span">Proof: Why BFS levels are shortest-path distances in an unweighted graph</summary>

시작점의 거리를 0으로 둡니다. 거리 d인 정점을 queue에서 처리할 때 처음 발견하는 미방문 이웃은 그 정점까지의 경로 뒤에 간선 하나를 붙일 수 있으므로 거리 후보가 d+1입니다.

BFS queue에는 먼저 발견된 낮은 level의 정점이 항상 앞에 있습니다. 어떤 정점 x가 거리 d+1로 처음 발견되기 전에 더 짧은 길이 d 이하의 경로가 있었다고 가정하겠습니다. 그 경로에서 x 바로 앞 정점의 거리는 d-1 이하이므로, 그 정점은 현재 부모보다 먼저 queue에서 처리되어 x를 더 일찍 발견했어야 합니다. 이는 x가 지금 처음 발견되었다는 사실과 모순입니다.

따라서 처음 기록한 level은 더 짧아질 수 없고, 실제 경로도 존재하므로 최단 거리입니다. 이 증명은 모든 간선 비용을 동일한 1로 셀 때 성립합니다.

</details>

## 8. DFS와 BFS 비교

| 항목 | DFS | BFS |
|---|---|---|
| 진행 방식 | 한 갈래를 끝까지 탐색 후 되돌아감 | 시작점과 가까운 정점을 층별로 탐색 |
| 핵심 자료구조 | 재귀 call stack 또는 명시적 stack | queue |
| 비가중 최단 거리 | 일반적으로 보장하지 않음 | 시작점 기준 최단 간선 수 보장 |
| 인접 리스트 시간 | $$\Theta(N+M)$$ | $$\Theta(N+M)$$ |
| 추가 공간 | visited와 최대 $$O(N)$$ stack | visited와 최대 $$O(N)$$ queue |
| 순서 의존성 | 이웃 저장 순서에 따라 방문 순서 변경 | 같은 level 안의 순서가 이웃 저장 순서에 따라 변경 |

두 알고리즘의 시간복잡도가 같은 이유는 목적이 같아서가 아니라, 인접 리스트에서 각 정점을 최대 한 번 처리하고 각 간선 항목을 상수 번 확인하기 때문입니다. 탐색 순서가 다르므로 얻기 쉬운 정보도 다릅니다.

### 8.1 연결되지 않은 그래프 전체 순회

전체 정점을 빠짐없이 처리하려면 바깥 반복을 둡니다.

```python
visited = [False] * len(graph)
for start in range(len(graph)):
    if not visited[start]:
        dfs_from(start, visited)
```

탐색을 새로 시작한 횟수는 무방향 그래프의 연결 요소 수와 같습니다. 다음 강의의 Disjoint Set은 반복적인 연결과 같은 집합 여부 질의를 효율적으로 관리하고, Minimum Spanning Tree는 가중치 그래프에서 모든 정점을 최소 비용으로 연결하는 문제로 이어집니다.

## 마지막 핵심 정리

- 그래프는 객체를 정점으로, 객체 사이의 관계를 간선으로 표현합니다.
- 경로·사이클·연결성·방향·가중치는 그래프에서 물을 수 있는 문제의 조건을 결정합니다.
- 인접 행렬은 $$\Theta(N^2)$$ 공간을 사용하지만 특정 간선의 존재를 $$\Theta(1)$$에 확인합니다.
- 인접 리스트는 실제 이웃만 저장하므로 희소 그래프의 전체 순회를 $$\Theta(N+M)$$에 수행합니다.
- DFS는 재귀나 stack으로 한 갈래를 깊게 탐색하고, BFS는 queue로 같은 거리의 정점을 층별로 탐색합니다.
- 한 번의 탐색은 시작점이 속한 연결 요소만 방문합니다. 사이클에서 중복 방문을 막으려면 `visited`가 필요합니다.
- 원문 BFS 초기화는 정의되지 않은 `v`가 아니라 `start`를 방문 처리해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

| 학습 순서 | 다시 볼 부분 | 확인할 내용 |
|---:|---|---|
| 1 | pp. 5–9 | 정점·간선·경로·사이클·연결·완전·방향·가중치 정의 |
| 2 | pp. 11–13 | 지식 그래프, GNN, road graph에서 관계가 필요한 이유 |
| 3 | pp. 15–22 | 같은 그래프를 행렬과 리스트로 옮기고 공간·연산 비용 비교 |
| 4 | pp. 24–28 | DFS의 깊은 진행, 되돌아가기, 재귀와 stack의 대응 |
| 5 | pp. 29–31 | BFS queue 상태와 level별 최단 간선 수 추적 |

먼저 작은 그래프 하나를 직접 그린 뒤 인접 행렬과 인접 리스트를 모두 작성합니다. 이어서 같은 이웃 순서로 DFS와 BFS를 손으로 추적하면 저장 방식과 방문 방식의 차이가 분리됩니다. 마지막에는 그래프를 비연결 상태로 바꾸어 한 번의 탐색이 시작 연결 요소에서 멈추는지 확인합니다.

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">Q1. What do the row and column mean in a directed adjacency matrix?</summary>

답변: 행 i는 출발 정점, 열 j는 도착 정점입니다. `A[i][j]=1`이면 `i → j`가 존재합니다. 방향 그래프에서는 반대 방향 `A[j][i]`가 자동으로 1이 되지 않습니다.

</details>

<details markdown="block">
<summary markdown="span">Q2. Why is an adjacency list efficient for a sparse graph?</summary>

답변: 인접 리스트는 실제로 존재하는 이웃만 저장합니다. 정점 N개와 간선 M개의 저장 공간은 $$\Theta(N+M)$$이며, 0이 대부분인 $$N\times N$$ 행렬을 유지할 필요가 없습니다.

</details>

<details markdown="block">
<summary markdown="span">Q3. What does the DFS stack remember?</summary>

답변: 현재 경로에서 다음 이웃을 모두 확인한 뒤 돌아갈 이전 정점과 아직 처리할 갈래를 기억합니다. 재귀 DFS에서는 call stack이 이 정보를 보존하고, 반복 DFS에서는 명시적인 stack이 같은 역할을 합니다.

</details>

<details markdown="block">
<summary markdown="span">Q4. Why does BFS mark a vertex when it is enqueued?</summary>

답변: 여러 정점이 같은 이웃을 발견하더라도 queue에 한 번만 넣기 위해서입니다. Dequeue할 때까지 방문 표시를 미루면 같은 정점이 중복 enqueue되어 불필요한 작업과 parent·distance 갱신 충돌이 생길 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">Q5. When can one DFS fail to visit every vertex?</summary>

답변: 그래프가 연결되지 않았고 시작점에서 일부 정점으로 가는 경로가 없을 때입니다. 한 번의 DFS는 시작점의 연결 요소만 방문하므로, 모든 정점을 대상으로 미방문 정점에서 탐색을 다시 시작해야 합니다.

</details>

<details markdown="block">
<summary markdown="span">Q6. Why is a BFS level not the minimum cost in a weighted graph?</summary>

답변: BFS level은 지나간 간선 수만 셉니다. 간선마다 비용이 다르면 간선 한 개의 비싼 경로보다 간선 여러 개의 싼 경로가 총비용이 작을 수 있습니다. 음수가 없는 가중치의 최소 비용은 보통 Dijkstra 알고리즘으로 구합니다.

</details>

## PDF

- [lecture-12-graph-basics.pdf]({{ "/assets/pdfs/study/algorithms/lecture-12-graph-basics.pdf" | relative_url }})

## Lecture Transcript

- [Lecture 12 automatic transcript]({{ "/assets/transcripts/study/algorithms/lecture-12-graph-basics.html" | relative_url }}){: target="_blank" rel="noopener"}
