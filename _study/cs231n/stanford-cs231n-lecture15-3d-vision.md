---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 15: 3D Vision"
course: "CS231N"
topic: "3D Vision"
order: 15
major_topic: "Computer Vision"
keywords:
  - "3D Vision"
  - "Depth Estimation"
  - "Point Clouds"
  - "NeRF"
  - "Geometry"
---

# Stanford CS231N Lecture 15: 3D Vision

Source: [Stanford CS231N Spring 2025 Lecture 15](https://www.youtube.com/watch?v=7lxrKDKtykM){:target="_blank" rel="noopener"}
Slides: [Official Stanford CS231N 2025 Lecture 15 PDF](https://cs231n.stanford.edu/slides/2025/lecture_15.pdf){:target="_blank" rel="noopener"}

> **핵심:** 3D vision에는 pixel처럼 유일한 표준 표현이 없다. Point cloud, mesh, voxel, implicit field는 각각 저장, topology, differentiability, rendering 비용이 다르며, **표현 선택이 곧 가능한 network와 loss를 결정한다.**

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Explicit geometry | Point cloud와 mesh는 무엇을 직접 저장하는가? |
| 2 | Grids and learning | Voxel은 왜 쉽지만 비효율적인가? |
| 3 | PointNet and set distances | PointNet/PointNet++와 Chamfer/Earth Mover distance는 어떤 문제를 푸는가? |
| 4 | Implicit functions | 공간 좌표 query로 표면을 어떻게 표현하는가? |
| 5 | Neural rendering | NeRF와 Gaussian splatting은 2D supervision을 어떻게 쓰는가? |

## 1. Point cloud와 polygon mesh

Point cloud는 3D 좌표와 선택적으로 color·normal을 가진 점의 집합이다. Scanner에서 직접 얻기 쉽고 단순하지만 점 사이 연결과 표면이 명시되지 않아 매끄러운 rendering과 editing이 어렵다. 순서가 없는 집합이므로 network도 입력 permutation에 대해 같은 결과를 내야 한다.

Mesh는 vertex와 edge, face로 표면 topology를 표현한다. Graphics pipeline에서 rendering과 변형을 지원하지만, 같은 형태도 서로 다른 수의 vertex와 연결 구조로 표현될 수 있다. 매우 상세한 표면은 mesh가 커지고, 불규칙하거나 깨진 topology는 학습을 어렵게 한다.

## 2. Voxel: 3D pixel의 편리함과 비용

Voxel grid는 3D 공간을 규칙적인 격자로 나누고 occupancy나 feature를 저장한다. 이미지 CNN의 2D convolution을 3D convolution으로 확장할 수 있어 초기 3D deep learning에서 자연스러운 선택이었다. ShapeNet 같은 대규모 CAD dataset은 shape classification·completion·generation 연구를 뒷받침했다.

그러나 해상도 $$R$$을 두 배로 올리면 cell 수는 $$R^3$$에 비례해 여덟 배가 된다. 물체 표면 주변만 중요해도 빈 공간 전체를 저장·계산한다. Octree는 균일한 빈 영역을 큰 cell로 묶고 복잡한 영역만 세분화해 이 낭비를 줄인다.

## 3. Point set을 직접 처리하고 비교하기

**PointNet**은 각 점에 같은 함수(shared MLP)를 적용하고 symmetric max pooling으로 global feature를 만든다. Max 같은 symmetric 연산은 입력 순서가 바뀌어도 결과가 같아 permutation invariance를 제공한다. 강의는 이 단순한 구조가 강력한 출발점이었다고 강조한다. **PointNet++**는 local neighborhood를 계층적으로 묶어 가까운 점의 기하 관계와 여러 공간 scale을 포착하고, graph neural network는 점을 node, 근접 관계를 edge로 바꾸는 후속 방향이다.

생성된 point cloud와 정답은 점 순서가 대응하지 않는다. 따라서 index별 $$L_2$$ loss 대신 set distance가 필요하다. **Chamfer distance**는 각 점에서 상대 집합의 nearest neighbor까지 거리를 양방향 합산한다. **Earth Mover distance**는 두 집합 사이의 one-to-one bipartite matching을 찾아 모든 matched pair의 이동 거리를 최소화한다. Earth Mover는 전역 대응을 강제해 더 구조적인 비교가 가능하지만 matching 계산이 더 비싸다. 이는 representation이 loss 설계까지 바꾼다는 예다.

## 4. Deep implicit function

Implicit representation은 좌표 $$\mathbf{x}=(x,y,z)$$를 network에 넣고 occupancy, signed distance, density 같은 값을 query한다. 예를 들어 surface를 signed distance field $$f_\theta(\mathbf{x})=0$$의 level set으로 나타낼 수 있다. Grid resolution에 고정되지 않고 좌표를 연속적으로 질의할 수 있지만 surface를 보려면 많은 query와 iso-surface extraction이 필요하다.

이 관점은 하나의 network parameter가 한 shape를 표현하는 경우와, latent code를 함께 입력해 여러 shape를 표현하는 경우로 확장된다. 좌표 기반 MLP는 복잡한 topology도 고정 mesh connectivity 없이 표현한다.

## 5. NeRF와 differentiable volume rendering

NeRF는 위치와 viewing direction을 입력해 density $$\sigma$$와 radiance $$\mathbf{c}$$를 예측한다. Camera ray $$\mathbf{r}(t)=\mathbf{o}+t\mathbf{d}$$ 위 여러 지점을 query하고 volume-rendering equation으로 pixel color를 합성한다. Rendering이 differentiable하므로 여러 시점의 2D image와 camera pose만으로 field parameter를 학습할 수 있다.

Implicit field는 고품질 novel-view synthesis를 제공하지만 ray마다 많은 network query가 필요해 느리다. 3D Gaussian splatting은 위치·크기·방향·opacity·color를 가진 explicit Gaussian primitive를 최적화하고 rasterization해 rendering을 가속한다. 강의는 NeRF와 비슷한 시각 품질을 훨씬 빠른 rendering으로 얻는 최근 흐름으로 이를 소개한다.

## 핵심 수식 유도

### 작성자 보충: Chamfer distance와 Earth Mover distance

두 point set을 $$X=\{x_i\}_{i=1}^{n}$$, $$Y=\{y_j\}_{j=1}^{m}$$라 하자. Squared Euclidean distance와 합을 사용하는 symmetric Chamfer distance convention은

$$
d_{\mathrm{CD}}(X,Y)
=\sum_{i=1}^{n}\min_{1\le j\le m}\lVert x_i-y_j\rVert_2^2
+\sum_{j=1}^{m}\min_{1\le i\le n}\lVert y_j-x_i\rVert_2^2
$$

이다. 두 방향을 모두 더하지만 nearest neighbor를 각각 독립적으로 고르므로 일대일 대응은 강제하지 않는다. 논문과 구현에 따라 각 합을 $$n,m$$으로 나눈 mean convention이나 제곱하지 않은 norm을 쓰므로 값을 비교할 때 정의를 확인해야 한다. 위 식은 선택한 convention의 **정확한 정의**다.

Equal-cardinality set $$n=m$$에서 discrete Earth Mover distance의 bijection convention은 permutation 집합 $$S_n$$에 대해

$$
d_{\mathrm{EMD}}(X,Y)
=\min_{\pi\in S_n}
\sum_{i=1}^{n}\lVert x_i-y_{\pi(i)}\rVert_2
$$

이다. 각 source point를 서로 다른 target point에 대응시키는 minimum-cost bipartite matching의 **정확한 정의**이며, 평균 convention은 앞에 $$1/n$$을 붙인다. Cardinality가 다르거나 point mass가 균등하지 않으면 이 bijection 식이 아니라 mass를 명시한 optimal transport 또는 dummy point가 필요하다.

좌표가 length 단위이면 unsquared EMD는 length, 위 squared Chamfer는 length squared 단위를 가지며, mean을 사용해도 단위는 변하지 않는다. Unsquared Chamfer나 squared EMD를 택하면 그에 맞춰 단위도 바뀐다. Chamfer는 many-to-one match 때문에 point density와 coverage 차이를 놓칠 수 있고 squared norm은 outlier에 민감하다. EMD는 global matching을 주지만 exact assignment의 계산·메모리 비용이 커 대규모 cloud에서는 근사 solver를 자주 쓴다. 두 loss 모두 nearest neighbor나 optimal assignment가 바뀌는 경계에서는 미분 가능하지 않을 수 있다.

### 작성자 보충: pinhole projection

Pinhole camera에서 3D point $$(X,Y,Z)$$와 focal length $$f$$에 대해 닮은꼴 삼각형으로 $$x=fX/Z$$, $$y=fY/Z$$를 얻는다. 이는 $$Z\ne0$$인 ideal camera의 **정확한 투영식**이다. $$X,Y,Z,f,x,y$$는 같은 길이 단위로 둘 수 있다. $$Z\to0$$에서 불안정하고 lens distortion·occlusion을 포함하지 않는다.

### 작성자 보충: NeRF alpha compositing의 유도

Ray를 $$t_1<\cdots<t_N$$에서 sampling하고 구간 길이를 $$\Delta_i=t_{i+1}-t_i$$, 해당 구간의 density와 color를 $$\sigma_i,\mathbf{c}_i$$라 하자. 구간 안에서 density가 일정하다는 piecewise-constant 근사와 Beer-Lambert law를 쓰면 그 구간을 통과할 확률은 $$e^{-\sigma_i\Delta_i}$$, 흡수될 확률은

$$
\alpha_i=1-e^{-\sigma_i\Delta_i}
$$

다. 앞선 모든 구간을 통과해 $$i$$번째 구간에 도달할 transmittance는

$$
T_i=\exp\left(-\sum_{j<i}\sigma_j\Delta_j\right)
$$

이므로, $$i$$번째 color가 pixel에 기여할 weight는 “먼저 도달하고 그 구간에서 흡수될 확률”인 $$w_i=T_i\alpha_i$$다. 따라서 배경 color까지 포함한 discrete rendering은

$$
\widehat{\mathbf{C}}(\mathbf{r})
=\sum_{i=1}^{N}T_i\alpha_i\mathbf{c}_i
+T_{N+1}\mathbf{c}_{\mathrm{bg}}.
$$

Sample 간격이 작아지는 극한에서는 $$T(t)=\exp(-\int_{t_n}^{t}\sigma(s)ds)$$와 $$\int T(t)\sigma(t)\mathbf{c}(t)dt$$인 continuous volume-rendering equation으로 이어진다. $$\sigma$$의 단위는 길이의 역수, $$\Delta_i$$는 길이이므로 exponent, $$T_i$$, $$\alpha_i$$, $$w_i$$는 무차원이고 합성 color는 $$\mathbf{c}_i$$와 같은 단위를 가진다. 이 식은 구간별 독립 흡수·방출과 선택한 sampling quadrature에 의존하는 **수치 근사**이므로 step이 너무 크면 얇은 geometry나 급격한 density 변화를 놓친다.

## 마지막 핵심 정리

- Point cloud는 단순하고 raw sensor와 가깝지만 surface topology가 없다.
- PointNet은 shared point function과 symmetric pooling으로 순서 불변성을 만들고, PointNet++는 local geometry를 계층화한다.
- Chamfer distance는 nearest-neighbor 집합 거리이고, Earth Mover distance는 one-to-one matching 비용이다.
- Mesh는 표면 연산에 강하고, voxel은 CNN 적용이 쉽지만 cubic memory cost가 크다.
- Implicit field는 연속 좌표 query로 해상도 고정을 피한다.
- NeRF는 differentiable rendering으로 2D image를 3D supervision으로 바꾸고, Gaussian splatting은 explicit primitive로 rendering을 빠르게 한다.

## Study Guide

각 representation을 `저장 단위`, `규칙성`, `surface 명시 여부`, `rendering`, `대표 network/loss`로 비교한다. NeRF는 camera ray에서 sample, density·color query, alpha composition, pixel loss로 이어지는 계산 흐름을 설명할 수 있어야 한다.

## 복습 질문

<details markdown="block"><summary>1. Voxel resolution을 높이기 어려운 이유는?</summary>

답변: 축마다 resolution이 늘어나므로 총 cell 수와 3D convolution 비용이 $$O(R^3)$$로 증가하고, 대부분의 빈 공간에도 자원을 쓰기 때문이다.
</details>

<details markdown="block"><summary>2. Point cloud loss가 index별 오차를 쓰기 어려운 이유는?</summary>

답변: Point set에는 고정된 순서나 일대일 대응이 없기 때문이다. 최근접 이웃 기반 Chamfer distance처럼 permutation에 무관한 비교가 필요하다.
</details>

<details markdown="block"><summary>3. NeRF가 2D image만으로 3D field를 학습할 수 있는 이유는?</summary>

답변: Camera ray의 density와 radiance를 pixel color로 합성하는 volume-rendering 과정이 differentiable해, rendered pixel 오차가 field network까지 역전파되기 때문이다.
</details>

## 원문 대조 기록

공식 PDF **105쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 1–44쪽 · 영상 00:02:47 | explicit/implicit geometry, point cloud, mesh, voxel | 1–4절 |
| PDF 45–76쪽 · 영상 00:46:23, 00:50:22, 00:50:51 | multi-view CNN, PointNet, symmetric function, point-set distance | 3절 및 작성자 보충 |
| PDF 77–88쪽 · 영상 00:59:08, 01:00:08 | deep implicit field, NeRF, volume rendering | 4–5절 및 작성자 보충 |
| PDF 89–105쪽 | Gaussian splatting과 structure-aware representation | 표현 계보 대조; 비수식 사례는 추가하지 않음 |

3D representation과 neural architecture 비교는 강의 원문 요약이다. Chamfer/EMD 정의, pinhole projection, NeRF alpha compositing 유도는 **작성자 보충**이다.

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=7lxrKDKtykM){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 15 PDF](https://cs231n.stanford.edu/slides/2025/lecture_15.pdf){:target="_blank" rel="noopener"}
