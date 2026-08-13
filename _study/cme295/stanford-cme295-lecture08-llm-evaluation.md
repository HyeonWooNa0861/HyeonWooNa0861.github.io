---
layout: default
title: "Stanford CME295 Lecture 8: LLM Evaluation"
course: "CME295"
topic: "LLM Output Quality Evaluation, LLM-as-a-Judge, Agent Evaluation, and Benchmarks"
order: 8
major_topic: "Large Language Models"
keywords:
  - "LLM Evaluation"
  - "Benchmarks"
  - "Human Evaluation"
  - "Safety Evaluation"
  - "Evals"
---

# Stanford CME295 Lecture 8: LLM Evaluation

Source: [Stanford CME295 Autumn 2025 Lecture 8](https://www.youtube.com/watch?v=8fNP4N46RRo){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 평가의 범위 | 이 강의에서 LLM evaluation은 latency나 pricing이 아니라 어떤 대상을 주로 평가하는가? |
| 2 | human rating과 agreement | 사람 평가가 이상적이지만 비용, 속도, 주관성 때문에 어떤 agreement metric이 필요한가? |
| 3 | rule-based metrics | METEOR, BLEU, ROUGE는 reference와 prediction을 어떻게 비교하며 어디서 한계가 생기는가? |
| 4 | LLM-as-a-Judge | judge LLM에는 어떤 입력이 들어가고, 왜 rationale을 score보다 먼저 출력하게 하는가? |
| 5 | judge bias와 best practices | position, verbosity, self-enhancement bias를 줄이기 위한 실무적 방법은 무엇인가? |
| 6 | factuality와 agent evaluation | 긴 답변의 사실성을 fact 단위로 쪼개는 이유와 agent loop의 오류를 단계별로 나누는 이유는 무엇인가? |
| 7 | 벤치마크와 해석 | MMLU, AIME, PIQA, SWE-bench, HarmBench, tau-bench는 각각 어떤 능력을 보려는가? |

## 핵심 내용

이 강의는 LLM 평가를 출력 품질 평가로 좁혀 정의한다. LLM은 자연어, 코드, 수학 reasoning 등 자유 형식 출력을 만들기 때문에 보편적 지표를 만들기 어렵다. 이상적으로는 모든 출력을 사람이 평가할 수 있지만, 비용과 속도 문제가 크고 rating task 자체가 주관적일 수 있으므로 inter-rater agreement를 추적해야 한다. 단순 agreement rate는 우연 일치의 baseline을 반영하지 못하므로 Cohen's kappa, Fleiss's kappa, Krippendorff's alpha 같은 지표가 소개된다.

그 다음 강의는 reference output을 고정하고 METEOR, BLEU, ROUGE 같은 rule-based metric으로 예측 출력과 비교하는 방식을 설명한다. METEOR는 precision, recall, ordering penalty를 조합하고, BLEU는 n-gram precision과 brevity penalty를 사용하며, ROUGE는 summarization에서 자주 쓰인다. 그러나 이런 지표들은 문체적 변형을 충분히 허용하지 못하고 human rating과의 상관도 제한적이어서, prompt, response, criteria를 다른 LLM에 넣어 rationale과 score를 얻는 LLM-as-a-Judge가 핵심 방법으로 제시된다.

후반부는 LLM-as-a-Judge의 실무 주의점과 더 넓은 벤치마크 생태계를 다룬다. judge는 pointwise 또는 pairwise로 쓸 수 있고, structured output을 위해 constrained-guided decoding 또는 provider의 structured output 기능을 사용한다. position bias, verbosity bias, self-enhancement bias를 줄이려면 응답 순서 바꾸기, 명확한 guideline, binary scale, rationale-before-score, human calibration, 낮은 temperature가 필요하다. factuality는 텍스트를 fact 단위로 쪼개고 RAG나 web search로 사실 여부를 binary로 확인한 뒤 가중합으로 평가할 수 있으며, 에이전트 평가는 tool prediction, tool execution, output synthesis 각각의 실패 모드를 분리해 본다. 마지막으로 MMLU, AIME, PIQA, SWE-bench, HarmBench, tau-bench, data contamination, Pareto frontier, Goodhart's law가 LLM 성능 해석의 맥락으로 소개된다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Inter-rater agreement | 여러 사람이 같은 LLM 출력에 대해 얼마나 일관된 평가를 내리는지 측정하는 개념이다. |
| Cohen's kappa | 두 평가자의 observed agreement를 chance agreement와 비교해 보정하는 지표로, 우연보다 나은 일치인지 판단하게 해 준다. |
| METEOR | translation evaluation metric으로, precision과 recall 기반 F score에 ordering penalty를 곱해 reference와 prediction을 비교한다. |
| BLEU | bilingual evaluation understudy. prediction의 n-gram precision을 중심으로 보며, 너무 짧은 번역을 막기 위해 brevity penalty를 둔다. |
| LLM-as-a-Judge | LLM 출력 평가를 다른 LLM에 맡겨 score와 rationale을 생성하는 방식이다. |
| Structured output | JSON 같은 특정 형식을 보장하기 위해 decoding 중 valid token만 허용하는 constrained-guided decoding 계열 기능이다. |
| Position bias | pairwise judge에서 먼저 제시된 응답을 더 선호하는 경향이다. |
| Self-enhancement bias | 모델이 자신이 생성한 응답을 더 선호할 수 있는 judge bias로, generation model과 judge model을 분리해 줄일 수 있다. |
| tau-bench | airline과 retail 도메인에서 tools, policies, simulated user를 이용해 agent가 task를 일관되게 완료하는지 평가하는 benchmark다. |
| Goodhart's law | 측정값이 목표가 되면 좋은 측정값이 아니게 된다는 법칙으로, benchmark 최적화가 실제 사용 품질을 대체할 수 없음을 경고한다. |

## 학습 포인트

- LLM output quality 평가는 자유 형식 텍스트를 다루기 때문에 보편적인 단일 metric을 만들기 어렵다.
- agreement rate는 우연히 일치할 확률을 반영하지 못하므로 Cohen's kappa 같은 chance-adjusted agreement metric이 필요하다.
- METEOR, BLEU, ROUGE는 reference 기반 자동 평가이지만 문체 변형과 의미 동등성을 충분히 반영하지 못한다.
- LLM-as-a-Judge는 prompt, response, criteria를 입력으로 받아 rationale과 score를 출력하며, pointwise와 pairwise 설정 모두 가능하다.
- structured output은 constrained-guided decoding 또는 provider의 structured output 기능으로 JSON 같은 형식을 강제할 수 있다.
- judge에는 position bias, verbosity bias, self-enhancement bias가 있을 수 있으므로 평가 prompt와 실험 설계를 조심해야 한다.
- factuality 평가는 답변 전체를 한 번에 pass/fail하지 않고 fact extraction, fact checking, weighted aggregation으로 세분화할 수 있다.
- benchmark score는 model profile을 보여주는 도구이지 절대적 품질 보증이 아니며, contamination과 Goodhart's law를 고려해야 한다.

## 마지막 핵심 정리

이 강의의 핵심은 `LLM 출력 품질 평가, LLM-as-a-Judge, 에이전트 및 벤치마크 평가`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것이다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 한다.

## Study Guide

1. human rating, rule-based metric, LLM-as-a-Judge를 비용, reference 필요 여부, 해석 가능성, 실패 모드 관점에서 비교한다.
2. Cohen's kappa가 agreement rate와 다른 점을 chance agreement 예시와 함께 설명한다.
3. LLM-as-a-Judge prompt에 prompt, response, criteria, output schema가 어떻게 들어가야 하는지 작은 예시를 만든다.
4. position bias, verbosity bias, self-enhancement bias에 대해 각각 하나의 실패 사례와 mitigation을 적는다.
5. MMLU, AIME, PIQA, SWE-bench, HarmBench, tau-bench를 knowledge, reasoning, coding, safety, agent tool-use 범주로 분류한다.

## 복습 질문

<details>
<summary>1. agreement rate만으로 inter-rater agreement를 평가하면 왜 문제가 되는가?</summary>

답변: 두 평가자가 무작위로 답해도 일정 비율은 일치한다. 예를 들어 둘 다 0.5 확률로 1 또는 0을 고르면 우연 agreement rate가 0.5가 되므로, 관측 일치를 chance baseline과 비교해야 한다.

</details>

<details>
<summary>2. METEOR와 BLEU의 공통 한계는 무엇인가?</summary>

답변: 둘 다 reference와 prediction의 token 또는 n-gram matching에 크게 의존하므로, 의미는 같지만 표현이 다른 자연어 응답을 낮게 평가할 수 있다.

</details>

<details>
<summary>3. LLM-as-a-Judge에서 rationale을 score보다 먼저 출력하게 하는 이유는 무엇인가?</summary>

답변: 모델이 평가 근거를 먼저 verbalize하면 reasoning model이 답 전에 reasoning chain을 만드는 것과 비슷하게, score 품질이 경험적으로 좋아질 수 있기 때문이다.

</details>

<details>
<summary>4. factuality를 평가할 때 답변 전체를 하나의 binary label로 처리하지 않는 이유는 무엇인가?</summary>

답변: 한 답변 안에는 여러 사실이 있고 일부만 틀릴 수 있다. fact extraction, 개별 fact checking, 중요도 가중 aggregation을 쓰면 부분 오류의 정도를 더 잘 반영할 수 있다.

</details>

<details>
<summary>5. tau-bench에서 pass_hat_k가 중요한 이유는 무엇인가?</summary>

답변: agent는 한 번만 성공하는 것보다 반복 실행에서 모두 성공하는 reliability와 consistency가 중요하다. 그래서 k번 시도 중 하나라도 성공하는 pass@k보다 모든 시도가 성공할 확률을 본다.

</details>

## 참고자료

- [강의 영상](https://www.youtube.com/watch?v=8fNP4N46RRo){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
