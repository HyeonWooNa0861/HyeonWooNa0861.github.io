---
layout: default
date: 2026-11-06 15:00:00 +0900
title: "Lecture 16: Prediction III"
course: "Autonomous Driving"
topic: "Multimodal Motion Prediction with Target-Driven Trajectories"
order: 16
major_topic: "Autonomous Systems"
keywords:
  - "Motion Prediction"
  - "Multimodal Prediction"
  - "TNT"
  - "VectorNet"
  - "Target Prediction"
  - "Mode Averaging"
  - "Trajectory Scoring"
  - "Non-Maximum Suppression"
---

# Lecture 16: Prediction III

Source PDF: [16 Prediction (3).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf" | relative_url }})

교차로에 접근하는 차량은 직진할 수도, 회전할 수도 있다. 둘 다 가능한 상황에서 미래 경로 하나만 회귀하면, 실제로는 어느 운전자도 택하지 않을 **두 경로의 중간**을 예측할 수 있다. 이 강의는 가능한 미래를 여러 개 유지하는 문제를 다루며, **TNT(Target-driveN Trajectory Prediction)**를 통해 도착 위치 후보를 먼저 찾고 각 후보로 향하는 전체 경로를 생성한다.

> **핵심:** TNT는 **어디에 도착할지**, **그곳까지 어떻게 움직일지**, **어떤 경로들을 남길지**를 나누어 학습한다. 여러 target으로 의도 차이를 표현하고, 전체 궤적의 점수와 중복 제거를 통해 작지만 다양한 최종 예측 집합을 만든다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–6 | Context and outline | VectorNet의 장면 표현에서 다중 미래 예측으로 무엇이 추가되는가? |
| 7–10 | Intent uncertainty | 단일 경로와 mode averaging은 왜 문제가 되는가? |
| 11–12 | TNT and targets | Target은 검출 객체인가, 미래 도착 위치인가? |
| 13–16 | Context and sampling | 지도·추적 정보로 후보 위치를 어떻게 구성하는가? |
| 17–19 | Target prediction | 분류와 offset 회귀로 후보를 어떻게 줄이는가? |
| 20 | Motion estimation | 도착 위치를 알면 전체 궤적을 어떻게 예측하는가? |
| 21–23 | Scoring and selection | 도착점 점수 외에 경로 점수와 중복 제거가 왜 필요한가? |
| 24–27 | Summary and next topic | 여러 미래 경로는 planning에 무엇을 제공하는가? |

페이지는 PDF의 1-based 쪽수다. 1·2·4·6·24·27쪽은 표지·구간 구분·마무리 화면이다. 아래 수치 예제는 원본 그림을 읽은 뒤 계산을 확인하기 위한 보충 예제이며, 논문의 성능 실험값이 아니다.

## 1. 경로 하나가 여러 가능한 미래를 대신할 수 없는 이유

### 1.1 같은 과거, 다른 미래

7–8쪽의 차량은 같은 교차로에 접근하더라도 직진·회전·차선 변경을 선택할 수 있다. 예측 대상인 **actor of interest**의 과거 위치와 속도가 같아도, 아직 드러나지 않은 운전 의도 때문에 미래가 하나로 결정되지 않는다. 이것이 **intent uncertainty**다.

9쪽에서는 가능한 두 행동의 중간에 해당하는 경로를 출력하는 문제를 **mode averaging**으로 설명한다.

<figure id="adc-16-p09">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p09.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p09.png" | relative_url }}" alt="교차로에서 직진과 회전이라는 두 미래 행동을 단일 경로로 평균하면 부자연스러운 중간 경로가 생길 수 있음을 설명하는 강의 9쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=9" | relative_url }}">lecture PDF, p. 9</a>.</figcaption>
</figure>

그림에서 왼쪽으로 이어지는 화살표는 직진, 아래쪽으로 굽는 화살표는 다른 이동 의도를 나타낸다. 여기서 필요한 것은 두 화살표의 평균 방향 하나가 아니라, **서로 다른 행동을 별도 가설로 유지하는 것**이다. 모든 단일 출력 모델이 반드시 평균을 내는 것은 아니지만, squared-error로 대표값 하나를 학습하면 이런 현상이 나타날 수 있다.

### 1.2 원본 분포 그림을 읽는 법

<figure id="adc-16-p10">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p10.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p10.png" | relative_url }}" alt="파란 분포 p(x)는 두 봉우리를 갖고 초록 점선 q 별표 분포는 그 사이를 넓게 덮는 단봉 근사로 표시된 강의 10쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=10" | relative_url }}">lecture PDF, p. 10</a>.</figcaption>
</figure>

