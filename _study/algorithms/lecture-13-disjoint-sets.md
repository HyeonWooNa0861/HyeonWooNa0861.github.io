---
layout: default
date: 2026-10-29 00:11:17 +0900
title: "Lecture 13: Disjoint Sets"
course: "Algorithms"
topic: "Union-Find, Union by Rank, and Path Compression"
order: 13
major_topic: "Data Structures & Algorithms"
keywords:
  - "Disjoint Sets"
  - "Union-Find"
  - "Union by Rank"
  - "Path Compression"
  - "Connected Components"
  - "Amortized Analysis"
---

# Lecture 13: Disjoint Sets

Source PDF: [13 Disjoint Sets.pdf](/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf)

두 원소가 같은 집합에 속하는지 반복해서 확인하면서, 필요할 때 두 집합을 합치는 문제를 생각하자. 매번 집합의 모든 원소를 비교할 필요는 없다. **각 집합에 대표 원소를 하나 정하고, 두 원소의 대표가 같은지 확인하면 된다.** 이 연산을 효율적으로 지원하는 자료구조가 서로소 집합 자료구조, 또는 Union-Find다.

> **핵심:** 배열에 집합 번호를 직접 저장하면 조회는 빠르지만 합칠 때 많은 값을 바꿔야 한다. 트리에서는 두 root만 연결해 합칠 수 있지만, 트리가 길어지면 조회가 느려진다. Union by rank는 합칠 때 높이 증가를 억제하고, path compression은 조회한 경로를 짧게 만든다. 두 기법의 역할과 대표 반환값을 구분하는 것이 핵심이다.

## 전체 흐름

| PDF 쪽 | 원문 범위 | 핵심 질문 |
|---|---|---|
| 1–5 | 표지, Graph Basics 복습, 목차 | 그래프의 연결 여부를 어떻게 관리하는가? |
| 6–10 | Disjoint의 뜻, 세 연산, 집합 표현 문제 | 무엇을 반환하고 언제 합치는가? |
| 11–13 | 집합 번호 배열 | 조회가 빠른 대신 무엇을 갱신해야 하는가? |
| 14–15 | Root를 대표로 하는 forest | Root 연결만으로 충분한 이유와 최악의 높이는? |
| 16–18 | Union by rank와 높이 분석 | 높이가 증가하는 조건은 무엇인가? |
| 19 | Path compression과 두 구현 | 어떤 parent를 바꾸며 무엇을 반환하는가? |
| 20–23 | 요약, 다음 주제 MST, 질문 | Kruskal에 어떤 연산이 필요한가? |

## 1. 서로소 집합과 세 연산

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=8" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p08-operations.jpg" | relative_url }}" alt="서로 겹치지 않는 집합을 관리하는 make-set, find-set, union과 Kruskal 및 연결 요소 응용을 제시한 원본 8쪽" loading="lazy"></a>
  <figcaption>원문 PDF p. 8. 세 연산의 정의와 그래프 알고리즘에서의 사용처.</figcaption>
</figure>

원문의 위쪽 정의에서 출발해 `make-set`, `find-set`, `union` 순으로 읽으면 된다. 오른쪽 A·B·C의 경계는 집합, 내부의 파란색·초록색·노란색 점은 각 집합의 원소다. A에는 3개, B에는 2개, C에는 3개 원소가 있으며 어느 점도 두 경계에 동시에 포함되지 않는다. 7쪽의 disjoint는 두 집합에 공통 원소가 없다는 뜻이며, 자료구조는 전체 원소를 **서로 겹치지 않는 집합들로 분할**해 관리한다. 한 원소는 정확히 한 집합에 속한다.

예를 들어 전체 원소가 $$U=\{0,1,2,3,4\}$$이면 `{0}`, `{1,3}`, `{2,4}`로 나눈 것은 가능한 분할이다. `{1,3}`과 `{3,4}`를 동시에 별개의 집합으로 두면 원소 3이 중복되므로 이 자료구조의 상태가 아니다.

| 연산 | 입력 | 결과 |
|---|---|---|
| `make_set(u)` | 아직 등록하지 않은 원소 `u` | `{u}`를 생성한다. |
| `find_set(u)` | 등록된 원소 `u` | `u`가 속한 집합의 대표 식별자를 반환한다. |
| `union(u, v)` | 두 등록 원소 | 두 원소가 속한 집합을 합친다. 이미 같으면 그대로 둔다. |

