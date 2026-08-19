---
layout: default
title: "Stanford CS236 Lecture 14: Energy-Based Models III"
course: "CS236"
topic: "Noise Conditional Score Networks, Annealed Langevin Dynamics, and Reverse-Time SDEs"
order: 14
major_topic: "Deep Generative Models"
keywords:
  - "Energy-Based Models"
  - "Score-Based Models"
  - "NCSN"
  - "Annealed Langevin Dynamics"
  - "Reverse-Time SDE"
  - "Probability Flow ODE"
---

# Stanford CS236 Lecture 14: Energy-Based Models III

## Source

- Video: [Stanford CS236 Lecture 14](https://www.youtube.com/watch?v=E69Lp_T9nVg){:target="_blank" rel="noopener"}
- Source Slides: [lecture_14_comp.pptx](https://deepgenerativemodels.github.io/assets/slides/lecture_14_comp.pptx){:target="_blank" rel="noopener"}

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Lecture 13 recap | Score matching, denoising score matching, sliced score matching은 각각 무엇을 해결했는가? |
| 2 | Gaussian perturbation | Noise를 더하면 manifold와 low-density score 문제를 어떻게 완화하는가? |
| 3 | Multiple noise scales | 단일 \(\sigma\)의 tradeoff를 여러 noise level로 어떻게 피하는가? |
| 4 | Annealed Langevin dynamics | 큰 noise에서 작은 noise로 내려오며 sample을 어떻게 정제하는가? |
| 5 | Noise Conditional Score Networks | \(s_\theta(x,\sigma)\) 하나로 여러 perturbed density의 score를 어떻게 학습하는가? |
| 6 | Continuous-time view | 유한 noise level을 SDE와 reverse-time SDE로 일반화하면 무엇이 달라지는가? |
| 7 | Probability flow and conditioning | ODE likelihood와 Bayes score decomposition은 diffusion model 활용을 어떻게 넓히는가? |

## 핵심 내용

Lecture 14는 제목상 Energy-Based Models III로 묶여 있지만 실제 전개는 score-based model을 diffusion model로 확장하는 강의다. 지난 강의에서 score model은 \(s_\theta(x)\approx \nabla_x\log p_{\mathrm{data}}(x)\)를 학습하고 Langevin dynamics로 sample을 만들었다. 그러나 clean data에 바로 score matching을 적용하면 manifold 위의 data, low-density region의 부정확한 score, mode 사이의 느린 mixing 때문에 sampling이 안정적이지 않았다.

강의의 핵심 해결책은 Gaussian perturbation이다. Clean data에 noise를 더하면 support가 ambient space 전체로 퍼지고, low-density region에서도 training sample이 생긴다. 큰 noise는 멀리 떨어진 지점에서도 대략적인 방향 정보를 주기 쉽다. 반대로 큰 noise를 계속 쓰면 우리가 배우는 것은 clean distribution이 아니라 흐려진 distribution의 score다. 작은 noise는 clean data에 가깝지만 추정이 어렵고, 큰 noise는 추정이 쉽지만 sample quality를 떨어뜨린다. 단일 \(\sigma\)로는 이 tradeoff를 피하기 어렵다.

Diffusion/score-based model의 아이디어는 여러 noise scale을 함께 쓰는 것이다. \(\sigma_1<\sigma_2<\cdots<\sigma_L\)처럼 noise level들을 두고, 각 level에서 perturbed density \(p_{\sigma_i}\)의 score를 학습한다. Sampling은 큰 noise에서 시작해 작은 noise로 내려온다. 처음에는 sample이 거의 구조 없는 noise이므로 큰 \(\sigma\)에서 학습된 score를 따라가고, 점점 data manifold 근처로 이동하면 더 작은 \(\sigma\)의 score를 사용한다. 이 절차가 annealed Langevin dynamics다. 각 단계의 output을 다음 noise level의 initial point로 사용하므로, score가 정확한 영역 안에서만 다음 refinement를 수행할 가능성이 높아진다.

효율적인 학습을 위해 Noise Conditional Score Network(NCSN)를 사용한다. Noise level마다 separate model을 학습할 수도 있지만, 실제로는 하나의 network가 \(x\)와 \(\sigma\)를 같이 입력받아

$$
s_\theta(x,\sigma)\approx \nabla_x\log p_\sigma(x)
$$

를 출력한다. Training loss는 여러 noise level의 denoising score matching loss를 weighted sum으로 묶는다. Minibatch에서는 clean data point를 뽑고, noise level index를 뽑고, 해당 \(\sigma_i\)의 Gaussian noise를 더한 뒤, 그 noise를 제거하는 방향을 예측하도록 학습한다. \(\lambda(\sigma_i)\)는 noise level별 loss scale을 균형 있게 만들기 위한 weight다. 강의는 noise schedule도 중요하게 다룬다. Maximum noise는 data point들 사이를 충분히 연결할 정도로 커야 하고, minimum noise는 clean image와 거의 구분되지 않을 정도로 작아야 한다. 중간 level들은 인접 perturbed distributions가 충분히 overlap하도록 보통 geometric progression으로 둔다.

후반부는 유한한 noise scale을 continuous-time으로 확장한다. 여러 \(\sigma_i\) 대신 time \(t\in[0,T]\)에 따라 점점 noise가 커지는 stochastic process를 생각한다. Forward process는 data에서 pure noise로 가는 SDE로 표현할 수 있고, sample generation은 이 과정을 시간 반대로 푸는 문제다. Reverse-time SDE는 각 time의 score \(\nabla_x\log p_t(x)\)를 필요로 한다. 따라서 time-dependent score network \(s_\theta(x,t)\)를 denoising score matching으로 학습한 뒤, true score 대신 estimated score를 reverse SDE에 넣어 noise에서 data로 적분한다. Euler-Maruyama 같은 기본 numerical solver부터 predictor-corrector sampler까지 다양한 solver를 사용할 수 있다. Predictor는 SDE를 따라 time을 이동시키고, corrector는 같은 time slice에서 Langevin MCMC로 sample을 보정한다.

같은 marginal distributions를 갖는 deterministic probability flow ODE도 존재한다. 이 관점에서는 noise에서 data로 가는 mapping이 ODE solution으로 정의되며, continuous-time normalizing flow처럼 invertible하게 해석된다. 그래서 score matching으로 학습한 model에서도 likelihood 계산이 가능해진다. 또 conditioning은 score level에서 자연스럽다. Bayes rule에 의해

$$
\nabla_x\log p(x\mid y)=\nabla_x\log p(x)+\nabla_x\log p(y\mid x)
$$

처럼 쓸 수 있으므로, unconditional score model에 관측 모델이나 guidance term을 더해 inverse problem, stroke-to-image, language-guided generation 같은 작업으로 확장할 수 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Gaussian perturbation | Clean data에 Gaussian noise를 더해 support를 넓히고 score estimation을 안정화하는 방법이다. |
| Noise scale | Data에 더하는 noise의 표준편차 또는 intensity다. 작은 값은 clean data에 가깝고 큰 값은 estimation을 쉽게 만든다. |
| Annealed Langevin dynamics | 큰 noise level에서 작은 noise level로 순차적으로 Langevin dynamics를 실행해 sample을 점진적으로 정제하는 sampling 절차다. |
| NCSN | Noise Conditional Score Network. \(x\)와 \(\sigma\)를 입력받아 해당 noise level의 score를 출력하는 하나의 amortized score model이다. |
| Geometric noise schedule | 인접 noise distributions가 충분히 overlap하도록 maximum과 minimum noise 사이를 등비적으로 배치하는 heuristic이다. |
| Reverse-time SDE | Data를 noise로 보내는 forward SDE를 시간 반대로 풀어 noise에서 data sample을 생성하는 stochastic dynamics다. |
| Predictor-corrector sampler | Numerical SDE solver step과 Langevin correction step을 결합하는 score-based sampling 방식이다. |
| Probability flow ODE | Reverse SDE와 같은 marginal distribution을 갖는 deterministic ODE로, likelihood와 invertible flow 해석을 가능하게 한다. |

## 학습 포인트

- Noise는 단순 regularization이 아니라 score를 정의하고 학습하기 쉬운 distribution sequence를 만드는 장치다.
- 작은 \(\sigma\)는 quality에 유리하고 큰 \(\sigma\)는 global guidance와 mixing에 유리하다. 여러 scale을 쓰는 이유는 이 둘을 순차적으로 결합하기 위해서다.
- Annealed Langevin dynamics는 처음부터 clean score를 믿지 않는다. 큰 noise score로 coarse structure를 만들고, 작은 noise score로 detail을 복원한다.
- NCSN은 noise level마다 모델을 따로 두지 않고 \(s_\theta(x,\sigma)\) 하나로 여러 denoising task를 amortize한다.
- Continuous-time SDE 관점은 diffusion model을 "noise schedule + denoising"에서 "stochastic process reversal"로 일반화한다.
- Probability flow ODE는 score-based model이 likelihood-free sample generator에만 머물지 않고 flow-like likelihood 평가까지 가능하게 만든다.

## 마지막 핵심 정리

Lecture 14의 핵심은 score-based model의 practical failure를 multi-scale noise로 해결하는 것이다. 여러 perturbed data distributions의 score를 NCSN으로 학습하고, annealed Langevin dynamics 또는 reverse-time SDE solver로 큰 noise에서 clean data로 내려오면 안정적인 image generation이 가능해진다. 이 관점은 sampling뿐 아니라 likelihood 계산, predictor-corrector sampling, conditional generation까지 연결한다.

## Study Guide

1. Lecture 13의 세 failure mode를 먼저 쓰고, Gaussian perturbation이 각각에 어떤 도움을 주는지 연결한다.
2. 단일 noise level의 tradeoff를 quality와 score estimation accuracy라는 두 축으로 정리한다.
3. Annealed Langevin dynamics를 "large-noise global move"와 "small-noise local refinement"의 반복으로 이해한다.
4. NCSN training loop를 clean data, sampled noise index, Gaussian noise, denoising target, weighted loss 순서로 재구성한다.
5. Discrete noise schedule과 continuous-time SDE를 같은 아이디어의 두 표현으로 비교한다.
6. Probability flow ODE가 왜 normalizing flow와 닮았는지, 그리고 왜 likelihood 계산과 연결되는지 확인한다.

## 복습 질문

<details>
<summary>1. Gaussian perturbation이 manifold 문제를 완화하는 이유는 무엇인가?</summary>

답변: Clean image data가 저차원 manifold에 놓이면 manifold 밖의 density가 0에 가까워 score가 불안정할 수 있다. Gaussian noise를 더하면 perturbed distribution이 ambient space 전체에 support를 갖게 되어, manifold 밖에서도 score를 정의하고 학습할 수 있다.

</details>

<details>
<summary>2. 여러 noise scale을 사용하는 이유는 무엇인가?</summary>

답변: 큰 noise는 score estimation과 global mixing을 쉽게 하지만 clean distribution에서 멀어진다. 작은 noise는 clean data에 가깝지만 score estimation이 어렵다. 여러 scale을 쓰면 큰 noise에서 구조를 잡고 작은 noise로 detail을 복원하는 순차적 sampling이 가능하다.

</details>

<details>
<summary>3. Annealed Langevin dynamics는 vanilla Langevin dynamics와 어떻게 다른가?</summary>

답변: Vanilla Langevin dynamics는 하나의 target score만 따라간다. Annealed Langevin dynamics는 큰 noise level의 score로 시작해 점점 작은 noise level의 score로 바꾸며, 각 단계의 sample을 다음 단계의 초기값으로 사용한다.

</details>

<details>
<summary>4. NCSN에서 \(\sigma\)를 입력으로 주는 이유는 무엇인가?</summary>

답변: Noise level마다 perturbed density와 score field가 다르다. \(\sigma\)를 입력으로 주면 하나의 neural network가 "현재 어떤 noise level의 score를 예측해야 하는지"를 알 수 있어, 여러 score estimation task를 하나의 model로 amortize할 수 있다.

</details>

<details>
<summary>5. Reverse-time SDE에서 score network가 필요한 위치는 어디인가?</summary>

답변: Forward SDE는 data를 점점 noise로 보낸다. 이를 시간 반대로 풀어 noise에서 data로 가려면 각 time \(t\)에서의 \(\nabla_x\log p_t(x)\)가 필요하다. 실제로는 true score를 모르므로 \(s_\theta(x,t)\)로 근사해 reverse SDE solver에 넣는다.

</details>

<details>
<summary>6. Probability flow ODE가 중요한 이유는 무엇인가?</summary>

답변: Reverse SDE와 같은 marginal distribution을 유지하면서 deterministic ODE로 sample path를 정의할 수 있다. ODE solution은 invertible mapping처럼 볼 수 있으므로 continuous-time normalizing flow와 연결되고, score-based model에서도 likelihood 계산을 가능하게 한다.

</details>

## Slides

- [Official Lecture 14 slide deck](https://deepgenerativemodels.github.io/assets/slides/lecture_14_comp.pptx){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 14 Slides](https://deepgenerativemodels.github.io/assets/slides/lecture_14_comp.pptx){:target="_blank" rel="noopener"}
- [CS236 Lecture 14 Video](https://www.youtube.com/watch?v=E69Lp_T9nVg){:target="_blank" rel="noopener"}
- [Generative Modeling by Estimating Gradients of the Data Distribution](https://arxiv.org/abs/1907.05600){:target="_blank" rel="noopener"}
- [Score-Based Generative Modeling through Stochastic Differential Equations](https://arxiv.org/abs/2011.13456){:target="_blank" rel="noopener"}
