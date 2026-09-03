---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "DRL That Matters"
topic: "Reproducibility and statistical reporting in deep reinforcement learning"
order: 51
major_topic: "Safe & Reliable Reinforcement Learning"
keywords:
  - "DRL reproducibility"
  - "Statistical reporting"
  - "Benchmarking"
  - "Random seeds"
---

# Deep Reinforcement Learning that Matters

Source PDF: `deep-reinforcement-learning-that-matters.pdf`

## Paper Information

| Field | Detail |
| --- | --- |
| Original title | Deep Reinforcement Learning that Matters |
| Venue | AAAI 2018 |
| Authors | Peter Henderson, Riashat Islam, Philip Bachman, Joelle Pineau, Doina Precup, David Meger |
| Official source | [AAAI proceedings](https://ojs.aaai.org/index.php/AAAI/article/view/11694){:target="_blank" rel="noopener"} / [DOI](https://doi.org/10.1609/aaai.v32i1.11694){:target="_blank" rel="noopener"} |
| Core topic | Reproducibility, variance, and reporting standards in DRL experiments |

## 한 줄 요약

이 논문은 새로운 DRL 알고리즘을 제안하기보다, random seed, hyperparameter, network architecture, environment, codebase, evaluation metric만 바뀌어도 DRL 성능 결론이 흔들릴 수 있음을 실험으로 보이고, 재현 가능한 연구를 위한 보고 기준을 제안한다.

## 핵심 내용

| Section | 핵심 내용 |
| --- | --- |
| Abstract / Introduction | DRL은 non-determinism과 높은 variance 때문에 작은 성능 차이를 실제 개선으로 해석하기 어렵다. 그런데 당시 연구 관행은 significance test와 실험 보고 기준이 부족했다. |
| Technical background | TRPO, DDPG, PPO, ACKTR 등 policy-gradient 계열 알고리즘과 MuJoCo 기반 continuous control 환경을 대상으로 비교한다. |
| Experimental analysis | random seed, hyperparameter search, network architecture, reward scale, environment choice, codebase 차이가 성능 결론에 미치는 영향을 분리해 확인한다. |
| Evaluation metrics | 최고 성능만 보고하는 방식, 소수 seed 평균, baseline 구현 차이로 인한 과대 해석을 비판하고, confidence interval, bootstrap, significance test, power analysis를 권장한다. |
| Recommendations | hyperparameter와 implementation detail을 공개하고, baseline은 원 논문 수준으로 튜닝하며, 충분한 seed와 통계 검정을 함께 보고해야 한다고 정리한다. |

## 한국어 번역형 해설

논문의 출발점은 "강화학습 알고리즘 A가 B보다 좋다"는 문장이 실험 설계에 얼마나 민감한가이다. DRL은 정책 학습이 stochastic하고, 환경 초기화와 exploration이 결과에 영향을 주며, 하나의 실험 실행 비용도 크다. 그래서 작은 seed 수로 평균 return을 보고하면 우연한 분산을 알고리즘 개선으로 오해할 수 있다.

저자들은 TRPO, DDPG, PPO, ACKTR을 중심으로 OpenAI Gym MuJoCo 환경인 Hopper-v1, HalfCheetah-v1, Swimmer, Walker2d 등을 사용한다. 대부분의 실험은 OpenAI Baselines를 기준으로 하되, codebase 비교에서는 원래 TRPO 구현, rllab TensorFlow, rllab Theano, rllabplusplus 같은 구현 차이도 다룬다. 이 선택은 논문의 핵심 메시지와 연결된다. 논문이 묻는 것은 "어떤 알고리즘이 가장 강한가"가 아니라 "같은 알고리즘이라고 부르는 구현과 설정이 정말 같은 비교 단위인가"이다.

random seed 실험은 특히 직접적이다. 같은 hyperparameter 설정에서 10개 trial을 두 묶음의 5개 seed로 나누었을 때, HalfCheetah에서 TRPO는 두 묶음 사이에 $$t=-9.0916$$, $$p=0.0016$$ 수준의 차이를 보였다. 이 값은 단순히 seed를 다르게 뽑은 것만으로도 통계적으로 유의한 차이가 나타날 수 있음을 의미한다. 따라서 3개나 5개 seed 평균만으로 새로운 알고리즘의 우월성을 주장하는 것은 약하다.

network architecture와 activation도 결과를 바꾼다. 논문은 MLP hidden layer 구성을 $$(64,64)$$, $$(100,50,25)$$, $$(400,300)$$ 등으로 바꾸고, tanh, ReLU, Leaky ReLU를 비교한다. 이 변화는 같은 알고리즘 이름 아래에서도 학습 안정성과 최종 return을 달라지게 한다. DDPG의 경우 HalfCheetah처럼 상대적으로 안정적인 환경에서는 좋은 결과를 보일 수 있지만, Hopper처럼 균형을 잃으면 episode가 끝나는 환경에서는 성능 차이가 다르게 나타난다.

평가 지표에 대한 비판도 중요하다. 최고 return만 고르면 trial 수가 많은 쪽이 유리하고, 평균 return만 보면 outlier나 실패 run을 가릴 수 있다. Walker2d에서 ACKTR과 DDPG를 비교한 예시는 $$t=1.03$$, $$p=0.334$$, KS statistic $$=0.40$$, $$p=0.697$$처럼 단순 평균 차이를 유의한 개선으로 보기 어렵다는 점을 보여준다. bootstrap percent difference도 44.47%였지만 confidence interval은 $$[-80.62\%, 111.72\%]$$로 매우 넓었다.

## Claim vs Interpretation

| 논문에서 직접 주장하는 내용 | 해석할 때의 주의점 |
| --- | --- |
| DRL 결과는 random seed와 implementation detail에 크게 흔들린다. | "DRL이 무의미하다"는 뜻이 아니라, 실험 설계와 보고 기준 없이는 개선 주장의 신뢰도가 낮다는 뜻이다. |
| baseline은 충분히 튜닝되어야 한다. | 새 알고리즘만 세밀하게 튜닝하고 baseline은 기본값으로 두면 비교가 불공정해진다. |
| significance test와 confidence interval이 필요하다. | 통계 검정만으로 모든 재현성 문제가 해결되지는 않는다. 코드, seed, environment version, hyperparameter 공개가 함께 필요하다. |

## 한계와 확장 방향

1. 실험 범위는 당시의 MuJoCo continuous control과 policy-gradient 계열에 집중되어 있다. 현대 benchmark에서는 offline RL, model-based RL, large-scale simulator, pixel-based control까지 포함해 같은 재현성 기준을 확장해야 한다.
2. 논문은 평가 원칙을 제시하지만, 하나의 표준 metric을 완전히 고정하지는 않는다. 이후 연구에서는 interquartile mean, stratified bootstrap CI, probability of improvement처럼 더 robust한 집계 지표를 결합해 사용할 수 있다.
3. codebase 차이를 줄이려면 단순히 코드를 공개하는 것을 넘어, dependency version, environment wrapper, preprocessing, evaluation protocol, trained checkpoint까지 재사용 가능한 형태로 공개해야 한다.

## 참고자료

- [Local source PDF](/assets/pdfs/research/deep-reinforcement-learning-that-matters/deep-reinforcement-learning-that-matters.pdf){:target="_blank" rel="noopener"}
- [AAAI proceedings](https://ojs.aaai.org/index.php/AAAI/article/view/11694){:target="_blank" rel="noopener"}
- [DOI](https://doi.org/10.1609/aaai.v32i1.11694){:target="_blank" rel="noopener"}
