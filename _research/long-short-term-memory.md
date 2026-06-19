---
layout: default
title: "Long Short-Term Memory"
topic: "Original LSTM architecture for long time lag learning"
order: 21
---

# Long Short-Term Memory

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Long Short-Term Memory |
| 저자 | Sepp Hochreiter, Jurgen Schmidhuber |
| 출처 | Neural Computation, 1997 |
| 주제 | Recurrent Neural Networks, Long-Term Dependency, Constant Error Carousel |
| 핵심 방법 | LSTM memory cell and gates |

## 한 줄 요약

LSTM은 recurrent backpropagation에서 장기 의존성을 학습하기 어려운 vanishing gradient 문제를 해결하기 위해, constant error flow를 유지하는 memory cell과 gate 구조를 제안한 고전 논문이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | RNN은 왜 긴 시간 간격의 정보를 저장하고 학습하기 어려운가? |
| 2 | 핵심 구조 | Constant Error Carousel은 gradient decay를 어떻게 줄이는가? |
| 3 | Gate | Input/output gate는 memory 접근을 어떻게 제어하는가? |
| 4 | 결과 | 기존 recurrent algorithm보다 긴 time lag task를 더 잘 해결하는가? |

## 1. 문제 배경

기본 RNN은 feedback connection을 통해 과거 정보를 저장할 수 있지만, recurrent backpropagation에서는 error signal이 시간축을 따라 사라지거나 폭주할 수 있다. 특히 긴 time lag를 건너 정보를 유지해야 하는 task에서 학습이 매우 느려지거나 실패한다.

## 2. 제안 방법

LSTM은 memory cell 내부에서 error가 일정하게 흐르도록 constant error carousel을 도입한다. Gate unit은 memory에 언제 쓰고 언제 읽을지 학습한다.

| 구성 | 역할 |
|---|---|
| Memory cell | 장기 정보를 저장 |
| Constant error carousel | gradient가 시간축에서 사라지는 것을 완화 |
| Input gate | 새 정보를 cell에 쓸지 제어 |
| Output gate | cell state를 출력으로 노출할지 제어 |

초기 LSTM은 이후 버전과 달리 forget gate가 기본 구성에 포함되지 않는다. Forget gate는 후속 연구에서 추가되어 더 널리 쓰이는 modern LSTM 구조가 된다.

## 3. 결과 및 해석

논문은 artificial long time lag task에서 LSTM이 기존 RTRL, BPTT, Elman network보다 더 성공적으로 학습한다고 보고한다. 핵심은 gradient path를 짧게 만드는 것이 아니라, 필요한 error flow를 cell 내부에서 보존하는 것이다.

## 4. 연구 맥락

MEC offloading에서 LSTM은 task arrival, edge load, queue length처럼 시간적 의존성이 있는 state를 기억하기 위해 사용된다. 원 논문은 LSTM이 왜 장기 상태 추적에 적합한지 이론적 출발점을 제공한다.

## 한국어 번역형 해설

이 논문은 RNN이 원칙적으로 과거 정보를 저장할 수 있지만 실제 학습에서는 긴 시간 간격을 다루기 어렵다는 문제에서 시작한다. Gradient가 반복적으로 곱해지며 작아지면 과거 정보가 현재 loss에 거의 영향을 주지 못하고, 모델은 long-term dependency를 학습하지 못한다.

LSTM은 memory cell과 gate를 통해 이 문제를 완화한다. Memory cell은 정보를 오래 보존하고, gate는 언제 정보를 저장하고 출력할지 결정한다. Constant error carousel은 gradient가 장기간 유지될 수 있는 경로를 제공한다.

오늘날의 LSTM은 forget gate가 포함된 형태로 많이 쓰이지만, 원 논문의 핵심은 장기 기억을 위한 별도 memory path와 gate-based access control이다. QECO에서 LSTM을 사용하는 이유도 edge load와 task sequence의 시간적 패턴을 기억하기 위해서다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/long-short-term-memory/long-short-term-memory.pdf" | relative_url }}" target="_blank" rel="noopener">Long Short-Term Memory PDF</a></li>
</ul>
