---
layout: default
date: 2026-05-19 12:11:10 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "LS11 BST and AVL Trees"
course: "Data Structures"
topic: "BST and AVL Trees"
order: 11
major_topic: "Data Structures & Algorithms"
keywords:
  - "BST"
  - "AVL Trees"
  - "Rotations"
  - "Balance Factor"
  - "Height Balance"
---

# LS11 BST and AVL Trees

Source PDF: `LS11_BST_AVL_tree.pdf`

> **핵심:** BST에서 자식이 둘인 노드를 삭제할 때는 오른쪽 서브트리의 최소 노드로 대체할 수 있습니다. 트리가 한쪽으로 편향되면 높이가 $$n$$까지 커지므로 탐색·삽입·삭제의 최악 시간복잡도는 $$O(n)$$입니다.

## 원본 그림으로 읽기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/data-structures/LS11_BST_AVL_tree.pdf#page=13" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/data-structures/source-figures/ls11-p13-bst-delete.jpg" | relative_url }}" alt="BST에서 리프 노드 28을 삭제하기 전후를 보여 주는 강의 슬라이드" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 13. 자식이 없는 리프 삭제는 부모의 해당 포인터를 null로 바꾸면 끝납니다.</figcaption>
</figure>

빨간 원의 28은 자식이 없으므로 구조를 이어 줄 노드가 없습니다. 부모 30의 왼쪽 포인터만 끊으면 중위 순서와 BST 조건이 유지됩니다. 한 자식·두 자식 삭제는 이 단순 사례와 달리 서브트리 연결이나 successor 교체가 필요합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | BST 탐색/삽입 복습 | 비교 결과로 왼쪽/오른쪽 이동을 어떻게 결정합니까? |
| 2 | BST 삭제 | 삭제 대상의 자식 수에 따라 어떻게 처리합니까? |
| 3 | BST 비용 | 왜 트리 높이가 성능을 결정합니까? |
| 4 | AVL 트리 | 스스로 균형을 유지하는 BST는 무엇입니까? |
| 5 | AVL 삽입 회전 | LL, RR, LR, RL은 어떤 회전으로 해결합니까? |

</details>

## 1. BST 삭제의 세 경우

BST에서 key가 `x`인 노드를 삭제할 때는 먼저 탐색을 수행하고, 삭제 대상 노드의 자식 수에 따라 경우를 나눕니다.

| 경우 | 처리 |
|---|---|
| 자식이 없음 | 단순히 부모의 링크를 `null`로 만듭니다. |
| 자식이 하나 | 삭제 노드를 그 자식으로 대체합니다. |
| 자식이 둘 | 오른쪽 서브트리의 최소 노드, 즉 successor로 대체합니다. |

세 번째 경우가 가장 중요합니다. 삭제 대상보다 큰 값 중 가장 작은 값을 가져오면 BST 조건을 유지할 수 있습니다.

## 2. Successor와 `getMin`

오른쪽 서브트리에서 가장 작은 노드는 계속 왼쪽으로 내려가면 찾을 수 있습니다.

```java
private Node getMin(Node rt) {
    if (rt.left == null) return rt;
    return getMin(rt.left);
}
```

successor를 삭제할 때는 `deleteMin`을 사용합니다.

```java
private Node deleteMin(Node rt) {
    if (rt.left == null) return rt.right;
    rt.left = deleteMin(rt.left);
    return rt;
}
```

`rt.left == null`인 노드가 최소값입니다. 그 노드를 제거하면 오른쪽 자식이 그 자리를 대신합니다.

예를 들어 key 20인 노드의 왼쪽 서브트리에 10, 오른쪽 서브트리에 30과 그 왼쪽 자식 25가 있다고 하겠습니다. 20을 지우면서 30을 바로 올리면 25를 어디에 둘지 다시 처리해야 합니다. 대신 오른쪽 서브트리의 최소값 25를 20의 자리에 복사한 뒤, 원래 위치의 25만 `deleteMin`으로 제거합니다. 25는 왼쪽의 모든 key보다 크고 오른쪽의 나머지 key보다 작으므로 두 서브트리 사이의 경계를 그대로 지킵니다.

