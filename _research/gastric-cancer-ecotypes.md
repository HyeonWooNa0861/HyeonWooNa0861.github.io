---
layout: default
date: 2026-11-02 09:43:08 +0900
title: "Gastric Cancer Ecotypes"
topic: "A 15-layer multi-omics analysis of gastric cancer ecotypes"
order: 84
major_topic: "Computational Biology & Proteomics"
keywords:
  - "Gastric cancer"
  - "Tumor ecotypes"
  - "Multi-omics"
  - "Tumor microenvironment"
  - "Proteogenomics"
---

# A 15-Layer Multi-Omics Analysis of Gastric Cancer Ecotypes Provides Therapeutic Insights

Official article: <a href="https://doi.org/10.1016/j.xcrm.2026.102756" target="_blank" rel="noopener">Publisher page and DOI</a> · <a href="https://pmc.ncbi.nlm.nih.gov/articles/PMC13198309/" target="_blank" rel="noopener">PubMed Central full text</a>

## 논문 정보

| 항목 | 내용 |
|---|---|
| 출처 | Cell Reports Medicine 7(5), 102756, 2026 |
| DOI | 10.1016/j.xcrm.2026.102756 |
| 저자 | Yuefan Wang, Lindsey K. Olsen, Fenglong Jiao 외, Clinical Proteomic Tumor Analysis Consortium |
| 분석 표본 | 치료 전 비분문부 원발성 위선암 165개와 paired NAT 41개 등록; 품질 관리 후 종양 159개와 NAT 30개 분석 |
| 핵심 방법 | 15개 오믹스 층 통합, 세포 상태 deconvolution, 종양 생태형 분류, 표적 후보 우선순위화 |
| 공개 라이선스 | CC BY-NC-ND 4.0 |

## 한 줄 요약

이 연구는 유전체 아형만으로 설명하기 어려운 위암의 차이를 종양세포·면역세포·기질세포의 조합인 **생태형(ecotype)**으로 다시 분류하고, 15개 오믹스 층을 연결해 생태형마다 다른 조절 프로그램과 치료 표적 후보를 찾는다.

## 핵심 내용

같은 MSI, CIN 또는 genomically stable 아형 안에서도 면역세포와 기질세포의 구성은 다를 수 있다. 논문은 bulk RNA-seq에서 71개 세포 상태의 상대량을 추정하고, 함께 나타나는 종양 미세환경 프로그램을 이용해 C1–C6 여섯 생태형을 정의했다. 이 분류는 기존 유전체·조직학 분류를 없애는 대체물이 아니라, **같은 유전체 아형 내부의 미세환경 차이를 추가로 구분하는 층**이다.

15개 오믹스 층은 유전체 변이부터 전사체, 단백질, 번역 후 변형, 단백질 상호작용, 대사체와 미생물군까지 연결한다. 이 통합 분석은 생태형별 경로와 표적 후보를 제시하지만, 곧바로 환자별 치료법이 검증됐다는 뜻은 아니다. 연구 자체가 자원 구축과 가설 생성에 초점을 두며, 구체적 치료 가설의 기능·임상 검증은 후속 과제로 남긴다.

## 전체 흐름

| 순서 | 분석 단계 | 핵심 질문 |
|---:|---|---|
| 1 | 15-layer atlas | 한 종양을 어떤 분자 층에서 동시에 관찰했는가? |
| 2 | Cell-state deconvolution | Bulk RNA-seq에서 종양·면역·기질 세포 상태를 어떻게 추정했는가? |
| 3 | Ecotype clustering | 함께 나타나는 세포 상태가 어떤 미세환경 구조를 만드는가? |
| 4 | Cross-layer interpretation | 생태형별 전사, 신호, PTM, 상호작용, 대사와 미생물 특징은 무엇인가? |
| 5 | Target prioritization | 단백질 양과 PTM 이상을 세포 계통·생태형 맥락에서 어떻게 표적 후보로 좁혔는가? |

## 문제 배경: 유전체 아형만으로는 부족하다

위암은 종양세포의 변이뿐 아니라 면역세포, 섬유아세포, 혈관과 미생물군이 함께 만드는 환경도 크게 다르다. 기존 TCGA 분류는 EBV, MSI, CIN, GS 같은 유전체 특성을 잘 구분하지만, 같은 아형 안에 서로 다른 면역 활성도와 기질 구성이 섞일 수 있다. 이런 차이는 예후와 면역관문억제제 반응을 해석할 때 중요하다.

