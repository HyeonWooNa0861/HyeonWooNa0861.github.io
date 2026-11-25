---
layout: default
date: 2026-05-17 01:14:20 +0900
last_modified_at: 2026-11-25 16:46:01 +0900
title: "Program Memory Areas"
course: "C++"
topic: "Code/Data/Stack/Heap"
---

# 프로그램 메모리 영역

Source PDF: `Code Data Stack Heap.pdf`

## 과제 개요

C++ 프로그램의 메모리는 Code, Data, Stack, Heap 영역으로 나뉩니다. 각 영역의 역할과 객체 수명은 서로 다르며, Stack·Heap의 확장 방향, 단편화와 누수 문제도 이 구조를 이해해야 설명할 수 있습니다.

**핵심 메시지:** 메모리 영역의 차이는 저장 위치만의 문제가 아니라 객체의 수명, 할당·해제 책임, 성능과 오류 가능성을 결정합니다. 특히 Heap 자원은 RAII와 Smart Pointer로 소유권을 명확히 해야 합니다.

## 1. 프로그램 메모리 영역

C++ 프로그램의 메모리는 일반적으로 Code, Data, Stack, Heap 영역으로 구분됩니다. Code 영역은 컴파일된 기계어 명령을 저장하는 공간이며, 프로그램 실행 중 내용이 바뀌지 않는 읽기 전용 영역으로 취급됩니다.

Data 영역은 전역 변수와 `static` 변수를 저장합니다. 초기값이 있는 데이터는 Initialized Data 영역에 저장되고, 초기값이 없는 데이터는 BSS 영역에 저장되며 보통 0으로 초기화됩니다.

Stack 영역은 함수 호출과 함께 생성되는 지역 변수, 매개변수, 반환 주소 등을 저장합니다. LIFO 구조로 동작하며, 함수가 종료되면 해당 함수의 스택 프레임이 자동으로 제거됩니다. 관리가 빠르고 단순하지만 크기에 제한이 있습니다.

Heap 영역은 `new`나 `malloc`처럼 실행 중 동적으로 할당되는 메모리를 저장합니다. 필요한 만큼 유동적으로 사용할 수 있지만, 프로그래머가 직접 해제해야 하므로 메모리 누수나 잘못된 해제 문제가 발생할 수 있습니다.

## 2. Stack과 Heap의 확장 방향

<a href="{{ "/assets/images/assignment/cpp/source-captures/program-memory-areas-page-04.png" | relative_url }}" target="_blank" rel="noopener"><img src="{{ "/assets/images/assignment/cpp/source-captures/program-memory-areas-page-04.png" | relative_url }}" alt="원본 과제의 process memory 영역과 stack heap 참조 구조" loading="lazy"></a>

*원본 `Code Data Stack Heap.pdf` p. 4. 위 왼쪽은 낮은 주소의 text·data·BSS, 그 위의 heap, 높은 주소의 stack 배치를 보여줍니다. 위 오른쪽은 heap이 아래쪽, stack이 위쪽으로 free memory를 향해 자라는 전형적 그림입니다. 아래 예시는 stack 변수들이 heap 객체를 reference하는 관계를 나타냅니다. <a href="{{ "/assets/pdfs/assignment/cpp/Code Data Stack Heap.pdf#page=4" | relative_url }}" target="_blank" rel="noopener">원문 PDF p. 4</a>*

화살표 방향은 특정 process layout을 설명하는 관례이며 C++ 표준이 모든 OS에서 같은 주소 배치를 보장하는 것은 아닙니다. 핵심은 stack frame의 자동 수명과 heap 객체의 별도 수명, 그리고 stack의 pointer/reference가 heap 객체를 가리킬 수 있다는 구분입니다.

강의 그림처럼 Stack과 Heap을 서로 반대 방향으로 그리는 전형적인 process layout이 있습니다. 이 그림에서는 Stack이 높은 주소에서 낮은 주소로, Heap이 낮은 주소에서 높은 주소로 커집니다. 가운데의 비어 있는 주소 범위를 두 영역이 필요에 따라 사용할 수 있다는 생각을 보여 주는 도식입니다.

다만 현대 운영체제는 virtual memory, address-space randomization, 별도 memory mapping을 사용하므로 두 영역이 실제로 한 공간에서 계속 자라다가 직접 부딪힌다고 일반화하면 안 됩니다. Stack overflow는 보통 제한된 stack 범위나 guard page를 넘을 때 발생하고, Heap 할당 실패는 allocator와 사용 가능한 virtual memory 조건에 따라 결정됩니다. 기억할 핵심은 화살표 방향보다 **Stack은 호출 수명에 맞춰 자동 관리되고, Heap 객체는 별도 소유권과 수명을 가진다**는 차이입니다.

## 3. 메모리 단편화

