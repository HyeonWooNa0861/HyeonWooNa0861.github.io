---
layout: default
date: 2026-10-14 13:17:33 +0900
last_modified_at: 2026-10-18 16:22:58 +0900
title: "Autonomous Driving Computing Midterm Review through Lab 2"
course: "Autonomous Driving"
topic: "Sensors, 2D and 3D Perception, Lab 1, and Lab 2"
order: 14
major_topic: "Autonomous Systems"
keywords:
  - "Autonomous Driving"
  - "Sensor Geometry"
  - "Object Detection"
  - "Average Precision"
  - "Faster R-CNN"
  - "RetinaNet"
  - "VoxelNet"
  - "LiDAR"
  - "Sensor Fusion"
---

# Autonomous Driving Computing Midterm Review through Lab 2

Source Materials: Lectures 2–11, Labs 1–2, and Assignment 1 (Average Precision).

> **핵심:** 자율주행 perception은 센서가 만든 측정값을 좌표계가 있는 표현으로 바꾸고, 그 표현에서 객체의 종류·위치·형상을 추정한 뒤, 정답과 같은 규칙으로 평가하는 과정이다. 2D 검출에서는 feature, anchor, IoU, NMS와 AP가 이 흐름을 연결한다. 3D 검출에서는 camera ray의 깊이 모호성, LiDAR의 희소성, voxel·point·BEV 표현, calibration과 fusion이 추가된다. Lab 1은 Faster R-CNN과 RetinaNet의 2D 검출 흐름을, Lab 2는 실제 KITTI point cloud의 표현과 합성 데이터에서 학습한 VoxelNet 흐름을 코드 수준에서 추적한다.

**이 총정리의 복습 범위는 Lecture 2–11과 Lab 1–2다.** Lab 1의 풀이·출력은 Assignment 2 notebook에, Lab 2의 풀이·출력은 Assignment 3 notebook에 담겨 있다. 시험 범위에 관한 별도 공지가 있으면 그 공지를 우선한다.

## 전체 흐름

| 순서 | 주제 | 반드시 답할 질문 |
|---:|---|---|
| 1 | Sensor와 geometry | 각 센서는 무엇을 직접 측정하며, 어느 좌표계에 있는가? |
| 2 | 2D perception task | Classification, localization, detection, segmentation의 출력은 어떻게 다른가? |
| 3 | Detection metric | IoU, NMS, precision, recall, AP는 각각 어느 단계에서 쓰이는가? |
| 4 | 2D detector 계보 | R-CNN에서 Faster R-CNN, RetinaNet, YOLO, FCOS까지 무엇이 공유되고 무엇이 달라지는가? |
| 5 | 3D perception | Camera, LiDAR, fusion 방식은 깊이와 3D box를 어떻게 얻는가? |
| 6 | Lab 1 | Tensor, anchor label, box target, focal loss와 plot을 어떻게 읽는가? |
| 7 | Lab 2 | KITTI 좌표 변환, voxelization, VFE, 3D convolution, BEV head와 loss가 어떻게 이어지는가? |

## 1. Sensor: 모델보다 먼저 측정값을 이해한다

### 1.1 Camera, LiDAR, RADAR가 직접 주는 것

| Sensor | 직접 측정하는 핵심 정보 | 강점 | 대표 실패 조건 |
|---|---|---|---|
| Camera | 영상 평면의 색·밝기·texture | 높은 각해상도, class와 표지·신호 의미 | 조도, glare, 안개·비, metric depth 모호성 |
| Stereo camera | 두 camera의 대응 pixel disparity | calibration과 대응점이 맞으면 metric depth | texture 부족, occlusion, 작은 disparity의 큰 깊이 오차 |
| LiDAR | laser 왕복 시간으로 얻은 3D surface point와 reflectance | 직접적인 3D geometry와 거리 | 원거리 희소성, 가림, 날씨·반사 재질, 비용 |
| RADAR | radio wave의 range·relative velocity·angle | 장거리와 Doppler 속도, 악천후 견고성 | 낮은 각해상도, multipath, object shape 해석 한계 |

센서 하나의 장점이 perception 전체의 정확성을 보장하지 않는다. Calibration, timestamp 정렬, ego-motion 보정, 표현 변환, 모델, 후처리와 평가까지 맞아야 한다.

### 1.2 Pinhole projection: 3D point가 pixel이 되는 과정

World point의 homogeneous coordinate를 $$\tilde{X}_w=[X_w,Y_w,Z_w,1]^{\top}$$라 하자. Extrinsic matrix가 world에서 camera로, intrinsic matrix $$K$$가 camera ray를 pixel로 바꾼다.

$$
s\begin{bmatrix}u\\v\\1\end{bmatrix}
=K[R\mid t]\tilde{X}_w
$$

여기서 $$u,v$$는 pixel coordinate, $$s$$는 camera depth에 비례하는 scale이다. Distortion을 무시한 pinhole model이며 camera 앞의 point는 camera-frame depth가 양수여야 한다. 같은 pixel $$[u,v]$$는 한 3D point가 아니라 camera center에서 뻗는 **ray 전체**를 나타낸다. 따라서 단안 영상만으로 metric depth를 유일하게 정할 수 없다.

작은 trace를 보자. Camera intrinsic이 $$f_x=f_y=800\ \mathrm{px}$$, principal point가 $$(c_x,c_y)=(640,360)\ \mathrm{px}$$이고 camera point가 $$(X,Y,Z)=(2,1,20)\ \mathrm{m}$$이면

$$
\begin{aligned}
u&=f_x\frac{X}{Z}+c_x=720,\\
v&=f_y\frac{Y}{Z}+c_y=400.
\end{aligned}
$$

같은 $$X/Z$$와 $$Y/Z$$를 가진 $$(4,2,40)$$도 같은 pixel에 투영된다. 이것이 scale–distance ambiguity다.

<details markdown="block">
<summary markdown="span">Derivation: Camera projection and inverse ray</summary>

Camera coordinate $$(X_c,Y_c,Z_c)$$에서 normalized coordinate는

$$
x_n=X_c/Z_c,\qquad y_n=Y_c/Z_c
$$

다. Intrinsic matrix를

$$
K=\begin{bmatrix}
f_x&0&c_x\\
0&f_y&c_y\\
0&0&1
\end{bmatrix}
$$

로 두면 $$u=f_xx_n+c_x$$, $$v=f_yy_n+c_y$$가 된다. 반대로 pixel과 depth $$Z_c$$가 주어지면

$$
\begin{aligned}
X_c&=(u-c_x)Z_c/f_x,\\
Y_c&=(v-c_y)Z_c/f_y.
\end{aligned}
$$

로 역투영할 수 있다. Depth가 없으면 $$Z_c$$가 자유 변수이므로 ray만 정해진다. Lens distortion이 크거나 calibration이 틀리면 이 식을 그대로 적용할 수 없다.

</details>

### 1.3 Stereo depth와 불확실성

광축이 평행하고 rectification을 마쳤으며 두 camera의 matched intrinsic과 principal-point convention을 사용하는 stereo에서, 같은 3D point의 left·right horizontal pixel 차이를 disparity $$d=u_L-u_R$$라 하면

$$
Z=\frac{fB}{d}
$$

다. $$f$$는 pixel 단위 focal length, $$B$$는 meter 단위 baseline, $$d$$는 pixel이므로 $$Z$$는 meter다. Disparity가 작아지는 원거리에서 깊이 오차가 빠르게 커진다.

