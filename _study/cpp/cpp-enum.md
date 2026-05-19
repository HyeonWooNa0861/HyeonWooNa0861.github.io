---
layout: default
title: "C++ Enumerations"
course: "C++"
topic: "enum과 enum class"
order: 6
---

# C++ Enumerations

Source PDF: `열거형 (Enum).pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 열거형의 의미 | 숫자 대신 이름 있는 값 집합을 만들 수 있는가? |
| 2 | C 스타일 enum | 전통적인 enum은 어떻게 동작하는가? |
| 3 | enum class | C++에서는 왜 scoped enum을 권장하는가? |
| 4 | 활용 예 | 상태 머신과 비트 플래그에 어떻게 쓰는가? |

## 1. 열거형이란?

열거형은 서로 관련된 상수 값에 의미 있는 이름을 붙이는 문법이다.

매직 넘버를 쓰면 의미가 불분명하다.

```cpp
int direction = 0;

if (direction == 0) {
    // 0이 북쪽인지 동쪽인지 코드만 보고 알기 어렵다.
}
```

열거형을 쓰면 의도가 명확해진다.

```cpp
enum Direction {
    NORTH,
    EAST,
    SOUTH,
    WEST
};

Direction dir = NORTH;
```

## 2. C 스타일 enum

C 스타일 enum은 첫 번째 값을 0으로 두고, 이후 값을 1씩 증가시킨다.

```cpp
enum Color {
    RED,
    GREEN,
    BLUE
};
```

값:

```text
RED = 0
GREEN = 1
BLUE = 2
```

직접 값을 지정할 수도 있다.

```cpp
enum HttpStatus {
    OK = 200,
    NOT_FOUND = 404
};
```

## 3. C 스타일 enum의 문제점

C 스타일 enum은 이름이 enum 바깥 전역 스코프에 노출된다.

```cpp
enum Color { RED, GREEN, BLUE };
enum Fruit { APPLE, GREEN, MANGO }; // 오류: GREEN 중복
```

또한 정수로 암묵 변환될 수 있어 타입 안전성이 약하다.

```cpp
Color c = GREEN;
int n = c; // 허용
```

## 4. `enum class`

C++에서는 `enum class`를 권장한다.

```cpp
enum class Color {
    RED,
    GREEN,
    BLUE
};

Color c = Color::GREEN;
```

`enum class`의 장점:

| 장점 | 설명 |
|---|---|
| 이름 충돌 방지 | 값 이름이 enum 내부에 한정된다. |
| 타입 안전성 | 정수로 암묵 변환되지 않는다. |
| 가독성 | `Color::GREEN`처럼 소속이 명확하다. |

## 5. 기반 타입 지정

기본 기반 타입은 보통 `int`지만, 필요하면 직접 지정할 수 있다.

```cpp
enum class Permission : unsigned int {
    NONE = 0,
    READ = 1 << 0,
    WRITE = 1 << 1,
    EXECUTE = 1 << 2
};
```

메모리 크기나 비트 플래그 용도를 명확히 하고 싶을 때 기반 타입을 지정한다.

## 6. 상태 머신 예

신호등 상태처럼 정해진 상태 집합을 표현할 때 enum class가 적합하다.

```cpp
enum class TrafficLight {
    RED,
    YELLOW,
    GREEN
};

TrafficLight next(TrafficLight current) {
    switch (current) {
    case TrafficLight::RED:
        return TrafficLight::GREEN;
    case TrafficLight::GREEN:
        return TrafficLight::YELLOW;
    case TrafficLight::YELLOW:
        return TrafficLight::RED;
    }
}
```

상태를 숫자로 표현하는 것보다 훨씬 명확하다.

## 7. 비트 플래그 예

권한처럼 여러 값을 조합해야 할 때는 비트 플래그를 사용할 수 있다.

```cpp
enum class Permission : unsigned int {
    NONE = 0,
    READ = 1 << 0,
    WRITE = 1 << 1,
    EXECUTE = 1 << 2
};
```

각 값은 서로 다른 비트를 사용한다.

```text
READ    = 001
WRITE   = 010
EXECUTE = 100
```

단, `enum class`는 타입 안전성을 위해 비트 연산자가 자동으로 제공되지 않으므로, 필요하면 `operator|`, `operator&` 등을 직접 정의한다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| enum | 관련 상수에 이름을 붙인다. |
| 매직 넘버 | 의미 없는 숫자 사용은 가독성을 떨어뜨린다. |
| C 스타일 enum | 이름이 외부 스코프에 노출되고 정수 변환이 쉽다. |
| enum class | 이름 충돌을 막고 타입 안전성을 높인다. |
| 기반 타입 | 저장 크기나 비트 플래그 목적에 맞게 지정할 수 있다. |
| 상태 머신 | 제한된 상태 집합을 표현하기 좋다. |
| 비트 플래그 | 여러 옵션 조합에 사용할 수 있다. |

현대 C++에서는 특별한 이유가 없다면 C 스타일 enum보다 `enum class`를 사용하는 것이 더 안전하고 명확하다.

## Study Guide

이 문서는 "숫자에 의미를 부여하는 방법"에서 출발해 `enum class`의 타입 안전성으로 이어지는 흐름으로 읽으면 좋다. 먼저 매직 넘버가 왜 위험한지 이해하고, 그다음 C 스타일 `enum`이 어떤 편리함과 한계를 동시에 갖는지 확인한다.

시험이나 코드 작성에서는 `enum`과 `enum class`의 차이를 정확히 말할 수 있어야 한다. 핵심은 스코프와 암묵 변환이다. C 스타일 `enum`은 열거자 이름이 바깥 스코프에 노출되고 정수처럼 쓰이기 쉽지만, `enum class`는 `Color::Red`처럼 소속을 명시하고 정수 변환도 제한한다.

비트 플래그는 단순 상태 표현과 다르다. 상태 머신은 여러 값 중 하나만 가지는 경우에 적합하고, 권한 플래그는 여러 값을 조합해야 하므로 각 값을 서로 다른 비트에 배치한다. 이 차이를 구분하면 `enum class`를 언제 단순 상태로 쓰고 언제 연산자 오버로딩과 함께 써야 하는지 판단할 수 있다.

## 복습 질문

<details>
<summary>1. C 스타일 `enum`보다 `enum class`가 더 안전한 이유는 무엇인가?</summary>

답변: `enum class`는 열거자 이름이 enum 내부 스코프에 묶이고, 정수로 암묵 변환되지 않는다. 그래서 이름 충돌과 실수로 정수처럼 사용하는 문제를 줄일 수 있다.

</details>

<details>
<summary>2. 열거형의 기반 타입을 직접 지정하는 이유는 무엇인가?</summary>

답변: 저장 크기나 비트 표현을 명확히 하기 위해서다. 예를 들어 권한 플래그처럼 비트 단위 조합이 필요한 경우 `enum class Permission : unsigned int`처럼 기반 타입을 지정하면 의도가 더 분명해진다.

</details>

<details>
<summary>3. `enum class`로 비트 플래그를 만들 때 `operator|` 같은 연산자를 직접 정의해야 하는 이유는 무엇인가?</summary>

답변: `enum class`는 타입 안전성을 위해 정수로 자동 변환되지 않기 때문이다. 따라서 `READ | WRITE` 같은 비트 조합을 자연스럽게 쓰려면 해당 enum 타입에 맞는 비트 연산자 오버로딩을 직접 제공해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/열거형 (Enum).pdf" | relative_url }}" target="_blank" rel="noopener">열거형 (Enum).pdf</a></li>
</ul>
