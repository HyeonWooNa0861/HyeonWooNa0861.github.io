---
layout: post
title: "nxtcloud Boot Camp 2일차: Amazon Bedrock RAG Workshop"
nav_title: "2일차"
date: 2026-06-29 00:00:01 +0900
categories: [BootCamp, AWS, Bedrock]
tags: [Amazon Bedrock, RAG, Knowledge Bases, Vector Search, RetrieveAndGenerate]
permalink: /posts/nxtcloud-boot-camp-day-2-bedrock-rag/
section: nxtcloud-boot-camp
---

## 1. 교육 과정 개요

nxtcloud Boot Camp 2일차는 Amazon Bedrock 기반 RAG(Retrieval-Augmented Generation) 구조를 이해하고, 지식 기반을 사용해 모델 응답을 외부 문서와 연결하는 과정을 정리한 자료다. 1일차가 모델 호출 방식과 챗봇 API 선택에 초점을 두었다면, 2일차는 “모델이 모르는 사내 문서, 매뉴얼, FAQ를 어떻게 답변 근거로 사용할 수 있는가”를 다룬다.

이 글은 NxtCloud Workshop의 Bedrock RAG 과정 링크를 기준으로 2일차 흐름을 구성하고, Amazon Bedrock 공식 Knowledge Bases 문서와 API 문서를 함께 대조해 개념을 보강한 정리본이다. 원본 링크는 참고자료로 보존하되, 본문은 RAG를 구성하는 데이터 준비, 임베딩, 벡터 검색, 검색 결과 기반 생성, API 선택 기준을 중심으로 재구성한다.

## 2. 전체 학습 흐름

| 순서 | 원본 Lab | 핵심 질문 | 학습 결과 |
|---|---|---|---|
| 0 | Overview | RAG는 왜 필요한가? | 일반 LLM 호출과 문서 기반 응답의 차이를 이해한다. |
| 1 | Lab 01 | 지식 기반은 어떤 데이터 흐름으로 만들어지는가? | 문서 수집, chunking, embedding, vector store의 역할을 구분한다. |
| 2 | Lab 02 | Knowledge Base는 어떻게 검색 가능한 상태가 되는가? | 데이터 소스 연결, 동기화, 인덱싱 과정을 이해한다. |
| 3 | Lab 03 | 검색 결과만 가져오는 것과 답변까지 생성하는 것은 어떻게 다른가? | `Retrieve`와 `RetrieveAndGenerate`의 책임 차이를 구분한다. |
| 4 | Lab 04 | 챗봇에 RAG를 연결할 때 무엇을 관리해야 하는가? | 사용자 질문, 검색 결과, 생성 모델, 출처 표시 흐름을 연결한다. |
| 5 | Lab 05 | RAG 품질은 어떤 기준으로 조정하는가? | 검색 개수, chunk 전략, reranking, citation, guardrail 관점을 정리한다. |

## 3. Overview: RAG가 필요한 이유

일반적인 LLM 호출은 모델이 학습 과정에서 얻은 일반 지식을 바탕으로 답변한다. 이 방식은 범용 질문에는 유용하지만, 최신 내부 문서, 기업별 정책, 강의 자료, 제품 매뉴얼처럼 모델 학습 데이터에 포함되지 않은 정보에는 약하다. 또한 모델이 근거 문서를 확인하지 못하면 그럴듯하지만 부정확한 답변을 만들 가능성이 있다.

RAG는 이 한계를 줄이기 위해 사용자 질문과 관련 있는 외부 문서 조각을 먼저 검색하고, 그 검색 결과를 프롬프트의 context로 넣어 모델이 답변하도록 만드는 구조다. Amazon Bedrock Knowledge Bases는 이 과정을 관리형 기능으로 제공해, 데이터 소스 연결, embedding 생성, vector store 저장, 검색, 출처 기반 생성까지 이어지는 RAG 파이프라인을 단순화한다.

## 4. Lab 01: 지식 기반과 전처리 흐름

RAG의 첫 단계는 모델에 바로 질문을 던지는 것이 아니라, 답변 근거가 될 문서를 검색 가능한 형태로 바꾸는 것이다. 문서는 보통 긴 텍스트이므로 그대로 모델에 넣기 어렵다. 따라서 문서를 적절한 크기의 chunk로 나누고, 각 chunk를 embedding model을 통해 숫자 벡터로 변환한 뒤 vector store에 저장한다.

