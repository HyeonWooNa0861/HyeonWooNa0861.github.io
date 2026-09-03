---
layout: default
date: 2026-05-18 11:56:08 +0900
title: "C++ Classes and Operator Overloading"
course: "C++"
topic: "Function and Operator Overloading"
order: 7
major_topic: "C++ Programming"
keywords:
  - "Operator Overloading"
  - "Function Overloading"
  - "Constructors"
  - "Member Functions"
  - "this Pointer"
---

# C++ Classes and Operator Overloading

Source PDF: `C++ 오버로딩.pdf`

> **핵심:** **오버로딩** 반환형이 아니라 매개변수로 구별. **복사 생성자** 새 객체를 복사로 만들 때 호출.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 함수/생성자 오버로딩 | 같은 이름을 어떻게 구별하는가? |
| 2 | 복사 생성자/복사 대입 | 객체 복사는 언제 위험한가? |
| 3 | `static`, `const` | 객체별 기능과 클래스 공통 기능은 어떻게 나누는가? |
| 4 | `friend` | 전역 함수가 private 멤버에 접근하려면? |
| 5 | 연산자 오버로딩 | 어떤 연산자는 멤버, 어떤 연산자는 전역인가? |
| 6 | `operator[]`, `operator()` | 객체를 배열처럼, 함수처럼 쓰는 방법은? |
| 7 | 파일 분리 | `.h`와 `.cpp`는 어떻게 역할을 나누는가? |

## 1. 오버로딩

오버로딩은 같은 이름을 쓰되, 매개변수 구성을 다르게 해서 여러 함수를 구별하는 기능이다.

| 종류 | 예시 | 핵심 |
|---|---|---|
| 함수 오버로딩 | `print(int)`, `print(double)` | 이름은 같아도 매개변수가 다르면 다른 함수 |
| 생성자 오버로딩 | `T()`, `T(int)`, `T(const T&)` | 객체 생성 방식을 여러 개 제공 |
| 반환형만 다른 함수 | `int f()`, `double f()` | 오버로딩 불가 |

반환형은 함수 구별 기준에 포함되지 않는다. C++은 함수 이름과 매개변수 목록, 즉 시그니처로 함수를 구분한다.

## 2. 복사 생성자와 복사 대입

객체 복사에는 두 가지 상황이 있다.

| 상황 | 코드 예시 | 호출되는 함수 |
|---|---|---|
| 새 객체를 기존 객체로 생성 | `Student b = a;` | 복사 생성자 |
| 이미 있는 객체에 대입 | `b = a;` | 복사 대입 연산자 |

동적 메모리를 가진 클래스에서는 기본 복사가 위험할 수 있다. 포인터 값만 복사되면 두 객체가 같은 메모리를 공유하는 얕은 복사가 발생한다.

복사 대입 연산자에서 중요한 순서는 다음과 같다.

```cpp
if (this == &other) return *this; // 자기 대입 방지
// 기존 자원 해제
// 새 자원 깊은 복사
return *this;
```

`return *this;`는 `a = b = c` 같은 연쇄 대입을 가능하게 한다.

## 3. static과 const

`static`은 객체가 아니라 클래스에 속한다.

```cpp
class Counter {
    static int count;
};
```

모든 객체가 같은 `static` 멤버를 공유한다. `static` 멤버 함수는 객체 없이 호출할 수 있지만, `this`가 없으므로 일반 멤버 변수에는 직접 접근할 수 없다.

`const` 멤버 함수는 객체 상태를 바꾸지 않겠다는 약속이다.

```cpp
int getAge() const;
```

`const` 객체는 `const` 멤버 함수만 호출할 수 있으므로, 값을 읽기만 하는 함수에는 `const`를 붙이는 것이 좋다.

## 4. friend

전역 함수는 기본적으로 클래스의 private 멤버에 접근할 수 없다.

```cpp
class Complex {
    double re, im; // private
};
```

전역 `operator+`나 `operator<<`가 `re`, `im`에 접근해야 한다면 `friend`를 사용할 수 있다.

```cpp
friend Complex operator+(const Complex& a, const Complex& b);
friend std::ostream& operator<<(std::ostream& os, const Complex& c);
```

