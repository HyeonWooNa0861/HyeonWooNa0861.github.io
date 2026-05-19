---
layout: default
title: "C Structs and C++ Classes"
course: "C++"
topic: "구조체와 클래스"
order: 2
---

# C Structs and C++ Classes

Source PDFs:

- `C_구조체.pdf`
- `클래스 (Class) 입문.pdf`
- `C에서 C++로 넘어가기.pdf`

세 자료는 C의 구조체에서 출발해 C++ 클래스, 접근 제어, 생성자, 문자열, C/C++ 헤더 차이로 넘어가는 흐름을 공유한다. 중복되는 “데이터 묶기” 설명은 합치고, C에서 C++로 확장되는 순서로 정리했다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 구조체 | 관련 데이터를 하나의 타입으로 묶는 방법은? |
| 2 | 구조체 포인터 | `.`와 `->`는 어떻게 다른가? |
| 3 | 구조체와 함수 | 큰 구조체는 어떻게 전달하는 것이 좋은가? |
| 4 | 구조체에서 클래스로 | 데이터와 함수를 한 타입에 묶을 수 있는가? |
| 5 | 접근 지정자 | 외부에 공개할 것과 숨길 것을 어떻게 나누는가? |
| 6 | 생성자/소멸자 | 객체 생성과 정리는 언제 자동으로 일어나는가? |
| 7 | C에서 C++로 | C 헤더, 문자열, 메모리 관리는 C++에서 어떻게 바뀌는가? |

## 1. 구조체란?

구조체는 관련 있는 여러 데이터를 하나의 사용자 정의 타입으로 묶는 문법이다.

```c
struct Student {
    char name[32];
    int age;
    double gpa;
};
```

구조체를 쓰면 흩어진 변수를 하나의 의미 있는 단위로 다룰 수 있다.

```c
struct Student s;
strcpy(s.name, "홍길동");
s.age = 20;
s.gpa = 4.1;
```

## 2. 구조체 선언과 초기화

```c
struct Point {
    int x;
    int y;
};

struct Point p = { 10, 20 };
```

구조체 멤버에는 `.` 연산자로 접근한다.

```c
printf("(%d, %d)\n", p.x, p.y);
```

## 3. `typedef`로 구조체 이름 단순화

C에서는 `struct Student`처럼 `struct` 키워드를 매번 써야 한다. `typedef`를 사용하면 타입 이름을 단순화할 수 있다.

```c
typedef struct {
    char name[32];
    int age;
} Student;

Student s;
```

이 방식은 C 코드에서 구조체를 더 간결하게 사용할 때 자주 쓰인다.

## 4. 구조체 포인터와 `->`

구조체 변수가 직접 있을 때는 `.`를 사용한다.

```c
Student s;
s.age = 20;
```

구조체 포인터가 있을 때는 `->`를 사용한다.

```c
Student* p = &s;
p->age = 21;
```

`p->age`는 사실상 `(*p).age`와 같은 뜻이다.

| 표현 | 의미 |
|---|---|
| `s.age` | 구조체 변수의 멤버 접근 |
| `p->age` | 구조체 포인터가 가리키는 객체의 멤버 접근 |
| `(*p).age` | `p->age`와 같은 의미 |

## 5. 구조체와 함수

구조체를 함수에 값으로 전달하면 전체 구조체가 복사된다.

```c
void print_point(Point p) {
    printf("(%d, %d)\n", p.x, p.y);
}
```

구조체가 크면 복사 비용이 커진다. 이때는 포인터를 전달하는 것이 좋다.

```c
void print_point(const Point* p) {
    printf("(%d, %d)\n", p->x, p->y);
}
```

`const Point*`는 함수가 구조체를 읽기만 하고 수정하지 않겠다는 뜻이다.

## 6. 구조체 배열과 동적 할당

고정 크기 배열:

```c
Student students[30];
```

실행 중 필요한 크기가 결정된다면 동적 할당을 사용할 수 있다.

```c
Student* students = malloc(sizeof(Student) * count);

// 사용 후
free(students);
```

구조체 동적 할당은 `malloc`과 `free` 쌍이 맞아야 하며, 해제 후 포인터 사용에 주의해야 한다.

## 7. 구조체에서 클래스로