예를 들어 $$f=700\ \mathrm{px}$$, $$B=0.54\ \mathrm{m}$$, $$d=35\ \mathrm{px}$$이면 $$Z=10.8\ \mathrm{m}$$다. Disparity 오차가 약 $$1\ \mathrm{px}$$이면 1차 근사 깊이 오차 크기는

$$
\lvert\Delta Z\rvert\approx\frac{fB}{d^2}\lvert\Delta d\rvert
=0.309\ \mathrm{m}
$$

다. 같은 $$1\ \mathrm{px}$$ 오차가 $$d=7\ \mathrm{px}$$인 원거리에서는 약 $$7.71\ \mathrm{m}$$로 커진다.

<details markdown="block">
<summary markdown="span">Derivation: Why stereo depth becomes unstable far away</summary>

정확한 식 $$Z=fB/d$$를 $$d$$에 대해 미분하면

$$
\frac{\partial Z}{\partial d}=-\frac{fB}{d^2}.
$$

작은 disparity perturbation에서

$$
\Delta Z\approx-\frac{fB}{d^2}\Delta d
$$

다. 이 식은 local linear approximation이다. Correspondence가 완전히 틀리거나 occlusion으로 대응점이 없으면 작은 오차 근사가 아니라 잘못된 depth 자체가 생긴다.

</details>

### 1.4 LiDAR range와 sensor uncertainty

Laser 왕복 시간차가 $$\Delta t$$이면 range는

$$
r=\frac{c\Delta t}{2}
$$

다. 빛이 물체까지 갔다가 돌아오므로 2로 나눈다. $$c$$는 빛의 속도다. 실제 point cloud의 오차는 시간 측정만이 아니라 beam divergence, reflectance, incidence angle, motion distortion, calibration과 synchronization에도 영향을 받는다.

| 불확실성 | 관측에 미치는 영향 | 대응 |
|---|---|---|
| Camera calibration error | 3D point와 pixel이 어긋남 | Intrinsic·extrinsic 재보정, reprojection error 확인 |
| Timestamp mismatch | 이동 중 sensor frame이 서로 다른 장면을 봄 | 시간 동기화, ego pose interpolation, LiDAR deskew |
| Stereo correspondence error | disparity와 depth가 크게 틀림 | confidence·occlusion 처리, multi-scale matching |
| LiDAR sparsity | 원거리·작은 물체의 point가 부족함 | multi-frame aggregation, point·voxel 설계, uncertainty 반영 |
| RADAR multipath | 실제 물체가 아닌 위치·속도 반응 | tracking과 map context, sensor fusion |

## 2. Perception task는 출력 단위가 다르다

| Task | 입력 | 출력 | 핵심 질문 |
|---|---|---|---|
| Classification | 이미지 하나 | 이미지 전체 class score | 무엇인가? |
| Localization | 이미지 하나 | 주 물체 class와 box 하나 | 무엇이며 어디인가? |
| Object detection | 이미지 하나 | 개수가 변하는 class·box·score 집합 | 무엇이 각각 어디에 몇 개인가? |
| Semantic segmentation | 이미지 하나 | pixel마다 semantic class | 각 pixel은 어느 종류인가? |
| Instance segmentation | 이미지 하나 | object instance마다 class·box·mask | 같은 class의 개체를 어떻게 분리하는가? |

CNN은 spatial neighborhood에 같은 filter를 공유해 local feature를 추출한다. ResNet은 residual path로 깊은 network의 optimization을 돕는다. Vision Transformer는 image patch를 token으로 바꾸고 positional embedding을 더한 뒤 self-attention으로 token 사이의 context를 계산한다. CNN과 ViT의 feature는 detector나 segmentation head가 사용할 backbone representation이 된다.

Task가 바뀌면 label과 loss도 바뀐다. Classification의 single class label만으로 detection의 box regression을 학습할 수 없다. Detection box만으로 semantic segmentation의 모든 pixel label을 직접 감독할 수도 없다.

## 3. Detection의 공통 문법: IoU, NMS, precision, recall, AP

### 3.1 IoU는 두 box의 겹침 비율이다

$$
\operatorname{IoU}(A,B)=\frac{\operatorname{area}(A\cap B)}{\operatorname{area}(A\cup B)}.
$$

예측 box $$A=[0,0,4,4]$$와 GT box $$B=[2,0,6,4]$$를 생각하자. 두 box의 넓이는 각각 16이고 교집합은 $$2\times4=8$$이다. 합집합은 $$16+16-8=24$$이므로 IoU는 $$8/24=1/3$$이다. IoU threshold가 0.5면 이 예측은 match가 아니다.

IoU는 세 곳에서 다른 역할을 한다.

1. Anchor와 GT를 positive·negative·ignore로 나눌 수 있다.
2. Detection을 GT와 match해 TP·FP를 정할 수 있다.
3. NMS에서 예측끼리 중복 여부를 판단할 수 있다.

같은 IoU라도 **anchor–GT**, **prediction–GT**, **prediction–prediction** 중 무엇을 비교하는지 먼저 확인한다.

### 3.2 NMS는 정답 판정이 아니라 중복 억제다

Class별 NMS의 기본 흐름은 다음과 같다.

1. 가장 높은 score의 box를 남긴다.
2. 남긴 box와 IoU가 threshold보다 큰 같은 class box를 제거한다.
3. 남은 box에서 반복한다.

Score 0.95인 box와 score 0.90인 box의 IoU가 0.70이고 NMS threshold가 0.50이면 두 번째 box를 억제한다. Score 0.82인 세 번째 box의 IoU가 0.20이면 남긴다. NMS는 두 box가 실제로 같은 물체라는 것을 증명하지 않는다. 가까이 겹친 두 객체를 잘못 합치거나, 한 객체의 서로 덜 겹친 중복 box를 모두 남길 수 있다.

### 3.3 Precision과 recall은 서로 다른 실패를 본다

$$
\mathrm{Precision}=\frac{TP}{TP+FP},\qquad
\mathrm{Recall}=\frac{TP}{TP+FN}.
$$

Precision은 내놓은 검출 중 맞은 비율이다. Recall은 실제 객체 중 찾아낸 비율이다. Score threshold를 높이면 보통 FP가 줄어 precision이 오르지만 TP도 줄어 recall이 내려갈 수 있다.

### 3.4 AP worked example

한 image에 GT가 4개 있고 confidence 순서의 prediction 결과가 `TP, FP, TP, TP, FP`라고 하자. 각 prediction은 **같은 image의 같은 class에 속한 아직 사용하지 않은 GT**와만 match한다. 중복 prediction은 이미 매칭된 GT에 다시 붙을 수 없으므로 FP다.

| 순위 | 결과 | 누적 TP | 누적 FP | Precision | Recall |
|---:|---|---:|---:|---:|---:|
| 1 | TP | 1 | 0 | 1.000 | 0.25 |
| 2 | FP | 1 | 1 | 0.500 | 0.25 |
| 3 | TP | 2 | 1 | 0.667 | 0.50 |
| 4 | TP | 3 | 1 | 0.750 | 0.75 |
| 5 | FP | 3 | 2 | 0.600 | 0.75 |

Monotonic precision envelope를 쓰는 all-points interpolation에서 recall 0.25, 0.50, 0.75의 증가분마다 이후 최대 precision은 1.00, 0.75, 0.75다. 최대 recall이 0.75라 나머지 구간의 precision은 0이다.

$$
AP=0.25(1.00)+0.25(0.75)+0.25(0.75)=0.625.
$$

AP는 한 score threshold의 precision이나 recall이 아니다. IoU threshold, class, interpolation 방식, 데이터 split이 달라지면 AP도 달라진다. mAP는 정의된 class 또는 IoU threshold들의 AP를 평균한 값이므로 평가 protocol을 같이 적어야 한다.

