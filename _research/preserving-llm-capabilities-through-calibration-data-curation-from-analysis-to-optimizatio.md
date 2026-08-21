---
layout: default
date: 2026-07-15 22:57:10 +0900
title: "CoLA"
topic: "Preserving LLM capabilities through calibration data curation"
order: 41
major_topic: "Machine Learning & Data Curation"
keywords:
  - "calibration data"
  - "LLM quantization"
  - "capability preservation"
  - "CoLA"
---

# Preserving LLM Capabilities through Calibration Data Curation: From Analysis to Optimization

Source PDF: `preserving-llm-capabilities-through-calibration-data-curation-from-analysis-to-optimizatio.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Preserving LLM Capabilities through Calibration Data Curation: From Analysis to Optimization |
| 저자 | Bowei He, Lihao Yin, Huiling Zhen, Shuqi Liu, Han Wu, Xiaokun Zhang, Mingxuan Yuan, Chen Ma |
| 출처 | arXiv:2510.10618v1, NeurIPS 2025 |
| 주제 | LLM Compression, Calibration Data, Capability Preservation |
| 핵심 방법 | activation space의 representativeness/diversity를 기준으로 calibration data를 큐레이션 |

## 한 줄 요약

이 논문은 LLM 압축 이후의 성능 보존이 compression method만이 아니라 calibration data의 구성, 도메인 대응성, activation space 다양성에 크게 좌우된다고 분석하고 calibration data curation framework를 제안한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 calibration data가 압축 후 capability 보존에 영향을 주는가? |
| 2 | 분석 축 | source, sample amount, sequence length, domain은 어떤 차이를 만드는가? |
| 3 | Activation mechanism | activation space의 대표성과 다양성은 왜 중요한가? |
| 4 | Curation framework | 어떤 기준으로 calibration data를 선택하고 최적화하는가? |
| 5 | 평가 | math, code, reasoning capability 보존에 어떤 차이가 나타나는가? |

## 1. 문제 배경

PTQ와 pruning은 작은 calibration set을 사용해 weight importance와 activation dynamic range를 추정한다. 많은 압축 연구는 calibration data를 부수적인 입력처럼 다루지만, 논문은 calibration data의 성격이 압축 후 LLM capability를 크게 좌우한다고 본다.

특히 언어 모델링이나 commonsense reasoning만 보는 것으로는 부족하다. 실제 LLM 배포에서는 math solving, code generation, complex reasoning처럼 높은 수준의 능력을 유지해야 하며, 이 능력들은 calibration set의 domain과 activation pattern에 민감할 수 있다.

## 2. 핵심 관찰

논문은 calibration data 품질을 단순히 source나 sample count로 보지 않고 activation space 관점에서 분석한다.

| 관점 | 의미 |
|---|---|
| representativeness | 압축 후 사용될 task/domain의 activation pattern을 얼마나 대표하는가 |
| diversity | calibration sample들이 activation space의 여러 영역을 얼마나 폭넓게 덮는가 |
| compositional property | reasoning, code, math 같은 구성적 능력에 필요한 패턴을 포함하는가 |
| domain correspondence | target evaluation domain과 calibration domain이 얼마나 맞는가 |

이 관점은 COVERCAL의 outlier-channel coverage와도 연결된다. COVERCAL이 채널 단위 coverage를 강조한다면, 이 논문은 capability 보존 관점에서 calibration data의 activation-space quality를 강조한다.

## 3. 방법과 의미

논문은 분석 결과를 바탕으로 calibration data curation framework를 제안한다. 핵심은 무작위 calibration set을 쓰는 대신, 압축 후 보존해야 할 capability와 activation pattern을 고려해 데이터를 선택하는 것이다.

| 기존 관행 | 논문이 제안하는 관점 |
|---|---|
| C4/WikiText에서 random sample 선택 | target capability와 activation diversity를 고려 |
| sample 수 중심 비교 | sample composition과 domain correspondence까지 비교 |
| perplexity 중심 평가 | math/code/reasoning capability 보존 평가 |

## EPTQ 후속연구 관점

EPTQ, QTIP, QuIP# 같은 PTQ 방법을 비교할 때 동일한 calibration set을 쓰더라도 그 set이 어떤 capability를 보존하는지에 따라 downstream 결과가 달라질 수 있다. 따라서 EPTQ 후속실험에서는 quantizer만 바꾸는 ablation 외에 calibration data source/coverage/domain ablation을 별도 축으로 둘 수 있다.

## 핵심 내용

- Calibration data는 PTQ/pruning의 부수 입력이 아니라 압축 후 capability 보존을 좌우하는 설계 변수다.
- Activation space의 대표성과 다양성이 calibration data 품질의 핵심 메커니즘으로 제시된다.
- Math, code, complex reasoning 같은 고수준 능력은 calibration data 구성에 민감할 수 있다.
- COVERCAL, Self-Calibration과 함께 calibration data selection 연구 축을 형성한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/preserving-llm-capabilities-through-calibration-data-curation-from-analysis-to-optimizatio/preserving-llm-capabilities-through-calibration-data-curation-from-analysis-to-optimizatio.pdf" | relative_url }}" target="_blank" rel="noopener">preserving-llm-capabilities-through-calibration-data-curation-from-analysis-to-optimizatio.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2510.10618" target="_blank" rel="noopener">arXiv:2510.10618</a></li>
</ul>
