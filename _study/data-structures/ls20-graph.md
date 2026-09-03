---
layout: default
date: 2026-05-27 11:31:26 +0900
last_modified_at: 2026-09-03 19:42:12 +0900
title: "LS20 Graph"
course: "Data Structures"
topic: "Graph"
order: 20
major_topic: "Data Structures & Algorithms"
keywords:
  - "Graphs"
  - "Vertices"
  - "Edges"
  - "Adjacency Matrix"
  - "Adjacency List"
---

# LS20 Graph

Source PDF: `LS20_graph.pdf`

> **핵심:** **그래프 $$G=(V,E)$$의 의미는** 정점 집합과 간선 집합으로 이루어진 자료 구조. **무향 그래프와 유향 그래프의 차이는** 간선 방향의 존재 여부.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 그래프 정의 | 정점과 간선으로 관계를 표현한다는 말은 무엇인가? |
| 2 | 그래프 종류 | 무향, 유향, 가중치 그래프는 어떻게 다른가? |
| 3 | 경로와 사이클 | 정점들의 나열이 언제 path 또는 cycle이 되는가? |
| 4 | 비순환 그래프 | cycle이 없다는 조건은 어떤 구조를 만드는가? |
| 5 | Graph vs Tree | 트리는 그래프 중 어떤 조건을 만족하는 특수한 경우인가? |
| 6 | 연결 요소 | 그래프가 여러 덩어리로 나뉠 때 각 덩어리를 어떻게 정의하는가? |
| 7 | SCC | 유향 그래프에서 양방향 도달 가능성은 어떻게 묶이는가? |
| 8 | 인접 행렬 | 간선 존재 여부를 빠르게 확인하려면 어떻게 저장하는가? |
| 9 | 인접 리스트 | 희소 그래프를 공간 효율적으로 저장하려면 어떻게 하는가? |
| 10 | 표현법 비교 | 어떤 상황에서 matrix 또는 list가 더 유리한가? |

20강은 그래프의 기본 용어와 표현 방법을 정리한다. 핵심은 그래프를 $$G=(V,E)$$로 보고, 정점 사이의 관계를 간선으로 표현한 뒤, 이 구조를 실제 프로그램에서 인접 행렬 또는 인접 리스트로 저장하는 것이다.

## 1. 그래프의 정의

그래프는 정점(vertex) 집합과 간선(edge) 집합으로 이루어진 자료 구조다.

$$
G=(V,E)
$$

| 기호 | 의미 |
|---|---|
| $$V$$ | 정점들의 집합 |
| $$E$$ | 간선들의 집합 |
| $$\lvert V\rvert$$ | 정점의 개수 |
| $$\lvert E\rvert$$ | 간선의 개수 |

간선은 정점 집합 $$V$$에 속한 두 정점 사이의 관계를 나타낸다. 예를 들어 사람을 정점으로 두고 친구 관계를 간선으로 두면 소셜 네트워크 그래프가 된다. 서버나 라우터를 정점으로 두고 물리적 연결을 간선으로 두면 컴퓨터 네트워크 그래프가 된다.

그래프의 강점은 "대상" 자체보다 "대상 사이의 관계"가 중요할 때 나타난다.

| 예시 | 정점 | 간선 |
|---|---|---|
| 소셜 네트워크 | 사람 | 친구 관계 |
| 웹 그래프 | 웹 페이지 | 하이퍼링크 |
| 지도 | 장소 | 도로 |
| 컴퓨터 네트워크 | 서버, 라우터 | 연결 |
| 작업 의존성 | 작업 | 선행 관계 |

## 2. 무향 그래프

무향 그래프(undirected graph)는 간선에 방향이 없는 그래프다. 정점 $$u$$와 $$v$$가 연결되어 있으면, $$u$$에서 $$v$$로 갈 수 있고 $$v$$에서 $$u$$로도 갈 수 있다고 본다.

무향 간선은 보통 순서 없는 쌍으로 생각한다.

$$
\{u,v\}
$$

따라서 다음 두 표현은 같은 연결을 의미한다.

$$
\{u,v\}=\{v,u\}
$$

친구 관계나 협업 관계처럼 상호 연결이 중요한 관계는 무향 그래프로 표현하기 좋다.

