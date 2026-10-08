---
layout: default
date: 2026-10-08 16:58:59 +0900
title: "Lab 1: Two-Stage vs One-Stage Object Detection"
course: "Autonomous Driving"
topic: "Tracing Faster R-CNN and RetinaNet"
order: 13
major_topic: "Autonomous Systems"
keywords:
  - "Object Detection"
  - "Faster R-CNN"
  - "RetinaNet"
  - "Feature Pyramid Network"
  - "Region Proposal Network"
  - "RoIAlign"
  - "Focal Loss"
  - "Penn-Fudan"
---

# Lab 1: Two-Stage vs One-Stage Object Detection

Source Notebook: <a href="{{ "/assets/materials/study/autonomous-driving/adc-lab-01-two-stage-vs-one-stage.ipynb" | relative_url }}" download data-no-resource-reader>ADC_<wbr>Lab1_<wbr>TwoStage_<wbr>vs_<wbr>OneStage.ipynb</a>

> **핵심:** 이 실습은 Faster R-CNN과 RetinaNet의 최종 박스만 비교하는 실습이 아니다. **같은 이미지가 feature, anchor, 학습 정답, 예측 박스, 최종 검출로 바뀌는 과정을 직접 추적**한다. Faster R-CNN은 먼저 물체 후보를 고르고 각 후보를 다시 분류·보정한다. RetinaNet은 밀집 anchor에서 클래스와 박스를 바로 예측하고, 그때 생기는 배경 불균형을 focal loss와 낮은 초기 클래스 확률로 다룬다. 두 구조의 차이는 검출 결과보다 **어디에서 판단하고 어떤 후보로 학습하는가**에 있다.

제공된 notebook은 Markdown 35개와 code cell 39개로 구성된다. Code cell의 실행 번호는 모두 비어 있고 저장된 출력도 없다. 따라서 실제 anchor 수, loss, precision·recall, 학습 시간은 **실행 후 확인할 값**이다. 아래 수치 예제는 원리를 설명하기 위한 별도 합성 계산이며, 학습 결과를 대신하지 않는다.

## 전체 흐름

| Notebook 구간 | 살펴보는 대상 | 확인할 질문 |
|---|---|---|
| 0–1절 | 실행 환경, Penn-Fudan, 초기 모델과 COCO 모델 | 어떤 데이터와 어떤 초기 가중치를 비교하는가? |
| 2–3절 | Transform, Backbone·FPN, anchor | 이미지 좌표와 feature 위치는 어떻게 연결되는가? |
| 4절 | RPN label, sampling, regression target | 무엇이 정답이고 무엇을 학습하는가? |
| 5–6절 | Proposal 선별, RoIAlign, 두 번째 분류·회귀 | 많은 anchor가 최종 박스로 줄어드는 이유는 무엇인가? |
| 7–9절 | 초기·COCO 검출, 직접 학습, 평가 | 어느 단계가 좋아졌는지 어떻게 구분하는가? |
| 10–12절 | RetinaNet 구조와 dense 출력 | Proposal별 두 번째 단계가 사라지면 무엇이 남는가? |
| 13–14절 | Focal loss, prior 초기화, 후처리 | 배경이 많은 상태에서 어떻게 학습하고 중복을 줄이는가? |
| 15–17절 | RetinaNet 학습과 두 구조의 종합 비교 | 구조 차이와 실제 성능 차이를 어떻게 분리해 읽는가? |

개념 설명은 [Lecture 6: Two-Stage Object Detection]({{ "/study/autonomous-driving/lecture-06-perception-04/" | relative_url }})과 [Lecture 7: Single-Stage Object Detection]({{ "/study/autonomous-driving/lecture-07-perception-05/" | relative_url }})에 연결된다. 여러 인지 기술의 위치는 [Perception Overview]({{ "/study/autonomous-driving/perception-overview/" | relative_url }})에서 함께 볼 수 있다.

## 1. 실습에서 비교하는 것은 무엇인가

### 1.1 Two-stage는 네트워크를 두 번 실행한다는 뜻이 아니다

Faster R-CNN의 두 단계는 **RPN이 후보 영역을 만드는 단계**와 **RoI head가 후보별 클래스·위치를 결정하는 단계**다. 두 단계는 같은 backbone feature를 공유한다. 이미지 전체를 독립적인 CNN 두 개에 각각 넣는 방식으로 이해하면 계산 흐름을 잘못 짚게 된다.

```text
Faster R-CNN
Image → Transform → Backbone + FPN
      → RPN: objectness + box offset
      → proposal filtering → RoIAlign → class + box refinement
      → final filtering

RetinaNet
Image → Transform → Backbone + FPN
      → dense class logits + box offsets
      → final filtering
```

RetinaNet에도 convolution layer와 후처리는 여러 개 있다. One-stage라는 이름은 layer가 하나이거나 NMS가 없다는 뜻이 아니라, **선별된 proposal마다 두 번째 검출 head를 적용하지 않는다**는 뜻이다. 이 실습의 RetinaNet은 anchor 기반 모델이며, 모든 one-stage 모델이 anchor를 사용하는 것은 아니다.

### 1.2 `init`, `coco`, 직접 학습한 snapshot은 다르다

| 비교 대상 | 시작 가중치 | 읽어야 할 의미 |
|---|---|---|
| `model_init`, `retina_init` | ResNet-50 body는 ImageNet 사전학습, FPN·검출 head는 새 초기화 | 검출 기능을 아직 학습하지 않은 시작점 |
| `model_coco`, `retina_coco` | COCO 검출 checkpoint | 별도 대규모 데이터로 학습된 검출 기능 |
| Epoch snapshot | 초기 모델에서 Penn-Fudan으로 직접 학습 | 같은 실습 데이터에서 검출 기능이 변하는 과정 |

`weights=None`은 이 코드에서 **모든 부분을 무작위로 시작한다**는 뜻이 아니다. `weights_backbone`에 ImageNet의 `IMAGENET1K_V1` weight를 함께 지정하므로 ResNet body는 이미 학습되어 있다. 반대로 COCO 모델은 실습에서 15 epoch 학습한 결과물이 아니다.

## 2. 데이터와 좌표계를 먼저 읽는다

### 2.1 Instance mask가 bounding box 정답으로 바뀐다

