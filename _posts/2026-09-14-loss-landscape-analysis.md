---
layout: post
title: "Loss Landscape Analysis: Bayesian Ensembles, Mode Connectivity, and Model Merging"
nav_title: "Loss Landscape Analysis"
date: 2026-09-14 16:22:00 +0900
last_modified_at: 2026-09-14 22:41:00 +0900
categories: [Machine Learning, Neural Networks]
tags: [Loss Landscape, Bayesian Neural Networks, Mode Connectivity, Model Merging, Permutation Symmetry]
permalink: /posts/loss-landscape-analysis/
section: ai-education
---

Source PDF: `Loss surface analysis.pdf` — locally supplied; not redistributed.

> **핵심 메시지:** 신경망의 서로 다른 해 사이에 낮은 손실 경로가 존재할 수 있고, 숨은 뉴런의 순서를 맞추면 직선 보간도 좋아질 수 있다. 그러나 **경로의 존재, 예측의 다양성, 가중치 평균의 품질, Bayesian posterior의 정확성은 서로 다른 문제**다. 이 차이를 이해해야 loss landscape 그림을 앙상블·모델 병합·압축 연구의 근거로 올바르게 사용할 수 있다.

이 글은 표지에 *Loss Landscape Analysis*와 Kookmin University Seminar가 적힌 25쪽 자료를 바탕으로 한 독자적 한국어 해설이다. 특정 정규 교과목·발표자·발표일은 PDF에서 확인되지 않아 추정하지 않았다. 원문 전체를 번역하거나 그림을 재배포하지 않고, 주요 논지를 공개 원 논문과 대조했다. 아래의 유도와 수치 예제는 별도 표시가 없는 한 **복습을 위한 작성자 보충 설명**이며, 세미나에서 실행한 실험 결과가 아니다.

## Reading Map

| Slides | Topic | This article |
|---|---|---|
| 1–3 | 불확실성과 Bayesian model averaging | Sections 1–2: 목표 확률분포와 평균의 유도 |
| 4–6 | MCMC와 deep ensemble 비교 | Section 3: mixing, 계산 예산, DEE 그림 |
| 7–10 | 곡선 연결, FGE, simplex, 지형 시각화 | Sections 4–5: 연결성이 보장하는 것과 아닌 것 |
| 11–12 | 함수 공간의 bridge와 가중치 생성 시도 | Section 6: 학습·추론 비용의 분리 |
| 13–17 | 학습 이력, 순열 정렬, Git Re-Basin | Sections 7–8: 순열 불변성 증명과 반례 |
| 18–22 | convex hull, 여러 모델, posterior 정렬 | Sections 9–10: 집합의 기하와 분포의 기하 |
| 23–24 | 양자화, pruning, SAM, SWA, NTK | Section 11: 연구로 확장할 때의 조건 |
| 25 | Q&A | 핵심 정리와 검산 질문 |

## 1. What Is a Loss Landscape?

신경망은 입력을 출력으로 보내는 함수이지만, 학습에서는 모든 가중치와 편향을 모은 벡터를 움직인다. 이 벡터를 $$\theta\in\mathbb{R}^{d}$$라고 하자. 데이터셋 $$D=\{(x_i,y_i)\}_{i=1}^{n}$$에 대한 경험적 손실은 다음과 같이 **정의**할 수 있다.

$$
\mathcal{L}_{D}(\theta)=\frac{1}{n}\sum_{i=1}^{n}\ell(f_{\theta}(x_i),y_i).
$$

입력 공간의 좌표는 $$x$$이고, loss landscape의 좌표는 $$\theta$$다. 그림의 두 가로축을 데이터의 두 특성으로 오해하면 안 된다. 실제 매개변수는 매우 고차원이므로 보통 선택한 방향 $$u,v$$에 대해 다음 2차원 단면을 그린다.

$$
g(a,b)=\mathcal{L}_{D}(\theta_{\mathrm{ref}}+au+bv).
$$

이는 전체 지형이 아니라 **특정 기준점과 방향을 선택한 단면**이다. 방향의 길이나 정규화가 바뀌면 같은 모델도 더 가파르거나 평평하게 보일 수 있다. 낮은 학습 손실이 낮은 검증 손실·좋은 calibration·높은 posterior 질량을 동시에 뜻하지도 않는다.

| Symbol | Meaning | Unit / domain |
|---|---|---|
| $$x,y,D$$ | 입력, 표적, 관측 데이터셋 | 문제에 따라 다름; 이 글은 정규화된 입력과 분류·장난감 회귀 예시 사용 |
| $$\theta,d$$ | 전체 매개변수 벡터, 그 차원 | 모델 좌표; 보편적인 SI 단위 없음, $$d$$는 개수 |
| $$n,N$$ | 관측 개수, 앙상블 또는 표본 개수 | 개수; 무차원 |
| $$p(y\mid x,\theta)$$ | 모델의 조건부 예측분포 | 분류 확률은 무차원; 연속값의 확률밀도는 표적 단위의 역수 |
| $$\mathcal L,\ell$$ | 데이터 손실, 표본 손실 | 분류 negative log-likelihood는 무차원; 제곱오차는 표적 단위의 제곱 |
| $$t,\lambda_i$$ | 보간 비율, 혼합계수 | 무차원; 0–1 구간 |
| $$P,\pi$$ | 순열행렬, 네트워크 전체에 일관되게 적용하는 순열 | 무차원 |
| $$H,\delta$$ | 손실 Hessian, 매개변수 변화 | 각각 손실/매개변수 단위의 제곱, 매개변수 단위 |

## 2. Why Bayesian Model Averaging?

### 2.1 One prediction is not the whole uncertainty

