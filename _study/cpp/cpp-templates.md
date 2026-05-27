---
layout: default
title: "C++ Templates"
course: "C++"
topic: "템플릿과 제네릭 프로그래밍"
order: 11
---

# C++ Templates

Source PDF: `C++ 템플릿.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 템플릿의 필요성 | 타입만 다른 코드를 계속 복사해야 하는가? |
| 2 | 함수 템플릿 | 함수의 매개변수 타입과 반환 타입을 일반화할 수 있는가? |
| 3 | 템플릿 인스턴스화 | 템플릿 코드는 언제 실제 함수나 클래스로 만들어지는가? |
| 4 | 여러 타입 매개변수 | 서로 다른 타입을 함께 받는 함수는 어떻게 작성하는가? |
| 5 | 클래스 템플릿 | 자료구조를 특정 타입에 묶지 않고 만들 수 있는가? |
| 6 | 비타입 템플릿 매개변수 | 타입뿐 아니라 정수 같은 값도 템플릿 인자로 쓸 수 있는가? |
| 7 | 템플릿 특수화 | 특정 타입만 별도로 다르게 처리할 수 있는가? |
| 8 | 템플릿과 헤더 파일 | 왜 템플릿 정의는 보통 헤더에 함께 작성하는가? |
| 9 | STL과 템플릿 | `vector<int>`와 `vector<double>`은 어떤 원리로 가능한가? |

## 1. 템플릿이 필요한 이유

템플릿은 **타입이 달라도 같은 구조로 동작하는 코드를 하나의 틀로 작성하는 기능**이다. 예를 들어 두 값 중 큰 값을 반환하는 함수는 `int`, `double`, `char`에 대해 거의 같은 구조를 가진다.

```cpp
int max_int(int a, int b) {
    return (a > b) ? a : b;
}

double max_double(double a, double b) {
    return (a > b) ? a : b;
}
```

두 함수는 타입만 다르고 로직은 같다. 이런 코드를 계속 복사하면 다음 문제가 생긴다.

| 문제 | 설명 |
|---|---|
| 중복 증가 | 타입이 늘어날 때마다 같은 함수를 반복해서 작성해야 한다. |
| 유지보수 어려움 | 로직을 수정할 때 모든 버전을 함께 고쳐야 한다. |
| 실수 가능성 증가 | 한 타입 버전만 수정하고 다른 타입 버전을 빠뜨릴 수 있다. |

템플릿을 사용하면 타입을 고정하지 않고, 나중에 사용하는 시점에 타입을 넣어 코드를 생성할 수 있다.

```cpp
template <typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}
```

이제 같은 함수 템플릿으로 여러 타입을 처리할 수 있다.

```cpp
int a = max_value(3, 5);          // T = int
double b = max_value(2.5, 1.2);   // T = double
char c = max_value('a', 'z');     // T = char
```

핵심은 템플릿이 “아무 타입이나 되는 함수”가 아니라, **타입을 매개변수처럼 받아서 컴파일 시점에 실제 코드를 만들어내는 문법**이라는 점이다.

## 2. 함수 템플릿의 기본 형태

함수 템플릿은 함수 앞에 `template <typename T>`를 붙여 작성한다.

```cpp
template <typename T>
T square(T x) {
    return x * x;
}
```

구성은 다음과 같다.

| 부분 | 의미 |
|---|---|
| `template` | 지금부터 템플릿을 정의한다는 표시 |
| `<typename T>` | `T`라는 타입 매개변수를 사용하겠다는 의미 |
| `T square(T x)` | 반환 타입과 매개변수 타입에 `T`를 사용 |

사용 예:

```cpp
int i = square(3);        // int square(int)
double d = square(2.5);   // double square(double)
```

컴파일러는 호출에 사용된 인자의 타입을 보고 `T`를 추론한다. 그래서 보통은 `square<int>(3)`처럼 타입을 직접 쓰지 않아도 된다.

```cpp
int a = square<int>(3);   // 명시적 지정
int b = square(3);        // 타입 추론
```

두 코드는 결과적으로 같은 의미다.

## 3. `typename`과 `class`

템플릿 타입 매개변수를 선언할 때 `typename` 대신 `class`를 사용할 수도 있다.

```cpp
template <typename T>
T add(T a, T b) {
    return a + b;
}

