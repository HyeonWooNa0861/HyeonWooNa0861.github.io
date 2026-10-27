---
layout: default
date: 2026-10-27 11:20:00 +0900
title: "Lecture 12: Object Tracking I"
course: "Autonomous Driving"
topic: "Data Association and the Hungarian Algorithm"
order: 12
major_topic: "Autonomous Systems"
keywords:
  - "Object Tracking"
  - "Multiple Object Tracking"
  - "Data Association"
  - "Hungarian Algorithm"
  - "Bipartite Matching"
  - "Assignment Problem"
---

# Lecture 12: Object Tracking I

Source PDF: [12 Object Tracking (1).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf" | relative_url }})

Object detection이 한 장의 영상에서 객체의 위치를 찾는다면, **object tracking은 여러 영상에 나타난 객체가 이전의 어느 객체인지를 연결한다.** 같은 자동차에 같은 ID를 유지해야 이동 방향과 궤적을 읽을 수 있다. 이 강의는 검출 결과를 시간축으로 연결하는 **data association**과, 연결 비용의 합을 최소화하는 **Hungarian algorithm**을 다룬다.

> **핵심:** 각 객체가 가장 가까운 검출을 제각각 고르면 여러 ID가 하나의 검출에 겹칠 수 있다. 전체 연결을 함께 고려해 **행·열이 중복되지 않으면서 총비용이 가장 작은 배정**을 찾아야 한다. 다만 비용이 최소라는 사실만으로 실제 객체의 신원이 맞거나, 새 객체와 가림까지 처리되었다고 볼 수는 없다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–3 | Introduction | 검출 다음에 어떤 정보가 더 필요한가? |
| 4–8 | Detection → tracking | Bounding box에 ID를 더하면 무엇을 알 수 있는가? |
| 9–17 | Tracking by detection | 다음 frame의 box에 이전 ID를 어떻게 연결하는가? |
| 18–19 | Association conflicts | 새 객체가 들어오거나 최근접 후보가 겹치면 어떻게 되는가? |
| 20–28 | Hungarian algorithm | 비용행렬을 바꾸어도 최적 배정이 유지되는 이유는 무엇인가? |
| 29 | Rectangular assignment | 검출 수와 track 수가 다를 때 무엇을 추가해야 하는가? |
| 30–33 | Summary | 배정 알고리즘이 해결하는 일과 남겨 두는 일은 무엇인가? |

페이지 표기는 PDF의 1-based 쪽수이며 인쇄된 슬라이드 번호와 같다. 2·4·9·20·30·33쪽은 구간 표지 또는 질문 화면이다. 원문의 그림과 수치를 중심으로 설명하고, 수식 유도·계산 검산 및 tracking 운영상의 주의점은 보충 해설로 구분한다.

## 1. Detection에서 tracking으로: 같은 객체라는 연결

5쪽의 detector는 single image를 입력받아 객체별 bounding box를 출력한다. 실제 detector는 class와 confidence도 내놓을 수 있지만, 여기서 중요한 것은 **서로 다른 frame의 box가 같은 객체를 가리킨다는 보장은 없다는 점**이다. 다음 frame에서도 `car`로 검출되었다는 것과, 이전의 특정 자동차와 동일하다는 것은 다른 판단이다.

<figure id="adc-12-p07">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p07.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p07.png" | relative_url }}" alt="동일한 거리 영상에서 detection box와 ID 및 이동 방향을 포함한 tracking 결과 비교" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=7" | relative_url }}">lecture PDF, p. 7</a>.</figcaption>
</figure>

그림 왼쪽은 현재 위치를 감싼 box만 보여 준다. 오른쪽은 box마다 ID와 방향 화살표가 있다. ID는 `car`와 같은 종류 번호가 아니라 **시간에 걸쳐 같은 객체를 구별하기 위한 식별자**다. 같은 frame의 서로 다른 객체에는 다른 ID를 주고, 다음 frame에서 같은 객체를 찾으면 이전 ID를 이어 쓴다.

6쪽이 여러 frame을 강조하는 이유도 여기에 있다. 한 장에서는 위치만 보이지만, 연속 frame에서 같은 객체를 연결하면 위치 변화의 순서를 얻는다. 8쪽의 **MOT(Multiple Object Tracking)** 예시는 여러 객체의 ID와 위치를 함께 유지한다. 2D MOT는 주로 영상 좌표의 box를, 3D MOT는 3차원 위치와 box를 다룬다는 차이가 있지만, 시간에 걸친 동일 객체 연결이라는 목적은 같다.

### 위치 변화와 실제 속도는 구분한다

ID가 유지되면 영상 속 이동량은 계산할 수 있다. 예를 들어 같은 자동차의 중심이 $$(100,50)$$ pixel에서 $$(104,53)$$ pixel로 이동했다면 변위는 $$(4,3)$$ pixel, 이동 거리는 5 pixel이다. 두 frame의 간격이 0.1 s이면 **영상상의 이동 속력**은 50 pixel/s다. 이것을 곧바로 50 m/s로 읽으면 안 된다.

**보충 해설:** 카메라가 움직여도 영상 속 box는 움직이고, 같은 실제 이동도 원근에 따라 다른 pixel 이동으로 나타난다. 실제 공간의 m/s를 얻으려면 3D 위치 또는 적절한 평면 가정, calibration, 시간 간격과 ego-motion 보정 등이 필요하다. 7쪽의 “속도 및 방향 정보 취득 가능”은 이런 추정의 기반을 얻는다는 뜻이지, ID만 붙이면 실제 속도가 자동으로 주어진다는 뜻이 아니다.

## 2. Frame별 검출에서 data association까지

10–14쪽은 tracking을 네 단계로 나눈다.

1. **Frame 분리:** Video를 시간순 영상으로 나눈다.
2. **Object detection:** 각 frame에서 bounding box를 얻는다.
3. **초기 ID 부여:** 처음 관리할 객체마다 서로 다른 ID를 붙인다.
4. **Data association:** 새 frame의 검출을 기존 ID와 연결한다.

<figure id="adc-12-p14">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p14.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p14.png" | relative_url }}" alt="Frame 3의 ID 1과 ID 2를 frame 4의 아직 ID가 없는 두 검출에 대응시키는 문제" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=14" | relative_url }}">lecture PDF, p. 14</a>.</figcaption>
</figure>

왼쪽 frame 3에서는 트럭이 ID 1, 작은 차가 ID 2다. 오른쪽 frame 4에서는 검출 box가 있지만 ID는 아직 `?`다. **Detector의 출력 순서가 첫 번째라고 해서 ID 1을 붙이는 것이 아니라, 이전 객체와의 대응을 계산해야 한다.** 17쪽의 결과는 트럭에 ID 1, 작은 차에 ID 2를 이어 붙인다.

### 2.1 연결 기준: 중심점 사이 L2 distance

15쪽은 box 중심점 사이의 Euclidean distance, 즉 L2 distance를 예시 기준으로 쓴다. 가까운 곳에서 다시 관측된 box일수록 같은 객체일 가능성이 높다는 단순한 가정이다. 빠른 이동, 낮은 frame rate, 가림, 카메라 움직임이 크면 이 가정만으로는 부족할 수 있다.

**보충 수식 — 비용의 정의:** 이전 중심을 $$\mathbf c_i=(x_i,y_i)$$, 현재 검출 중심을 $$\mathbf d_j=(u_j,v_j)$$라고 하면 연결 비용을 다음처럼 둘 수 있다.

$$
C_{ij}=\lVert\mathbf c_i-\mathbf d_j\rVert_2
=\sqrt{(x_i-u_j)^2+(y_i-v_j)^2}
$$

$$i$$는 기존 track, $$j$$는 현재 detection의 번호다. 영상 좌표가 pixel이면 중심 좌표와 $$C_{ij}$$의 단위도 pixel이다. 앞의 $$(4,3)$$ 이동 예제는 $$\sqrt{4^2+3^2}=5$$에 해당한다. 여기서 $$C_{ij}$$는 동일인 확률이 아니라 **연결의 불리함을 나타내는 비용**이다. 값이 작을수록 선호한다.

<details markdown="block">
<summary markdown="span">Derivation: Box centers and Euclidean distance</summary>

축에 평행한 box가 $$(x_{\min},y_{\min},x_{\max},y_{\max})$$로 주어지면 중심은 양 끝점의 평균이다.

$$
x_c=\frac{x_{\min}+x_{\max}}{2},\qquad
y_c=\frac{y_{\min}+y_{\max}}{2}
$$

두 중심의 수평·수직 차이를 직각삼각형의 두 변으로 보면 Pythagorean theorem으로 거리 제곱은 두 차이의 제곱합이다. 거리는 음수가 아니므로 양의 제곱근을 취해 위 L2 식을 얻는다. 좌표 차이의 제곱 단위는 pixel²이고, 제곱근 후 pixel로 돌아온다.

L2와 **squared L2**는 구분해야 한다. 한 쌍의 후보 순위는 제곱해도 유지되지만, 여러 쌍의 **합**을 최소화하는 최적 배정은 바뀔 수 있다. 예를 들어 두 배정의 거리 목록이 각각 $$(1,5)$$와 $$(3.1,3.1)$$이면 거리합은 6과 6.2여서 전자를 택하지만, 제곱합은 26과 19.22여서 후자를 택한다. 이는 비용 집계의 차이를 보여 주는 보충 수치 예시이며 원문 차량 좌표의 측정값은 아니다.

</details>

### 2.2 이분 그래프와 비용행렬은 같은 후보들을 표현한다

<figure id="adc-12-p16">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p16.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p16.png" | relative_url }}" alt="이전 두 객체와 다음 두 검출 사이의 네 후보 연결에 거리 220 8 17 189가 표시된 이분 그래프" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>.</figcaption>
</figure>

그림은 왼쪽에 기존 ID, 오른쪽에 현재 검출을 놓고 가능한 쌍마다 선을 긋는다. 서로 다른 두 집합 사이에만 연결이 있으므로 **bipartite graph(이분 그래프)**다. 원문에서 오른쪽 위는 작은 차, 아래는 트럭이다. 이 순서대로 열을 쓰면 다음 비용행렬이 된다. 거리의 단위는 원문에 따로 기재되어 있지 않다.

| Previous ID | Current small car | Current truck |
|---|---:|---:|
| ID 1: truck | 220 | 8 |
| ID 2: small car | 17 | 189 |

ID 1→트럭, ID 2→작은 차의 총비용은 $$8+17=25$$다. 반대로 연결하면 $$220+189=409$$다. 이 예제에서는 가까운 후보를 개별 선택해도 서로 충돌하지 않아 올바른 일대일 배정을 얻는다. 그러나 다음 예제에서는 이 방식이 실패한다.

**수치 해석 주의:** 16·19쪽은 선에 거리를 표시하지만, 제시된 값들은 동일한 중심좌표들 사이의 실제 L2 distance로는 서로 일관되지 않는다. 아래에서는 원문 숫자를 유지하되 **배정 원리를 설명하는 비용 예제**로 사용한다. 영상에서 직접 측정한 정확한 거리라고 받아들이지는 않는다.

## 3. 가장 가까운 후보가 겹칠 때

18쪽에서는 frame 5에 새로운 자동차가 들어와 검출 수가 늘어난다. 19쪽은 기존 두 ID가 **동일한 가운데 검출을 가장 가까운 후보로 선택하는 상황**을 보여 준다. 여기서 “겹친다”는 것은 box가 물리적으로 포개진다는 뜻이 아니라, 서로 다른 ID가 같은 후보를 고른다는 뜻이다.

<figure id="adc-12-p19">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p19.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p19.png" | relative_url }}" alt="ID 1의 최소거리 12와 ID 2의 최소거리 9가 같은 가운데 검출에 연결되어 충돌하는 예제" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=19" | relative_url }}">lecture PDF, p. 19</a>.</figcaption>
</figure>

| Previous ID | Top detection | Middle detection | Bottom detection |
|---|---:|---:|---:|
| ID 1 | 15 | **12** | 90 |
| ID 2 | 17 | **9** | 47 |

행별 최소값은 12와 9지만, 둘 다 가운데 열이므로 **동시에 선택할 수 없다.** 일대일 제약 아래에서는 ID 1→위쪽 15, ID 2→가운데 9를 택해 총비용 24를 얻는다. ID 1→가운데 12, ID 2→위쪽 17의 총비용 29보다 작다. 아래쪽 검출은 기존 ID와 연결되지 않은 채 남는다.

**한 쌍의 가장 작은 비용을 먼저 확정하는 greedy 선택과, 가능한 전체 배정의 총비용 최소화는 다른 문제다.** Hungarian algorithm은 후자를 해결한다. 다만 아래쪽 검출을 실제 신규 객체로 확정하고 새 ID를 주는 규칙은 배정 결과를 사용하는 tracker가 별도로 정해야 한다.

<details markdown="block">
<summary markdown="span">Source Check: Are the example costs consistent Euclidean distances?</summary>

**보충 검증:** 실제 Euclidean distance는 삼각부등식을 만족해야 한다. 16쪽의 기존 두 중심을 $$P_1,P_2$$, 현재 작은 차와 트럭의 중심을 $$Q_1,Q_2$$라고 하자. 원문은 $$d(P_1,Q_1)=220$$, $$d(P_1,Q_2)=8$$, $$d(P_2,Q_1)=17$$, $$d(P_2,Q_2)=189$$를 제시한다. 세 구간을 돌아가는 경로보다 직선거리가 클 수 없으므로

$$
d(P_1,Q_1)\le d(P_1,Q_2)+d(Q_2,P_2)+d(P_2,Q_1)=8+189+17=214
$$

여야 하는데 220은 이 상한을 넘는다.

19쪽에서도 기존 두 중심 사이 거리를 $$D$$라 하면 가운데 검출을 거치는 삼각부등식에서 $$D\le12+9=21$$이다. 그러나 아래 검출까지의 거리 90과 47에는 역삼각부등식이 적용되어 $$D\ge\lvert90-47\rvert=43$$이어야 한다. 두 조건을 동시에 만족할 수 없다.

따라서 두 그림의 숫자로 공통된 실제 중심좌표를 복원할 수는 없다. **비용행렬로서의 배정 계산은 유효**하므로 원문 값을 그대로 사용하되, 이를 기하학적으로 일관된 거리 측정으로 설명하지 않는 것이 정확하다.

</details>

## 4. Hungarian algorithm: 전체 배정을 함께 고르기

### 4.1 Worker–job 예제를 tracking으로 읽기

21쪽은 각 worker에게 job을 하나씩 배정하되 총 이동 거리를 최소화하는 문제다. Tracking에 대응시키면 worker는 기존 track, job은 현재 detection, 각 칸은 연결 비용이 된다. 29쪽은 반대로 detection을 행, track을 열에 놓는다. 어느 방향을 쓰든 **행·열의 의미를 고정하고 중복 없이 배정**하면 된다.

<figure id="adc-12-p21">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p21.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p21.png" | relative_url }}" alt="Worker A B C와 Job 1 2 3 사이 비용행렬 10 15 9, 9 18 5, 6 14 3" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=21" | relative_url }}">lecture PDF, p. 21</a>.</figcaption>
</figure>

이제 비용이 $$C_{ij}$$인 $$n\times n$$ 정사각형 문제를 생각하자. 각 행과 열에서 하나씩 선택해야 하므로 목표는 다음과 같다.

$$
\min_{\pi}\sum_{i=1}^{n}C_{i,\pi(i)}
$$

$$\pi$$는 열 번호를 중복 없이 나열한 순열이고, $$n$$과 번호는 무차원이다. 비용합의 단위는 각 비용과 같다. 슬라이드는 거리를 비용으로 소개하지만 숫자의 물리적 단위는 명시하지 않으므로, 아래 계산도 **원문 비용 단위**로 읽는다.

### 4.2 Step 1: 각 행의 최솟값을 뺀다 — p. 22

<figure id="adc-12-p22">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p22.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p22.png" | relative_url }}" alt="각 행에서 최솟값 9 5 3을 차감해 행마다 0을 만드는 Hungarian 첫 단계" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=22" | relative_url }}">lecture PDF, p. 22</a>.</figcaption>
</figure>

원행렬의 행별 최솟값은 A에서 9, B에서 5, C에서 3이다. 해당 행의 **모든 원소에서** 그 값을 빼면 다음이 된다. `Remove`는 원소를 삭제한다는 뜻이 아니라 차감한다는 뜻이다.

$$
\begin{bmatrix}10&15&9\\9&18&5\\6&14&3\end{bmatrix}
\longrightarrow
\begin{bmatrix}1&6&0\\4&13&0\\3&11&0\end{bmatrix}
$$

**0은 실제 이동 거리가 0이라는 뜻이 아니다.** 같은 행의 기준 비용을 제거하고 남은 상대적 추가 비용이다. 모든 완전 배정은 각 행을 한 번씩 사용하므로, 어떤 배정을 고르든 총비용에서 똑같이 $$9+5+3=17$$이 빠진다. 따라서 배정의 우열은 바뀌지 않는다.

### 4.3 Step 2: 각 열의 최솟값을 뺀다 — p. 23

<figure id="adc-12-p23">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p23.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p23.png" | relative_url }}" alt="행 차감 결과에서 열 최솟값 1 6 0을 차감한 비용행렬" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=23" | relative_url }}">lecture PDF, p. 23</a>.</figcaption>
</figure>

현재 열별 최솟값 1, 6, 0을 각각 빼면 다음 행렬을 얻는다.

$$
\begin{bmatrix}1&6&0\\4&13&0\\3&11&0\end{bmatrix}
\longrightarrow
\begin{bmatrix}0&0&0\\3&7&0\\2&5&0\end{bmatrix}
$$

이번에도 모든 완전 배정은 각 열을 한 번씩 사용하므로 총비용에서 공통으로 7이 빠진다. 지금까지 원래 배정 비용에서 빠진 값은 $$17+7=24$$다. 하지만 **0이 여러 개 생겼다고 바로 배정할 수 있는 것은 아니다.** B와 C의 0이 모두 Job 3에만 있어 두 worker를 동시에 배정할 수 없기 때문이다.

### 4.4 Step 3: 모든 0을 최소 개수의 선으로 덮는다 — p. 24

<figure id="adc-12-p24">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p24.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p24.png" | relative_url }}" alt="0을 불필요하게 많은 선으로 덮은 왼쪽 예와 A행 및 Job 3열 두 선으로 덮은 오른쪽 예" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=24" | relative_url }}">lecture PDF, p. 24</a>.</figcaption>
</figure>

오른쪽처럼 A행과 Job 3열에 선을 하나씩 그으면 모든 0을 덮는다. 한 선만으로는 덮을 수 없으므로 최소 선 수는 2다. 행렬 크기 3보다 작아 아직 세 쌍의 독립적인 0을 고를 수 없다.

여기서 **최소**라는 조건이 중요하다. 일부러 행 세 개에 선을 그어 “선이 3개니까 종료”라고 판단하면 안 된다. 0만으로 만든 이분 그래프에서 최소 vertex cover의 크기는 maximum matching의 크기와 같다는 성질을 이용한다. 따라서 $$n\times n$$ 행렬에서 최소 선 수가 $$n$$이면 행·열이 중복되지 않는 0을 $$n$$개 배정할 수 있다. 실제 배정도 그 조건에 맞게 찾아야 한다.

### 4.5 Step 4: 미덮인 최솟값으로 행렬을 조정한다 — p. 25–26

<figure id="adc-12-p25">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p25.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p25.png" | relative_url }}" alt="미덮인 값 3 7 2 5 중 최솟값 2를 이용해 새 0을 만들고 두 선의 교차 칸에 2를 더하는 단계" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=25" | relative_url }}">lecture PDF, p. 25</a>.</figcaption>
</figure>

미덮인 칸은 B·C행의 Job 1·2, 값은 3·7·2·5다. 그중 최솟값 $$\delta=2$$로 다음처럼 조정한다.

- **어느 선에도 덮이지 않은 칸:** 2를 뺀다.
- **가로·세로 선이 교차해 두 번 덮인 칸:** 2를 더한다.
- **선 하나만 지나는 칸:** 그대로 둔다.

$$
\begin{bmatrix}0&0&0\\3&7&0\\2&5&0\end{bmatrix}
\longrightarrow
\begin{bmatrix}0&0&2\\1&5&0\\0&3&0\end{bmatrix}
$$

> **원문 문구를 정확히 읽기:** 25쪽의 `smallest element of the matrix`는 **미덮인 원소 중 최솟값**을 뜻해야 한다. 전체 행렬의 최솟값은 이미 0이므로 그것을 빼면 아무것도 바뀌지 않는다. 그림의 실제 계산은 올바르게 2를 사용한다.

조정의 목적은 기존의 모든 0을 무조건 보존하는 것이 아니라 **최적 배정의 우열을 유지하면서 새로운 독립적 연결 후보를 만드는 것**이다. 여기서는 C–Job 1에 새 0이 생기고, 두 선이 교차했던 A–Job 3은 2가 된다. 26쪽처럼 0 덮기를 다시 검사하며, 아직 최소 선 수가 3이 아니면 조정과 재검사를 반복한다.

### 4.6 Step 5: 중복 없는 0을 배정하고 원래 비용으로 합산한다 — p. 27–28

조정된 행렬에서 B행은 Job 3만 0이므로 B→Job 3을 고른다. Job 3을 더 사용할 수 없으므로 C→Job 1, 마지막으로 A→Job 2를 고른다. 각 행과 열을 정확히 한 번 사용한다.

<figure id="adc-12-p28">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p28.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p28.png" | relative_url }}" alt="원래 비용행렬과 최종 Job 1 Worker C, Job 2 Worker A, Job 3 Worker B 배정 결과" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=28" | relative_url }}">lecture PDF, p. 28</a>.</figcaption>
</figure>

| Worker | Assigned job | Original cost |
|---|---|---:|
| A | Job 2 | 15 |
| B | Job 3 | 5 |
| C | Job 1 | 6 |
| **Total** | | **26** |

변환된 행렬의 선택 값은 모두 0이지만, **실제 목적함수 값은 원행렬의 $$15+5+6=26$$**이다. 가능한 여섯 배정의 비용은 26, 27, 29, 31, 32, 33으로 이 배정이 유일한 최적해다.

27쪽의 “0이 하나인 줄부터 배정”은 이 예제를 푸는 데 유용하다. 일반 문제에서는 후보가 여러 개일 때 아무 0이나 확정하면 이후 배정이 막힐 수 있다. 필요한 경우 기존 선택을 다시 연결하는 matching 절차로 **완전한 일대일 배정**을 찾아야 한다.

<details markdown="block">
<summary markdown="span">Derivation: Why reductions preserve the optimum</summary>

**보충 증명:** 행 기준값을 $$r_i$$, 열 기준값을 $$s_j$$라 두고 $$C'_{ij}=C_{ij}-r_i-s_j$$로 변환하면, 임의의 완전 배정 $$\pi$$에 대해

$$
\sum_{i=1}^{n}C'_{i,\pi(i)}
=\sum_{i=1}^{n}C_{i,\pi(i)}
-\sum_{i=1}^{n}r_i-\sum_{j=1}^{n}s_j
$$

다. 순열이 모든 열을 한 번씩 사용하기 때문에 마지막 두 합은 배정과 무관한 상수다. 따라서 어떤 배정이 더 저렴한지는 바뀌지 않는다. 이 논증은 각 행·열을 한 번씩 쓰는 **정사각형 완전 할당**을 전제로 한다. 직사각형 문제에 그대로 적용하지 않고 먼저 적절히 padding하거나 직사각형용 solver를 사용한다.

선 조정도 같은 원리다. 덮인 행 여부를 $$R_i\in\{0,1\}$$, 덮인 열 여부를 $$S_j\in\{0,1\}$$라 두면 조정은

$$
C''_{ij}=C'_{ij}+\delta(R_i+S_j-1)
$$

로 쓸 수 있다. $$R_i+S_j$$가 0·1·2일 때 각각 $$-\delta$$·0·$$+\delta$$가 되어 본문의 세 규칙을 얻는다. 완전 배정의 총비용 변화는

$$
\delta\left(\sum_iR_i+\sum_jS_j-n\right)
$$

으로 역시 배정과 무관하다. 이 예제는 덮인 행 1개, 열 1개, $$n=3$$, $$\delta=2$$이므로 모든 배정의 비용이 추가로 2씩 줄어든다.

행·열 감소에서 24, 선 조정에서 2가 빠졌으므로 최종 행렬에서의 배정 비용은 언제나 **원래 비용−26**이다. 최종 원소가 모두 음이 아니므로 모든 원래 배정 비용은 26 이상이다. 위 배정은 0만 선택해 정확히 26을 달성한다. 따라서 최적이라는 결론을 얻는다. 이는 이 예제에서의 최적성 증명이며 단순히 결과 숫자만 비교한 주장이 아니다.

</details>

## 5. 검출 수와 track 수가 다르면: rectangular assignment

<figure id="adc-12-p29">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p29.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-12-p29.png" | relative_url }}" alt="검출 네 개와 기존 track 세 개의 4×3 행렬을 값 90인 dummy열로 4×4에 맞추는 예제" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf#page=29" | relative_url }}">lecture PDF, p. 29</a>.</figcaption>
</figure>

29쪽은 detection 4개와 기존 track 3개의 비용을 보여 준다. 오른쪽의 `Tracking 4`는 실제로 관측된 기존 track이 아니라 **정사각형 크기를 맞추는 dummy 열**로 해석해야 한다.

| Detection | Track 1 | Track 2 | Track 3 | Dummy |
|---|---:|---:|---:|---:|
| D1 | 21 | 10 | 0 | 90 |
| D2 | 56 | 62 | 11 | 90 |
| D3 | 20 | 77 | 90 | 90 |
| D4 | 10 | 80 | 20 | 90 |

**보충 검산:** 최소 배정은 D4→Track 1, D1→Track 2, D2→Track 3, D3→Dummy다. 실제 연결 비용은 $$10+10+11=31$$, dummy까지 포함한 완전 할당 비용은 $$31+90=121$$이다. D1→Track 3의 0만 먼저 확정하면 전체 최적 배정을 놓친다.

### Dummy의 90은 매칭 거절 기준이 아니다

이 4×4 완전 할당은 dummy 열을 **반드시 한 번** 사용한다. 따라서 어떤 배정이든 dummy 비용 90이 똑같이 한 번 더해진다. 같은 상수를 채운다면 90 대신 0을 써도 실제 세 연결의 최적 배정은 바뀌지 않는다. 이 예제에서 dummy는 **네 검출 중 하나가 기존 세 track과 연결되지 않는다**는 자리이지, “거리 90보다 크면 모두 거절”하는 threshold가 아니다.

원문은 열 추가를 보여 주지만, 일반적으로 행이 더 많으면 dummy **열**, 열이 더 많으면 dummy **행**을 추가해 크기를 $$\max(N,M)$$으로 맞춘다. 여기서 $$N,M$$은 각각 행·열의 개수다. 직사각형 행렬을 직접 받는 구현도 있으며, <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html" target="_blank" rel="noopener">SciPy의 공식 assignment API</a>가 그 예다. 이 함수의 현재 구현은 modified Jonker–Volgenant이므로, 강의의 다섯 단계를 그대로 실행하는 Hungarian 구현이라고 부르지는 않는다.

### 배정 이후에는 track 관리가 남는다

**보충 해설 — 강의의 배정 문제와 별도인 운영 규칙:** Dummy에 연결된 검출은 새 객체일 수도 있고 오검출일 수도 있다. 반대로 기존 track이 현재 frame에서 검출되지 않았다고 즉시 객체가 사라진 것은 아니다. 가려졌거나 detector가 놓쳤을 수 있다.

- 새 ID를 언제 확정할지, 미검출 track을 몇 frame 유지할지 별도 규칙이 필요하다.
- 현실적으로 불가능한 큰 이동은 gating 등의 기준으로 후보에서 제외할 수 있다.
- 객체 수가 같더라도 모든 쌍을 강제로 연결하면 잘못된 ID가 이어질 수 있다. 임의 개수의 미매칭을 허용하려면 그에 맞는 dummy 구성과 비용 또는 별도의 제약이 필요하다.

Hungarian algorithm은 **주어진 후보와 비용 안에서** 최적 배정을 찾는다. 비용이 외형·움직임·시간 간격을 충분히 반영하는지, 어떤 쌍을 허용할지는 tracker 설계의 문제다. 이 경계를 구분하면 “최적화가 정확한데도 ID가 바뀌는 이유”를 이해할 수 있다.

## 마지막 핵심 정리

- Detection은 현재 frame의 위치, tracking은 시간에 걸친 **동일 객체의 ID 연결**을 다룬다.
- Data association은 기존 track과 현재 detection 사이의 후보 비용을 계산하고 일대일 연결을 고르는 단계다.
- 개별 최근접 선택은 충돌할 수 있다. Hungarian algorithm은 **전체 비용합이 최소인 배정**을 찾는다.
- 행·열 차감과 선 조정은 완전 배정의 비용을 공통 상수만큼 바꾸어 최적해를 보존한다. 최종 비용은 원행렬에서 계산한다.
- 25쪽의 최소값은 **미덮인 값의 최소값**이다. 29쪽의 dummy는 수를 맞추는 장치이며, 새 ID·가림·거절 정책 자체가 아니다.

## Study Guide

1. 14–17쪽의 두 frame에서 ID, detection, 후보 연결을 각각 짚고 비용행렬로 옮긴다.
2. 19쪽의 두 행에서 최소값을 골라 충돌을 확인한 뒤, 서로 다른 열을 고르는 총비용 24와 29를 비교한다.
3. 21–28쪽의 원행렬에서 시작해 행 감소 → 열 감소 → 최소 zero cover → 미덮인 값 조정 → 독립적인 0 선택을 직접 수행한다.
4. 29쪽에서 dummy가 한 번 선택되는 이유와 실제 비용 31, padding 포함 비용 121의 차이를 설명한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">Q1. Why does a detector need an association step?</summary>

답변: Detector는 각 frame에서 box를 찾지만 이전 frame의 어떤 객체인지까지 보장하지 않는다. Class가 같거나 출력 순서가 같다는 이유로 ID를 이어 쓰면 다른 객체를 같은 track으로 묶을 수 있다. Association은 기존 ID와 현재 검출의 대응을 결정한다.

</details>

<details markdown="block">
<summary markdown="span">Q2. Why is selecting the nearest detection independently invalid?</summary>

답변: 여러 기존 track이 같은 검출을 가장 가깝다고 선택할 수 있기 때문이다. 19쪽의 12와 9는 같은 열이어서 함께 사용할 수 없다. 한 track당 한 검출, 한 검출당 한 track이라는 제약을 지키면서 전체 비용합을 비교해야 한다.

</details>

<details markdown="block">
<summary markdown="span">Q3. Do zeros represent zero physical distance?</summary>

답변: 아니다. 원래 비용에서 행·열의 기준값 등을 뺀 **변환된 비용**이 0이라는 뜻이다. 28쪽의 최종 연결은 변환 후 모두 0이지만, 원래 비용은 15·5·6이고 합은 26이다.

</details>

<details markdown="block">
<summary markdown="span">Q4. Which minimum is used in the uncovered-entry adjustment?</summary>

답변: 어느 선에도 덮이지 않은 원소 중 최솟값이다. 25쪽에서는 3·7·2·5 중 2다. 미덮인 칸에서 2를 빼고, 두 선의 교차 칸에 2를 더하며, 선 하나만 지나는 칸은 유지한다. 이후 최소 zero cover와 완전 matching 가능 여부를 다시 확인한다.

</details>

<details markdown="block">
<summary markdown="span">Q5. Does the dummy cost of 90 reject every expensive match?</summary>

답변: 아니다. 29쪽의 padding에서는 어떤 완전 할당이든 dummy 열을 한 번 사용하므로 총비용에 90이 공통으로 추가된다. 최적 실제 연결 비용은 31이며, dummy를 포함하면 121이다. 큰 이동을 거절하거나 두 집합에서 임의의 수를 미매칭으로 남기는 정책은 별도로 설계해야 한다.

</details>

## References

- Youngwook Kim, *Automatic Driving Computing — 12. Object Tracking (1)*, supplied lecture PDF, pp. 1–33.
- <a href="https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html" target="_blank" rel="noopener">SciPy: linear_sum_assignment</a> — assignment 목적함수, 정사각형·직사각형 입력과 구현 구분.

## PDF

- [12 Object Tracking (1).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-12-object-tracking-01.pdf" | relative_url }})