파란 $$p(x)$$의 두 봉우리는 자주 일어나는 두 종류의 결과를 나타낸다. 가운데 골짜기는 그 사이 결과가 드물다는 뜻이다. 초록 점선 $$q^*(x)$$처럼 이를 넓은 단봉 분포로 근사하면, 실제로 드문 가운데까지 그럴듯하게 보이게 할 수 있다. 이 그림 자체에는 학습 loss가 명시되지 않으므로 특정 최적화 결과의 증명으로 읽지는 않는다.

**보충 계산:** 미래 도착 위치가 각각 확률 0.5로 $$(10,4)$$ m와 $$(10,-4)$$ m라고 하자. 두 위치를 하나의 squared-error 회귀값으로 표현하면 평균인 $$(10,0)$$ m가 나온다. 두 정답까지의 squared distance는 각각 16 m²다. $$(10,4)$$ m만 출력하면 오차는 0과 64 m²이므로 평균은 32 m²다. 따라서 평균 위치는 loss를 16 m²로 낮추면서도, 실제 가능한 두 결과 중 어느 것도 표현하지 못한다.

<details markdown="block">
<summary markdown="span">Derivation: Why does squared-error regression favor the mean?</summary>

장면 조건을 $$c$$, 미래 위치를 $$Y$$, 단일 예측을 $$a$$라고 하자. $$\mu=\mathbb E[Y\mid c]$$를 넣어 전개하면

$$
\mathbb E[\lVert Y-a\rVert_2^2\mid c]
=\mathbb E[\lVert Y-\mu\rVert_2^2\mid c]
+\lVert \mu-a\rVert_2^2
$$

이다. 교차항은 $$\mathbb E[Y-\mu\mid c]=0$$이므로 사라진다. 첫 항은 $$a$$와 무관하고 둘째 항은 $$a=\mu$$에서 최소다. 따라서 조건부 squared-error의 최적 대표값은 조건부 평균이다. **평균이 가장 그럴듯한 mode와 같다는 보장은 없다.** 이 결과는 squared-error 목적에 대한 것이며, 모든 loss와 모든 단일 경로 모델에 그대로 적용되지는 않는다.

</details>

## 2. TNT의 핵심 아이디어: 경로 전체보다 도착 위치를 먼저 나눈다

11–12쪽의 TNT에서 **target**은 예측 horizon $$T$$ 시점의 도착 위치 $$(x_T,y_T)$$다. 검출할 객체라는 뜻도, 학습 정답 전체라는 뜻도 아니다. **Ground truth target**은 정답 미래 궤적에서 $$T$$ 시점에 기록된 실제 위치이고, **target candidate**는 모델이 검토할 위치 후보다. 과거 입력 이력의 마지막 관측점과는 구분한다.

경로 전체가 $$T$$개 시점의 2D 좌표이면 출력 공간은 $$2T$$차원이다. 이에 비해 마지막 위치는 2차원이다. TNT는 이 낮은 차원의 공간에 후보를 배치하여 의도 차이를 표현하고, 각 후보와 장면을 조건으로 전체 궤적을 만든다.

이는 여행 경로를 검토할 때 **도착 후보를 나누어 놓고 각각의 이동 경로를 살펴보는 것**과 비슷하다. 여기서 도착 후보는 $$T$$시점의 위치, 이동 경로는 그때까지의 위치열에 대응한다. 다만 실제 운전자가 목적지를 모델에 알려 준다는 뜻은 아니다. 후보와 그 점수도 관측 정보로 예측해야 한다.

TNT의 기여는 경로를 여러 개 출력한다는 사실만이 아니다. **공간적으로 해석 가능한 target으로 의도 불확실성을 나누고, target별 경로와 최종 경로 집합을 단계적으로 학습한다는 설계**다. 여러 경로를 평균하지 않고 각각 유지하면서, 지도 같은 사전 지식을 후보 생성에 사용할 수 있다.

강의 3쪽의 VectorNet과 TNT는 같은 축의 대체 기술이 아니다.

- **VectorNet:** 지도 선분과 actor의 과거 움직임을 표현하고, 서로의 관계를 반영한 장면 feature를 만든다.
- **TNT:** 그 feature를 받아 미래 도착 후보와 궤적을 생성·평가한다.

따라서 강의의 연결은 **벡터 기반 장면 표현을 다중 미래 예측의 입력으로 활용하는 관계**다.

<details markdown="block">
<summary markdown="span">Derivation: Decomposing future uncertainty using a target</summary>

