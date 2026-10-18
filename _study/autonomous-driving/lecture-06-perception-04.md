---
layout: default
date: 2026-09-21 00:00:00 +0900
last_modified_at: 2026-10-18 18:30:39 +0900
title: "Lecture 6: Perception (4) - Faster R-CNN and Feature Pyramid Networks"
course: "Autonomous Driving"
topic: "Region Proposal Networks, Anchor Boxes, and Multiscale Features"
order: 6
major_topic: "Autonomous Systems"
keywords:
  - "Object Detection"
  - "Faster R-CNN"
  - "RPN"
  - "Anchor Box"
  - "Feature Pyramid Network"
  - "Small Objects"
---

# Lecture 6: Perception (4) - Faster R-CNN and Feature Pyramid Networks

Source PDF: [6 Perception (4).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf" | relative_url }})

[5강의 Fast R-CNN]({{ "/study/autonomous-driving/lecture-05-perception-03/" | relative_url }})은 영역별 CNN 계산을 줄였지만 region proposal을 만드는 별도 단계는 남겼다. 국민대학교 Youngwook Kim 교수의 *Automatic Driving Computing* 6강에서는 이를 **RPN**으로 통합하고, 다양한 크기의 물체를 **FPN**으로 처리하는 흐름을 다룬다. 강의 그림의 수치와 이후 논문의 구현 세부는 구분한다.

> **핵심:** Faster R-CNN은 별도의 Selective Search 대신 공유 CNN feature 위에서 RPN이 objectness와 anchor별 box 보정을 예측한다. 그래도 깊은 feature map 하나만 사용하면 작은 물체의 공간 정보가 부족할 수 있다. FPN은 높은 층의 의미 정보와 낮은 층의 위치 해상도를 top-down·lateral 연결로 합쳐 여러 크기의 물체를 처리한다.

## 전체 흐름

| 순서 | 원문 범위 | 핵심 질문 |
|---|---|---|
| 1 | 1–8쪽 | Fast R-CNN에 남은 제안 영역 생성 병목은 무엇인가? |
| 2 | 9–16쪽 | RPN은 feature 위치마다 anchor의 objectness·box offset을 어떻게 만든다? |
| 3 | 17–19쪽 | 두 단계 검출기는 어떤 네 가지 손실과 추론 단계로 묶이는가? |
| 4 | 20–26쪽 | image pyramid와 단순 multi-stage feature 검출의 약점은 무엇인가? |
| 5 | 27–35쪽 | FPN의 top-down·lateral 융합이 작은 물체 문제에 어떻게 대응하는가? |

## 1. Fast R-CNN의 남은 병목

Fast R-CNN은 이미지의 convolution을 proposal마다 되풀이하지 않고 **공유 feature map**을 쓴다. 그러나 box 후보 자체는 Selective Search 같은 별도 알고리즘에서 가져온다. 원문 7쪽은 이 고전적 CPU 알고리즘의 실행 시간이 새 병목이 되었다고 설명한다. 슬라이드 그래프의 특정 수치(예: Fast R-CNN 검출 0.32초, region proposal을 포함하면 약 2.3초)는 그 실험 설정의 측정치이지 모든 모델·하드웨어의 보편 속도가 아니다. 원 Faster R-CNN 논문도 Selective Search의 CPU 구현과 GPU 검출기의 실행 환경이 다름을 명시한다.

원문 8쪽의 해법은 **feature를 재사용하면서 proposal 생성도 학습하는 것**이다. 공유 backbone의 feature map에 Region Proposal Network(RPN)를 올려 “어디가 물체일 가능성이 높은가?”와 “그 상자를 얼마나 움직이고 늘릴까?”를 예측한다. Faster R-CNN은 RPN이 후보를 만든 뒤 Fast R-CNN형 검출 head가 그 후보의 class와 정확한 box를 최종 판단하는 **two-stage detector**다. RPN의 objectness는 class-agnostic한 물체/배경 판정이고, 두 번째 stage의 분류는 예를 들어 car·person·dog를 구분한다.

## 2. RPN이 anchor를 proposal로 바꾸는 과정

<figure id="adc-06-p16">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-06-p16.png" | relative_url }}" alt="K개 anchor마다 objectness와 네 box 보정값을 출력하는 RPN" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>.</figcaption>
</figure>

한 feature 위치마다 K개 anchor가 있고, objectness head와 box-regression head가 같은 feature를 읽는다. 그림의 K=6 예에서는 두 head의 channel 수가 각각 2K와 4K로 다르다. 앞쪽 점수는 물체일 가능성이고 뒤쪽 네 값은 기준 box를 이동·확대할 보정값이다. Proposal 선택에는 이 예측의 decode와 후처리가 필요하다.

원문 9–16쪽은 고양이 영상 한 장에서 RPN을 순서대로 그린다. CNN backbone이 이미지 좌표와 대응되는 feature map을 만들고, 각 feature 위치에 **기준 상자(anchor)**를 놓는다. 한 위치에 크기·종횡비가 다른 $$K$$개 anchor를 두면 서로 다른 형태의 물체 후보를 같은 feature에서 살펴볼 수 있다. 강의 그림은 처음에는 **한 위치에 anchor 1개**를 설명하고, 이후 $$K=6$$인 교육용 예시로 확장한다. 원 Faster R-CNN 논문의 대표 설정 $$k=9$$와 다르므로, $$K=6$$을 원 논문의 고정값으로 일반화하면 안 된다.

**Anchor는 정답도, 검출 결과도 아니다.** 미리 정한 위치·크기의 기준 box이고, 네트워크는 이미지 feature를 보고 이 기준을 얼마나 보정할지 학습한다. 같은 anchor라도 입력 이미지가 달라지면 예측 점수와 보정값이 달라진다.

**Supplementary table — Anchor, ground truth, and prediction.** 위 그림의 기준 상자, 학습 때 대조하는 정답, 네트워크 출력으로 만든 상자의 역할을 구분한다.

| 구분 | 어디서 오는가? | 무엇에 쓰이는가? |
|---|---|---|
| Anchor | Feature 위치와 미리 정한 크기·종횡비 | 예측할 이동·크기 변화의 기준 |
| GT (ground truth) | 학습 데이터에 주어진 객체의 정답 box | Anchor의 label과 목표 보정값을 계산 |
| Prediction | 네트워크가 낸 보정값을 anchor에 적용한 box | RPN 후처리를 거쳐 proposal 후보가 됨 |

GT는 학습의 감독 신호이며 **추론 때는 필요하지 않다**. RPN에서 decode한 box는 아직 최종 검출 결과가 아니라 proposal 후보다. 다음 detection head가 class를 판단하고 box를 다시 보정한다. Objectness 점수도 box 좌표 자체가 아니며 GT와의 IoU를 정확히 예측한 값이라는 보장은 없다.

원문에서 feature map의 예시 공간 크기는 $$5\times6$$, channel 수는 512다. 위치마다 $$K$$개 anchor라면 총 후보 수는 $$5\cdot6\cdot K$$개다. RPN 출력은

$$
\text{objectness logits}: 2K\times5\times6,
\qquad
\text{box offsets}: 4K\times5\times6
$$

로 나타난다. $$K=6$$을 대입하면 각각 $$12\times5\times6$$과 $$24\times5\times6$$이며 후보는 180개다. 여기서 $$2K$$는 anchor별 물체/배경 두 logit, $$4K$$는 anchor별 중심 이동 두 값·크기 변화 두 값이다. $$K$$와 feature grid 크기는 **개수/무차원**, box 좌표와 크기는 해당 이미지 좌표계의 pixel, logit과 offset은 **무차원**이다. 예시 feature map `512×5×6`은 이 강의의 설명용 그림이지 입력 `640×480`의 보편적인 실제 CNN 출력 비율이 아니다.

### 2.1 Box offset의 정의와 역변환

왜 box의 절대 pixel 좌표 대신 anchor에 대한 상대 offset을 예측할까? 같은 10 pixel 이동도 폭 20 pixel인 상자에는 큰 변화이고 폭 200 pixel인 상자에는 작은 변화다. 이동을 anchor 폭·높이로 나누면 **기준 크기에 비해 얼마나 움직이는지** 표현할 수 있다. 크기는 양수여야 하므로 폭·높이의 비율을 로그로 표현하고, decode할 때 지수함수로 되돌린다.

다음은 강의 14쪽의 anchor-to-GT transform을 풀어 쓴 **작성자 설명용 예시**다. 좌표는 box의 중심이며 모든 좌표·크기의 단위는 pixel이다. 실제 모델의 실행 결과가 아니다.

- **Anchor:** 중심 (100, 100), 폭 40, 높이 20.
- **GT:** 중심 (112, 98), 폭 60, 높이 20.
- **Prediction:** 중심 (110, 100), 폭 60, 높이 20.

GT에 맞추려면 anchor를 오른쪽 12 pixel, 위쪽 2 pixel 옮기고 폭을 1.5배로 늘려야 한다. 따라서 목표 offset은 $$(0.30,-0.10,\ln 1.5,0)$$이다. 반면 네트워크가 $$(0.25,0,\ln 1.5,0)$$을 예측했다면 오른쪽으로 $$40\times0.25=10$$ pixel만 이동한다. 결과는 중심 $$(110,100)$$, 크기 $$(60,20)$$이다. **폭은 맞았지만 중심은 GT보다 왼쪽 2 pixel, 아래쪽 2 pixel에 남는다.** 학습은 이런 오차를 줄이는 과정이지 anchor 자체를 정답으로 사용하는 과정이 아니다.

네 offset은 모두 무차원이다. 좌표계는 위쪽으로 갈수록 y가 작아지는 이미지 좌표계를 사용했다. Anchor가 정답과 너무 동떨어져 있으면 큰 보정이 필요하므로, 여러 크기·종횡비의 anchor를 두고 적절한 positive anchor를 학습에 사용한다.

<details markdown="block">
<summary markdown="span">Derivation: Encoding a target and decoding a predicted box</summary>

원 Faster R-CNN 논문의 box parameterization은 **회귀 대상을 정하는 정의**다. Anchor를 $$(x_a,y_a,w_a,h_a)$$, 매칭된 GT를 $$(x_g,y_g,w_g,h_g)$$라 하고 모든 폭·높이가 양수라고 가정한다. 목표 offset에는 별표를 붙여 네트워크 예측값 $$\hat{t}$$와 구분한다.

$$
t_x^*=\frac{x_g-x_a}{w_a},\qquad
t_y^*=\frac{y_g-y_a}{h_a},\qquad
t_w^*=\ln\frac{w_g}{w_a},\qquad
t_h^*=\ln\frac{h_g}{h_a}.
$$

이동량의 분자·분모는 모두 pixel이므로 단위가 상쇄된다. 로그의 입력도 양수인 크기 비율이다. $$\ln$$은 자연로그다. 본문 예시의 목표값을 계산하면

$$
t^*=
\left(\frac{112-100}{40},\frac{98-100}{20},
\ln\frac{60}{40},\ln\frac{20}{20}\right)
=(0.30,-0.10,\ln1.5,0).
$$

역변환은 이 정의를 좌표에 대해 푼 **정확한 등식**이다. 예를 들어 $$t_x=(x-x_a)/w_a$$의 양변에 $$w_a$$를 곱하고 $$x_a$$를 더하면 $$x=x_a+w_at_x$$가 된다. 크기는 $$t_w=\ln(w/w_a)$$에서 양변에 지수함수를 적용해 $$e^{t_w}=w/w_a$$를 얻고, $$w_a$$를 곱한다. 따라서 예측 offset을 decode하면

$$
\hat{x}=x_a+w_a\hat{t}_x,\qquad
\hat{y}=y_a+h_a\hat{t}_y,\qquad
\hat{w}=w_a e^{\hat{t}_w},\qquad
\hat{h}=h_a e^{\hat{t}_h}.
$$

본문 예측값의 검산은 $$\hat{x}=100+40(0.25)=110$$, $$\hat{y}=100+20(0)=100$$, $$\hat{w}=40e^{\ln1.5}=60$$, $$\hat{h}=20e^0=20$$이다. 목표값 $$t^*$$를 대신 decode하면 GT $$(112,98,60,20)$$를 복원한다. 이는 encode/decode가 서로 역연산이라는 뜻이며, 실제 예측 $$\hat{t}$$가 목표 $$t^*$$와 같다는 보장은 아니다. 실제 구현에서는 이후 이미지 경계 clipping 등의 처리가 이어질 수 있다.

</details>

### 2.2 Positive·negative·neutral anchor

원문 15쪽의 학습 규칙은 정답 box(GT)와의 IoU를 사용한다.

- **Positive:** 어느 GT와 IoU $$>0.7$$이거나, 각 GT에 대해 IoU가 가장 높은 anchor. 최고 IoU anchor 조건 덕분에 0.7에 못 미치는 GT도 적어도 하나의 학습 후보를 얻을 수 있다.
- **Negative:** 모든 GT와 IoU $$<0.3$$인 non-positive anchor.
- **Neutral:** 그 사이에 있으면서 positive도 아닌 anchor. 해당 예시 규칙에서는 학습 손실 계산에서 제외한다.

여기서 0.7·0.3은 **RPN 학습 label 기준**이고, 5강의 NMS 0.7 또는 AP 매칭 0.5와 역할이 다르다. 같은 box 좌표계에서 면적 양수인 상자끼리 IoU를 계산한다. Positive anchor만 목표 box offset을 갖고 box regression 손실에 참여한다. Negative anchor에 임의의 GT transform을 강제로 학습시키면 안 된다. 원 Faster R-CNN 논문에서도 regression loss는 positive anchor에서만 활성화된다.

**Supplementary table — Which anchors train which head?** 위 label 규칙으로 분류한 뒤 minibatch에 선택된 anchor가 어느 손실에 참여하는지 대응시킨 표다. Head가 값을 출력하는 것과 그 값에 학습 손실을 부여하는 것은 다르다.

| Anchor state | Objectness target | Box-regression target |
|---|---|---|
| Positive | 물체 1로 학습 | 매칭된 GT의 상대 offset으로 학습 |
| Negative | 배경 0으로 학습 | 제외; 배경에는 맞출 객체 box가 없음 |
| Neutral | 제외 | 제외 |

Negative도 objectness를 낮추는 데 필요한 학습 예다. 반면 neutral은 애매한 위치를 강제로 배경이나 물체로 학습시키지 않도록 두 손실에서 빠진다. 이 표는 RPN의 감독 신호이며, 추론 단계에서 GT label을 계산한다는 뜻은 아니다.

### 2.3 추론에서 proposal을 고르는 순서

원문 16쪽은 $$K\cdot5\cdot6$$개 상자의 물체 점수를 정렬하고 **상위 300개**를 region proposal로 삼는 대표 흐름을 보여준다. 정확하게는 원 논문 구현에는 경계 box 처리와 높은 겹침을 줄이는 **NMS** 같은 후처리가 있으며, top-N을 취하는 단계의 위치와 개수는 구현·학습/시험 설정에 따라 달라진다. 따라서 “score 정렬만 하고 NMS 없이 무조건 300개”가 Faster R-CNN의 보편 정의는 아니다. 원문 그림의 $$K=6,5\times6$$을 그대로 대입하면 raw anchor가 180개뿐이므로 **그 동일 예시에서 실제로 300개를 선택할 수는 없다**. 원문 300은 실제 고해상도 feature map을 쓰는 논문 설정을 보여주는 별도 관례로 읽어야 한다.

## 3. 왜 Faster R-CNN은 두 단계인가

원문 17쪽의 네 손실은 역할을 두 단계로 나누면 이해가 쉽다.

| 단계 | 예측 | 학습 신호 |
|---|---|---|
| 1단계 RPN | anchor의 물체/배경 objectness | RPN classification loss |
| 1단계 RPN | anchor → proposal의 상대 offset | RPN box regression loss, positive anchor에서만 |
| 2단계 detection head | proposal의 배경/구체적 객체 class | Object classification loss |
| 2단계 detection head | proposal → 최종 object box의 offset | Object box regression loss, 대상 객체에서만 |

첫 단계의 backbone과 RPN은 이미지당 한 번 실행하고, 둘째 단계의 RoI pooling/align과 head는 proposal마다 실행한다(원문 19쪽). “jointly train with 4 losses”는 네 손실을 구분하는 개념도이며, 모든 버전이 처음부터 끝까지 단일 optimizer로 완전 end-to-end 학습했다는 뜻은 아니다. 원 Faster R-CNN 논문은 feature 공유를 위한 **alternating optimization**을 제시했다. 학습법과 추론 구조를 혼동하지 않는 것이 중요하다.

원문 18쪽은 설정별 시험 시간 그래프를 통해 R-CNN 49초, SPP-Net 4.3초, Fast R-CNN 2.3초, Faster R-CNN 0.2초라는 비교를 제시한다. 이 수치는 특정 backbone·GPU·proposal 알고리즘·프로토콜을 전제한 역사적 예시다. 0.2초는 약 5 FPS이지, 그 자체로 모든 자율주행 시스템의 안전 요구나 실시간 마감시간을 충족한다고 단정할 수 없다.

## 4. 작은 물체가 어려운 이유

멀리 있는 자동차·보행자처럼 영상에서 작게 보이는 물체는 깊은 feature map에서 몇 cell 이하로 줄어들 수 있다. 반복 downsampling이 경계와 세부 정보를 잃게 하고, localization에 쓸 공간 근거가 약해진다. 원문 21쪽은 같은 도로 장면에서 크기가 다른 차량을 제시하고, 22쪽은 모델별 COCO 결과표에서 작은 물체 AP가 중·대형보다 낮은 예를 보여준다. 다만 표의 행마다 모델·학습 데이터·평가 열이 달라 **모든 행을 동일 조건의 직접 비교 실험처럼 읽을 수는 없다**. 핵심은 작은 물체에 대해 성능이 특히 낮다는 문제 제기다.

### 4.1 Image pyramid와 단순 feature hierarchy

원문 23–24쪽의 고전적인 **image pyramid**는 입력 이미지를 여러 해상도로 resize하고 각 스케일에 detector를 실행한다. 작은 물체를 확대된 입력에서 포착할 수 있지만 스케일마다 이미지 특징을 다시 계산해야 해 비용이 커진다.

원문 25–26쪽의 대안은 하나의 CNN이 계산한 stage별 feature를 이용하는 것이다. 강의 도식에서 224×224 입력이 stage 2의 56×56, stage 3의 28×28, stage 4의 14×14, stage 5의 7×7 feature로 내려간다. 높은 해상도의 초기 stage는 작은 물체의 위치를 더 세밀하게 보지만, 깊은 stage의 **전체 backbone 의미 정보**를 아직 받지 못한다. 각 stage에 detector만 붙이는 것은 높은 공간 해상도와 강한 semantic feature를 동시에 얻는 답이 아니다. 단계별 크기는 이 그림의 예시이고 네트워크 구조마다 달라진다.

## 5. FPN: 높은 의미 정보와 높은 해상도를 결합하기

<figure id="adc-06-p31">
  <img src="{{ "/assets/images/study/autonomous-driving/source-captures/adc-06-p31.png" | relative_url }}" alt="Image pyramid와 단일 feature map 및 FPN의 비교" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf#page=31" | relative_url }}">lecture PDF, p. 31</a>.</figcaption>
</figure>

(a)는 입력 이미지를 여러 크기로 다시 처리하고, (c)는 CNN 중간의 서로 다른 해상도에서 예측한다. (d)의 FPN에는 높은 층에서 내려오는 top-down 경로와 같은 해상도의 lateral 연결이 함께 있다. 따라서 단순히 feature map을 여러 장 쓰는 것만이 아니라 높은 층의 의미 정보를 더 촘촘한 공간 격자에 전달하는 점이 핵심이다.

FPN(Feature Pyramid Network)은 bottom-up backbone의 여러 해상도 $$C_2,C_3,C_4,C_5$$를 보존하고, 깊은 층에서 얕은 층으로 정보가 흐르는 **top-down pathway**와 같은 해상도의 **lateral connection**을 만든다(원문 27–31쪽). 핵심 결합은 “깊은 feature를 2배 upsample” + “현재 stage feature를 1×1 convolution으로 channel 정렬” + “원소별 합”이다.

$$
P_5=\operatorname{Conv}_{1\times1}(C_5),\qquad
P_l=\operatorname{Conv}_{1\times1}(C_l)
 +\operatorname{Upsample}_{2\times}(P_{l+1}),\quad l=4,3,2.
$$

이는 원문 28–30쪽의 도식을 표현한 **구성식**이다. $$C_l$$은 bottom-up stage $$l$$의 feature tensor, $$P_l$$은 융합된 pyramid tensor, $$l$$은 stage index(무차원)다. 원소별 합이 성립하려면 두 tensor의 높이·폭·channel 수를 같게 맞춰야 한다. $$1\times1$$ convolution은 위치당 channel을 투영하고, upsample은 공간 크기를 맞춘다. 예를 들어 $$P_5$$가 7×7이고 $$C_4$$가 14×14라면 $$P_5$$를 2배 키워 14×14에 맞춘 뒤 더한다. 그 결과 $$P_4$$는 stage 4의 상대적으로 세밀한 위치 신호와 stage 5의 의미 정보를 함께 받는다. 이 합은 미분 방정식의 유도 결과가 아니라 **설계된 네트워크 연산**이다.

원 FPN 논문은 이 융합 뒤 3×3 convolution으로 upsampling aliasing을 줄여 최종 pyramid feature를 만든다. 이 단계는 원문 단순 도식에는 생략돼 있으므로 **원 논문 보충**으로 구분한다. FPN이 곧 작은 물체를 완벽하게 검출한다는 보장은 없으며, 입력 해상도 부족·심한 가림·label 품질·anchor/level 배치 등의 한계는 남는다.

FPN을 Faster R-CNN에 결합할 때 각 pyramid 수준에 RPN head를 두어 크기별 proposal을 생성하고, 생성된 proposal은 공유되는 둘째-stage 검출기로 전달할 수 있다(원문 30쪽). **FPN은 RPN의 대체제가 아니라 RPN과 detector가 쓸 다중 스케일 feature 표현**이다. 원문 31쪽의 네 도식은 (a) 입력별 image pyramid, (b) 단일 feature map, (c) backbone의 피라미드형 feature hierarchy, (d) top-down·lateral 연결을 갖춘 FPN을 비교한다.

## 원문 정확성 검토: Source Check

| 원문 위치 | 확인한 내용 | 이 글의 처리 |
|---|---|---|
| 7·18쪽 | 시간 그래프는 R-CNN 49초부터 Faster R-CNN 0.2초까지의 역사적 비교를 제시한다. | 하드웨어·backbone·proposal 설정에 의존하는 실험 수치로만 소개했다. 임의의 자율주행 배포 성능으로 확대하지 않았다. |
| 15–16쪽 | 도식은 $$K=6$$, feature 5×6으로 180개 raw anchor를 그린 다음 top 300 proposal이라고 적는다. | 두 값이 같은 예제 안에서는 양립하지 않음을 계산해 밝히고, `top 300`은 원 논문의 실제 feature map 설정에서의 별도 예시로 분리했다. 또한 실제 RPN의 NMS를 원 논문에서 확인해 보충했다. |
| 17쪽 | 네 손실을 “jointly train”이라고 요약한다. | 손실 항목의 개념적 결합으로 설명하고, 원 논문의 feature 공유 학습은 alternating optimization이었다는 점을 구분했다. |
| 22쪽 | 작은 물체 AP가 낮은 모델별 표가 나온다. | 서로 다른 행의 학습 데이터·평가값이 동일 실험조건이라고 전제하지 않고 문제의 방향만 해석했다. |

## 마지막 핵심 정리

| 단계 | 입력과 출력 | 해결하는 병목 또는 문제 |
|---|---|---|
| Fast R-CNN | 이미지 → 공유 feature; 외부 proposal → class/box | proposal마다 CNN을 다시 돌리는 중복 계산 |
| RPN / Faster R-CNN | 공유 feature → anchor별 objectness·offset → proposal → 최종 class/box | 별도 Selective Search의 proposal 생성 비용 |
| FPN | backbone의 여러 해상도 → top-down·lateral 융합 feature | 작은 물체의 위치 해상도와 깊은 의미 정보 사이의 간극 |

## Study Guide

1. **먼저 병목 사슬을 외운다:** R-CNN의 proposal별 CNN → Fast R-CNN의 공유 feature → Faster R-CNN의 학습형 RPN → FPN의 다중 크기 feature.
2. **숫자로 검산한다:** 강의의 $$5\times6$$ feature, $$K=6$$이면 anchor는 180개, objectness logit은 360개, box offset 숫자는 720개다. `300 proposals`가 이 장난감 feature 예시와 다름을 설명한다.
3. **Anchor label을 구분한다:** positive의 `최고 IoU 또는 >0.7`, negative의 `<0.3`, neutral의 학습 제외를 작은 표로 다시 써 본다.
4. **FPN 그림을 설명한다:** image pyramid와 feature hierarchy의 계산·의미 한계를 먼저 말하고, stage 5의 7×7을 stage 4의 14×14에 맞춰 합하는 이유를 설명한다.
5. **실패 조건을 기억한다:** RPN anchor가 맞지 않으면 proposal recall이 떨어지고, FPN도 정보가 처음부터 영상에 없거나 너무 작으면 복구할 수 없다.

## 복습 질문

<details markdown="block">
<summary>1. Fast R-CNN이 빠른데도 Faster R-CNN이 왜 필요한가?</summary>

답변: Fast R-CNN은 이미지를 CNN에 한 번 통과시켜 feature를 공유하지만 region proposal을 얻는 Selective Search 같은 외부 알고리즘은 남는다. Faster R-CNN은 공유 feature 위에서 RPN이 proposal을 예측하여 그 병목을 줄인다.

</details>

<details markdown="block">
<summary>2. RPN의 objectness와 두 번째 stage의 class prediction은 어떻게 다른가?</summary>

답변: RPN objectness는 anchor가 어떤 물체일 가능성이 있는지 배경과 이진 구분하는 class-agnostic 점수다. 두 번째 stage는 선택된 proposal을 RoI feature로 바꾼 뒤 구체적인 객체 class와 더 정밀한 box를 예측한다.

</details>

<details markdown="block">
<summary>3. 5×6 feature와 위치당 6개 anchor에서 RPN의 출력 모양은?</summary>

답변: 위치는 30개, 전체 anchor는 180개다. anchor마다 물체/배경 logit 2개라 $$2K\times5\times6=12\times5\times6$$, box offset 4개라 $$4K\times5\times6=24\times5\times6$$이다. 이 그림에서 raw 후보 180개보다 많은 300개를 실제로 선택할 수는 없다.

</details>

<details markdown="block">
<summary>4. Anchor 중심 100 pixel·폭 40 pixel에서 offset 0.25와 log-width offset log 2를 적용하면?</summary>

답변: 역변환 $$x=x_a+w_at_x$$로 중심은 $$100+40(0.25)=110$$ pixel이다. $$w=w_ae^{t_w}$$로 폭은 $$40e^{\log2}=80$$ pixel이다. 높이도 대응하는 식으로 계산한다.

</details>

<details markdown="block">
<summary>5. FPN의 lateral connection이 단순 upsampling보다 필요한 이유는?</summary>

답변: 깊은 feature는 의미 정보가 강하지만 해상도가 거칠다. 이를 upsample만 하면 위치의 정확도가 자동으로 복구되지 않는다. 같은 공간 크기의 얕은 feature를 1×1 convolution으로 channel 정렬해 더하면 비교적 정확한 위치 정보와 깊은 의미 정보가 함께 전달된다.

</details>

<details markdown="block">
<summary>6. FPN은 RPN을 없애는가, 아니면 RPN의 입력을 바꾸는가?</summary>

답변: RPN을 없애지 않는다. 단일 feature map 대신 여러 수준의 FPN feature를 RPN이 사용해 크기가 다른 물체의 proposal을 만들게 한다. 그 proposal들은 두 번째 stage 검출에 쓰인다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture 6 source slides (PDF)</a></li>
</ul>

## References

- Shaoqing Ren et al., <a href="https://papers.nips.cc/paper/2015/file/14bfa6bb14875e45bba028a21ed38046-Paper.pdf" target="_blank" rel="noopener">Faster R-CNN: Towards Real-Time Object Detection with Region Proposal Networks</a>, NeurIPS 2015. RPN label, box transform, NMS와 feature 공유 학습의 원 논문.
- Tsung-Yi Lin et al., <a href="https://arxiv.org/pdf/1612.03144" target="_blank" rel="noopener">Feature Pyramid Networks for Object Detection</a>, CVPR 2017. Top-down·lateral 연결과 RPN 결합의 원 논문.
- Ross Girshick, <a href="https://arxiv.org/pdf/1504.08083" target="_blank" rel="noopener">Fast R-CNN</a>, ICCV 2015. Faster R-CNN의 두 번째 stage와 RoI pooling에 대한 선행 논문.
