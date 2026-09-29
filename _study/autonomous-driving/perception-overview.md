---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Perception Review: From Image Classification to Instance Segmentation"
course: "Autonomous Driving"
topic: "Integrated Review of Visual Representations, Detection, and Segmentation"
order: 9
major_topic: "Autonomous Systems"
keywords:
  - "Visual Perception"
  - "Object Detection"
  - "Feature Pyramid Networks"
  - "FCOS"
  - "Instance Segmentation"
  - "Average Precision"
---

# Perception Review: From Image Classification to Instance Segmentation

Source PDF: [Perception 1]({{ "/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf" | relative_url }}), [Perception 2]({{ "/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf" | relative_url }}), [Perception 3]({{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf" | relative_url }}), [Perception 4]({{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf" | relative_url }}), [Perception 5]({{ "/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf" | relative_url }}), [Perception 6]({{ "/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf" | relative_url }}).

> **핵심:** 시각 인지는 이미지의 이름을 맞히는 문제에서 시작해, 여러 물체의 위치·경계·개체를 구분하는 문제로 확장된다. 구조의 발전은 반복 연산, 작은 물체, 배경 불균형, 공간 정렬이라는 서로 다른 문제를 해결하는 과정이다. **출력의 의미, 좌표계, 학습 손실, 평가 지표를 함께 설명할 수 있어야 모델을 이해한 것이다.**

국민대학교 자율주행 수업의 Perception 1–6은 이미지 분류에서 시작해 위치 추정, 객체 검출, 분할로 범위를 넓힌다. 개별 강의 노트에는 슬라이드별 설명과 수식 점검을 두고, 이 통합 복습에서는 개념의 연결과 직접 계산하는 예제에 집중한다. **외부 보강**은 원 논문·공식 평가 구현에 근거하며, 별도 표기가 없는 계산 예제는 원리 설명용으로 구성한 값이지 논문의 실험 결과가 아니다.

## 전체 흐름

| 자료 | 주요 내용과 원문 범위 | 상세 글 |
|---|---|---|
| Perception 1, 57 pages | 이미지 분류·학습, pp. 8–22; CNN, pp. 24–33; ViT, pp. 35–53 | [Lecture 3](/study/autonomous-driving/lecture-03-perception-01/) |
| Perception 2, 40 pages | 위치 추정·IoU, pp. 11–20; 다중 물체·R-CNN, pp. 22–36 | [Lecture 4](/study/autonomous-driving/lecture-04-perception-02/) |
| Perception 3, 32 pages | NMS·AP, pp. 6–17; Fast R-CNN·RoI pooling, pp. 19–28 | [Lecture 5](/study/autonomous-driving/lecture-05-perception-03/) |
| Perception 4, 35 pages | RPN·Faster R-CNN, pp. 7–19; FPN, pp. 21–31 | [Lecture 6](/study/autonomous-driving/lecture-06-perception-04/) |
| Perception 5, 24 pages | Dense detection·RetinaNet, pp. 7–12; YOLO·FCOS, pp. 13–20 | [Lecture 7](/study/autonomous-driving/lecture-07-perception-05/) |
| Perception 6, 30 pages | Semantic segmentation·upsampling, pp. 7–17; instance segmentation, pp. 18–26 | [Lecture 8](/study/autonomous-driving/lecture-08-perception-06/) |

## 용어 정의

| 용어 | 이 리뷰에서의 뜻 |
|---|---|
| Perception (인지) | 센서 데이터에서 주변 장면의 의미 있는 정보를 추정하는 과정이다. 강의의 도입부에서는 물체를 ‘식별’한다고 표현하지만, 이 리뷰에서는 분류뿐 아니라 물체의 위치와 개수, 픽셀별 범주와 개체 경계를 알아내는 검출·분할까지 포함한다. |
| Convolution (합성곱) | 작은 필터(커널)를 입력의 국소 영역마다 적용해 대응하는 값들을 곱한 뒤 합산하고 특징맵을 만드는 연산이다. CNN에서는 같은 커널 가중치를 여러 위치에서 공유한다. 실무의 많은 CNN 구현은 커널을 뒤집지 않는 교차상관(cross-correlation)을 관례적으로 convolution이라고 부른다. |

## 1. 먼저 출력의 의미를 정한다

같은 카메라 영상이라도 질문이 달라지면 정답 데이터와 출력 형태가 달라진다. 이미지 전체에 자동차가 있다는 사실만으로 자동차의 위치나 개수를 알 수는 없다.

