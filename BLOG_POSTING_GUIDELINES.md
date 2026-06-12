# GitBlog Posting Guidelines

이 문서는 새 자료를 GitBlog에 정리할 때 따르는 기준이다. 판단이 애매하면 이 순서로 결정한다.

## 1. 기본 원칙

- 원본 자료는 보존하고, 블로그에는 읽기 쉬운 Markdown 정리본과 PDF 링크를 제공한다.
- 정리본은 원문 자료의 주요 범위와 논지를 충실히 따라야 한다. 읽기 쉽게 재구성하되, 원문에서 비중 있게 다룬 장, 절, 코드 예제, 수식, 표, 결론을 임의로 누락하지 않는다.
- 파일명과 폴더명은 영문 kebab-case를 사용한다.
- 기존 collection, URL, sidebar 구조를 우선한다.
- 수상 실적, 증명서, 확인서처럼 본문 해설 대상이 아닌 증빙 PDF는 별도 포스트를 만들지 않고, 관련 포스트의 하단 참고자료/source 목록에 첨부한다.
- 수식은 MathJax 문법을 사용한다.
  - inline: `\\(...\\)`
  - display: `$$...$$`
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
- 복습 질문은 답변을 포함한다.
- 복습 질문 답변은 HTML `<details>` / `<summary>` toggle 형식으로 작성한다.
- `<summary>`에는 질문을 쓰고, 펼친 내용에는 간결하지만 충분한 답변을 쓴다.
- 원문 순서를 그대로 베끼기보다 다시 읽기 쉬운 학습 구조로 정리한다.

권장 구성:

- 제목과 Source PDF 파일명 표기
- 전체 흐름
- 개념별 정리
- 핵심 수식 또는 코드 예제
- 시험 포인트
- 복습 질문
- PDF 링크

Study 공통 구조 참고:

```md
---
layout: default
title: "English Title"
course: "Course Name"
topic: "한국어 주제"
order: 1
---

# English Title

Source PDF: `원문 파일명.pdf`

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
- `공부 포인트` 대신 `해석 포인트`를 사용한다.
- 논문 주장과 작성자의 해석을 구분한다.
- 실험 수치는 결과와 해석을 함께 적되 과장하지 않는다.
- 질문형 섹션을 쓰더라도 시험 문제가 아니라 분석 관점이어야 한다.

권장 구성:

- 논문 정보
- 한 줄 요약
- 전체 흐름
- 문제 배경과 문제 정의
- 제안 방법 또는 시스템 구조
- 핵심 수식과 알고리즘 해석
- 실험 설정과 주요 결과
- 논문의 핵심 기여
- 읽을 때 잡아야 할 관점
- 한계와 향후 과제
- 참고자료

## 5. Assignment 자료

대상: `_assignment/`

목적: 과제 주제의 요약, 분석, 학습 성과 정리

필수 기준:

- 상단에 `Source PDF:` 또는 `Source PDFs:` 형식으로 원문 파일명을 명시한다. PDF가 아니라 이미지 기반 자료라면 `Source Images:`를 사용한다.
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
- Research 글처럼 분석 자료인 경우에는 Research 기준을 따른다.
- permalink, categories, tags는 기존 post 형식을 따른다.

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