Penn-Fudan은 170장의 보행자 이미지와 instance mask를 제공한다. Mask의 0은 배경이고 나머지 값은 서로 다른 사람을 나타낸다. `PennFudan.__getitem__()`은 각 instance의 pixel 좌표를 모아 bounding box를 만든다.

```python
ys, xs = np.where(mask == instance_id)
box = [xs.min(), ys.min(), xs.max() + 1, ys.max() + 1]
```

`+1`은 최대 pixel index를 box의 바깥 경계로 옮기는 역할을 한다. 예를 들어 x index 10–19를 차지하면 너비는 10 pixel이다. 경계를 `[10, 20]`으로 두어야 `x2 - x1 = 10`이 된다. 입력 box shape는 `[G, 4]`, label shape는 `[G]`이며, $$G$$는 정답 보행자 수다.

정렬한 파일 목록을 seed 0으로 섞고 처음 30장을 검증에, 나머지 140장을 학습에 사용한다. 학습에서는 확률 0.5로 좌우 반전을 수행한다. 이미지 너비가 $$W$$이면 box의 x 경계도 함께 바꾼다.

$$
x'_1=W-x_2,\qquad x'_2=W-x_1.
$$

이미지만 뒤집고 box를 유지하면 사람이 있는 위치와 정답 위치가 달라진다. 이 augmentation은 입력과 정답을 같은 좌표 변환으로 처리해야 한다.

### 2.2 Resize, normalization, padding은 서로 다른 작업이다

`model.transform()`은 RGB 값을 channel별로 정규화하고, 비율을 유지하며 resize한 뒤 batch tensor를 padding한다. 짧은 변의 목표는 600 pixel, 긴 변의 상한은 1,000 pixel이다. 긴 변 상한에 걸리면 짧은 변은 600보다 작아질 수 있다.

Normalization은 channel별로 다음과 같이 적용된다.

$$
z_c=\frac{x_c-\mu_c}{\sigma_c},\qquad
\mu=(0.485,0.456,0.406),\quad
\sigma=(0.229,0.224,0.225).
$$

`to_display()`는 $$x_c=z_c\sigma_c+\mu_c$$로 이를 되돌리고 padding을 잘라 화면에 보인다. 이 함수가 필요한 이유는 모델 입력 tensor와 눈으로 보는 RGB 이미지가 같은 값 범위를 사용하지 않기 때문이다.

| 좌표·shape | 용도 | 주의할 점 |
|---|---|---|
| 원본 이미지 `[3, H, W]` | `detect()`의 입력과 최종 검출 그림 | 반환 box는 원본 크기로 복원됨 |
| `image_list.image_sizes` | Resize 후 유효 이미지 크기 | GT도 이 크기에 맞게 변환됨 |
| `image_list.tensors` | Padding까지 포함한 batch | Feature grid는 이 tensor에서 생성됨 |
| 중간 proposal·decoded box | 내부 단계 추적 | Resize 좌표의 GT와 비교해야 함 |

`rpn_dissect()`와 `os_dissect()`는 내부 후처리까지 풀어 놓은 함수다. 그 안의 box를 원본 크기의 이미지에 그대로 올리면 위치가 어긋난다. Notebook이 중간 단계에는 `disp`·`gt_boxes`, 최종 `detect()`에는 `img`·`tgt['boxes']`를 사용하는 이유다.

## 3. Backbone, FPN, anchor는 어떤 역할인가

### 3.1 FPN은 서로 다른 크기의 물체를 위한 feature 계층이다

Backbone은 pixel을 feature로 바꾼다. FPN은 서로 다른 해상도의 feature를 연결해 높은 해상도에서도 상위 계층의 의미 정보를 이용하도록 한다. 이 notebook의 Faster R-CNN은 P2–P6, RetinaNet은 P3–P7을 사용한다.

작은 물체는 높은 해상도에서 더 많은 위치를 차지하므로 촘촘한 feature가 유리할 수 있다. 큰 물체에는 더 넓은 문맥과 큰 anchor가 필요하다. 특정 level만 항상 정답이라고 단정하기보다 GT 크기, anchor 크기, 실제 IoU를 함께 본다.

FPN 그림의 `f[0].abs().mean(0)`은 channel축의 절댓값 평균이다. 밝은 부분은 평균 activation 크기가 큰 위치다. **물체일 확률이나 분류 정확도 지도는 아니다.** 자동 색상 범위가 서로 다른 activation 그림에서는 밝기만으로 두 모델의 수치를 직접 비교할 수도 없다.

### 3.2 Anchor는 학습되는 박스가 아니라 기준 박스다

Anchor는 feature의 각 위치에 배치하는 고정된 크기·비율의 box template이다. 학습되는 것은 anchor 자체가 아니라 **anchor의 점수와 GT까지 이동할 offset을 예측하는 함수**다.

Faster R-CNN은 level마다 기본 크기 1개와 높이/너비 비율 3개를 조합하므로 위치당 3개를 둔다. 기본 크기는 32, 64, 128, 256, 512이다. RetinaNet은 각 level에서 scale 3개와 비율 3개를 조합하므로 위치당 9개를 둔다. 세로로 긴 보행자에는 높이/너비 비율 2인 anchor가 더 잘 맞을 수 있지만, 크기와 중심 위치도 IoU에 영향을 준다. <a href="https://docs.pytorch.org/vision/stable/_modules/torchvision/models/detection/faster_rcnn.html" target="_blank" rel="noopener">Torchvision Faster R-CNN 기본 구성</a>과 <a href="https://docs.pytorch.org/vision/stable/_modules/torchvision/models/detection/retinanet.html" target="_blank" rel="noopener">RetinaNet 기본 구성</a>은 이 차이를 명시한다.

Level $$l$$의 grid가 $$H_l\times W_l$$이고 위치당 anchor 수가 $$A_l$$이면 전체 anchor 수는 다음과 같다.

$$
N=\sum_l H_lW_lA_l.
$$

따라서 원문 비교표의 “약 12만 anchor”는 고정된 구조 상수가 아니다. **합성 grid 예제**로 padding된 입력을 608×800이라고 하고 다음 feature shape를 가정하면 두 모델의 수는 다르다.

| 모델 | 가정한 grid 크기 | 계산한 anchor 수 |
|---|---|---:|
| Faster R-CNN | 152×200, 76×100, 38×50, 19×25, 10×13 | $$3(30400+7600+1900+475+130)=121515$$ |
| RetinaNet | 76×100, 38×50, 19×25, 10×13, 5×7 | $$9(7600+1900+475+130+35)=91260$$ |

