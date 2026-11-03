---
layout: default
date: 2026-11-03 14:47:00 +0900
title: "SAM Category Descriptors"
topic: "Long-tailed nuclei segmentation and classification with low-level domain alignment"
order: 85
major_topic: "Medical Image Analysis"
keywords:
  - "Segment Anything Model"
  - "Nuclei segmentation"
  - "Nuclei classification"
  - "Category descriptors"
  - "Domain alignment"
  - "Long-tailed recognition"
---

# Enhanced Nuclei Segmentation and Classification via Category Descriptors in the SAM Model

Official article: <a href="{{ '/assets/pdfs/research/sam-category-descriptors/sam-category-descriptors.pdf' | relative_url }}" target="_blank" rel="noopener">Original PDF</a> · <a href="https://doi.org/10.3390/bioengineering11030294" target="_blank" rel="noopener">Publisher page and DOI</a> · <a href="https://www.mdpi.com/2306-5354/11/3/294" target="_blank" rel="noopener">MDPI full text</a>

## 논문 정보

| 항목 | 내용 |
|---|---|
| 저자 | Miguel Luna, Philip Chikontwe, Sang Hyun Park |
| 저널 | *Bioengineering* 11(3), 294, 2024 |
| DOI | 10.3390/bioengineering11030294 |
| 데이터 | Lizard: 결장 H&E 영상, 핵 495,179개, 6개 세포 유형 |
| 핵심 방법 | 학습 가능한 category descriptor, 저수준 domain alignment, 장꼬리 손실 |
| 공개 라이선스 | CC BY 4.0 |

## 한 줄 요약

**핵 종류·배경·경계를 나타내는 학습 가능한 prompt와 patch embedding 직후의 저수준 domain alignment를 결합해, SAM의 고수준 표현과 수동 point prompt 능력을 보존하면서 희귀 핵 탐지를 개선한다.**

## 핵심 내용

Lizard의 핵 분포는 심하게 불균형하다. 상피세포·림프구·결합조직이 92.4%를 차지하지만, 형질세포는 5.9%, 호중구와 호산구는 합계 1.7%뿐이다. 일반적인 분할 모델은 빈발 class의 gradient에 끌리거나 다른 도메인으로 이동할 때 희귀 class를 놓치기 쉽다.

이 논문은 SAM 전체를 의료 영상에 맞게 다시 학습하지 않는다. 각 핵 유형뿐 아니라 **배경과 핵 경계**를 표현하는 category descriptor를 prompt token으로 학습한다. 별도 domain alignment module은 **patch embedding 다음, transformer block 이전**에서만 저수준 특징을 바꾼다. 원래 SAM image encoder, prompt encoder, mask decoder는 고정된다. 학습되는 것은 category descriptor와 domain alignment module이다.

논문 초록의 “F1 최대 12% 향상”은 전체 평균 F1이 12%p 상승했다는 뜻이 아니다. 희귀 범주의 특정 비교에서 얻은 최대 개선을 요약한 표현이다. 공통 CoNSeP 검증에서 평균 F1은 0.733이고, 4-fold test 평균은 0.639다.

## 1. 문제: 핵 분할과 분류를 함께 해야 한다

핵 instance segmentation은 각 핵의 경계를 찾는 것만으로 끝나지 않는다. 같은 영역 안에 호중구, 호산구, 형질세포, 결합조직, 림프구, 상피세포가 섞여 있으므로 각 instance에 올바른 class를 붙여야 한다. 이때 세 가지 어려움이 겹친다.

1. 인접한 핵의 경계가 흐리거나 겹친다.
2. 희귀 class는 학습 예제가 매우 적다.
3. SAM은 자연 장면으로 학습됐고, H&E 조직의 색·질감·객체 크기는 다르다.

SAM의 everything mode처럼 일정한 grid point를 넣는 것만으로는 경계가 모호한 조직 영상을 안정적으로 처리하기 어렵다. SAM에는 핵 종류를 분류하는 built-in head도 없다. 논문은 prompt를 수동 입력이 아니라 **class를 지정하는 학습 가능한 기술자**로 바꾼다.

