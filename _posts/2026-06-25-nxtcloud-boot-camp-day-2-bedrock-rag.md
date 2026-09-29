---
layout: post
title: "nxtcloud Boot Camp Day 2: Amazon Bedrock RAG Workshop"
nav_title: "Day 2"
date: 2026-06-25 00:00:00 +0900
last_modified_at: 2026-09-29 20:14:56 +0900
categories: [BootCamp, AWS, Bedrock]
tags: [Amazon Bedrock, RAG, Knowledge Bases, Vector Search, RetrieveAndGenerate]
permalink: /posts/nxtcloud-boot-camp-day-2-bedrock-rag/
section: nxtcloud-boot-camp
---

> **핵심 메시지:** RAG는 질문과 관련된 문서 조각을 검색해 LLM의 답변 입력에 추가하는 방식이다. 검색 결과가 답변의 근거가 될 수 있지만, 관련 문서를 찾았다는 사실만으로 답변의 정확성까지 보장되지는 않는다.

## 1. 교육 과정 개요

nxtcloud Boot Camp 2일차의 주제는 Amazon Bedrock 기반 RAG(Retrieval-Augmented Generation)다. 1일차의 모델 호출 방식과 챗봇 API 선택에서 나아가, 모델이 모르는 사내 문서·매뉴얼·FAQ를 어떻게 답변 근거로 연결할지 다룬다.

2일차 과정은 데이터 준비와 임베딩, 벡터 검색, 검색 결과 기반 생성, API 선택으로 이어진다. Knowledge Base의 구성과 검색 API 설명은 Amazon Bedrock의 공식 Knowledge Bases·API 문서를 따른다.

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

문서 검색 없이 모델에 질문만 보내면, 모델은 학습 과정에서 얻은 일반 지식과 질문에 포함된 정보로 답변한다. 이 방식은 범용 질문에는 유용하지만, 최신 내부 문서, 기업별 정책, 강의 자료, 제품 매뉴얼처럼 모델에 제공되지 않은 정보에는 약하다. 또한 모델이 근거 문서를 확인하지 못하면 그럴듯하지만 부정확한 답변을 만들 가능성이 있다.

RAG(검색 증강 생성)는 질문과 관련된 외부 문서 조각을 검색하고, 그 내용을 질문과 함께 생성 모델에 전달하는 구조다. 문서 내용을 모델 가중치에 새로 학습시키는 방식과 다르다. Amazon Bedrock Knowledge Bases는 데이터 소스 연결, 문서 처리와 검색을 관리하며, 선택한 API에 따라 검색 결과만 받거나 검색 결과를 이용한 생성 답변까지 받을 수 있다.

## 4. Lab 01: 지식 기반과 전처리 흐름

RAG의 첫 단계는 답변 근거가 될 문서를 검색 가능한 형태로 바꾸는 것이다. 긴 문서를 작은 텍스트 단위인 chunk(청크)로 나누고, embedding model(임베딩 모델)이 각 청크를 숫자 배열인 vector(벡터)로 변환한다. vector store(벡터 저장소)는 벡터와 원본 문서의 연결 정보를 저장해 검색에 사용한다.

청크는 검색 단위다. 너무 크면 불필요한 내용이 함께 검색될 수 있고, 너무 작으면 문맥이 끊겨 답변에 필요한 정보가 빠질 수 있다. 임베딩은 텍스트의 의미적 유사도를 비교할 수 있게 만든 수치 표현이다. 질문도 임베딩 모델을 거쳐 벡터로 변환되며, 검색 단계에서 질문 벡터와 가까운 문서 청크를 찾는다. 벡터가 가깝다는 것은 관련성의 신호이지, 해당 문서의 사실성이나 답변의 정확성을 증명하지는 않는다.

문서 준비와 질문 처리는 시점이 다르다.

1. **문서 준비:** 원본 문서를 청크로 나누고, 각 청크의 임베딩과 원본 위치를 벡터 저장소에 기록한다.
2. **질문 검색:** 사용자의 질문을 임베딩한 뒤 관련성이 높은 청크를 검색한다.
3. **답변 생성:** 검색된 청크의 텍스트를 질문과 함께 생성 모델에 전달한다. 모델은 이 입력을 참고해 문장을 만든다.
4. **출처 확인:** 애플리케이션은 검색된 원본 위치와 답변 내용을 연결해 사용자가 근거를 확인할 수 있게 한다.

