---
layout: default
date: 2026-11-02 23:40:00 +0900
title: "Lecture 14: Prediction I"
course: "Autonomous Driving"
topic: "Actor-Centric Rasterization and Uncertainty-Aware Motion Prediction"
order: 14
major_topic: "Autonomous Systems"
keywords:
  - "Motion Prediction"
  - "Trajectory Prediction"
  - "Rasterization"
  - "Actor-Centric Coordinates"
  - "Aleatoric Uncertainty"
  - "Half-Normal Distribution"
  - "LSTM"
---

# Lecture 14: Prediction I

Source PDF: [14 Prediction (1).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf" | relative_url }})

Tracking이 **지금까지 같은 객체였는지**를 연결한다면, prediction은 그 결과를 받아 **앞으로 어디로 움직일지**를 추정한다. 위치와 속도만 직선으로 연장하면 도로 구조, 주변 차량과의 상호작용, 여러 가능한 미래를 충분히 반영하기 어렵다. 이 강의는 주변 환경을 actor 중심의 raster image로 바꾸고, CNN이 짧은 미래 궤적과 그 오차 규모를 함께 예측하는 방법을 설명한다.

> **핵심:** 입력의 중심은 예측 대상 actor다. HD map과 주변 actor의 과거 위치를 같은 raster에 정렬하고, 미래의 각 시점마다 $$(x,y)$$를 예측한다. 불확실성을 사용할 때는 위치 두 값에 half-normal scale 하나를 더해 총 $$3H$$개 값을 출력한다.

## 전체 흐름

| PDF pages | Topic | 핵심 질문 |
|---|---|---|
| 1–9 | Prediction overview | Tracking 다음에 왜 미래 궤적이 필요한가? |
| 10–12 | Prediction challenges | 상호작용·도로 맥락·불확실성은 왜 어려운가? |
| 13–21 | Raster representation | Map과 actor history를 CNN 입력으로 어떻게 바꾸는가? |
| 22–25 | Training objectives | 위치 오차와 불확실성을 어떤 loss로 학습하는가? |
| 26–27 | Network architecture | CNN 특징과 actor state를 결합해 $$2H/3H$$를 어떻게 출력하는가? |
| 28–31 | Summary | Raster 방식이 해결하는 것과 남기는 한계는 무엇인가? |

페이지는 PDF의 1-based 쪽수다. 1·2·4·6·13·28·30·31쪽은 표지·구간 구분·예고·질문 화면이다. 원본 그림을 먼저 읽고, 계산 예제와 수식 유도는 보충 해설로 구분한다.

## 1. Prediction은 어떤 정보를 다음 단계에 넘기는가?

8쪽은 자율주행 기능의 큰 흐름에서 prediction의 위치를 보여 준다. Perception이 주변 객체를 찾고 tracking이 시간에 걸쳐 같은 객체를 연결하면, prediction은 각 actor의 미래 위치열을 만든다. Planning은 이 궤적을 참고해 충돌 가능성과 주행 선택지를 검토한다.

<figure id="adc-14-p08">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p08.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p08.png" | relative_url }}" alt="자율주행 기능 스택에서 perception 다음의 prediction이 주변 객체의 미래 궤적을 출력하는 강의 슬라이드" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=8" | relative_url }}">lecture PDF, p. 8</a>.</figcaption>
</figure>

9쪽의 문제를 기호로 쓰면, 현재 시점 $$t_j$$까지의 actor state와 map을 보고 대상 actor $$i$$의 다음 $$H$$개 위치를 구하는 일이다.

$$
\bigl[(x_{i(j+1)},y_{i(j+1)}),\ldots,
(x_{i(j+H)},y_{i(j+H)})\bigr]
$$

$$H$$는 **prediction horizon의 time-step 수**다. 원 논문의 실험은 10 Hz 데이터에서 3 s를 예측하므로 $$H=30$$이다. 즉, “3초 뒤 위치 하나”가 아니라 0.1 s 간격의 미래 위치 30개를 출력한다.

강의는 perception·detection·tracking이 완료되었다고 가정하고 prediction을 설명한다. 이는 모듈을 나누어 배우기 위한 **입력 조건**이다. 실제 시스템에서 검출 위치나 ID 연결이 틀리면 raster와 actor state도 틀어지므로, prediction이 upstream 오차와 독립적인 것은 아니다.

## 2. 미래 궤적 예측이 어려운 세 가지 이유

### 2.1 Actor interaction

10쪽의 첫 문제는 주변 actor의 움직임이다. 앞차가 감속하면 뒤차도 속도를 줄일 수 있고, 합류 차량이 들어오면 원래의 직진 경로가 달라질 수 있다. 따라서 대상 actor의 과거 위치만 외삽하는 모델보다 **누가 주변 어느 위치에 있는지**를 함께 표현해야 한다.

슬라이드는 perception과 prediction의 차이를 강조하기 위해 perception이 객체를 개별적으로 처리한다고 단순화한다. 하지만 모든 perception 모델이 상호작용을 무시한다는 일반 명제는 아니다. 여기서 확인할 핵심은 **prediction의 출력이 주변 actor의 조건에 따라 달라져야 한다는 점**이다.

### 2.2 Road context

11쪽의 차선, 교차로, 횡단보도는 가능한 이동 방향을 제한한다. 같은 속도와 heading을 가진 차량도 직선 차로와 회전 차로에서는 다른 미래가 자연스럽다. Map은 단순한 배경 그림이 아니라 **drivable area, lane direction, boundary, crosswalk** 같은 구조를 제공한다.

강의 모델은 미리 구축된 HD map을 입력으로 사용한다. 이 설계는 해당 논문의 조건이며, 모든 자율주행 시스템이 항상 같은 map 구성이나 사전 구축 방식만 사용한다는 뜻은 아니다.

### 2.3 Future uncertainty

12쪽은 한 장면에서 여러 미래가 가능하다는 문제를 제시한다. 교차로에 접근한 차량은 직진·좌회전·우회전 중 하나를 선택할 수 있다. 이 강의에서 다루는 WACV 2020 모델은 **대표 궤적 하나와 시간별 오차 규모**를 예측한다. 서로 분리된 여러 경로를 직접 출력하는 multimodal predictor는 아니다.

따라서 예측 scale이 커졌다는 사실은 “이 조건의 displacement error가 클 수 있다”는 신호로 읽을 수 있지만, 그것만으로 좌회전과 직진이라는 별도 모드를 복원하거나 안전을 보장하지는 않는다.

## 3. Actor-centric raster: 주변 맥락을 한 장의 입력으로 만들기

15쪽이 소개하는 논문은 Djuric et al.의 **Uncertainty-aware Short-term Motion Prediction of Traffic Actors for Autonomous Driving**다. 문제의식은 사람이 직접 lane distance, 앞차와의 간격 같은 feature를 모두 설계하는 대신, map과 actor 상태를 raster로 만들고 CNN이 유용한 공간 특징을 학습하게 하는 것이다.

### 3.1 Vector layer에서 RGB raster로

18쪽은 HD map의 선·polygon과 tracking 결과를 2D image로 바꾸는 과정을 보여 준다. Raster 방식에서는 공간을 일정한 크기의 pixel 격자로 양자화한다. CNN은 그 격자에서 차선 방향, 도로 영역, 주변 actor 배치를 함께 읽는다.

<figure id="adc-14-p18">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p18.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p18.png" | relative_url }}" alt="노란 대상 차량 주변의 vector map과 actor 정보를 raster image로 바꾸어 CNN 입력으로 사용하는 강의 그림" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=18" | relative_url }}">lecture PDF, p. 18</a>.</figcaption>
</figure>

원 논문은 각 layer에 구별되는 RGB 색을 지정한다. Lane direction은 고정 색 하나가 아니라 선분의 방향각을 HSV의 hue로 바꾼 뒤 RGB로 변환한다. 반대 방향 차선은 color wheel에서도 반대쪽 hue가 되므로, 방향 차이를 영상 channel 안에 넣을 수 있다.

### 3.2 좌표계를 actor에 고정하는 이유

19쪽의 raster는 $$300\times300$$ pixel이고 해상도는 0.1 m/pixel이다. 전체 한 변은 30 m다. 이미지를 대상 actor의 heading이 위쪽을 향하도록 회전하면, 장면마다 전역 방위가 달라도 모델 관점에서는 **앞·뒤·왼쪽·오른쪽의 의미가 일정**해진다.

<figure id="adc-14-p19">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p19.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p19.png" | relative_url }}" alt="300 곱하기 300 raster와 0.1미터 해상도, 대상 차량의 위치와 heading 정렬을 설명하는 강의 슬라이드" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=19" | relative_url }}">lecture PDF, p. 19</a>. The coordinate conventions are reconciled below using the primary paper.</figcaption>
</figure>

**좌표 convention 확인:** 19쪽은 대상 actor를 $$(250,150)$$으로 적지만 tuple의 축과 원점을 명시하지 않는다. WACV 원 논문은 **왼쪽 아래 기준 $$(w,h)=(150,50)$$**이라고 정의한다. 300×300 영상을 왼쪽 위 기준의 array $$(row,column)$$로 바꾸면 $$row=300-50=250$$, $$column=150$$이므로 슬라이드의 $$(250,150)$$과 정확히 대응한다. 따라서 오기로 단정하지 않고, **슬라이드는 top-left row–column, 논문은 bottom-left width–height를 썼을 가능성**으로 읽는다.

논문 기준 배치에서는 actor 앞쪽 25 m, 뒤쪽 5 m가 raster에 들어간다. 300 pixel × 0.1 m/pixel = 30 m이므로 $$25+5=30$$ m와도 일치한다.

Raster pixel과 예측 좌표도 구분해야 한다.

- **Raster pixel:** 왼쪽 아래 기준의 $$(w,h)$$이며 입력 이미지를 그릴 때 사용한다.
- **예측 좌표:** actor bounding-box 중심을 원점으로 하고, 진행 방향이 $$x$$축, 왼쪽이 $$y$$축인 metric coordinate다.

따라서 $$(150,50)$$ pixel은 예측 위치 $$(x,y)=(150,50)$$ m를 뜻하지 않는다. 학습 목표는 actor 중심의 meter 좌표다.

### 3.3 Map layer와 tracking history

20쪽은 road, sidewalk, crosswalk, lane direction을 서로 다른 표현으로 겹친다. 넓은 polygon부터 lane과 actor box 같은 미세 구조 순서로 그려야 작은 요소가 가려지지 않는다.

21쪽은 대상 actor를 빨간색, 다른 actor를 노란색 box로 표현하고 과거 box를 더 어둡게 그린다. 이 **fading effect**는 한 장의 raster에도 이동 방향과 대략적인 속도 단서가 남게 한다.

<figure id="adc-14-p21">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p21.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p21.png" | relative_url }}" alt="대상 actor를 빨간색, 주변 actor를 노란색으로 그리고 과거 위치의 밝기를 낮춘 raster history 예시" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=21" | relative_url }}">lecture PDF, p. 21</a>.</figcaption>
</figure>

원 논문의 과거 $$k$$번째 box 밝기는 다음 규칙을 사용한다.

$$
b_k=\max(0,1-k\delta),\qquad \delta=0.1
$$

예를 들어 현재가 $$k=0$$이면 밝기 1.0, 3 step 전이면 0.7이다. 논문은 history 길이 $$K=1$$인 no-fading 입력과 $$K=5$$인 fading 입력을 비교한다. 밝기는 시간 정보를 담는 **인코딩 규칙**이지, actor가 실제로 어두워졌다는 뜻이 아니다.

## 4. 위치 오차: 어디까지 빗나갔는가?

22쪽은 horizon $$h$$에서 정답과 예측 위치 사이의 Euclidean distance를 정의한다.

<figure id="adc-14-p22">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p22.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p22.png" | relative_url }}" alt="정답 위치와 예측 위치의 x y 차이로 Euclidean displacement error를 정의하는 강의 수식" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=22" | relative_url }}">lecture PDF, p. 22</a>.</figcaption>
</figure>

$$
d_{i(j+h)}=
\sqrt{
\left(x_{i(j+h)}-\hat x_{i(j+h)}\right)^2+
\left(y_{i(j+h)}-\hat y_{i(j+h)}\right)^2
}
$$

$$i$$는 actor, $$j$$는 현재 time step, $$h$$는 몇 step 뒤인지를 나타낸다. 좌표가 meter이면 $$d$$도 meter다. 이 값은 방향을 버리고 **위치가 떨어진 거리**만 나타낸다.

23쪽의 point-estimate loss는 horizon 전체의 squared displacement를 평균한다.

$$
L_{ij}=\frac1H\sum_{h=1}^{H}d_{i(j+h)}^2
$$

### 수치 예제: 세 미래 지점의 loss

세 시점에서 $$(\Delta x,\Delta y)$$가 각각 $$(0.3,-0.4)$$, $$(-0.8,0.6)$$, $$(0.5,-0.5)$$ m라고 하자.

| Horizon step | $$d^2=(\Delta x)^2+(\Delta y)^2$$ | $$d$$ |
|---:|---:|---:|
| 1 | 0.25 m² | 0.50 m |
| 2 | 1.00 m² | 1.00 m |
| 3 | 0.50 m² | 0.707 m |

$$
L=\frac{0.25+1.00+0.50}{3}
=0.583\;\mathrm{m^2}
$$

Loss의 단위는 m²다. 이해를 위해 제곱근을 취하면 root mean squared displacement는 약 0.764 m지만, **슬라이드의 학습 loss 자체는 제곱근을 취하지 않는다.** 또한 이 값은 각 시점 거리의 산술평균인 ADE와도 다르다.

<details markdown="block">
<summary markdown="span">Derivation: Why does squared displacement become coordinate MSE?</summary>

Euclidean displacement를 제곱하면 제곱근이 사라진다.

$$
d_h^2=(x_h-\hat x_h)^2+(y_h-\hat y_h)^2
$$

이를 horizon 전체에 평균하면

$$
L=\frac1H\sum_{h=1}^{H}(x_h-\hat x_h)^2
+\frac1H\sum_{h=1}^{H}(y_h-\hat y_h)^2
$$

가 된다. 즉, $$x$$와 $$y$$ 좌표의 squared error를 합한 형태다. 큰 위치 오차는 제곱 때문에 더 큰 비용을 받는다. 반대로 outlier가 많은 데이터에서는 큰 오차에 민감하다는 특징도 생긴다.

</details>

## 5. Point estimate에서 uncertainty-aware prediction으로

24쪽은 평균 위치만 예측하는 point estimate와 uncertainty까지 예측하는 경우를 구분한다.

<figure id="adc-14-p24">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p24.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p24.png" | relative_url }}" alt="미래 예측에서 평균만 내는 point estimate와 평균 및 scale을 내는 uncertainty-aware estimate를 대비한 슬라이드" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=24" | relative_url }}">lecture PDF, p. 24</a>.</figcaption>
</figure>

**기호 정정:** 논문은 $$\sigma$$를 standard deviation이라고 부르지만, 아래 half-normal density에서는 **underlying zero-mean normal의 standard deviation이자 half-normal의 scale parameter**다. 따라서 $$\sigma^2$$는 underlying normal의 variance이고, 관측되는 $$d$$ 자체의 표준편차는 $$\sigma\sqrt{1-2/\pi}$$, 분산은 $$\sigma^2(1-2/\pi)$$다. 단위는 $$\sigma$$가 m, $$\sigma^2$$가 m²다. 24쪽의 “표준편차 혹은 분산 $$(\sigma)$$”처럼 두 개념을 같은 기호로 부르면 안 된다.

원 논문은 음수가 아닌 displacement magnitude가 half-normal distribution을 따른다고 가정한다.

$$
d_{i(j+h)}\sim
\mathrm{HalfNormal}\left(0,\hat\sigma_{i(j+h)}^2\right)
$$

그 음의 로그우도를 정리하면 25쪽의 loss가 된다. 분포의 정규화 상수처럼 모델 최적화에 영향을 주지 않는 상수항은 생략되어 있다.

<figure id="adc-14-p25">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p25.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p25.png" | relative_url }}" alt="예측 displacement와 sigma로 구성된 half-normal negative log likelihood loss를 설명하는 강의 슬라이드" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=25" | relative_url }}">lecture PDF, p. 25</a>.</figcaption>
</figure>

$$
L_{ij}=\sum_{h=1}^{H}
\left(
\frac{d_{i(j+h)}^2}{2\hat\sigma_{i(j+h)}^2}
+\log\hat\sigma_{i(j+h)}
\right)
$$

두 항은 서로 반대 방향으로 작동한다.

- $$d^2/(2\hat\sigma^2)$$: 같은 오차라면 큰 $$\hat\sigma$$가 비용을 줄인다.
- $$\log\hat\sigma$$: 무조건 $$\hat\sigma$$를 크게 내는 방법에 비용을 부과한다.

### 수치 예제: 오차가 1 m일 때

$$d=1$$ m인 한 horizon step만 보자.

| Predicted $$\hat\sigma$$ | Residual term | Log term | Sum |
|---:|---:|---:|---:|
| 0.5 m | 2.000 | −0.693 | 1.307 |
| 1.0 m | 0.500 | 0.000 | 0.500 |
| 2.0 m | 0.125 | 0.693 | 0.818 |

$$\hat\sigma=0.5$$ m는 실제 1 m 오차에 비해 지나치게 자신 있어서 residual term이 크다. $$\hat\sigma=2$$ m는 residual을 약하게 만들지만 log penalty가 커진다. 이 단일 관측 식에서는 두 효과가 $$\hat\sigma=d$$에서 균형을 이룬다.

이 결과를 “예측 위치에서 반경 $$\sigma$$ 안에 반드시 실제 위치가 있다”로 읽으면 안 된다. 학습된 scale이 실제 빈도와 맞는지는 별도의 calibration 평가가 필요하고, 이 모델의 단일 scale은 서로 떨어진 여러 미래 경로를 직접 표현하지 않는다.

<details markdown="block">
<summary markdown="span">Derivation: From the half-normal density to the loss</summary>

평균 0인 Gaussian 변수의 절댓값 $$d\ge0$$는 half-normal distribution을 따른다. Scale을 $$\sigma>0$$라 하면 density는

$$
p(d\mid\sigma)=
\frac{\sqrt{2}}{\sigma\sqrt{\pi}}
\exp\left(-\frac{d^2}{2\sigma^2}\right),
\qquad d\ge0
$$

이다. 음의 로그를 취하면

$$
-\log p(d\mid\sigma)
=\frac{d^2}{2\sigma^2}+\log\sigma
+\frac12\log\frac{\pi}{2}
$$

가 된다. 마지막 항은 $$d$$와 $$\sigma$$에 무관한 상수이므로 최적화 식에서 생략할 수 있다. 각 horizon의 조건부 오차를 더하면 25쪽 식을 얻는다.

이 유도는 **2차원 위치 자체에 isotropic Gaussian density를 둔 식**이 아니라, 논문처럼 **2차원 위치에서 계산한 nonnegative displacement magnitude에 half-normal을 둔 식**이다. 2차원 Gaussian NLL이라면 정규화 항의 계수가 달라질 수 있으므로 혼동하지 않는다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Why does the loss not let sigma grow without limit?</summary>

한 시점의 상수항을 제외한 loss를

$$
\ell(\sigma)=\frac{d^2}{2\sigma^2}+\log\sigma
$$

라고 하자. $$d>0$$에서 미분하면

$$
\ell'(\sigma)=-\frac{d^2}{\sigma^3}+\frac1\sigma
=\frac{\sigma^2-d^2}{\sigma^3}
$$

다. $$\sigma>0$$이므로 $$\ell'(\sigma)=0$$은 $$\sigma=d$$에서 성립한다. $$0<\sigma<d$$에서는 미분값이 음수이고 $$\sigma>d$$에서는 양수이므로 이 지점이 최솟값이다.

$$d=0$$이면 이상적인 식의 최솟값은 $$\sigma\to0$$ 쪽으로 가므로, 실제 구현은 양의 scale을 보장하고 수치적으로 0을 피하도록 parameterization과 안정화가 필요하다. 강의 슬라이드만으로 구체 구현의 lower bound를 확정할 수는 없다.

</details>

## 6. Architecture: raster와 actor state를 어떻게 합치는가?

26쪽의 feed-forward 모델은 두 입력을 결합한다.

<figure id="adc-14-p26">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p26.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p26.png" | relative_url }}" alt="300 곱하기 300 곱하기 3 raster를 CNN으로 처리하고 3차원 actor state와 결합해 2H 또는 3H를 출력하는 구조" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=26" | relative_url }}">lecture PDF, p. 26</a>.</figcaption>
</figure>

1. $$300\times300\times3$$ raster를 base CNN에 넣고 flatten한다.
2. 대상 actor의 **velocity, acceleration, heading-change rate**를 3차원 state vector로 만든다.
3. Raster feature와 state feature를 concatenate한다.
4. 4096차원 fully connected layer를 거쳐 horizon 전체 출력을 만든다.

Position과 heading 자체가 state vector에 없는 이유는 정보가 필요 없어서가 아니다. Raster를 만들 때 이미 actor position을 기준점으로 잡고 heading을 위쪽으로 정렬했기 때문에 **좌표 정규화 과정에 사용된 정보**다.

### 2H와 3H가 뜻하는 것

| Model output | Per horizon step | Total size |
|---|---|---:|
| Point prediction | $$\hat x_h,\hat y_h$$ | $$2H$$ |
| Uncertainty-aware | $$\hat x_h,\hat y_h,\hat\sigma_h$$ | $$3H$$ |

논문의 $$H=30$$ 예에서는 각각 60개와 90개 값이다. $$3H$$는 $$x,y,z$$의 3D 위치가 아니라, 2D 위치 두 값과 displacement scale 한 값이다.

### FC와 LSTM 출력의 차이

27쪽은 두 decoder를 비교한다. FC는 horizon 전체 vector를 한 번에 출력한다. LSTM은 128차원 hidden/cell state를 사용하고 각 미래 step마다 2개 또는 3개 값을 순서대로 출력한다.

<figure id="adc-14-p27">
  <a href="{{ "/assets/images/study/autonomous-driving/lecture-14-p27.png" | relative_url }}"><img src="{{ "/assets/images/study/autonomous-driving/lecture-14-p27.png" | relative_url }}" alt="Fully connected decoder가 전체 horizon을 한 번에 출력하고 LSTM decoder가 시점별로 2개 또는 3개 값을 출력하는 비교 그림" loading="lazy"></a>
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf#page=27" | relative_url }}">lecture PDF, p. 27</a>.</figcaption>
</figure>

- **FC output:** 하나의 feature에서 $$[x_1,y_1,\ldots,x_H,y_H]$$를 병렬로 낸다.
- **LSTM output:** 이전 hidden/cell state를 다음 미래 step으로 전달해 순차 의존성을 표현한다.

LSTM이 시간 구조를 명시적으로 갖는다는 사실과, 어떤 데이터에서도 항상 FC보다 우수하다는 주장은 다르다. 이 논문의 실험에서는 MobileNet-v2 + LSTM이 비교 모델 중 가장 낮은 평균 displacement error를 보였지만, architecture 선택은 데이터·지연시간·학습 조건과 함께 판단해야 한다.

## 7. 이 방법이 해결하는 것과 남기는 것

### 해결하는 부분

- Actor를 기준으로 회전·정렬해 장면마다 같은 방향 의미를 만든다.
- HD map, 주변 actor, actor history를 하나의 CNN 입력에 합친다.
- Horizon 전체 궤적을 예측한다.
- 시점별 displacement scale을 학습해 관측 오차가 모두 같다고 가정하지 않는다.
- Raster feature와 수치 state를 함께 사용한다.

### 남는 한계와 확장 방향

- **Raster quantization:** 0.1 m/pixel 격자는 세부 geometry를 이산화한다. 다음 강의의 vector representation은 선과 polygon 구조를 직접 다루는 방향으로 이어진다.
- **Fixed context:** 25 m 앞, 5 m 뒤는 원 논문의 저속 도로 조건에서 선택한 값이다. 더 빠른 도로에는 더 넓은 문맥이나 다른 해상도가 필요하다.
- **Unimodal future:** 평균 궤적 하나와 scale 하나로 좌·직진·우회전처럼 떨어진 여러 모드를 완전히 표현할 수 없다. Multi-hypothesis 또는 distributional trajectory model이 확장 방향이다.
- **Upstream dependency:** 잘못된 map, detection, tracking ID는 입력 자체를 바꾼다. Prediction loss만 낮추는 것으로 전체 pipeline의 오류를 제거할 수 없다.
- **Calibration:** Scale을 출력한다는 사실만으로 신뢰구간이 정확해지지 않는다. 실제 error frequency와 predicted scale의 일치 여부를 별도로 평가해야 한다.

## 마지막 핵심 정리

1. Prediction은 tracking 결과를 받아 미래 $$H$$개 actor 위치를 예측한다.
2. Actor-centric 좌표는 진행 방향 $$x$$, 왼쪽 $$y$$, actor 중심 원점이다.
3. Raster는 map layer, 현재·과거 actor box, lane direction을 CNN 입력으로 결합한다.
4. 원 논문의 raster actor pixel은 왼쪽 아래 기준 $$(w,h)=(150,50)$$이다. 이는 왼쪽 위 기준 $$(row,column)=(250,150)$$과 동치다.
5. Point loss는 horizon 평균 squared displacement다.
6. $$\sigma$$는 half-normal scale이다. Half-normal 변수 $$d$$의 분산은 $$\sigma^2$$가 아니라 $$\sigma^2(1-2/\pi)$$다.
7. Uncertainty loss의 $$d^2/(2\sigma^2)$$와 $$\log\sigma$$는 각각 residual weighting과 scale penalty 역할을 한다.
8. $$2H$$는 horizon별 $$(x,y)$$, $$3H$$는 $$(x,y,\sigma)$$다.
9. FC는 horizon 전체를 한 번에, LSTM은 미래 step을 순차적으로 decode한다.

## Study Guide

| 다시 볼 부분 | 확인할 내용 |
|---|---|
| pp. 8–12 | Tracking 출력, interaction, road context, future uncertainty의 관계 |
| pp. 18–21 | Actor-centric raster의 원점·방향·해상도와 fading history |
| pp. 22–25 | Displacement, point loss, half-normal scale loss의 단위와 차이 |
| pp. 26–27 | State vector, $$2H/3H$$ 출력, FC/LSTM decoder 차이 |

공식을 외우기 전에 **입력 raster → trajectory output → loss** 순서로 연결한다. 그다음 $$d$$와 $$\sigma$$의 단위, 좌표 convention, output dimension을 수치 예제로 확인한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. Raster를 대상 actor의 heading에 맞춰 회전하는 이유는 무엇인가?</summary>

답변: 전역 방위가 달라도 모델이 보는 앞·뒤·왼쪽·오른쪽의 의미를 일정하게 만들기 위해서다. 이 정렬은 서로 다른 장면의 공간 패턴을 actor 기준으로 비교할 수 있게 한다.

</details>

<details markdown="block">
<summary markdown="span">2. 300×300 raster에서 $$(250,150)$$과 $$(150,50)$$이 동시에 나타날 수 있는 이유는 무엇인가?</summary>

답변: 좌표 convention이 다르기 때문이다. 왼쪽 아래 기준 $$(w,h)=(150,50)$$을 왼쪽 위 기준 array $$(row,column)$$로 바꾸면 $$(300-50,150)=(250,150)$$이다.

</details>

<details markdown="block">
<summary markdown="span">3. Point model과 uncertainty-aware model의 출력 크기는 왜 각각 $$2H$$와 $$3H$$인가?</summary>

답변: 각 미래 step에서 point model은 $$(x,y)$$ 두 값을 출력한다. Uncertainty-aware model은 여기에 displacement error의 half-normal scale $$\sigma$$ 하나를 더하므로 step당 세 값이다.

</details>

<details markdown="block">
<summary markdown="span">4. $$d^2/(2\sigma^2)$$만 사용하지 않고 $$\log\sigma$$를 더하는 이유는 무엇인가?</summary>

답변: 첫 항만 있으면 모델이 $$\sigma$$를 크게 만들어 residual 비용을 계속 줄일 수 있다. $$\log\sigma$$는 큰 scale에 비용을 부과해 residual 설명과 scale 크기 사이의 균형을 만든다.

</details>

<details markdown="block">
<summary markdown="span">5. 예측 scale 하나가 여러 가능한 미래 경로를 모두 표현하지 못하는 이유는 무엇인가?</summary>

답변: Scale은 대표 궤적 주변의 오차 크기를 나타내지만, 좌회전·직진처럼 서로 떨어진 별도 궤적과 각 확률을 직접 출력하지 않는다. 그런 경우에는 multi-hypothesis 또는 multimodal distribution이 필요하다.

</details>

## References

- <a href="https://openaccess.thecvf.com/content_WACV_2020/html/Djuric_Uncertainty-aware_Short-term_Motion_Prediction_of_Traffic_Actors_for_Autonomous_Driving_WACV_2020_paper.html" target="_blank" rel="noopener">Djuric et al., “Uncertainty-aware Short-term Motion Prediction of Traffic Actors for Autonomous Driving,” WACV 2020 (CVF Open Access)</a>

## PDF

[Open the original lecture PDF]({{ "/assets/pdfs/study/autonomous-driving/lecture-14-prediction-01.pdf" | relative_url }})
