---
layout: default
title: "SkySearch"
topic: "Satellite video search at scale"
order: 2
---

# SkySearch: Satellite Video Search at Scale

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | SkySearch: Satellite Video Search at Scale |
| 저자 | Minyoung Choe, Geon Lee, Changhun Han, Suji Kim, Woong Hu, Hyebeen Hwang, Geunseok Park, Beongyeon Kim, Hyesook Lee, Ha-Myung Park, Kijung Shin |
| 학회 | KDD 2025 |
| DOI | `10.1145/3711896.3737263` |
| 키워드 | Satellite Video, Similarity Search, Video Retrieval, Video Prediction |
| 배포 맥락 | Korea Meteorological Administration, KMA |

## 한 줄 요약

SkySearch는 대규모 위성 이미지 DB에서 현재 기상 상황과 유사한 과거 위성 비디오를 빠르게 찾기 위해, self-supervised video embedding, 예측 기반 query augmentation, time-restricted graph search를 결합한 실사용 검색 시스템이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 정의 | 위성 이미지를 어떤 단위의 "비디오 검색" 문제로 바꾸는가? |
| 2 | 데이터 압축 | 라벨이 없는 위성 비디오를 어떻게 embedding으로 압축하는가? |
| 3 | Query augmentation | 현재 상황 query에 미래 예측 frame을 왜 붙이는가? |
| 4 | Candidate search | 거대한 DB에서 유사 비디오 후보를 어떻게 초 단위로 찾는가? |
| 5 | Time-restricted search | 특정 시간 구간 안에서 유사 사례를 찾으려면 무엇이 달라지는가? |
| 6 | Ranking | 빠른 embedding distance와 느린 perceptual metric을 어떻게 절충하는가? |
| 7 | Evaluation | 정확도, 속도, 실사용성에서 어떤 근거를 제시하는가? |
| 8 | 한계 | scattered cloud, metric 부재, prediction confidence 문제는 왜 남는가? |

## 1. 문제 배경

기상 예보에서는 과거의 비슷한 위성 영상 사례를 찾는 일이 중요하다. 현재 구름 패턴과 유사하게 전개된 과거 사례를 찾으면, 수치예보모델이 잘 설명하지 못하는 cloud dynamics를 forecaster가 보조적으로 해석할 수 있다.

하지만 위성 비디오 검색은 일반 image retrieval보다 어렵다.

| 어려움 | 설명 |
|---|---|
| 라벨 부재 | 어떤 과거 위성 비디오가 서로 유사한지 정답 label이 없다. |
| 고해상도 | 한 video가 수백만 pixel로 구성되어 직접 비교가 비싸다. |
| 시간성 | 한 장의 이미지보다 구름의 시간적 변화가 중요하다. |
| 실시간성 | 예보 업무에서는 query 결과가 몇 초 안에 나와야 한다. |
| 시간 제한 | 특정 계절, 기간, 위성, 채널 안에서 검색해야 할 수 있다. |

SkySearch의 핵심 목표는 다음이다.

```text
query satellite video -> similar historical satellite videos
```

단순히 이미지를 비슷하게 찾는 것이 아니라, 12시간 동안의 spatial pattern과 temporal evolution이 유사한 과거 비디오를 ranked list로 제공한다.

## 2. 문제 정의

논문은 satellite image dataset을 timestamp가 붙은 이미지 집합으로 본다.

$$
D = \{(x_1,t_1),\ldots,(x_{\lvert D\rvert},t_{\lvert D\rvert})\}
$$

Satellite video는 1시간 간격으로 샘플링한 연속 이미지 \\(L\\)개의 sequence다. 논문 설정에서는 \\(L = 12\\)이므로 하나의 query video는 12시간짜리 위성 영상이다.

$$
v = ((x_{i+1},t_{i+1}),(x_{i+2},t_{i+2}),\ldots,(x_{i+L},t_{i+L}))
$$

검색 결과는 query video와 유사한 candidate video들의 ranked list다.

| 기호 | 의미 |
|---|---|
| \\(D\\) | timestamp가 있는 전체 위성 이미지 DB |
| \\(v\\) | DB에서 sliding window로 만든 satellite video |
| \\(q\\) | 외부에서 들어온 query video |
| \\(L\\) | video 길이, 기본 12시간 |
| \\(C\\) | 검색된 candidate video 집합 |

## 3. Framework 개요

