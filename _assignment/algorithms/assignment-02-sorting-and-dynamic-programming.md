---
layout: default
date: 2026-10-13 17:04:00 +0900
title: "Algorithms Assignment 2: Sorting Traces and Dynamic Programming"
course: "Algorithms"
topic: "Sorting Traces and Dynamic Programming"
order: 2
major_topic: "Algorithms"
keywords: [insertion-sort, bubble-sort, quick-sort, merge-sort, dynamic-programming, unbounded-knapsack]
---

# Algorithms Assignment 2: Sorting Traces and Dynamic Programming

Source Materials: JUNGOL Problems 1158, 1157, 3518, 3519, 1848, and 1077 with the provided algorithm implementations

## 과제 개요

**네 정렬의 중간 배열을 읽고, 두 동적 계획법의 상태와 점화식을 직접 세우는 연습이다.** 정렬 문제는 최종 결과만 맞히는 것이 아니라 어느 인덱스와 구간이 확정됐는지 추적해야 한다. 동적 계획법 문제는 코드보다 먼저 상태가 답에 필요한 정보를 충분히 담는지 확인해야 한다.

- Insertion Sort는 정렬된 접두부에 현재 값을 삽입한다.
- Bubble Sort는 한 pass가 끝날 때 미정렬 구간의 최댓값 하나를 오른쪽에 확정한다.
- Quick Sort는 partition 직후 pivot 하나만 확정된다. 양쪽 구간 내부는 아직 정렬되지 않았다.
- Merge Sort는 이미 정렬된 두 구간을 합쳐 더 큰 정렬 구간 하나를 확정한다.
- Theater Seating은 VIP 좌석이 분리한 독립 구간의 경우의 수를 곱한다.
- Knapsack Filling 1은 같은 보석을 다시 선택할 수 있는 unbounded knapsack이다.

## References and Source Materials

문제 출처는 JUNGOL의 <a href="https://jungol.co.kr/problem/1158" target="_blank" rel="noopener">1158 Insertion Sort</a>, <a href="https://jungol.co.kr/problem/1157" target="_blank" rel="noopener">1157 Bubble Sort</a>, <a href="https://jungol.co.kr/problem/3518" target="_blank" rel="noopener">3518 Quick Sort</a>, <a href="https://jungol.co.kr/problem/3519" target="_blank" rel="noopener">3519 Merge Sort</a>, <a href="https://jungol.co.kr/problem/1848" target="_blank" rel="noopener">1848 Theater Seating</a>, <a href="https://jungol.co.kr/problem/1077" target="_blank" rel="noopener">1077 Knapsack Filling 1</a>이다.

입출력 추적은 제공된 과제 구현을 기준으로 한다. 문제별 제약 조건은 각 원문 링크를 참조한다.

## 1. Insertion Sort: Grow a Sorted Prefix

### Input and output

- 입력: 길이 $$n$$과 원소 $$a_0,\dots,a_{n-1}$$.
- 출력: $$i=1$$부터 $$n-1$$까지 각 삽입이 끝난 배열 한 줄.
- 중간 상태의 의미: 출력 직후 $$a[0:i+1]$$은 정렬되어 있고, 뒤쪽은 아직 처리하지 않은 입력이다.

### How one pass changes the array

`current = a[i]`를 먼저 보관한다. 왼쪽의 값이 `current`보다 큰 동안 한 칸씩 오른쪽으로 밀고, 생긴 빈자리에 `current`를 넣는다.

예를 들어 `[7, 3, 5, 2]`는 다음처럼 변한다.

| $$i$$ | 삽입할 값 | 이동한 값 | 삽입 위치 | pass 뒤 배열 | 확정된 구간 |
|---:|---:|---|---:|---|---|
| 1 | 3 | 7 | 0 | `[3, 7, 5, 2]` | `[0, 2)` |
| 2 | 5 | 7 | 1 | `[3, 5, 7, 2]` | `[0, 3)` |
| 3 | 2 | 7, 5, 3 | 0 | `[2, 3, 5, 7]` | `[0, 4)` |

