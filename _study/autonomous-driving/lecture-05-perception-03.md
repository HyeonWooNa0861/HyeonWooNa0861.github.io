---
layout: default
date: 2026-09-21 00:00:00 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Lecture 5: Perception (3) - R-CNN Inference and Fast R-CNN"
course: "Autonomous Driving"
topic: "Non-Maximum Suppression, Average Precision, Fast R-CNN, and RoI Pooling"
order: 5
major_topic: "Autonomous Systems"
keywords:
  - "Object Detection"
  - "R-CNN"
  - "NMS"
  - "Average Precision"
  - "Fast R-CNN"
  - "RoI Pooling"
---

# Lecture 5: Perception (3) - R-CNN Inference and Fast R-CNN

Source PDF: [5 Perception (3).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf" | relative_url }})

R-CNN에서는 여러 후보 상자가 한 물체를 가리킬 수 있고, 후보마다 CNN을 다시 실행하는 비용도 큽니다. 국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 5강은 이 문제를 추론 후처리·평가·계산량의 관점에서 다룹니다. 4강의 R-CNN과 6강의 Faster R-CNN·FPN을 잇는 내용입니다.

> **핵심:** R-CNN은 한 물체에 여러 예측 상자를 낼 수 있으므로 NMS로 중복을 줄이고, 단일 confidence threshold의 accuracy가 아닌 class별 precision–recall 곡선의 AP로 평가합니다. Fast R-CNN은 proposal마다 CNN을 다시 실행하는 낭비를 없애기 위해 이미지 전체의 feature map을 공유하고, RoI pooling으로 가변 크기 영역을 고정 크기 특징으로 바꿉니다.

## 전체 흐름

| 순서 | 원문 범위 | 핵심 질문 |
|---|---|---|
| 1 | 1–7쪽 | 왜 R-CNN의 예측 상자가 중복되고 NMS는 무엇을 제거합니까? |
| 2 | 8–17쪽 | confidence를 바꾸며 precision·recall·AP·mAP를 어떻게 계산합니까? |
| 3 | 18–23쪽 | R-CNN의 반복 CNN 계산을 Fast R-CNN은 어떻게 줄입니까? |
| 4 | 24–28쪽 | 크기가 서로 다른 RoI를 같은 크기의 feature로 만드는 과정은 무엇입니까? |
| 5 | 29–32쪽 | 다음 강의의 proposal 생성 병목과 어떻게 연결됩니까? |

## 1. 하나의 물체가 여러 detection을 만드는 이유

한 강아지 주위에 조금씩 다른 상자를 여러 개 그리면, 모든 상자 안에 같은 강아지가 보일 수 있습니다. R-CNN은 이렇게 물체가 있을 법한 후보 상자, 즉 region proposal을 각각 분류하고 위치를 보정하므로 같은 물체에 여러 detection이 남을 수 있습니다. 원문 6쪽에서도 한 물체 주위에 confidence 0.9와 0.8, 다른 물체 주위에 0.75와 0.7인 상자가 함께 남습니다. 가장 큰 class score를 고르는 일과 중복 상자를 제거하는 일은 별도 단계입니다.

두 상자가 같은 물체를 거의 같은 위치에서 둘렀는지 확인하려면, 겹친 넓이를 두 상자가 차지한 전체 넓이와 비교합니다. 완전히 같으면 1, 전혀 겹치지 않으면 0이 됩니다. 이 비율을 intersection over union(IoU)이라고 하며 다음처럼 정의합니다.

$$
\operatorname{IoU}(A,B)=\frac{\lvert A\cap B\rvert}{\lvert A\cup B\rvert}
=\frac{\lvert A\cap B\rvert}{\lvert A\rvert+\lvert B\rvert-\lvert A\cap B\rvert}.
$$

여기서 $$A,B$$는 영상 좌표의 면적이 양수인 상자, $$\lvert\cdot\rvert$$는 pixel 제곱 단위의 면적입니다. 분자와 분모의 단위가 같아서 IoU는 **무차원**이며 0–1 사이에 있습니다. 교집합 면적을 합집합으로 나누는 이유는 단순 겹침 면적만으로는 큰 상자가 과도하게 유리해지기 때문입니다. 예를 들어 두 상자의 면적이 각각 100, 교집합이 80 pixel²이면 합집합은 120 pixel²이고 IoU는 $$80/120=0.667$$입니다. 겹치지 않으면 0, 완전히 일치하면 1입니다.

### 1.1 Class별 non-maximum suppression

같은 강아지를 가리키는 상자 네 개가 남았다면 가장 믿을 만한 상자 하나만 남기고 싶습니다. 같은 class의 상자를 confidence 순으로 세운 뒤, 최고 점수 상자와 너무 많이 겹치는 낮은 점수 상자를 지웁니다. 이 과정을 non-maximum suppression(NMS)이라고 합니다. 원문 7쪽은 “너무 많이 겹침”의 예시 기준으로 IoU $$>0.7$$을 사용합니다. 앞에서 고른 결과를 되돌리지 않는 탐욕적 후처리이므로 최적 상자 집합을 보장하지는 않습니다.

```text
class별 detection을 confidence 내림차순으로 정렬
while 후보가 남아 있다:
    최고 점수 상자를 채택
    그 상자와 IoU가 임계값보다 큰 같은 class 후보를 제거
```

원문 그림에서 confidence 0.9인 파란 상자와 0.8인 주황 상자의 IoU는 0.78이라 주황 상자를 제거합니다. 0.75인 보라 상자와 0.7인 노란 상자의 IoU는 0.74라 노란 상자를 제거합니다. 결과는 두 강아지를 가리키는 파란·보라 상자입니다. **서로 다른 class끼리 같은 위치에 있어도** 원문 NMS는 무조건 상호 제거하지 않습니다. 반대로 가까이 붙거나 가려진 두 실제 물체의 box가 크게 겹치면 한 물체를 잘못 없앨 수 있으므로 NMS 임계값은 데이터와 평가 설정에 맞춰 선택해야 합니다.

> **구분:** 이 강의의 NMS $$0.7$$은 *예측 상자끼리의 중복 제거* 기준입니다. 아래 AP 예제의 $$0.5$$는 *예측 상자와 정답 상자의 매칭* 기준입니다. 두 IoU가 쓰이는 목적도 비교 대상도 다릅니다.

## 2. Accuracy보다 precision–recall이 필요한 이유

원문 8–10쪽은 NMS 뒤 dog class를 독립적으로 평가합니다. Dog 정답 상자가 3개이고, confidence가 $$0.99,0.95,0.90,0.50,0.10$$인 예측 5개를 높은 점수부터 정답과 비교합니다. 원문 그림의 판정은 순서대로 **TP, TP, FP, FP, TP**입니다. IoU가 평가 기준 $$>0.5$$인 정답에 매칭돼야 TP이며, 한 정답은 중복해서 TP로 셀 수 없습니다. 매칭되지 않은 예측은 FP, 끝까지 찾지 못한 정답은 FN입니다.

$$
\mathrm{Precision}=\frac{TP}{TP+FP},\qquad
\mathrm{Recall}=\frac{TP}{TP+FN}.
$$

이 둘은 **정의**이며 무차원 비율입니다. Precision은 “검출이라고 말한 것 중 맞은 비율”, recall은 “실제 물체 중 찾아낸 비율”입니다. 분모가 0인 특수 경우에는 평가 구현체의 정의를 확인해야 합니다. 배경의 수많은 true negative(TN)는 객체 검출에서 의미 있게 세기 어렵고 데이터 구성에 크게 좌우되므로, 단순 accuracy는 잘못된 상자와 놓친 물체의 교환관계를 충분히 보여주지 못합니다.

### 2.1 원문 5개 예측으로 계산하기

<figure id="adc-05-p12">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-05-p12.png" | relative_url }}" alt="Confidence 0.99인 첫 detection으로 precision 1 recall 0.33을 계산한 원문" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf#page=12" | relative_url }}">lecture PDF, p. 12</a>.</figcaption>
</figure>

첫 예측이 정답 물체 하나와 매칭되므로 TP는 1, FP는 0입니다. 정답 물체는 총 3개이므로 precision은 1이고 recall은 1/3입니다. 가로축 recall과 세로축 precision의 점 하나가 이렇게 생깁니다. 다음 예측을 confidence 순서로 추가할 때마다 누적 TP·FP를 갱신합니다.

confidence threshold를 높은 값에서 낮은 값으로 이동시키면 예측이 한 개씩 추가됩니다. 원문 12–16쪽 도식의 숫자를 직접 계산하면 다음과 같습니다.

| 포함한 예측 수 | 마지막 confidence | TP | FP | FN | Precision | Recall |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0.99 | 1 | 0 | 2 | 1.00 | 1/3 |
| 2 | 0.95 | 2 | 0 | 1 | 1.00 | 2/3 |
| 3 | 0.90 | 2 | 1 | 1 | 2/3 | 2/3 |
| 4 | 0.50 | 2 | 2 | 1 | 1/2 | 2/3 |
| 5 | 0.10 | 3 | 2 | 0 | 3/5 | 1.00 |

예를 들어 threshold를 $$0.95$$ 이상으로 놓으면 첫 두 예측만 남아 $$P=1, R=2/3$$입니다. $$0.10$$ 이상이면 모두 남아 $$P=0.6, R=1$$입니다. 후자의 마지막 예측은 낮은 점수지만 미검출 정답을 찾아 recall을 올렸습니다. 따라서 threshold를 낮춘다고 precision이 **항상** 단조 감소하는 것은 아닙니다. 다만 새 FP가 유입될 위험은 커집니다. 실제 시험에서는 threshold에 따른 TP·FP·FN을 먼저 적고 비율을 계산하면 헷갈리지 않습니다.

### 2.2 AP와 mAP

Confidence 기준을 높이면 확실한 상자만 남고, 낮추면 더 많은 정답과 오탐이 함께 들어옵니다. 따라서 기준 하나에서 나온 precision·recall만으로 모델 전체를 평가하면 선택한 기준에 따라 결론이 달라집니다. Class별 예측을 높은 score부터 하나씩 추가하며 만든 precision–recall 곡선의 면적이 average precision(AP)입니다. 여러 class의 AP를 평균한 값이 mAP입니다. 원문 17쪽은 더 높은 recall 구간의 최대 precision을 앞 구간으로 전파한 보간 방식을 사용합니다. 정확한 적분·보간 규칙은 VOC, COCO 등 평가 규약마다 다릅니다.

이 강의 예제에서 양성 정답 수 $$N_{GT}=3$$이고 TP가 나온 순위는 1, 2, 5입니다. 각 TP 직후 precision은 $$1,1,3/5$$이므로, recall 증가량 $$1/3$$을 곱한 **all-point 방식의 예제 계산**은

$$
AP=\sum_{k\,\text{at TP}}\Delta R_k P_{\mathrm{interp}}(R_k)
=\frac{1}{3}\left(1+1+\frac{3}{5}\right)
=\frac{13}{15}\approx0.867.
$$

$$\Delta R_k$$는 해당 TP가 만드는 recall 증가량(무차원), $$P_{\mathrm{interp}}$$는 보간 precision(무차원)입니다. 첫 두 지점의 precision은 이미 최대 1이라 이 예제에서는 보간 전후가 같습니다. 원문 도표의 `Dog AP = 0.86`은 이 값의 두 자리 **절삭 또는 도식상 근삿값**으로 보이며, 통상적인 소수 둘째 자리 반올림은 0.87입니다. AP는 0–1 사이의 무차원 점수입니다.

여러 class의 AP를 평균하면 mAP입니다. 원문 17쪽의 Car 0.65, Cat 0.80, Dog 0.86을 그대로 사용하면

$$
mAP@0.5=\frac{AP_{\mathrm{car}}+AP_{\mathrm{cat}}+AP_{\mathrm{dog}}}{3}
=\frac{0.65+0.80+0.86}{3}=0.77.
$$

여기서 `@0.5`는 **정답 매칭용 IoU 임계값**을 뜻합니다. 0.5가 NMS 임계값이나 confidence threshold라는 뜻이 아닙니다. 서로 다른 데이터셋·매칭 IoU·보간 규칙의 AP를 같은 성능 척도인 양 비교하지 말아야 합니다.

## 3. R-CNN에서 Fast R-CNN으로

원문 19쪽은 이미지당 약 2,000개의 proposal 각각을 잘라 CNN에 넣기 때문에 약 2,000번의 convolutional forward pass가 필요하다고 설명합니다. 같은 도로·차량·배경 pixel이 상자마다 반복 계산됩니다. 이는 차량의 perception pipeline에서 지연을 키웁니다. Fast R-CNN(원문 20–23쪽)은 **이미지 전체에 backbone CNN을 한 번 적용**해 feature map을 만들고, 각 proposal을 그 feature map의 좌표로 옮겨 사용합니다.

```text
R-CNN:      image → proposals → proposal별 crop/warp → proposal별 CNN → class/box
Fast R-CNN: image → CNN 한 번 → 공유 feature map
                          proposals → RoI별 feature 추출 → class/box
```

공유되는 것은 무거운 **convolutional backbone feature**입니다. 각 RoI의 pooling, per-region head, class prediction, box regression까지 한 번만 실행한다는 뜻은 아닙니다. 원문 20–23쪽은 backbone 예시로 AlexNet·VGG·ResNet을 그리고, proposal을 공유 feature map 위에 투영한 뒤 각 영역에서 class와 box transform을 예측합니다. Fast R-CNN 논문은 전체 이미지와 RoI 목록을 입력받아 공유 feature map을 만들고, RoI pooling·fully connected layers 뒤 class 확률과 box offset 두 출력을 학습한다고 설명합니다.

## 4. RoI pooling: 가변 크기 상자를 고정 크기 특징으로

<figure id="adc-05-p28">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-05-p28.png" | relative_url }}" alt="Feature map에 투영한 proposal을 2×2 bin으로 나눠 max pooling하는 예" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf#page=28" | relative_url }}">lecture PDF, p. 28</a>.</figcaption>
</figure>

원본 이미지의 proposal을 축소된 feature map 위치로 옮긴 뒤 구역별 최대값을 뽑습니다. 예시 출력의 공간 크기는 2×2지만 channel은 512개로 유지됩니다. 같은 크기의 물체를 찾는 연산이 아니라 크기가 다른 proposal도 같은 크기의 head 입력으로 만드는 연산입니다. 좌표를 격자에 맞추는 과정이 이후 RoIAlign과의 차이를 만듭니다.

서로 다른 proposal을 그대로 per-region head에 넣으면 입력 tensor의 공간 크기가 제각각입니다. **고정 크기 특징**이 필요한 분류·회귀 head와 연결하기 위해 RoI pooling을 씁니다(원문 24–28쪽).

1. 원본 이미지의 proposal 좌표를 backbone feature map의 좌표계로 **투영**합니다. 이때 feature stride를 반영해야 하며, 좌표가 어긋나면 다른 물체의 feature를 읽습니다.
2. feature map의 연속 좌표를 이산 **grid cell에 맞춰 양자화(snap)** 합니다.
3. RoI를 목표 출력 $$H\times W$$개의 대략 같은 크기 bin으로 나눕니다.
4. 각 bin과 각 channel에서 max를 취합니다. 따라서 결과는 원래 RoI 크기와 상관없이 $$C\times H\times W$$입니다.

원문 그림은 $$C=512$$인 feature map에서 설명용 $$2\times2$$ RoI pooling을 하여 $$512\times2\times2$$를 만듭니다. 실사용 예시로는 $$7\times7$$ 또는 $$14\times14$$를 적었습니다. $$C,H,W$$는 channel 수와 출력 grid 크기로 모두 **개수/무차원**이며, 공간 좌표는 image pixel과 feature-map cell을 혼동하면 안 됩니다. 예를 들어 4×4 cell RoI를 2×2 bin으로 나누면 bin마다 2×2 cell의 max를 취합니다. 첫 bin 값이 `[1, 4; 2, 3]`이면 출력 첫 값은 4입니다. 다른 bin에도 같은 작업을 하고 모든 channel에 독립 적용합니다. 이는 **정의된 연산**이지 interpolation에 의한 연속값 추정은 아닙니다.

RoI pooling은 feature 길이를 맞추지만 좌표를 cell에 snap하므로 작은 물체나 정밀한 경계에서는 위치 오차가 날 수 있습니다. 원문은 RoI Align을 다루지 않으므로 여기서는 비교만 덧붙입니다: RoI Align은 이러한 양자화 오차를 줄이려고 고안된 후속 기법입니다. 또한 Fast R-CNN의 feature 공유만으로 proposal 생성이 공짜가 되는 것은 아닙니다. 이 남은 병목이 [6강 Faster R-CNN]({{ "/study/autonomous-driving/lecture-06-perception-04/" | relative_url }})의 출발점입니다.

## 원문 정확성 검토: Source Check

<details markdown="block">
<summary markdown="span">Source notes: assumptions and corrections</summary>

| 원문 위치 | 확인한 내용 | 이 글의 처리 |
|---|---|---|
| 7·9쪽 | NMS는 예측끼리 IoU 0.7, TP 매칭은 예측–GT IoU 0.5를 사용합니다. | 두 임계값의 목적과 비교 대상을 분리했습니다. 둘 다 이 강의의 **예시 설정**이지 항상 고정값은 아닙니다. |
| 11쪽 | “confidence threshold 높이면 오탐 발생 → precision 감소”라고 적혀 있습니다. | 바로 위의 높은 threshold→미탐 증가 설명 및 12–16쪽 누적 예제와 모순됩니다. **원문 오류 가능성이 높은 방향 표기**로 판단하여, 일반적으로 threshold를 *낮추면* FP가 추가될 수 있다고 정정했습니다. 단 precision의 단조 감소까지 주장하지 않았습니다. |
| 17쪽 | Dog AP 0.86, Car/Cat/Dog mAP 0.77이 제시됩니다. | 예제 TP 순위로 AP는 $$13/15\approx0.8667$$을 재계산했습니다. Dog 0.86은 절삭/도식 근사로 표시하고, 원문 수치의 mAP 0.77은 별도로 검산했습니다. |

슬라이드 그림에 없는 구체적인 모델 구현 수치나 보편적인 자율주행 실시간성 보장은 이 예제에서 추론하지 않았습니다.

</details>

## 마지막 핵심 정리

| 개념 | 풀려는 문제 | 반드시 구분할 점 |
|---|---|---|
| Class별 NMS | 한 물체의 중복 detection | 예측–예측 IoU와 confidence로 후처리; 가까운 실제 물체를 누락시킬 위험이 있습니다. |
| Precision·recall | FP와 FN의 교환관계 | threshold에 따라 함께 변하며 accuracy 하나로 대체할 수 없습니다. |
| AP·mAP | threshold 전 범위의 class별 성능 | 매칭 IoU와 보간 프로토콜이 같아야 수치 비교가 의미 있습니다. |
| Fast R-CNN | proposal별 CNN 반복 | 공유 backbone은 한 번이지만 per-RoI head는 남습니다. |
| RoI pooling | 가변 크기 RoI | 좌표 투영·양자화·bin별 max로 고정 크기 출력을 만듭니다. |

## Study Guide

<details markdown="block">
<summary markdown="span">학습 점검표 보기</summary>

1. **계산 순서:** IoU 정의를 손으로 계산한 뒤, NMS의 예측–예측 IoU와 AP 매칭의 예측–GT IoU를 구분합니다.
2. **시험형 예제:** 원문 12–16쪽의 TP–TP–FP–FP–TP를 표로 다시 만들고 threshold 0.95와 0.10의 precision·recall을 직접 구합니다. 그다음 AP의 TP 순위 1·2·5를 합합니다.
3. **설계 흐름:** R-CNN의 반복 CNN → Fast R-CNN의 공유 feature → RoI pooling으로 고정 크기화 → 남은 proposal 생성 병목을 한 문장씩 설명합니다.
4. **오개념 확인:** AP 0.5, NMS 0.7, confidence 0.95는 서로 다른 역할의 임계값입니다. AP의 0.86/0.87 차이는 계산 방식과 반올림을 먼저 확인합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. 같은 강아지에 대한 상자가 두 개 남으면 NMS는 어떤 순서로 처리합니까?</summary>

답변: 같은 class의 예측을 confidence 내림차순으로 정렬하고 높은 점수 상자를 채택합니다. 그 상자와 IoU가 설정된 중복 임계값보다 큰 낮은 점수 상자를 제거한 뒤 남은 후보에 반복합니다. 원문에서는 0.9/0.8 상자 IoU 0.78과 0.75/0.7 상자 IoU 0.74가 모두 예시 임계값 0.7을 넘어 각각 낮은 점수 상자가 제거됩니다.

</details>

<details markdown="block">
<summary>2. Dog 정답 3개 중 threshold 0.95에서 두 개를 맞혔다면 precision과 recall은 무엇입니까?</summary>

답변: 남은 detection 두 개가 모두 TP이므로 $$TP=2,FP=0,FN=1$$입니다. Precision은 $$2/(2+0)=1$$, recall은 $$2/(2+1)=2/3$$입니다. threshold를 0.10으로 내리면 예제의 다섯 detection 중 TP 3, FP 2가 되어 precision 3/5, recall 1입니다.

</details>

<details markdown="block">
<summary>3. AP와 mAP@0.5를 계산할 때 0.5는 무엇입니까?</summary>

답변: 각 예측 box를 정답 box와 TP로 매칭할 때 요구하는 IoU 기준입니다. AP는 class 하나의 PR 곡선 면적이고 mAP는 class별 AP의 평균입니다. 0.5는 confidence threshold도 NMS 임계값도 아닙니다.

</details>

<details markdown="block">
<summary>4. Fast R-CNN이 R-CNN보다 빠른 이유와 여전히 남는 계산은 무엇입니까?</summary>

답변: 이미지 전체의 convolutional feature map을 한 번 계산해 여러 proposal이 공유하기 때문입니다. 하지만 proposal별 RoI pooling과 per-region 분류·상자 회귀는 수행하며, Fast R-CNN 자체의 외부 region proposal 생성도 여전히 비용이 듭니다.

</details>

<details markdown="block">
<summary>5. RoI pooling이 다양한 크기의 입력을 같은 크기로 만드는 구체적인 방법은 무엇입니까?</summary>

답변: 원본 상자를 feature map에 투영하고 이산 cell로 맞춘 다음 목표 $$H\times W$$개의 bin으로 나눕니다. 각 bin과 channel에서 max를 뽑아 $$C\times H\times W$$ 출력을 만듭니다. 좌표 양자화 때문에 작은 물체의 위치 정보는 손실될 수 있습니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 5 source slides (PDF)</a></li>
</ul>

## References

- Ross Girshick, <a href="https://arxiv.org/pdf/1504.08083" target="_blank" rel="noopener">Fast R-CNN</a>, ICCV 2015. RoI pooling, 공유 convolution, class·box head의 원 논문.
- Shaoqing Ren et al., <a href="https://papers.nips.cc/paper/2015/file/14bfa6bb14875e45bba028a21ed38046-Paper.pdf" target="_blank" rel="noopener">Faster R-CNN: Towards Real-Time Object Detection with Region Proposal Networks</a>, NeurIPS 2015. Fast R-CNN 이후 proposal 생성 병목의 연결 자료.
