# GitBlog Posting Guidelines

이 문서는 새 자료를 GitBlog에 정리할 때 따르는 기준이다. 판단이 애매하면 이 순서로 결정한다.

## 0. 적용 범위와 권한

- 이 문서는 GitBlog의 콘텐츠 구조, 공개 안전, 검증, 게시 준비 기준을 정의한다.
- 사용자 요청과 상위 `AGENTS.md`의 권한·안전 규칙이 이 문서보다 우선한다. 충돌하면 상위 규칙을 따르고 충돌 내용을 보고한다.
- 글 작성·수정 요청은 로컬 콘텐츠 편집만 허용한다. commit, push, pull request, 배포는 각각 사용자가 현재 작업에서 명시적으로 요청한 경우에만 수행한다.
- 공개된 permalink와 collection 경로는 외부 링크 계약으로 취급한다. 변경이 꼭 필요하면 기존 URL을 보존하는 redirect와 링크 이전 계획을 먼저 마련한다.
- 반복 가능한 운영 규칙은 이 문서에 두고, 실제 게시 transport와 최근 성공·실패 이력은 `.LLM-Wiki/workflows/material-branches/`의 workflow와 publish log를 따른다.

## 1. 기본 원칙

- 원본 자료는 원래의 로컬 작업 위치에 보존하고, 블로그에는 읽기 쉬운 Markdown 정리본을 제공한다. PDF 자체는 재배포 근거가 확인된 경우에만 공개 자산으로 복제해 링크하며, 근거가 없으면 원본명·제공 맥락·공개 원문 URL만 기록하고 파일은 첨부하지 않는다.
- 정리본은 원문 자료의 주요 범위와 논지를 충실히 따라야 한다. 읽기 쉽게 재구성하되, 원문에서 비중 있게 다룬 장, 절, 코드 예제, 수식, 표, 결론을 임의로 누락하지 않는다.
- 파일명과 폴더명은 영문 kebab-case를 사용한다.
- `research_files` 원천 자료에 논문 별칭이 있으면 최종 원문 PDF와 최종 번역본 Markdown 파일명은 별칭을 맨 앞에 둔다. 이 별칭 우선 규칙은 제목 기반 slug 규칙보다 우선한다. 예: `cola-preserving-..._원문.pdf`, `cola-preserving-..._번역본.md`.
- 별칭 우선 파일명 규칙은 `*_원문.pdf`와 `*_번역본.md` 같은 최종 산출물에만 적용하고, 추출 후보, review packet, report, sidecar metadata 같은 중간 산출물에는 적용하지 않는다.
- 기존 collection, URL, sidebar 구조를 우선한다.
- `_posts`, `_research`, `_study`, `_assignment`의 모든 공개 문서는 front matter에 `date: YYYY-MM-DD HH:MM:SS +0900` 형식의 최초 등록 시각을 둔다. 이 값은 `Latest accessions`와 `Accession Log`의 collection 통합 정렬 기준이며, 기존 문서를 수정할 때 임의로 갱신하지 않는다.
- 게시 후 내용을 실질적으로 수정한 경우 최초 `date`는 보존하고 `last_modified_at: YYYY-MM-DD HH:MM:SS +0900`을 선택적으로 추가하거나 갱신한다. 오탈자처럼 의미가 바뀌지 않는 수정에는 필요하지 않다.
- `_config.yml`의 `future: true`에서는 미래 시각도 즉시 공개될 수 있으므로, `date`와 `last_modified_at`은 현재 시각보다 미래일 수 없다. 예약 게시는 날짜만 미래로 적는 방식으로 처리하지 않고 별도의 배포 정책을 먼저 마련한다.
- 실질적인 게시물 본문을 제외한 공개 UI와 콘텐츠 메타데이터는 영어로 작성한다. 여기에는 front matter의 `title`, `nav_title`, `topic`, 공개되는 category/tag, navigation title/description, index와 card의 제목·설명, tab/sidebar label, 버튼, 상태 문구가 포함된다.
- front matter, `_config.yml`, navigation의 공개 문자열은 정상적인 작은따옴표·큰따옴표와 기호를 사용할 수 있다. 대신 layout·include·index에서 동적 문자열을 HTML로 출력할 때 마지막에 Liquid `escape` filter를 적용한다. `href`·`src`가 읽는 URL 필드는 scheme과 attribute delimiter를 별도로 검증하며, metadata에 raw HTML markup을 저장하지 않는다.
- 본문이 한국어여도 posting title과 index에 노출되는 이름은 영어로 유지한다. 한국어는 본문의 해설, 표, 예제, 인용 맥락처럼 실제 내용을 전달하는 영역에서만 사용한다.
- 수상 실적, 증명서, 확인서처럼 본문 해설 대상이 아닌 증빙 PDF는 별도 포스트를 만들지 않고, 관련 포스트의 하단 참고자료/source 목록에 첨부한다.
- 수식은 Kramdown이 MathJax용 HTML로 변환할 수 있는 문법을 사용한다. Markdown source의 inline 수식은 같은 줄의 `$$...$$`, display 수식은 각각 독립된 줄의 `$$` 사이에 작성한다. 코드 예제를 제외하고 raw `\(...\)`·`\[...\]` delimiter를 source에 직접 쓰지 않는다. Kramdown이 이 backslash를 Markdown escape로 소비해 수식이 일반 괄호 텍스트로 깨질 수 있다.
- superscript/subscript가 LaTeX 명령이나 여러 token을 포함하면 항상 brace로 묶는다. 예: `h^{\top}`, `XX^{\top}`, `w_0(1+g)^{\rho}`, `\lVert x\rVert_2^{2}`.
- 수식 기호와 변수명은 원본 PDF notation을 우선한다.
- 강의 중 정정된 수식이 확인되면 원본 PDF보다 정정 사항을 우선한다.
- 정정 내용이 "불필요한 변수 제거"라면 다른 문자로 단순 치환하지 말고 수식을 재작성한다.
- 원본에 없는 보조 수식을 넣을 때는 설명용 확장임이 드러나게 작성한다.
- 실제 코드와 의사코드는 수식으로 바꾸지 않는다.

