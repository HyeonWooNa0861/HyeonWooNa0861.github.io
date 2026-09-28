---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Lecture 6: Heaps and Heap Sort"
course: "Algorithms"
topic: "Max-Heaps, Bottom-Up Construction, and In-Place Sorting"
order: 6
major_topic: "Data Structures & Algorithms"
keywords:
  - "Heap Sort"
  - "Max-Heap"
  - "Complete Binary Tree"
  - "Sift Down"
  - "Build Heap"
  - "Loop Invariant"
---

# Lecture 6: Heaps and Heap Sort

Source PDF: [6 Sorting (3).pdf](/assets/pdfs/study/algorithms/06-sorting-03.pdf)

이 강의는 최대 힙의 배열 표현, `siftdown`, 바닥에서 위로 힙을 만드는 방법, 그리고 그 힙으로 제자리 정렬하는 과정을 다룬다. 핵심은 **힙 내부가 완전히 정렬된 것은 아니지만 루트에는 최대값이 있다**는 성질을 반복 활용하는 것이다. 아래의 인덱스 공식·불변식·복잡도 증명은 강의의 그림과 코드를 연결하기 위한 작성자 보충이다.

> **핵심:** 최대 힙을 $$\Theta(n)$$ 시간에 만들고, 루트의 최대값을 뒤쪽 정렬 구간으로 $$n-1$$번 옮긴다. 각 이동 후 높이만큼 `siftdown`하므로 최악 시간은 $$\Theta(n\log n)$$, 배열 이외의 보조 공간은 $$\Theta(1)$$이다.

## 전체 흐름

| PDF 쪽 | 내용 | 이 글에서 다루는 위치 |
|---|---|---|
| 1–5 | 제목, 이전 병합·퀵 정렬 복습, 목차 | 도입 및 Comparison |
| 6–11 | 최대 힙의 정의, 배열 인덱스, sift down | Max-Heap, Sift Down |
| 12–17 | bottom-up build, $$\Theta(n)$$ 분석 | Build Heap, Source Check |
| 18–24 | 루트 추출을 반복하는 Heap Sort | Heap Sort, Worked Example |
| 25–28 | 요약, 다음 강의, 질문 | Comparison, Study Guide, Q&A |

## 1. Max-Heap

### 1.1 Shape and order

최대 힙(max-heap)은 **완전 이진트리의 모양**과 **힙 순서**를 동시에 만족한다(7–8쪽). 완전 이진트리는 마지막 층을 제외한 모든 층이 채워져 있고 마지막 층은 왼쪽부터 빈틈없이 채워진다. 각 부모의 키는 자식의 키보다 크거나 같아야 한다. 그러므로 루트가 전체의 최대값이다. 그러나 형제나 서로 다른 가지의 원소는 대소 관계가 정해지지 않는다. 힙은 “최대값을 빠르게 찾는 구조”이지 “배열 전체가 정렬된 상태”가 아니다.

완전 이진트리는 층별로 왼쪽에서 오른쪽 순서로 배열에 빈칸 없이 담을 수 있다(9쪽). 0부터 시작하는 인덱스 $$k$$의 자식과 부모는 다음과 같다.

$$
\operatorname{left}(k)=2k+1,\qquad
\operatorname{right}(k)=2k+2,\qquad
\operatorname{parent}(k)=\left\lfloor\frac{k-1}{2}\right\rfloor\ (k>0).
$$

예를 들어 슬라이드의 최대 힙 배열 `[88, 85, 83, 72, 73, 42, 57, 6, 48, 60]`에서 인덱스 1의 값 `85`는 인덱스 3·4의 값 `72`·`73`보다 크다. 인덱스 0의 값 `88`은 1·2의 `85`·`83`보다 크다. 인덱스 $$\lfloor n/2\rfloor$$ 이상은 자식이 없는 잎이다. 높이는 $$\lfloor\log_2 n\rfloor$$ 이하이므로 한 경로를 따라 내려가는 작업은 $$O(\log n)$$이다.

### 1.2 Sift Down

`sift_down(i, arr, n)`은 유효 범위 `arr[0:n]`에서 인덱스 `i`의 값을 아래로 내려 힙 순서를 복구한다(10–11쪽). **전제는 `i`의 두 자식 아래가 이미 각각 힙**이라는 것이다. 원소를 무조건 아래로 보내는 게 아니라, 더 큰 자식을 골라 부모보다 클 때만 교환한다.

```python
def sift_down(i, arr, n):
    while 2 * i + 1 < n:
        child = 2 * i + 1
        if child + 1 < n and arr[child] < arr[child + 1]:
            child += 1
        if arr[i] >= arr[child]:
            break
        arr[i], arr[child] = arr[child], arr[i]
        i = child
```

