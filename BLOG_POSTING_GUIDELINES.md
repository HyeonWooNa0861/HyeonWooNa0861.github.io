# GitBlog Posting Guidelines

이 문서는 새 자료를 GitBlog에 정리할 때 따르는 기준이다. 판단이 애매하면 이 순서로 결정한다.

## 1. 기본 원칙

- 원본 자료는 보존하고, 블로그에는 읽기 쉬운 Markdown 정리본과 PDF 링크를 제공한다.
- 정리본은 원문 자료의 주요 범위와 논지를 충실히 따라야 한다. 읽기 쉽게 재구성하되, 원문에서 비중 있게 다룬 장, 절, 코드 예제, 수식, 표, 결론을 임의로 누락하지 않는다.
- 파일명과 폴더명은 영문 kebab-case를 사용한다.
- `research_files` 원천 자료에 논문 별칭이 있으면 최종 원문 PDF와 최종 번역본 Markdown 파일명은 별칭을 맨 앞에 둔다. 이 별칭 우선 규칙은 제목 기반 slug 규칙보다 우선한다. 예: `cola-preserving-..._원문.pdf`, `cola-preserving-..._번역본.md`.
- 별칭 우선 파일명 규칙은 `*_원문.pdf`와 `*_번역본.md` 같은 최종 산출물에만 적용하고, 추출 후보, review packet, report, sidecar metadata 같은 중간 산출물에는 적용하지 않는다.
- 기존 collection, URL, sidebar 구조를 우선한다.
- `_posts`, `_research`, `_study`, `_assignment`의 모든 공개 문서는 front matter에 `date: YYYY-MM-DD HH:MM:SS +0900` 형식의 최초 등록 시각을 둔다. 이 값은 `Latest accessions`와 `Accession Log`의 collection 통합 정렬 기준이며, 기존 문서를 수정할 때 임의로 갱신하지 않는다.
- 실질적인 게시물 본문을 제외한 공개 UI와 콘텐츠 메타데이터는 영어로 작성한다. 여기에는 front matter의 `title`, `nav_title`, `topic`, 공개되는 category/tag, navigation title/description, index와 card의 제목·설명, tab/sidebar label, 버튼, 상태 문구가 포함된다.
- 본문이 한국어여도 posting title과 index에 노출되는 이름은 영어로 유지한다. 한국어는 본문의 해설, 표, 예제, 인용 맥락처럼 실제 내용을 전달하는 영역에서만 사용한다.
- 수상 실적, 증명서, 확인서처럼 본문 해설 대상이 아닌 증빙 PDF는 별도 포스트를 만들지 않고, 관련 포스트의 하단 참고자료/source 목록에 첨부한다.
- 수식은 MathJax 문법을 사용한다.
  - inline: `\(...\)` (Markdown source 기준으로 backslash를 한 번만 쓴다)
  - display: `$$...$$`
- 수식 내부 LaTeX 명령도 source 기준 단일 backslash만 사용한다. 예: `\odot`, `\top`, `\widehat{W}`, `\mathrm{diag}`. `\\odot`, `\\top`처럼 이중 escape하면 GitBlog/MathJax 렌더링에서 `odot`, `top`이 문자처럼 보일 수 있다.
- superscript/subscript가 LaTeX 명령이나 여러 token을 포함하면 항상 brace로 묶는다. 예: `h^{\top}`, `XX^{\top}`, `w_0(1+g)^{\rho}`, `\lVert x\rVert_2^{2}`.
- 수식 기호와 변수명은 원본 PDF notation을 우선한다.
- 강의 중 정정된 수식이 확인되면 원본 PDF보다 정정 사항을 우선한다.
- 정정 내용이 "불필요한 변수 제거"라면 다른 문자로 단순 치환하지 말고 수식을 재작성한다.
- 원본에 없는 보조 수식을 넣을 때는 설명용 확장임이 드러나게 작성한다.
- 실제 코드와 의사코드는 수식으로 바꾸지 않는다.
- Markdown table 안의 `|`는 필요하면 `\|`로 escape한다.

### 원문 충실성 기준

PDF, 이미지, 논문, 과제 원문을 바탕으로 글을 작성할 때는 다음을 반드시 확인한다.

