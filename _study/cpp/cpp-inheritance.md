---
layout: default
date: 2026-05-18 11:56:08 +0900
title: "C++ Inheritance"
course: "C++"
topic: "Inheritance and Class Hierarchies"
order: 9
major_topic: "C++ Programming"
keywords:
  - "Inheritance"
  - "Class Hierarchies"
  - "Access Control"
  - "Overriding"
  - "Constructors"
---

# C++ Inheritance

Source PDF: `C++ 상속.pdf`

> **핵심:** **상속** 공통 기능을 기본 클래스에 두고 파생 클래스가 재사용한다. **is-a 관계** public 상속은 “파생 클래스는 기본 클래스의 일종”이라는 의미다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 상속의 의미 | 공통 기능을 어떻게 재사용하는가? |
| 2 | 기본 문법 | 기본 클래스와 파생 클래스는 어떻게 작성하는가? |
| 3 | private / protected | 파생 클래스는 어떤 멤버에 접근할 수 있는가? |
| 4 | 상속 접근 지정자 | public, protected, private 상속은 무엇이 다른가? |
| 5 | 생성자와 소멸자 순서 | 기본 클래스와 파생 클래스 중 무엇이 먼저 실행되는가? |
| 6 | 기본 클래스 생성자 호출 | 파생 클래스 생성자에서 기반 부분은 어떻게 초기화하는가? |
| 7 | 함수 숨김과 오버라이딩 | 같은 이름의 함수가 있을 때 어떤 함수가 호출되는가? |
| 8 | 업캐스팅과 다운캐스팅 | 기본 클래스 포인터와 파생 클래스 포인터는 어떻게 변환되는가? |
| 9 | 다중 상속 | 여러 클래스를 동시에 상속할 때 어떤 문제가 생기는가? |

## 1. 상속이란?

상속은 기존 클래스의 멤버와 기능을 다른 클래스가 물려받아 사용하는 문법이다.

```cpp
class Shape {
public:
    double x, y;

    Shape(double _x, double _y) : x(_x), y(_y) {}
    void print() const {
        printf("위치: (%.1f, %.1f)\n", x, y);
    }
};

class Circle : public Shape {
    double radius;

public:
    Circle(double _x, double _y, double r)
        : Shape(_x, _y), radius(r) {}

    double area() const {
        return 3.14159 * radius * radius;
    }
};
```

상속의 핵심은 다음 세 가지다.

| 개념 | 의미 |
|---|---|
| 코드 재사용 | 공통 멤버를 기본 클래스에 한 번만 작성한다. |
| is-a 관계 | `Circle`은 `Shape`의 일종이다. |
| 계층 확장 | 공통 인터페이스를 유지하면서 파생 기능을 추가한다. |

## 2. 기본 클래스와 파생 클래스

상속 관계에서 물려주는 쪽을 **기본 클래스(Base Class)** 라고 하고, 물려받는 쪽을 **파생 클래스(Derived Class)** 라고 한다.

```cpp
class Circle : public Shape {
    double r;

public:
    Circle(double _x, double _y, double _r)
        : Shape(_x, _y), r(_r) {}

    double area() const {
        return 3.14159 * r * r;
    }
};
```

`Circle : public Shape`는 `Circle`이 `Shape`를 public 방식으로 상속한다는 뜻이다.

파생 클래스는 기본 클래스의 public 멤버를 사용할 수 있다.

```cpp
Circle c(1.0, 2.0, 5.0);

printf("x=%.1f\n", c.x); // Shape의 x
c.print();               // Shape의 print()
printf("%.2f\n", c.area()); // Circle의 area()
```

`print()`는 `Shape`에 한 번만 정의했지만, `Circle`, `Rect` 같은 여러 파생 클래스에서 함께 사용할 수 있다.

## 3. private 멤버와 인터페이스 접근

기본 클래스의 private 멤버는 파생 클래스에서도 직접 접근할 수 없다.

```cpp
class Account {
    double balance; // private

public:
    Account(double _balance) : balance(_balance) {}
};

class SavingsAccount : public Account {
public:
    SavingsAccount(double _balance)
        : Account(_balance) {}

    void addInterest(double rate) {
        balance *= (1 + rate); // 오류: private 접근 불가
    }
};
```

해결 방법은 public 인터페이스를 통해 간접 접근하는 것이다.