`a[j] > current`일 때만 이동하므로 같은 값은 서로를 추월하지 않는다. 따라서 이 구현은 stable하다.

### Correctness and complexity

반복을 시작할 때 $$a[0:i]$$가 정렬되어 있다고 가정한다. 그보다 큰 값만 오른쪽으로 옮기면 빈자리의 왼쪽 값은 `current` 이하, 오른쪽 값은 `current` 초과가 된다. 따라서 삽입 뒤 $$a[0:i+1]$$도 정렬된다. 길이 1인 첫 접두부가 기저 조건이므로 모든 pass 뒤 전체 배열이 정렬된다.

- 이미 정렬된 입력: 비교가 pass마다 한 번씩 끝나므로 $$\Theta(n)$$.
- 역순 입력: 이동 횟수는 $$1+2+\cdots+(n-1)=n(n-1)/2$$이므로 $$\Theta(n^2)$$.
- 추가 공간: $$\Theta(1)$$.

<details markdown="block">
<summary markdown="span">Code Walkthrough: insertion trace</summary>

```python
import sys
data = list(map(int, sys.stdin.buffer.read().split()))
n, a = data[0], data[1:]
for i in range(1, n):
    current = a[i]
    j = i - 1
    while j >= 0 and a[j] > current:
        a[j + 1] = a[j]
        j -= 1
    a[j + 1] = current
    print(*a)
```

- `i`는 이번에 접두부로 편입할 원소의 인덱스다.
- `j`는 정렬된 접두부를 오른쪽에서 왼쪽으로 검사한다.
- 출력은 삽입이 끝난 뒤 한 번만 수행한다.

</details>

## 2. Bubble Sort: Fix One Right Boundary per Pass

### Input and output

- 입력: 길이 $$n$$과 배열.
- 출력: 바깥 pass가 끝날 때마다 배열 한 줄, 모두 $$n-1$$줄.
- 경계: `end` 이후의 suffix는 이미 최종 위치가 확정되어 다음 pass에서 비교하지 않는다.

예를 들어 `[5, 1, 4, 2]`의 첫 pass는 인접 비교 세 번을 수행한다.

| 비교 인덱스 | 비교 전 | 교환 | 비교 뒤 |
|---|---|---|---|
| 0, 1 | `[5, 1, 4, 2]` | 5와 1 | `[1, 5, 4, 2]` |
| 1, 2 | `[1, 5, 4, 2]` | 5와 4 | `[1, 4, 5, 2]` |
| 2, 3 | `[1, 4, 5, 2]` | 5와 2 | `[1, 4, 2, 5]` |

첫 pass가 끝나면 최댓값 5가 인덱스 3에 확정된다. 두 번째 pass는 `[0, 3)`만 비교해 `[1, 2, 4, 5]`, 세 번째 pass는 `[0, 2)`를 비교해 같은 배열을 출력한다.

### Correctness and complexity

한 pass에서 더 큰 값은 인접 교환을 거듭해 오른쪽으로 이동한다. 그러므로 비교 구간의 최댓값이 pass 끝에서 `end` 위치에 놓인다. 매 pass마다 확정 suffix가 한 칸씩 늘어나므로 마지막에는 전체 배열이 정렬된다.

이 구현은 조기 종료 검사를 하지 않아 입력 상태와 무관하게 비교 횟수가

$$
(n-1)+(n-2)+\cdots+1=\frac{n(n-1)}{2}
$$

이다. 시간은 최선·평균·최악 모두 $$\Theta(n^2)$$, 추가 공간은 $$\Theta(1)$$이다. `>`일 때만 교환하므로 stable하다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: bubble-sort pass trace</summary>

```python
import sys
data = list(map(int, sys.stdin.buffer.read().split()))
n, a = data[0], data[1:]
for end in range(n - 1, 0, -1):
    for i in range(end):
        if a[i] > a[i + 1]:
            a[i], a[i + 1] = a[i + 1], a[i]
    print(*a)
```