이 값은 trace image의 실제 출력이 아니다. 실행 때는 notebook이 출력하는 level별 shape와 anchor 수를 사용한다. 위치당 9개라는 이유만으로 RetinaNet 전체 anchor 수가 항상 Faster R-CNN의 세 배가 되지도 않는다.

## 4. RPN 정답은 어떻게 만들어지는가

### 4.1 IoU로 positive, negative, ignore를 나눈다

IoU는 두 box가 겹치는 면적을 합집합 면적으로 나눈 무차원 값이다.

$$
\operatorname{IoU}(a,g)=\frac{\operatorname{area}(a\cap g)}{\operatorname{area}(a)+\operatorname{area}(g)-\operatorname{area}(a\cap g)}.
$$

예를 들어 `[0, 0, 10, 10]`과 `[5, 0, 15, 10]`은 각각 면적 100, 교집합 50이므로 IoU는 $$50/(100+100-50)=1/3$$이다.

RPN은 각 anchor의 최대 GT IoU를 보고 label을 정한다.

| 조건 | Label | 학습에서의 역할 |
|---|---:|---|
| 최대 IoU ≥ 0.7 | 1 | 물체로 분류하고 위치도 보정 |
| 최대 IoU < 0.3 | 0 | 배경으로 분류 |
| 그 사이 | −1 | Loss에서 제외 |

여기에 `allow_low_quality_matches=True`가 적용되어 각 GT와 가장 잘 겹치는 anchor들도 positive로 확보한다. 최대 IoU 동률이면 여러 anchor가 지정될 수 있고, 0.7 아래의 positive도 생긴다. 원문의 단순 threshold 설명에 이 예외를 함께 읽어야 한다.

정답 label과 regression target은 **현재 모델의 예측 점수와 무관**하다. Resize된 GT와 anchor가 같으면 초기 모델에서도 학습된 모델에서도 RPN 정답은 같다. 모델은 이미 정해진 정답을 더 잘 예측하도록 학습된다.

### 4.2 모든 anchor를 그대로 학습하면 배경이 압도한다

RPN은 이미지당 최대 256개를 뽑고 positive 비율의 상한을 50%로 둔다. Positive가 충분하면 최대 128개이고, 부족하면 남는 자리를 negative로 채운다. **항상 positive 128개를 뽑는 규칙은 아니다.** Ignore는 sampling과 loss에서 빠진다.

Notebook의 IoU histogram에서 y축이 log scale인 이유는 매우 많은 낮은-IoU anchor와 적은 높은-IoU anchor를 같은 그림에서 보기 위해서다. 정답 분포가 얼마나 불균형한지 확인한 뒤, sampled anchor 그림으로 실제 loss에 참여하는 후보가 훨씬 적다는 점을 확인한다.

### 4.3 Box offset은 왜 이 형태인가

Anchor 중심과 크기를 $$(a_x,a_y,a_w,a_h)$$, GT를 $$(g_x,g_y,g_w,g_h)$$라고 하면 RPN의 기본 target은 다음과 같다.

$$
\begin{aligned}
t_x&=\frac{g_x-a_x}{a_w}, & t_y&=\frac{g_y-a_y}{a_h},\\
t_w&=\log\frac{g_w}{a_w}, & t_h&=\log\frac{g_h}{a_h}.
\end{aligned}
$$

중심 이동을 pixel 그대로 사용하면 같은 10-pixel 이동도 작은 box와 큰 box에 서로 다른 의미를 갖는다. Anchor의 너비·높이로 나누면 **기준 크기에 대한 상대 이동**이 된다. 크기는 차이가 아니라 비율로 표현하고 log를 취한다. 같은 배수의 확대·축소를 일관되게 나타내며, 역변환에서는 exponential을 사용해 양의 크기를 복원할 수 있다. 이 표현은 box 회귀를 위한 설계이며 물리 법칙에서 유일하게 도출되는 식은 아니다.

예측한 offset을 $$\hat t$$라고 하면 역변환은 다음과 같다.

$$
\begin{aligned}
\hat g_x&=a_x+a_w\hat t_x, & \hat g_y&=a_y+a_h\hat t_y,\\
\hat g_w&=a_w e^{\hat t_w}, & \hat g_h&=a_h e^{\hat t_h}.
\end{aligned}
$$

이는 앞 식을 중심 좌표와 크기에 대해 풀어 얻는다. Target을 정확히 예측했다면 $$a_we^{\log(g_w/a_w)}=g_w$$이므로 원래 GT 크기가 복원된다. 중심·크기는 pixel 단위이고 offset 네 개는 무차원이다. 너비·높이가 0인 box에는 나눗셈과 log가 정의되지 않는다.

**합성 계산:** anchor가 `(100, 80, 40, 80)`, GT가 `(110, 84, 48, 72)`이면 다음 target을 얻는다.

$$
(t_x,t_y,t_w,t_h)=(0.25,0.05,\log 1.2,\log 0.9)
\approx(0.25,0.05,0.182322,-0.105361).
$$

너비는 20% 커지고 높이는 10% 작아지는 이동이다. 원문 4절의 `box_coder.encode()`와 `decode_single()`은 이렇게 **target을 encode한 뒤 다시 decode하면 GT가 복원되는지** 직접 대조한다. 이때 복원 오차가 작은 것은 box 표현의 일관성을 확인한 것이지 모델이 그 offset을 학습했다는 증거는 아니다.

## 5. RPN 예측이 proposal로 줄어드는 과정

RPN head는 각 anchor에 objectness logit 1개와 box offset 4개를 출력한다. 각 level의 shape는 `[B, A, H, W]`, `[B, 4A, H, W]`이고, flatten한 순서는 anchor 순서와 맞아야 한다.

```python
obj, deltas = model.rpn.head(feature_list)
obj_flat, deltas_flat = concat_box_prediction_layers(obj, deltas)
proposals = model.rpn.box_coder.decode(deltas_flat, anchors)
```

`sigmoid(obj_flat)`은 objectness score다. 이 단계는 “보행자인가, 자동차인가”를 최종 결정하지 않고, 물체 후보를 골라 다음 단계로 넘긴다. 후처리에서는 level별 top-K, 이미지 경계 clipping, 너무 작은 box 제거, score 조건, level별 NMS와 최종 개수 제한을 적용한다. 기본 test 경로의 proposal 상한은 1,000, train 경로는 2,000이다. <a href="https://github.com/pytorch/vision/blob/main/torchvision/models/detection/rpn.py" target="_blank" rel="noopener">Torchvision RPN 구현</a>을 기준으로 보면 원문의 축약된 네 단계보다 실제 필터가 더 많다.

