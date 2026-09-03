---
layout: default
date: 2026-05-19 12:11:10 +0900
last_modified_at: 2026-09-03 19:42:12 +0900
title: "LS15 Quick Sort"
course: "Data Structures"
topic: "Quick Sort"
order: 15
major_topic: "Data Structures & Algorithms"
keywords:
  - "Quick Sort"
  - "Partitioning"
  - "Pivot Selection"
  - "Divide and Conquer"
  - "In-Place Sorting"
---

# LS15 Quick Sort

Source PDF: `LS15_quick_sort_R1.pdf`

> **핵심:** **partition의 반환값은** 피벗의 최종 위치. **Lomuto 방식의 피벗은** 강의 기준 배열의 마지막 원소 `A[r]`.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 퀵 정렬 전략 | 피벗을 기준으로 어떻게 문제를 나누는가? |
| 2 | Partition | 피벗보다 작은 영역과 큰 영역을 어떻게 만든다? |
| 3 | 재귀 호출 | 피벗 위치가 확정된 뒤 어디를 다시 정렬하는가? |
| 4 | 복잡도 | 평균은 왜 빠르고 최악은 왜 느려질 수 있는가? |
| 5 | 병합 정렬 비교 | 시간, 공간, 캐시 관점에서 어떤 차이가 있는가? |

## 1. 퀵 정렬의 핵심 전략

퀵 정렬은 분할 정복 알고리즘이다. 병합 정렬과 달리 병합 단계가 거의 없다.

1. 피벗 pivot을 하나 고른다.
2. 피벗보다 작거나 같은 값은 왼쪽, 큰 값은 오른쪽에 오도록 재배치한다.
3. 피벗은 최종 위치에 놓인다.
4. 왼쪽 부분 배열과 오른쪽 부분 배열을 재귀적으로 정렬한다.

```text
QuickSort(A, p, r):
    if p < r:
        q = Partition(A, p, r)
        QuickSort(A, p, q - 1)
        QuickSort(A, q + 1, r)
```

`q`는 피벗이 최종적으로 자리 잡은 인덱스다.

## 2. Lomuto Partition

강의에서는 배열의 마지막 원소 `A[r]`을 피벗으로 사용하는 Lomuto partition 방식을 다룬다.

```text
Partition(A, p, r):
    x = A[r]
    i = p - 1
    for j = p to r - 1:
        if A[j] <= x:
            i = i + 1
            swap(A[i], A[j])
    swap(A[i + 1], A[r])
    return i + 1
```

## 3. Partition 불변식

반복문이 진행되는 동안 인덱스 `i`와 `j`는 다음 의미를 가진다.

| 구간 | 의미 |
|---|---|
| `A[p ... i]` | 피벗 이하인 값들 |
| `A[i+1 ... j-1]` | 피벗보다 큰 값들 |
| `A[j ... r-1]` | 아직 검사하지 않은 값들 |
| `A[r]` | 피벗 |

`A[j] <= pivot`이면 `i`를 한 칸 늘리고 `A[i]`와 `A[j]`를 바꾼다. 반복이 끝나면 `A[i+1]`과 피벗을 바꿔 피벗을 경계 위치에 둔다.

## 4. 퀵 정렬 예제 해석

초기 배열:

```text
31 8 48 23 7 11 20 29 65 15
```

마지막 원소 `15`를 피벗으로 잡으면, partition 후 `15` 왼쪽에는 `15` 이하 값들이, 오른쪽에는 더 큰 값들이 놓인다.

```text
8 7 11 15 31 48 20 29 65 23
```

이제 `15`의 위치는 확정이다. 이후 왼쪽 부분 `[8, 7, 11]`과 오른쪽 부분 `[31, 48, 20, 29, 65, 23]`만 재귀적으로 정렬하면 된다.

## 5. 시간 복잡도

| 경우 | 설명 | 시간 |
|---|---|---|
| 평균 | 피벗이 배열을 비교적 균형 있게 나눔 | $$O(n\log n)$$ |
| 최악 | 피벗이 매번 최소 또는 최대값 | $$O(n^2)$$ |

피벗이 매번 한쪽 끝 값이 되면 재귀 깊이가 `n`에 가까워진다. 특히 이미 정렬된 배열에서 마지막 원소를 피벗으로 고르면 최악에 가까워질 수 있다.

## 6. 공간 복잡도

퀵 정렬은 배열 안에서 swap하며 정렬하는 in-place 방식이다. 추가 배열이 필요하지 않다.