| Task | 예측해야 할 것 | 정답의 기본 단위 | 구분해야 하는 정보 |
|---|---|---|---|
| Classification | 이미지의 범주 | 이미지와 class label | 무엇인가 |
| Single-object localization | 범주와 하나의 box | label와 4개 좌표 | 무엇이 어디에 있는가 |
| Object detection | 가변 개수의 범주·box·score | 각 물체의 label와 box | 몇 개이며 각각 어디인가 |
| Semantic segmentation | 각 픽셀의 범주 | pixel-wise class map | 어느 픽셀이 어느 범주인가 |
| Instance segmentation | 개체별 범주와 mask | instance별 binary mask | 같은 범주 안에서 어느 개체인가 |

**Semantic segmentation의 같은 색이 같은 개체를 뜻하지는 않는다.** 사람 둘이 붙어 있어도 둘 다 person으로 표시될 수 있다. 반대로 instance mask는 두 사람을 별도 개체로 나눈다. 도로처럼 넓게 이어지는 영역과 셀 수 있는 물체를 함께 다루려면 데이터셋의 things/stuff 정의까지 확인해야 한다.

자율주행 관점에서 이 구분은 출력의 사용처를 정한다. 2D box는 영상 속 위치이고 거리의 단위인 미터가 아니다. 도로 mask 역시 바로 주행 가능한 3D 공간을 증명하지 않는다. 거리 추정·보정·시간적 추적과 결합하는 단계는 이 강의 묶음의 2D 인지 범위를 넘어선다.

## 2. 분류에서 검출까지 공통으로 쓰는 학습 원리

### 2.1 특징, 예측, 손실, 갱신

이미지 $$x$$에서 backbone이 특징 $$F=f_\theta(x)$$를 만들고, head가 필요한 형태의 출력을 계산한다. 분류에서는 class score, 검출에서는 score와 좌표, 분할에서는 위치별 class score가 나온다. 같은 backbone을 쓰더라도 head와 정답의 구조가 다르다.

단일 정답 class $$y$$에 대한 softmax와 cross-entropy를 쓰면 다음과 같다. $$z_c$$는 logit이고 $$p_c$$는 class 확률로 모델링한 값이다. 두 값 모두 무차원이다.

$$
p_c=\frac{e^{z_c}}{\sum_j e^{z_j}},\qquad L=-\log p_y=-z_y+\log\sum_j e^{z_j}.
$$

**도출 이유:** 정답 class에 할당한 확률을 최대화하려면 그 확률의 음의 로그를 최소화하면 된다. 독립 표본들의 likelihood를 곱하면 로그를 취했을 때 손실의 합이 되므로 minibatch 평균으로 학습하기 편하다. 이는 categorical likelihood라는 모델링 선택이지 모든 예측 문제에 강제되는 법칙은 아니다.

위 식을 $$z_c$$로 미분하면 지수함수의 미분과 chain rule로

$$
\frac{\partial L}{\partial z_c}=p_c-\mathbf{1}[c=y]
$$

를 얻는다. 정답 확률이 0.2면 정답 logit의 미분은 −0.8이므로 gradient descent는 그 logit을 높이는 방향으로 움직인다. 다른 class의 양의 미분은 해당 logit을 낮추는 방향을 만든다. 실제 가중치 갱신에는 logit에서 가중치까지의 chain rule이 추가된다.

$$
\theta_{t+1}=\theta_t-\eta\nabla_\theta L.
$$

학습률 $$\eta$$는 갱신 크기를 정한다. 한 번의 갱신이 모든 표본의 손실을 줄이거나 전역 최적해를 보장하지는 않는다. 이 식은 SGD의 기본 형태이며 Adam의 적응적 갱신과 같은 식으로 취급하지 않는다.

### 2.2 CNN과 ViT는 무엇을 보존하는가

CNN은 작은 커널을 공간에 공유해 지역 패턴을 반복 탐색한다. 입력·출력 채널 수가 각각 $$C_{in},C_{out}$$이고 커널이 $$k\times k$$이면 bias를 포함한 파라미터 수는

$$
(k^2C_{in}+1)C_{out}
$$

이다. 각 출력 채널에 $$k^2C_{in}$$개의 가중치와 bias 하나가 필요하기 때문이다. 입력 면적이 커져도 이 파라미터 수는 유지되지만 연산량과 활성값 메모리는 증가한다. Flatten 자체는 원소를 없애는 연산이 아니다. Dense 연결로 바꾸면 지역성·공유 가중치라는 구조적 제약을 직접 활용하지 않는다는 점이 핵심이다.

