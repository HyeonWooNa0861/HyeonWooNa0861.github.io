---
layout: post
title: "How Did Discrete Diffusion Become a Large Language Model?"
nav_title: "From SEDD to LLaDA"
date: 2026-10-15 19:05:00 +0900
categories: [Machine Learning, Language Models]
tags: [Discrete Diffusion, SEDD, MDLM, MD4, RADD, SMDM, LLaDA, Masked Language Modeling]
permalink: /posts/discrete-diffusion-language-models/
section: 26-2-paper-research-seminar
---

Source Slides: <a href="{{ '/assets/pdfs/post/26-2-paper-research-seminar/how-did-discrete-diffusion-become-a-large-language-model.pdf' | relative_url }}" target="_blank" rel="noopener">How Did Discrete Diffusion Become a Large Language Model? — From SEDD to LLaDA</a> · 이혜은, 2026.10.12, 21 slides.

> **핵심 메시지:** 언어모델의 목적은 문장의 확률분포를 배우는 것이지, 반드시 왼쪽부터 한 단어씩 생성하는 것이 아니다. SEDD는 이산 상태 사이의 **확률비**를 학습했고, masked diffusion 연구는 이를 **가려진 토큰의 원래 값을 예측하는 문제**로 단순화했다. LLaDA는 이 학습을 8B 규모의 사전학습과 지시문 학습으로 확장했다. 핵심은 마스킹 자체가 아니라, **마스킹·복원·손실함수가 하나의 생성 확률모형으로 연결된다는 점**이다.

이 발표는 한 논문의 결과만 소개하기보다, 이산 확산의 수학적 표현이 어떻게 대규모 언어모델의 학습 절차로 이어졌는지 설명한다. 아래 해설은 발표의 순서를 따라가되, 원 논문의 가정과 설명용 계산을 보충한다. 실험 결과는 발표가 인용한 LLaDA의 결과이며, 이후 모델까지 포함한 최신 순위로 읽지 않는다.

## Reading Map

| Slides | Question | Section |
|---|---|---|
| 1–5 | 왜 autoregression 이외의 생성 방식을 연구하는가? | 1 |
| 6–7 | 연속 score를 토큰에 어떻게 대응시키는가? | 2 |
| 8–10 | SEDD에서 masked diffusion으로 무엇이 단순해졌는가? | 3–4 |
| 11–12 | BERT와 무엇이 다르고, 왜 손실에 1/t가 붙는가? | 5 |
| 13–15 | 대규모 사전학습과 SFT는 어떻게 이루어지는가? | 6 |
| 16 | 한 번에 예측하면서도 여러 단계가 필요한 이유는? | 7 |
| 17–19 | scaling 그래프와 benchmark는 무엇을 보여주는가? | 8 |
| 20–21 | 의의, 남은 과제와 참고 논문은? | 9–References |

## 1. The Goal Is a Distribution, Not a Fixed Order

언어모델은 토큰 열 $$x=(x^1,\ldots,x^L)$$에 확률을 부여한다. $$L$$은 토큰 개수이고, 토큰은 실제로 단어 하나와 일치하지 않을 수 있다. 학습 데이터에 자주 등장하는 자연스러운 표현에는 높은 확률을, 부자연스러운 조합에는 낮은 확률을 주도록 모델을 조정한다.

Autoregressive model(AR)은 이 결합확률을 앞에서부터의 조건부 확률로 분해한다.

$$
p_\theta(x)=\prod_{i=1}^{L}p_\theta(x^i\mid x^{<i}).
$$

이는 확률의 chain rule에 근거한 정확한 분해다. 모델은 각 조건부 분포를 근사하며, 일반적인 생성은 이미 나온 토큰을 조건으로 다음 토큰을 뽑는다. **결합확률을 학습한다는 목표와, 생성 순서를 왼쪽부터 고정한다는 선택은 구별할 수 있다.**

Masked diffusion은 일부 위치가 가려진 문장 전체를 보고 그 위치의 원래 토큰을 예측한다. 예를 들어 `The [MASK] is blue`에서는 앞의 `The`와 뒤의 `is blue`를 모두 조건으로 사용할 수 있다. 처음에는 모든 생성 위치를 가린 상태로 시작하고, 여러 번의 예측을 통해 문장을 완성한다.

이 방식은 양방향 문맥 사용, 유연한 채우기 순서, 여러 위치의 동시 예측을 가능하게 한다. 다만 **일반적인 AR 학습도 teacher forcing으로 여러 위치의 손실을 병렬 계산한다.** 여기서 중요한 차이는 학습의 병렬성 자체보다 추론 때 어떤 문맥을 보고 어떤 위치를 갱신하는가에 있다.

<details markdown="block">
<summary markdown="span">Derivation: Maximum likelihood and KL divergence</summary>

고정된 데이터 분포 $$p_{\mathrm{data}}$$에 대해 다음 식이 성립한다. 로그는 자연로그이며, 확률과 KL divergence는 무차원이고 로그 손실은 nats로 표현한다.

$$
\begin{aligned}
D_{\mathrm{KL}}(p_{\mathrm{data}}\Vert p_\theta)
&=\mathbb E_{p_{\mathrm{data}}}[\log p_{\mathrm{data}}(x)]
-\mathbb E_{p_{\mathrm{data}}}[\log p_\theta(x)]\\
&=-H(p_{\mathrm{data}})-\mathbb E_{p_{\mathrm{data}}}[\log p_\theta(x)].
\end{aligned}
$$

