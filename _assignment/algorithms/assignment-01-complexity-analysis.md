---
layout: default
date: 2026-09-15 00:00:00 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Algorithms Assignment 1: Complexity Analysis and Recurrences"
course: "Algorithms"
topic: "Asymptotic Analysis and Recurrences"
order: 1
major_topic: "Algorithms"
keywords: [operation-counting, asymptotic-analysis, recurrence-relations, master-theorem]
---

# Algorithms Assignment 1: Complexity Analysis and Recurrences

## 원문 문제 먼저 읽기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf#page=1" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/assignment/algorithms/source-figures/assignment-01-p1-problems.jpg" | relative_url }}" alt="행렬 곱셈 연산 수, 점근 표기 증명, 재귀식 분석 문제를 제시한 과제 원문 첫 페이지" loading="lazy"></a>
  <figcaption>과제 원문 PDF p. 1. 문제 1의 코드, 문제 2의 증명 대상, 문제 3의 재귀 함수가 한 페이지에 제시됩니다.</figcaption>
</figure>

이 과제는 실행시간의 답만 적는 대신, **그 답이 어떻게 나오는지** 확인합니다. 행렬 곱셈에서는 기본 연산을 종류별로 세고, 점근 표기에서는 정의에 맞는 상수와 시작점을 찾습니다. 재귀 함수에서는 코드가 실제로 몇 번 호출되는지부터 확인합니다.

예를 들어 행렬 한 칸을 계산하려면 한 행과 한 열의 값을 차례로 곱하고 더합니다. 행렬 크기가 커질 때 이 작업이 몇 번 반복되는지 세면 실행시간 식을 만들 수 있습니다. 이후의 $$O$$, $$\Omega$$, $$\Theta$$는 각각 그 식의 성장 속도에 대한 상한, 하한, 양쪽이 일치하는 범위를 말합니다.

아래 해설은 원문의 요구 순서를 유지합니다. 그림의 문제 문구를 먼저 읽고, 각 풀이에서 무엇을 1회 연산으로 세는지와 어떤 가정을 사용했는지 대조합니다.

## Key Takeaways

**행렬 곱셈의 연산 횟수, 점근 표기법의 정의, 재귀 실행시간, Master Theorem을 연결하는 과제 해설입니다.** 원문의 4개 문제와 15개 소문항을 순서대로 다룹니다. 기존 문제지의 독립 풀이에 제공된 2026년 해답의 설명을 대조했습니다. 특히 3번은 의도한 재귀 구조와 기존 코드의 실제 호출 구조를 구분해야 합니다.

- 행렬 곱셈은 곱셈을 정확히 $$n^3$$번 수행하며 실행시간은 $$\Theta(n^3)$$입니다.
- 정의를 이용한 증명에서는 최고차항만 지목하지 않고 **양의 상수와 시작점**을 실제로 제시해야 합니다.
- 재귀 호출 3회와 선형 작업을 수행하면 $$\Theta(n\log n)$$입니다. 반면 `3 * fn(n / 3) + n`은 호출 **한 번**과 상수 작업이므로 $$\Theta(\log n)$$입니다. 제공된 해답은 두 코드 해석을 구분해 인정합니다.
- Master Theorem에서는 $$f(n)$$과 $$n^{\log_b a}$$를 비교합니다. Case 3은 정규성 조건까지 확인합니다.

## Original Material

[Original Assignment PDF]({{ '/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf' | relative_url }})

Source PDFs: [Assignment 1 instructions]({{ '/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf' | relative_url }}) · [Assignment 1 provided solutions]({{ '/assets/pdfs/assignment/algorithms/assignment-01-2026-solutions.pdf' | relative_url }})

원문: *2026 Fall Algorithms Assignment #1*, 2쪽. 1쪽의 문제 1–3과 2쪽의 문제 4를 다룹니다. 수치 연산을 상수 시간으로 세는 표준 단위 비용 모형을 사용합니다. 별도 표시가 없는 한 $$n$$은 양의 정수이며, 재귀식의 기저 비용은 양의 상수입니다.

## 1. Matrix Multiplication

