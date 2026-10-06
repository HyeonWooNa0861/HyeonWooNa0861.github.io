---
layout: default
date: 2026-10-06 12:10:00 +0900
title: "Lecture 7: Counting Sort and Radix Sort"
course: "Algorithms"
topic: "Comparison Lower Bounds, Stable Counting Sort, and LSD Radix Sort"
order: 7
major_topic: "Data Structures & Algorithms"
keywords:
  - "Comparison Sorting"
  - "Counting Sort"
  - "Radix Sort"
  - "Stable Sort"
  - "Decision Tree"
  - "LSD"
---

# Lecture 7: Counting Sort and Radix Sort

Source PDF: [7 Sorting (4).pdf](/assets/pdfs/study/algorithms/lecture-07-sorting-04.pdf)

이 강의는 원소끼리 대소를 비교하는 정렬의 한계를 먼저 확인한 뒤, 정수 키의 범위와 자릿수라는 추가 정보를 사용하는 Counting Sort와 LSD Radix Sort를 다룬다. 핵심은 이 알고리즘들이 비교 정렬의 하한을 깨는 것이 아니라, **비교만 허용하는 모델을 벗어나 제한된 키 영역에 직접 접근한다**는 데 있다. Counting Sort의 누적 개수와 역방향 배치는 안정성을 만들고, 그 안정성이 Radix Sort의 자리별 정렬 결과를 다음 단계까지 보존한다.

> **핵심:** 비교 정렬에는 최악의 경우 $$\Omega(n\log n)$$번의 비교가 필요하다. 키가 $$0$$ 이상 $$r-1$$ 이하인 정수라는 조건에서는 Counting Sort가 $$\Theta(n+r)$$ 시간에 안정 정렬할 수 있다. 이를 $$k$$개 자릿수에 반복하는 LSD Radix Sort의 시간은 $$\Theta(k(n+r))$$이며, 각 자리 정렬이 반드시 안정적이어야 한다.

## 전체 흐름

| PDF 쪽 | 내용 | 이 글에서 다루는 위치 |
|---|---|---|
| 1–5 | 제목, 이전 Heap Sort 복습, 목차 | 도입 및 Comparison Sorting |
| 6–8 | 비교 정렬의 공통점과 질문 | 비교 정렬 하한 |
| 9–14 | Counting Sort의 아이디어, 코드, 애니메이션, 복잡도 | Counting Sort, Worked Example |
| 15–19 | radix, 자릿수, LSD·MSD, 안정 정렬 | Radix Sort의 전제 |
| 20–26 | 네 자리 수의 LSD Radix Sort 단계 | Radix Sort Worked Example |
| 27 | Radix Sort 복잡도 | 시간·공간 분석, Source Check |
| 28–31 | 요약, 다음 강의, 질문 | 마지막 핵심 정리, Study Guide, 복습 질문 |

## 1. Comparison Sorting and Its Lower Bound

### 1.1 비교 정렬의 모델

Bubble Sort, Selection Sort, Insertion Sort, Merge Sort, Quick Sort, Heap Sort는 실행 방식은 다르지만, 정렬 순서를 결정할 때 원소 사이의 대소 비교를 사용한다(7쪽). 서로 다른 $$n$$개 키를 정렬한다고 하자. 한 번의 이진 비교는 가능한 경우를 두 갈래로 나누므로, 비교 과정을 이진 결정 트리로 나타낼 수 있다. 입력의 가능한 순열은 $$n!$$개이며 모든 순열을 구별하려면 결정 트리에 적어도 $$n!$$개의 잎이 필요하다.

트리 높이를 $$h$$, 즉 최악 입력에서 수행하는 비교 횟수를 $$h$$회라고 하면 높이 $$h$$인 이진 트리의 잎 수는 최대 $$2^h$$개다. 따라서 다음 부등식이 성립한다.

$$
2^h \ge n!
\quad\Longrightarrow\quad
h \ge \log_2(n!).
$$

$$\log_2(n!)$$의 성장률은 직접 하한을 잡아 확인할 수 있다. $$n$$이 2 이상일 때 뒤쪽 절반의 인수는 각각 $$n/2$$ 이상이므로,

$$
n!
=1\cdot2\cdots n
\ge \left(\frac{n}{2}\right)^{n/2}.
$$

