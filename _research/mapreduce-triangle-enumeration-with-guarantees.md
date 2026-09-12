---
layout: default
date: 2026-09-12 18:42:46 +0900
title: "CTTP"
topic: "Multi-round MapReduce triangle enumeration with space guarantees"
order: 79
major_topic: "Graph Algorithms & Distributed Systems"
keywords:
  - "CTTP"
  - "Research seminar"
---

# MapReduce Triangle Enumeration With Guarantees

## 자료 정보

| 항목 | 내용 |
| --- | --- |
| 제목 | MapReduce Triangle Enumeration With Guarantees |
| 저자 | Ha-Myung Park, Francesco Silvestri, U Kang, Rasmus Pagh |
| 연도 | 2014 |

## 핵심 질문

CTTP는 triangle-type subproblem을 여러 MapReduce round에 배치해, 한 round에서 동시에 발생하는 중간 데이터의 규모를 제한한다. 전체 작업량, reducer별 메모리, 시스템 전체의 중간 데이터 한도를 구분해 이해하는 것이 중요하다.

## 강의 구성

- Triangle enumeration과 출력 범위
- 색 분할과 triangle type별 subproblem
- 여러 round에 subproblem을 배치하는 규칙
- 공간 보장의 조건과 PTE와의 차이

## 읽을 때 구분할 점

기대값 보장과 추가 조건이 필요한 높은 확률 보장을 구분한다. Triangle을 열거하는 것과 모든 결과를 하나의 거대한 파일로 저장하는 것도 같은 요구가 아니다.

## 세미나 강의자료

슬라이드와 함께 학습 원고·발표자 노트를 볼 수 있습니다.

| 자료 | 분량 | PDF | PowerPoint | 학습 원고 | 발표자 노트 |
| --- | ---: | --- | --- | --- | --- |
| 한국어 강의 | 25장 | <a href="/assets/seminars/mapreduce-triangle-enumeration-with-guarantees/cttp-seminar-ko-v3.pdf" target="_blank" rel="noopener">보기</a> | <a href="/assets/seminars/mapreduce-triangle-enumeration-with-guarantees/cttp-seminar-ko-v3.pptx" download>다운로드</a> | <a href="/assets/seminars/mapreduce-triangle-enumeration-with-guarantees/slides-v3.md.txt" download="slides-v3.md">Markdown</a> | <a href="/assets/seminars/mapreduce-triangle-enumeration-with-guarantees/presenter-notes-v3.md.txt" download="presenter-notes-v3.md">Markdown</a> |

## 공개 출처

- [ACM DOI record](https://doi.org/10.1145/2661829.2662017){:target="_blank" rel="noopener"}
- [저자 공개 원문](https://www.dei.unipd.it/~silvestri/assets/publications/PSKP14.pdf){:target="_blank" rel="noopener"}
