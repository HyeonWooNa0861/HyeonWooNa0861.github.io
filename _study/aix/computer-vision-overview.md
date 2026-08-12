---
layout: default
title: "Computer Vision Overview"
course: "AIX"
topic: "Visual Intelligence and Deep Learning Vision"
order: 3
---

# Computer Vision Overview

Source PDF: `03_Computer_Vision.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Visual intelligence | 픽셀을 의미로 바꾸는 문제는 왜 어려운가? |
| 2 | 고전적 CV | grouping, matching, face detection은 어떤 접근이었는가? |
| 3 | Benchmark | Caltech101, PASCAL VOC, ImageNet은 왜 중요했는가? |
| 4 | CNN 역사 | Neocognitron, LeNet, AlexNet은 어떤 흐름으로 이어지는가? |
| 5 | Vision task | classification 이후 detection, segmentation, video로 어떻게 확장되는가? |
| 6 | Generative vision | DeepDream, style transfer, GAN, diffusion은 무엇을 보여주는가? |
| 7 | 성공 요인 | data, compute, algorithm은 어떤 역할을 했는가? |
| 8 | 한계와 책임 | robustness, bias, safety 문제를 왜 함께 보아야 하는가? |

## 1. Visual Intelligence

Computer vision의 핵심 질문은 픽셀 배열을 의미 있는 정보로 바꾸는 것이다.

```text
image pixels -> objects, scenes, actions, relationships
```

사람에게는 자연스러운 장면 이해가 컴퓨터에는 어렵다. 같은 물체도 조명, 시점, 가림, 배경, 해상도에 따라 픽셀 형태가 크게 달라지기 때문이다.

| 문제 | 예 |
|---|---|
| Appearance variation | 같은 물체가 각도와 조명에 따라 다르게 보인다. |
| Occlusion | 물체 일부가 가려진다. |
| Scale variation | 가까운 물체와 먼 물체의 크기가 다르다. |
| Context reasoning | 픽셀만으로는 관계와 의도를 알기 어렵다. |

## 2. 고전적 Computer Vision

1990년대와 2000년대의 많은 vision 시스템은 사람이 설계한 처리 단계와 feature에 의존했다.

| 접근 | 핵심 아이디어 |
|---|---|
| Grouping | 이미지를 의미 있는 영역으로 나눈 뒤 추론한다. |
| Matching | SIFT 같은 local feature를 추출해 이미지 사이의 대응점을 찾는다. |
| Face detection | Haar-like feature와 cascade classifier처럼 효율적인 detector를 사용한다. |

이 시기의 철학은 대체로 `hand-designed feature -> classifier`였다. 딥러닝 이전에도 machine learning은 사용되었지만, feature 자체는 사람이 강하게 설계하는 경우가 많았다.

## 3. Dataset과 Benchmark

Computer vision이 빠르게 발전한 중요한 이유는 공통 dataset과 benchmark가 생겼기 때문이다.

| Dataset | 의미 |
|---|---|
| Caltech101 | 여러 object category에 대한 classification benchmark |
| PASCAL VOC | classification, detection, segmentation 평가를 대중화 |
| ImageNet | 대규모 image classification과 deep learning 혁신의 촉매 |

Benchmark는 연구자들이 같은 문제를 같은 metric으로 비교하게 해준다. 특히 ImageNet은 데이터 규모와 평가 체계를 통해 high-capacity model을 학습하고 비교할 수 있는 장을 만들었다.

## 4. CNN으로 이어지는 역사

CNN의 아이디어는 갑자기 등장한 것이 아니다.

| 모델/사건 | 핵심 의미 |
|---|---|
| Neocognitron | 생물학적 시각 피질에서 영감을 받은 계층 구조 |
| Backpropagation | 내부 feature를 end-to-end로 학습할 수 있는 방법 |
| LeNet | convolutional network가 실제 image task에 효과적임을 보임 |
| AlexNet | ImageNet에서 deep CNN의 성능을 대중적으로 각인 |

Neocognitron과 AlexNet은 계층적 구조라는 점에서 닮아 있다. 차이는 대규모 데이터, GPU compute, backpropagation을 통한 end-to-end training이 가능해졌다는 점이다.

## 5. CNN의 핵심 직관

이미지는 공간 구조를 가진다. CNN은 이 구조를 이용하기 위해 convolution과 pooling을 사용한다.

| 구성 | 역할 |
|---|---|
| Convolution | 작은 filter를 이미지 전체에 공유하여 local pattern을 찾는다. |
| Weight sharing | 같은 filter를 여러 위치에 적용해 parameter 수를 줄인다. |
| Pooling/stride | 공간 크기를 줄이고 위치 변화에 더 강하게 만든다. |
| Hierarchy | 낮은 layer는 edge, 높은 layer는 object part와 semantic feature를 학습한다. |

이 구조는 이미지에서 locality와 translation invariance를 활용하는 inductive bias다.

## 6. Classification 이후의 Vision Task

Image classification은 이미지 전체에 하나의 label을 붙이는 문제다. 하지만 실제 vision은 더 구조적인 출력을 요구한다.

| Task | 출력 |
|---|---|
| Classification | 이미지 하나의 class label |
| Detection | object class와 bounding box |
| Segmentation | 픽셀 단위 class 또는 instance mask |
| Pose estimation | 사람 또는 물체의 keypoint |
| Video understanding | 시간에 따른 action, event, motion |
| Visual reasoning | object 사이의 관계와 고수준 의미 |

Detection과 segmentation은 "무엇인가"뿐 아니라 "어디에 있는가"를 묻는다. Video는 여기에 시간적 변화와 motion을 추가한다.

## 7. Generative Vision

딥러닝은 인식뿐 아니라 이미지 생성과 편집에서도 큰 변화를 만들었다.

| 기법 | 의미 |
|---|---|
| DeepDream | network가 어떤 pattern을 증폭하는지 시각화 |
| Style transfer | content와 style representation을 분리해 이미지 변환 |
| GAN | generator와 discriminator의 경쟁으로 사실적인 이미지 생성 |
| Text-to-image | 자연어 prompt를 시각 결과로 변환 |
| Diffusion | noise를 점진적으로 제거하며 sample을 생성 |

Generative model은 이미지 분포 자체를 학습한다. 따라서 단일 label 예측보다 데이터의 구조를 더 풍부하게 다룬다.

## 8. Deep Learning 성공 요인

딥러닝의 성공은 한 가지 이유만으로 설명하기 어렵다.

| 요인 | 역할 |
|---|---|
| Data | 큰 모델이 일반화할 수 있는 다양한 예제를 제공 |
| Compute | GPU와 tensor core가 대규모 학습을 가능하게 함 |
| Algorithm | CNN, backpropagation, normalization, optimizer 등 학습 방법 개선 |

세 요소가 함께 맞물릴 때 성능이 급격히 좋아졌다. 데이터만 많거나 모델만 크다고 충분하지 않고, 학습 가능한 구조와 계산 자원이 함께 필요하다.

## 9. 한계와 책임

Computer vision은 의료, 안전, 과학, 보조 기술처럼 큰 가치를 만들 수 있다. 동시에 surveillance, 편향된 face analysis, 고위험 자동화처럼 사람에게 피해를 줄 수도 있다.

| 이슈 | 설명 |
|---|---|
| Robustness | distribution shift와 adversarial case에서 실패할 수 있다. |
| Bias | 데이터 편향이 특정 집단에 불리한 결과를 만들 수 있다. |
| Reasoning | 물리, 상식, 사회적 맥락 이해는 여전히 어렵다. |
| Evaluation | 실제 deployment에서는 benchmark accuracy만으로 부족하다. |

따라서 vision 시스템은 성능뿐 아니라 실패 양상과 사용 맥락을 함께 평가해야 한다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| CNN이 이미지에 잘 맞는 이유는? | locality, weight sharing, spatial hierarchy를 활용하기 때문 |
| ImageNet이 중요했던 이유는? | 대규모 benchmark가 deep CNN 학습과 비교를 가능하게 했기 때문 |
| Detection과 segmentation의 차이는? | box 단위 위치 예측 vs pixel 단위 영역 예측 |
| Diffusion model의 기본 아이디어는? | noise를 추가한 과정을 거꾸로 학습해 sample을 생성 |
| Vision에서 책임 있는 평가가 필요한 이유는? | 실제 오류가 사람과 사회에 직접 영향을 줄 수 있기 때문 |

## 복습 질문

<details>
<summary>1. Hand-crafted feature 기반 vision과 representation learning 기반 vision의 차이를 설명하라.</summary>

답변: hand-crafted feature는 사람이 edge, corner, texture 같은 특징을 설계한 뒤 모델이 이를 사용한다. representation learning은 CNN이나 Transformer가 데이터에서 필요한 feature를 직접 학습한다. 후자는 더 큰 데이터와 compute가 필요하지만 복잡한 시각 패턴을 자동으로 포착할 수 있다.

</details>

<details>
<summary>2. AlexNet이 과거 CNN 아이디어를 다시 강력하게 만든 조건은 무엇인가?</summary>

답변: CNN 아이디어 자체는 오래전부터 있었지만, AlexNet은 대규모 ImageNet 데이터, GPU 학습, ReLU, dropout 같은 실용적 요소가 결합되면서 성능을 크게 끌어올렸다. 즉 모델 구조만이 아니라 데이터와 연산 자원의 성숙이 함께 작용했다.

</details>

<details>
<summary>3. Computer vision에서 bias와 robustness를 별도로 평가해야 하는 이유는 무엇인가?</summary>

답변: 평균 정확도가 높아도 특정 조명, 배경, 인종, 성별, 날씨, 카메라 조건에서 성능이 무너질 수 있다. bias는 데이터나 모델이 특정 분포에 치우친 문제이고, robustness는 분포 변화와 노이즈에도 안정적인지의 문제다. 실제 서비스에서는 둘 다 안전성과 신뢰성에 직접 영향을 준다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/03_Computer_Vision.pdf" | relative_url }}" target="_blank" rel="noopener">03_Computer_Vision.pdf</a></li>
</ul>
