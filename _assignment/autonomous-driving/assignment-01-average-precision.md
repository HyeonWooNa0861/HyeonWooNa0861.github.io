---
layout: default
date: 2026-10-13 16:59:26 +0900
title: "Autonomous Driving Computing Assignment 1: Average Precision"
course: "Autonomous Driving"
topic: "Object Detection Metrics"
order: 1
major_topic: "Autonomous Systems"
keywords:
  - "Intersection over Union"
  - "Precision"
  - "Recall"
  - "Average Precision"
  - "Object Detection"
---

# Autonomous Driving Computing Assignment 1: Average Precision

Source Materials: Average Precision assignment handout and local worked solution

## 과제 개요

이 과제는 object detector의 box 좌표와 confidence만 주어졌을 때 평가 지표가 만들어지는 전 과정을 추적한다. 순서는 **box 겹침 계산 → confidence 정렬 → 중복 없는 TP/FP 매칭 → 누적 precision·recall → 단조 감소 precision envelope → AP 적분**이다.

**핵심 메시지:** AP는 box가 얼마나 잘 겹치는지만 보는 값이 아니다. 높은 confidence의 prediction이 먼저 평가되므로, 같은 box 집합이라도 **confidence 순서가 바뀌면 precision-recall curve와 AP가 달라진다.**

원본은 Car와 Pedestrian 각각에 대해 GT 4개와 prediction 5개를 제공한다. NMS는 이미 적용되었고, TP 판정 기준은 IoU가 0.5보다 큰 경우다. 하나의 GT에는 confidence가 가장 높은 prediction 하나만 TP로 연결한다.

## 1. 평가 파이프라인

### 1.1 Box와 IoU

Box는 pixel 좌표 $$(x_1,y_1,x_2,y_2)$$로 표현한다. 너비와 높이는 각각 $$x_2-x_1$$, $$y_2-y_1$$이며 면적 단위는 pixel²이다.

두 box $$A$$와 $$B$$의 교집합 너비와 높이는 음수가 되지 않도록 자른다.

$$
w_I=\max\!\left(0,\min(x_{2,A},x_{2,B})-\max(x_{1,A},x_{1,B})\right)
$$

$$
h_I=\max\!\left(0,\min(y_{2,A},y_{2,B})-\max(y_{1,A},y_{1,B})\right)
$$

교집합 면적 $$I=w_Ih_I$$, 합집합 면적 $$U=\operatorname{area}(A)+\operatorname{area}(B)-I$$이므로

$$
\operatorname{IoU}(A,B)=\frac{I}{U}
$$

이다. IoU는 동일한 면적 단위가 약분된 무차원 값이며 0과 1 사이에 있다.

### 1.2 Confidence 순서로 한 번씩 매칭한다

Prediction을 confidence 내림차순으로 정렬한 뒤 하나씩 처리한다.

1. 모든 GT 중 IoU가 가장 큰 것을 찾는다.
2. 그 IoU가 0.5보다 크고 해당 GT가 아직 매칭되지 않았으면 TP다.
3. IoU 기준을 넘지 못하거나, 가장 잘 겹치는 GT가 이미 매칭되었으면 FP다. 한 GT를 두 번 TP로 세지 않는다.
4. 상위 $$k$$개까지의 누적 TP와 FP로 precision·recall을 계산한다.

$$
P_k=\frac{TP_k}{TP_k+FP_k},
\qquad
R_k=\frac{TP_k}{N_{GT}}
$$

Precision은 예측 중 맞은 비율이고 recall은 존재하는 GT 중 찾은 비율이다. 둘 다 무차원이다.

### 1.3 AP는 PR curve의 면적이다

원본의 방식은 관측된 precision을 오른쪽에서 왼쪽으로 최대화해 단조 감소 envelope를 만든 뒤 recall 구간별 면적을 더한다.

$$
\widetilde P(r)=\max_{r'\ge r}P(r'),
\qquad
AP=\sum_i (R_i-R_{i-1})\widetilde P(R_i)
$$

이는 이 과제에서 사용하는 all-point interpolation이다. COCO처럼 여러 IoU threshold를 평균하는 AP와 동일한 수치 정의는 아니다.

## 2. Car Detection

