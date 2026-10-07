---
layout: default
date: 2026-10-07 10:49:37 +0900
title: "Speech and Audio Recognition Lecture 5: Self-Supervised Learning"
course: "Speech and Audio Recognition"
topic: "Self-Supervised Speech Representation Learning"
order: 6
major_topic: "Speech and Audio Processing"
keywords:
  - "Self-Supervised Learning"
  - "Weak Supervision"
  - "wav2vec 2.0"
  - "Contrastive Learning"
  - "Product Quantization"
  - "Gumbel Softmax"
  - "HuBERT"
  - "Masked Prediction"
  - "XLS-R"
  - "Conformer"
  - "CTC Fine-Tuning"
---

# Speech and Audio Recognition Lecture 5: Self-Supervised Learning

Source PDF: <a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">SpeechAudio_Lecture5.pdf</a> — Inkyu An, Kookmin University (49 slides).

[Lecture 4: Automatic Speech Recognition II](/study/speech-and-audio-recognition/lecture-04-attention-and-rnn-transducer/)에서는 labeled transcript로 CTC, LAS, RNN-T를 학습하는 방법을 다뤘다. 이번 강의는 그보다 앞 단계로 돌아가, transcript가 없는 대규모 음성에서 먼저 유용한 표현을 배우고 적은 labeled speech로 ASR에 적응시키는 방법을 설명한다.

> **핵심:** Self-supervised learning은 입력 자체에서 예측 target을 만들어 representation을 학습한다. wav2vec 2.0은 가린 latent position의 **정답 quantized vector를 distractor와 구별**하고, HuBERT는 offline clustering으로 만든 **hidden-unit label을 문맥에서 예측**한다. 둘 다 이후 CTC 등으로 fine-tuning할 수 있지만 target 생성 방식, collapse 방지 장치, layer별 정보의 변화는 서로 다르다.

아래 페이지 번호는 PDF의 물리적 쪽 번호다. 수식 유도와 수치 예시는 **작성자 보충 설명**이다. 슬라이드의 축약 표현 가운데 조건이 빠졌거나 일반화하기 어려운 부분은 본문과 마지막 `Source Check`에서 원 논문에 맞춰 구분했다.

## 전체 흐름

| 강의 위치 | 주제 | 이해할 질문 |
|---|---|---|
| pp. 1–2 | 강의 개요 | 왜 labeled ASR 전에 representation learning을 하는가? |
| pp. 3–11 | Learning paradigms | Supervised, unsupervised, semi-supervised, weakly supervised는 supervision을 어디서 얻는가? |
| p. 12 | 대규모 weak supervision | MMS와 Whisper의 데이터·학습 방식은 SSL과 어떻게 다른가? |
| pp. 13–18 | Self-supervised learning | 입력 일부를 target으로 삼는다는 뜻과 장점의 조건은 무엇인가? |
| pp. 19–20 | Speech SSL의 과제 | 연속 waveform에서 예측할 vocabulary와 시간 단위를 어떻게 만드는가? |
| pp. 21–32 | wav2vec 2.0 pre-training | CNN, masking, Transformer, product quantization, contrastive·diversity loss가 어떻게 연결되는가? |
| pp. 33–39 | Fine-tuning과 확장 | CTC, XLS-R, layer analysis, Conformer 계열 결과를 어떤 조건과 함께 읽어야 하는가? |
| pp. 40–43 | Attention과 순서 정보 | Self-attention이 순서에 둔감한 이유와 positional information이 필요한 이유는 무엇인가? |
| pp. 44–49 | HuBERT | Offline cluster target과 반복 refinement가 wav2vec 2.0의 online codebook과 어떻게 다른가? |

### 기호와 단위

| 기호 | 의미 | 단위·성격 |
|---|---|---|
| $$x, x_n$$ | raw waveform과 sample | 보통 정규화된 amplitude; 물리 단위를 임의로 부여하지 않음 |
| $$f_s$$ | sampling rate | samples/s 또는 Hz |
| $$z_t$$ | CNN feature encoder의 연속 latent vector | 학습된 무차원 벡터 |
| $$c_t$$ | Transformer가 만든 contextualized vector | 학습된 무차원 벡터 |
| $$q_t$$ | $$z_t$$에서 선택한 quantized target vector | 여러 codebook entry의 결합 |
| $$T,t$$ | latent sequence 길이와 position | 무차원 정수; sample index와 구분 |
| $$G,V$$ | codebook 수와 codebook당 entry 수 | 무차원 정수 |
| $$K$$ | contrastive distractor 수 | 무차원 정수; 후보 전체는 $$K+1$$개 |
| $$\kappa,\tau$$ | contrastive temperature와 Gumbel-softmax temperature | 양의 무차원 값 |
| $$M$$ | 가린 position의 index 집합 | 집합 |
| $$y_t$$ | HuBERT clustering이 만든 hidden-unit class | 이산 pseudo-label |
| $$\mathcal L_m,\mathcal L_d$$ | masked contrastive loss와 diversity loss | 자연로그이면 nats; 물리 단위 없음 |

## 1. Learning paradigm은 label의 출처로 구분한다

### 1.1 Supervised learning

Supervised learning은 입력 $$x_i$$와 사람이 정하거나 검수한 target $$y_i$$의 쌍으로 mapping을 학습한다(pp. 3–5). 분류 예시에서는 class boundary를 찾고, ASR에서는 음성과 transcript를 연결한다.

$$
\mathcal D_{\mathrm{sup}}=\{(x_i,y_i)\}_{i=1}^{N},\qquad
\min_{\theta}\sum_i \ell(f_{\theta}(x_i),y_i)
$$

장점은 downstream 목적과 target이 직접 일치한다는 점이다. 비용은 label 제작이다. 음성 transcript는 언어 지식, 긴 청취 시간, 표기 규칙이 필요하고 저자원 언어에는 충분한 labeled corpus가 없을 수 있다.

### 1.2 Unsupervised learning

