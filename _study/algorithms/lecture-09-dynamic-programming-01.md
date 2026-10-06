---
layout: default
date: 2026-10-06 12:10:00 +0900
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

이 강의는 재귀식에 같은 부분 문제가 반복해서 나타날 때, 그 답을 한 번만 계산해 저장하는 동적 계획법을 소개한다. 피보나치 수로 top-down과 bottom-up의 차이를 확인한 뒤, 격자 최대 경로와 행렬 연쇄 곱셈 순서 문제에서 상태·점화식·계산 순서를 설계한다. 아래의 최적 부분 구조 증명, 경계 조건 교정, 경로와 괄호 복원은 슬라이드의 전개를 정확히 연결하기 위한 보충 설명이다.

> **핵심:** 동적 계획법은 점화식만 세우는 기법이 아니다. **상태가 무엇을 뜻하는지**, **기저 사례가 무엇인지**, **의존 상태가 먼저 계산되는 순서가 무엇인지**, **최적값을 만든 선택을 어떻게 복원할지**까지 함께 설계해야 한다.

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

3–5쪽은 선택 문제와 Quickselect, median of medians를 복습한다. 무작위 피벗 Quickselect의 기대 시간 분석에서는 재귀적으로 남는 부분 배열 크기를 평균내어 다음 상한을 사용한다.

$$
T(n)
\le \frac{2}{n}\sum_{k=\lfloor n/2\rfloor}^{n-1}T(k)+c_0n.
$$

귀납 가설 $$T(k)\le ck$$를 대입하면 재귀항은 $$3cn/4$$ 이하로 묶인다. 홀수 $$n$$에서는 대칭인 두 피벗 경우가 같은 중앙 크기를 만들 수 있는데, 위 식의 계수 2는 그 중앙 항까지 두 번 세므로 등식이 아니라 안전한 상한이다. 충분히 큰 상수 $$c$$를 택하면 선형항 $$c_0n$$을 흡수할 수 있어 기대 시간 $$T(n)=O(n)$$을 얻는다. 여기서 $$n$$은 원소 수, $$T(n)$$은 기본 연산 횟수, $$c$$와 $$c_0$$은 연산 횟수의 상수 계수다.

median of medians를 피벗 선택에 사용하면 최악의 경우에도 다음과 같은 재귀 상한을 얻는다(5쪽). 먼저 슬라이드가 사용하는 반올림을 생략한 형태는 다음과 같다.

$$
T(n)\le T\!\left(\frac{n}{5}\right)+T\!\left(\frac{7n}{10}\right)+c_0n.
$$

이 이상화된 식에 같은 귀납 가설을 대입하면 재귀항의 합이 $$9cn/10$$ 이하이므로 $$c\ge 10c_0$$이면 $$T(n)\le cn$$이다. 실제 그룹 수와 제거되는 원소 수에는 반올림이 들어가므로 더 정확한 형태는 $$T(\lceil n/5\rceil)+T(7n/10+O(1))+c_0n$$이다. 충분히 큰 $$n$$에서는 두 재귀 입력 비율의 합이 1보다 작은 상태로 유지되어 반올림의 상수 오차를 선형 여유분이 흡수한다. 그 임계값 아래의 유한한 기저 구간까지 $$c$$를 확대하면 최악 시간 $$O(n)$$이 성립한다. 이 복습은 “큰 문제를 더 작은 문제의 답으로 표현한다”는 재귀적 사고를 동적 계획법으로 이어 주지만, 선택 알고리즘 자체는 이번 강의의 DP 예제가 아니다.

## 2. Dynamic Programming

### 2.1 When DP applies

슬라이드는 동적 계획법의 출발점을 두 조건으로 설명한다(9쪽).

1. 큰 문제의 해답이 작은 문제의 해답으로 구성되는 **재귀적 부분 구조**가 있다. 최적화 문제에서는 전체 최적해가 부분 문제의 최적해를 포함하는 **최적 부분 구조**가 필요하다.
2. 재귀 호출 트리에서 같은 부분 문제가 여러 번 계산되는 **중복 부분 문제**가 있다.