원문의 `find-set(u)`가 “u가 속한 집합”을 반환한다는 표현은 **집합 전체의 원소 목록이 아니라 그 집합을 식별하는 대표**로 이해해야 한다. 대표가 1인 집합에 4와 6이 속하면 `find_set(4) == find_set(6) == 1`이다. 대표는 가장 작은 원소일 필요가 없고, union으로 집합이 합쳐지면 바뀔 수 있다.

두 원소의 같은 집합 여부는 다음 **정의에 따른 동치 관계**다.

$$
u\sim v\quad\Longleftrightarrow\quad
\operatorname{find}(u)=\operatorname{find}(v).
$$

여기서 $$u,v$$는 원소의 식별자이고 $$\sim$$는 같은 집합에 속한다는 관계다. 식별자와 뒤에서 사용할 원소 수·높이·rank는 모두 물리 단위가 없는 정수다. `make_set`을 이미 포함된 원소에 다시 적용해 parent를 초기화하면 기존 연결을 끊을 수 있으므로, 이후 구현에서는 초기화할 때만 singleton을 만든다.

## 2. 원문 문제: 합치기와 같은 집합 여부 질의

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=9" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p09-set-queries.jpg" | relative_url }}" alt="0부터 n까지 n+1개 singleton에서 0 a b는 합집합, 1 a b는 같은 집합 여부를 묻는 원문 문제" loading="lazy"></a>
  <figcaption>원문 PDF p. 9. 초기 집합, 연산 형식과 YES/NO 출력 조건.</figcaption>
</figure>

먼저 문제 첫 줄의 `{0}, …, {n}`을 확인한다. **원소는 0부터 n까지이므로 n개가 아니라 n+1개**다. 이어서 입력의 `n m`은 최대 식별자와 연산 수를 뜻한다. `0 a b`이면 두 집합을 합치고, `1 a b`이면 대표를 비교해 `YES` 또는 `NO`를 출력한다.

### 2.1 원본 예제의 출력이 NO, NO, YES인 이유

9쪽 아래의 원본 예제는 `7 8`로 시작한다. 0부터 7까지 8개 원소에 다음 8개 연산을 수행한다.

```text
0 1 3
1 1 7
0 7 6
1 7 1
0 3 7
0 4 2
0 1 1
1 1 1
```

첫 union으로 `{1,3}`을 만들지만 7은 별개이므로 첫 질의는 `NO`다. 다음 union으로 `{6,7}`이 생겨도 `{1,3}`과는 아직 별개이므로 두 번째 질의도 `NO`다. `union(3,7)`에서 비로소 `{1,3,6,7}`이 하나가 된다. `union(4,2)`는 별도로 `{2,4}`를 만들고, `union(1,1)`은 기존 집합을 바꾸지 않는다. 마지막 질의는 같은 원소 1과 1을 비교하므로 `YES`다. 이 세 출력은 원문 예제와 일치하며 완성 구현으로도 확인했다.

### 2.2 서로 다른 두 집합이 하나가 되는 보충 예제

아래는 원문의 입력 형식으로 직접 구성한 작은 예제다. 원문이 제공한 정답 예시가 아니라, 뒤의 구현으로 실행해 확인한 예시다.

```text
Input
4 7
1 1 3
0 1 3
1 1 3
0 2 4
1 3 4
0 3 4
1 1 2

Output
NO
YES
NO
YES
```

<div class="table-scroll" markdown="block">

| 처리 | 0 이외 원소의 집합 | 확인 결과 |
|---|---|---|
| 초기 `1 1 3` | `{1}, {2}, {3}, {4}` | 1과 3은 다르므로 `NO` |
| `0 1 3`, 다음 질의 | `{1,3}, {2}, {4}` | 1과 3은 같으므로 `YES` |
| `0 2 4`, 다음 질의 | `{1,3}, {2,4}` | 3과 4는 다르므로 `NO` |
| `0 3 4`, 다음 질의 | `{1,2,3,4}` | 1과 2는 같으므로 `YES` |

</div>

*Supplementary table — 작성자 예제에서 연산별 집합 상태를 추적했다. 원소 0은 계속 singleton이다.*

