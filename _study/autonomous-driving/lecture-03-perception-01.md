---
layout: default
date: 2026-09-21 00:00:00 +0900
title: "Lecture 3: Perception I — Image Classification and Vision Backbones"
course: "Autonomous Driving"
topic: "Image Classification, CNNs, and Vision Transformers"
order: 3
major_topic: "Autonomous Systems"
keywords:
  - "Perception"
  - "Image Classification"
  - "CNN"
  - "ResNet"
  - "Vision Transformer"
  - "Self-Attention"
---

# Lecture 3: Perception I — Image Classification and Vision Backbones

Source PDF: [3 Perception (1).pdf]({{ "/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf" | relative_url }}) (국민대학교 Youngwook Kim, *Automatic Driving Computing*, 57쪽)

이 강의는 센서가 만든 수치를 곧바로 운전 명령으로 바꾸지 않고, 먼저 장면의 의미를 추출하는 **perception**을 다룬다. 전체 도로 장면의 여러 물체를 한 번에 찾기 전에, 물체 하나가 중심인 이미지의 분류 문제로 시작한다. 이후 학습의 수학적 골격, CNN의 공간적 귀납 편향, Vision Transformer(ViT)의 패치 간 관계 학습을 연결한다.

> **핵심:** 이미지 분류는 “이 영상은 무엇인가?”에 답하지만 물체의 위치와 개수는 알려주지 않는다. CNN은 작은 필터의 공유로 국소 특징을 효율적으로 추출하고, ViT는 패치를 token으로 바꿔 self-attention으로 상호 맥락을 반영한다. 두 방식의 출력은 다음 강의의 localization·detection을 위한 시각 표현(backbone)이 된다.

## 전체 흐름

| 범위 | 주제 | 이해할 질문 |
|---|---|---|
| 2–11쪽 | 센서 복습과 perception | 카메라·LiDAR·RADAR 관측을 주행 의미로 바꾸는 단계는 어디인가? |
| 13–22쪽 | 이미지 분류와 신경망 학습 | pixel tensor를 class score로 바꾸고 오차를 어떻게 줄이는가? |
| 24–33쪽 | CNN, VGG, ResNet | 국소성·가중치 공유·skip connection이 필요한 이유는 무엇인가? |
| 35–53쪽 | ViT와 self-attention | 패치 사이의 관련성을 어떻게 계산하고 전체 이미지를 분류하는가? |

## 1. Perception이 풀려는 문제

2–4쪽은 이전 강의의 camera·LiDAR·RADAR와 위성 SAR 사례를 복습한다. SAR은 전파로 원격 영상을 얻는 별도 응용 사례이지 이 강의의 차량 perception 입력이나 핵심 알고리즘은 아니다. 8쪽의 autonomy stack은 **maps/sensors → perception → prediction → planning → control**이다. Perception은 측정으로부터 물체를 감지하고 추적할 정보를 만들며, 이후 단계가 그 물체의 미래 움직임과 차량 경로를 판단한다. 9–11쪽은 먼저 camera 이미지를 택하고, 단일 물체 이미지를 분류하는 간단한 문제로 범위를 좁힌다. 이것이 다중 객체 검출 문제를 이미 해결했다는 뜻은 아니다.

이미지는 사람이 보기에 고양이지만 컴퓨터에는 높이·너비·채널의 숫자 배열이다(13쪽). 8-bit RGB 이미지의 raw pixel은 채널마다 0–255 정수일 수 있다. 학습 전에는 float 변환·정규화 등을 적용할 수 있으므로 **네트워크 입력이 언제나 0–255 정수인 것은 아니다**. 슬라이드의 800×600×3 예시는 총 1,440,000개 채널 값이며, 같은 의미의 물체라도 조명·시점·배경이 달라지면 값이 크게 바뀐다. 이것이 pixel과 semantic category 사이의 간극이다.

분류기의 출력은 정해진 각 class에 대한 **score 또는 logit**이다(14쪽). 강의의 예에서 cat score 5.1이 dog 3.2보다 커 cat을 선택하지만, 5.1 자체는 5.1의 확률을 뜻하지 않는다. Softmax를 통과시킨 뒤에야 합이 1인 class 확률을 얻는다. 새롭거나 학습하지 않은 물체에 대해서도 기등록 class 중 하나를 고르는 폐쇄형 분류의 한계를 함께 기억해야 한다.