### MathJax 작성·렌더링 체크리스트

1. Markdown source delimiter는 inline `$$...$$`, display block의 독립된 `$$` 줄만 사용한다. raw `\(...\)`·`\[...\]` delimiter는 코드 예제 밖에서 금지한다. 단, 수식 안의 LaTeX 명령은 단일 backslash로 작성한다. 예: `\alpha`, `\top`, `\mathrm{diag}`. `\\alpha`, `\\top`처럼 이중 escape하지 않는다.
2. `\\`는 `aligned`, `align`, `matrix`처럼 여러 행을 허용하는 환경 안의 행 구분에만 사용한다. 일반 수식이나 Markdown의 줄바꿈 용도로 사용하지 않는다.
3. 모든 LaTeX 명령과 수식 기호는 Kramdown용 `$$...$$` 안에 둔다. delimiter 쌍, `\begin{...}`과 같은 이름의 `\end{...}`, `{`와 `}`가 각각 균형을 이루는지 확인한다. 생성된 HTML에서는 Kramdown이 inline 수식을 `\(...\)`, display 수식을 `\[...\]`로 변환했는지 확인한다.
4. HTML `<details>` toggle의 opening tag는 항상 `<details markdown="block">`으로 작성한다. 이 opt-in이 없으면 Kramdown이 답변 안의 문단, 목록, 강조와 display 수식을 Markdown으로 변환하지 않고 literal text로 남길 수 있다. 기존 class나 접근성 속성이 있으면 제거하지 말고 `markdown="block"`을 함께 둔다.
5. HTML `<summary>` 안에 Markdown 또는 MathJax를 쓸 때는 opening tag를 `<summary markdown="span">`으로 작성한다. 특히 `$$...$$` 수식이 있는 summary에서 이 속성을 생략하면 Kramdown이 내부를 inline Markdown으로 변환하지 않으므로 필수이다. 기존 class나 접근성 속성이 있으면 제거하지 말고 `markdown="span"`을 함께 둔다.
6. Same-line inline 수식에는 raw `|`를 쓰지 않는다. Kramdown GFM이 수식 delimiter보다 먼저 이를 Markdown table 열 구분자로 해석해 수식 전체를 분해할 수 있으며, 실제 table 셀 안이 아니어도 같은 문제가 발생한다. 조건부 관계는 `\mid`, cardinality·절댓값은 `\lvert ... \rvert`, norm은 `\lVert ... \rVert`를 우선하고, literal pipe가 꼭 필요하면 `\|`로 escape한다.
7. 자동 validator와 Jekyll build를 통과한 뒤 변경된 수식이 있는 대표 페이지를 실제 렌더링해 desktop과 mobile 폭에서 확인한다. raw 명령, 노출된 delimiter, 누락된 기호, 잘린 행 또는 table 열 분리가 없어야 한다.
8. 정적 검사나 실제 렌더링에서 수식 손상이 하나라도 확인되면 원인을 수정하고 다시 검증할 때까지 commit·push·배포하지 않는다.