다만 재귀 호출 스택은 필요하다.

| 경우 | 재귀 깊이 | 공간 |
|---|---|---|
| 평균 | $$O(\log n)$$ | $$O(\log n)$$ |
| 최악 | $$O(n)$$ | $$O(n)$$ |

강의 비교표에서는 평균적인 공간 장점을 $$O(\log n)$$으로 강조한다.

## 7. Quick Sort vs Merge Sort

| 항목 | Quick Sort | Merge Sort |
|---|---|---|
| 평균 시간 | $$O(n\log n)$$ | $$O(n\log n)$$ |
| 최악 시간 | $$O(n^2)$$ | $$O(n\log n)$$ |
| 추가 공간 | 평균 $$O(\log n)$$ | $$O(n)$$ |
| 방식 | in-place partition | 보조 배열로 merge |
| 캐시 효율 | 연속 접근이 많아 유리 | 두 배열을 오가므로 상대적으로 불리 |

퀵 정렬은 평균적으로 빠르고 메모리를 적게 쓰지만, 피벗 선택이 나쁘면 최악 성능이 크다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| partition의 반환값은? | 피벗의 최종 위치 |
| Lomuto 방식의 피벗은? | 강의 기준 배열의 마지막 원소 `A[r]` |
| 퀵 정렬에서 merge 단계가 필요 없는 이유는? | partition 후 피벗 기준으로 양쪽이 이미 분리되어 있기 때문 |
| 최악 $$O(n^2)$$이 되는 경우는? | 피벗이 매번 최소/최대가 되어 한쪽 부분 배열만 커지는 경우 |

## Study Guide

Lomuto partition에서 pivot=A[r], 경계 i, scan index j를 표에 적고 한 단계마다 배열과 두 index를 갱신한다. partition 반환값은 pivot의 최종 위치일 뿐 양쪽 부분 배열까지 정렬된 것은 아니라는 점이 대표 혼동 지점이다. 균형 분할의 O(n log n)과 편향 분할의 O(n²)을 recursion shape로 비교하고 Merge Sort의 메모리·최악 보장과 대비한다.

## 복습 질문

<details markdown="block">
<summary>1. `i`와 `j`가 partition에서 각각 무엇을 추적하는가?</summary>

답변: Lomuto partition에서 `i`는 피벗 이하 값들이 모인 구간의 마지막 위치를 추적하고, `j`는 현재 검사 중인 원소의 위치를 추적한다.

</details>

<details markdown="block">
<summary>2. 피벗보다 작은 값이 발견되면 왜 `i`를 증가시키고 swap하는가?</summary>

답변: 그 값을 피벗보다 작거나 같은 왼쪽 구간에 포함해야 하기 때문이다. `i`를 증가시켜 왼쪽 구간을 한 칸 넓히고, 현재 값 `A[j]`를 그 위치로 보내면 partition 불변식이 유지된다.

</details>

<details markdown="block">
<summary>3. 병합 정렬보다 퀵 정렬이 메모리 측면에서 유리한 이유는 무엇인가?</summary>

답변: 퀵 정렬은 배열 내부에서 swap하며 partition을 수행하므로 큰 보조 배열이 필요하지 않다. 평균적으로 재귀 호출 스택 정도만 필요해 $$O(\log n)$$ 추가 공간으로 볼 수 있다. 반면 병합 정렬은 merge를 위한 $$O(n)$$ 보조 공간이 필요하다.

</details>

## Study Notes

퀵 정렬도 분할 정복이지만 병합 정렬과 결이 다르다. 병합 정렬은 먼저 반으로 나누고 나중에 정렬된 결과를 병합한다. 퀵 정렬은 partition 단계에서 피벗을 기준으로 작은 값과 큰 값을 나누기 때문에, 재귀 호출이 끝난 뒤 별도의 merge가 필요 없다.

Lomuto partition에서는 마지막 원소를 피벗으로 잡는다.

```text
A = [31, 8, 48, 23, 7, 11, 20, 29, 65, 15]
pivot = 15
```

반복 중 `i`는 피벗 이하 구간의 마지막 위치를 가리키고, `j`는 아직 검사 중인 위치를 가리킨다.

$$
A[p \ldots i] \le \mathrm{pivot}
$$

$$
A[i+1 \ldots j-1] > \mathrm{pivot}
$$

$$
A[j \ldots r-1] = \mathrm{unknown},\qquad A[r]=\mathrm{pivot}
$$

