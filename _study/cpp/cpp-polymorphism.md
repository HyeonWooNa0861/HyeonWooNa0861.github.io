---
layout: default
date: 2026-05-18 11:56:08 +0900
title: "C++ Polymorphism"
course: "C++"
topic: "Virtual Functions and Dynamic Binding"
order: 10
major_topic: "C++ Programming"
keywords:
  - "Virtual Functions"
  - "Dynamic Binding"
  - "Abstract Classes"
  - "Vtables"
  - "Runtime Polymorphism"
---

# C++ Polymorphism

Source PDF: `C++ 다형성.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 다형성의 의미 | 같은 호출이 여러 타입에서 다르게 동작할 수 있는가? |
| 2 | 정적/동적 다형성 | 함수 선택은 컴파일 타임인가, 런타임인가? |
| 3 | 가상 함수 | 기본 클래스 포인터로 파생 클래스 함수를 호출하려면? |
| 4 | 추상 클래스 | 반드시 구현해야 하는 인터페이스를 어떻게 강제하는가? |
| 5 | 가상 소멸자 | 기본 클래스 포인터로 삭제할 때 왜 virtual 소멸자가 필요한가? |
| 6 | `override`, `final` | 오버라이딩 오류를 어떻게 방지하고 제한하는가? |

## 1. 다형성이란?

다형성은 같은 이름의 함수 호출이 객체의 타입이나 상황에 따라 다르게 동작하는 성질이다. C++의 다형성은 크게 정적 다형성과 동적 다형성으로 나뉜다.

| 종류 | 결정 시점 | 메커니즘 | 예 |
|---|---|---|---|
| 정적 다형성 | 컴파일 타임 | 함수 오버로딩, 템플릿 | `print(int)`, `print(double)` |
| 동적 다형성 | 런타임 | `virtual` 함수 + 포인터/참조 | `Animal*` → `Dog::speak()` |

정적 다형성은 컴파일러가 어떤 함수를 호출할지 미리 결정한다.

```cpp
void draw(Circle c) { /* ... */ }
void draw(Rectangle r) { /* ... */ }
```

동적 다형성은 실행 중 실제 객체 타입에 따라 호출할 함수가 결정된다.

```cpp
void render(Shape* s) {
    s->draw(); // 실제 객체가 Circle인지 Rectangle인지 런타임에 결정
}
```

핵심은 기본 클래스 포인터나 참조를 통해 파생 클래스 객체를 다룰 때, `virtual` 함수 호출이 실제 객체 타입 기준으로 결정된다는 점이다.

## 2. 가상 함수와 동적 바인딩

`virtual`이 없으면 기본 클래스 포인터로 호출할 때 포인터 타입 기준으로 함수가 결정된다.

```cpp
class Animal {
public:
    void speak() const { printf("...\n"); }
};

class Dog : public Animal {
public:
    void speak() const { printf("왈왈!\n"); }
};

Animal* p = new Dog();
p->speak(); // "..." 출력
delete p;
```

`p`가 실제로는 `Dog` 객체를 가리키더라도, 포인터 타입이 `Animal*`이므로 `Animal::speak()`가 호출된다. 이것을 정적 바인딩이라고 볼 수 있다.

반대로 기본 클래스 함수에 `virtual`을 붙이면 런타임에 실제 객체 타입을 기준으로 함수가 선택된다.

```cpp
class Animal {
public:
    virtual void speak() const { printf("...\n"); }
    virtual ~Animal() {}
};

class Dog : public Animal {
public:
    void speak() const override { printf("왈왈!\n"); }
};

Animal* p = new Dog();
p->speak(); // "왈왈!" 출력
delete p;
```

이처럼 `virtual` 함수는 기본 클래스 포인터/참조를 통해 호출해도 파생 클래스의 오버라이딩 함수가 실행되도록 한다.

## 3. 다형성 활용 예시

다형성을 사용하면 서로 다른 파생 클래스 객체를 하나의 기본 클래스 포인터 배열에 담아 공통 방식으로 처리할 수 있다.

```cpp
class Animal {
public:
    std::string name;

    Animal(const std::string& n) : name(n) {}

    virtual void speak() const {
        printf("%s: ...\n", name.c_str());
    }

    virtual ~Animal() {}
};

class Dog : public Animal {
public:
    Dog(const std::string& n) : Animal(n) {}

    void speak() const override {
        printf("%s: 왈왈!\n", name.c_str());
    }
};

class Cat : public Animal {
public:
    Cat(const std::string& n) : Animal(n) {}

