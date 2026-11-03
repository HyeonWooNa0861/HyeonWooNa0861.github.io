---
layout: default
date: 2026-11-03 14:46:00 +0900
title: "ResTL"
topic: "Resting-state EEG transfer learning for cross-subject motor imagery classification"
order: 87
major_topic: "Brain–Computer Interfaces & EEG"
keywords:
  - "Electroencephalography"
  - "Motor imagery"
  - "Resting-state EEG"
  - "Cross-subject transfer learning"
  - "Subject adaptation"
  - "Brain–computer interfaces"
---

# Subject-Adaptive Transfer Learning Using Resting State EEG Signals for Cross-Subject EEG Motor Imagery Classification

## 논문 정보

| 항목 | 내용 |
|---|---|
| 저자 | Sion An, Myeongkyun Kang, Soopil Kim, Philip Chikontwe, Li Shen, Sang Hyun Park |
| 학회 | MICCAI 2024, LNCS 15011, pp. 678–688 |
| DOI | 10.1007/978-3-031-72120-5_63 |
| arXiv | 2405.19346 |
| 온라인 공개 | 2024-10-03 |
| 연구 문제 | 보지 못한 대상자의 motor imagery EEG를 대상자별 task-specific EEG 없이 분류하도록 모델을 적응시키는 방법 |
| 핵심 자원 | 대상자의 resting-state EEG, source 대상자들의 task-specific EEG와 resting-state EEG |

## 한 줄 요약

**ResTL은 대상자의 resting-state EEG에서 개인 특성을 추출한 뒤, 이 특성과 motor-imagery class 조건을 만족하는 보정 신호를 만들고 분류기를 미세조정해 대상자의 task-specific EEG를 직접 수집하지 않고도 cross-subject 적응을 수행한다.**

## 핵심 내용

Motor imagery(MI) EEG는 실제로 움직이지 않고 왼손, 오른손, 양발 또는 혀의 움직임을 상상할 때 나타나는 뇌 활동을 분류한다. 문제는 같은 과제를 수행해도 EEG의 분포가 사람마다 크게 다르다는 점이다. 기존 적응법은 새 대상자의 MI 과제 신호를 일부 수집해 이 차이를 줄이지만, 과제 지시와 반복 수행에는 시간이 들고 집중력도 필요하다.

ResTL은 더 쉽게 수집할 수 있는 resting-state(RS) EEG를 대상자 정보의 원천으로 사용한다. 하지만 RS 신호에는 MI class label이 없다. 논문은 이 간극을 다음 세 단계로 메운다.

1. Source 대상자들의 task-specific(TS) EEG와 RS EEG로 task-dependent feature와 subject-dependent feature를 분리한다.
2. 고정된 분류기를 거꾸로 이용해 target RS EEG의 subject feature를 조건으로 class별 보정 신호를 최적화한다.
3. 보정 신호와 생성한 class label로 모델 전체를 미세조정한 뒤, 실제 target TS EEG를 평가한다.

![ResTL의 source 학습, target resting-state 보정, target 모델 적응 흐름]({{ "/assets/images/research/restl/restl-flow.svg" | relative_url }})

*Supplementary diagram. 원 논문의 Figure 1을 복제하지 않고, 학습 시점과 대상자 적응 시점의 데이터 경계를 독자용으로 재구성했다.*

## 먼저 구분할 것: resting-state와 task-specific EEG

| 구분 | 수집 상태 | label | ResTL에서 맡는 역할 |
|---|---|---|---|
| Task-specific EEG | 특정 움직임을 상상하는 과제를 수행 | MI class label 있음 | Source 분류기 학습과 최종 target 평가 |
| Resting-state EEG | 명시적 MI 과제 없이 휴식 상태를 기록 | MI class label 없음 | 대상자 고유 특성의 기준 feature 추출 |
| Calibrated EEG | 난수 입력을 고정 모델로 최적화 | 최적화에 지정한 MI class label | Target RS의 subject feature와 MI class 특성을 함께 담는 적응용 대리 신호 |

중요한 경계는 **target 대상자의 TS EEG가 적응 과정에 들어가지 않는다**는 점이다. Target TS EEG는 성능 평가에만 사용된다. 반면 source 대상자들의 TS EEG와 RS EEG는 초기 모델 및 feature 분리 학습에 사용된다. 따라서 `RS EEG만 사용한다`는 표현은 전체 모델 학습 데이터가 RS뿐이라는 뜻이 아니라, **새 대상자 적응에 필요한 대상자별 데이터가 RS뿐**이라는 뜻이다.

## 전체 방법: 학습, 신호 보정, 모델 적응