과거 움직임과 주변 장면을 $$c$$, 미래 궤적을 $$s_F=(s_1,\ldots,s_T)$$, 도착 위치를 $$\tau$$라고 하자. 전체 확률 법칙으로

$$
p(s_F\mid c)
=\int p(\tau\mid c)\,p(s_F\mid\tau,c)\,d\tau
$$

라고 쓸 수 있다. TNT는 target 공간을 후보 집합으로 근사하여 이를 합으로 다룬다.

$$
p(s_F\mid c)
\approx\sum_{n=1}^{N}p(\tau_n\mid c)\,
p(s_F\mid\tau_n,c)
$$

앞의 분포는 **어디로 갈지**, 뒤의 조건부 분포는 **그 target을 향해 어떻게 움직일지**를 맡는다. 후보가 다른 target을 덮지 못하면 합에도 그 가능성이 들어가지 않으므로 후보의 coverage가 중요하다. 이는 원 논문의 식 (1)을 학습용 기호로 정리한 것이며, 마지막 scoring 단계의 점수가 이 합과 항상 수치적으로 같다는 뜻은 아니다.

</details>

## 3. 장면 인코딩: 지도와 추적 이력을 함께 읽는다

<figure id="adc-16-p13">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p13.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p13.png" | relative_url }}" alt="파란 예측 대상 차량과 초록 주변 차량 및 차선을 vectorization과 VectorNet context encoding으로 연결한 강의 13쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=13" | relative_url }}">lecture PDF, p. 13</a>.</figcaption>
</figure>

그림의 파란 차량은 예측 대상, 초록 차량은 주변 actor다. 회색 점선은 lane centerline이다. 왼쪽 장면을 벡터로 표현한 뒤 오른쪽의 VectorNet이 지도와 actor 간 관계를 반영한다. 출력 feature에는 단순히 대상 차량의 속도뿐 아니라 **현재 차선, 연결된 도로, 주변 차량의 위치와 움직임**에 관한 맥락이 들어가도록 학습한다.

VectorNet의 polyline은 여러 선분을 묶은 표현이다. 지도에서는 차선 등의 기하 구조를, actor에서는 시간 순서의 과거 이동을 나타낼 수 있다. Polyline 내부의 정보를 모은 뒤 global graph로 서로의 관계를 계산한다. TNT는 이를 context encoder로 이용한다. 강의는 HD map이 있는 구성에 집중하지만, 원 논문은 입력이 영상일 때 다른 encoder를 사용하는 구성도 구분한다.

## 4. Target sampling: 가능한 위치를 넓게 덮는다

14쪽은 먼저 target 후보 $$N$$개를 준비한다. 이때 sampling은 반드시 무작위 추출을 뜻하지 않는다. **도로 중심선이나 일정한 격자 위에서 위치 후보를 체계적으로 배치하는 것**도 포함한다.

<figure id="adc-16-p16">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p16.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p16.png" | relative_url }}" alt="차량은 차선 중심선을 따라, 보행자는 주변 2D 격자 위에 노란 마름모 target 후보를 두고 별표 위치로 보정하는 강의 16쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>.</figcaption>
</figure>

왼쪽 차량 그림의 노란 마름모는 **차선 중심선을 따라 놓은 후보**이고, 주황 별은 후보에서 offset을 보정한 예측 target이다. 오른쪽 보행자 그림은 차선 위에만 놓지 않고 주변 2D grid를 사용한다.

| 대상 | 후보 배치 | 필요한 이유와 조건 |
|---|---|---|
| Vehicle | Lane centerline을 일정 간격으로 sampling | 도로 구조로 후보 공간을 줄인다. 차선에서 멀리 벗어나지 않는다는 가정을 이용한다. |
| Pedestrian | 현재 위치 주변의 2D grid | 차량 차선에 묶이지 않는 이동 방향을 후보에 포함한다. Grid 범위 밖은 별도로 확장해야 한다. |

15쪽의 “도로 법규 준수·차선 밖으로 이탈하지 않음”은 **후보 구성의 가정**이지, 모델이 모든 차량의 준법 운전을 보장한다는 뜻이 아니다. Offset은 중심선 밖의 작은 위치 차이를 보정하지만, 후보 범위를 크게 벗어난 미래까지 자동으로 복구한다고 볼 수 없다.

강의의 $$N=1000$$, $$M=50$$은 원 논문이 설명하는 실용적인 예시다. 후보는 넓게 두되, 뒤에서 실제 궤적을 생성할 target은 더 적게 남긴다. 이 숫자들은 모든 장면과 데이터셋에 고정된 법칙이 아니다.

