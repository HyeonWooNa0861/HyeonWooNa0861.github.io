---
layout: post
title: "PinSpot: K-콘텐츠 장소를 발견하는 모바일 PWA"
nav_title: "PinSpot"
date: 2026-08-11 00:00:00 +0900
categories: [Project, PWA, KContent]
tags: [PinSpot, React, MapLibre, OpenFreeMap, On-device AI, Curated Data]
permalink: /posts/pinspot-k-content-place-discovery-pwa/
section: projects
---

PinSpot은 K-pop 아티스트와 한국 배우, 드라마·영화·뮤직비디오에 연결된 장소를 지도에서 탐색하는 모바일 우선 PWA다. 공개 근거를 검토한 장소 정보와 주변 스팟, 도보 경로, 기기 내 사진 비교를 하나의 여행 흐름으로 제공한다.

## 1. 주요 기능

| 기능 | 핵심 역할 |
|---|---|
| 홈 | 아티스트·작품·장소 검색과 추천 코스 탐색 |
| 지도 | 검증 장소, 현재 위치, 주변 스팟과 도보 경로 표시 |
| 카메라 | 선택한 사진을 등록된 장소 레퍼런스와 기기 안에서 비교 |
| 스토어 | 공개 행사·티켓·굿즈 정보와 공식 링크 제공 |
| 프로필 | 방문 기록, 위시리스트, 언어와 테마를 브라우저에 저장 |

한국어를 포함한 8개 표시 언어와 라이트·다크 테마를 지원하며, 홈 화면에 설치할 수 있는 PWA로 구성했다.

## 2. 데이터 신뢰 기준

PinSpot은 검색 결과를 곧바로 아티스트 관련 장소로 취급하지 않는다.

- `관련 장소`: 공개 근거와 장소 정체성을 검토한 결과
- `큐레이션 추천`: 팬 페이지·블로그 등에서 찾은 방문 아이디어
- `사진 유사 후보`: 이미지가 등록된 장소와 비슷하다는 결과

세 결과는 서로 다른 의미를 가지며 자동으로 같은 신뢰 단계로 승격되지 않는다.

## 3. 개인정보와 비용 경계

- 선택한 사진은 서버나 외부 AI 서비스로 전송하지 않는다.
- 현재 위치는 권한을 허용했을 때만 사용하며 영구 저장하지 않는다.
- 방문 기록과 위시리스트는 계정 없이 현재 브라우저에만 저장한다.
- 런타임 LLM이나 유료 API 키 없이 오픈데이터와 로컬 검색을 사용한다.

사진 비교는 오픈소스 CLIP 모델을 브라우저에서 실행한다. 등록된 레퍼런스가 제한적이므로 결과는 장소 확정이 아닌 후보 안내로 사용한다.

## 4. 기술 구성

| 영역 | 기술 |
|---|---|
| Web | React, TypeScript, Vite |
| Map | MapLibre GL JS, OpenFreeMap |
| API | Express |
| Data | Versioned JSON, SQLite FTS5 |
| Photo matching | Transformers.js, ONNX Runtime Web, CLIP |
| PWA | vite-plugin-pwa, Workbox |

## 5. 현재 한계

- 사진 매칭이 지원하는 장소가 제한적이다.
- 일부 세부 화면은 다국어 적용 범위가 다르다.
- 개인 기록은 다른 기기와 동기화되지 않는다.
- 공개 지도·검색·라우팅 서비스의 가용성에 영향을 받는다.

PinSpot의 핵심은 많은 결과를 보여주는 것이 아니라, 검토된 장소와 추천, 사진 후보를 구분해 K-콘텐츠 여행 탐색을 돕는 데 있다.

## 6. 참고자료

<ul>
  <li><a href="https://pinspot-kmu.vercel.app/" target="_blank" rel="noopener">PinSpot 웹앱</a></li>
  <li><a href="https://maplibre.org/maplibre-gl-js/docs/" target="_blank" rel="noopener">MapLibre GL JS</a></li>
  <li><a href="https://openfreemap.org/" target="_blank" rel="noopener">OpenFreeMap</a></li>
</ul>
