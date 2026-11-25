---
layout: default
date: 2026-08-12 10:07:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Stanford CME295 Lecture 2: Transformer-Based Models & Tricks"
course: "CME295"
topic: "Transformer Variants, Positional Information, Attention Optimization, and BERT Models"
order: 2
major_topic: "Large Language Models"
keywords:
  - "RoPE"
  - "RMSNorm"
  - "GQA"
  - "BERT"
  - "Position Embeddings"
---

# Stanford CME295 Lecture 2: Transformer-Based Models & Tricks

Source: [Stanford CME295 Autumn 2025 Lecture 2](https://www.youtube.com/watch?v=yT84Y5zCnaA){:target="_blank" rel="noopener"}

**원본 영상 먼저 보기:** [00:37:26의 RoPE 설명](https://www.youtube.com/watch?v=yT84Y5zCnaA&t=2246s){:target="_blank" rel="noopener"}에서 query와 key를 위치별 각도로 회전시키고 두 위치의 차이가 attention score에 남는다는 설명을 먼저 듣습니다. 아래 위치 표현 절은 이 관계를 회전 행렬과 상대 위치 항등식으로 보강합니다.

<figure>
  <a href="{{ '/assets/images/study/cme295/source-captures/lecture-02-rope-00h37m26s.jpg' | relative_url }}" target="_blank" rel="noopener">
    <img src="{{ '/assets/images/study/cme295/source-captures/lecture-02-rope-00h37m26s.jpg' | relative_url }}" alt="query와 key 벡터를 위치별 각도로 회전시키는 RoPE 강의 슬라이드" loading="lazy">
  </a>
  <figcaption><a href="https://www.youtube.com/watch?v=yT84Y5zCnaA&t=2246s" target="_blank" rel="noopener">공식 영상 00:37:26</a> — 위치 m의 query와 위치 n의 key에 각각 mθ, nθ 회전을 적용하는 RoPE의 기하적 표현과 2차원 회전 행렬입니다.</figcaption>
</figure>

왼쪽과 오른쪽 벡터는 절대 위치만큼 따로 회전하지만, 두 벡터의 내적에서는 회전각의 차이인 $$(m-n)\theta$$가 남습니다. 이 때문에 별도 위치 벡터를 더하지 않아도 attention score가 상대 거리를 반영합니다.

> **핵심:** ‘민지가 준호를 불렀다’에서 이름의 자리를 바꾸면 누가 누구를 불렀는지가 달라집니다. 단어 사이의 관련도만 계산하는 셀프 어텐션에는 자리 자체를 알려 주는 장치가 없습니다. 이 강의에서는 위치를 알려 주는 방법과 긴 글을 더 적은 메모리로 처리하는 방법을 구분해 살핍니다.

<details markdown="block">
<summary markdown="span">전체 구성 보기</summary>

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | Attention map과 multi-head | 각 head는 Q/K/V projection을 어떻게 다르게 학습하고 attention map으로 무엇을 해석할 수 있습니까? |
| 2 | Position embedding | Learned position embedding과 sinusoidal position embedding은 어떤 장단점을 갖습니까? |
| 3 | Relative position methods | T5 relative position bias, ALiBi, RoPE는 위치 정보를 attention 계산에 어떻게 넣습니까? |
| 4 | Normalization 변화 | Post-norm에서 pre-norm으로, LayerNorm에서 RMSNorm으로 바뀐 이유는 무엇입니까? |
| 5 | Attention efficiency | Sliding window attention, MQA, GQA는 O(n^2) 계산량 또는 KV cache 메모리를 어떻게 줄입니까? |
| 6 | Transformer model families | Encoder-decoder, encoder-only, decoder-only 모델은 어떤 task와 objective에 대응합니까? |
| 7 | BERT training | BERT의 MLM, NSP, CLS/SEP/segment embedding은 classification representation을 어떻게 학습시킵니까? |
| 8 | BERT variants | DistilBERT와 RoBERTa는 BERT의 어떤 비용 또는 objective 문제를 바꾸려 했습니까? |

</details>
## 핵심 내용

왜 위치를 따로 넣어야 하는지부터 보면 뒤의 방법들이 정리됩니다. Self-attention만 계산하면 토큰 집합은 알 수 있어도 `개가 사람을 쫓았다`와 `사람이 개를 쫓았다`의 자리 차이를 자동으로 알 수 없습니다. Position embedding은 각 토큰에 “몇 번째인가”라는 표식을 붙이고, relative position 방식은 “두 토큰이 얼마나 떨어졌는가”를 attention 점수에 반영합니다. Sinusoidal, T5 bias, ALiBi, RoPE는 모두 이 순서 문제를 해결하지만 위치 정보를 넣는 지점과 방식이 서로 다릅니다.

구체적으로 원래 Transformer는 위치별 embedding을 토큰 embedding에 더했고, 학습형과 sinusoidal 방식을 모두 시험했습니다. Sinusoidal 방식은 서로 다른 주기의 sine과 cosine으로 위치마다 고유한 무늬를 만듭니다. T5 relative position bias와 ALiBi는 두 토큰 사이 거리에 따른 값을 attention 점수에 더합니다. RoPE(Rotary Position Embeddings)는 query와 key를 위치별 각도로 회전시켜, 두 벡터를 비교할 때 상대 거리가 드러나게 합니다. 정확한 주파수식과 회전식은 아래 상세 유도에서 확인할 수 있습니다.

다음은 학습 안정성과 긴 입력의 비용 문제입니다. Normalization은 한 층의 숫자 크기가 지나치게 커지거나 작아지지 않도록 맞춥니다. Pre-norm은 이 정리를 sublayer 계산 전에 하고, post-norm은 계산과 residual 덧셈 뒤에 합니다. LayerNorm은 평균과 분산을 사용하고, RMSNorm은 평균을 빼지 않고 제곱평균의 제곱근으로 크기만 맞춥니다.

긴 문장에서는 모든 토큰 쌍을 비교하는 full attention의 계산량이 토큰 수의 제곱으로 증가합니다. Sliding-window attention은 각 토큰이 주변만 보게 해 비교 수를 줄입니다. MQA는 여러 attention head가 같은 key/value를 공유하고, GQA는 몇 개의 head끼리 공유해 KV cache 저장량을 줄입니다. 즉 windowing은 **비교할 위치 수**, MQA·GQA는 **저장할 key/value 묶음 수**를 줄입니다.

여기서 normalization과 효율화는 서로 다른 질문에 답합니다. Pre-norm과 RMSNorm은 깊은 층을 지나도 학습 신호가 안정적으로 흐르게 하는 쪽이고, sliding window·MQA·GQA는 긴 입력을 처리할 때 계산량과 저장 공간이 커지는 문제를 줄이는 쪽입니다. 모델 표에서 이 이름들이 함께 보여도, 하나는 **학습 안정성**, 다른 하나는 **실행 비용**을 조정한다는 기준으로 나누어 읽으면 됩니다.

후반부는 Transformer 기반 모델 계열을 세 갈래로 정리합니다. Encoder-decoder 계열에는 T5가 있으며, T5는 Transfer Text-to-Text Transformer의 약자로 mT5, ByT5 같은 변형과 span corruption objective, sentinel token, teacher forcing을 사용합니다. Encoder-only 계열에서는 BERT를 깊게 다룹니다. BERT는 Bidirectional Encoder Representations from Transformers이고, decoder를 제거한 encoder-only 구조로 모든 token이 양방향으로 attend할 수 있어 classification에 적합합니다. CLS token은 전체 입력의 bidirectional 정보를 담는 placeholder로 classification head에 연결되고, SEP token은 두 문장을 구분합니다. Pre-training은 MLM(Masked Language Model)과 NSP(Next Sentence Prediction)로 구성되며, MLM은 선택 token의 80%를 [MASK]로 바꾸고 10%는 그대로 두며 10%는 random word로 바꿉니다. Fine-tuning에서는 CLS token 또는 token-level embedding 위에 linear layer를 붙입니다. 마지막에는 BERT base가 약 110M parameter와 512 context length 한계를 갖는다고 언급하고, DistilBERT는 distillation과 layer 수 감소로 더 작고 빠르게 만들며, RoBERTa는 NSP를 제거하고 dynamic masking과 더 크고 다양한 data strategy를 사용했다고 설명합니다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| Attention map | 특정 query token이 다른 key token들과 갖는 attention weight를 시각화한 것입니다. 강의에서는 its가 law, application과 강하게 연결되는 예를 들었습니다. |
| Sinusoidal position embedding | Position m과 dimension i에 대해 sine/cosine 값을 계산해 position embedding을 만드는 방식입니다. 강의에서는 omega_i = 10000^{-2i/d_model} 형태를 소개했습니다. |
| Relative position bias | Attention softmax 내부에 position 차이에 따른 bias를 더하는 방식입니다. T5는 m - n 거리를 bucketize하고 bias term을 학습한다고 설명됐습니다. |
| ALiBi | Attention with Linear Bias로 소개되며, learned bias 대신 relative distance에 대한 deterministic formula를 attention에 넣는 방법입니다. |
| RoPE | Rotary Position Embeddings의 약자입니다. Query와 key vector를 position에 따른 angle로 회전시켜 QK^T가 relative distance에 의존하게 합니다. |
| RMSNorm | Root Mean Square Normalization입니다. LayerNorm과 달리 mean subtraction과 beta 없이 root mean square로 normalize하고 gamma만 학습합니다. |
| Sliding window attention | 각 token이 전체 sequence가 아니라 주변 window의 token에만 attend하도록 제한하는 local attention 방식입니다. |
| Grouped Query Attention (GQA) | Query projection은 head별로 유지하되 key/value projection을 group 단위로 공유하는 방식입니다. KV cache memory 절약과 관련해 설명됐습니다. |
| Span corruption | T5의 training objective입니다. 입력 문장의 일부 span을 sentinel token으로 대체하고 decoder가 빠진 span들을 순서대로 복원합니다. |
| Masked Language Model (MLM) | BERT pre-training objective입니다. 선택된 token을 80%는 [MASK], 10%는 그대로, 10%는 random word로 처리하고 원래 token을 예측하게 합니다. |

**Supplementary table — attention score에 위치를 넣는 방식**

<div markdown="block" role="region" aria-label="Transformer positional encoding comparison" tabindex="0" style="overflow-x: auto;">

| 방법 | 위치 정보가 들어가는 곳 | Learned parameter | 상대 거리 표현의 핵심 |
|---|---|---|---|
| Sinusoidal | Token embedding에 절대 위치 vector를 더함 | 없음 | Sine/cosine의 내적과 선형 관계로 위치 차이를 해석할 수 있습니다. |
| T5 relative bias | Attention logit에 거리 bucket별 bias를 더함 | Bucket별 bias | 정확한 거리 대신 범위별 상대 거리를 학습합니다. |
| ALiBi | Attention logit에 head별 선형 거리 penalty를 더함 | 보통 위치 embedding 자체는 없음 | 멀수록 더 큰 deterministic penalty를 줍니다. |
| RoPE | Query와 key를 위치별 회전한 뒤 내적 | 회전 주파수 설정은 구현에 따름 | $$R(m)^\top R(n)=R(n-m)$$으로 상대 위치가 score에 남습니다. |
{: .reference-candidate-table style="min-width: 44rem;" }

</div>

표는 원본 강의의 네 방법을 `입력에 더하는가, logit을 바꾸는가, Q/K를 회전하는가`로 구분한 작성자 보충입니다. 각 방법의 long-context 성능은 이 구조만으로 보장되지 않고 학습 길이와 extrapolation 설정에 의존합니다.

## 수식 해설: position, normalization, attention cost

위치 기법은 attention score에 상대 거리 정보를 넣고, RMSNorm은 vector의 RMS로 scale을 정규화합니다. 계산 측면에서는 full attention이 token 수 $$n$$에 대해 $$\Theta(n^2)$$이고, KV cache는 대략 $$2Lnh_{kv}d_hb$$ byte를 사용하므로 windowing과 KV head 공유가 서로 다른 병목을 줄입니다.

<details markdown="block">
<summary markdown="span">Derivation: Relative position, RMSNorm, and attention memory</summary>

| 수식 주제 | 공식 영상 timestamp | 출처 경계 |
|---|---:|---|
| Sinusoidal position과 상대 거리 | 00:16:12–00:24:45 | 주파수식과 삼각함수·내적 설명은 강의 원문이며, 아래 행렬 표기와 조건 정리는 작성자 보충입니다. |
| T5 relative bias와 ALiBi | 00:28:41–00:30:45, 00:36:35–00:36:48 | Bucketized learned bias와 deterministic linear bias는 강의 원문이며, 아래 식·부호·거리 convention은 작성자 보충입니다. |
| RoPE rotation identity | 00:37:26–00:43:20 | 상대 위치가 회전 차이로 들어간다는 설명은 강의 원문입니다. 전개식은 강의가 생략한 수학 세부를 보충합니다. |
| RMSNorm | 00:47:04–00:47:44 | Root mean square 정규화와 parameter 감소는 강의 원문이며, 정확한 정의·shift 한계는 작성자 보충입니다. |
| Attention 비용과 KV 공유 | 00:50:48–00:52:35, 00:57:34–00:59:45 | $$O(n^2)$$와 MQA/GQA의 메모리 직관은 강의 원문이며, $$\Theta(nw)$$·byte 식은 작성자 보충입니다. |

### Sinusoidal position과 relative distance

짝을 이룬 두 차원에서 $$\omega_i=10000^{-2i/d_{\mathrm{model}}}$$라 두고

$$
p_m^{(i)}=
\begin{bmatrix}
\sin(m\omega_i)\\
\cos(m\omega_i)
\end{bmatrix}
$$

로 정의합니다. 두 position의 같은 frequency 쌍을 내적하면

$$
\left(p_m^{(i)}\right)^\top p_n^{(i)}
=\sin(m\omega_i)\sin(n\omega_i)
+\cos(m\omega_i)\cos(n\omega_i)
=\cos((m-n)\omega_i).
$$

따라서 내적은 position 차이 $$m-n$$에 의존합니다. 이는 **정확한 삼각함수 항등식**입니다. Index와 angle은 무차원입니다. 여러 frequency를 합친 embedding이 임의 거리에서 유일하거나 extrapolation 품질을 보장한다는 뜻은 아닙니다.

Attention logit에 relative bias를 더하는 공통 표기는

$$
\ell_{ij}=\frac{q_i^\top k_j}{\sqrt{d_k}}+b(i,j)
$$

입니다. 여기서는 query 위치를 $$i$$, key 위치를 $$j$$로 두고 causal attention의 과거 거리를 $$\delta=i-j\ge0$$로 정의합니다. T5 방식은 $$b(i,j)=\beta_{B(j-i)}$$처럼 **signed relative displacement를 bucket 함수 $$B$$에 넣어 bucket별 $$\beta$$를 학습**합니다. $$B(i-j)$$를 쓰는 구현도 가능하지만 그때는 bucket의 양·음 방향 의미도 함께 뒤집어야 합니다. Bucket 경계와 bidirectional/causal bucket 분할은 구현 convention이며, 강의는 식 전체가 아니라 learned bucket bias의 아이디어를 설명합니다.

ALiBi의 한 causal-head convention은

$$
\ell_{ij}=\frac{q_i^\top k_j}{\sqrt{d_k}}-m_h(i-j),
\qquad j\le i,\quad m_h>0,
$$

이고 $$j>i$$는 causal mask로 제외합니다. 거리가 커질수록 음의 penalty가 커집니다. 이를 $$+m_h(j-i)$$로 쓰는 것은 같은 convention이며, 거리의 방향을 정의하지 않고 부호만 옮기면 반대 효과가 나므로 둘을 섞으면 안 됩니다. Head별 slope $$m_h$$의 실제 schedule과 extrapolation 품질은 설계·경험적 결과이지 위 선형식만으로 증명되지 않습니다.

RoPE의 2차원 rotation matrix를 $$R(\theta)$$라 하면

$$
(R(m\theta)q)^\top(R(n\theta)k)
=q^\top R(m\theta)^\top R(n\theta)k
=q^\top R((n-m)\theta)k.
$$

여기서 $$R(a)^\top=R(-a)$$, $$R(a)R(b)=R(a+b)$$를 썼습니다. Score가 relative displacement에 의존한다는 것은 회전 block 안의 정확한 항등식이지만 실제 long-context 품질은 frequency schedule과 training range에 좌우됩니다.

### RMSNorm과 비용식

입력 $$x\in\mathbb{R}^{d}$$에 대한 RMSNorm은 보통

$$
\operatorname{RMSNorm}(x)_i
=\gamma_i\frac{x_i}{\sqrt{\frac{1}{d}\sum_{j=1}^{d}x_j^2+\varepsilon}}
$$

로 정의합니다. $$\gamma_i$$는 학습 scale, $$\varepsilon>0$$은 수치 안정화 상수입니다. LayerNorm과 달리 mean을 빼지 않으므로 shift invariance는 없습니다. 비슷한 성능은 경험적 관찰이지 정의에서 증명되는 결과가 아닙니다.

Full attention은 $$n\times n$$ score matrix를 만들므로 계산·저장량이 $$\Theta(n^2)$$입니다. Window 폭이 $$w$$이면 최대 $$\Theta(nw)$$로 줄지만 window 밖 직접 연결을 잃습니다. Autoregressive KV cache는 layer 수 $$L$$, token 수 $$n$$, KV head 수 $$h_{kv}$$, head dimension $$d_h$$, element당 byte $$b$$일 때 대략

$$
M_{KV}=2Lnh_{kv}d_hb
$$

byte입니다. 2는 key와 value를 뜻합니다. Batch·beam 수와 allocator overhead는 별도로 반영해야 합니다.

</details>

## 학습 포인트

- Position information은 Transformer에서 별도로 주입되어야 하며, learned embedding은 training set의 max position에 제한됩니다.
- Sinusoidal position embedding은 sine/cosine을 사용해 position dot product가 relative distance의 함수가 되도록 설계됩니다.
- RoPE는 query와 key를 position-dependent angle로 회전시켜 attention formula 안에 relative distance를 직접 반영합니다.
- 현대 모델은 원 Transformer의 post-norm보다 pre-norm을 많이 쓰고, LayerNorm 대신 RMSNorm을 쓰기도 합니다.
- Self-attention은 sequence length n에 대해 O(n^2)이므로 sliding window/local attention 같은 근사가 사용됩니다.
- MQA와 GQA는 key/value projection을 head 사이에 공유해 KV cache memory를 줄이는 attention 변형입니다.
- T5는 encoder-decoder 구조와 span corruption, sentinel token을 사용합니다.
- BERT는 encoder-only 구조이며 MLM과 NSP pre-training 후 CLS token 또는 token-level embedding 위에서 fine-tuning됩니다.

## 마지막 핵심 정리

이 강의의 핵심은 `Transformer 변형, 위치 정보, attention 최적화, BERT 계열`를 개별 기법 목록이 아니라 Transformer 기반 LLM의 설계·학습·운영 흐름 속에서 이해하는 것입니다. 세부 구현을 볼 때도 입력 표현, 학습 목표, 추론 비용, 평가 기준이 서로 어떻게 연결되는지 함께 확인해야 합니다.

## Study Guide

<details markdown="block">
<summary markdown="span">Review guide: concepts to revisit in order</summary>

1. Position embedding 방법들을 input에 더하는 방식과 attention 내부에 넣는 방식으로 나눠 비교합니다.
2. RoPE가 왜 query/key 회전과 relative distance를 연결하는지 QK^T 관점에서 설명합니다.
3. LayerNorm, RMSNorm, pre-norm, post-norm의 차이를 식의 위치와 학습 parameter 관점에서 정리합니다.
4. Sliding window attention, MQA, GQA가 각각 계산량 또는 메모리의 어느 부분을 줄이는지 구분합니다.
5. T5, BERT, GPT-style decoder-only 모델을 encoder-decoder, encoder-only, decoder-only로 분류합니다.
6. BERT의 MLM/NSP, WordPiece, CLS/SEP/PAD, segment embedding, fine-tuning 절차를 순서대로 복습합니다.

</details>

## 복습 질문

<details markdown="block">
<summary>1. Learned position embedding의 한계는 무엇입니까?</summary>

답변: Training set에서 본 최대 position까지만 embedding을 학습할 수 있고, training data의 position bias를 embedding이 그대로 학습할 수 있습니다. 더 긴 sequence의 position은 직접 학습되지 않습니다.

</details>

<details markdown="block">
<summary>2. RoPE가 attention 계산에 위치 정보를 넣는 방식은 무엇입니까?</summary>

답변: Query와 key vector를 각각 자신의 position에 따른 angle로 회전합니다. 그 결과 QK^T의 값이 두 position의 relative distance에 의존하게 되어 attention layer 안에서 위치 정보가 직접 반영됩니다.

</details>

<details markdown="block">
<summary>3. RMSNorm은 LayerNorm과 무엇이 다릅니까?</summary>

답변: LayerNorm은 activation에서 mean을 빼고 standard deviation으로 나눈 뒤 gamma와 beta를 학습합니다. RMSNorm은 root mean square로 normalize하고 gamma만 학습해 더 적은 parameter로 비슷한 convergence 특성을 노립니다.

</details>

<details markdown="block">
<summary>4. GQA와 MQA는 왜 KV cache와 관련이 있습니까?</summary>

답변: Decoding 때 이전 token들의 key/value를 계속 재사용해야 하므로 KV cache가 커집니다. GQA와 MQA는 key/value projection을 여러 head 사이에서 공유해 저장해야 할 key/value 수를 줄입니다.

</details>

<details markdown="block">
<summary>5. BERT의 CLS token은 fine-tuning에서 어떻게 사용됩니까?</summary>

답변: CLS token은 sequence 맨 앞에 놓이고 encoder self-attention을 거친 뒤 전체 입력의 bidirectional 정보를 담는 embedding으로 사용됩니다. Sentiment classification 같은 sentence-level task에서는 그 embedding 위에 classification layer를 붙입니다.

</details>

<details markdown="block">
<summary>6. RoBERTa는 BERT와 비교해 어떤 pre-training 선택을 바꾸었습니까?</summary>

답변: 강의에 따르면 RoBERTa는 NSP objective를 제거해도 성능 저하가 거의 없다는 점을 보였고, dynamic masking과 더 크고 다양한 data strategy를 추가했습니다.

</details>

## 참고자료

- 자료 확인 범위: 공식 Stanford CME295 강의 영상과 영문 전사를 대조했습니다. 공식 슬라이드는 없어 화면에 보이지 않는 내용은 추정하지 않았습니다.

- [강의 영상](https://www.youtube.com/watch?v=yT84Y5zCnaA){:target="_blank" rel="noopener"}
- [Stanford CME295 Autumn 2025 재생목록](https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy){:target="_blank" rel="noopener"}
