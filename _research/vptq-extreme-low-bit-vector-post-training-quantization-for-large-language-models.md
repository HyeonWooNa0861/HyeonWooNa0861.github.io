---
layout: default
title: "VPTQ"
topic: "Extreme low-bit vector post-training quantization for LLMs"
order: 45
major_topic: "LLM Quantization & Compression"
keywords:
  - "VPTQ"
  - "vector quantization"
  - "low-bit PTQ"
  - "LLM compression"
---

# VPTQ: Extreme Low-bit Vector Post-Training Quantization for Large Language Models

Source PDF: `vptq-extreme-low-bit-vector-post-training-quantization-for-large-language-models.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | VPTQ: Extreme Low-bit Vector Post-Training Quantization for Large Language Models |
| 저자 | Yifei Liu, Jicheng Wen, Yang Wang, Shengyu Ye, Li Lyna Zhang, Ting Cao, Cheng Li, Mao Yang |
| 출처 | arXiv / Microsoft Research material |
| 주제 | Vector Quantization, 2-bit LLM PTQ, Codebook Initialization |
| 핵심 방법 | second-order optimization 기반 VQ, channel-independent refinement, residual/outlier quantization |

## 한 줄 요약

VPTQ는 LLM weight-only quantization을 vector quantization 문제로 정식화하고, second-order optimization과 codebook initialization을 결합해 2-bit 수준의 정확도와 throughput을 개선하는 PTQ 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 scalar quantization은 2-bit LLM에서 한계가 있는가? |
| 2 | VQ formulation | LLM weight quantization을 어떤 vector optimization 문제로 보는가? |
| 3 | Second-order optimization | Hessian/second-order 정보는 codebook 선택에 어떻게 쓰이는가? |
| 4 | Refinement | channel-independent refinement와 residual/outlier quantization은 무엇을 보완하는가? |
| 5 | 실험 결과 | perplexity, QA accuracy, quantization time, throughput은 어떻게 개선되는가? |

## 1. 문제 배경

2-bit LLM PTQ에서는 scalar quantization의 표현력이 부족해 성능이 급격히 떨어질 수 있다. Vector quantization은 여러 weight를 묶어 codebook index로 표현하므로 같은 bit-width에서 더 큰 표현력을 가질 수 있다. 그러나 codebook search, initialization, inference lookup cost가 실용성을 좌우한다.

## 2. 핵심 아이디어

VPTQ는 VQ를 단순 clustering 문제가 아니라 second-order optimization 문제로 본다.

| 구성 | 역할 |
|---|---|
| Second-Order Optimization | quantization error가 output에 미치는 영향을 반영 |
| Channel-Independent Second-Order Optimization | 더 세밀한 VQ refinement 수행 |
| Codebook initialization | 최적화 문제를 분해해 효과적인 초기 codebook 구성 |
| residual/outlier quantization | 정확도를 높이고 추가 압축을 지원 |

## 3. 실험 결과

논문은 2-bit 조건에서 LLaMA-2, Mistral-7B, LLaMA-3 계열을 평가한다.

| 항목 | 결과 |
|---|---|
| LLaMA-2 perplexity | 기존 SOTA 대비 0.01-0.34 감소 |
| Mistral-7B perplexity | 0.38-0.68 감소 |
| LLaMA-3 perplexity | 4.41-7.34 감소 |
| QA accuracy | 모델군별 평균 0.79-22% 개선 |
| quantization time | 기존 SOTA의 10.4-18.6% 수준 |
| inference throughput | 1.6-1.8배 증가 |

## QTIP/EPTQ와의 연결

VPTQ는 QTIP, QuIP#, EPTQ와 함께 2-bit LLM PTQ에서 scalar quantization을 넘어서는 흐름에 속한다. VPTQ는 VQ formulation과 second-order refinement에 초점을 두고, QTIP은 trellis-coded quantization으로 codebook dimension 문제를 풀며, EPTQ는 FE8 codebook과 cache-friendly lookup을 강조한다.

## 핵심 내용

- VPTQ는 LLM 2-bit quantization을 vector post-training quantization 문제로 본다.
- Second-order optimization으로 codebook 선택과 refinement를 설계한다.
- Residual/outlier quantization을 통해 정확도와 압축률을 함께 개선한다.
- EPTQ/QTIP과 비교할 때 VQ 기반 극저비트 PTQ의 중요한 baseline이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/vptq-extreme-low-bit-vector-post-training-quantization-for-large-language-models/vptq-extreme-low-bit-vector-post-training-quantization-for-large-language-models.pdf" | relative_url }}" target="_blank" rel="noopener">vptq-extreme-low-bit-vector-post-training-quantization-for-large-language-models.pdf</a></li>
  <li><a href="https://github.com/microsoft/VPTQ" target="_blank" rel="noopener">VPTQ code</a></li>
</ul>