### Collection별 front matter 계약

| Collection | 필수 필드 | 선택 필드와 조건 |
|---|---|---|
| `_posts` | `layout: post`, `title`, `date`, `categories`, `tags`, `permalink`, `section` | 짧은 탐색명이 필요하면 `nav_title`; 실질 수정 시 `last_modified_at` |
| `_research` | `layout: default`, `date`, `title`, `topic`, `order`, `major_topic`, `keywords` | 논문 별칭은 `title`에 우선; 실질 수정 시 `last_modified_at` |
| `_study` | `layout: default`, `date`, `title`, `course`, `topic`, `order`, `major_topic`, `keywords` | 실질 수정 시 `last_modified_at` |
| `_assignment` | `layout: default`, `date`, `title`, `course`, `topic` | 목록 정렬이 필요한 경우 `order`; 실질 수정 시 `last_modified_at` |
| `pages/`, `post/` index | `layout: default`, `title`, `permalink` | collection 글과 달리 등록 시각이 필요할 때만 `date`; 공개 UI 본문은 영어 |

- `date`와 `last_modified_at`은 `YYYY-MM-DD HH:MM:SS +0900` 형식을 사용한다.
- `_posts` 파일명의 `YYYY-MM-DD`와 front matter `date`의 날짜는 같아야 한다.
- `_posts`의 `permalink`는 `/posts/<영문-kebab-case>/` 형식을 사용하고 중복을 허용하지 않는다.
- `_research`의 `order`는 collection 전체에서, `_study`의 `order`는 course 안에서 중복되지 않게 한다.
- 필수 필드 추가나 의미 변경은 먼저 실제 collection 전체를 검사하고, 기존 문서와 navigation을 함께 마이그레이션할 수 있을 때만 적용한다.

### 공개 안전, 권리와 개인정보

- 공개 저장소에 API key, token, password, private key, 내부 URL, 비공개 저장소 주소, 공개 목적과 사용자 승인이 없는 개인 연락처나 식별 정보가 포함되지 않았는지 확인한다. About/Profile에 사용자가 공개를 명시적으로 승인한 연락 수단과 프로필 링크는 허용한다.
- 증명서·확인서·과제·화면 캡처를 공개할 때 이름, 학번, 이메일, 서명, QR 코드, 계정 식별자 등 불필요한 개인정보를 제거한다.
- 이미지와 PDF는 필요하면 EXIF·작성자·로컬 경로 등 공개할 필요가 없는 metadata를 제거한 뒤 게시한다.
- 외부 이미지, 도표, 코드, PDF, 번역문은 소유권·라이선스·직접 허가·공개 도메인 등 재배포 근거가 확인된 범위에서만 복제한다. 단순 열람만 허용된 원문은 원본 링크와 짧은 인용을 사용한다.
- 인용에는 출처와 원문 링크를 남기고, 수정·번역·재구성했다면 그 사실을 밝힌다. 공개 전체 번역은 게시 권한의 근거를 `번역·게시 권한` 항목에 기록한다.

### 접근성, 링크와 자산

