---
layout: default
title: "C/C++ 포인터와 메모리"
course: "C++"
topic: "포인터와 동적 할당"
order: 3
---

# C와 C++ 포인터 메모리 통합 요약

원본 자료:

- `C_동적할당.pdf`
- `(심화) C++ 포인터.pdf`

두 자료는 C의 `malloc/free`, C++의 `new/delete`, 포인터 문법, 스마트 포인터가 이어지는 주제를 다룬다. 중복되는 메모리 구조와 포인터 기초 설명은 합치고, C 방식에서 C++ 방식으로 발전하는 흐름으로 정리했다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 메모리 구조 | Stack과 Heap은 어떤 역할을 하는가? |
| 2 | C 동적 할당 | `malloc`, `calloc`, `free`는 어떻게 쓰는가? |
| 3 | C++ 포인터 | `nullptr`, `new`, `delete`는 C와 무엇이 다른가? |
| 4 | const와 포인터 | `const int*`, `int* const`는 어떻게 읽는가? |
| 5 | 클래스와 포인터 | 객체를 동적으로 만들 때 생성자/소멸자는 어떻게 동작하는가? |
| 6 | 스마트 포인터 | RAII로 메모리 해제를 자동화할 수 있는가? |
| 7 | 선택 기준 | `unique_ptr`, `shared_ptr`, `weak_ptr`는 언제 쓰는가? |

## 1. 프로그램 메모리 구조

프로그램 메모리는 일반적으로 다음 영역으로 나눌 수 있다.

| 영역 | 역할 |
|---|---|
| Text/Code | 함수 코드, 기계어 명령 저장 |
| Data/BSS | 전역 변수, static 변수 저장 |
| Stack | 지역 변수, 함수 호출 정보 저장 |
| Heap | 실행 중 동적으로 할당한 메모리 저장 |

Stack은 함수 호출에 따라 자동으로 할당/해제된다. Heap은 프로그래머가 직접 요청해서 얻는 공간이며, 직접 해제해야 한다.

## 2. 정적 할당과 동적 할당

정적 또는 자동 할당은 크기가 컴파일 시점에 정해지는 경우에 적합하다.

```c
int arr[10];
```

동적 할당은 실행 중에 필요한 크기가 결정될 때 사용한다.

```c
int* arr = malloc(sizeof(int) * n);
```

동적 메모리는 바이트 단위로 할당되고, 할당된 메모리 자체에는 타입이 없다. 포인터 타입이 그 메모리를 어떻게 해석할지 결정한다.

## 3. `malloc`

`malloc`은 지정한 바이트 수만큼 메모리를 할당하고, 시작 주소를 `void*`로 반환한다.

```c
void* malloc(size_t size);
```

예:

```c
int* p = (int*)malloc(sizeof(int));
*p = 42;
free(p);
```

초기값은 정해지지 않으므로 쓰레기 값이 들어 있을 수 있다.

## 4. `calloc`

`calloc`은 원소 개수와 원소 크기를 받아 전체 메모리를 할당하고 0으로 초기화한다.

```c
void* calloc(size_t nmemb, size_t size);
```

예:

```c
int* arr = (int*)calloc(n, sizeof(int));
```

`malloc`과 달리 초기값이 0으로 설정된다.

## 5. `free`와 메모리 오류

동적 할당한 메모리는 반드시 `free`로 해제해야 한다.

```c
free(p);
```

흔한 오류:

| 문제 | 원인 | 해결책 |
|---|---|---|
| 메모리 누수 | `free()` 미호출 | 모든 실행 경로에서 해제 |
| 댕글링 포인터 | `free()` 후 포인터 사용 | 해제 후 `p = NULL` |
| 이중 해제 | 같은 포인터를 두 번 `free()` | 소유권을 명확히 관리 |

## 6. 크기 재조정 패턴

배열 크기를 늘리려면 새 공간을 할당하고 기존 내용을 복사한 뒤 기존 공간을 해제한다.

```c
int* bigger = malloc(sizeof(int) * new_size);
memcpy(bigger, old, sizeof(int) * old_size);
free(old);
old = bigger;
```

