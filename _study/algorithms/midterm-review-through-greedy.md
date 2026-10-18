---
layout: default
date: 2026-10-14 13:20:00 +0900
last_modified_at: 2026-10-18 16:43:00 +0900
title: "Algorithms Midterm Review: Analysis through Greedy Algorithms"
course: "Algorithms"
topic: "Comprehensive Review from Algorithm Analysis through Greedy Algorithms"
order: 12
major_topic: "Data Structures & Algorithms"
keywords:
  - "Algorithm Analysis"
  - "Practice"
  - "Asymptotic Notation"
  - "Master Theorem"
  - "Sorting"
  - "Selection"
  - "Dynamic Programming"
  - "Greedy Algorithms"
---

# Algorithms Midterm Review: Analysis through Greedy Algorithms

Source PDFs:

- [Lecture 2: Algorithm Analysis](/assets/pdfs/study/algorithms/02-algorithm-analysis.pdf)
- [Lecture 3: Recurrence](/assets/pdfs/study/algorithms/03-recurrence.pdf)
- [Lecture 4: Sorting (1)](/assets/pdfs/study/algorithms/04-sorting-01.pdf)
- [Lecture 5: Sorting (2)](/assets/pdfs/study/algorithms/05-sorting-02.pdf)
- [Lecture 6: Sorting (3)](/assets/pdfs/study/algorithms/06-sorting-03.pdf)
- [Lecture 7: Sorting (4)](/assets/pdfs/study/algorithms/lecture-07-sorting-04.pdf)
- [Lecture 8: Selection](/assets/pdfs/study/algorithms/lecture-08-selection.pdf)
- [Lecture 9: Dynamic Programming (1)](/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf)
- [Lecture 10: Dynamic Programming (2)](/assets/pdfs/study/algorithms/lecture-10-dynamic-programming-02.pdf)
- [Lecture 11: Greedy Algorithm](/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf)
- [Assignment 1 Instructions](/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf)
- [Assignment 1 Solutions](/assets/pdfs/assignment/algorithms/assignment-01-2026-solutions.pdf)

> **핵심:** 알고리즘 분석은 코드가 실제로 수행하는 기본 연산을 세는 데서 시작한다. 점화식은 재귀 호출 수와 호출 밖 작업을 분리하고, 정렬·선택·동적 계획법·그리디에서는 각 단계가 보존하는 불변식과 최적성 조건을 확인한다. 결론만 외우지 말고 **입력·출력, 상태 또는 활성 구간, 적용 조건, 반례**를 한 묶음으로 설명할 수 있어야 한다.

Lecture 11의 4쪽은 시험 범위를 첫 내용부터 Greedy Algorithm까지로 명시한다. 현재 확보된 강의 자료는 Lecture 2–11이며, Lecture 1의 세부 내용은 자료 없이 추정하지 않는다. Assignment 1·2는 범위 개념을 적용하는 연습으로 포함했다. 아래 Original Practice는 Lecture 2 원문 문제이고, 그 밖의 새 배열·수치 예시는 **작성자가 구성하고 직접 계산한 연습 예제**다.

## 대표 원본 그림

Lecture 9의 Matrix Path 그림은 DP에서 상태, 이전 상태, 계산 순서를 한 번에 보여 준다.

<figure class="study-source-figure">
  <img src="{{ "/assets/images/study/algorithms/source-figures/lecture-09-p19-matrix-path.jpg" | relative_url }}" alt="Matrix Path의 경로와 bottom-up 점화식을 함께 보여 주는 강의 원본 슬라이드" loading="lazy">
  <figcaption>대표 원본: Lecture 9 PDF p. 19. 상태 정의, 이전 상태, 계산 순서를 한 장에서 대조한다.</figcaption>
</figure>

그림의 경로를 따라 현재 칸으로 들어오는 마지막 선택을 먼저 나누면 점화식을 외우지 않고 다시 만들 수 있다. §5에서는 이 원리를 상태·기저 사례·계산 순서로 나눠 적용한다.

## Original Practice