<details markdown="block">
<summary markdown="span">Derivation: Confidence sorting, one-to-one matching, and AP</summary>

각 image와 class 안에서 prediction을 score 내림차순으로 처리한다. 같은 image의 아직 사용하지 않은 같은 class GT 중 IoU가 가장 큰 것을 찾고, 그 IoU가 평가 threshold 이상이면 TP로 만들며 해당 GT를 사용 처리한다. 조건을 만족하지 않거나 이미 사용한 GT를 다시 검출하면 FP다. 그 뒤 dataset 전체 prediction을 confidence 순으로 모아 PR curve를 만든다.

누적 precision과 recall을 만든 뒤 precision envelope를

$$
p_{\mathrm{interp}}(r)=\max_{\tilde{r}\ge r}p(\tilde{r})
$$

로 정의한다. Recall이 증가한 구간의 폭과 해당 envelope 높이를 곱해 합하면 AP를 얻는다. Dataset과 benchmark에 따라 11-point, 101-point 또는 모든 recall 변화점을 쓰므로 숫자를 비교할 때 protocol이 같아야 한다.

</details>

## 4. 2D detector 계보를 같은 축으로 비교하기

### 4.1 R-CNN에서 Faster R-CNN까지

| Model | Proposal | Feature 계산 | Head | 핵심 병목·개선 |
|---|---|---|---|---|
| R-CNN | Selective Search | proposal마다 CNN 반복 | class + box regression | 약 2,000개 region의 반복 계산과 분리된 학습 |
| Fast R-CNN | Selective Search | 이미지 전체 feature map 1회 | RoI pooling 뒤 class + box | feature 공유. Proposal 생성은 여전히 외부 CPU 과정 |
| Faster R-CNN | 학습되는 RPN | backbone feature 공유 | RPN 뒤 RoI head | Anchor objectness·box regression으로 proposal도 학습 |
| Faster R-CNN + FPN | RPN | P2–P6 같은 multi-scale feature | scale에 맞는 level에서 RoI 처리 | 낮은 층의 spatial detail과 높은 층의 semantics 결합 |

Two-stage는 backbone을 반드시 두 번 실행한다는 뜻이 아니다. 첫 단계가 object proposal을 고르고 두 번째 단계가 proposal을 다시 classifying·refining한다는 뜻이다.

FPN의 핵심은 backbone의 bottom-up feature만 나열하는 것이 아니다. 높은 level을 upsample하고 lateral connection으로 낮은 level feature와 합쳐, 각 pyramid level이 비교적 강한 semantics와 서로 다른 spatial resolution을 함께 갖게 한다.

### 4.2 RetinaNet, YOLO, FCOS

| Model | Candidate 표현 | Class imbalance 대응 | Box 표현 | 기억할 점 |
|---|---|---|---|---|
| RetinaNet | FPN의 dense anchor | Focal loss, low prior probability | Anchor offset | One-stage anchor-based detector |
| YOLO | Dense grid·feature location | 버전별 objectness·assignment·loss | 버전별 anchor-based 또는 anchor-free | `한 번 본다`는 이름보다 사용 버전의 label assignment와 head 확인 |
| FCOS | FPN location point | Focal loss와 center sampling 계열 | Point에서 left·top·right·bottom 거리 | Anchor-free. Centerness가 경계 위치의 낮은 품질 box를 억제 |

RetinaNet의 binary focal loss는

$$
FL(p_t)=-\alpha_t(1-p_t)^{\gamma}\log p_t
$$

다. 잘 맞춘 쉬운 예제는 $$p_t\to1$$일 때 $$(1-p_t)^{\gamma}$$가 작아져 loss 기여가 줄어든다. Focal loss는 negative를 삭제하지 않는다. 쉬운 negative의 gradient 비중을 줄인다.

FCOS는 feature location이 GT box 안에 있으면 그 위치에서 box 네 변까지 거리 $$(l,t,r,b)$$를 예측한다. Box 경계 가까운 위치는 한쪽 거리가 작고 localization quality가 낮기 쉬워 centerness로 score를 조절한다. Anchor가 없다고 candidate나 assignment가 사라지는 것은 아니다.

## 5. Segmentation: box보다 더 촘촘한 출력

Semantic segmentation은 같은 class의 두 차량을 같은 `car` pixel class로 표시할 수 있다. Instance segmentation은 차량마다 별도 mask를 낸다. Road·sky처럼 셀 수 없는 영역은 보통 stuff, car·person처럼 개체 단위가 중요한 대상은 thing으로 구분한다.

FCN은 fully connected layer 대신 convolutional prediction을 사용해 spatial score map을 만든다. Downsampling은 큰 receptive field와 semantic context를 얻지만 경계를 흐릴 수 있다. Transposed convolution이나 interpolation과 skip connection은 resolution을 복원한다.

1D에서 input `[a,b]`, kernel `[k_0,k_1,k_2]`, stride 2인 transposed convolution은 각 input이 kernel 모양을 output 위치에 더한다. 겹치는 위치는 합산된다. Input 사이에 0을 넣고 적절한 kernel 방향과 padding을 적용하는 계산으로도 볼 수 있다. Output size는 padding·output padding까지 확인해야 한다.

Mask R-CNN은 Faster R-CNN의 proposal·classification·box 경로에 RoI별 mask branch를 추가한다. RoIAlign은 quantization을 줄여 pixel mask와 feature의 정렬을 돕는다. Class별 binary mask loss와 semantic segmentation의 pixel softmax를 같은 것으로 보면 안 된다.

## 6. 3D perception: 깊이와 방향이 추가된다

### 6.1 3D box와 좌표계

Lab 2가 쓰는 LiDAR box는 $$(x,y,z,l,w,h,\theta)$$다. $$(x,y,z)$$는 box center, $$l,w,h$$는 길이·너비·높이, $$\theta$$는 yaw다. 그러나 dataset과 library마다 다음이 다를 수 있다.

- 축 방향: Camera는 흔히 $$x$$ right, $$y$$ down, $$z$$ forward이고, LiDAR는 $$x$$ forward, $$y$$ left, $$z$$ up을 쓴다.
- 위치 기준: KITTI camera label의 location은 bottom center다. Lab 2 helper는 box center로 바꾼다.
- Dimension 순서: `h,w,l`, `l,h,w`, `l,w,h`가 혼재한다.
- Yaw 기준축과 양의 회전 방향이 다르다.

수치만 복사하지 말고 coordinate convention을 먼저 고정해야 한다.

### 6.2 Image-based 3D detection

| Method | 핵심 입력·가정 | 처리 | 한계 |
|---|---|---|---|
| Mono3D | RGB, road·class prior | 3D candidate를 만들고 image에 projection해 semantic·shape·context·location feature로 scoring | Candidate와 prior 품질에 의존 |
| MonoRCNN | RGB, 물리 높이와 투영 높이에 관한 예측 | 높이와 PCL의 역수로 depth를 복원하고 각 성분의 uncertainty를 학습 | 단안 scale ambiguity가 사라지는 것이 아니라 learned prior로 줄어듦 |
| Pseudo-LiDAR | Stereo 또는 monocular depth map | Pixel depth를 camera-frame 3D point로 역투영한 뒤 point-cloud detector 사용 | Depth error가 3D 위치 error로 변환됨 |

