---
layout: default
date: 2026-05-26 14:31:45 +0900
title: "Attention Is All You Need"
topic: "Transformer architecture and v1-v7 revision notes"
order: 6
major_topic: "Deep Learning Architectures"
keywords:
  - "Transformer"
  - "Self-attention"
  - "Sequence modeling"
  - "Neural machine translation"
---

# Attention Is All You Need

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Attention Is All You Need |
| 저자 | Ashish Vaswani, Noam Shazeer, Niki Parmar, Jakob Uszkoreit, Llion Jones, Aidan N. Gomez, Łukasz Kaiser, Illia Polosukhin |
| 발표 | 31st Conference on Neural Information Processing Systems, NIPS 2017 |
| arXiv | `1706.03762` |
| 비교한 버전 | v1: 12 Jun 2017, v7: 2 Aug 2023 |
| 핵심 키워드 | Transformer, Self-Attention, Multi-Head Attention, Sequence Transduction, Machine Translation |

## 한 줄 요약

이 논문은 sequence transduction에서 recurrence와 convolution을 제거하고, encoder-decoder 전체를 self-attention과 feed-forward network로 구성한 Transformer를 제안한 연구다.

## 핵심 내용

이 절은 원문 전체를 축어적으로 옮긴 번역본이 아니라, 논문의 흐름을 한국어로 따라 읽을 수 있도록 재구성한 번역형 해설이다. 원문의 핵심 용어와 수식, 실험 수치, v1-v7 비교 정보는 유지하되 문장 구성은 학습용 설명에 맞게 다시 정리했다.

초록과 서론의 핵심은 sequence transduction에서 recurrence와 convolution이 필수라는 기존 가정을 뒤집는 데 있다. 기존 RNN 계열 모델은 입력 token을 순서대로 처리하므로 병렬화에 불리하고, 멀리 떨어진 token 관계를 여러 단계의 hidden state를 통해 전달해야 한다. Transformer는 이 병목을 줄이기 위해 self-attention을 중심 연산으로 두고, 모든 token이 다른 token을 직접 참고할 수 있게 만든다.

모델 구조는 encoder와 decoder stack으로 구성된다. Encoder는 입력 문장의 token 관계를 self-attention으로 계산하고, decoder는 masked self-attention과 encoder-decoder attention을 통해 이전 출력과 입력 문맥을 함께 사용한다. Scaled Dot-Product Attention은 query와 key의 내적으로 관련성을 구하고, softmax weight를 value에 곱해 필요한 정보를 모은다. \(\sqrt{d_k}\) scaling은 dot product가 커져 softmax gradient가 작아지는 문제를 줄이기 위한 안정화 장치다.

Multi-Head Attention은 하나의 attention map만 사용하는 대신 여러 projection 공간에서 token 관계를 병렬로 본다. 이 설계는 문장 안의 문법 관계, 의미 관계, 장거리 참조처럼 서로 다른 패턴을 여러 head가 나누어 포착할 수 있게 한다. 또한 recurrence가 없으면 token 순서가 사라지므로, Transformer는 sinusoidal positional encoding을 embedding에 더해 위치 정보를 주입한다.

실험에서는 WMT 2014 English-German과 English-French translation에서 Transformer가 높은 BLEU와 낮은 training cost를 보였다. 논문은 self-attention이 계산 병렬성, 짧은 path length, 장거리 관계 포착 측면에서 RNN/CNN과 다른 inductive bias를 가진다고 설명한다. 다만 모든 token pair를 비교하는 구조 때문에 긴 sequence에서는 quadratic cost가 발생하고, autoregressive decoder에서는 inference가 여전히 순차적으로 진행된다는 한계가 남는다.

v1에서 v7로의 변화는 architecture 변경이 아니라 논문 정보의 정리와 보강에 가깝다. 학회 정보, figure/table 재사용 문구, 저자 기여, reference, code availability, positional embedding ablation, 일부 실험 표기가 정리되었다. 따라서 v7은 Transformer의 핵심 아이디어가 바뀐 버전이라기보다, 최종 인용과 구현 맥락을 더 명확히 제공하는 판본으로 읽는 것이 적절하다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | RNN 기반 encoder-decoder가 긴 sequence에서 왜 병렬화와 장거리 의존성에 취약한가? |
| 2 | 핵심 제안 | recurrence 없이 attention만으로 sequence representation을 만들 수 있는가? |
| 3 | 구조 | encoder, decoder, multi-head attention, feed-forward layer가 어떻게 결합되는가? |
| 4 | 위치 정보 | recurrence가 없을 때 token order를 어떻게 주입하는가? |
| 5 | 계산 관점 | self-attention은 RNN/CNN과 비교해 어떤 복잡도와 path length를 갖는가? |
| 6 | 실험 | WMT translation과 parsing에서 어떤 성능을 보였는가? |
| 7 | 버전 갱신 | v1에서 v7로 가며 어떤 정보가 보강되었는가? |
| 8 | 해석 | Transformer의 기여와 한계를 어떻게 읽어야 하는가? |

