---
layout: default
title: "LS14 Merge Sort"
course: "Data Structures"
topic: "Merge Sort"
order: 14
---

# LS14 Merge Sort

Source PDF: `LS14_merge_sort.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 분할 정복 | 큰 문제를 어떻게 나누고 다시 합치는가? |
| 2 | 병합 정렬 전략 | divide, conquer, merge가 각각 무엇인가? |
| 3 | 두 정렬 배열 병합 | 두 포인터로 어떻게 `O(n)` 병합을 하는가? |
| 4 | 구현 | `mergeSort()`와 `merge()`는 어떤 역할을 하는가? |
| 5 | 복잡도 | 왜 전체 시간이 `O(n log n)`인가? |

## 1. 분할 정복 Divide and Conquer

분할 정복은 다음 세 단계로 문제를 해결한다.

| 단계 | 의미 |
|---|---|
| Divide | 큰 문제를 작은 하위 문제로 나눈다. |
| Conquer | 하위 문제를 각각 해결한다. |
| Merge | 하위 문제의 답을 결합해 전체 답을 만든다. |

병합 정렬은 분할 정복의 대표 예시다.

## 2. 병합 정렬의 전략

병합 정렬은 다음 순서로 동작한다.

1. 입력 배열을 절반으로 나눈다.
2. 왼쪽과 오른쪽 배열을 재귀적으로 병합 정렬한다.
3. 정렬된 두 배열을 하나의 정렬된 배열로 병합한다.

핵심은 "정렬은 재귀가 하고, 실제 정렬된 순서를 만드는 작업은 merge가 한다"는 점이다.

## 3. 두 정렬 배열 병합

이미 정렬된 두 배열이 있다고 하자.

```text
left  = [3, 4, 7, 12, 13]
right = [2, 5, 6, 8, 9]
```

병합은 두 배열의 앞 원소를 비교하며 더 작은 값을 결과 배열에 넣는 방식이다.

```text
i = 0, j = 0
while i < left.size and j < right.size:
    smaller one -> result
```

한쪽 배열이 끝나면 나머지 배열의 남은 원소를 그대로 붙인다.

두 배열의 모든 원소를 한 번씩만 처리하므로 병합 시간은 `O(n)`이다.

## 4. `mergeSort()` 구현 흐름

```java
List<Integer> mergeSort(List<Integer> inList) {
    if (inList.size() <= 1)
        return inList;

    int mid = inList.size() / 2;
    List<Integer> left = new ArrayList<>(inList.subList(0, mid));
    List<Integer> right = new ArrayList<>(inList.subList(mid, inList.size()));

    return merge(mergeSort(left), mergeSort(right));
}
```

중요한 부분은 기저 조건이다. 길이가 0 또는 1인 리스트는 이미 정렬되어 있으므로 그대로 반환한다.

## 5. `merge()` 구현 흐름

```java
List<Integer> merge(List<Integer> left, List<Integer> right) {
    List<Integer> result = new ArrayList<>();
    int i = 0, j = 0;

    while (i < left.size() && j < right.size()) {
        if (left.get(i) <= right.get(j))
            result.add(left.get(i++));
        else
            result.add(right.get(j++));
    }

    while (i < left.size())
        result.add(left.get(i++));

    while (j < right.size())
        result.add(right.get(j++));

    return result;
}
```

시험에서 빈칸이 나온다면 세 구간을 떠올리면 된다.

1. 둘 다 남아 있을 때 작은 값 선택
2. 왼쪽 남은 값 모두 붙이기
3. 오른쪽 남은 값 모두 붙이기

## 6. 시간 복잡도

병합 정렬은 매 단계에서 배열을 절반으로 나눈다. 따라서 재귀 깊이는 `log n`이다.

각 깊이에서는 모든 원소가 병합 과정에 한 번씩 참여하므로 레벨당 비용은 `n`이다.

```text
총 비용 = 레벨 수 * 레벨당 비용
       = log n * n
       = O(n log n)