이 패턴은 C에서 동적 배열을 직접 구현할 때 기본이 된다.

## 7. C++의 `nullptr`

C의 `NULL`은 단순히 `0`으로 정의되는 경우가 있어 함수 오버로딩에서 혼란을 만들 수 있다. C++에서는 포인터 전용 null 상수인 `nullptr`를 사용한다.

```cpp
void func(int n);
void func(int* p);

func(nullptr); // 포인터 버전 호출
```

`nullptr`는 타입 안전한 null 포인터 표현이다.

## 8. `new`와 `delete`

C++에서는 `malloc/free` 대신 `new/delete`를 사용해 객체를 동적으로 생성하고 삭제할 수 있다.

```cpp
int* p = new int;
*p = 42;
delete p;
```

배열:

```cpp
int* arr = new int[n];
delete[] arr;
```

`new`는 메모리 할당뿐 아니라 생성자 호출까지 수행한다. `delete`는 소멸자를 호출한 뒤 메모리를 해제한다.

## 9. `new`와 `malloc` 차이

| 항목 | `malloc` | `new` |
|---|---|---|
| 언어 | C 함수 | C++ 연산자 |
| 반환 타입 | `void*` | 정확한 타입 포인터 |
| 캐스팅 | C++에서는 필요 | 불필요 |
| 생성자 호출 | 없음 | 있음 |
| 해제 | `free` | `delete` |
| 실패 시 | `NULL` 반환 가능 | 기본적으로 예외 발생 |

주의할 점은 할당과 해제 방식을 반드시 맞춰야 한다는 것이다.

```cpp
int* p = new int;
delete p; // 맞음

int* q = (int*)malloc(sizeof(int));
free(q); // 맞음
```

`malloc`으로 할당한 것을 `delete`하거나, `new`로 만든 것을 `free`하면 안 된다.

## 10. const와 포인터

포인터와 `const`는 위치에 따라 의미가 달라진다.

| 형태 | 의미 |
|---|---|
| `const int* p` | p가 가리키는 값을 수정할 수 없음 |
| `int* const p` | p 자체가 다른 주소를 가리킬 수 없음 |
| `const int* const p` | 값도 못 바꾸고, 포인터도 못 바꿈 |

읽는 요령은 오른쪽에서 왼쪽으로 읽는 것이다.

```cpp
const int* p;      // pointer to const int
int* const p;      // const pointer to int
const int* const p; // const pointer to const int
```

## 11. 포인터와 클래스

객체를 `new`로 생성하면 생성자가 호출된다.

```cpp
Student* s = new Student(20, "홍길동");
delete s;
```

객체 배열:

```cpp
Student* arr = new Student[3];
delete[] arr;
```

단일 객체에는 `delete`, 배열에는 `delete[]`를 사용해야 한다.

## 12. 스마트 포인터가 필요한 이유

원시 포인터를 직접 관리하면 예외나 조기 반환 때문에 `delete`가 누락될 수 있다.

```cpp
void process(bool error) {
    int* data = new int[1000];

    if (error) return; // delete[] 누락

    delete[] data;
}
```

스마트 포인터는 객체 수명과 자원 해제를 묶는 RAII 방식으로 이 문제를 줄인다.

## 13. RAII와 스마트 포인터

RAII는 Resource Acquisition Is Initialization의 약자다. 자원을 객체가 소유하게 하고, 객체가 소멸될 때 소멸자에서 자원을 자동 해제하는 방식이다.

C++ 표준 스마트 포인터:

| 스마트 포인터 | 의미 |
|---|---|
| `std::unique_ptr` | 단독 소유 |
| `std::shared_ptr` | 공유 소유, 참조 카운팅 |
| `std::weak_ptr` | 비소유 관찰, 순환 참조 방지 |

## 14. `unique_ptr`

`unique_ptr`는 하나의 포인터만 객체를 소유하게 한다. 복사는 불가능하고 이동만 가능하다.

```cpp
#include <memory>

auto p = std::make_unique<int>(42);
auto q = std::move(p);
```

