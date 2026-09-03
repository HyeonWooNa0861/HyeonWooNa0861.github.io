---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-09-03 15:50:43 +0900
title: "Autonomous Driving 2"
course: "AIX"
topic: "Tesla Occupancy and Driving Foundation Models"
order: 8
major_topic: "Artificial Intelligence"
keywords:
  - "Occupancy Networks"
  - "Voxel Representation"
  - "End-to-End Driving"
  - "Fleet Learning"
  - "Foundation Models"
---

# Autonomous Driving 2

Source PDF: `Autonomous_Driving_2.pdf`

> **핵심:** **2022 Tesla occupancy pivot의 의미는** object list보다 dense 3D geometry를 중심 representation으로 둔 것. **Occupancy가 safety에 유리한 이유는** unknown obstacle도 차 있는 공간으로 표현할 수 있기 때문.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | CVPR 2022 Tesla | object list에서 occupancy 중심 표현으로 왜 이동했는가? |
| 2 | Voxel과 occupancy | 3D 공간을 cell 단위로 예측하면 무엇이 좋아지는가? |
| 3 | 2022 architecture | multi-camera video를 어떻게 3D representation으로 바꾸는가? |
| 4 | Attention의 역할 | fixed query와 positional encoding은 왜 필요한가? |
| 5 | Geometry vs ontology | 이름 붙은 object보다 geometry가 중요한 경우는 언제인가? |
| 6 | Representation-level end-to-end | camera-to-steering과는 어떻게 다른 end-to-end인가? |
| 7 | CVPR 2023 foundation model | shared world representation은 왜 중요해졌는가? |
| 8 | Data engine과 fleet learning | foundation model 성능은 어떤 폐루프에 의존하는가? |

### 수식 원문 대응

이 자료의 직접적인 핵심 수식은 p.7의 $$Q,K,V$$ 기반 scaled dot-product attention이다. 본문의 mask·행렬 차원·가중합 표기는 그 식을 occupancy query 문맥으로 풀어 쓴 **정의**이고, $$\sqrt{d_k}$$ 설명은 독립·평균 0·단위분산을 둔 **근사적 분산 분석**이다. p.8은 fixed query와 positional encoding을 도식으로 제시하며 별도의 증명식을 주지 않는다. 나머지 p.2-6, p.9-41은 occupancy, geometry, temporal alignment, foundation model 및 fleet-learning 구조를 설명하는 개념·경험 자료이므로 인위적인 수식 증명을 추가하지 않았다.

## 1. 2022 Occupancy Pivot

Tesla의 2022 CVPR 발표는 object list 중심 perception에서 occupancy 중심 world representation으로 이동한 사건으로 볼 수 있다.

기존 detector는 "무슨 object가 어디에 있는가"를 묻는다. Occupancy는 더 직접적으로 "공간의 어떤 부분이 차 있고 비어 있는가"를 묻는다.

| 표현 | 질문 |
|---|---|
| Object list | 이 장면에 어떤 class의 물체가 있는가? |
| Lane/free-space mask | 어디가 주행 가능한가? |
| Occupancy | 3D 공간의 각 cell은 비어 있는가, 차 있는가, 어떤 의미인가? |

Unknown obstacle이나 불규칙한 geometry는 object ontology로만 다루기 어렵다.

## 2. Voxel Intuition

Occupancy는 3D 공간을 voxel 또는 grid로 나누고 각 cell의 상태를 예측한다.

```text
3D space -> voxel grid -> occupied / free / semantic
```

| 장점 | 설명 |
|---|---|
| Geometry-first | class 이름보다 공간 구조를 먼저 표현한다. |
| Unknown object 대응 | 학습된 class가 아니어도 차 있는 공간으로 표현 가능 |
| Planning 친화성 | planner가 collision과 free space를 직접 사용할 수 있음 |

이 직관은 safety와 연결된다. class를 틀리더라도 공간이 막혀 있다는 사실을 알면 충돌 회피에 사용할 수 있다.

## 3. 2022 Architecture Overview

2022 구조는 multi-camera video를 입력으로 받아 3D occupancy feature로 변환한다. 강의 내용상 backbone은 pure Vision Transformer라기보다 RegNet과 BiFPN 같은 CNN 계열 feature extractor를 포함하고, 이후 attention block이 image feature를 occupancy representation으로 끌어올린다.

```text
multi-camera images
-> image backbone
-> feature fusion / attention
-> occupancy features
-> occupancy volume
```