원문 1쪽의 코드는 다음과 같습니다. 배열은 미리 준비되어 있고, 이 함수는 결과 배열 `M`을 채웁니다.

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

답변: 곱셈 $$n^3$$회, 덧셈 $$n^3-n^2$$회, 결과 원소 저장 $$n^3$$회입니다. 산술·저장을 각각 단위 비용으로 세면 총 $$3n^3-n^2$$회입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 먼저 무엇을 기본 연산으로 세는지 정합니다. 여기서는 **스칼라 곱셈, 스칼라 덧셈, 결과 원소 저장**을 각각 1회로 셉니다. `+=`는 덧셈 1회와 저장 1회로 분리합니다. 인덱싱 및 반복 제어 비용은 이 표와 구분합니다.

각 $$i,j$$ 쌍에 대해 첫 항을 한 번 계산하고, 나머지 $$n-1$$개 항을 더합니다. $$i,j$$ 쌍은 $$n^2$$개입니다.

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

**초기값을 0으로 설정한 뒤 모든 항을 더하는 코드가 아닙니다.** 따라서 덧셈을 $$n^3$$번으로 세면 출력 원소마다 1회씩 과대 계산합니다. $$n=1$$일 때 곱셈 1회, 덧셈 0회라는 경계값도 확인할 수 있습니다.

배열 접근까지 별도 기본 연산으로 세면 `A` 원소 읽기와 `B` 원소 읽기는 각각 $$n^3$$회, 기존 `M` 원소 읽기는 $$n^3-n^2$$회, `M` 원소 쓰기는 $$n^3$$회입니다. 이는 **원소 접근** 기준이며 Python 중첩 리스트의 개별 인덱싱 명령 수와 같다는 뜻은 아닙니다.

반복 제어도 포함해야 한다면 다음의 개념적 `initialize; test; advance` 모형을 추가할 수 있습니다. 종료를 판정하는 마지막 실패 검사도 셉니다.

| Loop | Initialization | Condition test | Advance |
| --- | --- | --- | --- |
| i | $$1$$ | $$n+1$$ | $$n$$ |
| j | $$n$$ | $$n(n+1)$$ | $$n^2$$ |
| k | $$n^2$$ | $$n^3$$ | $$n^2(n-1)$$ |

`k` 반복은 각 출력 원소에서 $$n-1$$회 진행하지만 검사는 $$n$$회 합니다. 이 표는 **분석용 반복 모형**입니다. Python의 `range`와 반복자에 실제로 이 형태의 비교·증가 명령이 실행된다고 주장하는 것은 아닙니다. 정확한 다항식 계수는 선택한 비용 모형에 따라 달라집니다.

</details>

### 1(b). Derive the Time Complexity

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^3)$$입니다. 산술 연산만 세면 $$2n^3-n^2$$회이며, 저장까지 세면 $$3n^3-n^2$$회입니다.

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

$$n\ge1$$에서 $$n^3\le2n^3-n^2\le2n^3$$이므로 산술 비용은 $$\Theta(n^3)$$입니다. 상수 시간 배열 접근과 반복 제어를 포함해도 총 비용은 $$O(n^3)$$이며, 곱셈만 이미 $$n^3$$회이므로 하한은 $$\Omega(n^3)$$입니다.

답변: **$$T(n)=\Theta(n^3)$$**. 특히 $$O(n^3)$$도 성립하지만, $$\Theta$$는 상한과 하한을 함께 표현합니다. 배열 할당 비용은 제시된 함수 바깥이며, 별도로 $$\Theta(n^2)$$ 비용을 추가하더라도 결론은 바뀌지 않습니다.

</details>

## 2. Proofs from Asymptotic Definitions

충분히 큰 $$n$$에서 함수가 음수가 아니라고 할 때, 정의는 다음과 같습니다.

$$
\begin{aligned}
f(n)\in O(g(n))&\iff\exists c>0,n_0:\ 0\le f(n)\le cg(n)\quad(n\ge n_0),\\
f(n)\in\Omega(g(n))&\iff\exists c>0,n_0:\ 0\le cg(n)\le f(n)\quad(n\ge n_0),\\
f(n)\in\Theta(g(n))&\iff\exists c_1,c_2>0,n_0:\ 0\le c_1g(n)\le f(n)\le c_2g(n)\quad(n\ge n_0).
\end{aligned}
$$