무향 그래프에서 정점의 차수(degree)는 해당 정점과 연결된 간선의 수다.

$$
\deg(v)
=
\text{number of edges incident to }v
$$

참고로 무향 그래프에서는 모든 정점 차수의 합이 간선 수의 두 배가 된다. 하나의 간선이 양끝 정점의 degree에 각각 1씩 기여하기 때문이다.

$$
\sum_{v\in V}\deg(v)=2\lvert E\rvert
$$

## 3. 유향 그래프

유향 그래프(directed graph)는 간선에 방향이 있는 그래프다. 간선 $$u\to v$$와 $$v\to u$$는 서로 다른 간선이다.

$$
(u,v)\ne(v,u)
$$

유향 그래프는 팔로우 관계, 웹 페이지 링크, 전화 발신 기록처럼 방향이 의미를 가지는 관계를 표현한다. 예를 들어 A가 B를 팔로우한다고 해서 B가 A를 팔로우하는 것은 아니다.

유향 그래프에서 degree는 두 종류로 나뉜다.

| 용어 | 의미 |
|---|---|
| in-degree | 해당 정점으로 들어오는 간선의 수 |
| out-degree | 해당 정점에서 나가는 간선의 수 |

정점 $$v$$의 진입 차수와 진출 차수는 다음처럼 쓴다.

$$
\deg^{-}(v),\qquad \deg^{+}(v)
$$

유향 그래프에서는 전체 in-degree 합과 전체 out-degree 합이 모두 간선 수와 같다.

$$
\sum_{v\in V}\deg^{-}(v)
=
\sum_{v\in V}\deg^{+}(v)
=
\lvert E\rvert
$$

## 4. 가중치 그래프

가중치 그래프(weighted graph)는 간선마다 비용 또는 weight가 붙어 있는 그래프다.

$$
w(u,v)
$$

가중치는 거리, 이동 시간, 비용, 네트워크 지연 시간, 용량 등 문제에서 중요한 수치를 표현한다.

| 예시 | weight의 의미 |
|---|---|
| 지도 그래프 | 두 장소 사이의 거리 |
| 교통 그래프 | 이동 시간 또는 혼잡도 |
| 네트워크 그래프 | 통신 비용 또는 지연 시간 |
| 작업 그래프 | 작업 전환 비용 |

가중치가 없는 그래프에서는 간선의 존재 여부만 중요하지만, 가중치 그래프에서는 어떤 경로가 더 저렴한지 또는 더 짧은지가 중요해진다. 이후 최단 경로 알고리즘을 배울 때 이 weight가 핵심 입력이 된다.

## 5. 경로

경로(path)는 정점들의 나열이다. 다음과 같은 정점열을 생각하자.

$$
v_1,v_2,\ldots,v_n
$$

모든 $$i$$에 대해 $$v_i$$와 $$v_{i+1}$$ 사이에 간선이 존재하면 이 정점열은 path다.

$$
(v_i,v_{i+1})\in E
\qquad
(1\le i<n)
$$

간선 수 기준으로 이 path의 길이는 $$n-1$$이다. 예를 들어 슬라이드의 예시처럼 `0, 4, 1, 3, 2, 4`는 인접한 정점쌍마다 간선이 있으므로 경로가 된다.

경로에 등장하는 모든 정점이 서로 다르면 단순 경로(simple path)라고 한다.

```text
0, 4, 1, 3, 2      simple path
0, 4, 1, 3, 2, 4   path, but not simple path
```

두 번째 경로는 정점 `4`가 반복되므로 단순 경로가 아니다.

## 6. 사이클

사이클(cycle)은 시작 정점에서 출발해 하나 이상의 다른 정점을 거친 뒤 다시 시작 정점으로 돌아오는 경로다. 강의에서는 길이가 3 이상인 경로 중 처음과 마지막 정점이 같은 경우로 설명한다.

```text
1, 3, 2, 4, 1
```

이 정점열은 `1`에서 시작해 다시 `1`로 돌아오므로 cycle이다.

단순 사이클(simple cycle)은 첫 번째와 마지막 정점을 제외하고는 경로상의 모든 정점이 서로 다른 cycle이다.

