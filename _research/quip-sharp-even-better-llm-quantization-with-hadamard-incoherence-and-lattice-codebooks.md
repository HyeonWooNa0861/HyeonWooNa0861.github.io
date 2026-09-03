---
layout: default
date: 2026-07-15 22:57:10 +0900
title: "QuIP#"
topic: "Hadamard incoherence and E8 lattice codebooks for LLM quantization"
order: 42
major_topic: "LLM Quantization & Compression"
keywords:
  - "QuIP#"
  - "Hadamard incoherence"
  - "E8 lattice codebooks"
  - "LLM quantization"
---

# QuIP#: Even Better LLM Quantization with Hadamard Incoherence and Lattice Codebooks

Source PDF: `quip-sharp-even-better-llm-quantization-with-hadamard-incoherence-and-lattice-codebooks.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | QuIP#: Even Better LLM Quantization with Hadamard Incoherence and Lattice Codebooks |
| 저자 | Albert Tseng, Jerry Chee, Qingyao Sun, Volodymyr Kuleshov, Christopher De Sa |
| 출처 | ICML 2024 |
| 주제 | LLM PTQ, Hadamard Incoherence, E8 Lattice Codebooks, Vector Quantization |
| 핵심 방법 | randomized Hadamard transform, E8 lattice codebook, inter-layer fine-tuning을 결합한 weight-only PTQ |

## 한 줄 요약

QuIP#은 QuIP의 incoherence processing을 randomized Hadamard transform으로 개선하고, E8 lattice 기반 codebook과 fine-tuning을 결합해 극저비트 LLM PTQ 품질을 높인 방법이다.

## 핵심 내용

- QuIP#은 극저비트 LLM PTQ에서 QuIP보다 강한 incoherence/codebook 설계를 제안한다.
- E8 lattice는 8D sphere packing 성질 때문에 low-bit vector quantization에 적합하다.
- Randomized Hadamard transform은 빠르고 이론적으로 좋은 incoherence 처리를 제공한다.
- EPTQ의 FE8 관점과 비교하면, QuIP#은 품질 중심 E8 codebook 흐름의 중요한 선행 자료다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 2-4 bit LLM PTQ에서 품질과 decoding efficiency를 동시에 얻기 어려운가? |
| 2 | Hadamard incoherence | randomized Hadamard transform은 QuIP보다 무엇을 개선하는가? |
| 3 | E8 codebook | 8D lattice codebook은 왜 low-bit vector quantization에 적합한가? |
| 4 | Fine-tuning | PTQ 후 fidelity를 어떻게 더 높이는가? |
| 5 | 실험 결과 | QuIP#, QTIP, EPTQ로 이어지는 흐름에서 어떤 위치를 갖는가? |

## 1. 문제 배경

LLM autoregressive decoding은 memory-bound인 경우가 많기 때문에 weight-only PTQ는 큰 효용을 갖는다. 그러나 2-bit 수준에서는 scalar quantization이 충분하지 않고, vector quantization은 codebook lookup과 decoding cost가 문제가 된다. QuIP#은 이 문제를 incoherence processing과 lattice codebook 조합으로 접근한다.

## 2. 핵심 아이디어

QuIP#은 세 요소를 결합한다.

| 구성 | 역할 |
|---|---|
| Randomized Hadamard Transform | weight와 Hessian의 좌표축 정렬을 깨고 더 Gaussian-like한 분포를 만든다. |
| E8 lattice codebook | 8D sphere packing 성질을 활용해 낮은 bit에서 좋은 vector quantization 품질을 얻는다. |
| fine-tuning | 양자화 후 원 모델에 대한 fidelity를 추가로 개선한다. |

이 구성은 QuIP의 이론적 방향을 유지하면서도 더 빠른 incoherence processing과 더 강한 codebook geometry를 도입한다.

## EPTQ/QTIP과의 연결

QuIP#은 EPTQ와 직접 연결되는 중요한 선행 흐름이다. EPTQ의 Factored-E8 아이디어는 E8 lattice codebook을 deployment-friendly하게 줄이는 문제와 맞닿아 있고, QTIP은 VQ codebook lookup 대신 trellis-coded quantization으로 높은 effective dimension을 달성하려 한다.

| 방법 | 핵심 차이 |
|---|---|
| QuIP | incoherence processing + LDLQ adaptive rounding |
| QuIP# | Hadamard incoherence + E8 lattice codebook + fine-tuning |
| QTIP | trellis-coded quantization으로 high-dimensional quantization을 효율화 |
| EPTQ | E8/FE8 codebook과 cache-friendly lookup을 결합 |

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/quip-sharp-even-better-llm-quantization-with-hadamard-incoherence-and-lattice-codebooks/quip-sharp-even-better-llm-quantization-with-hadamard-incoherence-and-lattice-codebooks.pdf" | relative_url }}" target="_blank" rel="noopener">quip-sharp-even-better-llm-quantization-with-hadamard-incoherence-and-lattice-codebooks.pdf</a></li>
  <li><a href="https://github.com/Cornell-RelaxML/quip-sharp" target="_blank" rel="noopener">QuIP# code</a></li>
</ul>
