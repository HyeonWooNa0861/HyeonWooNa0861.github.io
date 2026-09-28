---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Lecture 4: Perception II — Localization, Detection, and R-CNN"
course: "Autonomous Driving"
topic: "Object Localization, Object Detection, and Region-Based CNNs"
order: 4
major_topic: "Autonomous Systems"
keywords:
  - "Perception"
  - "Object Localization"
  - "Object Detection"
  - "IoU"
  - "R-CNN"
  - "Bounding Box Regression"
---

# Lecture 4: Perception II — Localization, Detection, and R-CNN

Source PDF: [4 Perception (2).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf" | relative_url }}) (국민대학교 Youngwook Kim, *Automatic Driving Computing*, 40쪽)

앞 강의의 이미지 분류는 화면에 무엇이 있는지 판단했지만 **어디에 몇 개 있는지**는 답하지 못했다. 이 강의는 단일 물체의 bounding box를 예측하는 localization을 거쳐, 물체 수가 달라지는 장면의 detection으로 문제를 확장한다. R-CNN은 후보 영역을 먼저 제안한 뒤 각 영역에 시각 분류기를 적용하는 초기의 region-based 해결법이다.

> **핵심:** Localization은 단일 물체의 class와 box를, detection은 모든 물체 각각의 class와 box를 요구한다. IoU는 예측 box와 정답 box의 겹침을 평가한다. R-CNN은 약 2,000개 region proposal을 선별해 CNN으로 해석하고 box를 보정하지만, 제안·영역별 반복 계산이 시간 비용을 만든다.

## 전체 흐름

| 범위 | 주제 | 이해할 질문 |
|---|---|---|
| 2–9쪽 | 이전 강의와 perception 연결 | 분류·localization·detection·segmentation은 출력이 어떻게 다른가? |
| 11–20쪽 | 단일 객체 localization | Box 좌표, 두 손실, transfer learning, IoU는 왜 필요한가? |
| 22–25쪽 | 다중 객체 detection | 물체 수와 위치가 고정되지 않을 때 무엇이 어려운가? |
| 27–36쪽 | Region proposal과 R-CNN | 후보 추출·분류·box 보정·학습 표본 선택은 어떻게 이어지는가? |

## 1. 분류에서 검출까지: 출력 단위가 달라진다

2–3쪽은 CNN과 ViT 같은 **vision backbone**을 복습한다. 7–9쪽은 카메라 영상에서 시작해 문제의 출력을 단계별로 늘린다.

| 작업 | 입력 가정 | 출력 | 예시 |
|---|---|---|---|
| Image classification | 보통 대표 물체가 있는 영상 | 영상 전체 class 하나 또는 class score | “고양이” |
| Object localization | 단일 주요 물체 | class + box 하나 | “고양이, 이 사각형” |
| Object detection | 개수가 가변적인 여러 물체 | 물체별 class + box 목록 | “고양이 하나와 개 둘의 각각의 box” |
| Semantic segmentation | pixel 단위 범주 구분이 필요 | 각 pixel의 class map | “고양이 범주가 차지한 pixel” — 같은 범주의 개체는 구별하지 않음 |
| Instance segmentation | 같은 범주 안의 개체도 구분해야 함 | 개체별 class + mask | “고양이 한 마리씩 별도의 외곽 pixel” |

9쪽은 네 작업을 한 그림으로 비교하지만 본 강의의 수식·학습 범위는 **2D bounding-box localization과 R-CNN detection**이다. Segmentation은 차이를 알아보는 비교 대상으로만 제시된다. 실제 자율주행 장면에는 겹침, 잘림, 크기 변화, 빈 화면도 있으므로 단일 주요 물체 가정은 학습을 위한 축소 문제다.

## 2. Object localization: “what”과 “where”를 함께 예측

### 2.1 네 숫자로 box를 표현하기

11–12쪽의 단일 객체 입력은 RGB 이미지이며 출력은 class label과 bounding box다. Box는 $$(x,y,w,h)$$ 또는 $$(x_1,y_1,x_2,y_2)$$로 나타낼 수 있다. **어느 기준점인지 먼저 정해야 한다.** 이 글에서 $$(x,y)$$는 중심 좌표, $$w,h>0$$는 폭·높이로 두고, $$(x_1,y_1)$$·$$(x_2,y_2)$$는 왼쪽 위와 오른쪽 아래 모서리로 둔다. 같은 pixel 좌표계에서의 **정확한 변환**은 다음과 같다.

$$
x_1=x-\frac{w}{2},\quad x_2=x+\frac{w}{2},\quad
y_1=y-\frac{h}{2},\quad y_2=y+\frac{h}{2}
$$

좌표를 pixel로 표시하면 모든 $$x,y,w,h$$의 단위는 pixel이다. 0–1로 정규화했다면 무차원 값이므로 정답과 예측에 같은 규약을 써야 한다. 예를 들어 중심 $$(50,40)$$, 크기 $$(20,10)$$이면 모서리는 $$(40,35)$$와 $$(60,45)$$다. Box가 이미지 경계 밖으로 나가거나 폭이 음수가 되지 않도록 출력 표현·후처리를 정해야 한다. 강의 도식은 단순한 4좌표를 소개하며 세부 인코딩은 고정하지 않는다.

### 2.2 두 head와 두 loss

13–15쪽의 교육용 모델은 하나의 CNN 표현을 **classification head**와 **localization head**가 공유한다. 첫 head는 class score에 cross-entropy를 적용하고, 두 번째는 box 좌표에 L2 loss를 적용한다. $$p_y$$가 정답 class의 예측 확률, $$b$$·$$b^*$$가 같은 좌표 규약의 예측·정답 box라면 설명용 결합식은

$$
L=L_{\mathrm{cls}}+\lambda L_{\mathrm{reg}},\qquad
L_{\mathrm{cls}}=-\log p_y,\qquad
L_{\mathrm{reg}}=\lVert b-b^*\rVert_2^{2}
$$

다. $$\lambda\ge0$$는 두 항의 상대 비중이다. 정규화 좌표를 쓰면 두 손실 모두 무차원이다. Pixel 좌표를 직접 쓰면 제곱 오차 항의 단위는 pixel²이고 scale이 이미지 크기에 좌우될 수 있어 좌표 정규화 또는 다른 손실 설계가 중요하다. **이 식은 15쪽 도식을 재구성한 작성자 보충 표현**이지, 모든 detector나 원래 R-CNN이 이 단일 목적함수로 end-to-end 학습했다는 주장이 아니다. Cross-entropy는 class 선택 오류를, L2는 위치 오차를 줄이려 한다. Box가 없는 background 후보에는 box regression loss를 적용할 정답이 없다.

### 2.3 Transfer learning이 필요한 이유

16쪽은 class 이름만 붙이는 것보다 모든 물체의 정확한 box를 표시하는 일이 어렵다는 문제를 든다. 17쪽은 ImageNet image classification으로 미리 학습한 CNN 가중치를 초기값으로 가져오는 **transfer learning**을 제안한다. 대규모 분류에서 익힌 edge·texture·부분 표현을 다시 활용하고, 새 과제에 맞는 head 또는 전체 network를 학습한다. 단순히 가중치를 복사하는 것만으로 도로 장면의 새 class·box를 자동으로 검출하는 것은 아니다. 사전학습 자료와 실제 운행 카메라의 시점·환경이 다르면 domain shift가 생겨 대상 데이터로 검증해야 한다.

## 3. IoU: 같은 물체를 얼마나 잘 둘렀는가?

18–20쪽에서 prediction box와 ground-truth box의 겹침을 **Intersection over Union**으로 평가한다. 면적이 유한하고 두 box의 합집합 면적이 양수일 때의 **정의**는

$$
\operatorname{IoU}(A,B)=\frac{|A\cap B|}{|A\cup B|}
=\frac{I}{|A|+|B|-I},\qquad 0\le\operatorname{IoU}\le1
$$

다. $$A,B$$는 box가 차지하는 2D 영역, $$I$$는 교집합 면적이다. 면적 단위가 pixel²이면 비율 IoU는 **무차원**이다. 예를 들어 각각 100 pixel²인 두 box의 교집합이 50 pixel²이면 합집합은 150 pixel², IoU는 $$50/150=1/3$$이다. 겹치지 않으면 0, 두 box가 같으면 1이다. 20쪽의 0.51·0.72·0.91 그림은 box가 점점 정답에 더 잘 맞는 예시다.

**작성자 보충: 좌표로 직접 계산하기.** 각 box가 $$(x_1,y_1,x_2,y_2)$$로 주어지고 좌표축과 평행하다면, 교집합의 폭은 $$\max(0,\min(x_{2,A},x_{2,B})-\max(x_{1,A},x_{1,B}))$$이고 높이도 $$y$$에 같은 규칙을 적용한다. 폭×높이가 $$I$$다. 예컨대 $$A=[0,0,10,10]$$, $$B=[5,0,15,10]$$이면 $$I=5\cdot10=50$$, IoU는 $$1/3$$이다. 경계 접촉만 하면 면적 0이므로 IoU 0이다. 이 계산은 box의 위치 적합도를 말하지만, 예측 class가 맞는지와 중복 검출이 있는지까지 단독으로 평가하지는 못한다.

## 4. Object detection: 출력 개수도 미리 모른다

22–25쪽은 실제 영상이 여러 물체를 포함할 때의 세 난점을 분리한다. 첫째, 영상마다 물체 수가 달라 class·box 출력도 가변 길이여야 한다. 둘째, pixel array만 입력받는 컴퓨터는 물체 수를 미리 알지 못한다. 셋째, 가능한 위치와 크기 조합이 많아 모든 사각형을 무작정 평가하기 어렵다. 강의의 책상 사진에서는 여러 크기·위치의 후보 사각형 가운데 물체를 잘 둘러싼 것을 찾아야 한다. 검출은 “한 이미지를 한 class로 분류”하는 단계를 반복하는 것만으로 충분하지 않다. **어떤 부분 영상을 분류할지**와 겹친 예측을 **어떻게 중복 제거할지**도 결정해야 한다.

## 5. R-CNN: 먼저 물체가 있을 법한 영역을 고른다

### 5.1 Region proposal과 계산 흐름

27쪽의 selective search는 인근 pixel의 색·질감 등 유사성을 바탕으로 작은 영역을 묶어 다양한 크기의 **class-agnostic proposal**을 만든다. 강의는 약 2,000개 후보와 당시 CPU 기준 약 2초/영상이라는 수치를 제시한다. 이는 그 알고리즘·하드웨어·설정의 예이지 현대 시스템의 보편적 지연 시간이 아니다. Proposal 단계는 **물체 종류를 확정하지 않으며**, 좋은 후보를 놓치면 뒤 CNN이 복구하기 어렵다.

28–32쪽의 R-CNN 절차는 다음처럼 읽으면 된다.

```text
입력 이미지
  → selective search로 후보 영역 생성
  → 각 후보를 고정 크기 입력으로 warp/resize
  → 후보마다 CNN feature 추출
  → class score 부여 + box 위치 보정
  → 중복 후보 정리
```

강의 그림은 각 후보를 224×224로 맞춘 뒤 **각각 CNN을 통과**시키는 비용을 강조한다(30–31, 36쪽). 원 [R-CNN 논문](https://arxiv.org/abs/1311.2524){:target="_blank" rel="noopener"}은 약 2,000개 후보, CNN feature, class별 linear SVM, class별 box regressor와 non-maximum suppression(NMS)을 사용한다. NMS는 같은 class의 매우 겹치는 후보 중 높은 score의 box를 남기는 후처리다. **강의의 “class head + box head” 도식은 개념적 압축이며 원 논문의 실제 학습·추론 단계를 그대로 나타낸 것은 아니다.** Fast/Faster R-CNN의 feature 공유나 end-to-end 구조를 이 원래의 R-CNN에 소급해서 붙이지 않는다.

### 5.2 왜 절대 좌표가 아니라 proposal의 변화량을 예측하는가?

32–34쪽은 이미 대략 맞는 proposal $$P$$를 정답 $$G$$ 쪽으로 옮기는 **box regression**을 설명한다. Proposal의 중심·크기를 $$(p_x,p_y,p_w,p_h)$$, 보정 결과를 $$(b_x,b_y,b_w,b_h)$$라 하자. 모든 위치·크기는 pixel이고 $$p_w,p_h>0$$이다. 모델의 출력 $$t_x,t_y,t_w,t_h$$는 **무차원 보정량**이다. 33쪽의 decoding **정의**는

$$
b_x=p_x+p_wt_x,\qquad b_y=p_y+p_ht_y,\qquad
b_w=p_w e^{t_w},\qquad b_h=p_h e^{t_h}
$$

다. 중심 이동을 원 proposal 폭·높이로 스케일하므로 다양한 크기의 후보를 같은 숫자 범위에서 다룰 수 있다. 폭·높이에 지수 함수를 쓰면 결과가 양수다. 정답 box $$G=(g_x,g_y,g_w,g_h)$$를 대입해 위 식을 역으로 풀면 34쪽의 학습 target이 **정확히 유도**된다.

$$
t_x^*=\frac{g_x-p_x}{p_w},\qquad
t_y^*=\frac{g_y-p_y}{p_h},\qquad
t_w^*=\log\frac{g_w}{p_w},\qquad
t_h^*=\log\frac{g_h}{p_h}
$$

예를 들어 proposal 중심 $$(50,50)$$, 크기 $$(20,10)$$과 정답 중심 $$(52,49)$$, 크기 $$(24,10)$$이면 target은 $$(0.1,-0.1,\log1.2,0)$$이다. 다시 decoding하면 $$b_x=50+20(0.1)=52$$, $$b_y=50+10(-0.1)=49$$, $$b_w=20e^{\log1.2}=24$$, $$b_h=10$$으로 정답을 복원한다. 이 변환은 원 R-CNN 논문의 Appendix C에도 나온다. $$p_w,p_h,g_w,g_h>0$$이어야 나눗셈과 로그가 정의된다. 멀리 떨어진 proposal에 아무 정답 box를 강제로 대응시키는 것은 타당하지 않다.

### 5.3 Positive, negative, neutral의 의미

35–36쪽은 각 proposal과 정답 box의 IoU로 학습 표본을 선택한다. 슬라이드의 교육용 규칙은 **어떤 GT와 IoU > 0.5이면 positive**, **모든 GT와 IoU < 0.3이면 negative**, 그 사이이면 neutral이다. Positive에는 class와 box 정답이 있고, negative에는 background class만 있어 box regression target을 적용하지 않는다는 직관을 제시한다. 경계의 등호는 슬라이드가 엄격 부등호로 적었으므로 exactly 0.3·0.5인 경우를 단정하지 않는다.

원래 R-CNN 논문을 대조하면 이 그림을 실제 단일 학습 loop와 동일시할 수 없다. **CNN fine-tuning**에서는 IoU 0.5 이상 proposal을 positive로 사용하고 나머지를 background로 둔다. **Class-specific SVM**에서는 GT box를 positive, 해당 class의 모든 GT와 IoU 0.3 미만인 proposal을 negative로 두며 중간 overlap을 무시한다. **Box regressor**는 별도의 회귀 단계로, 원 논문 Appendix C는 GT와 IoU가 0.6보다 큰 가까운 proposal을 사용하고 정규화된 least-squares 목적함수로 학습한다. 따라서 “positive에는 classification+regression loss, negative에는 classification loss만”이라는 36쪽 문장은 관련 목적을 이해시키는 **후대 detector와 유사한 개념도**로 읽어야 정확하다.

### 5.4 무엇이 병목인가?

후보를 수천 개로 줄여 전수 검색보다 현실적으로 만들었지만, 각 후보를 CNN에 별도로 넣으면 동일 이미지의 겹치는 영역을 여러 번 계산한다. 또한 selective search 자체도 시간이 들고 미분 가능한 CNN의 일부가 아니어서 통합 최적화가 어렵다. 원 R-CNN 논문은 당시 설정에서 CNN feature 계산이 주요 비용이라고 보고한다. 따라서 슬라이드의 약 2초/영상은 **selective search 예시**와 원 시스템 전체 처리 시간을 혼동하지 않아야 한다. 이 병목은 다음 강의의 검출 모델 발전을 이해하는 출발점이다.

## Source Check

| 위치 | 분류 | 확인과 정리 |
|---|---|---|
| 12쪽 | 표기 관례 차이 | $$(x,y,w,h)$$에서 $$x,y$$가 중심인지 모서리인지 명시되지 않았다. 본문에서는 중심 규약을 선언했고 33–34쪽 proposal 식과 일치시켰다. |
| 15쪽 | 가정이 생략된 단순화 | $$L_{\mathrm{cls}}+\lambda L_{\mathrm{reg}}$$는 단일 객체 localization 도식이다. 이것을 원 R-CNN의 end-to-end 학습식으로 옮기지 않는다. |
| 27쪽 | 적용 범위 제한 | 약 2,000 proposals·약 2초/영상은 강의가 제시한 selective-search 예시다. 현재 장비의 보편적 실행 시간으로 단정하지 않는다. |
| 35–36쪽 | 원문 대비 정정 | 슬라이드의 positive·negative·동시 loss 도식과 [원 R-CNN 논문](https://arxiv.org/pdf/1311.2524){:target="_blank" rel="noopener"}의 CNN fine-tuning, class별 SVM, 별도 box regressor를 구별했다. 특히 regressor는 0.6 초과 overlap proposal을 별도로 사용한다. |

## 시험 포인트

1. Classification, localization, detection, segmentation의 출력 형식을 구별한다. 특히 detection의 출력 **개수는 가변적**이다.
2. 중심 box와 모서리 box를 변환하고, 같은 좌표 단위를 사용해 IoU를 계산한다.
3. Class loss와 box loss가 서로 다른 오차를 측정하며, background에는 box target이 없다는 이유를 설명한다.
4. R-CNN의 **proposal → warp → 후보별 CNN → 분류·보정 → 중복 제거** 순서를 도식 없이 재현한다.
5. $$t_x=(g_x-p_x)/p_w$$와 $$t_w=\log(g_w/p_w)$$를 decoding 식에서 유도하고, 폭·높이 양수 조건을 설명한다.
6. 슬라이드의 단순화된 학습 그림과 원 R-CNN 논문의 실제 분리된 학습 절차를 구별한다.

## 마지막 핵심 정리

Localization은 **하나의 what+where**, detection은 **가변 개수의 what+where 목록**이다. IoU는 box overlap의 무차원 척도다. R-CNN은 후보 영역을 먼저 만든 뒤 CNN으로 분류하고 상대적 위치·크기 보정으로 box를 개선한다. Proposal의 재현율과 수천 번의 후보별 CNN 연산은 장점과 동시에 병목이다. CNN·ViT backbone에서 detector로 이어지는 큰 흐름은 [Perception Overview]({{ "/study/autonomous-driving/perception-overview/" | relative_url }})에서 함께 정리한다.

## Study Guide

- 9–12쪽의 네 작업 비교를 먼저 외우지 말고, 각 작업이 **출력에서 추가하는 정보**를 그림 없이 설명한다.
- 13–20쪽은 class score·box 좌표·loss·IoU를 한 예에 연결한다. IoU는 점수 평가에 쓰이는 정의이고, 14쪽의 L2는 학습 손실이라는 역할 차이를 기억한다.
- 27–36쪽을 읽을 때 제안 후보 수, 후보별 CNN 호출 수, positive/negative 기준을 따로 적는다. 33–34쪽 수식은 숫자 예를 다시 decoding해 검산한다.
- `Source Check`를 통해 강의의 개념적 파이프라인과 2014년 원 R-CNN 구현을 혼동하지 않는다.

## 복습 질문

<details markdown="block">
<summary>1. 이미지 분류기만으로 다중 객체 검출을 완성할 수 없는 이유는?</summary>

답변: 분류기는 보통 이미지 전체에 대한 class score만 내며 물체의 수, 각 물체의 위치, 겹치는 후보의 중복 여부를 알려주지 않는다. Detection에는 후보 위치 생성 또는 위치 예측, 물체별 class·box, 중복 정리가 추가로 필요하다.

</details>

<details markdown="block">
<summary>2. 면적 100인 두 box가 50만큼 겹치면 IoU는 왜 0.5가 아니라 1/3인가?</summary>

답변: 합집합은 $$100+100-50=150$$이다. 따라서 $$\operatorname{IoU}=50/150=1/3$$이다. 교집합을 각 box 하나의 면적으로 나누는 값이 아니라 **합집합 면적**으로 나눈다.

</details>

<details markdown="block">
<summary>3. Box 폭을 직접 더하지 않고 지수 보정하는 이유는?</summary>

답변: Proposal 폭 $$p_w>0$$와 보정량 $$t_w$$에서 $$b_w=p_we^{t_w}$$로 정의하면 예측 폭은 항상 양수다. 정답 폭 $$g_w>0$$로부터 목표 보정량을 $$t_w^*=\log(g_w/p_w)$$로 구할 수 있다. 비율이 1이면 0, 1.2배면 $$\log1.2$$다.

</details>

<details markdown="block">
<summary>4. 왜 negative region에는 box regression loss를 적용하지 않는가?</summary>

답변: Negative는 물체가 아닌 background 후보이므로 특정 물체의 정답 box와 합리적으로 짝지을 수 없다. 따라서 background 분류 손실은 계산해도, 그 후보를 옮겨야 할 box target은 정의하지 않는 것이 자연스럽다.

</details>

<details markdown="block">
<summary>5. 슬라이드 35–36쪽의 학습 규칙이 원래 R-CNN 논문의 단일 학습 절차인가?</summary>

답변: 아니다. 슬라이드는 positive의 분류·회귀, negative의 분류라는 직관을 압축한다. 원 논문은 CNN fine-tuning, class별 SVM 학습, 별도 box regressor 학습을 나누며 표본 기준도 단계별로 다르다. 따라서 슬라이드 임계값 하나를 모든 단계에 적용하면 안 된다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf" | relative_url }}" target="_blank" rel="noopener">4 Perception (2).pdf</a></li>
</ul>

## References

- Girshick et al., [Rich Feature Hierarchies for Accurate Object Detection and Semantic Segmentation](https://arxiv.org/abs/1311.2524){:target="_blank" rel="noopener"} — 원 R-CNN의 후보별 CNN, SVM, NMS, box regression과 학습 임계값.
