---
layout: default
date: 2026-11-18 00:00:02 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Lecture 17: Traveling Salesman Problem"
course: "Algorithms"
topic: "State-Space Trees, Backtracking, and Branch-and-Bound"
order: 17
major_topic: "Data Structures & Algorithms"
keywords:
  - "Traveling Salesman Problem"
  - "State-Space Tree"
  - "Backtracking"
  - "Branch and Bound"
  - "Lower Bound"
  - "Pruning"
---

# Lecture 17: Traveling Salesman Problem

Source PDF: [lecture-17-traveling-salesman-problem.pdf](/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf)

외판원 문제(TSP)는 한 출발점에서 모든 정점을 정확히 한 번씩 방문하고 출발점으로 돌아오는 순회 중 비용이 가장 작은 것을 찾습니다. 가능한 순회를 모두 만들면 정답은 찾지만 경우의 수가 급격히 커집니다. 이 강의는 **state-space tree로 후보를 체계화하고, 정답이 될 수 없는 가지를 일찍 버리는 방법**을 backtracking과 branch-and-bound 순서로 설명합니다.

도시가 네 개라면 여러 방문 순서를 직접 비교할 수 있지만, 도시 수가 늘면 순서의 수가 곱셈처럼 빠르게 증가합니다. 가지치기는 현재까지의 경로가 이미 너무 비싸거나, 앞으로 아무리 싸게 이어도 기존 최선보다 나쁠 때 그 뒤의 모든 순서를 계산하지 않는 방법입니다.

> **핵심:** Backtracking은 지금까지 쓴 비용이 이미 최선보다 나쁜지 봅니다. Branch-and-bound는 현재 비용에 앞으로 반드시 들 최소 비용의 하한을 더해 더 일찍 자릅니다. 하한은 실제 가능한 완성 비용을 넘지 않아야 하며, 가지치기는 평균 탐색량을 줄여도 TSP의 최악 factorial 규모 자체를 없애지는 않습니다.

## 전체 흐름

| PDF 쪽 | 원문 범위 | 이 글의 대응 |
|---|---|---|
| 1–6 | 표지, 위상 정렬 복습, 목차 | 선수 개념과 강의 구조 |
| 7–9 | TSP 정의와 탐색 동기 | 입력·출력·순회 비용 |
| 10–16 | State-Space Tree | 고정 출발점의 후보 수와 leaf 해석 |
| 17–25 | Backtracking | 누적 비용 기반 가지치기와 조건 |
| 26–37 | Branch-and-Bound | lower bound 구성, 단계별 pruning |
| 38–41 | 요약, 다음 강의, 질문 | 방법 비교와 점검 문제 |

## 1. TSP의 입력과 출력

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=8" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p08-weighted-graph.jpg" | relative_url }}" alt="다섯 정점 사이의 방향별 가중치가 다른 완전 가중 그래프로 표현한 외판원 문제" loading="lazy"></a>
  <figcaption>원문 PDF p. 8. 화살표 방향마다 비용을 읽어야 하며, 반대 방향의 숫자가 같다고 가정할 수 없습니다.</figcaption>
</figure>

입력은 가중 방향 그래프 $$G=(V,E,w)$$입니다. 간선 비용 $$w(u,v)$$는 u에서 v로 이동하는 비용이며 단위는 문제에 따라 거리·시간·금액 등이 될 수 있습니다. 슬라이드 예제에서는 단위가 지정되지 않은 수치입니다. 원문은 connected weighted graph라고 쓰지만, **연결되어 있다는 사실만으로 모든 정점을 한 번씩 도는 Hamiltonian cycle이 보장되지는 않습니다.** 이 강의 예제처럼 모든 정점 쌍 사이를 이동할 수 있는 complete graph를 가정하거나, 없는 간선의 비용을 $$\infty$$로 두고 유효한 순회가 있는지 함께 검사해야 합니다.

방향별 비용이 다르면 역방향 순회를 같은 후보로 합칠 수 없어 대칭성을 활용하기 어렵습니다. 그러나 비용이 대칭인 TSP도 후보 수가 폭발하는 어려운 최적화 문제입니다. **비대칭성이 난이도의 유일한 원인은 아닙니다.**

