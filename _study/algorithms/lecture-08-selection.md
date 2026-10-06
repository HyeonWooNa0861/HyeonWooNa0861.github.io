---
layout: default
date: 2026-10-06 12:10:00 +0900
title: "Lecture 8: Selection Algorithms"
course: "Algorithms"
topic: "Order Statistics, Randomized Quickselect, and Median of Medians"
order: 8
major_topic: "Data Structures & Algorithms"
keywords:
  - "Selection Problem"
  - "Order Statistic"
  - "Quickselect"
  - "Randomized Selection"
  - "Median of Medians"
  - "Worst-Case Linear Time"
---

# Lecture 8: Selection Algorithms

Source PDF: [8 Selection.pdf](/assets/pdfs/study/algorithms/lecture-08-selection.pdf)

정렬되지 않은 배열에서 필요한 순위의 값 하나만 찾는 **selection problem**을 다룬다. 강의의 `i`는 0부터 세므로, `i=0`은 최솟값이고 `i=n-1`은 최댓값이다. 전체 정렬에는 $$\Theta(n\log n)$$ 시간이 들지만, Quickselect는 무작위 pivot 아래에서 기대 $$\Theta(n)$$, median of medians는 결정론적으로 최악 $$\Theta(n)$$에 순위 통계량을 찾는다.

> **핵심:** partition 한 번은 pivot을 최종 순위 구간에 놓고, selection은 목표 순위가 있는 한쪽만 계속 처리한다. 무작위 pivot은 기대 시간을 선형으로 만들지만 최악의 이차 시간은 남는다. Median of medians는 pivot 양쪽에서 상수 비율의 원소를 제거하도록 보장해 최악 시간까지 선형으로 낮춘다.

## 전체 흐름

| PDF 쪽 | 내용 | 이 글의 대응 위치 |
|---|---|---|
| 1–5 | 제목, 이전 정렬 강의 복습, 목차 | 도입 및 전체 흐름 |
| 6–9 | Selection problem, 단순 방법, 선형 하한 | Selection Problem |
| 10–13 | Partition을 이용한 Quickselect와 예제 코드 | Quickselect |
| 14–21 | 최선·최악·평균 시간과 기대 시간 유도 | Randomized Complexity |
| 22–24 | 1:9 분할의 선형 점화식과 최악 회피 동기 | Balanced Splits, Source Check |
| 25–28 | Median of medians 절차, 의사코드, 30%–70% 논리 | Median of Medians |
| 29–31 | 결정론적 최악 선형 시간 증명 | Worst-Case Recurrence |
| 32–35 | 요약, 다음 강의 Dynamic Programming, 질문 | 마지막 핵심 정리, Study Guide, 복습 질문 |

## 1. Selection Problem

### 1.1 Rank convention

길이 $$n$$인 배열 `arr`와 정수 $$i$$가 주어졌다고 하자. 입력 조건은 $$0\le i<n$$이고, 반환값은 배열을 오름차순으로 정렬했을 때 인덱스 $$i$$에 놓이는 값이다(7쪽). 즉 순위는 **0-based**이다. 중복값도 각각 한 자리를 차지한다.

$$
\operatorname{select}(A,i)=\operatorname{sorted}(A)[i].
$$

여기서 $$A$$는 길이 $$n$$의 값 배열, $$i$$는 단위가 없는 인덱스, 반환값의 단위는 배열 원소와 같다. 예를 들어

```text
A = [7, 2, 7, 4, 7, 1, 4]
sorted(A) = [1, 2, 4, 4, 7, 7, 7]
```

이면 $$i=3$$의 결과는 `4`다. 두 개의 `4`와 세 개의 `7`을 제거하거나 서로 다른 값으로 취급하지 않는다.

7쪽의 배열 `[46, 35, 92, 83, 74, 21, 58, 67]`을 직접 정렬하면 `[21, 35, 46, 58, 67, 74, 83, 92]`다. 따라서 강의가 선언한 0-based 규약에서 $$i=4$$의 결과는 `67`이다. 슬라이드에 강조된 `58`은 1-based로 네 번째 값이며, 이 불일치는 아래 Source Check에 분리해 기록한다.

