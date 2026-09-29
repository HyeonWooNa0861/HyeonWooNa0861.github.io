---
layout: default
date: 2026-09-12 18:42:46 +0900
title: "Calibration Data Impact"
topic: "Calibration data effects in post-training quantization and pruning"
order: 81
major_topic: "LLM Quantization & Compression"
keywords:
  - "Calibration Data Impact"
  - "Research seminar"
---

# On the Impact of Calibration Data in Post-training Quantization and Pruning

## 논문 정보

| 항목 | 내용 |
| --- | --- |
| 제목 | On the Impact of Calibration Data in Post-training Quantization and Pruning |
| 저자 | Miles Williams, Nikolaos Aletras |
| 발표 | ACL 2024 |
| 연구 대상 | LLM의 post-training quantization 및 pruning에서 calibration data가 미치는 영향 |

## 한 줄 요약

**같은 LLM과 압축법을 유지해도 calibration text의 출처와 표본을 바꾸면 일부 downstream 정확도가 달라지며, WikiText perplexity만으로 그 변화를 판단하기 어렵다.**

## 핵심 내용

이 논문은 calibration data를 압축 전에 잠깐 쓰는 부속 입력이 아니라 **어떤 가중치를 어떻게 압축할지 결정하는 입력**으로 다룬다. 저자들은 9개 모델, 4개 압축법, 5개 데이터 출처에서 각각 10개씩 뽑은 calibration set을 교차해 1,800개 압축 모델을 만들고, 10개 zero-shot 과제와 WikiText perplexity를 평가했다(Section 3).

핵심 발견은 세 가지다. **동일한 C4 출처 안의 표본 차이**만으로도 특정 과제 정확도가 달라졌다(Figure 2). **출처 간 우열은 압축법과 모델에 따라 바뀌어** 모든 설정에 통하는 최고 corpus가 없었다(Table 1). 또한 **perplexity의 작은 표준편차가 downstream 과제의 안정성을 보장하지 않았다**(Table 2). 이는 calibration data를 여러 번 샘플링해 실제 사용 과제로 검증하고, 재현 가능한 표본 자체를 기록해야 한다는 결론으로 이어진다.

## 전체 흐름

| 원문 위치 | 이 글에서 다루는 질문 |
| --- | --- |
| Sections 1-2, Figure 1 | 왜 비라벨 calibration text가 압축 결과에 관여하는가? |
| Section 3, Tables 3-4 | 어떤 모델·압축법·표본·과제를 비교했는가? |
| Section 4, Figures 2-4, Tables 1-2 | 같은 출처 안의 변동, 출처 차이, 표본 수, 지표 간 불일치는 어떻게 나타났는가? |
| Sections 5-6, Limitations | 저자들이 권하는 사용·공개 방식과 일반화의 경계는 무엇인가? |
| Appendix C | 본문에 요약된 결과를 모델·과제별 표와 Vicuna·OPT 분포까지 어떻게 확인하는가? |

## 1. 문제 배경: calibration은 학습도 평가도 아니다

Post-training compression은 이미 학습된 모델을 다시 훈련하지 않고 가중치 표현을 바꾼다. Quantization은 가중치를 더 낮은 비트로 표현하고, pruning은 가중치 일부를 제거한다. 이때 소량의 **비라벨 calibration text**를 모델에 통과시켜 얻은 layer activation을 압축 선택의 근거로 사용한다. Calibration text의 정답으로 gradient를 계산해 원 모델을 supervised fine-tuning하는 과정과 다르며, 압축 후 성능을 재는 평가 데이터와도 역할이 다르다. 논문은 zero-shot 평가 데이터가 calibration 출처에 섞이지 않도록 분리했다(Sections 2.1, 3.3).

원문이 소개하는 layer-wise reconstruction 문제는 층 $$\ell$$의 원래 가중치 $$W_\ell$$, 압축 가중치 $$\widetilde W_\ell$$, calibration 입력으로 얻은 activation $$X_\ell$$에 대해 다음 출력 차이를 작게 만드는 것이다(Section 2.1, PDF p. 2).

$$
\left\lVert W_\ell X_\ell-\widetilde W_\ell X_\ell\right\rVert_2^{2}
$$

이 식은 **calibration activation 위에서의 재구성 오차**라는 압축용 대리 목적을 나타낸다. 압축 제약을 만족하는 후보 중 어떤 $$\widetilde W_\ell$$을 선호할지가 $$X_\ell$$에 따라 달라질 수 있다. 따라서 같은 모델·알고리즘이라도 text 표본이 바뀌면 선택이 달라질 여지가 있다. 다만 이 식의 값이 작다는 사실만으로 별도의 downstream 정확도, 공정성, 실제 추론 속도까지 보장되지는 않는다. 이는 식의 적용 범위에 관한 해석이지 논문이 직접 검증한 결과는 아니다.

