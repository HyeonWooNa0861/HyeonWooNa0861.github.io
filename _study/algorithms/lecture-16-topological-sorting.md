---
layout: default
date: 2026-11-18 00:00:01 +0900
title: "Lecture 16: Topological Sorting"
course: "Algorithms"
topic: "DAG Ordering with Kahn's Algorithm and DFS Postorder"
order: 16
major_topic: "Data Structures & Algorithms"
keywords:
  - "Topological Sorting"
  - "Directed Acyclic Graph"
  - "Kahn's Algorithm"
  - "DFS Postorder"
  - "Indegree"
  - "Cycle Detection"
---

# Lecture 16: Topological Sorting

Source PDF: [lecture-16-topological-sorting.pdf](/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf)

여러 작업에 선후 관계가 있으면 단순히 이름이나 소요 시간으로 정렬할 수 없다. **모든 의존 관계를 지키면서 실행 가능한 순서를 만드는 문제**가 위상 정렬이다. 강의는 진입 차수가 0인 정점을 앞에서 제거하는 Kahn 알고리즘과, DFS 종료 순서를 뒤집는 방법을 비교한다.

> **핵심:** 위상 순서는 DAG에서만 존재한다. 간선 `u → v`가 있으면 결과에서 `u`가 `v`보다 앞서야 한다. Kahn은 아직 선행 작업이 없는 정점을 고르고, DFS는 후속 작업을 모두 처리한 정점을 stack에 넣는다. 두 방법 모두 인접 리스트에서 $$O(\lvert V\rvert+\lvert E\rvert)$$이다.

## 전체 흐름

| PDF 쪽 | 원문 범위 | 이 글의 대응 |
|---|---|---|
| 1–8 | 표지, 공지, SSSP 복습, 목차 | 행정 공지를 제외한 학습 범위 확인 |
| 9–11 | 라면 조리 순서와 위상 정렬 정의 | 작업 그래프, DAG, 올바른 순서의 조건 |
| 12–22 | Kahn's Algorithm | 진입 차수, 단계별 제거, 구현과 cycle 판정 |
| 23–30 | DFS-based Algorithm | postorder, stack, cycle 판정과 구현 |
| 31–34 | 요약, 다음 강의, 질문 | 두 방법 비교와 점검 문제 |

## 1. 위상 정렬은 무엇을 정렬하는가

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf#page=11" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-16/p11-definition.jpg" | relative_url }}" alt="작업 선후 관계를 방향 그래프로 나타내고 모든 간선 u v에서 u가 v보다 먼저 오도록 정렬하는 위상 정렬 정의" loading="lazy"></a>
  <figcaption>원문 PDF p. 11. 화살표의 시작 정점은 선행 작업, 도착 정점은 후행 작업이다.</figcaption>
</figure>

방향 그래프 $$G=(V,E)$$에서 간선 $$(u,v)$$는 `u를 끝낸 뒤 v를 수행할 수 있다`는 제약이다. 위상 순서 $$\pi$$는 모든 간선에 대해 다음을 만족하는 정점의 나열이다.

$$
(u,v)\in E \Longrightarrow \operatorname{pos}_{\pi}(u)<\operatorname{pos}_{\pi}(v).
$$

여기서 $$\operatorname{pos}_{\pi}(u)$$는 순서에서 정점 u의 위치다. 정점은 작업, 간선은 선행 조건이며 모두 물리 단위가 없는 식별자다.

### 1.1 순서는 하나일 필요가 없다

보충 예제로 `A → C`, `B → C`, `C → D`를 보자. A와 B 사이에는 제약이 없으므로 다음 두 순서는 모두 맞다.

```text
A, B, C, D
B, A, C, D
```

반면 `A, C, B, D`는 `B → C`를 어기므로 틀리다. 따라서 출력이 예상 답안과 문자 그대로 같지 않아도 **모든 정점을 한 번씩 포함하고 모든 간선 방향을 지키면** 올바른 위상 순서다.

### 1.2 cycle이 있으면 왜 불가능한가

`A → B → C → A`라면 A는 B보다 앞, B는 C보다 앞, C는 다시 A보다 앞이어야 한다. 선형 순서에서 이 세 조건을 동시에 만족할 수 없다. 위상 정렬의 입력 조건이 DAG, 즉 directed acyclic graph인 이유다.

