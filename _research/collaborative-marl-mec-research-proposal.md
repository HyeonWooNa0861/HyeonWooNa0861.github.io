---
layout: default
date: 2026-09-12 18:42:46 +0900
title: "Collaborative MARL Proposal"
topic: "Research proposal for collaborative device-edge and edge-edge offloading"
order: 80
major_topic: "Edge Computing & Task Offloading"
keywords:
  - "Collaborative MARL Proposal"
  - "Research seminar"
---

# Multi-Agent Deep Reinforcement Learning for Collaborative Computation Offloading in Mobile Edge-Computing

## 논문 정보

| 항목 | 내용 |
| --- | --- |
| 제목 | Multi-Agent Deep Reinforcement Learning for Collaborative Computation Offloading in Mobile Edge-Computing |
| 저자 | Iman Rahmati |
| 문서 성격 | 3쪽짜리 Research Proposal. 완성된 알고리즘·실험 논문이 아님 |
| 연도 | 본문에 발표·출판 연도 미기재 |
| 구성 | Abstract, Introduction, Problem Statement and Solution Approach, References |

## 한 줄 요약

모바일 기기에서 엣지 노드로 보내는 D2E와 엣지 노드 간 E2E 오프로딩을 함께 다루기 위해 Dec-POMDP와 다중 에이전트 DRL을 제안하지만, 성능 향상을 입증할 실험 결과는 아직 제시하지 않는다.

## 핵심 내용

- **문제:** 기존 D2E 중심의 작업 배치에서는 어떤 엣지 노드(EN)의 여유 계산 자원을 다른 EN이 이용할 기회를 놓칠 수 있다. 저자는 모바일 기기(MD)와 EN 모두를 의사결정 주체로 삼아 D2E·E2E를 연결하려 한다(원문 pp. 1-2).
- **방법의 방향:** 각 주체가 네트워크 일부만 관측하는 상황을 Dec-POMDP로 보고, 서로 다른 계층·시점의 결정을 분리한다. 해법 후보는 에이전트별 분산 actor와 중앙 critic을 둔 multi-agent DDPG다(원문 p. 2).
- **결과와 의의:** 원문은 큐 기반 협력 모델과 MARL 해법을 *제안된 기여*로 열거한다. 지연·에너지·자원 활용률의 실측 수치나 비교 실험은 없으므로, 개선 효과는 연구 가설로 읽어야 한다(원문 pp. 2-3).

## 전체 흐름

| 원문 위치 | 다루는 내용 | 이 글에서의 해석 |
| --- | --- | --- |
| p. 1, Abstract | D2E와 E2E를 포괄하는 협력 오프로딩, 큐 기반 다계층 모델, Dec-POMDP와 multi-agent DRL | 연구 목표와 모델링 방향의 선언 |
| pp. 1-2, Introduction | 기존 D2E 중심 연구, EN 간 자원 공유 동기, 부분 관측과 다른 에이전트의 정책 변화 | 왜 단일 주체의 결정만으로는 문제를 다루기 어려운지에 대한 문제 제기 |
| p. 2, Problem Statement and Solution Approach | 결정 계층·시점의 분리, MD·EN의 에이전트, 분산 actor·중앙 critic, 두 가지 기여 항목 | 구현 명세가 아닌 제안 구조 |
| p. 3, References | 배경이 된 MEC·RL·MARL·Dec-POMDP 문헌 | 제안의 개념적 출처. 이 문서 자체의 실험 자료는 아님 |

## 문제 배경과 문제 정의

MEC에서는 계산량이 크고 시간에 민감한 작업을 MD 가까이 있는 EN에서 처리할 수 있다. 그러나 무선 상태, 기기 성능, 작업 요청과 EN의 가용 자원이 시시각각 달라진다. 오프로딩은 단순히 “보낼 것인가”만 결정하는 일이 아니다. 작업을 맡을 계산 주체와 전송 링크를 고르는 선택이 함께 따라온다(원문 p. 1, Introduction).

