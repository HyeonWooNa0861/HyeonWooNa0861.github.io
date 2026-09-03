---
layout: default
date: 2026-08-12 10:07:20 +0900
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

> **핵심:** 이 강의는 이전 강의의 reasoning model과 GRPO를 짧게 복습한 뒤, LLM이 학습 시점의 지식에 갇혀 있다는 문제에서 출발한다. 모델 가중치를 계속 재학습하는 방식은 회귀 위험과 유지보수 비용이 크고, 모든 최신 정보를 긴 프롬프트에 넣는 방식은 컨텍스트 길이, needle-in-a-haystack 성능 저하, 토큰 비용 때문에 부적절하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | reasoning model 복습 | GRPO와 reasoning chain은 vanilla LLM의 어떤 약점을 보완했는가? |
| 2 | 지식 cutoff와 RAG 동기 | 왜 최신 정보를 모델 가중치나 긴 프롬프트에 직접 넣는 방식이 실용적이지 않은가? |
| 3 | RAG 검색 파이프라인 | retrieve, augment, generate 중 검색 단계가 왜 전체 품질을 좌우하는가? |
| 4 | candidate retrieval | bi-encoder, Sentence-BERT, cosine similarity, BM25는 각각 어떤 검색 문제를 다루는가? |
| 5 | reranking과 평가 | cross-encoder reranker와 NDCG, reciprocal rank, precision@k, recall@k는 어떤 기준으로 top-k 문서를 평가하는가? |
| 6 | tool calling | LLM은 함수 구현을 직접 보는 대신 어떤 API 정보로 도구와 인자를 선택하는가? |
| 7 | MCP와 에이전트 | MCP, ReAct, Agent2Agent는 도구와 다중 단계 행동을 어떻게 표준화하거나 확장하는가? |

## 핵심 내용

이 강의는 이전 강의의 reasoning model과 GRPO를 짧게 복습한 뒤, LLM이 학습 시점의 지식에 갇혀 있다는 문제에서 출발한다. 모델 가중치를 계속 재학습하는 방식은 회귀 위험과 유지보수 비용이 크고, 모든 최신 정보를 긴 프롬프트에 넣는 방식은 컨텍스트 길이, needle-in-a-haystack 성능 저하, 토큰 비용 때문에 부적절하다. 그래서 RAG는 질문에 필요한 관련 문서만 검색해 프롬프트를 보강하고 답을 생성하는 retrieve, augment, generate 절차로 제시된다.

RAG의 핵심은 검색 품질이다. 문서를 토큰 수 기준의 chunk로 나누고 임베딩을 만든 뒤, candidate retrieval에서는 bi-encoder와 cosine similarity, approximate nearest neighbor, BM25 또는 하이브리드 검색으로 후보를 줄인다. 이어 reranking에서는 query와 chunk를 함께 넣는 cross-encoder로 더 정밀한 relevance score를 만들며, NDCG, reciprocal rank, precision@k, recall@k, MTEB 같은 기준으로 retriever를 평가한다. 강의는 chunk size, overlap, embedding size, context를 붙이는 방법, prompt caching 같은 실무적 선택도 다룬다.

후반부는 구조화된 데이터와 외부 행동을 다루는 tool calling으로 이동한다. LLM은 함수의 API와 설명을 보고 적절한 도구와 인자를 예측하고, 실제 함수 실행 결과를 다시 받아 자연어 응답을 만든다. 이 능력은 SFT 예제나 프롬프트 설명 반복으로 유도할 수 있고, 도구가 많아지면 tool selector/router가 필요한 후보 도구만 고른다. MCP는 도구 노출 방식을 표준화하는 프로토콜로 소개되고, ReAct 계열 에이전트는 observe, plan, act 같은 반복 루프를 통해 목표를 하위 행동으로 나누며, Agent2Agent와 안전성 문제가 이어서 논의된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| RAG | Retrieval-Augmented Generation. 관련 문서를 검색하고 프롬프트에 보강한 뒤 LLM이 답을 생성하는 방법이다. |
| Knowledge base | RAG가 검색할 문서들의 저장소로, 문서를 chunk로 나누고 각 chunk에 대한 임베딩을 미리 계산해 둔다. |
| Bi-encoder | query와 chunk를 각각 독립적으로 encoder에 통과시켜 임베딩을 만들고, cosine similarity 같은 점수로 빠르게 비교하는 구조다. |
| Sentence-BERT | BERT를 확장해 문장 또는 sequence 단위 임베딩을 만들고, 관련 쌍의 cosine similarity가 높아지도록 학습하는 예로 소개된다. |
| BM25 | query와 document의 단어 overlap에 기반한 heuristic relevance score로, 반드시 특정 키워드가 포함되어야 하는 검색에 유용하다. |
| Cross-encoder reranker | query와 chunk를 함께 encoder에 넣어 두 입력 사이의 attention 상호작용을 반영한 relevance score를 계산하는 reranking 방식이다. |
| NDCG | relevant document가 순위 상단에 있을수록 높은 점수를 주고, 이상적인 DCG로 normalize해 query별 점수를 비교 가능하게 만든다. |
| Tool calling | LLM이 사용 가능한 함수 API를 보고 호출할 도구와 인자를 선택한 뒤, 실행 결과를 받아 최종 답변을 생성하는 방식이다. |
| MCP | Model Context Protocol. MCP server, tools, prompts, resources, MCP client 같은 vocabulary로 도구 노출 방식을 표준화한다. |
| ReAct | Reason plus act. 복잡한 목표를 observe, plan, act 또는 think, observe, act 같은 반복 가능한 하위 단계로 분해하는 에이전트 프레임워크다. |