논문의 novelty는 세 가지 분석을 한 흐름으로 묶은 데 있다.

1. 15개 분자 층에서 385,000개가 넘는 고신뢰 특징을 구축한다.
2. 세포 상태 조합으로 여섯 종양 생태형을 정의해 기존 아형 안의 미세환경 차이를 드러낸다.
3. 단백질·PTM 이상을 생태형과 세포 계통에 다시 연결해 맥락 의존적인 치료 표적 후보를 우선순위화한다.

## 15개 오믹스 층이 맡는 역할

| 정보 층 | 관찰 대상 | 이 연구에서 연결한 질문 |
|---|---|---|
| WGS·WES | 체세포 변이와 copy-number alteration | 어떤 유전적 변화가 반복되는가? |
| DNA methylation | 후성유전 조절 | 유전자 억제·활성과 연결되는 변화가 있는가? |
| RNA·miRNA | 전사량과 전사 후 조절 | 어떤 세포 상태와 경로가 활성화되는가? |
| Global proteome | 실제 단백질 양 | RNA 변화가 단백질 수준에서도 유지되는가? |
| Phosphorylation·acetylation·ubiquitination·glycosylation | 단백질 상태와 활성 조절 | 양이 같아도 활성·분해·표면 epitope가 달라지는가? |
| XL-MS | 단백질 간 물리적 접촉 | 종양 맥락에서 어떤 상호작용이 나타나는가? |
| Metabolomics | 대사산물 | 생태형별 대사 프로그램은 무엇인가? |
| WGS·RNA 기반 microbiome | 조직 연관 미생물 | 미생물군이 생태형·대사·내성 경로와 연관되는가? |

위 표는 15개 층을 기능별 큰 범주로 묶은 것이며, 각 행이 원문의 한 층과 일대일로 대응하지는 않는다. 품질 관리 후 159개 종양과 30개 인접 정상 조직이 남았다. 유전체가 분석된 종양 157개에서는 TCGA 아형이 EBV-positive 8%, MSI 19%, CIN 35%, GS 38%로 나타났다. 이 비율은 표본 구성과 분석 조건에 따른 관찰값이며 다른 인구집단의 고정 비율로 일반화하면 안 된다.

단백질과 RNA 사이 중앙 Spearman 상관은 0.41이었다. PTM과 단백질의 상관도 0.22–0.44로 제한적이었다. 따라서 RNA만 측정하면 단백질의 활성 상태, 분해 표지와 glycosylation 같은 변화를 놓칠 수 있다는 것이 여러 오믹스 층을 함께 측정한 직접적인 이유다.

## 종양 생태형을 만드는 과정

연구진은 bulk RNA-seq deconvolution으로 epithelial, stromal, immune 계열을 포함한 71개 세포 상태의 상대량을 추정했다. 이 71개 상태 전체를 이용한 consensus clustering으로 C1–C6 여섯 생태형을 구분했다. 별도로, 생태형 사이에서 유의하게 달라지는 37개 세포 상태의 공존 관계에서 다섯 미세환경 프로그램을 정의했다. 따라서 여섯 생태형은 표본의 분류이고, 다섯 프로그램은 각 생태형을 특징짓는 세포 상태의 조합이다. 두 개수를 같은 분류 단계로 읽으면 안 된다. 이 관계는 원문 Figure 3과 해당 분석 방법에 대응한다.

| 생태형 | 두드러진 미세환경 특성 | 논문에서 보고한 해석 |
|---|---|---|
| C1 | Immunoregulatory + angiogenic immunosuppressive, 높은 기질 함량 | 가장 불리한 예후와 연결되고 EMT·diffuse 특성이 풍부함 |
| C2 | Angiogenic immunosuppressive 우세 | C1과 혈관·면역억제를 공유하지만 immunoregulatory 프로그램은 약함 |
| C3 | Naive-primed immune | 면역세포가 있으나 활성은 제한된 상태 |
| C4 | Transitional interface, 높은 종양 순도 | 증식성 epithelial 프로그램이 강함 |
| C5 | Immune effector-enriched + naive-primed immune | 면역 침윤이 높고 PD-L1·IDO1 및 MSI 관련 특징이 나타남 |
| C6 | AGR2-positive epithelial cell enrichment | 드문 epithelial 중심 상태 |

