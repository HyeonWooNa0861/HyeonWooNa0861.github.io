---
layout: default
date: 2026-11-02 09:44:00 +0900
title: "MutCombinator"
topic: "Frame-aware variant-graph search for combinatorial mutated peptides"
order: 83
major_topic: "Computational Biology & Proteomics"
keywords:
  - "MutCombinator"
  - "Proteogenomics"
  - "Variant graph"
  - "Mutated peptide"
  - "Mass spectrometry"
  - "ISMB 2020"
---

# MutCombinator: identification of mutated peptides allowing combinatorial mutations using nucleotide-based graph search

## 논문 정보

| 항목 | 내용 |
|---|---|
| 저자 | Seunghyuk Choi, Eunok Paek |
| 발표 | ISMB 2020 proceedings, *Bioinformatics* 36(Supplement 1), i203-i209 |
| DOI | 10.1093/bioinformatics/btaa504 |
| 연구 대상 | 여러 변이가 조합된 암 유래 펩타이드를 tandem mass spectrum에서 찾는 proteogenomic search |
| 공개 라이선스 | CC BY-NC 4.0 |

## 한 줄 요약

**MutCombinator는 가능한 변이 펩타이드를 FASTA로 모두 펼치지 않고, 번역 프레임을 기록한 variant graph를 3-amino-acid tag로 직접 탐색해 조합 변이 펩타이드 후보를 찾는다.**

## 핵심 내용

일반적인 맞춤형 단백질 데이터베이스는 변이를 하나씩 반영하거나, 한 유전자 안의 변이가 모두 동시에 존재한다고 가정한다. 가능한 변이 조합을 모두 FASTA로 만들면 조합 수가 급격히 증가한다. 이 논문은 데이터베이스를 먼저 열거하는 대신 **그래프에서 스펙트럼이 지지하는 경로만 탐색**한다.

핵심 장치는 세 가지다. 첫째, transcript와 variant call을 **frame-aware variant graph**로 합친다. 둘째, 스펙트럼에서 추정한 길이 3의 amino-acid tag를 9개 nucleotide index와 연결해 탐색 시작점을 좁힌다. 셋째, 경로를 따라가면서 frame이 무효가 되거나 변이 수가 사용자가 정한 $$n$$을 넘으면 즉시 중단한다. 실험에서는 $$n=3$$을 사용했다.

## 전체 흐름

| 원문 위치 | 핵심 질문 |
|---|---|
| Figure 1, Sections 1-2.3 | 스펙트럼에서 variant graph의 후보 경로를 어떻게 찾는가? |
| Figure 2, Section 2.1 | 서로 다른 transcript와 변이를 합쳐도 올바른 번역 frame을 어떻게 보존하는가? |
| Figure 3, Sections 2.4-3.1 | 기존 검색에서 남은 스펙트럼을 왜 단계별로 다시 검색하는가? |
| Figures 4-5, Sections 3.2-3.3 | Coding 및 noncoding 영역에서 무엇을 추가로 찾았는가? |
| Section 4 | 계산량, false positive, 해석 범위의 한계는 무엇인가? |

## 1. 문제의식: 가능한 서열을 먼저 만들면 조합 수가 폭발한다

하나의 펩타이드에 후보 변이가 여러 개 있으면 가능한 조합은 변이 수에 따라 지수적으로 늘어난다. 기존 variant graph-to-FASTA 방식은 search engine이 읽을 수 있도록 그래프 경로를 미리 서열로 열거한다. 그러나 유전자마다 변이 밀도가 달라 내부 열거 제한값을 직관적으로 정하기 어렵고, coding region에서 in-frame만 볼지 noncoding region에서 세 frame을 모두 볼지도 명확히 제어하기 어렵다.

MutCombinator의 novelty는 **"모든 후보를 먼저 만든 뒤 검색"을 "스펙트럼 tag가 가리키는 그래프 경로만 그때 생성"으로 바꾼 것**이다. 이 구조는 서로 다른 변이 출처를 한 그래프에 합친 상태에서도 최대 변이 수를 펩타이드 단위로 직접 제한할 수 있게 한다.

## 2. Figure 1: spectrum tag에서 candidate peptide까지

![MutCombinator pipeline: frame-aware variant graph construction, 9-nucleotide index, and spectrum-derived 3-amino-acid tag lookup]({{ "/assets/images/research/mutcombinator/figure-1-pipeline.jpg" | relative_url }})

