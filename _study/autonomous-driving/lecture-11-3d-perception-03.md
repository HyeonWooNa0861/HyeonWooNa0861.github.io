---
layout: default
date: 2026-10-06 11:40:00 +0900
title: "Lecture 11: Multimodal 3D Object Detection"
course: "Autonomous Driving"
topic: "Frustum PointNets, MV3D, and Perception Datasets"
order: 11
major_topic: "Autonomous Systems"
keywords:
  - "Multimodal 3D Detection"
  - "Frustum PointNets"
  - "MV3D"
  - "Sensor Fusion"
  - "KITTI"
  - "Autonomous Driving Datasets"
---

# Lecture 11: Multimodal 3D Object Detection

Source PDF: [11 3D Perception (3).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf" | relative_url }})

국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 강의에서 RGB camera와 LiDAR를 결합하는 두 고전적 3D detector인 **Frustum PointNets**와 **MV3D**를 살펴본다. 두 방법이 proposal을 만드는 좌표계와 feature를 결합하는 위치가 어떻게 다른지 비교하고, perception dataset의 sensor·split·metric을 읽는 기준까지 연결한다.

> **핵심:** Camera는 촘촘한 색·질감과 강한 2D 인식 단서를 제공하고, LiDAR는 metric depth와 3D 구조를 제공한다. 그러나 두 센서의 장점을 합치려면 “feature를 이어 붙인다”는 말보다 먼저 **같은 좌표계·같은 시간·같은 객체 영역**을 만들어야 한다. Frustum PointNets는 2D box를 3D search frustum으로 들어 올린 뒤 그 안의 점을 직접 처리하고, MV3D는 LiDAR의 BEV·front view와 RGB view에서 같은 3D proposal의 RoI feature를 맞춘 뒤 깊게 융합한다.

## 전체 흐름

| 순서 | 슬라이드 | 주제 | 핵심 질문 |
|---|---:|---|---|
| 1 | 1–7 | 표지·공지·이전 강의 복습·목차 | 이번 강의가 LiDAR-only 3D detection에서 무엇을 확장하는가? |
| 2 | 8–10 | Multimodal 3D detection의 필요성 | Camera와 LiDAR는 어떤 정보를 서로 보완하는가? |
| 3 | 11–14 | Frustum PointNets | 2D region을 3D frustum으로 바꾸고 점에서 box를 어떻게 찾는가? |
| 4 | 15–21 | MV3D | BEV proposal과 세 view의 RoI feature를 어느 단계에서 합치는가? |
| 5 | 22–27 | Perception dataset과 KITTI | 모델 비교에서 sensor 구성·split·task를 왜 함께 봐야 하는가? |
| 6 | 28–30 | 요약·질문 | 두 fusion 전략과 dataset 선택 기준을 어떻게 연결하는가? |

3쪽은 과제 공지, 2·4·6·8·23·28·30쪽은 구간 표지 또는 질문 화면이다. 과제의 마감·제출 안내는 학습 본문에 옮기지 않았다. 22·24쪽은 렌더링된 PDF에서 검은 embedded-media 영역으로 보여 세부 영상 내용은 확인할 수 없었고, 이 글은 앞뒤의 명시적 슬라이드 내용만 사용한다.

## 1. 왜 multimodal 3D detection인가

9쪽은 두 센서의 보완 관계를 간단히 요약한다.

| 센서 | 강점 | 구조적 한계 | 3D detection에서의 역할 |
|---|---|---|---|
| RGB camera | 높은 공간 해상도, 색·질감·윤곽 | 한 장의 영상만으로 metric depth가 직접 주어지지 않음 | 2D proposal, class·appearance feature |
| LiDAR | 각 return의 3D 위치와 거리 | 멀수록 점이 성기고 texture가 없음 | 3D 위치·크기·방향, geometric proposal |

Camera가 “depth를 전혀 알 수 없다”는 말은 **센서가 한 픽셀마다 직접 metric depth를 측정하지 않는다**는 뜻으로 읽어야 한다. Stereo, multi-view geometry, monocular depth network로 depth를 추정할 수는 있지만, 추정값은 관측 조건과 학습 가정에 의존한다. 반대로 LiDAR가 low-resolution이라는 말도 영상의 정규 pixel grid보다 return이 성기다는 비교이지, 모든 거리와 방향에서 같은 해상도를 갖는다는 뜻은 아니다.

### 1.1 Fusion 전에 필요한 세 가지 정렬

슬라이드는 model architecture에 집중하지만, 그림의 projection 화살표가 성립하려면 다음 전제가 필요하다.

1. **공간 calibration:** LiDAR 좌표를 camera 좌표로 옮기는 extrinsic과 camera intrinsic이 알려져야 한다.
2. **시간 synchronization:** 서로 다른 시각에 측정한 점과 영상은 ego motion과 객체 motion을 보정해야 한다.
3. **표현 alignment:** 서로 다른 해상도와 support를 가진 feature에서 같은 3D proposal에 해당하는 영역을 뽑아야 한다.

#### 공간 calibration과 projection

**작성자 보충 — 정확한 좌표 변환:** LiDAR 점의 동차좌표를 $$\bar{\mathbf p}_{L}=[X_L,Y_L,Z_L,1]^{\top}$$, LiDAR에서 camera로의 extrinsic을 $$\mathbf T_{C\leftarrow L}\in SE(3)$$라 두자. $$SE(3)$$는 회전과 평행이동을 결합한 3차원 강체 변환의 집합이다. 회전행렬 $$\mathbf R$$과 이동벡터 $$\mathbf t$$를 한 번의 행렬곱으로 적용하기 위해

$$
\mathbf T_{C\leftarrow L}=
\begin{bmatrix}
\mathbf R&\mathbf t\\
\mathbf 0^{\top}&1
\end{bmatrix}
$$

로 정의한다. 이 행렬에 동차좌표를 곱하면 앞의 세 성분은 $$\mathbf R\mathbf p_L+\mathbf t$$, 마지막 성분은 1이 된다. 따라서 camera 좌표는 다음과 같다.

$$
\begin{bmatrix}
X_C\\Y_C\\Z_C\\1
\end{bmatrix}
=
\mathbf T_{C\leftarrow L}\bar{\mathbf p}_{L}
$$

이때 $$X_L,Y_L,Z_L,X_C,Y_C,Z_C$$의 단위는 m, 회전은 무차원, 평행이동 성분은 m다. 왜곡을 이미 보정한 pinhole camera를 가정하고 $$Z_C>0$$이면, intrinsic matrix $$\mathbf K$$를 곱한 동차 image 좌표는 $$\tilde{\mathbf q}=\mathbf K[X_C,Y_C,Z_C]^{\top}$$다. 마지막 성분 $$Z_C$$로 앞의 두 성분을 나누면 다음 **정확한 모델 식**을 얻는다.

$$
u=f_x\frac{X_C}{Z_C}+c_x,\qquad
v=f_y\frac{Y_C}{Z_C}+c_y
$$

$$u,v,c_x,c_y,f_x,f_y$$의 단위는 pixel이다. 실제 lens distortion을 보정하지 않았거나 rolling shutter·calibration drift가 있으면 이 식만으로 정확한 대응을 얻을 수 없다.

예를 들어 camera 좌표의 점이 $$(X_C,Y_C,Z_C)=(8,1.2,20)\ \mathrm{m}$$이고 $$f_x=f_y=800\ \mathrm{pixel}$$, $$(c_x,c_y)=(640,360)\ \mathrm{pixel}$$이면 $$(u,v)=(960,408)\ \mathrm{pixel}$$이다. 이 점이 2D proposal 안에 있는지 확인하면 해당 proposal의 3D frustum point 후보를 고를 수 있다.

#### 시간 synchronization과 motion error

LiDAR 시각을 $$t_L$$, camera 시각을 $$t_C$$, 차이를 $$\Delta t=t_C-t_L$$라고 하자. 두 센서 frame을 같은 시각으로 보정하지 않으면, 등속도 $$v$$와 일정 yaw rate $$\omega$$라는 단순 가정에서만 다음 근사가 성립한다. 이동 거리와 회전각을 각각 속도와 각속도의 시간 적분으로 정의하고, 구간에서 두 값이 일정하다고 두면 적분이 곱으로 줄어든다.

$$
\Delta s\approx v\Delta t,\qquad
\Delta\psi\approx\omega\Delta t
$$

$$\Delta t$$는 s, $$v$$는 m/s, $$\Delta s$$는 m, $$\omega$$는 rad/s, $$\Delta\psi$$는 rad다. 예를 들어 $$v=15\ \mathrm{m/s}$$, $$\Delta t=0.05\ \mathrm{s}$$이면 위치 차이는 약 $$0.75\ \mathrm{m}$$다. $$\omega=0.2\ \mathrm{rad/s}$$이면 방향 차이는 $$0.01\ \mathrm{rad}\approx0.57^{\circ}$$다. 이는 **constant-motion 근사**이며, 가감속·동적 객체·한 번의 LiDAR scan 안에서 point마다 측정 시각이 다른 경우에는 ego pose interpolation과 point-wise deskew가 필요하다.

## 2. Frustum PointNets: 2D proposal로 3D 탐색 공간 줄이기

10–11쪽의 Frustum PointNets는 camera와 depth/LiDAR point cloud를 순차적으로 연결한다. 넓은 3D 공간 전체에서 먼저 proposal을 만들지 않고, 잘 발달한 2D detector가 낸 image box를 camera ray 방향으로 들어 올려 **절두체(frustum)**를 만든다.

1. RGB image에서 2D detector가 object box와 class를 예측한다.
2. Calibration을 이용해 box의 네 모서리 ray를 3D로 확장한다. Sensor의 유효 near/far depth를 더하면 3D frustum이 된다.
3. Frustum 안의 point를 모은 뒤, frustum의 중심 ray가 camera의 정면축을 향하도록 먼저 회전한다.
4. 회전된 frustum point를 PointNet 계열 network로 foreground와 background로 분리한다.
5. Foreground point의 centroid를 빼고 T-Net으로 center residual을 보정한 뒤 amodal 3D box를 추정한다.

여기서 **amodal box**는 현재 보이는 surface point만 감싸는 box가 아니라, 가려진 부분까지 포함한 객체의 전체 3D extent를 추정하는 box다. 2D detector가 물체를 놓치면 해당 물체의 frustum도 생기지 않으므로, 뒤의 3D network가 이를 독립적으로 복구할 수 없다는 cascade 한계가 있다.

### 2.1 Stage 1: frustum 안의 point-wise segmentation

첫 PointNet에 넣기 전에 Frustum PointNets는 **frustum rotation**을 수행한다. KITTI처럼 upright object와 camera의 vertical axis를 가정하고 camera 좌표의 수평 중심 ray를 $$\mathbf d=(\sin\alpha,0,\cos\alpha)^{\top}$$라 두자. Column vector와 camera 원점 중심의 yaw rotation convention에서

$$
\mathbf p_F=\mathbf R_y(-\alpha)\mathbf p_C,
\qquad
\mathbf R_y(-\alpha)=
\begin{bmatrix}
\cos\alpha&0&-\sin\alpha\\
0&1&0\\
\sin\alpha&0&\cos\alpha
\end{bmatrix}
$$

이면 $$\mathbf R_y(-\alpha)\mathbf d=(0,0,1)^{\top}$$가 되어 frustum의 수평 중심축이 camera 정면 방향과 맞는다. $$\alpha$$의 단위는 rad이고 회전행렬은 무차원이다. 이 좌표를 논문은 **frustum coordinate**로 구분한다. 회전은 객체 위치를 원점으로 옮기는 translation이 아니며, 관측 방향 변화로 생기는 좌표 변동을 먼저 정규화하는 단계다.

12쪽의 첫 PointNet은 이렇게 회전된 frustum point cloud $$\mathbf P_F\in\mathbb R^{n\times c}$$를 받아 각 점이 관심 객체인지 background인지 binary classification한다. $$n$$은 point 수, $$c$$는 XYZ와 intensity 같은 feature channel 수로 무차원 개수다. XYZ는 m, intensity는 sensor 정의에 따른 무차원 또는 raw 단위다.

같은 image box의 frustum에는 foreground occluder, 관심 객체, 뒤쪽 건물·도로가 함께 들어올 수 있다. 그러므로 “box 안의 모든 point”를 바로 box regression에 넣는 대신 3D 공간에서 객체 point를 먼저 고른다. 12쪽의 `RGB point cloud`는 RGB만으로 만든 point cloud라는 뜻이라기보다 **RGB-D proposal에 연결된 frustum point cloud**로 읽는 편이 정확하다.

### 2.2 Stage 2: T-Net의 center translation

13쪽은 mask로 남긴 $$m$$개 point의 centroid를 빼 **mask coordinate**로 옮긴 뒤, T-Net이 amodal box center를 향한 center residual을 예측해 **object coordinate**를 만드는 과정을 그린다. 따라서 좌표 정규화 순서는 `camera coordinate → frustum rotation → instance segmentation → centroid subtraction → T-Net translation`이다. 앞 단계의 frustum rotation은 view angle을 정규화하고, centroid subtraction은 분할된 점 집합의 평균을 원점으로 옮기며, T-Net은 남은 center residual을 학습한다. 세 연산은 목적과 적용 시점이 서로 다르다. “centroid를 3D box center와 맞춘다”는 말은 정답 center를 기하학적으로 정확히 알아낸다는 뜻이 아니라, **학습된 translation residual로 남은 차이를 줄인다**는 뜻이다.

Frustum PointNets 논문의 center 합성은 다음과 같다.

$$
\mathbf C_{\mathrm{pred}}^F
=\mathbf C_{\mathrm{mask}}^F
+\Delta\mathbf C_{\mathrm{T\text{-}Net}}^F
+\Delta\mathbf C_{\mathrm{box}}^F
$$

위첨자 $$F$$는 앞에서 회전한 frustum coordinate를 뜻한다. 세 center와 residual은 모두 그 축에서 m 단위를 가져야 한다. 이 식은 세 translation의 **정확한 합성 정의**지만, 예측 residual 자체가 정답이라는 보장은 없다. 예를 들어 frustum coordinate에서 $$\mathbf C_{\mathrm{mask}}^F=(10,0.5,1.2)\ \mathrm{m}$$, $$\Delta\mathbf C_{\mathrm{T\text{-}Net}}^F=(0.3,-0.1,0)\ \mathrm{m}$$, $$\Delta\mathbf C_{\mathrm{box}}^F=(0.1,0,0.05)\ \mathrm{m}$$이면 합은 $$\mathbf C_{\mathrm{pred}}^F=(10.4,0.4,1.25)\ \mathrm{m}$$다. 이 값을 camera-frame center로 바로 사용해서는 안 된다.

최종 camera coordinate로 되돌릴 때는 처음 회전의 역변환을 적용한다. 회전행렬의 역행렬이 transpose이고 $$\mathbf R_y(\alpha)\mathbf R_y(-\alpha)=\mathbf I$$이므로

$$
\mathbf C_{\mathrm{pred}}^C
=\mathbf R_y(\alpha)\mathbf C_{\mathrm{pred}}^F
$$

가 된다. Corner들도 같은 역회전으로 복원해야 한다. 수평 방향을 $$+Z$$에서 $$+X$$ 쪽으로 재는 앞의 각도 convention에서는 heading도 $$\theta_C=\operatorname{wrap}(\theta_F+\alpha)$$로 변환한다. 여기서 wrap은 각도를 선택한 $$2\pi$$ 길이 구간으로 되돌리는 연산이다. Dataset의 축·각도 convention이 다르면 그 규약에 맞춰 변환해야 한다.

### 2.3 Stage 3: amodal 3D box parameter regression

14쪽의 마지막 PointNet은 center $$(c_x,c_y,c_z)$$, size $$(h,w,l)$$, heading $$\theta$$를 예측한다. Center와 size는 m, heading은 rad다. 논문은 size template 수를 $$N_S$$, heading bin 수를 $$N_H$$라 두고 class와 residual을 함께 예측하므로 출력 수를 다음처럼 센다.

$$
3+4N_S+2N_H
$$

왜 이 수가 나오는가?

- Center residual: $$3$$개.
- Size: $$N_S$$개 class score와 각 class의 $$h,w,l$$ residual $$3N_S$$개, 합계 $$4N_S$$개.
- Heading: $$N_H$$개 bin score와 각 bin의 angle residual $$N_H$$개, 합계 $$2N_H$$개.

이는 논문이 선택한 **hybrid classification-regression parameterization의 정확한 차원 계산**이다. 다른 detector가 anchor-free size나 연속 angle만 회귀하면 같은 출력 차원을 요구하지 않는다. 슬라이드 14쪽의 마지막 box 변수는 `y`처럼 보이지만, 위치 좌표 $$y$$와 중복되므로 이 글은 원 논문에 따라 heading $$\theta$$로 표기한다.

## 3. MV3D: 같은 proposal을 세 view에서 feature로 읽기

15쪽의 MV3D는 입력을 세 2D representation으로 만든다.

- **LiDAR bird's-eye view(BEV):** 높이 slice, intensity, density map.
- **LiDAR front view(FV):** height, distance, intensity map.
- **RGB image:** 색·질감과 object appearance.

원래 3D point cloud를 2D grid로 바꾸면 2D convolution을 사용할 수 있지만 discretization과 projection 과정에서 정보가 양자화된다. 따라서 BEV가 metric geometry를 유용하게 보존한다는 말은 **calibrated orthographic ground-plane grid에서 cell 크기만큼 양자화된 footprint를 유지한다**는 뜻이다. 임의의 voxel compression에서도 물리 크기가 완전히 보존된다는 뜻은 아니다.

### 3.1 1단계: BEV에서 3D proposal 생성

16–17쪽에서 3D Proposal Network는 LiDAR BEV feature로 objectness와 3D box residual을 예측한다. 원근 투영인 image와 달리, BEV grid에서 같은 크기의 물체는 거리에 따라 급격히 작아지지 않는다. 예를 들어 한 cell이 $$0.1\ \mathrm{m}\times0.1\ \mathrm{m}$$인 설명용 grid에서 ground-plane 크기가 $$4.2\ \mathrm{m}\times1.8\ \mathrm{m}$$인 축 정렬 차량은 대략 $$42\times18$$ cell footprint를 차지한다. 이는 cell boundary와 box heading을 무시한 **작성자 보충 근사**다.

슬라이드의 “3D bounding box들이 서로 겹치지 않음”은 invariant가 아니다. BEV는 perspective occlusion을 크게 줄여 서로 다른 거리의 객체를 분리하기 좋지만, 실제 footprint가 겹치는 장면, multi-level road, loose proposal, sensor noise에서는 2D BEV box가 겹칠 수 있다.

### 3.2 2단계: 하나의 3D proposal을 각 view의 RoI로 투영

18쪽은 BEV proposal을 BEV, FV, RGB의 각 feature map에 투영하고 RoI pooling을 수행한다. 3D box의 여덟 corner를 $$\mathbf q_i$$라 하면, image view에서는 앞서 정의한 camera projection으로 $$(u_i,v_i)$$를 구해 다음 axis-aligned RoI를 만들 수 있다.

$$
\mathcal R_{\mathrm{img}}
=
[\min_i u_i,\min_i v_i,\max_i u_i,\max_i v_i]
$$

BEV에서는 corner의 ground-plane 좌표로 같은 방식의 범위를 만들고, FV에서는 LiDAR의 range-view mapping을 적용한다. $$u_i,v_i$$는 pixel, BEV 범위는 grid cell 또는 m로 표현한 뒤 feature-map scale에 맞춰야 한다. 실제 proposal이 camera 뒤에 있거나 image 밖으로 나가거나 corner projection만으로 visible region을 잘 설명하지 못하는 경계 사례도 처리해야 한다.

세 view는 원래 해상도와 모양이 다르다. RoI pooling은 각 영역을 고정 크기 tensor 또는 같은 길이 vector로 바꿔 fusion 가능한 shape을 만든다. 그러나 **shape가 같아졌다는 사실만으로 의미가 정렬되지는 않는다**. 잘못된 extrinsic, time offset, proposal 오차가 있으면 같은 vector 위치가 서로 다른 물체 부분을 나타낼 수 있다.

### 3.3 3단계: early, late, deep fusion

19–21쪽의 Region-based Fusion Network는 정렬된 view feature로 class와 3D box residual을 예측한다. 20쪽의 도식은 fusion 위치를 다음처럼 비교한다.

| 방법 | 결합 위치 | 장점 | 위험 |
|---|---|---|---|
| Early fusion | 입력 또는 첫 feature 단계 | 처음부터 cross-modal interaction 가능 | calibration 오차와 scale 차이를 그대로 섞기 쉬움 |
| Late fusion | 각 stream의 고수준 feature 뒤 | modality별 전문 feature 보존 | 세밀한 중간 상호작용이 제한됨 |
| Deep fusion | 여러 중간 layer에서 반복 | 계층별 정보를 지속적으로 교환 | shape·scale 정렬과 학습 설계가 복잡함 |

MV3D 원 논문에서 proposal $$\mathcal R$$의 세 RoI feature를 각각 $$\mathbf f_{\mathrm{BV}},\mathbf f_{\mathrm{FV}},\mathbf f_{\mathrm{RGB}}$$라 하면 deep fusion의 초기 상태와 $$l$$번째 hidden state는 다음과 같이 정의된다.

$$
\mathbf f_0
=
\mathbf f_{\mathrm{BV}}
\mathbin{\oplus}
\mathbf f_{\mathrm{FV}}
\mathbin{\oplus}
\mathbf f_{\mathrm{RGB}}
$$

$$
\mathbf f_l
=
\mathcal H_l^{\mathrm{BV}}(\mathbf f_{l-1})
\mathbin{\oplus}
\mathcal H_l^{\mathrm{FV}}(\mathbf f_{l-1})
\mathbin{\oplus}
\mathcal H_l^{\mathrm{RGB}}(\mathbf f_{l-1}),
\qquad l=1,\ldots,L
$$

$$\mathcal H_l^{v}$$는 view $$v$$의 $$l$$번째 transformation이고, $$\oplus$$는 fusion 연산이다. Early·late fusion에서는 이 연산에 concatenation을 쓰지만, 논문의 deep fusion에서는 같은 shape의 세 출력을 **element-wise mean**으로 합친다. 즉 deep fusion의 한 layer에서 $$\mathbf a,\mathbf b,\mathbf c\in\mathbb R^d$$가 나오면 $$\mathbf a\oplus\mathbf b\oplus\mathbf c=(\mathbf a+\mathbf b+\mathbf c)/3$$이다. Feature와 평균은 model 내부의 무차원 값이며, channel 대응과 compatible shape이 전제된다.

중요한 점은 세 branch가 각자 이전 branch만 이어받는 것이 아니라, 모두 동일한 fused hidden input $$\mathbf f_{l-1}$$를 받는다는 사실이다. 따라서 한 view에서 나온 정보가 평균으로 합쳐진 뒤 다음 layer의 **모든** view transformation에 다시 들어가며, 이 과정이 계층마다 반복된다. 이것이 raw vector를 한 번 평균하는 것과 다른 hierarchical cross-view interaction이다.

### 3.4 최종 oriented 3D box regression

Region-based Fusion Network의 마지막 출력은 class score와 oriented 3D box refinement다. Proposal의 여덟 corner를 $$\mathbf p_i=(x_i^p,y_i^p,z_i^p)$$, 대응하는 ground-truth corner를 $$\mathbf g_i=(x_i^g,y_i^g,z_i^g)$$, proposal box의 3D 대각선 길이를 $$d_p$$라 두면 각 target은 다음처럼 정규화한다.

$$
\Delta x_i=\frac{x_i^g-x_i^p}{d_p},\qquad
\Delta y_i=\frac{y_i^g-y_i^p}{d_p},\qquad
\Delta z_i=\frac{z_i^g-z_i^p}{d_p},
\qquad i=0,\ldots,7
$$

따라서 회귀 vector는

$$
\mathbf t=
(\Delta x_0,\ldots,\Delta x_7,
\Delta y_0,\ldots,\Delta y_7,
\Delta z_0,\ldots,\Delta z_7)
\in\mathbb R^{24}
$$

이다. 분자와 $$d_p$$가 모두 m이므로 target은 무차원이다. 여덟 corner를 각각 보정하면 축 정렬 box뿐 아니라 방향이 있는 box도 표현할 수 있고, 논문은 예측된 corner에서 orientation을 계산한다. 이 24차원 정의는 MV3D의 회귀 parameterization이며 모든 3D detector에 공통인 규칙은 아니다.

## 4. Frustum PointNets와 MV3D를 같은 축에서 비교하기

| 비교 축 | Frustum PointNets | MV3D |
|---|---|---|
| 첫 proposal | RGB image의 2D box | LiDAR BEV의 3D proposal |
| 3D 탐색 공간 | 2D box를 확장한 frustum 안의 raw point | BEV proposal을 세 2D view로 투영 |
| 핵심 처리 | Frustum rotation → point-wise segmentation → centroid subtraction·T-Net → amodal box | RoI pooling → hierarchical deep fusion → class·24-D corner refinement |
| Camera의 역할 | 2D proposal과 class prior | RGB RoI appearance feature |
| LiDAR의 역할 | Frustum 안 raw 3D point | BEV/FV grid와 3D proposal |
| 대표 실패 전파 | 2D miss·부정확한 box가 frustum을 제한 | BEV proposal miss·view misalignment가 뒤 fusion을 제한 |

둘 다 two-stage 성격을 갖지만 “어디에서 후보를 만들고 무엇을 fusion하는가”가 다르다. Frustum PointNets는 image-space의 강한 2D detector로 3D point search를 줄이고, MV3D는 metric ground-plane geometry가 드러나는 BEV에서 proposal을 만든 뒤 여러 view의 **feature**를 합친다.

## 5. Perception dataset을 읽는 기준

24–26쪽은 KITTI 3D object detection benchmark를 대표 사례로 든다. 공식 benchmark의 `7,481 training / 7,518 test`는 **KITTI 전체 자료의 총량**이 아니라 image와 대응 point cloud를 가진 **3D object detection benchmark split**이다. Test label은 공개 training label과 같은 방식으로 직접 학습·검증하는 자료가 아니라 evaluation server 제출을 위한 split이므로, 논문의 자체 validation split과 공식 test result를 구분해야 한다.

### 5.1 3D IoU와 leaderboard 숫자 읽기

3D detection은 class뿐 아니라 위치·크기·방향을 맞혀야 한다. Prediction box $$B_p$$와 ground-truth box $$B_g$$의 3D IoU는 다음 **정의**다.

$$
\operatorname{IoU}_{3D}(B_p,B_g)
=
\frac{\operatorname{Vol}(B_p\cap B_g)}
{\operatorname{Vol}(B_p)+\operatorname{Vol}(B_g)-\operatorname{Vol}(B_p\cap B_g)}
$$

분모는 두 volume을 더한 뒤 두 번 센 교집합을 한 번 빼는 inclusion-exclusion으로 얻는다. Volume 단위는 $$\mathrm{m}^3$$지만 같은 단위끼리 나눈 IoU는 무차원이고 $$0\le\operatorname{IoU}_{3D}\le1$$이다. 예를 들어 두 axis-aligned box가 각각 $$4\times2\times1.5=12\ \mathrm{m}^3$$이고 교집합이 $$3\times2\times1.5=9\ \mathrm{m}^3$$이면 union은 $$12+12-9=15\ \mathrm{m}^3$$, IoU는 $$9/15=0.6$$이다. Oriented box에서는 ground-plane polygon 교집합과 높이 overlap을 함께 계산해야 한다.

26쪽 leaderboard와 Frustum PointNets 표는 서로 다른 시점의 snapshot이다. Leaderboard는 계속 갱신되고 metric·difficulty·data policy가 달라질 수 있으므로, 이 글은 해당 순위와 성능 수치를 현재 사실로 옮기지 않는다. 같은 이름의 KITTI라도 2D, BEV, 3D, tracking task의 metric이 다르다는 점도 확인해야 한다.

### 5.2 27쪽의 dataset 표가 보여 주는 범위

27쪽은 2008–2019년 dataset을 sensor·annotation·날씨·지도·class·지역 축으로 비교한다. 표에 나온 이름은 다음과 같다.

- Image 중심: CamVid, Cityscapes, Vistas, BDD100K, ApolloScape, D²-City.
- Point cloud 또는 multimodal 항목을 포함한 행: KITTI, AS lidar, KAIST, H3D, nuScenes, Argoverse, Lyft L5, Waymo Open, A³D, A2D2.

따라서 이 표 전체를 “multimodal 3D detection dataset 목록”으로 부르면 안 된다. 앞부분에는 image-only dataset이 포함되고, 뒤쪽도 dataset version과 task에 따라 sensor·label 범위가 달라진다. 표의 숫자는 강의 자료가 인용한 당시 survey snapshot으로만 읽고, 실제 실험을 설계할 때는 공식 version과 task page를 다시 확인해야 한다.

강의 이후에도 자주 비교되는 세 사례를 공식 자료 기준으로 읽으면 다음과 같다.

| Dataset | 강의와 연결되는 핵심 | 숫자를 읽을 때의 주의 |
|---|---|---|
| KITTI | Image와 LiDAR point cloud의 고전적 3D detection benchmark | 7,481/7,518은 object benchmark split이지 전체 KITTI 규모가 아님 |
| nuScenes | Camera·LiDAR·radar·map·pose를 포함하는 multi-sensor dataset | `sample`, intermediate `sweep`, annotated keyframe 수를 섞지 말아야 함 |
| Waymo Open Dataset | 동기화·보정된 camera와 LiDAR, 2D·3D detection/tracking | 초기 공개 논문의 1,150 scene과 이후 확장된 공식 release 규모를 구분해야 함 |

Dataset 선택에서는 단순히 “더 크다”보다 **sensor suite, calibration·timestamp 제공, annotation 좌표계, class taxonomy, weather·location diversity, official split, evaluation metric**이 목표 모델과 맞는지를 먼저 본다.

## Source Check

| 위치 | 판정 | 확인과 이 글의 처리 |
|---|---|---|
| 1쪽 `10. PERCEPTION (8)` | 표지 numbering 불일치 | 제공 파일명은 `11 3D Perception (3).pdf`이고 내용은 multimodal 3D detection 후속 강의다. 글 제목은 Lecture 11로 정리하되 원본 PDF는 변경하지 않았다. |
| 3쪽 과제 공지 | 행정 페이지 | 전체 흐름에는 존재를 표시했지만 마감·제출 안내는 학습 본문에서 생략했다. |
| 12쪽 `RGB point cloud` | 표현상 단순화 | RGB-only point가 아니라 RGB-D와 calibration으로 2D proposal에 연결된 frustum point cloud로 설명했다. |
| 11–14쪽 좌표 변환 도식 | 단계가 합쳐져 보일 수 있음 | Frustum rotation은 segmentation 전에 view angle을 정규화한다. 이후 centroid subtraction과 T-Net translation을 별도 단계로 구분했다. |
| 13쪽 centroid와 box center 정렬 | 학습 결과를 단정하기 쉬운 표현 | T-Net은 translation residual을 예측해 center 차이를 줄인다. 정확한 일치는 보장되지 않는다. |
| 14쪽 box parameter의 마지막 `y` | 기호 중복·오기 가능성 | 위치 $$y$$와 구분하기 위해 Frustum PointNets 원 논문의 heading $$\theta$$를 사용했다. |
| 17쪽 BEV에서 physical size 유지 | 조건이 생략된 설명 | Calibrated orthographic BEV grid에서 cell quantization 범위로 footprint가 보존된다고 한정했다. |
| 17쪽 3D box가 서로 겹치지 않음 | 일반적으로 거짓인 단정 | Perspective overlap은 줄지만 multi-level scene, 실제 footprint overlap, loose proposal에서는 BEV box도 겹칠 수 있다고 정정했다. |
| 20쪽 deep fusion의 `M` | 단일 평균으로 오해하기 쉬운 도식 | 원 논문의 recurrence에 따라 각 layer가 공통 fused hidden input을 받고, view별 transformation 결과를 element-wise mean으로 다시 결합한다고 풀어 썼다. |
| 19–21쪽 box refinement | 회귀 target 세부 정의 생략 | 원 논문을 확인해 proposal 대각선으로 정규화한 8개 corner의 24개 offset으로 보강했다. |
| 22·24쪽 검은 embedded-media 영역 | 시각 내용 미확인 | 렌더 결과로 세부 내용을 확인할 수 없어 앞뒤의 명시적 text와 figure만 사용했다. |
| 25쪽 `현재까지 21,000회 이상 인용` | 시점 의존 주장 | 강의 작성 시점의 검색 snapshot이므로 현재 인용 수로 재진술하지 않았다. |
| 25쪽 `7,481 / 7,518` | 범위가 생략된 수치 | KITTI 전체 규모가 아니라 공식 3D object detection benchmark의 train/test image-point-cloud split으로 한정했다. |
| 26쪽 leaderboard | 시간에 따라 변하는 snapshot | 현재 순위나 최신 성능의 증거로 사용하지 않고 benchmark 해석 예로만 다뤘다. |
| 27쪽 dataset 표 | 역사적 survey snapshot | Image-only dataset도 포함한다. 행의 숫자를 최신 규모로 일반화하지 않고 공식 dataset page의 version·task 확인을 요구했다. |

## 핵심 복습 포인트

- LiDAR 점을 RGB pixel로 옮기는 $$\mathbf T_{C\leftarrow L}$$와 pinhole projection의 역할, 단위, $$Z_C>0$$ 조건을 설명한다.
- Sensor time offset이 왜 meter 단위 위치 오차로 커질 수 있는지 $$\Delta s\approx v\Delta t$$로 계산한다.
- Frustum PointNets의 **2D proposal → frustum rotation → point segmentation → centroid subtraction → T-Net translation → amodal box** 순서를 그리고 세 좌표 변환의 목적을 구분한다.
- $$\mathbf C_{\mathrm{pred}}=\mathbf C_{\mathrm{mask}}+\Delta\mathbf C_{\mathrm{T\text{-}Net}}+\Delta\mathbf C_{\mathrm{box}}$$의 세 항을 구분한다.
- Frustum PointNets의 출력 차원 $$3+4N_S+2N_H$$가 center·size·heading의 class와 residual에서 어떻게 나오는지 설명한다.
- MV3D가 BEV에서 proposal을 만들고 세 view에서 RoI pooling을 하는 이유를 말한다.
- Early, late, deep fusion을 **결합 위치와 interaction 횟수**로 비교하고, deep fusion의 각 branch가 같은 $$\mathbf f_{l-1}$$를 입력받는 recurrence를 설명한다.
- MV3D의 oriented box 회귀가 proposal 대각선으로 정규화한 여덟 corner의 $$24$$개 offset인 이유를 설명한다.
- KITTI의 7,481/7,518이 무엇의 split인지, leaderboard snapshot을 현재 성능으로 그대로 인용하면 안 되는 이유를 설명한다.

## 마지막 핵심 정리

Multimodal 3D detection의 핵심은 센서를 많이 쓰는 것이 아니라 **상보적 정보를 올바르게 대응시키는 것**이다. Frustum PointNets는 RGB detector가 만든 2D hypothesis로 3D point search를 좁히고, MV3D는 BEV가 만든 3D proposal을 여러 view의 RoI feature와 결합한다. 두 방법 모두 calibration, synchronization, proposal 품질에 의존하며 한 단계의 누락이나 misalignment가 뒤 단계로 전파된다. Dataset 결과를 비교할 때도 sensor·split·task·metric·version이 같아야 숫자가 의미를 갖는다.

## Study Guide

먼저 9쪽에서 camera와 LiDAR의 강점·한계를 한 문장씩 쓰고, calibration 식으로 LiDAR point 하나를 pixel로 직접 투영한다. 다음으로 11–14쪽을 보며 `camera → frustum → mask → object coordinate` 변환과 세 network, center 합성식을 순서대로 그린다. 15–21쪽에서는 한 3D proposal이 BEV·FV·RGB의 세 RoI가 되는 경로를 따라간 뒤, deep fusion recurrence에서 공통 hidden state가 각 view branch로 되먹임되는 위치와 24-D corner target을 표시한다. 마지막으로 25–27쪽에서 dataset 이름보다 **공식 split, sensor suite, task, metric, version**을 먼저 확인하는 습관을 익힌다. Source Check의 11–14·17·20·25·27쪽 항목은 원문 문구를 그대로 암기하지 않기 위한 필수 보정이다.

## 복습 질문

<details markdown="block">
<summary>1. Camera와 LiDAR feature를 합치기 전에 반드시 확인해야 할 세 가지 정렬은 무엇인가?</summary>

답변: Extrinsic·intrinsic을 이용한 공간 calibration, ego/object motion을 고려한 시간 synchronization, 같은 3D proposal에서 각 modality의 같은 객체 영역을 뽑는 representation alignment다. Vector 길이만 같게 만든다고 공간과 시간이 자동으로 맞는 것은 아니다.

</details>

<details markdown="block">
<summary>2. Frustum PointNets에서 2D detector가 물체를 놓치면 뒤 PointNet이 복구하기 어려운 이유는 무엇인가?</summary>

답변: 2D box가 3D frustum을 정의하고 그 안의 점만 뒤 단계로 전달하기 때문이다. 2D proposal이 없으면 관심 물체를 위한 frustum point cloud 자체가 만들어지지 않는다.

</details>

<details markdown="block">
<summary markdown="span">3. Frustum rotation, centroid subtraction, T-Net translation은 각각 무엇을 정규화하는가?</summary>

답변: Frustum rotation은 segmentation 전에 중심 ray를 camera 정면축과 맞춰 view angle을 정규화한다. Centroid subtraction은 segmentation 뒤 foreground point 평균을 원점으로 옮긴다. T-Net은 그 mask centroid와 amodal box center 사이의 translation residual을 학습해 object coordinate로 보정한다.

</details>

<details markdown="block">
<summary markdown="span">4. Frustum PointNets의 출력 차원이 왜 $$3+4N_S+2N_H$$인가?</summary>

답변: Center residual 3개, size class $$N_S$$개와 각 class의 3차원 size residual $$3N_S$$개, heading class $$N_H$$개와 각 bin의 residual $$N_H$$개를 더하기 때문이다.

</details>

<details markdown="block">
<summary>5. MV3D가 3D proposal을 RGB image에서가 아니라 LiDAR BEV에서 만드는 이유는 무엇인가?</summary>

답변: Calibrated BEV grid에서는 ground-plane footprint가 perspective distance에 따라 급격히 축소되지 않고 metric geometry가 드러나므로 3D proposal 생성에 유리하다. 다만 BEV box가 절대 겹치지 않거나 quantization 없이 크기를 보존한다는 뜻은 아니다.

</details>

<details markdown="block">
<summary>6. RoI pooling 뒤 vector 길이가 같으면 multimodal alignment가 끝난 것인가?</summary>

답변: 아니다. RoI pooling은 tensor shape을 맞추지만 calibration, timestamp, proposal 위치가 틀리면 각 vector는 서로 다른 공간·시간의 내용을 담는다. Shape alignment와 semantic alignment를 구분해야 한다.

</details>

<details markdown="block">
<summary markdown="span">7. MV3D deep fusion에서 세 view branch가 $$l$$번째 layer에 받는 입력은 무엇이며, 출력은 어떻게 합쳐지는가?</summary>

답변: 세 branch 모두 동일한 이전 fused hidden state $$\mathbf f_{l-1}$$를 입력받는다. 각 view별 transformation 결과는 element-wise mean으로 다시 $$\mathbf f_l$$이 되고, 이 fused state가 다음 layer의 모든 branch에 전달된다.

</details>

<details markdown="block">
<summary markdown="span">8. MV3D의 oriented 3D box regression target이 24차원인 이유와 proposal 대각선으로 나누는 이유는 무엇인가?</summary>

답변: 여덟 corner마다 $$x,y,z$$ offset 세 개를 예측하므로 $$8\times3=24$$차원이다. 각 offset을 proposal의 3D 대각선 길이로 나누면 target이 무차원이 되고 proposal scale에 대한 민감도가 줄어든다.

</details>

<details markdown="block">
<summary>9. KITTI의 7,481 training과 7,518 test를 “KITTI 전체 크기”라고 말하면 왜 틀리는가?</summary>

답변: 그 수치는 공식 3D object detection benchmark에 속한 image와 대응 point cloud의 train/test split이다. KITTI에는 다른 task와 raw data가 별도로 있으므로 dataset 전체 규모와 동일하지 않다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 11 source slides (PDF)</a></li>
</ul>

## References

- <a href="https://openaccess.thecvf.com/content_cvpr_2018/html/Qi_Frustum_PointNets_for_CVPR_2018_paper.html" target="_blank" rel="noopener">Qi et al., Frustum PointNets for 3D Object Detection From RGB-D Data</a> — frustum proposal, 3D instance segmentation, T-Net center 보정, amodal box parameterization.
- <a href="https://openaccess.thecvf.com/content_cvpr_2017/html/Chen_Multi-View_3D_Object_CVPR_2017_paper.html" target="_blank" rel="noopener">Chen et al., Multi-View 3D Object Detection Network for Autonomous Driving</a> — BEV proposal과 region-based deep fusion.
- <a href="https://www.cvlibs.net/datasets/kitti/eval_object.php?obj_benchmark=3d" target="_blank" rel="noopener">KITTI 3D Object Detection Evaluation</a> — 공식 train/test 규모, data format, evaluation page.
- <a href="https://www.nuscenes.org/" target="_blank" rel="noopener">nuScenes official dataset</a> — camera·LiDAR·radar·map을 포함한 sensor suite와 dataset 구성.
- <a href="https://waymo.com/research/scalability-in-perception-for-autonomous-driving-waymo-open-dataset/" target="_blank" rel="noopener">Sun et al., Scalability in Perception for Autonomous Driving: Waymo Open Dataset</a> — 초기 공개본의 동기화·보정된 camera–LiDAR 구성과 annotation.
