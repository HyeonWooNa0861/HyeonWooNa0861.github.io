---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Random Seeds in DRL"
topic: "Statistical power analysis for Deep RL seed counts"
order: 58
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "Random seeds"
  - "Statistical power"
  - "DRL evaluation"
  - "Reproducibility"
---

# How Many Random Seeds? Statistical Power Analysis in Deep Reinforcement Learning Experiments

Source PDF: `how-many-random-seeds-drl.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | How Many Random Seeds? Statistical Power Analysis in Deep Reinforcement Learning Experiments |
| 출처 | arXiv:1806.08295, 2018 |
| 주제 | Statistical power analysis for Deep RL seed counts |
| 핵심 방법 | Power analysis for choosing random seed counts |

## 한 줄 요약

이 논문은 Deep RL 비교에서 random seed 수를 관행적으로 정하지 말고, 검출하려는 effect size와 variance에 맞춰 power analysis로 계획해야 한다고 주장한다.

## 핵심 내용

Deep RL 성능은 random seed, 초기 상태와 환경 확률성에 따라 달라지므로, 소수 run의 평균만으로 알고리즘 차이를 판단하면 false positive 또는 낮은 검정력이 생길 수 있다. 이 논문은 seed 수를 관행적으로 고정하지 말고 검출하려는 effect size, 관측 variance, type-I error와 목표 power를 먼저 정하라고 제안한다.

Power analysis는 연구자가 주장하려는 최소 성능 차이를 실제로 검출할 수 있는 반복 횟수를 계산하게 한다. 따라서 핵심 결과는 특정 seed 수를 보편적 정답으로 제시하는 것이 아니라, variance와 effect size를 보고하고 그에 맞는 sample size를 설계해야 재현 가능한 비교가 된다는 실험 원칙을 확립한 데 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Seed variance | seed 수가 부족하면 어떤 오류가 생기는가? |
| 2 | Effect size | 검출할 성능 차이를 어떻게 정의하는가? |
| 3 | Power | 원하는 검정력에 필요한 run 수는 어떻게 계산하는가? |
| 4 | Practice | DRL 논문 reporting에는 어떤 정보가 필요한가? |

## 한국어 번역형 해설

### 초록과 문제의식

저자들은 Deep RL 재현성 문제에서 통계적 유의성 검정이 선택 사항이 아니라 실험 방법론의 일부라고 본다. 같은 알고리즘도 random seed, 초기 상태, 환경 stochasticity 때문에 서로 다른 성능을 낼 수 있으므로, 논문이 평균 학습 곡선만 제시하면 실제 차이와 표본 잡음을 구분하기 어렵다.

논문의 핵심 주장은 단순하다. seed 수를 3개, 5개, 10개처럼 관행적으로 정하지 말고, 검출하려는 effect size $$\epsilon$$, 표본 variance, type-I error $$\alpha$$, type-II error $$\beta$$를 함께 두고 필요한 sample size $$N$$을 계획해야 한다. 여기서 연구자의 해석을 덧붙이면, 이 논문은 "더 많은 seed가 좋다"는 일반론보다 "어떤 차이를 주장하려면 그 차이를 검출할 실험 설계가 먼저 필요하다"는 기준을 제공한다.

### 방법: seed 수를 power analysis 문제로 보기

논문은 알고리즘 성능을 random variable $$X$$로 모델링한다. 한 번의 실행은 하나의 realization $$x_i$$이고, $$N$$회 반복하면 표본 $$x=(x_1,\ldots,x_N)$$이 된다. 두 알고리즘을 비교할 때 관심 대상은 평균 차이 $$\mu_{\mathrm{diff}}=\mu_1-\mu_2$$이며, effect size는 $$\epsilon=\mu_1-\mu_2$$로 둘 수 있다.

저자들은 Henderson et al.이 권고한 Welch's $$t$$-test와 bootstrap confidence interval test를 중심으로 논의를 전개한다. Welch's $$t$$-test는 두 알고리즘의 variance가 같다고 가정하지 않는다는 점에서 일반 $$t$$-test보다 DRL 비교에 더 맞지만, 여전히 표본 독립성, 대표성, 분포 형태에 대한 가정을 둔다. Bootstrap confidence interval은 분포 가정을 줄이는 대신, 표본 자체가 기저 분포를 충분히 대표한다는 요구가 커진다.

Power analysis는 다음 질문에 답하는 절차다. 유의수준 $$\alpha$$의 검정을 사용해 effect size $$\epsilon$$을 $$1-\beta$$의 확률로 탐지하려면 seed가 몇 개 필요한가? 논문은 $$\beta$$가 $$\alpha$$, $$\epsilon$$, 두 표본의 경험 표준편차 $$s_1,s_2$$, 그리고 $$N$$에 의존한다고 정리한다. 따라서 $$s_1,s_2$$를 작은 pilot에서 부정확하게 추정하면 필요한 seed 수도 과소추정될 수 있다.

### 실험과 사례: 5 seed가 만든 false positive

Half-Cheetah 예시는 이 논문의 문제의식을 잘 보여준다. 저자들은 두 알고리즘을 각각 $$N=5$$개 random seed로 실행하고, 마지막 100개 평가 episode의 평균 성능을 비교한다. 평균 곡선과 95% confidence interval만 보면 Algo 1이 Algo 2보다 좋아 보이며, Welch's $$t$$-test도 $$p=0.031$$, bootstrap confidence interval도 $$[259,1564]$$로 0을 포함하지 않는다.

하지만 이 결론은 false positive였다. 두 알고리즘은 실제로 OpenAI baselines의 동일한 DDPG implementation이었기 때문이다. 즉 $$H_0$$가 참인데도 기각한 type-I error가 발생했다. 이 사례는 작은 seed 수에서 confidence interval이 겹치지 않는 것처럼 보이거나 $$p < 0.05$$가 나와도, 그 결과가 곧 알고리즘 우위를 보장하지 않는다는 점을 보여준다.

이후 논문은 작은 표본에서 bootstrap test가 특히 민감하고, non-normal 성능 분포에서는 $$t$$-test가 type-I error를 과소평가할 수 있음을 경험적으로 보인다. 또한 표준편차 추정이 불안정하면 power analysis가 요구하는 $$N$$도 지나치게 작게 나올 수 있다.

### 결론과 실무 지침

저자들의 권고는 보수적이다. Bootstrap confidence interval test는 $$N<20$$인 sample에는 사용하지 않는 것이 좋고, false positive rate를 0.05 아래로 유지하려면 검정의 significance level을 0.05보다 더 엄격하게 잡아야 한다. 여러 환경, 여러 알고리즘, 여러 metric을 동시에 비교한다면 Bonferroni correction 같은 multiple comparison 보정도 필요하다.

또한 두 알고리즘의 standard deviation을 robust하게 추정하려면 pilot study에서 적어도 $$n=20$$ sample을 확보하라고 권고한다. 최종 $$N$$은 power analysis가 산출한 값보다 크게 잡는 것이 안전하다. 연구자의 해석으로는, 이 지침은 계산 예산이 부족한 논문에서 "seed가 적다"는 약점을 숨기기보다, 검출 가능한 effect size와 불확실성을 함께 보고하게 만드는 reporting 기준에 가깝다.

### 한계와 확장 방향

논문 자체도 power analysis가 사전 variance와 effect size 추정에 의존한다는 한계를 갖는다. DRL benchmark는 환경, 구현, hyperparameter, reward scaling에 따라 분산이 달라지므로, 한 논문의 pilot 결과가 다른 설정에 그대로 이전되지는 않는다.

실무적 해결 방향은 세 가지다. 첫째, historical benchmark와 pilot run을 이용해 $$s_1,s_2$$를 명시적으로 추정한다. 둘째, 논문에는 평균 곡선뿐 아니라 raw seed score, confidence interval, 검정 방식, multiple comparison 보정 여부를 함께 공개한다. 셋째, 계산 예산이 제한될 때는 sequential 또는 adaptive design을 쓰되, 중단 규칙을 사전에 고정해 유리한 seed만 남기는 선택 편향을 막아야 한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/how-many-random-seeds-drl/how-many-random-seeds-drl.pdf" | relative_url }}" target="_blank" rel="noopener">how-many-random-seeds-drl.pdf</a></li>
  <li><a href="https://arxiv.org/abs/1806.08295" target="_blank" rel="noopener">arXiv:1806.08295</a></li>
</ul>