### 재구성한 입력

| GT | Box |
| --- | --- |
| G1 | (20, 50, 120, 110) |
| G2 | (150, 40, 230, 90) |
| G3 | (270, 45, 350, 95) |
| G4 | (410, 55, 450, 85) |

| Prediction | Box | Confidence | Best GT | IoU |
| --- | --- | ---: | --- | ---: |
| D1 | (270, 45, 350, 85) | 0.72 | G3 | 0.80 |
| D2 | (400, 55, 440, 85) | 0.61 | G4 | 0.60 |
| D3 | (30, 50, 120, 110) | 0.98 | G1 | 0.90 |
| D4 | (310, 45, 390, 95) | 0.85 | G3 | 0.333… |
| D5 | (150, 50, 230, 100) | 0.93 | G2 | 0.666… |

Confidence 순서는 D3 → D5 → D4 → D1 → D2다. D4는 G3와 일부 겹치지만 IoU가 기준보다 낮아 FP다. 뒤에 처리되는 D1은 G3와 IoU 0.80이므로 TP가 된다.

| Rank $$k$$ | Prediction | Result | Cumulative TP | Cumulative FP | Precision | Recall |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | D3 | TP | 1 | 0 | 1.000 | 0.25 |
| 2 | D5 | TP | 2 | 0 | 1.000 | 0.50 |
| 3 | D4 | FP | 2 | 1 | 0.667 | 0.50 |
| 4 | D1 | TP | 3 | 1 | 0.750 | 0.75 |
| 5 | D2 | TP | 4 | 1 | 0.800 | 1.00 |

오른쪽 최대값을 적용하면 recall 0–0.5 구간의 precision은 1, 0.5–1 구간은 0.8이 된다.

$$
AP_{car}=0.5\times1+0.5\times0.8=0.9
$$

<details markdown="block">
<summary markdown="span">Derivation: Car IoU and AP calculations</summary>

풀이과정:

- D1–G3: 교집합은 $$80\times40=3200$$, 합집합은 $$3200+4000-3200=4000$$이므로 IoU는 $$4/5$$다.
- D2–G4: 교집합은 $$30\times30=900$$, 합집합은 $$1200+1200-900=1500$$이므로 IoU는 $$3/5$$다.
- D3–G1: 교집합은 $$90\times60=5400$$, 합집합은 $$5400+6000-5400=6000$$이므로 IoU는 $$9/10$$이다.
- D4–G3: 교집합은 $$40\times50=2000$$, 합집합은 $$4000+4000-2000=6000$$이므로 IoU는 $$1/3$$이다.
- D5–G2: 교집합은 $$80\times40=3200$$, 합집합은 $$4000+4000-3200=4800$$이므로 IoU는 $$2/3$$이다.

Raw precision은 $$1,1,2/3,3/4,4/5$$다. 오른쪽에서 왼쪽으로 최대값을 취하면 recall이 실제로 증가하는 지점의 precision은 $$1,1,4/5,4/5$$가 된다. 따라서 네 개의 recall 증가폭 $$1/4$$에 대응하는 면적 합은 $$9/10$$이다.

</details>

### Confidence threshold 비교

| Threshold | Included predictions | TP | FP | Precision | Recall |
| ---: | --- | ---: | ---: | ---: | ---: |
| 0.8 | D3, D5, D4 | 2 | 1 | 0.667 | 0.50 |
| 0.5 | D3, D5, D4, D1, D2 | 4 | 1 | 0.800 | 1.00 |

이 예제에서는 0.5가 precision과 recall을 모두 높인다. 하지만 이 한 장면만으로 일반적인 detector threshold를 정할 수는 없다. 실제 차량에서는 검증 데이터 전체의 PR curve, false alarm 비용, missed detection 비용, 처리 지연을 함께 본다.

## 3. Pedestrian Detection

### 재구성한 입력과 매칭

| Prediction | Confidence | Best relation | IoU | Result |
| --- | ---: | --- | ---: | --- |
| D2 | 0.92 | 모든 GT와 불일치 | 0 | FP |
| D5 | 0.88 | G1 | 0.75 | TP |
| D3 | 0.67 | G2 | 0.40 | FP |
| D1 | 0.55 | G3 | 0.60 | TP |
| D4 | 0.15 | 모든 GT와 불일치 | 0 | FP |

