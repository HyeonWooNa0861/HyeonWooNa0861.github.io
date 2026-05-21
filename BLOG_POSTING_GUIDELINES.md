# GitBlog Posting Guidelines

이 문서는 HyeonWooNa0861.github.io에 자료를 포스팅할 때 적용할 기준을 정리한 것이다. 새 강의자료, 연구 논문, conference 자료를 처리할 때 이 문서를 우선 판단 기준으로 삼는다.

## 1. 공통 원칙

- 업로드된 원본 자료는 가능한 한 보존하고, 블로그에는 읽기 쉬운 Markdown 요약본과 PDF 링크를 함께 제공한다.
- 파일명과 폴더명은 영문 kebab-case를 기본으로 한다.
- PDF는 성격에 맞는 `assets/pdfs/...` 하위 폴더에 배치하고, Markdown 하단 `참고자료` 또는 `PDF` 섹션에서 링크한다.
- Markdown front matter는 기존 collection 규칙을 따른다.
- 수식은 MathJax 문법을 사용한다.
  - inline 수식: `\(...\)`
  - display 수식: `$$...$$`
  - 실제 코드 예제는 code fence 또는 inline code로 유지한다.
- 표 안의 `|` 문자는 Markdown table을 깨뜨릴 수 있으므로 필요하면 `\|`로 escape한다.

## 2. Study 자료 기준

Study 자료는 강의 복습과 시험 대비 기능을 가져도 된다.

대상:

- `_study/machine-learning-basic/`
- `_study/aix/`
- `_study/data-structures/`
- `_study/cpp/`

권장 구성:

- 제목과 source PDF
- 전체 흐름
- 개념별 정리
- 핵심 수식 또는 코드 예제
- 시험 포인트
- 복습 질문
- PDF 링크

판단 기준:

- 강의자료는 "공부 자료"로 작성한다.
- 시험 포인트, 복습 질문, Study Notes 섹션을 둘 수 있다.
- 복습 질문은 답변을 함께 포함해야 한다.
- 복습 질문의 답변은 바로 노출하지 않고 HTML `<details>` / `<summary>` toggle 형식으로 작성한다.
- toggle의 summary에는 질문을 쓰고, 펼친 내용에는 간결하지만 충분한 답변을 적는다.
- 개념 설명은 원문보다 학습자가 다시 읽기 쉬운 구조를 우선한다.
- 코드 강의는 실제 코드와 의사코드를 수식으로 바꾸지 않는다.

## 3. Research 자료 기준

Research 자료는 공부 문제집 형태가 아니라 분석 및 해석 자료여야 한다.

대상:

- `_research/`

금지 항목:

- `시험 포인트`
- `복습 질문`
- `Study Notes`
- `공부 포인트`
- 시험 대비식 Q&A

권장 구성:

- 논문 정보
- 한 줄 요약
- 전체 흐름
- 문제 배경
- 문제 정의
- 제안 방법 또는 시스템 구조
- 핵심 수식과 알고리즘 해석
- 실험 설정과 주요 결과
- 논문의 핵심 기여
- 읽을 때 잡아야 할 관점
- 한계와 향후 과제
- 참고자료

표현 기준:

- `공부 포인트` 대신 `해석 포인트`를 사용한다.
- "외워야 할 내용"보다 "이 논문이 어떤 문제를 어떻게 보고 있는가"를 중심에 둔다.
- 질문형 섹션을 쓰더라도 시험 문제가 아니라 분석 관점이어야 한다.
- 논문 주장과 작성자의 해석을 구분해 쓴다.
- 실험 수치는 결과 자체와 해석을 함께 적되, 과장하지 않는다.

## 4. Conference / Post 자료 기준

Conference 준비 글이나 일반 post는 목적에 따라 구성한다.

대상:

- `_posts/`

판단 기준:

- 발표 준비 자료는 예상 질문과 답변을 포함할 수 있다.
- 단, 논문 분석 글을 `_research`에 올릴 때처럼 범용 시험 포인트나 복습 질문으로 만들지는 않는다.
- 행사 후기, 기술 트렌드, 프로젝트 설명은 독립 post로 작성한다.
- permalink, categories, tags는 기존 post 형식을 따른다.

## 5. PDF 처리 기준

Research PDF:

- `assets/pdfs/research/<paper-slug>/<paper-slug>.pdf`
- `_research/<paper-slug>.md`

Study PDF:

- Machine Learning Basic: `assets/pdfs/study/machine-learning-basic/`
- AIX: `assets/pdfs/study/aix/`
- Data Structures: `assets/pdfs/study/data-structures/`
- CPP: `assets/pdfs/study/cpp/`

PDF 파일명이 숫자 또는 임시명인 경우:

- 전문을 읽고 논문 제목 또는 핵심 주제 기반 slug로 rename한다.
- 같은 slug의 폴더를 만들고 PDF를 이동한다.
- Markdown 파일명도 같은 slug를 사용한다.

## 6. Navigation 기준

- 기존 category 안에 새 글을 추가할 때는 collection의 `order` 값을 확인한다.
- 새 section 또는 새 상위 category가 생기면 `_data/navigation.yml`을 갱신한다.
- 기존 sidebar 구조와 URL 규칙을 깨지 않는다.

## 7. 검증 기준

포스팅 후 가능한 검증:

- Markdown table pipe 수 확인
- front matter YAML parsing 확인
- MathJax delimiter 짝수 확인
- `git diff --check`
- Jekyll 환경이 있으면 `jekyll build` 또는 `bundle exec jekyll build`

현재 로컬 환경에서 Jekyll 실행 파일이나 Gemfile이 없으면, 빌드 불가 사유를 작업 결과에 명시한다.

## 8. Git 반영 기준

- 변경 파일을 확인한 뒤 의미 있는 단위로 commit한다.
- 사용자가 포스팅 진행을 요청한 경우 `main` branch에 push하여 GitHub Pages 반영까지 진행한다.
- push가 remote 변경으로 거절되면 `git pull`로 원격 변경을 통합한 뒤 다시 push한다.
