---
layout: default
date: 2026-05-20 13:52:05 +0900
last_modified_at: 2026-11-23 16:50:00 +0900
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

> **핵심:** 2022년 Tesla의 occupancy 접근은 객체 목록보다 조밀한 3D 공간 표현을 중심에 둡니다. 이름을 모르는 장애물도 점유 공간으로 나타낼 수 있다는 점이 안전 판단에 유용합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">글의 구성과 원문 대응 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | CVPR 2022 Tesla | object list에서 occupancy 중심 표현으로 왜 이동했습니까? |
| 2 | Voxel과 occupancy | 3D 공간을 cell 단위로 예측하면 무엇이 좋아집니까? |
| 3 | 2022 architecture | multi-camera video를 어떻게 3D representation으로 바꿉니까? |
| 4 | Attention의 역할 | fixed query와 positional encoding은 왜 필요합니까? |
| 5 | Geometry vs ontology | 이름 붙은 object보다 geometry가 중요한 경우는 언제입니까? |
| 6 | Representation-level end-to-end | camera-to-steering과는 어떻게 다른 end-to-end입니까? |
| 7 | CVPR 2023 foundation model | shared world representation은 왜 중요해졌습니까? |
| 8 | Data engine과 fleet learning | foundation model 성능은 어떤 폐루프에 의존합니까? |

### 수식 원문 대응

이 자료의 직접적인 핵심 수식은 p.7의 $$Q,K,V$$ 기반 scaled dot-product attention입니다. 본문의 mask·행렬 차원·가중합 표기는 그 식을 occupancy query 문맥으로 풀어 쓴 **정의**이고, $$\sqrt{d_k}$$ 설명은 독립·평균 0·단위분산을 둔 **근사적 분산 분석**입니다. p.8은 fixed query와 positional encoding을 도식으로 제시하며 별도의 증명식을 주지 않습니다. 나머지 p.2-6, p.9-41은 occupancy, geometry, temporal alignment, foundation model 및 fleet-learning 구조를 설명하는 개념·경험 자료이므로 인위적인 수식 증명을 추가하지 않았습니다.

</details>

## 1. 2022 Occupancy Pivot

Tesla의 2022 CVPR 발표는 object list 중심 perception에서 occupancy 중심 world representation으로 이동한 사건으로 볼 수 있습니다.

기존 detector는 "무슨 object가 어디에 있는가"를 묻습니다. Occupancy는 더 직접적으로 "공간의 어떤 부분이 차 있고 비어 있는가"를 묻습니다.

| 표현 | 질문 |
|---|---|
| Object list | 이 장면에 어떤 class의 물체가 있습니까? |
| Lane/free-space mask | 어디가 주행 가능합니까? |
| Occupancy | 3D 공간의 각 cell은 비어 있는가, 차 있는가, 어떤 의미입니까? |

Unknown obstacle이나 불규칙한 geometry는 object ontology로만 다루기 어렵습니다.

## 2. Voxel Intuition

Occupancy는 3D 공간을 voxel 또는 grid로 나누고 각 cell의 상태를 예측합니다.

```text
3D space -> voxel grid -> occupied / free / semantic
```

| 장점 | 설명 |
|---|---|
| Geometry-first | class 이름보다 공간 구조를 먼저 표현합니다. |
| Unknown object 대응 | 학습된 class가 아니어도 차 있는 공간으로 표현 가능 |
| Planning 친화성 | planner가 collision과 free space를 직접 사용할 수 있음 |

이 직관은 safety와 연결됩니다. class를 틀리더라도 공간이 막혀 있다는 사실을 알면 충돌 회피에 사용할 수 있습니다.

## 3. 2022 Architecture Overview

2022 구조는 multi-camera video를 입력으로 받아 3D occupancy feature로 변환합니다. 강의 내용상 backbone은 pure Vision Transformer라기보다 RegNet과 BiFPN 같은 CNN 계열 feature extractor를 포함하고, 이후 attention block이 image feature를 occupancy representation으로 끌어올립니다.

```text
multi-camera images
-> image backbone
-> feature fusion / attention
-> occupancy features
-> occupancy volume
```

핵심은 최종 출력이 단순 object list가 아니라 dense spatial volume이라는 점입니다.

