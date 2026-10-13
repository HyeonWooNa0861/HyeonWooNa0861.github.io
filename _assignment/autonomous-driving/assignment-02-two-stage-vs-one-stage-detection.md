---
layout: default
date: 2026-10-13 17:00:00 +0900
title: "Autonomous Driving Computing Assignment 2: Two-Stage vs One-Stage Detection"
course: "Autonomous Driving"
topic: "Faster R-CNN and RetinaNet"
order: 2
major_topic: "Autonomous Systems"
keywords:
  - "Faster R-CNN"
  - "RetinaNet"
  - "Region Proposal Network"
  - "Focal Loss"
  - "Anchor"
---

# Autonomous Driving Computing Assignment 2: Two-Stage vs One-Stage Detection

Source Materials: [Two-stage vs one-stage detection lab notebook (outputs cleared)]({{ "/assets/notebooks/study/autonomous-driving/assignment-02-two-stage-vs-one-stage.ipynb" | relative_url }}){:target="_blank" rel="noopener"}

## 과제 개요

이 과제는 Penn-Fudan 보행자 데이터의 같은 이미지를 Faster R-CNN과 RetinaNet에 넣고, 최종 box뿐 아니라 중간 tensor와 학습 target을 비교한다.

**핵심 메시지:** Two-stage와 one-stage의 차이는 CNN을 몇 번 호출하는지가 아니다. Faster R-CNN은 dense anchor에서 object proposal을 먼저 고른 뒤 각 proposal을 다시 분류·보정한다. RetinaNet은 모든 위치에서 class와 box를 바로 예측하며, 그 대신 압도적으로 많은 쉬운 배경 anchor를 focal loss로 약화한다.

공개 notebook은 식별 정보와 저장 출력을 제거한 학습용 코드다. 아래 수치·형상·그림은 로컬 원본에 저장된 CUDA 실행 결과를 읽은 것이며, 독립적으로 재실행해 검증한 값은 아니다.

## 전체 흐름

```text
Faster R-CNN
image → transform → ResNet-50 + FPN
      → anchor → RPN objectness + offset
      → proposal filtering → RoIAlign
      → class + second box refinement → final NMS

RetinaNet
image → transform → ResNet-50 + FPN
      → dense class logits + box offsets
      → score filtering + NMS
```

두 모델 모두 backbone, FPN, anchor, classification, box regression을 사용한다. 차이는 **proposal을 명시적으로 선별해 두 번째 head로 보내는가**에 있다.

## 1. 입력과 FPN

Penn-Fudan dataset의 instance mask에서 각 사람의 pixel 범위를 찾아 box $$(x_1,y_1,x_2,y_2)$$를 만든다. 입력 image는 normalization, aspect-ratio preserving resize, batch padding을 거친다.

저장 출력의 trace image는 원래 391×533 pixel이며, 유효 image가 600×817로 resize된 뒤 batch tensor는 608×832가 됐다. Faster R-CNN의 FPN shape는 다음과 같다.

| Level | Tensor shape | Approximate stride |
| --- | --- | ---: |
| P2 | 1×256×152×208 | 4 |
| P3 | 1×256×76×104 | 8 |
| P4 | 1×256×38×52 | 16 |
| P5 | 1×256×19×26 | 32 |
| P6 | 1×256×10×13 | 64 |

촘촘한 P2는 작은 물체의 위치를 더 세밀하게 보존하고, P5·P6는 넓은 문맥과 큰 anchor를 제공한다. FPN activation 그림은 channel별 절댓값의 평균이며 object probability 그 자체가 아니다.

## 2. Faster R-CNN: 후보를 만들고 다시 판정한다

### 2.1 Anchor와 RPN target

Faster R-CNN은 각 FPN 위치에 비율 0.5, 1, 2의 anchor 세 개를 둔다. 저장 출력에서는 총 126,360개였다. Anchor는 학습 parameter가 아니라 고정 template다. 모델은 각 anchor의 objectness와 GT까지의 offset을 예측한다.

$$
t_x=\frac{g_x-a_x}{a_w},\quad
t_y=\frac{g_y-a_y}{a_h},\quad
t_w=\log\frac{g_w}{a_w},\quad
t_h=\log\frac{g_h}{a_h}
$$