```text
1, 3, 2, 4, 1            simple cycle
1, 3, 2, 4, 1, 3, 2, 4, 1   cycle, but not simple cycle
```

경로와 사이클은 무향 그래프와 유향 그래프 모두에서 정의될 수 있다. 단, 유향 그래프에서는 간선의 방향을 따라 이동해야 한다.

## 7. 비순환 그래프와 DAG

비순환 그래프(acyclic graph)는 cycle이 없는 그래프다.

유향 그래프에서 cycle이 없으면 Directed Acyclic Graph, 줄여서 DAG라고 부른다.

$$
\text{DAG}=\text{Directed Acyclic Graph}
$$

DAG는 작업 순서나 의존 관계를 표현할 때 자주 쓰인다.

| 활용 | DAG로 보는 이유 |
|---|---|
| 작업 스케줄링 | 어떤 작업이 먼저 끝나야 다음 작업을 할 수 있다. |
| 패키지 의존성 | 어떤 라이브러리가 다른 라이브러리에 의존한다. |
| 선수 과목 | 특정 과목을 듣기 전에 선행 과목이 필요하다. |
| 위상 정렬 | 방향성과 비순환성을 이용해 가능한 순서를 찾는다. |

cycle이 있는 의존성 그래프에서는 "A를 하려면 B가 먼저 필요하고, B를 하려면 A가 먼저 필요하다" 같은 모순이 생길 수 있다. 그래서 scheduling과 dependency 문제에서는 DAG 조건이 중요하다.

## 8. Graph vs Tree

트리는 그래프의 한 종류다. 즉, 모든 트리는 그래프이지만 모든 그래프가 트리는 아니다.

그래프가 트리가 되려면 다음 조건을 만족해야 한다.

| 조건 | 의미 |
|---|---|
| connected | 모든 정점 사이에 경로가 존재한다. |
| acyclic | cycle이 없다. |

트리는 "연결되어 있으면서 cycle이 없는 그래프"다.

$$
\text{tree}
=
\text{connected graph}
+
\text{acyclic graph}
$$

트리에는 중요한 성질이 있다.

| 성질 | 설명 |
|---|---|
| 간선 수 | 정점이 $$n$$개이면 간선은 $$n-1$$개다. |
| 간선 제거 | 어떤 간선 하나라도 제거하면 연결성이 사라진다. |
| 최소 연결 구조 | 연결을 유지하는 데 필요한 간선만 가진다. |
| 단순 경로 | 임의의 두 정점 사이에 단순 경로가 정확히 하나만 존재한다. |

만약 connected graph에 cycle이 있으면 어떤 두 정점 사이에 둘 이상의 경로가 생길 수 있다. 반대로 graph가 acyclic이어도 disconnected라면 tree가 아니라 forest 또는 여러 component로 나뉜 그래프다.

## 9. Graph와 Tree 비교 요약

| 기준 | Graph | Tree |
|---|---|---|
| cycle | 있을 수도 있고 없을 수도 있음 | 없음 |
| connected | 연결될 수도 있고 아닐 수도 있음 | 항상 연결 |
| 두 정점 사이 단순 경로 | 여러 개일 수 있음 | 정확히 1개 |
| 간선 수 | 자유로움 | 정점 수가 $$n$$이면 $$n-1$$ |
| 포함 관계 | 더 일반적인 구조 | 그래프의 특수한 경우 |

시험에서는 "tree는 graph인가?"와 "graph는 tree인가?"를 구분하는 문제가 나오기 쉽다. 답은 다음 한 문장으로 정리된다.

> 모든 트리는 그래프이지만, 모든 그래프가 트리는 아니다.

## 10. 연결 요소

연결 요소(connected component)는 무향 그래프에서 서로 경로로 연결되어 있는 정점들의 최대 집합이다.

좀 더 풀어 쓰면 다음 두 조건을 만족한다.

1. 같은 component 안의 임의의 두 정점 사이에는 경로가 있다.
2. 그 component에 다른 정점을 더 추가하면 1번 조건이 깨진다.

즉, connected component는 "더 이상 확장할 수 없는 연결된 덩어리"다.

그래프 전체가 하나의 connected component라면 그 그래프는 connected graph다. 반대로 connected component가 여러 개라면 그래프는 disconnected graph다.

