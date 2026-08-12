---
layout: default
title: "Stanford CS231N Lecture 14: Generative Models 2"
course: "CS231N"
topic: "Generative Models 2"
order: 14
---

# Stanford CS231N Lecture 14: Generative Models 2

Source: [Stanford CS231N Spring 2025 Lecture 14](https://www.youtube.com/watch?v=Edr4uZFh4EE){:target="_blank" rel="noopener"}

## 핵심 내용

Diffusion model과 score-based generative modeling을 중심으로 현대 이미지 생성 모델을 설명한다. 모델은 데이터에 점진적으로 노이즈를 추가하는 forward process와, 노이즈를 제거해 샘플을 복원하는 reverse process를 학습한다. 조건부 생성, guidance, latent diffusion은 텍스트-이미지 생성과 고해상도 생성의 실용적 기반이 된다.

## 학습 포인트

- Diffusion model은 노이즈 제거 과정을 학습해 샘플을 생성한다.
- 조건부 생성은 텍스트나 클래스 정보를 이용해 생성 방향을 제어한다.
- Latent diffusion은 픽셀 공간 대신 압축된 잠재 공간에서 효율적으로 생성한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Diffusion Model | 점진적 노이즈 추가와 제거 과정을 이용하는 생성 모델 |
| Denoising | 노이즈가 섞인 입력에서 깨끗한 데이터 방향을 예측하는 작업 |
| Guidance | 조건 정보를 강하게 반영하도록 생성 과정을 조절하는 방법 |
| Latent Diffusion | 잠재 공간에서 diffusion을 수행해 계산 비용을 줄이는 접근 |

## Study Guide

1. diffusion model의 forward process와 reverse process는 무엇인가?
2. guidance는 생성 결과에 어떤 영향을 주는가?
3. latent diffusion이 픽셀 공간 diffusion보다 효율적인 이유는 무엇인가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 14](https://www.youtube.com/watch?v=Edr4uZFh4EE){:target="_blank" rel="noopener"}
