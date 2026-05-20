---
layout: default
title: "Time-Restricted kNN Search with MBI"
topic: "Multi-Level Block Indexing for high-dimensional filtered kNN"
order: 3
---

# Efficient Time-Restricted kNN Search with MBI

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Efficient Time-Restricted kNN Search in High-Dimensional Data Using Multi-Level Block Indexing, with Extensions to Multi-Attribute Filtering |
| 저자 | Jisoo Kang, Changhun Han, Suji Kim, Ha-Myung Park |
| 저널 | ACM Transactions on Knowledge Discovery from Data, Vol. 20, No. 3, Article 41 |
| 발행 | February 2026 |
| DOI | `10.1145/3789265` |
| 키워드 | k-Nearest Neighbor Search, Spatio-temporal Data, High-Dimensional, Time-Restricted kNN Search, Multi-Attribute Filtering |
| 코드/데이터 | `https://github.com/kjsoo-1010/mbi2025` |

## 한 줄 요약

이 논문은 시간이 계속 누적되는 고차원 벡터 데이터에서 특정 시간 구간 안의 approximate kNN을 빠르게 찾기 위해, timestamp 기반 계층 블록마다 graph index를 두는 Multi-Level Block Indexing(MBI)을 제안하고 이를 다중 수치 속성 필터링 문제로 확장한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 일반 ANN index만으로 time-restricted kNN을 처리하기 어려운가? |
| 2 | 문제 정의 | T kNN과 m-AkNN은 어떤 조건부 kNN 문제인가? |
| 3 | 단순 접근 | BSBF와 SF는 각각 어떤 구간에서 느려지는가? |
| 4 | MBI 구조 | 시간을 기준으로 block tree를 만들면 무엇이 좋아지는가? |
| 5 | 삽입 | 새 데이터가 시간순으로 들어올 때 index를 어떻게 갱신하는가? |
| 6 | 질의 처리 | query window에 맞는 block set을 어떻게 고르는가? |
| 7 | 다중 속성 확장 | timestamp 하나에서 여러 수치 속성 constraint로 어떻게 확장하는가? |
| 8 | 복잡도 | index size, indexing time, query time은 어떻게 해석되는가? |
| 9 | 실험 | 어떤 dataset에서 얼마나 빨라졌는가? |
| 10 | 한계 | update, deletion, optimality 분석에는 어떤 과제가 남는가? |

## 1. 문제 배경

현대 데이터는 시간이 지나며 계속 쌓인다. 위성 이미지, 음악 트랙, 유튜브 영상, SNS 사진처럼 새 항목이 지속적으로 추가되고, 각 항목은 보통 embedding vector로 표현된다.

일반 kNN search는 query vector와 가까운 항목을 찾는다.

```text
query vector w
-> nearest vectors in whole database D
```

하지만 실제 검색에서는 전체 DB가 아니라 특정 기간 안에서만 찾고 싶을 때가 많다.

```text
"1980년부터 1995년 사이에 개봉한 영화 중 Zootopia와 가장 비슷한 5개"
"2010년 1월부터 2011년 5월 사이에 찍은 사진 중 현재 사진과 가장 비슷한 10개"
```

이런 질의는 similarity 조건과 time window 조건을 동시에 만족해야 한다. 논문은 이를 Time-Restricted kNN, 줄여서 T kNN 문제로 정의한다.

## 2. 문제 정의

데이터베이스는 timestamp가 붙은 벡터 집합이다.

```text
D = {(v, t)}
v in R^d, t in T
```

시간 구간 `[t_a, t_b)`에 속한 데이터만 모으면 다음처럼 쓴다.

```text
D[t_a : t_b] = {(v, t) in D | t_a <= t < t_b}
```

T kNN query는 다음 형태다.

```text
q = (w, k, t_s, t_e)
```

| 기호 | 의미 |
|---|---|
| `w` | query vector |
| `k` | 반환할 이웃 수 |
| `t_s`, `t_e` | 검색할 시작/끝 timestamp |
| `D[t_s : t_e]` | 시간 조건을 만족하는 후보 집합 |

