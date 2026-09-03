---
layout: post
title: "nxtcloud Boot Camp Day 3: Claude Code Workshop"
nav_title: "Day 3"
date: 2026-06-26 00:00:00 +0900
categories: [BootCamp, ClaudeCode, AIEngineering]
tags: [Claude Code, AI Coding Agent, CLI, MCP, Hooks, Permissions]
permalink: /posts/nxtcloud-boot-camp-day-3-claude-code/
section: nxtcloud-boot-camp
---

> **핵심 메시지:** Claude Code는 codebase를 읽고 수정·실행·검증하는 coding agent이며, 효과적인 활용에는 명확한 목표와 프로젝트 컨텍스트, 권한 경계, 테스트 기준이 함께 필요하다.

## 1. 교육 과정 개요

nxtcloud Boot Camp 3일차는 Claude Code를 개발 작업에 적용하는 흐름을 정리한 자료다. 1일차와 2일차가 Amazon Bedrock 기반 모델 호출과 RAG 구조를 다루었다면, 3일차는 AI coding agent를 실제 개발 환경에서 어떻게 사용하고 통제할 것인지에 초점을 둔다.

이 글은 NxtCloud Workshop의 Claude Code 과정 URL을 참고자료로 보존하고, 공개적으로 확인 가능한 Anthropic Claude Code 공식 문서를 중심으로 3일차 학습 흐름을 재구성한 정리본이다. 원본 workshop 페이지는 현재 직접 본문 확인이 제한되어, 본문은 Claude Code의 agentic loop, 설치와 첫 세션, 프로젝트 컨텍스트, 권한 모드, MCP와 hooks, 실무 workflow를 중심으로 정리한다.

## 2. 전체 학습 흐름

| 순서 | 원본 Lab | 핵심 질문 | 학습 결과 |
|---|---|---|---|
| 0 | Overview | Claude Code는 일반 코드 자동완성과 무엇이 다른가? | codebase를 읽고, 파일을 수정하고, 명령을 실행하는 agentic coding tool의 역할을 이해한다. |
| 1 | Lab 01 | Claude Code를 어떻게 설치하고 첫 세션을 시작하는가? | CLI 실행, 로그인, 프로젝트 디렉터리에서의 기본 대화 흐름을 익힌다. |
| 2 | Lab 02 | Claude Code는 프로젝트 정보를 어떻게 읽고 기억하는가? | `CLAUDE.md`, session, context window, auto memory의 역할을 구분한다. |
| 3 | Lab 03 | 안전하게 파일 수정과 명령 실행을 맡기려면? | permission mode, plan mode, checkpoint, 검증 절차를 이해한다. |
| 4 | Lab 04 | 반복 작업을 어떻게 workflow로 만들 수 있는가? | test 작성, lint 수정, commit, PR 준비 같은 common workflow를 정리한다. |
| 5 | Lab 05 | 외부 도구와 연결하려면 무엇이 필요한가? | MCP, skills, hooks를 통한 확장 구조를 이해한다. |
| 6 | Lab 06 | 팀 단위로 Claude Code를 쓸 때 무엇을 표준화해야 하는가? | 작업 지시, 권한, 검증, 보안, 협업 규칙을 운영 기준으로 정리한다. |

## 3. Overview: Claude Code의 역할

Claude Code는 단순히 코드 일부를 추천하는 자동완성 도구가 아니라, 터미널과 개발 도구 안에서 프로젝트를 읽고 작업을 수행하는 agentic coding tool이다. 공식 문서 기준으로 Claude Code는 codebase를 읽고, 파일을 편집하고, 명령을 실행하며, 개발 도구와 통합된다. 따라서 사용자는 “이 함수 완성해 줘”보다 더 큰 단위인 “버그를 조사하고 수정한 뒤 테스트까지 실행해 줘”와 같은 작업을 위임할 수 있다.