### 5.1 NMS는 같은 물체로 보이는 중복 후보를 억제한다

NMS는 score가 높은 box를 먼저 남기고, 그 box와 IoU가 threshold를 넘는 낮은-score 후보를 제거하는 절차를 반복한다. **정답 GT를 보고 제거하는 과정은 아니다.** RPN은 FPN level을 구분해 NMS를 수행하므로 서로 다른 level에서 나온 중복 proposal이 일부 남을 수 있다.

Notebook 5절의 “before NMS” 그림은 모든 decoded anchor box를, “after NMS”는 `filter_proposals()`가 반환한 box를 사용한다. 둘의 개수 차이에는 **top-K·clipping·크기 필터·NMS·최종 상한의 효과가 함께 포함**된다. 이 차이 전체를 NMS 하나의 순수 효과라고 해석하지 않는다. NMS만 비교하려면 같은 pre-NMS 후보 집합을 고정하고 NMS 직전·직후를 별도로 기록해야 한다.

최종 class별 NMS도 “사람당 반드시 박스 하나”를 보장하지 않는다. 중복이 남거나, 가까운 두 사람 가운데 하나가 잘못 억제될 수 있다. Threshold를 너무 낮추면 서로 다른 물체도 제거되기 쉽고, 높이면 중복이 더 많이 남는다.

### 5.2 Proposal이 놓친 물체는 다음 단계가 되살리기 어렵다

GT마다 top-K proposal과의 최대 IoU를 계산하면 첫 단계의 후보 품질을 볼 수 있다. K가 커질 때 정답 근처 proposal이 새로 포함되는지 확인한다. **적어도 하나의 좋은 후보가 있는가**와 **최종 클래스·box가 정확한가**는 다른 질문이다.

Objectness heatmap은 한 위치의 3개 anchor score 중 최댓값이다. 밝은 위치는 그중 한 anchor가 높은 점수를 받았다는 뜻이며, 모든 anchor가 좋거나 box가 정확하다는 뜻은 아니다. 그림과 proposal의 GT IoU를 함께 봐야 한다.

## 6. RoI head는 후보를 어떻게 다시 판단하는가

### 6.1 두 번째 단계도 별도의 정답·sampling이 있다

| 항목 | RPN | RoI head |
|---|---|---|
| 기준 box | 고정 anchor | 예측된 proposal |
| Positive IoU 기준 | 0.7과 low-quality match 예외 | 0.5 |
| 샘플 수 상한 | 이미지당 256 | 이미지당 512 |
| Positive 비율 상한 | 50% | 25% |
| 분류 | Object / background | Background를 포함한 클래스 softmax |
| 회귀 | Anchor 기준 offset | Proposal 기준 class별 offset |
| 학습 중 GT 추가 | 없음 | GT box를 proposal에 추가 |

RoI head는 학습 중 GT box 자체도 proposal에 넣어 positive 학습 기회를 확보한다. 따라서 training RoI 그림에 정확한 GT box가 보이는 것은 예상된 동작이다. **Inference에서 GT를 모델에 알려준다는 뜻은 아니다.**

RoI target에는 기본 box-coder weights `(10, 10, 5, 5)`가 곱해진다. RPN의 `(1, 1, 1, 1)`과 달라서 같은 상대 이동이어도 출력 target 값이 다르다. Decode에서는 이 가중치를 다시 나눠 복원한다. 서로 다른 stage의 target 숫자를 같은 척도로 비교하면 안 된다.

### 6.2 RoIAlign은 proposal별 feature 크기를 맞춘다

Proposal의 실제 크기는 제각각이지만 box head에는 고정된 크기의 feature가 필요하다. RoIAlign은 proposal 크기에 맞는 FPN level을 선택하고, 해당 영역에서 값을 보간해 7×7 feature를 만든다. 이 모델의 channel 수는 256이므로 RoI가 K개이면 출력 shape는 `[K, 256, 7, 7]`이다.

기본 level 배정은 다음 규칙을 사용한다.

$$
k=\operatorname{clamp}_{[2,5]}
\left(\left\lfloor4+\log_2\frac{\sqrt{wh}}{224}\right\rfloor\right).
$$

$$w,h$$는 resize된 이미지 좌표에서의 pixel 크기다. $$\sqrt{wh}=224$$이면 P4를 기준으로 하고, 크기가 두 배가 되면 log 항이 1 증가해 더 낮은 해상도의 level로 이동한다. 작은 경우에는 반대다. 이 식은 canonical size·level을 둔 **배정 규칙**이며 실행 구현에는 작은 수치 안정화 항이 포함될 수 있다.

RoIAlign은 경계를 정수 grid로 먼저 잘라 버리는 대신 fractional 위치의 feature를 bilinear interpolation한다. 인접 feature 값이 $$v_{00},v_{10},v_{01},v_{11}$$이고 상대 위치가 $$u,v\in[0,1]$$이면 보간값은 다음과 같다.

$$
\tilde v=(1-u)(1-v)v_{00}+u(1-v)v_{10}+(1-u)vv_{01}+uvv_{11}.
$$

가로·세로의 두 선형 보간을 적용해 얻는 식이다. Proposal별 feature 크기를 통일하면서 좌표 반올림으로 생기는 위치 오차를 줄인다. RoIAlign feature 그림도 channel 절댓값 평균이며, 분류 확률 그림과는 다르다.

### 6.3 Class와 box를 별도로 출력한다

`box_head`는 RoI feature를 `[K, 1024]` 표현으로 바꾸고, `box_predictor`는 class logits `[K, C]`와 class별 offsets `[K, 4C]`를 출력한다. 여기서 $$C$$는 background를 포함한 출력 column 수다. Softmax는 같은 RoI의 column들이 경쟁하도록 만든다.

같은 proposal이라도 선택한 class에 따라 적용하는 refinement가 다르다. 이후 낮은 score와 작은 box를 제거하고 class별 NMS·최종 개수 제한을 적용한다. 이 단계까지의 score는 RPN objectness와 다른 값이다.

