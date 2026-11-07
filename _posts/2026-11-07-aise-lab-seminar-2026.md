---
layout: post
title: "AISE Lab Seminar 2026"
nav_title: "AISE Lab Seminar 2026"
date: 2026-11-07 13:40:00 +0900
categories: [Events, Research]
tags: [AISE Lab, Research Seminar, Graph Learning, RAG, AI Education, Computer Vision, Deepfake Detection, Edge AI]
major_topic: "Applied AI Research"
keywords: [PS-SGAD, GIN, SupCon, XC-RAG, PBL, WaSR, YOLO, FSFM, WavLM, Deepfake-Eval-2024, Llama, NPU, Prefill, Decode]
description: "Six research posters on graph anomaly detection, disaster-response RAG, AI education, maritime perception, deepfake detection, and edge LLM scheduling."
permalink: /posts/aise-lab-seminar-2026/
section: 26-2-paper-research-seminar
---

> **여섯 발표를 관통하는 질문은 ‘모델을 어디에, 어떤 조건으로 적용할 것인가’다.** 소수 클래스의 표현, 재난 대응 절차, 학습자의 문제 정의, 해상 환경, 실유통 데이터, 엣지 하드웨어처럼 실제 적용 조건을 모델·검색·교육·시스템 설계에 반영한다.

2026년 11월 7일 국민대학교 소프트웨어융합대학원 AISE Lab 세미나에서 다룬 여섯 연구 포스터를 정리한다. 각 발표의 문제의식, 해결 방식, 결과를 원본 그림과 함께 읽고, 제목·저자·공식 발표 목록을 대조해 연결되는 논문을 구분했다.

Source Posters: <a href="{{ '/assets/pdfs/post/26-2-paper-research-seminar/aise-lab-seminar-2026.pdf' | relative_url }}" target="_blank" rel="noopener">AISE Lab Seminar 2026 — Six Posters</a> (6 pages). 공개용 사본은 포스터 2의 연락처만 가렸으며, 연구 내용과 발표자 표기는 유지했다. 아래 수치는 별도 표시가 없으면 포스터의 보고값이다.

## Session Map

| Page | Presenter | Research question | Main approach |
|---|---|---|---|
| 1 | 강다솔 | 드문 이상 서브그래프의 특징을 어떻게 더 잘 학습하는가? | PS-SGAD: GIN, supervised contrastive learning, prototype |
| 2 | 황채아 | 문장이 비슷해도 대응 절차가 다른 매뉴얼을 어떻게 구분하는가? | XC-RAG: 조건 추출과 메타데이터 필터링 |
| 3 | 오성경 | 생성형 AI 도구 사용을 실무 문제 해결로 어떻게 연결하는가? | PBL 기반 문제 정의·프로토타입·피드백 |
| 4 | 정민욱·윤수연 | 해무와 해상 배경 속 물체를 어떻게 구분하는가? | Dehazing, WaSR, YOLO 결합 |
| 5 | 최재민 | 실유통 딥페이크에서 얼굴·음성·정합성을 어떻게 함께 판단하는가? | Face–audio–synchrony fusion |
| 6 | 손현호·윤수연 | LLM 추론의 각 단계에 어떤 엣지 연산 장치를 배정하는가? | NPU prefill과 CPU decode의 이종 스케줄링 |

## 1. PS-SGAD: Learning Rare Anomalous Subgraphs

**발표 제목:** 서브그래프 기반 이상 탐지에서 소수 클래스 표현력 강화를 위한 연구

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-01-ps-sgad.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-01-ps-sgad.jpg' | relative_url }}" alt="PS-SGAD poster with GIN architecture, prototype alignment, and anomaly-ranking results" width="1526" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 1쪽. 가운데의 모델 구조와 아래쪽의 성능·표현 공간 비교를 함께 보면, 분류 경계뿐 아니라 소수 클래스의 임베딩을 개선하려는 목적이 드러난다.</figcaption>
</figure>

### Problem and method

