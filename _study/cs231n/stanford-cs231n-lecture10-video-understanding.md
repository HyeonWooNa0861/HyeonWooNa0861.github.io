---
layout: default
title: "Stanford CS231N Lecture 10: Video Understanding"
course: "CS231N"
topic: "비디오 이해"
order: 10
---

# Stanford CS231N Lecture 10: Video Understanding

Source: [Stanford CS231N Spring 2025 Lecture 10](https://www.youtube.com/watch?v=wElqklprhPE){:target="_blank" rel="noopener"}

## 핵심 내용

비디오는 이미지의 시간적 확장으로, 행동과 사건을 이해하려면 공간 정보와 시간 정보를 함께 모델링해야 한다. 2D CNN을 프레임별로 적용하는 방식, 3D convolution, two-stream network, temporal modeling, transformer 기반 비디오 모델이 비교된다. 핵심은 움직임과 시간적 맥락이 정적 이미지 분류와 다른 학습 신호를 만든다는 점이다.

## 학습 포인트

- 비디오 이해는 공간 특징과 시간적 변화를 함께 다룬다.
- 3D convolution과 temporal attention은 움직임 정보를 직접 모델링한다.
- 데이터 크기와 계산 비용은 비디오 모델의 큰 제약이다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Video Classification | 비디오 전체의 행동이나 사건 범주를 예측하는 작업 |
| 3D Convolution | 공간과 시간 축을 함께 합성곱하는 연산 |
| Optical Flow | 프레임 사이 픽셀 이동을 나타내는 움직임 단서 |
| Temporal Modeling | 시간 순서와 지속성을 모델에 반영하는 방법 |

## Study Guide

1. 비디오 모델이 이미지 모델보다 계산 비용이 큰 이유는 무엇인가?
2. 2D CNN 프레임 처리와 3D CNN은 어떤 차이가 있는가?
3. 움직임 정보는 어떤 경우에 분류 성능을 크게 바꾸는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 10](https://www.youtube.com/watch?v=wElqklprhPE){:target="_blank" rel="noopener"}