슬라이드 2의 여러 곡선은 관측점에 비슷하게 맞는 모델도 관측이 드문 곳에서 다른 출력을 낼 수 있음을 보여준다. 하나의 최적 가중치를 정답처럼 사용하는 대신, 관측과 양립하는 여러 모델의 불확실성을 예측에 반영하려는 것이 Bayesian 접근의 동기다.

**Aleatoric uncertainty**는 주어진 관측 조건에서 남는 잡음이고, **epistemic uncertainty**는 모델·매개변수에 대한 불확실성이다. 전자를 irreducible이라고 부를 때는 입력 정보와 측정 조건이 고정되어 있다는 단서가 필요하다. 더 좋은 센서나 추가 설명변수가 생기면 이전의 불확실성 일부가 줄어들 수 있다. 후자도 데이터만 늘리면 반드시 사라지는 것은 아니며 모델 오지정과 분포 이동을 따로 고려해야 한다.

### 2.2 Deriving the predictive integral

슬라이드 3의 핵심 수식은 **전체확률법칙**에서 나온다. 새 표적 $$y$$와 매개변수의 결합분포에서 매개변수를 적분해 제거하면

$$
\begin{aligned}
p(y\mid x,D)
&=\int p(y,\theta\mid x,D)\,d\theta\\
&=\int p(y\mid x,\theta,D)p(\theta\mid x,D)\,d\theta\\
&=\int p(y\mid x,\theta)p(\theta\mid D)\,d\theta.
\end{aligned}
$$

마지막 등호는 일반적인 판별 모델 설정에서 **매개변수가 주어지면 새 표적은 학습 데이터와 조건부 독립이고, 새 입력 하나가 매개변수 posterior를 갱신하지 않는다는 가정**을 쓴다. 입력의 생성과정까지 공동 모델링하는 경우에는 이 단순화를 먼저 점검해야 한다.

Bayes 정리로 posterior는

$$
p(\theta\mid D)=\frac{p(D\mid\theta)p(\theta)}{p(D)}.
$$

조건부 독립 표본에서 손실을 평균 negative log-likelihood로 정의했다면 다음 관계가 성립한다.

$$
p(\theta\mid D)\propto\exp\{-n\mathcal{L}_{D}(\theta)\}\,p(\theta).
$$

따라서 **loss만 낮다고 posterior도 동일한 것은 아니다.** prior가 다를 수 있고, 한 점의 밀도와 주변 영역을 적분한 확률질량도 다르다. 여러 개의 좋은 점을 찾는 최적화와 영역별 올바른 질량을 반영하는 추론을 구분해야 한다.

### 2.3 From an integral to an ensemble

posterior를 대표하는 표본 $$\theta_1,\ldots,\theta_N$$을 확보하면, 슬라이드 3의 합은 기대값에 대한 Monte Carlo **근사**가 된다.

$$
p(y\mid x,D)\approx\frac{1}{N}\sum_{j=1}^{N}p(y\mid x,\theta_j).
$$