| 개념 | 의미 |
|---|---|
| connected graph | 연결 요소가 1개인 무향 그래프 |
| disconnected graph | 연결 요소가 2개 이상인 무향 그래프 |
| connected component | 최대 연결 정점 집합 |

## 11. 강연결요소

강연결요소(SCC, Strongly Connected Component)는 유향 그래프에서 정의된다. 같은 SCC에 속한 임의의 두 정점 $$u$$, $$v$$는 서로 양방향으로 도달 가능해야 한다.

$$
u\leadsto v
\quad\text{and}\quad
v\leadsto u
$$

여기서 $$u\leadsto v$$는 $$u$$에서 $$v$$로 가는 directed path가 존재한다는 뜻이다.

SCC도 connected component처럼 최대 집합이다. 즉, SCC 안에서는 모든 정점이 서로 왕복 가능하지만, 바깥 정점을 더 넣으면 이 조건이 깨진다.

| 개념 | 적용 그래프 | 핵심 조건 |
|---|---|---|
| connected component | 무향 그래프 | 경로로 서로 연결 |
| strongly connected component | 유향 그래프 | 양방향으로 서로 도달 가능 |

SCC는 directed graph를 "서로 강하게 묶인 덩어리"로 압축해서 볼 때 중요하다. SCC들을 하나의 node로 압축하면 전체 구조는 DAG 형태가 된다.

## 12. 그래프 표현 방법

그래프를 실제 프로그램에서 다루려면 $$V$$와 $$E$$를 메모리에 저장해야 한다. 대표적인 표현법은 두 가지다.

| 표현법 | 핵심 아이디어 |
|---|---|
| Adjacency Matrix | 정점 쌍마다 간선 여부를 2차원 배열에 저장 |
| Adjacency List | 각 정점마다 이웃 정점 목록을 저장 |

표현법을 고를 때 중요한 연산은 다음과 같다.

| 연산 | 질문 |
|---|---|
| edge existence | $$i$$에서 $$j$$로 가는 간선이 있는가? |
| neighbor traversal | 정점 $$i$$의 이웃은 누구인가? |
| edge enumeration | 그래프의 모든 간선을 어떻게 훑는가? |
| memory usage | 정점과 간선이 많을 때 공간을 얼마나 쓰는가? |

## 13. 인접 행렬

인접 행렬(adjacency matrix)은 정점 수가 $$\lvert V\rvert$$일 때, $$\lvert V\rvert\times\lvert V\rvert$$ 크기의 행렬 $$A$$로 그래프를 표현한다.

간선이 있으면 1, 없으면 0을 저장한다.

$$
A[i][j]
=
\begin{cases}
1 & \text{if edge } i\to j \text{ exists}\\
0 & \text{otherwise}
\end{cases}
$$

무향 그래프에서는 $$i$$와 $$j$$의 연결이 양방향으로 같은 의미이므로 인접 행렬이 대칭 행렬이 된다.

$$
A[i][j]=A[j][i]
$$

유향 그래프에서는 $$i\to j$$와 $$j\to i$$가 다르므로 일반적으로 대칭이 아니다.

가중치 그래프에서는 1 대신 weight를 저장할 수 있다. 간선이 없는 경우에는 문제에 따라 0, $$\infty$$, `null` 같은 별도 값을 둔다.

## 14. 인접 행렬의 복잡도

인접 행렬은 정점 쌍마다 칸을 하나씩 가지므로 공간 복잡도가 크다.

$$
O(\lvert V\rvert^2)
$$

간선이 거의 없는 sparse graph에서도 모든 정점 쌍의 칸을 저장해야 하므로 공간 낭비가 생긴다.

| 연산 | 복잡도 | 이유 |
|---|---|---|
| 간선 존재 여부 검사 | $$O(1)$$ | $$A[i][j]$$에 바로 접근 |
| 특정 정점의 이웃 탐색 | $$O(\lvert V\rvert)$$ | 해당 행 전체를 확인해야 함 |
| 모든 간선 나열 | $$O(\lvert V\rvert^2)$$ | 행렬 전체를 검사해야 함 |
| 공간 복잡도 | $$O(\lvert V\rvert^2)$$ | 모든 정점 쌍을 저장 |