원문의 $$T(n)=O(g(n))$$ 표기는 관례적인 표현입니다. 여기서는 함수가 점근적 함수 집합에 속함을 드러내기 위해 $$\in$$도 사용합니다.

### 2(a). A Cubic Upper Bound

증명 대상: $$6n^3-15n^2+20\in O(n^3)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$6n^3-15n^2+20\in O(n^3)$$. 정의를 만족하는 상수는 $$c=6,\ n_0=3$$입니다.

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

따라서 모든 정수 $$n\ge3$$에 대해 $$0\le T(n)\le6n^3$$입니다. **$$c=6,n_0=3$$**이 정의를 만족하므로 $$T(n)\in O(n^3)$$입니다. 최소 상수나 최소 시작점을 찾을 필요는 없습니다.

</details>

### 2(b). A Quadratic Lower Bound

증명 대상: $$7n^2-4n\log_2n\in\Omega(n^2)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$7n^2-4n\log_2n\in\Omega(n^2)$$. 정의를 만족하는 상수는 $$c=3,\ n_0=1$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 양의 정수 $$n$$에서 $$\log_2n\le n$$임을 먼저 확인합니다. $$2^1\ge1$$이고, $$2^n\ge n$$이면

$$
2^{n+1}\ge2n\ge n+1\qquad(n\ge1).
$$

귀납법으로 $$2^n\ge n$$이며, 증가함수 $$\log_2$$를 적용하면 $$n\ge\log_2n$$입니다. 양수 $$4n$$을 곱하고 음수 부호를 적용할 때 부등호 방향에 주의하면

$$
-4n\log_2n\ge-4n^2.
$$

따라서

$$
T(n)=7n^2-4n\log_2n\ge7n^2-4n^2=3n^2>0.
$$

**$$c=3,n_0=1$$**이므로 $$T(n)\in\Omega(n^2)$$입니다. 음의 항을 무시하는 것은 하한 증명이 아닙니다. 그 항이 얼마나 많이 차감할 수 있는지 제어해야 합니다.

</details>

### 2(c). A Tight Quadratic Bound

증명 대상: $$3n^2+5n-2\in\Theta(n^2)$$.

<details markdown="block" open>
<summary>Answer</summary>

답변: $$3n^2+5n-2\in\Theta(n^2)$$. $$c_1=3,\ c_2=8,\ n_0=1$$로 잡으면 됩니다.

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

**$$c_1=3,c_2=8,n_0=1$$**로 양쪽 부등식이 같은 구간에서 성립합니다. 그러므로 $$T(n)\in\Theta(n^2)$$입니다.

</details>

## 3. A Single Recursive Call

기존 문제지 1쪽은 $$n=3^k$$인 양의 정수를 가정합니다. 따라서 $$k$$는 0 이상의 정수입니다. **제공된 해답 2–3쪽은 재귀 3회와 선형 작업이 출제 의도였으며, 아래 기존 코드의 단일 호출 해석도 인정한다고 설명합니다.** 해답에는 문제지의 코드 구조를 명확하게 수정했다는 안내가 있지만, 아래에 연결한 기존 문제지 PDF의 코드를 임의로 바꾸지는 않습니다.

### Intended Recurrence: Three Calls and Linear Work

입력 크기 $$n/3$$인 하위 문제 세 개를 각각 계산하고, 현재 호출에서 $$n$$만큼의 작업을 하면 실행시간은 다음과 같습니다. 여기서는 제공된 해답과 같이 기저 비용과 선형 작업의 계수를 1로 정규화합니다.

$$
T(1)=1,\qquad T(n)=3T(n/3)+n.
$$

**결과는 $$T(n)=n+n\log_3n=\Theta(n\log n)$$입니다.** 같은 레벨에 있는 하위 문제의 크기를 모두 더하면 매번 $$n$$이므로, 선형 작업을 재귀 깊이만큼 더합니다.

