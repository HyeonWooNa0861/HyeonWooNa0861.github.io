---
layout: post
title: "AWS Charting: AI-Powered U.S. Stock Risk Dashboard"
nav_title: "AWS Charting"
date: 2026-06-30 00:00:00 +0900
categories: [BootCamp, Project, AIWorkflow]
tags: [AWS Charting, AI Workflow, Stock Dashboard, Groq AI, Next.js]
permalink: /posts/nxtcloud-boot-camp-day-5-aws-charting/
section: nxtcloud-boot-camp
---

AWS Charting은 미국 주식 초보자가 시장 전체의 흐름과 개별 종목의 위험을 한 화면에서 이해하도록 만든 AI 기반 대시보드다. S&P 500, 종목 차트, 뉴스, 기술 지표와 AI 요약을 연결해 흩어진 정보를 빠르게 비교하고 다음에 확인할 근거를 찾도록 돕는다.

이 서비스는 nxtcloud Boot Camp 5일차 AI Workflow 프로젝트로 시작했다. 데이터 수집부터 뉴스 분류, 위험 분석, 시각화와 배포까지 하나의 경험으로 완성해 AI가 금융 정보를 어떻게 해석 보조 도구로 바꿀 수 있는지 보여준다.

> **핵심 메시지:** AWS Charting의 가치는 가격 차트 하나가 아니라 시장 위험, 종목 뉴스, 기술 지표와 AI 해석을 같은 판단 흐름에 놓는 데 있다. 외부 AI나 데이터 provider가 실패해도 fallback과 상태 안내를 통해 교육용 분석 경험을 유지하도록 설계하는 것이 핵심이다.

## 1. 서비스 개요

nxtcloud Boot Camp 5일차 작업물은 `AWS Charting`이라는 미국 주식 위험 분석 대시보드다. 이 프로젝트는 주식 데이터를 단순히 차트로 보여주는 데서 멈추지 않고, 뉴스, 시장 지표, 기술적 지표, AI 분석을 결합해 사용자가 종목 위험을 빠르게 파악할 수 있게 구성한 교육용 서비스다.

이 글은 배포 서비스와 공개 저장소를 기준으로 서비스 가치, 기능, 데이터 흐름, 기술 구성과 확장 로드맵을 정리한다.

## 2. 서비스가 해결하는 문제

주식 투자 판단에는 가격 변화뿐 아니라 시장 전체에 영향을 주는 거시 요인과 개별 종목에 영향을 주는 뉴스가 함께 작용한다. 그러나 초보 사용자가 금리, 달러, 반도체 이슈, 종목별 뉴스, PER, RSI, 변동성 같은 정보를 한 화면에서 해석하기는 쉽지 않다.

`AWS Charting`은 이 문제를 체계적 위험과 비체계적 위험으로 나누어 정리한다. 체계적 위험은 금리, 달러, 반도체처럼 시장 전체에 영향을 주는 요인이고, 비체계적 위험은 특정 기업이나 종목에만 영향을 주는 뉴스와 지표다. 프로젝트의 핵심 목표는 이 두 위험을 분리해 보여주고, AI가 각 종목의 상태를 `관심`, `관망`, `주의` 같은 판단으로 요약하게 만드는 것이다.

## 3. 전체 기능 흐름

| 구분 | 기능 | 핵심 역할 |
|---|---|---|
| 시장 정보 | S&P 500 지수 조회 | 전체 시장 흐름을 확인하는 기준 지표로 사용한다. |
| 종목 차트 | 장기 캔들스틱 차트와 이동평균선 | 개별 종목의 가격 흐름을 시각적으로 확인한다. |
| 뉴스 수집 | Google News RSS 기반 기사 수집 | 시장 이슈와 종목별 뉴스를 위험 판단의 근거로 사용한다. |
| AI 분석 | Groq AI 기반 뉴스 및 종목 분석 | 호재, 악재, 중립 분류와 종목별 판단 이유를 생성한다. |
| 자동 갱신 | 1분 단위 데이터 새로고침 | 사용자가 주기적으로 갱신된 시장 상태를 확인할 수 있게 한다. |