- 의미 있는 이미지에는 내용을 전달하는 대체 텍스트를 넣는다. 장식 이미지는 빈 `alt`를 사용할 수 있지만 `role="presentation"` 또는 `aria-hidden="true"`로 장식 목적을 명시해야 한다.
- 제목은 문서 H1 다음에 H2, H3 순으로 내려가며 시각적 크기만을 위해 heading level을 건너뛰지 않는다.
- 링크 문구는 `여기`, `링크` 대신 대상과 목적을 설명한다. 외부 링크는 새 창으로 열고 `target="_blank" rel="noopener"`를 함께 둔다. 속성을 안정적으로 선언할 수 없는 `<https://...>` 형태의 외부 autolink는 사용하지 않는다.
- `javascript:`, `vbscript:`, `data:`, `file:`처럼 실행·내장·로컬 접근을 유발하거나 공개 웹 경로가 아닌 URI scheme은 링크와 이미지에 사용하지 않는다.
- URL의 scheme이나 구분자를 HTML named character reference로 숨기지 않는다. validator가 해석하지 못하는 named reference가 URL에 필요하면 percent-encoding이나 검증 가능한 직접 URL로 바꾼다.
- 내부 route와 자산 링크는 문서 위치에 따라 의미가 달라지는 상대 경로 대신 `/`로 시작하는 site-root 경로 또는 명시적인 `relative_url` 표현을 사용한다.
- 게시물의 Liquid 링크는 `{{ "/site-root/path/" | relative_url }}`처럼 정적인 site-root literal만 사용한다. 변수 기반 링크는 검증된 navigation·collection 값을 소비하는 사전 등록된 index/layout/include 템플릿에서만 허용하고, 새 변수 링크를 추가할 때는 출처와 렌더 결과를 확인해 validator allowlist를 함께 갱신한다. navigation 값 자체에는 Liquid를 넣지 않는다.
- Liquid로 HTML tag 이름, attribute 이름, 또는 여러 attribute를 담은 fragment를 생성하지 않는다. 조건부 `target`/`rel`이 필요하면 Liquid 분기를 opening tag 밖에 두고 검증 가능한 두 opening tag 형태로 작성한다.
- 같은 HTML 또는 Kramdown attribute list 안에 같은 속성을 두 번 선언하지 않는다. 중복 속성은 브라우저와 검사기가 서로 다른 값을 선택할 수 있으므로 게시 오류로 취급한다.
- 원문 reader는 사용자가 링크를 선택할 때만 열고 초기 상태는 `[hidden]`으로 강제 숨긴다. 열린 reader에는 영어 `Open`과 `Hide` 동작을 제공한다. PDF·이미지·내부 문서와 공식 YouTube video/playlist URL은 reader에서 열고, 원래 URL은 `Open`으로 유지한다. YouTube는 HTTPS의 공식 host와 `watch`, `youtu.be` 루트, `embed`, `shorts`, `live`, `playlist` 경로만 허용하고 공식 `https://www.youtube.com/embed/...` iframe 형식으로 변환한다. `Preview unavailable?`처럼 본문 위에 계속 겹치는 fallback 안내는 두지 않는다.
- URL suffix만으로 resource type을 넓게 추정하지 않는다. 확장자 없는 PDF는 검증된 host/path allowlist 또는 명시적 metadata가 있을 때만 reader에 연결하고, Wikimedia Commons의 `/wiki/File:...`처럼 파일명으로 끝나도 실제로는 HTML 설명 페이지인 URL은 이미지 preview에서 제외한다.
- 외부 PPT/PPTX·Word·Excel은 임의의 viewer URL을 조합하지 않는다. Microsoft가 안내하는 방식처럼 공개 OneDrive/PowerPoint for the web에서 발급한 공식 iframe `src`가 확보된 문서만 reader에 연결하고, 그렇지 않으면 검증된 원문 direct link를 유지한다.
- 코드 fence에는 가능한 한 언어를 지정하고, 표만으로 전달하기 어려운 핵심 관계는 표 앞뒤의 문장으로도 설명한다.
- 내부 링크와 `assets/` 경로는 대소문자까지 실제 파일·route와 같아야 한다. 신규 공개 자산에는 공백, 임시 숫자명, 대문자·underscore 혼합명을 사용하지 않는다. 이미 공개된 legacy 자산은 URL 안정성을 우선해 그대로 보존하고, 이전이 필요하면 새 kebab-case 사본과 호환 링크를 마련한 뒤 내부 참조를 단계적으로 바꾼다.
- navigation 최상위 `url`과 모든 `match`는 `/`로 시작하는 실제 내부 route여야 한다. 하위 `url`과 `source_url`은 실제 내부 route 또는 명시적인 `http://`·`https://` URL만 허용하며 protocol-relative URL(`//...`)과 Liquid 값은 사용하지 않는다. 모든 collection 문서와 index page를 합친 실제 출력 route는 중복될 수 없고, Research 전체와 Study·Assignment의 같은 course 안에서는 `order`를 중복 사용하지 않는다.

### 원문 충실성 기준

PDF, 이미지, 논문, 과제 원문을 바탕으로 글을 작성할 때는 다음을 반드시 확인한다.

