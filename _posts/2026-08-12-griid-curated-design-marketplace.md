---
layout: post
title: "gri:d: 디자이너와 컬렉터를 연결하는 큐레이션 마켓"
nav_title: "gri:d"
date: 2026-08-12 00:00:00 +0900
categories: [Project, Marketplace, Fashion]
tags: ["gri:d", Next.js, React, TypeScript, Auction, Curation]
permalink: /posts/griid-curated-design-marketplace/
section: projects
---

gri:d는 독립 디자이너의 작품을 발견하고, 저장하고, 입찰 참여까지 이어갈 수 있도록 설계한 큐레이션 기반 디자인 마켓이다. 이미지 중심 피드와 디자이너별 탐색, My Lounge, 상품 등록, 낙찰 이후의 결제 흐름을 하나의 경험으로 연결해 작품을 보는 순간부터 소장을 결정하는 순간까지의 거리를 줄인다.

## 1. 주요 기능

| 기능 | 사용자 가치 |
|---|---|
| 이미지 중심 피드 | 작품의 분위기와 디테일을 크게 보며 새로운 취향 발견 |
| 컬렉션 탐색 | 카테고리·디자이너·검색어로 관심 상품을 빠르게 선별 |
| 상품 상세 | 이미지 갤러리와 입찰 흐름을 한 화면에서 확인 |
| Watchlist와 Active Bids | 저장한 작품과 참여 중인 입찰을 My Lounge에서 관리 |
| Product Upload | 판매자가 이미지, 설명, 가격, 입찰 조건을 구성 |
| Winner Flow | 낙찰 알림과 결제 정보 입력까지 후속 거래 경험 연결 |

## 2. 서비스의 의의

gri:d는 상품 목록보다 작품의 이미지와 디자이너의 개성을 먼저 보여준다. 컬렉터는 피드를 따라 취향을 발견하고 관심 작품을 저장한 뒤 자연스럽게 입찰 흐름에 참여할 수 있다. 독립 디자이너에게는 작품을 전시하고 판매 가능성을 확인하는 공간을 제공한다.

경매형 상호작용은 희소성과 제작 배경이 중요한 패션·공예·오브젝트에 잘 맞는다. gri:d는 감상과 거래를 분리하지 않고 `발견 → 저장 → 참여 → 소장`으로 이어지는 짧고 몰입감 있는 경험을 만든다.

## 3. 사용자 흐름

1. 홈 피드에서 작품을 발견한다.
2. 카테고리와 디자이너 필터로 취향을 좁힌다.
3. 관심 작품을 Watchlist에 저장하거나 Active Bids에 추가한다.
4. My Lounge에서 저장 상품, 입찰, 등록 상품을 다시 확인한다.
5. 판매자는 상품 조건을 등록하고, 낙찰자는 안내와 결제 흐름으로 이동한다.

## 4. 기술 구성

| 영역 | 기술 |
|---|---|
| Web | Next.js App Router, React, TypeScript |
| UI | Tailwind CSS, responsive image feed |
| State | localStorage 기반 Watchlist·Active Bids |
| API | Next.js Route Handler |
| Notification | Nodemailer 기반 낙찰 알림 흐름 |
| Deploy | Vercel, GitHub Pages 정적 export 선택 지원 |

## 5. 성장 로드맵

| 현재 제공 기반 | 해결 방향 | 확장 가능성 |
|---|---|---|
| 로컬 카탈로그로 작품 탐색 경험을 제공 | 설계된 상품·이미지·카테고리 스키마에 API와 DB 연결 | 실제 판매 등록, 검색, 재고·상태 관리 |
| Watchlist와 Active Bids를 브라우저에 저장 | 사용자·입찰·주문 데이터와 계정 인증 연결 | 여러 기기 동기화와 개인화 큐레이션 |
| 낙찰 알림과 결제 입력 흐름을 화면으로 연결 | 메일 발송 정책, 주문 상태, PG 연동을 단계적으로 추가 | 낙찰부터 결제·배송까지 이어지는 거래 플랫폼 |

현재의 화면과 상호작용을 그대로 활용하면서 데이터 지속성, 인증, 결제, 알림을 단계적으로 연결할 수 있어 서비스형 마켓플레이스로 확장하기 좋은 구조다.

## 6. 참고자료

<ul>
  <li><a href="https://proj-griid.vercel.app/" target="_blank" rel="noopener">gri:d 웹앱</a></li>
  <li><a href="https://github.com/HyeonWooNa0861/proj_griid" target="_blank" rel="noopener">gri:d GitHub 저장소</a></li>
</ul>