목표는 `D[t_s : t_e]` 안에서 `w`와 가장 가까운 `k`개를 찾는 것이다.

논문은 이를 더 일반화해 m-Attribute Filtering kNN, 즉 m-AkNN도 정의한다. timestamp 하나가 아니라 나이, 키, 몸무게, 논문 인용수, 출판일처럼 여러 수치 속성에 범위 조건을 걸고 kNN을 수행하는 문제다.

```text
q = (w, k, a_lower, a_upper)
```

T kNN은 filtering attribute가 timestamp 하나인 `m = 1` 특수 사례로 볼 수 있다.

## 3. 단순 접근의 한계

논문은 먼저 두 가지 직관적인 baseline을 설명한다.

| 방법 | 핵심 아이디어 | 강한 구간 | 약한 구간 |
|---|---|---|---|
| BSBF | timestamp 정렬 후 binary search로 시간 구간을 찾고, 그 안에서 brute-force kNN 수행 | query time window가 짧을 때 | query time window가 길 때 |
| SF | 전체 graph-based ANN index를 탐색하면서 시간 조건을 만족하는 후보만 모음 | query time window가 넓을 때 | query time window가 좁을 때 |

BSBF(Binary Search and Brute-Force)는 시간 구간을 빠르게 찾지만, 구간이 커지면 결국 많은 벡터와 query distance를 직접 계산해야 한다.

SF(Search and Filtering)는 기존 graph-based approximate kNN index를 그대로 활용한다. 하지만 시간 구간이 좁으면 탐색 중 만나는 대부분의 후보가 filter out된다. 결과 `k`개를 채울 때까지 탐색 범위를 크게 넓혀야 하므로 느려진다.

m-AkNN에서는 BSBF가 AFBF(Attribute-Filtering Brute-Force)로 바뀐다. 여러 속성에는 timestamp처럼 간단한 binary search를 적용하기 어렵기 때문에, 먼저 전체 데이터에서 속성 조건을 brute-force로 검사하고 그 결과 안에서 kNN을 수행한다.

## 4. MBI의 핵심 아이디어

MBI는 BSBF와 SF의 장단점을 block tree로 절충한다.

```text
timestamp-sorted vectors
-> leaf blocks
-> merged parent blocks
-> root block
```

각 block은 두 가지를 가진다.

| 구성 | 의미 |
|---|---|
| vector set | 해당 block의 timestamp 범위에 속한 데이터 |
| graph index | block 내부에서 approximate kNN을 빠르게 수행하기 위한 graph-based index |

root block은 전체 데이터를 담고, leaf block은 최대 `S_L`개 정도의 작은 데이터만 담는다. 중간 block은 인접한 child block을 합친 timestamp 구간을 표현한다.

이 구조의 직관은 다음과 같다.

| query time window | 선택되는 block 경향 | 동작 느낌 |
|---|---|---|
| 짧은 구간 | 작은 block | BSBF처럼 불필요한 전체 탐색을 피함 |
| 긴 구간 | 큰 block | SF처럼 graph search의 장점을 사용 |
| 중간 구간 | 크고 작은 block 조합 | 시간 범위를 덮는 적절한 block set에서 검색 |

핵심은 시간 제한을 검색 후 filter로 처리하지 않고, index 구조 자체에 반영한다는 점이다.

## 5. MBI의 삽입 방식

T kNN 설정에서 데이터는 timestamp가 증가하는 순서로 들어온다고 가정한다. 새 vector가 들어오면 최신 leaf block에 추가된다.

| 상황 | 처리 |
|---|---|
| 최신 leaf block이 아직 가득 차지 않음 | 해당 block에 vector 추가 |
| leaf block이 가득 참 | 새 leaf block 생성 |
| leaf block이 `S_L`개를 채움 | 해당 leaf의 graph index 생성 후 ancestor block을 bottom-up으로 merge |