양변에 밑이 2인 로그를 적용하면,

$$
\log_2(n!)
\ge \frac{n}{2}\log_2\!\left(\frac{n}{2}\right)
=\Omega(n\log n).
$$

여기서 $$n$$의 단위는 **원소 수**, $$h$$와 로그 하한의 단위는 **비교 횟수**다. 이 하한은 임의의 키를 비교 결과만으로 구별하는 정렬에 적용된다. 따라서 비교 정렬은 최악의 경우 $$\Omega(n\log n)$$보다 빠를 수 없다. Merge Sort와 Heap Sort의 최악 시간 $$\Theta(n\log n)$$은 이 모델에서 점근적으로 최적이다.

### 1.2 Counting Sort가 하한과 충돌하지 않는 이유

8쪽은 비교 없이 더 빠른 정렬이 가능한지 묻는다. 답은 **입력 키에 추가 조건이 있으면 가능하다**이다. Counting Sort는 두 키를 비교해 순서를 찾지 않는다. 키가 제한된 정수라는 사실을 이용해 키 자체를 배열 인덱스로 사용한다. Radix Sort도 각 자릿수를 제한된 범위의 키로 취급한다. 두 알고리즘은 비교 정렬의 결정 트리 모델에 속하지 않으므로 $$\Omega(n\log n)$$ 비교 하한과 모순되지 않는다.

## 2. Counting Sort

### 2.1 입력 조건과 기호

Counting Sort의 입력을 길이 $$n$$인 배열 $$A$$라고 하자. 이 글에서 $$r$$은 가능한 키의 **개수**이며, 각 키는 다음 조건을 만족한다.

$$
A[i]\in\{0,1,\ldots,r-1\}.
$$

즉 $$0\le A[i]<r$$이다. $$n$$과 $$r$$은 모두 개수를 나타내므로 무차원이다. 음수, 실수, 문자열을 이 구현에 그대로 인덱스로 사용할 수는 없다. 최소 키가 $$m$$인 연속 정수 범위라면 $$A[i]-m$$으로 평행 이동할 수 있지만, 필요한 카운트 배열 크기는 여전히 전체 범위의 폭이다.

10쪽의 예시는 다음 열 개의 키를 사용한다.

```text
A = [5, 1, 5, 1, 0, 4, 1, 2, 4, 5]
n = 10, r = 6
```

값별 빈도 배열 $$c$$는 `[1, 3, 1, 0, 2, 3]`이다. 인덱스 0부터 5가 각 키를 나타내고, $$c[v]$$는 키 $$v$$의 출현 횟수다.

### 2.2 누적 개수가 위치를 결정하는 과정

빈도만 알면 같은 값을 몇 번 출력해야 하는지는 알 수 있지만, 안정적으로 레코드를 배치할 정확한 위치는 아직 정해지지 않는다. 이를 위해 누적 배열 $$C$$를 만든다.

$$
C[v]=\sum_{t=0}^{v}c[t].
$$

이 식은 정확한 등식이며, $$C[v]$$는 키가 $$v$$ 이하인 원소의 개수다. 따라서 0부터 시작하는 출력 배열에서 키 $$v$$가 차지할 마지막 위치의 다음 인덱스가 된다. 예시의 누적 배열은 `[1, 4, 5, 5, 7, 10]`이다. 키 4 이하인 원소가 7개이므로 키 4가 들어갈 마지막 인덱스는 처음에는 $$7-1=6$$이다.

원소 $$x$$ 하나를 배치할 때는 다음 두 갱신을 수행한다.

$$
C[x]\leftarrow C[x]-1,
\qquad
B[C[x]]\leftarrow x.
$$

감소 후의 $$C[x]$$가 아직 비어 있는 키 $$x$$의 가장 오른쪽 위치다. 같은 키를 다시 만나면 위치가 한 칸 왼쪽으로 이동한다. 모든 원소를 처리한 뒤 출력 배열 $$B$$를 입력 배열에 복사한다.

### 2.3 Stable Counting Sort code

강의 코드의 의미를 유지하면서 매개변수의 범위를 명시하면 다음과 같다(12–14쪽).