## 2. Kahn's Algorithm: 선행 작업이 없는 정점부터

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf#page=13" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-16/p13-kahn-steps.jpg" | relative_url }}" alt="진입 간선이 없는 정점을 선택해 결과에 넣고 해당 정점과 간선을 제거하는 Kahn 알고리즘 단계" loading="lazy"></a>
  <figcaption>원문 PDF p. 13. 진입 간선이 0이라는 말은 아직 남은 선행 작업이 없다는 뜻이다.</figcaption>
</figure>

정점 v의 진입 차수 $$\operatorname{indegree}(v)$$는 v로 들어오는 간선 수다. 진입 차수가 0이면 현재 남아 있는 그래프에서 먼저 처리해도 위반할 선행 조건이 없다.

1. 모든 정점의 진입 차수를 센다.
2. 진입 차수가 0인 정점을 자료구조 `S`에 넣는다.
3. `S`에서 정점 u를 꺼내 결과 뒤에 붙인다.
4. u에서 나가는 모든 간선 `u → v`를 제거한 효과로 `indegree[v]`를 1 줄인다.
5. 새로 0이 된 v를 `S`에 넣는다.
6. `S`가 빌 때까지 반복한다.

원문 21–22쪽은 진입 차수 배열을 `dist`라고 쓴다. 이 값은 최단 거리 distance가 아니라 **indegree count**다. 의미를 드러내려면 `indegree`라는 이름이 안전하다. 실제 간선을 지울 필요도 없다. u를 한 번 처리할 때 u의 인접 리스트를 순회해 카운트만 줄이면 된다.

### 2.1 작은 수치 예제

앞의 보충 그래프에서 초기 진입 차수는 다음과 같다.

| 정점 | A | B | C | D |
|---|---:|---:|---:|---:|
| 초기 진입 차수 | 0 | 0 | 2 | 1 |

`S=[A,B]`에서 A를 먼저 꺼내면 C의 값은 2에서 1이 된다. 이어 B를 꺼내면 C가 0이 되어 `S`에 들어간다. C를 처리하면 D도 0이 된다. 결과는 `A,B,C,D`다. Stack으로 B를 먼저 꺼내면 `B,A,C,D`가 되며 역시 맞다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf#page=20" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-16/p20-kahn-example.jpg" | relative_url }}" alt="라면 조리 작업 그래프에서 진입 차수가 0인 작업을 차례로 결과 리스트에 넣는 Kahn 알고리즘 마지막 단계" loading="lazy"></a>
  <figcaption>원문 PDF p. 20. 아래 결과 리스트는 물 붓기·점화처럼 서로 직접 의존하지 않는 작업의 순서가 달라질 수 있음을 보여 준다.</figcaption>
</figure>

원본 그림은 `냄비에 물 붓기 → 점화 → 라면 넣기`, `라면봉지 뜯기 → 라면 넣기`, `라면봉지 뜯기 → 스프 넣기`, `라면 넣기 → 계란 풀어넣기` 같은 선후 관계를 나타낸다. 아래 리스트는 정점이 제거된 순서다. 같은 시점에 진입 차수가 0인 작업이 둘 이상이면 그 사이의 선택은 자유롭다.

### 2.2 완성 구현과 cycle 판정

<details markdown="block">
<summary markdown="span">Code Walkthrough: Kahn's algorithm with explicit cycle detection</summary>

~~~python
from collections import deque


def topological_sort_kahn(graph):
    """Return one topological order, or raise ValueError for a cycle."""
    n = len(graph)
    indegree = [0] * n

    for u in range(n):
        for v in graph[u]:
            indegree[v] += 1

    ready = deque(u for u in range(n) if indegree[u] == 0)
    order = []

    while ready:
        u = ready.popleft()
        order.append(u)
        for v in graph[u]:
            indegree[v] -= 1
            if indegree[v] == 0:
                ready.append(v)

    if len(order) != n:
        raise ValueError("graph contains a directed cycle")
    return order
~~~

