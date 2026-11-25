---
layout: default
date: 2026-05-19 12:11:10 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "LS08 Doubly Linked Lists and Dictionaries"
course: "Data Structures"
topic: "Doubly Linked Lists and Dictionaries"
order: 8
major_topic: "Data Structures & Algorithms"
keywords:
  - "Doubly Linked Lists"
  - "Dictionaries"
  - "List Nodes"
  - "Search"
  - "Key-Value Pairs"
---

# LS08 Doubly Linked Lists and Dictionaries

Source PDF: `LS08_dll_dictionary.pdf`

단일 연결 리스트는 다음 노드만 기억하므로 이전 노드로 바로 돌아갈 수 없습니다. 이중 연결 리스트는 앞·뒤 주소를 모두 저장해 양쪽으로 이동합니다. 대신 노드 하나를 넣거나 뺄 때 앞쪽 연결과 뒤쪽 연결을 모두 정확히 고쳐야 합니다.

> **핵심:** 이중 연결 리스트는 `next`뿐 아니라 `prev`도 저장하므로 양방향으로 이동할 수 있습니다. 노드를 삽입할 때는 새 노드의 `prev`·`next`와 양옆 노드의 `next`·`prev`를 함께 갱신해야 합니다.

## 원본 그림으로 읽기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/data-structures/LS08_dll_dictionary.pdf#page=25" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/data-structures/source-figures/ls08-p25-doubly-linked-list.jpg" | relative_url }}" alt="prev, item, next 필드를 가진 이중 연결 리스트 노드의 강의 도식" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 25. 각 노드는 이전과 다음 노드 양쪽을 가리킵니다.</figcaption>
</figure>

가운데 `item=20`을 기준으로 왼쪽 포인터는 `prev`, 오른쪽 포인터는 `next`입니다. 양방향 탐색과 주어진 노드의 `O(1)` 삭제가 가능해지는 대신, 삽입·삭제 때 양쪽 연결을 모두 갱신해야 하고 노드당 포인터 하나가 더 필요합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 스택/큐 구현 복습 | 비어 있는 경우와 마지막 원소 삭제는 어떻게 처리합니까? |
| 2 | 단방향 선형 구조 | 배열, 연결 리스트, 스택, 큐는 왜 한 방향적 성격을 갖습니까? |
| 3 | 이중 연결 리스트 | `prev`와 `next`를 함께 쓰면 무엇이 좋아집니까? |
| 4 | 딕셔너리 | 인덱스가 아니라 key로 값을 찾는 구조는 무엇입니까? |
| 5 | 해시 충돌 | 딕셔너리의 평균 $$O(1)$$은 언제 깨질 수 있습니까? |

</details>

## 1. 스택과 큐 구현에서 중요한 예외 처리

이 강의는 이전 강의에서 비워 둔 스택/큐 코드의 핵심 처리도 복습합니다.

| 구조 | 핵심 처리 |
|---|---|
| ArrayStack | `pop()`은 `--top` 후 반환, `topValue()`는 `top - 1` 반환 |
| LinkedStack | `pop()` 후 `top = top.next`, `size--` |
| ArrayQueue | `front = (front + 1) % capacity` |
| LinkedQueue | 마지막 노드 삭제 시 `rear = null` |

시험에서 코드 빈칸이 나오면 "현재 포인터/인덱스가 무엇을 의미하는가"를 먼저 확인해야 합니다.

## 2. 단방향 선형 구조

배열, 단일 연결 리스트, 스택, 큐는 모두 선형 자료구조입니다. 데이터가 일렬로 배치되고 접근 흐름이 비교적 일정합니다.

| 구조 | 단방향적 성격 |
|---|---|
| 배열 | 앞에서 뒤로 순차 탐색하는 경우가 많습니다. |
| 단일 연결 리스트 | `next`만 있어 뒤로만 이동합니다. |
| 스택 | `top` 한쪽 끝에서만 접근합니다. |
| 큐 | `rear`에서 삽입하고 `front`에서 삭제합니다. |

## 3. 이중 연결 리스트

이중 연결 리스트는 각 노드가 이전 노드와 다음 노드를 모두 가리킵니다.

```java
private static class Node<E> {
    E item;
    Node<E> prev;
    Node<E> next;
}
```

