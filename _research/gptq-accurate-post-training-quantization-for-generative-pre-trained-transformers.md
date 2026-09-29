---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "GPTQ"
topic: "Accurate post-training quantization for generative pretrained transformers"
order: 28
major_topic: "LLM Quantization & Compression"
keywords:
  - "GPTQ"
  - "Post-training quantization"
  - "Large language models"
  - "Weight quantization"
---

# GPTQ: Accurate Post-Training Quantization for Generative Pre-Trained Transformers

Source PDF: `gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | GPTQ: Accurate Post-Training Quantization for Generative Pre-Trained Transformers |
| 저자 | Elias Frantar, Saleh Ashkboos, Torsten Hoefler, Dan Alistarh |
| 출처 | arXiv:2210.17323, ICLR 2023 |
| 주제 | Large Language Model, Post-Training Quantization, Weight-Only Quantization, Approximate Second-Order Method |
| 핵심 방법 | OBQ를 대규모 GPT/OPT/BLOOM 계열 모델에 맞게 단순화하고 batch update, Cholesky 재정식화, group-wise quantization을 결합한 one-shot PTQ |

## 한 줄 요약

GPTQ는 거대 GPT 계열 모델을 재학습 없이 3-4비트 weight로 압축하기 위해 layer-wise reconstruction과 approximate second-order compensation을 확장한 PTQ 방법이다.

## 핵심 내용

GPTQ가 다루는 문제는 거대 생성형 Transformer의 추론 비용이다. GPT/OPT/BLOOM 계열 모델은 parameter 수가 커질수록 weight memory만으로도 단일 GPU 용량을 넘기 쉽고, 여러 GPU에 나누어 실행하면 비용과 운영 복잡도가 커진다. 논문은 이러한 문제를 재학습 없는 one-shot PTQ로 줄이려 한다.

방법의 출발점은 layer-wise reconstruction이다. 각 linear layer에서 $$WX$$와 $$\widehat{W}X$$의 차이를 줄이도록 quantized weight를 선택하며, 단순 nearest rounding이 아니라 Hessian 정보를 사용해 양자화 error를 남은 weight에 보상한다. 이는 OBQ의 아이디어지만, 원래 OBQ는 계산량과 메모리 접근 패턴 때문에 GPT 규모에 그대로 쓰기 어렵다.

GPTQ의 핵심 수정은 scale-up이다. 모든 row가 같은 quantization order를 쓰게 해 Hessian inverse update를 공유하고, lazy batch update로 GPU memory bandwidth 병목을 줄이며, Cholesky 기반 계산으로 수치 불안정을 완화한다. 이 조합 덕분에 175B급 모델도 몇 시간 안에 3-4비트 weight로 양자화할 수 있다고 보고한다.

실험 결과는 GPTQ가 3-4비트 weight-only PTQ에서 정확도와 실용성을 동시에 겨냥했음을 보여준다. OPT/BLOOM 175B 수준에서도 perplexity 손실을 작게 유지하고, 압축된 model을 단일 GPU 또는 더 적은 GPU 수로 실행할 수 있게 만든다. 또한 memory-bound generation에서는 FP16 대비 의미 있는 end-to-end speedup을 얻는다.

결론적으로 GPTQ는 LLM PTQ 연구에서 중요한 기준점이다. 이후 QuaRot은 activation과 KV cache까지 4비트로 낮추기 위해 outlier 제거와 rotation을 도입하고, QTIP과 EPTQ는 더 낮은 bit-width에서 codebook geometry와 decoding 효율을 개선한다. 따라서 GPTQ는 "대형 LLM weight-only PTQ가 실제로 가능하다"는 것을 보여준 출발점으로 읽는 것이 적절하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 GPT-175B급 모델은 추론만 해도 multi-GPU가 필요한가? |
| 2 | 기존 PTQ 한계 | RTN, ZeroQuant, LLM.int8()은 왜 3-4비트 weight-only 압축에서 부족한가? |
| 3 | OBQ 기반 | Optimal Brain Quantization의 Hessian compensation을 어떻게 활용하는가? |
| 4 | GPTQ 수정 | 임의 순서, lazy batch update, Cholesky 재정식화가 어떤 계산 병목을 줄이는가? |
| 5 | 실험 결과 | OPT/BLOOM에서 perplexity, zero-shot, runtime, speedup은 어떻게 달라지는가? |
| 6 | 해석 포인트 | GPTQ의 성능 개선은 계산량 감소인가, memory movement 감소인가? |

## 1. 문제 배경

GPT, OPT, BLOOM 같은 생성형 Transformer는 모델 크기가 커질수록 추론 비용이 급격히 증가한다. 예를 들어 175B parameter 모델은 FP16 weight만으로도 단일 GPU 메모리를 넘기 쉽다. 따라서 모델을 여러 GPU에 나누거나 더 큰 장비를 사용해야 하고, 이는 연구와 배포의 접근성을 낮춘다.

논문은 학습을 다시 수행하지 않는 post-training quantization(PTQ)에 초점을 둔다. 전체 fine-tuning이나 quantization-aware training은 거대 LLM에서는 비용이 크므로, 적은 calibration data와 짧은 변환 시간으로 weight bit-width를 낮추는 방식이 필요하다.

## 2. 문제 정의

GPTQ는 각 linear layer를 독립적으로 양자화하면서, full precision layer output과 quantized layer output의 차이를 줄이는 reconstruction problem으로 본다.

$$
\mathop{\mathrm{argmin}}_{\widehat{W}} \; \lVert W X - \widehat{W} X \rVert_2^{2}
$$

여기서 $$W$$는 원래 weight, $$X$$는 양자화 전에 출력 변화를 측정하는 calibration input, $$\widehat{W}$$는 quantized weight다. 중요한 점은 weight 자체의 round error가 아니라, 그 weight가 calibration input에 곱해졌을 때 생기는 output error를 줄인다는 것이다.

### 출력 오차와 보정의 작은 예시

다음은 논문 실험값이 아니라 식 (1)을 하나의 출력 행에 제한해 보정의 작동을 보여 주는 예시다. 이 경우 출력 오차는 각 calibration input에서 생긴 오차의 제곱을 더해 계산한다. Weight 행을 $$w=(0.6, 0.4)$$, 두 calibration input을 $$x^{(1)}=(1,1)^{\top}$$, $$x^{(2)}=(1,0)^{\top}$$이라고 하자. 원래 출력 $$wx^{(1)}$$과 $$wx^{(2)}$$는 각각 $$1.0$$과 $$0.6$$이다.

이 예시에서만 첫 번째 weight의 양자화 격자를 $$\{0,1\}$$로 두면 $$0.6$$은 가까운 값 $$1$$로 고정된다. 두 번째 weight를 그대로 두었을 때 출력은 $$1.4$$와 $$1.0$$으로 바뀌고, 원래 출력과의 제곱오차 합은 $$0.4^2+0.4^2=0.32$$다. 아직 양자화하지 않은 두 번째 weight를 $$w_2$$라고 하면, 첫 번째 출력은 $$1+w_2$$이고 두 번째 출력은 $$1$$로 고정된다. 따라서 $$w_2$$를 $$0.4$$에서 $$0$$으로 보정하면 출력은 $$1.0$$과 $$1.0$$이 되고, 제곱오차 합은 $$0^2+0.4^2=0.16$$으로 줄어든다. 두 번째 입력은 $$w_2$$에 곱해지는 값이 $$0$$이므로 그 출력 오차는 남는다.

이 예시는 한 weight의 양자화 오차를 남은 weight로 일부 보상하는 목적을 보여 준다. 실제 보정량은 calibration input에 따라 달라진다. 목적식은 주어진 $$X$$ 위의 오차만 측정하고 이후 남은 weight도 양자화되므로, 다른 입력이나 최종 layer에서도 오차가 항상 이 예시처럼 줄어든다는 보장은 없다.

## 3. OBQ에서 GPTQ로

GPTQ는 Optimal Brain Quantization(OBQ)의 아이디어를 가져온다. 위 예시에서 두 번째 weight를 조정한 것이 보정의 기본 동작이다. 논문 3절의 OBQ는 각 weight row의 출력 제곱오차가 남은 weight에 대해 이차식이라는 점을 이용한다. 아직 양자화하지 않은 weight의 index 집합을 $$F$$, 그에 대응하는 입력 행을 $$X_F$$라고 하면 Hessian(오차의 곡률을 나타내는 행렬)은 $$H_F=2X_F X_F^{\top}$$다. OBQ는 하나의 weight를 양자화한 뒤 $$H_F^{-1}$$을 이용해 남은 weight의 보정량을 계산한다. 이 역행렬 표기는 $$H_F$$가 비특이일 때 성립한다. 논문의 실제 GPTQ 알고리즘은 작은 damping 항 $$\lambda I$$($$I$$는 항등행렬)을 더한 $$\left(2XX^{\top}+\lambda I\right)^{-1}$$을 사용하고 Cholesky 재정식화로 수치 불안정성을 줄인다. 따라서 예시의 $$0.4\rightarrow0$$은 모든 입력에 적용되는 고정 규칙이 아니라, 이 두 calibration input에서 출력 제곱오차를 줄이는 한 경우다.

하지만 원래 OBQ는 column 수에 대해 cubic한 비용을 가지며, row마다 greedy order와 inverse update를 반복해야 하므로 GPT 규모에는 직접 적용하기 어렵다. GPTQ는 다음 수정으로 이 병목을 줄인다.

| 수정 | 의미 |
|---|---|
| Fixed quantization order | 모든 row가 같은 순서로 weight를 양자화하게 해 inverse Hessian update를 공유한다. |
| Lazy batch update | column을 하나씩 전역 갱신하지 않고 block 단위로 error update를 모아 GPU utilization을 높인다. |
| Cholesky 재정식화 | 반복적인 inverse update에서 생기는 수치 불안정을 줄인다. |
| Group-wise quantization | 작은 group마다 scale을 둬 3비트 이하 영역의 정확도 손실을 줄인다. |

## 4. 실험 설정과 주요 결과

논문은 OPT와 BLOOM 계열의 다양한 크기 모델을 대상으로 GPTQ를 평가한다. 지표는 WikiText2/C4/PTB perplexity, zero-shot task accuracy, quantization runtime, generation speedup이다.

핵심 결과는 다음과 같이 정리할 수 있다.

| 항목 | 결과 |
|---|---|
| 변환 비용 | 175B급 모델도 약 4 GPU hour 안에 양자화 가능하다고 보고한다. |
| 3-4비트 정확도 | 3비트와 4비트 weight에서 FP16 baseline 대비 perplexity 증가가 작다. |
| 단일 GPU 실행 | 175B 모델을 단일 고용량 GPU에서 생성 추론할 수 있는 수준으로 weight memory를 줄인다. |
| 추론 속도 | memory-bound generation에서 A100 약 3.25x, A6000 약 4.5x speedup을 보고한다. |
| 극단적 양자화 | 2비트 또는 ternary weight에서도 합리적인 정확도를 일부 유지한다. |

## 5. 읽을 때 잡아야 할 관점

GPTQ의 핵심은 "Hessian 기반 양자화가 정확하다"가 아니라, 그 방법을 175B급 모델에서 실제로 돌릴 수 있게 만든 구현적 단순화에 있다. OBQ가 제공하는 second-order compensation을 유지하되, greedy ordering과 per-weight inverse update의 비용을 줄여 대규모 LLM PTQ로 확장한다.

또한 GPTQ의 speedup은 low-bit 곱셈 연산 자체가 항상 더 빠르기 때문이라기보다, weight memory traffic 감소와 전용 kernel 활용에서 나온다. 따라서 batch size, hardware, kernel 지원 여부에 따라 실제 속도 이득은 달라질 수 있다.

## 6. 한계와 향후 과제

논문은 weight-only quantization에 집중한다. Activation quantization은 별도 문제이며, 특히 outlier activation을 다루는 후속 연구들과 결합될 여지가 있다. 또한 GPTQ의 실효성은 low-bit weight를 빠르게 load/decompress하는 kernel과 memory-bound generation setting에 크게 의존한다.

3-4비트에서는 강한 결과를 보이지만, 2비트 이하에서는 group size와 model size에 따라 손실이 커질 수 있다. 따라서 초저비트 영역은 QTIP, EPTQ, QuaRot 같은 후속 PTQ 연구들이 별도의 codebook, rotation, trellis, lattice 구조를 탐색하게 되는 출발점으로 읽을 수 있다.

## Seminar Materials
| Materials | Slides | PDF | PowerPoint | Study Notes | Speaker Notes |
| --- | ---: | --- | --- | --- | --- |
| Korean Seminar | 26 slides | <a href="/assets/seminars/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers/gptq-seminar-ko-v1.pdf" target="_blank" rel="noopener">View</a> | <a href="/assets/seminars/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers/gptq-seminar-ko-v1.pptx" download>Download</a> | <a href="/assets/seminars/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers/slides-v1.md.txt" download="slides-v1.md">Markdown</a> | <a href="/assets/seminars/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers/presenter-notes-v1.md.txt" download="presenter-notes-v1.md">Markdown</a> |

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers/gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers.pdf" | relative_url }}" target="_blank" rel="noopener">gptq-accurate-post-training-quantization-for-generative-pre-trained-transformers.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2210.17323" target="_blank" rel="noopener">arXiv:2210.17323</a></li>
  <li><a href="https://github.com/IST-DASLab/gptq" target="_blank" rel="noopener">IST-DASLab/gptq</a></li>
</ul>
