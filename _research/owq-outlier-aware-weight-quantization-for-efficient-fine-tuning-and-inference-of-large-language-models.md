---
layout: default
title: "OWQ"
topic: "Outlier-aware weight quantization for efficient LLM tuning and inference"
order: 40
---

# OWQ: Outlier-Aware Weight Quantization for Efficient Fine-Tuning and Inference of Large Language Models

Source PDF: `owq-outlier-aware-weight-quantization-for-efficient-fine-tuning-and-inference-of-large-language-models.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | OWQ: Outlier-Aware Weight Quantization for Efficient Fine-Tuning and Inference of Large Language Models |
| 저자 | Changhun Lee, Jungyu Jin, Taesu Kim, Hyungjun Kim, Eunhyeok Park |
| 출처 | AAAI 2024 |
| 주제 | LLM Weight Quantization, Outlier-Aware Mixed Precision, Efficient Fine-Tuning |
| 핵심 방법 | 민감한 column은 고정밀로 보존하고 나머지 dense weight를 저비트로 양자화하는 OWQ와 Weak Column Tuning |

## 한 줄 요약

OWQ는 activation outlier가 특정 weight column의 양자화 민감도를 키운다는 점에 주목해, 소수의 중요한 column만 고정밀로 보존하고 나머지는 저비트로 저장하는 mixed-precision LLM weight quantization 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 3-bit LLM weight quantization에서 성능 저하가 남는가? |
| 2 | Outlier sensitivity | activation outlier는 어떤 weight column을 민감하게 만드는가? |
| 3 | OWQ | 고정밀 column 보존과 dense quantization을 어떻게 결합하는가? |
| 4 | WCT | quantized model을 task-specific하게 어떻게 미세조정하는가? |
| 5 | 실험 결과 | 3.1-bit OWQ는 4-bit OPTQ와 어떤 관계를 보이는가? |

## 1. 문제 배경

LLM 추론은 weight memory와 bandwidth에 크게 묶인다. GPTQ/OPTQ 같은 PTQ 방법은 3-4 bit weight-only quantization으로 memory footprint를 줄이지만, 3-bit 이하에서는 일부 모델과 작업에서 성능 열화가 남는다. OWQ는 이 열화가 모든 weight에서 균일하게 발생하는 것이 아니라, activation outlier와 연결된 특정 column에 집중된다고 본다.

## 2. 핵심 아이디어

OWQ는 weight column별 양자화 민감도를 평가하고, 민감한 작은 부분집합을 고정밀로 저장한다. 나머지 dense weight는 강하게 최적화된 low-bit quantization을 적용한다.

| 구성 | 역할 |
|---|---|
| outlier-aware sensitivity | activation outlier가 큰 column을 식별 |
| mixed precision | 민감한 column은 FP16 등 고정밀로 보존 |
| dense low-bit path | 대부분의 weight는 낮은 bit로 저장 |
| weak column tuning | 보존 column을 이용한 parameter-efficient task adaptation |

이 구조는 QLoRA처럼 fine-tuning을 가능하게 하면서도, quantized dense matrix 자체의 품질을 더 중요하게 본다.

## 3. 실험 결과와 의미

논문은 OWQ를 사용한 3.1-bit 모델이 OPTQ 기반 4-bit 모델과 비슷한 성능을 보인다고 보고한다. 이는 평균 bit-width를 낮추면서도 outlier-sensitive column을 보존하면 실제 성능 저하를 줄일 수 있음을 보여준다.

| 관점 | 해석 |
|---|---|
| inference | memory footprint를 줄이면서 큰 성능 열화를 피함 |
| fine-tuning | WCT로 task-specific adaptation을 지원 |
| quantization 설계 | 모든 weight를 같은 bit로 다루기보다 구조화된 민감도 차이를 반영 |

## EPTQ/QTIP 계열과의 연결

QTIP, QuIP#, EPTQ가 codebook geometry와 vector quantization을 통해 낮은 bit 표현력을 높인다면, OWQ는 outlier-sensitive column을 고정밀로 남기는 혼합 정밀도 전략이다. 극저비트 LLM PTQ를 볼 때 "어떤 weight를 양자화하지 않을 것인가"라는 preservation 축을 제공한다.

## 핵심 내용

- LLM weight quantization 성능 저하는 activation outlier와 연결된 특정 column에 집중될 수 있다.
- OWQ는 소수의 민감한 structured weight를 고정밀로 저장하고 나머지를 저비트로 양자화한다.
- Weak Column Tuning은 OWQ format 위에서 task-specific fine-tuning을 가능하게 한다.
- 3.1-bit OWQ가 4-bit OPTQ와 비슷한 성능을 보인다는 점이 핵심 실험 메시지다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/owq-outlier-aware-weight-quantization-for-efficient-fine-tuning-and-inference-of-large-language-models/owq-outlier-aware-weight-quantization-for-efficient-fine-tuning-and-inference-of-large-language-models.pdf" | relative_url }}" target="_blank" rel="noopener">owq-outlier-aware-weight-quantization-for-efficient-fine-tuning-and-inference-of-large-language-models.pdf</a></li>
  <li><a href="https://github.com/xvyaward/owq" target="_blank" rel="noopener">OWQ code</a></li>
</ul>
