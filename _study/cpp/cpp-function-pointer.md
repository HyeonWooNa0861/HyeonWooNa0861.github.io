---
layout: default
title: "C++ Function Pointers"
course: "C++"
topic: "함수 포인터와 콜백"
order: 8
---

# C++ Function Pointers

Source PDF: `C++ 함수포인터.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 함수 포인터 | 함수를 변수처럼 가리키고 호출할 수 있는가? |
| 2 | 콜백 함수 | 함수를 다른 함수에 전달하면 무엇이 달라지는가? |
| 3 | `qsort` | 정렬 기준을 함수 포인터로 어떻게 바꾸는가? |
| 4 | `typedef`, `using` | 복잡한 함수 포인터 타입을 어떻게 읽기 쉽게 만드는가? |
| 5 | 클래스와 `qsort` | 객체 배열도 콜백으로 정렬할 수 있는가? |
| 6 | `std::sort`와 `operator<` | C++ 스타일 정렬 기준은 어떻게 정의하는가? |
| 7 | 람다 비교자 | 정렬 기준을 그 자리에서 바꿀 수 있는가? |
| 8 | 훅(Hook) | 특정 시점에 사용자 함수를 끼워 넣는 구조는 무엇인가? |
| 9 | 함수 포인터와 가상 함수 | 수동 디스패치와 `virtual`은 어떤 관계인가? |

## 1. 함수 포인터란?

함수 포인터는 **함수의 주소를 저장하는 포인터**다. 데이터 포인터가 변수의 주소를 저장하듯, 함수 포인터는 특정 함수의 시작 주소를 저장하고 나중에 그 함수를 간접 호출할 수 있다.

```cpp
int add(int a, int b) { return a + b; }
int sub(int a, int b) { return a - b; }

int (*op)(int, int);

op = add;
printf("%d\n", op(3, 4)); // 7

op = sub;
printf("%d\n", op(3, 4)); // -1
```

함수 포인터 선언은 다음 구조로 읽는다.

```cpp
반환타입 (*이름)(매개변수 타입...)
```

예를 들어:

```cpp
int (*op)(int, int);
```

는 “`int`, `int` 두 인자를 받고 `int`를 반환하는 함수를 가리키는 포인터 `op`”라는 뜻이다.

## 2. 데이터 포인터와 함수 포인터 비교

| 구분 | 데이터 포인터 | 함수 포인터 |
|---|---|---|
| 선언 예 | `int* p` | `int (*fp)(int)` |
| 대입 | `p = &x` | `fp = func` |
| 사용 | `*p` | `fp(arg)` 또는 `(*fp)(arg)` |
| 목적 | 데이터 접근 | 함수 간접 호출 |

함수 이름은 함수 주소처럼 사용할 수 있으므로 보통 `op = add;`처럼 `&`를 생략할 수 있다.

```cpp
int (*fp)(int, int) = add;
```

## 3. 콜백 함수

콜백 함수는 **어떤 작업을 할지 함수로 전달하고, 실제 호출 시점은 호출받은 쪽이 결정하는 함수**다.

콜백의 핵심은 다음이다.

> 호출할 함수 자체를 인자로 전달하여, “무엇을 할지”와 “언제 호출할지”를 분리한다.

활용 예시는 다음과 같다.

| 상황 | 콜백 역할 |
|---|---|
| `qsort` | 정렬 기준을 정하는 비교 함수 |
| GUI 이벤트 | 버튼 클릭 시 실행할 함수 |
| 비동기 I/O | 작업 완료 후 호출할 함수 |
| 알고리즘 라이브러리 | 각 원소에 적용할 처리 함수 |

## 4. 함수 포인터를 매개변수로 전달하기

다음 예제에서 `apply` 함수는 바뀌지 않는다. 대신 세 번째 인자로 전달하는 콜백 함수만 바꾸면 동작이 달라진다.

```cpp
int add(int a, int b) { return a + b; }
int mul(int a, int b) { return a * b; }