## 4. Transformer-Style Attention

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/autonomous-driving-2-slide-08.png" | relative_url }}" alt="AIX Autonomous Driving 2 강의 8쪽. occupancy network의 volumetric, multi-camera, video context 특성과 차량 주변 3D occupancy 예시." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf#page=8" | relative_url }}" target="_blank" rel="noopener"><code>Autonomous_Driving_2.pdf</code> p.8</a> — 여러 camera와 시간 문맥을 3D occupancy로 통합하는 원본 사례.</figcaption>
</figure>

오른쪽 3D 장면은 camera별 detection 결과를 나열한 것이 아니라, 차량 주변 공간에서 무엇이 차지되어 있는지를 하나의 volumetric representation으로 합친 결과입니다. Fixed query와 positional encoding은 attention이 이 공간의 특정 위치를 일관되게 조회하도록 좌표 기준을 제공합니다.

2022 구조에는 Q, K, V와 softmax attention이 명시적으로 등장합니다. 즉 pure ViT는 아니지만 transformer-style attention이 2D image feature를 3D occupancy query와 연결하는 역할을 합니다.

| 요소 | 역할 |
|---|---|
| Fixed query | 3D 공간에서 알고 싶은 위치 또는 cell을 대표 |
| Positional encoding | 공간 위치 정보를 attention 계산에 제공 |
| Key/value | camera image feature에서 가져올 정보 |
| Attention | 어떤 view와 feature가 해당 3D 위치에 중요한지 선택 |

슬라이드에 제시된 attention 계산을 occupancy 문맥에 맞춰 쓰면 다음과 같습니다.

$$
O=\operatorname{softmax}\left(\frac{QK^T}{\sqrt{d_k}}+M\right)V
$$

$$Q\in\mathbb{R}^{n_q\times d_k}$$는 $$n_q$$개 공간 query, $$K\in\mathbb{R}^{n_f\times d_k}$$와 $$V\in\mathbb{R}^{n_f\times d_v}$$는 $$n_f$$개 image feature, $$M$$은 볼 수 없는 위치에 $$-\infty$$를 주는 선택적 mask입니다. 모두 learned representation이므로 물리 단위는 없습니다. 행별 softmax weight $$\alpha_{ij}$$는 합이 1이고, 각 output query는 $$o_i=\sum_j\alpha_{ij}v_j$$라는 value의 가중합이 됩니다. 이는 attention의 **정의**이며, weight가 높은 feature가 인과적으로 중요하다는 증명은 아닙니다.

Scaling은 query와 key 성분이 독립·평균 0·분산 1이라고 근사할 때 dot product 분산이 $$d_k$$가 되는 데서 나옵니다. $$\sqrt{d_k}$$로 나누면 분산이 약 1이 되어 softmax 포화를 줄입니다. 실제 feature는 상관될 수 있으므로 이는 **근사적 분산 분석**입니다. Camera calibration, positional encoding 또는 query 위치가 틀리면 attention 연산 자체가 정상이어도 잘못된 3D cell에 정보를 모을 수 있습니다.

이 구조는 classical perception과 transformer-era representation learning 사이의 bridge로 볼 수 있습니다.

## 5. Geometry Beats Ontology

자율주행 safety에서는 물체 이름을 맞히는 것보다 그 공간이 안전한지 아는 것이 더 중요할 때가 있습니다.

예를 들어 detector가 false pedestrian을 만들거나 true pedestrian을 놓치는 경우, 문제는 classification accuracy만이 아니라 downstream driving consequence입니다.

| 문제 | Object-centric 표현의 한계 |
|---|---|
| Unknown obstacle | 학습된 class에 없으면 표현이 약합니다. |
| Irregular geometry | box로 깔끔하게 감싸기 어렵습니다. |
| Occlusion | 보이지 않는 공간의 불확실성을 표현해야 합니다. |
| Planning | planner가 geometry와 free space를 직접 필요로 합니다. |

Occupancy는 ontology가 틀리거나 빠져도 geometry를 통해 안전 판단을 보완할 수 있습니다.

## 6. Representation-Level End-to-End

2022 Tesla story는 강한 의미의 "camera directly to steering"은 아닙니다. 더 정확히는 representation-level end-to-end입니다.

```text
camera/video -> learned unified world representation -> downstream driving modules
```

즉 사람이 만든 object list interface를 줄이고, 더 통합된 latent world state를 학습합니다. 하지만 모든 planning과 control이 하나의 network로 완전히 합쳐졌다고 보기는 어렵습니다.

