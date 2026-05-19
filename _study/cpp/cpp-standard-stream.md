---
layout: default
title: "C++ Standard Streams"
course: "C++"
topic: "입출력 스트림"
order: 4
---

# C++ Standard Streams

Source PDF: `C++ 표준 스트림 (updated).pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 표준 스트림 | `stdin`, `stdout`, `stderr`는 무엇인가? |
| 2 | C vs C++ 입출력 | `printf/scanf`와 `cout/cin`은 어떻게 다른가? |
| 3 | 출력 서식 | `iomanip`으로 숫자와 폭을 어떻게 조절하는가? |
| 4 | 입력 처리 | `cin`, `getline`은 언제 다르게 써야 하는가? |
| 5 | 리다이렉션과 파이프 | 쉘은 표준 스트림을 어떻게 바꾸는가? |
| 6 | 버퍼링 | 출력이 바로 보이지 않는 이유는 무엇인가? |
| 7 | 파일 디스크립터 | `FILE*`와 fd 0/1/2는 어떤 관계인가? |

## 1. 세 가지 표준 스트림

프로그램이 시작되면 기본적으로 세 가지 표준 스트림이 연결된다.

| 스트림 | 파일 디스크립터 | 용도 |
|---|---:|---|
| `stdin` | 0 | 표준 입력 |
| `stdout` | 1 | 정상 출력 |
| `stderr` | 2 | 에러 출력 |

`stdin`은 키보드, 파일, 파이프에서 입력을 받을 수 있다. `stdout`은 정상 결과를 출력하고, `stderr`는 오류나 진단 메시지를 출력한다.

## 2. C vs C++ 표준 입출력

C 스타일:

```c
#include <stdio.h>

int age;
char name[32];

scanf("%d %s", &age, name);
printf("%s: %d\n", name, age);
```

C++ 스타일:

```cpp
#include <iostream>
#include <string>

int age;
std::string name;

std::cin >> age >> name;
std::cout << name << ": " << age << "\n";
```

비교:

| 항목 | C `printf/scanf` | C++ `cout/cin` |
|---|---|---|
| 헤더 | `<cstdio>` | `<iostream>` |
| 형식 지정자 | 직접 작성 | 타입 자동 인식 |
| 타입 안전성 | 낮음 | 높음 |
| 문자열 | `char[]` | `std::string` |
| 사용자 정의 타입 | 직접 처리 필요 | `operator<<`, `operator>>` 오버로딩 가능 |

## 3. `std::cout`

`std::cout`은 표준 출력 스트림이다.

```cpp
std::cout << "hello\n";
std::cout << "value = " << 42 << "\n";
```

`using namespace std;`를 쓰면 `std::` 접두사를 생략할 수 있지만, 큰 코드에서는 이름 충돌을 피하기 위해 명시적으로 쓰는 편이 좋다.

## 4. 출력 서식 조작자

`<iomanip>`은 출력 폭, 정밀도, 채움 문자 등을 조절하는 조작자를 제공한다.

```cpp
#include <iomanip>

std::cout << std::fixed << std::setprecision(2) << 3.14159;
std::cout << std::setw(10) << 42;
```

| 조작자 | 의미 |
|---|---|
| `std::fixed` | 고정 소수점 출력 |
| `std::setprecision(n)` | 소수점 정밀도 설정 |
| `std::setw(n)` | 다음 출력의 폭 지정 |
| `std::setfill(c)` | 빈 공간을 채울 문자 지정 |

`setw`는 다음 출력 한 번에만 적용된다.

## 5. `stderr`, `std::cerr`, `std::clog`

C에서는 에러 출력을 `fprintf(stderr, ...)`로 보낸다.

```c
fprintf(stderr, "error\n");
```

C++에서는 `std::cerr`와 `std::clog`를 사용한다.

```cpp
std::cerr << "치명적 오류\n";
std::clog << "로그 메시지\n";
```

| 스트림 | 특징 |
|---|---|
| `std::cerr` | 언버퍼드, 즉시 출력, 에러용 |
| `std::clog` | 버퍼링 있음, 로그용 |

## 6. `std::cin`

`std::cin`은 표준 입력 스트림이다.

```cpp
int a;
double b;