### 1. Feature disentanglement

모델은 네 구성요소를 가진다.

- $$E_{stem}$$: EEG에서 공통 저수준 feature를 추출한다.
- $$E_{task}$$: class와 관련 있고 대상자에는 덜 민감한 feature를 만든다.
- $$E_{subject}$$: 대상자 identity와 관련 있고 MI class에는 덜 민감한 feature를 만든다.
- $$C$$: task feature로 MI class를 예측한다.

초기 학습 목적함수는 세 loss를 결합한다.

$$
\Theta^{*}=\arg\min_{\Theta}
\mathcal{L}_{CE}
+\lambda_{1}\mathcal{L}_{task}
+\lambda_{2}\mathcal{L}_{sub}
$$

$$\mathcal{L}_{CE}$$는 MI 분류를 학습한다. $$\mathcal{L}_{task}$$는 각 class의 prototype을 중심으로 같은 class feature를 모으고 다른 class와 margin을 두는 center·metric loss다. $$\mathcal{L}_{sub}$$는 같은 대상자의 신호를 가깝게, 다른 대상자의 신호를 멀게 만드는 triplet loss다. 이 loss에는 TS와 RS EEG가 모두 참여한다.

<details markdown="block">
<summary markdown="span">Derivation: task and subject losses</summary>

Task feature $$f_i$$와 정답 class $$y_i$$의 prototype $$P_{y_i}$$ 사이 거리를 줄이고, 다른 class prototype과는 margin $$m$$을 확보한다.

$$
\mathcal{L}_{task}
=\frac{1}{N}\sum_{i=1}^{N}
\left(
d(f_i,P_{y_i})
+\sum_{y_i\ne y_j}
\max\left(0,d(f_i,P_{y_i})-d(f_i,P_{y_j})+m\right)
\right)
$$

Subject feature에는 anchor $$g_i$$, 같은 대상자의 positive $$g_p$$, 다른 대상자의 negative $$g_n$$을 사용한다.

$$
\mathcal{L}_{sub}
=\frac{1}{N}\sum_{i=1}^{N}
\max\left(0,d(g_i,g_p)-d(g_i,g_n)+m\right)
$$

출판본의 식 (1)과 (2)는 합 앞에 음의 부호를 표기하지만, 공식 구현은 음의 부호 없이 거리와 hinge를 더하고 Adam으로 최소화한다. 같은 class·대상자의 거리를 줄인다는 본문 설명과도 구현이 일치한다. 따라서 위 식은 공개 코드의 실제 최적화 방향을 따른다.

구현 대조의 기준은 공식 저장소 commit `1f05ad2d9d9211fe29f7c0615b77293019139bac`의 `train.py`다. 아래 signal calibration과 adaptation의 구현 설명도 같은 버전을 기준으로 한다. 공개 코드에는 데이터 로더의 미완성 부분이 있어, 코드 구조의 확인과 benchmark 성능의 재현은 구분해야 한다.

</details>

### 2. Target RS-conditioned pseudo-signal optimization

초기 학습을 마치면 model parameter는 고정한다. Target 대상자의 RS 신호 $$z_{RS}$$를 $$E_{subject}$$에 넣어 subject feature $$g=E_{subject}(z_{RS})$$를 저장한다. 공식 구현은 RS 신호의 복사본이 아니라 같은 shape의 난수 입력 $$z$$를 만들고, 이를 class마다 최적화해 보정 신호 $$z^{*}$$를 만든다.

$$
z^{*}=\arg\min_{z}
\mathcal{L}_{CE}
+\gamma_{1}\mathcal{L}_{task}
+\gamma_{2}d\!\left(g,E_{subject}(z)\right)
$$

세 항의 의미는 다르다.

- $$\mathcal{L}_{CE}$$: 보정 신호가 지정한 MI class로 분류되게 한다.
- $$\mathcal{L}_{task}$$: 보정 신호의 task feature를 해당 class prototype 쪽으로 이동시킨다.
- Subject constraint: 보정 전 RS 신호에서 얻은 subject feature와 보정 후 subject feature가 멀어지지 않게 한다.

Class가 $$K$$개이면 하나의 RS subject feature를 조건으로 class별 $$K$$개의 보정 신호를 만들 수 있다. 이 과정은 생리학적으로 실제 MI trial을 복원한다기보다, **고정 모델이 target 대상자의 특성과 class 조건을 동시에 인식하는 입력을 최적화하는 과정**이다.

