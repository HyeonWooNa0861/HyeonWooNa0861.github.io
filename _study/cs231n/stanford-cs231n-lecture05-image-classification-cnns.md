---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 5: Image Classification with CNNs"
course: "CS231N"
topic: "CNN-Based Image Classification"
order: 5
major_topic: "Computer Vision"
keywords:
  - "CNN"
  - "Convolution"
  - "Pooling"
  - "Image Classification"
  - "Feature Maps"
---

# Stanford CS231N Lecture 5: Image Classification with CNNs

Source: [Stanford CS231N Spring 2025 Lecture 5](https://www.youtube.com/watch?v=f3g1zGdxptI){:target="_blank" rel="noopener"}
Slides: [Official Stanford CS231N 2025 Lecture 5 PDF](https://cs231n.stanford.edu/slides/2025/lecture_5.pdf){:target="_blank" rel="noopener"}

> **핵심:** CNN은 이미지를 평평한 벡터로만 보지 않고, 지역 연결과 가중치 공유로 공간 구조를 모델에 넣는다. 필터 하나는 모든 위치에서 같은 패턴을 찾고, 여러 층은 작은 지역 관측을 넓은 receptive field와 계층적 표현으로 확장한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Image features | raw pixel보다 유용한 표현은 어떻게 얻는가? |
| 2 | Convolution | 작은 필터가 feature map을 어떻게 만드는가? |
| 3 | Spatial structure | local connectivity와 weight sharing은 왜 필요한가? |
| 4 | Receptive field | 깊은 unit은 입력의 어느 범위를 보는가? |
| 5 | Shape and cost | kernel, padding, stride가 출력 크기와 연산량을 어떻게 바꾸는가? |
| 6 | Downsampling | pooling과 strided convolution은 무엇을 보존하고 버리는가? |

## 1. Hand-crafted features에서 learned features로

선형 분류기는 펼친 픽셀에 직접 가중치를 곱하므로 위치 변화에 취약하고, 한 클래스의 여러 모양을 단일 템플릿으로 담기 어렵다. 전통적인 방식은 color histogram이나 edge descriptor를 사람이 설계한 뒤 선형 분류기에 넣었다. 신경망은 이 feature transform 자체를 데이터에서 학습한다.

CNN은 이미지의 두 가지 구조적 가정을 활용한다.

- 가까운 픽셀끼리 먼저 상호작용하는 **locality**
- 같은 시각 패턴이 다른 위치에도 나타날 수 있다는 **translation equivariance**

## 2. Convolution 연산

입력 $$X$$의 작은 영역과 필터 $$W$$의 dot product를 모든 공간 위치에서 반복해 하나의 activation map을 만든다. 엄밀히 말해 딥러닝 구현은 필터를 뒤집지 않는 cross-correlation이지만 관례상 convolution이라 부른다.

입력이 $$H\times W\times C_{in}$$, kernel이 $$K\times K$$, 필터 수가 $$C_{out}$$이면 가중치 tensor는 $$K\times K\times C_{in}\times C_{out}$$이다. 각 필터는 입력의 모든 channel을 관통하며 출력 channel 하나를 만든다.

$$
Y[i,j,c]=b_c+\sum_{u,v,k}W[u,v,k,c]X[i+u,j+v,k]
$$

한 필터의 파라미터가 모든 위치에 공유되므로 물체가 이동해도 같은 패턴 검출기가 대응 위치에서 활성화된다. 입력 이동이 출력 feature map의 이동으로 이어진다는 의미에서 equivariant하다.

## 3. Output size

한 공간축의 입력 크기 $$N$$, kernel $$K$$, padding $$P$$, stride $$S$$에 대한 출력 크기는

$$
N_{out}=\left\lfloor\frac{N+2P-K}{S}\right\rfloor+1
$$

이다. $$K=3,S=1,P=1$$은 크기를 유지하는 대표적인 설정이다. 나눗셈이 정수가 되지 않으면 일부 경계 위치가 버려지므로 구조 설계 전에 shape을 확인해야 한다.

Padding은 경계 정보가 빠르게 사라지는 것을 막고 출력 크기를 조절한다. Stride는 필터 이동 간격을 늘려 공간 해상도와 연산량을 함께 줄인다.

## 4. Receptive field

Receptive field는 출력 unit 하나가 의존하는 원본 입력 영역이다. stride 1의 $$3\times3$$ convolution 두 층을 쌓으면 두 번째 층 unit은 입력의 $$5\times5$$ 영역에 의존한다. 작은 kernel을 깊게 쌓으면 파라미터를 절약하면서 비선형성을 더 많이 넣고 관측 범위를 넓힐 수 있다.

일반적으로 layer $$l$$의 jump와 receptive field는

$$
j_l=j_{l-1}s_l,
\qquad
r_l=r_{l-1}+(k_l-1)j_{l-1}
$$

로 추적할 수 있다. 이론적 receptive field 안의 모든 픽셀이 실제로 같은 영향력을 갖는 것은 아니며, 중심부의 영향이 더 큰 effective receptive field가 관찰된다.

## 5. Parameter sharing의 효과

Fully connected layer가 $$HWC$$ 입력을 $$M$$개 unit에 연결하면 파라미터 수가 $$HWC\times M$$이다. 반면 convolution은 $$K^2C_{in}C_{out}$$개의 kernel 파라미터만 필요하며 공간 크기와 무관하게 이를 재사용한다.

이 inductive bias는 데이터 효율을 높이지만 완전한 translation invariance를 자동 보장하지는 않는다. 경계, stride, pooling, 최종 readout에 따라 출력은 이동에 민감할 수 있다.

## 6. Downsampling

Pooling은 작은 창에서 값을 요약한다.

- **Max pooling:** 가장 강한 activation을 보존하고 위치를 거칠게 만든다.
- **Average pooling:** 영역 평균으로 부드럽게 축소한다.
- **Strided convolution:** downsampling 방식도 학습하게 한다.

공간 크기를 절반으로 줄이면 이후 층의 feature-map 메모리와 계산량이 크게 감소한다. 그러나 sampling 전에 고주파 성분을 충분히 억제하지 않으면 aliasing이 생길 수 있어 anti-aliased pooling 같은 변형도 사용된다.

## 7. CNN classifier의 전체 구조

전형적인 흐름은 여러 `conv -> activation` 블록으로 spatial feature를 만들고, 중간에 downsampling을 수행한 뒤 마지막 feature를 classifier에 연결하는 것이다. 낮은 층은 edge와 color contrast, 중간 층은 texture와 part, 높은 층은 task에 유용한 의미 조합을 학습한다.

Backpropagation에서는 같은 kernel이 여러 위치에 쓰였으므로 각 위치에서 발생한 weight gradient를 모두 합한다. Weight sharing은 순전파뿐 아니라 역전파에도 반영된다.

## 핵심 수식 유도

### 작성자 보충: convolution parameter 수

Kernel 높이·폭을 $$K_h,K_w$$, 입력·출력 channel 수를 $$C_{in},C_{out}$$이라 하자. 표준 dense convolution의 출력 channel 하나는 모든 입력 channel을 관통하는 $$K_hK_wC_{in}$$개 weight와 bias 하나를 가지므로 전체 학습 parameter 수는

$$
\boxed{K_hK_wC_{in}C_{out}+C_{out}}
$$

이다. 이는 spatial 위치 수와 무관한 **정확한 개수**이며 모든 기호와 parameter count는 무차원 정수다. Bias를 사용하지 않으면 마지막 $$C_{out}$$을 빼며, grouped·depthwise convolution은 연결 구조가 다르므로 이 식을 그대로 쓰지 않는다.

### 작성자 보충: receptive field recurrence

Layer $$l$$의 kernel 크기, stride, dilation을 각각 $$K_l,S_l,D_l$$라 하고 effective kernel을 $$K_l^{\mathrm{eff}}=1+(K_l-1)D_l$$라 하자. 입력 pixel 수준에서 receptive field 크기 $$r_0=1$$, 인접 feature 사이의 입력 간격인 jump $$j_0=1$$로 시작하면

$$
j_l=j_{l-1}S_l,
\qquad
r_l=r_{l-1}+(K_l^{\mathrm{eff}}-1)j_{l-1}.
$$

새 layer의 첫 kernel 위치가 기존 $$r_{l-1}$$ 범위를 보고, 마지막 kernel 위치가 $$(K_l^{\mathrm{eff}}-1)$$번의 jump만큼 더 멀리 보기 때문에 두 번째 식이 나온다. 이는 regular grid convolution·pooling의 **정확한 기하식**이고 $$r_l,j_l,K_l$$는 pixel 개수, stride와 dilation은 무차원 정수다. Padding은 이론적 receptive-field 크기를 바꾸지 않지만 경계에서는 일부 위치가 실제 image 대신 padding을 본다. Skip connection, irregular sampling, deformable convolution에서는 경로별 receptive field를 따로 추적해야 하며, gradient가 실제로 집중되는 empirical effective receptive field는 이 이론적 최대 범위보다 작을 수 있다.

### 작성자 보충: output shape

입력 폭 $$W$$, zero-padding $$P$$, filter 폭 $$F$$, stride $$S$$에서 첫 window 시작은 0, 마지막은 $$W+2P-F$$이므로 가능한 이동 횟수는 $$(W+2P-F)/S$$다. 시작 위치까지 포함하면 output width는

$$
W_{\mathrm{out}}=1+\frac{W+2P-F}{S}.
$$

이는 numerator가 $$S$$로 나누어떨어질 때의 **정확한 shape 식**이며 길이들은 pixel, 비율은 무차원이다. 나누어떨어지지 않으면 framework의 floor/ceil 정책을 확인해야 한다. Backward에서는 input gradient가 자신을 덮은 모든 filter contribution의 합이고, weight gradient는 각 receptive-field patch와 upstream gradient의 correlation이다.

## 마지막 핵심 정리

- CNN의 핵심은 **local connectivity와 weight sharing**이다.
- 필터는 모든 입력 channel을 보며, 필터 수가 출력 channel 수가 된다.
- 출력 크기는 $$(N+2P-K)/S+1$$로 계산한다.
- 깊이가 늘면 receptive field와 표현의 추상성이 함께 커진다.
- Downsampling은 계산량을 줄이지만 공간 정보와 aliasing의 trade-off를 만든다.

## Study Guide

1. 임의의 입력·kernel·stride·padding에서 출력 tensor shape을 계산한다.
2. parameter count와 activation memory를 구분해 계산한다.
3. translation equivariance와 invariance의 차이를 예로 설명한다.
4. 여러 convolution layer를 거친 receptive field를 재귀식으로 추적한다.

## 복습 질문

<details markdown="block"><summary>1. convolution이 fully connected layer보다 이미지에 효율적인 이유는?</summary>

답변: 가까운 픽셀만 먼저 연결하고 같은 kernel을 모든 위치에 공유하므로 이미지의 공간 구조를 반영하면서 파라미터 수를 크게 줄이기 때문이다.
</details>

<details markdown="block"><summary>2. padding 없이 convolution을 반복하면 어떤 문제가 생기는가?</summary>

답변: feature map이 층마다 줄고 경계 픽셀이 중심 픽셀보다 적은 연산에 참여해 경계 정보가 빠르게 약해진다.
</details>

<details markdown="block"><summary>3. receptive field와 feature-map 크기는 같은 개념인가?</summary>

답변: 아니다. feature-map 크기는 출력 위치의 개수이고, receptive field는 출력 위치 하나가 참조하는 원본 입력 범위다.
</details>

## 원문 대조 기록

공식 PDF **141쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 29–79쪽 · 영상 00:24:34 | convolution filter, channel, activation map | 1–2절 |
| PDF 80–98쪽 · 영상 00:49:40, 00:51:31 | receptive field, stride, padding, output size | 3–4절 |
| PDF 99–107쪽 | pooling과 downsampling | 6절 |
| PDF 108–141쪽 | convolution history와 appendix examples | 본문 핵심 개념 대조; 비수식 사례는 추가하지 않음 |

Convolution 구조 설명은 강의 원문 요약이고, parameter count·receptive-field recurrence·output-shape 경계 조건은 **작성자 보충**이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 5](https://www.youtube.com/watch?v=f3g1zGdxptI){:target="_blank" rel="noopener"}
- [Official Stanford CS231N 2025 Lecture 5 PDF](https://cs231n.stanford.edu/slides/2025/lecture_5.pdf){:target="_blank" rel="noopener"}