```python
def counting_sort(arr, r):
    """Sort integer keys x satisfying 0 <= x < r."""
    n = len(arr)
    counts = [0] * r

    for x in arr:
        counts[x] += 1

    for value in range(1, r):
        counts[value] += counts[value - 1]

    output = [0] * n
    for x in reversed(arr):
        counts[x] -= 1
        output[counts[x]] = x

    arr[:] = output
```

세 반복문의 의미는 각각 **빈도 계산**, **누적 위치 계산**, **안정적 배치**다. `arr[:] = output`은 새 리스트 객체로 반환하는 대신 기존 리스트의 내용을 정렬 결과로 바꾼다.

### 2.4 역방향 순회가 안정성을 만드는 이유

안정 정렬은 키가 같은 레코드들의 입력 상대 순서를 보존한다(19쪽). 입력에서 키 1인 레코드를 `1_B`, `1_D`, `1_G`라고 표시해 보자. 출력 위치는 왼쪽부터 세 칸이 연속으로 배정된다. 입력을 오른쪽에서 왼쪽으로 처리하면 `1_G`가 가장 오른쪽 칸, `1_D`가 가운데 칸, `1_B`가 가장 왼쪽 칸에 들어가므로 최종 순서는 `1_B, 1_D, 1_G`다.

반대로 누적 배열을 그대로 사용하면서 입력을 왼쪽에서 오른쪽으로 처리하면 `1_B`가 가장 오른쪽 칸부터 차지해 순서가 뒤집힌다. 단순 정수만 정렬하면 값이 같아 차이를 볼 수 없지만, 키와 데이터를 함께 가진 레코드나 Radix Sort의 중간 단계에서는 이 차이가 정확성을 결정한다.

### 2.5 Worked example

강의의 배열을 역방향으로 처리하는 첫 네 단계는 다음과 같다(13쪽).

| 읽은 원소 | 감소 후 위치 | 출력 배열에서 확정된 항목 |
|---|---:|---|
| 마지막 `5` | 9 | `B[9] = 5` |
| 뒤에서 두 번째 `4` | 6 | `B[6] = 4` |
| `2` | 4 | `B[4] = 2` |
| 그 앞의 `1` | 3 | `B[3] = 1` |

같은 과정을 끝까지 수행하면 다음 결과를 얻는다.

```text
빈도:     [1, 3, 1, 0, 2, 3]
누적값:   [1, 4, 5, 5, 7, 10]
정렬 결과: [0, 1, 1, 1, 2, 4, 4, 5, 5, 5]
```

빈도 합은 $$1+3+1+0+2+3=10=n$$이고, 누적 배열의 마지막 값도 $$C[5]=10=n$$이다. 두 값은 카운트 누락이나 중복을 찾는 간단한 검산 기준이다.

### 2.6 Time and space complexity

입력을 세는 데 $$\Theta(n)$$, 길이 $$r$$인 배열을 누적하는 데 $$\Theta(r)$$, 출력 배열에 배치하고 다시 복사하는 데 각각 $$\Theta(n)$$이 든다. 따라서 정확한 점근 시간은

$$
T(n,r)=\Theta(n)+\Theta(r)+\Theta(n)+\Theta(n)
=\Theta(n+r).
$$

카운트 배열은 $$\Theta(r)$$칸, 출력 배열은 $$\Theta(n)$$칸이므로 추가 공간은 $$\Theta(n+r)$$이다. $$r=O(n)$$이면 시간은 $$\Theta(n)$$이지만, $$r\gg n$$이면 대부분 비어 있는 카운트 배열을 초기화하고 순회하는 비용이 커진다. Counting Sort는 키 범위가 입력 크기에 비해 충분히 작을 때 유리하다.

## 3. LSD Radix Sort

### 3.1 자리별 정렬의 전제

Radix Sort는 큰 키 범위 전체에 카운트 배열 하나를 만들지 않고, 각 키를 기수 $$r$$의 자릿수로 나눈다(16–18쪽). 입력 키가 음이 아닌 정수이고 모두 $$k$$자리 이하라고 하자. 그러면

$$
0\le x<r^k
$$

이며, 오른쪽에서 $$j$$번째 자릿수는 다음과 같이 계산한다.

$$
d_j(x)=\left\lfloor\frac{x}{r^j}\right\rfloor\bmod r,
\qquad 0\le j<k.
$$

