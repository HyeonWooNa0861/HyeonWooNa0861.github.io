---
layout: default
date: 2026-10-14 13:38:33 +0900
last_modified_at: 2026-10-16 19:32:34 +0900
title: "Lecture 11: Greedy Algorithms"
course: "Algorithms"
topic: "Greedy Choice, Change Making, and Activity Selection"
order: 11
major_topic: "Data Structures & Algorithms"
keywords:
  - "Greedy Algorithms"
  - "Greedy-Choice Property"
  - "Optimal Substructure"
  - "Change Problem"
  - "Activity Selection"
  - "Exchange Argument"
---

# Lecture 11: Greedy Algorithms

Source PDF: [11 Greedy Algorithm.pdf](/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf)

그리디 알고리즘은 매 단계에서 현재 기준으로 가장 좋은 선택 하나를 확정한다. 선택을 되돌리지 않으므로 빠르고 단순할 수 있지만, **지역 최선이 전역 최선으로 이어진다는 증명**이 없으면 정답을 보장하지 않는다. 이 강의는 동전 교환과 회의 배정을 통해 안전한 선택을 찾고, 교환 논증과 최적 부분 구조로 그 선택을 증명하는 방법을 다룬다.

> **핵심:** 그리디 풀이에는 선택 규칙만이 아니라 두 근거가 필요하다. 어떤 최적해가 그리디 선택을 포함하도록 바꿀 수 있어야 하고, 그 선택 뒤의 남은 문제도 같은 형태의 최적 문제여야 한다. 동전 액면의 배수 관계는 동전 교환 그리디의 충분조건이며, 회의 최대 선택 문제에서는 가장 빨리 끝나는 회의를 고른다.

## 원본 그림으로 읽기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf#page=25" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-11-p25-meeting-room.jpg" | relative_url }}" alt="종료 시간이 가장 빠른 회의를 선택하는 greedy-choice property와 optimal substructure를 설명한 강의 슬라이드" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 25. 가장 빨리 끝나는 회의를 포함하는 최적해가 존재함을 교환 논증으로 설명한다.</figcaption>
</figure>

원문은 임의의 최적해 `T`가 첫 회의를 포함하지 않아도, `T`에서 가장 빨리 끝나는 회의를 빼고 첫 회의를 넣으면 겹침 없이 같은 개수를 유지할 수 있다고 설명한다. 첫 선택 뒤에는 종료 시각 이후 회의만 남는 같은 형태의 하위 문제가 생긴다. 두 성질이 함께 있어야 지역 선택을 반복해도 전체 최적해가 된다.

## 전체 흐름

| PDF 쪽 | 원문 범위 | 이 글의 대응 |
|---|---|---|
| 1–4 | 제목, 과제·중간고사 안내 | 자료 범위와 문서상 안내 |
| 5–8 | Dynamic Programming (2) 복습, 목차 | DP와 Greedy 비교, 세 문제의 연결 |
| 9–13 | Greedy 정의, 두 조건, Making It 1 질문 | 그리디 선택, 최적 부분 구조, 실패 반례 |
| 14–18 | Change Problem | 620원 trace, 구현, 배수 사슬 증명, 800원 반례 |
| 19–25 | Meeting Room Allocation | 세 선택 전략, 종료 시각 그리디, 교환 논증, 구현 |
| 26–29 | 요약, 다음 강의, 질문 | 마지막 핵심 정리와 복습 질문 |

4쪽의 시험 일정·범위·방식은 제공된 PDF에 적힌 문서상 안내다. 이 글은 별도의 최신 학사 공지를 확인한 일정 안내가 아니라, 11강의 알고리즘 내용을 설명하는 학습 자료다. 28쪽은 Graph algorithms를 중간고사 이후의 다음 주제로 예고한다.

## 1. Greedy Algorithm

### 1.1 현재 선택을 바로 확정한다

그리디 알고리즘은 현재 상태에서 정한 기준으로 가장 좋아 보이는 선택을 한다. 그 선택 뒤의 더 작은 문제로 이동하며, 이미 한 선택을 다시 검토하지 않는다.

이 방식은 완전탐색처럼 모든 선택 조합을 비교하지 않는다. 동적 계획법처럼 여러 상태의 최적값을 표에 저장해 비교하지도 않는다. 따라서 실행 과정은 짧을 수 있지만, 선택 기준이 틀리면 이후 단계가 아무리 정확해도 전체 답을 복구할 수 없다.

| 방법 | 현재 단계에서 하는 일 | 이전 선택 | 정답 근거 |
|---|---|---|---|
| Greedy | 한 선택을 즉시 확정 | 보통 되돌리지 않음 | greedy-choice property와 optimal substructure |
| Dynamic Programming | 가능한 선택의 하위 상태 값을 비교 | 표나 memo에 여러 결과 보존 | 빠짐없는 점화식과 최적 부분 구조 |
| Divide and Conquer | 독립적인 하위 문제를 모두 해결 | 각 하위 결과를 결합 | 분할·정복·결합의 정확성 |

