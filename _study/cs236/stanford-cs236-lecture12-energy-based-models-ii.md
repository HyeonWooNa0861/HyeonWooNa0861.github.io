---
layout: default
date: 2026-08-19 15:27:32 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CS236 Lecture 12: Energy-Based Models II"
course: "CS236"
topic: "Score Matching, Noise Contrastive Estimation, and Sampling-Free EBM Training"
order: 12
major_topic: "Deep Generative Models"
keywords:
  - "Energy-Based Models"
  - "Score Matching"
  - "Fisher Divergence"
  - "Noise Contrastive Estimation"
  - "Langevin MCMC"
---

# Stanford CS236 Lecture 12: Energy-Based Models II

## Source

- Video: [Stanford CS236 Deep Generative Models Lecture 12](https://www.youtube.com/watch?v=Nci1Bepcy0g){:target="_blank" rel="noopener"}
- Source PDF: [cs236_lecture12.pdf](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}

> **핵심:** EBM은 후보의 상대 점수는 알지만 모델이 믿는 sample을 직접 뽑기 어렵습니다. 12강은 후보를 조금씩 고치는 MCMC, 더 그럴듯한 방향을 배우는 score matching, 실제 데이터와 noise를 구별하는 NCE로 이 병목을 풉니다.

EBM의 상대 점수는 두 입력 중 무엇이 더 그럴듯한지는 말해 주지만, 실제 표본을 얻거나 normalized likelihood를 계산하려면 어려운 $$Z(\theta)$$가 다시 나타납니다. Score는 log-density를 입력 방향으로 미분해 $$Z(\theta)$$를 없애고, NCE는 데이터와 알려진 noise를 구분하는 문제로 바꿉니다. 각 방법은 같은 병목을 서로 다른 계산으로 우회합니다.

## 전체 흐름

<details markdown="block">
<summary markdown="span">학습 순서와 원문 대조 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | EBM recap | $$Z(\theta)$$ 때문에 likelihood와 sampling은 왜 어렵지만 ratio와 score는 가능합니까? |
| 2 | MCMC sampling | Metropolis-Hastings와 Langevin dynamics는 EBM sample을 어떻게 만듭니까? |
| 3 | Score function | $$\nabla_x\log p_\theta(x)$$에서 partition function은 왜 사라집니까? |
| 4 | Score matching | data score를 몰라도 Fisher divergence를 어떻게 최적화 가능한 형태로 바꿉니까? |
| 5 | NCE | noise distribution과 binary classifier로 EBM과 partition function을 어떻게 학습합니까? |
| 6 | Adversarial EBM training | variational distribution을 사용하면 EBM likelihood를 어떤 game으로 바꿀 수 있습니까? |

### 원본 수식 위치

| 원본 PDF | 중요한 식·도식 | 본문 처리 |
|---|---|---|
| pp. 2--4 | EBM recap, symmetric MH, unadjusted Langevin update | `핵심 내용`과 `score와 Langevin update`에서 조건부 정확성 및 수치 근사를 구분합니다. |
| pp. 6--10 | EBM score, Fisher divergence, integration-by-parts objective | 두 `핵심 수식 유도`에서 항등식, 경계 가정, 실패 조건을 설명합니다. |
| pp. 12--16 | NCE classifier, trainable normalizer, stable loss | `NCE cross-entropy와 안정적 estimator`에서 population optimum과 수치 안정화를 구분합니다. |
| pp. 18--19 | Flow contrastive estimation | `핵심 내용`에서 tractable noise model을 학습하는 원문 확장으로 설명합니다. |
| p. 20 | Variational upper bound와 adversarial EBM game | `핵심 내용`에서 원문 objective를 model-sampling 대안으로 설명합니다. |

</details>

## 원본 그림 해설

### 색으로 구분된 score matching 전개

<figure>
  <a href="{{ "/assets/images/study/cs236/source-captures/lecture-12-source-09-excerpt.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs236/source-captures/lecture-12-source-09-excerpt.png" | relative_url }}" alt="CS236 Lecture 12, p. 9: 색으로 구분한 score matching 제곱 전개와 부분적분. 원본 발췌." loading="lazy"></a>
  <figcaption><a href="https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf#page=9" target="_blank" rel="noopener">Original p. 9</a> — 색으로 구분한 score matching 제곱 전개와 부분적분. 필요한 영역만 발췌했습니다. 이미지를 누르면 확대됩니다.</figcaption>
</figure>

[Lecture 12 PDF p. 9](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf#page=9){:target="_blank" rel="noopener"}

원본의 파란 항은 데이터 분포만 포함하므로 $$\theta$$에 대해 상수입니다. 초록 항은 모델 score의 제곱이고, 빨간 교차항은 부분적분 후 갈색의 두 번째 미분 항으로 바뀝니다. 이 변형 덕분에 모르는 data score를 직접 입력하지 않고 모델의 미분으로 목적함수를 계산합니다. 단, 경계항이 사라지는 조건이 필요하며 아래 유도에서 그 조건을 확인합니다.

<figure>
  <a href="{{ "/assets/images/study/cs236/source-captures/lecture-12-source-13-excerpt.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/study/cs236/source-captures/lecture-12-source-13-excerpt.png" | relative_url }}" alt="CS236 Lecture 12, p. 13: model density와 noise density로 구성한 NCE 판별 확률. 원본 발췌." loading="lazy"></a>
  <figcaption><a href="https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf#page=13" target="_blank" rel="noopener">Original p. 13</a> — model density와 noise density로 구성한 NCE 판별 확률. 필요한 영역만 발췌했습니다. 이미지를 누르면 확대됩니다.</figcaption>
</figure>

[PDF p.13](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf#page=13){:target="_blank" rel="noopener"}의 NCE 분수는 model density와 알려진 noise density의 상대 크기를 판별 확률로 바꿉니다. 원문의 마지막 줄은 판별기의 odds를 noise density에 곱해 data density를 복원하는 관계입니다. 그림의 분모에 혼합 비율이 따로 없는 식은 data/noise의 class prior가 같은 설정으로 읽어야 합니다.

## 핵심 내용

11강에서 EBM은 후보의 상대 점수는 쉽게 비교했지만, 모델이 믿는 후보를 직접 뽑는 과정은 어려웠습니다. 12강은 이 막힌 지점을 세 갈래로 풉니다. Score matching은 데이터 주변에서 점수가 커지는 방향을 맞추고, NCE는 실제 데이터와 미리 정한 잡음을 구별하며, MCMC는 현재 후보를 조금씩 고쳐 모델 분포를 탐색합니다. 세 방법은 모두 계산하기 어려운 전체 정규화 합을 직접 구하지 않는다는 공통점이 있습니다.

Lecture 12는 EBM의 가장 큰 병목인 sampling과 likelihood 학습을 우회하는 방법을 다룹니다. 지난 강의의 기본 형태는

$$
p_\theta(x)=\frac{\exp(f_\theta(x))}{Z(\theta)}
$$

였습니다. $$Z(\theta)$$를 계산하기 어렵기 때문에 likelihood를 직접 평가하기 어렵고, contrastive divergence로 maximum likelihood gradient를 근사하려면 매 training step마다 $$x_{\mathrm{sample}}\sim p_\theta$$를 뽑아야 합니다. 그런데 EBM에서 sampling 자체도 어렵습니다. 이 강의는 먼저 MCMC sampling을 복습한 뒤, sampling 없이 또는 model sampling을 덜 요구하면서 EBM을 학습하는 score matching, noise contrastive estimation, adversarial training을 정리합니다.

Metropolis-Hastings MCMC는 현재 상태 $$x_t$$에서 symmetric random-walk perturbation으로 $$x'$$를 제안할 때, $$f_\theta(x')\ge f_\theta(x_t)$$이면 항상 받아들이고 더 낮은 score라면 $$\exp(f_\theta(x')-f_\theta(x_t))$$ 확률로 받아들입니다. 즉 강의의 $$\min\{1,\exp(f_\theta(x')-f_\theta(x_t))\}$$ 식은 **symmetric proposal에 한정**됩니다. 비대칭 proposal $$q(x'\mid x_t)$$에서는 Hastings ratio $$q(x_t\mid x')/q(x'\mid x_t)$$까지 곱해야 detailed balance가 성립합니다. 이론적으로 충분히 오래 반복하면 target distribution에 수렴할 수 있지만, high-dimensional image space에서는 많은 iteration이 필요합니다.

Langevin MCMC는 더 informed proposal을 만듭니다.

$$
x_{t+1}=x_t+\epsilon\nabla_x\log p_\theta(x_t)+\sqrt{2\epsilon}z_t,\qquad z_t\sim\mathcal{N}(0,I)
$$

EBM에서는 $$Z(\theta)$$가 $$x$$에 의존하지 않으므로

$$
\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)
$$

가 됩니다. 즉 score direction을 따라 likelihood가 증가하는 쪽으로 움직이되, Gaussian noise를 섞어 exploration을 유지합니다. 이 방법은 단순 random walk보다 낫지만, training inner loop에서 수천 step의 chain을 반복해야 한다면 여전히 비쌉니다. 따라서 이후 내용의 목표는 "model에서 sample을 뽑지 않고 학습할 수 있는 objective"를 찾는 것입니다.

Score matching은 likelihood 자체가 아니라 score function을 맞춥니다. 이 score는 분류 점수가 아닙니다. 현재 점 $$x$$를 아주 조금 움직일 때 어느 방향으로 가야 모델이 더 그럴듯하다고 평가하는지를 나타내는 화살표입니다. 따라서 각 데이터 점에 올바른 화살표를 붙이는 문제로 바꾸면, 모든 공간의 확률을 먼저 합산하지 않고도 분포의 모양을 배울 수 있습니다.

Stein score는

$$
s_\theta(x)=\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)
$$

