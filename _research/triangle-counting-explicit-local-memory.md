---
layout: default
date: 2026-11-19 20:28:37 +0900
title: "Why GPU Rankings Do Not Survive the Move"
nav_title: "Why GPU Rankings Do Not Survive the Move"
topic: "Triangle counting on GPUs and the Tenstorrent P150a"
order: 89
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "Triangle counting"
  - "Tenstorrent P150a"
  - "Explicit local memory"
  - "Graph analytics"
  - "WeTriC"
  - "TRUST"
  - "TriCore"
  - "StepTC"
---

# [Experiment, Analysis, and Benchmark] Why GPU Rankings Do Not Survive the Move: Triangle Counting on a Many-Core Accelerator with Explicit Local Memory

## 한 줄 요약

GPU에서는 흩어진 이웃 목록을 빠르게 찾아보는 방식이 유리했지만, 데이터를 코어로 직접 옮겨야 하는 P150a에서는 **한 번 가져온 목록으로 여러 질문에 답하는 방식**이 대부분의 비교에서 앞섰다.

## 논문 정보

| 항목 | 내용 |
|---|---|
| 원제 | [Experiment, Analysis, and Benchmark] Why GPU Rankings Do Not Survive the Move: Triangle Counting on a Many-Core Accelerator with Explicit Local Memory |
| 저자 | Ha-Myung Park, Jaekoo Lee · Kookmin University |
| 비교 대상 | NVIDIA RTX 4080·GTX 1660, Tenstorrent P150a |
| 측정 대상 | 같은 그래프의 정확한 삼각형 수를 구하는 네 알고리즘 계열의 계수 시간 |

## 핵심 내용

Facebook 그래프에서 RTX 4080은 WeTriC로 **0.0355 ms**, TRUST로 **0.132 ms**가 걸렸다. 같은 그래프를 P150a에서 세면 WeTriC가 **1.28 ms**, TRUST가 **0.735 ms**다(표 VI). P150a가 GPU를 앞질렀다는 결과가 아니다. **같은 장치 안에서 무엇을 선택해야 빠른지가 뒤집혔다.**

### 무엇을 반복해서 읽는가

삼각형을 정확히 한 번 세려면 정점에 순서를 정하고 각 간선을 앞에서 뒤로 향하게 할 수 있다. 예를 들어 A에서 B와 C로 가는 간선이 있으면, B에서 C로도 가는지 확인한다. 이 마지막 확인을 수없이 반복할 때 **어느 정점의 이웃 목록을 다시 쓸 수 있는가**가 네 방법의 차이다.

| 계열 | 검사 단위와 방법 |
|---|---|
| TriCore | 간선별로 두 이웃 목록을 비교한다. 한쪽에서 꺼낸 정점을 다른 쪽에서 이진 탐색한다. |
| WeTriC | 두 간선으로 이뤄진 쐐기(wedge)를 병렬로 검사한다. 독립적인 검사를 많이 만들 수 있지만, 검사마다 다른 정점의 목록이 필요할 수 있다. |
| TRUST | 출발 정점의 이웃을 해시 테이블에 한 번 넣는다. 그 정점에서 뻗어 나가는 여러 간선을 검사할 때 같은 테이블을 재사용한다. |
| StepTC | 정점의 차수에 따라 탐색과 해싱을 바꾼다. 짧은 목록에도 해시 테이블을 만드는 고정 비용을 지불하지 않으려는 설계다. |

### GPU가 숨겨 주던 비용

GPU에서 WeTriC가 요청하는 주소는 흩어져 있지만, 저자들이 수집한 카운터에서는 요청한 L2 섹터의 **96.6%**가 캐시에 적중했다. P150a에서는 필요한 목록이 코어의 로컬 SRAM에 없으면 소프트웨어가 전송을 요청해야 한다. 반면 TRUST의 해시 테이블은 출발 정점을 처리하는 동안 SRAM에 남는다. 둘은 같은 삼각형을 세지만 장치 메모리에 다녀오는 횟수가 다르다.

