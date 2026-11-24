---
layout: default
date: 2026-10-14 13:17:33 +0900
last_modified_at: 2026-11-23 16:50:00 +0900
title: "Autonomous Driving Computing: Midterm Review"
course: "Autonomous Driving"
topic: "Sensors, 2D and 3D Perception, Lab 1, and Lab 2"
order: 92
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

# Autonomous Driving Computing: Midterm Review

## Presentation

[View slides (PDF)]({{ "/assets/pdfs/study/autonomous-driving/adc-midterm-review-slides.pdf" | relative_url }}) · <a href="{{ "/assets/presentations/study/autonomous-driving/adc-midterm-review-slides.pptx" | relative_url }}" download>Download PowerPoint (PPTX)</a>

37장으로 센서·2D/3D perception·Lab 1–2의 핵심 그림과 계산 예제를 정리했습니다. Lab의 핵심 요약·생각해보기는 anchor 선택과 sampling, NMS, focal loss, 높이별 occupancy, 거리별 희소성, voxel tensor, 학습 결과와 평가 기준으로 풀어 설명합니다. 원본 notebook의 저장 그림·수치는 일반 원리와 구분했습니다. PDF를 선택하면 본문과 나란히 볼 수 있고, 좁은 화면에서는 모달로 열립니다. 상세 유도와 코드 해설은 아래 본문에서 이어집니다.

Source Materials: Lectures 2–11, Labs 1–2, and Assignment 1 (Average Precision).

> **핵심:** 자율주행 perception은 센서가 만든 측정값을 좌표계가 있는 표현으로 바꾸고, 그 표현에서 객체의 종류·위치·형상을 추정한 뒤, 정답과 같은 규칙으로 평가하는 과정입니다. 2D 검출에서는 feature, anchor, IoU, NMS와 AP가 이 흐름을 연결합니다. 3D 검출에서는 camera ray의 깊이 모호성, LiDAR의 희소성, voxel·point·BEV 표현, calibration과 fusion이 추가됩니다. Lab 1은 Faster R-CNN과 RetinaNet의 2D 검출 흐름을, Lab 2는 실제 KITTI point cloud의 표현과 합성 데이터에서 학습한 VoxelNet 흐름을 코드 수준에서 추적합니다.

**이 총정리의 복습 범위는 Lecture 2–11과 Lab 1–2입니다.** Lab 1의 풀이·출력은 Assignment 2 notebook에, Lab 2의 풀이·출력은 Assignment 3 notebook에 담겨 있습니다. 시험 범위에 관한 별도 공지가 있으면 그 공지를 우선합니다.

## 전체 흐름

| 순서 | 주제 | 반드시 답할 질문 |
|---:|---|---|
| 1 | Sensor와 geometry | 각 센서는 무엇을 직접 측정하며, 어느 좌표계에 있습니까? |
| 2 | 2D perception task | Classification, localization, detection, segmentation의 출력은 어떻게 다릅니까? |
| 3 | Detection metric | IoU, NMS, precision, recall, AP는 각각 어느 단계에서 쓰입니까? |
| 4 | 2D detector 계보 | R-CNN에서 Faster R-CNN, RetinaNet, YOLO, FCOS까지 무엇이 공유되고 무엇이 달라집니까? |
| 5 | 3D perception | Camera, LiDAR, fusion 방식은 깊이와 3D box를 어떻게 얻습니까? |
| 6 | Lab 1 | Tensor, anchor label, box target, focal loss와 plot을 어떻게 읽습니까? |
| 7 | Lab 2 | KITTI 좌표 변환, voxelization, VFE, 3D convolution, BEV head와 loss가 어떻게 이어집니까? |

## 1. Sensor: 모델보다 먼저 측정값을 이해한다

### 1.1 Camera, LiDAR, RADAR가 직접 주는 것

| Sensor | 직접 측정하는 핵심 정보 | 강점 | 대표 실패 조건 |
|---|---|---|---|
| Camera | 영상 평면의 색·밝기·texture | 높은 각해상도, class와 표지·신호 의미 | 조도, glare, 안개·비, metric depth 모호성 |
| Stereo camera | 두 camera의 대응 pixel disparity | calibration과 대응점이 맞으면 metric depth | texture 부족, occlusion, 작은 disparity의 큰 깊이 오차 |
| LiDAR | laser 왕복 시간으로 얻은 3D surface point와 reflectance | 직접적인 3D geometry와 거리 | 원거리 희소성, 가림, 날씨·반사 재질, 비용 |
| RADAR | radio wave의 range·relative velocity·angle | 장거리와 Doppler 속도, 악천후 견고성 | 낮은 각해상도, multipath, object shape 해석 한계 |

센서 하나의 장점이 perception 전체의 정확성을 보장하지 않습니다. Calibration, timestamp 정렬, ego-motion 보정, 표현 변환, 모델, 후처리와 평가까지 맞아야 합니다.

### 1.2 Pinhole projection: 3D point가 pixel이 되는 과정

World point의 homogeneous coordinate를 $$\tilde{X}_w=[X_w,Y_w,Z_w,1]^{\top}$$라 하겠습니다. Extrinsic matrix가 world에서 camera로, intrinsic matrix $$K$$가 camera ray를 pixel로 바꿉니다.

$$
s\begin{bmatrix}u\\v\\1\end{bmatrix}
=K[R\mid t]\tilde{X}_w
$$

여기서 $$u,v$$는 pixel coordinate, $$s$$는 camera depth에 비례하는 scale입니다. Distortion을 무시한 pinhole model이며 camera 앞의 point는 camera-frame depth가 양수여야 합니다. 같은 pixel $$[u,v]$$는 한 3D point가 아니라 camera center에서 뻗는 **ray 전체**를 나타냅니다. 따라서 단안 영상만으로 metric depth를 유일하게 정할 수 없습니다.

작은 trace를 보겠습니다. Camera intrinsic이 $$f_x=f_y=800\ \mathrm{px}$$, principal point가 $$(c_x,c_y)=(640,360)\ \mathrm{px}$$이고 camera point가 $$(X,Y,Z)=(2,1,20)\ \mathrm{m}$$이면

$$
\begin{aligned}
u&=f_x\frac{X}{Z}+c_x=720,\\
v&=f_y\frac{Y}{Z}+c_y=400.
\end{aligned}
$$

같은 $$X/Z$$와 $$Y/Z$$를 가진 $$(4,2,40)$$도 같은 pixel에 투영됩니다. 이것이 scale–distance ambiguity입니다.

<details markdown="block">
<summary markdown="span">Derivation: Camera projection and inverse ray</summary>

Camera coordinate $$(X_c,Y_c,Z_c)$$에서 normalized coordinate는

$$
x_n=X_c/Z_c,\qquad y_n=Y_c/Z_c
$$

입니다. Intrinsic matrix를

$$
K=\begin{bmatrix}
f_x&0&c_x\\
0&f_y&c_y\\
0&0&1
\end{bmatrix}
$$

로 두면 $$u=f_xx_n+c_x$$, $$v=f_yy_n+c_y$$가 됩니다. 반대로 pixel과 depth $$Z_c$$가 주어지면

$$
\begin{aligned}
X_c&=(u-c_x)Z_c/f_x,\\
Y_c&=(v-c_y)Z_c/f_y.
\end{aligned}
$$

로 역투영할 수 있습니다. Depth가 없으면 $$Z_c$$가 자유 변수이므로 ray만 정해집니다. Lens distortion이 크거나 calibration이 틀리면 이 식을 그대로 적용할 수 없습니다.

</details>

### 1.3 Stereo depth와 불확실성

광축이 평행하고 rectification을 마쳤으며 두 camera의 matched intrinsic과 principal-point convention을 사용하는 stereo에서, 같은 3D point의 left·right horizontal pixel 차이를 disparity $$d=u_L-u_R$$라 하면

$$
Z=\frac{fB}{d}
$$

입니다. $$f$$는 pixel 단위 focal length, $$B$$는 meter 단위 baseline, $$d$$는 pixel이므로 $$Z$$는 meter입니다. Disparity가 작아지는 원거리에서 깊이 오차가 빠르게 커집니다.

예를 들어 $$f=700\ \mathrm{px}$$, $$B=0.54\ \mathrm{m}$$, $$d=35\ \mathrm{px}$$이면 $$Z=10.8\ \mathrm{m}$$입니다. Disparity 오차가 약 $$1\ \mathrm{px}$$이면 1차 근사 깊이 오차 크기는

$$
\lvert\Delta Z\rvert\approx\frac{fB}{d^2}\lvert\Delta d\rvert
=0.309\ \mathrm{m}
$$

입니다. 같은 $$1\ \mathrm{px}$$ 오차가 $$d=7\ \mathrm{px}$$인 원거리에서는 약 $$7.71\ \mathrm{m}$$로 커집니다.

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

입니다. 이 식은 local linear approximation입니다. Correspondence가 완전히 틀리거나 occlusion으로 대응점이 없으면 작은 오차 근사가 아니라 잘못된 depth 자체가 생깁니다.

</details>

### 1.4 LiDAR range와 sensor uncertainty

Laser 왕복 시간차가 $$\Delta t$$이면 range는

$$
r=\frac{c\Delta t}{2}
$$

입니다. 빛이 물체까지 갔다가 돌아오므로 2로 나눕니다. $$c$$는 빛의 속도입니다. 실제 point cloud의 오차는 시간 측정만이 아니라 beam divergence, reflectance, incidence angle, motion distortion, calibration과 synchronization에도 영향을 받습니다.

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
| Classification | 이미지 하나 | 이미지 전체 class score | 무엇입니까? |
| Localization | 이미지 하나 | 주 물체 class와 box 하나 | 무엇이며 어디입니까? |
| Object detection | 이미지 하나 | 개수가 변하는 class·box·score 집합 | 무엇이 각각 어디에 몇 개입니까? |
| Semantic segmentation | 이미지 하나 | pixel마다 semantic class | 각 pixel은 어느 종류입니까? |
| Instance segmentation | 이미지 하나 | object instance마다 class·box·mask | 같은 class의 개체를 어떻게 분리합니까? |

