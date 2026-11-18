---
layout: default
date: 2026-11-18 00:00:03 +0900
title: "Speech and Audio Recognition Lecture 1: Introduction to Robot Audition"
course: "Speech and Audio Recognition"
topic: "Robot Audition, Real-World Acoustic Challenges, and Multimodal Spatial Reasoning"
order: 1
major_topic: "Speech and Audio Processing"
keywords:
  - "Robot Audition"
  - "Sound Event Detection"
  - "Sound Source Localization"
  - "Speech Separation"
  - "Speech Recognition"
  - "TDoA"
  - "NLOS"
  - "Multimodal Spatial Reasoning"
  - "Embodied AI"
---

# Speech and Audio Recognition Lecture 1: Introduction to Robot Audition

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf" | relative_url }}" target="_blank" rel="noopener">speech-audio-lecture-01-introduction.pdf</a> — Inkyu An, Kookmin University (21 pages).

이 글은 강의의 운영 안내가 아니라 PDF pp. 5–20의 기술 내용을 중심으로 정리한 학습 노트다. 출발점은 단순하다. 로봇이 사람처럼 소리를 듣고 행동하려면 “무슨 소리인가”뿐 아니라 **어디에서, 몇 개의 소리가, 어떤 환경을 거쳐 도착했는가**까지 알아야 한다. 강의는 이 문제를 robot audition으로 묶고, 이후 multimodal spatial reasoning과 embodied AI로 확장한다.

> **핵심:** robot audition은 하나의 분류기가 아니다. sound event detection, sound source localization, speech separation, speech recognition을 연결해 복잡한 acoustic scene을 해석하고, 그 결과를 navigation과 planning에 전달하는 perception pipeline이다.

## 학습 목표

1. Robot audition이 해결하려는 문제를 입력과 출력으로 설명한다.
2. Sound event detection, localization, separation, recognition의 역할을 구분한다.
3. Noise, simultaneous sources, robot self-noise, moving source, NLOS가 왜 어려운지 설명한다.
4. Microphone pair의 time difference of arrival(TDoA)가 방향 단서를 만드는 원리를 계산한다.
5. Audio가 vision과 결합할 때 spatial reasoning이 어떻게 확장되는지 설명한다.
6. Perception, memory, global representation, planning의 연결을 연구 제안과 검증 결과로 구분해 읽는다.

## 전체 흐름

```text
Acoustic scene
    -> event detection: what happened? ----------┐
    -> localization: where did it happen? -------┤ combine or run in parallel
    -> separation: which signal is each source? -┤
    -> recognition: what was said? --------------┘
    -> multimodal perception and memory
    -> environment representation
    -> planning and robot action
```

이 흐름은 모든 system이 반드시 같은 순서로 실행된다는 뜻이 아니다. Detection과 localization을 병렬로 추정할 수도 있고, localization 단서를 separation에 넣거나 separation 결과를 recognition에 전달할 수도 있다. 표는 각 과제가 제공하는 정보를 정리한 개념 지도다.

| 단계 | 대표 입력 | 대표 출력 | 다음 단계가 필요로 하는 정보 |
|---|---|---|---|
| Event detection | microphone waveform or spectrogram | event label and time interval | 주목할 소리의 종류와 발생 시점 |
| Localization | synchronized multichannel audio | direction or position | 로봇이 향하거나 이동할 공간 단서 |
| Separation | overlapping mixture | source-wise signals | 각 화자·음원의 깨끗한 신호 |
| Recognition | separated or enhanced speech | text or acoustic content | 명령·상황의 의미 |
| Multimodal reasoning | audio, vision, tactile signals, history | spatial-semantic state | 계획에 사용할 world model |
| Planning | current state and goal | action or trajectory | 실제 robot behavior |

## 1. Robot audition은 무엇을 듣는가