int apply(int a, int b, int (*op)(int, int)) {
    return op(a, b);
}

printf("%d\n", apply(3, 4, add)); // 7
printf("%d\n", apply(3, 4, mul)); // 12
```

흐름은 다음과 같다.

| 호출 | 내부 동작 | 결과 |
|---|---|---|
| `apply(3, 4, add)` | `op = add`, `add(3, 4)` 호출 | `7` |
| `apply(3, 4, mul)` | `op = mul`, `mul(3, 4)` 호출 | `12` |

즉, `apply`의 코드는 그대로 두고 전달하는 함수만 바꿔서 계산 방식을 교체한다.

## 5. `qsort`와 콜백 기반 정렬

C 표준 라이브러리의 `qsort`는 콜백 함수를 이용해 정렬 기준을 외부에서 받는다.

```cpp
#include <cstdlib>

void qsort(
    void* base,
    size_t count,
    size_t size,
    int (*cmp)(const void*, const void*)
);
```

매개변수 의미는 다음과 같다.

| 매개변수 | 의미 |
|---|---|
| `base` | 배열 시작 주소 |
| `count` | 원소 개수 |
| `size` | 원소 하나의 크기 |
| `cmp` | 비교 기준을 정하는 콜백 함수 |

비교 함수의 반환값 규칙은 다음과 같다.

| 반환값 | 의미 | 결과 |
|---|---|---|
| 음수 | `a < b` | `a`를 앞에 둠 |
| 0 | `a == b` | 순서 유지 |
| 양수 | `a > b` | `b`를 앞에 둠 |

예시:

```cpp
int cmp_asc(const void* a, const void* b) {
    return *(int*)a - *(int*)b;
}

int cmp_desc(const void* a, const void* b) {
    return *(int*)b - *(int*)a;
}

int arr[] = { 5, 2, 8, 1, 9 };

qsort(arr, 5, sizeof(int), cmp_asc);  // 1 2 5 8 9
qsort(arr, 5, sizeof(int), cmp_desc); // 9 8 5 2 1
```

`qsort` 내부 로직은 그대로이고, 비교 콜백만 바꾸면 정렬 기준이 달라진다.

## 6. `typedef`로 함수 포인터 읽기 쉽게 만들기

함수 포인터 타입은 문법이 복잡하다.

```cpp
int (*op)(int, int);
int (*table[2])(int, int);
```

`typedef`를 사용하면 타입에 이름을 붙일 수 있다.

```cpp
typedef int (*BinaryOp)(int, int);

BinaryOp op = add;
BinaryOp table[2] = { add, mul };
```

이제 `BinaryOp`는 “`int`, `int`를 받아 `int`를 반환하는 함수 포인터 타입”을 의미한다.

## 7. `using`으로 함수 포인터 읽기 쉽게 만들기

C++11부터는 `using`을 사용해 타입 별칭을 더 읽기 좋게 만들 수 있다.

```cpp
using BinaryOp = int (*)(int, int);
```

`typedef`와 같은 의미지만, 왼쪽에서 오른쪽으로 읽기 쉬운 형태다.

```cpp
using BinaryOp = int (*)(int, int);

int apply(int a, int b, BinaryOp op) {
    return op(a, b);
}

BinaryOp op = add;
BinaryOp table[2] = { add, mul };
```

강의자료의 핵심은 C++에서는 `typedef`보다 `using`이 더 직관적인 타입 별칭 문법이라는 점이다.

## 8. 클래스 배열과 `qsort`

객체 배열도 `qsort`로 정렬할 수 있다. 다만 `qsort`의 비교 함수는 `const void*`를 받기 때문에, 비교 함수 안에서 원래 타입으로 캐스팅해야 한다.

```cpp
class Student {
public:
    char name[20];
    int score;

