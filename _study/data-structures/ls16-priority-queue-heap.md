---
layout: default
date: 2026-05-19 12:11:10 +0900
last_modified_at: 2026-09-03 19:42:12 +0900
title: "LS16 Priority Queues and Heaps"
course: "Data Structures"
topic: "Priority Queues and Heaps"
order: 16
major_topic: "Data Structures & Algorithms"
keywords:
  - "Priority Queues"
  - "Heaps"
  - "Heap Order"
  - "Binary Heap"
  - "Heap Operations"
---

# LS16 Priority Queues and Heaps

Source PDF: `LS16_priority_queue_and_heap.pdf`

> **핵심:** **우선순위 큐가 일반 큐와 다른 점은** 들어온 순서가 아니라 우선순위로 삭제. **힙의 두 조건은** 완전 이진 트리 + heap property.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 우선순위 큐 | FIFO가 아니라 우선순위 기준으로 꺼내려면 어떻게 해야 하는가? |
| 2 | 구현 방법 비교 | 정렬/비정렬 배열은 왜 한쪽 연산이 느린가? |
| 3 | 힙 정의 | 완전 이진 트리와 heap property는 무엇인가? |
| 4 | 힙의 배열 표현 | 완전 이진 트리를 배열로 어떻게 저장하는가? |
| 5 | buildHeap/removeMax | `sift down`으로 힙 속성을 어떻게 복구하는가? |

## 1. 우선순위 큐 Priority Queue

우선순위 큐는 각 원소가 우선순위를 가지며, 우선순위가 높은 원소가 먼저 처리되는 큐다.

일반 큐는 FIFO지만, 우선순위 큐는 들어온 순서보다 우선순위가 중요하다.

## 2. 사용 예시

| 분야 | 사용 방식 |
|---|---|
| 운영체제 스케줄링 | 우선순위 높은 프로세스 먼저 실행 |
| 네트워크 패킷 처리 | 긴급 패킷 먼저 전송 |
| Dijkstra 알고리즘 | 현재 최단 거리가 가장 작은 노드 먼저 꺼냄 |
| Huffman Coding | 빈도가 낮은 노드부터 결합 |

## 3. 단순 구현의 한계

| 구현 | 삽입 | 삭제/최댓값 제거 | 문제 |
|---|---|---|---|
| 정렬되지 않은 배열/리스트 | $$O(1)$$ | $$O(n)$$ | 꺼낼 때 전체 탐색 필요 |
| 정렬된 배열/리스트 | $$O(n)$$ | $$O(1)$$ | 넣을 때 위치를 찾아야 함 |

우선순위 큐는 삽입과 삭제가 모두 자주 일어난다. 한쪽만 빠른 구조로는 부족하다.

힙은 삽입과 삭제를 모두 $$O(\log n)$$에 처리할 수 있어 우선순위 큐 구현에 적합하다.

## 4. 힙 Heap

힙은 heap property를 만족하는 완전 이진 트리다.

| 종류 | 조건 |
|---|---|
| Max Heap | 모든 노드는 자손 노드보다 크거나 같다. |
| Min Heap | 모든 노드는 자손 노드보다 작거나 같다. |

강의는 Max Heap을 중심으로 다룬다. Max Heap에서는 루트가 항상 최댓값이다.

## 5. 힙은 완전 정렬이 아니다

힙은 루트의 최댓값 또는 최솟값만 빠르게 보장한다. 전체가 정렬된 것은 아니다.

| 구조 | 탐색 |
|---|---|
| BST | 정렬 관계가 있어 평균/균형 상태에서 $$O(\log n)$$ 탐색 |
| Heap | 부분 정렬만 되어 있어 임의 값 탐색은 $$O(n)$$ |

힙은 임의 탐색에는 약하지만, 최댓값/최솟값을 반복적으로 꺼내는 일에는 강하다.

## 6. 힙의 배열 표현

