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

C++은 메모리를 직접 제어할 수 있지만 누수, dangling pointer, double deletion 같은 위험도 함께 가진다. 스마트 포인터는 소유권을 명시해 이 위험을 줄인다. 특히 `std::shared_ptr`의 reference counting은 JVM의 Garbage Collection과 해제 시점 및 순환 참조 처리 방식이 다르다.

**핵심 메시지:** 스마트 포인터 선택의 기준은 편의성이 아니라 소유권이다. 단독 소유는 `unique_ptr`, 실제 공유 소유는 `shared_ptr`, 공유 객체에 대한 비소유 관찰과 순환 참조 차단은 `weak_ptr`로 표현해야 한다.

## 1. 일반 포인터의 문제점

C++에서 `new`로 할당한 메모리는 `delete`로 직접 해제해야 한다. 이 과정을 놓치면 할당된 메모리가 계속 남아 메모리 누수가 발생한다. 이미 해제된 메모리를 다시 참조하면 dangling pointer 문제가 생기고, 같은 메모리를 두 번 해제하면 double deletion으로 프로그램이 불안정해질 수 있다.

이러한 문제는 코드가 복잡해질수록 더 자주 발생한다. 특히 예외가 발생하거나 함수가 중간에 반환되는 경우에는 해제 코드를 놓치기 쉽다. 따라서 C++에서는 객체의 생명주기에 자원 관리를 묶는 RAII 방식이 중요하다.

## 2. 스마트 포인터와 RAII

RAII(Resource Acquisition Is Initialization)는 자원의 획득과 해제를 객체 수명에 묶는 방식이다. C++ 표준 라이브러리의 `std::unique_ptr`와 `std::shared_ptr`는 소유권에 따라 대상 객체를 정리한다. `std::weak_ptr`는 대상을 소유하지 않으므로, 자신이 소멸해도 대상 객체를 파괴하지 않는다.

`std::unique_ptr`는 한 자원에 소유자를 하나만 둔다. 복사는 불가능하고 `std::move`로 소유권을 넘기면 원래 포인터는 비게 된다. 단독 소유가 명확한 자원에 적합하다.

`std::shared_ptr`는 여러 포인터가 하나의 객체를 공유할 때 사용한다. 내부적으로 참조 횟수를 관리하며, 마지막 소유자가 사라질 때 객체를 해제한다. 여러 모듈이 같은 자원을 함께 사용해야 할 때 유용하다.

`std::weak_ptr`는 `shared_ptr`가 관리하는 객체를 비소유 방식으로 관찰한다. 객체에 접근할 때는 `lock()`으로 유효한 소유권을 얻고, 반환된 `shared_ptr`가 비어 있지 않은지 확인한다.

## 3. Reference Counting 동작 원리

`std::shared_ptr`의 reference counting은 객체를 가리키는 모든 포인터가 아니라 **소유권을 공유하는 `shared_ptr`의 수**를 센다. 같은 객체의 소유자들은 control block을 공유하며, 이 블록이 소유자 수(use count)와 `weak_ptr`의 존재를 관리한다. 소유자 수가 0이 되면 대상 객체가 파괴된다.

```cpp
#include <memory>

int main() {
    auto first = std::make_shared<int>(10); // 소유자 1명
    std::weak_ptr<int> view = first;        // 여전히 1명
    {
        auto second = first;                // 소유자 2명
    }                                       // 다시 1명
    first.reset();                          // 0명: int 객체 파괴
    auto alive = view.lock();               // 빈 shared_ptr 반환
    return alive ? 1 : 0;                   // 0: 객체에 접근할 수 없음
}
```

`view`가 남아 있어도 마지막 소유자인 `first`가 `reset()`되면 객체는 파괴된다. 다만 `weak_ptr`가 남아 있는 동안 control block은 유지될 수 있으므로, 객체 파괴와 메모리 할당 전체의 반환은 구분해야 한다. 파일 핸들처럼 소멸자에서 정리하는 자원은 이 소유권 종료 시점에 정리할 수 있다.

## 4. Reference Counting의 한계

Reference counting에는 비용과 구조적 한계가 있다. `shared_ptr`를 복사하거나 해제할 때마다 카운트를 증가·감소해야 하며, 멀티스레드 환경에서는 원자적 연산이 필요해 성능 오버헤드가 발생한다.