인접 행렬은 edge existence query가 매우 많은 dense graph에서 유리하다. 반대로 간선이 적은 그래프에서는 대부분의 칸이 0이 되므로 비효율적이다.

## 15. 인접 리스트

인접 리스트(adjacency list)는 각 정점마다 연결된 이웃 정점들의 리스트를 둔다. 전체적으로는 $$\lvert V\rvert$$개의 리스트를 가진 배열처럼 볼 수 있다.

```text
0: 1, 4
1: 0, 3
2: 3, 4
3: 1, 2
4: 0, 2
```

무향 그래프에서는 간선 $$\{u,v\}$$가 있으면 $$u$$의 리스트에 $$v$$를 넣고, $$v$$의 리스트에도 $$u$$를 넣는다.

유향 그래프에서는 보통 $$u\to v$$가 있을 때 $$u$$의 리스트에 $$v$$를 넣는다. 즉, outgoing neighbor 중심으로 저장한다. 들어오는 간선을 자주 찾아야 한다면 reverse adjacency list를 따로 둘 수도 있다.

## 16. 인접 리스트의 복잡도

인접 리스트는 존재하는 간선만 저장하므로 공간 복잡도가 효율적이다.

$$
O(\lvert V\rvert+\lvert E\rvert)
$$

| 연산 | 복잡도 | 이유 |
|---|---|---|
| 간선 존재 여부 검사 | $$O(\deg(i))$$ | 정점 $$i$$의 리스트를 찾아야 함 |
| 특정 정점의 이웃 탐색 | $$O(\deg(i))$$ | 리스트 길이만큼만 보면 됨 |
| 모든 간선 나열 | $$O(\lvert E\rvert)$$ | 존재하는 간선만 훑으면 됨 |
| 공간 복잡도 | $$O(\lvert V\rvert+\lvert E\rvert)$$ | 정점 배열과 간선 목록만 저장 |

인접 리스트는 sparse graph에 특히 유리하다. 대부분의 실제 네트워크는 가능한 모든 정점 쌍이 연결되어 있지 않으므로 인접 리스트가 자주 사용된다.

## 17. 인접 행렬 vs 인접 리스트

| 비교 | 인접 행렬 | 인접 리스트 |
|---|---|---|
| 공간 복잡도 | $$O(\lvert V\rvert^2)$$ | $$O(\lvert V\rvert+\lvert E\rvert)$$ |
| 간선 존재 여부 | $$O(1)$$ | $$O(\deg(i))$$ |
| 이웃 탐색 | $$O(\lvert V\rvert)$$ | $$O(\deg(i))$$ |
| 모든 간선 탐색 | $$O(\lvert V\rvert^2)$$ | $$O(\lvert E\rvert)$$ |

## 18. 표현 복잡도의 합으로 보는 증명

> **분류:** 저장 칸과 인접 리스트 길이를 세는 **증명 개요**다. $$n=\lvert V\rvert$$, $$m=\lvert E\rvert$$라 하자.

> **원문 추적:** `LS20_graph.pdf` pp.38–43은 adjacency matrix, pp.44–49는 adjacency list와 두 표현의 복잡도를 제시한다. degree 합으로 정확한 저장 항목 수를 세는 과정은 작성자 보충이다.

인접 행렬은 가능한 모든 순서쌍 $$(u,v)$$마다 한 칸을 두므로 $$n\times n=n^2$$칸이 필요하다. 한 정점의 이웃은 행 하나의 $$n$$칸을 검사해야 하고, 모든 간선 나열은 행렬 전체를 보므로 각각 $$\Theta(n)$$, $$\Theta(n^2)$$이다.

인접 리스트는 정점별 헤더 $$n$$개와 간선 항목을 저장한다. 유향 그래프에서는 간선당 한 항목이라 길이 합이

$$
\sum_{v\in V}\operatorname{outdeg}(v)=m,
$$

무향 그래프에서는 한 간선이 양 끝 리스트에 한 번씩 나타나므로 handshake lemma에 의해

$$
\sum_{v\in V}\deg(v)=2m.
$$

