---
layout: default
date: 2026-09-03 10:45:36 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
title: "Lecture 2: Sensors for Autonomous Driving"
course: "Autonomous Driving"
topic: "Camera, LiDAR, RADAR, and Sensor-Stack Trade-offs"
order: 2
major_topic: "Autonomous Systems"
keywords:
  - "Camera"
  - "LiDAR"
  - "RADAR"
  - "Sensor Fusion"
  - "Perception"
---

# Lecture 2: Sensors for Autonomous Driving

Source PDF: `02-sensors.pdf`

이 글은 국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 2강 자료를 바탕으로, 자율주행 센서가 perception의 입력을 만드는 과정과 camera·LiDAR·RADAR의 상호보완 관계를 복습하기 좋게 재구성한 노트다.

강의 슬라이드가 직접 제시한 개념·수치·사례를 중심에 두고, 실제 구현에서 필요한 calibration, synchronization, failure condition과 system safety 관점은 **작성자 보충**으로 구분해 공식 기술 자료를 함께 연결한다.

> **핵심:** 자율주행 센서 선택의 목적은 가장 뛰어난 센서 하나를 고르는 것이 아니다. 운행 환경에서 필요한 색·형태·거리·속도 정보를 안정적으로 확보하고, 서로 다른 실패 조건을 가진 센서를 조합해 perception의 신뢰도를 높이는 것이 핵심이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 센서의 역할 | 센서 정보는 자율주행 stack의 어디에서 사용되는가? |
| 2 | Camera | RGB 영상은 어떻게 만들어지며 무엇을 잘 인식하는가? |
| 3 | Stereo camera | 두 영상의 차이로 깊이를 어떻게 추정하는가? |
| 4 | LiDAR | 레이저 왕복 시간은 어떻게 3D point cloud가 되는가? |
| 5 | BEV | 3D 측정값을 위에서 본 공간 표현으로 바꾸는 이유는 무엇인가? |
| 6 | RADAR | 전파와 Doppler effect로 거리와 속도를 어떻게 얻는가? |
| 7 | 센서 비교 | 해상도, 깊이, 속도, 날씨, 비용의 trade-off는 무엇인가? |
| 8 | 차량 사례 | Waymo·Zoox·Tesla의 센서 구성은 어떤 설계 철학을 보여주는가? |

## 1. 센서는 자율주행차의 눈이다

운전자는 시각을 중심으로 도로의 차선, 신호, 차량, 보행자와 장애물을 파악한다. 강의 자료는 사람이 받아들이는 정보에서 시각이 83%로 가장 큰 비중을 차지하고, 청각 11%, 후각 3%, 촉각 2%, 미각 1%가 뒤따른다고 제시한다. 이 수치의 핵심은 정확한 감각 비율 자체보다 **주행 판단이 외부 환경을 관측하는 능력에 크게 의존한다**는 점이다.

자율주행차에는 사람의 눈을 대신하는 하나의 센서가 없다. 각 센서는 물리적으로 다른 신호를 관측한다.

| 센서 | 직접 관측하는 신호 | 주로 얻는 정보 |
|---|---|---|
| Camera | 가시광선이 만든 2D 영상 | 색, 질감, 형태, 문자, 차선과 신호 의미 |
| LiDAR | 레이저의 반사와 왕복 시간 | 3D 위치, 거리, 표면 형상 |
| RADAR | 전파의 반사와 주파수 변화 | 거리, 방위, 상대적인 방사 속도 |

강의의 autonomy stack은 다음 흐름으로 정리된다.

```text
Maps + Sensors
      -> Perception (detections, tracks)
      -> Prediction (long-term predictions)
      -> Planning (motion trajectory)
      -> Control (steering, acceleration)
```

센서의 측정값은 perception에서 객체와 주행 공간으로 해석되고, 그 결과가 prediction과 planning을 거쳐 steering·acceleration 명령으로 이어진다. 따라서 센서는 단순한 주변 장치가 아니라, 뒤 단계가 현실을 이해할 수 있게 만드는 **전체 stack의 관측 기반**이다.