이 차이는 학습 관점에서 중요하다. Claude Code를 잘 쓰려면 프롬프트만 잘 쓰는 것이 아니라, 코드베이스 구조, 테스트 명령, Git 상태, 권한 범위, 검증 기준을 함께 제공해야 한다. 결국 AI coding agent 활용 능력은 “코드를 대신 작성시키는 기술”이 아니라 “작업을 정의하고, 맥락을 제공하고, 결과를 검토하는 개발 운영 능력”에 가깝다.

## 4. Lab 01: 설치와 첫 세션

Claude Code의 기본 사용 흐름은 프로젝트 디렉터리에서 CLI를 실행하고, 자연어로 작업을 요청하는 방식이다. 공식 quickstart는 터미널을 열고 프로젝트로 이동한 뒤 `claude` 명령으로 세션을 시작하는 흐름을 안내한다. 첫 사용 시에는 계정 로그인과 인증 과정이 필요하다.

첫 세션에서 중요한 것은 곧바로 큰 수정 작업을 맡기는 것이 아니라, Claude Code가 현재 프로젝트를 어떻게 이해하는지 확인하는 것이다. 예를 들어 “이 프로젝트의 구조를 설명해 줘”, “테스트 실행 방법을 찾아 줘”, “README와 package 설정을 읽고 개발 흐름을 요약해 줘”처럼 탐색형 요청으로 시작하면 이후 수정 작업의 실패 가능성을 줄일 수 있다.

실습에서 확인해야 할 핵심은 다음과 같다.

- Claude Code는 현재 디렉터리와 그 하위 파일을 중심으로 project context를 구성한다.
- terminal command, git 상태, build/test script가 중요한 작업 단서가 된다.
- 첫 요청은 구현보다 탐색과 요약이 적합하다.
- 설치 방식은 OS와 환경에 따라 다르므로 공식 설치 문서를 우선 확인해야 한다.

## 5. Lab 02: 프로젝트 컨텍스트와 기억

Claude Code가 프로젝트를 잘 다루려면 반복적으로 필요한 규칙을 명시해야 한다. 이때 핵심 파일이 `CLAUDE.md`다. `CLAUDE.md`에는 프로젝트의 coding convention, architecture decision, test command, review checklist, 금지해야 할 작업 등을 기록할 수 있다. 매번 같은 설명을 프롬프트에 반복하기보다 프로젝트 루트에 지속 지시사항을 두는 방식이다.

세션과 memory도 구분해야 한다. Claude Code의 session은 대화와 도구 사용 이력을 담는 작업 단위이고, context window는 현재 모델이 참고할 수 있는 정보 범위다. 대화가 길어지면 context가 압축될 수 있으므로, 반드시 보존되어야 하는 규칙은 대화 중 설명보다 `CLAUDE.md` 같은 지속 문서에 남기는 편이 안정적이다.

| 항목 | 역할 | 운영 기준 |
|---|---|---|
| `CLAUDE.md` | 프로젝트별 지속 지시사항 | test command, style rule, architecture note를 기록한다. |
| Session | 하나의 작업 대화 단위 | 작업 목적이 바뀌면 새 세션을 고려한다. |
| Context window | 현재 모델이 볼 수 있는 정보 범위 | 긴 작업에서는 중요한 조건을 문서화한다. |
| Auto memory | 반복 학습되는 프로젝트 패턴 | 민감 정보가 저장되지 않도록 주의한다. |

## 6. Lab 03: 권한, 계획, 검증

AI coding agent는 파일을 수정하고 명령을 실행할 수 있기 때문에 권한 통제가 중요하다. Claude Code는 permission mode를 통해 파일 edit, shell command, 자동 승인 범위를 조절한다. 기본 모드에서는 중요한 작업 전에 확인을 요구하고, plan mode에서는 실제 수정을 하기 전 탐색과 계획 수립에 집중할 수 있다.