std::cin >> a >> b;
```

C의 `scanf`는 주소를 넘기기 위해 `&`가 필요하지만, C++의 `cin`은 변수 자체를 넘긴다.

```c
scanf("%d", &a);
```

```cpp
std::cin >> a;
```

## 7. `getline`

`operator>>`는 공백을 기준으로 입력을 끊는다. 한 줄 전체를 읽으려면 `std::getline`을 사용한다.

```cpp
std::string line;
std::getline(std::cin, line);
```

EOF까지 모든 줄을 읽을 수도 있다.

```cpp
while (std::getline(std::cin, line)) {
    std::cout << line << "\n";
}
```

주의할 점은 `cin >> age` 뒤에 `getline`을 바로 쓰면 버퍼에 남은 개행 문자 때문에 빈 줄이 읽힐 수 있다는 것이다. 이런 경우 `ignore()`를 사용하거나, 모든 입력을 `getline`으로 받고 파싱하는 패턴이 안전하다.

## 8. stdin 잔류 문제 권장 패턴

C에서는 `fgets`로 한 줄을 읽고 `sscanf`로 파싱하는 방식이 안전하다.

```c
char line[256];
int age;
char name[64];

fgets(line, sizeof(line), stdin);
sscanf(line, "%d %63s", &age, name);
```

C++에서는 `getline`과 `istringstream` 조합이 좋다.

```cpp
std::string line;
int age;
std::string name;

