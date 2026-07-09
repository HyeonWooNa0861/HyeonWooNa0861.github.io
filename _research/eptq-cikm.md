---
layout: default
title: "EPTQ"
topic: "Fast and accurate 2-bit post-training quantization via Factored E8 lattice"
order: 27
---

# EPTQ: Fast and Accurate 2-bit Post-Training Quantization via Factored E8 Lattice

Source PDF: `eptq-cikm.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | EPTQ: Fast and Accurate 2-bit Post-Training Quantization via Factored E8 Lattice |
| 저자 | Anonymous Author(s) |
| 출처 | CIKM '26, Rome, Italy |
| 주제 | Post-Training Quantization, Vector Quantization, Large Language Models, Model Compression, E8 Lattice |
| 핵심 방법 | E8-based Post Training Quantization(EPTQ), Factored-E8(FE8), Weight Scale Normalization, Adaptive Critical Weight Preservation |

## 한 줄 요약

EPTQ는 LLM을 2-bit 수준으로 압축할 때 scalar quantization의 성능 붕괴와 기존 vector quantization의 느린 양자화/추론 문제를 함께 줄이기 위해, E8 lattice quantization을 4 KB codebook으로 factorization하고 weight scale normalization과 adaptive critical weight preservation을 결합한 PTQ framework다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 2-bit PTQ에서 scalar quantization은 무너지고, 기존 VQ는 실용성이 떨어지는가? |
| 2 | 문제 정의 | PTQ는 full-precision weight matrix를 어떤 output reconstruction 문제로 보는가? |
| 3 | Factored-E8 | E8 lattice의 65,536개 8D point를 어떻게 4 KB codebook으로 표현하는가? |
| 4 | Weight Scale Normalization | row/column variance mismatch를 왜 Sinkhorn-Knopp 방식의 scale vector로 맞추는가? |
| 5 | Adaptive CWP | Hessian-sensitive critical vector를 어떻게 per-matrix knee point로 찾는가? |
| 6 | EPTQ Algorithm | WSN, critical masking, Hessian compensation, FE8 lookup은 어떤 순서로 결합되는가? |
| 7 | 실험 결과 | Llama-2/Llama-3에서 PPL, zero-shot accuracy, quantization time, decode throughput은 어떻게 달라지는가? |
| 8 | 해석 포인트 | E8과 FE8은 정확도와 추론 효율 사이에서 어떤 선택지를 제공하는가? |

## 1. 문제 배경

LLM 배포에서 post-training quantization(PTQ)은 학습을 다시 하지 않고 weight 표현 bit 수를 줄이는 방법이다. 일반적으로 bit 수를 낮추면 memory footprint와 bandwidth 부담이 줄어든다. 하지만 2-bit 수준에서는 scalar quantization이 weight distribution의 구조를 제대로 표현하지 못해 perplexity와 downstream accuracy가 크게 붕괴한다.

기존 vector quantization(VQ)은 여러 weight를 묶어 quantization하므로 2-bit에서도 accuracy를 어느 정도 유지한다. 그러나 논문은 기존 VQ 계열이 두 가지 practical bottleneck을 가진다고 본다.

| 병목 | 설명 |
|---|---|
| Quantization time | codebook learning 또는 복잡한 optimization pipeline 때문에 model별 변환 시간이 길다. |
| Inference throughput | codebook lookup이나 decoding이 느리면 memory를 줄여도 실제 decode 속도가 낮아진다. |

EPTQ의 목표는 단순히 PPL을 낮추는 것이 아니라, 2-bit PTQ에서 accuracy, quantization time, decode throughput을 동시에 개선하는 것이다.

## 2. 문제 정의

논문은 linear layer의 full-precision weight matrix를 \\(W\\), calibration input을 \\(X\\)로 두고, quantized matrix \\(\\widehat{W}\\)가 layer output을 최대한 보존하도록 문제를 정의한다.

$$
\\underset{\\widehat{W}}{\\arg\\min}\\ \\lVert WX - \\widehat{W}X \\rVert_F^{2}
\\quad
\\text{s.t.}
\\quad
\\widehat{W}=\\mathrm{quant}(W)
$$

이 식에서 핵심은 quantization 자체가 목적이 아니라, quantization 이후 layer output error를 줄이는 것이다. 따라서 EPTQ는 단순 rounding 대신, weight vector의 geometry, row/column scale, Hessian sensitivity를 함께 고려하는 quantization function을 설계한다.

## 3. Factored-E8 Quantization

EPTQ의 중심은 8-dimensional vector quantization이다. Neural network weight는 대체로 Gaussian distribution에 가까운 형태를 가지므로, Cartesian grid 기반 scalar quantization보다 hypersphere 구조에 더 잘 맞는 lattice quantization이 유리하다는 관점에서 출발한다.

E8 lattice는 8차원에서 조밀한 sphere packing 구조를 제공한다. 기존 E8 기반 방식은 65,536개의 8D lattice point를 직접 codebook으로 저장할 수 있지만, 이 경우 codebook이 약 1 MB가 되어 GPU L1 cache에 올라가기 어렵다. lookup이 L2 cache 중심으로 밀리면 decode throughput이 떨어진다.

논문이 제안하는 Factored-E8(FE8)은 8D vector를 두 개의 4D half로 나누고, 각 half를 네 가지 coset type으로 분류한다.

| 구성 | 역할 |
|---|---|
| 4D half vector | 8D E8 point를 두 개의 4D vector로 분해 |
| coset type \\(t\\) | integer/half-integer 여부와 coordinate sum parity를 함께 표현 |
| \\(F_t \\times F_t\\) | 같은 type의 4D half 두 개를 결합해 valid E8 point 구성 |
| 4 KB codebook | 4 type x 128 vector x 4 dimension 구조로 저장 |

이 factorization은 65,536개의 8D quantization point capacity를 유지하면서도 codebook storage를 1 MB에서 4 KB로 줄인다. 논문은 이를 256x smaller codebook으로 설명하며, GPU L1 cache residency가 가능해져 inference lookup 비용이 낮아진다고 해석한다.

## 4. Decomposed Search와 16-bit Index

8D vector \\(v=[a;b]\\)를 quantize할 때, FE8은 모든 65,536개 candidate를 직접 비교하지 않는다. 같은 coset type \\(t\\) 안에서 앞쪽 4D half와 뒤쪽 4D half를 따로 비교하고, 두 half의 distance 합이 가장 작은 type과 index pair를 고른다.

논문에서 quantized vector index는 하나의 16-bit integer로 저장된다.

```text
index = (t << 14) | (i << 7) | j
```

여기서 \\(t\\)는 coset type, \\(i\\)와 \\(j\\)는 각각 두 4D half의 codebook index다. Decode 시에는 4 KB codebook에서 두 번의 4D lookup을 수행하면 된다. 이 구조가 FE8의 throughput 이점을 만든다.

## 5. Weight Scale Normalization

FE8 quantization은 weight가 Gaussian-like distribution을 따른다는 가정에 의존한다. 하지만 실제 LLM weight matrix를 row와 column 단위로 보면 variance가 균일하지 않다. 어떤 row/column은 scale이 크고, 어떤 row/column은 작기 때문에 동일한 lattice radius를 적용하면 특정 영역에서 quantization error가 커진다.

논문은 weight matrix를 다음처럼 factorize한다.

$$
W = W' \\odot (g h^{\\top})
$$

| 기호 | 의미 |
|---|---|
| \\(W\\) | 원래 weight matrix |
| \\(W'\\) | row/column scale이 normalized된 matrix |
| \\(g\\) | row-wise scale vector |
| \\(h\\) | column-wise scale vector |

이때 목표는 \\(W'\\)의 row와 column이 비슷한 magnitude distribution을 갖도록 만드는 것이다. 논문은 variance 대신 L1 norm, 즉 mean absolute value를 맞추는 방식을 택한다. L2 norm은 outlier에 민감하지만 L1 norm은 더 robust하고, 큰 outlier성 weight는 뒤에서 critical weight preservation으로 따로 보존할 수 있기 때문이다.

계산은 Sinkhorn-Knopp algorithm과 유사한 row/column alternating normalization으로 수행된다. 논문은 이 과정이 보통 5 iteration 미만에서 수렴한다고 보고한다.

## 6. Adaptive Critical Weight Preservation

모든 weight vector가 동일하게 중요하지는 않다. 특정 vector는 quantization되면 output loss를 크게 키운다. EPTQ는 이런 vector를 critical vector로 보고 full precision으로 보존한다.

중요도 score는 8D vector \\(v_{b,j}\\)를 quantize했을 때 생기는 error와 calibration input의 Hessian 정보를 함께 사용해 계산한다.

$$
S_{b,j}
=
\\frac{\\lVert v_{b,j}-\\widehat{v}_{b,j}\\rVert_2^{2}}
{[XX^{\\top}]^{-1}_{j,j}}
$$

이 score는 quantization error가 크고 Hessian 관점에서 민감한 vector일수록 커진다. 단순히 top \\(p\\%\\)를 고르는 fixed-ratio 방식은 layer별 score distribution이 다르면 잘 맞지 않는다. 논문은 Kneedle algorithm을 사용해 각 matrix마다 score curve의 knee point를 찾고, 그 지점을 threshold \\(\\tau\\)로 사용한다.

| 방식 | 문제 |
|---|---|
| fixed threshold | layer마다 score scale이 다르면 보존 비율이 불안정해진다. |
| fixed ratio | layer마다 natural knee 위치가 다르면 중요하지 않은 vector를 보존하거나 중요한 vector를 놓칠 수 있다. |
| adaptive knee point | matrix별 heavy-tail distribution에서 high-sensitivity 영역의 경계를 자동으로 찾는다. |

보존 mask는 별도 1-bit mask로 저장하지 않는다. FE8 codebook의 마지막 index를 reserved marker로 사용해 critical vector를 표시한다. 이로써 mask metadata를 따로 저장하지 않는 zero bit-overhead preservation이 가능해진다.

## 7. EPTQ Algorithm

EPTQ 전체 흐름은 다음과 같다.

| 단계 | 내용 |
|---|---|
| 1 | weight matrix \\(W\\)에 대해 iterative weight scaling을 수행해 \\(W'\\), \\(g\\), \\(h\\)를 얻는다. |
| 2 | normalized matrix \\(W'\\)에 맞춰 effective input \\(X'=\\mathrm{diag}(h)X\\)를 구성한다. |
| 3 | \\(X'\\) 기반 Hessian inverse와 Cholesky decomposition을 계산한다. |
| 4 | adaptive critical vector masking으로 preservation mask \\(M\\)을 만든다. |
| 5 | 각 column을 block-wise로 처리하며 FE8 quantization과 Hessian error compensation을 수행한다. |
| 6 | 마지막에 \\(\\widehat{W}\\leftarrow \\widehat{W}\\odot(gh^{\\top})\\)로 scale을 복원한다. |

이 구조는 GPTQ 계열의 Hessian-based compensation을 활용하면서, quantization function 자체를 FE8 lattice lookup으로 바꾸고, scale normalization과 adaptive preservation을 결합한 형태다.

## 8. 실험 설정

논문은 Llama-2와 Llama-3 family를 대상으로 EPTQ를 평가한다.

| 항목 | 내용 |
|---|---|
| 모델 | Llama-2-7B, Llama-2-13B, Llama-2-70B, Llama-3-8B |
| PPL dataset | Wikitext-2, C4 |
| Zero-shot benchmark | PIQA, ARC-easy, ARC-challenge, HellaSwag, WinoGrande |
| Calibration | C4에서 128 samples, sequence length 2048 |
| Baselines | GPTQ, AWQ, VPTQ, QTIP |
| Hardware | Single NVIDIA H100 GPU |

평가 지표는 token-level perplexity, zero-shot accuracy, quantization time, decode throughput이다. 이 조합은 EPTQ가 단순 compression ratio가 아니라 실제 deployment efficiency를 겨냥한다는 점을 보여준다.

## 9. 주요 결과

논문은 EPTQ를 E8과 FE8 두 variant로 나눈다.

| Variant | 특징 | 해석 |
|---|---|---|
| EPTQ (E8) | full E8 codebook 사용 | accuracy가 더 강한 선택지 |
| EPTQ (FE8) | factored 4 KB codebook 사용 | decode throughput과 quantization time이 강한 선택지 |

핵심 결과는 다음과 같다.

| 비교 항목 | 결과 |
|---|---|
| Llama-2-7B accuracy | EPTQ(E8, \\(\\rho=.1\\))가 QTIP보다 낮은 WikiText-2 PPL을 기록했다: 7.28 vs. 7.34 |
| Llama-2-13B zero-shot | EPTQ(E8, \\(\\rho=.1\\))가 평균 67.53으로 QTIP 67.12보다 높았다. |
| Llama-2-13B quantization time | EPTQ(FE8)는 2,115 s로 QTIP 13,531 s보다 6.4x 빠르다. |
| Llama-2-70B quantization time | EPTQ(FE8)는 8,376 s로 QTIP 57,205 s보다 6.8x 빠르다. |
| Llama-2-7B throughput | EPTQ(FE8)는 235.2 tok/s로 QTIP 180.5 tok/s, FP16 187.1 tok/s를 넘는다. |
| Llama-3-8B throughput | EPTQ(FE8)는 193.0 tok/s로 QTIP 164.7 tok/s, FP16 161.8 tok/s보다 높다. |

FE8은 codebook을 L1 cache에 올릴 수 있어 decode throughput에서 강하다. 반면 E8은 full codebook을 사용하므로 정확도 측면에서 더 나은 경우가 있다. 논문은 두 variant를 상호 배타적 경쟁 관계가 아니라, deployment 목적에 따라 선택 가능한 trade-off로 제시한다.

## 10. Ablation 해석

### Weight Scale Normalization

WSN은 모든 모델에서 C4 PPL과 zero-shot accuracy를 개선한다. 특히 Llama-3-8B에서 효과가 크다. 논문은 Llama-3-8B의 weight distribution이 row/column variance imbalance를 더 크게 가진 것으로 해석한다.

| 모델 | \\(\\rho\\) | C4 PPL 개선 | Zero-shot 개선 |
|---|---:|---:|---:|
| Llama-2-7B | .02 | 10.58 -> 9.14 | 58.6 -> 61.6 |
| Llama-2-13B | .02 | 8.51 -> 7.92 | 65.2 -> 66.6 |
| Llama-3-8B | .02 | 18.34 -> 14.90 | 51.5 -> 58.8 |

### Adaptive CWP

Adaptive critical weight preservation은 같은 preservation budget에서 fixed-ratio 방식보다 낮은 perplexity를 보였다. 중요한 점은 보존되는 weight 수가 많아서가 아니라, 어떤 weight를 보존할지 더 정확히 고른다는 것이다.

### Hyperparameter Sensitivity

Codebook radius \\(r\\)는 이론적으로 약 1.77 근처가 적절하다고 설명된다. 실험에서는 \\(r\\in[1.70,1.80]\\) 범위에서 PPL이 비교적 안정적이었고, 논문은 기본값으로 \\(r=1.75\\)를 사용한다.

## 11. 해석 포인트

EPTQ의 기여는 2-bit compression을 단순한 quantization level 문제로 보지 않고, 다음 세 층의 문제를 동시에 다룬다는 점에 있다.

| 층위 | 논문의 처리 |
|---|---|
| Geometry | scalar grid 대신 E8 lattice 기반 8D vector quantization 사용 |
| Distribution | row/column scale mismatch를 \\(g\\), \\(h\\)로 normalization |
| Sensitivity | Hessian-sensitive vector를 adaptive knee point로 찾아 FP16 보존 |

이 논문을 읽을 때 중요한 관점은 "2-bit인데도 정확하다"보다 "2-bit에서 정확도와 실제 추론 속도를 동시에 설계했다"는 점이다. 기존 VQ가 accuracy 문제를 풀었더라도 codebook lookup이 느리면 deployment 관점에서는 한계가 있다. FE8은 codebook 구조 자체를 cache-friendly하게 바꿔 이 문제를 직접 겨냥한다.

## 12. 한계와 향후 과제

논문은 EPTQ가 weight-only PTQ framework라는 점에서 activation quantization까지 다루지는 않는다. 또한 FE8의 장점은 GPU cache behavior와 kernel implementation에 의존하므로, hardware-aware kernel 최적화가 후속 과제로 남는다.

실험은 single NVIDIA H100 GPU에서 수행되었다. 따라서 다른 GPU architecture, CPU inference, mobile/edge accelerator에서 같은 throughput gain이 유지되는지는 추가 확인이 필요하다. 또한 저자 정보와 DOI가 anonymized/placeholder 상태이므로, 최종 출판본에서는 인용 정보가 달라질 수 있다.

## 핵심 내용

이 절은 원문 전체를 그대로 옮긴 번역이 아니라, EPTQ 논문의 문제 설정부터 방법, 실험, 결론까지를 한국어로 따라 읽을 수 있게 재구성한 번역형 해설이다. 논문 고유명사, 수식 기호, 모델명, 실험 수치는 원문 기준을 유지했다.

초록과 서론에서 논문은 2-bit PTQ의 핵심 난점을 제기한다. GPTQ, AWQ, OmniQuant, SEPTQ 같은 scalar quantization 기반 방법은 2-bit에서 성능이 크게 무너질 수 있다. 반대로 VPTQ나 QTIP 같은 vector quantization 계열은 정확도 측면에서 유리하지만, quantization pipeline이 오래 걸리거나 inference throughput이 낮아 실제 배포에서 부담이 된다. EPTQ는 이 둘 사이의 trade-off를 줄이는 것을 목표로 한다.

방법의 첫 번째 축은 Factored-E8 quantization이다. E8 lattice는 8D 공간에서 weight vector의 spherical distribution을 잘 표현할 수 있지만, full codebook은 1 MB 규모라 GPU L1 cache에 올리기 어렵다. EPTQ는 8D vector를 두 개의 4D half로 나누고, 같은 coset type끼리 결합하는 구조를 이용해 65,536개 point capacity를 유지하면서도 codebook을 4 KB로 줄인다. 이 설계는 lookup을 cache-friendly하게 만들어 decode throughput을 크게 높인다.

두 번째 축은 weight scale normalization이다. Weight matrix 전체는 Gaussian처럼 보일 수 있지만 row와 column 단위로 보면 variance가 균일하지 않다. EPTQ는 \\(W=W'\\odot(gh^{\\top})\\)로 weight를 분해하고, Sinkhorn-Knopp 방식의 반복 scaling으로 \\(W'\\)의 row/column magnitude를 맞춘다. 이 단계는 FE8 lattice quantization이 가정하는 분포 조건에 weight를 더 가깝게 만든다.

세 번째 축은 adaptive critical weight preservation이다. 일부 8D vector는 quantization되면 output error를 크게 키우므로 full precision으로 남기는 것이 유리하다. EPTQ는 Hessian 기반 importance score를 계산하고, 각 matrix별 score distribution에서 Kneedle algorithm으로 knee point를 찾아 preservation threshold를 정한다. 이 방식은 fixed threshold나 fixed ratio보다 layer별 sensitivity 차이를 더 잘 반영한다. 또한 reserved codebook index를 mask marker로 사용해 별도 mask bit를 저장하지 않는다.

실험에서는 Llama-2-7B, Llama-2-13B, Llama-2-70B, Llama-3-8B를 대상으로 Wikitext-2, C4, PIQA, ARC, HellaSwag, WinoGrande 평가가 수행된다. 결과적으로 EPTQ(E8)는 Llama-2 모델에서 QTIP과 경쟁 가능한 정확도를 보이고, EPTQ(FE8)는 대부분 모델에서 가장 높은 decode throughput을 보인다. 특히 Llama-3-8B에서 FE8은 193.0 tok/s로 QTIP 164.7 tok/s와 FP16 161.8 tok/s를 넘는다.

결론적으로 EPTQ는 2-bit PTQ의 한계를 bit-width만의 문제가 아니라 codebook geometry, distribution alignment, critical weight selection, cache behavior가 결합된 시스템 문제로 본다. 정확도 중심 배포라면 E8 variant가, latency와 throughput 중심 배포라면 FE8 variant가 더 적합한 선택지가 될 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/eptq-cikm/eptq-cikm.pdf" | relative_url }}" target="_blank" rel="noopener">eptq-cikm.pdf</a></li>
  <li><a href="https://www.together.ai/blog/yaqa" target="_blank" rel="noopener">Together AI Blog: Model-Preserving Adaptive Rounding with YAQA</a> - EPTQ 후속연구에서 original-output KL divergence 평가축을 추가할 때 참고할 자료</li>
</ul>