    Student(const char* _name, int _score)
        : score(_score) {
        strncpy(name, _name, 20);
    }
};
```

점수 기준 내림차순 정렬:

```cpp
int cmp_by_score(const void* a, const void* b) {
    const Student* sa = (const Student*)a;
    const Student* sb = (const Student*)b;

    return sb->score - sa->score;
}
```

이름 기준 오름차순 정렬:

```cpp
int cmp_by_name(const void* a, const void* b) {
    const Student* sa = (const Student*)a;
    const Student* sb = (const Student*)b;

    return strcmp(sa->name, sb->name);
}
```

사용 예:

```cpp
Student arr[] = {
    Student("Alice", 85),
    Student("Bob", 92),
    Student("Carol", 78)
};

qsort(arr, 3, sizeof(Student), cmp_by_score);
qsort(arr, 3, sizeof(Student), cmp_by_name);
```

정렬 함수는 그대로 두고 콜백만 바꾸면 점수순, 이름순처럼 정렬 기준을 교체할 수 있다.

## 9. `std::sort`와 `operator<`

C++의 `std::sort`는 C의 `qsort`보다 타입 안전하고 C++ 객체와 잘 맞는다. 기본적으로 `std::sort(arr, arr + n)`은 원소 타입의 `<` 연산자를 사용해 정렬한다.

`Student` 객체를 점수 기준으로 정렬하려면 `operator<`를 정의할 수 있다.

```cpp
#include <algorithm>
#include <cstring>

class Student {
public:
    char name[20];
    int score;

    Student(const char* _name, int _score)
        : score(_score) {
        strncpy(name, _name, 20);
    }

    bool operator<(const Student& o) const {
        return score < o.score;
    }
};
```

사용:

```cpp
Student arr[] = {
    Student("Alice", 85),
    Student("Bob", 92),
    Student("Carol", 78)
};

std::sort(arr, arr + 3);
```

`operator<`는 멤버 함수로도 정의할 수 있고, 전역 함수로도 정의할 수 있다.

```cpp
bool operator<(const Student& a, const Student& b) {
    return a.score < b.score;
}
```

멤버 함수 방식에서는 왼쪽 피연산자가 `*this`가 되고, 전역 함수 방식에서는 두 피연산자를 모두 매개변수로 받는다.

## 10. 람다로 정렬 기준 교체

`std::sort`는 세 번째 인자로 비교 함수를 받을 수 있다. 이때 람다를 사용하면 별도의 비교 함수를 만들지 않고 정렬 기준을 그 자리에서 작성할 수 있다.

점수 기준 오름차순:

```cpp
std::sort(arr, arr + 3,
    [](const Student& a, const Student& b) {
        return a.score < b.score;
    }
);
```

점수 기준 내림차순:

```cpp
std::sort(arr, arr + 3,
    [](const Student& a, const Student& b) {
        return a.score > b.score;
    }
);
```

이름 기준 정렬도 가능하다.

```cpp
std::sort(arr, arr + 3,
    [](const Student& a, const Student& b) {
        return strcmp(a.name, b.name) < 0;
    }
);
```

람다는 “짧은 함수를 그 자리에서 만드는 문법”이다. 정렬 기준처럼 한 번만 쓰는 함수를 따로 이름 붙이지 않아도 되므로 코드가 간결해진다.

## 11. 함수 포인터와 훅(Hook)

훅(Hook)은 특정 처리 전후에 사용자가 지정한 함수를 끼워 넣는 구조다. 호출 시점은 라이브러리나 프레임워크가 결정하고, 무엇을 할지는 사용자가 함수 포인터로 전달한다.

```cpp
using HookFn = void (*)(const char*);

HookFn on_before = nullptr;
HookFn on_after = nullptr;

void process(const char* data) {
    if (on_before) on_before(data);
    printf("처리 중: %s\n", data);
    if (on_after) on_after(data);
}

void log_before(const char* d) {
    printf("[시작] %s\n", d);
}

void log_after(const char* d) {
    printf("[완료] %s\n", d);
}
```

사용:

```cpp
process("A"); // 훅 없이 실행

on_before = log_before;
on_after = log_after;

