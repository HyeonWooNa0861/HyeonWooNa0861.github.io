---
layout: default
title: "Stanford CS231N Lecture 9: Object Detection, Image Segmentation, Visualizing"
course: "CS231N"
topic: "Object Detection, Segmentation, and Visualization"
order: 9
major_topic: "Computer Vision"
keywords:
  - "Object Detection"
  - "Image Segmentation"
  - "Visualization"
  - "Region Proposals"
  - "Feature Attribution"
---

# Stanford CS231N Lecture 9: Object Detection, Image Segmentation, Visualizing

Source: [Stanford CS231N Spring 2025 Lecture 9](https://www.youtube.com/watch?v=PTypu6GqEd4){:target="_blank" rel="noopener"}

## 핵심 내용

이미지 전체 레이블을 넘어 객체 위치와 픽셀 단위 구조를 예측하는 dense prediction 문제를 다룬다. Object detection은 bounding box와 클래스 예측을 결합하고, segmentation은 픽셀 단위 의미나 인스턴스 마스크를 출력한다. 모델 시각화는 CNN이 어떤 특징을 보고 판단하는지 해석하는 도구로 소개된다.

## 학습 포인트

- 검출은 무엇이 어디에 있는지를 동시에 예측한다.
- 분할은 픽셀 단위로 장면 구조를 이해하는 문제다.
- 시각화는 모델의 내부 표현과 실패 원인을 분석하는 데 도움이 된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Object Detection | 객체의 범주와 위치를 bounding box로 예측하는 작업 |
| Semantic Segmentation | 각 픽셀에 의미 범주를 부여하는 작업 |
| Instance Segmentation | 같은 범주의 객체도 개별 인스턴스로 구분하는 작업 |
| Visualization | 모델이 사용하는 특징과 주의 영역을 분석하는 방법 |

## Study Guide

1. classification과 detection의 출력 구조는 어떻게 다른가?
2. semantic segmentation과 instance segmentation의 차이는 무엇인가?
3. 모델 시각화는 왜 성능 숫자만으로 알 수 없는 정보를 주는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 9](https://www.youtube.com/watch?v=PTypu6GqEd4){:target="_blank" rel="noopener"}