10쪽 코드는 세 연산의 사용 흐름을 보여준다. 실행 가능한 프로그램으로 만들려면 먼저 `n, m`을 읽고, 자료구조를 초기화한 뒤 정확히 m개 연산을 처리해야 한다. 원문 출력 코드의 곡선 따옴표도 Python 문자열의 직선 따옴표로 바꿔야 한다. 출력은 질의에만 발생한다. 이미 같은 집합을 합치는 연산이나 `1 a a`도 정상 입력이다.

## 3. 집합 번호 배열: 조회와 합치기의 비용 교환

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=12" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p12-label-array.jpg" | relative_url }}" alt="union(4,5) 전후 집합 번호 배열에서 원소 2,5,7의 label 2가 1로 바뀌는 원본 도식" loading="lazy"></a>
  <figcaption>원문 PDF p. 12. 배열 값은 바로 집합 label이며, parent가 아니다.</figcaption>
</figure>

왼쪽 원의 `{1,4,6}`은 파란색 label 1, `{2,5,7}`은 노란색 label 2를 공유한다. 아래 배열의 인덱스가 원소이고, 칸 안의 값이 집합 번호다. 원소 0은 독립 집합이며, 그림의 인덱스 3에 있는 `/`는 이 예시에서 사용하지 않은 칸이다. 실제 `0..n` 문제의 원소 3을 제거하라는 뜻은 아니다.

`union(4,5)`는 **4와 5만 합치는 연산이 아니다.** 4의 label이 1, 5의 label이 2이므로, label 2를 가진 원소 2·5·7을 모두 label 1로 바꾼다. 오른쪽 배열에서 세 칸의 값이 바뀌는 이유다. 최종 대표 label은 1이지만, 이것은 구현이 택한 label이지 “항상 최솟값을 대표로 둔다”는 규칙은 아니다.

전체 등록 원소 수를 $$N$$이라고 하자. `find`는 `label[u]` 한 칸을 읽으므로 $$\Theta(1)$$이다. 원문의 단순 union은 배열을 훑어 같은 label을 찾으므로 서로 다른 두 집합을 합칠 때 $$\Theta(N)$$ 시간이 든다. Singleton 하나의 생성은 $$\Theta(1)$$, N개 전체 초기화는 $$\Theta(N)$$이다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Relabeling without changing the comparison target</summary>

다음은 원문의 배열 방식을 실행 가능하게 풀어 쓴 보충 코드다. `labels[i]`는 원소 i의 집합 번호이며, 리스트 길이는 N이다.

~~~python
def union_labels(labels, u, v):
    new_label = labels[u]
    old_label = labels[v]
    if new_label == old_label:
        return False
    for i in range(len(labels)):
        if labels[i] == old_label:
            labels[i] = new_label
    return True
~~~

비교할 `old_label`을 반복 전에 저장해야 한다. 반복 중 `labels[v]` 자체가 새 값으로 바뀔 수 있기 때문이다. `[0, 1, 2, 3, 1, 2, 1, 2]`에서 `union_labels(labels, 4, 5)`를 실행하면 `[0, 1, 1, 3, 1, 1, 1, 1]`이 된다. 이 검산에서는 원문의 `/` 칸 대신 실제 singleton 3을 넣었다. 이미 같은 집합이면 `False`, 새로 합쳤으면 `True`를 반환한다.

</details>

## 4. Forest: root만 연결하면 집합이 합쳐진다

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=14" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p14-parent-forest.jpg" | relative_url }}" alt="원소에서 부모로 향하는 화살표를 따라 root를 찾고 union(4,5)에서 root 2의 parent만 1로 바꾸는 forest 도식" loading="lazy"></a>
  <figcaption>원문 PDF p. 14. 아래 배열은 집합 번호가 아니라 각 노드의 parent다.</figcaption>
</figure>

이번에는 화살표를 **자식에서 부모 방향으로** 따라 읽는다. 4와 6은 1을, 5와 7은 2를 가리키며, root 1과 2는 자신을 가리킨다. 따라서 `find(4)=1`, `find(5)=2`다. `union(4,5)`에서 `parent[2]=1`로 바꾸면, 5와 7의 parent는 여전히 2여도 최종적으로 1에 도달한다.

배열 방식과 달리 모든 구성원의 값을 다시 쓰지 않아도 된다. **두 root를 찾은 뒤 root 하나의 parent만 바꾸면** 그 root의 모든 하위 노드가 같은 대표를 공유하게 된다. 다만 union의 전체 비용은 root 연결 한 번만 세어 $$O(1)$$이라고 할 수 없다. 먼저 수행하는 두 번의 find 비용을 포함해야 한다.