- 작성 전 원문을 한 번 훑어 전체 목차, 페이지별 주제, 반복해서 등장하는 핵심 키워드를 파악한다.
- 작성 후 원문을 다시 대조해 각 주요 페이지 묶음 또는 장이 Markdown 본문 어딘가에 반영되었는지 확인한다.
- 원문에서 여러 페이지에 걸쳐 다룬 내용은 한두 문장으로만 처리하지 말고, 학습자가 복습할 수 있을 정도로 예시와 차이를 함께 정리한다.
- 원문 코드 예제는 그대로 복붙하기보다 설명 가능한 형태로 재구성하되, 함수 이름, 매개변수 의미, 반환값, 주의점은 빠뜨리지 않는다.
- 원문 수식과 알고리즘은 notation을 유지하고, 변형하거나 보조 설명을 추가할 때는 원문 내용과 작성자 설명을 구분한다.
- 원문에 있는 범위를 의도적으로 생략해야 할 경우, “이 글에서는 ... 범위만 다룬다”처럼 생략 범위를 명시한다.
- 게시 전 `Source PDF` 또는 `Source Images` 표기와 하단 `PDF`/자료 링크가 서로 일치하는지 확인한다.
- 특히 Study 자료는 원문 대비 누락이 생기기 쉬우므로, `전체 흐름` 표가 원문 전체 범위를 대표하는지 마지막에 다시 점검한다.

### 상세성과 핵심 강조 기준

- 글의 길이에 일률적인 최소 글자 수나 최대 분량을 두지 않는다. 원문 또는 검증된 자료가 뒷받침하는 범위 안에서 가능한 한 자세히 작성한다.
- 각 문단은 개념 정의, 작동 원리, 근거·수치, 예시, 비교, 적용 조건, 실무·학습 의미 중 하나 이상의 새로운 정보를 제공해야 한다.
- 원문에서 큰 비중을 차지하는 장, 절, 수식, 알고리즘, 코드, 실험, 사례는 각각 본문의 대응 구간을 가져야 한다. 여러 페이지나 여러 강의 구간에 걸친 핵심 주제를 한두 문장으로만 축약하지 않는다.
- 핵심 내용은 긴 상세 설명 속에 묻히지 않도록 글의 앞과 뒤에서 명시적으로 강조한다.
  - 본격적인 상세 설명 전에는 결론과 읽어야 할 이유를 파악할 수 있는 핵심 요약 또는 핵심 메시지를 둔다.
  - 참고자료나 PDF 링크 전에는 다시 찾아볼 핵심 주장, 수식, 결과, 비교 또는 실천 항목을 짧게 정리한다.
  - collection별 기존 명칭을 유지한다. Research는 `한 줄 요약`과 `핵심 내용`, Study는 `전체 흐름`과 `마지막 핵심 정리`, Assignment는 `과제 개요`와 `핵심 정리`, 일반 Post는 도입부의 핵심 메시지와 마지막 핵심 정리를 사용한다.
- 핵심 요약에는 본문에서 실제로 설명하고 추적할 수 있는 내용만 담는다. 주요 결론, 수식, 수치와 조건은 굵은 글씨, 인용형 callout, 짧은 목록 또는 비교 표 가운데 가장 읽기 쉬운 형식으로 선택적으로 강조한다.
- 상세성을 높일 때는 같은 내용을 표현만 바꾸어 반복하거나, 근거 없는 일반론·사례·수치·성과를 덧붙이지 않는다. 분량이 아니라 **새롭고 검증 가능한 정보의 밀도**를 기준으로 삼는다.
- 원문 전체의 축어 번역, 긴 인용, 슬라이드 문구의 연속 복제는 상세성으로 인정하지 않는다. 인용과 번역은 필요한 최소 범위로 제한하고, 나머지는 출처를 밝힌 독자적 해설로 재구성한다.
- 원문이나 검증 가능한 자료가 없으면 내용을 추측해 확장하지 않는다. 이 경우 확인 가능한 범위와 자료 부재 또는 생략 범위를 명시하고, 원자료를 확보한 뒤 별도 검증 배치에서 보강한다.
- 짧은 공지나 단일 목적 기록처럼 앞뒤 요약이 사실상 같아지는 글은 하나의 핵심 블록으로 통합할 수 있다. 이 예외에서도 핵심 메시지와 확인 가능한 범위는 분명해야 한다.