Unsupervised learning은 외부 label 없이 입력의 구조를 찾는다(pp. 6–8). Clustering, density estimation, dimensionality reduction이 대표적이다. 그림의 회색 점을 여러 집단으로 묶는 일은 가능하지만, 각 cluster가 실제로 어떤 의미인지 또는 downstream class와 일치하는지는 별도 해석이 필요하다.

Self-supervised learning도 사람이 붙인 label 없이 학습하므로 넓은 분류에서는 unsupervised representation learning에 포함될 수 있다. 다만 **입력에서 자동으로 target을 구성해 명시적 예측 loss를 만든다**는 학습 설계가 강조된다.

### 1.3 Semi-supervised learning

Semi-supervised learning은 적은 labeled data와 많은 unlabeled data를 함께 사용한다(pp. 9–10).

$$
\mathcal D=\mathcal D_L\cup\mathcal D_U,\qquad
\mathcal D_L=\{(x_i,y_i)\},\quad \mathcal D_U=\{x_j\}
$$

Pseudo-labeling, consistency regularization, noisy student처럼 unlabeled example을 supervised model 개선에 직접 넣는 방법이 있다. SSL pre-training 뒤 labeled data로 fine-tuning하는 pipeline도 최종 시스템 전체를 보면 labeled와 unlabeled data를 모두 활용하지만, **pre-training objective 자체**는 self-supervised다. 한 모델을 어느 한 단어로만 부르기보다 어느 stage의 supervision을 말하는지 명시해야 한다.

### 1.4 Weak supervision

Weak supervision은 label이 있으나 사람의 정밀 annotation보다 noisy, coarse, indirect하거나 자동 수집된 경우를 뜻한다(pp. 10–12). 이미지의 hashtag는 객체 위치·정확한 class를 보장하지 않지만 이미지와 함께 수집된다. 인터넷의 audio–caption pair도 transcript가 부정확하거나 음성과 완전히 정렬되지 않을 수 있다.

Whisper는 웹에서 모은 680,000시간의 multilingual·multitask audio–text pair로 대응 text를 예측한다. 따라서 입력만으로 target을 만드는 wav2vec 2.0식 SSL과 달리 **외부 text supervision을 사용하는 weakly supervised 학습**이다. MMS는 종교 문서와 읽기 음성을 정렬해 labeled ASR 데이터를 만들면서 wav2vec 2.0 self-supervised pre-training도 활용한다. MMS 전체를 한 종류의 supervision으로만 묶는 설명은 정확하지 않다.

## 2. Self-supervision은 입력을 문제와 정답으로 나눈다

### 2.1 Masked prediction의 공통 원리

슬라이드 pp. 13–16의 이미지 patch와 문장 token 예시는 원본 입력 $$x$$에서 일부를 가린 $$\tilde{x}$$를 만들고, 가린 부분 $$y$$를 target으로 삼는 과정을 보여 준다.

$$
\tilde{x}=\operatorname{corrupt}(x,M),\qquad
y=\operatorname{target}(x,M)
$$

$$
\min_{\theta}\;\ell\bigl(f_{\theta}(\tilde{x}),y\bigr)
$$

사람이 새 label을 붙이지 않아도 원본에서 target을 얻는다. 그러나 target이 “공짜”라는 말은 계산·저장·수집·정제 비용이 없다는 뜻이 아니다. Corruption 규칙과 target 표현을 잘못 고르면 모델은 의미보다 쉬운 복원 shortcut을 배울 수 있다.

### 2.2 왜 downstream에 도움이 될 수 있는가

슬라이드 p. 17은 빠른 수렴, 더 나은 수렴, low-resource, large-scale model, foundation model을 장점으로 제시한다. 이를 보장으로 읽어서는 안 된다. 효과가 나타나려면 다음 조건이 맞아야 한다.

- Pre-training data가 downstream 음성의 언어·도메인·channel과 충분히 관련되어야 한다.
- Pretext objective가 phonetic, lexical, speaker, prosody 등 downstream에 필요한 정보를 보존해야 한다.
- Model capacity와 optimization이 데이터 규모를 감당해야 한다.
- Fine-tuning data, decoder, external LM, evaluation split을 같은 조건으로 비교해야 한다.

좋은 초기 representation은 적은 label에서도 성능과 optimization을 개선할 수 있지만, domain mismatch나 부적절한 objective에서는 negative transfer가 생길 수 있다. `foundation model`도 폭넓은 adaptation 가능성을 가리키는 용어이지 모든 task에서 최적이라는 증명이 아니다.

### 2.3 Text와 speech의 target 차이

Text에는 tokenizer가 정의한 discrete vocabulary가 이미 있다(p. 18). Speech waveform은 연속값이며, 16 kHz mono 신호라면 1초에 16,000 samples가 있다는 뜻일 뿐 **항상 16,000 floats인 것은 아니다**(p. 19). 저장 dtype이 int16일 수도 있고 sampling rate가 8, 44.1, 48 kHz일 수도 있다.

$$
N_{\mathrm{samples}}=f_s\times \Delta t
$$

Speech SSL은 따라서 두 문제를 함께 해결해야 한다.

1. 매우 긴 sample sequence를 계산 가능한 latent sequence로 줄인다.
2. “맞혀야 할 단위”를 continuous vector, quantized code, cluster ID 등으로 정의한다.

pp. 20의 연대표는 generative, contrastive, predictive 계열이 공존함을 보여 준다. 이 구분은 절대적이지 않다. 예를 들어 wav2vec 2.0은 quantized target에 대한 contrastive classification을 하고, HuBERT는 cluster class의 masked prediction을 한다.

## 3. wav2vec 2.0의 전체 구조

### 3.1 Raw waveform → CNN latent sequence

Feature encoder $$f$$는 raw waveform $$x$$를 latent sequence로 바꾼다(pp. 21–22).

$$
z_1,\ldots,z_T=f(x)
$$