## 5. Target prediction: 분류와 offset 회귀를 함께 사용한다

<figure id="adc-16-p17">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p17.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p17.png" | relative_url }}" alt="장면 feature와 N개 target 후보를 Target Predictor에 넣어 target score와 offset을 출력하고 M개로 줄이는 강의 17쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=17" | relative_url }}">lecture PDF, p. 17</a>.</figcaption>
</figure>

그림에서 위쪽 입력은 context feature, 아래쪽 입력은 target 후보 좌표다. Target predictor는 각 후보에 대해 두 종류의 출력을 만든다.

1. **Target score:** 이 후보 근처가 실제 도착 위치일 가능성을 비교한다.
2. **Target offset:** 격자나 중심선 위 후보에서 정확한 도착 위치로 얼마나 이동해야 하는지 예측한다.

17쪽의 score는 후보들 사이의 softmax 분류로 학습한다. 18쪽의 offset은 실제 도착 위치와 가장 가까운 후보를 기준으로 Huber loss를 적용한다. 19쪽에서는 높은 score의 $$M$$개 target을 다음 단계로 보낸다.

### 수치 예제: 후보 선택과 위치 보정

설명을 위해 후보를 세 개만 둔다. 후보 위치가 $$(10,0)$$, $$(10,4)$$, $$(6,6)$$ m이고 실제 도착 위치가 $$(9.6,4.3)$$ m라면, 가장 가까운 후보는 두 번째다. 이 후보가 배울 offset은

$$
(9.6,4.3)-(10,4)=(-0.4,0.3)\ \mathrm{m}
$$

이다. 보정된 target은 $$(10,4)+(-0.4,0.3)=(9.6,4.3)$$ m가 된다.

Score의 softmax 결과가 $$(0.1,0.7,0.2)$$라면, 두 번째 후보를 정답으로 하는 classification loss는 $$-\log 0.7\approx0.357$$이다. Target score가 높다는 것과 offset이 정확하다는 것은 다른 능력이므로 두 학습 항이 필요하다. 정답 위치는 **학습할 때** label을 만들기 위해 쓰며, 추론 때 모델에 미래 정답을 넣지는 않는다.

<details markdown="block">
<summary markdown="span">Derivation: Target classification and Huber offset loss</summary>

후보 위치를 $$a_n$$, context를 $$c$$, 후보별 logit을 $$f_n=f(a_n,c)$$라고 하면

$$
\pi_n=\frac{\exp(f_n)}{\sum_{j=1}^{N}\exp(f_j)}
$$

이다. 실제 최종 위치를 $$s_T^{\mathrm{GT}}$$라고 할 때

$$
u=\underset{n}{\arg\min}\,
\lVert s_T^{\mathrm{GT}}-a_n\rVert_2,
\qquad
\Delta_u^*=s_T^{\mathrm{GT}}-a_u
$$

로 정답 후보와 offset을 정한다. 최근접 후보가 같은 거리로 겹치면 실제 구현에는 일관된 tie-breaking이 필요하다.

$$
L_{\mathrm{target}}
=-\log\pi_u+
\sum_{d\in\{x,y\}}
H_\delta(\widehat\Delta_{u,d}-\Delta_{u,d}^*)
$$

Huber loss의 일반적인 정의는

$$
H_\delta(e)=
\begin{cases}
\frac12e^2,&\lvert e\rvert\leq\delta,\\
\delta(\lvert e\rvert-\frac12\delta),&\lvert e\rvert>\delta.
\end{cases}
$$

이다. 작은 오차에서는 제곱, 큰 오차에서는 선형으로 증가하여 큰 residual의 영향을 완화한다. 예를 들어 $$\delta=1$$인 정규화된 좌표 예제에서 offset을 0으로 출력하면 residual 크기는 0.4와 0.3이다. 두 좌표의 loss 합은 $$\frac12(0.4^2+0.3^2)=0.125$$다. 이 값은 설명용 설정이지 논문 구현의 좌표 정규화나 전체 loss scale을 재현한 수치가 아니다.

위 식은 원 논문 식 (3)의 분류·offset 학습을 풀어 쓴 것이다. 연속 offset을 추가하므로 target은 sampling한 점에 정확히 고정되지 않는다.

</details>

## 6. Motion estimation: target까지의 중간 위치를 생성한다

<figure id="adc-16-p20">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p20.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p20.png" | relative_url }}" alt="M개 target과 장면 feature를 Motion Estimator에 입력하여 target별 전체 궤적을 만들고 intent uncertainty 감소를 아래 화살표로 나타낸 강의 20쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=20" | relative_url }}">lecture PDF, p. 20</a>.</figcaption>
</figure>