게시 전 상세성·강조 검증:

1. 상세 본문보다 앞에 collection 성격에 맞는 핵심 요약이 있는가?
2. 참고자료 또는 PDF 링크보다 앞에 마지막 핵심 정리나 이에 해당하는 명시적 요약이 있는가?
3. 원문의 주요 장·주제마다 대응하는 본문 구간이 있는가?
4. 핵심 요약의 각 항목을 상세 본문에서 다시 찾을 수 있는가?
5. 수치와 성능 주장은 조건, 비교 기준 또는 출처와 함께 제시되는가?
6. 원문 주장, 확인된 사실과 작성자의 보충 해설이 구분되는가?
7. 반복 문단, 장식적 나열, 근거 없는 확장, 원문을 대체할 정도의 장문 복제가 없는가?

## 2. 표 작성 및 표시 규칙

Markdown table은 화면 폭이 좁아져도 의미 구조가 유지되게 작성한다. 이 규칙은 개별 Markdown 문서의 임시 스타일이 아니라 `_layouts/default.html`의 전역 CSS로 적용되는 포스트 공통 디자인 구조이다.

- 표의 header(`th`)는 기준 축이므로 가능하면 짧게 쓰고 한 줄로 유지한다.
- 본문 셀(`td`)에는 설명이 길어질 수 있으므로 자연 줄바꿈을 허용한다.
- 긴 URL, 긴 영문 토큰, 코드 식별자는 본문 셀에서만 필요한 경우 줄바꿈되게 둔다.
- 표 전체가 화면보다 넓어질 경우 페이지 전체 비율을 줄이지 말고, 표 내부 가로 스크롤로 처리한다.
- header가 길어 두 줄로 깨질 것 같으면 header를 축약하고, 자세한 설명은 본문 셀이나 표 아래 문단에 둔다.
- 짧은 기준 컬럼(예: 일자, 시간, 번호, 구분)은 내용 폭을 기준으로 compact하게 유지하고, 긴 설명 컬럼에서 줄바꿈되게 구성한다.
- 모바일에서는 표를 억지로 축소하지 않고, header 가독성과 본문 설명성을 우선한다.
- 개별 포스트에서 inline style이나 HTML table 속성으로 표 비율을 따로 덮어쓰지 않는다. 예외가 필요하면 전역 CSS 규칙을 먼저 조정한다.

현재 디자인 기준:

- `th`: `white-space: nowrap`
- `td`: `white-space: normal`, `overflow-wrap: break-word`, `word-break: keep-all`
- `td`에는 고정 `min-width`를 두지 않고, 짧은 열은 내용 폭 기준으로 자연스럽게 compact하게 둔다.
- 4열 이상 표의 3열 이후: 설명 컬럼으로 보고 최대 폭을 제한해 자연 줄바꿈 허용
- `table`: `overflow-x: auto`

## 3. Study 자료

대상: `_study/`

목적: 강의 복습과 시험 대비용 공부 자료

허용:

- `시험 포인트`
- `복습 질문`
- `Study Notes`
- 핵심 개념, 수식, 코드 예제

필수 기준:

- 원문 PDF나 이미지 자료의 핵심 범위를 충실히 반영한다. 시험 대비용으로 재구성하더라도 원문에서 큰 비중을 차지하는 장이나 예제를 누락하지 않는다.
- Source 표기 다음에 강의의 결론과 학습 이유를 압축한 핵심 메시지를 두고, 본문 끝에는 `마지막 핵심 정리`를 둔다.
- 복습 질문은 답변을 포함한다.
- 복습 질문 답변은 HTML `<details>` / `<summary>` toggle 형식으로 작성한다.
- `<summary>`에는 질문을 쓰고, 펼친 내용에는 간결하지만 충분한 답변을 쓴다.
- 원문 순서를 그대로 베끼기보다 다시 읽기 쉬운 학습 구조로 정리한다.

권장 구성:

- 제목과 Source PDF 파일명 표기
- 초반 핵심 메시지
- 전체 흐름
- 개념별 정리
- 핵심 수식 또는 코드 예제
- 시험 포인트
- 마지막 핵심 정리
- Study Guide
- 복습 질문
- PDF 링크

Study 공통 구조 참고:

```md
---
layout: default
title: "English Title"
course: "Course Name"
topic: "English Topic"
order: 1
---

# English Title

Source PDF: `원문 파일명.pdf`

> **핵심:** 강의의 결론, 중요한 작동 원리, 이 내용을 학습해야 하는 이유를 2~4문장으로 먼저 정리한다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | ... | ... |

## 1. 첫 번째 개념

본문을 원문 순서 그대로 옮기지 말고, 공부 흐름에 맞게 재구성한다.

## 마지막 핵심 정리

핵심 개념을 표나 짧은 문단으로 정리한다.

## Study Guide

읽는 순서, 시험 대비 포인트, 헷갈리기 쉬운 개념을 정리한다.

## 복습 질문

<details>
<summary>1. 질문을 쓴다.</summary>

답변: 간결하지만 충분하게 설명한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/<course>/<원문 파일명.pdf>" | relative_url }}" target="_blank" rel="noopener">원문 파일명.pdf</a></li>
</ul>
```

Study 구조 규칙:

- 제목은 영어로 작성하고, 파일명은 영문 kebab-case를 사용한다.
- 제목과 파일명에서 `요약`, `정리본` 같은 표현은 가능하면 빼고 주제명만 남긴다.
- 상단에는 `Source PDF:` 형식으로 원문 PDF 파일명을 명시한다.
- 하단에는 `## PDF` 섹션을 두고 같은 원문 PDF 링크를 다시 제공한다.
- 본문 순서는 `전체 흐름` → 개념별 본문 → `마지막 핵심 정리` → `Study Guide` → `복습 질문` → `PDF`를 기본으로 한다.
- 복습 질문은 반드시 `<details>` / `<summary>` toggle 형식으로 작성하고, 답변은 `답변:`으로 시작한다.
- `<details>` 내부에서 `Vector<int>`처럼 `<`, `>`가 들어간 코드는 HTML 태그로 오해될 수 있으므로 `<code>Vector&lt;int&gt;</code>`처럼 HTML escape하여 쓴다.
- 원문 PDF가 여러 개라면 상단에는 `Source PDFs:` 아래 목록을 두고, 하단 `## PDF`에도 같은 파일들을 모두 링크한다.

## 4. Research 자료

대상: `_research/`

목적: 논문 분석 및 해석 자료

금지:

- `시험 포인트`
- `복습 질문`
- `Study Notes`
- `공부 포인트`
- 시험 대비식 Q&A

필수 기준:

- 연구 글은 문제집처럼 만들지 않는다.
- 상세 본문보다 앞에 `한 줄 요약`을 두고, 문제·방법·결과·의의를 연결한 `핵심 내용`을 독립적으로 강조한다.
- `공부 포인트` 대신 `해석 포인트`를 사용한다.
- 논문에 별칭이 있으면 Research post의 front matter `title`과 `_data/navigation.yml`의 tab/sidebar 제목은 별칭을 우선한다. 이 규칙은 긴 논문 제목을 그대로 tab 제목으로 쓰는 규칙보다 우선한다.
- 긴 논문 원제는 본문 H1, `논문 정보` 표, `참고자료`에 보존한다. 예: tab/front matter title은 `CoLA`, 본문 H1은 `Preserving LLM Capabilities through Calibration Data Curation: From Analysis to Optimization`.
- 논문 주장과 작성자의 해석을 구분한다.
- 실험 수치는 결과와 해석을 함께 적되 과장하지 않는다.
- 질문형 섹션을 쓰더라도 시험 문제가 아니라 분석 관점이어야 한다.
- 원문 논문 전체를 축어적으로 번역해 게시하지 않는다. 저작권 보호를 위해 본문에는 논문 전체 구조를 따라가는 `한국어 번역형 해설`을 제공한다.
- `한국어 번역형 해설`은 초록/서론, 방법, 실험, 결론/한계를 빠짐없이 따라가되 문장과 표현은 새로 구성한다.
- 원문 고유명사, 모델명, 수식 기호, 데이터셋, 실험 수치, DOI, source PDF 링크는 유지한다.
- 원문 전체 번역 권한이 명시적으로 있는 경우에만 축어 번역을 게시할 수 있으며, 그 경우에도 허가 범위나 라이선스 정보를 참고자료에 남긴다.
- Research 원문 PDF는 `assets/pdfs/research/<slug>/<slug>.pdf` 아래에 두고, 포스트 하단 `참고자료`에서 같은 경로로 연결한다.