template <class T>
T sub(T a, T b) {
    return a - b;
}
```

위 두 방식은 타입 매개변수를 선언하는 문맥에서는 사실상 같은 의미다.

| 문법 | 의미 |
|---|---|
| `template <typename T>` | `T`는 어떤 타입이라는 뜻 |
| `template <class T>` | `T`는 어떤 타입이라는 뜻 |

현대 C++에서는 타입 매개변수임을 더 직접적으로 드러내기 위해 `typename`을 선호하는 경우가 많다. 하지만 강의나 예제, 오래된 코드에서는 `class`도 자주 등장한다.

## 4. 템플릿 인스턴스화

템플릿 자체는 아직 완성된 함수가 아니다. 템플릿은 함수나 클래스를 만들어내는 **설계도**에 가깝다.

```cpp
template <typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}
```

이 템플릿을 다음처럼 호출하면:

```cpp
int x = max_value(10, 20);
double y = max_value(1.5, 3.2);
```

컴파일러는 내부적으로 다음과 같은 함수가 필요하다고 판단한다.

```cpp
int max_value(int a, int b) {
    return (a > b) ? a : b;
}

double max_value(double a, double b) {
    return (a > b) ? a : b;
}
```

이처럼 템플릿에 실제 타입을 넣어 구체적인 함수나 클래스를 만들어내는 과정을 **인스턴스화(instantiation)**라고 한다.

| 용어 | 의미 |
|---|---|
| 템플릿 | 타입이 비어 있는 코드의 틀 |
| 인스턴스화 | 실제 타입을 넣어 구체적인 코드를 생성하는 과정 |
| 템플릿 인자 | `int`, `double`, `std::string`처럼 템플릿에 들어가는 실제 타입 |

중요한 점은 템플릿 오류가 템플릿 정의 시점이 아니라, 실제 타입을 넣어 사용하는 시점에 드러나는 경우가 많다는 것이다.

```cpp
struct Point {
    int x;
    int y;
};

Point p1{1, 2};
Point p2{3, 4};

// max_value(p1, p2); // 오류: Point에는 operator>가 정의되어 있지 않음
```

`max_value` 안에서 `a > b`를 사용하므로, `T` 타입은 `>` 연산이 가능해야 한다. 템플릿은 모든 타입을 무조건 받아주는 기능이 아니라, **템플릿 본문에서 요구하는 연산을 만족하는 타입에 대해 동작하는 기능**이다.

## 5. 타입 추론과 주의할 점

함수 템플릿은 인자를 보고 타입을 추론한다.

```cpp
template <typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}