## 7. 2023 Foundation Model 방향

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/autonomous-driving-2-slide-26.png" | relative_url }}" alt="AIX Autonomous Driving 2 강의 슬라이드 26쪽. 여러 카메라 입력이 image featurizer, spatial attention, temporal alignment, deconvolution을 지나 surface, volume, queryable output으로 분기되는 Tesla 2023 구조." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf#page=26" | relative_url }}" target="_blank" rel="noopener"><code>Autonomous_Driving_2.pdf</code> p.26</a> — 여러 task가 공유하는 world representation과 queryable output을 보여주는 원본 슬라이드.</figcaption>
</figure>

왼쪽의 여러 카메라 입력은 공통 image featurizer를 지나 spatial attention에서 공간적으로 합쳐집니다. 가운데 temporal alignment는 이전 frame의 정보를 현재 representation에 정렬합니다. 오른쪽에서는 같은 내부 상태가 deconvolution을 거쳐 surface와 volume output으로 분기되고, 별도 query head도 이 상태를 재사용합니다. 여기서 `shared`는 모든 task의 최종 출력이 같다는 뜻이 아니라, 서로 다른 head가 공통 latent world state를 질의한다는 뜻입니다.

2023 발표는 occupancy를 넘어 shared world representation을 여러 task가 재사용하는 foundation model 관점으로 확장됩니다.

| 2022 | 2023 |
|---|---|
| Occupancy 중심 dense geometry | 여러 task가 공유하는 world representation |
| 공간을 더 잘 표현 | 표현을 detection, mapping, forecasting, planning에 재사용 |
| Representation pivot | Foundation-model style reuse |

Foundation model for driving의 핵심은 하나의 큰 representation이 여러 downstream task의 공통 기반이 되는 것입니다.

## 8. Temporal Alignment와 Video

운전은 단일 이미지 문제가 아니라 시간적 문제입니다. 2023 흐름에서는 multi-camera뿐 아니라 시간축 정렬이 중요해집니다.

| 시간 정보가 필요한 이유 | 설명 |
|---|---|
| Occlusion recovery | 잠깐 가려진 물체를 이전 frame으로 보완 |
| Motion reasoning | agent의 속도와 의도를 추정 |
| Future consistency | 미래 상태 예측과 planning 안정화 |
| 4D world model | 3D 공간에 시간축을 더한 표현 |

따라서 video는 driving foundation model의 자연스러운 training unit이 됩니다.

## 9. Data Engine과 Fleet Learning

Foundation model은 모델 구조만으로 완성되지 않습니다. 실제 fleet에서 수집한 data를 바탕으로 실패 사례를 찾고, auto-labeling과 retraining을 반복해야 합니다.

<figure>
  <a href="{{ "/assets/images/study/aix/supplementary/fleet-learning-closed-loop.svg" | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ "/assets/images/study/aix/supplementary/fleet-learning-closed-loop.svg" | relative_url }}" alt="Fleet data, failure mining, auto-labeling, training과 validation, deployment가 다시 fleet data로 이어지는 폐루프." loading="lazy">
  </a>
  <figcaption><strong>Supplementary diagram.</strong> Fleet learning의 deployment–data feedback loop를 정리한 보강 도식. 이미지를 누르면 확대해서 볼 수 있습니다.</figcaption>
</figure>

1번부터 5번까지 시계 방향으로 읽습니다. 실제 차량에서 모은 data 전체를 그대로 재학습에 넣는 것이 아니라, failure mining으로 어려운 사례를 고르고 auto-labeling으로 supervision을 만듭니다. 새 모델은 training과 validation을 통과한 뒤에만 deployment되며, 그 결과가 다음 cycle의 fleet data가 됩니다. 이는 과정 관계를 설명하는 작성자 보충 도식이며, 각 단계의 처리량이나 성능 향상 폭을 측정한 원문 결과가 아닙니다.

| 요소 | 의미 |
|---|---|
| Fleet scale | rare case를 충분히 모을 수 있는 기반 |
| Auto-labeling | 사람이 모두 labeling할 수 없는 규모의 supervision 생성 |
| Failure mining | 모델이 약한 상황을 찾아 데이터셋에 반영 |
| Deployment loop | 개선된 모델을 다시 실제 주행에 연결 |

이 폐루프가 빠르게 돌수록 representation은 실제 도로 분포에 더 잘 맞춰집니다.