권장 구성:

- 논문 정보
- 한 줄 요약
- 핵심 내용
- 전체 흐름
- 문제 배경과 문제 정의
- 제안 방법 또는 시스템 구조
- 핵심 수식과 알고리즘 해석
- 실험 설정과 주요 결과
- 논문의 핵심 기여
- 읽을 때 잡아야 할 관점
- 한계와 향후 과제
- 한국어 번역형 해설
- 참고자료

## 5. Assignment 자료

대상: `_assignment/`

목적: 과제 주제의 요약, 분석, 학습 성과 정리

필수 기준:

- 상단에 `Source PDF:` 또는 `Source PDFs:` 형식으로 원문 파일명을 명시한다. PDF가 아니라 이미지 기반 자료라면 `Source Images:`를 사용한다.
- `과제 개요`에서 목적과 결론을 먼저 파악할 수 있게 하고, PDF 링크 전에 `핵심 정리`를 둔다.
- 과제 원문을 그대로 붙이지 않고, 핵심 개념과 분석 결과를 블로그용으로 재구성한다.
- 과제 원문에서 요구한 조건, 비교 항목, 구현 범위, 결론을 빠뜨리지 않는다. 요약이 짧아지더라도 원문의 평가 조건은 모두 추적 가능해야 한다.
- Study 자료처럼 `시험 포인트`나 `복습 질문`을 넣지 않는다. 단, 아래의 `시험 대비형 Assignment 예외`에 해당하면 공부 중심 구조를 사용할 수 있다.
- Research 자료처럼 논문 기여와 한계 중심으로 쓰지 않는다.
- 과제의 주제, 개념 설명, 정리 결과, 원본 PDF 링크를 포함한다.
- 코드나 실행 결과는 과제 이해에 필요한 범위에서만 넣는다.

권장 구성:

- 제목과 course/topic
- 과제 개요
- 주제별 정리
- 핵심 정리
- 결론 및 학습 성과
- PDF 링크

### 시험 대비형 Assignment 예외

과제 자료가 시험 대비, 기출문제, 기말과제 풀이, 예상문제 풀이처럼 평가 대비 성격을 가지면 Study 자료처럼 공부에 초점을 맞춘 구조를 허용한다. 이 경우에도 collection은 `_assignment/`를 사용하고, `_study/`로 분류하지 않는다.

이 예외에 해당하는 글은 `_assignment/<course>/assignment.md`처럼 문제풀이형 학습 자료로 구성할 수 있다.

허용:

- `출제 의도`
- `원문 문제 재구성`
- `풀이과정`
- `정답`
- `관련 변형 문제`
- `실수 포인트`
- `마지막 핵심 정리`
- `Study Guide`
- `복습 질문`

필수 기준:

- 과제 원문 문제를 그대로 붙이지 않고, 학습 흐름에 맞춰 재구성한다.
- 풀이과정과 정답은 HTML `<details>` / `<summary>` toggle 형식으로 작성한다.
- Toggle 내부 답변은 `풀이과정:` 또는 `답변:`으로 시작한다.
- 관련 변형 문제를 추가할 수 있지만, 원문 과제와 어떤 개념으로 연결되는지 설명한다.
- 제목과 본문에서는 `Past Exam`, `기출문제`로 단정하지 않는다. 실제 자료가 과제라면 `Assignment`, `Final Assignment`, `과제`로 정의한다.
- PDF는 `assets/pdfs/assignment/<course>/` 아래에 둔다.

권장 구성:

- 제목과 Source PDF 파일명 표기
- 과제 개요
- 전체 흐름
- 문항별 출제 의도 또는 학습 목표
- 원문 문제 재구성
- 풀이과정 및 정답 toggle
- 관련 변형 문제 toggle
- 실수 포인트
- 마지막 핵심 정리
- Study Guide
- 복습 질문
- PDF 링크

현재 구조:

- C++ 과제 Markdown: `_assignment/cpp/`
- C++ 과제 PDF: `assets/pdfs/assignment/cpp/`
- URL: `/assignment/cpp/<slug>/`
- Machine Learning Basic 과제 Markdown: `_assignment/machine-learning-basic/`
- Machine Learning Basic 과제 PDF: `assets/pdfs/assignment/machine-learning-basic/`
- URL: `/assignment/machine-learning-basic/<slug>/`