ViT는 patch를 token으로 바꾸고 attention으로 문맥을 섞는다. $$QK^\top$$의 한 행은 한 query가 각 key와 맺는 유사도를 나타내며, 행별 softmax 후 $$V$$를 곱하면 값 벡터들의 가중합이 된다. 따라서 분류 backbone을 검출에 재사용할 때는 최종 class token만 볼 것이 아니라 공간별 특징을 어떻게 head에 제공할지도 확인해야 한다. 자세한 attention 수식과 scaling 도출은 Lecture 3에 둔다.

## 3. 물체의 위치를 숫자로 학습하는 방법

### 3.1 좌표계와 IoU

이 절의 box는 연속 좌표 $$B=(x_1,y_1,x_2,y_2)$$, $$x_2>x_1,y_2>y_1$$로 정의한다. 원점은 영상 왼쪽 위이고 오른쪽·아래쪽이 양의 방향이다. 좌표 단위는 pixel, 면적은 pixel squared다. 정수 픽셀 양끝을 모두 포함하는 구현의 `+1` 규칙과 섞지 않는다.

두 box $$A,B$$의 교집합 폭과 높이를 각각 계산한다.

$$
w_I=\max(0,\min(x_2^A,x_2^B)-\max(x_1^A,x_1^B)),
$$

$$
h_I=\max(0,\min(y_2^A,y_2^B)-\max(y_1^A,y_1^B)).
$$

교집합은 $$I=w_Ih_I$$다. 두 면적을 더하면 겹친 부분을 두 번 세므로 합집합은 $$U=\operatorname{area}(A)+\operatorname{area}(B)-I$$다. 따라서

$$
\operatorname{IoU}(A,B)=\frac{I}{U}
$$

이며 $$U>0$$에서 무차원 값이고 0과 1 사이에 있다. 면적 100인 두 정사각형이 가로로 2 pixel 어긋나면 $$I=80,U=120$$이므로 IoU는 $$2/3$$이다. 같은 2 pixel 오차도 작은 물체에는 상대적으로 큰 영향을 준다.

### 3.2 Box offset을 쓰는 이유와 역변환

기준 box의 중심·크기를 $$(x_a,y_a,w_a,h_a)$$, 정답을 $$(x^*,y^*,w^*,h^*)$$라고 하자. 중심 이동은 기준 크기로 나누고 크기 변화는 비율의 로그로 표현한다.

$$
t_x^*=\frac{x^*-x_a}{w_a},\quad t_y^*=\frac{y^*-y_a}{h_a},\quad t_w^*=\log\frac{w^*}{w_a},\quad t_h^*=\log\frac{h^*}{h_a}.
$$

이들은 모두 무차원이다. 물체 크기가 달라도 같은 상대 이동은 같은 target이 되며, 양수 크기의 비율을 실수 범위로 옮길 수 있다. 정의를 역으로 풀면

$$
\hat{x}=x_a+w_a\hat{t}_x,\quad\hat{y}=y_a+h_a\hat{t}_y,\quad\hat{w}=w_ae^{\hat{t}_w},\quad\hat{h}=h_ae^{\hat{t}_h}.
$$

예를 들어 기준 box가 $$(50,40,20,10)$$이고 정답이 $$(54,39,30,10)$$이면 target은 $$(0.2,-0.1,\log1.5,0)$$다. 역변환하면 원래 정답을 정확히 복원한다. **이 복원은 좌표 정의의 대수적 성질이지 신경망이 target을 정확히 예측한다는 보장은 아니다.**

외부 보강: 이 계열의 상대 좌표화는 <a href="https://arxiv.org/abs/1311.2524" target="_blank" rel="noopener">R-CNN</a>과 <a href="https://arxiv.org/abs/1506.01497" target="_blank" rel="noopener">Faster R-CNN</a>을 읽을 때 공통 기준이 된다. Positive/negative 표본을 고르는 IoU와 최종 평가 IoU는 목적이 다르므로 임계값을 하나로 외우면 안 된다.

## 4. R-CNN 계열은 어떤 병목을 차례로 해결했는가