네 방법은 calibration 신호를 같은 방식으로 읽지 않는다. 이 차이도 이후 결과를 해석할 때 중요하다(Section 2.1, Appendix A).

| 방법 | 압축 | 이 실험의 설정 | calibration이 쓰이는 방식 |
| --- | --- | --- | --- |
| GPTQ | 가중치 양자화 | 4-bit, group size 128 | inverse-Hessian 정보를 이용해 양자화 오차를 보정 |
| SpQR | 가중치 양자화 | 4-bit, outlier 별도 처리 | outlier 가중치를 높은 정밀도로 남기는 양자화 과정에 활용 |
| SparseGPT | 가중치 pruning | 2:4, 50% sparsity | Hessian 관련 정보로 제거·보정 순서를 결정 |
| Wanda | 가중치 pruning | 2:4, 50% sparsity | 가중치 크기와 입력 activation의 $$\ell_2$$ norm을 결합해 제거 기준을 계산 |

두 양자화법과 두 pruning법은 **압축 예산과 연산이 서로 다르다**. 따라서 결과의 절대 정확도 차이를 calibration만의 효과나 네 알고리즘의 공정한 성능 순위로 읽어서는 안 된다. Calibration 효과를 보려면 먼저 같은 모델·방법 안에서 표본만 바뀐 결과를 비교해야 한다.

## 2. 실험 설계와 재현 조건

주요 실험의 격자는 **9개 모델 × 4개 압축법 × 5개 출처 × 출처별 10개 calibration set = 1,800개 압축 모델**이다. 각 모델의 10개 zero-shot 과제 정확도와 WikiText test perplexity를 평가하므로 원문이 보고하는 조합 수는 **19,800 model-evaluation**이다. 이 수는 서로 독립적인 학습 seed 19,800개를 뜻하지 않는다(Section 3).

| 축 | 원문 조건 |
| --- | --- |
| 모델 | LLaMA 7B·13B·33B, Vicuna 7B·13B·33B, OPT 6.7B·13B·30B. LLaMA·OPT는 base, Vicuna는 instruction-tuned 계열 |
| 압축 | GPTQ·SpQR의 4-bit weight quantization; SparseGPT·Wanda의 2:4 semi-structured pruning(가중치 50% 제거) |
| 표본 | 출처당 중복 없는 10개 set, set당 128개 example, example당 2,048 tokens. 따라서 set당 262,144 tokens |
| 평가 | ARC-Easy, ARC-Challenge, BoolQ, HellaSwag, LAMBADA, OpenBookQA, PIQA, RTE, StoryCloze, WinoGrande의 zero-shot 정확도와 WikiText perplexity |
| 구현 | Hugging Face Datasets·Transformers, EleutherAI LM Evaluation Harness; 압축과 평가는 NVIDIA A100 SXM 80GB 한 대에서 수행 |

출처는 웹 텍스트 기준선인 **C4**, 뉴스 장르의 **CNN/Daily Mail(CNN-DM)**, 공개 사전학습 데이터 재현본 **RedPajama**, 필터링·중복 제거된 웹 텍스트 **RefinedWeb**, 전처리된 **영어 Wikipedia(2022-03-01 dump)**이다(Section 3.3). C4와 RefinedWeb은 첫 shard에서, RedPajama는 기존 1B-token extract에서 샘플링했다. 각 출처 안에서는 비복원 추출을 반복해 서로 겹치지 않는 10개 set을 만들었다(Section 3.6). 다른 출처를 비교할 때 장르뿐 아니라 필터링, 길이, 중복 제거, 모델의 사전학습 자료와의 관계도 함께 바뀔 수 있다. **이 실험은 corpus 수준 비교이지 어느 한 속성의 인과 효과를 분리한 실험은 아니다.**

평가는 단일 평균만 보지 않는다. 열 과제 평균은 전체 경향을 요약하지만, 과제별 정확도는 취약한 지점을 드러낸다. Appendix B의 평가 예시 수는 BoolQ 3,270개에 비해 RTE가 277개다. 그래서 RTE의 큰 범위를 calibration 민감도의 보편적 크기로 곧장 일반화하기 어렵다. WikiText perplexity는 언어 모델링 지표이고, 열 과제의 정확도를 대신하지 않는다.

