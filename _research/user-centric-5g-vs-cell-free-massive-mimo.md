---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "User-Centric 5G"
topic: "User-centric 5G cellular networks versus cell-free massive MIMO"
order: 66
major_topic: "Wireless Networks & Massive MIMO"
keywords:
  - "user-centric 5G"
  - "cell-free massive MIMO"
  - "resource allocation"
  - "network comparison"
---

# User-Centric 5G Cellular Networks: Resource Allocation and Comparison with the Cell-Free Massive MIMO Approach

**Resources:** <a href="/assets/pdfs/research/user-centric-5g-vs-cell-free-massive-mimo/user-centric-5g-vs-cell-free-massive-mimo.pdf" target="_blank" rel="noopener">Paper PDF</a> · <a href="/assets/seminars/user-centric-5g-vs-cell-free-massive-mimo/user-centric-cf-seminar-ko-v1.pdf" target="_blank" rel="noopener">Seminar PDF</a>

## Paper Information

| Field | Detail |
|---|---|
| Title | User-Centric 5G Cellular Networks: Resource Allocation and Comparison with the Cell-Free Massive MIMO Approach |
| Authors | Stefano Buzzi, Carmen D'Andrea, Alessio Zappone |
| Venue | IEEE Transactions on Wireless Communications 19(2):1250-1264, 2020 |
| DOI | <a href="https://doi.org/10.1109/TWC.2019.2952117" target="_blank" rel="noopener">10.1109/TWC.2019.2952117</a> |
| Topic | Resource allocation and architecture comparison between user-centric distributed MIMO and cell-free massive MIMO |

## 한 줄 요약

이 논문은 가까운 일부 AP만 각 사용자를 서비스하는 user-centric 구조가 cell-free massive MIMO의 all-AP overhead를 줄이면서, 특히 uplink에서 더 나은 achievable rate-per-user를 제공할 수 있음을 보입니다.

## 핵심 내용

이 논문은 cell-free massive MIMO가 모든 AP(access point)가 모든 MS(mobile station)를 서비스한다는 이상적 구조를 가질 때 생기는 overhead를 지적하고, 각 MS가 가까운 일부 AP 집합에서만 서비스되는 user-centric(UC) 구조와 비교합니다. 저자들의 핵심 결론은 UC approach가 backhaul 부담을 줄이면서도 대부분의 사용자에게 더 나은 achievable rate-per-user를 줄 수 있으며, 특히 uplink에서 그 차이가 뚜렷하다는 것입니다.

## 논문 전개

| 단계 | 내용 | 읽을 포인트 |
|---:|---|---|
| 1 | Architecture motivation | CF massive MIMO의 all-AP serving이 넓은 area에서 왜 비효율적입니까? |
| 2 | System and channel model | `K` MS, `M` AP, TDD coherence interval, pilot training을 어떻게 둡니다. |
| 3 | UC clustering | AP가 estimated channel Frobenius norm 기준으로 strongest `N` MS만 서비스합니다. |
| 4 | Power allocation | Sum-rate maximization과 minimum-rate maximization을 downlink/uplink에 적용합니다. |
| 5 | Numerical comparison | UC와 CF를 uniform, sum-rate, minimum-rate power allocation에서 비교합니다. |

## 한국어 번역형 해설

### 배경과 문제의식

Cell-free massive MIMO는 다수의 distributed AP가 cell boundary 없이 사용자를 공동 서비스한다는 점에서 coverage와 fairness를 개선합니다. 그러나 모든 AP가 모든 MS를 처리하면, 멀리 떨어져 SINR이 낮은 user를 위해 AP power, computation, backhaul을 쓰는 상황이 생깁니다. 논문은 이 지점을 practical inefficiency로 보고, 각 AP가 가까운 사용자 subset만 처리하는 user-centric architecture를 제안합니다.

이 논문의 차별점은 AP와 MS가 모두 multiple antenna를 갖는 case까지 CF/UC comparison을 확장했다는 점입니다. 또한 MS에서 별도 downlink channel estimation을 요구하지 않고, 많은 transmitting antenna로 생기는 channel hardening effect를 이용해 channel-inverting beamforming을 구성합니다.

