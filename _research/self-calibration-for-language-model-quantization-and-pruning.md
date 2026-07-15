---
layout: default
title: "Self-Calibration"
topic: "Synthetic calibration data for language model quantization and pruning"
order: 43
---

# Self-calibration for Language Model Quantization and Pruning

Source PDF: `self-calibration-for-language-model-quantization-and-pruning.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Self-calibration for Language Model Quantization and Pruning |
| 저자 | Miles Williams, George Chrysostomou, Nikolaos Aletras |
| 출처 | NAACL 2025 |
| 주제 | Calibration Data, Quantization, Pruning, Synthetic Data |
| 핵심 방법 | 압축 대상 language model이 직접 synthetic calibration data를 생성하는 self-calibration |

## 한 줄 요약

Self-Calibration은 외부 calibration corpus 없이 압축 대상 LM이 스스로 생성한 synthetic text를 calibration data로 사용해 quantization과 pruning의 downstream 성능을 유지하려는 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 random web text calibration이 항상 적절하지 않은가? |
| 2 | Self-calibration | 모델이 직접 만든 텍스트가 pretraining distribution을 어떻게 근사하는가? |
| 3 | Compression targets | quantization과 pruning에 모두 적용 가능한가? |
| 4 | 실험 결과 | real data calibration과 비교해 downstream 성능은 어떤가? |
| 5 | 해석 | data-free compression과 calibration data curation 사이에서 어떤 의미가 있는가? |

## 1. 문제 배경

사후 학습 quantization과 pruning은 보통 소량의 unlabeled calibration examples에 의존한다. 관행적으로는 웹 텍스트를 무작위로 샘플링해 pretraining distribution을 대략 반영한다고 가정한다. 그러나 공개되지 않은 training data를 가진 모델도 많고, 부적절한 calibration example은 압축 후 성능을 떨어뜨릴 수 있다.

## 2. 핵심 아이디어

Self-calibration은 외부 데이터를 가져오지 않고, 압축하려는 모델 자신에게 calibration text를 생성하게 한다. 모델이 학습 중 내재화한 distribution을 다시 샘플링해 calibration data로 쓰는 관점이다.

| 구성 | 의미 |
|---|---|
| external calibration | C4/WikiText 등 외부 corpus에서 무작위 샘플 |
| self-calibration | 모델이 생성한 synthetic samples |
| 목표 | downstream task 성능을 유지하는 compression calibration |
| 적용 대상 | quantization과 pruning |

이 방법은 training data가 비공개인 모델에도 적용 가능하고, domain mismatch가 큰 외부 corpus를 쓰는 문제를 줄일 수 있다.

## 3. Calibration 연구 축에서의 의미

Self-Calibration은 COVERCAL이나 Calibration Data Curation과 함께 "압축 성능은 calibration data 설계에 의존한다"는 흐름을 만든다. COVERCAL은 outlier channel coverage를, Calibration Data Curation은 activation-space diversity와 capability 보존을, Self-Calibration은 external data 없이 model-generated data를 쓰는 방향을 제시한다.

## 핵심 내용

- Quantization/pruning은 calibration data 품질에 민감하다.
- Self-calibration은 외부 corpus 없이 모델이 직접 synthetic calibration examples를 생성하게 한다.
- 데이터 공개가 제한된 모델이나 domain mismatch가 큰 환경에서 유용하다.
- 압축 대상 모델의 internal distribution을 활용하는 data-free calibration 접근이다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/self-calibration-for-language-model-quantization-and-pruning/self-calibration-for-language-model-quantization-and-pruning.pdf" | relative_url }}" target="_blank" rel="noopener">self-calibration-for-language-model-quantization-and-pruning.pdf</a></li>
  <li><a href="https://github.com/mlsw/llm-compression-calibration" target="_blank" rel="noopener">Self-calibration code</a></li>
  <li><a href="https://arxiv.org/abs/2410.17170" target="_blank" rel="noopener">arXiv:2410.17170</a></li>
</ul>
