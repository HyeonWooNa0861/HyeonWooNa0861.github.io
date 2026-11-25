---
layout: default
date: 2026-10-06 12:10:00 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Lecture 9: Dynamic Programming I"
course: "Algorithms"
topic: "Memoization, Matrix Paths, and Matrix-Chain Order"
order: 9
major_topic: "Data Structures & Algorithms"
keywords:
  - "Dynamic Programming"
  - "Optimal Substructure"
  - "Memoization"
  - "Tabulation"
  - "Matrix Path"
  - "Matrix Chain Multiplication"
---

# Lecture 9: Dynamic Programming I

Source PDF: [9 Dynamic Programming (1).pdf](/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf)

이 강의는 재귀식에 같은 부분 문제가 반복해서 나타날 때, 그 답을 한 번만 계산해 저장하는 동적 계획법을 소개합니다. 피보나치 수로 top-down과 bottom-up의 차이를 확인한 뒤, 격자 최대 경로와 행렬 연쇄 곱셈 순서 문제에서 상태·점화식·계산 순서를 설계합니다. 아래의 최적 부분 구조 증명, 경계 조건 교정, 경로와 괄호 복원은 슬라이드의 전개를 정확히 연결하기 위한 보충 설명입니다.

피보나치 재귀에서 `F(5)`를 구하면 `F(3)` 같은 값이 여러 경로에서 다시 계산됩니다. 동적 계획법은 `F(3)=2`를 처음 계산했을 때 저장하고, 다음 요청에서는 그 값을 그대로 사용합니다. 큰 문제를 작은 문제로 나누는 것뿐 아니라, **작은 답을 어떤 이름으로 저장하고 어떤 순서로 재사용할지** 정하는 방법입니다.

> **핵심:** 동적 계획법은 점화식만 세우는 기법이 아닙니다. **상태가 무엇을 뜻하는지**, **기저 사례가 무엇인지**, **의존 상태가 먼저 계산되는 순서가 무엇인지**, **최적값을 만든 선택을 어떻게 복원할지**까지 함께 설계해야 합니다.

## 원본 그림으로 읽기

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf#page=19" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-09-p19-matrix-path.jpg" | relative_url }}" alt="Matrix Path의 선택 경로와 bottom-up 점화식을 함께 보여 주는 강의 슬라이드" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 19. 노란 경로는 왼쪽 또는 위쪽 상태 중 더 큰 값을 골라 현재 칸을 더하는 과정을 보여 줍니다.</figcaption>
</figure>

현재 칸 `(i,j)`로 들어오는 마지막 이동은 왼쪽 `(i,j-1)` 또는 위 `(i-1,j)`뿐입니다. 따라서 두 이전 상태의 최댓값에 `mat[i][j]`를 더하면 됩니다. 그림의 행 우선 계산은 참조하는 두 상태가 먼저 채워지도록 보장합니다. 다만 그림 속 `[[0] * n+1 ...]`은 괄호가 잘못되어 그대로 실행되지 않고, 음수 인덱스를 경계처럼 쓰는 방식도 일반 입력에는 안전하지 않습니다. 아래 4절은 이 두 점을 고친 구현입니다.

## 전체 흐름

| PDF 쪽 | 내용 | 이 글에서 다루는 위치 |
|---|---|---|
| 1–5 | 이전 강의의 Quickselect와 median of medians 복습 | Previous Lecture Recap |
| 6–9 | 목차와 동적 계획법의 조건 | Dynamic Programming |
| 10–15 | 피보나치 재귀, tabulation, memoization | Fibonacci Numbers |
| 16–20 | Matrix Path Problem의 점화식과 두 구현 | Matrix Path Problem |
| 21–27 | Matrix Multiplication Order Problem의 점화식과 두 구현 | Matrix-Chain Order |
| 28–31 | 요약, 다음 강의, 질문 | 마지막 핵심 정리, Study Guide, Q&A |

## 1. Previous Lecture Recap

3–5쪽은 선택 문제와 Quickselect, median of medians를 복습합니다. 무작위 피벗 Quickselect의 기대 시간 분석에서는 재귀적으로 남는 부분 배열 크기를 평균내어 다음 상한을 사용합니다.

$$
T(n)
\le \frac{2}{n}\sum_{k=\lfloor n/2\rfloor}^{n-1}T(k)+c_0n.
$$

귀납 가설 $$T(k)\le ck$$를 대입하면 재귀항은 $$3cn/4$$ 이하로 묶입니다. 홀수 $$n$$에서는 대칭인 두 피벗 경우가 같은 중앙 크기를 만들 수 있는데, 위 식의 계수 2는 그 중앙 항까지 두 번 세므로 등식이 아니라 안전한 상한입니다. 충분히 큰 상수 $$c$$를 택하면 선형항 $$c_0n$$을 흡수할 수 있어 기대 시간 $$T(n)=O(n)$$을 얻습니다. 여기서 $$n$$은 원소 수, $$T(n)$$은 기본 연산 횟수, $$c$$와 $$c_0$$은 연산 횟수의 상수 계수입니다.

median of medians를 피벗 선택에 사용하면 최악의 경우에도 다음과 같은 재귀 상한을 얻습니다(5쪽). 먼저 슬라이드가 사용하는 반올림을 생략한 형태는 다음과 같습니다.

$$
T(n)\le T\!\left(\frac{n}{5}\right)+T\!\left(\frac{7n}{10}\right)+c_0n.
$$

이 이상화된 식에 같은 귀납 가설을 대입하면 재귀항의 합이 $$9cn/10$$ 이하이므로 $$c\ge 10c_0$$이면 $$T(n)\le cn$$입니다. 실제 그룹 수와 제거되는 원소 수에는 반올림이 들어가므로 더 정확한 형태는 $$T(\lceil n/5\rceil)+T(7n/10+O(1))+c_0n$$입니다. 충분히 큰 $$n$$에서는 두 재귀 입력 비율의 합이 1보다 작은 상태로 유지되어 반올림의 상수 오차를 선형 여유분이 흡수합니다. 그 임계값 아래의 유한한 기저 구간까지 $$c$$를 확대하면 최악 시간 $$O(n)$$이 성립합니다. 이 복습은 “큰 문제를 더 작은 문제의 답으로 표현한다”는 재귀적 사고를 동적 계획법으로 이어 주지만, 선택 알고리즘 자체는 이번 강의의 DP 예제가 아닙니다.