## 7. RetinaNet에서는 무엇이 사라지고 무엇이 늘어나는가

RetinaNet의 `model.head()`는 모든 anchor에서 클래스 logits와 box offsets를 만든다. Proposal을 고른 뒤 RoI feature를 다시 추출하는 단계가 없고, box는 anchor에서 한 번 보정된다.

| 출력 | Shape | 의미 |
|---|---|---|
| `cls_logits` | `[N, C]` | Anchor별 각 class의 독립 logit |
| `sigmoid(cls_logits)` | `[N, C]` | 각 class의 score; class축 합이 1일 필요 없음 |
| `bbox_regression` | `[N, 4]` | Anchor별 공통 box offset |

RetinaNet의 분류 target은 유효 anchor의 각 class column에 대해 0 또는 1을 둔다. Background anchor는 **모든 class target이 0**이다. Faster R-CNN처럼 background를 softmax의 경쟁 class로 판정하지 않는다. 이 차이는 <a href="https://docs.pytorch.org/vision/stable/_modules/torchvision/models/detection/retinanet.html" target="_blank" rel="noopener">RetinaNet classification loss 구현</a>에서 확인할 수 있다.

### 이 notebook의 class index를 읽을 때

원문은 두 모델 모두 `CLASSES = ['__background__', 'pedestrian']`와 `num_classes=2`를 사용한다. Faster R-CNN에서는 column 0이 background, column 1이 pedestrian이다. **RetinaNet에서는 column 0도 sigmoid 출력이며 background의 상보 확률이 아니다.** 정답 label을 항상 1로 주므로 column 1만 positive 정답을 받고, column 0은 늘 negative target을 받는 추가 출력이다.

이 설정은 class index를 맞춰 실습을 이어 갈 수 있지만 두 모델의 background 의미까지 같게 만들지는 않는다. RetinaNet의 column 0을 `P(background)`로 읽거나 `p_0+p_1=1`로 가정하면 안 된다. Torchvision의 공개 API 문서는 `num_classes`를 background index를 포함하는 수로 설명한다. Output column을 임의로 줄이거나 label 0을 foreground로 재사용하는 변경은 공식 label 관례와 외부 evaluator의 호환성을 확인하고 학습·후처리·표시·평가를 함께 검증해야 한다. 첨부 원본은 수업 코드 그대로 보존한다.

또한 COCO의 `person` column은 weight metadata에서 조회한다. Custom dataset의 `pedestrian` label 1과 COCO class 이름을 대응시키는 것은 **같은 대상을 찾기 위한 label mapping**이지 두 모델의 class 집합이 같다는 뜻이 아니다.

## 8. Focal loss와 prior 초기화는 왜 함께 필요한가

### 8.1 Classification은 유효 anchor 전체, regression은 positive만

RetinaNet은 IoU ≥ 0.5를 positive, IoU < 0.4를 negative, 중간을 ignore로 분류하고 low-quality matching 예외도 적용한다. RPN처럼 256개로 줄이는 sampling은 없다. 하지만 원문의 “모든 anchor가 loss에 참여한다”는 표현에는 구분이 필요하다.

- **Classification loss:** ignore를 제외한 positive·negative anchor의 class column들에 적용한다.
- **Box regression loss:** positive anchor에만 적용한다. 배경에는 회귀할 GT box가 없다.

Torchvision의 이 RetinaNet v1 회귀는 기본 L1 loss다. 각 이미지의 loss는 positive 수로 정규화하며 positive가 없을 때는 분모를 최소 1로 둔다. Focal loss를 쓰더라도 모든 위치의 box를 정답에 억지로 맞추는 것은 아니다.

### 8.2 Focal loss는 이미 쉬운 예제의 기여를 줄이는 설계다

Foreground class의 sigmoid score를 $$p$$, binary target을 $$y\in\{0,1\}$$라 두면 정답 class 쪽 확률은 다음과 같다.

$$
p_t=yp+(1-y)(1-p).
$$

Positive에서는 $$p_t=p$$이고, negative에서는 $$p_t=1-p$$이다. Binary cross entropy는 $$-\log p_t$$다. Focal loss는 여기에 난이도에 따른 가중치를 곱한다.

$$
\operatorname{FL}(p_t)=-\alpha_t(1-p_t)^\gamma\log p_t,
\qquad
\alpha_t=\begin{cases}\alpha,&y=1,\\1-\alpha,&y=0.\end{cases}
$$

Notebook의 실제 loss 호출은 $$\alpha=0.25,\gamma=2$$를 사용한다. 잘 맞힌 경우 $$p_t\approx1$$이면 $$(1-p_t)^\gamma$$가 매우 작아져 loss 기여가 줄어든다. 어려운 경우에는 이 억제가 작다. $$\gamma=0$$이면 modulation이 사라지지만 $$\alpha_t$$를 남기면 일반 BCE가 아니라 **class 가중 BCE**다. 원문 focal curve는 $$\alpha_t$$를 생략해 modulation의 효과만 보여준다.

이 식은 CE의 필연적인 항등 변형이 아니라, 많은 쉬운 배경이 학습을 지배하지 않도록 도입한 목적함수 설계다. Focal loss가 모든 배경을 제거하거나 모든 어려운 예제의 정확도를 보장하지는 않는다.

**별도 합성 계산:** foreground score가 0.01일 때 같은 score라도 label에 따라 의미가 완전히 달라진다.

| Target | 정답 쪽 확률 $$p_t$$ | BCE | Focal loss, $$\alpha=0.25,\gamma=2$$ |
|---|---:|---:|---:|
| Negative, $$y=0$$ | 0.99 | 0.0100503 | 0.0000007538 |
| Positive, $$y=1$$ | 0.01 | 4.6051702 | 1.1283818 |

대부분이 negative일 때는 이미 낮은 foreground score를 낸 쉬운 배경의 기여를 크게 줄이고, 놓친 positive는 여전히 큰 loss를 받는다. Loss 합의 **절대 크기**와 background의 **비율**은 별개다. 원문 막대그래프에서 negative 비율이 얼마나 줄어드는지는 실제 positive 수와 logits에 달려 있으며 항상 같은 비율로 줄어들지는 않는다. 이 표와 CE·focal 지도는 person column 하나만 계산한 관찰용 분석이다. 실제 학습 loss는 유효 anchor의 모든 class column을 사용하고 positive 수로 정규화하므로 여기 표시한 합과 동일하지 않다.