process("B"); // 훅과 함께 실행
```

흐름은 다음과 같다.

```text
process("A")
→ 처리 중: A

process("B")
→ [시작] B
→ 처리 중: B
→ [완료] B
```

훅은 프로그램의 핵심 로직을 수정하지 않고도 전처리, 후처리, 로깅, 이벤트 처리 등을 끼워 넣을 수 있게 한다.

## 12. 표준 라이브러리의 훅 예시

`std::atexit`는 프로그램 종료 시 호출할 함수를 등록하는 훅이다.

```cpp
#include <cstdlib>
#include <cstdio>

void cleanup1() { printf("cleanup1 실행\n"); }
void cleanup2() { printf("cleanup2 실행\n"); }

int main() {
    std::atexit(cleanup2);
    std::atexit(cleanup1);

    printf("main 종료\n");
}
```

출력 순서는 LIFO 방식이다.

```text
main 종료
cleanup1 실행
cleanup2 실행
```

`std::set_new_handler`는 `operator new`가 메모리 할당에 실패했을 때 호출할 함수를 등록한다.

```cpp
#include <new>
#include <cstdlib>
#include <cstdio>

void on_alloc_fail() {
    printf("메모리 부족!\n");
    std::abort();
}

int main() {
    std::set_new_handler(on_alloc_fail);
}
```

이처럼 훅은 “특정 사건이 발생했을 때 실행할 함수”를 미리 등록하는 방식이다.

## 13. 함수 포인터와 가상 함수

함수 포인터를 객체 안에 멤버로 넣으면, 객체마다 다른 함수를 호출하게 만들 수 있다. 이것은 수동 디스패치 방식이다.

```cpp
struct Animal {
    const char* name;
    void (*speak)(const char*);
};

void dog_speak(const char* n) {
    printf("%s: 왈왈!\n", n);
}

void cat_speak(const char* n) {
    printf("%s: 야옹!\n", n);
}

Animal dog = { "멍멍이", dog_speak };
Animal cat = { "냥냥이", cat_speak };
```

호출:

```cpp
Animal* zoo[] = { &dog, &cat };

for (auto* a : zoo) {
    a->speak(a->name);
}
```

이 방식은 개발자가 직접 함수 포인터를 저장하고 호출한다. C++의 `virtual` 함수는 이런 함수 포인터 기반 디스패치를 언어 차원에서 자동 관리하는 방식이라고 볼 수 있다.

```cpp
class Animal {
public:
    const char* name;

    Animal(const char* _name) : name(_name) {}
    virtual void speak() const = 0;
};