**Mono3D의 class semantic은 ‘어떤 종류인가’, instance semantic은 ‘같은 종류 중 어느 개체인가’를 구분한다.** [Lecture 9 p. 24](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=24)의 class map에서는 차량들이 같은 색이고, instance map에서는 차량마다 색이 다르다. 따라서 후보가 차량 영역을 덮는지만 보는 것과 한 차량의 영역에 맞는지 보는 것은 다르다. 이 정보는 projection된 3D 후보의 점수를 매기는 데 쓰이며, instance 색은 실제 차체 색이나 시간에 걸친 tracking ID가 아니다.

MonoRCNN은 [Lecture 9 p. 27](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=27)의 물리 높이 $$H$$와 영상에 투영된 중심 수직선의 길이 $$h$$를 이용한다. 보정된 pinhole camera에서 그 선의 두 끝점이 같은 depth를 갖는 수직선 모델이면

$$
Z=\frac{f_yH}{h}=f_yHh_{\mathrm{rec}},\qquad h_{\mathrm{rec}}=\frac{1}{h}
$$

다. $$Z,H$$는 m, 세로 초점거리 $$f_y$$와 $$h$$는 pixel, $$h_{\mathrm{rec}}$$은 pixel의 역수다. **$$h$$는 2D detection box 전체 높이가 아니라 PCL(projected central line) 길이**다. Network는 $$H$$와 $$h_{\mathrm{rec}}$$ 및 각 uncertainty를 예측하고 이 관계로 depth를 복원한다. 같은 높이의 물체라면 PCL이 짧을수록 멀리 있다는 뜻이다. <a href="https://arxiv.org/html/2104.03775" target="_blank" rel="noopener">MonoRCNN 원 논문, Figure 1–2</a>도 이 분해와 예측 대상을 구분한다.

<details markdown="block">
<summary markdown="span">Derivation: Depth from physical and projected height</summary>

중심 수직선의 위·아래 끝점이 camera 좌표에서 같은 $$X,Z$$를 갖고 $$Y$$만 $$H$$만큼 다르면, pinhole 식 $$v=f_yY/Z+c_y$$에서 두 끝점의 pixel 차이는 $$h=f_yH/Z$$다. 양수인 $$h$$로 나누면 $$Z=f_yH/h$$를 얻는다. Camera roll·pitch나 왜곡을 무시할 수 없는 장면에는 이 단순화의 적용 여부를 먼저 확인해야 한다.

작성자 계산 예시로 $$f_y=800\ \mathrm{px}$$, $$H=1.5\ \mathrm{m}$$, $$h=120\ \mathrm{px}$$이면 $$Z=10\ \mathrm{m}$$다. 다른 조건이 같고 $$h=60\ \mathrm{px}$$이면 $$Z=20\ \mathrm{m}$$다. 두 계산 모두 길이 단위는 m이며, 예측 높이가 틀리면 복원한 depth도 틀릴 수 있다.

</details>

3D IoU는 oriented box의 교집합 volume을 합집합 volume으로 나눈다. BEV IoU만 같아도 height overlap이 다르면 3D IoU는 다르다.

### 6.3 LiDAR-based 3D detection

| Method | 중심 표현 | 핵심 연산 | 장점·제약 |
|---|---|---|---|
| PointNet | Raw point set | Shared MLP + symmetric max pooling | 순서 불변. Local neighborhood 표현은 제한적 |
| PointNet++ | Hierarchical point neighborhoods | Sampling, grouping, local PointNet | Multi-scale local geometry 학습 |
| PointRCNN | Raw points | Point-wise foreground segmentation, point-generated proposal, canonical refinement | 두 단계. Foreground quality가 proposal recall에 영향 |
| VoxelNet | 3D voxel | VFE, sparse-to-dense, 3D convolution, BEV RPN | Learned voxel feature. Dense 3D 계산 비용 |
| PIXOR | BEV height-slice grid | 2D CNN dense oriented box detection | 빠른 BEV 처리. Vertical detail을 channel로 요약 |

PointNet의 permutation invariance는 input point 순서를 바꿔도 shared point function과 symmetric max 결과가 같다는 뜻이다. 모든 rotation·translation에 자동으로 invariant하다는 뜻은 아니다. PointNet++는 local neighborhood를 계층적으로 모아 PointNet의 local structure 약점을 보완한다.

### 6.4 Camera–LiDAR fusion

| Method | Proposal 시작점 | Fusion 위치 | 핵심 흐름 |
|---|---|---|---|
| Frustum PointNets | 2D image detector | 2D box가 만든 3D frustum 안의 points | Point segmentation, mask centroid, T-Net translation, amodal 3D box regression |
| MV3D | LiDAR BEV | BEV·LiDAR front view·RGB RoI feature | BEV 3D proposal을 각 view에 projection하고 deep fusion 후 class·3D box refinement |

Fusion 전에는 공간 calibration, timestamp synchronization, 같은 object region의 대응이 필요하다. Camera와 LiDAR feature를 단순 concatenate해도 좌표와 시간이 어긋나면 같은 물체의 정보가 아니다.