### 8.3 Prior 0.01은 정답 분포를 강제하는 규칙이 아니다

RetinaNet은 분류 head bias를 낮은 foreground prior $$\pi=0.01$$에 맞춰 초기화한다. Sigmoid 식을 bias에 대해 풀면 다음을 얻는다.

$$
\pi=\frac{1}{1+e^{-b}}
\quad\Longrightarrow\quad
b=\log\frac{\pi}{1-\pi}
\approx-4.595120.
$$

최종 layer의 작은 초기 weight와 이 bias 때문에 시작 score는 대략 0.01 근처다. 모든 입력의 score가 정확히 0.01로 같지는 않다. 이미지의 정답 보행자 비율을 1%로 고정하거나, 학습 이후 확률을 1% 이하로 제한하는 것도 아니다.

처음부터 대부분의 anchor가 foreground score 0.5를 내면 매우 많은 배경 위치가 큰 기여를 낸다. 낮은 초기 prior는 이 시작 상태를 완화하고, focal loss는 학습 중 이미 쉬운 예제의 기여를 계속 낮춘다. 초기 RetinaNet에서 threshold 0.05 이상의 검출이 적게 보일 수 있는 이유는 이 초기화와 연결된다. **검출 수가 적다는 사실만으로 잘 학습된 모델이라고 판단할 수는 없다.**

## 9. Dense 출력이 최종 검출이 되는 과정

RetinaNet은 class score threshold를 적용하고 level별 상위 후보를 제한한 뒤 offset을 decode·clip하고, class별 NMS와 최종 개수 제한을 적용한다. 확인한 Torchvision 기본값은 score threshold 0.05, NMS threshold 0.5, level별 후보 상한 1,000, 최종 검출 상한 300이다. 실행 버전에서 출력되는 설정을 함께 확인해야 한다.

원문 14절의 `top-300` 그림은 **person column만** score 상위 300개를 골라 decode한 관찰용 그림이다. 실제 `postprocess_detections()`는 **모든 class column**을 대상으로 level별 후보를 만든다. 따라서 이 그림의 300개가 그대로 최종 그림으로 넘어간다고 해석하면 안 된다. `n_thr` 역시 person column의 개수이지만 `len(d['boxes'])`는 모든 class의 최종 개수다.

최종 그림에는 다시 score > 0.5 조건이 적용된다. 내부 threshold 0.05와 표시 threshold 0.5가 다르므로 “모델이 반환한 box 수”와 “그림에 그려진 box 수”도 다를 수 있다.

## 10. 그래프를 어떻게 읽어야 하는가

| 그림·출력 | 실제로 표시하는 것 | 확인할 질문 |
|---|---|---|
| FPN activation | Channel별 절댓값 평균 | Level별 공간 해상도와 표현이 어떻게 다른가? |
| Anchor template·grid | 고정된 크기·비율과 위치 | GT와 크기·비율·중심이 맞는 template이 있는가? |
| Positive·ignore·negative box | IoU로 만든 정답 분류 | 어떤 후보가 loss에서 빠지고 왜 sampling이 필요한가? |
| Regression target·복원 오차 | GT offset 표현과 encode/decode | 좌표·크기를 다시 복원하는 계산이 맞는가? |
| Objectness heatmap | 위치별 RPN anchor score 최댓값 | 물체 근처 후보가 높은 score를 받는가? |
| Proposal와 RoI refinement | 첫 단계와 두 번째 단계의 box | 후보 coverage와 최종 위치 정확도가 따로 좋아지는가? |
| Softmax 막대그래프 | 특정 RoI의 class별 확률 | Background와 foreground가 어떤 경쟁을 하는가? |
| RetinaNet class heatmap | 선택한 class의 위치별 score 최댓값 | 별도 objectness 없이 class가 직접 어디서 반응하는가? |
| CE·focal loss 지도 | Class loss의 위치별 합 | 쉬운 배경의 절대 기여가 얼마나 작아지는가? |
| Epoch별 세 칸 비교 | Score 지도·중간 후보·최종 검출 | 어느 단계의 변화가 최종 개선으로 연결되는가? |

Heatmap은 해부를 돕는 그림이지 pixel 단위 정답 mask가 아니다. 특히 coarse level에서 원문 overlay는 `padded_width / feature_width`를 가로·세로에 공통 적용한다. 실제 anchor generator의 정수 stride와 축별 간격이 다를 수 있어 작은 정렬 오차가 생긴다. 정확한 위치 대조에는 heatmap 배경색보다 **실제 anchor center와 box 좌표**를 우선한다.

Loss map의 제목에 표시한 합은 모든 level의 합이고 화면에 보이는 map은 P3뿐이다. 큰 숫자가 P3 한 장의 합이라고 혼동하지 않는다. CE와 focal은 동일한 색 범위로 그리므로 밝기 감소는 loss 기여 감소를 보여 주지만 검출 정확도를 직접 표시하지는 않는다.

## 11. 직접 학습하는 코드의 흐름

| 설정 | Faster R-CNN | RetinaNet |
|---|---:|---:|
| Epoch | 15 | 15 |
| Batch size | 2 | 2 |
| 초기 learning rate | 0.01 | 0.005 |
| Optimizer | SGD, momentum 0.9 | SGD, momentum 0.9 |
| Weight decay | 0.0001 | 0.0001 |
| Snapshot epoch | 0, 1, 3, 8, 15 | 0, 1, 3, 8, 15 |
| Gradient norm 상한 | 10 | 10 |

140장과 batch size 2를 사용하면 epoch당 70 iteration, 전체 1,050 iteration이다. Warm-up은 `min(200, total // 5)`이므로 200 iteration이다. Learning rate를 처음부터 크게 적용하지 않고 선형으로 올린 다음 cosine schedule로 줄인다. 이 계산도 설정으로부터 얻는 값이며 실제 실행 시간을 측정한 값은 아니다.

한 iteration은 다음 흐름으로 읽는다.

```python
loss_dict = model(images, targets)   # train(): 정답으로 학습 loss 계산
loss = sum(loss_dict.values())
optimizer.zero_grad(set_to_none=True)
loss.backward()                     # 각 학습 parameter의 gradient
clip_grad_norm_(parameters, 10.0)
optimizer.step()                    # parameter 갱신
scheduler.step()                    # 다음 iteration의 learning rate
```