### 1.2 Merge 함수의 선택은 왜 안전한가

11쪽은 Merge Sort의 `merge` 함수를 그리디 선택의 예로 든다. 단, **Merge Sort 전체는 분할 정복 알고리즘**이고, 그 안의 merge 단계가 두 정렬 배열의 head 중 작은 값을 고르는 지역 선택을 사용한다.

두 입력이 `L=[1,4,7]`, `R=[2,3,8]`이라면 head만 비교해 다음처럼 출력한다.

```text
L head  R head  선택  출력
1       2       1     [1]
4       2       2     [1, 2]
4       3       3     [1, 2, 3]
4       8       4     [1, 2, 3, 4]
7       8       7     [1, 2, 3, 4, 7]
-       8       8     [1, 2, 3, 4, 7, 8]
```

두 배열이 각각 정렬되어 있으므로 아직 출력하지 않은 전체 원소의 최솟값은 두 head 중 하나다. 더 작은 head를 지금 출력해도 나중 원소보다 클 수 없다. 이 정렬 불변식이 local minimum 선택을 안전하게 만든다.

### 1.3 최적성을 위한 두 조건

강의는 그리디 알고리즘이 최적해를 갖기 위한 조건을 다음 두 가지로 정리한다.

1. **Greedy-choice property:** 그리디가 지금 고른 선택을 포함하는 최적해가 존재한다.
2. **Optimal substructure:** 그 선택을 고정한 뒤 남은 부분도 해당 부분 문제의 최적해로 채울 수 있다.

첫 조건은 보통 **교환 논증(exchange argument)**으로 보인다. 임의의 최적해가 그리디 선택을 쓰지 않더라도, 그 최적해의 첫 선택을 그리디 선택으로 바꾸어 값이 나빠지지 않음을 증명한다. 둘째 조건은 남은 해가 최적이 아니라고 가정하고, 더 좋은 부분해로 교체하면 전체 해도 좋아져 원래 해의 최적성과 모순이라는 방식으로 증명한다.

<details markdown="block">
<summary markdown="span">Derivation: A reusable greedy proof template</summary>

최대화 문제의 입력을 $$I$$, 그리디 선택을 $$g$$, 최적값을 $$OPT(I)$$라고 하자.

1. 임의의 최적해 $$O$$를 잡는다.
2. $$O$$가 $$g$$를 포함하면 greedy-choice property의 첫 단계는 끝난다.
3. 포함하지 않으면 $$O$$의 어떤 선택 $$o$$를 $$g$$로 교체한다.
4. 교체 뒤 해가 여전히 feasible하고 목적값이 나빠지지 않음을 보인다.
5. 따라서 $$g$$를 포함하는 최적해 $$O'$$가 존재한다.
6. $$g$$ 뒤의 잔여 입력을 $$I_g$$라 하자. $$O'$$의 나머지가 $$I_g$$의 최적해가 아니면 더 나은 부분해로 바꿀 수 있으므로 $$O'$$가 최적이라는 가정과 모순이다.
7. 따라서 $$OPT(I)$$는 그리디 선택의 기여와 $$OPT(I_g)$$로 분해된다.

이 틀을 쓰려면 3–4단계의 교체가 문제 제약을 보존한다는 구체적인 이유가 필요하다. “현재 가장 좋아 보인다”는 설명만으로는 증명이 되지 않는다.

</details>

## 2. Greedy가 실패하는 경우: Making It 1

13쪽은 이전 강의의 Making It 1을 그리디로 풀어도 최적해가 보장되는지 묻는다. 허용 연산이 `1 빼기`, `2로 나누기`, `3으로 나누기`라고 하자. “가능하면 3으로 나누고, 다음으로 2로 나누고, 아니면 1을 뺀다”는 규칙은 자연스럽지만 안전하지 않다.

작성자가 구성한 $$N=10$$ 반례는 다음과 같다.

```text
greedy: 10 -> 5 -> 4 -> 2 -> 1   4회
optimal: 10 -> 9 -> 3 -> 1        3회
```

첫 단계에서 `10/2=5`가 `10-1=9`보다 작아 보여도, 5에서 1까지의 남은 최소 비용은 9에서 1까지의 비용보다 크다. 현재 숫자를 가장 많이 줄이는 선택이 남은 최적 비용을 보존하지 않으므로 greedy-choice property가 성립하지 않는다.

DP는 양의 정수 $$i$$를 1로 만드는 최소 연산 수를 $$D[i]$$로 둔다. 나눗셈은 $$i$$가 2 또는 3으로 나누어떨어져 결과가 정수일 때만 허용한다. 각 수 $$i$$에서 가능한 모든 첫 연산의 결과를 비교하면 다음 식을 얻는다.

