---
layout: default
date: 2026-09-15 00:00:00 +0900
title: "Algorithms Assignment 1: Complexity Analysis and Recurrences"
course: "Algorithms"
topic: "Asymptotic Analysis and Recurrences"
order: 1
major_topic: "Algorithms"
keywords: [operation-counting, asymptotic-analysis, recurrence-relations, master-theorem]
---

# Algorithms Assignment 1: Complexity Analysis and Recurrences

## Key Takeaways

**행렬 곱셈의 연산 횟수, 점근 표기법의 정의, 재귀 실행시간, Master Theorem을 연결하는 과제 해설이다.** 원문의 4개 문제와 15개 소문항을 순서대로 다룬다. 아래 내용은 원문 문제에 대한 독립 풀이이며, 교수자 제공 공식 해답은 아니다.

- 행렬 곱셈은 곱셈을 정확히 $$n^3$$번 수행하며 실행시간은 $$\Theta(n^3)$$이다.
- 정의를 이용한 증명에서는 최고차항만 지목하지 않고 **양의 상수와 시작점**을 실제로 제시해야 한다.
- `3 * fn(n / 3)`은 재귀 호출 **한 번**의 결과에 3을 곱한다. 실행시간은 $$\Theta(\log n)$$이며 반환값의 증가율과 다르다.
- Master Theorem에서는 $$f(n)$$과 $$n^{\log_b a}$$를 비교한다. Case 3은 정규성 조건까지 확인한다.

## Original Material

[Original Assignment PDF]({{ '/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf' | relative_url }})

원문: *2026 Fall Algorithms Assignment #1*, 2쪽. 1쪽의 문제 1–3과 2쪽의 문제 4를 다룬다. 수치 연산을 상수 시간으로 세는 표준 단위 비용 모형을 사용한다. 별도 표시가 없는 한 $$n$$은 양의 정수이며, 재귀식의 기저 비용은 양의 상수이다.

## 1. Matrix Multiplication

원문 1쪽의 코드는 다음과 같다. 배열은 미리 준비되어 있고, 이 함수는 결과 배열 `M`을 채운다.

```python
def matmul(A, B, M, n):
    for i in range(n):
        for j in range(n):
            M[i][j] = A[i][0] * B[0][j]
            for k in range(1, n):
                M[i][j] += A[i][k] * B[k][j]
```

### 1(a). Count Basic Operations

<details markdown="block" open>
<summary>Answer</summary>

답변: 곱셈 $$n^3$$회, 덧셈 $$n^3-n^2$$회, 결과 원소 저장 $$n^3$$회이다. 산술·저장을 각각 단위 비용으로 세면 총 $$3n^3-n^2$$회이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 먼저 무엇을 기본 연산으로 세는지 정한다. 여기서는 **스칼라 곱셈, 스칼라 덧셈, 결과 원소 저장**을 각각 1회로 센다. `+=`는 덧셈 1회와 저장 1회로 분리한다. 인덱싱 및 반복 제어 비용은 이 표와 구분한다.

각 $$i,j$$ 쌍에 대해 첫 항을 한 번 계산하고, 나머지 $$n-1$$개 항을 더한다. $$i,j$$ 쌍은 $$n^2$$개이다.

| Operation | Initial term per entry | Remaining terms per entry | Total |
| --- | --- | --- | --- |
| Scalar multiplication | $$1$$ | $$n-1$$ | $$n^3$$ |
| Scalar addition | $$0$$ | $$n-1$$ | $$n^3-n^2$$ |
| Write to M | $$1$$ | $$n-1$$ | $$n^3$$ |

예를 들어 곱셈 횟수는

$$
\sum_{i=0}^{n-1}\sum_{j=0}^{n-1}\left(1+\sum_{k=1}^{n-1}1\right)
=n^2(1+n-1)=n^3.
$$

덧셈은 초기 대입문에 없으므로

$$
\sum_{i=0}^{n-1}\sum_{j=0}^{n-1}\sum_{k=1}^{n-1}1
=n^2(n-1)=n^3-n^2.
$$

