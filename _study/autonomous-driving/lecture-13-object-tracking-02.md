---
layout: default
date: 2026-10-28 23:10:00 +0900
title: "Lecture 13: Object Tracking II"
course: "Autonomous Driving"
topic: "Kalman Filtering, SORT, DeepSORT, and MOTA"
order: 13
major_topic: "Autonomous Systems"
keywords:
  - "Object Tracking"
  - "Kalman Filter"
  - "SORT"
  - "DeepSORT"
  - "Data Association"
  - "MOTA"
---

# Lecture 13: Object Tracking II

Source PDF: [13 Object Tracking (2).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf" | relative_url }})

Tracking에서 같은 객체의 ID를 유지하려면 **다음 위치를 예상하는 일**과 **새 검출이 어느 객체인지를 고르는 일**을 함께 해야 한다. 검출 box는 조금씩 흔들리고, 객체는 움직이며, 가려지면 검출 자체가 사라지기도 한다. 이전 위치에 가장 가까운 box를 고르는 것만으로는 이런 변화를 다루기 어렵다.

이 강의는 **Kalman filter로 다음 상태를 예측·보정하고, SORT로 예측 box와 현재 검출을 연결한 뒤, DeepSORT의 외형 정보로 ID 연결을 보완하는 과정**을 설명한다. 마지막에는 MOTA로 미검출·오검출·ID 변경을 집계한다.

> **핵심:** Kalman filter는 “어디에 있을까?”, data association은 “누구일까?”를 다룬다. 둘은 서로 필요하지만 같은 계산은 아니다. MOTA는 그 결과의 오류를 세는 평가 지표이며, 실제 추적 중에 정답 위치를 알려 주는 장치는 아니다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–5 | Introduction and review | 검출과 Hungarian 배정 다음에 무엇이 필요한가? |
| 6–11 | Kalman filter | 흔들리는 검출과 움직임 예측을 어떻게 결합하는가? |
| 12–13 | SORT | 예측·IoU·배정을 어떻게 하나의 tracker로 묶는가? |
| 14 | DeepSORT | 위치만으로 구분하기 어려울 때 외형을 어떻게 사용하는가? |
| 15–16 | Tracking metrics | FN·FP·ID switch를 어떻게 평가하는가? |
| 17–20 | Summary and next topic | Tracking의 출력과 이후 prediction의 역할은 어떻게 다른가? |

페이지는 PDF의 1-based 쪽수다. 1·2·4·6·12·15·17·20쪽은 표지·구간 구분·질문 화면이다. 원본 그림을 먼저 읽고, 강의에서 식으로 전개하지 않은 Kalman 계산과 논문 세부 절차는 보충 해설로 구분한다. 이 자료에는 실행 코드가 없다.

## 1. 검출 box가 흔들려도 같은 객체를 이어 가기

7쪽은 frame마다 얻는 검출이 정확한 위치 측정과 같지 않다는 점을 보여 준다. 빠른 움직임, 가림, detector의 오차 때문에 box의 중심·크기·종류가 불안정해질 수 있다. 이 강의의 범위는 **tracking-by-detection**, 즉 detector의 출력을 시간축으로 연결하는 방식이다.

<figure id="adc-13-p07">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p07.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p07.png" | relative_url }}" alt="도로 영상의 차량 검출 box가 객체 경계와 어긋나고 class 표기도 잘못된 tracking-by-detection 예시" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=7" | relative_url }}">lecture PDF, p. 7</a>.</figcaption>
</figure>

오른쪽 차량 부근의 큰 초록 box는 객체의 경계와 어긋나 있고, `aeroplane`이라는 잘못된 class 표기도 보인다. 그림은 **검출 결과에 오차가 있다는 예시**다. 한 장의 정지 영상만으로 오차가 발생한 원인을 빠른 이동이나 가림 하나로 확정할 수는 없다.

같은 객체를 이전부터 관찰했다면 “지난 위치와 속도를 고려할 때 이번에는 이 부근에 있을 것”이라는 예측을 만들 수 있다. 새 검출이 예상 위치와 조금 달라도 곧바로 새 ID를 만들지 않고, 기존 track과의 연결 가능성을 검사한다. 다만 잘못된 class나 다른 객체의 box를 Kalman filter가 자동으로 올바르게 고쳐 주는 것은 아니다. **올바른 측정 연결이 먼저 성립해야 상태 보정도 의미가 있다.**

## 2. Kalman filter: 예측과 측정의 신뢰도를 함께 쓰기

### 2.1 Prediction과 update가 번갈아 필요한 이유

8쪽은 Kalman filter를 동역학 모델과 잡음이 있는 측정을 결합하는 방법으로 소개한다. 9쪽에서는 이를 tracking에 대응시켜 **등속도 모델로 예측하고 detector의 box로 보정**한다. 등속도는 이 예제와 SORT가 선택한 모델이지 Kalman filter의 일반 정의는 아니다.

<figure id="adc-13-p09">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p09.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p09.png" | relative_url }}" alt="Kalman filter의 prediction-update 순환과 예측 분포 및 측정 분포를 결합해 보정 분포를 얻는 개념도" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=9" | relative_url }}">lecture PDF, p. 9</a>.</figcaption>
</figure>

왼쪽 순환도를 먼저 보면 두 단계가 반복된다.

1. **Prediction:** 직전 상태와 움직임 모델로 이번 상태를 예상한다. 검출이 없어도 계산할 수 있지만, 모델 오차 때문에 불확실성이 쌓인다.
2. **Update:** 이번 검출이 해당 track의 측정으로 연결되면 예측을 보정한다. 예측과 검출 중 어느 쪽을 더 신뢰할지는 불확실성으로 정한다.

오른쪽 곡선은 이 결합을 개념적으로 나타낸다. 가로 방향은 가능한 상태 값, 곡선의 폭은 그 값에 대한 불확실성으로 읽는다. 두 정보가 같은 상태에 대한 독립적인 Gaussian 정보라면 결합 후 분포는 각각보다 좁아질 수 있다. 세로 높이는 확률밀도이므로 **곡선 한 점의 높이를 그 위치일 확률로 읽지 않는다.** 원문 곡선은 실제 차량 데이터로 얻은 정량 결과가 아니다.

### 2.2 수치 예제: 110 pixel과 114 pixel 중 어디를 택하는가?

**보충 예제:** 한 track의 이전 수평 위치가 100 pixel, 속도가 10 pixel/s이고 다음 frame까지 1 s가 지났다고 하자. 등속도 예측은 110 pixel이다. 현재 detector는 114 pixel을 보고했다.

두 위치를 무조건 반반 평균하지 않는다. 예측 위치의 오차 분산이 $$P^-=4\;\mathrm{pixel}^2$$, 측정 잡음 분산이 $$R=9\;\mathrm{pixel}^2$$이고 두 오차가 독립적이라면 **Kalman gain은 $$K=4/(4+9)=4/13$$**이다. 예측을 기준으로 측정과의 차이 4 pixel 중 약 30.8%만 반영한다.

$$
\hat x^+=110+\frac{4}{13}(114-110)
\approx111.23\;\mathrm{pixel}
$$

측정이 더 불확실하므로 보정값은 114보다 110에 가깝다. 반대로 $$R=1\;\mathrm{pixel}^2$$로 측정을 더 신뢰하면 $$K=4/5$$가 되어 113.2 pixel로 이동한다. **Gain은 객체의 이동 속도가 아니라, 현재 측정으로 얼마나 보정할지를 정하는 무차원 가중치**다.

| Symbol | Meaning | Unit in this example |
|---|---|---|
| $$\hat x^-,\hat x^+$$ | 측정 반영 전·후 위치 추정 | pixel |
| $$z$$ | 현재 detector가 측정한 위치 | pixel |
| $$P^-$$ | 예측 위치 오차의 분산 | pixel² |
| $$R$$ | 측정 잡음의 분산 | pixel² |
| $$K$$ | 측정 차이를 반영하는 gain | dimensionless |

위 기호에서 위첨자 $$-$$와 $$+$$는 음수·양수 표시가 아니라 **update 이전과 이후**를 구분한다. 아래 유도는 1차원 위치에 대한 설명이며, 실제 tracker는 위치·크기·속도를 포함하는 벡터와 공분산 행렬을 사용한다.

<details markdown="block">
<summary markdown="span">Derivation: Why is the gain P / (P + R)?</summary>

예측 오차와 측정 잡음이 독립적인 Gaussian이고 측정이 위치 자체라면, 참 위치 $$x$$에 대해 예측 정보와 측정 정보의 곱을 생각할 수 있다. 음의 로그에서 $$x$$에 무관한 항을 빼면 다음 목적함수를 얻는다.

$$
J(x)=\frac{(x-\hat x^-)^2}{2P^-}
+\frac{(z-x)^2}{2R}
$$

분산이 작을수록 그 정보에서 벗어나는 데 큰 비용이 부과된다. 미분해 0으로 두면

$$
\frac{x-\hat x^-}{P^-}+\frac{x-z}{R}=0
$$

이고, 양변에 $$P^-R$$을 곱해 정리하면

$$
\begin{aligned}
(P^-+R)x&=R\hat x^-+P^-z,\\
x&=\hat x^-+\frac{P^-}{P^-+R}(z-\hat x^-).
\end{aligned}
$$

따라서 $$K=P^-/(P^-+R)$$다. 목적함수의 2차 미분은 $$1/P^-+1/R>0$$이므로 이 점이 유일한 최솟값이다. 이 Gaussian 조건에서는 posterior mean과 MAP가 일치하며, 평균제곱오차를 최소화하는 추정이기도 하다.

결합 후 분산은 precision, 즉 분산의 역수를 더해 구한다.

$$
P^+=\left(\frac1{P^-}+\frac1R\right)^{-1}
=\frac{P^-R}{P^-+R}=(1-K)P^-.
$$

예제에서는 $$P^+=36/13\approx2.77\;\mathrm{pixel}^2$$다. 모델이 틀리거나 잘못된 객체의 검출을 연결하면 이 수치가 작아져도 실제 위치가 정확하다는 보장은 없다. 독립성·잡음 모형 등 가정이 중요하다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: From constant velocity to the vector Kalman filter</summary>

위치와 속도를 함께 추적하는 1차원 등속도 모델을 쓰자. 시간 간격 $$\Delta t$$의 단위는 s다.

$$
\mathbf x_t=\begin{bmatrix}x_t\\v_t\end{bmatrix},\qquad
F=\begin{bmatrix}1&\Delta t\\0&1\end{bmatrix},\qquad
H=\begin{bmatrix}1&0\end{bmatrix}.
$$

$$F$$의 첫 행은 $$x_t=x_{t-1}+v_{t-1}\Delta t$$, 둘째 행은 속도를 그대로 유지하는 가정이다. $$H$$는 detector가 속도가 아니라 위치를 직접 측정한다는 뜻이다. 선형 모델에 평균 0의 process noise $$\mathbf w_t$$와 measurement noise $$\mathbf n_t$$를 더하면

$$
\mathbf x_t=F\mathbf x_{t-1}+\mathbf w_t,\qquad
z_t=H\mathbf x_t+\mathbf n_t.
$$

$$Q$$는 process noise 공분산, $$R$$은 measurement noise 공분산이다. 모델이 설명하지 못하는 가속 등을 $$Q$$로 반영한다. 잡음과 이전 오차가 독립적이라는 조건에서 선형변환의 공분산 법칙을 쓰면 prediction은 다음과 같다.

$$
\hat{\mathbf x}_t^-=F\hat{\mathbf x}_{t-1}^+,\qquad
P_t^-=FP_{t-1}^+F^\top+Q.
$$

검출과 예측의 차이인 innovation 및 그 공분산을 계산한다.

$$
\boldsymbol\nu_t=z_t-H\hat{\mathbf x}_t^-,\qquad
S_t=HP_t^-H^\top+R.
$$

상태 오차와 innovation의 교차 공분산은 $$P_t^-H^\top$$이므로, Gaussian 조건부 평균의 보정 계수는 $$K_t=P_t^-H^\top S_t^{-1}$$이다. 따라서

$$
\hat{\mathbf x}_t^+=\hat{\mathbf x}_t^-+K_t\boldsymbol\nu_t,\qquad
P_t^+=(I-K_tH)P_t^-.
$$

실제 수치 구현에서는 공분산의 대칭성과 안정성을 위해 Joseph form도 사용할 수 있다.

$$
P_t^+=(I-K_tH)P_t^-(I-K_tH)^\top+K_tRK_t^\top.
$$

상태에 위치와 속도가 섞이면 $$P$$의 위치 분산·속도 분산·교차 공분산은 각각 pixel², pixel²/s², pixel²/s 단위다. 전체 행렬에 하나의 물리 단위를 붙이지 않는다. 검출이 연결되지 않으면 이번 update를 생략하고 예측 상태를 유지하되, 미검출 기간에 대한 track 관리 규칙이 필요하다.

</details>

### 2.3 ID마다 예측하고, 연결된 검출로만 보정한다

<figure id="adc-13-p10">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p10.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p10.png" | relative_url }}" alt="ID 1 트럭과 ID 2 차량을 다음 frame의 검출에 연결할 때 Kalman filter의 예측 위치를 이용하는 그림" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=10" | relative_url }}">lecture PDF, p. 10</a>.</figcaption>
</figure>

10쪽의 주황 점선 box는 Kalman filter가 예상한 위치다. **이전 frame에 있던 위치 그대로가 아니라, 현재 frame에서 예상되는 위치**와 새 검출을 비교해야 한다. Track마다 별도의 상태와 공분산을 유지하고, 연결이 정해지면 해당 track만 그 검출로 보정한다.

이 때문에 실제 처리 순서는 **기존 track 예측 → 현재 검출과 배정 → 매칭된 track 보정**이다. 급회전·급가속·카메라 움직임이 모델과 맞지 않으면 예상 위치도 빗나갈 수 있다. 더 적절한 운동 모델이나 카메라 움직임 보정, 외형 정보 등을 함께 쓰는 이유다.

<figure id="adc-13-p11">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p11.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p11.png" | relative_url }}" alt="실내 보행자 주변의 box와 여러 색 궤적 및 기둥에 의한 가림이 보이는 tracking 정지 화면" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=11" | relative_url }}">lecture PDF, p. 11</a>.</figcaption>
</figure>

11쪽에서는 현재 보행자 box와 이어진 궤적을 구분해 본다. 중앙의 기둥처럼 관측을 가리는 구조물이 있어도 track은 이전 관측과 움직임 정보를 유지할 수 있다. 다만 원본은 정지 화면이고 색의 의미를 정한 범례가 없다. **색깔별 선을 prediction·measurement·정답으로 단정하거나, 이 한 장에서 가림 전후 ID 유지 성공률을 계산할 수는 없다.**

## 3. SORT: 예측·겹침·배정을 실시간 추적기로 묶기

SORT의 문제의식은 복잡한 추적 구성요소를 계속 추가하기보다 **좋은 detector와 단순한 상태 추정·배정만으로 얼마나 빠르고 효과적으로 추적할 수 있는가**에 있다. 별도의 appearance embedding 없이 box의 위치·크기와 시간적 예측을 사용한다. 새로운 Kalman 수식 자체보다, 이 조합을 간단한 online MOT 기준선으로 제시한 것이 핵심이다.

<figure id="adc-13-p13">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p13.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p13.png" | relative_url }}" alt="SORT에서 video detector 출력과 기존 track의 예측 box로 IoU matrix를 만들고 assignment 결과를 tracker에 되먹임하는 구조" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=13" | relative_url }}">lecture PDF, p. 13</a>.</figcaption>
</figure>

그림은 두 입력이 `IoU Matrix`에서 만나는 순서로 읽는다. 위쪽 `Detector`는 **현재 frame의 검출 box**를, 아래쪽 `Prediction`은 **기존 track이 현재 있어야 할 예측 box**를 보낸다. `Assignment`는 두 집합의 대응을 정하고, 결과는 `Trackers`로 돌아가 다음 frame의 예측에 사용된다.

1. 기존 track마다 Kalman prediction을 수행한다.
2. 예측 box와 현재 detection 사이의 IoU를 계산한다.
3. Hungarian 방식으로 일대일 배정을 구하고, 겹침이 너무 작은 연결은 threshold로 거절한다.
4. 연결된 track은 detection으로 update한다. 미연결 detection의 신규 track 후보 생성과 오래 미검출된 track 삭제는 별도로 처리한다.

**서지·속도 정정:** 13쪽의 `ICIP 2017`과 달리 SORT는 **ICIP 2016** 논문이다. 원문에서 보고한 **260 Hz는 detector를 제외한 tracking component**의 처리 속도다. 단일 Intel i7 2.5 GHz core와 16 GB 메모리 환경의 결과이며, 카메라 입력부터 detection까지 포함한 전체 자율주행 시스템이 260 fps라는 뜻은 아니다. <a href="https://arxiv.org/abs/1602.00763" target="_blank" rel="noopener">SORT 원 논문</a>에서 조건을 확인할 수 있다.

### IoU가 큰 연결을 선호하는 이유

IoU는 두 box가 덮는 영역 중 겹치는 부분의 비율이다. 위치뿐 아니라 box 크기의 일치도 함께 반영한다. **보충 예제:** 높이와 너비가 각각 10 pixel인 두 box가 수평으로만 2 pixel 어긋났다면 교집합은 $$8\times10=80\;\mathrm{pixel}^2$$, 합집합은 $$100+100-80=120\;\mathrm{pixel}^2$$다. IoU는 $$80/120=2/3$$이며 무차원이다.

최소화 문제에는 $$C_{ij}=1-\mathrm{IoU}_{ij}$$처럼 바꾼 비용을 사용할 수 있다. **IoU는 동일 객체일 확률이 아니라 box의 기하학적 겹침 비율**이다. 두 후보가 모두 겹치지 않으면 둘 다 0이어서 위치·겹침만으로는 우열을 가리기 어렵다.

<details markdown="block">
<summary markdown="span">Details: SORT state, assignment cost, and track management</summary>

SORT 원 논문은 각 객체의 상태를 다음 7차원 벡터로 둔다.

$$
\mathbf x=[u,v,s,r,\dot u,\dot v,\dot s]^\top.
$$

$$u,v$$는 box 중심의 영상 좌표, $$s$$는 면적, $$r$$은 가로세로 비다. 중심과 면적은 등속도 모델로 바꾸고 가로세로 비는 일정하다고 가정한다. 원래 SORT와 아래 DeepSORT의 상태 표현은 다르므로 같은 벡터라고 혼동하지 않는다.

IoU의 정의는 다음과 같다. 교집합과 합집합 면적 단위가 약분되어 값은 0–1이다.

$$
\mathrm{IoU}(B_i,D_j)
=\frac{\operatorname{area}(B_i\cap D_j)}{\operatorname{area}(B_i\cup D_j)}.
$$

선택하는 쌍의 수가 $$m$$으로 고정되어 있으면 $$\sum(1-\mathrm{IoU}_{ij})=m-\sum\mathrm{IoU}_{ij}$$다. 따라서 이 비용의 최소화는 IoU 합의 최대화와 같다. 하지만 **연결 거절과 미매칭을 허용할 때는 그 정책까지 명시**해야 하며, 비용 변환 자체가 모든 신규 객체·가림 문제를 해결하지는 않는다.

논문은 신규 track의 초기 속도를 0으로 두되 속도에 큰 불확실성을 부여하고, 일정한 검출 증거를 요구하는 확인 기간을 둔다. 논문 실험의 미검출 종료 설정은 $$T_{\mathrm{Lost}}=1$$ frame이다. 이는 단기 frame 연결과 속도에 집중한 원 실험 설정이며 모든 SORT 구현이 반드시 같은 수를 쓰는 규칙은 아니다. 오래 사라진 객체의 re-identification은 원래 SORT의 중심 목표가 아니다.

</details>

## 4. DeepSORT: 비슷한 위치에서 다시 나타나도 외형으로 구별하기

SORT가 위치와 box 겹침으로만 연결하면 가림 후 재등장하거나 두 사람이 교차할 때 ID가 바뀌기 쉽다. **DeepSORT는 외형을 비교하는 학습된 descriptor를 추가해 이 약점을 줄인다.** 위치 예측을 버리는 것이 아니라, 움직임과 외형이 서로 다른 근거를 제공하도록 한다.

<figure id="adc-13-p14">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p14.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p14.png" | relative_url }}" alt="두 객체 crop을 CNN 특징으로 바꾸어 외형 거리를 비교하며 자동차와 사람은 7.2 사람과 사람은 0.3으로 예시한 개념도" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=14" | relative_url }}">lecture PDF, p. 14</a>.</figcaption>
</figure>

그림은 **객체 crop → CNN feature vector → 두 vector의 거리** 순서로 읽는다. 위쪽은 서로 다른 외형, 아래쪽은 비슷한 외형을 비교한다. CNN 출력은 `person`이라는 class 번호가 아니라 같은 사람을 구별하는 데 사용할 표현이다. 파랑·빨강으로 그렸다고 서로 독립적으로 학습한 CNN을 각각 쓴다는 뜻도 아니다. Descriptor는 같은 feature 공간에서 비교되어야 한다.

**그림 수치의 범위:** 7.2와 0.3은 일반적인 “다른 외형은 멀고 비슷한 외형은 가깝다”는 개념 예시로 읽어야 한다. 실제 DeepSORT의 정규화된 descriptor에 대한 cosine distance는 0–2 범위이므로 **7.2를 그 cosine distance의 실제 결과로 해석할 수 없다.** 자동차·사람 예시 역시 보행자 re-identification으로 학습한 원 논문의 차량 추적 성능 실험을 뜻하지 않는다.

**서지 정정:** 14쪽의 `WACV 2018`과 달리 DeepSORT의 해당 논문은 **ICIP 2017**, *Simple Online and Realtime Tracking with a Deep Association Metric*이다. <a href="https://arxiv.org/abs/1703.07402" target="_blank" rel="noopener">저자 원고</a>는 appearance distance뿐 아니라 motion gating과 matching cascade를 함께 설명한다.

### 외형만 비슷하면 무조건 같은 객체인가?

아니다. 비슷한 옷을 입은 두 사람이 있을 수 있고, 같은 사람도 방향이나 가림에 따라 다르게 보인다. DeepSORT는 다음 역할을 분리한다.

- **Appearance distance:** 현재 crop이 해당 track의 과거 외형과 얼마나 비슷한가?
- **Motion gating:** 그 검출 위치가 예측 상태와 불확실성을 고려할 때 가능한가?
- **Matching cascade:** 최근에 관측된 track부터 배정해 오래 미관측된 track이 후보를 부당하게 가져가지 않게 한다.

**보충 수치 예제:** 정규화된 두 특징이 $$(1,0)$$과 $$(0.8,0.6)$$이면 내적은 0.8, cosine distance는 0.2다. $$(1,0)$$과 $$(0,1)$$은 distance가 1이다. 같은 척도에서는 0.2인 쌍을 더 비슷하게 보지만, 이것은 동일인 확률 80%라는 뜻은 아니다.

<details markdown="block">
<summary markdown="span">Details: Cosine distance, motion gating, and the matching cascade</summary>

DeepSORT는 정규화된 현재 descriptor $$\mathbf r_j$$와 track $$i$$의 과거 descriptor 집합 $$\mathcal R_i$$ 사이에서 가장 작은 cosine distance를 사용한다.

$$
d_{\mathrm{app}}(i,j)
=\min_{\mathbf r\in\mathcal R_i}(1-\mathbf r_j^\top\mathbf r),
\qquad \lVert\mathbf r_j\rVert_2=\lVert\mathbf r\rVert_2=1.
$$

Cauchy–Schwarz 부등식에서 내적은 $$-1\le\mathbf r_j^\top\mathbf r\le1$$이므로 distance는 0–2다. 그림의 7.2가 실제 cosine distance일 수 없는 이유다. 과거 외형 중 현재 관측과 잘 맞는 것을 찾으므로 여러 시점의 외형을 활용할 수 있지만, 잘못된 연결이 gallery에 들어가면 이후 판단에도 영향을 준다.

DeepSORT의 box 측정은 중심 좌표·가로세로 비·높이로 표현한다. Track의 예측을 측정 공간으로 투영한 평균 $$\mathbf y_i$$, 공분산 $$S_i$$와 현재 측정 $$\mathbf d_j$$로 다음 squared Mahalanobis distance를 계산한다.

$$
d_{\mathrm{motion}}(i,j)
=(\mathbf d_j-\mathbf y_i)^\top S_i^{-1}(\mathbf d_j-\mathbf y_i).
$$

같은 위치 차이도 불확실성이 작은 track에서는 큰 이탈, 큰 track에서는 상대적으로 작은 이탈로 평가한다. 공분산으로 정규화하므로 무차원이다. 원 논문은 4차원 측정에 대한 95% chi-square threshold 9.4877로 motion gate를 만들고, 외형에도 별도 threshold를 적용한다.

논문은 motion·appearance의 가중합 비용을 정의하지만, 실험에서는 appearance 쪽 가중치만 남기는 $$\lambda=0$$을 쓴다. **이때도 motion gate는 유지된다.** “외형 비용을 쓴다”와 “운동 정보를 전혀 쓰지 않는다”는 다르다.

미관측이 길어져 공분산이 커진 track은 같은 차이에 대해 Mahalanobis distance가 작아질 수 있다. 모든 track을 한꺼번에 경쟁시키면 이런 오래된 track이 최근의 확실한 track보다 유리해질 수 있다. Matching cascade는 마지막 관측 이후 지난 frame 수가 작은 track부터 처리하고, 남은 검출을 다음 단계에 넘긴다. 이후 미확인 track과 일부 최근 미매칭 track에는 SORT 방식의 IoU 연결을 추가로 수행한다.

</details>

### SORT에서 DeepSORT로 이어지는 변화

| Method | 해결하려는 문제 | 주요 수단 | 남는 조건과 확장 방향 |
|---|---|---|---|
| Kalman state estimation | 검출이 흔들리고 다음 위치가 필요함 | 운동 모델과 측정의 불확실성 결합 | 연결이 틀리거나 모델이 맞지 않으면 오차가 생겨 gating·모델 개선 필요 |
| SORT | 빠르고 단순한 online MOT | Kalman prediction, IoU, Hungarian 배정, track 관리 | 긴 가림 후 ID 회복이 어려워 appearance 등 추가 단서 필요 |
| DeepSORT | 위치·겹침만으로는 ID가 바뀜 | 학습된 appearance, motion gate, matching cascade | 외형의 유사성과 학습 도메인에 영향을 받아 데이터·특징·카메라 운동 대응 개선 필요 |

**Kalman은 추정기, SORT와 DeepSORT는 그 추정기를 포함한 추적 시스템**이다. 세 이름을 동일한 수준의 box 검출 알고리즘으로 비교하지 않는 것이 중요하다.

## 5. MOTA: 추적 결과에서 어떤 오류가 났는가?

16쪽의 MOTA(Multiple Object Tracking Accuracy)는 **놓친 정답, 불필요한 검출, 바뀐 ID**를 합쳐 정답 객체의 frame별 등장 횟수로 정규화한다. 이 단계에서는 평가용 GT(ground truth)와 tracker 출력을 대응시킨다. 앞의 tracking 배정은 정답을 모르는 실제 실행이고, 여기서는 정답 annotation을 가진 평가라는 차이가 있다.

<figure id="adc-13-p16">
  <a href="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p16.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-13-p16.png" | relative_url }}" alt="MOTA 수식과 6개 frame에서 GT 점선 및 빨강 파랑 track의 FN FP ID switch fragmentation을 비교하는 원본 예제" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>. Diagram cross-check: <a href="https://arxiv.org/abs/1603.00831" target="_blank" rel="noopener">MOT16, Figure 4</a>.</figcaption>