첫 조건은 올바른 점화식을 세울 근거이고, 둘째 조건은 계산 결과를 저장했을 때 이득을 얻는 이유다. 피보나치는 정의된 수열의 값을 계산하는 문제이지 최적화 문제가 아니다. 반면 Matrix Path와 Matrix Chain에서는 최적 부분 구조를 증명해야 한다. 중복이 거의 없는 재귀는 메모 테이블을 두어도 큰 이득이 없고, 최적 부분 구조가 성립하지 않으면 작은 문제의 최적값만 이어 붙여 전체 최적값을 보장할 수 없다.

### 2.2 Four design decisions

| 설계 항목 | 확인할 질문 | 이 강의의 예 |
|---|---|---|
| 상태 | 테이블 한 칸이 정확히 무엇을 뜻하는가? | `fib[i]`, $$P_{i,j}$$, $$S(s,e)$$ |
| 기저 사례 | 더 쪼갤 필요가 없는 가장 작은 문제는 무엇인가? | $$F_0=0$$, $$F_1=1$$; 시작 칸; 행렬 한 개 |
| 평가 순서 | 현재 상태가 의존하는 상태가 먼저 계산되는가? | 작은 인덱스, 행 우선, 짧은 행렬 구간 순서 |
| 복원 정보 | 최적값을 만든 선택을 어떻게 되찾는가? | 이전 칸 좌표, 최적 분할점 |

Top-down memoization은 목표 상태에서 출발해 필요한 상태만 재귀적으로 계산하고, 첫 계산 결과를 저장한다. Bottom-up tabulation은 기저 상태에서 시작해 의존 관계를 만족하는 순서로 테이블을 채운다. 두 방식은 같은 상태와 점화식을 계산할 수 있지만 호출 스택, 계산되는 상태의 범위, 평가 순서를 표현하는 방법이 다르다.

## 3. Fibonacci Numbers

### 3.1 State and recurrence

피보나치 상태 $$F_n$$은 0부터 세었을 때 $$n$$번째 피보나치 수다. 여기서는 입력 $$n$$이 0 이상의 정수라고 가정한다. 인덱스 $$n$$은 무차원 정수이고, $$F_n$$은 문제에서 세는 경우의 수이므로 단위가 없는 개수다(10쪽).

$$
F_0=0,\qquad F_1=1,\qquad F_n=F_{n-1}+F_{n-2}\quad(n\ge2).
$$

각 항은 바로 앞의 두 항을 더해 정의된다. 따라서 이 식은 근사가 아니라 수열의 정의에서 나오는 정확한 등식이다.

### 3.2 Why the naive recursion is exponential

11–12쪽의 재귀 함수는 점화식을 그대로 실행한다.

```python
def fib_recursive(n):
    if n <= 1:
        return n
    return fib_recursive(n - 1) + fib_recursive(n - 2)
```

함수 호출 수를 $$C_n$$이라 두면 $$C_0=C_1=1$$이고 다음 식이 성립한다.

$$
C_n=C_{n-1}+C_{n-2}+1.
$$

$$D_n=C_n+1$$로 놓으면 $$D_n=D_{n-1}+D_{n-2}$$가 되어 피보나치와 같은 성장률을 갖는다. 실제로 $$C_n=2F_{n+1}-1$$이며, $$\phi=(1+\sqrt5)/2$$일 때 호출 수는 $$\Theta(\phi^n)$$이다. `fib(5)` 안에서 `fib(3)`과 `fib(2)`가 여러 번 호출되는 그림은 이 중복을 보여 준다. 실행 시간의 단위는 기본 호출 횟수이고, 재귀 깊이는 최대 $$n$$이므로 호출 스택 공간은 $$\Theta(n)$$이다.

### 3.3 Bottom-up tabulation

작은 인덱스부터 테이블을 채우면 각 상태를 정확히 한 번 계산한다(13쪽).

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

평가 순서는 `0, 1, 2, ..., n`이다. `table[i]`를 계산할 때 `table[i-1]`과 `table[i-2]`가 이미 채워져 있다. 정수 덧셈을 단위 비용으로 세고 공간을 저장한 정수 개수로 측정하면, 상태 수가 $$n+1$$이고 상태마다 덧셈 한 번이므로 시간은 $$\Theta(n)$$, 테이블 공간은 $$\Theta(n)$$이다. 최종 값만 필요하면 직전 두 값만 보존해 정수 개수 기준 공간을 $$\Theta(1)$$로 줄일 수 있다. Python의 무한 정밀 정수에서 $$F_n$$은 $$\Theta(n)$$비트이므로 비트 연산과 실제 저장 바이트를 세면 이 단위 비용 분석보다 비용이 커진다.

