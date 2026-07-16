---
layout: default
title: "Stanford CS231N Lecture 15: 3D Vision"
course: "CS231N"
topic: "3D 비전"
order: 15
---

# Stanford CS231N Lecture 15: 3D Vision

Source: [Stanford CS231N Spring 2025 Lecture 15](https://www.youtube.com/watch?v=7lxrKDKtykM){:target="_blank" rel="noopener"}

## 핵심 내용

2D 이미지에서 3차원 구조를 이해하는 문제를 다룬다. Depth, camera geometry, stereo, point cloud, mesh, implicit representation, NeRF 같은 표현은 3D 장면을 모델링하는 서로 다른 방식이다. 3D 비전은 자율주행, 로보틱스, AR/VR, 장면 재구성에서 핵심적인 역할을 한다.

## 학습 포인트

- 3D 비전은 이미지 뒤의 기하 구조와 카메라 관계를 추론한다.
- depth, point cloud, mesh, implicit field는 3D를 표현하는 다른 방식이다.
- NeRF 계열 방법은 여러 시점 이미지에서 연속적인 장면 표현을 학습한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Depth Estimation | 각 픽셀의 카메라로부터의 거리를 추정하는 작업 |
| Point Cloud | 3D 공간의 점 집합으로 물체나 장면을 표현하는 방식 |
| Mesh | 정점과 면으로 표면 구조를 표현하는 방식 |
| NeRF | 시점과 위치에 따른 색과 밀도를 학습해 새로운 시점을 렌더링하는 방법 |

## Study Guide

1. 2D 이미지 하나에서 3D 구조를 추론하기 어려운 이유는 무엇인가?
2. point cloud와 mesh 표현은 어떤 장단점이 있는가?
3. NeRF는 여러 시점 정보를 어떻게 활용하는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 15](https://www.youtube.com/watch?v=7lxrKDKtykM){:target="_blank" rel="noopener"}
