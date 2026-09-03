---
layout: default
date: 2026-07-09 19:59:33 +0900
title: "Minions"
topic: "On-device small LM and cloud frontier model collaboration"
order: 37
major_topic: "Language Models & NLP"
keywords:
  - "on-device LLM"
  - "cloud collaboration"
  - "long-context reasoning"
  - "cost-efficient inference"
---

# Minions

Source PDF: `minions-on-device-cloud-collaboration.pdf`

Source URL: `https://www.together.ai/blog/minions`

## 자료 정보

| 항목 | 내용 |
|---|---|
| 논문 | Minions: Cost-efficient Collaboration Between On-device and Cloud Language Models |
| arXiv | 2502.15964v1 |
| 공개일 | 2025-02-21 |
| 저자 | Avanika Narayan, Dan Biderman, Sabri Eyuboglu, Avner May, Scott Linderman, James Zou, Christopher Re |
| 출처 | Stanford University, Together AI |
| 연결 축 | QECO-Adapt의 edge/cloud split motivation 확장 |

## 한 줄 요약

Minions는 긴 private context를 전부 cloud frontier model에 보내지 않고, local small LM이 context chunk를 읽어 중간 결과를 만들고 cloud model이 task decomposition과 aggregation을 담당하게 하는 local-remote LM 협업 프로토콜이다.

## 핵심 내용

- Minions는 local small LM과 cloud frontier model의 협업으로 long-context task의 cloud 비용을 줄이는 protocol이다.
- 단순 Minion protocol은 cloud cost를 크게 줄이지만, local model이 long context와 multi-step instruction에 취약해 성능 손실이 남는다.
- MinionS는 RemoteLM이 job generation code를 만들고, LocalLM이 context chunk별 job을 병렬 실행하고, RemoteLM이 filtered output을 집계하는 구조다.
- 논문 v1 기준 MinionS는 8B local model에서 remote-only 성능의 97.9%를 회복하면서 cloud cost는 18.0%만 사용한다.
- MEC/QECO-Adapt 관점에서는 "AI workload의 local-edge-cloud 역할 분담"을 설명하는 참고자료로 활용할 수 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 설정 | 왜 long-context reasoning을 전부 cloud model에 맡기면 비싼가? |
| 2 | Minion | local LM과 cloud LM의 자유 대화는 어디서 막히는가? |
| 3 | MinionS | task를 job 단위로 분해하면 무엇이 달라지는가? |
| 4 | 실험 결과 | 비용을 줄이면서 remote-only 성능을 얼마나 회복하는가? |
| 5 | 설계 변수 | local model 크기, parallel workload, communication round는 어떤 trade-off를 만드는가? |
| 6 | QECO-Adapt 연결 | MEC/edge-cloud offloading 연구의 broader motivation으로 어떻게 읽을 수 있는가? |

## 1. 문제 배경

논문은 local device에 있는 긴 context와 cloud frontier model 사이의 비용-성능 trade-off에서 출발한다. 예를 들어 금융 보고서, 의료 기록, 과학 논문처럼 긴 문서를 바탕으로 추론해야 하는 작업은 cloud model에 전체 context를 넣으면 토큰 비용이 커진다. 논문은 million-token code repository를 OpenAI o1 API로 처리하는 비용이 query당 15달러를 넘을 수 있다고 문제를 잡는다.

동시에 1B-8B 규모의 small LM은 개인 컴퓨터나 스마트폰에서 실행 가능할 정도로 좋아지고 있다. 그러나 작은 모델은 여전히 복잡한 reasoning이나 긴 context 처리에서 frontier model을 완전히 대체하기 어렵다. 따라서 논문의 질문은 "작은 모델만으로 충분한가?"가 아니라 "local small LM과 cloud frontier LM이 어떻게 역할을 나누면 cloud inference cost를 줄이면서 품질을 유지할 수 있는가?"이다.

## 2. 문제 정의와 비용 모델

논문이 다루는 task는 context \(c\), query \(q\), 정답 \(y\)로 정의된다. Local-remote system \(S\)는 local device의 작은 모델과 cloud의 큰 모델을 함께 사용해 \(\hat{y} \sim S(c,q)\)를 출력한다.