**초기값을 0으로 설정한 뒤 모든 항을 더하는 코드가 아니다.** 따라서 덧셈을 $$n^3$$번으로 세면 출력 원소마다 1회씩 과대 계산한다. $$n=1$$일 때 곱셈 1회, 덧셈 0회라는 경계값도 확인할 수 있다.

배열 접근까지 별도 기본 연산으로 세면 `A` 원소 읽기와 `B` 원소 읽기는 각각 $$n^3$$회, 기존 `M` 원소 읽기는 $$n^3-n^2$$회, `M` 원소 쓰기는 $$n^3$$회이다. 이는 **원소 접근** 기준이며 Python 중첩 리스트의 개별 인덱싱 명령 수와 같다는 뜻은 아니다.

반복 제어도 포함해야 한다면 다음의 개념적 `initialize; test; advance` 모형을 추가할 수 있다. 종료를 판정하는 마지막 실패 검사도 센다.

| Loop | Initialization | Condition test | Advance |
| --- | --- | --- | --- |
| i | $$1$$ | $$n+1$$ | $$n$$ |
| j | $$n$$ | $$n(n+1)$$ | $$n^2$$ |
| k | $$n^2$$ | $$n^3$$ | $$n^2(n-1)$$ |

`k` 반복은 각 출력 원소에서 $$n-1$$회 진행하지만 검사는 $$n$$회 한다. 이 표는 **분석용 반복 모형**이다. Python의 `range`와 반복자에 실제로 이 형태의 비교·증가 명령이 실행된다고 주장하는 것은 아니다. 정확한 다항식 계수는 선택한 비용 모형에 따라 달라진다.

</details>

### 1(b). Derive the Time Complexity

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^3)$$이다. 산술 연산만 세면 $$2n^3-n^2$$회이며, 저장까지 세면 $$3n^3-n^2$$회이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 산술 연산만 세면

$$
T_{\mathrm{arithmetic}}(n)=n^3+(n^3-n^2)=2n^3-n^2.
$$

원소 저장도 1회로 세는 앞의 모형에서는

$$
T_{\mathrm{arithmetic+write}}(n)=3n^3-n^2.
$$

$$n\ge1$$에서 $$n^3\le2n^3-n^2\le2n^3$$이므로 산술 비용은 $$\Theta(n^3)$$이다. 상수 시간 배열 접근과 반복 제어를 포함해도 총 비용은 $$O(n^3)$$이며, 곱셈만 이미 $$n^3$$회이므로 하한은 $$\Omega(n^3)$$이다.

답변: **$$T(n)=\Theta(n^3)$$**. 특히 $$O(n^3)$$도 성립하지만, $$\Theta$$는 상한과 하한을 함께 표현한다. 배열 할당 비용은 제시된 함수 바깥이며, 별도로 $$\Theta(n^2)$$ 비용을 추가하더라도 결론은 바뀌지 않는다.

</details>

## 2. Proofs from Asymptotic Definitions

충분히 큰 $$n$$에서 함수가 음수가 아니라고 할 때, 정의는 다음과 같다.

$$
\begin{aligned}
f(n)\in O(g(n))&\iff\exists c>0,n_0:\ 0\le f(n)\le cg(n)\quad(n\ge n_0),\\
f(n)\in\Omega(g(n))&\iff\exists c>0,n_0:\ 0\le cg(n)\le f(n)\quad(n\ge n_0),\\
f(n)\in\Theta(g(n))&\iff\exists c_1,c_2>0,n_0:\ 0\le c_1g(n)\le f(n)\le c_2g(n)\quad(n\ge n_0).
\end{aligned}
$$

원문의 $$T(n)=O(g(n))$$ 표기는 관례적인 표현이다. 여기서는 함수가 점근적 함수 집합에 속함을 드러내기 위해 $$\in$$도 사용한다.

### 2(a). A Cubic Upper Bound

증명 대상: $$6n^3-15n^2+20\in O(n^3)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$6n^3-15n^2+20\in O(n^3)$$. 정의를 만족하는 상수는 $$c=6,\ n_0=3$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$n\ge3$$이면