## 2. Dynamic Programming

### 2.1 When DP applies

슬라이드는 동적 계획법의 출발점을 두 조건으로 설명합니다(9쪽).

1. 큰 문제의 해답이 작은 문제의 해답으로 구성되는 **재귀적 부분 구조**가 있습니다. 최적화 문제에서는 전체 최적해가 부분 문제의 최적해를 포함하는 **최적 부분 구조**가 필요합니다.
2. 재귀 호출 트리에서 같은 부분 문제가 여러 번 계산되는 **중복 부분 문제**가 있습니다.

첫 조건은 올바른 점화식을 세울 근거이고, 둘째 조건은 계산 결과를 저장했을 때 이득을 얻는 이유입니다. 피보나치는 정의된 수열의 값을 계산하는 문제이지 최적화 문제가 아닙니다. 반면 Matrix Path와 Matrix Chain에서는 최적 부분 구조를 증명해야 합니다. 중복이 거의 없는 재귀는 메모 테이블을 두어도 큰 이득이 없고, 최적 부분 구조가 성립하지 않으면 작은 문제의 최적값만 이어 붙여 전체 최적값을 보장할 수 없습니다.

### 2.2 Four design decisions

| 설계 항목 | 확인할 질문 | 이 강의의 예 |
|---|---|---|
| 상태 | 테이블 한 칸이 정확히 무엇을 뜻합니까? | `fib[i]`, $$P_{i,j}$$, $$S(s,e)$$ |
| 기저 사례 | 더 쪼갤 필요가 없는 가장 작은 문제는 무엇입니까? | $$F_0=0$$, $$F_1=1$$; 시작 칸; 행렬 한 개 |
| 평가 순서 | 현재 상태가 의존하는 상태가 먼저 계산됩니까? | 작은 인덱스, 행 우선, 짧은 행렬 구간 순서 |
| 복원 정보 | 최적값을 만든 선택을 어떻게 되찾습니까? | 이전 칸 좌표, 최적 분할점 |

Top-down memoization은 목표 상태에서 출발해 필요한 상태만 재귀적으로 계산하고, 첫 계산 결과를 저장합니다. Bottom-up tabulation은 기저 상태에서 시작해 의존 관계를 만족하는 순서로 테이블을 채웁니다. 두 방식은 같은 상태와 점화식을 계산할 수 있지만 호출 스택, 계산되는 상태의 범위, 평가 순서를 표현하는 방법이 다릅니다.

### 2.3 점화식을 처음부터 만드는 순서

점화식을 외우기보다, 구하려는 답을 작은 문제의 답으로 어떻게 만들 수 있는지 거꾸로 살펴보면 됩니다. 이 순서는 뒤의 세 예제에 공통으로 적용됩니다.

1. **구할 답을 정합니다.** 입력 전체에 대해 수열의 값 하나를 구하는지, 경로의 최대 점수를 구하는지, 곱셈의 최소 비용을 구하는지 먼저 분명히 합니다.
2. **상태의 뜻을 한 문장으로 적습니다.** `dp[...]`가 어떤 범위까지의 답인지 정하고 인덱스도 고정합니다. 이 글의 $$F_n$$은 $$n$$번째 값, $$P_{i,j}$$는 $$(i,j)$$까지의 최대 합, $$S(s,e)$$는 $$A_s$$부터 $$A_{e-1}$$까지의 최소 비용입니다.
3. **마지막 선택을 빠짐없이 찾습니다.** 목표에 도달하기 직전의 경우를 나누면 Matrix Path는 위·왼쪽, Matrix Chain은 가능한 모든 마지막 분할점으로 나뉩니다. 피보나치처럼 선택이 없다면, 값을 만드는 마지막 규칙을 확인합니다.
4. **각 경우를 더 작은 상태로 바꿉니다.** 직전 칸이나 더 짧은 구간처럼 이미 정의한 상태로 표현합니다. 그 상태의 답만으로 다음 값을 정할 수 없다면 상태에 필요한 정보를 더 넣어야 합니다.
5. **후보를 결합하고 끝나는 곳을 정합니다.** 이번 단계에 새 값·비용이 생기면 작은 상태의 답에 붙입니다. 분기들의 결과는 문제의 목표에 맞게 더하거나 `max`·`min`으로 고릅니다. 피보나치는 앞의 두 항 자체를 더하고, 경로 최댓값은 두 후보를 비교한 뒤 현재 칸의 값을 더합니다. 더 쪼갤 수 없는 기저 사례와 아예 존재하지 않는 경우도 구분합니다. 특히 불가능한 경로를 점수 0으로 취급하면 음수 입력에서 오답이 됩니다.
6. **계산 순서와 최종 상태를 확인합니다.** 모든 오른쪽 항이 현재 상태보다 먼저 계산되도록 작은 인덱스·행 우선·짧은 구간 순서 중 맞는 것을 고릅니다. 마지막에 읽을 답은 각각 $$F_n$$, $$P_{R-1,C-1}$$, $$S(0,m)$$입니다.

최적화 문제에서는 한 후보의 부분 경로·부분 곱셈 순서를 더 나은 것으로 교체해도 나머지 조건이 변하지 않아야 작은 상태의 **최적값**을 쓸 수 있습니다. 이 조건이 성립하는 이유를 Matrix Path와 Matrix Chain에서 각각 확인합니다.

## 3. Fibonacci Numbers

### 3.1 State and recurrence

피보나치 상태 $$F_n$$은 0부터 세었을 때 $$n$$번째 피보나치 수입니다. 여기서는 입력 $$n$$이 0 이상의 정수라고 가정합니다. 인덱스 $$n$$은 무차원 정수이고, $$F_n$$은 수열의 무차원 정수값입니다(10쪽).

