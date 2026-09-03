---
layout: post
title: "Harness Engineering for Self-Improvement"
nav_title: "Harness Engineering"
date: 2026-07-04 00:00:00 +0900
categories: [AIAgents, HarnessEngineering]
tags: [AI Agent, Harness, Self Improvement, Context Engineering, Workflow Automation]
permalink: /posts/harness-engineering-self-improvement/
section: ai-agents
---

이 글은 Lilian Weng의 글 <a href="https://lilianweng.github.io/posts/2026-07-04-harness/" target="_blank" rel="noopener">Harness Engineering for Self-Improvement</a>를 바탕으로, AI agent를 둘러싼 harness가 왜 recursive self-improvement 논의에서 중요한지 정리한 해설이다. 원문은 harness를 단순한 prompt wrapper가 아니라 모델이 도구를 호출하고, context를 관리하고, 파일에 상태를 남기고, 결과를 평가하며, 실패를 다시 학습하는 실행 시스템으로 본다.

핵심은 모델 자체의 지능만 보지 말고, 모델 주변의 실행 환경을 함께 봐야 한다는 점이다. coding agent가 실제 repository에서 파일을 읽고 수정하고 테스트를 실행할 수 있는 이유는 base model만으로 설명되지 않는다. 어떤 도구를 언제 쓸 수 있는지, 실패 로그를 어디에 남기는지, sub-agent를 어떻게 띄우고 회수하는지, 어떤 검증을 통과해야 완료로 볼 것인지가 모두 harness의 설계 문제다.

> **핵심 메시지:** Agent의 실제 능력은 base model만이 아니라 context, tools, persistent state, permissions, evaluation과 반복 workflow를 묶는 harness에서 결정된다. Self-improvement도 먼저 이 실행 체계를 관찰 가능하고 검증 가능하게 개선하는 문제로 이해해야 한다.

## 1. 글의 문제의식

Recursive self-improvement는 AI가 자기 자신을 더 나은 시스템으로 개선하는 반복 구조를 뜻한다. 원문은 이 개념을 모델이 직접 weight를 고치는 좁은 의미로만 보지 않는다. 더 현실적인 가까운 경로는 모델 주변의 training pipeline, deployment system, workflow, memory, evaluator를 개선하는 방향이라고 본다.

여기서 deployment system, 특히 harness가 중요해진다. 같은 모델이라도 어떤 harness 안에서 실행되는지에 따라 할 수 있는 일이 달라진다. 단발성 답변 모델은 긴 프로젝트를 유지하기 어렵지만, 파일 시스템, 작업 로그, 테스트 루프, 권한 제어, sub-agent 실행을 갖춘 coding agent는 훨씬 긴 작업을 수행할 수 있다.

## 2. Harness란 무엇인가

원문에서 harness는 base model을 둘러싼 실행 시스템이다. 이 시스템은 모델이 생각하고 계획하는 방식, tool call, 행동, context 관찰, artifact 저장, 평가 절차를 조직한다.

초기 agent framework가 흔히 “LLM + memory + tools + planning + action”으로 설명되었다면, harness engineering은 그보다 runtime과 software system design에 가깝다. 단순히 좋은 prompt template을 쓰는 문제가 아니라 다음 요소를 함께 설계해야 한다.

| 구성 요소 | 역할 |
|---|---|
| Workflow | 계획, 실행, 관찰, 테스트, 개선을 어떤 loop로 연결할지 정한다. |
| Persistent memory | 긴 작업의 로그, 산출물, 실패 사례를 파일로 남겨 context window 한계를 줄인다. |
| Tool interface | 파일 읽기, 검색, 수정, shell 실행, browser, MCP 같은 도구 접근 방식을 정한다. |
| Evaluation | 결과가 맞는지 판단할 test, verifier, benchmark, review 절차를 둔다. |
| Permission control | 모델이 수정할 수 있는 영역과 절대 건드리면 안 되는 영역을 분리한다. |
| Sub-agent orchestration | 병렬 탐색, 독립 실험, backend job 실행과 결과 회수를 관리한다. |