임의의 두 노드를 직접 연결해서도 안 된다. Root가 아닌 노드를 다른 트리에 붙이면 기존 자식 일부만 옮겨갈 수 있고, 같은 트리 안에서 연결하면 cycle이 생길 수 있다. Root를 찾고 같으면 종료하는 절차가 필요하다.

### 4.1 단순 연결은 긴 chain을 만들 수 있다

트리 높이 h는 root에서 가장 깊은 노드까지의 **간선 수**다. Singleton은 높이 0이다. 높이가 h인 경로의 find는 최대 h개 parent 간선을 따라가므로 $$O(h+1)$$이다. 강의의 $$O(h)$$ 표기는 높이가 커지는 경우의 비용을 간단히 나타낸 것이다.

항상 두 번째 root를 첫 번째 root 아래에 붙인다면 `union(1,0)`, `union(2,1)`, `union(3,2)` 뒤에 `0 → 1 → 2 → 3`이라는 chain이 생긴다. find(0)는 간선 3개를 따라간다. 같은 방법으로 N개를 잇는 최악의 높이는 $$N-1$$이므로 단순 forest의 find와 union은 최악 $$O(N)$$이다. 이 문제를 합치는 시점에서 막는 기법이 union by rank다.

## 5. Union by rank: 낮은 트리를 높은 트리 아래로

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=16" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p16-rank-attachment.jpg" | relative_url }}" alt="높이 1인 root 1 트리와 높이 2인 root 2 트리를 두 방향으로 합쳐 결과 높이 3과 2를 비교한 원본" loading="lazy"></a>
  <figcaption>원문 PDF p. 16. 같은 두 집합도 연결 방향에 따라 높이가 달라진다.</figcaption>
</figure>

위쪽 root 1 트리는 4·6을 자식으로 가지므로 높이 1이다. Root 2 트리는 `8 → 5 → 2` 경로가 있어 높이 2다. 왼쪽 아래처럼 2를 1 아래로 붙이면 `8 → 5 → 2 → 1`이 되어 높이가 3으로 증가한다. 오른쪽 아래처럼 1을 2 아래로 붙이면 가장 긴 경로가 길이 2로 유지된다.

**높이가 다른 두 트리는 낮은 쪽을 높은 쪽 아래로 붙인다.** 높이가 같으면 어느 root를 부모로 택해도 높이는 1 증가한다. 이것이 강의의 union by rank다.

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=17" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p17-height-bound.jpg" | relative_url }}" alt="Union by rank에서 높이가 다르면 큰 높이를 유지하고 같을 때만 1 증가하며 노드 수 n이 2의 h제곱 이상이라는 원본 분석" loading="lazy"></a>
  <figcaption>원문 PDF p. 17. 높이 변화의 세 경우와 지수적 최소 원소 수.</figcaption>
</figure>

위쪽 세 경우를 먼저 비교하고, 아래쪽 $$n\ge 2^h$$로 내려가면 논리가 이어진다. 경로 압축을 아직 하지 않는 union by rank에서 높이가 h가 되려면 최소 $$2^h$$개 원소가 필요하다. 여기서 원문의 n은 **그 트리의 원소 수**이며, 앞의 입력에서 최대 식별자로 사용한 n과 역할이 다르다. 혼동을 피하기 위해 아래에서는 트리 원소 수를 s로 쓴다.

$$
s\ge 2^h\quad\Longrightarrow\quad h\le\lfloor\log_2 s\rfloor.
$$

예를 들어 높이 0에는 원소 1개, 높이 1에는 최소 2개, 높이 2에는 최소 4개, 높이 3에는 최소 8개가 필요하다. 이 때문에 N개 원소의 find·union은 각각 최악 $$O(\log N)$$으로 제한된다. 이 식은 **union by rank로 만든 트리에 대한 성질**이지, 아무 트리나 높이 h이면 $$2^h$$개 노드가 필요하다는 뜻이 아니다. 단순 chain은 반례다.

<details markdown="block">
<summary markdown="span">Derivation: Why rank is bounded by the logarithm of component size</summary>