순환 참조에서는 소유자가 남아 있어 객체가 파괴되지 않는다. `A→B`와 `B→A`가 모두 `shared_ptr`이고 외부 변수 `a`, `b`도 각각 `A`, `B`를 소유하면, 연결 직후 소유자 수는 `A=2(a, B→A)`, `B=2(b, A→B)`이다. 외부의 `a`, `b`가 사라진 뒤에도 내부 소유권이 남아 `A=1`, `B=1`이다. 반대로 `B→A`를 `weak_ptr<A>`로 바꾸면 `A=1`, `B=2`에서 시작해 `b` 해제 후 `B=1`, `a` 해제 후 `A=0`이 된다. 이때 `A`의 소멸자가 `A→B`를 해제하므로 `B=0`이 된다. 이는 두 외부 변수 이외에 다른 소유자가 없을 때의 흐름이다.

원문 PDF 3쪽의 "control block이 별도 메모리 공간에 존재한다"는 설명은 모든 생성 방식에 적용되지 않는다. `std::make_shared`는 객체와 control block을 한 번에 할당할 수 있다(<a href="https://learn.microsoft.com/en-us/cpp/standard-library/memory-functions?view=msvc-170#make_shared" target="_blank" rel="noopener">Microsoft Learn: make_shared</a>). 따라서 모든 포인터를 무조건 `shared_ptr`로 바꾸기보다, 소유권 구조와 카운트 관리 비용에 맞게 `unique_ptr`, `shared_ptr`, `weak_ptr`를 구분해야 한다.

## 5. JVM Garbage Collection과 비교

JVM은 Garbage Collection을 통해 더 이상 도달할 수 없는 객체를 자동으로 회수한다. 대표적인 방식은 mark-and-sweep으로, 실행 중인 객체 그래프를 탐색해 reachable 객체를 표시하고, 표시되지 않은 객체를 수거한다.

C++ 스마트 포인터와 JVM GC는 모두 개발자가 직접 `delete`를 호출하지 않아도 된다는 공통점이 있다. 하지만 철학은 다르다. C++의 RAII와 reference counting은 객체가 스코프를 벗어나거나 참조 카운트가 0이 되는 시점에 비교적 예측 가능하게 자원을 해제한다.

반면 JVM GC는 메모리 관리 부담을 크게 줄이고 순환 참조도 자동으로 처리할 수 있지만, 언제 GC가 실행될지 정확히 예측하기 어렵다. 경우에 따라 stop-the-world pause가 발생할 수 있어 실시간성이 중요한 시스템에서는 부담이 될 수 있다.

## 핵심 정리

| 주제 | 꼭 기억할 기준 |
|---|---|
| RAII | 자원 수명을 객체 수명에 묶어 정상 반환과 예외 상황 모두에서 정리를 보장한다. |
| `unique_ptr` | 복사할 수 없는 단독 소유권이며, 소유권 이전에는 `std::move`를 사용한다. |
| `shared_ptr` | control block의 use count로 공유 소유권을 관리하며 마지막 소유자가 사라질 때 객체를 파괴한다. |
| `weak_ptr` | use count를 늘리지 않는 비소유 참조로 `shared_ptr` 순환을 끊는다. |
| 비용 | 참조 카운트 갱신, 멀티스레드 원자적 연산, control block 관리에 따른 오버헤드가 있다. |
| JVM GC와 차이 | C++ RAII는 해제 시점을 비교적 예측할 수 있고, tracing GC는 순환 참조를 회수하지만 실행 시점이 비결정적일 수 있다. |

## 결론 및 학습 성과

스마트 포인터는 수동 `delete`에서 생기는 오류를 줄이지만, 순환 소유권이나 공유 비용까지 자동으로 해결하지는 않는다. 이 과제에서 확인할 판단 기준은 실제 소유 관계를 따라가며 마지막 소유자가 사라지는 경로가 있는지 점검하는 것이다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Smart Pointer, RAII, Reference Counting.pdf" | relative_url }}" target="_blank" rel="noopener">Smart Pointer, RAII, Reference Counting.pdf</a></li>
</ul>