C 구조체는 주로 데이터를 묶는 데 사용한다. C++ 클래스는 데이터와 함수를 함께 묶어 하나의 타입을 만든다.

```cpp
class Student {
public:
    int age;
    char name[32];

    void greet() const {
        printf("안녕하세요, %s입니다.\n", name);
    }
};
```

사용:

```cpp
Student s;
s.age = 20;
strcpy(s.name, "홍길동");
s.greet();
```

클래스는 구조체보다 객체의 상태와 동작을 함께 설계하는 데 적합하다.

## 8. 접근 지정자

C++ 클래스는 `public`, `private`로 외부 공개 범위를 제어한다.

```cpp
class BankAccount {
public:
    void deposit(int amount) {
        if (amount > 0) balance += amount;
    }

    int get_balance() const {
        return balance;
    }

private:
    int balance = 0;
};
```

외부에서는 public 함수만 사용할 수 있고, private 멤버는 직접 접근할 수 없다.

```cpp
BankAccount acc;
acc.deposit(1000);
printf("%d\n", acc.get_balance());

// acc.balance = 9999; // 오류
```

이처럼 내부 데이터를 숨기고 공개 인터페이스를 통해서만 다루게 하는 것을 캡슐화라고 한다.

## 9. 생성자와 소멸자

생성자는 객체가 만들어질 때 자동으로 호출되는 함수다. 클래스 이름과 같고 반환형이 없다.

```cpp
class Student {
public:
    int age;
    char name[32];

    Student(int age, const char* name) {
        this->age = age;
        strcpy(this->name, name);
    }
};
```

소멸자는 객체가 사라질 때 자동으로 호출된다. 이름 앞에 `~`가 붙고 인자가 없다.

```cpp
~Student() {
    printf("Student 소멸\n");
}
```

동적 메모리나 파일 같은 자원을 가진 클래스에서는 소멸자에서 자원을 정리한다.

## 10. 멤버 초기화 리스트

생성자 본문에서 대입하는 방식보다 멤버 초기화 리스트가 권장된다.

```cpp
class Point {
public:
    int x;
    int y;

    Point(int a, int b) : x(a), y(b) {}
};
```

초기화 리스트는 멤버가 생성될 때 바로 값을 넣는다. `const` 멤버나 참조 멤버는 반드시 초기화 리스트로 초기화해야 한다.

## 11. `this` 포인터와 메서드 체이닝

`this`는 현재 객체 자신을 가리키는 포인터다. 매개변수 이름과 멤버 이름이 같을 때 구분하는 데 사용할 수 있다.

```cpp
this->age = age;
```

함수가 `*this`를 반환하면 메서드 체이닝이 가능하다.

```cpp
class Builder {
public:
    Builder& setA(int value) {
        a = value;
        return *this;
    }
};
```

## 12. C 헤더와 C++ 헤더

C++에서는 C 표준 헤더를 C++ 스타일 헤더로 포함할 수 있다.

| C 헤더 | C++ 헤더 | 주요 내용 |
|---|---|---|
| `<stdio.h>` | `<cstdio>` | `printf`, `scanf`, `fopen` |
| `<stdlib.h>` | `<cstdlib>` | `malloc`, `free`, `exit` |
| `<string.h>` | `<cstring>` | `strcpy`, `strlen`, `memcpy` |

C++ 헤더를 쓰면 함수들이 주로 `std::` 네임스페이스 안에 배치된다.

## 13. `std::string`

C 스타일 문자열은 `char` 배열과 널 문자로 표현된다. C++에서는 `std::string`을 사용해 문자열을 더 안전하고 편하게 다룰 수 있다.

```cpp
#include <string>

std::string a = "hello";
std::string b = " world";
std::string s = a + b;
```

C 문자열이 필요할 때는 `c_str()`을 사용한다.

```cpp
printf("%s\n", s.c_str());
```

## 14. `std::string_view`

C++17의 `std::string_view`는 문자열을 복사하지 않고 읽기 전용으로 참조하는 타입이다.

```cpp
#include <string_view>

void print_len(std::string_view s) {
    printf("%zu\n", s.size());
}
```

`const char*`와 `std::string`을 모두 받을 수 있어 읽기 전용 문자열 인자로 유용하다.

## 15. C와 C++ 혼용 시 주의사항

