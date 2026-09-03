---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:52:00 +0900
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

> **핵심:** 1강은 CS236 전체를 여는 강의로, deep generative model을 단순한 이미지 생성 도구가 아니라 복잡한 데이터 분포를 모델링하는 통계적 방법으로 정의한다. 강의의 출발점은 computer vision, NLP, robotics, computational speech가 모두 high-dimensional unstructured input을 이해해야 한다는 점이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 생성 모델의 문제의식 | 복잡한 이미지, 언어, 음성, 행동을 "이해한다"는 말을 생성 관점에서 어떻게 해석할 수 있는가? |
| 2 | 통계적 생성 모델 | 생성 모델을 왜 확률분포 $$p(x)$$ 또는 data simulator로 볼 수 있는가? |
| 3 | 조건부 생성 | caption, measurement, low-resolution signal 같은 control signal은 생성 과정을 어떻게 조종하는가? |
| 4 | 주요 응용 | 이미지, inverse problem, audio, language, code, video, robotics, molecule generation은 같은 틀로 어떻게 묶이는가? |
| 5 | 위험과 책임 | deepfake와 synthetic content는 왜 생성 모델의 성능뿐 아니라 사용 맥락까지 요구하는가? |
| 6 | 수업 로드맵 | representation, learning, inference라는 세 축이 이후 모델군과 어떻게 연결되는가? |

### 원문 슬라이드 전수 대조

| 공식 PPTX 범위 | 대조한 내용 | 수식·증명 판단 |
|---|---|---|
| slides 1–12 | 생성 모델 정의, probability distribution, simulator 관점 | 정의·개념 중심이며 별도 증명 대상 없음 |
| slides 13–15 | 생성, inverse problem, outlier detection 응용 | 사례·그림 중심이며 별도 증명 대상 없음 |
| slides 16–19 | joint/conditional distribution, Bayes rule, conditional generation | slides 16–17의 핵심 식과 missing-data 함의를 아래에서 유도·구분 |
| slides 20–44 | image, audio, language, code, video, robotics, molecule, deepfake 사례 | 결과·사례 중심이며 별도 증명 대상 없음 |
| slides 45–50 | course roadmap, prerequisite, logistics, project | slide 45의 학습 목표를 아래 작성자 보충으로 명시; 나머지는 운영 정보 |

> **PPTX viewer 한계:** 이번 독립 감사에서는 공식 PPTX의 50개 slide XML text와 순서를 모두 대조했지만, 로컬 Quick Look renderer가 sandbox 정책으로 실행되지 않아 animation/build layer를 포함한 시각 재현은 독립적으로 완료하지 못했다. 기존 편집 기록의 Office Viewer 확인은 참고 증거이며, 외부 viewer는 animation 단계나 slide ID를 다르게 처리할 수 있다. 따라서 이 글은 원문에 실제로 있는 slides 16–17의 식과 slide 45의 도식을 구분하고, 추가 전개는 명시적으로 작성자 보충으로 표시한다.

## 핵심 내용

1강은 CS236 전체를 여는 강의로, deep generative model을 단순한 이미지 생성 도구가 아니라 복잡한 데이터 분포를 모델링하는 통계적 방법으로 정의한다. 강의의 출발점은 computer vision, NLP, robotics, computational speech가 모두 high-dimensional unstructured input을 이해해야 한다는 점이다. 이미지가 컴퓨터에는 숫자 행렬이고, 문장이 문자 또는 token sequence라면, "이해"란 그 숫자와 sequence 뒤에 있는 구조를 파악하는 일이다.

강의는 Feynman의 "만들 수 없는 것은 이해하지 못한다"는 관점을 생성 모델의 철학으로 바꾼다. 어떤 시스템이 자연스러운 문장, 이미지, 음성, 행동을 만들어 낼 수 있다면, 그 시스템은 적어도 데이터가 어떤 구조를 가져야 하는지 일부를 배운 것이다. 이 말은 생성이 곧 완전한 인간적 이해라는 뜻은 아니다. 하지만 좋은 생성 결과를 내려면 문법, object relation, physical plausibility, style, context 같은 제약을 어느 정도 내재화해야 하므로, 생성은 표현 학습과 의사결정 문제로 이어진다.

