---
layout: default
date: 2026-07-16 16:07:00 +0900
title: "Stanford CS231N Lecture 6: CNN Architectures"
course: "CS231N"
topic: "CNN Architectures"
order: 6
major_topic: "Computer Vision"
keywords:
  - "AlexNet"
  - "VGG"
  - "ResNet"
  - "Inception"
  - "CNN Architectures"
---

# Stanford CS231N Lecture 6: CNN Architectures

Source: [Stanford CS231N Spring 2025 Lecture 6](https://www.youtube.com/watch?v=aVJy4O5TOk8){:target="_blank" rel="noopener"}

> **핵심:** CNN architecture의 발전은 단순한 층 증가가 아니다. AlexNet은 GPU 기반 대규모 CNN의 가능성을 보였고, VGG는 작은 \(3\times3\) filter를 반복하는 규칙을, GoogLeNet/Inception은 여러 scale을 병렬 처리하는 효율적 module을, ResNet은 깊은 모델을 실제로 최적화하는 residual path를 제시했다. 여기에 initialization, normalization, regularization, transfer learning이 결합되어야 구조가 안정적으로 학습된다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | CNN backward | pooling과 convolution의 gradient는 어디로 흐르는가? |
| 2 | Activation and initialization | 깊어져도 activation·gradient scale을 어떻게 유지하는가? |
| 3 | AlexNet and VGG | 대규모 CNN에서 깊이와 작은 filter는 어떤 이점을 주는가? |
| 4 | GoogLeNet/Inception | 여러 receptive-field scale을 어떻게 효율적으로 병렬 결합하는가? |
| 5 | Residual networks | 깊은 층이 identity를 쉽게 학습하도록 어떻게 돕는가? |
| 6 | Normalization and regularization | activation scale과 일반화를 어떻게 안정화하는가? |
| 7 | Transfer learning | 데이터가 적을 때 pretrained model을 어떻게 활용하는가? |

## 1. CNN layer의 역전파

Max pooling은 순전파 창에서 최댓값의 위치를 저장하고, 역전파 때 그 위치로만 upstream gradient를 보낸다. 같은 입력이 겹치는 여러 창의 최댓값이었다면 gradient를 합한다. Average pooling은 gradient를 창의 원소 수로 나누어 모든 입력에 전달한다.

Convolution에서는 kernel이 모든 위치에 공유되므로, 한 kernel weight의 gradient는 그 weight가 사용된 모든 공간 위치의 기여를 더한 값이다. 입력 gradient는 각 출력 위치가 참조한 kernel-weighted gradient의 합이다.

## 2. Activation functions revisited

Sigmoid와 tanh는 입력 절댓값이 커지면 포화되어 derivative가 0에 가까워진다. 깊은 네트워크에서 이 작은 값들을 반복 곱하면 gradient가 사라진다. ReLU는 양수 구간에서 derivative가 1이어서 이를 완화하지만, 음수에 계속 머무는 unit은 학습하지 않는 dead ReLU가 될 수 있다.

Leaky ReLU는 음수 구간에 작은 기울기를 두고, GELU 같은 부드러운 함수도 현대 모델에 사용된다. 선택의 기준은 forward 표현뿐 아니라 backward의 gradient 전달 성질이다.

## 3. Weight initialization

모든 weight를 0으로 초기화하면 같은 층의 unit이 같은 gradient를 받아 계속 동일하게 움직이는 symmetry 문제가 생긴다. 작은 random weight로 symmetry를 깨되, 너무 작거나 크면 깊이에 따라 activation과 gradient가 소실·폭주한다.

ReLU 계열에서 널리 쓰는 He initialization은 fan-in이 \(n\)일 때 대략

$$
W_{ij}\sim\mathcal{N}\left(0,\frac{2}{n}\right)
$$

로 두어 층을 지날 때 분산을 유지한다. Xavier initialization은 선형/tanh 계열에서 fan-in과 fan-out을 고려한다. 핵심은 특정 상수 암기가 아니라 **신호의 scale이 깊이에 따라 무너지지 않게 하는 것**이다.

## 4. AlexNet: 대규모 CNN의 전환점

강의는 ImageNet architecture의 역사적 출발점으로 AlexNet을 짚는다. AlexNet은 GPU를 사용해 이전보다 큰 CNN을 대규모 이미지 분류에 학습했고, ImageNet에서 CNN 기반 접근이 강력하게 작동할 수 있음을 보여주었다. 이 결과는 이후 architecture가 더 깊고 규칙적인 convolution stack을 탐색하게 만든 기준점이다.

구조적으로는 앞부분의 convolution과 pooling이 공간 feature를 추출하고, 뒤의 fully connected layer가 1,000개 ImageNet class score를 만든다. ReLU, dropout, data augmentation 같은 당시의 실용적 선택도 큰 모델의 학습과 일반화를 뒷받침했다. 다만 큰 초기 kernel과 무거운 fully connected layer 때문에 이후 구조보다 규칙성과 파라미터 효율이 낮다.

## 5. VGG: 작은 filter를 깊게 쌓는 규칙

VGG는 architecture를 거의 전부 `3x3 convolution, stride 1, padding 1` 블록과 주기적인 max pooling으로 구성한다. Convolution 동안 spatial 크기를 유지하고 pooling 뒤에는 해상도를 낮추며 channel 수를 늘린다. 마지막에는 강의에서 설명한 4,096차원 fully connected layer들과 1,000-class 출력이 이어진다.

VGG를 이해하는 핵심은 큰 kernel 하나와 작은 kernel stack의 비교다. Stride 1인 \(3\times3\) convolution 세 층은 \(3\to5\to7\)로 receptive field가 커져 \(7\times7\) 영역을 본다. 입출력 channel이 모두 \(C\)라고 단순화하면 파라미터 수는 다음처럼 비교할 수 있다.

$$
3\cdot(3^2C^2)=27C^2
\qquad\text{vs.}\qquad
7^2C^2=49C^2
$$

작은 filter stack은 더 적은 파라미터로 같은 receptive field를 만들면서, 중간 ReLU를 세 번 통과해 더 복잡한 비선형 관계를 표현한다. AlexNet보다 층이 많지만 블록 규칙이 단순해 feature extractor로 널리 재사용되었다. 반면 고해상도 activation과 큰 fully connected layer 때문에 메모리·연산 비용이 크다.

## 6. GoogLeNet/Inception: multi-scale branch

VGG가 한 종류의 작은 filter를 순차적으로 쌓았다면, Inception module은 같은 입력에 \(1\times1\), \(3\times3\), 더 큰 receptive-field branch와 pooling branch를 병렬 적용하고 channel 축으로 결과를 합친다. 한 scale을 미리 고정하지 않고 국소 패턴과 더 넓은 문맥을 한 stage에서 함께 추출하려는 설계다.

큰 kernel을 입력 channel 전체에 바로 적용하면 비용이 급증한다. 그래서 \(1\times1\) convolution을 projection/bottleneck으로 두어 channel 수를 먼저 줄인 뒤 비싼 branch를 계산한다. \(1\times1\) convolution은 spatial 위치를 바꾸지 않으면서 channel을 혼합하므로, 표현을 재조합하고 연산량을 제어하는 역할을 동시에 한다.

GoogLeNet/Inception이 남긴 핵심은 **layer를 단순히 더 깊게 만드는 것 외에도 module 내부의 폭, branch, bottleneck을 함께 설계할 수 있다**는 점이다. VGG의 규칙적 순차 stack과 비교하면 구조는 복잡하지만 multi-scale feature와 계산 효율을 함께 겨냥한다.

## 7. Residual connections

깊은 plain network는 표현력이 더 커도 optimization이 어려워 성능이 나빠질 수 있다. Residual block은 원하는 mapping \(H(x)\) 대신 잔차 \(F(x)=H(x)-x\)를 학습한다.

$$
y=F(x;W)+x
$$

잔차 branch가 불필요하면 \(F(x)\approx0\)으로 만들어 identity에 가까워질 수 있다. 역전파에서도 addition을 통해 gradient가 identity path로 직접 전달된다. Spatial/channel shape이 다르면 projection shortcut으로 차원을 맞춘다.

이 아이디어는 단순히 정보를 건너뛰는 것이 아니라 깊은 모델을 **기존 표현에 대한 점진적 수정**으로 재매개변수화한다.

## 8. Normalization

Normalization layer는 먼저 선택한 축에서 평균과 분산을 구해 정규화한 뒤 learnable scale \(\gamma\)와 shift \(\beta\)를 적용한다.

$$
\hat{x}=\frac{x-\mu_B}{\sqrt{\sigma_B^2+\epsilon}},
\qquad y=\gamma\hat{x}+\beta
$$

어떤 원소를 하나의 통계 집합으로 묶는지가 방법마다 다르다.

| 방법 | 평균·분산을 구하는 범위 | 실무적 특징 |
|---|---|---|
| BatchNorm | batch와 공간축, channel별 분리 | 훈련·추론 통계가 다르고 작은 batch에 민감 |
| LayerNorm | 샘플별 feature/channel·공간축 | 샘플을 독립 처리하며 Transformer에서 널리 사용 |
| InstanceNorm | 샘플·channel별 공간축 | instance별 contrast를 다루는 이미지 변환에 사용 |
| GroupNorm | 샘플별 channel group과 공간축 | batch 크기에 덜 의존하면서 channel 구조를 보존 |

BatchNorm은 훈련 시 batch 통계를 사용하고, 추론 시에는 누적 running statistics를 사용한다. 작은 batch에서는 통계가 noisy할 수 있다. LayerNorm은 한 샘플 안에서 통계를 구하므로 batch 구성에 의존하지 않는다.

Normalization은 activation scale과 optimization을 안정화하지만 잘못된 train/eval mode 전환이나 통계 관리가 성능 차이를 만든다.

## 9. Regularization in CNNs

Dropout은 훈련 중 각 activation을 확률적으로 0으로 만든다. Inverted dropout은 살아남은 값을 keep probability로 나누어 기대값을 맞추므로 추론 때 별도 scaling이 필요 없다. CNN에서는 spatial structure를 고려한 channel dropout이나 stochastic depth도 가능하다.

이미지에서는 random crop, horizontal flip, color transform 같은 data augmentation이 강력하다. 단, 숫자 방향이나 의료 영상처럼 변환이 레이블을 바꾸는 문제에서는 task-specific 검토가 필요하다.

## 10. Transfer learning

Pretrained backbone은 대규모 데이터에서 얻은 일반적인 시각 feature를 제공한다.

| 데이터 상황 | 권장 시작점 |
|---|---|
| 매우 적은 데이터 | backbone을 freeze하고 새 linear head만 학습 |
| 중간 규모·유사한 도메인 | head를 먼저 학습한 뒤 작은 학습률로 일부 또는 전체 fine-tuning |
| 큰 데이터 또는 다른 도메인 | 전체 fine-tuning 또는 scratch 학습을 validation으로 비교 |

Fine-tuning에서는 새 head를 더 큰 학습률로, pretrained backbone을 더 작은 학습률로 갱신할 수 있다. 입력 resolution과 normalization도 사전학습 설정에 맞춰야 한다.

## 11. Training diagnosis

작은 데이터 subset을 거의 완벽히 overfit할 수 있는지 먼저 확인하면 구현 오류를 찾기 쉽다. 이후 learning rate를 logarithmic scale로 탐색하고, train/validation curve로 underfitting과 overfitting을 구분한다. 여러 hyperparameter를 동시에 크게 바꾸기보다 coarse-to-fine search로 범위를 좁힌다.

## 마지막 핵심 정리

- AlexNet은 GPU로 대규모 CNN을 ImageNet에 성공적으로 학습한 역사적 전환점이다.
- VGG의 연속된 \(3\times3\) convolution은 큰 receptive field를 더 적은 파라미터와 더 많은 비선형성으로 만든다.
- GoogLeNet/Inception은 multi-scale branch를 병렬 결합하고 \(1\times1\) bottleneck으로 계산량을 제어한다.
- Residual connection은 \(y=F(x)+x\)로 표현과 gradient의 identity path를 만든다.
- 올바른 초기화는 activation과 gradient 분산을 깊이에 걸쳐 유지한다.
- Batch normalization은 train/eval 통계가 다르며, 작은 batch에서는 주의가 필요하다.
- Regularization과 augmentation은 task의 불변성을 반영해야 한다.
- 데이터가 적을수록 pretrained feature와 단계적 fine-tuning이 강력한 기준선이다.

## Study Guide

1. AlexNet, VGG, Inception, ResNet을 `더 크게`, `더 규칙적으로`, `더 넓고 효율적으로`, `더 쉽게 최적화하도록`이라는 설계 목표로 비교한다.
2. VGG의 세 \(3\times3\) layer와 한 \(7\times7\) layer의 receptive field, 파라미터 수, activation 횟수를 계산한다.
3. Inception의 병렬 branch와 \(1\times1\) bottleneck이 각각 표현과 계산량에 미치는 영향을 설명한다.
4. plain block과 residual block에서 gradient path를 비교한다.
5. BatchNorm의 train mode와 eval mode 차이를 점검한다.
6. 학습 시작 전 small-subset overfit, learning-rate sweep, curve diagnosis 순서를 익힌다.

## 복습 질문

<details><summary>1. 모든 weight를 0으로 초기화하면 왜 학습이 실패하는가?</summary>

답변: 같은 층의 모든 unit이 같은 출력과 gradient를 받아 서로 다른 feature를 학습하지 못하는 symmetry가 유지되기 때문이다.
</details>

<details><summary>2. VGG가 큰 kernel 하나보다 여러 개의 3x3 convolution을 사용한 이유는?</summary>

답변: 같은 크기의 effective receptive field를 더 적은 파라미터로 만들고, 층 사이의 activation을 추가해 더 복잡한 비선형 함수를 표현할 수 있기 때문이다.
</details>

<details><summary>3. Inception module에서 1x1 convolution은 어떤 역할을 하는가?</summary>

답변: 각 공간 위치에서 channel 정보를 혼합하고, 큰 kernel branch 앞에서 channel 차원을 줄여 파라미터와 연산량을 제한하는 bottleneck 역할을 한다.
</details>

<details><summary>4. residual connection은 역전파에 어떤 경로를 추가하는가?</summary>

답변: 잔차 branch의 미분과 별개로 addition의 identity 경로를 통해 upstream gradient가 입력으로 직접 전달된다.
</details>

<details><summary>5. BatchNorm 모델을 추론할 때 train mode로 두면 왜 문제가 되는가?</summary>

답변: 현재 추론 batch의 불안정한 통계를 사용하고 running statistics도 바뀔 수 있어, 입력 구성에 따라 출력이 달라지기 때문이다.
</details>

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 6](https://www.youtube.com/watch?v=aVJy4O5TOk8){:target="_blank" rel="noopener"}
