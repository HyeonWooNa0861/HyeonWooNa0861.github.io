---
layout: default
title: "LS07 Stacks and Queues"
course: "Data Structures"
topic: "Stacks and Queues"
order: 7
---

# LS07 Stacks and Queues

Source PDF: `LS07_stack_queue_R1.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 리스트 복습 | 배열 리스트와 연결 리스트의 연산 비용은 어떻게 다른가? |
| 2 | 스택 | LIFO 구조를 어떤 연산으로 표현하는가? |
| 3 | 스택 구현 | 배열 기반과 연결 리스트 기반 스택은 어떻게 다른가? |
| 4 | 큐 | FIFO 구조를 어떤 연산으로 표현하는가? |
| 5 | 큐 구현 | 원형 큐와 연결 큐는 어떤 포인터/인덱스를 관리하는가? |

## 1. 스택 Stack

스택은 가장 나중에 들어온 원소가 가장 먼저 나가는 LIFO(Last-In First-Out) 구조다.

삽입과 삭제가 모두 한쪽 끝 `top`에서만 일어난다.

| 연산 | 의미 |
|---|---|
| `push(item)` | 맨 위에 원소 삽입 |
| `pop()` | 맨 위 원소 제거 후 반환 |
| `topValue()` | 맨 위 원소를 제거하지 않고 확인 |
| `length()` | 원소 개수 반환 |
| `clear()` | 스택 초기화 |

스택은 함수 호출 관리, 괄호 검사, DFS, 실행 취소 기능 등에 자주 쓰인다.

## 2. 배열 기반 스택 ArrayStack

배열 기반 스택은 내부 배열과 `top` 인덱스를 사용한다.

```java
private E[] listArray;
private int top;
private int capacity;
```

강의 코드에서는 `top`이 **다음에 삽입될 위치**를 가리킨다. 따라서 실제 맨 위 원소는 `top - 1`에 있다.

```java
public void push(E it) {
    if (top == capacity) throw new RuntimeException("Stack is full");
    listArray[top++] = it;
}
```

`pop()`은 먼저 `top`을 줄인 뒤 그 위치의 값을 반환한다.

```java
public E pop() {
    if (top == 0) throw new RuntimeException("Stack is empty");
    return listArray[--top];
}
```

## 3. 연결 리스트 기반 스택 LinkedStack

연결 스택에서는 `top`이 첫 번째 노드를 가리킨다. 새 원소는 항상 맨 앞에 붙인다.

```java
public void push(E it) {
    top = new Node<>(it, top);
    size++;
}
```

`pop()`은 현재 `top`의 값을 저장한 뒤 `top = top.next`로 한 칸 내려간다.

```java
public E pop() {
    if (top == null) throw new RuntimeException("Stack is empty");
    E val = top.item;
    top = top.next;
    size--;
    return val;
}
```

## 4. 스택 구현 비교

| 연산 | ArrayStack | LinkedStack |
|---|---|---|
| `push` | \(O(1)\) | \(O(1)\) |
| `pop` | \(O(1)\) | \(O(1)\) |
| `topValue` | \(O(1)\) | \(O(1)\) |
| `length` | \(O(1)\) | \(O(1)\) |
| 공간 | \(O(n)\) 배열 | \(O(n)\) + 포인터 |

ArrayStack은 배열이 가득 차면 재할당 비용이 발생할 수 있다. LinkedStack은 크기 제한이 덜하지만 노드마다 포인터 공간이 추가된다.

## 5. 큐 Queue

큐는 먼저 들어온 원소가 먼저 나가는 FIFO(First-In First-Out) 구조다.

| 연산 | 의미 |
|---|---|
| `enqueue(item)` | 뒤쪽 `rear`에 원소 삽입 |
| `dequeue()` | 앞쪽 `front`에서 원소 제거 후 반환 |
| `frontValue()` | 맨 앞 원소 확인 |
| `length()` | 원소 개수 반환 |
| `clear()` | 큐 초기화 |

큐는 작업 대기열, BFS, 프로세스 스케줄링 등에 사용된다.

## 6. 배열 기반 큐 ArrayQueue

배열 큐는 `front`, `rear`, `size`, `capacity`를 관리한다.

```java
private int front; // 삭제 위치
private int rear;  // 삽입 위치
private int size;
private int capacity;
```

일반 배열처럼 계속 뒤로만 이동하면 앞쪽 빈 공간을 재사용하지 못한다. 그래서 원형 큐를 사용한다.

```java
rear = (rear + 1) % capacity;
front = (front + 1) % capacity;
```

나머지 연산 `% capacity`가 인덱스를 배열 범위 안에서 순환시킨다.

## 7. 연결 리스트 기반 큐 LinkedQueue

연결 큐는 앞쪽 삭제를 위한 `front`, 뒤쪽 삽입을 위한 `rear`를 가진다.

```java
private Node<E> front;
private Node<E> rear;
private int size;
```

삽입 시에는 `rear.next`에 새 노드를 붙이고 `rear`를 갱신한다. 빈 큐라면 `front`와 `rear`가 모두 새 노드를 가리켜야 한다.

삭제 시 마지막 노드를 제거하면 `front`가 `null`이 된다. 이때 `rear = null`도 함께 처리해야 한다.

## 8. 큐 구현 비교

| 연산 | ArrayQueue | LinkedQueue |
|---|---|---|
| `enqueue` | \(O(1)\) | \(O(1)\) |
| `dequeue` | \(O(1)\) | \(O(1)\) |
| `frontValue` | \(O(1)\) | \(O(1)\) |
| `length` | \(O(1)\) | \(O(1)\) |
| 공간 | \(O(n)\) 배열 | \(O(n)\) + 포인터 |

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 스택과 큐의 차이는? | 스택은 LIFO, 큐는 FIFO |
| ArrayStack에서 `top`은 무엇을 가리키는가? | 다음 삽입 위치. 실제 top 값은 `top - 1` |
| 원형 큐에서 `% capacity`가 필요한 이유는? | 배열 끝 이후 다시 0번 인덱스로 돌아가기 위해 |
| LinkedQueue에서 마지막 원소 삭제 시 주의점은? | `front`뿐 아니라 `rear`도 `null`로 만들어야 한다. |

## 복습 질문

<details>
<summary>1. `push(1), push(2), pop(), push(3), pop()`의 반환 순서는?</summary>

답변: `2`, `3` 순서로 반환된다. 스택은 LIFO 구조이므로 가장 나중에 들어온 값이 먼저 나온다.

</details>

<details>
<summary>2. `enqueue(1), enqueue(2), dequeue(), enqueue(3), dequeue()`의 반환 순서는?</summary>

답변: `1`, `2` 순서로 반환된다. 큐는 FIFO 구조이므로 먼저 들어온 값이 먼저 나온다.

</details>

<details>
<summary>3. 배열 큐에서 원형 구조를 쓰지 않으면 어떤 공간 낭비가 생기는가?</summary>

답변: 앞쪽 원소를 `dequeue`한 뒤 배열 앞부분에 빈칸이 생겨도 `rear`가 계속 뒤로만 이동하면 그 빈칸을 재사용하기 어렵다. 원형 큐는 `% capacity`를 사용해 뒤쪽 끝 다음을 다시 0번 인덱스로 연결해 이 낭비를 줄인다.

</details>

## Study Notes

스택과 큐는 리스트보다 제한된 ADT다. 제한이 있다는 것은 불편하다는 뜻이 아니라, 오히려 동작이 명확해진다는 뜻이다. 스택은 한쪽 끝에서만 넣고 빼므로 LIFO가 되고, 큐는 뒤로 넣고 앞으로 빼므로 FIFO가 된다.

스택은 "가장 최근 작업"을 다룰 때 자연스럽다.

| 예시 | 스택이 맞는 이유 |
|---|---|
| 함수 호출 | 가장 나중에 호출된 함수가 먼저 종료된다. |
| 괄호 검사 | 가장 최근에 열린 괄호가 먼저 닫혀야 한다. |
| 되돌리기 | 가장 최근 작업부터 취소한다. |
| DFS | 최근에 발견한 경로를 먼저 깊게 탐색한다. |

큐는 "도착 순서"를 지켜야 할 때 자연스럽다.

| 예시 | 큐가 맞는 이유 |
|---|---|
| 프린터 대기열 | 먼저 요청한 작업을 먼저 처리한다. |
| BFS | 가까운 노드부터 순서대로 방문한다. |
| 네트워크 요청 | 먼저 들어온 요청부터 처리한다. |

원형 큐는 배열 큐의 핵심이다. 단순 배열 큐에서 `dequeue`를 할 때마다 모든 원소를 앞으로 당기면 비용이 \(O(n)\)이 된다. 그래서 `front`와 `rear` 인덱스만 움직이고, 배열 끝에 도달하면 `% capacity`로 처음으로 돌아간다.

$$
\mathrm{rear} = (\mathrm{rear}+1)\bmod \mathrm{capacity}
$$

$$
\mathrm{front} = (\mathrm{front}+1)\bmod \mathrm{capacity}
$$

이 식은 인덱스가 배열 범위를 벗어나지 않게 한다. 예를 들어 \(\mathrm{capacity}=5\)이고 \(\mathrm{rear}=4\)이면 다음 위치는 \((4+1)\bmod 5=0\)이다.

## Implementation Checklist

| 구조 | 확인할 상태 |
|---|---|
| ArrayStack | `top`이 다음 삽입 위치인지, 마지막 원소 위치인지 확인 |
| LinkedStack | `pop` 후 `top`과 `size` 갱신 |
| ArrayQueue | full/empty 조건, `% capacity` 적용 |
| LinkedQueue | 마지막 원소 삭제 시 `rear = null` 처리 |

스택과 큐 문제는 연산 순서를 직접 써 보면 대부분 풀린다. 반환값을 묻는 문제에서는 삽입된 순서와 삭제되는 순서를 표로 적는 습관이 좋다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS07_stack_queue_R1.pdf" | relative_url }}" target="_blank" rel="noopener">LS07_stack_queue_R1.pdf</a></li>
</ul>
