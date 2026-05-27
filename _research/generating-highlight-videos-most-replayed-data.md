---
layout: default
title: "Generating Highlight Videos with Most Replayed Data"
topic: "User-specified length highlight generation using Most Replayed Data"
order: 8
---

# Generating Highlight Videos of a User-Specified Length using Most Replayed Data

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Generating Highlight Videos of a User-Specified Length using Most Replayed Data |
| 저자 | Minsun Kim, Dawon Lee, Junyong Noh |
| 학회 | CHI 2025, Yokohama, Japan |
| DOI | `10.1145/3706598.3713880` |
| 키워드 | Highlight Generation, Video Summarization, Video Editing, Image Processing, Most Replayed Data |
| 프로젝트 페이지 | `https://w-dlee.github.io/highlights` |

## 한 줄 요약

이 논문은 YouTube의 Most Replayed Data를 시청자 관심도 신호로 사용해, 사용자가 지정한 정확한 길이에 맞는 highlight video를 자동으로 생성하는 방법을 제안한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 기존 자동 highlight 생성 방식은 왜 사용자가 원하는 길이를 맞추기 어려운가? |
| 2 | 데이터 신호 | Most Replayed Data는 영상의 중요한 순간을 얼마나 잘 반영하는가? |
| 3 | 그래프 모델링 | highlight 편집 과정을 timestamp와 segment duration의 path 탐색 문제로 어떻게 바꾸는가? |
| 4 | reward 설계 | 높은 replay 구간과 자연스러운 segment 길이를 어떻게 함께 고려하는가? |
| 5 | 사용자 조정 | 특정 장면을 포함하거나 제외하면서도 전체 길이를 유지할 수 있는가? |
| 6 | 실험 결과 | 제안 방식은 기존 baseline과 사람 편집본에 비해 어떤 평가를 받았는가? |
| 7 | 한계 | MRD 의존성, 계산량, shot boundary, short-form 변환 문제는 어떻게 남는가? |

## 1. 문제 배경

Highlight video는 원본 영상에서 시청자가 가장 흥미롭게 느낄 만한 장면을 짧게 편집한 결과물이다. 스포츠 경기의 주요 장면, 공연 영상의 핵심 구간, 긴 방송 영상의 요약본처럼 highlight는 원본을 전부 보지 않고도 핵심 경험을 전달하는 역할을 한다.

하지만 실제 영상 배포 환경에서는 highlight의 길이가 중요하다. TV 광고 slot, social media 업로드 제한, short-form 플랫폼의 권장 길이처럼 외부 조건이 정해져 있기 때문이다. 사용자가 30초, 1분, 2분처럼 특정 길이를 요구할 때, 자동 시스템은 단순히 중요한 장면을 고르는 것만으로는 부족하다.

기존 방법은 frame importance나 event score가 높은 구간을 골라 요약 영상을 만들 수 있지만, 결과 길이가 임의로 결정되거나 threshold 조정에 크게 의존하는 경우가 많다. 또한 높은 점수를 가진 frame을 짧게 이어 붙이면 1초 미만의 빠른 cut이 반복되어 맥락을 이해하기 어렵다.

이 논문의 문제 정의는 다음처럼 정리할 수 있다.

```text
original video + Most Replayed Data + user-specified length
-> highlight video with exact target duration
-> engaging moments + readable context + natural segment duration
```

즉, 논문의 핵심은 "중요한 장면을 찾는 것"과 "정확한 길이에 맞게 편집하는 것"을 하나의 최적화 문제로 결합하는 데 있다.

## 2. Most Replayed Data를 사용하는 이유

Most Replayed Data는 YouTube 영상에서 시청자들이 어느 구간을 많이 되돌려 보았는지 보여주는 replay frequency graph다. 논문은 이 데이터를 영상 내 중요한 순간을 가리키는 crowd-sourced attention signal로 해석한다.

