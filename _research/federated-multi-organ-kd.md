---
layout: default
date: 2026-11-03 14:42:22 +0900
title: "Federated Multi-Organ KD"
topic: "Knowledge distillation for federated multi-organ segmentation with partial labels"
order: 86
major_topic: "Medical Image Analysis"
keywords:
  - "Federated learning"
  - "Knowledge distillation"
  - "Multi-organ segmentation"
  - "Partially labeled datasets"
  - "Medical image analysis"
  - "Catastrophic forgetting"
---

# Federated learning with knowledge distillation for multi-organ segmentation with partially labeled datasets

## 논문 정보

| 항목 | 내용 |
|---|---|
| 저자 | Soopil Kim, Heejung Park, Myeongkyun Kang, Kyong Hwan Jin, Ehsan Adeli, Kilian M. Pohl, Sang Hyun Park |
| 저널 | *Medical Image Analysis* 95 (2024), Article 103156 |
| DOI | 10.1016/j.media.2024.103156 |
| 온라인 공개 | 2024-03-25 |
| 연구 대상 | 기관마다 장기·종양 label이 다른 복부 CT를 이용한 federated multi-organ segmentation |

## 한 줄 요약

**각 client가 가진 label만으로 local update를 하면 다른 장기 지식이 사라진다. 이 논문은 global model과 장기별 사전학습 모델을 teacher로 사용해 미표기 head의 예측을 보존하고, 공유 U-Net에 가벼운 multi-head를 붙여 한 번의 추론으로 여러 장기를 분할한다.**

## 핵심 내용

문제는 단순한 데이터 부족이 아니다. 기관마다 촬영 분포가 다르고, 어떤 곳은 간·간종양만, 다른 곳은 신장·신장종양만 주석한다. FedAvg는 데이터 자체를 모으지 않고 model parameter를 평균하지만, client가 자기 label만 보고 학습하는 동안 **미표기 장기의 출력도 함께 변한다**. 이 변화가 누적되면 global model이 가진 다장기 지식이 local update에서 훼손된다.

논문은 이 현상을 두 teacher로 제어한다.

- **Global KD:** 통신 round가 시작될 때 받은 global model이 현재 CT의 미표기 장기를 예측한다. Local model은 그 soft prediction을 따라가며 global knowledge를 유지한다.
- **Local KD:** 각 기관이 먼저 학습한 장기별 segmentation model이 해당 장기의 teacher가 된다. 다른 client는 자기 CT에서 그 teacher의 예측을 받아 미표기 장기 head를 학습한다.
- **Multi-head U-Net:** encoder와 decoder를 공유하고, target별로 162-parameter segmentation head만 분리한다. 공유 feature map에 여러 head를 적용하므로 조건부 모델처럼 장기마다 전체 forward pass를 반복하지 않는다.

![Global and local knowledge distillation teacher paths for a client multi-head U-Net]({{ "/assets/images/research/federated-multi-organ-kd/kd-teacher-flow.svg" | relative_url }})

*Supplementary diagram. 원 논문의 그림을 복제하지 않고, 표기 head와 미표기 head에 들어가는 학습 신호를 독자용으로 재구성했다.*

## 전체 흐름

| 원문 위치 | 핵심 질문 |
|---|---|
| Sections 1-2 | 부분 label과 federated learning이 만나면 왜 catastrophic forgetting이 커지는가? |
| Sections 3.1-3.2, Eqs. (1)-(6) | 기본 목적함수와 FedAvg는 어떤 대상을 최적화하는가? |
| Sections 3.3-3.4, Eqs. (7)-(10) | Global teacher와 장기별 teacher는 미표기 class 지식을 어떻게 보존하는가? |
| Section 3.5, Fig. 3 | Multi-head 구조가 KD와 빠른 다장기 추론에 왜 적합한가? |
| Section 4, Tables 1-11 | 내부·외부 데이터와 client 수 변화에서 어떤 개선이 확인되는가? |
| Section 5 | 남은 병목은 무엇인가? |