### 1.2 Baselines and lower bound

8쪽은 두 단순 방법을 비교한다.

1. 최솟값을 반복해서 제거하면 0-based $$i$$에 대해 $$i+1$$개의 작은 값을 확인해야 한다. 매번 남은 배열을 선형 탐색하는 직접 구현의 상한은 $$O((i+1)n)$$이고, $$i=\Theta(n)$$이면 $$O(n^2)$$이다.
2. 배열 전체를 비교 정렬한 뒤 `arr[i]`를 읽으면 $$\Theta(n\log n)$$ 시간이 든다.

일반적인 비교 기반 selection은 최악의 경우 입력 전체에 관한 정보를 얻어야 한다. 보지 않은 원소의 값을 바꾸어 목표 순위를 바꿀 수 있으므로 $$\Omega(n)$$의 비교·검사 하한이 있다(9쪽). 따라서 선형 시간 selection은 가능한 가장 좋은 점근 차수다.

## 2. Quickselect

### 2.1 Partition gives a final rank

Partition은 현재 구간의 원소를 pivot보다 작은 부분, pivot과 같은 부분, pivot보다 큰 부분으로 나눈다. 서로 다른 키만 있고 pivot 하나를 최종 인덱스 $$p$$에 놓는 2-way partition이라면 다음이 성립한다(11–12쪽).

$$
A[j] < A[p]\quad (j<p),
\qquad
A[j] > A[p]\quad (j>p).
$$

따라서 pivot은 정렬된 배열에서도 인덱스 $$p$$에 있다. 목표 인덱스 $$i$$와 비교해 세 경우만 처리한다.

- $$i=p$$이면 pivot을 반환한다.
- $$i<p$$이면 왼쪽 부분만 처리한다.
- $$i>p$$이면 오른쪽 부분만 처리한다.

Quicksort는 양쪽을 모두 정렬하지만 Quickselect는 목표가 있는 한쪽만 처리한다. 이 차이가 선형 기대 시간을 가능하게 한다.

### 2.2 Duplicate-safe three-way partition

중복값이 있으면 단일 pivot 인덱스보다 **같은 값의 연속 구간**을 추적하는 편이 정확하고 효율적이다. Partition 결과를 다음 세 구간으로 둔다.

$$
A[\ell:m_1] < v,
\qquad
A[m_1:m_2] = v,
\qquad
A[m_2:r] > v.
$$

목표 $$i$$가 $$[m_1,m_2)$$ 안이면 값 $$v$$가 답이다. 이 방식은 모든 원소가 같을 때도 한 번의 partition으로 끝난다. 다음 코드는 설명과 실행 검산을 위한 copy-based 구현이다. 각 partition에서 현재 구간 크기만큼 보조 저장 공간을 사용하며, 제자리 구현이 필요하면 Dutch national flag 방식으로 세 구간을 만들 수 있다.

```python
from random import Random


def quickselect(values, i, seed=0):
    if not 0 <= i < len(values):
        raise IndexError("rank is outside the array")

    a = list(values)
    lo, hi = 0, len(a)  # active range: [lo, hi)
    rng = Random(seed)

    while True:
        if hi - lo == 1:
            return a[lo]

        pivot = a[rng.randrange(lo, hi)]
        lower = [x for x in a[lo:hi] if x < pivot]
        equal = [x for x in a[lo:hi] if x == pivot]
        higher = [x for x in a[lo:hi] if x > pivot]
        a[lo:hi] = lower + equal + higher

        m1 = lo + len(lower)
        m2 = m1 + len(equal)
        if i < m1:
            hi = m1
        elif i < m2:
            return pivot
        else:
            lo = m2
```

13쪽의 입력 `[11, 1, 9, 2, 7, 13, 12, 8, 6, 3, 10]`에 $$i=3$$을 넣으면 정렬 결과가 `[1, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13]`이므로 답은 `6`이다. 위 구현을 독립 실행한 결과도 `6`이었다. 중복 예제 `[7, 2, 7, 4, 7, 1, 4]`, $$i=3$$은 `4`를 반환했다.