</figure>

$$
\mathrm{MOTA}
=1-\frac{\sum_t(FN_t+FP_t+IDSW_t)}{\sum_t GT_t}.
$$

| Symbol | Meaning | What is counted? |
|---|---|---|
| $$FN_t$$ | False negative | 정답 객체가 있지만 대응하는 tracker 출력이 없는 수 |
| $$FP_t$$ | False positive | 정답과 대응하지 않는 tracker 출력 수 |
| $$IDSW_t$$ | Identity switch | 같은 정답 객체에 연결된 tracker ID가 바뀐 횟수 |
| $$GT_t$$ | Ground-truth objects | 해당 frame의 정답 객체 수 |

분모는 고유 객체 ID의 개수가 아니다. **객체 한 개가 6개 frame에 계속 존재하면 총 GT는 6**이다. FN·FP·IDSW를 frame별로 모두 합하므로 분자에서도 세 항 전체에 합산을 적용한다. MOTA는 무차원이며 1이 가장 좋고, 오류합이 GT 등장 횟수보다 크면 음수가 될 수 있다. GT 합이 0이면 위 비율은 정의되지 않는다.

### 5.1 원본 그림에서 점을 중복 집계하지 않기

그림의 검은 점선은 정답 궤적, 빨강·파랑 실선은 서로 다른 tracker ID다. **빨강·파랑 속이 찬 점은 TP hypothesis이고, 검은 중심에 해당 색 테두리를 가진 점은 그 hypothesis에 연결된 GT 위치**다. 조금 떨어져 보이는 두 점은 하나의 올바른 매칭을 표현하므로, 각각 다른 검출이라고 두 번 세지 않는다. 속이 빈 빨강·파랑 점은 FP, 회색의 빈 점은 FN이다.