$$
6n^3-15n^2+20=3n^2(2n-5)+20>0.
$$

또한 $$15n^2\ge20$$이므로

$$
6n^3-15n^2+20\le6n^3.
$$

따라서 모든 정수 $$n\ge3$$에 대해 $$0\le T(n)\le6n^3$$이다. **$$c=6,n_0=3$$**이 정의를 만족하므로 $$T(n)\in O(n^3)$$이다. 최소 상수나 최소 시작점을 찾을 필요는 없다.

</details>

### 2(b). A Quadratic Lower Bound

증명 대상: $$7n^2-4n\log_2n\in\Omega(n^2)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$7n^2-4n\log_2n\in\Omega(n^2)$$. 정의를 만족하는 상수는 $$c=3,\ n_0=1$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 양의 정수 $$n$$에서 $$\log_2n\le n$$임을 먼저 확인한다. $$2^1\ge1$$이고, $$2^n\ge n$$이면

$$
2^{n+1}\ge2n\ge n+1\qquad(n\ge1).
$$

귀납법으로 $$2^n\ge n$$이며, 증가함수 $$\log_2$$를 적용하면 $$n\ge\log_2n$$이다. 양수 $$4n$$을 곱하고 음수 부호를 적용할 때 부등호 방향에 주의하면

$$
-4n\log_2n\ge-4n^2.
$$

따라서

$$
T(n)=7n^2-4n\log_2n\ge7n^2-4n^2=3n^2>0.
$$

**$$c=3,n_0=1$$**이므로 $$T(n)\in\Omega(n^2)$$이다. 음의 항을 무시하는 것은 하한 증명이 아니다. 그 항이 얼마나 많이 차감할 수 있는지 제어해야 한다.

</details>

### 2(c). A Tight Quadratic Bound

증명 대상: $$3n^2+5n-2\in\Theta(n^2)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$3n^2+5n-2\in\Theta(n^2)$$. $$c_1=3,\ c_2=8,\ n_0=1$$로 잡으면 된다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$n\ge1$$이면 $$5n-2\ge0$$이므로

$$
3n^2\le3n^2+5n-2.
$$

동시에 $$n\le n^2$$이므로

$$
3n^2+5n-2\le3n^2+5n\le8n^2.
$$

따라서

$$
0\le3n^2\le T(n)\le8n^2\qquad(n\ge1).
$$

**$$c_1=3,c_2=8,n_0=1$$**로 양쪽 부등식이 같은 구간에서 성립한다. 그러므로 $$T(n)\in\Theta(n^2)$$이다.

</details>

## 3. A Single Recursive Call

원문 1쪽은 $$n=3^k$$인 양의 정수를 가정한다. 따라서 $$k$$는 0 이상의 정수이다.

```python
def fn(n):
    if n <= 1:
        return 1
    else:
        return 3 * fn(n / 3) + n
```

### 3(a). Build the Runtime Recurrence

<details markdown="block" open>
<summary>Answer</summary>

답변: 실행시간 점화식은 $$T(1)=b,\ T(n)=T(n/3)+d$$이다($$b,d>0$$). 재귀 호출은 한 번이며, 반환값의 점화식과 구분한다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: `fn(n / 3)`을 한 번 호출한 뒤, 그 반환값에 곱셈 1회와 덧셈 1회를 수행한다. 조건 검사와 인자 나눗셈도 상수 비용이다. 비기저 호출의 자체 비용을 $$d>0$$, 기저 호출 비용을 $$b>0$$라 두면

$$
T(1)=b,\qquad T(n)=T(n/3)+d\quad(n>1).
$$

비용을 정확한 상수로 고정하지 않는 일반적인 표기는 $$T(n)=T(n/3)+\Theta(1)$$이다. **$$3T(n/3)+n$$은 이 코드의 실행시간 점화식이 아니다.** `+ n`은 반복문이 아니라 덧셈 한 번이며, 앞의 `3 *`도 호출 수를 늘리지 않는다.