메모리 단편화는 할당과 해제가 반복되면서 메모리 공간이 비효율적으로 사용되는 현상입니다. 내부 단편화는 필요한 크기보다 큰 블록이 할당되어 블록 내부에 남는 공간이 생기는 경우입니다. 예를 들어 10바이트만 필요하지만 16바이트 블록이 할당되면 6바이트가 낭비됩니다.

외부 단편화는 전체 여유 공간은 충분하지만 연속된 공간이 부족해서 큰 메모리 블록을 할당할 수 없는 경우입니다. Heap에서 다양한 크기의 메모리를 반복적으로 할당하고 해제할 때 주로 발생합니다.

Paging은 메모리를 고정 크기 페이지와 프레임으로 나누어 외부 단편화를 줄입니다. 다만 프로세스 크기가 페이지 크기의 배수가 아니면 마지막 페이지 내부에 남는 공간이 생겨 내부 단편화가 발생할 수 있습니다. Segmentation은 코드, 데이터, 스택처럼 논리적 단위로 메모리를 나누는 방식이며 구조를 이해하기 쉽지만 외부 단편화가 발생할 수 있습니다.

**Supplementary table — 내부·외부 단편화의 위치와 실패 형태**

| 구분 | 빈 공간이 생기는 위치 | 작은 상태 예시 | 문제가 되는 순간 | 대표 완화 방향 |
|---|---|---|---|---|
| 내부 단편화 | **할당된 블록 안쪽** | 10 B 요청에 16 B block을 주면 block 내부 6 B가 남습니다. | 할당은 성공하지만 실제 사용량보다 더 많은 공간을 점유합니다. | 더 세분화된 size class, 작은 allocation unit |
| 외부 단편화 | **할당된 블록 사이** | 4 B와 6 B hole이 떨어져 있으면 총 10 B가 비어도 연속 8 B 요청이 실패할 수 있습니다. | 전체 free 용량은 충분하지만 필요한 연속 block이 없습니다. | compaction이 가능한 관리 방식, paging, 적절한 allocator |

표의 수치는 단편화 위치를 설명하기 위한 예시이지 특정 allocator의 측정 결과가 아닙니다. 내부 단편화는 “받은 블록의 남는 부분”, 외부 단편화는 “블록 사이에 흩어진 hole”을 찾으면 구분할 수 있습니다. Paging은 물리 메모리의 연속 배치를 요구하지 않아 외부 단편화를 줄이지만, 마지막 page 안의 남는 공간까지 없애지는 않습니다.

## 4. 메모리 누수와 해결 방법

메모리 누수는 동적으로 할당한 메모리를 해제하지 않아 더 이상 사용할 수 없는 상태로 남는 현상입니다. C/C++에서는 `malloc`으로 할당한 메모리에 `free`를 호출하지 않거나, `new`로 만든 객체를 `delete`하지 않으면 누수가 발생할 수 있습니다.

메모리 누수를 줄이는 대표적인 방법에는 Garbage Collection과 Smart Pointer가 있습니다. Garbage Collection은 사용되지 않는 객체를 자동으로 탐지해 제거하는 방식이며 Java, Python 같은 언어에서 주로 사용됩니다. 안전성이 높지만 런타임 오버헤드가 생길 수 있습니다.

C++에서는 `std::unique_ptr`, `std::shared_ptr` 같은 Smart Pointer를 사용해 RAII 방식으로 자원을 관리할 수 있습니다. 객체의 수명이 끝나면 소멸자가 자동으로 호출되어 메모리가 해제되므로, 수동 `delete`에 비해 안전하고 예외 상황에서도 자원 누수를 줄일 수 있습니다.

## 핵심 정리

- 프로그램 메모리는 Code, Data, Stack, Heap 영역으로 나뉩니다.
- Stack은 함수 호출과 지역 변수 관리를 담당하며 자동으로 관리됩니다.
- Heap은 동적 할당을 위한 공간이며 프로그래머의 관리 책임이 큽니다.
- Stack과 Heap은 메모리 효율성을 위해 서로 반대 방향으로 확장됩니다.
- 단편화는 내부 단편화와 외부 단편화로 나뉘며, Paging과 Segmentation으로 완화할 수 있습니다.
- C++에서는 Smart Pointer를 활용해 메모리 누수를 줄이고 자원 관리를 더 안전하게 만들 수 있습니다.

## 결론 및 학습 성과

C++의 메모리 구조는 성능, 안정성, 오류 가능성과 직접 연결됩니다. Stack과 Heap의 차이를 알면 지역 변수와 동적 할당 객체의 수명을 구분하고, 누수나 단편화 문제의 원인을 더 구체적으로 설명할 수 있습니다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Code Data Stack Heap.pdf" | relative_url }}" target="_blank" rel="noopener">Code Data Stack Heap.pdf</a></li>
</ul>