왼쪽은 frame 1에서 GT를 놓치고, frame 5에서 빨강 ID가 파랑 ID로 바뀐다. 오른쪽은 frame 3–4에서 추적이 끊겼다가 frame 5에 다른 ID로 재개된다. 원 도식의 범례와 MOT16의 association 규칙에 따라 센 **보충 계산**은 다음과 같다.

| Frame | Left FN | Left FP | Left IDSW | Right FN | Right FP | Right IDSW |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 1 | 0 | 0 | 0 | 0 |
| 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| 3 | 0 | 1 | 0 | 1 | 1 | 0 |
| 4 | 0 | 1 | 0 | 1 | 1 | 0 |
| 5 | 0 | 1 | 1 | 0 | 0 | 1 |
| 6 | 0 | 0 | 0 | 0 | 0 | 0 |
| Total | **1** | **4** | **1** | **2** | **2** | **1** |

두 예제 모두 $$\sum_t GT_t=6$$이다. 왼쪽은 $$1-(1+4+1)/6=0$$, 오른쪽은 $$1-(2+2+1)/6=1/6\approx0.167$$이다. **0이라는 값이 한 번도 검출하지 못했다는 뜻은 아니다.** 왼쪽도 5개 frame에서 GT와 매칭되지만, FP와 ID 변경까지 합친 오류가 분모 6과 같아서 최종 점수가 0이 된다.

