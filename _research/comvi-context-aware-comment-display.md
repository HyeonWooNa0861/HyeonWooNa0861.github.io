---
layout: default
date: 2026-05-27 17:35:55 +0900
title: "ComVi"
topic: "Context-aware optimized comment display in video playback"
order: 7
major_topic: "Human–Computer Interaction & Media"
keywords:
  - "ComVi"
  - "Comment display"
  - "Video playback"
  - "Context awareness"
---

# ComVi: Context-Aware Optimized Comment Display in Video Playback

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | ComVi: Context-Aware Optimized Comment Display in Video Playback |
| 저자 | Minsun Kim, Dawon Lee, Junyong Noh |
| 학회 | CHI 2026, Barcelona, Spain |
| DOI | `10.1145/3772318.3791018` |
| 키워드 | Comments, Video Interfaces, Comment Visualization, Contextual Alignment, Viewing Experience |
| 프로젝트 페이지 | `https://w-dlee.github.io/comvi` |

## 한 줄 요약

ComVi는 일반 동영상 플랫폼의 댓글을 영상의 현재 장면과 의미적으로 맞는 timestamp에 배치하고, 관련성, 인기도, 읽기 시간을 함께 고려해 최적의 댓글 표시 sequence를 구성하는 comment-integrated video playback 시스템이다.

## 핵심 내용

이 절은 원문 전체를 그대로 옮긴 번역이 아니라, ComVi 논문의 문제 설정부터 사용자 연구까지를 한국어로 다시 따라갈 수 있게 재구성한 번역형 해설이다. 시스템명, 수식, 실험 조건, DOI와 같은 고유 정보는 원문 기준을 유지했다.

초록과 서론에서 논문은 일반 동영상 댓글이 영상 재생 맥락과 분리되어 있다는 문제를 제기한다. YouTube식 댓글 목록은 현재 장면과 관계없는 내용이나 spoiler를 먼저 노출할 수 있고, Danmaku식 댓글은 timestamp metadata가 있는 경우에 강하지만 일반 댓글에는 그대로 적용하기 어렵다. ComVi는 timestamp가 없는 일반 댓글을 영상 장면과 의미적으로 맞는 시간에 배치하고, 사용자가 읽을 수 있는 방식으로 정렬하는 시스템으로 제안된다.

ComVi의 방법은 댓글과 영상 timestamp 사이의 audio-visual correlation을 계산하는 데서 시작한다. Subtitle 또는 speech-to-text 결과는 audio context를 제공하고, shot segmentation과 video captioning 결과는 visual context를 제공한다. 댓글과 각 timestamp의 관련성은 Sentence-BERT embedding 기반 cosine similarity로 계산되며, threshold를 넘는 댓글은 timed comment 후보가 된다. 명시적인 timestamp reference가 있는 댓글은 작성자의 의도를 우선해 해당 시점에 직접 배치된다.

댓글을 어느 시점에 얼마나 오래 보여줄지는 최적화 문제로 다룬다. 각 댓글에는 의미 관련성, 좋아요 수, 읽기 시간이 반영된 score가 부여되고, 댓글이 서로 겹치지 않으면서 총점이 최대가 되는 sequence를 dynamic programming으로 선택한다. 이 구조는 weighted interval scheduling과 유사하며, 단순히 관련성 높은 댓글을 많이 보여주는 것이 아니라 읽기 가능성과 화면 부담까지 함께 고려한다.

평가에서는 ComVi가 random 배치보다 높은 semantic correlation과 popularity를 보였고, reading speed나 동시 표시 개수 설정에 따라 선택되는 댓글 수가 자연스럽게 조절되었다. 사용자 연구에서는 ComVi가 YouTube, Danmaku, 단일 댓글 표시 baseline보다 mental demand와 physical demand를 낮추고 contextual alignment와 engagement를 높인 것으로 보고된다.