이며 partition function을 포함하지 않습니다. 두 분포 $$p,q$$를 비교하는 Fisher divergence는

$$
D_F(p,q)=\frac{1}{2}\mathbb{E}_{x\sim p}\left[\lVert\nabla_x\log p(x)-\nabla_x\log q(x)\rVert_2^2\right]
$$

입니다. $$p=p_{\mathrm{data}}$$, $$q=p_\theta$$로 두면 data score $$\nabla_x\log p_{\mathrm{data}}(x)$$를 모른다는 문제가 남습니다. 강의의 핵심 trick은 integration by parts입니다. data density가 boundary에서 충분히 빠르게 0으로 간다고 가정하면, unknown data score가 들어간 cross term을 model의 second derivative term으로 바꿀 수 있습니다. 다변량에서는 Gauss theorem으로 같은 결과를 얻고, 최적화 가능한 score matching loss는 상수항을 제외하면

$$
\mathbb{E}_{x\sim p_{\mathrm{data}}}\left[\frac{1}{2}\lVert\nabla_x f_\theta(x)\rVert_2^2+\mathrm{tr}(\nabla_x^2 f_\theta(x))\right]
$$

가 됩니다. 이 식은 training data와 model derivative만 필요하므로 EBM sampling이 필요 없습니다. 단점은 Hessian trace 계산이 크고 복잡한 neural network에서 비싸다는 것입니다. 그래서 denoising score matching이나 sliced score matching 같은 scalable approximation이 중요해지며, 다음 diffusion model 강의와 직접 연결됩니다.