### 3.4 Top-down memoization

14–15쪽의 방식은 재귀 구조를 유지하면서 이미 계산한 값을 즉시 반환한다.

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

`None`은 “아직 계산하지 않음”을 나타내고 실제 값 `0`과 구분된다. 단위 비용 정수 덧셈과 저장 정수 개수 모델에서 각 $$k$$는 처음 호출될 때만 두 하위 문제를 계산하므로 시간은 $$\Theta(n)$$이다. 메모 테이블과 최대 깊이 $$n$$의 호출 스택을 합한 공간도 $$\Theta(n)$$이다. Python의 무한 정밀 정수에 대한 비트 비용을 세면 bottom-up과 마찬가지로 이보다 커진다. 피보나치에서는 목표 $$n$$을 계산하면 결국 0부터 $$n$$까지 모두 필요하지만, 도달 가능한 상태가 희소한 문제에서는 top-down이 필요한 상태만 계산한다는 차이가 생긴다.

## 4. Matrix Path Problem

### 4.1 Problem and state

$$R\times C$$ 행렬 $$M$$의 왼쪽 위 $$(0,0)$$에서 오른쪽 아래 $$(R-1,C-1)$$까지 이동한다. 한 번에 오른쪽 또는 아래로만 갈 수 있고, 방문한 모든 칸의 값을 더한다. 여기서는 $$R,C\ge1$$인 직사각형 행렬이고 모든 행의 길이가 같으며, 각 칸의 값은 덧셈과 비교가 가능한 유한 실수라고 가정한다. 슬라이드는 $$n\times n$$을 사용하지만 직사각형으로 일반화해도 점화식은 같다(17쪽).

$$P_{i,j}$$를 시작 칸에서 $$(i,j)$$까지 가는 유효한 경로 중 최대 합으로 정의한다. $$i,j$$는 단위 없는 0-based 인덱스이고, $$M_{i,j}$$와 $$P_{i,j}$$의 단위는 입력 점수와 같다.

### 4.2 Recurrence and boundary cases

마지막 이동은 위 $$(i-1,j)$$ 또는 왼쪽 $$(i,j-1)$$에서만 올 수 있다. 따라서 정확한 경계 처리를 포함한 점화식은 다음과 같다.

$$
\begin{aligned}
P_{0,0}&=M_{0,0},\\
P_{0,j}&=P_{0,j-1}+M_{0,j} && (j>0),\\
P_{i,0}&=P_{i-1,0}+M_{i,0} && (i>0),\\
P_{i,j}&=\max(P_{i-1,j},P_{i,j-1})+M_{i,j} && (i>0,\ j>0).
\end{aligned}
$$

이는 정확한 등식이며 행렬 값이 양수라는 가정이 필요 없다. 슬라이드 18쪽처럼 행렬 밖 상태를 0으로 두는 표기는 **모든 유효 경로 합이 0 이상인 경우**에만 안전하다. 음수 칸을 허용하는 일반 문제에서는 존재하지 않는 경로를 $$-\infty$$로 두거나 위처럼 첫 행과 첫 열을 별도로 초기화해야 한다.

### 4.3 Why optimal substructure holds

$$(i,j)$$까지의 최적 경로가 위 칸에서 왔다고 하자. 그 경로에서 $$(i-1,j)$$까지의 접두 경로가 해당 칸까지의 최적 경로가 아니라면, 더 큰 합을 가진 경로로 접두 부분을 교체할 수 있다. 마지막 한 칸 이동과 $$M_{i,j}$$는 그대로이므로 전체 합이 더 커져 원래 경로가 최적이라는 가정과 모순된다. 왼쪽 칸에서 오는 경우도 같다. 따라서 최적 경로는 두 선행 상태의 최적값 중 하나를 반드시 포함한다.

### 4.4 Bottom-up evaluation and reconstruction

행 우선으로 위에서 아래, 왼쪽에서 오른쪽으로 채우면 현재 칸의 두 선행 상태가 이미 계산되어 있다. 최댓값뿐 아니라 어느 선행 칸을 골랐는지도 저장하면 경로를 복원할 수 있다.

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