- 작성 전 원문을 한 번 훑어 전체 목차, 페이지별 주제, 반복해서 등장하는 핵심 키워드를 파악한다.
- 작성 후 원문을 다시 대조해 각 주요 페이지 묶음 또는 장이 Markdown 본문 어딘가에 반영되었는지 확인한다.
- 원문에서 여러 페이지에 걸쳐 다룬 내용은 한두 문장으로만 처리하지 말고, 학습자가 복습할 수 있을 정도로 예시와 차이를 함께 정리한다.
- 원문 코드 예제는 그대로 복붙하기보다 설명 가능한 형태로 재구성하되, 함수 이름, 매개변수 의미, 반환값, 주의점은 빠뜨리지 않는다.
- 원문 수식과 알고리즘은 notation을 유지하고, 변형하거나 보조 설명을 추가할 때는 원문 내용과 작성자 설명을 구분한다.
- 원문에 있는 범위를 의도적으로 생략해야 할 경우, “이 글에서는 ... 범위만 다룬다”처럼 생략 범위를 명시한다.
- 게시 전 `Source PDF` 또는 `Source Images` 표기와 하단 자료 섹션이 서로 일치하는지 확인한다. 재배포 근거가 없는 로컬 원문은 상단과 하단 모두에서 `locally supplied; not redistributed`처럼 비공개 첨부 상태를 명시하고, 공개 원문 URL이 있을 때만 링크한다.
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

- 원문 PDF, 영상, 웹 문서, 이미지 자료의 핵심 범위를 충실히 반영한다. 시험 대비용으로 재구성하더라도 원문에서 큰 비중을 차지하는 장이나 예제를 누락하지 않는다.
- 원문 슬라이드의 중요한 수식을 모두 식별하고 본문의 대응 구간에서 설명한다. 원문에 증명이나 유도 과정이 없으면 아래 `수식 해설 및 증명 규칙`에 따라 단계별 유도 또는 증명 개요를 보충한다.
- Source 표기 다음에 강의의 결론과 학습 이유를 압축한 핵심 메시지를 두고, 본문 끝에는 `마지막 핵심 정리`를 둔다.
- 복습 질문은 답변을 포함한다.
- 복습 질문 답변은 HTML `<details markdown="block">` / `<summary>` toggle 형식으로 작성한다. `<details>`의 `markdown="block"`은 답변 문단·목록·강조·display 수식의 Kramdown 변환을 위해 필수이다.
- `<summary>`에는 질문을 쓰고, 펼친 내용에는 간결하지만 충분한 답변을 쓴다. 질문에 Markdown 또는 MathJax가 포함되면 `<summary markdown="span">`을 사용한다.
- 원문 순서를 그대로 베끼기보다 다시 읽기 쉬운 학습 구조로 정리한다.

### 수식 해설 및 증명 규칙

