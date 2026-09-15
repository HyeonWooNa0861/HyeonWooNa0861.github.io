---
layout: default
date: 2026-09-14 16:37:00 +0900
last_modified_at: 2026-09-15 12:00:00 +0900
title: "RLT"
nav_title: "RLT"
topic: "Recurrent latent computation and full-history policy replay"
order: 82
major_topic: "Deep Learning Architectures"
keywords:
  - "Recurrent Looped Transformer"
  - "Latent reasoning"
  - "Sliding-window attention"
  - "Backpropagation through time"
  - "Policy replay"
  - "Model-hardware co-design"
---

# Recurrent Looped Transformer

Source: [Official project page](https://yifanzhang-pro.github.io/recurrent-looped-tranformer/){:target="_blank" rel="noopener"} · [Technical report PDF]({{ "/assets/pdfs/research/rlt-recurrent-looped-transformer/rlt-recurrent-looped-transformer.pdf" | relative_url }}){:target="_blank" rel="noopener"} · [Official repository](https://github.com/yifanzhang-pro/recurrent-looped-tranformer){:target="_blank" rel="noopener"}

## Paper Information

| Field | Detail |
|---|---|
| Title | Recurrent Looped Transformer |
| Alias | RLT |
| Author | Yifan Zhang |
| Report date | September 12, 2026 |
| Material type | Technical report and project documentation |
| Reviewed version | Original 19-page English PDF, repository README, and experiment figure accessed September 14, 2026 |
| Evidence boundary | Report definitions and analytical arguments; separate preliminary synthetic results in the README |

## One-Line Summary

**RLT는 토큰 사이로 계산 상태를 전달하는 구조이며, 핵심은 깊이라는 숫자보다 “무엇을 상태로 보존하고 어떻게 같은 계산을 재현하는가”에 있다.**

## Key Insights

공식 소개의 세 축은 잠재 공간의 순환 계산, 하드웨어를 고려한 실행, RL 정책 재평가의 일관성이다. Encoder는 전역 문맥을 제공하고 decoder는 이전 출력과 층별 sliding-window attention(SWA) 캐시를 이어받는다. Prompt와 response 경계에서도 이 상태를 유지한다. [Project overview](https://yifanzhang-pro.github.io/recurrent-looped-tranformer/){:target="_blank" rel="noopener"}

읽을 때는 세 질문을 분리해야 한다. **계산 경로가 존재하는가**, **그 경로에서 유용한 정보와 gradient가 유지되는가**, **동일한 비용에서 성능이 좋아지는가**는 다른 문제다. 아래는 이 구분을 위한 독자적 수학 해설이다. 원문 전체의 번역이 아니며, 작은 수치 예제와 검증 제안은 이 글에서 추가했다.

## Reading Map

| Source | Focus in this article |
|---|---|
| Report Sections 1–2 | State, attention memory, token processing |
| Section 3 and Appendix B | Causality, serving-split invariance, temporal depth |
| Section 4 | Sequential dependencies and hardware trade-offs |
| Section 5 and Appendices A–C | Losses, gradients, replay, cache validity |
| Sections 6–8 | Conversation continuity, related-work context, validation needs |
| Repository README | Preliminary synthetic experiment and evidence limits |

## 1. State Is More Than a Hidden Vector

### 1.1 Definitions and notation

원문 식 (2.3)–(2.6)의 중심 정의는 다음과 같다.

$$
H_0=(s_\star,\varnothing),\qquad H_t=(s_t,C_t^D).
$$

$$
H_t=D_\phi\!\left(\operatorname{Merge}(e_t,s_{t-1});M_{\le t},C_{t-1}^D,t\right).
$$

$$
p_\Theta(x_{t+1}\mid x_{1:t})
=\operatorname{softmax}\!\left(W_o\operatorname{RMSNorm}_o(s_t)\right)_{x_{t+1}}.
$$

여기서 마지막 식은 다음 토큰의 조건부 확률을 **정의**한다. Softmax는 vocabulary 전체의 확률 벡터를 만들고, 첨자는 그중 실제 다음 토큰에 대응하는 성분을 선택한다. 현재 토큰 $$x_t$$까지 상태를 갱신한 뒤 $$s_t$$로 다음 토큰 $$x_{t+1}$$을 예측한다. $$x_{t+1}$$을 먼저 읽고 그 토큰의 확률을 구하면 다른 조건부 분포를 계산한다.

| Symbol | Meaning | Type / unit |
|---|---|---|
| $$x_t$$ | 위치 $$t$$에서 읽은 토큰 | 이산 ID, 무차원 |
| $$t,T$$ | 현재 위치와 prompt 마지막 위치 | 정수 index, 무차원 |
| $$e_t,s_t$$ | Encoder 표현과 decoder 최종 출력 | $$\mathbb R^d$$ 벡터, 물리 단위 없음 |
| $$H_t$$ | Decoder 출력과 SWA 캐시의 묶음 | 복합 상태, 물리 단위 없음 |
| $$C_t^D$$ | 층별로 보관한 decoder key/value | 텐서 묶음, 물리 단위 없음 |
| $$M_{\le t}$$ | 현재 위치까지의 encoder 유래 전역 메모리 | Key/value 묶음, 물리 단위 없음 |
| $$W,L_E,L_D$$ | SWA 창 크기, encoder·decoder 층 수 | 양의 정수 개수 |
| $$\Theta,\phi$$ | 전체 파라미터와 decoder 파라미터 | 학습 변수, 물리 단위 없음 |
| $$s_\star$$ | 학습하는 초기 decoder 출력 | $$\mathbb R^d$$ 벡터 |

$$H_t$$는 **decoder의** 완전 상태이지 서비스 전체의 모든 상태는 아니다. Encoder의 incremental cache, 위치 정보, 메모리도 별도로 필요하다. 특정 텐서만 저장하고 전체 문맥을 복원했다고 판단하지 않는 것이 이 구분의 실용적 의미다.

### 1.2 Why separate memories are necessary

아래는 attention의 일반적 계산을 단순화한 설명이다. Key가 어떤 값에 주목할지 결정하고 value가 결합할 정보를 담는다고 하자. 한 head의 계산은 다음과 같다.

$$
a_j=\frac{\exp(q^{\top}k_j/\sqrt{d_k})}
{\sum_{m\in\mathcal J}\exp(q^{\top}k_m/\sqrt{d_k})},
\qquad o=\sum_{j\in\mathcal J}a_jv_j.
$$

$$q,k_j\in\mathbb R^{d_k}$$이고 $$v_j$$는 value 벡터다. $$\mathcal J$$는 허용된 위치의 집합이다. 확률 가중치의 합이 1이므로 출력은 허용된 value의 가중합이다. 동일한 query라도 **어느 메모리에서 key/value를 가져오는가**가 바뀌면 계산이 달라진다. 이는 기존 [Transformer 해설](/research/attention-is-all-you-need/)의 attention 정의와 연결된다.

이를 확인하는 작성자 예제로 모든 key를 0으로 두자. 가중치가 균등해지므로 value가 1, 3이면 출력은 2지만, 캐시를 비운 뒤 value 3만 남기면 출력은 3이다. 다른 입력과 hidden vector가 같아도 캐시가 다르면 attention 결과가 달라질 수 있다. 따라서 hidden vector만 같다는 이유로 다음 상태까지 같다고 증명할 수 없다.

### 1.3 Window boundaries without off-by-one errors

원문에서 SWA 창은 현재 토큰을 포함한 $$W$$개 위치다. 현재 시점의 접근 집합과 다음 시점을 위한 보존 집합을 나누면 다음처럼 계산된다.

$$
\mathcal J_t=\{\max(1,t-W+1),\ldots,t\},
\qquad
\mathcal C_t=\{\max(1,t-W+2),\ldots,t\}.
$$

예를 들어 $$W=3$$이면 다음과 같다. 각 decoder 층이 자신의 key/value로 같은 위치 규칙을 적용한다.

| Consumed position | Positions read now | History retained next |
|---|---|---|
| 1 | 1 | 1 |
| 2 | 1, 2 | 1, 2 |
| 3 | 1, 2, 3 | 2, 3 |
| 4 | 2, 3, 4 | 3, 4 |

$$W=1$$이면 보존 집합은 공집합이다. 그러나 $$s_t$$와 encoder 메모리까지 없어진다는 뜻은 아니다. “SWA 과거가 없다”와 “모델에 과거 정보가 전혀 없다”를 혼동하면 잘못된 ablation을 설계하게 된다. 원문 Section 2.5의 현재 key/value는 해당 층의 입력으로 먼저 만들어지므로, 현재 위치를 attention에 포함하는 것 자체가 순환 정의를 만들지는 않는다.

## 2. Feedback, Depth, and Causality

### 2.1 What the merge controls

원문 식 (2.9)–(2.11)의 gated merge는 다음과 같은 선택이다.

$$
r_{t-1}=\operatorname{RMSNorm}_s(s_{t-1}),\qquad
g_t=\sigma\!\left(W_g[e_t;r_{t-1}]+b_g\right),
$$

$$
u_t=e_t+\alpha g_t\odot W_sr_{t-1}.
$$

대괄호의 세미콜론은 두 벡터의 연결이고, $$\odot$$는 성분별 곱이다. $$W_g\in\mathbb R^{d\times2d}$$, $$W_s\in\mathbb R^{d\times d}$$이므로 gate와 feedback의 차원은 모두 $$d$$로 맞는다. $$b_g$$는 bias, $$\sigma$$는 sigmoid, $$\alpha$$는 feedback scale이다. 이 수식은 구조 선택이지 최적성 정리가 아니다.

해석을 위해 gate가 0에 가까우면 이전 출력의 직접 주입이 작아지고, 1에 가까우면 투영된 이전 출력이 더 많이 들어온다고 볼 수 있다. 다만 $$\alpha=0$$으로 직접 feedback을 꺼도 decoder SWA가 유지되면 과거 activation 경로는 남는다. “Token-only merge”라는 이름만으로 모든 시간 의존성이 제거되었다고 판단하지 말고 실제 제거한 연결을 확인해야 한다.

### 2.2 Deriving temporal depth

각 토큰 전이를 $$F_t$$로 쓰고, 한 전이가 $$L_D$$개 decoder block을 거친다고 하자. 첫 토큰에서 경로 길이는 $$L_D$$이고, 다음 토큰마다 같은 수의 block이 이어진다. 따라서 경로 길이 $$D_t$$는

$$
D_0=0,\qquad D_t=D_{t-1}+L_D,
\qquad D_t=tL_D
$$

가 된다. 마지막 등식은 재귀식을 반복 대입한 정확한 **경로 개수**다. 원문의 48+48 구성에서는 $$D_{10}=480$$이며, 토큰 하나의 encoder와 decoder 논리 block 수는 96이다. 이 숫자로 FLOPs나 지연시간을 직접 계산할 수는 없다. Cross-attention의 문맥 길이와 각 block의 내부 연산도 비용을 결정하기 때문이다.

더 긴 경로가 기억을 보장하지 않는 이유는 아래의 작성자 선형 예제로 확인할 수 있다.

$$
h_t=ah_{t-1}+u_t
\quad\Longrightarrow\quad
h_t=a^th_0+\sum_{j=1}^{t}a^{t-j}u_j.
$$

스칼라 $$a,h_t,u_t$$에 대한 정확한 등식이며, 유도는 $$h_{t-1}$$를 반복 대입하면 된다. 초기값에 대한 미분은 $$\partial h_t/\partial h_0=a^t$$다. $$a=0.5$$이면 10단계 뒤 영향은 $$1/1024$$로 줄고, $$a=1.1$$이면 약 2.594로 커진다. **구조적 깊이와 정보·gradient의 실제 전달은 별개**다. 실제 RLT의 전달량을 이 스칼라 값으로 예측하는 예제는 아니다.

### 2.3 Why a causal encoder is not sufficient by itself

Causal encoder는 $$e_t$$가 $$x_{1:t}$$에만 의존하게 한다. 그렇더라도 이른 decoder 위치가 전체 prompt의 encoder 메모리를 읽으면 미래 입력을 볼 수 있다. 앞 절의 균등 attention 예제를 다시 쓰면, 첫 위치에서 허용된 value가 1일 때 출력은 1이다. 아직 읽지 않은 둘째 위치의 value 9까지 허용하면 출력은 5로 바뀐다. Encoder 표현 각각이 causal이라는 사실만으로 이 누출이 사라지지 않는다.

인과성을 증명하려면 초기 상태에 미래 정보가 없고, $$H_{t-1}$$는 $$x_{1:t-1}$$만 사용하며, 다음 전이가 $$e_t$$·$$M_{\le t}$$·현재까지의 decoder KV만 사용한다는 조건이 함께 필요하다. 이 조건에서 $$H_t$$도 $$x_{1:t}$$에만 의존한다. 귀납법으로 모든 시점의 인과성이 성립한다. 이는 원문 Appendix B.1을 확인하는 논리이며, padding·다른 문서 경계의 mask까지 올바르게 구현되었다는 증거를 대신하지는 않는다.

## 3. Serving-Split Invariance and Its Limits

원문 Proposition 3.1의 비교 대상은 **같은 토큰열을 처리하는 두 실행 방식**이다. 토큰화·파라미터·초기값·위치 규칙·창 규칙을 고정하고, encoder가 수학적으로 같은 표현을 만들며 decoder가 결정적으로 실행된다고 가정한다.

두 실행의 상태를 $$H_t^{(A)}$$와 $$H_t^{(B)}$$라고 쓰면 증명은 다음 두 단계다.

$$
H_0^{(A)}=H_0^{(B)}.
$$

$$
H_{t-1}^{(A)}=H_{t-1}^{(B)}
\quad\Longrightarrow\quad
F_t(H_{t-1}^{(A)})=F_t(H_{t-1}^{(B)}).
$$

따라서 모든 위치에서 두 상태가 같고, 같은 readout에 넣은 다음 토큰 확률도 같다. Prompt의 끝이라고 지정한 위치가 전이식에 들어가지 않으므로 경계를 이동해도 결과는 변하지 않는다.

여기에는 중요한 조건이 있다. 긴 prompt를 encoder가 먼저 처리하더라도 decoder는 각 위치에서 해당 prefix만 읽어야 한다. 이전 토큰의 decoder 계산을 건너뛰거나 캐시를 초기화하면 동일한 $$F_t$$의 반복이라는 전제가 깨진다. 또한 이 정리는 실수 연산의 동치에 관한 것이며, 다른 GPU kernel의 부동소수점 결과가 bitwise 동일하다는 증명은 아니다.

저자의 별도 [prefill–decode kernel mismatch 보고서](https://raw.githubusercontent.com/yifanzhang-pro/Pretraining-RL-Science/master/Prefill_Decode_Kernel_Mismatch.pdf){:target="_blank" rel="noopener"}는 같은 가중치에서도 실행 경로·정밀도·sampling 변환에 따라 실제 분포가 달라질 수 있으며, 한 파라미터 값에서 forward 확률이 같아도 gradient가 같다는 결론은 따르지 않는다고 구분한다. 이는 RLT의 구조적 경계 불변성과 별도로 확인해야 할 실행 조건이다.

작성자가 권하는 검사는 동일한 토큰열을 여러 chunk 크기와 경계로 나눠 실행한 뒤, 출력 확률뿐 아니라 매 시점의 $$s_t$$와 각 층의 KV를 함께 비교하는 것이다. 확률만 비교하면 readout에 드러나지 않은 상태 차이가 뒤에서 커지는 버그를 놓칠 수 있다.

## 4. Loss Masking Is Not Gradient Masking

### 4.1 From likelihood to a masked objective

일반적인 autoregressive likelihood는 조건부 확률들의 곱이다. 로그를 취하면 합으로 바뀌고, 최대화를 최소화 문제로 쓰기 위해 음수를 붙인다. 특정 target만 학습하는 경우 binary mask $$m_{t+1}$$로 항을 선택할 수 있다.

$$
\mathcal L(\Theta)
=-\frac{1}{N_m}\sum_{t=1}^{S-1}m_{t+1}
\log p_\Theta(x_{t+1}\mid x_{1:t}),
\qquad N_m=\sum_{t=1}^{S-1}m_{t+1}>0.
$$

$$S$$는 sequence 길이, $$N_m$$은 선택한 target 수다. Pretraining에서는 유효한 다음 토큰 target을 선택하고, SFT에서는 assistant target을 선택한다. Target이 없는 예제를 분모 0으로 계산해서는 안 된다. 예제별 평균 후 batch 평균을 내는 방식과 전체 토큰 수로 한 번에 나누는 방식도 서로 다른 가중치를 준다.

이 손실에서 $$m_{t+1}=0$$은 그 시점의 **직접 손실 항**을 없앨 뿐이다. 이후 예측에 필요한 상태 계산까지 생략해도 된다는 뜻은 아니다.

### 4.2 A complete numerical counterexample

다음은 원문 모델을 축소 구현한 것이 아니라 chain rule을 설명하는 작성자 예제다. Prompt 상태가 $$h=\theta$$이고 response 점수가 $$z=\theta h$$이며, response 손실만 $$\ell=z^2/2$$라고 하자. 정확한 계산은

$$
z=\theta^2,\qquad \ell=\frac{1}{2}\theta^4,
\qquad \frac{d\ell}{d\theta}=2\theta^3.
$$

반면 prompt 상태에 `stopgrad`를 적용하면 forward 값은 같지만 미분 중에는 $$h$$가 상수로 취급된다.

$$
\frac{d\ell_{\mathrm{detached}}}{d\theta}
=\frac{\partial\ell}{\partial z}\frac{\partial z}{\partial\theta}
=z h=\theta^3.
$$

$$\theta=2$$에서 양쪽 손실은 8로 같지만 gradient는 각각 16과 8이다. **Forward 일치만으로 학습 일치를 검증할 수 없다.** Prompt에 직접 손실을 주지 않아도 response loss가 prompt 계산을 거쳐 파라미터를 바꾸는 경로가 존재한다.

### 4.3 Full-state Jacobians

캐시를 고정된 slot과 유효성 mask로 나타내고 encoder 입력을 고정한 부분미분을 생각하자. Decoder 상태의 Jacobian은 일반적으로 다음 block 구조를 갖는다.

$$
J_t=\frac{\partial H_t}{\partial H_{t-1}}
=\begin{pmatrix}
\dfrac{\partial s_t}{\partial s_{t-1}} & \dfrac{\partial s_t}{\partial C_{t-1}^D} \\
\dfrac{\partial C_t^D}{\partial s_{t-1}} & \dfrac{\partial C_t^D}{\partial C_{t-1}^D}
\end{pmatrix}.
$$

Chain rule을 두 시점에 먼저 적용하면 $$\partial H_t/\partial H_{t-2}=J_tJ_{t-1}$$이고, 반복하면 $$\partial H_t/\partial H_j=J_tJ_{t-1}\cdots J_{j+1}$$이다. Hidden vector 블록만 곱하면 캐시를 경유하는 경로를 빠뜨린다. 이것은 원문 Appendix B의 상태 미분이며, 전체 파라미터 미분에는 encoder 표현과 메모리의 파라미터 의존성도 추가해야 한다.

Checkpointing은 필요한 forward를 같은 조건으로 재계산하는 메모리 절약 방법이다. Detach는 미분 연결을 끊는 방법이다. 두 방법 모두 메모리를 줄일 수 있지만 같은 gradient를 계산하는지는 다르다. SWA의 오래된 KV 삭제도 이미 그 값을 읽은 연산의 gradient까지 자동 삭제한다는 뜻은 아니다.

## 5. Policy Replay and Importance Sampling

### 5.1 Why current parameters require current states

여기서 replay는 저장한 토큰열을 현재 파라미터로 다시 처리해 확률을 구하는 작업이다. 상태가 $$h=f_\theta(x_{1:t})$$라면 가중치를 바꾼 뒤 필요한 상태는 $$f_{\theta_{\mathrm{new}}}(x_{1:t})$$다. 오래된 상태를 사용하면 일반적으로

$$
g_{\theta_{\mathrm{new}}}\!\left(f_{\theta_{\mathrm{old}}}(x_{1:t})\right)
\ne
g_{\theta_{\mathrm{new}}}\!\left(f_{\theta_{\mathrm{new}}}(x_{1:t})\right).
$$

작성자 예제로 $$f_\theta(x)=\theta x$$, $$g_\theta(h)=\theta h$$, $$x=1$$을 사용하자. 가중치를 1에서 2로 바꾸면 새 계산의 점수는 4지만 이전 상태를 재사용하면 2다. 따라서 현재 출력층에 현재 가중치를 썼다는 사실만으로 현재 정책의 확률이 되는 것은 아니다.

RLT에서 확인할 대상은 encoder cache, encoder-derived memory, recurrent output, decoder SWA KV 전체다. 다만 토큰열과 실제 sampling 당시 기록한 behavior log-probability는 관측 기록이므로 새 가중치로 덮어쓰면 안 된다. 보고서 Section 5.3–5.4 및 Appendices A.4, C가 이 구분을 다룬다.

### 5.2 Deriving the policy gradient

다음은 이산 출력에 대한 일반적인 score-function 유도다. Prompt $$c$$를 고정하고, 미분과 합을 교환할 수 있으며 reward $$R(c,y)$$가 파라미터에 직접 의존하지 않는다고 하자.

$$
J(\Theta)=\sum_y\pi_\Theta(y\mid c)R(c,y).
$$

양의 확률에서 $$\nabla_\Theta\pi_\Theta=\pi_\Theta\nabla_\Theta\log\pi_\Theta$$이므로

$$
\nabla_\Theta J
=\mathbb E_{y\sim\pi_\Theta}
\left[R(c,y)\nabla_\Theta\log\pi_\Theta(y\mid c)\right].
$$

또한 $$\pi_\Theta(y\mid c)=\prod_i p_\Theta(y_i\mid c,y_{<i})$$이므로 log-policy gradient는 토큰별 log-probability gradient의 합이다. Response와 무관한 baseline $$b(c)$$를 빼도 기대값은 변하지 않는다. 그 이유는

$$
\sum_y\pi_\Theta(y\mid c)b(c)\nabla_\Theta\log\pi_\Theta(y\mid c)
=b(c)\nabla_\Theta\sum_y\pi_\Theta(y\mid c)=0
$$

이기 때문이다. Baseline은 이 policy-gradient 항에서 상수로 취급한다. Reward나 sampling의 미분 가능성에 대한 전제를 바꾸면 같은 식을 그대로 적용할 수 없다.

### 5.3 Why a correct denominator is still not enough

과거 sampling 분포를 $$\mu$$라고 하면, 현재 확률과 당시 확률의 비는

$$
r_i=\frac{p_\Theta(y_i\mid c,y_{<i})}{\mu(y_i\mid c,y_{<i})}
=\exp\!\left(\log p_\Theta(y_i\mid c,y_{<i})-\log\mu(y_i\mid c,y_{<i})\right)
$$

이다. 정확한 trajectory importance sampling에서는 전체 sequence의 비인 $$\prod_i r_i$$가 등장한다. 성립하려면 target이 양의 확률을 주는 결과를 behavior도 생성할 수 있어야 하고 기대값이 잘 정의되어야 한다.

작성자 반례로 target이 두 행동 A, B에 각각 0.6, 0.4를 주지만 top-1 sampler가 A만 선택한다고 하자. Reward가 A에서 0, B에서 1이면 target 기대 reward는 0.4다. 그러나 관측 sample은 모두 A이므로 어떤 유한 가중치를 곱해도 reward는 0이다. **관측되지 않을 결과의 기여는 log-probability 기록만으로 복구할 수 없다.**

Temperature만 바꾸고 양의 support를 유지하는 경우와 top-k/top-p로 일부 확률을 0으로 만드는 경우를 구분해야 한다. Clipped token ratio를 사용하는 학습 목표 역시 정확한 trajectory importance sampling과 동일하다고 단정할 수 없다. RLT의 구조가 이런 추정 문제를 자동 해결한다는 해석은 성립하지 않는다.

## 6. Hardware and Conversation State

### 6.1 Parallel work does not remove a dependency chain

$$H_{t+1}=F_{t+1}(H_t)$$가 일반적인 비선형 함수이면 다음 토큰의 결과는 이전 결과를 기다린다. 독립된 sequence A와 B의 다음 연산을 한 batch에 넣는 것은 가능하지만, A의 서로 의존하는 두 연산을 동시에 끝낼 수 있다는 뜻은 아니다.

일반적인 dense attention에서 시점 $$t$$가 $$t$$개 key를 읽고 key 폭이 $$d_k$$이면 score 계산량은 대략 $$O(td_k)$$다. 이를 길이 $$T$$에 대해 더하면

$$
\sum_{t=1}^{T}O(td_k)=O(T^2d_k).
$$

반면 고정 창 $$W$$만 읽는 local attention 항은 $$O(T\min(W,T)d_k)$$로 계산할 수 있다. 이는 attention score 부분의 큰 차수 분석이며 projection·FFN·통신 비용을 모두 포함한 실행시간 공식은 아니다. Local cache가 bounded라고 해서 전역 encoder 메모리까지 상수 공간이 되는 것은 아니다.

원문 식 (3.3)은 이 구분을 추론 cache 저장량에도 적용한다. 유효 KV 폭을 $$d_{\mathrm{KV}}$$, decoder KV 폭을 $$d_{\mathrm{KV}}^D$$, encoder-memory group 수를 $$G$$라고 하면 시점 $$t$$의 저장량은 대략 다음과 같다.

$$
O\!\left((L_E+G)t d_{\mathrm{KV}}+L_D\min(t,W-1)d_{\mathrm{KV}}^D+d\right).
$$

첫 항은 encoder cache와 전역 메모리 때문에 길이에 따라 증가하고, 둘째 항만 decoder SWA의 **보존된 과거**를 뜻한다. 현재 위치의 일시적인 KV는 그 둘째 항에 세지 않는다. 마지막 $$O(d)$$는 순환 출력이다. 따라서 decoder 창을 고정해도 **전체 추론 상태가 상수 공간이 되는 것은 아니다.** 이것은 저장량의 차수식이지 실제 GPU 메모리 사용량이나 속도 측정치는 아니다. 원문 식 (3.2)의 prefill 연산량 추정도 순차 decoder 경로를 없애지는 않는다.

RLT의 weight tying은 저장 파라미터 수와 반복 계산량을 구분해서 해석해야 한다. 동일한 행렬을 두 번 곱하면 행렬 저장은 한 번이어도 곱셈은 두 번이다. 따라서 속도 검증에는 같은 파라미터 수뿐 아니라 sequence 길이, batch 크기, precision, FLOPs, 지연시간과 메모리 측정이 필요하다.

### 6.2 Cache validity as a reproducibility contract

Conversation에서 user·tool 입력은 모델이 샘플한 action이 아니어도 다음 예측에 영향을 주는 입력이다. 이를 건너뛰고 assistant token만 상태에 반영하면 텍스트 기록과 실제 계산 문맥이 달라진다. 반대로 외부 입력에 모델 행동의 importance ratio를 부여해서도 안 된다.

구현 검토에서는 “이 cache가 어느 가중치·토큰 prefix·위치·창 규칙을 나타내는가”를 함께 기록하는 편이 유용하다. Prefix 일부를 수정하거나 삭제하면 마지막 상태가 삭제된 내용을 여전히 포함할 수 있으므로, 수정 지점 이전의 유효한 상태에서 다시 계산해야 한다. Text-only 대화 기록은 hidden state 자체가 아니라 재계산 입력이다.

또 하나의 경계는 마지막 출력 토큰이다. 사용자에게 출력했지만 아직 상태 전이에 반영하지 않은 token이 있다면 `emitted`와 `consumed`를 구분해야 한다. 재개 때 이를 두 번 소비하거나 건너뛰는 오류는 단순 cache 최적화 문제가 아니라 조건부 모델의 입력열을 바꾼다. 이 사례는 원문 Appendix A.2의 pending-token 규칙과 대응한다.

## 7. Preliminary Results and What They Establish

**19쪽 보고서와 현재 README를 같은 증거로 합치지 않는다.** 보고서는 측정된 효율·scaling 결과를 제시하지 않는다. 별도의 [README experiment section](https://github.com/yifanzhang-pro/recurrent-looped-tranformer#preliminary-synthetic-experiments){:target="_blank" rel="noopener"}과 [원본 결과 그림](https://raw.githubusercontent.com/yifanzhang-pro/recurrent-looped-tranformer/master/assets/rlt-state-tracking-results.png){:target="_blank" rel="noopener"}에는 약 79K 파라미터, 3 seeds, 학습 길이 32 operations의 synthetic state-tracking 실험이 있다. 과제·길이별 test program 수는 2,048이며 parameter/data budget은 맞췄지만 FLOPs는 맞추지 않았다.

| Task | RLT at 32 operations | RLT at 128 operations | Stated chance level |
|---|---|---|---|
| Parity | Approximately 100% | 60.8% | 50% |
| Five-state transitions | Approximately 100% | 20.7% | 20% |

32-operation 값은 그림의 근사 판독치이고 128-operation 값은 그림에 표시된 수치다. 원문의 whisker는 seed 최솟값·최댓값이며 신뢰구간이 아니다. 128-operation 비교군에서 Transformer는 각각 약 48%, 약 21%로 제시되지만, **GRU는 parity 100%, five-state 99.97%**로 표시된다. 즉 이 그림은 RLT의 두 과제 학습 길이 적합을 보여 주지만, 긴 길이에서 RLT가 모든 비교군보다 우수하다는 근거는 아니다. 이 글에서 실험을 재실행한 결과는 아니다.

작성자 해석은 다음과 같다. Parity의 60.8%는 기재된 chance보다 10.8 percentage points 높지만, five-state의 20.7%는 0.7 points 차이다. 특히 같은 그림의 GRU는 이 두 합성 과제에서 128 operations까지 거의 완전한 정확도를 유지한다. 이를 보고 RLT가 두 과제에서 안정적인 4배 길이 일반화를 달성했다거나, 이 실험의 GRU 기준선을 앞섰다고 요약해서는 안 된다. 개별 seed 결과와 불확실성 분석 없이 작은 차이의 통계적 유의성을 확정할 수도 없다. 대규모 언어 reasoning, RL scaling, wall-clock 향상으로 결론을 확장하려면 각각의 추가 실험이 필요하다.

## 8. Interpretation and Next Tests

관련 연구를 읽을 때는 이름에 recurrent 또는 looped가 있는지만 보지 말고, **feedback 위치, 상태 종류, 한 번에 처리하는 단위, gradient 연결 범위**를 비교하는 것이 좋다. 보고서 Section 7은 이 계열의 문헌을 연결한다. 본문은 그 모든 선행연구의 성능 주장을 독립 검증하는 survey는 아니다.

다음은 보고된 성과가 아니라 작성자의 후속 검증 제안이다.

| Question | Test | What it would clarify |
|---|---|---|
| 직접 feedback이 기여하는가? | 다른 경로를 고정하고 merge feedback만 제거 | 직접 순환 경로의 기여 |
| SWA와 전역 메모리는 어떤 역할인가? | 창 크기·메모리 조건을 한 축씩 변화 | 상태 용량과 접근 범위의 효과 |
| 길이 일반화가 견고한가? | 길이별 정확도, seed별 결과와 불확실성 공개 | 긴 sequence에서의 성능 감소 |
| 학습 gradient가 보존되는가? | 작은 모델에서 full replay와 checkpointed replay의 gradient 비교 | Forward-only 검사로 놓치는 차이 |
| 실제로 효율적인가? | 계산 예산과 하드웨어 조건을 맞춘 지연시간·처리량 측정 | Parameter tying과 속도의 차이 |
| RL replay가 정확한가? | 가중치 갱신 전후 상태 재계산·support·sampling 확률 점검 | 상태 오류와 추정 오차의 분리 |

이런 검증을 통해 구조의 장점을 실제 성과로 연결할 수 있다. 현재 공개 자료만으로 “기존 Transformer를 대체했다”거나 “무한 기억을 구현했다”고 표현할 근거는 없다.

## Source Check

| Item | Finding | Treatment |
|---|---|---|
| Infinite depth | 시간 경로의 구조적 개수 | 기억·정확도·속도 보장과 분리 |
| Complete state | Hidden output 외에 decoder KV도 포함 | Attention 반례와 block Jacobian으로 확인 |
| SFT prompt masking | 손실 선택과 계산 경로가 다름 | 동일 forward·상이한 gradient 예제 추가 |
| RL replay | 값 재계산과 gradient 보존이 별개 | Stale-state 예제와 support 반례 추가 |
| Results | 보고서와 README의 실험 범위가 다르고 그림의 GRU 기준선이 강함 | 출처를 분리하고 128-operation GRU 100%/99.97%를 명시 |
| Verification scope | 원본 19쪽 PDF 전 페이지와 README 결과 그림을 시각 대조 | 수식·그림·결론의 출처를 확인했으나 실험 재현이나 독립 벤치마크는 수행하지 않음 |

## Key Takeaways

- **State:** hidden vector뿐 아니라 예측이 의존하는 cache·메모리·위치까지 확인한다.
- **Depth:** 경로 길이, gradient 전달, reasoning 성능은 구분해서 검증한다.
- **Training:** 손실 mask는 상태 갱신이나 gradient 경로를 자동으로 제거하지 않는다.
- **Replay:** 현재 정책은 현재 파라미터의 상태로 계산하되, behavior 확률은 실제 sampling 기록을 유지한다.
- **Evidence:** 합성 과제의 proof of concept를 대규모 reasoning·RL·하드웨어 성능의 증거로 확대하지 않는다.

## References

아래 기술보고서와 공식 실험 자료에서 구조·수식·결과를 함께 확인할 수 있다.

- Yifan Zhang. [Recurrent Looped Transformer — project overview](https://yifanzhang-pro.github.io/recurrent-looped-tranformer/){:target="_blank" rel="noopener"}, September 12, 2026.
- Yifan Zhang. [Recurrent Looped Transformer — technical report, 19 pages]({{ "/assets/pdfs/research/rlt-recurrent-looped-transformer/rlt-recurrent-looped-transformer.pdf" | relative_url }}){:target="_blank" rel="noopener"}. Architecture: Sections 2–3; training and serving: Sections 5–6; execution and gradients: Appendices A–C.
- [Official README and preliminary synthetic experiments](https://github.com/yifanzhang-pro/recurrent-looped-tranformer#preliminary-synthetic-experiments){:target="_blank" rel="noopener"}, accessed September 14, 2026.
- [Official synthetic-results figure](https://raw.githubusercontent.com/yifanzhang-pro/recurrent-looped-tranformer/master/assets/rlt-state-tracking-results.png){:target="_blank" rel="noopener"}, accessed September 14, 2026.
- [Related prefill–decode kernel mismatch report](https://raw.githubusercontent.com/yifanzhang-pro/Pretraining-RL-Science/master/Prefill_Decode_Kernel_Mismatch.pdf){:target="_blank" rel="noopener"}, cited for execution and gradient-parity limits.
- Unmodified report by Yifan Zhang, redistributed under [Apache-2.0]({{ "/assets/pdfs/research/rlt-recurrent-looped-transformer/LICENSE.txt" | relative_url }}). [Repository license](https://github.com/yifanzhang-pro/recurrent-looped-tranformer/blob/master/LICENSE){:target="_blank" rel="noopener"}.