max_value(3, 5);       // T = int
max_value(1.2, 4.5);   // T = double
```

하지만 두 인자의 타입이 다르면 문제가 생길 수 있다.

```cpp
// max_value(3, 4.5); // T를 int로 볼지 double로 볼지 애매함
```

이럴 때는 방법이 몇 가지 있다.

```cpp
max_value<double>(3, 4.5);       // T를 double로 명시
max_value(3.0, 4.5);             // 두 인자를 모두 double로 맞춤
max_value(static_cast<double>(3), 4.5);
```

또는 서로 다른 두 타입을 받을 수 있도록 템플릿 매개변수를 두 개로 만들 수도 있다.

```cpp
template <typename T, typename U>
auto max_mixed(T a, U b) {
    return (a > b) ? a : b;
}
```

여기서 `auto`는 반환 타입을 컴파일러가 추론하게 한다. 다만 `a`와 `b`의 타입이 다르면 반환 타입과 형 변환 규칙을 더 신중히 생각해야 한다.

## 6. 여러 타입 매개변수

템플릿은 하나의 타입만 받을 필요가 없다. 여러 타입 매개변수를 선언할 수 있다.

```cpp
template <typename T, typename U>
auto add(T a, U b) {
    return a + b;
}
```

사용 예:

```cpp
auto x = add(3, 4);       // int + int
auto y = add(3, 4.5);     // int + double
auto z = add(2.5, 10);    // double + int
```

흐름은 다음과 같다.

| 호출 | 추론된 타입 | 반환값 성격 |
|---|---|---|
| `add(3, 4)` | `T = int`, `U = int` | `int` |
| `add(3, 4.5)` | `T = int`, `U = double` | 보통 `double` |
| `add(2.5, 10)` | `T = double`, `U = int` | 보통 `double` |

`auto` 반환 타입은 편리하지만, 반환 타입이 명확해야 하는 공용 인터페이스에서는 너무 많이 의존하지 않는 편이 좋다. 공부 단계에서는 `auto`가 “연산 결과 타입을 컴파일러가 계산한다”는 정도로 이해하면 충분하다.

## 7. 클래스 템플릿

함수뿐 아니라 클래스도 템플릿으로 만들 수 있다. 클래스 템플릿은 특정 타입 하나에 묶이지 않는 자료구조를 만들 때 특히 유용하다.

```cpp
template <typename T>
class Box {
private:
    T value_;

public:
    explicit Box(T value)
        : value_(value) {}

    T get() const {
        return value_;
    }

    void set(T value) {
        value_ = value;
    }
};
```

사용 예:

```cpp
Box<int> intBox(10);
Box<double> doubleBox(3.14);
Box<std::string> stringBox("hello");
```

`Box<int>`와 `Box<double>`은 같은 템플릿에서 만들어졌지만 서로 다른 타입이다.

```cpp
Box<int> a(1);
Box<double> b(1.0);

// a = b; // 오류: Box<int>와 Box<double>은 다른 타입
```

클래스 템플릿의 핵심은 다음과 같다.

| 개념 | 설명 |
|---|---|
| `Box<T>` | 아직 타입이 정해지지 않은 클래스 템플릿 |
| `Box<int>` | `T`가 `int`인 구체적인 클래스 |
| `Box<double>` | `T`가 `double`인 구체적인 클래스 |

## 8. 클래스 템플릿 멤버 함수 정의

클래스 템플릿의 멤버 함수를 클래스 밖에서 정의할 때는 함수 정의 앞에도 `template <typename T>`를 붙여야 한다.

```cpp
template <typename T>
class Box {
private:
    T value_;

public:
    explicit Box(T value);
    T get() const;
};

template <typename T>
Box<T>::Box(T value)
    : value_(value) {}

template <typename T>
T Box<T>::get() const {
    return value_;
}
```

여기서 `Box<T>::get()`처럼 클래스 이름 뒤에 `<T>`를 붙이는 이유는, 지금 정의하는 함수가 일반 `Box`가 아니라 **템플릿 클래스 `Box<T>`의 멤버 함수**이기 때문이다.

## 9. 비타입 템플릿 매개변수

템플릿 매개변수에는 타입뿐 아니라 **컴파일 타임에 결정되는 값**도 사용할 수 있다. 이것을 비타입 템플릿 매개변수라고 한다.

```cpp
template <typename T, int N>
```

위 선언에서 `T`는 타입 매개변수이고, `N`은 값 매개변수다.

| 매개변수 | 예 | 의미 |
|---|---|---|
| 타입 템플릿 매개변수 | `typename T` | `int`, `double`, `std::string` 같은 타입을 받음 |
| 비타입 템플릿 매개변수 | `int N` | `3`, `10`, `100` 같은 컴파일 타임 상수 값을 받음 |

PDF의 핵심 예시는 크기를 컴파일 타임 상수로 고정하는 `Vector<T, N>`과 `Matrix<T, R, C>`다. 여기서 `N`, `R`, `C`는 객체를 만들고 나서 정해지는 값이 아니라, 타입을 만들 때 이미 정해지는 값이다.

### 9.1 `Vector<T, N>` 예제

다음 코드는 원소 타입 `T`와 크기 `N`을 템플릿 인자로 받는 고정 크기 벡터다.

```cpp
template <typename T, int N>
class Vector {
private:
    T data_[N];

public:
    T& operator()(int i) {
        return data_[i];
    }

