---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Lecture 8: Semantic and Instance Segmentation"
course: "Autonomous Driving"
topic: "Dense Pixel Labels, Transposed Convolution, and Mask R-CNN"
order: 8
major_topic: "Autonomous Systems"
keywords:
  - "Semantic Segmentation"
  - "Instance Segmentation"
  - "Fully Convolutional Network"
  - "Transposed Convolution"
  - "Mask R-CNN"
---

# Lecture 8: Semantic and Instance Segmentation

Source PDF: [8 Perception (6).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf" | relative_url }})

국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 8강을 바탕으로 한 학습 노트다. 7강의 single-stage object detection을 복습한 뒤, 픽셀별 class와 개체별 mask가 어떻게 다른지 학습한다. 슬라이드의 convolution 그림과 수치 예제를 재구성했으며, 슬라이드에 없는 단계별 계산은 **작성자 보충**으로 표시했다. 다른 Perception 강의와의 연결은 [통합 Perception 학습 노트]({{ "/study/autonomous-driving/perception-overview/" | relative_url }})를 참고한다.

> **핵심:** Semantic segmentation은 각 픽셀이 **무슨 종류인지** 예측하되 같은 종류의 서로 다른 개체를 구분하지 않는다. Instance segmentation은 검출된 각 **thing 개체마다 별도 mask**를 만든다. FCN은 전체 영상의 dense class score를 한꺼번에 계산하고, Mask R-CNN은 Faster R-CNN의 RoI별 분류·box 경로에 정렬된 mask 경로를 더한다. Downsampling으로 얻은 문맥과 upsampling으로 복원한 경계 사이의 trade-off를 이해해야 결과를 바르게 읽을 수 있다.

## 전체 흐름

| 순서 | 슬라이드 | 핵심 질문 |
|---|---:|---|
| 1 | 3, 7–9 | Semantic segmentation은 classification·box detection과 무엇이 다른가? |
| 2 | 8–11 | FCN의 dense score와 down/up-sampling은 왜 필요한가? |
| 3 | 12–17 | Transposed convolution은 겹치는 출력을 어떻게 합산하는가? |
| 4 | 18–20, 26 | Thing/stuff와 semantic/instance 구분은 어디서 갈리는가? |
| 5 | 21–25 | Mask R-CNN은 RoI마다 클래스·box·mask를 어떻게 예측하는가? |
| 6 | 27–30 | 다음 3D detection으로 이어지는 학습 경계는 무엇인가? |

## 1. Box에서 픽셀로: 예측 대상의 변화

7쪽은 semantic segmentation을 이미지의 **모든 픽셀에 category label을 부여하는 pixel-level task**로 정의한다. 예컨대 고양이·풀·하늘의 픽셀이 각기 다른 클래스로 칠해진다. 두 마리 소가 같은 영상에 있다면 소 픽셀은 둘 다 같은 semantic class일 뿐 “첫째 소”, “둘째 소”라는 instance ID를 자동으로 갖지는 않는다.

**작성자 보충 — 수학적 표기:** 높이 $$H$$, 너비 $$W$$, class 수 $$C$$의 영상에 대해 모델의 score tensor를 $$S\in\mathbb{R}^{C\times H\times W}$$, 정답 label map을 $$Y\in\{1,\ldots,C\}^{H\times W}$$로 둔다. $$H,W,C$$는 무차원 **개수**, 픽셀 위치 $$(u,v)$$는 pixel index다. 각 위치의 예측은 아래처럼 정의한다.

$$
\hat{Y}_{u,v}=\underset{c\in\{1,\ldots,C\}}{\operatorname{argmax}}\ S_{c,u,v}
$$

슬라이드 8쪽의 `3 × H × W → D × H × W → C × H × W → H × W` 흐름은 RGB 입력 채널 3개, 중간 feature channel $$D$$개, 클래스별 score $$C$$개, 최종 class index 한 장을 뜻한다. 그 옆의 **per-pixel cross-entropy**는 유효한 정답 픽셀 집합 $$\Omega$$에 대해 다음처럼 쓸 수 있다. 이는 슬라이드 식을 풀어 쓴 **작성자 보충 정의**다.

$$
\mathcal{L}_{\mathrm{pixel}}=-\frac{1}{\lvert\Omega\rvert}\sum_{(u,v)\in\Omega}\log p_{Y_{u,v},u,v}
$$

여기서 $$p_{c,u,v}$$는 픽셀 $$(u,v)$$가 class $$c$$일 확률, $$\lvert\Omega\rvert$$는 무시 대상 라벨을 뺀 유효 pixel 수다. 확률과 손실은 무차원이다. 이 식은 **평균 손실의 한 정의**이며 실제 구현은 class weight 또는 ignore label 등으로 달라질 수 있다. 한 픽셀의 정답 확률이 0.8이면 기여는 $$-\log0.8\approx0.223$$, 0.2이면 $$-\log0.2\approx1.609$$로 오분류 위험이 큰 픽셀을 더 벌준다. 각 픽셀을 잘 맞혀도 인접한 동일 class의 두 개체를 분리하는 supervision은 별도로 없다.

## 2. FCN의 문맥과 해상도 문제

Fully Convolutional Network(FCN)는 위치마다 별도 분류기를 돌리기보다 convolutional feature를 공유하며 전체 영상의 픽셀 예측을 한 번에 계산한다(8쪽). 그러나 9쪽은 **고해상도 feature를 끝까지 유지하면 계산·메모리 비용이 크고**, 수용영역을 키우기 위해 층만 쌓는 방식은 비효율적일 수 있다고 지적한다.

슬라이드의 `L개의 3×3 conv → receptive field 1+2L`은 stride 1, dilation 1, 각 층 3×3, 경계 효과를 무시하는 **특정 조건의 정확한 크기 계산**이다. 첫 점의 수용영역 폭은 1이고, 3×3 층마다 양쪽으로 한 픽셀씩 늘어나므로 $$R_0=1$$, $$R_{L+1}=R_L+2$$, 따라서 아래가 된다.

$$
R_L=1+2L
$$

$$R_L,L$$은 pixel 개수 또는 층 수다. 예를 들어 5개 층이면 폭 11 pixel의 **이론적** 수용영역이다. Stride, dilation, pooling이 바뀌면 식도 바뀌고, 실제 유효 수용영역의 정보 분포는 이론적 폭과 같지 않다. 이 제한을 적지 않고 “모든 FCN의 수용영역은 선형”이라고 일반화하면 틀린다.

10–11쪽의 encoder–decoder 구조는 pooling 또는 strided convolution으로 해상도를 낮춰 넓은 문맥을 효율적으로 얻은 뒤, upsampling으로 픽셀 해상도에 돌아온다. 낮은 해상도는 물체가 무엇인지 이해하는 데 도움이 되지만 작은 표지판·얇은 경계 같은 세부 정보가 사라질 수 있다. 단순 확대만으로 잃어버린 경계 정보가 저절로 복구되지는 않는다. [FCN 원 논문](https://arxiv.org/abs/1605.06211){:target="_blank" rel="noopener"}은 깊고 거친 의미 정보와 얕고 세밀한 appearance 정보를 skip 구조로 결합한다. 이는 슬라이드 그림을 이해하기 위한 원 논문 보강이며, 10쪽 도식의 모든 층을 특정 FCN 구현과 1:1 대응시킨다는 뜻은 아니다.

## 3. Transposed convolution: 학습 가능한 upsampling

12–13쪽은 먼저 **일반 convolution**을 복습한다. Kernel 3, stride 1, pad 1의 4×4 입력은 4×4 출력을 만들고, stride 2로 바꾸면 2×2가 된다. 14–17쪽은 역방향 크기 관계를 만드는 transposed convolution을 1D와 2D 예제로 설명한다. 이 연산은 원 convolution의 행렬 연산을 전치한 형태이며, 입력을 원상복구하는 수학적 역함수는 아니다. 그래서 슬라이드 15쪽도 “deconvolution”보다 **transposed convolution**이라는 명칭을 선호한다.

### 3.1 1D 예제: 왜 가운데서 더하는가

슬라이드 14–15쪽에서 입력은 $$(a,b)$$, 길이 3 filter는 $$(x,y,z)$$, stride는 2다. 첫 입력 $$a$$는 앞쪽 세 위치에 $$(ax,ay,az)$$를, 둘째 $$b$$는 두 칸 뒤 세 위치에 $$(bx,by,bz)$$를 놓는다. 가운데 한 위치가 겹치므로 **작성자 보충 전개**는 다음과 같다.

$$
(a,b)\xrightarrow[\text{stride }2]{(x,y,z)}(ax,\ ay,\ az+bx,\ by,\ bz)
$$

식은 padding·crop이 없는 이 예제에 대한 **정확한 선형 결합**이다. $$a,b$$는 입력 feature 값, $$x,y,z$$는 학습 filter weight, 출력은 feature 값으로 물리 단위가 없는 모델 내부 수치다. 예를 들어 $$a=1,b=2,x=1,y=0,z=-1$$이면 출력은 $$(1,0,1,0,-2)$$다. 겹치는 셀을 덮어쓰지 않고 더해야 이 값이 나온다. Filter를 학습한다는 것은 확대 결과의 값을 데이터에 맞게 결정한다는 뜻이지, 원래 고해상도 영상의 참값을 항상 복구한다는 뜻은 아니다.

### 3.2 2D 출력 크기와 crop

16–17쪽은 2×2 입력, 3×3 kernel, stride 2의 각 입력 위치가 출력 평면의 3×3 영역에 값을 놓고 **겹치면 합산**하는 모습을 그린다. Padding 0, dilation 1, output padding 0인 한 축의 출력 크기 $$m$$은 **작성자 보충**으로 다음과 같다.

$$
m=(n-1)s+k
$$

여기서 $$n$$은 입력 길이, $$s$$는 stride, $$k$$는 kernel 길이, $$m$$은 출력 길이로 모두 pixel 개수다. 대입하면 $$(2-1)\cdot2+3=5$$이므로 2×2에서 **full output은 5×5**다. 슬라이드 16쪽의 “4×4 output” 그림은 첫 두 입력만 그린 중간 그림으로 읽어야 하고, 17쪽이 네 입력을 모두 반영한 뒤 **5×5를 한 행·열 잘라 4×4**로 맞춘다고 명시한다. 자르는 쪽은 출력 정렬 규약의 한 선택이다. 일반 설정에서는 padding·output padding도 출력 크기를 바꾸므로 2×2→4×4를 kernel과 stride만으로 유일하게 결정할 수 없다.

왜 crop을 쓰는가? Decoder가 encoder의 특정 feature와 합쳐지려면 공간 크기와 정렬이 맞아야 한다. 그러나 crop은 정보를 제거하므로 어떤 모서리를 자르는지, 원본 좌표와 feature alignment가 맞는지를 확인해야 한다. Transposed convolution의 겹침은 학습 가능한 장점이지만 kernel·stride 조합에 따라 불균일한 겹침 패턴이 생길 수 있다. 이 마지막 주의는 슬라이드의 주장이라기보다 구현 시 고려할 **작성자 보충**이다.

## 4. Thing, stuff, semantic, instance

18쪽은 **thing**을 개체별로 셀 수 있는 범주(예: car, person), **stuff**를 개체 경계를 붙이지 않는 배경·재료 범주(예: sky, grass)로 설명한다. 중요한 것은 **데이터셋의 annotation taxonomy**다. 슬라이드에 `trees`가 stuff 예시로 있으나 모든 나무가 본질적으로 개별 instance를 가질 수 없다는 뜻은 아니다. 어떤 데이터셋은 tree를 하나의 영역 클래스로 표시하고, 다른 작업은 개별 나무를 탐지·분할할 수 있다. [COCO-Stuff 원 논문](https://arxiv.org/abs/1612.03716){:target="_blank" rel="noopener"}의 thing/stuff 분류도 데이터셋 설계 맥락에서 읽는다.

19–20쪽과 26쪽은 네 작업의 출력 차이를 시각화한다.

| 작업 | 위치 정보 | 같은 class의 두 개체 분리 | 예시 출력 |
|---|---|---|---|
| Image classification | 영상 전체 label | 아니오 | `cat` |
| Object detection | 물체별 대략적 box | 예 | `cow #1 box`, `cow #2 box` |
| Semantic segmentation | 픽셀별 class 영역 | 아니오 | 소 픽셀 모두 `cow` |
| Instance segmentation | 개체별 pixel mask | 예 | `cow #1 mask`, `cow #2 mask` |

여기서 semantic segmentation도 **cow라는 물체 class의 픽셀**을 표시한다. 슬라이드 26쪽의 “no objects, just pixels”는 개체 **ID가 없다**는 뜻으로 제한해서 읽어야 한다. 반대로 이 강의가 다루는 instance segmentation은 주로 thing 개체의 mask를 예측하므로 sky·road 같은 stuff 전체를 자동으로 완전히 모델링한다는 뜻이 아니다. 두 출력을 함께 다루려면 별도 panoptic segmentation 같은 문제 설정이 필요하다.

## 5. Mask R-CNN: RoI마다 정렬된 mask 만들기

21–22쪽은 Faster R-CNN의 RPN·RoI 분류·box 경로에 **mask prediction branch**를 더한 Mask R-CNN을 소개한다. 검출 box만으로는 소의 몸통 윤곽과 배경을 구분하지 못한다. Mask branch는 각 RoI의 픽셀 범위를 예측해 같은 클래스의 두 개체에도 별도 색·영역을 줄 수 있다(20, 22, 25쪽).

23쪽은 RoI Align 뒤의 예시 feature가 $$256\times14\times14$$이고, conv 기반 mask 경로가 class별 $$C\times28\times28$$ mask score를 만든다고 나타낸다. 256은 feature 채널 수, 14와 28은 **RoI 내부 grid의 픽셀 개수**, $$C$$는 thing 클래스 수로 모두 무차원 개수다. 28×28은 **RoI에 정규화된 작은 mask**이지 원본 영상 전체가 28×28로 줄어든다는 뜻이 아니다. 추론 시 선택한 class의 mask를 해당 RoI 크기에 맞춰 다시 투영한다.

Mask R-CNN 원 논문은 RoI Pooling의 좌표 반올림이 작은 mask의 경계를 어긋나게 할 수 있어 **RoIAlign**에서 양선형 보간으로 분수 좌표를 보존한다고 설명한다. 이는 슬라이드 21–22쪽의 구식 Faster R-CNN `RoI pooling` 도식과 23쪽의 Mask R-CNN `RoI Align` 도식을 구분할 근거다. 단순히 “mask head 하나 추가”만으로 pixel alignment가 해결되는 것은 아니다. [Mask R-CNN 원 논문](https://arxiv.org/abs/1703.06870){:target="_blank" rel="noopener"}의 설명을 따른다.

**작성자 보충 — mask loss:** 각 양성 RoI의 정답 class $$k$$에 대해서만 $$m\times m$$ mask target $$y_{i,j}\in\{0,1\}$$와 예측 확률 $$q_{k,i,j}$$의 binary cross-entropy를 평균한다. 아래는 원 논문의 설명을 학습용으로 펼친 식이다.

$$
\mathcal{L}_{\mathrm{mask}}=-\frac{1}{m^2}\sum_{i=1}^{m}\sum_{j=1}^{m}\bigl[y_{i,j}\log q_{k,i,j}+(1-y_{i,j})\log(1-q_{k,i,j})\bigr]
$$

$$m,i,j,k$$는 무차원 index·크기, 확률과 손실도 무차원이다. 식은 $$0<q_{k,i,j}<1$$에서 유한하며 실제 계산에는 수치 안정화가 필요하다. 원 논문의 전체 RoI 손실은 분류·box·mask의 세 항을 결합한다. **의미 분할의 픽셀 softmax**와 달리 class별 binary mask를 만들고 선택된 class의 mask에만 손실을 적용한다는 점이 핵심이다. 24쪽의 여러 훈련 target은 같은 영상에서도 개체마다 별도 RoI crop·binary mask가 필요하다는 뜻이다.

## Source Check

| 위치 | 판정 | 확인과 이 글의 처리 |
|---|---|---|
| 9쪽 $$1+2L$$ receptive field | 가정이 생략된 단순화 | 3×3, stride 1, dilation 1의 연속 층에 한정한다. Pooling/stride 변경 시 그대로 쓰지 않는다. |
| 10쪽 low-res 단계의 `H/4 × W/4` 반복 | 도식 차원 표기 불명확 | 그림은 더 낮은 해상도를 표현하지만 med-res와 같은 문자 크기가 반복된다. 특정 단계의 실제 크기로 단정하지 않고 구조 개념만 설명한다. |
| 16–17쪽 2×2→4×4 transposed conv | 중간 그림과 crop 조건 | 전체 3×3, stride 2 출력은 5×5이며 17쪽의 crop을 반영해야 4×4다. |
| 18쪽 `trees`를 stuff로 제시 | 데이터셋 관례 | 나무 개체 분리 가능성 자체를 부정하지 않는다. Thing/stuff는 작업의 label taxonomy에 좌우된다. |
| 26쪽 semantic의 `no objects, just pixels` | 표현상 단순화 | Cow 같은 thing class 픽셀은 존재하지만 **instance ID는 없다**는 뜻으로 고쳐 읽는다. |
| 21–23쪽 RoI pooling/Align | 모델 단계 구분 | Faster R-CNN 복습 그림은 pooling, Mask R-CNN mask 경로는 RoIAlign이다. |

## 시험 포인트

- Semantic의 $$C\times H\times W$$ score tensor를 $$H\times W$$ label map으로 바꾸는 argmax 축을 설명한다.
- Pixel-wise CE가 class label은 학습하지만 instance ID를 자동으로 주지 않는 이유를 말한다.
- $$1+2L$$의 **성립 가정**과 down/up-sampling의 정보·비용 trade-off를 구분한다.
- 1D transposed conv의 가운데 항 $$az+bx$$와 2D 2×2→5×5→crop 4×4 계산을 직접 해 본다.
- Thing/stuff와 semantic/instance를 다른 축으로 설명한다. 예컨대 semantic mask에는 thing class도 포함될 수 있다.
- Mask R-CNN에서 RPN, RoIAlign, class/box branch, mask branch의 위치를 그릴 수 있어야 한다.

## 마지막 핵심 정리

**공간 범위만 필요하면 box detection, 픽셀별 종류가 필요하면 semantic segmentation, 같은 종류의 개체마다 정확한 윤곽이 필요하면 instance segmentation**을 생각한다. FCN은 dense score의 계산을 공유하지만 해상도 복원이 필요하고, transposed convolution은 겹치는 가중 filter 출력으로 학습 가능한 확대를 한다. Mask R-CNN은 검출된 RoI를 정렬해 개체별 mask를 만든다. 이 강의의 다음 단계는 픽셀 평면을 넘어 거리·방향·크기를 갖는 **3D object detection**이다(29쪽).

## Study Guide

먼저 7, 19, 20, 26쪽의 같은 사진을 비교해 **영상 label → box → class 영역 → 개체별 영역**의 출력 차이를 말로 설명한다. 그 다음 8–11쪽에서 채널과 공간 크기를 분리해 적고, 12–17쪽의 1D 예제를 실제 숫자로 계산한다. 마지막으로 21–24쪽에서 Faster R-CNN과 Mask R-CNN을 나란히 그려 RoIAlign·mask branch를 표시한다. 원문 그림의 `H/4` 반복과 2×2→4×4 중간 단계는 Source Check와 함께 보아야 수치를 잘못 암기하지 않는다.

## 복습 질문

<details markdown="block">
<summary>1. 두 대의 차가 붙어 있을 때 semantic segmentation과 instance segmentation의 출력 차이는 무엇인가?</summary>

답변: Semantic segmentation은 두 차의 픽셀을 같은 `car` class로 표시하지만 어느 픽셀이 첫째 차인지 식별하지 않는다. Instance segmentation은 차마다 다른 instance mask를 만들어 두 개체를 분리한다.

</details>

<details markdown="block">
<summary>2. 3×3 stride-1 convolution L개에 대해 수용영역 폭이 1+2L인 조건은 무엇인가?</summary>

답변: 모든 층이 3×3, stride 1, dilation 1이고 중간 pooling이나 크기 변경이 없을 때다. 각 층이 입력상 양쪽으로 한 픽셀씩 범위를 넓히므로 폭이 2씩 증가한다. Stride나 dilation이 바뀌면 이 식을 그대로 쓸 수 없다.

</details>

<details markdown="block">
<summary>3. 1D transposed convolution 예제에서 가운데 출력이 왜 az+bx인가?</summary>

답변: 입력 $$a$$가 놓은 세 번째 filter 값 $$az$$와 stride 2로 이동한 입력 $$b$$가 놓은 첫 번째 값 $$bx$$가 같은 출력 위치에 겹친다. Transposed convolution은 겹친 기여를 더한다.

</details>

<details markdown="block">
<summary>4. RoIAlign이 Mask R-CNN의 mask 예측에 중요한 이유는 무엇인가?</summary>

답변: RoI 경계를 정수 격자로 거칠게 반올림하면 작은 mask의 위치가 실제 영상과 어긋날 수 있다. RoIAlign은 분수 좌표를 유지하고 보간으로 feature를 취해 픽셀 경계 정렬을 개선한다.

</details>

<details markdown="block">
<summary>5. “Tree는 stuff”라는 문장을 언제 그대로 적용하면 위험한가?</summary>

답변: 개별 나무를 세거나 분할하는 작업에서는 나무를 thing instance로 다룰 수 있다. Thing/stuff는 물체의 절대적 본성이 아니라 데이터셋의 label·annotation 목적에 따라 정해지는 범주다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 8 source slides (PDF)</a></li>
</ul>

## References

- <a href="https://arxiv.org/abs/1605.06211" target="_blank" rel="noopener">Shelhamer, Long, and Darrell, Fully Convolutional Networks for Semantic Segmentation</a> — dense prediction과 coarse/fine 정보 결합.
- <a href="https://arxiv.org/abs/1612.03716" target="_blank" rel="noopener">Caesar et al., COCO-Stuff</a> — thing/stuff label taxonomy.
- <a href="https://arxiv.org/abs/1703.06870" target="_blank" rel="noopener">He et al., Mask R-CNN</a> — RoIAlign, class별 mask, mask loss의 원문.