## 3. Randomized Quickselect Complexity

### 3.1 Best and worst cases

크기 $$n$$의 구간을 partition하는 비용을 $$c_0n$$ 이하라고 두자. $$c_0$$는 비교·분류·복사 같은 기본 연산의 상수이고, $$n$$의 단위는 원소 수다.

- pivot이 바로 목표 순위이면 partition 한 번으로 끝나므로 $$\Theta(n)$$이다.
- pivot이 매번 한쪽 끝의 순위를 차지하고 목표가 반대쪽에 있으면 처리 크기가 $$n-1,n-2,\ldots,1$$로 줄어든다.

$$
T(n)=T(n-1)+c_0n
=\Theta\!\left(\sum_{m=1}^{n}m\right)
=\Theta(n^2).
$$

마지막 원소를 항상 pivot으로 쓰는 결정론적 구현은 이미 정렬된 입력과 목표 순위의 조합에서 이 최악 경우를 만날 수 있다(14쪽). 무작위 pivot도 **기대** 성능은 선형이지만, 가능한 실행 중 최악 시간 자체는 여전히 $$\Theta(n^2)$$이다.

### 3.2 Expected linear time

15–21쪽의 분석은 먼저 키가 모두 다르다고 두고, 현재 구간에서 pivot의 최종 순위 $$k$$가 $$0,1,\ldots,n-1$$에 균등하게 분포한다고 가정한다. 이는 각 재귀 단계에서 pivot을 현재 구간의 원소 중 균등하고 독립적으로 뽑는 randomized Quickselect에 해당한다. 목표 $$i$$에 따라 실제로는 한쪽만 재귀하지만, 상한을 위해 더 큰 쪽의 비용을 사용하면

$$
\mathbb{E}[T(n)]
\le
\frac{1}{n}\sum_{k=0}^{n-1}
\max\!\left(\mathbb{E}[T(k)],\mathbb{E}[T(n-k-1)]\right)
+c_0n.
$$

대칭인 두 절반을 묶으면

$$
\mathbb{E}[T(n)]
\le
\frac{2}{n}\sum_{k=\lfloor n/2\rfloor}^{n-1}\mathbb{E}[T(k)]
+c_0n.
$$

홀수 $$n$$에서는 가운데 항을 한 번 더 세는 안전한 상한이므로 합의 시작점에 $$\lfloor n/2\rfloor$$를 쓴다. 귀납 가설 $$\mathbb{E}[T(k)]\le ck$$를 대입한다. 합의 항 수와 첫째·마지막 항을 사용하면 주항은 다음과 같다.

$$
\frac{2c}{n}\sum_{k=\lfloor n/2\rfloor}^{n-1}k
\le \frac{3}{4}cn+O(c).
$$

따라서 충분히 큰 $$c$$와 기준 크기 $$n_0$$를 택하면

$$
\mathbb{E}[T(n)]
\le
\left(\frac{3}{4}c+c_0\right)n+O(c)
\le cn.
$$

강의는 예시로 $$c_0=100$$, $$c=800$$, $$n_0\ge12$$를 사용한다(21쪽). 이는 정확한 상수 선택의 한 예일 뿐 알고리즘의 실행 시간 상수가 항상 800이라는 뜻은 아니다. Partition 자체의 $$\Omega(n)$$ 하한과 합치면 randomized Quickselect의 기대 시간은 $$\Theta(n)$$이다.

중복 키가 있으면 같은 값에 원래 위치를 보조 순서로 붙여 서로 다른 가상 순위를 만든 뒤 위 분석과 결합할 수 있다. 실제 3-way partition은 pivot과 같은 값 전체를 한 번에 `equal` 구간으로 확정하므로, 하나씩만 제거하는 이 가상 실행보다 더 큰 재귀 구간을 만들지 않는다. 따라서 중복 안전 구현의 기대 상한도 $$O(n)$$이다.

### 3.3 A fixed fractional split

22쪽의 1:9 예처럼 목표가 매번 큰 부분에 있어도 큰 부분의 크기가 항상 $$9n/10$$ 이하라면