## 4. 체계적 위험과 비체계적 위험

프로젝트는 위험을 두 층으로 나누어 설명한다. 체계적 위험 영역에서는 금리, 달러, 반도체 같은 거시 이슈를 다룬다. 이 정보는 특정 기업 하나만의 문제가 아니라 시장 전체의 방향성에 영향을 줄 수 있는 요소다. 예를 들어 금리 인상 가능성, 달러 약세, 반도체 수출 규제 검토 같은 뉴스는 여러 종목에 동시에 영향을 줄 수 있다.

비체계적 위험 영역은 개별 종목 중심이다. Apple, NVIDIA 같은 특정 종목에 관한 호재, 악재, 중립 뉴스를 따로 분류해 사용자가 종목별 위험을 파악할 수 있게 한다. 이 구조는 포트폴리오 이론에서 말하는 시장 위험과 개별 기업 위험을 웹 대시보드 UI로 구분해 보여준다는 점에서 의미가 있다.

## 5. AI 종목 분석 구조

`AWS Charting`의 주요 특징은 단순 규칙 기반 점수 계산이 아니라, 여러 지표와 뉴스를 함께 묶어 AI가 종합 판단을 제공한다는 점이다. 원본 HTML 기준으로 AI 분석에는 PER, RSI, SML 알파, 변동성, 리스크 점수, 최신 뉴스가 포함된다. 모델은 Groq AI의 `llama-3.1-8b-instant`를 사용하는 것으로 설명되어 있으며, AI 분석을 사용할 수 없을 때는 규칙 기반 분석으로 전환한다.

이 fallback은 외부 AI API의 지연이나 호출 제한 속에서도 핵심 분석 경험을 유지하는 해결책이다. 분석 계층이 분리되어 있어 향후 복수 모델 provider, 섹터별 판단 기준, 모델 상태 표시로 확장할 수 있다.

## 6. 데이터 흐름

원본 HTML에 정리된 데이터 흐름은 다음과 같다.

1. FRED API에서 S&P 500 장기 일별 종가 데이터를 조회한다.
2. Twelve Data를 우선 사용하고, 필요하면 Alpha Vantage를 백업으로 사용해 8개 종목의 OHLC 데이터를 수집한다.
3. Google News RSS에서 기사를 수집하고 Groq AI가 호재, 악재, 중립으로 분류한다.
4. 주가 지표와 뉴스를 종합해 Groq AI가 종목별 판단과 이유를 생성한다.
5. 브라우저는 API를 주기적으로 호출해 대시보드 화면을 갱신한다.

이 흐름은 프론트엔드 화면만 만든 프로젝트가 아니라, 여러 외부 데이터 소스와 AI 분석 단계를 연결하는 통합형 프로젝트라는 점을 보여준다. 특히 Twelve Data와 Alpha Vantage를 함께 쓰는 방식은 데이터 제공자의 호출 제한에도 조회 경로를 유지하는 해결책이며, provider 상태와 데이터 신선도 표시를 더해 다중 데이터 운영 구조로 확장할 수 있다.

## 7. 기술 스택

| 영역 | 기술 | 역할 |
|---|---|---|
| Frontend | Next.js 16.2 App Router | 대시보드 화면과 라우팅 구성 |
| Language | TypeScript | 정적 타입 기반 구현 안정성 확보 |
| AI | Groq AI, `llama-3.1-8b-instant` | 뉴스 분류와 종목별 위험 분석 |
| Market Data | FRED API | S&P 500 지수 데이터 조회 |
| Stock Data | Twelve Data, Alpha Vantage | 종목별 OHLC 데이터 조회 |
| News | Google News RSS | 시장 및 종목 관련 뉴스 수집 |
| Chart | SVG Charts | 커스텀 차트 시각화 |
| Deploy | Vercel | 웹 서비스 배포 |

