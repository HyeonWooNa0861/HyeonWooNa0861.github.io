---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-09-03 19:55:00 +0900
title: "Stanford CS236 Lecture 18: Diffusion Models for Discrete Data"
course: "CS236"
topic: "Diffusion Models for Discrete Data"
order: 18
major_topic: "Deep Generative Models"
keywords:
  - "Discrete Diffusion"
  - "Concrete Score"
  - "Score Entropy"
  - "Continuous-Time Markov Chain"
  - "Autoregressive Models"
  - "Prompt Infilling"
---

# Stanford CS236 Lecture 18: Diffusion Models for Discrete Data

## Source

- Video: [Stanford CS236 Deep Generative Models 2023 Lecture 18](https://www.youtube.com/watch?v=mCaRNnEnYwA){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture18.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture18.pdf){:target="_blank" rel="noopener"}

> **핵심:** Lecture 18은 diffusion model을 discrete data로 옮기는 문제를 다룬다. Continuous data에서는 image pixel이나 latent vector를 조금 움직이는 것이 의미 있다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Discrete data | token sequence처럼 격자형 data는 continuous data와 무엇이 다른가? |
| 2 | Autoregressive baseline | AR modeling은 왜 강력하지만 discrete generation의 유일한 답은 아닌가? |
| 3 | Concrete score | continuous score를 쓸 수 없는 공간에서 score를 어떻게 다시 정의하는가? |
| 4 | Score Entropy | discrete score ratio를 어떤 objective로 학습하는가? |
| 5 | Discrete diffusion | Continuous-time Markov chain으로 forward/reverse process를 어떻게 만든다? |
| 6 | Generation and likelihood | discrete diffusion은 controllable generation과 perplexity 평가를 어떻게 다루는가? |

### 원본 수식 위치

| 원본 PDF | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| p. 12 | Autoregressive factorization | `핵심 내용`에서 chain-rule model 정의와 sequential sampling 한계를 설명한다. |
| pp. 18--27 | Concrete score, Score Entropy, implicit·denoising forms | `Concrete score와 Score Entropy`에서 정의, population optimum, tractable reformulations를 구분한다. |
| pp. 29--35 | CTMC generator, transition expansion, matrix exponential, factorized corruption | `CTMC generator` 및 reverse-process 절에서 exact continuous-time 정의와 discretization을 구분한다. |
| pp. 36--40 | Reverse CTMC rate와 accelerated sampling | `Reverse CTMC`에서 source-index convention, corrected direction, learned-score approximation을 명시한다. |
| pp. 46--47 | Perplexity와 likelihood bound | `Reverse CTMC와 likelihood bound`에서 source sign/index 문제를 공개하고 algebraically consistent한 해석을 제시한다. |

## 핵심 내용

Lecture 18은 diffusion model을 discrete data로 옮기는 문제를 다룬다. Continuous data에서는 image pixel이나 latent vector를 조금 움직이는 것이 의미 있다. 하지만 text token, molecule symbol, DNA sequence, code token 같은 discrete data는 $$x\in\{1,\ldots,n\}^d$$ 형태의 격자 위에 있다. "cat" token과 "dog" token 사이의 중간 token을 연속적으로 지나간다는 개념은 원래 공간에 없다. 따라서 gradient, divergence, SDE처럼 calculus에 기대는 continuous generative model을 그대로 적용하기 어렵다.

Discrete modeling은 언어 모델에서 이미 핵심 문제다. Language model pretraining은 large token sequence distribution을 맞추는 discrete probabilistic modeling으로 볼 수 있다. VQ-VAE나 MAGVIT류 모델처럼 image/video를 discrete codebook index로 바꾼 뒤 modeling하는 흐름도 있다. 즉 discrete generative modeling은 text만의 문제가 아니라, structured object와 compressed representation을 다루는 넓은 문제다.

현재 가장 강한 기본선은 autoregressive modeling이다. Chain rule로

$$
p(x)=\prod_i p(x_i\mid x_{<i})
$$

를 쓰면 각 step은 vocabulary 위의 categorical distribution을 예측하는 문제로 바뀐다. 이 방식은 likelihood와 perplexity 계산이 쉽고, transformer와 결합해 scale이 잘 된다. 그러나 sampling은 token을 하나씩 생성해야 하므로 느리고, early token mistake가 뒤쪽 generation을 흔들 수 있다. 또한 left-to-right causal order는 language에는 자연스럽지만, molecule, graph, image token grid, infilling처럼 순서가 덜 명확한 domain에는 강한 제약이 될 수 있다.

Lecture 18의 핵심 전환은 "discrete space에서도 score matching을 할 수 있는가"다. Continuous score $$\nabla_x\log p(x)$$는 discrete token에 대해 정의되지 않는다. 대신 concrete score는 인접한 discrete state 사이의 probability ratio를 모델링한다. 예를 들어 한 token만 바꾼 이웃 상태 $$y$$에 대해 $$p(y)/p(x)$$ 같은 local ratio를 예측하면, absolute probability를 정규화하지 않아도 어느 방향의 discrete move가 더 plausible한지 알 수 있다. 모든 $$y$$와의 pairwise ratio를 다루면 너무 크기 때문에, 실제로는 local replacement나 structured neighborhood를 사용한다.

Score Entropy는 이 concrete score를 학습하기 위한 discrete analogue of score matching이다. 목표는 neural network가 nonnegative ratio-like quantity를 예측하고, true ratio에서 objective가 최소가 되도록 만드는 것이다. 강의에서는 continuous score matching의 implicit/denoising 변형처럼 discrete에서도 implicit score entropy와 denoising score entropy가 중요하다고 설명한다. Implicit form은 모든 ratio를 직접 계산하지 않도록 식을 재배열해 scalable하게 만들고, denoising form은 corruption process를 사용해 noisy state에서 clean distribution 방향의 score를 학습한다.

Sampling은 Continuous-Time Markov Chain으로 구성된다. Discrete state는 continuous vector처럼 조금 이동하지 않고, 한 state에서 다른 state로 jump한다. 강의의 column-vector convention $$\dot p_t=Q_tp_t$$에서는 $$Q_t(j,i)$$가 state $$i\to j$$의 transition rate이고, valid CTMC가 되려면 off-diagonal entries가 nonnegative이며 각 source column의 합이 0이어야 한다. Forward diffusion은 data token을 점차 mask나 uniform noise 쪽으로 corrupt한다. Reverse diffusion은 현재 noisy token sequence에서 어떤 token replacement가 더 data-like한지 concrete score를 이용해 transition rate를 조정한다.

이 reverse process는 개념적으로 continuous diffusion과 비슷하다. Forward process는 data를 simple prior로 보내고, reverse process는 learned score를 사용해 prior에서 data로 돌아온다. 차이는 trajectory가 continuous curve가 아니라 token jump sequence라는 점이다. 가장 단순한 CTMC reverse sampler는 한 번에 한 token만 바꿀 수 있어 느릴 수 있다. 이를 완화하기 위해 여러 token을 함께 갱신하거나, discretization step을 크게 잡아 sampling을 가속한다. Masked sequence를 자연스러운 문장으로 infill하는 작업은 discrete diffusion의 conditional generation 예로 볼 수 있다.

Likelihood와 perplexity도 중요한 평가 축이다. Autoregressive model은 chain rule 때문에 likelihood가 직접 계산되지만, discrete diffusion은 reverse process와 score ratio를 통해 우회적으로 평가해야 한다. 강의는 weighted score entropy가 likelihood bound를 형성할 수 있고, discrete diffusion이 autoregressive model과 perplexity 기준에서도 경쟁할 수 있음을 강조한다. 따라서 이 접근은 단순히 빠른 sampling trick이 아니라, discrete probabilistic modeling 자체를 AR 중심에서 확장하려는 시도다.

### 핵심 수식 유도: CTMC generator가 확률을 보존하는 조건

> **Source mapping:** Official Lecture 18 PDF pp. 29--30의 column-vector master equation, nonnegative off-diagonal rate, column-sum-zero generator 정의에 대응한다.

Column-vector convention에서 상태확률 $$p_t$$의 forward equation을 $$\dot p_t=Q_t p_t$$로 둔다. 서로 다른 상태로 가는 rate는 음수가 될 수 없으므로 $$(Q_t)_{ij}\ge0$$ for $$i\ne j$$이고, 각 source column의 합을 0으로 두면

$$
\frac{d}{dt}\mathbf1^\top p_t
=\mathbf1^\top Q_t p_t=0.
$$

따라서 $$\mathbf1^\top p_t=1$$이 보존된다. Diagonal은 $$(Q_t)_{jj}=-\sum_{i\ne j}(Q_t)_{ij}$$라 현재 상태에서 빠져나가는 총 rate의 음수다. 이는 valid CTMC를 위한 **정확한 조건**이며, row-vector convention에서는 row-sum-zero로 전치된다. $$Q_t$$의 단위는 시간의 역수, $$p_t$$와 concrete score ratio $$p_t(y)/p_t(x)$$는 무차원이다. 음의 off-diagonal rate나 합 조건 위반은 probability를 음수로 만들거나 총합을 깨뜨린다. 여러 jump를 큰 time step 하나로 근사하는 sampler는 병렬화에는 유리하지만 discretization bias가 커질 수 있다.

### Concrete score와 Score Entropy 목적함수 (작성자 보충; 강의 슬라이드 18--27)

> **Source mapping:** Official Lecture 18 PDF pp. 18--22의 concrete score/Score Entropy, pp. 23--25의 implicit form, pp. 26--27의 denoising form에 대응한다.

강의는 이산함수의 차분을 $$\nabla f(x)=[f(y)-f(x)]_{y\in\mathcal N(x)}$$로 두고, probability에 적용한 concrete score를

$$
s_p(x)_y=\frac{p(y)}{p(x)},\qquad y\in\mathcal N(x)
$$

로 정의한다. 여기서 $$\mathcal N(x)$$는 한 token replacement 같은 허용된 neighbor 집합이다. Ratio와 state index는 무차원이며 $$p(x)>0$$인 state에서만 유한하다. 모든 state pair를 쓰면 sequence 길이 $$d$$와 alphabet 크기 $$N$$에 대해 비용이 폭발하므로 local neighborhood를 택하는 것은 계산 가능한 구조를 넣는 설계 선택이다.

Positive output $$s_\theta(x)_y>0$$에 대해, neighbor weight를 $$w_{xy}=1$$로 둔 **완전한 Score Entropy 정의**는 true ratio $$r_{xy}=p(y)/p(x)$$와 $$K(r)=r(\log r-1)$$를 사용해

$$
\mathcal L_{\mathrm{SE}}(\theta)
=\mathbb E_{x\sim p}
\sum_{y\ne x}
\left[s_\theta(x)_y-r_{xy}\log s_\theta(x)_y+K(r_{xy})\right].
$$

괄호 안은 $$s-r+r\log(r/s)$$인 generalized KL 형태이므로 음수가 아니며 $$s=r$$에서 0이다. $$K(r_{xy})$$는 $$\theta$$와 무관하지만 완전한 divergence의 비음수성과 영점을 정한다. 최적화만 볼 때는 이 항을 생략해도 된다. 각 $$(x,y)$$에 대해 scalar $$s$$로 미분하면 $$1-r_{xy}/s=0$$이므로 unrestricted population minimizer는 정확히 $$s^*(x)_y=r_{xy}=p(y)/p(x)$$다. 하지만 unknown ratio 때문에 그대로는 계산할 수 없다. 합의 index를 바꾸면 ratio 항이 사라져, $$\theta$$와 무관한 차이 없이 같은 minimizer를 갖는 **implicit Score Entropy**는

$$
\mathcal L_{\mathrm{ISE}}(\theta)
=\mathbb E_{x\sim p}
\sum_{y\ne x}
\left[s_\theta(x)_y-\log s_\theta(y)_x\right]
$$

가 된다.

Corruption kernel $$p(x\mid x_0)$$로 $$p(x)=\sum_{x_0}p(x\mid x_0)p_0(x_0)$$를 만들면, known conditional ratio를 쓰는 **denoising Score Entropy**는

$$
\begin{aligned}
\mathcal L_{\mathrm{DSE}}(\theta)
={}&\mathbb E_{x\sim p}\sum_{y\ne x}s_\theta(x)_y\\
&-\mathbb E_{x_0\sim p_0,\,x\sim p(\cdot\mid x_0)}
\sum_{y\ne x}
\frac{p(y\mid x_0)}{p(x\mid x_0)}
\log s_\theta(x)_y.
\end{aligned}
$$

이 식은 corruption transition을 평가할 수 있고 denominator가 양수일 때 noisy marginal concrete score를 겨냥한다. Neighbor sum이 매우 크면 implicit form도 비싸고, conditional ratio가 극단적이면 DSE variance와 numerical overflow가 커진다. Log output parameterization은 positivity를 보장하지만 ratio 자체를 exponentiate할 때 clipping bias가 생길 수 있다.

### Reverse CTMC와 likelihood bound (작성자 보충; 강의 슬라이드 35--47)

> **Source mapping and correction disclosure:** Official Lecture 18 PDF pp. 29--30이 $$\dot p_t=Q_tp_t$$와 column-sum-zero인 column-source convention을 확립한다. P. 35는 time-dependent denoising Score Entropy를 제시한다. P. 37의 첫 reverse-rate 식은 같은 페이지의 두 번째 식 및 pp. 29--30의 convention과 index 방향이 충돌하므로, 아래에서는 두 번째 식과 앞선 convention에 algebraically consistent한 corrected version을 사용한다. P. 47의 likelihood-bound weight $$Q_t(x_t,y)$$는 원문 그대로 유지한다. 같은 페이지의 perplexity 식은 `DSE`의 부호 정의와 $$\theta$$-독립 boundary constant의 포함 여부를 함께 명시해야 해석할 수 있다.

앞 절과 동일하게 $$\dot p_t=Q_tp_t$$인 **column-source convention**을 끝까지 쓴다. 즉 $$Q_t(j,i)$$는 forward jump $$i\to j$$의 rate다. 그러면 reverse jump $$i\to j$$에 해당하는 off-diagonal matrix entry는

$$
\bar Q_t(j,i)
=\frac{p_t(j)}{p_t(i)}Q_t(i,j),\qquad i\ne j,
$$

이고 learned concrete score를 사용하면

$$
\bar Q_t(j,i)
\approx s_\theta(i,t)_jQ_t(i,j).
$$

Diagonal은 $$\bar Q_t(i,i)=-\sum_{j\ne i}\bar Q_t(j,i)$$로 정해 각 source column의 합을 0으로 만든다. 첫 식은 $$p_t(i)>0$$인 state와 well-defined forward CTMC 아래의 **정확한 time-reversal 식**, 둘째는 score model을 넣은 **근사**다. Matrix entry와 jump 방향을 뒤집어 읽으면 score ratio와 rate가 모두 잘못되므로, row-source 표기와 섞지 않아야 한다. Rate의 단위는 time의 역수이고 score ratio는 무차원이라 reverse rate도 time의 역수다. Score가 음수를 내거나 큰 ratio를 과대평가하면 invalid 또는 stiff generator가 되고, 큰 step으로 여러 jump를 병렬 근사하면 bias가 생긴다.

Forward transition을 $$p_{t\mid0}(x_t\mid x_0)$$라 할 때, p. 47의 원문 weight 방향을 유지하고 NLL-upper-bound 부호로 명시하면 다음과 같다.

$$
\begin{aligned}
-\log p_\theta(x_0)
\le{}&\int_0^T
\mathbb E_{x_t\sim p_{t\mid0}(\cdot\mid x_0)}
\sum_{y\ne x_t}Q_t(x_t,y)\\
&\quad\left[
s_\theta(x_t,t)_y
-\frac{p_{t\mid0}(y\mid x_0)}{p_{t\mid0}(x_t\mid x_0)}
\log s_\theta(x_t,t)_y
\right]dt+C_{Q,\pi}(x_0).
\end{aligned}
$$

여기서 weight $$Q_t(x_t,y)$$는 p. 47의 weighted Score Entropy 식에 적힌 방향 그대로이며, 앞 절의 outgoing-rate 표기로 임의 치환하지 않는다. $$\pi$$는 reverse model의 terminal prior이고, $$C_{Q,\pi}(x_0)$$는 forward generator $$Q_t$$, transition $$p_{t\mid0}(\cdot\mid x_0)$$와 terminal prior $$\pi$$가 정하는 **$$\theta$$-독립 path-space boundary/entropy 항 전체**를 뜻한다. 이는 일반적으로 0이 아니며 $$x_0$$에 의존할 수 있다. 위 표기에서 적분항만을 $$\mathrm{DSE}_{\mathrm{int}}(x_0)$$, 상수까지 포함한 bound를

$$
\mathrm{DSE}_{\mathrm{full}}(x_0)
:=\mathrm{DSE}_{\mathrm{int}}(x_0)+C_{Q,\pi}(x_0)
$$

로 정의하면 부호 관계는

$$
\mathrm{NLL}_\theta(x_0)
:=-\log p_\theta(x_0)
\le\mathrm{DSE}_{\mathrm{full}}(x_0),
\qquad
\mathrm{PPL}_\theta(x_0)
:=\exp\!\left(\frac{\mathrm{NLL}_\theta(x_0)}{d}\right)
\le\exp\!\left(\frac{\mathrm{DSE}_{\mathrm{full}}(x_0)}{d}\right)
$$

가 된다. P. 47에 인쇄된 $$\mathrm{PPL}\le e^{-\mathrm{DSE}/d}$$를 성립시키려면 그 `DSE`를 이 글과 반대 부호의 log-likelihood lower-bound quantity로 정의해야 한다. 반대로 이 글처럼 $$\mathrm{DSE}_{\mathrm{full}}$$을 NLL의 upper bound로 정의하면 위의 **양의 지수**가 algebraically consistent하다. 적분항만 `DSE`라고 부르면 지수 안에 $$C_{Q,\pi}$$를 반드시 더해야 한다.

Bound의 증명은 CTMC path-space likelihood를 forward process에 대한 variational bound로 바꾸고, jump compensator와 reverse-rate log term을 모으면 시간가중 Score Entropy가 된다는 흐름이다. 위 식은 **증명 개요**만 제시하며 regularity, support coverage와 finite jump intensity를 가정한다. NLL, DSE, perplexity는 무차원이다. Finite time sampling, Monte Carlo time/state estimate, neighbor subsampling과 learned score 때문에 계산한 bound는 noisy할 수 있고, terminal distribution mismatch나 누락된 support가 있으면 bound가 느슨하거나 무한해질 수 있다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Discrete data | token, category, graph edge, molecule symbol처럼 가능한 값이 분리된 data다. |
| Autoregressive model | $$p(x)=\prod_i p(x_i\mid x_{<i})$$로 분포를 순서대로 분해하는 모델이다. |
| Concrete score | discrete state 사이의 local probability ratio를 예측해 move direction을 나타내는 score 개념이다. |
| Score Entropy | concrete score를 학습하기 위한 discrete score-matching objective다. |
| Denoising Score Entropy | corruption process를 사용해 noisy discrete state에서 clean distribution 방향의 score를 학습한다. |
| Continuous-Time Markov Chain | discrete state 사이의 jump rate로 확률분포 변화를 정의하는 stochastic process다. |
| Prompt infilling | 주어진 일부 token을 조건으로 두고 mask 또는 빈 부분을 채우는 conditional discrete generation task다. |

## 학습 포인트

- Discrete diffusion의 어려움은 neural network 입력이 discrete라서가 아니라, 원래 state space에서 미분과 연속 이동이 정의되지 않는다는 점이다.
- Token embedding을 continuous vector로 바꾼 뒤 일반 diffusion을 적용하는 방식은 빈 공간과 discretization 문제를 만든다. Lecture 18은 discrete space 자체에서 score 개념을 다시 세운다.
- Autoregressive model은 likelihood와 scaling에서 강하지만, sampling order와 one-token-at-a-time generation이라는 구조적 제약을 가진다.
- Concrete score는 absolute probability보다 local ratio를 중시한다. 이는 energy model과 score-based model처럼 normalization을 직접 피하려는 흐름과 닮았다.
- CTMC generator matrix의 부호와 합 조건은 discrete diffusion이 valid probability dynamics가 되기 위한 최소 조건이다.
- Denoising Score Entropy와 forward corruption process를 함께 설계해야 학습과 sampling이 맞물린다.
- Discrete diffusion의 장점은 controllable generation, infilling, potentially faster parallel updates에서 특히 드러난다.

## 마지막 핵심 정리

Lecture 18의 핵심은 diffusion과 score matching을 continuous vector space의 전유물로 보지 않는 것이다. Discrete data에서는 gradient 대신 state 간 local probability ratio인 concrete score를 학습하고, Score Entropy로 이를 최적화한다. Forward process는 CTMC로 token을 corrupt하고, reverse process는 learned concrete score로 plausible한 token jump를 선택한다. 이 접근은 autoregressive modeling의 likelihood 장점을 바로 대체하기보다는, sampling order 제약과 느린 sequential generation을 완화하는 discrete probabilistic modeling의 대안으로 이해하는 것이 좋다.

## Study Guide

1. Continuous score $$\nabla_x\log p(x)$$가 discrete token space에서 왜 정의되지 않는지 예시로 설명한다.
2. Autoregressive factorization의 장점과 단점을 나누어 적는다. 특히 likelihood 계산과 sampling 속도를 분리해서 본다.
3. Concrete score를 "확률값 자체"가 아니라 "neighboring discrete state 사이의 ratio"로 기억한다.
4. Score Entropy, implicit Score Entropy, denoising Score Entropy가 각각 어떤 계산 문제를 줄이려는지 구분한다.
5. CTMC generator matrix $$Q_t$$의 off-diagonal nonnegative 조건과 column-sum-zero 조건이 왜 필요한지 확인한다.
6. Prompt infilling을 예로 들어 reverse discrete diffusion이 조건부 generation을 어떻게 수행하는지 설명해 본다.

## 복습 질문

<details markdown="block">
<summary>1. Discrete data에 continuous diffusion을 그대로 적용하기 어려운 이유는 무엇인가?</summary>

답변: Discrete data는 token이나 category처럼 분리된 state로 이루어져 있어 두 state 사이의 연속 경로가 원래 공간에 없다. 따라서 $$\nabla_x\log p(x)$$ 같은 continuous gradient나 작은 Gaussian perturbation을 그대로 정의하기 어렵다.

</details>

<details markdown="block">
<summary>2. Autoregressive model이 discrete data에서 강한 baseline인 이유는 무엇인가?</summary>

답변: Chain rule로 joint distribution을 conditional categorical distributions의 곱으로 분해할 수 있어 likelihood와 perplexity 계산이 직접적이다. Transformer와 결합하면 scale이 잘 되고 language modeling에는 left-to-right order가 비교적 자연스럽다.

</details>

<details markdown="block">
<summary>3. Autoregressive generation의 구조적 한계는 무엇인가?</summary>

답변: Token을 순서대로 하나씩 생성해야 하므로 sampling이 느리다. 앞쪽 token의 실수가 뒤쪽 sample에 누적될 수 있고, 고정된 causal order는 infilling, graph, image token grid처럼 자연스러운 순서가 없는 문제에 제약을 준다.

</details>

<details markdown="block">
<summary>4. Concrete score는 continuous score와 무엇이 다른가?</summary>

답변: Continuous score는 입력을 미소하게 움직였을 때 log density가 증가하는 방향인 $$\nabla_x\log p(x)$$다. Concrete score는 discrete neighbor state 사이의 probability ratio를 모델링해 어떤 token replacement나 jump가 더 plausible한지 알려준다.

</details>

<details markdown="block">
<summary>5. CTMC generator matrix가 valid하려면 어떤 조건이 필요한가?</summary>

답변: 서로 다른 state로 이동하는 off-diagonal transition rates는 nonnegative여야 하고, 각 column의 합은 0이어야 한다. 이 조건은 probability mass가 음수가 되지 않고 전체 mass가 보존되도록 한다.

</details>

<details markdown="block">
<summary>6. Denoising Score Entropy가 discrete diffusion과 잘 맞는 이유는 무엇인가?</summary>

답변: Discrete diffusion은 forward corruption으로 noisy token sequence를 만든다. Denoising Score Entropy는 이런 noisy state에서 clean data distribution 쪽으로 가는 local ratio를 학습하므로, training objective와 reverse sampling process가 같은 corruption 구조를 공유한다.

</details>

## PDF

- [Official Lecture 18 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture18.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Course Notes](https://deepgenerativemodels.github.io/notes/index.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 18 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture18.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 18 Video](https://www.youtube.com/watch?v=mCaRNnEnYwA){:target="_blank" rel="noopener"}
- [Lou, Meng, and Ermon, “Discrete Diffusion Modeling by Estimating the Ratios of the Data Distribution”](https://openreview.net/forum?id=CNicRIVIPA){:target="_blank" rel="noopener"}