*Figure 1. 저자 원문 그림. CC BY-NC 4.0. 왼쪽 아래 입력으로 graph를 만들고, 위쪽 index를 거쳐, 오른쪽 아래 spectrum tag가 가리키는 경로만 탐색한다.*

그림은 다음 순서로 읽으면 된다.

1. Reference genome, transcript model, variant calls로 variant graph를 만든다.
2. 그래프의 모든 유효 경로에서 9-nucleotide 구간을 읽고, 이에 대응하는 3-amino-acid tag와 위치를 index table에 저장한다.
3. Tandem mass spectrum에서 de novo sequencing으로 길이 3의 amino-acid tag를 추정한다.
4. Index에서 tag의 시작 위치를 찾고 양옆 graph path를 확장한다.
5. 확장한 서열의 theoretical precursor mass가 관측 precursor mass 허용오차에 들어오면 candidate peptide로 남긴다.
6. Candidate spectrum match는 MODa의 PRM spectrum 및 dynamic programming 기반 점수로 평가한다.

3개의 amino acid를 쓰는 이유는 nucleotide로 바꾸면 9개 염기가 되어 짧은 tag보다 위치를 더 강하게 제한하면서도 spectrum에서 추정 가능한 길이를 유지하기 때문이다. 다만 tag 추정이 틀리면 실제 peptide가 검색 시작점에 들어오지 못할 수 있다. Tag filtering은 속도를 얻는 대신 sensitivity에 조건을 추가한다.

## 3. Figure 2: frame-aware graph가 필요한 이유

![Frame-aware variant graph with per-frame transcript bit vectors]({{ "/assets/images/research/mutcombinator/figure-2-frame-aware-graph.jpg" | relative_url }})

*Figure 2. 각 node 아래 F1-F3 bit vector는 해당 frame으로 그 node를 통과할 수 있는 transcript를 기록한다.*

Transcript를 합치면 같은 genome 위치를 공유하는 구간은 하나의 node가 된다. 문제는 서로 다른 exon 구조와 insertion이 합쳐질 때 같은 nucleotide 위치라도 읽는 frame이 달라질 수 있다는 점이다. 논문은 각 node와 frame에 transcript membership을 bit vector로 기록한다.

예를 들어 설명용 F1 bit vector를 `0b00000011`로 두면 transcript 1과 2가 모두 frame 1로 그 node를 통과할 수 있다는 뜻이다. 경로의 유효 frame은 방문한 node들의 bit vector를 bitwise AND 하여 계산한다. AND 결과가 0이면 **처음부터 끝까지 같은 transcript와 frame으로 이어지는 경로가 없으므로** 더 확장하지 않는다.

각 node의 frame 표시는 그 node 안에서 codon이 시작되는 위치를 나타내므로, 앞에서 소비한 nucleotide 수에 맞춰 다음 node의 frame을 추적해야 한다. 특히 insertion·deletion으로 서열의 순길이가 3의 배수가 아닌 만큼 변하면 이후 reading frame이 달라진다. **SNV는 염기 치환이므로 그 자체로 서열 길이나 reading frame을 바꾸지는 않는다.** 이러한 위치·transcript 정보를 함께 추적하지 않으면 서로 다른 transcript 조각을 이어 붙인 생물학적으로 불가능한 peptide가 후보로 들어갈 수 있다.

<details markdown="block">
<summary markdown="span">Derivation: Frame consistency and bitwise intersection</summary>

Node $$v$$의 frame $$f$$에 대해 $$B(v,f)$$를 그 node를 해당 frame으로 지나는 transcript의 집합을 나타내는 bit vector라 하자. 경로 $$P=(v_1,\ldots,v_k)$$가 하나의 transcript와 frame에서 유효하려면 모든 node에 공통으로 존재하는 transcript가 적어도 하나 있어야 한다.

$$
B(P,f)=B(v_1,f_1)\land B(v_2,f_2)\land\cdots\land B(v_k,f_k)
$$

`AND`는 모든 집합의 교집합과 같다. 따라서 $$B(P,f)=0$$이면 공통 transcript가 없고, 그 뒤에 node를 더 붙여도 0이 다시 1이 될 수 없다. 이 때문에 즉시 pruning해도 유효 경로를 잃지 않는다. 이 증명은 frame bit가 정확히 구성됐다는 전제 위에서 성립한다.

</details>

## 4. Candidate generation과 계산량 제어