반환값을 별도 함수 $$F(n)$$으로 정의하면 오히려

$$
F(1)=1,\qquad F(n)=3F(n/3)+n
$$

이다. 양변을 $$n$$으로 나누면 $$F(n)/n=F(n/3)/(n/3)+1$$이다. 이를 $$k=\log_3n$$번 전개하여

$$
F(n)=n(1+\log_3n)
$$

을 얻는다. 예컨대 $$n=9$$이면 반환값은 27이지만 함수 호출은 `fn(9)`, `fn(3)`, `fn(1)`의 3회이다. **출력 수치의 크기와 연산 횟수는 다른 대상**이다.

분석은 단위 비용 모형에 따른다. 실제 Python의 `/`는 부동소수점 값을 만들므로 매우 큰 입력의 정확한 정수 재귀를 시험할 때는 `n // 3`을 사용할 수 있다. 임의 정밀도 정수의 비트 연산 비용까지 세는 분석은 여기서 가정한 비용 모형과 다르다.

</details>

### 3(b). Iterative Substitution

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=b+d\log_3n\in O(\log n)$$이며, 더 정확히는 $$\Theta(\log n)$$이다. 반복 대입은 $$\log_3n$$단계에서 기저에 도달한다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 같은 식을 재귀 항에 반복 대입한다.

$$
\begin{aligned}
T(n)&=T(n/3)+d\\
&=T(n/3^2)+2d\\
&=T(n/3^3)+3d\\
&=T(n/3^j)+jd.
\end{aligned}
$$

기저 입력에 도달하는 조건은 $$n/3^j=1$$이므로 $$j=\log_3n=k$$이다. 따라서

$$
T(n)=T(1)+d\log_3n=b+d\log_3n.
$$

$$n\ge3$$에서는 $$\log_3n\ge1$$이므로

$$
d\log_3n\le T(n)\le(b+d)\log_3n.
$$

답변: **$$T(n)\in O(\log n)$$**, 더 정확히는 $$\Theta(\log n)$$이다. 로그의 밑은 상수배만 바꾸므로 점근 분류에 영향을 주지 않는다. 호출 스택의 최대 깊이도 $$k+1$$이므로 추가 스택 공간은 $$\Theta(\log n)$$이다.

</details>

### 3(c). Guess and Verification

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(3^k)=dk+b$$라는 추측을 귀납법으로 검증하면 $$T(n)\in O(\log n)$$을 얻는다. 기저 $$k=0$$과 귀납 단계를 모두 확인한다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 입력이 매번 3분의 1이 되므로 $$T(n)=d\log_3n+b$$를 추측한다. $$n=3^k$$에 대해 $$T(3^k)=dk+b$$를 귀납법으로 검증한다.

**기저 단계:** $$k=0$$이면 $$T(3^0)=T(1)=b=d\cdot0+b$$이다.

**귀납 가정:** 어떤 $$k\ge0$$에서 $$T(3^k)=dk+b$$라고 가정한다.

**귀납 단계:** 점화식에 대입하면

$$
T(3^{k+1})=T(3^k)+d=(dk+b)+d=d(k+1)+b.
$$

따라서 모든 $$k\ge0$$에서 추측한 식이 성립한다. $$n\ge3$$에서 $$T(n)\le(d+b)\log_3n$$이므로 $$O(\log n)$$이다.

상한만 직접 검증하려면 $$T(n)\le C(1+\log_3n)$$을 추측해도 된다. $$C\ge\max(b,d)$$로 두면 기저에서 $$b\le C$$이고,

$$
T(n)\le C(1+\log_3(n/3))+d
=C\log_3n+d\le C(1+\log_3n).
$$

여기서 **$$1+\log n$$은 기저 입력을 포함시키기 위한 것**이다. $$T(1)>0$$인데 $$T(1)\le C\log_3 1=0$$을 요구하는 잘못된 귀납 기저를 피한다.

</details>

## 4. Master Theorem

원문 2쪽의 일곱 점화식에 다음 형태를 적용한다.