- 안쪽 반복의 유효 비교 인덱스는 `0 <= i < end`다.
- 한 pass가 끝난 뒤 `a[end]`가 새로 확정된다.
- 이미 정렬됐어도 문제의 trace 형식에 맞춰 각 pass를 출력한다.

</details>

## 3. Quick Sort: Partition, Print, Recurse

### Input and output

- 입력: 길이 $$n$$과 배열.
- 출력: partition 한 번이 끝날 때마다 현재 전체 배열 한 줄.
- 구간: 재귀 호출은 양끝을 모두 포함하는 $$[low,high]$$를 처리한다.
- pivot: 각 구간의 첫 값 `a[low]`.

### Partition state

포인터 `i`는 왼쪽에서 pivot보다 큰 값을, `j`는 오른쪽에서 pivot보다 작은 값을 찾는다. 둘을 바꾸며 진행하다 포인터가 교차하면 pivot과 `a[j]`를 바꾼다.

종료 직후 구간은 다음 조건을 만족한다.

| 구간 | 상태 |
|---|---|
| `[low, j)` | pivot 이하 |
| `j` | pivot의 확정 위치 |
| `(j, high]` | pivot 이상 |

같은 값은 어느 쪽에도 있을 수 있다. 중요한 사실은 **pivot 하나의 위치만 확정**된다는 것이다. 두 하위 구간 내부까지 정렬됐다고 해석하면 안 된다.

예를 들어 `[4, 7, 2, 6, 1]`에서 pivot은 4다. 7과 1, 이어 7과 2의 위치가 조정되고 pivot을 경계 위치로 옮기면 `[1, 2, 4, 6, 7]`이 된다. 이 예시는 우연히 양쪽도 정렬되지만 일반적으로는 그렇지 않다. `[4, 8, 2, 7, 1, 6]`처럼 더 긴 배열에서는 첫 partition 뒤 양쪽 내부 정렬이 남는다.

### Correctness and complexity

partition이 pivot보다 작은 쪽과 큰 쪽을 분리하고 pivot을 최종 위치에 둔다. 두 하위 구간이 재귀적으로 정렬된다고 가정하면 전체 구간도 정렬된다.

- 균형 분할: $$T(n)=2T(n/2)+\Theta(n)=\Theta(n\log n)$$.
- 한쪽 길이가 계속 0과 $$n-1$$: $$T(n)=T(n-1)+\Theta(n)=\Theta(n^2)$$.
- 재귀 stack: 평균 $$\Theta(\log n)$$, 최악 $$\Theta(n)$$.
- swap 때문에 stable하지 않다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: first-pivot Quick Sort trace</summary>

```python
import sys
sys.setrecursionlimit(10000)
data = list(map(int, sys.stdin.buffer.read().split()))
n, a = data[0], data[1:]
def quick_sort(low, high):
    if low >= high:
        return
    pivot = a[low]
    i, j = low + 1, high
    while i <= j:
        while i <= j and a[i] <= pivot:
            i += 1
        while i <= j and a[j] >= pivot:
            j -= 1
        if i < j:
            a[i], a[j] = a[j], a[i]
    a[low], a[j] = a[j], a[low]
    print(*a)
    quick_sort(low, j - 1)
    quick_sort(j + 1, high)
quick_sort(0, n - 1)
```

- `i <= j` 검사가 배열 경계 밖 접근을 막는다.
- 출력 시점은 pivot 교환 직후이자 재귀 호출 직전이다.
- 동일 키의 상대 순서는 보존하지 않는다.

</details>

## 4. Merge Sort: Print after Every Merge

### Input and output

- 입력: 길이 $$n$$과 배열.
- 출력: 두 하위 구간을 합칠 때마다 현재 전체 배열 한 줄.
- 구간: 양끝 포함 $$[low,high]$$, 중간점은 `mid = (low + high) // 2`.

### Merge state