| 구조 | 바뀐 핵심 | 남은 과제와 다음 연결 |
|---|---|---|
| R-CNN | 후보 영역마다 CNN 특징 계산 | 겹치는 영역에서 연산 반복; 특징을 공유하는 Fast R-CNN으로 연결 |
| Fast R-CNN | 전체 영상 특징을 한 번 계산하고 RoI별로 추출 | 외부 proposal 생성 비용; RPN으로 학습하는 Faster R-CNN으로 연결 |
| Faster R-CNN | 공유 특징 위에서 RPN으로 후보 생성 | 단일 저해상도 특징의 작은 물체 문제; 다중 해상도 FPN으로 연결 |
| FPN 결합 검출기 | 깊은 의미 정보와 얕은 고해상도 정보를 결합 | 메모리·연산과 scale assignment를 함께 조정해야 함 |

외부 근거: <a href="https://arxiv.org/abs/1504.08083" target="_blank" rel="noopener">Fast R-CNN</a>, <a href="https://arxiv.org/abs/1506.01497" target="_blank" rel="noopener">Faster R-CNN</a>, <a href="https://arxiv.org/abs/1612.03144" target="_blank" rel="noopener">Feature Pyramid Networks</a>. 이 표는 해결한 구조적 문제를 비교한 것이며, 서로 다른 논문의 FPS 수치를 같은 장비의 실험처럼 비교하지 않는다.

### 4.1 공유 특징이 계산을 줄이는 이유

후보 수를 $$N$$, 후보 한 개의 CNN 비용을 $$C_{crop}$$, 전체 이미지 backbone 비용을 $$C_{image}$$, 후보별 head 비용을 $$C_{head}$$라 하자. Proposal 비용을 제외한 단순 모델에서 R-CNN은 대략 $$NC_{crop}$$, Fast R-CNN은 $$C_{image}+NC_{head}$$가 든다. 일반적으로 head가 backbone보다 가벼우면 공유가 유리하다. 정확한 속도비는 후보 수, 입력 크기, backbone, 메모리 이동에 의존한다.

RPN은 공유 특징의 각 위치에 기준 box들을 놓고 물체 여부와 offset을 예측한다. 여기서 **anchor는 사전 정의한 기준이고 proposal은 점수화·보정·선별된 후보**다. 첫 단계의 objectness와 두 번째 단계의 구체적인 class 분류를 구분하면 two-stage의 의미가 명확해진다.

### 4.2 FPN과 작은 물체

입력에서 폭 $$w$$인 물체는 stride $$s$$인 feature map에서 대략 $$w/s$$칸에 해당한다. 폭 16 pixel 물체가 stride 32에서는 반 칸, stride 4에서는 네 칸 정도를 차지한다. 이 근사는 위치 정렬과 padding을 생략하지만 작은 물체의 공간 표현이 왜 부족해지는지 설명한다.

FPN은 단순히 작은 feature map을 확대하지 않는다. 깊은 특징의 의미 정보와 얕은 특징의 공간 정보를 lateral connection으로 합친다. 채널을 맞춘 특징을 $$\operatorname{Lat}(C_l)$$라 하면 기본 연결을

$$
M_l=\operatorname{Lat}(C_l)+\operatorname{Up}(M_{l+1})
$$

로 나타낼 수 있다. 두 항은 공간 크기와 채널 수가 같아야 더할 수 있다. 이 구조는 잃어버린 입력 정보를 완벽히 복원하는 역변환이 아니다. 남아 있는 고해상도 특징을 재활용하는 방법이다.

## 5. Dense prediction: 배경 불균형과 anchor-free 표현

### 5.1 Focal loss는 왜 쉬운 배경의 비중을 낮추는가

외부 보강: <a href="https://arxiv.org/html/1708.02002v2" target="_blank" rel="noopener">RetinaNet의 focal loss</a>는 dense detector에서 수많은 쉬운 음성 표본이 손실을 지배하는 문제를 다룬다. 정답에 대한 확률을 $$p_t$$라 하면

$$
L_{FL}=-\alpha_t(1-p_t)^\gamma\log p_t,\qquad\gamma\geq0.
$$

$$\alpha_t$$는 class 가중치, $$\gamma$$는 쉬운 예제 억제 정도다. $$\gamma=0$$이면 가중 cross-entropy로 돌아간다. $$\gamma=2$$일 때 $$p_t=0.9$$인 예제의 modulation factor는 0.01이고 $$p_t=0.1$$인 예제는 0.81이다. 따라서 잘 맞힌 표본의 손실 비중이 작아진다. 이 81배 차이는 **가중 계수의 비율**이지 전체 손실 또는 gradient 비율이 아니다.