이 코드는 강의의 `siftdown`과 같은 구조이되 동점일 때 불필요한 교환을 하지 않도록 `>=`에서 멈춘다. 반복 시작 시 현재 노드 아래 두 자식의 부분트리는 각각 힙이다. 더 큰 자식과 비교해 부모가 작으면 교환한다. 교환 후 예전 부모가 내려간 위치에서만 힙 조건이 깨질 수 있으므로 그 위치를 다음 `i`로 삼는다. 부모가 더 크거나 같으면 그 노드의 부분트리 전체가 힙이어서 즉시 종료한다. 한 번에 층 하나를 내려가므로 최악 $$O(\log n)$$, 이미 조건을 만족하면 $$O(1)$$이며 추가 배열은 쓰지 않는다.

## 2. Build Heap from the Bottom

### 2.1 Why start at the last internal node?

길이 $$n$$인 배열에서 $$\lfloor n/2\rfloor$$ 이상은 잎이므로 이미 크기 1의 힙이다. 따라서 마지막 내부 노드 $$\lfloor n/2\rfloor-1$$부터 루트 0까지 거꾸로 `sift_down`한다(12–16쪽). 이 순서에서는 `i`를 처리할 때 그 자식 아래의 부분트리가 이미 힙이므로 앞 절의 전제가 성립한다.

```python
def build_heap(arr):
    n = len(arr)
    for i in range(n // 2 - 1, -1, -1):
        sift_down(i, arr, n)
```

루프 불변식은 “현재 `i`보다 큰 인덱스를 루트로 하는 모든 부분트리가 힙이다”이다. 잎에서 시작할 때 참이고, 자식들이 이미 힙인 `i`에 `sift_down`을 적용하면 `i`의 부분트리도 힙이 된다. 인덱스 0까지 마치면 전체 배열이 힙이다. 슬라이드 입력 `[73, 6, 57, 88, 60, 42, 83, 72, 48, 85]`(12–16쪽)은 `[88, 85, 83, 72, 73, 42, 57, 6, 48, 60]`이라는 최대 힙이 된다. 이것은 여전히 오름차순 정렬 결과가 아니다.

### 2.2 Why construction is linear

`sift_down` 하나의 최악 시간이 $$O(\log n)$$이라고 해서, 그 작업을 $$n/2$$번 하는 build가 반드시 $$O(n\log n)$$인 것은 아니다(17쪽). 대부분의 노드가 바닥 가까이에 있어 내려갈 수 있는 거리가 짧다. 높이 $$h$$인 노드는 대략 $$n/2^{h+1}$$개 이하이고, 각 노드의 비용은 $$O(h)$$이다. 따라서 상한은 다음처럼 묶인다.

$$
\sum_{h=1}^{\lfloor\log_2 n\rfloor}
\left\lceil\frac{n}{2^{h+1}}\right\rceil O(h)
=O\!\left(n\sum_{h\ge1}\frac{h}{2^h}\right)+O((\log n)^2)
=O(n).
$$

무한급수 $$S=\sum_{h\ge1}h/2^h$$에서 한 칸 이동한 $$S/2$$를 빼면 $$S-S/2=\sum_{h\ge1}1/2^h=1$$이므로 $$S=2$$다. 또한 $$O((\log n)^2)=O(n)$$이다. 이 코드가 실제로 방문하는 내부 노드는 $$\lfloor n/2\rfloor$$개이며 각 호출에서 적어도 상수 횟수의 제어 연산을 실행하므로 $$\Omega(n)$$이다. 따라서 build 비용은 $$\Theta(n)$$이다. 더 직관적으로는 “노드는 많을수록 낮고, 높을수록 적다”는 가중 합의 결과다. 여기서 $$n$$의 단위는 **원소 수**, $$h$$의 단위는 **트리 층수**, 합으로 추정한 값의 단위는 **기본 연산 횟수**다. 이 분석은 힙 정렬 전체의 $$n\log n$$ 비용과 구분해야 한다.

## 3. Heap Sort

### 3.1 Repeated maximum extraction

최대 힙의 루트가 최대값이라는 사실을 이용한다(18–24쪽). 먼저 힙을 만든다. 현재 힙 범위를 `arr[0:i+1]`로 볼 때 `arr[0]`과 `arr[i]`를 교환하면 최대값이 정렬될 최종 위치 `i`로 이동한다. 힙 범위를 `arr[0:i]`로 줄이고, 새 루트를 `sift_down`하여 힙을 복구한다.