중심 이동은 anchor 크기로 정규화되고, 크기 변화는 비율의 log로 표현되므로 네 target은 무차원이다. 너비나 높이가 0인 box에는 이 표현을 사용할 수 없다.

Trace image의 RPN label은 positive 17개, negative 125,811개, ignore 532개였다. Positive 17개 중 9개는 각 GT의 best anchor를 보장하는 low-quality matching으로 추가됐다. Loss에는 positive 17개와 negative 239개, 총 256개만 sampling됐다.

<details markdown="block">
<summary markdown="span">Derivation: Why box encoding reconstructs the target box</summary>

풀이과정:

예측값이 target과 정확히 같다고 두면 중심은

$$
a_x+a_wt_x=a_x+a_w\frac{g_x-a_x}{a_w}=g_x
$$

로 복원된다. 너비는

$$
a_we^{t_w}=a_we^{\log(g_w/a_w)}=g_w
$$

가 된다. 따라서 encode한 target을 정확히 decode하면 GT가 복원된다. 이는 표현식의 역관계를 확인하는 계산이며, 실제 network가 target을 정확히 예측했다는 증거는 아니다.

</details>

### 2.2 Proposal과 두 번째 단계

RPN은 offset을 decode하고 level별 top-K, clipping, 작은 box 제거, NMS를 거쳐 proposal을 만든다. 저장 출력에서 COCO-trained RPN은 네 GT에 대해 top-10 proposal만으로 best IoU 0.80–0.92를 만들었다. 초기 RPN은 top-1000을 사용해도 best IoU가 0.22–0.36에 머물렀다.

RoI head는 proposal을 새로운 기준 box처럼 취급한다.

| Property | RPN | RoI head |
| --- | --- | --- |
| Reference | Fixed anchor | RPN proposal |
| Positive threshold | IoU ≥ 0.7, with best-match exception | IoU ≥ 0.5 |
| Sample count | 256, positive at most 50% | 512, positive at most 25% |
| Classification | Object/background | Classes plus background |
| Regression | Anchor → GT | Proposal → class-specific GT offset |

RoIAlign은 크기가 서로 다른 proposal을 FPN level에서 잘라 256×7×7 tensor로 맞춘다. 이 고정 크기 feature가 class score와 class-specific box offset의 입력이 된다.

## 3. RetinaNet: 모든 anchor에서 바로 예측한다

RetinaNet은 P3–P7 각 위치에 3 scales × 3 aspect ratios, 총 9개 anchor를 둔다. Trace image의 저장 출력은 94,851개 anchor와 91개 class logit, 4개 box offset을 기록한다.

Proposal과 RoIAlign이 없는 대신 모든 유효 anchor가 classification loss에 참여한다. 저장된 label 분포는 positive 77, negative 94,606, ignore 168로, negative가 positive의 약 1,229배였다.

### Focal loss가 필요한 이유

Binary focal loss는 정답 class에 부여한 probability $$p_t$$에 대해

$$
\operatorname{FL}(p_t)=-\alpha_t(1-p_t)^\gamma\log p_t
$$

로 정의된다. $$p_t$$가 1에 가까운 쉬운 sample은 $$(1-p_t)^\gamma$$가 작아져 gradient 기여가 줄어든다. 어려운 positive나 잘못 분류한 negative에 상대적으로 더 집중한다.

RetinaNet은 초기 foreground probability가 약 0.01이 되도록 classification bias를 초기화한다. “대부분 배경”이라는 시작 prior와 focal loss를 함께 사용해 초기 negative loss 폭증을 줄인다.

저장된 단일-image 계산에서 prior $$p\approx0.01$$과 focal loss를 함께 썼을 때 negative loss 합은 0.07, positive loss 합은 86.94였다. 이 값은 해당 trace image와 저장 실행의 합계이며 일반적인 비율이나 성능 지표가 아니다.

<details markdown="block">
<summary markdown="span">Derivation: How focal loss suppresses easy examples</summary>

풀이과정:

$$\gamma=2$$일 때 정답 probability가 0.9인 쉬운 sample의 조절 항은