이는 유일하게 증명되는 최적 손실이 아니라 설계한 목적함수다. 작동 방향은 식으로 설명할 수 있지만 검출 성능 향상은 데이터와 실험으로 확인해야 한다.

### 5.2 FCOS의 네 거리와 centerness

외부 보강: <a href="https://arxiv.org/html/1904.01355v5" target="_blank" rel="noopener">FCOS, §3</a>는 anchor 대신 위치 $$(x,y)$$에서 box 네 변까지의 거리 $$(l,t,r,b)$$를 예측한다. 같은 좌표계에서 $$x_1=x-l,y_1=y-t,x_2=x+r,y_2=y+b$$로 복원한다.

중심에 가까운 위치를 높게 평가하는 학습 target은 다음과 같다.

$$
c^*=\sqrt{\frac{\min(l,r)}{\max(l,r)}\frac{\min(t,b)}{\max(t,b)}}.
$$

양의 거리에서 각 비율은 0과 1 사이이고, 중심에서는 $$l=r,t=b$$이므로 1이다. 좌우 거리가 2와 8, 상하가 각각 5이면 $$c^*=\sqrt{(2/8)(5/5)}=0.5$$다. 제곱근은 곱 자체보다 값을 크게 유지해 중심에서 멀어질 때의 감소를 완화한다. 이 역시 정의를 통한 설계이지 자연법칙의 증명은 아니다.

**FCOS 원 논문의 box regression은 IoU loss이며 단순 L2가 아니다.** 또한 centerness는 실제 IoU의 정답값이 아니라 기하학적 보조 target이다. Anchor-free여도 위치별 정답 배정, scale별 담당 범위, 중복 box 처리 문제는 남는다. Lecture 7에서 슬라이드와 원 논문의 차이를 확인한다.

## 6. 검출 평가는 점수, 중복 제거, 정답 매칭을 분리한다

### 6.1 서로 다른 세 임계값

| 기준 | 비교하는 것 | 질문 |
|---|---|---|
| Confidence threshold | 예측 score와 문턱값 | 출력 후보로 남길 것인가 |
| NMS IoU threshold | 예측 box와 다른 예측 box | 같은 물체의 중복으로 억제할 것인가 |
| Evaluation IoU threshold | 예측 box와 정답 box | 위치가 충분히 맞았는가 |

NMS는 보통 같은 class 안에서 높은 score부터 선택하고 많이 겹친 낮은 score를 억제한다. 서로 가깝게 선 실제 두 물체까지 지워질 수 있다. 이런 경우는 임계값 검토, 밀집 장면별 평가, 대체 후처리의 비교 실험으로 개선 여부를 확인해야 한다. 단순히 NMS를 끄면 중복 검출이 늘어날 수 있다.

### 6.2 Precision, recall, AP를 손으로 계산하기

기본 예제에서는 한 class, 일반 정답 3개, 고정 IoU 임계값, ignore/crowd 없음, score 내림차순의 일대일 매칭을 가정한다. 같은 정답에 대한 두 번째 검출은 TP를 추가하지 못한다. 예측의 매칭 결과가 TP, FP, TP, FP, TP라면 다음과 같다.

| 순위까지 채택 | 누적 TP | 누적 FP | Precision | Recall |
|---|---|---|---|---|
| 1 | 1 | 0 | 1 | 1/3 |
| 2 | 1 | 1 | 1/2 | 1/3 |
| 3 | 2 | 1 | 2/3 | 2/3 |
| 4 | 2 | 2 | 1/2 | 2/3 |
| 5 | 3 | 2 | 3/5 | 1 |

$$
P=\frac{TP}{TP+FP},\qquad R=\frac{TP}{TP+FN}.
$$

정답 총수는 $$TP+FN=3$$으로 고정된다. Threshold를 낮춰 후보를 추가할 때 recall은 이 설정에서 감소하지 않지만, precision은 TP가 추가되는지 FP가 추가되는지에 따라 올라가거나 내려간다. 따라서 **threshold와 precision 사이에 무조건적인 단조 관계를 주장하면 틀린다.**

보간 precision을 $$p_{interp}(r)=\max_{\tilde r\geq r}p(\tilde r)$$로 두면 이후 더 높은 recall에서 얻은 좋은 precision을 반영하는 상단 envelope가 된다. 이 예제에서 all-points 방식의 면적은