```python
def heap_sort(arr):
    build_heap(arr)
    for i in range(len(arr) - 1, 0, -1):
        arr[0], arr[i] = arr[i], arr[0]
        sift_down(0, arr, i)
```

반복 시작 시의 불변식은 다음 두 가지다.

1. 앞쪽 `arr[0:i+1]`은 최대 힙이다.
2. 뒤쪽 `arr[i+1:n]`은 오름차순으로 정렬되었고, 앞쪽의 모든 원소 이상이다.

교환으로 앞쪽 최대값을 인덱스 `i`에 놓으면 뒤쪽 정렬 구간이 한 칸 확장된다. 현재 힙에 남은 `i`개 원소 중 새 루트만 힙 조건을 위반할 수 있으므로 `sift_down(0, arr, i)`로 복구한다. `i=0`까지 오면 뒤쪽에 모든 원소가 놓여 배열 전체가 오름차순이다. 원소를 교환할 뿐 제거하지 않으므로 입력의 다중집합도 보존된다.

### 3.2 Worked example

위 입력의 build 결과 `[88, 85, 83, 72, 73, 42, 57, 6, 48, 60]`에서 첫 단계는 루트 `88`을 마지막 `60`과 바꾼다. 인덱스 9의 `88`은 이후 더 이상 힙에 속하지 않는 확정 원소다. 앞의 9개에 `sift_down`을 적용하면 `[85, 73, 83, 72, 60, 42, 57, 6, 48 | 88]`이 된다. 다음 단계에서는 `85`가 그다음 확정 위치로 이동한다. 마지막 결과는 `[6, 42, 48, 57, 60, 72, 73, 83, 85, 88]`이다(19–24쪽). 수직선 `|`은 설명을 위해 힙 영역과 확정 영역을 구분한 표시이며 실제 배열의 원소는 아니다.

### 3.3 Time, space, and stability

build에 $$\Theta(n)$$, 최대 $$n-1$$번의 추출과 복구에 각각 $$O(\log n)$$이므로 전체 최악 시간은 $$O(n\log n)$$이다. 하한은 비교 정렬의 결정 트리로 확인할 수 있다. 서로 다른 $$n$$개 키의 가능한 순열은 $$n!$$개이고, 이들을 구별하는 이진 비교 트리의 최악 깊이는 적어도 $$\lceil\log_2(n!)\rceil=\Omega(n\log n)$$이다. 힙 정렬 역시 비교 정렬이므로 최악 시간은 $$\Theta(n\log n)$$이다. 이 보장은 퀵 정렬의 마지막-원소 피벗 방식과 달리 입력 순서에 의존하지 않는다. 배열 내부에서 교환하므로 보조 공간은 $$\Theta(1)$$이다. 다만 멀리 떨어진 원소를 교환해 같은 키의 원래 순서를 바꿀 수 있어 일반적으로 안정적이지 않다. 시간 분석의 $$n$$은 원소 수이며, 비용은 비교·교환 등을 상수 시간의 기본 연산으로 센 횟수다.

## 4. Comparison

| 정렬 | 최악 시간 | 추가 배열/스택 | 안정성 조건 |
|---|---|---|---|
| Merge Sort | $$\Theta(n\log n)$$ | 임시 배열 $$\Theta(n)$$ | 동점 시 왼쪽 우선 병합이면 안정적 |
| Quick Sort (5강 구현) | $$\Theta(n^2)$$ | 스택 최악 $$\Theta(n)$$ | 일반적으로 불안정 |
| Heap Sort | $$\Theta(n\log n)$$ | $$\Theta(1)$$ | 일반적으로 불안정 |

세 알고리즘 모두 비교를 사용하지만 비용과 저장 공간의 균형이 다르다. 힙 정렬의 장점은 **추가 배열 없이 최악 시간 상한을 보장**한다는 점이고, 단점은 안정성이 필요한 자료에는 그대로 쓰기 어렵다는 점이다.

## Source Check

