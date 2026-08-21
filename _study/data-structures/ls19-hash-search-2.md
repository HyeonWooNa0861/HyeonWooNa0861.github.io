---
layout: default
date: 2026-05-20 12:13:13 +0900
title: "LS19 Hash Search 2"
course: "Data Structures"
topic: "Hash Search 2"
order: 19
major_topic: "Data Structures & Algorithms"
keywords:
  - "Hash Tables"
  - "Probing"
  - "Linear Probing"
  - "Quadratic Probing"
  - "Double Hashing"
---

# LS19 Hash Search 2

Source PDF: `LS19_hash_search_2.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 해싱 복습 | key를 table index로 매핑하는 구조는 무엇인가? |
| 2 | 충돌 해결 | 같은 슬롯으로 모인 key를 어떻게 처리하는가? |
| 3 | Open Hashing | 슬롯 밖의 연결 리스트를 이용하면 무엇이 좋아지는가? |
| 4 | Closed Hashing | 테이블 내부에서 빈 슬롯을 찾는 방식은 무엇인가? |
| 5 | Bucket Hashing | 슬롯을 버킷 단위로 묶으면 어떤 한계가 생기는가? |
| 6 | Linear Probing | 순차적으로 빈 칸을 찾으면 왜 clustering이 생기는가? |
| 7 | 개선된 probing | pseudo-random, quadratic, double hashing은 무엇을 줄이는가? |
| 8 | Load Factor | 적재율이 closed hashing 성능을 어떻게 바꾸는가? |

## 1. 해싱과 충돌 복습

해싱은 해시 함수 \\(h(k)\\)를 사용해 key \\(k\\)를 해시 테이블의 특정 슬롯으로 매핑하는 방식이다.

$$
k \to h(k) \to HT[h(k)]
$$

해시 테이블 `HT`는 크기 \\(m\\)의 배열이고, 해시 함수는 key를 \\(0\\)부터 \\(m - 1\\) 사이의 인덱스로 변환한다.

충돌 collision은 서로 다른 key가 같은 해시값을 갖는 상황이다.

$$
h(k_1) = h(k_2),\qquad k_1 \ne k_2
$$

충돌이 발생하면 한 슬롯에 여러 아이템이 몰리므로 탐색, 삽입, 삭제에 추가 작업이 필요하다. 따라서 좋은 해시 함수뿐 아니라 충돌을 처리하는 collision resolution 전략이 필수다.

## 2. 충돌 해결 방식의 큰 분류

충돌 해결은 크게 두 방식으로 나뉜다.

| 방식 | 다른 이름 | 핵심 아이디어 |
|---|---|---|
| Open Hashing | Separate Chaining | 슬롯마다 외부 연결 리스트를 둔다. |
| Closed Hashing | Open Addressing | 모든 아이템을 테이블 내부 슬롯에 저장한다. |

이름이 헷갈리기 쉽다. `Open Hashing`은 저장 공간이 테이블 밖으로 열려 있고, `Open Addressing`은 주소 탐색이 열려 있지만 분류상 `Closed Hashing`에 해당한다.

## 3. Open Hashing: Separate Chaining

Open Hashing은 해시 테이블의 각 슬롯에 연결 리스트를 붙이는 방식이다.

```text
HT[0] -> (key, value) -> (key, value)
HT[1] -> null
HT[2] -> (key, value)
```

삽입 시 충돌이 발생하면 해당 슬롯의 리스트에 새 노드를 추가한다.

| 장점 | 설명 |
|---|---|
| 테이블 크기에 덜 민감 | 슬롯 밖의 리스트가 계속 확장될 수 있다. |
| 삭제가 쉬움 | 리스트 노드만 제거하면 된다. |
| 구현 직관적 | 연결 리스트 삽입/삭제로 충돌을 처리한다. |

| 단점 | 설명 |
|---|---|
| 추가 메모리 필요 | 리스트 노드와 포인터 저장 공간이 필요하다. |
| 캐시 효율 낮음 | 노드가 메모리에 흩어질 수 있다. |
| 특정 슬롯 집중 시 느려짐 | 한 체인이 길어지면 그 슬롯 탐색은 \\(O(\text{length of chain})\\)이 된다. |

## 4. Closed Hashing: Open Addressing

Closed Hashing은 모든 아이템을 해시 테이블 내부에만 저장한다.

충돌이 나면 다른 빈 슬롯을 탐색한다. 이 과정을 probing이라고 한다.

```text
initial slot = h(k)
if occupied -> probe next candidate slot
```

| 장점 | 설명 |
|---|---|
| 추가 외부 구조 없음 | 메모리 사용이 상대적으로 효율적이다. |
| 캐시 친화적 | 배열 내부를 탐색하므로 연속 메모리 접근이 많다. |

| 단점 | 설명 |
|---|---|
| load factor에 민감 | 테이블이 찰수록 빈 슬롯을 찾기 어려워진다. |
| 삭제가 복잡 | 그냥 비우면 탐색 경로가 끊길 수 있어 별도 마킹이 필요하다. |
| 테이블이 가득 차면 삽입 불가 | 외부 리스트처럼 무한 확장되지 않는다. |

삭제 시에는 tombstone처럼 "삭제된 자리"를 표시해야 한다. 완전히 빈 슬롯처럼 처리하면 그 뒤에 probe되어 들어간 원소를 탐색하지 못할 수 있다.

## 5. Open Hashing vs Closed Hashing

| 비교 | Open Hashing | Closed Hashing |
|---|---|---|
| 저장 위치 | 해시 테이블 + 외부 리스트 | 해시 테이블 내부 |
| 대표 기법 | Linked list chaining | Bucket hashing, linear probing |
| load factor 영향 | 비교적 안정적 | 높아질수록 급격히 악화 |
| 삭제 | 쉬움 | tombstone 등 별도 처리 필요 |
| 메모리 | 포인터/노드 추가 | 외부 구조가 적음 |
| 캐시 효율 | 낮을 수 있음 | 높은 편 |

## 6. Bucket Hashing

Bucket Hashing은 해시 테이블의 \\(m\\)개 슬롯을 \\(b\\)개 버킷으로 나눈다.

$$
\text{bucket size} = \frac{m}{b}
$$

기본 방식에서는 해시 함수가 버킷 번호를 결정한다.

$$
h(k) = k \bmod b
$$

아이템은 해당 버킷의 첫 번째 빈 슬롯에 들어간다. 버킷이 가득 차면 overflow bucket을 사용한다.

| 구성 | 의미 |
|---|---|
| `m` | 전체 슬롯 수 |
| `b` | 버킷 수 |
| `m / b` | 버킷 하나의 슬롯 수 |
| overflow bucket | 버킷이 꽉 찼을 때 쓰는 추가 공간 |

## 7. Bucket Hashing 변형

변형 방식에서는 해시 함수가 버킷 번호가 아니라 슬롯을 직접 지정한다.

```text
h(k) = k mod m
```

단, 실제 저장은 그 슬롯이 속한 버킷 안에서 처리한다.

1. \\(h(k)\\) 슬롯이 비어 있으면 바로 삽입한다.
2. 차 있으면 같은 버킷 안의 다른 빈 슬롯을 찾는다.
3. 버킷 전체가 차 있으면 overflow bucket에 넣는다.

이 방식은 기본 bucket hashing보다 분포가 고르게 될 수 있다.

## 8. Bucket Hashing의 한계

버킷 단위 저장은 공간 활용도가 낮아질 수 있다.

전체 테이블에는 빈 공간이 남아 있어도, 특정 key가 속한 버킷이 가득 차면 overflow bucket을 사용해야 한다. 즉, 테이블 전체 관점에서는 여유가 있는데 버킷 관점에서는 꽉 찬 상태가 될 수 있다.

## 9. Linear Probing

Linear Probing은 버킷 없이 closed hashing을 수행하는 방식이다. 충돌이 발생하면 다음 슬롯을 차례대로 검사한다.

$$
h_i(k) = (h(k)+i)\bmod m,\qquad i=0,1,2,3,\ldots
$$

첫 번째 위치가 차 있으면 \\(h(k)+1\\), 그다음은 \\(h(k)+2\\), 이런 식으로 빈 슬롯을 찾는다.

| 장점 | 설명 |
|---|---|
| 구현 단순 | 한 칸씩 이동하면 된다. |
| 캐시 효율 좋음 | 인접 슬롯을 연속적으로 확인한다. |

| 단점 | 설명 |
|---|---|
| primary clustering | 채워진 슬롯들이 덩어리로 뭉친다. |
| 성능 악화 | 클러스터가 길어질수록 탐색 횟수가 증가한다. |

## 10. Primary Clustering

Primary clustering은 채워진 슬롯들이 연속 구간으로 뭉치는 현상이다.

linear probing에서는 어떤 key가 클러스터 안의 아무 위치로 해싱되어도 결국 클러스터 뒤의 첫 번째 빈 슬롯으로 밀려난다. 그러면 그 빈 슬롯이 채워지고 클러스터는 더 길어진다.

결과적으로 새 key가 특정 빈 슬롯에 배치될 확률이 균등하지 않게 된다. 강의 예시처럼 어떤 슬롯은 여러 해시값의 최종 목적지가 되어 선택 확률이 커질 수 있다.

## 11. Improved Linear Probing

### 상수 간격 probing

한 칸씩이 아니라 \\(c\\)칸씩 건너뛰는 방식이다.

$$
h_i(k) = (h(k)+ic)\bmod m
$$

단, \\(c\\)와 \\(m\\)은 서로소여야 한다. 서로소가 아니면 특정 슬롯들만 반복 방문하고 나머지 슬롯은 영원히 방문하지 못할 수 있다.

예를 들어 \\(m = 6\\), \\(c = 2\\)라면 \\(0 \to 2 \to 4 \to 0\\)만 반복된다.

### Pseudo-random probing

미리 섞어 둔 순열 \\(\mathrm{Perm}\\)을 이용해 임의 순서로 슬롯을 탐색한다.

$$
h_i(k) = (h(k)+\mathrm{Perm}[i])\bmod m
$$

primary clustering은 완화되지만, 메모리 접근이 흩어져 캐시 효율은 낮아질 수 있다.

### Quadratic probing

probe 간격을 점점 크게 만드는 방식이다.

$$
h_i(k) = (h(k)+i^2)\bmod m
$$

primary clustering은 줄어든다. 하지만 같은 해시값을 가진 key들은 같은 probe 경로를 따라가므로 secondary clustering은 남는다.

### Double hashing

두 번째 해시 함수 \\(h_2(k)\\)를 사용해 key마다 probe 간격을 다르게 만든다.

$$
h_i(k) = (h(k)+i h_2(k))\bmod m
$$

같은 \\(h(k)\\)를 가진 key라도 \\(h_2(k)\\)가 다르면 probe sequence가 달라진다. 그래서 secondary clustering을 줄이는 데 효과적이다.

## 12. Primary vs Secondary Clustering

| 구분 | 원인 | 대표적으로 나타나는 방식 |
|---|---|---|
| Primary clustering | 연속된 점유 구간이 점점 커짐 | Linear probing |
| Secondary clustering | 같은 \\(h(k)\\)를 가진 key가 같은 probe 경로를 공유 | Quadratic probing |

Double hashing은 key마다 다른 두 번째 해시값을 사용해 secondary clustering을 줄인다.

## 13. Closed Hashing 분석: Load Factor

Closed hashing 성능은 load factor에 크게 좌우된다.

$$
\alpha = \frac{s}{m}
$$

여기서 \\(s\\)는 저장된 아이템 수, \\(m\\)은 해시 테이블 크기다.

\\(\alpha = 0.7\\)이면 테이블의 70%가 차 있다는 뜻이다.

균등한 probing을 가정하면, 삽입 시 빈 슬롯을 만날 확률은 \\(1-\alpha\\)이다. 따라서 평균 탐색 횟수는 대략 다음처럼 해석할 수 있다.

$$
\mathbb{E}[\mathrm{probes}]
\approx \frac{1}{1-\alpha}
$$

| load factor \\(\alpha\\) | 평균 probe 해석 |
|---|---|
| \\(0.5\\) | 약 2번 |
| \\(0.7\\) | 약 3.33번 |
| \\(0.9\\) | 약 10번 |

\\(\alpha\\)가 1에 가까워질수록 빈 슬롯을 찾는 비용이 급격히 커진다. 그래서 closed hashing은 일정 적재율을 넘기 전에 resize 또는 rehashing이 필요하다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Open Hashing과 Closed Hashing의 차이는? | 외부 리스트 사용 vs 테이블 내부 probing |
| chaining의 장점은? | 삭제가 쉽고 load factor가 높아도 비교적 안정적 |
| open addressing에서 삭제가 어려운 이유는? | 탐색 경로가 끊기지 않도록 삭제 마킹이 필요 |
| bucket hashing의 한계는? | 특정 버킷이 차면 전체 빈 공간이 있어도 overflow 사용 |
| linear probing의 대표 문제는? | primary clustering |
| double hashing의 장점은? | key마다 probe sequence를 달리해 secondary clustering 완화 |
| load factor가 높아지면? | 평균 probe 횟수가 급격히 증가 |

## 복습 질문

<details>
<summary>1. Separate chaining에서 충돌이 발생하면 어디에 저장하는가?</summary>

답변: 해당 슬롯에 연결된 리스트에 새 노드를 추가한다. 따라서 같은 해시값을 가진 여러 아이템이 하나의 체인에 저장된다.

</details>

<details>
<summary>2. Open addressing에서 삭제한 슬롯을 단순히 empty로 만들면 왜 문제가 되는가?</summary>

답변: linear probing 등으로 뒤쪽 슬롯에 들어간 원소를 찾으려면 probe 경로를 계속 따라가야 한다. 중간 슬롯을 empty로 바꾸면 탐색이 그 자리에서 실패했다고 판단해 뒤쪽 원소를 놓칠 수 있다. 그래서 tombstone 같은 삭제 마킹이 필요하다.

</details>

<details>
<summary>3. \\(m = 6\\), \\(c = 2\\)인 상수 간격 probing이 위험한 이유는?</summary>

답변: \\(c\\)와 \\(m\\)이 서로소가 아니므로 \\(0 \to 2 \to 4 \to 0\\)처럼 일부 슬롯만 반복 방문할 수 있다. 모든 슬롯을 탐색하지 못해 빈 슬롯이 있어도 삽입에 실패할 수 있다.

</details>

<details>
<summary>4. load factor가 `0.9`인 closed hashing에서 삽입이 느려지는 이유는?</summary>

답변: 테이블의 90%가 이미 차 있으므로 빈 슬롯을 만날 확률이 낮다. 균등 probing을 가정하면 평균 probe 횟수는 \\(1/(1-0.9)=10\\) 정도로 커진다.

</details>

## Study Notes

LS19의 핵심은 "충돌은 피할 수 없으므로 어떻게 처리할 것인가"이다.

LS18이 좋은 해시 함수와 테이블 크기 선택을 다뤘다면, LS19는 충돌이 실제로 발생했을 때의 저장 전략을 비교한다.

가장 먼저 외워야 할 구분은 다음이다.

| 이름 | 실제 저장 위치 |
|---|---|
| Open Hashing / Separate Chaining | 테이블 슬롯 + 외부 리스트 |
| Closed Hashing / Open Addressing | 테이블 내부 슬롯 |

Closed hashing의 장점은 배열 안에서 해결하므로 메모리와 캐시 효율이 좋다는 점이다. 대신 테이블이 차오를수록 빈 슬롯을 찾는 비용이 빠르게 커진다.

Linear probing은 가장 단순하지만 primary clustering이 생긴다. Quadratic probing은 primary clustering을 줄이지만 같은 초기 해시값을 가진 key들은 같은 경로를 따라가므로 secondary clustering이 남는다. Double hashing은 두 번째 해시 함수로 key마다 probe 간격을 달리해 이 문제를 줄인다.

## Common Pitfalls

| 실수 | 올바른 이해 |
|---|---|
| Open Hashing과 Open Addressing을 같은 말로 이해한다. | Open Addressing은 Closed Hashing 계열이다. |
| Linear probing은 빈 칸만 찾으면 끝이라 항상 빠르다고 생각한다. | load factor가 높거나 clustering이 길면 매우 느려진다. |
| 삭제 슬롯을 그냥 비우면 된다고 생각한다. | probe 경로 보존을 위해 tombstone이 필요하다. |
| Quadratic probing이 모든 clustering을 해결한다고 생각한다. | secondary clustering은 남을 수 있다. |
| load factor를 단순한 용량 비율로만 본다. | closed hashing의 평균 probe 횟수를 결정하는 핵심 변수다. |

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/data-structures/LS19_hash_search_2.pdf" | relative_url }}" target="_blank" rel="noopener">LS19_hash_search_2.pdf</a></li>
</ul>