보충 증명에서는 rank r인 root의 집합에 적어도 $$2^r$$개 원소가 있다는 불변식을 쓴다. 모든 원소는 singleton으로 시작하고, rank가 다르면 높은 rank를 유지하며, 같은 rank일 때만 새 root의 rank를 1 증가시킨다고 가정한다.

1. 초기 rank는 0이고 집합 크기는 $$1=2^0$$이므로 성립한다.
2. rank가 다른 두 집합을 합치면 큰 rank r은 그대로다. 이미 그쪽에 $$2^r$$개 이상이 있었고 원소가 추가되므로 불변식은 유지된다.
3. 두 rank가 r로 같으면 각각 적어도 $$2^r$$개 원소가 있고 서로소다. 따라서 합친 집합은 적어도 $$2^r+2^r=2^{r+1}$$개를 가지며 새 rank는 r+1이다.

그러므로 크기 s인 집합의 rank는 $$r\le\lfloor\log_2 s\rfloor$$다. 경로 압축 전에는 rank가 실제 높이이고, 압축을 추가한 뒤에는 **실제 높이의 상한**으로 남는다. Find는 집합의 원소 수를 바꾸지 않으므로 위 크기 불변식도 유지된다.

Parent를 따라가면 rank가 엄격하게 증가한다. 서로 다른 rank끼리 합칠 때는 낮은 쪽에서 높은 쪽으로 연결하고, 같은 rank끼리 합칠 때는 부모 rank를 1 높이기 때문이다. 경로 압축으로 더 위의 root에 연결해도 이 성질은 유지된다. 따라서 경로 길이도 최대 root rank로 제한된다. 단, 이는 로그 상한의 증명이며, 뒤의 inverse-Ackermann 분할상환 경계를 증명한 것은 아니다.

</details>

## 6. Path compression: 찾아간 경로를 다음 조회에 재사용한다

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf#page=19" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-13-p19-path-compression.jpg" | relative_url }}" alt="find-set(10)의 경로 10,8,5,2,1을 root 1로 압축하는 도식과 반환문이 빠진 원본 재귀 및 반복 구현" loading="lazy"></a>
  <figcaption>원문 PDF p. 19. 그림의 경로 압축과 아래 코드의 반환값 누락을 구분해서 읽는다.</figcaption>
</figure>

왼쪽에서 10의 화살표를 따라가면 `10 → 8 → 5 → 2 → 1`이다. 첫 find는 간선 4개를 따라 root 1을 찾는다. 오른쪽에서는 10·8·5의 parent가 1로 바뀌고, 2는 이미 1을 직접 가리키고 있다. 이후 `find(10)`은 간선 하나만 따라가면 된다.

4와 6은 이미 1을 직접 가리켰으므로 그대로다. **방문하지 않은 노드 7은 여전히 2를 가리킨다.** 그림은 모든 노드를 한꺼번에 평탄화한 것이 아니라, 이번 find 경로만 압축한 것이다. 나중에 find(7)을 하면 `7 → 2 → 1`을 확인하고 7의 parent도 1로 바꿀 수 있다.

압축 전후 집합과 대표는 같다. 바뀌는 것은 같은 root에 도달하는 경로다. 반면 rank는 압축 뒤의 실제 높이를 다시 측정한 값으로 바꾸지 않는다. **Rank는 합치는 순서를 결정하는 이력 기반 상한**이며, 경로 압축으로 높이가 낮아져도 그대로 유지한다.

### 6.1 원문 코드에서 반드시 보완할 반환값

19쪽 재귀 코드에는 비-root 호출의 `return parent[u]`가 빠져 있고, 반복 코드에는 `return r`이 빠져 있다. Python에서 반환문 없이 끝나면 `None`을 반환한다. 재귀 버전은 직접 root의 자식인 노드에서부터 반환값이 없어지고, 더 깊은 재귀에서는 그 `None`이 parent에 저장될 수도 있다. 반복 버전은 구조를 압축해도 대표 비교에 사용할 값을 돌려주지 못한다.

이는 그림의 알고리즘이 틀렸다는 뜻이 아니라 **제시된 코드를 그대로 실행할 때 발생하는 구현 누락**이다. 다음 완성 코드에서는 root를 명시적으로 반환한다. 원본 첨부 PDF는 수정하지 않았다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Returning the representative in both versions</summary>

재귀 구현의 수정은 마지막 한 줄이다. 아래 함수는 정수 parent 배열과 올바른 forest를 전제로 한다.