## 3. Design Pattern 1: Workflow Automation

첫 번째 패턴은 모델이 반복적으로 작업할 수 있는 workflow를 만드는 것이다. 일반적인 loop는 목표 설정, 계획, 실행, 관찰 또는 테스트, 개선, 재실행으로 이어진다.

중요한 차이는 prompt 하나로 모든 것을 해결하려 하지 않는다는 점이다. agent runtime이 작업 궤적과 실패 사례를 관찰하고, 그 결과를 다음 행동에 반영한다. 예를 들어 coding agent라면 다음과 같은 흐름이 자연스럽다.

1. 문제를 읽고 repository 구조를 탐색한다.
2. 관련 파일을 열어 현재 구현 방식을 파악한다.
3. 작은 변경을 적용한다.
4. 테스트나 lint를 실행한다.
5. 실패하면 로그를 읽고 원인을 좁힌다.
6. 성공 조건이 충족될 때까지 수정한다.

이 loop가 명시되어 있으면 모델은 “답을 생성하는 일”이 아니라 “작업을 완료하는 일”에 맞춰 움직일 수 있다.

## 4. Design Pattern 2: File System as Persistent Memory

긴 agent 작업에서는 모든 로그와 산출물을 context에 계속 들고 있을 수 없다. 원문은 그래서 파일 시스템을 persistent memory로 쓰는 패턴을 강조한다.

파일 시스템은 단순하지만 강력하다. 실험 로그, code diff, paper summary, error trace, rollout trajectory를 파일로 남기면 agent는 필요한 시점에 다시 읽을 수 있다. context window가 제한되어 있어도 작업의 역사 전체를 매번 prompt에 붙일 필요가 없다.

이 관점은 실제 coding agent 사용 경험과도 잘 맞는다. 좋은 작업 기록은 다음 실행에서 바로 증거가 된다. 반대로 실패 로그가 chat context에만 남아 있으면 세션이 끊긴 뒤 복구하기 어렵고, 같은 실패를 반복하기 쉽다.

## 5. Design Pattern 3: Sub-agent와 Backend Job

세 번째 패턴은 병렬성을 명시적으로 관리하는 것이다. main agent가 여러 가설을 동시에 조사하거나, 독립 실험을 병렬로 실행하거나, 긴 backend job을 띄워야 할 때 sub-agent와 job manager가 필요하다.

여기서 중요한 기준은 병렬 실행이 inspectable해야 한다는 점이다. sub-agent 결과가 transient chat에만 있으면 hidden state가 된다. 반대로 각 agent의 입력, 로그, 상태, 산출물이 파일이나 명시적 record로 남으면 parent agent가 중단 후에도 회수하고 비교할 수 있다.

즉 sub-agent는 단순히 “더 많은 모델 호출”이 아니다. 어떤 작업을 분리할지, 결과를 어떤 형식으로 받을지, 실패한 job을 어떻게 취소할지, 최종 판단을 main agent가 어떻게 통합할지가 harness 설계의 일부다.

## 6. Harness Layer와 Core Intelligence

원문은 near-term self-improvement가 model weight를 직접 고치는 방식보다 harness engineering에서 먼저 나타날 가능성이 높다고 본다. 이유는 harness가 답 자체보다 “더 좋은 답을 얻는 방법”을 개선하는 meta-methodology이기 때문이다.

다만 harness가 모든 것을 해결한다는 뜻은 아니다. 모델이 충분히 강하지 않으면 좋은 harness도 한계가 있다. 반대로 모델이 강해질수록 지나치게 복잡한 harness는 줄어들 수 있다. prompt engineering의 일부 기법이 모델 내부 능력으로 흡수된 것처럼, harness의 일부 기능도 장기적으로 core model behavior에 흡수될 수 있다.

그래도 외부 context, tool, permission, evaluator와 연결되는 interface는 계속 중요하게 남는다. 실제 세계에서 작업하려면 모델 바깥의 파일, 코드, 브라우저, 데이터, 권한 경계가 필요하기 때문이다.