| 주제 | 주의점 |
|---|---|
| `void*` | C에서는 암묵 변환이 되지만 C++에서는 명시 캐스팅이 필요하다. |
| 전역 `const` | C와 C++에서 링키지 규칙이 다를 수 있다. |
| 메모리 관리 | `malloc/free`와 `new/delete`를 섞어 쓰면 안 된다. |
| 문자열 | C++에서는 가능하면 `std::string`, 읽기 전용은 `std::string_view`를 사용한다. |

C 라이브러리를 쓸 수는 있지만, C++ 코드에서는 타입 안전성과 RAII를 유지하는 방향으로 감싸서 사용하는 것이 좋다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| 구조체 | 관련 데이터를 하나의 타입으로 묶는다. |
| `.` | 구조체/객체 값의 멤버 접근 |
| `->` | 구조체/객체 포인터의 멤버 접근 |
| 구조체 포인터 전달 | 큰 구조체 복사를 피하고 원본 접근이 가능하다. |
| 클래스 | 데이터와 함수를 함께 묶은 사용자 정의 타입 |
| `public` / `private` | 외부 공개 여부를 제어한다. |
| 생성자 | 객체 생성 시 자동 호출된다. |
| 소멸자 | 객체 소멸 시 자동 호출된다. |
| 초기화 리스트 | 멤버를 생성과 동시에 초기화하는 권장 방식 |
| `std::string` | C++의 안전하고 편리한 문자열 타입 |
| `std::string_view` | 복사 없이 문자열을 읽기 전용으로 참조한다. |

이 문서는 C의 구조체가 C++ 클래스와 객체지향 문법으로 확장되는 흐름을 정리한 것이다.

## Study Guide

이 문서는 C의 `struct`에서 C++의 `class`로 넘어가는 다리를 놓는다. 구조체는 관련 데이터를 하나로 묶는 도구이고, 클래스는 거기에 동작과 접근 제어를 함께 넣어 객체의 책임을 더 명확하게 만든다.

`private`와 `public`은 캡슐화의 출발점이다. 멤버 변수를 모두 공개하면 외부 코드가 객체 상태를 마음대로 바꿀 수 있다. 반대로 내부 데이터는 숨기고 필요한 함수만 공개하면 객체가 스스로 유효한 상태를 유지하기 쉬워진다.

생성자, 소멸자, 초기화 리스트는 객체 수명과 연결해서 공부해야 한다. 객체가 만들어질 때 어떤 값으로 시작하는지, 사라질 때 어떤 정리가 필요한지, 멤버가 언제 초기화되는지를 이해하면 이후 RAII와 스마트 포인터도 더 쉽게 이어진다.

## 복습 질문

<details>
<summary>1. 구조체 포인터에서 `.` 대신 `->`를 사용하는 이유는 무엇인가?</summary>

답변: `.`는 구조체 또는 객체 값 자체의 멤버에 접근할 때 사용하고, `->`는 포인터가 가리키는 객체의 멤버에 접근할 때 사용한다. `p->age`는 `(*p).age`와 같은 의미다.

</details>

<details>
<summary>2. C++ 클래스에서 `private`와 `public`을 나누는 이유는 무엇인가?</summary>

답변: 외부에 공개할 인터페이스와 내부 구현 세부사항을 분리하기 위해서다. 데이터 멤버를 `private`로 숨기고 필요한 함수만 `public`으로 열어 두면 객체 상태를 더 안전하게 관리할 수 있다.

</details>

<details>
<summary>3. 생성자 초기화 리스트를 사용하는 이유는 무엇인가?</summary>

답변: 멤버 변수를 생성과 동시에 초기화할 수 있기 때문이다. 특히 `const` 멤버, 참조 멤버, 기본 생성자가 없는 멤버 객체는 생성자 본문에서 대입할 수 없으므로 초기화 리스트가 필요하다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C_구조체.pdf" | relative_url }}" target="_blank" rel="noopener">C_구조체.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/클래스 (Class) 입문.pdf" | relative_url }}" target="_blank" rel="noopener">클래스 (Class) 입문.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C에서 C++로 넘어가기.pdf" | relative_url }}" target="_blank" rel="noopener">C에서 C++로 넘어가기.pdf</a></li>
</ul>
