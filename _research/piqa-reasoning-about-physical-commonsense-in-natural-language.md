---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "PIQA"
topic: "Physical commonsense reasoning benchmark in natural language"
order: 34
major_topic: "Language Models & NLP"
keywords:
  - "PIQA"
  - "physical commonsense"
  - "natural language reasoning"
  - "benchmark"
---

# PIQA

Source PDF: `piqa-reasoning-about-physical-commonsense-in-natural-language.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | PIQA: Reasoning about Physical Commonsense in Natural Language |
| 핵심 주제 | 자연어 모델의 물리적 상식 추론 평가 |
| 데이터셋 | Physical Interaction: Question Answering |
| 과제 | 목표와 두 해결책이 주어졌을 때 더 타당한 해결책 선택 |

## 한 줄 요약

PIQA는 텍스트만 많이 읽은 언어 모델이 물체의 형태, 재료, 사용 가능성, 조작 결과 같은 물리적 상식을 얼마나 이해하는지 평가하기 위한 이지선다형 벤치마크이다.

## 핵심 내용

- PIQA는 목표와 두 해결책 중 더 물리적으로 타당한 해결책을 고르는 benchmark이다.
- 데이터는 Instructables 기반으로 만들어져 일상 물체, 재료, 조작, 결과를 중심으로 구성된다.
- AFLite로 쉬운 annotation artifact를 줄여 표면 단서에 의존하기 어렵게 만들었다.
- 당시 강한 Transformer 모델도 인간 성능과 차이가 있었고, 특히 관계어와 넓은 affordance를 가진 물체에서 약했다.
- 논문의 메시지는 물리적 상식이 단순 텍스트 패턴만으로 충분히 학습되기 어렵다는 것이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 물리적 상식 | 왜 텍스트 사전학습만으로 부족할 수 있는가? |
| 2 | 데이터 수집 | 목표-해결책 쌍을 어떻게 만들었는가? |
| 3 | 편향 제거 | annotation artifact를 어떻게 줄였는가? |
| 4 | 모델 평가 | GPT, BERT, RoBERTa는 어디서 실패하는가? |
| 5 | 오류 분석 | 어떤 물리 개념이 특히 어려운가? |

## 1. 문제 배경

대규모 사전학습 언어 모델은 백과사전형 질의응답이나 추상적 언어 과제에서 좋은 성능을 보였지만, 물리 세계에 대한 상식은 텍스트에 충분히 드러나지 않는다. 사람은 병을 눌렀다가 놓으면 흡입력이 생긴다는 것을 경험적으로 알지만, 이런 지식은 말뭉치에서 명시적으로 반복되지 않을 수 있다.

PIQA는 이 간극을 평가한다. 목표가 자연어로 주어지고, 두 해결책 중 물리적으로 더 타당한 것을 고르는 방식이다.

## 2. PIQA 과제 형식

각 예시는 하나의 goal과 두 개의 solution으로 구성된다. 두 solution은 구문과 주제가 비슷하지만, 실제 물리적 결과는 다르도록 설계된다.

예를 들어 어떤 물체를 찾기 위해 진공청소기를 사용할 때, 끝을 막아버리는 방법과 헤어넷을 씌워 빨려 들어가지 않게 하는 방법은 표면적으로 비슷해 보일 수 있다. 그러나 물체를 회수한다는 goal에는 후자가 더 타당하다.

이런 형식은 단순한 단어 빈도나 문체 단서보다, 물체의 속성과 조작 결과를 이해해야 풀 수 있도록 만든다.

## 3. 데이터 수집 방식

논문은 instructables.com의 일상 제작, 요리, 수리 지침을 출발점으로 사용한다. 주석 작성자는 특정 목표와 이를 달성하는 해결책을 만들고, 그 해결책을 미묘하게 틀리게 만드는 대안을 함께 작성한다.

이 방식은 두 가지 장점이 있다. 첫째, 목표가 실제 물체와 조작을 포함하므로 물리적 상식이 자연스럽게 요구된다. 둘째, 정답과 오답이 같은 주제 영역에 머물기 때문에 단순한 topic matching으로 풀기 어렵다.

## 4. 데이터셋 통계와 편향 제거

PIQA는 16,000개 이상의 학습 예시와 별도의 개발 및 테스트 예시를 포함한다. 목표는 짧고, 두 해결책은 평균 길이가 거의 같도록 구성된다. 또한 올바른 해결책과 잘못된 해결책의 어휘가 많이 겹치도록 만들어 표면 단서를 줄였다.

논문은 AFLite를 사용해 annotation artifact를 추가로 제거한다. AFLite는 사전 계산된 표현으로 label이 쉽게 예측되는 예시를 걸러내어, 모델이 편향된 문체 단서가 아니라 실제 물리적 판단을 하도록 과제를 어렵게 만든다.

## 5. 모델 평가와 결과

논문은 GPT, BERT-Large, RoBERTa-Large를 PIQA에 맞게 fine-tuning해 평가한다. 사람에게는 쉬운 과제이지만, 당시 대규모 사전학습 모델은 인간 수준과 큰 차이를 보인다. 논문은 사람 정확도를 약 95%, 강한 사전학습 모델의 성능을 약 77% 수준으로 보고한다.

핵심은 모델이 완전히 무능하다는 주장이 아니다. 모델은 전형적이고 자주 등장하는 물체-행동 관계에서는 잘 맞출 수 있다. 하지만 위/아래, 전/후, 물의 다양한 사용 가능성처럼 유연한 물리 관계에서는 성능이 크게 흔들린다.

## 6. 오류 분석

RoBERTa는 단일 단어만 바뀐 예시에서 특히 흥미로운 실패를 보인다. "before"와 "after", "top"과 "bottom"처럼 관계를 바꾸는 단어는 실제 물리 결과를 크게 바꾸지만, 모델은 이런 차이를 안정적으로 추론하지 못한다.

또한 "spoon"처럼 affordance가 비교적 좁은 물체는 잘 다루지만, "water"처럼 쓰임이 넓고 문맥에 따라 역할이 바뀌는 개념에서는 성능이 낮아진다. 이는 언어 모델이 단어의 평균적 쓰임은 배울 수 있어도, 물리적 상황을 시뮬레이션하는 능력은 제한적일 수 있음을 보여준다.

## 해석 포인트

PIQA는 "언어 모델이 상식을 아는가"를 넓게 묻기보다, 물리적 상호작용이라는 비교적 구체적인 영역으로 좁혀 묻는다. 이 때문에 실패 분석이 더 선명하다. 모델이 틀리는 지점은 사실 지식의 양보다, 물체와 행동의 결과를 상황 속에서 연결하는 능력에 가깝다.

## 한계와 향후 과제

PIQA는 자연어만으로 물리적 상식을 평가하므로, 실제 시각/로봇 상호작용에서 필요한 연속적 물리 추론 전체를 포함하지는 않는다. 또한 Instructables 기반 데이터는 일상 제작과 조작 상황에 강하게 치우칠 수 있다. 향후에는 시각, 로봇 경험, 시뮬레이션과 결합한 평가가 중요하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/piqa-reasoning-about-physical-commonsense-in-natural-language/piqa-reasoning-about-physical-commonsense-in-natural-language.pdf" | relative_url }}" target="_blank" rel="noopener">PIQA: Reasoning about Physical Commonsense in Natural Language PDF</a></li>
</ul>