이 상태에서는 최댓값을 고르는 선택이 없습니다. $$n\ge2$$일 때 다음 값을 만들려면 직전 값 $$F_{n-1}$$과 그 앞 값 $$F_{n-2}$$가 **둘 다** 필요합니다. 두 값 중 하나를 고르는 것이 아니라 더하는 이유가 여기에 있습니다. 더 작은 항으로 내려가다 $$n=0,1$$에 도달하면 주어진 첫 두 값으로 멈춥니다.

$$
F_0=0,\qquad F_1=1,\qquad F_n=F_{n-1}+F_{n-2}\quad(n\ge2).
$$

각 항은 바로 앞의 두 항을 더해 정의됩니다. 따라서 이 식은 근사가 아니라 수열의 정의에서 나오는 정확한 등식입니다.

예를 들어 빈 테이블에 $$F_0=0$$, $$F_1=1$$을 먼저 적으면 $$F_2=0+1=1$$, $$F_3=1+1=2$$, $$F_4=1+2=3$$을 차례로 얻습니다. 이렇게 $$n$$까지 채운 뒤 읽는 값이 구하려던 $$F_n$$입니다.

### 3.2 Why the naive recursion is exponential

11–12쪽의 재귀 함수는 점화식을 그대로 실행합니다.

```python
def fib_recursive(n):
    if n <= 1:
        return n
    return fib_recursive(n - 1) + fib_recursive(n - 2)
```

함수 호출 수를 $$C_n$$이라 두면 $$C_0=C_1=1$$이고 다음 식이 성립합니다.

$$
C_n=C_{n-1}+C_{n-2}+1.
$$

$$D_n=C_n+1$$로 놓으면 $$D_n=D_{n-1}+D_{n-2}$$가 되어 피보나치와 같은 성장률을 갖습니다. 실제로 $$C_n=2F_{n+1}-1$$이며, $$\phi=(1+\sqrt5)/2$$일 때 호출 수는 $$\Theta(\phi^n)$$입니다. `fib(5)` 안에서 `fib(3)`과 `fib(2)`가 여러 번 호출되는 그림은 이 중복을 보여 줍니다. 실행 시간의 단위는 기본 호출 횟수이고, 재귀 깊이는 최대 $$n$$이므로 호출 스택 공간은 $$\Theta(n)$$입니다.

### 3.3 Bottom-up tabulation

작은 인덱스부터 테이블을 채우면 각 상태를 정확히 한 번 계산합니다(13쪽).

```python
def fib_bottom_up(n):
    if n <= 1:
        return n

    table = [0] * (n + 1)
    table[1] = 1
    for i in range(2, n + 1):
        table[i] = table[i - 1] + table[i - 2]
    return table[n]
```

평가 순서는 `0, 1, 2, ..., n`입니다. `table[i]`를 계산할 때 `table[i-1]`과 `table[i-2]`가 이미 채워져 있습니다. 정수 덧셈을 단위 비용으로 세고 공간을 저장한 정수 개수로 측정하면, 상태 수가 $$n+1$$이고 상태마다 덧셈 한 번이므로 시간은 $$\Theta(n)$$, 테이블 공간은 $$\Theta(n)$$입니다. 최종 값만 필요하면 직전 두 값만 보존해 정수 개수 기준 공간을 $$\Theta(1)$$로 줄일 수 있습니다. Python의 무한 정밀 정수에서 $$F_n$$은 $$\Theta(n)$$비트이므로 비트 연산과 실제 저장 바이트를 세면 이 단위 비용 분석보다 비용이 커집니다.

### 3.4 Top-down memoization

14–15쪽의 방식은 재귀 구조를 유지하면서 이미 계산한 값을 즉시 반환합니다.

```python
def fib_top_down(n):
    memo = [None] * (n + 1)

    def solve(k):
        if k <= 1:
            return k
        if memo[k] is not None:
            return memo[k]
        memo[k] = solve(k - 1) + solve(k - 2)
        return memo[k]

    return solve(n)
```

`None`은 “아직 계산하지 않음”을 나타내고 실제 값 `0`과 구분됩니다. 단위 비용 정수 덧셈과 저장 정수 개수 모델에서 각 $$k$$는 처음 호출될 때만 두 하위 문제를 계산하므로 시간은 $$\Theta(n)$$입니다. 메모 테이블과 최대 깊이 $$n$$의 호출 스택을 합한 공간도 $$\Theta(n)$$입니다. Python의 무한 정밀 정수에 대한 비트 비용을 세면 bottom-up과 마찬가지로 이보다 커집니다. 피보나치에서는 목표 $$n$$을 계산하면 결국 0부터 $$n$$까지 모두 필요하지만, 도달 가능한 상태가 희소한 문제에서는 top-down이 필요한 상태만 계산한다는 차이가 생깁니다.

## 4. Matrix Path Problem

### 4.1 Problem and state

$$R\times C$$ 행렬 $$M$$의 왼쪽 위 $$(0,0)$$에서 오른쪽 아래 $$(R-1,C-1)$$까지 이동합니다. 한 번에 오른쪽 또는 아래로만 갈 수 있고, 방문한 모든 칸의 값을 더합니다. 여기서는 $$R,C\ge1$$인 직사각형 행렬이고 모든 행의 길이가 같으며, 각 칸의 값은 덧셈과 비교가 가능한 유한 실수라고 가정합니다. 슬라이드는 $$n\times n$$을 사용하지만 직사각형으로 일반화해도 점화식은 같습니다(17쪽).

$$P_{i,j}$$를 시작 칸에서 $$(i,j)$$까지 가는 유효한 경로 중 최대 합으로 정의합니다. $$i,j$$는 단위 없는 0-based 인덱스이고, $$M_{i,j}$$와 $$P_{i,j}$$의 단위는 입력 점수와 같습니다.

### 4.2 Recurrence and boundary cases