동점에서는 Python의 tuple 비교 규칙에 따라 한 선행 칸이 결정된다. 최댓값만 필요하면 어느 쪽을 택해도 맞지만, 재현 가능한 경로가 필요하면 “동점 시 위 우선”처럼 정책을 명시적으로 정하는 편이 좋다. 테이블 계산은 $$RC$$개 상태를 한 번씩 처리하므로 시간과 `dp` 공간은 $$\Theta(RC)$$이다. `parent`도 $$\Theta(RC)$$이고 복원은 경로 길이 $$R+C-1$$에 비례한다.

### 4.5 Top-down evaluation

Top-down 구현도 상태와 점화식은 같지만, `None`으로 계산 여부를 구분한다. 값 `0`을 미계산 표시로 사용하면 실제 최적합이 0인 상태를 반복 계산하게 된다.

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

최악의 경우 모든 칸을 계산하므로 시간과 메모 공간은 $$\Theta(RC)$$이고, 호출 스택 깊이는 $$O(R+C)$$이다. 경로까지 필요하면 각 상태에서 선택한 선행 좌표를 별도 테이블에 저장해야 한다.

### 4.6 Independently checked trace

17·19쪽의 행렬을 행 우선으로 계산하면 `dp`는 다음과 같다.

| 행 | 열 0 | 열 1 | 열 2 | 열 3 |
|---|---:|---:|---:|---:|
| 0 | 6 | 13 | 25 | 30 |
| 1 | 11 | 16 | 36 | 54 |
| 2 | 18 | 35 | 39 | 57 |
| 3 | 26 | 45 | 59 | 68 |

최댓값은 68이고, 한 최적 경로는 다음과 같다.

$$
\begin{aligned}
&(0,0)\rightarrow(1,0)\rightarrow(2,0)\rightarrow(2,1)\\
&\rightarrow(3,1)\rightarrow(3,2)\rightarrow(3,3).
\end{aligned}
$$

방문 값은 `6, 5, 7, 17, 10, 14, 9`이고 합은 68이다. 오른쪽·아래쪽으로 이루어진 가능한 20개 경로를 전수 열거한 결과와도 일치한다. 슬라이드에 노란색으로 표시된 경로의 합은 `6+7+12+11+18+3+9=66`이므로 문제의 최적 경로 예시로는 맞지 않는다.

## 5. Matrix Multiplication Order Problem

### 5.1 Problem and dimension vector

$$m\ge1$$개의 행렬 $$A_0,A_1,\ldots,A_{m-1}$$을 곱한다. 행렬 곱은 결합법칙을 만족하므로 괄호 위치를 바꿔도 결과 행렬은 같지만, 스칼라 곱셈 횟수는 달라질 수 있다(22쪽). 인접 행렬의 안쪽 차원이 일치하고 모든 차원이 양의 정수라고 가정하며, 차원 벡터를

$$
p=(p_0,p_1,\ldots,p_m)
$$

라고 하면 $$A_i$$의 크기는 $$p_i\times p_{i+1}$$이다. $$a\times b$$ 행렬과 $$b\times c$$ 행렬을 곱할 때 각 출력 원소 $$ac$$개가 길이 $$b$$의 내적을 수행하므로 스칼라 곱셈 수는 정확히 $$abc$$회다. $$p_i$$의 단위는 행 또는 열의 원소 수이고, 비용의 단위는 스칼라 곱셈 횟수다.

### 5.2 Half-open interval state and recurrence

$$S(s,e)$$를 반열린 구간의 곱 $$A_sA_{s+1}\cdots A_{e-1}$$을 계산하는 최소 스칼라 곱셈 수로 정의한다. 결과 행렬의 크기는 $$p_s\times p_e$$다. 행렬 하나는 곱셈이 필요 없으므로 기저 사례는 다음과 같다.

$$
S(s,s+1)=0.
$$

마지막 곱셈에서 분할점을 $$k$$로 선택하면 왼쪽 결과는 $$p_s\times p_k$$, 오른쪽 결과는 $$p_k\times p_e$$이고, 두 결과를 곱하는 비용은 $$p_sp_kp_e$$다. 따라서 정확한 점화식은 다음과 같다(24쪽).

$$
S(s,e)=\min_{s<k<e}
\left\{S(s,k)+S(k,e)+p_sp_kp_e\right\}.
$$

### 5.3 Why optimal substructure holds

