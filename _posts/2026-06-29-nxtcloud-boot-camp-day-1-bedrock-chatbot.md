---
layout: post
title: "nxtcloud Boot Camp 1일차: Amazon Bedrock Chatbot Workshop"
nav_title: "1일차"
date: 2026-06-29 00:00:00 +0900
categories: [BootCamp, AWS, Bedrock]
tags: [Amazon Bedrock, Chatbot, Converse, Streaming, API]
permalink: /posts/nxtcloud-boot-camp-day-1-bedrock-chatbot/
section: nxtcloud-boot-camp
---

## 1. 교육 과정 개요

nxtcloud Boot Camp 1일차는 Amazon Bedrock을 사용해 챗봇 호출 방식을 단계적으로 비교하는 실습 과정이다. 전체 흐름은 단일 턴 모델 호출에서 시작해, 멀티턴 대화, 스트리밍 응답, Converse API, API 선택 기준까지 이어진다.

이 과정의 핵심은 “모델을 한 번 호출하는 코드”를 넘어서, 실제 챗봇 서비스를 만들 때 어떤 호출 방식을 선택해야 하는지 판단하는 데 있다. 같은 Claude 모델을 호출하더라도 `invoke_model`, `invoke_model_with_response_stream`, `converse`, `converse_stream`은 요청 형식, 응답 파싱 방식, 스트리밍 처리, 모델 교체 가능성에서 서로 다른 개발 경험을 만든다.

이 글은 NxtCloud Workshop의 Bedrock Chatbot 과정 링크를 기준으로 1일차 흐름을 정리하고, Amazon Bedrock 공식 API 문서를 함께 대조해 API 의미를 보강한 자료다. `00-overview`와 `lab-01`은 원본 링크를 참고자료로 보존하되, 핵심 내용은 Bedrock 챗봇 실습의 입문 단계인 과정 개요와 `invoke_model` 단일 턴 호출 구조를 중심으로 정리한다.

## 2. 전체 학습 흐름

| 순서 | 원본 Lab | 핵심 질문 | 학습 결과 |
|---|---|---|---|
| 0 | Overview | Amazon Bedrock 챗봇 실습은 어떤 순서로 진행되는가? | 단일 호출에서 고수준 API 비교까지 이어지는 전체 구조를 파악한다. |
| 1 | Lab 01 | 한 번 묻고 한 번 답하는 챗봇은 어떻게 호출되는가? | `invoke_model`의 기본 요청 body와 응답 파싱 구조를 이해한다. |
| 2 | Lab 02 | 모델은 이전 대화를 기억하는가? | 모델은 stateless이며, 멀티턴을 위해 매 호출마다 전체 `messages`를 다시 보내야 함을 이해한다. |
| 3 | Lab 03 | 응답을 한 번에 받지 않고 실시간으로 보여주려면? | `invoke_model_with_response_stream`의 이벤트 스트림과 `content_block_delta` 파싱을 이해한다. |
| 4 | Lab 04 | 모델별 요청 형식 차이를 줄일 수 있는가? | `converse`와 `converse_stream`으로 표준 메시지, 시스템 프롬프트, 파라미터를 통합한다. |
| 5 | Lab 05 | 어떤 API를 언제 선택해야 하는가? | 저수준 API와 고수준 API의 책임 범위, 편의성, 제어 가능성을 비교한다. |

## 3. Lab 01: `invoke_model` 단일 턴 호출

첫 단계는 `invoke_model`을 사용해 사용자의 질문 하나를 모델에 보내고, 완성된 응답 하나를 받는 구조다. 이 방식은 Bedrock Runtime에 직접 요청 body를 넘기고, 돌아온 JSON 응답에서 텍스트를 직접 꺼내는 저수준 호출 방식이다.

단일 턴 호출의 장점은 구조가 단순하다는 점이다. 사용자가 입력한 질문을 `messages` 배열에 담고, `max_tokens`, `anthropic_version` 같은 모델별 필드를 포함한 뒤 `modelId`와 함께 호출하면 된다. 그러나 이 방식은 모델별 요청 body를 개발자가 직접 책임져야 한다. Anthropic Claude 계열은 `anthropic_version`과 `messages` 형식을 사용하지만, 다른 모델군은 다른 입력 구조를 요구할 수 있다.