외부 위암 데이터 다섯 개에 분류기를 적용한 생존 분석에서는 C1의 예후가 가장 불리했고 C4–C6이 상대적으로 유리했다. 연령, 성별, 병기와 Lauren 아형을 조정한 Cox 회귀에서도 생태형은 독립적인 예측 변수로 보고됐다. 그러나 발견 코호트 자체의 장기 생존 자료는 충분하지 않았고, 외부 자료에는 상세 치료 정보가 없었다. 따라서 생태형이 특정 치료의 효과를 직접 예측한다고 단정할 수 없다.

### 같은 MSI라도 생태형이 다른 이유

MSI는 면역관문억제제와 관련된 유전체 biomarker지만, 논문에서는 MSI 종양의 45%가 발견 코호트에서 C5가 아닌 다른 생태형에 속했다. TCGA/ACRG에서도 이 비율은 47%였다. C5-MSI 종양은 다른 MSI 종양보다 gene-expression 기반 PredictIO 점수가 높았다.

이 결과는 **MSI가 종양의 변이 상태를 말하고, 생태형은 그 종양을 둘러싼 세포 구성과 활성 상태를 말한다**는 차이를 보여준다. 다만 PredictIO는 실제 치료 반응 자체가 아니라 반응 가능성을 추정하는 expression signature다. 임상 반응 검증 없이 C5-MSI 환자에게 특정 치료가 더 효과적이라고 결론 내릴 수 없다.

## 번역 후 변형과 단백질 상호작용: 양이 같아도 기능은 다르다

Figure 4의 질문은 `어떤 단백질이 많은가?`에서 끝나지 않는다. 연구진은 phosphorylation, acetylation, ubiquitination, glycosylation을 단백질 양과 함께 비교하고, XL-MS로 단백질 사이의 물리적 접촉도 추적했다. RNA-단백질 중앙 상관이 0.41이고 PTM-단백질 상관도 0.22–0.44에 머문 결과는, 전사량이나 총 단백질 양만으로 활성 상태와 상호작용을 대체할 수 없음을 보여준다.

이 분석은 생태형마다 다른 신호 전달과 세포 계통을 연결하는 데 유용하다. 다만 PTM 또는 XL-MS 연관은 인과관계가 아니다. 특정 변형이나 접촉이 종양 성장을 일으킨다고 말하려면 별도의 perturbation 실험이 필요하다.

## 대사체: 분자층으로 농도를 얼마나 설명할 수 있는가

Figure 5에서는 다른 오믹스 층과 연관된 대사체 220개 가운데 정량 가능한 예측 변수를 가진 114개를 모델링 대상으로 삼았다. 각 대사체의 농도를 설명하도록 회귀 모델을 학습한 뒤 교차검증으로 평가했고, 그중 51개가 견고한 예측 기준을 충족했다. 여기서 `예측`은 새로운 환자의 치료 반응을 맞혔다는 뜻이 아니라, 유전체·전사체·단백질·미생물 특징의 조합이 해당 대사체 농도의 표본 간 차이를 재현했다는 뜻이다.

이 결과는 대사 상태가 하나의 유전자보다 여러 분자층의 합성 결과임을 보여준다. 모델의 높은 설명력도 인과 방향을 정하지는 않는다. 대사체가 분자 프로그램의 결과인지, 반대로 그 프로그램을 조절하는지는 후속 실험이 필요하다.

## 조직 연관 미생물: 오염을 줄인 뒤 남은 연관성

Figure 6에서는 WGS와 RNA 데이터에서 미생물 신호를 추정하고, 실험·환경 오염 가능성을 단계적으로 걸러 두 데이터 유형이 함께 지지하는 315종을 남겼다. 이후 종별 풍부도를 생태형, 대사체, 단백질 경로와 연결했다. 이렇게 DNA와 RNA의 교집합을 요구한 것은 낮은 생체량 종양 조직에서 생길 수 있는 위양성을 줄이기 위한 보수적 선택이다.

그러나 이는 위 조직에서 살아 있는 미생물을 배양하거나 공간적으로 확인한 결과가 아니다. 관찰된 연관성만으로 특정 미생물이 생태형이나 치료 내성을 유발한다고 결론 낼 수 없다.

## 치료 표적 후보: 생태형 맥락에서 outlier를 찾는다

생태형별 분자 분석은 분류표를 생물학적 프로그램과 연결한다.

- C1은 EMT, angiogenesis와 hypoxia를 포함한 기질 경로가 강했다.
- C4는 증식과 생합성 신호가 두드러졌다.
- C5는 면역 관련 프로그램이 넓게 활성화되고 일부 대사 경로는 억제됐다.