재귀 호출이 끝났다면 `[low, mid]`와 `[mid + 1, high]`는 각각 정렬되어 있다. 두 포인터가 가리키는 첫 미사용 값 가운데 더 작은 값을 임시 배열에 넣으면 다음 출력 위치의 최솟값이 확정된다.

`[4, 3, 2, 1]`의 merge 순서는 다음과 같다.

| 합치는 구간 | 왼쪽 / 오른쪽 | merge 뒤 배열 |
|---|---|---|
| `[0, 1]` | `[4]` / `[3]` | `[3, 4, 2, 1]` |
| `[2, 3]` | `[2]` / `[1]` | `[3, 4, 1, 2]` |
| `[0, 3]` | `[3, 4]` / `[1, 2]` | `[1, 2, 3, 4]` |

출력 행의 수는 재귀 구조에서 실제 merge가 일어난 횟수다. 빈 구간이나 길이 1 구간은 출력하지 않는다.

### Correctness and complexity

병합 중 `temp[low:k]`가 양쪽 구간에서 이미 소비한 값들의 정렬된 결과라는 불변식을 유지한다. 한쪽이 끝나면 다른 쪽의 남은 값은 이미 정렬되어 있으므로 그대로 복사한다. 길이 1 구간이 기저 조건이고, 두 정렬 구간의 merge가 정렬을 보존하므로 귀납적으로 전체가 정렬된다.

각 재귀 깊이에서 모든 구간 길이의 합은 $$n$$이고 깊이는 $$\Theta(\log n)$$이므로 시간은 모든 입력에서 $$\Theta(n\log n)$$이다. 임시 배열은 $$\Theta(n)$$, 재귀 stack은 $$\Theta(\log n)$$이다. 동점에서 왼쪽을 먼저 고르므로 stable하다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: inclusive-range Merge Sort trace</summary>

```python
import sys
data = list(map(int, sys.stdin.buffer.read().split()))
n, a = data[0], data[1:]
temp = [0] * n
def merge_sort(low, high):
    if low >= high:
        return
    mid = (low + high) // 2
    merge_sort(low, mid)
    merge_sort(mid + 1, high)
    i, j = low, mid + 1
    for k in range(low, high + 1):
        if j > high or (i <= mid and a[i] <= a[j]):
            temp[k] = a[i]
            i += 1
        else:
            temp[k] = a[j]
            j += 1
    a[low:high + 1] = temp[low:high + 1]
    print(*a)
merge_sort(0, n - 1)
```

- `temp`와 `a`는 모두 길이 `n`이다.
- `i <= mid`, `j <= high`가 두 하위 구간의 읽기 경계다.
- merge가 끝난 구간만 `a`에 복사한 뒤 전체 배열 상태를 출력한다.

</details>

## 5. Theater Seating: Split at Fixed Seats

### State definition

VIP 좌석은 고정되어 움직일 수 없다. VIP 사이의 일반 좌석은 서로 독립인 연속 구간을 만든다. 길이 $$k$$인 일반 구간의 가능한 배치를 $$W(k)$$라고 정의한다.

### Deriving the recurrence

구간의 첫 사람을 기준으로 경우를 나눈다.

1. 자기 좌석에 앉으면 나머지는 길이 $$k-1$$의 문제다.
2. 바로 옆 사람과 서로 자리를 바꾸면 두 좌석이 함께 결정되고 나머지는 길이 $$k-2$$의 문제다.

두 경우는 겹치지 않고 모든 허용 배치를 포함하므로

$$
W(k)=W(k-1)+W(k-2),\qquad W(0)=1,\quad W(1)=1.
$$

빈 구간의 경우의 수를 1로 두어야 VIP 좌석이 연속하거나 첫·마지막 좌석이 VIP여도 전체 곱을 바꾸지 않는다.

### Combining independent blocks

예를 들어 좌석이 9개이고 VIP가 4, 7이라면 일반 구간 길이는 3, 2, 2다. 서로 다른 구간의 선택은 VIP를 넘어 영향을 주지 않으므로 곱셈 원리에 따라

$$
W(3)W(2)W(2)=3\cdot2\cdot2=12.
$$

