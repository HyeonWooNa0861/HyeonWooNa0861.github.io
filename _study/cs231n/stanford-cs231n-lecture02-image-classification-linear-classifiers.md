---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 2: Image Classification with Linear Classifiers"
course: "CS231N"
topic: "Image Classification and Linear Classifiers"
order: 2
major_topic: "Computer Vision"
keywords:
  - "Image Classification"
  - "k-NN"
  - "Linear Classifier"
  - "SVM Loss"
  - "Softmax Loss"
---

# Stanford CS231N Lecture 2: Image Classification with Linear Classifiers

Source: [Stanford CS231N Spring 2025 Lecture 2](https://www.youtube.com/watch?v=pdqofxJeBN8){:target="_blank" rel="noopener"}

Official slides: [Lecture 2 PDF](https://cs231n.stanford.edu/slides/2025/lecture_2.pdf){:target="_blank" rel="noopener"}

> **핵심:** 이미지 분류는 사람이 규칙을 직접 쓰는 문제가 아니라, 데이터로부터 점수 함수를 학습하는 문제다. k-NN은 데이터와 거리의 의미를, 선형 분류기는 점수·손실·최적화로 이어지는 학습의 기본 틀을 보여준다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Image classification | 픽셀 배열을 의미 있는 범주로 바꾸기 어려운 이유는 무엇인가? |
| 2 | Data-driven approach | 규칙 대신 데이터로 분류기를 만드는 절차는 무엇인가? |
| 3 | k-Nearest Neighbors | 거리와 이웃 수는 예측 경계를 어떻게 바꾸는가? |
| 4 | 데이터 분할 | hyperparameter는 어느 데이터에서 선택해야 하는가? |
| 5 | Linear classifier | 하나의 행렬곱이 어떻게 클래스별 점수를 만드는가? |
| 6 | Loss function | SVM과 softmax는 좋은 점수를 어떻게 정의하는가? |

## 1. 이미지 분류와 semantic gap

입력은 보통 $$H \times W \times 3$$ 크기의 RGB tensor이고, 출력은 미리 정한 클래스 가운데 하나다. 사람은 고양이의 의미를 즉시 인식하지만 컴퓨터가 보는 것은 0–255 사이의 수치다. 이 **semantic gap** 때문에 픽셀 수준의 작은 변화와 의미 수준의 변화가 일치하지 않는다.

- **Viewpoint variation:** 카메라 위치만 바뀌어도 거의 모든 픽셀이 달라진다.
- **Illumination:** 같은 물체도 빛과 그림자에 따라 색과 명암이 변한다.
- **Deformation and occlusion:** 자세가 바뀌거나 일부가 가려져도 범주는 유지된다.
- **Background clutter:** 물체와 배경의 경계가 약할 수 있다.
- **Intraclass variation:** 같은 클래스 내부의 모양 차이가 클 수 있다.

따라서 모든 경우를 `if` 문으로 열거하는 방식은 확장되지 않는다. 필요한 것은 입력과 정답 쌍으로부터 공통 패턴을 찾는 데이터 중심 접근이다.

## 2. 데이터 중심 접근

전형적인 파이프라인은 세 단계다.

1. `train(images, labels)`에서 모델의 파라미터 또는 훈련 데이터를 준비한다.
2. `predict(test_images)`에서 보지 못한 입력의 레이블을 추정한다.
3. validation/test set에서 일반화 성능을 측정한다.

핵심 전환은 **알고리즘의 규칙을 사람이 고정하는 대신, 학습 절차와 모델 형태를 정하고 실제 규칙은 데이터에서 얻는 것**이다.

## 3. k-Nearest Neighbors

k-NN은 별도 파라미터를 학습하지 않고 훈련 이미지를 저장한다. 새 입력 $$x$$와 각 훈련 샘플 $$x_i$$의 거리를 계산한 뒤 가까운 $$k$$개 레이블의 다수결로 예측한다.

$$
d_1(x,x_i)=\sum_j |x_j-x_{ij}|,
\qquad
d_2(x,x_i)=\sqrt{\sum_j (x_j-x_{ij})^2}
$$

L1은 좌표축 방향의 차이를 더하고, L2는 유클리드 공간의 직선거리를 본다. 고차원 픽셀 공간의 거리가 인간의 시각적 유사성과 반드시 일치하지 않는다는 것이 근본 한계다.

### $$k$$가 결정 경계에 미치는 영향

- $$k=1$$: 훈련 샘플 하나의 잡음에도 경계가 민감하다.
- 큰 $$k$$: 이웃 투표가 경계를 부드럽게 하지만, 지나치면 작은 클래스나 세부 구조를 잃는다.
- 동률: 거리 가중 투표나 정해진 tie-breaking 규칙이 필요하다.

k-NN은 훈련이 거의 없지만 예측 때 모든 데이터와 거리를 계산하므로 느리다. 실제 서비스는 일반적으로 훈련 비용을 감수하고 추론을 빠르게 만드는 쪽이 유리하다.

## 4. Train, validation, test split

거리 함수, $$k$$, 정규화 강도처럼 학습 전에 정해야 하는 값을 **hyperparameter**라고 한다. 이 값은 test set이 아니라 validation set으로 고른다.

| 분할 | 용도 |
|---|---|
| Training set | 모델 파라미터 학습 |
| Validation set | hyperparameter와 모델 선택 |
| Test set | 선택이 끝난 모델의 최종 평가 |

데이터가 작으면 여러 fold를 번갈아 validation으로 쓰는 cross-validation이 더 안정적인 추정치를 준다. 딥러닝에서는 계산 비용 때문에 고정 validation split을 더 자주 사용한다.

## 5. Linear classifier as a score function

이미지 $$x$$를 길이 $$D$$의 벡터로 펼치고 클래스 수를 $$C$$라 하면 선형 점수 함수는 다음과 같다.

$$
s = f(x,W,b)=Wx+b,
\qquad W\in\mathbb{R}^{C\times D},\ b\in\mathbb{R}^{C}
$$

$$W$$의 각 행은 한 클래스가 선호하는 픽셀 패턴을 담는 템플릿처럼 볼 수 있다. 점수는 입력마다 달라지지만 가중치는 모든 입력에 공유된다. 행렬곱 하나로 $$C$$개 점수를 동시에 계산하므로 k-NN과 달리 추론이 빠르다.

선형 분류기의 결정 경계는 입력 공간에서 hyperplane이다. 하나의 클래스가 다양한 자세와 배경을 가진다면 단일 템플릿으로 모두 표현하기 어렵다. 이 한계가 이후 비선형 신경망과 CNN을 도입하는 동기가 된다.

## 6. Multiclass SVM loss

정답 클래스 $$y_i$$의 점수 $$s_{y_i}$$가 모든 오답 점수보다 margin $$\Delta$$만큼 높기를 요구한다.

$$
L_i=\sum_{j\ne y_i}\max(0, s_j-s_{y_i}+\Delta)
$$

정답 점수가 충분히 높으면 해당 오답 클래스의 항은 0이다. SVM loss는 절대적인 점수보다 클래스 사이의 **상대적 간격**을 본다. 모든 점수를 같은 만큼 이동해도 손실은 변하지 않는다.

## 7. Softmax and cross-entropy loss

$$
p_j=\frac{e^{s_j}}{\sum_k e^{s_k}},
\qquad
L_i=-\log p_{y_i}
$$

정답 클래스 확률이 1에 가까우면 손실은 0에 가까워지고, 정답에 매우 낮은 확률을 주면 손실이 커진다. 수치적으로는 큰 점수를 빼고 지수함수를 계산하는 log-sum-exp 안정화가 필요하다.

SVM은 margin을 만족하면 더 이상 보상하지 않지만, softmax는 정답의 확률을 계속 높이려 한다. 두 손실 모두 점수 함수의 파라미터 $$W,b$$를 어떻게 고칠지 알려 주는 스칼라 목적함수다.

## 8. Loss over the dataset

$$
L(W)=\frac{1}{N}\sum_{i=1}^{N}L_i + \lambda R(W)
$$

첫 항은 데이터 적합도이고, 둘째 항은 지나치게 복잡한 가중치를 억제한다. 이 강의에서는 손실을 정의하고, 실제로 그 손실을 낮추는 최적화는 다음 강의로 넘긴다.

## 핵심 수식 유도

### 작성자 보충: softmax cross-entropy gradient

강의의 loss 정의를 미분 과정까지 확장한다. 클래스 수가 유한한 $$C$$이고, logit $$s=(s_1,\ldots,s_C)\in\mathbb{R}^C$$가 모두 유한하며, 정답 index가 $$y\in\{1,\ldots,C\}$$라고 하자. Softmax probability와 한 샘플의 cross-entropy loss는

$$
p_j=\frac{e^{s_j}}{\sum_{k=1}^{C}e^{s_k}},
\qquad
L=-\log p_y
$$

라는 **정의**다. $$Z=\sum_{k=1}^{C}e^{s_k}$$라 두면 quotient 안의 log를 풀어

$$
L=-\log\frac{e^{s_y}}{Z}=-s_y+\log Z
$$

를 얻는다. 임의의 클래스 $$j$$에 대해 첫 항은 정답 logit일 때만 미분값을 가지므로

$$
\frac{\partial(-s_y)}{\partial s_j}=-\mathbf{1}[j=y]
$$

이고, log-sum-exp 항은 chain rule로

$$
\begin{aligned}
\frac{\partial\log Z}{\partial s_j}
&=\frac{1}{Z}\frac{\partial}{\partial s_j}
\sum_{k=1}^{C}e^{s_k}\\
&=\frac{e^{s_j}}{Z}=p_j.
\end{aligned}
$$

따라서 두 항을 합치면

$$
\boxed{\frac{\partial L}{\partial s_j}
=p_j-\mathbf{1}[j=y]}
$$

라는 **정확한 등식**이 된다. 오답 클래스에서는 gradient가 $$p_j\ge 0$$이므로 gradient descent가 그 logit을 낮추고, 정답 클래스에서는 $$p_y-1\le 0$$이므로 logit을 높인다. 또한 $$\sum_j \partial L/\partial s_j=0$$이어서 모든 logit에 같은 상수를 더해도 probability와 loss가 변하지 않는다는 사실과 일치한다.

지수와 logarithm의 입력은 무차원이어야 하므로 logit $$s_j$$, probability $$p_j$$, loss $$L$$, class index와 indicator는 모두 무차원이며, $$\partial L/\partial s_j$$도 무차원이다. $$p_y\to1$$이면 $$L\to0$$이고 모든 gradient가 0에 가까워진다. 반대로 $$p_y\to0^+$$이면 $$L\to\infty$$이며 정답 logit의 gradient는 $$-1$$에 가까워진다. 수학적으로 유한한 logit에서는 $$0<p_j<1$$이지만, 구현에서는 overflow·underflow를 피하려고 모든 logit에서 $$\max_k s_k$$를 빼는 log-sum-exp 안정화를 사용해야 한다.

이 유도는 one-hot 정답을 갖는 categorical likelihood와 미분 가능한 유한 logit을 가정한다. Label noise, 심한 class imbalance, multi-label target, 불완전한 class 정의에서는 이 loss가 실제 task utility를 그대로 나타내지 못하며, hard label이 틀렸을 때 큰 gradient가 오히려 잘못된 방향의 학습 신호가 될 수 있다.

## 마지막 핵심 정리

- 이미지 분류의 핵심 난점은 **픽셀의 거리와 의미의 거리가 다르다**는 데 있다.
- k-NN은 거리 기반 기준선이지만 느린 추론과 부적절한 픽셀 거리라는 한계가 있다.
- 선형 분류기는 $$s=Wx+b$$로 클래스 점수를 빠르게 계산하지만 결정 경계가 선형이다.
- SVM은 margin, softmax는 정답 log-probability로 좋은 점수를 정의한다.
- test set은 마지막 평가에만 쓰고 hyperparameter는 validation set에서 선택한다.

## Study Guide

1. `image -> score function -> loss -> optimization`의 연결을 먼저 설명한다.
2. k-NN에서는 $$k$$와 거리 함수가 왜 파라미터가 아니라 hyperparameter인지 구분한다.
3. SVM loss와 softmax loss의 수식을 직접 계산해 보고, 점수 이동에 대한 불변성을 확인한다.
4. 선형 분류기의 클래스별 가중치를 이미지로 시각화했을 때 평균 템플릿처럼 보이는 이유를 설명한다.

## 복습 질문

<details markdown="block">
<summary>1. 픽셀 L2 거리가 시각적 유사성을 잘 나타내지 못하는 이유는 무엇인가?</summary>

답변: 작은 평행 이동이나 조명 변화도 많은 픽셀 값을 바꾸지만 물체의 의미는 유지되기 때문이다. 반대로 배경과 색이 비슷한 서로 다른 물체가 픽셀 공간에서는 가깝게 보일 수도 있다.

</details>

<details markdown="block">
<summary>2. validation set과 test set을 분리해야 하는 이유는 무엇인가?</summary>

답변: validation 성능을 보며 hyperparameter를 반복 선택하면 그 정보에 간접적으로 과적합된다. test set을 마지막 한 번의 독립 평가에 남겨야 일반화 성능을 공정하게 추정할 수 있다.

</details>

<details markdown="block">
<summary>3. SVM loss에서 정답 점수가 margin보다 충분히 높으면 어떻게 되는가?</summary>

답변: 해당 오답 클래스의 $$\max(0,\cdot)$$ 항이 0이 되어 더 이상 손실에 기여하지 않는다.

</details>

<details markdown="block">
<summary>4. softmax loss가 점수를 확률처럼 해석하는 과정은 무엇인가?</summary>

답변: 각 점수를 지수화해 양수로 만든 뒤 모든 지수값의 합으로 나누고, 정답 클래스 확률의 음의 로그를 손실로 사용한다.

</details>

## 원문 대조 기록

공식 PDF **102쪽 전체**를 페이지 단위로 시각 점검하고 강의 transcript와 대조했다. 아래 쪽수는 PDF viewer 기준이다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 30–48쪽 · 영상 00:01:38 | k-NN, L1/L2 distance, validation | 2–4절 |
| PDF 53–67쪽 | linear score $$s=Wx+b$$와 template 해석 | 5절 |
| PDF 68–102쪽 · 영상 00:57:44 | softmax, cross-entropy, multiclass SVM | 6–8절 |

1–8절의 정의와 비교는 강의 원문 요약이고, softmax gradient의 단계별 미분·단위·수치 안정성은 원문 식을 확장한 **작성자 보충**이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 2](https://www.youtube.com/watch?v=pdqofxJeBN8){:target="_blank" rel="noopener"}
- [Official Lecture 2 slides](https://cs231n.stanford.edu/slides/2025/lecture_2.pdf){:target="_blank" rel="noopener"}
