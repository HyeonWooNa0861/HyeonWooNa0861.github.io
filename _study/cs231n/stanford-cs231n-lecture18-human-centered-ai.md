---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 18: Human-Centered AI"
course: "CS231N"
topic: "Human-Centered AI"
order: 18
major_topic: "Computer Vision"
keywords:
  - "Human-Centered AI"
  - "Bias"
  - "Fairness"
  - "Interpretability"
  - "Responsible AI"
---

# Stanford CS231N Lecture 18: Human-Centered AI

Source: [Stanford CS231N Spring 2025 Lecture 18](https://www.youtube.com/watch?v=g8UaBfj6Sh8){:target="_blank" rel="noopener"}

> **핵심:** Human-centered AI는 정확도 뒤에 윤리 점검표를 붙이는 일이 아니다. 인간의 지각 한계를 보완하고 실제 필요를 해결하도록 **문제 선택, sensor, privacy representation, workflow, robot task, 평가 기준을 처음부터 사람 중심으로 설계**하는 접근이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | From recognition to spatial intelligence | AI가 보고 이름 붙이는 것을 넘어 무엇을 이해해야 하는가? |
| 2 | Human limits and augmentation | AI는 사람의 주의와 기억을 어떻게 보완할 수 있는가? |
| 3 | Privacy-aware healthcare | 유용한 행동 정보와 개인 식별 정보를 분리할 수 있는가? |
| 4 | Ambient intelligence | Hospital과 home workflow에서 어떤 결과를 측정해야 하는가? |
| 5 | Human-centered robotics | 가능한 task가 아니라 사람들이 원하는 task를 어떻게 찾는가? |

## 1. Recognition에서 spatial intelligence로

강의는 visual intelligence가 image label 하나보다 훨씬 넓다고 돌아본다. 사람은 scene에서 object와 관계, action, intent를 읽고 앞으로 벌어질 일을 예측한다. 이러한 spatial intelligence는 3D world를 이해하고 행동을 계획하는 embodied system으로 이어진다.

Deep learning의 parameter 학습은 많은 예에서 regularity를 얻어 새로운 image에 generalize하게 한다. 그러나 benchmark 성능이 높아도 open world의 긴 tail, context 변화, 인간에게 중요한 결과를 자동으로 해결하지는 않는다. “무엇을 맞힐 것인가”라는 task formulation부터 사회적 목적과 연결해야 한다.

## 2. 사람의 한계와 AI augmentation

사람은 풍부한 지능을 갖지만 주의, 기억, 피로에 한계가 있다. 수술실의 도구 확인처럼 작은 누락이 workflow를 중단시키거나 안전 문제를 만들 수 있다. Computer vision은 사람을 교체하기보다 지속적으로 관찰하고 빠진 절차를 알려주는 보조 장치가 될 수 있다.

반대로 AI도 training data와 설계자의 bias를 증폭할 수 있다. Bias는 단순한 모델 내부 숫자가 아니라 누구의 환경에서 error가 나고 그 error가 어떤 결과를 만드는지의 문제다. 배포 전 subgroup 성능만이 아니라 운영 중 feedback, 수정 권한, 책임 주체를 함께 설계해야 한다.

## 3. Privacy를 보존하면서 행동을 인식하기

Patient room과 home camera는 fall, hand hygiene, activity 같은 유용한 신호를 주지만 face, body, 생활 공간이라는 민감 정보도 담는다. 강의는 raw RGB를 그대로 보관하는 것만이 해답이 아님을 강조하고 depth, silhouette 등 identity detail을 줄인 representation과 smart sensor를 논의한다.

Privacy와 utility는 이분법이 아니다. 정보를 강하게 제거하면 행동 구분 능력도 떨어질 수 있다. 목적에 필요한 최소 정보가 무엇인지 정하고, sensor 단계에서부터 보존하지 않을 정보, 저장 기간, 접근 권한을 설계해야 한다. 이는 사후 blur보다 더 구조적인 privacy-by-design 접근이다.

## 4. Healthcare의 ambient intelligence

Healthcare는 한 장의 diagnosis image뿐 아니라 긴 workflow의 행동을 이해해야 한다. Hospital-acquired infection을 줄이기 위한 hand-hygiene monitoring, ICU와 step-down unit의 patient activity, 고령자의 독립 생활 지원이 사례로 제시된다. Human auditor가 모든 장면을 지속 관찰하기 어렵다는 점이 ambient sensor의 동기다.

좋은 system은 recognition accuracy만 보고 끝나지 않는다. Alert가 실제 care workflow에 들어가는지, false alarm이 staff의 주의를 소모하지 않는지, patient와 caregiver가 받아들일 수 있는지, infection·fall·response time 같은 실제 outcome이 개선되는지를 봐야 한다. 기술 지표와 인간 결과 사이에 deployment design이 놓인다.

## 5. 사람들이 원하는 robot task를 먼저 찾기

Robotics 연구는 model이 수행하기 쉬운 benchmark task를 택하기 쉽다. 강의의 human-centered survey는 household robot에게 사람들이 실제로 맡기고 싶은 일을 묻고, cleaning처럼 선호되는 지원과 맡기고 싶지 않은 일을 구분한다. Government survey와 생활 data를 함께 사용해 연구 priority를 실제 필요에 맞춘다.

또한 cloth와 liquid 같은 deformable material, 긴 horizon manipulation, open instruction은 오늘의 robot이 어려워하는 영역이다. 화려한 demo의 성공 여부뿐 아니라 실제 속도, 재시도, 사전 programming 범위를 투명하게 봐야 한다. 목표는 사람을 밀어내는 automation이 아니라 위험하고 반복적이며 돌봄 인력이 부족한 일을 보완하는 augmentation이다.

## 마지막 핵심 정리

- Human-centered AI는 **사람에게 중요한 문제와 outcome에서 출발**한다.
- AI는 인간의 주의·기억 한계를 보완할 수 있지만 data와 배포 구조의 bias도 증폭할 수 있다.
- Healthcare vision은 raw RGB 수집을 기본값으로 두지 않고 task에 필요한 최소 representation을 설계해야 한다.
- Robot 연구도 가능한 task보다 사람들이 원하고 사회적으로 필요한 task를 우선해야 한다.
- 마지막 기준은 replacement가 아니라 인간 능력과 care capacity를 얼마나 안전하게 확장했는가이다.

## Study Guide

하나의 healthcare 또는 home-assistance 사례를 골라 stakeholder, 필요한 signal, 불필요한 identity 정보, failure cost, human override, 실제 outcome을 적는다. Accuracy가 같아도 이 요소에 따라 어느 system이 더 human-centered한지 비교해 본다.

## 복습 질문

<details><summary>1. Human-centered AI가 단순한 fairness audit보다 넓은 이유는?</summary>

답변: Problem selection부터 data·sensor·interface·workflow·평가·책임 구조까지 system 전체가 사람의 필요와 영향을 중심으로 설계되어야 하기 때문이다.
</details>

<details><summary>2. Privacy-aware representation에는 어떤 trade-off가 있는가?</summary>

답변: Face나 texture처럼 identity 정보를 제거하면 privacy는 좋아지지만 task에 필요한 행동 단서까지 잃을 수 있다. 목적별 최소 충분 정보를 찾아야 한다.
</details>

<details><summary>3. Robot task를 human survey로 선정하는 의의는?</summary>

답변: 연구자가 구현하기 쉬운 benchmark와 사용자가 실제로 원하거나 돌봄 공백을 줄이는 task가 다를 수 있으므로, 제한된 연구 자원을 현실의 필요에 맞출 수 있다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=g8UaBfj6Sh8){:target="_blank" rel="noopener"}