## 6. Posts

대상: `_posts/`

- Conference 준비 글은 예상 질문과 답변을 포함할 수 있다.
- 일반 post는 행사 후기, 기술 트렌드, 프로젝트 설명 등 목적에 맞게 작성한다.
- 일반 post는 도입부에서 글의 핵심 메시지를 명시하고, 참고자료 전에 주요 결론이나 실천 항목을 다시 찾을 수 있는 마지막 핵심 정리를 둔다.
- 확인 가능한 원자료가 있는 기술·강의·행사 post는 배경, 작동 원리 또는 진행 맥락, 핵심 사례, 결과와 의미를 충분히 설명한다.
- Research 글처럼 분석 자료인 경우에는 Research 기준을 따른다.
- permalink, categories, tags는 기존 post 형식을 따른다.

### Project 노트

- Project tab의 서비스 소개 글은 `_posts/`에 두고 `layout: post`, `section: projects`를 사용한다. 다른 연재 section에 이미 속한 글을 Project 노트로 재사용할 때는 기존 section을 보존하고 navigation의 `source_url`로 연결한다.
- 제목과 첫 문단에는 서비스가 해결하는 문제, 대상 사용자, 제공 가치가 드러나게 한다.
- 기능을 나열하는 데서 멈추지 않고 각 기능이 사용자에게 주는 결과와 서비스의 의의를 함께 설명한다.
- 미완성, 제약, 외부 의존성만을 독립적인 결론이나 목록으로 강조하지 않는다.
- 현재 범위나 한계를 언급해야 하면 같은 표나 문단에 `해결 방향`과 `확장 가능성`을 반드시 함께 작성한다.
- 검증되지 않은 기능, 이용자 수, 성과, 운영 상태와 로드맵을 현재 사실처럼 쓰지 않는다.
- 참고자료에는 공개 서비스와 검증된 공개 저장소 또는 공식 소개 링크만 연결한다.
- 권장 흐름은 `서비스 소개` → `주요 기능` → `서비스의 의의` → `사용 흐름` → `기술 구성` → `해결 방향과 확장성` → `참고자료`이다.

## 7. PDF와 경로

Research:

- PDF: `assets/pdfs/research/<slug>/<slug>.pdf`
- Markdown: `_research/<slug>.md`

Assignment:

- PDF: `assets/pdfs/assignment/<course>/`
- Markdown: `_assignment/<course>/<slug>.md`

Study:

- Machine Learning Basic: `assets/pdfs/study/machine-learning-basic/`
- AIX: `assets/pdfs/study/aix/`
- Data Structures: `assets/pdfs/study/data-structures/`
- CPP: `assets/pdfs/study/cpp/`

Post 증빙/참고자료:

- 발표 자료, 행사 자료, 수상 실적 PDF: `assets/pdfs/post/<section>/`
- 증빙 PDF는 제목 기반 영문 kebab-case 파일명으로 저장한다.
- 증빙 PDF만 추가하는 경우 navigation과 새 Markdown 포스트는 만들지 않는다.

PDF 파일명이 숫자 또는 임시명이면 전문을 확인한 뒤 제목 기반 slug로 rename한다.

## 8. Navigation

- 새 글은 기존 category의 `order`를 확인해 배치한다.
- 새 section이나 category가 생기면 `_data/navigation.yml`을 갱신한다.
- Assignment에 새 과목이 생기면 `pages/assignment/<course>.md`와 navigation children을 함께 만든다.
- sidebar와 URL 규칙을 깨지 않는다.

## 9. 검증

포스팅 후 가능한 한 확인한다.

- Markdown table pipe 수
- front matter YAML parsing
- MathJax delimiter 짝수 여부
- `git diff --check`
- Jekyll 환경이 있으면 `jekyll build` 또는 `bundle exec jekyll build`

Jekyll 실행 파일이나 Gemfile이 없으면 빌드 불가 사유를 결과에 명시한다.

## 10. Git

- 변경은 의미 있는 단위로 commit한다.
- 포스팅 요청은 `main` branch push까지 진행한다.
- push가 거절되면 원격 변경을 통합한 뒤 다시 push한다.
