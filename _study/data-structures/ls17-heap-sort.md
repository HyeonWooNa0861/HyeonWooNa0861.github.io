---
layout: default
date: 2026-05-19 12:11:10 +0900
title: "LS17 Heap Sort"
course: "Data Structures"
topic: "Heap Sort"
order: 17
major_topic: "Data Structures & Algorithms"
keywords:
  - "Heap Sort"
  - "Max Heap"
  - "Heapify"
  - "Selection Sorting"
  - "In-Place Sorting"
---

# LS17 Heap Sort

Source PDF: `LS17_heap_sort.pdf`

> **핵심:** **힙 정렬에서 처음 하는 일은** 배열을 Max Heap으로 만든다. **정렬 완료 영역은 어디서부터 생기는가** 배열의 오른쪽 끝.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 힙 복습 | Max Heap에서 최댓값은 어디에 있는가? |
| 2 | 힙 정렬 개념 | 선택 정렬을 힙으로 어떻게 개선하는가? |
| 3 | Build Heap | 배열을 힙으로 만드는 비용은 왜 \(O(n)\)인가? |
| 4 | 정렬 과정 | 루트와 마지막 원소를 바꾸며 sorted 영역을 어떻게 키우는가? |
| 5 | 복잡도 | 전체 시간과 추가 메모리는 어떻게 되는가? |

## 1. 힙 정렬의 아이디어

힙 정렬은 선택 정렬의 개선 버전으로 볼 수 있다.

선택 정렬은 매번 전체 배열에서 최댓값을 찾는다. 힙 정렬은 Max Heap을 만들어 최댓값을 루트에서 \(O(1)\)에 확인하고, 제거 후 `siftDown`으로 \(O(\log n)\)에 재정렬한다.

| 항목 | Selection Sort | Heap Sort |
|---|---|---|
| 최대값 찾기 | \(O(n)\) | \(O(1)\) |
| 재정렬 | \(O(1)\) | \(O(\log n)\) |
| 전체 시간 | \(O(n^2)\) | \(O(n\log n)\) |
| 추가 메모리 | 없음 | 없음, in-place 가능 |

## 2. 힙 정렬 과정

힙 정렬은 다음 순서로 진행된다.

1. 크기 `n` 배열을 Max Heap으로 변환한다.
2. 루트, 즉 최댓값을 배열 끝 원소와 교환한다.
3. 힙 크기를 1 줄인다. 배열 끝은 정렬 완료 영역이 된다.
4. 루트에서 `siftDown`을 수행해 남은 힙을 복구한다.
5. 힙 크기가 1이 될 때까지 반복한다.

정렬된 영역은 배열의 오른쪽 끝에서 왼쪽으로 확장된다.

```text
[ Heap 영역 ][ Sorted 영역 ]
```

## 3. Build Heap

임의 배열을 힙으로 만들 때는 마지막 내부 노드부터 루트까지 `siftDown`을 수행한다.

마지막 내부 노드부터 시작하는 이유는 리프 노드는 이미 heap property를 만족하기 때문이다. 자식이 없는 노드는 내려갈 곳이 없다.

## 4. Build Heap이 \(O(n)\)인 이유

각 노드마다 최악 \(O(\log n)\)이 걸린다고 단순히 보면 \(O(n\log n)\)처럼 보일 수 있다. 하지만 실제로는 대부분의 노드가 아래쪽에 있어 내려갈 수 있는 높이가 작다.

| 레벨 | 노드 수 | 최대 siftDown 횟수 |
|---|---|---|
| 루트 근처 | 적음 | 큼 |
| 리프 근처 | 많음 | 작음 |

이 합을 계산하면 전체 buildHeap 비용은 \(O(n)\)이다.

## 5. 루트 제거와 정렬 영역

Max Heap의 루트는 현재 힙 영역의 최댓값이다. 루트와 힙의 마지막 원소를 바꾸면 최댓값이 배열 끝으로 간다.

```text
before:
[88, 85, 83, ..., 60]

swap root with last:
[60, 85, 83, ..., 88]
                  sorted
```

그다음 힙 크기를 줄여 `88`은 더 이상 힙에 포함하지 않는다. 남은 앞부분에서만 `siftDown`을 수행한다.

## 6. 시간과 공간 복잡도

| 단계 | 비용 |
|---|---|
| buildHeap | \(O(n)\) |
| removeMax 반복 | `n`번 × \(O(\log n)\) |
| 전체 | \(O(n\log n)\) |

추가 배열 없이 원래 배열 안에서 swap하므로 in-place 정렬이다. 추가 메모리는 \(O(1)\)로 볼 수 있다.

## 7. 힙 정렬의 특징

| 장점 | 설명 |
|---|---|
| 최악 시간 보장 | 항상 \(O(n\log n)\) |
| 추가 메모리 적음 | in-place 정렬 가능 |
| 큰 입력에 안정적 | 선택 정렬보다 훨씬 효율적 |