출발점을 1로 고정하고 방문 순서를 $$1,v_2,\ldots,v_n,1$$이라 하면 목적함수는 다음입니다.

$$
C=w(1,v_2)+\sum_{i=2}^{n-1}w(v_i,v_{i+1})+w(v_n,1).
$$

각 정점은 중간에서 정확히 한 번 방문하고 마지막에 출발점 1로 돌아와야 합니다. `1→2→3→4→5`까지만 계산하고 되돌아오는 `5→1`을 빼면 순회 비용이 아닙니다.

## 2. State-Space Tree: 모든 선택을 한 트리에

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=16" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p16-state-space-tree.jpg" | relative_url }}" alt="출발점 1에서 미방문 정점을 하나씩 붙여 TSP 후보 순회를 만드는 state-space tree와 leaf 비용" loading="lazy"></a>
  <figcaption>원문 PDF p. 16. 한 node는 부분 경로, 한 edge는 다음 방문 정점의 선택, leaf는 출발점으로 돌아온 완성 순회입니다.</figcaption>
</figure>

Root `1`은 아직 출발점만 고른 상태입니다. `1-2`는 다음 정점으로 2를 정한 부분 경로이고, 그 자식 `1-2-3`은 3까지 정한 상태입니다. 방문하지 않은 정점만 자식으로 붙이면 leaf 하나가 완성 순회 하나에 대응합니다.

슬라이드는 brute force 경우의 수를 간단히 `n!`이라고 표현합니다. 정점 수가 n이고 **출발점 1을 고정**한 이 트리의 정확한 순열 수는 $$(n-1)!$$입니다. 방향이 없는 대칭 TSP에서 역방향 순회를 같은 것으로 간주하면 $$(n-1)!/2$$까지 줄일 수 있지만, 원본처럼 방향별 비용이 다르면 역순은 다른 비용이므로 합치면 안 됩니다.

다섯 정점에서는 출발점 뒤 네 정점의 순서가 $$4!=24$$개입니다. 원문 leaf 중 다음 두 순회를 직접 합산해 보겠습니다.

```text
1-2-3-4-5-1 = 10 + 14 + 7 + 3 + 14 = 48
1-2-5-4-3-1 = 10 + 10 + 3 + 7 + 10 = 40
```

따라서 그림에 적힌 48과 40이 재현됩니다. 현재까지 확인한 최선값을 incumbent, 여기서는 40이라고 부릅니다.

## 3. Backtracking: 현재 비용만으로도 늦지 않았는가

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=24" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p24-backtracking.jpg" | relative_url }}" alt="현재 최선 비용 40과 부분 경로 누적 비용을 비교해 TSP state-space tree를 backtracking으로 가지치기하는 예" loading="lazy"></a>
  <figcaption>원문 PDF p. 24. 가지 옆 숫자는 출발점부터 현재 node까지 이미 사용한 간선 비용의 합입니다.</figcaption>
</figure>

부분 경로 $$P=(1,v_2,\ldots,v_k)$$의 누적 비용을 $$g(P)$$라 하겠습니다. 모든 남은 간선 비용이 0 이상이면 경로를 더 확장해도 비용은 감소하지 않습니다. 현재 최선 완성 순회의 비용이 U일 때

$$
g(P)\ge U
$$

이면 P에서 출발하는 어떤 완성도 U보다 좋아질 수 없어 가지를 버릴 수 있습니다. 예를 들어 `1-3-2-4`의 누적 비용은 `10+18+21=49`입니다. 이미 40짜리 순회를 찾았다면 돌아오는 비용을 계산하기 전에도 이 가지를 버립니다.

**조건:** 이 pruning은 남은 간선 비용이 음수가 아닐 때 안전합니다. 음수 간선이 허용되면 이후 비용이 감소할 수 있으므로 현재 누적합만으로는 결론을 낼 수 없습니다.

### 3.1 Backtracking은 무엇을 줄이는가

빠르게 좋은 incumbent를 얻을수록 더 많은 가지가 잘립니다. 그러나 방문 순서가 나쁘거나 가중치가 비슷하면 거의 모든 후보를 확인할 수도 있습니다. 따라서 worst case는 여전히 $$\Theta((n-1)!)$$ 규모입니다.