## 1. 문제 설정: label의 부재는 background label이 아니다

Client $$c^k$$는 부분 주석 dataset $$D^k$$를 가진다. 전체 class 집합을 $$L=\{1,2,\ldots,N_C\}$$라 하고, client $$k$$가 실제로 주석한 class subset을 $$L^k\subseteq L$$라 하자. 입력 $$X_i^k\in\mathbb{R}^{Z\times H\times W}$$에서 target $$l$$의 binary mask를 예측하는 model을 $$f_\theta(X_i^k,l)$$로 둔다.

$$
\theta = \arg\min_{\theta}
\sum_{k=1}^{N_D}\sum_{i=1}^{N_I^k}\sum_{l\in L^k}
\mathcal{L}\!\left(f_\theta(X_i^k,l),Y_i^{kl}\right)
$$

이 목적함수는 **존재하는 label에 대해서만** supervised loss를 계산한다. $$l\notin L^k$$인 장기가 영상에 없다는 뜻은 아니다. 단지 annotator가 그 장기를 표시하지 않았다는 뜻이다. 미표기 장기를 background로 간주하면 잘못된 음성 label을 만들고, 아무 제약도 두지 않으면 local update가 기존 예측을 자유롭게 바꾼다.

## 2. FedAvg baseline과 forgetting의 발생 지점

각 client는 global parameter $$\theta_g$$를 받아 local parameter $$\theta_k$$를 갱신한다. 논문은 표기된 target에 cross-entropy와 Dice loss를 함께 사용한다.

$$
\mathcal{L}\!\left(f_{\theta_k}(X_i^k,l),Y_i^{kl}\right)
=\mathcal{L}_{\mathrm{CE},i}+\mathcal{L}_{\mathrm{Dice},i}
$$

Local training 후 server는 client parameter를 단순 평균한다.

$$
\theta_g=\frac{1}{N_D}\sum_{k=1}^{N_D}\theta_k
$$

원래 FedAvg는 client sample 수로 가중할 수 있지만, 논문은 label distribution이 client마다 이질적이므로 가중하지 않는다. 이 선택은 큰 기관의 특정 장기 label이 global update를 지배하는 상황을 피하려는 문제 설정상의 결정이다.

Catastrophic forgetting은 supervised head에만 생기는 현상이 아니다. 공유 encoder-decoder가 표기 장기에 맞춰 변하면 **같은 feature를 사용하는 모든 미표기 head의 출력도 바뀐다**. Table 4에서 local model은 자기 target 장기에는 높은 Dice를 유지하지만 non-target 장기 성능은 크게 떨어진다. 예를 들어 Multihead client C0의 kidney, pancreas, spleen Dice는 모두 50% 미만인 반면 global model 평균 Dice는 85.4%였다.

## 3. Global KD: 현재 global model을 teacher로 고정한다

Global KD는 local update 직전의 global model $$f_{\theta_g}$$를 teacher로 사용한다. Client $$k$$에서 label이 없는 class $$l\notin L^k$$에 대해 teacher와 student의 voxel prediction 사이 cross-entropy를 계산한다.

$$
\mathcal{L}^{\mathrm{global}}_{\mathrm{KD},i}
=-\frac{1}{N_V}\frac{1}{N_C-n(L^k)}
\sum_{l\notin L^k}\sum_{j=1}^{N_V}
f_{\theta_g}(X_{ij}^k,l)
\log f_{\theta_k}(X_{ij}^k,l)
$$

여기서 $$N_V=ZHW$$는 voxel 수, $$n(L^k)$$는 client가 가진 표기 class 수다. Teacher는 미표기 class 각각의 **해당 segmentation head 출력**을 제공한다. Student는 표기 class에 CE와 Dice를 적용하면서, 미표기 class에는 KD를 적용한다.

$$
\mathcal{L}_{\mathrm{client}}
=\mathcal{L}_{\mathrm{CE}}+\mathcal{L}_{\mathrm{Dice}}
+\mathcal{L}^{\mathrm{global}}_{\mathrm{KD}}
$$