그림에서는 주황 별 target이 motion estimator의 입력으로 들어가고, 여러 주황 궤적이 나온다. **별은 마지막 위치 하나, 궤적은 그때까지의 전체 위치열**이다. 같은 도착 위치라도 너무 늦게 회전하거나 중간에 다른 차량과 겹치는 경로는 문제가 있으므로 endpoint만 예측해서는 충분하지 않다.

Motion estimator는 context와 target을 받아 $$1,\ldots,T$$ 시점의 좌표, 즉 target당 $$2T$$개 값을 출력한다. 예를 들어 미래 30 step을 예측한다면 target 하나당 60개 좌표값, $$M=50$$개 target이면 총 $$50\times30\times2=3000$$개 좌표값이다. 여기서 **30 step은 계산을 위한 예시**이며 슬라이드가 고정한 horizon은 아니다.

슬라이드 오른쪽의 아래 화살표는 target을 조건으로 주면 의도 불확실성이 줄어든다는 설명이다. 이를 **모든 불확실성이 사라진다**고 읽으면 안 된다. 여러 의도는 여러 target에 남아 있고, 같은 target으로 향하는 속도·회전 시점 등의 차이도 존재한다.

원 논문은 이 조건부 경로 분포를 단봉으로 근사하고, target과 context가 주어진 뒤의 미래 시점을 조건부 독립으로 모델링한다. 이는 계산을 단순하게 하는 **모델 가정**이다. 같은 endpoint에 도달하는 서로 다른 복잡한 경로까지 항상 하나의 mode로 정리된다는 수학적 보장은 아니다.

<details markdown="block">
<summary markdown="span">Details: Motion loss, conditional independence, and training targets</summary>

한 target $$\tau$$에 대해 원 논문은

$$
p(s_F\mid\tau,c)
=\prod_{t=1}^{T}p(s_t\mid\tau,c)
$$

로 모델링한다. 이것은 확률의 곱 법칙만으로 자동 성립하는 식이 아니다. 일반적인 곱 법칙에는 과거의 미래 상태도 조건으로 들어가지만, 여기서는 $$\tau,c$$가 주어졌을 때 각 미래 시점이 조건부 독립이라는 가정을 추가한다. 그 결과 시점별 예측을 순차적으로 반복하지 않고 한 번의 MLP 출력으로 계산할 수 있다.

Motion regression은 각 시점의 좌표 오차에 Huber loss를 합한다.

$$
L_{\mathrm{motion}}
=\sum_{t=1}^{T}\sum_{d\in\{x,y\}}
H_\delta(\widehat s_{t,d}-s_{t,d}^{\mathrm{GT}})
$$

원 논문은 학습을 안정화하기 위해 **teacher forcing**으로 실제 도착 위치를 target 입력에 사용한다. 추론에서는 이전 단계가 예측한 target을 사용한다. 따라서 학습과 추론의 입력 조건을 구분해야 한다. 위 식은 학습 목적의 정의이며, loss가 작다는 사실만으로 운동학적 제약이나 무충돌이 증명되지는 않는다.

</details>

## 7. Trajectory scoring: 도착점이 아니라 경로 전체를 다시 평가한다

<figure id="adc-16-p21">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p21.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p21.png" | relative_url }}" alt="전체 궤적에 대한 Score Predictor와 시점별 squared displacement의 최댓값 D를 제시한 강의 21쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=21" | relative_url }}">lecture PDF, p. 21</a>.</figcaption>
</figure>

Target score는 **마지막에 그 근처에 있을 가능성**을 평가한다. Trajectory score는 **그곳까지 이어지는 전체 경로**를 평가한다. 마지막 위치가 같아도 중간 움직임은 다를 수 있으므로 첫 점수를 그대로 재사용하지 않는다. 그림에서 motion estimator 뒤에 별도의 score predictor가 붙는 이유다.

원본 수식의 $$D$$는 같은 시점의 위치 차이를 비교한 뒤, 가장 큰 squared distance를 취한다.

$$
D(s^i,s^j)
=\max_{1\leq t\leq T}
\lVert s_t^i-s_t^j\rVert_2^2
$$

**마지막 위치만 보는 FDE도, 전체 시점의 평균을 보는 ADE도 아니다.** 예를 들어 두 시점의 위치 오차가 1 m와 3 m이면 $$D=\max(1^2,3^2)=9$$ m²다. 평균 Euclidean error는 2 m이므로 다른 값이다.

### “거리에 반비례”를 정확히 읽기