| 필드 | 의미 |
|---|---|
| `prev` | 이전 노드 |
| `next` | 다음 노드 |

이 구조는 양방향 탐색이 가능하고, 특정 노드를 알고 있을 때 그 노드의 앞뒤 연결을 더 쉽게 바꿀 수 있습니다.

## 4. 이중 연결 리스트 삽입

`A`와 `B` 사이에 `X`를 넣는다고 생각하면 네 연결을 맞춰야 합니다.

```text
A <-> B

A <-> X <-> B
```

필요한 갱신은 다음과 같습니다.

```java
X.prev = A;
X.next = B;
A.next = X;
B.prev = X;
```

네 줄은 같은 연결을 양쪽에서 일치시키는 작업입니다. `X.prev = A`, `X.next = B`만 실행하면 X는 양옆을 알지만 A와 B에서 출발한 순회는 여전히 X를 건너뜁니다. 반대로 주변 노드만 X를 가리키게 하고 X의 링크를 비워 두면 X에서 앞뒤로 이동할 수 없습니다. 즉 `A.next == X`와 `X.prev == A`, `X.next == B`와 `B.prev == X`가 각각 한 쌍으로 맞아야 합니다.

단, 맨 앞이나 맨 뒤 삽입에서는 `head`, `tail`, `null` 처리가 추가됩니다.

## 5. 이중 연결 리스트 삭제

`A <-> X <-> B`에서 `X`를 삭제하려면 `A`와 `B`를 직접 이어 줍니다.

```java
A.next = B;
B.prev = A;
```

삭제 대상이 `head`나 `tail`이면 각각 `head = head.next`, `tail = tail.prev` 형태의 처리가 필요합니다.

## 6. 이중 연결 리스트 장단점

| 장점 | 설명 |
|---|---|
| 양방향 탐색 | 앞뒤로 이동할 수 있습니다. |
| 삭제/삽입 유연성 | 특정 노드를 알고 있으면 앞뒤 연결을 쉽게 바꿀 수 있습니다. |
| `tail` 활용 | 뒤쪽 작업이 더 자연스럽습니다. |

| 단점 | 설명 |
|---|---|
| 메모리 증가 | 노드마다 `prev` 포인터가 추가됩니다. |
| 구현 복잡성 | 삽입/삭제 시 갱신할 포인터가 많습니다. |
| 예외 처리 증가 | 빈 리스트, 맨 앞, 맨 뒤 처리가 중요합니다. |

## 7. 딕셔너리 Dictionary

딕셔너리는 데이터를 key-value 쌍으로 저장하는 구조입니다.

```text
key       value
"2025001" -> "Alice"
"2025017" -> "Cindy"
```

리스트가 위치나 인덱스로 원소를 찾는다면, 딕셔너리는 key로 value를 찾습니다.

예를 들어 `get("2025017")`은 두 번째 칸을 달라는 요청이 아니라, key가 `"2025017"`인 기록을 달라는 요청입니다. 저장 순서가 바뀌어도 같은 key는 같은 학생 기록을 가리켜야 합니다. 그래서 딕셔너리를 이해할 때는 위치보다 **key가 어떤 대상을 식별하는가**를 먼저 정해야 합니다.

| 연산 | 의미 |
|---|---|
| `put(key, value)` | key-value 쌍 삽입 또는 기존 값 수정 |
| `get(key)` | key에 해당하는 value 탐색 |
| `remove(key)` | key-value 쌍 삭제 |
| `contains(key)` | key 존재 여부 확인 |

## 8. 딕셔너리의 특징

| 특징 | 설명 |
|---|---|
| key는 유일 | 같은 key는 하나만 존재합니다. |
| value는 중복 가능 | 여러 key가 같은 value를 가질 수 있습니다. |
| 평균 탐색 $$O(1)$$ | 해시 함수를 통해 key를 배열 인덱스로 바꿉니다. |
| 순서 없음 | 일반적으로 삽입 순서나 정렬 순서를 보장하지 않습니다. |
| 충돌 가능 | 서로 다른 key가 같은 인덱스로 갈 수 있습니다. |

