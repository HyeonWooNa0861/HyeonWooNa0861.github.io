---
layout: default
title: "QECO-Adapt"
topic: "Load-adaptive task offloading in dense MEC"
order: 1
---

# QECO-Adapt

## 연구 개요

QECO-Adapt는 dense Mobile Edge Computing(MEC) 환경에서 기존 QECO 기반 task offloading 방식의 초기 수렴 손실과 dropped-task 누적 문제를 줄이기 위한 부하 적응형 보완 알고리즘이다. 기존 QECO의 D3QN/LSTM 구조와 action space를 유지하면서, effective load 기반 adaptive energy weight와 offloading gating을 결합해 edge에 사용자 부하가 집중되는 상황을 다룬다.

이 연구는 QECO를 완전히 대체하는 새 구조를 제안하기보다, QECO가 강점을 가진 QoE 중심 offloading 흐름 위에 dense-load-aware control layer를 추가하는 방향으로 접근한다. 따라서 핵심 질문은 “기존 QECO 구조를 크게 바꾸지 않고도, 단일 edge dense stress 조건에서 warm-up 손실을 줄일 수 있는가?”로 정리할 수 있다.

## 문제 인식

MEC 환경에서 모바일 디바이스는 연산을 로컬에서 처리하거나 edge node로 offloading할 수 있다. 그러나 사용자가 특정 edge에 집중되면 edge backlog, transmission delay, deadline miss가 커질 수 있고, 학습 초기 구간에서는 불리한 offloading action이 누적되어 QoE가 낮아질 수 있다.

QECO-Adapt는 이 문제를 단일 edge stress test로 관찰한다. 원문 QECO의 edge당 사용자 밀도 10 MDs/EN을 기준으로 삼고, 사용자 수를 10, 30, 50, 80으로 늘려 1x, 3x, 5x, 8x 조건을 구성한다. 이를 통해 저부하 조건과 dense 조건에서 알고리즘이 어떻게 달라지는지 비교한다.

## 방법

첫 번째 핵심 요소는 effective load이다. effective load는 사용자 수, 평균 task arrival profile, 평균 사용자 활동성, edge 수를 반영해 edge 하나가 감당해야 하는 task pressure를 단순화한 값이다.

$$
L_{\mathrm{eff}} = \frac{N\bar{b}\bar{a}}{M}
$$

두 번째 요소는 gating strength이다. 부하가 커질수록 offloading action을 더 보수적으로 검토하도록 effective load를 control strength로 변환한다.

$$
g(L_{\mathrm{eff}})
= \frac{L_{\mathrm{eff}}}{L_{\mathrm{eff}} + M\lambda}
$$

세 번째 요소는 adaptive energy weight이다. 기존 QECO reward의 energy cost 항에 부하 기반 가중치를 적용해 dense 환경에서 energy-aware behavior를 강화한다.

$$
w_E = w_0\left(1+g(L_{\mathrm{eff}})\right)^{\rho}
$$

이 방식은 policy-invariant reward shaping이 아니다. energy cost의 상대 가중치를 바꾸고, gating 조건에 따라 실제 offloading action을 local action으로 바꿀 수 있기 때문이다. 따라서 QECO-Adapt는 기존 QECO의 최적 정책을 보존한다고 주장하기보다, dense load 조건에 맞춘 load-adaptive reward/cost reweighting과 action-level gating으로 보는 것이 정확하다.

## 실험 결과 요약

전체 400 episode 평균 기준으로, QECO-Adapt는 1x 저부하 조건에서는 QECO보다 불리한 지표가 있었지만, 3x 이상 dense 조건에서는 주요 지표가 개선되는 경향을 보였다.

| Users | Density | QoE | Delay | Energy | Dropped tasks | Runtime |
|---:|---:|---:|---:|---:|---:|---:|
| 10 | 1x | -9.13% | -3.65% | +7.83% | -32.85% | -5.07% |
| 30 | 3x | +10.97% | +1.30% | +5.37% | +5.88% | +3.12% |
| 50 | 5x | +41.45% | +1.87% | +12.25% | +10.25% | -10.98% |
| 80 | 8x | +89.51% | +1.72% | +18.29% | +11.17% | -10.83% |