$$
(1-0.9)^2=0.01
$$

이다. 같은 cross-entropy를 1% 규모로 줄인다. 반면 $$p_t=0.2$$인 어려운 sample은

$$
(1-0.2)^2=0.64
$$

이므로 신호가 훨씬 많이 남는다. Focal loss는 negative를 무조건 버리는 sampling이 아니라, 현재 모델이 쉽게 맞히는 sample의 가중치를 연속적으로 줄이는 방법이다.

</details>

## 4. 저장된 학습 결과를 읽는 법

Notebook은 seed 0, Penn-Fudan train 140장·validation 30장, 15 epochs, batch size 2 설정을 저장한다.

| Model | Stored final metric condition | Precision | Recall |
| --- | --- | ---: | ---: |
| Faster R-CNN | Epoch 15, score ≥ 0.5, IoU ≥ 0.5 | 0.886 | 0.963 |
| RetinaNet | Epoch 15, score ≥ 0.5, IoU ≥ 0.5 | 0.907 | 0.963 |

Faster R-CNN의 proposal recall@100은 epoch 15에서 IoU 0.5 기준 1.000, IoU 0.7 기준 0.951로 저장돼 있다. 이는 첫 단계가 GT 근처 후보를 얼마나 제공하는지 나타내며, 최종 class 판정의 정확도와는 다르다.

이 수치로 RetinaNet이 항상 우수하다고 결론 내릴 수 없다. Dataset이 작고 pedestrian 한 class에 집중하며, validation split과 seed가 하나고, COCO AP가 아니라 고정 score·IoU 기준 precision/recall을 사용한다. 동일한 compute budget이나 여러 seed 비교도 없다.

## 5. Two-Stage와 One-Stage의 학습 차이

| Question | Faster R-CNN | RetinaNet |
| --- | --- | --- |
| Where is objectness decided? | RPN | Class head itself |
| Is there proposal selection? | Yes | No explicit proposal stage |
| How many box refinements? | Anchor → proposal → final box | Anchor → final box |
| How is imbalance handled? | RPN/RoI sampling | Focal loss and prior bias |
| Final filtering | RPN NMS and class-wise final NMS | Score threshold and class-wise NMS |

NMS가 두 번 등장한다고 같은 일을 중복하는 것은 아니다. 첫 NMS는 second stage에 보낼 candidate를 줄이고, 마지막 NMS는 class score와 최종 보정 box를 기준으로 최종 중복을 줄인다.

## 핵심 정리

1. Anchor와 GT로 만드는 target은 모델 prediction과 무관하다.
2. Faster R-CNN은 RPN이 “어디에 있는가”를 좁히고 RoI head가 “무엇이며 정확히 어디인가”를 다시 판단한다.
3. RetinaNet은 proposal 단계를 없애지만 모든 anchor를 직접 학습해야 하므로 class imbalance가 커진다.
4. Focal loss는 이미 잘 맞힌 easy sample의 loss를 줄인다.
5. 저장된 metric은 해당 notebook 설정의 결과이며 독립 재실행이나 일반 성능 보장이 아니다.

## 결론 및 학습 성과

이 과제의 핵심 학습 성과는 detector를 최종 box 생성기로만 보지 않는 데 있다. Feature resolution, anchor, target assignment, loss, proposal filtering, box refinement, NMS를 순서대로 추적하면 두 구조가 어디에서 계산량과 학습 난점을 교환하는지 설명할 수 있다.

더 긴 tensor·수식 해설은 [Lab 1: Two-Stage vs One-Stage Object Detection]({{ "/study/autonomous-driving/adc-lab-01-two-stage-vs-one-stage/" | relative_url }})에서 이어서 볼 수 있다.

## References

- [Faster R-CNN](https://arxiv.org/abs/1506.01497){:target="_blank" rel="noopener"}
- [Focal Loss for Dense Object Detection](https://arxiv.org/abs/1708.02002){:target="_blank" rel="noopener"}
- [Penn-Fudan Database for Pedestrian Detection](https://www.cis.upenn.edu/~jshi/ped_html/){:target="_blank" rel="noopener"}
