---
layout: default
title: "C++ Final Exam Review"
course: "C++"
topic: "Study and Assignment Integrated Review"
order: 90
major_topic: "C++ Programming"
keywords:
  - "C++ Review"
  - "Object-Oriented Programming"
  - "Pointers"
  - "Templates"
  - "STL"
---

# C++ Final Exam Review

Source PDFs:

- `C 프로그래밍 소개.pdf`
- `C 프로그래밍 개요.pdf`
- `C_구조체.pdf`
- `클래스 (Class) 입문.pdf`
- `C에서 C++로 넘어가기.pdf`
- `C_동적할당.pdf`
- `(심화) C++ 포인터.pdf`
- `C++ 표준 스트림 (updated).pdf`
- `참조 (Reference).pdf`
- `열거형 (Enum).pdf`
- `C++ 오버로딩.pdf`
- `C++ 함수포인터.pdf`
- `C++ 상속.pdf`
- `C++ 다형성.pdf`
- `C++ 템플릿.pdf`
- `C++ STL.pdf`
- `Operator Overloading.pdf`
- `Code Data Stack Heap.pdf`
- `Smart Pointer, RAII, Reference Counting.pdf`
- `stdin, stdout, stderr, File Descriptor.pdf`

Source Pages:

<ul>
  <li><a href="{{ "/study/cpp/c-programming-basics/" | relative_url }}">C Programming Fundamentals</a></li>
  <li><a href="{{ "/study/cpp/c-struct-to-cpp-class/" | relative_url }}">C Structs and C++ Classes</a></li>
  <li><a href="{{ "/study/cpp/cpp-pointer-memory/" | relative_url }}">C and C++ Pointer Memory</a></li>
  <li><a href="{{ "/study/cpp/cpp-standard-stream/" | relative_url }}">C++ Standard Streams</a></li>
  <li><a href="{{ "/study/cpp/cpp-reference/" | relative_url }}">C++ References</a></li>
  <li><a href="{{ "/study/cpp/cpp-enum/" | relative_url }}">C++ Enumerations</a></li>
  <li><a href="{{ "/study/cpp/cpp-overloading/" | relative_url }}">C++ Classes and Operator Overloading</a></li>
  <li><a href="{{ "/study/cpp/cpp-function-pointer/" | relative_url }}">C++ Function Pointers</a></li>
  <li><a href="{{ "/study/cpp/cpp-inheritance/" | relative_url }}">C++ Inheritance</a></li>
  <li><a href="{{ "/study/cpp/cpp-polymorphism/" | relative_url }}">C++ Polymorphism</a></li>
  <li><a href="{{ "/study/cpp/cpp-templates/" | relative_url }}">C++ Templates</a></li>
  <li><a href="{{ "/study/cpp/cpp-stl/" | relative_url }}">C++ STL</a></li>
  <li><a href="{{ "/assignment/cpp/operator-overloading/" | relative_url }}">Operator Overloading Assignment</a></li>
  <li><a href="{{ "/assignment/cpp/program-memory-areas/" | relative_url }}">Program Memory Areas Assignment</a></li>
  <li><a href="{{ "/assignment/cpp/smart-pointer-memory-management/" | relative_url }}">Smart Pointer and Memory Management Assignment</a></li>
  <li><a href="{{ "/assignment/cpp/standard-io-file-descriptor/" | relative_url }}">Standard I/O and File Descriptor Assignment</a></li>
</ul>

## 전체 흐름

| 순서 | 큰 주제 | 시험에서 묻는 핵심 |
|---|---|---|
| 1 | C/C++ 기초 | 컴파일, 변수, 함수, 포인터, C와 C++ 차이 |
| 2 | 메모리와 자원 관리 | Code/Data/Stack/Heap, `malloc/free`, `new/delete`, RAII |
| 3 | 구조체와 클래스 | 접근 지정자, 생성자/소멸자, `this`, 초기화 리스트 |
| 4 | 참조와 const | 값 전달, 포인터 전달, 참조 전달, `const T&` |
| 5 | 표준 입출력 | `cin/cout/cerr`, 버퍼, `stdin/stdout/stderr`, file descriptor |
| 6 | enum | C-style enum과 `enum class`, 기반 타입, 비트 플래그 |
| 7 | 연산자 오버로딩 | 멤버/비멤버, `friend`, `[]`, `()`, `<<`, Python 비교 |
| 8 | 함수 포인터와 콜백 | 함수 주소, `qsort`, `std::sort`, 람다, hook |
| 9 | 상속과 다형성 | 생성 순서, 접근 지정자, overriding, virtual, vtable |
| 10 | 템플릿 | 함수/클래스 템플릿, 비타입 템플릿, 특수화, 헤더 정의 |
| 11 | STL | 컨테이너, iterator, algorithm, erase-remove, `map`/`set` |