사람은 접시가 깨지는 소리를 들으면 물체를 보지 못했더라도 사건의 종류와 대략적인 방향을 추정한다. 반면 microphone은 우선 시간에 따른 압력 변화만 기록한다. Robot audition의 목적은 이 waveform에서 **사건, 위치, 개별 음원, 발화 내용**을 복원하는 것이다.

<figure id="speech-01-p08">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-08.png" | relative_url }}" alt="sound event detection, sound source localization, speech separation, speech recognition으로 구성된 robot audition 기술 지도" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=08" | relative_url }}">lecture PDF, p. 08</a>. 그림은 robot audition을 네 개의 서로 다른 질문으로 나눈다.</figcaption>
</figure>

### 1.1 네 과제는 같은 답을 내지 않는다

원본 slide의 장면에서는 사람이 “Hey Robot”이라고 부르고 개가 “Bowwow” 하고 짖는다. 로봇은 두 사건을 서로 다른 class와 방향으로 구분해야 한다.

- **Sound event detection:** speech와 dog bark가 언제 발생했는지 찾는다.
- **Sound source localization:** 사람의 음성과 개 짖는 소리가 어느 방향에서 왔는지 찾는다.
- **Speech separation:** 여러 speech source가 겹치면 화자별 signal로 나눈다.
- **Speech recognition:** “Hey Robot” 같은 speech를 text sequence로 바꾼다.

같은 구분을 일반화하면, 방 안에서 두 사람이 동시에 말하고 문이 닫히는 장면에도 적용할 수 있다.

- **Sound event detection:** `speech`, `door slam`이 언제 발생했는지 찾는다.
- **Sound source localization:** 각 사건이 어느 방향 또는 위치에서 왔는지 찾는다.
- **Speech separation:** 겹친 두 화자의 mixture를 화자별 signal로 나눈다.
- **Speech recognition:** 분리한 speech를 text sequence로 바꾼다.

Detection 결과가 정확해도 위치를 알 수 없고, localization 결과가 정확해도 겹친 발화를 바로 읽을 수 있는 것은 아니다. 따라서 실제 system에서는 한 모듈의 오류가 다음 모듈로 전달될 수 있다. 반대로 detection이 관심 구간을 좁히거나 localization이 특정 방향의 signal을 강조하면 separation과 recognition을 도울 수도 있다.

### 1.2 입력과 출력으로 구분하기

| 과제 | 입력 예시 | 출력 예시 | 흔한 혼동 |
|---|---|---|---|
| Detection | single-channel spectrogram | `alarm: 1.2–2.7 s` | 위치를 직접 출력한다고 생각하는 것 |
| Localization | microphone-array signals | azimuth `35°` | 사건의 의미까지 안다고 생각하는 것 |
| Separation | two-speaker mixture | speaker A/B waveform | text를 바로 출력한다고 생각하는 것 |
| Recognition | speech features | “문을 열어 줘” | 여러 음원을 자동으로 분리한다고 생각하는 것 |

## 2. 실제 환경이 어려운 이유

실험실의 clean speech와 실제 robot audio 사이에는 큰 차이가 있다. 강의는 대표적인 방해 요소를 noise, simultaneous sound sources, moving source의 NLOS 전환, robot self-noise로 제시한다.

<figure id="speech-01-p09">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-09.png" | relative_url }}" alt="공사 소음, 동시에 발생하는 음원, NLOS 이동 음원, 로봇 자체 소음으로 정리된 실제 robot audition 문제" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=09" | relative_url }}">lecture PDF, p. 09</a>. 네 문제는 서로 독립적이지 않으며 실제 장면에서는 동시에 나타날 수 있다.</figcaption>
</figure>

### 2.1 Noise와 interfering source는 다르다

Construction noise처럼 목표가 아닌 넓은 background 성분은 target의 특징을 가린다. 동시에 말하는 다른 사람은 단순한 무작위 noise가 아니라 **구조를 가진 competing source**다. 두 경우 모두 signal-to-noise ratio를 낮출 수 있지만, 후자는 target과 유사한 speech structure를 가져 separation을 더 어렵게 만든다.