최적 괄호 묶기의 마지막 분할점이 $$k$$라고 하자. 왼쪽 부분 $$A_s\cdots A_{k-1}$$의 계산 순서가 그 부분의 최소 비용이 아니라면, 더 싼 순서로 바꾸어도 왼쪽 결과의 크기 $$p_s\times p_k$$는 변하지 않는다. 따라서 마지막 곱셈 비용과 오른쪽 비용은 그대로인데 전체 비용만 줄어들어 최적성에 모순된다. 오른쪽 부분도 같은 논리이므로 두 부분은 각각 최적이어야 한다.

### 5.4 Bottom-up tabulation and reconstruction

길이 1 구간을 먼저 0으로 두고, 구간 너비 2부터 증가시키면 $$S(s,e)$$가 참조하는 두 짧은 구간이 이미 계산되어 있다. 최소 비용을 만든 분할점도 `split[s][e]`에 저장한다.

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

행렬 수를 $$m=n-1$$이라 하면 구간 상태는 $$\Theta(m^2)$$개이고 각 상태에서 최대 $$m-1$$개 분할점을 확인한다. 차원 곱과 비용의 덧셈·비교를 단위 비용으로 세면 시간은 $$\Theta(m^3)$$, `cost`와 `split` 공간은 $$\Theta(m^2)$$다. 큰 차원에서 비용 정수의 비트 수까지 세면 산술 비용을 별도로 곱해야 한다. 복원은 이진 분할 트리의 $$\Theta(m)$$개 노드를 방문하며, 위 구현은 토큰을 모아 한 번만 `join`하므로 문자열 작성 시간은 최종 출력 길이에 비례한다. 행렬 인덱스를 십진수로 쓰면 출력 길이는 $$O(m\log m)$$일 수 있다.

### 5.5 Top-down memoization

27쪽의 구현처럼 목표 구간에서 재귀를 시작할 수도 있다. 차원이 양의 정수이면 모든 실제 비용은 0 이상이므로 `-1`도 미계산 표시로 사용할 수 있지만, 값과 상태를 명확히 분리하기 위해 `None`을 쓰는 편이 안전하다.

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

최악의 경우 가능한 모든 구간과 분할점을 확인하므로 bottom-up과 같은 $$\Theta(m^3)$$ 시간과 $$\Theta(m^2)$$ 메모 공간을 사용한다. 비용만 저장하면 최소값은 얻지만 괄호 묶기는 복원할 수 없다. 복원이 필요하면 최솟값을 갱신한 $$k$$를 함께 저장해야 한다.

### 5.6 Independently checked example

23쪽의 차원 벡터는 $$p=(10,100,5,50)$$이다.

$$
\begin{aligned}
(A_0A_1)A_2 &: 10\cdot100\cdot5+10\cdot5\cdot50=5000+2500=7500,\\
A_0(A_1A_2) &: 100\cdot5\cdot50+10\cdot100\cdot50=25000+50000=75000.
\end{aligned}
$$

따라서 최소 비용은 7,500회이고 복원된 순서는 `((A0A1)A2)`다. 두 괄호 묶기는 같은 $$10\times50$$ 결과를 만들지만 비용은 10배 차이 난다.

## 6. State, Order, and Reconstruction Comparison

| 문제 | 상태 | 기저 사례 | Bottom-up 평가 순서 | 복원 정보 |
|---|---|---|---|---|
| Fibonacci | $$F_i$$ | $$F_0=0, F_1=1$$ | 인덱스 증가 | 보통 최종 값만 필요 |
| Matrix Path | $$P_{i,j}$$ | 시작 칸, 첫 행, 첫 열 | 행 우선 또는 열 우선 | 선택한 이전 칸 |
| Matrix Chain | $$S(s,e)$$ | $$S(s,s+1)=0$$ | 구간 너비 증가 | 최소 비용을 만든 분할점 $$k$$ |

Top-down에서는 표의 순서를 반복문으로 직접 쓰지 않는다. 재귀가 의존 상태를 먼저 방문하고 반환하면서 그 순서를 만든다. 반대로 bottom-up에서는 올바른 위상 순서를 반복문으로 명시해야 한다. 어느 방식이든 값 테이블만으로는 자동으로 해답 구조가 복원되지 않으며, 선택 정보를 별도로 저장해야 한다.

