---
layout: default
title: "Stanford CS231N Lecture 11: Large Scale Distributed Training"
course: "CS231N"
topic: "대규모 분산 학습"
order: 11
---

# Stanford CS231N Lecture 11: Large Scale Distributed Training

Source: [Stanford CS231N Spring 2025 Lecture 11](https://www.youtube.com/watch?v=9MvD-XsowsE){:target="_blank" rel="noopener"}

## 핵심 내용

현대 딥러닝 모델을 큰 데이터와 많은 장비에서 학습시키는 분산 학습의 원리를 다룬다. Data parallelism, model parallelism, gradient synchronization, communication overhead, mixed precision, scaling law 등이 핵심 주제다. 큰 모델을 학습할 때 병목은 연산만이 아니라 메모리와 통신이며, 시스템 설계가 모델 성능과 실험 속도를 좌우한다.

## 학습 포인트

- 분산 학습은 계산, 메모리, 통신을 함께 최적화하는 문제다.
- Data parallelism은 같은 모델을 여러 장비에 복제하고 데이터만 나눠 학습한다.
- 통신 비용과 동기화 방식은 확장 효율을 제한한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Data Parallelism | 여러 장비가 서로 다른 미니배치를 처리하고 gradient를 합치는 방식 |
| Model Parallelism | 모델 자체를 여러 장비에 나누어 배치하는 방식 |
| All-Reduce | 여러 장비의 gradient를 합산하고 공유하는 통신 연산 |
| Mixed Precision | 낮은 정밀도 연산으로 속도와 메모리 효율을 높이는 기법 |

## Study Guide

1. data parallelism과 model parallelism은 어떤 상황에서 각각 유리한가?
2. 분산 학습에서 통신 병목은 왜 발생하는가?
3. mixed precision을 사용할 때 주의할 점은 무엇인가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 11](https://www.youtube.com/watch?v=9MvD-XsowsE){:target="_blank" rel="noopener"}