Cycle 안의 모든 정점은 적어도 하나의 진입 간선을 계속 가진다. 그래서 `ready`가 먼저 비고, 결과 길이가 전체 정점 수보다 작아진다. 원문 코드는 이 길이 검사를 생략하므로 DAG를 전제하면 맞지만, 일반 방향 그래프 입력에서 cycle을 명시적으로 알리려면 마지막 검사가 필요하다.

Queue 대신 stack을 쓰면 다른 정답이 나올 수 있다. 정점 번호가 작은 순서를 항상 먼저 원하면 min-heap을 사용할 수 있지만 시간은 $$O((\lvert V\rvert+\lvert E\rvert)\log \lvert V\rvert)$$ 범위로 증가한다.

</details>

## 3. DFS 방식: 끝난 작업을 뒤에서부터 쌓기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf#page=24" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-16/p24-dfs-postorder.jpg" | relative_url }}" alt="DFS에서 진출 간선이 없는 정점부터 후처리하고 종료 순서의 역순을 위상 순서로 사용하는 그래프" loading="lazy"></a>
  <figcaption>원문 PDF p. 24. 슬라이드의 방문 순서는 정점에 처음 들어간 순서가 아니라 DFS가 끝난 postorder다.</figcaption>
</figure>

DFS가 u에 들어가면 u의 모든 후속 정점을 먼저 재귀 방문한다. u에서 갈 수 있는 정점의 처리가 모두 끝난 뒤 u를 stack에 넣으면, 후행 작업이 stack 아래쪽에 먼저 들어간다. 마지막에 stack을 꺼내거나 postorder를 뒤집으면 선행 작업이 앞에 온다.

간선 `u → v`를 보자. DFS가 u에서 v로 내려가면 v가 u보다 먼저 종료된다. 이미 v를 방문한 경우에도 DAG에서는 v가 u의 미완료 조상이 될 수 없으므로, v는 이미 종료했거나 다른 경로에서 처리된다. 따라서 종료 시각은 `finish(u) > finish(v)`이고, 이를 내림차순으로 나열하면 u가 v보다 앞선다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf#page=29" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-16/p29-dfs-stack.jpg" | relative_url }}" alt="알파벳 순서로 DFS를 수행해 후처리 시 정점을 stack에 쌓는 위상 정렬 예제" loading="lazy"></a>
  <figcaption>원문 PDF p. 29. 정점은 재귀 진입 시점이 아니라 모든 인접 정점을 처리한 시점에 stack에 들어간다.</figcaption>
</figure>

### 3.1 `visited` 두 상태만으로는 cycle을 못 찾는다

원문 30쪽 코드는 DAG 입력을 전제로 한 위상 순서는 계산하지만, 처리 중인 조상으로 돌아가는 back edge를 구분하지 않는다. 일반 입력까지 검증하려면 세 상태를 사용한다.

- 0: 아직 방문하지 않음
- 1: 현재 재귀 경로에서 처리 중
- 2: 모든 후속 정점 처리 완료

처리 중인 정점으로 향하는 간선을 만나면 directed cycle이다.

<details markdown="block">
<summary markdown="span">Derivation and code: Why reverse postorder works, including cycle detection</summary>

~~~python
def topological_sort_dfs(graph):
    n = len(graph)
    state = [0] * n
    postorder = []

    def dfs(u):
        state[u] = 1
        for v in graph[u]:
            if state[v] == 0:
                dfs(v)
            elif state[v] == 1:
                raise ValueError("graph contains a directed cycle")
        state[u] = 2
        postorder.append(u)

    for u in range(n):
        if state[u] == 0:
            dfs(u)

    return list(reversed(postorder))
~~~

정확성은 모든 간선 `u → v`에 대해 역 postorder에서 u가 v보다 앞섬을 보이면 된다.

1. DFS가 u를 처리할 때 v가 미방문이면 v의 재귀 호출이 완전히 끝난 뒤 u가 끝난다.
2. v가 완료 상태면 v는 이미 postorder에 있고, u는 그 뒤에 추가된다.
3. v가 처리 중이면 `u → v`는 조상으로 돌아가는 간선이며 cycle이므로 위상 순서가 없다.
4. DAG에서는 1 또는 2만 남아 postorder에서 v가 u보다 앞선다. 전체를 뒤집으면 u가 v보다 앞선다.

</details>

## 4. 두 방법 비교