거래 그래프에서 이상 사례가 드물면, 전체 오류를 줄이는 학습만으로는 정상 사례의 특징이 우선 반영되기 쉽다. 이 연구는 **이상 서브그래프를 정상과 구별하는 것에 더해, 이상 클래스 내부의 표현을 일관되게 만드는 문제**에 주목한다. 포스터의 Elliptic2 실험에서는 정상 약 98%, 의심 사례 약 2%라는 불균형을 다룬다. 여기서 ‘의심’이라는 데이터 라벨을 법적으로 확정된 범죄와 동일시해서는 안 된다.

PS-SGAD는 **GIN 인코더, supervised contrastive learning(SupCon), prototype 정렬**을 결합한다. GIN이 서브그래프를 벡터로 만들고, 분류 손실은 라벨 예측을 학습한다. SupCon은 같은 클래스의 표현을 가깝게, 다른 클래스의 표현을 구분되게 만드는 역할을 한다. Prototype 정렬은 기준 표현과의 관계를 추가로 반영한다. 각각 ‘정답을 맞추는가’, ‘표현끼리 어떤 관계를 갖는가’, ‘기준 표현과 얼마나 정렬되는가’를 담당한다.

포스터의 구조도는 64차원 GIN 표현, 별도 projection head, prototype과의 cosine similarity가 분류에 결합되는 흐름을 보여준다. 다만 prototype의 생성·갱신 규칙까지 그림만으로 확정할 수는 없다. 학습 전체를 재현하려면 해당 정의와 손실 가중치를 논문 본문에서 확인해야 한다.

### Results and interpretation

| Setting or metric | Reported value | How to read it |
|---|---|---|
| Graph | 444,521 nodes, 367,137 edges, 43 features | Elliptic2 기반 실험의 입력 규모 |
| Split | Train / validation / test = 70 / 15 / 15 | 포스터에 명시된 분할 비율 |
| AUPRC | GIN+CE 0.4062, PS-SGAD+CE 0.4520 | 정밀도와 재현율의 관계를 요약하는 지표 개선 |
| Precision at top 0.2% | 0.9189 | 가장 의심스러운 상위 후보 집합의 정밀도 |
| NDCG at top 0.2% | 0.9351 | 상위 순위에 관련 사례를 배치한 정도 |

**AUPRC의 절대 증가량은 0.0458, 상대 개선율은 약 11.3%다.** 이를 11.3퍼센트포인트 상승으로 읽으면 안 된다. 정상 비율이 높은 데이터에서는 전체 accuracy만으로 드문 이상 사례의 탐지력을 설명하기 어렵기 때문에, AUPRC와 상위 후보의 정밀도가 연구 목적에 더 직접적으로 연결된다.

표현 공간 그림과 kNN purity 결과는 소수 클래스가 더 일관된 이웃을 갖는다는 해석을 보탠다. 다만 2차원 시각화만으로 고차원 전체의 분리나 개별 구성요소의 인과적 기여가 증명되는 것은 아니다. 손실별 제거 실험과 반복 실험을 함께 보면 개선 원인을 더 명확히 구분할 수 있다.

<details markdown="block">
<summary markdown="span">Loss terms and improvement calculation</summary>

포스터의 결합 손실은 다음과 같다.

$$
\mathcal L_{\mathrm{total}}=\mathcal L_{\mathrm{CE}}+\lambda\mathcal L_{\mathrm{SCL}}+(1-\lambda)\mathcal L_{\mathrm{proto}}.
$$

$$\mathcal L_{\mathrm{CE}}$$는 분류, $$\mathcal L_{\mathrm{SCL}}$$은 supervised contrastive learning, $$\mathcal L_{\mathrm{proto}}$$는 prototype 정렬 항이다. 이 식은 손실의 결합 구조를 나타낸다. 각 항의 구체적 정의·정규화와 $$\lambda$$의 실제 설정은 별도로 확인해야 한다.

보고된 AUPRC 개선을 검산하면 다음과 같다. 두 값은 무차원 지표이며, 아래 백분율은 기준값에 대한 상대 증가율이다.

$$
0.4520-0.4062=0.0458,\qquad
\frac{0.0458}{0.4062}\times100\simeq11.3\%.
$$

</details>