~~~python
def find_recursive(parent, u):
    if parent[u] == u:
        return u
    parent[u] = find_recursive(parent, parent[u])
    return parent[u]
~~~

`10 → 8 → 5 → 2 → 1`에서 find(1)이 1을 반환하면, 호출이 돌아오면서 parent[2], parent[5], parent[8], parent[10]을 차례로 1로 바꾸고 각 호출도 1을 반환한다. 아래 완성 구현의 반복 버전은 같은 일을 두 번의 while로 수행한다. 첫 반복은 root r을 찾고, 두 번째 반복은 **바꾸기 전 parent를 t에 보관**한 뒤 경로를 압축한다. 마지막 `return r`이 질의의 비교값이다.

단순 forest처럼 긴 chain이 가능하면 재귀 깊이가 커질 수 있다. 아래에서는 Python 재귀 한도에 의존하지 않는 반복 버전을 사용한다.

</details>

## 7. 완성 구현: union by rank와 전체 경로 압축

입력 원소는 정수 `0..n`, 배열 길이는 `n+1`이다. `parent[u]`는 부모 식별자, `rank[u]`는 높이 상한이다. `union`은 새로 합쳤을 때만 `True`를 반환하며, 같은 root를 다시 합쳐도 rank를 올리지 않는다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Executable union-find and query processing</summary>

~~~python
import sys


class DisjointSet:
    def __init__(self, n):
        self.parent = list(range(n + 1))
        self.rank = [0] * (n + 1)

    def find(self, u):
        r = u
        while self.parent[r] != r:
            r = self.parent[r]
        while u != r:
            t = self.parent[u]
            self.parent[u] = r
            u = t
        return r

    def union(self, u, v):
        a, b = self.find(u), self.find(v)
        if a == b:
            return False
        if self.rank[a] < self.rank[b]:
            a, b = b, a
        self.parent[b] = a
        if self.rank[a] == self.rank[b]:
            self.rank[a] += 1
        return True


def solve(stream):
    n, m = map(int, stream.readline().split())
    dsu = DisjointSet(n)
    answers = []
    for _ in range(m):
        op, u, v = map(int, stream.readline().split())
        if op == 0:
            dsu.union(u, v)
        elif op == 1:
            answers.append("YES" if dsu.find(u) == dsu.find(v) else "NO")
    return "\n".join(answers)


if __name__ == "__main__":
    result = solve(sys.stdin)
    if result:
        print(result)
~~~

원문 입력 조건에 따라 op는 0 또는 1이고, u·v는 0 이상 n 이하라고 가정한다. `solve`는 m개 연산을 처리해 질의 결과 문자열을 반환한다. 실제 출력은 main에서 한 번 수행한다. 원문 10쪽의 사용 흐름에 초기 입력 처리, rank 관리, 두 반환값을 보완한 구현이다.

Rank가 같을 때는 이 구현이 첫 인수의 root를 유지한다. 따라서 2절 예제에서 `union(1,3)` 뒤 root는 1, `union(2,4)` 뒤 root는 2다. `union(3,4)`는 두 rank-1 root 중 1을 유지하고 rank[1]을 2로 올린다. 다른 올바른 구현은 다른 root를 선택해도 질의 답이 같을 수 있다.

Python으로 위 입력의 `NO, YES, NO, YES`를 확인했다. 같은 원소·중복 union·고립 원소 0과 작은 무작위 연산열도 직접 label을 관리하는 기준 구현과 대조했다. 기본 자료구조의 공간은 $$\Theta(N)$$이며, 이 출력 방식의 `answers`에는 질의 수만큼 문자열이 추가로 저장된다.

</details>

## 8. 복잡도: 한 번의 비용과 연산열의 비용

여기서는 $$N=n+1$$을 전체 원소 수, M을 초기화 뒤 수행하는 find·union 연산 수라고 하자. 배열 인덱싱과 parent 변경 하나를 단위 비용으로 센다.

| 방식 | Find 최악 | Union 최악 | 핵심 차이 |
|---|---|---|---|
| 집합 번호 배열, 전체 순회 relabel | $$\Theta(1)$$ | $$O(N)$$ | 조회는 한 칸, 합치기는 전체 배열 갱신 |
| 균형 없는 parent forest | $$O(N)$$ | $$O(N)$$ | 연결은 짧지만 root 탐색이 길어질 수 있음 |
| Union by rank만 적용 | $$O(\log N)$$ | $$O(\log N)$$ | 높이를 로그 이하로 제한 |
| Rank와 path compression 결합 | $$O(\log N)$$ | $$O(\log N)$$ | 연산열 기준 한 연산당 분할상환 $$O(\alpha(N))$$ |

