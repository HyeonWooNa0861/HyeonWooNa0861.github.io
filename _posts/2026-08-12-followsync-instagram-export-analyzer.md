---
layout: post
title: "FollowSync: 공식 Instagram ZIP으로 팔로우 관계를 점검하는 웹앱"
nav_title: "FollowSync"
date: 2026-08-12 00:10:00 +0900
categories: [Project, NextJS, Privacy]
tags: [FollowSync, Next.js, Instagram Export, JSZip, Vercel, Privacy]
permalink: /posts/followsync-instagram-export-analyzer/
section: projects
---

FollowSync는 Instagram의 공식 데이터 내보내기 ZIP을 분석해 팔로워와 팔로잉 관계를 간편하게 비교하는 웹앱이다. 계정 로그인이나 비밀번호 입력 없이 사용자가 직접 받은 데이터 사본만으로, 내가 팔로우하지만 나를 팔로우하지 않는 계정을 빠르게 확인할 수 있다.

## 1. 주요 기능

| 기능 | 사용자 가치 |
|---|---|
| 공식 ZIP 업로드 | Instagram에서 직접 내려받은 export 파일로 분석 시작 |
| 관계 비교 | followers와 following 목록을 정규화해 비상호 팔로우 계정 확인 |
| 결과 바로가기 | 결과 계정의 Instagram 프로필을 곧바로 열어 확인 |
| 단계별 가이드 | export ZIP을 만드는 과정을 한국어·영어로 안내 |
| 화면 설정 | 한국어·영어와 라이트·다크 테마 지원 |

## 2. 서비스의 의의

SNS 관계를 점검하기 위해 외부 서비스에 계정 인증을 맡기거나 두 목록을 직접 대조하는 일은 번거롭다. FollowSync는 공식 export 파일, 한 번의 업로드, 명확한 결과 목록으로 이 과정을 짧게 만든다.

핵심은 자극적인 숫자보다 사용자가 자신의 관계 데이터를 직접 소유하고 이해하도록 돕는 데 있다. 인증정보를 요구하지 않고 비교 기준을 분명히 보여주므로, 한 번의 정리부터 정기적인 관계 점검까지 설명하기 쉽고 바로 사용할 수 있다.

## 3. 사용 흐름

1. Instagram Accounts Center에서 정보 내보내기를 선택한다.
2. Followers and following 항목을 JSON 형식으로 내려받는다.
3. 받은 ZIP을 FollowSync에 업로드한다.
4. 팔로워·팔로잉 수와 비상호 팔로우 계정을 확인한다.
5. 필요한 계정은 결과의 프로필 링크로 이동해 살펴본다.

## 4. 기술과 신뢰 기준

| 영역 | 구성 |
|---|---|
| Web | Next.js App Router, React, TypeScript |
| ZIP parsing | JSZip |
| API | Next.js Route Handler `/api/upload` |
| 비교 | 사용자 이름 정규화 후 Set 기반 차집합 |
| Trust | 로그인·비밀번호 없이 공식 export 파일만 사용 |

현재 구현은 선택된 ZIP을 서버 라우트에서 분석하고 결과를 응답하며, 코드에는 파일을 데이터베이스나 저장소에 영구 보관하는 로직을 두지 않았다.

## 5. 신뢰성과 확장 로드맵

| 현재 제공 기반 | 해결 방향 | 확장 가능성 |
|---|---|---|
| 서버 라우트에서 ZIP을 즉시 분석 | 요청 크기, 폐기 시점, 비식별 로그 정책을 화면에 명문화 | Web Worker 기반 기기 내 분석 선택지 제공 |
| 현재 Instagram export 구조를 파싱 | 형식 버전 감지와 파일별 진단 메시지 추가 | export 구조 변경에 빠르게 대응하는 모듈형 파서 |
| 한 시점의 관계 차이를 제공 | 사용자가 보관한 과거 export끼리 비교 | 관계 변화 기록, 메모, 그룹 기반 개인 데이터 관리 |

FollowSync는 공식 데이터 사본을 활용하는 단순한 흐름을 바탕으로, 개인정보 경계를 더 선명하게 하면서도 장기적인 관계 관리 도구로 확장할 수 있다.

## 6. 참고자료

<ul>
  <li><a href="https://followsync.vercel.app/" target="_blank" rel="noopener">FollowSync 웹앱</a></li>
  <li><a href="https://github.com/HyeonWooNa0861/proj_FollowSync" target="_blank" rel="noopener">FollowSync GitHub 저장소</a></li>
</ul>