원 논문의 일곱 convolution stride는 $$(5,2,2,2,2,2,2)$$이므로 총 stride는 다음과 같다.

$$
5\times2^6=320\ \mathrm{samples}
$$

16 kHz라면 latent step 간격은 $$320/16000=0.02$$ s, 즉 약 20 ms다. 길이 1초가 정확히 50개 latent가 된다는 뜻은 padding과 boundary convention에 따라 달라진다. 원 논문은 output frequency를 약 49 Hz로 보고한다.

Kernel width $$(10,3,3,3,3,2,2)$$와 stride를 순서대로 적용하면 한 latent의 receptive field는 400 samples다. $$r_0=1,j_0=1$$에서

$$
r_i=r_{i-1}+(k_i-1)j_{i-1},\qquad j_i=j_{i-1}s_i
$$

를 적용하면 마지막에 $$r=400,j=320$$이다. 16 kHz에서 receptive field는 25 ms, step은 20 ms라 인접 latent의 입력 구간이 겹친다.

### 3.2 Masking은 CNN 뒤, Transformer 앞에서 한다

Mask index에는 학습 가능한 mask embedding $$m$$을 넣고 나머지 $$z_t$$는 유지한다(p. 23).

$$
\tilde z_t=
\begin{cases}
m,&t\in M\\
z_t,&t\notin M
\end{cases}
$$

Transformer context network $$g$$가 주변의 unmasked latent를 이용해 contextualized representation을 만든다(p. 24).

$$
c_1,\ldots,c_T=g(\tilde z_1,\ldots,\tilde z_T)
$$

중요한 비대칭이 있다. **Transformer 입력 branch는 masked $$\tilde z$$를 보지만 quantizer branch는 원래 $$z$$를 본다.** 따라서 가린 위치의 target $$q_t$$는 손상되지 않은 latent에서 만들어진다. Target branch까지 mask하면 무엇을 맞혀야 하는지가 사라진다.

### 3.3 Transformer에는 순서 정보가 따로 필요하다

pp. 40–43은 일반 attention에서 self-attention까지의 변환을 복습한다. 입력 $$X$$에서

$$
Q=XW_Q,\qquad K=XW_K,\qquad V=XW_V
$$

$$
\operatorname{Attention}(Q,K,V)=\operatorname{softmax}\left(\frac{QK^{\top}}{\sqrt{d_k}}\right)V
$$

를 계산한다. Positional signal이 없다면 입력 순서를 같은 permutation으로 바꿀 때 출력도 그 순서를 따라 바뀌는 permutation-equivariant 연산이어서 “첫 번째 음소와 마지막 음소”의 절대·상대 위치를 자체로 알 수 없다. wav2vec 2.0은 fixed absolute position table 대신 convolutional positional embedding을 latent에 더한다. **Attention이 순서를 완전히 무시한다**기보다, 내용 기반 attention만으로는 위치를 식별할 근거가 부족하므로 position mechanism이 필요하다고 표현하는 편이 정확하다.

## 4. Product quantization은 speech vocabulary를 학습한다

### 4.1 여러 codebook에서 하나씩 선택한다

Quantization module은 $$z_t$$를 $$G$$개 codebook에 대한 logits로 바꾸고 각 codebook의 $$V$$개 entry 중 하나를 선택한다(pp. 25–28). 선택한 vector를 이어 붙인 뒤 projection하여 $$q_t$$를 얻는다.

$$
q_t=W_q[e_{1,v_1};e_{2,v_2};\ldots;e_{G,v_G}]
$$

가능한 조합의 이론적 최대 수는 $$G\times V$$가 아니라

$$
V^G
$$

이다. 원 설정의 $$G=2,V=320$$이면 $$320^2=102{,}400$$개 조합이다. 이는 가능한 조합 수이며 실제 학습에서 모두 같은 빈도로 등장하거나 서로 다른 음소 하나씩에 대응한다는 뜻은 아니다.

### 4.2 Gumbel-softmax로 discrete 선택을 학습한다

Codebook $$g$$의 entry $$v$$에 대한 logit을 $$l_{g,v}$$라 하자. Uniform sample $$u_{g,v}\sim\mathcal U(0,1)$$에서 Gumbel noise를 만든다.

$$
n_{g,v}=-\log(-\log u_{g,v})
$$

$$
p_{g,v}=\frac{\exp((l_{g,v}+n_{g,v})/\tau)}{\sum_{j=1}^{V}\exp((l_{g,j}+n_{g,j})/\tau)}
$$

Forward에서는 argmax entry를 고르는 hard choice를 사용하고 backward에서는 soft probability의 gradient를 사용하는 straight-through estimator를 쓴다. $$\tau$$가 크면 분포가 부드럽고, 작아지면 선택이 날카로워진다. $$\tau\to0$$은 수치적으로 민감하므로 원 설정도 양의 최솟값까지만 annealing한다.

## 5. Contrastive objective를 단계별로 계산하기

### 5.1 Positive와 distractor

가린 position $$t$$에서 positive는 같은 position의 quantized target $$q_t$$다. 원 논문은 다른 **masked positions of the same utterance**에서 $$K$$개 distractor를 균등 표본한다(pp. 29–32). 후보 집합은 $$Q_t$$이고 크기는 $$K+1$$이다.

Cosine similarity는 두 벡터가 0이 아닐 때 다음과 같다.

$$
\operatorname{sim}(a,b)=\frac{a^{\top}b}{\lVert a\rVert_2\lVert b\rVert_2}
$$

Masked position 하나의 contrastive loss는 positive를 정답 class로 둔 cross-entropy다.

$$
\mathcal L_m(t)=-\log
\frac{\exp\left(\operatorname{sim}(c_t,q_t)/\kappa\right)}
{\sum_{\tilde q\in Q_t}\exp\left(\operatorname{sim}(c_t,\tilde q)/\kappa\right)}
$$