Index의 각 tag entry는 시작·끝 node, node 내부 위치, gene ID, tag까지 포함된 mutation 수, frame bit vector를 저장한다. Index 생성 중 이미 변이 수가 $$n$$을 초과하거나 frame bit가 0인 tag는 버린다.

Search 단계에서는 tag의 양옆을 따라가며 peptide mass를 늘린다. 다음 두 조건 중 하나가 성립하면 탐색을 중단한다.

- 방문 node의 frame 교집합이 `0b00000000`이 된다.
- 경로에 포함된 mutation 수가 최대 허용값 $$n$$을 넘는다.

이 pruning은 전체 그래프를 무차별 순회하지 않게 하지만, $$n$$을 늘리면 가능한 경로 수가 여전히 빠르게 증가한다. 따라서 MutCombinator는 조합 폭발을 없앤 알고리즘이 아니라 **스펙트럼 tag와 생물학적 frame 제약으로 실제 탐색 범위를 줄인 알고리즘**이다.

## 5. Figure 3: multistage search

![Multistage search for coding and noncoding mutated peptides]({{ "/assets/images/research/mutcombinator/figure-3-multistage-search.jpg" | relative_url }})

*Figure 3. 기존 검색에서 식별되지 않은 스펙트럼을 coding graph에 적용한 뒤, 다시 남은 스펙트럼을 noncoding graph에 적용하는 multistage search다.*

실험은 MSI-high early-onset gastric cancer sample N33T34를 사용했다. PE-MMR 처리된 4,215,882개 MS/MS spectrum과 RNA-seq, WES를 결합했다. 먼저 CustomizedDB와 MS-GF+를 사용한 conventional search에서 588,483 PSM을 얻었다. 남은 spectrum 중 2,792,596개를 coding-region MutCombinator search에 넣었다.

| 설정 | 값 |
|---|---|
| Precursor tolerance | 10 ppm |
| Fragment tolerance | 0.025 Da |
| Fixed modifications | Carbamidomethylation on C; iTRAQ on N-terminus and Lys |
| Enzyme rule | Semi-tryptic, missed cleavage 최대 2 |
| Minimum peptide length | 8 amino acids |
| Maximum mutations | $$n=3$$ |
| Statistical filtering | Coding search에서 wild-type·mutated target/decoy group을 분리해 PSM-level 1% local FDR 적용, scan당 최고 점수만 유지 |

Coding search에서는 wild-type peptide match와 mutated peptide match가 직접 경쟁할 때 한쪽이 불리해지는 문제를 줄이기 위해 두 target/decoy group을 나눈 뒤 각각 1% local FDR을 적용했다. Noncoding search도 그 단계의 결과에 1% local FDR을 적용했지만, 원문은 이를 coding/noncoding search-space 크기의 차이를 보정하는 방법이라고 설명하지 않는다.

## 6. Coding-region 결과

![Coding-region peptide-spectrum-match results and mutation combinations]({{ "/assets/images/research/mutcombinator/figure-4-coding-results.jpg" | relative_url }})

*Figure 4. PSM·peptide·gene 수, pathway 비교, 변이 조합 구성, IGV와 spectrum 근거를 함께 제시한다.*

1% local FDR를 적용한 뒤, UniProt 및 contaminant 대조 전에는 wild-type PSM 8,778개와 mutated PSM 231개가 남았다. 해당 대조에서 제거할 항목을 걸러낸 뒤 coding region의 mutated PSM은 211개였다. 이는 이전 결과에 **mutated peptide 80개, gene 52개, mutation combination 70개**를 추가했다.

70개 조합의 구성은 다음과 같다.

| 변이 조합 | 수 |
|---|---:|
| SNV | 60 |
| INDEL | 6 |
| Double SNV | 3 |
| Double INDEL | 1 |

RHOA, RRBP1, HIST1H3H, LSP1에서는 **exclusively expressed mutation을 지닌 mutated peptide 4개**가 보고됐다. 원문이 자세히 제시한 LSP1 구간의 예는 가까운 sample-specific SNV 두 개를 동시에 품은 peptide 하나가 아니라, 서로 다른 single SNV를 각각 지닌 peptide 두 개다. 그러나 PSM 식별은 변이가 종양 성장의 원인이라는 기능적 증명이 아니다. 별도 검증 없이 driver mutation이나 치료 표적으로 해석하면 안 된다.

## 7. Noncoding-region 결과

![Aberrantly translated peptides in noncoding regions]({{ "/assets/images/research/mutcombinator/figure-5-noncoding-results.jpg" | relative_url }})