<details markdown="block">
<summary markdown="span">Derivation: Three calls, recursion levels, and induction</summary>

풀이과정: 깊이 $$j$$에는 $$3^j$$개의 호출이 있고 각각 $$n/3^j$$만큼 작업합니다. 따라서 한 레벨의 비용은 $$3^j(n/3^j)=n$$입니다. 비기저 레벨은 $$\log_3n$$개이고, 마지막에는 기저 호출이 $$n$$개 있습니다.

$$
T(n)=n\log_3n+n.
$$

반복 대입으로도 $$T(n)=3^jT(n/3^j)+jn$$을 얻습니다. $$j=\log_3n$$을 대입하면 같은 결과입니다. $$n=9$$일 때 기저 비용 9와 두 비기저 레벨의 비용 18을 더해 27입니다.

상한 $$T(n)\le2n\log_3n$$을 귀납법으로 확인할 때는 $$n=3$$에서 시작합니다. $$T(3)=6$$으로 기저가 성립하고, $$n\ge9$$에서 귀납 가정을 대입하면

$$
T(n)\le3\left(2\frac n3\log_3\frac n3\right)+n
=2n\log_3n-n\le2n\log_3n.
$$

$$n=1$$에서는 오른쪽이 0이므로 이 상한을 기저로 사용할 수 없습니다. 하한은 위의 정확한 전개에서 $$n\log_3n$$만 남겨 확인합니다.

</details>

### Literal Code: One Call and Constant Work

아래 코드는 세 번 호출하지 않습니다. 호출 결과에 3을 곱하는 연산과, 같은 함수를 세 번 실행하는 연산은 다릅니다. 이어지는 3(a)–3(c)는 이 기존 코드의 실행시간 풀이입니다.

```python
def fn(n):
    if n <= 1:
        return 1
    else:
        return 3 * fn(n / 3) + n
```

<details markdown="block">
<summary markdown="span">Answer map: intended recurrence, literal runtime, and return value</summary>

**Supplementary table.** 같은 `3`과 `n`이 보여도 반환값 식과 실행시간 식은 세는 대상이 다릅니다. 다음 표는 제공된 해답의 의도와 문제지의 literal code를 한 위치에서 구분합니다. 반환값 행은 문제지처럼 $$F(1)=1$$을 가정합니다.

| 해석 | 크기 $$n/3$$ 재귀 호출 수 | 현재 호출의 실행 작업 | 점화식 | $$n=3^k$$ 결과 |
|---|---:|---|---|---|
| Intended algorithm의 시간 | 3 | 선형 작업 $$n$$ | $$T(n)=3T(n/3)+n$$ | 시간 $$\Theta(n\log n)$$ |
| Literal code의 시간 | 1 | 조건·나눗셈·곱셈·덧셈의 상수 개 | $$T(n)=T(n/3)+\Theta(1)$$ | 시간 $$\Theta(\log n)$$ |
| Literal code의 반환값 | 실행시간 대상 아님 | 재귀 결과에 3을 곱하고 $$n$$을 더함 | $$F(n)=3F(n/3)+n$$ | 값 $$F(n)=n(1+\log_3n)$$ |

표의 첫 열을 먼저 고른 뒤 아래 풀이를 읽어야 합니다. `3 * fn(...)`은 함수를 한 번 실행해 얻은 **값**을 세 배로 만들 뿐, 호출을 세 번 생성하지 않습니다. 반대로 intended algorithm은 실제로 세 하위 호출을 수행한다고 가정합니다.

</details>

### 3(a). Build the Runtime Recurrence

<details markdown="block" open>
<summary>Answer</summary>

답변: 실행시간 점화식은 $$T(1)=b,\ T(n)=T(n/3)+d$$입니다($$b,d>0$$). 재귀 호출은 한 번이며, 반환값의 점화식과 구분합니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: `fn(n / 3)`을 한 번 호출한 뒤, 그 반환값에 곱셈 1회와 덧셈 1회를 수행합니다. 조건 검사와 인자 나눗셈도 상수 비용입니다. 비기저 호출의 자체 비용을 $$d>0$$, 기저 호출 비용을 $$b>0$$라 두면