- 중요한 수식은 강의의 결론·알고리즘·모델 정의·성능 해석·시험 포인트에 직접 쓰이거나, 뒤의 전개가 의존하는 식을 뜻한다. 작성 전 슬라이드별 수식 목록을 만들고 각 식을 본문에서 설명했는지 대조한다.
- PDF/PPTX text extraction과 video transcript는 수식 탐색용 보조 index일 뿐 전수 검증 증거가 아니다. 수식이 raster image, vector drawing, equation object 또는 영상 화면에만 있을 수 있으므로 원본의 모든 page/slide를 읽을 수 있는 해상도로 렌더링해 시각적으로 확인하고, 수식 목록에 page/slide 번호를 기록한다.
- 영상만 있고 공식 slide deck을 확보할 수 없다면 transcript와 timestamp frame을 함께 대조한다. 화면 수식을 확인할 수 없는 구간이 남으면 해당 범위를 명시하고 `전체 수식 검증 완료`로 보고하지 않는다.
- 원문에 증명이나 유도 과정이 없으면, 필요한 정의에서 출발해 중간 변형과 결론이 이어지는 단계별 유도를 제공한다. 전체 증명이 글의 범위를 크게 벗어나면 핵심 논리와 생략된 단계의 범위를 밝힌 증명 개요를 제공한다.
- 유도 전에 성립에 필요한 가정과 적용 영역을 명시한다. 예: 연속성·미분 가능성, 독립성, 선형성, 정상성, 유한 에너지, 표본화 조건, 변수의 실수·복소수 영역과 분모가 0이 아닌 조건.
- 각 수식이 **정의**, **항등식·정확한 등식**, **근사**, **경험 법칙·휴리스틱** 가운데 무엇인지 명시한다. 근사에는 유효 조건과 오차가 커지는 상황을, 정확한 등식에는 성립 조건을 함께 적는다.
- 식에 등장하는 기호를 처음 사용할 때 이름과 의미를 정의하고, 물리량이면 SI 단위 또는 원문이 사용하는 단위를 표로 정리한다. 무차원량·지수·표본 index처럼 단위가 없는 기호도 `무차원`으로 표시한다.
- 유도 뒤에는 식이 직관적으로 무엇을 뜻하는지와 어떤 입력·가정·경계 조건에서 해석이 실패하거나 사용할 수 없는지를 설명한다.
- 경험적으로 관찰된 비례식, 보정식, 모델 적합식에는 존재하지 않는 수학적 증명을 만들지 않는다. `경험 법칙`, `근사`, `보정식` 등으로 표시하고 관측 근거·적합 조건·적용 한계를 설명한다.
- 유도가 글 안에서 완결되지 않거나 일반적인 기초 지식만으로 확인하기 어려우면, 해당 단계의 교재·논문·공식 문서 등 외부 유도 출처를 바로 옆이나 참고자료에 인용한다. 출처가 원문의 주장만 반복하고 실제 유도를 제공하지 않으면 유도 근거로 사용하지 않는다.

Study 수식 검증 체크리스트:

1. 원문 슬라이드의 중요한 수식마다 본문의 대응 위치가 있는가?
2. 원문에 없는 유도는 작성자의 보충 해설임을 구분했는가?
3. 유도의 시작 가정, 적용 영역과 필요한 정의를 명시했는가?
4. 등호·정의·근사·비례·경험 법칙을 서로 구분했는가?
5. 중간 단계가 생략되어 결론이 갑자기 나오지 않는가?
6. 모든 핵심 기호의 의미와 단위 또는 무차원 여부를 정의했는가?
7. 수식의 직관, 사용 조건과 실패 조건을 설명했는가?
8. 자체 완결적이지 않은 유도에 검증 가능한 외부 출처가 있는가?
9. 경험식에 증명을 꾸며내지 않고 관측 근거와 적용 한계를 적었는가?
10. Text extraction이나 transcript에만 의존하지 않고 모든 source page/slide를 시각적으로 확인했는가?
11. 각 중요 수식의 source page/slide 또는 video timestamp와 본문 위치를 대조할 수 있는가?

이 체크리스트는 의미 정확성을 다루므로 자동 validator 통과만으로 대체하지 않는다. 게시 전 원문 대조와 수식 재계산을 포함한 수동 검증을 수행한다.

권장 구성:

- 제목과 자료 유형에 맞는 Source 표기
- 초반 핵심 메시지
- 전체 흐름
- 개념별 정리
- 핵심 수식 또는 코드 예제
- 시험 포인트
- 마지막 핵심 정리
- Study Guide
- 복습 질문
- 재배포가 허용된 원문 자료 링크 또는 비공개 첨부 상태와 공개 참고자료

Study 공통 구조 참고:

```md
---
layout: default
date: 2026-01-01 10:00:00 +0900
title: "English Title"
course: "Course Name"
topic: "English Topic"
order: 1
major_topic: "English Major Topic"
keywords:
  - "Keyword One"
  - "Keyword Two"
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

<details markdown="block">
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
- 원문이 PDF이면 상단에 `Source PDF:` 형식으로 파일명을 명시한다. 재배포 근거가 확인된 PDF만 하단 `## PDF`에서 같은 공개 자산을 링크한다. 근거가 없으면 `locally supplied; not redistributed`를 함께 적고 하단 `## Source Materials`에서 비공개 첨부 상태와 공개 가능한 원문·참고 URL을 기록한다.
- 원문이 영상·웹 문서·이미지이면 `Source:`, `Source Materials:`, `Source Images:` 중 자료 유형에 맞는 표기를 사용하고, 하단에는 `## References` 또는 `## Source Materials`로 원문 링크를 제공한다. PDF가 없는 자료에 `Source PDF`나 `## PDF`를 만들지 않는다.
- 본문 순서는 `전체 흐름` → 개념별 본문 → `마지막 핵심 정리` → `Study Guide` → `복습 질문` → 원문 자료 링크를 기본으로 한다.
- 복습 질문은 반드시 `<details markdown="block">` / `<summary>` toggle 형식으로 작성하고, 답변은 `답변:`으로 시작한다.
- `<details>` 내부에서 `Vector<int>`처럼 `<`, `>`가 들어간 코드는 HTML 태그로 오해될 수 있으므로 `<code>Vector&lt;int&gt;</code>`처럼 HTML escape하여 쓴다.
- 원문 PDF가 여러 개라면 상단에는 `Source PDFs:` 아래 목록을 두고, 재배포가 허용된 파일만 하단 `## PDF`에 링크한다. 비공개 파일은 각각 `not redistributed`로 표시한다. 다른 유형의 원문이 여러 개라면 같은 원칙을 `Source Materials`와 대응하는 하단 섹션에 적용한다.

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
- 풀이과정과 정답은 HTML `<details markdown="block">` / `<summary>` toggle 형식으로 작성한다. Summary 문구에 Markdown 또는 MathJax가 포함되면 `<summary markdown="span">`을 사용한다.
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

- Markdown: `_assignment/<course>/<slug>.md`
- PDF: `assets/pdfs/assignment/<course>/`
- URL: `/assignment/<course>/<slug>/`
- 현재 course: `aix`, `cpp`, `machine-learning-basic`

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

- Markdown: `_study/<course>/<slug>.md`
- PDF: `assets/pdfs/study/<course>/`
- URL: `/study/<course>/<slug>/`
- 새 course는 같은 slug로 `pages/study/<course>.md`와 navigation entry를 함께 추가한다.

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

검증은 게시 후 선택 작업이 아니라 commit·push·배포 전 필수 게이트이다. 필수 검증이 실패하면 수정하거나, 안전하게 해결할 수 없는 정확한 이유를 보고하고 게시 단계로 진행하지 않는다.

자동 검증:

1. `ruby scripts/validate_blog.rb`
   - collection과 공개 index page의 front matter 필수 필드, 값의 type, layout과 날짜 형식
   - `_config.yml` 구조와 공개 static include 경로
   - `_posts` 파일명 날짜와 front matter 날짜 일치
   - 전체 출력 route·order 중복과 미래 시각
   - 공개 metadata 및 index/template UI의 언어 경계와 동적 Liquid 출력의 HTML escaping
   - 내부 route·로컬 자산 경로, 이미지 대체 텍스트, 외부 링크의 새 창 안전 속성
   - Markdown table 열, Kramdown GFM code fence, MathJax source delimiter, `<details markdown="block">`와 `<summary markdown="span">` 구조의 기본 무결성
   - 공개 대상 text file 전체의 일반적인 secret/private-key signature 보조 검사
2. `git diff --check`
3. `node scripts/test_resource_reader.cjs`
   - reader가 초기 상태에서 숨겨지고 persistent fallback을 만들지 않는지 확인한다.
   - 공식 YouTube video/playlist URL이 검증된 iframe URL로 변환되며 잘못된 ID와 다른 host는 거부하는지 확인한다.
   - 확장자 없는 PDF allowlist, 일반 download URL 거부, Wikimedia 설명 페이지와 raw image의 구분을 회귀 검사한다.
4. Kramdown 2.4.0이 준비된 환경에서 `ruby scripts/test_kramdown_math_render.rb`
   - 모든 공개 `<details markdown="block">` 답변을 실제 HTML로 변환해 literal `$$` delimiter나 변환되지 않은 Markdown 문법이 남지 않는지 검사한다.
   - `<summary markdown="span">` 안의 수식은 display가 아니라 inline MathJax delimiter로 변환되는지 별도로 검사한다.
5. CI 또는 MathJax test dependency가 준비된 환경에서 `NODE_PATH=<mathjax-full 설치 경로>/node_modules node scripts/test_mathjax_tex_render.cjs`
   - production CDN과 같은 MathJax 3.2.2 TeX parser로 모든 공개 Markdown 수식을 compile한다. Production `tex-chtml`이 기본 또는 autoload로 지원하는 명령 범위를 검사하되, 오류를 숨기는 `noundefined`·`noerrors`는 의도적으로 제외하고 `formatError`를 예외로 바꿔 알 수 없는 LaTeX 명령도 실패로 처리한다.
   - fenced·indented·inline code와 `<code>`, `<pre>`, `<script>`, `<style>`, `<textarea>`처럼 production MathJax가 건너뛰는 영역은 compile 대상에서 제외하고, 실제 렌더 대상 수식에서 오류가 하나라도 생기면 실패한다.
