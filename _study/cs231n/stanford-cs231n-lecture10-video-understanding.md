---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 10: Video Understanding"
course: "CS231N"
topic: "Video Understanding"
order: 10
major_topic: "Computer Vision"
keywords:
  - "Video Understanding"
  - "Temporal Modeling"
  - "Optical Flow"
  - "Action Recognition"
  - "Spatiotemporal Features"
---

# Stanford CS231N Lecture 10: Video Understanding

Source: [Stanford CS231N Spring 2025 Lecture 10](https://www.youtube.com/watch?v=wElqklprhPE){:target="_blank" rel="noopener"}

> **핵심:** 비디오는 단순히 이미지가 여러 장 모인 입력이 아니다. 정적 장면 단서가 강할 때는 프레임별 CNN도 훌륭한 기준선이지만, 행동의 방향과 순서를 구분하려면 특징을 **언제, 어느 깊이에서 시간축으로 결합할지** 설계해야 한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Video as space-time data | 긴 비디오를 어떻게 학습 가능한 clip으로 바꾸는가? |
| 2 | Temporal fusion | Single-frame, late, early, slow fusion은 무엇이 다른가? |
| 3 | 3D CNN and recurrent models | 시간 정보를 연산 자체에 어떻게 넣는가? |
| 4 | Motion and scale | 움직임 단서와 대규모 데이터셋은 왜 중요한가? |
| 5 | Multisensory video | 영상과 소리를 함께 보면 무엇을 더 알 수 있는가? |
| 6 | Global context and efficiency | Non-local block과 X3D는 무엇을 개선하는가? |

## 1. 비디오는 공간에 시간이 추가된 데이터다

RGB 이미지를 \(3\times H\times W\) 텐서로 본다면 비디오는 \(3\times T\times H\times W\)의 시공간 볼륨이다. 분류 손실 자체는 이미지 분류와 비슷하게 쓸 수 있지만, 입력 특징을 만드는 비용과 문제의 성격이 달라진다. 이미지가 객체·장면을 주로 묻는다면 비디오는 달리기, 수영, 점프처럼 **행동과 사건**을 자주 묻는다.

원시 비디오는 저장량과 GPU 메모리 부담이 크다. 해법은 공간 해상도와 frame rate를 낮추고, 긴 영상을 짧은 clip으로 잘라 학습하는 것이다. 추론 시 여러 clip의 예측을 평균하면 긴 영상의 결정을 만들 수 있다. 따라서 프레임·clip 샘플링은 단순 전처리가 아니라 어떤 장면을 모델이 보게 할지 결정하는 모델링 요소다.

## 2. 시간 정보를 결합하는 네 가지 기준선

| 방식 | 결합 위치 | 장점 | 놓치기 쉬운 정보 |
|---|---|---|---|
| Single-frame CNN | 각 프레임의 최종 예측 평균 | 싸고 강한 기준선 | 움직임의 방향과 순서 |
| Late fusion | 프레임별 고수준 특징 뒤 | 사전학습 2D CNN 활용이 쉬움 | 낮은 수준의 짧은 움직임 |
| Early fusion | 입력 채널 쪽에서 여러 프레임 결합 | 초반부터 국소 시간 변화 포착 | 긴 시간 구조 |
| Slow fusion | 네트워크 깊이에 따라 점진적 결합 | 공간·시간 수용영역을 함께 확대 | 구현·계산 복잡도 |

정적 배경이나 물체가 행동을 강하게 암시하면 single-frame CNN도 좋은 성능을 낼 수 있다. 따라서 새 비디오 모델을 설계하기 전에 반드시 이 기준선을 실행해야 한다. 반대로 앞뒤 순서가 의미를 바꾸는 행동은 프레임 평균만으로 구분하기 어렵다.

## 3. 2D convolution에서 3D convolution으로

2D kernel이 \(K_h\times K_w\) 공간만 훑는다면 3D kernel은 \(K_t\times K_h\times K_w\)로 시간축까지 훑는다. 출력 위치 하나는 주변 픽셀뿐 아니라 인접 프레임의 패턴에도 반응한다. 여러 층을 쌓으면 시간 수용영역이 커져 짧은 움직임에서 더 긴 행동 단위로 올라간다.

3D CNN의 대가는 계산량과 데이터 요구량이다. 2D 이미지 모델의 kernel을 시간축으로 복제해 초기화하는 **inflation**은 이미지 사전학습의 이점을 비디오로 옮기는 실용적 연결고리다. 강의의 I3D 논의도 이 아이디어에 기반한다.

I3D는 2D kernel을 시간축으로 \(K_t\)번 복사하고 \(K_t\)로 나눠 초기화한다. 그러면 같은 frame이 반복된 video를 넣었을 때 원래 2D network와 같은 출력을 유지하면서 image-pretrained weight를 재사용할 수 있다. 여기에 **non-local block**을 독립 모듈로 삽입하면 query-key attention으로 멀리 떨어진 시공간 위치의 value를 한 번에 집계한다. Local 3D convolution의 수용영역을 층층이 넓히는 방식과 달리, block 하나가 전체 space-time feature 사이의 관계를 연결한다.

## 4. 공간과 시간을 분리하거나 순차적으로 모델링하기

Two-stream 접근은 RGB의 appearance stream과 optical flow의 motion stream을 따로 처리한 뒤 결합한다. Optical flow는 인접 프레임 사이의 픽셀 이동을 명시적으로 제공하므로, 배경보다 움직임이 중요한 행동을 보완한다. 다만 flow 계산이 별도 비용이고 end-to-end 단순성이 떨어진다.

또 다른 선택은 각 프레임의 CNN 특징을 RNN/LSTM에 순서대로 넣는 것이다. 상태 갱신을 \(h_t=f(h_{t-1},x_t)\)로 보면 현재 프레임 \(x_t\)와 이전 문맥 \(h_{t-1}\)이 합쳐진다. 긴 순서를 표현할 수 있지만 순차 계산 때문에 병렬화가 어렵고, 실제 성능은 특징 추출과 샘플링 품질에 크게 의존한다.

## 5. 데이터 규모와 비디오가 주는 추가 감각

Sports-1M과 Kinetics 같은 대규모 행동 데이터셋은 3D 모델 학습을 가능하게 했다. 비디오는 중복이 많지만 annotation과 저장·전송 비용도 크다. 결과를 비교할 때는 모델 이름만이 아니라 clip 길이, frame rate, crop 수, test-time sampling을 함께 봐야 한다.

마지막에는 audio-visual 학습으로 범위를 넓힌다. 같은 장면의 소리는 보이지 않는 사건이나 소리의 위치를 알려주는 동기화된 학습 신호가 된다. 이는 비디오 이해가 시각 프레임만의 문제가 아니라 여러 감각을 정렬하는 문제로 확장됨을 보여준다.

효율화는 clip model과 long-video sampling 두 층에서 일어난다. **X3D**는 더 나은 3D CNN으로 clip 하나의 계산 효율을 높이는 방향이고, selective sampler는 긴 영상의 모든 clip을 처리하지 않고 중요한 구간만 골라 video-level 예측을 합친다. 강의는 audio를 preview signal로 쓰거나, 상황에 따라 video clip 수와 사용할 modality를 policy가 선택하는 접근도 함께 제시한다.

## 마지막 핵심 정리

- **먼저 single-frame 기준선**을 세워 정적 단서만으로 풀리는 정도를 확인한다.
- 시간 모델의 차이는 결국 **결합 시점과 시간 수용영역**의 차이다.
- 3D CNN은 시공간 패턴을 직접 학습하지만 계산량과 데이터 규모가 커진다.
- Non-local block은 전역 시공간 관계를 직접 집계하고, X3D와 selective sampling은 각각 clip과 long-video 수준의 비용을 줄인다.
- Optical flow, recurrent state, audio는 RGB가 놓치는 움직임·순서·사건 단서를 보완한다.

## Study Guide

`single frame → fusion → 3D convolution → two-stream/RNN → multisensory` 순으로 비교한다. 시험에서는 early/late/slow fusion의 결합 위치, 2D와 3D kernel의 차원, clip sampling이 평가 결과에 미치는 영향을 설명할 수 있어야 한다.

## 복습 질문

<details><summary>1. 왜 single-frame CNN이 비디오 분류의 중요한 기준선인가?</summary>

답변: 많은 행동 데이터에서 물체, 자세, 배경만으로도 범주가 강하게 암시되기 때문이다. 시간 모델의 진짜 이득을 판단하려면 이 값싼 기준선보다 무엇을 더 해결했는지 비교해야 한다.
</details>

<details><summary>2. 3D convolution은 2D convolution과 무엇이 다른가?</summary>

답변: kernel에 시간 크기 \(K_t\)가 추가되어 인접 프레임의 공간 패턴을 동시에 합성곱한다. 따라서 특징 계층 자체가 움직임을 표현하지만 계산량도 증가한다.
</details>

<details><summary>3. 긴 비디오를 학습·평가할 때 clip sampling이 중요한 이유는?</summary>

답변: 전체 영상을 한 번에 GPU에 넣기 어렵고 행동이 일부 구간에만 나타날 수 있기 때문이다. 학습에서는 다양한 짧은 clip을 뽑고, 추론에서는 여러 clip의 예측을 통합한다.
</details>

## 참고자료

- [Lecture video and transcript source](https://www.youtube.com/watch?v=wElqklprhPE){:target="_blank" rel="noopener"}