$$
T(1)=b,\qquad T(n)=T(n/3)+d\quad(n>1).
$$

비용을 정확한 상수로 고정하지 않는 일반적인 표기는 $$T(n)=T(n/3)+\Theta(1)$$입니다. **$$3T(n/3)+n$$은 이 코드의 실행시간 점화식이 아닙니다.** `+ n`은 반복문이 아니라 덧셈 한 번이며, 앞의 `3 *`도 호출 수를 늘리지 않습니다.

반환값을 별도 함수 $$F(n)$$으로 정의하면 오히려

$$
F(1)=1,\qquad F(n)=3F(n/3)+n
$$

입니다. 양변을 $$n$$으로 나누면 $$F(n)/n=F(n/3)/(n/3)+1$$입니다. 이를 $$k=\log_3n$$번 전개하여

$$
F(n)=n(1+\log_3n)
$$

을 얻습니다. 예컨대 $$n=9$$이면 반환값은 27이지만 함수 호출은 `fn(9)`, `fn(3)`, `fn(1)`의 3회입니다. **출력 수치의 크기와 연산 횟수는 다른 대상**입니다.

분석은 단위 비용 모형에 따릅니다. 실제 Python의 `/`는 부동소수점 값을 만들므로 매우 큰 입력의 정확한 정수 재귀를 시험할 때는 `n // 3`을 사용할 수 있습니다. 임의 정밀도 정수의 비트 연산 비용까지 세는 분석은 여기서 가정한 비용 모형과 다릅니다.

</details>

### 3(b). Iterative Substitution

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=b+d\log_3n\in O(\log n)$$이며, 더 정확히는 $$\Theta(\log n)$$입니다. 반복 대입은 $$\log_3n$$단계에서 기저에 도달합니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 같은 식을 재귀 항에 반복 대입합니다.

$$
\begin{aligned}
T(n)&=T(n/3)+d\\
&=T(n/3^2)+2d\\
&=T(n/3^3)+3d\\
&=T(n/3^j)+jd.
\end{aligned}
$$

기저 입력에 도달하는 조건은 $$n/3^j=1$$이므로 $$j=\log_3n=k$$입니다. 따라서

$$
T(n)=T(1)+d\log_3n=b+d\log_3n.
$$

$$n\ge3$$에서는 $$\log_3n\ge1$$이므로

$$
d\log_3n\le T(n)\le(b+d)\log_3n.
$$

답변: **$$T(n)\in O(\log n)$$**, 더 정확히는 $$\Theta(\log n)$$입니다. 로그의 밑은 상수배만 바꾸므로 점근 분류에 영향을 주지 않습니다. 호출 스택의 최대 깊이도 $$k+1$$이므로 추가 스택 공간은 $$\Theta(\log n)$$입니다.

</details>

### 3(c). Guess and Verification

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(3^k)=dk+b$$라는 추측을 귀납법으로 검증하면 $$T(n)\in O(\log n)$$을 얻습니다. 기저 $$k=0$$과 귀납 단계를 모두 확인합니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: 입력이 매번 3분의 1이 되므로 $$T(n)=d\log_3n+b$$를 추측합니다. $$n=3^k$$에 대해 $$T(3^k)=dk+b$$를 귀납법으로 검증합니다.

**기저 단계:** $$k=0$$이면 $$T(3^0)=T(1)=b=d\cdot0+b$$입니다.

**귀납 가정:** 어떤 $$k\ge0$$에서 $$T(3^k)=dk+b$$라고 가정합니다.

**귀납 단계:** 점화식에 대입하면

$$
T(3^{k+1})=T(3^k)+d=(dk+b)+d=d(k+1)+b.
$$

따라서 모든 $$k\ge0$$에서 추측한 식이 성립합니다. $$n\ge3$$에서 $$T(n)\le(d+b)\log_3n$$이므로 $$O(\log n)$$입니다.

상한만 직접 검증하려면 $$T(n)\le C(1+\log_3n)$$을 추측해도 됩니다. $$C\ge\max(b,d)$$로 두면 기저에서 $$b\le C$$이고,