$$
D[i]=1+\min\left(
D[i-1],
D[i/2]\text{ if }2\mid i,
D[i/3]\text{ if }3\mid i
\right),
\qquad D[1]=0.
$$

이 식은 후보를 하나만 즉시 확정하지 않는다. 필요한 하위 상태의 최솟값을 모두 계산한 뒤 가장 작은 값을 선택한다는 점이 그리디와 다르다.

## 3. Change Problem

### 3.1 입력은 물건값이고, 목표는 잔돈의 동전 수다

강의 문제는 `500, 100, 50, 10, 5, 1`원 동전이 충분히 있을 때, 1000원을 내고 물건을 산 뒤 받는 잔돈의 **최소 동전 수**를 구한다. 입력 $$p$$는 물건값이고 실제로 바꿀 금액은 $$x=1000-p$$다.

15쪽의 입력 380은 380원을 동전으로 바꾸라는 뜻이 아니다.

$$
x=1000-380=620.
$$

큰 동전부터 최대한 쓰면 다음과 같다.

| 단계 | 남은 금액 | 선택 | 사용 개수 | 선택 뒤 금액 |
|---|---:|---:|---:|---:|
| 1 | 620원 | 500원 | 1개 | 120원 |
| 2 | 120원 | 100원 | 1개 | 20원 |
| 3 | 20원 | 50원 | 0개 | 20원 |
| 4 | 20원 | 10원 | 2개 | 0원 |

따라서 `500+100+10+10=620`이고 출력은 4다. 같은 쪽의 입력 1은 잔돈 999원을 뜻하며 출력은 15다.

### 3.2 Greedy trace와 복잡도

액면을 큰 순서로 $$d_1,d_2,\ldots,d_m$$이라 하자. $$x$$와 $$d_i$$의 단위는 원, 선택 개수 $$c_i$$는 무차원 정수다. 각 액면 $$d_i$$에서 몫만큼 동전을 쓰고 나머지를 다음 단계로 넘긴다.

$$
c_i=\left\lfloor\frac{x}{d_i}\right\rfloor,
\qquad
x\leftarrow x\bmod d_i.
$$

기본 정수 산술 한 번을 $$O(1)$$로 세는 비용 모형에서 동전 종류가 $$m$$개이면 시간은 $$\Theta(m)$$이다. 액면별 선택을 반환하면 출력 공간은 $$\Theta(m)$$이고, 입력과 출력을 제외한 scan의 추가 공간은 $$O(1)$$이다. 이 강의처럼 여섯 액면이 고정되어 있으면 입력 크기와 무관한 상수 시간으로 볼 수 있다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Minimum change for the lecture's coin system</summary>

~~~python
COINS = (500, 100, 50, 10, 5, 1)


def minimum_change(price: int, paid: int = 1000):
    """Return (coin_count, denomination_counts) for paid - price."""
    if not isinstance(price, int) or not isinstance(paid, int):
        raise TypeError("price and paid must be integers")
    if price < 0 or price > paid:
        raise ValueError("price must satisfy 0 <= price <= paid")

    remaining = paid - price
    total = 0
    used = {}

    for coin in COINS:
        count, remaining = divmod(remaining, coin)
        used[coin] = count
        total += count

    return total, used


assert minimum_change(380) == (
    4,
    {500: 1, 100: 1, 50: 0, 10: 2, 5: 0, 1: 0},
)
assert minimum_change(1)[0] == 15
~~~

`remaining`은 아직 만들어야 할 잔돈이다. `divmod(remaining, coin)`은 현재 동전의 최대 사용 개수와 선택 뒤 남은 금액을 동시에 계산한다. 반환값은 최소 개수뿐 아니라 액면별 선택을 함께 제공한다.

</details>

### 3.3 배수 사슬은 왜 충분한가

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf#page=18" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-11-p18-change-condition.jpg" | relative_url }}" alt="동전 액면의 배수 사슬이 greedy change의 충분조건임을 대조하는 강의 슬라이드" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 18. 위 한국 동전 집합은 각 큰 액면이 바로 아래 액면의 배수라 교환 논증이 가능하다. 아래 반례 집합처럼 이 구조가 없으면 큰 동전 우선이 항상 최적이라고 보장할 수 없다.</figcaption>
</figure>

강의의 액면은 인접한 큰 동전이 바로 아래 작은 동전의 정수배다.

```text
500 = 5×100
100 = 2×50
 50 = 5×10
 10 = 2×5
  5 = 5×1
```

작은 동전이 큰 동전 하나와 같은 금액만큼 모였다면 큰 동전 하나로 교환할 수 있다. 금액은 같고 동전 수는 줄어든다. 따라서 최적해는 그런 교환이 가능한 작은 동전 묶음을 남길 수 없다. 작은 액면의 묶음을 큰 액면으로 올리는 교환을 더 이상 불가능할 때까지 반복하면 그리디가 만든 몫과 나머지 표현을 얻는다.

