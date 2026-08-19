---
layout: default
title: "QoE-Driven SIM"
topic: "QoE-driven resource allocation for stacked intelligent metasurface systems"
order: 72
major_topic: "Wireless Communications & Resource Allocation"
keywords:
  - "Stacked intelligent metasurface"
  - "Quality of experience"
  - "Conservative Q-learning"
  - "Meta-learning"
  - "Mean opinion score"
---

# QoE-Driven Resource Allocation for Stacked Intelligent Metasurface Systems

Source PDF: `qoe-driven-resource-allocation-for-stacked-intelligent-metasurface-systems.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | QoE-Driven Resource Allocation for Stacked Intelligent Metasurface Systems |
| 출처 | IEEE PIMRC 2025, Track 3: Mobile and Wireless Networks |
| DOI | 10.1109/PIMRC62392.2025.11275274 |
| 저자 | Hosein Zarini, S. Mohsen Kazemi, Jiancheng An, Ali Movaghar, Mehdi Sookhak, Nuri Yilmazer |
| 주제 | QoE-driven resource allocation for stacked intelligent metasurface systems |
| 핵심 방법 | Meta-enhanced conservative Q-learning for joint transmit-power and SIM response control |

## 한 줄 요약

이 논문은 stacked intelligent metasurface가 wave-domain beamforming을 수행하는 downlink에서 BS power와 SIM phase response를 Meta-CQL로 함께 조정해 web, video, audio 사용자의 mean opinion score를 높인다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | SIM architecture | 여러 metasurface layer가 RF chain 대신 wave-domain beamforming을 어떻게 수행하는가? |
| 2 | QoE modeling | Data rate를 web, video, audio의 MOS로 어떻게 변환하는가? |
| 3 | Joint optimization | BS power와 SIM electromagnetic response를 왜 함께 조정해야 하는가? |
| 4 | Meta-CQL | Mobility가 있는 환경에서 CQL의 적응 속도를 어떻게 높이는가? |
| 5 | Evaluation | QoS 중심 allocation보다 서비스별 MOS가 얼마나 개선되는가? |

## 한국어 번역형 해설

### QoS에서 QoE로 목적을 바꾸기

전통적인 wireless resource allocation은 data rate, latency 또는 energy efficiency를 직접 최적화한다. 그러나 동일한 rate 변화도 web page loading, live video와 VoLTE에서 사용자가 느끼는 차이는 다르다. 논문은 서비스별 체감 품질을 mean opinion score, 즉 MOS로 바꾸어 optimization objective로 사용한다.

| 서비스 | QoE 연결 방식 | MOS에 영향을 주는 요소 |
|---|---|---|
| Web browsing | Page loading delay의 logarithmic function | RTT, file size, TCP slow start, data rate |
| HTTP live video | Rate에서 PSNR을 계산한 뒤 piecewise MOS로 변환 | Encoding parameters, achievable rate |
| VoLTE audio | ITU-T G.107 R-factor와 rate 기반 model 사용 | Voice rate와 perceived audio quality |

이 구조의 의미는 모든 사용자에게 단순히 같은 rate를 주는 것이 아니라, 각 서비스에서 최소 만족도를 지키면서 전체 MOS를 높이는 것이다.

### Stacked intelligent metasurface

SIM은 여러 transmissive metasurface layer를 쌓고 각 meta-atom의 phase shift를 제어한다. Layer \(l\)의 transmission matrix를 \(\Gamma^l=\mathrm{diag}(\Phi^l)\), layer 사이 propagation matrix를 \(B^l\)라고 하면 전체 electromagnetic response는 다음과 같다.

$$
\Omega=\Gamma^L B^L\Gamma^{L-1}B^{L-1}\cdots\Gamma^2B^2\Gamma^1.
$$

사용자 \(u\)의 received signal은 BS power allocation과 \(\Omega\)가 함께 결정한다. 따라서 optimization variable은 BS의 사용자별 transmit power \(P\)와 SIM response \(\Omega\)를 묶은 \(\Psi=\{P,\Omega\}\)다. 각 사용자의 최소 MOS, BS maximum power, SIM layer propagation과 phase range를 constraint로 둔다.

### Optimization problem

서비스 \(\ell\in\{\text{Web},\text{Video},\text{Audio}\}\)에 대해 목적은 다음 형태다.

$$
\max_{\Psi}\sum_{u\in U}\mathrm{MOS}_{\ell,u}
$$

각 user의 minimum MOS를 만족하고 total transmit power가 \(P^{\max}\)를 넘지 않아야 한다. MOS function과 SIM response가 nonconvex이고 변수들이 강하게 결합되어 있어 반복적 convex optimization은 많은 matrix computation과 convergence time을 요구한다. 논문은 real-time mobility를 고려해 문제를 MDP로 바꾸고 CQL agent가 resource allocation을 선택하도록 한다.

### MDP와 Meta-CQL

| MDP 요소 | 구성 |
|---|---|
| Agent | Wireless resource를 제어하는 edge node |
| State | 이전 time step에서 관측된 사용자별 SINR |
| Action | BS power와 SIM electromagnetic response를 포함한 \(\Psi\) |
| Objective signal | 사용자 MOS 합과 constraint penalty |

CQL은 경험 데이터에서 충분히 관측되지 않은 action의 Q-value를 보수적으로 낮춰 overestimation을 줄이려는 방법이다. 논문은 여기에 meta-learning의 inner loop와 outer loop를 결합한다. Inner loop는 특정 mobility 또는 service task에 정책을 적응시키고, outer loop는 여러 task에서 빠르게 조정될 initialization을 학습한다.

연구자의 해석으로는 CQL과 meta-learning의 결합은 서로 다른 역할을 맡는다. CQL은 training data 밖 action에 대한 과신을 줄이고, meta-learning은 network condition이 바뀔 때 적은 update로 policy를 다시 맞추는 역할을 한다. 다만 논문은 offline dataset 구성과 online interaction boundary를 상세히 제시하지 않으므로, 재현 시에는 data collection protocol을 별도로 명시해야 한다.

### 실험 설정과 주요 결과

기본 simulation은 사용자 50명, time slot 100개, slot duration 0.1초, BS maximum power 46 dBm, SIM layer 5개를 사용한다. Meta-CQL은 standard CQL보다 더 빠르게 수렴하고 높은 reward를 보이며, random allocation보다 큰 차이를 나타낸다.

| 서비스 | 비교 기준 | 보고된 평균 MOS 개선 |
|---|---|---:|
| Web browsing | Traditional QoS-driven resource allocation | 31% |
| HTTP live video | Traditional QoS-driven resource allocation | 44% |
| VoLTE audio | Traditional QoS-driven resource allocation | 26% |

BS power budget이 커지면 feasible region이 넓어져 web MOS가 증가한다. Video minimum MOS requirement를 높이면 feasible set이 좁아져 평균 video MOS가 내려간다. BS antenna element와 사용자 stream을 일대일로 늘리는 audio 실험에서는 antenna gain과 inter-user interference가 함께 증가해 MOS가 포화되는 경향을 보인다.

### 수식 해석 시 주의점

원문 reward 설명은 constraint indicator를 `constraint가 만족되면 \(\chi_i=1\), 아니면 0`으로 정의한 뒤 MOS 합에서 \(\chi_i\)가 곱해진 항을 빼도록 적는다. 이 정의를 문자 그대로 적용하면 constraint를 더 많이 만족할수록 reward가 더 크게 감소하므로, 바로 다음 문장의 `constraint adherence` 목적과 반대가 된다.

일반적인 penalty 설계라면 violation일 때 indicator가 1이 되거나, 만족 시 1인 indicator에는 반대 부호 구조가 필요하다. 따라서 구현 전 저자 코드 또는 정정 자료로 \(\chi_i\) 정의를 확인해야 한다. 이 글은 원문의 수식을 임의로 수정하지 않고, 재현 과정에서 확인해야 할 표기 문제로 남긴다.

## 논문의 핵심 기여

- SIM 기반 wave-domain beamforming을 multimedia service의 QoE와 직접 연결한다.
- Web, video, audio별 MOS model을 사용해 단순 rate maximization보다 사용자 만족도에 가까운 목적함수를 구성한다.
- BS transmit power와 SIM phase response를 하나의 action으로 공동 제어한다.
- CQL에 meta-learning을 결합해 mobility와 network dynamism에 대한 빠른 적응을 목표로 한다.
- 서비스별로 기존 QoS 중심 allocation 대비 31%, 44%, 26%의 평균 MOS 개선을 보고한다.

## 한계와 해결 방향

실험은 simulation과 사전에 설정된 MOS model에 의존한다. 실제 사용자 만족도는 device, content, codec, buffering과 주관적 preference에 따라 달라질 수 있으므로 field data로 MOS parameter를 calibration해야 한다. 해결 방향은 service telemetry와 user study를 이용한 model calibration, 그리고 MOS prediction uncertainty를 constraint에 반영하는 robust optimization이다.

State가 이전 slot의 SINR만 포함하므로 queue, mobility trajectory, service state와 channel uncertainty를 충분히 표현하지 못할 수 있다. Recurrent 또는 belief-state encoder를 추가하고 observation ablation을 수행하면 partial observability를 줄일 수 있다. 또한 SIM hardware의 quantized phase, calibration error, insertion loss와 control overhead를 포함한 hardware-in-the-loop 검증이 필요하다. 이러한 검증을 거치면 multi-service scheduling, personalized QoE와 energy-aware SIM control로 확장할 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/qoe-driven-resource-allocation-for-stacked-intelligent-metasurface-systems/qoe-driven-resource-allocation-for-stacked-intelligent-metasurface-systems.pdf" | relative_url }}" target="_blank" rel="noopener">Local source PDF</a></li>
  <li><a href="https://ieeexplore.ieee.org/document/11275274/" target="_blank" rel="noopener">IEEE Xplore</a></li>
  <li><a href="https://doi.org/10.1109/PIMRC62392.2025.11275274" target="_blank" rel="noopener">DOI: 10.1109/PIMRC62392.2025.11275274</a></li>
</ul>