통계적 생성 모델의 핵심 객체는 확률분포 $$p(x)$$다. 여기서 $$x$$는 이미지, 문장, 음성 신호, 행동 trajectory, molecule structure처럼 복잡한 데이터일 수 있다. 모델은 어떤 $$x$$가 그럴듯한지 확률값으로 평가하고, $$p(x)$$에서 sampling하여 새로운 $$x$$를 만든다. 따라서 생성 모델은 데이터가 입력으로만 주어지는 전통적 supervised learning과 달리, 데이터를 출력으로 만드는 simulator처럼 동작한다.

이 simulator는 순수한 규칙 기반 graphics engine과 다르다. Computer graphics는 물리, 재질, 조명, 렌더링 방정식 같은 strong prior를 많이 사용한다. CS236이 다루는 statistical generative model은 더 data-driven하다. 물론 prior가 사라지는 것은 아니다. 아키텍처, loss function, optimizer, 변수 분해 방식, sampling procedure 모두 prior다. 차이는 사람이 직접 scene rule을 모두 쓰기보다, 대규모 데이터와 신경망을 통해 그 구조를 학습한다는 데 있다.

조건부 생성은 이 강의에서 반복되는 중요한 관점이다. 무조건 $$p(x)$$에서 sampling하는 것보다 $$p(x \mid y)$$처럼 control signal $$y$$를 주면 원하는 결과를 더 정확히 만들 수 있다. Text-to-image에서는 $$y$$가 caption이고, image super-resolution에서는 $$y$$가 low-resolution image이며, CT reconstruction에서는 $$y$$가 sparse measurement다. Machine translation에서는 source language sentence가 조건이고 target language sentence가 출력이다. 즉 "생성"은 무작위로 새 데이터를 만드는 일만이 아니라, 관측된 단서에 맞춰 가능한 데이터를 완성하는 일이다.

응용 사례는 매우 넓다. 이미지 쪽에서는 GAN과 diffusion model의 발전으로 realistic face, text-to-image, editing, inpainting, colorization, super-resolution이 가능해졌다. Audio에서는 WaveNet과 diffusion-based speech model이 text-to-speech와 audio super-resolution을 개선했다. Language에서는 autoregressive model이 prompt를 이어 쓰고, code generation에서는 자연어 설명을 프로그램으로 바꾼다. Video generation은 이미지 생성의 시간 축 확장으로 볼 수 있고, imitation learning은 과거 관측에서 미래 행동 sequence를 생성하는 문제로 볼 수 있다. Molecule generation은 원하는 성질을 가진 구조를 찾는 과학·공학 문제로 연결된다.

마지막으로 강의는 기술의 양면성을 짚는다. 생성 모델이 실제와 구분하기 어려운 얼굴, 음성, 영상, 문서를 만들 수 있다는 것은 창작과 과학에는 큰 가능성이지만, deepfake와 misinformation 같은 위험도 함께 만든다. 따라서 이 수업의 목표는 최신 시스템을 표면적으로 사용하는 법보다, 어떤 모델링 가정이 결과를 만들고 어떤 실패 가능성을 남기는지 이해하는 데 있다.

### 원문 수식 감사: joint와 conditional, missing data

> **근거 위치:** 공식 Lecture 1 PPTX slides 16–17. PPTX XML에서 conditional/joint notation과 Bayes-rule fraction을 대조했다. Animation 단계에 따라 fraction 일부가 외부 viewer에서 달리 보일 수 있다. 아래 marginalization은 slide 17의 missing-data 주장을 풀어 쓴 작성자 보충이다.

> **슬라이드 원문 정리:** Lecture 1의 discriminative/generative 비교에서 conditional과 joint는 Bayes rule로 정확히 연결된다.

$$
p(y\mid x)=\frac{p(x,y)}{p(x)},
\qquad
p(x,y)=p(y\mid x)p(x)=p(x\mid y)p(y).
$$

Discriminative model은 입력 $$x$$가 주어진 prediction에 필요한 $$p(y\mid x)$$를 바로 모델링한다. Generative classifier는 $$p(x,y)$$ 또는 $$p(y)p(x\mid y)$$를 모델링하므로 $$p(x)$$까지 포함한다. 위 식은 $$p(x)>0$$인 지지집에서의 **정확한 확률 항등식**이며, 확률과 label은 무차원이다. $$x$$의 좌표가 물리 단위를 가진 continuous variable이면 density는 그 좌표 단위의 역수를 가지지만, density ratio인 conditional probability는 무차원이다.

> **작성자 보충:** $$x=(x_{\mathrm{obs}},x_{\mathrm{mis}})$$로 나누면 joint model은 관측되지 않은 변수를 소거해 분류할 수 있다. Discrete missing variable에서는