## 1. 시험 직전 큰 지도

C++ 기말 범위는 작은 문법을 따로 외우는 시험이라기보다, **타입과 메모리, 객체 수명, 함수 호출 방식, STL 패턴을 연결해서 설명하는 시험**으로 보는 것이 좋다.

가장 큰 줄기는 다음 네 가지다.

| 축 | 질문 | 연결되는 단원 |
|---|---|---|
| 메모리 | 이 객체나 값은 어디에 저장되고 누가 해제하는가? | 포인터, 동적 할당, smart pointer, stack/heap |
| 타입 | 이 문법에서 실제 타입은 무엇이고 어떤 변환이 일어나는가? | 참조, const, enum class, template, STL |
| 호출 | 이 코드는 어떤 함수 호출로 해석되는가? | 함수 포인터, operator overload, virtual function, lambda |
| 범위 | 이 반복/탐색은 어디서 시작해 어디 직전까지 처리하는가? | iterator, STL algorithm, erase-remove |

시험장에서 코드를 볼 때는 다음 순서로 읽는다.

1. 객체가 만들어지는 지점과 사라지는 지점을 찾는다.
2. 포인터인지 참조인지 값 복사인지 확인한다.
3. 함수 호출이 일반 함수, 멤버 함수, 연산자 함수, 가상 함수, 템플릿 인스턴스 중 무엇인지 본다.
4. STL 코드라면 `begin()`과 `end()` 범위, 반환 iterator, size 변화 여부를 확인한다.

## 2. C와 C++ 기본 문법

C는 절차적 언어에 가깝고, C++은 C 문법을 기반으로 객체지향, 제네릭 프로그래밍, RAII를 추가한 언어다.

| 구분 | C | C++ |
|---|---|---|
| 문자열 | `char*`, `char[]` 중심 | `std::string` 사용 가능 |
| 입출력 | `printf`, `scanf` | `std::cout`, `std::cin` |
| 동적 할당 | `malloc`, `free` | `new/delete`, smart pointer |
| 사용자 정의 타입 | `struct` 중심 | `class`, 생성자, 소멸자, 접근 지정자 |
| 코드 재사용 | 함수, 매크로 | 함수, 클래스, 상속, 템플릿 |

기본 C 프로그램은 다음 요소를 가진다.

```cpp
#include <stdio.h>

int main() {
    int x = 10;
    printf("%d\n", x);
    return 0;
}
```

C++에서는 다음처럼 쓸 수 있다.

```cpp
#include <iostream>

int main() {
    int x = 10;
    std::cout << x << "\n";
    return 0;
}
```

컴파일 관점에서는 전처리, 컴파일, 링크의 흐름을 기억한다.

```text
source file -> preprocessing -> compilation -> object file -> linking -> executable
```

헤더에는 선언을 두고, `.cpp`에는 구현을 두는 방식이 일반적이다. 다만 템플릿은 예외적으로 정의를 헤더에 두는 경우가 많다. 컴파일러가 템플릿에 실제 타입을 넣어 코드를 생성하려면 정의를 볼 수 있어야 하기 때문이다.

## 3. 메모리 영역과 동적 할당

프로그램 메모리는 보통 Code, Data, Stack, Heap 영역으로 설명한다.

| 영역 | 저장 내용 | 수명 |
|---|---|---|
| Code | 실행 명령어 | 프로그램 전체 |
| Data/BSS | 전역 변수, static 변수 | 프로그램 전체 |
| Stack | 지역 변수, 매개변수, 반환 주소 | 함수 호출 동안 |
| Heap | 동적 할당 객체 | 직접 해제하거나 소유 객체가 해제할 때까지 |

Stack은 함수 호출과 함께 자동으로 관리된다.

```cpp
void f() {
    int x = 10; // stack
}
```

Heap은 실행 중 필요한 크기를 동적으로 확보한다.

```cpp
int* p = new int(10);
delete p;
```

C 방식 동적 할당은 다음과 같다.

```cpp
int* p = (int*)malloc(sizeof(int) * 5);
free(p);
```

`malloc/free`와 `new/delete`의 핵심 차이는 생성자/소멸자 호출 여부다.

| 구분 | `malloc/free` | `new/delete` |
|---|---|---|
| 언어 | C library | C++ operator |
| 반환 | `void*` | 실제 타입 포인터 |
| 생성자 | 호출 안 함 | 호출함 |
| 소멸자 | 호출 안 함 | 호출함 |
| 실패 처리 | `nullptr` 가능 | 기본적으로 예외 |

객체를 다룰 때는 `new/delete`가 C++스럽고, 더 좋은 방향은 smart pointer와 RAII를 쓰는 것이다.

## 4. RAII와 smart pointer