| 슬라이드 위치 | 확인할 점 | 이 글의 처리 |
|---|---|---|
| 7–9쪽 | 최대 힙 그림에서 부모·자식 관계만 직접 확인 가능 | 루트가 최대라는 결론은 모든 경로에서 부모 $$\ge$$ 자식 관계를 반복 적용한 결과라고 설명한다. 형제나 다른 가지까지 정렬된 것으로 해석하지 않는다. |
| 11쪽 | 원문 `siftdown`은 `arr[i] > arr[c]`이면 멈춤 | 값이 같으면 교환하지만 정확성 문제는 없다. 불필요한 동점 교환을 피하도록 재구성 코드는 `>=`로 멈춘다. |
| 12–16쪽 | 바닥부터 `siftdown`을 호출하는 코드·그림 | 각 자식 부분트리가 이미 힙이라는 전제를 루프 불변식으로 명시했다. 마지막 내부 노드는 $$\lfloor n/2\rfloor-1$$이다. |
| 17쪽 | build의 $$\sum_h \lceil n/2^{h+1}\rceil\Theta(h)$$ 요약 | 단일 `siftdown`의 최악 $$O(\log n)$$을 단순히 횟수로 곱하지 않고 높이별 비용 합으로 $$O(n)$$을 설명했다. $$\Theta(n)$$의 하한도 분리해 적었다. |
| 19–24쪽 | 루트를 뒤로 보내고 줄어든 힙에서 복구 | `sift_down(0, arr, i)`의 세 번째 인자는 **마지막 인덱스가 아니라 유효 길이** `i`다. 확정된 꼬리 구간을 건드리지 않음을 명시했다. |

## 마지막 핵심 정리

- 최대 힙은 **완전 이진트리 + 부모가 자식 이상**이라는 두 조건을 만족한다. 루트는 최대값이지만 전체 배열은 정렬되지 않았다.
- Bottom-up `build_heap`은 낮은 노드가 많다는 높이별 가중 합 때문에 $$\Theta(n)$$이다.
- Heap Sort는 힙 접두부의 최대값을 뒤쪽의 확정 접미부로 하나씩 옮긴다. 최악 $$\Theta(n\log n)$$, 보조 공간 $$\Theta(1)$$, 일반적으로 불안정하다.

다음 강의에서는 값의 범위나 자릿수 같은 추가 정보를 활용하는 특수한 정렬 알고리즘으로 넘어간다(27쪽).

## Study Guide

1. 힙의 **모양 조건**과 **부모-자식 순서 조건**을 분리해 말해 보자. 한쪽만 맞으면 힙이 아니다.
2. 배열 인덱스 0·1·2의 자식 위치를 직접 계산하고, `n//2`부터 왜 잎인지 확인한다.
3. `sift_down`을 호출하기 전 자식 부분트리가 힙인지 따진다. 이 전제가 build의 처리 순서와 정렬 중 루트 복구의 이유다.
4. build의 비용과 정렬의 비용을 따로 더한다. `build_heap`은 $$\Theta(n)$$이고, 추출 반복 전체가 $$\Theta(n\log n)$$의 최악 비용을 만든다.
5. 반복 중 **힙 접두부**와 **정렬된 접미부**의 경계를 `i`로 표시해 예시를 손으로 추적해 보자.

## 복습 질문

<details markdown="block">
<summary>Q&A: Is a max-heap already sorted?</summary>

답변: 아니다. 최대 힙은 각 부모가 자식보다 크거나 같다는 국소 관계만 보장한다. 루트에는 최대값이 있지만, 다른 가지의 원소가 전체 오름차순이나 내림차순으로 나열되지는 않는다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Why does `build_heap` take linear time rather than $$n\log n$$?</summary>

답변: 루트 근처 노드는 아래로 오래 내려갈 수 있지만 수가 적고, 바닥 근처 노드는 많지만 거의 내려가지 않는다. 높이별 노드 수와 비용을 곱해 합치면 $$n\sum_{h\ge1}h/2^h=2n$$ 규모다. 그래서 최악 $$O(n)$$이고 $$\lfloor n/2\rfloor$$개 내부 노드 방문의 하한까지 포함하면 $$\Theta(n)$$이다.

</details>

<details markdown="block">
<summary>Q&A: Why is the heap boundary i, not i + 1, after the swap?</summary>

답변: 교환으로 인덱스 `i`에 이번 단계의 최대값을 확정했기 때문이다. 이후 유효 힙은 `arr[0:i]`의 `i`개 원소뿐이다. `sift_down`에 길이 `i`를 전달해야 확정된 원소를 다시 건드리지 않는다.

</details>

<details markdown="block">
<summary>Q&A: Why is heap sort not stable?</summary>

답변: 루트와 배열 끝을 바꾸는 장거리 교환은 같은 키끼리의 상대 순서를 보존하지 않는다. 안정성이 필요한 레코드 정렬이라면 같은 키의 원래 순서를 유지하는 병합 방식 또는 원래 위치를 부가 키로 쓰는 별도 처리가 필요하다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/06-sorting-03.pdf" | relative_url }}" target="_blank" rel="noopener">6 Sorting (3).pdf</a></li>
</ul>