마지막 이동은 위 $$(i-1,j)$$ 또는 왼쪽 $$(i,j-1)$$에서만 올 수 있습니다. 두 후보는 각 선행 칸까지의 최대 합에 현재 칸 $$M_{i,j}$$를 한 번 더한 값입니다. 어느 쪽에서 와도 더하는 값이 같으므로, 선행 경로 둘 중 큰 값을 고른 뒤 현재 칸을 더합니다. 시작 칸에는 선행 경로가 없고 첫 행·첫 열에는 선행 방향이 하나뿐입니다. 따라서 정확한 경계 처리를 포함한 점화식은 다음과 같습니다.

$$
\begin{aligned}
P_{0,0}&=M_{0,0},\\
P_{0,j}&=P_{0,j-1}+M_{0,j} && (j>0),\\
P_{i,0}&=P_{i-1,0}+M_{i,0} && (i>0),\\
P_{i,j}&=\max(P_{i-1,j},P_{i,j-1})+M_{i,j} && (i>0,\ j>0).
\end{aligned}
$$

이는 정확한 등식이며 행렬 값이 양수라는 가정이 필요 없습니다. 슬라이드 18쪽처럼 행렬 밖 상태를 0으로 두는 표기는 모든 도달 가능한 부분 경로 합이 0 이상이면 **최댓값 계산에는 안전합니다**. 그러나 음수 합이 가능한 일반 문제에서는 존재하지 않는 경로를 $$-\infty$$로 두거나 위처럼 첫 행과 첫 열을 별도로 초기화해야 합니다.

작은 음수 예제로 $$M=[[-3,-4],[-2,-1]]$$을 보겠습니다. `·`는 아직 채우지 않은 상태입니다. 빈 표에서 시작해 가능한 선행 칸만 사용하면 계산이 다음 순서로 진행됩니다.

| 단계 | 새로 채운 상태 | 계산 | `P`의 첫 행 / 둘째 행 |
|---|---|---|---|
| 시작 | 없음 | 기저 사례를 넣기 전 | `[·, ·] / [·, ·]` |
| 1 | `P[0,0]` | `-3` | `[-3, ·] / [·, ·]` |
| 2 | `P[0,1]` | `-3-4=-7` | `[-3, -7] / [·, ·]` |
| 3 | `P[1,0]` | `-3-2=-5` | `[-3, -7] / [-5, ·]` |
| 4 | `P[1,1]` | `max(-7,-5)-1=-6` | `[-3, -7] / [-5, -6]` |

최종 답은 $$P_{1,1}=-6$$입니다. 첫 행만 떼어 $$1\times2$$ 입력 `[-3, -4]`로 보아도 정답은 $$-7$$인데, 행렬 밖을 0점 경로로 허용하면 두 번째 칸을 $$0-4=-4$$로 계산해 시작 칸 $$-3$$을 거치지 않은 가짜 경로를 택합니다. 그래서 불가능한 상태의 0과 실제로 합이 0인 경로는 다르게 취급해야 합니다.

### 4.3 Why optimal substructure holds

$$(i,j)$$까지의 최적 경로가 위 칸에서 왔다고 하겠습니다. 그 경로에서 $$(i-1,j)$$까지의 접두 경로가 해당 칸까지의 최적 경로가 아니라면, 더 큰 합을 가진 경로로 접두 부분을 교체할 수 있습니다. 마지막 한 칸 이동과 $$M_{i,j}$$는 그대로이므로 전체 합이 더 커져 원래 경로가 최적이라는 가정과 모순됩니다. 왼쪽 칸에서 오는 경우도 같습니다. 따라서 최적 경로는 두 선행 상태의 최적값 중 하나를 반드시 포함합니다.

### 4.4 Bottom-up evaluation and reconstruction

행 우선으로 위에서 아래, 왼쪽에서 오른쪽으로 채우면 현재 칸의 두 선행 상태가 이미 계산되어 있습니다. 최댓값뿐 아니라 어느 선행 칸을 골랐는지도 저장하면 경로를 복원할 수 있습니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Maximum matrix path and parent reconstruction</summary>

```python
def matrix_path(mat):
    rows, cols = len(mat), len(mat[0])
    dp = [[float("-inf")] * cols for _ in range(rows)]
    parent = [[None] * cols for _ in range(rows)]
    dp[0][0] = mat[0][0]

    for i in range(rows):
        for j in range(cols):
            if i == 0 and j == 0:
                continue

            candidates = []
            if i > 0:
                candidates.append((dp[i - 1][j], (i - 1, j)))
            if j > 0:
                candidates.append((dp[i][j - 1], (i, j - 1)))

            best, previous = max(candidates)
            dp[i][j] = best + mat[i][j]
            parent[i][j] = previous

    path = []
    current = (rows - 1, cols - 1)
    while current is not None:
        path.append(current)
        current = parent[current[0]][current[1]]
    path.reverse()
    return dp[-1][-1], path
```

- 입력 `mat`의 shape는 `(rows, cols)`입니다. 같은 shape의 `dp`는 각 칸까지의 최대 합, `parent`는 그 값을 만든 선행 좌표를 저장합니다.
- 행 우선 순회에서는 위와 왼쪽 상태가 먼저 계산됩니다. 존재하는 후보만 모으므로 음수 입력에서도 행렬 밖의 가짜 0점 경로가 생기지 않습니다.
- 출력은 오른쪽 아래의 최대 합과 좌표 경로입니다. `parent`를 끝에서 시작점까지 따라간 뒤 뒤집어 진행 순서를 복원합니다.

</details>

동점에서는 Python의 tuple 비교 규칙에 따라 한 선행 칸이 결정됩니다. 최댓값만 필요하면 어느 쪽을 택해도 맞지만, 재현 가능한 경로가 필요하면 “동점 시 위 우선”처럼 정책을 명시적으로 정하는 편이 좋습니다. 테이블 계산은 $$RC$$개 상태를 한 번씩 처리하므로 시간과 `dp` 공간은 $$\Theta(RC)$$입니다. `parent`도 $$\Theta(RC)$$이고 복원은 경로 길이 $$R+C-1$$에 비례합니다.

### 4.5 Top-down evaluation

Top-down 구현도 상태와 점화식은 같지만, `None`으로 계산 여부를 구분합니다. 값 `0`을 미계산 표시로 사용하면 실제 최적합이 0인 상태를 반복 계산하게 됩니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Memoized maximum matrix path</summary>