실무에서는 plan mode를 적극적으로 활용하는 편이 안전하다. 큰 구조 변경, 데이터 삭제 가능성이 있는 작업, 배포 관련 명령처럼 영향 범위가 큰 요청은 먼저 코드와 설정을 읽게 하고, 변경 계획을 검토한 뒤 실행 단계로 넘어가는 방식이 적절하다. 또한 파일 수정 후에는 test, lint, type check, build 같은 검증 명령을 요구해야 한다.

이 Lab의 핵심은 Claude Code에게 더 많은 권한을 주는 것이 생산성의 전부가 아니라는 점이다. 높은 권한은 빠른 실행을 가능하게 하지만, 잘못된 명령이나 범위 초과 수정이 발생하면 복구 비용이 커진다. 따라서 권한은 작업 위험도에 맞게 조절해야 한다.

## 7. Lab 04: common workflow

Claude Code는 반복적인 개발 업무를 workflow 단위로 처리할 때 효과가 크다. 예를 들어 테스트가 없는 모듈에 테스트를 추가하고, 실패한 테스트를 읽고, 원인을 찾아 수정한 뒤 다시 테스트를 실행하는 흐름은 agentic loop에 잘 맞는다. 공식 문서에서도 Claude Code가 context를 모으고, action을 수행하고, 결과를 verify하는 반복 구조로 동작한다고 설명한다.

대표적인 workflow는 다음과 같다.

| 작업 | 요청 방식 | 검증 기준 |
|---|---|---|
| 버그 수정 | 증상, 재현 조건, 관련 파일 범위를 제공한다. | 재현 테스트가 실패 후 성공하는지 확인한다. |
| 테스트 추가 | 대상 모듈과 기대 동작을 명시한다. | test suite가 통과하는지 확인한다. |
| 리팩터링 | 변경 목적과 유지해야 할 public behavior를 분리한다. | 기존 테스트와 type check를 실행한다. |
| 문서화 | 대상 독자와 사용 흐름을 지정한다. | 명령, 경로, 예제가 실제 코드와 맞는지 확인한다. |
| Git 작업 | commit 범위와 메시지 의도를 지정한다. | diff에 의도하지 않은 파일이 포함되지 않았는지 확인한다. |

핵심은 “알아서 고쳐 줘”가 아니라, 실패 조건과 성공 기준을 함께 주는 것이다. Claude Code는 도구를 실행하며 스스로 확인할 수 있으므로, 사용자가 검증 가능한 기준을 제공할수록 결과 품질이 안정된다.

## 8. Lab 05: MCP, skills, hooks 확장

Claude Code는 기본적인 파일 편집과 명령 실행을 넘어 외부 도구와 연결할 수 있다. MCP(Model Context Protocol)는 외부 서비스나 사내 도구를 Claude Code에 연결하기 위한 표준 방식이다. 예를 들어 문서 저장소, 이슈 트래커, 디자인 도구, 내부 API를 MCP server로 연결하면 Claude Code가 프로젝트 외부의 맥락까지 활용할 수 있다.

Skills와 hooks도 workflow 표준화에 사용된다. Skill은 반복 가능한 작업 지침을 패키징하는 방식이고, hook은 특정 시점에 shell command를 실행해 자동 검증이나 formatting을 연결하는 방식이다. 예를 들어 파일 수정 후 formatter를 실행하거나, commit 전 lint를 실행하는 구조를 만들 수 있다.

확장 기능을 설계할 때는 편의성보다 통제 가능성을 먼저 봐야 한다. 외부 시스템 접근 권한, 개인정보, API token, 삭제성 명령이 관련될 수 있기 때문이다. 따라서 MCP와 hooks는 “무엇을 자동화할 것인가”와 함께 “무엇은 절대 자동화하지 않을 것인가”를 명시해야 한다.

## 9. Lab 06: 팀 운영 기준

팀에서 Claude Code를 쓰려면 개인 생산성 도구로만 취급해서는 안 된다. 같은 코드베이스에서 여러 사람이 AI agent를 사용하면 coding convention, test command, branch strategy, review 기준이 흔들릴 수 있다. 따라서 팀 단위 운영 기준이 필요하다.

