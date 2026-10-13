---
layout: default
date: 2026-10-13 17:01:00 +0900
title: "Autonomous Driving Computing Assignment 3: LiDAR 3D Object Detection"
course: "Autonomous Driving"
topic: "VoxelNet and Point Cloud Detection"
order: 3
major_topic: "Autonomous Systems"
keywords:
  - "LiDAR"
  - "VoxelNet"
  - "Point Cloud"
  - "3D Object Detection"
  - "Bird's-Eye View"
---

# Autonomous Driving Computing Assignment 3: LiDAR 3D Object Detection

Source Materials: [LiDAR 3D object detection lab notebook (outputs cleared)]({{ "/assets/notebooks/study/autonomous-driving/assignment-03-lidar-3d-object-detection.ipynb" | relative_url }}){:target="_blank" rel="noopener"}

## 과제 개요

이 과제는 LiDAR point cloud를 3D detector가 처리할 수 있는 tensor로 바꾸는 과정을 VoxelNet 중심으로 추적한다. 실제 KITTI sample로 좌표와 희소성을 확인한 뒤, 합성 LiDAR scene에서 voxelization, VFE, 3D convolution, BEV RPN, anchor target, loss, post-processing을 연결한다.

**핵심 메시지:** Point cloud는 일정한 2D grid가 아니라 순서가 없고 점 개수가 변하는 집합이다. VoxelNet은 이 불규칙한 입력을 voxel 단위 feature로 학습하고, 3D convolution으로 높이 방향 문맥을 모은 뒤, BEV 위의 dense detection 문제로 바꾼다.

공개 notebook은 식별 정보와 저장 출력을 제거한 학습용 코드다. 아래 학습 수치·형상·그림은 로컬 원본에 저장된 T4/CUDA 실행 결과를 읽은 것이며, 독립적으로 재실행해 검증한 값은 아니다.

## 전체 흐름

```text
point cloud (N × 4)
→ voxel partition and point grouping
→ per-point 7D input and VFE
→ one learned feature per non-empty voxel
→ sparse-to-dense 3D tensor
→ 3D convolution and height-to-channel reshape
→ 2D BEV RPN
→ class-specific 3D anchors, scores, 7-DoF box offsets
→ score filtering and BEV NMS
```

## 1. Point Cloud를 입력으로 읽기

KITTI LiDAR `.bin` sample은 header 없이 이어진 float32 값이다. 네 값씩 묶으면 한 점의 $$(x,y,z,r)$$가 된다. $$x,y,z$$의 단위는 meter이고 $$r$$은 reflectance다.

저장 출력은 275,808 bytes를 17,238점 × 4 values × 4 bytes로 해석했다. Tensor shape는 `(17238, 4)`다. 행 순서를 섞어도 동일한 점 집합이지만 배열 자체는 달라진다. 따라서 point-based network는 입력 순서에 의존하지 않는 aggregation을 사용해야 한다.

### 같은 point cloud를 보는 네 방식

| Representation | Input shape or axes | Preserved information | Main loss |
| --- | --- | --- | --- |
| Raw 3D points | $$N\times4$$ | Original coordinates and reflectance | Irregular size and sparsity |
| BEV | x-y plane | Object footprint and metric scale | Height detail must be encoded separately |
| Range image | Elevation × azimuth | Sensor scanning order and range | Projection collisions and empty bins |
| Camera projection | Image u-v plus depth | Alignment with RGB scene | Calibration and visibility required |

이 표현들은 서로 다른 데이터가 아니다. 같은 측정을 어떤 grid와 좌표계에서 읽을지 바꾼 것이다.

## 2. 거리와 희소성

LiDAR의 angular resolution이 고정되어 있으면 같은 크기의 물체도 멀리 갈수록 더 작은 각도를 차지한다. 따라서 물체 표면에 닿는 ray 수가 감소한다. 저장된 KITTI sample에서 차량 내부 점 수는 8.2 m에서 1,933개, 21.9 m에서 169개, 34.3 m에서 54개였다.

이 세 값은 한 frame의 사례다. 거리 외에도 가림, 차량 방향, 반사 특성, camera field-of-view로 잘린 sample이라는 조건이 영향을 준다. 따라서 “거리 두 배면 점 수가 정확히 몇 배 감소한다”는 보편식으로 사용하면 안 된다.

## 3. PIXOR, VoxelNet, PointRCNN의 입력 차이

| Method | Representation | What learns the feature? |
| --- | --- | --- |
| PIXOR | Height-sliced BEV occupancy and reflectance | 2D CNN after manually designed encoding |
| VoxelNet | Points grouped in 3D voxels | VFE learns a voxel feature |
| PointRCNN | Raw point set | Point-wise network learns foreground and proposals |

저장된 simplified PIXOR example은 7개 height occupancy slices와 reflectance 1장을 합쳐 `(8, 512, 512)` tensor를 만들었다. 이는 논문 설정을 그대로 복제한 benchmark가 아니라 입력 표현을 확인하기 위한 축소 예제다.