```python
def matrix_path_top_down(mat):
    rows, cols = len(mat), len(mat[0])
    memo = [[None] * cols for _ in range(rows)]

    def solve(i, j):
        if i == 0 and j == 0:
            return mat[0][0]
        if memo[i][j] is not None:
            return memo[i][j]

        candidates = []
        if i > 0:
            candidates.append(solve(i - 1, j))
        if j > 0:
            candidates.append(solve(i, j - 1))
        memo[i][j] = max(candidates) + mat[i][j]
        return memo[i][j]

    return solve(rows - 1, cols - 1)
```

- `solve(i, j)`의 출력은 시작점부터 좌표 `(i, j)`까지의 최대 합입니다. 시작점이 기저 사례이며, `memo`의 `None`은 계산하지 않은 상태만 뜻합니다.
- 현재 칸은 존재하는 위·왼쪽 상태만 재귀 호출합니다. 두 후보의 큰 값에 현재 칸을 더하고 같은 좌표의 메모 칸에 저장합니다.
- 최종 출력은 최대 합입니다. 경로가 필요하면 선택한 선행 좌표를 별도로 저장해야 합니다.

</details>

최악의 경우 모든 칸을 계산하므로 시간과 메모 공간은 $$\Theta(RC)$$이고, 호출 스택 깊이는 $$O(R+C)$$입니다. 경로까지 필요하면 각 상태에서 선택한 선행 좌표를 저장하거나, 계산된 값에서 두 선행 후보를 다시 비교하며 역추적할 수 있습니다.

### 4.6 Independently checked trace

17·19쪽의 행렬을 행 우선으로 계산하면 `dp`는 다음과 같습니다.

| 행 | 열 0 | 열 1 | 열 2 | 열 3 |
|---|---:|---:|---:|---:|
| 0 | 6 | 13 | 25 | 30 |
| 1 | 11 | 16 | 36 | 54 |
| 2 | 18 | 35 | 39 | 57 |
| 3 | 26 | 45 | 59 | 68 |

최댓값은 68이고, 한 최적 경로는 다음과 같습니다.

$$
\begin{aligned}
&(0,0)\rightarrow(1,0)\rightarrow(2,0)\rightarrow(2,1)\\
&\rightarrow(3,1)\rightarrow(3,2)\rightarrow(3,3).
\end{aligned}
$$

방문 값은 `6, 5, 7, 17, 10, 14, 9`이고 합은 68입니다. 오른쪽·아래쪽으로 이루어진 가능한 20개 경로를 전수 열거한 결과와도 일치합니다. 슬라이드에 노란색으로 표시된 경로의 합은 `6+7+12+11+18+3+9=66`이므로 문제의 최적 경로 예시로는 맞지 않습니다.

## 5. Matrix Multiplication Order Problem

### 5.1 Problem and dimension vector

<figure class="study-source-figure">
  <a href="{{ "/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf#page=24" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/algorithms/source-figures/lecture-09-p24-matrix-chain-recurrence.jpg" | relative_url }}" alt="행렬 연쇄의 마지막 분할점을 모두 열거해 최소 비용을 고르는 점화식을 보여 주는 강의 슬라이드" loading="lazy"></a>
  <figcaption>원문 강의 PDF p. 24. `A1…A7`을 마지막에 어디서 둘로 나눌지 모두 후보로 만들고, 두 부분 비용과 마지막 행렬 곱 비용의 합이 가장 작은 분할을 고릅니다.</figcaption>
</figure>

$$m\ge1$$개의 행렬 $$A_0,A_1,\ldots,A_{m-1}$$을 곱합니다. 행렬 곱은 결합법칙을 만족하므로 괄호 위치를 바꿔도 결과 행렬은 같지만, 스칼라 곱셈 횟수는 달라질 수 있습니다(22쪽). 인접 행렬의 안쪽 차원이 일치하고 모든 차원이 양의 정수라고 가정하며, 차원 벡터를

$$
p=(p_0,p_1,\ldots,p_m)
$$

라고 하면 $$A_i$$의 크기는 $$p_i\times p_{i+1}$$입니다. $$a\times b$$ 행렬과 $$b\times c$$ 행렬을 곱할 때 각 출력 원소 $$ac$$개가 길이 $$b$$의 내적을 수행하므로 스칼라 곱셈 수는 정확히 $$abc$$회입니다. $$p_i$$의 단위는 행 또는 열의 원소 수이고, 비용의 단위는 스칼라 곱셈 횟수입니다.

### 5.2 Half-open interval state and recurrence

$$S(s,e)$$를 반열린 구간의 곱 $$A_sA_{s+1}\cdots A_{e-1}$$을 계산하는 최소 스칼라 곱셈 수로 정의합니다. 결과 행렬의 크기는 $$p_s\times p_e$$입니다. 행렬 하나는 곱셈이 필요 없으므로 기저 사례는 다음과 같습니다.

$$
S(s,s+1)=0.
$$

마지막 곱셈은 연속한 왼쪽 구간 $$[s,k)$$과 오른쪽 구간 $$[k,e)$$의 결과 사이에서 일어나므로 $$s<k<e$$인 모든 분할점을 확인합니다. 분할점을 $$k$$로 선택하면 왼쪽·오른쪽을 만드는 최소 비용은 각각 $$S(s,k)$$, $$S(k,e)$$입니다. 두 결과의 크기는 내부 괄호와 무관하게 $$p_s\times p_k$$, $$p_k\times p_e$$로 정해지고, 마지막에 이들을 곱하는 비용은 $$p_sp_kp_e$$입니다. 각 분할점의 세 비용을 더해 후보를 만든 뒤 그중 가장 작은 값을 고릅니다. 따라서 정확한 점화식은 다음과 같습니다(24쪽).

$$
S(s,e)=\min_{s<k<e}
\left\{S(s,k)+S(k,e)+p_sp_kp_e\right\}.
$$

### 5.3 Why optimal substructure holds