## 2. Camera: 빛을 디지털 영상으로 바꾸기

### 2.1 영상이 만들어지는 과정

강의 자료의 camera 설명은 두 단계에서 시작한다.

1. 광자(photon)가 광원에서 출발해 물체 표면에서 반사된다.
2. 반사된 빛이 lens를 통과하고, 격자 형태의 color filter array와 image sensor에 도달한다.

센서의 각 pixel은 들어온 빛의 세기를 전기 신호로 바꾼다. 일반적인 color filter array는 한 pixel이 red·green·blue 가운데 일부 파장에 더 민감하도록 구성되며, 주변 pixel의 측정값을 함께 사용해 RGB 영상을 복원한다.

강의에서 함께 제시한 빛의 삼원색은 **가산 혼합(additive color mixing)** 관점이다.

| 결합 | 결과 색 |
|---|---|
| Red + Green | Yellow |
| Green + Blue | Cyan |
| Blue + Red | Magenta |
| Red + Green + Blue | White |

이 RGB 정보 덕분에 camera는 신호등 색, 차선 색, 표지판 문자처럼 geometry만으로 구분하기 어려운 semantic cue를 풍부하게 제공한다.

### 2.2 Camera의 강점

- **높은 영상 해상도:** 물체 경계, 차선, 작은 표지와 문자 같은 세부 정보를 관측하기 좋다.
- **색과 질감:** 신호 상태와 표지판 종류처럼 의미 인식에 필요한 정보를 제공한다.
- **학습 데이터와의 궁합:** object detection, semantic segmentation, lane detection 등 computer vision 모델의 직접 입력으로 사용할 수 있다.

### 2.3 Camera의 제약

- 한 대의 camera는 lens와 설치 방향이 정한 field of view 밖을 볼 수 없다.
- monocular image의 각 pixel은 본질적으로 2D 투영 결과이므로, metric depth를 직접 측정하지 않는다.
- 안개, 비, 역광, 눈부심과 렌즈 오염 같은 외부 조건이 영상 품질에 영향을 준다.
- 야간에는 가용 광량이 줄어 noise와 motion blur가 커질 수 있다.

> **작성자 보충:** 강의 슬라이드는 야간 정보 취득이 불가능하다고 단순화하지만, 실제 camera는 low-light sensor, HDR, 조명 또는 infrared 보조를 통해 야간에도 정보를 얻을 수 있다. 다만 **주간과 같은 품질이 자동으로 보장되는 것은 아니다**라는 점이 중요하다.

## 3. Stereo camera: 두 시점으로 깊이 추정하기

Stereo camera는 간격을 두고 배치한 두 대 이상의 camera로 같은 장면을 촬영한다. 가까운 물체일수록 왼쪽과 오른쪽 영상에서 위치 차이, 즉 disparity가 크게 나타나고 먼 물체일수록 작게 나타난다.

평행한 두 camera를 단순화하면 깊이 $$Z$$는 다음 관계로 설명할 수 있다.

$$
Z = \frac{fB}{d}
$$

- $$f$$: camera focal length
- $$B$$: 두 camera 사이의 baseline
- $$d$$: 같은 점이 좌우 영상에서 이동한 disparity

| 기호 | 명칭 | 단위 | 주의 |
|---|---|---|---|
| $$Z$$ | Optical axis 방향 depth | $$B$$와 같은 길이 단위, 보통 $$\mathrm{m}$$ | rectified pinhole-camera model의 값 |
| $$f$$ | Focal length | pixel | image coordinate로 계산할 때 pixel 단위를 사용 |
| $$B$$ | Stereo baseline | $$\mathrm{m}$$ | 두 optical center 사이 거리 |
| $$d=x_L-x_R$$ | Horizontal disparity | pixel | rectification 뒤 대응점의 horizontal coordinate 차이 |

### 3.1 작성자 보충: $$Z=fB/d$$의 기하학적 유도

이 식은 **평행 optical axis, 동일한 focal length, rectified image, pinhole projection**을 가정한 정확한 기하 관계다. 왼쪽 camera를 원점에 두고 3D 점을 $$(X,Z)$$, 오른쪽 camera를 baseline $$B$$만큼 옮긴 위치에 두면 닮은삼각형으로