이 loss의 역할은 새 장기 지식을 만들어내는 것이 아니다. 직전 global model이 이미 가진 예측을 local update가 불필요하게 훼손하지 않도록 제한한다. 추가 장기별 model을 저장할 필요가 없어 client data가 적어도 적용할 수 있다는 장점이 있다.

<details markdown="block">
<summary markdown="span">Derivation: Why global KD reduces forgetting on unlabeled heads</summary>

Local supervised update만 수행하면 parameter 변화 $$\Delta\theta_k$$는 표기 class loss의 gradient로 결정된다.

$$
\Delta\theta_k\propto-
\nabla_{\theta_k}
\left(\mathcal{L}_{\mathrm{CE}}+\mathcal{L}_{\mathrm{Dice}}\right)
$$

공유 encoder-decoder 때문에 이 변화는 미표기 class $$l\notin L^k$$의 출력에도 영향을 준다. Global KD를 더하면 student output이 teacher distribution에서 멀어질수록 gradient가 반대 방향으로 작용한다.

$$
\Delta\theta_k\propto-
\nabla_{\theta_k}
\left(
\mathcal{L}_{\mathrm{CE}}+\mathcal{L}_{\mathrm{Dice}}
+\mathcal{L}^{\mathrm{global}}_{\mathrm{KD}}
\right)
$$

따라서 KD는 parameter 자체를 고정하는 FedProx형 제약이 아니라, **미표기 head의 함수 출력**을 보존하는 제약이다. Teacher가 틀린 예측을 하면 그 오류도 보존할 수 있으므로 정확도 개선은 실험으로 확인해야 한다.

</details>

## 4. Local KD: 장기별 expert knowledge를 전달한다

Local KD에서는 각 client가 자기 dataset으로 장기별 model $$\tilde{h}_{\tilde{\theta}_l}$$을 먼저 학습하고 그 parameter를 다른 client와 공유한다. Client $$k$$는 미표기 class $$l\notin L^k$$에 대응하는 teacher output으로 student head를 학습한다.

$$
\mathcal{L}^{\mathrm{local}}_{\mathrm{KD},i}
=-\frac{1}{N_V}\frac{1}{N_C-n(L^k)}
\sum_{l\notin L^k}\sum_{j=1}^{N_V}
\tilde{h}_{\tilde{\theta}_l}(X_{ij}^k)
\log f_{\theta_k}(X_{ij}^k,l)
$$

모든 teacher를 매 update마다 실행하면 client 수와 class 수에 따라 계산량이 커진다. 논문은 매 update에서 미표기 class 하나를 무작위 표본화해 다음 식으로 단순화한다.

$$
\mathcal{L}^{\mathrm{local}}_{\mathrm{KD},i}
=-\frac{1}{N_V}
\sum_{j=1}^{N_V}
\tilde{h}_{\tilde{\theta}_l}(X_{ij}^k)
\log f_{\theta_k}(X_{ij}^k,l),
\qquad l\notin L^k
$$

한 update에서는 한 teacher만 쓰지만 반복 학습 동안 여러 teacher가 표본화된다. Table 11에서 한 번에 표본화한 model 수가 1, 3, 5, 7일 때 Dice는 70.02-70.80 범위로 큰 차이가 없었다. 모든 teacher를 매번 실행하지 않아도 된다는 실험 근거다.

Global KD와 local KD는 teacher knowledge가 다르다. Global teacher는 여러 client를 이미 평균한 **현재 federated state**를 보존한다. Local teacher는 특정 장기에 집중한 **expert state**를 전달한다. 반면 local teacher의 training data가 적으면 expert 자체가 부정확할 수 있다. 21-client 실험에서 dataset을 더 작게 쪼갰을 때 두 KD를 결합한 방법이 평균 Dice와 HD 모두 가장 좋은 조합이었다.

## 5. Multi-head U-Net: 한 feature map, 여러 가벼운 head