오른쪽은 추적 중단 후 재개되는 **fragmentation도 1건**이다. 그러나 fragmentation은 MOTA 분자에 별도 항으로 더하지 않는다. ID switch와 fragmentation은 서로 다른 사건이며, 이 그림에서는 함께 발생한다.

<details markdown="block">
<summary markdown="span">Details: What MOTA measures and what it leaves out</summary>

MOTA는 “GT 등장 한 번당 오류가 얼마나 발생했는가”를 1에서 뺀 집계다. FN·FP·IDSW는 같은 실패를 여러 표현으로 반복한 것이 아니라 서로 다른 종류의 사건이다. 한 frame에서 실제 객체를 놓치는 동시에 다른 곳에 잘못된 box를 출력하면 FN과 FP가 함께 생길 수 있다.

ID switch를 어느 과거 대응과 비교하는지, 어느 겹침 threshold에서 GT와 출력을 매칭하는지는 benchmark의 평가 규약을 따라야 한다. 이 도식은 마지막으로 연결된 ID와 비교하므로, 오른쪽처럼 미검출 구간 뒤에 다른 ID로 돌아와도 switch가 생긴다. 단순히 “바로 이전 frame에 GT 매칭이 없으니 switch도 없다”라고 세면 안 된다.

MOTA 식에는 box의 위치 오차 크기나 fragmentation 수가 직접 들어 있지 않다. 잘못된 위치가 매칭 실패를 일으키면 FN·FP에 간접 반영되지만, 성공적으로 매칭된 두 box의 정밀한 위치 오차 차이를 이 식 하나로 비교할 수는 없다. 동일한 MOTA도 FN·FP·IDSW 구성은 다를 수 있으므로 각 오류 수와 위치·ID 관련 보완 지표를 함께 확인해야 한다.