출판본은 RS 신호 $$z$$를 보정한다고 서술한다. 공식 코드의 `generate_signal_from_RS`는 target RS에서 `subf_init`을 추출한 뒤 `torch.rand_like(RS)`로 최적화 입력을 초기화한다. 따라서 구현 수준에서는 `RS waveform을 직접 수정한다`보다 `RS-derived subject feature로 난수 입력을 조건화한다`가 정확하다.

### 3. Target model adaptation

공식 구현은 원래 target RS와 최적화한 pseudo-signal을 시간축으로 이어 붙인 뒤, 지정한 class label과 함께 adaptation dataset으로 사용한다. 이 신호 집합으로 model parameter 전체를 10 epoch 미세조정한다.

$$
\Theta^{*}=\arg\min_{\Theta}\mathcal{L}_{CE}
$$

이제 모델은 target 대상자의 실제 TS EEG $$X^{te}$$를 입력받아 $$Y^{te}$$를 예측한다. Target TS EEG는 이 마지막 평가 단계에서만 등장한다. 본문 식 (6)은 cross-entropy로 요약하지만, 공개 구현은 one-hot pseudo-label과 `KLDivLoss`를 사용한다.

## Cross-subject protocol을 읽는 법

모든 실험은 leave-one-subject-out(LOSO) validation을 사용한다. 한 대상자를 target test subject로 남기고 나머지 대상자로 초기 모델을 학습한다. 학습 대상자 데이터의 20%는 validation set으로 무작위 분리한다. 각 target 대상자에 대해 이 과정을 반복하고 대상자별 정확도의 평균과 표준편차를 보고한다.

이 protocol은 random trial split보다 어렵고 실제 cross-subject 적용에 가깝다. 같은 사람의 trial이 train과 test에 동시에 들어가 생기는 identity leakage를 막기 때문이다. 다만 논문이 설명한 20% validation sampling의 구체적 재현 단위와 random seed는 코드를 함께 확인해야 한다.

## Dataset과 전처리

| Dataset | 대상자 | 채널 | Sampling rate | MI class | Session·trial |
|---|---:|---:|---:|---|---|
| BCI Competition IV-2a | 9 | 22 | 250 Hz | 왼손, 오른손, 양발, 혀 | 대상자별 2 session, session별 class당 72 trial |
| BCI Competition IV-2b | 9 | 3 | 250 Hz | 왼손, 오른손 | 대상자별 5 session, session별 200 또는 240 trial |
| OpenBMI | 54 | 62 | 1,000 Hz를 250 Hz로 down-sampling | 왼손, 오른손 | 대상자별 2 session, session별 200 trial |

논문은 각 trial의 0–3초를 RS 구간, 3–6초를 TS 구간으로 사용한다. 모든 신호에는 0.5–40 Hz band-pass filter와 standardization을 적용한다. 따라서 여기서 RS는 별도의 장시간 eyes-open/eyes-closed recording만을 뜻하지 않고, 해당 benchmark trial 안의 과제 전 resting 구간을 포함한다. 실제 BCI 배치 전에 별도 RS 기록으로 같은 성능이 재현되는지는 추가 검증이 필요하다.

## 학습 조건

| 단계 | 설정 |
|---|---|
| Initial training | Adam, learning rate $$5\times10^{-4}$$, 100 epoch |
| Learning-rate decay | 10 epoch 동안 매 epoch 0.99의 exponential decay |
| Loss weights | $$\lambda_1=0.5$$, $$\lambda_2=0.05$$, $$\epsilon=10^{-5}$$ |
| RS calibration | Adam, learning rate $$5\times10^{-3}$$, 300 update |
| Calibration weights | $$\gamma_1=1$$, $$\gamma_2=10$$ |
| Target adaptation | 보정 신호로 10 epoch fine-tuning |
| Backbone | EEGNet 또는 Conformer |

Model selection은 validation loss가 가장 작은 checkpoint를 기준으로 한다. 논문은 session 안에서 사용할 수 있는 RS 신호를 모두 calibration에 사용한 결과를 주 결과로 보고한다.

## 주요 결과

Table 1의 평균 정확도와 대상자 간 표준편차는 다음과 같다.

| Method | BCI IV-2a | BCI IV-2b | OpenBMI |
|---|---:|---:|---:|
| EEGNet | 51.30 ± 7.36 | 67.81 ± 6.52 | 68.84 ± 14.12 |
| Conformer | 58.23 ± 10.54 | 68.23 ± 6.65 | 77.98 ± 9.58 |
| Conformer-BCM | 62.23 ± 11.73 | 71.38 ± 7.89 | 78.49 ± 10.21 |
| EEGNet-ResTL | 62.07 ± 7.71 | 73.13 ± 9.12 | 83.44 ± 9.06 |
| **Conformer-ResTL** | **65.09 ± 11.72** | **73.76 ± 9.41** | **86.05 ± 9.10** |