    const T& operator()(int i) const {
        return data_[i];
    }

    int size() const {
        return N;
    }
};
```

사용 예는 다음과 같다.

```cpp
Vector<int, 3> v;
v(0) = 1;
v(1) = 2;
v(2) = 3;

Vector<float, 2> vf;
vf(0) = 1.5f;
vf(1) = 2.5f;
```

이 예제에서 `Vector<int, 3>`은 `int` 원소 3개를 가지는 타입이고, `Vector<float, 2>`는 `float` 원소 2개를 가지는 타입이다.

| 코드 | 의미 |
|---|---|
| `Vector<int, 3>` | `int` 원소 3개를 저장하는 벡터 타입 |
| `Vector<float, 2>` | `float` 원소 2개를 저장하는 벡터 타입 |
| `T data_[N]` | `T` 타입 배열을 `N`개만큼 고정 크기로 확보 |
| `size()` | 멤버 변수를 세지 않고 템플릿 인자 `N`을 반환 |

`N`이 템플릿 인자이므로 `size()`는 객체 안에 저장된 크기 변수를 읽는 것이 아니다. 컴파일러가 `Vector<int, 3>`을 만들 때 이미 `N = 3`이라는 사실을 알고 있다.

### 9.2 읽기와 쓰기 접근

PDF 예제의 `Vector`와 `Matrix`는 `operator()`를 이용해 원소에 접근한다.

```cpp
T& operator()(int i) {
    return data_[i];
}

const T& operator()(int i) const {
    return data_[i];
}
```

두 버전이 있는 이유는 읽기와 쓰기를 구분하기 위해서다.

```cpp
Vector<int, 3> v;
v(0) = 10;           // 비-const 객체: T& 반환, 쓰기 가능

const Vector<int, 3> cv = v;
int x = cv(0);       // const 객체: const T& 반환, 읽기만 가능
// cv(0) = 20;       // 오류: const T&에는 대입할 수 없음
```

C++은 Python의 `__getitem__`, `__setitem__`처럼 읽기/쓰기 함수를 이름으로 분리하지 않는다. 대신 `const` 객체인지 아닌지와 반환 타입이 `T&`인지 `const T&`인지로 접근 가능성을 나눈다.

### 9.3 `Matrix<T, R, C>` 예제

행렬은 원소 타입 `T`, 행 개수 `R`, 열 개수 `C`를 템플릿 인자로 받을 수 있다.

```cpp
template <typename T, int R, int C>
class Matrix {
private:
    T data_[R][C];

public:
    T& operator()(int r, int c) {
        return data_[r][c];
    }

    const T& operator()(int r, int c) const {
        return data_[r][c];
    }

    int rows() const {
        return R;
    }

    int cols() const {
        return C;
    }
};
```

사용 예:

```cpp
Matrix<int, 2, 3> A;

A(0, 0) = 1;
A(0, 1) = 2;
A(0, 2) = 3;
A(1, 0) = 4;
A(1, 1) = 5;
A(1, 2) = 6;
```

`Matrix<int, 2, 3>`은 `int` 원소를 가지는 2행 3열 행렬 타입이다. 여기서 `2`와 `3`도 단순한 생성자 인자가 아니라 타입의 일부다.

| 코드 | 의미 |
|---|---|
| `Matrix<int, 2, 3>` | `int` 원소를 가지는 2행 3열 행렬 타입 |
| `Matrix<int, 3, 2>` | `int` 원소를 가지는 3행 2열 행렬 타입 |
| `Matrix<float, 2, 3>` | `float` 원소를 가지는 2행 3열 행렬 타입 |

`Matrix<int, 2, 3>`과 `Matrix<int, 3, 2>`는 저장하는 전체 원소 수가 같더라도 서로 다른 타입이다. 행과 열의 크기가 템플릿 인자로 들어갔기 때문이다.

### 9.4 비타입 인자는 컴파일 타임 상수여야 한다

비타입 템플릿 인자는 컴파일 시점에 값이 확정되어야 한다.

```cpp
Vector<int, 3> a;       // 가능: 3은 컴파일 타임 상수

