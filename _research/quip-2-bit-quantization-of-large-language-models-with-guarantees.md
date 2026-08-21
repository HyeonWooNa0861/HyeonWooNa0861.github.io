---
layout: default
date: 2026-07-09 14:09:04 +0900
title: "QuIP"
topic: "2-bit LLM quantization with incoherence processing and LDLQ"
order: 35
major_topic: "LLM Quantization & Compression"
keywords:
  - "QuIP"
  - "2-bit quantization"
  - "incoherence processing"
  - "LDLQ"
---

# QuIP

Source PDF: `quip-2-bit-quantization-of-large-language-models-with-guarantees.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | QuIP: 2-Bit Quantization of Large Language Models With Guarantees |
| 핵심 주제 | LLM 사후 학습 2-bit 양자화 |
| 방법 | Incoherence processing + LDLQ adaptive rounding |
| 평가 | OPT 계열, Llama 2 70B, 언어 생성 및 zero-shot 과제 |
| 코드 | https://github.com/Cornell-RelaxML/QuIP |

## 한 줄 요약

QuIP은 가중치와 Hessian을 무작위 직교 변환으로 비정합적으로 만든 뒤 LDLQ 적응형 반올림을 적용해, 2-bit LLM 양자화에서 발생하던 성능 붕괴를 크게 완화한 PTQ 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 2-bit PTQ 문제 | 왜 단순 반올림이나 OPTQ가 낮은 bit에서 무너지는가? |
| 2 | LDLQ | Hessian 기반 adaptive rounding을 어떻게 최적화하는가? |
| 3 | Incoherence | 가중치와 Hessian의 좌표축 정렬을 왜 깨야 하는가? |
| 4 | QuIP 알고리즘 | 전처리, LDLQ, 후처리를 어떻게 결합하는가? |
| 5 | 실험 | Llama 2 70B와 OPT에서 2-bit 성능이 얼마나 개선되는가? |

## 1. 문제 배경

LLM은 매개변수 수가 매우 커서 추론 비용과 메모리 비용이 크다. Post-training quantization은 재학습 없이 가중치를 낮은 bit로 줄이는 방법이지만, 2-bit처럼 극단적인 압축에서는 단순 반올림이나 기존 PTQ가 성능 붕괴를 일으키기 쉽다.

QuIP의 출발점은 양자화가 가중치와 Hessian의 좌표계 성질에 민감하다는 관찰이다. 특정 좌표에 큰 가중치나 중요한 Hessian 방향이 몰려 있으면, 낮은 bit 격자에 맞추는 과정에서 오류가 크게 증폭된다.

## 2. 대리 목적함수

QuIP은 선형 layer의 원래 가중치 \(W\), 양자화된 가중치 \(\hat{W}\), calibration input의 second moment matrix \(H\)를 사용해 다음 이차 대리 손실을 최소화한다.

$$\ell(\hat{W})=\operatorname{tr}\left((\hat{W}-W)H(\hat{W}-W)^{T}\right).$$

이 목적함수는 양자화 오차가 모델 출력에 미치는 영향을 Hessian으로 가중해 측정한다. 핵심은 모든 entry를 독립적으로 반올림하는 대신, 앞서 반올림한 열의 오차를 뒤쪽 열에 보정하는 adaptive rounding을 사용한다는 점이다.

## 3. LDLQ

LDLQ는 \(H\)의 LDL 분해를 이용해 선형 feedback 행렬을 정한다. 열 \(k\)를 양자화할 때 이전 열들의 양자화 오차를 보정항으로 더한다.

$$\hat{W}_k=Q\left(W_k+(W_{1:(k-1)}-\hat{W}_{1:(k-1)})a_k\right).$$

논문은 이 계열의 adaptive rounding 방법 중 LDLQ가 최악 경우와 평균 경우의 대리 손실에서 최적임을 보인다. 또한 비정합성 처리를 제거한 LDLQ가 OPTQ와 동치이며, OPTQ의 이론적 해석을 제공한다고 설명한다.

## 4. Incoherence Processing

QuIP의 핵심 차별점은 양자화 전에 가중치와 Hessian을 비정합적으로 만드는 전처리이다. 직관적으로 비정합성은 큰 값이나 중요한 방향이 특정 좌표에 몰리지 않도록 퍼뜨리는 성질이다.

전처리는 대략 다음 순서로 진행된다.

1. \(H\)에 damping 항을 더한다.
2. \(W\)와 \(H\)를 대각 재스케일링한다.
3. 무작위 직교행렬 \(U,V\)로 \(W\leftarrow UWV^{T}\), \(H\leftarrow VHV^{T}\)를 적용한다.
4. Frobenius norm 기반 범위로 \(W\)를 양자화 격자에 맞게 scale하고 clamp한다.

후처리에서는 같은 시드로 생성한 직교행렬을 사용해 변환을 되돌리고, 대각 재스케일링도 복원한다.

## 5. 빠른 직교 곱셈

완전한 무작위 직교행렬을 실제 추론에 그대로 쓰면 비용이 너무 크다. QuIP은 Kronecker product 형태의 무작위 직교행렬을 사용한다. 예를 들어 \(n=pq\)이면 \(U=U_L\otimes U_R\)로 두고, 벡터를 행렬로 reshape한 뒤 양쪽에서 작은 직교행렬을 곱하는 방식으로 연산한다.

이 설계는 비정합성 효과를 얻으면서도 전처리와 추론 오버헤드를 통제하기 위한 장치이다.

## 6. QuIP과 OPTQ의 관계

논문은 비정합성 처리를 제거한 QuIP, 즉 LDLQ가 OPTQ와 동치라고 설명한다. 차이는 구현 효율이다. OPTQ 구현은 \(H\)의 역행렬과 두 번의 Cholesky 분해가 필요하지만, LDLQ 구현은 역행렬 없이 한 번의 분해로 처리할 수 있다.

따라서 QuIP은 OPTQ를 단순히 대체하는 별도 휴리스틱이라기보다, OPTQ 계열의 adaptive rounding을 더 이론적으로 정리하고 그 앞뒤에 비정합성 처리를 붙인 방법으로 볼 수 있다.

## 7. 실험 결과 해석

QuIP은 OPT 모델 계열과 Llama 2 70B에서 평가된다. 특히 Llama 2 70B 결과에서 2-bit OPTQ는 WikiText2 perplexity 123.908, C4 perplexity 70.541로 크게 무너지지만, QuIP 2-bit는 각각 6.326, 8.937까지 낮춘다. Zero-shot 과제에서도 PiQA는 50.54에서 75.08, StoryCloze는 51.75에서 75.37로 개선된다.

OPT-30B 절제 결과에서도 비정합성 처리는 LDLQ/OPTQ뿐 아니라 Greedy, Near rounding과 결합했을 때도 2-bit 성능 붕괴를 크게 줄인다. 즉 개선은 특정 반올림 구현 하나의 효과가 아니라, 좌표계와 이상치 구조를 바꾸는 전처리의 효과가 크다.

## 핵심 내용

- QuIP은 2-bit LLM PTQ를 목표로 하는 방법이며, 핵심은 LDLQ adaptive rounding과 incoherence processing의 결합이다.
- LDLQ는 Hessian 기반 대리 손실을 줄이기 위해 이전 열의 양자화 오차를 다음 열에 보정한다.
- Incoherence processing은 무작위 직교 변환과 재스케일링으로 가중치와 Hessian의 좌표축 집중을 완화한다.
- OPTQ는 LDLQ의 특수한 경우로 해석되며, QuIP은 이 관계를 통해 OPTQ에 대한 이론적 설명도 제공한다.
- Llama 2 70B와 OPT 실험에서 2-bit 양자화 성능 붕괴를 크게 완화한다.

## 해석 포인트

QuIP의 메시지는 "좋은 반올림 방법"만으로는 부족하다는 것이다. 낮은 bit에서는 어떤 좌표계에서 반올림하느냐가 성능을 좌우한다. 비정합성 처리는 가중치와 Hessian의 나쁜 좌표 정렬을 깨고, LDLQ가 더 유리한 조건에서 동작하게 만든다.

## 한계와 향후 과제

QuIP은 2-bit PTQ에서 강력한 결과를 보이지만, 직교 변환과 후처리 구조가 실제 추론 커널 및 배포 스택과 어떻게 결합되는지는 별도 엔지니어링 과제이다. 또한 논문은 calibration set 기반 Hessian 추정에 의존하므로, calibration 데이터 분포가 실제 사용 분포와 달라질 때의 안정성도 중요하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/quip-2-bit-quantization-of-large-language-models-with-guarantees/quip-2-bit-quantization-of-large-language-models-with-guarantees.pdf" | relative_url }}" target="_blank" rel="noopener">QuIP: 2-Bit Quantization of Large Language Models With Guarantees PDF</a></li>
  <li><a href="https://github.com/Cornell-RelaxML/QuIP" target="_blank" rel="noopener">QuIP GitHub repository</a></li>
</ul>
