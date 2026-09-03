---
layout: default
date: 2026-07-15 22:57:10 +0900
title: "SqueezeLLM"
topic: "Dense-and-sparse post-training quantization for LLM inference"
order: 44
major_topic: "LLM Quantization & Compression"
keywords:
  - "SqueezeLLM"
  - "dense-sparse quantization"
  - "PTQ"
  - "LLM inference"
---

# SqueezeLLM: Dense-and-Sparse Quantization

Source PDF: `squeezellm-dense-and-sparse-quantization.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | SqueezeLLM: Dense-and-Sparse Quantization |
| 저자 | Sehoon Kim, Coleman Hooper, Amir Gholami, Zhen Dong, Xiuyu Li, Sheng Shen, Michael W. Mahoney, Kurt Keutzer |
| 출처 | ICML 2024 |
| 주제 | LLM PTQ, Non-uniform Quantization, Dense-and-Sparse Decomposition |
| 핵심 방법 | 민감도 기반 비균일 양자화와 outlier/sensitive weight의 sparse 보존 |

## 한 줄 요약

SqueezeLLM은 LLM 생성 추론의 병목이 compute보다 memory bandwidth에 있다는 점에서 출발해, 3-bit 수준의 non-uniform quantization과 dense-and-sparse decomposition으로 모델 크기와 추론 지연을 줄이는 PTQ framework다.

## 핵심 내용

- LLM 생성 추론의 핵심 병목은 memory bandwidth일 수 있다.
- SqueezeLLM은 3-bit 수준에서도 성능 열화를 줄이기 위해 non-uniform quantization을 사용한다.
- Outlier/sensitive weight는 sparse representation으로 별도 보존한다.
- PTQ 품질뿐 아니라 실제 GPU inference speedup을 함께 목표로 한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Memory wall | 왜 LLM single-batch generation은 memory-bound인가? |
| 2 | Non-uniform quantization | weight sensitivity를 반영해 bit allocation을 어떻게 조정하는가? |
| 3 | Dense-and-sparse | outlier와 sensitive weight를 sparse format으로 어떻게 보존하는가? |
| 4 | 실험 결과 | 3-bit quantization에서 perplexity와 speedup은 어떻게 달라지는가? |
| 5 | 다른 PTQ와 비교 | GPTQ/OWQ/QuIP 계열과 어떤 축이 다른가? |

## 1. 문제 배경

LLM 추론, 특히 작은 batch의 autoregressive generation은 연산량보다 parameter를 memory에서 읽는 bandwidth가 병목이 되기 쉽다. 따라서 weight를 낮은 bit로 저장하면 memory footprint뿐 아니라 latency와 throughput에도 직접적인 영향을 줄 수 있다.

기존 quantization은 낮은 bit로 갈수록 성능 열화가 커진다. SqueezeLLM은 모든 weight를 균일하게 낮은 precision으로 표현하기보다, 민감한 weight와 outlier를 별도로 다루는 방식을 택한다.

## 2. 핵심 아이디어

| 구성 | 역할 |
|---|---|
| sensitivity-based non-uniform quantization | second-order information으로 layer/weight sensitivity를 반영 |
| Dense path | 대부분의 weight를 low-bit dense representation으로 저장 |
| Sparse path | outlier와 sensitive weight value를 sparse format으로 보존 |
| deployment focus | memory bandwidth 병목을 줄여 실제 inference speedup을 노림 |

논문은 3-bit 양자화가 FP16 baseline 대비 perplexity gap을 줄이고, A6000 GPU에서 baseline 대비 최대 2.3배 speedup을 보인다고 보고한다.

## EPTQ/OWQ와의 연결

SqueezeLLM은 OWQ처럼 민감한 일부 weight를 별도로 보존한다. 다만 OWQ가 outlier-aware column mixed precision과 WCT에 초점을 둔다면, SqueezeLLM은 dense-and-sparse decomposition과 sensitivity-based non-uniform quantization을 결합한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/squeezellm-dense-and-sparse-quantization/squeezellm-dense-and-sparse-quantization.pdf" | relative_url }}" target="_blank" rel="noopener">squeezellm-dense-and-sparse-quantization.pdf</a></li>
  <li><a href="https://github.com/SqueezeAILab/SqueezeLLM" target="_blank" rel="noopener">SqueezeLLM code</a></li>
  <li><a href="https://arxiv.org/abs/2306.07629" target="_blank" rel="noopener">arXiv:2306.07629</a></li>
</ul>