[Lecture 11 p. 20](/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf#page=20)의 fusion 비교는 **언제, 몇 번 결합하는가**로 읽는다. Early fusion은 입력 또는 초기 feature에서, late fusion은 각 stream이 고수준 feature를 만든 뒤 결합한다. Deep fusion은 중간 layer마다 정보를 반복 교환한다. MV3D 그림의 `C`는 concatenation, `M`은 element-wise mean이다. Deep fusion에서는 한 번 합친 hidden state를 다음 단계의 각 view branch가 함께 받아 처리한다.

## 7. Lab 1: Two-stage와 one-stage를 tensor 흐름으로 읽기

<figure id="source-rpn-output">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-assignment2-rpn-proposals.png" | relative_url }}" alt="Init와 COCO 모델의 top 50 RPN proposal과 정답 box" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-02-two-stage-vs-one-stage.ipynb" | relative_url }}">Assignment 2 notebook, cell 27 (0-based), saved output</a>.</figcaption>
</figure>

청록 box는 상위 50개 proposal, 흰 점선은 GT다. 오른쪽 COCO 모델에서 물체 주변으로 후보가 모이는지 왼쪽 초기화 모델과 비교한다. 이 단계는 class를 확정한 최종 detection이 아니므로 proposal 수가 많다고 recall이나 precision이 높다고 단정하지 않는다.

### 7.1 입력에서 FPN까지

Penn–Fudan dataset의 instance mask에서 instance별 foreground pixel의 최소·최대 좌표를 구해 2D box를 만든다. 이미지 transform은 resize, normalization, batch padding을 수행한다. 이 셋을 혼동하면 box coordinate와 feature coordinate를 잘못 비교하게 된다.

Faster R-CNN backbone은 FPN feature P2–P6을, notebook의 RetinaNet은 P3–P7을 사용한다. Level $$l$$의 feature shape가 $$C\times H_l\times W_l$$이고 위치당 anchor template 수가 $$A_l$$이면 해당 level anchor 수는

$$
N_l=H_lW_lA_l.
$$

전체 anchor 수는 $$\sum_lN_l$$이다. Padded image size와 feature shape가 달라지면 anchor 수가 달라지므로 고정 숫자로 외우지 않는다.

### 7.2 Anchor label과 sampling

Anchor는 학습되는 box가 아니라 center, scale, aspect ratio를 가진 기준 box다. RPN의 전형적인 label은 다음과 같다.

- Positive: GT와 높은 IoU를 갖거나 각 GT의 최고-IoU anchor다.
- Negative: 모든 GT와 낮은 IoU를 갖는다.
- Ignore: 그 사이 영역이며 loss에서 제외한다.

각 GT의 최고-IoU anchor를 positive로 보장하는 low-quality match 규칙은 threshold를 넘는 anchor가 없는 GT도 학습 후보를 갖게 한다. 그 뒤 positive·negative 일부를 sampling해 RPN loss를 계산한다. `전체 anchor label 분포`와 `loss에 실제 사용한 sampled anchor`는 다른 통계다.

### 7.3 Box encode와 decode

Anchor center·size를 $$(x_a,y_a,w_a,h_a)$$, GT를 $$(x_g,y_g,w_g,h_g)$$라 하면 대표적인 2D target은

$$
t_x=\frac{x_g-x_a}{w_a},\quad
t_y=\frac{y_g-y_a}{h_a},\quad
t_w=\log\frac{w_g}{w_a},\quad
t_h=\log\frac{h_g}{h_a}.
$$

Decode는 이를 반대로 적용한다.

$$
\hat{x}=t_xw_a+x_a,\quad
\hat{y}=t_yh_a+y_a,\quad
\hat{w}=e^{t_w}w_a,\quad
\hat{h}=e^{t_h}h_a.
$$

Offset은 absolute coordinate보다 다양한 image size와 object scale을 anchor-relative 변화량으로 정규화한다.

<details markdown="block">
<summary markdown="span">Derivation: A small box encode and decode trace</summary>

Anchor가 center $$(50,40)$$, size $$(20,10)$$이고 GT가 center $$(54,38)$$, size $$(30,5)$$라고 하자.

$$
t_x=4/20=0.2,\qquad
t_y=-2/10=-0.2,
$$

$$
t_w=\log(1.5)\approx0.4055,\qquad
t_h=\log(0.5)\approx-0.6931.
$$

Decode하면 $$0.2(20)+50=54$$, $$-0.2(10)+40=38$$, $$e^{0.4055}(20)\approx30$$, $$e^{-0.6931}(10)\approx5$$로 GT가 복원된다. Width와 height는 양수여야 하며 anchor size가 0이면 정의되지 않는다.

</details>

### 7.4 Faster R-CNN code path

1. Image transform이 normalized padded batch와 resized target을 만든다.
2. Backbone + FPN이 multi-scale feature를 만든다.
3. RPN head가 anchor별 objectness와 4-d offset을 예측한다.
4. Decode, clipping, small-box 제거, score top-K, NMS, proposal cap을 거쳐 proposal을 만든다.
5. RoIAlign이 proposal마다 고정 크기 feature를 만든다.
6. Box head가 background 포함 class logit과 class별 box refinement를 예측한다.
7. Class별 decode, score filter, NMS가 최종 detection을 만든다.

Proposal 수가 줄었다고 NMS 하나의 효과라고 단정하면 안 된다. Top-K, clipping, size filter, score filter, NMS와 final cap이 함께 작동한다.

### 7.5 RetinaNet code path

1. FPN P3–P7의 모든 location에 dense anchor를 만든다.
2. Classification subnet이 anchor별 sigmoid class logit을 만든다.
3. Regression subnet이 anchor별 4-d offset을 만든다.
4. Anchor–GT matching으로 positive·negative·ignore를 정한다.
5. Classification loss는 ignore를 제외한 유효 anchor에 적용한다.
6. Box regression loss는 positive anchor에만 적용한다.
7. Per-level score filter와 top-K, decode, clipping, class별 NMS를 거쳐 최종 detection을 만든다.

Notebook의 `num_classes=2`, custom foreground label 1 설정에서는 RetinaNet의 두 sigmoid column을 softmax background·foreground 두 칸으로 읽으면 안 된다. Public API의 class-index convention까지 확인해야 한다.

### 7.6 Focal loss, prior와 plot 해석

RetinaNet classification bias를 foreground prior $$\pi$$에 맞추는 대표 초기화는

$$
b=-\log\frac{1-\pi}{\pi}.
$$

$$\pi=0.01$$이면 초기 sigmoid probability가 약 0.01이 된다. 이는 정답 비율을 강제하는 규칙이 아니라, 학습 시작 때 수많은 dense anchor가 높은 foreground score를 내지 않도록 하는 초기 조건이다.

Lab 1의 plot은 다음처럼 읽는다.

| Plot | 관찰할 것 | 단정하면 안 되는 것 |
|---|---|---|
| FPN activation | Level별 spatial resolution과 object response | 밝기만으로 해당 level이 정답이라는 결론 |
| Anchor grid | Center spacing, scale, aspect ratio, GT와 겹침 | 가장 높은 IoU anchor가 최종 detection이라는 결론 |
| Objectness heatmap | RPN이 proposal 후보를 어디에 집중하는가 | 최종 class score와 같다는 해석 |
| Proposal before/after filter | 후보 수와 중복이 줄어드는 과정 | 감소가 NMS만의 효과라는 해석 |
| CE vs focal map | 쉬운 negative의 loss 비중이 감소하는가 | Focal loss가 모든 hard example을 올바르게 만든다는 결론 |
| Epoch snapshots | 같은 trace image에서 score·box가 변하는 흐름 | 한 이미지로 일반 성능·속도 우열을 결론내림 |
| Proposal recall vs detection P/R | 1단계 coverage와 최종 판정의 차이 | Fixed threshold P/R을 AP나 COCO mAP로 부름 |

## 8. Lab 2: KITTI point에서 VoxelNet detection까지

<figure id="source-voxel-output">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-assignment3-voxelization.png" | relative_url }}" alt="Voxel별 점 수 histogram과 BEV grid 및 높이 bin 비교" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-03-lidar-3d-object-detection.ipynb" | relative_url }}">Assignment 3 notebook, cell 25 (0-based), saved output</a>.</figcaption>
</figure>

왼쪽은 비어 있지 않은 voxel의 점 수 분포이며 세로축은 로그 척도다. 빨간 T=32 선은 voxel 하나에서 남길 최대 점 수를 표시한다. 가운데의 0.2 m 격자와 오른쪽의 0.4 m 높이 구간은 공간 분할 크기다. 점 수 제한과 voxel의 물리적 크기를 분리해야 sparse 입력이 고정 tensor로 바뀌는 과정을 이해할 수 있다.

### 8.1 실제 KITTI 관찰과 synthetic 학습의 구분

| 구간 | Data | 목적 | 결과 해석 |
|---|---|---|---|
| Part A | 공개 KITTI sample frame 1개 | 실제 point cloud 형식, 좌표 변환, 3D·BEV·range image·camera projection 확인 | 실제 측정 자료의 표현 관찰 |
| Part B training | Ray-casting synthetic train 600 scenes | 축소 VoxelNet을 15 epochs 학습 | 합성 분포 안의 학습 결과 |
| Part B validation | Synthetic validation 60 scenes | Center-distance AP, P@0.5, R@0.5 계산 | 실습용 합성 metric |
| B8 transfer | 실제 KITTI sample frame | Synthetic-trained model의 domain gap 시각화 | 정성 비교. KITTI 공식 성능 아님 |

**실제 KITTI 관찰, 합성 데이터 학습, 실제 장면으로의 적용은 서로 다른 단계다.** 합성 validation AP를 KITTI 공식 성능으로 해석할 수 없다.

### 8.2 KITTI coordinate를 LiDAR box로 바꾸기

실제 sample `.bin`은 header 없는 float32 배열이며 4개씩 읽어 $$(x,y,z,\mathrm{reflectance})$$ point를 만든다. 저장 sample의 shape는 $$(17238,4)$$로, 각 행이 한 point다.

KITTI label의 camera box location은 bottom center이고 camera의 $$y$$는 아래 방향이다. Notebook helper는 먼저 camera location의 $$y$$에서 height의 절반을 빼 box center로 만든다. 이후 inverse `lidar2cam` transform으로 LiDAR coordinate로 옮기고 dimension을 $$(l,w,h)$$로 재배열한다. Yaw는 notebook convention에서

$$
\theta_{\mathrm{lidar}}=-r_y-\frac{\pi}{2}
$$

로 바꾼다. 이 식만 외우기보다 source·target coordinate의 축과 회전 방향을 함께 확인해야 한다.

### 8.3 Point cloud의 집합 성질과 네 표현

Point cloud는 frame마다 point 수가 달라지는 순서 없는 집합이다. Point 행을 permutation해도 같은 scene이다. 그러나 array 값의 행 순서는 달라지므로 point network는 permutation-invariant aggregation을 설계해야 한다.

| 표현 | 축과 값 | 보존하는 정보 | 잃거나 근사하는 정보 |
|---|---|---|---|
| Raw 3D points | point마다 $$x,y,z,r$$ | 개별 3D measurement | Regular grid가 없어 batch convolution이 어려움 |
| BEV | $$x,y$$ grid, height·occupancy·feature | Metric ground-plane footprint, perspective overlap 감소 | Height를 channel·statistic으로 요약. 서로 가까운 BEV box는 여전히 겹칠 수 있음 |
| Range image | elevation × azimuth, 값은 range | LiDAR scan topology | Cartesian object shape가 왜곡될 수 있음 |
| Camera projection | Pixel에 point depth·feature | RGB와 point의 correspondence | Occlusion과 sparse projection, calibration error |

같은 각도 간격으로 조사하는 LiDAR에서는 원거리의 작은 물체가 적은 point로 관측되기 쉽다. 거리뿐 아니라 물체 크기·가림·반사 특성도 point 수에 영향을 준다.

### 8.4 Voxelization

Notebook 설정은 다음 범위를 쓴다.

$$
x\in[0,51.2),\quad y\in[-25.6,25.6),\quad z\in[-3,1)\ \mathrm{m}.
$$

Voxel size는 $$(0.2,0.2,0.4)\ \mathrm{m}$$다. 따라서 grid는

$$
N_x=256,\quad N_y=256,\quad N_z=10
$$

이고 전체 cell은 655,360개다. Point $$(x,y,z)$$의 integer voxel index는 floor 연산으로 구한다.

$$
i_x=\left\lfloor\frac{x-x_{\min}}{0.2}\right\rfloor,\quad
i_y=\left\lfloor\frac{y-y_{\min}}{0.2}\right\rfloor,\quad
i_z=\left\lfloor\frac{z-z_{\min}}{0.4}\right\rfloor.
$$

범위 밖 point를 제거하고 같은 index의 point를 묶는다. 계산 설명은 $$(i_x,i_y,i_z)$$ 순서지만 `voxelize`가 반환하는 `coords` 열 순서는 **`(iz, iy, ix)`**다. Dense tensor에 scatter한 뒤 shape 순서는 **`(B,C,N_z,N_y,N_x)`**다. Voxel당 최대 point 수는 32다. 32개가 넘으면 shuffle 뒤 처음 32개를 남긴다. 장면당 non-empty voxel도 최대 20,000개로 제한한다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: From point coordinates to grouped voxels</summary>

저장된 synthetic validation scene에서는 41,819 input points 중 40,950개가 범위 안에 있었고, 7,236개 non-empty voxel을 만들었다. 전체 grid의 약 1.10%다. 103개 voxel이 32-point limit을 넘어 sampling됐다. 이는 한 scene의 실행 기록이며 frame마다 달라진다.

`voxelize`의 상태 변화는 다음과 같다.

```text
(N, 4) points
  -> range mask
  -> shuffled in-range points
  -> integer (ix, iy, iz)
  -> flattened voxel id
  -> unique voxel ids + inverse map + counts
  -> rank of each point inside its voxel
  -> keep rank < 32
  -> voxels (V, 32, 4), npts (V,), coords (V, 3)
```

Padding point는 0으로 채우고 `npts`에서 만든 mask로 실제 point와 구분한다. Shuffle가 있으므로 32개를 넘는 voxel의 선택된 subset은 seed·호출 순서에 따라 달라질 수 있다.

</details>

### 8.5 VFE: point-wise 정보와 voxel context를 합친다

각 point의 VFE input은

$$
[x,y,z,r,x-\bar{x}_v,y-\bar{y}_v,z-\bar{z}_v]
$$

의 7차원이다. $$(\bar{x}_v,\bar{y}_v,\bar{z}_v)$$는 같은 voxel의 실제 point centroid다. Offset은 voxel 안의 local shape를 표현한다.

VFE layer는 모든 point에 같은 `Linear + BN + ReLU`를 적용해 point-wise feature를 만든다. 같은 voxel의 point 축으로 element-wise max를 취해 locally aggregated feature를 만든다. 이 vector를 모든 point에 복제해 point-wise feature와 concatenate한다.

Shared point function과 symmetric max는 **같은 selected point set 안에서의 순서 불변성**을 준다. Sampling으로 선택된 점 자체가 바뀌거나 좌표 변환으로 voxel 소속이 달라지는 것은 별개다. Rotation invariance나 training mode의 stochastic 실행까지 보장하지는 않는다.

### 8.6 Sparse-to-dense, 3D convolution, BEV RPN

VFE가 만든 voxel별 vector를 3D grid에 배치하고, 3D convolution으로 주변 voxel과 height 정보를 처리한다. 이후 남은 height axis를 channel에 합쳐 2D BEV RPN에 전달한다. **Height를 처음부터 무시하는 것이 아니라, 처리한 height 정보를 channel 표현에 담는 과정**이다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Stored VoxelNet tensor shapes</summary>

Notebook에 저장된 한 scene의 tensor trace다. Non-empty voxel 수는 scene마다 달라진다.

| 단계 | Tensor shape | 의미 |
|---|---|---|
| Voxel feature | $$(7236,64)$$ | Non-empty voxel당 64-d feature |
| Dense voxel tensor | $$(1,64,10,256,256)$$ | Batch, channel, height, y, x |
| 3D conv 1 | $$(1,32,5,256,256)$$ | Height stride 2 |
| 3D conv 2 | $$(1,32,5,256,256)$$ | 3D context 유지 |
| 3D conv 3 | $$(1,32,3,256,256)$$ | Height stride 2 |
| BEV reshape | $$(1,96,256,256)$$ | 32 channel × 3 height를 channel로 합침 |
| RPN blocks | 128², 64², 32² maps | 서로 다른 receptive field |
| Upsample + concat | $$(1,384,128,128)$$ | Multi-scale BEV feature |
| Class output | $$(1,65536)$$ | 3D anchor별 logit |
| Box output | $$(1,65536,7)$$ | 3D anchor별 7-d offset |

BEV reshape에서 $$32\times3=96$$이므로 channel 수가 96이 된다. 그 뒤 128×128 위치마다 4개 anchor를 배치해 $$128\times128\times4=65{,}536$$개 prediction을 만든다.

</details>

### 8.7 3D anchor label과 box target

128×128 output grid의 각 location에 Car 0°·90°, Pedestrian 0°·90° anchor 네 개가 있어 총 65,536개다.

Anchor와 GT의 BEV IoU threshold는 notebook 설정에서 다음과 같다.

| Class | Positive | Negative | Ignore |
|---|---:|---:|---:|
| Car | $$\mathrm{IoU}\ge0.60$$ | $$\mathrm{IoU}<0.45$$ | 그 사이의 non-positive anchor |
| Pedestrian | $$\mathrm{IoU}\ge0.50$$ | $$\mathrm{IoU}<0.35$$ | 그 사이의 non-positive anchor |

각 GT의 최고-IoU anchor도 overlap이 0보다 크면 positive로 보장한다. Notebook의 BEV IoU는 box의 yaw를 0°·90° 방향으로 근사한 axis-aligned overlap이다. 임의 방향 box의 정확한 rotated IoU와 구분한다.

3D target에서 horizontal center는 anchor diagonal $$d_a=\sqrt{l_a^2+w_a^2}$$로 정규화한다.

$$
\Delta x=\frac{x_g-x_a}{d_a},\quad
\Delta y=\frac{y_g-y_a}{d_a},\quad
\Delta z=\frac{z_g-z_a}{h_a},
$$

$$
\Delta l=\log\frac{l_g}{l_a},\quad
\Delta w=\log\frac{w_g}{w_a},\quad
\Delta h=\log\frac{h_g}{h_a},\quad
\Delta\theta=\theta_g-\theta_a.
$$

Notebook의 yaw difference는 $$\pi$$ 주기로 정규화되어 앞·뒤가 뒤집힌 box 방향을 같은 것으로 취급한다. 별도 heading 분류기를 쓰는 일반 detector 전체의 성질은 아니다.

### 8.8 Loss와 class imbalance

현재 config `CLS_LOSS = "voxelnet"`은 positive와 negative BCE sum을 각각 해당 개수로 나눈 뒤 가중한다.

$$
L=\frac{\alpha}{N_{pos}}\sum_{i\in pos}L_{cls}(p_i,1)
+\frac{\beta}{N_{neg}}\sum_{j\in neg}L_{cls}(p_j,0)
+\frac{1}{N_{pos}}\sum_{i\in pos}L_{reg}(u_i,u_i^*).
$$

Notebook은 $$\alpha=1.5$$, $$\beta=1.0$$을 쓰고 regression은 positive anchor에만 Smooth L1을 적용한다. $$N_{pos},N_{neg}$$는 각각 유효 positive·negative 수이며 코드에서는 빈 집합으로 나누지 않도록 각 분모를 최소 1로 제한한다. 별도 평균은 훨씬 많은 negative가 classification loss를 개수만으로 압도하지 않게 한다.

<details markdown="block">
<summary markdown="span">Derivation: Separate positive and negative loss normalization</summary>

저장 trace의 한 scene에는 positive 65개, negative 65,374개, ignore 97개가 있었다. 유효 anchor를 한 번에 평균하면 positive 비율은 $$65/(65+65374)\approx0.10\%$$다.

모든 유효 anchor에서 $$p=0.5$$라고 둔 설명용 조건에서는 BCE가 모두 $$-\log0.5$$로 같다. 별도 평균 후 positive·negative classification 항은 각각 $$1.5(-\log0.5)$$와 $$1.0(-\log0.5)$$다. 따라서 두 classification 항의 합에서 positive 항은 $$1.5/(1.5+1)=60\%$$를 차지한다. 실제 학습에서는 예측값마다 BCE가 달라지므로 60%가 항상 유지되는 것은 아니다.

코드는 `CLS_LOSS = "focal"`도 지원하지만 저장 학습 run의 설정은 `"voxelnet"`이다.

</details>

### 8.9 Training phase, postprocessing, metric

후처리는 class score filtering, 상위 후보 선택, box decode, class별 NMS 순서로 최종 prediction set을 만든다. 평가는 각 scene·class 안에서 prediction을 confidence 순으로 처리하고, 아직 사용하지 않은 같은 class GT 중 BEV center가 가장 가까운 것을 one-to-one match한다. 이후 validation scenes의 prediction을 class별 confidence 순으로 모아 PR curve를 만든다.

- Car: center distance $$<2\ \mathrm{m}$$
- Pedestrian: center distance $$<1\ \mathrm{m}$$
- AP: center-distance match의 precision–recall area
- P@0.5, R@0.5: 위 후처리로 남은 set에서 score threshold 0.5를 적용한 fixed operating point

<details markdown="block">
<summary markdown="span">Figure Analysis: Saved training and validation results</summary>

저장 run은 synthetic train 600 scenes, batch size 4, 15 epochs, AdamW와 left–right flip augmentation을 사용했다. CUDA에서는 mixed precision을 쓴다. Snapshot은 epoch 0, 1, 3, 8, 15에 저장됐다.

`postprocess` 설정은 sigmoid score **0.1 초과**, 전체 top 500, 7-d decode, class별 approximate BEV NMS, 장면당 최대 100 detections다. Epoch 15의 AP는 60개 synthetic validation scenes에서 Car 0.948, Pedestrian 0.912였다. 위 center-distance 규칙과 후처리 조건에서 얻은 값이다.

Score map의 집중과 loss 감소는 optimization 진행을 보여 준다. 실제 환경에서의 일반화 성능을 입증하지는 않는다.

</details>

### 8.10 Synthetic-to-real 경계

Simulator는 단순화한 물체에 ray를 쏘고 range noise와 point dropout을 추가한다. 실제 환경의 곡면·유리·식생·경사·반사 특성과 장면 분포를 모두 재현하지는 못한다. 이 **domain gap** 때문에 합성 장면에서 잘 학습한 box가 실제 KITTI sample에서는 어긋날 수 있다. B8은 이를 관찰하는 정성 비교다. 실제 데이터로 fine-tuning하고 같은 평가 규칙으로 검증하는 것이 이후 보완 방향이다.

## 9. 자주 섞이는 개념

| 혼동 | 올바른 구분 |
|---|---|
| Anchor = prediction | Anchor는 기준 box, prediction은 anchor offset을 decode한 box다 |
| Objectness = class score | RPN objectness는 object proposal 가능성, RoI class score는 class 판정이다 |
| NMS = evaluation matching | NMS는 prediction끼리 중복 억제, evaluation은 prediction과 GT의 one-to-one matching이다 |
| Fixed P/R = AP | P/R은 한 threshold, AP는 score sweep의 PR curve 면적이다 |
| BEV IoU = 3D IoU | BEV overlap은 height overlap을 직접 포함하지 않는다 |
| PointNet 순서 불변 = 회전 불변 | Symmetric aggregation은 point order에 대한 invariance다 |
| VoxelNet = 3D convolution만 | Voxel grouping, VFE, 3D middle layers, BEV RPN, anchor head와 후처리의 전체 흐름이다 |

## 10. 마지막 핵심 정리

1. Sensor는 서로 다른 물리량과 실패 조건을 가진다. Camera pixel은 ray를, LiDAR point는 직접 측정한 surface geometry를 나타낸다.
2. Projection에는 coordinate convention, intrinsic, extrinsic과 positive depth 조건이 필요하다. Stereo depth 오차는 원거리에서 빠르게 커진다.
3. Detection의 공통 흐름은 feature, candidate, label assignment, class·box prediction, filtering·NMS, GT matching과 AP다.
4. R-CNN 계열은 region proposal 처리 위치가 발전했고, FPN은 multi-scale semantics와 resolution을 결합한다.
5. RetinaNet은 dense anchor의 imbalance를 focal loss로, FCOS는 anchor-free distance와 centerness로 다룬다.
6. 3D detector는 raw point, voxel, BEV 또는 image-depth representation 중 계산 중심을 선택한다.
7. Lab 1은 Faster R-CNN의 proposal–refinement와 RetinaNet의 dense prediction을 같은 image에서 추적한다.
8. Lab 2는 실제 KITTI 표현 관찰과 synthetic VoxelNet training을 분리한다. 저장 AP는 synthetic center-distance AP다.

## Study Guide

- **계산:** projection·stereo depth, IoU·AP, box encode·decode, voxel index를 숫자를 바꿔 직접 계산한다.
- **비교:** two-stage와 one-stage, semantic과 instance segmentation, image·point·voxel·BEV 표현의 차이를 설명한다.
- **Lab 1:** image, FPN, anchor, RPN proposal, RoI refinement의 입력·출력을 추적하고 RetinaNet의 dense head와 비교한다.
- **Lab 2:** point, voxel, VFE, 3D convolution, BEV RPN 순서로 tensor의 축이 어떻게 바뀌는지 설명한다.
- **평가:** IoU의 비교 대상, AP의 matching 규칙, 사용한 데이터 분포를 명시한다.

## 복습 질문

<details markdown="block">
<summary markdown="span">1. 단안 camera pixel 하나로 metric 3D point를 유일하게 정할 수 없는 이유는?</summary>

답변: Pixel과 intrinsic은 camera center에서 나가는 ray의 방향만 정한다. Ray 위의 depth $$Z$$는 자유 변수이므로 크기·거리 prior, stereo disparity, LiDAR 또는 learned depth 같은 추가 정보가 필요하다.

</details>

<details markdown="block">
<summary markdown="span">2. Stereo에서 원거리 depth가 불안정해지는 이유는?</summary>

답변: $$Z=fB/d$$이고 $$\partial Z/\partial d=-fB/d^2$$다. 원거리에서는 disparity $$d$$가 작아져 같은 pixel 오차가 훨씬 큰 depth 오차로 증폭된다.

</details>

<details markdown="block">
<summary markdown="span">3. IoU는 학습, 후처리, 평가에서 어떻게 다르게 쓰이는가?</summary>

답변: 학습에서는 anchor–GT label assignment, 후처리에서는 prediction–prediction NMS, 평가에서는 prediction–GT TP/FP matching에 사용한다. Threshold와 비교 대상이 서로 다를 수 있다.

</details>

<details markdown="block">
<summary markdown="span">4. AP가 한 score threshold의 precision과 다른 이유는?</summary>

답변: AP는 prediction을 confidence 순으로 누적해 만든 전체 precision–recall curve의 면적이다. 한 threshold의 precision·recall은 그 curve의 operating point 하나다.

</details>

<details markdown="block">
<summary markdown="span">5. Faster R-CNN을 two-stage라 부르는 정확한 이유는?</summary>

답변: RPN이 object proposal을 만들고 RoI head가 각 proposal을 다시 classification·box refinement하기 때문이다. Backbone CNN을 반드시 두 번 계산한다는 뜻은 아니다.

</details>

<details markdown="block">
<summary markdown="span">6. RetinaNet에서 regression loss를 negative anchor에 적용하지 않는 이유는?</summary>

답변: Negative anchor에는 대응하는 GT box가 없어 회귀 target을 정의할 수 없다. Classification loss는 유효 positive·negative에, box regression은 positive에만 적용한다.

</details>

<details markdown="block">
<summary markdown="span">7. FPN이 작은 물체에 도움이 되는 구조적 이유는?</summary>

답변: 낮은 backbone level의 높은 spatial resolution에 높은 level의 semantics를 top-down·lateral connection으로 결합한다. 작은 물체가 사라지기 전의 위치 정보를 비교적 강한 의미 표현과 함께 쓸 수 있다.

</details>

<details markdown="block">
<summary markdown="span">8. PointNet의 permutation invariance와 VFE의 순서 불변성을 어디까지 말할 수 있는가?</summary>

답변: 같은 selected point set에 shared point function과 symmetric max를 적용하면 point 순서가 결과를 바꾸지 않는다. Random sampling으로 set이 달라지거나 좌표 변환으로 voxel membership이 달라지는 경우, rotation·translation까지 자동으로 invariant한 것은 아니다.

</details>

<details markdown="block">
<summary markdown="span">9. Lab 2에서 3D convolution 뒤 BEV로 바꾸는 것이 height 정보를 즉시 버리는 것과 다른 이유는?</summary>

답변: 먼저 3D convolution이 height·ground-plane 이웃을 함께 처리한다. 그 결과의 남은 height bins를 channel에 합쳐 2D RPN 입력으로 만든다. Raw height axis는 사라지지만 학습된 height context가 channel feature에 들어 있다.

</details>

<details markdown="block">
<summary markdown="span">10. 합성 validation AP와 실제 KITTI 적용 결과는 무엇을 각각 보여 주는가?</summary>

답변: 합성 validation AP는 같은 simulator 분포의 별도 장면에서 center-distance 규칙으로 평가한 성능이다. 실제 KITTI sample에 그린 box는 분포가 달라질 때의 동작을 관찰하는 정성 결과다. KITTI 공식 rotated 3D IoU AP는 별도 데이터와 평가 절차가 필요하다.

</details>

<details markdown="block">
<summary markdown="span">11. Mono3D의 class semantic과 instance semantic은 무엇이 다른가?</summary>

답변: Class semantic은 각 pixel의 종류를 구분하고, instance semantic은 같은 종류 안에서도 개체를 나눈다. 차량 두 대가 붙어 있을 때 class 정보만으로는 모두 car지만, instance 정보는 한 후보가 어느 차량 영역에 대응하는지 구분하는 단서가 된다. 둘은 다른 image feature들과 함께 3D 후보의 점수를 매기는 데 쓰인다.

</details>

<details markdown="block">
<summary markdown="span">12. Camera–LiDAR fusion에서 feature concatenation 전에 필요한 조건은?</summary>

답변: Intrinsic·extrinsic calibration으로 공간 좌표를 맞추고, timestamp·ego motion으로 시간을 맞추며, 같은 proposal 또는 object region을 각 view에서 대응시켜야 한다.

</details>

## Source Materials

### Lecture PDFs

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/02-sensors.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 2 — Sensors</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 3 — Perception I</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 4 — Perception II</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 5 — R-CNN Inference and Fast R-CNN</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 6 — Faster R-CNN and FPN</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 7 — Single-Stage Detection</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 8 — Segmentation</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 9 — Image-Based 3D Detection</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 10 — LiDAR-Based 3D Detection</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 11 — Multimodal 3D Detection</a></li>
</ul>

### Notebooks

<ul>
  <li><a href="{{ "/assets/materials/study/autonomous-driving/adc-lab-01-two-stage-vs-one-stage.ipynb" | relative_url }}" download data-no-resource-reader>Lab 1 base notebook — Two-Stage vs One-Stage Object Detection</a></li>
  <li><a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-02-two-stage-vs-one-stage.ipynb" | relative_url }}" target="_blank" rel="noopener">Lab 1 — Solutions and Outputs</a></li>
  <li><a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-03-lidar-3d-object-detection.ipynb" | relative_url }}" target="_blank" rel="noopener">Lab 2 — LiDAR 3D Object Detection</a></li>
</ul>

### Detailed Notes

- [Lecture notes and course materials](/study/autonomous-driving/)
- [Assignment 1: Average Precision](/assignment/autonomous-driving/assignment-01-average-precision/)
- [Lab 1: Two-Stage vs One-Stage Detection](/assignment/autonomous-driving/assignment-02-two-stage-vs-one-stage-detection/)
- [Lab 2: LiDAR 3D Object Detection](/assignment/autonomous-driving/assignment-03-lidar-3d-object-detection/)

Notebook의 그림·tensor shape·학습 수치는 저장된 출력과 코드에 근거하며, 이 총정리를 위해 새로 실행한 결과가 아니다. AP 손계산과 작은 수치 예시는 본문 조건으로 별도 계산한 것이다.
