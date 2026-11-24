---
layout: default
date: 2026-11-25 00:57:12 +0900
title: "Lecture 18: String Matching I"
course: "Algorithms"
topic: "Naive Matching, LPS, and KMP"
order: 18
major_topic: "Data Structures & Algorithms"
keywords:
  - "String Matching"
  - "Naive Algorithm"
  - "KMP"
  - "LPS"
  - "Failure Function"
---

# Lecture 18: String Matching I

문자열 매칭은 긴 문서 $$A$$ 안에서 짧은 패턴 $$P$$가 시작되는 위치를 찾는 문제입니다. 단순한 방법은 패턴을 한 칸씩 옮기며 처음부터 다시 비교합니다. KMP는 실패하기 직전까지 확인한 문자가 **이미 알려 준 접두사·접미사 정보**를 재사용하여 문서 포인터를 뒤로 돌리지 않습니다.

> **핵심:** KMP가 건너뛰는 것은 확인하지 않은 문자가 아닙니다. 이미 일치가 확인된 구간에서 접두사와 접미사가 겹친다는 사실을 이용해, 다시 비교해도 결과가 정해진 부분만 건너뜁니다. 전처리에 $$O(m)$$, 탐색에 $$O(n)$$이 들어 전체 시간은 $$O(n+m)$$입니다.

## 1. 무엇을 찾는 문제인가

문서의 길이를 $$n$$, 패턴의 길이를 $$m$$이라 하겠습니다. 보통 $$m\ll n$$입니다. 출력은 다음 조건을 만족하는 시작 인덱스 $$s$$입니다.

$$
A[s:s+m]=P.
$$

예를 들어 `A = "boboycatsoaropt"`, `P = "soar"`이면 `A[8:12]`가 `soar`이므로 답은 8입니다. 패턴이 여러 번 나타날 수 있는 문제라면 첫 위치 하나가 아니라 모든 시작 위치를 모아야 합니다. 패턴이 빈 문자열일 때의 반환 규칙도 실제 API에서는 따로 정해야 합니다.

## 2. Naive matching: 모든 시작점을 확인합니다

가능한 시작점은 $$0$$부터 $$n-m$$까지입니다. 각 시작점에서 패턴의 문자를 왼쪽부터 비교하고, 하나라도 다르면 다음 시작점으로 이동합니다.

~~~python
def naive_matching(text, pattern):
    n, m = len(text), len(pattern)
    for start in range(n - m + 1):
        if text[start:start + m] == pattern:
            return start
    return -1
~~~

원문 p. 14의 의사코드는 `A[i:i+m-1]`로 적혀 있습니다. Python slice의 끝 인덱스는 포함되지 않으므로 이 표현은 길이 $$m-1$$만 잘라냅니다. 길이 $$m$$인 패턴과 비교하려면 위 코드처럼 `A[i:i+m]`을 사용해야 합니다.

시작점은 최대 $$n-m+1$$개이고 한 위치에서 최대 $$m$$자를 비교합니다. 따라서 최악 시간은

$$
O((n-m+1)m)=O(nm)
$$

입니다. 예를 들어 `text = "aaaaaaaaab"`, `pattern = "aaaab"`처럼 대부분의 위치에서 마지막 가까이까지 일치한 뒤 실패하면 같은 `a`들을 반복해 비교합니다. KMP가 줄이려는 비용이 바로 이 중복입니다.

## 3. Prefix, suffix, LPS를 먼저 이해합니다

- **Prefix:** 문자열의 첫 문자부터 시작하는 부분 문자열입니다.
- **Suffix:** 문자열의 마지막 문자에서 끝나는 부분 문자열입니다.
- **Proper prefix/suffix:** 문자열 전체는 제외합니다.
- **LPS:** proper prefix이면서 suffix인 문자열 중 가장 긴 것의 길이입니다.

문자열 `ababa`의 proper prefix는 `a`, `ab`, `aba`, `abab`이고 proper suffix는 `a`, `ba`, `aba`, `baba`입니다. 가장 긴 공통 항목은 `aba`이므로 LPS 길이는 3입니다.