21쪽의 표현은 **정답 경로와 가까울수록 높은 점수를 부여한다**는 방향을 설명한다. 원 논문의 실제 학습용 target distribution은 문자 그대로 $$1/D$$가 아니라 **음의 거리에 softmax를 취한 분포**다. $$D=0$$에서도 나눗셈 발산은 생기지 않는다.

설명용으로 경로 두 개의 $$D$$가 0과 1 m²이고 temperature $$\alpha=1$$ m²이면, 학습용 점수는 약 0.731과 0.269다. 모델이 출력한 점수가 $$(0.6,0.4)$$라면 soft-label cross entropy는 약 0.620이다. 이는 “첫 경로가 정답에 더 가깝다”는 상대적 학습 신호다. **실제 미래가 각각 이 확률로 발생한다는 보정된 확률값의 보장은 아니다.**

<details markdown="block">
<summary markdown="span">Derivation: Distance-based soft labels and trajectory scores</summary>

$$M$$개 궤적의 모델 점수와 학습 target은 각각 다음과 같다.

$$
\phi_m=
\frac{\exp(g(s_F^m,c))}
{\sum_{j=1}^{M}\exp(g(s_F^j,c))}
$$

$$
\psi_m=
\frac{\exp(-D(s_F^m,s_F^{\mathrm{GT}})/\alpha)}
{\sum_{j=1}^{M}\exp(-D(s_F^j,s_F^{\mathrm{GT}})/\alpha)}
$$

$$
L_{\mathrm{score}}
=-\sum_{m=1}^{M}\psi_m\log\phi_m
$$

정답과 가까운 경로는 $$-D/\alpha$$가 더 크므로 더 큰 $$\psi_m$$를 얻는다. 예제의 두 거리를 넣으면

$$
(\psi_1,\psi_2)
=\frac{(1,e^{-1})}{1+e^{-1}}
\approx(0.7311,0.2689)
$$

$$
L_{\mathrm{score}}
\approx-0.7311\log0.6-0.2689\log0.4
\approx0.6199
$$

이다. $$\alpha>0$$가 작으면 가장 가까운 경로에 label이 집중되고, 크면 더 고르게 분산된다. 원 논문의 실험 설정은 $$\alpha=0.01$$이며, 본문 계산의 1은 직관을 위한 다른 설정이다.

**단위 확인:** 강의와 논문의 수식처럼 Euclidean norm을 제곱하면 $$D$$의 단위는 m²다. 지수의 입력이 무차원이 되려면 $$\alpha$$도 같은 단위를 가져야 한다. 논문 본문은 $$D$$를 meters라고 부르지만 제곱 수식과는 일치하지 않으므로, 여기서는 **수식의 정의를 따라 squared distance와 그에 맞는 temperature 단위**를 사용한다.

</details>

## 8. Selection: 높은 점수와 다양한 경로는 다른 조건이다

<figure id="adc-16-p22">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p22.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p22.png" | relative_url }}" alt="N개 target 후보에서 M개 target과 경로를 만든 뒤 scoring과 중복 제거로 K개 궤적을 남기는 전체 TNT 구조의 강의 22쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=22" | relative_url }}">lecture PDF, p. 22</a>.</figcaption>
</figure>

단순히 점수가 높은 경로 $$K$$개를 고르면 서로 거의 겹치는 직진 경로만 남을 수 있다. 이는 여러 예측을 출력했어도 다른 의도는 담지 못하는 경우다. TNT는 점수순으로 경로를 확인하면서, 이미 선택한 경로들과 너무 비슷한 후보를 제외한다.

**보충 예제:** A·B·C의 점수가 0.50·0.30·0.20이라고 하자. A와 B는 거의 같은 직진 경로이고 C는 회전 경로다. $$D(A,B)=0.04$$ m², $$D(A,C)=9$$ m²이고 중복 기준을 1 m²로 두면 A를 먼저 선택한 뒤 B를 제외하고 C를 남긴다. $$K=2$$인 이 예제에서 단순 top-2는 A·B, 다양성 선택은 A·C다.

이때 1 m²는 원리를 보여 주기 위한 예시 threshold다. 실제로는 좌표 scale, 데이터셋, 선택 정책에 맞춰 정해야 한다. 원 논문의 선택 방식은 object detection의 **NMS에서 착안**했지만, bounding-box IoU가 아니라 궤적 간 거리로 유사도를 판단한다.

### 후보 수가 줄어드는 세 단계

