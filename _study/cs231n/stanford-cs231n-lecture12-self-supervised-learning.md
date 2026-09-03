---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 12: Self-Supervised Learning"
course: "CS231N"
topic: "Self-Supervised Learning"
order: 12
major_topic: "Computer Vision"
keywords:
  - "Self-Supervised Learning"
  - "Contrastive Learning"
  - "Pretext Tasks"
  - "Representation Learning"
  - "Masked Modeling"
---

# Stanford CS231N Lecture 12: Self-Supervised Learning

Source: [Stanford CS231N Spring 2025 Lecture 12](https://www.youtube.com/watch?v=4howBU7THbM){:target="_blank" rel="noopener"}

> **핵심:** 자기지도학습은 레이블을 없애는 마법이 아니라, 데이터 변환과 가림으로 **학습 목표를 자동 생성**하는 설계다. 좋은 pretext task는 정답을 맞히는 지름길보다 downstream task에 재사용할 의미 표현을 요구해야 한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Pretext task | 입력에서 supervision을 어떻게 만드는가? |
| 2 | Transformation tasks | 회전·조각 순서·색 복원이 무엇을 학습시키는가? |
| 3 | Reconstruction | Inpainting과 MAE는 왜 비대칭 구조를 쓰는가? |
| 4 | Contrastive learning | Positive는 가깝게, negative는 멀게 만드는 법은? |
| 5 | SimCLR and MoCo | Augmentation, batch, queue가 어떤 역할을 하는가? |

## 1. Pretext task가 표현을 만든다

Self-supervised learning은 사람이 붙인 class label 대신 입력 자체에서 target을 만든다. Encoder \(f_\theta\)를 pretext objective로 학습한 뒤 task-specific head를 붙여 fine-tuning하거나, encoder를 고정하고 linear probe로 표현 품질을 측정한다.

Pretext accuracy가 높다고 표현이 반드시 좋은 것은 아니다. 모델이 변환 과정의 경계선이나 고정된 crop 위치 같은 지름길로 답을 맞히면 의미 구조를 배우지 못한다. 평가의 초점은 **downstream transfer**에 있어야 한다.

## 2. 회전, jigsaw, 상대 위치, colorization

회전 예측은 이미지를 \(0^\circ,90^\circ,180^\circ,270^\circ\) 중 하나로 돌리고 각도를 분류한다. 물체의 정상 방향을 알려면 형태와 의미를 어느 정도 알아야 한다. Jigsaw는 patch를 섞어 permutation을 맞히게 하고, 상대 위치 예측은 기준 patch에 대한 다른 patch의 위치를 분류한다. 두 방법 모두 부분과 전체의 공간 관계를 요구한다.

Colorization은 grayscale 입력에서 색을 복원한다. 단순 RGB 회귀는 가능한 색의 평균을 내 흐릿해지기 쉬우므로, 강의는 색 공간을 양자화한 class distribution 예측과 불균형 보정 아이디어를 설명한다. 이 작업은 객체 종류와 영역 경계를 알아야 그럴듯한 색을 선택할 수 있다는 점에서 표현 학습 신호가 된다.

## 3. Inpainting에서 Masked Autoencoder로

Inpainting은 입력 일부를 가리고 missing region을 복원한다. Masked Autoencoder(MAE)는 이미지를 patch token으로 바꾸고 높은 비율을 가린 뒤, 보이는 token만 큰 encoder에 넣는다. 작은 decoder가 encoder 출력과 공통 mask token, 위치 정보를 받아 가려진 patch의 pixel을 복원한다.

핵심은 encoder와 decoder가 비대칭이라는 점이다. Encoder는 visible patch만 처리해 pretraining 계산량을 줄이고, reconstruction 전용 decoder는 downstream 사용 시 버린다. Loss도 주로 masked patch에서 계산하므로 이미 보이는 픽셀을 복사하는 쉬운 문제가 되지 않는다.

## 4. Contrastive learning과 InfoNCE

한 이미지에 서로 다른 augmentation을 적용한 두 view를 positive pair로, 다른 이미지의 view를 negative로 둔다. 정규화된 표현 \(z_i,z_j\)의 유사도를 \(s_{ij}=z_i^\top z_j\), temperature를 \(\tau\)라 하면 한 방향의 InfoNCE는 다음처럼 쓸 수 있다.

$$
\mathcal{L}_i=-\log\frac{\exp(s_{i,+}/\tau)}{\sum_{k}\exp(s_{ik}/\tau)}
$$

분자는 positive 유사도를 키우고 분모의 다른 표본은 상대적으로 밀어낸다. 강의는 negative 수가 많을수록 mutual-information lower bound가 더 촘촘해지는 해석도 소개하지만, 실제 성공은 어떤 augmentation이 의미를 보존하는지에 크게 달려 있다.

## 5. SimCLR, MoCo, DINO로 이어지는 설계

SimCLR은 한 batch 안에서 각 이미지의 두 augmented view를 만들고, encoder 뒤 projection head에서 contrastive loss를 계산한다. 큰 batch는 많은 negative를 제공한다. Crop과 color distortion 같은 강한 augmentation의 조합이 핵심이며, downstream에는 projection 이전 표현을 사용한다.

MoCo는 batch 밖 과거 key 표현을 queue에 저장해 많은 negative를 유지한다. Key encoder는 query encoder의 exponential moving average로 천천히 갱신되어 queue의 표현이 갑자기 바뀌지 않게 한다. 강의 말미는 DINO처럼 teacher-student와 momentum encoder를 사용하면서 명시적 negative에 덜 의존하는 흐름도 연결한다.

## 마지막 핵심 정리

- Self-supervision의 품질은 **자동 target이 어떤 의미 정보를 요구하는가**에 달려 있다.
- MAE는 visible token만 큰 encoder에 넣어 계산을 아끼고 masked patch 복원에 집중한다.
- InfoNCE는 positive similarity를 다른 후보보다 상대적으로 크게 만든다.
- SimCLR은 augmentation과 큰 batch, MoCo는 momentum encoder와 queue로 학습 신호를 구성한다.

## Study Guide

각 pretext task마다 “자동 정답”, “모델이 배워야 하는 정보”, “가능한 지름길”을 세 칸 표로 정리한다. MAE의 encoder 입력과 decoder 입력을 구분하고, SimCLR과 MoCo가 negative를 확보하는 방법을 비교하면 흐름이 선명해진다.

## 복습 질문

<details><summary>1. Pretext task 성능만으로 좋은 표현을 판단할 수 없는 이유는?</summary>

답변: 모델이 의미 이해 없이 low-level artifact나 데이터 생성 규칙을 이용해 pretext 정답을 맞힐 수 있기 때문이다. Transfer 또는 linear-probe 결과로 재사용 가능성을 확인해야 한다.
</details>

<details><summary>2. MAE가 masked token을 큰 encoder에 넣지 않는 이유는?</summary>

답변: 보이는 patch만 처리하면 token 수가 줄어 pretraining 계산량을 크게 아낄 수 있다. Mask token과 전체 위치 복원은 작은 decoder가 담당한다.
</details>

<details><summary>3. SimCLR과 MoCo의 negative 확보 방식은 어떻게 다른가?</summary>

답변: SimCLR은 현재 큰 batch의 다른 view를 negative로 사용한다. MoCo는 momentum key encoder로 만든 과거 표현을 queue에 저장해 batch 크기와 분리된 많은 negative를 사용한다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=4howBU7THbM){:target="_blank" rel="noopener"}