$$d_j(x)$$는 $$0$$부터 $$r-1$$까지의 무차원 정수다. $$j=0$$은 least significant digit, 즉 가장 낮은 자리이고, $$j=k-1$$은 가장 높은 자리다. 자릿수가 짧은 수의 앞쪽에는 0이 있다고 해석한다. 예를 들어 네 자리 10진수 정렬에서 `4`는 `0004`로 처리한다.

### 3.2 Why every pass must be stable

LSD Radix Sort는 $$j=0,1,\ldots,k-1$$ 순서로 각 자릿수에 대해 안정 정렬을 수행한다(19–26쪽). 첫 패스가 끝나면 일의 자리 순서가 맞는다. 다음 패스에서 십의 자리가 같은 원소들의 기존 상대 순서를 보존하면, 그 그룹 안의 일의 자리 순서가 그대로 남는다. 따라서 십의 자리까지 고려한 순서가 맞아진다.

이를 루프 불변식으로 정리할 수 있다.

> $$j$$번째 패스를 마친 배열은 각 키의 하위 $$j+1$$자리, 즉 $$x\bmod r^{j+1}$$를 기준으로 정렬되어 있다.

초기 패스 $$j=0$$은 일의 자리 하나를 직접 정렬하므로 불변식이 성립한다. $$j-1$$번째 패스 뒤에 하위 $$j$$자리가 정렬되어 있다고 가정하자. $$j$$번째 자릿수로 안정 정렬하면 더 작은 $$d_j$$를 가진 원소가 먼저 오고, $$d_j$$가 같은 원소들은 이전의 하위 $$j$$자리 순서를 유지한다. 그러므로 하위 $$j+1$$자리 전체가 정렬된다. 마지막 패스 뒤에는 $$0\le x<r^k$$인 키의 모든 자리가 반영되므로 전체 키 순서와 일치한다.

안정성이 없는 정렬을 자리별 패스에 쓰면 같은 현재 자릿수를 가진 원소의 낮은 자리 순서가 깨질 수 있다. 그 경우 마지막 패스가 끝나도 전체 수의 순서는 보장되지 않는다.

### 3.3 Counting Sort as the digit sorter

각 자릿수 $$d_j(x)$$는 범위가 정확히 $$0$$부터 $$r-1$$이므로 Stable Counting Sort를 적용하기 적합하다. 레코드 전체를 자릿수별 버킷 위치로 옮기고, 입력을 역방향으로 읽어 같은 자릿수의 상대 순서를 보존한다.

```python
def radix_sort(arr, r=10):
    if not arr:
        return

    place = 1
    maximum = max(arr)

    while maximum // place > 0:
        counts = [0] * r
        output = [0] * len(arr)

        for x in arr:
            digit = (x // place) % r
            counts[digit] += 1

        for digit in range(1, r):
            counts[digit] += counts[digit - 1]

        for x in reversed(arr):
            digit = (x // place) % r
            counts[digit] -= 1
            output[counts[digit]] = x

        arr[:] = output
        place *= r
```

이 구현은 음이 아닌 정수와 $$r\ge2$$를 전제로 한다. 모든 값이 0이면 반복을 수행하지 않아도 이미 정렬되어 있다. 음수를 포함하려면 부호를 분리하는 등 별도 규칙이 필요하며, 위 코드에 그대로 넣으면 올바른 자릿수 순서를 얻을 수 없다.

### 3.4 Worked example: four decimal digits

20–26쪽의 입력을 앞쪽 0까지 포함해 쓰면 다음과 같다.

```text
0123, 2154, 0222, 0004, 0283, 1560, 1061, 2150
```

각 자리의 안정 정렬 결과는 다음과 같다.

```text
1의 자리:    1560, 2150, 1061, 0222, 0123, 0283, 2154, 0004
10의 자리:   0004, 0222, 0123, 2150, 2154, 1560, 1061, 0283
100의 자리:  0004, 1061, 0123, 2150, 2154, 0222, 0283, 1560
1000의 자리: 0004, 0123, 0222, 0283, 1061, 1560, 2150, 2154
```

첫 패스에서 일의 자리 0인 `1560`과 `2150`은 입력에서의 순서를 유지한다. 둘째 패스에서 십의 자리 2인 `0222`와 `0123`도 직전 배열의 순서를 유지한다. 이런 보존이 누적되어 마지막 배열이 수 전체의 오름차순과 일치한다.