품질은 정답 여부 기반 accuracy로 측정한다. 비교 기준은 세 가지다.

| 기준 | 의미 |
|---|---|
| Remote only | cloud model이 전체 context와 query를 직접 읽는다. |
| Local only | local model만 context와 query를 읽는다. |
| Local-remote | local model과 remote model이 protocol에 따라 협업한다. |

비용은 cloud model 호출 비용으로 계산한다. 논문은 local model 실행 비용, local hardware 고정비, energy cost를 비용 계산에서 제외한다. Cloud cost는 input token에 해당하는 prefill token과 output token에 해당하는 decode token의 가중합으로 본다.

$$
C_{\mathrm{remote}}(n_{\mathrm{prefill}}, n_{\mathrm{decode}})
\propto
n_{\mathrm{prefill}}+\alpha n_{\mathrm{decode}}
$$

여기서 decode token은 GPU utilization과 KV cache 접근 특성 때문에 prefill token보다 더 비싸다고 설명한다. 실험 표의 비용은 2025년 1월 GPT-4o 가격인 input 1M token당 2.50달러, output 1M token당 10.00달러를 기준으로 계산된다.

## 3. 대상 작업

평가는 data-intensive reasoning에 맞는 세 benchmark에서 수행된다.

| 작업 | 문서 유형 | 요구 능력 |
|---|---|---|
| FinanceBench | 10-K report 등 금융 문서 | 재무 수치 추출과 계산 |
| LongHealth | longitudinal patient record | 의료 기록 추적과 해석 |
| QASPER | scientific paper | 논문 기반 질의응답 |

공통점은 context가 길고, 최종 답변에 필요한 정보가 일부 구간에 흩어져 있다는 점이다. 이 구조에서는 local model이 전체 문서를 먼저 훑고, cloud model은 필요한 정보만 받아 reasoning과 aggregation을 담당할 여지가 생긴다.

## 4. Minion: 자유 대화형 local-remote protocol

Minion은 가장 단순한 local-remote 협업 baseline이다. LocalLM은 전체 context를 가진 상태에서 시작하고, RemoteLM은 context 없이 query만 알고 있다. 이후 두 모델이 자유롭게 대화하면서 RemoteLM이 최종 답변을 낸다.

이 방식은 cloud model이 전체 문서를 읽지 않기 때문에 비용을 크게 줄인다. 논문은 Minion이 FinanceBench, LongHealth, QASPER에서 각각 38.13배, 31.3배, 20.9배의 RemoteLM cost reduction을 보였고, 평균적으로 remote-only와 local-only 사이 quality gap의 87.0%를 회복했다고 보고한다.

하지만 자유 대화형 protocol에는 두 가지 한계가 있다.

| 한계 | 설명 |
|---|---|
| multi-step instruction 취약성 | 작은 LM은 복잡한 지시를 한 번에 처리하기 어렵다. 논문은 sub-part를 분리하면 성능이 크게 개선된다고 분석한다. |
| long-context 취약성 | context가 길어질수록 작은 LM의 extraction 성능이 떨어진다. 논문은 1K 미만에서 65K 초과로 context가 길어질 때 단순 extraction 성능이 하락한다고 보고한다. |

따라서 작은 모델에게 "긴 문서를 읽고 복잡한 지시를 해결하라"고 통째로 맡기는 방식은 비용은 낮지만 정확도 손실이 남는다.

## 5. MinionS: decomposition-based protocol

MinionS는 Minion의 한계를 줄이기 위해 task를 더 작은 job으로 분해한다. 핵심은 RemoteLM이 전체 문서를 직접 읽지 않고도 job generation code를 만들고, local device가 이 code를 실행해 context chunk별 job을 생성한다는 점이다.

프로토콜은 세 단계 loop다.