## 4. Branch-and-Bound: 미래의 최소 비용까지 미리 더하기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=27" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p27-pruning-comparison.jpg" | relative_url }}" alt="Backtracking은 현재 비용, branch-and-bound는 현재 비용과 미래 추정 하한을 사용한다는 비교" loading="lazy"></a>
  <figcaption>원문 PDF p. 27. 미래 추정은 낙관적이어야 합니다. 실제 완성 비용보다 크게 잡으면 정답 가지를 잘못 자를 수 있습니다.</figcaption>
</figure>

Lower bound $$LB(P)$$는 부분 경로 P를 완성할 때 가능한 최종 비용의 **낙관적인 하한**입니다.

$$
LB(P)\le C(T)\quad\text{for every completion }T\text{ of }P.
$$

현재 최선 U에 대해 $$LB(P)\ge U$$이면 P의 모든 완성은 U보다 좋지 않으므로 잘라도 됩니다. 같은 비용의 다른 해도 보존해야 하는 목적이면 `>`일 때만 자르고, 최솟값 하나만 필요하면 `≥`도 안전합니다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=30" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p30-lower-bound.jpg" | relative_url }}" alt="각 정점의 최소 출발 간선 비용 합 33을 root lower bound로 사용하고 첫 이동별 하한을 계산한 branch-and-bound 예" loading="lazy"></a>
  <figcaption>원문 PDF p. 30. 괄호 값은 lower bound이며, 아래 `현재 사용 비용 + 아직 고정되지 않은 출발 간선의 최소 합`으로 읽습니다.</figcaption>
</figure>

원본 그래프에서 정점별 최소 out-edge는 다음과 같습니다.

| 출발 정점 | 1 | 2 | 3 | 4 | 5 | 합계 |
|---|---:|---:|---:|---:|---:|---:|
| 최소 비용 | 10 | 10 | 7 | 3 | 3 | 33 |

모든 완성 순회는 각 정점에서 정확히 한 번 나가야 합니다. 각 정점의 가장 싼 출구를 서로 독립적으로 고른 33은 실제로 하나의 유효한 순회를 만들지 못할 수 있지만, 어떤 순회도 정점별 최소보다 싼 출구를 쓸 수는 없습니다. 따라서 root의 lower bound로 안전합니다.

### 4.1 `1-2`의 lower bound가 33인 이유

`1→2`를 이미 고르면 정점 1의 출발 간선 비용은 10으로 확정됩니다. 아직 출발 간선이 고정되지 않은 정점 2,3,4,5의 최소값을 더합니다.

$$
LB(1\!\to\!2)=10+(10+7+3+3)=33.
$$

중요한 점은 이미 사용한 `1→2` 비용 10을 더한 뒤 정점 1의 최소값 10을 다시 더하지 않는 것입니다. 그렇게 하면 같은 출발 간선을 이중 계산합니다. 같은 방식으로 `1→4`는 실제 사용 비용 30과 나머지 최소 합 23을 더해 53이고, incumbent 40보다 커 바로 잘립니다.

원문 p. 35에는 `1-3` 아래의 세 형제가 모두 `1-3-2`처럼 보이는 라벨 오기가 있습니다. 누적 비용과 다음 쪽의 전개를 대조하면 왼쪽은 `1-3-2`($$28+16=44$$), 가운데는 `1-3-4`($$17+16=33$$), 오른쪽은 `1-3-5`($$19+16=35$$)입니다. 원본 PDF는 보존하고 이 글에서만 의미를 바로잡았습니다.

<details markdown="block">
<summary markdown="span">Derivation: Why the outgoing-edge lower bound is admissible</summary>

부분 경로 P에서 이미 출발 간선이 정해진 정점 집합을 F, 아직 정해지지 않은 정점을 R이라 하겠습니다. $$g(P)$$는 F에서 선택한 간선 비용의 합입니다. 각 $$u\in R$$에 대해 현재 제약을 무시하고 선택할 수 있는 최소 출발 비용을 $$m(u)$$라 두면

$$
LB(P)=g(P)+\sum_{u\in R}m(u).
$$