권장 기준은 다음과 같다.

- 프로젝트 루트에 `CLAUDE.md`를 두고 공통 규칙을 기록한다.
- 위험한 shell command와 배포 명령은 자동 승인하지 않는다.
- 큰 변경은 plan mode로 먼저 검토한다.
- 테스트, lint, type check 등 검증 명령을 표준화한다.
- AI가 작성한 코드도 사람이 review한다.
- secret, credential, 개인정보가 prompt나 memory에 남지 않도록 주의한다.
- commit은 작업 단위로 작게 나누고 diff를 확인한다.

이 기준은 Claude Code를 제한하기 위한 것이 아니라, 팀이 재현 가능한 방식으로 AI coding agent를 활용하기 위한 운영 장치다. 좋은 사용 방식은 속도를 높이면서도 변경 범위, 검증 결과, 보안 책임을 명확하게 남긴다.

## 10. 3일차 핵심 정리

3일차의 핵심은 Claude Code를 단순한 코드 생성 도구가 아니라 개발 workflow를 수행하는 agent로 이해하는 것이다. Claude Code는 프로젝트를 읽고, 파일을 수정하고, 명령을 실행하고, 테스트로 결과를 확인할 수 있다. 이 능력을 제대로 활용하려면 명확한 작업 목표, 프로젝트 컨텍스트, 권한 설정, 검증 기준이 함께 필요하다.

가장 중요한 결론은 다음과 같다.

- Claude Code는 codebase context와 terminal tool을 결합한 agentic coding tool이다.
- 좋은 요청은 작업 목적, 관련 범위, 성공 기준, 검증 명령을 포함한다.
- `CLAUDE.md`는 반복되는 프로젝트 규칙을 안정적으로 전달하는 핵심 문서다.
- plan mode와 permission mode는 생산성과 안전성의 균형을 맞추는 장치다.
- MCP, skills, hooks는 workflow를 확장하지만 권한과 보안 기준이 함께 필요하다.
- 팀 단위 활용에서는 AI 결과물도 review와 test를 통과해야 한다.

## 11. 참고자료

<ul>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/00-overview" target="_blank" rel="noopener">NxtCloud Workshop: Claude Code 과정 개요</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-01" target="_blank" rel="noopener">Lab 01: Claude Code</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-02" target="_blank" rel="noopener">Lab 02: Claude Code</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-03" target="_blank" rel="noopener">Lab 03: Claude Code</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-04" target="_blank" rel="noopener">Lab 04: Claude Code</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-05" target="_blank" rel="noopener">Lab 05: Claude Code</a></li>
  <li><a href="https://workshop.nxtcloud.kr/courses/claude-code/lab-06" target="_blank" rel="noopener">Lab 06: Claude Code</a></li>
  <li><a href="https://code.claude.com/docs/en/overview" target="_blank" rel="noopener">Claude Code Docs: Overview</a></li>
  <li><a href="https://code.claude.com/docs/en/quickstart" target="_blank" rel="noopener">Claude Code Docs: Quickstart</a></li>
  <li><a href="https://code.claude.com/docs/en/how-claude-code-works" target="_blank" rel="noopener">Claude Code Docs: How Claude Code works</a></li>
  <li><a href="https://code.claude.com/docs/en/memory" target="_blank" rel="noopener">Claude Code Docs: How Claude remembers your project</a></li>
  <li><a href="https://code.claude.com/docs/en/permission-modes" target="_blank" rel="noopener">Claude Code Docs: Permission modes</a></li>
  <li><a href="https://code.claude.com/docs/en/mcp" target="_blank" rel="noopener">Claude Code Docs: MCP</a></li>
  <li><a href="https://code.claude.com/docs/en/hooks" target="_blank" rel="noopener">Claude Code Docs: Hooks</a></li>
  <li><a href="https://code.claude.com/docs/en/best-practices" target="_blank" rel="noopener">Claude Code Docs: Best practices</a></li>
</ul>