| 기호 | 대상 | 역할 |
|---|---|---|
| $$N$$ | 초기 target 후보 | 가능한 도착 위치를 넓게 덮는다. 강의 예시는 1000개다. |
| $$M$$ | 보정·선별한 target 및 생성 궤적 | 유망한 위치만 상세 경로로 바꾼다. 강의 예시는 50개다. |
| $$K$$ | 최종 궤적 | 점수와 다양성을 고려한 작은 출력 집합이다. 강의·논문 예시는 6개다. |

$$N,M,K$$는 서로 다른 단계의 후보 수다. 시점 수 $$T$$나 actor 수를 뜻하지 않는다. Target prediction, motion estimation, trajectory scoring의 MLP는 원 논문의 설정에서 각각 **2-layer, hidden size 64**를 사용한다. 이 크기는 구현 설정이며 TNT라는 문제 분해 자체의 필수 조건은 아니다.

<details markdown="block">
<summary markdown="span">Details: Greedy diversity selection</summary>

점수 내림차순의 $$M$$개 궤적을 순회한다. 선택 집합 $$S$$가 비어 있으면 첫 궤적을 넣는다. 이후 후보 $$s$$는

$$
\min_{r\in S}D(s,r)>\theta
$$

일 때만 넣는다. 즉 이미 선택한 **모든** 경로와 충분히 달라야 한다. $$K$$개를 선택하거나 후보를 소진하면 끝난다. 이는 개념을 설명하는 선택 절차이며, threshold 조정이나 부족한 후보를 채우는 fallback의 세부 정책은 실제 구현에서 확인해야 한다.

$$T$$시점의 거리 비교가 $$O(T)$$라면, score 정렬은 $$O(M\log M)$$, 최대 $$K$$개와의 비교는 $$O(MKT)$$다. 후보를 많이 유지하면 coverage가 늘 수 있지만 후속 계산량도 증가하므로 $$M$$은 recall과 비용을 함께 조절한다. Greedy 선택은 전역적으로 최적인 경로 집합을 보장하지 않는다.

</details>

## 9. 원본 마지막 그림으로 전체 과정을 다시 읽기

<figure id="adc-16-p23">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-16-p23.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-16-p23.png" | relative_url }}" alt="왼쪽에서 target 후보를 보정하고 가운데서 경로를 생성한 뒤 오른쪽에서 점수 0.3 0.2 0.4 0.1과 선택 및 제외 궤적을 나타낸 강의 23쪽" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf#page=23" | relative_url }}">lecture PDF, p. 23</a>. The framework illustration originates from the TNT paper, Figure 1.</figcaption>
</figure>

왼쪽의 **노란 마름모**는 아직 검토 중인 위치 후보다. **주황 별**은 target predictor가 위치를 보정한 결과다. 가운데에서는 별을 향하는 **주황 선**이 생긴다. 마지막 패널에서는 선마다 0.3·0.2·0.4·0.1 같은 점수가 붙고, 일부 경로는 **점선**으로 표시되어 선택되지 않았음을 보여 준다.

그림의 점수는 합이 1인 설명용 예시다. 최고 점수 0.4인 경로 하나만 정답이라고 단정하거나, 최종 출력 수가 그림에 보이는 선 수로 항상 고정된다고 읽지 않는다. 중요한 변화는 **점 후보, 전체 경로, 점수를 가진 경로 집합**이 차례로 만들어진다는 것이다.

Object detection과의 공통점은 후보를 만들고, 위치를 보정하고, 점수를 매긴 뒤 중복을 제거한다는 처리 구조다. 차이점은 TNT의 후보가 현재 객체의 box가 아니라 **미래 위치**, 최종 예측이 현재 검출이 아니라 **미래 위치열**이라는 점이다. 26쪽의 다음 주제인 planning은 이러한 여러 미래를 참고해 자차의 선택을 검토한다. TNT 자체가 최종 조향·가속 명령을 출력하는 것은 아니다.

### 원 논문의 검증 범위

TNT 원 논문은 차량 예측을 Argoverse Forecasting·INTERACTION에서, 보행자 예측을 Stanford Drone·Pedestrian-at-Intersection에서 평가한다. 따라서 차량의 lane 기반 후보와 보행자의 grid 후보는 서로 다른 이동 조건을 다루는 설계다. 다만 이 강의에는 성능 비교표나 ablation 결과가 없으므로, 앞의 설명용 수치를 실험 성능으로 해석하거나 구조도만으로 모든 환경에서의 우수성을 결론 내리지는 않는다.

## 마지막 핵심 정리

