---
layout: default
title: "Stanford CS231N Lecture 5: Image Classification with CNNs"
course: "CS231N"
topic: "CNN-Based Image Classification"
order: 5
major_topic: "Computer Vision"
keywords:
  - "CNN"
  - "Convolution"
  - "Pooling"
  - "Image Classification"
  - "Feature Maps"
---

# Stanford CS231N Lecture 5: Image Classification with CNNs

Source: [Stanford CS231N Spring 2025 Lecture 5](https://www.youtube.com/watch?v=f3g1zGdxptI){:target="_blank" rel="noopener"}

## 핵심 내용

이미지의 공간 구조를 활용하는 합성곱 신경망을 본격적으로 소개한다. 합성곱 필터는 지역 패턴을 감지하고, weight sharing은 위치마다 같은 필터를 적용해 파라미터 수를 줄인다. pooling, padding, stride, receptive field 같은 개념은 CNN의 출력 크기와 표현 범위를 이해하는 데 필요하다.

## 학습 포인트

- CNN은 이미지의 지역성과 이동 등가성을 활용한다.
- 합성곱 층은 필터를 통해 공간적으로 공유되는 특징 검출기를 학습한다.
- 출력 크기와 receptive field 계산은 CNN 설계의 기본이다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Convolution | 작은 필터를 입력 전체에 적용해 feature map을 만드는 연산 |
| Stride | 필터가 이동하는 간격 |
| Padding | 출력 크기와 경계 정보를 조절하기 위해 입력 주변에 값을 추가하는 방식 |
| Receptive Field | 한 뉴런이 영향을 받는 입력 영역 |

## Study Guide

1. CNN이 fully connected network보다 이미지에 적합한 이유는 무엇인가?
2. padding과 stride는 출력 크기에 어떤 영향을 주는가?
3. receptive field가 깊은 층에서 커지는 이유는 무엇인가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 5](https://www.youtube.com/watch?v=f3g1zGdxptI){:target="_blank" rel="noopener"}