여러 엔진이 동시에 읽는 실험에서 읽기 요청 한 건의 고정 비용은 **약 400바이트를 전송하는 비용**과 맞먹었다. 최소 전송 단위가 400바이트라는 뜻은 아니다. 필요한 바이트만 골라도 요청을 잘게 쪼개면 오히려 느릴 수 있다는 뜻이다. 특히 목록의 시작 주소를 먼저 읽어야 다음 읽기를 시작할 수 있다면 두 요청을 겹치기도 어렵다. 자주 쓰는 행 포인터를 SRAM에 두어 이 선행 요청을 없앴을 때 최대 **1.64배** 빨라졌다.

### 알고리즘 차이와 구현 차이를 어떻게 나눴나

저자들은 네 계열을 직접 이식한 뒤, 같은 계열 안에서 전송 방식·탐색 요청 묶기·다른 프로세서에 일감 넘기기 등을 단계별로 바꿨다. 후보를 제거하는 가지치기 한 단계를 제외하면 검사 후보를 유지하고, 단계마다 독립적인 기준 구현과 계수 결과를 대조했다. 덕분에 ‘검사할 후보가 줄었다’와 ‘같은 검사를 더 싸게 했다’를 구분할 수 있다. 일감을 추가 프로세서에 넘기는 것도 항상 이득은 아니었다. 배치가 작으면 작업 내용을 전달하고 완료를 확인하는 시간이 절약한 연산 시간보다 컸다.

### 순위가 뒤집히는 범위와 도로망이라는 반례

| 원문 비교 조건 | 관측 결과 |
|---|---|
| 네 계열을 모두 비교한 기본 그래프 12개 | RTX 4080과 P150a의 1위 계열은 직접 이식 단계에서 1개만 일치했다. P150a에서 계열별 최속 변형을 골랐을 때는 일치한 그래프가 없었다. 두 GPU끼리는 10개에서 일치했다. |
| P150a에서 네 계열 모두 마지막 최적화 단계에 도달한 기본 그래프 13개 | 마지막 단계끼리 비교하면 TRUST가 13개 모두에서 가장 빨랐다. WebCC는 가장 긴 이웃 목록이 고정 버퍼에 들어가지 않아 이 비교에서 제외됐다. |
| 별도 도로망 3개 | 정렬 방향을 따라 남은 이웃이 정점당 최대 4개였다. 세 그래프 모두 GPU와 P150a의 1위는 WeTriC였다. |

도로망에서는 해시 테이블을 한 번 만들어도 다시 쓸 기회가 적다. 짧은 목록을 페이지 캐시에서 읽는 편이 싼 이유다. 가령 펜실베이니아 도로망에서 P150a의 WeTriC는 **1.69 ms**, TRUST는 **5.04 ms**였다(표 VI, 각 계열의 최속 변형). TRUST를 일률적으로 권하는 결론이라면 이 결과를 설명할 수 없다.

## 해석 포인트

이식 후보를 고를 때 먼저 볼 값은 GPU 순위보다 **읽기 요청 하나로 몇 번의 검사를 처리하는지**, 그리고 **작업을 한 번 넘겨서 얼마나 많은 계산을 끝내는지**다. 그래프가 바뀌면 같은 장치에서도 두 값이 바뀐다. 여기서 비교한 시간은 삼각형을 세는 단계의 시간이다. 원문 표 VII에서도 호스트에서 장치로 올리는 시간은 별도 열이므로, 표 VI의 수치를 전체 질의 지연으로 읽으면 안 된다.

[PTE]({{ "/research/pte-enumerating-trillion-triangles-distributed-systems/" | relative_url }})도 같은 데이터를 반복해서 옮기는 비용을 다루지만 문제의 규모와 출력이 다르다. PTE는 클러스터에서 간선 묶음을 나눠 삼각형을 **열거**하고, 이 논문은 한 가속기 안에서 이웃 목록을 공급하는 방식을 바꿔 삼각형의 **수**를 구한다. 두 결과를 속도 순위로 비교하기보다, 어느 경계에서 데이터 이동이 비싸지는지를 비교하는 편이 맞다.

## 참고자료

- Ha-Myung Park and Jaekoo Lee, *[Experiment, Analysis, and Benchmark] Why GPU Rankings Do Not Survive the Move: Triangle Counting on a Many-Core Accelerator with Explicit Local Memory*. §IV–V는 이식 단계와 비용 측정, §VI 및 표 VI–VIII은 장치별 비교와 그래프별 예외를 다룬다.
- <a href="https://github.com/kmudmlab/trima" target="_blank" rel="noopener">저자들이 원문에 기재한 실험 저장소: trima</a>.