```cpp
class Account {
    double balance;

public:
    Account(double _balance) : balance(_balance) {}

    double getBalance() const { return balance; }
    void deposit(double amount) { balance += amount; }
};

class SavingsAccount : public Account {
public:
    SavingsAccount(double _balance)
        : Account(_balance) {}

    void addInterest(double rate) {
        deposit(getBalance() * rate);
    }
};
```

이 방식은 캡슐화를 유지하면서 파생 클래스가 필요한 동작만 사용할 수 있게 한다.

## 4. protected 멤버

`protected` 멤버는 같은 클래스와 파생 클래스 내부에서는 접근할 수 있지만, 외부에서는 접근할 수 없다.

```cpp
class Shape {
private:
    int id;

protected:
    double x, y;

public:
    Shape(double _x, double _y) : id(0), x(_x), y(_y) {}
};

class Circle : public Shape {
    double r;

public:
    Circle(double _x, double _y, double _r)
        : Shape(_x, _y), r(_r) {}

    void move(double dx, double dy) {
        x += dx; // 가능: protected
        y += dy; // 가능
        // id += 1; // 오류: private
    }
};
```

접근 지정자 차이는 다음과 같다.

| 접근 지정자 | 같은 클래스 | 파생 클래스 | 외부 |
|---|---|---|---|
| `public` | 가능 | 가능 | 가능 |
| `protected` | 가능 | 가능 | 불가능 |
| `private` | 가능 | 불가능 | 불가능 |

설계 원칙은 간단하다. 파생 클래스가 직접 수정해야 하는 멤버는 `protected`, 그 외 내부 구현은 `private`으로 두는 것이 좋다.

## 5. 상속 접근 지정자

상속에도 접근 지정자를 붙일 수 있다.

```cpp
class PubDerived : public Base {};
class ProtDerived : protected Base {};
class PrivDerived : private Base {};
```

기본 클래스 멤버가 파생 클래스에서 어떤 접근 수준이 되는지는 다음과 같다.

| 기본 클래스 멤버 | public 상속 | protected 상속 | private 상속 |
|---|---|---|---|
| `public` | public | protected | private |
| `protected` | protected | protected | private |
| `private` | 접근 불가 | 접근 불가 | 접근 불가 |

예를 들어 public 상속이면 기본 클래스의 public 멤버가 파생 클래스에서도 public으로 유지된다.

```cpp
PubDerived pd;
pd.pub = 1; // 가능
```

반면 protected 상속이면 기본 클래스의 public 멤버가 파생 클래스에서 protected로 낮아진다.

```cpp
ProtDerived td;
// td.pub = 1; // 오류
```

일반적인 is-a 관계를 표현할 때는 대부분 public 상속을 사용한다. protected/private 상속은 구현 재사용 목적의 “구현 상속”에 가깝고 드물게 사용된다.

## 6. 생성자와 소멸자 호출 순서

상속 관계에서 객체가 생성될 때는 기본 클래스가 먼저 생성되고, 그 다음 파생 클래스가 생성된다.

```cpp
class Base {
public:
    Base() { printf("Base 생성\n"); }
    ~Base() { printf("Base 소멸\n"); }
};

class Derived : public Base {
public:
    Derived() { printf("Derived 생성\n"); }
    ~Derived() { printf("Derived 소멸\n"); }
};

int main() {
    Derived d;
}
```

실행 순서:

```text
Base 생성
Derived 생성
Derived 소멸
Base 소멸
```

정리하면 다음과 같다.

| 상황 | 순서 |
|---|---|
| 생성 | 기본 클래스 → 파생 클래스 |
| 소멸 | 파생 클래스 → 기본 클래스 |

객체의 기반 부분이 먼저 준비되어야 파생 클래스가 그 기반 위에 자기 멤버를 초기화할 수 있다. 소멸은 생성의 역순으로 진행된다.

## 7. 기본 클래스 생성자 호출

파생 클래스 생성자는 초기화 목록에서 기본 클래스 생성자를 명시적으로 호출할 수 있다.

```cpp
class Shape {
public:
    double x, y;

    Shape(double _x, double _y) : x(_x), y(_y) {
        printf("Shape(%g, %g) 생성\n", _x, _y);
    }
};

class Circle : public Shape {
    double r;

public:
    Circle(double _x, double _y, double _r)
        : Shape(_x, _y), r(_r) {
        printf("Circle(r=%g) 생성\n", _r);
    }
};
```

`Circle`을 만들 때 `Shape(_x, _y)`가 먼저 실행되고, 그 뒤 `r`과 `Circle` 생성자 본문이 처리된다.