## 2. Category descriptor: class를 prompt token으로 표현한다

SAM은 여러 prompt를 token으로 변환해 mask decoder에 전달한다. 논문은 같은 인터페이스에 다음 범주의 token stack을 학습한다.

- 호중구, 호산구, 형질세포, 결합조직, 림프구, 상피세포
- 배경 조직
- 핵 경계

각 descriptor는 해당 범주가 있는 위치를 활성화한다. 배경과 경계를 따로 예측하면 핵 전경만 찾는 방식보다 맞닿은 instance를 분리하기 쉽다. 여러 범주의 출력 mask를 결합해 최종 instance와 class를 만든다.

![Category descriptor and domain alignment architecture]({{ "/assets/images/research/sam-category-descriptors/figure-1-architecture.png" | relative_url }})

*Figure 1 excerpt. Category descriptor는 세포 유형뿐 아니라 배경과 경계를 위한 mask prompt를 만든다. Domain alignment module은 patch embedding 뒤와 transformer block 앞에 있다. 출처: Luna et al., 2024, Figure 1, CC BY 4.0.*

Figure 1의 눈송이 표시는 고정된 원래 SAM 구성요소를, 불꽃 표시는 학습되는 category prompt encoder와 domain alignment module을 나타낸다. 따라서 “SAM 전체 fine-tuning”이나 “mask decoder fine-tuning”으로 설명하면 구조를 잘못 읽게 된다.

## 3. 저수준 domain alignment

자연 장면과 H&E 영상의 domain gap을 줄이기 위해 transformer 내부의 고수준 feature를 직접 수정할 수도 있다. 그러나 작은 의료 데이터셋에서 많은 고수준 parameter를 바꾸면 과적합하고 SAM의 일반 표현을 잃을 위험이 있다.

논문은 patch embedding 결과에 MobileNetV2식 inverted residual block을 연속 적용한다. 각 block은 96 channel과 3×3 depthwise convolution을 사용한다. 이렇게 변환된 저수준 특징만 기존 transformer block에 전달한다. 목적은 H&E의 색·질감 분포를 SAM이 익숙한 특징 공간에 가까이 옮기면서, transformer가 학습한 객체 표현은 그대로 쓰는 것이다.

Ablation은 alignment의 중요성을 분리해 보여준다. Residual layer가 0개일 때 descriptor를 32개에서 512개로 늘려도 F1은 0.285에서 0.309로만 증가한다. 반면 descriptor 32개를 유지하고 residual layer를 4개로 늘리면 F1은 0.498까지 오른다. **더 많은 prompt token만으로 domain gap을 메울 수 없었다.**

## 4. 장꼬리 학습 목적함수

형태가 비슷한 핵 class는 여러 descriptor를 동시에 활성화할 수 있다. 모든 음성 class를 같은 강도로 억제하면 빈발 class가 만드는 음의 gradient가 희귀 class 학습을 압도한다. 논문은 두 장치를 결합한다.

- 영상에 실제로 존재하는 세포 유형에만 class별 binary cross entropy를 적용한다.
- 여러 descriptor의 점수가 비슷한 hard pixel에 multi-class hinge loss를 적용한다.

Margin은 $$\gamma=0.2$$다. Target class의 확률이 다른 class보다 충분히 높으면 그 쉬운 pixel에서는 추가 gradient를 만들지 않는다. 이 설계는 희귀 class를 무조건 가중하는 방식이 아니라, **현재 영상에 존재하는 class와 실제로 모호한 pixel에 학습 신호를 집중**한다.

## 5. 데이터와 평가

| 항목 | 설정 |
|---|---|
| 영상 | 결장 H&E, 20× objective, 약 0.5 μm/pixel |
| 출처 | CoNSeP, CRAG, DigestPath, GlaS, PanNuke |
| 검증 | CoNSeP 공통 validation |
| Test | 나머지 4개 subset을 순환하는 4-fold cross-validation |
| SAM | ViT-B, 91M parameters |
| 학습 | 20 epochs, Adam, 초기 learning rate $$10^{-3}$$ |
| 입력 | 256×256 random crop, RFS, flip·rotation·color jitter |
| 추론 | 256×256 sliding window, 128-pixel step |
| 지표 | object F1, COCO mAP·mAP50 |