| 기준 | Kahn | DFS postorder |
|---|---|---|
| 핵심 상태 | 남은 진입 차수 | 방문 상태와 종료 순서 |
| 결과를 만드는 방향 | 앞에서부터 확정 | 뒤에서부터 쌓은 뒤 반전 |
| cycle 판정 | 결과 길이가 전체 정점 수보다 작음 | 처리 중 정점으로 향하는 edge |
| 자료구조 | Queue/stack/heap | 재귀 stack 또는 명시적 stack |
| 시간·공간 | $$O(V+E)$$ / $$O(V)$$ | $$O(V+E)$$ / $$O(V)$$ |

두 알고리즘 모두 각 정점을 상수 번, 각 간선을 한 번 확인한다. 인접 행렬을 쓰면 이웃 확인만으로 $$O(V^2)$$가 될 수 있으므로 강의처럼 인접 리스트를 전제해야 $$O(V+E)$$다.

## 마지막 핵심 정리

- 위상 정렬은 모든 의존 간선의 방향을 지키는 DAG의 선형 순서다.
- Kahn은 indegree가 0인 정점을 결과 앞에서부터 확정하고, 결과 길이로 cycle을 검출한다.
- DFS는 정점을 처음 발견한 순서가 아니라 종료한 postorder를 뒤집는다.
- Tie-breaking에 따라 결과가 달라도 모든 간선 제약을 지키면 정답이다.
- 인접 리스트를 사용하면 두 방법 모두 시간은 $$O(V+E)$$, 보조 공간은 $$O(V)$$다.

## Study Guide

먼저 p. 11의 모든 화살표를 “앞 작업 → 뒤 작업”으로 읽고, 서로 직접 연결되지 않은 작업의 순서를 바꿔 본다. 다음으로 p. 20에서 한 정점을 제거할 때 어느 정점의 indegree가 줄어드는지 표로 적는다. 마지막으로 p. 24의 DFS 그림에서 discovery 순서와 finish 순서를 따로 기록하면 두 알고리즘의 방향 차이가 선명해진다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Why can a DAG have more than one topological order?</summary>

답변: 서로 사이에 경로 제약이 없는 두 정점은 어느 쪽을 먼저 놓아도 간선을 어기지 않는다. Kahn의 ready 집합에 동시에 들어온 정점의 선택 순서가 다른 정답을 만든다.

</details>

<details markdown="block">
<summary markdown="span">2. What does an empty ready queue with unprocessed vertices mean?</summary>

답변: 남은 모든 정점이 진입 간선을 하나 이상 가진다는 뜻이다. 이 간선들을 따라가면 유한한 정점 중 하나를 다시 만나므로 directed cycle이 있다. 따라서 완전한 위상 순서가 없다.

</details>

<details markdown="block">
<summary markdown="span">3. Why does DFS use postorder instead of preorder?</summary>

답변: Preorder는 선행 정점에 들어온 직후 기록하므로 다른 시작점이나 cross edge의 제약을 모두 확인하기 전이다. Postorder는 모든 후행 정점이 끝난 뒤 현재 정점을 기록한다. 이를 뒤집으면 선행 정점이 후행 정점보다 앞에 온다.

</details>

<details markdown="block">
<summary markdown="span">4. How can a proposed order be verified in linear time?</summary>

답변: 각 정점의 결과 위치를 배열 `pos`에 저장한다. 모든 간선 `u→v`를 한 번 순회하며 `pos[u] < pos[v]`인지 확인한다. 정점 중복·누락 검사까지 포함해 시간은 $$O(V+E)$$다.

</details>

## English Summary

Topological sorting linearizes dependency constraints in a directed acyclic graph. Kahn's algorithm repeatedly removes zero-indegree vertices, while the DFS method reverses postorder. Both run in $$O(V+E)$$ with adjacency lists. A complete implementation must also detect cycles: Kahn checks whether every vertex was emitted, and DFS detects an edge to an active ancestor.

## PDF

- [Lecture 16: Topological Sorting — Source PDF](/assets/pdfs/study/algorithms/lecture-16-topological-sorting.pdf)

## References

- Youngwook Kim, *Algorithms — Topological Sorting*, provided lecture slides, pp. 1–34.