상속이 여러 단계일 때도 가장 위쪽 기본 클래스부터 초기화된다.

```cpp
class Cylinder : public Circle {
    double h;

public:
    Cylinder(double _x, double _y, double _r, double _h)
        : Circle(_x, _y, _r), h(_h) {
        printf("Cylinder(h=%g) 생성\n", _h);
    }
};
```

초기화 순서는 다음과 같다.

```text
Shape → Circle → Cylinder
```

이 순서는 생성자 호출 순서와 같다고 이해해도 된다. 더 정확히 말하면, C++은 객체를 만들 때 먼저 가장 위쪽 기본 클래스 부분을 초기화하고, 그 다음 파생 클래스 부분을 차례로 초기화한다. 따라서 `Cylinder` 객체를 만들 때는 `Shape` 생성자, `Circle` 생성자, `Cylinder` 생성자 순서로 실행된다.

단, 초기화 목록에 적은 순서가 실제 초기화 순서를 마음대로 바꾸지는 못한다.

```cpp
class Cylinder : public Circle {
    double h;

public:
    Cylinder(double _x, double _y, double _r, double _h)
        : h(_h), Circle(_x, _y, _r) {
        printf("Cylinder(h=%g) 생성\n", _h);
    }
};
```

위처럼 초기화 목록에 `h(_h)`를 먼저 적어도 실제로는 기본 클래스인 `Circle`이 먼저 초기화되고, 그 다음 멤버 변수 `h`가 초기화된다. C++의 실제 초기화 순서는 다음 규칙을 따른다.

```text
기본 클래스 → 멤버 변수 → 생성자 본문
```

상속이 여러 단계라면 기본 클래스 쪽에서도 다시 가장 위쪽 기본 클래스부터 생성된다. 그래서 전체적으로는 `Shape → Circle → Cylinder`처럼 기반 클래스에서 파생 클래스로 내려오는 순서가 된다.

초기화 목록에서 기본 클래스 생성자를 호출하지 않으면 기본 생성자가 자동 호출된다. 그런데 기본 클래스에 기본 생성자가 없다면 컴파일 오류가 발생한다.

## 8. 함수 오버라이딩과 함수 숨김

파생 클래스에서 기본 클래스와 같은 이름의 함수를 다시 정의하면, 겉으로는 “덮어쓴 것”처럼 보일 수 있다. 하지만 `virtual`이 없으면 이것은 **오버라이딩**이 아니라 **함수 숨김(name hiding)** 으로 동작한다.

```cpp
class Shape {
public:
    void describe() const {
        printf("Shape\n");
    }

    double area() const {
        return 0.0;
    }
};

class Circle : public Shape {
    double r;

public:
    Circle(double _r) : r(_r) {}

    double area() const {
        return 3.14159 * r * r;
    }
};
```

직접 `Circle` 객체로 호출하면 `Circle::area()`가 호출된다.

```cpp
Circle c(5.0);
c.area();        // Circle::area
c.Shape::area(); // Shape::area 명시적 호출
```

하지만 기본 클래스 포인터로 접근하면 이야기가 달라진다.

```cpp
Shape* p = &c;
p->area(); // Shape::area 호출
```

`area()`가 `virtual`이 아니므로 호출할 함수가 포인터 타입인 `Shape*`를 기준으로 컴파일 타임에 결정된다. 즉, `Circle` 객체를 가리키고 있어도 `Shape::area()`가 호출된다.

| 구분 | 결정 시점 | 기준 | 목적 |
|---|---|---|---|
| 함수 숨김 | 컴파일 타임 | 포인터/참조 타입 | 같은 이름의 기본 클래스 함수를 가림 |
| 오버라이딩 | 런타임 | 실제 객체 타입 | 다형적 동작 제공 |

포인터나 참조를 통한 다형성이 목적이라면 기본 클래스 함수에 `virtual`을 붙여야 한다.

```cpp
class Shape {
public:
    virtual double area() const {
        return 0.0;
    }
};
```

## 9. 업캐스팅과 다운캐스팅

업캐스팅(upcasting)은 파생 클래스 객체를 기본 클래스 포인터나 참조로 다루는 변환이다. public 상속 관계에서는 항상 안전하며 암묵적으로 허용된다.

```cpp
Circle c(0, 0, 5.0);

Shape* sp = &c; // 업캐스팅
Shape& sr = c;  // 참조 업캐스팅
```

