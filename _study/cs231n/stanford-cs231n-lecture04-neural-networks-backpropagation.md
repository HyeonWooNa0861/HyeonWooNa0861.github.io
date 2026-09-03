---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 4: Neural Networks and Backpropagation"
course: "CS231N"
topic: "Neural Networks and Backpropagation"
order: 4
major_topic: "Computer Vision"
keywords:
  - "Neural Networks"
  - "Backpropagation"
  - "Activation Functions"
  - "Computational Graphs"
  - "Gradients"
---

# Stanford CS231N Lecture 4: Neural Networks and Backpropagation

Source: [Stanford CS231N Spring 2025 Lecture 4](https://www.youtube.com/watch?v=25zD5qJHYsk){:target="_blank" rel="noopener"}
Slides: [Official Stanford CS231N 2025 Lecture 4 PDF](https://cs231n.stanford.edu/slides/2025/lecture_4.pdf){:target="_blank" rel="noopener"}

> **핵심:** 신경망의 표현력은 affine transform 사이에 비선형성을 넣는 데서 나오고, 학습 가능성은 계산 그래프의 chain rule을 역순으로 재사용하는 backpropagation에서 나온다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Linear to neural network | 선형 층을 여러 개 쌓는 것만으로 충분하지 않은 이유는? |
| 2 | Activation functions | 비선형 함수는 결정 경계를 어떻게 확장하는가? |
| 3 | Computational graph | 복잡한 함수를 어떤 작은 연산으로 분해하는가? |
| 4 | Backpropagation | local gradient가 전체 gradient로 어떻게 연결되는가? |
| 5 | Vector gradients | 행렬 연산에서는 shape을 어떻게 보존하는가? |

## 1. 선형 분류기에서 신경망으로

2-layer network의 점수 함수는 다음처럼 쓸 수 있다.

$$
h=\phi(W_1x+b_1),
\qquad
s=W_2h+b_2
$$

첫 층은 입력을 여러 hidden feature로 바꾸고 둘째 층은 그 feature를 클래스 점수로 조합한다. 만약 $$\phi$$가 없다면 두 선형 변환은 $$W_2W_1x$$라는 하나의 선형 변환으로 합쳐진다. 깊이의 효과를 얻으려면 층 사이에 비선형 함수가 반드시 필요하다.

Hidden unit은 입력 공간의 한 영역에서 활성화되는 feature detector로 이해할 수 있다. 여러 unit의 출력 조합은 하나의 hyperplane으로 표현할 수 없는 복잡한 결정 경계를 만든다.

## 2. Activation functions

| 함수 | 정의 | 특징 |
|---|---|---|
| Sigmoid | $$\sigma(x)=1/(1+e^{-x})$$ | 출력이 0–1이지만 포화 영역에서 gradient가 작음 |
| Tanh | $$\tanh(x)$$ | zero-centered이나 역시 포화 가능 |
| ReLU | $$\max(0,x)$$ | 양수 영역 gradient가 일정하고 계산이 단순 |

ReLU는 깊은 모델에서 기본 선택이지만 음수 영역의 gradient가 0이라 unit이 계속 비활성화되는 dead ReLU가 생길 수 있다. 활성 함수를 고를 때는 출력 범위뿐 아니라 역전파 때의 derivative를 함께 봐야 한다.

## 3. Computational graph

복잡한 손실 함수는 덧셈, 곱셈, max, exp 같은 작은 연산 노드로 분해할 수 있다. 순전파는 입력에서 손실 방향으로 중간값을 계산하고 저장한다. 역전파는 손실에서 입력 방향으로 각 노드의 local derivative를 곱한다.

연쇄법칙은 다음 형태다.

$$
\frac{\partial L}{\partial x}
=\frac{\partial L}{\partial z}
\frac{\partial z}{\partial x}
$$

상류에서 받은 $$\partial L/\partial z$$와 노드가 알고 있는 local gradient $$\partial z/\partial x$$를 곱하면 하류 입력에 대한 gradient가 된다. 각 노드는 전체 모델을 알 필요가 없다.

## 4. 자주 쓰는 gate의 역전파

- **Add gate:** 상류 gradient를 각 입력으로 그대로 복제한다.
- **Multiply gate:** 한 입력의 gradient는 상류 gradient와 다른 입력값의 곱이다.
- **Max gate:** 순전파에서 최댓값이었던 입력으로만 gradient를 전달한다.
- **Fan-out:** 한 값이 여러 경로에 쓰이면 각 경로에서 온 gradient를 합한다.

예를 들어 $$z=xy$$, 손실 $$L$$에 대해

$$
\frac{\partial L}{\partial x}=\frac{\partial L}{\partial z}y,
\qquad
\frac{\partial L}{\partial y}=\frac{\partial L}{\partial z}x
$$

이다. 입력값과 local derivative를 cache해 두는 이유가 여기에 있다.

## 5. Sigmoid를 하나의 gate로 보기

Sigmoid의 derivative는 출력값만으로 표현된다.

$$
\frac{d\sigma(x)}{dx}=\sigma(x)(1-\sigma(x))
$$

따라서 여러 원시 연산으로 나누어 미분할 수도 있고 sigmoid 전체를 하나의 gate로 묶을 수도 있다. 구현의 추상화 수준은 달라도 gradient가 같아야 한다. 이 관점은 프레임워크의 layer/module 설계로 이어진다.

## 6. Vector와 matrix의 gradient

스칼라 예제와 달리 실제 신경망의 중간값은 벡터와 행렬이다. 역전파에서 각 gradient는 대응하는 순전파 변수와 같은 shape을 가져야 한다.

Affine layer $$y=Wx+b$$에서 상류 gradient를 $$g_y=\partial L/\partial y$$라 하면

$$
\frac{\partial L}{\partial W}=g_yx^{\top},
\qquad
\frac{\partial L}{\partial x}=W^{\top}g_y,
\qquad
\frac{\partial L}{\partial b}=g_y
$$

Batch가 있으면 각 샘플의 bias gradient를 batch 축으로 합해야 한다. Broadcasting을 사용한 순전파는 역전파에서 broadcast된 축을 다시 sum해야 한다.

## 7. 역전파 구현 원칙

1. 순전파에서 출력과 backward에 필요한 중간값을 cache한다.
2. 손실의 시작 gradient를 1로 둔다.
3. 그래프의 역위상 순서로 backward를 호출한다.
4. 한 변수가 여러 경로로 분기되었다면 gradient를 누적한다.
5. 작은 입력에서 numerical gradient로 shape와 값을 검사한다.

Backpropagation은 별개의 학습 규칙이라기보다 계산 그래프에 chain rule을 효율적으로 적용하는 reverse-mode automatic differentiation이다. 출력 손실이 스칼라이고 파라미터가 많은 딥러닝에 특히 적합하다.

## 핵심 수식 유도

### 작성자 보충: sigmoid derivative

Sigmoid를 $$\sigma(x)=(1+e^{-x})^{-1}$$로 쓰고 바깥의 역수, 덧셈, 지수함수 순서로 chain rule을 적용하면

$$
\begin{aligned}
\frac{d\sigma}{dx}
&=-(1+e^{-x})^{-2}\frac{d}{dx}(1+e^{-x})\\
&=-(1+e^{-x})^{-2}(-e^{-x})\\
&=\frac{e^{-x}}{(1+e^{-x})^2}.
\end{aligned}
$$

한편 $$1-\sigma(x)=e^{-x}/(1+e^{-x})$$이므로

$$
\boxed{\frac{d\sigma(x)}{dx}=\sigma(x)(1-\sigma(x))}
$$

라는 **정확한 항등식**을 얻는다. 지수함수의 입력 $$x$$와 $$\sigma(x)$$는 무차원이며 derivative도 무차원이다. $$x=0$$에서 derivative의 최댓값은 $$1/4$$이고, $$x\to\infty$$ 또는 $$x\to-\infty$$이면 $$\sigma(x)$$가 1 또는 0으로 포화되어 derivative가 0에 가까워진다. 따라서 깊은 sigmoid network에서는 여러 층의 작은 local derivative가 곱해져 gradient가 사라질 수 있다.

### 작성자 보충: vector chain rule

합성함수 $$z=f(x)$$, $$L=g(z)$$의 backpropagation은 chain rule **항등식**

$$
\frac{\partial L}{\partial x}=\frac{\partial z}{\partial x}^{\!\top}\frac{\partial L}{\partial z}=J_f(x)^{\top}\nabla_zL
$$

이다. Local Jacobian의 transpose가 upstream gradient를 입력 공간으로 당긴다.

공식 슬라이드 마지막의 matrix multiplication $$Y=XW$$를 성분으로 확인하자. $$X\in\mathbb R^{N\times D}$$, $$W\in\mathbb R^{D\times M}$$이면 $$Y_{nm}=\sum_{d=1}^{D}X_{nd}W_{dm}$$다. Upstream gradient를 $$G=\nabla_YL$$라 둘 때

$$
\frac{\partial L}{\partial X_{nd}}
=\sum_{m=1}^{M}
\frac{\partial L}{\partial Y_{nm}}
\frac{\partial Y_{nm}}{\partial X_{nd}}
=\sum_{m=1}^{M}G_{nm}W_{dm}
=(GW^\top)_{nd},
$$

$$
\frac{\partial L}{\partial W_{dm}}
=\sum_{n=1}^{N}
\frac{\partial L}{\partial Y_{nm}}
\frac{\partial Y_{nm}}{\partial W_{dm}}
=\sum_{n=1}^{N}X_{nd}G_{nm}
=(X^\top G)_{dm}.
$$

그러므로

$$
\boxed{\nabla_XL=GW^\top},
\qquad
\boxed{\nabla_WL=X^\top G}
$$

라는 **정확한 chain-rule 항등식**과 올바른 shape $$N\times D$$, $$D\times M$$을 동시에 얻는다. Bias가 있으면 broadcast된 각 행의 기여를 합쳐 $$\nabla_bL=\sum_nG_{n:}$$가 된다. 모든 항의 단위는 “loss 단위/해당 변수 단위”다. In-place mutation, 잘못된 broadcasting, non-differentiable branch에서는 계산 graph와 이 유도가 어긋날 수 있다.

## 마지막 핵심 정리

- 비선형 activation이 없으면 여러 선형 층은 하나의 선형 층과 같다.
- Backpropagation은 **upstream gradient × local gradient**를 반복한다.
- 분기된 경로의 gradient는 합산되고, 각 gradient shape은 원래 변수 shape과 맞아야 한다.
- 순전파 cache와 계산 그래프의 모듈화가 정확하고 효율적인 구현의 핵심이다.

## Study Guide

1. affine–ReLU–affine network를 계산 그래프로 직접 그린다.
2. add, multiply, max, sigmoid gate의 forward/backward를 손으로 계산한다.
3. matrix multiplication의 gradient shape을 매번 적어 전치 위치를 확인한다.
4. analytical gradient와 numerical gradient가 다를 때 broadcasting, accumulation, non-differentiable point를 점검한다.

## 복습 질문

<details markdown="block"><summary>1. activation 없이 affine layer를 여러 개 쌓아도 표현력이 늘지 않는 이유는?</summary>

답변: affine transform의 합성은 다시 하나의 affine transform이므로 결정 경계가 여전히 선형이기 때문이다.
</details>

<details markdown="block"><summary>2. 계산 그래프가 backpropagation을 단순하게 만드는 이유는?</summary>

답변: 각 노드가 자신의 작은 연산에 대한 local derivative만 알면 되고, 전체 gradient는 상류 gradient와의 곱으로 조립되기 때문이다.
</details>

<details markdown="block"><summary>3. 한 변수가 두 계산 경로에 동시에 쓰였다면 gradient는 어떻게 처리하는가?</summary>

답변: 두 경로가 손실에 미친 기여를 모두 반영해야 하므로 각 경로에서 돌아온 gradient를 더한다.
</details>

## 원문 대조 기록

공식 PDF **147쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 23–50쪽 | two-layer network와 activation functions | 1–2절 |
| PDF 52–94쪽 · 영상 00:41:28 | computational graph, scalar gate, backpropagation | 3–5절 |
| PDF 95–147쪽 · 영상 01:12:17 | vector Jacobian과 matrix-multiplication backward | 6–7절 및 작성자 보충 |

Gate와 backpropagation 규칙은 강의 원문 요약이다. Sigmoid derivative, vector chain rule, $$Y=XW$$의 성분별 gradient 증명은 **작성자 보충**이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 4](https://www.youtube.com/watch?v=25zD5qJHYsk){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 4 PDF](https://cs231n.stanford.edu/slides/2025/lecture_4.pdf){:target="_blank" rel="noopener"}