저자는 선행 RL 기반 연구 [5]-[10]의 주된 관심을 MD에서 EN으로 향하는 D2E 결정으로 정리하고, EN끼리 남는 계산 자원을 나누는 협력에 연구 공백이 있다고 주장한다. 이는 *이 제안서의 선행연구 해석*이지, [5]-[10] 각각의 기여를 이 글이 독립적으로 재평가했다는 뜻은 아니다. 논문이 제안하는 확장은 MD뿐 아니라 EN도 작업을 다른 EN에 맡길 수 있게 하자는 것이다(원문 pp. 1-2).

| 구분 | 결정 주체와 링크 | 기대하는 역할 | 원문에서 정하지 않은 것 |
| --- | --- | --- | --- |
| D2E | MD에서 EN으로 가는 링크 | 모바일 작업을 엣지 계산 자원에 연결 | 목적 EN 선택 규칙, 무선 자원 제약 |
| E2E | EN에서 다른 EN으로 가는 링크 | 여유 EN의 계산 자원을 협력적으로 이용 | 전달 시점·횟수, 전송 비용, 목적 EN의 수락 조건 |

두 링크를 함께 고려한다고 해서 모든 작업이 반드시 D2E 다음 E2E를 거쳐야 한다는 뜻은 아니다. 또한 E2E 전달이 로컬 EN 처리보다 언제 유리한지도 이 문서는 증명하지 않는다. 가능한 경로와 실제로 허용할 경로·정책을 구분해야 한다.

각 MD와 EN은 전체 네트워크 상태가 아니라 자신에게 제한적으로 보이는 정보로 결정한다. 다른 에이전트도 동시에 학습·행동하면, 한 에이전트 관점의 환경은 상대 정책 변화에 따라 달라질 수 있다. 저자는 이를 단일 에이전트 RL의 비정상성 문제로 연결하고 협력형 MARL의 필요성을 제기한다. 다만 단일 에이전트 방법이 언제나 실패한다는 비교 결과를 제시한 것은 아니다(원문 pp. 1-2, Introduction).

## 제안 방법과 시스템 구조

### 큐 기반 다계층 협력

초록은 *queue-based multi-layer model scenario*를, 2절은 계층별 오프로딩 결정을 서로 다른 시점에 내리는 구상을 제시한다. 이를 읽을 때의 핵심은 MD의 D2E 선택과 EN의 E2E 선택을 하나의 순간에 묶지 않는다는 점이다. 작업이나 자원 상태가 바뀌면 해당 계층의 결정도 조정할 수 있다는 것이 저자의 기대다(원문 pp. 1-2).

그러나 큐가 MD·EN 중 어디에 놓이는지, 도착·서비스·전달·폐기 이벤트가 어떤 순서로 일어나는지, 계층별 시계가 어떻게 동기화되는지는 쓰여 있지 않다. 따라서 “큐 기반”을 대기열 갱신식이나 구현된 스케줄러가 이미 있다는 의미로 확대하면 안 된다. 마찬가지로 *asynchronous*는 결정 시점이 다를 수 있다는 제안이지, 확정된 타임라인이나 충돌 해결 규칙을 뜻하지 않는다.

### 부분 관측을 Dec-POMDP로 보는 이유

Dec-POMDP는 여러 주체가 제한된 관측으로 공동의 목표를 향해 결정하는 문제 틀이다. 이 제안서에서 MD와 EN은 서로 다른 결정자이며, 전체 네트워크 상태를 완전히 알지 못한 채 시스템 성능을 높이려 한다(원문 p. 2, Problem Statement and Solution Approach; 참고문헌 [16]).