`ways[0]`부터 `ways[n]`까지 한 번 계산하고 VIP 목록을 한 번 훑으므로 시간은 $$\Theta(n+m)$$, 공간은 $$\Theta(n)$$이다. $$m$$은 VIP 수다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: block lengths and Fibonacci counts</summary>

```python
import sys
data = list(map(int, sys.stdin.buffer.read().split()))
n, m = data[0], data[1]
vip_seats = data[2:2 + m]
ways = [0] * (n + 1)
ways[0] = 1
if n >= 1:
    ways[1] = 1
for length in range(2, n + 1):
    ways[length] = ways[length - 1] + ways[length - 2]
answer = 1
previous = 0
for vip in vip_seats:
    answer *= ways[vip - previous - 1]
    previous = vip
answer *= ways[n - previous]
print(answer)
```

- `previous`는 직전 VIP 좌석 번호이며 좌석 번호는 1부터 시작한다.
- `vip - previous - 1`이 두 VIP 사이의 일반 좌석 수다.
- 마지막 VIP 뒤 구간까지 곱해야 전체 좌석을 포함한다.

</details>

## 6. Knapsack Filling 1: Reuse Is Allowed

### State definition

보석 종류마다 무게 $$w_i$$와 가치 $$v_i$$가 있고, 같은 종류를 여러 번 사용할 수 있다고 본다. 정확한 제한 용량을 $$c$$라고 할 때 얻을 수 있는 최대 가치를

$$
dp[c]=\text{capacity가 }c\text{일 때 얻을 수 있는 최대 가치}
$$

로 정의한다. 남는 용량을 허용하므로 `capacity at most c`라는 의미다.

### Deriving the recurrence

최적 선택의 마지막 보석이 종류 $$i$$라고 가정한다. 그 보석의 무게 $$w_i$$를 빼기 전에는 용량 $$c-w_i$$에서 최적인 구성을 사용해야 한다. 그렇지 않으면 앞부분을 더 좋은 구성으로 바꿔 전체 가치도 키울 수 있어 원래 선택이 최적이라는 가정과 모순된다.

따라서

$$
dp[c]=\max\left(dp[c],\ dp[c-w_i]+v_i\right)
\quad\text{for every }i\text{ with }w_i\le c,
$$

이며 $$dp[0]=0$$이다. 오른쪽이 더 작은 용량만 참조하므로 $$c=1,2,\dots,C$$ 순서로 계산한다. 같은 `dp` 배열을 다시 참조하기 때문에 같은 종류를 여러 번 사용할 수 있다.

### Small verification

보석이 $$(w,v)=(2,3),(3,4)$$이고 용량이 7이라고 하자.

| $$c$$ | 가능한 마지막 선택 | $$dp[c]$$ |
|---:|---|---:|
| 0 | 없음 | 0 |
| 1 | 없음 | 0 |
| 2 | $$(2,3)$$ | 3 |
| 3 | $$(2,3)$$ 또는 $$(3,4)$$ | 4 |
| 4 | $$dp[2]+3$$ | 6 |
| 5 | $$dp[3]+3$$ 또는 $$dp[2]+4$$ | 7 |
| 6 | $$dp[4]+3$$ 또는 $$dp[3]+4$$ | 9 |
| 7 | $$dp[5]+3$$ 또는 $$dp[4]+4$$ | 10 |

용량 7의 10은 무게 2 보석 두 개와 무게 3 보석 한 개로 얻는다. 종류 수를 $$n$$, 용량을 $$C$$라 하면 시간은 $$\Theta(nC)$$, 공간은 $$\Theta(C)$$이다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: capacity-first unbounded knapsack</summary>

```python
import sys
data = list(map(int, sys.stdin.buffer.read().split()))
n, capacity = data[0], data[1]
gems = [(data[i], data[i + 1]) for i in range(2, 2 + 2 * n, 2)]
best = [0] * (capacity + 1)
for current in range(1, capacity + 1):
    for weight, value in gems:
        if weight <= current:
            best[current] = max(
                best[current],
                best[current - weight] + value,
            )
print(best[capacity])
```