$$
T(n)=aT(n/b)+f(n),\qquad a\ge1,\quad b>1,\quad p=\log_ba.
$$

기저 비용은 $$\Theta(1)$$이고 $$f(n)$$은 충분히 큰 입력에서 음수가 아니라고 가정한다. 각 점화식은 우선 $$n$$이 해당 $$b$$의 거듭제곱인 입력에서 해석한다. 표준적인 바닥·천장 처리에도 아래 점근 결론은 유지된다.

- **Case 1:** 어떤 $$\varepsilon>0$$에 대해 $$f(n)=O(n^{p-\varepsilon})$$이면 $$T(n)=\Theta(n^p)$$.
- **Case 2:** $$f(n)=\Theta(n^p)$$이면 $$T(n)=\Theta(n^p\log n)$$. 이 과제에는 이 기본 형태만 필요하다.
- **Case 3:** 어떤 $$\varepsilon>0$$에 대해 $$f(n)=\Omega(n^{p+\varepsilon})$$이고, 어떤 $$c<1$$에 대해 $$af(n/b)\le cf(n)$$이면 $$T(n)=\Theta(f(n))$$.

왜 $$n^p$$와 비교하는가? 재귀 트리 높이는 $$\log_bn$$이며 잎 수는 $$a^{\log_bn}=n^{\log_ba}$$이다. 깊이 $$j$$의 비재귀 작업량은 $$a^jf(n/b^j)$$이다. 이것이 아래로 갈수록 증가하면 잎 부근이, 일정하면 모든 레벨의 합이, 기하급수적으로 감소하면 루트 부근이 총 비용을 결정한다.

### Answer Overview

| Item | a | b | f(n) | Critical power | Case | Tight bound |
| --- | --- | --- | --- | --- | --- | --- |
| 4(a) | 2 | 3 | $$n$$ | $$n^{\log_3 2}$$ | 3 | $$\Theta(n)$$ |
| 4(b) | 1 | 3 | $$n$$ | $$1$$ | 3 | $$\Theta(n)$$ |
| 4(c) | 4 | 2 | $$n$$ | $$n^2$$ | 1 | $$\Theta(n^2)$$ |
| 4(d) | 1 | 2 | $$1$$ | $$1$$ | 2 | $$\Theta(\log n)$$ |
| 4(e) | 4 | 2 | $$n^2$$ | $$n^2$$ | 2 | $$\Theta(n^2\log n)$$ |
| 4(f) | 8 | 2 | $$n^3$$ | $$n^3$$ | 2 | $$\Theta(n^3\log n)$$ |
| 4(g) | 5 | 5 | $$n^2$$ | $$n$$ | 3 | $$\Theta(n^2)$$ |

### 4(a). Two Subproblems and Linear Work

$$T(n)=2T(n/3)+n.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$2/3<1$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_3 2<1$$이다. $$\varepsilon=1-\log_3 2>0$$로 두면 $$f(n)=n=n^{p+\varepsilon}$$이다. 정규성 조건도

$$2f(n/3)=2n/3=(2/3)f(n)$$

으로 성립한다. $$c=2/3<1$$이므로 **$$T(n)=\Theta(n)$$**이다. 깊이 $$j$$의 작업은 $$n(2/3)^j$$로 감소한다. 그 합은 $$n$$ 이상 $$3n$$ 이하의 비재귀 비용이며, 잎 비용 $$\Theta(n^{\log_3 2})$$도 선형 상한 안에 들어간다.

</details>

### 4(b). One Subproblem and Linear Work

$$T(n)=T(n/3)+n.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$1/3<1$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_3 1=0$$이므로 임계 함수는 $$n^0=1$$이다. $$\varepsilon=1$$이면 $$f(n)=n=n^{p+\varepsilon}$$이며,

$$f(n/3)=n/3=(1/3)f(n).$$

따라서 Case 3으로 **$$T(n)=\Theta(n)$$**이다. 실제 레벨 비용도 $$n+n/3+n/9+\cdots$$의 기하급수이다. 문제 3과 달리 이 식의 $$+n$$은 비재귀 작업량이 선형이라고 **주어진 것**이다. 문제 3 코드의 `+ n`이라는 덧셈 한 번과 혼동하지 않는다.