Conformer-ResTL은 표의 세 dataset에서 가장 높은 평균 정확도를 기록했다. 같은 backbone의 plain Conformer와 비교한 절대 정확도 증가는 BCI IV-2a 6.86%p, BCI IV-2b 5.53%p, OpenBMI 8.07%p다. RS EEG를 feature correction에 사용하는 Conformer-BCM과 비교하면 각각 2.86%p, 2.38%p, 7.56%p 높다.

이 값은 동일한 target 대상자에게서 TS calibration trial을 수집한 방법과의 직접적인 시간·성능 trade-off 비교는 아니다. 또한 대상자 간 표준편차가 9%p 이상인 결과가 많아, 평균 개선과 함께 individual variability도 봐야 한다.

## Ablation과 신호 수 효과

논문은 pretrained classifier에서 입력을 역최적화하는 DeepDream과 DeepInversion을 비교한다. RS 정보를 사용하지 않는 조건보다 target RS에서 subject 정보를 얻는 조건의 정확도가 높았고, subject feature constraint를 함께 쓰는 ResTL이 BCI IV-2a와 IV-2b에서 가장 높았다. 이는 target RS의 subject feature가 calibration을 조건화하는 역할을 한다는 해석을 지지한다.

RS 신호를 전체의 20%, 40%, 60%, 80%, 100%로 늘린 실험도 보고했다.

| Dataset·encoder | 20% | 40% | 60% | 80% | 100% |
|---|---:|---:|---:|---:|---:|
| BCI IV-2a, EEGNet | 60.07 | 60.60 | 61.19 | 61.46 | 62.07 |
| BCI IV-2a, Conformer | 63.33 | 63.89 | 64.59 | 64.73 | 65.09 |
| BCI IV-2b, EEGNet | 72.58 | 72.66 | 72.90 | 73.02 | 73.13 |
| BCI IV-2b, Conformer | 72.88 | 73.28 | 73.35 | 73.58 | 73.76 |

논문은 신호 수가 늘수록 성능이 증가한다고 해석한다. 다만 다섯 지점의 단조 증가를 `linear`한 법칙으로 일반화하거나, 기록 시간이 계속 늘어도 같은 기울기가 유지된다고 결론 내릴 근거는 부족하다.

## Feature visualization이 보여주는 것

BCI IV-2b의 t-SNE에서 calibrated right 신호의 task feature는 실제 right TS feature와, calibrated left 신호는 실제 left TS feature와 가까운 cluster를 형성했다. 반면 subject feature는 class에 관계없이 한 cluster에 모였다. 이는 방법이 의도한 `task는 분리하고 subject는 유지한다`는 구조와 일치한다.

그러나 t-SNE는 시각화 도구다. 2차원 배치만으로 disentanglement의 인과적 성공이나 생리학적 신호 타당성을 증명하지는 않는다. 보정 신호의 spectrum, spatial pattern, test–retest reliability와 독립적인 subject-identification 지표가 함께 검증되면 주장을 더 강하게 뒷받침할 수 있다.

## 논문의 기여

- Target 대상자의 TS EEG 없이 RS EEG만으로 대상자별 model adaptation을 수행하는 문제 설정을 제시했다.
- Task feature와 subject feature를 분리한 뒤, target RS-derived subject feature를 조건으로 난수 입력을 class별 pseudo-signal로 최적화했다.
- EEGNet과 Conformer에 같은 전략을 적용해 backbone에 종속되지 않는 적응 구조를 보였다.
- 세 공개 benchmark의 LOSO 평가에서 plain backbone과 RS 기반 BCM보다 높은 평균 정확도를 보고했다.
- RS 신호 수, RS 정보 사용 여부, subject feature constraint의 효과를 ablation으로 분리했다.

## 해석과 한계

ResTL의 핵심은 `resting-state EEG를 바로 MI classifier에 넣는다`가 아니다. RS-derived subject feature는 난수 입력의 target identity 조건이자 기준이고, pretrained classifier와 class prototype이 task 정보를 주입한다. 따라서 성능 향상은 RS 자체의 MI label 정보라기보다, source에서 학습한 task geometry와 target RS의 subject signature를 결합한 결과로 해석하는 편이 정확하다.

남은 한계도 분명하다.