    void speak() const override {
        printf("%s: 야옹!\n", name.c_str());
    }
};
```

사용:

```cpp
Dog dog("멍멍이");
Cat cat("냥냥이");
Dog dog2("바둑이");

Animal* zoo[] = { &dog, &cat, &dog2 };

for (Animal* a : zoo) {
    a->speak();
}
```

출력:

```text
멍멍이: 왈왈!
냥냥이: 야옹!
바둑이: 왈왈!
```

배열의 타입은 모두 `Animal*`이지만, 실제 객체가 `Dog`인지 `Cat`인지에 따라 다른 `speak()`가 호출된다.

## 4. 순수 가상 함수와 추상 클래스

순수 가상 함수는 함수 선언 뒤에 `= 0`을 붙여 만든다.

```cpp
class Shape {
public:
    virtual double area() const = 0;
    virtual double perimeter() const = 0;

    virtual void print() const {
        printf("넓이=%.2f\n", area());
    }

    virtual ~Shape() {}
};
```

순수 가상 함수를 하나라도 가진 클래스는 추상 클래스가 된다. 추상 클래스는 직접 객체를 만들 수 없다.

```cpp
// Shape s;    // 오류
// new Shape;  // 오류
```

추상 클래스는 공통 인터페이스를 강제하는 기반 타입으로 사용된다.

```cpp
class Circle : public Shape {
    double r;

public:
    Circle(double r) : r(r) {}

    double area() const override {
        return 3.14159 * r * r;
    }

    double perimeter() const override {
        return 2 * 3.14159 * r;
    }
};
```

```cpp
class Rect : public Shape {
    double w, h;

public:
    Rect(double w, double h) : w(w), h(h) {}

    double area() const override {
        return w * h;
    }

    double perimeter() const override {
        return 2 * (w + h);
    }
};
```

이후에는 기본 클래스 포인터 배열로 여러 도형을 함께 다룰 수 있다.

```cpp
Circle c(5);
Rect r(3, 4);

Shape* shapes[] = { &c, &r };

for (Shape* s : shapes) {
    s->print();
}
```

`print()`는 기본 클래스에 정의되어 있지만, 내부에서 호출하는 `area()`는 실제 객체 타입에 따라 `Circle::area()` 또는 `Rect::area()`로 결정된다.

## 5. 가상 소멸자

다형성으로 사용할 기본 클래스에는 반드시 가상 소멸자를 선언해야 한다.

가상 소멸자가 없는 경우:

```cpp
class Base {
public:
    ~Base() { printf("Base 소멸\n"); }
};

class Derived : public Base {
    int* data;

public:
    Derived() : data(new int[100]) {}

    ~Derived() {
        delete[] data;
        printf("Derived 소멸\n");
    }
};

Base* p = new Derived();
delete p; // Base 소멸자만 호출될 수 있음
```

이 경우 `Derived::~Derived()`가 호출되지 않으면 `data`가 해제되지 않아 메모리 누수가 발생한다.

올바른 방식:

```cpp
class Base {
public:
    virtual ~Base() { printf("Base 소멸\n"); }
};
```

이제:

```cpp
Base* p = new Derived();
delete p;
```

를 실행하면 소멸 순서가 올바르게 진행된다.

```text
Derived 소멸
Base 소멸
```

규칙은 다음과 같다.

> 기본 클래스 포인터/참조로 다형성을 사용할 클래스라면 기본 클래스 소멸자는 반드시 `virtual`로 둔다.

## 6. `override`

`override`는 파생 클래스 함수가 실제로 기본 클래스의 가상 함수를 오버라이딩하는지 컴파일러에게 검사하게 한다.

```cpp
class Animal {
public:
    virtual void speak() const {}
    virtual void move() const {}
};

class Dog : public Animal {
public:
    void speak() const override {}

    // void move(int speed) const override {}
    // 오류: Animal::move(int)는 없음
};
```

`override`를 붙이면 함수 이름, 매개변수, `const` 여부 등이 기본 클래스와 맞는지 컴파일러가 검증한다. `override`가 없으면 오타나 서명 불일치가 단순한 함수 숨김(hiding)으로 넘어갈 수 있다.

## 7. `final`

`final`은 더 이상 오버라이딩할 수 없도록 막는 키워드다.

```cpp
class Shape {
public:
    virtual double area() const = 0;
};

class Circle : public Shape {
    double r = 1.0;

public:
    double area() const override final {
        return 3.14159 * r * r;
    }
};

// class Ellipse : public Circle {
//     double area() const override {}
// };
// 오류: Circle::area는 final
```

클래스 자체에 `final`을 붙이면 상속 자체를 막을 수 있다.

```cpp
class ImmutablePoint final {
    double x, y;
};