예를 들어 프랑스와 아르헨티나의 2018 FIFA World Cup 경기 영상에서는 MRD peak가 주요 경기 event와 강하게 맞물렸다. 43분, 52분, 62분, 68분, 73분, 97분 부근의 peak는 득점이나 중요한 장면과 연결되었고, 13분 부근의 peak는 이후 첫 골로 이어지는 yellow card와 penalty kick 상황과 관련되었다.

논문은 MRD가 단순한 소리 크기나 live chat 빈도보다 key moment를 더 안정적으로 반영할 수 있다고 설명한다.

| 비교 신호 | MRD와의 cosine similarity | 해석 |
|---|---:|---|
| 영상 내 sound intensity | 0.79 | 큰 소리가 나는 순간과 어느 정도 맞지만, 모든 중요 장면을 설명하지는 못한다. |
| live chat frequency | 0.70 | 시청자 반응을 담지만, spam이나 잡담 때문에 실제 event와 어긋날 수 있다. |

해석하면 MRD는 영상의 시청자 행동에서 직접 관찰된 관심도 신호다. 따라서 highlight 생성에서 "무엇이 중요해 보이는가"를 모델이 추정하는 대신, 많은 시청자가 실제로 다시 본 구간을 활용한다는 장점이 있다.

## 3. Highlight Editing Path로 문제 모델링

논문은 highlight 생성 과정을 그래프 위의 최적 path 탐색 문제로 만든다. 입력은 원본 영상, MRD, 사용자가 지정한 길이 \\(L_{user}\\)다. 여기서 \\(L_{user}\\)는 원본 영상보다 짧은 임의의 길이로 설정될 수 있다.

각 node는 다음과 같이 정의된다.

$$
n = \{t, d\}
$$

| 기호 | 의미 |
|---|---|
| \\(t\\) | 원본 영상의 timestamp, 초 단위 |
| \\(d\\) | 현재 segment가 이어진 시간 |

전체 node 수는 \\(T \times D\\)로 볼 수 있다. \\(T\\)는 원본 영상의 길이이고, \\(D\\)는 segment duration의 최대값이다. 논문에서는 한 segment가 너무 길어져 지루해지는 것을 막기 위해 \\(D=30\\)초를 사용한다.

Edge는 시간 순서를 유지하면서 두 가지 편집 동작을 표현한다.

