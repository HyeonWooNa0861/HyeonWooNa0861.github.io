---
layout: default
title: "AdaStop"
topic: "Sequential statistical testing for Deep RL reproducibility"
order: 46
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "AdaStop"
  - "DRL reproducibility"
  - "Sequential testing"
  - "Statistical evaluation"
---

# AdaStop: adaptive statistical testing for sound comparisons of Deep RL agents

Source PDF: `adastop-sequential-testing-deep-rl.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | AdaStop: adaptive statistical testing for sound comparisons of Deep RL agents |
| 저자 | Timothée Mathieu, Matheus Medeiros Centa, Riccardo Della Vecchia, Hector Kohler, Alena Shilova, Odalric-Ambrym Maillard, Philippe Preux |
| 출처 | Transactions on Machine Learning Research / OpenReview, 2024 |
| 주제 | Sequential statistical testing for Deep RL reproducibility |
| 핵심 방법 | Multiple group sequential tests with family-wise error control |
| 코드 | `TimotheeMathieu/adastop` |

## 한 줄 요약

AdaStop은 Deep RL 알고리즘 비교를 고정된 seed 수 관행이 아니라, family-wise error를 제어하는 순차적 통계 검정 문제로 재정의해 필요한 실행 수를 데이터에 맞춰 줄이거나 늘리는 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Reproducibility | 왜 3-5 seed 비교가 통계적으로 불안정한가? |
| 2 | Problem setup | agent, score distribution, mean 비교를 어떻게 정의하는가? |
| 3 | Sequential testing | 중간 분석을 반복하면서 언제 더 실행하고 언제 멈출 수 있는가? |
| 4 | Multiple testing | 여러 agent 비교에서 family-wise error(FWE)를 어떻게 제어하는가? |
| 5 | MuJoCo use cases | benchmark별 score variance가 필요한 실행 수를 어떻게 바꾸는가? |
| 6 | Limits | 방향성 결론과 non-asymptotic power는 어디까지 보장되는가? |

## 한국어 번역형 해설

### 초록과 문제의식

논문은 Deep RL의 재현성 문제를 “코드를 공개했는가”보다 좁고 통계적인 질문으로 다룬다. 한 번의 학습 실행에서 얻는 성능 score는 random variable이므로, 알고리즘의 평균 성능을 비교하려면 여러 independent executions가 필요하다. 저자들은 ICML 2022에 발표되고 MuJoCo를 사용한 RL 논문들을 조사해 대부분의 실험이 agent당 5개 이하의 score로 결론을 냈다고 보고한다. 이 관행은 계산 비용을 줄이는 데는 유리하지만, score distribution이 non-Gaussian이거나 multimodal이면 평균 차이를 안정적으로 판단하기 어렵다.

AdaStop의 문제의식은 seed 수를 “3개면 충분한가, 80개면 과한가”처럼 고정값으로 정하는 대신, 비교 대상의 score가 실제로 얼마나 구분되는지를 보며 실행 수를 적응적으로 결정하자는 데 있다. 논문에서 말하는 agent는 hyperparameter가 고정된 구체적 구현이고, score는 해당 agent를 학습·평가해 얻은 성능값이다. 따라서 AdaStop은 추상적인 알고리즘 우열 판정이 아니라, 정해진 evaluation protocol 안에서 agent들의 score distribution 또는 평균을 비교하는 절차로 읽어야 한다.

### 제안 방법 또는 분석 구조

AdaStop은 multiple group sequential tests를 Deep RL 비교에 맞춘 절차다. 실험자는 한 번에 모든 seed를 실행하지 않고, \(N\)개의 중간 분석과 각 단계의 batch 크기 \(K\)를 정한다. 각 단계에서 새 score가 추가되면 pairwise comparison을 수행하고, 충분한 증거가 모인 비교는 더 이상 score를 요구하지 않는다. 아직 구분되지 않은 비교에는 다음 단계 실행을 배정한다.

핵심은 여러 agent를 동시에 비교할 때 생기는 multiple testing 문제다. pairwise test를 여러 번 수행하면 개별 test의 type I error가 작아도 전체 family에서 하나 이상 잘못 reject할 확률이 커진다. AdaStop은 family-wise error(FWE)를 기준으로 이 위험을 제어하며, 논문은 distribution comparison에 대해 non-asymptotic FWE bound를 제시한다. 저자들이 “better” 대신 “most likely better(MLB)”라는 표현을 쓰는 것도 이 통계적 보장의 범위를 넘지 않기 위한 장치다.

이 방법이 요구하는 성질은 명확하다. Deep RL score는 정규분포를 따르지 않을 수 있으므로 nonparametric해야 하고, 계산량을 줄이기 위해 sequential/adaptive해야 하며, 여러 agent 비교를 다루기 위해 multiple testing을 포함해야 한다. 또한 실제 실험에서는 agent당 최대 budget \(B\)가 있으므로 bounded budget 안에서 결론을 내릴 수 있어야 한다.

### 실험 설정과 결과 해석

논문은 toy example과 MuJoCo benchmark에서 AdaStop을 보인다. HalfCheetah와 Hopper 예시에서는 SAC, PPO, TRPO, DDPG를 비교하고, 각 agent의 최대 score budget을 \(B=30\)으로 둔다. HalfCheetah에서는 AdaStop이 SAC와 PPO 각각 5개 score만으로 SAC가 PPO보다 MLB라고 결론 내린다. Hopper에서는 SAC가 DDPG 및 TRPO보다 MLB라는 결론에 10개 score가 충분했지만, SAC와 PPO가 동등하게 수행된다는 결론에는 양쪽 모두 최대 budget 30개 score가 필요했다.

Colas et al.의 HalfCheetah SAC-TD3 data를 사용한 비교도 중요한 확인점이다. \(N=4, K=5\)이면 최대 \(N \times K=20\) score를 사용할 수 있지만, AdaStop은 평균적으로 12개의 effective scores만으로 power 0.82 수준의 decision을 냈다. 같은 맥락에서 기존 non-adaptive protocol은 약 15개 score를 요구했다. 이 결과는 AdaStop이 항상 적은 seed를 쓰게 한다는 뜻이 아니라, 차이가 뚜렷한 비교에서는 빨리 멈추고 애매한 비교에서는 budget까지 간다는 뜻이다.

Section 5.3의 MuJoCo 실험은 Ant-v3, HalfCheetah-v3, Hopper-v3, Humanoid-v3, Walker2d-v3에서 PPO, SAC, DDPG, TRPO를 비교한다. \(N=5, K=6\) 설정에서 SAC가 여러 환경에서 다른 agent보다 MLB로 나타나지만, 동등하거나 분리하기 어려운 비교는 \(NK=30\)까지 필요했다. Appendix의 early accept heuristic을 쓰면 Walker2d-v3에서 각 agent당 10개 score로 같은 final decisions를 얻는 예도 제시된다.

### 논문 주장과 해석의 경계

논문이 주장하는 것은 AdaStop이 여러 algorithm의 score distribution을 비교할 때 FWE를 낮게 유지하면서 실행 수를 적응적으로 선택한다는 점이다. 이 주장은 정해진 agent, score definition, evaluation protocol, budget 안에서 성립한다. 따라서 블로그 해석으로 “AdaStop을 쓰면 RL 알고리즘의 절대적 우열을 증명한다”고 확장하면 과장이다.

작성자 관점에서 AdaStop의 의의는 Deep RL 성능표를 평균과 표준편차의 나열로 끝내지 않고, 그 표가 어떤 오류 보장 아래 만들어졌는지를 묻게 만든 데 있다. 재현성 논의는 seed 수, score 추출 방식, evaluation schedule, multiple comparison 보정을 함께 포함해야 한다.

### 한계와 확장 방향

논문은 bidirectional distribution test를 사용한 뒤 empirical mean의 부호로 방향을 해석하는 관행이 conceptually unsatisfactory하다고 인정한다. 즉 test 자체가 “두 분포가 다르다”를 보장하더라도, 어느 쪽 평균이 더 큰지에 대한 directional error 문제는 별도 분석이 필요하다. 해결 방향은 mean comparison에 대한 non-asymptotic power, FWE, directional error control을 함께 정리하는 것이다.

또 다른 한계는 AdaStop이 실험 설계의 품질을 대체하지 못한다는 점이다. score definition, random seed policy, hyperparameter selection, evaluation episode 수가 흔들리면 순차 검정도 흔들린 결론을 낸다. 실제 적용에서는 AdaStop 설정 \(N, K, B, \alpha\), evaluation protocol, early stopping rule을 사전에 고정하고, Atari나 MuJoCo 여러 task 묶음처럼 task collection 전체를 비교하는 방향으로 확장하는 것이 필요하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/adastop-sequential-testing-deep-rl/adastop-sequential-testing-deep-rl.pdf" | relative_url }}" target="_blank" rel="noopener">adastop-sequential-testing-deep-rl.pdf</a></li>
  <li><a href="https://openreview.net/forum?id=lXyZr9TLEU" target="_blank" rel="noopener">OpenReview</a></li>
  <li><a href="https://arxiv.org/abs/2306.10882" target="_blank" rel="noopener">arXiv:2306.10882</a></li>
  <li><a href="https://github.com/TimotheeMathieu/adastop" target="_blank" rel="noopener">Project repository</a></li>
</ul>