$$
T(n)\le C(1+\log_3(n/3))+d
=C\log_3n+d\le C(1+\log_3n).
$$

여기서 **$$1+\log n$$은 기저 입력을 포함시키기 위한 것**입니다. $$T(1)>0$$인데 $$T(1)\le C\log_3 1=0$$을 요구하는 잘못된 귀납 기저를 피합니다.

</details>

## 4. Master Theorem

원문 2쪽의 일곱 점화식에 다음 형태를 적용합니다.

$$
T(n)=aT(n/b)+f(n),\qquad a\ge1,\quad b>1,\quad p=\log_ba.
$$

기저 비용은 $$\Theta(1)$$이고 $$f(n)$$은 충분히 큰 입력에서 음수가 아니라고 가정합니다. 각 점화식은 우선 $$n$$이 해당 $$b$$의 거듭제곱인 입력에서 해석합니다. 표준적인 바닥·천장 처리에도 아래 점근 결론은 유지됩니다.

- **Case 1:** 어떤 $$\varepsilon>0$$에 대해 $$f(n)=O(n^{p-\varepsilon})$$이면 $$T(n)=\Theta(n^p)$$.
- **Case 2:** $$f(n)=\Theta(n^p)$$이면 $$T(n)=\Theta(n^p\log n)$$. 이 과제에는 이 기본 형태만 필요합니다.
- **Case 3:** 어떤 $$\varepsilon>0$$에 대해 $$f(n)=\Omega(n^{p+\varepsilon})$$이고, 어떤 $$c<1$$에 대해 $$af(n/b)\le cf(n)$$이면 $$T(n)=\Theta(f(n))$$.

왜 $$n^p$$와 비교합니까? 재귀 트리 높이는 $$\log_bn$$이며 잎 수는 $$a^{\log_bn}=n^{\log_ba}$$입니다. 깊이 $$j$$의 비재귀 작업량은 $$a^jf(n/b^j)$$입니다. 이것이 아래로 갈수록 증가하면 잎 부근이, 일정하면 모든 레벨의 합이, 기하급수적으로 감소하면 루트 부근이 총 비용을 결정합니다.

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

답변: $$T(n)=\Theta(n)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$2/3<1$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_3 2<1$$입니다. $$\varepsilon=1-\log_3 2>0$$로 두면 $$f(n)=n=n^{p+\varepsilon}$$입니다. 정규성 조건도

$$2f(n/3)=2n/3=(2/3)f(n)$$

으로 성립합니다. $$c=2/3<1$$이므로 **$$T(n)=\Theta(n)$$**입니다. 깊이 $$j$$의 작업은 $$n(2/3)^j$$로 감소합니다. 그 합은 $$n$$ 이상 $$3n$$ 이하의 비재귀 비용이며, 잎 비용 $$\Theta(n^{\log_3 2})$$도 선형 상한 안에 들어갑니다.

</details>

### 4(b). One Subproblem and Linear Work

$$T(n)=T(n/3)+n.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$1/3<1$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_3 1=0$$이므로 임계 함수는 $$n^0=1$$입니다. $$\varepsilon=1$$이면 $$f(n)=n=n^{p+\varepsilon}$$이며,

$$f(n/3)=n/3=(1/3)f(n).$$

따라서 Case 3으로 **$$T(n)=\Theta(n)$$**입니다. 실제 레벨 비용도 $$n+n/3+n/9+\cdots$$의 기하급수입니다. 문제 3과 달리 이 식의 $$+n$$은 비재귀 작업량이 선형이라고 **주어진 것**입니다. 문제 3 코드의 `+ n`이라는 덧셈 한 번과 혼동하지 않습니다.

</details>

### 4(c). Four Subproblems and Linear Work

$$T(n)=4T(n/2)+n.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2)$$. Master Theorem Case 1이며, 임계 지수는 $$2$$, 다항식 차이는 $$\varepsilon=1$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 4=2$$입니다. $$f(n)=n=O(n^{2-1})$$이므로 $$\varepsilon=1$$을 택할 수 있습니다. Case 1에 따라 **$$T(n)=\Theta(n^2)$$**입니다. 깊이 $$j$$의 작업은 $$4^j(n/2^j)=n2^j$$로 증가하며, 잎 수도 $$4^{\log_2 n}=n^2$$입니다.

