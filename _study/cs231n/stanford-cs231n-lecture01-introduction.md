---
layout: default
date: 2026-07-15 22:57:10 +0900
title: "Stanford CS231N Lecture 1: Introduction"
course: "CS231N"
topic: "Foundations of Computer Vision and Deep Learning"
order: 1
major_topic: "Computer Vision"
keywords:
  - "Visual Intelligence"
  - "CNN"
  - "ImageNet"
  - "AlexNet"
  - "Vision Tasks"
---

# Stanford CS231N Lecture 1: Introduction

Source: [Stanford CS231N Deep Learning for Computer Vision, Spring 2025, Lecture 1](https://youtu.be/2fq9wYslV0A?si=YXCKanCTWpZFstJ2){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Computer vision의 위치 | 시각 지능은 AI 안에서 어떤 문제를 다루는가? |
| 2 | 시각의 역사 | 생물학적 시각과 기계 시각은 어떻게 연결되는가? |
| 3 | 초기 연구 | Hubel-Wiesel, Marr, Summer Vision Project는 어떤 관점을 남겼는가? |
| 4 | Neural network와 CNN | 역전파와 합성곱 구조는 왜 중요했는가? |
| 5 | ImageNet과 AlexNet | 현대 딥러닝 전환점은 어떤 조건들이 맞물린 결과였는가? |
| 6 | Vision task의 확장 | 분류 이후 검출, 분할, 비디오, 생성으로 어떻게 넓어지는가? |
| 7 | 사회적 함의 | 편향, 안전, 인간 중심 설계를 왜 함께 고려해야 하는가? |
| 8 | CS231N 수업 구조 | 앞으로 어떤 주제를 순서대로 배우는가? |

## 1. Computer Vision의 위치

CS231N은 인공지능 전체를 다루는 수업이 아니라, 컴퓨터 비전과 딥러닝이 만나는 핵심 영역을 다룬다. 컴퓨터 비전의 목표는 이미지와 비디오의 픽셀을 물체, 장면, 행동, 관계 같은 의미로 바꾸는 것이다.

```text
pixels -> features -> objects/scenes/actions -> decisions
```

이 문제는 자연어 처리, 로보틱스, 의학, 과학, 법, 교육, 비즈니스와도 연결된다. 시각 정보는 현실 세계를 이해하는 중요한 입력이기 때문에, 컴퓨터 비전은 단순한 이미지 처리보다 넓은 시각 지능 문제로 보아야 한다.

## 2. 시각과 지능

강의는 시각을 지능 진화의 중요한 계기로 설명한다. 생물학적 시각은 환경을 더 능동적으로 감지하고 반응하게 만들었고, 인간 역시 시각 의존도가 매우 높은 존재다.

이 관점에서 computer vision은 카메라나 센서를 만드는 일이 아니라, 시각 입력에서 의미를 추론하는 시스템을 만드는 일이다. 물체가 같은 범주에 속하더라도 조명, 시점, 가림, 배경이 달라지면 픽셀은 크게 달라진다. 따라서 컴퓨터 비전의 어려움은 픽셀과 의미 사이의 간극에서 나온다.

## 3. 초기 Computer Vision과 신경과학

Hubel과 Wiesel의 시각 피질 연구는 계층적 시각 처리라는 직관을 제공했다. 낮은 수준에서는 선분, 방향, 가장자리 같은 단순 패턴을 감지하고, 더 높은 수준에서는 복잡한 형태와 의미를 다룬다는 생각이다.

초기 computer vision 연구도 이 영향을 받았다. Larry Roberts의 3D 형상 연구, MIT Summer Vision Project, David Marr의 시각 처리 이론은 이미지에서 구조를 추론하려는 시도였다. 하지만 실제 이미지는 조명, 시점, 가림, 물체 다양성 때문에 사람이 설계한 규칙만으로는 충분히 다루기 어려웠다.

## 4. Neural Network와 CNN

신경망은 생물학적 시각 시스템에서 영감을 받았지만, 실제 성능을 내기 위해서는 학습 방법과 계산 자원이 필요했다. 역전파는 출력 오류를 네트워크 내부 파라미터로 전달해 feature 자체를 학습하게 만든 핵심 방법이다.

CNN은 이미지의 공간 구조를 활용한다. 작은 filter를 이미지 전체에 공유하고, 낮은 layer에서는 edge 같은 지역 패턴을, 높은 layer에서는 물체 부분과 의미적 표현을 학습한다.

| 개념 | 역할 |
|---|---|
| Convolution | 지역 패턴을 공유된 filter로 감지 |
| Weight sharing | 위치마다 별도 파라미터를 두지 않아 효율화 |
| Hierarchy | 낮은 수준 특징에서 높은 수준 의미로 표현 확장 |
| Backpropagation | feature와 classifier를 함께 학습 |

## 5. ImageNet과 AlexNet

현대 딥러닝의 전환은 알고리즘 하나만의 결과가 아니다. 대규모 데이터, GPU 계산 자원, 학습 가능한 신경망 구조, 역전파가 함께 맞물렸다.

ImageNet은 수많은 이미지를 공통 범주와 평가 체계로 묶어 대규모 시각 인식 benchmark를 만들었다. AlexNet은 2012년 ImageNet에서 deep CNN이 기존 방법보다 큰 성능 향상을 낼 수 있음을 보여주었다. 이 사건은 데이터와 계산 자원이 충분할 때 high-capacity model이 시각 문제에서 강력하게 작동한다는 신호가 되었다.

## 6. Classification 이후의 Vision Task

Image classification은 이미지 하나에 label을 붙이는 문제지만, 실제 비전 시스템은 더 구조적인 출력을 요구한다.

| Task | 출력 |
|---|---|
| Classification | 이미지 전체의 범주 |
| Object detection | 물체 범주와 bounding box |
| Semantic segmentation | 픽셀 단위 의미 범주 |
| Instance segmentation | 개별 객체별 mask |
| Video understanding | 시간에 따른 행동과 사건 |
| Vision-language model | 이미지와 텍스트의 연결 |
| Generative vision | 이미지 생성, 편집, 변환 |

이 흐름은 컴퓨터 비전이 단일 label 예측에서 장면 이해, 멀티모달 추론, 생성 모델, 3D vision, embodied agent로 확장되고 있음을 보여준다.

## 7. 사회적 함의

컴퓨터 비전은 의료, 보조 기술, 과학, 안전 분야에서 큰 가치를 만들 수 있다. 동시에 얼굴 인식, 감시, 채용, 대출, 의료 판단처럼 사람의 삶에 영향을 주는 영역에서는 편향과 책임 문제가 발생한다.

데이터는 인간 사회의 산물이기 때문에 데이터에 담긴 편향이 모델에 반영될 수 있다. 따라서 컴퓨터 비전 시스템은 정확도뿐 아니라 robustness, fairness, privacy, accountability를 함께 고려해야 한다.

## 8. CS231N 수업 구조

강의는 앞으로 다음 축을 따라 진행된다.

| 축 | 내용 |
|---|---|
| 딥러닝 기초 | 이미지 분류, 선형 분류기, 최적화, 신경망 학습 |
| 시각 인식 | CNN, detection, segmentation, video understanding |
| 생성과 상호작용 | diffusion, vision-language model, 3D vision, embodied agent |
| 인간 중심 AI | 사회적 영향, 편향, 책임 있는 비전 시스템 |

## 마지막 핵심 정리

- Computer vision은 픽셀을 의미로 바꾸는 시각 지능 문제다.
- CNN은 이미지의 지역성과 계층성을 활용하는 신경망 구조다.
- ImageNet과 AlexNet은 데이터, 계산 자원, 알고리즘이 함께 맞물린 전환점이었다.
- 현대 vision은 분류를 넘어 검출, 분할, 비디오, 생성, 멀티모달 이해로 확장된다.
- 비전 시스템은 성능뿐 아니라 편향, 안전, 사회적 영향까지 함께 평가해야 한다.

## Study Guide

| 질문 | 확인할 개념 |
|---|---|
| 왜 시각을 지능의 핵심 요소로 볼 수 있는가? | 시각 입력과 환경 이해 |
| Hubel-Wiesel 연구는 CNN과 어떻게 연결되는가? | 수용장, 계층적 표현 |
| AlexNet의 성공을 한 가지 이유만으로 설명하면 왜 부족한가? | data, compute, algorithm |
| Classification과 detection은 무엇이 다른가? | label vs location |
| Computer vision의 편향 문제는 왜 공학만의 문제가 아닌가? | 데이터, 사회적 의사결정, 책임 |

## 복습 질문

1. Computer vision에서 픽셀과 의미 사이의 간극은 어떤 예로 설명할 수 있는가?
2. CNN의 weight sharing은 왜 이미지 처리에 적합한가?
3. ImageNet은 단순한 데이터셋을 넘어 어떤 연구 인프라 역할을 했는가?
4. Detection, semantic segmentation, instance segmentation의 출력 차이는 무엇인가?
5. Vision-language model과 generative vision은 기존 classification 문제를 어떻게 확장하는가?

## 참고자료

- [Stanford CS231N Deep Learning for Computer Vision, Spring 2025, Lecture 1](https://youtu.be/2fq9wYslV0A?si=YXCKanCTWpZFstJ2){:target="_blank" rel="noopener"}