## 학습 포인트

- RAG는 관련 정보를 검색해 프롬프트에 추가한 뒤 답을 생성하는 방식이며, 핵심은 관련 정보만 넣는 것이다.
- 문서 chunk는 보통 수백 토큰 규모이고, embedding size, chunk size, overlap은 저장 공간, 계산량, 문맥 보존 사이의 trade-off를 만든다.
- candidate retrieval은 recall 중심의 빠른 필터링이고, reranking은 더 작은 후보 집합에 더 비싼 cross-encoder 점수를 적용한다.
- semantic search는 의미 유사도를 찾지만 정확한 키워드 포함을 보장하지 않으므로 BM25나 하이브리드 검색이 유용할 수 있다.
- RAG 검색 평가는 NDCG, reciprocal rank, precision@k, recall@k처럼 순위와 정답 relevance label을 함께 보는 지표를 사용한다.
- tool calling은 LLM이 도구 이름과 인자를 예측하고, 실행된 도구의 structured output을 바탕으로 최종 자연어 답변을 만드는 절차다.
- 도구가 많아지면 tool selector/router가 context window와 needle-in-a-haystack 문제를 줄이기 위해 관련 도구만 고른다.
- 에이전트는 도구 호출을 여러 번 반복하며 목표 달성 여부를 점검하는 시스템이고, 안전성 문제는 학습 단계와 inference safeguard 모두에서 다뤄야 한다.

## 마지막 핵심 정리

이 강의의 핵심은 `RAG, 도구 호출, MCP, 에이전트 워크플로`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. RAG의 세 단계 retrieve, augment, generate를 각각 한 문장으로 설명하고, 실패가 가장 자주 발생하는 지점을 검색 단계와 연결해 정리한다.
2. candidate retrieval과 reranking을 속도, 입력 형태, 모델 구조, 평가 지표 관점에서 표로 비교한다.
3. cosine similarity 기반 semantic search와 BM25 기반 keyword search가 서로 다른 실패 사례를 만드는 예를 하나씩 만든다.
4. tool calling의 두 LLM 단계인 tool prediction과 final response synthesis를 SFT 데이터 형식으로 써 본다.
5. MCP, ReAct, Agent2Agent가 각각 tool 노출, 단일 에이전트 루프, 다중 에이전트 통신 중 어디에 해당하는지 구분한다.

## 복습 질문

<details>
<summary>1. RAG가 모델 재학습보다 선호되는 이유는 무엇인가?</summary>

답변: 가중치에 새 지식을 주입하면 회귀와 유지보수 문제가 생기고, 모든 downstream use case에 같은 업데이트를 반복해야 한다. RAG는 필요한 외부 지식만 검색해 프롬프트에 넣으므로 더 실용적이다.

</details>

<details>
<summary>2. bi-encoder retrieval과 cross-encoder reranking의 차이는 무엇인가?</summary>

답변: bi-encoder는 query와 chunk를 따로 인코딩해 빠르게 임베딩 유사도를 비교한다. cross-encoder는 query와 chunk를 함께 넣어 attention 상호작용을 사용하므로 더 비싸지만 더 정밀한 relevance score를 낼 수 있다.

</details>

<details>
<summary>3. NDCG가 단순 precision보다 ranking 평가에 더 맞는 이유는 무엇인가?</summary>

답변: NDCG는 relevant document가 몇 개 있는지만 보지 않고, 그 문서들이 top-k 안에서 얼마나 앞쪽에 배치되었는지도 반영한다.

</details>

<details>
<summary>4. tool calling에서 LLM이 함수 구현 전체를 볼 필요가 없는 이유는 무엇인가?</summary>

답변: LLM의 역할은 도구 API, 인자, 설명을 보고 적절한 호출을 생성하는 것이다. 실제 구현은 코드베이스나 backend가 실행하고, LLM은 실행 결과를 다시 받아 답변을 합성한다.

</details>

<details>
<summary>5. ReAct식 에이전트가 단순 tool call과 다른 점은 무엇인가?</summary>

답변: 단순 tool call은 보통 한 번의 도구 선택과 결과 합성에 가깝지만, ReAct식 에이전트는 관찰, 계획, 행동을 반복하며 목표가 달성되었는지 확인하고 필요하면 추가 도구를 호출한다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=h-7S6HNq0Vg){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