$$
T(n)\le T(9n/10)+c_0n.
$$

이를 전개하면 각 단계의 partition 비용은 기하급수 합이 된다.

$$
T(n)
\le c_0n\sum_{j\ge0}\left(\frac{9}{10}\right)^j
=10c_0n
=\Theta(n).
$$

핵심 조건은 pivot이 정확한 최솟값이나 최댓값이 아니라는 정도가 아니다. 매 단계에서 제거되는 원소 수가 현재 크기의 **고정된 양의 비율**이어야 한다. 예를 들어 pivot이 매번 두 번째로 작은 값이면 극값은 아니지만 크기는 $$n-2$$씩만 줄어 전체 시간이 $$\Theta(n^2)$$가 될 수 있다.

## 4. Median of Medians

### 4.1 Deterministic pivot construction

Median of medians는 입력값이나 난수 운에 관계없이 충분히 중앙에 가까운 pivot을 만든다(25–27쪽).

1. 현재 구간을 최대 5개씩 그룹으로 나눈다.
2. 각 그룹을 정렬해 중앙값을 구한다.
3. 그룹 중앙값들의 중앙값 $$M$$을 같은 selection 알고리즘으로 재귀 선택한다.
4. $$M$$을 pivot으로 3-way partition하고 목표 순위가 있는 한쪽만 처리한다.

다음 구현은 절차와 중복 처리를 분명히 보여 주기 위한 copy-based 버전이다. 마지막 5개 미만 그룹도 포함하고, 작은 입력은 직접 정렬한다.

```python
def median_of_medians_select(values, i):
    if not 0 <= i < len(values):
        raise IndexError("rank is outside the array")

    a = list(values)
    if len(a) <= 5:
        return sorted(a)[i]

    groups = [a[j:j + 5] for j in range(0, len(a), 5)]
    medians = [sorted(group)[len(group) // 2] for group in groups]
    pivot = median_of_medians_select(medians, len(medians) // 2)

    lower = [x for x in a if x < pivot]
    equal = [x for x in a if x == pivot]
    higher = [x for x in a if x > pivot]

    if i < len(lower):
        return median_of_medians_select(lower, i)
    if i < len(lower) + len(equal):
        return pivot
    return median_of_medians_select(
        higher,
        i - len(lower) - len(equal),
    )
```

독립 실행 예제 `[31, 4, 17, 9, 2, 26, 11, 8, 20, 14, 6]`, $$i=5$$는 정렬 배열 `[2, 4, 6, 8, 9, 11, 14, 17, 20, 26, 31]`의 인덱스 5인 `11`을 반환했다. 이 코드는 매 단계 새 리스트를 만들어 보조 공간을 사용한다. Median of medians의 최악 선형 **시간** 보장은 제자리 구현 여부와 별개의 성질이다.

### 4.2 Why the pivot removes a constant fraction

먼저 $$n$$이 5의 배수이고 그룹 수 $$g=n/5$$라고 가정하자(28쪽). 각 완전한 그룹은 정렬했을 때 중앙값보다 작거나 같은 원소가 3개, 크거나 같은 원소가 3개다. 중앙값들의 중앙값을 $$M$$이라 하면 중앙값의 적어도 절반은 $$M$$ 이하이고 적어도 절반은 $$M$$ 이상이다. 그러므로 반올림과 마지막 불완전 그룹을 잠시 제외하면 양쪽에 각각 최소한 다음 수의 원소가 확인된다.

$$
3\cdot\frac{g}{2}
=\frac{3}{2}\cdot\frac{n}{5}
=\frac{3n}{10}.
$$

따라서 $$M$$보다 엄격히 작은 구간과 엄격히 큰 구간 중 어느 쪽도 대략 $$7n/10$$을 넘지 않는다. 중복값이 있으면 `equal` 구간이 커지고, 목표가 그 안에 있으면 즉시 끝난다. 목표가 바깥에 있어도 재귀하는 `lower` 또는 `higher`의 크기는 이 상한을 만족한다. 일반적인 $$n$$에서는 바닥·천장 함수와 불완전 그룹 때문에 상수 개의 오차가 붙지만 점근 차수는 바뀌지 않는다.

