---
layout: default
title: "Stanford CS231N Lecture 8: Attention and Transformers"
course: "CS231N"
topic: "Attention and Transformers"
order: 8
---

# Stanford CS231N Lecture 8: Attention and Transformers

Source: [Stanford CS231N Spring 2025 Lecture 8](https://www.youtube.com/watch?v=RQowiOF_FvQ){:target="_blank" rel="noopener"}

## 핵심 내용

RNN의 순차 처리 한계를 넘어 attention을 통해 입력 위치 간의 관계를 직접 계산하는 방식을 설명한다. Self-attention은 각 토큰이나 패치가 다른 모든 위치를 참조해 표현을 갱신하도록 한다. Transformer는 병렬 처리와 긴 의존성 모델링에 강하며, vision transformer와 멀티모달 모델의 기반이 된다.

## 학습 포인트

- Attention은 필요한 위치에 가중치를 두어 정보를 선택적으로 결합한다.
- Self-attention은 입력 내부의 모든 위치 간 상호작용을 모델링한다.
- Transformer는 비전과 언어를 연결하는 현대 모델의 핵심 구조다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Attention | query, key, value를 이용해 관련 위치의 정보를 가중합하는 메커니즘 |
| Self-Attention | 같은 입력 안의 위치들이 서로를 참조하는 attention |
| Transformer | attention과 feedforward block을 쌓은 시퀀스 모델 구조 |
| Vision Transformer | 이미지를 patch sequence로 보고 Transformer를 적용하는 모델 |

## Study Guide

1. Attention은 RNN의 어떤 한계를 완화하는가?
2. query, key, value는 각각 어떤 역할을 하는가?
3. 이미지를 Transformer에 넣으려면 어떤 표현 변환이 필요한가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 8](https://www.youtube.com/watch?v=RQowiOF_FvQ){:target="_blank" rel="noopener"}
