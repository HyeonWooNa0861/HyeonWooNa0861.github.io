---
layout: default
title: "Stanford CS231N Lecture 2: Image Classification with Linear Classifiers"
course: "CS231N"
topic: "Image Classification and Linear Classifiers"
order: 2
---

# Stanford CS231N Lecture 2: Image Classification with Linear Classifiers

Source: [Stanford CS231N Spring 2025 Lecture 2](https://www.youtube.com/watch?v=pdqofxJeBN8){:target="_blank" rel="noopener"}

## 핵심 내용

이미지 분류 문제를 정식화하고, k-NN과 선형 분류기를 통해 데이터 기반 접근법의 기본 구조를 설명하는 강의다. 이미지가 고차원 픽셀 벡터로 표현될 때 분류기는 각 클래스의 점수를 계산하고, 손실 함수는 올바른 클래스 점수가 다른 클래스보다 충분히 높아지도록 학습 신호를 제공한다. SVM loss와 softmax loss는 이후 신경망 학습의 기본 언어가 된다.

## 학습 포인트

- 이미지 분류는 고차원 입력을 이산 클래스 레이블로 매핑하는 문제다.
- 선형 분류기는 각 클래스별 가중치 벡터로 점수를 계산한다.
- 손실 함수는 파라미터가 어떤 방향으로 바뀌어야 하는지 정의한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| k-NN | 학습 데이터와의 거리로 레이블을 예측하는 비모수 분류기 |
| Linear Classifier | 입력 픽셀과 가중치의 선형 결합으로 클래스 점수를 계산하는 모델 |
| SVM Loss | 정답 클래스 점수와 오답 클래스 점수 사이의 margin을 강제하는 손실 |
| Softmax Loss | 클래스 점수를 확률처럼 해석하고 정답 로그확률을 최대화하는 손실 |

## Study Guide

1. k-NN은 왜 학습은 빠르지만 추론은 느린가?
2. 선형 분류기의 한계는 이미지 분류에서 어떻게 나타나는가?
3. SVM loss와 softmax loss는 어떤 관점 차이를 갖는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 2](https://www.youtube.com/watch?v=pdqofxJeBN8){:target="_blank" rel="noopener"}