충돌이 많아지면 삽입, 삭제, 탐색이 최악의 경우 $$O(n)$$까지 느려질 수 있습니다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 단일 연결 리스트와 이중 연결 리스트의 차이는 무엇입니까? | 이중 연결 리스트는 `prev`와 `next`를 모두 가집니다. |
| 이중 연결 리스트 삽입 시 갱신해야 할 포인터는 무엇입니까? | 새 노드의 `prev/next`, 주변 노드의 `next/prev` |
| 딕셔너리는 리스트와 무엇이 다릅니까? | 위치가 아니라 key로 value를 찾습니다. |
| 딕셔너리의 평균 $$O(1)$$이 항상 보장됩니까? | 충돌이 많으면 최악 $$O(n)$$ 가능 |

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

이중 연결 리스트 삽입·삭제는 새 노드와 양쪽 이웃의 prev/next 네 연결을 그림에 표시한 뒤 한 줄씩 코드로 옮깁니다. dictionary는 위치가 아니라 unique key로 value를 찾으며 value 자체는 중복될 수 있다는 점을 리스트와 대비합니다. 해시 기반 평균 O(1)은 충돌이 적다는 조건부 주장이고 최악 O(n)도 가능하다는 문장이 시험 핵심입니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. `A <-> B` 사이에 `X`를 넣을 때 포인터 네 개를 어떤 순서로 바꿉니까?</summary>

답변: `X.prev = A`, `X.next = B`, `A.next = X`, `B.prev = X`로 연결합니다. 핵심은 새 노드가 양쪽 노드를 가리키고, 양쪽 노드도 새 노드를 가리키게 만드는 것입니다.

</details>

<details markdown="block">
<summary>2. 딕셔너리에서 key는 중복될 수 있습니까?</summary>

답변: key는 중복될 수 없습니다. 같은 key를 다시 넣으면 보통 새 항목을 추가하는 것이 아니라 기존 key의 value를 갱신합니다. value는 중복될 수 있습니다.

</details>

<details markdown="block">
<summary>3. 딕셔너리가 순서를 유지하지 않는다는 말은 정렬된 출력이 필요할 때 어떤 의미를 갖습니까?</summary>

답변: 일반적인 해시 기반 딕셔너리는 key의 정렬 순서를 보장하지 않습니다. 따라서 정렬된 출력이 필요하면 key를 따로 정렬하거나, 처음부터 트리 기반 맵처럼 순서를 유지하는 자료구조를 사용해야 합니다.

</details>

## Study Notes

### 복잡도 주장의 조건 확인

> **분류:** stack/queue 복습과 dictionary 비용에 대한 **불변식·조건부 분석**입니다.
>
> **원문 추적:** Source PDF 10--20쪽의 stack/queue 복잡도 표와 원형 큐 코드, 25--31쪽의 이중 연결 리스트 연산, 35--38쪽의 dictionary 연산·특징을 대조한 보충 해설입니다.

용량 $$C>0$$인 원형 배열 큐는 `rear`와 `front`를 각각 $$(x+1)\bmod C$$로 갱신합니다. 나머지는 항상 $$0,\ldots,C-1$$ 범위라 배열 끝 다음이 0으로 이어집니다. 별도 `size`를 둔다면 $$0\le\mathrm{size}\le C$$, empty는 `size == 0`, full은 `size == C`가 불변식입니다. `front == rear`만으로 두 상태를 모두 나타내면 구분할 수 없으므로 한 칸을 비우거나 flag가 필요합니다.

여기서 $$n$$은 저장 원소 수, $$C$$는 배열 용량이며 둘 다 무차원 개수입니다. 이중 연결 리스트에서 삭제할 노드 참조를 이미 알고 있으면 `prev.next`, `next.prev` 등 상수 개의 링크만 바꾸므로 $$\Theta(1)$$입니다. 반면 key로 노드를 먼저 찾아야 하면 최대 $$n$$개 노드를 지나므로 탐색이 $$\Theta(n)$$일 수 있습니다. 해시 dictionary의 평균 $$O(1)$$ 역시 좋은 분산과 낮은 충돌을 가정한 조건부 결론이며, 모든 key가 한 슬롯에 모이면 체인이나 probe를 $$n$$개 확인해 최악 $$\Theta(n)$$입니다.