### 시스템 모델과 통신 절차

System은 `K`개의 MS와 `M`개의 AP로 구성되고, 모든 AP는 backhaul network를 통해 CPU에 연결됩니다. Uplink와 downlink는 TDD로 나뉘며, coherence interval은 uplink channel estimation, downlink data transmission, uplink data transmission의 세 phase로 구성됩니다. 논문은 MS antenna 수를 `N_{MS}`, AP antenna 수를 `N_{AP}`로 두고, channel matrix `G_{k,m}`, large-scale coefficient `\beta_{k,m}`, coherence length `\tau_c`, pilot length `\tau_p`, pilot matrix `\Phi_k`를 사용합니다.

CF architecture에서는 모든 AP가 모든 MS의 downlink transmission과 uplink decoding에 참여합니다. UC architecture에서는 AP `m`이 service set `K(m)`에 속한 MS만 처리하고, user `k`는 AP set `M(k)`로부터 서비스됩니다. 논문이 사용하는 UC selection은 각 AP가 estimated channel의 Frobenius norm을 내림차순으로 정렬하고, design parameter `N`에 따라 strongest `N`명의 MS만 선택하는 방식입니다. 따라서 CF는 `N=K`인 UC의 special case로 볼 수 있습니다.

Uplink에서는 UC가 backhaul overhead를 직접 줄입니다. CF에서는 모든 AP가 모든 user의 soft estimate를 CPU로 보내야 하지만, UC에서는 associated MS에 대한 soft estimate만 보내면 됩니다. 이 차이는 paper가 UC의 practical value를 강조하는 핵심 근거입니다.

### Power allocation 방법

논문은 downlink와 uplink 모두에서 두 목적 함수를 다룹니다.

- Sum-rate maximization: 전체 system data rate를 최대화합니다.
- Minimum-rate maximization: 가장 낮은 user rate를 끌어올려 fairness를 개선합니다.

Downlink power coefficient는 `\eta_{k,m}^{DL}`로 표현되고, variable 수는 대략 `K M`으로 커집니다. 이 optimization은 non-concave라 직접 풀기 어렵기 때문에, 저자들은 alternating optimization과 sequential convex programming을 결합한 successive lower-bound maximization을 사용합니다. Algorithm 1은 sum-rate maximization, Algorithm 2는 minimum-rate maximization을 다루며, 각 iteration 뒤 objective가 감소하지 않고 limit point가 KKT first-order optimality condition을 만족한다는 proposition을 제시합니다.

Uplink는 optimization variable이 user별 transmit power 중심이라 downlink보다 작습니다. 논문은 uplink rate도 두 concave function의 차이로 표현할 수 있음을 이용해 downlink와 유사한 sequential optimization framework를 적용합니다.

### 실험 설정과 결과

Simulation은 `1000 x 1000` m² square area에서 수행되며, carrier frequency `f_0=1.9` GHz, bandwidth `W=20` MHz, AP antenna height 15 m, MS antenna height 1.65 m, shadow fading standard deviation `\sigma_{sh}=8` dB를 사용합니다. Boundary effect를 줄이기 위해 wrap-around를 적용하고, 100개의 random scenario realization 평균을 보고합니다. 기본 antenna setting은 `N_{AP}=4`, `N_{MS}=2`, user당 multiplexing order `P_k=2`이며, uplink training power는 `p_k=100` mW입니다.

High-density scenario는 `M=80`, `K=15`, `N=6`, `\tau_p=16`이고, low-density scenario는 `M=50`, `K=5`, `N=2`, `\tau_p=8`입니다. Downlink에서는 AP maximum power를 200 mW로 두고, uplink에서는 MS maximum power를 100 mW로 둡니다. 비교는 perfect CSI와 partial CSI, uniform power allocation, sum-rate maximizing allocation, minimum-rate maximizing allocation을 모두 포함합니다.

