---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 6: CNN Architectures"
course: "CS231N"
topic: "CNN Architectures"
order: 6
major_topic: "Computer Vision"
keywords:
  - "AlexNet"
  - "VGG"
  - "ResNet"
  - "Inception"
  - "CNN Architectures"
---

# Stanford CS231N Lecture 6: CNN Architectures

Source: [Stanford CS231N Spring 2025 Lecture 6](https://www.youtube.com/watch?v=aVJy4O5TOk8){:target="_blank" rel="noopener"}

## 핵심 내용

LeNet, AlexNet, VGG, GoogLeNet, ResNet 등 주요 CNN 구조의 발전을 따라가며 깊이, 폭, 연산량, 최적화 난점이 어떻게 다뤄졌는지 설명한다. 특히 residual connection은 매우 깊은 네트워크를 학습 가능하게 만든 핵심 아이디어다. 아키텍처 설계는 정확도뿐 아니라 메모리, FLOPs, 병렬화, 배치 정규화 같은 실용 요소와 함께 이해해야 한다.

## 학습 포인트

- CNN 아키텍처의 발전은 더 깊고 효율적인 표현 학습을 향해 진행됐다.
- Residual connection은 깊은 네트워크의 최적화 문제를 완화한다.
- 모델 구조 선택은 성능, 계산량, 메모리의 균형 문제다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| VGG | 작은 3x3 convolution을 깊게 쌓은 단순하고 강력한 CNN 구조 |
| GoogLeNet | inception module로 여러 필터 규모를 병렬 결합한 구조 |
| ResNet | 잔차 연결을 통해 깊은 네트워크 학습을 안정화한 구조 |
| Batch Normalization | 중간 활성 분포를 정규화해 학습을 안정화하는 기법 |

## Study Guide

1. VGG가 단순한 구조임에도 중요한 이유는 무엇인가?
2. ResNet의 skip connection은 어떤 최적화 문제를 완화하는가?
3. 아키텍처 비교에서 정확도 외에 어떤 비용을 봐야 하는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 6](https://www.youtube.com/watch?v=aVJy4O5TOk8){:target="_blank" rel="noopener"}