핵심 구성 요소는 다음과 같다.

| 구성 | 역할 | 주의점 |
|---|---|---|
| Data source | 원본 문서가 저장된 위치 | S3, 문서 저장소, 내부 자료 구조를 명확히 정리해야 한다. |
| Chunk | 검색 가능한 문서 조각 | 크기와 overlap이 검색 품질에 직접 영향을 준다. |
| Embedding model | 텍스트를 벡터로 변환 | 언어, 도메인, 비용, 성능을 함께 고려해야 한다. |
| Vector store | 벡터를 저장하고 유사도 검색 수행 | 검색 속도와 필터링 조건을 고려해야 한다. |
| Metadata | 문서 제목, 위치, 날짜 등 부가 정보 | 출처 표시와 필터 검색에 쓰인다. 접근 권한은 별도 정책으로 확인해야 한다. |

## 5. Lab 02: Knowledge Base 생성과 동기화

Knowledge Base는 데이터 소스와 vector store 사이의 연결을 관리한다. 데이터 소스가 연결되면 Bedrock은 문서를 읽고, chunking과 embedding을 거쳐 vector index를 구성한다. 이후 문서가 바뀌면 다시 동기화해야 최신 정보가 검색 결과에 반영된다.

AWS 공식 문서 기준에서 knowledge base를 vector store와 함께 만들 때의 일반 흐름은 데이터 소스 연결, embedding model 선택, vector store 선택, 데이터 동기화 순서로 진행된다. 이 흐름은 RAG 시스템이 단순히 “문서를 업로드하는 기능”이 아니라, 문서를 검색 가능한 의미 벡터 구조로 변환하는 pipeline이라는 점을 보여준다.

실습에서 확인해야 할 핵심은 다음과 같다.

- 원본 문서와 검색 index는 같은 것이 아니다.
- 문서를 추가하거나 수정하면 knowledge base를 다시 sync해야 한다.
- embedding model과 vector store 선택은 검색 품질과 비용에 영향을 준다.
- 운영 환경에서는 문서 접근 권한과 metadata 설계가 중요하다.

## 6. Lab 03: `Retrieve`와 `RetrieveAndGenerate`

벡터 저장소 기반 Knowledge Base를 질의할 때, `Retrieve`와 `RetrieveAndGenerate`는 반환하는 결과가 다르다. `Retrieve`는 Knowledge Base를 조회해 검색 결과를 반환한다. `RetrieveAndGenerate`는 검색된 내용을 바탕으로 지정한 foundation model이 생성한 답변을 반환한다.

`Retrieve`의 응답에는 검색된 내용과 원본 위치 등의 정보가 포함되며, 답변 문장을 만들려면 애플리케이션이 별도로 생성 단계를 연결해야 한다. 검색 결과를 직접 점검하거나 독자적인 생성 흐름을 구성할 때 적합하다. `RetrieveAndGenerate`는 검색과 생성을 하나의 호출로 연결하며, 응답의 `citations` 필드로 생성 문장과 관련 출처를 표시할 수 있다. 출처가 표시되더라도 답변 문장과 원문이 실제로 일치하는지 확인하는 일은 남는다.

| 방식 | 책임 범위 | 적합한 상황 |
|---|---|---|
| `Retrieve` | 검색된 문서 내용과 위치 반환 | 검색 결과를 직접 점검하고 생성 흐름을 별도로 구성할 때 |
| `RetrieveAndGenerate` | 검색 후 모델 답변 생성, 관련 출처 표시 가능 | 지원되는 Knowledge Base에서 검색과 생성을 한 호출로 연결할 때 |

API 선택은 Knowledge Base 유형과 필요한 제어 범위에 따라 달라진다. AWS API 문서에 따르면 `RetrieveAndGenerate`는 AWS가 별도 유형으로 부르는 *Managed Knowledge Base*에는 사용할 수 없으므로, 모든 Knowledge Base에 두 API를 그대로 대입할 수는 없다.

## 7. Lab 04: 챗봇에 RAG 연결하기