$$\kappa$$가 작으면 similarity 차이를 더 크게 확대한다. Negative가 쉬우면 loss가 작지만 representation 학습 신호도 약해질 수 있고, false negative가 실제로 같은 음성 단위를 담으면 불필요하게 둘을 밀어낼 수 있다. Same-utterance sampling은 speaker·channel shortcut을 줄이는 데 도움을 주지만 false negative 가능성을 없애지는 않는다.

### 5.2 작성자 수치 예시

Positive similarity가 0.8, 두 distractor similarity가 0.3과 0.1, $$\kappa=0.1$$이라고 하자. 분자·분모에서 $$\exp(8)$$을 나누면 overflow 없이 계산할 수 있다.

$$
\mathcal L_m
=-\log\frac{1}{1+\exp(-5)+\exp(-7)}
=\log\left(1+\exp(-5)+\exp(-7)\right)
\approx0.0076207
$$

Positive가 가장 크고 temperature가 작아 정답 확률이 1에 가깝기 때문에 loss가 작다. 이 값은 설명용이며 슬라이드의 실험 수치가 아니다.

### 5.3 Diversity loss와 부호

Contrastive loss만 최적화하면 일부 codebook entry만 쓰는 collapse가 생길 수 있다. Batch에서 Gumbel noise와 temperature를 제외한 softmax probability를 평균해 $$\bar p_{g,v}$$라 하면,

$$
\mathcal L_d=\frac{1}{GV}\sum_{g=1}^{G}\sum_{v=1}^{V}\bar p_{g,v}\log\bar p_{g,v}
=-\frac{1}{GV}\sum_{g=1}^{G}H(\bar p_g)
$$

이다. $$\mathcal L_d$$를 **최소화**하면 entropy를 크게 만드는 방향으로 움직인다. $$G=1,V=2$$에서 완전 collapse $$(1,0)$$이면 극한값으로 $$\mathcal L_d=0$$이고, 균등 사용 $$(0.5,0.5)$$이면

$$
\mathcal L_d=\frac{0.5\log0.5+0.5\log0.5}{2}
=-0.346574
$$

이므로 균등 사용 쪽이 더 작은 값이다. `diversity loss`가 양수여야 한다고 생각해 앞의 음수를 임의로 없애면 optimization 방향이 뒤집힌다.

전체 objective는 masked positions에 대해 합·평균한 contrastive term과 diversity term을 결합한다.

$$
\mathcal L=\mathcal L_m+\alpha\mathcal L_d
$$

원 논문의 $$\alpha=0.1$$은 특정 실험 설정이다. 너무 큰 가중치는 task discrimination보다 균등 사용을 과도하게 강제할 수 있고, 너무 작으면 collapse 방지가 약해질 수 있다.

## 6. Pre-training에서 ASR fine-tuning으로

### 6.1 CTC output layer를 붙인다

Pre-training은 transcript를 사용하지 않는다. ASR fine-tuning 단계에서는 Transformer context output 위에 vocabulary projection을 붙이고 CTC loss를 최소화한다(p. 33).

$$
o_t=W_c c_t+b_c,\qquad p_t=\operatorname{softmax}(o_t)
$$

$$
\mathcal L_{\mathrm{CTC}}=-\log\sum_{\pi:\mathcal B(\pi)=y}\prod_t p_t(\pi_t)
$$

Quantized code가 그대로 문자 vocabulary가 되는 것은 아니다. Pre-training codebook은 latent acoustic target이고, fine-tuning의 output class는 문자·phoneme·subword와 blank 등 downstream vocabulary다.

원 논문 Table 1의 model 규모는 Base 약 95M, Large 317M parameters다. 슬라이드의 96M은 반올림 또는 표기 차이로 볼 수 있다. Pre-training data, labeled minutes, decoder LM이 다르면 WER을 단순 비교해서는 안 된다. 특히 10분 labeled 설정의 낮은 WER은 LV-60k pre-training과 Transformer LM decoding 조건을 포함한다.

### 6.2 XLS-R은 cross-lingual scale을 키운 wav2vec 2.0이다

XLS-R은 wav2vec 2.0 계열을 128개 언어, 약 436k hours 규모의 public speech로 확장하고 최대 2B parameter model을 학습한다(p. 34). 그림의 `recognition · translation · classification`은 하나의 frozen encoder가 곧바로 모든 과제를 zero-shot으로 푼다는 뜻이 아니다. 원 논문은 labeled downstream data로 과제별 fine-tuning을 수행해 automatic speech recognition, speech translation, language identification, speaker identification을 각각 평가한다. 예를 들어 speech translation은 XLS-R 위에 Transformer decoder를 쌓고, speaker identification은 XLS-R의 모든 parameter를 fine-tune한다.

여러 언어가 하나의 pre-trained encoder capacity를 공유해 저자원 언어에 transfer할 수 있지만, downstream head·labeled data·fine-tuning protocol이 과제마다 다르고 언어 간 data imbalance와 model capacity도 결과에 영향을 준다. 따라서 `Cross-lingual`이라는 이름이나 p. 34의 과제 그림만으로 zero-shot 지원, 모든 과제의 동일한 성능, 모든 언어에 대한 공정성을 보장한다고 해석해서는 안 된다.

### 6.3 Layer-wise analysis는 “한 층이 모든 정보를 가진다”가 아님을 보인다

슬라이드 pp. 35, 38의 CCA 그래프는 각 layer representation과 spectrogram, phone label 등 reference feature 사이의 선형 연관을 비교한다. CCA similarity가 높다는 것은 선택한 metric에서 공유되는 선형 subspace가 크다는 뜻이지, 그 layer가 원본 spectrogram을 완전히 복원한다거나 task causal factor를 증명한다는 뜻은 아니다.