$$
x_L=\frac{fX}{Z},\qquad
x_R=\frac{f(X-B)}{Z}
$$

를 얻는다. 두 image coordinate의 차이를 취하면

$$
d=x_L-x_R
=\frac{fX-f(X-B)}{Z}
=\frac{fB}{Z}.
$$

양변을 정리하면 $$Z=fB/d$$다. 즉 같은 $$f,B$$에서는 disparity가 절반으로 줄 때 추정 depth가 두 배가 된다. 다만 $$d=0$$이면 식의 분모가 0이 되어 유한 depth를 정할 수 없고, 먼 물체처럼 $$d$$가 작을수록 작은 disparity 오차가 크게 증폭된다. 미분한 1차 오차 근사

$$
|\delta Z|\approx\left|\frac{\partial Z}{\partial d}\right||\delta d|
=\frac{fB}{d^2}|\delta d|
=\frac{Z^2}{fB}|\delta d|
$$

는 이 민감도를 보여준다. 이는 $$\lvert\delta d\rvert\ll d$$일 때만 유효한 선형 근사이며, calibration 오차·lens distortion·잘못된 correspondence까지 포함한 완전한 오차 모델은 아니다.

이 식은 **disparity가 클수록 물체가 가깝고, 작을수록 멀다**는 직관을 보여준다.