최적 괄호 묶기의 마지막 분할점이 $$k$$라고 하겠습니다. 왼쪽 부분 $$A_s\cdots A_{k-1}$$의 계산 순서가 그 부분의 최소 비용이 아니라면, 더 싼 순서로 바꾸어도 왼쪽 결과의 크기 $$p_s\times p_k$$는 변하지 않습니다. 따라서 마지막 곱셈 비용과 오른쪽 비용은 그대로인데 전체 비용만 줄어들어 최적성에 모순됩니다. 오른쪽 부분도 같은 논리이므로 두 부분은 각각 최적이어야 합니다.

### 5.4 Bottom-up tabulation and reconstruction

길이 1 구간을 먼저 0으로 두고, 구간 너비 2부터 증가시키면 $$S(s,e)$$가 참조하는 두 짧은 구간이 이미 계산되어 있습니다. 최소 비용을 만든 분할점도 `split[s][e]`에 저장합니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Bottom-up matrix-chain cost and reconstruction</summary>

```python
def matrix_chain_order(p):
    n = len(p)
    cost = [[float("inf")] * n for _ in range(n)]
    split = [[None] * n for _ in range(n)]

    for s in range(n - 1):
        cost[s][s + 1] = 0

    for width in range(2, n):
        for s in range(n - width):
            e = s + width
            for k in range(s + 1, e):
                candidate = (
                    cost[s][k]
                    + cost[k][e]
                    + p[s] * p[k] * p[e]
                )
                if candidate < cost[s][e]:
                    cost[s][e] = candidate
                    split[s][e] = k

    def parenthesize(s, e):
        tokens = []

        def emit(left, right):
            if right - left == 1:
                tokens.append(f"A{left}")
                return
            k = split[left][right]
            tokens.append("(")
            emit(left, k)
            emit(k, right)
            tokens.append(")")

        emit(s, e)
        return "".join(tokens)

    return cost[0][n - 1], parenthesize(0, n - 1)
```

- 입력 `p`는 길이 `m + 1`의 차원 벡터입니다. `cost[s][e]`는 반열린 행렬 구간 `[s, e)`의 최소 곱셈 수, `split[s][e]`는 그 값을 만든 마지막 분할점입니다.
- 구간 너비가 작은 순서로 채우므로 후보 `cost[s][k]`와 `cost[k][e]`는 이미 계산되어 있습니다. 모든 `k` 중 최소 후보만 저장합니다.
- 출력은 전체 최소 비용과 괄호 문자열입니다. 복원 함수는 `split`의 이진 분할을 따라 토큰을 모은 뒤 한 번에 결합합니다.

</details>

행렬 수를 $$m=n-1$$이라 하면 구간 상태는 $$\Theta(m^2)$$개이고 각 상태에서 최대 $$m-1$$개 분할점을 확인합니다. 차원 곱과 비용의 덧셈·비교를 단위 비용으로 세면 시간은 $$\Theta(m^3)$$, `cost`와 `split` 공간은 $$\Theta(m^2)$$입니다. 큰 차원에서 비용 정수의 비트 수까지 세면 산술 비용을 별도로 곱해야 합니다. 복원은 이진 분할 트리의 $$\Theta(m)$$개 노드를 방문하며, 위 구현은 토큰을 모아 한 번만 `join`하므로 문자열 작성 시간은 최종 출력 길이에 비례합니다. 행렬 인덱스를 십진수로 쓰면 출력 길이는 $$O(m\log m)$$일 수 있습니다.

### 5.5 Top-down memoization

27쪽의 구현처럼 목표 구간에서 재귀를 시작할 수도 있습니다. 차원이 양의 정수이면 모든 실제 비용은 0 이상이므로 `-1`도 미계산 표시로 사용할 수 있지만, 값과 상태를 명확히 분리하기 위해 `None`을 쓰는 편이 안전합니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Memoized matrix-chain cost</summary>

```python
def matrix_chain_top_down(p):
    n = len(p)
    memo = [[None] * n for _ in range(n)]

    def solve(s, e):
        if e - s == 1:
            return 0
        if memo[s][e] is not None:
            return memo[s][e]

        memo[s][e] = min(
            solve(s, k) + solve(k, e) + p[s] * p[k] * p[e]
            for k in range(s + 1, e)
        )
        return memo[s][e]

    return solve(0, n - 1)
```

- `solve(s, e)`는 `[s, e)`의 최소 스칼라 곱셈 수를 반환합니다. 행렬 하나인 길이 1 구간은 비용 0입니다.
- 모든 분할점 `k`에서 왼쪽 비용, 오른쪽 비용, 마지막 곱셈 비용을 더하고 최솟값을 메모합니다.
- 이 버전의 출력은 비용뿐입니다. 괄호 구조까지 보존하려면 최솟값을 만든 `k`를 함께 저장합니다.

</details>

최악의 경우 가능한 모든 구간과 분할점을 확인하므로 bottom-up과 같은 $$\Theta(m^3)$$ 시간과 $$\Theta(m^2)$$ 메모 공간을 사용합니다. 최종 최소 비용 숫자만 남기면 일반적으로 괄호 묶기를 알 수 없습니다. 전체 비용 테이블을 보존했다면 각 구간의 후보 $$k$$를 다시 비교해 복원할 수 있고, 계산 중 선택한 $$k$$를 별도 테이블에 저장하면 그 재비교를 피하고 동점 처리 결과도 보존할 수 있습니다.

### 5.6 Independently checked example

23쪽의 차원 벡터는 $$p=(10,100,5,50)$$입니다.

처음에는 한 행렬씩인 $$S(0,1)=S(1,2)=S(2,3)=0$$만 압니다. 길이 2 구간을 채우면 $$S(0,2)=10\cdot100\cdot5=5000$$, $$S(1,3)=100\cdot5\cdot50=25000$$입니다. 이제 전체 구간 $$S(0,3)$$에서 가능한 마지막 분할은 $$k=1$$과 $$k=2$$뿐입니다. 아래 첫째 줄은 $$k=2$$, 둘째 줄은 $$k=1$$에서 얻는 총비용입니다.