연구 결과는 objective에 따라 acoustic·phonetic·word information의 layer trend가 달라지고, 어떤 downstream task에서는 한 layer를 잘 고르는 것이 모든 layer 결합과 비슷하거나 더 나을 수 있음을 보인다. 슬라이드의 `waveform → spectrogram`은 **raw-waveform CNN representation이 spectrogram과 높은 유사성을 보일 수 있다**는 분석·설계 가설로 읽어야 하며, wav2vec 2.0 입력이 실제 spectrogram으로 바뀌었다는 뜻이 아니다.

### 6.4 Conformer 관련 슬라이드는 서로 다른 후속 연구다

Conformer는 self-attention의 global interaction과 convolution의 local pattern modeling을 결합한다(p. 36). 대표 block은 두 feed-forward module 사이에 self-attention과 convolution module을 두는 Macaron형 구조이며, 각 feed-forward residual에는 절반 가중치를 쓰는 설정이 알려져 있다.

pp. 36–37에는 세 연구가 함께 등장한다.

- **Conformer 원 논문:** supervised ASR encoder architecture를 제안한다. 이것 자체가 wav2vec 2.0 pre-training objective는 아니다.
- **Wav2Vec-Aug:** 제한된 unlabeled data 조건에서 augmentation과 구성 개선을 wav2vec 2.0 pre-training에 적용한다.
- **Pushing the Limits of Semi-Supervised Learning:** wav2vec 2.0의 masked contrastive idea를 쓰지만 입력과 target 경로를 그대로 복제하지 않는다. Raw waveform 대신 80-dimensional log-mel filter-bank feature를 입력으로 쓰고, 2D convolution subsampling 뒤 giant Conformer로 문맥을 만든다. Target branch도 quantizer가 아니라 linear projection이므로 quantization과 diversity loss를 쓰지 않는다. Pre-training source는 Libri-Light `unlab-60k`이지만, random segmentation으로 실제 구성한 2.9M utterances의 합은 **30,031 hours**다. 이후 LibriSpeech labeled data로 transducer를 fine-tune하고, SpecAugment와 iterative noisy-student training을 더한다.

따라서 `Transformer → Conformer`는 wav2vec 2.0의 필수 단계가 아니다. 이 연구는 context architecture뿐 아니라 **입력 표현**(waveform → log-mel), **target·objective 구성**(quantizer와 diversity loss 제거), **downstream training recipe**(transducer fine-tuning, SpecAugment, noisy student)까지 함께 바꾼 후속 pipeline이다. 성능 차이를 Conformer encoder 하나의 효과로 분리할 수 없다. 이는 §6.3의 CCA 관찰, 즉 raw-waveform model의 중간 representation이 spectrogram과 선형 상관을 보인다는 분석과도 별개의 주장이다.

### 6.5 Frozen representation 분석을 읽는 조건

p. 38의 c-siam과 wav2vec layer graph는 encoder를 freeze한 뒤 layer별 probing을 비교한다. Frozen probe가 좋은 layer는 고정 representation이 해당 label과 쉽게 연결된다는 뜻이다. 전체 fine-tuning 후의 최종 ASR 순위와 같다고 단정할 수 없다.

p. 39의 `Frozen Encoder ⇒ Autoencoder-like behavior`는 contrastive 계열의 상위 layer가 입력 acoustic feature와 다시 유사해지는 관찰을 요약한 표현이다. 실제 waveform reconstruction decoder로 sample-level reconstruction loss를 학습한 autoencoder라는 뜻은 아니다. `autoencoder-like`는 layer trend에 대한 해석으로 한정해야 한다.

## 7. HuBERT: offline hidden unit을 예측한다

### 7.1 첫 target은 MFCC clustering에서 만든다

HuBERT도 raw waveform을 CNN과 Transformer로 처리하고 latent span을 mask한다(pp. 44–46). 차이는 target이다. 첫 iteration에서는 39-dimensional MFCC(13 coefficients와 1·2차 delta)를 k-means로 clustering해 frame별 cluster ID $$y_t$$를 만든다.

$$
y_t=\operatorname{kmeans}(a_t),\qquad a_t=\operatorname{MFCC}(x)_t
$$

이 cluster ID는 phoneme 정답이 아니다. 같은 phoneme가 speaker·context에 따라 여러 cluster로 갈 수 있고, 다른 sound가 한 cluster에 섞일 수도 있다. HuBERT의 핵심 가정은 target의 완벽한 의미보다 **시간에 걸친 일관성**이 masked contextual prediction을 학습시키는 데 유용하다는 것이다.

### 7.2 Masked hidden-unit classification

Mask set을 $$M$$, 손상된 입력을 $$\tilde X$$, cluster target을 $$y_t$$라 하자. 최소화하는 masked negative log-likelihood를 쓰면 다음과 같다.

$$
\mathcal L_{\mathrm{HuBERT}}
=-\sum_{t\in M}\log p_{\theta}(y_t\mid\tilde X,t)
$$

원 논문은 masked와 unmasked log-likelihood에 가중치를 두는 일반식을 정의하고 핵심 설정에서는 masked region에만 loss를 둔다. Unmasked position의 정답을 그대로 흉내 내는 shortcut보다, 주변 문맥에서 가린 unit을 예측하도록 강제하기 위해서다.

### 7.3 Iterative refinement

첫 HuBERT를 학습한 뒤 intermediate Transformer layer feature를 다시 k-means로 clustering하여 다음 iteration target을 만든다(p. 47).

```text
MFCC -> 100-cluster labels -> HuBERT Base iteration 1
     -> iteration-1 layer 6 features -> 500-cluster labels
     -> HuBERT Base iteration 2
     -> iteration-2 layer 9 features -> 500-cluster labels
     -> HuBERT Large / X-Large training target
```

원 논문의 Base 두 번째 iteration은 첫 model의 6th layer를 사용하고, Large/X-Large target은 두 번째 Base model의 9th layer를 사용한다. 슬라이드의 `6-th / 9-th layer`는 임의의 두 layer를 동시에 섞는다는 뜻이 아니라 **model·iteration에 따라 선택한 teacher layer가 다르다**는 뜻이다.