bottom-up merge는 child block의 vector set을 합쳐 parent block을 만들고, parent block의 graph index를 새로 만든다. 논문은 block 번호를 postorder traversal 순서로 부여해 sibling과 parent를 효율적으로 찾는다.

중요한 점은 각 block의 graph index가 독립적으로 만들어진다는 것이다. 따라서 여러 block의 index construction은 병렬화하기 쉽다.

## 6. Query Processing

MBI query는 두 단계로 볼 수 있다.

```text
1. query time window를 덮는 search block set 선택
2. 각 block에서 kNN search 수행 후 결과 merge
```

block 선택은 overlap ratio로 결정된다.

```text
overlap ratio = query window와 block window가 겹치는 비율
```

논문은 threshold `tau`를 사용한다.

| 조건 | 처리 |
|---|---|
| overlap ratio가 0 | 해당 block 제외 |
| leaf block이거나 overlap ratio가 `tau` 이상 | 해당 block 선택 |
| non-leaf이고 overlap ratio가 `tau`보다 작음 | child block으로 내려감 |

`tau`는 block 선택의 보수성을 조절한다.

| `tau` 값 | 선택 경향 | 장단점 |
|---|---|---|
| 낮음 | root에 가까운 큰 block 선택 | 긴 query window에 유리하지만 짧은 window에서는 filter 비용 증가 |
| 높음 | leaf에 가까운 작은 block 선택 | 짧은 window에 유리하지만 block 수가 많아짐 |
| 약 0.5 | 실험상 무난한 기본값 | 대부분의 dataset에서 안정적 |

논문은 `tau <= 0.5`이면 T kNN query를 처리하는 block 수가 최대 2개임을 보인다. 이것이 MBI가 다양한 query window 길이에서 안정적인 속도를 보이는 핵심 이유다.

## 7. m-AkNN으로 확장

T kNN은 filtering attribute가 timestamp 하나라서 binary tree로 충분하다. m-AkNN은 여러 수치 속성의 범위 조건을 동시에 만족해야 한다.

```text
age in [20, 40)
height in [160, 180)
weight in [50, 80)
```

이 경우 MBI는 `2^m`-ary tree로 확장된다.

| `m` | 구조 |
|---:|---|
| 1 | binary tree |
| 2 | quadtree |
| 3 | octree |

다만 실제 데이터는 균일한 grid에 예쁘게 분포하지 않는다. 그래서 논문은 rigid grid 대신 count-based recursive space partitioning을 사용한다. 데이터가 많은 영역은 더 깊게 나누고, sparse한 영역은 얕게 유지한다.

T kNN과 다른 중요한 제약도 있다.

| 문제 | update 가정 |
|---|---|
| T kNN | timestamp 증가 순서의 incremental insertion 지원 |
| m-AkNN | attribute가 insertion order와 독립적이므로 static dataset 중심 |

즉, m-AkNN 확장은 query filtering에는 강하지만 arbitrary insertion/deletion까지 다루지는 않는다.

## 8. 복잡도 정리

논문은 block 내부 index로 NNDescent 기반 graph index를 사용한다고 두고 분석한다.

| 항목 | 결과 | 해석 |
|---|---|---|
| index size | `O(n log n)` | 여러 level의 block index를 모두 저장하므로 SF보다 큼 |
| total indexing time | `O(n^1.14)` | NNDescent의 경험적 복잡도 `O(n^1.14)`를 block별 합산 |
| amortized insertion time | `O(n^0.14)` | 시간순으로 누적되는 데이터에서 삽입 비용 증가가 완만함 |
| T kNN query, `tau <= 0.5` | `O(log(b / tau) + k / tau)` | `b`는 query time window 안의 데이터 수 |
| m-AkNN query upper bound | `O((b / (S_L tau)) * (log S_L + k / tau))` | 최악의 경우 leaf block 위주로 처리한다고 보는 거친 상한 |

