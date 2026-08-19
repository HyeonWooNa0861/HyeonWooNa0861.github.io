---
layout: default
title: "Stanford CS236 Lecture 1: Introduction"
course: "CS236"
topic: "Deep Generative Models Overview"
order: 1
major_topic: "Deep Generative Models"
keywords:
  - "Generative Modeling"
  - "Probability Distribution"
  - "Data Simulator"
  - "Conditional Generation"
  - "Diffusion Models"
---

# Stanford CS236 Lecture 1: Introduction

## Source

- Video: [Stanford CS236 Lecture 1](https://www.youtube.com/watch?v=XZ0PMRWXBEU){:target="_blank" rel="noopener"}
- Source Slides: [cs236_lecture1_2023.pptx](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture1_2023.pptx){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 생성 모델의 문제의식 | 복잡한 이미지, 언어, 음성, 행동을 "이해한다"는 말을 생성 관점에서 어떻게 해석할 수 있는가? |
| 2 | 통계적 생성 모델 | 생성 모델을 왜 확률분포 \(p(x)\) 또는 data simulator로 볼 수 있는가? |
| 3 | 조건부 생성 | caption, measurement, low-resolution signal 같은 control signal은 생성 과정을 어떻게 조종하는가? |
| 4 | 주요 응용 | 이미지, inverse problem, audio, language, code, video, robotics, molecule generation은 같은 틀로 어떻게 묶이는가? |
| 5 | 위험과 책임 | deepfake와 synthetic content는 왜 생성 모델의 성능뿐 아니라 사용 맥락까지 요구하는가? |
| 6 | 수업 로드맵 | representation, learning, inference라는 세 축이 이후 모델군과 어떻게 연결되는가? |

## 핵심 내용

1강은 CS236 전체를 여는 강의로, deep generative model을 단순한 이미지 생성 도구가 아니라 복잡한 데이터 분포를 모델링하는 통계적 방법으로 정의한다. 강의의 출발점은 computer vision, NLP, robotics, computational speech가 모두 high-dimensional unstructured input을 이해해야 한다는 점이다. 이미지가 컴퓨터에는 숫자 행렬이고, 문장이 문자 또는 token sequence라면, "이해"란 그 숫자와 sequence 뒤에 있는 구조를 파악하는 일이다.

강의는 Feynman의 "만들 수 없는 것은 이해하지 못한다"는 관점을 생성 모델의 철학으로 바꾼다. 어떤 시스템이 자연스러운 문장, 이미지, 음성, 행동을 만들어 낼 수 있다면, 그 시스템은 적어도 데이터가 어떤 구조를 가져야 하는지 일부를 배운 것이다. 이 말은 생성이 곧 완전한 인간적 이해라는 뜻은 아니다. 하지만 좋은 생성 결과를 내려면 문법, object relation, physical plausibility, style, context 같은 제약을 어느 정도 내재화해야 하므로, 생성은 표현 학습과 의사결정 문제로 이어진다.

통계적 생성 모델의 핵심 객체는 확률분포 \(p(x)\)다. 여기서 \(x\)는 이미지, 문장, 음성 신호, 행동 trajectory, molecule structure처럼 복잡한 데이터일 수 있다. 모델은 어떤 \(x\)가 그럴듯한지 확률값으로 평가하고, \(p(x)\)에서 sampling하여 새로운 \(x\)를 만든다. 따라서 생성 모델은 데이터가 입력으로만 주어지는 전통적 supervised learning과 달리, 데이터를 출력으로 만드는 simulator처럼 동작한다.

이 simulator는 순수한 규칙 기반 graphics engine과 다르다. Computer graphics는 물리, 재질, 조명, 렌더링 방정식 같은 strong prior를 많이 사용한다. CS236이 다루는 statistical generative model은 더 data-driven하다. 물론 prior가 사라지는 것은 아니다. 아키텍처, loss function, optimizer, 변수 분해 방식, sampling procedure 모두 prior다. 차이는 사람이 직접 scene rule을 모두 쓰기보다, 대규모 데이터와 신경망을 통해 그 구조를 학습한다는 데 있다.

조건부 생성은 이 강의에서 반복되는 중요한 관점이다. 무조건 \(p(x)\)에서 sampling하는 것보다 \(p(x \mid y)\)처럼 control signal \(y\)를 주면 원하는 결과를 더 정확히 만들 수 있다. Text-to-image에서는 \(y\)가 caption이고, image super-resolution에서는 \(y\)가 low-resolution image이며, CT reconstruction에서는 \(y\)가 sparse measurement다. Machine translation에서는 source language sentence가 조건이고 target language sentence가 출력이다. 즉 "생성"은 무작위로 새 데이터를 만드는 일만이 아니라, 관측된 단서에 맞춰 가능한 데이터를 완성하는 일이다.

응용 사례는 매우 넓다. 이미지 쪽에서는 GAN과 diffusion model의 발전으로 realistic face, text-to-image, editing, inpainting, colorization, super-resolution이 가능해졌다. Audio에서는 WaveNet과 diffusion-based speech model이 text-to-speech와 audio super-resolution을 개선했다. Language에서는 autoregressive model이 prompt를 이어 쓰고, code generation에서는 자연어 설명을 프로그램으로 바꾼다. Video generation은 이미지 생성의 시간 축 확장으로 볼 수 있고, imitation learning은 과거 관측에서 미래 행동 sequence를 생성하는 문제로 볼 수 있다. Molecule generation은 원하는 성질을 가진 구조를 찾는 과학·공학 문제로 연결된다.

마지막으로 강의는 기술의 양면성을 짚는다. 생성 모델이 실제와 구분하기 어려운 얼굴, 음성, 영상, 문서를 만들 수 있다는 것은 창작과 과학에는 큰 가능성이지만, deepfake와 misinformation 같은 위험도 함께 만든다. 따라서 이 수업의 목표는 최신 시스템을 표면적으로 사용하는 법보다, 어떤 모델링 가정이 결과를 만들고 어떤 실패 가능성을 남기는지 이해하는 데 있다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Statistical generative model | 데이터 공간 위의 확률분포 \(p(x)\)를 학습하고, likelihood 평가와 sampling을 통해 새 데이터를 만드는 모델이다. |
| Data simulator | 학습된 분포를 사용해 가능한 data point를 생성하는 관점이다. 실제 세계의 data-generating process를 근사하려는 목표를 강조한다. |
| Prior knowledge | 아키텍처, loss, optimizer, factorization, 변수 타입 가정처럼 모델이 데이터 이전에 갖는 구조적 선택이다. |
| Conditional generation | \(p(x \mid y)\)처럼 조건 \(y\)를 주어 생성 과정을 조종하는 방식이다. Caption, sketch, measurement, source sentence 등이 조건이 될 수 있다. |
| Inverse problem | 손상되거나 부분적인 관측에서 원래 신호를 복원하는 문제다. Inpainting, colorization, super-resolution, CT reconstruction이 포함된다. |
| Representation | 데이터의 고차원 관측값을 의미 있는 feature 또는 latent factor로 바꾸는 내부 구조다. 좋은 생성 모델은 이 표현을 암묵적으로 배운다. |
| Learning | 데이터 분포와 모델 분포를 가깝게 만들기 위해 어떤 loss 또는 divergence를 최적화할지 정하는 단계다. |
| Inference | 학습된 모델에서 sampling하거나, 관측값으로부터 latent variable이나 missing value를 추론하는 단계다. |

## 학습 포인트

- 생성 모델은 "그럴듯한 결과를 만든다"에서 끝나지 않고, 데이터가 어떤 확률 구조를 가지는지 모델링하는 문제다.
- \(p(x)\)를 직접 또는 간접적으로 표현하면 generation, density estimation, anomaly detection, representation learning을 같은 틀에서 볼 수 있다.
- Control signal을 넣으면 생성 모델은 image editing, translation, reconstruction처럼 조건부 문제를 풀 수 있다.
- 동일한 모델링 원리는 이미지, 텍스트, 음성, 비디오, 행동, 분자 구조처럼 서로 다른 modality에도 적용된다.
- 수업 전체는 representation, learning, inference의 세 질문으로 돌아간다. 어떤 분포를 어떻게 표현하는가, 어떤 기준으로 학습하는가, 어떻게 효율적으로 샘플링하거나 역추론하는가가 핵심이다.
- Autoregressive model, flow, latent variable model, GAN, energy-based model, score-based diffusion model은 이 세 질문에 대한 서로 다른 답이다.

## 마지막 핵심 정리

이 강의의 핵심은 deep generative model을 확률분포 \(p(x)\)를 학습하는 data simulator로 보는 것이다. 좋은 생성 모델은 새 데이터를 만들 뿐 아니라, 어떤 입력이 자연스러운지 평가하고, 누락된 정보를 채우고, 조건에 맞는 출력을 만들며, 데이터 내부 표현을 배운다. 이후 강의에서 등장하는 모든 모델군은 "고차원 분포를 compact하게 표현하고, 데이터로 학습하고, 필요한 출력을 추론한다"는 같은 문제를 서로 다른 방식으로 푼다.

## Study Guide

1. 먼저 생성 모델을 이미지 생성 예시로만 보지 말고 \(p(x)\), \(p(x \mid y)\), sampling, likelihood라는 네 단어로 다시 정의한다.
2. Graphics engine과 statistical generative model을 비교한다. 전자는 강한 물리 prior를 직접 넣고, 후자는 데이터와 비교적 약한 구조적 prior로 분포를 학습한다.
3. Text-to-image, CT reconstruction, machine translation을 모두 conditional generation으로 묶어 본다.
4. Representation, learning, inference가 각각 어떤 질문인지 외운 뒤, 뒤 강의의 모델군을 이 세 축에 배치한다.
5. Deepfake 논의는 부가 윤리 주제가 아니라, 모델이 실제 데이터 분포를 얼마나 잘 모사하는지와 직접 연결된 사회적 결과로 이해한다.

## 복습 질문

<details>
<summary>1. CS236에서 생성 모델을 data simulator로 부르는 이유는 무엇인가?</summary>

답변: 학습된 생성 모델은 기존 데이터를 단순히 분류하는 것이 아니라, 데이터가 나올 법한 확률분포를 근사한 뒤 그 분포에서 새로운 sample을 만든다. 그래서 실제 data-generating process를 흉내 내는 simulator처럼 볼 수 있다.

</details>

<details>
<summary>2. \(p(x)\)를 학습하면 generation 외에 어떤 작업을 할 수 있는가?</summary>

답변: 특정 입력 \(x\)의 확률을 평가해 density estimation이나 anomaly detection을 할 수 있고, 데이터가 공유하는 구조를 학습해 representation learning에도 사용할 수 있다. 조건부 분포를 만들면 missing value 복원이나 편집도 가능하다.

</details>

<details>
<summary>3. Conditional generation에서 control signal은 어떤 역할을 하는가?</summary>

답변: Control signal은 생성될 결과가 따라야 할 조건을 제공한다. Caption은 원하는 이미지 의미를 정하고, low-resolution image는 super-resolution의 단서가 되며, source sentence는 translation의 조건이 된다.

</details>

<details>
<summary>4. Graphics 기반 생성과 statistical generative model의 차이는 무엇인가?</summary>

답변: Graphics는 조명, 물리, 재질, geometry 같은 prior를 사람이 명시적으로 많이 설계한다. Statistical generative model은 데이터에서 분포를 학습하며, prior는 주로 모델 구조, loss, optimizer, sampling 방법의 형태로 들어간다.

</details>

<details>
<summary>5. 1강의 수업 로드맵에서 representation, learning, inference는 각각 무엇을 묻는가?</summary>

답변: Representation은 고차원 joint distribution을 어떻게 compact하게 표현할지 묻는다. Learning은 데이터 분포와 모델 분포를 어떤 기준으로 가깝게 만들지 묻는다. Inference는 학습된 모델로 어떻게 sample을 만들거나 latent structure를 추론할지 묻는다.

</details>

<details>
<summary>6. 생성 모델의 사회적 위험이 기술적 이해와 분리될 수 없는 이유는 무엇인가?</summary>

답변: 모델이 실제와 구분하기 어려운 이미지, 음성, 영상을 만들수록 창작과 복원에는 도움이 되지만 deepfake와 misinformation 위험도 커진다. 어떤 데이터와 prior가 어떤 출력을 가능하게 하는지 이해해야 책임 있는 사용과 평가가 가능하다.

</details>

## Slides

- [Official Lecture 1 slide deck](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture1_2023.pptx){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 course website](https://deepgenerativemodels.github.io/){:target="_blank" rel="noopener"}
- [Official video](https://www.youtube.com/watch?v=XZ0PMRWXBEU){:target="_blank" rel="noopener"}
- [Official slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture1_2023.pptx){:target="_blank" rel="noopener"}
- [Official course notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
