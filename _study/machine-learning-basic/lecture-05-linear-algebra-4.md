---
layout: default
title: "Lecture 05 Linear Algebra 4"
course: "Machine Learning Basic"
topic: "Linear Algebra 4"
order: 5
---

# Lecture 05 Linear Algebra 4

Source PDF: `machine-learning-basic-lecture-05.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 변환 행렬 | 선형 변환은 기저 선택에 따라 어떻게 표현되는가? |
| 2 | 기저 변환 | 좌표계를 바꾸면 행렬 표현은 어떻게 달라지는가? |
| 3 | 동치와 닮음 | 행렬들이 같은 변환을 다른 좌표에서 표현한다는 뜻은 무엇인가? |
| 4 | 이미지/영 공간 | 선형 변환의 출력 공간과 0으로 가는 공간은 무엇인가? |
| 5 | 아핀 공간과 아핀 변환 | 원점을 지나지 않는 선형 구조는 어떻게 다루는가? |

## 1. 변환 행렬의 의미

선형 변환은 기저를 정하면 행렬로 표현된다. 같은 추상적 변환이라도 입력과 출력 공간의 기저를 어떻게 잡느냐에 따라 행렬의 숫자 표현은 달라진다.

중요한 해석은 두 가지다.

| 관점 | 설명 |
|---|---|
| 데이터 변환 | 벡터 자체를 다른 벡터로 보낸다. |
| 좌표 변환 | 같은 벡터를 다른 축 기준의 좌표로 표현한다. |

머신러닝에서는 PCA, whitening, embedding 변환처럼 두 관점이 모두 등장한다.

## 2. 기저 변환

기저가 바뀌면 벡터의 좌표도 바뀐다. 기저 변환 행렬은 한 기저에서 표현된 좌표를 다른 기저의 좌표로 옮기는 역할을 한다.

기저 변환을 이해할 때는 "벡터 자체"와 "좌표 표현"을 구분해야 한다.

같은 벡터 \\(x\\)라도 기저가 달라지면 좌표 표현이 달라진다.

$$
[x]_B \quad \text{and} \quad [x]_C
$$

## 3. 동치와 닮음

두 행렬이 가역행렬을 이용해 서로 연결되면 같은 선형 구조를 다른 좌표에서 본 것으로 해석할 수 있다.

| 개념 | 형태 | 의미 |
|---|---|---|
| equivalent | \\(B = PAQ\\) | 입력/출력 기저가 모두 바뀐 표현 |
| similar | \\(B = P^{-1}AP\\) | 같은 공간에서 기저만 바뀐 표현 |

닮은 행렬은 고유값 같은 중요한 성질을 공유한다.

## 4. 이미지 공간과 영 공간

선형 변환 `A`에 대해 두 공간이 중요하다.

| 공간 | 의미 |
|---|---|
| image space / column space | \\(Ax\\)로 도달 가능한 모든 출력 |
| null space | \\(Ax = 0\\)을 만족하는 모든 입력 |

영 공간은 항상 0 벡터를 포함한다. 영 공간이 0만 포함하면 변환은 injective하다.

## 5. Rank-Nullity 정리

\\(A\\)가 \\(m \times n\\) 행렬일 때:

$$
\operatorname{rank}(A) + \operatorname{nullity}(A) = n
$$

입력 차원은 "출력으로 살아남는 차원(rank)"과 "0으로 사라지는 차원(nullity)"으로 나뉜다.

정사각행렬에서 \\(\operatorname{rank}(A)=n\\)이면 injective, surjective, bijective가 서로 동치가 된다.

## 6. 아핀 공간

아핀 공간은 부분공간을 어떤 기준점만큼 평행이동한 공간이다.

$$
x_0 + U
$$

여기서 \\(U\\)는 direction space, \\(x_0\\)는 support point다. 원점을 지나지 않을 수 있으므로 일반적으로 벡터공간은 아니다.

| 차원 | 아핀 공간 예 |
|---|---|
| 1차원 | 선 |
| 2차원 | 평면 |
| \\(n-1\\)차원 | hyperplane |

## 7. 아핀 변환

아핀 변환은 선형 변환에 평행이동을 더한 형태다.

$$
f(x) = Ax + a
$$

신경망의 layer \\(Wx + b\\)도 기본적으로 아핀 변환 뒤에 비선형 함수를 적용하는 구조로 볼 수 있다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 기저 변환에서 바뀌는 것은? | 벡터 자체가 아니라 좌표 표현 |
| similar matrix가 중요한 이유는? | 같은 선형 변환의 다른 기저 표현이며 고유값을 공유 |
| image space는 무엇인가? | \\(Ax\\)로 만들 수 있는 출력 전체 |
| affine mapping의 형태는? | \\(Ax + a\\) |

## 복습 질문

1. \\(Ax=0\\)의 해 공간이 크다는 것은 변환 \\(A\\)가 어떤 정보를 잃는다는 뜻인가?
2. 신경망의 bias term은 왜 아핀 변환 관점에서 자연스러운가?
3. 닮은 행렬이 고유값을 공유하는 이유를 좌표 변환 관점으로 설명해보자.


## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/machine-learning-basic/machine-learning-basic-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">machine-learning-basic-lecture-05.pdf</a></li>
</ul>
