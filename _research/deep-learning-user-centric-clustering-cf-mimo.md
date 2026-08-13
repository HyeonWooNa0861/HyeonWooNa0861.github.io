---
layout: default
title: "DL UC Clustering"
topic: "User-centric AP clustering with deep learning"
order: 50
---

# Deep Learning User-Centric Clustering for Cell-Free Massive MIMO Systems

Source PDF: `deep-learning-user-centric-clustering-cf-mimo.pdf`

## Paper Information

| Field | Detail |
| --- | --- |
| Original title | Deep Learning User-Centric Clustering for Cell-Free Massive MIMO Systems |
| Venue | IEEE SPAWC 2024 |
| Authors | Giovanni Di Gennaro, Amedeo Buonanno, Gianmarco Romano, Stefano Buzzi, Francesco A. N. Palmieri |
| Official source | [IEEE DOI](https://doi.org/10.1109/SPAWC60668.2024.10694529){:target="_blank" rel="noopener"} / [arXiv](https://arxiv.org/abs/2410.02775){:target="_blank" rel="noopener"} |
| Core topic | User-centric AP-UE clustering in cell-free massive MIMO |

## 한 줄 요약

Cell-free massive MIMO에서 모든 AP가 모든 UE를 섬기면 fronthaul과 계산 비용이 커지므로, 이 논문은 UE별 master AP와 채널 정보를 순서화해 LSTM 기반으로 AP-UE 연결을 고르고, 합 spectral efficiency를 크게 잃지 않으면서 active link 수를 줄이는 방법을 제안한다.

## 전체 흐름

| Section | 핵심 내용 |
| --- | --- |
| Abstract / Introduction | Cell-free massive MIMO는 AP를 분산 배치해 coverage와 macro-diversity를 얻지만, AP-user association은 조합 최적화라 사용자 수와 AP 수가 커질수록 직접 탐색이 어렵다. |
| System model | \(L\)개 AP, AP당 \(N\)개 안테나, \(K\)개 single-antenna UE를 둔 downlink CF-mMIMO를 다루며, TDD coherence block은 \(\tau_c=\tau_p+\tau_u+\tau_d\)로 나뉜다. |
| Optimization target | sum spectral efficiency를 높이면서 active AP-UE connection 수를 줄이는 목적식을 세우고, 모든 UE가 적어도 하나의 AP에 연결되고 AP별 전송 전력이 \(\rho_{\max}\)를 넘지 않도록 제한한다. |
| DL approach | UE를 master AP와 channel gain 기준으로 정렬한 뒤 LSTM과 shared fully-connected layer가 AP-UE 연결 확률을 출력한다. 학습 중에는 Bernoulli sampling을, 추론 중에는 50% threshold를 사용한다. |
| Simulation | \(700 \times 700\,\mathrm{m}^2\) 영역, \(L=25\), \(N=4\), \(K=10\), 3GPP microcell path loss, shadow fading standard deviation 4 dB 조건에서 기존 heuristic과 비교한다. |
| Conclusion | 제안 방식은 active link를 크게 줄이면서 SE를 비슷하게 유지하거나 pilot 수가 충분할 때 더 높은 SE를 보인다. 후속 과제로 energy efficiency 목적식과 transmit power 최적화를 제시한다. |

## 한국어 번역형 해설

논문의 문제의식은 cell-free massive MIMO의 장점이 곧 운영 비용으로 돌아온다는 점이다. 모든 AP가 모든 UE에 서비스를 제공하면 신호 결합 이득은 얻을 수 있지만, fronthaul signaling, channel estimation, power allocation, precoding 계산량이 커진다. 그래서 practical deployment에서는 각 UE를 일부 AP cluster에만 연결하는 user-centric clustering이 필요하다.

원문은 이 문제를 constrained non-convex optimization으로 정리한다. 목적은 각 UE의 spectral efficiency 합을 높이는 동시에 AP-UE active connection 수에 \(\lambda\) penalty를 주는 것이다. 즉 단순히 link를 줄이는 모델이 아니라, rate 손실과 network load 사이의 균형을 학습하는 모델이다. constraint는 모든 UE가 최소 하나의 AP에 연결되어야 한다는 조건과 AP별 power budget 조건을 포함한다.

제안 모델의 핵심은 LSTM을 이용한 순서 기반 일반화다. 각 UE는 strongest channel을 가진 master AP를 기준으로 정렬되고, AP 후보도 channel gain에 따라 정렬된다. 이 구조를 쓰면 UE 수가 달라져도 같은 recurrent cell을 반복 적용할 수 있어, 논문이 강조하는 "사용자 수 변화에 재학습 없이 대응"한다는 주장이 가능해진다. 단, 이것은 입력 ordering이 물리적 의미를 충분히 보존한다는 가정 위에 서 있다.

학습 과정에서는 모델이 AP-UE connection probability를 출력하고, training에서는 Bernoulli sampling으로 clustering decision을 만든다. inference에서는 0.5 threshold로 link를 선택하며, master AP connection은 강제로 유지한다. Power allocation은 별도 deep model이 아니라 기존 문헌의 방식에 의존한다. 따라서 이 논문의 기여는 full radio resource management가 아니라 AP clustering decision을 neural policy로 근사한 데 있다.

## Simulation Details

| Item | Value |
| --- | --- |
| Deployment area | \(700 \times 700\,\mathrm{m}^2\) |
| AP / antennas | \(L=25\), \(N=4\) antennas per AP |
| Users | \(K=10\) UEs |
| Training / test locations | 1000 / 200 locations per UE |
| Bandwidth / carrier | 20 MHz / 2 GHz |
| Coherence block | \(\tau_c=200\) |
| Noise power | -94 dBm |
| UE uplink power | 100 mW |
| AP downlink max power | 200 mW |
| Training | 200 epochs, learning rate 0.00001, batch size 64 |
| Penalty | \(\lambda=0.04\) |

Table II의 비교는 제안 방식의 trade-off를 잘 보여준다.

| Pilot length | Method | Sum SE | Active connections |
| --- | --- | ---: | ---: |
| \(\tau_p=3\) | Heuristic [6] | 24.42 | 75 |
| \(\tau_p=3\) | Proposed DL | 23.94 | 32.60 |
| \(\tau_p=10\) | Heuristic [6] | 24.65 | 250 |
| \(\tau_p=10\) | Proposed DL | 25.42 | 38.18 |

\(\tau_p=3\)에서는 제안 방식이 SE를 약간 낮추는 대신 link 수를 절반 이하로 줄인다. \(\tau_p=10\)에서는 link 수를 훨씬 적게 유지하면서도 더 높은 sum SE를 얻는다. 이 결과는 "많이 연결할수록 항상 좋다"는 직관보다, pilot contamination과 interference까지 고려한 sparse clustering이 더 실용적일 수 있음을 보여준다.

## Claim vs Interpretation

| 논문에서 직접 주장하는 내용 | 해석할 때의 주의점 |
| --- | --- |
| LSTM 기반 clustering은 UE 수가 달라도 재학습 없이 적용될 수 있다. | 입력을 master AP와 channel gain 기준으로 정렬했기 때문에 가능한 주장이다. 완전히 다른 배치, mobility, channel model에서도 같은 성질이 보장된다는 의미는 아니다. |
| 제안 방식은 active connection 수를 크게 줄이면서 SE 손실을 제한한다. | Table II 기준으로는 성립한다. 다만 \(\lambda\), pilot length, power allocation 방식에 따라 trade-off가 달라질 수 있다. |
| Pilot contamination이 있는 환경에서도 적용 가능하다. | 모델 입력이 pilot assignment 자체를 명시적으로 최적화하지는 않는다. pilot allocation과 clustering을 함께 학습하면 더 강한 확장이 가능하다. |

## 한계와 확장 방향

1. 실험은 제한된 synthetic geometry와 channel model에 기반한다. 실제 deployment에서는 AP 배치, 사용자 밀도, mobility, blockage가 달라지므로, online calibration이나 domain randomization을 포함한 추가 검증이 필요하다.
2. 목적식은 sum SE와 active connection penalty에 집중한다. 논문이 결론에서 언급하듯 energy efficiency, latency, fronthaul budget, transmit power를 함께 다루는 multi-objective formulation으로 확장할 수 있다.
3. Pilot assignment와 power control은 완전히 end-to-end로 학습되지 않는다. Clustering, pilot allocation, power allocation을 joint policy로 다루면 pilot contamination과 load balancing을 더 직접적으로 줄일 수 있다.

## 참고자료

- [Local source PDF](/assets/pdfs/research/deep-learning-user-centric-clustering-cf-mimo/deep-learning-user-centric-clustering-cf-mimo.pdf){:target="_blank" rel="noopener"}
- [IEEE DOI](https://doi.org/10.1109/SPAWC60668.2024.10694529){:target="_blank" rel="noopener"}
- [arXiv:2410.02775](https://arxiv.org/abs/2410.02775){:target="_blank" rel="noopener"}