class Dog : public Animal {
public:
    Dog(const char* _name) : Animal(_name) {}
    void speak() const override {
        printf("%s: 왈왈!\n", name);
    }
};
```

`virtual`을 사용하면 함수 포인터를 직접 멤버로 넣지 않아도 실제 객체 타입에 맞는 함수가 호출된다.

## 14. 함수 포인터와 vtable

가상 함수가 있는 클래스에서 컴파일러는 내부적으로 vtable을 만든다. vtable은 가상 함수 주소를 담은 테이블이라고 이해할 수 있다.

| 구분 | 함수 포인터 수동 방식 | `virtual` / vtable 방식 |
|---|---|---|
| 테이블 관리 | 개발자가 직접 관리 | 컴파일러가 자동 생성 |
| 타입 안전성 | 낮음, 잘못된 함수 연결 위험 | 높음, 타입 시스템과 연동 |
| 상속 연동 | 직접 구현해야 함 | 파생 클래스 오버라이딩 자동 반영 |
| 오버헤드 | 포인터 1회 역참조 | 포인터 1회 역참조 |

즉, `virtual` 함수는 함수 포인터 디스패치를 C++ 타입 시스템과 상속 구조에 통합한 것이다. 개발자는 함수 포인터 테이블을 직접 만들지 않고도 런타임 다형성을 사용할 수 있다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| 함수 포인터 | 함수 주소를 저장하고 나중에 호출할 수 있다. |
| 콜백 함수 | 동작을 함수 인자로 전달해 호출 시점과 동작 내용을 분리한다. |
| `qsort` | 비교 함수를 콜백으로 받아 정렬 기준을 바꾼다. |
| `typedef` | 복잡한 함수 포인터 타입에 별칭을 붙인다. |
| `using` | C++11 이후 권장되는 더 읽기 쉬운 타입 별칭 문법이다. |
| 클래스 정렬 | `const void*`를 원래 객체 타입 포인터로 캐스팅해 비교한다. |
| `std::sort` | C++ 객체 정렬에 적합하며 `operator<` 또는 비교자를 사용한다. |
| 람다 비교자 | 정렬 기준을 그 자리에서 간결하게 정의할 수 있다. |
| 훅 | 특정 시점에 실행할 사용자 함수를 함수 포인터로 등록하는 구조다. |
| `std::atexit` | 프로그램 종료 시 실행할 함수를 등록한다. |
| `std::set_new_handler` | 메모리 할당 실패 시 실행할 함수를 등록한다. |
| 가상 함수 | 함수 포인터 디스패치를 타입 시스템과 상속에 통합한 형태다. |
| vtable | 가상 함수 주소를 담는 컴파일러 관리 테이블이다. |

함수 포인터는 C++에서 함수를 데이터처럼 전달하고 저장하기 위한 기본 도구다. 특히 콜백 구조를 이해하면 정렬, 이벤트 처리, 알고리즘 라이브러리처럼 “동작을 외부에서 주입하는 코드”를 설계할 수 있다.

## Study Guide

함수 포인터는 선언 문법이 가장 큰 장벽이다. `int (*op)(int, int)`에서 괄호는 `op`가 함수가 아니라 함수 포인터임을 나타낸다. 이 문법을 읽을 수 있으면 콜백, 훅, 정렬 비교자 같은 예제가 훨씬 자연스럽게 보인다.

이 문서의 핵심 흐름은 "함수를 값처럼 전달한다"는 생각이다. `qsort`는 정렬 알고리즘 자체는 고정해 두고, 비교 기준만 함수 포인터로 받는다. 즉, 알고리즘의 뼈대와 구체적인 판단 기준을 분리하는 방식이다.

후반부의 `virtual`과 vtable은 함수 포인터를 직접 쓰는 방식이 C++의 객체지향 디스패치로 어떻게 발전하는지 보여 준다. 개발자가 수동으로 함수 포인터 테이블을 만들 수도 있지만, C++에서는 상속과 `virtual`을 사용하면 컴파일러가 그 구조를 안전하게 관리해 준다.

## 복습 질문

<details>
<summary>1. `int (*op)(int, int)`는 어떻게 읽어야 하는가?</summary>

답변: `op`는 `int` 두 개를 매개변수로 받고 `int`를 반환하는 함수를 가리키는 함수 포인터다. 괄호가 중요하며, `int *op(int, int)`처럼 쓰면 함수 포인터가 아니라 포인터를 반환하는 함수 선언처럼 해석될 수 있다.

</details>

<details>
<summary>2. 콜백 함수는 왜 유용한가?</summary>

답변: 함수의 실행 시점은 라이브러리나 다른 함수가 관리하되, 실제로 어떤 동작을 할지는 사용자 함수로 전달할 수 있기 때문이다. 예를 들어 `qsort`는 정렬 알고리즘은 고정하지만 비교 기준은 콜백 함수로 바꿀 수 있다.

</details>

<details>
<summary>3. C++의 `virtual` 함수와 함수 포인터는 어떤 관계로 이해할 수 있는가?</summary>

답변: `virtual` 함수는 함수 포인터 기반 디스패치를 C++ 상속과 타입 시스템 안에 통합한 형태로 볼 수 있다. 컴파일러가 vtable에 가상 함수 주소를 저장하고, 런타임에 실제 객체 타입에 맞는 함수를 호출한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 함수포인터.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 함수포인터.pdf</a></li>
</ul>