| 단점 | 설명 |
|---|---|
| 구현 복잡 | 힙 인덱스와 `siftDown` 관리 필요 |
| 캐시 효율 | 퀵 정렬보다 실제 성능이 낮을 수 있음 |
| 안정 정렬 아님 | 같은 값의 상대 순서를 보장하지 않는 구현이 일반적 |

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 힙 정렬에서 처음 하는 일은? | 배열을 Max Heap으로 만든다. |
| 정렬 완료 영역은 어디서부터 생기는가? | 배열의 오른쪽 끝 |
| buildHeap 시간은? | \(O(n)\) |
| 전체 힙 정렬 시간은? | \(O(n\log n)\) |
| 힙 정렬은 추가 배열이 필요한가? | 필요 없다. in-place 가능 |

## Study Guide

배열을 Max Heap으로 만든 뒤 root와 마지막 원소를 교환하고 heap size를 줄여 siftDown하는 반복을 끝까지 추적한다. 오른쪽부터 확정되는 정렬 영역과 아직 heap인 왼쪽 영역의 경계를 매 단계 표시하면 구현 오류를 줄일 수 있다. buildHeap은 O(n), 전체 정렬은 O(n log n)이며 in-place지만 일반적으로 stable하지 않다는 조합이 시험 우선순위다.

## 복습 질문

<details>
<summary>1. Max Heap에서 루트와 마지막 원소를 교환하는 이유는?</summary>

답변: Max Heap의 루트는 현재 heap 영역의 최댓값이다. 루트와 마지막 원소를 교환하면 최댓값을 배열의 오른쪽 끝, 즉 정렬 완료 영역으로 보낼 수 있다.

</details>

<details>
<summary>2. 힙 크기를 줄인 뒤 `siftDown`을 해야 하는 이유는?</summary>

답변: 마지막 원소가 루트로 올라오면서 heap property가 깨질 수 있기 때문이다. 정렬 완료 영역은 제외하고 남은 heap 영역에서만 `siftDown`을 수행해 Max Heap 조건을 복구한다.

</details>

<details>
<summary>3. `buildHeap`을 단순히 \(n\log n\)으로 보지 않는 이유는 무엇인가?</summary>

답변: 모든 노드가 높이 \(\log n\)만큼 내려가는 것이 아니기 때문이다. 대부분의 노드는 리프 근처에 있어 내려갈 거리가 짧고, 루트 근처의 높은 노드는 수가 적다. 이 비용을 모두 합하면 \(O(n)\)이 된다.

</details>

## Study Notes

힙 정렬은 "최댓값을 반복해서 꺼내 오른쪽부터 채우는 정렬"이다. 선택 정렬도 매번 최댓값 또는 최솟값을 고르지만, 선택 정렬은 찾는 데 \(O(n)\)이 걸린다. 힙 정렬은 Max Heap을 사용해 최댓값을 루트에서 바로 확인한다.

과정은 다음처럼 영역을 나누어 보면 쉽다.

```text
[ heap area | sorted area ]
```

처음에는 전체 배열이 heap area다. 루트의 최댓값을 heap area의 마지막 원소와 바꾸면, 최댓값이 배열 오른쪽 끝으로 이동한다. 그 위치는 이제 sorted area가 된다.

```text
before
[88, 85, 83, 60, 70]

swap root and last
[70, 85, 83, 60, 88]
                 sorted
```

하지만 `70`이 루트로 올라오면서 heap property가 깨질 수 있다. 그래서 heap size를 하나 줄인 뒤, 남은 heap area에서 루트부터 `siftDown`을 수행한다.

## Why Build Heap Is O(n)

모든 노드에 `siftDown`을 하면 \(n\log n\)처럼 보이지만, 실제로는 \(O(n)\)이다. 대부분의 노드가 아래쪽에 있기 때문이다.

```text
리프 근처: 노드 수 많음, 내려갈 거리 짧음
루트 근처: 노드 수 적음, 내려갈 거리 김
```

각 노드의 높이를 모두 더하면 \(n\)에 비례한다. 그래서 heap을 만드는 단계는 \(O(n)\)이고, 이후 최댓값을 \(n\)번 제거하는 단계가 \(O(n\log n)\)이다.

## Properties

| 항목 | 힙 정렬 |
|---|---|
| 시간 | 항상 \(O(n\log n)\) |
| 추가 공간 | \(O(1)\) in-place 가능 |
| 안정성 | 일반 구현은 stable하지 않음 |
| 장점 | 최악 시간 보장, 추가 배열 불필요 |
| 단점 | 실제 캐시 효율은 quick sort보다 낮을 수 있음 |

힙 정렬은 quick sort의 최악 \(O(n^2)\)이 부담스럽고, merge sort의 \(O(n)\) 추가 메모리도 부담스러운 상황에서 의미가 있다. 다만 안정 정렬이 필요하면 일반적인 heap sort는 적절하지 않을 수 있다.

## Implementation Checklist

1. 배열을 Max Heap으로 만든다.
2. `end`를 배열 마지막 인덱스로 둔다.
3. `swap(0, end)`로 최댓값을 오른쪽 끝으로 보낸다.
4. heap size를 줄인다.
5. 루트에서 `siftDown`한다.
6. `end`가 0이 될 때까지 반복한다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS17_heap_sort.pdf" | relative_url }}" target="_blank" rel="noopener">LS17_heap_sort.pdf</a></li>
</ul>