원문은 CUDA에서 autocast·GradScaler를 사용한다. Scale된 gradient를 먼저 unscale한 뒤 clipping해야 실제 gradient norm 기준으로 제한된다. `train()`에서는 loss dictionary, `eval()`에서는 검출 dictionary가 반환된다. `torch.no_grad()`는 해부·평가 시 gradient graph를 만들지 않도록 한다.

Faster R-CNN의 네 loss는 objectness, RPN box, RoI class, RoI box에 대응한다. RetinaNet은 classification과 box regression의 두 loss다. **Loss가 네 개냐 두 개냐로 모델이 더 정확한지 결정하지 않는다.** 두 모델은 정규화·대상·목적함수가 달라 전체 loss의 크기도 직접 경쟁 점수가 아니다.

`params = [p for p in model.parameters() if p.requires_grad]`는 학습이 허용된 parameter만 optimizer에 넣는다. 이 코드가 사용하는 사전학습 backbone의 기본 설정에서는 마지막 3개 ResNet stage를 학습하고 앞부분은 고정한다. `train()`을 호출했다고 모든 backbone layer의 weight를 갱신하는 것은 아니다. 다른 Torchvision 버전이나 `trainable_backbone_layers` 변경 시에는 실제 `requires_grad`를 다시 확인한다.

Snapshot은 같은 trace image에서 epoch별 변화를 비교하기 위한 기록이다. Seed를 고정해도 GPU 연산, augmentation·data-loader 순서, library 버전이 다르면 완전한 bitwise 재현을 보장하지 않는다. 첫 환경 cell의 torch·torchvision version과 실행 환경을 결과에 함께 남기는 편이 좋다.

## 12. 평가 지표가 말하는 것과 말하지 않는 것

### 12.1 Proposal recall은 첫 단계의 후보 coverage다

GT가 $$G$$개이고 top-K proposal 집합을 $$\mathcal P_K$$라고 할 때 threshold $$\tau$$의 proposal recall은 다음과 같다.

$$
R_{\mathrm{proposal}}(K,\tau)=\frac{1}{G}
\sum_{j=1}^{G}\mathbf 1\left[
\max_{b\in\mathcal P_K}\operatorname{IoU}(b,g_j)\ge\tau
\right].
$$

각 GT에 충분히 가까운 proposal이 하나라도 있으면 1을 세고 전체 GT 수로 나눈 정의다. Notebook은 K=100, IoU 0.5와 0.7을 사용한다. GT 4개 중 3개에 IoU ≥ 0.5 후보가 있고 2개만 IoU ≥ 0.7이면 두 recall은 각각 0.75와 0.5다. 이것은 별도 예제이며 실제 validation 값이 아니다.

Proposal recall이 낮으면 첫 단계가 GT를 놓쳤을 가능성이 크다. 높지만 최종 recall이 낮으면 RoI class·refinement·score threshold·최종 NMS를 따로 살핀다. 최종 성능을 한 숫자로만 보면 개선할 단계가 가려진다.

### 12.2 Detection precision과 recall은 최종 판단이다

최종 box를 score 순서대로 처리하고, class가 같은 아직 사용하지 않은 GT와 IoU ≥ 0.5일 때 TP로 센다. GT 하나는 한 번만 사용할 수 있으므로 같은 사람을 두 번 검출하면 추가 box는 FP가 된다.

$$
\operatorname{Precision}=\frac{TP}{TP+FP},\qquad
\operatorname{Recall}=\frac{TP}{TP+FN}.
$$

정답 4명에 검출 5개가 있고 3개가 올바르게 매칭되면 $$TP=3,FP=2,FN=1$$이므로 precision은 0.6, recall은 0.75다. Precision은 반환한 검출의 정확성을, recall은 정답을 얼마나 놓치지 않았는지 나타낸다.

원문 평가 함수는 score **≥ 0.5**를 쓰고, 그림은 주로 **> 0.5**를 쓴다. 실제 score가 정확히 0.5인 경계에서는 집계가 다를 수 있다. 이 평가에는 threshold를 바꾸며 누적하는 AP나 여러 IoU threshold를 평균한 COCO mAP 계산이 없다. **고정 threshold의 P/R을 mAP라고 부르면 안 된다.**

### 12.3 이 실습만으로 속도·정확도 우열을 결론내리지 않는다

두 모델은 같은 이미지와 같은 split을 보지만 FPN level, anchor 수, class head, learning rate, 검출 개수 상한이 다르다. COCO 비교 그림은 출력하는 class가 여러 개이고, Penn-Fudan 정답은 보행자 중심이다. 원문이 언급하는 일부 미라벨 사람의 존재는 이 미실행 파일만으로 확인되지 않으므로 개별 이미지·annotation을 대조하기 전 일반적 사실로 단정하지 않는다.

Notebook의 경과 시간 출력은 **훈련 loop의 누적 시간**이다. CUDA 동기화·warm-up·반복 추론을 갖춘 inference latency benchmark가 아니다. 자율주행에서 중요한 속도 비교를 하려면 같은 하드웨어·입력·batch·precision 조건에서 전처리, 모델, 후처리 시간을 같은 범위로 측정해야 한다.

Penn-Fudan에서 보행자를 잘 검출해도 먼 거리의 작은 물체, 야간, 악천후, 가림, 다양한 도로 객체에 대한 성능이 증명되는 것은 아니다. 이 실습은 그런 시스템 평가에 앞서 **실패가 후보 단계인지 분류·위치 단계인지 진단하는 관점**을 제공한다.

## 마지막 핵심 정리

1. Anchor와 정답 target은 기준이다. 학습은 그 기준에 맞는 score와 offset을 예측하는 능력을 바꾼다.
2. Faster R-CNN은 RPN의 후보 coverage와 RoI head의 최종 판단을 분리해 볼 수 있다. Backbone feature는 공유한다.
3. RetinaNet은 proposal별 두 번째 단계를 없애고 class를 밀집 예측한다. Background는 독립적인 softmax class가 아니라 foreground target이 모두 0인 상태다.
4. Focal loss는 쉬운 예제의 기여를 줄인다. Prior 초기화는 많은 배경이 있는 학습의 시작 상태를 완화한다.
5. Activation, score, loss, recall은 서로 다른 양이다. 밝은 그림이나 낮은 loss 하나로 검출 성공을 단정하지 않는다.
6. 최종 박스뿐 아니라 **정답 생성, 중간 후보, 후처리 조건, 평가 정의**를 함께 추적해야 두 구조의 차이가 보인다.