## 2. 신경망 학습: 숫자, 비선형성, 오차

### 2.1 선형층과 비선형 활성화

15–19쪽의 “magic box”를 수학적 함수로 풀면, 벡터 $$x$$에 대한 층의 예는 다음과 같다. $$x$$는 입력 특징(무차원 또는 전처리된 pixel 값), $$W$$는 학습 가중치, $$b$$는 편향, $$\phi$$는 원소별 활성화 함수다.

$$
h=\phi(Wx+b)
$$

선형 변환만 여러 번 합성하면 다시 하나의 선형 변환이므로 복잡한 경계를 표현하려면 비선형성이 필요하다. 19쪽은 sigmoid, tanh, ReLU를 비교한다. ReLU의 **정의**는 $$\operatorname{ReLU}(z)=\max(0,z)$$다. 양수 영역에서 기울기 1, 음수 영역에서 0이므로 계산이 간단하지만 음수 입력에서 gradient가 사라질 수 있다. Sigmoid와 tanh는 큰 절댓값의 입력에서 포화되어 gradient가 작아진다. 이 수식은 학습 성능 보장식이 아니라 층이 계산하는 함수의 정의다.

### 2.2 Softmax와 cross-entropy

20쪽의 class score를 확률로 바꾸는 softmax와 정답 class $$y$$의 cross-entropy를 함께 정리하면 다음과 같다. $$z_k$$는 $$k$$번째 class logit(무차원), $$C$$는 class 수, $$p_k$$는 확률(무차원)이다.

$$
p_k=\frac{e^{z_k}}{\sum_{j=1}^{C}e^{z_j}},\qquad
L_{\mathrm{CE}}=-\log p_y
$$

첫 식은 확률 벡터의 **정의**, 두 번째는 one-hot 정답에 대한 cross-entropy **손실 정의**다. 목적은 정답 확률을 높이는 방향으로 가중치를 바꾸는 것이다. 예를 들어 두 class의 logit이 2와 0이면 첫 class 확률은 $$e^2/(e^2+1)\approx0.881$$이고, 첫 class가 정답일 때 손실은 약 0.127이다. 같은 score에 대해 둘째 class가 정답이라면 손실은 약 2.127로 커진다. 실제 계산에서는 overflow를 피하기 위해 모든 logit에서 최댓값을 빼도 확률이 같다는 성질을 이용한다. 모든 class가 정답과 상호 배타적이라는 단순화가 맞지 않는 multi-label 문제에는 그대로 적용하면 안 된다.

### 2.3 Backpropagation, gradient descent, mini-batch

21쪽의 chain rule 그림은 오차가 어떤 가중치에 얼마나 민감한지 역방향으로 구하는 원리다. 중간 출력 $$o$$가 가중치 $$w$$에 의존한다면 **정확한 미분 항등식**은 다음과 같다.

$$
\frac{\partial L}{\partial w}
=\frac{\partial L}{\partial o}\frac{\partial o}{\partial w}
$$

이 그래디언트를 이용한 가장 기본적인 gradient-descent **업데이트 정의**는 $$w_{t+1}=w_t-\eta\,\partial L/\partial w_t$$다. $$\eta>0$$는 학습률(무차원), $$t$$는 step index(무차원)이다. 예를 들어 $$\partial L/\partial w=+0.1$$이고 $$\eta=0.01$$이면 한 step에서 $$w$$는 0.001 감소한다. 0.1은 “가중치를 0.1만큼 늘린다”가 아니라, 다른 변수 고정 시 해당 가중치를 조금 늘렸을 때 손실이 증가하는 국소적 민감도다. 학습률이 너무 크면 최소점을 지나치고, 너무 작으면 느리다. PyTorch 자동미분은 gradient를 계산해 주지만 loss 구성, optimizer, 데이터와 단위의 타당성까지 자동으로 보증하지는 않는다.

22쪽의 mini-batch는 데이터셋 전체를 한 번에 GPU에 올리지 않고 표본 일부로 gradient를 근사하는 운영 방식이다. **Batch size**는 한 step에 쓰는 표본 수, **epoch**는 전체 학습 표본을 한 번 사용한 주기다. $$N$$개 표본에 batch size $$B$$라면 한 epoch의 step 수는 대략 $$\lceil N/B\rceil$$이다(마지막 batch를 버리지 않는 경우). SGD와 Adam은 gradient를 가중치 변경으로 바꾸는 서로 다른 optimizer이며, batch size·epoch와 동의어가 아니다.

