---
layout: post
title: "nxtcloud Boot Camp Day 4: AI Workflow Automation"
nav_title: "Day 4"
date: 2026-06-27 00:00:00 +0900
categories: [BootCamp, AIWorkflow, Automation]
tags: [AI Workflow, Automation, Prompting, Project Workflow, Team Project]
permalink: /posts/nxtcloud-boot-camp-day-4-ai-workflow/
section: nxtcloud-boot-camp
---

> **핵심 메시지:** AI Workflow는 단발성 프롬프트가 아니라 목표, 자료, 도구, 구현, 검증과 산출물을 연결하고 반복 작업을 안전하게 자동화하는 프로젝트 운영 구조다.

## 1. 교육 과정 개요

nxtcloud Boot Camp 4일차는 AI Workflow를 프로젝트 수행 과정에 적용하는 흐름을 정리한 자료다. 1일차와 2일차가 Amazon Bedrock 기반 모델 호출과 RAG 구조를 다루고, 3일차가 Claude Code를 활용한 개발 workflow를 다루었다면, 4일차는 AI를 활용해 팀 프로젝트의 기획, 구현, 자동화 과정을 어떻게 연결할 것인지에 초점을 둔다.

이 글은 NxtCloud Workshop의 `ai-workflow` 과정 URL을 참고자료로 보존하고, 현재 직접 접근 가능한 원문이 제한된 상태에서 4일차 학습 흐름을 블로그용으로 재구성한 정리본이다. 추가 탐색 범위는 `00-overview`, `lab-01`, `lab-02`, `lab-03`, `lab-04`, `appendix-automation`이며, 본문은 AI Workflow의 전체 구조, 프로젝트 작업 흐름, 자동화 설계 기준을 중심으로 작성했다.

## 2. 전체 학습 흐름

| 순서 | 원본 항목 | 핵심 질문 | 학습 결과 |
|---|---|---|---|
| 0 | Overview | AI Workflow는 일반적인 AI 도구 사용과 무엇이 다른가? | 단일 프롬프트가 아니라 목표, 자료, 도구, 검증, 산출물을 연결하는 작업 흐름으로 이해한다. |
| 1 | Lab 01 | 프로젝트 목표를 어떻게 AI가 처리 가능한 작업으로 바꿀 것인가? | 문제 정의, 대상 사용자, 최종 산출물을 먼저 고정한다. |
| 2 | Lab 02 | 필요한 자료와 도구를 어떻게 정리할 것인가? | API, 문서, 코드베이스, 참고자료를 workflow의 입력으로 정리한다. |
| 3 | Lab 03 | 산출물과 검증 기준을 어떻게 연결할 것인가? | 구현 결과, 문서, 발표 자료가 같은 목표를 향하는지 점검한다. |
| 4 | Lab 04 | 팀 프로젝트에서 AI를 어디에 배치해야 하는가? | 기획, 자료 조사, 구현 보조, 코드 검토, 문서화, 발표 준비 단계별 AI 활용 지점을 구분한다. |
| 5 | Appendix Automation | 반복 작업을 어떻게 자동화할 수 있는가? | 반복 입력, 파일 생성, 검증, 배포 전 점검을 자동화 후보로 분류한다. |

## 3. AI Workflow의 의미

AI Workflow는 AI에게 단발성 질문을 던지는 방식이 아니다. 하나의 작업 목표를 정하고, 필요한 자료를 모으고, AI가 처리할 수 있는 단위로 나눈 뒤, 결과를 사람이 검토하고 다시 다음 단계로 넘기는 전체 과정을 의미한다.

예를 들어 팀 프로젝트에서 “주식 위험 분석 대시보드를 만든다”는 목표가 있다면, AI는 단순히 코드 한 조각을 작성하는 역할에 머물지 않는다. 프로젝트 아이디어 정리, 화면 구성안 작성, API 후보 비교, 데이터 흐름 설계, 코드 초안 생성, 버그 원인 분석, README 작성, 발표 문구 정리까지 여러 단계에 개입할 수 있다.

중요한 점은 AI가 모든 결정을 대신하는 것이 아니라, 사람이 목표와 기준을 정하고 AI가 반복적이고 구조화 가능한 작업을 빠르게 수행하도록 배치하는 것이다.

## 4. Lab 01-03 관점: workflow 준비 단계

`lab-01`부터 `lab-03`까지는 AI Workflow를 실제 프로젝트 작업으로 옮기기 전의 준비 단계로 볼 수 있다. 원문 페이지는 현재 직접 확인되지 않지만, 제공된 URL 구조와 4일차 전체 맥락을 기준으로 보면 초반 Lab의 핵심은 목표 정의, 자료 정리, 산출물 기준 설정에 있다.