| 단계 | 수행 위치 | 내용 |
|---|---|---|
| Job preparation | RemoteLM | query와 decomposition prompt를 바탕으로 context를 job list로 나누는 Python function을 생성한다. |
| Job execution and filtering | LocalLM | 생성된 job을 context chunk 위에서 병렬 실행하고, abstain하지 않은 결과만 남긴다. |
| Job aggregation | RemoteLM | local output을 받아 최종 답변을 만들거나 추가 round가 필요한지 판단한다. |

Job은 context-instruction pair로 볼 수 있다.

$$
t^{(i)}=(\tilde{q}^{(i)}, \tilde{c}^{(i)})
$$

LocalLM은 각 job에 대해 answer, citation, explanation을 포함한 JSON 형태의 응답을 만들도록 지시받는다. 관련 없는 chunk에서는 abstain할 수 있고, 이렇게 필터링된 결과만 cloud로 보내므로 전체 context를 그대로 전송하는 것보다 communication cost를 줄일 수 있다.

RemoteLM은 aggregation 단계에서 충분한 정보가 있으면 최종 답변을 내고, 부족하면 다시 job preparation으로 돌아간다. 논문은 round 사이의 state 유지 방식으로 단순 retry와 scratchpad 방식을 비교한다.

## 6. 주요 실험 결과

논문 Table 1의 macro average 기준 결과는 다음과 같다.

| Protocol | Local Model | Remote Model | Macro Avg. Acc. | Avg. Cost |
|---|---|---|---:|---:|
| Remote only | - | GPT-4o | 0.724 | $0.233 |
| Local only | Llama-8B | - | 0.444 | $0.000 |
| Local only | Llama-3B | - | 0.213 | $0.000 |
| Minion | Llama-8B | GPT-4o | 0.630 | $0.008 |
| Minion | Llama-3B | GPT-4o | 0.518 | $0.010 |
| MinionS | Llama-8B | GPT-4o | 0.709 | $0.042 |
| MinionS | Llama-3B | GPT-4o | 0.662 | $0.052 |
| MinionS | Qwen-3B | GPT-4o | 0.676 | $0.039 |

해석하면, Minion은 비용을 극단적으로 낮추지만 remote-only accuracy와의 gap이 남는다. 반면 MinionS는 local compute를 더 많이 쓰고 cloud로 보내는 중간 결과도 늘리면서 accuracy를 크게 회복한다.

논문 기준 핵심 수치는 다음과 같다.

| 항목 | 결과 |
|---|---|
| Minion | remote-only 대비 30.4배 cost reduction, 87% performance recovery |
| MinionS 8B local | remote-only 성능의 97.9% 회복, cloud cost 18.0% 사용 |
| MinionS 3B local | remote-only 성능의 93.4% 회복, cloud cost 16.6% 사용 |
| 평균 cost reduction | MinionS는 remote-only 대비 평균 5.7배 비용 절감 |

기존 Together AI blog의 요약 표현과 논문 표의 숫자는 약간 다르게 보일 수 있다. 이 글에서는 로컬 PDF의 arXiv v1 기준으로 8B local MinionS의 비용을 18.0%로 정리한다.

## 7. 설계 변수와 trade-off

논문은 MinionS의 성능이 protocol hyperparameter에 따라 달라진다고 분석한다.

| 설계 변수 | 논문 해석 |
|---|---|
| LocalLM 크기 | 1B는 부족하고, 3B부터 remote-only baseline에 근접하기 시작한다. 8B는 97.9% recovery까지 올라간다. |
| model family | Llama와 Qwen2.5는 서로 다른 compression-quality trade-off를 보인다. |
| task 수 | round당 task 수를 늘리면 decomposition이 세밀해져 accuracy가 오르지만 remote prefill cost도 증가한다. |
| sample 수 | local sampling을 늘리면 성능이 오를 수 있지만, 너무 많은 sample은 aggregation noise를 키운다. |
| chunk granularity | chunk를 더 잘게 나누면 local extraction이 쉬워지지만 cloud로 전달되는 filtered output이 늘 수 있다. |
| communication round | round 수를 늘리면 accuracy는 오르지만 비용도 증가한다. |