SkySearch는 다섯 단계로 구성된다.

```text
satellite videos
-> self-supervised video compression
-> optional video prediction for query augmentation
-> graph-based candidate search
-> ranking
-> forecaster UI
```

| 모듈 | 역할 |
|---|---|
| Data compression | 고해상도 비디오를 256차원 embedding으로 압축 |
| Video prediction | 현재 query 뒤의 미래 frame을 예측해 query를 확장 |
| Candidate search | latent space에서 k-NN graph를 탐색해 후보를 빠르게 찾음 |
| Ranking | 후보를 embedding distance 또는 perceptual metric으로 정렬 |
| Visualization | KMA forecaster가 query와 유사 사례를 비교할 수 있게 표시 |

이 구조의 중요한 포인트는 "모든 것을 brute-force로 비교하지 않는다"는 것이다. 먼저 비디오를 작은 embedding으로 만들고, embedding 사이의 관계를 graph로 만들어 검색 비용을 줄인다.

## 4. Self-Supervised Video Compression

위성 비디오에는 유사도 label이 없다. SkySearch는 기상 현상이 시간적으로 급격히 무작위로 바뀌지 않는다는 가정을 사용한다. 가까운 시간의 비디오는 positive pair, 먼 시간의 비디오는 negative pair로 둔다.

$$
P_v = \{v' : \lvert t_v - t_{v'}\rvert \le \Delta\}
$$

$$
N_v = \{v' : \lvert t_v - t_{v'}\rvert > \Delta\}
$$

논문에서는 \\(\Delta = 8\text{ hours}\\)를 기본값으로 사용한다.

Loss는 triplet/margin ranking loss처럼 이해하면 된다.

$$
L_v =
\mathbb{E}_{p \sim P_v,\ n \sim N_v}
\left[
\max\left(
\lVert f(v)-f(p)\rVert_2^2
- \lVert f(v)-f(n)\rVert_2^2
+ \gamma,
0
\right)
\right]
$$

즉, encoder \\(f\\)가 만든 embedding에서 시간적으로 가까운 video는 가깝게, 먼 video는 멀게 배치하도록 학습한다.

## 5. Encoder 구조

Video encoder는 두 부분으로 구성된다.

| 구성 | 역할 |
|---|---|
| Spatial encoder | 각 frame의 공간적 cloud pattern을 feature로 변환 |
| Sequential encoder | frame feature sequence를 받아 시간적 변화를 반영 |

Spatial encoder는 convolution layer, max pooling, linear layer로 frame-level embedding을 만든다. Sequential encoder는 Convolutional Recurrent Neural Network로 temporal dependency를 처리하고 video-level embedding을 만든다.

훈련은 두 단계로 나뉜다.

| 단계 | 설명 |
|---|---|
| 1 | Spatial encoder를 먼저 학습한다. |
| 2 | Spatial encoder를 freeze한 뒤 sequential encoder를 학습한다. |

이렇게 나누면 배포 중 문제가 생겼을 때 spatial representation 문제인지 temporal modeling 문제인지 분리해서 debug하기 쉽다.

## 6. Compression 효과

원래 위성 비디오는 매우 크다. 논문 설정에서 한 video는 다음 크기를 가진다.

$$
600 \times 748 \times 12 = 5{,}385{,}600
$$

반면 embedding은 256차원 float vector다.

| 표현 | 대략적 크기 |
|---|---|
| 원본 12-frame video | 약 5.14 MB |
| 256-d float embedding | 약 1 KB |

논문은 이 압축이 약 \\(5260\times\\)의 저장공간 감소를 만든다고 설명한다. 이 압축 덕분에 검색도 원본 pixel이 아니라 compact latent space에서 수행할 수 있다.

## 7. Video Prediction과 Query Augmentation

현재 시점의 query는 과거 DB에 있는 완성된 24시간 패턴과 직접 비교하기 어렵다. SkySearch는 query가 현재 상황을 나타낼 때, 미래 frame을 예측해 query를 확장한다.

```text
12-hour current query
-> predict next 12 hours
-> 24-hour augmented query
```

이렇게 하면 검색 결과가 현재 상태뿐 아니라 앞으로의 예상 전개와도 비슷한 과거 사례를 찾을 수 있다.

Base predictor는 SimVP 계열의 encoder-decoder 구조다. 하지만 논문은 pixel-wise MSE만 쓰면 고해상도 위성 영상에서 blurry prediction이 생긴다고 보고, adversarial learning을 추가한다.