Object F1은 예측과 ground truth를 IoU가 가장 큰 일대일 쌍으로 연결한 뒤 계산한다.

$$
F1=\frac{2TP}{2TP+FP+FN}
$$

mAP는 10개 IoU threshold와 101개 precision-recall interpolation point를 사용하는 COCO 방식이다. F1은 instance detection과 class 배정에 민감하고, mAP는 mask overlap 품질까지 더 엄격하게 반영한다.

## 6. 정량 결과

### 6.1 CoNSeP validation

| 방법 | F1 mean | Neutrophil | Eosinophil | Plasma | mAP | mAP50 |
|---|---:|---:|---:|---:|---:|---:|
| CDNet + Seesaw | 0.671 | 0.443 | 0.690 | 0.574 | 0.295 | 0.545 |
| Mask R-CNN | 0.665 | 0.382 | 0.646 | 0.564 | 0.240 | 0.459 |
| Mask R-CNN + Seesaw | 0.668 | 0.382 | 0.676 | 0.556 | 0.292 | 0.536 |
| **제안 방법** | **0.733** | **0.540** | **0.797** | **0.645** | **0.321** | **0.594** |

희귀 class의 F1과 AP가 가장 크게 개선됐다. 빈발 class에서는 다른 방법이 일부 AP를 앞서기도 했다. 이는 object F1과 pixel-level mask 품질을 포함한 AP가 서로 다른 성질을 측정하기 때문이다.

### 6.2 Four-fold test

| 방법 | F1 mean | mAP | mAP50 |
|---|---:|---:|---:|
| CDNet + ECM | 0.507 | 0.162 | 0.309 |
| CDNet + Seesaw | **0.565** | 0.171 | 0.336 |
| Mask R-CNN | 0.533 | **0.225** | 0.396 |
| Mask R-CNN + Seesaw | 0.521 | 0.220 | 0.390 |
| **제안 방법** | **0.639** | **0.269** | **0.470** |

Subset 사이 domain shift가 커지자 모든 방법의 점수가 낮아졌지만, 제안 방법은 경쟁 최고값보다 F1 mean 0.074, mAP 0.044 높았다. mAP50도 0.470으로 가장 높았다. Wilcoxon signed-rank test의 paired difference는 모든 비교에서 $$p\le0.05$$였다.

![Rare nuclei qualitative comparison]({{ "/assets/images/research/sam-category-descriptors/figure-2-rare-type-comparison.png" | relative_url }})

*Figure 2 excerpt. (a)–(c)는 호중구, (d)–(e)는 호산구가 있는 표본이다. 색은 여섯 핵 유형을 나타낸다. 제안 방법은 희귀 핵을 놓치거나 다른 class로 바꾸는 오류를 줄인다. 출처: Luna et al., 2024, Figure 2, CC BY 4.0.*

## 7. Ablation을 올바르게 읽기

| Residual layers | Descriptors per class | F1 | mAP | 해석 |
|---:|---:|---:|---:|---|
| 0 | 32 | 0.285 | 0.060 | Category descriptor만 사용 |
| 8 | 32 | 0.628 | 0.237 | Alignment의 큰 이득 확인 |
| **12** | **32** | **0.638** | **0.240** | 논문이 선택한 성능·메모리 절충 |
| 16 | 32 | 0.643 | 0.244 | 작은 추가 이득, 더 큰 메모리 비용 |
| 12 | 128 | **0.647** | **0.246** | 표의 raw 최고값, 최종 설정은 아님 |

Table 6의 최고 수치는 12 residual layers와 128 descriptors에서 F1 0.647, mAP 0.246이다. 논문은 최고 수치만 선택하지 않고, 메모리 사용량 증가를 고려해 12 layers와 32 descriptors(F1 0.638, mAP 0.240)를 모든 본 실험에 사용했다.