## 3. 주요 결과: 같은 입력 조건에서 무엇이 달라졌나

### 같은 corpus에서도 뽑힌 문장에 따라 과제별 성능이 흔들린다

Figure 2는 **C4에서 추출한 10개 calibration set**으로 각각 압축한 LLaMA 계열의 과제별 분포를 보여 준다. 예를 들어 LLaMA-7B + SparseGPT의 정확도 범위는 **RTE 52.7-61.7%**, **BoolQ 66.4-73.0%**다. 범위의 폭은 각각 9.0, 6.6 percentage points이다. 이는 C4 전체가 좋거나 나쁘다는 비교가 아니라 **같은 출처의 서로 다른 표본**만으로도 해당 과제 결과가 달라진다는 관찰이다. 원문은 RTE의 평가 집합이 작아 변동 해석에 주의가 필요하다고 명시한다. Appendix C의 Figure 5·6은 Vicuna·OPT의 대응 분포를 제시한다.

### 출처 효과는 조건부이며, 단일 우승 corpus는 없다

Table 1의 값은 각 출처에서 만든 **10개 set의 평균 zero-shot 정확도 ± 표준편차**다. SparseGPT에서는 RefinedWeb이 9개 모델 중 8개에서 가장 높은 평균을 보였고, Wikipedia는 8개에서 가장 낮았다. 하지만 이것이 범용 권장 순위는 아니다. 같은 LLaMA-7B라도 Wanda에서는 **RedPajama 52.7±0.2%**가 높고 **RefinedWeb 52.2±0.3%**가 낮다. Vicuna-7B + SparseGPT에서는 **CNN-DM 52.7±0.6%**와 **RefinedWeb 56.3±0.4%** 사이에 3.6 percentage points 차이가 있다. 반대로 SpQR의 출처 간 평균 차이는 대체로 약 0.2 percentage points로 작다. 작은 차이에는 표본 간 분산을 함께 보아야 하므로, 평균이 조금 높은 출처를 통계적으로 확정된 승자로 부르지 않는다.

### 민감도의 크기는 압축법과 모델 계열에 의존한다

Figure 4는 모델·방법별로 **다섯 출처의 50개 calibration set 전체**에서 얻은 열 과제 평균 정확도의 분포를 모았다. OPT-6.7B에서 최고-최저 범위는 GPTQ **1.6**, SpQR **0.9**, SparseGPT **2.4**, Wanda **2.4 percentage points**였다. 원문이 보고한 모델 전반의 범위도 GPTQ 0.9-1.6, SpQR 0.6-1.0, SparseGPT 2.4-4.8, Wanda 0.6-2.9 percentage points로 서로 다르다. 저자들은 이 설정에서 양자화가 pruning보다 대체로 덜 민감하고 SparseGPT의 분산이 크다고 관찰한다(Section 4). Pruning이 더 파괴적이어서 그럴 수 있다는 설명은 **저자들의 추측**이며, 원인 분해 실험의 결론은 아니다.

같은 C4 조건의 Table 1에서는 SparseGPT가 모든 9개 모델에서 Wanda보다 높은 평균 정확도를 보였다. 격차는 OPT에서 2.2-2.6, LLaMA에서 0.3-2.0, Vicuna에서 0.9-2.6 percentage points로 보고된다. 그러나 저자들도 **방법 간 우열 비교가 이 연구의 목적은 아니라고** 밝힌다. 이는 이 논문의 특정 2:4 설정에서 나온 부수적 관찰로 두는 편이 정확하다.

### 표본 수를 늘리는 이득과 비용은 방법마다 다르다

Figure 3은 **LLaMA-7B + C4**에서 calibration example 수를 1, 2, 4, …, 512개로 바꿔 WikiText perplexity와 열 과제 평균을 함께 추적한다. 각 점은 10개 set의 평균이고 음영은 표준편차다. 표본 1개에서 128개로 갈 때 GPTQ의 perplexity는 **6.13±0.05 → 5.90±0.03**, SparseGPT는 **55.26±10.82 → 11.12±0.26**으로 낮아진다(낮을수록 좋다). 반면 SpQR은 거의 **5.74±0.01**로 유지되고 Wanda는 **12.50±0.15 → 11.56±0.06**으로 개선된다. 평균 zero-shot 정확도도 대체로 초반에 평탄해지지만, SparseGPT는 128개에서 512개로 네 배 늘릴 때 약 **0.4 percentage points** 더 올랐다. 저자들은 동시에 example 수가 많아질수록 압축 계산 비용이 증가한다고 지적한다. 따라서 “128개가 모든 방법의 보편적 최적값”도, “많을수록 항상 실질적으로 이득”도 아니다.