핵심은 최종 출력이 단순 object list가 아니라 dense spatial volume이라는 점이다.

## 4. Transformer-Style Attention

2022 구조에는 Q, K, V와 softmax attention이 명시적으로 등장한다. 즉 pure ViT는 아니지만 transformer-style attention이 2D image feature를 3D occupancy query와 연결하는 역할을 한다.

| 요소 | 역할 |
|---|---|
| Fixed query | 3D 공간에서 알고 싶은 위치 또는 cell을 대표 |
| Positional encoding | 공간 위치 정보를 attention 계산에 제공 |
| Key/value | camera image feature에서 가져올 정보 |
| Attention | 어떤 view와 feature가 해당 3D 위치에 중요한지 선택 |

슬라이드에 제시된 attention 계산을 occupancy 문맥에 맞춰 쓰면 다음과 같다.

$$
O=\operatorname{softmax}\left(\frac{QK^T}{\sqrt{d_k}}+M\right)V
$$

$$Q\in\mathbb{R}^{n_q\times d_k}$$는 $$n_q$$개 공간 query, $$K\in\mathbb{R}^{n_f\times d_k}$$와 $$V\in\mathbb{R}^{n_f\times d_v}$$는 $$n_f$$개 image feature, $$M$$은 볼 수 없는 위치에 $$-\infty$$를 주는 선택적 mask다. 모두 learned representation이므로 물리 단위는 없다. 행별 softmax weight $$\alpha_{ij}$$는 합이 1이고, 각 output query는 $$o_i=\sum_j\alpha_{ij}v_j$$라는 value의 가중합이 된다. 이는 attention의 **정의**이며, weight가 높은 feature가 인과적으로 중요하다는 증명은 아니다.

Scaling은 query와 key 성분이 독립·평균 0·분산 1이라고 근사할 때 dot product 분산이 $$d_k$$가 되는 데서 나온다. $$\sqrt{d_k}$$로 나누면 분산이 약 1이 되어 softmax 포화를 줄인다. 실제 feature는 상관될 수 있으므로 이는 **근사적 분산 분석**이다. Camera calibration, positional encoding 또는 query 위치가 틀리면 attention 연산 자체가 정상이어도 잘못된 3D cell에 정보를 모을 수 있다.

이 구조는 classical perception과 transformer-era representation learning 사이의 bridge로 볼 수 있다.

## 5. Geometry Beats Ontology

자율주행 safety에서는 물체 이름을 맞히는 것보다 그 공간이 안전한지 아는 것이 더 중요할 때가 있다.

예를 들어 detector가 false pedestrian을 만들거나 true pedestrian을 놓치는 경우, 문제는 classification accuracy만이 아니라 downstream driving consequence다.

| 문제 | Object-centric 표현의 한계 |
|---|---|
| Unknown obstacle | 학습된 class에 없으면 표현이 약하다. |
| Irregular geometry | box로 깔끔하게 감싸기 어렵다. |
| Occlusion | 보이지 않는 공간의 불확실성을 표현해야 한다. |
| Planning | planner가 geometry와 free space를 직접 필요로 한다. |

Occupancy는 ontology가 틀리거나 빠져도 geometry를 통해 안전 판단을 보완할 수 있다.

## 6. Representation-Level End-to-End

2022 Tesla story는 강한 의미의 "camera directly to steering"은 아니다. 더 정확히는 representation-level end-to-end다.

```text
camera/video -> learned unified world representation -> downstream driving modules
```

즉 사람이 만든 object list interface를 줄이고, 더 통합된 latent world state를 학습한다. 하지만 모든 planning과 control이 하나의 network로 완전히 합쳐졌다고 보기는 어렵다.

## 7. 2023 Foundation Model 방향

2023 발표는 occupancy를 넘어 shared world representation을 여러 task가 재사용하는 foundation model 관점으로 확장된다.

| 2022 | 2023 |
|---|---|
| Occupancy 중심 dense geometry | 여러 task가 공유하는 world representation |
| 공간을 더 잘 표현 | 표현을 detection, mapping, forecasting, planning에 재사용 |
| Representation pivot | Foundation-model style reuse |

Foundation model for driving의 핵심은 하나의 큰 representation이 여러 downstream task의 공통 기반이 되는 것이다.

## 8. Temporal Alignment와 Video

운전은 단일 이미지 문제가 아니라 시간적 문제다. 2023 흐름에서는 multi-camera뿐 아니라 시간축 정렬이 중요해진다.