업캐스팅 후에는 기본 클래스 인터페이스를 통해 객체를 다룬다.

```cpp
sp->print(); // Shape의 public 멤버 호출 가능
```

다만 `Shape*`로는 `Circle`에만 있는 멤버에 직접 접근할 수 없다.

```cpp
// sp->area(); // Shape에 area가 없거나 virtual 인터페이스가 아니면 접근 불가
```

다운캐스팅(downcasting)은 기본 클래스 포인터를 다시 파생 클래스 포인터로 바꾸는 변환이다. 이때 실제 객체 타입이 맞는지 조심해야 한다.

```cpp
Shape* p = new Circle(0, 0, 5.0);
Circle* cp = dynamic_cast<Circle*>(p);

if (cp) {
    printf("Circle: %.2f\n", cp->area());
} else {
    printf("Circle이 아님\n");
}
```

`dynamic_cast`는 런타임에 실제 타입을 검사한다. 타입이 맞으면 파생 클래스 포인터를 돌려주고, 포인터 변환에 실패하면 `nullptr`를 반환한다. 단, 제대로 된 런타임 타입 검사를 위해 기본 클래스에 `virtual` 함수가 있어야 한다.

반면 `static_cast`는 런타임 검사를 하지 않는다.

```cpp
Shape* p = new Circle(0, 0, 5.0);
Circle* cp = static_cast<Circle*>(p); // 타입이 맞다고 확신할 때만 사용
```

실제 객체가 `Circle`이면 문제가 없지만, 실제로는 `Rect`인데 `Circle*`로 바꾸면 undefined behavior가 발생할 수 있다.

```cpp
Shape* p2 = new Rect(0, 0, 3.0, 4.0);
Circle* wrong = static_cast<Circle*>(p2); // 위험
```

정리하면 다음과 같다.

| 구분 | `static_cast` | `dynamic_cast` |
|---|---|---|
| 검사 시점 | 컴파일 타임 | 런타임 |
| 실패 시 | 잘못 쓰면 undefined behavior | 포인터는 `nullptr` |
| 속도 | 빠름 | 상대적으로 느림 |
| 요구 사항 | 타입이 맞는다는 확신 | 기본 클래스에 `virtual` 함수 필요 |

## 10. 다중 상속

다중 상속은 하나의 클래스가 여러 기본 클래스를 동시에 상속하는 것이다.

```cpp
class Flyable {
public:
    void fly() {
        printf("날기\n");
    }
};

class Swimmable {
public:
    void swim() {
        printf("수영\n");
    }
};

class Duck : public Flyable, public Swimmable {
public:
    void quack() {
        printf("꽥꽥!\n");
    }
};
```

`Duck`은 `Flyable`과 `Swimmable`을 모두 상속하므로 두 기능을 함께 사용할 수 있다.

```cpp
Duck d;
d.fly();
d.swim();
d.quack();
```

다중 상속의 대표적인 문제는 다이아몬드 문제다.

```cpp
class Animal {
public:
    int age;
};

class Lion : public Animal {};
class Tiger : public Animal {};
class Liger : public Lion, public Tiger {};
```

`Liger`는 `Lion`과 `Tiger`를 모두 상속하고, 두 클래스는 각각 `Animal`을 상속한다. 따라서 `Liger` 객체 안에는 `Animal` 부분이 두 개 생긴다.

```cpp
Liger li;
// li.age = 5;       // 오류: Lion의 age인지 Tiger의 age인지 모호함
li.Lion::age = 5;   // 가능
li.Tiger::age = 5;  // 가능
```

이 문제는 virtual 상속으로 해결할 수 있다.

```cpp
class Lion : virtual public Animal {};
class Tiger : virtual public Animal {};
class Liger : public Lion, public Tiger {};
```

virtual 상속을 사용하면 `Lion`과 `Tiger`가 `Animal` 기본 클래스 부분을 하나만 공유한다. 따라서 `Liger` 객체 안에 `Animal`이 중복으로 생기지 않고, `age`도 하나만 존재한다.

