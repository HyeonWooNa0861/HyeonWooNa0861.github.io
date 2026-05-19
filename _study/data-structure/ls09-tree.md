---
layout: default
title: "LS09 Trees"
course: "Data Structures"
topic: "Trees"
order: 9
---

# LS09 Trees

Source PDF: `LS09_tree.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 트리 정의 | 계층적 데이터를 어떻게 표현하는가? |
| 2 | 트리 용어 | 루트, 내부 노드, 리프, 조상, 자손은 무엇인가? |
| 3 | 이진 트리 | 자식이 최대 두 개인 트리는 어떤 특징이 있는가? |
| 4 | 이진 트리 종류 | full, complete, perfect는 어떻게 다른가? |
| 5 | 트리 순회 | 전위, 후위, 중위 순회는 어떤 순서로 방문하는가? |

## 1. 트리란?

트리는 데이터를 계층적 구조로 저장하는 자료구조다. 조직도나 파일 시스템처럼 부모-자식 관계가 자연스러운 데이터를 표현하기 좋다.

```text
Company
├── Sales
│   ├── US
│   └── International
├── Manufacturing
└── R&D
```

트리는 선형 구조와 달리 한 원소가 여러 하위 원소를 가질 수 있다.

## 2. 기본 용어

| 용어 | 의미 |
|---|---|
| 노드 Node | 데이터가 저장되는 기본 단위 |
| 간선 Edge | 두 노드를 연결하는 관계 |
| 루트 Root | 부모가 없는 최상위 노드 |
| 내부 노드 Internal node | 하나 이상의 자식을 가진 노드 |
| 외부 노드 / 리프 Leaf | 자식이 없는 노드 |
| 조상 Ancestor | 어떤 노드에서 루트로 가는 경로 위의 노드들 |
| 자손 Descendant | 어떤 노드 아래에 이어지는 모든 하위 노드 |

용어 문제는 그림을 보고 직접 표시해보는 연습이 중요하다.

## 3. 메모리에서의 트리 표현

트리 노드는 보통 다음 정보를 가진 객체로 표현한다.

| 정보 | 설명 |
|---|---|
| 데이터 원소 | 노드가 저장하는 값 |
| 부모 링크 | 부모 노드 주소 |
| 자식 집합 | 자식 노드들의 주소 |

일반 트리는 자식 수가 일정하지 않을 수 있으므로 자식들을 리스트로 저장하는 경우가 많다.

## 4. 이진 트리

이진 트리는 각 노드가 최대 두 개의 자식을 갖는 트리다. 두 자식은 보통 왼쪽 자식과 오른쪽 자식으로 구분된다.

이진 트리는 산술 표현식, 의사결정 트리, 이진 탐색 트리, 힙 등 많은 자료구조의 기반이 된다.

## 5. 이진 트리의 예시

### 산술 표현식 트리

산술 표현식 트리에서는 내부 노드가 연산자, 외부 노드가 피연산자다.

```text
(2 * (a - 1)) + (3 * b)
```

위 식은 루트가 `+`이고, 그 아래에 두 곱셈 서브트리가 있는 형태로 표현할 수 있다.

### 이진 결정 트리

이진 결정 트리는 각 내부 노드가 Yes/No 질문이고, 리프 노드가 최종 결정이다.

## 6. 이진 트리 종류

| 종류 | 조건 |
|---|---|
| 정 이진 트리 Full Binary Tree | 모든 노드의 자식 수가 0 또는 2 |
| 완전 이진 트리 Complete Binary Tree | 마지막 레벨을 제외한 모든 레벨이 차 있고, 마지막 레벨은 왼쪽부터 채워짐 |
| 포화 이진 트리 Perfect Binary Tree | 모든 리프의 레벨이 같고 모든 내부 노드가 자식 2개를 가짐 |

헷갈리기 쉬운 부분은 complete와 perfect다. complete는 마지막 레벨이 덜 차도 되지만 왼쪽부터 채워져야 한다. perfect는 모든 레벨이 꽉 차야 한다.

## 7. 트리 순회

트리 순회는 모든 노드를 정해진 규칙에 따라 정확히 한 번씩 방문하는 과정이다.

| 순회 | 방문 순서 | 활용 |
|---|---|---|
| 전위 Pre-order | 노드 -> 왼쪽 -> 오른쪽 | 계층 구조 출력, prefix 표기 |
| 후위 Post-order | 왼쪽 -> 오른쪽 -> 노드 | 디렉터리 용량 계산, postfix 표기 |
| 중위 In-order | 왼쪽 -> 노드 -> 오른쪽 | BST에서 정렬된 키 얻기 |

## 8. 순회 의사코드

```text
preorder(v):
    visit(v)
    preorder(left(v))
    preorder(right(v))
