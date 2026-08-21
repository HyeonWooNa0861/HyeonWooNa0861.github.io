---
layout: default
date: 2026-07-09 19:59:33 +0900
title: "YAQA"
topic: "Model-preserving adaptive rounding for LLM post-training quantization"
order: 36
major_topic: "LLM Quantization & Compression"
keywords:
  - "YAQA"
  - "adaptive rounding"
  - "KL divergence"
  - "LLM PTQ"
  - "model preservation"
---

# YAQA

Source PDF: `model-preserving-adaptive-rounding.pdf`

Source URL: `https://www.together.ai/blog/yaqa`

## 자료 정보

| 항목 | 내용 |
|---|---|
| 원문 | Model-Preserving Adaptive Rounding with YAQA |
| 출처 | Together AI Research Blog |
| 공개일 | 2025-06-05 |
| 저자 | Albert Tseng, Zhaofeng Sun, Chris De Sa |
| 연결 축 | EPTQ 후속 연구의 평가 지표 확장 |

## 한 줄 요약

YAQA는 LLM PTQ를 layer별 activation error 최소화 문제가 아니라, 양자화 모델이 원 모델의 출력 분포를 얼마나 보존하는지의 문제로 재정의하고 KL divergence를 직접 줄이려는 adaptive rounding 관점을 제시한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | PTQ 목표 재정의 | 작은 모델을 만드는 것만으로 충분한가? |
| 2 | 기존 proxy 비판 | layerwise activation error가 원 모델 출력 보존을 보장하는가? |
| 3 | KL 기반 Hessian | 원 모델 출력 KL을 어떻게 양자화 목적함수로 연결하는가? |
| 4 | YAQA rounding | QuIP/LDLQ보다 무엇을 확장하는가? |
| 5 | EPTQ 연결 | EPTQ 후속연구에서 어떤 평가축을 추가할 수 있는가? |

## 1. PTQ 목표의 차이

Together AI 글은 YAQA를 weight-only LLM post-training quantization 방법으로 소개한다. 핵심 표현은 "원 모델의 출력을 직접 보존"하는 양자화이다. 이 관점에서는 PTQ의 목적이 단순히 weight를 낮은 bit로 표현하는 것이 아니라, 원 모델 \(M(\theta^{*}, X)\)와 양자화 모델 \(M(\theta, X)\)의 출력 분포 차이를 줄이는 것이다.

이를 KL divergence 목적함수로 쓰면 다음과 같은 형태가 된다.

$$
\hat{\theta}
\gets
\underset{\theta\in C}{\arg\min}
\mathbb{E}_{X\sim\mathcal{D}}
D_{\mathrm{KL}}\left(M(\theta^{*},X)\|M(\theta,X)\right)
$$

여기서 \(C\)는 표현 가능한 low-precision point 집합이다. 실제로 이 최적화는 직접 풀기 어렵기 때문에 YAQA는 tractable한 근사를 설계한다.

## 2. 기존 layerwise proxy 비판

YAQA 글은 LDLQ, GPTQ, AWQ 같은 기존 알고리즘이 보통 각 linear layer의 immediate activation error를 독립적으로 줄이는 proxy를 사용한다고 설명한다.

$$
\underset{W\in C}{\arg\min}
\mathbb{E}_{x\sim\mathcal{D}}
\left\|x(W^{*}-W)^{T}\right\|_{F}^{2}
$$

이 proxy는 실무에서 잘 작동하지만, 해당 layer 뒤쪽의 layer들이 양자화 오차를 어떻게 증폭하거나 상쇄하는지는 직접 고려하지 않는다. 따라서 layerwise activation error가 작아졌다고 해서 원 모델 출력과의 KL divergence가 반드시 줄어든다고 보장하기 어렵다.

이 지점이 EPTQ 후속연구에 중요한 비판 축이 된다. EPTQ의 Hessian-aware compensation과 adaptive critical preservation이 downstream accuracy와 perplexity를 개선하더라도, 원 모델의 출력 분포를 얼마나 보존했는지는 별도 metric으로 확인할 필요가 있다.

## 3. KL 기반 Hessian 근사

YAQA는 KL minimization 문제를 linear layer \(W\) 주변에서 second-order expansion으로 근사한다. 이때 Hessian은 원 모델 출력에 대한 KL divergence의 Hessian이다.

글은 KL의 Hessian이 Fisher Information Matrix와 연결되며, Hessian-vector product를 통해 큰 LLM에서도 근사 계산이 가능하다고 설명한다. 전체 Hessian \(H\in\mathbb{R}^{mn\times mn}\)을 직접 만들면 너무 크므로, YAQA는 Kronecker-factored approximation을 사용한다.

