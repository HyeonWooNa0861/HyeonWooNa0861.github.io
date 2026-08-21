---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 4: Neural Networks and Backpropagation"
course: "CS231N"
topic: "Neural Networks and Backpropagation"
order: 4
major_topic: "Computer Vision"
keywords:
  - "Neural Networks"
  - "Backpropagation"
  - "Activation Functions"
  - "Computational Graphs"
  - "Gradients"
---

# Stanford CS231N Lecture 4: Neural Networks and Backpropagation

Source: [Stanford CS231N Spring 2025 Lecture 4](https://www.youtube.com/watch?v=25zD5qJHYsk){:target="_blank" rel="noopener"}

## 핵심 내용

선형 분류기를 여러 층의 비선형 함수로 확장해 신경망을 구성하는 방법과, 계산 그래프를 따라 미분을 전달하는 역전파를 설명한다. 활성화 함수는 모델에 비선형성을 부여하고, 은닉층은 입력의 중간 표현을 학습한다. 역전파는 chain rule을 체계적으로 적용해 각 파라미터가 손실에 미치는 영향을 계산한다.

## 학습 포인트

- 신경망은 선형 변환과 비선형 활성화 함수를 쌓아 복잡한 함수를 표현한다.
- 계산 그래프는 순전파 값과 역전파 기울기의 흐름을 명확히 만든다.
- 역전파는 딥러닝 학습을 가능하게 하는 핵심 알고리즘이다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Activation Function | 선형 변환 사이에 비선형성을 넣어 표현력을 높이는 함수 |
| Computational Graph | 연산을 노드와 간선으로 표현해 미분 흐름을 추적하는 구조 |
| Backpropagation | chain rule로 손실의 기울기를 각 파라미터까지 전달하는 알고리즘 |
| Hidden Layer | 입력과 출력 사이에서 중간 표현을 학습하는 층 |

## Study Guide

1. 신경망에서 비선형 활성화 함수가 필요한 이유는 무엇인가?
2. 계산 그래프 관점에서 역전파는 어떤 정보를 뒤로 전달하는가?
3. 깊이가 늘어날 때 기울기 계산은 왜 더 어려워질 수 있는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 4](https://www.youtube.com/watch?v=25zD5qJHYsk){:target="_blank" rel="noopener"}