std::getline(std::cin, line);
std::istringstream iss(line);
iss >> age >> name;
```

## 9. 리다이렉션과 파이프

쉘은 프로그램 실행 전에 표준 스트림의 연결 대상을 바꿀 수 있다.

| 명령 | 의미 |
|---|---|
| `./prog > output.txt` | stdout을 파일로 저장 |
| `./prog >> output.txt` | stdout을 파일에 추가 |
| `./prog 2> error.txt` | stderr를 파일로 저장 |
| `./prog > all.txt 2>&1` | stdout과 stderr를 같은 파일로 저장 |
| `./producer | ./consumer` | producer의 stdout을 consumer의 stdin으로 연결 |

Windows PowerShell은 리다이렉션 문법이 다를 수 있으므로, 강의 예제는 cmd 또는 POSIX 계열 쉘 기준으로 이해하는 것이 좋다.

## 10. 버퍼란?

버퍼는 출력 데이터를 바로 OS에 보내지 않고 잠시 모아 두는 유저 공간의 임시 저장소다.

```text
프로그램 → 유저 공간 버퍼 → 시스템 콜 → OS 커널 → 터미널/파일
```

버퍼를 쓰는 이유는 시스템 콜 비용이 크기 때문이다. 작은 출력을 매번 OS에 보내는 것보다 모아서 보내는 편이 효율적이다.

## 11. 버퍼링의 종류

| 종류 | 플러시 시점 | 적용 대상 |
|---|---|---|
| 풀 버퍼링 | 버퍼가 가득 찰 때 | stdout → 파일/파이프 |
| 라인 버퍼링 | `\n`을 만날 때 | stdout → 터미널 |
| 언버퍼드 | 즉시 출력 | stderr |

터미널에 연결된 stdout은 보통 줄 단위로 플러시된다. 파일이나 파이프에 연결되면 풀 버퍼링이 적용될 수 있다.

## 12. 플러시 제어

C에서는 `fflush(stdout)`으로 강제 플러시할 수 있다.

```c
printf("진행 중...");
fflush(stdout);
```

C++에서는 `std::flush` 또는 `std::endl`을 사용할 수 있다.

```cpp
std::cout << "결과: " << 42 << std::endl;
```

`std::endl`은 `'\n'` 출력과 flush를 함께 수행한다. 단, 불필요한 flush는 성능을 낮출 수 있으므로 줄바꿈만 필요하면 `"\n"`이 더 적합하다.

## 13. `FILE*`와 파일 디스크립터

C의 `FILE*`는 유저 공간의 스트림 객체이고, 내부적으로 파일 디스크립터 번호와 버퍼 정보를 가진다.

```c
printf("%d\n", fileno(stdin));  // 0
printf("%d\n", fileno(stdout)); // 1
printf("%d\n", fileno(stderr)); // 2
```

관계:

```text
FILE* stdin/stdout/stderr
↕ fileno()
파일 디스크립터 0/1/2
↕
OS 커널의 실제 입출력 대상
```

`FILE*`는 C 표준 레이어이고, 파일 디스크립터는 POSIX 계열 OS 커널 레이어라고 볼 수 있다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| `stdin` | 표준 입력, fd 0 |
| `stdout` | 정상 출력, fd 1 |
| `stderr` | 에러 출력, fd 2 |
| `std::cout` | C++ 표준 출력 |
| `std::cin` | C++ 표준 입력 |
| `std::cerr` | 즉시 출력되는 에러 스트림 |
| `std::clog` | 버퍼링되는 로그 스트림 |
| 리다이렉션 | 쉘이 fd 연결 대상을 바꾸는 기능 |
| 파이프 | 한 프로그램의 stdout을 다른 프로그램의 stdin에 연결 |
| 버퍼링 | 시스템 콜을 줄이기 위해 데이터를 모아 두는 방식 |
| 플러시 | 버퍼 내용을 강제로 내보내는 동작 |

표준 스트림은 단순한 입출력 문법이 아니라, 유저 공간 버퍼와 OS 파일 디스크립터가 연결된 추상화다. 이 구조를 이해하면 리다이렉션, 파이프, stdout/stderr 분리, 출력 지연 문제를 더 정확히 설명할 수 있다.

## Study Guide

표준 스트림은 `cout`과 `cin` 문법만 외우는 단원이 아니다. 프로그램이 시작될 때 기본적으로 입력, 정상 출력, 에러 출력 세 통로가 연결되어 있고, 쉘은 이 통로를 파일이나 다른 프로그램으로 바꿀 수 있다.

`stdout`과 `stderr`를 분리하는 이유를 이해하면 리다이렉션이 쉬워진다. 정상 결과는 파일로 저장하면서 에러 메시지는 터미널에 남기는 식의 제어가 가능하기 때문이다. 이 관점에서 fd 0, 1, 2는 단순 번호가 아니라 OS가 입출력 대상을 구분하는 기본 약속이다.

버퍼링은 출력 지연 문제를 설명하는 핵심이다. `std::endl`은 줄바꿈과 flush를 함께 수행하므로 즉시 출력이 필요할 때 유용하지만, 매번 flush하면 성능이 떨어질 수 있다. 줄바꿈만 필요하면 `"\n"`을 쓰는 것이 더 적합하다.

## 복습 질문

<details>
<summary>1. `stdin`, `stdout`, `stderr`의 파일 디스크립터 번호는 각각 무엇인가?</summary>

답변: `stdin`은 0, `stdout`은 1, `stderr`는 2다. `stdin`은 입력, `stdout`은 정상 출력, `stderr`는 오류나 진단 메시지 출력에 사용된다.

</details>

<details>
<summary>2. `std::endl`과 `"\n"`은 어떤 차이가 있는가?</summary>

답변: 둘 다 줄바꿈을 만들 수 있지만, `std::endl`은 줄바꿈 후 flush까지 수행한다. 단순 줄바꿈만 필요하면 `"\n"`이 더 가볍고, 출력 버퍼를 즉시 비워야 할 때 `std::endl`이나 `std::flush`를 사용한다.

</details>

<details>
<summary>3. 리다이렉션과 파이프는 표준 스트림 관점에서 무엇을 바꾸는가?</summary>

답변: 쉘이 프로그램의 표준 스트림 연결 대상을 바꾼다. 리다이렉션은 `stdout`이나 `stdin`을 파일로 연결하고, 파이프는 한 프로그램의 `stdout`을 다른 프로그램의 `stdin`으로 연결한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 표준 스트림 (updated).pdf" | relative_url }}" target="_blank" rel="noopener">C++ 표준 스트림 (updated).pdf</a></li>
</ul>