CNN은 spatial neighborhood에 같은 filter를 공유해 local feature를 추출합니다. 이 특징을 만드는 **backbone**과, 특징에서 class·box·mask를 예측하는 **head**는 역할이 다릅니다. VGG·ResNet·ViT는 먼저 표현을 만드는 방식의 차이로 읽어야 뒤의 detector와 혼동하지 않습니다.

Task가 바뀌면 label과 loss도 바뀝니다. Classification의 single class label만으로 detection의 box regression을 학습할 수 없습니다. Detection box만으로 semantic segmentation의 모든 pixel label을 직접 감독할 수도 없습니다.

### 2.1 VGG, ResNet, ViT: 깊이와 정보 결합을 바꾸는 방법

Supplementary table — [Lecture 3 pp. 32–38](/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf#page=32)의 핵심을 문제와 설계 변경으로 비교한 표입니다.

| 논문 | 해결하려는 문제 | 핵심 방법과 의미 |
|---|---|---|
| [VGG](https://arxiv.org/abs/1409.1556){:target="_blank" rel="noopener"} | 더 풍부한 시각 특징을 얻으려면 network를 어떻게 깊게 만들 것입니까? | 작은 3×3 convolution을 반복해 깊이를 늘립니다. 큰 filter 하나로 끝내기보다 여러 층에서 비선형 변환을 누적합니다. |
| [ResNet](https://arxiv.org/abs/1512.03385){:target="_blank" rel="noopener"} | 층을 늘렸는데도 학습이 어려워져 성능이 나빠지는 문제 | 입력을 shortcut으로 더하고 block은 잔차를 학습합니다. 깊은 표현을 실제로 최적화하기 쉽게 만드는 것이 핵심이며, 깊이 증가만으로 성능을 보장하지는 않습니다. |
| [ViT](https://arxiv.org/abs/2010.11929){:target="_blank" rel="noopener"} | 영상 표현을 convolution 중심 구조 외의 방식으로 만들 수 있습니까? | Patch를 token으로 바꾸고 위치 정보를 더해 self-attention으로 patch 사이의 관계를 계산합니다. 큰 규모의 사전학습과 전이 조건이 중요한 방법입니다. |
{: .reference-candidate-table}

**VGG와 ResNet은 ‘깊은 표현’과 ‘그 표현을 학습하는 어려움’으로 연결됩니다.** ViT는 그 다음 깊이를 더 늘린 CNN이 아니라, 공간 정보를 결합하는 연산을 바꾸는 선택입니다. [Lecture 3의 ViT 원본 그림](/study/autonomous-driving/lecture-03-perception-01/#adc-03-p53)에서는 patch embedding → Transformer → class token 순서로 읽으면 됩니다. 이 backbone 선택 위에 다음 절의 detection·segmentation head가 올라갑니다.

## 3. Detection의 공통 문법: IoU, NMS, precision, recall, AP

### 3.1 IoU는 두 box의 겹침 비율이다

$$
\operatorname{IoU}(A,B)=\frac{\operatorname{area}(A\cap B)}{\operatorname{area}(A\cup B)}.
$$

예측 box $$A=[0,0,4,4]$$와 GT box $$B=[2,0,6,4]$$를 생각해 보겠습니다. 두 box의 넓이는 각각 16이고 교집합은 $$2\times4=8$$입니다. 합집합은 $$16+16-8=24$$이므로 IoU는 $$8/24=1/3$$입니다. IoU threshold가 0.5면 이 예측은 match가 아닙니다.

IoU는 세 곳에서 다른 역할을 합니다.

1. Anchor와 GT를 positive·negative·ignore로 나눌 수 있습니다.
2. Detection을 GT와 match해 TP·FP를 정할 수 있습니다.
3. NMS에서 예측끼리 중복 여부를 판단할 수 있습니다.

같은 IoU라도 **anchor–GT**, **prediction–GT**, **prediction–prediction** 중 무엇을 비교하는지 먼저 확인합니다.

### 3.2 NMS는 정답 판정이 아니라 중복 억제다

Class별 NMS의 기본 흐름은 다음과 같습니다.

1. 가장 높은 score의 box를 남깁니다.
2. 남긴 box와 IoU가 threshold보다 큰 같은 class box를 제거합니다.
3. 남은 box에서 반복합니다.

Score 0.95인 box와 score 0.90인 box의 IoU가 0.70이고 NMS threshold가 0.50이면 두 번째 box를 억제합니다. Score 0.82인 세 번째 box의 IoU가 0.20이면 남깁니다. NMS는 두 box가 실제로 같은 물체라는 것을 증명하지 않습니다. 가까이 겹친 두 객체를 잘못 합치거나, 한 객체의 서로 덜 겹친 중복 box를 모두 남길 수 있습니다.

### 3.3 Precision과 recall은 서로 다른 실패를 본다

$$
\mathrm{Precision}=\frac{TP}{TP+FP},\qquad
\mathrm{Recall}=\frac{TP}{TP+FN}.
$$

Precision은 내놓은 검출 중 맞은 비율입니다. Recall은 실제 객체 중 찾아낸 비율입니다. Score threshold를 높이면 보통 FP가 줄어 precision이 오르지만 TP도 줄어 recall이 내려갈 수 있습니다.

### 3.4 AP worked example

한 image에 GT가 4개 있고 confidence 순서의 prediction 결과가 `TP, FP, TP, TP, FP`라고 하겠습니다. 각 prediction은 **같은 image의 같은 class에 속한 아직 사용하지 않은 GT**와만 match합니다. 중복 prediction은 이미 매칭된 GT에 다시 붙을 수 없으므로 FP입니다.

| 순위 | 결과 | 누적 TP | 누적 FP | Precision | Recall |
|---:|---|---:|---:|---:|---:|
| 1 | TP | 1 | 0 | 1.000 | 0.25 |
| 2 | FP | 1 | 1 | 0.500 | 0.25 |
| 3 | TP | 2 | 1 | 0.667 | 0.50 |
| 4 | TP | 3 | 1 | 0.750 | 0.75 |
| 5 | FP | 3 | 2 | 0.600 | 0.75 |

Monotonic precision envelope를 쓰는 all-points interpolation에서 recall 0.25, 0.50, 0.75의 증가분마다 이후 최대 precision은 1.00, 0.75, 0.75입니다. 최대 recall이 0.75라 나머지 구간의 precision은 0입니다.

$$
AP=0.25(1.00)+0.25(0.75)+0.25(0.75)=0.625.
$$

AP는 한 score threshold의 precision이나 recall이 아닙니다. IoU threshold, class, interpolation 방식, 데이터 split이 달라지면 AP도 달라집니다. mAP는 정의된 class 또는 IoU threshold들의 AP를 평균한 값이므로 평가 protocol을 같이 적어야 합니다.

<details markdown="block">
<summary markdown="span">Derivation: Confidence sorting, one-to-one matching, and AP</summary>

각 image와 class 안에서 prediction을 score 내림차순으로 처리합니다. 같은 image의 아직 사용하지 않은 같은 class GT 중 IoU가 가장 큰 것을 찾고, 그 IoU가 평가 threshold 이상이면 TP로 만들며 해당 GT를 사용 처리합니다. 조건을 만족하지 않거나 이미 사용한 GT를 다시 검출하면 FP입니다. 그 뒤 dataset 전체 prediction을 confidence 순으로 모아 PR curve를 만듭니다.

누적 precision과 recall을 만든 뒤 precision envelope를

$$
p_{\mathrm{interp}}(r)=\max_{\tilde{r}\ge r}p(\tilde{r})
$$

로 정의합니다. Recall이 증가한 구간의 폭과 해당 envelope 높이를 곱해 합하면 AP를 얻습니다. Dataset과 benchmark에 따라 11-point, 101-point 또는 모든 recall 변화점을 쓰므로 숫자를 비교할 때 protocol이 같아야 합니다.

</details>

## 4. 2D detector 계보를 같은 축으로 비교하기

### 4.1 R-CNN에서 Faster R-CNN까지

Supplementary table — [Lecture 4 pp. 26–36](/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf#page=26), [Lecture 5 pp. 19–28](/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf#page=19), [Lecture 6 pp. 7–19](/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf#page=7)의 논문별 변경점입니다.

| 논문 | 출발한 문제 | 바꾼 부분과 남은 과제 |
|---|---|---|
| [R-CNN](https://arxiv.org/abs/1311.2524){:target="_blank" rel="noopener"} | 이미지 분류용 CNN으로 개수와 위치가 다른 여러 객체를 검출해야 함 | Selective Search의 후보 영역을 각각 CNN에 넣어 분류·box 보정합니다. 학습된 시각 특징을 검출에 활용하지만, 겹치는 약 2,000개 영역에서 CNN 계산을 반복합니다. |
| [Fast R-CNN](https://arxiv.org/abs/1504.08083){:target="_blank" rel="noopener"} | 같은 영상의 겹치는 후보마다 convolution을 다시 계산함 | 이미지 전체 feature를 한 번 계산하고 RoI pooling으로 후보별 고정 크기 특징을 얻습니다. Class·box를 함께 학습하지만 Selective Search는 별도로 남습니다. |
| [Faster R-CNN](https://arxiv.org/abs/1506.01497){:target="_blank" rel="noopener"} | Feature 계산을 공유한 뒤에는 외부 proposal 생성이 병목이 됨 | 같은 backbone feature를 쓰는 RPN이 anchor의 objectness·offset을 예측합니다. Proposal 생성까지 학습하고, RoI head가 후보를 다시 분류·보정합니다. |
{: .reference-candidate-table}

[R-CNN 원본 그림](/study/autonomous-driving/lecture-04-perception-02/#adc-04-p32)의 후보마다 따로 놓인 ConvNet이 반복 계산을 보여줍니다. Fast R-CNN은 그 계산을 공유하고, Faster R-CNN은 공유 뒤에도 남아 있던 후보 생성 비용을 줄입니다. **‘영역마다 계산 → 이미지 특징 공유 → 후보 생성도 학습’**이 세 논문을 잇는 핵심입니다. 원 R-CNN의 실제 학습은 CNN fine-tuning·SVM·box regressor로 나뉘므로, 강의의 간략한 class/box head 그림을 Fast R-CNN과 같은 공동 학습 구조로 읽지 않습니다.

Two-stage는 backbone을 반드시 두 번 실행한다는 뜻이 아닙니다. 첫 단계가 object proposal을 고르고 두 번째 단계가 proposal을 다시 classifying·refining한다는 뜻입니다.

### 4.2 FPN: 빠르게 찾는 것과 작은 물체를 잘 보는 것은 다른 문제다

[FPN](https://arxiv.org/abs/1612.03144){:target="_blank" rel="noopener"}은 proposal 생성의 속도보다 **물체 크기가 달라질 때 feature가 충분한 정보를 가지는가**를 다룹니다. 깊은 층은 의미 정보가 강하지만 해상도가 낮고, 얕은 층은 위치가 세밀하지만 의미 정보가 상대적으로 약합니다.

<figure id="source-fpn-comparison">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-06-p31.png" | relative_url }}" alt="Image pyramid, single feature map, feature hierarchy와 top-down lateral connection을 가진 FPN의 비교" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf#page=31" | relative_url }}">Lecture 6, p. 31</a>.</figcaption>
</figure>

그림 (a)는 크기를 바꾼 입력마다 feature를 다시 만들고, (b)는 마지막 map 하나에서만 예측합니다. (c)는 여러 해상도를 쓰지만 얕은 층의 의미 정보가 부족할 수 있습니다. (d)의 FPN은 높은 층의 feature를 **위에서 아래로 확대하고 lateral connection으로 같은 해상도의 특징과 결합**합니다. 이로써 각 level에서 위치 정보와 의미 정보를 함께 씁니다. FPN은 독립적인 최종 detector가 아니라 특징을 만드는 구조이므로 Faster R-CNN의 RPN·RoI head에도, RetinaNet의 dense head에도 결합할 수 있습니다.

### 4.3 RetinaNet, YOLO, FCOS: 한 단계 안에서도 해결하는 문제가 다르다

Supplementary table — [Lecture 7 pp. 8–20](/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf#page=8)의 비교입니다. 강의는 RetinaNet 다음 YOLO를 소개하지만, 원형 YOLO가 더 먼저 발표되었으므로 이 배치를 그대로 발전 연표로 읽지 않습니다.

| 논문 | 문제의식 | 핵심 방법과 해석 |
|---|---|---|
| [RetinaNet](https://arxiv.org/abs/1708.02002){:target="_blank" rel="noopener"} | Dense prediction에서 쉬운 배경 anchor가 너무 많아 학습을 지배함 | FPN feature의 anchor마다 class·box를 예측하고 focal loss로 쉬운 예제의 기여를 줄입니다. FPN은 크기 문제, focal loss는 학습 불균형을 담당합니다. |
| [YOLO 원형](https://arxiv.org/abs/1506.02640){:target="_blank" rel="noopener"} | 후보를 따로 생성·분류하는 검출 과정을 하나의 예측 문제로 묶고 싶음 | 전체 영상을 한 network로 평가해 grid별 box와 class 정보를 직접 냅니다. 논문 초록의 핵심은 검출을 통합된 회귀 문제로 다룬다는 것이며, 이후 YOLO 버전의 anchor·loss 설계와 구분합니다. |
| [FCOS](https://arxiv.org/abs/1904.01355){:target="_blank" rel="noopener"} | Anchor 크기·비율·개수 설계와 anchor–GT matching에 의존함 | FPN의 위치마다 class, 네 변까지의 거리, centerness를 예측합니다. 미리 정한 box template을 없애되 multi-scale 표현과 dense prediction은 유지합니다. |
{: .reference-candidate-table}

**RetinaNet과 FCOS는 같은 one-stage 접근에서 box의 기준을 anchor와 point로 달리합니다.** [RetinaNet 그림](/study/autonomous-driving/lecture-07-perception-05/#adc-07-p09)은 한 위치에 여러 기준 box가 있고, [FCOS 그림](/study/autonomous-driving/lecture-07-perception-05/#adc-07-p18)은 한 위치에서 네 변까지 거리를 냅니다. FCOS도 class에는 focal loss를 사용하므로 anchor-free가 앞선 설계를 전부 버린다는 뜻은 아닙니다. 그림의 RetinaNet class 출력 표기는 원 논문과 달라, 계산에는 위치당 `A × K` sigmoid 점수와 `4A` box 값을 사용합니다(`A`: anchor 수, `K`: 전경 class 수).

RetinaNet의 binary focal loss는

$$
FL(p_t)=-\alpha_t(1-p_t)^{\gamma}\log p_t
$$

입니다. 잘 맞춘 쉬운 예제는 $$p_t\to1$$일 때 $$(1-p_t)^{\gamma}$$가 작아져 loss 기여가 줄어듭니다. Focal loss는 negative를 삭제하지 않습니다. 쉬운 negative의 gradient 비중을 줄입니다.

FCOS는 feature location이 GT box 안에 있으면 그 위치에서 box 네 변까지 거리 $$(l,t,r,b)$$를 예측합니다. Box 경계 가까운 위치는 한쪽 거리가 작고 localization quality가 낮기 쉬워 centerness로 score를 조절합니다. Anchor가 없다고 candidate나 assignment가 사라지는 것은 아닙니다.

강의 p. 12의 속도–AP 곡선은 당시 모델·입력·장치 조건에서의 비교입니다. p. 13의 45 fps도 원형 base YOLO의 결과이며, 모든 one-stage detector가 모든 two-stage detector보다 빠르거나 정확하다는 결론으로 확장하지 않습니다.

## 5. Segmentation: box보다 더 촘촘한 출력

Semantic segmentation은 같은 class의 두 차량을 같은 `car` pixel class로 표시할 수 있습니다. Instance segmentation은 차량마다 별도 mask를 냅니다. Road·sky처럼 셀 수 없는 영역은 보통 stuff, car·person처럼 개체 단위가 중요한 대상은 thing으로 구분합니다.

[FCN](https://arxiv.org/abs/1411.4038){:target="_blank" rel="noopener"}은 이미지 전체에 class 하나를 내는 분류 network를 **위치마다 class를 내는 dense predictor**로 바꿉니다. Fully connected layer를 convolution으로 바꾸어 spatial score map을 유지하고 upsampling해 pixel 단위 출력으로 복원합니다. Downsampling으로 얻은 넓은 문맥과 세밀한 경계를 함께 쓰기 위해 깊은 coarse feature와 얕은 fine feature를 skip으로 결합합니다. [Lecture 8 pp. 8–11](/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf#page=8)의 해상도 변화는 이 필요성을 보여줍니다.

1D에서 input `[a,b]`, kernel `[k_0,k_1,k_2]`, stride 2인 transposed convolution은 각 input이 kernel 모양을 output 위치에 더합니다. 겹치는 위치는 합산됩니다. Input 사이에 0을 넣고 적절한 kernel 방향과 padding을 적용하는 계산으로도 볼 수 있습니다. Output size는 padding·output padding까지 확인해야 합니다.

[Mask R-CNN](https://arxiv.org/abs/1703.06870){:target="_blank" rel="noopener"}은 **Faster R-CNN으로 찾은 각 객체의 box 안에서 어느 pixel이 그 객체인지**까지 예측합니다. [Lecture 8 p. 23](/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf#page=23)의 CNN+RPN → RoIAlign 뒤에서 class·box 경로와 mask 경로가 갈라집니다. RoI pooling의 좌표 반올림은 mask 경계를 어긋나게 할 수 있으므로 RoIAlign은 분수 좌표를 보간해 공간 정렬을 보존합니다. p. 24의 서로 다른 RoI target은 같은 영상에서도 객체마다 별도의 이진 mask를 학습한다는 뜻입니다.

여기에는 두 연결이 있습니다. **Faster R-CNN → Mask R-CNN은 검출 결과에 개체별 mask를 추가하는 직접적인 확장**입니다. FCN과 Mask R-CNN은 convolution으로 촘촘한 출력을 만든다는 공통점이 있지만, FCN은 영상 전체의 pixel class를, Mask R-CNN의 mask branch는 RoI 안 특정 객체의 포함 여부를 다룹니다. 또 FCN의 skip과 FPN의 lateral connection은 세밀한 위치·깊은 의미 정보를 결합한다는 공통 원리를 갖지만, 전자는 segmentation map 복원, 후자는 여러 detection scale의 특징 생성에 쓰입니다.

## 6. 3D perception: 깊이와 방향이 추가된다

### 6.1 3D box와 좌표계

Lab 2가 쓰는 LiDAR box는 $$(x,y,z,l,w,h,\theta)$$입니다. $$(x,y,z)$$는 box center, $$l,w,h$$는 길이·너비·높이, $$\theta$$는 yaw입니다. 그러나 dataset과 library마다 다음이 다를 수 있습니다.

- 축 방향: Camera는 흔히 $$x$$ right, $$y$$ down, $$z$$ forward이고, LiDAR는 $$x$$ forward, $$y$$ left, $$z$$ up을 씁니다.
- 위치 기준: KITTI camera label의 location은 bottom center입니다. Lab 2 helper는 box center로 바꿉니다.
- Dimension 순서: `h,w,l`, `l,h,w`, `l,w,h`가 혼재합니다.
- Yaw 기준축과 양의 회전 방향이 다릅니다.

수치만 복사하지 말고 coordinate convention을 먼저 고정해야 합니다.

### 6.2 Image-based 3D detection

**Camera 기반 방법들의 공통 질문은 ‘직접 측정하지 않은 depth를 무엇으로 보충할 것인가’입니다.** Mono3D는 3D 후보와 장면의 prior, MonoRCNN은 물체 높이와 투영 geometry, Pseudo-LiDAR는 depth의 표현 방식에 초점을 둡니다.

Supplementary table — Lecture 9의 [Mono3D, pp. 20–26](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=20), [MonoRCNN, pp. 27–31](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=27), [Pseudo-LiDAR, pp. 33–36](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=33)를 비교했습니다.

| 논문 | 문제의식 | 핵심 방법과 기여 |
|---|---|---|
| [Mono3D](https://openaccess.thecvf.com/content_cvpr_2016/html/Chen_Monocular_3D_Object_CVPR_2016_paper.html){:target="_blank" rel="noopener"} | 단안 영상의 많은 3D 해석 중 실제 객체일 가능성이 높은 후보를 어떻게 고를까요? | Ground plane·class별 크기 prior로 3D 후보를 만들고 영상에 투영합니다. Semantic·instance·shape·context 등의 단서로 점수를 매겨 후보를 좁히고 정제합니다. |
| [MonoRCNN](https://openaccess.thecvf.com/content/ICCV2021/html/Shi_Geometry-Based_Distance_Decomposition_for_Monocular_3D_Object_Detection_ICCV_2021_paper.html){:target="_blank" rel="noopener"} | RGB에서 거리 하나를 직접 회귀하면 오차 원인을 구분하기 어려움 | 물리 높이와 영상에 투영된 중심선 길이의 역수를 따로 예측하고 camera geometry로 depth를 복원합니다. 성분별 uncertainty를 학습해 거리 추정을 분해합니다. |
| [Pseudo-LiDAR](https://openaccess.thecvf.com/content_CVPR_2019/html/Wang_Pseudo-LiDAR_From_Visual_Depth_Estimation_Bridging_the_Gap_in_3D_CVPR_2019_paper.html){:target="_blank" rel="noopener"} | 추정 depth가 있어도 image grid에서 처리하면 metric 3D 이웃 관계를 활용하기 어려움 | Stereo 또는 monocular depth를 3D point cloud로 역투영하고 LiDAR용 detector에 넣습니다. Depth 추정뿐 아니라 **그 정보를 어떤 좌표 표현으로 처리하는가**도 중요하다는 기여입니다. |
{: .reference-candidate-table}

Mono3D와 MonoRCNN은 단안 모호성에 대응하는 서로 다른 해법입니다. Pseudo-LiDAR는 완성된 depth map을 point-cloud 표현으로 바꾸는 방향이라 다음 LiDAR 기반 detector들과 연결됩니다. 예를 들어 영상에서 이웃한 두 pixel도 하나가 가까운 차량, 다른 하나가 먼 배경이면 3D에서는 멀리 떨어집니다. 역투영은 이 차이를 meter 단위 좌표로 드러내지만, 잘못 추정한 depth 자체를 고쳐 주지는 않습니다. Camera frame에서 복원한 점을 LiDAR-frame detector에 넣는 경우에는 extrinsic으로 좌표 convention도 맞춰야 합니다.

강의의 MonoRCNN → Pseudo-LiDAR 순서는 개념 설명 순서입니다. Pseudo-LiDAR는 2019년, MonoRCNN은 2021년 논문이므로 앞 방법을 뒤 방법이 역사적으로 계승했다고 읽지 않습니다.

**Mono3D의 class semantic은 ‘어떤 종류인가’, instance semantic은 ‘같은 종류 중 어느 개체인가’를 구분합니다.** [Lecture 9 p. 24](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=24)의 class map에서는 차량들이 같은 색이고, instance map에서는 차량마다 색이 다릅니다. 따라서 후보가 차량 영역을 덮는지만 보는 것과 한 차량의 영역에 맞는지 보는 것은 다릅니다. 이 정보는 projection된 3D 후보의 점수를 매기는 데 쓰이며, instance 색은 실제 차체 색이나 시간에 걸친 tracking ID가 아닙니다.

MonoRCNN은 [Lecture 9 p. 27](/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf#page=27)의 물리 높이 $$H$$와 영상에 투영된 중심 수직선의 길이 $$h$$를 이용합니다. 보정된 pinhole camera에서 그 선의 두 끝점이 같은 depth를 갖는 수직선 모델이면

$$
Z=\frac{f_yH}{h}=f_yHh_{\mathrm{rec}},\qquad h_{\mathrm{rec}}=\frac{1}{h}
$$

입니다. $$Z,H$$는 m, 세로 초점거리 $$f_y$$와 $$h$$는 pixel, $$h_{\mathrm{rec}}$$은 pixel의 역수입니다. **$$h$$는 2D detection box 전체 높이가 아니라 PCL(projected central line) 길이**입니다. Network는 $$H$$와 $$h_{\mathrm{rec}}$$ 및 각 uncertainty를 예측하고 이 관계로 depth를 복원합니다. 같은 높이의 물체라면 PCL이 짧을수록 멀리 있다는 뜻입니다. <a href="https://arxiv.org/html/2104.03775" target="_blank" rel="noopener">MonoRCNN 원 논문, Figure 1–2</a>도 이 분해와 예측 대상을 구분합니다.

<details markdown="block">
<summary markdown="span">Derivation: Depth from physical and projected height</summary>

중심 수직선의 위·아래 끝점이 camera 좌표에서 같은 $$X,Z$$를 갖고 $$Y$$만 $$H$$만큼 다르면, pinhole 식 $$v=f_yY/Z+c_y$$에서 두 끝점의 pixel 차이는 $$h=f_yH/Z$$입니다. 양수인 $$h$$로 나누면 $$Z=f_yH/h$$를 얻습니다. Camera roll·pitch나 왜곡을 무시할 수 없는 장면에는 이 단순화의 적용 여부를 먼저 확인해야 합니다.

작성자 계산 예시로 $$f_y=800\ \mathrm{px}$$, $$H=1.5\ \mathrm{m}$$, $$h=120\ \mathrm{px}$$이면 $$Z=10\ \mathrm{m}$$입니다. 다른 조건이 같고 $$h=60\ \mathrm{px}$$이면 $$Z=20\ \mathrm{m}$$입니다. 두 계산 모두 길이 단위는 m이며, 예측 높이가 틀리면 복원한 depth도 틀릴 수 있습니다.

</details>

3D IoU는 oriented box의 교집합 volume을 합집합 volume으로 나눕니다. BEV IoU만 같아도 height overlap이 다르면 3D IoU는 다릅니다.

### 6.3 LiDAR-based 3D detection

LiDAR는 depth를 직접 측정하지만 점의 개수·순서가 고정되지 않고 공간 밀도도 불균일합니다. 여기서는 **point set의 특징을 만드는 방법**과 **그 특징에서 3D box를 찾는 detector**를 구분합니다.

Supplementary table — [Lecture 10 pp. 10–13](/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=10)의 point-set 특징 학습.

| 논문 | 해결하려는 문제 | 핵심 방법과 기여 |
|---|---|---|
| [PointNet](https://arxiv.org/abs/1612.00593){:target="_blank" rel="noopener"} | 규칙적인 pixel grid 없이 순서 없는 점들을 처리해야 함 | 점마다 같은 MLP를 적용하고 symmetric max pooling으로 모읍니다. 점 순서에 의존하지 않는 global feature를 만들며, point별 feature와 결합해 segmentation에도 사용합니다. |
| [PointNet++](https://arxiv.org/abs/1706.02413){:target="_blank" rel="noopener"} | 점을 곧바로 global pooling하면 주변 점들의 local geometry를 명시적으로 쌓기 어려움 | 중심점 sampling → 이웃 grouping → local PointNet을 반복합니다. 작은 이웃에서 넓은 영역으로 특징을 계층화하는 PointNet의 직접적인 확장입니다. |
{: .reference-candidate-table}

[PointNet 원본 그림](/study/autonomous-driving/lecture-10-3d-perception-02/#adc-10-p12)의 max pooling은 점 축을 하나의 특징으로 모으는 위치입니다. PointNet++는 그 연산을 여러 local neighborhood 안에서 먼저 수행합니다. 두 방법을 그 자체로 완성된 3D box detector라고 부르면 이후 proposal·box head의 역할이 빠집니다.

PointNet이 point cloud의 세 조건을 처리하는 방식은 구분해야 합니다.

- **가변 점 수:** 각 점에 shared MLP를 적용하고 점 축으로 max pooling하면, 점 수 $$N$$이 달라도 global feature 길이 $$K$$는 같습니다. 점을 추가·제거해도 특징 값이나 예측이 같다는 뜻은 아닙니다.
- **순열 불변성:** 같은 점들을 재배열하면 shared MLP의 특징도 순서만 바뀝니다. 각 특징 차원에서 max의 후보 값은 같으므로 global feature와 물체 분류 결과는 그대로입니다. 점별 segmentation 결과는 입력과 함께 재배열되는 순열 등변성을 갖습니다.
- **회전 대응:** T-Net이 입력·특징의 정렬을 학습하지만 모든 회전에 대한 엄밀한 불변성을 보장하지는 않습니다. 점 순서의 변경과 좌표 값의 회전은 다른 연산입니다.

Supplementary table — Lecture 10의 [PointRCNN, pp. 16–23](/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=16), [VoxelNet, pp. 24–32](/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=24), [PIXOR, pp. 33–37](/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=33)의 detector 비교.

| 논문 | 문제의식 | 핵심 방법과 연결 |
|---|---|---|
| [PointRCNN](https://openaccess.thecvf.com/content_CVPR_2019/html/Shi_PointRCNN_3D_Object_Proposal_Generation_and_Detection_From_Point_Cloud_CVPR_2019_paper.html){:target="_blank" rel="noopener"} | 넓은 3D 공간에서 실제 객체 주변의 후보를 효율적으로 만들고 정밀하게 보정해야 함 | PointNet++ backbone으로 점별 foreground를 예측하고 그 점에서 3D proposal을 만듭니다. 후보 주변 점을 canonical coordinate로 옮겨 두 번째 단계에서 box를 정제합니다. |
| [VoxelNet](https://openaccess.thecvf.com/content_cvpr_2018/html/Zhou_VoxelNet_End-to-End_Learning_CVPR_2018_paper.html){:target="_blank" rel="noopener"} | 점군을 grid로 바꿀 때 수작업 요약 특징에 의존함 | Voxel 안의 점과 중심 대비 위치를 VFE로 학습해 voxel feature를 만듭니다. 3D convolution으로 이웃 정보를 모은 뒤 BEV detection head로 box를 예측합니다. |
| [PIXOR](https://openaccess.thecvf.com/content_cvpr_2018/html/Yang_PIXOR_Real-Time_3D_CVPR_2018_paper.html){:target="_blank" rel="noopener"} | 3D 공간 전체에서 convolution을 수행하는 계산 부담 | 높이별 occupancy 등을 BEV channel로 표현하고 2D CNN으로 oriented box를 밀집 예측합니다. Proposal 없이 top-down 검출을 수행하며 수직 표현과 계산량 사이의 선택을 합니다. |
{: .reference-candidate-table}

**PointNet → PointNet++ → PointRCNN은 특징 학습의 확장과 실제 backbone 활용 관계**입니다. 반면 PointRCNN·VoxelNet·PIXOR는 순서대로 이전 논문을 대체한 계보가 아닙니다. [PointRCNN 그림](/study/autonomous-driving/lecture-10-3d-perception-02/#adc-10-p22)은 점 기반 후보와 정제, [VoxelNet 그림](/study/autonomous-driving/lecture-10-3d-perception-02/#adc-10-p29)은 voxel 내부 학습 뒤 3D 이웃 처리, [PIXOR 그림](/study/autonomous-driving/lecture-10-3d-perception-02/#adc-10-p37)은 BEV에서의 2D 처리를 보여줍니다. 같은 점군을 **점 집합으로 유지할지, 3D grid로 묶을지, 높이를 channel에 담은 2D grid로 바꿀지**가 비교의 축입니다.

2D 검출과도 연산의 역할을 비교할 수 있습니다. PointRCNN의 proposal–refinement는 Faster R-CNN처럼 두 단계지만, 후보를 만드는 입력과 방식은 다릅니다. VoxelNet의 모듈 이름에 `RPN`이 있어도 원 모델에는 별도 RoI 재판정 단계가 없으므로 이름만 보고 two-stage라고 분류하면 안 됩니다. PIXOR의 BEV box도 겹칠 수 있어 oriented NMS가 필요합니다.

### 6.4 Camera–LiDAR fusion

두 센서는 서로 다른 정보를 주지만, 어느 영역이 같은 객체에 속하는지 먼저 맞춰야 합니다. **Frustum PointNets는 영상의 2D 후보로 3D 탐색 범위를 좁히고, MV3D는 LiDAR에서 만든 3D 후보를 기준으로 여러 view를 모읍니다.**

Supplementary table — [Lecture 11 pp. 11–21](/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf#page=11)의 후보 생성과 정보 결합 비교.

| 논문 | 해결하려는 문제 | 핵심 방법과 기여 |
|---|---|---|
| [Frustum PointNets](https://openaccess.thecvf.com/content_cvpr_2018/html/Qi_Frustum_PointNets_for_CVPR_2018_paper.html){:target="_blank" rel="noopener"} | 넓은 3D 공간을 처음부터 탐색하기 어려움 | 2D detector의 box를 camera ray 방향의 frustum으로 확장해 점을 고릅니다. PointNet 계열로 객체 점을 분리하고, 중심 보정 뒤 가려진 부분까지 포함한 amodal 3D box를 추정합니다. |
| [MV3D](https://openaccess.thecvf.com/content_cvpr_2017/html/Chen_Multi-View_3D_Object_CVPR_2017_paper.html){:target="_blank" rel="noopener"} | LiDAR geometry와 RGB appearance를 같은 객체 단위로 결합해야 함 | LiDAR BEV에서 3D proposal을 만들고 BEV·LiDAR front view·RGB에 투영합니다. 각 RoI feature를 deep fusion해 class와 3D box를 정제합니다. |
{: .reference-candidate-table}

[Frustum PointNets 원본 그림](/study/autonomous-driving/lecture-11-3d-perception-03/#adc-11-p14)은 PointNet 계열을 segmentation·중심 보정·box 추정에 활용하는 연결을 보여줍니다. 다만 2D detector가 객체를 놓쳐 frustum 자체가 없으면 뒤의 point 처리도 그 객체를 복구하기 어렵습니다. [MV3D 원본 그림](/study/autonomous-driving/lecture-11-3d-perception-03/#adc-11-p21)은 BEV proposal을 각 view에 대응시키므로 image detector의 후보에 직접 의존하지 않지만, BEV 후보 누락이나 잘못된 calibration은 뒤의 fusion을 제한합니다. 후보 recall 개선과 calibration·시간 정렬 점검이 각각 필요한 이유입니다. 강의에서는 Frustum PointNets 뒤에 MV3D를 설명하지만 발표는 MV3D(2017), Frustum PointNets(2018) 순입니다.

Fusion 전에는 공간 calibration, timestamp synchronization, 같은 object region의 대응이 필요합니다. Camera와 LiDAR feature를 단순 concatenate해도 좌표와 시간이 어긋나면 같은 물체의 정보가 아닙니다.

[Lecture 11 p. 20](/assets/pdfs/study/autonomous-driving/lecture-11-3d-perception-03.pdf#page=20)의 fusion 비교는 **언제, 몇 번 결합하는가**로 읽습니다. Early fusion은 입력 또는 초기 feature에서, late fusion은 각 stream이 고수준 feature를 만든 뒤 결합합니다. Deep fusion은 중간 layer마다 정보를 반복 교환합니다. MV3D 그림의 `C`는 concatenation, `M`은 element-wise mean입니다. Deep fusion에서는 한 번 합친 hidden state를 다음 단계의 각 view branch가 함께 받아 처리합니다.

## 7. Lab 1: Two-stage와 one-stage를 tensor 흐름으로 읽기

<figure id="source-rpn-output">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-assignment2-rpn-proposals.png" | relative_url }}" alt="Init와 COCO 모델의 top 50 RPN proposal과 정답 box" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-02-two-stage-vs-one-stage.ipynb" | relative_url }}">Assignment 2 notebook, cell 27 (0-based), saved output</a>.</figcaption>
</figure>

청록 box는 상위 50개 proposal, 흰 점선은 GT입니다. 오른쪽 COCO 모델에서 물체 주변으로 후보가 모이는지 왼쪽 초기화 모델과 비교합니다. 이 단계는 class를 확정한 최종 detection이 아니므로 proposal 수가 많다고 recall이나 precision이 높다고 단정하지 않습니다.

### 7.1 입력에서 FPN까지

Penn–Fudan dataset의 instance mask에서 instance별 foreground pixel의 최소·최대 좌표를 구해 2D box를 만듭니다. 이미지 transform은 resize, normalization, batch padding을 수행합니다. 이 셋을 혼동하면 box coordinate와 feature coordinate를 잘못 비교하게 됩니다.

Faster R-CNN backbone은 FPN feature P2–P6을, notebook의 RetinaNet은 P3–P7을 사용합니다. Level $$l$$의 feature shape가 $$C\times H_l\times W_l$$이고 위치당 anchor template 수가 $$A_l$$이면 해당 level anchor 수는

$$
N_l=H_lW_lA_l.
$$

전체 anchor 수는 $$\sum_lN_l$$입니다. Padded image size와 feature shape가 달라지면 anchor 수가 달라지므로 고정 숫자로 외우지 않습니다.

### 7.2 Anchor label과 sampling

**Anchor는 미리 정한 기준 box, GT는 데이터의 정답 box, prediction은 네트워크가 예측한 offset을 anchor에 적용한 box**입니다. GT는 학습 label과 목표 offset을 만드는 데 쓰이며 추론 입력이 아닙니다. RPN prediction은 proposal 후보이고, 최종 class·box는 다음 detection head에서 정제합니다. RPN의 전형적인 label은 다음과 같습니다.

- Positive: GT와 높은 IoU를 갖거나 각 GT의 최고-IoU anchor입니다.
- Negative: 모든 GT와 낮은 IoU를 갖습니다.
- Ignore: 그 사이 영역이며 loss에서 제외합니다.

각 GT의 최고-IoU anchor를 positive로 보장하는 low-quality match 규칙은 threshold를 넘는 anchor가 없는 GT도 학습 후보를 갖게 합니다. 그 뒤 positive·negative 일부를 sampling해 RPN loss를 계산합니다. `전체 anchor label 분포`와 `loss에 실제 사용한 sampled anchor`는 다른 통계입니다.

### 7.3 Box encode와 decode

Anchor center·size를 $$(x_a,y_a,w_a,h_a)$$, GT를 $$(x_g,y_g,w_g,h_g)$$라 하면 대표적인 2D target은

$$
t_x=\frac{x_g-x_a}{w_a},\quad
t_y=\frac{y_g-y_a}{h_a},\quad
t_w=\log\frac{w_g}{w_a},\quad
t_h=\log\frac{h_g}{h_a}.
$$

위 $$t$$는 GT를 encode한 **목표값**입니다. 실제 추론에서는 네트워크의 예측 offset $$\hat{t}$$를 decode합니다.

$$
\hat{x}=\hat{t}_xw_a+x_a,\quad
\hat{y}=\hat{t}_yh_a+y_a,\quad
\hat{w}=e^{\hat{t}_w}w_a,\quad
\hat{h}=e^{\hat{t}_h}h_a.
$$

위치 offset은 이동을 anchor 크기로 나누고, 크기 offset은 양수인 비율에 자연로그를 취합니다. 따라서 모두 무차원입니다. 예측 offset이 목표값과 다르면 decode한 box도 GT와 다릅니다.

<details markdown="block">
<summary markdown="span">Derivation: A small box encode and decode trace</summary>

Anchor가 center $$(50,40)$$, size $$(20,10)$$이고 GT가 center $$(54,38)$$, size $$(30,5)$$라고 하겠습니다.

$$
t_x=4/20=0.2,\qquad
t_y=-2/10=-0.2,
$$

$$
t_w=\log(1.5)\approx0.4055,\qquad
t_h=\log(0.5)\approx-0.6931.
$$

이 **목표 offset**을 decode하면 $$0.2(20)+50=54$$, $$-0.2(10)+40=38$$, $$e^{0.4055}(20)\approx30$$, $$e^{-0.6931}(10)\approx5$$로 GT가 복원됩니다. Encode/decode의 역연산 검산이지 실제 네트워크 예측이 정답과 같다는 뜻은 아닙니다. Width와 height는 양수여야 하며 anchor size가 0이면 정의되지 않습니다.

</details>

### 7.4 Faster R-CNN code path

1. Image transform이 normalized padded batch와 resized target을 만듭니다.
2. Backbone + FPN이 multi-scale feature를 만듭니다.
3. RPN head가 anchor별 objectness와 4-d offset을 예측합니다.
4. Decode, clipping, small-box 제거, score top-K, NMS, proposal cap을 거쳐 proposal을 만듭니다.
5. RoIAlign이 proposal마다 고정 크기 feature를 만듭니다.
6. Box head가 background 포함 class logit과 class별 box refinement를 예측합니다.
7. Class별 decode, score filter, NMS가 최종 detection을 만듭니다.

Proposal 수가 줄었다고 NMS 하나의 효과라고 단정하면 안 됩니다. Top-K, clipping, size filter, score filter, NMS와 final cap이 함께 작동합니다.

### 7.5 RetinaNet code path

1. FPN P3–P7의 모든 location에 dense anchor를 만듭니다.
2. Classification subnet이 anchor별 sigmoid class logit을 만듭니다.
3. Regression subnet이 anchor별 4-d offset을 만듭니다.
4. Anchor–GT matching으로 positive·negative·ignore를 정합니다.
5. Classification loss는 ignore를 제외한 유효 anchor에 적용합니다.
6. Box regression loss는 positive anchor에만 적용합니다.
7. Per-level score filter와 top-K, decode, clipping, class별 NMS를 거쳐 최종 detection을 만듭니다.

Notebook의 `num_classes=2`, custom foreground label 1 설정에서는 RetinaNet의 두 sigmoid column을 softmax background·foreground 두 칸으로 읽으면 안 됩니다. Public API의 class-index convention까지 확인해야 합니다.

### 7.6 Focal loss, prior와 plot 해석

RetinaNet classification bias를 foreground prior $$\pi$$에 맞추는 대표 초기화는

$$
b=-\log\frac{1-\pi}{\pi}.
$$

$$\pi=0.01$$이면 초기 sigmoid probability가 약 0.01이 됩니다. 이는 정답 비율을 강제하는 규칙이 아니라, 학습 시작 때 수많은 dense anchor가 높은 foreground score를 내지 않도록 하는 초기 조건입니다.

Lab 1의 plot은 다음처럼 읽습니다.

| Plot | 관찰할 것 | 단정하면 안 되는 것 |
|---|---|---|
| FPN activation | Level별 spatial resolution과 object response | 밝기만으로 해당 level이 정답이라는 결론 |
| Anchor grid | Center spacing, scale, aspect ratio, GT와 겹침 | 가장 높은 IoU anchor가 최종 detection이라는 결론 |
| Objectness heatmap | RPN이 proposal 후보를 어디에 집중합니까 | 최종 class score와 같다는 해석 |
| Proposal before/after filter | 후보 수와 중복이 줄어드는 과정 | 감소가 NMS만의 효과라는 해석 |
| CE vs focal map | 쉬운 negative의 loss 비중이 감소합니까 | Focal loss가 모든 hard example을 올바르게 만든다는 결론 |
| Epoch snapshots | 같은 trace image에서 score·box가 변하는 흐름 | 한 이미지로 일반 성능·속도 우열을 결론내림 |
| Proposal recall vs detection P/R | 1단계 coverage와 최종 판정의 차이 | Fixed threshold P/R을 AP나 COCO mAP로 부름 |

## 8. Lab 2: KITTI point에서 VoxelNet detection까지

<figure id="source-voxel-output">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-assignment3-voxelization.png" | relative_url }}" alt="Voxel별 점 수 histogram과 BEV grid 및 높이 bin 비교" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/notebooks/study/autonomous-driving/assignment-03-lidar-3d-object-detection.ipynb" | relative_url }}">Assignment 3 notebook, cell 25 (0-based), saved output</a>.</figcaption>
</figure>

왼쪽은 비어 있지 않은 voxel의 점 수 분포이며 세로축은 로그 척도입니다. 빨간 T=32 선은 voxel 하나에서 남길 최대 점 수를 표시합니다. 가운데의 0.2 m 격자와 오른쪽의 0.4 m 높이 구간은 공간 분할 크기입니다. 점 수 제한과 voxel의 물리적 크기를 분리해야 sparse 입력이 고정 tensor로 바뀌는 과정을 이해할 수 있습니다.

### 8.1 실제 KITTI 관찰과 synthetic 학습의 구분

| 구간 | Data | 목적 | 결과 해석 |
|---|---|---|---|
| Part A | 공개 KITTI sample frame 1개 | 실제 point cloud 형식, 좌표 변환, 3D·BEV·range image·camera projection 확인 | 실제 측정 자료의 표현 관찰 |
| Part B training | Ray-casting synthetic train 600 scenes | 축소 VoxelNet을 15 epochs 학습 | 합성 분포 안의 학습 결과 |
| Part B validation | Synthetic validation 60 scenes | Center-distance AP, P@0.5, R@0.5 계산 | 실습용 합성 metric |
| B8 transfer | 실제 KITTI sample frame | Synthetic-trained model의 domain gap 시각화 | 정성 비교. KITTI 공식 성능 아님 |

**실제 KITTI 관찰, 합성 데이터 학습, 실제 장면으로의 적용은 서로 다른 단계입니다.** 합성 validation AP를 KITTI 공식 성능으로 해석할 수 없습니다.

### 8.2 KITTI coordinate를 LiDAR box로 바꾸기

실제 sample `.bin`은 header 없는 float32 배열이며 4개씩 읽어 $$(x,y,z,\mathrm{reflectance})$$ point를 만듭니다. 저장 sample의 shape는 $$(17238,4)$$로, 각 행이 한 point입니다.

KITTI label의 camera box location은 bottom center이고 camera의 $$y$$는 아래 방향입니다. Notebook helper는 먼저 camera location의 $$y$$에서 height의 절반을 빼 box center로 만듭니다. 이후 inverse `lidar2cam` transform으로 LiDAR coordinate로 옮기고 dimension을 $$(l,w,h)$$로 재배열합니다. Yaw는 notebook convention에서

$$
\theta_{\mathrm{lidar}}=-r_y-\frac{\pi}{2}
$$

로 바꿉니다. 이 식만 외우기보다 source·target coordinate의 축과 회전 방향을 함께 확인해야 합니다.

### 8.3 Point cloud의 집합 성질과 네 표현

Point cloud는 frame마다 point 수가 달라지는 순서 없는 집합입니다. Point 행을 permutation해도 같은 scene입니다. 그러나 array 값의 행 순서는 달라지므로 point network는 permutation-invariant aggregation을 설계해야 합니다.

| 표현 | 축과 값 | 보존하는 정보 | 잃거나 근사하는 정보 |
|---|---|---|---|
| Raw 3D points | point마다 $$x,y,z,r$$ | 개별 3D measurement | Regular grid가 없어 batch convolution이 어려움 |
| BEV | $$x,y$$ grid, height·occupancy·feature | Metric ground-plane footprint, perspective overlap 감소 | Height를 channel·statistic으로 요약. 서로 가까운 BEV box는 여전히 겹칠 수 있음 |
| Range image | elevation × azimuth, 값은 range | LiDAR scan topology | Cartesian object shape가 왜곡될 수 있음 |
| Camera projection | Pixel에 point depth·feature | RGB와 point의 correspondence | Occlusion과 sparse projection, calibration error |

같은 각도 간격으로 조사하는 LiDAR에서는 원거리의 작은 물체가 적은 point로 관측되기 쉽습니다. 거리뿐 아니라 물체 크기·가림·반사 특성도 point 수에 영향을 줍니다.

### 8.4 Voxelization

Notebook 설정은 다음 범위를 씁니다.

$$
x\in[0,51.2),\quad y\in[-25.6,25.6),\quad z\in[-3,1)\ \mathrm{m}.
$$

Voxel size는 $$(0.2,0.2,0.4)\ \mathrm{m}$$입니다. 따라서 grid는

$$
N_x=256,\quad N_y=256,\quad N_z=10
$$

이고 전체 cell은 655,360개입니다. Point $$(x,y,z)$$의 integer voxel index는 floor 연산으로 구합니다.

$$
i_x=\left\lfloor\frac{x-x_{\min}}{0.2}\right\rfloor,\quad
i_y=\left\lfloor\frac{y-y_{\min}}{0.2}\right\rfloor,\quad
i_z=\left\lfloor\frac{z-z_{\min}}{0.4}\right\rfloor.
$$

범위 밖 point를 제거하고 같은 index의 point를 묶습니다. 계산 설명은 $$(i_x,i_y,i_z)$$ 순서지만 `voxelize`가 반환하는 `coords` 열 순서는 **`(iz, iy, ix)`**입니다. Dense tensor에 scatter한 뒤 shape 순서는 **`(B,C,N_z,N_y,N_x)`**입니다. Voxel당 최대 point 수는 32입니다. 32개가 넘으면 shuffle 뒤 처음 32개를 남깁니다. 장면당 non-empty voxel도 최대 20,000개로 제한합니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: From point coordinates to grouped voxels</summary>

저장된 synthetic validation scene에서는 41,819 input points 중 40,950개가 범위 안에 있었고, 7,236개 non-empty voxel을 만들었습니다. 전체 grid의 약 1.10%입니다. 103개 voxel이 32-point limit을 넘어 sampling됐습니다. 이는 한 scene의 실행 기록이며 frame마다 달라집니다.

`voxelize`의 상태 변화는 다음과 같습니다.

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

Padding point는 0으로 채우고 `npts`에서 만든 mask로 실제 point와 구분합니다. Shuffle가 있으므로 32개를 넘는 voxel의 선택된 subset은 seed·호출 순서에 따라 달라질 수 있습니다.

</details>

### 8.5 VFE: point-wise 정보와 voxel context를 합친다

각 point의 VFE input은

$$
[x,y,z,r,x-\bar{x}_v,y-\bar{y}_v,z-\bar{z}_v]
$$

의 7차원입니다. $$(\bar{x}_v,\bar{y}_v,\bar{z}_v)$$는 같은 voxel의 실제 point centroid입니다. Offset은 voxel 안의 local shape를 표현합니다.

VFE layer는 모든 point에 같은 `Linear + BN + ReLU`를 적용해 point-wise feature를 만듭니다. 같은 voxel의 point 축으로 element-wise max를 취해 locally aggregated feature를 만듭니다. 이 vector를 모든 point에 복제해 point-wise feature와 concatenate합니다.

Shared point function과 symmetric max는 **같은 selected point set 안에서의 순서 불변성**을 줍니다. Sampling으로 선택된 점 자체가 바뀌거나 좌표 변환으로 voxel 소속이 달라지는 것은 별개입니다. Rotation invariance나 training mode의 stochastic 실행까지 보장하지는 않습니다.

### 8.6 Sparse-to-dense, 3D convolution, BEV RPN

VFE가 만든 voxel별 vector를 3D grid에 배치하고, 3D convolution으로 주변 voxel과 height 정보를 처리합니다. 이후 남은 height axis를 channel에 합쳐 2D BEV RPN에 전달합니다. **Height를 처음부터 무시하는 것이 아니라, 처리한 height 정보를 channel 표현에 담는 과정**입니다.

<details markdown="block">
<summary markdown="span">Code Walkthrough: Stored VoxelNet tensor shapes</summary>

Notebook에 저장된 한 scene의 tensor trace입니다. Non-empty voxel 수는 scene마다 달라집니다.

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

BEV reshape에서 $$32\times3=96$$이므로 channel 수가 96이 됩니다. 그 뒤 128×128 위치마다 4개 anchor를 배치해 $$128\times128\times4=65{,}536$$개 prediction을 만듭니다.

</details>

### 8.7 3D anchor label과 box target

128×128 output grid의 각 location에 Car 0°·90°, Pedestrian 0°·90° anchor 네 개가 있어 총 65,536개입니다.

여기서 **voxel은 입력 점을 묶는 공간 cell이고, anchor는 출력 box 회귀의 기준**입니다. 3D anchor는 중심·길이·폭·높이·yaw를 가지며, 네트워크가 예측한 일곱 보정값으로 최종 3D box를 만듭니다. GT는 이 보정의 목표를 정합니다. Lab 2의 개수·class·각도 설정은 해당 notebook의 설정이지 모든 VoxelNet의 고정값이 아닙니다.

Anchor와 GT의 BEV IoU threshold는 notebook 설정에서 다음과 같습니다.

| Class | Positive | Negative | Ignore |
|---|---:|---:|---:|
| Car | $$\mathrm{IoU}\ge0.60$$ | $$\mathrm{IoU}<0.45$$ | 그 사이의 non-positive anchor |
| Pedestrian | $$\mathrm{IoU}\ge0.50$$ | $$\mathrm{IoU}<0.35$$ | 그 사이의 non-positive anchor |

각 GT의 최고-IoU anchor도 overlap이 0보다 크면 positive로 보장합니다. Notebook의 BEV IoU는 box의 yaw를 0°·90° 방향으로 근사한 axis-aligned overlap입니다. 임의 방향 box의 정확한 rotated IoU와 구분합니다.

3D target에서 horizontal center는 anchor diagonal $$d_a=\sqrt{l_a^2+w_a^2}$$로 정규화합니다.

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

Notebook의 yaw difference는 $$\pi$$ 주기로 정규화되어 앞·뒤가 뒤집힌 box 방향을 같은 것으로 취급합니다. 별도 heading 분류기를 쓰는 일반 detector 전체의 성질은 아닙니다.

### 8.8 Loss와 class imbalance

현재 config `CLS_LOSS = "voxelnet"`은 positive와 negative BCE sum을 각각 해당 개수로 나눈 뒤 가중합니다.

$$
L=\frac{\alpha}{N_{pos}}\sum_{i\in pos}L_{cls}(p_i,1)
+\frac{\beta}{N_{neg}}\sum_{j\in neg}L_{cls}(p_j,0)
+\frac{1}{N_{pos}}\sum_{i\in pos}L_{reg}(u_i,u_i^*).
$$

Notebook은 $$\alpha=1.5$$, $$\beta=1.0$$을 쓰고 regression은 positive anchor에만 Smooth L1을 적용합니다. $$N_{pos},N_{neg}$$는 각각 유효 positive·negative 수이며 코드에서는 빈 집합으로 나누지 않도록 각 분모를 최소 1로 제한합니다. 별도 평균은 훨씬 많은 negative가 classification loss를 개수만으로 압도하지 않게 합니다.

<details markdown="block">
<summary markdown="span">Derivation: Separate positive and negative loss normalization</summary>

저장 trace의 한 scene에는 positive 65개, negative 65,374개, ignore 97개가 있었습니다. 유효 anchor를 한 번에 평균하면 positive 비율은 $$65/(65+65374)\approx0.10\%$$입니다.

모든 유효 anchor에서 $$p=0.5$$라고 둔 설명용 조건에서는 BCE가 모두 $$-\log0.5$$로 같습니다. 별도 평균 후 positive·negative classification 항은 각각 $$1.5(-\log0.5)$$와 $$1.0(-\log0.5)$$입니다. 따라서 두 classification 항의 합에서 positive 항은 $$1.5/(1.5+1)=60\%$$를 차지합니다. 실제 학습에서는 예측값마다 BCE가 달라지므로 60%가 항상 유지되는 것은 아닙니다.

코드는 `CLS_LOSS = "focal"`도 지원하지만 저장 학습 run의 설정은 `"voxelnet"`입니다.

</details>

### 8.9 Training phase, postprocessing, metric

후처리는 class score filtering, 상위 후보 선택, box decode, class별 NMS 순서로 최종 prediction set을 만듭니다. 평가는 각 scene·class 안에서 prediction을 confidence 순으로 처리하고, 아직 사용하지 않은 같은 class GT 중 BEV center가 가장 가까운 것을 one-to-one match합니다. 이후 validation scenes의 prediction을 class별 confidence 순으로 모아 PR curve를 만듭니다.

- Car: center distance $$<2\ \mathrm{m}$$
- Pedestrian: center distance $$<1\ \mathrm{m}$$
- AP: center-distance match의 precision–recall area
- P@0.5, R@0.5: 위 후처리로 남은 set에서 score threshold 0.5를 적용한 fixed operating point

<details markdown="block">
<summary markdown="span">Figure Analysis: Saved training and validation results</summary>

저장 run은 synthetic train 600 scenes, batch size 4, 15 epochs, AdamW와 left–right flip augmentation을 사용했습니다. CUDA에서는 mixed precision을 씁니다. Snapshot은 epoch 0, 1, 3, 8, 15에 저장됐습니다.

`postprocess` 설정은 sigmoid score **0.1 초과**, 전체 top 500, 7-d decode, class별 approximate BEV NMS, 장면당 최대 100 detections입니다. Epoch 15의 AP는 60개 synthetic validation scenes에서 Car 0.948, Pedestrian 0.912였습니다. 위 center-distance 규칙과 후처리 조건에서 얻은 값입니다.

Score map의 집중과 loss 감소는 optimization 진행을 보여 줍니다. 실제 환경에서의 일반화 성능을 입증하지는 않습니다.

</details>

### 8.10 Synthetic-to-real 경계

Simulator는 단순화한 물체에 ray를 쏘고 range noise와 point dropout을 추가합니다. 실제 환경의 곡면·유리·식생·경사·반사 특성과 장면 분포를 모두 재현하지는 못합니다. 이 **domain gap** 때문에 합성 장면에서 잘 학습한 box가 실제 KITTI sample에서는 어긋날 수 있습니다. B8은 이를 관찰하는 정성 비교입니다. 실제 데이터로 fine-tuning하고 같은 평가 규칙으로 검증하는 것이 이후 보완 방향입니다.

## 9. 자주 섞이는 개념

| 혼동 | 올바른 구분 |
|---|---|
| Anchor = prediction | Anchor는 기준 box, prediction은 anchor offset을 decode한 box입니다 |
| Objectness = class score | RPN objectness는 object proposal 가능성, RoI class score는 class 판정입니다 |
| NMS = evaluation matching | NMS는 prediction끼리 중복 억제, evaluation은 prediction과 GT의 one-to-one matching입니다 |
| Fixed P/R = AP | P/R은 한 threshold, AP는 score sweep의 PR curve 면적입니다 |
| BEV IoU = 3D IoU | BEV overlap은 height overlap을 직접 포함하지 않습니다 |
| PointNet 순서 불변 = 회전 불변 | Symmetric aggregation은 point order에 대한 invariance입니다 |
| PointNet = PointRCNN | PointNet 계열은 point feature를 학습하는 기반 구조이고, PointRCNN은 이를 활용해 proposal과 3D box를 만드는 detector입니다 |
| VoxelNet = 3D convolution만 | Voxel grouping, VFE, 3D middle layers, BEV RPN, anchor head와 후처리의 전체 흐름입니다 |
| 강의의 소개 순서 = 논문의 발전 순서 | 직접 확장한 방법과 같은 문제에 다른 표현을 선택한 방법을 구분해야 합니다 |

## 10. 마지막 핵심 정리

1. Sensor는 서로 다른 물리량과 실패 조건을 가집니다. Camera pixel은 ray를, LiDAR point는 직접 측정한 surface geometry를 나타냅니다.
2. Projection에는 coordinate convention, intrinsic, extrinsic과 positive depth 조건이 필요합니다. Stereo depth 오차는 원거리에서 빠르게 커집니다.
3. Detection의 공통 흐름은 feature, candidate, label assignment, class·box prediction, filtering·NMS, GT matching과 AP입니다.
4. R-CNN → Fast R-CNN은 region별 CNN 반복을 feature 공유로 줄이고, Faster R-CNN은 외부 proposal 생성을 RPN으로 바꿉니다. FPN은 별도로 작은 물체의 위치 정보와 강한 semantics를 결합합니다.
5. RetinaNet은 dense prediction의 foreground–background imbalance를 focal loss로 완화합니다. FCOS는 anchor box 대신 위치별 거리와 centerness를 예측합니다. Mask R-CNN은 Faster R-CNN에 정밀한 RoI 정렬과 instance mask branch를 더합니다.
6. 단안 3D는 모호한 depth를 다루는 방법이 핵심입니다. Mono3D는 geometry·semantic prior로 후보를 평가하고, MonoRCNN은 거리 추정을 기하 항으로 분해하며, Pseudo-LiDAR는 추정 depth를 3D point 표현으로 바꿉니다.
7. PointNet++는 PointNet에 지역 구조 학습을 더하고 PointRCNN은 이를 3D 검출에 활용합니다. VoxelNet·PIXOR는 각각 voxel·BEV를 계산 중심으로 선택합니다. Fusion에서는 Frustum PointNets가 image box에서, MV3D가 LiDAR BEV에서 후보를 시작합니다.
8. Lab 1은 Faster R-CNN의 proposal–refinement와 RetinaNet의 dense prediction을 같은 image에서 추적합니다.
9. Lab 2는 실제 KITTI 표현 관찰과 synthetic VoxelNet training을 분리합니다. 저장 AP는 synthetic center-distance AP입니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

- **계산:** projection·stereo depth, IoU·AP, box encode·decode, voxel index를 숫자를 바꿔 직접 계산합니다.
- **비교:** two-stage와 one-stage, semantic과 instance segmentation, image·point·voxel·BEV 표현의 차이를 설명합니다.
- **논문:** 각 방법이 바꾼 병목·표현·출력을 설명합니다. 직접 확장한 구조인지, 같은 문제의 대안인지 구분합니다.
- **Lab 1:** image, FPN, anchor, RPN proposal, RoI refinement의 입력·출력을 추적하고 RetinaNet의 dense head와 비교합니다.
- **Lab 2:** point, voxel, VFE, 3D convolution, BEV RPN 순서로 tensor의 축이 어떻게 바뀌는지 설명합니다.
- **평가:** IoU의 비교 대상, AP의 matching 규칙, 사용한 데이터 분포를 명시합니다.

</details>

## 복습 질문

<details markdown="block">
<summary markdown="span">1. 단안 camera pixel 하나로 metric 3D point를 유일하게 정할 수 없는 이유는 무엇입니까?</summary>

답변: Pixel과 intrinsic은 camera center에서 나가는 ray의 방향만 정합니다. Ray 위의 depth $$Z$$는 자유 변수이므로 크기·거리 prior, stereo disparity, LiDAR 또는 learned depth 같은 추가 정보가 필요합니다.

</details>

<details markdown="block">
<summary markdown="span">2. Stereo에서 원거리 depth가 불안정해지는 이유는 무엇입니까?</summary>

답변: $$Z=fB/d$$이고 $$\partial Z/\partial d=-fB/d^2$$입니다. 원거리에서는 disparity $$d$$가 작아져 같은 pixel 오차가 훨씬 큰 depth 오차로 증폭됩니다.

</details>

<details markdown="block">
<summary markdown="span">3. IoU는 학습, 후처리, 평가에서 어떻게 다르게 쓰입니까?</summary>

답변: 학습에서는 anchor–GT label assignment, 후처리에서는 prediction–prediction NMS, 평가에서는 prediction–GT TP/FP matching에 사용합니다. Threshold와 비교 대상이 서로 다를 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">4. AP가 한 score threshold의 precision과 다른 이유는 무엇입니까?</summary>

답변: AP는 prediction을 confidence 순으로 누적해 만든 전체 precision–recall curve의 면적입니다. 한 threshold의 precision·recall은 그 curve의 operating point 하나입니다.

</details>

<details markdown="block">
<summary markdown="span">5. Faster R-CNN을 two-stage라 부르는 정확한 이유는 무엇입니까?</summary>

답변: RPN이 object proposal을 만들고 RoI head가 각 proposal을 다시 classification·box refinement하기 때문입니다. Backbone CNN을 반드시 두 번 계산한다는 뜻은 아닙니다.

</details>

<details markdown="block">
<summary markdown="span">6. RetinaNet에서 regression loss를 negative anchor에 적용하지 않는 이유는 무엇입니까?</summary>

답변: Negative anchor에는 대응하는 GT box가 없어 회귀 target을 정의할 수 없습니다. Classification loss는 유효 positive·negative에, box regression은 positive에만 적용합니다.

</details>

<details markdown="block">
<summary markdown="span">7. FPN이 작은 물체에 도움이 되는 구조적 이유는 무엇입니까?</summary>

답변: 낮은 backbone level의 높은 spatial resolution에 높은 level의 semantics를 top-down·lateral connection으로 결합합니다. 작은 물체가 사라지기 전의 위치 정보를 비교적 강한 의미 표현과 함께 쓸 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">8. PointNet의 permutation invariance와 VFE의 순서 불변성을 어디까지 말할 수 있습니까?</summary>

답변: 같은 selected point set에 shared point function과 symmetric max를 적용하면 point 순서가 결과를 바꾸지 않습니다. Random sampling으로 set이 달라지거나 좌표 변환으로 voxel membership이 달라지는 경우, rotation·translation까지 자동으로 invariant한 것은 아닙니다.

</details>

<details markdown="block">
<summary markdown="span">9. Lab 2에서 3D convolution 뒤 BEV로 바꾸는 것이 height 정보를 즉시 버리는 것과 다른 이유는 무엇입니까?</summary>

답변: 먼저 3D convolution이 height·ground-plane 이웃을 함께 처리합니다. 그 결과의 남은 height bins를 channel에 합쳐 2D RPN 입력으로 만듭니다. Raw height axis는 사라지지만 학습된 height context가 channel feature에 들어 있습니다.

</details>

<details markdown="block">
<summary markdown="span">10. 합성 validation AP와 실제 KITTI 적용 결과는 무엇을 각각 보여 줍니까?</summary>

답변: 합성 validation AP는 같은 simulator 분포의 별도 장면에서 center-distance 규칙으로 평가한 성능입니다. 실제 KITTI sample에 그린 box는 분포가 달라질 때의 동작을 관찰하는 정성 결과입니다. KITTI 공식 rotated 3D IoU AP는 별도 데이터와 평가 절차가 필요합니다.

</details>

<details markdown="block">
<summary markdown="span">11. Mono3D의 class semantic과 instance semantic은 무엇이 다릅니까?</summary>

답변: Class semantic은 각 pixel의 종류를 구분하고, instance semantic은 같은 종류 안에서도 개체를 나눕니다. 차량 두 대가 붙어 있을 때 class 정보만으로는 모두 car지만, instance 정보는 한 후보가 어느 차량 영역에 대응하는지 구분하는 단서가 됩니다. 둘은 다른 image feature들과 함께 3D 후보의 점수를 매기는 데 쓰입니다.

</details>

<details markdown="block">
<summary markdown="span">12. Camera–LiDAR fusion에서 feature concatenation 전에 필요한 조건은 무엇입니까?</summary>

답변: Intrinsic·extrinsic calibration으로 공간 좌표를 맞추고, timestamp·ego motion으로 시간을 맞추며, 같은 proposal 또는 object region을 각 view에서 대응시켜야 합니다.

</details>

<details markdown="block">
<summary markdown="span">13. Fast R-CNN, Faster R-CNN, FPN은 같은 병목을 해결합니까?</summary>

Fast R-CNN은 proposal마다 CNN을 다시 계산하는 비용을 줄입니다. Faster R-CNN은 여전히 외부에 남아 있던 proposal 생성을 shared feature 위의 RPN으로 옮깁니다. FPN은 proposal 생성 방식 자체보다 feature scale의 문제를 다룹니다. 높은 해상도의 위치 정보와 깊은 층의 의미 정보를 결합하므로 Faster R-CNN과 RetinaNet 모두에 사용할 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">14. PointRCNN, VoxelNet, PIXOR는 무엇을 다르게 선택합니까?</summary>

PointRCNN은 point별 feature와 foreground segmentation으로 3D proposal을 만든 뒤 보정합니다. VoxelNet은 voxel 안의 point feature를 학습하고 규칙적인 3D grid에서 이웃 정보를 결합합니다. PIXOR는 높이 정보를 channel로 담은 BEV 표현에서 oriented box를 직접 예측합니다. 차이는 단순히 더 최신인 모델이 아니라, 불규칙한 점군을 어느 공간에서 계산할지에 있습니다.

</details>

<details markdown="block">
<summary markdown="span">15. Frustum PointNets와 MV3D는 후보가 누락될 때 어떤 차이가 있습니까?</summary>

Frustum PointNets는 2D image detection에서 frustum을 만들므로 image에서 놓친 물체는 이후 point 처리로 넘어가기 어렵습니다. MV3D는 LiDAR BEV에서 만든 proposal을 여러 view에 투영하므로 BEV proposal이 누락되면 해당 물체의 image feature를 결합할 기회도 줄어듭니다. Fusion이 모든 누락을 자동으로 복구하는 것은 아닙니다. 후보 단계의 recall을 확보하고 센서 간 정렬을 검증해야 합니다.

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

Notebook의 그림·tensor shape·학습 수치는 저장된 출력과 코드에 근거하며, 이 총정리를 위해 새로 실행한 결과가 아닙니다. AP 손계산과 작은 수치 예시는 본문 조건으로 별도 계산한 것입니다.