### 7.4 “No codebook collapse”의 정확한 범위

HuBERT는 wav2vec 2.0처럼 student와 함께 online Gumbel codebook을 학습하지 않는다. Target을 offline k-means로 미리 고정하므로, contrastive training 중 codebook entry가 한두 개로 몰리는 **online codebook collapse mechanism**과 diversity loss가 필요하지 않다(p. 49).

그러나 이것이 cluster가 항상 균형 있고 의미 있다는 보장은 아니다. K-means도 빈 cluster, 불균형 assignment, initialization 민감도, domain mismatch를 가질 수 있다. Offline vocabulary는 collapse 문제를 다른 stage로 분리할 뿐 clustering quality 검증을 없애지 않는다.

### 7.5 Labeled-data curve는 같은 조건 안에서 읽는다

p. 48은 10 minutes, 1, 10, 100, 960 hours의 labeled data가 늘어날 때 dev-other·test-other WER가 내려가는 곡선을 보여 준다. 이 그림에서 안전하게 읽을 수 있는 핵심은 **self-supervised pre-training 뒤에도 downstream label의 양이 성능에 영향을 준다**는 점이다. HuBERT와 wav2vec 2.0의 선 높이를 objective만의 순위로 해석해서는 안 된다. Pre-training corpus가 LibriSpeech 960 hours인지 Libri-Light 60k hours인지, model scale과 fine-tuning·decoding 조건이 무엇인지도 함께 고정해야 한다.

## 8. wav2vec 2.0과 HuBERT를 나란히 보기

| 항목 | wav2vec 2.0 | HuBERT |
|---|---|---|
| 공통 입력 | Raw waveform → CNN latent → masked Transformer context | Raw waveform → CNN latent → masked Transformer context |
| Pre-training target | 같은 position의 online quantized $$q_t$$ | Offline k-means cluster ID $$y_t$$ |
| 핵심 loss | Positive vs same-utterance distractors contrastive loss | Masked cluster classification loss |
| Vocabulary 생성 | Product codebook을 model과 jointly learning | MFCC 또는 이전 HuBERT feature에 k-means |
| Collapse 대응 | Diversity loss와 temperature schedule | Online codebook 없음; cluster quality·balance는 별도 문제 |
| Negative sampling | 필요; false negative와 sampling 설계 영향 | 기본 hidden-unit CE에는 explicit distractor sampling 없음 |
| 반복 refinement | 원 기본 구조의 필수 단계 아님 | 이전 iteration layer로 target을 재-clustering |
| ASR adaptation | Labeled data에서 CTC fine-tuning | Labeled data에서 CTC fine-tuning 가능 |

둘 중 하나가 모든 조건에서 우월하다는 결론은 슬라이드나 원 논문 비교만으로 낼 수 없다. Model size, pre-training hours, labeled subset, LM decoding, augmentation, fine-tuning recipe가 같아야 objective 차이를 가깝게 비교할 수 있다.

## 9. 실패 조건과 실무 점검

### 9.1 무엇을 먼저 확인할 것인가

1. **시간 단위:** sampling rate와 CNN stride를 함께 기록한다. `stride=320`만으로 ms를 알 수 없다.
2. **Target branch:** mask가 context branch에만 적용되는지, target이 원래 signal에서 생성되는지 확인한다.
3. **Candidate 정의:** wav2vec 2.0의 $$K$$가 distractor 수인지 전체 candidate 수인지 구분한다.
4. **Loss 부호:** diversity term이 negative entropy이며 최소화 시 entropy를 높이는지 확인한다.
5. **Fine-tuning 조건:** encoder freeze 구간, labeled hours, CTC vocabulary, LM 사용 여부를 기록한다.
6. **Layer probe:** frozen probe, full fine-tuning, CCA similarity를 같은 성능 지표처럼 섞지 않는다.
7. **HuBERT iteration:** cluster feature의 model iteration·layer·cluster 수를 함께 기록한다.

### 9.2 대표적인 실패 양상

- Easy negative만 뽑아 contrastive loss가 너무 빨리 0에 가까워짐
- 동일 phonetic content가 negative에 포함되어 false-negative 압력이 커짐
- Codebook usage가 일부 entry에 몰림
- K-means target이 speaker나 recording condition을 주로 분리함
- Domain mismatch로 pre-training representation이 downstream에 덜 유용함
- 적은 label에서 dev set에 맞춘 LM·hyperparameter 선택이 test 비교를 왜곡함
- Model size와 data scale 효과를 objective 효과로 오인함

## 마지막 핵심 정리

- Supervised, semi-supervised, weakly supervised, self-supervised는 label의 존재만이 아니라 **어디서 target이 오고 어느 stage에 쓰이는가**로 구분한다.
- 16 kHz speech 1초는 16,000 samples이지만 dtype이나 sampling rate까지 `16,000 floats`로 고정되는 것은 아니다.
- wav2vec 2.0은 raw waveform을 stride 320 CNN latent로 줄이고, latent span을 mask한 뒤 Transformer context로 quantized target을 구별한다.
- Product quantization의 가능한 조합은 $$V^G$$다. Gumbel-softmax는 hard selection의 forward와 soft gradient의 backward를 연결한다.
- Contrastive candidate는 positive 하나와 $$K$$ distractors다. Diversity term은 negative entropy이므로 최소화할수록 평균 codebook usage의 entropy가 커진다.
- ASR fine-tuning의 class vocabulary는 pre-training codebook과 다르며 CTC와 labeled transcript가 필요하다.
- XLS-R, Conformer, Wav2Vec-Aug, noisy student는 data scale·architecture·training recipe를 서로 다르게 확장한 연구다. 이름만으로 성능을 비교하지 않는다.
- HuBERT는 offline k-means label을 masked context에서 예측하고 이전 model의 intermediate layer로 target을 개선한다. Online codebook collapse는 피하지만 cluster 품질 문제까지 사라지는 것은 아니다.

## Study Guide