이 구성은 Boot Camp의 AI workflow 성격과 잘 맞는다. 단순 정적 페이지가 아니라, API 연동, AI 분석, 시각화, 배포까지 하나의 결과물로 연결되어 있다.

## 8. UI와 사용성

원본 HTML은 어두운 배경의 대시보드 스타일을 사용한다. 상단 고정 navigation, hero section, ticker strip, feature grid, risk grid, AI analysis card, 기술 스택 배지가 순서대로 배치되어 있다. 사용자는 첫 화면에서 프로젝트의 목적을 바로 이해하고, 대시보드와 GitHub 저장소로 이동할 수 있다.

또한 QR 코드 영역을 제공해 모바일 접속도 고려했다. 교육용 발표나 부트캠프 데모에서는 청중이 바로 서비스에 접근할 수 있어야 하므로, QR 연결은 실제 시연 환경에서 유용한 요소다.

## 9. 신뢰성과 확장 로드맵

| 현재 제공 기반 | 해결 방향 | 확장 가능성 |
|---|---|---|
| 뉴스와 지표를 결합한 AI 판단 | 사용 뉴스, 지표, 점수 요인을 판단 카드에 함께 표시 | 종목별 근거 리포트와 공유 가능한 분석 기록 |
| 교육용 위험 분석 경험 | 화면과 분석 카드에 교육 목적, 데이터 출처, 기준 시각을 명확히 표시 | 초보자용 금융 리터러시 모드와 설명 패널 |
| 데이터 제공자 fallback과 캐시 | provider 상태, 데이터 신선도, 빈 응답 안내를 UI에 노출 | 다중 provider 모니터링과 장애 알림 |
| AI 실패 시 규칙 기반 분석 | 분류 기준과 사용 지표를 사용자에게 설명 | 섹터·위험 성향별 분석 기준과 비교 리포트 |

AWS Charting은 이미 provider fallback, 캐시와 로컬 규칙 분석을 갖추고 있어, 근거와 데이터 상태를 더 투명하게 보여주는 방향으로 운영 신뢰성과 교육 가치를 함께 확장할 수 있다.

## 10. 5일차 핵심 정리

`AWS Charting`은 5일차 작업물로서 AI workflow 수업의 결과를 프로젝트 형태로 정리한 사례다. 데이터 수집, AI 분류, 위험 분석, 시각화, 배포가 하나의 흐름으로 연결되어 있으며, 주식 시장이라는 익숙한 도메인을 통해 AI 기반 의사결정 보조 시스템의 구조를 보여준다.

핵심은 다음과 같다.

- 주식 위험을 체계적 위험과 비체계적 위험으로 나누어 설명한다.
- 뉴스, 지표, AI 분석을 결합해 종목별 판단을 제공한다.
- FRED, Twelve Data, Alpha Vantage, Google News RSS, Groq AI를 연결한다.
- Next.js와 TypeScript 기반으로 대시보드 UI를 구성한다.
- 교육용 데모이므로 실제 투자 조언이 아니라 AI workflow 학습 결과물로 해석해야 한다.

## 11. 참고자료

<ul>
  <li><a href="https://sigebert111-boot-charting.vercel.app/" target="_blank" rel="noopener">AWS Charting 배포 페이지</a></li>
  <li><a href="https://github.com/nxtcloud-edu/2026-kookmin-ai-workflow-team5" target="_blank" rel="noopener">AWS Charting GitHub 저장소</a></li>
  <li><a href="https://github.com/nxtcloud-edu/2026-kookmin-ai-workflow-team5/blob/main/team5.html" target="_blank" rel="noopener">GitHub Source: team5.html</a></li>
  <li><a href="https://htmlpreview.github.io/?https://github.com/nxtcloud-edu/2026-kookmin-ai-workflow-team5/blob/main/team5.html" target="_blank" rel="noopener">HTMLPreview: team5.html</a></li>
  <li><a href="{{ "/assets/pdfs/post/nxtcloud-boot-camp/nxtcloud-certificate.pdf" | relative_url }}" target="_blank" rel="noopener">nxtcloud Boot Camp 수료증</a></li>
</ul>