| Loss | 역할 |
|---|---|
| MSE loss | 예측 frame을 ground-truth future frame과 pixel 단위로 맞춤 |
| Generator adversarial loss | 생성 frame이 실제 future frame처럼 보이도록 유도 |
| Discriminator adversarial loss | real future와 generated future를 구분하도록 학습 |

논문에서 사용한 sampling weight는 다음이다.

| 항목 | 값 |
|---|---:|
| MSE | 0.3 |
| Generator adversarial | 0.6 |
| Discriminator adversarial | 0.1 |

## 8. Graph-Based Candidate Search

모든 DB embedding과 query embedding을 직접 비교하면 실시간 검색이 어렵다. SkySearch는 embedding을 node로 보고, 유사한 embedding끼리 edge로 연결한 k-NN graph를 구성한다.

```text
video embedding -> node
similar embeddings -> edge
query -> best-first graph traversal
```

검색은 best-first 방식으로 진행된다.

| 단계 | 설명 |
|---|---|
| 1 | 임의의 candidate node들을 초기 집합으로 둔다. |
| 2 | query와 가장 유사한 node를 방문한다. |
| 3 | 해당 node의 neighbor를 candidate set에 추가한다. |
| 4 | 현재 top-k보다 충분히 좋지 않은 방향은 threshold로 가지치기한다. |
| 5 | 방문 후보가 없어질 때까지 반복한다. |

이 방식은 approximate nearest neighbor search다. 정확한 전수 비교는 아니지만, 큰 DB에서 빠르게 좋은 후보를 찾는 데 목적이 있다.

## 9. Time-Restricted k-NN과 MBI

기상 분석에서는 "전체 기간에서 유사한 것"보다 특정 시간 구간에서 유사한 것을 찾아야 할 때가 많다. 예를 들어 특정 연도, 계절, 위성 운영 기간 안에서만 검색하는 상황이다.

단순한 방식은 검색 결과를 얻은 뒤 시간 구간 밖의 결과를 버리는 것이다. 하지만 구간이 좁으면 대부분의 후보가 버려져 검색이 느려진다.

SkySearch는 Multi-level Block Indexing(MBI)을 사용한다.

| 아이디어 | 설명 |
|---|---|
| 시간 block | embedding을 timestamp에 따라 block으로 나눈다. |
| 계층 구조 | 인접 block을 묶어 higher-level block을 만든다. |
| block별 graph | 각 block은 자체 graph를 가진다. |
| query interval overlap | query 시간 구간과 겹치는 block에서만 graph traversal을 한다. |
| lazy graph construction | block이 capacity에 도달할 때 graph를 만든다. |

핵심은 시간 제한 조건을 검색 이후 filter로 처리하지 않고, index 구조 안에 직접 반영한다는 점이다.

## 10. Ranking

Candidate search가 반환한 후보들은 기본적으로 query embedding과의 Euclidean distance로 정렬된다. 이 방식은 매우 빠르다.

더 정밀한 ranking이 필요하면 LPIPS, FSIM, SSIM 같은 image similarity metric으로 후보를 다시 정렬할 수 있다.

| Ranking 방법 | 장점 | 단점 |
|---|---|---|
| Embedding distance | 매우 빠르고 기본 배포에 적합 | perceptual refinement는 제한적 |
| LPIPS | 사람의 지각과 잘 맞는 편 | 계산 비용이 큼 |
| FSIM | 구조적 feature 유사도 반영 | 매우 느릴 수 있음 |
| SSIM | 구조적 유사도 평가에 익숙함 | 고해상도 sequence에서는 비용 부담 |

논문은 KMA forecaster와의 논의에서 LPIPS가 기상적으로 의미 있는 pattern과 가장 잘 맞고, 그 다음이 FSIM, SSIM이었다고 설명한다.

## 11. Dataset과 배포 환경

SkySearch는 KMA 환경에서 동작하며, COMS와 GK2A 위성 데이터를 사용한다.

| Satellite | Years | Images | Videos |
|---|---:|---:|---:|
| COMS | 2010-2020 | 837,525 | 295,713 |
| GK2A | 2019-2021 | 292,506 | 209,373 |
| Total | 2010-2021 | 1,130,031 | 505,086 |

데이터 특성은 다음과 같다.

