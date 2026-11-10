---
layout: default
date: 2026-11-10 15:40:00 +0900
title: "GenQ"
topic: "Generative synthetic data for quantization in low-data regimes"
order: 88
major_topic: "Machine Learning & Data Curation"
keywords:
  - "GenQ"
  - "data-free quantization"
  - "data-scarce quantization"
  - "synthetic calibration data"
  - "Stable Diffusion"
  - "PTQ"
  - "QAT"
---

# GenQ: Quantization in Low Data Regimes with Generative Synthetic Data

Source PDF: `genq.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | GenQ: Quantization in Low Data Regimes with Generative Synthetic Data |
| 저자 | Yuhang Li, Youngeun Kim, Donghyun Lee, Souvik Kundu, Priyadarshini Panda |
| 출처 | ECCV 2024, arXiv:2312.05272v3 |
| 대상 | ImageNet 분류 모델의 data-free·data-scarce PTQ/QAT |
| 생성 모델 | Stable Diffusion v1-5 |
| 핵심 방법 | class prompt로 후보 이미지를 생성하고, full-precision 모델의 통계로 후보를 걸러 양자화에 사용 |

## 한 줄 요약

GenQ는 원본 학습 데이터가 없거나 극히 적을 때 text-to-image diffusion model로 합성 이미지를 만들고, 모델·구조별 필터로 양자화에 유용한 샘플을 남겨 PTQ와 QAT의 정확도를 회복하는 방법이다.

## 핵심 내용

- **생성과 선택을 분리한다.** Stable Diffusion은 class label로 넓은 후보군을 만들고, full-precision 모델은 그중 원래 데이터 분포에 가까운 후보를 선택한다.
- **모델 구조에 맞춰 두 번째 필터를 바꾼다.** CNN은 BatchNorm 통계를, BN이 없는 ViT는 patch similarity의 다양성을 사용한다.
- **real data가 조금 있으면 소수 이미지를 단순 복제하지 않는다.** 여러 class의 샘플로 하나의 learnable token을 학습해 데이터셋의 공통 style을 prompt에 주입한다.
- **합성 데이터는 특정 양자화기 하나에 묶이지 않는다.** 논문은 BRECQ·Genie-M 기반 PTQ와 LSQ 기반 QAT, CNN과 ViT에서 같은 데이터 파이프라인을 평가한다.
- **가장 강한 결과는 낮은 bit와 취약한 구조에서 나타난다.** W3A3 QAT와 lightweight CNN에서 기존 합성 방식과의 차이가 특히 컸다. 다만 모든 모델에서 real data를 일관되게 앞선 것은 아니다.

## 전체 흐름

| 단계 | 입력 | 처리 | 출력 |
|---|---|---|---|
| 선택적 사전 단계 | class별 소수 real image | dataset style token을 textual inversion 방식으로 학습 | data-scarce prompt |
| 1. 후보 생성 | class label, prompt template, 선택적 style token | Stable Diffusion v1-5로 class별 이미지 생성 | 실제처럼 보이지만 distribution shift가 섞인 후보군 |
| 2. 공통 필터 | full-precision 모델 logits | energy score로 in-distribution 후보 선별 | 의미적으로 더 그럴듯한 후보 |
| 3. 구조별 필터 | CNN의 BN 통계 또는 ViT patch feature | BN sensitivity 또는 patch-similarity entropy로 추가 선별 | 양자화용 합성 데이터 |
| 4. 양자화 | 선별된 합성 데이터 | reconstruction PTQ 또는 PTQ 초기화 QAT | 낮은 bit의 CNN·ViT |

## 1. 왜 양자화에 데이터가 필요한가

양자화는 full-precision weight $$\mathbf{w}$$를 제한된 정수 구간에 매핑한다. step size를 $$s$$, zero point를 $$\mathbf{z}$$라 하면 기본 형태는 다음과 같다.

$$
\mathbf{w}_{\mathrm{int}}
=
\mathrm{clip}\left(
\left\lfloor \frac{\mathbf{w}}{s}\right\rceil + \mathbf{z},
n,
p
\right)
$$

$$
\mathbf{w}^{q}=s\left(\mathbf{w}_{\mathrm{int}}-\mathbf{z}\right)
$$

정수로 반올림하면 activation이 원 모델과 달라진다. PTQ는 소량의 calibration data로 layer나 block의 출력 오차를 줄이도록 step size와 rounding을 조정한다. QAT는 forward pass에서 양자화를 모사한 채 weight와 quantization parameter를 end-to-end로 학습하므로 더 많은 데이터와 연산이 필요하다.

문제는 원 학습 데이터가 개인정보, 저작권, IP 보호 때문에 배포 환경에 없을 수 있다는 점이다. 기존 data-free quantization은 대체로 두 경로를 썼다.

| 기존 경로 | 작동 방식 | GenQ가 지적하는 제약 |
|---|---|---|
| Image inversion | pretrained model의 BN 통계나 activation을 목표로 픽셀을 직접 최적화 | 고차원 이미지 역문제가 느리고, BN이 없는 ViT에 적용하기 어렵다 |
| GAN 기반 생성 | generator와 quantized model을 함께 학습 | 생성기가 모델·과업에 결합되어 재사용성이 낮을 수 있다 |

GenQ의 선택은 이미 대규모 이미지 생성 능력을 가진 diffusion model을 외부 생성기로 쓰는 것이다. 다만 생성 이미지가 사진처럼 자연스럽다는 사실만으로 양자화에 적합하지는 않다. 그래서 **생성 품질**과 **원 학습 분포에 대한 적합성**을 별도 문제로 다룬다.

## 2. Data-Free GenQ

### 2.1 Class label에서 후보 이미지 만들기

ImageNet-1k의 class 이름만 사용할 수 있다고 하자. GenQ는 `photo of a {class}`, `cropped photo of the {class}`, `photo of a small {class}` 같은 27개 template에서 prompt를 만들고 Stable Diffusion으로 이미지를 생성한다. 생성 단계에서는 양자화 대상 모델을 사용하지 않으므로 같은 후보군을 여러 구조에 재사용할 수 있다.

하지만 prompt는 원 ImageNet의 촬영 조건, 배경, object scale, class별 편향을 알지 못한다. 생성된 `hamster`가 시각적으로 훌륭해도 원 모델이 학습한 hamster 분포와 다르면 calibration activation을 잘 대표하지 못할 수 있다. 이 차이를 줄이는 단계가 model-dependent selection이다.

![GenQ의 생성·필터링 파이프라인]({{ "/assets/images/research/genq/genq-figure-2.png" | relative_url }})

그림은 두 경로를 함께 보여준다. Data-free 경로는 class label로 바로 이미지를 생성한다. Data-scarce 경로는 소수의 real image로 prompt token을 먼저 학습한다. 두 경로 모두 생성 뒤에 같은 공통 필터와 구조별 필터를 거친다.

### 2.2 첫 번째 필터: energy score

합성 이미지를 full-precision classifier에 넣고 logits에서 energy score를 계산한다. Logit은 softmax로 확률을 만들기 전의 class별 원시 점수다. OOD detection의 표준 energy는 temperature $$\alpha$$와 class logit $$f_i(\mathbf{x})$$에 대해 다음과 같은 log-sum-exp 형태다.

$$
E(\mathbf{x};f)
=
-\alpha\log\sum_{i=1}^{C}
\exp\left(\frac{f_i(\mathbf{x})}{\alpha}\right)
$$

논문의 선택 논리는 낮은 energy를 보이는 이미지를 원 분포에 가까운 후보로 간주하는 것이다. 이 단계는 CNN과 ViT에 공통으로 적용된다. 단, 원문 Eq. (5)의 표기에는 확인이 필요한 불일치가 있어 아래 `Source Check`에서 별도로 다룬다.

### 2.3 CNN 필터: BatchNorm distance와 sensitivity

CNN의 BatchNorm layer에는 학습 데이터에서 누적한 channel별 running mean $$\mu_{\ell}$$와 variance $$\sigma_{\ell}$$가 남아 있다. 합성 batch의 통계 $$\mu_{\ell}^{s},\sigma_{\ell}^{s}$$가 이에 가까우면 원 학습 데이터와 유사한 internal activation을 만든다고 볼 수 있다. 여기서는 원문의 기호와 `variance` 설명을 그대로 따른다.

$$
D_{\mathrm{BN}}
=
\sum_{\ell=1}^{L}
\left(
\left\lVert\mu_{\ell}^{s}-\mu_{\ell}\right\rVert_{F}
+
\left\lVert\sigma_{\ell}^{s}-\sigma_{\ell}\right\rVert_{F}
\right)
$$

한 이미지씩 BN distance를 계산하면 batch interaction을 잃는다. GenQ는 이미지 $$\mathbf{x}_i$$를 batch에서 제거하기 전후의 거리를 비교한다.

$$
S(\mathbf{x}_i)
=
D_{\mathrm{BN}}\left(\{\mathbf{x}_j\}_{j=1}^{B}\right)
-
D_{\mathrm{BN}}\left(\{\mathbf{x}_j\}_{j=1,\,j\neq i}^{B}\right)
$$

제거했을 때 BN distance가 크게 줄면 해당 이미지가 batch의 internal distribution을 더 많이 흐트러뜨린다는 뜻이다. GenQ는 이런 이미지의 우선순위를 낮춘다. 이 leave-one-out 정의는 개별 이미지 점수이면서도 batch 문맥을 반영한다.

### 2.4 ViT 필터: patch similarity diversity

ViT에는 BatchNorm running statistics가 없으므로 같은 지표를 쓸 수 없다. GenQ는 output feature의 patch pair 사이 cosine similarity를 계산한다.

$$
\Gamma(\mathbf{o}_i,\mathbf{o}_j)
=
\frac{\mathbf{o}_i\cdot\mathbf{o}_j}
{\left\lVert\mathbf{o}_i\right\rVert_2
\left\lVert\mathbf{o}_j\right\rVert_2}
$$

모든 patch pair로 만든 similarity distribution에 kernel density estimation을 적용하고 differential entropy를 구한다.

$$
H=-\int \hat{f}_{h}(x)\log \hat{f}_{h}(x)\,dx
$$

낮은 entropy는 patch 관계가 한정된 패턴에 몰렸음을 뜻한다. GenQ는 energy filtering 뒤에 patch similarity가 더 다양한 이미지를 남긴다. 즉, **공통 필터는 class-level plausibility를, 구조별 필터는 internal feature 통계를 보완한다.**

## 3. Data-Scarce GenQ

Data-scarce 설정은 class마다 real image 한 장, ImageNet-1k 전체로 1,000장을 사용할 수 있다고 가정한다. 단순히 이 1,000장만 QAT에 반복 사용하면 데이터 다양성이 부족하다. GenQ는 소수 샘플을 직접 복제하는 대신, 데이터셋의 공통 특성을 나타내는 learnable text token $$\{S\}$$를 학습한다.

class $$C_{[i]}$$의 prompt는 개념적으로 다음 형태다.

```text
A photo of a {class C[i]} in the style of {S}
```

Stable Diffusion의 encoder, decoder, text encoder, denoising U-Net은 고정한다. 각 real image에 noise를 넣고 이를 복원하는 diffusion loss를 줄이되 token embedding만 갱신한다.

$$
\mathbb{E}_{
t\sim\mathcal{U}(1,T),\,
i\sim\mathcal{U}(1,M),\,
\epsilon\sim\mathcal{N}(\mathbf{0},\mathbf{I})
}
\lambda(t)
\left\lVert
\epsilon-\epsilon_{\theta}
\left(\mathbf{x}_{[i]t},t,\mathrm{Prompt}_{[i]}\right)
\right\rVert_F^{2}
$$

원래 textual inversion이 소수 이미지에서 특정 object의 token을 찾는다면, GenQ는 여러 class를 섞어 ImageNet 전체에 공통인 distribution characteristic을 하나의 token에 담으려 한다. 부록 설정은 50,000 iteration, batch size 32, Adam, learning rate $$5\times10^{-4}$$다. 학습한 token으로 새 이미지를 생성한 뒤 data-free와 같은 필터를 적용한다.

이 설계의 의미는 real data를 양자화기에 직접 공급하는 데 그치지 않고 **생성 분포의 방향을 정하는 신호**로 증폭한다는 데 있다. 반면 한 token이 복잡한 dataset bias를 충분히 표현하는지는 별도 한계로 남는다.

## 4. 합성 데이터로 PTQ와 QAT 수행하기

PTQ에서는 선별된 합성 이미지를 BRECQ나 Genie-M 같은 reconstruction-based rounding optimization에 넣는다. QAT는 PTQ 결과에서 시작한다. PTQ가 학습한 rounding variable $$\mathbf{v}$$와 weight $$\mathbf{w}$$를 고정하고, 0으로 초기화한 보정 변수 $$\mathbf{u}$$만 추가한다.

$$
\mathbf{w}_{\mathrm{int}}
=
\mathrm{clip}\left(
\left\lfloor\frac{\mathbf{w}}{s}\right\rfloor
+\mathrm{sgn}(\mathbf{v})
+\left\lfloor\frac{\mathbf{u}}{s}\right\rceil
+\mathbf{z},n,p
\right)
$$

PTQ에서 이미 찾은 rounding 결정을 출발점으로 유지하면서 $$\mathbf{u}$$를 STE로 업데이트한다. 처음부터 양자화 모델 전체를 흔드는 대신 검증된 PTQ 해 주변에서 보정하므로 QAT 초기화가 안정적이라는 논리다. Data-free PTQ·QAT에서는 GenQ synthetic data만 사용한다. Data-scarce QAT 실험은 예외적으로 1,000장의 real data로 Genie-M PTQ 초기화를 만든 뒤, real-only 조건과 GenQ 보강 조건을 비교한다.

## 5. 실험 설정

모든 정확도는 ImageNet top-1 accuracy다. 기본 생성기는 Stable Diffusion v1-5, guidance scale은 3.5다. W4A4에서 `W`는 weight bit, `A`는 activation bit를 뜻하므로 W2A4는 weight를 2-bit, activation을 4-bit로 양자화한 설정이다.

| 설정 | 데이터와 양자화 조건 |
|---|---|
| Data-free CNN PTQ | 합성 2,048장을 만들고 50%를 걸러 1,024장 사용; BRECQ·Genie-M; W4A4와 W2A4 |
| Data-free ViT PTQ | 합성 64장을 만들고 50%를 걸러 32장 사용; PTQ4ViT·RepQ-ViT; W4A4 |
| Data-free CNN QAT | class당 1,600장, 총 1.6M장을 만든 뒤 0.4M장을 제거해 1.2M장 사용; 50 epoch SGD |
| Data-scarce CNN QAT | ResNet-50 W3A3; real-only는 1·10·100·300·1,200장/class, GenQ 보강은 1·10·100장/class 조건에서 비교 |

생성 비용 비교는 ResNet-50을 필터 또는 optimization 모델로 사용해 ImageNet 이미지 1,000장을 만드는 시간을 측정했다.

| 방법 | 생성 방식 | 1,000장 시간 | 다른 모델 재사용 |
|---|---|---:|---|
| Genie | Image inversion | 152분 | 가능 |
| TexQ | GAN | 10분 | 불가능 |
| GenQ | Text-to-image | 24분 | 가능 |

GenQ는 TexQ보다 느리지만 Table 1의 Genie보다 약 6.3배 빠르다. 논문 서론은 최대 15배를 주장하며 Figure 1의 GenQ 시간은 10분으로 표시돼 Table 1의 24분과 다르다. 원문은 이 차이의 조건을 해명하지 않으므로 이 글의 직접 비교는 측정 조건을 설명한 Table 1을 기준으로 한다. 재사용성은 생성 시간이 가장 짧은 방법만 고르는 것과 다른 축이다.

## 6. 주요 결과

### 6.1 Data-free PTQ: 낮은 bit와 lightweight CNN에서 큰 차이

BRECQ W2A4에서 GenQ와 Genie-D의 결과를 비교하면 다음과 같다(원문 Table 2).

| Model | Genie-D | GenQ | 차이 |
|---|---:|---:|---:|
| ResNet-18 | 63.93 | 65.04 | +1.11%p |
| ResNet-50 | 69.72 | 69.90 | +0.18%p |
| MobileNetV2 | 49.75 | 53.08 | +3.33%p |
| MobileNet-b | 38.01 | 47.31 | +9.30%p |
| MnasNet-1 | 45.53 | 50.84 | +5.31%p |

ResNet에서는 차이가 작지만 MobileNet·MnasNet 계열에서는 커진다. 논문은 lightweight model이 quantization error에 덜 견고하기 때문에 더 나은 합성 데이터의 효과가 커졌다고 해석한다. 다만 Genie-M W4A4 ResNet-50에서는 Genie-D가 75.61%, GenQ가 75.50%다. 따라서 “모든 구조와 설정에서 GenQ가 우세하다”는 결론은 표가 지지하지 않는다.

ViT W4A4에서도 GenQ는 PSAQ-ViT보다 높은 결과를 보였다(원문 Table 4). RepQ-ViT 기준 ViT-B는 60.18%에서 67.50%, Swin-B는 54.21%에서 70.08%로 증가했다. real data 기준은 각각 67.93%, 72.80%여서 GenQ가 ViT-B에서는 근접하지만 Swin-B에는 2.72%p 차이가 남는다.

### 6.2 Data-free QAT: W3A3에서 격차가 확대된다

원문 Table 3의 대표 수치를 비교하면 다음과 같다.

| Model | Bit | TexQ | GenQ | Real-data LSQ |
|---|---|---:|---:|---:|
| ResNet-18 | W4A4 | 67.73 | 70.03 | 71.10 |
| MobileNetV2 | W4A4 | 67.07 | 69.65 | 69.50 |
| ResNet-50 | W4A4 | 70.72 | 76.10 | 76.70 |
| ResNet-18 | W3A3 | 50.28 | 68.18 | 70.20 |
| MobileNetV2 | W3A3 | 32.80 | 59.15 | 65.30 |
| ResNet-50 | W3A3 | 25.27 | 73.99 | 75.80 |

W4A4에서는 GenQ가 real-data LSQ에 근접하고 MobileNetV2에서는 표의 LSQ보다 0.15%p 높다. W3A3에서는 기존 data-free QAT가 크게 무너지는 반면 GenQ가 상당 부분을 회복한다. ResNet-50의 TexQ 대비 차이는 48.72%p다. 이것은 상대 개선율 48%가 아니라 top-1 accuracy의 절대 percentage-point 차이다.

### 6.3 Data-scarce QAT: 1-shot 정보를 생성에 증폭한다

ResNet-50 W3A3에서 class당 real image 한 장만 쓰면 67.45%였다(원문 Figure 4). 같은 1-shot real data로 token을 학습하고 GenQ 합성 데이터를 보강하면 68.88%가 됐다. 논문 그림에서 real data만 class당 300장 쓴 결과는 69.13%다. 즉, GenQ가 300배의 real data를 완전히 대체했다기보다 **1-shot 보강 결과가 300-shot real-only 결과에 0.25%p까지 접근했다**고 읽는 편이 정확하다.

### 6.4 Transferability: 생성과 필터의 결합 정도가 다르다

W2A4 교차 모델 평가에서 GenQ 후보를 다른 source model로 필터링해도 target ResNet-18 정확도는 65.44–65.72%, MobileNetV2는 54.24–54.82% 범위였다(원문 Table 5). 기존 Genie-D·PSAQ-ViT 데이터는 source와 target 구조가 달라질 때 더 크게 하락했다. 특히 ViT-B-16 기반 PSAQ-ViT 데이터를 MobileNetV2에 쓰면 17.96%였다.

이 결과는 diffusion generator가 양자화 대상 모델에서 분리되어 있다는 설계와 맞닿는다. 그러나 실험은 ImageNet과 세 source 구조 안에서 수행됐으므로 다른 dataset, 생성기, domain에서도 같은 transferability가 유지된다고 확대할 수는 없다.

## 7. Ablation이 알려주는 것

### 합성 데이터 수

ResNet-50 W2A4의 GenQ 정확도는 합성 이미지 512·1,024·2,048·4,096장에서 각각 69.78·70.36·70.92·71.23%로 증가했다(원문 Figure 5). 원문은 4,096장 조건이 real image 1,024장으로 최적화한 PTQ baseline을 앞섰다고 보고한다. Figure 5의 real-data 수평선에는 별도 수치 label이 없어 차이를 임의로 계산하지 않는다. 이 결과는 더 많은 후보가 도움이 될 수 있음을 보이지만, 합성·필터 비용과 데이터 수가 함께 늘어난 비교다.

### 필터 강도

Energy filter는 제거 비율 0.1에서 0.9로 높일수록 대체로 개선됐지만 전체 정확도 변화는 작았다(원문 Figure 6(a)). 최종 $$N$$장을 남기면서 제거 비율을 $$r$$로 정하면 생성해야 하는 수는 $$N/(1-r)$$이므로 높은 비율은 비용을 급격히 늘린다.

BN sensitivity는 50% 제거에서 65.65%로 가장 좋았고, 90%에서는 65.13%로 하락했다. 이 수치는 원문 Figure 6(b)의 각 label을 직접 읽은 값이다. 논문은 너무 강한 필터가 데이터 다양성을 없앨 수 있다고 해석한다. 좋은 샘플만 남기는 것과 충분히 넓은 activation pattern을 유지하는 것 사이에 절충이 있다.

## 8. 논문의 핵심 기여

1. Text-to-image diffusion model을 data-free quantization용 데이터 생성기로 사용하고, 생성기와 양자화 대상 모델의 역할을 분리했다.
2. Energy score 뒤에 CNN용 BN sensitivity와 ViT용 patch-similarity diversity를 연결해 구조 차이를 처리했다.
3. 소수 real image를 dataset-level token으로 바꾸는 data-scarce 경로를 제안했다.
4. PTQ·QAT, CNN·ViT, 2–4 bit 설정에서 생성 비용, 정확도, transferability, 필터 강도를 함께 평가했다.

## 9. 해석 포인트

- GenQ의 핵심은 diffusion model 자체보다 **외부 생성기의 prior와 대상 모델의 internal statistics를 결합하는 선택 구조**다.
- Data-free는 real image를 쓰지 않는다는 뜻이지, 외부 데이터로 학습된 생성기까지 포함해 아무 데이터 지식도 쓰지 않는다는 뜻은 아니다. Stable Diffusion이 가진 visual prior에 의존한다.
- FID나 사진의 자연스러움이 직접 목적함수는 아니다. 최종 판단 기준은 해당 합성 데이터로 양자화한 모델의 accuracy다.
- 필터는 품질만 올리지 않는다. 필터 강도가 커질수록 후보 생성 비용이 늘고 다양성이 줄 수 있다.
- GenQ는 양자화 algorithm을 대체하지 않는다. BRECQ, Genie-M, PTQ4ViT, RepQ-ViT, LSQ가 실제 quantization update를 담당하고 GenQ는 이들에 공급할 데이터를 만든다.

## 10. 한계와 향후 과제

- 실험이 ImageNet classification에 집중되어 있다. Detection, segmentation, language model처럼 입력과 목적함수가 다른 과업은 별도 검증이 필요하다.
- Stable Diffusion v1-5의 사전학습 분포, class 표현 능력, bias와 라이선스 조건에 의존한다. 희귀 class나 전문 domain에서 prompt만으로 충분한 후보를 만들 수 있는지는 확인되지 않았다.
- Data-scarce의 dataset style을 하나의 token에 압축한다. Class별 특성이나 multimodal distribution을 한 token이 얼마나 보존하는지 분리된 ablation은 없다.
- 합성 1.2M장을 사용하는 QAT는 원본 데이터 접근 문제를 줄이지만 생성·저장·필터 비용을 없애지는 않는다.
- 일부 baseline 수치는 다른 논문에서 가져왔고, 일부는 저자 재구현이다. 모든 비교가 완전히 같은 codebase와 tuning budget에서 실행된 것은 아니다.
- 공개된 공식 code URL은 2026-11-10 확인 시 404를 반환했다. 따라서 이 글은 논문 수식과 표를 검토했으며 실제 implementation path까지 확인했다고 주장하지 않는다.

## Source Check

원문 PDF 21쪽과 arXiv v3 HTML을 대조했다. Eq. (1)의 unsigned $$b$$-bit 상한은 PDF에서 $$2^b-1$$로 정상 표기되어 있다. HTML text extraction에서는 지수가 붙은 수식이 다르게 읽힐 수 있으므로 PDF 화면을 기준으로 확인했다.

원문 Eq. (5)는 다음처럼 적혀 있다.

$$
E_{\mathrm{paper}}(\mathbf{x};f)
=
-\alpha\sum_{i=1}^{C}
\exp\left(-\frac{f_i(\mathbf{x})}{\alpha}\right)
$$

하지만 이 식이 인용한 Liu et al.의 energy-based OOD score는 앞서 설명한 $$-\alpha\log\sum_i\exp(f_i/\alpha)$$ 형태다. 원문 식에는 `log`가 없고 logit 부호도 다르다. 저자 code URL을 현재 열 수 없어 논문 실험이 어느 구현을 사용했는지는 확인하지 못했다. 따라서 본문은 표준 OOD energy 식을 설명하고, GenQ가 실제로 낮은 score 후보를 선택했다는 절차까지만 확정한다. 이 표기 불일치가 실험 결과의 오류였다고 단정하지 않는다.

## 한국어 번역형 해설

이 논문이 해결하려는 문제는 “양자화기는 있는데 원 학습 데이터가 없을 때 무엇으로 보정할 것인가”다. 기존 방식은 모델에 남아 있는 BN 통계를 거꾸로 따라가며 픽셀을 만들거나, quantized model과 함께 GAN을 학습했다. GenQ는 이 생성 문제를 이미 강한 text-to-image diffusion model에 맡긴다.

그 결과 파이프라인의 역할이 명확히 나뉜다. Class label은 무엇을 만들지 지정하고, diffusion model은 다양한 후보를 만든다. Full-precision model은 그 후보가 자신이 학습한 분포와 가까운지 판단한다. CNN에서는 BN 통계, ViT에서는 patch 관계를 이용한다. 생성기는 시각적 prior를 제공하고 대상 모델은 calibration relevance를 제공하는 구조다.

Real image가 class당 한 장이라도 있으면 그 정보는 token embedding 학습에 쓰인다. 이 token은 특정 한 물체를 복원하기보다 ImageNet 전체의 style을 공유 표현으로 담으려 한다. 학습한 token과 class name을 결합하면 소수 이미지의 특징을 반영한 합성 후보를 대량 생성할 수 있다.

실험은 이 데이터가 단순히 보기 좋은지보다 실제 양자화 뒤 정확도를 본다. 4-bit에서는 real-data baseline에 근접하고, 3-bit QAT와 lightweight model에서는 기존 data-free 방식보다 큰 차이를 보였다. 동시에 일부 4-bit ResNet 설정에서는 기존 방식과 비슷하거나 약간 낮았다. 따라서 GenQ의 가치는 항상 우승하는 단일 quantizer가 아니라, 데이터가 부족할 때 여러 quantization method에 공급할 수 있는 생성·선택 계층으로 보는 것이 맞다.

## 핵심 정리

- GenQ는 `class prompt 생성 → energy filtering → 구조별 filtering → PTQ/QAT` 순서로 작동한다.
- CNN은 BN sensitivity, ViT는 patch-similarity entropy로 합성 데이터의 internal distribution 적합성을 본다.
- Data-scarce 설정은 class별 1-shot real image에서 dataset token을 학습해 생성 분포를 조정한다.
- ImageNet에서 W3A3 QAT와 lightweight CNN의 개선이 컸고, real data와의 차이는 설정별로 남았다.
- 결과를 다른 domain으로 확대하려면 생성기 prior, 데이터 규모, 필터 비용, 구현 미확인 수식을 함께 검증해야 한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/genq/genq.pdf" | relative_url }}" target="_blank" rel="noopener">GenQ original paper PDF (unchanged, CC BY-NC-ND 4.0)</a></li>
  <li><a href="https://arxiv.org/abs/2312.05272" target="_blank" rel="noopener">arXiv:2312.05272</a></li>
  <li><a href="https://arxiv.org/html/2312.05272v3" target="_blank" rel="noopener">arXiv v3 HTML</a></li>
  <li><a href="https://github.com/Intelligent-Computing-Lab-Yale/GenQ" target="_blank" rel="noopener">Author-provided code URL (unavailable when checked on 2026-11-10)</a></li>
  <li><a href="https://papers.nips.cc/paper_files/paper/2020/file/f5496252609c43eb8a3d147ab9b9c006-Paper.pdf" target="_blank" rel="noopener">Energy-based Out-of-distribution Detection</a></li>
  <li><a href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank" rel="noopener">CC BY-NC-ND 4.0 license</a></li>
</ul>

The linked paper PDF and extracted Figure 2 are reproduced without modification under CC BY-NC-ND 4.0. Attribution: Yuhang Li, Youngeun Kim, Donghyun Lee, Souvik Kundu, and Priyadarshini Panda, “GenQ: Quantization in Low Data Regimes with Generative Synthetic Data,” ECCV 2024.
