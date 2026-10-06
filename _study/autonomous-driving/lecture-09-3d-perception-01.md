---
layout: default
date: 2026-10-06 11:40:00 +0900
title: "Lecture 9: Image-Based 3D Object Detection"
course: "Autonomous Driving"
topic: "3D Boxes, Camera Geometry, Mono3D, MonoRCNN, and Pseudo-LiDAR"
order: 9
major_topic: "Autonomous Systems"
keywords:
  - "3D Object Detection"
  - "Pinhole Camera Model"
  - "Monocular Depth"
  - "Mono3D"
  - "MonoRCNN"
  - "Pseudo-LiDAR"
---

# Lecture 9: Image-Based 3D Object Detection

Source PDF: [9 3D Perception (1).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf" | relative_url }})

국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 9강은 2D 검출에서 3D 검출로 넘어가며, 한 장의 영상이 잃어버린 깊이를 어떤 가정과 기하로 보완하는지 설명한다. 강의의 세 사례는 서로 다른 전략을 보여 준다. **Mono3D**는 도로 장면의 ground plane과 전형적인 물체 크기를 proposal prior로 사용하고, **MonoRCNN**은 물리적 높이와 영상 높이로 거리를 분해하며, **Pseudo-LiDAR**는 픽셀별 깊이를 3D point cloud로 역투영한다. 아래 투영식과 수치 검산은 이 세 방법에 공통인 기하 원리를 연결하는 보충 해설이다.

> **핵심:** 2D pixel 하나는 3D 점 하나가 아니라 카메라 중심에서 뻗는 **ray 전체**에 대응한다. 따라서 단안 영상만으로는 물체의 크기와 거리를 동시에 유일하게 정할 수 없다. 3D 검출기는 camera calibration, ground plane, class별 크기, 학습된 depth 같은 추가 정보를 이용해 이 모호성을 줄이며, 결과는 3D IoU와 precision–recall 기반 AP로 평가한다.

## 전체 흐름

| 순서 | 슬라이드 | 핵심 질문 |
|---|---:|---|
| 1 | 5, 7–11 | 3D detection은 2D detection보다 무엇을 더 예측하고 어떻게 평가하는가? |
| 2 | 13–18 | Pinhole projection에서 intrinsic·extrinsic·depth는 어떤 역할을 하는가? |
| 3 | 20–26 | Mono3D는 자율주행 장면의 prior로 3D proposal을 어떻게 줄이는가? |
| 4 | 27–32 | MonoRCNN은 거리 $$Z$$를 물리 높이와 영상 높이로 왜 분해하는가? |
| 5 | 33–36 | Pseudo-LiDAR는 depth map을 어떤 식으로 3D point cloud로 바꾸는가? |
| 6 | 37–40 | 이번 강의의 범위와 다음 LiDAR 기반 강의의 경계는 어디인가? |

## 1. 2D box에서 3D oriented box로

슬라이드 9–10쪽의 목표는 물체마다 **category label과 3D bounding box**를 예측하는 것이다. 2D box $$(x,y,w,h)$$는 영상 평면의 위치와 크기만 나타낸다. 반면 3D box는 보통 중심 $$(X,Y,Z)$$, 물리적 크기 $$(W,H,L)$$, 방향을 함께 가진다. 슬라이드 10쪽은 roll·pitch·yaw까지 포함한 일반 box를 그린 뒤, 도로 위 물체에서는 roll과 pitch를 0으로 두고 yaw만 예측하는 단순화를 소개한다.

이 글에서는 좌표와 각도를 혼동하지 않도록 yaw를 $$\psi$$로 써서 다음처럼 나타낸다.

$$
B=(X,Y,Z,W,H,L,\psi)
$$

$$X,Y,Z,W,H,L$$의 단위는 meter, $$\psi$$의 단위는 radian 또는 degree다. 좌표축의 방향과 box 원점은 데이터셋·구현마다 다르므로, 숫자만 보고 앞·오른쪽·위 방향을 단정하면 안 된다. 또한 yaw-only 가정은 평탄한 도로의 자동차에는 유용하지만, 경사로·전복 차량·드론처럼 roll이나 pitch가 중요한 장면에는 부족하다.

슬라이드 11쪽은 입력을 세 범주로 나눈다.

| 입력 modality | 직접 관측하는 정보 | 대표적인 장점과 한계 |
|---|---|---|
| Image only | RGB intensity와 texture | 의미 정보가 풍부하지만 한 시점만으로 metric depth가 모호하다. |
| LiDAR only | 3D sample point와 반사 강도 등 | metric geometry를 직접 얻지만 point가 희소하고 거리·반사 특성에 따라 밀도가 달라진다. |
| Image + LiDAR | 두 입력의 정렬된 정보 | 의미와 기하를 함께 쓸 수 있지만 calibration·시간 동기화·fusion 설계가 필요하다. |

### 1.1 3D IoU: 겹친 부피의 비율

슬라이드 9쪽의 3D Intersection over Union(IoU)은 예측 box $$B_p$$와 정답 box $$B_g$$의 겹친 **부피**를 합집합 부피로 나눈 정의다.

$$
\operatorname{IoU}_{3D}(B_p,B_g)
=\frac{\operatorname{Vol}(B_p\cap B_g)}
{\operatorname{Vol}(B_p)+\operatorname{Vol}(B_g)-\operatorname{Vol}(B_p\cap B_g)}
$$

부피의 단위는 $$\mathrm{m}^3$$이지만 분자·분모에서 상쇄되므로 IoU는 무차원이며 $$0\leq\operatorname{IoU}_{3D}\leq1$$이다. 같은 크기의 두 axis-aligned box가 각각 $$8\,\mathrm{m}^3$$이고 겹친 부피가 $$4\,\mathrm{m}^3$$이면

$$
\operatorname{IoU}_{3D}=\frac{4}{8+8-4}=\frac{1}{3}\approx0.333
$$

이다. Yaw가 있는 box는 각 변의 겹침 길이만 곱할 수 없다. 일반적으로 bird's-eye view에서 두 회전 사각형의 교차 polygon 넓이를 구하고, 수직 방향의 겹친 높이를 곱해 교차 부피를 계산한다. Box가 영상에서는 잘 겹쳐 보여도 깊이 방향으로 어긋나면 3D IoU는 작아질 수 있다.

### 1.2 Average Precision: confidence 순서까지 평가하기

IoU는 box 한 쌍의 위치 정확도를 재지만, detector는 여러 box와 confidence를 출력한다. 평가에서는 confidence가 높은 순서대로 예측을 정렬하고, 정해진 class·IoU 기준을 만족하면서 아직 매칭되지 않은 정답을 찾으면 true positive(TP), 그렇지 않으면 false positive(FP)로 센다.

$$
\operatorname{Precision}=\frac{TP}{TP+FP},\qquad
\operatorname{Recall}=\frac{TP}{N_{gt}}
$$

$$N_{gt}$$는 해당 class의 정답 물체 수이며 세 값 모두 개수 또는 무차원 비율이다. Average Precision(AP)은 confidence threshold를 바꾸며 얻은 precision–recall curve를 요약한다. **정확한 보간 방식, recall sample 수, IoU threshold는 benchmark 규약에 따라 달라지므로** 슬라이드의 `AP`만 보고 특정 구현을 가정하지 않는다. 예를 들어 정답이 3개이고 상위 네 예측의 판정이 TP, FP, TP, TP라면 누적 $$(TP,FP)$$는 $$(1,0),(1,1),(2,1),(3,1)$$이 되고, 각 지점의 precision과 recall을 계산해 curve를 만든다.

## 2. 2D image와 3D world를 잇는 pinhole camera model

13–16쪽의 viewing frustum 그림은 projection의 핵심을 단계적으로 보여 준다. 3D 점은 image plane의 한 pixel로 투영되지만, 그 pixel에서 3D로 돌아갈 때는 카메라 중심을 지나는 **ray**만 알 수 있다. 2D box의 네 모서리를 ray로 뒤로 뻗으면 잘린 사각뿔 모양의 frustum이 되고, 물체는 그 내부 여러 깊이에 놓일 수 있다.

### 2.1 Extrinsic: world 좌표를 camera 좌표로

**작성자 보충 — 좌표 변환:** World 좌표의 점 $$P_w=(X_w,Y_w,Z_w)$$를 camera 좌표 $$P_c=(X_c,Y_c,Z_c)$$로 옮길 때 회전 $$R\in\mathbb{R}^{3\times3}$$과 이동 $$t\in\mathbb{R}^{3}$$를 쓴다.

$$
\begin{bmatrix}X_c\\Y_c\\Z_c\end{bmatrix}
=R\begin{bmatrix}X_w\\Y_w\\Z_w\end{bmatrix}+t
$$

$$R$$은 두 좌표계의 축 방향을 바꾸는 무차원 rotation matrix이고, $$t$$는 world 원점을 camera frame에서 본 위치로 길이 단위를 가진다. 이 $$R,t$$가 **extrinsic parameters**다. 식의 방향은 world-to-camera로 정의했으며, 반대 방향 변환에는 역변환이 필요하다.

### 2.2 Intrinsic: camera 좌표를 pixel로

왜 intrinsic matrix가 필요한가? 같은 ray 방향이라도 초점거리와 image sensor의 pixel scale이 다르면 영상상의 위치가 달라지기 때문이다. Lens distortion을 보정한 pinhole model에서

$$
K=
\begin{bmatrix}
f_x&0&c_x\\
0&f_y&c_y\\
0&0&1
\end{bmatrix}
$$

이다. $$f_x,f_y$$는 pixel 단위 초점거리, $$(c_x,c_y)$$는 pixel 단위 principal point다. World 점의 전체 projection은 homogeneous coordinate로 다음처럼 쓴다.

먼저 camera 중심, 3D 점, image plane의 투영점이 만드는 similar triangles를 보면 normalized image plane의 좌표는

$$
x'=\frac{X_c}{Z_c},\qquad y'=\frac{Y_c}{Z_c}
$$

가 된다. 이 단계에서 $$X_c,Y_c,Z_c$$는 같은 길이 단위를 쓰므로 $$x',y'$$는 무차원이다. Intrinsic matrix는 이 normalized 좌표를 pixel scale로 확대하고 principal point만큼 이동한다.

$$
s\begin{bmatrix}u\\v\\1\end{bmatrix}
=K\begin{bmatrix}R&t\end{bmatrix}
\begin{bmatrix}X_w\\Y_w\\Z_w\\1\end{bmatrix}
$$

위와 같이 $$K$$의 마지막 행을 $$(0,0,1)$$로 둔 normalization에서는 homogeneous scale $$s=Z_c$$다. $$s$$는 좌표를 정규화하기 위한 scale이며 별도의 camera parameter가 아니다. Algebra상 나눗셈에는 $$Z_c\neq0$$이면 충분하지만, 카메라 앞쪽의 실제 가시점을 다루는 통상적인 좌표계에서는 $$Z_c>0$$을 요구한다. 이때 실제 pixel 좌표는

$$
u=f_x\frac{X_c}{Z_c}+c_x,\qquad
v=f_y\frac{Y_c}{Z_c}+c_y
$$

다. $$u,v,c_x,c_y,f_x,f_y$$는 pixel, 비율 $$X_c/Z_c$$와 $$Y_c/Z_c$$는 무차원이다. OpenCV의 공식 camera calibration 문서도 이 intrinsic·extrinsic 분리를 사용한다. 실제 카메라에서는 radial·tangential distortion을 별도로 보정해야 하므로 이 단순식은 **distortion-free model**이라는 가정이 필요하다.

### 2.3 왜 단안 영상에는 scale–distance ambiguity가 생기는가

17–18쪽의 토끼 그림은 크기가 큰 먼 물체와 크기가 작은 가까운 물체가 같은 영상 크기를 만들 수 있음을 보여 준다. 위 식에서 camera 좌표를 양수 $$\lambda$$배 해도

$$
u'=f_x\frac{\lambda X_c}{\lambda Z_c}+c_x=u,\qquad
v'=f_y\frac{\lambda Y_c}{\lambda Z_c}+c_y=v
$$

이므로 projection은 같다. 즉 pixel만으로는 ray 위의 scale $$\lambda$$를 정할 수 없다. 이것이 슬라이드의 “한 2D point는 3D ray에 대응한다”는 문장의 수학적 의미다.

2D box도 마찬가지로 frustum만 정한다. 물체의 깊이를 정하려면 stereo disparity, LiDAR, 알려진 ground plane, 전형적인 class 크기, 여러 frame의 motion, 또는 학습된 monocular depth prior 같은 추가 정보가 필요하다.

## 3. Mono3D: 도로 장면의 prior로 3D proposal 줄이기

19쪽은 세 가지 image-based 방법을 소개하고, 20–26쪽은 CVPR 2016의 Mono3D 흐름을 설명한다. 단안 projection만 보면 물체는 frustum 어디에나 있을 수 있지만, 자율주행 장면의 자동차·보행자·자전거는 대체로 **ground plane 부근에 있고 class별 물리 크기 분포가 제한적**이라는 prior를 쓸 수 있다.

Mono3D의 proposal pipeline은 다음 다섯 단계다.

1. **3D candidate sampling(22쪽):** ground plane 부근의 위치, class별 size template, 제한된 방향 후보를 조합해 3D box proposal을 만든다. 이 가정은 탐색 공간을 크게 줄이지만 경사, 연석, 비정상적 크기나 공중 물체에서는 틀릴 수 있다.
2. **2D projection(23쪽):** 각 3D proposal의 모서리를 calibration으로 image plane에 투영해 2D candidate box를 얻는다. Projection은 후보를 생성하는 것이 아니라 3D 후보가 현재 영상과 얼마나 맞는지 비교할 수 있게 한다.
3. **Feature scoring(24쪽):** class-level semantic segmentation, instance-level segmentation, shape, context, location prior를 조합해 proposal score를 계산한다. 원 논문은 이 feature들의 가중치를 structured SVM으로 학습한다.
4. **Non-maximum suppression(25쪽):** 높은 점수의 후보부터 선택하고 심하게 겹치는 중복 proposal을 제거한다. NMS가 비교하는 overlap 공간과 threshold는 구현 규약을 확인해야 하며, “NMS가 정확한 깊이를 계산한다”는 뜻은 아니다.
5. **Second-stage detection(26쪽):** 남은 proposal의 box region과 주변 context region에서 CNN feature를 뽑아 class, 2D box, orientation을 정제한다.

Mono3D의 중요한 아이디어는 **단안 깊이 문제를 없애는 것**이 아니라, 도로 장면에서 가능한 3D 상태에 높은 prior를 주고 영상 evidence로 후보를 순위화하는 것이다. Ground plane이 잘못 추정되거나 class size가 분포 밖이면 proposal 단계에서 정답을 놓칠 수 있으며, 이후 classifier가 없는 후보를 복구할 수는 없다. 이 흐름은 <a href="https://openaccess.thecvf.com/content_cvpr_2016/html/Chen_Monocular_3D_Object_CVPR_2016_paper.html" target="_blank" rel="noopener">Mono3D 원 논문</a>의 proposal 생성·scoring 설명과 일치한다.

## 4. MonoRCNN: 거리를 해석 가능한 성분으로 분해하기

27쪽은 정확한 depth $$Z$$를 하나의 값으로 바로 회귀하기 어렵다는 문제에서 출발한다. 같은 물체 class라면 실제 높이 $$H$$가 어느 정도 제한되고, 3D box 중심의 수직선이 영상에 투영된 길이 $$h$$는 거리가 멀수록 작아진다. MonoRCNN은 이 선을 **projected central line(PCL)**이라고 부르고, depth를 PCL 길이·물리 높이·camera focal length로 분해한다.

### 4.1 Similar triangles에서 얻는 거리 식

**작성자 보충 — 단순화한 유도:** Roll과 pitch를 0으로 두고 distortion이 보정되었다고 하자. 3D box 중심을 지나는 수직선의 물리 길이가 $$H$$ meter, 그 선의 투영 길이인 PCL이 $$h$$ pixel, 세로 초점거리가 $$f_y$$ pixel이면 similar triangles에서

$$
\frac{h}{f_y}=\frac{H}{Z}
$$

이고, 따라서

$$
Z=\frac{f_yH}{h}=f_yHh_{\mathrm{rec}},\qquad h_{\mathrm{rec}}=\frac{1}{h}
$$

이다. $$Z,H$$는 meter, $$f_y,h$$는 pixel, $$h_{\mathrm{rec}}$$은 $$\mathrm{pixel}^{-1}$$이므로 결과 단위는 meter다. 예를 들어 $$f_y=800\,\mathrm{pixel}$$, $$H=1.5\,\mathrm{m}$$, $$h=120\,\mathrm{pixel}$$이면

$$
Z=\frac{800\times1.5}{120}=10\,\mathrm{m}
$$

이다. 같은 물체가 영상에서 60 pixel 높이로 보이면 다른 조건이 같을 때 depth는 20 m가 된다.

여기서 $$h$$는 관측된 2D 검출 box의 세로 길이가 아니다. MonoRCNN의 distance head가 물리 높이 $$H$$와 PCL의 역수 $$h_{\mathrm{rec}}=1/h$$를 **각각 직접 회귀**하며, 두 값의 uncertainty도 함께 출력한다. 따라서 keypoint나 orientation으로 visual height를 기하적으로 재구성한 뒤 거리를 구하는 방식과 다르다. Roll·pitch가 무시되지 않거나 camera model과 annotation convention이 달라지면 이 단순한 수직선 모델의 가정도 다시 확인해야 한다.

### 4.2 세 개 head와 최종 box 복원

28–31쪽의 그림은 Faster R-CNN backbone·RoIAlign 위에 다음 head를 붙인다.

| Head | 출력 | 의미 |
|---|---|---|
| 2D head | class, score, 2D box $$b$$ | 영상에서 물체를 찾는 기본 검출 결과 |
| 3D attribute head | size $$m=(W,H,L)$$, allocentric pose $$a=(\sin\theta,\cos\theta)$$, projected center와 여덟 projected corners | 3D box의 크기·방향·2D keypoint. 여덟 corner는 학습 보조 loss에만 쓰고 inference에는 center만 사용 |
| 3D distance head | $$H,\sigma_H,h_{\mathrm{rec}},\sigma_{h_{\mathrm{rec}}}$$ | 거리 분해 성분과 각 성분의 uncertainty |

Distance head에서 $$Z=f_yHh_{\mathrm{rec}}$$를 계산한 뒤, projected 3D center $$p$$를 역투영하면 camera-frame 중심을 얻을 수 있다.

$$
X=\frac{(p_1-c_x)Z}{f_x},\qquad
Y=\frac{(p_2-c_y)Z}{f_y}
$$

여기에 $$m$$과 방향을 결합하면 3D box를 복원한다. 단, 논문의 $$\theta$$는 camera axis에 대한 보통의 yaw가 아니라 **viewing ray를 기준으로 본 allocentric pose**다. Camera-frame yaw를 얻으려면 $$\theta$$와 object center ray의 방위각 $$\operatorname{atan2}(X,Z)$$를 결합해야 하며, 더하는지 빼는지와 축의 양의 방향은 KITTI 같은 dataset의 좌표·각도 convention에 따라 달라진다. 따라서 $$\theta$$를 그대로 camera yaw로 읽으면 안 된다.

31쪽의 파란 화살표는 network prediction, 주황 화살표는 inference 때 geometry로 box를 복원하는 경로를 나타낸다. Attribute head는 projected center와 여덟 projected corners를 모두 예측하지만, corner regression은 학습을 돕는 auxiliary loss이고 inference에서 위치 복원에 쓰는 keypoint는 center뿐이다. <a href="https://arxiv.org/html/2104.03775" target="_blank" rel="noopener">MonoRCNN 원 논문</a>은 distance head가 $$H$$와 $$h_{\mathrm{rec}}$$를 직접 회귀하고 이들로 $$Z$$를 복원한다고 명시한다.

### 4.3 Uncertainty-aware regression과 재순위화

예측값을 $$q$$, 정답을 $$q^*$$라고 쓰면 $$q\in\{H,h_{\mathrm{rec}}\}$$에 대해 논문은 L1 오차를 uncertainty로 나누고 log penalty를 더한다. $$q$$와 $$\sigma_q$$는 각 target의 단위가 같아야 한다. 높이는 m, 역 PCL은 $$\mathrm{pixel}^{-1}$$이므로, 단위가 있는 값에 log를 직접 취하지 않도록 같은 단위의 고정 reference scale $$\sigma_{q,0}>0$$를 명시하면 다음처럼 쓸 수 있다.

$$
L_q=\frac{L_1(q^*,q)}{\sigma_q}
+\lambda_q\log\frac{\sigma_q}{\sigma_{q,0}}
$$

이때 $$\sigma_q>0$$, $$\lambda_q>0$$다.

L1 오차는 $$\lvert q^*-q\rvert$$이므로 첫 항과 log 내부는 모두 무차원이다. Reference scale을 넣는 것은 논문의 $$\log\sigma_q$$ 표기에 고정 상수 $$-\lambda_q\log\sigma_{q,0}$$를 더하는 단위 명시일 뿐, 학습 변수에 대한 gradient를 바꾸지 않는다.

첫 항은 예측 uncertainty $$\sigma_q$$가 큰 sample의 회귀 오차 가중치를 낮춘다. 그러나 $$\sigma_q$$만 끝없이 키우면 두 번째 log 항이 증가한다. 고정된 양의 오차 $$e=\lvert q^*-q\rvert>0$$에서 이를 미분하면 균형점을 직접 확인할 수 있다.

$$
\frac{\partial L_q}{\partial\sigma_q}
=-\frac{e}{\sigma_q^2}+\frac{\lambda_q}{\sigma_q}=0
\quad\Longrightarrow\quad \sigma_q=\frac{e}{\lambda_q}
$$

즉 이 조건에서 큰 오차에는 더 큰 uncertainty가 대응하지만, uncertainty를 무한히 키우는 것이 최적은 아니다. 이는 paper가 학습한 uncertainty를 이용하는 방식이지, 모든 dataset에서 확률적으로 calibration된 신뢰구간이라는 뜻은 아니다.

$$H$$를 고정해 $$Z=f_yHh_{\mathrm{rec}}$$를 미분하면 $$\partial Z/\partial h_{\mathrm{rec}}=f_yH$$다. 따라서 역 PCL 오차의 scale은 거리 공간에서 $$f_yH\sigma_{h_{\mathrm{rec}}}$$ m로 변환된다. 이는 $$H$$ 자체의 uncertainty와 두 성분의 상관관계까지 모두 합성한 일반적인 오차 전파식은 아니다. Paper는 이 양을 이용해 3D box 순위를 raw detection score 대신

$$
s_{\mathrm{rank}}=\frac{\mathrm{score}}{f_yH\sigma_{h_{\mathrm{rec}}}}
$$

로 정한다. 이는 해당 방법의 **ranking heuristic**이며, $$s_{\mathrm{rank}}$$ 자체를 calibrated probability로 해석해서는 안 된다.

32쪽은 정적 PDF에서 검은 직사각형으로만 남은 embedded-media 영역이다. 따라서 해당 페이지가 의도한 qualitative video의 장면·성능은 이 글에서 추정하지 않는다.

## 5. Pseudo-LiDAR: depth map을 3D representation으로 바꾸기

33–35쪽의 pipeline은 `stereo/mono image → depth estimation → depth map → pseudo-LiDAR → LiDAR-based detector → 3D boxes`다. Depth estimation은 각 pixel에 연속적인 depth를 예측하는 pixel-wise regression task이며, 출력 해상도를 복원한다는 점에서 semantic segmentation과 encoder–decoder 구조가 비슷할 수 있다. 그러나 segmentation은 discrete class를, depth estimation은 길이 값을 예측하므로 출력 의미와 loss가 같지는 않다.

### 5.1 Stereo에서는 disparity가 metric depth를 준다

**작성자 보충 — rectified stereo:** 좌우 camera의 optical axis가 평행하도록 rectification했고, 두 camera의 $$f_x$$와 $$c_x$$가 같으며, 오른쪽 camera 중심이 왼쪽에서 $$b$$ meter만큼 가로로 이동했다고 하자. 왼쪽 camera frame의 점 $$(X,Y,Z)$$는 두 영상에서

$$
u_L=f_x\frac{X}{Z}+c_x,\qquad
u_R=f_x\frac{X-b}{Z}+c_x
$$

로 투영된다. 같은 점의 disparity를 $$d=u_L-u_R$$로 정의해 두 식을 빼면

$$
d=f_x\frac{b}{Z}
$$

이고 이를 $$Z$$에 대해 풀면

$$
Z(u,v)=\frac{f_xb}{d(u,v)}
$$

이다. $$f_x$$와 $$d$$가 pixel이므로 상쇄되고 $$Z$$의 단위는 meter다. 예를 들어 $$f_x=700\,\mathrm{pixel}$$, $$b=0.54\,\mathrm{m}$$, $$d=54\,\mathrm{pixel}$$이면 $$Z=7\,\mathrm{m}$$다.

Disparity 오차에 대한 depth의 국소 민감도는

$$
\left\lvert\frac{\mathrm{d}Z}{\mathrm{d}d}\right\rvert
=\frac{f_xb}{d^2}
$$

이다. 같은 1 pixel disparity 오차라도 $$d$$가 작아지는 먼 거리에서 depth 오차가 제곱 역비례로 커진다. 위 수치에서 민감도는 약 $$0.13\,\mathrm{m/pixel}$$이지만 $$d=9\,\mathrm{pixel}$$이면 약 $$4.67\,\mathrm{m/pixel}$$이다. 이는 1차 미분으로 본 국소 근사이며, $$d=0$$에는 원래 depth 식도 사용할 수 없다.

Monocular depth network는 stereo baseline 없이 한 장의 appearance와 학습 prior로 depth를 추정한다. Metric scale을 어떻게 확보하는지는 supervision과 모델 설정에 달려 있으므로, 모든 monocular depth map이 자동으로 절대 meter 단위를 갖는다고 가정하면 안 된다.

### 5.2 Pixel을 camera-frame point로 역투영하기

34쪽의 “각 pixel depth 정보를 3D 공간으로 보냄”은 pinhole projection을 역으로 푸는 과정이다. Depth map $$D(u,v)$$가 camera optical axis 방향 depth $$Z$$를 meter로 제공한다고 하면

$$
Z=D(u,v),\qquad
X=\frac{(u-c_x)Z}{f_x},\qquad
Y=\frac{(v-c_y)Z}{f_y}
$$

이다. 앞 예제에 $$u-c_x=70\,\mathrm{pixel}$$, $$v-c_y=35\,\mathrm{pixel}$$, $$f_x=f_y=700\,\mathrm{pixel}$$을 더하면 point는

$$
(X,Y,Z)=(0.7,0.35,7)\,\mathrm{m}
$$

다. 모든 유효 pixel에 이 계산을 적용하면 camera-frame 3D point cloud가 된다. LiDAR detector가 다른 sensor frame을 기대하면 extrinsic transform으로 좌표를 바꿔야 한다. Lens distortion이 남은 pixel, 잘못된 intrinsic, depth convention의 차이(range와 optical-axis depth)를 무시하면 point cloud가 체계적으로 휜다.

이 point cloud를 “pseudo” LiDAR라고 부르는 이유는 **좌표 표현이 LiDAR point cloud와 비슷할 뿐 측정 원리가 같지 않기 때문**이다. 영상 depth의 모든 오류가 그대로 3D 좌표 오류가 되고, 실제 LiDAR reflectance와 sampling pattern도 자연히 생기지 않는다. 그럼에도 물체의 물리 크기가 depth에 따라 image plane에서 축소되는 표현보다, 3D 좌표에서 직접 다루는 편이 기존 point-cloud detector와 잘 맞는다는 것이 핵심이다. 이는 <a href="https://openaccess.thecvf.com/content_CVPR_2019/html/Wang_Pseudo-LiDAR_From_Visual_Depth_Estimation_Bridging_the_Gap_in_3D_CVPR_2019_paper.html" target="_blank" rel="noopener">Pseudo-LiDAR 원 논문</a>의 표현 관점이다.

35–36쪽은 생성된 point cloud에 LiDAR-based detector를 적용한다고만 소개하고, 구체적인 point·voxel embedding과 detector 종류는 다음 강의로 넘긴다. 따라서 이 글도 해당 알고리즘의 구조나 성능 수치를 임의로 채우지 않는다.

## Source Check

| 위치 | 판정 | 확인과 이 글의 처리 |
|---|---|---|
| 9쪽 `3D IoU & AP` | 평가 규약 생략 | 정의는 설명하되 IoU threshold와 AP interpolation은 benchmark마다 다르다고 명시했다. |
| 10쪽 box tuple의 마지막 `y` | 기호 충돌 가능 | 공간 좌표 $$Y$$와 yaw를 구분하기 위해 yaw를 $$\psi$$로 표기했다. |
| 13–18쪽 simplified camera model | 가정이 생략된 단순화 | Distortion-free pinhole, calibration, 좌표 변환 방향을 명시하고 intrinsic·extrinsic 식을 보충했다. |
| 17쪽 scale–distance ambiguity | 정확한 projective 성질 | 3D 좌표의 공통 scale이 pixel projection에서 상쇄됨을 식으로 확인했다. |
| 21–26쪽 ground plane·typical size | 장면 prior | 평탄한 도로와 학습 분포에서 유용하지만 경사·비정상 크기·공중 물체에 일반화되지 않는다고 제한했다. |
| 27쪽 $$Z=fH/h$$ 도식 | PCL 기반 거리 분해 | $$h$$를 2D box 높이가 아니라 3D box 중앙 수직선의 투영 길이로 정의하고, distance head가 $$H$$와 $$h_{\mathrm{rec}}$$를 직접 회귀함을 원 논문으로 확인했다. |
| 28–31쪽 keypoint·uncertainty | 역할 구분 필요 | 여덟 projected corners는 train-only auxiliary loss이고 inference에는 center만 사용한다. Uncertainty loss와 $$\mathrm{score}/(f_yH\sigma_{h_{\mathrm{rec}}})$$ 재순위화도 확률 calibration으로 과해석하지 않았다. |
| 29쪽 yaw $$a=(\sin\theta,\cos\theta)$$ | 좌표 convention 주의 | $$\theta$$는 allocentric pose이므로 viewing-ray 방위각과 dataset convention을 반영해 camera-frame yaw로 변환해야 한다고 구분했다. |
| 32쪽 검은 media 영역 | 정적 PDF에서 미확인 | 보이지 않는 qualitative 결과를 추정하거나 성능 주장으로 사용하지 않았다. |
| 33–36쪽 stereo/mono depth | modality 차이 생략 | Stereo disparity의 metric 식과 monocular metric-scale 조건을 분리했다. |
| 34쪽 pseudo-LiDAR 변환 | 식 생략 | 원 논문과 pinhole model의 back-projection 식, 단위, 좌표계 조건을 보충했다. |

## 슬라이드 전체 대응표

| 슬라이드 | 역할 | 이 글의 대응 |
|---:|---|---|
| 1 | 강의 표지 | 제목·강의 metadata |
| 2–3 | 공지·Assignment #1 | 행정 페이지로 확인했으며 학습 본문에서는 제외 |
| 4–5 | 지난 강의 복습 | 2D semantic·instance segmentation에서 3D detection으로 넘어가는 연결 |
| 6–8 | 목차와 3D detection section | 전체 흐름, 1절 |
| 9–10 | 3D box, IoU, AP, pose | 1절과 1.1–1.2절 |
| 11 | Image/LiDAR/multi-modal | 1절 modality 표 |
| 12 | Image-based section 표지 | 2절 진입 |
| 13–16 | Viewing frustum·ray·용어 | 2절과 2.1–2.2절 |
| 17–18 | Scale–distance ambiguity·frustum candidates | 2.3절 |
| 19 | 세 image-based method 목록 | 3–5절의 방법 범위 |
| 20–21 | 단안 모호성과 자율주행 prior | 3절 도입 |
| 22–26 | Mono3D proposal→projection→score→NMS→CNN | 3절의 다섯 단계 |
| 27 | Height-based distance decomposition | 4절과 4.1절 |
| 28–31 | MonoRCNN head와 inference recovery | 4.2–4.3절 |
| 32 | Embedded qualitative media | Source Check의 미확인 항목 |
| 33–35 | Depth map→pseudo-LiDAR→3D detection | 5절과 5.1–5.2절 |
| 36 | 다음 강의의 LiDAR 질문 | 5절의 범위 경계 |
| 37–38 | Summary | 마지막 핵심 정리 |
| 39 | Next lecture | LiDAR detector가 다음 강의 범위임을 명시 |
| 40 | Questions | 강의 종료 페이지로 확인 |

## 복습 포인트

- 3D box의 중심·물리 크기·yaw를 정의하고, yaw-only 가정이 언제 깨지는지 설명한다.
- 3D IoU의 분자·분모를 부피로 쓰고, 단위가 왜 상쇄되는지 계산한다.
- Intrinsic $$K$$와 extrinsic $$R,t$$의 역할을 구분하고 $$u=f_xX/Z+c_x$$를 유도한다.
- 같은 ray 위의 $$(\lambda X,\lambda Y,\lambda Z)$$가 같은 pixel로 투영되는 이유를 보여 준다.
- Mono3D의 다섯 단계에서 ground plane과 typical size가 어디에 쓰이는지 말한다.
- MonoRCNN의 PCL과 2D box 높이를 구분하고, $$H$$·$$h_{\mathrm{rec}}$$ 직접 회귀와 uncertainty-aware loss를 설명한다.
- Rectified stereo의 $$Z=f_xb/d$$와 depth-map back-projection을 작은 숫자로 계산한다.
- 실제 LiDAR와 pseudo-LiDAR가 같은 것은 3D 좌표 표현이지 sensing noise·reflectance·sampling pattern이 아님을 구분한다.

## 마지막 핵심 정리

**3D object detection의 중심 난점은 영상의 2D 위치를 찾는 것보다 ray 위의 depth와 metric size를 정하는 데 있다.** Pinhole model은 3D를 2D로 투영하는 방법을 정확히 주지만, 단안 영상에서 잃은 scale을 저절로 복구하지는 않는다. Mono3D는 ground plane과 class size prior로 후보 공간을 줄이고, MonoRCNN은 depth를 physical height와 PCL의 reciprocal로 분해하며, Pseudo-LiDAR는 예측 depth를 3D point representation으로 바꾼다. 세 방법 모두 추가 가정이나 learned prior의 정확도가 최종 3D box를 제한한다.

## Study Guide

먼저 13–18쪽을 보며 `3D point → pixel`과 `pixel → ray`를 반대 방향으로 구분한다. 그 다음 intrinsic·extrinsic 식을 직접 쓰고, $$\lambda$$ scale이 상쇄되는지 확인한다. 9–10쪽에서는 box parameter와 3D IoU를 계산하고, 20–26쪽의 Mono3D를 `prior → candidate → projection → scoring → NMS → refinement` 순서로 외운다. 마지막으로 27–35쪽에서 같은 pinhole 식이 MonoRCNN의 PCL 기반 거리 분해와 Pseudo-LiDAR의 back-projection에 어떻게 다시 등장하는지 연결한다.

## 복습 질문

<details markdown="block">
<summary>1. 한 pixel이 3D 점 하나가 아니라 ray에 대응하는 이유는 무엇인가?</summary>

답변: Pinhole projection의 $$u=f_xX/Z+c_x$$, $$v=f_yY/Z+c_y$$에서 $$X,Y,Z$$를 같은 양수 $$\lambda$$배 해도 비율이 변하지 않는다. 따라서 camera center에서 같은 방향에 있는 여러 깊이의 점이 동일한 pixel로 투영된다.

</details>

<details markdown="block">
<summary>2. 3D IoU가 높은 box라도 AP가 낮을 수 있는 이유는 무엇인가?</summary>

답변: IoU는 한 예측과 한 정답의 기하학적 겹침만 잰다. AP는 전체 예측을 confidence 순으로 보며 중복 검출, 잘못된 class, 누락, false positive까지 precision–recall curve에 반영한다. 일부 box가 정확해도 많은 오검출이나 누락이 있으면 AP가 낮아질 수 있다.

</details>

<details markdown="block">
<summary>3. Mono3D의 ground-plane prior가 도움이 되면서도 실패 원인이 되는 이유는 무엇인가?</summary>

답변: 도로 장면의 자동차·보행자 후보를 ground plane 부근으로 제한하면 frustum 전체를 탐색할 필요가 없다. 하지만 경사면, 연석, 잘못된 camera pose, 공중 물체처럼 prior가 맞지 않으면 올바른 후보 자체가 생성되지 않을 수 있다.

</details>

<details markdown="block">
<summary markdown="span">4. MonoRCNN의 $$Z=f_yH/h$$에서 $$h$$는 무엇이며, 절반이 되면 depth는 어떻게 되는가?</summary>

답변: $$h$$는 2D detection box 높이가 아니라 3D box 중심의 수직선을 투영한 PCL 길이다. $$f_y$$와 물리 높이 $$H$$가 같다면 $$Z$$는 $$h$$에 반비례하므로 $$h$$가 절반일 때 depth는 두 배다. MonoRCNN은 $$H$$와 $$h_{\mathrm{rec}}=1/h$$를 distance head에서 직접 회귀한다.

</details>

<details markdown="block">
<summary markdown="span">5. Stereo disparity가 0에 가까워질수록 $$Z=f_xb/d$$가 불안정해지는 이유는 무엇인가?</summary>

답변: $$d$$가 분모이므로 작은 disparity 오차가 큰 depth 변화로 확대된다. 먼 물체일수록 disparity가 작아져 pixel quantization이나 correspondence 오류의 영향이 커지며, $$d=0$$에서는 유한한 depth를 계산할 수 없다.

</details>

<details markdown="block">
<summary>6. Pseudo-LiDAR point와 실제 LiDAR point의 가장 중요한 차이는 무엇인가?</summary>

답변: 둘 다 3D 좌표 형태로 detector에 입력될 수 있지만, pseudo-LiDAR 좌표는 영상에서 예측한 depth를 역투영한 값이다. 따라서 depth-network 오차와 camera calibration 오차를 그대로 가지며, 실제 LiDAR의 beam sampling과 reflectance 측정도 자동으로 재현하지 않는다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-09-3d-perception-01.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 9 source slides (PDF)</a></li>
</ul>

## References

- <a href="https://openaccess.thecvf.com/content_cvpr_2016/html/Chen_Monocular_3D_Object_CVPR_2016_paper.html" target="_blank" rel="noopener">Chen et al., Monocular 3D Object Detection for Autonomous Driving</a> — ground-plane prior, 3D proposal generation, image-space scoring과 refinement.
- <a href="https://openaccess.thecvf.com/content/ICCV2021/html/Shi_Geometry-Based_Distance_Decomposition_for_Monocular_3D_Object_Detection_ICCV_2021_paper.html" target="_blank" rel="noopener">Shi et al., Geometry-Based Distance Decomposition for Monocular 3D Object Detection</a> — MonoRCNN의 height decomposition, uncertainty와 3D box recovery.
- <a href="https://openaccess.thecvf.com/content_CVPR_2019/html/Wang_Pseudo-LiDAR_From_Visual_Depth_Estimation_Bridging_the_Gap_in_3D_CVPR_2019_paper.html" target="_blank" rel="noopener">Wang et al., Pseudo-LiDAR From Visual Depth Estimation: Bridging the Gap in 3D Object Detection for Autonomous Driving</a> — stereo·monocular depth의 point-cloud 변환과 LiDAR-based detector 연결.
- <a href="https://docs.opencv.org/doc/doxygen/html/d4/d93/group__calib.html" target="_blank" rel="noopener">OpenCV Camera Calibration documentation</a> — pinhole projection, intrinsic matrix, extrinsic transform와 scale ambiguity.