결론적으로 ComVi의 기여는 새로운 deep learning model 자체보다 video comment consumption을 하나의 HCI 최적화 문제로 재정의한 데 있다. 한계도 명확하다. 전체 감상 댓글처럼 특정 timestamp에 대응되지 않는 댓글, Sentence-BERT의 lexical overlap bias, 장면 복잡도에 따른 cognitive load, subtitle과 댓글의 충돌 문제는 후속 연구가 필요하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 일반 댓글은 왜 영상 재생 맥락과 어긋나기 쉬운가? |
| 2 | 입력과 출력 | ComVi는 어떤 데이터를 받아 어떤 comment sequence를 만드는가? |
| 3 | timestamp mapping | 시간 정보가 없는 댓글을 어떻게 timed comment로 바꾸는가? |
| 4 | sequence generation | 댓글을 겹치지 않게 표시하면서 읽을 시간을 어떻게 보장하는가? |
| 5 | scoring과 최적화 | 의미 관련성, 좋아요 수, display duration을 어떻게 하나의 목적함수로 결합하는가? |
| 6 | personalization | 사용자가 읽기 방식과 관심 주제를 어떻게 조절할 수 있는가? |
| 7 | 결과와 사용자 연구 | ComVi는 YouTube, Danmaku 계열 interface보다 어떤 경험을 제공했는가? |
| 8 | 한계 | timestamp에 잘 맞지 않는 전체 감상 댓글, 다양성, cognitive load 문제는 어떻게 남는가? |

## 1. 문제 배경

YouTube, TikTok, Vimeo 같은 플랫폼의 댓글은 영상 이해를 돕고, 다른 시청자의 해석을 접하게 하며, 함께 보는 느낌을 만든다. 그러나 일반 플랫폼의 댓글 목록은 재생 시간과 독립적으로 표시된다. 사용자는 영상을 보면서 댓글을 읽다가 아직 나오지 않은 장면에 대한 spoiler나 현재 장면과 무관한 반응을 먼저 볼 수 있다.

Danmaku 기반 interface는 댓글을 영상 위에 시간 동기화해 보여주지만, 댓글 작성 시점 자체가 display timestamp로 저장되어 있어야 한다. 따라서 timestamp metadata가 없는 일반 댓글에는 그대로 적용하기 어렵다. 또한 많은 댓글이 동시에 지나가면 화면이 복잡해지고 읽기 시간이 부족해질 수 있다.

ComVi의 문제 정의는 다음과 같다.

```text
general video comments without timestamps
-> semantically aligned timed comments
-> readable, non-overlapping, optimized display sequence
```

즉, 핵심은 댓글을 단순히 많이 보여주는 것이 아니라, 현재 장면과 맞는 댓글을 읽을 수 있는 시간 동안 보여주는 것이다.

## 2. ComVi 시스템 개요

ComVi는 video, comments, comment metadata를 입력으로 받는다. Metadata에는 좋아요 수와 user profile 정보가 포함된다. 출력은 각 댓글의 appearance timing과 display duration이 정해진 하나의 comment sequence다.

| 단계 | 역할 |
|---|---|
| Comment deduplication | 동일한 텍스트 댓글이 여러 개 있으면 좋아요 수가 가장 높은 것만 유지 |
| Audio-visual correlation | 댓글과 각 timestamp의 audio/visual content 간 의미적 관련성 계산 |
| Timed comment mapping | 관련성이 threshold를 넘는 timestamp에 댓글을 배치 |
| Candidate sequence generation | 읽기 시간과 non-overlap 조건을 만족하는 sequence 후보 생성 |
| Score evaluation | semantic relevance, likes, reading duration을 합쳐 각 timed comment 점수 계산 |
| Dynamic programming | 총점이 가장 높은 optimal sequence 선택 |

ComVi의 기본 interface는 한 시점에 하나의 댓글만 영상 하단에 표시한다. 논문은 이를 기반으로 동시 표시 개수와 관심 주제 기반 filtering을 조절하는 확장 기능도 제안한다.

## 3. General Comment를 Timed Comment로 매핑

댓글 집합을 다음처럼 둔다.

$$
\{C_1, C_2, \ldots, C_I\}
$$

각 댓글 \(C_i\)는 여러 timestamp \(t\)에 대응될 수 있다. \(C_{i,t}\)는 댓글 \(C_i\)가 timestamp \(t\)에 표시되는 timed comment를 뜻한다.

ComVi는 댓글과 timestamp의 관련성을 audio correlation과 visual correlation으로 나누어 계산한다.

$$
Corr(C_{i,t})
=
Norm\left(
\sqrt{
\frac{
Corr_A(C_{i,t})^{2} + Corr_V(C_{i,t})^{2}
}{2}
}
\right)
$$

| 항목 | 계산 방식 |
|---|---|
| \(Corr_A(C_{i,t})\) | 댓글과 timestamp에 대응되는 subtitle segment 사이의 cosine similarity |
| \(Corr_V(C_{i,t})\) | 댓글과 timestamp가 속한 video shot description 사이의 cosine similarity |
| Text encoder | Sentence-BERT `all-mpnet-base-v2` |
| Shot segmentation | PySceneDetect |
| Visual description | Tarsier video captioning model |