첫 번째 단계는 문제를 명확히 쓰는 것이다. “AI를 활용해 무언가를 만든다”는 표현은 너무 넓다. 대신 어떤 사용자의 어떤 문제를 해결할지, 최종 결과물이 웹앱인지 문서인지 발표 자료인지, 성공 기준이 무엇인지를 먼저 고정해야 한다.

두 번째 단계는 입력 자료를 정리하는 것이다. AI에게 좋은 결과를 얻으려면 관련 URL, API 문서, 코드 파일, 데이터 예시, 기존 프로젝트 설명이 분리되어 있어야 한다. 자료가 섞여 있으면 AI는 작업 범위를 잘못 판단하거나 존재하지 않는 기능을 만들어낼 가능성이 높다.

세 번째 단계는 산출물과 검증 기준을 연결하는 것이다. 웹 프로젝트라면 배포 URL, GitHub source, 핵심 기능, 사용 기술, 제한 사항이 서로 맞아야 한다. 문서나 발표 자료라면 실제 구현 내용과 설명이 일치해야 한다. 이 기준이 있어야 AI가 만든 결과를 사람이 검토할 수 있다.

## 5. 프로젝트 작업 흐름에 AI 배치하기

AI Workflow를 프로젝트에 적용할 때는 작업을 단계별로 나누어야 한다. 모든 단계에서 같은 방식의 프롬프트를 쓰면 결과 품질이 흔들리기 쉽다. 기획 단계에서는 문제 정의와 사용자 시나리오가 중요하고, 구현 단계에서는 코드 구조와 테스트 기준이 중요하며, 발표 단계에서는 전달력과 근거 자료가 중요하다.

| 단계 | AI 활용 방식 | 사람이 확인할 기준 |
|---|---|---|
| 문제 정의 | 프로젝트 목표, 대상 사용자, 해결할 문제를 문장으로 정리한다. | 실제 프로젝트 범위와 맞는지 확인한다. |
| 자료 조사 | API, 기술 스택, 유사 서비스, 위험 요소를 비교한다. | 출처가 명확하고 최신 정보인지 확인한다. |
| 설계 | 데이터 흐름, 화면 구성, 기능 우선순위를 정리한다. | 구현 가능성과 일정에 맞는지 확인한다. |
| 구현 | 코드 초안, 컴포넌트 구조, 오류 원인 분석을 보조한다. | 실행 결과와 테스트 결과가 맞는지 확인한다. |
| 문서화 | README, 발표 자료, 기능 설명을 작성한다. | 실제 구현 내용과 문서가 일치하는지 확인한다. |
| 검증 | 체크리스트, 테스트 항목, 배포 전 점검표를 만든다. | 누락된 기능이나 위험한 가정이 없는지 확인한다. |

## 6. Lab 04 관점: 팀 프로젝트에서의 AI 사용

Lab 04는 URL 구조상 AI Workflow 과정 중 실습형 단계로 보인다. 4일차 프로젝트 흐름과 연결하면, 핵심은 AI를 팀 작업의 어느 위치에 넣을 것인지 결정하는 것이다.

팀 프로젝트에서는 작업자가 여러 명이기 때문에 AI 사용 방식도 표준화되어야 한다. 한 사람은 UI 초안을 만들고, 다른 사람은 API 연동을 만들고, 또 다른 사람은 발표 자료를 작성할 수 있다. 이때 각자 AI에게 다른 기준으로 요청하면 결과물의 톤, 구조, 기술 용어가 어긋날 수 있다. 따라서 팀 차원의 공통 규칙이 필요하다.

권장 기준은 다음과 같다.

- 프로젝트 목표와 사용자 정의를 먼저 고정한다.
- 기술 스택과 API 사용 기준을 문서화한다.
- AI에게 맡길 작업과 사람이 직접 결정할 작업을 분리한다.
- 코드 생성 후에는 실행, 테스트, 리뷰를 반드시 거친다.
- 발표 자료와 README는 실제 구현 결과와 대조한다.
- AI가 만든 문장이나 코드도 팀의 최종 산출물 기준에 맞게 수정한다.

## 7. Appendix Automation 관점: 자동화 후보 찾기

자동화는 AI Workflow의 핵심 확장 지점이다. 반복되는 작업을 자동화하면 팀은 더 많은 시간을 문제 정의, 품질 검토, 결과 해석에 사용할 수 있다. 다만 자동화는 모든 작업에 적용하는 것이 아니라 반복성과 검증 가능성이 높은 작업부터 적용하는 것이 적절하다.