조건부 U-Net은 target ID에 따라 전체 network의 동작을 바꾸고, 장기별 prediction을 얻기 위해 forward pass를 반복할 수 있다. 이 논문은 shared encoder-decoder가 만든 feature map에 여러 얕은 segmentation head를 적용한다.

각 head는 세 convolution layer로 구성되며 논문이 계산한 parameter 수는 다음과 같다.

$$
(8+1)\times 8+(8+1)\times 8+(8+1)\times 2=162
$$

마지막 output channel 2개는 해당 task의 organ과 tumor에 대응한다. Spleen처럼 tumor label이 없는 task도 있고, colon과 lung처럼 tumor만 표기된 dataset도 있다. Head 분리는 task별 출력을 유지하고, shared trunk는 여러 dataset의 표현을 함께 학습한다.

구조의 novelty는 multi-head 자체만이 아니다. **KD가 요구하는 여러 target prediction을 한 번에 계산할 수 있는 baseline**과 global/local KD를 결합한 점이 핵심이다. Table 9에서 7개 task 전체 prediction의 test time은 Multihead FedAvg와 제안법 모두 0.097 s였고, Separate Encoder는 0.427 s였다. KD는 train time을 늘리지만 배포 시 test time은 늘리지 않았다.

## 6. 실험 설정

| 항목 | 설정 |
|---|---|
| Dataset | 공개 복부 CT dataset 8개 |
| Target | liver, kidney, pancreas, hepatic vessel, colon, lung, spleen의 7개 장기·관련 종양 task |
| Federated training | 7개 dataset을 7 clients로 사용, 추가로 각 dataset을 3분할한 21-client 설정 |
| Training / internal test | 889 CT / 233 CT |
| External test | BTCV 30 CT, 공통 label인 liver·kidney·pancreas·spleen 평가 |
| Preprocessing | voxel size 3.0 × 1.5 × 1.5 mm³, intensity [-325, 325]를 [-1, 1]로 정규화 |
| Input patch | 64 × 128 × 128, 80%는 ROI 인근에서 crop |
| Optimization | SGD, initial learning rate 1e-2, momentum 0.99, batch size 2 |
| Federated schedule | 1000 communication rounds, client당 round마다 80 local iterations |
| Metrics | Dice, Hausdorff distance, inference time, parameter 수, GFLOPs |

Dataset 8개 중 7개가 federated training과 internal test에 쓰이고, BTCV는 external transfer test다. 따라서 “8 datasets, 7 organs, 889 train, 233 internal, 30 external”은 서로 다른 단위의 숫자다. 889와 233은 7개 training-domain dataset의 volume 수이고, 30은 BTCV volume 수다.

## 7. 주요 결과

### 7.1 7-client federated setting

| 방법 | Avg Dice ↑ | Avg HD ↓ |
|---|---:|---:|
| DoDNet FedAvg | 53.20 | 58.21 |
| Separate Encoder FedAvg | 66.82 | 21.45 |
| Multihead FedAvg | 66.58 | 23.84 |
| Global KD | 69.55 | 18.36 |
| Local KD | 70.80 | **15.99** |
| Global KD + Local KD | **71.00** | 16.19 |
| Centralized Multihead reference | 72.72 | 15.29 |

Global + Local KD는 Multihead FedAvg보다 평균 Dice가 4.42 percentage points 높고, 평균 HD가 8.55 voxel 낮다. 두 KD가 federated와 centralized setting의 격차를 줄였지만, 모든 metric에서 같은 변형이 최고는 아니다. Local KD가 평균 HD 15.99로 가장 낮고, 결합형이 평균 Dice 71.00으로 가장 높다.

### 7.2 External BTCV

| 설정 | 방법 | Avg Dice ↑ | Avg HD ↓ |
|---|---|---:|---:|
| 7 clients | Separate Encoder FedAvg | 72.41 | 25.28 |
| 7 clients | Global KD | **77.53** | **15.09** |
| 7 clients | Global + Local KD | 76.66 | 15.78 |
| 21 clients | Global KD | 75.97 | **14.39** |
| 21 clients | Global + Local KD | **76.60** | 18.26 |