*Figure 5. Noncoding search에서 찾은 peptide 유형과 genomic locus·gene·mutation 정보를 보여 준다.*

Noncoding transcript 12,516개를 3-frame translation으로 검색했다. 입력 spectrum 2,773,632개에서 1% local FDR 기준 122 PSM을 얻었고, UniProt 및 contaminant와 일치한 86개를 제거해 36 PSM, 27 peptide가 남았다. 다시 coding region에 mapping되는 13개를 제외한 유형은 다음과 같다.

- Pseudogene-derived peptide 5개
- Frameshift peptide 4개
- Exon-extension peptide 2개
- 5' UTR peptide 2개
- 3' UTR peptide 1개

이 결과는 noncoding annotation 전체가 단백질로 번역된다는 뜻이 아니다. 해당 sample과 search 조건에서 spectrum이 지지한 aberrantly translated peptide 후보를 찾았다는 의미다.

## 8. 기여, 한계, 확장성

**기여.** MutCombinator는 FASTA 열거를 피하고 graph를 직접 탐색하면서, peptide당 최대 mutation 수와 coding/noncoding translation frame을 명시적으로 제어한다. COSMIC처럼 큰 mutation source와 sample-specific variants를 한 그래프에 합쳐도 조합 변이를 탐색할 수 있다는 점이 실용적 기여다.

**한계.** Search time은 $$n$$과 graph의 variant density가 커질수록 증가한다. Tag 기반 pruning은 tag 추정 품질에 의존하고, 넓은 search space는 false-positive 위험을 높인다. 결과는 위암 sample 한 건의 deep proteogenomic dataset에서 평가됐으므로 다른 암종·기기·fragmentation 조건의 재현성은 별도 검증이 필요하다. 또한 PSM-level 1% local FDR은 개별 peptide의 생물학적 기능을 보증하지 않는다.

CustomizedDB/MS-GF+와 MutCombinator는 후보로 검색하는 서열 공간이 크게 다르다. 따라서 이 실험은 기존 검색 뒤에 추가로 식별한 spectrum과 peptide를 보여 주는 비교이며, 동일한 후보 집합에서 정확도나 속도가 전반적으로 우월함을 입증한 비교는 아니다.

**확장 방향.** 더 정교한 tag uncertainty 처리, graph index 압축, 여러 sample에서의 재현성 분석, peptide-level 검증과 targeted MS 확인을 결합하면 후보 수와 생물학적 근거를 함께 개선할 수 있다. 이는 논문의 구조에서 이어지는 연구 방향이며, 원문이 해당 성능 향상을 이미 입증했다는 뜻은 아니다.

## Source Check

원문의 mutation 총수에는 내부 불일치가 있다. Abstract에는 **96,287**이라고 적혀 있지만 Results는 sample-specific 12,688개와 COSMIC 83,873개, 중복 254개를 제시하고 통합 수를 **96,307**로 적는다.

$$
12{,}688+83{,}873-254=96{,}307
$$

따라서 이 글은 계산과 Results 본문의 값이 일치하는 **96,307**을 기준으로 해석한다. 이 차이는 알고리즘 결과를 새로 계산한 정정이 아니라 원문 내부 숫자 불일치를 표시한 것이다.

## 마지막 핵심 정리

- **문제:** 조합 변이 peptide를 FASTA로 모두 열거하면 search space가 폭발한다.
- **방법:** spectrum-derived 3-aa tag로 frame-aware variant graph의 시작점을 찾고, mass·frame·mutation-count 조건을 만족하는 경로만 확장한다.
- **결과:** N33T34 dataset에서 기존 검색에 더해 coding mutated peptide 80개와 여러 noncoding-origin candidate를 제시했다.
- **경계:** PSM은 peptide 존재의 통계적 근거이며 mutation 기능이나 임상적 유용성의 직접 증명은 아니다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/mutcombinator/mutcombinator.pdf" | relative_url }}" target="_blank" rel="noopener">Original paper PDF</a> — CC BY-NC 4.0</li>
  <li><a href="https://doi.org/10.1093/bioinformatics/btaa504" target="_blank" rel="noopener">Publisher page and DOI</a></li>
  <li><a href="https://pmc.ncbi.nlm.nih.gov/articles/PMC7355298/" target="_blank" rel="noopener">PubMed Central full text</a></li>
  <li><a href="https://creativecommons.org/licenses/by-nc/4.0/" target="_blank" rel="noopener">CC BY-NC 4.0 license</a></li>
</ul>
