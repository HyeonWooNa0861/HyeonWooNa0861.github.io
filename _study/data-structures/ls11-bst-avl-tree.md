---
layout: default
title: "LS11 BST and AVL Trees"
course: "Data Structures"
topic: "BST and AVL Trees"
order: 11
---

# LS11 BST and AVL Trees

Source PDF: `LS11_BST_AVL_tree.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | BST 탐색/삽입 복습 | 비교 결과로 왼쪽/오른쪽 이동을 어떻게 결정하는가? |
| 2 | BST 삭제 | 삭제 대상의 자식 수에 따라 어떻게 처리하는가? |
| 3 | BST 비용 | 왜 트리 높이가 성능을 결정하는가? |
| 4 | AVL 트리 | 스스로 균형을 유지하는 BST는 무엇인가? |
| 5 | AVL 삽입 회전 | LL, RR, LR, RL은 어떤 회전으로 해결하는가? |

## 1. BST 삭제의 세 경우

BST에서 key가 `x`인 노드를 삭제할 때는 먼저 탐색을 수행하고, 삭제 대상 노드의 자식 수에 따라 경우를 나눈다.

| 경우 | 처리 |
|---|---|
| 자식이 없음 | 단순히 부모의 링크를 `null`로 만든다. |
| 자식이 하나 | 삭제 노드를 그 자식으로 대체한다. |
| 자식이 둘 | 오른쪽 서브트리의 최소 노드, 즉 successor로 대체한다. |

세 번째 경우가 가장 중요하다. 삭제 대상보다 큰 값 중 가장 작은 값을 가져오면 BST 조건을 유지할 수 있다.

## 2. Successor와 `getMin`

오른쪽 서브트리에서 가장 작은 노드는 계속 왼쪽으로 내려가면 찾을 수 있다.

```java
private Node getMin(Node rt) {
    if (rt.left == null) return rt;
    return getMin(rt.left);
}
```

successor를 삭제할 때는 `deleteMin`을 사용한다.

```java
private Node deleteMin(Node rt) {
    if (rt.left == null) return rt.right;
    rt.left = deleteMin(rt.left);
    return rt;
}
```

`rt.left == null`인 노드가 최소값이다. 그 노드를 제거하면 오른쪽 자식이 그 자리를 대신한다.

## 3. BST 비용 분석

BST의 탐색, 삽입, 삭제는 루트에서 리프 방향으로 내려가며 수행된다. 따라서 비용은 트리 높이 `h`에 비례한다.

| 상황 | 높이 | 시간 복잡도 |
|---|---|---|
| 균형 트리 | `O(log n)` | `O(log n)` |
| 편향 트리 | `O(n)` | `O(n)` |

BST가 효율적이려면 균형이 중요하다. 이 문제를 해결하기 위해 등장하는 것이 AVL 트리다.

## 4. AVL 트리

AVL 트리는 모든 노드에서 왼쪽 서브트리와 오른쪽 서브트리의 높이 차이가 최대 1을 넘지 않도록 유지하는 self-balancing BST다.

Balance Factor는 보통 다음처럼 생각한다.

```text
BF(node) = height(left subtree) - height(right subtree)
```

AVL 조건은 모든 노드에서 Balance Factor가 `-1`, `0`, `1` 중 하나여야 한다는 뜻으로 볼 수 있다.

## 5. AVL 삽입 과정

AVL 삽입은 다음 순서로 진행된다.

1. 일반 BST 삽입을 수행한다.
2. 새 노드에서 조상 방향으로 올라가며 처음 불균형이 발생한 노드 `z`를 찾는다.
3. `z`를 루트로 하는 서브트리에 적절한 회전을 적용한다.

불균형을 찾을 때는 새로 삽입된 노드가 `z`의 어느 방향으로 들어갔는지를 본다.

## 6. AVL 삽입의 4가지 케이스

| 케이스 | 삽입 위치 | 해결 |
|---|---|---|
| LL | `z`의 왼쪽 자식의 왼쪽 서브트리 | `z`에서 Right Rotation |
| RR | `z`의 오른쪽 자식의 오른쪽 서브트리 | `z`에서 Left Rotation |
| LR | `z`의 왼쪽 자식의 오른쪽 서브트리 | 왼쪽 자식에서 Left Rotation 후 `z`에서 Right Rotation |
| RL | `z`의 오른쪽 자식의 왼쪽 서브트리 | 오른쪽 자식에서 Right Rotation 후 `z`에서 Left Rotation |

외우는 요령은 다음과 같다.

| 모양 | 회전 |
|---|---|
| 한쪽으로 직선 | 반대 방향 한 번 회전 |
| 꺾인 모양 | 먼저 꺾임을 펴고, 그다음 반대 방향 회전 |

## 7. 회전의 의미

회전은 BST의 키 순서를 깨지 않으면서 높이를 줄이는 포인터 재배치다.

Right Rotation에서 `z`의 왼쪽 자식 `y`가 위로 올라오고, `z`는 `y`의 오른쪽 자식이 된다. `y`의 기존 오른쪽 서브트리는 `z`의 왼쪽 서브트리가 된다.

Left Rotation은 이 과정을 좌우 반대로 수행한다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| BST 삭제에서 자식 둘인 노드는 어떻게 처리하는가? | 오른쪽 서브트리의 최소 노드로 대체 |
| BST 최악 시간복잡도가 `O(n)`인 이유는? | 트리가 한쪽으로 편향되면 높이가 `n`이 됨 |
| AVL 조건은? | 모든 노드의 좌우 서브트리 높이 차이가 최대 1 |
| LL/RR/LR/RL 해결 회전은? | LL: Right, RR: Left, LR: Left+Right, RL: Right+Left |

## 복습 질문

<details>
<summary>1. BST에서 루트 노드를 삭제하는데 자식이 둘이면 어떤 노드를 새 루트 후보로 쓰는가?</summary>

답변: 보통 오른쪽 서브트리의 최소 노드, 즉 inorder successor를 새 루트 후보로 쓴다. 또는 왼쪽 서브트리의 최대 노드인 inorder predecessor를 사용할 수도 있다.

</details>

<details>
<summary>2. AVL 삽입에서 처음 불균형이 발생한 노드를 왜 찾는가?</summary>

답변: 삽입으로 인해 균형이 깨진 가장 낮은 조상 노드를 기준으로 회전하면, 그 서브트리의 높이와 균형을 복구할 수 있기 때문이다. 삽입의 경우 보통 처음 불균형 노드에서 회전하면 위쪽 균형도 함께 해결된다.

</details>

<details>
<summary>3. LR과 RL은 왜 회전이 두 번 필요한가?</summary>

답변: LR과 RL은 트리가 한 방향으로 곧게 기울어진 것이 아니라 중간에서 꺾인 모양이다. 먼저 자식 쪽에서 회전해 직선 형태로 펴고, 그 다음 불균형 노드에서 반대 방향 회전을 해야 균형이 맞는다.

</details>

## Study Notes

이 강의는 BST의 삭제와 AVL 트리의 필요성을 연결한다. BST는 균형만 잘 잡히면 빠르지만, 삽입 순서가 나쁘면 높이가 `n`까지 커진다. AVL 트리는 이 문제를 해결하기 위해 삽입과 삭제 후 균형을 복구한다.

BST 삭제는 삭제할 노드의 자식 수에 따라 나뉜다.

| 삭제 대상 | 처리 |
|---|---|
| leaf node | 그냥 제거한다. |
| child가 1개 | 자식을 삭제 대상 위치로 올린다. |
| child가 2개 | 오른쪽 서브트리의 최소 노드 또는 왼쪽 서브트리의 최대 노드로 대체한다. |

자식이 둘인 경우 바로 노드를 지우면 BST 구조가 깨지기 쉽다. 그래서 현재 노드보다 크면서 가장 작은 값, 즉 inorder successor를 가져오는 방식이 자연스럽다.

AVL 트리는 모든 노드에서 다음 조건을 유지한다.

```text
abs(height(left) - height(right)) <= 1
```

Balance Factor는 보통 다음처럼 정의한다.

```text
BF = height(left) - height(right)
```

AVL 조건에서는 BF가 `-1`, `0`, `1` 중 하나여야 한다.

삽입 후 불균형이 생기면 새 노드에서 루트 방향으로 올라가며 처음으로 조건이 깨진 노드 `z`를 찾는다. `z`의 어느 쪽 자식 `y`로 내려갔는지, 다시 `y`의 어느 쪽 자식 `x`로 내려갔는지를 보면 LL, RR, LR, RL을 판별할 수 있다.

```text
z -> y -> x
```

| 경로 | 케이스 | 회전 |
|---|---|---|
| left -> left | LL | Right Rotation |
| right -> right | RR | Left Rotation |
| left -> right | LR | Left Rotation, Right Rotation |
| right -> left | RL | Right Rotation, Left Rotation |

## Rotation Intuition

회전은 정렬 순서를 바꾸는 작업이 아니다. BST의 inorder 결과는 그대로 유지하면서 높이를 줄이는 포인터 재배치다. 그래서 회전 전후에 중위 순회를 해 보면 key 순서는 같다.

```text
LL case

    z              y
   /              / \
  y      ->      x   z
 /
x
```

직선으로 기울어진 경우는 한 번의 반대 방향 회전으로 충분하다. 꺾인 모양은 먼저 직선에 가깝게 펴고, 그 다음 반대 방향 회전을 해야 한다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS11_BST_AVL_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS11_BST_AVL_tree.pdf</a></li>
</ul>