### 2.2 Robot self-noise는 sensor와 함께 움직인다

Wheel, motor, fan, joint에서 생기는 소리는 robot microphone과 가까우며 robot action에 따라 변한다. 고정된 background-noise model만으로 제거하기 어려운 이유다. Motor command나 motion state를 보조 정보로 이용할 수 있지만, 이 강의의 Introduction 슬라이드는 구체적인 suppression architecture나 성능 수치를 제공하지 않는다.

### 2.3 NLOS에서는 가장 빠른 경로가 곧바른 경로가 아닐 수 있다

Line of sight(LOS)는 source와 receiver 사이의 직접 경로가 가려지지 않은 상태다. Non-line of sight(NLOS)에서는 벽이나 장애물이 direct path를 막아 reflected or diffracted paths가 주된 관측이 될 수 있다. 이때 microphone에 먼저 도착한 강한 peak를 곧바로 source direction으로 해석하면 실제 위치와 어긋날 수 있다.

## 3. TDoA가 방향 단서를 만드는 원리

Sound source localization의 가장 기본적인 단서 중 하나는 두 microphone에 소리가 도착하는 시간 차이, 즉 **time difference of arrival(TDoA)**다. 같은 wavefront가 가까운 microphone에 먼저 도착하고 먼 microphone에 나중에 도착한다.

<figure id="speech-01-p11">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-11.png" | relative_url }}" alt="alarm, speech, clapping이 동시에 존재하는 환경에서 robust TDoA microphone pair를 시험하는 장면" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=11" | relative_url }}">lecture PDF, p. 11</a>. alarm·speech·clapping이 함께 있을 때 하나의 명확한 arrival peak를 얻기 어렵다는 점이 핵심이다.</figcaption>
</figure>

Far-field plane-wave model에서 microphone 간격을 $$d$$, sound speed를 $$c$$, broadside로부터의 입사각을 $$\theta$$라고 둔다. 또한 $$\tau_1$$과 $$\tau_2$$를 각 microphone의 arrival time, signed delay를 $$\Delta\tau=\tau_2-\tau_1$$로 정의한다. Microphone 2에 더 늦게 도착하면 $$\Delta\tau>0$$이다. 이 channel-order convention에서 geometric delay는 다음과 같다.

$$
\Delta \tau = \frac{d\sin\theta}{c}
$$

각 기호의 단위는 $$d\,[\mathrm{m}]$$, $$c\,[\mathrm{m/s}]$$, $$\Delta\tau\,[\mathrm{s}]$$, $$\theta\,[\mathrm{rad}]$$ 또는 degree다. Sampling rate가 $$f_s\,[\mathrm{sample/s}]$$이면 sample 단위 delay는

$$
\Delta n = f_s\Delta\tau
$$

다. 예를 들어 $$d=0.08\ \mathrm{m}$$, $$\theta=30^\circ$$, $$c=343\ \mathrm{m/s}$$, $$f_s=16{,}000\ \mathrm{Hz}$$로 가정하면

$$
\Delta \tau
=\frac{0.08\sin 30^\circ}{343}
\approx 116.6\ \mu\mathrm{s},
$$

$$
\Delta n
=16{,}000\times116.6\times10^{-6}
\approx 1.87\ \text{samples}.
$$

즉 두 channel의 특징이 약 1.87 samples만큼 어긋난다. 실제 system이 integer sample만 비교하면 정보가 거칠어지므로 cross-correlation의 peak를 보간하거나 frequency-domain phase difference를 이용해 sub-sample delay를 추정한다.

$$\lvert\sin\theta\rvert\leq1$$이므로 물리적으로 가능한 delay는

$$
\lvert\Delta\tau\rvert\leq\frac{d}{c}
$$