Subtitle이 없는 경우에는 Whisper 같은 speech-to-text model로 생성할 수 있다고 설명한다. Visual side에서는 video를 shot 단위로 나눈 뒤, 각 shot에 대해 "Describe the video in detail" prompt로 textual description을 만든다.

논문에서 timed comment로 채택되는 기준은 audio-visual correlation이 threshold `0.3`을 넘는 경우다. 단, 댓글 안에 명시적 timestamp reference가 있는 경우에는 작성자의 의도를 반영해 해당 timestamp에 직접 mapping한다.

## 4. Candidate Sequence 생성

ComVi는 timed comment pool에서 후보 sequence를 만들 때 두 조건을 둔다.

첫째, 각 댓글은 사용자가 읽을 수 있을 만큼 충분히 표시되어야 한다. 댓글 \(C_i\)의 reading time은 comment length \(L(C_i)\)와 사용자 reading speed \(\alpha_{user}\)를 이용해 계산한다.

$$
Reading(C_i)
=
\min(\alpha_{user} \cdot L(C_i), \tau_{max})
$$

| 값 | 의미 |
|---|---|
| \(\alpha_{user}\) | character당 평균 reading time, 기본값 0.068초 |
| \(L(C_i)\) | 댓글의 character 수 |
| \(\tau_{max}\) | 최대 display duration, 기본값 6초 |

다음 댓글 \(C_{i',t'}\)은 이전 댓글이 끝난 뒤 나타나야 하므로 기본 조건은 다음과 같다.

$$
t' \ge t + Reading(C_i)
$$

둘째, 한 번 선택된 댓글은 이후 sequence에서 다시 선택하지 않는다. 이 조건은 반복 노출을 줄이기 위한 장치다.

## 5. Sequence Quality와 최적화

각 timed comment의 score는 semantic relevance와 popularity를 결합해 계산한다.

$$
Score(C_{i,t})
=
\left(
w_{corr}Corr(C_{i,t})
+ w_{likes}Likes(C_i)
\right)
\cdot Reading(C_i)
$$

논문에서 기본값은 \(w_{corr}=2\), \(w_{likes}=1\)이다. \(Likes(C_i)\)는 normalized like count이며, 원시 좋아요 수가 long-tailed distribution을 가지기 때문에 Box-Cox transformation을 적용한 뒤 0과 1 사이로 정규화한다.

좋아요 수 정규화는 다음처럼 정의된다.

$$
Likes(C_i)
=
\begin{cases}
Norm(BoxCox(l_i)) & \text{if } l_i \ne 0 \\
0 & \text{otherwise}
\end{cases}
$$

$$
BoxCox(l_i)
=
\begin{cases}
\frac{l_i^{\lambda} - 1}{\lambda} & \lambda \ne 0 \\
\ln(l_i) & \lambda = 0
\end{cases}
$$

여기서 \(l_i\)는 raw like count다. \(\lambda\)는 like count distribution을 더 정규분포에 가깝게 만들도록 자동 추정된다.

최종 목표는 sequence \(S\) 안의 timed comment 점수 합을 최대화하는 것이다.

$$
S^{*}
=
\arg\max_S
\sum_{k=1}^{n}
Score(C_{i_k,t_k})
$$

논문은 dynamic programming을 사용해 이 최적 sequence를 구한다. 이 formulation은 weighted interval scheduling과 비슷하게 읽을 수 있다. 각 댓글은 시작 시간과 읽기 duration을 가진 interval이고, ComVi는 겹치지 않는 interval들 중 총점이 큰 조합을 고른다.

## 6. Personalized Comment Curation

ComVi는 자동 sequence를 기본으로 하지만 사용자의 읽기 방식과 관심 주제를 조절할 수 있게 한다.

| 기능 | 설명 |
|---|---|
| 동시 표시 개수 조절 | \(N_{user}\)를 설정해 한 번에 최대 몇 개 댓글을 볼지 정한다. |
| 관심 주제 query | 사용자가 자연어 query \(q_{user}\)를 입력하면, query와 유사한 댓글만 먼저 filtering한다. |

동시 표시 개수를 허용할 때는 non-overlap 조건을 완화한다. 대신 현재 timestamp에서 이미 표시 중인 댓글 수가 \(N_{user}\)보다 작아야 한다.

$$
Overlap(C_{i',t'})
=
\left|
\left\{
C_{i,t} \in S_{current}
\mid
t + Reading(C_i) > t'
\right\}
\right|
$$