$$
\begin{aligned}
(A_0A_1)A_2 &: 10\cdot100\cdot5+10\cdot5\cdot50=5000+2500=7500,\\
A_0(A_1A_2) &: 100\cdot5\cdot50+10\cdot100\cdot50=25000+50000=75000.
\end{aligned}
$$

따라서 최소 비용은 7,500회이고 복원된 순서는 `((A0A1)A2)`입니다. 두 괄호 묶기는 같은 $$10\times50$$ 결과를 만들지만 비용은 10배 차이 납니다.

## 6. State, Order, and Reconstruction Comparison

| 문제 | 상태 | 기저 사례 | Bottom-up 평가 순서 | 복원 정보 |
|---|---|---|---|---|
| Fibonacci | $$F_i$$ | $$F_0=0, F_1=1$$ | 인덱스 증가 | 보통 최종 값만 필요 |
| Matrix Path | $$P_{i,j}$$ | 시작 칸, 첫 행, 첫 열 | 행 우선 또는 열 우선 | 선택한 이전 칸 |
| Matrix Chain | $$S(s,e)$$ | $$S(s,s+1)=0$$ | 구간 너비 증가 | 최소 비용을 만든 분할점 $$k$$ |

Top-down에서는 표의 순서를 반복문으로 직접 쓰지 않습니다. 재귀가 의존 상태를 먼저 방문하고 반환하면서 그 순서를 만듭니다. 반대로 bottom-up에서는 올바른 위상 순서를 반복문으로 명시해야 합니다. 어느 방식이든 최종 값 하나만으로는 보통 해답 구조를 알 수 없습니다. 선택을 함께 저장하면 바로 역추적할 수 있고, 필요한 값 테이블이 남아 있다면 후보를 다시 비교해 선택을 찾아낼 수도 있습니다.

## Source Formula Map

<details markdown="block">
<summary markdown="span">Reference: formulas and their source slides</summary>

| PDF 쪽 | 원문의 핵심 식·코드 | 본문의 대응 |
|---|---|---|
| 4 | 무작위 Quickselect의 평균 재귀 상한 | Previous Lecture Recap의 기대 선형 시간 설명 |
| 5 | $$T(n)\le T(n/5)+T(7n/10)+c_0n$$ | 이상화된 식의 귀납 조건과 실제 반올림 항 처리 |
| 10–12 | $$F_n=F_{n-1}+F_{n-2}$$, $$\Theta(\phi^n)$$ 재귀 | 상태 정의, 호출 수 유도, 중복 호출 |
| 13–15 | 피보나치 tabulation·memoization | 두 구현, 평가 순서, 시간·공간 비교 |
| 18 | $$P_{i,j}=\max(P_{i-1,j},P_{i,j-1})+M_{i,j}$$ | 경계까지 포함한 점화식과 최적 부분 구조 증명 |
| 19–20 | Matrix Path bottom-up·top-down 코드 | 안전한 초기화, `None` 메모, 경로 복원 |
| 22–23 | $$abc$$ 스칼라 곱셈 비용, 7,500/75,000 예제 | 비용 단위의 유도와 독립 검산 |
| 24 | $$S(s,e)$$ 반열린 구간 점화식 | 차원 일치, 최적 부분 구조 증명 |
| 26–27 | Matrix Chain bottom-up·top-down 코드 | 구간 너비 순서, 메모, 분할점 복원 |

</details>

## Source Check

<details markdown="block">
<summary markdown="span">Source notes: assumptions and corrections</summary>

| 슬라이드 위치 | 확인 결과 | 이 글의 처리 |
|---|---|---|
| 9쪽 | 부분 문제의 해답을 결합하는 구조를 optimal substructure로 함께 설명 | 일반적인 재귀적 부분 구조와 최적화 문제의 최적 부분 구조를 구분했습니다. Fibonacci는 최적화가 아닌 수열 계산입니다. |
| 4쪽 | Quickselect 기대 시간 상한의 합은 $$\lfloor n/2\rfloor$$부터 시작하며, 홀수 입력의 중앙 크기는 계수 2에 의해 중복 계산됨 | 중앙 항의 중복이 등식이 아니라 안전한 상한을 만든다고 설명했습니다. |
| 5쪽 | $$n/5$$와 $$7n/10$$은 반올림 상수항을 생략한 표기 | 실제 재귀 입력의 $$O(1)$$ 오차, 충분히 큰 $$n$$의 선형 여유분, 유한 기저 구간 확대를 구분했습니다. |
| 12쪽 | 단순 재귀의 호출 수는 피보나치 성장률을 가져 $$\Theta(\phi^n)$$ | $$C_n=2F_{n+1}-1$$로 호출 수를 직접 연결했습니다. |
| 13–14쪽 | `memo = [0, 1] + [-1] * n`은 필요한 길이보다 한 칸 크지만 동작 가능 | 정확히 `n+1`칸을 만들고, 실제 값과 충돌하지 않는 `None`을 사용했습니다. |
| 18쪽 | 행렬 밖을 0으로 두는 점화식은 음수 값에서 존재하지 않는 경로를 선택할 수 있음 | 시작 칸·첫 행·첫 열을 명시하고 일반 입력에 맞는 경계를 사용했습니다. |
| 19쪽 | `[[0] * n+1 ...]`은 Python에서 리스트에 정수 `1`을 더하려 해 실행 오류 | 올바른 크기의 2차원 테이블로 고쳤습니다. |
| 19쪽 | 음수 인덱스로 마지막 행·열을 경계처럼 쓰는 구현은 Python 표현에 의존 | 유효한 선행 칸만 후보에 넣어 언어의 음수 인덱스에 의존하지 않습니다. |
| 20쪽 | `0`을 미계산 표시로 쓰면 실제 최적합이 0인 상태를 구분하지 못함 | `None`으로 계산 여부를 분리했습니다. |
| 17·19쪽 | 노란 경로의 합은 66이지만 가능한 경로의 실제 최댓값은 68 | 20개 경로 전수 열거와 DP가 같은 68을 내는지 검산하고 최적 경로를 제시했습니다. |
| 22쪽 | $$a\times b$$와 $$b\times c$$의 곱셈 비용은 $$abc$$회 | 출력 원소 수와 내적 길이로 단위를 유도했습니다. |
| 23쪽 | 두 순서의 비용은 각각 7,500회와 75,000회 | 각 항을 다시 계산하고 DP 복원 결과 `((A0A1)A2)`와 대조했습니다. |
| 24·26쪽 | $$S(s,e)$$는 $$A_s\cdots A_{e-1}$$의 반열린 구간 | 결과 차원 $$p_s\times p_e$$와 기저 $$S(s,s+1)=0$$을 일관되게 사용했습니다. |