constexpr int n = 4;
Vector<int, n> b;       // 가능: constexpr 값

int size = 5;
// Vector<int, size> c; // 오류: size는 런타임 변수
```

`size`는 실행 중 값이 들어가는 일반 변수이므로 템플릿 인자로 사용할 수 없다. 실행 중 크기가 달라져야 하는 자료구조라면 비타입 템플릿 매개변수보다 `std::vector<T>`처럼 런타임 크기를 관리하는 컨테이너가 더 적합하다.

### 9.5 생성자 인자와 다른 점

다음 두 방식은 겉으로는 둘 다 크기를 정하는 것처럼 보이지만 의미가 다르다.

```cpp
Vector<int, 3> a;       // 크기 3이 타입에 포함됨
std::vector<int> b(3);  // 크기 3은 객체 생성 시 전달되는 값
```

| 구분 | 비타입 템플릿 인자 | 생성자 인자 |
|---|---|---|
| 예 | `Vector<int, 3>` | `std::vector<int> v(3)` |
| 결정 시점 | 컴파일 타임 | 런타임 |
| 타입에 포함 여부 | 포함됨 | 포함되지 않음 |
| 크기 변경 | 보통 불가 | 가능 |
| 적합한 상황 | 고정 크기 벡터, 행렬, 버퍼 | 실행 중 크기가 바뀌는 배열 |

즉, `Vector<int, 3>`에서 `3`은 객체의 초기값이 아니라 타입을 구성하는 정보다. 그래서 `Vector<int, 3>`과 `Vector<int, 4>`는 서로 다른 타입으로 취급된다.

### 9.6 `using`으로 긴 템플릿 타입 줄이기

PDF는 비타입 템플릿 매개변수와 함께 `using` 별칭도 보여 준다. `Vector<int, 3>`이나 `Matrix<float, 4, 4>`처럼 템플릿 인자가 길어지면 코드를 읽기 어려워지기 때문이다.

```cpp
using Vec2i = Vector<int, 2>;
using Vec3f = Vector<float, 3>;
using Mat2x3i = Matrix<int, 2, 3>;
using Mat4f = Matrix<float, 4, 4>;
```

이제 다음처럼 짧게 쓸 수 있다.

```cpp
Vec2i position;
Vec3f velocity;
Mat2x3i transform;
```

`using`은 새 타입을 만드는 것이 아니라 기존 타입에 읽기 쉬운 이름을 붙이는 것이다.

비타입 템플릿 매개변수의 핵심은 **크기나 차원 같은 값을 타입 수준으로 끌어올린다**는 점이다. 이렇게 하면 고정 크기 벡터나 행렬처럼 크기가 명확한 자료구조를 타입 안전하게 표현할 수 있다.

## 10. 템플릿 특수화

템플릿 특수화는 일반 템플릿과 달리, 특정 타입에 대해서만 별도 구현을 제공하는 기능이다.

```cpp
template <typename T>
class Printer {
public:
    void print(T value) {
        std::cout << value << '\n';
    }
};
```

대부분의 타입은 위 일반 템플릿으로 출력할 수 있다. 그런데 `bool`은 `0`, `1` 대신 `true`, `false`로 출력하고 싶다고 하자.

```cpp
template <>
class Printer<bool> {
public:
    void print(bool value) {
        std::cout << (value ? "true" : "false") << '\n';
    }
};
```

이제 사용 흐름은 다음과 같다.

```cpp
Printer<int> p1;
p1.print(10);       // 일반 템플릿 사용

