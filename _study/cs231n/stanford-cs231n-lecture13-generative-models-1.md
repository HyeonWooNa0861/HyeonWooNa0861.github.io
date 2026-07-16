---
layout: default
title: "Stanford CS231N Lecture 13: Generative Models 1"
course: "CS231N"
topic: "생성 모델 1"
order: 13
---

# Stanford CS231N Lecture 13: Generative Models 1

Source: [Stanford CS231N Spring 2025 Lecture 13](https://www.youtube.com/watch?v=zbHXQRUNlH0){:target="_blank" rel="noopener"}

## 핵심 내용

생성 모델의 목표와 초기 주요 계열을 소개한다. 모델은 데이터 분포를 학습해 새로운 샘플을 생성하거나 확률을 추정한다. Autoregressive model, VAE, GAN은 각각 명시적 순차 확률, 잠재변수 기반 근사 추론, 판별자와 생성자의 게임이라는 서로 다른 관점을 제공한다.

## 학습 포인트

- 생성 모델은 데이터 분포를 학습해 새로운 데이터를 만들거나 확률을 계산한다.
- VAE는 잠재 공간과 재구성 손실, KL 정규화를 결합한다.
- GAN은 생성자와 판별자의 경쟁으로 사실적인 샘플을 만든다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Generative Model | 데이터가 생성되는 분포를 모델링하는 방법 |
| Autoregressive Model | 데이터를 순서대로 조건부 확률의 곱으로 분해하는 모델 |
| VAE | 잠재변수와 변분추론을 사용하는 생성 모델 |
| GAN | 생성자와 판별자의 적대적 학습으로 샘플을 생성하는 모델 |

## Study Guide

1. 생성 모델은 discriminative model과 어떤 목표 차이를 갖는가?
2. VAE의 reconstruction term과 KL term은 각각 어떤 역할을 하는가?
3. GAN 학습이 불안정할 수 있는 이유는 무엇인가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 13](https://www.youtube.com/watch?v=zbHXQRUNlH0){:target="_blank" rel="noopener"}