**논문 연결:** [국민대학교 Data Mining Lab의 공식 논문 목록](https://dm.kookmin.ac.kr/publications/){:target="_blank" rel="noopener"}에서 같은 제목의 강다솔·박하명 KCC 2026 발표와 우수논문상 기록을 확인할 수 있다. 포스터의 학위논문 표기와 학회 발표는 버전이 다를 수 있으므로 동일 본문이라고 단정하지 않는다. 이 절의 해설은 포스터를 기준으로 한다.

## 2. XC-RAG: Retrieve the Right Procedure

**발표 제목:** 재난대응 매뉴얼 기반 의미적 검색의 한계 분석과 절차적 구조의 효과 검증

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-02-xc-rag.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-02-xc-rag.jpg' | relative_url }}" alt="XC-RAG poster showing condition extraction, metadata filtering, retrieval, and evaluation" width="1568" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 2쪽의 공개용 사본. 왼쪽 아래의 조건 추출·필터링 순서가 오른쪽 평가표에서 무엇을 개선했는지 설명한다. 연락처는 비공개 처리했다.</figcaption>
</figure>

### Why semantic similarity is not enough

재난 매뉴얼은 여러 상황에서 ‘보고’, ‘대피’, ‘통제’처럼 비슷한 표현을 사용한다. 그러나 같은 단어가 들어 있다고 현재의 재난 유형·대응 단계·행동 주체에 맞는 절차인 것은 아니다. **문장의 유사성과 절차의 적합성은 서로 다른 조건**이다.

설명용으로 지진 직후의 현장 조치를 찾는 상황을 생각할 수 있다. 의미가 비슷하다는 이유로 복구 단계의 문서나 다른 재난의 대피 절차를 가져오면, 문장 자체가 자연스러워도 질문에 맞지 않는 근거가 된다. 이는 포스터의 실험 질문을 그대로 인용한 사례가 아니라 검색 오류의 성격을 설명하는 예다.

XC-RAG(Cross-filtered & Condition-aware RAG)는 먼저 질문에서 **재난 유형, 대응 단계, 행동 정보**를 추출한다. 이어 메타데이터로 후보 문서를 제한하고, 그 안에서 의미 기반 검색을 수행한 뒤 답변을 생성한다. 의미 검색을 없애는 방식이 아니라 **절차 조건으로 검색 범위를 먼저 정하는 방식**이다. 포스터의 다섯 단계 구조도에서 필터링이 similarity retrieval보다 앞에 배치된 이유가 여기에 있다.

### What improved

15종 재난 매뉴얼, 150개 질의, 4단계 대응 절차를 대상으로 평가했다. 구현에는 Ollama·Qwen2.5, RAGFlow, BAAI 계열 로컬 임베딩이 사용된다. 구체적인 임베딩 모델명은 포스터만으로 확정하지 않는다.

| Metric | Baseline RAG | XC-RAG | Meaning |
|---|---|---|---|
| Precision@5 | 0.156 | 0.425 | 상위 다섯 검색 결과 중 관련 결과의 비율 |
| MRR | 0.278 | 0.973 | 첫 관련 결과가 얼마나 앞 순위에 등장하는가 |
| CMA | 0.133 | 1.000 | 포스터에서 사용한 조건 관련 평가 지표 |
| Cross-disaster information mixing | — | 0% | 해당 평가에서 보고한 다른 재난 정보의 혼입 |

MRR 개선은 맞는 근거를 더 앞에서 찾았다는 의미이지 생성 답변의 모든 문장이 사실이라는 뜻은 아니다. CMA는 포스터의 평가 명칭을 유지했으며, 정확한 산식이 확인되지 않아 이를 일반적인 답변 accuracy로 바꾸어 설명하지 않는다. **혼입 0%도 이 평가 집합의 결과**다. 조건 추출이 틀리는 질의와 새로운 유형의 매뉴얼까지 확대 검증하면 검색 필터의 효과와 적용 범위를 더 분명히 알 수 있다.

**관련 발표:** [KICS 2026 Summer 공식 프로그램](https://conf.kics.or.kr/2026s/program){:target="_blank" rel="noopener"}에는 황채아·최재민·윤수연의 「재난대응 매뉴얼 기반 조건 추출형 RAG 모델 설계 및 평가에 관한 연구」가 등재되어 있다(6월 19일, 26A-1). 문제와 저자가 연결되는 발표이지만, 제목이 다르고 본문은 확인하지 못했으므로 이번 포스터와 동일한 실험·버전으로 취급하지 않는다.

## 3. PBL: From AI Tool Use to Problem Solving

**발표 제목:** PBL 기반 생성형 AI 실무교육 모델 개발 및 적용에 관한 연구

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-03-pbl.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-03-pbl.jpg' | relative_url }}" alt="PBL poster showing a five-step AI education model, learner prototypes, and assessment rubric" width="1568" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 3쪽. 교육 설계의 단계, 실제 프로토타입, 평가 배점을 구분해서 읽어야 한다. 평가표의 숫자는 학습자가 얻은 평균 점수가 아니다.</figcaption>
</figure>

### The problem comes before the tool

생성형 AI로 결과물을 만드는 능력과, 자신의 업무에서 해결할 문제를 정의하는 능력은 같지 않다. 이 발표는 비전공 성인·재직 학습자를 대상으로 **문제 정의부터 도구 선택, 기획, 프로토타입, 피드백까지 이어지는 실무교육 과정**을 설계한다.

5 Why, How Might We, persona, problem statement는 각각 증상을 원인으로 좁히고, 해결할 질문을 만들고, 사용자를 구체화하고, 문제를 명료한 문장으로 고정하는 데 쓰인다. 예를 들어 ‘AI 서비스를 만들겠다’는 목표보다 ‘어떤 사용자가 어떤 상황에서 겪는 불편을 줄일 것인가’가 먼저 정해져야 도구와 평가 기준을 선택할 수 있다.

포스터의 과정은 온라인 수업 3회와 비동기 활동을 결합한다. 제출물도 완성 화면 하나로 끝나지 않는다. 기획 문서, 프로토타입, AI 활용 과정 요약, README를 함께 남겨 **무엇을 만들었는지와 어떻게 문제를 풀었는지**를 연결한다.

### How to read the examples and rubric

프로토타입 사례에는 AED 위치·응급 질의응답을 다룬 ‘심장길잡이’, 운동 장소를 다룬 ‘헬스맵 AI’, 음악의 분위기·메타데이터를 다룬 ‘#TagTune’이 제시된다. 사례 그림은 도구 활용이 각자의 서비스 문제로 구체화된 모습을 보여준다. 서비스 효과나 실제 이용 성과를 측정한 결과와는 구분해야 한다.

| Rubric item | Allocated points | What it evaluates |
|---|---|---|
| Functional novelty | 25 | 기능과 문제 해결 방식의 새로움 |
| Interest | 20 | 사용자의 관심을 끄는 정도 |
| Creativity | 30 | 아이디어와 구현의 창의성 |
| User experience | 25 | 사용 흐름과 이용 경험 |

배점 합계는 100점이다. **25·20·30·25는 평가 설계이지 관측된 교육 효과가 아니다.** 포스터는 기획의 명확성·도구 활용 등에 대한 정성적 결과를 제시한다. 학습 효과의 크기까지 판단하려면 참여자 수, 사전·사후 평가, 비교 조건을 함께 확인하는 후속 분석이 필요하다.

**논문 연결:** [KICS 2026 Summer 공식 프로그램](https://conf.kics.or.kr/2026s/program){:target="_blank" rel="noopener"}에서 같은 제목의 오성경·윤수연 발표를 확인했다(6월 19일, 26B-3). 포스터의 발표자 표기는 오성경이며, 윤수연은 외부 학회 기록에서 확인되는 공동저자다. 프로그램 등재는 확인했지만 논문 본문은 확인하지 못했다.

## 4. Maritime Perception: Restore Visibility and Use Context

**발표 제목:** 해안지역의 해무현상으로 인한 저시정 현상 개선 및 미확인 물체 탐지 방안에 대한 정확성 개선 방안

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-04-maritime-perception.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-04-maritime-perception.jpg' | relative_url }}" alt="Maritime perception poster combining dehazing, WaSR water segmentation, and YOLO object detection" width="1573" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 4쪽. 해무 제거 전후 영상과 수면 분할·물체 탐지의 결합이 핵심이다. 시각적 개선 예시와 정량적인 탐지 정확도는 서로 다른 증거다.</figcaption>
</figure>

### Why combine three methods?

해무는 대비와 가시성을 낮추고, 파도·반사광·배경 구조물은 물체처럼 보이는 패턴을 만든다. 따라서 영상이 더 선명해지는 것만으로 오탐이 모두 줄어들지는 않는다. 이 발표는 **시야를 개선하는 단계와 물체가 나타날 공간을 해석하는 단계를 결합**한다.

첫째, dehazing으로 입력의 가시성을 개선한다. 둘째, WaSR 계열 수면 분할과 YOLO 물체 탐지를 결합한다. 셋째, 수면 영역 정보와 탐지 상자의 위치를 대조해 후보를 정리한다. 단순히 ‘상자가 보인다’가 아니라 ‘그 상자가 현재 해상 장면에서 의미 있는 위치에 있는가’를 함께 판단하는 구조다.

수면 분할이 탐지에 보조 정보를 제공하지만, 분할 오류가 나면 실제 표적을 제외할 가능성도 생긴다. 따라서 후속 평가에서는 필터링 전후의 precision·recall을 함께 비교하고, 경계 부근 물체나 작은 물체를 별도로 살펴보는 것이 적절하다. 이는 구조에서 예상되는 검증 항목이며, 포스터에 수치로 입증된 실패율을 뜻하지 않는다.

### Results and paper connection

포스터에는 해무 제거와 탐지의 시각적 결과, YOLOv5와 YOLOv7의 처리 속도 비교에 대한 서술이 있다. 다만 FPS·실행 장치·mAP 등이 함께 제시되어 있지 않아 특정 구현이 일반적으로 더 빠르고 정확하다고 결론내리지는 않는다. 파도와 반사광에 의한 오탐도 후속 개선 대상으로 남는다.

데이터셋 표기에도 확인할 부분이 있다. 포스터에는 ‘MaSTr1478’이 적혀 있으나, [공식 MaSTr1325 자료](https://vicos.si/resources/mastr1325/){:target="_blank" rel="noopener"}는 1,325장 데이터셋을 설명한다. 별도 확장본인지 오기인지 확인되지 않았으므로 데이터 수나 버전을 임의로 맞추지 않는다. 또한 가시광 해상 영상의 수면 물체 탐지와 수중 물체의 광학적 탐지는 구별해야 한다.

**같은 제목의 논문**은 정민욱·윤수연, 『한국통신학회논문지』 50권 4호, 637–646쪽(2025년 4월)에서 확인된다. [공식 학술지 목차](https://journal.kics.or.kr/digital-library/publication?number=4&volume=50){:target="_blank" rel="noopener"}, [DOI: 10.7840/kics.2025.50.4.637](https://doi.org/10.7840/kics.2025.50.4.637){:target="_blank" rel="noopener"}, [KCI 서지·초록](https://www.kci.go.kr/kciportal/ci/sereArticleSearch/ciSereArtiView.kci?sereArticleSearchBean.artiId=ART003194222){:target="_blank" rel="noopener"}을 대조했다. 논문 전체 본문을 확인한 것은 아니므로, 여기의 구체적 파이프라인 해설은 포스터에 근거한다.

WaSR 자체의 방법론은 [저자 측 논문 소개](https://prints.vicos.si/publications/392/wasr-a-water-segmentation-and-refinement-maritime-obstacle-detection-network){:target="_blank" rel="noopener"}에서 더 살펴볼 수 있다. WaSR 원 논문의 기능이 이번 포스터 구현에 모두 사용되었다고 가정하지는 않는다.

## 5. Deepfake Detection: Face, Audio, and Synchrony

**발표 제목:** 얼굴·음성·정합성 통합 멀티모달 모델을 통한 실유통 딥페이크 탐지 성능 향상 연구

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-05-deepfake-detection.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-05-deepfake-detection.jpg' | relative_url }}" alt="Deepfake detection poster with face, audio, synchrony branches and an in-the-wild evaluation" width="1573" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 5쪽. 얼굴·음성의 개별 특징과 입술·음성의 시간적 정합성을 결합한다. 본문의 AUC 0.727은 통합 모델의 최종 결과이며, 정합성 단독 성능과 구분한다.</figcaption>
</figure>

### Why a synchrony branch is useful

학습용 딥페이크와 실제 유통 영상은 압축·편집·녹음 환경이 다르다. 얼굴의 시각적 흔적이나 음성의 음향적 흔적 한 가지만 보면 학습 데이터에서 유효했던 단서가 약해질 수 있다. 이 연구는 **얼굴이 자연스러운가, 음성이 자연스러운가, 두 정보의 시간적 관계가 맞는가**를 함께 사용한다.

입력은 얼굴 16프레임, 입술 16프레임, 16 kHz 음성 4초다. 얼굴·입술에는 FSFM ViT-B 계열 가중치를, 음성에는 WavLM-base+를 사용한다. 입술과 음성 사이의 cross-attention으로 정합성을 추출하고, 이를 얼굴·음성 특징과 결합해 최종 판단을 만든다.

그림의 별도 정합성 경로는 ‘얼굴 점수와 음성 점수를 평균 내는 것’과 다르다. 각각의 입력이 그럴듯해 보여도 **입 모양과 소리의 관계가 어긋나는 단서**를 별도로 학습한다는 의미다. 반대로 인코딩 지연이나 편집으로 생긴 불일치도 있을 수 있으므로, 정합성 자체를 조작 여부의 완전한 증거로 볼 수는 없다.

### Evaluation and the meaning of AUC

| Setting or metric | Reported value |
|---|---|
| Training data | DeepSpeak v2: 10,650; FakeAVCeleb: 2,195 |
| Evaluation | Deepfake-Eval-2024: 1,245 samples, zero-shot |
| Final integrated model AUC | **0.727** |
| Reported accuracy | 68.2% |

**AUC 0.727은 얼굴·음성·정합성을 결합한 최종 모델의 결과다.** 포스터의 정합성 단독 표기와 혼동하지 않도록 구분한다. AUC는 판단 임계값을 바꾸며 진짜·가짜를 순위화하는 능력을 요약한다. 따라서 ‘72.7%의 영상을 맞혔다’는 의미가 아니다. 정답률은 별도 지표인 accuracy로 보고되어 있다.

평가 데이터에 맞춘 추가 학습 없이 모델을 적용했다는 점에서 일반화 성능이 연구의 중심이다. 다만 내부 평가 AUC와 실유통 평가 AUC는 같은 난도의 수치가 아니다. [Deepfake-Eval-2024 원 논문 v1](https://arxiv.org/html/2503.02857v1){:target="_blank" rel="noopener"}의 기존 모델 결과 역시 모달리티·평가 대상·집계 단위가 다를 수 있어, 포스터의 1,245개 표본과 조건을 맞추지 않은 채 직접 우열이나 최고 성능을 주장할 수는 없다.

**관련 발표:** [KICS 2026 Summer 공식 프로그램](https://conf.kics.or.kr/2026s/program){:target="_blank" rel="noopener"}에 최재민·황채아·윤수연의 「멀티모달 정합성 기반 딥페이크 검출을 위한 Cross-Modal Synchronization Transformer 연구」가 등재되어 있다(6월 19일, 26A-3). 관련 주제·저자 기록이지만 이번 통합 모델과 같은 버전인지는 확인되지 않았다. 시각 인코더의 배경은 [FSFM 원 논문](https://arxiv.org/abs/2412.12032){:target="_blank" rel="noopener"}에서 확인할 수 있으며, 이것이 통합 모델의 성능을 별도로 입증하는 근거는 아니다.

## 6. Edge LLMs: Match the Backend to the Phase

**발표 제목:** 엣지 SoC에서 LLM 추론의 Hetero Scheduling과 Phase별 백엔드 효율 분석

<figure>
  <a href="{{ '/assets/images/post/aise-lab-seminar-2026/poster-06-edge-llm.jpg' | relative_url }}" target="_blank" rel="noopener"><img src="{{ '/assets/images/post/aise-lab-seminar-2026/poster-06-edge-llm.jpg' | relative_url }}" alt="Edge LLM poster comparing NPU, CPU, GPU and prefill-decode backend scheduling" width="1562" height="2200" loading="lazy"></a>
  <figcaption>원본 포스터 6쪽. 단계별 지연과 전체 처리량을 분리해서 읽어야 한다. NPU의 명목 연산량만으로 자동회귀 생성 전체의 성능을 예측할 수 없다는 것이 핵심이다.</figcaption>
</figure>

### Prefill and decode have different bottlenecks

LLM은 입력 프롬프트를 처리하는 **prefill**과 다음 토큰을 하나씩 생성하는 **decode**에서 다른 연산 형태를 갖는다. Prefill에서는 여러 입력 토큰을 함께 처리해 큰 행렬 연산의 비중이 커진다. 단일 요청의 decode에서는 토큰마다 가중치와 누적 문맥을 반복해서 사용하므로 메모리 접근과 작은 연산의 실행 효율이 중요해진다.

따라서 NPU의 TOPS가 높다는 사실만으로 decode까지 가장 빠르다고 보장할 수는 없다. 이 발표는 같은 SoC의 NPU·CPU·GPU를 비교하고, **prefill은 NPU, decode는 CPU 2스레드**에 맡기는 결합을 평가한다. 모델 전체에 하나의 연산 장치를 고정하는 대신, 단계별 병목에 맞추어 선택하는 접근이다.

실험에는 Llama 3.2-1B-Instruct, NPU의 RKLLM, CPU의 MNN, Mali-G610 GPU의 MNN OpenCL 백엔드가 제시된다. WikiText-2 기반 입력을 사용하며, 프롬프트 길이 64–3,500, 생성 길이 32–2,048의 조건과 3회 평균을 보고한다. 포스터가 제안하는 QKV projection·attention core 단위의 선택 구상과, 실제 수치로 제시한 prefill/decode 조합은 구분해야 한다.

### Local speedups versus end-to-end throughput

| Comparison | Reported result | Scope |
|---|---|---|
| NPU prefill vs. CPU 4 threads | About 1.6× | Context length 3,500 |
| CPU 2-thread decode vs. NPU | About 1.52× | Context length 3,500 |
| Hybrid throughput gain | 1.04–1.17× | 포스터의 전체 처리량 비교 |
| KV transfer overhead | About 2.1 ms | 단계 전환 시 보고된 비용 |

두 단계가 각각 빨라져도 그 배수를 곱해 전체 향상을 계산할 수는 없다. **입력 처리 시간, 생성 토큰 수, 토큰별 지연, 장치 전환 비용을 모두 더한 시간이 최종 응답 시간을 결정**하기 때문이다. 생성 길이가 짧으면 prefill의 비중이 크고, 길면 decode의 비중이 커진다. 포스터의 생성 길이 32 조건에서 약 1.04배, 256–1,024 조건에서 약 1.17배로 효과가 달라지는 결과도 이 구분으로 읽을 수 있다.

이 결과는 해당 하드웨어·모델·백엔드에서의 조합을 지지한다. 다른 SoC나 동시 요청 수에서도 CPU decode가 항상 유리하다는 법칙은 아니다. 또한 처리 속도 결과만으로 에너지 절감량을 계산할 수는 없으며, 전력·에너지 계측을 추가하면 배터리 기반 서비스의 장단점까지 비교할 수 있다.

**논문 연결:** [KICS 2026 Summer 공식 프로그램](https://conf.kics.or.kr/2026s/program){:target="_blank" rel="noopener"}에서 같은 제목의 손현호·윤수연 발표를 확인했다(6월 19일, 26B-4). 본문을 확인하지 못했으므로 이 글의 세부 수치와 구현 해설은 포스터 기준이다.

## Publication Cross-Check

| Poster | Publication evidence | What is established |
|---|---|---|
| PS-SGAD | 국민대학교 Data Mining Lab 공식 목록, KCC 2026 | 제목·저자·학회 발표 확인. 학위논문과 동일 버전인지는 별도 확인 필요 |
| XC-RAG | KICS 2026 Summer 26A-1 | 관련 저자의 조건 추출형 RAG 발표 확인. 제목이 달라 동일 논문으로 확정하지 않음 |
| PBL | KICS 2026 Summer 26B-3 | 같은 제목·저자 기록 확인. 본문 미확인 |
| Maritime perception | JKICS 50(4), 637–646, DOI·KCI | 같은 제목·저자와 정식 학술지 게재 확인. 서지·초록 대조, 전체 본문 미확인 |
| Deepfake detection | KICS 2026 Summer 26A-3 | 정합성 기반 관련 발표 확인. 이번 통합 모델과 동일 버전인지는 미확인 |
| Edge LLM scheduling | KICS 2026 Summer 26B-4 | 같은 제목·저자 기록 확인. 본문 미확인 |

학회 프로그램에서 제목을 찾았다는 사실과 논문 전체를 읽었다는 사실은 다르다. 같은 제목은 연결 근거가 되지만, 포스터와 논문의 실험 설정이 일치하는지는 본문 대조가 필요하다. 관련 제목만 확인된 경우에는 ‘같은 논문’ 대신 ‘관련 발표’로 구분했다.

## Key Takeaways

- **표현 학습:** PS-SGAD는 드문 이상 사례를 분류하는 데 그치지 않고 소수 클래스의 임베딩 관계를 다룬다.
- **검색:** XC-RAG는 문장의 의미적 유사성에 앞서 대응 절차의 조건을 맞춘다.
- **교육:** PBL 과정은 생성형 AI 도구 사용을 문제 정의·프로토타입·피드백으로 연결한다.
- **인식:** 해상 탐지는 가시성 개선과 수면이라는 장면 정보를 함께 활용한다.
- **일반화:** 딥페이크 탐지는 개별 모달리티와 정합성을 결합하고 실제 유통 환경에서 평가한다.
- **시스템:** 엣지 LLM은 명목 TOPS보다 단계별 병목과 전체 지연을 기준으로 백엔드를 선택한다.

서로 다른 연구지만, 공통점은 **실제 사용 조건을 먼저 정의하고 그 조건에 맞는 구성요소를 설계·평가한다는 점**이다. 성능 수치는 데이터와 평가 조건을 함께 읽을 때 의미가 분명해진다.

## Sources

1. <a href="{{ '/assets/pdfs/post/26-2-paper-research-seminar/aise-lab-seminar-2026.pdf' | relative_url }}" target="_blank" rel="noopener">AISE Lab Seminar 2026 — Six Posters</a>, 2026-11-07, pp. 1–6. 사용자 제공 행사 자료의 연락처 비식별 공개용 사본.
2. [Kookmin University Data Mining Lab — Publications](https://dm.kookmin.ac.kr/publications/){:target="_blank" rel="noopener"}. PS-SGAD의 KCC 2026 제목·저자·수상 기록.
3. [KICS 2026 Summer — Official Program](https://conf.kics.or.kr/2026s/program){:target="_blank" rel="noopener"} 및 [Program PDF](https://conf.kics.or.kr/2026s/downloadProgram?type=program){:target="_blank" rel="noopener"}. 2026-06-19, sessions 26A·26B의 발표 제목·저자 기록.
4. 정민욱·윤수연, [해안지역의 해무현상으로 인한 저시정 현상 개선 및 미확인 물체 탐지 방안에 대한 정확성 개선 방안](https://doi.org/10.7840/kics.2025.50.4.637){:target="_blank" rel="noopener"}, JKICS 50(4), 637–646, 2025. 서지·초록 확인.
5. [MaSTr1325 — Official Dataset](https://vicos.si/resources/mastr1325/){:target="_blank" rel="noopener"}. 포스터 데이터셋 표기와의 대조 자료.
6. Bovcon and Kristan, [WaSR: A Water Segmentation and Refinement Maritime Obstacle Detection Network](https://prints.vicos.si/publications/392/wasr-a-water-segmentation-and-refinement-maritime-obstacle-detection-network){:target="_blank" rel="noopener"}, DOI: 10.1109/TCYB.2021.3085856. 구성 방법의 배경 자료.
7. [Deepfake-Eval-2024, arXiv:2503.02857v1](https://arxiv.org/html/2503.02857v1){:target="_blank" rel="noopener"}. 실유통 평가와 모달리티별 비교 조건, Table S4.
8. [FSFM, arXiv:2412.12032](https://arxiv.org/abs/2412.12032){:target="_blank" rel="noopener"}, CVPR 2025. 얼굴 표현 인코더의 배경 자료.