RAII(Resource Acquisition Is Initialization)는 **자원 획득을 객체 초기화에 묶고, 자원 해제를 객체 소멸자에 맡기는 방식**이다.

```cpp
{
    std::unique_ptr<int> p = std::make_unique<int>(10);
} // scope 종료 시 자동 해제
```

스마트 포인터 선택 기준은 다음과 같다.

| 포인터 | 소유권 | 복사 | 대표 상황 |
|---|---|---|---|
| `std::unique_ptr` | 단독 소유 | 불가 | 한 객체가 명확히 한 자원을 소유 |
| `std::shared_ptr` | 공유 소유 | 가능 | 여러 객체가 같은 자원 공유 |
| `std::weak_ptr` | 비소유 관찰 | 가능 | `shared_ptr` 순환 참조 방지 |

`shared_ptr`는 reference counting으로 수명을 관리한다. 마지막 `shared_ptr`가 사라질 때 객체가 해제된다.

```cpp
auto p1 = std::make_shared<int>(10);
auto p2 = p1; // reference count 증가
```

하지만 서로가 서로를 `shared_ptr`로 잡으면 reference count가 0이 되지 않는 순환 참조가 생긴다. 이때 한쪽 연결을 `weak_ptr`로 바꾸면 소유권 순환을 끊을 수 있다.

## 5. 포인터, 참조, const

포인터는 주소를 저장하는 변수이고, 참조는 기존 객체의 별칭이다.

| 구분 | 포인터 | 참조 |
|---|---|---|
| null 가능성 | 가능 | 일반적으로 불가 |
| 재지정 | 가능 | 불가 |
| 사용 문법 | `*p`, `p->x` | 원래 변수처럼 사용 |
| 의미 | 대상을 가리킴 | 대상의 별칭 |

함수 인자 전달은 세 가지로 비교한다.

```cpp
void byValue(Student s);          // 복사
void byPointer(Student* s);       // 주소 전달, null 가능
void byReference(Student& s);     // 별칭 전달, null 없음
void readOnly(const Student& s);  // 복사 없이 읽기 전용
```

큰 객체를 읽기만 할 때는 `const T&`가 자주 쓰인다.

```cpp
void printStudent(const Student& s) {
    std::cout << s.name;
}
```

`const` 포인터 문법은 위치로 읽는다.

| 형태 | 의미 |
|---|---|
| `const int* p` | 가리키는 값을 수정할 수 없음 |
| `int* const p` | 포인터 변수 자체를 다른 주소로 바꿀 수 없음 |
| `const int* const p` | 값도 못 바꾸고 주소도 못 바꿈 |

## 6. 구조체와 클래스

C의 `struct`는 데이터를 묶는 데 주로 쓰지만, C++의 `struct`와 `class`는 멤버 함수, 생성자, 소멸자도 가질 수 있다. 차이는 기본 접근 지정자다.

| 구분 | 기본 접근 |
|---|---|
| `struct` | `public` |
| `class` | `private` |

클래스는 데이터를 감추고 public interface를 통해 접근하게 만든다.

```cpp
class Student {
private:
    int age;
    std::string name;

public:
    Student(int age, std::string name)
        : age(age), name(std::move(name)) {}

    void greet() const {
        std::cout << name << "\n";
    }
};
```

생성자 초기화 리스트는 멤버를 생성 시점에 초기화한다.

```cpp
Student(int age, std::string name)
    : age(age), name(std::move(name)) {}
```

중요한 점은 **초기화 순서는 초기화 리스트에 적은 순서가 아니라, 클래스 안에 멤버가 선언된 순서**라는 것이다.

## 7. 복사 생성자와 복사 대입

객체 복사 상황은 두 가지다.

| 상황 | 예 | 호출 |
|---|---|---|
| 새 객체를 기존 객체로 생성 | `Student b = a;` | 복사 생성자 |
| 이미 있는 객체에 대입 | `b = a;` | 복사 대입 연산자 |

동적 메모리를 직접 소유하는 클래스는 기본 복사만으로 위험할 수 있다. 포인터 값만 복사되면 두 객체가 같은 메모리를 가리키고, double delete가 생길 수 있다.

복사 대입 연산자는 보통 자기 대입을 검사하고, 기존 자원을 정리한 뒤 깊은 복사를 수행한다.

```cpp
Buffer& operator=(const Buffer& other) {
    if (this == &other) return *this;

    delete[] data;
    size = other.size;
    data = new int[size];

    for (int i = 0; i < size; ++i) {
        data[i] = other.data[i];
    }

    return *this;
}
```

`return *this;`는 `a = b = c` 같은 체이닝을 가능하게 하고, 현재 객체 자신을 반환한다는 의미를 드러낸다.

## 8. 표준 입출력과 파일 디스크립터

C++의 기본 입출력은 `iostream`을 사용한다.