힙은 완전 이진 트리이므로 배열에 빈칸 없이 저장할 수 있다.

0-based index 기준:

| 관계 | 공식 |
|---|---|
| 부모 | `(i - 1) / 2` |
| 왼쪽 자식 | `2i + 1` |
| 오른쪽 자식 | `2i + 2` |

이 공식은 힙 정렬과 우선순위 큐 구현에서 계속 사용된다.

## 7. Build Heap과 Sift Down

`buildHeap`은 임의 배열을 힙 구조로 바꾸는 작업이다.

강의에서는 마지막 내부 노드부터 루트까지 차례로 `siftDown`을 수행한다.

`siftDown`은 현재 노드가 자식보다 작으면 더 큰 자식과 교환하며 내려가는 작업이다.

```java
private void siftDown(int pos) {
    while (!isLeaf(pos)) {
        int largest = leftChild(pos);
        int rc = rightChild(pos);

        if (rc < n && Heap[rc] > Heap[largest])
            largest = rc;

        if (Heap[pos] >= Heap[largest])
            return;

        swap(pos, largest);
        pos = largest;
    }
}
```

핵심은 두 자식 중 더 큰 자식과 교환해야 Max Heap 속성이 유지된다는 점이다.

## 8. Remove Max

Max Heap에서 최댓값은 루트에 있다. 하지만 루트만 제거하면 완전 이진 트리 모양이 깨진다.

따라서 다음 순서로 처리한다.

1. 루트와 마지막 노드를 교환한다.
2. 마지막 노드를 제거하고 그 값을 반환한다.
3. 새 루트에서 `siftDown`을 수행해 heap property를 복구한다.

`siftDown`은 트리 높이만큼 내려갈 수 있으므로 `removeMax`는 $$O(\log n)$$이다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 우선순위 큐가 일반 큐와 다른 점은? | 들어온 순서가 아니라 우선순위로 삭제 |
| 힙의 두 조건은? | 완전 이진 트리 + heap property |
| Max Heap의 루트에는 무엇이 있는가? | 최댓값 |
| 힙에서 임의 원소 탐색이 느린 이유는? | 전체 정렬이 아니라 부분 정렬이기 때문 |
| `siftDown`에서 어느 자식과 바꾸는가? | 더 큰 자식 |

## Study Guide

배열 index에서 parent와 두 child 위치를 먼저 계산한 뒤, 삽입의 siftUp과 최댓값 삭제의 siftDown을 각각 손으로 수행한다. siftDown은 존재하는 자식 중 더 큰 쪽과 바꿔야 max-heap property가 유지된다는 점을 코드 조건으로 확인한다. heap은 root의 최댓값만 강하게 보장하므로 특정 key 탐색과 정렬 순회에 강한 BST와 혼동하지 않는다.

## 복습 질문

<details markdown="block">
<summary>1. 정렬된 배열로 우선순위 큐를 만들면 삽입이 왜 느린가?</summary>

답변: 새 원소를 정렬 순서에 맞는 위치에 넣어야 하기 때문이다. 위치를 찾은 뒤 그 뒤의 원소들을 한 칸씩 밀어야 하므로 삽입 비용이 $$O(n)$$이 될 수 있다.

</details>

<details markdown="block">
<summary>2. 힙과 BST는 둘 다 트리인데 탐색 성능이 왜 다른가?</summary>

답변: BST는 왼쪽 < 루트 < 오른쪽이라는 정렬 관계를 모든 서브트리에서 보장하므로 특정 key를 방향을 정해 탐색할 수 있다. 힙은 부모와 자식 사이의 우선순위 관계만 보장하고 전체 정렬 관계는 없어서 임의 key 탐색은 보통 $$O(n)$$이다.

</details>

<details markdown="block">
<summary>3. `removeMax`에서 마지막 노드를 루트로 가져오는 이유는 무엇인가?</summary>