먼저 Section 1에서 네 learning paradigm을 **target의 출처**로 설명할 수 있어야 한다. 다음으로 wav2vec 2.0 그림을 `waveform → z → mask → c`와 `z → quantizer → q`의 두 branch로 나누어 그린다. Contrastive loss에서는 positive·distractor·temperature를, diversity loss에서는 부호와 entropy 방향을 직접 계산한다. 마지막으로 HuBERT의 `MFCC cluster → iteration 1 → layer 6 cluster → iteration 2` 흐름을 그린 뒤 두 모델의 target 생성 차이를 표로 복습한다.

시험에서는 숫자를 외우기보다 조건을 붙이는 것이 중요하다. `320 samples`는 16 kHz에서 20 ms이고, `K=100`은 후보 전체가 아니라 distractor 수이며, `Base 95M/Large 317M`은 원 논문의 특정 architecture다. WER은 labeled hours, unlabeled data, external LM과 split을 함께 쓰지 않으면 비교 근거가 부족하다.

## 복습 질문

<details markdown="block">
<summary>1. Self-supervised learning과 unsupervised learning은 완전히 별개의 범주인가?</summary>

답변: 넓게는 SSL도 사람이 붙인 label 없이 representation을 학습하므로 unsupervised learning에 포함될 수 있다. SSL이라는 이름은 입력 자체에서 target을 만들어 명시적 예측 objective를 구성한다는 설계를 강조한다.

</details>

<details markdown="block">
<summary>2. Whisper와 wav2vec 2.0은 모두 대규모 음성으로 pre-training하므로 같은 supervision인가?</summary>

답변: 아니다. Whisper는 인터넷에서 수집한 audio–text pair의 text supervision을 사용해 weakly supervised sequence-to-sequence 학습을 한다. wav2vec 2.0 pre-training은 transcript 없이 audio latent에서 target과 distractor를 만든다.

</details>

<details markdown="block">
<summary markdown="span">3. wav2vec 2.0의 stride 320은 16 kHz에서 몇 ms이며, 왜 sampling rate가 필요한가?</summary>

답변: $$320/16000=0.02$$ s이므로 20 ms다. 같은 320 samples라도 sampling rate가 다르면 시간 길이가 달라지므로 stride 숫자만으로 ms를 결정할 수 없다.

</details>

<details markdown="block">
<summary>4. Masking한 latent를 quantizer에도 넣으면 왜 문제가 되는가?</summary>

답변: Context branch는 가린 입력에서 주변 문맥을 이용해야 하지만 target branch는 원래 position의 내용을 보존해야 한다. Quantizer까지 mask embedding을 보면 positive target이 실제 음성 latent를 나타내지 못한다.

</details>

<details markdown="block">
<summary markdown="span">5. $$G=2,V=320$$일 때 가능한 product code 수가 왜 640이 아닌가?</summary>

답변: 각 codebook에서 하나씩 독립적으로 고르므로 ordered pair의 수는 $$320\times320=102{,}400$$이다. 640은 entry를 단순히 더한 수일 뿐 조합 수가 아니다.

</details>

<details markdown="block">
<summary markdown="span">6. Contrastive loss의 $$K=100$$은 무엇을 뜻하는가?</summary>

답변: Positive target 외에 뽑는 distractor가 100개라는 뜻이다. 따라서 분모의 candidate는 positive를 포함해 101개다. 원 논문에서는 같은 utterance의 다른 masked position에서 distractor를 뽑는다.

</details>

<details markdown="block">
<summary>7. Diversity loss가 음수인데도 최소화할 수 있는 이유는 무엇인가?</summary>

답변: 이 항은 평균 codebook 분포 entropy의 음수다. 균등 분포일수록 entropy가 크고 negative entropy는 더 작아진다. 전체 loss를 최소화하면 codebook entry를 더 고르게 쓰는 방향으로 유도된다.

</details>

<details markdown="block">
<summary>8. Pre-training codebook entry가 ASR character와 일대일 대응하는가?</summary>

답변: 아니다. Codebook은 latent acoustic representation의 학습된 단위다. ASR fine-tuning에서는 별도 projection과 문자·phoneme·subword vocabulary를 두고 CTC 등으로 transcript를 학습한다.

</details>

<details markdown="block">
<summary>9. CCA similarity가 높은 layer는 무엇을 증명하는가?</summary>

답변: 선택한 reference feature와 layer representation 사이에 CCA가 찾은 선형 상관 subspace가 크다는 증거다. 원본을 완전 복원한다거나 그 정보가 모델 판단의 원인이라는 증명은 아니다.

</details>

<details markdown="block">
<summary>10. HuBERT의 첫 번째와 다음 iteration target은 어떻게 다른가?</summary>

답변: 첫 target은 MFCC를 k-means로 clustering한 ID다. 다음 target은 이전 HuBERT의 intermediate Transformer feature를 다시 clustering해 만든다. 원 설정에서는 첫 Base model의 6th layer와 두 번째 Base model의 9th layer가 서로 다른 후속 단계에 쓰인다.

</details>

<details markdown="block">
<summary>11. HuBERT는 codebook collapse가 절대 없는가?</summary>

답변: Joint training 중 Gumbel codebook이 일부 entry로 몰리는 online collapse mechanism은 없다. 그러나 offline k-means도 불균형·빈 cluster·나쁜 target을 만들 수 있으므로 cluster 품질과 assignment 분포는 검증해야 한다.

</details>

<details markdown="block">
<summary>12. wav2vec 2.0과 HuBERT 중 어느 쪽이 항상 더 좋은가?</summary>

답변: 그렇게 결론 낼 수 없다. Objective뿐 아니라 model size, pre-training data, labeled hours, fine-tuning recipe, decoder와 LM, evaluation domain을 맞춰야 비교할 수 있다.

</details>

## Source Check

