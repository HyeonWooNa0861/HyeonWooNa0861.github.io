---
layout: default
date: 2026-07-16 16:07:00 +0900
last_modified_at: 2026-09-03 19:49:35 +0900
title: "Stanford CS231N Lecture 8: Attention and Transformers"
course: "CS231N"
topic: "Attention and Transformers"
order: 8
major_topic: "Computer Vision"
keywords:
  - "Attention"
  - "Transformers"
  - "Self-Attention"
  - "Vision Transformer"
  - "QKV"
---

# Stanford CS231N Lecture 8: Attention and Transformers

Source: [Stanford CS231N Spring 2025 Lecture 8](https://www.youtube.com/watch?v=RQowiOF_FvQ){:target="_blank" rel="noopener"}

Official slides: [Lecture 8 PDF](https://cs231n.stanford.edu/slides/2025/lecture_8.pdf){:target="_blank" rel="noopener"}

> **핵심:** Attention은 query와 key의 유사도로 value를 가중합하는 연산이다. Self-attention은 모든 token이 서로 직접 정보를 교환하게 해 RNN의 긴 경로와 순차 계산을 줄이고, Transformer는 이 연산에 residual connection, normalization, MLP를 결합한 범용 구조다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Attention의 기원 | decoder가 encoder의 어느 위치를 볼지 어떻게 선택하는가? |
| 2 | Q, K, V | 검색 조건과 검색 대상, 전달 내용을 왜 분리하는가? |
| 3 | Self-attention | 입력 token끼리 어떻게 직접 상호작용하는가? |
| 4 | Masking | 미래 정보를 보지 않는 생성 모델은 어떻게 만드는가? |
| 5 | Multi-head attention | 여러 관계를 동시에 표현하려면 어떻게 하는가? |
| 6 | Transformer block | attention 주변에 어떤 연산이 필요한가? |

## 1. RNN attention의 동기

기존 encoder–decoder RNN은 입력 전체를 마지막 hidden state 하나로 압축했다. 긴 문장에서는 앞부분 정보가 이 병목을 통과하기 어렵다. Attention은 decoder의 현재 상태와 모든 encoder state의 유사도를 계산해, 이번 출력에 필요한 위치를 직접 가중합한다.

각 decoder step마다 attention weight가 달라지므로 단어를 생성할 때 참고하는 입력 위치도 바뀐다. 가중치는 해석 단서가 될 수 있지만, 곧바로 인간의 인과적 설명과 동일하다고 보아서는 안 된다.

## 2. Query, Key, Value

Attention을 검색 연산으로 보면 역할이 분명해진다.

- **Query $$Q$$:** 지금 찾고 싶은 정보
- **Key $$K$$:** 각 항목이 어떤 조건에 대응하는지 나타내는 주소
- **Value $$V$$:** 실제로 전달할 내용

Scaled dot-product attention은 다음과 같다.

$$
\operatorname{Attention}(Q,K,V)
=\operatorname{softmax}\left(\frac{QK^{\top}}{\sqrt{d_k}}\right)V
$$

$$QK^{\top}$$는 모든 query–key 쌍의 similarity matrix다. 행별 softmax는 각 query가 key들에 배분하는 가중치를 만든다. 이를 value에 곱하면 query별 weighted sum이 나온다.

## 3. 왜 $$\sqrt{d_k}$$로 나누는가

Query와 key의 차원이 커지면 독립 성분의 dot product 분산도 커진다. 큰 logit은 softmax를 지나치게 뾰족하게 만들어 대부분 위치의 gradient를 작게 할 수 있다. $$\sqrt{d_k}$$ scaling은 logit의 scale을 안정화한다.

이는 cosine similarity와 같지 않다. 벡터 norm을 1로 정규화하는 대신 차원에 따른 통계적 크기를 보정하는 것이다.

## 4. Cross-attention과 self-attention

Cross-attention은 query와 key/value가 서로 다른 출처에서 온다. 예를 들어 decoder query가 encoder의 key/value를 읽는다.

Self-attention에서는 같은 token matrix $$X$$를 서로 다른 learned projection으로 바꾼다.

$$
Q=XW_Q,\qquad K=XW_K,\qquad V=XW_V
$$

각 token의 출력은 다른 모든 token value의 입력 의존적 가중합이다. RNN에서 멀리 떨어진 token이 여러 step을 거쳤다면 self-attention에서는 한 layer 안에서 직접 연결된다. 또한 모든 query 행의 계산을 행렬곱으로 병렬화할 수 있다.

## 5. 순서 정보와 masking

Self-attention 자체는 token 순서를 바꿔 넣으면 출력도 같은 방식으로 바뀌는 permutation-equivariant 연산이다. 순서의 의미가 필요하면 positional encoding 또는 positional embedding을 입력에 더해야 한다.

Autoregressive language model은 위치 $$t$$가 미래 token을 보면 안 된다. Causal mask는 $$j>t$$인 attention logit에 $$-\infty$$를 더해 softmax 뒤의 가중치를 0으로 만든다.

$$
A=\operatorname{softmax}\left(\frac{QK^{\top}}{\sqrt{d_k}}+M\right)
$$

Encoder-style bidirectional attention은 전체 입력을 볼 수 있고, decoder-style masked attention은 과거와 현재만 본다는 차이가 있다.

## 6. Multi-head self-attention

하나의 attention map만으로 모든 관계를 표현하지 않고, 서로 다른 projection을 가진 $$H$$개 head를 병렬로 계산한다.

$$
\operatorname{head}_h=\operatorname{Attention}(XW_Q^{(h)},XW_K^{(h)},XW_V^{(h)})
$$

$$
\operatorname{MHA}(X)=\operatorname{Concat}(\operatorname{head}_1,\ldots,\operatorname{head}_H)W_O
$$

각 head는 위치 관계, 문법적 관계, 시각적 유사성처럼 다른 상호작용을 학습할 가능성이 있다. Head 수를 늘린다고 총 embedding dimension까지 반드시 늘어나는 것은 아니며, 보통 전체 차원을 head별 subspace로 나눈다.

## 7. Transformer block

Attention만으로는 각 token 내부의 비선형 변환이 충분하지 않다. Transformer block은 self-attention과 position-wise MLP를 결합하고 각 sublayer에 residual connection과 layer normalization을 둔다.

```text
tokens
  -> (LayerNorm) -> Multi-Head Self-Attention -> residual add
  -> (LayerNorm) -> MLP                       -> residual add
```

MLP는 모든 위치에 같은 파라미터를 독립적으로 적용한다. Attention이 token 사이 정보를 섞고, MLP가 token별 feature를 변환한다. Residual path는 깊은 stack에서 정보와 gradient 흐름을 돕는다.

Pre-norm은 sublayer 전에 normalization을 두고, post-norm은 residual addition 뒤에 둔다. 깊은 모델에서는 optimization 성질이 달라진다.

## 8. Complexity와 inductive bias

길이 $$N$$의 full self-attention은 attention matrix 때문에 시간·메모리가 대략 $$O(N^2)$$로 증가한다. 대신 token 간 path length가 짧고 병렬화가 쉽다. RNN은 순차적이지만 step당 관계 계산은 선형이고, convolution은 locality를 강하게 가정한다.

Transformer는 locality를 자동으로 강제하지 않으므로 데이터에서 관계를 학습할 자유가 크다. 이미지에서는 픽셀이나 patch 수가 커질수록 quadratic cost가 빠르게 커져 patching, local attention, hierarchical structure 같은 보완이 필요하다.

## 9. 현대 Transformer의 normalization과 gated MLP

공식 슬라이드 111–120쪽은 기본 block 뒤의 현대적 변형을 짚는다. **RMSNorm**은 평균을 빼지 않고 root-mean-square로 feature scale만 정규화한다.

$$
\operatorname{RMS}(x)
=\sqrt{\frac1D\sum_{j=1}^{D}x_j^2+\epsilon},
\qquad
y_i=\gamma_i\frac{x_i}{\operatorname{RMS}(x)}
$$

**SwiGLU** 계열 MLP는 한 projection을 SiLU gate로, 다른 projection을 value로 사용해 elementwise 곱한 뒤 출력 projection을 적용한다. 구현마다 bias와 projection 표기는 다르지만 대표 형태는

$$
\operatorname{SwiGLU}(x)
=\bigl(\operatorname{SiLU}(xW_g)\odot xW_v\bigr)W_o
$$

다. **Mixture of Experts(MoE)**는 token마다 router가 일부 expert만 선택해 conditional computation을 수행한다. 이는 같은 계산 예산에서 parameter capacity를 늘리는 architecture heuristic이며, routing imbalance·통신 비용·expert collapse 때문에 이론적 FLOP 절감이 실제 처리량으로 그대로 이어지지는 않는다.

## 핵심 수식 유도

### 작성자 보충: scaled dot product의 분산

독립이고 평균 0, 분산 1인 query/key 성분을 가정하면 dot product $$q^\top k=\sum_{i=1}^{d_k}q_ik_i$$의 분산은 $$d_k$$다. 따라서 $$q^\top k/\sqrt{d_k}$$의 분산은 1이 된다. 이는 가정 아래의 **분산 계산**이며 softmax saturation을 줄이는 scaling 근거다. $$d_k$$는 무차원 차원 수다. 성분이 강하게 상관되거나 norm이 별도 정규화되면 정확한 분산은 달라지며, scaling만으로 attention collapse를 막을 수는 없다.

### 작성자 보충: RMSNorm의 scale 성질

$$\epsilon=0$$이고 scalar $$a\ne0$$라 하면

$$
\operatorname{RMS}(ax)
=\sqrt{\frac1D\sum_j a^2x_j^2}
=|a|\operatorname{RMS}(x).
$$

따라서

$$
\frac{ax}{\operatorname{RMS}(ax)}
=\operatorname{sign}(a)\frac{x}{\operatorname{RMS}(x)}.
$$

즉 양의 공통 scale $$a>0$$에는 정규화 결과가 변하지 않고, 음수 scale에는 부호만 바뀐다. 이는 $$\epsilon=0$$인 정의에서 나오는 **정확한 항등식**이다. 실제 구현의 $$\epsilon>0$$에서는 denominator가 $$\sqrt{a^2\operatorname{RMS}_0(x)^2+\epsilon}$$이므로 작은 norm 영역의 완전한 scale invariance는 깨지지만 0으로 나누는 것을 막는다. $$x$$와 $$\gamma$$가 각각 feature와 output scale을 정하며, RMS로 나눈 값 자체는 무차원이다. RMSNorm은 평균을 제거하지 않으므로 LayerNorm과 동일한 변환이나 동일한 학습 동역학을 보장하지 않는다.

## 마지막 핵심 정리

- Attention은 $$\operatorname{softmax}(QK^{\top}/\sqrt{d_k})V$$다.
- Q/K는 **어디를 읽을지**, V는 **무엇을 전달할지** 정한다.
- Self-attention은 token 쌍을 직접 연결하고 행렬 연산으로 병렬화한다.
- Causal mask는 미래 위치의 확률을 0으로 만든다.
- Transformer block은 attention, MLP, residual, normalization의 조합이다.
- Full attention의 핵심 비용은 길이에 대한 $$O(N^2)$$ attention matrix다.

## Study Guide

1. 작은 Q, K, V 행렬로 score–softmax–weighted sum을 직접 계산한다.
2. self-attention과 cross-attention의 입력 출처를 구분한다.
3. causal mask 전후 attention matrix를 그려 미래 정보 차단을 확인한다.
4. RNN, CNN, Transformer의 path length, 병렬화, inductive bias를 비교한다.

## 복습 질문

<details markdown="block"><summary>1. key와 value를 분리하는 이유는 무엇인가?</summary>

답변: 어떤 항목을 선택할지 판단하는 표현과 선택된 뒤 전달할 내용을 서로 다른 projection으로 학습할 수 있기 때문이다.
</details>

<details markdown="block"><summary>2. self-attention만으로 token 순서를 알 수 없는 이유는?</summary>

답변: 같은 permutation을 입력에 적용하면 attention 출력도 그 permutation대로 바뀔 뿐, 연산 자체에는 절대 위치나 순서 정보가 없기 때문이다.
</details>

<details markdown="block"><summary>3. multi-head attention의 각 head는 왜 다른 관계를 학습할 수 있는가?</summary>

답변: head마다 독립된 Q/K/V projection이 있어 입력을 서로 다른 subspace에서 비교하고 결합하기 때문이다.
</details>

## 원문 대조 기록

공식 PDF **122쪽 전체**를 페이지 단위로 시각 점검하고 transcript를 대조했다.

| 원문 위치 | 확인한 내용 | 노트 대응 |
|---|---|---|
| PDF 6–46쪽 | RNN encoder–decoder attention과 Q/K/V | 1–4절 |
| PDF 47–61쪽 · 영상 00:34:01 | scaled dot-product self-attention과 masking | 3–5절 |
| PDF 62–78쪽 · 영상 00:55:32 | multi-head attention과 projection | 6절 |
| PDF 79–110쪽 | Transformer block, LM, ViT, complexity | 7–8절 |
| PDF 111–120쪽 | pre-norm, RMSNorm, SwiGLU, MoE | 9절 |

Attention과 현대 block 변형의 정의는 강의 원문 요약이다. Dot-product 분산과 RMSNorm scale 성질의 전개는 **작성자 보충**이며, MoE의 실제 처리량 평가는 수학적 보장이 아닌 시스템상 주의점이다.

## 참고자료

- [Stanford CS231N Spring 2025 Lecture 8](https://www.youtube.com/watch?v=RQowiOF_FvQ){:target="_blank" rel="noopener"}
- [Official Lecture 8 slides](https://cs231n.stanford.edu/slides/2025/lecture_8.pdf){:target="_blank" rel="noopener"}
