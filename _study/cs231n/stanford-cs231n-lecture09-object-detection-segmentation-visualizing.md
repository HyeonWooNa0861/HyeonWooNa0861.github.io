---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 9: Object Detection, Image Segmentation, Visualizing"
course: "CS231N"
topic: "Object Detection, Segmentation, and Visualization"
order: 9
major_topic: "Computer Vision"
keywords:
  - "Object Detection"
  - "Image Segmentation"
  - "Visualization"
  - "Region Proposals"
  - "Feature Attribution"
---

# Stanford CS231N Lecture 9: Object Detection, Image Segmentation, Visualizing

Source: [Stanford CS231N Spring 2025 Lecture 9](https://www.youtube.com/watch?v=PTypu6GqEd4){:target="_blank" rel="noopener"}
Slides: [Official Stanford CS231N 2025 Lecture 9 PDF](https://cs231n.stanford.edu/slides/2025/lecture_9.pdf){:target="_blank" rel="noopener"}

> **핵심:** 분류가 이미지 전체의 한 레이블을 예측한다면 segmentation은 픽셀마다, detection은 객체마다 구조화된 출력을 예측한다. 현대 방법은 CNN/ViT backbone의 feature를 공유하고 task-specific head를 붙이며, Grad-CAM 같은 도구는 예측을 지지한 공간적 근거를 점검하게 한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Vision Transformer recap | 이미지를 token sequence로 어떻게 바꾸는가? |
| 2 | Semantic segmentation | 해상도를 줄인 feature에서 픽셀 레이블을 어떻게 복원하는가? |
| 3 | Object detection | 개수가 가변적인 객체의 클래스와 box를 어떻게 예측하는가? |
| 4 | R-CNN family and YOLO | two-stage와 one-stage detector는 무엇이 다른가? |
| 5 | DETR | detection을 set prediction으로 어떻게 바꾸는가? |
| 6 | Instance segmentation | 객체별 box와 mask를 어떻게 함께 얻는가? |
| 7 | Visualization | 모델이 본 영역을 어떻게 진단하는가? |

## 1. Vision Transformer recap

ViT는 이미지를 $$P\times P$$ patch로 나누고 각 patch를 펼쳐 linear projection으로 token을 만든다. $$H\times W$$ 이미지의 patch token 수는 $$N=HW/P^2$$다. Self-attention에는 2D 위치가 내장되어 있지 않으므로 positional embedding을 더한다.

분류에서는 학습 가능한 `[CLS]` token을 sequence 앞에 붙이고 Transformer를 지난 해당 출력에 classifier를 연결할 수 있다. 또는 모든 patch token을 pooling할 수도 있다. Patch가 작으면 세부 정보는 좋아지지만 token 수가 늘어 attention 비용이 커진다.

## 2. Semantic segmentation

Semantic segmentation은 각 픽셀을 클래스 중 하나로 분류한다. 같은 클래스의 서로 다른 객체 instance는 구분하지 않는다. 출력은 보통 $$H\times W\times C$$ logits이고 픽셀별 softmax cross-entropy를 사용한다.

초기 방식처럼 각 픽셀 주변 patch를 따로 분류하면 겹치는 계산이 막대하다. Fully convolutional network는 전체 이미지에서 shared feature map을 한 번 계산하고 spatial class score를 출력한다.

### Downsampling과 upsampling

Backbone은 stride/pooling으로 해상도를 낮추면서 receptive field와 semantic abstraction을 높인다. Segmentation head는 coarse score map을 원래 크기로 복원해야 한다.

- **Nearest/bilinear interpolation:** 파라미터 없는 고정 upsampling
- **Transposed convolution:** 학습 가능한 upsampling
- **Unpooling:** max-pooling 때 저장한 위치를 이용해 값을 되돌림
- **Skip connection:** 얕은 층의 고해상도 detail과 깊은 층의 semantics를 결합

Transposed convolution은 convolution의 역함수가 아니라 convolution 연산에 대한 선형 변환의 transpose에 해당한다. Kernel/stride가 겹치는 방식에 따라 checkerboard artifact가 생길 수 있다.

## 3. Object detection의 출력과 평가

Detection은 각 객체의 클래스와 bounding box $$(x,y,w,h)$$를 예측한다. 이미지마다 객체 수가 달라 출력 크기가 고정되지 않는 것이 분류와 다른 점이다.

예측 box와 정답 box의 겹침은 Intersection over Union으로 측정한다.

$$
\operatorname{IoU}(A,B)=\frac{|A\cap B|}{|A\cup B|}
$$

Detector는 classification loss와 box regression loss를 함께 최적화한다. 높은 confidence의 중복 box가 많이 나오면 Non-Maximum Suppression이 가장 높은 score를 남기고 IoU가 큰 나머지를 제거한다. 임계값은 중복 제거와 가까운 객체 보존 사이의 trade-off다.

## 4. R-CNN 계열: two-stage detection

R-CNN은 먼저 selective search 같은 방법으로 region proposal을 만들고 각 crop을 CNN에 넣어 분류·box 보정을 수행한다. Proposal마다 CNN을 반복 실행해 매우 느리다.

Fast R-CNN은 전체 이미지의 feature map을 한 번 계산하고 proposal 위치의 feature를 crop/pool해 head에 전달한다. Faster R-CNN은 proposal 생성도 Region Proposal Network로 학습해 end-to-end detector에 가까워진다.

```text
image -> shared backbone feature
      -> region proposals
      -> RoI feature extraction
      -> class scores + box offsets
```

Two-stage 방식은 후보 생성과 후보 판별을 분리하므로 정교한 region reasoning에 강하지만 pipeline이 복잡하다.

## 5. YOLO: one-stage detection

YOLO 계열은 dense grid/feature 위치에서 class, objectness, box를 한 번에 예측한다. 별도의 proposal crop 단계를 없애 병렬성이 좋고 빠르다. 여러 scale feature와 anchor 또는 anchor-free parameterization으로 다양한 크기의 객체를 다룬다.

출력 후보가 많으므로 confidence threshold와 NMS 후처리가 중요하다. 작은 객체, 겹친 객체, class imbalance는 detector 설계와 학습에서 계속 다뤄야 할 문제다. 강의는 YOLO에 여러 세대의 구현이 있음을 언급하므로 특정 버전의 세부 구조를 전체 계열의 불변 규칙처럼 보면 안 된다.

## 6. DETR: set prediction

DETR은 CNN 또는 vision backbone feature를 Transformer에 넣고, 고정 수의 learned object query가 cross-attention으로 image token을 읽게 한다. 각 query는 객체 클래스 또는 `no object`와 box를 출력한다.

정답 객체와 query 예측의 순서는 정해져 있지 않으므로 Hungarian matching으로 one-to-one assignment를 찾고 matched pair의 class/box loss를 계산한다. 이 set prediction 관점은 duplicate prediction을 학습 안에서 직접 다뤄 전통적 anchor와 NMS 의존을 줄인다.

Object query는 특정 클래스나 위치가 미리 지정된 box가 아니라, 학습을 통해 서로 다른 객체 슬롯 역할을 나누는 벡터다.

## 7. Instance segmentation과 Mask R-CNN

Instance segmentation은 semantic class뿐 아니라 같은 클래스의 객체들을 개별 mask로 구분한다. Mask R-CNN은 Faster R-CNN에 각 RoI의 binary mask를 예측하는 branch를 추가한다.

RoIAlign은 quantization으로 좌표를 거칠게 반올림하지 않고 interpolation으로 feature를 sampling해 mask에 필요한 정렬 정확도를 높인다. Class/box/mask head가 shared backbone feature 위에서 함께 학습된다.

| Task | 출력 |
|---|---|
| Classification | 이미지당 class |
| Semantic segmentation | 픽셀당 class |
| Object detection | 객체당 class + box |
| Instance segmentation | 객체당 class + box + mask |

## 8. Model visualization

### Saliency map

특정 클래스 점수 $$s_c$$의 입력 이미지 gradient 절댓값을 계산하면 어느 픽셀의 작은 변화가 점수에 민감한지 볼 수 있다.

$$
M_{ij}=\max_k\left|\frac{\partial s_c}{\partial I_{ijk}}\right|
$$

이는 중요도의 한 근사이며 noisy할 수 있고, 큰 gradient가 곧 인간이 이해하는 원인임을 뜻하지는 않는다.

### Activation maximization

특정 neuron 또는 class score를 크게 만드는 입력을 gradient ascent로 최적화한다. 자연스러운 이미지를 얻으려면 입력 norm, smoothness, jitter 같은 regularization이 필요하다. 결과는 모델이 선호하는 패턴을 보여주지만 데이터의 실제 대표 예시와 동일하지 않다.

### Grad-CAM

Grad-CAM은 class score가 마지막 convolutional feature map $$A^k$$에 미치는 gradient를 공간 평균해 channel weight를 만든다.

$$
\alpha_k^c=\frac{1}{Z}\sum_{i,j}\frac{\partial y^c}{\partial A_{ij}^k},
\qquad
L_{\mathrm{Grad-CAM}}^c=\operatorname{ReLU}\left(\sum_k\alpha_k^cA^k\right)
$$

마지막 ReLU는 target class에 긍정적으로 기여한 영역을 남긴다. 결과는 class-discriminative하지만 feature map 해상도만큼 거칠다. 설명 지도는 정답 증명이 아니라 shortcut, 배경 의존, 잘못된 관심 영역을 찾는 진단 도구로 사용해야 한다.

## 핵심 수식 유도

### 작성자 보충: Grad-CAM channel weight

Target class score $$y^c$$가 마지막 convolution feature map $$A^k\in\mathbb R^{H\times W}$$에 대해 미분 가능하다고 하자. 공간 위치 수는 정확히

$$
Z=HW
$$

이다. Feature에 작은 변화 $$\delta A$$를 줄 때의 1차 Taylor 근사는

$$
\delta y^c
\approx\sum_k\sum_{i=1}^{H}\sum_{j=1}^{W}
\frac{\partial y^c}{\partial A_{ij}^k}\delta A_{ij}^k
$$

이다. Grad-CAM은 channel $$k$$의 공간적 민감도를 하나의 scalar로 요약하기 위해 이 gradient를 평균한

$$
\alpha_k^c
=\frac{1}{Z}\sum_{i=1}^{H}\sum_{j=1}^{W}
\frac{\partial y^c}{\partial A_{ij}^k}
$$

를 사용하고, positive contribution만 남기는 heatmap을

$$
L_{\mathrm{Grad-CAM}}^c
=\operatorname{ReLU}\left(\sum_k\alpha_k^cA^k\right)
$$

로 정의한다. Taylor 전개 자체는 작은 perturbation에 대한 **1차 근사**지만, spatial gradient를 평균하고 ReLU로 자르는 과정은 localization을 위한 **휴리스틱**이다. $$Z,H,W$$는 무차원 개수다. $$A$$의 단위를 `feature`, $$y^c$$의 단위를 `score`라 하면 gradient와 $$\alpha$$는 `score/feature`, heatmap은 `score` 단위를 가진다.

이 지도는 feature map 해상도보다 세밀할 수 없어 upsampling 후 경계가 거칠고, softmax probability가 포화되면 gradient가 작아질 수 있어 보통 pre-softmax score를 사용한다. ReLU는 class를 억제하는 negative evidence를 버리며, gradient saturation과 nonlinear interaction도 설명하지 못한다. 따라서 Grad-CAM은 입력 영역이 예측의 원인이라는 증명이 아니라 모델 민감도의 비인과적 진단이다.

### 작성자 보충: IoU와 detection loss

IoU는 두 box 영역 $$A,B$$에 대한 **정의** $$\operatorname{IoU}=\lvert A\cap B\rvert/\lvert A\cup B\rvert$$이며 $$\lvert A\cup B\rvert=\lvert A\rvert+\lvert B\rvert-\lvert A\cap B\rvert$$에서 계산된다. 면적 단위가 약분되어 IoU는 무차원이고 $$[0,1]$$ 범위다. 겹치지 않는 box에서는 IoU와 그 직접 loss의 gradient가 0이므로 GIoU/DIoU 같은 보완 loss가 필요할 수 있다. Detection total loss는 classification, box regression, mask 항의 weighted sum이라는 **설계 선택**이며 weight는 서로 다른 scale을 맞추는 hyperparameter이지 수학적으로 유일한 값이 아니다.

## 마지막 핵심 정리

- Segmentation은 dense prediction, detection은 variable-size object prediction이다.
- Encoder의 의미 정보와 decoder/skip connection의 공간 detail을 함께 써야 정밀한 segmentation이 가능하다.
- R-CNN 계열은 proposal 기반 two-stage, YOLO는 dense one-stage 접근이다.
- DETR은 object query와 bipartite matching으로 detection을 set prediction으로 정식화한다.
- Mask R-CNN은 aligned RoI feature에서 객체별 mask를 예측한다.
- Grad-CAM은 class gradient로 feature channel을 가중하지만 인과 설명으로 과해석하면 안 된다.

## Study Guide

1. 네 vision task의 출력 tensor/객체 구조를 비교한다.
2. R-CNN → Fast R-CNN → Faster R-CNN에서 중복 계산과 proposal 생성이 어떻게 바뀌는지 추적한다.
3. IoU와 NMS를 작은 box 예제로 직접 계산한다.
4. DETR의 object query, cross-attention, Hungarian matching을 한 흐름으로 설명한다.
5. saliency와 Grad-CAM이 각각 input gradient와 feature-map gradient를 사용한다는 차이를 구분한다.

## 복습 질문

<details markdown="block"><summary>1. Semantic segmentation과 instance segmentation의 차이는?</summary>

답변: semantic segmentation은 픽셀의 클래스만 구분하므로 같은 클래스의 두 객체가 하나로 합쳐질 수 있다. Instance segmentation은 객체별 identity를 나누고 각각의 mask를 출력한다.
</details>

<details markdown="block"><summary>2. Fast R-CNN이 R-CNN보다 빠른 핵심 이유는?</summary>

답변: proposal마다 CNN을 다시 실행하지 않고 전체 이미지 feature map을 한 번 계산한 뒤 각 proposal의 feature만 추출해 공유하기 때문이다.
</details>

<details markdown="block"><summary>3. DETR에서 Hungarian matching이 필요한 이유는?</summary>

답변: 예측 query와 정답 객체 모두 순서가 없는 집합이므로, 전체 비용을 최소화하는 one-to-one 대응을 먼저 정해야 각 예측에 올바른 loss를 줄 수 있기 때문이다.
</details>

<details markdown="block"><summary>4. Grad-CAM heatmap이 모델 판단의 완전한 설명이 아닌 이유는?</summary>

답변: 마지막 feature map과 local gradient에 기반한 저해상도 근사이며, 표시된 상관 영역이 실제 인과 근거임을 보장하지 않기 때문이다.
</details>

## 원문 대조 기록

공식 PDF **178쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 33–65쪽 · 영상 00:17:45 | semantic segmentation, upsampling, U-Net | 1–2절 |
| PDF 66–124쪽 · 영상 00:38:55, 00:44:45 | R-CNN 계열, YOLO, DETR, Mask R-CNN | 3–5절 |
| PDF 127–148쪽 · 영상 01:07:37 | saliency, activation maximization, CAM/Grad-CAM | 6절 |
| PDF 149–178쪽 | convolution matrix, RoI Pool/Align, guided-backprop appendix | 본문 관련 절 대조; 반복 사례는 추가하지 않음 |

Task와 architecture 비교는 강의 원문 요약이다. Grad-CAM의 Taylor 해석과 IoU·detection-loss 경계 조건은 **작성자 보충**이며, Grad-CAM은 인과 증명이 아닌 localization heuristic으로 구분했다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 9](https://www.youtube.com/watch?v=PTypu6GqEd4){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 9 PDF](https://cs231n.stanford.edu/slides/2025/lecture_9.pdf){:target="_blank" rel="noopener"}