| 시간 정보가 필요한 이유 | 설명 |
|---|---|
| Occlusion recovery | 잠깐 가려진 물체를 이전 frame으로 보완 |
| Motion reasoning | agent의 속도와 의도를 추정 |
| Future consistency | 미래 상태 예측과 planning 안정화 |
| 4D world model | 3D 공간에 시간축을 더한 표현 |

따라서 video는 driving foundation model의 자연스러운 training unit이 된다.

## 9. Data Engine과 Fleet Learning

Foundation model은 모델 구조만으로 완성되지 않는다. 실제 fleet에서 수집한 data를 바탕으로 실패 사례를 찾고, auto-labeling과 retraining을 반복해야 한다.

```text
fleet data -> mining -> auto-labeling -> training -> deployment -> fleet data
```

| 요소 | 의미 |
|---|---|
| Fleet scale | rare case를 충분히 모을 수 있는 기반 |
| Auto-labeling | 사람이 모두 labeling할 수 없는 규모의 supervision 생성 |
| Failure mining | 모델이 약한 상황을 찾아 데이터셋에 반영 |
| Deployment loop | 개선된 모델을 다시 실제 주행에 연결 |

이 폐루프가 빠르게 돌수록 representation은 실제 도로 분포에 더 잘 맞춰진다.

## 10. 역사적 종합

자율주행 표현은 다음 흐름으로 볼 수 있다.

```text
Modular stack -> Occupancy representation -> Foundation model for driving
```

Modular stack은 문제를 module output으로 나눴고, occupancy는 더 조밀한 world state를 학습했으며, foundation model은 그 world state를 여러 task가 공유하도록 확장했다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 2022 Tesla occupancy pivot의 의미는? | object list보다 dense 3D geometry를 중심 representation으로 둔 것 |
| Occupancy가 safety에 유리한 이유는? | unknown obstacle도 차 있는 공간으로 표현할 수 있기 때문 |
| 2022 구조가 pure ViT가 아닌 이유는? | CNN backbone과 attention-based lifting이 결합된 구조이기 때문 |
| Representation-level end-to-end란? | 사람이 만든 중간 output 대신 통합 latent world state를 학습하는 것 |
| 2023 foundation model 방향의 핵심은? | 하나의 shared representation을 여러 driving task가 재사용하는 것 |

## Study Guide

multi-camera feature가 attention-based lifting을 거쳐 3D voxel occupancy가 되는 2022 구조를 순서대로 그려 본다. CNN backbone을 포함한다는 점 때문에 pure ViT와 다르고, representation-level end-to-end가 곧 camera-to-steering을 뜻하지 않는다는 점이 주요 혼동 지점이다. 마지막에는 temporal alignment가 4D world model을 만드는 과정과 shared representation·fleet learning의 연결을 함께 설명한다.

## 복습 질문

<details markdown="block">
<summary>1. Object detector가 높은 정확도를 가져도 occupancy가 필요한 이유는 무엇인가?</summary>

답변: object detector는 정해진 객체 class와 bounding box 중심으로 환경을 본다. 그러나 주행에는 도로 위 점유 공간, 비정형 장애물, 가려진 영역, free space도 중요하다. occupancy는 객체가 무엇인지보다 어디가 차 있는지를 표현하므로 planning에 더 직접적인 정보를 제공한다.

</details>

<details markdown="block">
<summary>2. Fixed query와 positional encoding이 3D occupancy attention에서 하는 역할을 설명하라.</summary>

답변: fixed query는 3D 공간의 각 위치나 voxel을 질의하는 기준점 역할을 한다. positional encoding은 그 query가 공간상 어디에 있는지 모델에 알려준다. attention은 이미지 feature와 이 공간 query를 연결해 2D 관측을 3D occupancy 표현으로 끌어올린다.

</details>

<details markdown="block">
<summary>3. Fleet learning loop가 foundation model for driving의 일부로 봐야 하는 이유는 무엇인가?</summary>

답변: 실제 차량 fleet에서 수집되는 데이터는 드문 상황과 실패 사례를 계속 보강한다. 이 데이터가 labeling, training, validation을 거쳐 모델에 다시 반영되면 주행 모델은 점점 더 넓은 상황을 학습한다. 그래서 fleet learning loop는 단순 배포 과정이 아니라 driving foundation model을 키우는 핵심 학습 체계다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf" | relative_url }}" target="_blank" rel="noopener">Autonomous_Driving_2.pdf</a></li>
</ul>