</details>

## 핵심 정리

- **Kalman filter:** 예측과 검출을 불확실성에 따라 결합한다. 검출이 없으면 예측은 가능하지만 오차 누적과 track 수명 관리가 필요하다.
- **SORT:** Kalman prediction으로 box를 예상하고 IoU·Hungarian 배정으로 연결한다. Detector와 tracking component의 속도는 구분한다.
- **DeepSORT:** 외형 특징을 추가하되 motion gating과 matching cascade도 함께 사용한다. 외형 거리나 IoU를 동일 객체일 확률로 읽지 않는다.
- **MOTA:** FN·FP·IDSW의 합을 frame별 GT 등장 횟수로 정규화한다. Fragmentation은 별도 항이 아니며 MOTA만으로 추적의 모든 품질을 판단하지 않는다.

18쪽 요약은 위 세 축인 Kalman filter·SORT·tracking metric을 다시 묶는다. 19쪽의 다음 주제 `Prediction`은 track의 과거·현재 정보를 바탕으로 이후 움직임을 다루는 방향이다. **현재 frame의 관측을 연결하기 위한 Kalman의 한 단계 예측과, 장래 행동·궤적 예측이라는 후속 문제를 구분**해 읽는다.

## Study Guide

1. 9쪽의 prediction과 update를 “검출이 아직 없는 시점”과 “해당 ID에 검출을 연결한 시점”으로 나누어 설명한다.
2. 예측 110 pixel, 측정 114 pixel 예제에서 측정 분산을 9에서 1로 낮추면 보정값이 어느 쪽으로 이동하는지 먼저 예상한 뒤 계산한다.
3. 13쪽 파이프라인에서 Detector와 Prediction이 각각 무엇을 출력하며 Assignment 이후 어떤 track이 update되는지 짚는다.
4. 14쪽의 7.2를 실제 cosine distance로 읽을 수 없는 이유와, appearance만으로 해결되지 않는 경우를 설명한다.
5. 16쪽 범례를 먼저 읽고 왼쪽·오른쪽의 FN·FP·IDSW를 직접 집계한다. TP hypothesis와 매칭된 GT 점을 중복 계산하지 않는다.