17쪽의 식은 경계에서 주의해야 한다. 500원 동전을 쓸 수 있는 조건은 $$x>500$$이 아니라 **$$x\ge500$$**이다. 최소 동전 수를 $$S(x)$$라 하면 이 액면 체계에서는

$$
S(x)=1+S(x-500)\qquad(x\ge500)
$$

로 쓸 수 있다. $$x<500$$에서는 다음 액면 100원에 같은 논리를 적용한다.

<details markdown="block">
<summary markdown="span">Derivation: Exchange proof for a divisibility-chain coin system</summary>

액면이

$$
d_1>d_2>\cdots>d_m=1,
\qquad d_i=b_i d_{i+1},
\qquad b_i\in\mathbb Z,\ b_i\ge2
$$

를 만족한다고 하자. 모든 동전 수는 무제한이다.

어떤 해에 $$d_{i+1}$$ 동전이 $$b_i$$개 이상 있으면, 그중 $$b_i$$개를 $$d_i$$ 하나로 바꿀 수 있다. 값은 $$b_id_{i+1}=d_i$$로 같고 동전 수는 $$b_i$$개에서 1개로 감소한다. 따라서 최적해에는 이런 교환 가능한 묶음이 남아 있을 수 없다.

모든 인접 액면에서 더 이상 교환할 수 없을 때까지 작은 액면에서 큰 액면 쪽으로 carry하면, 각 $$d_{j+1}$$ 동전의 개수는 $$b_j$$보다 작다. 이때 $$d_i$$보다 작은 동전들의 총액은 최대

$$
\sum_{j=i}^{m-1}(b_j-1)d_{j+1}
=\sum_{j=i}^{m-1}(d_j-d_{j+1})
=d_i-1
$$

이다. 합을 펼치면 중간항이 서로 상쇄되고 $$d_m=1$$이므로 마지막 등식이 성립한다.

이제 큰 액면을 처리하고 $$d_i$$ 이하의 동전으로 만들어야 할 잔액을 $$r_i$$라 하자. 정규화된 최적해에서 $$d_i$$보다 작은 동전의 총액은 $$d_i$$ 미만이므로 $$d_i$$ 동전의 개수와 다음 잔액은 각각

$$
c_i=\left\lfloor\frac{r_i}{d_i}\right\rfloor,
\qquad
r_{i+1}=r_i\bmod d_i
$$

로 강제된다. 최고 액면에서는 $$r_1=x$$로 시작하고, 각 단계의 잔액에 같은 논리를 적용한다. 이는 그리디가 계산하는 몫과 나머지와 정확히 같다.

첫 액면부터 마지막 액면까지 같은 논리를 적용하면 그리디 결과보다 적은 동전으로 같은 금액을 만드는 해가 없음을 얻는다.

</details>

### 3.4 충분조건과 필요조건을 구분한다

인접 액면의 배수 관계는 그리디 최적성을 보장하는 **충분조건**이다. 이 관계가 깨졌다고 해서 그리디가 반드시 실패한다는 뜻은 아니다.

작성자 구성 액면 `{3,2,1}`은 3이 2의 배수가 아니지만 모든 음이 아닌 정수 금액에서 그리디가 최적이다. $$x=3q+r$$, $$r\in\{0,1,2\}$$라 하면 그리디 동전 수는 $$q$$ 또는 $$q+1$$이다. 한 동전의 최대 가치가 3이므로 어떤 해도 $$\lceil x/3\rceil$$개보다 적은 동전을 쓸 수 없고, 그리디가 이 하한을 달성한다.

반면 18쪽의 액면 `{500,400,100,75,50}`과 금액 800에서는 실제로 실패한다.

```text
greedy: 500 + 100 + 100 + 100 = 800   4개
optimal: 400 + 400 = 800               2개
```

따라서 임의의 동전 체계에서는 액면만 보고 같은 코드를 적용하면 안 된다. 그리디 최적성을 별도로 증명하거나, 증명이 되지 않으면 금액을 상태로 둔 DP 같은 방법을 검토해야 한다.

## 4. Meeting Room Allocation Problem

### 4.1 문제는 최대 회의 선택이다

입력은 하나의 회의실을 사용하려는 $$n$$개 회의다. 회의 $$a_i=(s_i,f_i)$$는 같은 단위로 측정한 시작 시각 $$s_i$$와 종료 시각 $$f_i$$를 가지며 $$s_i\le f_i$$를 허용한다. 시각은 비교 가능한 수이고, 한 회의가 끝나는 시각에 다음 회의가 바로 시작할 수 있다.

