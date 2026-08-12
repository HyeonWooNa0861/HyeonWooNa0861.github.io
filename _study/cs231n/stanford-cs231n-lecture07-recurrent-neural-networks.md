---
layout: default
title: "Stanford CS231N Lecture 7: Recurrent Neural Networks"
course: "CS231N"
topic: "Recurrent Neural Networks"
order: 7
---

# Stanford CS231N Lecture 7: Recurrent Neural Networks

Source: [Stanford CS231N Spring 2025 Lecture 7](https://www.youtube.com/watch?v=kG2lAPBF7zA){:target="_blank" rel="noopener"}

## 핵심 내용

시퀀스 데이터를 처리하는 RNN, LSTM, GRU의 기본 원리를 다룬다. 이미지 캡셔닝, 비디오, 언어처럼 길이가 가변적인 입력과 출력을 처리하려면 이전 상태를 기억하는 구조가 필요하다. vanilla RNN의 기울기 소실과 폭주 문제는 LSTM의 gate 구조가 등장한 배경으로 설명된다.

## 학습 포인트

- RNN은 시간에 따라 반복되는 동일한 함수를 사용해 상태를 업데이트한다.
- LSTM과 GRU는 장기 의존성을 더 안정적으로 보존하기 위해 gate를 사용한다.
- 시퀀스 모델은 vision-language와 video understanding의 기반이 된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| RNN | 이전 hidden state와 현재 입력으로 다음 상태를 계산하는 순환 구조 |
| LSTM | input, forget, output gate로 장기 기억을 제어하는 RNN 변형 |
| GRU | LSTM보다 단순한 gate 구조를 가진 순환 모델 |
| Sequence Modeling | 길이가 변하는 입력이나 출력을 다루는 모델링 방식 |

## Study Guide

1. RNN이 feedforward network와 다른 점은 무엇인가?
2. vanilla RNN에서 장기 의존성 학습이 어려운 이유는 무엇인가?
3. LSTM의 gate는 어떤 정보를 보존하거나 지우는가?

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 7](https://www.youtube.com/watch?v=kG2lAPBF7zA){:target="_blank" rel="noopener"}