## 7. Context Engineering: Context를 Artifact처럼 다루기

Harness optimization에서 먼저 다루는 축은 context engineering이다. 긴 agent 작업에서 모든 tool response와 model generation을 그대로 붙이면 context가 쉽게 붕괴한다. 그래서 context를 계속 길어지는 prompt가 아니라 관리되는 artifact로 봐야 한다.

원문은 Agentic Context Engineering(ACE)과 Meta Context Engineering(MCE)을 예로 든다. ACE는 성공과 실패 trajectory에서 배운 내용을 structured context playbook으로 축적한다. 핵심은 전체 prompt blob을 매번 다시 쓰는 대신, 식별자와 설명을 가진 itemized bullet들을 관리한다는 점이다.

MCE는 한 단계 더 나아가 context를 관리하는 mechanism 자체를 optimization 대상으로 둔다. 어떤 지식을 저장하고, 어떻게 검색하고, 어떤 형식으로 모델에 제공할지까지 skill 형태로 진화시킨다. 여기서 context는 단순 문자열이 아니라 파일, static component, dynamic operator가 결합된 실행 가능한 구조가 된다.

## 8. Workflow Design: 연구 자동화의 사례

원문은 auto-research 계열 시스템을 통해 workflow design을 설명한다. AI Scientist, ScientistOne, Autodata, ADAS, AFlow 같은 시스템은 모두 모델이 연구 아이디어를 만들고, 코드를 작성하고, 실험을 실행하고, 결과를 해석하고, 문서를 쓰는 과정을 harness로 조직한다.

이때 중요한 설계 기준은 verifiability다. 연구 자동화는 그럴듯한 글을 쓰는 능력만으로 충분하지 않다. citation, 수치, 방법론, 결론이 실제 evidence와 연결되어야 한다. ScientistOne이 Chain-of-Evidence를 강조하는 이유도 여기에 있다.

Workflow 자체도 search problem이 될 수 있다. ADAS는 agent design을 optimization 대상으로 보고, meta-agent가 새로운 workflow를 code로 제안하고 평가한다. AFlow는 workflow를 graph로 표현하고 Monte Carlo Tree Search로 더 나은 workflow 후보를 찾는다.

## 9. Self-Improving Harness

Self-improving harness의 핵심은 harness 자체를 code로 보고, 그 code를 agent가 개선할 수 있게 만드는 것이다. 원문은 STOP, Meta-Harness, Self-Harness 같은 흐름을 연결해 설명한다.

STOP은 solution을 직접 고치는 것이 아니라 improver 자체를 개선하려는 초기 사례다. Self-Harness는 더 직접적으로 weakness mining, harness proposal, proposal validation의 loop를 사용한다.

| 단계 | 의미 |
|---|---|
| Weakness mining | 실행 trace와 verifier 결과를 모아 반복 실패 패턴을 찾는다. |
| Harness proposal | editable surface와 실패 패턴을 바탕으로 좁은 harness 수정안을 만든다. |
| Proposal validation | held-in, held-out 평가로 regression이 없는 수정만 받아들인다. |

이 구조에서 중요한 점은 permission control과 security layer가 self-improvement loop 바깥에 있어야 한다는 것이다. harness가 자기 자신을 수정할 수 있더라도, 모든 것을 수정할 수 있게 두면 abstraction boundary가 무너진다. reward hacking 문제도 그대로 남는다.

## 10. Evolutionary Search와 Harness Evolution

Harness search는 gradient로 직접 최적화하기 어렵지만 평가 가능한 후보를 만들 수 있다는 점에서 evolutionary search와 잘 맞는다. Promptbreeder, GEPA, AlphaEvolve, ShinkaEvolve, Darwin Godel Machine 같은 방법은 prompt, program, agent harness를 population으로 두고 mutation과 selection을 반복한다.

AlphaEvolve는 candidate program과 prompt를 저장하고, LLM이 diff를 만들어 개선한 뒤 평가를 통과한 후보를 유지한다. Darwin Godel Machine은 더 직접적으로 agent가 자기 harness codebase를 수정해 새로운 coding agent version을 만들고, benchmark에서 성능이 좋은 후보를 pool에 다시 넣는다.