## 3. CNN: 공간 구조를 살리는 시각 표현

### 3.1 왜 모든 pixel을 처음부터 완전 연결하지 않는가?

24–25쪽의 32×32×3 영상을 flatten하면 길이 3,072의 벡터다. 이를 출력 10개와 바로 연결하면 편향을 제외하고 $$3072\times10=30{,}720$$개 가중치가 필요하다. 이미지의 가로·세로 길이를 각각 두 배로 늘리고 출력 폭을 유지하면 입력 가중치 수는 네 배가 된다. 슬라이드의 “quadratic increase”는 **가로·세로 길이 모두가 같은 비율로 증가할 때**의 설명이다. Flatten 자체가 픽셀 값을 없애는 것은 아니지만, 보통의 완전 연결층은 인접 pixel이 가깝다는 구조를 모델에 명시하지 않는다.

Convolution은 작은 receptive field를 이동시키며 같은 필터를 여러 위치에 재사용한다(26쪽). 공간 kernel이 $$K\times K$$이고 입력 채널 $$C_{\mathrm{in}}$$, 출력 채널 $$C_{\mathrm{out}}$$라면 가중치 수는 $$K^2 C_{\mathrm{in}} C_{\mathrm{out}}$$개(편향 제외)다. 이는 출력 이미지의 높이·너비에 직접 비례하지 않는다. 예를 들어 3×3, 입력 3채널, 출력 16채널이면 가중치 432개다. 대신 출력 위치마다 convolution 계산은 반복되므로, 파라미터 감소와 계산량 감소는 같은 주장이 아니다.

27쪽의 교육용 구조는 **(CONV → ReLU → POOL) 반복 → flatten → fully connected → softmax**다. Conv는 국소 특징을 찾고, ReLU는 비선형 경계를 허용하며, pooling은 공간 크기를 줄인다. 모델마다 pooling과 classifier head 구성은 달라 이 순서는 모든 CNN의 필수 구조가 아니다.

### 3.2 CNN이 얻는 것과 얻지 못하는 것

28–31쪽의 장점은 (1) 공간 배열을 feature map으로 보존, (2) 필터 공유로 파라미터 절약, (3) 초기 층의 edge·색 blob에서 뒤 층의 부분·객체 패턴으로 계층화, (4) 물체 이동에 대한 유사한 반응이다. 여기서 마지막 항목은 조심해야 한다. **Convolution feature map은 이상적인 경계 조건에서 translation *equivariance***, 즉 입력이 이동하면 feature map도 함께 이동하는 성질을 갖는다. Pooling·집계·분류 head가 일부 위치 변화에 대한 **invariance**를 도울 수 있지만, padding·stride·crop·경계·학습 데이터에 따라 완전한 불변성은 보장되지 않는다. 도로 표지판이 픽셀 몇 칸 이동해도 인식이 안정적일 수 있다는 직관과, 어느 위치든 반드시 같은 예측이 나온다는 단정은 다르다.

### 3.3 VGG와 ResNet

32쪽의 VGG는 작은 3×3 kernel을 쌓고 깊이를 늘려 성능을 개선한 사례다. 연속된 두 3×3 convolution의 receptive field는 stride 1일 때 5×5에 대응한다(비선형층이 사이에 들어가므로 하나의 5×5 선형 필터와 기능상 동일하지는 않다). Padding 1과 stride 1이면 공간 크기를 유지할 수 있다. 강의 그림의 11.7%→7.3%는 **ILSVRC 분류 오류의 서로 다른 2013/2014 제출 결과**로 읽어야 하며, 같은 네트워크를 단지 8층에서 19층으로 바꾼 통제 실험의 인과 효과로 해석하면 안 된다. VGG 원 논문은 16–19 weight layer를 실험하고 2014 분류 2위·localization 1위를 보고한다.

33쪽의 ResNet은 더 깊게 쌓을 때 생기는 최적화 난점을 residual block으로 완화한다. 입력 $$x$$와 잔차 함수 $$F(x)$$의 차원이 같다고 가정하면 block의 **정의**는