`friend`는 private 접근을 허용하는 예외 장치다. 편리하지만 캡슐화를 약화시킬 수 있으므로 필요한 함수에만 제한적으로 쓰는 것이 좋다.

## 5. 연산자 오버로딩

연산자 오버로딩은 사용자 정의 타입도 기본 타입처럼 자연스럽게 연산하도록 만드는 기능이다.

| 구현 방식 | 연산자 | 이유 |
|---|---|---|
| 반드시 멤버 함수 | `=`, `[]`, `()`, `->` | C++ 표준상 멤버 함수여야 함 |
| 사실상 전역 함수 | `<<`, `>>` | 왼쪽 피연산자가 `ostream` 또는 `istream` |
| 둘 다 가능 | `+`, `-`, `*`, `/`, `==`, `<` | 상황에 따라 선택 |
| 멤버 함수가 자연스러움 | `+=`, `-=`, `*=`, `/=` | 현재 객체를 직접 수정 |

`cout << obj`에서 왼쪽 피연산자는 `cout`, 즉 `std::ostream`이다. `std::ostream` 클래스를 수정할 수 없으므로 `operator<<`는 보통 전역 함수로 만든다.

## 6. operator[]

`operator[]`는 객체를 배열처럼 사용할 수 있게 한다.

```cpp
v[0] = 1.414;
printf("%lf\n", v[0]);
```

비-`const` 버전은 참조를 반환해서 쓰기가 가능하다.

```cpp
double& operator[](int i);
```

`const` 버전은 읽기 전용 접근을 제공한다.

```cpp
double operator[](int i) const;
```

두 버전을 모두 제공하면 일반 객체는 읽기/쓰기가 가능하고, `const` 객체는 안전하게 읽기만 가능하다.

## 7. operator()

`operator()`는 객체를 함수처럼 호출할 수 있게 한다.

```cpp
Vector2D v(3.0, 4.0);

v(0); // x 성분
v(1); // y 성분
```

행렬에서는 인자를 두 개 받아서 원소 접근에 사용할 수 있다.

```cpp
Matrix2D m(2, 0, 0, 3);

m(0, 0);     // 읽기
m(0, 0) = 1; // 쓰기
```

`operator()`는 매개변수 개수와 타입을 다르게 해서 여러 형태로 오버로딩할 수 있다.

## 8. 1차원 배열로 2차원 행렬 표현

2차원 행렬을 내부적으로 1차원 배열에 저장할 수 있다.

| 방식 | 저장 순서 | 인덱스 계산 |
|---|---|---|
| 행 우선 | `a, b, c, d` | `m[i * 2 + j]` |
| 열 우선 | `a, c, b, d` | `m[i + j * 2]` |

겉으로 보이는 행렬은 같아도 내부 저장 방식은 다를 수 있다. 중요한 것은 저장 방식과 인덱스 계산식을 일관되게 맞추는 것이다.

## 9. 클래스 파일 분리

C++에서는 보통 선언과 구현을 분리한다.

| 파일 | 역할 |
|---|---|
| `.h` | 클래스 선언 |
| `.cpp` | 멤버 함수 정의 |
| `main.cpp` | 클래스 사용 |

`student.h`

```cpp
class Student {
public:
    Student(int age, const char* name);
    void greet() const;
};
```

`student.cpp`

```cpp
Student::Student(int age, const char* name) {
    this->age = age;
}
```

헤더에는 `#pragma once`를 넣어 중복 include를 막는다. 일반 함수 구현을 헤더에 넣으면 여러 `.cpp`에서 include될 때 중복 정의 오류가 날 수 있다.

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| 오버로딩 | 반환형이 아니라 매개변수로 구별 |
| 복사 생성자 | 새 객체를 복사로 만들 때 호출 |
| 복사 대입 | 이미 있는 객체에 대입할 때 호출 |
| `static` | 모든 객체가 공유 |
| `const` 멤버 함수 | 객체 상태를 변경하지 않음 |
| `friend` | private 접근 허용, 최소한만 사용 |
| `operator[]` | 배열처럼 접근 |
| `operator()` | 함수처럼 호출 |
| `operator<<` | 보통 전역 함수로 구현 |
| 파일 분리 | `.h`는 선언, `.cpp`는 구현 |