49쪽 전체를 시각적으로 대조하고 architecture, 시간 단위, objective, model 규모와 HuBERT iteration을 원 논문 및 직접 계산으로 확인했다. 아래 보충·정정은 원저자의 공식 정정문이 아니라 공개된 일차 문헌과 계산에 따른 검토다.

| 위치 | 원문 표현 | 본문의 처리·근거 |
|---|---|---|
| pp. 3–12 | Learning paradigm 그림과 MMS·Whisper 예시 | Paradigm을 target 출처와 stage로 정의. MMS는 weak alignment뿐 아니라 wav2vec 2.0 SSL도 포함하므로 하나의 supervision으로 단순화하지 않음 |
| pp. 13–18 | 입력 일부 예측, 빠른·더 나은 convergence와 foundation model | Masked-prediction objective로 정식화하고 data·objective·fine-tuning 조건이 필요한 경험적 장점으로 제한 |
| p. 19 | `1 speech second ~ 16000 floats` | 16 kHz라면 16,000 samples로 정정. Sampling rate와 storage dtype을 구분 |
| pp. 22–24 | CNN `stride=320`, masking, Transformer | 16 kHz에서 20 ms step, 25 ms receptive field를 stride·kernel로 재계산. Context branch와 target branch의 masking 차이 명시 |
| pp. 25–28 | $$G$$ codebooks, $$V$$ entries, Gumbel-softmax | 조합 수 $$V^G$$, straight-through hard/soft 계산과 temperature 조건 보충 |
| pp. 29–32 | Contrastive·diversity loss, `K=100` | 후보가 positive 포함 $$K+1$$임을 명시. Same-utterance masked distractor, cosine similarity, diversity term 부호와 직접 수치 검산 보충 |
| p. 33 | Base 96M, Large 317M과 10분 label 표 | 원 논문 표의 Base 95M·Large 317M과 LM/pre-training data 조건 명시. 반올림보다 성능 조건을 우선 |
| p. 34 | XLS-R의 recognition·translation·classification 그림 | ASR, speech translation, language identification, speaker identification은 labeled data와 task-specific fine-tuning으로 각각 평가됨을 명시. 그림을 zero-shot 지원이나 과제·언어 간 동일 성능의 보장으로 해석하지 않음 |
| pp. 35–39 | Spectrogram, Conformer, frozen layer와 summary | CCA의 spectrogram 상관과 실제 log-mel 입력 변경을 구분. Pushing the Limits는 80-D log-mel, Conformer, linear target/no quantization·diversity loss, 30,031-hour segmented pre-training, transducer·SpecAugment·noisy-student recipe를 함께 사용함을 명시. `autoencoder-like`도 보편적 wav2vec 2.0 단계로 해석하지 않음 |
| pp. 40–43 | Attention is permutation invariant | Position-free self-attention의 permutation equivariance와 positional mechanism의 필요로 정교화 |
| pp. 44–49 | HuBERT predictive approach, 6th/9th layer, no collapse | MFCC 100-cluster → layer-6 500-cluster → layer-9 target의 iteration별 역할 확인. Online codebook collapse와 offline clustering 품질 문제를 구분 |

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/speech-and-audio-recognition/speech-audio-lecture-05.pdf" | relative_url }}" target="_blank" rel="noopener">Lecture Slides: Self-Supervised Learning — Inkyu An</a></li>
</ul>

## References

<ul>
  <li><a href="https://github.com/yandexdataschool/speech_course" target="_blank" rel="noopener">Yandex Data School Speech Course</a> and <a href="https://github.com/markovka17/dla" target="_blank" rel="noopener">DLA Course Materials</a> — lecture source collections.</li>
  <li><a href="https://arxiv.org/abs/2006.11477" target="_blank" rel="noopener">wav2vec 2.0: A Framework for Self-Supervised Learning of Speech Representations</a> — CNN stride, product quantization, contrastive·diversity loss, CTC fine-tuning and experimental conditions.</li>
  <li><a href="https://arxiv.org/abs/2106.07447" target="_blank" rel="noopener">HuBERT: Self-Supervised Speech Representation Learning by Masked Prediction of Hidden Units</a> — offline clustering, masked prediction and iterative layer targets.</li>
  <li><a href="https://arxiv.org/abs/2111.09296" target="_blank" rel="noopener">XLS-R: Self-supervised Cross-lingual Speech Representation Learning at Scale</a> — multilingual wav2vec 2.0 scaling.</li>
  <li><a href="https://arxiv.org/abs/2005.08100" target="_blank" rel="noopener">Conformer: Convolution-augmented Transformer for Speech Recognition</a> — convolution and self-attention encoder architecture.</li>
  <li><a href="https://arxiv.org/abs/2206.13654" target="_blank" rel="noopener">Wav2Vec-Aug: Improved Self-Supervised Training with Limited Data</a> — augmentation for limited-data SSL.</li>
  <li><a href="https://arxiv.org/abs/2010.10504" target="_blank" rel="noopener">Pushing the Limits of Semi-Supervised Learning for Automatic Speech Recognition</a> — wav2vec 2.0, Conformer and noisy-student pipeline.</li>
  <li><a href="https://arxiv.org/abs/2205.14054" target="_blank" rel="noopener">Contrastive Siamese Network for Semi-Supervised Speech Recognition</a> — frozen layer-wise comparison context.</li>
  <li><a href="https://arxiv.org/abs/2211.03929" target="_blank" rel="noopener">Comparative Layer-Wise Analysis of Self-Supervised Speech Models</a> — CCA-based acoustic, phonetic and word-level layer analysis.</li>
  <li><a href="https://arxiv.org/abs/2305.13516" target="_blank" rel="noopener">Scaling Speech Technology to 1,000+ Languages</a> — MMS data construction and self-supervised multilingual speech models.</li>
  <li><a href="https://cdn.openai.com/papers/whisper.pdf" target="_blank" rel="noopener">Robust Speech Recognition via Large-Scale Weak Supervision</a> — Whisper data and weakly supervised training.</li>
</ul>