다중 상속은 여러 인터페이스나 기능을 조합할 때 유용하지만, 멤버 이름 충돌과 다이아몬드 문제를 만들 수 있으므로 신중하게 사용해야 한다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| 상속 | 공통 기능을 기본 클래스에 두고 파생 클래스가 재사용한다. |
| is-a 관계 | public 상속은 “파생 클래스는 기본 클래스의 일종”이라는 의미다. |
| private | 파생 클래스에서도 직접 접근할 수 없다. |
| protected | 파생 클래스 내부에서는 접근 가능하지만 외부에서는 불가능하다. |
| public 상속 | 일반적인 상속 관계에서 가장 많이 사용한다. |
| 생성 순서 | 기본 클래스가 먼저 생성된다. |
| 소멸 순서 | 파생 클래스가 먼저 소멸된다. |
| 초기화 순서 | 초기화 목록의 작성 순서가 아니라 기본 클래스 → 멤버 변수 → 생성자 본문 순서를 따른다. |
| 기본 생성자 호출 | 명시하지 않으면 기본 생성자가 자동 호출되며, 없으면 오류다. |
| 함수 숨김 | `virtual`이 없으면 기본 클래스 포인터로 호출할 때 포인터 타입 기준으로 결정된다. |
| 오버라이딩 | `virtual`을 사용하면 실제 객체 타입 기준으로 런타임에 함수가 결정된다. |
| 업캐스팅 | 파생 클래스 객체를 기본 클래스 포인터/참조로 다루는 안전한 변환이다. |
| 다운캐스팅 | 기본 클래스 포인터를 파생 클래스 포인터로 바꾸는 변환이며, `dynamic_cast`가 더 안전하다. |
| 다중 상속 | 여러 클래스를 동시에 상속할 수 있지만 다이아몬드 문제에 주의해야 한다. |
| virtual 상속 | 다이아몬드 구조에서 공통 기본 클래스를 하나만 공유하게 한다. |

상속은 코드 재사용을 위한 문법이지만, 단순히 코드를 물려받는 기능만은 아니다. 올바른 상속은 “파생 클래스가 기본 클래스의 일종인가?”라는 is-a 관계가 성립할 때 가장 자연스럽다.

## Study Guide

상속은 문법보다 관계를 먼저 판단해야 한다. `Circle`이 `Shape`의 일종이라면 public 상속이 자연스럽지만, 단순히 코드를 재사용하고 싶다는 이유만으로 상속을 쓰면 구조가 쉽게 꼬인다. 먼저 is-a 관계가 성립하는지 확인하는 습관이 중요하다.

생성자와 소멸자 순서는 반드시 외워야 한다. 객체가 만들어질 때는 기본 클래스 부분이 먼저 준비되어야 파생 클래스가 그 위에 자기 멤버를 초기화할 수 있다. 반대로 소멸할 때는 파생 클래스가 자기 자원을 먼저 정리한 뒤 기본 클래스 부분이 정리된다.

오버라이딩과 함수 숨김은 실수하기 쉬운 지점이다. `virtual`이 없으면 기본 클래스 포인터로 호출할 때 포인터 타입 기준으로 함수가 결정될 수 있다. 다형적 사용을 의도한다면 기본 클래스 함수에 `virtual`을 붙이고, 파생 클래스에는 `override`를 붙이는 습관이 안전하다.

## 복습 질문

<details>
<summary>1. 파생 클래스 객체가 생성될 때 기본 클래스와 파생 클래스 중 어느 생성자가 먼저 실행되는가?</summary>

답변: 기본 클래스 생성자가 먼저 실행되고, 그 다음 멤버 변수가 초기화된 뒤 파생 클래스 생성자 본문이 실행된다. 소멸은 반대로 파생 클래스 소멸자부터 실행되고 기본 클래스 소멸자가 나중에 실행된다.

</details>

<details>
<summary>2. `private` 멤버와 `protected` 멤버는 파생 클래스에서 어떻게 다르게 보이는가?</summary>

답변: `private` 멤버는 파생 클래스 내부에서도 직접 접근할 수 없다. `protected` 멤버는 외부에서는 접근할 수 없지만, 파생 클래스 내부에서는 직접 접근할 수 있다.

</details>

<details>
<summary>3. 다중 상속의 다이아몬드 문제는 무엇이며, virtual 상속은 어떻게 해결하는가?</summary>

답변: 두 부모 클래스가 같은 기본 클래스를 상속하고, 파생 클래스가 그 두 부모를 모두 상속하면 기본 클래스 부분이 두 개 생겨 멤버 접근이 모호해질 수 있다. virtual 상속을 사용하면 공통 기본 클래스 부분을 하나만 공유하게 만들어 중복을 줄인다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 상속.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 상속.pdf</a></li>
</ul>