이 강의의 결론은 C++ 클래스가 단순히 데이터와 함수를 묶는 문법이 아니라, 객체의 생성, 복사, 대입, 접근, 출력, 호출 방식까지 직접 설계하는 도구라는 점이다.

## 부록. `10주차_추가자료.cpp` 전문 및 해석

이 추가자료는 `Vector2D`, `Matrix2D` 클래스를 통해 `operator()`와 `operator*` 오버로딩을 실제 코드로 보여준다. 핵심은 다음 세 가지다.

| 주제 | 코드에서 보이는 방식 |
|---|---|
| 객체를 함수처럼 호출 | `v(0)`, `A(0, 0)` |
| 읽기/쓰기 구분 | `double&` 반환이면 대입 가능, `const` 버전은 읽기 전용 |
| 행렬-벡터 곱 | `A * v`, `v * A`를 전역 `operator*`로 구현 |

### 코드 전문

```cpp
#include <iostream>
#include <cstdio>

class Vector2D 
{
public:
	Vector2D() : x(0.0), y(0.0)                     {}
	Vector2D(double _x, double _y) : x(_x), y(_y)   {}

	double operator()(int i) const
	{
		return	(i == 0) ? x : y;
	}
	double& operator()(int i)
	{
		return	(i == 0) ? x : y;
	}

private:
	double	x, y;
};

class Matrix2D
{
public:
	Matrix2D()	
	{ data[0] = data[1] = data[2] = data[3] = 0.0; }

	Matrix2D(double _a, double _b, double _c, double _d)
	{
		data[0] = _a; 
		data[1] = _b; 
		data[2] = _c; 
		data[3] = _d; 
	}

	double& operator()(int i, int j)
	{
		//i = 0, j = 0 -> [0]
		//i = 1, j = 0 -> [1]
		//i = 0, j = 1 -> [2]
		//i = 1, j = 1 -> [3]
		return data[i + 2*j];
	}

	double operator()(int i, int j) const 
	{
		return data[i + 2*j];
	}

private:
	double data[4];
};

Vector2D operator*(const Matrix2D& A, const Vector2D& x)
{
	Vector2D ret;

	ret(0) = A(0,0)*x(0) + A(0,1)*x(1);
	ret(1) = A(1,0)*x(0) + A(1,1)*x(1);

	return	ret;
}

Vector2D operator*(const Vector2D& x, const Matrix2D& A)
{
	Vector2D ret;

	ret(0) = x(0)*A(0,0) + x(1)*A(1,0);
	ret(1) = x(0)*A(0,1) + x(1)*A(1,1);

	return	ret;
}

int main()
{
	Vector2D	v, w(3.0, 1.0);

	Matrix2D	A;
	Matrix2D	B(1.0, 0.0, -1.0, 0.0);

	A(0,0) = 1.0;

	double d = A(0,0);

	v(1) = 3.14;

	w = A*v;
	w = v*A;
}
```

### 1. `Vector2D` 클래스 해석

`Vector2D`는 2차원 벡터를 표현하는 클래스다.

```cpp
class Vector2D 
{
private:
	double x, y;
};
```

내부에는 `x`, `y` 두 개의 `double` 값이 있다. 이 값들은 `private`이므로 클래스 바깥에서 직접 접근할 수 없다.

```cpp
Vector2D() : x(0.0), y(0.0) {}
Vector2D(double _x, double _y) : x(_x), y(_y) {}
```

첫 번째 생성자는 기본 생성자다. `Vector2D v;`처럼 만들면 `v`는 `(0.0, 0.0)`이 된다. 두 번째 생성자는 원하는 값을 받아서 `(x, y)`를 초기화한다.

```cpp
Vector2D w(3.0, 1.0);
```

위 코드는 `w`를 `(3.0, 1.0)` 벡터로 만든다.

### 2. `Vector2D`의 `operator()` 해석

`Vector2D`에는 `operator()`가 두 개 있다.