- `best`의 shape는 `(capacity + 1,)`이다.
- `current`가 증가하므로 `best[current - weight]`는 이미 계산되어 있다.
- 보석을 사용했는지 표시하지 않아 같은 종류를 다시 고를 수 있다.

</details>

## Sorting Trace Comparison

| Algorithm | 출력 시점 | 새로 확정되는 것 | 핵심 경계 | Time | Extra space | Stable |
|---|---|---|---|---|---|---|
| Insertion Sort | 원소 하나를 삽입한 뒤 | 정렬된 prefix | `[0, i + 1)` | best $$\Theta(n)$$, worst $$\Theta(n^2)$$ | $$\Theta(1)$$ | Yes |
| Bubble Sort | 인접 비교 pass 뒤 | 오른쪽 원소 하나 | `[0, end]` 비교 | $$\Theta(n^2)$$ | $$\Theta(1)$$ | Yes |
| Quick Sort | partition 뒤 | pivot 한 개 | `[low, high]` | average $$\Theta(n\log n)$$, worst $$\Theta(n^2)$$ | stack dependent | No |
| Merge Sort | merge 뒤 | 합친 정렬 구간 | `[low, high]` | $$\Theta(n\log n)$$ | $$\Theta(n)$$ | Yes |

## 마지막 핵심 정리

- 정렬 trace를 읽을 때는 출력 시점, 이번 단계에서 확정된 구간, 다음 단계의 유효 인덱스를 함께 표시한다.
- Insertion·Bubble Sort는 각각 정렬 prefix와 확정 suffix를 늘리고, Quick Sort는 pivot 하나, Merge Sort는 합친 구간 하나를 확정한다.
- 복잡도는 결론만 외우지 않고 비교·이동의 합 또는 분할 재귀식과 입력 조건을 함께 확인한다.
- DP는 상태 의미를 먼저 고정하고 마지막 선택으로 점화식을 만든 뒤 기저값, 계산 순서, 작은 입력 검산까지 연결한다.

## Review Checklist

- 정렬 trace에서 출력 직전 어떤 구간이나 인덱스가 확정됐는가?
- inclusive range와 half-open range를 섞지 않았는가?
- pivot partition 뒤 양쪽 내부까지 정렬됐다고 잘못 해석하지 않았는가?
- 정렬의 시간복잡도 결론과 그 합·재귀식의 근거를 함께 설명할 수 있는가?
- DP 상태가 답에 필요한 정보를 충분히 보존하는가?
- 점화식을 마지막 선택으로 나누어 도출했는가?
- 기저값, 계산 순서, 최종 답의 위치를 모두 확인했는가?
- 작은 입력을 손으로 계산해 코드와 같은 값을 얻는가?

## Related Study Notes

- [Sorting I]({{ '/study/algorithms/lecture-04-sorting-01/' | relative_url }})
- [Merge Sort and Quick Sort]({{ '/study/algorithms/lecture-05-sorting-02/' | relative_url }})
- [Dynamic Programming I]({{ '/study/algorithms/lecture-09-dynamic-programming-01/' | relative_url }})
- [Dynamic Programming II]({{ '/study/algorithms/lecture-10-dynamic-programming-02/' | relative_url }})

## Source

<a href="https://jungol.co.kr/problem/1158" target="_blank" rel="noopener">JUNGOL 1158</a> · <a href="https://jungol.co.kr/problem/1157" target="_blank" rel="noopener">JUNGOL 1157</a> · <a href="https://jungol.co.kr/problem/3518" target="_blank" rel="noopener">JUNGOL 3518</a> · <a href="https://jungol.co.kr/problem/3519" target="_blank" rel="noopener">JUNGOL 3519</a> · <a href="https://jungol.co.kr/problem/1848" target="_blank" rel="noopener">JUNGOL 1848</a> · <a href="https://jungol.co.kr/problem/1077" target="_blank" rel="noopener">JUNGOL 1077</a>