// class Sub : public ImmutablePoint {};
// 오류
```

## 8. vtable 개념

강의 자료에는 `vtable`이 등장한다. `vtable`은 컴파일러가 가상 함수 호출을 구현하기 위해 내부적으로 만드는 함수 포인터 배열이라고 이해할 수 있다.

객체가 가상 함수를 가진 클래스에 속하면, 런타임에 실제 타입의 vtable을 통해 어떤 함수가 호출될지 결정된다. 개발자가 직접 vtable을 조작하지는 않지만, 동적 다형성이 런타임 디스패치로 동작한다는 점을 이해하는 데 중요하다.

## 마지막 핵심 정리

| 개념 | 키워드 / 문법 | 핵심 |
|---|---|---|
| 정적 다형성 | 오버로딩, 템플릿 | 컴파일 타임 결정, 오버헤드 없음 |
| 동적 다형성 | `virtual` + 포인터/참조 | 런타임 결정, 확장에 열려 있음 |
| 가상 함수 | `virtual void f()` | 파생 클래스 버전이 런타임에 호출됨 |
| vtable | 컴파일러 자동 생성 | 함수 포인터 배열을 통한 런타임 디스패치 |
| 순수 가상 함수 | `virtual f() = 0` | 추상 클래스, 인터페이스 강제 |
| 가상 소멸자 | `virtual ~Base()` | 다형성 클래스에 필수, 누수 방지 |
| `override` | `void f() override` | 오버라이딩 서명을 컴파일 타임에 검증 |
| `final` | `void f() final` | 이후 오버라이딩 금지 |

다형성의 핵심은 기본 클래스 포인터나 참조로 파생 클래스 객체를 다루더라도, `virtual` 함수 호출은 실제 객체 타입을 기준으로 런타임에 결정된다는 점이다. 이를 통해 새로운 파생 클래스를 추가해도 기존 처리 코드를 크게 바꾸지 않는 확장 가능한 구조를 만들 수 있다.

## Study Guide

다형성은 "같은 호출, 다른 동작"으로 시작하면 이해하기 쉽다. 정적 다형성은 컴파일 타임에 함수가 결정되고, 동적 다형성은 런타임에 실제 객체 타입을 보고 함수가 결정된다. 이 문서에서는 특히 `virtual`을 통한 동적 다형성이 핵심이다.

기본 클래스 포인터나 참조로 파생 클래스 객체를 다룰 때 `virtual`이 없으면 기대한 함수가 호출되지 않을 수 있다. 다형적으로 사용될 함수를 기본 클래스에서 `virtual`로 선언하고, 파생 클래스에서 `override`를 붙여 정확히 오버라이딩했는지 확인하는 것이 안전하다.

가상 소멸자는 별도 암기 항목처럼 중요하다. 기본 클래스 포인터로 파생 객체를 삭제할 가능성이 있다면 기본 클래스 소멸자는 반드시 `virtual`이어야 한다. 그렇지 않으면 파생 클래스의 정리 코드가 실행되지 않을 수 있다.

## 복습 질문

<details>
<summary>1. 정적 다형성과 동적 다형성의 차이는 무엇인가?</summary>

답변: 정적 다형성은 컴파일 타임에 호출될 함수가 결정되며 함수 오버로딩과 템플릿이 대표적이다. 동적 다형성은 런타임에 실제 객체 타입을 보고 호출될 함수가 결정되며 `virtual` 함수와 기본 클래스 포인터/참조를 사용한다.

</details>

<details>
<summary>2. 기본 클래스 포인터로 파생 클래스 객체를 삭제할 때 기본 클래스 소멸자가 `virtual`이어야 하는 이유는 무엇인가?</summary>

답변: 기본 클래스 소멸자가 virtual이 아니면 기본 클래스 포인터로 `delete`할 때 파생 클래스 소멸자가 호출되지 않을 수 있다. 그러면 파생 클래스가 가진 자원이 해제되지 않아 누수나 정리 누락이 발생할 수 있다.

</details>

<details>
<summary>3. `override`를 붙이는 이유는 무엇인가?</summary>

답변: 파생 클래스 함수가 실제로 기본 클래스의 가상 함수를 오버라이딩하는지 컴파일러가 검사하게 하기 위해서다. 함수 이름, 매개변수, `const` 여부가 맞지 않으면 오류를 내므로 실수로 함수 숨김이 발생하는 것을 줄일 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 다형성.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 다형성.pdf</a></li>
</ul>