```cpp
double operator()(int i) const
{
	return (i == 0) ? x : y;
}

double& operator()(int i)
{
	return (i == 0) ? x : y;
}
```

이 연산자를 만들면 객체를 함수처럼 호출할 수 있다.

```cpp
v(0); // x 성분
v(1); // y 성분
```

두 버전의 차이는 반환 타입과 `const` 여부다.

| 함수 | 의미 | 사용 상황 |
|---|---|---|
| `double operator()(int i) const` | 값을 복사해서 반환 | `const` 객체에서 읽기 |
| `double& operator()(int i)` | 실제 원소의 참조 반환 | 일반 객체에서 읽기/쓰기 |

`double&`는 실제 멤버 변수에 대한 참조이므로 대입이 가능하다.

```cpp
v(1) = 3.14;
```

위 코드는 `v`의 `y` 값을 `3.14`로 바꾼다. `operator()`가 `double`만 반환했다면 반환값은 복사본이므로 이런 대입은 불가능하다.

### 3. `Matrix2D` 클래스 해석

`Matrix2D`는 2x2 행렬을 표현한다.

```cpp
class Matrix2D
{
private:
	double data[4];
};
```

겉으로는 2x2 행렬처럼 사용하지만, 내부 저장은 `double data[4]`라는 1차원 배열로 한다.

기본 생성자는 네 원소를 모두 0으로 초기화한다.

```cpp
Matrix2D()	
{ data[0] = data[1] = data[2] = data[3] = 0.0; }
```

인자를 받는 생성자는 네 값을 배열에 순서대로 넣는다.

```cpp
Matrix2D(double _a, double _b, double _c, double _d)
{
	data[0] = _a; 
	data[1] = _b; 
	data[2] = _c; 
	data[3] = _d; 
}
```

주의할 점은 이 코드가 행렬을 **열 우선(column-major)** 방식으로 저장한다는 것이다.

| 행렬 위치 | 내부 배열 |
|---|---|
| `A(0, 0)` | `data[0]` |
| `A(1, 0)` | `data[1]` |
| `A(0, 1)` | `data[2]` |
| `A(1, 1)` | `data[3]` |

따라서 생성자 호출:

```cpp
Matrix2D B(1.0, 0.0, -1.0, 0.0);
```

은 다음 행렬을 만든다.

```text
B(0,0) =  1.0
B(1,0) =  0.0
B(0,1) = -1.0
B(1,1) =  0.0

행렬 모양:
[ 1.0  -1.0 ]
[ 0.0   0.0 ]
```

### 4. `Matrix2D`의 `operator()` 해석

행렬 원소 접근도 `operator()`로 구현되어 있다.

```cpp
double& operator()(int i, int j)
{
	return data[i + 2*j];
}

double operator()(int i, int j) const 
{
	return data[i + 2*j];
}
```

`i`는 행 번호, `j`는 열 번호다. 2x2 행렬이므로 가능한 인덱스는 `0` 또는 `1`이다.

```cpp
A(0,0) = 1.0;
double d = A(0,0);
```

첫 번째 줄은 `A`의 `(0,0)` 원소에 값을 쓴다. 두 번째 줄은 같은 원소를 읽어서 `d`에 저장한다.

인덱스 계산식은 다음과 같다.

```cpp
i + 2*j
```

이 식은 열 우선 저장 방식이다.

| `i` | `j` | 계산식 | 배열 위치 |
|---|---|---|---|
| 0 | 0 | `0 + 2*0` | `data[0]` |
| 1 | 0 | `1 + 2*0` | `data[1]` |
| 0 | 1 | `0 + 2*1` | `data[2]` |
| 1 | 1 | `1 + 2*1` | `data[3]` |

### 5. `A * x`: 행렬-벡터 곱

첫 번째 `operator*`는 행렬과 벡터의 곱을 정의한다.

```cpp
Vector2D operator*(const Matrix2D& A, const Vector2D& x)
{
	Vector2D ret;

	ret(0) = A(0,0)*x(0) + A(0,1)*x(1);
	ret(1) = A(1,0)*x(0) + A(1,1)*x(1);

	return ret;
}
```