| Rank $$k$$ | Prediction | Result | Cumulative TP | Cumulative FP | Precision | Recall |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | D2 | FP | 0 | 1 | 0 | 0 |
| 2 | D5 | TP | 1 | 1 | 0.500 | 0.25 |
| 3 | D3 | FP | 1 | 2 | 0.333 | 0.25 |
| 4 | D1 | TP | 2 | 2 | 0.500 | 0.50 |
| 5 | D4 | FP | 2 | 3 | 0.400 | 0.50 |

Recall은 최대 0.5까지만 도달한다. Precision envelope의 유효 높이는 recall 0–0.5에서 0.5이고 이후는 0이므로

$$
AP_{ped}=0.5\times0.5=0.25
$$

낮은 AP의 원인은 세 종류로 분리된다.

- **배경 오탐:** D2와 D4는 어떤 GT와도 겹치지 않는다.
- **위치 오차:** D3은 G2와 겹치지만 IoU 0.4라서 기준을 넘지 못한다.
- **미탐:** G4는 끝까지 TP와 매칭되지 않는다.

### D2 confidence를 0.10으로 낮추면

Box와 TP/FP 개수는 그대로지만 순서는 D5 → D3 → D1 → D4 → D2로 바뀐다. 첫 prediction이 TP가 되고, 두 번째 TP도 더 앞에 나타난다.

$$
AP'_{ped}=\frac14\times1+\frac14\times\frac23=\frac{5}{12}\approx0.4167
$$

이 변화는 AP가 classification accuracy처럼 순서를 무시하는 지표가 아님을 보여준다. Confidence가 실제 localization 품질과 잘 정렬될수록 PR curve의 왼쪽 위 영역이 커진다.

<details markdown="block">
<summary markdown="span">Derivation: Pedestrian AP before and after confidence correction</summary>

풀이과정:

원래 순서에서 TP는 두 번째와 네 번째에 나온다. 각각의 precision은 $$1/2$$와 $$2/4=1/2$$이므로 recall 증가폭 $$1/4$$씩에 대해

$$
AP=\frac14\cdot\frac12+\frac14\cdot\frac12=\frac14
$$

이다.

D2를 마지막으로 보내면 첫 번째 TP의 precision은 1이다. 두 번째 TP가 나오는 세 번째 rank의 precision은 $$2/3$$이다.

$$
AP'=\frac14\cdot1+\frac14\cdot\frac23=\frac{5}{12}
$$

Recall은 여전히 0.5이므로 box localization이나 미탐이 해결된 것은 아니다. 순위 품질만 좋아졌다.

</details>

## 실수하기 쉬운 지점

- Confidence 순서가 아니라 원래 D1–D5 순서로 평가하지 않는다.
- IoU는 교집합을 두 box 면적의 합에서 한 번 빼야 한다.
- 이미 TP에 사용한 GT를 뒤 prediction에 다시 연결하지 않는다.
- FP가 추가되면 recall은 그대로이고 precision만 변할 수 있다.
- AP 0.9를 “90%의 box가 맞았다”라고 해석하지 않는다. PR curve 아래 면적이다.
- 이 과제의 AP와 COCO의 `AP@[.50:.95]`를 같은 수치로 취급하지 않는다.

## 핵심 정리

1. IoU는 localization 품질을 판정한다.
2. Confidence는 prediction의 평가 순서를 정한다.
3. One-to-one matching은 한 GT를 여러 번 맞힌 것으로 세는 일을 막는다.
4. Precision과 recall은 각 rank에서 누적 계산한다.
5. AP는 precision envelope 아래 면적이므로 높은 confidence의 오류에 더 민감하다.

## 결론 및 학습 성과

평가 지표는 마지막 숫자 하나가 아니라 detector의 오류를 분해하는 절차다. IoU를 바꾸면 localization 허용 범위가 달라지고, confidence를 바꾸면 순위가 달라지며, threshold를 바꾸면 precision-recall operating point가 달라진다. 실제 시스템에서는 이 세 요소를 분리해 읽어야 모델 개선 지점을 찾을 수 있다.