공부할 때 중요한 해석은 MBI가 index memory를 더 쓰는 대신 query time을 안정화한다는 점이다. 특히 query window가 짧든 길든 한쪽 baseline처럼 급격히 나빠지지 않는 것이 목적이다.

## 9. 실험 설정

T kNN 실험에는 6개 dataset을 사용한다.

| Dataset | Train items | Test items | Dim. | Distance |
|---|---:|---:|---:|---|
| MovieLens | 57,571 | 200 | 32 | Angular |
| COMS | 291,180 | 200 | 128 | Angular |
| GloVe-100 | 1,183,514 | 10,000 | 100 | Angular |
| SIFT1M | 1,000,000 | 10,000 | 128 | Euclidean |
| GIST1M | 1,000,000 | 1,000 | 960 | Euclidean |
| DEEP1B subset | 9,990,000 | 10,000 | 96 | Angular |

m-AkNN 실험에는 COMS-GTS와 CORD-19를 사용한다.

| Dataset | Items | Dim. | Filtering attributes |
|---|---:|---:|---|
| COMS-GTS | 25,544 | 128 | timestamp, temperature, humidity |
| CORD-19 | 49,800 | 728 | publication date, citation counts |

query 성능은 approximate answer와 exact answer의 overlap인 recall@k로 맞춘 뒤 queries per second를 비교한다.

## 10. 주요 결과

T kNN에서 MBI는 query time window의 길이에 관계없이 BSBF와 SF보다 안정적인 속도를 보인다.

| 결과 | 의미 |
|---|---|
| up to 10.88x faster | BSBF와 SF 중 더 빠른 것을 고르는 가상 baseline보다도 최대 10.88배 빠름 |
| recall@k 0.995 조건 비교 | 정확도를 높게 맞춘 상태에서 속도 우위 확인 |
| `k = 10, 50, 100` 모두 유사한 경향 | k가 커지면 전체 속도는 떨어지지만 MBI의 상대적 장점은 유지 |
| SIFT1M scalability slope 약 1.29 | 데이터가 커질수록 이론적 `n^1.14`에 가까워지는 경향 |
| parallel indexing | block index를 병렬 생성하면 indexing time이 최대 5.08배 감소 |

m-AkNN에서도 MBI는 AFBF와 SF의 약점을 줄인다.

| 결과 | 의미 |
|---|---|
| up to 1.99x faster | m-AkNN에서 가상 baseline보다 최대 1.99배 빠름 |
| higher recall than SF | SF는 attribute 조건으로 후보가 많이 걸러지며 recall이 흔들릴 수 있음 |
| faster than AFBF | AFBF보다 적은 vector를 직접 검사하므로 query speed가 높음 |
| stable indexing trend | m-AkNN에서도 T kNN과 유사한 scalability trend 관찰 |

index size는 SF보다 커진다. 예를 들어 DEEP1B subset에서는 input data 3.92GB에 대해 MBI index가 18.24GB, SF index가 6.10GB로 보고된다. 속도를 위해 저장공간을 쓰는 trade-off다.

## 11. 논문의 핵심 기여

| 기여 | 공부 포인트 |
|---|---|
| T kNN 문제화 | 고차원 ANN에 timestamp range constraint를 결합한 문제를 명확히 다룸 |
| MBI 구조 | block별 graph index와 hierarchical time partition을 결합 |
| incremental insertion | 시간순 데이터 누적 환경에서 bottom-up merge로 index 갱신 |
| query block selection | overlap ratio와 `tau`로 큰 block과 작은 block을 섞어 선택 |
| m-AkNN 일반화 | timestamp 하나를 여러 numerical attribute constraint로 확장 |
| 이론과 실험 연결 | index size, indexing time, query time 분석을 실험 결과와 비교 |

## 12. 읽을 때 잡아야 할 관점

이 논문은 "새로운 ANN search graph"를 제안하는 논문이라기보다, 기존 graph-based ANN index를 시간/속성 필터 조건이 있는 검색에 맞게 배치하는 indexing framework 논문으로 읽는 것이 좋다.