두 회의를 이 순서로 배치할 때 $$f_i\le s_j$$이면 compatible하다고 하자. 목표는 모든 회의를 배치하는 것이 아니라, **서로 compatible한 회의의 최대 개수**를 선택하는 것이다.

이 문제를 “모든 회의를 수용하는 데 필요한 최소 회의실 수”와 혼동하면 안 된다. 최소 회의실 문제는 회의를 버리지 않고 동시 진행 수를 줄이는 자원 할당 문제다. 이 강의 문제는 회의실 하나만 두고 일부 회의를 선택하는 activity-selection 문제다.

### 4.2 완전탐색과 실패하는 두 기준

회의마다 선택하거나 선택하지 않는 두 경우가 있으므로 부분집합은 $$2^n$$개다. 모든 부분집합을 만들고, 겹치는 집합을 제거하고, 크기가 가장 큰 집합을 찾는 방법은 지수 시간이 필요해 큰 입력에 비현실적이다.

강의는 세 가지 그리디 기준을 비교한다.

1. 가장 짧은 회의를 먼저 고른다.
2. 가장 일찍 시작하는 회의를 먼저 고른다.
3. 가장 일찍 끝나는 회의를 먼저 고른다.

앞의 두 기준은 최적해를 보장하지 않는다. 다음은 원문 규칙을 검증하기 위해 작성자가 구성한 반례다.

- **최단 시간 우선 실패:** `[0,4)`, `[3,5)`, `[4,8)`에서 길이 2인 `[3,5)`를 먼저 고르면 1개뿐이다. `[0,4)`, `[4,8)`을 고르면 2개다.
- **최소 시작 시각 우선 실패:** `[0,10)`, `[1,2)`, `[2,3)`, `[3,4)`에서 `[0,10)`을 먼저 고르면 1개뿐이다. 나머지 세 회의는 모두 연속해 선택할 수 있다.

회의 길이나 시작 시각은 선택 뒤 남는 시간의 크기를 직접 보장하지 않는다. 반면 종료 시각이 가장 빠른 회의는 이후 회의가 사용할 수 있는 시작 구간을 가장 넓게 남긴다.

### 4.3 가장 빠른 종료 시각 전략

회의를 `(종료 시각, 시작 시각)` 오름차순으로 정렬한다. 정렬된 순서에서 현재 회의의 시작 시각이 마지막 선택 회의의 종료 시각 이상이면 선택한다.

작성자 구성 입력을 추적하면 다음과 같다.

| 순서 | 회의 | 마지막 종료 전 | 판단 | 마지막 종료 후 |
|---:|---|---:|---|---:|
| 1 | `B=(1,2)` | $$-\infty$$ | 선택 | 2 |
| 2 | `A=(0,3)` | 2 | `0 < 2`, 제외 | 2 |
| 3 | `C=(2,4)` | 2 | 선택 | 4 |
| 4 | `D=(4,4)` | 4 | 선택 | 4 |
| 5 | `E=(4,6)` | 4 | 선택 | 6 |
| 6 | `F=(5,7)` | 6 | `5 < 6`, 제외 | 6 |

결과는 `B, C, D, E`, 총 4개다. `D`는 시작과 종료가 같은 zero-duration 회의이며, 이전 회의가 4에 끝나고 다음 회의가 4에 시작하는 사이에 선택할 수 있다.

<figure class="study-source-figure">
  <a href="{{ "/assets/images/study/algorithms/supplementary/activity-selection-timeline.svg" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/supplementary/activity-selection-timeline.svg" | relative_url }}" alt="시간축 위에 여섯 회의를 배치하고 종료 시각 순회에서 B, C, D, E가 선택되고 A와 F가 제외되는 과정" loading="lazy"></a>
  <figcaption><strong>Supplementary diagram.</strong> 바로 위 작성자 구성 입력의 scan을 시간축에 놓은 도식이다. 강의 원본 결과가 아니라 `(finish, start)` 정렬과 호환성 경계를 보충한다.</figcaption>
</figure>

도식은 위에서 아래로 정렬된 처리 순서를 나타낸다. 파란 막대의 시작점이 직전 파란 막대의 끝점 이상이면 선택한다. 회색 `A`는 `B` 선택 뒤 시작점 0이 경계 2보다 작고, `F`는 `E` 선택 뒤 시작점 5가 경계 6보다 작아 제외된다. 점으로 표시한 `D=[4,4]`는 길이가 0이지만 `C`의 종료와 `E`의 시작이 모두 4이므로 두 회의 사이에 들어간다.

시각 비교와 대입을 $$O(1)$$로 세면 정렬은 $$O(n\log n)$$, 한 번의 scan은 $$O(n)$$이므로 전체 시간은 $$O(n\log n)$$이다. 이미 같은 순서로 정렬된 입력이면 scan만 수행해 $$O(n)$$이다. 선택 목록을 제외한 scan의 추가 공간은 $$O(1)$$이며, 실제 정렬의 추가 공간은 사용한 정렬 구현에 따른다.