BTCV의 kidney CT는 training kidney dataset과 contrast 조건이 달라 성능이 낮아졌다. 이 결과는 domain shift가 사라졌다는 뜻이 아니다. 제안법이 비교 방법보다 견고했지만, teacher prediction도 acquisition 차이에 영향을 받는다.

### 7.3 Centralized setting과 효율

Centralized experiment에서도 KD를 포함한 Ours는 평균 Dice 73.79, 평균 HD 13.00을 기록했다. 이때의 KD는 federated setting의 global/local teacher를 그대로 쓰지 않고, Eq. 11처럼 batch update 전 모델 $$f_{\theta}$$와 update 후 모델 $$f_{\theta'}$$의 미표기 장기 출력을 cross-entropy로 맞춘다. Multihead baseline은 각각 72.72와 15.29였다. 작은 batch에서 부분 label만 반복 학습하면 중앙집중 학습에서도 forgetting이 생길 수 있다는 저자 해석과 맞는다.

Table 9의 7-task inference 기준으로 제안법의 test time은 0.097 s, test cost는 461.0 GFLOPs다. Separate Encoder는 0.427 s와 3219.1 GFLOPs였다. 다만 이 수치는 3D patch 하나에 대한 값이다. 논문은 volume 하나에 약 50개 patch를 사용하는 sliding-window inference를 적용했으므로 실제 volume latency는 더 길다.

## 8. 논문의 핵심 기여

1. **Forgetting을 output space에서 직접 제한했다.** Parameter distance만 제한하는 일반 FL regularizer와 달리, 미표기 장기의 segmentation output을 teacher prediction에 맞춘다.
2. **Teacher knowledge를 두 층으로 분리했다.** Global KD는 federated consensus를 보존하고, local KD는 장기별 expert knowledge를 전달한다.
3. **KD와 inference 효율을 함께 설계했다.** Shared trunk와 162-parameter heads는 여러 teacher target을 한 forward pass에서 계산하고, 배포 시에도 여러 장기를 반복 추론하지 않는다.
4. **부분 label·client 수·외부 domain을 함께 평가했다.** 7-client와 21-client, 내부 233 volumes와 외부 BTCV 30 volumes를 분리해 확인했다.

## 9. 해석 포인트와 한계

- **FL은 data sharing을 줄이지만 privacy를 자동 보장하지 않는다.** 논문은 raw CT를 공유하지 않는 학습 구조를 다룬다. Secure aggregation, differential privacy, model inversion 방어까지 검증한 연구는 아니다.
- **Local teacher는 사전학습과 model 공유 비용이 있다.** Client data가 작으면 장기별 teacher가 부정확해질 수 있다. Global KD가 더 넓게 적용되는 이유다.
- **통신 병목이 남는다.** 1000 rounds, round당 80 local iterations 설정에서 성능을 확인했다. 저자도 많은 server-client 통신을 핵심 한계로 명시하고, 적은 round로 학습하는 후속 연구를 제안한다.
- **실험은 공개 복부 CT 8개에 한정된다.** 다른 modality, 장기, 기관 보안 정책, 실제 heterogeneous hardware에서 같은 결과를 보장하지 않는다.
- **Teacher confidence를 따로 보정하지 않는다.** KD는 teacher가 만든 오류도 student에 전달할 수 있다. 평균 성능 향상과 각 사례의 신뢰성은 구분해야 한다.
- **‘First’ 주장은 저자의 related-work 범위다.** 논문은 부분 label segmentation을 위한 첫 KD-based federated model이라고 주장한다. 문헌 전체에 대한 절대적 최초성을 이 글이 독립 검증하지는 않았다.

## 10. 독립 해설: 문제와 방법 연결하기

이 논문의 출발점은 의료 영상 주석의 비대칭성이다. 복부 CT 한 장에는 여러 장기와 종양이 함께 보이지만, 공개 dataset은 특정 장기나 특정 종양만 표시하는 경우가 많다. 여러 기관이 각자의 dataset을 보유하면 이 비대칭성에 acquisition 차이까지 더해진다. 한곳에 모든 CT를 모으기 어려우므로 federated learning이 자연스러운 대안이지만, 일반 FedAvg는 각 client가 자기 target만 학습할 때 다른 target의 지식을 보존하도록 요구하지 않는다.

저자들은 이 빈 부분을 knowledge distillation로 채운다. Global KD에서는 server가 보낸 model이 teacher다. Local model은 자기 label로 새 정보를 학습하면서도, label이 없는 장기에서는 global teacher가 내던 prediction을 유지한다. Local KD에서는 각 장기에 특화된 model이 teacher다. 이 model들은 자기 기관의 주석으로 먼저 학습되며, 다른 client의 CT에서 해당 장기 pseudo target을 제공한다. 모든 teacher를 동시에 실행하는 비용을 줄이기 위해 매 update에서 하나를 표본화한다.

이 방식이 작동하려면 여러 장기의 prediction을 빠르게 얻어야 한다. 저자들은 U-Net의 encoder-decoder를 공유하고 끝부분의 얕은 head만 target별로 나눈다. 각 head는 162 parameters에 불과하다. Shared feature를 한 번 계산한 뒤 모든 head에 적용하므로, target ID를 바꿔 전체 network를 반복 실행하는 conditional architecture보다 다장기 prediction이 빠르다.

실험은 7개 partially labeled dataset을 각각 client로 두고 889 CT로 학습했다. 내부 test 233 CT에서 Global + Local KD는 평균 Dice 71.00을 기록해 Multihead FedAvg의 66.58보다 높았다. 외부 BTCV 30 CT에서도 KD 변형은 비교 방법보다 높은 평균 Dice를 보였다. Dataset을 더 쪼갠 21-client 조건에서도 결합형은 높은 Dice를 유지했다. 이 수치는 KD가 forgetting을 완화한다는 주장을 지지하지만, 장기별 결과와 domain shift의 영향은 여전히 남는다.

가장 중요한 실무적 결론은 “federated”라는 학습 위치만으로 부분 label 문제가 해결되지 않는다는 점이다. Client update가 어떤 output을 보존해야 하는지 명시해야 한다. Global teacher는 현재 federation의 공통 지식을 보존하고, local teacher는 장기별 전문 지식을 보충한다. Multi-head 구조는 이 두 신호를 계산 가능한 비용으로 적용한다. 남은 과제는 많은 통신 round, teacher 오류, 실제 privacy 공격, 기관별 compute 차이를 함께 다루는 것이다.

## 마지막 핵심 정리

- **문제:** 부분 label client의 local update가 non-target organ knowledge를 잊는다.
- **방법:** Global model과 장기별 model을 teacher로 두고 미표기 head에 KD를 적용한다.
- **구조:** 공유 3D U-Net trunk와 target별 162-parameter head가 한 번의 forward pass로 다장기 prediction을 만든다.
- **근거:** 8 datasets, 7 organs, 889 train, 233 internal test, 30 external test에서 KD 변형이 Multihead FedAvg보다 높은 정확도를 보였다.
- **한계:** 통신량, teacher 품질, domain shift, 실제 privacy 보장은 별도 문제다.

## 참고자료

<ul>
  <li><a href="https://doi.org/10.1016/j.media.2024.103156" target="_blank" rel="noopener">Publisher page and DOI</a></li>
  <li><a href="https://www.sciencedirect.com/science/article/pii/S1361841524000811" target="_blank" rel="noopener">ScienceDirect article page</a></li>
  <li><a href="https://cnslab.stanford.edu/publications" target="_blank" rel="noopener">Stanford CNS Lab publication list</a></li>
  <li><a href="https://cnslab.stanford.edu/assets/documents/Federatedlearningwithknowledge.pdf" target="_blank" rel="noopener">Author-lab PDF</a></li>
</ul>