두 경우 모두 상수 2를 무시하면 저장과 전체 이웃 순회가 $$\Theta(n+m)$$이다. 이 결론은 평범한 배열/연결 리스트 표현 기준이다. 각 인접 집합을 균형 트리나 해시 테이블로 바꾸면 간선 존재 검사 비용은 $$O(\deg(v))$$와 달라질 수 있다.

정리하면 인접 행렬은 dense graph에 유리하지만 sparse graph에서는 공간을 낭비한다. 인접 리스트는 sparse graph에 유리하지만, 평범한 리스트 구현에서는 edge existence query가 한 정점의 이웃 수에 비례해 느려질 수 있다.

선택 기준은 간단하다.

| 상황 | 추천 표현 |
|---|---|
| 정점 수가 작고 간선 존재 여부를 자주 묻는다. | 인접 행렬 |
| 가능한 간선 대부분이 실제로 존재한다. | 인접 행렬 |
| 정점 수가 크고 간선이 상대적으로 적다. | 인접 리스트 |
| BFS, DFS처럼 이웃을 순회하는 연산이 많다. | 인접 리스트 |

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 그래프 $$G=(V,E)$$의 의미는? | 정점 집합과 간선 집합으로 이루어진 자료 구조 |
| 무향 그래프와 유향 그래프의 차이는? | 간선 방향의 존재 여부 |
| degree, in-degree, out-degree의 차이는? | 무향에서는 연결 간선 수, 유향에서는 들어오는 간선 수와 나가는 간선 수 |
| simple path란? | 정점이 중복되지 않는 경로 |
| simple cycle이란? | 시작과 끝 정점만 같고 나머지 정점은 중복되지 않는 cycle |
| DAG란? | 방향이 있고 cycle이 없는 그래프 |
| tree가 되기 위한 조건은? | connected and acyclic |
| connected component란? | 무향 그래프의 최대 연결 정점 집합 |
| SCC란? | 유향 그래프에서 모든 정점 쌍이 양방향으로 도달 가능한 최대 집합 |
| 인접 행렬의 장점은? | 간선 존재 여부를 $$O(1)$$에 확인 |
| 인접 리스트의 장점은? | sparse graph에서 공간 효율적이고 이웃 탐색이 빠름 |

## Study Guide

한 그래프를 vertex/edge set, adjacency matrix, adjacency list 세 형태로 다시 표현해 정보가 보존되는지 확인한다. matrix의 O(1) edge check와 list의 O(V+E) 공간·빠른 neighbor traversal을 sparse/dense 조건과 연결한다. path와 simple path, cycle과 simple cycle, acyclic graph와 connected tree, 무향 component와 directed SCC를 반례로 구분하는 것이 시험 핵심이다.

## 복습 질문

<details markdown="block">
<summary>1. 모든 트리는 그래프이지만 모든 그래프가 트리는 아닌 이유는?</summary>

답변: 트리는 connected이고 acyclic인 그래프다. 그래프는 cycle이 있을 수도 있고 disconnected일 수도 있으므로, 트리 조건을 만족하지 않는 그래프가 존재한다. 따라서 tree는 graph의 특수한 경우다.

</details>

<details markdown="block">
<summary>2. 무향 그래프에서 degree와 유향 그래프에서 in-degree/out-degree는 어떻게 다른가?</summary>

답변: 무향 그래프의 degree는 해당 정점에 연결된 간선의 수다. 유향 그래프에서는 방향이 있으므로 들어오는 간선 수인 in-degree와 나가는 간선 수인 out-degree로 나누어 센다.

</details>

<details markdown="block">
<summary>3. path와 simple path의 차이는 무엇인가?</summary>

답변: path는 인접한 정점쌍 사이에 간선이 존재하는 정점들의 나열이다. simple path는 그 path에 등장하는 모든 정점이 서로 달라야 한다. 즉, 정점이 반복되면 path일 수는 있지만 simple path는 아니다.

</details>

<details markdown="block">
<summary>4. cycle과 simple cycle의 차이는 무엇인가?</summary>

답변: cycle은 시작 정점으로 다시 돌아오는 경로다. simple cycle은 첫 번째와 마지막 정점을 제외한 나머지 정점들이 모두 서로 달라야 한다. 같은 cycle을 여러 번 반복한 경로는 cycle이지만 simple cycle은 아니다.