### 4.4 Zero-duration 회의와 tie-break

양의 길이 회의만 있다면 종료 시각이 같은 회의의 순서는 결과 개수에 영향을 주지 않는다. 그러나 $$s_i=f_i$$를 허용하는 원문 조건에서는 종료 시각 동점에 **시작 시각 오름차순** tie-break가 필요하다.

```text
입력 순서: (1,1), (0,1)
종료 시각만 사용한 stable sort: (1,1), (0,1)
결과: (1,1)을 고른 뒤 (0,1)을 고를 수 없어 1개

(종료, 시작) 오름차순: (0,1), (1,1)
결과: 두 회의를 순서대로 골라 2개
```

이 경계 조건 때문에 구현과 증명 모두 “가장 빠른 종료”의 동점 규칙을 명시해야 한다.

### 4.5 Greedy-choice property와 optimal substructure

`(종료 시각, 시작 시각)` 순서의 첫 회의를 $$a_1=(s_1,f_1)$$이라 하자. 어떤 최적 일정의 첫 회의가 $$a_j$$라면 $$f_1\le f_j$$다. $$a_j$$를 $$a_1$$로 바꾸어도 뒤의 모든 회의는 여전히 $$f_1$$ 이후에 시작할 수 있다. 따라서 $$a_1$$을 포함하는 최적해가 존재한다.

$$a_1$$을 선택한 뒤의 정확한 잔여 집합은

$$
R(a_1)=\{a_i\in A\setminus\{a_1\}:s_i\ge f_1\}
$$

이다. 선택한 $$a_1$$을 집합에서 제외해야 한다. 그렇지 않으면 $$s_1=f_1$$인 zero-duration 회의가 자기 자신을 다시 선택할 수 있다. 빈 집합의 최적값을 0이라 두면

$$
OPT(A)=1+OPT(R(a_1))
$$

로 분해된다. 남은 일정이 $$R(a_1)$$의 최적해가 아니라면 더 큰 compatible 집합으로 바꾸어 전체 선택 수도 늘릴 수 있으므로 모순이다.

<details markdown="block">
<summary markdown="span">Derivation: Full exchange argument with zero-duration meetings</summary>

회의는 `(종료 시각, 시작 시각)` 오름차순으로 비교한다. 그 첫 회의를 $$a_1$$이라 하고, 최적 일정 $$O=(o_1,o_2,\ldots,o_k)$$를 시간 순서로 적는다.

**경우 1: $$a_1\notin O$$.** $$a_1$$의 종료 시각은 전체에서 최소이므로 $$f_1\le f(o_1)$$다. $$O$$에서 $$o_1$$을 $$a_1$$로 교체한다. 원래 두 번째 회의부터는 시작 시각이 $$f(o_1)$$ 이상이므로 $$f_1$$ 이상이기도 하다. 따라서 새 일정은 feasible하고 회의 수 $$k$$도 유지된다.

**경우 2: $$a_1\in O$$이지만 첫 회의가 아니다.** $$a_1$$ 앞에 있는 회의의 종료는 $$a_1$$의 시작 이하이고, $$a_1$$의 종료는 전체 최소다. 따라서 관련 시각은 모두 같아야 한다. 시작 시각 tie-break까지 적용하면 이들은 같은 시각의 zero-duration 회의이며 $$a_1$$을 맨 앞으로 옮겨도 feasibility가 유지된다.

두 경우 모두 $$a_1$$을 첫 선택으로 갖는 최적 일정이 존재한다. 이제 $$a_1$$ 뒤의 일정은 정확히 $$R(a_1)$$ 안에서 선택된다. 그 나머지가 최적이 아니면 더 큰 잔여 일정을 붙여 전체 회의 수를 늘릴 수 있으므로 원래 일정이 최적이라는 가정에 모순이다.

</details>

<details markdown="block">
<summary markdown="span">Code Walkthrough: Selecting a maximum compatible meeting set</summary>

~~~python
from math import inf


def select_max_meetings(meetings):
    """Return selected (start, finish) meetings in schedule order."""
    checked = []
    for index, meeting in enumerate(meetings):
        if len(meeting) != 2:
            raise ValueError("each meeting must be (start, finish)")
        start, finish = meeting
        if start > finish:
            raise ValueError("meeting must satisfy start <= finish")
        checked.append((start, finish, index))

    ordered = sorted(checked, key=lambda item: (item[1], item[0], item[2]))
    selected = []
    last_finish = -inf

    for start, finish, _ in ordered:
        if start >= last_finish:
            selected.append((start, finish))
            last_finish = finish

    return selected


meetings = [(0, 3), (1, 2), (2, 4), (4, 4), (4, 6), (5, 7)]
assert select_max_meetings(meetings) == [
    (1, 2),
    (2, 4),
    (4, 4),
    (4, 6),
]
assert select_max_meetings([(1, 1), (0, 1)]) == [(0, 1), (1, 1)]
~~~