## 10. 역사적 종합

<figure>
  <img src="{{ "/assets/images/study/aix/source-figures/autonomous-driving-2-slide-40.png" | relative_url }}" alt="AIX Autonomous Driving 2 강의 40쪽. modular ADS와 end-to-end 흐름을 출발점으로 occupancy 및 foundation model 방향을 종합한 슬라이드." loading="lazy">
  <figcaption><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf#page=40" | relative_url }}" target="_blank" rel="noopener"><code>Autonomous_Driving_2.pdf</code> p.40</a> — modular output에서 dense world state와 reusable foundation representation으로 이동한 역사를 요약한 원본 슬라이드.</figcaption>
</figure>

그림 중앙의 modular/end-to-end 비교는 출발점입니다. 강의의 뒤쪽 흐름은 개별 task output을 바로 만드는 데서 멈추지 않고, occupancy처럼 더 조밀한 world state를 학습한 뒤 여러 task가 그 표현을 공유하는 방향으로 이동합니다.

자율주행 표현은 다음 흐름으로 볼 수 있습니다.

```text
Modular stack -> Occupancy representation -> Foundation model for driving
```

Modular stack은 문제를 module output으로 나눴고, occupancy는 더 조밀한 world state를 학습했으며, foundation model은 그 world state를 여러 task가 공유하도록 확장했습니다.

## 마지막 핵심 정리

### 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| 2022 Tesla occupancy pivot의 의미는 무엇입니까? | object list보다 dense 3D geometry를 중심 representation으로 둔 것 |
| Occupancy가 safety에 유리한 이유는 무엇입니까? | unknown obstacle도 차 있는 공간으로 표현할 수 있기 때문 |
| 2022 구조가 pure ViT가 아닌 이유는 무엇입니까? | CNN backbone과 attention-based lifting이 결합된 구조이기 때문 |
| Representation-level end-to-end란 무엇입니까? | 사람이 만든 중간 output 대신 통합 latent world state를 학습하는 것 |
| 2023 foundation model 방향의 핵심은 무엇입니까? | 하나의 shared representation을 여러 driving task가 재사용하는 것 |

## Study Guide

multi-camera feature가 attention-based lifting을 거쳐 3D voxel occupancy가 되는 2022 구조를 순서대로 그려 봅니다. CNN backbone을 포함한다는 점 때문에 pure ViT와 다르고, representation-level end-to-end가 곧 camera-to-steering을 뜻하지 않는다는 점이 주요 혼동 지점입니다. 마지막에는 temporal alignment가 4D world model을 만드는 과정과 shared representation·fleet learning의 연결을 함께 설명합니다.

## 복습 질문

<details markdown="block">
<summary>1. Object detector가 높은 정확도를 가져도 occupancy가 필요한 이유는 무엇입니까?</summary>

답변: object detector는 정해진 객체 class와 bounding box 중심으로 환경을 봅니다. 그러나 주행에는 도로 위 점유 공간, 비정형 장애물, 가려진 영역, free space도 중요합니다. occupancy는 객체가 무엇인지보다 어디가 차 있는지를 표현하므로 planning에 더 직접적인 정보를 제공합니다.

</details>

<details markdown="block">
<summary>2. Fixed query와 positional encoding은 3D occupancy attention에서 각각 어떤 역할을 합니까?</summary>

답변: fixed query는 3D 공간의 각 위치나 voxel을 질의하는 기준점 역할을 합니다. positional encoding은 그 query가 공간상 어디에 있는지 모델에 알려줍니다. attention은 이미지 feature와 이 공간 query를 연결해 2D 관측을 3D occupancy 표현으로 끌어올립니다.

</details>

<details markdown="block">
<summary>3. Fleet learning loop가 foundation model for driving의 일부로 봐야 하는 이유는 무엇입니까?</summary>

답변: 실제 차량 fleet에서 수집되는 데이터는 드문 상황과 실패 사례를 계속 보강합니다. 이 데이터가 labeling, training, validation을 거쳐 모델에 다시 반영되면 주행 모델은 점점 더 넓은 상황을 학습합니다. 그래서 fleet learning loop는 단순 배포 과정이 아니라 driving foundation model을 키우는 핵심 학습 체계입니다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_2.pdf" | relative_url }}" target="_blank" rel="noopener">Autonomous_Driving_2.pdf</a></li>
</ul>