먼저 [Lecture 2의 Practice 원문 28쪽](/assets/pdfs/study/algorithms/02-algorithm-analysis.pdf#page=28)을 풀고, 아래 해설에서 **계산한 값과 계산에 쓴 연산 수**를 따로 확인한다. 세 문항 모두 제공된 정답 페이지는 없으며, 해설은 강의 9쪽의 비용 모형에 따라 도출하고 검산한 작성자 풀이다.

| Source | Question | Review |
|---|---|---|
| Lecture 2, p. 28, Ex1 | 한 번의 대입은 무엇에 비례하는가? | [Assignment](#practice-assignment) |
| Lecture 2, p. 28, Ex2 | 누적 결과와 반복 횟수는 어떻게 다른가? | [Accumulation](#practice-accumulation) |
| Lecture 2, p. 28, Ex3 | 길이가 늘어나는 안쪽 반복과 뒤의 독립 반복을 어떻게 세는가? | [Triangular Loop](#practice-triangular-loop) |

세 문항을 푼 뒤 점화식, 정렬의 단계별 입출력, DP 상태·점화식 설계로 범위를 넓힌다.

## 전체 흐름

| 범위 | 핵심 질문 | 이 글의 결과 |
|---|---|---|
| Lecture 2 | 무엇을 세고 어떤 bound를 말하는가? | 비용 모형, case와 점근 표기의 분리, 정식 정의 |
| Lecture 3 | 재귀 비용을 어떻게 푸는가? | 반복 대입, 귀납, Master Theorem의 세 경우와 조건 |
| Lecture 4–7 | 정렬 과정에서 무엇이 확정되는가? | 8개 정렬의 trace, 안정성, in-place 조건, 복잡도 |
| Lecture 8 | 정렬 없이 순위 원소를 찾을 수 있는가? | Quickselect의 최악·기대 시간과 Median of Medians |
| Lecture 9–10 | 상태와 점화식을 어떻게 설계하는가? | 기저·sentinel·순서·답·복원을 포함한 DP 설계 |
| Lecture 11 | 지역 선택이 언제 전역 최적해가 되는가? | 동전 교환과 회의 배정의 교환 논증, 반례 |
| Assignment 1 | 분석 정의와 재귀 해석을 적용할 수 있는가? | 제공된 해답의 상수, Q3 두 해석, 7개 Master 사례 |
| Assignment 2 | trace와 DP 상태를 구현으로 연결할 수 있는가? | 4개 정렬 출력 시점, 좌석 DP, unbounded knapsack |

## 1. Algorithm Analysis: 먼저 비용 모형을 고정한다

알고리즘은 입력과 출력의 관계를 계산하는 절차다. 시간 복잡도 $$T(n)$$을 말하려면 먼저 입력 크기 $$n$$과 기본 연산을 정의해야 한다. Lecture 2는 산술, 대입, 비교를 기본 연산의 예로 든다. 같은 코드라도 배열 접근, 반복 제어, 함수 호출을 별도 비용으로 세면 정확한 다항식은 달라질 수 있지만, 각 연산이 상수 시간이라는 같은 RAM 비용 모형에서는 점근 차수가 보통 유지된다.

예를 들어 다음 두 반복은 모두 배열 원소에 상수 시간 작업을 한다.

```text
for i = 0 .. n-1:          n회
for i = 0 .. n-1:
    for j = 0 .. n-1:      n^2회
```

따라서 첫 코드는 $$T(n)=an+b=\Theta(n)$$, 둘째는 $$T(n)=an^2+bn+c=\Theta(n^2)$$다. 계수 $$a,b,c$$를 생략하는 이유는 값이 없어서가 아니라, 충분히 큰 $$n$$에서 성장률을 비교하는 목적에 상수배가 영향을 주지 않기 때문이다.

### 1.1 정확한 횟수, case, 점근 표기는 서로 다른 축이다

- **정확한 횟수:** 선택한 비용 모형에서 몇 번 실행되는가.
- **Best/Worst/Average case:** 같은 크기의 입력 중 어떤 입력 집합을 보는가.
- **Big-O/$$\Omega$$/$$\Theta$$:** 함수 사이의 점근적 상한·하한·tight bound를 말한다.

따라서 “worst case = Big-O”는 정의가 아니다. 예를 들어 삽입 정렬의 worst-case 실행시간은 $$\Theta(n^2)$$이며, 이 함수는 동시에 $$O(n^3)$$이기도 하다. 가장 유용한 표현은 상·하한이 맞는 $$\Theta(n^2)$$다. Average case에는 입력 분포가 필요하다. 분포를 지정하지 않은 “평균”은 수학적 기대값으로 정의되지 않는다.

### 1.2 점근 표기의 정식 정의

충분히 큰 $$n$$에서 $$f(n),g(n)$$이 음수가 아니라고 가정한다.

$$
\begin{aligned}
f(n)\in O(g(n))
&\iff \exists c>0,n_0:\ 0\le f(n)\le cg(n)\quad(n\ge n_0),\\
f(n)\in \Omega(g(n))
&\iff \exists c>0,n_0:\ 0\le cg(n)\le f(n)\quad(n\ge n_0),\\
f(n)\in \Theta(g(n))
&\iff \exists c_1,c_2>0,n_0:\
0\le c_1g(n)\le f(n)\le c_2g(n)\quad(n\ge n_0).
\end{aligned}
$$

이 식들은 **정의**다. 상수와 시작점을 실제로 제시해야 정의를 이용한 증명이 끝난다.

<details markdown="block">
<summary markdown="span">Derivation: Why $$3n^2+5n-2\in\Theta(n^2)$$</summary>

작성자 검산: $$n\ge2$$이면 $$5n-2\ge0$$이므로

$$
3n^2\le3n^2+5n-2.
$$

또한 $$n\le n^2$$이고 $$-2\le0$$이므로

$$
3n^2+5n-2\le3n^2+5n^2=8n^2.
$$

제공된 Assignment 1 해답은 더 느슨한 하한 $$2n^2$$을 사용하여 $$c_1=2,c_2=8,n_0=2$$를 제시한다. 둘 다 정의를 만족한다. 점근 증명은 최소 상수나 최소 시작점을 찾는 문제가 아니다.

</details>

성장률은 보통 다음 순서로 커진다.

$$
1\prec\log n\prec n\prec n\log n\prec n^2\prec n^3\prec c^n\prec n!
\qquad(c>1).
$$

### 1.3 Practice: Code, Result, and Cost

공통 조건은 $$n\ge0$$인 정수와 단위 비용 산술이다. **산술과 대입은 각각 1회**, 반복문의 제어 변수 초기화·조건 검사·증감은 제외한다. 따라서 본문의 `sum++`은 덧셈과 대입 2회지만, 반복 제어인 `i++`는 여기서 세지 않는다. 이는 선택한 계수 규칙이지 실제 컴퓨터에서 반복 제어가 무료라는 뜻은 아니다. 정수 overflow와 메모리 접근 실패는 없다고 가정한다.

#### Ex1: Assignment
{: #practice-assignment}

```c
a = b;
```

입력 `b`를 `a`에 복사한다. 대입 뒤의 값과 실행한 연산 수를 각각 말해 보자.

<details markdown="block">
<summary markdown="span">Answer: Assignment</summary>

종료 후 `a == b`다. 대입은 한 번이므로 $$T(n)=1\in\Theta(1)$$이다. 이 코드에는 입력 크기에 따라 늘어나는 반복이 없다.

</details>

#### Ex2: Accumulation
{: #practice-accumulation}

```c
sum = 0;
for (i = 0; i < n; i++)
    sum += n;
```

`n`을 한 번 더하는 것과 본문을 `n`번 실행하는 것을 구분한다. 종료값이 크다는 이유만으로 연산 수도 그만큼 크다고 판단하면 안 된다.

<details markdown="block">
<summary markdown="span">Answer: Accumulation</summary>

종료 후 $$\texttt{sum}=n^2$$이지만, $$T(n)=2n+1\in\Theta(n)$$이다. **계산 결과는 이차식이고 실행시간은 선형**이다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Value versus operation count</summary>

초기 대입 `sum = 0`이 1회다. 본문은 $$n$$번 실행되며 `sum += n`은 `sum = sum + n`이므로 매번 덧셈과 대입을 한 번씩 수행한다.

$$
T(n)=1+\sum_{i=0}^{n-1}2=1+2n.
$$

반면 `sum`에는 $$n$$이 $$n$$번 더해진다. $$n=3$$이면 `sum`은 `0, 3, 6, 9`로 변하고 연산 수는 $$1+2\times3=7$$이다. $$n=0$$에서는 본문이 실행되지 않아 종료값은 0, 비용은 초기 대입 1회다.

정식 tight bound도 짧게 확인할 수 있다. $$n\ge1$$이면 $$2n\le2n+1\le3n$$이므로 $$c_1=2,c_2=3,n_0=1$$을 택하면 된다.

</details>

#### Ex3: Triangular Loop
{: #practice-triangular-loop}

```c
for (j = 1; j <= n; j++)
    for (i = 1; i <= j; i++)
        sum++;

for (k = 0; k < n; k++)
    A[k] = k;
```

원문에는 `sum` 초기화가 없다. 아래에서는 **이미 초기화된 값이 $$s_0$$**이고, `A`에 적어도 $$n$$칸이 있다고 가정한다. 초기화 코드를 새로 삽입해 원문의 연산 수에 더하지 않는다. C의 초기화하지 않은 자동 지역 변수라면 `sum++`을 실행하는 경우 정상적인 결과를 보장할 수 없다.

<details markdown="block">
<summary markdown="span">Answer: Triangular Loop</summary>

강의 비용 모형에서 $$T(n)=n^2+2n\in\Theta(n^2)$$이다. 종료 상태는

$$
\texttt{sum}=s_0+\frac{n(n+1)}{2}.
$$

$$
A[k]=k\quad(0\le k<n).
$$

두 번째 반복은 첫 중첩 반복 **뒤에** 실행된다. 두 비용을 곱하지 않고 더한다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Count iterations before counting operations</summary>

`j`가 1, 2, …, $$n$$일 때 `sum++`은 각각 1, 2, …, $$n$$번 실행된다. 이 합을 정순·역순으로 더하면 $$n$$쌍이 모두 $$n+1$$이므로

$$
S=\sum_{j=1}^{n}j=\frac{n(n+1)}{2}.
$$

여기서 $$S$$는 본문 실행 횟수다. 본문당 덧셈·대입 2회와 뒤의 배열 대입 $$n$$회를 따로 적용하면

$$
T(n)=2S+n=n(n+1)+n=n^2+2n.
$$

$$n=3,s_0=0$$일 때는 다음과 같다. 표의 비용은 해당 단계만의 비용이다.

| Stage | Body executions | Result | Operations |
|---|---:|---|---:|
| `j = 1` | 1 | `sum = 1` | 2 |
| `j = 2` | 2 | `sum = 3` | 4 |
| `j = 3` | 3 | `sum = 6` | 6 |
| Array loop | 3 | `A = [0, 1, 2]` | 3 |
| Total | 9 | `sum = 6` | 15 |

$$n\ge1$$이면 $$n^2\le n^2+2n\le3n^2$$이므로 $$c_1=1,c_2=3,n_0=1$$로 $$\Theta(n^2)$$를 증명한다. $$n=0$$에서는 두 반복 모두 실행되지 않아 비용은 0이다.

`sum++` 전체를 하나의 갱신으로 세는 **다른** 비용 모형에서는 $$S+n$$이다. 정확식은 달라지지만 점근 차수는 같다. Ex2에서 산술·대입을 나눠 세었다면 Ex3에서도 같은 기준을 유지해야 한다.

</details>

## 2. Recurrence: 호출 수와 호출 밖 작업을 분리한다

재귀 알고리즘의 실행시간은 보통 다음 형태로 쓴다.

$$
T(n)=aT(n/b)+f(n).
$$

$$a$$는 재귀 호출 개수, $$n/b$$는 각 호출의 입력 크기, $$f(n)$$은 현재 호출이 재귀 밖에서 수행하는 총 작업이다. 반환값 앞의 숫자와 호출 개수는 같지 않다. 코드의 `3 * fn(n/3)`은 `fn`을 한 번 호출한 뒤 결과에 3을 곱한다.

### 2.1 반복 대입과 귀납 검증

$$T(n)=2T(n/2)+n$$, $$T(1)=d$$이고 $$n=2^k$$라 하자. $$j$$번 펼치면

$$
T(n)=2^jT(n/2^j)+jn.
$$

$$j=\log_2n$$이면 기저 입력이 1이고 잎이 $$n$$개이므로

$$
T(n)=nd+n\log_2n=\Theta(n\log n).
$$

반복 대입은 답을 발견하는 데 쓰고, 추측한 상·하한은 귀납법으로 검증할 수 있다. 귀납식이 닫히지 않으면 더 강한 가설이 필요할 수 있다. Lecture 3의 $$T(n)=2T(n/2)+1$$에서 단순한 $$T(n)\le cn$$보다 $$T(n)\le cn-1$$ 같은 강한 형태가 대입 후 상수항을 흡수하기 쉽다.

### 2.2 Master Theorem의 세 경우와 조건

$$T(n)=aT(n/b)+f(n)$$에서 $$a\ge1$$, $$b>1$$이고, 기저 비용은 $$\Theta(1)$$, $$f(n)$$은 충분히 큰 입력에서 음수가 아니라고 가정한다. 임계 함수는

$$
h(n)=n^{\log_ba}
$$

다. 잎 수가 $$a^{\log_bn}=n^{\log_ba}$$이므로 이 함수가 재귀가 만드는 고유 비용을 나타낸다.

| Case | 비교 조건 | 추가 조건 | 결론 |
|---|---|---|---|
| 1 | 어떤 $$\varepsilon>0$$에 대해 $$f(n)=O(n^{\log_ba-\varepsilon})$$ | 다항식 차이 필요 | $$T(n)=\Theta(n^{\log_ba})$$ |
| 2 | $$f(n)=\Theta(n^{\log_ba})$$ | 이 강의·과제의 기본형 | $$T(n)=\Theta(n^{\log_ba}\log n)$$ |
| 3 | 어떤 $$\varepsilon>0$$에 대해 $$f(n)=\Omega(n^{\log_ba+\varepsilon})$$ | 어떤 $$c<1$$에 대해 $$af(n/b)\le cf(n)$$ | $$T(n)=\Theta(f(n))$$ |

단순히 “더 크다”는 말로는 부족하다. Case 1·3에는 **다항식 차이**가 필요하고, Case 3에는 정규성 조건이 필요하다. 예를 들어 $$f(n)=n^{\log_ba}\log n$$은 임계 함수보다 크지만 기본 Case 3의 다항식 차이를 만족하지 않는다.

<details markdown="block">
<summary markdown="span">Derivation: Three representative Master cases</summary>

1. $$T(n)=4T(n/2)+n$$: 임계 함수는 $$n^{\log_24}=n^2$$다. $$n=O(n^{2-1})$$이므로 Case 1, 결과는 $$\Theta(n^2)$$다.
2. $$T(n)=4T(n/2)+n^2$$: $$f(n)=\Theta(n^2)$$이므로 Case 2, 결과는 $$\Theta(n^2\log n)$$다.
3. $$T(n)=5T(n/5)+n^2$$: 임계 함수는 $$n$$이고 $$f(n)=n^2$$다. 또한

$$
5f(n/5)=5(n/5)^2=\frac15n^2.
$$

정규성 조건에서 $$c=1/5<1$$을 쓸 수 있으므로 Case 3, 결과는 $$\Theta(n^2)$$다.

</details>

## 3. Sorting: 출력 배열과 확정 구간을 함께 추적한다

정렬 입력은 키 배열 $$A[0:n)$$이고, 출력은 입력과 같은 다중집합을 가지며 오름차순인 배열이다. **Stable** 정렬은 같은 키를 가진 레코드의 상대 순서를 보존한다. **In-place**는 보통 입력 배열 밖의 보조 메모리를 $$O(1)$$만 쓰는 구현을 뜻한다. 재귀 stack을 별도로 세는지 명시해야 한다.

### 3.1 전체 비교

비교 정렬의 Average는 서로 다른 키의 모든 입력 순열이 균등하다는 통상적인 가정이다. Quick Sort의 기대 시간은 이 입력 분포 또는 각 활성 구간에서 pivot을 균등하게 무작위로 선택하는 조건에서 성립한다. 아래 첫 원소 pivot trace 하나가 기대 시간의 증명은 아니다.

| 알고리즘 | Best | Average | Worst | Extra space | Stable 조건 | In-place 조건 |
|---|---:|---:|---:|---:|---|---|
| Bubble | $$\Theta(n)$$ 또는 $$\Theta(n^2)$$ | $$\Theta(n^2)$$ | $$\Theta(n^2)$$ | $$\Theta(1)$$ | 동점에 교환하지 않으면 Yes | Yes |
| Selection | $$\Theta(n^2)$$ | $$\Theta(n^2)$$ | $$\Theta(n^2)$$ | $$\Theta(1)$$ | 일반 swap 구현은 No | Yes |
| Insertion | $$\Theta(n)$$ | $$\Theta(n^2)$$ | $$\Theta(n^2)$$ | $$\Theta(1)$$ | `>`인 값만 이동하면 Yes | Yes |
| Merge | $$\Theta(n\log n)$$ | $$\Theta(n\log n)$$ | $$\Theta(n\log n)$$ | $$\Theta(n)$$ | 동점에 왼쪽을 먼저 선택하면 Yes | 일반 배열 구현은 No |
| Quick | $$\Theta(n\log n)$$ | 기대 $$\Theta(n\log n)$$ | $$\Theta(n^2)$$ | stack 평균 $$\Theta(\log n)$$, 최악 $$\Theta(n)$$ | 일반 partition은 No | 배열 partition은 보조 배열 없이 가능 |
| Heap | $$\Omega(n)$$, $$O(n\log n)$$ | $$\Theta(n\log n)$$ | $$\Theta(n\log n)$$ | $$\Theta(1)$$ | No | Yes |
| Counting | $$\Theta(n+r)$$ | $$\Theta(n+r)$$ | $$\Theta(n+r)$$ | $$\Theta(n+r)$$ | 누적 위치와 역방향 배치 구현은 Yes | 해당 stable 구현은 No |
| LSD Radix | $$\Theta(k(n+r))$$ | $$\Theta(k(n+r))$$ | $$\Theta(k(n+r))$$ | digit sort에 따름 | 각 자리 정렬이 stable이어야 Yes | 일반 counting 기반 구현은 No |

여기서 $$r$$은 키 범위 또는 기수, $$k$$는 처리할 자릿수다. Bubble Sort의 best가 $$\Theta(n)$$이 되려면 한 pass 동안 교환이 없을 때 끝내는 조기 종료가 있어야 한다. 강의·Assignment 2의 고정 pass 구현은 이미 정렬된 입력에서도 $$\Theta(n^2)$$다. Heap Sort도 `sift-down`이 제자리에서 멈출 수 있는 구현과 모든 키가 같은 입력에서는 $$\Theta(n)$$까지 내려갈 수 있다. 일반 입력의 평균과, 매 추출에서 아래로 길게 이동하는 최악 입력은 $$\Theta(n\log n)$$이다.

### 3.2 비교 정렬 세 가지 trace

작성자 구성 입력은 `[5, 1, 4, 2, 8]`이다. 모든 결과는 직접 실행해 확인했다.

**Bubble Sort**는 각 pass 뒤 미정렬 구간의 최댓값을 오른쪽 끝에 확정한다.

```text
input       [5, 1, 4, 2, 8]
pass end=4  [1, 4, 2, 5, 8]   fixed suffix [4,5)
pass end=3  [1, 2, 4, 5, 8]   fixed suffix [3,5)
pass end=2  [1, 2, 4, 5, 8]   fixed suffix [2,5)
pass end=1  [1, 2, 4, 5, 8]   sorted
```

**Selection Sort**는 $$i$$부터 끝까지의 최솟값을 찾아 $$A[i]$$와 바꾼다. 접두부가 확정되지만, 멀리 떨어진 swap이 동점 레코드의 순서를 뒤집을 수 있다.

```text
input  [5, 1, 4, 2, 8]
i=0    [1, 5, 4, 2, 8]   fixed prefix [0,1)
i=1    [1, 2, 4, 5, 8]   fixed prefix [0,2)
i=2    [1, 2, 4, 5, 8]   fixed prefix [0,3)
i=3    [1, 2, 4, 5, 8]   sorted
```

**Insertion Sort**는 `current=A[i]`를 보관하고, 정렬된 접두부에서 `current`보다 큰 값만 오른쪽으로 이동한다.

```text
input  [5, 1, 4, 2, 8]
i=1    [1, 5, 4, 2, 8]   sorted prefix [0,2)
i=2    [1, 4, 5, 2, 8]   sorted prefix [0,3)
i=3    [1, 2, 4, 5, 8]   sorted prefix [0,4)
i=4    [1, 2, 4, 5, 8]   sorted prefix [0,5)
```

Selection Sort는 입력과 무관하게 비교를 $$n(n-1)/2$$회 한다. Insertion Sort는 이미 정렬된 입력에서 이동이 없지만 역순에서는 이동이 $$1+\cdots+(n-1)=n(n-1)/2$$회다.

### 3.3 Merge Sort와 Quick Sort trace

**Merge Sort**는 반열린 구간 $$[lo,hi)$$를 나누고, 정렬된 두 하위 구간을 합친다. 아래 trace는 재귀 호출이 반환될 때마다 merge 결과를 기록한다.

```text
input          [5, 1, 4, 2, 8]
merge [0,2)    [1, 5, 4, 2, 8]
merge [3,5)    [1, 5, 4, 2, 8]
merge [2,5)    [1, 5, 2, 4, 8]
merge [0,5)    [1, 2, 4, 5, 8]
```

각 merge는 길이에 선형이고, 재귀 깊이는 $$\Theta(\log n)$$이므로 $$T(n)=2T(n/2)+\Theta(n)=\Theta(n\log n)$$이다.

**Quick Sort**는 inclusive 구간 $$[lo,hi]$$에서 첫 원소를 pivot으로 고르는 Assignment 2 구현을 따른다. partition 직후 확정되는 것은 pivot 하나다.

```text
input          [5, 1, 4, 2, 8]
pivot 5 -> 3   [2, 1, 4, 5, 8]
pivot 2 -> 1   [1, 2, 4, 5, 8]
```

첫 partition 뒤 `[2, 1, 4]`가 아직 정렬되지 않았다는 점이 핵심이다. 균형 분할이면 $$2T(n/2)+\Theta(n)=\Theta(n\log n)$$, pivot이 계속 끝에 놓이면 $$T(n-1)+\Theta(n)=\Theta(n^2)$$다.

### 3.4 Heap Sort trace

0-based max-heap에서 자식은 $$2i+1,2i+2$$다. `sift-down`은 두 자식이 이미 heap이라는 조건에서 부모를 더 큰 자식과 바꿔 내려보낸다. 마지막 내부 노드 $$\lfloor n/2\rfloor-1$$부터 시작하는 bottom-up build-heap은 단순한 $$n\log n$$ 상한보다 강한 $$\Theta(n)$$이다. 높이 $$h$$인 노드 수가 대략 $$n/2^{h+1}$$이므로

$$
\sum_{h\ge0}\frac{n}{2^{h+1}}O(h)=O(n).
$$

같은 입력의 직접 실행 trace다.

```text
input             [5, 1, 4, 2, 8]
build max-heap    [8, 5, 4, 2, 1]
fix index 4       [5, 2, 4, 1, 8]
fix index 3       [4, 2, 1, 5, 8]
fix index 2       [2, 1, 4, 5, 8]
fix index 1       [1, 2, 4, 5, 8]
```

루트와 끝 원소를 바꾼 뒤 heap 크기를 한 칸 줄이고 sift-down한다. swap은 같은 키의 상대 순서를 보존하지 않는다.

### 3.5 Counting Sort와 LSD Radix Sort trace

Counting Sort는 비교 대신 정수 키의 분포를 사용한다. 작성자 구성 레코드 입력 `[(2,A),(0,B),(2,C),(1,D)]`에서 키 범위는 `0..2`다.

```text
raw counts       [1, 1, 2]
prefix counts    [1, 2, 4]
stable output    [(0,B), (1,D), (2,A), (2,C)]
```

입력을 오른쪽에서 왼쪽으로 읽고 누적 개수에서 1을 뺀 위치에 배치하면 같은 키 `2`의 `A,C` 순서가 보존된다. 출력 배열을 따로 쓰므로 이 stable 구현의 추가 공간은 $$\Theta(n+r)$$다. $$r\gg n$$이면 선형이라는 표현이 실용적 이점을 뜻하지 않는다.

LSD Radix Sort는 낮은 자리부터 높은 자리 순서로 **stable** digit sort를 적용한다. 작성자 구성 입력의 검산 결과다.

```text
input        [329, 457, 657, 839, 436, 720, 355]
ones digit   [720, 355, 436, 457, 657, 329, 839]
tens digit   [720, 329, 436, 839, 355, 457, 657]
hundreds     [329, 355, 436, 457, 657, 720, 839]
```

자리 정렬이 불안정하면 앞서 정렬한 낮은 자리의 순서가 깨져 최종 정렬을 보장할 수 없다.

## 4. Selection: 전체 정렬 없이 순위 하나만 찾는다

Selection 문제는 정렬되지 않은 배열에서 $$i$$번째로 작은 값을 찾는다. 이 글은 0-based rank를 사용한다. 모든 입력 원소를 적어도 한 번은 보아야 하므로 하한은 $$\Omega(n)$$이다.

### 4.1 Quickselect

Partition 뒤 pivot은 최종 rank에 놓인다.

1. 목표 rank가 pivot rank와 같으면 반환한다.
2. 작으면 왼쪽 구간만 재귀한다.
3. 크면 오른쪽 구간만 재귀한다.

한쪽만 재귀한다는 점이 Quick Sort와 다르다. Pivot이 바로 목표면 $$\Theta(n)$$, 매번 반대 끝이면

$$
T(n)=T(n-1)+\Theta(n)=\Theta(n^2).
$$

각 단계에서 현재 구간의 원소를 균등하게 무작위 pivot으로 고르면 **기대 시간**은 $$\Theta(n)$$이다. 이는 최악 시간이 선형이라는 뜻이 아니다. 무작위 실행에도 $$\Theta(n^2)$$ 경로는 존재한다.

<details markdown="block">
<summary markdown="span">Derivation: Why randomized Quickselect is expected $$\Theta(n)$$</summary>

키가 모두 다르고 pivot rank가 균등하다고 가정한다. 목표가 어느 쪽에 있든 큰 쪽을 재귀하는 것으로 상한을 잡으면

$$
\mathbb E[T(n)]
\le \frac{2}{n}\sum_{k=\lfloor n/2\rfloor}^{n-1}\mathbb E[T(k)]+cn.
$$

귀납 가설 $$\mathbb E[T(k)]\le dk$$를 대입하면 합의 주항은 최대 약 $$(3/4)dn$$이다. $$d$$를 partition 상수 $$c$$보다 충분히 크게 잡으면 나머지 $$(1/4)dn$$이 현재 레벨 비용 $$cn$$을 흡수한다. 따라서 기대 상한은 $$O(n)$$이고, 입력을 읽는 $$\Omega(n)$$ 하한과 합쳐 $$\Theta(n)$$이다.

</details>

### 4.2 Median of Medians

결정론적 최악 $$O(n)$$을 얻는 절차는 다음과 같다.

1. 원소를 5개씩 묶는다.
2. 각 그룹의 중앙값을 구한다.
3. 이 중앙값들의 중앙값을 재귀적으로 구해 pivot으로 쓴다.
4. Partition 후 목표가 있는 한쪽만 재귀한다.

선택된 pivot보다 크거나 같은 원소와 작거나 같은 원소가 각각 적어도 약 $$3n/10$$개 확보된다. 따라서 큰 재귀 구간은 최대 약 $$7n/10$$이고,

$$
T(n)\le T(n/5)+T(7n/10+O(1))+O(n)=O(n).
$$

강의의 “최악 pivot만 아니면 선형”은 분할 비율이 고정 상수만큼 보장된다는 조건과 함께 읽어야 한다. 단지 최댓값·최솟값이 아니라고 해서 pivot이 두 번째로 작은 값처럼 끝에 매우 가까운 경우까지 자동으로 선형이 되는 것은 아니다.

## 5. Dynamic Programming: 상태 설계부터 복원까지

DP는 중복 부분 문제의 답을 저장하는 기법이지만, 저장 전에 올바른 상태와 점화식이 필요하다. 다음 일곱 항목을 항상 같이 쓴다.

1. **State:** 상태가 정확히 무엇을 뜻하는가.
2. **Choice:** 가능한 첫 선택 또는 마지막 선택을 빠짐없이 나눴는가.
3. **Recurrence:** 각 선택을 더 작은 상태로 바꿨는가.
4. **Base/Sentinel:** 빈 문제와 불가능 상태를 어떻게 표현하는가.
5. **Order:** 참조 상태가 먼저 계산되는가.
6. **Answer:** 어느 상태가 최종 답인가.
7. **Reconstruction:** 값뿐 아니라 실제 선택이 필요하면 무엇을 저장하는가.

`0`이 유효한 답인 문제에서 미계산 상태도 `0`으로 두면 구분할 수 없다. Top-down은 `None` 또는 `-1` 같은 별도 sentinel을 쓰되 실제 답 범위와 겹치지 않는지 확인한다. 최댓값 문제의 불가능 상태에는 $$-\infty$$, 최솟값 문제에는 $$+\infty$$를 쓸 수 있다.

### 5.1 Matrix Path와 2×n Tiling

Matrix Path에서 $$P[i,j]$$를 시작점부터 $$(i,j)$$까지 오른쪽·아래 이동만 했을 때의 최대 합이라 두면

$$
P[i,j]=M[i,j]+\max(P[i-1,j],P[i,j-1]).
$$

첫 행과 첫 열은 한 방향에서만 올 수 있으므로 별도 초기화하거나, 격자 밖을 $$-\infty$$로 두고 시작점만 직접 초기화한다. 경로가 필요하면 더 큰 값을 준 이전 칸을 `parent[i][j]`에 저장한다.

그림에 강조된 경로의 합은 66이지만, 그림의 행렬 전체에 같은 점화식을 적용한 최댓값은 68이다. 강조선은 점화식의 이동 방향을 보여 주는 예시로 읽고, 최적값 자체와 구분한다.

2×n Tiling은 첫 열을 세로 도미노 하나로 덮거나, 가로 도미노 두 개로 덮는 두 배타적 경우를 나눈다.

$$
D[n]=D[n-1]+D[n-2],\qquad D[0]=1,\ D[1]=1.
$$

경우의 수는 배타적 경우를 **더한다**. 최적화 문제처럼 `max`나 `min`을 쓰지 않는다.

### 5.2 Worked LCS

$$L[i,j]$$를 문자열 $$X[0:i)$$와 $$Y[0:j)$$의 LCS 길이라 둔다. 빈 접두사와의 LCS는 0이다.

$$
L[i,j]=
\begin{cases}
L[i-1,j-1]+1,&X[i-1]=Y[j-1],\\
\max(L[i-1,j],L[i,j-1]),&X[i-1]\ne Y[j-1].
\end{cases}
$$

작성자 검산 예제 $$X=\texttt{ABCBDAB}$$, $$Y=\texttt{BDCABA}$$의 전체 표다.

|  | ∅ | B | D | C | A | B | A |
|---|---:|---:|---:|---:|---:|---:|---:|
| ∅ | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| A | 0 | 0 | 0 | 0 | 1 | 1 | 1 |
| B | 0 | 1 | 1 | 1 | 1 | 2 | 2 |
| C | 0 | 1 | 1 | 2 | 2 | 2 | 2 |
| B | 0 | 1 | 1 | 2 | 2 | 3 | 3 |
| D | 0 | 1 | 2 | 2 | 2 | 3 | 3 |
| A | 0 | 1 | 2 | 2 | 3 | 3 | 4 |
| B | 0 | 1 | 2 | 2 | 3 | 4 | 4 |

최종 답은 $$L[7,6]=4$$다. 오른쪽 아래에서 문자가 같으면 그 문자를 기록하고 대각선으로, 다르면 더 큰 이웃으로 이동한다. 동점에서 위를 고르는 규칙으로 복원하면 `BCBA`를 얻는다. `BDAB`도 길이 4의 정답이므로 복원 tie-break에 따라 답 문자열은 달라질 수 있다. 시간·공간은 $$\Theta(mn)$$이고, 길이만 필요하면 두 행으로 공간을 줄일 수 있지만 일반적인 경로 복원 정보는 잃는다.

### 5.3 Worked Matrix-Chain Order

행렬 $$A_i$$의 크기를 $$p_i\times p_{i+1}$$라 한다. 반열린 구간 $$[s,e)$$의 최소 스칼라 곱셈 수를 $$C[s,e]$$라 두면

$$
C[s,s+1]=0,
$$

$$
C[s,e]=\min_{s<k<e}
\left(C[s,k]+C[k,e]+p_sp_kp_e\right).
$$

구간 너비가 작은 순서로 계산하고, 최소를 만든 분할점 $$k$$를 `split[s][e]`에 저장한다. 최종 답은 $$C[0,m]$$이고, `split`을 재귀적으로 따라가 괄호를 복원한다.

Lecture 9의 $$p=(10,100,5,50)$$을 직접 계산하면

$$
\begin{aligned}
(A_0A_1)A_2 &: 10\cdot100\cdot5+10\cdot5\cdot50=7{,}500,\\
A_0(A_1A_2) &: 100\cdot5\cdot50+10\cdot100\cdot50=75{,}000.
\end{aligned}
$$

따라서 답은 7,500회와 `((A0A1)A2)`다. 상태 수는 $$\Theta(m^2)$$, 상태마다 최대 $$m-1$$개 분할을 보므로 시간 $$\Theta(m^3)$$, 공간 $$\Theta(m^2)$$다.

### 5.4 Worked Unbounded Knapsack from Assignment 2

양의 정수 무게 $$w_i$$와 음이 아닌 가치 $$v_i$$를 가정하고, $$dp[c]$$를 용량이 최대 $$c$$일 때 얻는 최대 가치라 둔다. 빈 선택도 허용한다. 보석 $$(w_i,v_i)$$를 마지막에 하나 넣는 선택을 보면

$$
dp[c]=\max\left(\{0\}\cup\left\{dp[c-w_i]+v_i:i,\ w_i\le c\right\}\right),
\qquad dp[0]=0.
$$

용량을 0부터 증가시키면 더 작은 용량이 먼저 계산된다. 같은 `dp` 배열을 참조하므로 같은 종류를 다시 쓸 수 있다. 0/1 knapsack에서 용량을 역순으로 순회하는 이유와 반대다.

작성자 검산 예제는 보석 $$(2,3),(3,4)$$, 용량 7이다.

```text
capacity c  0  1  2  3  4  5  6  7
dp[c]       0  0  3  4  6  7  9 10
```

최종 가치 10은 무게 2 보석 두 개와 무게 3 보석 한 개다. 실제 선택을 복원하려면 갱신을 만든 보석 index를 `choice[c]`에 저장하고 용량에서 그 무게를 반복해서 뺀다. 종류 수가 $$n$$, 용량이 $$C$$이면 시간 $$\Theta(nC)$$, 공간 $$\Theta(C)$$다.

### 5.5 Making It 1과 경로 복원

Lecture 10은 정수 $$i$$를 1로 만드는 최소 연산 수와 실제 경로를 함께 다룬다. 허용 연산이 `-1`, 2로 나누기, 3으로 나누기라면

$$
D[i]=1+\min\left(
D[i-1],
D[i/2]\text{ if }2\mid i,
D[i/3]\text{ if }3\mid i
\right),
$$

$$D[1]=0$$이다. $$i=2,3,\ldots,N$$ 순서로 계산하고 최솟값을 만든 다음 상태를 `parent[i]`에 저장한다. 최종 값은 $$D[N]$$, 경로는 $$N$$에서 `parent`를 따라 1까지 간다. 값 테이블과 복원 테이블은 목적이 다르다.

## 6. Greedy Algorithms: 선택 규칙을 증명해야 한다

Lecture 11은 그리디를 현재 가장 좋아 보이는 선택을 하고 미래를 직접 탐색하지 않는 전략으로 정의한다. 그러나 그리디라는 형식만으로 최적성을 보장하지 않는다. 강의는 두 조건을 강조한다.

- **Greedy-choice property:** 어떤 최적해가 현재의 그리디 선택을 포함하도록 바꿀 수 있다.
- **Optimal substructure:** 그 선택 뒤 남은 문제의 해도 최적이어야 한다.

보통 첫 조건은 **교환 논증**으로, 둘째는 “남은 해가 최적이 아니면 더 좋은 해로 바꿔 전체를 개선할 수 있다”는 모순으로 증명한다.

### 6.1 Making It 1은 단순 그리디가 실패한다

Lecture 11의 13쪽은 Lecture 10의 Making It 1을 그리디로 풀어도 되는지 묻는다. 작성자 구성 반례 $$N=10$$에서 “나눌 수 있으면 3, 다음 2로 나누고 아니면 1을 뺀다”는 규칙은

```text
10 -> 5 -> 4 -> 2 -> 1   (4회)
```

를 만든다. 그러나

```text
10 -> 9 -> 3 -> 1        (3회)
```

가 더 짧다. 지역 선택이 미래 상태의 품질을 보존한다는 증명이 없으므로 DP가 필요하다.

### 6.2 Change Problem: 배수 사슬에서의 교환 논증

강의의 동전은 `500, 100, 50, 10, 5, 1`원이며 각 동전은 무제한이다. 남은 금액 이하의 가장 큰 동전을 최대한 선택한다. 380원 자체를 바꾸면 `100×3 + 50 + 10×3 = 380`, 총 7개다. 강의 15쪽의 예제 출력 4는 **1000원을 냈을 때 물건값 380원이라 잔돈이 620원**인 문맥이다. 이 경우 `500+100+10+10`, 4개다.

강의 17쪽의 `x > 500`은 경계 오기이며, 500원도 선택할 수 있도록 `x >= 500`이 맞다.

최적성은 인접 동전의 배수 관계로 증명할 수 있다. 큰 동전 $$d_i$$가 다음 동전 $$d_{i+1}$$의 $$q_i$$배라면, 최적해에 $$d_{i+1}$$가 $$q_i$$개 이상 있을 수 없다. 그 묶음을 $$d_i$$ 하나로 바꾸면 같은 금액을 더 적은 동전으로 만들기 때문이다. 이 교환을 큰 단위부터 반복하면 각 작은 동전 개수가 그리디가 남기는 나머지와 같아진다.

이 배수 조건은 **충분조건이지 필요조건은 아니다.** 작성자 구성 동전 `{3,2,1}`은 3이 2의 배수가 아니지만, 그리디가 모든 금액 $$x=3q+r$$에 대해 $$q+\mathbf1[r>0]=\lceil x/3\rceil$$개를 사용하여 최적이다. 반대로 `{4,3,1}`에서 금액 6은 그리디 `4+1+1`의 3개보다 `3+3`의 2개가 낫다.

### 6.3 Meeting Room Allocation: 가장 빨리 끝나는 회의

회의 $$a_i=(s_i,f_i)$$에서 $$s_i\le f_i$$를 가정한다. 두 회의를 이 순서로 배치할 때 $$f_i\le s_j$$이면 양립 가능하다고 정의하며, 끝나는 시각과 다음 시작 시각이 같아도 된다. 목표는 이런 순서로 배치할 수 있는 회의의 최대 개수다.

`(종료 시각, 시작 시각)` 오름차순으로 정렬하고, 마지막 선택 회의의 종료 시각 이상에서 시작하는 첫 회의를 반복 선택한다. 양의 길이 회의만 있다면 종료 시각 동점의 순서는 결과에 영향을 주지 않는다. 그러나 zero-duration 회의도 허용하면 시작 시각 tie-break가 필요하다. 예를 들어 `(1,1)`을 `(0,1)`보다 먼저 처리하면 scan은 1개만 고르지만, `(0,1)`, `(1,1)` 순서이면 2개를 고른다. 시간은 정렬 때문에 $$O(n\log n)$$, 이미 이 순서로 정렬되어 있으면 scan은 $$O(n)$$이다.

<details markdown="block">
<summary markdown="span">Derivation: Exchange proof for earliest finish time</summary>

`(종료 시각, 시작 시각)` 순서의 첫 회의를 $$a_1$$이라 하자. 최적해 $$O$$가 $$a_1$$을 포함하지 않는다면, $$O$$에서 첫 회의를 $$a_j$$라 하자. $$f_1\le f_j$$이므로 $$a_j$$ 뒤에 배치된 모든 회의는 $$a_1$$ 뒤에도 배치할 수 있다. $$a_j$$를 $$a_1$$로 교체해도 회의 수는 같고 충돌이 생기지 않는다. 따라서 $$a_1$$을 포함하는 최적해가 존재한다. $$a_1$$이 이미 최적해에 있다면 같은 종료 시각에서는 더 이른 시작을 먼저 두는 tie-break에 맞춰 맨 앞으로 옮길 수 있다.

$$a_1$$을 고른 뒤 남는 집합을 정확히

$$
A'=\{a_i\in A\setminus\{a_1\}:s_i\ge f_1\}
$$

로 정의한다. 남은 선택이 $$A'$$의 최적해가 아니라면 더 큰 compatible 집합으로 바꿔 전체 회의 수도 늘릴 수 있으므로 모순이다. 따라서

$$
OPT(A)=1+OPT(A').
$$

$$A\setminus\{a_1\}$$를 명시하지 않으면 $$s_1=f_1$$인 zero-duration 회의가 자기 자신을 다시 포함할 수 있다. 강의 식은 일반 입력에 적용할 때 이 제외 조건이 필요하다.

</details>

다음은 원문 문제가 아닌 작성자 구성 반례다.

- **가장 짧은 회의 우선 실패:** `[0,4)`, `[3,5)`, `[4,8)`에서 가장 짧은 `[3,5)`를 고르면 1개지만, `[0,4)`와 `[4,8)`은 2개다.
- **가장 이른 시작 우선 실패:** `[0,10)`, `[1,2)`, `[2,3)`, `[3,4)`에서 `[0,10)`을 고르면 1개지만 나머지 세 개를 모두 고를 수 있다.

## 7. Assignment 1: 제공된 해답 기준

### 7.1 행렬 곱셈과 점근 정의

제공된 해답 1쪽은 $$n\times n$$ 행렬 곱 코드에서 곱셈 $$n^3$$회, 덧셈 $$n^3-n^2$$회, 대입 $$n^3$$회를 세어 총

$$
3n^3-n^2=\Theta(n^3)
$$

로 정리한다. `M[i][j]`의 첫 항은 대입이지만 덧셈은 아니므로 덧셈 수가 $$n^3$$보다 $$n^2$$만큼 적다.

점근 정의 문제에서 제공된 해답이 제시한 한 가지 유효한 상수 선택은 다음과 같다.

| 주장 | 제공된 상수 | 확인 |
|---|---|---|
| $$6n^3-15n^2+20\in O(n^3)$$ | $$c=26,n_0=1$$ | $$-15n^2\le0$$, $$20\le20n^3$$; 정수 $$n\ge1$$에서 함수도 양수 |
| $$7n^2-4n\log_2n\in\Omega(n^2)$$ | $$c=3,n_0=1$$ | $$\log_2n\le n$$이므로 하한 $$3n^2$$ |
| $$3n^2+5n-2\in\Theta(n^2)$$ | $$c_1=2,c_2=8,n_0=2$$ | 같은 구간에서 양쪽 부등식 성립 |

더 작은 상수나 다른 시작점도 정의를 만족하면 정답이다.

### 7.2 Q3의 두 해석

제공된 해답 2–3쪽은 문제의 의도가 **재귀 호출 3회와 선형 작업**이었다고 설명하면서, 기존 코드 `3 * fn(n/3) + n`을 문자 그대로 분석한 답도 인정한다. 두 대상은 다음처럼 다르다.

| 해석 대상 | 점화식 | 결과 |
|---|---|---|
| 의도한 재귀 구조 | $$T(n)=3T(n/3)+n$$ | $$\Theta(n\log n)$$ |
| 기존 코드 실행시간 | $$T(n)=T(n/3)+\Theta(1)$$ | $$\Theta(\log n)$$ |
| 기존 코드 반환값 $$F(n)$$ | $$F(n)=3F(n/3)+n$$ | $$n=3^k,\ F(1)=1$$이면 정확히 $$F(n)=n(1+\log_3n)$$ |

첫 점화식은 각 레벨의 선형 작업이 $$n$$이고 깊이가 $$\log_3n$$이므로 $$\Theta(n\log n)$$이다. 문자 코드에는 재귀 호출이 한 번뿐이고 `+n`은 숫자 덧셈 한 번이므로 실행시간은 $$\Theta(\log n)$$이다. 표의 정확한 반환값 식은 $$n=3^k$$와 기저값 $$F(1)=1$$을 전제로 하며, 일반 $$n$$에서는 정수 나눗셈·반올림 규칙을 따로 지정해야 한다. 반환값 크기와 실행 연산 수를 혼동하지 않는다.

### 7.3 Master Theorem 7개 결과

| 항목 | 점화식 | Case | Tight bound |
|---|---|---:|---|
| (a) | $$2T(n/3)+n$$ | 3 | $$\Theta(n)$$ |
| (b) | $$T(n/3)+n$$ | 3 | $$\Theta(n)$$ |
| (c) | $$4T(n/2)+n$$ | 1 | $$\Theta(n^2)$$ |
| (d) | $$T(n/2)+1$$ | 2 | $$\Theta(\log n)$$ |
| (e) | $$4T(n/2)+n^2$$ | 2 | $$\Theta(n^2\log n)$$ |
| (f) | $$8T(n/2)+n^3$$ | 2 | $$\Theta(n^3\log n)$$ |
| (g) | $$5T(n/5)+n^2$$ | 3 | $$\Theta(n^2)$$ |

## 8. Assignment 2: 정렬 출력과 DP 연습

Assignment 2는 정렬 결과만이 아니라 **출력 시점**을 묻는다. Insertion은 삽입 뒤, Bubble은 pass 뒤, Quick은 partition 뒤, Merge는 merge 뒤에 전체 배열을 출력한다. 각 출력에서 prefix, suffix, pivot, merged interval 가운데 무엇이 확정됐는지 표시하면 trace 오류를 줄일 수 있다.

DP 문제는 다음 두 구조를 추가로 연습한다.

- **Theater Seating:** VIP 좌석이 일반 좌석을 독립 구간으로 나눈다. 길이 $$k$$ 구간의 경우의 수 $$W(k)=W(k-1)+W(k-2)$$, $$W(0)=W(1)=1$$을 구하고 각 구간 값을 곱한다.
- **Knapsack Filling 1:** 같은 보석을 반복 사용할 수 있는 unbounded knapsack이다. 용량 증가 순서와 `dp[c-w_i]` 참조가 재사용을 허용한다.

연습 문제:

- <a href="https://jungol.co.kr/problem/1158" target="_blank" rel="noopener">JUNGOL 1158: Insertion Sort</a>
- <a href="https://jungol.co.kr/problem/1157" target="_blank" rel="noopener">JUNGOL 1157: Bubble Sort</a>
- <a href="https://jungol.co.kr/problem/3518" target="_blank" rel="noopener">JUNGOL 3518: Quick Sort</a>
- <a href="https://jungol.co.kr/problem/3519" target="_blank" rel="noopener">JUNGOL 3519: Merge Sort</a>
- <a href="https://jungol.co.kr/problem/1848" target="_blank" rel="noopener">JUNGOL 1848: Theater Seating</a>
- <a href="https://jungol.co.kr/problem/1077" target="_blank" rel="noopener">JUNGOL 1077: Knapsack Filling 1</a>

## 마지막 핵심 정리

- 분석 전에 입력 크기와 기본 연산을 고정한다. Case와 점근 표기는 다른 축이다.
- 재귀식의 $$a$$는 실제 호출 수다. 반환값의 계수나 숫자 덧셈을 호출 수·선형 작업으로 오해하지 않는다.
- Master Theorem은 $$f(n)$$과 $$n^{\log_ba}$$의 다항식 차이와 Case 3 정규성 조건까지 확인한다.
- 정렬 trace는 현재 배열, 활성 구간, 비교·이동 값, 새로 확정된 구간을 함께 기록한다.
- Randomized Quickselect는 기대 $$\Theta(n)$$이지만 최악은 $$\Theta(n^2)$$다. Median of Medians는 결정론적 최악 $$O(n)$$을 보장한다.
- DP는 state, recurrence, base, sentinel, order, answer, reconstruction을 한 세트로 설계한다.
- 그리디 최적성은 greedy-choice property와 optimal substructure를 교환 논증·모순으로 증명한다. 지역 규칙만 제시해서는 충분하지 않다.

## Study Guide

1. [Original Practice](#original-practice)의 세 코드를 답을 닫고 다시 푼다. 종료값·본문 실행 횟수·연산 수를 나눠 적고, Lecture 2–3의 비용 모형과 재귀식으로 연결한다.
2. 정렬 8개를 같은 입력에 손으로 실행하고, 각 줄의 확정 구간을 표시한다.
3. Selection은 pivot 선택 방식마다 worst와 expected 보장이 어떻게 달라지는지 말한다.
4. DP 문제마다 일곱 항목 체크리스트를 빈 종이에 작성한다.
5. Greedy 규칙에는 성공 증명 또는 가장 작은 반례를 붙인다.
6. Assignment 1 Q3은 “실행시간”과 “반환값”을 별도 함수로 써서 구분한다.

## 복습 질문

<details markdown="block">
<summary>1. Worst case와 Big-O가 같은 말이 아닌 이유는?</summary>

답변: Worst case는 크기 $$n$$인 입력 중 최대 비용을 택하는 입력 분류다. Big-O는 그렇게 얻은 함수나 다른 함수의 점근적 상한 관계다. Worst-case 비용이 $$\Theta(n^2)$$이면 $$O(n^2)$$뿐 아니라 $$O(n^3)$$도 성립한다.

</details>

<details markdown="block">
<summary markdown="span">2. $$T(n)=2T(n/2)+n$$에서 각 레벨 비용이 왜 $$n$$인가?</summary>

답변: 깊이 $$j$$에는 $$2^j$$개 호출이 있고 각 호출의 비재귀 작업은 $$n/2^j$$다. 곱하면 $$2^j(n/2^j)=n$$이다. 깊이가 $$\log_2n$$이므로 총비용은 $$\Theta(n\log n)$$이다.

</details>

<details markdown="block">
<summary>3. Master Theorem Case 3에서 정규성 조건은 무엇을 막는가?</summary>

답변: $$f(n)$$이 임계 함수보다 커도 재귀 단계마다 불규칙하게 급증하여 하위 레벨 비용이 충분히 줄지 않는 경우를 막는다. $$af(n/b)\le cf(n)$$, $$c<1$$이면 레벨 비용이 기하급수적으로 감소해 루트의 $$f(n)$$이 전체를 지배한다.

</details>

<details markdown="block">
<summary>4. Stable과 in-place는 왜 별개인가?</summary>

답변: Stable은 동점 레코드의 상대 순서에 관한 출력 성질이고, in-place는 보조 메모리 사용량에 관한 구현 성질이다. Insertion Sort는 둘 다 가능하지만, stable Counting Sort는 일반적으로 출력 배열이 필요해 in-place가 아니다.

</details>

<details markdown="block">
<summary>5. Quick Sort partition 뒤 확정되는 범위는?</summary>

답변: Pivot의 최종 위치 하나가 확정된다. 왼쪽 값들은 pivot 이하, 오른쪽 값들은 pivot 이상이지만 각 구간 내부 순서는 아직 정렬되지 않았다.

</details>

<details markdown="block">
<summary>6. LSD Radix Sort의 각 자리 정렬이 stable해야 하는 이유는?</summary>

답변: 높은 자리가 같은 두 원소는 이전 pass에서 정한 낮은 자리 순서를 유지해야 한다. 불안정한 자리 정렬은 이전 자리의 정보를 깨뜨려 최종 사전식 숫자 순서를 보장하지 못한다.

</details>

<details markdown="block">
<summary>7. Randomized Quickselect의 기대 시간과 최악 시간은?</summary>

답변: 현재 구간에서 pivot을 균등하게 뽑는 가정 아래 기대 시간은 $$\Theta(n)$$이다. 그러나 매번 극단 pivot을 뽑는 실행 경로가 있으므로 최악 시간은 $$\Theta(n^2)$$이다.

</details>

<details markdown="block">
<summary>8. DP에서 값 0과 미계산 상태를 왜 구분해야 하는가?</summary>

답변: 0이 실제 최적값이나 경우의 수일 수 있기 때문이다. 둘을 같은 값으로 두면 memo hit인지 아직 계산하지 않았는지 알 수 없어 재계산하거나 잘못된 값을 사용할 수 있다. `None` 또는 답 범위 밖 sentinel을 쓴다.

</details>

<details markdown="block">
<summary>9. LCS 길이 표만으로 실제 LCS를 복원할 수 있는가?</summary>

답변: 전체 표가 남아 있으면 같은 문자에서는 대각선, 다른 문자에서는 더 큰 이웃을 따라가 복원할 수 있다. 길이만 위해 두 행만 보존했다면 일반적인 역추적 정보가 사라진다. 동점에서는 여러 LCS가 가능하다.

</details>

<details markdown="block">
<summary>10. Unbounded knapsack과 0/1 knapsack의 1차원 갱신 순서는 어떻게 다른가?</summary>

답변: Unbounded는 같은 물건을 다시 쓰도록 용량을 작은 값부터 증가시킨다. 0/1은 같은 iteration에서 같은 물건을 재사용하지 않도록 용량을 큰 값부터 감소시킨다.

</details>

<details markdown="block">
<summary>11. 동전 액면이 배수 사슬이면 그리디가 최적인 이유는?</summary>

답변: 작은 동전이 큰 동전 하나와 같은 금액만큼 모이면 큰 동전 하나로 교환하여 동전 수를 줄일 수 있다. 따라서 최적해는 각 단계에서 그리디가 허용하는 수보다 많은 작은 동전을 가질 수 없고, 큰 동전부터 정규화한 형태가 그리디 결과와 같다.

</details>

<details markdown="block">
<summary>12. 회의 배정에서 가장 빠른 종료 시각이 안전한 선택인 이유는?</summary>

답변: 어떤 최적해의 첫 회의를 가장 빨리 끝나는 회의로 교체해도 이후 회의의 시작 조건을 해치지 않는다. 회의 수가 유지되므로 그 선택을 포함하는 최적해가 존재하고, 남은 compatible 집합도 최적으로 풀면 된다.

</details>

<details markdown="block">
<summary>13. Assignment 1 Q3의 두 실행시간 답이 모두 나오는 이유는?</summary>

답변: 출제 의도는 하위 문제 3개와 선형 작업이라 $$3T(n/3)+n=\Theta(n\log n)$$이다. 그러나 기존 코드 `3 * fn(n/3) + n`은 함수를 한 번만 호출하고 상수 개 산술 연산을 하므로 $$T(n/3)+\Theta(1)=\Theta(\log n)$$이다. 제공된 해답은 이 불일치를 설명하고 두 해석을 구분한다.

</details>

## Related Notes

- [Lecture notes and course materials]({{ "/study/algorithms/" | relative_url }})
- [Assignment 1: Complexity Analysis and Recurrences]({{ "/assignment/algorithms/assignment-01-complexity-analysis/" | relative_url }})
- [Assignment 2: Sorting Traces and Dynamic Programming]({{ "/assignment/algorithms/assignment-02-sorting-and-dynamic-programming/" | relative_url }})

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/02-algorithm-analysis.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2: Algorithm Analysis</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/03-recurrence.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 3: Recurrence</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/04-sorting-01.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 4: Sorting (1)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/05-sorting-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 5: Sorting (2)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/06-sorting-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 6: Sorting (3)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-07-sorting-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 7: Sorting (4)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-08-selection.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 8: Selection</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 9: Dynamic Programming (1)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-10-dynamic-programming-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 10: Dynamic Programming (2)</a></li>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-11-greedy-algorithm.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 11: Greedy Algorithm</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/algorithms/algorithms-assignment-01-instructions.pdf" | relative_url }}" target="_blank" rel="noopener">Assignment 1 Instructions</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/algorithms/assignment-01-2026-solutions.pdf" | relative_url }}" target="_blank" rel="noopener">Assignment 1 Solutions</a></li>
</ul>