관심 주제 filtering은 \(q_{user}\)와 각 댓글 embedding의 cosine similarity를 계산한 뒤, threshold `0.6` 이상인 댓글만 다음 mapping process로 넘긴다.

## 7. 결과 분석

논문은 ComVi가 생성한 sequence의 semantic correlation, popularity, reading speed 변화, customization 효과를 분석한다.

### 7.1 Semantic Correlation

ComVi는 documentary, movie, news video에서 Random condition보다 훨씬 높은 correlation을 보였고, explicit timestamp reference를 활용한 Ground-truth condition과 비교 가능한 수준의 결과를 보였다.

| Video | ComVi | Ground-truth | Random |
|---|---:|---:|---:|
| Documentary | 0.66 | 0.76 | 0.14 |
| Movie | 0.66 | 0.61 | 0.17 |
| News | 0.74 | 0.72 | 0.24 |

해석하면, ComVi는 단순히 댓글을 무작위로 배치하는 것이 아니라 장면 의미와 관련 있는 댓글을 골라낼 수 있음을 보여준다. 다만 Ground-truth보다 낮은 경우도 있는데, 이는 읽기 시간 조건 때문에 correlation이 가장 높은 댓글을 건너뛰어야 하는 경우가 있기 때문이다.

### 7.2 Popularity

ComVi는 normalized like count 측면에서도 Total comment pool과 Likes-ablated baseline보다 높은 값을 보였다.

| Video | ComVi | Likes-ablated | Total |
|---|---:|---:|---:|
| Documentary | 0.94 | 0.14 | 0.10 |
| Movie | 0.76 | 0.31 | 0.15 |
| News | 0.93 | 0.12 | 0.09 |

이는 ComVi의 scoring function이 semantic relevance만이 아니라 comment popularity도 실제로 반영한다는 근거다.

### 7.3 Reading Speed와 Sequence 구조

\(\alpha_{user}\)가 커질수록 댓글 하나가 더 오래 표시되므로, 전체 sequence에 포함되는 댓글 수는 감소한다.

| \(\alpha_{user}\) | 평균 display duration | 선택된 댓글 수 |
|---:|---:|---:|
| 0.048 | 3.45초 | 85 |
| 0.068 | 3.89초 | 75 |
| 0.088 | 4.63초 | 63 |

이 결과는 ComVi가 단순히 높은 점수 댓글을 많이 넣는 것이 아니라, 사용자의 읽기 속도에 따라 정보량과 readability 사이의 trade-off를 조절한다는 점을 보여준다.

### 7.4 Customization

동시 표시 댓글 수 \(N_{user}\)를 2에서 3으로 높이면 선택된 댓글 수가 65개에서 96개로 증가했다. 또한 user-specified query \(q_{user}\)를 적용하면 동일한 video segment에서도 사용자의 관심 주제와 관련된 다른 댓글 sequence가 생성된다.

### 7.5 Implementation Cost

ComVi는 Python으로 구현되었고, AMD EPYC 7352 CPU, 62GB RAM, NVIDIA RTX A5000 GPU 환경에서 실행되었다. 2분에서 10분 길이의 다섯 video와 1,000개 이상의 댓글을 대상으로 computation time은 17초에서 1분 11초 사이였다.

다만 이 시간은 video, comments, metadata 수집 및 visual textual representation 생성 과정을 제외한다. 논문은 PySceneDetect 기반 shot segmentation에 약 20초, Tarsier captioning에는 약 10분이 걸렸다고 보고한다. 따라서 실시간 서비스 관점에서는 preprocessing cost를 별도로 고려해야 한다.

## 8. 사용자 연구

논문은 ComVi가 기존 interface보다 더 나은 comment-integrated viewing experience를 제공하는지 평가하기 위해 사용자 연구를 수행했다.

| 항목 | 내용 |
|---|---|
| 참가자 | 32명, 남성 15명/여성 17명, 평균 나이 26.34세 |
| 비교 조건 | ComVi, YouTube, Danmaku, YouTube-1ver., Danmaku-1ver. |
| Video genre | movie, entertainment, news, documentary, music video |
| 측정 항목 | mental demand, physical demand, contextual alignment, overall engagement |
| 척도 | 7-point Likert scale |

Friedman test 결과, 네 질문 모두에서 다섯 interface 간 유의미한 차이가 있었다.