다. 위 간격에서는 최대 약 $$233.2\ \mu\mathrm{s}$$다. 이 범위를 벗어난 peak는 direct-path far-field model과 맞지 않으며 reflection, wrong pairing, synchronization error를 의심해야 한다. 또한 microphone pair 하나는 같은 delay를 만드는 방향들을 완전히 구분하지 못한다. 2D에서는 대표적으로 front-back ambiguity가 남으므로 여러 microphone pair, array geometry, motion, vision 같은 추가 단서가 필요하다.

<details markdown="block">
<summary markdown="span">Derivation: Why microphone spacing becomes a time delay</summary>

Far-field source의 wavefront는 작은 microphone array에 거의 평면으로 도착한다고 본다. 두 microphone을 잇는 baseline 방향으로 source propagation vector를 signed projection하면 두 sensor 사이의 경로 차이는

$$
\Delta \ell=d\sin\theta
$$

가 된다. 거리와 시간은 $$\Delta\ell=c\Delta\tau$$ 관계를 가지므로

$$
\Delta\tau=\frac{\Delta\ell}{c}
=\frac{d\sin\theta}{c}
$$

를 얻는다. 이 유도에는 far-field, approximately constant sound speed, synchronized microphones, dominant direct path라는 가정이 들어간다. NLOS reflection, reverberation, array calibration error가 크면 같은 식으로 얻은 angle은 bias될 수 있다.

</details>

## 4. 반사 경로를 모델링하는 이유

<figure id="speech-01-p10">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-10.png" | relative_url }}" alt="장애물이 있는 공간에서 두 이동 음원과 반사 경로를 보여 주는 acoustic ray tracing 기반 localization demo" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=10" | relative_url }}">lecture PDF, p. 10</a>. 검은 구조물 주변의 경로는 direct path만으로 설명하기 어려운 NLOS 관측을 나타낸다.</figcaption>
</figure>

Acoustic ray tracing은 source에서 나온 sound propagation path가 벽과 장애물에서 어떻게 반사되는지 기하적으로 추적한다. 그림을 읽을 때는 세 요소를 분리해야 한다.

1. **실제 source trajectory:** 음원이 공간에서 움직인 경로다.
2. **Acoustic propagation paths:** source와 microphone 사이에 가능한 direct or reflected paths다.
3. **Estimated location:** algorithm이 observations에서 추정한 위치다.

그림에 경로가 보인다고 해서 실제 room impulse response의 모든 diffraction과 material absorption이 정확히 복원되었다는 뜻은 아니다. Ray model은 복잡한 propagation을 다룰 수 있는 구조적 가설이며, 성능 주장은 별도의 evaluation metric과 test condition이 있어야 판단할 수 있다.

Lecture 1의 demo 흐름은 localization에서 끝나지 않는다. NLOS clapping source의 위치를 추적한 뒤 robot navigation으로 연결한다. 필요한 변환은 다음과 같다.

```text
multichannel audio
  -> direction or spatial likelihood
  -> source position in a map coordinate system
  -> obstacle-aware navigation goal
  -> path planning and control
```

Audio coordinate, robot coordinate, map coordinate를 맞추는 calibration이 없으면 올바른 angle을 얻어도 잘못된 지점으로 이동할 수 있다.

## 5. Robot audition에서 multimodal spatial reasoning으로

Vision은 보이는 surface와 object를 풍부하게 표현하지만, camera 밖이나 wall 뒤의 사건은 직접 관찰하지 못한다. Audio는 source가 보이지 않아도 도착할 수 있으나 reflection 때문에 위치가 모호해질 수 있다. 두 modality는 서로를 대체하기보다 **서로 다른 ambiguity를 줄이는 관계**다.

<figure id="speech-01-p15">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-15.png" | relative_url }}" alt="여러 방으로 구성된 실제 환경에서 vision-only 공간 인식의 한계와 다양한 acoustic event를 보여 주는 그림" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=15" | relative_url }}">lecture PDF, p. 15</a>. 같은 건물에서도 room, wall, event 종류에 따라 관측 가능성이 달라진다.</figcaption>
</figure>