$$
H(x)=F(x)+x,\qquad F(x)=H(x)-x
$$

다. 원하는 변환이 항등 변환에 가깝다면 $$F(x)\approx0$$을 학습하면 된다. 또한 출력 gradient는 **chain rule로** $$\partial H/\partial x=\partial F/\partial x+I$$라는 직접 경로를 갖는다. 이것이 깊은 네트워크 최적화에 도움이 되는 이유 중 하나지만, gradient 소실을 모든 경우에 없애는 보증은 아니다. 채널 수나 해상도가 달라지는 block에는 projection shortcut 등이 필요하다. [ResNet 원 논문](https://arxiv.org/abs/1512.03385){:target="_blank" rel="noopener"}은 residual learning의 동기와 실험 근거를 제공한다.

## 4. ViT: 이미지를 패치 시퀀스로 보기

35–38쪽에서 ViT는 이미지를 작은 패치로 자른 뒤 각 패치를 한 token처럼 취급한다. $$H\times W\times C$$ 영상에 $$P\times P$$ 크기 패치를 비중첩으로 자르고 $$H,W$$가 $$P$$로 나누어떨어진다고 가정하면 token 수의 **정의**는 $$N=HW/P^2$$다. 예를 들어 224×224 영상을 16×16 패치로 나누면 $$14\times14=196$$개다. 각 패치를 길이 $$P^2C$$로 펼쳐 trainable linear projection을 거쳐 $$D$$차원 embedding으로 만든다. $$H,W,P,N,D,C$$는 모두 pixel 수 또는 채널·차원 개수이므로 무차원 count다.

패치만 순서 없이 놓으면 “위쪽의 하늘”과 “아래쪽의 도로”의 위치 정보를 잃기 쉬워 **positional embedding**을 더한다(36쪽). 학습 가능한 **[class] token**을 앞에 붙여 전체 영상의 표현을 모을 자리를 마련한다(37쪽). Encoder의 self-attention과 MLP, normalization, residual connection을 반복한 뒤 0번 [class] token의 최종 embedding에 classifier를 적용한다(38, 53쪽). 이는 강의가 소개한 ViT의 구조이며, 모든 vision transformer가 반드시 class token을 사용하는 것은 아니다. [ViT 원 논문](https://arxiv.org/abs/2010.11929){:target="_blank" rel="noopener"}의 패치 시퀀스·분류 설계를 보강 근거로 삼았다.

### 4.1 Q, K, V에서 context vector까지

39–43쪽의 도식은 영상 출처를 표시하며 self-attention의 네 단계를 보여준다. 아래는 그 도식을 수식으로 정리한 **작성자 보충 유도**다. $$X\in\mathbb{R}^{n\times d_{\mathrm{model}}}$$를 token별 입력 embedding(무차원 특징), $$n$$을 [class] 포함 token 수, $$d_k$$를 query/key 차원, $$d_v$$를 value 차원(모두 무차원 count)이라 하자. 학습 행렬로 각 역할을 분리한다.

$$
Q=XW_Q,\qquad K=XW_K,\qquad V=XW_V
$$

Token $$i$$가 token $$j$$와 얼마나 관련 있는지는 내적 $$q_i\cdot k_j$$로 측정한다. **스케일의 이유:** 설명을 위한 가정으로 각 성분 $$q_{i,r},k_{j,r}$$가 서로 독립이고 평균 0·분산 1이라고 두면, 곱 $$q_{i,r}k_{j,r}$$의 평균은 0, 분산은 1이다. 따라서 독립인 $$d_k$$개 곱을 더한 내적의 분산은 $$d_k$$이고, $$\sqrt{d_k}$$로 나눈 score의 분산은 1이 된다. 이는 차원이 커질 때 softmax 입력의 전형적인 크기가 커지는 현상을 완화한다는 **가정하의 유도**이지, 학습된 query/key가 실제로 독립·단위분산이라는 보장은 아니다. 각 query 행에서 softmax로 정규화한 뒤 value에 곱해 문맥 벡터를 만든다.

$$
A=\operatorname{softmax}\!\left(\frac{QK^{\top}}{\sqrt{d_k}}\right),\qquad
Z=AV
$$

여기서 $$A\in\mathbb{R}^{n\times n}$$, $$Z\in\mathbb{R}^{n\times d_v}$$이며, softmax는 **각 행에** 적용된다. 따라서 $$a_{ij}\ge0$$이고 $$\sum_j a_{ij}=1$$이다. 각 출력 행은 $$z_i=\sum_j a_{ij}v_j$$라는 가중합이다. 행렬 곱의 차원이 맞는다는 것은 수식 검산의 첫 단계다: $$(n\times d_k)(d_k\times n)(n\times d_v)\to n\times d_v$$. 이 식은 단일 attention head의 **정의**다. 실제 encoder는 여러 head의 결과를 결합하고 출력 projection·residual connection·MLP를 더한다.

슬라이드의 축구 예(45–51쪽)는 공격수 A가 다른 선수 B·C·D·E에게 각각 0.50·0.30·0.15·0.05의 비중을 주는 모습을 보인다. 네 수의 합이 1임을 확인할 수 있다. 값 자체는 **학습된 실제 모델의 측정 결과가 아닌 설명용 도식**이며, 팀 동료의 표현을 평균해 자기 표현에 더하면 상황을 반영한 embedding이 된다는 직관을 준다. 선수 E는 다른 비중을 두므로 attention matrix의 각 행은 일반적으로 다르다. 52쪽의 게임 팀 예도 같은 원리다. 도식은 자신을 제외한 네 명을 강조하지만, 표준 self-attention은 **별도 mask가 없으면 자기 token에도 attend할 수 있다**.

### 4.2 CNN과 ViT를 비교할 때

CNN은 작은 필터의 국소성과 위치 간 가중치 공유가 구조에 내장되어 있다. ViT는 패치 사이 관계를 attention으로 명시적으로 계산한다. 강의는 이를 한쪽이 무조건 우월하다는 실험으로 제시하지 않는다. Attention의 $$n\times n$$ score matrix는 패치 수 증가 시 메모리와 계산 부담이 커진다. 반대로 CNN도 깊어질수록 receptive field를 키워 넓은 맥락을 포착할 수 있다. 비교할 때는 입력 크기, 학습 데이터, 계산 자원, downstream task를 함께 보아야 한다.

## Source Check

| 위치 | 분류 | 확인과 정리 |
|---|---|---|
| 13쪽 | 가정이 생략된 단순화 | 0–255 정수는 8-bit raw RGB의 예시다. 정규화된 모델 입력까지 같은 범위라고 일반화하지 않는다. |
| 31쪽 | 가정이 생략된 단순화 | 그림 제목의 translation invariance와 convolution 자체의 equivariance를 구분했다. 완전한 불변성은 보장되지 않는다. |
| 32쪽 | 비교 해석 주의 | 11.7%와 7.3%를 단순히 깊이 하나만 바꾼 실험으로 해석하지 않는다. [VGG 원 논문](https://arxiv.org/abs/1409.1556){:target="_blank" rel="noopener"}은 16–19층 구성과 당시 과제별 순위를 명시한다. |
| 45–52쪽 | 도식의 적용 범위 | 축구·게임 attention 비중은 개념 예시다. 표준 self-attention의 자기 token 연결은 mask가 없을 때 가능하다. |

## 시험 포인트

1. Logit과 softmax 확률을 구분하고, 정답 확률이 낮을수록 cross-entropy가 커지는 이유를 설명한다.
2. Flatten+FC와 convolution의 가중치 수를 같은 입력 조건에서 계산하고, 파라미터 수와 연산 수를 구분한다.
3. Convolution의 translation equivariance와 분류 출력의 부분적 invariance를 혼동하지 않는다.
4. Residual block의 $$H(x)=F(x)+x$$와 차원 일치 조건을 쓰고, 왜 최적화가 쉬워질 수 있는지 말한다.
5. ViT의 patch → embedding+position → [class] → encoder → 분류 순서를 설명하고 $$QK^{\top}$$, row softmax, $$AV$$의 차원을 검산한다.

## 마지막 핵심 정리

분류는 이미지 하나에 대한 class score에서 시작한다. 학습은 softmax·cross-entropy가 만든 오차를 backpropagation과 optimizer로 줄이는 과정이다. CNN은 **국소성·공유 필터·계층적 표현**, ViT는 **패치 token·위치 정보·문맥 가중합**으로 의미 표현을 얻는다. 어느 backbone을 쓰든 분류 결과만으로 도로 위 모든 물체의 **위치와 개수**를 알 수 없으므로 다음 강의의 localization·detection이 필요하다. 관련 개념을 한 번에 연결하려면 [Perception Overview]({{ "/study/autonomous-driving/perception-overview/" | relative_url }})를 함께 읽는다.

## Study Guide

- 먼저 9–14쪽을 보고 입력 tensor와 class score의 차이를 설명한다. 그 뒤 20–22쪽의 loss, gradient, batch를 한 단계씩 연결한다.
- 24–31쪽에서는 32×32×3 숫자 예를 직접 계산하고, “filter를 공유한다”는 말을 가중치 수 식으로 검산한다.
- 35–53쪽은 패치 3개 정도를 가정해 $$Q,K,V,A,Z$$의 shape를 적은 후 축구 예의 행별 가중합을 확인한다.
- Source Check의 네 항목은 원문 도식의 교육적 단순화와 정확한 수학적 성질을 구분하는 체크리스트로 삼는다.

## 복습 질문

<details markdown="block">
<summary>1. 분류기 score가 5.1이면 해당 class의 확률이 5.1인가?</summary>

답변: 아니다. Score 또는 logit은 정규화 전 실수다. 모든 class score에 softmax를 적용해야 0–1 사이이면서 합이 1인 확률이 된다. 가장 큰 logit은 가장 큰 softmax 확률을 갖지만 값 자체는 확률이 아니다.

</details>

<details markdown="block">
<summary>2. 32×32×3 영상에서 출력 10개의 완전 연결층과 3×3, 출력 16채널 convolution의 가중치 수는?</summary>

답변: 편향을 빼면 FC는 $$32\cdot32\cdot3\cdot10=30{,}720$$개, convolution은 $$3\cdot3\cdot3\cdot16=432$$개다. Convolution의 같은 432개 가중치를 여러 위치에 재사용한다. 계산량까지 432/30,720 비율로 줄었다는 뜻은 아니다.

</details>

<details markdown="block">
<summary>3. 왜 ResNet block은 입력을 출력에 더하며, 언제 단순 덧셈을 할 수 없는가?</summary>

답변: $$H(x)=F(x)+x$$로 두면 항등 변환이 필요한 곳에서 잔차 $$F(x)\approx0$$을 학습할 수 있고 gradient의 직접 경로도 생긴다. $$F(x)$$와 $$x$$의 크기·채널이 다르면 그대로 더할 수 없으므로 projection 등으로 차원을 맞춘다.

</details>

<details markdown="block">
<summary>4. ViT에서 positional embedding과 [class] token은 각각 왜 필요한가?</summary>

답변: Positional embedding은 패치의 공간적 위치를 표현에 더한다. [class] token은 encoder를 거쳐 전체 패치의 정보를 모을 수 있는 학습 가능한 위치이며, 강의의 ViT에서는 그 최종 표현을 분류 head에 전달한다.

</details>

<details markdown="block">
<summary>5. Attention matrix의 한 행은 무엇을 뜻하며 합이 1이어야 하는 이유는?</summary>

답변: 한 query token이 각 key token의 value를 얼마나 반영할지 나타내는 가중치다. 각 행에 softmax를 적용하므로 값은 음수가 아니고 합이 1이다. 예를 들어 슬라이드의 0.50+0.30+0.15+0.05=1이며, 이는 해당 선수 관점의 맥락 가중합이다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/autonomous-driving/lecture-03-perception-01.pdf" | relative_url }}" target="_blank" rel="noopener">3 Perception (1).pdf</a></li>
</ul>

## References

- Simonyan and Zisserman, [Very Deep Convolutional Networks for Large-Scale Image Recognition](https://arxiv.org/abs/1409.1556){:target="_blank" rel="noopener"} — VGG 깊이와 ILSVRC 결과의 1차 근거.
- He et al., [Deep Residual Learning for Image Recognition](https://arxiv.org/abs/1512.03385){:target="_blank" rel="noopener"} — residual block의 동기와 검증.
- Dosovitskiy et al., [An Image is Worth 16×16 Words](https://arxiv.org/abs/2010.11929){:target="_blank" rel="noopener"} — ViT의 patch sequence와 class token.