| C++ 스트림 | 의미 | POSIX file descriptor |
|---|---|---|
| `std::cin` | 표준 입력 | 0 |
| `std::cout` | 표준 출력 | 1 |
| `std::cerr` | 표준 에러 | 2 |
| `std::clog` | 로그용 표준 에러 | 2 |

`std::endl`은 줄바꿈과 flush를 함께 수행한다.

```cpp
std::cout << "hello" << std::endl;
```

반면 `"\n"`은 줄바꿈 문자만 출력한다.

```cpp
std::cout << "hello\n";
```

시험에서는 `stdout`과 `stderr`를 구분하는 문제가 자주 나온다.

```bash
./program > out.txt 2> err.txt
```

이 명령은 정상 출력은 `out.txt`, 에러 출력은 `err.txt`로 보낸다.

`stdin`에 남은 개행 때문에 `getline`이 바로 빈 문자열을 읽는 문제도 중요하다.

```cpp
int age;
std::string name;

std::cin >> age;
std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
std::getline(std::cin, name);
```

## 9. enum과 enum class

C-style enum은 이름이 바깥 scope로 퍼지고, 정수로 암시 변환될 수 있다.

```cpp
enum Color { Red, Green, Blue };

int x = Red; // 가능
```

`enum class`는 더 안전하다.

```cpp
enum class Color { Red, Green, Blue };

Color c = Color::Red;
// int x = c; // 오류
```

비트 플래그를 `enum class`로 만들면 연산자를 직접 정의해야 한다.

```cpp
enum class Permission {
    Read = 1,
    Write = 2,
    Execute = 4
};
```

`enum class`는 암시적으로 정수 연산을 허용하지 않으므로, `operator|` 같은 연산자를 따로 제공해야 자연스럽게 쓸 수 있다.

## 10. 연산자 오버로딩

연산자 오버로딩은 사용자 정의 타입도 자연스러운 연산 문법으로 사용할 수 있게 한다.

멤버 연산자에서는 왼쪽 피연산자가 항상 `*this`다.

```cpp
Complex operator+(const Complex& rhs) const;
// z1 + z2 -> z1.operator+(z2)
```

비멤버 연산자는 두 피연산자를 모두 매개변수로 받는다.

```cpp
Complex operator+(const Complex& lhs, const Complex& rhs);
// z1 + z2 -> operator+(z1, z2)
```

왼쪽 피연산자가 기본 타입일 수 있으면 비멤버 연산자가 자연스럽다.

```cpp
Complex operator+(double lhs, const Complex& rhs);
// 1.0 + z
```

반드시 멤버 함수여야 하는 연산자도 있다.

| 연산자 | 이유 |
|---|---|
| `operator=` | 대입 대상이 현재 객체여야 함 |
| `operator[]` | 객체의 첨자 접근 |
| `operator()` | 함수 호출 형태 |
| `operator->` | 멤버 접근 연산 |

출력 연산자는 보통 비멤버로 만든다.

```cpp
std::ostream& operator<<(std::ostream& os, const Complex& c) {
    os << c.real() << " + " << c.imag() << "i";
    return os;
}
```

반환 타입이 `std::ostream&`인 이유는 `std::cout << a << b`처럼 체이닝해야 하기 때문이다.

## 11. 함수 포인터, 콜백, 람다

함수 포인터는 함수의 주소를 저장한다.

```cpp
int add(int a, int b) { return a + b; }

int (*op)(int, int) = add;
std::cout << op(3, 4);
```

콜백은 “실행할 함수를 인자로 전달하고, 호출 시점은 받은 쪽이 정하는 구조”다.

```cpp
int apply(int a, int b, int (*op)(int, int)) {
    return op(a, b);
}
```

`qsort`는 C 스타일 콜백 정렬의 대표 예다.

```cpp
int cmp_asc(const void* a, const void* b) {
    return *(const int*)a - *(const int*)b;
}
```

현대 C++에서는 `std::sort`와 람다가 더 자연스럽다.

```cpp
std::sort(v.begin(), v.end(),
    [](int a, int b) {
        return a > b;
    });
```

람다는 이름 없는 함수 객체에 가깝다.

```cpp
[capture](parameters) -> return_type { body }
```

외부 변수를 쓰려면 capture가 필요하다.

```cpp
int threshold = 30;

auto it = std::find_if(v.begin(), v.end(),
    [threshold](int x) {
        return x > threshold;
    });
```

## 12. 상속

상속은 공통 속성과 동작을 기본 클래스에 두고, 파생 클래스가 이를 확장하는 구조다.

```cpp
class Animal {
public:
    void eat();
};

class Dog : public Animal {
public:
    void bark();
};
```

상속 접근 지정자는 기본 클래스의 public/protected 멤버가 파생 클래스 밖에서 어떻게 보이는지를 바꾼다.