`p`의 소유권이 `q`로 이동한다. 단독 소유가 기본 선택지라면 `unique_ptr`가 가장 적합하다.

## 15. `shared_ptr`

`shared_ptr`는 여러 포인터가 같은 객체를 공유할 수 있게 한다.

```cpp
auto a = std::make_shared<int>(99);
auto b = a;

printf("%ld\n", a.use_count()); // 2
```

내부적으로 참조 카운트를 관리하고, 마지막 `shared_ptr`가 사라질 때 객체를 해제한다.

## 16. 순환 참조와 `weak_ptr`

`shared_ptr`끼리 서로를 소유하면 참조 카운트가 0이 되지 않아 메모리가 해제되지 않을 수 있다.

```cpp
struct Node {
    int val;
    std::shared_ptr<Node> next;
    std::shared_ptr<Node> prev; // 문제 가능
};
```

한쪽을 `weak_ptr`로 바꾸면 소유 관계를 끊을 수 있다.

```cpp
struct Node {
    int val;
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;
};
```

`weak_ptr`는 객체를 소유하지 않으므로 참조 카운트를 증가시키지 않는다. 실제 접근이 필요할 때는 `lock()`으로 `shared_ptr`를 얻는다.

## 17. 커스텀 삭제자

스마트 포인터는 `delete`가 아닌 방식으로 해제해야 하는 자원도 관리할 수 있다. 예를 들어 `FILE*`는 `fclose`로 닫아야 한다.

```cpp
auto file_deleter = [](FILE* f) {
    if (f) fclose(f);
};

std::unique_ptr<FILE, decltype(file_deleter)> fp(
    fopen("test.txt", "r"),
    file_deleter
);
```

`shared_ptr`도 생성 시 삭제자를 전달할 수 있다.

## 18. `make_unique`, `make_shared` 권장

직접 `new`를 쓰기보다 `make_unique`, `make_shared`를 사용하는 것이 권장된다.

```cpp
auto up = std::make_unique<T>(args...);
auto sp = std::make_shared<T>(args...);
```

`make_shared`는 객체와 control block을 한 번에 할당할 수 있어 메모리 효율이 좋다. 또한 함수 인자 평가 순서 문제로 인한 잠재적 누수를 줄인다.

## 19. 선택 가이드

| 상황 | 권장 |
|---|---|
| 동적 할당이 필요 없음 | 일반 객체 사용 |
| 단독 소유 | `std::unique_ptr<T>` |
| 여러 곳에서 공유 | `std::shared_ptr<T>` |
| 공유 객체를 관찰만 함 | `std::weak_ptr<T>` |
| C 자원 관리 | 스마트 포인터 + 커스텀 삭제자 |

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| Heap | 실행 중 동적으로 할당하는 메모리 영역 |
| `malloc/free` | C 방식 동적 할당과 해제 |
| `new/delete` | C++ 방식 객체 생성과 해제 |
| `nullptr` | C++의 타입 안전한 null 포인터 |
| `const int*` | 가리키는 값을 수정할 수 없음 |
| `int* const` | 포인터 자체를 다른 주소로 바꿀 수 없음 |
| RAII | 객체 수명과 자원 관리를 묶는 방식 |
| `unique_ptr` | 단독 소유, 이동 가능 |
| `shared_ptr` | 공유 소유, 참조 카운팅 |
| `weak_ptr` | 비소유 관찰, 순환 참조 방지 |

이 통합 요약의 핵심은 C의 수동 메모리 관리에서 C++의 RAII와 스마트 포인터로 발전하는 흐름이다. C++에서는 가능하면 원시 `new/delete`보다 스마트 포인터와 자동 수명 관리를 우선 고려하는 것이 안전하다.

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C_동적할당.pdf" | relative_url }}" target="_blank" rel="noopener">C_동적할당.pdf</a></li>
  <li><a href="{{ "/assets/pdfs/study/cpp/(심화) C++ 포인터.pdf" | relative_url }}" target="_blank" rel="noopener">(심화) C++ 포인터.pdf</a></li>
</ul>
