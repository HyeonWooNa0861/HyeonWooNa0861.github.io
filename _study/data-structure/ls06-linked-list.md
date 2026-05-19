---
layout: default
title: "LS06 연결 리스트"
course: "자료구조"
topic: "연결 리스트"
order: 6
---

# LS06 연결 리스트 요약

원본 자료: `LS06_linked_list.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 배열 기반 리스트 복습 | 배열 리스트는 왜 인덱스 접근이 빠르고 삽입/삭제가 느린가? |
| 2 | 연결 리스트 구조 | 노드와 포인터로 리스트를 어떻게 표현하는가? |
| 3 | 삽입 연산 | 맨 앞, 맨 뒤, 지정 위치 삽입은 어떻게 다른가? |
| 4 | 삭제와 탐색 | 삭제 전에는 왜 이전 노드까지 가야 하는가? |
| 5 | 배열 vs 연결 리스트 | 두 구현은 어떤 작업에서 각각 유리한가? |

## 1. 연결 리스트의 구조

연결 리스트는 각 원소를 노드로 저장하고, 노드들이 다음 노드를 가리키며 이어지는 구조다.

```java
class Node<E> {
    E item;
    Node<E> next;

    Node(E item, Node<E> next) {
        this.item = item;
        this.next = next;
    }
}
```

각 노드는 다음 두 정보를 가진다.

| 필드 | 의미 |
|---|---|
| `item` | 실제 데이터 |
| `next` | 다음 노드의 주소 |

연결 리스트 객체는 보통 `head`, `tail`, `size`를 가진다.

| 변수 | 역할 |
|---|---|
| `head` | 첫 번째 노드 |
| `tail` | 마지막 노드 |
| `size` | 현재 노드 개수 |

## 2. 배열 리스트와의 핵심 차이

배열은 원소를 연속된 메모리에 저장한다. 연결 리스트는 노드가 메모리 곳곳에 흩어져 있어도 `next` 포인터로 연결할 수 있다.

| 비교 | 배열 기반 리스트 | 연결 리스트 |
|---|---|---|
| 메모리 배치 | 연속적 | 비연속 가능 |
| 인덱스 접근 | 빠름 `O(1)` | 처음부터 따라가야 함 `O(n)` |
| 중간 삽입/삭제 작업 자체 | 원소 이동 필요 | 포인터만 바꾸면 됨 |
| 포인터 저장 공간 | 없음 | 노드마다 추가 필요 |

## 3. 맨 앞 삽입 `addFirst`

맨 앞 삽입은 새 노드의 `next`가 기존 `head`를 가리키게 한 뒤 `head`를 새 노드로 바꾸면 된다.

```java
public void addFirst(E item) {
    Node<E> newNode = new Node<>(item, head);
    head = newNode;
    if (tail == null)
        tail = newNode;
    size++;
}
```

빈 리스트였던 경우에는 `head`와 `tail`이 모두 새 노드를 가리켜야 한다.

시간 복잡도는 `O(1)`이다.

## 4. 맨 뒤 삽입 `addLast`

`tail`이 있으면 마지막 노드 뒤에 새 노드를 붙이고, `tail`을 새 노드로 갱신한다.

```java
public void addLast(E item) {
    Node<E> newNode = new Node<>(item, null);
    if (head == null) {
        head = newNode;
        tail = newNode;
    } else {
        tail.next = newNode;
        tail = newNode;
    }
    size++;
}
```

`tail` 포인터가 있기 때문에 맨 뒤 삽입도 `O(1)`이다. `tail`이 없다면 마지막 노드까지 매번 찾아가야 하므로 `O(n)`이 된다.

## 5. 지정 위치 삽입

지정 위치 삽입은 새 노드를 끼우는 작업 자체는 `O(1)`이다. 하지만 그 위치의 바로 앞 노드까지 가는 과정이 필요하므로 전체 시간은 `O(n)`이다.

```java
prev.next = new Node<>(item, prev.next);
```

이 한 줄의 의미는 다음과 같다.

1. 새 노드의 `next`는 원래 `prev.next`였던 노드를 가리킨다.
2. `prev.next`는 새 노드를 가리킨다.
3. 결과적으로 `prev -> newNode -> oldNext`가 된다.

## 6. 삭제 연산

단일 연결 리스트에서 어떤 노드를 삭제하려면 삭제할 노드의 바로 앞 노드가 필요하다.

```java
Node<E> target = prev.next;
prev.next = target.next;
```

맨 앞 삭제는 `head = head.next`로 처리할 수 있다. 단, 삭제 후 리스트가 비면 `tail = null`도 함께 처리해야 한다.

마지막 노드를 삭제하는 경우에는 `tail`을 이전 노드로 바꿔야 한다.

## 7. 탐색 연산

연결 리스트는 인덱스로 바로 접근할 수 없다. `head`에서 시작해 `next`를 따라가야 한다.

```java
Node<E> cur = head;
for (int i = 0; i < pos; i++)
    cur = cur.next;
return cur.item;
```

따라서 특정 위치 탐색은 `O(n)`이다.

## 8. 배열 기반 리스트 vs 연결 리스트

| 연산 | 배열 기반 리스트 | 연결 리스트 |
|---|---|---|
| 인덱스 접근 | `O(1)` | `O(n)` |
| 특정 값 탐색 | `O(n)` | `O(n)` |
| 맨 앞 삽입 | `O(n)` | `O(1)` |
| 맨 뒤 삽입 | `O(1)` | `O(1)` with `tail` |
| 지정 위치 삽입 | `O(n)` | `O(n)` 접근 + `O(1)` 연결 |
| 맨 뒤 삭제 | `O(1)` | `O(n)` |
| 지정 위치 삭제 | `O(n)` | `O(n)` 접근 + `O(1)` 연결 |
| 순회 | `O(n)` | `O(n)` |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 연결 리스트에서 중간 삽입이 `O(n)`인 이유는? | 연결 자체는 `O(1)`이지만 이전 노드까지 탐색해야 한다. |
| `tail` 포인터의 장점은? | 맨 뒤 삽입을 `O(1)`로 만든다. |
| 맨 앞 삭제 후 `tail` 처리가 필요한 경우는? | 마지막 노드를 삭제해서 리스트가 비는 경우 |
| 연결 리스트의 단점은? | 임의 접근 불가, 포인터 추가 메모리, 낮은 캐시 효율, 구현 복잡성 |

## 복습 질문

1. `head.next.next.item`은 어떤 순서로 노드를 따라가는가?
2. 단일 연결 리스트에서 마지막 노드 삭제가 `O(n)`인 이유는 무엇인가?
3. 삽입/삭제가 잦고 인덱스 접근이 거의 없는 경우 배열과 연결 리스트 중 무엇이 더 자연스러운가?
## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structure/LS06_linked_list.pdf" | relative_url }}" target="_blank" rel="noopener">LS06_linked_list.pdf</a></li>
</ul>