| 구성 요소 | 원문이 밝힌 수준 | 재현 가능한 문제 정의에 더 필요한 명세 |
| --- | --- | --- |
| 에이전트 | MD와 EN이 각각 에이전트를 구성·훈련 | 에이전트 수, 소속, 생성·종료 조건 |
| 관측 | 네트워크와 다른 주체에 관한 부분 정보 | 실제 관측 변수, 갱신 주기, 정보 전달 범위 |
| 행동 | 계층별 오프로딩 결정 | D2E·E2E 행동 집합, 연속·이산 여부, 실행 가능성 제약 |
| 상태·전이 | 동적·불확실한 MEC 환경을 전제 | 작업 도착, 큐, 링크, CPU 상태의 전이 규칙 |
| 공동 목표 | 전체 시스템 성능과 자원 활용 개선 | 보상 함수, 목표 간 가중치, 제약 위반 처리 |

이 표의 오른쪽 열은 **필자가 식별한 후속 명세**이며 원문에 이미 정의된 구성 요소가 아니다. 특히 “전체 성능”이라는 표현만으로 지연, 에너지, QoE 또는 처리량 중 무엇을 최적화하는지 확정할 수 없다.

### 분산 actor와 중앙 critic

저자는 MD와 EN이 각각 에이전트를 갖고, 그 에이전트마다 *decentralized actor*와 *centralized critic*을 두는 multi-agent DDPG 접근을 제시한다(원문 p. 2; 참고문헌 [17]). 이 구상은 각 주체의 분산 결정과 에이전트 간 협력을 함께 겨냥한다. 그러나 중앙 critic의 입력에 어떤 전역 정보가 들어가는지, actor가 실행 중 무엇을 관측하는지, 파라미터를 공유하는지, 어떤 순서로 업데이트하는지는 적지 않았다. 따라서 여기서 네트워크 구조·학습식·훈련 절차를 구현 완료된 알고리즘으로 소개할 수 없다.

## 수식·알고리즘과 가정의 경계

원문 세 쪽에는 번호 붙은 수식, 큐 전이식, 보상식, DDPG gradient, pseudocode, 그림과 표가 없다. 따라서 이 글도 원저자의 식인 것처럼 새로운 수식을 삽입하지 않는다. 방법을 실험 가능한 모델로 바꾸려면 최소한 다음 가정과 정의가 필요하다.

1. 작업의 입력 크기·계산 요구량·마감시간과 도착 과정, 그리고 MD·EN의 계산 및 통신 용량을 정의해야 한다.
2. D2E와 E2E의 지연·에너지·전송 비용, EN 사이 연결 가능 여부, 큐의 위치와 처리 순서를 명시해야 한다.
3. 각 에이전트의 관측·행동·보상 및 중앙 critic의 입력·학습 접근 권한을 정해야 한다.
4. 서로 다른 시점의 결정이 같은 작업에 충돌하거나 전달을 반복할 때의 제약을 정해야 한다.

이는 원문이 **검증한 가정 목록이 아니라**, 제안된 Dec-POMDP와 MARL을 재현하려면 확인해야 할 설계 질문이다. 값이나 분포를 임의로 채워 넣으면 제안서의 결과와 별개의 실험이 된다.

## 실험 설정과 주요 결과

**보고된 실험: 없음.** 원문에는 데이터셋·시뮬레이터, MD/EN 수, 작업 도착률, 링크·CPU 조건, 비교 기준, 반복 횟수, 성능 표나 그래프가 없다. 2절의 “성능 향상”과 “효율·반응성 개선” 표현은 목표 또는 기대 효과이지 관측 결과가 아니다(원문 pp. 1-3 전체 확인).

후속 연구에서 이 주장을 검증하려면 동일한 작업·자원·무선 조건에서 적어도 D2E만 허용한 정책과 D2E+E2E 정책을 비교해야 한다. E2E가 도입하는 추가 전송 지연과 비용을 포함한 종단 간 지연, 에너지, 마감시간 위반율, EN별 이용률, 그리고 학습 안정성을 함께 측정해야 자원 공유의 순효과를 판단할 수 있다. 부하가 한 EN에 몰릴 때와 균등할 때를 나누고 여러 무작위 초기화에서 결과 변동도 확인해야 한다. **이 비교 설계와 지표는 필자의 검증 제안이며, 원문이 수행한 실험이 아니다.**