| 항목 | 내용 |
|---|---|
| 지역 | East Asia, Korean Peninsula 중심 |
| 채널 | IR, SWIR, WV |
| 원본 해상도 | 약 1300 x 1500 |
| 전처리 해상도 | 600 x 748 |
| video 길이 | 12 consecutive hourly images |
| 배포 서버 | AMD EPYC 7742 64-Core CPU, 1TB RAM |
| GPU | NVIDIA A100 40GB |

## 12. Search Accuracy 결과

평가는 short-term search accuracy와 long-term search accuracy로 나뉜다.

| 구분 | 의미 |
|---|---|
| Short-term | query에 주어진 첫 12시간과 검색 결과의 첫 12시간 비교 |
| Long-term | query 12시간 + 예측 12시간을 포함한 24시간 비교 |

대표 결과는 다음과 같다. LPIPS는 낮을수록 좋고, FSIM/SSIM은 높을수록 좋다.

| Model | 12h LPIPS | 12h FSIM | 12h SSIM | 24h LPIPS | 24h FSIM | 24h SSIM |
|---|---:|---:|---:|---:|---:|---:|
| EfficientNet fine-tuned | 0.2039 | 0.3479 | 0.2703 | 0.2047 | 0.3476 | 0.2690 |
| VideoMAE pre-trained | 0.2039 | 0.3486 | 0.2712 | 0.2051 | 0.3480 | 0.2692 |
| SkySearch w/o prediction | 0.1943 | 0.3502 | 0.2784 | 0.1974 | 0.3490 | 0.2751 |
| SkySearch w/ prediction | 0.1960 | 0.3495 | 0.2775 | 0.1965 | 0.3494 | 0.2766 |

해석은 단순하다.

| 관찰 | 의미 |
|---|---|
| Prediction 없는 SkySearch | 주어진 12시간 자체와 가장 비슷한 과거 사례를 잘 찾는다. |
| Prediction 있는 SkySearch | 24시간 장기 전개까지 고려할 때 가장 좋은 결과를 낸다. |
| Baseline 대비 | pre-trained/fine-tuned image/video model보다 retrieval 목적에 맞춘 self-supervised embedding이 유리하다. |

## 13. Component Evaluation

Video prediction에서는 adversarial learning을 추가한 SkySearch predictor가 SimVP보다 선명하고 정확한 예측을 만든다.

| 모델 | Average LPIPS |
|---|---:|
| SimVP | 0.3907 |
| SkySearch predictor | 0.2170 |

Candidate search에서는 time-restricted query interval length가 달라져도 높은 QPS를 유지한다. 논문은 recall 99% 이상인 설정만 비교하고, SkySearch가 다음 속도 개선을 보였다고 보고한다.

| 비교 대상 | 조건 | 속도 개선 |
|---|---|---:|
| BSBF | query interval이 넓을 때 | up to 112.50x |
| PyNNDescent | query interval이 좁을 때 | up to 943.87x |

Deep1B 10M vector 실험에서도 SkySearch는 QIL 변화와 무관하게 높은 query speed를 보였다. 다만 Deep1B index size는 18.24GB로 원본 3.92GB보다 약 5배 크다. 속도를 위해 index memory를 쓰는 전형적인 trade-off다.

## 14. Ranking Trade-Off

Appendix의 ranking 비교는 "정확도를 조금 더 얻기 위해 얼마나 느려지는가"를 잘 보여준다.

| Ranking | LPIPS | FSIM | SSIM | Time |
|---|---:|---:|---:|---:|
| Embedding distance | 0.2033 | 0.3482 | 0.2606 | 0.0121s |
| LPIPS | 0.1923 | 0.3522 | 0.2774 | 51.8519s |
| FSIM | 0.1946 | 0.3541 | 0.2728 | 5043.7140s |
| SSIM | 0.1953 | 0.3517 | 0.2822 | 86.9802s |
| LPIPS-Lite | 0.1927 | 0.3524 | 0.2766 | 22.8965s |
| SSIM-Lite | 0.1947 | 0.3519 | 0.2817 | 12.1341s |

Embedding distance는 배포용 기본값으로 적절하다. LPIPS/FSIM/SSIM은 결과를 더 미세하게 다듬을 수 있지만, real-time retrieval에는 계산 비용이 너무 크다.

## 15. Ablation과 추가 분석