```

## 7. 공간 복잡도

강의 구현처럼 새 리스트를 만들어 병합하면 보조 배열이 필요하다. 따라서 추가 공간은 보통 `O(n)`으로 본다.

## 병합 정렬 특징

| 항목 | 내용 |
|---|---|
| 전략 | 분할 정복 |
| 시간 복잡도 | `O(n log n)` |
| 추가 공간 | `O(n)` |
| 강점 | 최악의 경우에도 안정적으로 `O(n log n)` |
| 약점 | 보조 배열 공간이 필요 |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 병합 정렬의 기저 조건은? | 리스트 길이 0 또는 1 |
| 병합 연산이 `O(n)`인 이유는? | 각 원소를 한 번씩 결과에 넣기 때문 |
| 전체가 `O(n log n)`인 이유는? | 깊이 `log n`, 각 깊이 비용 `n` |
| merge 함수의 마지막 두 while문은 왜 필요한가? | 한쪽 배열에 남은 원소를 붙이기 위해 |

## 복습 질문

<details>
<summary>1. `[4, 3, 9, 8, 7, 6, 5, 2]`를 처음 divide하면 어떤 두 배열로 나뉘는가?</summary>

답변: 가운데를 기준으로 `[4, 3, 9, 8]`과 `[7, 6, 5, 2]`로 나뉜다. 병합 정렬은 리스트를 절반씩 나누는 방식으로 재귀를 진행한다.

</details>

<details>
<summary>2. 병합 정렬은 왜 선택/삽입/버블 정렬보다 큰 입력에서 유리한가?</summary>

답변: 병합 정렬은 `O(n log n)`이고, 선택/삽입/버블 정렬은 평균 또는 최악에서 보통 `O(n^2)`이다. 입력이 커질수록 `n^2`은 `n log n`보다 훨씬 빠르게 증가하므로 병합 정렬이 유리하다.

</details>

<details>
<summary>3. 병합 정렬이 추가 메모리를 쓰는 지점은 어디인가?</summary>

답변: 두 정렬된 부분 배열을 하나로 합치는 `merge` 단계에서 결과를 담을 보조 배열 또는 리스트가 필요하다. 강의 구현처럼 `left`, `right`, `result` 리스트를 만들면 추가 공간이 `O(n)` 든다.

</details>

## Study Notes

병합 정렬은 분할 정복의 구조를 가장 깔끔하게 보여 주는 정렬 알고리즘이다. 정렬 문제를 절반씩 나누고, 작은 리스트가 될 때까지 내려간 뒤, 정렬된 두 리스트를 다시 합친다.

```text
[4, 3, 9, 8, 7, 6, 5, 2]

divide
[4, 3, 9, 8] [7, 6, 5, 2]

divide
[4, 3] [9, 8] [7, 6] [5, 2]

divide
[4] [3] [9] [8] [7] [6] [5] [2]
```

길이가 1인 리스트는 이미 정렬되어 있다. 이후 merge 단계에서 정렬된 작은 리스트들을 합쳐 큰 정렬 리스트를 만든다.

병합의 핵심은 두 리스트가 이미 정렬되어 있다는 점이다. 그래서 맨 앞 원소끼리만 비교하면 된다.

```text
left  = [3, 4, 7]
right = [2, 5, 6]

compare 3 and 2 -> take 2
compare 3 and 5 -> take 3
compare 4 and 5 -> take 4
compare 7 and 5 -> take 5
compare 7 and 6 -> take 6
right empty, append 7

result = [2, 3, 4, 5, 6, 7]
```

각 merge는 원소를 한 번씩만 결과에 넣으므로 `O(n)`이다. 문제 크기를 절반씩 나누기 때문에 재귀 깊이는 `log n`이다. 따라서 전체는 `O(n log n)`이다.

## Properties

| 항목 | 병합 정렬 |
|---|---|
| 방식 | divide and conquer |
| 시간 | 항상 `O(n log n)` |
| 공간 | 보조 배열 때문에 보통 `O(n)` |
| 안정성 | 안정 정렬로 구현 가능 |
| 강점 | 최악의 경우에도 성능 보장 |
| 약점 | 추가 메모리 사용 |

병합 정렬은 quick sort보다 평균 실제 속도에서 불리할 수 있지만, 최악 시간 보장이 좋고 안정 정렬이 필요할 때 유용하다.

## Recursive Thinking

재귀 코드를 볼 때는 두 가지를 확인한다.

1. 기저 조건: 더 나눌 필요가 없는가?
2. 결합 조건: 작은 문제의 답을 어떻게 합치는가?

병합 정렬의 기저 조건은 크기 0 또는 1이고, 결합 조건은 `merge(left, right)`이다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structure/LS14_merge_sort.pdf" | relative_url }}" target="_blank" rel="noopener">LS14_merge_sort.pdf</a></li>
</ul>