$$
p(y\mid x_{\mathrm{obs}})
=
\frac{\sum_{x_{\mathrm{mis}}}p(y,x_{\mathrm{obs}},x_{\mathrm{mis}})}
{\sum_{y'}\sum_{x_{\mathrm{mis}}}p(y',x_{\mathrm{obs}},x_{\mathrm{mis}})}.
$$

Continuous missing variable이면 합을 적분으로 바꾼다. 이는 분모가 0이 아니고 joint model이 정규화되어 있다는 가정 아래 **정확한 marginalization**이다. 반면 완전한 $$x$$만 받도록 학습한 $$p(y\mid x)$$만으로는 이 합의 항들을 계산할 수 없다. 별도 imputation, missingness mask 학습, 또는 partial-input conditional model을 두면 예외적으로 처리할 수 있지만, joint model의 자동적 능력은 아니다. Joint 가정이 틀리거나 missingness 기제가 학습 분포와 다르면 이 추론도 실패한다.

### Data distribution에서 model distribution을 학습하는 목적 (작성자 보충)

> **Source mapping:** Official Lecture 1 PPTX slide 45의 representation·learning·inference roadmap에 대응한다. 아래 $$P_{\mathrm{data}}$$, model family, discrepancy 최적화 표기는 그 roadmap의 “분포를 비교해 학습한다”는 목적을 수학적으로 명확히 쓴 **작성자 보충**이며, slide 45에 동일한 완성 식이 인쇄되어 있다는 뜻은 아니다. 추상적인 $$d$$에 대해 존재하지 않는 보편 증명을 주장하지 않는다.

데이터 공간을 $$\mathcal X\subseteq\mathbb R^d$$, model parameter를 $$\theta\in\mathcal M\subseteq\mathbb R^q$$라 하자. $$P_{\mathrm{data}}$$는 실제 data-generating distribution이고, $$\{P_\theta:\theta\in\mathcal M\}$$은 선택한 representation이 표현할 수 있는 model family다. Population 수준의 이상적인 학습 목표는

$$
\theta^*
\in
\operatorname*{arg\,min}_{\theta\in\mathcal M}
d\!\left(P_{\mathrm{data}},P_\theta\right)
$$

이다. 이 식은 “실제 분포와 model distribution 사이의 discrepancy를 가장 작게 만드는 parameter를 고른다”는 **설계 목적의 정의**다. $$\operatorname*{arg\,min}$$이 여러 원소를 가질 수 있으므로 $$\theta^*$$의 유일성을 자동으로 뜻하지 않는다.

실제로는 $$P_{\mathrm{data}}$$ 자체를 알 수 없고 유한한 i.i.d. sample

$$
x_1,\ldots,x_n\overset{\mathrm{i.i.d.}}{\sim}P_{\mathrm{data}}
$$

만 관측한다. Empirical distribution과 실제 training estimator를 각각

$$
\widehat P_n=\frac1n\sum_{i=1}^n\delta_{x_i},
\qquad
\widehat\theta_n
\in
\operatorname*{arg\,min}_{\theta\in\mathcal M}
\widehat d_n(\theta)
$$

로 쓸 수 있다. 문제에 따라 $$\widehat d_n(\theta)=d(\widehat P_n,P_\theta)$$를 직접 계산하기도 하지만, likelihood의 sample average, variational bound, adversarial critic, score-matching loss처럼 population discrepancy를 추정하거나 대신하는 surrogate를 쓰기도 한다. 특히 continuous density에 atomic empirical measure를 넣은 literal $$D_{\mathrm{KL}}(\widehat P_n\Vert P_\theta)$$는 일반적으로 적절하지 않다. Maximum likelihood는 대신

$$
\widehat d_n(\theta)
=-\frac1n\sum_{i=1}^n\log p_\theta(x_i)
$$

를 최소화하며, population에서는 $$\theta$$와 무관한 data entropy를 제외하고 forward KL 최소화와 연결된다. 따라서 $$\theta^*$$는 알 수 없는 population target이고, $$\widehat\theta_n$$은 sample과 optimization에 의존하는 **유한 표본 추정량**이다.

기호 $$d$$는 이름과 달리 반드시 metric일 필요가 없다. KL divergence는 비대칭이고 triangle inequality를 만족하지 않으며, Jensen–Shannon divergence나 total variation도 사용할 수 있다. GAN 계열에서는 함수족 $$\mathcal F$$가 정하는 integral probability metric을