Noise Contrastive Estimation(NCE)은 data와 noise를 구분하는 binary classifier를 학습하되, discriminator를 EBM density 형태로 제한합니다. noise distribution $$p_n(x)$$는 sample도 쉽고 likelihood도 계산 가능해야 합니다. 이상적인 discriminator는

$$
D^*(x)=\frac{p_{\mathrm{data}}(x)}{p_{\mathrm{data}}(x)+p_n(x)}
$$

입니다. 이제 discriminator를

$$
D_{\theta,Z}(x)=\frac{\exp(f_\theta(x))}{\exp(f_\theta(x))+Zp_n(x)}
$$

로 parameterize하고 cross-entropy를 최적화하면, $$f_\theta$$와 함께 $$Z$$도 trainable scalar로 학습됩니다. 이론적으로 optimal solution에서는 $$p_{\theta,Z}(x)=p_{\mathrm{data}}(x)$$가 되고, 학습된 $$Z$$가 true partition function이 됩니다. NCE는 GAN과 비슷하게 classifier를 쓰지만, generator를 adversarial하게 업데이트하지 않습니다. noise distribution은 고정되어 있으며, EBM에서 sample을 뽑지 않아도 됩니다. 실제 성능은 $$p_n$$이 data distribution과 충분히 가깝고도 구분 가능해야 한다는 선택 문제에 크게 의존합니다.

