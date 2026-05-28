---
layout: default
title: "User Performance in Consecutive Temporal Pointing"
topic: Research
order: 9
---

# User Performance in Consecutive Temporal Pointing: An Exploratory Study

## 논문 정보

| 항목 | 내용 |
| --- | --- |
| 제목 | User Performance in Consecutive Temporal Pointing: An Exploratory Study |
| 저자 | Dawon Lee, Sunjun Kim, Junyong Noh, Byungjoo Lee |
| 학회 | CHI '24 |
| 주제 | Consecutive Temporal Pointing, Temporal Pointing, Button Input Performance |
| DOI | [10.1145/3613904.3642904](https://doi.org/10.1145/3613904.3642904) |

## 한 줄 요약

Consecutive Temporal Pointing(CTP)은 두 번의 일반 temporal pointing을 단순히 이어 붙인 과제가 아니며, 특히 두 번째 입력은 입력 간격인 TTS, 버튼 활성화 방식, 사용자의 운동 제약에 의해 별도의 성능 패턴을 보인다.

## 문제의식

Temporal pointing은 사용자가 특정 공간 위치가 아니라 특정 시점에 버튼 입력을 맞추는 과제다. 리듬 게임의 노트 입력, 움직이는 표적이 판정선에 닿는 순간의 클릭, 시간 제한이 있는 버튼 입력이 여기에 속한다.

이 논문은 한 번의 temporal pointing이 아니라, 짧은 시간 간격 안에서 두 번의 입력을 하나의 덩어리처럼 수행해야 하는 Consecutive Temporal Pointing을 다룬다. 예시는 다음과 같다.

- 더블 클릭처럼 첫 번째 입력 뒤 일정 시간 안에 두 번째 입력을 해야 하는 경우
- 슈팅 게임의 차지 공격처럼 누르기와 떼기의 타이밍이 모두 의미를 갖는 경우
- 리듬 게임의 롱 노트처럼 시작 시점과 끝 시점을 모두 맞춰야 하는 경우

핵심 질문은 명확하다. CTP를 두 번의 ordinary temporal pointing으로 분해해서 설명할 수 있는가?

## 핵심 개념

### TTF와 TTS

논문은 CTP를 두 시간 변수로 정리한다.

| 변수 | 의미 |
| --- | --- |
| TTF(Time-to-First-Input) | 과제가 시작된 뒤 첫 번째 입력 목표 시점까지의 시간 |
| TTS(Time-to-Second-Input) | 첫 번째 입력 목표 시점에서 두 번째 입력 목표 시점까지의 시간 |

두 입력의 실제 타이밍 분포는 각각 정규분포로 표현된다.

$$
N_1(\mu_1,\sigma_1^2),\quad N_2(\mu_2,\sigma_2^2)
$$

여기서 $$\mu$$는 목표 시점 대비 평균 오차, 즉 정확도에 가깝고, $$\sigma$$는 입력 타이밍의 퍼짐, 즉 정밀도에 가깝다. CTP에서는 첫 번째 입력과 두 번째 입력을 따로 보아야 하므로 $$\mu_1,\mu_2,\sigma_1,\sigma_2$$가 모두 분석 대상이 된다.

### CTP의 두 유형

| 유형 | 설명 | 예시 |
| --- | --- | --- |
| Type I CTP | 첫 번째 입력은 사용자가 시작하고, 두 번째 입력에 시간 조건이 부여됨 | 더블 클릭, 차지 공격의 release 타이밍 |
| Type II CTP | 첫 번째 입력과 두 번째 입력 모두 외부 목표 시점에 맞춰야 함 | 리듬 게임의 롱 노트 |

논문 관점에서 중요한 점은 Type I과 Type II 모두 두 번째 입력이 단순한 반복 입력이 아니라, 첫 번째 입력과의 관계 안에서 계획된다는 것이다.

## 기존 Temporal Pointing 모델

기존 temporal pointing 연구는 사용자의 입력 타이밍 정밀도 $$\sigma$$가 주로 다음 요인에 의해 달라진다고 본다.

첫째, 입력 주기 $$P$$가 길수록 내부 시계의 불확실성이 커진다.

$$
\sigma = c_1P
$$

둘째, 움직이는 표적을 관찰할 수 있는 시간 $$t_c$$가 길수록 표적 움직임을 더 잘 예측할 수 있다.

$$
\sigma = c_2 + \frac{1}{e^{c_3t_c}-1}
$$

Moving-target acquisition 모델은 이 두 단서를 결합하여 다음과 같이 temporal pointing 성능을 예측한다.

$$
\sigma =
\frac{
c_1P\left(c_2+\frac{1}{e^{c_3t_c}-1}\right)
}{
\sqrt{
(c_1P)^2+
\left(c_2+\frac{1}{e^{c_3t_c}-1}\right)^2
}
}
$$

논문은 이 모델을 CTP에 적용해 본다. 만약 CTP가 정말로 두 번의 일반 temporal pointing이라면, 첫 번째 입력과 두 번째 입력 모두 이 모델의 예측 흐름을 따라야 한다.

## 연구 질문

| 구분 | 질문 |
| --- | --- |
| RQ1 | CTP의 첫 번째 입력과 두 번째 입력을 각각 ordinary temporal pointing으로 볼 수 있는가? |
| RQ2 | 버튼 활성화 지점, 시각 단서, 입력 간격 등 기존 temporal pointing의 주요 요인이 CTP에서는 어떻게 작동하는가? |

## 실험 설계

논문은 총 100명의 참가자를 대상으로 세 가지 CTP 변형을 실험했다. 모든 과제는 움직이는 선이 판정선에 닿는 시점에 버튼 입력을 맞추는 moving-target acquisition 형태로 구성되었다.

| 변형 | 유형 | 주요 조건 | 참가자 |
| --- | --- | --- | --- |
| Variation 1 | Type I CTP | TTS, Visual Cue Presence, Input Method | 25명 |
| Variation 2 | Type II CTP | TTF, TTS, Input Period, Visual Cue Presence, Input Method | 43명 |
| Variation 3.1 | Type I CTP, 양손 입력 | TTS, Visual Cue Presence, Input Order | 16명 |
| Variation 3.2 | Type II CTP, 양손 입력 | TTF, TTS, Visual Cue Presence, Input Order | 16명 |

입력 방식은 두 가지로 비교된다.

| 방식 | 의미 |
| --- | --- |
| Press-Press | 첫 번째 입력과 두 번째 입력 모두 keyPressed로 활성화 |
| Press-Release | 첫 번째 입력은 keyPressed, 두 번째 입력은 keyReleased로 활성화 |

참가자는 조건당 50회 시행했고, 학습 효과를 고려해 마지막 40회가 분석에 사용되었다. 전체 109,090회 시행 중 약 2.43%는 허용 범위를 벗어난 입력으로 처리되어 다시 수행되었다.

## 결과 분석

### 1. 첫 번째 입력은 기존 모델과 비교적 잘 맞는다

Variation 2에서 첫 번째 입력의 표준편차 $$\sigma_1$$은 기존 temporal pointing 모델로 잘 설명되었다. 논문은 이 경우 $$R^2 = 0.93$$의 높은 적합도를 보고한다.

이 결과는 첫 번째 입력이 일반 temporal pointing과 유사한 구조를 가질 수 있음을 보여준다. 즉, 목표가 나타나고 사용자가 첫 번째 판정 시점을 예측하는 과정은 기존 모델의 cue-viewing time 기반 설명과 크게 충돌하지 않는다.

### 2. 두 번째 입력은 기존 모델로 설명되지 않는다

논문의 핵심 결과는 두 번째 입력의 표준편차 $$\sigma_2$$에서 나온다. 기존 모델이 맞다면, 관찰 시간이 늘어날수록 $$\sigma$$는 줄어들어야 한다. 그러나 CTP의 두 번째 입력에서는 $$\sigma_2$$가 그런 방식으로 움직이지 않았다.

논문은 이를 CTP가 단순한 temporal pointing 두 개의 연결이 아니라는 근거로 제시한다. 두 번째 입력은 시각적 표적 단서만 보고 계획되는 것이 아니라, 첫 번째 입력과 두 번째 입력 사이의 시간 간격인 TTS를 별도의 감각 단서처럼 활용하는 것으로 해석된다.

### 3. TTS는 두 번째 입력의 독립적인 단서가 된다

논문 해석에 따르면 사용자는 두 번째 입력을 계획할 때 전체 입력 주기 $$P$$보다 짧은 TTS를 활용할 수 있다. 내부 시계의 관점에서 더 짧은 시간 간격은 더 정밀하게 부호화될 수 있으므로, TTS는 두 번째 입력을 위한 강한 단서가 된다.

다만 TTS가 충분히 길어지면 이 단서의 신뢰도가 낮아지고, 사용자는 다시 움직이는 표적의 시각 단서에 더 의존하는 것으로 해석된다. 논문은 약 300 ms 이후부터 이런 전환 가능성을 논의한다.

### 4. Press-Press는 정밀하지만 짧은 간격에서는 운동 제약을 만든다

기존 연구처럼 이 논문에서도 keyPressed 기반 입력은 keyReleased 기반 입력보다 더 높은 시간 정밀도를 보인다. Variation 1과 2에서 Press-Press 조건의 $$\sigma_2$$는 Press-Release 조건보다 작았다. 논문은 Press-Press의 $$\sigma_2$$가 Press-Release 대비 Variation 1에서는 82.8%, Variation 2에서는 93.7% 수준이라고 보고한다.

하지만 Press-Press가 항상 좋은 것은 아니다. 두 번의 press를 만들려면 손가락이 Down-Up-Down 움직임을 수행해야 한다. TTS가 150 ms 미만처럼 매우 짧아지면 이 추가 움직임이 운동 제약으로 작동하여 두 번째 입력이 뒤로 밀릴 수 있다.

반대로 Press-Release는 Down-Up 한 번으로 두 입력을 만들 수 있기 때문에, 매우 짧은 간격에서는 운동 제약을 줄이는 방식이 될 수 있다.

### 5. 양손 조건에서는 입력 순서 효과가 뚜렷하지 않았다

Variation 3은 두 손을 번갈아 사용하는 조건을 포함한다. 논문은 dominant hand에서 non-dominant hand로 가는 순서와 그 반대 순서 사이의 유의미한 차이를 찾지 못했다고 보고한다.

이는 CTP가 순수한 리듬 과제와 다르기 때문으로 해석된다. CTP에서는 움직이는 표적이 보이고, 입력 간격도 전형적인 리듬 동기화 과제보다 짧다. 따라서 손 우세성보다 시각 단서, TTS, 과제 구조의 영향이 더 크게 나타났을 가능성이 있다.

## 해석 포인트

### CTP는 관계적 타이밍 과제다

논문의 가장 중요한 기여는 CTP를 두 번의 독립 입력으로 보지 않고, 두 입력 사이의 관계를 포함한 과제로 다룬다는 점이다. 두 번째 입력은 첫 번째 입력 이후의 상대적 시간 간격을 이용해 계획된다. 따라서 모델에도 TTS 기반 단서가 독립적으로 들어가야 한다.

### 게임 난이도 설계에서 TTS는 단순한 여유 시간이 아니다

TTS가 길면 무조건 쉬워진다고 보기 어렵다. 짧은 TTS는 운동적으로 어렵지만, 내부 시계 단서로는 정밀할 수 있다. 반대로 긴 TTS는 운동적으로는 여유가 있지만, 간격 부호화의 신뢰도가 낮아질 수 있다. 게임의 콤보, 차지 공격, 롱 노트 난이도를 설계할 때 이 차이를 분리해서 봐야 한다.

### 버튼 이벤트는 press와 release를 기능적으로 구분해야 한다

일반적으로 press 이벤트는 더 높은 정밀도를 줄 수 있지만, 매우 짧은 연속 입력에서는 release 이벤트가 더 자연스러운 운동 경로를 제공할 수 있다. 특히 150 ms 미만의 연속 입력을 자주 요구하는 인터랙션이라면 Press-Release 구조가 더 적합할 수 있다.

### 후속 모델은 평균 오차도 설명해야 한다

기존 temporal pointing 모델은 주로 $$\sigma$$, 즉 정밀도 예측에 초점을 맞춘다. 그러나 CTP에서는 두 번째 입력이 밀리거나, 첫 번째 입력이 이를 보상하기 위해 앞당겨지는 평균 오차 $$\mu$$의 변화도 중요하다. 후속 모델은 내부 시계, 운동 지연, 보상 구조를 함께 고려해야 한다.

## 한계

이 논문은 CTP 연구의 출발점에 가깝다. 실험 과제는 1차원 등속 이동 표적으로 제한되어 있고, 실제 게임이나 인터랙션의 복잡한 표적 움직임을 모두 반영하지는 않는다. 참가자도 주로 젊은 대학생이며, 일반 temporal pointing 성능을 개인별 baseline으로 측정하지 않았다.

따라서 이 결과를 모든 연속 입력 인터랙션에 그대로 일반화하기보다는, CTP가 기존 temporal pointing과 다른 구조를 가진다는 근거로 읽는 편이 적절하다.

## PDF 및 참고자료

- [PDF 원문](/assets/pdfs/research/user-performance-in-consecutive-temporal-pointing/user-performance-in-consecutive-temporal-pointing.pdf)
- [ACM DOI](https://doi.org/10.1145/3613904.3642904)