강의는 다음 네 방향을 제안한다.

<figure id="speech-01-p16">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-16.png" | relative_url }}" alt="audio spatial perception, temporal context, tactile spatial perception, context-adaptive understanding의 네 연구 방향" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=16" | relative_url }}">lecture PDF, p. 16</a>. 각 modality가 제공하는 단서와 해결하려는 실패 유형을 함께 읽어야 한다.</figcaption>
</figure>

| 연구 방향 | 문제 정의 | 추가되는 단서 | 기대 효과 |
|---|---|---|---|
| Audio spatial perception | camera에 보이지 않는 event | arrival time, direction, acoustic class | hidden or distant event awareness |
| Temporal context | 한 frame만으로 사건의 변화 파악이 어려움 | event history and sequence | 지속·반복·변화 구분 |
| Tactile spatial perception | 접촉과 힘의 상태가 시각에 충분히 드러나지 않음 | touch and force | manipulation state 이해 |
| Context-adaptive understanding | 환경이 바뀌면 고정 model의 해석이 어긋남 | room, task, history context | 상황에 맞는 inference |

여기서 “audio가 벽을 통과한다”를 “audio만 있으면 정확한 방 위치를 항상 안다”로 확대하면 안 된다. Audio는 visibility gap을 보완하지만 reverberation과 NLOS ambiguity를 함께 가져온다. 그래서 map, vision, motion history와의 fusion이 필요하다.

## 6. Multimodal encoder에서 3D semantic perception까지

<figure id="speech-01-p17">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-17.png" | relative_url }}" alt="audio tactile vision encoder가 multimodal large language model과 spatiotemporal 3D semantic perception으로 연결되는 연구 구조" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=17" | relative_url }}">lecture PDF, p. 17</a>. encoder, reasoning, spatial state update를 서로 다른 처리 단계로 읽는다.</figcaption>
</figure>

그림의 왼쪽 encoder들은 raw sensor data를 바로 문장으로 바꾸는 단일 block이 아니다. 각 modality의 구조를 feature로 요약한 뒤 multimodal reasoning에 전달한다.

- **Audio encoder:** event, spectral-temporal pattern, direction 단서를 표현한다.
- **Tactile encoder:** contact, pressure, slip 같은 local interaction을 표현한다.
- **Vision encoder:** object, geometry, appearance를 표현한다.
- **Multimodal LLM:** 표현 사이의 semantic relation을 추론하는 후보 중심부다.
- **Spatiotemporal 3D semantic perception:** 어떤 object or event가 어디에 있었고 어떻게 변했는지 state로 유지한다.
- **Semantic update and compression:** 장기 운용에서 모든 observation을 그대로 저장하지 않고 중요한 변화만 남긴다.

이 slide는 *on-going research* 방향을 나타낸다. 따라서 block diagram 자체는 완료된 system의 accuracy나 latency를 증명하지 않는다. “어떤 정보가 어느 block으로 흐르는가”와 “어떤 metric으로 검증해야 하는가”를 분리해서 읽어야 한다.

## 7. 시간 문맥은 왜 memory가 되는가

한 시점의 observation만 보면 cup이 table 위에 있다는 사실은 알 수 있지만, 누가 언제 옮겼는지는 알 수 없다. Temporal context는 observation sequence를 사건 단위 memory로 바꾸어 현재 장면의 원인을 추적하게 한다.

<figure id="speech-01-p18">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-18.png" | relative_url }}" alt="AV-LLM coarse memory와 LLM-based memory generator가 시간대별 사건을 episodic memory로 구성하는 구조" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=18" | relative_url }}">lecture PDF, p. 18</a>. 10 AM, 2 PM, 4 PM observation은 같은 장소의 상태가 시간에 따라 달라짐을 보여 준다.</figcaption>
</figure>