## 1. 문제 배경

기존 sequence-to-sequence 모델은 주로 RNN, LSTM, GRU를 encoder-decoder 구조에 사용했다. 이 구조는 이전 hidden state를 다음 위치 계산에 사용하므로 sequence 길이 방향으로 계산이 순차화된다.

```text
token_1 -> hidden_1 -> hidden_2 -> ... -> hidden_n
```

이 순차성은 두 가지 문제를 만든다.

| 문제 | 설명 |
|---|---|
| 병렬화 제약 | 한 sequence 안에서 다음 위치 계산이 이전 위치 결과에 의존하므로 GPU 병렬성이 제한된다. |
| 장거리 의존성 | 멀리 떨어진 token 사이 정보가 여러 recurrent step을 지나야 하므로 학습이 어려워질 수 있다. |

Attention mechanism은 이미 encoder-decoder 사이에서 중요한 정보를 고르는 방법으로 쓰이고 있었다. 이 논문의 질문은 한 단계 더 나아간다.

```text
attention을 보조 장치가 아니라 모델의 중심 구조로 둘 수 있는가?
```

## 2. 핵심 제안

Transformer는 recurrence와 convolution을 제거하고, attention mechanism만으로 sequence 내부 token 관계를 계산한다. 논문의 핵심 주장은 다음과 같다.

| 주장 | 의미 |
|---|---|
| Self-attention 중심 구조 | 각 token이 sequence 안의 다른 모든 token을 직접 참조한다. |
| Multi-head attention | 하나의 attention map이 아니라 여러 representation subspace에서 병렬로 관계를 본다. |
| Position-wise feed-forward | attention 이후 각 위치별 비선형 변환으로 표현력을 보강한다. |
| Positional encoding | recurrence가 사라진 대신 위치 정보를 vector에 더한다. |

이 구조 덕분에 Transformer는 sequence 길이 방향 계산을 더 많이 병렬화할 수 있고, 두 위치 사이 정보 전달 경로를 짧게 만든다.

## 3. 모델 구조

Transformer는 encoder stack과 decoder stack으로 구성된다. 논문 기본 설정은 encoder 6층, decoder 6층이다.

| 구성 | 역할 |
|---|---|
| Encoder self-attention | 입력 sequence 내부 token 관계를 계산 |
| Decoder masked self-attention | 현재 위치가 미래 token을 보지 못하게 제한 |
| Encoder-decoder attention | decoder가 encoder output을 참조 |
| Feed-forward network | 각 위치의 representation을 독립적으로 변환 |
| Residual connection + LayerNorm | 깊은 stack의 안정적 학습 지원 |

Encoder 한 층은 self-attention sublayer와 feed-forward sublayer로 볼 수 있다. Decoder는 여기에 encoder-decoder attention sublayer가 하나 더 추가된다.

```text
encoder layer:
self-attention -> feed-forward

decoder layer:
masked self-attention -> encoder-decoder attention -> feed-forward
```

## 4. Scaled Dot-Product Attention

Transformer의 기본 attention은 query, key, value로 표현된다. Query와 key의 dot product로 compatibility를 구하고, softmax로 weight를 만든 뒤 value를 가중합한다.

$$
\mathrm{Attention}(Q,K,V)
=
\mathrm{softmax}\left(\frac{QK^{T}}{\sqrt{d_k}}\right)V
$$

여기서 \(\sqrt{d_k}\)로 나누는 이유는 dot product 값이 너무 커져 softmax gradient가 작아지는 문제를 줄이기 위해서다.

| 기호 | 의미 |
|---|---|
| \(Q\) | 현재 위치가 무엇을 찾는지 나타내는 query |
| \(K\) | 각 위치가 어떤 정보와 매칭되는지 나타내는 key |
| \(V\) | 실제로 집계되는 value |
| \(d_k\) | key/query dimension |

## 5. Multi-Head Attention

Multi-head attention은 하나의 attention을 크게 쓰는 대신 여러 head가 서로 다른 projection에서 attention을 수행하게 한다.

