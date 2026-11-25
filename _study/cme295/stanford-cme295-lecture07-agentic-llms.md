---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CME295 Lecture 7: Agentic LLMs"
course: "CME295"
topic: "RAG, Tool Calling, MCP, and Agent Workflows"
order: 7
major_topic: "Large Language Models"
keywords:
  - "Agentic LLMs"
  - "Planning"
  - "Tool Use"
  - "Memory"
  - "Multi-Agent Systems"
---

# Stanford CME295 Lecture 7: Agentic LLMs

Source: [Stanford CME295 Autumn 2025 Lecture 7](https://www.youtube.com/watch?v=h-7S6HNq0Vg){:target="_blank" rel="noopener"}

**원본 영상 먼저 보기:** [00:28:25의 embedding retrieval 설명](https://www.youtube.com/watch?v=h-7S6HNq0Vg&t=1705s){:target="_blank" rel="noopener"}에서 query와 chunk embedding을 비교해 후보를 고르는 흐름을 먼저 듣습니다. 아래 RAG 절은 chunking→candidate retrieval→reranking→generation 순서와 cosine similarity가 쓰이는 위치를 연결합니다.

<figure>
  <a href="{{ '/assets/images/study/cme295/source-captures/lecture-07-retrieval-00h28m25s.jpg' | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ '/assets/images/study/cme295/source-captures/lecture-07-retrieval-00h28m25s.jpg' | relative_url }}" alt="query와 chunk를 embedding 기반 유사도로 비교하는 candidate retrieval 강의 슬라이드" loading="lazy">
  </a>
  <figcaption><a href="https://www.youtube.com/watch?v=h-7S6HNq0Vg&t=1705s" target="_blank" rel="noopener">공식 영상 00:28:25</a> — 지식 베이스에서 잠재적으로 관련된 후보를 고르는 첫 단계와 query·chunk 입력을 보여 줍니다.</figcaption>
</figure>

Query와 Chunk는 원문 문자열 그대로 비교되는 것이 아니라 각각 embedding 벡터로 바뀝니다. candidate retrieval은 이 벡터의 유사도로 넓게 후보를 모으는 단계이며, 정밀한 순위 조정은 다음 reranking 단계가 담당합니다.

> **핵심:** 학습이 끝난 LLM은 이후의 정보를 자동으로 알 수 없고, 긴 프롬프트에 모든 지식을 넣기도 어렵습니다. RAG는 필요한 문서를 검색해 답변에 연결하고, tool calling은 모델이 외부 기능을 사용하게 하며, 에이전트는 이 두 능력을 여러 단계의 작업으로 조직합니다.

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | reasoning model 복습 | GRPO와 reasoning chain은 vanilla LLM의 어떤 약점을 보완했습니까? |
| 2 | 지식 cutoff와 RAG 동기 | 왜 최신 정보를 모델 가중치나 긴 프롬프트에 직접 넣는 방식이 실용적이지 않습니까? |
| 3 | RAG 검색 파이프라인 | retrieve, augment, generate 중 검색 단계가 왜 전체 품질을 좌우합니까? |
| 4 | candidate retrieval | bi-encoder, Sentence-BERT, cosine similarity, BM25는 각각 어떤 검색 문제를 다룹니까? |
| 5 | reranking과 평가 | cross-encoder reranker와 NDCG, reciprocal rank, precision@k, recall@k는 어떤 기준으로 top-k 문서를 평가합니까? |
| 6 | tool calling | LLM은 함수 구현을 직접 보는 대신 어떤 API 정보로 도구와 인자를 선택합니까? |
| 7 | MCP와 에이전트 | MCP, ReAct, Agent2Agent는 도구와 다중 단계 행동을 어떻게 표준화하거나 확장합니까? |

</details>
## 핵심 내용

학습이 끝난 LLM의 가중치에는 이후의 정보가 자동으로 반영되지 않습니다. 가중치를 계속 갱신하면 회귀 위험과 유지보수 비용이 생기고, 모든 최신 정보를 긴 프롬프트에 넣으면 컨텍스트 길이와 토큰 비용, 긴 문맥에서의 정보 검색 성능이 문제가 됩니다. RAG는 질문에 필요한 문서만 찾아 프롬프트에 더한 뒤 답을 만드는 retrieve–augment–generate 절차로 이 문제를 다룹니다.

RAG는 모델이 모르는 내용을 영구히 외우게 하는 방법이 아니라, 답할 때 참고할 쪽지를 찾아 건네는 방법에 가깝습니다. 예를 들어 사내 규정을 묻는 질문이 오면 규정 문서 전체를 매번 넣지 않고 관련 조항 몇 개를 검색해 질문 옆에 붙입니다. 모델은 그 근거를 읽고 답하므로 문서가 바뀌면 검색 저장소를 갱신할 수 있고, 어떤 문장을 근거로 썼는지도 추적하기 쉬워집니다.

RAG의 핵심은 검색 품질입니다. 먼저 긴 문서를 검색하기 쉬운 작은 구간인 **chunk**로 나눕니다. Candidate retrieval은 질문과 관련 있어 보이는 chunk를 빠르게 넓게 모읍니다. 이 단계에서 빠진 문서는 뒤에서 되찾기 어렵습니다. Reranking은 모은 후보만 질문과 더 자세히 비교해 최종 순서를 정합니다. 즉 첫 단계는 `놓치지 않기`, 두 번째 단계는 `정확히 고르기`에 초점을 둡니다.

빠른 후보 검색에는 embedding cosine similarity, BM25 또는 두 방식을 섞은 검색을 사용할 수 있습니다. 더 비싼 cross-encoder는 질문과 후보 chunk를 함께 읽어 reranking 점수를 만듭니다. Precision@$$k$$는 상위 결과가 얼마나 정확한지, recall@$$k$$는 필요한 문서를 얼마나 놓치지 않았는지를 봅니다. NDCG와 reciprocal rank는 관련 문서가 위쪽에 놓였는지도 반영합니다. Chunk 크기와 겹침 정도는 문맥 보존, 저장량, 검색 정밀도 사이의 절충입니다.

후반부는 구조화된 데이터와 외부 행동을 다루는 tool calling으로 이동합니다. LLM은 함수의 API와 설명을 보고 적절한 도구와 인자를 예측하고, 실제 함수 실행 결과를 다시 받아 자연어 응답을 만듭니다. 이 능력은 SFT 예제나 프롬프트 설명 반복으로 유도할 수 있고, 도구가 많아지면 tool selector/router가 필요한 후보 도구만 고릅니다. MCP는 도구 노출 방식을 표준화하는 프로토콜로 소개되고, ReAct 계열 에이전트는 observe, plan, act 같은 반복 루프를 통해 목표를 하위 행동으로 나누며, Agent2Agent와 안전성 문제가 이어서 논의됩니다.

RAG와 tool calling의 경계는 **정보를 읽는가, 외부 상태에 행동하는가**로 잡을 수 있습니다. 문서를 검색해 답변 근거로 쓰는 것은 RAG이고, 캘린더 조회 함수를 호출하거나 파일을 저장하는 것은 tool calling입니다. Agent는 이 둘을 포함한 여러 단계를 계획하고 결과를 확인한 뒤 다음 행동을 정할 수 있습니다. 그래서 검색 한 번으로 답하는 RAG와, 관찰–행동을 반복하는 agent loop를 같은 개념으로 보지 않습니다.

**Supplementary table — 검색과 도구 실행의 단계별 실패 지점**

<div markdown="block" role="region" aria-label="Retrieval and tool execution failure comparison" tabindex="0" style="overflow-x: auto;">

| 단계 | 입력 → 출력 | 이 단계가 필요한 이유 | 대표 실패 |
|---|---|---|---|
| Candidate retrieval | Query → 넓은 후보 chunk 집합 | 낮은 비용으로 recall을 확보합니다. | 관련 문서가 후보에 들지 않으면 이후 단계가 복구하기 어렵습니다. |
| Reranking | Query + 후보 → 정렬된 소수 chunk | 더 비싼 상호작용 점수를 작은 집합에만 씁니다. | Relevant 후보를 낮게 배치하거나 중복 chunk가 context를 차지합니다. |
| Augment and generate | Query + 선택 chunk → 근거가 포함된 답 | 외부 정보를 generation context에 연결합니다. | 검색 근거를 무시하거나 근거보다 강한 주장을 만듭니다. |
| Tool prediction | Goal + tool schema → tool 이름과 arguments | 자연어 의도를 실행 가능한 호출로 바꿉니다. | 잘못된 tool·argument를 선택하거나 권한 경계를 넘습니다. |
| Execution and synthesis | Tool result → 상태 확인 또는 최종 답 | 실제 결과를 다음 판단에 반영합니다. | 실행 실패를 성공으로 오인하거나 오래된 결과로 답합니다. |
{: .reference-candidate-table style="min-width: 44rem;" }

</div>

표는 원본 강의에서 각각 설명한 RAG 흐름과 tool-calling 흐름의 역할·실패 지점을 나란히 비교한 작성자 보충입니다. 두 흐름이 반드시 직렬로 이어지는 것은 아니며, 검색 결과를 tool 호출의 근거로 쓰거나 agent loop에 RAG를 넣는 것은 시스템 설계 선택입니다. RAG의 generation은 한 번으로 끝날 수 있지만 agent는 결과를 관찰한 뒤 계획과 실행을 반복할 수 있습니다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| RAG | Retrieval-Augmented Generation. 관련 문서를 검색하고 프롬프트에 보강한 뒤 LLM이 답을 생성하는 방법입니다. |
| Knowledge base | RAG가 검색할 문서들의 저장소로, 문서를 chunk로 나누고 각 chunk에 대한 임베딩을 미리 계산해 둡니다. |
| Bi-encoder | query와 chunk를 각각 독립적으로 encoder에 통과시켜 임베딩을 만들고, cosine similarity 같은 점수로 빠르게 비교하는 구조입니다. |
| Sentence-BERT | BERT를 확장해 문장 또는 sequence 단위 임베딩을 만들고, 관련 쌍의 cosine similarity가 높아지도록 학습하는 예로 소개됩니다. |
| BM25 | query와 document의 단어 overlap에 기반한 heuristic relevance score로, 반드시 특정 키워드가 포함되어야 하는 검색에 유용합니다. |
| Cross-encoder reranker | query와 chunk를 함께 encoder에 넣어 두 입력 사이의 attention 상호작용을 반영한 relevance score를 계산하는 reranking 방식입니다. |
| NDCG | relevant document가 순위 상단에 있을수록 높은 점수를 주고, 이상적인 DCG로 normalize해 query별 점수를 비교 가능하게 만듭니다. |
| Tool calling | LLM이 사용 가능한 함수 API를 보고 호출할 도구와 인자를 선택한 뒤, 실행 결과를 받아 최종 답변을 생성하는 방식입니다. |
| MCP | Model Context Protocol. MCP server, tools, prompts, resources, MCP client 같은 vocabulary로 도구 노출 방식을 표준화합니다. |
| ReAct | Reason plus act. 복잡한 목표를 observe, plan, act 또는 think, observe, act 같은 반복 가능한 하위 단계로 분해하는 에이전트 프레임워크입니다. |

## 수식 해설: retrieval score와 ranking metric

Retrieval은 query와 document의 lexical 또는 embedding similarity로 후보를 고르고, ranking metric은 relevant item이 상위에 얼마나 잘 놓였는지 측정합니다. Cosine, BM25, Precision/Recall@$$k$$, NDCG는 서로 다른 질문에 답하므로 한 지표를 relevance 전체의 증명으로 해석하면 안 됩니다.

<details markdown="block">
<summary markdown="span">Derivation: Similarity, BM25, and ranking metrics</summary>

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Cosine similarity retrieval | 00:28:25–00:33:24 | Embedding 비교와 top-candidate retrieval은 강의 원문이며, 범위·zero-vector 조건은 작성자 보충입니다. |
| BM25 | 00:34:44–00:37:23 | Lexical heuristic이라는 성격과 hybrid retrieval은 강의 원문이며, parameter 의존성은 작성자 보충입니다. |
| DCG/NDCG | 00:49:41–00:52:19 | Rank discount와 ideal-DCG normalization은 강의 원문이며, 정확한 convention과 zero denominator 처리는 작성자 보충입니다. |
| Reciprocal rank, Precision@k, Recall@k | 00:54:12–00:56:44 | Metric 의미는 강의 원문이며, 분모가 0인 query 처리 조건은 작성자 보충입니다. |

Embedding $$q,d\in\mathbb{R}^{m}$$의 cosine similarity는

$$
\operatorname{cos}(q,d)=\frac{q^\top d}{\|q\|_2\|d\|_2}
$$

로 정의합니다. 두 vector가 0이 아니어야 합니다. Cauchy-Schwarz inequality $$\lvert q^\top d\rvert\le\|q\|_2\|d\|_2$$의 양변을 양수인 $$\|q\|_2\|d\|_2$$로 나누면 $$-1\le\operatorname{cos}(q,d)\le1$$이므로 값은 $$[-1,1]$$에 놓입니다. 이 한 줄 유도는 강의가 제시한 cosine similarity를 보완한 작성자 설명입니다. L2-normalized embedding에서는 $$\|q\|=\|d\|=1$$이라 dot product와 같습니다. 높은 cosine이 실제 relevance를 보장한다는 것은 embedding training과 domain에 의존하는 경험적 가정입니다.

Top-$$k$$ retrieval의 exact-count metric은

$$
\operatorname{Precision@k}=\frac{\#\text{ relevant in top }k}{k},
\qquad
\operatorname{Recall@k}=\frac{\#\text{ relevant in top }k}{\#\text{ all relevant}}.
$$

Relevant 문서가 하나도 없는 query에서는 recall 분모가 0이므로 dataset policy를 정해야 합니다. 첫 relevant rank가 $$r$$이면 reciprocal rank는 $$1/r$$이고, 없으면 보통 0으로 둡니다.

Graded relevance $$rel_i$$를 쓰는 한 convention은

$$
DCG@k=\sum_{i=1}^{k}\frac{2^{rel_i}-1}{\log_2(i+1)},
\qquad
NDCG@k=\frac{DCG@k}{IDCG@k}.
$$

IDCG는 같은 label을 이상적으로 정렬한 DCG입니다. $$IDCG=0$$이면 NDCG가 정의되지 않아 구현별 처리 규칙이 필요합니다. Discount와 gain 선택은 convention이며, NDCG가 downstream answer correctness를 증명하지는 않습니다.

BM25는 강의가 00:34:44–00:37:23에서 lexical heuristic으로 소개했지만 완전한 식은 제시하지 않았습니다. 한 가지 널리 쓰는 **작성자 보충 convention**은

$$
\operatorname{BM25}(D,Q)
=\sum_{t\in Q}\operatorname{IDF}(t)
\frac{f(t,D)(k_1+1)}
{f(t,D)+k_1\left(1-b+b\frac{|D|}{\operatorname{avgdl}}\right)},
$$

$$
\operatorname{IDF}(t)
=\log\!\left(1+\frac{N-n_t+0.5}{n_t+0.5}\right).
$$

$$f(t,D)$$는 document term frequency, $$\lvert D\rvert$$와 $$\operatorname{avgdl}>0$$은 document 길이와 corpus 평균 길이, $$N$$은 문서 수, $$n_t$$는 term $$t$$를 포함한 문서 수입니다. $$k_1>0$$은 term-frequency 증가를 포화시키고, $$0\le b\le1$$은 길이 정규화 강도를 조절합니다. 위 IDF는 rare term에 더 큰 nonnegative weight를 주는 convention이며, 구현에 따라 log의 $$+1$$, query-term factor, duplicate query term 처리가 다릅니다. 높은 BM25가 semantic relevance의 theorem인 것은 아니며 tokenizer와 corpus statistics에 따라 순위가 바뀝니다.

</details>

## 학습 포인트

- RAG는 관련 정보를 검색해 프롬프트에 추가한 뒤 답을 생성하는 방식이며, 핵심은 관련 정보만 넣는 것입니다.
- 문서 chunk는 보통 수백 토큰 규모이고, embedding size, chunk size, overlap은 저장 공간, 계산량, 문맥 보존 사이의 trade-off를 만듭니다.
- candidate retrieval은 recall 중심의 빠른 필터링이고, reranking은 더 작은 후보 집합에 더 비싼 cross-encoder 점수를 적용합니다.
- semantic search는 의미 유사도를 찾지만 정확한 키워드 포함을 보장하지 않으므로 BM25나 하이브리드 검색이 유용할 수 있습니다.
- RAG 검색 평가는 NDCG, reciprocal rank, precision@k, recall@k처럼 순위와 정답 relevance label을 함께 보는 지표를 사용합니다.
- tool calling은 LLM이 도구 이름과 인자를 예측하고, 실행된 도구의 structured output을 바탕으로 최종 자연어 답변을 만드는 절차입니다.
- 도구가 많아지면 tool selector/router가 context window와 needle-in-a-haystack 문제를 줄이기 위해 관련 도구만 고릅니다.
- 에이전트는 도구 호출을 여러 번 반복하며 목표 달성 여부를 점검하는 시스템이고, 안전성 문제는 학습 단계와 inference safeguard 모두에서 다뤄야 합니다.

## 마지막 핵심 정리

이 강의의 핵심은 `RAG, 도구 호출, MCP, 에이전트 워크플로`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것입니다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

1. RAG의 세 단계 retrieve, augment, generate를 각각 한 문장으로 설명하고, 실패가 가장 자주 발생하는 지점을 검색 단계와 연결해 정리합니다.
2. candidate retrieval과 reranking을 속도, 입력 형태, 모델 구조, 평가 지표 관점에서 표로 비교합니다.
3. cosine similarity 기반 semantic search와 BM25 기반 keyword search가 서로 다른 실패 사례를 만드는 예를 하나씩 만듭니다.
4. tool calling의 두 LLM 단계인 tool prediction과 final response synthesis를 SFT 데이터 형식으로 써 봅니다.
5. MCP, ReAct, Agent2Agent가 각각 tool 노출, 단일 에이전트 루프, 다중 에이전트 통신 중 어디에 해당하는지 구분합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. RAG가 모델 재학습보다 선호되는 이유는 무엇입니까?</summary>

답변: 가중치에 새 지식을 주입하면 회귀와 유지보수 문제가 생기고, 모든 downstream use case에 같은 업데이트를 반복해야 합니다. RAG는 필요한 외부 지식만 검색해 프롬프트에 넣으므로 더 실용적입니다.

</details>

<details markdown="block">
<summary>2. bi-encoder retrieval과 cross-encoder reranking의 차이는 무엇입니까?</summary>

답변: bi-encoder는 query와 chunk를 따로 인코딩해 빠르게 임베딩 유사도를 비교합니다. cross-encoder는 query와 chunk를 함께 넣어 attention 상호작용을 사용하므로 더 비싸지만 더 정밀한 relevance score를 낼 수 있습니다.

</details>

<details markdown="block">
<summary>3. NDCG가 단순 precision보다 ranking 평가에 더 맞는 이유는 무엇입니까?</summary>

답변: NDCG는 relevant document가 몇 개 있는지만 보지 않고, 그 문서들이 top-k 안에서 얼마나 앞쪽에 배치되었는지도 반영합니다.

</details>

<details markdown="block">
<summary>4. tool calling에서 LLM이 함수 구현 전체를 볼 필요가 없는 이유는 무엇입니까?</summary>

답변: LLM의 역할은 도구 API, 인자, 설명을 보고 적절한 호출을 생성하는 것입니다. 실제 구현은 코드베이스나 backend가 실행하고, LLM은 실행 결과를 다시 받아 답변을 합성합니다.

</details>

<details markdown="block">
<summary>5. ReAct식 에이전트가 단순 tool call과 다른 점은 무엇입니까?</summary>

답변: 단순 tool call은 보통 한 번의 도구 선택과 결과 합성에 가깝지만, ReAct식 에이전트는 관찰, 계획, 행동을 반복하며 목표가 달성되었는지 확인하고 필요하면 추가 도구를 호출합니다.

</details>

## 참고자료

- 자료 확인 범위: 공식 Stanford CME295 강의 영상과 영문 전사를 대조했습니다. 공식 슬라이드는 없어 화면에 보이지 않는 내용은 추정하지 않았습니다.

- [강의 영상](https://www.youtube.com/watch?v=h-7S6HNq0Vg){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