PointRCNN 설명에서 GT box 안의 point를 foreground로 표시한 결과는 5,132 / 17,238점, 약 29.8%였다. 이 값도 해당 sample의 label과 field-of-view에 한정된다.

## 4. Voxelization과 VFE

### 4.1 Voxel partition

Voxel size는 0.2×0.2×0.4 m로 설정돼 있다. 공간 범위 안의 point는 정수 voxel index로 변환된다.

$$
i_x=\left\lfloor\frac{x-x_{min}}{v_x}\right\rfloor,
\quad
i_y=\left\lfloor\frac{y-y_{min}}{v_y}\right\rfloor,
\quad
i_z=\left\lfloor\frac{z-z_{min}}{v_z}\right\rfloor
$$

이 식은 정의다. Point가 범위 밖이면 해당 grid에 들어가지 않으며, 음수 좌표의 floor 처리와 boundary clipping을 일관되게 해야 한다.

저장된 한 scene에서는 범위 안 40,950점이 7,236개의 non-empty voxel로 묶였다. 전체 655,360 voxel 중 1.10%만 비어 있지 않았다. Voxel당 최대 point 수 $$T=32$$를 넘는 103개 voxel은 random sampling으로 줄였다.

### 4.2 Point-wise input and VFE

Voxel 안 point $$p_i$$의 입력은

$$
[x_i,y_i,z_i,r_i,x_i-\bar x,y_i-\bar y,z_i-\bar z]
$$

의 7차원이다. 앞의 네 값은 절대 위치와 reflectance, 뒤의 세 값은 voxel centroid에 대한 상대 위치다. Point가 32개보다 적으면 zero padding을 넣고 mask로 실제 point와 구분한다.

VFE는 각 point에 FCN을 적용한 local feature와 voxel 전체의 channel-wise max feature를 이어 붙인다. Max aggregation은 point 순서가 바뀌어도 같은 결과를 만든다. 다만 max 하나만으로 모든 분포 통계를 보존하는 것은 아니다.

<details markdown="block">
<summary markdown="span">Derivation: Why max aggregation is permutation invariant</summary>

풀이과정:

Voxel의 point feature 집합을 $$\{h_1,\dots,h_T\}$$라고 하자. Channel $$c$$의 aggregated feature는

$$
g_c=\max_i h_{i,c}
$$

다. Point 순서를 permutation $$\pi$$로 바꿔도 집합의 원소는 같으므로

$$
\max_i h_{\pi(i),c}=\max_i h_{i,c}=g_c
$$

가 성립한다. 이는 max 연산의 정확한 성질이다. 그러나 서로 다른 point 집합이 같은 channel-wise maximum을 만들 수 있으므로 aggregation이 injective하다는 뜻은 아니다.

</details>

## 5. Sparse 3D에서 Dense BEV로

저장 출력의 shape 변화는 다음과 같다.

| Stage | Stored shape | Meaning |
| --- | --- | --- |
| Voxel features | 7,236×64 | One learned vector per non-empty voxel |
| Dense tensor | 1×64×10×256×256 | Batch, channel, height, y, x |
| 3D conv output | 1×32×3×256×256 | Height context after z-stride |
| BEV reshape | 1×96×256×256 | 32 channels × 3 height bins |
| RPN head | 65,536 scores and 65,536×7 offsets | Four anchors per BEV location |

Height dimension을 channel로 합친 뒤부터는 2D CNN으로 처리한다. 이 변환은 높이 정보를 버리는 단순 projection이 아니다. 앞선 VFE와 3D convolution으로 높이 문맥을 feature channel에 먼저 반영한 뒤 BEV detector에 넘긴다.

## 6. 3D Anchor와 Regression Target

3D box는 $$(x,y,z,l,w,h,\theta)$$의 7개 값으로 표현한다. Anchor는 class별 대표 크기와 yaw 0°, 90°를 조합한다. Center offset에는 horizontal diagonal $$d_a=\sqrt{l_a^2+w_a^2}$$와 height $$h_a$$를 사용한다.

$$
\Delta x=\frac{x_g-x_a}{d_a},\quad
\Delta y=\frac{y_g-y_a}{d_a},\quad
\Delta z=\frac{z_g-z_a}{h_a}
$$

$$
\Delta l=\log\frac{l_g}{l_a},\quad
\Delta w=\log\frac{w_g}{w_a},\quad
\Delta h=\log\frac{h_g}{h_a},\quad
\Delta\theta=\theta_g-\theta_a
$$

길이 단위는 정규화와 비율에서 약분되므로 target은 무차원이며 angle은 radian이다. Notebook은 yaw를 $$\pi$$ 주기로 정규화해 앞뒤 방향을 동일한 box orientation으로 취급한다.

저장된 scene에서는 65,536 anchors 중 positive 65, negative 65,374, ignore 97이었다. BEV matching은 회전 box의 정확한 polygon IoU가 아니라 가까운 0°/90° 축정렬 box로 근사한다. 따라서 이 실습의 matching과 KITTI 공식 rotated 3D IoU 평가를 동일하게 보면 안 된다.

