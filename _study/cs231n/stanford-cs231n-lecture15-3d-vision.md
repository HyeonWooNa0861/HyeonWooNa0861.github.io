---
layout: default
date: 2026-07-16 16:07:00 +0900
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

그러나 해상도 \(R\)을 두 배로 올리면 cell 수는 \(R^3\)에 비례해 여덟 배가 된다. 물체 표면 주변만 중요해도 빈 공간 전체를 저장·계산한다. Octree는 균일한 빈 영역을 큰 cell로 묶고 복잡한 영역만 세분화해 이 낭비를 줄인다.

## 3. Point set을 직접 처리하고 비교하기

**PointNet**은 각 점에 같은 함수(shared MLP)를 적용하고 symmetric max pooling으로 global feature를 만든다. Max 같은 symmetric 연산은 입력 순서가 바뀌어도 결과가 같아 permutation invariance를 제공한다. 강의는 이 단순한 구조가 강력한 출발점이었다고 강조한다. **PointNet++**는 local neighborhood를 계층적으로 묶어 가까운 점의 기하 관계와 여러 공간 scale을 포착하고, graph neural network는 점을 node, 근접 관계를 edge로 바꾸는 후속 방향이다.

생성된 point cloud와 정답은 점 순서가 대응하지 않는다. 따라서 index별 \(L_2\) loss 대신 set distance가 필요하다. **Chamfer distance**는 각 점에서 상대 집합의 nearest neighbor까지 거리를 양방향 합산한다. **Earth Mover distance**는 두 집합 사이의 one-to-one bipartite matching을 찾아 모든 matched pair의 이동 거리를 최소화한다. Earth Mover는 전역 대응을 강제해 더 구조적인 비교가 가능하지만 matching 계산이 더 비싸다. 이는 representation이 loss 설계까지 바꾼다는 예다.

## 4. Deep implicit function

Implicit representation은 좌표 \(\mathbf{x}=(x,y,z)\)를 network에 넣고 occupancy, signed distance, density 같은 값을 query한다. 예를 들어 surface를 signed distance field \(f_\theta(\mathbf{x})=0\)의 level set으로 나타낼 수 있다. Grid resolution에 고정되지 않고 좌표를 연속적으로 질의할 수 있지만 surface를 보려면 많은 query와 iso-surface extraction이 필요하다.

이 관점은 하나의 network parameter가 한 shape를 표현하는 경우와, latent code를 함께 입력해 여러 shape를 표현하는 경우로 확장된다. 좌표 기반 MLP는 복잡한 topology도 고정 mesh connectivity 없이 표현한다.

## 5. NeRF와 differentiable volume rendering

NeRF는 위치와 viewing direction을 입력해 density \(\sigma\)와 radiance \(\mathbf{c}\)를 예측한다. Camera ray \(\mathbf{r}(t)=\mathbf{o}+t\mathbf{d}\) 위 여러 지점을 query하고 volume-rendering equation으로 pixel color를 합성한다. Rendering이 differentiable하므로 여러 시점의 2D image와 camera pose만으로 field parameter를 학습할 수 있다.

Implicit field는 고품질 novel-view synthesis를 제공하지만 ray마다 많은 network query가 필요해 느리다. 3D Gaussian splatting은 위치·크기·방향·opacity·color를 가진 explicit Gaussian primitive를 최적화하고 rasterization해 rendering을 가속한다. 강의는 NeRF와 비슷한 시각 품질을 훨씬 빠른 rendering으로 얻는 최근 흐름으로 이를 소개한다.

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

<details><summary>1. Voxel resolution을 높이기 어려운 이유는?</summary>

답변: 축마다 resolution이 늘어나므로 총 cell 수와 3D convolution 비용이 \(O(R^3)\)로 증가하고, 대부분의 빈 공간에도 자원을 쓰기 때문이다.
</details>

<details><summary>2. Point cloud loss가 index별 오차를 쓰기 어려운 이유는?</summary>

답변: Point set에는 고정된 순서나 일대일 대응이 없기 때문이다. 최근접 이웃 기반 Chamfer distance처럼 permutation에 무관한 비교가 필요하다.
</details>

<details><summary>3. NeRF가 2D image만으로 3D field를 학습할 수 있는 이유는?</summary>

답변: Camera ray의 density와 radiance를 pixel color로 합성하는 volume-rendering 과정이 differentiable해, rendered pixel 오차가 field network까지 역전파되기 때문이다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=7lxrKDKtykM){:target="_blank" rel="noopener"}