`A[j] <= pivot`이면 그 값은 왼쪽 구간으로 가야 한다. 그래서 `i`를 하나 늘리고 `A[i]`와 `A[j]`를 바꾼다. 반복이 끝나면 `i + 1` 위치가 피벗이 들어갈 자리다.

## Complexity by Partition Quality

퀵 정렬의 시간은 partition이 얼마나 균형 있게 나뉘는지에 좌우된다.

| 경우 | 분할 형태 | 시간 |
|---|---|---|
| 좋은 경우 | 절반 가까이 나뉨 | $$O(n\log n)$$ |
| 평균적인 경우 | 대체로 적당히 나뉨 | $$O(n\log n)$$ |
| 나쁜 경우 | 한쪽이 거의 비고 한쪽이 `n-1` | $$O(n^2)$$ |

이미 정렬된 배열에서 마지막 원소를 항상 피벗으로 고르면 피벗이 매번 최댓값이 될 수 있다. 그러면 한쪽 부분 배열만 계속 커져 재귀 깊이가 `n`이 된다.

## Quick Sort vs Merge Sort

| 기준 | Quick Sort | Merge Sort |
|---|---|---|
| 평균 시간 | 빠른 편, $$O(n\log n)$$ | $$O(n\log n)$$ |
| 최악 시간 | $$O(n^2)$$ 가능 | $$O(n\log n)$$ 보장 |
| 추가 공간 | 평균 재귀 스택 $$O(\log n)$$ | 보조 배열 $$O(n)$$ |
| 안정성 | 일반 구현은 안정적이지 않음 | 안정 정렬로 구현 가능 |
| 실제 성능 | 캐시 효율이 좋아 빠른 경우 많음 | 안정적이지만 메모리 사용 큼 |

퀵 정렬은 피벗 선택 전략이 중요하다. random pivot이나 median-of-three 같은 방법은 최악 상황을 줄이기 위한 실용적 개선이다.

## Partition 정확성과 점화식

> **분류:** 앞부분은 Lomuto partition의 **루프 불변식 증명**, 뒷부분은 분할 품질에 따른 **점화식 해석**이다. 비교 가능한 원소와 마지막 원소 피벗을 가정한다.

> **원문 추적:** `LS15_quick_sort_R1.pdf` pp.12–68은 partition 코드와 단계별 실행을, pp.69–70은 평균 $$O(n\log n)$$·최악 $$O(n^2)$$ 및 재귀 깊이를 제시한다. 루프 불변식과 두 점화식의 전개는 작성자 보충이다.

반복 시작마다 다음 불변식을 둔다.

$$
A[p\ldots i]\le q,
\quad A[i+1\ldots j-1]>q,
\quad A[j\ldots r-1]\text{는 미검사},
$$

여기서 $$q=A[r]$$은 피벗이다. 처음에는 $$i=p-1,j=p$$라 두 확정 구간이 비어 있어 참이다. `A[j] <= q`이면 `i`를 늘린 뒤 swap하여 왼쪽 구간에 포함시키고, 크면 `j`만 전진시켜 오른쪽 구간에 포함시킨다. 따라서 매 반복 뒤에도 불변식이 유지된다. 종료 시 미검사 구간이 비고, 피벗을 $$i+1$$과 교환하면 왼쪽은 피벗 이하, 오른쪽은 피벗 초과이므로 피벗 위치가 확정된다.

Partition 자체는 $$n-1$$개를 한 번씩 검사해 $$\Theta(n)$$이다. 균형 분할이면

$$
T(n)=2T(n/2)+cn=\Theta(n\log n).
$$

피벗이 계속 최솟값 또는 최댓값이면

$$
T(n)=T(n-1)+cn
=c\sum_{k=2}^{n}k+T(1)
=\Theta(n^2).
$$

“평균 $$O(n\log n)$$”은 무작위 피벗이나 입력 순서에 대한 확률 가정이 있는 기대값이다. 고정된 마지막 원소 피벗과 정렬·역정렬 입력에는 그 기대 보장을 그대로 적용할 수 없다. 모든 동일 key를 한쪽으로 보내는 2-way partition은 중복값이 많은 입력에서 불균형해질 수 있어 3-way partition이 더 적합할 수 있다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS15_quick_sort_R1.pdf" | relative_url }}" target="_blank" rel="noopener">LS15_quick_sort_R1.pdf</a></li>
</ul>