| 관점 | 질문 |
|---|---|
| Filtering-first vs search-first | 먼저 조건을 거르고 찾을 것인가, 먼저 찾고 조건을 거를 것인가? |
| Block granularity | leaf size `S_L`이 작거나 클 때 어떤 비용이 커지는가? |
| Threshold `tau` | query window 길이에 따라 큰 block과 작은 block 중 무엇을 고를 것인가? |
| Memory trade-off | block마다 graph index를 저장하는 추가 비용을 감당할 수 있는가? |
| Dynamic workload | timestamp 순서 삽입이라는 가정이 실제 서비스에 맞는가? |

## 13. 한계와 향후 과제

논문이 직접 언급한 한계는 다음과 같다.

| 한계 | 설명 |
|---|---|
| timestamp 순서 가정 | T kNN indexing은 데이터가 non-decreasing timestamp order로 들어온다고 가정한다. |
| arbitrary insertion/deletion 미지원 | 과거 timestamp로 새 데이터를 넣거나 임의 삭제하는 경우는 다루지 않는다. |
| m-AkNN static dataset | 다중 속성 설정에서는 dynamic update를 고려하지 않는다. |
| formal optimality open | MBI block selection이 이론적으로 최적인지에 대한 분석은 남아 있다. |

가능한 확장으로는 오래된 왼쪽 block을 순차적으로 제거하는 sliding-window deletion이 제시된다. 실시간 서비스에서 최근 몇 년 또는 최근 몇 달만 유지하는 형태라면 자연스러운 확장 방향이다.

## 시험 포인트

| 질문 | 답의 방향 |
|---|---|
| T kNN이 일반 kNN과 다른 점은? | query vector와 가까워야 할 뿐 아니라 timestamp가 query time window 안에 있어야 한다. |
| BSBF가 긴 window에서 느린 이유는? | window 안의 vector가 많아져 brute-force distance 계산량이 커진다. |
| SF가 짧은 window에서 느린 이유는? | graph search 후보 대부분이 시간 조건을 만족하지 않아 계속 더 넓게 탐색해야 한다. |
| MBI의 block은 무엇을 저장하는가? | timestamp 범위의 vector set과 그 vector set에 대한 graph-based kNN index를 저장한다. |
| `tau`의 역할은? | query window와 block window의 overlap ratio 기준으로 block 선택을 조절한다. |
| `tau <= 0.5`의 의미는? | T kNN에서 query를 처리하는 block 수가 최대 2개로 제한됨을 보인다. |
| m-AkNN 확장은 어떤 구조를 쓰는가? | `m = 2`는 quadtree, `m = 3`은 octree 기반의 count-based space partitioning을 사용한다. |
| 가장 큰 trade-off는? | query speed와 update 효율을 얻는 대신 index size가 커진다. |

## 복습 질문

1. 시간 조건이 있는 kNN에서 "검색 후 filtering"이 항상 좋은 전략이 아닌 이유를 설명하라.
2. MBI가 BSBF처럼 동작하는 상황과 SF처럼 동작하는 상황을 각각 설명하라.
3. leaf size `S_L`을 작게 설정하면 query, indexing, index size에 어떤 변화가 생기는가?
4. m-AkNN에서 uniform grid 방식이 비효율적일 수 있는 이유는 무엇인가?
5. MBI를 실제 서비스에 적용할 때 memory budget과 update pattern을 어떻게 점검해야 하는가?

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/efficient-time-restricted-knn-search-mbi/efficient-time-restricted-knn-search-mbi.pdf" | relative_url }}" target="_blank" rel="noopener">efficient-time-restricted-knn-search-mbi.pdf</a></li>
  <li><a href="https://doi.org/10.1145/3789265" target="_blank" rel="noopener">DOI: 10.1145/3789265</a></li>
  <li><a href="https://github.com/kjsoo-1010/mbi2025" target="_blank" rel="noopener">Code and datasets from paper</a></li>
</ul>