자동화 후보는 다음과 같이 나눌 수 있다.

| 자동화 대상 | 예시 | 주의점 |
|---|---|---|
| 자료 정리 | 링크 목록 정리, API 문서 요약, 기능 목록 생성 | 원문 접근 실패나 오래된 정보가 섞이지 않게 확인한다. |
| 코드 보조 | 반복 컴포넌트 생성, 타입 정의, 간단한 변환 로직 작성 | 실제 실행과 테스트를 반드시 거친다. |
| 문서 생성 | README, 사용법, 발표 스크립트 초안 작성 | 구현 내용과 다르면 즉시 수정한다. |
| 검증 | 체크리스트 생성, 테스트 케이스 후보 작성 | 자동 생성된 검증 항목만 믿지 않는다. |
| 배포 전 점검 | 링크, 환경 변수, 빌드 명령, 배포 URL 확인 | secret이나 private token이 노출되지 않게 한다. |

자동화는 생산성을 높이지만, 자동화된 결과가 항상 맞다는 뜻은 아니다. 특히 외부 API, 금융 데이터, AI 판단처럼 오류 가능성이 있는 영역에서는 자동화된 결과를 사람이 해석하고 검증하는 절차가 필요하다.

## 8. 5일차 작업물과의 연결

4일차 AI Workflow는 5일차 `AWS Charting` 프로젝트와 직접 연결된다. `AWS Charting`은 뉴스 수집, 주가 데이터 조회, AI 분석, 대시보드 시각화, 배포가 결합된 결과물이다. 이 구조는 4일차에서 다룬 workflow 관점을 실제 산출물로 확장한 사례로 볼 수 있다.

특히 다음 연결점이 중요하다.

- AI Workflow의 문제 정의는 “미국 주식 위험을 초보자도 이해할 수 있게 정리한다”는 프로젝트 목표로 이어진다.
- 자료 조사와 기술 비교는 FRED, Twelve Data, Alpha Vantage, Google News RSS, Groq AI 선택으로 이어진다.
- 자동화 관점은 1분 자동 새로고침, 뉴스 수집, AI 분류, fallback 분석 구조로 이어진다.
- 문서화 관점은 GitHub HTML 소개 페이지와 배포 링크 제공으로 이어진다.

따라서 4일차는 프로젝트를 만들기 전 workflow를 설계하는 단계이고, 5일차는 그 workflow가 실제 대시보드로 구현된 단계라고 정리할 수 있다.

## 9. 4일차 핵심 정리

4일차의 핵심은 AI를 단순한 답변 도구가 아니라 프로젝트 workflow의 일부로 배치하는 것이다. 좋은 AI 활용은 프롬프트를 잘 쓰는 것에서 끝나지 않고, 목표 정의, 자료 정리, 구현, 자동화, 검증, 문서화가 이어지는 구조를 만든다.

핵심 결론은 다음과 같다.

- AI Workflow는 목표, 자료, 도구, 검증, 산출물을 연결하는 작업 흐름이다.
- Lab 01-03은 목표 정의, 자료 정리, 산출물 검증 기준을 세우는 준비 단계로 해석할 수 있다.
- 팀 프로젝트에서는 AI 사용 기준을 문서화해야 결과물의 일관성이 유지된다.
- 자동화는 반복성과 검증 가능성이 높은 작업부터 적용해야 한다.
- AI가 생성한 결과는 코드, 데이터, 문서 모두 사람이 검토해야 한다.
- 4일차 workflow 설계는 5일차 `AWS Charting` 프로젝트 구현과 직접 연결된다.

## 10. 참고자료

<ul>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/00-overview" target="_blank" rel="noopener">NxtCloud Workshop: AI Workflow Overview</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/lab-01" target="_blank" rel="noopener">NxtCloud Workshop: AI Workflow Lab 01</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/lab-02" target="_blank" rel="noopener">NxtCloud Workshop: AI Workflow Lab 02</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/lab-03" target="_blank" rel="noopener">NxtCloud Workshop: AI Workflow Lab 03</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/lab-04" target="_blank" rel="noopener">NxtCloud Workshop: AI Workflow Lab 04</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/ai-workflow/appendix-automation" target="_blank" rel="noopener">NxtCloud Workshop: Appendix Automation</a></li>
  <li><a href="https://sigebert111-boot-charting.vercel.app/" target="_blank" rel="noopener">5일차 작업물: AWS Charting 배포 페이지</a></li>
  <li><a href="https://github.com/nxtcloud-edu/2026-kookmin-ai-workflow-team5/blob/main/team5.html" target="_blank" rel="noopener">5일차 작업물 Source: team5.html</a></li>
</ul>