AWS 공식 API 기준에서 `InvokeModel`은 지정한 Bedrock 모델에 prompt와 inference parameter를 담은 request body를 보내 추론을 실행하는 기능이다. 요청의 핵심 축은 어떤 모델을 호출할지 나타내는 `modelId`, 입력 형식을 나타내는 `contentType`, 모델별 입력을 담는 `body`다. 따라서 Lab 01에서 확인해야 할 부분은 “질문 문자열을 어디에 넣는가”뿐 아니라, 모델별 JSON schema를 정확히 맞추고 응답 body에서 실제 생성 텍스트를 꺼내는 파싱 경로까지 포함된다.

이 Lab에서 잡아야 할 핵심은 다음과 같다.

- `invoke_model`은 모델별 요청 형식을 직접 구성하는 저수준 API다.
- 응답은 완성된 뒤 한 번에 도착한다.
- 응답 JSON 내부의 텍스트 경로를 개발자가 직접 파싱해야 한다.
- 단일 턴 호출은 이전 대화를 기억하지 않는다.

## 4. Lab 02: 멀티턴 대화와 상태 관리

Lab 02의 핵심 문장은 “모델은 기억이 없다”로 정리할 수 있다. LLM 호출은 이전 호출의 상태를 내부에 저장하는 대화 객체가 아니라, 입력을 받아 출력을 생성하는 stateless 함수에 가깝다. 따라서 사용자가 “내 이름은 넥클이야”라고 말한 뒤 “내 이름 뭐야?”라고 물어도, 두 번째 호출에 첫 번째 대화가 함께 전달되지 않으면 모델은 맥락을 알 수 없다.

멀티턴 챗봇은 애플리케이션 쪽에서 `history`를 관리하고, 매 호출마다 지금까지의 사용자 발화와 모델 응답을 모두 `messages`로 다시 보내는 방식으로 구현된다. 이 방식은 맥락을 유지할 수 있지만, 대화가 길어질수록 입력 토큰이 누적되고 비용이 증가한다. 또한 오래된 대화를 어느 시점에 자를지, 요약할지, 보안상 어떤 메시지를 신뢰할지 같은 추가 설계 문제가 생긴다.

이 Lab은 단순히 “채팅이 이어진다”는 기능보다, 멀티턴 대화의 책임이 모델 내부가 아니라 애플리케이션의 히스토리 관리에 있다는 점을 이해하는 것이 중요하다.

## 5. Lab 03: 스트리밍 응답 처리

Lab 03은 사용자가 긴 답변을 기다릴 때 느끼는 체감 지연을 줄이기 위해 스트리밍 호출을 다룬다. 일반 `invoke_model`은 답변이 전부 생성된 뒤 한 번에 응답하지만, `invoke_model_with_response_stream`은 응답을 여러 이벤트 조각으로 나누어 순차적으로 보낸다.

스트리밍의 핵심은 전체 생성 시간을 반드시 줄이는 것이 아니라, 첫 글자가 화면에 나타나는 시간을 줄여 사용자가 시스템이 동작 중임을 빠르게 느끼게 하는 데 있다. 이를 위해 응답 이벤트의 `chunk.bytes`를 JSON으로 파싱하고, 여러 이벤트 타입 중 실제 텍스트 조각이 들어 있는 `content_block_delta`의 `delta.text`만 골라 출력한다.

이 과정에서 Python 제너레이터의 역할도 함께 등장한다. 함수가 텍스트 조각을 모두 모아 반환하면 스트리밍 효과가 사라진다. 따라서 `yield`로 조각을 하나씩 내보내야 UI가 모델 생성 속도에 맞춰 글자를 즉시 표시할 수 있다.

## 6. Lab 04: Converse API와 고수준 통합

Lab 04는 앞선 저수준 호출에서 드러난 불편함을 `converse`와 `converse_stream`으로 정리한다. 저수준 API에서는 모델별 body 형식, 시스템 프롬프트 삽입 방식, 추론 파라미터 이름, 스트리밍 이벤트 파싱을 개발자가 직접 관리해야 한다. Converse API는 이 차이를 표준 메시지 형식으로 통합한다.

Converse의 메시지 구조는 `content`를 단순 문자열이 아니라 `[{"text": "..."}]` 형태의 블록 리스트로 다룬다. 이 구조는 텍스트뿐 아니라 이미지나 도구 호출 결과 같은 확장 가능성을 고려한 표준 형식이다. 또한 `system` 인자로 페르소나를 분리하고, `inferenceConfig`에 `maxTokens`, `temperature` 같은 추론 파라미터를 모아 전달한다.