답변: 루트의 최댓값을 제거한 뒤에도 완전 이진 트리 모양을 유지해야 하기 때문이다. 마지막 노드를 루트로 옮기면 모양은 유지되고, 이후 `siftDown`으로 heap property를 복구할 수 있다.

</details>

## Study Notes

우선순위 큐는 "먼저 들어온 것"보다 "우선순위가 높은 것"을 먼저 꺼내는 ADT다. 일반 큐의 삭제 기준은 시간 순서지만, 우선순위 큐의 삭제 기준은 key 또는 priority다.

단순한 구현은 한쪽 연산이 빠르면 다른 쪽이 느리다.

| 구현 | 삽입 | 최댓값 삭제 |
|---|---|---|
| 정렬되지 않은 배열 | 끝에 넣으면 $$O(1)$$ | 최댓값 찾기 $$O(n)$$ |
| 정렬된 배열 | 위치 찾고 밀기 $$O(n)$$ | 끝에서 삭제 $$O(1)$$ |
| 힙 | $$O(\log n)$$ | $$O(\log n)$$ |

힙은 완전 이진 트리 모양과 heap property를 동시에 만족한다. 완전 이진 트리이기 때문에 배열에 빈칸 없이 저장할 수 있고, heap property 때문에 루트에서 최댓값 또는 최솟값을 바로 알 수 있다.

0-based 배열에서 인덱스 관계는 반드시 익숙해져야 한다.

$$
\operatorname{parent}(i)=\left\lfloor\frac{i-1}{2}\right\rfloor
$$

$$
\operatorname{left}(i)=2i+1,\qquad
\operatorname{right}(i)=2i+2
$$

Max Heap에서 삽입은 보통 새 원소를 배열 끝에 붙인 뒤 위로 올린다. 이를 sift up 또는 bubble up이라고 한다. 부모보다 크면 부모와 바꾸고, heap property가 맞을 때까지 반복한다.

삭제는 반대다. 루트의 최댓값을 제거하려면 마지막 원소를 루트로 가져온 뒤 아래로 내린다. 이를 sift down이라고 한다. 두 자식 중 더 큰 자식과 비교해야 Max Heap 조건이 유지된다.

## Heap Is Not a BST

힙과 BST는 모두 트리지만 목적이 다르다.

| 구조 | 보장하는 것 | 강한 연산 |
|---|---|---|
| BST | 왼쪽 < 루트 < 오른쪽 | 특정 key 탐색, 정렬 순회 |
| Heap | 부모가 자식보다 큼 또는 작음 | 최댓값/최솟값 확인과 삭제 |

힙에서는 루트가 최댓값이라는 사실만 빠르게 보장한다. 임의의 key가 어디 있는지는 알 수 없으므로 일반 탐색은 $$O(n)$$이다.

## Build Heap Intuition

`buildHeap`은 모든 내부 노드에서 아래 방향으로 `siftDown`을 수행한다. 마지막 내부 노드부터 시작하는 이유는 리프 노드는 이미 힙 조건을 만족하기 때문이다. 아래쪽 노드는 많지만 내려갈 높이가 작고, 위쪽 노드는 적지만 내려갈 높이가 크다. 이 균형 때문에 전체 `buildHeap`은 $$O(n)$$이 된다.

### Bottom-up `buildHeap`의 level sum

> **작성자 보충 · 분류:** Floyd의 bottom-up `buildHeap`에 대한 **상한 유도와 점근적 정확한 결론**이다. $$n$$은 원소 수, $$k$$는 leaf에서 센 높이, $$T(n)$$은 비교·교환 같은 기본 연산 수이며 모두 무차원 개수다. 완전 이진 트리를 배열에 빈칸 없이 저장하고, 각 내부 노드에서 한 번씩 `siftDown`한다고 가정한다.

> **원문 추적:** `LS16_priority_queue_and_heap.pdf` pp.24–42는 bottom-up `buildHeap` 절차를 제시하지만 선형 합은 전개하지 않는다. 이 합의 강의 원형은 다음 자료인 `LS17_heap_sort.pdf` pp.21–29이며, 무한급수와 $$\Theta(n)$$ 하한 확인은 작성자 보충이다.

