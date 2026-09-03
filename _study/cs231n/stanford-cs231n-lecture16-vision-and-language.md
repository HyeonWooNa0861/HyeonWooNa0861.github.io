---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 16: Vision and Language"
course: "CS231N"
topic: "Vision-Language Models"
order: 16
major_topic: "Computer Vision"
keywords:
  - "Vision-Language"
  - "CLIP"
  - "Image Captioning"
  - "Visual Question Answering"
  - "Multimodal Models"
---

# Stanford CS231N Lecture 16: Vision and Language

Source: [Stanford CS231N Spring 2025 Lecture 16](https://www.youtube.com/watch?v=mQOK0Mfyrkk){:target="_blank" rel="noopener"}

> **핵심:** Vision-language foundation model의 능력은 단순히 모델을 크게 만든 결과가 아니다. **어떤 image-text supervision을 수집하고, global alignment를 넘어 region·point grounding을 어떻게 가르치며, 다른 도구와 어떻게 연결하는가**가 실제 유용성과 신뢰성을 결정한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Foundation models | 왜 하나의 task가 아니라 transferable representation을 학습하는가? |
| 2 | CLIP | Image와 text를 같은 공간에 어떻게 정렬하는가? |
| 3 | LLaVA and Flamingo | Visual token을 입력에 붙일지, layer마다 cross-attend할지? |
| 4 | Molmo and pointing | 위치를 가리키는 supervision이 왜 중요한가? |
| 5 | SAM/SAM2 and chaining | Promptable image·video segmentation을 다른 model과 어떻게 연결하는가? |
| 6 | Evaluation | Foundation model의 실제 능력을 어떻게 검증하는가? |

## 1. Foundation model의 범위

전통적 computer vision model은 한 dataset의 고정 label을 예측했다. Foundation model은 훨씬 넓은 data와 objective로 pretrain한 뒤 classification, retrieval, captioning, VQA, segmentation 같은 여러 task에 adapt한다. 강의는 단일 benchmark의 높은 숫자보다 distribution shift와 새로운 개념에 대한 generalization을 평가해야 한다고 강조한다.

Web-scale image-text pair는 class label보다 풍부하지만 noisy하고 편향되어 있다. Caption은 이미지 전체의 요약에 강한 반면 작은 object의 위치, 객체 간 관계, counting 같은 세밀한 정보는 빠뜨릴 수 있다. Data scale만 키워도 supervision이 말하지 않은 구조가 자동으로 생기지는 않는다.

## 2. CLIP의 contrastive image-text alignment

CLIP은 image encoder와 text encoder가 paired sample을 가까이, batch의 다른 조합을 멀리 배치하도록 학습한다. 정규화한 image embedding \(v_i\), text embedding \(t_j\), temperature \(\tau\)로 similarity logit을

$$
\ell_{ij}=\frac{v_i^\top t_j}{\tau}
$$

로 만들고 image-to-text와 text-to-image cross-entropy를 대칭적으로 적용한다. 추론에서는 class 이름을 prompt로 text embedding으로 만들고 이미지와 가장 가까운 label을 골라 zero-shot classification을 할 수 있다.

장점은 training objective가 단순하고 retrieval·zero-shot transfer에 재사용하기 쉽다는 점이다. 한계는 global embedding 하나가 “무엇이 어디에 있고 어떤 관계인가”를 압축한다는 것이다. 강의의 compositionality 사례처럼 같은 단어가 있어도 관계가 뒤바뀐 문장을 잘 구별하지 못할 수 있다.

## 3. Visual token을 language model에 넣기

Multimodal language model은 pretrained vision encoder의 patch feature를 projection layer로 language-model embedding 차원에 맞춰 token sequence에 삽입한다. LLaVA 계열처럼 CLIP encoder와 LLM을 connector로 잇고 image instruction data로 tuning하면 대화형 VQA와 설명 생성이 가능해진다.

이 구조는 language model의 지식과 in-context 능력을 활용하지만 시각 encoder에 없는 정보는 connector가 복원할 수 없다. Image-level caption만으로 학습하면 정교한 localization이 약하고, 그럴듯한 language prior가 실제 image evidence보다 앞서 hallucination을 만들 수 있다.

**Flamingo**는 LLaVA처럼 projected visual token을 입력 앞에 한 번 붙이는 대신, vision encoder의 feature를 LLM의 각 layer에 gated cross-attention으로 주입한다. Perceiver sampler가 image feature를 고정된 수의 token으로 줄이고, frozen vision encoder와 frozen LLM 사이에서 sampler와 cross-attention module만 학습한다. 각 language layer가 필요한 시점에 image feature를 선택할 수 있고, 여러 image-text interleaved sequence로 학습해 multi-turn dialogue와 visual in-context learning을 지원한다.

## 4. Molmo: 답변뿐 아니라 위치를 가리키기

강의는 open multimodal model인 Molmo를 중심 사례로 다룬다. 핵심 supervision은 자세한 image description과 **pointing data**다. Model이 object를 언어로만 언급하는 데 그치지 않고 image coordinate의 point sequence로 가리키도록 학습하면 답이 어떤 시각 근거에 연결되는지 확인할 수 있다.

Pointing은 object counting에서도 유용하다. 각 instance를 순서대로 가리키면 최종 숫자만 내는 것보다 중복·누락을 점검할 중간 표현이 생긴다. 이는 hallucination을 완전히 없애지는 않지만 language answer와 visual evidence 사이의 연결을 강화한다.

## 5. Model chaining과 broader foundation models

**Segment Anything Model(SAM)**은 image encoder, point·box·text를 받는 prompt encoder, mask decoder로 구성된 promptable segmentation model이다. 하나의 point가 물체 전체, 부분, 서로 겹친 대상 중 무엇을 뜻하는지 모호하므로 세 가지 granularity의 mask를 출력하고 ground truth에 가장 가까운 후보로 loss를 계산한다. 이 구조는 하나의 고정 category set보다 사용자가 지정한 대상을 자르는 범용 interface를 목표로 한다.

Point output은 다른 model의 prompt가 될 수 있다. 강의의 구체적 chain은 Molmo가 cricket bat의 point를 찾고, **SAM 2**가 그 point를 받아 시간축 전체의 mask로 추적하는 방식이다. 같은 원리로 Molmo가 water bottle 위치를 찾고 motion planner가 robot arm의 경로를 만들 수 있다. CLIP, multimodal LLM, segmentation foundation model을 연결하면 개별 모델의 고정 output을 더 정밀한 system 행동으로 바꿀 수 있다.

평가도 classification accuracy 하나로 끝나지 않는다. VQA, counting, spatial relation, grounding, compositionality, real-user preference를 함께 봐야 한다. Benchmark contamination과 narrow metric 때문에 숫자가 실제 사용 능력을 과장할 수 있으므로 정성적 실패 분석이 병행되어야 한다.

## 마지막 핵심 정리

- CLIP은 contrastive objective로 global image-text alignment를 학습한다.
- Multimodal LLM은 visual feature를 token으로 LLM에 연결하지만 encoder와 data의 한계도 함께 물려받는다.
- Flamingo는 perceiver sampler와 gated cross-attention으로 각 LLM layer가 visual feature를 선택하게 한다.
- **Point grounding은 말과 image evidence를 연결**해 counting·localization·tool chaining을 돕는다.
- SAM은 point·box·text prompt를 mask로 바꾸며, SAM 2는 Molmo의 point를 video segmentation으로 확장할 수 있다.
- Foundation model은 단일 점수가 아니라 transfer, composition, grounding, hallucination을 함께 평가해야 한다.

## Study Guide

`CLIP dual encoder → visual-token LLM → grounded pointing → model chaining`의 interface 변화를 따라간다. 각 단계에서 입력·출력과 supervision 단위가 global pair인지, token인지, coordinate인지 구분하면 발전 이유를 이해하기 쉽다.

## 복습 질문

<details><summary>1. CLIP이 zero-shot classification을 할 수 있는 이유는?</summary>

답변: Class 이름이나 설명을 text encoder로 embedding하고, 학습 때 정렬한 공통 공간에서 image embedding과 similarity를 비교할 수 있기 때문이다.
</details>

<details><summary>2. Global image-text alignment가 spatial reasoning에 부족한 이유는?</summary>

답변: 이미지 전체와 문장 전체를 한 vector로 맞추면 개별 object의 위치와 관계를 직접 감독하지 않으므로 같은 단어를 가진 서로 다른 구성을 구분하기 어렵다.
</details>

<details><summary>3. Pointing output은 model chaining에 어떻게 쓰이는가?</summary>

답변: Multimodal model이 자연어 지시에서 찾은 coordinate를 segmentation이나 robot planning 같은 다른 model의 입력 prompt로 전달해 더 정밀한 행동으로 바꿀 수 있다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=mQOK0Mfyrkk){:target="_blank" rel="noopener"}