## Study Guide

- **첫 번째 읽기:** 1–3절에서 입력 좌표·FPN·anchor를 구분한다. Shape의 축을 직접 말할 수 있는지 확인한다.
- **두 번째 읽기:** 4–6절에서 label 할당, sampling, target encoding, proposal 선별, RoI refinement를 이어 본다. 정답을 만드는 코드와 예측하는 코드를 분리한다.
- **세 번째 읽기:** 7–9절에서 sigmoid와 softmax, focal loss와 prior, 관찰용 top-K와 실제 후처리를 구분한다.
- **실행 후 읽기:** 동일한 trace image의 epoch별 세 그림을 대조하고 proposal recall·최종 P/R을 함께 확인한다. 원본에는 저장 출력이 없으므로 실제 숫자는 실행 기록과 함께 읽는다.

## 복습 질문

<details markdown="block">
<summary>1. ImageNet backbone을 쓰는 초기 모델은 왜 보행자 검출을 아직 잘하지 못할 수 있는가?</summary>

답변: ImageNet 사전학습은 ResNet body에 적용된다. FPN, RPN, RoI head 또는 RetinaNet head는 새로 초기화되어 objectness, box offset, 검출 class를 학습하지 않았다. 이미지 feature를 추출할 능력과 정확한 검출을 할 능력은 같지 않다.

</details>

<details markdown="block">
<summary>2. RPN target이 초기 모델과 학습된 모델에서 같을 수 있는 이유는 무엇인가?</summary>

답변: 같은 resize GT와 같은 anchor에 대해 IoU label과 box offset이 결정되기 때문이다. Target을 만드는 데 현재 예측 logits나 가중치를 사용하지 않는다. 학습 전후에 달라지는 것은 target이 아니라 그것을 예측하는 함수다.

</details>

<details markdown="block">
<summary>3. Proposal recall은 높은데 최종 detection recall이 낮다면 어디를 살펴보는가?</summary>

답변: 첫 단계에는 GT 근처 후보가 있다는 뜻이므로 RoI class score, box refinement, 표시·평가 threshold, 최종 NMS와 개수 제한을 살펴본다. Recall threshold와 proposal K도 같게 두어야 비교가 된다. 후보가 있다는 사실이 최종 올바른 class·box를 보장하지 않는다.

</details>

<details markdown="block">
<summary markdown="span">4. Negative anchor의 foreground score가 $$p=0.01$$이면 focal loss에서 왜 쉬운 예제인가?</summary>

답변: Negative의 정답 쪽 확률은 $$p_t=1-p=0.99$$다. $$\gamma=2$$이면 modulation은 $$(1-0.99)^2=0.0001$$이 되어 BCE 기여를 크게 낮춘다. 같은 0.01이라도 positive에서는 정답 쪽 확률이 0.01이라 큰 loss가 남는다.

</details>

<details markdown="block">
<summary>5. RetinaNet에서 class score 두 개의 합이 1이 아닌 이유는 무엇인가?</summary>

답변: 각 column에 sigmoid를 독립적으로 적용하기 때문이다. Background anchor는 모든 foreground target이 0인 상태다. 이 notebook의 추가 column 0도 background softmax 확률이 아니므로 pedestrian column과 합쳐 1이 된다고 가정하지 않는다.

</details>

<details markdown="block">
<summary>6. NMS 전후 box 개수 차이를 모두 NMS의 효과라고 볼 수 있는가?</summary>

답변: 원문 RPN 비교에서는 NMS 뒤의 집합에 top-K, clipping, 작은 box 제거와 개수 상한도 적용되어 있으므로 그렇지 않다. NMS 자체를 분석하려면 동일한 후보 집합을 NMS에 넣고 직전·직후를 따로 비교해야 한다. RetinaNet의 person-only 관찰 그림과 all-class 후처리 역시 같은 집합이 아니다.

</details>

<details markdown="block">
<summary>7. 이 notebook이 직접 입증하는 모델 성능 수치는 무엇인가?</summary>

답변: 제공된 파일에는 저장 출력이 없어 실제 학습 성능 수치를 입증하지 않는다. 코드에서 비교 설계와 계산 방법은 확인할 수 있다. 실제 성능은 실행 버전·데이터 split·threshold와 함께 저장한 결과로 확인해야 하며, 고정 threshold P/R이나 훈련 시간은 mAP·추론 latency를 대신하지 않는다.

</details>

## Source Check

검토 범위는 원문 74개 cell 전체, 저장 출력 유무, 모델 구성·target·후처리·평가 코드다. Box encode/decode, IoU, focal loss, prior bias, anchor 수와 P/R 예제는 별도 작은 수치 계산으로 대조했다. 실제 모델 가중치 다운로드, 추론과 15-epoch 학습은 수행하지 않았다.

원문의 “모든 anchor”, “약 12만”, “사람당 박스 하나”, RetinaNet background column 설명은 각각 ignore·regression 구분, 입력 shape 의존성, NMS의 비보장성, 실제 target column에 맞춰 위 본문에서 풀어 썼다. 원본 notebook은 수정하지 않았다. Runtime 버전이 저장되지 않았으므로 공식 구현 확인은 아래 Torchvision 문서·소스의 확인 시점 기준이며, 실제 실행에서는 첫 cell의 버전 출력과 설정을 함께 확인한다.

## Source Materials

<ul>
  <li><a href="{{ "/assets/materials/study/autonomous-driving/adc-lab-01-two-stage-vs-one-stage.ipynb" | relative_url }}" download data-no-resource-reader>Download source notebook</a> — ADC_<wbr>Lab1_<wbr>TwoStage_<wbr>vs_<wbr>OneStage.ipynb</li>
  <li><a href="https://docs.pytorch.org/vision/stable/_modules/torchvision/models/detection/faster_rcnn.html" target="_blank" rel="noopener">Torchvision Faster R-CNN implementation</a></li>
  <li><a href="https://docs.pytorch.org/vision/stable/_modules/torchvision/models/detection/retinanet.html" target="_blank" rel="noopener">Torchvision RetinaNet implementation</a></li>
  <li><a href="https://github.com/pytorch/vision/blob/main/torchvision/models/detection/rpn.py" target="_blank" rel="noopener">Torchvision RPN implementation</a></li>
</ul>