결과는 downlink에서 uniform allocation과 minimum-rate maximization을 사용할 때 UC approach가 CF approach보다 우수하다고 보고합니다. Sum-rate maximization에서는 CF가 UC보다 나은 경우가 있지만, 그 차이는 제한적이라고 설명합니다. Uplink에서는 여기서 고려한 모든 power allocation strategy에서 UC approach가 CF approach보다 낫고, 일부 상황에서는 CF 대비 여러 배의 improvement를 보장한다고 보고합니다. 이 결과는 "가까운 AP만 쓰는 구조가 항상 손해"라는 직관을 반박하고, AP/user association을 잘 제한하면 rate와 overhead를 동시에 개선할 수 있음을 보여줍니다.

### 논문 주장과 읽기 해석

| 구분 | 내용 |
|---|---|
| 논문 주장 | UC architecture는 CF보다 backhaul overhead가 낮고, network 내 대다수 MS의 achievable rate-per-user를 개선할 수 있습니다. |
| 논문 주장 | CF는 `N=K`인 UC special case이므로, 두 구조는 단절된 개념이 아니라 같은 framework 안에서 비교할 수 있습니다. |
| 논문 주장 | Uplink에서는 UC가 모든 power allocation strategy에서 CF보다 우수한 결과를 보입니다. |
| 읽기 해석 | UC의 장점은 "협력을 줄이는 것" 자체가 아니라, 낮은 SINR link를 제거해 useful cooperation에 resource를 집중하는 데 있습니다. |
| 읽기 해석 | Sum-rate objective와 minimum-rate objective가 서로 다른 결론을 낼 수 있으므로, deployment 목적이 throughput인지 fairness인지 먼저 정해야 합니다. |

### 한계와 확장 방향

첫째, AP selection이 channel norm 기반으로 비교적 단순합니다. 이는 설명 가능하고 계산이 쉽지만, user mobility, queue state, traffic class, fronthaul congestion을 동시에 반영하지는 않습니다. 확장 방향은 long-term large-scale fading 기반 cluster와 short-term traffic-aware scheduling을 분리하고, online learning이나 bandit 기반 cluster update를 붙이는 것입니다.

둘째, 논문은 physical-layer simulation 중심입니다. 실제 5G deployment에서는 CPU placement, fronthaul scheduling, synchronization, handover, management-plane overhead가 성능을 좌우합니다. Multiple CU 구조, distributed SDN controller, radio stripe 같은 deployment 요소와 함께 재평가해야 UC의 operational gain을 더 정확히 측정할 수 있습니다.

셋째, future work로 논문이 직접 제시한 방향은 millimeter wave frequency에서의 CF/UC comparison, uRLLC 지원 가능성, NOMA 같은 5G-and-beyond multiple access와의 결합입니다. 이 방향은 단순한 성능 확장이 아니라, beam blockage, low-latency reliability, multi-user interference를 UC cluster design 안에 함께 넣는 문제로 이어집니다.

## Seminar Materials
| Materials | Slides | PDF | PowerPoint | Study Notes | Speaker Notes |
| --- | ---: | --- | --- | --- | --- |
| Korean Seminar | 27 slides | <a href="/assets/seminars/user-centric-5g-vs-cell-free-massive-mimo/user-centric-cf-seminar-ko-v1.pdf" target="_blank" rel="noopener">View</a> | <a href="/assets/seminars/user-centric-5g-vs-cell-free-massive-mimo/user-centric-cf-seminar-ko-v1.pptx" download>Download</a> | <a href="/assets/seminars/user-centric-5g-vs-cell-free-massive-mimo/slides-v1.md.txt" download="slides-v1.md">Markdown</a> | <a href="/assets/seminars/user-centric-5g-vs-cell-free-massive-mimo/presenter-notes-v1.md.txt" download="presenter-notes-v1.md">Markdown</a> |

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/user-centric-5g-vs-cell-free-massive-mimo/user-centric-5g-vs-cell-free-massive-mimo.pdf" | relative_url }}" target="_blank" rel="noopener">user-centric-5g-vs-cell-free-massive-mimo.pdf</a></li>
  <li><a href="https://doi.org/10.1109/TWC.2019.2952117" target="_blank" rel="noopener">DOI: 10.1109/TWC.2019.2952117</a></li>
</ul>