이 30%–70% 표현은 서로 다른 값에서 pivot의 단일 최종 인덱스를 설명할 때 가장 직접적이다. 중복값에서는 pivot 하나의 정확한 위치보다 `equal`이 차지하는 **순위 구간**으로 설명해야 한다.

### 4.3 Worst-case recurrence

그룹 중앙값은 최대 $$\lceil n/5\rceil$$개이므로 pivot을 찾는 재귀 비용이 $$T(\lceil n/5\rceil)$$이다. Partition 뒤 목표가 속할 수 있는 큰 쪽은 최대 $$7n/10+O(1)$$개다. 그룹 정렬은 크기 5라는 상수 안에서 끝나고 전체 partition도 선형이므로

$$
T(n)
\le
T(\lceil n/5\rceil)
+T(7n/10+O(1))
+c_0n.
$$

29–31쪽처럼 반올림과 작은 입력의 상수를 생략한 핵심 점화식은

$$
T(n)\le T(n/5)+T(7n/10)+c_0n
$$

이다. 귀납 가설 $$T(m)\le cm$$을 대입하면

$$
T(n)
\le c\frac{n}{5}+c\frac{7n}{10}+c_0n
=\left(\frac{9c}{10}+c_0\right)n.
$$

반올림을 생략한 모형에서는 $$c\ge10c_0$$로 택하면 우변이 $$cn$$ 이하이다. 실제 점화식의 $$O(1)$$ 크기 오차는 $$c>10c_0$$로 약간의 여유를 두고 충분히 큰 $$n_0$$를 택하면 흡수할 수 있으며, $$n<n_0$$인 유한한 기저 구간은 $$c$$를 다시 키워 덮는다. 따라서 $$T(n)=O(n)$$이다. Selection의 $$\Omega(n)$$ 하한과 합치면 median of medians는 결정론적으로 최악 $$\Theta(n)$$이다. 두 재귀 입력 크기의 계수 합이 $$1/5+7/10=9/10<1$$이라는 점이 선형 상한을 가능하게 한다.

## 5. Complexity Comparison

| 방법 | Pivot 규칙 | 기대 시간 | 최악 시간 | 중복값 처리 |
|---|---|---:|---:|---|
| Full sorting | 해당 없음 | $$\Theta(n\log n)$$ | $$\Theta(n\log n)$$ | 정렬된 다중집합의 인덱스 사용 |
| Fixed-pivot Quickselect | 예: 항상 마지막 원소 | 입력 분포에 의존 | $$\Theta(n^2)$$ | 3-way partition 권장 |
| Randomized Quickselect | 현재 구간에서 균등 무작위 | $$\Theta(n)$$ | $$\Theta(n^2)$$ | 3-way equal 구간에서 즉시 종료 |
| Median of medians | 5개 그룹의 중앙값들의 중앙값 | $$\Theta(n)$$ | $$\Theta(n)$$ | 3-way partition과 순위 구간 사용 |

Randomized Quickselect는 구현이 단순하고 실제 성능이 좋은 반면, 최악 실행에 대한 선형 보장은 없다. Median of medians는 pivot 계산 자체에 재귀가 하나 더 필요하지만 입력과 난수에 의존하지 않는 최악 선형 상한을 준다.

## Source Check

