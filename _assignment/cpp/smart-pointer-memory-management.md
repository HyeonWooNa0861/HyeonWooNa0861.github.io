---
layout: default
date: 2026-05-17 01:14:20 +0900
title: "Smart Pointers and Memory Management"
course: "C++"
topic: "Smart Pointer, RAII, Reference Counting"
---

# 스마트 포인터와 메모리 관리

Source PDF: `Smart Pointer, RAII, Reference Counting.pdf`

## 과제 개요

이 과제는 C++의 스마트 포인터가 왜 필요한지, `std::shared_ptr`의 reference counting이 어떻게 동작하는지, 그리고 JVM의 Garbage Collection과 어떤 차이가 있는지 정리한 내용이다. C++은 직접 메모리를 제어할 수 있다는 장점이 있지만, 그만큼 메모리 누수, dangling pointer, double deletion 같은 위험도 함께 가진다.

## 1. 일반 포인터의 문제점

C++에서 `new`로 할당한 메모리는 `delete`로 직접 해제해야 한다. 이 과정을 놓치면 할당된 메모리가 계속 남아 메모리 누수가 발생한다. 이미 해제된 메모리를 다시 참조하면 dangling pointer 문제가 생기고, 같은 메모리를 두 번 해제하면 double deletion으로 프로그램이 불안정해질 수 있다.

이러한 문제는 코드가 복잡해질수록 더 자주 발생한다. 특히 예외가 발생하거나 함수가 중간에 반환되는 경우에는 해제 코드를 놓치기 쉽다. 따라서 C++에서는 객체의 생명주기에 자원 관리를 묶는 RAII 방식이 중요하다.

## 2. 스마트 포인터와 RAII

스마트 포인터는 원시 포인터를 객체로 감싸서, 스코프를 벗어날 때 소멸자를 통해 자동으로 메모리를 해제하는 도구이다. C++ 표준 라이브러리는 대표적으로 `std::unique_ptr`, `std::shared_ptr`, `std::weak_ptr`를 제공한다.

`std::unique_ptr`는 하나의 객체가 하나의 자원만 소유하도록 만든다. 복사는 불가능하고 `std::move`를 통해 소유권을 이동할 수 있다. 단독 소유가 명확한 자원에 적합하다.

`std::shared_ptr`는 여러 포인터가 하나의 객체를 공유할 때 사용한다. 내부적으로 참조 횟수를 관리하며, 마지막 소유자가 사라질 때 객체를 해제한다. 여러 모듈이 같은 자원을 함께 사용해야 할 때 유용하다.

`std::weak_ptr`는 `shared_ptr`가 관리하는 객체를 비소유 방식으로 참조한다. 참조 카운트를 증가시키지 않기 때문에 순환 참조를 끊는 데 사용된다.

## 3. Reference Counting 동작 원리

Reference counting은 객체를 참조하는 소유자의 수를 기록하고, 그 수가 0이 되는 순간 객체를 해제하는 방식이다. `std::shared_ptr`는 이 방식을 사용하며, 실제 객체와 별도로 control block을 두어 use count와 weak count를 관리한다.

예를 들어 하나의 `shared_ptr`를 다른 변수에 복사하면 use count가 증가한다. 복사본이 스코프를 벗어나거나 `reset()`을 호출하면 use count가 감소한다. 마지막 `shared_ptr`가 사라져 use count가 0이 되면 실제 객체가 파괴된다.

이 방식의 장점은 객체가 더 이상 사용되지 않는 시점에 즉시 해제된다는 것이다. 파일 핸들, 네트워크 소켓처럼 메모리 외 자원을 스코프 기반으로 관리할 때도 예측 가능한 수명 관리가 가능하다.

## 4. Reference Counting의 한계

Reference counting에는 비용과 구조적 한계가 있다. `shared_ptr`를 복사하거나 해제할 때마다 카운트를 증가·감소해야 하며, 멀티스레드 환경에서는 원자적 연산이 필요해 성능 오버헤드가 발생한다.

가장 대표적인 문제는 순환 참조이다. 두 객체가 서로를 `shared_ptr`로 참조하면 두 객체 모두 use count가 0이 되지 않아 메모리가 해제되지 않는다. 이런 경우 한쪽 참조를 `weak_ptr`로 바꾸어 소유 관계를 끊어야 한다.

또한 control block이 별도 메모리 공간에 존재하기 때문에 캐시 지역성이 떨어질 수 있다. 따라서 모든 포인터를 무조건 `shared_ptr`로 바꾸는 것은 좋은 설계가 아니며, 소유권 구조에 맞게 `unique_ptr`, `shared_ptr`, `weak_ptr`를 구분해야 한다.

## 5. JVM Garbage Collection과 비교

JVM은 Garbage Collection을 통해 더 이상 도달할 수 없는 객체를 자동으로 회수한다. 대표적인 방식은 mark-and-sweep으로, 실행 중인 객체 그래프를 탐색해 reachable 객체를 표시하고, 표시되지 않은 객체를 수거한다.

C++ 스마트 포인터와 JVM GC는 모두 개발자가 직접 `delete`를 호출하지 않아도 된다는 공통점이 있다. 하지만 철학은 다르다. C++의 RAII와 reference counting은 객체가 스코프를 벗어나거나 참조 카운트가 0이 되는 시점에 비교적 예측 가능하게 자원을 해제한다.

반면 JVM GC는 메모리 관리 부담을 크게 줄이고 순환 참조도 자동으로 처리할 수 있지만, 언제 GC가 실행될지 정확히 예측하기 어렵다. 경우에 따라 stop-the-world pause가 발생할 수 있어 실시간성이 중요한 시스템에서는 부담이 될 수 있다.

## 6. 장단점 정리

- 스마트 포인터는 메모리 누수와 dangling pointer를 줄인다.
- RAII는 예외가 발생해도 자원을 안전하게 정리할 수 있게 한다.
- `shared_ptr`는 다중 소유권을 표현할 수 있지만 reference counting 오버헤드가 있다.
- 순환 참조는 `shared_ptr`만으로 해결되지 않으며 `weak_ptr`가 필요하다.
- JVM GC는 개발 편의성이 높지만 회수 시점이 비결정적이고 정지 시간이 생길 수 있다.

## 결론 및 학습 성과

스마트 포인터는 C++에서 안전한 메모리 관리를 위해 매우 중요한 도구이지만, 모든 문제를 자동으로 해결해 주지는 않는다. 핵심은 소유권 구조를 명확히 설계하는 것이다. 단독 소유에는 `unique_ptr`, 공유 소유에는 `shared_ptr`, 순환 참조 방지에는 `weak_ptr`를 사용해야 한다. 결국 C++의 자동 메모리 관리는 언어가 제공하는 도구와 개발자의 설계 판단이 함께 작동할 때 효과가 크다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Smart Pointer, RAII, Reference Counting.pdf" | relative_url }}" target="_blank" rel="noopener">Smart Pointer, RAII, Reference Counting.pdf</a></li>
</ul>