- **단일 평균 경로는 가능한 미래를 지울 수 있다.** 다중 경로 예측은 서로 다른 의도를 별도 가설로 유지한다.
- **Target은 horizon 끝의 위치다.** TNT는 target별 전체 경로를 예측하며, endpoint 점수와 경로 점수는 구분한다.
- **분류는 후보 간 선택, offset 회귀는 위치 보정**을 맡는다. 추론에 미래 정답은 사용하지 않는다.
- **$$N,M,K$$는 각각 초기 target·중간 target/경로·최종 경로 수**다. 1000·50·6은 설정 예시다.
- **경로 점수는 음의 거리 softmax로 학습한다.** 문자 그대로의 역거리나 자동으로 보정된 발생 확률이 아니다.
- **NMS 유사 선택은 중복을 줄인다.** 다양한 출력이 모든 미래를 포함하거나 안전을 보장한다는 뜻은 아니다.

## Study Guide

복습할 때는 23쪽의 마름모·별·선·점수가 무엇인지 먼저 설명하고, 22쪽에서 각 출력이 어느 모듈에서 생성되는지 확인한다. 이후 21쪽의 $$D$$가 마지막 오차나 평균 오차와 어떻게 다른지 계산하면, 왜 scoring 단계가 따로 필요한지 연결된다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. 직진·회전 경로의 평균은 왜 좋은 예측이 아닐 수 있는가?</summary>

답변: Squared-error 관점에서는 평균 위치의 손실이 작을 수 있지만, 평균 위치가 어느 실제 행동에도 해당하지 않을 수 있다. 따라서 단일 평균이 아니라 서로 다른 mode를 별도 경로로 유지할 필요가 있다.

</details>

<details markdown="block">
<summary markdown="span">2. VectorNet과 TNT는 서로 교체되는 모델인가?</summary>

답변: 이 강의의 구성에서는 아니다. VectorNet은 지도와 actor history에서 context feature를 만드는 encoder이고, TNT는 그 feature를 활용해 target과 다중 궤적을 예측하는 framework다.

</details>

<details markdown="block">
<summary markdown="span">3. Target score가 높은데도 trajectory score를 다시 계산하는 이유는 무엇인가?</summary>

답변: Target score는 마지막 위치의 타당성만 평가한다. 그곳까지 이어지는 중간 움직임까지 타당한지는 전체 경로를 보고 평가해야 하므로 별도의 trajectory score가 필요하다.

</details>

<details markdown="block">
<summary markdown="span">4. Target을 조건으로 주면 intent uncertainty가 완전히 사라지는가?</summary>

답변: 아니다. 여러 의도는 서로 다른 target 후보에 남아 있다. 같은 target 아래의 경로를 단봉 분포로 근사하는 것은 모델 가정이며, 그 아래에도 속도와 회전 시점 등의 차이가 남을 수 있다.

</details>

<details markdown="block">
<summary markdown="span">5. 두 경로의 시점별 오차가 1 m와 3 m이면 $$D$$는 얼마인가?</summary>

답변: $$D=\max(1^2,3^2)=9$$ m²다. 강의의 수식은 최대 squared distance이며 평균 거리 2 m나 마지막 거리 3 m와 다르다. Temperature와 선택 threshold도 이 정의의 단위에 맞춰 해석한다.

</details>

<details markdown="block">
<summary markdown="span">6. 최종 선택에서 단순 top-K 대신 중복 제거를 하는 이유는 무엇인가?</summary>

답변: 높은 점수의 경로들이 서로 거의 같을 수 있기 때문이다. 이미 선택한 경로와 너무 가까운 후보를 제외하면 제한된 출력 수 안에서 다른 미래를 남길 수 있다. 다만 coverage나 전역 최적성은 보장하지 않는다.

</details>

## PDF

[Open the original lecture PDF]({{ "/assets/pdfs/study/autonomous-driving/lecture-16-prediction-03.pdf" | relative_url }})

## References

- <a href="https://proceedings.mlr.press/v155/zhao21b.html" target="_blank" rel="noopener">TNT: Target-driven Trajectory Prediction — official PMLR record</a>. CoRL 2020; proceedings published in 2021.
- <a href="https://proceedings.mlr.press/v155/zhao21b/zhao21b.pdf" target="_blank" rel="noopener">TNT — primary paper</a>. Sections 3–4 explain target factorization, losses, and selection; Section 5.2 gives implementation settings.
- <a href="https://openaccess.thecvf.com/content_CVPR_2020/html/Gao_VectorNet_Encoding_HD_Maps_and_Agent_Dynamics_From_Vectorized_Representation_CVPR_2020_paper.html" target="_blank" rel="noopener">VectorNet: Encoding HD Maps and Agent Dynamics from Vectorized Representation — CVPR 2020</a>.