| 상속 방식 | public 멤버 | protected 멤버 |
|---|---|---|
| `public` | public 유지 | protected 유지 |
| `protected` | protected로 변경 | protected 유지 |
| `private` | private로 변경 | private로 변경 |

생성자/소멸자 순서도 중요하다.

```text
생성: 기본 클래스 -> 멤버 객체 -> 파생 클래스
소멸: 파생 클래스 -> 멤버 객체 -> 기본 클래스
```

파생 클래스 생성자는 기본 클래스 생성자를 초기화 리스트에서 명시할 수 있다.

```cpp
Derived(int x, int y)
    : Base(x), y(y) {}
```

## 13. 다형성

다형성은 같은 인터페이스로 여러 실제 타입의 동작을 다르게 실행하는 능력이다.

```cpp
class Shape {
public:
    virtual double area() const = 0;
    virtual ~Shape() = default;
};

class Circle : public Shape {
public:
    double area() const override;
};
```

기본 클래스 포인터나 참조로 파생 클래스 객체를 다룰 때, `virtual` 함수는 런타임에 실제 객체 타입을 기준으로 호출된다.

```cpp
Shape* s = new Circle();
s->area(); // Circle::area()
delete s;
```

기본 클래스 소멸자는 다형적으로 사용할 경우 반드시 `virtual`이어야 한다.

```cpp
virtual ~Shape() = default;
```

`override`는 파생 클래스 함수가 실제로 기반 클래스 가상 함수를 재정의하는지 컴파일러가 확인하게 한다.

```cpp
double area() const override;
```

순수 가상 함수가 하나라도 있으면 추상 클래스가 되고, 직접 객체를 만들 수 없다.

## 14. 템플릿

템플릿은 타입이나 값을 매개변수로 받아 컴파일 시점에 코드를 생성하는 문법이다.

```cpp
template <typename T>
T max_value(T a, T b) {
    return (a > b) ? a : b;
}
```

호출 시 실제 타입으로 인스턴스화된다.

```cpp
max_value(3, 5);       // T = int
max_value(1.2, 4.5);   // T = double
```

클래스 템플릿은 자료구조를 타입에 독립적으로 만든다.

```cpp
template <typename T>
class Box {
private:
    T value;
public:
    explicit Box(T value) : value(value) {}
    T get() const { return value; }
};
```

비타입 템플릿 매개변수는 타입이 아니라 값을 템플릿 인자로 받는다.

```cpp
template <typename T, int N>
class Vector {
private:
    T data[N];
};
```

여기서 `Vector<int, 3>`과 `Vector<int, 4>`는 서로 다른 타입이다.

템플릿은 보통 헤더에 정의를 둔다. 컴파일러가 실제 타입을 넣어 코드를 만들 때 함수 본문을 볼 수 있어야 하기 때문이다.

## 15. STL 컨테이너

STL은 컨테이너, iterator, algorithm, 함수 객체/람다가 연결된 구조다.

```text
container -> iterator range -> algorithm -> predicate/comparator
```

주요 컨테이너 선택 기준은 다음과 같다.

| 컨테이너 | 특징 | 대표 사용 |
|---|---|---|
| `vector` | 연속 메모리, 임의 접근 O(1) | 기본 선택 |
| `array` | 고정 크기 배열 | 컴파일 타임 크기 고정 |
| `list` | 이중 연결 리스트 | 위치를 알고 있을 때 중간 삽입/삭제 |
| `set` | 중복 없는 정렬 집합 | 방문 여부, 중복 제거 |
| `map` | key-value 저장 | 빈도 카운팅, 사전 |

`vector`에서 `size`와 `capacity`는 다르다.

```cpp
std::vector<int> v;
v.reserve(1000); // capacity 확보, size는 그대로
v.resize(10);    // 실제 원소 개수를 10으로 변경
```

`end()`는 마지막 원소가 아니라 마지막 원소 다음 위치다.

```cpp
for (auto it = v.begin(); it != v.end(); ++it) {
    std::cout << *it;
}
```

iterator 순회에서 `++it`를 선호하는 이유는 `it++`가 증가 전 상태를 반환해야 해서 불필요한 복사를 만들 수 있기 때문이다.

## 16. STL 알고리즘

`std::find`는 iterator 범위를 순차 탐색한다.

```cpp
auto it = std::find(v.begin(), v.end(), 30);
```

반면 `set.find()`나 `map.find()`는 컨테이너 내부 구조를 이용한다.

```cpp
auto it = freq.find("apple");
```

`std::remove`는 실제 삭제를 하지 않는다.

```cpp
auto new_end = std::remove(v.begin(), v.end(), 2);
v.erase(new_end, v.end());
```