### 낮은 perplexity 변동이 과제 성능의 안정성을 뜻하지 않는다

Table 2의 **Vicuna-7B + SparseGPT + CNN-DM** 사례에서 10개 calibration set의 WikiText perplexity는 **12.72±0.18**이다. 같은 압축 모델들의 **BoolQ 정확도는 66.7±4.7%**, 최소-최대는 **57.0-71.6%**였다(Section 4). 하나의 지표에서는 안정적으로 보이는 집합이 다른 과제에서는 크게 흔들릴 수 있음을 보여 주는 사례다. 이는 perplexity가 무용하다는 뜻이 아니라, 실제 사용 목적에 해당하는 downstream 과제를 함께 보라는 근거다.

## 4. 해석 포인트와 실무적 함의

**비교 단위를 먼저 고정해야 한다.** “Calibration에 민감하다”는 말에는 서로 다른 질문이 섞인다. Figure 2는 *같은 출처 안의 표본 변동*, Table 1은 *출처별 평균 차이*, Figure 4는 *전체 50개 set의 범위*를 보여 준다. 이 셋을 하나의 효과 크기로 합치면 출처 선택과 무작위 표본 선택을 구분할 수 없다.

**원문의 세 권고는 관찰에서 이어지지만 보장은 아니다.** 저자들은 (1) 정확한 calibration data를 공개해 재현성을 높이고, (2) 개발 중 여러 set으로 downstream 과제를 평가하며, (3) 무작위 표본의 이상 사례를 사람이 점검하라고 권한다(Section 5). 특히 seed와 생성 코드만으로 동일한 텍스트가 항상 복원된다고 가정하지 않는다. 실험 차이를 추적하려면 model checkpoint, 압축법·hyperparameter, corpus 버전·shard, 실제 토큰화된 표본, 평가 split을 함께 기록하는 편이 유용하다. 이 기록 범위는 논문의 실험 조건을 바탕으로 한 운영 제안이지 검증된 성능 향상법은 아니다.

**성능 범위는 성능 보장이나 추론 가속 수치가 아니다.** 논문은 2:4 패턴을 GPU 가속 가능한 pruning 설정으로 채택했지만, 이 실험 자체가 serving latency나 throughput을 측정해 비교한 것은 아니다. 출처별 텍스트 품질이나 사전학습 중복률의 인과 효과도 단독으로 검증하지 않았다.

## 5. 논문의 기여와 한계

첫째, 적은 수의 calibration sample에서 계산한 perplexity만으로 강건성을 판단하던 관행에 **과제별 정확도와 표본 간 분포**라는 관점을 더했다. 둘째, 양자화·pruning, base·instruction-tuned 계열, 다섯 출처를 함께 놓아 **민감도가 방법·모델·과제에 따라 달라지는 조건부 현상**임을 보였다. 셋째, 결과를 재현 가능성과 연결해 실제 calibration text 공개, 반복 샘플 평가, 표본 점검을 제안했다. Appendix C의 Tables 5-13은 평균·표준편차를 모델·과제별로 확인할 수 있게 한다.

원문이 명시한 가장 큰 한계는 **모델·calibration corpus·평가 과제가 모두 영어**라는 점이다(Limitations). 영어 밖의 언어 계열과 저자원 환경에서 같은 패턴이 재현되는지는 이 연구로 알 수 없다. 또한 방법은 네 가지, 모델은 세 계열의 2024년 설정이며, 2:4 sparsity와 4-bit weight 조건을 벗어난 압축률·activation quantization까지 대표하지 않는다. 저자들은 향후 **모델의 training protocol 선택**이 calibration 민감도를 어떻게 바꾸는지, 그리고 다양한 언어에서 어떤 결과가 나오는지 연구 과제로 남겼다(Section 6, Limitations).

**Source Check:** 원문 Appendix C의 소개 문장은 Vicuna를 Figure 6, OPT를 Figure 5로 연결하지만, 실제 그림의 제목·캡션은 **Figure 5 = Vicuna**, **Figure 6 = OPT**다(PDF pp. 12-14). 이 글은 그림 캡션을 기준으로 계열을 표기한다. 이 불일치는 결과 수치의 정정이 아니라 appendix 내 그림 참조의 뒤바뀜이다.

## 6. 한국어 번역형 해설

### 초록·서론을 따라 읽기