## Source Formula Map

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

## Source Check

| 슬라이드 위치 | 확인 결과 | 이 글의 처리 |
|---|---|---|
| 9쪽 | 부분 문제의 해답을 결합하는 구조를 optimal substructure로 함께 설명 | 일반적인 재귀적 부분 구조와 최적화 문제의 최적 부분 구조를 구분했다. Fibonacci는 최적화가 아닌 수열 계산이다. |
| 4쪽 | Quickselect 기대 시간 상한의 합은 $$\lfloor n/2\rfloor$$부터 시작하며, 홀수 입력의 중앙 크기는 계수 2에 의해 중복 계산됨 | 중앙 항의 중복이 등식이 아니라 안전한 상한을 만든다고 설명했다. |
| 5쪽 | $$n/5$$와 $$7n/10$$은 반올림 상수항을 생략한 표기 | 실제 재귀 입력의 $$O(1)$$ 오차, 충분히 큰 $$n$$의 선형 여유분, 유한 기저 구간 확대를 구분했다. |
| 12쪽 | 단순 재귀의 호출 수는 피보나치 성장률을 가져 $$\Theta(\phi^n)$$ | $$C_n=2F_{n+1}-1$$로 호출 수를 직접 연결했다. |
| 13–14쪽 | `memo = [0, 1] + [-1] * n`은 필요한 길이보다 한 칸 크지만 동작 가능 | 정확히 `n+1`칸을 만들고, 실제 값과 충돌하지 않는 `None`을 사용했다. |
| 18쪽 | 행렬 밖을 0으로 두는 점화식은 음수 값에서 존재하지 않는 경로를 선택할 수 있음 | 시작 칸·첫 행·첫 열을 명시하고 일반 입력에 맞는 경계를 사용했다. |
| 19쪽 | `[[0] * n+1 ...]`은 Python에서 리스트에 정수 `1`을 더하려 해 실행 오류 | 올바른 크기의 2차원 테이블로 고쳤다. |
| 19쪽 | 음수 인덱스로 마지막 행·열을 경계처럼 쓰는 구현은 Python 표현에 의존 | 유효한 선행 칸만 후보에 넣어 언어의 음수 인덱스에 의존하지 않는다. |
| 20쪽 | `0`을 미계산 표시로 쓰면 실제 최적합이 0인 상태를 구분하지 못함 | `None`으로 계산 여부를 분리했다. |
| 17·19쪽 | 노란 경로의 합은 66이지만 가능한 경로의 실제 최댓값은 68 | 20개 경로 전수 열거와 DP가 같은 68을 내는지 검산하고 최적 경로를 제시했다. |
| 22쪽 | $$a\times b$$와 $$b\times c$$의 곱셈 비용은 $$abc$$회 | 출력 원소 수와 내적 길이로 단위를 유도했다. |
| 23쪽 | 두 순서의 비용은 각각 7,500회와 75,000회 | 각 항을 다시 계산하고 DP 복원 결과 `((A0A1)A2)`와 대조했다. |
| 24·26쪽 | $$S(s,e)$$는 $$A_s\cdots A_{e-1}$$의 반열린 구간 | 결과 차원 $$p_s\times p_e$$와 기저 $$S(s,s+1)=0$$을 일관되게 사용했다. |

## 마지막 핵심 정리

- 동적 계획법은 재귀적 부분 구조와 중복 부분 문제를 활용한다. 최적화 문제에서는 최적 부분 구조가 필요하다. 저장은 중복 계산을 없애지만 잘못된 상태 정의나 점화식을 고쳐 주지는 않는다.
- Top-down은 필요한 상태를 재귀적으로 방문하고, bottom-up은 의존 관계를 만족하는 순서를 반복문으로 명시한다.
- Matrix Path의 상태는 “해당 칸까지의 최대 합”이며, 경계는 존재하지 않는 경로가 선택되지 않도록 처리해야 한다. 슬라이드 예제의 실제 최댓값은 68이다.
- Matrix Chain의 상태는 반열린 행렬 구간의 최소 비용이다. 짧은 구간부터 계산하면 $$\Theta(m^3)$$ 시간, $$\Theta(m^2)$$ 공간에 최소 비용을 얻는다.
- 최적값만 저장한 테이블과 실제 해답 구조는 다르다. 경로에는 이전 칸, 행렬 연쇄에는 분할점이 있어야 선택을 복원할 수 있다.

