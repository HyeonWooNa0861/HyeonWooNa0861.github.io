---
layout: default
title: "CoverCal"
topic: "Coverage-based calibration for LLM post-training quantization"
order: 38
---

# Coverage-Based Calibration for Post-Training Quantization via Weighted Set Cover over Outlier Channels

Source PDF: `coverage-based-calibration-for-post-training-quantization-via-weighted-set-cover-over-outlier-channels.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Coverage-Based Calibration for Post-Training Quantization via Weighted Set Cover over Outlier Channels |
| 저자 | Ibne Farabi Shihab, Sanjeda Akter, Anuj Sharma |
| 출처 | arXiv:2604.24008v1, NeurIPS 2025 |
| 주제 | LLM Post-Training Quantization, Calibration Data Selection, Outlier Channels |
| 핵심 방법 | calibration sample selection을 weighted set cover 문제로 정식화한 COVERCAL |

## 한 줄 요약

이 논문은 PTQ 보정 데이터의 품질을 일반적인 데이터 대표성이 아니라 outlier channel coverage 문제로 보고, 작은 calibration budget에서도 중요한 activation channel을 더 잘 덮는 COVERCAL 선택 기준을 제안한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 random calibration sample이 PTQ 품질을 불안정하게 만드는가? |
| 2 | Outlier channel | 어떤 hidden dimension이 양자화 손실을 지배하는가? |
| 3 | Weighted set cover | sample 선택을 어떤 부분모듈러 최적화로 볼 수 있는가? |
| 4 | COVERCAL | GPU 없이 사전 계산된 activation 통계로 어떻게 sample을 고르는가? |
| 5 | 실험 결과 | AWQ/GPTQ와 LLaMA/Mistral에서 어떤 개선이 나타나는가? |

## 1. 문제 배경

LLM PTQ는 보통 수십에서 수백 개의 calibration sequence만 사용해 activation range와 layer-wise reconstruction 통계를 추정한다. 기존 관행은 C4나 WikiText에서 균등 무작위 표본을 고르는 방식에 가깝다. 그러나 작은 calibration set은 중요한 activation pattern을 놓치기 쉽고, 특히 outlier channel을 충분히 활성화하지 못하면 quantizer가 해당 channel의 dynamic range를 과소추정한다.

논문은 이 실패가 단순한 sample representativeness 문제가 아니라 coverage 문제라고 본다. 좋은 calibration set은 입력 분포를 평균적으로 닮는 것보다, 양자화 손실에 큰 영향을 주는 outlier channel을 빠짐없이 활성화해야 한다.

## 2. 핵심 아이디어

COVERCAL은 각 sample이 어떤 outlier channel을 활성화하는지 보고, 중요한 channel을 많이 덮는 sample을 고른다. 이를 weighted set cover로 정식화한다.

| 구성 | 의미 |
|---|---|
| universe | outlier activation channel 집합 |
| set | 하나의 calibration sample이 활성화하는 outlier channel |
| weight | 해당 channel을 놓쳤을 때 예상되는 reconstruction/clipping 손실 |
| objective | 선택한 sample들이 덮는 weighted outlier coverage 최대화 |

이 목적함수는 monotone submodular 성질을 가지므로 greedy 선택이 자연스럽다. 논문의 중요한 점은 새 quantization backend를 제안하는 것이 아니라, GPTQ/AWQ 같은 기존 PTQ backend 앞단에서 calibration sample을 더 원칙적으로 선택한다는 것이다.

## 3. 실험 결과

논문은 LLaMA-2, LLaMA-3, Mistral 계열 모델과 AWQ/GPTQ backend에서 COVERCAL을 평가한다. 비교 대상은 random selection, max-perplexity, max-activation-variance, stratified selection이다.

| 조건 | 결과 |
|---|---|
| INT4, 128 samples | random calibration 대비 MMLU 1.2-1.5점 개선 |
| perplexity degradation | random 대비 15-30% 감소 |
| 64 samples | random 256 samples와 같거나 더 나은 성능 |
| 주요 이득 구간 | calibration budget이 작을수록 차이가 커짐 |

이 결과는 calibration data curation이 quantizer 자체만큼 중요할 수 있음을 보여준다. 특히 PTQ 연구에서 "어떤 backend가 좋은가"뿐 아니라 "그 backend에 어떤 calibration set을 넣는가"가 별도 연구 축이 된다는 점이 중요하다.

## EPTQ/YAQA와의 연결

EPTQ, QTIP, QuIP# 같은 연구가 quantizer geometry와 rounding 구조를 다룬다면, COVERCAL은 calibration input이 activation statistics를 어떻게 왜곡하는지에 집중한다. YAQA가 원 모델 출력 KL을 평가축으로 제안한다면, COVERCAL은 그 평가축을 개선하기 위한 calibration set 설계 문제로 연결될 수 있다.

## 핵심 내용

- PTQ calibration sample은 단순히 많을수록 좋은 것이 아니라 중요한 outlier channel을 덮어야 한다.
- Outlier channel을 놓치면 dynamic range가 과소추정되고 clipping/reconstruction error가 특정 channel에 집중된다.
- COVERCAL은 sample selection을 weighted set cover로 보고 greedy하게 calibration set을 구성한다.
- 기존 GPTQ/AWQ backend와 결합할 수 있는 calibration-data-side 개선 방법이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/coverage-based-calibration-for-post-training-quantization-via-weighted-set-cover-over-outlier-channels/coverage-based-calibration-for-post-training-quantization-via-weighted-set-cover-over-outlier-channels.pdf" | relative_url }}" target="_blank" rel="noopener">coverage-based-calibration-for-post-training-quantization-via-weighted-set-cover-over-outlier-channels.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2604.24008" target="_blank" rel="noopener">arXiv:2604.24008</a></li>
</ul>