이 표에서 `+`는 개선, `-`는 손실을 의미한다. 특히 5x와 8x에서는 QoE 개선폭이 크게 나타났고, 이는 QECO-Adapt가 dense 조건에서 초기 warm-up 손실과 dropped-task 누적을 줄이는 데 효과가 있음을 시사한다.

## 한계와 확장 방향

현재 결과는 단일 edge stress setup과 제한된 seed 조건에서 얻은 결과이므로, multi-edge 환경과 다중 seed 실험을 통해 일반성을 더 검증할 필요가 있다. 또한 final-window 성능뿐 아니라 목표 QoE 도달 episode, dropped-task 안정화 시점, runtime overhead 같은 직접 수렴 지표를 추가하면 알고리즘의 장단점을 더 명확히 설명할 수 있다.

따라서 QECO-Adapt의 의미는 “모든 MEC 환경에서 QECO를 대체하는 범용 알고리즘”이 아니라, 단일 edge에 부하가 집중되는 dense 조건에서 QECO의 초기 손실을 줄이는 lightweight adaptive variant로 정리하는 것이 적절하다.

## 핵심 내용

QECO-Adapt 자료는 외부 논문 번역본이 아니라 자체 연구 정리 자료이므로, 이 절은 전체 내용을 다시 읽기 위한 본문 해설로 둔다. 핵심은 dense Mobile Edge Computing 환경에서 기존 QECO의 구조를 크게 바꾸지 않고 초기 수렴 손실과 dropped-task 누적을 줄일 수 있는지를 검토하는 것이다.

문제 상황은 edge node에 사용자가 몰릴 때 발생한다. 모바일 디바이스가 task를 edge로 offloading하면 로컬 연산 부담은 줄어들 수 있지만, edge backlog와 transmission delay가 커지면 deadline miss와 dropped task가 증가한다. 특히 학습 초기에는 policy가 안정되지 않아 불리한 offloading action이 누적될 수 있다.

QECO-Adapt는 기존 QECO의 D3QN/LSTM 구조와 action space를 유지하면서 dense-load-aware control layer를 더한다. Effective load는 사용자 수, 평균 task arrival, 활동성, edge 수를 반영해 edge 하나가 받는 task pressure를 나타낸다. 이 값은 gating strength와 adaptive energy weight를 계산하는 기준이 된다.

Gating은 부하가 높을 때 offloading action을 더 보수적으로 검토하게 만들고, adaptive energy weight는 dense 조건에서 energy-aware behavior를 강화한다. 이 변화는 policy-invariant reward shaping이 아니므로, 기존 QECO의 최적 정책을 보존한다고 주장하기보다 dense 환경에 맞춘 reward/cost reweighting과 action-level gating으로 보는 것이 정확하다.

실험 결과는 저부하 1x 조건에서는 QECO-Adapt가 일부 손실을 보일 수 있지만, 3x 이상 dense 조건에서는 QoE, delay, energy, dropped task 측면에서 개선되는 경향을 보인다. 따라서 이 연구의 의미는 범용 대체 알고리즘이라기보다, 단일 edge dense stress 조건에서 QECO의 warm-up 손실과 dropped-task 누적을 줄이는 lightweight adaptive variant로 정리된다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/qeco-adapt/qeco-adapt-research.pdf" | relative_url }}" target="_blank" rel="noopener">QECO-Adapt 연구 PDF</a></li>
  <li><a href="{{ "/posts/2026-kiit-summer-conference-qeco-adapt/" | relative_url }}">QECO-Adapt Conference Preparation Notes</a></li>
  <li><a href="https://www.together.ai/blog/minions" target="_blank" rel="noopener">Together AI Blog: Minions</a> - local small model과 cloud frontier model의 역할 분담을 통해 edge/cloud split framing을 확장할 때 참고할 자료</li>
</ul>
