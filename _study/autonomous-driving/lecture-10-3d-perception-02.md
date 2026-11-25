---
layout: default
date: 2026-10-06 11:40:00 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Lecture 10: LiDAR-Based 3D Object Detection"
course: "Autonomous Driving"
topic: "Point Clouds, PointNet++, PointRCNN, VoxelNet, and PIXOR"
order: 10
major_topic: "Autonomous Systems"
keywords:
  - "LiDAR"
  - "Point Cloud"
  - "PointNet"
  - "PointNet++"
  - "PointRCNN"
  - "VoxelNet"
  - "PIXOR"
  - "3D Object Detection"
---

# Lecture 10: LiDAR-Based 3D Object Detection

Source PDF: [10 3D Perception (2).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf" | relative_url }})

국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 10강은 LiDAR가 만든 불규칙한 point set을 신경망 입력으로 바꾸는 방법에서 출발해 PointRCNN, VoxelNet, PIXOR의 서로 다른 3D detection 경로를 비교합니다. 핵심은 모델 이름을 외우는 것이 아니라 **어느 표현에서 정보를 모으고, 어느 단계에서 규칙적인 tensor로 바꾸며, 그 선택이 정확도·계산량·좌표 해석에 어떤 제약을 만드는지** 이해하는 데 있습니다.

> **핵심:** PointNet은 각 점을 같은 MLP로 처리한 뒤 대칭 함수인 max pooling으로 순서가 없는 집합을 요약합니다. PointNet++는 이 과정을 국소 이웃에 계층적으로 적용합니다. PointRCNN은 원시 점에서 foreground를 찾고 proposal을 두 단계로 다듬으며, VoxelNet은 3D voxel과 VFE를 거쳐 3D convolution을 사용합니다. PIXOR는 높이 축을 channel로 접어 BEV 위에서 2D convolution을 수행합니다. 따라서 세 detector의 차이는 단순히 one-stage와 two-stage의 차이가 아니라 **point-wise, voxel-wise, BEV pixel-wise 표현 중 무엇을 계산의 중심에 두는가**에 있습니다.

카메라 영상은 왼쪽 위부터 오른쪽 아래까지 pixel 위치가 정해진 격자지만, LiDAR point cloud는 $$(x,y,z)$$ 점들의 목록입니다. 같은 장면의 점을 파일에서 다른 순서로 나열해도 물체는 바뀌지 않습니다. 따라서 점 번호에 따라 결과가 달라지는 계산은 적절하지 않습니다. PointNet이 모든 점에 같은 MLP를 적용하고 max pooling을 쓰는 이유는, 각 점에서 강하게 검출된 특징만 모으면 입력 순서를 바꾸어도 같은 요약을 얻기 때문입니다. 다만 전체 max 하나만으로는 가까운 점끼리 만든 작은 구조를 놓칠 수 있어, PointNet++는 먼저 국소 이웃을 묶은 뒤 같은 계산을 계층적으로 반복합니다.

## 전체 흐름

| 순서 | 슬라이드 | 핵심 질문 |
|---|---:|---|
| 1 | 9–10 | Point cloud는 왜 일반 image tensor와 다루는 방식이 다릅니까? |
| 2 | 11–13 | PointNet의 순열 불변성과 PointNet++의 국소 계층은 어떻게 만들어집니까? |
| 3 | 15–23 | PointRCNN은 foreground point에서 proposal을 만들고 어떤 좌표계에서 정제합니까? |
| 4 | 24–32 | VoxelNet은 가변 개수의 점을 고정된 sparse 4D tensor로 어떻게 바꿉니까? |
| 5 | 33–37 | PIXOR는 왜 높이를 channel로 접고 BEV에서 dense prediction을 합니까? |
| 6 | 1–8, 38–41 | 강의의 행정·구성 페이지와 다음 multimodal 강의의 경계는 무엇입니까? |

## 1. Point cloud: 순서 없는 3D 측정 집합

슬라이드 9쪽은 LiDAR 측정을 $$N\times3$$ 행렬로 소개합니다. 각 행은 한 점의 3차원 위치입니다. 실제 LiDAR 파일에는 반사 강도, ring index, timestamp 같은 속성이 추가될 수 있지만 이 강의의 출발점은 다음 집합입니다.

$$
\mathcal{P}=\{\mathbf{p}_i\}_{i=1}^{N},\qquad
\mathbf{p}_i=(x_i,y_i,z_i)\in\mathbb{R}^{3}
$$

$$N$$은 점의 개수로 무차원이고, $$(x_i,y_i,z_i)$$는 센서 좌표계에서의 위치로 보통 meter 단위를 씁니다. 행렬로 저장하더라도 본질은 **집합**입니다. 같은 점들을 다른 행 순서로 저장해도 같은 장면이어야 합니다. 슬라이드 10쪽이 제시한 세 가지 난점은 여기에서 나옵니다.

1. **가변 크기:** 프레임마다 유효한 점의 수 $$N$$이 달라집니다.
2. **순열 불변성:** 같은 점들의 저장 순서만 바꾸면 전역 표현과 물체 분류 결과가 같아야 합니다.
3. **기하 변환 처리:** 센서 또는 물체 자세가 바뀌어도 의미를 안정적으로 추출해야 합니다.

두 번째 조건은 임의의 순열 $$\pi$$에 대해 다음처럼 쓸 수 있습니다.

$$
f(\mathbf{p}_1,\ldots,\mathbf{p}_N)
=f(\mathbf{p}_{\pi(1)},\ldots,\mathbf{p}_{\pi(N)})
$$

이 식은 **정의에 가까운 요구 조건**입니다. 점의 좌표를 회전시켜도 출력이 같다는 회전 불변성과는 별개입니다. 행 순서를 바꾸는 순열은 공간의 형상을 바꾸지 않지만, 좌표를 회전하면 각 점의 수치 자체가 달라집니다.

## 2. PointNet: shared MLP와 대칭 집계

<figure id="adc-10-p12">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-10-p12.png" | relative_url }}" alt="Point-wise MLP와 max pool을 공유하는 PointNet 분류 및 segmentation" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=12" | relative_url }}">lecture PDF, p. 12</a>.</figcaption>
</figure>

그림의 위쪽 classification 경로를 왼쪽부터 읽으면 **점별 특징 추출 → 점 전체의 집계 → 물체 분류**로 이어집니다. 입력의 $$n\times3$$에서 $$n$$은 점 수이고 3은 좌표 성분 수입니다. Shared MLP는 모든 점에 같은 가중치를 적용합니다. $$n\times1024$$까지는 점마다 1024개 특징이 있지만, max pool이 점 축을 따라 각 특징의 최댓값을 고르면 점 수와 무관한 길이 1024의 global feature가 됩니다. 그림의 소문자 $$n$$과 본문의 $$N$$은 같은 점 수를 뜻합니다.

아래 segmentation 경로에서는 global feature를 각 점의 local feature와 이어 붙여 점별 class를 예측합니다. $$n\times64$$ local feature의 각 행에 길이 1024의 global feature를 붙이므로 $$n\times1088$$이 됩니다. 위쪽은 물체 전체에 하나의 class score vector를, 아래쪽은 각 점에 하나씩 score vector를 만든다는 차이가 있습니다.

이 구조는 10쪽의 세 조건에 서로 다르게 대응합니다. **가변 점 수는 점 축을 줄이는 pooling으로, 순열 불변성은 shared MLP와 대칭 집계로 처리합니다. 회전에는 T-Net의 학습된 정렬로 대응하지만, 엄밀한 회전 불변성을 보장하지는 않습니다.** 실제 학습 구현에서 batch를 만들기 위해 일정 개수의 점을 sampling하는 것은 구조가 가변 점 수를 처리할 수 있다는 성질과 별개입니다.

슬라이드 11–12쪽의 PointNet은 모든 점에 같은 함수 $$h$$를 적용하고, 점 순서와 무관한 max pooling으로 전역 feature를 만듭니다. 분류용 핵심 구조는 다음처럼 요약할 수 있습니다.

점마다 여러 특징 점수가 있다고 생각하면 됩니다. Max pooling은 점 하나를 통째로 대표로 고르지 않습니다. **각 특징 항목에서 가장 강한 응답을 낸 점의 값만 따로 모아** 물체 전체 요약을 만듭니다. 점의 나열 순서를 바꿔도 항목별 최댓값은 같으므로 순열 불변성이 생깁니다.

$$
\mathbf{g}=\underset{i=1,\ldots,N}{\operatorname{MAX}}\ h(\mathbf{p}_i),
\qquad
\hat{\mathbf{y}}=\gamma(\mathbf{g})
$$

여기서 $$h:\mathbb{R}^{d}\rightarrow\mathbb{R}^{K}$$는 점별 shared MLP, $$\operatorname{MAX}$$는 $$K$$개 feature 차원마다 모든 점의 최댓값을 취하는 연산, $$\gamma$$는 전역 feature를 class score로 바꾸는 MLP입니다. $$d,K,N$$은 차원 또는 개수로 무차원이며 학습된 feature도 무차원 값입니다. 이 식은 정렬 이후의 분류 경로를 요약한 것입니다. 비어 있지 않은 입력에서 $$N\times d\rightarrow N\times K\rightarrow K$$로 점 축을 제거하므로 $$N$$이 달라도 분류기에 들어가는 feature 길이는 같습니다. **길이가 같다는 뜻이지, 점을 추가·제거해도 feature 값이나 예측이 같다는 뜻은 아닙니다.** 이는 [PointNet 원 논문](https://arxiv.org/abs/1612.00593){:target="_blank" rel="noopener"}의 대칭 함수 구성과 일치합니다.

### 2.1 작은 수치 예제

Shared MLP와 max pooling의 역할을 분리해 보기 위한 작성자 예제입니다. 세 점의 학습된 point-wise feature가 아래와 같다고 하겠습니다. 좌표 자체가 아니라 MLP를 통과한 2차원 특징 값입니다.

$$
\begin{aligned}
h(\mathbf{p}_1)&=(1,4)\\
h(\mathbf{p}_2)&=(3,2)\\
h(\mathbf{p}_3)&=(2,5)
\end{aligned}
$$

첫 번째 특징에서는 세 값 1, 3, 2를, 두 번째 특징에서는 4, 2, 5를 비교합니다.

$$
\mathbf{g}=(\max(1,3,2),\max(4,2,5))=(3,5)
$$

첫 번째 최댓값 3은 $$\mathbf{p}_2$$에서, 두 번째 최댓값 5는 $$\mathbf{p}_3$$에서 가져옵니다. **가장 큰 점 하나를 고르는 연산이 아니라 특징 차원마다 따로 최댓값을 고르는 연산**입니다.

입력 순서를 $$\mathbf{p}_3,\mathbf{p}_1,\mathbf{p}_2$$로 바꾸면 shared MLP는 각 점에 전과 같은 함수를 적용합니다. 따라서 특징 값은 바뀌지 않고 나열 순서만 달라집니다.

$$
\mathbf{g}'=(\max(2,1,3),\max(5,4,2))=(3,5)
$$

두 경우 모두 분류기는 같은 $$(3,5)$$를 받습니다. 반면 $$\mathbf{p}_3$$를 제거하면 global feature는 $$(3,4)$$로 바뀝니다. 점이 두 개여도 출력은 여전히 2차원이지만, 두 번째 특징의 최댓값은 달라집니다. 이 계산은 정렬 이후 특징을 고정해 pooling만 비교한 예입니다. 전체 모델에서는 점의 추가·제거가 T-Net의 정렬에도 영향을 줄 수 있습니다.

Shared MLP도 필요한 조건입니다. 첫 번째 행과 두 번째 행에 서로 다른 함수를 적용한다면 점을 재배열할 때 특징 값 자체가 달라질 수 있으므로, 마지막에 max를 쓰는 것만으로는 순열 불변성을 보장할 수 없습니다.

분할에서는 global feature를 각 점의 local feature와 이어 붙이고 shared MLP로 point-wise score를 만듭니다. 입력을 재배열하면 **같은 점에 붙는 예측은 유지되지만 출력 행도 함께 재배열됩니다.** 이를 순열 등변성(permutation equivariance)이라 합니다. 물체 전체의 분류 결과가 그대로인 순열 불변성과 구분해야 합니다.

<details markdown="block">
<summary markdown="span">Derivation: Permutation-invariant pooling and equivariant segmentation</summary>

다음은 shared point function과 coordinate-wise max의 성질을 보이는 작성자 보충 증명입니다. 학습된 함수를 고정한 추론에서 같은 비어 있지 않은 점 집합의 순서만 바꾼다고 가정합니다. $$\pi$$는 $$1,\ldots,N$$을 한 번씩 재배열하는 순열이고, $$h_k$$는 $$K$$차원 특징 중 $$k$$번째 성분입니다. Index와 특징 값은 모두 무차원입니다.

원래 순서의 $$k$$번째 global feature는 다음과 같습니다.

$$
g_k=\max_{1\le i\le N}h_k(\mathbf{p}_i)
$$

순서를 바꾸어도 같은 $$h$$를 적용하므로 바뀌는 것은 index뿐입니다. $$\pi$$가 모든 index를 정확히 한 번씩 방문하므로 최댓값의 후보 집합도 같습니다.

$$
\begin{aligned}
g'_k
&=\max_{1\le i\le N}h_k(\mathbf{p}_{\pi(i)})\\
&=\max_{1\le j\le N}h_k(\mathbf{p}_j)=g_k
\end{aligned}
$$

모든 $$k$$에서 같으므로 $$\mathbf{g}'=\mathbf{g}$$이고, 같은 분류 함수에 넣으면 $$\gamma(\mathbf{g}')=\gamma(\mathbf{g})$$입니다. 최댓값을 만드는 점이 여러 개여도 최댓값 자체는 같으므로 결론은 유지됩니다.

T-Net도 내부에서 shared point function과 대칭 max로 전체 입력을 요약해 하나의 변환 행렬을 예측합니다. 따라서 같은 점들의 순서만 바꾸면 같은 변환을 예측하고, 변환 후 각 점의 특징도 순서만 달라집니다. 위 논리는 T-Net을 포함한 경로에도 적용됩니다.

Segmentation에서 $$\boldsymbol{\ell}_i$$를 점 $$i$$의 local feature, $$\psi$$를 모든 점에 공유하는 예측 함수라 하면 점별 score는 다음과 같습니다. $$[\,\cdot\,;\,\cdot\,]$$는 두 벡터를 이어 붙인 결과를 나타냅니다.

$$
\mathbf{q}_i=\psi([\boldsymbol{\ell}_i;\mathbf{g}])
$$

재배열 뒤에는 local feature가 $$\boldsymbol{\ell}_{\pi(i)}$$가 되고 global feature는 그대로입니다. 따라서

$$
\mathbf{q}'_i=\psi([\boldsymbol{\ell}_{\pi(i)};\mathbf{g}])
=\mathbf{q}_{\pi(i)}
$$

가 됩니다. 예제의 순서가 3, 1, 2로 바뀌면 score의 순서도 $$\mathbf{q}_3,\mathbf{q}_1,\mathbf{q}_2$$로 바뀝니다. 이 증명은 같은 점 집합의 순열에 관한 것입니다. 점의 추가·제거, 좌표 회전, 서로 다른 sampling 결과가 같은 예측을 낸다는 증명은 아닙니다.

</details>

### 2.2 T-Net의 역할과 회전 불변성의 한계

그림 왼쪽 아래 T-Net은 입력 좌표용 $$3\times3$$ 행렬을, 그 옆 T-Net은 중간 특징용 $$64\times64$$ 행렬을 예측합니다. 각 행렬을 모든 점에 공통으로 곱해 좌표 또는 특징을 정렬합니다. 점을 열벡터로 쓰면 입력 정렬은 $$\mathbf{p}'_i=A_{\mathrm{in}}\mathbf{p}_i$$입니다. $$A_{\mathrm{in}}$$은 무차원이며 회전 각도를 미리 알아서 넣는 역회전 행렬이 아니라, 입력 점 집합을 보고 T-Net이 학습해 예측하는 행렬입니다.

**순열은 같은 좌표를 다른 순서로 놓지만, 회전은 좌표 값 자체를 바꿉니다.** 따라서 순열에 불변인 max pooling만으로 회전까지 제거할 수는 없습니다. T-Net은 서로 다른 자세의 입력을 비슷한 기준으로 정렬하도록 학습하고, 원 논문은 회전 data augmentation도 사용합니다. 이런 학습은 자세 변화에 대한 강건성을 높이려는 방법이지, 모든 회전에 대해 정확히 같은 출력이 나온다는 수학적 보장은 아닙니다.

Feature transform $$A$$에는 원 논문이 다음 정규화를 더합니다.

$$
\mathcal{L}_{\mathrm{reg}}=\left\lVert I-AA^{\top}\right\rVert_{F}^{2}
$$

$$I$$는 identity matrix, $$A$$는 학습한 feature transform, $$\lVert\cdot\rVert_F$$는 Frobenius norm이며 모두 모델 내부의 무차원 값입니다. 이 항은 $$A$$가 지나친 왜곡보다 orthogonal transform에 가까워지도록 유도합니다. 그러나 이는 모든 3D 회전에 대해 출력이 같다는 **엄밀한 회전 불변성 보장**이 아닙니다. 슬라이드 10쪽의 “rotation invariant”는 학습 목표 또는 바람직한 성질로 읽어야 하며, T-Net은 정렬을 학습해 민감도를 낮추는 방법입니다.

<details markdown="block">
<summary markdown="span">Derivation: What the orthogonality regularizer enforces</summary>

다음은 정규화 항의 의미를 확인하는 작성자 보충 유도입니다. $$A$$는 학습된 실수 정방행렬이며, $$\mathbf{a}_i$$는 $$i$$번째 행의 성분을 열벡터로 모은 것입니다. Frobenius norm의 정의에 따라 각 원소의 제곱을 더하면 다음 정확한 등식을 얻습니다.

$$
\left\lVert I-AA^{\top}\right\rVert_F^{2}
=\sum_{i}\sum_{j}\left(I_{ij}-\mathbf{a}_i^{\top}\mathbf{a}_j\right)^2
$$

각 제곱 항은 음수가 아니므로 합이 0인 것과 $$AA^{\top}=I$$인 것은 동치입니다. 이때 같은 행의 내적은 1, 서로 다른 행의 내적은 0이므로 행들이 unit length이고 서로 orthogonal합니다. 단위행렬을 넣으면 손실은 0입니다. 검산으로 $$A=2I$$를 넣으면 $$AA^{\top}=4I$$여서, 행렬 크기가 $$r\times r$$일 때 손실은 $$9r$$입니다. $$r$$도 무차원입니다.

실제 학습에서는 이 항과 주어진 task의 손실을 함께 줄이므로 정규화 손실이 정확히 0이 된다는 보장도 없습니다. 이 항은 특징 공간에서 길이·각도의 지나친 왜곡을 억제하는 **설계 목적함수**이며, 입력의 임의 회전 $$R$$에 대해 $$f(R\mathcal{P})=f(\mathcal{P})$$임을 증명하는 식은 아닙니다.

</details>

### 2.3 왜 local structure가 약한가

PointNet은 개별 점을 shared MLP로 처리한 뒤 장면 전체를 한 번에 max pooling합니다. 가까운 두 점이 이루는 모서리와 멀리 떨어진 두 점의 조합을 **국소 이웃 계층**으로 명시적으로 구분하지 않습니다. 슬라이드 12–13쪽의 “local structure를 모델링하지 못한다”는 지적은 이 구조적 한계를 뜻합니다. 모든 국소 정보를 전혀 배울 수 없다는 절대 명제보다는, metric neighborhood를 단계적으로 구성하지 않는다는 뜻으로 제한해 이해하는 편이 정확합니다.

## 3. PointNet++: 국소 영역을 점점 크게 요약하기

슬라이드 13쪽의 PointNet++는 PointNet을 없애는 모델이 아니라 **작은 이웃마다 PointNet을 반복 적용**하는 계층 구조입니다. [PointNet++ 원 논문](https://arxiv.org/abs/1706.02413){:target="_blank" rel="noopener"}의 set abstraction level은 세 단계로 구성됩니다.

1. **Sampling:** farthest point sampling으로 다음 계층의 centroid를 고릅니다.
2. **Grouping:** 각 centroid 주변의 점을 거리 기반 이웃으로 묶습니다.
3. **Local PointNet:** 이웃 점의 상대 좌표와 feature를 작은 PointNet으로 집계합니다.

입력이 $$N\times(d+C)$$ tensor라면 한 set abstraction level의 출력은 보통 $$N'\times(d+C')$$입니다. $$N'<N$$이므로 point 수는 줄고, 각 centroid의 feature 차원과 포괄하는 공간 범위는 커집니다. 이 과정을 반복하면 작은 표면 조각에서 물체 부품, 더 넓은 문맥으로 receptive field가 확장됩니다.

이웃을 centroid $$\mathbf{c}$$ 기준의 상대 좌표로 쓰는 이유는 지역 패턴이 장면의 절대 원점에만 묶이지 않게 하기 위해서입니다.

$$
\Delta\mathbf{p}_i=\mathbf{p}_i-\mathbf{c}
$$

두 항의 단위가 meter이므로 $$\Delta\mathbf{p}_i$$도 meter입니다. 이 변환은 평행이동에 대한 지역적 표현을 만들지만, sampling radius와 point density가 맞지 않으면 빈 이웃 또는 지나치게 조밀한 이웃이 생길 수 있습니다. 원 논문이 multi-scale grouping과 density 적응을 다루는 이유입니다. 슬라이드의 “Multi-scale PointNet”은 서로 다른 크기의 국소 문맥을 결합한다는 뜻입니다.

## 4. 3D bounding box와 세 detector의 표현 선택

슬라이드 15쪽은 LiDAR 기반 detector로 PointRCNN, VoxelNet, PIXOR를 제시합니다. 먼저 3D box를 다음처럼 나타내겠습니다.

$$
\mathbf{b}=(x_c,y_c,z_c,h,w,l,\theta)
$$

중심 $$(x_c,y_c,z_c)$$와 크기 $$(h,w,l)$$의 단위는 meter, yaw $$\theta$$의 단위는 radian입니다. 좌표축 이름은 데이터셋과 논문마다 다르므로 “$$y$$가 항상 전방”처럼 고정해서 외우면 안 됩니다. PointRCNN 원 논문은 ground plane을 $$X\text{-}Z$$, vertical axis를 $$Y$$로 기술합니다. VoxelNet 원 논문의 KITTI 설정은 $$Z,Y,X$$ 순으로 vertical, lateral, forward 범위를 적습니다.

| 모델 | 주된 중간 표현 | 집계 연산 | 검출 단계 |
|---|---|---|---|
| PointRCNN | 원시 point와 point-wise feature | PointNet++ 및 proposal별 point pooling | Bottom-up proposal + refinement의 two-stage |
| VoxelNet | Sparse 3D voxel feature tensor | VFE + 3D convolution | RPN head를 둔 one-stage |
| PIXOR | 높이를 channel로 쌓은 BEV grid | 2D convolution | Proposal-free dense one-stage |

## 5. PointRCNN: point에서 proposal을 위로 쌓기

<figure id="adc-10-p22">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-10-p22.png" | relative_url }}" alt="PointRCNN의 foreground 기반 proposal과 canonical refinement" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=22" | relative_url }}">lecture PDF, p. 22</a>.</figcaption>
</figure>

위 경로에서 foreground 점을 구분하고 bin-based box proposal을 만듭니다. 아래 경로는 proposal 주변의 점과 특징을 모아 canonical 좌표로 변환한 뒤 box와 confidence를 정제합니다. 2D 이미지에서 자른 crop을 분류하는 방식과 달리 3D 점의 위치를 직접 이용하는 two-stage 구조입니다.

슬라이드 16–23쪽의 PointRCNN은 “Faster R-CNN의 point cloud 버전”이라는 직관으로 소개되지만, proposal 생성 방식은 2D anchor 기반 RPN과 다릅니다. [PointRCNN 원 논문](https://arxiv.org/abs/1812.04244){:target="_blank" rel="noopener"}은 raw point cloud 전체에서 foreground point를 분할하고, 그 점을 중심으로 bottom-up proposal을 만든 뒤 canonical coordinate에서 정제합니다.

### 5.1 Stage 1: foreground segmentation이 검색 공간을 줄인다

PointNet++ backbone이 각 점의 semantic feature를 만듭니다. 3D ground-truth box 안에 있는 점은 foreground, 밖의 점은 background로 label합니다(17–18쪽). Outdoor scene은 background point가 훨씬 많으므로 원 논문은 focal loss를 사용합니다.

$$
\mathcal{L}_{\mathrm{focal}}(p_t)
=-\alpha_t(1-p_t)^{\gamma}\log p_t
$$

$$p_t$$는 정답 class에 대한 확률, $$\alpha_t$$와 $$\gamma$$는 무차원 hyperparameter입니다. 원 논문 설정 $$\alpha_t=0.25$$, $$\gamma=2$$에서 쉬운 양성점 $$p_t=0.9$$의 손실은 약 0.00026, 어려운 양성점 $$p_t=0.2$$의 손실은 약 0.2575입니다. 이는 많은 쉬운 background가 gradient를 지배하지 않도록 하는 **학습 손실의 설계**이며 foreground 판단이 완벽하다는 보장은 아닙니다.

Foreground로 예측한 점에서만 3D proposal을 만들면 장면 전체의 모든 위치에 많은 anchor를 깔 필요가 없습니다. 슬라이드 17쪽은 상위 100개 proposal을 refinement stage로 넘깁니다. 이 수는 해당 구현 설정이며 모든 PointRCNN 변형의 불변값은 아닙니다.

### 5.2 Bin-based box generation: 분류와 잔차 회귀의 결합

슬라이드 19쪽은 center $$(x,y,z)$$를 모두 foreground point에서 회귀한다고 요약합니다. 원 논문의 실제 parameterization은 더 구체적입니다.

- Ground plane의 $$x,z$$: 주변 search range를 bin으로 나누어 **bin classification + within-bin residual regression**을 합니다.
- Vertical coordinate $$y$$: 값의 범위가 작다는 가정 아래 smooth L1로 직접 회귀합니다.
- Size $$h,w,l$$: class 평균 크기에서의 residual을 직접 회귀합니다.
- Orientation $$\theta$$: angle bin classification + residual regression을 합니다.

한 축의 bin 중심을 $$c_k$$, 선택한 bin을 $$k^*$$, 예측 residual을 $$\Delta_k$$라 하면 복원은 다음 형태입니다.

$$
\hat{x}=c_{k^*}+\Delta_{k^*}
$$

$$c_k,\Delta_k,\hat{x}$$의 단위는 meter입니다. 예를 들어 bin 중심이 $$(-0.75,-0.25,0.25,0.75)\ \mathrm{m}$$이고 실제 offset이 $$0.62\ \mathrm{m}$$라면 $$0.75\ \mathrm{m}$$ bin과 $$-0.13\ \mathrm{m}$$ residual을 골라 $$0.62\ \mathrm{m}$$를 복원할 수 있습니다. 이 예는 분류가 coarse location을, residual이 bin 내부 정밀도를 맡는 방식을 보이기 위한 작성자 보충입니다.

### 5.3 Stage 2: proposal coordinate로 정규화해 정제한다

슬라이드 20–21쪽의 두 번째 단계는 각 3D proposal 안의 point와 stage 1 semantic feature를 pooling합니다. 각 proposal 중심 $$\mathbf{c}_p$$를 원점으로 옮기고 proposal의 평면 방향을 제거해 canonical coordinate를 만듭니다. 여기서는 PointRCNN의 다른 축·yaw 부호 관례와 섞이지 않도록, ground plane의 $$+X$$축에서 $$+Z$$축 방향으로 잰 proposal angle을 보조기호 $$\phi_p$$로 정의합니다.

먼저 global ground-plane 좌표 $$\mathbf{u}=[x,z]^{\top}$$에서 proposal 중심 $$\mathbf{c}_p=[x_p,z_p]^{\top}$$를 빼 translation을 제거합니다.

$$
\mathbf{q}=\mathbf{u}-\mathbf{c}_p
$$

Proposal의 local basis를 $$\mathbf{e}'_x=(\cos\phi_p,\sin\phi_p)$$, $$\mathbf{e}'_z=(-\sin\phi_p,\cos\phi_p)$$로 두면 local coordinate는 각 basis와의 dot product입니다.

$$
x'=\mathbf{e}_x'^{\top}\mathbf{q},\qquad
z'=\mathbf{e}_z'^{\top}\mathbf{q}
$$

두 식을 matrix로 쌓으면 작성자 보충 canonical transform이 됩니다.

$$
\begin{bmatrix}
x'\\z'
\end{bmatrix}
=
\begin{bmatrix}
\cos\phi_p&\sin\phi_p\\
-\sin\phi_p&\cos\phi_p
\end{bmatrix}
\left(
\begin{bmatrix}
x\\z
\end{bmatrix}
-
\begin{bmatrix}
x_p\\z_p
\end{bmatrix}
\right)
$$

좌표의 단위는 meter, $$\phi_p$$의 단위는 radian입니다. 예를 들어 $$\mathbf{c}_p=(10,5)\ \mathrm{m}$$, $$\phi_p=\pi/2$$, $$\mathbf{u}=(10,7)\ \mathrm{m}$$이면 $$\mathbf{q}=(0,2)\ \mathrm{m}$$입니다. Local basis에 투영하면 $$(x',z')=(2,0)\ \mathrm{m}$$가 되어, global $$+Z$$ 방향의 2 m offset이 proposal의 local $$+X$$ 방향으로 정렬됩니다. Proposal마다 서로 다른 전역 위치와 방향을 제거하면 refinement network는 “센서에서 어디에 있는 차인가”보다 “현재 proposal 내부에서 실제 box가 어느 쪽으로 얼마나 어긋났는가”를 학습하기 쉬워집니다. 이 canonical transform은 정보의 완전한 불변성을 증명하는 장치가 아니라, residual 예측의 조건을 단순화하는 좌표 변환입니다.

PointRCNN의 장점은 raw point의 정밀한 기하를 유지하며 proposal을 정제한다는 점입니다. 반면 foreground segmentation, proposal 생성, point pooling, refinement가 순차적으로 필요하므로 슬라이드 23쪽은 two-stage pipeline의 latency 부담을 지적합니다. “느리다”는 상대적 구조 설명이며 hardware·입력 범위·implementation 없이 보편적인 FPS 수치로 바꾸어 말할 수는 없습니다.

## 6. VoxelNet: 불규칙한 점을 학습 가능한 voxel feature로 바꾸기

<figure id="adc-10-p29">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-10-p29.png" | relative_url }}" alt="Voxel partition grouping sampling과 VFE를 통한 sparse tensor 생성" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=29" | relative_url }}">lecture PDF, p. 29</a>.</figcaption>
</figure>

왼쪽 점들을 voxel에 묶고, 각 voxel에서 점 수를 제한해 같은 VFE로 처리합니다. Point-wise feature와 voxel 안의 집계 정보를 결합한 뒤 voxel feature 하나를 만듭니다. 마지막 tensor의 공간 위치는 원래 voxel 좌표를 유지합니다. Voxel 크기를 정하는 일과 한 voxel에서 몇 점을 남길지는 서로 다른 선택입니다.

슬라이드 24쪽의 voxel은 3D 공간의 규칙적인 cell입니다. VoxelNet의 핵심은 각 cell에 단순 occupancy 또는 수작업 통계를 넣는 데 그치지 않고, cell 안의 point feature를 VFE로 학습한다는 점입니다. [VoxelNet 원 논문](https://arxiv.org/abs/1711.06396){:target="_blank" rel="noopener"}은 feature learning network, convolutional middle layers, region proposal network의 세 블록으로 구성됩니다.

### 6.1 Voxelization과 grid 크기

공간 범위를 $$[x_{\min},x_{\max})$$, voxel 폭을 $$v_x$$라 하면 한 점의 x축 cell index는 다음과 같습니다.

$$
i_x=\left\lfloor\frac{x-x_{\min}}{v_x}\right\rfloor
$$

$$x,x_{\min},v_x$$의 단위는 meter이고, $$i_x$$는 무차원 정수 index입니다. 다른 두 축도 같은 방식입니다. 원 논문의 KITTI car 설정은 $$Z,Y,X$$ 범위를 각각 $$[-3,1]$$, $$[-40,40]$$, $$[0,70.4]$$ meter로 제한하고 voxel 크기를 다음처럼 둡니다.

$$
(v_D,v_H,v_W)=(0.4,0.2,0.2)\ \mathrm{m}
$$

즉 vertical 방향이 0.4 m, 두 ground-plane 방향이 0.2 m입니다. 결과 grid는 $$D'=10$$, $$H'=400$$, $$W'=352$$로 총 $$1{,}408{,}000$$개 cell을 갖습니다. 슬라이드 25쪽의 “0.2 m × 0.2 m × 0.4 m”는 축 이름이 생략되어 있으므로 숫자의 순서만으로 x, y, z를 고정하면 안 됩니다.

### 6.2 Grouping과 random sampling이 필요한 이유

각 voxel의 point 수는 0부터 큰 값까지 달라집니다. 그대로 batch tensor로 만들면 memory shape가 일정하지 않고 가까운 표면의 조밀한 point가 계산을 과도하게 차지합니다. 슬라이드 26쪽과 원 논문은 point가 너무 많은 non-empty voxel에서 최대 $$T$$개를 random sample합니다. 원 논문의 car 설정은 $$T=35$$입니다.

이 sampling은 계산량을 제한하고 voxel 간 density imbalance를 줄이는 방법입니다. 반대로 sampling된 point만 남기므로 같은 입력이라도 선택에 따른 변동이 생길 수 있고, 드문 구조의 점이 빠질 수 있습니다. “balance 조정”은 모든 voxel의 정보량이 같아진다는 뜻이 아닙니다.

### 6.3 VFE: point-wise와 voxel-wise 정보를 결합한다

한 non-empty voxel의 점을 $$\mathbf{p}_i=(x_i,y_i,z_i,r_i)$$로 두겠습니다. $$r_i$$는 반사 강도로 sensor가 제공한 값이며 정규화 방식에 따라 무차원으로 다룹니다. Voxel centroid $$(\bar{x},\bar{y},\bar{z})$$를 계산한 뒤 원 논문의 VFE 입력은 7차원입니다.

$$
\hat{\mathbf{p}}_i=
(x_i,y_i,z_i,r_i,
x_i-\bar{x},y_i-\bar{y},z_i-\bar{z})
$$

좌표와 offset은 meter, $$r_i$$는 무차원입니다. Point-wise fully connected network가 $$\mathbf{f}_i$$를 만들고, 같은 voxel의 모든 점에 대해 element-wise max pooling한 local aggregate를 $$\tilde{\mathbf{f}}$$라 하겠습니다.

$$
\tilde{\mathbf{f}}=\underset{i=1,\ldots,t}{\operatorname{MAX}}\ \mathbf{f}_i
$$

그 다음 각 point feature에 같은 aggregate를 concat합니다.

$$
\mathbf{f}^{\mathrm{out}}_i=
\left[\mathbf{f}_i,\tilde{\mathbf{f}}\right]
$$

슬라이드 27쪽의 핵심은 이 concat입니다. 각 점은 자신의 local feature와 voxel 전체 요약을 동시에 다음 VFE layer로 보냅니다. 마지막 point-wise feature를 다시 max pooling하면 하나의 voxel-wise feature가 됩니다. 이것이 수작업 통계 대신 학습된 voxel 표현을 만드는 과정입니다.

### 6.4 Sparse 4D tensor에서 detection까지

Voxel-wise feature를 원래 grid 위치에 scatter하면 슬라이드 28–29쪽의 sparse tensor가 됩니다.

$$
\mathcal{V}\in\mathbb{R}^{C\times D'\times H'\times W'}
$$

$$C$$는 feature channel 수, $$D',H',W'$$는 voxel 개수로 모두 무차원입니다. 원 논문의 car 설정에서는 feature learning network가 $$128\times10\times400\times352$$ sparse tensor를 만듭니다. 30쪽의 3D convolutional middle layers는 이 tensor에서 이웃 voxel feature를 합쳐 receptive field를 넓힙니다. 이후 vertical dimension을 channel 쪽으로 reshape하고 2D RPN이 classification과 box regression map을 냅니다.

슬라이드 31쪽은 이 head를 `RPN`이라 부르면서도 전체 파이프라인은 one-stage라고 강조합니다. 이름만으로 two-stage라고 판단해서는 안 됩니다. VoxelNet의 RPN은 별도의 proposal을 다른 network가 다시 정제하는 PointRCNN식 두 번째 단계가 아니라 최종 score와 regression을 내는 detection head입니다.

슬라이드 32쪽의 trade-off도 표현 선택에서 나옵니다. 3D convolution은 kernel을 세 공간축으로 이동시키므로 2D convolution보다 계산 영역이 크고, sparse point를 dense grid로 펼치면 빈 cell이 많습니다. 다만 “3D convolution이므로 항상 느리다”는 보편 법칙은 아닙니다. Sparse convolution 구현, grid resolution, 범위, hardware에 따라 비용이 달라집니다. 이 강의에서는 **VoxelNet 원 설계의 비용 원인**으로 이해합니다.

### 6.5 3D anchor는 voxel과 무엇이 다른가

[원문 31쪽]({{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=31" | relative_url }})의 classification·regression 출력에서, regression의 기준이 되는 상자가 **3D anchor**입니다. Voxel이 입력 점을 묶는 공간 cell이라면, anchor는 검출 head의 출력 격자에 미리 놓는 객체 box의 기준입니다. **Voxel 크기와 anchor 크기는 서로 다른 설정**입니다. 하나의 차량이 여러 voxel에 걸쳐 있고, detection head는 주변 feature를 종합해 차량 box를 예측할 수 있습니다.

6강의 2D anchor에 깊이와 방향을 더하면 중심 위치 $$x,y,z$$, 길이·폭·높이 $$l,w,h$$, yaw $$\theta$$를 가진 3D box가 됩니다. 여기서는 원 VoxelNet 논문처럼 $$z$$를 **상자 중심의 수직 좌표**, yaw를 수직 Z축 주위의 회전각으로 정의합니다. 아래 보정식과 수치 예제는 슬라이드에 없는 부분을 [VoxelNet §2.2, 식 (1)](https://arxiv.org/abs/1711.06396){:target="_blank" rel="noopener"}에 근거해 보충한 것입니다.

- **Anchor:** 미리 정한 3D 중심·크기·방향으로, 회귀의 출발점입니다.
- **GT:** 데이터에 주어진 정답 3D box로, anchor 매칭과 목표 보정값을 만드는 데 씁니다.
- **Prediction:** 네트워크가 예측한 일곱 보정값을 anchor에 적용한 box입니다. GT와 일치할 수도, 오차가 남을 수도 있습니다.

추론에서는 GT 없이 feature로부터 score와 보정값을 예측합니다. VoxelNet의 decode 결과는 score filtering·NMS를 거쳐 검출 결과가 되며, Faster R-CNN처럼 별도의 두 번째 RoI head가 반드시 이어지는 구조는 아닙니다. 이 anchor 기반 설명을 다른 3D detector 전체에 그대로 적용해서는 안 됩니다.

**수치로 읽기.** 다음은 meter 단위의 작성자 설명용 예시이며 KITTI의 실제 anchor 설정이나 모델 실행 결과가 아닙니다. 세 box의 크기는 모두 $$(l,w,h)=(4,3,2)$$ m, yaw는 모두 $$0$$ rad으로 두고 중심만 비교합니다.

- **Anchor 중심:** (10, 5, 1) m. 보정의 기준입니다.
- **GT 중심:** (11.5, 5, 1) m. 학습 데이터의 정답입니다.
- **Prediction 중심:** (11, 5, 1) m. 예측 offset을 decode한 결과입니다.

Anchor 밑면의 대각선 길이는 $$d_a=\sqrt{4^2+3^2}=5$$ m입니다. GT까지 x축으로 1.5 m 이동해야 하므로 목표 수평 offset은 $$1.5/5=0.30$$입니다. 네트워크가 $$0.20$$을 예측했다면 실제 이동은 $$5\times0.20=1$$ m이므로 예측 중심 x는 11 m입니다. **GT보다 0.5 m 부족하게 이동한 것**입니다. 나머지 여섯 offset을 0으로 두었으므로 y·z·크기·yaw는 anchor와 같습니다.

이처럼 네트워크는 매번 절대 좌표를 처음부터 만들기보다 **기준 box에서의 변화량**을 예측합니다. VoxelNet은 수평 두 축에 같은 밑면 대각선 길이를 쓰고, 수직 이동에는 anchor 높이를 씁니다. 크기 비율에는 자연로그를 씁니다. 위치·크기 offset은 무차원이며 각도 offset은 rad입니다.

<details markdown="block">
<summary markdown="span">Derivation: Seven 3D anchor targets and their inverse transform</summary>

Anchor를 $$b_a=(x_a,y_a,z_a,l_a,w_a,h_a,\theta_a)$$, 매칭된 GT를 $$b_g=(x_g,y_g,z_g,l_g,w_g,h_g,\theta_g)$$라 하겠습니다. 중심·길이의 단위는 m이며 모든 길이는 양수입니다. 각도는 같은 기준축에서 rad으로 측정합니다. 원 논문의 회귀 target 정의를 별표로 표시하면

$$
d_a=\sqrt{l_a^2+w_a^2},\qquad
t_x^*=\frac{x_g-x_a}{d_a},\quad
t_y^*=\frac{y_g-y_a}{d_a},\quad
t_z^*=\frac{z_g-z_a}{h_a},
$$

$$
t_l^*=\ln\frac{l_g}{l_a},\quad
t_w^*=\ln\frac{w_g}{w_a},\quad
t_h^*=\ln\frac{h_g}{h_a},\quad
t_\theta^*=\theta_g-\theta_a.
$$

이는 box를 표현하기 위해 선택한 **정의**이지 학습 성능이 좋아진다는 수학적 증명은 아닙니다. 양수인 $$d_a,h_a$$로 나누므로 위치 offset은 무차원입니다. 두 수평 offset은 모두 같은 $$d_a$$로 나누므로 동일한 길이 척도를 사용합니다. 또한 $$l_a,w_a$$를 서로 바꿔도 $$d_a$$는 변하지 않습니다. 이 성질 자체가 임의 회전에 대한 전체 detector의 불변성을 보장하지는 않습니다.

Decode는 위 정의의 **정확한 역변환**입니다. 예를 들어 $$t_x=(x-x_a)/d_a$$에서 양변에 $$d_a$$를 곱하고 $$x_a$$를 더하면 $$x=x_a+d_at_x$$입니다. $$t_l=\ln(l/l_a)$$는 $$e^{t_l}=l/l_a$$를 거쳐 $$l=l_ae^{t_l}$$가 됩니다. 각도는 $$t_\theta=\theta-\theta_a$$에서 $$\theta=\theta_a+t_\theta$$로 풉니다. 네트워크 예측 $$\hat{t}$$에 적용하면

$$
\hat{x}=x_a+d_a\hat{t}_x,\quad
\hat{y}=y_a+d_a\hat{t}_y,\quad
\hat{z}=z_a+h_a\hat{t}_z,
$$

$$
\hat{l}=l_ae^{\hat{t}_l},\quad
\hat{w}=w_ae^{\hat{t}_w},\quad
\hat{h}=h_ae^{\hat{t}_h},\quad
\hat{\theta}=\theta_a+\hat{t}_\theta.
$$

본문 예시의 목표는 순서 $$(x,y,z,l,w,h,\theta)$$에 대해 $$t^*=(0.30,0,0,0,0,0,0)$$이고, 예측은 $$\hat{t}=(0.20,0,0,0,0,0,0)$$입니다. 목표를 decode하면 $$10+5(0.30)=11.5$$ m로 GT를 복원하지만, 예측을 decode하면 $$10+5(0.20)=11$$ m입니다. 크기 offset 0은 $$e^0=1$$이므로 원래 길이·폭·높이를 그대로 유지합니다. Anchor의 길이가 0이면 정규화나 로그 비율을 사용할 수 없습니다.

원 논문의 식 (1)은 yaw target을 단순한 각도 차이로 정의합니다. Lab 2 notebook은 이 차이를 **$$\pi$$ 주기로 정규화**합니다. 이는 해당 lab의 방향 동치 처리이며 원 논문 식에 있는 연산으로 소급해서 설명하지 않습니다. 또한 z를 바닥 중심으로 쓰는 구현이나 다른 tuple 순서의 값을 위 중심 좌표식에 그대로 대입하면 안 됩니다.

</details>

## 7. PIXOR: 높이를 channel로 바꾼 BEV dense detection

<figure id="adc-10-p37">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-10-p37.png" | relative_url }}" alt="Point cloud를 BEV input으로 변환해 oriented box를 예측하는 PIXOR" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf#page=37" | relative_url }}">lecture PDF, p. 37</a>.</figcaption>
</figure>

왼쪽 3D 점을 높이 구간 등의 channel을 가진 BEV 격자로 바꾼 뒤 detector가 위에서 본 oriented box를 출력합니다. 그림의 실시간 속도는 해당 실험 설정의 측정치이며 모든 장비에서 보장되는 값은 아닙니다. 아래의 tensor 설명에서는 공간 축 두 개와 높이 channel을 구분해서 읽습니다.

슬라이드 33쪽의 PIXOR는 “PIXel-wise neural network predictions”에서 “ORiented” box를 얻는 proposal-free detector입니다. [PIXOR 원 논문](https://openaccess.thecvf.com/content_cvpr_2018/html/Yang_PIXOR_Real-Time_3D_CVPR_2018_paper.html){:target="_blank" rel="noopener"}은 3D voxel grid 전체에 3D convolution을 적용하는 대신 BEV에서 2D convolution을 사용합니다.

### 7.1 BEV가 보존하는 것과 버리는 것

Perspective image에서는 멀리 있는 물체가 작아지지만, metric BEV grid에서는 4 m 길이 차량이 거리에 따라 임의로 짧아지지 않습니다. 그래서 ground plane의 physical size prior와 oriented box를 다루기 쉽습니다(34쪽). 또한 높이 축을 channel로 이동하면 convolution은 두 공간축만 이동합니다.

그러나 BEV가 모든 3D 정보를 손실 없이 보존하는 것은 아닙니다. Height bin을 channel에 남기더라도 vertical translation equivariance를 3D convolution처럼 사용하는 구조는 아니며, 원 설계는 vehicle이 공통 ground plane에 있다는 가정을 이용해 vertical center와 height를 최종 box parameter에서 생략합니다. 경사·다층 도로·공중 물체처럼 ground-plane 가정이 깨지는 상황에는 그대로 적용하기 어렵습니다.

슬라이드 34쪽의 “3D bounding box들이 서로 겹치지 않는다”는 문장은 front-view보다 occlusion이 줄어든다는 동기로 읽어야 합니다. 실제 BEV에서도 교차로의 차량, 겹치는 annotation, 근접한 oriented box는 겹칠 수 있습니다. PIXOR도 최종 단계에서 oriented IoU 기반 non-maximum suppression을 사용하므로 **비중첩은 기하학적 불변 조건이 아닙니다**.

### 7.2 Occupancy와 reflectance로 만드는 input tensor

슬라이드 35쪽은 각 축을 0.1 m cell로 나눈 occupancy를 소개합니다. 작성자 보충 정의로 한 cell의 occupancy는 다음과 같습니다.

$$
O_{i,j,k}=
\begin{cases}
1,&\text{cell }(i,j,k)\text{ 안에 LiDAR point가 하나 이상 있을 때}\\
0,&\text{그렇지 않을 때}
\end{cases}
$$

$$O_{i,j,k}$$와 index는 무차원입니다. 높이 bin $$k$$를 channel로 옮기면 ground-plane 위치 $$(i,j)$$마다 여러 occupancy channel이 생깁니다. 두 공개 판본은 이 기본 구성은 같지만 channel 수가 다릅니다.

- **CVPR 2018 판본:** height occupancy $$H/d_H$$개와 normalized reflectance 1개를 이어 붙여 channel 수가 $$H/d_H+1$$입니다. Network figure의 KITTI 입력은 $$800\times700\times36$$, 즉 35개 height slice와 reflectance 1개입니다.
- **2019 확장 저자 판본:** 범위 밖 point를 담는 occupancy channel 2개를 더해 channel 수가 $$H/d_H+3$$입니다. 같은 35개 height slice 설정의 KITTI 입력은 $$800\times700\times38$$입니다.

따라서 physical range가 $$L\times W\times H$$이고 resolution이 $$d_L,d_W,d_H$$라면 두 shape는 각각 다음과 같습니다.

$$
\text{CVPR 2018:}\qquad
\frac{L}{d_L}\times\frac{W}{d_W}\times
\left(\frac{H}{d_H}+1\right)
$$

$$
\text{2019 extended:}\qquad
\frac{L}{d_L}\times\frac{W}{d_W}\times
\left(\frac{H}{d_H}+3\right)
$$

첫 식의 `+1`은 reflectance, 둘째 식의 `+3`은 reflectance 1개와 out-of-range occupancy 2개입니다. 슬라이드의 occupancy-only 설명은 핵심 아이디어를 단순화한 것이며, 두 판본의 실제 입력을 완전히 기술하지는 않습니다.

### 7.3 Pixel-wise oriented box 출력

슬라이드 36쪽의 backbone은 2D residual blocks와 top-down upsampling을 결합해 고해상도와 넓은 문맥을 함께 사용합니다. 각 BEV output pixel은 object confidence와 oriented box regression을 예측합니다. 먼저 **복호화된 box geometry**는 다음 여섯 값으로 나타낼 수 있습니다.

$$
(\cos\theta,\sin\theta,d_x,d_y,w,l)
$$

$$d_x,d_y,w,l$$은 metric ground plane의 위치 offset과 크기이므로 meter, $$\cos\theta,\sin\theta$$는 무차원입니다. 이 tuple은 물리 geometry이지 network가 그대로 회귀하는 standardized training target과 같지 않습니다.

CVPR 2018 PDF의 Figure 3 caption은 $$\log d_x,\log d_y$$까지 포함한 표기를 제시하지만, signed offset은 음수가 될 수 있어 일반적인 실수 log가 정의되지 않습니다. 해당 판본은 음수 offset을 어떻게 처리했는지 명시하지 않으므로 구현 규약을 추측하지 않습니다. 2019 확장 저자 판본은 signed $$d_x,d_y$$를 log 없이 두고, 양수인 크기만 log로 바꾸어 이 모호성을 해소합니다. 단위를 가진 값에 log를 직접 쓰지 않도록 기준 길이 $$w_0,l_0$$를 두면 raw target을 다음처럼 쓸 수 있습니다.

$$
\mathbf{q}=
\left(\cos\theta,\sin\theta,d_x,d_y,
\log\frac{w}{w_0},\log\frac{l}{l_0}\right)
$$

$$w_0,l_0$$는 고정된 양의 reference length입니다. 크기 비와 삼각함수 성분은 무차원이며, $$d_x,d_y$$는 meter입니다. 각 target component는 training set 평균 $$\mu_j$$와 표준편차 $$\sigma_j$$로 표준화됩니다.

$$
\hat{q}_j=\frac{q_j-\mu_j}{\sigma_j}
\qquad\Longrightarrow\qquad
q_j=\sigma_j\hat{q}_j+\mu_j
$$

추론에서는 de-normalization 뒤 BEV cell 중심의 **metric 좌표**에 signed offset을 더하고, size는 exponential로 복원합니다. 여기서 $$p_x,p_y$$는 image pixel index가 아닙니다. Output grid index가 $$(i,j)$$, 유효 cell 간격이 $$r_x,r_y$$ meter, grid 원점이 $$(x_{\min},y_{\min})$$ meter이면 다음과 같이 길이 좌표로 변환합니다. Network output stride가 있다면 $$r_x,r_y$$에 그 stride를 포함합니다.

$$
p_x=x_{\min}+(i+\tfrac12)r_x,\qquad
p_y=y_{\min}+(j+\tfrac12)r_y
$$

이 좌표와 offset은 모두 meter 단위이므로 다음 덧셈이 가능합니다.

$$
x_c=p_x+d_x,\qquad y_c=p_y+d_y,
\qquad w=w_0\exp(q_w),\qquad l=l_0\exp(q_l)
$$

여기서 $$q_w=\log(w/w_0)$$, $$q_l=\log(l/l_0)$$입니다. 각도는 다음 정확한 항등식으로 복원합니다.

$$
\hat{\theta}=\operatorname{atan2}(\widehat{\sin\theta},\widehat{\cos\theta})
$$

결과는 radian입니다. Sin과 cos을 함께 예측하면 $$-\pi$$와 $$\pi$$가 같은 방향이라는 angle wrap-around를 scalar direct regression보다 자연스럽게 처리할 수 있습니다. 후보 proposal을 먼저 만들지 않고 모든 output pixel에서 dense prediction을 하므로 proposal-free one-stage detector입니다. Confidence threshold 뒤에는 겹치는 oriented box를 줄이기 위해 NMS를 적용합니다.

### 7.4 “Real-time” 수치는 판본과 구현 조건을 함께 읽기

슬라이드 37쪽의 `> 28 fps`는 출처 없는 오류가 아니라 [2019 확장 저자 판본](https://arxiv.org/html/1902.06326v1){:target="_blank" rel="noopener"}의 갱신된 구현 결과와 일치합니다. 이 판본의 KITTI timing table은 digitization 1 ms, network 31 ms, NMS 3 ms로 합계 35 ms를 보고합니다.

$$
1\ \mathrm{ms}+31\ \mathrm{ms}+3\ \mathrm{ms}
=35\ \mathrm{ms},
\qquad
\frac{1000\ \mathrm{ms/s}}{35\ \mathrm{ms/frame}}
\approx28.6\ \mathrm{frame/s}
$$

모든 계산은 GPU에서 수행했고, network time은 NVIDIA Titan Xp에서 KITTI의 비연속 100 frame 평균입니다. 그래서 이 조건에서는 `> 28 FPS`가 계산과 일치합니다.

반면 CVPR 2018 판본의 KITTI table은 digitization 17 ms, network 66 ms, NMS 10 ms로 합계 **93 ms**, 약 **10.8 FPS**를 보고합니다. 그 판본은 input representation과 NMS를 CPU Python으로 처리하고 network만 Titan Xp GPU에서 측정했습니다. 같은 PIXOR 이름이라도 구현 위치와 판본이 바뀌어 end-to-end latency가 달라진 사례입니다. 따라서 28 FPS는 2019 GPU pipeline의 검증된 값이지만 현재 hardware·다른 입력 범위·다른 구현에 자동으로 적용되는 보편 속도는 아닙니다.

## 8. 세 파이프라인을 한 장면에 적용하면

같은 LiDAR frame에 차량 하나가 있다고 가정하면 계산 경로는 다음처럼 달라집니다.

| 단계 | PointRCNN | VoxelNet | PIXOR |
|---|---|---|---|
| 입력 조직화 | Raw points 유지 | 3D voxel로 partition | 3D occupancy를 BEV channel로 접음 |
| 국소 feature | PointNet++ neighborhood | Voxel 내부 VFE, voxel 간 3D conv | BEV 2D conv |
| 후보 생성 | Foreground point에서 bottom-up proposal | Dense anchor 기반 detection head | Proposal-free pixel-wise prediction |
| 위치 정제 | Proposal별 canonical coordinate에서 stage 2 | 같은 one-stage head의 regression | BEV pixel offset·size·angle regression |
| 주요 가정 | Point-wise segmentation이 좋은 후보를 제공 | Grid resolution이 구조와 계산량을 균형 있게 표현 | Ground plane과 BEV가 vehicle geometry에 적절 |
| 주요 비용 | Proposal pooling과 refinement의 순차 단계 | 3D grid 및 3D convolution | 높은 BEV 해상도의 dense 2D prediction |

이 표는 어느 모델이 항상 더 좋다는 순위를 제시하지 않습니다. Point density, detection range, object class, hardware, sparse operator, training recipe가 바뀌면 정확도와 latency도 달라집니다. 강의의 비교는 각 방법이 계산 가능한 표현을 만들기 위해 선택한 **정보 보존과 구조화 방식**에 초점을 둡니다.

## Source Check

<details markdown="block">
<summary markdown="span">Source notes: assumptions and corrections</summary>

| 위치 | 판정 | 확인과 이 글의 처리 |
|---|---|---|
| 10쪽 `rotation invariant` | 가정이 생략된 목표 표현 | 순열 불변성은 symmetric max로 구조적으로 확보합니다. T-Net의 $$\lVert I-AA^{\top}\rVert_F^2$$는 행들의 orthonormality를 유도하지만 모든 회전에 대한 엄밀한 불변성 증명은 아닙니다. |
| 12–13쪽 PointNet의 local structure | 표현상 단순화 | PointNet이 국소 정보를 전혀 사용할 수 없다는 뜻이 아니라 metric neighborhood의 계층을 명시적으로 만들지 않는다는 한계로 설명했습니다. |
| 18쪽 box 안 점은 foreground | 데이터셋·annotation 가정 | 일반 장면에서 3D box가 절대 겹치지 않는다는 법칙은 아닙니다. 학습 label 생성 규칙으로 한정했습니다. |
| 19쪽 center $$(x,y,z)$$ regression | 원문 알고리즘 누락 | PointRCNN 원 논문은 $$x,z$$에 bin classification+residual, vertical $$y$$에 direct smooth L1을 사용합니다. |
| 25쪽 `0.2 × 0.2 × 0.4 m` | 축 순서 생략 | VoxelNet KITTI car 설정은 vertical $$v_D=0.4$$ m, 두 ground-plane 축 $$v_H=v_W=0.2$$ m입니다. |
| 31쪽 VoxelNet `RPN` | 명칭상 혼동 가능 | Head 이름은 RPN이지만 별도 second-stage refinement가 없는 원 논문의 one-stage detection 구조로 설명했습니다. |
| 32쪽 3D convolution은 느림 | 정성적 조건부 주장 | 원 설계의 비용 원인으로는 타당하지만 sparse implementation, resolution, range, hardware 없이 보편적 속도 순위를 만들지 않았습니다. |
| 34쪽 BEV box는 서로 겹치지 않음 | 원문·슬라이드의 과도한 일반화 | Front-view보다 occlusion이 줄 수 있으나 BEV box overlap은 가능하며 PIXOR도 oriented NMS를 사용합니다. |
| 35쪽 occupancy input | 원문 구성·판본 차이 | CVPR 2018은 height slice 35개+reflectance 1개로 36 channel, 2019 확장판은 out-of-range occupancy 2개를 더해 38 channel입니다. |
| PIXOR geometry target | 판본 간 표기 정정 | CVPR 2018 caption의 $$\log d_x,\log d_y$$는 signed offset에 일반적으로 정의되지 않고 별도 규약도 명시하지 않습니다. 2019 확장판의 signed $$d_x,d_y$$와 log-size target을 기준으로 설명했습니다. |
| 37쪽 `> 28 fps` | 후속 판본에서 확인 | CVPR 2018 CPU digitization/NMS 판본은 93 ms, 2019 확장 GPU pipeline은 1+31+3=35 ms, 약 28.6 FPS입니다. 슬라이드는 후속 저자 판본과 일치합니다. |

</details>

## 강의 전체 페이지 대응

<details markdown="block">
<summary markdown="span">Reference: topics by slide</summary>

| 페이지 | 성격 | 본문 반영 |
|---:|---|---|
| 1 | 강의 표지 | 강의명·교수·과목 출처를 도입부에 반영 |
| 2–3 | 공지·과제 마감 | 행정 페이지로 확인했으며 교육 본문에서 제외 |
| 4–5 | 지난 시간 복습 | 3D object detection과 image-based 접근의 이전 강의 경계로만 반영 |
| 6–8 | 목차·section divider | LiDAR data/backbone과 LiDAR detector의 두 축을 전체 흐름에 반영 |
| 9–10 | Point cloud와 학습 난점 | 1절의 set 정의, 가변 크기, 순열, 회전 구분 |
| 11–13 | PointNet·PointNet++ | 2–3절의 shared MLP, max pooling, T-Net, hierarchical neighborhood |
| 14–15 | LiDAR detector 도입 | 4절의 세 모델 비교 |
| 16–23 | PointRCNN | 5절의 foreground, bin-based box, canonical refinement, two-stage 비용 |
| 24–32 | VoxelNet | 6절의 voxelization, sampling, VFE, sparse tensor, 3D conv, RPN |
| 33–37 | PIXOR | 7절의 BEV input, dense output, speed 조건과 source correction |
| 38–39 | Summary | 마지막 핵심 정리에 두 주제를 재통합 |
| 40 | Next lecture | Multimodal image+LiDAR와 perception dataset은 다음 강의 범위로 구분 |
| 41 | Questions | 별도 새 개념이 없는 종료 페이지로 확인 |

</details>

## 복습 포인트

- Point cloud가 matrix로 저장되어도 set으로 처리해야 하는 이유와 순열 불변성 식을 설명합니다.
- PointNet의 shared MLP, coordinate-wise max pooling, global/local feature 결합을 직접 그립니다.
- T-Net의 학습 정렬과 엄밀한 rotation invariance를 구분합니다.
- PointNet++ set abstraction의 sampling, grouping, local PointNet 순서를 설명합니다.
- PointRCNN stage 1의 foreground segmentation과 stage 2의 canonical refinement가 각각 필요한 이유를 말합니다.
- PointRCNN에서 $$x,z,\theta$$는 bin+residual, $$y,h,w,l$$은 direct residual이라는 원 논문 구분을 기억합니다.
- VoxelNet의 7차원 point feature, voxel-wise max, sparse $$C\times D'\times H'\times W'$$ tensor를 연결합니다.
- PIXOR의 CVPR 2018 36-channel 입력과 2019 확장판 38-channel 입력, decoded geometry와 standardized training target을 구분합니다.
- Latency나 FPS를 비교할 때 input range, resolution, hardware, preprocessing, NMS 포함 여부를 함께 확인합니다.

## 마지막 핵심 정리

Point cloud detector의 설계는 **불규칙한 점을 언제, 어떻게 규칙화하는가**로 읽을 수 있습니다. PointRCNN은 raw point를 오래 유지한 채 foreground proposal을 canonical coordinate에서 정제합니다. VoxelNet은 일찍 3D voxel로 묶되 VFE로 cell 내부 feature를 학습하고, PIXOR는 높이를 channel로 접어 metric BEV에서 2D dense prediction을 수행합니다.

표현을 더 규칙적으로 만들수록 기존 convolution을 효율적으로 쓰기 쉬워지지만 discretization과 가정이 추가됩니다. 반대로 raw point를 유지하면 기하를 세밀하게 보존할 수 있지만 neighborhood 구성과 proposal refinement 비용이 생깁니다. **PointNet의 대칭 집계, PointNet++의 계층적 이웃, PointRCNN의 두 단계, VoxelNet의 VFE, PIXOR의 BEV channelization**이 이 trade-off를 구현하는 핵심 장치입니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

먼저 9–13쪽에서 데이터 표현만 따라갑니다. Point cloud를 set으로 쓰고, 순열을 바꿔도 coordinate-wise max가 그대로인지 작은 숫자로 확인한 다음 PointNet++가 centroid와 이웃을 어떻게 추가하는지 그립니다.

그 다음 16–23쪽에서 PointRCNN을 두 색으로 나누어 그립니다. Stage 1에는 `point-wise feature → foreground mask + bin-based proposal`, stage 2에는 `proposal pooling → canonical transform → refinement + confidence`를 적습니다. 이때 슬라이드 19쪽의 축별 회귀 요약은 Source Check의 원 논문 구분과 함께 봅니다.

마지막으로 24–37쪽에서 같은 point cloud가 VoxelNet과 PIXOR에서 어떤 tensor가 되는지 shape를 적습니다. VoxelNet은 $$C\times D'\times H'\times W'$$입니다. PIXOR는 height occupancy와 reflectance를 channel로 갖는 2D grid이며 CVPR 2018의 36 channel과 2019 확장판의 38 channel을 분리해서 봅니다. 속도도 CVPR 2018의 CPU 전후 처리 93 ms와 2019 GPU pipeline의 35 ms를 구현 판본과 함께 비교합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. PointNet의 max pooling은 왜 point 순서에 불변입니까?</summary>

답변: Max pooling은 각 feature 차원에서 값의 집합만 보고 최댓값을 고릅니다. 입력 point의 행 순서를 바꾸어도 값의 집합은 같으므로 결과도 같습니다. 다만 회전하면 point 좌표와 MLP 출력 값 자체가 달라질 수 있으므로 순열 불변성이 곧 회전 불변성은 아닙니다.

</details>

<details markdown="block">
<summary>2. PointNet++가 PointNet의 local structure 한계를 어떻게 보완합니까?</summary>

답변: Centroid를 sampling하고, 거리 기반으로 주변 point를 grouping한 뒤, 각 local region에 작은 PointNet을 적용합니다. 이 set abstraction을 반복하면 작은 이웃에서 큰 문맥으로 feature 범위가 계층적으로 넓어집니다.

</details>

<details markdown="block">
<summary markdown="span">3. PointRCNN에서 $$x,z$$와 $$y$$의 center 회귀 방식은 어떻게 다릅니까?</summary>

답변: 원 논문 좌표계에서 ground plane의 $$x,z$$는 search range를 bin으로 나누어 bin classification과 within-bin residual regression을 결합합니다. Vertical coordinate $$y$$는 범위가 작다는 가정 아래 smooth L1로 직접 회귀합니다. 슬라이드의 $$(x,y,z)$$ 일괄 regression 설명은 이 차이를 생략한 요약입니다.

</details>

<details markdown="block">
<summary>4. PointRCNN의 canonical transformation이 refinement에 왜 유리합니까?</summary>

답변: Proposal 중심을 원점으로 옮기고 proposal yaw를 제거하면 서로 다른 전역 위치와 방향의 후보가 비슷한 local coordinate로 정렬됩니다. Refinement network는 절대 위치보다 proposal 내부의 residual geometry에 집중할 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">5. VoxelNet의 한 point가 VFE에 들어갈 때 왜 좌표가 7차원입니까?</summary>

답변: 원래의 위치와 reflectance $$(x,y,z,r)$$에 voxel centroid로부터의 offset $$(x-\bar{x},y-\bar{y},z-\bar{z})$$를 붙이기 때문입니다. 절대 위치와 voxel 내부의 상대 위치를 함께 제공합니다.

</details>

<details markdown="block">
<summary>6. VoxelNet의 RPN이라는 이름만 보고 two-stage라고 판단하면 왜 틀립니까?</summary>

답변: VoxelNet에서는 그 RPN head가 classification과 box regression을 내어 최종 detection을 구성합니다. PointRCNN처럼 proposal을 별도 network가 pooling하고 다시 정제하는 두 번째 stage가 없으므로 전체는 one-stage 구조입니다.

</details>

<details markdown="block">
<summary>7. PIXOR에서 높이 축을 channel로 옮기는 장점과 한계는 무엇입니까?</summary>

답변: Ground plane 두 축에서만 2D convolution을 이동하므로 3D convolution보다 계산 구조가 단순하고, metric BEV에서 물체의 평면 크기를 유지합니다. 반면 height를 독립적인 공간축으로 convolution하지 않으며, 원 PIXOR의 box 출력은 공통 ground plane 가정에 의존합니다.

</details>

<details markdown="block">
<summary>8. PIXOR의 93 ms와 35 ms가 모두 원 논문 계열의 수치인 이유는 무엇입니까?</summary>

답변: CVPR 2018 판본은 digitization과 NMS를 CPU Python에서 처리해 17+66+10=93 ms를 보고했습니다. 2019 확장 저자 판본은 모든 계산을 GPU로 옮긴 구현에서 1+31+3=35 ms, 약 28.6 FPS를 보고했습니다. 슬라이드의 `> 28 FPS`는 후속 판본과 일치하지만, 판본·hardware·처리 위치가 다른 환경의 보편 속도는 아닙니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-10-3d-perception-02.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 10 source slides (PDF)</a></li>
</ul>

## References

- <a href="https://arxiv.org/abs/1612.00593" target="_blank" rel="noopener">Qi et al., PointNet: Deep Learning on Point Sets for 3D Classification and Segmentation</a> — symmetric max aggregation, T-Net, feature-transform regularization.
- <a href="https://arxiv.org/abs/1706.02413" target="_blank" rel="noopener">Qi et al., PointNet++: Deep Hierarchical Feature Learning on Point Sets in a Metric Space</a> — sampling, grouping, local PointNet 기반 set abstraction.
- <a href="https://arxiv.org/abs/1812.04244" target="_blank" rel="noopener">Shi, Wang, and Li, PointRCNN: 3D Object Proposal Generation and Detection from Point Cloud</a> — foreground segmentation, axis-specific bin-based localization, canonical refinement.
- <a href="https://arxiv.org/abs/1711.06396" target="_blank" rel="noopener">Zhou and Tuzel, VoxelNet: End-to-End Learning for Point Cloud Based 3D Object Detection</a> — voxel partition, VFE, sparse tensor, convolutional middle layers and RPN.
- <a href="https://openaccess.thecvf.com/content_cvpr_2018/html/Yang_PIXOR_Real-Time_3D_CVPR_2018_paper.html" target="_blank" rel="noopener">Yang, Luo, and Urtasun, PIXOR: Real-Time 3D Object Detection From Point Clouds (CVPR 2018)</a> — 36-channel input, oriented dense output, CPU digitization/NMS를 포함한 93 ms 구현.
- <a href="https://arxiv.org/html/1902.06326v1" target="_blank" rel="noopener">Yang, Luo, and Urtasun, PIXOR extended author version (2019)</a> — out-of-range channel과 signed-offset target 명료화, all-GPU 35 ms timing.