`std::remove`만 호출하면 `size`는 줄지 않는다. 제거 대상이 아닌 원소를 앞쪽으로 모으고, 유효 범위의 끝 iterator를 반환할 뿐이다.

`max_element`와 비교 함수도 자주 헷갈린다.

```cpp
auto max_it = std::max_element(freq.begin(), freq.end(),
    [](const auto& a, const auto& b) {
        return a.second < b.second;
    });
```

여기서 비교식은 “a가 b보다 작다”를 정의한다. 따라서 `max_element`는 `second`가 가장 큰 원소를 찾는다.

정렬/검색/집계 알고리즘은 다음처럼 정리한다.

| 알고리즘 | 핵심 |
|---|---|
| `sort` | 전체 정렬 |
| `stable_sort` | 같은 기준값의 기존 상대 순서 유지 |
| `partial_sort` | 앞 N개만 정렬 |
| `nth_element` | n번째 위치만 제자리로 이동 |
| `binary_search` | 정렬된 범위에서 존재 여부 확인 |
| `lower_bound` | key 이상인 첫 위치 |
| `upper_bound` | key 초과인 첫 위치 |
| `accumulate` | 초기값부터 범위를 누적 |
| `transform` | 원소 변환 |
| `copy_if` | 조건을 만족하는 원소만 복사 |

## 17. 과제 연결 포인트

과제 자료는 강의 개념을 시험 문제식으로 바꿔 보는 데 좋다.

| 과제 | 시험 연결 |
|---|---|
| Operator Overloading | 멤버/비멤버 연산자, Python 특수 메서드 비교 |
| Code/Data/Stack/Heap | 메모리 영역, stack/heap 확장 방향, 단편화 |
| Smart Pointer | RAII, reference counting, 순환 참조, GC 비교 |
| Standard I/O and File Descriptor | `stdin/stdout/stderr`, redirection, pipe |

Python 비교가 나오는 경우 다음 기준을 잡는다.

| C++ | Python |
|---|---|
| `operator+` | `__add__`, `__radd__` |
| `operator+=` | `__iadd__` |
| `operator[]` | `__getitem__`, `__setitem__` |
| `operator()` | `__call__` |
| `operator<<` | `__str__`, `__repr__`와 비교 가능 |
| `operator bool()` | `__bool__`, `__len__` |

C++은 어느 함수가 어떤 피연산자를 받는지와 반환 타입을 직접 설계하고, Python은 객체 프로토콜의 이름을 통해 동작을 제공한다.

## 18. 시험 실수 방지표

| 헷갈리는 부분 | 틀리기 쉬운 생각 | 올바른 기준 |
|---|---|---|
| `reserve` | size를 늘린다 | capacity만 확보한다 |
| `resize` | 공간만 확보한다 | 실제 원소 개수를 바꾼다 |
| `end()` | 마지막 원소다 | 마지막 원소 다음 위치다 |
| `std::remove` | 원소를 실제 삭제한다 | 유효 범위 끝을 반환할 뿐 size는 그대로다 |
| `erase` | capacity를 줄인다 | size를 줄이고 capacity는 보통 유지된다 |
| `std::find` | 모든 컨테이너에서 최적이다 | 순차 탐색이다 |
| `.find()` | vector에서도 쓴다 | `set`, `map` 등 전용 탐색 멤버다 |
| `stable_sort` | 그냥 느린 sort다 | 같은 기준값의 상대 순서를 유지한다 |
| `shared_ptr` | 항상 안전하다 | 순환 참조는 `weak_ptr`가 필요하다 |
| `virtual` 소멸자 | 선택 사항이다 | 다형적 삭제에는 사실상 필수다 |
| 템플릿 | 런타임에 타입을 고른다 | 컴파일 시점에 인스턴스화된다 |
| `enum class` | 정수처럼 바로 연산된다 | 강한 타입이라 명시 변환/연산자 정의가 필요하다 |

## 마지막 핵심 정리

| 개념 | 한 줄 정리 |
|---|---|
| C++ 객체 | 데이터와 동작, 생성과 소멸까지 함께 설계한다 |
| RAII | 자원 해제를 객체 수명에 묶는다 |
| 참조 | null 없는 별칭으로 생각한다 |
| `const T&` | 큰 객체를 복사 없이 읽기 전용으로 받는다 |
| 연산자 오버로딩 | 연산자를 함수 호출로 설계한다 |
| 함수 포인터 | 함수 주소를 저장하고 간접 호출한다 |
| 람다 | 즉석 함수 객체다 |
| 상속 | 공통 인터페이스와 확장 관계를 만든다 |
| 다형성 | `virtual`로 런타임 동적 바인딩을 만든다 |
| 템플릿 | 타입/값을 매개변수로 받는 컴파일 타임 코드 생성 도구다 |
| STL | 컨테이너와 iterator 범위에 알고리즘을 적용하는 구조다 |