$$
\mathrm{MultiHead}(Q,K,V)
=
\mathrm{Concat}(\mathrm{head}_1,\ldots,\mathrm{head}_h)W^{O}
$$

$$
\mathrm{head}_i
=
\mathrm{Attention}(QW_i^{Q},KW_i^{K},VW_i^{V})
$$

이 구조의 해석 포인트는 하나의 문장 안에서도 관계의 종류가 다양하다는 점이다. 어떤 head는 근처 단어의 local relation을 보고, 어떤 head는 long-distance dependency나 anaphora relation을 볼 수 있다.

## 6. Positional Encoding

Self-attention 자체는 token 순서를 알지 못한다. 따라서 Transformer는 input embedding에 positional encoding을 더한다.

$$
PE_{(pos,2i)}
=
\sin\left(\frac{pos}{10000^{2i/d_{\mathrm{model}}}}\right)
$$

$$
PE_{(pos,2i+1)}
=
\cos\left(\frac{pos}{10000^{2i/d_{\mathrm{model}}}}\right)
$$

Sinusoidal positional encoding은 고정된 함수이므로 학습 parameter를 추가하지 않는다. v7에서는 learned positional embedding도 실험했으며, Table 3 row E에서 sinusoidal version과 거의 비슷한 결과가 보고된다.

## 7. 왜 Self-Attention인가

논문은 self-attention, recurrent layer, convolutional layer를 세 관점에서 비교한다.

| 관점 | Self-Attention의 의미 |
|---|---|
| Layer당 계산량 | sequence length \(n\)이 representation dimension \(d\)보다 작을 때 유리할 수 있다. |
| 순차 연산 수 | RNN과 달리 sequence position 방향의 sequential operation이 줄어든다. |
| 최대 path length | 임의의 두 token이 attention 한 층에서 직접 연결될 수 있다. |

특히 maximum path length가 짧다는 점이 중요하다. RNN은 멀리 떨어진 token 사이 정보가 여러 step을 지나야 하지만, self-attention은 한 layer 안에서 직접 연결된다.

다만 self-attention은 모든 token pair를 비교하므로 sequence length에 대해 quadratic cost를 가진다. 이 한계는 이후 long-context Transformer 연구들이 계속 다루게 되는 문제다.

## 8. 실험 결과

논문은 WMT 2014 English-German, English-French translation task에서 Transformer를 평가한다.

| 모델 | EN-DE BLEU | EN-FR BLEU | 해석 |
|---|---:|---:|---|
| Transformer base | 27.3 | 38.1 | 이전 단일 모델 및 ensemble 대비 경쟁력 있는 성능 |
| Transformer big | 28.4 | 41.8 | v7 abstract/table 기준, 높은 BLEU와 낮은 training cost 강조 |

English-German에서는 Transformer big이 기존 ensemble까지 넘어서는 결과를 제시한다. English-French에서는 v7의 abstract와 Table 2에서 41.8 BLEU가 표기된다. 다만 v7 본문 일부 문단에는 41.0 BLEU 표기가 남아 있어, 결과를 인용할 때는 어느 위치의 수치인지 구분하는 것이 좋다.

논문은 English constituency parsing에도 Transformer를 적용해, machine translation에만 특화된 구조가 아니라 더 넓은 sequence modeling 구조로 확장될 수 있음을 보인다.

## 9. v1에서 v7로 업데이트된 점

v1과 v7은 핵심 architecture 자체가 바뀐 논문이라기보다, 최종 출판 맥락, attribution, reference, 실험 표기, 구현 공개 정보가 정리된 버전으로 읽는 것이 적절하다.