이 함수는 다음 형태를 처리한다.

```cpp
w = A * v;
```

수학적으로는 다음 계산이다.

```text
[ A00 A01 ] [ x0 ] = [ A00*x0 + A01*x1 ]
[ A10 A11 ] [ x1 ]   [ A10*x0 + A11*x1 ]
```

코드에서 결과 벡터의 첫 번째 성분은:

```cpp
ret(0) = A(0,0)*x(0) + A(0,1)*x(1);
```

결과 벡터의 두 번째 성분은:

```cpp
ret(1) = A(1,0)*x(0) + A(1,1)*x(1);
```

이다.

이 연산자는 멤버 함수가 아니라 전역 함수다. 왼쪽 피연산자가 `Matrix2D`, 오른쪽 피연산자가 `Vector2D`인 독립적인 이항 연산이므로 전역 함수로 두면 두 타입의 관계를 더 자연스럽게 표현할 수 있다.

### 6. `x * A`: 벡터-행렬 곱

두 번째 `operator*`는 반대 순서의 곱을 정의한다.

```cpp
Vector2D operator*(const Vector2D& x, const Matrix2D& A)
{
	Vector2D ret;

	ret(0) = x(0)*A(0,0) + x(1)*A(1,0);
	ret(1) = x(0)*A(0,1) + x(1)*A(1,1);

	return ret;
}
```

이 함수는 다음 형태를 처리한다.

```cpp
w = v * A;
```

수학적으로는 `v`를 행 벡터처럼 보고 계산한다.

```text
[ x0 x1 ] [ A00 A01 ] = [ x0*A00 + x1*A10,  x0*A01 + x1*A11 ]
          [ A10 A11 ]
```

그래서 결과의 첫 번째 성분은:

```cpp
ret(0) = x(0)*A(0,0) + x(1)*A(1,0);
```

결과의 두 번째 성분은:

```cpp
ret(1) = x(0)*A(0,1) + x(1)*A(1,1);
```

이다.

`A * v`와 `v * A`는 피연산자 순서가 다르므로 서로 다른 함수가 필요하다. C++은 함수 이름이 같아도 매개변수 타입과 순서가 다르면 다른 함수로 구별한다. 이것이 연산자 오버로딩이다.

### 7. `main()` 흐름 해석

```cpp
Vector2D v, w(3.0, 1.0);
```

`v`는 기본 생성자로 만들어져 `(0.0, 0.0)`이 된다. `w`는 `(3.0, 1.0)`으로 초기화된다.

```cpp
Matrix2D A;
Matrix2D B(1.0, 0.0, -1.0, 0.0);
```

`A`는 모든 원소가 0인 2x2 행렬이다. `B`는 값을 가진 행렬로 생성되지만, 이후 코드에서는 사용되지 않는다.

```cpp
A(0,0) = 1.0;
```

`A`의 `(0,0)` 원소를 `1.0`으로 바꾼다. 이때 `A(0,0)`은 `double&`를 반환하므로 대입문의 왼쪽에 올 수 있다.

```cpp
double d = A(0,0);
```

`A(0,0)` 값을 읽어서 `d`에 저장한다. 이 시점에서 `d`는 `1.0`이다. 다만 `d`는 이후 코드에서 사용되지 않는다.

```cpp
v(1) = 3.14;
```

`v`의 두 번째 성분, 즉 `y` 값을 `3.14`로 바꾼다. 이 시점에서 `v`는 `(0.0, 3.14)`다.

```cpp
w = A*v;
```

행렬-벡터 곱을 수행한다. `A`는 `(0,0)`만 `1.0`이고 나머지는 `0.0`이므로:

```text
A = [ 1.0  0.0 ]
    [ 0.0  0.0 ]

v = [ 0.0  ]
    [ 3.14 ]
```

계산 결과는:

```text
w(0) = 1.0*0.0 + 0.0*3.14 = 0.0
w(1) = 0.0*0.0 + 0.0*3.14 = 0.0
```

따라서 `w`는 `(0.0, 0.0)`이 된다.

```cpp
w = v*A;
```

이번에는 벡터-행렬 곱을 수행한다.