- 세 benchmark 모두 건강한 공개 MI dataset이다. 환자 재활, 장기 사용, session 간 electrode shift에서의 효과는 검증되지 않았다.
- Target 적응에 사용한 RS 구간은 benchmark trial 내부의 0–3초다. 별도 임상 RS recording으로의 전환 가능성은 추가 실험이 필요하다.
- 입력을 300회 최적화하고 전체 모델을 10 epoch 미세조정한다. 실제 online BCI에서 latency와 compute cost를 평가해야 한다.
- Calibrated EEG가 분류기에 유용하다는 것과 생리학적으로 실제 MI EEG를 재현한다는 것은 다르다.
- Mean accuracy는 개선됐지만 대상자별 편차가 크다. 실패 대상자와 BCI illiteracy 집단의 분석이 필요하다.
- Model adaptation에 pseudo-signal을 사용하므로 class별 보정 오류가 자기강화될 가능성과 overfitting을 점검해야 한다.

## 근거 있는 확장 방향

첫째, 별도의 짧은 eyes-open/eyes-closed RS recording을 사용해 trial 내부 baseline과 같은 적응 효과가 나는지 비교할 수 있다. 둘째, calibration objective에 spectral·spatial plausibility constraint를 추가해 분류기 편향만 만족하는 입력을 줄일 수 있다. 셋째, full fine-tuning 대신 adapter나 low-rank update를 사용하면 online adaptation 비용과 catastrophic forgetting을 줄일 수 있다. 넷째, meta-learning을 결합해 RS가 적거나 session shift가 큰 조건에서 빠르게 적응하는 방법은 논문이 제시한 후속 방향과도 맞는다.

이 확장들은 논문이 직접 검증한 결과가 아니다. ResTL의 데이터 경계와 목적함수에서 자연스럽게 도출되는 연구 가설이다.

## 독립 해설: 논문 구성 따라 읽기

### Introduction

서론은 inter-subject variability와 target TS EEG 수집 비용을 연결한다. 기존 feature disentanglement는 target 정보를 충분히 반영하지 못하고, transfer·few-shot 방법은 target task 수행을 요구한다. ResTL은 RS EEG가 상대적으로 쉽게 수집되며 subject 정보를 가진다는 점을 이용한다.

### Methodology

방법 절의 중심은 feature separation 자체보다 이를 target adaptation으로 연결하는 signal calibration이다. Source 단계에서 class prototype과 subject embedding geometry를 만들고, target 단계에서 RS-derived subject feature를 조건으로 난수 입력을 최적화한다. 고정 모델로 pseudo-signal을 만든 뒤 모델을 다시 업데이트한다는 두 단계가 혼동되기 쉽다.

### Experimental results

실험은 LOSO로 target subject를 완전히 분리하고, 세 dataset과 두 backbone에서 성능을 비교한다. 주 결과는 Conformer-ResTL의 최고 평균 정확도다. Ablation은 RS-derived subject 정보 사용과 subject constraint의 효과를 점검하며, 신호 수 실험은 더 많은 target RS가 도움이 됨을 보인다.

### Conclusion

결론은 TS EEG가 없는 target 대상자 적응의 가능성을 강조한다. 후속 연구로 few target sample 조건의 meta-learning 통합을 제안한다. 이 결론은 RS 기반 적응의 유용성을 지지하지만, 실제 임상 deployment나 생리학적 신호 생성까지 입증한 것은 아니다.

## 최종 핵심 포인트

- ResTL은 새 대상자의 MI label을 요구하지 않고 RS EEG로 target adaptation을 수행한다.
- Source 학습에는 TS와 RS EEG가 모두 필요하다.
- Calibration은 난수 입력을 class prototype 쪽으로 이동시키면서 target RS의 subject feature와 가깝게 만든다.
- Target TS EEG는 적응이 아니라 LOSO test에만 사용된다.
- 세 dataset에서 평균 정확도는 개선됐지만, 실제 RS recording과 임상 환경의 재현성은 후속 검증 대상이다.

## 참고자료

<ul>
  <li><a href="https://doi.org/10.1007/978-3-031-72120-5_63" target="_blank" rel="noopener">Springer chapter and DOI</a></li>
  <li><a href="https://papers.miccai.org/miccai-2024/paper/0192_paper.pdf" target="_blank" rel="noopener">MICCAI 2024 official paper PDF</a></li>
  <li><a href="https://arxiv.org/abs/2405.19346" target="_blank" rel="noopener">arXiv abstract and versions</a></li>
  <li><a href="https://github.com/SionAn/MICCAI2024-ResTL" target="_blank" rel="noopener">Official ResTL code repository</a></li>
  <li><a href="https://github.com/SionAn/MICCAI2024-ResTL/blob/1f05ad2d9d9211fe29f7c0615b77293019139bac/train.py" target="_blank" rel="noopener">Inspected training and calibration implementation</a></li>
</ul>