Flow contrastive estimation은 이 noise distribution 자체를 normalizing flow $$p_{n,\phi}$$로 parameterize해 더 좋은 contrast를 만들려는 확장입니다. noise가 data와 너무 멀면 classification이 쉬워져 EBM이 세밀한 구조를 배우기 어렵고, 너무 같으면 구분할 신호가 사라집니다. flow를 이용하면 sampling과 likelihood evaluation이 모두 가능하면서 data에 가까운 noise를 학습할 수 있습니다.

### What each training method needs

**Supplementary table —** 아래 비교는 앞의 gradient 식과 [원문 pp. 14–17](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf#page=14){:target="_blank" rel="noopener"}의 NCE 학습 절차를 같은 기준으로 정리한 것입니다. 왼쪽에서 오른쪽으로 학습 입력, 정규화 상수 처리, 남는 계산 부담을 읽습니다. 수치 성능 비교가 아니라 각 목적함수의 계산 의존성을 비교합니다.

<div markdown="block" role="region" aria-label="Energy-based model training comparison" tabindex="0" style="overflow-x: auto;">

| 학습법 | 관측 데이터 외에 필요한 것 | 정규화 상수 처리 | 남는 부담 |
|---|---|---|---|
| MLE의 model-expectation 추정 | 현재 EBM 분포를 대표하는 sample이 필요합니다. 실제로는 MCMC 등으로 근사합니다. | $$\nabla_\theta\log Z(\theta)$$를 model expectation으로 바꿉니다. | Chain이 충분히 섞이지 않으면 expectation 근사가 부정확해집니다. |
| 기본 score matching | 연속 입력에 대한 score와 그 미분을 관측 데이터 위치에서 계산합니다. EBM sample은 필요하지 않습니다. | $$x$$에 대한 미분에서 $$\log Z(\theta)$$가 사라집니다. | Hessian trace 계산과 적분 부분적분의 경계 조건이 필요합니다. |
| 고정 noise 분포를 사용하는 NCE | $$p_n$$에서 noise sample을 뽑고, 데이터와 noise 양쪽에서 $$p_n(x)$$를 평가합니다. EBM sample은 필요하지 않습니다. | $$Z$$를 별도 양의 parameter로 추정합니다. 실전에서는 $$\log Z$$를 parameter로 둘 수 있습니다. | Noise 분포의 선택과 density 평가가 필요합니다. 유한 학습에서 정확한 정규화를 자동 보장하지 않습니다. |
{: .reference-candidate-table style="min-width: 44rem;" }

</div>

따라서 “sampling-free”는 세 방법 모두에서 난수를 전혀 쓰지 않는다는 뜻이 아닙니다. NCE에는 **noise sampling이 남고 EBM sampling이 빠집니다**. 또한 score matching의 미분은 입력 $$x$$에 대한 미분인 반면, MLE의 정규화 항은 parameter $$\theta$$에 대한 미분입니다. 이 차이 때문에 두 방법에서 $$Z$$를 처리하는 방식이 달라집니다.

마지막으로 adversarial training for EBMs는 log-likelihood를 variational distribution $$q_\phi(x)$$로 upper bound하여

$$
\max_\theta\min_\phi\ \mathbb{E}_{x\sim p_{\mathrm{data}}}[f_\theta(x)]-\mathbb{E}_{x\sim q_\phi}[f_\theta(x)]-H(q_\phi)
$$

형태의 game을 만듭니다. $$q_\phi$$는 EBM이 높게 평가하는 negative sample을 제공하고, entropy term은 $$q_\phi$$가 한 점에 collapse하지 않도록 합니다. 이 관점은 GAN과 닮았지만, 목적은 deterministic generator를 학습하는 것이 아니라 EBM의 likelihood 학습을 근사하는 데 있습니다.

<details markdown="block">
<summary markdown="span">Derivation: The score identity and Langevin updates</summary>

> **Source mapping:** Official Lecture 12 PDF p. 4의 unadjusted Langevin update와 p. 6의 EBM score 정의에 대응합니다. SDE에서 Euler--Maruyama로 가는 설명은 작성자 보충입니다.

EBM의 $$Z(\theta)$$가 $$x$$에 의존하지 않고 $$f_\theta$$가 미분 가능하면

$$
\nabla_x\log p_\theta(x)
=\nabla_x(f_\theta(x)-\log Z(\theta))
=\nabla_x f_\theta(x)
$$

은 **정확한 항등식**입니다. 이를 overdamped Langevin SDE $$dX_t=\nabla_x\log p(X_t)dt+\sqrt2\,dW_t$$에 넣고 시간 간격 $$\epsilon$$으로 Euler-Maruyama 이산화하면 강의의 update 식이 나옵니다. $$x$$가 물리 단위를 가지면 score는 그 역단위이고 $$\epsilon$$은 좌표 단위의 제곱이며, 표준화 feature에서는 관례상 무차원입니다. 유한-step update는 **수치 근사**라 큰 $$\epsilon$$에서는 stationary distribution에서 벗어나고, non-smooth energy나 mode 장벽이 큰 분포에서는 mixing이 실패할 수 있습니다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Eliminating the data score by integration by parts</summary>

> **Source mapping:** Official Lecture 12 PDF pp. 8--9의 univariate integration-by-parts 전개와 multivariate score-matching loss에 대응합니다. Boundary·regularity 조건과 단위 해설은 작성자 보충입니다.

$$p=p_{\mathrm{data}}$$, $$s_p=\nabla_x\log p$$, $$s_\theta=\nabla_x\log p_\theta$$라고 하겠습니다. Fisher divergence를 전개하면

$$
\begin{aligned}
D_F(p,p_\theta)
&=\frac12\int_\Omega p(x)\lVert s_p(x)-s_\theta(x)\rVert_2^2dx\\
&=C_p+\frac12\int_\Omega p(x)\lVert s_\theta(x)\rVert_2^2dx
-\int_\Omega p(x)s_p(x)^\top s_\theta(x)dx,
\end{aligned}
$$

여기서 $$C_p=\tfrac12\int p\lVert s_p\rVert^2dx$$는 $$\theta$$와 무관합니다. 핵심 cross term에서 $$p\,s_p=\nabla p$$를 쓰고 좌표별로 integration by parts를 적용하면

$$
\begin{aligned}
-\int_\Omega p\,s_p^\top s_\theta\,dx
&=-\sum_i\int_\Omega (\partial_i p)(s_{\theta,i})\,dx\\
&=-\int_{\partial\Omega}p(x)s_\theta(x)^\top n(x)\,dS
+\int_\Omega p(x)\,\nabla_x\!\cdot s_\theta(x)\,dx.
\end{aligned}
$$

$$n(x)$$은 boundary의 outward unit normal입니다. $$\Omega=\mathbb R^d$$이면 $$\lVert x\rVert\to\infty$$에서 $$p(x)s_\theta(x)$$가 충분히 빨리 0으로 가고, bounded domain이면 $$p(x)s_\theta(x)^\top n(x)=0$$ 같은 boundary condition이 성립한다고 가정해야 surface term이 사라집니다. 그때

$$
D_F(p,p_\theta)
=C_p+\mathbb E_{x\sim p}\left[
\frac12\lVert s_\theta(x)\rVert_2^2
+\nabla_x\!\cdot s_\theta(x)
\right].
$$

EBM에서 $$s_\theta=\nabla_x f_\theta$$이므로 $$\nabla_x\!\cdot s_\theta=\operatorname{tr}(\nabla_x^2 f_\theta)$$이고, 본문의 tractable score-matching loss가 **정확히** 나옵니다. 이 유도에는 공통 support에서 양의 differentiable density, 적분 가능한 항, $$f_\theta\in C^2$$와 소멸하는 boundary term이 필요합니다. Support boundary에서 density가 0이 아니거나 score가 너무 빨리 발산하면 버린 surface term이 남아 objective가 원래 Fisher divergence와 달라집니다.

표준화된 $$x$$에서는 모든 항을 무차원으로 볼 수 있습니다. 물리 단위가 있는 좌표에서는 $$s_{\theta,i}$$가 $$x_i$$의 역단위이고, 서로 다른 단위의 좌표별 제곱을 그대로 더하려면 먼저 공통 scaling 또는 dimensionless coordinate를 정해야 합니다. Hessian diagonal도 각 좌표 단위의 제곱에 대한 역단위를 가지므로 같은 주의가 필요합니다.

</details>

<details markdown="block">
<summary markdown="span">Derivation: Stable noise-contrastive estimation</summary>

> **Source mapping:** Official Lecture 12 PDF pp. 12--14의 NCE density-ratio/normalizer 논리와 pp. 15--16의 `logsumexp` 및 minibatch estimator에 대응합니다.

Data와 noise를 같은 사전확률로 뽑고 $$c=\log Z$$를 학습하는 경우 logit을

$$
a_{\theta,c}(x)=f_\theta(x)-c-\log p_n(x)
$$

로 두면 $$D_{\theta,c}(x)=\sigma(a_{\theta,c}(x))$$입니다. Population NCE의 **binary cross-entropy 최대화식**은

$$
\mathcal J_{\mathrm{NCE}}(\theta,c)
=\mathbb E_{x\sim p_{\mathrm{data}}}[\log D_{\theta,c}(x)]
+\mathbb E_{y\sim p_n}[\log(1-D_{\theta,c}(y))].
$$

직접 exponential을 계산하지 않고 $$\operatorname{LSE}(u,v)=\log(e^u+e^v)$$를 쓰면 같은 식은

$$
\begin{aligned}
\log D_{\theta,c}(x)
&=f_\theta(x)-\operatorname{LSE}\!\left(f_\theta(x),c+\log p_n(x)\right),\\
\log(1-D_{\theta,c}(y))
&=c+\log p_n(y)-\operatorname{LSE}\!\left(f_\theta(y),c+\log p_n(y)\right).
\end{aligned}
$$

이는 algebraically **정확히 동등**하고, 구현에서는 두 입력의 최댓값을 먼저 빼는 `logsumexp`가 overflow와 catastrophic cancellation을 피합니다. Data minibatch $$x_1,\ldots,x_n$$과 noise minibatch $$y_1,\ldots,y_m$$에 대한 unbiased stochastic objective estimator는

$$
\begin{aligned}
\widehat{\mathcal J}_{\mathrm{NCE}}
={}&\frac1n\sum_{i=1}^{n}
\left[f_\theta(x_i)-\operatorname{LSE}\!\left(f_\theta(x_i),c+\log p_n(x_i)\right)\right]\\
&+\frac1m\sum_{j=1}^{m}
\left[c+\log p_n(y_j)-\operatorname{LSE}\!\left(f_\theta(y_j),c+\log p_n(y_j)\right)\right].
\end{aligned}
$$

여기서 unbiased는 고정된 $$\theta,c$$에서 minibatch 평균이 population objective를 unbiased하게 추정한다는 뜻이지, 유한 표본 optimizer나 learned normalizer가 unbiased하다는 뜻은 아닙니다.

**Normalizer를 회복하는 논리.** Binary cross-entropy의 unrestricted population optimum은 $$D^*(x)=p_{\mathrm{data}}(x)/(p_{\mathrm{data}}(x)+p_n(x))$$입니다. Model family가 이 optimum을 표현하고 $$p_n(x)>0$$가 data support에서 성립하면 $$D_{\theta,c}=D^*$$에서

$$
\frac{e^{f_\theta(x)}}{e^c}=p_{\mathrm{data}}(x).
$$

양변을 공통 reference measure에 대해 적분하면 $$e^c=\int e^{f_\theta(x)}dx=Z(\theta)$$입니다. 이는 infinite-data, global optimum, correct specification, finite partition function 아래의 **정확한 population argument**입니다. 제한된 network, optimization error, support를 덮지 못하는 noise, 너무 쉬운 classification에서는 $$c$$가 true $$\log Z$$에 가까울 이유가 없습니다. Density는 좌표 부피의 역단위를 가질 수 있지만 density ratio와 classifier probability는 무차원이며, log-density는 반드시 같은 reference measure와 단위 convention 아래에서 비교해야 합니다.

</details>

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Score function | $$\nabla_x\log p_\theta(x)$$. EBM에서는 partition function이 사라져 $$\nabla_x f_\theta(x)$$로 계산됩니다. |
| Metropolis-Hastings MCMC | proposal을 만들고 probability ratio에 따라 accept/reject하여 target distribution을 sampling하는 절차입니다. |
| Langevin MCMC | score gradient와 Gaussian noise를 결합해 continuous state space에서 더 informed sampling을 수행합니다. |
| Fisher divergence | 두 분포의 score field 차이를 평균 제곱으로 측정하는 divergence입니다. |
| Score matching | Fisher divergence를 최소화해 EBM을 학습하는 방법이며 model sampling이 필요 없습니다. |
| Noise Contrastive Estimation | data와 tractable noise를 구분하는 classifier를 통해 EBM과 partition function estimate를 함께 학습합니다. |
| Flow contrastive estimation | noise distribution을 normalizing flow로 학습해 NCE의 noise 선택 문제를 완화합니다. |

## 학습 포인트

<details markdown="block">
<summary markdown="span">추가 학습 포인트 보기</summary>

- $$\nabla_\theta\log p_\theta(x)$$와 $$\nabla_x\log p_\theta(x)$$를 구분해야 합니다. 전자는 learning gradient이고 $$Z(\theta)$$가 문제지만, 후자는 score이고 $$Z(\theta)$$가 $$x$$에 대해 상수라 사라집니다.
- Contrastive divergence는 이론적으로 maximum likelihood gradient를 근사하지만, 매번 EBM sample이 필요해 비용이 큽니다.
- Score matching은 data score를 직접 알 필요가 없어 보이지 않지만, integration by parts를 통해 data score를 제거합니다.
- Hessian trace는 score matching의 실제 병목입니다. 이 때문에 denoising score matching과 sliced score matching이 diffusion model에서 핵심적인 practical form으로 등장합니다.
- NCE는 GAN처럼 cross-entropy classifier를 쓰지만, minimax가 아니라 EBM parameter와 $$Z$$를 직접 학습합니다.
- 좋은 NCE noise distribution은 data와 너무 멀지 않아야 합니다. 쉬운 classifier는 좋은 density model을 강제하지 못합니다.

</details>

## 마지막 핵심 정리

Lecture 12의 핵심은 EBM 학습에서 partition function과 model sampling을 피하는 세 가지 길입니다. Score matching은 score field를 맞춰 $$Z(\theta)$$를 제거하고, NCE는 tractable noise와 classifier로 $$Z$$까지 추정하며, adversarial EBM training은 negative distribution을 학습해 likelihood objective를 근사합니다. 이 중 score matching은 다음 강의의 score-based model과 diffusion model을 이해하는 직접적인 기반입니다.

## Study Guide

<details markdown="block">
<summary markdown="span">학습 방법 보기</summary>

1. MCMC sampling과 contrastive divergence의 관계를 먼저 정리합니다. contrastive divergence가 왜 sampling-free가 아닌지 확인합니다.
2. $$Z(\theta)$$가 $$\theta$$에는 의존하지만 $$x$$에는 의존하지 않는다는 점을 이용해 score function 식을 직접 유도합니다.
3. Fisher divergence 식에서 data score가 문제로 보이는 이유와 integration by parts가 이를 제거하는 위치를 구분합니다.
4. Score matching, NCE, adversarial EBM training을 필요한 외부 객체 기준으로 비교합니다: Hessian, noise distribution, variational sampler.
5. Diffusion model을 공부할 때는 denoising score matching이 "score matching의 scalable approximation"이라는 연결고리를 기억합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. EBM에서 score function이 partition function을 포함하지 않는 이유는 무엇입니까?</summary>

답변: $$\log p_\theta(x)=f_\theta(x)-\log Z(\theta)$$이고 $$Z(\theta)$$는 model parameter에는 의존하지만 입력 $$x$$에는 의존하지 않습니다. 따라서 $$x$$에 대해 미분하면 $$\nabla_x\log Z(\theta)=0$$이 되어 $$\nabla_x\log p_\theta(x)=\nabla_x f_\theta(x)$$만 남습니다.

</details>

<details markdown="block">
<summary>2. Langevin MCMC에서 noise를 추가하는 이유는 무엇입니까?</summary>

답변: gradient만 따르면 local maximum을 찾는 optimization이 되기 쉽습니다. Sampling은 distribution 전체를 탐색해야 하므로 Gaussian noise를 넣어 주변을 탐색하고, 확률 질량이 있는 여러 영역을 방문할 수 있게 합니다.

</details>

<details markdown="block">
<summary>3. Score matching이 data score를 모르는 문제를 어떻게 해결합니까?</summary>

답변: Fisher divergence를 전개하면 data score가 들어간 cross term이 생깁니다. Integration by parts와 boundary decay 가정을 사용하면 이 항을 model log-density의 second derivative expectation으로 바꿀 수 있고, 최종 loss는 data sample과 model derivative만으로 계산됩니다.

</details>

<details markdown="block">
<summary>4. Score matching의 practical bottleneck은 무엇입니까?</summary>

답변: 다변량 score matching loss에는 $$\mathrm{tr}(\nabla_x^2 f_\theta(x))$$, 즉 Hessian trace가 들어갑니다. 큰 neural network와 high-dimensional input에서는 이 값을 정확히 계산하기 위해 많은 autodiff 연산이 필요하므로 비용이 큽니다.

</details>

<details markdown="block">
<summary>5. NCE는 GAN과 어떤 점이 같고 어떤 점이 다릅니까?</summary>

답변: 둘 다 real sample과 다른 sample을 구분하는 binary classifier와 cross-entropy loss를 사용합니다. 하지만 GAN은 generator와 discriminator의 minimax training이고 fake sample은 generator에서 오며, NCE는 fixed 또는 tractable noise distribution을 사용하고 discriminator 자체를 EBM density 형태로 제한해 $$f_\theta$$와 $$Z$$를 학습합니다.

</details>

<details markdown="block">
<summary>6. NCE에서 noise distribution이 data와 너무 멀면 왜 문제가 됩니까?</summary>

답변: classification task가 너무 쉬워져 classifier가 data distribution의 섬세한 구조를 배울 필요가 줄어듭니다. NCE는 discriminator가 data와 noise의 density ratio를 학습하도록 압력을 주는 방법이므로, noise는 sampling과 likelihood 계산이 가능하면서도 data에 충분히 가까워야 합니다.

</details>

## PDF

- [Official Lecture 12 slide PDF](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}

## 참고자료

- [CS236 Official Syllabus](https://deepgenerativemodels.github.io/syllabus.html){:target="_blank" rel="noopener"}
- [CS236 Lecture 12 Slides](https://deepgenerativemodels.github.io/assets/slides/cs236_lecture12.pdf){:target="_blank" rel="noopener"}
- [CS236 Lecture 12 Video](https://www.youtube.com/watch?v=Nci1Bepcy0g){:target="_blank" rel="noopener"}
- [How to Train Your Energy-Based Models](https://arxiv.org/abs/2101.03288){:target="_blank" rel="noopener"}