| 현재 말할 수 있는 것 | 현재 말할 수 없는 것 |
| --- | --- |
| EN 사이의 여유 자원을 활용하려는 연구 목표가 있다 | E2E가 D2E 단독보다 빠르거나 에너지를 덜 쓴다 |
| Dec-POMDP와 multi-agent DDPG가 해법 후보로 적혀 있다 | 이 방법이 다른 MARL·단일 에이전트 정책보다 우수하다 |
| 온라인·비동기 결정의 필요성을 주장한다 | 특정 부하·링크 조건에서 시스템 안정성이 보장된다 |

## 제안된 기여와 해석 포인트

원문 p. 2는 기여를 두 갈래로 제시한다. 첫째, D2E와 E2E를 포함하는 큐 기반 협력 MEC 시나리오다. 둘째, 온라인·비동기 다중 주체 결정을 다루기 위한 MARL 기반 해법이다. 두 항목 모두 *제안*의 내용이며 실험으로 입증된 성능 기여와 구분한다.

**해석 포인트:** 이 문서의 강점은 “기기에서 어느 EN으로 보낼까”라는 문제를 “받은 EN이 다른 EN과 어떻게 협력할까”까지 확장한다는 데 있다. 반면 협력의 실제 이득은 E2E 통신 비용, 목적 EN의 남는 용량, 관측 가능한 정보에 달려 있다. 여유 자원이 있다는 사실만으로 전달이 항상 유리해지지 않는다.

**Source Check:** p. 1 본문은 참고문헌 [5]를 계산 오프로딩 선행연구의 예로 소개하지만, p. 3에 기재된 [5]의 제목은 *Deep reinforcement learning for user association and resource allocation in heterogeneous cellular networks*다. 제목만으로 그 연구의 전체 범위를 판정하지는 않되, [5]를 이 제안의 D2E 오프로딩 성능 근거로 단정해 옮기지 않았다. 또 초록의 `Terms`에는 `Des-POMDP`라고 적힌 반면 초록 본문과 2절에는 `Dec-POMDP`를 사용하므로, 이 글은 후자의 표기를 따른다.

## 한계와 향후 과제

- **문제 정식화:** 상태·관측·행동·보상과 큐 전이가 없어 제안된 Dec-POMDP를 같은 조건으로 재현할 수 없다.
- **실행 가능성:** 무선 대역폭, EN의 CPU·메모리, E2E 연결성과 작업 마감시간을 동시에 만족시키는 선택 규칙이 필요하다.
- **비동기 협력:** 계층별 결정의 순서, 동시 요청의 충돌, 중복 전달과 루프 방지, 중앙 critic에 필요한 정보의 수집 비용을 정의해야 한다.
- **평가:** D2E 단독 대비 추가 E2E 전송이 실제 순이득을 주는 부하·토폴로지 조건을 찾아야 한다. 결과가 없으므로 일반적인 성능 우위를 주장할 수 없다.

## 한국어 번역형 해설

아래는 원문 PDF의 전개를 따라가되 문장을 새로 구성한 해설이다.

**초록(p. 1).** 계산 집약적 응용을 지원할 때 MD의 작업을 EN에 넘기는 것만이 아니라 EN 사이에 다시 배분하는 경우도 생각한다. 저자는 이런 협력이 빠르게 변하는 MEC에서 실시간·분산 결정을 요구한다고 보고, 큐 기반 다계층 상황을 Dec-POMDP로 바라보겠다고 한다. 여러 에이전트의 DRL은 그 문제를 풀기 위한 제안된 수단이다.