6. GitHub Pages와 같은 Ruby 3.3.4·`github-pages` 232 환경에서 `jekyll _3.10.0_ build --safe --strict_front_matter --destination <temporary-output>`
   - 공개 저장소 안에 `_site`나 cache를 남기지 않도록 임시 출력 경로를 사용한다.
   - CI와 게시 직전 검증은 실제 GitHub Pages의 safe-mode Jekyll build까지 성공해야 통과로 본다.

수동 검증:

- 원문 주요 범위와 핵심 결론이 본문에서 추적되는가?
- Study 글은 원문 수식 목록과 본문 대응 구간을 대조하고, `Study 수식 검증 체크리스트`의 가정·유도·표기·단위·직관·실패 조건·출처 항목을 모두 확인했는가?
- 인용·이미지·PDF·번역의 공개 및 재배포 근거가 있는가?
- 개인정보와 비공개 정보가 제거되었는가?
- 새 navigation 항목과 내부 링크가 실제 독자 흐름에 맞는가?
- 수식, 표, `<details>`, 코드, 이미지가 브라우저와 모바일 폭에서 읽히는가?

로컬에 같은 GitHub Pages 실행 환경이 없으면 CI와 동일한 격리된 임시 gem 환경을 만들거나, CI build 결과를 확인하기 전까지 빌드 미검증 상태로 둔다. 시각적 변경이나 새 레이아웃은 BrowserOS로 렌더링을 확인하며, 소유한 page target을 확보할 수 없으면 그 검증 공백을 보고한다. GitHub Actions는 pull request와 main 반영 후의 회귀 검사를 제공하지만, branch protection의 required check 설정이 확인되지 않은 상태에서는 직접 push 전 게이트를 대신하지 않는다.

## 10. Git

- 편집 요청만으로 commit이나 push를 수행하지 않는다. 현재 작업에서 사용자가 명시적으로 요청한 동작만 수행한다.
- commit 전에 `git status`와 staged diff를 확인하고, 현재 작업 파일만 stage한다. 관련 검증이 통과한 뒤 의미 있는 단위로 commit한다.
- push 전에는 매번 provider/host, owner 또는 organization, repository, remote 이름 또는 URL, branch의 전체 destination tuple을 사용자에게서 확인한다. checkout, 과거 대화, `origin`, 기본 branch로부터 추론하지 않는다.
- 원격 branch를 먼저 읽고 예상 parent와 다르면 push하지 않는다. 원격 변경 통합은 현재 작업 범위에서 안전한 방식이 분명할 때만 수행하며, 예상하지 못한 divergence는 보고하고 중단한다.
- push는 non-force fast-forward만 허용한다. force push, branch/tag 삭제, 사용자 변경 폐기, `git reset --hard`를 사용하지 않는다.
- 게시 후에는 공개 원격 ref와 실제 tree/content를 다시 확인한다. connector가 commit metadata를 정규화해 SHA가 달라지면 commit SHA 동일성과 content 동일성을 구분해 보고한다.

## 11. 수정, 정정과 되돌리기

- 게시 후 URL은 원칙적으로 유지한다. 제목이나 분류를 바꾸더라도 기존 permalink를 보존하고, 불가피한 URL 변경에는 redirect와 navigation·내부 링크 갱신을 포함한다.
- 사실·수치·결론이 바뀌는 수정은 `last_modified_at`을 기록하고, 독자의 해석에 영향을 주면 본문 또는 참고자료에 짧은 정정 내용을 남긴다.
- 원자료 접근 불가, 권리 불명확, 개인정보 노출, 빌드 실패, 잘못된 navigation이 발견되면 새 게시를 중단한다. 이미 공개된 문제는 영향 범위를 확인하고 가장 작은 수정 또는 검증된 이전 상태로 복구한다.
- 되돌리기 전에 현재 원격 ref와 대상 commit을 고정해 확인한다. 다른 작업을 포함한 광범위한 reset이나 force push 대신 역방향 commit 등 이력이 보존되는 방법을 사용한다.