$$
AP=\frac13\left(1+\frac23+\frac35\right)=\frac{34}{45}\approx0.7556.
$$

이는 PR 점들의 precision을 단순 평균한 것이 아니라 recall이 늘어난 구간의 넓이다. **외부 보강:** <a href="https://github.com/cocodataset/cocoapi/blob/master/PythonAPI/pycocotools/cocoeval.py" target="_blank" rel="noopener">COCO 공식 평가 구현</a>은 기본적으로 101개 recall 지점과 IoU 0.50–0.95의 0.05 간격을 사용하며 maxDets·area·ignore 설정도 포함한다. 위 교육용 all-points 값과 COCO AP를 동일한 수치라고 부르면 안 된다. Box AP와 mask AP도 겹침을 계산하는 대상이 다르다.

## 7. Box에서 pixel과 instance로 확장하기

### 7.1 Semantic segmentation과 공간 해상도

FCN은 class score를 위치별로 출력한다. 전체 픽셀 수를 $$M$$, class 수를 $$C$$, one-hot 정답을 $$y_{ic}$$, softmax 출력을 $$p_{ic}$$라 하면 기본 손실은

$$
L_{seg}=-\frac1M\sum_{i=1}^{M}\sum_{c=1}^{C}y_{ic}\log p_{ic}.
$$

이미지 분류의 cross-entropy를 픽셀마다 적용한 것이다. Ignore label이 있다면 해당 픽셀을 합과 분모에서 제외해야 한다. 출력 해상도가 작으면 정답 크기와 정렬하는 방법도 명시해야 한다.

Downsampling은 넓은 문맥을 모으고 비용을 줄이지만 경계의 세부 위치를 잃을 수 있다. <a href="https://arxiv.org/abs/1411.4038" target="_blank" rel="noopener">FCN 원 논문</a>의 coarse semantic information과 fine appearance information을 결합하는 관점은 FPN의 동기와 연결된다. 다만 segmentation의 pixel 출력과 detection의 scale별 box 출력을 같은 head로 혼동하지 않는다.

### 7.2 Transposed convolution은 역함수인가

아니다. Convolution을 벡터에 작용하는 선형행렬 $$A$$로 쓰면 $$y=Ax$$다. Transposed convolution의 대응 연산은 $$A^\top u$$이며 일반적으로 $$A^{-1}u$$가 아니다. Bias와 비선형성은 이 선형 예제에서 제외한다.

커널 $$(1,2)$$로 길이 3 벡터를 valid cross-correlation하면

$$
A=\begin{bmatrix}1&2&0\\0&1&2\end{bmatrix},\qquad x=\begin{bmatrix}1\\2\\3\end{bmatrix},\qquad Ax=\begin{bmatrix}5\\8\end{bmatrix}.
$$

이를 전치행렬에 넣으면 $$A^\top Ax=(5,18,16)^\top$$으로 원래 $$x$$와 다르다. 길이 3을 2로 줄인 이 변환은 일반적으로 정보를 잃어 고유한 역함수가 없다. 학습 가능한 upsampling은 적절한 출력 패턴을 학습하는 것이지 손실 정보를 수학적으로 완벽히 되돌리는 것이 아니다.

### 7.3 RoIAlign과 instance mask

외부 보강: <a href="https://arxiv.org/html/1703.06870v3" target="_blank" rel="noopener">Mask R-CNN, §3</a>은 Faster R-CNN에 RoI별 mask branch를 더하고, RoI pooling의 좌표 양자화로 생기는 어긋남을 RoIAlign으로 줄인다. 한 픽셀의 이동도 mask 경계에는 중요하다.

RoIAlign의 핵심인 bilinear interpolation은 가로 선형 보간 후 세로 선형 보간으로 도출된다. 주변 값이 $$f_{00},f_{10},f_{01},f_{11}$$이고 셀 내부 상대 좌표가 $$a,b\in[0,1]$$이면

$$
f(a,b)=(1-a)(1-b)f_{00}+a(1-b)f_{10}+(1-a)bf_{01}+abf_{11}.
$$

네 가중치는 음수가 아니고 합이 1이다. 중앙에서는 각 가중치가 1/4이다. 원 영상의 숨은 값을 완벽히 복원하는 공식이 아니라 격자 특징을 연속 좌표에서 샘플링하는 근사다.

원형 Mask R-CNN의 class-specific mask는 정답 class 채널에 binary cross-entropy를 적용한다. Semantic segmentation처럼 픽셀마다 모든 class가 softmax로 경쟁하는 손실과 다르다. RoI의 class 선택과 해당 instance 내부의 foreground mask 예측을 분리했기 때문이다.