마지막 행의 $$\alpha$$는 inverse-Ackermann 함수다. 매우 느리게 증가하지만, **모든 find가 최악 $$O(1)$$이라는 뜻은 아니다.** 아직 압축되지 않은 경로를 처음 찾는 연산은 오래 걸릴 수 있다. 그 작업으로 경로가 짧아져 뒤의 여러 연산이 저렴해지는 효과까지 연산열 전체로 분석한 것이 분할상환(amortized) 비용이다. 무작위 입력에 대한 average-case와도 다르다.

초기화까지 포함한 전체 시간의 표준 상한은 $$O(N+M\alpha(N))$$이다. 이 강의의 높이 분석만으로 이 경계를 도출할 수는 없으며, 본문의 로그 증명과 구분한다. <a href="https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/UF.html" target="_blank" rel="noopener">Princeton Algorithms의 UF 문서</a>도 rank와 path compression을 결합했을 때의 개별 최악 비용과 연산열의 비용을 별도로 제시한다. 해당 구현은 path halving을, 위 코드는 방문 경로 전체의 압축을 사용한다. 압축 방식은 다르지만 둘 다 rank와 결합한 표준 분할상환 경계를 갖는다. Inverse-Ackermann 경계의 전체 증명은 이 글의 범위에 포함하지 않는다.

## 9. 그래프에서의 사용처와 적용 범위

3쪽은 그래프 정의·표현·탐색을 복습하고, 8쪽은 연결 요소와 Kruskal을 응용으로 든다. Union-Find는 전체 그래프를 저장하는 대신 **현재까지 같은 연결 요소에 속하는지**를 관리한다.

무방향 그래프에서 간선 `(u,v)`를 추가할 때마다 union(u,v)을 수행하면, 두 정점의 find 결과가 같은지로 현재 연결 여부를 확인할 수 있다. 예를 들어 `(1,2)`, `(2,3)`을 넣은 뒤에는 1과 3의 대표가 같다. 간선 `(1,3)`을 추가하면 이미 같은 집합이므로 union은 집합을 바꾸지 않는다.

가중 무방향 그래프의 Kruskal은 간선을 가중치 순으로 검토하면서, 양 끝이 **서로 다른 집합일 때만 간선을 선택하고 합친다.** 이미 같은 집합이면 선택된 간선들로 양 끝 사이에 경로가 있으므로 새 간선을 더할 때 cycle이 생긴다. 다만 Union-Find만으로 최소 신장 트리가 만들어지는 것은 아니다. Kruskal에는 가중치 정렬과 안전한 간선 선택의 정확성 논증이 함께 필요하다. 비연결 그래프에서는 모든 정점을 잇는 하나의 트리 대신 연결 요소별 최소 신장 forest를 얻는다. 22쪽은 MST를 다음 강의 주제로 예고한다.

이 자료구조는 경로 자체, 최단 거리, 방향 그래프의 도달 가능성을 반환하지 않는다. 기본 구현은 집합을 합치기만 하므로 일반적인 간선 삭제 후의 분리도 처리하지 못한다. 정적인 그래프를 한 번 훑어 연결 요소를 찾을 때는 BFS/DFS도 적합하고, Union-Find는 간선 추가와 연결 질의가 반복되는 상황에 특히 잘 맞는다.

## Source Check

| 원문 위치 | 주의할 표현·코드 | 이 글의 해석·보완 |
|---|---|---|
| p. 8 | find가 집합을 반환한다는 표현 | 구성원 목록이 아니라 집합 대표를 반환 |
| p. 10 | 곡선 따옴표가 포함된 출력 코드 | 실행 코드에서는 `"YES"`, `"NO"`처럼 직선 따옴표 사용 |
| p. 12와 p. 14 | 비슷하게 생긴 배열 그림 | 전자는 직접 label, 후자는 parent라서 읽는 방식이 다름 |
| p. 14 | union의 root 연결 | 두 find를 포함한 전체 비용과 root 연결 한 번의 비용을 구분 |
| p. 17 | 높이 h이면 최소 $$2^h$$개 노드 | Rank 규칙으로 구성한 트리라는 전제와 singleton 높이 0을 명시 |
| p. 19 | 재귀·반복 find의 반환문 누락 | 각각 `return parent[u]`, `return r`을 추가해 실행 검증 |