KMP에서는 패턴의 각 prefix마다 이 길이를 미리 구합니다. 표준적인 LPS 배열을 다음처럼 정의할 수 있습니다.

$$
\operatorname{lps}[i]
=\max\{k:0\le k<i+1,\ P[0:k]=P[i-k+1:i+1]\}.
$$

즉 `lps[i]`는 `P[0:i+1]`에서 서로 같은 proper prefix와 suffix의 최대 길이입니다.

### 3.1 왜 실패 뒤에 처음으로 돌아가지 않아도 될까요?

패턴의 앞 $$j$$글자 `P[0:j]`가 문서와 일치했는데 다음 문자에서 실패했다고 하겠습니다. `P[0:j]`의 길이 $$k$$인 suffix가 같은 길이의 prefix와 같다면, 문서 끝의 $$k$$글자는 이미 `P[0:k]`와 일치합니다. 이 $$k$$글자를 다시 비교할 필요가 없습니다. 다음 비교는 `P[k]`부터 시작하면 됩니다.

예를 들어 `abdab`까지 일치한 뒤 실패하면, 이 문자열의 suffix `ab`는 prefix `ab`와 같습니다. 따라서 패턴을 전부 버리지 않고 `ab`가 맞은 상태, 즉 $$j=2$$로 돌아갑니다.

<details markdown="block">
<summary markdown="span">Derivation: Why the fallback preserves every possible match</summary>

문서에서 방금 일치한 길이 $$j$$의 구간을 $$S$$라 하겠습니다. 어떤 더 짧은 정렬이 여전히 정답 후보라면, 새 정렬에서 패턴의 prefix는 $$S$$의 suffix와 겹쳐야 합니다. 그런데 $$S=P[0:j]$$이므로 그 겹침은 `P[0:j]`의 prefix이면서 suffix여야 합니다.

그중 가장 긴 길이가 $$k=\operatorname{lps}[j-1]$$입니다. $$k$$보다 긴 겹침은 정의상 존재하지 않습니다. 따라서 $$j\leftarrow k$$로 이동하면 가장 가까운 유효 후보부터 검사하며, 그보다 짧은 후보들은 이후 fallback 과정에서 차례로 확인됩니다. 일치 가능성이 없는 정렬만 건너뛰므로 정답을 잃지 않습니다.

</details>

## 4. LPS 배열은 어떻게 만드나요?

`i`는 새로 결정할 위치, `length`는 직전까지 확인된 border의 길이입니다. 문자가 같으면 border를 한 글자 늘립니다. 다르면 `i`를 뒤로 보내지 않고, 지금 border의 더 짧은 border로 `length`만 이동합니다.

~~~python
def compute_lps(pattern):
    m = len(pattern)
    lps = [0] * m
    length = 0
    i = 1

    while i < m:
        if pattern[i] == pattern[length]:
            length += 1
            lps[i] = length
            i += 1
        elif length > 0:
            length = lps[length - 1]
        else:
            lps[i] = 0
            i += 1

    return lps
~~~

원문의 예제 `P = "aabcaaab"`를 표준 LPS 정의로 계산하면 다음과 같습니다.

| `i` | 문자 | `P[0:i+1]` | 가장 긴 같은 proper prefix·suffix | `lps[i]` |
|---:|:---:|---|---|---:|
| 0 | a | a | 없음 | 0 |
| 1 | a | aa | a | 1 |
| 2 | b | aab | 없음 | 0 |
| 3 | c | aabc | 없음 | 0 |
| 4 | a | aabca | a | 1 |
| 5 | a | aabcaa | aa | 2 |
| 6 | a | aabcaaa | aa | 2 |
| 7 | b | aabcaaab | aab | 3 |

따라서 표준 배열은 `[0, 1, 0, 0, 1, 2, 2, 3]`입니다.

### 4.1 강의의 $$\pi$$ 배열과 표준 LPS 배열의 위치 차이

원문 p. 20–30의 $$\pi$$는 실패한 상태의 `j`를 곧바로 `pi[j]`로 바꾸기 위해 LPS 값을 한 칸 오른쪽으로 옮긴 형태입니다.