## 8. 자율주행 관점의 외부 보강과 검증 설계

아래는 강의 구조로부터 도출한 **학습·실험 설계 제안**이며 특정 모델의 안전 인증이나 성능을 주장하지 않는다.

1. **작은 물체:** 전체 AP뿐 아니라 크기별 결과를 본다. 같은 pixel 오차의 상대 영향이 다르므로 해상도·FPN 설정을 비교한다.
2. **가림과 밀집:** 분류 오류, box 오류, NMS로 사라진 검출을 분리한다. 원인에 따라 데이터 보강, head 개선, 후처리 비교의 대상이 달라진다.
3. **배경 불균형:** loss 전체값만 보지 말고 positive와 negative의 기여를 나눈다. Focal loss 도입 전후 동일 조건에서 recall과 오탐 변화를 확인한다.
4. **시간 비용:** inference FPS와 sensor capture부터 최종 출력까지의 latency를 별도로 측정한다. Batch throughput만으로 차량 제어 지연을 대신할 수 없다.
5. **장면 변화:** 낮·밤, 날씨, 거리별로 오류를 나누고 train/test 누수를 막는다. 평균 지표가 개선돼도 중요한 조건의 실패가 가려질 수 있다.

간단한 단위 점검으로 속도 $$v$$에서 처리 지연 $$\Delta t$$ 동안 이동한 거리는 $$d=v\Delta t$$다. 일정 속도 15 m/s에서 0.1 s의 지연이면 1.5 m를 이동한다. 이는 이동거리 계산일 뿐 정지거리나 안전거리 공식이 아니다. 제동·반응·상대 운동 등의 추가 조건 없이 안전 판단으로 확대하지 않는다.

## Source Check

| 점검 대상 | 통합본의 처리 |
|---|---|
| Perception 1의 flatten 설명 | 배열 변환 자체와 공간 inductive bias의 차이를 구분 |
| Perception 2의 R-CNN 학습 설명 | 분류기 학습·fine-tuning·회귀의 표본 기준을 동일하게 일반화하지 않음 |
| Perception 3, p. 11의 threshold 문장 | 직접 TP/FP 예제로 recall과 precision의 관계를 확인; 상세 정정은 Lecture 5 |
| Perception 5, pp. 16–17의 FCOS L2 표기 | FCOS 원 논문 Eq. 2의 IoU regression loss와 구분 |
| Perception 5, p. 13의 YOLO 45 FPS | 원형 모델의 측정값을 전체 YOLO 계열의 보장 성능으로 확대하지 않음 |
| Perception 6의 upsampling과 things/stuff | 전치행렬은 역행렬이 아님; 범주 구분은 데이터셋 taxonomy에 의존 |
| AP 계산 방식 | 교육용 all-points 예제와 COCO의 sampling·matching 설정을 구분 |

## 마지막 핵심 정리

**분류는 의미, 검출은 의미와 위치, 분할은 픽셀 경계, instance segmentation은 개체 구분까지 요구한다.** Backbone의 공유는 연산 문제, FPN은 scale 표현 문제, focal loss는 표본 불균형 문제, RoIAlign은 공간 정렬 문제를 다룬다. 서로 다른 문제를 해결하는 구성요소를 단순한 모델 순위로 외우지 않는다.

수식 복습에서는 정의와 성능 주장을 구분한다. IoU·box offset·bilinear interpolation은 정의에서 계산을 유도할 수 있다. Focal loss·centerness는 목적에 맞게 설계한 함수다. AP 상승과 FPS는 데이터·구현·하드웨어 조건을 갖춘 실험 근거가 필요하다.

## Study Guide

- 먼저 §1과 §4를 읽고 여섯 강의의 큰 흐름을 연결한다.
- 수식은 §2의 cross-entropy 미분, §3의 box 역변환, §6의 AP 계산, §7의 전치행렬 예제를 직접 계산한다.
- 구현 전에는 좌표의 단위, positive assignment, loss 적용 대상, NMS 조건, 평가 설정을 한 장에 적는다.
- 상세 슬라이드 설명은 위 Lecture 3–8 링크로 이동한다. 복습할 때 원문 PDF를 함께 열어 도식과 식의 기호를 대조한다.

## 복습 질문

<details markdown="block">
<summary>1. Faster R-CNN과 FPN은 같은 문제를 해결하는가?</summary>

