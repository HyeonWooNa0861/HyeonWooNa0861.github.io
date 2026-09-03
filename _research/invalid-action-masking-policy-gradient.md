---
layout: default
date: 2026-08-13 09:45:28 +0900
title: "Invalid Action Masking"
topic: "Policy gradient with invalid action masking"
order: 59
major_topic: "Reinforcement Learning"
keywords:
  - "Invalid action masking"
  - "Policy gradient"
  - "Action spaces"
  - "Sampling efficiency"
---

# A Closer Look at Invalid Action Masking in Policy Gradient Algorithms

Source PDF: `invalid-action-masking-policy-gradient.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | A Closer Look at Invalid Action Masking in Policy Gradient Algorithms |
| 출처 | FLAIRS Conference, 2022 |
| 주제 | Policy gradient with invalid action masking |
| 핵심 방법 | Theoretical and empirical analysis of masking invalid actions |

## 한 줄 요약

이 논문은 action space가 크고 상태마다 유효 action이 다른 환경에서 invalid action masking이 policy gradient 학습에 어떤 영향을 주는지 분석한다.

## 핵심 내용

상태마다 유효 action이 다른 큰 discrete action space에서는 agent가 실행 불가능한 선택을 반복해 exploration budget을 낭비한다. Invalid action에 penalty를 주는 방식은 유효 action 비율이 작아질수록 학습 신호가 희박해지므로, 이 논문은 sampling 전에 invalid logit을 mask하는 방법을 policy-gradient 관점에서 분석한다.

상태 의존적 mask를 differentiable transformation으로 보면 masking된 distribution에서도 타당한 policy-gradient update를 구성할 수 있다. µRTS 실험은 invalid action 비율이 커질수록 masking이 penalty 방식보다 잘 확장됨을 보여주며, 구현 편의로 보이던 기법에 이론적 해석과 대규모 action-space 설계 근거를 제공한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---:|---|---|
| 1 | Invalid actions | 왜 큰 discrete action space에서 문제가 심해지는가? |
| 2 | Masking | logit masking은 policy distribution을 어떻게 바꾸는가? |
| 3 | Gradient | masking된 policy gradient는 어떤 조건에서 타당한가? |
| 4 | Empirical effect | invalid action 비율이 커질수록 성능이 어떻게 달라지는가? |

## 한국어 번역형 해설

### 초록과 문제의식

큰 discrete action space를 가진 게임과 조합 의사결정 환경에서는 전체 action 중 현재 상태에서 실행 가능한 action이 일부뿐이다. Invalid action을 그대로 sampling하게 두면 agent는 보상을 얻기 전에 불가능한 action을 반복하고, penalty만으로 이를 교정하려 하면 action space가 커질수록 exploration budget이 빠르게 낭비된다.

논문은 invalid action masking을 단순 구현 요령이 아니라 policy gradient 관점에서 분석한다. 저자들의 주장은 두 가지다. 첫째, invalid action masking은 상태에 따라 logit을 바꾸는 state-dependent differentiable function으로 볼 수 있으므로 valid policy gradient update를 만든다. 둘째, invalid action 수가 커질수록 penalty 방식보다 masking 방식이 경험적으로 훨씬 잘 scale된다.

### 방법: logit masking과 gradient 해석

논문은 policy network가 action logits를 출력하고 softmax를 통해 확률분포를 만든다고 가정한다. 어떤 상태 \(s\)에서 action \(a_2\)가 invalid라면, 해당 logit을 매우 큰 음수 \(M\)으로 바꾼다. 예시 값은 \(M=-1\times10^8\)이다. 그러면 softmax 이후 invalid action의 확률은 사실상 0이 되고, valid action들에만 확률질량이 재분배된다.

중요한 점은 이 조작이 sampling만 바꾸는 것이 아니라 gradient도 바꾼다는 것이다. Masked logit은 상수 함수처럼 취급되므로, invalid action에 대응하는 logit gradient가 0이 된다. 논문의 Proposition 1은 이 masking 과정이 각 logit에 대해 identity function 또는 constant function을 적용하는 미분 가능한 함수이며, 따라서 masking된 정책 \(\pi'_\theta\)에 대한 policy gradient로 해석할 수 있음을 보인다.

저자들이 별도로 비교한 naive masking은 이 지점을 의도적으로 어긴다. Action sampling에는 mask를 적용하지만, gradient update는 원래 unmasked probability로 계산한다. 이 경우 invalid action이 sampling되지 않는 장점은 유지되지만, PPO update의 target policy와 current policy 사이 KL divergence가 커져 학습 안정성이 악화된다.

### 실험 설정: µRTS와 invalid action 비율

실험 환경은 µRTS다. Observation은 \(h\times w\) map 위의 27개 binary feature plane으로 구성되고, action은 8개 discrete component를 가진 vector다. 첫 component는 Source Unit, 마지막 component는 Attack Target Unit이며, 두 component의 range가 map 크기에 따라 \(h\times w\)로 커진다.

이 구조 때문에 map이 커질수록 invalid action 문제가 급격히 심해진다. 예를 들어 Source Unit으로 선택 가능한 유닛이 base와 worker 두 개뿐인 상황에서 Source Unit 범위는 4×4 map의 16에서 24×24 map의 576으로 증가한다. 무작위로 valid Source Unit을 고를 확률은 4×4에서는 \(2/16=0.125\), 24×24에서는 \(2/576=0.0034\)에 불과하다.

비교 대상은 네 가지다. Invalid action penalty는 invalid action마다 \(r_{\mathrm{invalid}}\in\{0,-0.01,-0.1,-1\}\)을 부여한다. Invalid action masking은 Source Unit과 Attack Target Unit에 mask를 적용한다. Naive masking은 sampling에만 mask를 쓰고 gradient에는 쓰지 않는다. Masking removed는 mask로 학습한 뒤 평가 시 mask를 제거해 얼마나 행동이 유지되는지 본다.

### 결과 해석

결과는 masking의 scalability를 분명히 보여준다. Invalid action masking은 4×4, 10×10, 16×16, 24×24 map 모두에서 \(r_{\mathrm{episode}}=40.00\)을 달성하고, 첫 positive reward를 찾는 시간 \(t_{\mathrm{first}}\)도 전체 training time의 약 0.05%에서 0.08% 수준으로 낮다. \(t_{\mathrm{solve}}\)도 8.67%에서 18.38% 범위에 머문다.

Penalty 방식은 작은 4×4 map에서는 동작할 수 있지만, 10×10 이상에서는 reward가 거의 0에 머무는 경우가 많다. 논문은 10×10 map에서 penalty agent가 첫 reward를 찾는 데 training time의 몇 %를 소비하는 반면, masking agent는 모든 map에서 약 0.06% 수준으로 첫 reward를 찾는다고 해석한다. 이는 invalid action을 penalty로 "배우게" 하는 전략이 큰 action space에서는 보상 발견 자체를 지연시킨다는 뜻이다.

Naive masking은 일부 map에서 높은 episode reward를 보이지만, 논문이 강조하는 문제는 안정성이다. PPO의 KL divergence가 다른 설정보다 크게 증가하고, 24×24 map에서는 \(t_{\mathrm{solve}}=49.14\%\)까지 늘어난다. Masking removed 설정은 mask가 사라져도 어느 정도 useful behavior를 유지하지만, map이 커질수록 invalid Source Unit 선택이 증가하고 episode reward도 17점대로 낮아진다.

### 한계와 확장 방향

논문의 결론은 "masking은 항상 안전하다"가 아니다. Mask가 잘못 계산되면 valid action을 잘못 제거할 수 있고, agent는 그 action을 학습할 기회를 잃는다. 또한 실험은 Source Unit과 Attack Target Unit mask만 제공하며, action type별 parameter까지 완전하게 masking하지 않는다. 결과는 µRTS의 harvest task와 4 random seed 평균에 기반하므로, 모든 조합적 action 환경으로 바로 일반화하기에는 추가 검증이 필요하다.

실무 확장 방향은 mask 생성기를 별도의 검증 대상로 두는 것이다. Rule-based mask라면 unit test와 environment consistency check가 필요하고, learned feasibility model을 쓴다면 uncertainty가 큰 action을 완전히 제거하기보다 penalty, fallback sampling, safety shield와 결합하는 편이 안전하다. 연구자의 해석으로는, invalid action masking은 reward shaping이 아니라 action feasibility constraint를 policy distribution에 반영하는 기법으로 읽어야 한다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/invalid-action-masking-policy-gradient/invalid-action-masking-policy-gradient.pdf" | relative_url }}" target="_blank" rel="noopener">invalid-action-masking-policy-gradient.pdf</a></li>
  <li><a href="https://doi.org/10.32473/flairs.v35i.130584" target="_blank" rel="noopener">DOI: 10.32473/flairs.v35i.130584</a></li>
</ul>