### 3.5 Time, space, and the role of the key range

한 자리의 Stable Counting Sort는 $$\Theta(n+r)$$ 시간과 $$\Theta(n+r)$$ 추가 공간을 사용한다. 이를 $$k$$번 반복하므로,

$$
T(n,r,k)=\Theta(k(n+r)).
$$

출력 배열과 카운트 배열은 패스마다 재사용할 수 있으므로 추가 공간은 $$\Theta(n+r)$$이지 $$\Theta(k(n+r))$$가 아니다. 최대 키를 $$U>0$$라고 하면 필요한 자릿수는 정확히

$$
k=\left\lfloor\log_r U\right\rfloor+1
$$

이다. $$U=0$$이면 한 자리로 보거나 정렬 패스를 생략할 수 있다. 따라서 복잡도는 입력 개수 $$n$$만으로 결정되지 않고, 키의 최대 크기 $$U$$와 선택한 기수 $$r$$에도 의존한다. $$r$$을 크게 하면 패스 수는 줄지만 카운트 배열의 초기화·순회 비용과 공간이 늘어난다.

## Source Check

| 슬라이드 위치 | 확인할 점 | 이 글의 처리 |
|---|---|---|
| 7–8쪽 | 비교 기반 정렬과 비비교 정렬의 차이 | $$\Omega(n\log n)$$은 비교만으로 순서를 결정하는 모델의 하한임을 결정 트리로 유도했다. |
| 10·12·14쪽 | 설명은 “값이 `r` 이하”, 코드는 `cnts = [0] * r` | 코드에서 유효한 인덱스는 0부터 `r - 1`까지다. 이 글은 $$r$$을 키 개수로 정의해 $$0\le x<r$$로 정정했다. 최대 키를 $$R$$로 정의한다면 배열 길이는 $$R+1$$이어야 한다. |
| 12–13쪽 | 누적 카운트와 역방향 배치 | 예시의 빈도 `[1, 3, 1, 0, 2, 3]`, 누적값 `[1, 4, 5, 5, 7, 10]`, 최종 정렬 결과를 독립 계산했다. 역방향 순회가 안정성을 보장함을 태그가 있는 중복 키로 검산했다. |
| 19–26쪽 | LSD부터 각 자리 안정 정렬 | 네 패스의 중간 배열을 각각 다시 계산했으며 슬라이드의 순서와 일치한다. 자리별 안정성이 필요한 이유를 루프 불변식으로 증명했다. |
| 27쪽 | “모든 원소가 다르면 $$k=\log_r n$$” | 서로 다른 값 $$n$$개라는 사실은 $$r^k\ge n$$, 즉 $$k\ge\lceil\log_r n\rceil$$만 요구한다. 실제 $$k$$는 최대 키 $$U$$에 의해 $$\lfloor\log_r U\rfloor+1$$로 정해진다. equality에는 키 영역이 정확히 그 규모라는 추가 조건이 필요하다. |

## 마지막 핵심 정리

- 비교 정렬은 $$n!$$개의 순열을 비교 결과로 구별해야 하므로 최악의 경우 $$\Omega(n\log n)$$번의 비교가 필요하다.
- Counting Sort는 정수 키 $$0\le x<r$$를 배열 인덱스로 사용해 $$\Theta(n+r)$$ 시간에 정렬한다. 누적 개수는 출력 위치의 경계를 제공한다.
- 누적 위치를 사용하면서 입력을 뒤에서 앞으로 배치하면 같은 키의 상대 순서가 유지되어 안정 정렬이 된다.
- LSD Radix Sort는 낮은 자리부터 높은 자리까지 Stable Counting Sort를 반복한다. 패스 불변식은 “처리한 하위 자릿수 전체를 기준으로 정렬되어 있다”이다.
- Radix Sort의 시간은 $$\Theta(k(n+r))$$, 추가 공간은 $$\Theta(n+r)$$이다. 자릿수 $$k$$는 입력 개수만이 아니라 최대 키와 기수에 의해 결정된다.

다음 강의는 정렬된 결과에서 원하는 원소를 선택하는 Selection 문제로 넘어간다(30쪽).

