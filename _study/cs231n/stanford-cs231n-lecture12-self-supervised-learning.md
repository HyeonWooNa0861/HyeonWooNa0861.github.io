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

## 핵심 내용

라벨 없이 데이터 자체에서 학습 신호를 만드는 자기지도학습을 설명한다. Contrastive learning, masked prediction, representation learning은 대규모 비전 모델의 사전학습 방식으로 중요하다. 핵심은 사람이 붙인 정답 레이블이 없어도 좋은 표현을 학습하고, 이후 downstream task에서 적은 레이블로도 성능을 내는 것이다.

## 학습 포인트

- 자기지도학습은 데이터 자체에서 pretext task를 만들어 표현을 학습한다.
- Contrastive learning은 유사한 view는 가깝게, 다른 샘플은 멀게 배치한다.
- 사전학습된 표현은 다양한 downstream task에 전이될 수 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Self-Supervised Learning | 외부 라벨 없이 입력 데이터에서 학습 신호를 구성하는 방법 |
| Contrastive Learning | 양성 쌍과 음성 쌍의 거리 관계로 표현을 학습하는 방식 |
| Masked Prediction | 가려진 입력 일부를 복원하도록 학습하는 방식 |
| Representation Learning | 여러 작업에 유용한 중간 표현을 학습하는 것 |

## Study Guide

1. 자기지도학습은 supervised learning과 어떤 점에서 다른가?
2. contrastive learning에서 positive pair와 negative pair는 어떤 역할을 하는가?
3. 좋은 representation은 downstream task에서 어떤 이점을 주는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 12](https://www.youtube.com/watch?v=4howBU7THbM){:target="_blank" rel="noopener"}