</details>

### 4(c). Four Subproblems and Linear Work

$$T(n)=4T(n/2)+n.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2)$$. Master Theorem Case 1이며, 임계 지수는 $$2$$, 다항식 차이는 $$\varepsilon=1$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 4=2$$이다. $$f(n)=n=O(n^{2-1})$$이므로 $$\varepsilon=1$$을 택할 수 있다. Case 1에 따라 **$$T(n)=\Theta(n^2)$$**이다. 깊이 $$j$$의 작업은 $$4^j(n/2^j)=n2^j$$로 증가하며, 잎 수도 $$4^{\log_2 n}=n^2$$이다.

</details>

### 4(d). One Subproblem and Constant Work

$$T(n)=T(n/2)+1.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 상수이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 1=0$$이고 $$f(n)=1=\Theta(n^0)$$이다. Case 2에 따라 **$$T(n)=\Theta(\log n)$$**이다. 깊이는 $$\log_2n$$이고 각 비기저 레벨에서 1씩 더하므로, $$T(1)=b_0$$라면 정확히 $$T(n)=b_0+\log_2n$$이다.

</details>

### 4(e). Four Subproblems and Quadratic Work

$$T(n)=4T(n/2)+n^2.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 $$n^2$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=2$$이고 $$f(n)=n^2=\Theta(n^p)$$이므로 Case 2이다. 깊이 $$j$$에서

$$4^j(n/2^j)^2=n^2$$

의 비용이 든다. 같은 규모의 작업이 $$\log_2n$$개의 비기저 레벨에서 반복되므로 **$$T(n)=\Theta(n^2\log n)$$**이다. 잎의 총 비용 $$\Theta(n^2)$$를 더해도 이 결론은 유지된다.

</details>

### 4(f). Eight Subproblems and Cubic Work

$$T(n)=8T(n/2)+n^3.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^3\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 $$n^3$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 8=3$$이며 $$f(n)=n^3=\Theta(n^p)$$이다. Case 2가 적용된다. 깊이 $$j$$의 비용은

$$8^j(n/2^j)^3=n^3$$

으로 일정하다. 따라서 **$$T(n)=\Theta(n^3\log n)$$**이다. $$n^3$$은 한 레벨의 작업량이지 전체 트리의 작업량이 아니므로 로그 인자를 빠뜨리면 안 된다.

</details>

### 4(g). Five Subproblems and Quadratic Work

$$T(n)=5T(n/5)+n^2.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$1/5<1$$이다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_5 5=1$$이다. $$\varepsilon=1$$로 두면 $$f(n)=n^2=n^{p+\varepsilon}$$이며,

$$5f(n/5)=5(n/5)^2=n^2/5=(1/5)f(n).$$

$$c=1/5<1$$로 정규성 조건도 충족한다. 그러므로 **$$T(n)=\Theta(n^2)$$**이다. 레벨별 작업량은 $$n^2(1/5)^j$$로 감소한다. $$a=b$$라는 사실만으로 전체 복잡도를 선형이라고 판단할 수 없다. 비재귀 비용 $$f(n)$$까지 비교해야 한다.

</details>

## Review Checklist

- 기본 연산의 종류와 비용 모형을 먼저 고정했는가?
- 초기 대입문과 `+=`의 덧셈 횟수를 구분했는가?
- 점근 정의의 상수와 시작점을 제시하고 같은 구간에서 부등식을 증명했는가?
- 코드의 **재귀 호출 수**와 반환값의 계수를 구분했는가?
- 귀납 증명에 기저 단계와 귀납 단계를 모두 포함했는가?
- Master Theorem의 임계 지수, 다항식 차이, 필요한 정규성 조건을 확인했는가?

## Source

[Original Assignment PDF]({{ '/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf' | relative_url }}) · [Algorithms Study Notes]({{ '/study/algorithms/' | relative_url }})
