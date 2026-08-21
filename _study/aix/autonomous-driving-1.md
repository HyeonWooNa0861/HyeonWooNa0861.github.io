---
layout: default
date: 2026-05-20 13:52:05 +0900
title: "Autonomous Driving 1"
course: "AIX"
topic: "Modular Autonomous Driving and Occupancy Transition"
order: 7
major_topic: "Artificial Intelligence"
keywords:
  - "Modular ADS"
  - "Sensor Fusion"
  - "HD Map"
  - "RSS"
  - "Occupancy"
---

# Autonomous Driving 1

Source PDF: `Autonomous_Driving_1.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 자율주행이 AI 문제가 된 이유 | 운전은 왜 단순 제어가 아니라 인식과 불확실성 문제인가? |
| 2 | DARPA Challenge | 초기 자율주행은 어떤 benchmark로 발전했는가? |
| 3 | Modular ADS | localization, perception, prediction, planning, control은 왜 분리되었는가? |
| 4 | ML의 첫 진입 지점 | machine learning은 왜 perception에서 먼저 강해졌는가? |
| 5 | Sensor fusion과 HD map | 카메라, LiDAR, radar, map은 어떻게 결합되었는가? |
| 6 | RSS와 safety envelope | 규칙 기반 안전 보장은 왜 중요했는가? |
| 7 | Modular stack의 한계 | error propagation, corner case, stitched output 문제는 무엇인가? |
| 8 | Occupancy와 data engine | representation learning으로 중심이 어떻게 이동했는가? |

## 1. 자율주행이 AI 문제가 된 이유

운전은 단순히 steering angle과 acceleration을 제어하는 문제가 아니다. 실제 도로는 open-world 환경이며, 모델은 사람, 차량, 표지판, 차선, 장애물, 날씨, 예외 상황을 함께 이해해야 한다.

| 어려움 | 설명 |
|---|---|
| Perception | 주변 물체와 공간 구조를 인식해야 한다. |
| Prediction | 다른 agent의 미래 행동을 추정해야 한다. |
| Planning | 안전하고 규칙을 지키는 경로를 선택해야 한다. |
| Uncertainty | sensor noise, occlusion, rare event를 다뤄야 한다. |

따라서 자율주행은 robotics, computer vision, machine learning, control이 결합된 시스템 문제다.

## 2. Challenge Era

상용 제품 이전의 자율주행은 공개 robotics challenge를 통해 발전했다. DARPA Grand Challenge와 Urban Challenge는 자율주행을 하나의 통합 시스템 문제로 만들었다.

| Challenge | 의미 |
|---|---|
| DARPA Grand Challenge | off-road autonomous navigation을 목표로 함 |
| DARPA Urban Challenge | 교통 규칙, 교차로, 움직이는 agent가 포함된 도시 주행 |

Urban Challenge 이후 자율주행은 단순 경로 추종이 아니라 situational awareness와 decision making이 중요한 문제로 자리 잡았다.

## 3. Modular ADS 구조

초기 산업용 autonomous driving system은 대부분 modular architecture를 따랐다.

```text
sensors -> localization -> perception -> prediction -> planning -> control
```

| Module | 역할 |
|---|---|
| Localization | 차량이 지도상 어디에 있는지 추정 |
| Perception | 물체, 차선, drivable area 등을 인식 |
| Prediction | 주변 agent의 미래 움직임 예측 |
| Planning | 안전한 주행 경로와 행동 선택 |
| Control | 계획된 경로를 실제 차량 명령으로 실행 |

이 구조는 각 팀이 module을 독립적으로 개발, 검증, 디버깅하기 쉽다는 장점이 있었다.

## 4. Machine Learning이 먼저 들어온 곳

Machine learning은 자율주행 전체를 한 번에 대체하기보다 perception에서 먼저 강한 효과를 보였다.

| Perception task | ML 활용 |
|---|---|
| Object detection | 차량, 보행자, 신호등 검출 |
| Semantic segmentation | 픽셀 단위 도로, 차선, 보도 구분 |
| Tracking | 시간에 따른 물체 위치 추적 |
| Classification | 표지판, 신호 상태, object type 분류 |

Perception은 대량의 sensor data와 label을 활용해 supervised learning을 적용하기 쉬운 영역이었다.

## 5. Sensor Fusion과 HD Map

초기 산업용 자율주행에서는 camera, LiDAR, radar, HD map을 결합하는 설계가 중요했다.

| Sensor/정보 | 강점 |
|---|---|
| Camera | 풍부한 시각 정보와 semantic cue |
| LiDAR | 정확한 거리와 3D geometry |
| Radar | 속도 추정과 악천후 강건성 |
| HD map | 차선, 표지, 도로 구조에 대한 prior |

이 접근은 다양한 sensor의 장점을 결합하지만, 시스템이 복잡해지고 map 유지 비용이 커진다.

## 6. RSS와 Rule-Based Safety

Mobileye의 RSS(Responsibility-Sensitive Safety)는 안전을 learned policy의 감각에만 맡기지 않고, 명시적 규칙과 safe distance로 정의하려는 접근이다.

핵심 아이디어는 다음과 같다.

```text
proposed action -> safety envelope check -> proper response
```

| 관점 | 의미 |
|---|---|
| Safety envelope | 어떤 행동이 확실히 위험한지 규칙으로 정의 |
| Proper response | 위험 상황에서 취해야 하는 책임 있는 반응 |
| Accountability | opaque model과 별도로 검증 가능한 안전 기준 제공 |

산업에서는 규제, 검증, 책임 소재 때문에 rule-based safety layer가 오랫동안 중요했다.

## 7. Modular System의 장점과 한계

Modular system은 해석과 검증이 쉽지만, module 사이의 interface가 전체 성능을 제한할 수 있다.

| 한계 | 설명 |
|---|---|
| Error propagation | perception의 작은 오류가 prediction, planning으로 전파된다. |
| Long-tail corner case | 드문 상황마다 규칙을 추가하면 복잡도가 빠르게 증가한다. |
| Stitched outputs | object list, lane list, freespace mask가 coherent world model을 만들지는 않는다. |
| Local optimum | 각 module은 좋아도 전체 driving behavior가 최적이 아닐 수 있다. |

즉, module별 정확도만 높인다고 항상 좋은 주행 정책이 되는 것은 아니다.

## 8. Occupancy로의 이동

Occupancy representation은 물체 list만 예측하는 대신 3D space의 cell이 비어 있는지, 차 있는지, 어떤 의미를 갖는지 예측한다.

```text
3D space -> voxel/grid -> occupied, free, semantic label
```

이 방식은 알 수 없는 장애물이나 불규칙한 geometry도 표현할 수 있어 safety와 planning에 더 직접적으로 도움이 된다.

## 9. Data Engine과 Software 2.0

End-to-end 방향으로 가려면 모델 구조만 바뀌어서는 부족하다. Fleet data를 수집하고, 실패 사례를 mining하고, labeling과 retraining을 반복하는 data engine이 필요하다.

| 구성 | 역할 |
|---|---|
| Fleet data | 실제 도로에서 다양한 상황을 수집 |
| Mining | 실패 사례와 rare case를 찾아냄 |
| Auto-labeling | 대규모 supervision 생성 |
| Retraining | 새 데이터로 모델 갱신 |
| Redeployment | 개선된 모델을 다시 차량에 배포 |

이 관점에서 "모델"은 neural network 하나가 아니라 데이터 수집부터 배포까지 포함한 폐루프 시스템이다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| Modular ADS의 기본 module은? | localization, perception, prediction, planning, control |
| RSS의 핵심 목적은? | learned policy와 별도로 검증 가능한 safety envelope 제공 |
| Error propagation은 무엇인가? | 앞 module의 오류가 뒤 module 의사결정으로 전파되는 현상 |
| Occupancy가 object list보다 나은 점은? | unknown object와 irregular geometry를 공간적으로 표현 가능 |
| Data engine이 중요한 이유는? | rare case를 지속적으로 발견하고 모델을 갱신하기 위해 |

## 복습 질문

<details>
<summary>1. 자율주행에서 perception과 planning을 완전히 분리하면 어떤 장단점이 생기는가?</summary>

답변: 분리하면 각 모듈을 독립적으로 설계, 디버깅, 검증하기 쉽다. 하지만 perception의 오차가 planning으로 그대로 전달되고, planning에 필요한 정보가 perception 단계에서 사라질 수 있다. end-to-end 방식은 이런 정보 손실을 줄일 수 있지만 해석성과 안전 검증이 어려워진다.

</details>

<details>
<summary>2. HD map 기반 접근과 camera-first learning 접근의 차이를 설명하라.</summary>

답변: HD map 기반 접근은 정밀 지도와 위치 추정을 강하게 활용해 안정적인 주행 계획을 만든다. 반면 camera-first learning은 카메라 입력에서 주변 구조를 직접 학습해 지도 의존도를 줄인다. 전자는 검증 가능성이 높고, 후자는 확장성과 최신 환경 대응이 장점이다.

</details>

<details>
<summary>3. Occupancy representation이 end-to-end driving으로 가는 bridge가 되는 이유는 무엇인가?</summary>

답변: occupancy는 객체 단위 인식 결과보다 더 조밀하게 공간의 점유 여부를 표현한다. 따라서 perception 결과를 planning이 바로 사용할 수 있는 3D 공간 표현으로 바꿔준다. 완전한 black-box end-to-end보다 해석 가능성을 남기면서도 학습 기반 주행으로 연결되는 중간 표현이다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/Autonomous_Driving_1.pdf" | relative_url }}" target="_blank" rel="noopener">Autonomous_Driving_1.pdf</a></li>
</ul>
