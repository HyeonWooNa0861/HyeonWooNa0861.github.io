---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 3: Regularization and Optimization"
course: "CS231N"
topic: "Regularization and Optimization"
order: 3
major_topic: "Computer Vision"
keywords:
  - "Regularization"
  - "Optimization"
  - "Gradient Descent"
  - "Learning Rate"
  - "Overfitting"
---

# Stanford CS231N Lecture 3: Regularization and Optimization

Source: [Stanford CS231N Spring 2025 Lecture 3](https://www.youtube.com/watch?v=dyNGd06MWn4){:target="_blank" rel="noopener"}

## 핵심 내용

모델이 훈련 데이터를 외우지 않고 일반화하도록 만드는 정규화와, 손실을 실제로 낮추는 최적화 방법을 다룬다. L2 정규화, 데이터 증강, dropout 같은 방법은 모델 용량과 데이터 신호 사이의 균형을 조절한다. 경사하강법, 미니배치 SGD, momentum, adaptive optimizer는 고차원 손실 지형에서 효율적으로 파라미터를 이동시키는 핵심 도구로 설명된다.

## 학습 포인트

- 정규화는 훈련 정확도만 높이는 모델을 막고 일반화 성능을 개선한다.
- 최적화는 손실 함수의 기울기를 사용해 파라미터를 갱신하는 절차다.
- 학습률, 배치 크기, momentum은 학습 안정성과 속도에 직접 영향을 준다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Regularization | 모델의 과적합을 줄이기 위해 학습 문제에 제약이나 잡음을 추가하는 방법 |
| Gradient Descent | 손실의 기울기 반대 방향으로 파라미터를 갱신하는 방법 |
| Momentum | 이전 갱신 방향을 누적해 진동을 줄이고 진행 방향을 안정화하는 최적화 기법 |
| Learning Rate | 한 번의 갱신에서 파라미터가 움직이는 크기 |

## Study Guide

1. 정규화는 왜 단순히 손실을 낮추는 것과 다른 목표를 갖는가?
2. 미니배치 SGD가 전체 배치 경사하강법보다 실용적인 이유는 무엇인가?
3. 학습률이 너무 크거나 너무 작으면 어떤 문제가 생기는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 3](https://www.youtube.com/watch?v=dyNGd06MWn4){:target="_blank" rel="noopener"}