데이터의 entropy $$H(p_{\mathrm{data}})$$는 매개변수 $$\theta$$와 무관하다. 따라서 평균 log-likelihood를 최대화하는 것과 이 방향의 KL을 최소화하는 것은 같은 최적화다. 데이터에 양의 확률이 있는 곳에서 모델 확률이 0이면 KL은 무한대일 수 있으므로, 유한한 식으로 계산할 때는 적절한 support 조건이 필요하다.

이 등가는 학습 **목표**에 관한 것이다. 유한한 데이터와 모델, 불완전한 최적화로 실제 데이터 분포를 정확히 복원한다는 보장은 아니다. 또한 diffusion의 variational objective는 일반적으로 log-likelihood 자체가 아니라 그 하한을 최적화한다.

</details>

## 2. SEDD: From Gradients to Probability Ratios

### Continuous scores and discrete tokens

연속 확산의 score $$\nabla_x\log p_t(x)$$는 현재 잡음 수준 $$t$$에서 입력 좌표를 조금 바꾸면 log-density가 어느 방향으로 증가하는지를 나타낸다. 슬라이드 6의 그림은 위쪽에서 원본에 잡음을 더하고, 아래쪽에서는 학습한 score로 역방향 움직임을 보정하는 구조다.

토큰 ID는 이런 연속 좌표가 아니다. `sky`의 ID에 작은 실수를 더한다고 인접한 의미의 단어가 되지 않으며, ID 순서는 어휘의 의미적 거리를 정의하지 않는다. 이산 확산에서는 **토큰 사이의 전이 자체**와 **그 전이를 되돌리는 확률**을 정의해야 한다. 이미지도 저장 형식상 양자화되지만, 이 대비는 이미지 확산에서 실수 값 상태를 사용한다는 모델링 관점이다.

SEDD의 중요한 대상은 같은 시점의 두 상태 사이 확률비다.

$$
s_\theta(x,t)_y\approx\frac{p_t(y)}{p_t(x)},\qquad p_t(x)>0.
$$