## 마지막 핵심 정리

- Find는 집합의 대표를 반환한다. 대표가 같으면 같은 집합이고, 대표 값 자체가 최소 원소나 집합 크기를 뜻하지는 않는다.
- Label 배열은 합칠 때 구성원의 label을 바꾸고, forest는 root의 parent를 바꾼다. 두 배열을 같은 의미로 읽으면 안 된다.
- Union by rank는 낮은 rank를 높은 rank 아래에 붙이고, 같은 rank일 때만 1 증가시킨다. 이미 같은 root라면 아무것도 합치지 않는다.
- Path compression은 이번 find 경로만 같은 root로 단축한다. 집합은 보존하며 rank를 실제 높이로 다시 낮추지 않는다.
- Rank만으로 로그 높이를 보장하고, 압축까지 결합하면 연산열의 분할상환 비용을 더 낮춘다. 대표 반환값과 비용의 분석 단위를 함께 확인한다.

## Study Guide

먼저 12쪽과 14쪽의 `union(4,5)`에서 **어느 배열 칸이 왜 바뀌는지** 비교한다. 다음으로 16쪽의 두 연결 방향에 대해 가장 긴 경로를 직접 센다. 마지막으로 19쪽의 find(10) 경로를 그린 뒤, 방문하지 않은 7과 이미 같은 집합을 다시 합치는 경우까지 추적하면 된다. 긴 코드보다 “parent는 누구를 가리키고, find는 어떤 정수를 반환하는가”를 먼저 확인하는 편이 효과적이다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Can the representative be different from the smallest element?</summary>

답변: 그렇다. 대표는 집합을 식별하는 원소다. Union by rank는 크고 작은 식별자가 아니라 rank를 비교하므로 큰 번호가 root일 수 있다. 같은 집합의 모든 find가 같은 대표를 반환하는지가 중요하다.

</details>

<details markdown="block">
<summary markdown="span">2. Why does linking two roots merge all their descendants?</summary>

답변: 각 노드는 parent를 반복해서 따라가면 자신의 root에 도달한다. 한 root를 다른 root 아래에 연결하면 그 root에 도달하던 모든 경로가 새 root로 이어진다. 따라서 개별 자식의 parent를 모두 수정하지 않아도 같은 집합이 된다.

</details>

<details markdown="block">
<summary markdown="span">3. Does every tree of height three need eight nodes?</summary>

답변: 아니다. 일반 chain은 노드 4개로 높이 3을 만들 수 있다. 최소 $$2^h$$개라는 조건은 singleton에서 시작해 union by rank를 지킨 경우에 적용된다. 같은 높이끼리 합칠 때만 높이가 늘어나므로 그 순간 필요한 최소 원소 수가 두 배가 된다.

</details>

<details markdown="block">
<summary markdown="span">4. After compressing the path from 10, must node 7 point directly to 1?</summary>

답변: 아니다. 원본 경로는 `10 → 8 → 5 → 2 → 1`이며 7은 이 경로에 없다. 따라서 parent[7]은 2로 남는다. 다만 2가 1을 가리키므로 7의 대표도 여전히 1이다.

</details>

<details markdown="block">
<summary markdown="span">5. What goes wrong if find does not return its root?</summary>

답변: Python에서는 `None`이 반환된다. 반복 코드에서 두 find를 비교하면 서로 다른 집합도 `None == None`으로 같다고 오판할 수 있다. 재귀 코드에서는 반환된 `None`을 다른 노드의 parent에 저장해 forest 자체를 손상할 수도 있다. 압축과 대표 반환은 둘 다 필요하다.

</details>

## PDF

- [Lecture 13: Disjoint Sets — Source PDF](/assets/pdfs/study/algorithms/lecture-13-disjoint-sets.pdf)

## References

- Youngwook Kim, *Algorithms — 13. Disjoint Sets*, 제공된 강의 슬라이드, pp. 1–23.
- <a href="https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/UF.html" target="_blank" rel="noopener">Robert Sedgewick and Kevin Wayne, Algorithms, 4th Edition — UF API</a>: 대표의 의미, rank와 경로 압축을 결합한 비용 분석.