## 3. BST 비용 분석

BST의 탐색, 삽입, 삭제는 루트에서 리프 방향으로 내려가며 수행됩니다. 따라서 비용은 트리 높이 `h`에 비례합니다.

| 상황 | 높이 | 시간 복잡도 |
|---|---|---|
| 균형 트리 | $$O(\log n)$$ | $$O(\log n)$$ |
| 편향 트리 | $$O(n)$$ | $$O(n)$$ |

BST가 효율적이려면 균형이 중요합니다. 이 문제를 해결하기 위해 등장하는 것이 AVL 트리입니다.

## 4. AVL 트리

AVL 트리는 모든 노드에서 왼쪽 서브트리와 오른쪽 서브트리의 높이 차이가 최대 1을 넘지 않도록 유지하는 self-balancing BST입니다.

높이는 그 노드에서 가장 먼 leaf까지 내려가는 거리입니다. 예를 들어 왼쪽 높이가 3이고 오른쪽 높이가 1이면 차이가 2이므로 AVL 조건이 깨집니다. 회전은 key의 정렬 순서를 바꾸지 않은 채 이 긴 쪽의 높이를 낮추는 작업입니다.

Balance Factor는 보통 다음처럼 생각합니다.

$$
\operatorname{BF}(\mathrm{node})
= \operatorname{height}(\mathrm{left})
- \operatorname{height}(\mathrm{right})
$$

AVL 조건은 모든 노드에서 Balance Factor가 `-1`, `0`, `1` 중 하나여야 한다는 뜻으로 볼 수 있습니다.

부호는 어느 쪽이 더 높은지를 알려 줍니다. 위 정의에서는 양수면 왼쪽이, 음수면 오른쪽이 더 높습니다. 절댓값이 2가 되는 순간 회전이 필요합니다.

## 5. AVL 삽입 과정

AVL 삽입은 다음 순서로 진행됩니다.

1. 일반 BST 삽입을 수행합니다.
2. 새 노드에서 조상 방향으로 올라가며 처음 불균형이 발생한 노드 `z`를 찾습니다.
3. `z`를 루트로 하는 서브트리에 적절한 회전을 적용합니다.

불균형을 찾을 때는 새로 삽입된 노드가 `z`의 어느 방향으로 들어갔는지를 봅니다.

## 6. AVL 삽입의 4가지 케이스

| 케이스 | 삽입 위치 | 해결 |
|---|---|---|
| LL | `z`의 왼쪽 자식의 왼쪽 서브트리 | `z`에서 Right Rotation |
| RR | `z`의 오른쪽 자식의 오른쪽 서브트리 | `z`에서 Left Rotation |
| LR | `z`의 왼쪽 자식의 오른쪽 서브트리 | 왼쪽 자식에서 Left Rotation 후 `z`에서 Right Rotation |
| RL | `z`의 오른쪽 자식의 왼쪽 서브트리 | 오른쪽 자식에서 Right Rotation 후 `z`에서 Left Rotation |

외우는 요령은 다음과 같습니다.

| 모양 | 회전 |
|---|---|
| 한쪽으로 직선 | 반대 방향 한 번 회전 |
| 꺾인 모양 | 먼저 꺾임을 펴고, 그다음 반대 방향 회전 |

## 7. 회전의 의미

회전은 BST의 키 순서를 깨지 않으면서 높이를 줄이는 포인터 재배치입니다.

Right Rotation에서 `z`의 왼쪽 자식 `y`가 위로 올라오고, `z`는 `y`의 오른쪽 자식이 됩니다. `y`의 기존 오른쪽 서브트리는 `z`의 왼쪽 서브트리가 됩니다.