## Study Guide

1. 비교 정렬의 하한은 “모든 정렬”의 하한이 아니라 **비교만 사용하는 정렬 모델**의 하한임을 구분한다.
2. Counting Sort에서 $$r$$이 최대 키인지 키 개수인지 먼저 확인한다. `counts`의 길이가 $$r$$이면 유효 키는 0부터 $$r-1$$까지다.
3. 빈도 배열과 누적 배열의 의미를 분리한다. $$c[v]$$는 키 $$v$$의 개수이고, $$C[v]$$는 키가 $$v$$ 이하인 원소의 개수다.
4. 같은 키에 태그를 붙여 역방향 배치를 추적한다. 정수 값만 보면 안정성이 보이지 않으므로 레코드의 상대 순서를 확인해야 한다.
5. Radix Sort의 각 패스 뒤에 어떤 하위 자릿수까지 정렬되었는지 적고, 안정성이 깨졌을 때 이전 패스 결과가 왜 사라지는지 설명해 본다.
6. 복잡도를 쓸 때 $$n$$, $$r$$, $$k$$를 모두 남긴다. 키 범위에 대한 조건 없이 Radix Sort를 단순히 선형 시간이라고 부르면 적용 조건이 빠진다.

## 복습 질문

<details markdown="block">
<summary markdown="span">Q&A: Why does the $$\Omega(n\log n)$$ lower bound not rule out Counting Sort?</summary>

답변: 그 하한은 두 원소의 비교 결과만으로 순서를 결정하는 정렬에 적용된다. Counting Sort는 제한된 정수 키를 카운트 배열의 인덱스로 사용한다. 비교 모델에 없는 키 영역 정보를 사용하므로 $$\Theta(n+r)$$ 시간이 가능하며, 이는 비교 정렬 하한과 모순되지 않는다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: What does cumulative count $$C[v]$$ mean?</summary>

답변: $$C[v]=\sum_{t=0}^{v}c[t]$$는 키가 $$v$$ 이하인 원소의 개수다. 따라서 0부터 시작하는 출력 배열에서 키 $$v$$ 구간의 오른쪽 경계 다음 인덱스를 나타낸다. 원소를 놓기 전에 1을 감소시키면 현재 비어 있는 가장 오른쪽 위치를 얻는다.

</details>

<details markdown="block">
<summary>Q&A: Why does stable Counting Sort scan the input backward?</summary>

답변: 누적 카운트는 같은 키의 출력 구간을 오른쪽 끝부터 배정한다. 입력을 뒤에서 읽으면 나중에 등장한 레코드가 오른쪽에 먼저 놓이고, 먼저 등장한 레코드는 그보다 왼쪽에 놓인다. 결과적으로 같은 키의 입력 상대 순서가 보존된다.

</details>

<details markdown="block">
<summary>Q&A: Why must every LSD Radix Sort pass be stable?</summary>

답변: 높은 자릿수로 정렬할 때 같은 현재 자릿수를 가진 원소들의 낮은 자릿수 순서를 유지해야 하기 때문이다. 불안정한 정렬은 이전 패스가 만든 낮은 자리 순서를 바꿀 수 있어 전체 키 순서를 깨뜨린다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Does having $$n$$ distinct keys imply $$k=\log_r n$$?</summary>

답변: 아니다. 서로 다른 $$n$$개 키를 $$k$$자리 기수 $$r$$로 표현하려면 가능한 표현 수가 충분해야 하므로 $$r^k\ge n$$은 필요하다. 그러나 실제 자릿수는 최대 키 $$U$$에 의해 정해지며, $$U>0$$이면 $$k=\lfloor\log_r U\rfloor+1$$이다. equality에는 키 영역의 크기에 관한 추가 조건이 필요하다.

</details>

## References

- [Lecture 6: Heaps and Heap Sort](/study/algorithms/lecture-06-sorting-03/) — 이번 강의가 비교 정렬로 분류하는 Heap Sort의 구조와 복잡도
- `7 Sorting (4).pdf`, 1–31쪽 — Comparison Sorting, Counting Sort, LSD Radix Sort, complexity analysis

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-07-sorting-04.pdf" | relative_url }}" target="_blank" rel="noopener">7 Sorting (4).pdf</a></li>
</ul>