Printer<bool> p2;
p2.print(true);     // bool 특수화 사용
```

| 형태 | 의미 |
|---|---|
| `template <typename T>` | 일반 템플릿 |
| `template <>` | 모든 템플릿 매개변수를 구체적으로 지정한 특수화 |
| `Printer<bool>` | `bool` 타입에 대한 별도 구현 |

특수화는 강력하지만 너무 많이 사용하면 코드 흐름이 흩어진다. 일반 구현으로 해결하기 어려운 타입별 예외가 있을 때 제한적으로 쓰는 것이 좋다.

## 11. 템플릿과 헤더 파일

일반 함수는 보통 헤더에는 선언만 두고, `.cpp` 파일에 구현을 둔다.

```cpp
// add.h
int add(int a, int b);

// add.cpp
int add(int a, int b) {
    return a + b;
}
```

하지만 템플릿은 보통 선언과 정의를 모두 헤더에 둔다.

```cpp
// max_value.h
#pragma once

template <typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}
```

이유는 컴파일러가 템플릿을 인스턴스화하려면 템플릿의 전체 정의를 볼 수 있어야 하기 때문이다.

```cpp
// main.cpp
#include "max_value.h"

int main() {
    int x = max_value(1, 2);          // max_value<int> 필요
    double y = max_value(1.5, 2.5);   // max_value<double> 필요
}
```

`main.cpp`를 컴파일하는 순간 컴파일러는 `max_value<int>`와 `max_value<double>`을 만들어야 한다. 그러려면 함수의 선언뿐 아니라 본문까지 보여야 한다.

| 일반 함수 | 템플릿 |
|---|---|
| 선언만 보고 호출 가능 | 인스턴스화하려면 정의가 필요 |
| 구현을 `.cpp`에 두는 경우가 많음 | 구현을 헤더에 두는 경우가 많음 |
| 링크 단계에서 함수 본문을 찾음 | 컴파일 단계에서 타입별 코드를 생성 |

그래서 템플릿 코드는 헤더 파일이 길어지는 경우가 많다.

## 12. STL과 템플릿

C++ 표준 라이브러리의 많은 기능은 템플릿으로 만들어져 있다.

```cpp
std::vector<int> numbers;
std::vector<double> values;
std::vector<std::string> names;
```

`std::vector`는 클래스 템플릿이고, `<int>`, `<double>`, `<std::string>`이 실제 저장 타입을 정한다.

```cpp
std::vector<int> a;          // int를 저장하는 vector
std::vector<double> b;       // double을 저장하는 vector
std::vector<std::string> c;  // string을 저장하는 vector
```

정렬 알고리즘도 템플릿을 사용한다.

```cpp
std::vector<int> v = {5, 2, 8, 1};

std::sort(v.begin(), v.end());
```

`std::sort`는 특정 배열 타입 하나만 처리하는 함수가 아니다. 반복자(iterator)를 통해 다양한 컨테이너와 타입에 대해 동작하도록 작성된 함수 템플릿이다.

| STL 요소 | 템플릿 관점 |
|---|---|
| `std::vector<T>` | `T` 타입 원소를 저장하는 클래스 템플릿 |
| `std::stack<T>` | `T` 타입 원소를 저장하는 스택 템플릿 |
| `std::pair<T, U>` | 두 타입을 묶는 클래스 템플릿 |
| `std::sort` | 반복자 범위를 정렬하는 함수 템플릿 |

템플릿은 C++ 표준 라이브러리의 기반이라고 볼 수 있다.

## 13. 템플릿과 오버로딩 비교

템플릿과 함수 오버로딩은 모두 여러 타입을 다룰 수 있지만 목적이 다르다.

```cpp
void print(int x) {
    std::cout << x << '\n';
}