정렬 key의 첫 두 성분 `(finish, start)`가 증명에서 사용한 순서와 같다. 세 번째 원래 index는 시작과 종료가 모두 같은 회의들의 결과 순서를 결정할 뿐 선택 개수에는 영향을 주지 않는다. Scan 중 `last_finish`는 지금까지 선택한 마지막 회의의 종료 시각이다.

</details>

## 5. Greedy 문제를 푸는 순서

새 문제에서 “가장 큰 것부터”, “가장 작은 것부터”라는 규칙이 떠올라도 바로 구현하지 않는다. 다음 순서로 점검한다.

1. **목적함수와 feasible solution을 정의한다.** 무엇을 최소화·최대화하며 어떤 선택 조합이 허용되는지 쓴다.
2. **선택 기준을 한 문장으로 고정한다.** 동전은 남은 금액 이하의 최대 액면, 회의는 최소 `(종료, 시작)`이다.
3. **작은 입력 trace를 만든다.** 선택 뒤 상태와 최종 목적값을 기록한다.
4. **경쟁 규칙의 반례를 찾는다.** 회의 길이·시작 시각 기준처럼 자연스럽지만 틀린 규칙을 작은 입력으로 제거한다.
5. **교환 논증을 쓴다.** 임의의 최적해를 그리디 선택을 포함하도록 바꾸어도 손해가 없음을 보인다.
6. **잔여 문제를 정확히 정의한다.** 선택한 원소를 제외하고, 호환 조건을 만족하는 입력만 남긴다.
7. **복잡도와 경계를 확인한다.** 정렬 비용, 고정된 동전 종류, 빈 입력, 동점, zero-duration 입력을 포함한다.

증명이 되지 않으면 그리디를 정답 알고리즘으로 확정하지 않는다. 반례를 더 찾거나, DP·완전탐색·다른 자료구조가 필요한지 검토한다.

## 6. Source Check

| 원문 위치 | 확인한 내용 | 이 글의 처리 |
|---|---|---|
| p. 11 | Merge function의 local choice | 정렬된 두 입력의 head 최솟값 선택과 Merge Sort 전체의 분할 정복을 구분 |
| p. 13 | Making It 1의 Greedy 가능 여부 질문 | $$N=10$$ 구성 반례로 최적성 실패를 직접 확인 |
| p. 15 | 입력 380, 출력 4 | 입력은 물건값, 잔돈은 620원이며 동전 4개임을 계산 |
| p. 17 | `x > 500` 조건 | 500원 동전을 쓸 수 있는 정확한 경계 $$x\ge500$$로 정정 |
| p. 18 | 배수 관계와 800원 반례 | 배수 사슬은 충분조건임을 증명하고 `{500,400,100,75,50}`의 4개 대 2개를 확인 |
| p. 20–24 | 회의 정의와 세 선택 전략 | 최대 회의 선택 문제로 정의하고 두 실패 기준에 구성 반례 제시 |
| p. 25 | 교환 논증과 잔여 집합 | zero-duration 입력을 위해 `(finish, start)` tie-break와 $$A\setminus\{a_1\}$$를 명시 |

29쪽 전체를 화면과 추출 텍스트로 확인했다. 수치 예제와 코드는 별도로 실행해 검산했다. 원문의 `x > 500` 경계와 선택 회의를 포함할 수 있는 잔여 집합 표현은 원본 파일을 바꾸지 않고 본문에서 정정했다. 배수 관계가 없는 모든 체계에서 실패한다는 강한 해석은 사용하지 않고, 보장이 사라진다는 뜻으로 구분했다.

## 마지막 핵심 정리

- 그리디는 현재 선택을 확정하므로, 선택 규칙의 최적성 증명이 필요하다.
- Merge 함수의 작은 head 선택은 두 입력이 이미 정렬되어 있기 때문에 안전하다. Merge Sort 전체는 분할 정복이다.
- Making It 1은 현재 값을 가장 많이 줄이는 규칙이 실패할 수 있어 DP가 필요하다.
- 물건값 380원의 잔돈은 620원이고, 강의 동전으로 `500+100+10+10`의 4개다.
- 인접 액면의 배수 관계는 동전 그리디의 충분조건이지만 필요조건은 아니다.
- 회의 최대 선택은 가장 빨리 끝나는 회의를 고른다. 최소 회의실 수 문제와 다른 목표다.
- Zero-duration 회의에는 `(종료 시각, 시작 시각)` 정렬과 선택 회의를 제외한 잔여 집합이 필요하다.

## Study Guide

