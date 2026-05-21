---
layout: default
title: "Lecture 04 Linear Algebra 3"
course: "Machine Learning Basic"
topic: "Linear Algebra 3"
order: 4
---

# Lecture 04 Linear Algebra 3

Source PDF: `machine-learning-basic-lecture-04.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 선형 독립 판별 | REF의 pivot column은 무엇을 알려주는가? |
| 2 | 생성 집합과 span | 벡터들이 공간 전체를 만들 수 있는가? |
| 3 | 기저와 차원 | 최소 생성 집합과 최대 독립 집합은 어떻게 연결되는가? |
| 4 | 랭크 | 행렬의 독립적인 정보량은 어떻게 측정하는가? |
| 5 | 선형 사상과 좌표 | 행렬은 선형 변환을 어떻게 표현하는가? |

## 1. REF로 선형 독립 확인

벡터들을 열로 모아 행렬을 만들고 REF로 바꾸면 pivot column을 확인할 수 있다.

| 열 종류 | 의미 |
|---|---|
| pivot column | 이전 pivot column들과 선형 독립 |
| non-pivot column | 앞의 pivot column들의 선형 조합으로 표현 가능 |

따라서 모든 열이 pivot column이면 해당 벡터 집합은 선형 독립이다.

## 2. 생성 집합과 span

벡터 집합 \(A\)의 선형 조합으로 벡터공간 \(V\)의 모든 원소를 만들 수 있으면 \(A\)는 \(V\)의 생성 집합이다.

$$
\operatorname{span}(A) = V
$$

span은 "이 벡터들로 만들 수 있는 모든 방향과 위치"를 뜻한다. 머신러닝에서는 feature들이 어떤 공간을 span하는지가 모델 표현력과 연결된다.

## 3. 기저와 차원

기저는 공간을 만들기에 충분하면서도 중복이 없는 벡터 집합이다.

동치 관점은 다음과 같다.

| 관점 | 설명 |
|---|---|
| 최소 생성 집합 | 하나라도 빼면 공간 전체를 만들 수 없다. |
| 최대 선형 독립 집합 | 더 넣으면 선형 종속이 된다. |
| 유일한 좌표 표현 | 모든 벡터가 기저에 대해 유일한 선형 조합을 가진다. |

벡터공간의 차원은 기저 벡터의 개수다.

## 4. 랭크 Rank

행렬 `A`의 rank는 선형 독립인 열의 개수다. 이는 선형 독립인 행의 개수와도 같다.

| 개념 | 의미 |
|---|---|
| column rank | 독립인 열의 수 |
| row rank | 독립인 행의 수 |
| full rank | \(\operatorname{rank}(A) = \min(m,n)\) |

중요한 성질:

| 성질 | 의미 |
|---|---|
| \(A\)가 정사각행렬일 때 invertible iff \(\operatorname{rank}(A)=n\) | full rank면 역행렬 존재 |
| \(Ax=b\) 해 존재 iff \(\operatorname{rank}(A)=\operatorname{rank}([A\mid b])\) | augmented matrix rank로 consistency 확인 |
| \(Ax=0\) 해 공간 차원은 \(n-\operatorname{rank}(A)\) | null space 차원 |

## 5. 선형 사상

선형 사상은 덧셈과 스칼라곱 구조를 보존하는 함수다.

$$
T(x+y) = T(x) + T(y)
$$

$$
T(ax) = aT(x)
$$

| 용어 | 의미 |
|---|---|
| injective | 서로 다른 입력이 서로 다른 출력으로 간다. |
| surjective | 공역의 모든 원소가 어떤 입력의 출력이다. |
| bijective | injective이면서 surjective |
| isomorphism | 선형이고 bijective인 사상 |

유한 차원 벡터공간에서는 차원이 같으면 서로 동형인 구조로 볼 수 있다.

## 6. 좌표와 변환 행렬

기저가 주어지면 벡터는 기저 벡터들의 선형 조합 계수로 표현된다. 이 계수 벡터가 좌표 벡터다.

선형 변환도 기저를 고르면 행렬로 표현된다. 즉 행렬은 추상적인 선형 사상을 좌표계 위에서 계산 가능하게 만든 표현이다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 기저의 조건은? | span하면서 선형 독립 |
| 차원이란? | 기저 벡터의 개수 |
| rank-nullity 핵심은? | null space 차원은 \(n-\operatorname{rank}(A)\) |
| 선형 사상의 조건은? | 덧셈과 스칼라곱 보존 |

## 복습 질문

1. 모든 열이 pivot column이면 왜 선형 독립인가?
2. 기저가 바뀌면 벡터 자체가 바뀌는가, 좌표 표현이 바뀌는가?
3. \(\operatorname{rank}(A) < n\)이면 \(Ax=0\)은 어떤 해를 가지는가?


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-04.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-04.pdf</a></li>
</ul>