| 슬라이드 위치 | 확인 결과 | 이 글의 처리 |
|---|---|---|
| 7쪽 | 입력 조건은 $$0\le i<n$$이고 이후 예시도 0-based이지만, 배열의 강조값 `58`은 1-based 네 번째 값이다. 0-based $$i=4$$의 실제 답은 `67`이다. | 순위를 0-based로 고정하고 배열을 직접 정렬해 `67`로 정정했다. |
| 8쪽 | “최솟값 찾기 $$i$$번”은 $$i=0$$일 때 작업이 0회가 되는 문제가 있다. | 0-based $$i$$의 답까지 얻으려면 작은 값 $$i+1$$개가 필요하므로 직접 반복법을 $$O((i+1)n)$$으로 적었다. |
| 13쪽 | `[l,r)` 반열린 구간과 전역 인덱스 $$i$$를 사용하는 Quickselect 코드다. | 재귀 경계를 `l,p`와 `p+1,r`로 해석하고, 중복값에서는 단일 `p` 대신 3-way 순위 구간을 사용했다. |
| 15–21쪽 | 평균 분석은 pivot 순위가 매 단계 균등하다는 가정에 의존한다. | “일반적인 평균 입력”으로 넓히지 않고, 균등·독립 무작위 pivot의 기대 $$\Theta(n)$$으로 조건을 명시했다. |
| 22–24쪽 | 제목의 “Worse case: $$\Theta(n)$$”는 1:9의 고정 비율 분할 사례를 가리킨다. 23쪽의 “pivot이 최댓값 혹은 최솟값만 아니면 $$\Theta(n)$$ 보장”은 일반적으로 거짓이다. | 고정된 상수 비율 분할이면 선형임을 기하급수로 유도하고, 매번 두 번째 극값을 고르는 반례는 $$\Theta(n^2)$$임을 분리했다. |
| 26·28쪽 | 30%–70% 보장은 반올림을 생략한 점근 설명이다. 26쪽 예시는 그룹 중앙값이 6개인데 `15`를 lower median으로 택한다. 28쪽의 $$(\lfloor g/2\rfloor+1)\cdot3$$을 양쪽에 동시에 적용하면 이 짝수 그룹 예시와 맞지 않는다. | 양쪽에 최소 $$3g/2$$개라는 점근 하한과 $$O(1)$$ 반올림 오차만 사용했다. 중복값은 단일 위치가 아니라 equal 순위 구간으로 처리했다. |
| 27쪽 | 화면의 첫 단계는 `arr[l:n]`으로 적혀 있어 매개변수 `r`과 불일치한다. 재귀 호출에는 `i`가 빠져 있고 작은 입력의 base case도 생략되어 있다. | 현재 범위를 `[l,r)`로 통일하고, 실행 가능한 보강 코드에는 순위 인자·base case·마지막 불완전 그룹을 모두 포함했다. |
| 29–31쪽 | 점화식은 반올림과 불완전 그룹의 상수 오차를 생략하며 결론은 최악 $$O(n)$$으로 표기한다. | 일반 점화식에 $$\lceil n/5\rceil$$과 $$O(1)$$을 복원하고, 독립적인 $$\Omega(n)$$ 하한을 더해 최악 $$\Theta(n)$$으로 정리했다. |

## 마지막 핵심 정리

- Selection의 $$i$$는 0-based 순위다. 중복값은 각각 순위를 차지하며, 3-way partition의 equal 구간으로 처리하면 정확성과 종료 조건이 명확하다.
- Quickselect는 partition 뒤 목표가 있는 한쪽만 처리한다. 균등 무작위 pivot이면 기대 $$\Theta(n)$$이지만 최악은 $$\Theta(n^2)$$이다.
- Pivot이 극값만 아니면 충분한 것이 아니다. 매 단계 상수 비율을 제거해야 선형 합이 보장된다.
- Median of medians는 크기 5 그룹을 이용해 재귀할 큰 쪽을 최대 $$7n/10+O(1)$$로 제한한다. 점화식의 두 재귀 비율 합이 $$9/10$$이므로 결정론적 최악 $$\Theta(n)$$이다.
- 강의 수식의 $$n$$은 현재 처리하는 원소 수, $$i$$와 $$k$$는 무차원 순위 인덱스, $$T(n)$$은 기본 연산 횟수에 비례하는 실행 비용이다.

다음 강의는 Dynamic Programming을 다룬다(34쪽).

## Study Guide

