---
layout: default
date: 2026-09-12 18:42:46 +0900
title: "Calibration Data Impact"
topic: "Calibration data effects in post-training quantization and pruning"
order: 81
major_topic: "LLM Quantization & Compression"
keywords:
  - "Calibration Data Impact"
  - "Research seminar"
---

# On the Impact of Calibration Data in Post-training Quantization and Pruning

## 자료 정보

| 항목 | 내용 |
| --- | --- |
| 제목 | On the Impact of Calibration Data in Post-training Quantization and Pruning |
| 저자 | Miles Williams, Nikolaos Aletras |
| 연도 | 2024 |

## 핵심 질문

같은 모델과 압축 방법에서도 calibration text가 달라지면 결과가 달라질 수 있는지를 살핀다. Calibration data는 activation을 통해 압축 weight 선택에 관여하는 입력이며, 압축 후 성능을 재는 evaluation data와 구분해야 한다.

## 강의 구성

- Calibration과 training·evaluation의 구분
- Activation에 의존하는 PTQ·pruning의 흐름
- 실험 조건과 결과를 비교하는 방법
- Calibration 선택에 관한 교훈과 일반화의 한계

## 읽을 때 구분할 점

Calibration을 정답 label에 따른 재학습과 혼동하지 않는다. 실험에 사용한 압축 방법·모델·데이터 조건을 함께 읽고, 관찰된 차이를 모든 모델에 적용되는 보편적 규칙으로 확대하지 않는다.

## 세미나 강의자료

슬라이드와 함께 학습 원고·발표자 노트를 볼 수 있습니다.

| 자료 | 분량 | PDF | PowerPoint | 학습 원고 | 발표자 노트 |
| --- | ---: | --- | --- | --- | --- |
| 한국어 강의 | 20장 | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/calibration-impact-seminar-ko-v1.pdf" target="_blank" rel="noopener">보기</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/calibration-impact-seminar-ko-v1.pptx" download>다운로드</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/slides-v1.md.txt" download="slides-v1.md">Markdown</a> | <a href="/assets/seminars/on-the-impact-of-calibration-data-in-post-training-quantization-and-pruning/presenter-notes-v1.md.txt" download="presenter-notes-v1.md">Markdown</a> |

## 공개 출처

- [ACL Anthology](https://aclanthology.org/2024.acl-long.544/){:target="_blank" rel="noopener"}
- [arXiv v2](https://arxiv.org/abs/2311.09755v2){:target="_blank" rel="noopener"}