void print(double x) {
    std::cout << x << '\n';
}
```

오버로딩은 타입별로 함수를 직접 여러 개 작성한다.

```cpp
template <typename T>
void print(T x) {
    std::cout << x << '\n';
}
```

템플릿은 공통 로직을 하나의 틀로 작성한다.

| 구분 | 오버로딩 | 템플릿 |
|---|---|---|
| 함수 개수 | 타입별로 직접 작성 | 하나의 틀로 작성 |
| 적합한 상황 | 타입마다 동작이 다름 | 타입만 다르고 로직이 같음 |
| 결정 시점 | 컴파일 타임 | 컴파일 타임 |
| 예 | `print(int)`, `print(double)` | `print<T>(T)` |

동작이 타입마다 완전히 다르면 오버로딩이 더 명확하다. 반대로 타입만 다르고 구조가 같다면 템플릿이 더 적합하다.

## 14. 템플릿과 런타임 다형성 비교

템플릿은 정적 다형성의 대표적인 예다. 컴파일 시점에 타입이 결정되고, 타입별 코드가 생성된다.

반면 `virtual` 함수는 런타임 다형성이다. 실행 중 실제 객체 타입에 따라 호출 함수가 결정된다.

| 구분 | 템플릿 | `virtual` 함수 |
|---|---|---|
| 다형성 종류 | 정적 다형성 | 동적 다형성 |
| 결정 시점 | 컴파일 타임 | 런타임 |
| 타입 관계 | 상속 관계가 없어도 됨 | 보통 기본 클래스와 파생 클래스 관계 필요 |
| 장점 | 빠르고 타입 안정적 | 실행 중 객체 타입에 따라 유연하게 동작 |
| 단점 | 컴파일 오류가 길어질 수 있음 | 가상 함수 호출 비용이 있음 |

예를 들어 다음 함수 템플릿은 `draw()` 멤버 함수만 있으면 타입이 무엇이든 받을 수 있다.

```cpp
template <typename T>
void render(T& object) {
    object.draw();
}
```

이 방식은 상속이 필요 없다. 다만 `T` 타입에 `draw()`가 없으면 컴파일 오류가 난다.

```cpp
class Circle {
public:
    void draw() {}
};