가장 중요한 실습 포인트는 모델 교체다. 저수준 `invoke_model`에서는 Claude에서 Amazon Nova로 모델군이 바뀌면 요청 body 구조와 응답 파싱을 다시 맞춰야 한다. 반면 Converse는 `modelId`만 바꿔도 같은 메시지 구조와 파싱 경로를 유지할 수 있다. 이 점이 고수준 API의 실질적인 장점이다.

## 7. Lab 05: 세 API 비교와 선택 기준

마지막 Lab은 새 기능을 추가하기보다, 앞에서 만든 세 가지 호출 방식을 비교한다. 비교 대상은 `invoke_model`, `invoke_model_with_response_stream`, `Converse` 또는 `converse_stream`이다.

| 상황 | 권장 방식 | 이유 |
|---|---|---|
| 새 챗봇 프로젝트의 기본 구현 | `Converse` | 메시지 형식과 추론 파라미터가 표준화되어 모델 교체 비용이 낮다. |
| ChatGPT처럼 실시간으로 글자가 나오는 UI | `converse_stream` | 고수준 표준 형식을 유지하면서 스트리밍 UX를 구현할 수 있다. |
| 특정 모델의 비표준 파라미터나 raw 응답 제어가 필요할 때 | `invoke_model` | 모델별 body를 직접 구성하므로 세밀한 제어가 가능하다. |
| 저수준 호출을 유지하면서 실시간 출력이 필요할 때 | `invoke_model_with_response_stream` | raw 스트림 이벤트를 직접 처리할 수 있다. |

정리하면 기본값은 Converse로 두는 편이 합리적이다. 다만 Converse가 아직 지원하지 않는 모델 기능, 모델 고유 파라미터, raw 이벤트 메타데이터가 필요할 때는 의도적으로 저수준 API로 내려갈 수 있다. 즉 API 선택은 “무엇이 더 좋은가”가 아니라 “어느 수준의 추상화가 현재 요구사항에 맞는가”의 문제다.

## 8. 1일차 핵심 정리

이번 1일차 과정은 Bedrock 챗봇을 구현하는 데 필요한 API 호출 계층을 순서대로 경험하는 흐름이었다. 단일 턴에서는 `invoke_model`의 기본 구조를 익히고, 멀티턴에서는 모델이 상태를 저장하지 않는다는 점을 확인했다. 스트리밍 단계에서는 이벤트 조각을 파싱해 체감 지연을 줄이는 방법을 배웠고, Converse 단계에서는 모델별 차이를 표준 인터페이스로 감추는 고수준 API의 장점을 확인했다.

가장 중요한 결론은 다음과 같다.

- LLM은 호출 간 대화 상태를 자동으로 기억하지 않는다.
- 멀티턴은 애플리케이션이 `messages`를 누적해 다시 보내는 방식으로 구현된다.
- 스트리밍은 총 생성 시간보다 첫 응답 표시 시간을 줄이는 UX 개선 기법이다.
- 저수준 API는 자유도가 높지만 요청 형식과 응답 파싱을 직접 책임져야 한다.
- 새 프로젝트에서는 Converse를 기본값으로 선택하고, 명확한 필요가 있을 때만 저수준 API로 내려가는 것이 실무적으로 합리적이다.

## 9. 참고자료

<ul>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/00-overview" target="_blank" rel="noopener">NxtCloud Workshop: Amazon Bedrock 챗봇 핸즈온 과정 개요</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/lab-01" target="_blank" rel="noopener">Lab 01: invoke_model 단일 턴</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/lab-02" target="_blank" rel="noopener">Lab 02: 멀티턴 대화</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/lab-03" target="_blank" rel="noopener">Lab 03: 스트리밍</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/lab-04" target="_blank" rel="noopener">Lab 04: Converse 고수준 통합</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/bedrock-chatbot/lab-05" target="_blank" rel="noopener">Lab 05: 세 API 비교</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html" target="_blank" rel="noopener">AWS API Reference: InvokeModel</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModelWithResponseStream.html" target="_blank" rel="noopener">AWS API Reference: InvokeModelWithResponseStream</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_Converse.html" target="_blank" rel="noopener">AWS API Reference: Converse</a></li>
  <li><a href="https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ConverseStream.html" target="_blank" rel="noopener">AWS API Reference: ConverseStream</a></li>
</ul>