| 항목 | v1 | v7 | 해석 |
|---|---|---|---|
| arXiv 표기 | `arXiv:1706.03762v1`, 12 Jun 2017 | `arXiv:1706.03762v7`, 2 Aug 2023 | 초기 preprint에서 최종 정리본으로 이동 |
| 첫 페이지 문구 | 별도 재사용 허가 문구 없음 | Google의 figure/table 재사용 허가 문구 추가 | 논문 자료의 인용 및 재사용 맥락이 명확해짐 |
| 학회 정보 | 첫 페이지에 venue 표기가 없음 | NIPS 2017, Long Beach, CA, USA 표기 | 발표 맥락이 명시됨 |
| 저자 기여 | equal contribution 중심의 짧은 footnote | 각 저자의 역할을 더 자세히 기술 | Transformer 개발 과정의 contribution attribution이 보강됨 |
| EN-FR BLEU | abstract/table 기준 41.0 | abstract/table 기준 41.8 | 결과 표기가 상향 수정됨. 단, v7 본문 일부에는 41.0 표기가 남아 있음 |
| Table 3 base \(d_{ff}\) | 1024로 표기 | 2048로 표기 | 본문 3.3의 feed-forward dimension과 일치하도록 표가 정정된 것으로 해석 가능 |
| Positional encoding ablation | learned positional embedding row 없음 | row E 추가, positional embedding instead of sinusoids BLEU 25.7 | sinusoidal 선택의 근거가 실험 표와 더 잘 연결됨 |
| Reference 수 | 36개 | 40개 | ResNet, Active Memory, Output Embedding, End-to-End Memory Networks 등 관련 문헌이 보강됨 |
| Code availability | 곧 공개 예정이라고 서술 | `tensorflow/tensor2tensor` 링크 명시 | 재현성과 구현 접근성이 개선됨 |
| Acknowledgements | 별도 섹션 없음 | Nal Kalchbrenner, Stephan Gouws 언급 | 수정과 영감에 대한 acknowledgement 추가 |

## 10. 논문의 핵심 기여

첫째, Transformer는 attention을 encoder-decoder의 보조 연결이 아니라 sequence modeling의 중심 연산으로 끌어올렸다. 이 점이 이후 BERT, GPT 계열 모델의 구조적 출발점이 된다.

둘째, multi-head attention은 하나의 attention distribution으로 모든 관계를 설명하기보다, 여러 subspace에서 token relation을 나누어 보는 설계를 제공했다.

셋째, positional encoding을 통해 recurrence 없이도 순서 정보를 다룰 수 있음을 보였다. 이는 순차 처리 구조를 줄이고 병렬 학습 가능성을 크게 높인다.

넷째, machine translation에서 높은 BLEU와 낮은 training cost를 동시에 제시해, 구조적 단순화가 성능 저하로 이어지지 않는다는 근거를 제공했다.

## 11. 해석 포인트

이 논문을 읽을 때 가장 중요한 지점은 "attention이 좋은 성능을 냈다"가 아니라, sequence model의 inductive bias를 바꿨다는 점이다. RNN은 시간 순서를 따라 정보를 누적하는 구조이고, CNN은 local kernel을 쌓아 receptive field를 넓히는 구조다. Transformer는 모든 위치 간 관계를 직접 계산한 뒤, 필요한 관계를 attention weight로 선택한다.

또한 Transformer는 완전히 순서를 버린 모델이 아니다. 순서 처리는 recurrent transition이 아니라 positional encoding으로 분리된다. 즉, 순서 정보와 token relation 계산을 구조적으로 분리했다는 점이 중요하다.

v1과 v7 비교에서는 architectural novelty가 바뀌었다기보다, 결과와 attribution의 정확성이 보강된 점에 주목해야 한다. 특히 Table 3의 \(d_{ff}\) 수정과 positional embedding ablation 추가는 모델 세부 설정을 읽을 때 직접적인 영향을 준다.

## 12. 한계와 이후 과제

Transformer의 self-attention은 sequence 내 모든 token pair를 계산하므로 긴 입력에서 비용이 커진다. 논문 결론에서도 images, audio, video처럼 큰 입력을 다루기 위해 local 또는 restricted attention을 탐색하겠다고 언급한다.

또한 decoder generation은 여전히 autoregressive하게 진행된다. Encoder와 training에서는 병렬화 이점이 크지만, token을 하나씩 생성하는 inference 구조는 완전히 사라지지 않는다.

마지막으로 attention visualization은 모델 해석 가능성을 보여주는 흥미로운 자료지만, attention weight가 곧바로 인과적 설명을 의미한다고 단정하기는 어렵다. 따라서 attention map은 분석의 출발점이지 최종 설명으로 읽으면 안 된다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/attention-is-all-you-need/attention-is-all-you-need-v1.pdf" | relative_url }}" target="_blank" rel="noopener">Attention Is All You Need v1 PDF</a></li>
  <li><a href="{{ "/assets/pdfs/research/attention-is-all-you-need/attention-is-all-you-need-v7.pdf" | relative_url }}" target="_blank" rel="noopener">Attention Is All You Need v7 PDF</a></li>
  <li><a href="https://arxiv.org/abs/1706.03762" target="_blank" rel="noopener">arXiv:1706.03762</a></li>
  <li><a href="https://github.com/tensorflow/tensor2tensor" target="_blank" rel="noopener">tensorflow/tensor2tensor</a></li>
</ul>