$$
d_{\mathcal F}(P,Q)
=\sup_{f\in\mathcal F}
\left|\mathbb E_P[f(X)]-\mathbb E_Q[f(X)]\right|
$$

처럼 둘 수 있다. 어떤 discrepancy를 선택하는지는 mode coverage, sample quality, density evaluation처럼 model이 우선할 성질을 바꾼다.

이 목표가 population learning을 잘 근사하려면 sample이 실제 분포를 대표하는 i.i.d. 관측이어야 하고, empirical objective가 population objective에 충분히 수렴하며, 최적화가 유용한 해에 도달해야 한다. Model family가 너무 작으면 $$P_{\mathrm{data}}\notin\{P_\theta\}$$인 misspecification이 남고, 너무 크면 finite-sample overfitting이 생길 수 있다. 서로 다른 $$\theta$$가 같은 $$P_\theta$$를 만들면 parameter는 identifiable하지 않으며, discrepancy가 특정 mode를 약하게 벌주거나 inference algorithm이 학습된 분포를 제대로 탐색하지 못하면 objective 값이 좋아도 생성 결과가 나쁠 수 있다.

$$P$$와 사건의 probability는 무차원이다. Continuous density는 $$x$$의 좌표 volume에 대한 역단위를 가지지만, KL·Jensen–Shannon·total variation은 무차원이다. Wasserstein distance는 ground metric을 따르면 $$x$$와 같은 단위를 가지며, 일반 IPM의 단위는 critic output $$f(X)$$의 단위다. 따라서 slide의 추상적인 $$d$$에는 하나의 고정 단위를 부여할 수 없다. $$x\in\mathbb R^d$$와 $$\theta\in\mathbb R^q$$의 차원은 각각 data dimension과 parameter dimension이고, $$\theta$$의 물리 단위는 parameterization에 따라 달라진다.

이 그림은 수업의 세 축을 한 줄로 연결한다. **Representation**은 $$\mathcal M$$과 $$P_\theta$$의 factorization·density·sampler 형태를 정한다. **Learning**은 sample로부터 $$\widehat d_n$$을 최적화해 $$\widehat\theta_n$$을 고른다. **Inference**는 학습된 $$P_{\widehat\theta_n}$$에서 sampling하거나 likelihood, conditional distribution, latent variable을 계산한다. Representation이 실제 구조를 담지 못하면 learning의 최적해도 부족하고, inference가 부정확하면 잘 학습된 distribution도 원하는 출력으로 변환되지 않는다.

## 핵심 개념 표

| 개념 | 설명 |
|---|---|
| Statistical generative model | 데이터 공간 위의 확률분포 $$p(x)$$를 학습하고, likelihood 평가와 sampling을 통해 새 데이터를 만드는 모델이다. |
| Data simulator | 학습된 분포를 사용해 가능한 data point를 생성하는 관점이다. 실제 세계의 data-generating process를 근사하려는 목표를 강조한다. |
| Prior knowledge | 아키텍처, loss, optimizer, factorization, 변수 타입 가정처럼 모델이 데이터 이전에 갖는 구조적 선택이다. |
| Conditional generation | $$p(x \mid y)$$처럼 조건 $$y$$를 주어 생성 과정을 조종하는 방식이다. Caption, sketch, measurement, source sentence 등이 조건이 될 수 있다. |
| Inverse problem | 손상되거나 부분적인 관측에서 원래 신호를 복원하는 문제다. Inpainting, colorization, super-resolution, CT reconstruction이 포함된다. |
| Representation | 데이터의 고차원 관측값을 의미 있는 feature 또는 latent factor로 바꾸는 내부 구조다. 좋은 생성 모델은 이 표현을 암묵적으로 배운다. |
| Learning | 데이터 분포와 모델 분포를 가깝게 만들기 위해 어떤 loss 또는 divergence를 최적화할지 정하는 단계다. |
| Inference | 학습된 모델에서 sampling하거나, 관측값으로부터 latent variable이나 missing value를 추론하는 단계다. |

## 학습 포인트