독립 posterior 표본이면 대수의 법칙을 적용할 수 있다. MCMC의 상관된 표본에는 목표분포 불변성·ergodicity 등 적절한 수렴 조건이 필요하다. 반면 임의 초기화로 학습한 최적점의 단순 평균에는 이 posterior 표본 조건이 자동으로 성립하지 않는다. [Deep Ensembles 원 논문](https://papers.nips.cc/paper_files/paper/2017/hash/9ef2ed4b7fd2c810847ffa5fa85bce38-Abstract.html){:target="_blank" rel="noopener"}의 유용성과 정확한 Bayesian 추론 여부는 별개의 주장이다.

예를 들어 어떤 클래스에 대한 세 모델의 확률이 0.2, 0.6, 0.7이면 예측 평균은 0.5다. 이것은 확률 평균이며, 가중치 평균 모델이 0.5를 출력한다는 뜻은 아니다. 일반적으로

$$
p\!\left(y\mid x,\frac{1}{N}\sum_j\theta_j\right)
\ne\frac{1}{N}\sum_jp(y\mid x,\theta_j).
$$

회귀에서는 불확실성의 두 부분을 더 명확히 볼 수 있다. 조건부 평균과 분산을 각각 $$\mu_\theta(x)$$와 $$\sigma_\theta^2(x)$$라고 하자. 유한한 이차 모멘트가 존재하면

$$
\begin{aligned}
\operatorname{Var}(y\mid x,D)
&=\mathbb{E}_{\theta}[\sigma_\theta^2(x)+\mu_\theta^2(x)]
  -\{\mathbb{E}_{\theta}[\mu_\theta(x)]\}^{2}\\
&=\mathbb{E}_{\theta}[\sigma_\theta^2(x)]
  +\operatorname{Var}_{\theta}[\mu_\theta(x)].
\end{aligned}
$$

이는 $$\mathbb E[y^2\mid\theta]=\sigma_\theta^2+\mu_\theta^2$$를 대입한 **전체분산법칙**이다. 첫 항은 조건부 잡음, 둘째 항은 모델 평균 사이의 차이다. 모든 모델이 같은 출력을 내면 둘째 항은 0이지만 관측 잡음까지 0이 되지는 않는다.

## 3. MCMC, Deep Ensembles, and the Meaning of the Plot

슬라이드 4–6은 적은 계산 예산에서 서로 다른 예측을 확보하는 문제를 강조한다. 하나의 MCMC chain이 한 영역을 오래 방문하면 저장한 표본 수가 많아도 새로운 정보가 적을 수 있다. 정상상태이고 자기상관합이 적절히 수렴하는 스칼라 관측량에 대한 설명용 근사는

$$
N_{\mathrm{eff}}\approx\frac{N}{1+2\sum_{k\ge1}\rho_k}
$$

이다. $$\rho_k$$는 lag $$k$$의 자기상관이다. 이 분산 기반 해석은 [Stan의 effective sample size 설명](https://mc-stan.org/docs/reference-manual/analysis.html){:target="_blank" rel="noopener"}과 연결된다. 예를 들어 AR(1)식 자기상관이 $$\rho_k=0.9^k$$라면 분모는 $$1+2(0.9/0.1)=19$$이고 190개 표본의 유효 개수는 약 10이다. 이는 **모든 MCMC에 고정적으로 적용되는 수치가 아니라 상관의 영향을 보여주는 예시**다.

Deep ensemble은 여러 초기화에서 독립 학습하여 다른 해를 찾는 접근이다. 병렬화가 쉽고 좋은 예측 기준선이 되지만, 여러 초기화가 모두 다른 유용한 함수로 이어진다는 보장은 없다. MCMC 역시 단일 chain만 가능한 것은 아니며, 다중 chain과 HMC 등 방법·계산 예산에 따라 비교가 달라진다. [HMC posterior를 조사한 연구](https://proceedings.mlr.press/v139/izmailov21a.html){:target="_blank" rel="noopener"}는 좋은 일반화 성능과 posterior predictive 일치가 동의어가 아님을 보여준다.

**슬라이드 5의 세로축은 accuracy도 유효 표본 수도 아닌 DEE(Deep Ensemble Equivalent)**다. 그림은 Ashukha 등의 [Pitfalls of In-Domain Uncertainty Estimation and Ensembling in Deep Learning, Figure 3](https://openreview.net/pdf?id=BJxI5gHKDr){:target="_blank" rel="noopener"}와 대응한다. 논문은 calibrated log-likelihood를 기준으로 해당 방법의 성능에 대응하는 deep ensemble 크기를 정의한다. 높은 DEE는 그 평가조건에서 더 큰 독립 앙상블에 해당하는 품질을 뜻한다. 그림에는 CIFAR-10, CIFAR-100, ImageNet과 서로 다른 방법이 포함되어 있다.

따라서 원문에 등장하는 소수의 particles나 방법의 우열을 보편적 법칙으로 읽지 않는다. **같은 추론 횟수, 총 학습 비용, calibration 조건, 데이터 분포와 metric을 고정한 비교**가 있어야 결과를 해석할 수 있다. 이 글에서는 그래프에서 정확한 실험 수치를 추출하거나 새 성능을 주장하지 않는다.

## 4. Curved Connections Are Not Convexity

### 4.1 Testing a straight line

두 해 $$\theta_0,\theta_1$$의 직선 보간을

$$
\gamma_{\mathrm{lin}}(t)=(1-t)\theta_0+t\theta_1,\qquad 0\le t\le1
$$

로 정의한다. 끝점이 모두 좋더라도 중간 손실이 높을 수 있다. 설명용 barrier 지표를 다음처럼 정의하면 끝점 손실이 서로 다른 경우도 비교할 수 있다.

$$
B=\max_{0\le t\le1}
\left[\mathcal L(\gamma_{\mathrm{lin}}(t))-
\{(1-t)\mathcal L(\theta_0)+t\mathcal L(\theta_1)\}\right].
$$

끝점에서 대괄호 값이 0이므로 정확한 최대값은 음수가 아니다. 실험에서는 유한한 grid로 근사하므로 촘촘한 sampling을 해도 모든 중간점에 대한 증명이 되지는 않는다. 논문마다 barrier와 loss/error의 정의가 다를 수 있어 비교 전 확인이 필요하다.

### 4.2 Why a Bézier curve can help

슬라이드 7의 아이디어는 끝점은 고정하고 경로의 모양을 학습하는 것이다. 2차 Bézier 경로를 쓰면

$$
\gamma_c(t)=(1-t)^2\theta_0+2t(1-t)c+t^2\theta_1.
$$

$$c$$는 학습 가능한 제어점이다. $$t=0,1$$을 대입하면 원래 끝점이 보존된다. 중간점은

$$
\gamma_c(1/2)=\tfrac14\theta_0+\tfrac12c+\tfrac14\theta_1
$$

이므로 **두 끝점의 산술평균과 다르다.** 원문에서 가운데 모델이 좋다고 설명해도 무정렬 weight averaging이 좋다는 근거가 되지 않는 이유다.

경로 전체의 평균 손실을 줄이는 목적함수와 그 gradient는, 미분·적분 교환이 가능한 매끄러운 설정에서

$$
\begin{aligned}
J(c)&=\int_0^1\mathcal L(\gamma_c(t))\,dt,\\
\nabla_cJ(c)&=\int_0^1 2t(1-t)\nabla_\theta\mathcal L(\gamma_c(t))\,dt
\end{aligned}
$$

가 된다. 두 번째 식은 chain rule과 $$\partial\gamma_c/\partial c=2t(1-t)I$$에서 나온다. 실제 학습은 $$t$$와 mini-batch를 sampling해 이 gradient를 추정할 수 있다. ReLU의 비미분점에서는 일반 미분 대신 구현의 subgradient 관례를 확인해야 한다.

[Garipov et al.](https://papers.nips.cc/paper/2018/hash/be3087e74e9100d4bc4c6268cdbe8456-Abstract.html){:target="_blank" rel="noopener"}과 [Draxler et al.](https://proceedings.mlr.press/v80/draxler18a.html){:target="_blank" rel="noopener"}의 결과는 실험적으로 낮은 손실의 연결 경로를 찾을 수 있음을 뒷받침한다. 모든 신경망·모든 해를 잇는 보편 정리로 확대하지 않는다. 또한 평균 경로 손실을 최소화하는 목적만으로 경로의 **최악 손실**까지 작다는 보장은 없으므로 둘 다 검사해야 한다.

### 4.3 FGE separates collecting models from using them

슬라이드 8의 FGE(Fast Geometric Ensembling)는 짧은 주기의 학습률 변화로 좋은 영역을 탐색하고 snapshot을 모아 예측을 앙상블하는 방법이다. 명시적으로 Bézier 곡선을 먼저 구한 뒤 그 위를 정확히 따라가는 알고리즘과 같지 않다. 낮은 손실 연결성이라는 관찰이 효율적인 탐색의 동기를 제공한다.

한 학습 궤적에서 여러 모델을 얻으면 독립 학습 비용을 줄일 수 있지만, 여러 snapshot의 출력을 평균하려면 일반적으로 여러 번의 forward pass가 필요하다. **학습 비용 절감과 추론 비용 절감은 별도로 측정**해야 한다. 이것이 뒤의 bridge network와 SWA로 이어지는 문제다.

## 5. From Paths to Volumes and Pictures

슬라이드 9의 [Benton et al.](https://proceedings.mlr.press/v139/benton21a.html){:target="_blank" rel="noopener"}은 한 줄 경로에서 low-loss simplex와 그 복합체로 관심을 넓힌다. 꼭짓점 $$v_0,\ldots,v_k$$가 생성하는 simplex의 점은

$$
\theta(\lambda)=\sum_{i=0}^{k}\lambda_i v_i,
\qquad \lambda_i\ge0,\quad\sum_i\lambda_i=1
$$

로 표현된다. 꼭짓점이 affine 독립일 때 $$k=1$$은 선분, $$k=2$$는 삼각형이다. 계수의 합이 1이므로 좌표 원점을 바꾸어도 같은 기하학적 점을 나타내는 affine combination이 된다. 꼭짓점 손실이 낮아도 내부 손실이 낮지는 않으므로 내부를 sampling해 최적화·검증해야 한다.

여기서 volume은 **구성한 부분공간의 차원에 따른 부피**다. 전체 매개변수 차원보다 낮은 차원의 simplex는 전체 공간의 Lebesgue 부피가 0일 수 있다. “넓은 공간”이라는 그림만으로 full-dimensional posterior mass를 확보했다고 말할 수 없다. simplex에서 균일 sampling한 분포도 일반적으로 posterior와 다르다.

슬라이드 10은 [Skorokhodov와 Burtsev의 Loss Landscape Sightseeing](https://arxiv.org/abs/1910.03867){:target="_blank" rel="noopener"}에 연결되는 패턴 그림이다. 그림의 모양은 고차원 공간에서 어떤 단면·좌표를 골랐는지에 크게 의존한다. 이 경험적 결과를 “임의의 학습된 모델에서 어떤 그림이든 항상 쉽게 찾는다”는 정리로 쓰지 않는다. 별도의 [Czarnecki et al. 이론 연구](https://arxiv.org/abs/1912.07559){:target="_blank" rel="noopener"}도 충분한 표현력 등의 가정 아래 읽어야 한다.

실제로 지형 그림을 기록할 때는 기준 checkpoint, 두 방향의 생성·정규화 방식, training/validation split, loss 정의, BatchNorm 통계 처리와 축 범위를 함께 남기는 것이 재현에 필요하다.

## 6. Function-Space Bridges and Weight Generation

슬라이드 11의 문제는 **좋은 중간 모델을 발견했더라도 매번 전체 네트워크를 실행해야 하는가**다. [Yun et al., Traversing Between Modes in Function Space for Fast Ensembling](https://proceedings.mlr.press/v202/yun23a.html){:target="_blank" rel="noopener"}은 기존 네트워크의 feature를 받아 low-loss subspace의 출력을 예측하는 작은 bridge network를 제안한다. 한쪽 모델의 feature를 쓰는 형태와 양쪽 feature를 함께 쓰는 형태를 구분할 수 있다.

슬라이드의 기호를 따라 $$z_1,z_2$$를 두 모델의 중간 feature, $$v_{1,2}(t)$$를 경로상의 목표 출력이라고 읽으면, 핵심은 bridge 출력 $$\widetilde v_{1,2}(t)$$가 목표 출력을 **근사**하도록 학습하는 것이다. 원문 그림처럼 $$t=0.5$$ 등의 특정 위치를 고정한 bridge를 생각한다. 구현별 logit·확률 선택은 원 논문을 따라야 하며, 다음 식은 고정된 $$t$$에서 방식의 목적만 나타낸 설명용 제곱오차다. 여러 $$t$$를 하나의 bridge로 처리하려면 위치를 입력에 추가하는 등 별도의 설계가 필요하다.

$$
\min_\phi\;\mathbb E_x\left[
\left\lVert h_\phi(z_1(x))-v_{1,2}(t;x)\right\rVert_2^2
\right].
$$

목표 중간 모델을 학습 때 teacher로 실행하는 비용, bridge 학습 비용, 추론 때 실제 실행하는 backbone·bridge 비용을 나누어 계산해야 한다. 함수 출력을 모사한다고 중간 모델의 가중치 자체를 복원하는 것은 아니다.

슬라이드 12는 시작 가중치에서 다른 가중치를 diffusion 등으로 생성하려던 시도를 언급한다. 이는 **발표자의 개별 시도에 대한 설명**이지 일반적 불가능성의 증거가 아니다. 본문에서는 특정 실패 원인을 추정하지 않는다. 연구로 확장한다면 가중치의 순열 대칭, 학습용 모델 표본의 양, 생성한 가중치의 실제 기능과 calibration을 각각 평가해야 한다. 조건부 생성의 성공 또한 목표 posterior를 정확히 sampling했다는 결론과 별개다.

## 7. Shared Training History and Linear Connectivity

슬라이드 13–14는 비선형 경로를 찾고 따라가는 비용 때문에 다시 직선 연결을 묻는다. [Frankle et al.](https://proceedings.mlr.press/v119/frankle20a.html){:target="_blank" rel="noopener"}의 질문은 독립 초기화만 비교하는 경우보다 구체적이다. 같은 초기값 또는 초기 학습 구간을 공유한 뒤 서로 다른 SGD noise로 학습한 결과 사이의 안정성을 조사한다.

공유 checkpoint를 $$\theta_k$$라 하고 이후 다른 minibatch 순서 등의 noise로 얻은 결과를 $$\theta^{(1)},\theta^{(2)}$$라 하자. 두 끝점의 interpolation error가 언제 낮아지는지 측정하면 **학습 초반의 공통 이력이 표현 정렬에 어떤 영향을 주는지** 볼 수 있다. 원문의 그림은 공유한 학습 구간에 따른 instability 변화이지, 모든 초기화가 동일한 해로 수렴한다는 증명이 아니다.

복습에서 구분할 실험 조건은 세 가지다. 독립 초기화, 초기값만 공유, 일정 학습 후의 checkpoint를 공유하는 경우다. 이 조건들을 섞으면 모델 병합의 성공 원인을 잘못 해석할 수 있다.

## 8. Permutation Symmetry: A Proof and a Counterexample

### 8.1 Why relabeling hidden units preserves the function

슬라이드 15의 식을 한 hidden layer 네트워크에서 직접 확인하자. 모든 hidden unit에 같은 elementwise activation $$\sigma$$가 적용된다고 가정한다.

$$
f_\theta(x)=W_2\sigma(W_1x+b_1)+b_2.
$$

숨은 뉴런 순서를 바꾸는 순열행렬 $$P$$는 $$P^{\top}P=I$$를 만족한다. 입력 가중치의 행, bias, 출력 가중치의 열을 **함께** 바꾸면

$$
W'_1=PW_1,\qquad b'_1=Pb_1,\qquad W'_2=W_2P^{\top}.
$$

elementwise activation은 재정렬과 교환하므로 $$\sigma(Pz)=P\sigma(z)$$이다. 따라서

$$
\begin{aligned}
f_{\pi(\theta)}(x)
&=W_2P^{\top}\sigma(PW_1x+Pb_1)+b_2\\
&=W_2P^{\top}P\sigma(W_1x+b_1)+b_2\\
&=f_\theta(x).
\end{aligned}
$$

이것은 해당 구조에서 모든 입력에 성립하는 **정확한 항등식**이다. 한 layer의 행만 바꾸고 다음 layer의 열을 바꾸지 않으면 성립하지 않는다. 깊은 MLP에서도 인접 layer를 일관되게 변환해야 하며, residual 연결과 normalization state가 있는 모델은 연결 구조·상태까지 맞추어야 한다.

### 8.2 Same function does not make naïve averaging safe

두 hidden unit의 ReLU 모델을 생각하자. 편향은 0이고

$$
W_1=\begin{pmatrix}1\\-1\end{pmatrix},\qquad
W_2=\begin{pmatrix}1&1\end{pmatrix}.
$$

출력은 $$\operatorname{ReLU}(x)+\operatorname{ReLU}(-x)=\lvert x\rvert$$이다. 두 unit을 서로 바꾼 모델도 같은 함수를 낸다. 그러나 두 모델의 가중치를 좌표별로 평균하면 첫 layer의 두 가중치가 모두 0이 되어 출력이 0으로 붕괴한다.

$$x=-1,1$$과 표적 $$y=1$$ 두 점에서 평균 제곱오차를 계산하면 원래 두 모델의 손실은 각각 0, 평균 모델의 손실은 1이다. 순열을 먼저 되돌리면 가중치가 일치하므로 평균 후에도 손실 0을 유지한다. **동일한 함수도 매개변수 좌표가 맞지 않으면 weight average가 실패할 수 있다**는 구체적 반례다.

### 8.3 Finding the alignment is the hard part

슬라이드 16의 목적은 순열을 골라 두 모델 중간점의 성능 저하를 줄이는 것이다. 원문의 error 기호를 $$\varepsilon$$로 적으면

$$
\min_\pi\;\varepsilon\!\left(\frac{\theta_0+\pi(\theta_1)}{2}\right).
$$

이는 **최적화 문제의 정의**이지 모든 모델에서 최적값이 0이라는 정리가 아니다. 또한 중간점 하나의 품질만으로 전체 선분을 보증하지 않으므로 Section 4의 전체 구간 검사가 필요하다. [Entezari et al.](https://openreview.net/forum?id=dNigytemkL){:target="_blank" rel="noopener"}의 순열 연결성은 적용 조건과 conjecture의 지위를 함께 읽는다.

슬라이드 17의 [Git Re-Basin](https://openreview.net/forum?id=CQsmMYmlP5T){:target="_blank" rel="noopener"}은 activation matching과 weight matching 등으로 정렬을 구한다. 전자는 같은 입력에 대한 hidden activation의 대응을, 후자는 연결된 가중치의 대응을 사용한다. 단일 hidden layer의 activation 행렬을 $$A,B\in\mathbb R^{m\times n}$$라 하면 설명용 정렬 기준은

$$
\min_P\lVert A-PB\rVert_F^2.
$$

Frobenius norm을 전개하고 순열이 norm을 보존함을 이용하면

$$
\lVert A-PB\rVert_F^2
=\lVert A\rVert_F^2+\lVert B\rVert_F^2
-2\operatorname{tr}(A^{\top}PB)
$$

이므로 activation의 대응 점수를 최대화하는 assignment 문제로 바뀐다. 여러 layer의 weight matching은 인접 layer 순열이 서로 얽히므로 이 한 식만으로 전체 알고리즘이 끝나지는 않는다. 매칭 목적함수의 개선과 실제 병합 모델의 validation 성능도 따로 검증해야 한다. 원 논문 자체에 반례와 제약이 있으므로 단일 basin 가설의 보편 증명으로 인용하지 않는다.

## 9. Why Pairwise Success Does Not Guarantee a Convex Hull

슬라이드 18–21의 핵심은 “두 모델을 잘 연결했다”에서 “여러 모델을 마음대로 섞어도 된다”로 넘어갈 수 있는가다. 꼭짓점의 convex hull은 항상 수학적으로 정의되지만, **그 내부가 모두 낮은 손실인가**는 별도 문제다.

| Property | What must be low loss? | What is not guaranteed? |
|---|---|---|
| Curved connectivity | 선택한 두 해를 잇는 적어도 한 경로 | 직선과 평균 모델의 품질 |
| Pairwise linear connectivity | 각 쌍을 잇는 선분 | 세 점 이상이 만드는 내부의 품질 |
| Star-shaped low-loss set | 한 공통 중심에서 각 점으로 잇는 선분 | 서로 다른 두 끝점 사이의 모든 선분 |
| Low-loss convex set | 집합의 임의 두 점 사이의 모든 선분 | posterior 질량, calibration, test 성능 |

세 꼭짓점의 barycentric coordinate를 $$\lambda_1,\lambda_2,\lambda_3$$라 하자. 설명용 함수

$$
L(\lambda)=27\lambda_1\lambda_2\lambda_3
$$

는 삼각형의 모든 변에서 0이지만, 중심에서는 1이다. 변에서는 적어도 한 계수가 0이고 중심에서는 세 계수가 모두 $$1/3$$이기 때문이다. 따라서 **모든 쌍의 선분을 검사해도 내부의 높은 손실을 놓칠 수 있다.** 이것은 논문 실험이 아닌 논리적 반례다.

또 다른 문제는 정렬의 일관성이다. A–B, B–C를 각각 잘 맞춘 순열들이 A–C와도 동시에 양립한다고 보장할 수 없다. [Ito et al., ICML 2025](https://proceedings.mlr.press/v267/ito25a.html){:target="_blank" rel="noopener"}는 바로 여러 모델의 순열과 linear mode connectivity를 다룬다. 슬라이드 21의 STE-MM 의사코드는 단순한 시간축 weight averaging만을 뜻하지 않는다.

그 의사코드의 흐름은 마지막 모델을 기준으로 보조 매개변수를 초기화하고, weight matching으로 순열을 구한 다음, 무작위 양수 계수를 합이 1이 되게 정규화하여 **여러 모델 혼합점의 손실**을 계산하는 것이다. 이 손실의 gradient로 보조 매개변수를 갱신하고 마지막에 순열을 다시 구한다. 이산적인 순열 선택의 gradient 문제를 다루는 straight-through 방식이 포함되므로 정확한 이산 최적화의 해를 보장하는 절차로 읽지 않는다. 또한 각 Uniform 값을 독립적으로 뽑아 정규화한다면, 합이 1이라고 해서 simplex의 균일분포인 Dirichlet(1)과 같지는 않다. 원문 의사코드에 독립성 조건까지 명시된 것은 아니므로 구현을 확인할 때의 구분점으로 남긴다.

[Sonthalia et al.](https://arxiv.org/abs/2403.07968){:target="_blank" rel="noopener"}은 convexity보다 약한 star-domain 가설을 제안한다. 원문 슬라이드의 2024는 preprint 연도이며 학회 발표는 ICLR 2025다. 이 결과를 모든 모델 병합이 불가능하다는 정리로 바꾸지 않는다. 좋은 공통 중심을 찾는 접근과 여러 모델을 공동 정렬하는 접근은 여전히 유효한 연구 방향이다.

## 10. Aligning Posterior Distributions, Not Only Points

슬라이드 22는 점 추정치 하나 대신 approximate posterior 자체를 정렬한다. Gaussian 근사 $$q(\theta)=\mathcal N(\mu,\Sigma)$$에서 전체 매개변수 벡터를 재배열하는 순열행렬을 $$Q$$라 하자. $$\theta'=Q\theta$$의 평균과 공분산은 선형변환의 성질에 의해

$$
\begin{aligned}
\mathbb E[\theta']&=Q\mu,\\
\operatorname{Cov}(\theta')
&=\mathbb E[Q(\theta-\mu)(\theta-\mu)^{\top}Q^{\top}]\\
&=Q\Sigma Q^{\top}.
\end{aligned}
$$

즉 **평균만 옮기고 공분산을 그대로 두면 일반적으로 같은 분포의 재표현이 아니다.** Slide 22의 pushforward 표기는 분포 전체를 순열로 이동시키는 의미다. Section 8처럼 함수가 보존되어 likelihood도 같고, 가중치 prior까지 순열 대칭이라면 posterior의 해당 대칭도 유지된다. 서로 다른 역할의 뉴런에 다른 prior를 둔 모델에서는 이 가정을 별도로 확인해야 한다.

[Rossi et al.](https://proceedings.neurips.cc/paper_files/paper/2023/hash/d9dc5573f7368201d6409e07e882aa77-Abstract-Conference.html){:target="_blank" rel="noopener"}은 두 독립적인 근사 Bayesian 해를 permutation으로 정렬하는 variational 관점을 연구한다. 점 기반 병합과 구분되는 중요한 확장이지만, 정렬 후 근사가 정확한 posterior가 되거나 모든 test 분포에서 더 좋은 uncertainty를 준다는 뜻은 아니다.

슬라이드 18의 기대처럼 좋은 해들을 모았더라도, local approximation은 누락된 mode의 질량이나 비Gaussian 모양을 놓칠 수 있다. **좋은 기하학적 좌표를 찾는 것과 올바른 확률 가중치를 정하는 것을 함께 해결**해야 BMA 정확성에 대한 주장이 가능하다.

## 11. Connections to Compression and Learning Theory

### 11.1 Quantization and pruning: direction matters

슬라이드 23은 낮은 손실 영역을 넓혀 양자화된 가중치도 그 안에 들어오게 하는 아이디어를 제시한다. 매개변수 변화 $$\delta$$에 대해 이차 미분 가능한 손실을 Taylor 전개하면

$$
\mathcal L(\theta+\delta)
=\mathcal L(\theta)+\nabla\mathcal L(\theta)^{\top}\delta
+\tfrac12\delta^{\top}H\delta+o(\lVert\delta\rVert^2).
$$

stationary point에서는 일차항이 0이므로 작은 변화의 손실 변화는 Hessian에 대한 방향별 이차형식으로 **근사**된다. Saddle에서는 음의 방향도 가능하므로 항상 증가라고 부를 수 없다. 정규화된 두 매개변수에서 $$H=\operatorname{diag}(1,100)$$이고 변화의 길이가 0.1이면, 첫 축으로 이동한 이차 손실 증가는 0.005, 둘째 축으로는 0.5다. 같은 크기의 양자화 오차도 방향에 따라 영향이 다르다.

따라서 volume 최대화만으로 quantization 품질이 보장되지 않는다. 실제 rounding grid, clipping, layer별 scale과 오차 방향을 검사해야 한다. Pruning은 일부 좌표를 0으로 만드는 구조적 변화이므로 작은 무작위 perturbation과 다를 수 있고 재학습·mask 조건도 중요하다. 큰 변화나 ReLU 활성 경계를 가로지르는 경우 위의 국소 근사만 믿으면 안 된다.

### 11.2 SAM and SWA answer different questions

슬라이드 24의 [SAM](https://arxiv.org/abs/2010.01412){:target="_blank" rel="noopener"}은 주어진 norm에서 반경 $$\rho$$ 안의 큰 손실까지 고려하는 min–max 목적을 사용한다. 정규화항을 생략한 핵심 형태는

$$
\min_\theta\max_{\lVert\delta\rVert_2\le\rho}\mathcal L(\theta+\delta).
$$

일차 근사에서 내부 문제는 gradient $$g$$에 대해 $$\max g^{\top}\delta$$가 된다. Cauchy–Schwarz로 $$g^{\top}\delta\le\rho\lVert g\rVert_2$$이며, $$g\ne0$$일 때 $$\delta^*=\rho g/\lVert g\rVert_2$$가 그 상한을 달성한다. 이는 **선형화된 내부 문제의 정확한 해**이지 원래 비선형 내부 문제의 정확한 해가 아니다. $$g=0$$이면 나눗셈을 사용할 수 없고 고차항이나 수치 안정화가 필요하다.

[SWA](https://arxiv.org/abs/1803.05407){:target="_blank" rel="noopener"}는 특정 학습률 schedule로 얻은 여러 checkpoint의 가중치를 평균하여 단일 모델을 만든다. 목적상 여러 출력을 평균하는 FGE와 구분된다. 평균 주변에서 모델 출력이 매끄럽고 거의 선형이며 checkpoint 변화가 작다면, 평균에서의 Taylor 전개의 일차 변화가 상쇄되어 가중치 평균 출력과 출력 평균이 가까워질 수 있다. 그러나 큰 곡률·서로 다른 basin·순열 불일치에서는 이 직관이 실패한다. BatchNorm이 있으면 평균 가중치에 맞는 통계 재추정도 필요하다.

원문의 asymmetric valley는 평균의 위치가 일반화에 영향을 줄 수 있다는 관점이다. 특정 2차원 그림에서 덜 가파른 쪽으로 이동했다고 모든 데이터 분포의 일반화가 좋아지는 것은 아니므로 validation으로 확인한다.

### 11.3 Lazy learning and feature learning

[NTK](https://papers.neurips.cc/paper_files/paper/2018/hash/5a4be1fa34e62bb8a6ec6b91d2462f5a-Abstract.html){:target="_blank" rel="noopener"}와 [maximal-update parametrization](https://proceedings.mlr.press/v139/yang21c.html){:target="_blank" rel="noopener"}은 너비를 키울 때 학습 동작이 어떻게 달라지는지 이해하는 틀이다. 초기값 주변의 함수 선형화는

$$
f_\theta(x)\approx f_{\theta_0}(x)+J_{\theta_0}(x)(\theta-\theta_0)
$$

이며 $$J$$는 매개변수에 대한 Jacobian이다. 학습 내내 이 선형화가 유효하고 kernel이 거의 고정되는 regime과, representation이 유의미하게 변화하는 feature-learning regime을 구분해야 한다. 단순히 파라미터 수가 많다는 사실만으로 어느 regime인지 결정되지 않는다. 이 세미나에서는 후속 키워드 수준으로 제시되어 있으므로, 여기서는 무한너비 수렴 정리를 증명하지 않고 해당 원 논문으로 범위를 연결한다.

## Source Check

| Slides | Check | Interpretation used here |
|---|---|---|
| 2–3 | 불확실성 분류와 BMA 합의 가정 생략 | 정보 조건을 고정하고 posterior 표본 조건을 명시 |
| 4–6 | 방법의 우열을 단정하는 문구 | DEE 원 출처를 확인하고 특정 metric·예산의 비교로 제한 |
| 7–9 | 낮은 곡선·부피의 의미 | 곡선 중간점과 산술평균, 부분공간 부피와 posterior mass를 분리 |
| 10 | 임의 패턴을 항상 찾는다는 표현 | 경험적 시각화와 가정이 있는 별도 이론을 구분 |
| 11–12 | bridge와 개인 생성 시도 | 공개 bridge 논문과 연결; 발표자 신원·실패 원인·불가능성은 추정하지 않음 |
| 15–17 | permutation으로 같은 함수 유지 | 입출력 연결·bias·state의 동시 정렬 조건과 직접 증명 제공 |
| 18–21 | convex hull과 평균 성능 | 낮은 손실 hull은 별도 조건; Ito의 다중 모델 문제와 STE-MM 흐름 설명 |
| 20 | Sonthalia 2024 | 2024 preprint / ICLR 2025 구분; star-domain은 일반 정리가 아닌 가설 |
| 22–24 | posterior·압축·평탄성 | 분포 전체의 변환과 국소 근사의 가정 명시 |

검토 범위는 PDF 25쪽 전체의 텍스트·화면, 주요 그림의 축과 원 출처, 핵심 수식의 독립 유도다. 슬라이드 3의 예측 적분·합은 Section 2, 11의 출력 근사는 Section 6, 15–16의 순열식은 Section 8, 21의 혼합 알고리즘은 Section 9, 22의 분포 변환은 Section 10에서 대응한다. 각 논문의 모든 실험을 재현하거나 세미나의 구두 설명까지 확인한 것은 아니다.

## Key Takeaways

1. **예측 평균, 가중치 평균, posterior 적분을 구별한다.** 수식이 비슷해도 표본의 출처와 평균하는 대상이 다르다.
2. **곡선 연결은 convexity가 아니다.** 중간점·모든 쌍의 선분·여러 점의 내부를 차례로 별도 검사한다.
3. **순열 대칭은 정확하지만 정렬의 성공은 조건부다.** 같은 함수의 뉴런 순서 차이만으로도 무정렬 평균은 실패한다.
4. **낮은 손실은 확률질량이 아니다.** prior, 부피, 근사분포와 sampling 조건을 함께 봐야 Bayesian 주장을 할 수 있다.
5. **모델 병합·압축은 실제 방향과 비용으로 평가한다.** 예측 품질·calibration·학습 비용·추론 비용을 나누어 기록한다.

## Review Questions

<details markdown="block">
<summary>1. 낮은 손실 경로가 발견되면 MCMC 문제가 해결되는가?</summary>

답변: 아니다. 경로를 따라가는 transition이 목표 posterior를 보존하는지, 각 영역의 질량을 올바르게 반영하는지, mixing이 충분한지까지 확인해야 한다. 경로의 존재는 탐색에 대한 기하학적 단서다.

</details>

<details markdown="block">
<summary>2. 똑같은 함수를 내는 모델을 평균했는데 왜 성능이 떨어질 수 있는가?</summary>

답변: 함수의 동일성과 매개변수 좌표의 동일성은 다르기 때문이다. Section 8의 두-unit ReLU 예제에서는 뉴런 순서를 뒤집어도 함수는 같지만, 정렬 없이 평균하면 가중치가 0으로 상쇄된다. 연결된 가중치와 bias를 먼저 맞춰야 한다.

</details>

<details markdown="block">
<summary>3. 세 모델의 모든 쌍을 선형 연결하면 세 모델 평균도 안전한가?</summary>

답변: 아니다. 모든 변의 손실이 낮아도 삼각형 내부는 높을 수 있다. Section 9의 세 barycentric coordinate 곱은 모든 변에서 0이고 중심에서 1이다. 여러 모델을 합칠 때는 내부 혼합점도 검사한다.

</details>

## Source Materials

- Local source: `Loss surface analysis.pdf`, *Loss Landscape Analysis*, 25 pages — locally supplied; not redistributed. 로컬 보관명은 `loss-surface-analysis.pdf`이며 원본 bytes는 변경하지 않았다. 공개 원본 URL·재배포 허가·발표자·발표일은 확인되지 않았다.
- 이 글은 공개 원 논문을 링크한 독자적 해설이다. PDF·슬라이드 그림·전체 번역은 첨부하지 않는다. 각 절의 논문 링크는 해당 주장 바로 옆에서 확인할 수 있다.

핵심 주장과 수식의 대조에 사용한 공개 원 논문 PDF는 다음과 같다. 공개 웹에는 사본을 재업로드하지 않았다.

- 불확실성·분포 정렬: [Deep Ensembles — 예측 불확실성](https://papers.nips.cc/paper_files/paper/2017/file/9ef2ed4b7fd2c810847ffa5fa85bce38-Paper.pdf){:target="_blank" rel="noopener"} · [Rossi et al. — Bayesian posterior 순열 정렬](https://arxiv.org/pdf/2310.10171){:target="_blank" rel="noopener"}.
- 연결 경로·효율: [Garipov et al. — mode connectivity와 FGE](https://proceedings.neurips.cc/paper_files/paper/2018/file/be3087e74e9100d4bc4c6268cdbe8456-Paper.pdf){:target="_blank" rel="noopener"} · [Draxler et al. — low-loss path](https://proceedings.mlr.press/v80/draxler18a/draxler18a.pdf){:target="_blank" rel="noopener"} · [Benton et al. — simplexes](https://proceedings.mlr.press/v139/benton21a/benton21a.pdf){:target="_blank" rel="noopener"} · [Yun et al. — function-space bridge](https://proceedings.mlr.press/v202/yun23a/yun23a.pdf){:target="_blank" rel="noopener"}.
- 여러 모델 병합: [Git Re-Basin — permutation matching](https://arxiv.org/pdf/2209.04836){:target="_blank" rel="noopener"} · [Ito et al. — multiple-model LMC](https://raw.githubusercontent.com/mlresearch/v267/main/assets/ito25a/ito25a.pdf){:target="_blank" rel="noopener"} · [Sonthalia et al. — star-domain 가설](https://arxiv.org/pdf/2403.07968){:target="_blank" rel="noopener"}.
- 최적화·학습 이론: [SAM — 주변 손실](https://arxiv.org/pdf/2010.01412){:target="_blank" rel="noopener"} · [SWA — 가중치 평균](https://arxiv.org/pdf/1803.05407){:target="_blank" rel="noopener"} · [NTK — 무한 너비 극한](https://arxiv.org/pdf/1806.07572){:target="_blank" rel="noopener"}.
- 연결해서 읽기: [AI Education]({{ "/post/ai-education/" | relative_url }}) · [Machine Learning Basics]({{ "/study/machine-learning-basic/" | relative_url }}) · [Stanford CS236]({{ "/study/cs236/" | relative_url }}).