P를 완성한 임의의 순회 T는 R의 각 정점 u에서 정확히 하나의 출발 간선을 사용합니다. 그 비용은 정의상 $$m(u)$$ 이상입니다. 이미 고정된 F의 비용은 $$g(P)$$와 같습니다. 따라서

$$
C(T)=g(P)+\sum_{u\in R}w(u,\operatorname{next}_T(u))
\ge g(P)+\sum_{u\in R}m(u)=LB(P).
$$

이 하한은 각 최소 간선들이 같은 정점으로 들어가는 충돌이나 이미 방문한 정점을 무시하므로 실제 가능한 완성보다 작을 수 있습니다. 이것은 안전하지만 약한 bound입니다. 더 강한 bound는 방문·진입 제약이나 1-tree, assignment relaxation 등을 반영할 수 있지만 계산 비용도 커집니다.

</details>

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf#page=37" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/lecture-17/p37-bnb-result.jpg" | relative_url }}" alt="lower bound가 현재 최선 40보다 큰 가지를 제거하고 남은 TSP 후보를 비교한 branch-and-bound 최종 트리" loading="lazy"></a>
  <figcaption>원문 PDF p. 37. 회색으로 사라진 가지는 하한만으로도 40보다 좋아질 수 없다고 판정된 상태입니다.</figcaption>
</figure>

### 4.2 Backtracking과 Branch-and-Bound 비교

| 기준 | Backtracking | Branch-and-Bound |
|---|---|---|
| 판단값 | 지금까지 누적 비용 $$g(P)$$ | 하한 $$LB(P)=g(P)+미래의 최소 추정$$ |
| 자르는 이유 | 이미 incumbent보다 비쌈 | 낙관적으로 완성해도 incumbent보다 비쌈 |
| 계산 비용 | 작음 | bound 계산만큼 추가 |
| 가지치기 시점 | 상대적으로 늦음 | 좋은 bound면 더 빠름 |
| 정확성 조건 | 비용 비감소 등 pruning 조건 | admissible lower bound |

Branch-and-bound를 best-first로 구현하면 lower bound가 가장 작은 상태를 priority queue에서 먼저 꺼낼 수 있습니다. 강의의 state-space tree 그림은 원리를 보여 주며, 특정 queue 순서를 유일한 구현으로 강제하지 않습니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: A compact branch-and-bound skeleton</summary>

~~~python
from heapq import heappop, heappush
from math import inf


def tsp_branch_and_bound(weight):
    n = len(weight)
    min_out = [min(weight[u][v] for v in range(n) if v != u)
               for u in range(n)]

    # (lower_bound, cost_so_far, path, visited_mask)
    root_lb = sum(min_out)
    heap = [(root_lb, 0, (0,), 1)]
    best_cost, best_path = inf, None

    while heap:
        lb, cost, path, mask = heappop(heap)
        if lb >= best_cost:
            continue

        u = path[-1]
        if len(path) == n:
            total = cost + weight[u][0]
            if total < best_cost:
                best_cost = total
                best_path = path + (0,)
            continue

        for v in range(1, n):
            if mask & (1 << v):
                continue
            new_cost = cost + weight[u][v]
            # u's cheapest hypothetical exit is replaced by fixed u -> v.
            child_lb = lb - min_out[u] + weight[u][v]
            if child_lb < best_cost:
                heappush(heap, (child_lb, new_cost,
                                path + (v,), mask | (1 << v)))

    return best_cost, best_path
~~~

이 코드는 원문의 `각 정점 최소 out-edge` 하한을 그대로 사용한 교육용 뼈대입니다. 부분 경로가 확장될 때, 직전 정점 u의 가상 최소 출구를 실제 선택 `u→v`로 교체합니다. 완성 상태에서는 마지막 정점에서 출발점으로 돌아가는 실제 비용을 더해 후보를 검증합니다. 실제 응용에서는 없는 간선, 무한대, 음수 비용, 대칭성, 더 강한 bound를 별도로 처리해야 합니다.

</details>

## 5. 비용과 정확성 정리