## Study Guide

1. 먼저 메모리와 객체 수명부터 정리한다. `new/delete`, RAII, smart pointer, stack/heap을 모르면 뒤쪽 개념도 흔들린다.
2. 그다음 클래스 문법을 본다. 생성자, 소멸자, 복사 생성자, 복사 대입, `this`, `const` 멤버 함수가 핵심이다.
3. 연산자 오버로딩과 함수 포인터는 “코드가 실제로 어떤 함수 호출로 바뀌는가”를 기준으로 읽는다.
4. 상속과 다형성은 생성/소멸 순서, 접근 지정자, `virtual`, `override`, 가상 소멸자를 반드시 묶어서 본다.
5. 템플릿과 STL은 시험 직전 코드 패턴을 많이 보는 것이 좋다. 특히 iterator 반환값, `end()` 비교, erase-remove 관용구를 손에 익힌다.

## 복습 질문

<details>
<summary>1. Stack과 Heap의 가장 큰 차이는 무엇인가?</summary>

답변: Stack은 함수 호출과 함께 자동으로 관리되는 영역이고, Heap은 실행 중 동적으로 할당되는 영역이다. Stack 객체는 scope를 벗어나면 자동으로 정리되지만, Heap 객체는 직접 해제하거나 RAII 객체가 해제해야 한다.

</details>

<details>
<summary>2. `malloc/free`와 `new/delete`의 핵심 차이는 무엇인가?</summary>

답변: <code>malloc/free</code>는 메모리 블록만 할당/해제하고 생성자와 소멸자를 호출하지 않는다. <code>new/delete</code>는 C++ 객체의 생성자와 소멸자를 호출한다.

</details>

<details>
<summary>3. `const T&`를 함수 매개변수로 자주 쓰는 이유는 무엇인가?</summary>

답변: 큰 객체를 복사하지 않고 받을 수 있고, 함수 안에서 원본을 수정하지 않겠다는 약속도 함께 표현할 수 있기 때문이다.

</details>

<details>
<summary>4. 복사 생성자와 복사 대입 연산자는 언제 다르게 호출되는가?</summary>

답변: 새 객체를 기존 객체로 만들 때는 복사 생성자가 호출되고, 이미 존재하는 객체에 값을 대입할 때는 복사 대입 연산자가 호출된다.

</details>

<details>
<summary>5. `return *this;`를 대입 연산자에서 반환하는 이유는 무엇인가?</summary>

답변: 현재 객체 자신을 반환해 <code>a = b = c</code> 같은 체이닝을 가능하게 하고, 불필요한 복사를 줄이기 위해 보통 참조로 반환한다.

</details>

<details>
<summary>6. `std::endl`과 `"\n"`의 차이는 무엇인가?</summary>

답변: 둘 다 줄바꿈을 만들지만, <code>std::endl</code>은 출력 버퍼를 flush한다. <code>"\n"</code>은 줄바꿈 문자만 출력한다.

</details>

<details>
<summary>7. 멤버 연산자와 비멤버 연산자의 가장 중요한 차이는 무엇인가?</summary>

답변: 멤버 연산자는 왼쪽 피연산자가 항상 <code>*this</code>다. 비멤버 연산자는 두 피연산자를 모두 매개변수로 받으므로, 왼쪽 피연산자가 기본 타입인 경우에도 대응하기 쉽다.

</details>

<details>
<summary>8. <code>operator&lt;&lt;</code>를 보통 비멤버 함수로 만드는 이유는 무엇인가?</summary>

답변: <code>std::cout &lt;&lt; obj</code>에서 왼쪽 피연산자는 <code>std::ostream</code>이다. 사용자 정의 타입의 멤버 함수로는 <code>std::ostream</code>을 수정할 수 없으므로 보통 비멤버 연산자로 만든다.

</details>

<details>
<summary>9. 함수 포인터와 람다는 어떤 공통점이 있는가?</summary>

답변: 둘 다 어떤 동작을 다른 함수나 알고리즘에 전달할 수 있다. 함수 포인터는 함수 주소를 전달하고, 람다는 그 자리에서 정의한 함수 객체를 전달한다.

</details>

<details>
<summary>10. 기본 클래스 소멸자를 `virtual`로 두어야 하는 경우는 언제인가?</summary>

답변: 기본 클래스 포인터로 파생 클래스 객체를 삭제할 가능성이 있을 때다. 소멸자가 가상 함수가 아니면 파생 클래스 소멸자가 호출되지 않을 수 있다.

</details>

<details>
<summary>11. 템플릿이 런타임 다형성과 다른 점은 무엇인가?</summary>