</details>

### 4(d). One Subproblem and Constant Work

$$T(n)=T(n/2)+1.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 상수입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 1=0$$이고 $$f(n)=1=\Theta(n^0)$$입니다. Case 2에 따라 **$$T(n)=\Theta(\log n)$$**입니다. 깊이는 $$\log_2n$$이고 각 비기저 레벨에서 1씩 더하므로, $$T(1)=b_0$$라면 정확히 $$T(n)=b_0+\log_2n$$입니다.

</details>

### 4(e). Four Subproblems and Quadratic Work

$$T(n)=4T(n/2)+n^2.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 $$n^2$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=2$$이고 $$f(n)=n^2=\Theta(n^p)$$이므로 Case 2입니다. 깊이 $$j$$에서

$$4^j(n/2^j)^2=n^2$$

의 비용이 듭니다. 같은 규모의 작업이 $$\log_2n$$개의 비기저 레벨에서 반복되므로 **$$T(n)=\Theta(n^2\log n)$$**입니다. 잎의 총 비용 $$\Theta(n^2)$$를 더해도 이 결론은 유지됩니다.

</details>

### 4(f). Eight Subproblems and Cubic Work

$$T(n)=8T(n/2)+n^3.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^3\log n)$$. Master Theorem Case 2이며, 각 레벨의 작업량이 $$n^3$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_2 8=3$$이며 $$f(n)=n^3=\Theta(n^p)$$입니다. Case 2가 적용됩니다. 깊이 $$j$$의 비용은

$$8^j(n/2^j)^3=n^3$$

으로 일정합니다. 따라서 **$$T(n)=\Theta(n^3\log n)$$**입니다. $$n^3$$은 한 레벨의 작업량이지 전체 트리의 작업량이 아니므로 로그 인자를 빠뜨리면 안 됩니다.

</details>

### 4(g). Five Subproblems and Quadratic Work

$$T(n)=5T(n/5)+n^2.$$

<details markdown="block" open>
<summary>Answer</summary>

답변: $$T(n)=\Theta(n^2)$$. Master Theorem Case 3이며, 정규성 조건의 비율은 $$1/5<1$$입니다.

</details>

<details markdown="block">
<summary>Derivation</summary>

풀이과정: $$p=\log_5 5=1$$입니다. $$\varepsilon=1$$로 두면 $$f(n)=n^2=n^{p+\varepsilon}$$이며,

$$5f(n/5)=5(n/5)^2=n^2/5=(1/5)f(n).$$

$$c=1/5<1$$로 정규성 조건도 충족합니다. 그러므로 **$$T(n)=\Theta(n^2)$$**입니다. 레벨별 작업량은 $$n^2(1/5)^j$$로 감소합니다. $$a=b$$라는 사실만으로 전체 복잡도를 선형이라고 판단할 수 없습니다. 비재귀 비용 $$f(n)$$까지 비교해야 합니다.

</details>

## Review Checklist

- 기본 연산의 종류와 비용 모형을 먼저 고정했습니까?
- 초기 대입문과 `+=`의 덧셈 횟수를 구분했습니까?
- 점근 정의의 상수와 시작점을 제시하고 같은 구간에서 부등식을 증명했습니까?
- 코드의 **재귀 호출 수**와 반환값의 계수를 구분했습니까?
- 귀납 증명에 기저 단계와 귀납 단계를 모두 포함했습니까?
- Master Theorem의 임계 지수, 다항식 차이, 필요한 정규성 조건을 확인했습니까?

## Source

[Original Assignment PDF]({{ '/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf' | relative_url }}) · [Provided Solutions PDF]({{ '/assets/pdfs/assignment/algorithms/assignment-01-2026-solutions.pdf' | relative_url }}) · [Algorithms Study Notes]({{ '/study/algorithms/' | relative_url }})