```

```text
postorder(v):
    postorder(left(v))
    postorder(right(v))
    visit(v)
```

```text
inorder(v):
    inorder(left(v))
    visit(v)
    inorder(right(v))
```

실제 코드에서는 자식이 존재하는지 확인하는 조건이 함께 필요하다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 트리는 어떤 데이터에 적합한가? | 계층 관계가 있는 데이터 |
| full, complete, perfect의 차이는? | 자식 수 조건, 마지막 레벨 조건, 모든 레벨 포화 조건 |
| 중위 순회가 BST에서 중요한 이유는? | 키가 정렬된 순서로 나온다. |
| 후위 순회가 디렉터리 용량 계산에 맞는 이유는? | 자식 용량을 먼저 계산한 뒤 부모를 계산해야 한다. |

## 복습 질문

<details>
<summary>1. 어떤 노드의 조상에는 부모 노드가 포함되는가?</summary>

답변: 포함된다. 조상은 부모, 부모의 부모, 그 위의 모든 노드를 뜻한다. 따라서 어떤 노드의 바로 위 부모 노드는 가장 가까운 조상이다.

</details>

<details>
<summary>2. complete binary tree이지만 perfect binary tree가 아닌 예를 직접 그려보자.</summary>

답변: 마지막 레벨이 왼쪽부터 채워졌지만 전체가 꽉 차지는 않은 트리면 된다.

```text
    A
   / \
  B   C
 /
D
```

이 트리는 마지막 레벨이 왼쪽부터 채워져 complete binary tree지만, 모든 레벨이 꽉 차 있지는 않으므로 perfect binary tree는 아니다.

</details>

<details>
<summary>3. 다음 방문 순서를 외워보자: preorder, postorder, inorder.</summary>

답변: preorder는 Root - Left - Right, postorder는 Left - Right - Root, inorder는 Left - Root - Right다. 루트 방문이 앞이면 preorder, 가운데면 inorder, 뒤면 postorder로 기억하면 된다.

</details>

## Study Notes

트리는 선형 자료구조와 다르게 계층 관계를 표현한다. 배열, 리스트, 스택, 큐는 원소가 한 줄로 이어지는 구조지만, 트리는 부모와 자식 관계를 가진다.

```text
        A
      /   \
     B     C
    / \     \
   D   E     F
```

이 예에서 `A`는 루트, `D`, `E`, `F`는 리프다. `B`의 자식은 `D`, `E`이고, `D`의 조상은 `B`, `A`다.

트리 용어는 서로 연결해서 외우는 것이 좋다.

| 용어 | 의미 |
|---|---|
| root | 부모가 없는 최상위 노드 |
| parent | 어떤 노드 바로 위의 노드 |
| child | 어떤 노드 바로 아래의 노드 |
| sibling | 같은 부모를 가진 노드 |
| ancestor | 부모, 부모의 부모처럼 위쪽에 있는 노드 |
| descendant | 자식, 자식의 자식처럼 아래쪽에 있는 노드 |
| leaf | 자식이 없는 노드 |
| subtree | 어떤 노드를 루트로 보는 부분 트리 |

이진 트리의 종류도 자주 헷갈린다.

| 종류 | 핵심 조건 |
|---|---|
| full binary tree | 모든 노드의 자식 수가 0 또는 2 |
| complete binary tree | 마지막 레벨을 제외하고 꽉 차며, 마지막 레벨은 왼쪽부터 채워짐 |
| perfect binary tree | 모든 내부 노드가 자식 2개를 갖고 모든 리프가 같은 깊이 |

순회는 방문 순서를 외우면 된다. 기준은 항상 루트다.

| 순회 | 순서 | 자주 쓰는 상황 |
|---|---|---|
| preorder | Root - Left - Right | 트리 복사, 구조 먼저 출력 |
| inorder | Left - Root - Right | BST에서 정렬된 순서 출력 |
| postorder | Left - Right - Root | 하위 결과를 먼저 계산해야 하는 경우 |

## Traversal Example

위 그림에서 순회 결과는 다음과 같다.

| 순회 | 결과 |
|---|---|
| preorder | `A B D E C F` |
| inorder | `D B E A C F` |
| postorder | `D E B F C A` |

중위 순회는 일반 이진 트리에서는 단순한 방문 순서일 뿐이다. 하지만 BST에서는 왼쪽이 작고 오른쪽이 크다는 조건 때문에 정렬된 출력이 된다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structure/LS09_tree.pdf" | relative_url }}" target="_blank" rel="noopener">LS09_tree.pdf</a></li>
</ul>