하지만 이 방식은 평가가 빠르고 명확할 때 가장 잘 작동한다. matrix multiplication, GPU kernel optimization, algorithm contest처럼 fitness를 수치화하기 쉬운 문제와 달리, 연구의 novelty나 장기 유지보수성 같은 가치는 평가가 느리고 모호하다.

## 11. 남은 과제

원문은 harness engineering이 진전되고 있지만, full recursive self-improvement로 가기 위해서는 여러 bottleneck이 남아 있다고 정리한다.

| 과제 | 설명 |
|---|---|
| 약한 evaluator | 연구 가치, novelty, scientific taste는 unit test처럼 빠르게 평가하기 어렵다. |
| context와 memory lifecycle | memory가 커질수록 무엇을 보존하고 버릴지 정하는 관리 능력이 중요해진다. |
| negative result 보존 | 실패한 시도와 포기해야 할 가설을 기록하지 않으면 성공 사례 편향이 커진다. |
| diversity collapse | evolutionary/RL loop는 높은 reward pattern에 과도하게 수렴할 수 있다. |
| reward hacking | benchmark, unit test, judge model의 허점을 최적화할 위험이 있다. |
| 장기 유지보수 | 단기 task 성공이 repository 건강성, ownership boundary, migration cost를 보장하지 않는다. |
| 인간의 역할 | 사람은 loop 밖에서 적절한 추상화 수준의 oversight를 제공해야 한다. |

이 목록에서 특히 중요한 것은 “평가 가능한 것만 좋아지는 문제”다. coding task에서도 test를 통과하는 code가 항상 좋은 code는 아니다. 연구 task에서는 manuscript를 완성하는 것과 실제 scientific discovery 사이의 간극이 더 크다.

## 12. 읽을 때 잡아야 할 관점

이 글은 agent를 “똑똑한 모델 하나”로 이해하는 관점을 교정한다. 실제 성능은 base model, tool, context, workflow, memory, evaluator, permission이 결합된 system-level 결과다.

따라서 AI agent를 설계하거나 사용할 때는 다음 질문을 먼저 봐야 한다.

- 이 agent는 실패를 어디에 기록하는가?
- context가 길어질 때 무엇을 요약하고 무엇을 원문으로 보존하는가?
- 완료 판단은 model self-report인가, test/evaluator/review인가?
- 수정 가능한 surface와 금지된 surface는 분리되어 있는가?
- sub-agent나 병렬 job의 결과는 나중에 재검토 가능한 형태로 남는가?
- 단기 benchmark 점수와 장기 유지보수성이 충돌할 때 어떤 기준을 우선하는가?

## 13. 핵심 정리

Harness engineering은 모델을 둘러싼 실행 구조를 설계하는 일이다. 이 구조는 workflow, memory, tool call, evaluation, permission, sub-agent orchestration을 포함한다.

원문의 핵심 주장은 near-term self-improvement가 model weight 직접 수정이 아니라 harness와 deployment system 개선에서 먼저 나타날 가능성이 높다는 것이다. 다만 harness가 강력해질수록 evaluator, permission, 보안, 인간 oversight는 더 중요해진다. self-improvement loop 안에 모든 권한과 평가를 넣으면 성능은 오를 수 있어도 reward hacking과 boundary collapse 위험이 커진다.

결국 좋은 agent harness는 단순히 더 많은 자동화를 넣는 시스템이 아니다. 실패를 보존하고, 검증 가능한 작업 단위를 만들고, 수정 범위를 제한하고, 장기적인 품질을 해치지 않는 방식으로 모델의 능력을 배치하는 시스템이다.

## 14. 참고자료

<ul>
  <li><a href="https://lilianweng.github.io/posts/2026-07-04-harness/" target="_blank" rel="noopener">Lilian Weng, “Harness Engineering for Self-Improvement”, Lil'Log, July 4, 2026</a></li>
</ul>