1. 먼저 0-based 순위를 고정하고, 작은 배열을 직접 정렬해 원하는 인덱스를 확인한다. 1-based “몇 번째” 표현과 섞지 않는다.
2. Partition 이후에는 값 자체보다 `lower`, `equal`, `higher`가 차지하는 인덱스 구간을 표시한다. 중복값이 있을 때 특히 중요하다.
3. Quickselect의 세 시간 주장을 구분한다: 최선 $$\Theta(n)$$, 무작위 기대 $$\Theta(n)$$, 최악 $$\Theta(n^2)$$.
4. $$T(9n/10)+cn$$과 $$T(n-1)+cn$$을 각각 전개해, 상수 비율 감소와 상수 개수 감소의 차이를 확인한다.
5. Median of medians에서는 그룹 중앙값을 구하는 재귀 $$T(n/5)$$와 partition 뒤 선택 재귀 $$T(7n/10)$$를 둘 다 써야 한다.
6. Source Check의 정정 항목을 원문 페이지와 다시 대조한다. 특히 7쪽의 rank 예제와 23쪽의 선형 보장 조건은 그대로 암기하지 않는다.

## 복습 질문

<details markdown="block">
<summary markdown="span">Q&A: 0-based $$i=4$$는 몇 번째 원소인가?</summary>

답변: 오름차순으로 정렬했을 때 인덱스 4에 있는 다섯 번째 원소다. 7쪽 배열을 정렬하면 `[21, 35, 46, 58, 67, 74, 83, 92]`이므로 답은 `67`이다.

</details>

<details markdown="block">
<summary>Q&A: Why does Quickselect recurse into only one partition?</summary>

답변: Partition이 pivot보다 작은 구간, 같은 구간, 큰 구간의 순위 범위를 확정하기 때문이다. 목표 인덱스는 세 범위 중 하나에만 속한다. Equal 범위면 pivot이 답이고, 아니면 목표가 속한 한쪽만 더 처리하면 된다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Does randomized Quickselect guarantee worst-case $$\Theta(n)$$ time?</summary>

답변: 아니다. 현재 구간에서 pivot을 균등하게 뽑으면 기대 시간은 $$\Theta(n)$$이지만, 계속 극단적인 pivot을 뽑는 실행도 가능하므로 최악 시간은 $$\Theta(n^2)$$이다.

</details>

<details markdown="block">
<summary>Q&A: Is avoiding the minimum and maximum pivot sufficient for linear time?</summary>

답변: 아니다. 매번 두 번째로 작은 pivot을 고르면 재귀 크기는 거의 `n-2`라서 partition 비용의 합이 이차가 된다. 선형 시간을 보장하려면 매 단계 현재 입력의 고정된 양의 비율을 제거해야 한다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Why does median of medians use groups of five?</summary>

답변: 5개 그룹에서는 중앙값 양쪽에 각각 3개를 중앙값 이하·이상으로 인증할 수 있다. 그 결과 큰 재귀 구간이 최대 약 $$7n/10$$이고, pivot 선택 재귀 $$n/5$$와 합쳐도 비율이 $$9/10<1$$이다. 이 강의의 증명은 바로 이 여유를 사용한다.

</details>

<details markdown="block">
<summary>Q&A: What changes when many values equal the pivot?</summary>

답변: Pivot 하나의 인덱스를 정하려 하지 않고 모든 같은 값을 equal 구간으로 묶는다. 목표 순위가 그 구간 안이면 즉시 pivot을 반환한다. 목표가 밖에 있으면 엄격히 작은 구간이나 엄격히 큰 구간만 재귀하므로 중복이 많아도 불필요하게 같은 값을 반복 처리하지 않는다.

</details>

## References

<ul>
  <li><a href="https://doi.org/10.1016/S0022-0000(73)80033-9" target="_blank" rel="noopener">Blum, Floyd, Pratt, Rivest, and Tarjan, “Time Bounds for Selection” (1973)</a> — deterministic linear-time selection의 원 논문.</li>
  <li><a href="https://ocw.mit.edu/courses/6-046j-design-and-analysis-of-algorithms-spring-2015/resources/mit6_046js15_recitation4/" target="_blank" rel="noopener">MIT OpenCourseWare 6.046J, Recitation 4: Randomized Select and Randomized Quicksort</a> — randomized selection의 기대 시간 점화식 참고.</li>
</ul>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-08-selection.pdf" | relative_url }}" target="_blank" rel="noopener">8 Selection.pdf</a></li>
</ul>