답변: 템플릿은 컴파일 시점에 실제 타입을 넣어 코드를 생성한다. 런타임 다형성은 기본 클래스 포인터/참조와 virtual function을 통해 실행 중 실제 객체 타입에 맞는 함수를 호출한다.

</details>

<details>
<summary>12. `std::vector`에서 `reserve`와 `resize`의 차이는 무엇인가?</summary>

답변: <code>reserve</code>는 capacity만 확보하고 size는 바꾸지 않는다. <code>resize</code>는 실제 원소 개수인 size를 바꾼다.

</details>

<details>
<summary>13. iterator의 `end()`는 무엇을 가리키는가?</summary>

답변: 마지막 원소가 아니라 마지막 원소의 다음 위치를 가리킨다. 따라서 <code>*end()</code>는 하면 안 되고, 보통 <code>it != end()</code> 조건으로 반복을 끝낸다.

</details>

<details>
<summary>14. `std::remove`만 호출하면 왜 vector 크기가 줄지 않는가?</summary>

답변: <code>std::remove</code>는 제거 대상이 아닌 원소를 앞쪽으로 모으고 유효 범위 끝 iterator를 반환할 뿐이다. 실제 size를 줄이려면 <code>erase</code>를 이어서 호출해야 한다.

</details>

<details>
<summary>15. `std::find`와 `.find()`는 왜 다른가?</summary>

답변: <code>std::find</code>는 iterator 범위를 앞에서부터 순차 탐색하는 범용 알고리즘이다. <code>.find()</code>는 <code>set</code>, <code>map</code> 같은 컨테이너가 내부 구조를 이용해 제공하는 전용 탐색 함수다.

</details>

<details>
<summary>16. <code>std::max_element</code>에서 비교식 <code>a.second &lt; b.second</code>를 쓰면 왜 최대 빈도가 나오는가?</summary>

답변: 비교식은 “a가 b보다 작다”를 정의한다. <code>a.second &lt; b.second</code>를 기준으로 작고 큼을 판단하면, <code>max_element</code>는 <code>second</code>가 가장 큰 원소를 최대 원소로 선택한다.

</details>

<details>
<summary>17. `enum class`가 C-style enum보다 안전한 이유는 무엇인가?</summary>

답변: <code>enum class</code>는 이름이 enum scope 안에 묶이고, 정수로 암시 변환되지 않는다. 그래서 이름 충돌과 의도하지 않은 정수 연산을 줄일 수 있다.

</details>

<details>
<summary>18. `shared_ptr`의 순환 참조는 왜 문제가 되는가?</summary>

답변: 서로를 <code>shared_ptr</code>로 소유하면 reference count가 0이 되지 않아 객체가 해제되지 않는다. 이때 한쪽 참조를 <code>weak_ptr</code>로 바꾸면 소유권 순환을 끊을 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C 프로그래밍 소개.pdf" | relative_url }}" target="_blank" rel="noopener">C 프로그래밍 소개.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C 프로그래밍 개요.pdf" | relative_url }}" target="_blank" rel="noopener">C 프로그래밍 개요.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C_구조체.pdf" | relative_url }}" target="_blank" rel="noopener">C_구조체.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/클래스 (Class) 입문.pdf" | relative_url }}" target="_blank" rel="noopener">클래스 (Class) 입문.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C에서 C++로 넘어가기.pdf" | relative_url }}" target="_blank" rel="noopener">C에서 C++로 넘어가기.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C_동적할당.pdf" | relative_url }}" target="_blank" rel="noopener">C_동적할당.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/(심화) C++ 포인터.pdf" | relative_url }}" target="_blank" rel="noopener">(심화) C++ 포인터.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 표준 스트림 (updated).pdf" | relative_url }}" target="_blank" rel="noopener">C++ 표준 스트림 (updated).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/참조 (Reference).pdf" | relative_url }}" target="_blank" rel="noopener">참조 (Reference).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/열거형 (Enum).pdf" | relative_url }}" target="_blank" rel="noopener">열거형 (Enum).pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 오버로딩.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 오버로딩.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 함수포인터.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 함수포인터.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 상속.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 상속.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 다형성.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 다형성.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 템플릿.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 템플릿.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ STL.pdf" | relative_url }}" target="_blank" rel="noopener">C++ STL.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Operator Overloading.pdf" | relative_url }}" target="_blank" rel="noopener">Operator Overloading.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Code Data Stack Heap.pdf" | relative_url }}" target="_blank" rel="noopener">Code Data Stack Heap.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/Smart Pointer, RAII, Reference Counting.pdf" | relative_url }}" target="_blank" rel="noopener">Smart Pointer, RAII, Reference Counting.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/assignment/cpp/stdin, stdout, stderr, File Descriptor.pdf" | relative_url }}" target="_blank" rel="noopener">stdin, stdout, stderr, File Descriptor.pdf</a></li>
</ul>