Left Rotation은 이 과정을 좌우 반대로 수행합니다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| BST 삭제에서 자식 둘인 노드는 어떻게 처리합니까? | 오른쪽 서브트리의 최소 노드로 대체 |
| BST 최악 시간복잡도가 $$O(n)$$인 이유는 무엇입니까? | 트리가 한쪽으로 편향되면 높이가 `n`이 됨 |
| AVL 조건은 무엇입니까? | 모든 노드의 좌우 서브트리 높이 차이가 최대 1 |
| LL/RR/LR/RL 해결 회전은 무엇입니까? | LL: Right, RR: Left, LR: Left+Right, RL: Right+Left |

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

BST 삭제는 leaf, 자식 하나, 자식 둘의 세 경우를 먼저 연습하고, 자식 둘이면 오른쪽 서브트리의 최소 노드로 대체하는 과정을 재현합니다. 그다음 삽입 경로를 따라 LL·RR·LR·RL을 판정해 단일 회전과 이중 회전 순서를 그림으로 확인합니다. BST ordering과 AVL balance condition은 별도 불변식이므로 삭제 대체가 끝난 뒤에도 높이와 balance factor를 다시 계산합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. BST에서 루트 노드를 삭제하는데 자식이 둘이면 어떤 노드를 새 루트 후보로 씁니까?</summary>

답변: 보통 오른쪽 서브트리의 최소 노드, 즉 inorder successor를 새 루트 후보로 씁니다. 또는 왼쪽 서브트리의 최대 노드인 inorder predecessor를 사용할 수도 있습니다.

</details>

<details markdown="block">
<summary>2. AVL 삽입에서 처음 불균형이 발생한 노드를 왜 찾습니까?</summary>

답변: 삽입으로 인해 균형이 깨진 가장 낮은 조상 노드를 기준으로 회전하면, 그 서브트리의 높이와 균형을 복구할 수 있기 때문입니다. 삽입의 경우 보통 처음 불균형 노드에서 회전하면 위쪽 균형도 함께 해결됩니다.

</details>

<details markdown="block">
<summary>3. LR과 RL은 왜 회전이 두 번 필요합니까?</summary>

답변: LR과 RL은 트리가 한 방향으로 곧게 기울어진 것이 아니라 중간에서 꺾인 모양입니다. 먼저 자식 쪽에서 회전해 직선 형태로 펴고, 그 다음 불균형 노드에서 반대 방향 회전을 해야 균형이 맞습니다.

</details>

## Study Notes

이 강의는 BST의 삭제와 AVL 트리의 필요성을 연결합니다. BST는 균형만 잘 잡히면 빠르지만, 삽입 순서가 나쁘면 높이가 `n`까지 커집니다. AVL 트리는 이 문제를 해결하기 위해 삽입과 삭제 후 균형을 복구합니다.

BST 삭제는 삭제할 노드의 자식 수에 따라 나뉩니다.

| 삭제 대상 | 처리 |
|---|---|
| leaf node | 그냥 제거합니다. |
| child가 1개 | 자식을 삭제 대상 위치로 올립니다. |
| child가 2개 | 오른쪽 서브트리의 최소 노드 또는 왼쪽 서브트리의 최대 노드로 대체합니다. |

자식이 둘인 경우 바로 노드를 지우면 BST 구조가 깨지기 쉽습니다. 그래서 현재 노드보다 크면서 가장 작은 값, 즉 inorder successor를 가져오는 방식이 자연스럽습니다.

AVL 트리는 모든 노드에서 다음 조건을 유지합니다.

$$
\left|\operatorname{height}(\mathrm{left})-\operatorname{height}(\mathrm{right})\right| \le 1
$$

Balance Factor는 보통 다음처럼 정의합니다.

$$
\operatorname{BF}
= \operatorname{height}(\mathrm{left})
- \operatorname{height}(\mathrm{right})
$$

AVL 조건에서는 BF가 `-1`, `0`, `1` 중 하나여야 합니다.