**서론(pp. 1-2).** 기존 오프로딩 연구는 D2E 링크에서의 자원 배치와 지연·에너지 같은 문제를 주로 다뤘다는 것이 저자의 정리다. 이 제안은 EN 간 유휴 계산 능력을 공유하려면 E2E 링크도 선택지에 포함해야 한다고 주장한다. MD와 EN이 네트워크의 일부만 보고 각자 결정하므로, 다른 주체의 정책 변화까지 환경에 포함하는 단일 에이전트 접근만으로는 학습이 어려울 수 있다고 설명한다.

**문제와 접근(p. 2).** MD와 EN을 개별 의사결정자로 놓고 전체 성능을 목표로 하는 Dec-POMDP를 제시한다. 오프로딩 결정을 계층과 시점에 따라 나누어 현 상태와 자원 가용성에 맞추려 한다. 각 에이전트의 분산 actor와 중앙 critic을 쓰는 multi-agent DDPG가 해법 후보로 등장하지만, 관측 벡터와 학습식은 이 문서에 남아 있지 않다.

**실험·결론의 범위(pp. 2-3).** 본문은 두 가지 예상 기여를 열거한 뒤 참고문헌으로 끝난다. 별도 실험 절이나 결론 절, 측정값은 없으므로 “협력 구조가 성능을 높였다”는 식으로 결과를 번역할 근거가 없다. 현재 얻을 수 있는 결론은 협력 오프로딩을 연구할 문제 틀과 검증할 해법 방향이 제시되었다는 것까지다.

## 마지막 핵심 정리

- 이 자료는 **MD의 D2E + EN의 E2E**라는 협력 선택지를 연구 문제로 삼는다.
- **부분 관측 Dec-POMDP와 multi-agent DDPG는 설계 방향**이며, 큐·보상·학습·실행 제약은 미정이다.
- **실험 수치가 없으므로 성능 우위는 미검증**이다. 세미나의 설명 예시도 원문 실험으로 읽지 않아야 한다.

## 세미나 강의자료

아래 13장 강의자료는 제안의 논점을 설명하는 별도 학습 자료이며, 원문의 구현·실험 결과가 아니다.

| Material | Slides | PDF | PowerPoint | Slide Script | Presenter Notes |
| --- | ---: | --- | --- | --- | --- |
| Korean seminar | 13 | <a href="/assets/seminars/multi-agent-deep-reinforcement-learning-for-collaborative/collaborative-marl-mec-proposal-seminar-ko-v2.pdf" target="_blank" rel="noopener">Open PDF</a> | <a href="/assets/seminars/multi-agent-deep-reinforcement-learning-for-collaborative/collaborative-marl-mec-proposal-seminar-ko-v2.pptx" download>Download PPTX</a> | <a href="/assets/seminars/multi-agent-deep-reinforcement-learning-for-collaborative/slides-v2.md.txt" download="slides-v2.md">Download script</a> | <a href="/assets/seminars/multi-agent-deep-reinforcement-learning-for-collaborative/presenter-notes-v2.md.txt" download="presenter-notes-v2.md">Download notes</a> |

## 참고자료

- Iman Rahmati, *Multi-Agent Deep Reinforcement Learning for Collaborative Computation Offloading in Mobile Edge-Computing*, Research Proposal, pp. 1-3, 연도 미기재. [Source PDF](https://imanrht.github.io/assets/Multi_AgentDRL4MEC.pdf){:target="_blank" rel="noopener"}
- P. Hernandez-Leal et al., *A survey of learning in multiagent environments: Dealing with non-stationarity*, 2017. 원문 참고문헌 [11]; 다중 에이전트 비정상성의 배경.
- F. A. Oliehoek, C. Amato et al., *A concise introduction to decentralized POMDPs*, Springer, 2016. 원문 참고문헌 [16]; Dec-POMDP의 배경.
- R. Lowe et al., *Multi-agent actor-critic for mixed cooperative-competitive environments*, NeurIPS 30, 2017. 원문 참고문헌 [17]; multi-agent actor-critic 접근의 배경.