1. Greedy-choice property와 optimal substructure를 각각 한 문장으로 설명한다.
2. Making It 1의 $$N=10$$ 반례에서 greedy 경로와 최적 경로를 손으로 비교한다.
3. 물건값 380을 잔돈 620으로 바꾼 뒤 동전 선택 trace를 쓴다.
4. 배수 사슬의 교환 논증과 800원 반례를 함께 설명한다.
5. 회의 길이·시작 시각 기준의 반례를 그리고, 종료 시각 기준의 교환 과정을 말한다.
6. Zero-duration 회의 두 개로 종료 시각 동점 규칙이 필요한 이유를 확인한다.
7. 구현의 정렬 key, 선택 조건, 시간 복잡도를 증명의 기호와 연결한다.

## 복습 질문

<details markdown="block">
<summary>1. Greedy-choice property는 무엇인가?</summary>

답변: 현재의 그리디 선택을 포함하는 최적해가 적어도 하나 존재한다는 성질이다. 보통 임의의 최적해의 첫 선택을 그리디 선택으로 교체해도 feasibility와 목적값이 나빠지지 않음을 보여 증명한다.

</details>

<details markdown="block">
<summary>2. Merge 함수에서 작은 head를 즉시 출력해도 되는 이유는?</summary>

답변: 두 입력 배열이 각각 정렬되어 있어 아직 남은 모든 원소의 최솟값이 두 head 중 하나이기 때문이다. 더 작은 head는 어떤 뒤쪽 원소보다 클 수 없다. 단, Merge Sort 전체의 설계는 분할 정복이다.

</details>

<details markdown="block">
<summary>3. Making It 1에서 큰 나눗셈을 우선하는 규칙은 왜 실패하는가?</summary>

답변: $$N=10$$에서 나눌 수 있을 때 2로 나누면 `10,5,4,2,1`의 4회가 필요하지만, 먼저 1을 빼면 `10,9,3,1`의 3회로 끝난다. 현재 값의 감소량이 남은 최소 연산 수를 보존하지 않는다.

</details>

<details markdown="block">
<summary>4. 물건값이 380원일 때 출력이 4인 이유는?</summary>

답변: 1000원을 냈으므로 잔돈은 380원이 아니라 620원이다. `500+100+10+10=620`이므로 동전은 4개다.

</details>

<details markdown="block">
<summary>5. 동전 액면의 배수 관계는 필요조건인가?</summary>

답변: 아니다. 배수 사슬은 그리디 최적성을 보장하는 충분조건이다. `{3,2,1}`은 3이 2의 배수가 아니지만 그리디가 모든 금액에서 동전 수 하한 $$\lceil x/3\rceil$$을 달성한다.

</details>

<details markdown="block">
<summary>6. 원문의 800원 동전 체계에서 그리디는 어떻게 실패하는가?</summary>

답변: 액면 `{500,400,100,75,50}`에서 그리디는 `500+100+100+100`의 4개를 쓴다. 최적해는 `400+400`의 2개다.

</details>

<details markdown="block">
<summary>7. 회의 최대 선택과 최소 회의실 수는 어떻게 다른가?</summary>

답변: 회의 최대 선택은 회의실 하나에서 일부 회의를 버리며 선택 개수를 최대화한다. 최소 회의실 수는 모든 회의를 유지하면서 겹치는 회의를 수용할 자원 수를 최소화한다. 목적함수와 출력이 다르다.

</details>

<details markdown="block">
<summary>8. 회의 배정에서 가장 빠른 종료 시각이 안전한 이유는?</summary>

답변: 어떤 최적 일정의 첫 회의를 가장 빨리 끝나는 회의로 바꾸어도 이후 회의들의 시작 조건을 해치지 않는다. 선택 개수가 유지되므로 그 선택을 포함하는 최적해가 존재한다.

</details>

<details markdown="block">
<summary>9. Zero-duration 회의에서 `(finish, start)` 정렬이 필요한 이유는?</summary>

답변: `(1,1)`을 `(0,1)`보다 먼저 처리하면 scan은 뒤의 `(0,1)`을 제외해 1개만 고른다. `(finish, start)` 오름차순은 `(0,1)`, `(1,1)` 순서를 만들어 두 회의를 모두 선택한다.

</details>

<details markdown="block">
<summary markdown="span">10. 잔여 집합에서 왜 $$a_1$$을 제외해야 하는가?</summary>

답변: $$s_1=f_1$$인 zero-duration 회의는 조건 $$s_i\ge f_1$$을 자기 자신도 만족한다. $$A\setminus\{a_1\}$$를 쓰지 않으면 점화식이 같은 회의를 반복 선택할 수 있다.

</details>

## Related Notes

- [Lecture 10: Dynamic Programming II]({{ "/study/algorithms/lecture-10-dynamic-programming-02/" | relative_url }})
- [Algorithms: Midterm Review]({{ "/study/algorithms/midterm-review-through-greedy/" | relative_url }})

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 11: Greedy Algorithm</a></li>
</ul>