| 조건 | 의미 |
|---|---|
| \\(t' = t + 1\\), \\(d' = d + 1\\) | 같은 segment를 1초 더 재생한다. |
| \\(t' \ne t + 1\\), \\(d' = 0\\) | 다른 구간으로 cut transition한다. |
| cut transition 시 \\(t' \ge t + 5\\) | 최소 5초 이상 떨어진 구간으로 이동해 1초 단위의 어색한 interruption을 줄인다. |

Highlight editing path는 이 node와 edge를 따라가는 sequence이며, path의 길이가 곧 최종 highlight의 길이 \\(L_{user}\\)가 된다. 따라서 사용자가 60초 highlight를 원하면, 시스템은 정확히 60개의 초 단위 node로 이루어진 최적 path를 찾는다.

## 4. Reward 설계

각 node의 reward는 MRD 기반 관심도와 segment duration 기반 맥락 보존 점수를 결합한다.

$$
R(n) = R_{MRD}(t) + wR_{dur}(d)
$$

논문에서 \\(w=0.2\\)로 설정된다. \\(R_{MRD}(t)\\)는 timestamp \\(t\\)에서의 replay intensity를 의미한다. YouTube의 MRD graph는 영상 길이와 관계없이 100개의 data point로 제공되므로, 논문은 이를 1초 단위로 보간하고 0과 1 사이로 정규화한다.

Segment duration reward는 cut이 발생할 때만 반영된다.

$$
R_{dur}(d) =
\begin{cases}
R_{ctx}(d) & \text{if } d'=0 \\
0 & \text{otherwise}
\end{cases}
$$

여기서 \\(R_{ctx}(d)\\)는 segment가 너무 짧을 때 penalty를 주고, 충분히 길면 1에 가까운 보상을 주는 함수다.

$$
R_{ctx}(d) =
\begin{cases}
2e^{-(d-\tau)^2/8} - 1 & \text{if } d < \tau \\
1 & \text{otherwise}
\end{cases}
$$

논문은 cinematographic principle을 참고해 \\(\tau=8\\)초를 권장 최소 segment 길이로 둔다. 이 설계는 높은 MRD peak만 짧게 찍고 넘어가는 편집을 피하게 만든다. 즉, 장면의 관심도뿐 아니라 시청자가 상황을 이해할 수 있는 최소 맥락을 함께 확보한다.

최종 목표는 사용자가 지정한 길이만큼의 path 중 reward 합이 최대인 path를 찾는 것이다.

$$
P^* =
\arg\max_P
\sum_{i=1}^{L_{user}} R(n_i)
$$

논문은 이 최적 path를 dynamic programming으로 계산한다. 해석하면 이 문제는 "중요한 구간을 가능한 많이 포함하되, segment가 너무 짧아지지 않도록 제약을 둔 길이 고정 편집 문제"로 볼 수 있다.

## 5. 사용자 지정 장면 포함과 제외

시스템은 자동 highlight 생성만 제공하지 않고, 사용자가 특정 timestamp를 포함하거나 제외하도록 조정할 수 있다. 이를 위해 MRD reward에 사용자 reward를 더한다.

$$
R_{MRD}(t) \leftarrow R_{MRD}(t) + R_{user}(t)
$$

사용자가 timestamp \\(\alpha\\)를 포함하고 싶으면 양의 Gaussian reward를 더하고, 제외하고 싶으면 음의 Gaussian reward를 더한다.

$$
R_{user}(t) = \pm \lambda G(t-\alpha)
$$

논문에서는 \\(\lambda=10\\), standard deviation 1.333을 사용한다. 여러 timestamp가 선택되면 각 사용자 reward를 합산한다.

이 방식의 장점은 전체 최적화 구조를 유지한다는 점이다. 사용자가 특정 장면을 고정하더라도 highlight의 전체 길이 \\(L_{user}\\)는 그대로 유지되고, 남은 구간은 MRD와 duration reward에 따라 자동으로 채워진다.

## 6. 생성 결과 해석

논문은 archery, concert, soccer, audition 등 다양한 영상에서 highlight를 생성했다. 같은 soccer 영상에 대해 \\(L_{user}\\)를 30초, 60초, 90초, 120초로 바꾸면 선택되는 구간이 자연스럽게 달라진다.

| 설정 | 결과 경향 |
|---|---|
| 30초 | 가장 높은 MRD peak 3개 중심으로 매우 압축된 highlight가 생성된다. |
| 60초 이상 | 기존 peak 주변 segment가 길어지고, 추가 peak가 포함된다. |
| 길이가 증가할수록 | 평균 segment 수와 segment duration이 함께 증가한다. |
| 평균 MRD | 낮은 MRD 주변 구간도 포함되므로 전체 평균은 감소한다. |

중요한 점은 모든 \\(L_{user}\\) 조건에서 평균 segment duration이 8초 이상으로 유지되었다는 것이다. 이는 duration reward가 실제로 지나치게 짧은 cut을 억제했음을 보여준다.

사용자 지정 예시에서는 4분 24초, 7분 11초, 9분 19초, 10분 42초, 11분 57초 timestamp를 포함하도록 설정했다. 시스템은 해당 장면들을 반영하면서도 남은 길이를 1분 46초, 3분 33초, 6분 03초 부근의 높은 MRD peak로 채웠다. 이는 사용자의 의도와 crowd interest signal을 함께 사용하는 방식으로 해석할 수 있다.

## 7. 실험 설정과 주요 결과

논문은 두 가지 user study를 수행했다. 총 30명이 참여했고, 성별은 남성 15명과 여성 15명, 평균 나이는 23.40세였다. 각 study는 온라인 form으로 진행되었고, 참가자는 보상을 받았다.

### 7.1 기존 방법과의 비교

첫 번째 study는 제안 방법, threshold-based method, random method를 비교했다. 모든 highlight 길이는 60초로 맞췄다.

| 비교 방법 | 설명 |
|---|---|
| Proposed method | MRD와 duration reward를 함께 고려해 최적 path를 생성한다. |
| Threshold-based method | MRD가 높은 frame부터 선택해 총 길이를 맞춘 뒤 원래 순서로 정렬한다. |
| Random method | 제안 방법과 segment 수를 맞춘 뒤 random non-overlapping segment를 선택한다. |

참가자는 각 영상별 세 가지 highlight를 보고 appropriateness, key moment inclusion, satisfaction을 7점 Likert scale로 평가했다. Friedman test 결과 세 문항 모두에서 유의한 차이가 있었다.

| 문항 | 통계 결과 | 제안 방법 평균 | threshold 평균 | random 평균 |
|---|---|---:|---:|---:|
| Appropriateness | \\(\chi^2(2)=37.16, p<0.0001\\) | 5.27 | 4.14 | 4.06 |
| Key moment inclusion | \\(\chi^2(2)=40.99, p<0.0001\\) | 5.59 | 5.02 | 4.15 |
| Satisfaction | \\(\chi^2(2)=38.97, p<0.0001\\) | 5.43 | 4.59 | 3.99 |

해석하면, 제안 방법은 단순히 MRD가 높은 frame을 모으는 방식보다 자연스럽고 만족스러운 highlight를 만들었다. 특히 duration reward와 path formulation이 짧고 끊기는 편집을 줄이는 데 기여한 것으로 볼 수 있다.

### 7.2 사람 편집본과의 비교

두 번째 study는 제안 방법으로 만든 highlight와 YouTube Shorts의 사람 편집본을 비교했다. 제안 방법의 \\(L_{user}\\)는 각 Shorts의 길이와 동일하게 설정했다.

참가자는 원본 영상을 본 뒤 두 버전을 비교하고, 제안 방법, 사람 편집본, 또는 동등 선호 중 하나를 선택했다. Friedman test 결과는 다음과 같다.

$$
\chi^2(2)=5.8919,\quad p=0.0526
$$

통계적으로 유의한 선호 차이가 없었다는 점에서, 논문은 제안 방법이 사람 편집본과 유사한 수준의 viewing experience를 제공할 수 있다고 해석한다. 다만 \\(p=0.0526\\)은 유의수준 0.05에 매우 가까우므로, "사람보다 우수하다"가 아니라 "강한 선호 차이를 보이지 않았다"로 읽는 것이 적절하다.

정성적 의견에서는 12명이 제안 방법의 narrative structure가 명확하다고 응답했고, 10명은 engaging하고 이해하기 쉽다고 평가했다. 6명은 segment duration이 적절하다고 언급했으며, 3명은 편집이 자연스럽다고 보았다.

## 8. 계산 시간과 확장성

논문은 rendering 시간을 제외하고 path optimization 시간만 측정했다. Python implementation, Intel Xeon Silver 4214 2.20 GHz, 32 GB memory 환경에서 실험했다.

| 원본 영상 길이 | 목표 highlight 길이 | 최적화 시간 |
|---|---:|---:|
| 2분 10초 | 30초 | 2.72초 |
| 2분 10초 | 1분 | 4.34초 |
| 3분 15초 | 30초 | 6.49초 |
| 3분 15초 | 1분 | 15.9초 |
| 5분 05초 | 1분 | 41.62초 |
| 5분 05초 | 1분 30초 | 59.7초 |
| 8분 40초 | 1분 | 2분 32초 |
| 8분 40초 | 2분 | 4분 58초 |
| 10분 21초 | 3분 | 9분 59초 |

영상이 길어질수록 node와 edge 후보가 급격히 늘어나므로 계산 시간이 빠르게 증가한다. 이 점은 실시간 interactive editing tool로 확장할 때 중요한 병목이 될 수 있다.

## 9. 논문의 핵심 기여

첫째, MRD를 highlight generation의 중심 신호로 사용했다. 이는 사람이 직접 annotation하지 않아도 많은 시청자의 replay 행동을 활용할 수 있다는 점에서 실용적이다.

둘째, highlight 길이를 사후 조정하는 방식이 아니라 최적화 목표 안에 직접 포함했다. 이 덕분에 사용자는 30초, 1분, 2분처럼 구체적인 길이를 요구할 수 있다.

셋째, segment duration reward를 통해 너무 짧은 cut이 반복되는 문제를 줄였다. 이는 단순 frame selection과 달리 영상 편집의 맥락 유지 문제를 다룬 부분이다.

넷째, 사용자 지정 timestamp를 포함하거나 제외하는 customization을 제공한다. 자동 생성 결과에 사용자의 의도를 반영할 수 있으므로, 완전 자동 편집과 수동 편집 사이의 중간 지점을 만든다.

## 10. 해석 포인트

이 논문은 highlight generation을 단순한 중요도 ranking 문제가 아니라 편집 path optimization 문제로 재정의한다. 중요한 장면을 고르는 것, 그 장면을 어느 정도 길이로 보여줄 것, 전체 결과를 몇 초로 맞출 것이라는 세 가지 요구가 하나의 그래프 탐색 문제 안에서 결합된다.

또한 MRD는 모델이 예측한 중요도가 아니라 실제 platform interaction에서 나온 행동 데이터다. 이 점은 장점이지만 동시에 데이터가 존재하는 플랫폼과 영상에 의존한다는 제한도 만든다. 따라서 이 방법은 "모든 영상에 적용 가능한 일반 highlight model"이라기보다 "replay behavior가 충분히 축적된 영상에 강한 editing framework"로 이해하는 편이 정확하다.

사람 편집본과의 비교 결과도 조심해서 읽어야 한다. 논문은 제안 방법이 human editor보다 우월하다고 주장하기보다는, viewing experience 측면에서 유사한 수준에 도달할 가능성을 보였다고 보는 것이 적절하다.

## 11. 한계와 향후 과제

가장 큰 한계는 MRD availability다. MRD는 충분한 조회 수를 가진 YouTube 영상에서만 제공되며, 새로 업로드된 영상이나 조회 수가 낮은 영상에는 사용할 수 없다. 논문은 향후 MRD prediction model을 사용해 임의의 영상에서도 유사한 intensity graph를 만들 수 있다고 제안한다.

두 번째 한계는 긴 영상에서 계산량이 커진다는 점이다. 원본 영상 길이가 길어질수록 node와 edge가 늘어나고, 가능한 editing path도 많아진다. 논문은 sparse node interval이나 edge pruning을 대안으로 언급한다.

세 번째는 shot boundary를 직접 고려하지 않는다는 점이다. 이미 편집된 영상에서는 segment 내부에 shot cut이 포함될 수 있고, 이 경우 highlight가 시각적으로 어색해질 수 있다. 향후 shot boundary detection을 사용해 cut 주변 edge를 조정하면 더 자연스러운 결과를 만들 수 있다.

네 번째는 short-form platform을 위한 aspect ratio 변환 문제다. 논문은 highlight length를 맞추는 데 집중하므로, portrait video로 변환할 때 어떤 영역을 crop할지는 별도의 문제로 남는다. Region of interest detection이나 subject tracking이 결합될 수 있다.

마지막으로 narrative-driven highlight에는 추가적인 semantic understanding이 필요하다. MRD peak가 높은 구간은 관심도가 높은 순간을 알려주지만, 스토리의 시작, 갈등, 전환, 결말을 의도적으로 구성하는 편집까지 자동으로 보장하지는 않는다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/generating-highlight-videos-most-replayed-data/generating-highlight-videos-most-replayed-data.pdf" | relative_url }}" target="_blank" rel="noopener">Generating Highlight Videos of a User-Specified Length using Most Replayed Data.pdf</a></li>
  <li><a href="https://w-dlee.github.io/highlights" target="_blank" rel="noopener">Project page</a></li>
  <li><a href="https://doi.org/10.1145/3706598.3713880" target="_blank" rel="noopener">DOI: 10.1145/3706598.3713880</a></li>
</ul>