Coarse memory는 빠르게 요약한 scene-level state이고, episodic or fine memory는 특정 시간의 사건과 관계를 더 자세히 남기는 표현으로 읽을 수 있다. Slide의 glass cup example에는 object name과 material label이 서로 맞지 않는 draft-level contradiction이 있으므로 물성 정보로 받아들이지 않는다. 핵심은 시간, 사건, 위치, object change를 연결하는 memory schema다. 예를 들어 다음과 같이 정리할 수 있다.

```text
time: 14:00
event: glass impact sound
location: kitchen-side region
visual change: cup no longer on the table
confidence: audio 0.78, vision 0.64
```

이런 memory는 “현재 무엇이 보이는가”를 “이전에 무엇이 일어났는가”와 연결한다. 다만 Introduction slide는 memory generation의 loss function, dataset, hallucination control을 제시하지 않으므로 구현 세부를 확정된 사실처럼 채우지 않는다.

## 8. Perception에서 planning까지

<figure id="speech-01-p19">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-19.png" | relative_url }}" alt="auditory tactile vision input에서 robust multimodal perception, environment representation, adaptive robot planning으로 이어지는 전체 연구 흐름" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=19" | relative_url }}">lecture PDF, p. 19</a>. sensing, representation, planning을 하나의 인과 흐름으로 정리한 slide다.</figcaption>
</figure>

전체 연구 흐름은 세 층으로 나눌 수 있다.

1. **Robust multimodal spatiotemporal perception:** sensor noise와 missing observation이 있어도 event와 state를 추정한다.
2. **Global environment representation:** local observation을 map and memory에 정합한다.
3. **Adaptive robot planning:** 현재 state, uncertainty, goal을 바탕으로 행동을 선택한다.

Perception의 출력이 잘못되면 planning은 잘못된 state를 최적화할 수 있다. 따라서 planning 성능만 보고 perception을 평가하기보다 localization error, event detection accuracy, map consistency, task success를 함께 측정해야 한다.

<figure id="speech-01-p20">
  <img src="{{ "/assets/images/study/speech-and-audio-recognition/lecture-01/slide-20.png" | relative_url }}" alt="실내 공간에서 drone path planning과 장애물 회피를 보여 주는 그림" loading="lazy">
  <figcaption>Source: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf#page=20" | relative_url }}">lecture PDF, p. 20</a>. Drone example은 perception 결과가 motion planning으로 이어져야 한다는 응용 방향을 보여 준다.</figcaption>
</figure>

이 그림은 drone planning 응용을 보여 주지만, Lecture 1만으로 앞의 모든 audio and multimodal modules가 해당 drone을 end-to-end로 제어한다고 결론 내릴 수는 없다. Slide가 증명하는 범위와 연구 방향을 구분하는 것이 중요하다.

## 마지막 핵심 정리

- Robot audition은 event detection, localization, separation, recognition을 연결하는 acoustic perception 문제다.
- Real-world audio에서는 noise, competing sources, robot self-noise, reverberation, source motion, NLOS가 동시에 나타난다.
- TDoA는 microphone 사이의 path-length difference를 arrival-time difference로 바꾸는 방향 단서다.
- NLOS에서는 direct-path 가정이 무너져 reflection model, map context, multimodal fusion이 중요해진다.
- Audio는 vision의 blind spot을 보완하지만, spatial ambiguity가 없어지는 것은 아니다.
- Multimodal reasoning은 sensor feature를 semantic-spatial state와 temporal memory로 통합하는 방향이다.
- Planning은 perception의 다음 단계이며, block diagram은 empirical performance evidence와 구분해야 한다.

## Study Guide