## 7. Loss와 Class Imbalance

Notebook의 VoxelNet loss는 positive와 negative classification loss를 별도로 평균낸다.

$$
L=
\frac{\alpha}{N_{pos}}\sum_{i\in pos}L_{cls}(p_i,1)
+\frac{\beta}{N_{neg}}\sum_{j\in neg}L_{cls}(p_j,0)
+\frac{1}{N_{pos}}\sum_{i\in pos}L_{reg}(u_i,u_i^*)
$$

여기서 $$\alpha=1.5$$, $$\beta=1$$이고 regression은 smooth L1을 사용한다. Negative 수가 훨씬 많아도 별도 평균을 내므로 단순 개수만으로 negative가 loss 전체를 압도하지 않는다. 이는 RetinaNet의 focal loss와 목적은 비슷하지만 구현 방식은 다르다.

Positive가 0개인 batch에서는 분모가 0이 되지 않도록 구현 수준의 guard가 필요하다. 식만 보고 모든 batch에 positive가 반드시 존재한다고 가정하면 안 된다.

## 8. 저장된 학습 출력과 해석 한계

합성 train 600 scenes와 validation 60 scenes를 생성하고 15 epochs 학습한 출력이 저장돼 있다. 최종 저장 metric은 다음과 같다.

| Class | Center-distance AP | Precision at score 0.5 | Recall at score 0.5 |
| --- | ---: | ---: | ---: |
| Car | 0.948 | 0.308 | 0.974 |
| Pedestrian | 0.912 | 0.518 | 1.000 |

이 AP는 KITTI official AP가 아니다. Prediction center가 GT center에서 Car 2 m, Pedestrian 1 m 이내면 match하는 실습용 center-distance AP다. 합성 validation data에 대한 결과이므로 실제 도로 성능으로 해석할 수 없다.

Notebook의 학습 출력에는 `lr_scheduler.step()`을 `optimizer.step()`보다 먼저 호출했다는 PyTorch warning이 저장돼 있다. 이 순서는 첫 learning-rate 값을 건너뛸 수 있다. 따라서 저장 metric은 그 실행의 결과로 기록할 수 있지만, corrected schedule의 결과로 부르면 안 된다. 첨부 notebook은 원래 코드를 보존한 출력 제거본이다. 학습을 재실행할 때는 optimizer update 뒤에 scheduler update를 배치하고 metric을 다시 생성해야 한다.

## 9. Synthetic-to-Real Domain Gap

합성 ray caster는 64 channels, sensor height 1.73 m, angular sampling, range noise 2 cm, random point dropout 5%를 사용한다. Sensor geometry 일부를 맞췄지만 실제 KITTI에는 차량 표면 형상, 유리 투과·반사, vegetation, road slope, sensor calibration error와 같은 요소가 더 있다.

따라서 합성 학습 모델을 KITTI sample에 적용하는 마지막 그림은 benchmark가 아니라 **domain gap 진단**이다. 결과가 나쁘면 구조 자체의 실패와 simulation mismatch를 분리해 봐야 하며, 결과가 좋아 보여도 한 frame의 정성 결과로 일반화할 수 없다.

## 핵심 정리

1. Point cloud는 $$N\times4$$의 가변 길이 unordered set이다.
2. Voxelization은 point를 regular grid에 배치하지만 대부분의 voxel은 비어 있다.
3. VFE는 absolute·relative coordinates를 사용해 voxel feature를 학습한다.
4. 3D convolution 뒤 height를 channel에 합치면 BEV 2D detection으로 연결할 수 있다.
5. 3D anchor는 position, size, yaw를 예측하므로 7개 regression target을 사용한다.
6. 저장 metric은 synthetic data와 center-distance 평가에 한정되며 KITTI 공식 성능이 아니다.

## 결론 및 학습 성과

이 과제는 3D detector의 이름을 외우는 대신 representation이 어떻게 바뀌는지 추적하게 한다. Raw point에서 voxel feature, dense 3D tensor, BEV feature, anchor score와 box로 이어지는 shape 변화를 이해하면 VoxelNet의 계산 비용, 희소성 문제, anchor matching, domain gap을 하나의 흐름으로 설명할 수 있다.

## References

- [VoxelNet: End-to-End Learning for Point Cloud Based 3D Object Detection](https://arxiv.org/abs/1711.06396){:target="_blank" rel="noopener"}
- [PIXOR: Real-time 3D Object Detection from Point Clouds](https://arxiv.org/abs/1902.06326){:target="_blank" rel="noopener"}
- [PointRCNN: 3D Object Proposal Generation and Detection from Point Cloud](https://arxiv.org/abs/1812.04244){:target="_blank" rel="noopener"}
- [MMDetection3D KITTI demo data](https://github.com/open-mmlab/mmdetection3d/tree/main/demo/data/kitti){:target="_blank" rel="noopener"}
