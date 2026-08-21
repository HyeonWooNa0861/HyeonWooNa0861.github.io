---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Statistical Precipice"
topic: "Reliable statistical evaluation for deep reinforcement learning"
order: 53
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "DRL evaluation"
  - "Statistical reliability"
  - "Performance reporting"
  - "Benchmark variance"
---

# Deep Reinforcement Learning at the Edge of the Statistical Precipice

Source PDF: `drl-statistical-precipice.pdf`

## Paper Information

| Field | Detail |
| --- | --- |
| Original title | Deep Reinforcement Learning at the Edge of the Statistical Precipice |
| Venue | NeurIPS 2021 |
| Authors | Rishabh Agarwal, Max Schwarzer, Pablo Samuel Castro, Aaron C. Courville, Marc Bellemare |
| Official source | [NeurIPS proceedings](https://proceedings.neurips.cc/paper/2021/hash/f514cec81cb148559cf475e7426eed5-Abstract.html){:target="_blank" rel="noopener"} / [arXiv](https://arxiv.org/abs/2108.13264){:target="_blank" rel="noopener"} |
| Core topic | Statistical uncertainty, robust aggregate metrics, and reliable DRL benchmark evaluation |

## 한 줄 요약

이 논문은 DRL benchmark에서 mean이나 median 같은 point estimate만 보고하면 소수 seed와 benchmark variance 때문에 결론이 흔들린다고 비판하고, stratified bootstrap confidence interval, performance profile, interquartile mean, optimality gap, probability of improvement를 함께 쓰는 평가 체계를 제안한다.

## 전체 흐름

| Section | 핵심 내용 |
| --- | --- |
| Abstract / Introduction | DRL 논문은 보통 적은 run 수로 point estimate를 보고하지만, 이것은 statistical uncertainty를 숨긴다. Atari 100k case study에서 동일한 결과도 통계 분석 방식에 따라 다른 결론을 낳는다. |
| Formalism | \(M\)개 task와 \(N\)개 independent run에서 얻은 normalized score \(x_{m,n}\)를 population statistic의 sample estimate로 본다. |
| Uncertainty tools | Stratified bootstrap으로 task별 run 구조를 보존한 confidence interval을 만들고, score distribution을 performance profile로 시각화한다. |
| Robust metrics | Median은 robust하지만 sample efficiency가 낮고, mean은 outlier에 취약하다. 논문은 중간 50% score를 평균내는 interquartile mean(IQM)을 권장한다. |
| Case studies | Atari 100k, ALE, DeepMind Control Suite, Procgen benchmark를 다시 분석해 기존 ranking과 improvement claim이 confidence interval 안에서 흔들리는 사례를 보인다. |
| Tooling | 저자들은 같은 방법을 재사용할 수 있도록 Google Research의 `rliable` library와 Colab 예시를 제공한다. |

## 한국어 번역형 해설

논문의 문제의식은 DRL evaluation이 "평균 점수 하나"에 너무 많이 의존한다는 점이다. 강화학습은 seed, exploration, environment stochasticity, task selection에 민감하다. 그런데 benchmark 결과를 mean 또는 median 하나로 요약하면, 그 값이 얼마나 불확실한지 보이지 않는다. 저자들은 이를 "statistical precipice"라고 부른다. 작은 run 수와 높은 variance 위에서 성능 순위를 말하면, 결론이 낭떠러지 끝에 서 있는 것처럼 불안정하다는 의미다.

형식적으로 논문은 \(M\)개 task와 \(N\)개 run에서 얻은 normalized score를 \(x_{m,n}\)로 둔다. 목표는 단순히 sample mean을 계산하는 것이 아니라, underlying score distribution의 어떤 특성을 추정하는 것이다. 따라서 추정값에는 confidence interval이 붙어야 하며, task별 분포 차이를 보존하기 위해 stratified bootstrap을 사용한다. Atari 100k에서는 \(N=10\) 정도의 run에서도 median과 IQM에 대해 의미 있는 interval estimate가 가능하다고 분석한다.

Performance profile은 특정 threshold \(\tau\)를 넘는 score 비율을 보여준다.

$$
\hat{F}_X(\tau)=\frac{1}{M}\sum_{m=1}^{M}\frac{1}{N}\sum_{n=1}^{N}\mathbf{1}[x_{m,n}>\tau].
$$

이 곡선은 평균 점수 하나보다 많은 정보를 담는다. 예를 들어 어떤 알고리즘이 일부 게임에서만 매우 높은 outlier를 만들고 대부분의 게임에서는 약하다면, mean은 좋아 보일 수 있지만 performance profile은 score 구간별 약점을 드러낸다. 개별 outlier 하나가 profile 전체에 미치는 영향도 최대 \(1/(MN)\)로 제한된다.

논문이 권장하는 aggregate metric은 IQM이다. IQM은 하위 25%와 상위 25%를 제거하고 중간 50% score만 평균낸다. 그래서 mean보다 outlier에 덜 흔들리고, median보다 sample efficiency가 높다. 여기에 optimality gap은 threshold \(\gamma=1.0\) 같은 목표 성능까지 얼마나 부족한지를 보여주고, probability of improvement \(P(X>Y)\)는 알고리즘 \(X\)가 \(Y\)보다 나을 확률을 pairwise하게 해석하도록 돕는다.

Atari 100k case study는 이 주장을 구체화한다. 저자들은 26개 game에서 DER, OTR, DrQ, CURL, SPR 같은 알고리즘을 100개 independent run으로 평가하고, 3개부터 100개까지 run 수를 줄였을 때 결론이 어떻게 흔들리는지 본다. 기존 관행처럼 3, 5, 10개 seed만 쓰면 median이나 ranking이 크게 흔들릴 수 있고, 50개 run에서도 median uncertainty가 남는 경우가 있다. ALE, DeepMind Control Suite, Procgen 재분석에서도 confidence interval이 겹치거나, 기존 improvement claim이 50-70% 수준의 probability of improvement에 머무르는 사례가 나온다.

## Claim vs Interpretation

| 논문에서 직접 주장하는 내용 | 해석할 때의 주의점 |
| --- | --- |
| Point estimate만으로 DRL 성능을 비교하면 불확실성이 가려진다. | 평균이나 median을 쓰지 말라는 뜻이 아니라, interval estimate와 score distribution을 함께 보고해야 한다는 뜻이다. |
| IQM은 DRL benchmark의 aggregate metric으로 유용하다. | 모든 상황의 유일한 정답은 아니다. Task 실패율, safety constraint, worst-case 성능이 중요한 경우에는 다른 metric도 함께 봐야 한다. |
| `rliable`은 신뢰성 있는 benchmark 분석을 돕는다. | Library가 평가 설계를 대신해 주지는 않는다. 충분한 run 수, 공개된 raw scores, 일관된 normalization이 함께 필요하다. |

## 한계와 확장 방향

1. 제안한 통계 도구는 raw run score가 있어야 가장 잘 작동한다. 따라서 benchmark leaderboard는 평균값만 공개하지 말고 task별 seed score와 evaluation script를 함께 공개해야 한다.
2. Confidence interval은 uncertainty를 보여주지만, benchmark 자체의 task selection bias를 없애지는 못한다. 새로운 domain에서는 task suite 구성, normalization 기준, failure definition을 명확히 정해야 한다.
3. Robust metric도 잘못 사용하면 또 다른 단일 숫자 경쟁이 될 수 있다. 실무 적용에서는 IQM, performance profile, optimality gap, probability of improvement를 함께 보고하고, 중요 서비스에서는 worst-case와 safety metric을 별도로 유지해야 한다.

## 참고자료

- [Local source PDF](/assets/pdfs/research/drl-statistical-precipice/drl-statistical-precipice.pdf){:target="_blank" rel="noopener"}
- [NeurIPS proceedings](https://proceedings.neurips.cc/paper/2021/hash/f514cec81cb148559cf475e7426eed5-Abstract.html){:target="_blank" rel="noopener"}
- [arXiv:2108.13264](https://arxiv.org/abs/2108.13264){:target="_blank" rel="noopener"}
- [Project website](https://agarwl.github.io/rliable/){:target="_blank" rel="noopener"}
- [rliable GitHub repository](https://github.com/google-research/rliable){:target="_blank" rel="noopener"}