이때 chunk는 검색 단위가 된다. chunk가 너무 크면 불필요한 내용이 함께 검색될 수 있고, 너무 작으면 문맥이 끊겨 답변에 필요한 정보가 빠질 수 있다. embedding은 텍스트의 의미를 수치화한 표현이며, 사용자 질문도 같은 embedding 공간으로 변환되어 문서 chunk와 의미적으로 비교된다.

핵심 구성 요소는 다음과 같다.

| 구성 | 역할 | 주의점 |
|---|---|---|
| Data source | 원본 문서가 저장된 위치 | S3, 문서 저장소, 내부 자료 구조를 명확히 정리해야 한다. |
| Chunk | 검색 가능한 문서 조각 | 크기와 overlap이 검색 품질에 직접 영향을 준다. |
| Embedding model | 텍스트를 벡터로 변환 | 언어, 도메인, 비용, 성능을 함께 고려해야 한다. |
| Vector store | 벡터를 저장하고 유사도 검색 수행 | 검색 속도와 필터링 조건을 고려해야 한다. |
| Metadata | 문서 제목, 위치, 권한, 날짜 등 부가 정보 | 출처 표시와 필터 검색에 필요하다. |

## 5. Lab 02: Knowledge Base 생성과 동기화

Knowledge Base는 데이터 소스와 vector store 사이의 연결을 관리한다. 데이터 소스가 연결되면 Bedrock은 문서를 읽고, chunking과 embedding을 거쳐 vector index를 구성한다. 이후 문서가 바뀌면 다시 동기화해야 최신 정보가 검색 결과에 반영된다.

AWS 공식 문서 기준에서 knowledge base를 vector store와 함께 만들 때의 일반 흐름은 데이터 소스 연결, embedding model 선택, vector store 선택, 데이터 동기화 순서로 진행된다. 이 흐름은 RAG 시스템이 단순히 “문서를 업로드하는 기능”이 아니라, 문서를 검색 가능한 의미 벡터 구조로 변환하는 pipeline이라는 점을 보여준다.

실습에서 확인해야 할 핵심은 다음과 같다.

- 원본 문서와 검색 index는 같은 것이 아니다.
- 문서를 추가하거나 수정하면 knowledge base를 다시 sync해야 한다.
- embedding model과 vector store 선택은 검색 품질과 비용에 영향을 준다.
- 운영 환경에서는 문서 접근 권한과 metadata 설계가 중요하다.

## 6. Lab 03: `Retrieve`와 `RetrieveAndGenerate`

Bedrock RAG에서 runtime 단계는 크게 두 방식으로 나눌 수 있다. 첫 번째는 `Retrieve`처럼 knowledge base에서 관련 문서 조각만 검색하는 방식이고, 두 번째는 `RetrieveAndGenerate`처럼 검색 결과를 바탕으로 foundation model이 최종 답변까지 생성하는 방식이다.

`Retrieve`는 검색 결과를 애플리케이션이 직접 받아 처리하고 싶을 때 유용하다. 예를 들어 검색된 문서 조각을 UI에 따로 보여주거나, 별도의 prompt template에 넣거나, 여러 검색 결과를 다시 정렬하는 구조를 만들 수 있다. 반면 `RetrieveAndGenerate`는 검색과 생성을 하나의 API 흐름으로 묶어, knowledge base query와 모델 응답 생성을 함께 처리한다.

| 방식 | 책임 범위 | 적합한 상황 |
|---|---|---|
| `Retrieve` | 관련 문서 조각 검색 | 검색 결과를 직접 제어하거나 UI에 노출해야 할 때 |
| `RetrieveAndGenerate` | 검색 결과 기반 답변 생성 | 빠르게 문서 기반 Q&A를 구성해야 할 때 |

실무적으로는 처음에는 `RetrieveAndGenerate`로 빠르게 RAG 흐름을 확인하고, 이후 검색 결과 제어, reranking, prompt 구성, citation 표시 요구가 커지면 `Retrieve` 기반으로 세밀하게 분리하는 방식이 적절하다.

## 7. Lab 04: 챗봇에 RAG 연결하기

RAG 챗봇은 단순 챗봇보다 관리해야 할 정보가 많다. 사용자의 질문을 받아 모델에 바로 보내는 것이 아니라, 먼저 knowledge base에 검색을 요청하고, 검색된 문서 조각을 근거로 모델이 답변하도록 구성해야 한다. 이때 답변에는 가능하면 citation이나 source 정보를 함께 제공해야 한다.

RAG 챗봇의 기본 흐름은 다음과 같다.