- 생성 모델은 "그럴듯한 결과를 만든다"에서 끝나지 않고, 데이터가 어떤 확률 구조를 가지는지 모델링하는 문제다.
- $$p(x)$$를 직접 또는 간접적으로 표현하면 generation, density estimation, anomaly detection, representation learning을 같은 틀에서 볼 수 있다.
- Control signal을 넣으면 생성 모델은 image editing, translation, reconstruction처럼 조건부 문제를 풀 수 있다.
- 동일한 모델링 원리는 이미지, 텍스트, 음성, 비디오, 행동, 분자 구조처럼 서로 다른 modality에도 적용된다.
- 수업 전체는 representation, learning, inference의 세 질문으로 돌아간다. 어떤 분포를 어떻게 표현하는가, 어떤 기준으로 학습하는가, 어떻게 효율적으로 샘플링하거나 역추론하는가가 핵심이다.
- Autoregressive model, flow, latent variable model, GAN, energy-based model, score-based diffusion model은 이 세 질문에 대한 서로 다른 답이다.

## 마지막 핵심 정리

이 강의의 핵심은 deep generative model을 확률분포 $$p(x)$$를 학습하는 data simulator로 보는 것이다. 좋은 생성 모델은 새 데이터를 만들 뿐 아니라, 어떤 입력이 자연스러운지 평가하고, 누락된 정보를 채우고, 조건에 맞는 출력을 만들며, 데이터 내부 표현을 배운다. 이후 강의에서 등장하는 모든 모델군은 "고차원 분포를 compact하게 표현하고, 데이터로 학습하고, 필요한 출력을 추론한다"는 같은 문제를 서로 다른 방식으로 푼다.

## Study Guide

1. 먼저 생성 모델을 이미지 생성 예시로만 보지 말고 $$p(x)$$, $$p(x \mid y)$$, sampling, likelihood라는 네 단어로 다시 정의한다.
2. Graphics engine과 statistical generative model을 비교한다. 전자는 강한 물리 prior를 직접 넣고, 후자는 데이터와 비교적 약한 구조적 prior로 분포를 학습한다.
3. Text-to-image, CT reconstruction, machine translation을 모두 conditional generation으로 묶어 본다.
4. Representation, learning, inference가 각각 어떤 질문인지 외운 뒤, 뒤 강의의 모델군을 이 세 축에 배치한다.
5. Deepfake 논의는 부가 윤리 주제가 아니라, 모델이 실제 데이터 분포를 얼마나 잘 모사하는지와 직접 연결된 사회적 결과로 이해한다.

## 복습 질문

<details markdown="block">
<summary>1. CS236에서 생성 모델을 data simulator로 부르는 이유는 무엇인가?</summary>

답변: 학습된 생성 모델은 기존 데이터를 단순히 분류하는 것이 아니라, 데이터가 나올 법한 확률분포를 근사한 뒤 그 분포에서 새로운 sample을 만든다. 그래서 실제 data-generating process를 흉내 내는 simulator처럼 볼 수 있다.

</details>

<details markdown="block">
<summary markdown="span">2. $$p(x)$$를 학습하면 generation 외에 어떤 작업을 할 수 있는가?</summary>

답변: 특정 입력 $$x$$의 확률을 평가해 density estimation이나 anomaly detection을 할 수 있고, 데이터가 공유하는 구조를 학습해 representation learning에도 사용할 수 있다. 조건부 분포를 만들면 missing value 복원이나 편집도 가능하다.

</details>

<details markdown="block">
<summary>3. Conditional generation에서 control signal은 어떤 역할을 하는가?</summary>

답변: Control signal은 생성될 결과가 따라야 할 조건을 제공한다. Caption은 원하는 이미지 의미를 정하고, low-resolution image는 super-resolution의 단서가 되며, source sentence는 translation의 조건이 된다.

</details>

<details markdown="block">
<summary>4. Graphics 기반 생성과 statistical generative model의 차이는 무엇인가?</summary>

답변: Graphics는 조명, 물리, 재질, geometry 같은 prior를 사람이 명시적으로 많이 설계한다. Statistical generative model은 데이터에서 분포를 학습하며, prior는 주로 모델 구조, loss, optimizer, sampling 방법의 형태로 들어간다.

</details>

<details markdown="block">
<summary>5. 1강의 수업 로드맵에서 representation, learning, inference는 각각 무엇을 묻는가?</summary>

답변: Representation은 고차원 joint distribution을 어떻게 compact하게 표현할지 묻는다. Learning은 데이터 분포와 모델 분포를 어떤 기준으로 가깝게 만들지 묻는다. Inference는 학습된 모델로 어떻게 sample을 만들거나 latent structure를 추론할지 묻는다.

</details>

<details markdown="block">
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