</details>

## 마지막 핵심 정리

- 동적 계획법은 재귀적 부분 구조와 중복 부분 문제를 활용합니다. 최적화 문제에서는 최적 부분 구조가 필요합니다. 저장은 중복 계산을 없애지만 잘못된 상태 정의나 점화식을 고쳐 주지는 않습니다.
- Top-down은 필요한 상태를 재귀적으로 방문하고, bottom-up은 의존 관계를 만족하는 순서를 반복문으로 명시합니다.
- Matrix Path의 상태는 “해당 칸까지의 최대 합”이며, 경계는 존재하지 않는 경로가 선택되지 않도록 처리해야 합니다. 슬라이드 예제의 실제 최댓값은 68입니다.
- Matrix Chain의 상태는 반열린 행렬 구간의 최소 비용입니다. 짧은 구간부터 계산하면 $$\Theta(m^3)$$ 시간, $$\Theta(m^2)$$ 공간에 최소 비용을 얻습니다.
- 최종 최적값 하나와 실제 해답 구조는 다릅니다. 이전 칸·분할점을 계산 중 저장하면 복원이 빠르고, 전체 값 테이블이 남아 있으면 후보를 다시 비교해 경로나 괄호 묶기를 복원할 수 있습니다.

다음 강의에서는 동적 계획법의 다른 문제와 설계 패턴을 이어서 다룹니다(30쪽).

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

1. 각 문제에서 상태를 한 문장으로 먼저 정의하고, 인덱스 범위와 값의 단위를 적습니다.
2. 점화식을 쓰기 전에 가능한 마지막 선택을 모두 나열합니다. Matrix Path는 위·왼쪽, Matrix Chain은 모든 분할점입니다.
3. 기저 사례와 불가능한 상태를 구분합니다. 비용 0과 미계산, 유효한 0점 경로와 행렬 밖 경로는 같은 상태가 아닙니다.
4. Bottom-up 반복문의 방향이 의존 관계를 만족하는지 확인합니다. 행렬 연쇄에서는 시작점을 옮기기 전에 구간 너비부터 늘려야 합니다.
5. 작은 입력을 손으로 계산한 뒤 코드의 테이블과 대조합니다. 최적값뿐 아니라 복원된 경로나 괄호 묶기도 검산합니다.
6. 복잡도는 상태 수와 상태당 전이 수를 곱해 계산합니다. Matrix Path는 $$RC\cdot O(1)$$, Matrix Chain은 $$O(m^2)\cdot O(m)$$입니다.

</details>

## 복습 질문

<details markdown="block">
<summary>Q&A: What is the difference between optimal substructure and overlapping subproblems?</summary>

답변: 최적 부분 구조는 최적화 문제에서 전체 최적해가 부분 문제의 최적해를 포함한다는 정확성 조건입니다. 중복 부분 문제는 같은 상태가 재귀 과정에서 여러 번 등장한다는 효율 조건입니다. 전자는 점화식이 최적값을 보장하는 이유이고, 후자는 메모나 테이블이 계산량을 줄이는 이유입니다. Fibonacci처럼 최적값을 찾지 않는 문제에서는 작은 상태의 값으로 큰 상태의 값을 구성하는 재귀적 부분 구조를 사용합니다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Why does memoized Fibonacci take $$\Theta(n)$$ time?</summary>

답변: `solve(k)`가 처음 실행될 때만 하위 상태를 계산하고, 이후 호출은 저장된 값을 상수 시간에 반환합니다. 서로 다른 상태는 0부터 $$n$$까지 $$n+1$$개이고 각 상태의 실제 계산은 덧셈 한 번이므로 전체 시간은 $$\Theta(n)$$입니다.

</details>

<details markdown="block">
<summary>Q&A: Why is zero an unsafe outside-grid value for a maximum path?</summary>

답변: 행렬 값이 음수이면 유효한 선행 경로의 합보다 0이 더 클 수 있습니다. 그러면 알고리즘이 실제로 존재하지 않는 행렬 밖 경로에서 들어온 것처럼 선택합니다. 불가능 상태는 $$-\infty$$로 두거나 시작 칸·첫 행·첫 열을 별도로 초기화해야 합니다.

</details>

<details markdown="block">
<summary>Q&A: Why must matrix-chain tabulation increase interval width?</summary>

답변: $$S(s,e)$$는 모든 분할점 $$k$$에 대해 더 짧은 두 구간 $$S(s,k)$$와 $$S(k,e)$$를 참조합니다. 구간 너비를 1, 2, 3의 순서로 늘리면 현재 상태에 필요한 두 값이 이미 계산되어 있습니다. 시작 인덱스만 증가시키는 순서는 이 의존 관계를 보장하지 않습니다.

</details>

<details markdown="block">
<summary>Q&A: Why is a split table needed when the minimum cost table already exists?</summary>

답변: 분할점 테이블은 각 구간에서 선택한 $$k$$를 기록하므로, 후보 비용을 다시 비교하지 않고 괄호 묶기를 역추적할 수 있으며 동점 때 고른 쪽도 유지합니다. 필수인 것은 아닙니다. 전체 비용 테이블이 남아 있으면 후보 $$k$$를 다시 비교해 최적 괄호 묶기 하나를 찾을 수 있지만, 최종 최소 비용 숫자 하나만으로는 일반적으로 복원할 수 없습니다.

</details>

## References

- Youngwook Kim, *9. Dynamic Programming (1)*, Algorithms lecture slides, pp. 1–31.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf" | relative_url }}" target="_blank" rel="noopener">9 Dynamic Programming (1).pdf</a></li>
</ul>