여기서 $$x,y$$는 전체 토큰 열의 상태이고, 실제 전이는 잡음 과정이 허용하는 이웃 상태에 대해 계산한다. 이 비는 1보다 클 수도 있다. **어휘 전체에 합이 1인 토큰 예측 확률과는 다르다.** SEDD는 이 양의 비율을 score entropy라는 목적함수로 학습해 역방향 전이율을 구성한다. [SEDD, §3](https://proceedings.mlr.press/v235/lou24a.html){:target="_blank" rel="noopener"}.

<details markdown="block">
<summary markdown="span">Derivation: Why the reverse process needs probability ratios</summary>

연속시간 Markov chain에서 $$q_t(x,y)$$를 전방 과정의 $$x\to y$$ 전이율로 정의하자. 작은 시간 $$h>0$$ 동안 전이 확률은 $$q_t(x,y)h+o(h)$$다. Bayes 법칙으로 역방향 조건부 확률을 쓰면

$$
\Pr(X_{t-h}=y\mid X_t=x)
=\frac{\Pr(X_t=x\mid X_{t-h}=y)p_{t-h}(y)}{p_t(x)}.
$$

$$y\ne x$$이고 시간에 따른 변화가 충분히 매끄러우면 우변의 1차 항은 다음과 같다.

$$
\bar q_t(x,y)h
=q_t(y,x)h\frac{p_t(y)}{p_t(x)}+o(h).
$$

따라서 역방향 전이율은 **반대 방향 전방 전이율 × 현재 분포의 확률비**다. 행렬의 행·열 convention을 바꾸면 전치 표기가 달라질 수 있지만 이 조건부 확률 관계는 같다. 정규화된 시간축을 쓰면 전이율은 그 시간당 비율이고, $$p_t(y)/p_t(x)$$는 무차원이다.

고정된 목표 비율 $$r>0$$에 대한 score-entropy의 한 항은 매개변수와 무관한 상수를 제외하면 $$s-r\log s$$ 형태다. 미분하면 $$1-r/s=0$$에서 $$s=r$$이고, 이차 미분 $$r/s^2>0$$이므로 최소점이다. 실제 SEDD는 알 수 없는 데이터 확률비를 직접 라벨로 요구하지 않도록 denoising 형태의 학습 목적을 도출한다. 이 한 항은 최적점의 직관을 보여주는 설명이며 전체 학습 목적의 모든 전이 가중치를 생략한 형태다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Reading the continuous diffusion equation</summary>

슬라이드 6은 상태에 무관한 스칼라 확산 계수 $$g(t)$$를 쓰는 연속 SDE를 보여준다.

$$
dx=f(x,t)\,dt+g(t)\,dw,
$$

$$
dx=\bigl[f(x,t)-g(t)^2\nabla_x\log p_t(x)\bigr]dt+g(t)\,d\bar w.
$$

$$f$$는 drift, $$w$$는 전방 Wiener process이며 두 번째 식은 시간을 감소시키며 적분하는 역방향 SDE다. 따라서 두 번째 식의 $$dt$$는 음의 시간 진행을 뜻한다. 상태 의존 확산 행렬 등 더 일반적인 경우에는 추가 항이 필요하다. 그림의 score 항은 확률밀도가 높은 영역을 반영하도록 역과정의 drift를 보정한다.

역 SDE의 엄밀한 유도는 확률과정의 시간 반전 결과를 사용한다. 이 글에서는 전체 증명 대신 식의 조건과 역할을 설명하며, [Song et al., §3와 Appendix A](https://arxiv.org/abs/2011.13456){:target="_blank" rel="noopener"}가 원 유도 근거다. 토큰 모델이 이 실수 좌표 미분을 그대로 계산하는 것은 아니다.

</details>

## 3. Why an Absorbing Mask Simplifies the Problem

![Forward masking and reverse unmasking illustrated with four token positions](/assets/images/post/discrete-diffusion-language-models/masking-process.png)

*발표 슬라이드 10. 위쪽은 정보를 없애는 전방 과정, 아래쪽은 가려진 위치를 복원하는 역방향 과정이다.*

그림은 `The sky is blue`의 네 위치를 위에서 아래로 따라 읽는다. 전방 과정에서 각 토큰은 그대로 남거나 `[MASK]`로 바뀐다. **Absorbing**은 한 번 mask가 된 위치가 전방 과정에서 다른 일반 토큰으로 돌아오지 않는다는 뜻이다. 역방향에서는 mask 위치에 원래 토큰의 후보를 채운다.

이 글에서 $$t\in[0,1]$$은 실제 경과 시간이 아니라 **마스킹 확률을 나타내는 무차원 변수**다. $$M$$을 mask 기호, $$x_0$$를 원문이라고 하면, 위치별 독립 마스킹은 다음과 같다.

$$
q_t(x_t^i\mid x_0^i)
=(1-t)\mathbf 1[x_t^i=x_0^i]+t\mathbf 1[x_t^i=M].
$$

$$\mathbf 1[\cdot]$$는 조건이 참일 때 1, 거짓일 때 0이다. $$t=0$$은 원문, $$t=1$$은 전부 mask다. 일반 어휘에 특별한 mask 기호가 포함되지 않는다고 가정한다. 토큰 네 개에 $$t=0.5$$를 적용해도 정확히 두 개만 가려진다는 뜻은 아니다. **평균적으로 두 개**가 가려지며, 실제 개수는 달라진다.

이때 보이는 토큰은 오염된 가짜 단어가 아니라 원래 값 그대로다. 모델은 남은 문맥을 조건으로 숨겨진 토큰의 분포를 예측하면 된다. RADD는 absorbing diffusion에서 이 clean conditional과 SEDD의 확률비 사이 관계를 명확히 한다. MDLM과 MD4도 masked diffusion의 목적을 단순화한 중요한 동시대 연구다. 발표의 계보는 이 연구들의 연결을 보여주는 것이며, SEDD 이전에 이산 확산이 없었다는 뜻은 아니다.

<details markdown="block">
<summary markdown="span">Derivation: A discrete score becomes a clean-token conditional</summary>

$$x$$에서 위치 $$i$$가 mask이고, $$y$$는 그 위치만 일반 토큰 $$a$$로 바뀐 상태라고 하자. 다른 위치는 같고, 원문의 각 위치가 같은 확률 $$t$$로 독립 마스킹된다고 가정한다. $$0<t<1$$에서

$$
\frac{p_t(y)}{p_t(x)}
=\frac{1-t}{t}\,
p_{\mathrm{data}}(X_0^i=a\mid X_0^O=x^O).
$$

$$O$$는 $$x$$에서 보이는 위치들의 집합이다. 분모는 그 위치들의 값과 일치하는 모든 원문 확률을 합친 뒤, 해당 mask 패턴의 확률을 곱한다. 분자는 추가로 $$X_0^i=a$$를 만족하는 원문만 합친다. 위치 $$i$$가 mask일 확률 $$t$$ 대신 보일 확률 $$1-t$$가 들어가므로 앞의 비율이 남고, 원문 확률 합의 비는 조건부 확률이 된다.

설명용 예로 $$t=0.5$$이고 보이는 문맥에서 `sky`의 조건부 확률이 0.8이면, 해당 상태의 비율도 0.8이다. $$t=0.2$$라면 비율은 $$4\times0.8=3.2$$다. 비율이 1을 넘는 것은 오류가 아니다. 토큰의 조건부 확률 0.8은 그대로이고, 서로 다른 mask 패턴의 상대 발생 확률이 달라진 것이다.

이 관계는 mask-only corruption에 의존한다. 임의의 토큰 교체를 허용해 현재 보이는 단어도 틀릴 수 있다면 같은 식을 그대로 사용할 수 없다. [RADD, Theorem 1](https://arxiv.org/abs/2406.03736){:target="_blank" rel="noopener"}.

</details>

## 4. What Each Paper Added

| Work | Problem | Contribution |
|---|---|---|
| SEDD | 이산 상태에는 연속 score의 좌표 미분을 그대로 적용할 수 없다 | 상태 간 확률비와 score entropy로 역방향 전이를 학습 |
| MDLM | masked diffusion의 복잡한 목적함수와 매개변수화를 단순화할 필요가 있다 | mask 예측 중심의 단순한 목적과 매개변수화, 효율적인 생성 방법 |
| MD4 | 이산 diffusion의 설계·학습 목적을 더 간결하게 이해해야 한다 | masked diffusion의 간소화와 일반화, 학습 가능한 noise schedule |
| RADD | 확률비와 clean conditional의 연결, 시간 입력의 필요성이 불분명하다 | 확률비의 시간 인자 분리와 time-independent 조건부 예측, any-order AR 목적과의 연결 |
| SMDM | 작은 모델의 가능성이 큰 학습 예산에서도 유지되는가? | masked diffusion의 scaling 관계와 downstream 평가, unsupervised guidance |
| LLaDA | 사전학습뿐 아니라 지시 수행까지 가능한 대규모 모델인가? | 8B masked diffusion 모델의 사전학습·SFT·생성과 다양한 과제 평가 |

각 논문은 앞선 연구를 단순히 이름만 바꾼 것이 아니다. SEDD의 질문은 **무엇을 추정할 것인가**, masked diffusion 연구의 질문은 **어떤 손상 과정에서 학습이 단순해지는가**, LLaDA의 질문은 **그 목적이 실제 대규모 언어 능력으로 이어지는가**에 가깝다. 이론적 등가, 효율적인 구현, 실험적 성능은 서로 다른 근거를 요구한다.

연도는 preprint와 학회 발표를 구별해야 한다. SEDD는 2023년 preprint와 ICML 2024 논문이며, MDLM·MD4·RADD는 2024년 6월의 동시대 연구다. 특히 슬라이드 21의 RADD 학회 표기는 **ICLR 2025**로 정정한다. SMDM의 실험 규모는 최대 **1.1B**이며, 8B 확장은 LLaDA의 결과다. [RADD 학회 기록](https://proceedings.iclr.cc/paper_files/paper/2025/hash/a365e37c18fb91af547a2f0012a89e98-Abstract-Conference.html){:target="_blank" rel="noopener"}.

## 5. BERT and LLaDA: Similar Predictions, Different Generative Contracts

BERT도 가려진 토큰의 정답을 cross-entropy(CE)로 학습한다. 그러나 원래 BERT에서는 전체 토큰의 15%를 예측 대상으로 선택한 뒤, 그중 80%를 mask로, 10%를 임의 토큰으로 바꾸고 10%는 그대로 둔다. “BERT는 항상 전체의 15%를 mask로 바꾼다”는 표현은 이 차이를 지운다. BERT의 원래 사전학습에는 next sentence prediction도 포함된다. [BERT, §3.1](https://aclanthology.org/N19-1423/){:target="_blank" rel="noopener"}.

LLaDA는 여러 손상 수준을 학습하고, 전부 mask인 상태에서 문장을 생성하는 역과정과 학습 목적을 연결한다. **BERT로는 어떤 생성도 불가능하다는 주장이 아니라, 원래 학습·생성 계약이 다르다는 뜻**이다.

LLaDA의 사전학습 목적은 다음과 같다. $$\theta$$는 학습 매개변수, $$p_\theta(x_0^i\mid x_t)$$는 현재 문맥에서 위치 $$i$$의 정답 토큰에 부여하는 확률이다.

$$
\mathcal L(\theta)
=\mathbb E_{t,x_0,x_t}\left[
\frac{1}{t}\sum_{i=1}^{L}\mathbf1[x_t^i=M]
\left(-\log p_\theta(x_0^i\mid x_t)\right)
\right],\qquad t\sim\mathcal U(0,1).
$$

마스크가 된 위치만 정답을 맞히도록 하고, 그 합에 $$1/t$$를 곱한다. 원문을 알고 마스킹했으므로 별도 정답 라벨을 수집할 필요가 없다. 정답 확률이 0.8이면 CE는 약 0.2231 nats, 0.2이면 약 1.6094 nats다. **확신 있게 정답을 맞히는 예측에 더 작은 손실**을 주는 원리는 동일하다.

차이는 $$1/t$$와 시간 전체의 평균이 생성 과정의 확률적 의미를 갖는다는 점이다. 실제 학습에서는 매번 하나의 $$t$$와 mask 패턴을 뽑아 이 기대값을 추정한다. 한 번의 학습 예시를 만들기 위해 모든 역방향 단계를 실행하는 것은 아니다.

<details markdown="block">
<summary markdown="span">Derivation: Why the masking objective has a 1/t weight</summary>

단조 전방 마스킹을 구성하기 위해 위치마다 $$U_i\sim\mathcal U(0,1)$$를 한 번 뽑고, $$U_i\le t$$이면 그 위치가 mask라고 하자. 이 구성은 각 시점의 마스킹 확률 $$t$$를 만족한다. 시간을 $$t$$에서 $$t-\Delta t$$로 되돌릴 때, 이미 mask인 위치가 복원되는 조건은 $$t-\Delta t<U_i\le t$$다. 따라서 $$0<\Delta t\le t$$에서

$$
\Pr(\text{unmask}\mid\text{masked at }t)
=\frac{\Pr(t-\Delta t<U_i\le t)}{\Pr(U_i\le t)}
=\frac{\Delta t}{t}.
$$

예를 들어 $$t=0.8$$에서 0.6으로 되돌리면 현재 mask 중 기대 비율 0.25를 복원한다. 전체 위치 중 mask인 기대 비율은 $$0.8(1-0.25)=0.6$$이 된다. 반대로 0.2에서 0으로 가는 마지막 구간은 남은 mask를 모두 복원한다.

이 복원 사건에서 정답 토큰을 예측하는 CE를 시간 구간별로 가중 합하고, 연속시간 극한을 취하면 다음 형태가 나온다.

$$
\sum_k\frac{\Delta t_k}{t_k}
\mathbb E[\mathrm{CE}_{\mathrm{masked}}(t_k)]
\longrightarrow
\int_0^1\frac{1}{t}
\mathbb E[\mathrm{CE}_{\mathrm{masked}}(t)]\,dt.
$$

이 과정은 **선형 마스킹 확률에서의 가중치를 설명하는 유도**다. 전체 likelihood bound를 증명하려면 아래의 변분적 논리도 필요하다. 일반적인 생존 확률 $$\alpha(t)$$를 쓰면 가중치는 $$-\alpha'(t)/(1-\alpha(t))$$이고, $$\alpha(t)=1-t$$일 때 $$1/t$$가 된다.

$$t=0$$에서는 그대로 나눌 수 없다. 끝점은 연속 분포에서 확률 0인 사건이며, 구현은 작은 양의 하한 등을 사용한다. $$t$$가 작을 때 mask가 드물어진다는 점도 중요하다. 한 위치에 대해

$$
\mathbb E\left[\frac{\mathbf1[x_t^i=M]}{t}\mathrm{CE}_i\right]
=\mathbb E[\mathrm{CE}_i\mid x_t^i=M]
$$

이므로 mask 발생 확률 $$t$$가 기대값에서 상쇄된다. 단, 이 식은 손실이 모든 $$t$$에서 같다는 뜻이 아니다. 남아 있는 문맥이 달라지면 조건부 CE도 달라지고, 단일 표본의 분산은 커질 수 있다. 코드에서 토큰 평균을 내는지, 합을 쓰는지에 따라서도 숫자 크기가 달라진다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: From reverse trajectories to a likelihood bound</summary>

먼저 유한한 시간 격자에서 원문 $$x_0$$와 손상 경로 $$z$$를 생각하자. 전방 경로 분포를 $$q(z\mid x_0)$$, 생성 모델의 결합분포를 $$p_\theta(x_0,z)$$로 둔다. 적절한 support 조건에서 Jensen 부등식으로

$$
\begin{aligned}
\log p_\theta(x_0)
&=\log\mathbb E_{q(z\mid x_0)}
\left[\frac{p_\theta(x_0,z)}{q(z\mid x_0)}\right]\\
&\ge\mathbb E_{q(z\mid x_0)}
\left[\log\frac{p_\theta(x_0,z)}{q(z\mid x_0)}\right].
\end{aligned}
$$

우변이 evidence lower bound(ELBO)다. 부호를 바꾸면 **negative log-likelihood의 상한**을 얻는다. 더 정확히는 음의 ELBO와 NLL의 차이가 전방 경로 분포와 모델의 경로 posterior 사이 KL이다.

$$
-\mathrm{ELBO}(x_0)
=-\log p_\theta(x_0)
+D_{\mathrm{KL}}\!\left(q(z\mid x_0)\Vert p_\theta(z\mid x_0)\right).
$$

Absorbing 과정, 적절한 reverse parameterization과 끝점 조건을 적용하고 연속시간 극한을 취하면 masked-token의 가중 CE 형태로 정리된다. 이 마지막 전개는 [MDLM](https://arxiv.org/abs/2406.07524){:target="_blank" rel="noopener"}, [MD4](https://arxiv.org/abs/2406.04329){:target="_blank" rel="noopener"}, [RADD](https://arxiv.org/abs/2406.03736){:target="_blank" rel="noopener"}의 유도에 해당한다. 임의의 diffusion에 끝점 항 없이 같은 목적을 적용할 수 있다는 뜻은 아니다.

슬라이드 12는 개별 문장의 NLL과 데이터 전체 기대 손실을 한 줄에서 비교한다. 같은 범위로 쓰려면 표본별 bound $$-\log p_\theta(x_0)\le\mathcal L(x_0;\theta)$$ 또는 그 양쪽을 데이터에 대해 평균한 식을 사용해야 한다.

$$
\mathbb E_{x_0\sim p_{\mathrm{data}}}[-\log p_\theta(x_0)]
\le\mathbb E_{x_0\sim p_{\mathrm{data}}}[\mathcal L(x_0;\theta)].
$$

이는 **상한을 최소화하는 원리**다. 손실 감소가 모든 개별 문장의 실제 NLL 감소를 보장하지 않으며, 유한 단계·confidence 기반 sampling이 이론의 이상적인 역과정과 완전히 같다는 보장도 아니다.

</details>

## 6. Training: The Same Predictor, Different Contexts

![Pretraining masks the full sequence while supervised fine-tuning masks only the response](/assets/images/post/discrete-diffusion-language-models/pretraining-and-sft.png)

*발표 슬라이드 15. 왼쪽은 전체 텍스트 사전학습, 오른쪽은 prompt를 보존한 response 학습이다.*

그림의 색 막대는 토큰, X가 그어진 칸은 mask다. 회색 `Mask predictor`가 Transformer다. **왼쪽의 입력은 일부가 가려진 전체 문장이고, 출력은 가려진 위치의 어휘 분포**다. 오른쪽에서는 prompt를 가리지 않고 response 일부만 가린다. 모델이 답변을 예측할 때 질문과 현재 보이는 답변 토큰을 함께 활용하도록 만드는 차이다.

LLaDA는 Transformer에서 causal attention mask를 사용하지 않는다. 따라서 현재 입력의 오른쪽에 보이는 토큰도 참고할 수 있다. 이때 **attention의 causal mask를 없애는 것**과 **입력 토큰을 `[MASK]`로 가리는 것**은 완전히 다른 연산이다. 전자는 어떤 위치를 볼 수 있는지, 후자는 어떤 토큰 값을 감추는지를 결정한다.

SFT에서는 prompt $$c$$와 원래 response $$r_0$$, 손상된 response $$r_t$$를 사용한다. $$L_r$$는 response 길이다.

$$
\mathcal L_{\mathrm{SFT}}(\theta)
=\mathbb E_{t,c,r_0,r_t}\left[
\frac1t\sum_{i=1}^{L_r}\mathbf1[r_t^i=M]
\left(-\log p_\theta(r_0^i\mid c,r_t)\right)
\right].
$$

Prompt에 대한 복원 손실은 계산하지 않는다. 같은 mask 예측 모델에 **어떤 문맥을 고정하고 어떤 영역을 학습 대상으로 삼는지**가 달라진다. 여기서 설명하는 LLaDA의 post-training은 SFT이며, 그 결과에 RL 정렬까지 수행했다고 덧붙이면 안 된다.

### Why the predictor need not receive time explicitly

발표는 RADD의 $$p(x_0\mid x_t,t)=p(x_0\mid x_t)$$를 강조한다. 의미는 **현재 보이는 토큰과 mask 패턴을 알고 있다면, 원문을 추정하는 데 별도의 시간 입력이 필수는 아니라는 것**이다. 마스킹이 토큰 값과 무관하게 독립 적용되는 absorbing 과정이라는 조건이 붙는다.

이것은 생성 알고리즘이 시간을 전혀 사용하지 않는다는 뜻이 아니다. 몇 개의 mask를 복원할지 정하는 schedule과 전이율에는 여전히 시간이 들어간다. 토큰 예측기와 sampling schedule의 역할을 분리한 결과다.

<details markdown="block">
<summary markdown="span">Derivation: Why time cancels from the clean posterior</summary>

보이는 위치 집합을 $$O$$, mask 위치 집합을 $$H$$라 하자. 각 위치를 같은 확률로 독립 마스킹하면, 후보 원문 $$x_0$$에 대한 likelihood는

$$
q_t(x_t\mid x_0)
=t^{\lvert H\rvert}(1-t)^{\lvert O\rvert}
\mathbf1[x_0^O=x_t^O].
$$

Bayes 법칙의 분자와 분모에 같은 mask 패턴 확률이 들어간다. $$0<t<1$$에서 이 인자가 상쇄되어

$$
p(x_0\mid x_t,t)
=\frac{p_{\mathrm{data}}(x_0)\mathbf1[x_0^O=x_t^O]}
{\sum_{x'_0}p_{\mathrm{data}}(x'_0)\mathbf1[(x'_0)^O=x_t^O]}.
$$

우변은 현재 보이는 값만으로 결정되고 $$t$$가 없다. 관측된 상태의 확률이 양수라는 조건이 필요하다. 원문의 내용에 따라 mask 확률을 달리하거나 일반 토큰을 다른 토큰으로 교체하면 이 인자가 원문 후보마다 달라질 수 있어 같은 상쇄를 보장하지 않는다.

이 정리는 **이상적인 데이터 조건부 분포**에 대한 것이다. 유한한 신경망이 그 분포를 정확히 학습했다는 증명은 아니다. 또한 모든 위치의 조건부 marginal을 병렬 예측한다고 해서, 동시에 샘플링한 여러 토큰의 결합 의존성까지 정확히 재현하는 것은 아니다.

</details>

### What scaling to 8B means

발표 슬라이드 14의 표에서 LLaDA 8B는 32 layers, hidden dimension 4,096, attention heads 32, vocabulary 126,464, 총 약 8.02B parameters다. 비교된 LLaMA 3 8B와 모든 내부 설정이 같지는 않다. 예를 들어 LLaDA 표의 key/value heads는 32, LLaMA 3는 8이다. 따라서 “causal mask만 다르고 완전히 같은 모델”이라고 읽지 않는다.

LLaDA 원 논문은 **2.3T 토큰의 사전학습과 4.5M instruction pairs의 SFT**를 보고한다. 연구의 의의는 기존 AR 모델을 단순히 추론 때만 변형한 것이 아니라, masked diffusion 목적을 사용한 대규모 사전학습으로 언어 능력을 얻었다는 점이다. [LLaDA, §2 및 Appendix B](https://arxiv.org/abs/2502.09992){:target="_blank" rel="noopener"}.

## 7. Generation: Parallel Proposals, Iterative Decisions

![LLaDA generation keeps the prompt visible and repeatedly predicts and selects response tokens](/assets/images/post/discrete-diffusion-language-models/generation.png)

*발표 슬라이드 16. Prompt는 고정하고 response의 mask 위치를 단계적으로 채운다.*

위에서 아래로 읽으면, 먼저 정해진 길이의 답변 영역을 모두 mask로 만든다. 각 단계에서 모델은 현재 mask 위치들의 토큰 후보를 병렬 예측한다. 그중 일부를 남기고 나머지는 다시 mask로 두어 다음 단계에서 새 문맥을 보고 예측한다. Random remasking은 선택을 무작위로, low-confidence remasking은 신뢰도가 낮은 후보를 우선 미확정으로 남기는 방식이다.

다음은 처리 순서만 보여주는 **설명용 예시**이며 실제 모델 출력이나 문장의 정확한 tokenizer 분할이 아니다.

| Step | Current response | Interpretation |
|---|---|---|
| 0 | `[M] [M] [M] [M]` | 생성할 네 위치가 모두 미정 |
| 1 | `The [M] [M] blue` | 한 번의 예측에서 일부 후보만 확정 |
| 2 | `The sky [M] blue` | 새로 드러난 문맥을 사용해 다음 위치 확정 |
| 3 | `The sky is blue` | 남은 mask를 채워 종료 |

**병렬 예측은 한 번에 완성한다는 뜻이 아니다.** 각 단계의 Transformer 계산을 여러 번 반복하고, 단계 수를 줄이면 품질과 속도의 균형이 바뀐다. 한 단계에서 위치별 분포로 독립 샘플링한 후보들이 문법적으로 충돌할 수 있으므로, 작은 단계로 문맥을 갱신하는 과정이 중요하다.

또한 발표 슬라이드 5의 `are`를 `is`로 바꾸는 그림은 iterative refinement의 가능성을 보여준다. **기본 absorbing sampler에서 이미 확정된 모든 토큰을 언제든 다시 고치는 기능이 자동으로 생기는 것은 아니다.** 현재 mask 위치의 후보를 확정하지 않고 남기는 remasking과, 이전에 확정한 토큰까지 다시 지우는 별도 수정 정책을 구별해야 한다.

일반적인 AR decoding은 과거 토큰의 key/value를 재사용한다. 양방향 모델에서는 새 토큰이 채워지면 기존 위치의 표현도 바뀔 수 있어 같은 KV cache를 그대로 적용하기 어렵다. 따라서 실제 효율 비교에는 모델 크기뿐 아니라 생성 길이, 반복 횟수, batch size, 하드웨어, cache 정책과 품질 조건이 필요하다. 확산의 병렬성만으로 latency 우위를 결론낼 수 없다.

## 8. Reading the Results Without Overclaiming

### Scaling curves compare training compute, not decoding latency

![Six benchmark plots compare LLaDA and autoregressive baselines against pretraining FLOPs](/assets/images/post/discrete-diffusion-language-models/scaling-results.png)

*발표 슬라이드 17, LLaDA Figure 3. 가로축은 사전학습 FLOPs이며 로그 눈금이다. 파란 점은 AR baseline, 주황 별은 LLaDA다.*

여섯 패널은 MMLU, ARC-C, CMMLU, PIQA, GSM8K, HumanEval을 각각 보여준다. 세로축은 각 과제의 점수이며, 제목의 shot 수는 평가 입력에 제공한 예시 개수다. 각 패널의 세로축 범위가 다르므로 점의 높이나 기울기를 패널 사이에서 그대로 비교하지 않는다.

먼저 같은 패널에서 비슷한 학습 FLOPs의 점들을 비교한다. 계산량이 증가할 때 LLaDA 점수도 개선되고, 과제에 따라 AR보다 높거나 낮다. 특히 PIQA처럼 AR이 더 높은 영역이 보인다. 이 결과는 **같은 데이터로 학습한 저자들의 AR baseline과 비교했을 때 masked diffusion도 확장 가능한 경향을 보인다**는 근거다. 모든 과제의 우위, 특정 계산량에서의 정확한 인과 효과, 추론 속도를 증명하는 그림은 아니다.

슬라이드 14의 작은 SMDM 그래프는 다른 비교다. 가로축은 non-embedding parameter 수, 세로축은 validation loss, 곡선별 색은 고정된 학습 예산이다. 고정 예산에서 모델만 키우면 학습 데이터·업데이트에 쓸 자원이 줄어들 수 있어 U자형 최적점이 생긴다. 이 그래프 역시 “모델이 클수록 무조건 손실이 작아진다”는 뜻이 아니다.

### Base models: strengths depend on the benchmark

발표 슬라이드 18의 Table 1에서 같은 평가 protocol 표시가 붙은 LLaDA 8B와 LLaMA 3 8B의 일부 행을 뽑으면 다음과 같다. 점수는 백분율 척도이며 괄호 대신 별도 열에 shot 수를 적었다.

| Benchmark | Shots | LLaDA 8B | LLaMA 3 8B |
|---|---:|---:|---:|
| MMLU | 5 | 65.9 | 65.4 |
| GSM8K | 4 | 70.3 | 48.7 |
| Math | 4 | 31.4 | 16.0 |
| PIQA | 0 | 73.6 | 80.6 |
| HumanEval | 0 | 35.4 | 34.8 |

LLaDA가 일부 수학 과제에서 높지만 PIQA에서는 낮다. 더구나 학습 데이터와 tokenizer, 세부 구조가 같지 않고, 표의 사전학습 토큰 수도 2.3T와 15T로 다르다. **이 표는 완제품 모델의 능력 비교이지 생성 방식 하나만의 통제 실험이 아니다.** 다른 열의 Qwen 등은 별도 문헌에서 가져온 값과 서로 다른 shot 조건도 포함하므로 전체 표를 단일한 공정 순위로 합치지 않는다.

### Instruction tuning does not erase the differences

슬라이드 19의 Table 2는 SFT 이후 LLaDA와 post-trained AR 모델을 비교한다. LLaDA는 SFT만 사용했고, 비교군에는 RL alignment까지 적용한 모델이 있다.

| Benchmark | Shots | LLaDA 8B Instruct | LLaMA 3 8B Instruct |
|---|---:|---:|---:|
| MMLU | 5 | 65.5 | 68.4 |
| GSM8K | 4 | 69.4 | 78.3 |
| Math | 0 | 31.9 | 29.6 |
| HumanEval | 0 | 49.4 | 59.8 |

사전학습 표에서의 우열이 SFT 이후에도 그대로 유지되는 것은 아니다. 특히 위 두 표의 Math는 shot 조건부터 다르다. 숫자를 단순 차감해 SFT의 순수 효과라고 해석하지 않는다. 결과가 뒷받침하는 핵심은 **diffusion 기반 모델에서도 지시문을 따르는 능력을 얻을 수 있다**는 점이지, AR보다 전반적으로 우수하다는 주장이 아니다.

## 9. What Changed, and What Still Needs Work

SEDD에서 LLaDA로 이어지는 흐름에서 가장 큰 변화는 학습 대상의 표현이다. 이산 상태 사이 확률비를 직접 바라보던 관점이, absorbing mask 조건 아래에서는 익숙한 **토큰 분류와 가중 CE**로 연결된다. 그 결과 Transformer를 사용한 사전학습·SFT와 결합하기 쉬워졌다.

그러나 수학적으로 타당한 생성 목적, benchmark 경쟁력, 효율적인 서비스는 별개의 단계다. 반복 추론 비용을 줄이려면 단계 수와 품질을 함께 평가하고, cache·blockwise generation 등의 설계가 실제 지연시간에 주는 효과를 측정해야 한다. 이미 확정한 오답을 고치려면 별도의 재마스킹 정책을 정의하고 안정성까지 검증해야 한다. 이런 방향은 확장 가능성이며, 이 발표의 실험이 모두 해결했다고 볼 수는 없다.

## Key Takeaways

- **AR은 결합분포를 모델링하는 강력한 선택이지만 유일한 선택은 아니다.**
- **SEDD의 확률비와 masked-token 확률은 같은 값이 아니다.** Absorbing 과정에서 시간 인자를 통해 연결된다.
- **LLaDA의 핵심은 mask 예측을 생성모형의 likelihood bound와 연결한 학습이다.** $$1/t$$는 선형 마스킹 schedule에서 나온다.
- **시간 입력의 불필요성은 clean-token 예측기에 대한 조건부 성질이다.** Sampling schedule까지 사라지는 것은 아니다.
- **그림은 학습·생성 흐름과 과제별 scaling을 보여준다.** 병렬성, 전반적 우위, 실제 latency는 각각 별도 검증이 필요하다.

## References

- <a href="{{ '/assets/pdfs/post/26-2-paper-research-seminar/how-did-discrete-diffusion-become-a-large-language-model.pdf' | relative_url }}" target="_blank" rel="noopener">Seminar Slides — How Did Discrete Diffusion Become a Large Language Model?</a> · 이혜은, 2026.10.12. 본문 그림은 제공된 슬라이드 10·15·16·17을 렌더링했다.
- <a href="https://proceedings.mlr.press/v235/lou24a.html" target="_blank" rel="noopener">Lou, Meng, and Ermon — Discrete Diffusion Modeling by Estimating the Ratios of the Data Distribution</a>, ICML 2024. SEDD의 확률비·score entropy.
- <a href="https://arxiv.org/abs/2406.07524" target="_blank" rel="noopener">Sahoo et al. — Simple and Effective Masked Diffusion Language Models</a>, 2024. MDLM의 단순화된 목적함수.
- <a href="https://arxiv.org/abs/2406.04329" target="_blank" rel="noopener">Shi et al. — Simplified and Generalized Masked Diffusion for Discrete Data</a>, 2024. MD4의 masked diffusion 정식화.
- <a href="https://arxiv.org/abs/2406.03736" target="_blank" rel="noopener">Ou et al. — Your Absorbing Discrete Diffusion Secretly Models the Conditional Distributions of Clean Data</a>, 2024 preprint / ICLR 2025. RADD의 조건부 분포와 시간 인자 분리.
- <a href="https://arxiv.org/abs/2410.18514" target="_blank" rel="noopener">Nie et al. — Scaling Up Masked Diffusion Models on Text</a>, 2024 preprint / ICLR 2025. SMDM의 scaling 연구.
- <a href="https://arxiv.org/abs/2502.09992" target="_blank" rel="noopener">Nie et al. — Large Language Diffusion Models</a>, 2025. 학습·생성, Figure 3, Tables 1·2·5.
- <a href="https://github.com/ML-GSAI/LLaDA" target="_blank" rel="noopener">LLaDA Official Repository</a>. 학습 목적 예시·sampling 구현·연구 계보.
- <a href="https://aclanthology.org/N19-1423/" target="_blank" rel="noopener">Devlin et al. — BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding</a>, 2019. 원래 MLM의 15% 선택과 80/10/10 처리.
- <a href="https://arxiv.org/abs/2011.13456" target="_blank" rel="noopener">Song et al. — Score-Based Generative Modeling through Stochastic Differential Equations</a>, ICLR 2021. 슬라이드 6의 연속 확산 score와 역 SDE 해석.