논문의 출발점은 거대 모델을 배포하려면 메모리와 계산 부담을 낮춰야 한다는 현실적인 문제다. 이미 학습된 모델을 압축하는 방법은 추가 학습 없이도 작동하지만, 실제로는 몇 개의 비라벨 문장을 먼저 모델에 흘려보낸다. 저자들이 묻는 것은 그 문장을 단순한 준비물로 간주해도 되는가이다. 많은 압축 연구는 임의로 뽑은 웹 문장 몇 묶음이면 충분하다고 보았지만, 이 연구는 같은 압축 절차를 반복하면서 입력 문장만 바꿔 그 전제를 시험한다(Sections 1-2).

### 방법을 따라 읽기

각 층에서 입력 activation은 원 모델과 압축 모델의 출력을 비교하는 기준점이 된다. 그 점들이 calibration text에서 생기므로, 문장 집합을 바꾸면 어떤 압축 가중치가 오차를 작게 만드는지도 달라질 수 있다. 그러나 네 알고리즘은 같은 기준을 구현하지 않는다. GPTQ와 SparseGPT는 Hessian 관련 보정을 사용하고, Wanda는 activation norm과 weight magnitude를 결합하며, SpQR은 큰 outlier를 더 높은 정밀도로 남긴다. 저자들은 이 구조적 차이를 인정한 채 **각 방법 안에서** calibration 입력의 효과를 비교한다(Section 2.1, Appendix A).

### 실험과 결과를 따라 읽기

실험은 아홉 LLM에 네 압축법을 적용하되, calibration의 다섯 출처에서 열 번씩 독립적으로 표본을 구성한다. 동일 출처의 무작위 추출만 바꿔도 일부 과제에서는 넓은 정확도 범위가 생겼다. 출처를 바꾸면 SparseGPT에선 RefinedWeb이 자주 유리했으나 Wanda의 LLaMA-7B 사례는 그 순서를 뒤집었다. 양자화의 출처 간 차이는 상대적으로 작았다. 표본을 더 늘리는 실험에서는 많은 방법이 일찍 평탄해졌지만 SparseGPT에는 추가 이득이 남았다. 가장 중요한 평가상의 경고는, WikiText perplexity가 거의 흔들리지 않아도 BoolQ 같은 과제의 정확도는 넓게 달라질 수 있다는 점이다(Sections 3-4, Figures 2-4, Tables 1-2).

### 결론·한계를 따라 읽기

저자들은 하나의 마법 같은 corpus를 지목하지 않는다. 대신 압축 결과가 calibration 선택에 반응하는지 여러 표본과 실제 과제에서 살펴보고, 쓰인 표본을 재현 가능하게 공개하며, 작은 집합에 섞인 이상치를 확인하라고 제안한다. 이 결론은 영어 중심의 세 모델 계열과 네 방법에서 나온 것이다. 다른 언어, 다른 압축 설정, 다른 학습 이력으로 그대로 옮길 수 있는지는 아직 열린 문제다(Sections 5-6, Limitations).

## 마지막 핵심 정리

- **원리:** calibration text → layer activation → 압축 가중치 선택. Calibration은 label로 모델을 재학습하는 단계도, 평가 데이터도 아니다.
- **관찰:** 같은 출처의 다른 표본과 서로 다른 출처 모두 결과에 영향을 줄 수 있지만, 크기와 방향은 방법·모델·과제에 따라 바뀐다.
- **평가:** WikiText perplexity와 실제 downstream 정확도를 함께 보고, 평균뿐 아니라 반복 표본의 분산·범위를 확인한다.
- **경계:** 네 압축법의 특정 4-bit/2:4·영어 평가 설정에서 얻은 결과이며, 보편적 corpus 순위나 serving 성능의 증명은 아니다.

## 세미나 강의자료

슬라이드와 함께 학습 원고·발표자 노트를 볼 수 있습니다.

| 자료 | 분량 | PDF | PowerPoint | 학습 원고 | 발표자 노트 |
| --- | ---: | --- | --- | --- | --- |
| 한국어 강의 | 20장 | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/calibration-impact-seminar-ko-v1.pdf" target="_blank" rel="noopener">View PDF</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/calibration-impact-seminar-ko-v1.pptx" download>Download PPTX</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/slides-v1.md.txt" download="slides-v1.md">Download script</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/presenter-notes-v1.md.txt" download="presenter-notes-v1.md">Download notes</a> |

## 참고자료

- [ACL Anthology — published paper and source PDF](https://aclanthology.org/2024.acl-long.544/){:target="_blank" rel="noopener"}
- [arXiv v2 — author version](https://arxiv.org/abs/2311.09755v2){:target="_blank" rel="noopener"}
