---
layout: default
title: "LS10 Binary Search Trees"
course: "Data Structures"
topic: "Binary Search Trees"
order: 10
---

# LS10 Binary Search Trees

Source PDF: `LS10_binary_search_tree.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 이진 트리 성질 | 높이와 노드 수 사이에는 어떤 관계가 있는가? |
| 2 | 완전 이진 트리의 배열 표현 | 부모와 자식 인덱스는 어떻게 계산하는가? |
| 3 | BST 정의 | 왼쪽/오른쪽 서브트리는 어떤 키 조건을 만족해야 하는가? |
| 4 | BST ADT | 탐색, 삽입, 삭제, 최소/최대 삭제는 어떤 연산인가? |
| 5 | 탐색과 삽입 | 비교 결과에 따라 재귀적으로 어디로 이동하는가? |

## 1. 이진 트리의 노드 수 성질

이진 트리에서 레벨 \(i\)의 최대 노드 수는 \(2^i\)이다.

높이가 `h`인 이진 트리의 최대 노드 수는 다음과 같다.

$$
1 + 2 + 2^2 + \cdots + 2^h = 2^{h+1} - 1
$$

노드가 \(n\)개 있을 때 가능한 최소 레벨 수는 대략 다음과 같다.

$$
\lceil \log_2(n+1) \rceil
$$

그리고 트리에서 간선 수는 항상 \(n - 1\)이다. 루트를 제외한 모든 노드는 부모로부터 오는 간선 하나를 갖기 때문이다.

## 2. 완전 이진 트리의 배열 표현

완전 이진 트리는 빈칸 없이 왼쪽부터 채워지므로 배열로 자연스럽게 저장할 수 있다.

0-based index를 사용할 때 관계식은 다음과 같다.

| 관계 | 공식 |
|---|---|
| 부모 | \(\operatorname{parent}(i)=\left\lfloor(i-1)/2\right\rfloor\) |
| 왼쪽 자식 | \(\operatorname{leftChild}(i)=2i+1\) |
| 오른쪽 자식 | \(\operatorname{rightChild}(i)=2i+2\) |
| 왼쪽 형제 | \(\operatorname{leftSibling}(i)=i-1\), if \(i\) is even |
| 오른쪽 형제 | \(\operatorname{rightSibling}(i)=i+1\), if \(i\) is odd |

자식 인덱스가 \(n\)보다 작을 때만 실제 자식이 존재한다.

## 3. 이진 탐색 트리 BST

BST(Binary Search Tree)는 다음 조건을 만족하는 이진 트리다.

| 조건 | 설명 |
|---|---|
| 유일한 키 | 모든 노드는 서로 다른 key를 가진다. |
| 왼쪽 서브트리 | 노드 `K`의 왼쪽 서브트리 모든 키는 `K`보다 작다. |
| 오른쪽 서브트리 | 노드 `K`의 오른쪽 서브트리 모든 키는 `K`보다 크다. |
| 재귀 조건 | 모든 서브트리도 BST다. |

BST의 강점은 비교를 통해 탐색 범위를 절반 방향으로 줄일 수 있다는 점이다.

## 4. BST ADT

강의의 BST 인터페이스는 key와 element를 분리한다.

```java
public interface BST<Key extends Comparable<Key>, E> {
    public void clear();
    public void insert(Key k, E e);
    public E remove(Key k);
    public E removeMin();
    public E removeMax();
    public E find(Key k);
    public int size();
}
```

`Key extends Comparable<Key>`는 key끼리 비교가 가능해야 한다는 뜻이다. BST는 키의 대소 비교를 통해 이동 방향을 결정하므로 비교 가능성이 필수다.

## 5. 탐색 Search

BST 탐색은 루트에서 시작해 찾는 key와 현재 노드의 key를 비교한다.

| 비교 결과 | 이동 |
|---|---|
| `k == rt.key` | 현재 노드 반환 |
| `k < rt.key` | 왼쪽 서브트리 탐색 |
| `k > rt.key` | 오른쪽 서브트리 탐색 |

```java
private E findHelper(Node rt, Key k) {
    if (rt == null) return null;
    if (rt.key.compareTo(k) == 0) return rt.element;
    else if (rt.key.compareTo(k) > 0) return findHelper(rt.left, k);
    else return findHelper(rt.right, k);
}
```

`rt == null`은 탐색 실패를 의미한다.

## 6. 삽입 Insert

삽입은 탐색과 거의 같은 길을 따라간다. 차이는 탐색이 실패한 빈 위치에 새 노드를 만든다는 점이다.

```java
private Node insertHelper(Node rt, Key k, E e) {
    if (rt == null) return new Node(k, e);

    int cmp = rt.key.compareTo(k);
    if (cmp > 0)
        rt.left = insertHelper(rt.left, k, e);
    else if (cmp < 0)
        rt.right = insertHelper(rt.right, k, e);
    else
        rt.element = e;

    return rt;
}
```

재귀 호출 후 `rt.left` 또는 `rt.right`에 반환값을 다시 대입하는 점이 중요하다. 서브트리의 루트가 바뀔 수 있으므로 부모가 그 변화를 받아야 한다.

기존 key가 이미 있으면 새 노드를 만들지 않고 element를 갱신한다. 실제 구현에서는 이 경우 `nodeCount`를 증가시키지 않도록 주의하는 편이 자연스럽다.

## 7. 시간 복잡도 해석

BST 연산의 시간은 트리 높이 `h`에 비례한다.

| 트리 상태 | 높이 | 탐색/삽입 시간 |
|---|---|---|
| 균형 잡힌 트리 | \(O(\log n)\) | \(O(\log n)\) |
| 한쪽으로 편향된 트리 | \(O(n)\) | \(O(n)\) |

BST는 구조가 균형 잡혀 있을 때 빠르다. 정렬된 데이터를 순서대로 넣으면 연결 리스트처럼 편향될 수 있고, 이 경우 장점이 사라진다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| BST 조건은? | 왼쪽은 작고 오른쪽은 크며 모든 서브트리도 BST |
| `findHelper`의 종료 조건은? | `rt == null` 또는 key 일치 |
| 삽입에서 `return rt`가 필요한 이유는? | 재귀 후 서브트리 루트를 부모에 다시 연결하기 위해 |
| BST 연산 복잡도는 무엇에 좌우되는가? | 트리 높이 |

## 복습 질문

<details>
<summary>1. 배열로 완전 이진 트리를 저장할 때 인덱스 `5`의 부모와 자식 인덱스는?</summary>

답변: 0-based index 기준으로 부모는 `(5 - 1) / 2 = 2`, 왼쪽 자식은 `2 * 5 + 1 = 11`, 오른쪽 자식은 `2 * 5 + 2 = 12`다.

</details>

<details>
<summary>2. BST에 `50, 30, 80, 10, 40`을 순서대로 넣으면 어떤 모양이 되는가?</summary>

답변: `50`이 루트가 되고, `30`은 왼쪽, `80`은 오른쪽에 들어간다. `10`은 `30`의 왼쪽, `40`은 `30`의 오른쪽이다.

```text
        50
      /    \
    30      80
   /  \
 10   40