> **작성자 보충:** 실제 stereo depth 계산에는 camera calibration, lens distortion 보정, 좌우 영상 정렬과 같은 점을 찾는 correspondence 과정이 필요하다. 질감이 거의 없는 표면, 반복 무늬, 가려짐, 먼 거리에서는 correspondence가 어려워져 depth 오차가 커질 수 있다. NVIDIA의 [Stereo Disparity Workflow](https://docs.nvidia.com/drive/driveworks-3.5/stereo_usecase1.html){:target="_blank" rel="noopener"}는 좌·우 camera의 intrinsic/extrinsic parameter, rectification, occlusion과 invalid disparity 처리를 구현 조건으로 설명한다. 이 문서는 특정 DriveWorks 버전의 개발 문서이므로 일반적인 원리를 보강하는 범위에서만 참고한다.

## 4. LiDAR: 레이저로 3D geometry 측정하기

LiDAR는 *Light Detection and Ranging*의 약자다. 레이저 pulse를 내보내고 물체에서 반사되어 돌아오기까지 걸린 시간을 분석해 거리를 측정한다. 왕복 시간 $$\Delta t$$를 이용하는 단순한 time-of-flight 모델은 다음과 같다.

$$
r = \frac{c\Delta t}{2}
$$

- $$r$$: 센서에서 반사점까지의 거리
- $$c$$: 빛의 속도
- $$\Delta t$$: 레이저 pulse의 왕복 시간
- 분모의 2: 신호가 물체까지 갔다가 돌아오는 왕복 경로 보정

| 기호 | 명칭 | SI 단위 | 식의 성격 |
|---|---|---|---|
| $$r$$ | One-way range | $$\mathrm{m}$$ | 단순 ToF model에서의 거리 |
| $$c$$ | 빛의 전파 속도 | $$\mathrm{m/s}$$ | 진공에서는 정확히 $$299{,}792{,}458\ \mathrm{m/s}$$, 공기에서는 굴절률에 따라 조금 작음 |
| $$\Delta t$$ | Round-trip time of flight | $$\mathrm{s}$$ | 송신부터 echo 검출까지의 시간 |

### 4.1 작성자 보충: $$r=c\Delta t/2$$의 유도와 조건

전파 속도가 왕복 경로에서 일정하고 물체와 sensor가 측정 중 거의 움직이지 않는다고 하자. Pulse는 물체까지 $$r$$, 다시 sensor까지 $$r$$을 이동하므로 총 경로 길이는 $$2r$$다. 거리 = 속도 × 시간 관계에서

$$
2r=c\Delta t\quad\Longrightarrow\quad r=\frac{c\Delta t}{2}
$$

가 된다. 이는 위 가정 아래의 **정확한 등식**이며 경험적 보정식이 아니다. 다만 실제 장치의 $$\Delta t$$에는 electronics delay, pulse detection threshold, atmospheric propagation, multipath가 섞이므로 calibration된 offset과 noise model이 추가된다. 물체가 빠르게 움직이거나 echo가 여러 경로로 돌아오면 단일 왕복 경로 가정이 깨진다.

LiDAR는 여러 방향으로 이 측정을 반복해 각 반사점을 $$(x, y, z)$$ 좌표로 표현한다. 이렇게 얻은 점 집합이 **3D point cloud**다.

### 4.2 한 frame과 여러 frame

한 LiDAR frame은 특정 시점의 도로 표면, 차량, 건물과 장애물 표면을 점으로 보여준다. 연속 frame을 시각화하면 차량 이동과 주변 객체 변화를 시간축으로 관찰할 수 있다. 다만 frame을 합치려면 자차의 움직임을 보정하고 좌표계를 정렬해야 한다.

### 4.3 Point cloud에서 BEV로

강의 자료는 3D point cloud를 XY 평면에 투영해 **bird's-eye view(BEV)** 로 보는 예를 제시한다.

```text
3D point cloud -> XY-plane projection -> top-down BEV
```

BEV에서는 차량 주변의 앞·뒤·좌·우 위치 관계와 거리 구조가 한 좌표계에 놓인다. 이 표현은 object detection, occupancy estimation, map alignment와 motion planning에 유리하다. Camera의 perspective view에서 먼 물체가 작아지는 현상을 줄이고, planner가 사용하는 평면 좌표와 직접 연결하기 쉽기 때문이다.

### 4.4 LiDAR의 강점과 제약

| 관점 | 내용 |
|---|---|
| 강점 | 회전형 구성에서 360-degree coverage를 만들 수 있다. |
| 강점 | 물체까지의 depth를 직접 측정한다. |
| 강점 | 조밀한 point cloud로 높은 공간 해상도를 제공할 수 있다. |
| 제약 | 자연스러운 RGB 색을 직접 얻지 못한다. 일부 장비는 반사 강도는 제공한다. |
| 제약 | 비, 눈, 안개와 공기 중 입자가 레이저 반사에 영향을 줄 수 있다. |
| 제약 | 고성능 장비의 가격이 높지만 기술 발전과 양산으로 낮아지는 추세다. |
| 제약 | 레이저 구동, 회전 또는 beam steering과 신호 처리에 전력이 필요하다. |

## 5. RADAR: 전파로 거리와 속도 측정하기

RADAR는 *Radio Detection and Ranging*의 약자다. 전파를 송신하고 물체에서 반사된 신호를 분석해 대상의 거리와 방향을 추정한다. 자동차 radar는 송신 신호와 수신 신호의 시간·주파수·위상 차이를 이용한다.

특히 반사체가 센서 쪽으로 다가오거나 멀어지면 수신 주파수가 달라진다. 이 **Doppler effect**를 사용하면 line of sight 방향의 상대 속도를 직접 추정할 수 있다.

강의가 강조한 RADAR의 장점은 다음과 같다.

- 비, 안개 등 까다로운 기상 조건에서도 비교적 안정적으로 물체를 감지한다.
- 원거리 탐지에 유리하다.
- Doppler effect로 물체의 속도를 감지할 수 있다.
- LiDAR보다 상대적으로 저렴한 구성이 가능하다.

> **작성자 보충:** 일반적인 automotive RADAR는 camera나 고해상도 LiDAR보다 각도·형상·semantic 정보가 거칠 수 있고, multipath reflection이나 여러 target이 가까이 있을 때 측정이 복잡해질 수 있다. Texas Instruments의 [mmWave Radar Range and Angular Resolution](https://www.ti.com/lit/pdf/swra841){:target="_blank" rel="noopener"}은 radar가 range·angle·velocity를 함께 측정하는 원리와 센서별 trade-off를 설명한다. 문서의 제품별 해상도 수치는 전체 automotive RADAR의 보편 사양으로 일반화하지 않는다.

## 6. 세 센서의 trade-off

| 기준 | Camera | LiDAR | RADAR |
|---|---|---|---|
| 대표 출력 | RGB image | 3D point cloud | Range, angle, radial velocity |
| 가장 강한 정보 | 색·질감·의미 | 거리·형상·3D geometry | 장거리 거리·상대 속도 |
| 직접 depth 측정 | Monocular은 어려움; stereo로 추정 가능 | 가능 | 가능 |
| 직접 속도 측정 | 여러 frame과 추적 필요 | 여러 frame과 추적 필요 | Doppler로 가능 |
| 악천후 대응 | 가시성 저하에 민감 | 빗방울·안개·눈의 반사 영향 | 비교적 강함 |
| 공간 세부 묘사 | 높은 2D 해상도 | 높은 3D 해상도 | 보통 더 거친 편 |
| 색·문자 인식 | 강함 | 자연색 없음 | 어려움 |
| 대표 제약 | depth, low light, glare | 비용, 전력, 날씨 | 각도·형상·semantic 해상도 |

> **비교의 핵심:** Camera는 “무엇처럼 보이는가”, LiDAR는 “어디에 어떤 형상이 있는가”, RADAR는 “얼마나 멀고 어떤 속도로 움직이는가”에 특히 강하다.

## 7. 작성자 보충: Sensor fusion이 필요한 이유

이 절은 강의 슬라이드의 multi-sensor 차량 사례를 실제 구현 관점으로 확장한 작성자 보충이다. Sensor fusion은 단순히 측정값의 개수를 늘리는 작업이 아니라, 서로 다른 물리 신호를 결합해 한 센서의 약점을 다른 센서의 강점으로 보완하는 과정이다. Waymo의 [Sixth-Generation Driver 소개](https://waymo.com/blog/2024/08/meet-the-6th-generation-waymo-driver/){:target="_blank" rel="noopener"}도 camera·LiDAR·RADAR의 overlapping view와 redundancy를 자사 설계 원리로 설명한다. 이는 제조사의 1차 자료이며 독립적인 안전성 증명으로 해석하지 않는다.

예를 들어 야간에 camera가 먼 차량의 외형을 선명하게 보지 못하더라도 RADAR는 거리와 상대 속도를 제공할 수 있다. 반대로 RADAR가 인접한 두 물체의 형태를 거칠게 표현할 때 camera와 LiDAR가 경계와 위치를 세밀하게 보완할 수 있다.

효과적인 fusion에는 다음 조건이 필요하다. NVIDIA DriveWorks의 [Calibration Engine](https://docs.nvidia.com/drive/driveworks-3.5/calibration_2engine_2docs_2mainsection_8md_source.html){:target="_blank" rel="noopener"}과 [Time Synchronization](https://docs.nvidia.com/drive/archive/driveworks-3.0/sensors_2time_2docs_2mainsection_8md_source.html){:target="_blank" rel="noopener"}은 각각 sensor intrinsic/extrinsic alignment와 여러 sensor timestamp 정렬의 구현 사례를 제공한다. 두 문서 모두 특정 NVIDIA SDK의 보관 문서이므로 구현 원리를 보강하는 자료로 한정한다.

1. **Calibration:** 센서의 위치와 방향을 공통 vehicle coordinate에 맞춘다.
2. **Time synchronization:** 서로 다른 주기로 들어오는 측정 시각을 정렬한다.
3. **Association:** 각 센서가 본 결과가 같은 객체인지 연결한다.
4. **Uncertainty handling:** 센서별 noise와 confidence를 고려해 결합한다.
5. **Failure awareness:** 가려짐, 오염, glare, weather 같은 성능 저하를 감지한다.

센서가 많아도 calibration이 틀리거나 시간이 어긋나면 오히려 잘못된 world model을 만들 수 있다. 따라서 **sensor redundancy와 fusion quality는 별개의 문제**다.

## 8. Case study: 서로 다른 센서 구성 철학

강의 자료는 Waymo, Zoox, Tesla를 나란히 제시해 서로 다른 설계 선택을 비교한다. 아래 구성과 수치는 강의 슬라이드에 제시된 사례이며, 실제 차량 세대와 시점에 따라 바뀔 수 있다.

### 8.1 Waymo: 다양한 센서의 중첩

슬라이드는 Waymo Driver의 예로 **29 cameras, 5 LiDARs, 6 RADARs**를 제시한다. 차량의 여러 위치에 서로 다른 센서를 배치해 시야를 중첩하고, camera의 semantic 정보와 LiDAR의 geometry, RADAR의 거리·속도 정보를 함께 사용하는 방식이다.

이 구조의 목적은 센서 수 자체가 아니라 coverage와 redundancy다. 전방 장거리 관측, 근거리 blind spot, 측면·후방 관측처럼 서로 다른 범위를 담당하도록 구성한다.

### 8.2 Zoox: 360-degree robotaxi coverage

Zoox 사례는 cameras, LiDARs, RADAR, long-wave infrared sensors를 결합해 360-degree view를 만드는 구성을 보여준다. 양방향 주행을 고려한 전용 robotaxi에서는 특정한 “앞쪽” 하나보다 차량 둘레의 균형 잡힌 관측이 중요하다는 설계 의도를 읽을 수 있다.

### 8.3 Tesla: camera-centered vision approach

슬라이드는 Tesla 사례를 **9 cameras, AI & Vision Only**로 소개한다. 이 접근은 camera 영상과 학습 기반 perception을 중심에 두어 사람의 시각 운전과 비슷한 입력 체계를 추구하고, 센서 종류와 hardware complexity를 줄이는 방향을 보여준다.

이어지는 “하지만…” 슬라이드는 충돌 차량 사진을 제시한다. 이 사진만으로 특정 사고 원인이나 한 센서 전략의 우열을 단정할 수는 없다. 강의 흐름에서 잡아야 할 메시지는 **어떤 sensor suite도 인식·판단·안전 검증을 자동으로 보장하지 않는다**는 점이다. 실제 안전성은 sensor coverage뿐 아니라 data quality, perception model, prediction, planning, control, fail-safe와 검증 체계 전체에 달려 있다.

## 9. 작성자 보충: Sensor suite를 설계할 때의 판단 기준

이 절은 강의의 센서 비교와 차량 사례를 system engineering 관점으로 확장한 작성자 보충이다. NHTSA의 [Automated Driving Systems guidance](https://www.nhtsa.gov/vehicle-manufacturers/automated-driving-systems){:target="_blank" rel="noopener"}는 system safety, Operational Design Domain(ODD), object and event detection and response, fallback, validation을 주요 안전 요소로 제시한다. 이는 센서 종류나 개수를 정하는 규정이 아니라, sensor suite를 전체 운행 범위와 안전 검증 안에서 판단해야 한다는 기준으로 사용한다.

| 판단 기준 | 확인할 질문 |
|---|---|
| Operational Design Domain | 어떤 도로, 속도, 지역, 시간대와 날씨에서 운행하는가? |
| Detection range | 안전하게 멈추는 데 필요한 거리보다 일찍 위험을 볼 수 있는가? |
| Field of view | 전방뿐 아니라 측면, 후방, 근거리 blind spot을 어떻게 덮는가? |
| Complementarity | 한 센서가 약해지는 조건에서 다른 센서가 유효한 정보를 주는가? |
| Redundancy | 단일 센서 고장이나 오염 후에도 최소 안전 기능을 유지하는가? |
| Calibration | 설치 오차, 진동, 수리 후 정렬 상태를 어떻게 검증하는가? |
| Compute and power | 센서 data rate와 처리 지연, 전력·열 예산을 감당할 수 있는가? |
| Cost and maintainability | 차량 가격뿐 아니라 세척, 교정, 교체 비용을 감당할 수 있는가? |

즉, 센서 선택은 perception 모델만의 문제가 아니라 **ODD, 안전 목표, 차량 구조, compute budget과 운영 비용을 함께 다루는 system engineering 문제**다.

## 마지막 핵심 정리

1. **센서는 autonomy stack의 관측 기반이다.** Sensor data가 perception의 detection·tracking을 만들고 prediction, planning, control로 이어진다.
2. **Camera는 의미 정보에 강하다.** 높은 2D 해상도와 RGB 정보로 차선, 신호, 표지판을 잘 표현하지만 depth와 visibility 조건을 주의해야 한다.
3. **Stereo camera는 disparity로 depth를 추정한다.** 깊이는 calibration과 correspondence 품질에 크게 좌우된다.
4. **LiDAR는 3D geometry에 강하다.** 레이저 왕복 시간으로 직접 거리를 측정하고 point cloud와 BEV를 만든다.
5. **RADAR는 장거리 거리와 속도에 강하다.** 악천후에 비교적 강하고 Doppler effect로 상대 속도를 얻는다.
6. **센서 구성에는 단일 정답이 없다.** Waymo·Zoox의 multi-sensor 접근과 Tesla의 camera-centered 접근은 서로 다른 비용·복잡도·학습 전략을 반영한다.
7. **센서 개수보다 전체 안전 체계가 중요하다.** Calibration, synchronization, fusion, failure detection과 downstream stack 검증이 함께 작동해야 한다.

## Study Guide

1. 먼저 `Maps + Sensors -> Perception -> Prediction -> Planning -> Control` 흐름을 외운다.
2. Camera·LiDAR·RADAR를 **관측 신호, 대표 출력, 강점, 실패 조건**의 네 축으로 비교한다.
3. 두 depth 식 $$Z=fB/d$$와 $$r=c\Delta t/2$$가 각각 stereo geometry와 LiDAR time-of-flight를 설명한다는 점을 구분한다.
4. Point cloud와 BEV의 관계를 그림 없이 말로 설명해 본다.
5. Waymo·Zoox·Tesla 사례는 회사별 최신 hardware 사양 암기보다, multi-sensor와 vision-centered 설계의 trade-off를 설명하는 데 사용한다.

## 복습 질문

<details markdown="block">
<summary>1. Sensor data가 perception 뒤의 planning과 control에도 중요한 이유는 무엇인가?</summary>

답변: Perception은 sensor data를 detection과 track으로 변환하고, prediction은 그 결과로 주변 객체의 미래 움직임을 예측한다. Planning은 이 world model을 바탕으로 trajectory를 만들고 control은 실제 조향과 가속을 수행한다. 초기 관측이 부정확하면 뒤 단계의 판단도 잘못될 수 있으므로 sensor quality는 stack 전체의 기반이다.

</details>

<details markdown="block">
<summary>2. Monocular camera와 stereo camera의 depth 정보 차이를 설명하라.</summary>

답변: 한 대의 camera 영상은 3D 장면이 2D 평면에 투영된 결과이므로 metric depth를 직접 제공하지 않는다. Stereo camera는 서로 떨어진 두 시점에서 같은 점의 disparity를 구하고, focal length와 baseline을 이용해 depth를 계산한다. 다만 calibration과 correspondence 오차에 영향을 받는다.

</details>

<details markdown="block">
<summary>3. LiDAR point cloud를 BEV로 투영하는 이유는 무엇인가?</summary>

답변: BEV는 차량 주변 물체와 주행 가능 공간을 동일한 top-down 좌표계에서 보여준다. 거리와 방향 관계가 perspective distortion 없이 정리되므로 object detection, occupancy, map alignment와 trajectory planning에 연결하기 쉽다.

</details>

<details markdown="block">
<summary>4. RADAR가 camera와 LiDAR를 완전히 대체하기 어려운 이유는 무엇인가?</summary>

답변: RADAR는 장거리 거리와 상대 속도, 악천후 대응에 강하지만 일반적으로 물체의 색, 문자, 세밀한 경계와 3D 형상을 camera나 고해상도 LiDAR만큼 풍부하게 표현하지 못한다. 따라서 서로 다른 정보를 가진 센서를 결합하는 것이 유리하다.

</details>

<details markdown="block">
<summary>5. Sensor redundancy와 sensor fusion quality가 다른 개념인 이유는 무엇인가?</summary>

답변: Redundancy는 같은 영역을 여러 센서가 관측해 한 센서가 실패해도 정보를 남기는 설계다. Fusion quality는 서로 다른 측정값을 좌표와 시간에 맞게 정렬하고 불확실성을 고려해 일관된 world model로 만드는 능력이다. 센서가 많아도 calibration이나 synchronization이 틀리면 fusion 결과는 나빠질 수 있다.

</details>

<details markdown="block">
<summary>6. Waymo·Zoox·Tesla 사례에서 공통으로 확인해야 할 질문은 무엇인가?</summary>

답변: 센서의 개수보다 어떤 ODD를 목표로 하는지, 필요한 coverage와 detection range를 확보하는지, 각 센서의 실패 조건을 어떻게 보완하는지, compute·전력·비용을 감당하는지, 그리고 perception부터 fail-safe까지 전체 stack을 어떻게 검증하는지를 확인해야 한다.

</details>

## 원문 페이지 대조와 수식 판정

공개된 `02-sensors.pdf`의 **물리 PDF 32쪽 전체를 시각 대조**했다. 원문 슬라이드는 sensor 원리와 장단점을 그림·문장으로 설명하며, 대수적으로 증명해야 할 명시적 수식은 제시하지 않는다.

| 원문 PDF 쪽 | 원문 핵심 | 본문 반영 및 판정 |
|---:|---|---|
| 5–7 | 센서의 역할, 감각 정보 비중, autonomous-driving stack | §1과 전체 구조에서 개념·역할을 반영; proof-level 수식 없음 |
| 9–14 | camera, RGB filter, 장단점, stereo camera | §2–3에서 반영. $$Z=fB/d$$는 원문 식이 아니라 stereo depth 원리를 설명하기 위한 **작성자 보충 유도** |
| 15–21 | LiDAR 원리, point cloud, BEV, 장단점 | §4에서 반영. $$r=c\Delta t/2$$는 왕복 time-of-flight를 풀어 쓴 **작성자 보충 유도** |
| 22–23 | RADAR 원리와 Doppler 기반 속도 감지 | §5에서 반영; 원문에 Doppler equation은 없어 임의의 source formula로 추가하지 않음 |
| 25–28 | Waymo·Zoox·Tesla 사례와 사고 이미지 | §7에서 시점 의존 사례임을 분리해 설명 |
| 1–4, 8, 24, 29–32 | 표지·구분·요약·예고·질문 | 별도 증명이 필요한 수식 없음 |

따라서 이 자료의 수식 감사 결과는 “원문 수식의 미증명”이 아니라, 본문에 추가한 두 기하·물리 식의 출처 경계와 가정이 명확한지를 확인하는 문제다. 두 식 모두 기호·단위·성립 조건·실패 조건을 해당 절에서 함께 설명한다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/02-sensors.pdf" | relative_url }}" target="_blank" rel="noopener">02-sensors.pdf</a></li>
</ul>

### 작성자 보충 참고자료

- [NVIDIA DriveWorks: Stereo Disparity Workflow](https://docs.nvidia.com/drive/driveworks-3.5/stereo_usecase1.html){:target="_blank" rel="noopener"}
- [Texas Instruments: Understanding Range and Angular Resolution in mmWave Radar Devices](https://www.ti.com/lit/pdf/swra841){:target="_blank" rel="noopener"}
- [NVIDIA DriveWorks: Calibration Engine](https://docs.nvidia.com/drive/driveworks-3.5/calibration_2engine_2docs_2mainsection_8md_source.html){:target="_blank" rel="noopener"}
- [NVIDIA DriveWorks: Time Synchronization](https://docs.nvidia.com/drive/archive/driveworks-3.0/sensors_2time_2docs_2mainsection_8md_source.html){:target="_blank" rel="noopener"}
- [NHTSA: Automated Driving Systems](https://www.nhtsa.gov/vehicle-manufacturers/automated-driving-systems){:target="_blank" rel="noopener"}
- [Waymo: Meet the 6th-generation Waymo Driver](https://waymo.com/blog/2024/08/meet-the-6th-generation-waymo-driver/){:target="_blank" rel="noopener"}