$$
\pi[0]=0,\qquad \pi[j]=\operatorname{lps}[j-1]\quad(j\ge1).
$$

따라서 같은 패턴에서 원문의 배열은 `[0, 0, 1, 0, 0, 1, 2, 2]`가 됩니다. 두 배열은 서로 모순되지 않습니다. **배열의 각 칸이 어느 prefix를 뜻하는지**가 다릅니다. 구현을 섞으면 fallback 인덱스가 한 칸 어긋나므로, 표준 방식은 `j = lps[j-1]`, 강의 방식은 `j = pi[j]`를 사용해야 합니다.

## 5. KMP 탐색: 문서 포인터는 되돌리지 않습니다

아래 코드는 표준 LPS 배열을 사용하는 구현입니다.

~~~python
def kmp_matching(text, pattern):
    if pattern == "":
        return 0

    lps = compute_lps(pattern)
    i = 0  # text index
    j = 0  # pattern index

    while i < len(text):
        if text[i] == pattern[j]:
            i += 1
            j += 1
            if j == len(pattern):
                return i - j
        elif j > 0:
            j = lps[j - 1]
        else:
            i += 1

    return -1
~~~

세 경우만 구분하면 됩니다.

1. `text[i] == pattern[j]`: 두 포인터를 모두 한 칸 이동합니다.
2. 불일치이고 `j > 0`: 문서의 `i`는 그대로 두고 `j`만 LPS로 줄입니다.
3. 불일치이고 `j == 0`: 재사용할 일치 구간이 없으므로 `i`만 한 칸 이동합니다.

원문 p. 31–40의 예제는 `A = "xabdabddabdabwzab"`, `P = "abdabwz"`입니다. 첫 후보에서는 `abdab`까지 맞고 `text[6] = d`, `pattern[5] = w`에서 실패합니다. 강의의 shifted $$\pi$$에서 `pi[5] = 2`이므로 `j`만 2로 바뀝니다. 이미 맞은 suffix `ab`를 prefix `ab`로 재사용하는 것입니다. 이후 후보들이 제거되고, 인덱스 8부터 `abdabwz`가 모두 일치하여 8을 반환합니다.

### 5.1 문서 포인터를 되돌리지 않는다는 뜻

불일치 때 `i`를 유지하는 순간이 있으므로 한 번의 while 반복만 보면 같은 `text[i]`를 비교할 수 있습니다. 그러나 `i`는 절대 감소하지 않습니다. `i`가 그대로인 반복에서는 `j`가 더 작은 유효 border로 감소합니다. 따라서 `(i, j)` 상태는 계속 전진하며, 문서의 앞 구간으로 돌아가 재탐색하지 않습니다.

## 6. 왜 전체 시간이 $$O(n+m)$$인가요?

LPS 전처리에서 `i`는 최대 $$m$$까지 증가하고, 실패 때 감소하는 `length`의 총량도 앞서 증가한 총량을 넘지 않습니다. 따라서 전처리는 $$O(m)$$입니다.

탐색에서는 원문 p. 41처럼 잠재량을 다음과 같이 둘 수 있습니다.

$$
\Phi= i+(i-j)=2i-j.
$$

- 일치하면 `i`와 `j`가 모두 1 증가하므로 $$\Phi$$는 1 증가합니다.
- `j=0`에서 실패하면 `i`만 1 증가하므로 $$\Phi$$는 2 증가합니다.
- `j>0`에서 실패하면 `i`는 그대로이고 `j`가 감소하므로 $$\Phi$$는 최소 1 증가합니다.

반복할 때마다 $$\Phi$$는 증가하고, 탐색 중 $$0\le j\le i\le n$$이므로 $$\Phi\le2n$$입니다. 따라서 while 반복 수는 $$O(n)$$이며 전체 시간은

$$
O(m)+O(n)=O(n+m)
$$

입니다. LPS 배열 때문에 추가 공간은 $$O(m)$$입니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Return every match, including overlaps</summary>

첫 위치에서 즉시 반환하지 않고, 완전 일치 뒤에도 LPS로 돌아가면 겹치는 결과도 찾을 수 있습니다.

