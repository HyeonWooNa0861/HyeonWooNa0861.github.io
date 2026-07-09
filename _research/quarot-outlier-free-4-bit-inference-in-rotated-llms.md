---
layout: default
title: "QuaRot"
topic: "Outlier-free 4-bit inference in rotated LLMs"
order: 29
---

# QuaRot: Outlier-Free 4-Bit Inference in Rotated LLMs

Source PDF: `quarot-outlier-free-4-bit-inference-in-rotated-llms.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | QuaRot: Outlier-Free 4-Bit Inference in Rotated LLMs |
| 저자 | Saleh Ashkboos, Amirkeivan Mohtashami, Maximilian L. Croci, Bo Li, Pashmina Cameron, Martin Jaggi, Dan Alistarh, Torsten Hoefler, James Hensman |
| 출처 | arXiv:2404.00456 |
| 주제 | LLM Quantization, Rotation, Hadamard Transform, Activation Quantization, KV Cache Quantization |
| 핵심 방법 | Computational invariance를 이용해 LLM hidden state와 weight를 Hadamard rotation으로 바꾸고, outlier 없는 4-bit weight/activation/KV cache inference를 구성 |

## 한 줄 요약

QuaRot은 LLM의 output을 바꾸지 않는 회전 변환으로 activation outlier를 제거해, weight뿐 아니라 activation과 KV cache까지 4비트로 낮추는 quantization scheme이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 weight-only quantization만으로는 end-to-end 4-bit inference가 어려운가? |
| 2 | Outlier 문제 | Activation과 KV cache의 outlier feature는 왜 낮은 bit-width에서 치명적인가? |
| 3 | 계산 불변성 | Hidden state를 직교 행렬로 회전해도 model output을 유지할 수 있는가? |
| 4 | QuaRot 구조 | Hadamard rotation을 weight, FFN, attention, KV cache에 어떻게 배치하는가? |
| 5 | 실험 결과 | LLaMA 계열에서 PPL, zero-shot, prefill speedup, decoding memory saving은 어떻게 나타나는가? |
| 6 | 해석 포인트 | QuaRot은 GPTQ류 weight-only PTQ와 무엇이 다른가? |

## 1. 문제 배경

LLM inference 비용은 weight memory뿐 아니라 activation, KV cache, matrix multiplication precision에 의해 결정된다. Weight-only PTQ는 model footprint를 크게 줄이지만, 계산 과정에서 activation이 FP16으로 남거나 KV cache가 큰 precision으로 저장되면 end-to-end 4-bit inference까지는 가지 못한다.

특히 activation에는 큰 outlier feature가 나타난다. 이 outlier는 4-bit uniform quantization에서 dynamic range를 크게 만들고, 대부분의 작은 값이 거칠게 표현되게 만든다. 기존 방법들은 calibration data로 outlier channel을 찾아 high precision으로 남기는 mixed-precision 전략을 쓰기도 하지만, 이 경우 kernel과 deployment가 복잡해진다.

## 2. 핵심 아이디어

QuaRot은 LLM의 hidden state를 직교 행렬로 회전해도 model output을 유지할 수 있다는 computational invariance를 이용한다. Hadamard rotation은 값을 여러 좌표에 퍼뜨려 특정 channel에 집중된 outlier를 줄인다. 이 회전 효과를 가능한 weight matrix에 fuse하면, runtime overhead를 제한하면서 activation distribution을 quantization-friendly하게 바꿀 수 있다.

| 구성 | 역할 |
|---|---|
| Randomized Hadamard transform | hidden state와 weight의 outlier feature를 분산한다. |
| Weight fusion | 회전 행렬을 weight에 흡수해 output invariance를 유지한다. |
| Online Hadamard | FFN down-projection과 attention 일부에서 필요한 회전을 runtime에 수행한다. |
| KV cache rotation | key/value cache도 low-bit로 저장할 수 있게 outlier를 완화한다. |

## 3. 시스템 구조

QuaRot은 먼저 RMSNorm/LayerNorm의 scale을 인접 weight에 흡수한 뒤, Transformer block 사이 hidden state를 Hadamard matrix로 회전한다. Feed-forward block에서는 up/gate/down projection에 맞게 회전이 weight 또는 online transform으로 배치된다. Attention block에서는 value projection과 output projection, key rotation, positional embedding과의 관계까지 고려해 회전이 삽입된다.

이 방식의 목표는 모든 matrix multiplication이 low-bit path를 사용할 수 있게 만드는 것이다. 논문은 weight, activation, KV cache를 모두 4비트로 낮추는 구성을 제시하고, calibration data 없이도 6-bit와 8-bit에서는 round-to-nearest만으로 거의 손실 없는 결과를 얻을 수 있음을 보인다.

## 4. 실험 설정과 주요 결과

논문은 LLaMA-2, LLaMA-3, Phi 계열 모델에서 WikiText-2 perplexity와 zero-shot benchmark, prefill/decoding 성능을 평가한다.

| 항목 | 결과 |
|---|---|
| LLaMA2-70B INT4 | WikiText-2 perplexity loss가 최대 0.47 수준으로 보고된다. |
| Zero-shot | 4-bit 설정에서도 zero-shot 성능의 약 99%를 보존한다고 보고한다. |
| Prefill | LLaMA2-70B에서 batch size 64, sequence length 2048 기준 최대 3.33x speedup을 제시한다. |
| Decoding | KV cache low-bit 저장으로 decoding memory saving 최대 3.89x를 보고한다. |
| Calibration | 6-bit/8-bit에서는 calibration 없이 RTN으로도 손실이 거의 없음을 보인다. |

## 5. 읽을 때 잡아야 할 관점

QuaRot의 기여는 단순히 4-bit quantization을 적용했다는 것이 아니라, outlier channel을 high precision으로 예외 처리하지 않고도 activation과 KV cache까지 포함한 end-to-end low-bit path를 구성하려는 점이다. Rotation은 quantization error를 줄이는 preprocessing이면서, Transformer의 계산 불변성을 이용한 model reparameterization이다.

GPTQ는 weight-only PTQ의 대표적 기준점이라면, QuaRot은 activation/KV cache까지 낮추기 위해 distribution 자체를 바꾸는 접근이다. 따라서 두 방법은 경쟁만 하는 관계가 아니라, QuaRot이 weight quantization 단계에서 GPTQ를 사용할 수 있다는 점에서 결합 가능하다.

## 6. 한계와 향후 과제

QuaRot은 Hadamard transform과 low-bit kernel support에 의존한다. Rotation 자체의 수학적 output invariance가 있더라도, 실제 speedup은 hardware kernel, batch size, sequence length, memory-bound 정도에 따라 달라진다. 또한 LLaMA 계열 중심의 실험 결과가 다른 architecture나 production serving stack에서 그대로 유지되는지는 별도 검증이 필요하다.

LLAMA-3 결과에서는 LLAMA-2보다 quantization sensitivity가 더 크게 나타난다. 이는 같은 rotation scheme이라도 model family와 training distribution에 따라 quantization robustness가 달라질 수 있음을 시사한다.

## 핵심 내용

이 절은 원문 전체를 그대로 옮긴 번역이 아니라, QuaRot 논문의 문제 설정, 방법, 실험, 한계를 한국어로 따라 읽을 수 있게 재구성한 번역형 해설이다. 논문 고유명사, 수식 기호, 모델명, 실험 수치는 원문 기준을 유지했다.

QuaRot이 출발하는 문제는 activation outlier다. Weight-only quantization은 LLM memory footprint를 줄일 수 있지만, activation과 KV cache가 high precision으로 남으면 end-to-end inference 비용은 여전히 크다. 특히 4-bit activation quantization에서는 일부 feature의 큰 값이 전체 quantization range를 지배해 작은 값들의 표현 정확도를 떨어뜨린다.

논문은 이 문제를 channel별 예외 처리 대신 rotation으로 해결한다. Randomized Hadamard transform을 hidden state에 적용하면 특정 channel에 몰린 큰 값이 여러 coordinate로 퍼져 outlier가 완화된다. Transformer block의 computational invariance를 이용하면, 이런 회전은 weight matrix에 흡수되거나 attention/FFN 내부의 online transform으로 배치되어 model output을 유지할 수 있다.

QuaRot의 구조는 weight, activation, KV cache를 함께 고려한다. RMSNorm scale을 weight에 흡수하고, FFN down-projection과 attention value/key 경로에 Hadamard transform을 배치해 activation과 cache의 분포를 quantization-friendly하게 만든다. 결과적으로 모든 matrix multiplication이 4-bit path를 사용할 수 있는 구성을 목표로 한다.

실험에서는 LLaMA2-70B 기준 4-bit quantization에서 WikiText-2 perplexity 손실을 작게 유지하고, zero-shot 성능 대부분을 보존한다고 보고한다. 또한 prefill 단계에서는 low-bit matrix multiplication의 이점으로 speedup을, decoding 단계에서는 KV cache 압축으로 memory saving을 얻는다.

결론적으로 QuaRot은 LLM PTQ를 weight compression 문제에서 inference data path 전체의 precision 설계 문제로 확장한다. GPTQ가 weight-only PTQ의 실용성을 보였다면, QuaRot은 activation과 KV cache까지 포함한 end-to-end 4-bit inference의 가능성을 보여주는 연구로 읽을 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/quarot-outlier-free-4-bit-inference-in-rotated-llms/quarot-outlier-free-4-bit-inference-in-rotated-llms.pdf" | relative_url }}" target="_blank" rel="noopener">quarot-outlier-free-4-bit-inference-in-rotated-llms.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2404.00456" target="_blank" rel="noopener">arXiv:2404.00456</a></li>
  <li><a href="https://github.com/spcl/QuaRot" target="_blank" rel="noopener">spcl/QuaRot</a></li>
</ul>