```

</details>

<details>
<summary>3. 정렬된 입력을 BST에 그대로 넣으면 왜 위험한가?</summary>

답변: 트리가 한쪽으로 계속 기울어져 연결 리스트처럼 될 수 있기 때문이다. 이 경우 트리 높이가 \(O(\log n)\)이 아니라 \(O(n)\)이 되어 탐색, 삽입, 삭제 성능이 나빠진다.

</details>

## Study Notes

BST는 이진 트리에 정렬 규칙을 추가한 구조다. 어떤 노드 `x`에 대해 왼쪽 서브트리의 모든 key는 `x.key`보다 작고, 오른쪽 서브트리의 모든 key는 `x.key`보다 크다. 이 조건은 루트 하나에만 적용되는 것이 아니라 모든 서브트리에서 반복되어야 한다.

```text
        50
      /    \
    30      80
   /  \
 10   40
```

탐색은 루트에서 시작한다. 찾는 key가 현재 노드보다 작으면 왼쪽, 크면 오른쪽으로 간다. 이 방식은 매 단계에서 탐색 후보를 한쪽 서브트리로 줄인다.

```text
find 40
50보다 작음 -> left
30보다 큼   -> right
40 찾음
```

삽입도 탐색과 비슷하다. key가 들어갈 null 위치를 찾은 뒤 새 노드를 붙인다. 이미 같은 key가 있으면 강의 코드처럼 element를 갱신할 수 있다. 이때 새 노드가 생기지 않으므로 `nodeCount`를 증가시키면 안 된다.

재귀 구현에서 `return rt`가 중요한 이유는 부모가 자기 자식 링크를 다시 받아야 하기 때문이다.

```java
rt.left = insertHelper(rt.left, k, e);
```

이 코드는 왼쪽 서브트리에서 삽입이 일어난 뒤, 변경된 왼쪽 서브트리의 루트를 다시 연결한다. 단순히 `insertHelper(rt.left, k, e);`만 호출하면 새 노드가 부모와 연결되지 않는 상황이 생길 수 있다.

BST의 성능은 노드 수가 아니라 높이에 직접 좌우된다.

| 입력 순서 | 결과 |
|---|---|
| `50, 30, 80, 10, 40` | 비교적 균형 잡힌 트리 |
| `10, 20, 30, 40, 50` | 오른쪽으로 편향된 트리 |

편향된 BST는 사실상 연결 리스트처럼 동작한다. 그래서 탐색, 삽입이 \(O(\log n)\)이 아니라 \(O(n)\)까지 나빠질 수 있다. AVL 트리 같은 균형 트리가 필요한 이유가 여기서 나온다.

## Invariant Check

BST 문제를 풀 때는 다음 질문을 계속 확인한다.

1. 현재 노드의 왼쪽에는 더 작은 key만 있는가?
2. 현재 노드의 오른쪽에는 더 큰 key만 있는가?
3. 그 조건이 모든 서브트리에서도 성립하는가?
4. 삽입 또는 삭제 후에도 이 조건이 유지되는가?

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS10_binary_search_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS10_binary_search_tree.pdf</a></li>
</ul>