| 항목 | ComVi 결과 | 해석 |
|---|---|---|
| Mental demand | 2.22 | Danmaku, Danmaku-1ver.보다 유의하게 낮음 |
| Physical demand | 1.50 | YouTube, YouTube-1ver., Danmaku보다 유의하게 낮음 |
| Contextual alignment | 5.97 | 다른 네 interface 모두보다 유의하게 높음 |
| Overall engagement | 5.22 | 다른 네 interface 모두보다 유의하게 높음 |

선호도 조사에서는 71.9%의 참가자가 ComVi를 가장 선호했다. YouTube는 18.8%, Danmaku-1ver.는 6.2%, YouTube-1ver.는 3.1%였고, Danmaku를 선택한 참가자는 없었다.

## 9. 논문의 핵심 기여

첫째, ComVi는 timestamp metadata가 없는 일반 댓글을 video playback timeline에 맞춰 배치하는 방법을 제안한다. 이는 Danmaku처럼 작성 시점이 이미 저장된 댓글만 다루는 방식과 다르다.

둘째, 댓글 선택을 relevance ranking 문제가 아니라 temporal sequence optimization 문제로 다룬다. 댓글에는 시작 시간과 읽기 시간이 있고, 시스템은 겹치지 않으면서 총점이 높은 sequence를 찾아야 한다.

셋째, semantic relevance와 social signal인 likes를 함께 사용한다. 이를 통해 장면과 맞지만 아무도 주목하지 않은 댓글, 또는 인기 있지만 장면과 무관한 댓글 사이에서 균형을 잡는다.

넷째, 사용자 연구를 통해 ComVi가 mental demand, physical demand, contextual alignment, engagement 측면에서 기존 interface보다 나은 경험을 제공할 수 있음을 보였다.

## 10. 해석 포인트

이 논문을 읽을 때 중요한 점은 ComVi가 단순한 comment overlay가 아니라는 것이다. 핵심은 "어떤 댓글을 언제, 얼마나 오래 보여줄 것인가"를 하나의 최적화 문제로 재정의했다는 데 있다.

또한 ComVi의 contribution은 model 자체의 새 deep learning architecture보다 HCI system design에 가깝다. Sentence-BERT, PySceneDetect, Tarsier 같은 기존 모델을 조합하되, video comment consumption이라는 사용자 경험 문제에 맞게 scoring과 sequence selection을 설계했다.

사용자 연구 결과도 "ComVi가 모든 상황에서 항상 더 좋다"가 아니라, 현재 실험 조건에서 댓글과 영상을 함께 소비할 때 더 낮은 부담과 더 높은 alignment를 제공했다는 근거로 읽어야 한다. 특히 preprocessing cost와 video genre 다양성, long comment 처리, 전체 감상 댓글 처리 문제는 별도 검증이 필요하다.

## 11. 한계와 향후 과제

첫째, video 전체에 대한 감상이나 총평처럼 특정 timestamp에 대응되지 않는 댓글은 ComVi에서 덜 선택될 수 있다. 이런 댓글은 별도 panel이나 persistent comment 영역으로 다루는 확장이 가능하다.

둘째, Sentence-BERT는 lexical overlap이 큰 댓글에 높은 similarity를 줄 수 있다. 그 결과 narration을 그대로 반복하는 댓글이 우선될 수 있고, 새로운 관점이나 다양한 해석이 덜 노출될 수 있다. 논문은 novelty term이나 diversity constraint를 향후 방향으로 제안한다.

셋째, 정보 밀도가 높은 장면에서는 영상과 댓글을 동시에 처리하는 것이 cognitive overload를 만들 수 있다. 장면 복잡도에 따라 \(\alpha_{user}\)를 동적으로 조정하거나, shot boundary와 speech pause에 맞춰 댓글 표시 시점을 조정하는 방향이 필요하다.

넷째, 댓글은 화면 하단에 표시되므로 subtitle이나 중요한 시각 정보와 겹칠 수 있다. Dynamic placement, summarization, keyword highlighting, eye-tracking 기반 주의 분산 분석이 후속 연구로 제시된다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/comvi-context-aware-comment-display/comvi-context-aware-comment-display.pdf" | relative_url }}" target="_blank" rel="noopener">ComVi PDF</a></li>
  <li><a href="https://doi.org/10.1145/3772318.3791018" target="_blank" rel="noopener">DOI: 10.1145/3772318.3791018</a></li>
  <li><a href="https://w-dlee.github.io/comvi" target="_blank" rel="noopener">ComVi Project Page</a></li>
</ul>
