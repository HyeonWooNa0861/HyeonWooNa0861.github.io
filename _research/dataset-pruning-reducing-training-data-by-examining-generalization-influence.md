---
layout: default
title: "Dataset Pruning"
topic: "Reducing training data by examining generalization influence"
order: 39
major_topic: "Machine Learning & Data Curation"
keywords:
  - "Dataset pruning"
  - "Generalization influence"
  - "Training data selection"
  - "Data efficiency"
---

# Dataset Pruning: Reducing Training Data by Examining Generalization Influence

Source PDF: `dataset-pruning-reducing-training-data-by-examining-generalization-influence.pdf`

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Dataset Pruning: Reducing Training Data by Examining Generalization Influence |
| 저자 | Shuo Yang, Zeke Xie, Hanyu Peng, Min Xu, Mingming Sun, Ping Li |
| 출처 | ICLR 2023, arXiv:2205.09329 |
| 주제 | Dataset Pruning, Influence Functions, Sample Selection |
| 핵심 방법 | subset removal의 generalization influence를 근사해 가장 큰 redundant subset을 찾는 optimization-based pruning |

## 한 줄 요약

Dataset Pruning은 개별 sample 점수만으로 데이터를 고르는 대신, 특정 sample 집합을 제거했을 때 모델 일반화가 얼마나 변하는지 influence function으로 근사해 작은 proxy training set을 구성하는 방법이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 모든 training example이 같은 정도로 필요한가? |
| 2 | Generalization influence | sample 제거가 모델 파라미터와 test 성능에 미치는 효과를 어떻게 근사하는가? |
| 3 | Optimization | 가장 큰 redundant subset을 어떤 제약 최적화로 찾는가? |
| 4 | 실험 | CIFAR/TinyImageNet에서 training cost와 accuracy는 어떻게 바뀌는가? |
| 5 | 해석 | dataset condensation이나 forgetting score와 무엇이 다른가? |

## 1. 문제 배경

딥러닝 성능은 큰 데이터셋에 의존하지만, 모든 샘플이 동일하게 일반화에 기여하는 것은 아니다. 기존 subset selection은 class center와의 거리, forgetting score, gradient norm 같은 scalar score로 sample을 정렬하는 경우가 많다. 논문은 이런 방식이 sample 간 joint effect를 놓친다고 본다.

예를 들어 gradient norm이 큰 두 sample도 gradient 방향이 반대라면 함께 제거했을 때 평균 영향은 작을 수 있다. 따라서 중요한 질문은 "한 sample이 중요한가"보다 "어떤 sample 조합을 제거해도 일반화 격차가 제한되는가"이다.

## 2. 방법

논문은 training example을 제거했을 때 생기는 parameter change를 influence function으로 선형 근사한다. 모든 subset을 실제로 제거하고 재학습하는 것은 \(2^n\)번 학습이 필요하므로 불가능하다. 대신 영향 근사를 이용해 다음 형태의 문제를 푼다.

| 요소 | 의미 |
|---|---|
| objective | 제거할 sample 수를 최대화 |
| constraint | 제거로 인한 parameter/generalization 변화가 threshold 이하 |
| output | 원 데이터셋보다 작은 proxy training set |

핵심은 정확도만 보는 것이 아니라, 일반화 격차를 제한하는 조건 아래 중복 데이터를 최대한 제거하는 것이다.

## 3. 실험 결과

논문은 CIFAR-10, CIFAR-100, TinyImageNet 등에서 pruning 방법을 평가한다.

| 결과 | 해석 |
|---|---|
| CIFAR-10 40% training example 제거 | test accuracy는 1.3%만 감소 |
| convergence time | 약 절반으로 감소 |
| architecture search | 작은 proxy dataset이 여러 architecture 비교에 사용 가능 |
| 기존 score 기반 방법 대비 | joint influence를 고려해 더 안정적인 subset 구성 |

이 결과는 dataset pruning을 단순 데이터 축소가 아니라 training cost, hyperparameter tuning, architecture search를 가볍게 만드는 도구로 읽게 한다.

## GitBlog 관점

이 자료는 LLM quantization 계열과 직접 연결되지는 않지만, calibration data curation과 sample selection이라는 큰 축에서 관련된다. COVERCAL이나 Self-Calibration이 "압축 전에 어떤 calibration data를 쓸 것인가"를 다룬다면, Dataset Pruning은 "학습 또는 탐색에 필요한 데이터 subset을 어떻게 줄일 것인가"라는 더 일반적인 데이터 효율화 문제를 다룬다.

## 핵심 내용

- 데이터셋 축소는 개별 sample 점수보다 sample 집합의 공동 영향이 중요하다.
- Influence function을 이용해 sample 제거가 parameter/generalization에 미치는 영향을 근사한다.
- 일반화 격차 constraint를 두고 가장 큰 redundant subset을 제거한다.
- 학습 비용과 architecture search 비용을 줄이는 proxy dataset 구성에 활용할 수 있다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/dataset-pruning-reducing-training-data-by-examining-generalization-influence/dataset-pruning-reducing-training-data-by-examining-generalization-influence.pdf" | relative_url }}" target="_blank" rel="noopener">dataset-pruning-reducing-training-data-by-examining-generalization-influence.pdf</a></li>
  <li><a href="https://arxiv.org/abs/2205.09329" target="_blank" rel="noopener">arXiv:2205.09329</a></li>
</ul>