| 구분 | 반드시 설명할 수 있어야 하는 것 | 점검 질문 |
|---|---|---|
| Problem | 여러 acoustic event와 NLOS가 있는 실제 환경 | clean-speech model이 왜 그대로 통하지 않는가? |
| Tasks | detection, localization, separation, recognition의 입출력 | 네 과제 중 어느 결과를 다음 module이 사용하는가? |
| Geometry | signed TDoA, channel order, broadside angle, physical bound | delay의 부호와 최대 크기를 설명할 수 있는가? |
| Robustness | noise, competing sources, self-noise, reflection | direct path가 사라지면 무엇이 잘못되는가? |
| Multimodality | audio, vision, tactile, temporal context의 상호 보완 | 한 modality의 ambiguity를 다른 modality가 어떻게 줄이는가? |
| System boundary | perception, memory, world representation, planning | 연구 방향과 검증된 성능을 구분했는가? |

## 복습 질문

<details markdown="block">
<summary markdown="span">Question 1: Detection and recognition</summary>

**질문:** Sound event detection과 speech recognition은 입력과 출력이 어떻게 다른가?

**답변:** Detection은 waveform or spectrogram에서 event class와 time interval을 찾는다. Recognition은 speech 구간의 acoustic sequence를 token or text sequence로 바꾼다. Detection이 “speech가 1.2–2.7초에 있었다”를 답한다면 recognition은 그 구간에서 “Hey Robot”이라는 내용을 답한다.

</details>

<details markdown="block">
<summary markdown="span">Question 2: TDoA assumptions and ambiguity</summary>

**질문:** 두 microphone 사이의 TDoA가 source angle과 연결되는 가정과 한계는 무엇인가?

**답변:** Synchronized microphones, known geometry, approximately constant sound speed, far-field plane wave, dominant direct path를 가정한다. Signed delay는 channel order에 따라 부호가 달라지고, $$\lvert\Delta\tau\rvert\leq d/c$$를 만족해야 한다. Microphone pair 하나만으로는 같은 delay를 만드는 front-back directions를 완전히 구분하지 못한다.

</details>

<details markdown="block">
<summary markdown="span">Question 3: NLOS localization</summary>

**질문:** Source가 NLOS로 이동하면 direct-path localization이 왜 bias될 수 있는가?

**답변:** Direct path가 막히면 reflection or diffraction path가 먼저 또는 더 강하게 관측될 수 있다. 그 arrival direction을 곧바로 physical source direction으로 해석하면 장애물이나 벽의 반사점 쪽으로 추정이 치우친다.

</details>

<details markdown="block">
<summary markdown="span">Question 4: Robot self-noise</summary>

**질문:** Robot self-noise와 stationary background noise의 차이는 무엇인가?

**답변:** Self-noise는 wheel, motor, fan, joint처럼 microphone 가까이에서 생기고 robot action에 따라 변한다. 따라서 고정된 noise profile만으로 처리하기 어렵고, motion state or motor command 같은 action context가 유용할 수 있다.

</details>

<details markdown="block">
<summary markdown="span">Question 5: Why multimodal perception?</summary>

**질문:** Audio와 vision을 결합하면 어떤 ambiguity가 줄고 어떤 ambiguity는 남는가?

**답변:** Audio는 camera 밖 event를 알려 주고 vision은 object and geometry를 제공한다. 하지만 NLOS reflection, sensor calibration error, temporal mismatch는 자동으로 사라지지 않는다. Fusion은 ambiguity를 줄이는 방법이지 무조건적인 정답 장치가 아니다.

</details>

<details markdown="block">
<summary markdown="span">Question 6: From perception to action</summary>

**질문:** Multimodal perception, environment representation, planning은 각각 무엇을 출력해야 하는가?

**답변:** Perception은 event and state estimate, representation은 map-aligned semantic memory, planning은 goal-directed action or trajectory를 출력한다. 각 단계의 error metric을 분리해야 어느 module이 task failure를 만들었는지 알 수 있다.

</details>

## PDF

- <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-01-introduction.pdf" | relative_url }}" target="_blank" rel="noopener">speech-audio-lecture-01-introduction.pdf</a>