삽입 후 불균형이 생기면 새 노드에서 루트 방향으로 올라가며 처음으로 조건이 깨진 노드 `z`를 찾습니다. `z`의 어느 쪽 자식 `y`로 내려갔는지, 다시 `y`의 어느 쪽 자식 `x`로 내려갔는지를 보면 LL, RR, LR, RL을 판별할 수 있습니다.

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

회전은 정렬 순서를 바꾸는 작업이 아닙니다. BST의 inorder 결과는 그대로 유지하면서 높이를 줄이는 포인터 재배치입니다. 그래서 회전 전후에 중위 순회를 해 보면 key 순서는 같습니다.

```text
LL case

    z              y
   /              / \
  y      ->      x   z
 /
x
```

직선으로 기울어진 경우는 한 번의 반대 방향 회전으로 충분합니다. 꺾인 모양은 먼저 직선에 가깝게 펴고, 그 다음 반대 방향 회전을 해야 합니다.

## AVL 높이가 $$O(\log n)$$인 증명 개요

AVL 트리는 양쪽 subtree 높이 차이를 1 이하로 제한합니다. 이 조건 때문에 높이 $$h$$를 만들려면 필요한 최소 노드 수가 Fibonacci처럼 증가하고, 결과적으로 높이는 노드 수의 로그를 넘지 않습니다. 회전은 inorder 순서를 보존하면서 이 높이 조건만 복구합니다.

<details markdown="block">
<summary markdown="span">Proof: logarithmic AVL height and rotation order</summary>

> **분류:** AVL 균형 조건에서 따르는 **정리**입니다. 빈 트리 높이를 $$-1$$, 리프 높이를 0으로 두고, $$N(h)$$를 높이 $$h$$인 AVL 트리의 최소 노드 수라 하겠습니다.

> **원문 추적:** `LS11_BST_AVL_tree.pdf` p.19는 BST 비용이 높이에 좌우됨을, pp.21–48은 AVL 균형 조건과 네 회전 유형을 제시합니다. 최소 노드 점화식과 $$O(\log n)$$ 증명은 원문 결론을 엄밀화한 작성자 보충입니다.

노드 수를 최소화하려면 두 서브트리 높이는 균형 조건이 허용하는 가장 큰 차이인 $$h-1$$, $$h-2$$여야 합니다. 따라서

$$
N(h)=1+N(h-1)+N(h-2),
\qquad N(-1)=0,\quad N(0)=1.
$$

이 점화식은 피보나치 수열보다 1만큼 이동한 형태여서 $$N(h)$$는 $$\varphi^h$$에 비례해 증가합니다. 즉 어떤 양의 상수 $$c$$에 대해 $$N(h)\ge c\varphi^h$$이고,

$$
n\ge N(h)\ge c\varphi^h
\quad\Longrightarrow\quad
h\le \log_{\varphi}(n/c)=O(\log n).
$$

탐색·삽입·삭제는 루트에서 한 경로만 내려가므로 $$O(h)=O(\log n)$$입니다. 이 보장은 모든 노드에서 $$\lvert\mathrm{BF}\rvert\le1$$을 유지할 때만 성립합니다. 높이 갱신이나 회전을 빠뜨리면 트리가 편향되어 $$O(n)$$까지 나빠질 수 있습니다.

### 회전이 BST 순서를 보존하는 이유

LL 회전 전 key 구간을 $$A<y<B<z<C$$로 쓰면, 회전 전 inorder는 $$A,y,B,z,C$$입니다. `y`를 위로 올리고 `B`를 `z`의 왼쪽으로 옮긴 뒤에도 inorder는 $$A,y,B,z,C$$로 같습니다. 회전은 부모 관계만 바꾸며 key의 전체 순서를 바꾸지 않으므로 BST 불변식이 보존됩니다. LR/RL도 첫 회전으로 꺾인 구조를 직선 구조로 바꾼 뒤 같은 논리를 두 번 적용합니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS11_BST_AVL_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS11_BST_AVL_tree.pdf</a></li>
</ul>
