---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 16: Vision and Language"
course: "CS231N"
topic: "Vision-Language Models"
order: 16
major_topic: "Computer Vision"
keywords:
  - "Vision-Language"
  - "CLIP"
  - "Image Captioning"
  - "Visual Question Answering"
  - "Multimodal Models"
---

# Stanford CS231N Lecture 16: Vision and Language

Source: [Stanford CS231N Spring 2025 Lecture 16](https://www.youtube.com/watch?v=mQOK0Mfyrkk){:target="_blank" rel="noopener"}

## 핵심 내용

이미지와 텍스트를 함께 다루는 멀티모달 학습을 설명한다. Image captioning, visual question answering, contrastive image-text pretraining, CLIP류 모델, multimodal transformer가 핵심 흐름이다. 비전-언어 모델은 시각 내용을 언어로 설명하고, 언어 지시를 시각 추론이나 생성에 연결하는 기반이 된다.

## 학습 포인트

- 비전-언어 모델은 이미지 표현과 텍스트 표현을 같은 의미 공간에서 연결한다.
- Contrastive image-text pretraining은 대응되는 이미지-텍스트 쌍을 가깝게 만든다.
- 멀티모달 모델은 captioning, VQA, retrieval, grounding에 활용된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Image Captioning | 이미지 내용을 자연어 문장으로 생성하는 작업 |
| VQA | 이미지를 보고 자연어 질문에 답하는 작업 |
| CLIP | 이미지와 텍스트를 contrastive objective로 정렬한 모델 계열 |
| Grounding | 언어 표현을 이미지 속 위치나 객체와 연결하는 작업 |

## Study Guide

1. 이미지와 텍스트 표현을 정렬한다는 것은 무슨 뜻인가?
2. captioning과 VQA는 어떤 출력 차이를 갖는가?
3. CLIP류 모델이 zero-shot 분류에 쓰일 수 있는 이유는 무엇인가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 16](https://www.youtube.com/watch?v=mQOK0Mfyrkk){:target="_blank" rel="noopener"}