- 완전탐색은 출발점 고정 시 $$(n-1)!$$개 순서를 확인하고, 순회 하나의 비용 계산까지 포함하면 단순 구현은 $$O(n!)$$ 범위입니다.
- Backtracking과 branch-and-bound는 정답을 바꾸지 않고 방문 node 수를 줄입니다.
- 좋은 incumbent와 강한 lower bound가 빠른 pruning을 만듭니다.
- 어떤 입력에서는 거의 모든 state를 방문하므로 최악 시간은 여전히 exponential/factorial입니다.
- 메모이제이션 DP(Held–Karp)는 상태 `(visited set, last vertex)`를 합쳐 $$O(n^2 2^n)$$ 시간과 $$O(n2^n)$$ 공간을 사용하지만, 이 강의의 중심 범위는 state-space pruning입니다.

## 마지막 핵심 정리

- 출발점을 고정한 directed TSP의 후보 순서는 $$(n-1)!$$개입니다.
- State-space tree의 node는 부분 경로, leaf는 출발점으로 돌아온 완성 순회입니다.
- Backtracking은 비음수 비용에서 현재 누적 비용으로, branch-and-bound는 admissible lower bound로 가지를 자릅니다.
- Prefix에서 이미 outgoing edge가 확정된 정점의 minimum을 다시 더하면 이중 계산입니다.
- 가지치기는 실제 방문 상태를 줄이지만 최악의 factorial 규모를 없애지는 않습니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

p. 8에서 방향별 숫자를 따로 읽고 p. 16의 leaf 비용 48과 40을 직접 더합니다. 그다음 p. 24의 가지 옆 숫자를 “현재까지 확정된 비용”으로, p. 30의 괄호 숫자를 “완성 비용의 낙관적 하한”으로 구분합니다. 마지막으로 incumbent 40과 각 bound를 비교하며 어떤 node가 잘리는지 표시하면 backtracking과 branch-and-bound의 차이가 드러납니다.

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Why are there (n-1)! tours after fixing the start vertex?</summary>

답변: 출발점 1의 위치는 이미 고정되었습니다. 남은 n-1개 정점을 방문하는 순서만 고르면 되므로 순열 수는 $$(n-1)!$$입니다. 방향별 비용이 다르면 역순도 다른 후보입니다.

</details>

<details markdown="block">
<summary markdown="span">2. Can a partial cost of 39 be pruned when the incumbent is 40?</summary>

답변: 현재 비용만으로는 안 됩니다. 아직 최소 하나 이상의 이동과 출발점 복귀가 남았지만 그 비용이 얼마인지 확인해야 합니다. 남은 비용의 안전한 lower bound를 더한 값이 40 이상일 때는 최적해 하나를 찾는 목적에서 자를 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">3. What happens if a lower bound is greater than a feasible completion cost?</summary>

답변: 실제로는 좋은 정답을 포함한 가지를 불가능하다고 잘라낼 수 있습니다. Lower bound는 약해서 실제 값보다 작을 수는 있지만, 같은 부분 경로의 어떤 완성 비용도 넘으면 안 됩니다.

</details>

<details markdown="block">
<summary markdown="span">4. Why is adding node 1's minimum again at state 1-2 double counting?</summary>

답변: 상태 `1-2`에서 정점 1의 outgoing edge는 이미 실제 간선 `1→2`와 비용 10으로 확정됐습니다. `g(P)`에 이 10이 들어 있는데 정점 1의 가상 minimum 10을 다시 더하면 같은 출발 선택을 두 번 셉니다.

</details>

## English Summary

The traveling salesman problem asks for a minimum-cost Hamiltonian cycle. A state-space tree enumerates permutations after fixing the start vertex. Backtracking prunes a partial route when its accumulated nonnegative cost cannot beat the incumbent. Branch-and-bound adds an admissible estimate of unavoidable future cost and can prune earlier. These techniques reduce explored states in favorable inputs but do not remove the factorial worst case.

## PDF

- [Lecture 17: Traveling Salesman Problem — Source PDF](/assets/pdfs/study/algorithms/lecture-17-traveling-salesman-problem.pdf)

## Lecture Transcript

- [Lecture 17 automatic transcript]({{ "/assets/transcripts/study/algorithms/lecture-17-traveling-salesman-problem.html" | relative_url }}){: target="_blank" rel="noopener"}

## References

- Youngwook Kim, *Algorithms — Traveling Salesman Problem*, provided lecture slides, pp. 1–41.
