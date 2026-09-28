---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Lecture 7: Single-Stage Object Detection"
course: "Autonomous Driving"
topic: "RetinaNet, Focal Loss, YOLO, and FCOS"
order: 7
major_topic: "Autonomous Systems"
keywords:
  - "Object Detection"
  - "RetinaNet"
  - "Focal Loss"
  - "YOLO"
  - "FCOS"
---

# Lecture 7: Single-Stage Object Detection

Source PDF: [7 Perception (5).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf" | relative_url }})

국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 7강을 바탕으로 구성한 학습 노트다. 슬라이드의 Faster R-CNN 복습, RetinaNet, YOLO, FCOS 흐름을 따라가되 수식 유도와 예제는 **작성자 보충**으로 분리했다. [통합 Perception 학습 노트]({{ "/study/autonomous-driving/perception-overview/" | relative_url }})는 여러 강의의 연결 관계를 다룬다.

> **핵심:** Single-stage detector는 region proposal별 두 번째 분류 단계를 거치지 않고 밀집 위치에서 곧바로 클래스와 box를 예측한다. 그 대신 엄청난 배경 후보의 학습 불균형과 부정확한 box 품질이 과제가 된다. RetinaNet은 focal loss로 쉬운 배경의 기여를 줄이고, FCOS는 anchor 대신 위치별 네 방향 거리와 centerness를 예측한다. 빠른 추론 가능성은 자율주행에 매력적이지만 속도와 정확도는 **모델·입력 크기·하드웨어·평가 조건에 종속**된다.

## 전체 흐름

| 순서 | 슬라이드 | 핵심 질문 |
|---|---:|---|
| 1 | 3, 7 | Faster R-CNN의 두 단계 가운데 무엇을 없앨 수 있는가? |
| 2 | 8–12 | RetinaNet은 dense anchor와 배경 불균형을 어떻게 다루는가? |
| 3 | 13 | YOLO의 단일 네트워크 예측과 45 fps는 무슨 조건의 결과인가? |
| 4 | 14–20 | FCOS는 anchor 없이 위치·box·centerness를 어떻게 결합하는가? |
| 5 | 21–24 | 이 강의가 다음 segmentation 강의로 어떻게 이어지는가? |

## 1. Two-stage와 single-stage의 차이

지난 강의의 Faster R-CNN은 영상 전체에 backbone CNN과 Region Proposal Network(RPN)를 한 번 실행한 뒤, 제안된 **각 RoI**의 특징을 모아 클래스와 box 보정을 다시 예측한다(7쪽). 첫 단계는 후보를 만들고, 두 번째 단계는 후보를 정밀 판정한다. 이는 제안된 영역 수만큼 뒤 단계의 작업이 필요하다는 뜻이다. Single-stage는 중간의 별도 proposal/RoI 판정 경로를 제거하고 feature map의 여러 위치에서 클래스 점수와 box를 동시에 낸다. 단, “single-stage”가 CNN 층이 하나라는 뜻은 아니다. Backbone과 FPN 및 여러 prediction head가 여전히 존재한다.

왜 이를 자율주행에서 배우는가? 센서 입력은 연속적으로 들어오고 perception의 지연은 뒤따르는 prediction·planning의 가용 시간을 갉아먹는다. 한편 빠르다는 이름만으로 검출 누락이 허용되는 것은 아니므로 **지연과 검출 품질을 같은 데이터·장치 조건에서 함께** 비교해야 한다. [Faster R-CNN 원 논문](https://arxiv.org/abs/1506.01497){:target="_blank" rel="noopener"}도 RPN과 검출기가 이미지 특징을 공유한다는 점을 강조한다. 즉 두 단계의 비용을 단순히 “backbone 두 번”으로 세면 안 된다.

## 2. RetinaNet: anchor마다 직접 예측하기

8–10쪽의 도식은 입력 영상이 backbone feature map으로 바뀌고, 각 위치에서 여러 모양·크기의 anchor에 대한 분류와 box 변환을 출력하는 구조를 보여준다. 그림의 `5 × 6`은 **설명용 feature-grid 예시**이지 RetinaNet의 고정 입력 크기가 아니다. 위치 수가 많고 위치당 anchor가 여럿이므로 양성 물체보다 쉬운 배경 anchor가 훨씬 많이 생긴다(9쪽).

11쪽처럼 실제 RetinaNet은 ResNet 계열 backbone 위에 Feature Pyramid Network(FPN)를 둔다. 거친 해상도의 의미 정보와 상대적으로 세밀한 해상도를 결합하여 서로 다른 물체 크기에 대응한다. 각 pyramid level에 **분류 subnet**과 **box subnet**을 적용하며, 원 논문의 분류 출력은 위치당 $$A K$$개 sigmoid 점수, box 출력은 $$4A$$개다. 여기서 $$A$$는 한 위치의 anchor 수, $$K$$는 전경 클래스 수다. 슬라이드 8–10쪽의 `2K*(C+1)` 표기는 원 논문의 실제 RetinaNet head 차원과 다르므로 그대로 계산에 쓰지 않는다. [RetinaNet 원 논문](https://openaccess.thecvf.com/content_ICCV_2017/papers/Lin_Focal_Loss_for_ICCV_2017_paper.pdf){:target="_blank" rel="noopener"}의 class subnet 설명을 기준으로 한 정정이다.

### 2.1 왜 보통의 cross-entropy로 부족한가

슬라이드 10쪽의 중요한 수식은 아래 두 개다. $$p_t$$는 정답 클래스에 부여한 확률로, 범위는 $$0<p_t<1$$이며 무차원이다. $$\gamma\ge 0$$도 무차원 focusing parameter다. 로그의 입력 또한 무차원이어야 한다.

$$
\operatorname{CE}(p_t)=-\log p_t
$$

$$
\operatorname{FL}(p_t)=-(1-p_t)^{\gamma}\log p_t
$$

첫 식은 정답 확률이 높아질수록 손실이 줄어드는 **정의**다. 두 번째 식은 그 손실에 쉬운 예제를 누르는 가중치를 곱한 **focal loss 정의**다. $$\gamma=0$$이면 cross-entropy와 같고, $$p_t\to1$$이면 추가 계수 $$(1-p_t)^\gamma\to0$$이 된다. 반대로 어려운 예제의 $$p_t$$가 낮으면 계수가 1에 가까워 손실을 상대적으로 유지한다. 완전한 확률 경계 $$p_t=0$$은 로그가 발산하므로 수치 구현에서는 안정화가 필요하다.

**작성자 보충 — 직접 검산:** $$\gamma=2$$, $$p_t=0.9$$이면 CE는 약 $$0.105$$, FL은 $$0.00105$$로 100분의 1이다. $$p_t=0.1$$이면 CE는 약 $$2.303$$, FL은 약 $$1.865$$이다. 두 경우의 추가 가중치는 각각 $$0.01$$, $$0.81$$이므로, 수가 많은 **쉬운 배경**을 누르고 드문 어려운 샘플에 학습을 집중시키는 이유가 보인다. 이 값은 loss의 성질을 보여주는 예시일 뿐 모델 성능 수치가 아니다.

원 논문에는 전경/배경의 상대 비중을 조절하는 $$\alpha_t$$도 포함한 $$-\alpha_t(1-p_t)^\gamma\log p_t$$ 형태가 나온다. 슬라이드 식은 $$\alpha_t$$를 생략한 기본형이다. $$\alpha_t$$는 무차원 가중치이며 학습 데이터와 설정에 맞춰 선택한다. Focal loss는 **분류 손실**의 불균형 문제에 대응하지, 잘못된 box 좌표를 혼자 수정하는 손실은 아니다.

### 2.2 속도–정확도 곡선은 맥락과 함께 읽기

12쪽의 COCO AP 대 inference time 그림에서 RetinaNet-50/101은 당시 비교 모델의 trade-off 곡선을 보여준다. FPN을 붙인 Faster R-CNN 지점과 비교할 수 있지만, 이는 논문 당시의 구현·입력·하드웨어·평가 설정에 한정된 실험 결과다. **모든 single-stage 모델이 모든 two-stage 모델보다 빠르다**는 정리나 현대 차량 하드웨어에서의 실시간성 보증으로 읽지 않는다. AP는 데이터셋의 box 검출 평가 지표이며, 세로축 숫자를 자율주행 안전성 지표와 동일시할 수도 없다.

## 3. YOLO: 영상 한 번 평가해 box와 class를 함께 출력

13쪽은 YOLO 원 논문을 소개한다. 원형 YOLO는 전체 영상을 하나의 신경망으로 평가하여 box와 관련 클래스 확률을 바로 추정하고, 후처리로 결과를 정리한다. `You Only Look Once`라는 이름은 **영상에서 별도 proposal 생성·분류 단계 없이 한 번의 네트워크 평가로 검출한다**는 취지이지 모든 후처리가 사라진다는 뜻이 아니다.

슬라이드의 **45 fps**는 [원형 YOLO 논문](https://arxiv.org/abs/1506.02640){:target="_blank" rel="noopener"} 초록에 제시된 *base YOLO*의 실험 결과다. 단위 fps는 초당 처리 프레임 수이며 $$45\,\mathrm{fps}$$의 프레임당 단순 역수는 약 $$22.2\,\mathrm{ms}$$다. 이 계산은 처리량의 역수일 뿐 센서 취득·전처리·전송·후처리·planning까지 합친 지연 시간을 뜻하지 않는다. 원 논문은 별도 Fast YOLO 모델에 대해 다른 수치도 보고하므로 45 fps를 **YOLO family 전체의 고정 성능**처럼 적용하지 않는다. 원 논문은 속도와 함께 localization error라는 한계도 설명한다.

## 4. FCOS: anchor-free 위치에서 네 변까지 거리 예측

14–17쪽의 FCOS는 anchor 후보를 미리 정하지 않는다. Feature map의 한 위치가 원본 이미지의 위치 $$(x,y)$$에 대응한다고 할 때, 그 위치가 ground-truth box 내부이면 해당 클래스를 양성으로 지정하고 box의 왼쪽·위·오른쪽·아래 변까지 거리 $$l,t,r,b$$를 회귀한다. 훈련 목표 box를 $$(x_0,y_0,x_1,y_1)$$로 쓰면 **작성자 보충 유도**는 다음과 같다.

$$
l=x-x_0,\qquad t=y-y_0,\qquad r=x_1-x,\qquad b=y_1-y
$$

$$
(x_0,y_0,x_1,y_1)=(x-l,\,y-t,\,x+r,\,y+b)
$$

첫 줄은 네 거리의 **정의**이고 둘째 줄은 그 정의를 풀어 쓴 **정확한 좌표 변환**이다. $$x,y,x_0,y_0,x_1,y_1,l,t,r,b$$는 모두 이미지 **pixel 좌표 또는 pixel 거리**다. 모든 거리가 양수인 것은 위치가 box 내부일 때이며, 바깥 위치는 이 box의 양성 target이 아니다. 슬라이드 예시에서 각 위치가 $$C$$개 class score와 $$4$$개 box 값을 출력하므로 $$5\times6$$ grid에는 각각 $$C\times5\times6$$, $$4\times5\times6$$ 값이 나온다(15–17쪽). 여기서 $$C$$는 class 수, grid 숫자는 설명용이며 무차원 개수다.

**작성자 보충 — 좌표 검산:** box가 $$(10,20,50,60)$$ pixel이고 점이 $$(30,30)$$ pixel이면 $$(l,t,r,b)=(20,10,20,30)$$ pixel이다. 복원식은 다시 $$(10,20,50,60)$$을 준다. 점이 다른 box와도 겹친다면 어느 target을 줄지 별도 assignment 규칙이 필요하다. [FCOS 원 논문](https://openaccess.thecvf.com/content_ICCV_2019/papers/Tian_FCOS_Fully_Convolutional_One-Stage_Object_Detection_ICCV_2019_paper.pdf){:target="_blank" rel="noopener"}은 겹친 box 가운데 면적이 작은 것을 선택하고 FPN level별 허용 거리 범위를 적용한다.

### 4.1 Centerness가 필요한 이유

Box의 가장자리 근처 점도 양성으로 표시하면 위치에 따라 품질이 낮은 box가 많이 나올 수 있다. 18–19쪽은 중앙에 가까운 예측에 높은 목표값을 주는 **centerness**를 추가한다. 슬라이드의 대문자 $$L,T,R,B$$는 앞서 설명한 네 거리와 같은 뜻이다.

$$
c^*=\sqrt{\frac{\min(l,r)}{\max(l,r)}\,\frac{\min(t,b)}{\max(t,b)}}
$$

이는 **학습 목표의 정의**이며 $$0\le c^*\le1$$의 무차원 점수다. 분모가 0인 퇴화 box에는 그대로 적용하지 않는다. 중앙이면 $$l=r$$, $$t=b$$여서 $$c^*=1$$이다. 위 예시의 $$(20,10,20,30)$$에서는 $$c^*=\sqrt{1\cdot(1/3)}\approx0.577$$이다. 경계로 다가가 한쪽 거리가 0에 가까워지면 점수도 0에 가까워진다. 이 유도는 “정중앙의 비율은 1, 비대칭일수록 작다”는 정의의 직접 해석이지 정확한 localization을 보장하는 증명은 아니다.

예측 때는 class score에 **예측 centerness**를 곱해 box를 정렬한다(19쪽). 점수들의 곱은 휴리스틱 결합이며 잘못 검출한 물체를 무조건 제거하는 보증은 아니다. 20쪽 도식에서는 FPN의 여러 해상도에서 class·regression·centerness head를 반복 적용한다. 따라서 FCOS는 **anchor-free이지만 multi-scale과 후처리까지 없는 것은 아니다**.

### 4.2 세 가지 손실은 서로 다른 문제를 푼다

원 논문의 FCOS는 class에 focal loss, box에 IoU 기반 regression loss, centerness에 binary cross-entropy를 사용한다. 16–17쪽의 “box with L2 loss”는 원 논문의 제시 방식과 불일치한다. L2는 좌표별 차이를 작게 하는 다른 손실이며, IoU 손실과 동치가 아니다. 학생이 원 모델을 구현한다면 슬라이드의 L2 문구가 아니라 원 논문과 선택한 구현의 명세를 확인해야 한다.

## Source Check

| 위치 | 판정 | 확인과 이 글의 처리 |
|---|---|---|
| 8–10쪽 RetinaNet class 출력 `2K*(C+1)` | 원 모델과 불일치 | 원 논문의 위치당 $$AK$$ sigmoid 분류와 $$4A$$ box 출력을 사용한다. $$A$$는 anchors/location, $$K$$는 전경 클래스다. |
| 13쪽 YOLO `45fps` | 적용 범위 생략 | 원형 base YOLO 논문의 조건부 측정값으로만 읽는다. YOLO 전체 버전·차량 전체 pipeline의 속도로 일반화하지 않는다. |
| 16–17쪽 FCOS `L2 loss` | 원 논문과 불일치 | FCOS 원 논문은 box 회귀에 IoU loss를 쓴다. 정확한 구현에서는 논문/코드 버전을 확인한다. |
| 18–19쪽 centerness | 정의 확인 | $$\min/\max$$ 비율의 곱에 **제곱근**이 있다. 중심에서 1, 경계에서 0이라는 해석은 유효한 box 내부에서 성립한다. |
| 12쪽 속도–AP 그림 | 실험 조건 제한 | COCO 당시 비교 결과다. 실시간 주행 성능의 보편적 법칙이 아니다. |

## 시험 포인트

- Faster R-CNN의 **image-level backbone/RPN**과 **RoI별 두 번째 분류**를 구분한다.
- RetinaNet에서 anchor 수 증가 → 쉬운 배경 증가 → focal loss의 $$(1-p_t)^\gamma$$가 쉬운 예제 손실을 억제한다는 인과를 설명한다.
- RetinaNet은 **anchor-based**, FCOS는 **anchor-free**지만 둘 다 single-stage와 FPN을 사용할 수 있다.
- FCOS의 $$l,t,r,b$$로 원래 box를 복원하고, centerness를 수치로 계산해 본다.
- 45 fps는 원형 YOLO의 한 설정이고, fps 역수와 end-to-end 주행 지연은 다르다.

## 마지막 핵심 정리

| 모델 | 위치·box 표현 | 핵심 어려움/해결 | 슬라이드 |
|---|---|---|---:|
| Faster R-CNN | RPN 제안 후 RoI별 보정 | 높은 품질의 후보를 두 단계로 처리 | 7 |
| RetinaNet | 위치별 여러 anchor와 FPN | 밀집 배경 불균형을 focal loss로 완화 | 8–12 |
| YOLO 원형 | 영상 한 번 평가해 box·class 출력 | 빠른 처리, 원 논문의 localization 한계 | 13 |
| FCOS | 위치별 $$l,t,r,b$$와 centerness | anchor 설계 제거, 경계 위치 box 품질 억제 | 14–20 |

## Study Guide

먼저 7쪽에서 **proposal이 왜 두 번째 단계인지** 그림을 따라가고, 8–11쪽에서 RetinaNet이 proposal 대신 grid의 anchor를 쓴다는 차이를 잡는다. 이후 focal loss의 $$\gamma=0$$ 및 $$p_t\to1$$ 경계를 직접 대입한다. 14–20쪽에서는 점 하나와 box 하나를 종이에 그려 네 거리, box 복원, centerness를 계산하면 암기보다 오래 남는다. 원 슬라이드의 출력 차원과 L2 문구는 Source Check의 정정을 함께 보아야 한다. 다음 강의는 box로 물체의 범위를 두르는 것에서 픽셀 단위 영역을 표시하는 문제로 넘어간다.

## 복습 질문

<details markdown="block">
<summary>1. Single-stage detector에서 “한 단계”는 정확히 무엇을 줄인다는 뜻인가?</summary>

답변: proposal을 만든 뒤 각 RoI를 별도로 분류·보정하는 두 번째 검출 단계를 제거하고, feature map의 여러 위치에서 box와 class를 직접 예측한다는 뜻이다. Backbone, FPN, 여러 head 및 NMS가 모두 사라진다는 뜻은 아니다.

</details>

<details markdown="block">
<summary>2. RetinaNet에서 배경 anchor가 많으면 왜 focal loss가 유용한가?</summary>

답변: 쉬운 배경 anchor 각각의 CE가 작아도 개수가 많으면 총 학습 기여가 커진다. Focal loss는 정답 확률이 높은 예제에 $$(1-p_t)^\gamma$$를 곱해 그 기여를 더 작게 하고, 상대적으로 어려운 예제의 비중을 유지한다.

</details>

<details markdown="block">
<summary>3. FCOS가 예측하는 네 거리와 centerness는 서로 어떤 역할인가?</summary>

답변: $$l,t,r,b$$는 한 위치에서 box 네 변까지의 pixel 거리라서 box 좌표를 복원한다. Centerness는 점이 box 중앙에 가까운지를 나타내는 무차원 target·예측 점수로, 추론 때 class score와 결합해 경계 위치에서 나온 낮은 품질의 box를 낮게 정렬한다.

</details>

<details markdown="block">
<summary>4. 슬라이드의 FCOS L2 문구를 그대로 원 모델의 손실이라고 적으면 왜 안 되는가?</summary>

답변: FCOS 원 논문은 box 회귀에 IoU loss를 사용한다. L2와 IoU는 최적화하는 양이 다르므로, 슬라이드의 문구는 원 논문과 불일치하는 자료상 오류로 구분해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 7 source slides (PDF)</a></li>
</ul>

## References

- <a href="https://arxiv.org/abs/1506.01497" target="_blank" rel="noopener">Ren et al., Faster R-CNN</a> — two-stage 비교 기준.
- <a href="https://openaccess.thecvf.com/content_ICCV_2017/papers/Lin_Focal_Loss_for_ICCV_2017_paper.pdf" target="_blank" rel="noopener">Lin et al., Focal Loss for Dense Object Detection</a> — RetinaNet head와 focal loss의 원문.
- <a href="https://arxiv.org/abs/1506.02640" target="_blank" rel="noopener">Redmon et al., You Only Look Once</a> — 원형 YOLO의 45 fps 적용 범위.
- <a href="https://openaccess.thecvf.com/content_ICCV_2019/papers/Tian_FCOS_Fully_Convolutional_One-Stage_Object_Detection_ICCV_2019_paper.pdf" target="_blank" rel="noopener">Tian et al., FCOS</a> — 네 거리, centerness, IoU box loss의 원문.