## 복습 질문

<details markdown="block">
<summary markdown="span">Q1. Can the Kalman filter decide which person a detection belongs to?</summary>

답변: Kalman filter는 track의 상태를 예측하고 연결된 측정으로 보정한다. 누가 누구인지 고르는 data association은 별도 단계다. 예측과 공분산은 연결 후보를 평가하는 근거가 되지만, 잘못된 사람이 연결되면 filter도 잘못된 측정을 반영할 수 있다.

</details>

<details markdown="block">
<summary markdown="span">Q2. Does DeepSORT remove the motion model when appearance is used?</summary>

답변: 아니다. 원 논문의 실험에서는 association 비용을 appearance로 구성하더라도 motion gating을 유지한다. 위치상 불가능한 후보를 거절하고, 최근 관측된 track부터 cascade로 연결하며, 일부 남은 후보에는 IoU 연결도 수행한다.

</details>

<details markdown="block">
<summary markdown="span">Q3. Why can MOTA be zero even when most frames are matched?</summary>

답변: MOTA는 매칭 성공 비율만이 아니라 FN·FP·IDSW를 함께 센다. 원본 왼쪽 예제는 GT 6회 중 5회 매칭되지만 FN 1, FP 4, IDSW 1로 오류합도 6이어서 MOTA가 0이다.