특히 논문은 local model을 information encoder처럼 해석한다. LocalLM은 긴 context를 그대로 cloud로 보내는 대신, 예측에 필요한 정보만 압축해 RemoteLM에 전달한다. 좋은 local model일수록 같은 accuracy를 더 적은 remote token으로 달성하므로 local FLOPs를 cloud communication cost와 교환하는 구조가 된다.

## 8. RAG와의 차이

MinionS는 RAG와 비슷하게 전체 context를 그대로 cloud model에 넣지 않는다는 공통점이 있다. 그러나 역할 분담이 다르다.

| 비교 축 | RAG | MinionS |
|---|---|---|
| context 처리 | retriever가 관련 chunk를 고른다. | LocalLM이 chunk 위에서 subtask를 실행한다. |
| cloud 입력 | 검색된 raw text 중심 | local model이 생성한 answer, citation, explanation 중심 |
| 강점 | 정보가 특정 구간에 모여 있을 때 효율적 | 분산된 정보 추출, chunk별 reasoning, 반복적 aggregation에 유리 |
| 한계 | retrieval miss에 취약 | local model 품질과 protocol 설계에 민감 |

FinanceBench처럼 관련 정보가 특정 section에 잘 모이는 작업에서는 RAG도 강하다. 반면 긴 문서 전체에 흩어진 정보를 통합해야 하는 summarization이나 multi-hop reasoning에서는 단순 retrieval보다 local execution과 remote aggregation의 조합이 더 자연스러울 수 있다.

## QECO-Adapt와의 연결

Minions는 직접적인 MEC offloading 최적화 논문은 아니지만, QECO-Adapt와 비교할 수 있는 broader motivation을 제공한다. 두 자료 모두 "계산을 어디서 수행할 것인가"를 다룬다.

| 비교 축 | QECO-Adapt | Minions |
|---|---|---|
| 로컬 주체 | UE/mobile device | Consumer device의 local small LM |
| 원격 주체 | AP/channel/resource를 거친 edge server | Cloud frontier model |
| 핵심 병목 | edge backlog, delay, energy, dropped task | cloud token cost, long-context cost, local model 한계 |
| 제어 방식 | load-adaptive reward/cost reweighting과 offloading gating | decomposition-execution-aggregation communication protocol |
| 공통 질문 | 어떤 계산을 로컬에 남기고, 어떤 계산을 원격으로 보낼 것인가? | 어떤 context 처리와 reasoning을 local/cloud에 나눌 것인가? |

QECO-Adapt의 UE -> AP -> channel/resource -> edge server 구조는 통신 지연, edge load, energy를 중심으로 offloading을 결정한다. Minions는 network/MEC 수식은 없지만, local small model이 긴 context 처리라는 계산을 담당하고 cloud model은 고난도 reasoning과 aggregation을 담당한다는 split framing을 제공한다.

따라서 QECO-Adapt 후속 설명에서는 Minions를 "AI workload도 점점 local-edge-cloud split 문제로 이동한다"는 motivation 자료로 활용할 수 있다.

## 해석 포인트

이 논문은 "작은 모델이 큰 모델을 대체한다"는 주장보다 "작은 모델을 local information encoder와 parallel worker로 쓰고, 큰 모델을 decomposition/aggregation controller로 쓰자"는 주장에 가깝다. 따라서 QECO-Adapt와 연결할 때도 단순한 모델 경량화 사례가 아니라, 계산 위치와 communication volume을 함께 최적화하는 local-cloud split 사례로 읽는 편이 적절하다.

다만 논문의 비용 모델은 local execution을 free로 두고 hardware amortization, device energy, local latency를 제외한다. 실제 MEC나 mobile deployment와 비교하려면 local energy, queueing delay, wireless transmission cost를 추가해야 한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/minions-on-device-cloud-collaboration/minions-on-device-cloud-collaboration.pdf" | relative_url }}" target="_blank" rel="noopener">minions-on-device-cloud-collaboration.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2502.15964" target="_blank" rel="noopener">arXiv:2502.15964 - Minions: Cost-efficient Collaboration Between On-device and Cloud Language Models</a></li>
  <li><a href="https://www.together.ai/blog/minions" target="_blank" rel="noopener">Together AI Blog: Minions</a></li>
</ul>