다음 강의에서는 동적 계획법의 다른 문제와 설계 패턴을 이어서 다룬다(30쪽).

## Study Guide

1. 각 문제에서 상태를 한 문장으로 먼저 정의하고, 인덱스 범위와 값의 단위를 적는다.
2. 점화식을 쓰기 전에 가능한 마지막 선택을 모두 나열한다. Matrix Path는 위·왼쪽, Matrix Chain은 모든 분할점이다.
3. 기저 사례와 불가능한 상태를 구분한다. 비용 0과 미계산, 유효한 0점 경로와 행렬 밖 경로는 같은 상태가 아니다.
4. Bottom-up 반복문의 방향이 의존 관계를 만족하는지 확인한다. 행렬 연쇄에서는 시작점 순서보다 구간 너비가 먼저다.
5. 작은 입력을 손으로 계산한 뒤 코드의 테이블과 대조한다. 최적값뿐 아니라 복원된 경로나 괄호 묶기도 검산한다.
6. 복잡도는 상태 수와 상태당 전이 수를 곱해 계산한다. Matrix Path는 $$RC\cdot O(1)$$, Matrix Chain은 $$O(m^2)\cdot O(m)$$이다.

## 복습 질문

<details markdown="block">
<summary>Q&A: What is the difference between optimal substructure and overlapping subproblems?</summary>

답변: 최적 부분 구조는 최적화 문제에서 전체 최적해가 부분 문제의 최적해를 포함한다는 정확성 조건이다. 중복 부분 문제는 같은 상태가 재귀 과정에서 여러 번 등장한다는 효율 조건이다. 전자는 점화식이 최적값을 보장하는 이유이고, 후자는 메모나 테이블이 계산량을 줄이는 이유다. Fibonacci처럼 최적값을 찾지 않는 문제에서는 작은 상태의 값으로 큰 상태의 값을 구성하는 재귀적 부분 구조를 사용한다.

</details>

<details markdown="block">
<summary markdown="span">Q&A: Why does memoized Fibonacci take $$\Theta(n)$$ time?</summary>

답변: `solve(k)`가 처음 실행될 때만 하위 상태를 계산하고, 이후 호출은 저장된 값을 상수 시간에 반환한다. 서로 다른 상태는 0부터 $$n$$까지 $$n+1$$개이고 각 상태의 실제 계산은 덧셈 한 번이므로 전체 시간은 $$\Theta(n)$$이다.

</details>

<details markdown="block">
<summary>Q&A: Why is zero an unsafe outside-grid value for a maximum path?</summary>

답변: 행렬 값이 음수이면 유효한 선행 경로의 합보다 0이 더 클 수 있다. 그러면 알고리즘이 실제로 존재하지 않는 행렬 밖 경로에서 들어온 것처럼 선택한다. 불가능 상태는 $$-\infty$$로 두거나 시작 칸·첫 행·첫 열을 별도로 초기화해야 한다.

</details>

<details markdown="block">
<summary>Q&A: Why must matrix-chain tabulation increase interval width?</summary>

답변: $$S(s,e)$$는 모든 분할점 $$k$$에 대해 더 짧은 두 구간 $$S(s,k)$$와 $$S(k,e)$$를 참조한다. 구간 너비를 1, 2, 3의 순서로 늘리면 현재 상태에 필요한 두 값이 이미 계산되어 있다. 시작 인덱스만 증가시키는 순서는 이 의존 관계를 보장하지 않는다.

</details>

<details markdown="block">
<summary>Q&A: Why is a split table needed when the minimum cost table already exists?</summary>

답변: 비용 테이블은 최소 연산 횟수만 알려 주고, 어느 분할점이 그 값을 만들었는지는 보존하지 않는다. 각 구간에서 선택한 $$k$$를 함께 저장해야 왼쪽·오른쪽 구간을 재귀적으로 따라가 최적 괄호 묶기를 복원할 수 있다.

</details>

## References

- Youngwook Kim, *9. Dynamic Programming (1)*, Algorithms lecture slides, pp. 1–31.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/algorithms/lecture-09-dynamic-programming-01.pdf" | relative_url }}" target="_blank" rel="noopener">9 Dynamic Programming (1).pdf</a></li>
</ul>