$$
H\approx H_{O}\otimes H_{I}
$$

이 근사는 output dimension과 input dimension 양쪽의 curvature를 분리해 다룰 수 있게 한다.

## 4. YAQA와 QuIP/LDLQ의 관계

YAQA의 adaptive rounding은 QuIP의 LDLQ를 자연스럽게 확장한 형태로 설명된다. QuIP/LDLQ는 input dimension 쪽 feedback을 사용하지만, YAQA는 output dimension 쪽 feedback도 함께 사용한다.

Together AI 글은 LDLQ가 YAQA rounding의 특수한 경우이며, 이론적으로 YAQA보다 약한 형태라고 설명한다. 또한 LDLQ는 \(H_I\gets\mathbb{E}[x^{T}x]\), \(H_O\gets I\)로 둔 YAQA로 볼 수 있다고 정리한다.

이 관계는 YAQA를 QuIP/QTIP/EPTQ 계열과 분리된 주제가 아니라, 기존 Hessian-aware PTQ를 원 모델 출력 보존 관점으로 확장하는 흐름으로 읽게 만든다.

## 5. 실험 결과가 주는 메시지

원문은 YAQA가 다양한 모델과 quantizer에서 원 모델과의 KL divergence를 기존 rounding 알고리즘보다 30% 이상 줄였고, downstream task에서도 state-of-the-art 성능을 얻었다고 요약한다. 또한 YAQA는 quantizer-agnostic하므로 hardware-accelerated datatype과 QTIP 같은 memory-bound quantizer 모두에 적용 가능한 관점으로 제시된다.

중요한 점은 "성능이 좋다"보다 "무엇을 성능으로 볼 것인가"이다. YAQA는 downstream accuracy나 perplexity만으로 PTQ를 평가하면 원 모델 보존 여부를 놓칠 수 있음을 보여준다.

## EPTQ 후속연구에 주는 시사점

EPTQ는 FE8 lattice, weight scale normalization, adaptive critical weight preservation, Hessian-aware compensation을 결합해 2-bit PTQ의 정확도와 throughput을 개선한다. 후속연구에서는 다음 질문을 추가할 수 있다.

| 질문 | YAQA가 주는 근거 |
|---|---|
| Layerwise activation error 최소화만으로 충분한가? | YAQA는 이 proxy가 후속 layer와 원 모델 출력 KL을 직접 보존하지 않는다고 지적한다. |
| Critical vector preservation은 원 모델 출력 보존에도 중요한가? | 보존 mask가 downstream accuracy뿐 아니라 output KL에도 영향을 주는지 측정할 수 있다. |
| E8/FE8 variant의 차이는 KL에서도 같은 방향인가? | throughput 중심 FE8과 accuracy 중심 E8을 original-output KL 관점으로 재비교할 수 있다. |
| 추가 metric은 무엇인가? | Quantized model과 original model 사이의 KL divergence를 넣는 것이 자연스럽다. |

## 핵심 내용

- YAQA는 PTQ의 목표를 "layer별 activation error 감소"가 아니라 "원 모델 출력 분포 보존"으로 둔다.
- 기존 GPTQ/AWQ/LDLQ류 proxy는 각 layer를 독립적으로 다루므로, end-to-end KL 감소를 직접 보장하지 않는다.
- YAQA는 KL Hessian을 Kronecker factor로 근사하고, input/output dimension 양쪽 feedback을 사용하는 adaptive rounding을 제안한다.
- LDLQ는 YAQA rounding의 특수한 경우로 해석된다.
- EPTQ 후속연구에서는 downstream accuracy, perplexity, throughput 외에 original-output KL divergence를 추가 metric으로 넣을 근거가 된다.

## 해석 포인트

YAQA는 EPTQ의 경쟁 방법이라기보다 평가 철학을 바꾸는 자료로 읽는 것이 유용하다. EPTQ가 2-bit deployment를 위해 codebook geometry와 cache behavior를 설계했다면, YAQA는 "그 양자화 모델이 원 모델과 같은 모델인가"라는 보존성 질문을 던진다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/model-preserving-adaptive-rounding/model-preserving-adaptive-rounding.pdf" | relative_url }}" target="_blank" rel="noopener">model-preserving-adaptive-rounding.pdf</a></li>
  <li><a href="https://www.together.ai/blog/yaqa" target="_blank" rel="noopener">Together AI Blog: Model-Preserving Adaptive Rounding with YAQA</a></li>
  <li><a href="https://arxiv.org/abs/2505.22988" target="_blank" rel="noopener">Model-Preserving Adaptive Rounding paper</a></li>
</ul>