표적 탐색에서는 전체 종양-정상 평균 차이만 보지 않고, 일부 종양에서 반복적으로 매우 높은 단백질 또는 PTM을 outlier로 찾았다. 종양의 77%에서 ERBB2, TROP2, CEACAM5, MUC1, FOLR1 등을 포함한 기존 항체·T-cell 표적 23개 중 하나 이상이 높은 outlier로 나타났다.

Glycoform 분석은 단백질 양만 볼 때 놓치는 후보를 추가했다. 예를 들어 COL1A2와 COL5A2는 단백질 수준의 높은 outlier가 각각 12개와 14개 표본이었지만, site-specific glycoform outlier는 70개와 69개 표본에서 관찰됐다. 즉 표면 단백질의 총량이 크게 변하지 않아도 glycan 구조가 바뀌면 표적의 노출과 특성이 달라질 수 있다.

연구진은 세포주 CRISPR dependency 자료와 단백질·인산화 outlier를 결합해 세포 내 표적 후보 21개도 제시했다. 이는 후보를 좁히는 계산적 우선순위이지 약물 효능이나 안전성의 검증 결과가 아니다.

## 결과를 읽을 때 지켜야 할 경계

| 논문이 보여준 것 | 아직 보여주지 못한 것 |
|---|---|
| 여러 분자 층과 세포 상태를 연결한 위암 atlas | 이 분류를 이용한 전향적 치료 선택의 임상 효용 |
| 외부 코호트에서 재현된 생태형 패턴과 예후 연관 | 치료 종류별 생태형-효과 상호작용 |
| 생태형·세포 계통별 표적 후보의 우선순위 | 후보 표적의 기능적 인과성과 환자 치료 효과 |
| Bulk 자료에서 추정한 세포 상태 조합 | 공간적으로 직접 확인한 안정된 생태 단위 |

발견 코호트는 동유럽 환자가 대부분이었다. 정량적 연관성을 다른 ancestry와 의료 환경에 일반화하려면 더 넓은 multi-ancestry 연구가 필요하다. 생태형은 통합 분자 특징으로 추론됐으므로 single-cell과 spatial profiling을 통한 직접 검증도 필요하다. XL-MS와 깊은 PTM 분석은 새로운 연결을 제시하지만 임상 표본에서의 민감도와 분석 재현성도 더 검증해야 한다.

확장 방향은 생태형을 고정된 여섯 라벨로만 사용하는 것이 아니라, 공간·단일세포 측정으로 구성 세포를 확인하고 전향적 치료 코호트에서 시간에 따른 변화를 추적하는 것이다. 후보 표적은 organoid, 동물 모델과 임상 표본에서 기능·선택성·독성을 검증한 뒤에야 치료 전략으로 평가할 수 있다.

## 논문의 핵심 기여

- 위암의 15개 오믹스 층을 하나의 분석 자원으로 통합했다.
- 유전체 아형 안의 미세환경 차이를 C1–C6 생태형으로 구분했다.
- RNA, 단백질, PTM, 상호작용, 대사체와 미생물군을 생태형 프로그램으로 연결했다.
- 단백질 양만이 아니라 glycoform과 phosphorylation을 포함해 표적 후보를 넓혔다.
- 표적 후보를 생태형·유전체 아형·세포 계통 맥락에서 해석했다.

## 해석 포인트

이 논문의 중심은 새로운 단일 classifier보다 **서로 다른 해상도의 생물학 정보를 같은 종양 생태계 안에서 연결하는 방법**이다. 유전체는 종양세포가 가진 변화, deconvolution은 주변 세포 구성, proteome과 PTM은 실제 기능 상태, metabolome과 microbiome은 환경의 결과와 연관성을 각각 보여준다.

따라서 결과를 읽을 때도 `변이 발견 = 치료 표적 확정`으로 건너뛰지 않아야 한다. 논문이 강한 부분은 가설을 만들 후보와 맥락을 정밀하게 제공하는 것이다. 약물 선택과 환자 예후 개선은 별도의 기능·전향적 임상 검증이 필요한 다음 단계다.

## 참고자료

<ul>
  <li><a href="https://doi.org/10.1016/j.xcrm.2026.102756" target="_blank" rel="noopener">Publisher page and DOI</a></li>
  <li><a href="https://pmc.ncbi.nlm.nih.gov/articles/PMC13198309/" target="_blank" rel="noopener">PubMed Central full text</a></li>
  <li><a href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank" rel="noopener">CC BY-NC-ND 4.0 license</a></li>
</ul>