이중 연결 리스트는 단일 연결 리스트의 약점을 줄이기 위해 각 노드가 이전 노드와 다음 노드를 모두 기억합니다.

```text
null <- [A] <-> [B] <-> [C] -> null
```

이 구조의 장점은 뒤로도 이동할 수 있다는 점입니다. 특정 노드를 이미 알고 있다면 그 앞뒤의 연결을 더 쉽게 바꿀 수 있습니다. 단점은 노드마다 `prev` 포인터가 하나 더 필요하고, 삽입/삭제 시 갱신해야 할 포인터가 많아진다는 점입니다.

중간 삽입은 네 연결을 맞춰야 합니다.

```text
A <-> B 사이에 X 삽입

X.prev = A
X.next = B
A.next = X
B.prev = X
```

중간 삭제도 양쪽을 서로 직접 연결합니다.

```text
A <-> X <-> B 에서 X 삭제

A.next = B
B.prev = A
```

단, 삭제 대상이 첫 노드이거나 마지막 노드라면 `head`, `tail`, `null` 처리를 따로 확인해야 합니다. 그래서 실제 구현에서는 sentinel node를 두어 예외를 줄이는 경우도 많습니다.

딕셔너리는 연결 리스트와 관점이 다릅니다. 리스트는 위치 중심이고, 딕셔너리는 key 중심입니다. 사용자는 몇 번째 위치에 있는지보다 "이 key에 연결된 value가 무엇인가"를 묻습니다.

```text
studentId -> studentName
word      -> meaning
url       -> cachedPage
```

딕셔너리는 보통 해시 테이블로 구현되어 평균 $$O(1)$$ 탐색을 목표로 합니다. 하지만 이 평균 성능은 충돌이 적고 해시 함수가 값을 고르게 분산시킨다는 조건 위에 있습니다.

## Common Pitfalls

| 실수 | 올바른 이해 |
|---|---|
| 이중 연결 리스트 삽입에서 `prev`만 바꿉니다. | 양쪽 노드의 `next`, `prev`를 모두 맞춰야 합니다. |
| key와 value가 모두 유일하다고 생각합니다. | key는 유일하지만 value는 중복될 수 있습니다. |
| 딕셔너리를 항상 정렬된 구조로 생각합니다. | 일반적인 해시 기반 딕셔너리는 정렬 순서를 보장하지 않습니다. |
| 평균 $$O(1)$$을 최악 $$O(1)$$로 이해합니다. | 충돌이 심하면 최악 $$O(n)$$도 가능합니다. |

## 강의 수식과 관련 페이지

<details markdown="block">
<summary markdown="span">Reference: formulas and their source slides</summary>

Source PDF 40쪽 전체를 렌더링해 시각적으로 확인했습니다.

| PDF 페이지 | 확인한 수식·표현 | 본문 대응과 판단 |
|---|---|---|
| 1--9 | stack 구현 복습 | `top-1`, 인덱스 증감은 상태 전이 코드이며 별도 수학 증명 대상은 아닙니다. |
| 10--20 | stack/queue의 $$O(1)$$·$$O(n)$$ 공간 표와 $$(x+1)\bmod C$$ 코드 | 상수 연산 조건, 재할당 예외, 원형 index 불변식을 `복잡도 주장의 조건 확인`에서 설명했습니다. |
| 21--24 | 단방향 구조와 DLL 도입 | 개념·구조 그림이며 증명 대상 식은 없습니다. |
| 25--31 | DLL 구조, 삽입·삭제·순회 코드 | 대상 참조 확보 전후를 나눠 $$\Theta(1)$$ 갱신과 $$\Theta(n)$$ 탐색을 설명했습니다. |
| 32--34 | 사용 예와 dictionary 도입 | 예제 코드·이미지로, proof-level 수식이 없습니다. |
| 35--38 | dictionary 정의, 평균 $$O(1)$$와 최악 $$O(n)$$ | 균등 분산·낮은 충돌 가정과 한 슬롯 집중 반례를 설명했습니다. |
| 39--40 | HashMap 예제와 다음 강의 예고 | API 예제이며 추가 증명 대상 식은 없습니다. |

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS08_dll_dictionary.pdf" | relative_url }}" target="_blank" rel="noopener">LS08_dll_dictionary.pdf</a></li>
</ul>