</details>

<details markdown="block">
<summary>5. connected component와 SCC의 가장 큰 차이는 무엇인가?</summary>

답변: connected component는 무향 그래프에서 경로로 연결된 최대 정점 집합이다. SCC는 유향 그래프에서 임의의 두 정점이 서로 양방향으로 도달 가능한 최대 정점 집합이다. SCC에서는 방향을 반드시 고려해야 한다.

</details>

<details markdown="block">
<summary>6. 인접 행렬이 sparse graph에서 비효율적인 이유는?</summary>

답변: 인접 행렬은 실제 간선이 없어도 모든 정점 쌍에 대해 칸을 저장한다. 따라서 간선 수가 적은 sparse graph에서는 대부분의 칸이 0이 되어 $$O(\lvert V\rvert^2)$$ 공간이 낭비된다.

</details>

<details markdown="block">
<summary markdown="span">7. 인접 리스트에서 간선 존재 여부 검사가 $$O(\deg(i))$$인 이유는?</summary>

답변: 정점 $$i$$에서 $$j$$로 가는 간선이 있는지 확인하려면 $$i$$의 인접 리스트 안에 $$j$$가 있는지 찾아야 한다. 이 리스트의 길이가 $$\deg(i)$$이므로 최악의 경우 $$O(\deg(i))$$ 시간이 걸린다.

</details>

<details markdown="block">
<summary>8. BFS나 DFS에는 보통 인접 리스트가 유리한 이유는?</summary>

답변: BFS와 DFS는 현재 정점의 이웃을 순회하는 작업을 반복한다. 인접 리스트는 실제 이웃만 저장하므로 한 정점의 이웃을 $$O(\deg(i))$$에 순회할 수 있다. 반면 인접 행렬은 이웃을 찾기 위해 해당 행 전체, 즉 $$O(\lvert V\rvert)$$를 확인해야 한다.

</details>

## Study Notes

LS20의 핵심은 그래프의 용어를 정확히 구분하고, 표현 방법에 따른 비용 차이를 이해하는 것이다.

먼저 그래프는 $$G=(V,E)$$로 정의된다. 정점은 대상이고, 간선은 대상 사이의 관계다. 관계에 방향이 없으면 무향 그래프, 방향이 있으면 유향 그래프, 간선에 비용이 있으면 가중치 그래프다.

Tree는 graph의 특수한 경우다. 연결되어 있고 cycle이 없어야 tree다. 이 조건 때문에 정점이 $$n$$개인 tree는 항상 간선이 $$n-1$$개이고, 임의의 두 정점 사이의 simple path가 정확히 하나다.

표현법은 trade-off다. 인접 행렬은 간선 존재 여부 확인이 빠르지만 공간이 $$O(\lvert V\rvert^2)$$이다. 인접 리스트는 공간이 $$O(\lvert V\rvert+\lvert E\rvert)$$라 sparse graph에 좋고, 이웃 순회가 빠르다.

## Common Pitfalls

| 실수 | 올바른 이해 |
|---|---|
| path는 항상 정점이 중복되면 안 된다고 생각한다. | 정점 중복이 없는 것은 simple path다. 일반 path는 반복될 수 있다. |
| cycle과 simple cycle을 같은 말로 쓴다. | simple cycle은 시작/끝 외에는 정점이 반복되지 않아야 한다. |
| acyclic이면 항상 tree라고 생각한다. | tree가 되려면 acyclic뿐 아니라 connected도 필요하다. |
| 유향 그래프의 connected component를 무향 그래프처럼만 본다. | 유향 그래프에서는 양방향 도달 가능성을 보는 SCC가 중요하다. |
| 인접 행렬이 항상 더 빠르다고 생각한다. | edge check는 빠르지만 이웃 탐색과 공간 사용은 불리할 수 있다. |
| 인접 리스트의 공간을 $$O(\lvert E\rvert)$$로만 외운다. | 정점마다 리스트 헤더가 필요하므로 $$O(\lvert V\rvert+\lvert E\rvert)$$이다. |

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS20_graph.pdf" | relative_url }}" target="_blank" rel="noopener">LS20_graph.pdf</a></li>
</ul>