다음은 **작동 과정을 보여주기 위한 가상 FAQ**이며, 실제 부트캠프 데이터나 실행 결과가 아니다. 원본 FAQ 문서에 “수료를 완료한 뒤 교육 포털의 ‘내 학습’에서 수료증을 내려받을 수 있다”는 문장이 있다고 가정한다.

1. 문서 동기화 때 해당 문장이 포함된 청크를 벡터로 변환하고, 원본 FAQ 위치와 함께 검색 가능한 형태로 저장한다. 다른 청크에는 비밀번호 재설정 절차가 적혀 있다고 하자.
2. 사용자가 “수료증은 어디서 받나요?”라고 묻는다. 질문이 임베딩되고, 검색기가 두 청크 중 질문과 더 관련성이 높은 수료증 청크를 찾아 반환했다고 가정한다.
3. `Retrieve`만 호출했다면 애플리케이션은 청크 텍스트와 원본 위치를 받는다. 여기서 바로 완성된 답변이 생성되는 것은 아니다.
4. 검색된 청크를 생성 모델에 전달하거나 `RetrieveAndGenerate`를 사용하면, 모델은 “수료를 완료한 뒤 교육 포털의 ‘내 학습’에서 내려받을 수 있습니다”와 같은 답변을 만들 수 있다. 출처 정보가 반환되면 UI는 답변과 원본 FAQ 위치를 함께 표시할 수 있다.

검색기가 비밀번호 청크만 반환하거나 FAQ에 수료 조건이 없다면 위 답변을 확정해서는 안 된다. 먼저 검색 결과가 질문에 답하는지 확인하고, 근거가 부족하면 추가 검색이나 답변 보류가 필요하다.

## 8. Lab 05: RAG 품질 조정과 운영 관점

RAG 품질은 하나의 설정만으로 결정되지 않는다. 문서 준비, 검색, 생성, 출처 표시를 각각 점검해야 한다. 특히 **검색이 관련 청크를 놓치거나 오래된 문서를 찾으면, 생성 모델에 올바른 지침을 주어도 답변이 틀릴 수 있다.**

| 조정 항목 | 영향 | 점검 기준 |
|---|---|---|
| chunk size | 문맥 보존과 검색 정확도 | 답변에 필요한 문맥이 끊기지 않는가 |
| number of results | 검색 범위 | 관련 없는 문서가 너무 많이 섞이지 않는가 |
| metadata filter | 검색 제한 | 문서 유형, 날짜, 권한 조건을 반영할 수 있는가 |
| reranking | 검색 결과 순서 | 가장 관련 있는 chunk가 상위에 오는가 |
| prompt template | 생성 방식 | 모델이 검색 결과만 근거로 답하도록 유도하는가 |
| citation | 검증 가능성 | 답변 근거를 사용자가 확인할 수 있는가 |
| guardrail | 안전 정책 | 설정한 정책에 따른 개입 여부를 확인했는가. 사실 정확성 검증과는 구분되는가 |

운영 관점에서 RAG는 “한 번 만들면 끝나는 검색 기능”이 아니다. 문서가 갱신되면 재동기화해야 하고, 사용자 질문이 달라지면 청크와 검색 설정을 다시 평가해야 한다. 검색의 의미적 유사도와 `citations`는 사실 검증을 대신하지 않는다. 내부 문서 기반 시스템에서는 요청자의 문서 접근 권한, 로그 보관, 개인정보 포함 여부도 별도로 검토해야 한다.

## 9. 2일차 핵심 정리

2일차의 핵심은 Bedrock 챗봇을 단순 생성형 응답에서 문서 기반 응답으로 확장하는 것이다. 문서를 청크와 임베딩으로 검색 가능하게 만들고, 질문과 관련된 청크를 생성 입력에 추가한다. FAQ 예시처럼 답변은 검색된 문서에 연결할 수 있지만, 검색된 내용·답변·출처의 일치 여부는 별도로 확인해야 한다.

- RAG는 LLM의 일반 지식에 외부 문서 context를 결합하는 구조다.
- Knowledge Base는 문서 ingestion, embedding, indexing, retrieval을 관리한다.
- `Retrieve`는 검색 결과를 반환하고, 지원되는 Knowledge Base의 `RetrieveAndGenerate`는 검색 뒤 답변까지 생성한다.
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