## 8. 수동 point prompt는 학습 입력이 아니다

Category descriptor와 domain alignment를 학습할 때 수동 point prompt는 사용하지 않았다. Table 7은 학습 후 추론 단계에서만 class별 point를 순차적으로 더한 실험이다. Ground truth로 각 class에서 confidence가 가장 낮은 instance를 골라 point를 추가했으므로, 실제 병리 사용자의 클릭 효율을 직접 측정한 user study는 아니다.

| Class당 point 수 | F1 mean | Neutrophil | Eosinophil | Plasma |
|---:|---:|---:|---:|---:|
| 0 | 0.638 | 0.621 | 0.565 | 0.412 |
| 1 | 0.699 | 0.758 | 0.667 | 0.488 |
| 4 | 0.747 | 0.866 | 0.755 | 0.528 |
| 16 | 0.762 | 0.879 | 0.771 | 0.556 |

희귀 class가 빈발 class보다 크게 개선됐다. 이 결과의 핵심은 “point prompt로 본 모델을 학습했다”가 아니라, **저수준 정렬 뒤에도 SAM의 원래 interactive refinement 능력이 남아 있었다**는 점이다.

## 9. 한계와 일반화 경계

- ViT-B도 91M parameters다. Gigapixel whole-slide image에 적용하려면 계산량과 메모리 비용이 크다.
- 실험은 Lizard의 결장 H&E subset에 한정된다. 다른 장기, 염색법, scanner에서 같은 성능을 보장하지 않는다.
- 형질세포는 빈발 림프구와 형태가 비슷해 호중구·호산구보다 개선폭이 작았다.
- Point prompt 실험은 ground truth로 가장 불확실한 instance를 선택했다. 실제 사용자의 클릭 전략과 시간은 검증하지 않았다.
- 다른 의료 영상으로 확장할 수 있다는 주장은 category descriptor와 목적함수를 다시 설계해야 하는 후속 가설이다.

지식 증류는 whole-slide 배포를 위한 작은 student model을 만드는 후보 방향이다. 또한 형태가 매우 비슷한 핵을 분리하려면 색, 공간 문맥, 세포 주변 구조처럼 SAM의 형태 표현 외 정보를 더 활용할 필요가 있다.

## 논문의 핵심 기여

- 핵 유형·배경·경계를 학습 가능한 SAM prompt로 표현했다.
- Patch embedding 뒤의 저수준 domain alignment로 자연 영상과 H&E의 간격을 줄였다.
- 원래 SAM의 고수준 encoder·prompt encoder·mask decoder를 고정했다.
- 영상에 존재하는 class와 hard pixel에 집중하는 장꼬리 학습 목적함수를 사용했다.
- 희귀 핵의 자동 탐지를 개선하면서 추론 단계의 수동 point prompt 호환성을 유지했다.

## 마지막 핵심 정리

이 논문의 가장 중요한 선택은 SAM을 의료 영상에 맞게 전부 다시 쓰지 않은 것이다. **학습되는 class prompt와 저수준 정렬 모듈만 추가하고, 이미 학습된 고수준 표현과 prompt interface는 보존한다.** 성능 향상도 평균 수치 하나보다 희귀 class, domain shift, interactive refinement의 세 축으로 읽어야 한다.

## 참고자료

<ul>
  <li><a href="https://doi.org/10.3390/bioengineering11030294" target="_blank" rel="noopener">Publisher page and DOI</a></li>
  <li><a href="https://www.mdpi.com/2306-5354/11/3/294" target="_blank" rel="noopener">MDPI full text</a></li>
  <li><a href="https://creativecommons.org/licenses/by/4.0/" target="_blank" rel="noopener">Creative Commons Attribution 4.0 International</a></li>
</ul>

그림 1과 그림 2는 원문의 해당 부분을 해설 목적으로 발췌했다. 저작자 Miguel Luna, Philip Chikontwe, Sang Hyun Park, 2024. 원문과 그림은 CC BY 4.0에 따라 이용했으며, 이 글에서는 웹 표시를 위해 여백만 잘랐다.