높이 $$k$$에 있는 노드는 최대 $$\lceil n/2^{k+1}\rceil$$개이고, 그 노드의 `siftDown`은 최대 $$k$$개 level을 내려간다. 천장 함수가 만드는 선형 이하의 항을 분리하면

$$
T(n)\le c n\sum_{k\ge1}\frac{k}{2^{k+1}}+O(n)
$$

이다. 기하급수 $$\sum_{k\ge0}x^k=1/(1-x)$$를 미분한 정확한 항등식

$$
\sum_{k\ge1}kx^k=\frac{x}{(1-x)^2}
$$

에 $$x=1/2$$를 넣으면

$$
\sum_{k\ge1}\frac{k}{2^{k+1}}
=\frac12\sum_{k\ge1}k\left(\frac12\right)^k
=1.
$$

따라서 $$T(n)=O(n)$$이고, 표준 구현은 $$\lfloor n/2\rfloor$$개의 내부 노드를 적어도 한 번 방문하므로 $$T(n)=\Theta(n)$$이다. 반면 빈 heap에 원소를 하나씩 넣는 top-down 구성은 $$i$$번째 삽입이 최대 $$O(\log i)$$이므로

$$
\sum_{i=1}^{n}O(\log i)=O(\log(n!))=O(n\log n)
$$

이며 최악에는 $$\Theta(n\log n)$$이다. 즉 $$\Theta(n)$$은 bottom-up 방식의 결론이지 모든 heap 구성법의 결론이 아니다. 직관은 비싼 긴 이동을 할 수 있는 노드가 root 근처의 소수뿐이라는 것이다. 배열이 완전 이진 트리 모양을 유지하지 않거나 각 노드에서 subtree 전체를 다시 탐색하는 구현에는 이 level-sum 분석을 그대로 적용할 수 없다.

## 배열 인덱스와 $$O(\log n)$$ 연산의 근거

> **분류:** 완전 이진 트리의 레벨 순서 배치에서 따르는 **인덱스 정리**와 높이 기반 **복잡도 증명 개요**다.

> **원문 추적:** `LS16_priority_queue_and_heap.pdf` pp.16–18은 parent·left child·right child 인덱스 식을, pp.43–51은 `removeMax`와 `siftDown` 절차를 제시한다. 레벨 구간으로부터 인덱스를 유도하는 과정은 작성자 보충이다.

0-based 배열에서 레벨 순서로 빈칸 없이 저장하면 노드 $$i$$의 두 자식은 $$2i+1,2i+2$$다. 자식 인덱스 $$j>0$$를 홀수·짝수 경우로 역산하면 두 경우 모두

$$
\operatorname{parent}(j)=\left\lfloor\frac{j-1}{2}\right\rfloor
$$

가 된다. 완전 이진 트리의 높이를 $$h$$라 하면 최대 노드 수가 $$2^{h+1}-1$$이므로 $$h=\Theta(\log n)$$이다. `siftUp`과 `siftDown`은 한 단계마다 부모 또는 자식 레벨로 정확히 한 칸 이동하므로 최대 이동 횟수는 높이와 같아 $$O(\log n)$$이다.

이 증명은 배열이 완전 이진 트리의 레벨 순서를 유지할 때만 성립한다. 중간 슬롯을 비우거나 임의 트리 모양을 같은 식으로 저장하면 자식 인덱스와 로그 높이 보장이 깨진다. 힙은 부모-자식 순서만 보장하므로 특정 key 탐색에는 어느 자식으로 가야 할지 결정할 수 없어 최악 $$O(n)$$이다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS16_priority_queue_and_heap.pdf" | relative_url }}" target="_blank" rel="noopener">LS16_priority_queue_and_heap.pdf</a></li>
</ul>