</details>

## References

- Youngwook Kim, *Automatic Driving Computing — 13. Object Tracking (2)*, supplied lecture PDF, pp. 1–20.
- <a href="https://arxiv.org/abs/1602.00763" target="_blank" rel="noopener">Alex Bewley et al., Simple Online and Realtime Tracking</a>, ICIP 2016. <a href="https://doi.org/10.1109/ICIP.2016.7533003" target="_blank" rel="noopener">DOI</a>. Section 3의 상태·배정·track 관리, Section 4의 속도 조건을 대조했다.
- <a href="https://arxiv.org/abs/1703.07402" target="_blank" rel="noopener">Nicolai Wojke et al., Simple Online and Realtime Tracking with a Deep Association Metric</a>, ICIP 2017. <a href="https://doi.org/10.1109/ICIP.2017.8296962" target="_blank" rel="noopener">DOI</a>. Section 2의 appearance distance·motion gate·matching cascade를 대조했다.
- <a href="https://arxiv.org/abs/1603.00831" target="_blank" rel="noopener">Anton Milan et al., MOT16: A Benchmark for Multi-Object Tracking</a>, 2016. Figure 4의 범례와 평가 association 설명을 원본 16쪽 도식 계산에 사용했다.

## PDF

- [13 Object Tracking (2).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-13-object-tracking-02.pdf" | relative_url }})