아니다. RPN은 proposal을 학습하고 특징을 공유해 후보 생성 병목을 줄인다. FPN은 해상도별 특징에 의미 정보를 결합해 다양한 크기의 물체를 표현한다. 서로 함께 사용할 수 있다.

</details>

<details markdown="block">
<summary>2. Anchor-free이면 IoU도 NMS도 필요 없는가?</summary>

아니다. Anchor-free는 사전 box 기준을 쓰지 않는다는 뜻이다. FCOS는 IoU 기반 회귀 손실을 사용하고 중복 검출에 NMS를 적용한다. Anchor 배정과 평가·손실·후처리를 구분해야 한다.

</details>

<details markdown="block">
<summary>3. Confidence threshold를 높이면 precision은 항상 높아지는가?</summary>

아니다. 제거한 예측이 TP인지 FP인지에 따라 달라진다. 낮은 score의 TP를 제거하면 precision이 낮아질 수도 있다. 고정된 score 순위의 앞부분만 남기는 기본 설정에서 recall은 높아지지 않는다.

</details>

<details markdown="block">
<summary>4. 왜 transposed convolution을 역 convolution이라고 외우면 안 되는가?</summary>

전치행렬과 역행렬은 다르다. Downsampling으로 정보가 사라지면 고유한 역해가 없을 수 있다. §7의 예제처럼 전치 연산을 적용해도 입력이 복원되지 않는다.

</details>

<details markdown="block">
<summary>5. Semantic segmentation과 Mask R-CNN의 mask 손실은 왜 다른가?</summary>

기본 semantic segmentation은 각 픽셀의 class를 다중 범주로 예측한다. 원형 Mask R-CNN은 RoI classification으로 범주를 정하고, 해당 class 채널에서 그 instance의 foreground 여부를 binary mask로 학습한다.

</details>

## References

<ul>
  <li><a href="https://arxiv.org/abs/1311.2524" target="_blank" rel="noopener">Girshick et al. — Rich Feature Hierarchies for Accurate Object Detection and Semantic Segmentation</a>: region-based detection과 상대 box 좌표.</li>
  <li><a href="https://arxiv.org/abs/1504.08083" target="_blank" rel="noopener">Girshick — Fast R-CNN</a>: 공유 특징과 RoI 처리.</li>
  <li><a href="https://arxiv.org/abs/1506.01497" target="_blank" rel="noopener">Ren et al. — Faster R-CNN</a>: RPN과 공유 특징.</li>
  <li><a href="https://arxiv.org/abs/1612.03144" target="_blank" rel="noopener">Lin et al. — Feature Pyramid Networks for Object Detection</a>: top-down·lateral 구조.</li>
  <li><a href="https://arxiv.org/html/1708.02002v2" target="_blank" rel="noopener">Lin et al. — Focal Loss for Dense Object Detection</a>: dense detection의 불균형과 focal loss.</li>
  <li><a href="https://arxiv.org/html/1904.01355v5" target="_blank" rel="noopener">Tian et al. — FCOS</a>: LTRB, IoU loss, centerness.</li>
  <li><a href="https://arxiv.org/abs/1411.4038" target="_blank" rel="noopener">Long et al. — Fully Convolutional Networks for Semantic Segmentation</a>: dense prediction과 coarse/fine 정보 결합.</li>
  <li><a href="https://arxiv.org/html/1703.06870v3" target="_blank" rel="noopener">He et al. — Mask R-CNN</a>: RoIAlign과 class-specific binary masks.</li>
  <li><a href="https://github.com/cocodataset/cocoapi/blob/master/PythonAPI/pycocotools/cocoeval.py" target="_blank" rel="noopener">COCO API — Official Evaluation Implementation</a>: AP sampling과 matching 설정.</li>
</ul>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf" | relative_url }}" target="_blank" rel="noopener">3 Perception (1).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-04-perception-02.pdf" | relative_url }}" target="_blank" rel="noopener">4 Perception (2).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-05-perception-03.pdf" | relative_url }}" target="_blank" rel="noopener">5 Perception (3).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-06-perception-04.pdf" | relative_url }}" target="_blank" rel="noopener">6 Perception (4).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-07-perception-05.pdf" | relative_url }}" target="_blank" rel="noopener">7 Perception (5).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-08-perception-06.pdf" | relative_url }}" target="_blank" rel="noopener">8 Perception (6).pdf</a></li>
</ul>