Circle c;
render(c); // 가능
```

템플릿은 “이 타입이 어떤 클래스 계층에 속하는가”보다 “이 타입이 필요한 연산을 제공하는가”에 관심을 둔다.

## 15. 자주 발생하는 실수

| 실수 | 설명 | 해결 |
|---|---|---|
| 템플릿 정의를 `.cpp`에만 둠 | 사용하는 파일에서 본문을 볼 수 없어 인스턴스화 실패 | 템플릿 정의를 헤더에 둔다. |
| 모든 타입이 가능하다고 생각함 | 템플릿 내부 연산을 지원하지 않는 타입은 실패 | 필요한 연산자나 멤버 함수가 있는지 확인한다. |
| 다른 타입 인자를 섞어 호출함 | `T` 하나로 추론할 수 없는 호출이 생김 | 타입을 명시하거나 매개변수를 여러 개 둔다. |
| 템플릿과 `virtual`을 같은 것으로 이해함 | 둘 다 다형성이지만 결정 시점이 다름 | 템플릿은 컴파일 타임, `virtual`은 런타임으로 구분한다. |

템플릿은 편리하지만 컴파일러가 만들어내는 코드가 많아질 수 있고, 오류 메시지가 길어질 수 있다. 따라서 처음에는 단순한 함수 템플릿과 클래스 템플릿부터 익히는 것이 좋다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| 템플릿 | 타입을 매개변수처럼 받는 코드의 틀 |
| 함수 템플릿 | 타입만 다른 함수 중복을 줄임 |
| 클래스 템플릿 | 타입 독립적인 자료구조를 만들 수 있음 |
| 인스턴스화 | 템플릿에 실제 타입을 넣어 코드를 생성하는 과정 |
| `typename` / `class` | 템플릿 타입 매개변수 선언에서는 거의 같은 의미 |
| 비타입 매개변수 | `int N`처럼 컴파일 타임 값을 템플릿 인자로 사용 |
| 특수화 | 특정 타입에 대해서만 별도 구현 제공 |
| 헤더 정의 | 컴파일러가 인스턴스화하려면 템플릿 정의를 볼 수 있어야 함 |
| STL | `vector<T>`, `pair<T, U>`, `sort` 등은 템플릿 기반 |

템플릿의 핵심은 C++ 코드에서 타입을 고정하지 않고, **컴파일러가 실제 사용 타입에 맞는 코드를 만들어내도록 설계하는 것**이다. 이 기능 덕분에 C++은 `std::vector<int>`, `std::vector<double>`, `std::sort`처럼 타입 안전하면서도 재사용 가능한 라이브러리를 만들 수 있다.

## Study Guide

템플릿을 공부할 때는 다음 순서로 이해하면 좋다.

1. 타입만 다른 함수 중복을 직접 확인한다.
2. 함수 템플릿으로 중복을 줄인다.
3. 템플릿이 호출 시점에 타입별 함수로 인스턴스화된다는 점을 이해한다.
4. 클래스 템플릿으로 `Box<T>`, `Array<T>` 같은 타입 독립적 구조를 만든다.
5. `Vector<T, N>`과 `Matrix<T, R, C>`를 통해 비타입 템플릿 매개변수가 크기와 차원을 타입에 포함한다는 점을 확인한다.
6. STL의 `vector<int>`가 클래스 템플릿의 실제 사례임을 연결한다.
7. 템플릿은 런타임 다형성이 아니라 컴파일 타임 다형성임을 구분한다.

## 복습 질문

<details>
<summary>1. 템플릿은 왜 필요한가?</summary>

답변: 템플릿은 타입만 다르고 구조가 같은 코드를 하나의 틀로 작성하기 위해 필요하다. `int`, `double`, `std::string` 등 여러 타입에 대해 같은 로직을 반복 작성하지 않아도 되므로 중복을 줄이고 유지보수를 쉽게 만든다.

</details>

<details>
<summary>2. 함수 템플릿은 언제 실제 함수가 되는가?</summary>

답변: 함수 템플릿은 정의만으로는 실제 함수가 아니다. `max_value(3, 5)`처럼 특정 타입으로 호출될 때 컴파일러가 `max_value<int>` 같은 구체적인 함수를 생성한다. 이 과정을 인스턴스화라고 한다.

</details>

<details>
<summary>3. `template <typename T>`와 `template <class T>`는 다른가?</summary>

답변: 타입 매개변수를 선언하는 문맥에서는 거의 같은 의미다. 둘 다 `T`가 어떤 타입을 대표한다는 뜻이다. 현대 C++에서는 의미가 더 직접적인 `typename`을 선호하는 경우가 많지만, `class`도 여전히 사용할 수 있다.

</details>

<details>
<summary>4. 비타입 템플릿 매개변수에서 `Vector<int, 3>`의 `3`은 무엇을 의미하는가?</summary>

답변: `3`은 생성자에 전달되는 런타임 값이 아니라 컴파일 타임에 정해지는 템플릿 인자다. 따라서 `Vector<int, 3>`은 `int` 원소 3개를 가지는 벡터 타입이고, `Vector<int, 4>`와는 서로 다른 타입이다.

</details>

<details>
<summary>5. 템플릿 정의를 헤더에 두는 이유는 무엇인가?</summary>

답변: 컴파일러가 템플릿을 실제 타입으로 인스턴스화하려면 템플릿의 선언뿐 아니라 함수 본문이나 클래스 멤버 함수 정의까지 볼 수 있어야 한다. 그래서 템플릿은 보통 `.cpp`에 숨기지 않고 헤더에 정의까지 함께 작성한다.

</details>

<details>
<summary>6. 템플릿과 가상 함수의 차이는 무엇인가?</summary>

답변: 템플릿은 컴파일 타임에 타입별 코드를 생성하는 정적 다형성이다. 가상 함수는 런타임에 실제 객체 타입을 보고 호출 함수를 결정하는 동적 다형성이다. 템플릿은 상속 관계가 없어도 사용할 수 있지만, 필요한 연산이나 멤버 함수가 타입에 존재해야 한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 템플릿.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 템플릿.pdf</a></li>
</ul>