Temporal threshold \\(\Delta\\)는 positive/negative pair를 나누는 기준이다. 논문은 여러 variant에서 \\(\Delta = 8\text{ hours}\\)가 가장 낮은 LPIPS를 보여 기본값으로 채택한다.

Video prediction ablation에서는 prediction이 없는 경우 초반 frame에서는 좋을 수 있지만 후반 frame으로 갈수록 성능이 떨어진다. Prediction을 붙인 SkySearch는 24시간 전체에서 안정적인 LPIPS를 유지하고, ground-truth future를 쓴 경우와도 큰 차이가 나지 않는다.

Metric-supervised variant도 비교된다. LPIPS 같은 perceptual metric을 supervision으로 직접 쓰면 더 좋아질 것 같지만, 결과는 self-supervised loss와 거의 비슷하다.

| Model | LPIPS | FSIM | SSIM |
|---|---:|---:|---:|
| EfficientNet fine-tuned | 0.2084 | 0.3471 | 0.2590 |
| Metric-supervised SkySearch | 0.1985 | 0.3500 | 0.2693 |
| SkySearch self-supervised | 0.1978 | 0.3497 | 0.2689 |

논문의 해석은 중요하다. LPIPS는 평가에는 유용하지만, 구름 진화나 태풍 구조 같은 spatiotemporal meteorological dynamics를 supervision으로 직접 표현하기에는 한계가 있다.

## 16. 극한 상황과 한계

Typhoon event에서도 SkySearch는 baseline보다 좋은 결과를 보였다.

| Model | LPIPS | FSIM | SSIM |
|---|---:|---:|---:|
| ResNet pre-trained | 0.2583 | 0.3329 | 0.1724 |
| EfficientNet fine-tuned | 0.2445 | 0.3360 | 0.1861 |
| SkySearch w/ prediction | 0.2334 | 0.3388 | 0.2015 |

하지만 한계도 있다.

| 한계 | 설명 |
|---|---|
| 표준 기상 유사도 metric 부재 | LPIPS/FSIM/SSIM은 proxy일 뿐이다. |
| Scattered cloud prediction | 흩어진 구름 예측에서는 prediction quality가 떨어진다. |
| Index memory | 빠른 검색을 위해 추가 index memory를 사용한다. |
| Prediction uncertainty | 미래 frame이 틀리면 query augmentation이 오히려 검색을 왜곡할 수 있다. |
| Multi-channel integration | 현재 future work로 IR, SWIR, WV를 함께 쓰는 방향을 제시한다. |

## 17. 논문의 핵심 기여

| 기여 | 해석 포인트 |
|---|---|
| 실사용 시스템 | 단순 benchmark가 아니라 KMA 예보 업무에 배포된 retrieval system이다. |
| Label-free embedding | 유사도 label 없이 temporal proximity를 이용해 video representation을 학습한다. |
| Search와 ML의 결합 | neural embedding만으로 끝내지 않고 graph index와 MBI로 real-time search를 만든다. |
| Prediction-based retrieval | 현재 상황의 미래 전개를 예측해 장기 유사 사례 검색으로 확장한다. |
| Domain-specific evaluation | 기상 domain에서 LPIPS가 잘 맞는다는 전문가 논의를 반영한다. |

## 18. 읽을 때 잡아야 할 관점

이 논문은 "새로운 neural network 하나"보다 "도메인 제약을 반영한 전체 검색 시스템"으로 읽는 것이 좋다.

| 관점 | 질문 |
|---|---|
| Representation | temporal proximity만으로 meteorological similarity를 충분히 학습할 수 있는가? |
| Indexing | approximate graph search와 time interval constraint를 어떻게 동시에 만족시키는가? |
| Forecasting workflow | 검색 결과가 forecaster의 판단을 어떻게 보조하는가? |
| Evaluation | LPIPS/FSIM/SSIM이 실제 기상 유사도를 얼마나 잘 대변하는가? |
| Deployment | 속도, memory, update, UI까지 고려했는가? |

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/skysearch/SkySearch.pdf" | relative_url }}" target="_blank" rel="noopener">SkySearch.pdf</a></li>
  <li><a href="https://doi.org/10.1145/3711896.3737263" target="_blank" rel="noopener">DOI: 10.1145/3711896.3737263</a></li>
  <li><a href="https://github.com/geon0325/skysearch" target="_blank" rel="noopener">Code and appendix link from paper</a></li>
</ul>