~~~python
def kmp_find_all(text, pattern):
    if pattern == "":
        return list(range(len(text) + 1))

    lps = compute_lps(pattern)
    matches = []
    i = j = 0

    while i < len(text):
        if text[i] == pattern[j]:
            i += 1
            j += 1
            if j == len(pattern):
                matches.append(i - j)
                j = lps[j - 1]
        elif j > 0:
            j = lps[j - 1]
        else:
            i += 1

    return matches
~~~

`kmp_find_all("aaaaa", "aaa")`는 `[0, 1, 2]`를 반환합니다. 첫 일치 뒤 `j`를 0으로 초기화하면 인덱스 1과 2에서 시작하는 겹친 결과를 놓칠 수 있습니다.

</details>

## 마지막 핵심 정리

- Naive matching은 모든 시작점에서 최대 $$m$$자를 다시 확인해 최악 $$O(nm)$$입니다.
- LPS는 이미 일치한 패턴 prefix 안에서 재사용 가능한 가장 긴 prefix·suffix 길이입니다.
- 실패 때 문서 포인터 `i`는 되돌리지 않고 패턴 포인터 `j`만 유효한 border로 이동합니다.
- 표준 LPS와 강의의 shifted $$\pi$$는 값의 의미가 한 칸 다르므로 fallback 식도 함께 맞춰야 합니다.
- KMP의 전처리는 $$O(m)$$, 탐색은 $$O(n)$$, 추가 공간은 $$O(m)$$입니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 순서 보기</summary>

먼저 p. 11의 입력과 출력에서 시작 인덱스를 직접 확인합니다. p. 13–15에서는 같은 문자가 왜 반복 비교되는지 표시합니다. 그다음 `aabcaaab`의 표준 LPS와 p. 30의 shifted $$\pi$$를 나란히 적어 한 칸 차이의 의미를 확인합니다. 마지막으로 p. 31–40에서 불일치마다 `i`가 유지되는지, `j`가 어떤 값으로 돌아가는지를 추적하면 됩니다.

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Why is the naive worst case O(nm)?</summary>

답변: 가능한 시작점이 $$O(n)$$개이고, 각 시작점에서 불일치가 늦게 발견되면 패턴의 $$O(m)$$자를 비교하기 때문입니다.

</details>

<details markdown="block">
<summary markdown="span">2. Why does KMP keep i fixed after some mismatches?</summary>

답변: 방금까지 일치한 문서 구간의 suffix가 패턴 prefix와 같다는 사실을 이미 알고 있기 때문입니다. 문서 문자를 버리지 않고, 그 문자와 비교할 패턴 위치 `j`만 더 짧은 border로 바꿉니다.

</details>

<details markdown="block">
<summary markdown="span">3. What is the difference between lps[j-1] and pi[j]?</summary>

답변: 표준 LPS는 `P[0:j]`의 마지막 인덱스 `j-1`에 값을 저장합니다. 강의의 $$\pi$$는 같은 값을 실패 상태 `j`에서 바로 읽도록 한 칸 오른쪽에 저장합니다. 같은 정의의 배열처럼 섞어 쓰면 안 됩니다.

</details>

<details markdown="block">
<summary markdown="span">4. Why do we use a proper prefix?</summary>

답변: 문자열 전체를 prefix와 suffix로 허용하면 언제나 자기 자신이 가장 긴 답이 되어, 실패 뒤 더 짧은 후보로 이동하는 정보가 되지 못합니다.

</details>

## English Summary

String matching locates a pattern inside a longer text. The naive algorithm restarts the comparison at every candidate position and can take O(nm) time. KMP preprocesses the pattern into border information. On a mismatch, it keeps the text index and moves only the pattern index to the longest valid border. Preprocessing takes O(m), searching takes O(n), and the additional space is O(m).

## References

- Youngwook Kim, *Algorithms — String Matching (1)*, provided lecture slides, pp. 1–47.
- [Neo eCampus — Lecture 18: String Matching (1)](https://ecampus.kookmin.ac.kr/mod/ubfile/view.php?id=2007542){: target="_blank" rel="noopener"}