```text
w(0) = 0.0*1.0 + 3.14*0.0 = 0.0
w(1) = 0.0*0.0 + 3.14*0.0 = 0.0
```

따라서 이 코드에서도 `w`는 `(0.0, 0.0)`이 된다.

### 8. 이 코드에서 주의할 점

| 주의점 | 설명 |
|---|---|
| 범위 검사 없음 | `v(3)`, `A(2, 0)` 같은 잘못된 접근을 막지 않는다. |
| `B` 미사용 | `Matrix2D B(...)`는 생성되지만 이후 연산에 사용되지 않는다. |
| `d` 미사용 | `double d = A(0,0);`로 값을 읽지만 이후 사용하지 않는다. |
| 출력 없음 | `main()` 안에 `cout`이나 `printf` 출력문이 없어 실행해도 화면에 결과가 나오지 않는다. |
| `<iostream>`, `<cstdio>` 미사용 | 현재 코드에서는 포함되어 있지만 실제 출력이 없어 직접 사용되지는 않는다. |

실제 학습용으로는 출력 연산자를 추가하거나 `printf`로 `w(0)`, `w(1)`을 출력하면 연산 결과를 확인하기 쉽다.

```cpp
printf("w = (%lf, %lf)\n", w(0), w(1));
```

이 추가자료의 핵심은 `operator()`를 이용해 객체를 함수 호출처럼 접근하고, `operator*`를 이용해 `A * v`, `v * A` 같은 수학적 표기를 C++ 코드로 자연스럽게 표현하는 것이다.

## Study Guide

이 문서는 C++ 클래스가 단순히 변수와 함수를 묶는 문법이 아니라, 객체의 생성, 복사, 접근, 출력, 연산 방식까지 설계하는 도구라는 흐름으로 읽어야 한다. 생성자 오버로딩, 복사 생성자, 복사 대입은 모두 객체가 언제 어떻게 만들어지고 복사되는지 설명한다.

연산자 오버로딩은 "문법을 예쁘게 만드는 기능"으로만 보면 위험하다. 핵심은 사용자 정의 타입에 자연스럽고 예측 가능한 연산 의미를 부여하는 것이다. `Complex + Complex`, `Matrix * Vector`, `cout << obj`처럼 기존 수학적 또는 입출력 관례와 맞을 때 가장 효과적이다.

`operator[]`와 `operator()`는 반환 타입을 주의해서 봐야 한다. 참조를 반환하면 대입문의 왼쪽에 올 수 있고, 값으로 반환하면 읽기만 가능하다. const 객체에서 읽기 전용 접근을 제공하려면 const 버전의 연산자도 함께 설계해야 한다.

## 복습 질문

<details>
<summary>1. C++에서 함수 오버로딩을 구분할 때 반환형만 다르면 오버로딩이 가능한가?</summary>

답변: 불가능하다. C++은 함수 이름과 매개변수 목록으로 함수를 구분하며, 반환형만 다른 함수는 호출식만 보고 어느 함수를 뜻하는지 결정할 수 없기 때문에 오버로딩으로 인정되지 않는다.

</details>

<details>
<summary>2. 멤버 연산자와 비멤버 연산자의 가장 큰 차이는 무엇인가?</summary>

답변: 멤버 연산자는 왼쪽 피연산자가 항상 현재 객체 `*this`가 된다. 그래서 `a + b`는 `a.operator+(b)`처럼 해석된다. 비멤버 연산자는 두 피연산자를 모두 매개변수로 받으므로 `1 + obj`처럼 왼쪽 피연산자가 기본 타입인 경우도 처리하기 쉽다.

</details>

<details>
<summary>3. `operator[]`나 `operator()`가 참조를 반환하면 어떤 장점이 있는가?</summary>

답변: 반환값이 원본 원소의 별명이 되므로 대입문의 왼쪽에 올 수 있다. 예를 들어 `v(1) = 3.14`처럼 객체 내부 원소를 직접 수정할 수 있다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ 오버로딩.pdf" | relative_url }}" target="_blank" rel="noopener">C++ 오버로딩.pdf</a></li>
</ul>