1. 사용자가 질문을 입력한다.
2. 질문을 embedding 또는 query 형태로 변환해 knowledge base에 전달한다.
3. knowledge base가 의미적으로 관련 있는 문서 chunk를 검색한다.
4. 검색 결과가 prompt context로 들어간다.
5. foundation model이 context를 근거로 답변을 생성한다.
6. UI는 답변과 출처를 함께 보여준다.

이 구조에서 중요한 점은 모델이 “알고 있는 것처럼 말하는 답변”보다 “어떤 문서에 근거했는지 확인 가능한 답변”을 만드는 것이다. 따라서 RAG 챗봇은 생성 품질뿐 아니라 검색 품질과 출처 표시 품질도 함께 평가해야 한다.

## 8. Lab 05: RAG 품질 조정과 운영 관점

RAG 품질은 하나의 설정만으로 결정되지 않는다. 검색 품질, chunk 전략, embedding model, vector store, 검색 결과 개수, reranking, prompt template, guardrail, citation 표시가 모두 영향을 준다.

| 조정 항목 | 영향 | 점검 기준 |
|---|---|---|
| chunk size | 문맥 보존과 검색 정확도 | 답변에 필요한 문맥이 끊기지 않는가 |
| number of results | 검색 범위 | 관련 없는 문서가 너무 많이 섞이지 않는가 |
| metadata filter | 검색 제한 | 문서 유형, 날짜, 권한 조건을 반영할 수 있는가 |
| reranking | 검색 결과 순서 | 가장 관련 있는 chunk가 상위에 오는가 |
| prompt template | 생성 방식 | 모델이 검색 결과만 근거로 답하도록 유도하는가 |
| citation | 검증 가능성 | 답변 근거를 사용자가 확인할 수 있는가 |
| guardrail | 안전성 | 부적절한 입력이나 출력이 제어되는가 |

운영 관점에서 RAG는 “한 번 만들면 끝나는 검색 기능”이 아니다. 문서가 갱신되면 재동기화가 필요하고, 사용자 질문 패턴이 달라지면 chunk와 검색 설정을 다시 조정해야 한다. 또한 내부 문서 기반 시스템이라면 문서 권한, 로그 보관, 개인정보 포함 여부도 함께 검토해야 한다.

## 9. 2일차 핵심 정리

2일차의 핵심은 Bedrock 챗봇을 단순 생성형 응답에서 문서 기반 응답으로 확장하는 것이다. RAG는 모델을 다시 학습시키지 않고도 외부 문서를 답변 근거로 사용할 수 있게 해 준다. 이를 위해 문서를 chunk로 나누고 embedding으로 변환해 vector store에 저장한 뒤, 사용자 질문과 의미적으로 가까운 문서를 검색해 모델 응답에 반영한다.

가장 중요한 결론은 다음과 같다.

- RAG는 LLM의 일반 지식에 외부 문서 context를 결합하는 구조다.
- Knowledge Base는 문서 ingestion, embedding, indexing, retrieval을 관리한다.
- `Retrieve`는 검색 결과를 직접 제어할 때 유리하고, `RetrieveAndGenerate`는 검색과 생성을 빠르게 연결할 때 유리하다.
- RAG의 품질은 모델 성능만이 아니라 chunking, metadata, 검색 설정, reranking, citation 설계에 의해 결정된다.
- 운영 환경에서는 문서 갱신, 접근 권한, 출처 표시, guardrail을 함께 고려해야 한다.

## 10. 참고자료

<ul>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/00-overview" target="_blank" rel="noopener">NxtCloud Workshop: Amazon Bedrock RAG 과정 개요</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/lab-01" target="_blank" rel="noopener">Lab 01: Bedrock RAG</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/lab-02" target="_blank" rel="noopener">Lab 02: Bedrock RAG</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/lab-03" target="_blank" rel="noopener">Lab 03: Bedrock RAG</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/lab-04" target="_blank" rel="noopener">Lab 04: Bedrock RAG</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-rag/lab-05" target="_blank" rel="noopener">Lab 05: Bedrock RAG</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html" target="_blank" rel="noopener">AWS User Guide: Amazon Bedrock Knowledge Bases</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/userguide/kb-how-it-works.html" target="_blank" rel="noopener">AWS User Guide: How Amazon Bedrock Knowledge Bases work</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-build.html" target="_blank" rel="noopener">AWS User Guide: Build a knowledge base with vector stores</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Retrieve.html" target="_blank" rel="noopener">AWS API Reference: Retrieve</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrieveAndGenerate.html" target="_blank" rel="noopener">AWS API Reference: RetrieveAndGenerate</a></li>
</ul>
