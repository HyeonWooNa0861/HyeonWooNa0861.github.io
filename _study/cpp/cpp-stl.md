---
layout: default
title: "C++ STL"
course: "C++"
topic: "Standard Template Library"
order: 12
---

# C++ STL

Source PDF: `C++ STL.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | STL의 구조 | 컨테이너, 이터레이터, 알고리즘은 어떻게 연결되는가? |
| 2 | `std::vector` | 동적 배열은 언제 기본 선택지가 되는가? |
| 3 | `std::list` | 중간 삽입과 삭제가 많을 때 왜 연결 리스트가 유리한가? |
| 4 | `std::array` | 고정 크기 배열을 STL 방식으로 쓰면 무엇이 달라지는가? |
| 5 | 이터레이터 | 컨테이너 내부 구조가 달라도 왜 같은 반복문을 쓸 수 있는가? |
| 6 | `std::set` | 중복 없는 집합과 빠른 존재 확인은 어떻게 처리하는가? |
| 7 | `std::map` | 키-값 데이터를 어떻게 저장하고 검색하는가? |
| 8 | 함수 객체와 람다 | 알고리즘에 조건과 동작을 어떻게 전달하는가? |
| 9 | STL 알고리즘 | 검색, 정렬, 변환, 제거, 집계는 어떤 패턴으로 조합하는가? |
| 10 | 실전 조합 | 학생 성적 데이터를 STL로 어떻게 처리하는가? |

## 1. STL이란?

STL(Standard Template Library)은 C++ 표준 라이브러리에 포함된 **자료구조와 알고리즘의 묶음**이다. 직접 배열, 연결 리스트, 정렬 함수, 검색 함수를 매번 구현하지 않고, 검증된 표준 구현을 가져다 쓸 수 있게 한다.

```cpp
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>

int main() {
    std::vector<int> scores = {85, 92, 78, 95, 88};

    std::sort(scores.begin(), scores.end());
    // scores: {78, 85, 88, 92, 95}

    std::map<std::string, int> student;
    student["Alice"] = 95;
    student["Bob"] = 88;

    std::cout << student["Alice"]; // 95
}
```

STL의 장점은 다음 네 가지로 정리할 수 있다.

| 특성 | 의미 |
|---|---|
| 범용성 | 템플릿 기반이므로 `int`, `double`, 사용자 정의 타입 등 다양한 타입에 같은 인터페이스를 적용할 수 있다. |
| 표준성 | 모든 표준 C++ 컴파일러가 제공하므로 별도 라이브러리 설치 없이 사용할 수 있다. |
| 검증된 구현 | 정렬, 검색, 자료구조 구현이 이미 최적화되어 있고 안정적이다. |
| 재사용성 | 자료구조와 알고리즘을 직접 반복 구현하지 않아도 된다. |

STL은 크게 네 요소로 이해하면 된다.

| 구성 요소 | 역할 | 예시 |
|---|---|---|
| 컨테이너 | 데이터를 저장하는 자료구조 | `vector`, `list`, `array`, `set`, `map` |
| 이터레이터 | 컨테이너 원소를 가리키고 순회하는 객체 | `begin()`, `end()`, `++it`, `*it` |
| 알고리즘 | 이터레이터 범위에 적용되는 연산 | `sort`, `find`, `count_if`, `accumulate` |
| 함수 객체/람다 | 알고리즘에 전달하는 조건 또는 동작 | `std::greater<int>()`, `[](int x){ return x > 0; }` |

핵심 구조는 다음이다.

```text
컨테이너가 데이터를 저장한다.
이터레이터가 컨테이너의 범위를 표현한다.
알고리즘이 그 범위에 연산을 적용한다.
람다나 함수 객체가 알고리즘의 세부 기준을 정한다.
```

## 2. STL 헤더 파일

STL은 기능별로 헤더가 나뉜다.

| 분류 | 헤더 | 대표 기능 |
|---|---|---|
| 시퀀스 컨테이너 | `<vector>` | `std::vector<T>`, 동적 배열 |
| 시퀀스 컨테이너 | `<array>` | `std::array<T, N>`, 고정 크기 배열 |
| 시퀀스 컨테이너 | `<list>` | `std::list<T>`, 이중 연결 리스트 |
| 시퀀스 컨테이너 | `<deque>` | `std::deque<T>`, 양방향 큐 |
| 연관 컨테이너 | `<set>` | `std::set<T>`, 중복 없는 정렬 집합 |
| 연관 컨테이너 | `<map>` | `std::map<K, V>`, 키-값 저장소 |
| 비정렬 컨테이너 | `<unordered_set>` | 해시 기반 집합 |
| 비정렬 컨테이너 | `<unordered_map>` | 해시 기반 키-값 저장소 |
| 알고리즘 | `<algorithm>` | `sort`, `find`, `transform`, `count_if` |
| 집계 | `<numeric>` | `accumulate`, `iota`, `inner_product` |
| 함수 객체 | `<functional>` | `greater`, `less`, `plus`, `function` |

기본 선택 기준은 간단하다.

```text
특별한 이유가 없으면 std::vector를 먼저 고려한다.
중복 없는 집합이 필요하면 std::set을 쓴다.
키로 값을 찾고 싶으면 std::map을 쓴다.
```

## 3. `std::vector`

`std::vector`는 **동적 배열**이다. 내부적으로 연속된 메모리 공간을 사용하고, 원소가 늘어나면 더 큰 공간을 다시 확보한다. STL에서 가장 자주 쓰는 기본 컨테이너다.

```cpp
#include <vector>

std::vector<int> v1;
std::vector<int> v2 = {10, 20, 30};
std::vector<int> v3(5, 0); // {0, 0, 0, 0, 0}
std::vector<int> v4 = v2;  // {10, 20, 30}
```

기본 조작은 다음과 같다.

```cpp
std::vector<int> v;

v.push_back(10); // {10}
v.push_back(20); // {10, 20}
v.push_back(30); // {10, 20, 30}

v.size();  // 3
v.empty(); // false
v.front(); // 10
v.back();  // 30

v.pop_back(); // {10, 20}
```

`vector`는 뒤쪽 추가와 삭제가 빠르다. `push_back`은 평균적으로 O(1)이다. 다만 중간 삽입과 삭제는 뒤쪽 원소를 이동시켜야 하므로 O(n)이다.

```cpp
std::vector<int> v = {10, 30, 40};

v.insert(v.begin() + 1, 20);
// {10, 20, 30, 40}

v.erase(v.begin() + 2);
// {10, 20, 40}
```

중간에 `20`을 넣으면 기존 `30`, `40`이 오른쪽으로 한 칸씩 이동한다. 반대로 중간 원소를 지우면 뒤쪽 원소가 왼쪽으로 당겨진다. 이 원소 이동 때문에 중간 삽입과 삭제가 O(n)이 된다.

## 4. `vector`의 원소 접근

`vector` 원소는 배열처럼 접근할 수 있다.

```cpp
std::vector<int> v = {10, 20, 30, 40, 50};

v[0];    // 10
v[4];    // 50
v.at(2); // 30
```

`[]`와 `at()`의 차이는 경계 검사 여부다.

| 방식 | 경계 검사 | 특징 |
|---|---|---|
| `v[i]` | 없음 | 빠르지만 잘못된 인덱스 접근은 미정의 동작이다. |
| `v.at(i)` | 있음 | 범위를 벗어나면 `std::out_of_range` 예외가 발생한다. |

```cpp
try {
    v.at(10);
} catch (const std::out_of_range& e) {
    std::cout << e.what();
}
```

값 수정도 같은 방식으로 한다.

```cpp
v[1] = 99;
v.at(3) = 77;

for (auto& x : v) {
    x *= 2;
}
```

범위 기반 `for`에서 원본을 수정하려면 반드시 참조를 사용해야 한다.

```cpp
for (auto x : v) {
    x *= 2; // 복사본만 수정
}

for (auto& x : v) {
    x *= 2; // 원본 수정
}
```

## 5. `size`, `capacity`, `reserve`, `resize`

`vector`를 이해할 때 `size`와 `capacity`를 구분해야 한다.

| 개념 | 의미 |
|---|---|
| `size()` | 현재 실제 원소 개수 |
| `capacity()` | 재할당 없이 담을 수 있도록 확보된 공간 |

```cpp
std::vector<int> v;

v.size();     // 0
v.capacity(); // 0

v.push_back(1);
v.push_back(2);
v.push_back(3);

v.size();     // 3
v.capacity(); // 구현마다 다름
```

`capacity`가 부족한 상태에서 `push_back`을 하면 내부적으로 다음 일이 일어난다.

```text
1. 더 큰 배열을 새로 할당한다.
2. 기존 원소를 새 배열로 복사 또는 이동한다.
3. 기존 배열을 해제한다.
4. 새 원소를 뒤에 추가한다.
```

이 재할당은 비용이 크다. 원소 개수를 미리 예상할 수 있다면 `reserve()`로 공간을 먼저 확보한다.

```cpp
std::vector<int> v;
v.reserve(1000);

for (int i = 0; i < 1000; ++i) {
    v.push_back(i);
}
```

`reserve()`는 원소 개수를 바꾸지 않는다. 공간만 미리 잡는다.

```cpp
std::vector<int> v;
v.reserve(5);

v.size();     // 0
v.capacity(); // 5 이상
```

반면 `resize()`는 실제 원소 개수를 바꾼다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};

v.resize(3);
// {1, 2, 3}

v.resize(6, 0);
// {1, 2, 3, 0, 0, 0}

v.clear();
// size는 0, capacity는 보통 유지
```

정리하면 다음과 같다.

| 함수 | 바꾸는 대상 | 원소 생성/삭제 |
|---|---|---|
| `reserve(n)` | capacity | 하지 않음 |
| `resize(n)` | size | 필요하면 원소를 만들거나 삭제함 |
| `clear()` | size | 모든 원소를 제거하지만 capacity는 보통 유지 |

## 6. `std::list`

`std::list`는 **이중 연결 리스트**다. 각 원소가 앞 노드와 뒤 노드의 주소를 가지고 있고, 원소들이 메모리에 연속적으로 놓이지 않는다.

```text
vector:
[10 | 20 | 30 | 40]

list:
[prev | 10 | next] <-> [prev | 20 | next] <-> [prev | 30 | next]
```

기본 조작은 다음과 같다.

```cpp
#include <list>

std::list<int> lst = {20, 30};

lst.push_front(10); // {10, 20, 30}
lst.push_back(40);  // {10, 20, 30, 40}

lst.pop_front();    // {20, 30, 40}
lst.pop_back();     // {20, 30}

lst.front(); // 20
lst.back();  // 30
```

`list`는 앞과 뒤에서 모두 O(1)로 삽입과 삭제가 가능하다. 또한 이미 위치를 알고 있다면 중간 삽입과 삭제도 O(1)이다.

```cpp
std::list<int> lst = {10, 30, 40};

auto it = std::find(lst.begin(), lst.end(), 30);
lst.insert(it, 20);
// {10, 20, 30, 40}
```

하지만 여기서 주의할 점이 있다. `insert` 자체는 O(1)이지만, `30`을 찾는 `find`는 앞에서부터 순서대로 보므로 O(n)이다. 즉 위치를 이미 알고 있을 때 list의 중간 삽입이 빠르다.

`list`는 자체 멤버 알고리즘도 제공한다.

```cpp
std::list<int> lst = {30, 10, 40, 20, 10, 30};

lst.sort();    // 오름차순 정렬
lst.reverse(); // 역순
lst.unique();  // 연속 중복 제거
```

`std::sort(lst.begin(), lst.end())`는 사용할 수 없다. `std::sort`는 random access iterator가 필요하지만, `list` iterator는 bidirectional iterator이기 때문이다. 그래서 `list`는 `lst.sort()`를 사용한다.

`splice`는 list 고유의 강력한 기능이다.

```cpp
std::list<int> a = {1, 2, 3, 4, 5};
std::list<int> b = {10, 20, 30};

auto pos = std::find(a.begin(), a.end(), 3);
a.splice(pos, b);

// a: {1, 2, 10, 20, 30, 3, 4, 5}
// b: {}
```

`splice`는 원소를 복사하지 않고 노드 연결만 바꾼다. 그래서 구간 이동을 효율적으로 처리할 수 있다.

## 7. `std::array`

`std::array`는 **크기가 컴파일 타임에 고정된 배열**이다. C 배열과 비슷한 성능을 가지면서 STL 컨테이너 인터페이스를 제공한다.

```cpp
#include <array>

std::array<int, 5> a = {1, 2, 3, 4, 5};

a[0];     // 1
a.at(2);  // 3
a.front(); // 1
a.back();  // 5
a.size();  // 5
```

`std::array<int, 5>`에서 크기 `5`는 타입에 포함된다. 따라서 `std::array<int, 5>`와 `std::array<int, 3>`은 서로 다른 타입이다.

```cpp
void print(const std::array<int, 5>& a) {
    for (const auto& x : a) {
        std::cout << x << " ";
    }
}
```

`array`는 `fill`, `swap`, `data` 같은 기능을 제공한다.

```cpp
std::array<int, 5> a = {1, 2, 3, 4, 5};
std::array<int, 5> b = {6, 7, 8, 9, 10};

a.fill(0);
a.swap(b);

int* p = a.data();
```

`data()`는 첫 원소의 raw pointer를 반환한다. 그래서 C 스타일 함수를 호출할 때도 사용할 수 있다.

```cpp
void legacy_print(const int* arr, int n);

legacy_print(a.data(), a.size());
```

## 8. 시퀀스 컨테이너 선택 기준

시퀀스 컨테이너는 원소의 순서를 저장하는 컨테이너다. 대표적으로 `vector`, `array`, `list`가 있다.

| 컨테이너 | 메모리 구조 | 임의 접근 | 앞 삽입 | 중간 삽입 | 대표 상황 |
|---|---|---|---|---|---|
| `vector` | 연속 메모리 | O(1) | O(n) | O(n) | 대부분의 기본 선택 |
| `array` | 고정 연속 메모리 | O(1) | 불가 | 불가 | 크기가 컴파일 타임에 고정 |
| `list` | 노드 기반 연결 구조 | 불가 | O(1) | 위치를 알면 O(1) | 중간 삽입/삭제와 iterator 유지가 중요 |

선택 흐름은 다음과 같다.

```text
순서 있는 데이터를 저장한다.

1. 크기가 컴파일 타임에 고정인가?
   -> std::array<T, N>

2. 끝에서 추가/삭제가 주된 작업인가?
   -> std::vector<T>

3. 중간 삽입/삭제가 잦고 기존 iterator를 유지해야 하는가?
   -> std::list<T>
```

실무와 시험 모두에서 가장 중요한 결론은 다음이다.

```text
특별한 이유가 없으면 vector가 기본 선택이다.
list는 중간 삽입/삭제가 많다는 이유만으로 항상 빠른 것이 아니다.
list는 임의 접근이 안 되고 캐시 효율도 낮으므로 실제 성능은 상황에 따라 달라진다.
```

## 9. 이터레이터

이터레이터(iterator)는 컨테이너의 원소를 가리키는 객체다. 포인터처럼 `*it`로 값을 읽고, `++it`로 다음 원소로 이동한다.

```cpp
std::vector<int> v = {10, 20, 30, 40, 50};

std::vector<int>::iterator it = v.begin();

*it;  // 10
++it;
*it;  // 20
```

보통은 타입을 직접 쓰지 않고 `auto`를 사용한다.

```cpp
auto it = v.begin();
```

`begin()`과 `end()`는 STL 순회의 기본이다.

```cpp
std::vector<int> v = {10, 20, 30};

auto first = v.begin(); // 첫 번째 원소
auto last = v.end();    // 마지막 원소 다음 위치

for (auto it = v.begin(); it != v.end(); ++it) {
    std::cout << *it << " ";
}
```

`end()`는 마지막 원소가 아니다. **마지막 원소의 다음 위치**다.

```text
begin()          end()
  ↓               ↓
[10 | 20 | 30 |  x]
```

따라서 `*v.end()`는 잘못된 코드다. `end()`는 범위의 경계를 나타내는 sentinel 역할을 한다. 포인터에서 못 찾은 결과를 `nullptr`로 표현하듯, STL 알고리즘은 못 찾은 결과를 `end()`로 표현한다.

```cpp
auto it = std::find(v.begin(), v.end(), 99);

if (it != v.end()) {
    std::cout << *it;
} else {
    std::cout << "없음";
}
```

## 10. 이터레이터 카테고리

이터레이터는 지원하는 연산에 따라 카테고리가 나뉜다. 알고리즘이 어떤 iterator를 요구하는지 이해해야 컨테이너별 제약을 알 수 있다.

| 카테고리 | 주요 연산 | 대표 예 |
|---|---|---|
| Input | 읽기, `++`, `==`, `!=` | `istream_iterator` |
| Output | 쓰기, `++` | `ostream_iterator` |
| Forward | input + 다중 패스 | `forward_list` |
| Bidirectional | forward + `--` | `list`, `set`, `map` |
| Random Access | bidirectional + `+n`, `-n`, `[]`, `<` | `vector`, `array`, `deque` |

예를 들어 `vector` iterator는 random access iterator다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};

auto it = v.begin();
it += 3;
std::cout << *it; // 4
```

반면 `list` iterator는 bidirectional iterator다.

```cpp
std::list<int> lst = {1, 2, 3, 4, 5};

auto it = lst.begin();
++it;
--it;

// it += 3; // 오류: list iterator는 random access가 아님
```

이 차이 때문에 `std::sort`는 `vector`에는 사용할 수 있지만 `list`에는 사용할 수 없다.

## 11. 범위 기반 for, const iterator, reverse iterator

C++11부터는 범위 기반 `for`를 사용해 iterator를 직접 쓰지 않고도 순회할 수 있다.

```cpp
std::vector<int> v = {10, 20, 30};

for (const auto& x : v) {
    std::cout << x << " ";
}
```

순회 방식은 세 가지로 구분해서 기억하면 좋다.

| 형태 | 의미 | 원본 수정 |
|---|---|---|
| `auto x` | 값을 복사해서 순회 | 불가 |
| `auto& x` | 참조로 순회 | 가능 |
| `const auto& x` | 읽기 전용 참조로 순회 | 불가 |

읽기만 할 때는 보통 `const auto&`가 좋다. 복사를 피하면서 원본을 바꾸지 않겠다는 의도도 드러난다.

iterator도 읽기 전용과 역방향 순회를 지원한다.

| 함수 | iterator 종류 | 방향 | 수정 가능 |
|---|---|---|---|
| `begin()`, `end()` | iterator | 정방향 | 가능 |
| `cbegin()`, `cend()` | const_iterator | 정방향 | 불가 |
| `rbegin()`, `rend()` | reverse_iterator | 역방향 | 가능 |
| `crbegin()`, `crend()` | const_reverse_iterator | 역방향 | 불가 |

```cpp
std::vector<int> v = {10, 20, 30, 40, 50};

for (auto it = v.rbegin(); it != v.rend(); ++it) {
    std::cout << *it << " ";
}
// 50 40 30 20 10
```

## 12. `std::set`

`std::set`은 **중복을 허용하지 않는 정렬 집합**이다. 원소를 넣으면 자동으로 정렬된 상태를 유지하고, 중복 삽입은 무시된다.

```cpp
#include <set>

std::set<int> s;

s.insert(30);
s.insert(10);
s.insert(20);
s.insert(10); // 중복 무시

for (int x : s) {
    std::cout << x << " ";
}
// 10 20 30
```

검색과 삭제는 O(log n)이다.

```cpp
std::set<int> s = {10, 20, 30, 40, 50};

auto it = s.find(30);
if (it != s.end()) {
    std::cout << *it;
}

s.count(30); // 있으면 1, 없으면 0
s.erase(20);
```

`std::find(s.begin(), s.end(), 30)`도 가능하지만, set에서는 `s.find(30)`을 쓰는 것이 좋다. `std::find`는 선형 탐색 O(n)이고, `set::find`는 트리 구조를 이용해 O(log n)에 찾는다.

set의 활용 패턴은 다음과 같다.

```cpp
std::vector<int> data = {3, 1, 4, 1, 5, 9, 2, 6, 5};

std::set<int> s(data.begin(), data.end());
std::vector<int> unique_data(s.begin(), s.end());
// {1, 2, 3, 4, 5, 6, 9}
```

방문 여부 확인에도 자주 사용한다.

```cpp
std::set<int> visited;

visited.insert(3);
visited.insert(5);

if (visited.count(5)) {
    std::cout << "이미 방문";
}
```

## 13. `std::map`

`std::map`은 **키(key)로 값(value)을 찾는 사전형 컨테이너**다. 배열이 정수 인덱스로 값을 찾는다면, map은 문자열, 정수, 객체 등 다양한 키로 값을 찾는다.

```cpp
#include <map>
#include <string>

std::map<std::string, int> score;

score["Alice"] = 95;
score["Bob"] = 88;

std::cout << score["Alice"]; // 95
```

`map`의 각 원소는 `std::pair<const Key, Value>` 형태로 저장된다.

```cpp
std::map<std::string, int> score = {
    {"Alice", 95},
    {"Bob", 88}
};

auto it = score.begin();

it->first;  // key
it->second; // value
```

순회할 때는 C++17 구조화 바인딩을 쓰면 읽기 쉽다.

```cpp
for (const auto& [name, s] : score) {
    std::cout << name << ": " << s << "\n";
}
```

값을 수정하려면 참조로 받아야 한다.

```cpp
for (auto& [name, s] : score) {
    s += 5;
}
```

## 14. `map`의 삽입과 `[]` 주의점

`map`에는 여러 삽입 방식이 있다.

```cpp
std::map<std::string, int> m;

m.insert({"Dave", 85});
m.emplace("Alice", 95);
m.try_emplace("Bob", 88);
m.insert_or_assign("Alice", 100);
```

| 메서드 | 이미 있는 키 | 없는 키 |
|---|---|---|
| `insert` | 무시 | 삽입 |
| `try_emplace` | 무시 | 삽입 |
| `insert_or_assign` | 갱신 | 삽입 |
| `operator[]` | 갱신 | 기본값으로 삽입 |

`[]`는 편리하지만 읽기에서 함정이 있다.

```cpp
std::map<std::string, int> m;

m["Alice"] = 95;

std::cout << m["Nobody"]; // 0 출력
std::cout << m.size();    // Nobody가 추가되어 size 증가
```

없는 키를 `[]`로 읽으면 기본값을 넣어버린다. 따라서 읽기에는 `at()` 또는 `find()`를 사용하는 것이 안전하다.

```cpp
std::map<std::string, int> m = {
    {"Alice", 95},
    {"Bob", 88}
};

try {
    std::cout << m.at("Nobody");
} catch (const std::out_of_range&) {
    std::cout << "키 없음";
}

auto it = m.find("Bob");
if (it != m.end()) {
    std::cout << it->second;
}
```

## 15. `map`의 범위 조회와 빈도 카운팅

`map`은 키 순서로 정렬되어 있으므로 범위 조회가 가능하다.

```cpp
std::map<int, std::string> m = {
    {10, "A"}, {20, "B"}, {30, "C"}, {40, "D"}
};

for (auto it = m.lower_bound(20);
     it != m.upper_bound(30);
     ++it) {
    std::cout << it->first << " ";
}
// 20 30
```

| 함수 | 의미 |
|---|---|
| `lower_bound(key)` | key 이상인 첫 iterator |
| `upper_bound(key)` | key 초과인 첫 iterator |

`map`의 대표 활용은 빈도 카운팅이다.

```cpp
std::vector<std::string> words = {
    "apple", "banana", "apple",
    "cherry", "banana", "apple"
};

std::map<std::string, int> freq;

for (const auto& w : words) {
    freq[w]++;
}

// apple: 3, banana: 2, cherry: 1
```

이 경우에는 `freq[w]++`가 좋은 사용이다. 없는 단어는 자동으로 0으로 삽입된 뒤 1 증가하기 때문이다.

## 16. 연관 컨테이너 비교

`set`과 `map`은 모두 연관 컨테이너다. 원소가 키 순서로 정렬되어 있고, 삽입/검색/삭제가 O(log n)이다.

| 컨테이너 | 중복 키 | `[]` 사용 | 주 용도 |
|---|---|---|---|
| `set<T>` | 불가 | 불가 | 중복 없는 집합, 존재 여부 확인 |
| `map<K, V>` | 불가 | 가능 | 키-값 저장, 빠른 검색 |

선택 기준은 다음과 같다.

```text
중복 없는 원소 집합이 필요한가?
-> set<T>

키로 값을 찾아야 하는가?
-> map<K, V>

순서가 필요 없고 평균 O(1) 검색이 더 중요한가?
-> unordered_set 또는 unordered_map 고려
```

## 17. STL 알고리즘의 공통 패턴

STL 알고리즘은 컨테이너 자체가 아니라 **iterator 범위**를 받는다.

```cpp
std::sort(v.begin(), v.end());
std::find(v.begin(), v.end(), 30);
std::count_if(v.begin(), v.end(), [](int x){ return x > 0; });
```

이 패턴 덕분에 알고리즘은 컨테이너 종류와 분리된다. 다만 모든 알고리즘이 모든 iterator에서 동작하는 것은 아니다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5};
std::list<int> l = {3, 1, 4, 1, 5};

std::sort(v.begin(), v.end()); // 가능
// std::sort(l.begin(), l.end()); // 불가

l.sort(); // list 전용 정렬
```

대표 알고리즘은 다음과 같다.

| 분류 | 대표 함수 | 헤더 |
|---|---|---|
| 검색 | `find`, `find_if`, `find_if_not`, `count`, `count_if`, `any_of`, `all_of`, `none_of` | `<algorithm>` |
| 정렬 | `sort`, `stable_sort`, `partial_sort`, `nth_element`, `is_sorted` | `<algorithm>` |
| 변환 | `transform`, `copy`, `copy_if`, `fill`, `generate` | `<algorithm>` |
| 제거 | `remove`, `remove_if`, `unique` | `<algorithm>` |
| 순회/뒤집기 | `for_each`, `reverse` | `<algorithm>` |
| 이진 검색 | `binary_search`, `lower_bound`, `upper_bound` | `<algorithm>` |
| 집계 | `accumulate`, `max_element`, `min_element`, `minmax_element`, `iota` | `<numeric>` |

## 18. 검색 알고리즘

`find`는 특정 값과 같은 첫 원소를 찾는다.

```cpp
std::vector<int> v = {10, 20, 30, 40, 50};

auto it = std::find(v.begin(), v.end(), 30);

if (it != v.end()) {
    std::cout << *it;              // 30
    std::cout << (it - v.begin()); // 2
}
```

`find_if`는 조건을 만족하는 첫 원소를 찾는다.

```cpp
auto it = std::find_if(v.begin(), v.end(),
    [](int x){ return x > 25; });

// *it == 30
```

검색 계열의 차이는 다음과 같다.

| 함수 | 반환 | 의미 |
|---|---|---|
| `find` | iterator | 특정 값과 같은 첫 원소 |
| `find_if` | iterator | 조건을 만족하는 첫 원소 |
| `find_if_not` | iterator | 조건을 만족하지 않는 첫 원소 |
| `count` | 정수 | 특정 값의 개수 |
| `count_if` | 정수 | 조건을 만족하는 원소 개수 |
| `any_of` | bool | 하나라도 조건을 만족하는가 |
| `all_of` | bool | 모두 조건을 만족하는가 |
| `none_of` | bool | 아무도 조건을 만족하지 않는가 |

## 19. 정렬 알고리즘

정렬 알고리즘은 모두 iterator 범위를 받는다. 가장 기본은 `std::sort`이며, 오름차순 정렬이 기본 동작이다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

std::sort(v.begin(), v.end());
// {1, 1, 2, 3, 4, 5, 6, 9}
```

`sort`의 세 번째 인자로 비교 기준을 전달하면 정렬 방향이나 기준을 바꿀 수 있다.

```cpp
std::sort(v.begin(), v.end(), std::greater<int>());
// {9, 6, 5, 4, 3, 2, 1, 1}

std::sort(v.begin(), v.end(),
    [](int a, int b){ return a > b; });
// 람다로 직접 내림차순 기준 전달
```

비교 함수는 “앞 원소가 뒤 원소보다 먼저 와야 하는가?”를 `bool`로 반환한다.

```cpp
[](int a, int b) {
    return a > b;
}
```

이 람다는 `a`가 `b`보다 앞에 와야 할 조건을 뜻한다. `a > b`이면 큰 값이 앞에 오므로 내림차순이 된다.

`stable_sort`는 정렬 기준이 같은 원소들의 **기존 상대 순서**를 유지한다. 예를 들어 같은 점수의 학생들이 원래 `A`, `B` 순서였다면, 점수 기준 정렬 후에도 `A`, `B` 순서가 유지된다.

```cpp
struct Student {
    std::string name;
    int score;
};

std::vector<Student> students = {
    {"A", 90}, {"B", 90}, {"C", 80}
};

std::stable_sort(students.begin(), students.end(),
    [](const Student& a, const Student& b) {
        return a.score > b.score;
    });

// score가 같은 A와 B의 상대 순서 유지
// 결과 순서: A(90), B(90), C(80)
```

`partial_sort`는 전체를 정렬하지 않고, 앞쪽 N개만 정렬된 상태로 만든다. “상위 3개만 필요하다”처럼 전체 정렬이 낭비인 상황에 쓴다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

std::partial_sort(v.begin(), v.begin() + 3, v.end());

// 앞 3개는 정렬된 최소 3개
// {1, 1, 2, ...}
// 나머지 뒤쪽 순서는 보장하지 않음
```

`nth_element`는 n번째 위치에 들어갈 원소만 제자리로 보낸다. 전체 정렬이 아니라 “n번째 기준으로 왼쪽은 작거나 같고, 오른쪽은 크거나 같은 상태”를 만든다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

std::nth_element(v.begin(), v.begin() + 3, v.end());

// v[3]에는 정렬했을 때 4번째에 올 원소가 위치
// v[3] 왼쪽은 v[3] 이하
// v[3] 오른쪽은 v[3] 이상
// 전체가 정렬된 것은 아님
```

`is_sorted`는 범위가 이미 정렬되어 있는지 확인한다.

```cpp
std::vector<int> a = {1, 2, 3, 4, 5};
std::vector<int> b = {3, 1, 2};

std::is_sorted(a.begin(), a.end()); // true
std::is_sorted(b.begin(), b.end()); // false
```

정렬 계열은 이렇게 구분한다.

| 함수 | 결과 | 주 용도 |
|---|---|---|
| `sort` | 전체 정렬 | 일반적인 정렬 |
| `stable_sort` | 전체 정렬 + 같은 원소의 기존 순서 유지 | 점수는 같지만 입력 순서를 보존해야 할 때 |
| `partial_sort` | 앞 N개만 정렬 | 상위 N개 또는 하위 N개만 필요할 때 |
| `nth_element` | n번째 원소만 제자리 배치 | 중앙값, 상위 기준값처럼 순위 위치만 필요할 때 |
| `is_sorted` | 정렬 여부를 bool로 반환 | 정렬 전제 알고리즘 사용 전 확인 |

## 20. 변환 알고리즘

`transform`은 각 원소에 함수를 적용해 결과를 저장한다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};
std::vector<int> result(v.size());

std::transform(v.begin(), v.end(),
               result.begin(),
               [](int x){ return x * x; });

// result: {1, 4, 9, 16, 25}
```

제자리 변환도 가능하다.

```cpp
std::transform(v.begin(), v.end(),
               v.begin(),
               [](int x){ return x * 2; });
// v: {2, 4, 6, 8, 10}
```

두 범위를 함께 읽어서 새 결과를 만들 수도 있다.

```cpp
std::vector<int> a = {1, 2, 3};
std::vector<int> b = {4, 5, 6};
std::vector<int> c(3);

std::transform(a.begin(), a.end(),
               b.begin(),
               c.begin(),
               [](int x, int y){ return x + y; });

// c: {5, 7, 9}
```

`copy`는 범위를 그대로 복사한다. 이때 목적지에는 충분한 공간이 있어야 한다.

```cpp
std::vector<int> src = {1, 2, 3, 4, 5};
std::vector<int> dst(5);

std::copy(src.begin(), src.end(), dst.begin());
// dst: {1, 2, 3, 4, 5}
```

조건을 만족하는 원소만 복사할 때는 `copy_if`와 `back_inserter`를 자주 함께 쓴다. 조건을 만족하는 원소 개수를 미리 알기 어렵기 때문이다.

```cpp
std::vector<int> src = {1, 2, 3, 4, 5};
std::vector<int> evens;

std::copy_if(src.begin(), src.end(),
             std::back_inserter(evens),
             [](int x){ return x % 2 == 0; });
// evens: {2, 4}
```

`fill`은 이미 존재하는 범위를 같은 값으로 채운다.

```cpp
std::vector<int> dst(5);

std::fill(dst.begin(), dst.end(), 0);
// dst: {0, 0, 0, 0, 0}
```

`generate`는 함수를 호출한 결과로 범위를 채운다.

```cpp
std::vector<int> dst(5);
int n = 0;

std::generate(dst.begin(), dst.end(),
              [&n]{ return n++; });

// dst: {0, 1, 2, 3, 4}
```

정리하면 다음과 같다.

| 함수 | 역할 | 주의점 |
|---|---|---|
| `transform` | 원소를 변환해 다른 범위 또는 자기 자신에 저장 | 목적지 iterator가 유효해야 함 |
| `copy` | 범위를 그대로 복사 | 목적지 크기 확보 필요 |
| `copy_if` | 조건을 만족하는 원소만 복사 | 결과 개수를 모르면 `back_inserter` 사용 |
| `fill` | 이미 있는 범위를 같은 값으로 채움 | 새 원소를 추가하지는 않음 |
| `generate` | 함수 호출 결과로 범위를 채움 | 람다 캡처로 상태를 만들 수 있음 |

## 21. 제거와 중복 처리 알고리즘

`remove`와 `unique`는 이름과 다르게 실제 컨테이너 크기를 줄이지 않는다.

```cpp
std::vector<int> v = {1, 2, 3, 2, 4, 2, 5};

auto new_end = std::remove(v.begin(), v.end(), 2);

v.erase(new_end, v.end());
// {1, 3, 4, 5}
```

보통은 한 줄로 쓴다.

```cpp
v.erase(std::remove(v.begin(), v.end(), 2), v.end());
```

이것을 erase-remove 관용구라고 한다. `std::remove`는 지울 값을 뒤로 밀고, “남겨야 할 원소들의 끝”을 반환한다. 그래서 컨테이너 크기를 실제로 줄이는 작업은 `erase`가 맡는다.

`remove_if`는 조건으로 제거 대상을 정한다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5, 6};

v.erase(
    std::remove_if(v.begin(), v.end(),
        [](int x){ return x % 2 == 0; }),
    v.end());

// v: {1, 3, 5}
```

중복 제거는 `sort`와 `unique`를 조합한다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6, 5};

std::sort(v.begin(), v.end());
v.erase(std::unique(v.begin(), v.end()), v.end());
// {1, 2, 3, 4, 5, 6, 9}
```

`unique`는 **연속된 중복**만 처리한다. 따라서 전체 중복을 제거하려면 먼저 정렬해서 같은 값들이 붙어 있게 만든 뒤 `unique`를 적용한다.

| 함수 | 실제 삭제 여부 | 핵심 |
|---|---|---|
| `remove` | 삭제하지 않음 | 특정 값을 뒤쪽으로 밀고 새 끝 iterator 반환 |
| `remove_if` | 삭제하지 않음 | 조건을 만족하는 원소를 제거 대상으로 처리 |
| `unique` | 삭제하지 않음 | 연속 중복을 뒤쪽으로 밀고 새 끝 iterator 반환 |
| `erase` | 실제 삭제 | 컨테이너 크기를 줄임 |

## 22. 순회, 뒤집기, 이진 검색

`for_each`는 각 원소에 동작을 적용한다. 단순 출력에도 쓸 수 있고, 참조 매개변수를 사용하면 원소 수정도 가능하다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};

std::for_each(v.begin(), v.end(),
    [](int x){ std::cout << x << " "; });
// 1 2 3 4 5

std::for_each(v.begin(), v.end(),
    [](int& x){ x *= 2; });
// v: {2, 4, 6, 8, 10}
```

`reverse`는 범위의 순서를 뒤집는다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};

std::reverse(v.begin(), v.end());
// v: {5, 4, 3, 2, 1}

std::string s = "hello";
std::reverse(s.begin(), s.end());
// s: "olleh"
```

`binary_search`, `lower_bound`, `upper_bound`는 정렬된 범위에서만 올바르게 동작한다.

```cpp
std::vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8, 9};

std::binary_search(v.begin(), v.end(), 5);  // true
std::binary_search(v.begin(), v.end(), 99); // false

auto lb = std::lower_bound(v.begin(), v.end(), 5);
auto ub = std::upper_bound(v.begin(), v.end(), 5);

// *lb == 5
// *ub == 6
```

| 함수 | 반환 | 의미 |
|---|---|---|
| `binary_search` | bool | 값이 존재하는지 여부 |
| `lower_bound` | iterator | key 이상인 첫 위치 |
| `upper_bound` | iterator | key 초과인 첫 위치 |

값이 없으면 `lower_bound`도 `end()`를 반환할 수 있다.

```cpp
auto it = std::lower_bound(v.begin(), v.end(), 99);

if (it == v.end()) {
    std::cout << "없음\n";
}
```

## 23. 집계 알고리즘

`accumulate`는 범위를 하나의 값으로 접는다.

```cpp
#include <numeric>

std::vector<int> v = {1, 2, 3, 4, 5};

int sum = std::accumulate(v.begin(), v.end(), 0);
// 15

int product = std::accumulate(v.begin(), v.end(), 1,
    [](int acc, int x){ return acc * x; });
// 120
```

`accumulate`의 세 번째 인자는 **초기값**이다. 합계에서는 0, 곱에서는 1처럼 연산의 항등원을 넣어야 자연스럽다.

```cpp
int wrong_product = std::accumulate(v.begin(), v.end(), 0,
    [](int acc, int x){ return acc * x; });

// 0에서 곱하기 시작하므로 결과는 항상 0
```

문자열 연결도 가능하다.

```cpp
std::vector<std::string> words = {"C++", " ", "STL"};

std::string sentence = std::accumulate(
    words.begin(), words.end(), std::string{});

// sentence == "C++ STL"
```

최댓값과 최솟값은 iterator로 반환된다.

```cpp
std::vector<int> v = {3, 1, 4, 1, 5, 9, 2, 6};

auto max_it = std::max_element(v.begin(), v.end());
auto min_it = std::min_element(v.begin(), v.end());

std::cout << *max_it;              // 9
std::cout << (max_it - v.begin()); // 5
std::cout << *min_it;              // 1
```

최솟값과 최댓값을 한 번에 찾고 싶으면 `minmax_element`를 쓴다.

```cpp
auto [lo, hi] = std::minmax_element(v.begin(), v.end());

std::cout << *lo << ", " << *hi;
// 1, 9
```

`iota`는 순차 값을 채운다.

```cpp
std::vector<int> v(5);
std::iota(v.begin(), v.end(), 1);
// {1, 2, 3, 4, 5}
```

집계 계열은 다음처럼 정리할 수 있다.

| 함수 | 반환 | 의미 |
|---|---|---|
| `accumulate` | 누적 결과값 | 범위를 하나의 값으로 접음 |
| `max_element` | iterator | 최댓값 위치 |
| `min_element` | iterator | 최솟값 위치 |
| `minmax_element` | pair 형태의 iterator 두 개 | 최솟값 위치와 최댓값 위치 |
| `iota` | 없음 | 범위에 순차 값을 채움 |

## 24. 함수 객체와 람다

STL 알고리즘은 조건이나 동작을 함수처럼 받는다. 이때 함수 객체(functor)나 람다를 사용할 수 있다.

함수 객체는 `operator()`를 정의한 객체다.

```cpp
struct IsEven {
    bool operator()(int x) const {
        return x % 2 == 0;
    }
};

std::vector<int> v = {1, 2, 3, 4, 5, 6};

int cnt = std::count_if(v.begin(), v.end(), IsEven{});
// 3
```

상태를 가진 함수 객체도 만들 수 있다.

```cpp
struct GreaterThan {
    int threshold;

    GreaterThan(int t) : threshold(t) {}

    bool operator()(int x) const {
        return x > threshold;
    }
};

auto it = std::find_if(v.begin(), v.end(), GreaterThan{3});
// *it == 4
```

표준 라이브러리는 자주 쓰는 함수 객체를 `<functional>`에 제공한다.

```cpp
#include <functional>

std::sort(v.begin(), v.end(), std::greater<int>());
```

람다는 이름 없는 함수 객체에 가깝다. 알고리즘 호출 위치에서 바로 조건을 정의할 수 있다.

```cpp
std::sort(v.begin(), v.end(),
    [](int a, int b){ return a > b; });

auto it = std::find_if(v.begin(), v.end(),
    [](int x){ return x > 3; });
```

람다 기본 문법은 다음과 같다.

```cpp
[캡처](매개변수) -> 반환타입 { 본문 }
```

반환 타입은 생략할 수 있다.

```cpp
[](int x){ return x * 2; }
[](int a, int b){ return a > b; }
[](int x) -> bool { return x > 0; }
[]{ return 42; }
```

외부 변수를 쓰려면 캡처가 필요하다.

```cpp
int threshold = 30;
std::vector<int> v = {10, 20, 30, 40, 50};

auto it = std::find_if(v.begin(), v.end(),
    [threshold](int x){ return x > threshold; });
```

캡처 방식은 다음처럼 구분한다.

| 캡처 | 의미 |
|---|---|
| `[]` | 외부 변수 사용 안 함 |
| `[x]` | `x`를 값으로 복사 |
| `[&x]` | `x`를 참조로 캡처 |
| `[=]` | 사용하는 외부 변수를 기본적으로 값 캡처 |
| `[&]` | 사용하는 외부 변수를 기본적으로 참조 캡처 |
| `[=, &x]` | 기본은 값 캡처, `x`만 참조 캡처 |
| `[&, x]` | 기본은 참조 캡처, `x`만 값 캡처 |

## 25. 알고리즘 조합 예제

STL의 진짜 힘은 여러 알고리즘을 조합할 때 드러난다.

```cpp
#include <algorithm>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

struct Student {
    std::string name;
    int score;
};

int main() {
    std::vector<Student> students = {
        {"Alice", 85}, {"Bob", 92}, {"Carol", 78},
        {"Dave", 96}, {"Eve", 70}, {"Frank", 88}
    };

    std::sort(students.begin(), students.end(),
        [](const Student& a, const Student& b) {
            return a.score > b.score;
        });

    int pass = std::count_if(students.begin(), students.end(),
        [](const Student& s) {
            return s.score >= 80;
        });

    int total = std::accumulate(students.begin(), students.end(), 0,
        [](int acc, const Student& s) {
            return acc + s.score;
        });

    double avg = static_cast<double>(total) / students.size();

    std::vector<Student> top;
    std::copy_if(students.begin(), students.end(),
        std::back_inserter(top),
        [](const Student& s) {
            return s.score >= 90;
        });

    std::cout << "합격: " << pass << "명\n";
    std::cout << "평균: " << avg << "\n";

    for (const auto& s : top) {
        std::cout << s.name << "(" << s.score << ")\n";
    }
}
```

이 예제에는 STL의 핵심 패턴이 모두 들어 있다.

| 작업 | 사용한 기능 |
|---|---|
| 점수 내림차순 정렬 | `sort` + 이항 비교 람다 |
| 80점 이상 학생 수 | `count_if` + 단항 조건 람다 |
| 전체 평균 계산 | `accumulate` + 누적 람다 |
| 90점 이상 학생 추출 | `copy_if` + `back_inserter` |
| 결과 순회 | 범위 기반 `for` |

## 마지막 핵심 정리

| 개념 | 꼭 기억할 점 |
|---|---|
| STL | 컨테이너, 이터레이터, 알고리즘, 함수 객체/람다가 연결된 구조 |
| `vector` | 연속 메모리 동적 배열, 대부분의 기본 선택 |
| `reserve` | capacity만 확보하고 size는 바꾸지 않음 |
| `resize` | 실제 원소 개수를 바꿈 |
| `list` | 중간 삽입/삭제 위치를 알고 있으면 O(1), 임의 접근은 불가 |
| `array` | 크기가 타입에 포함되는 고정 크기 배열 |
| `begin()` | 첫 원소를 가리킴 |
| `end()` | 마지막 원소 다음 위치, 역참조 금지 |
| iterator category | 알고리즘 사용 가능 여부를 결정 |
| `set` | 중복 없는 정렬 집합, 존재 확인에 유리 |
| `map` | 키-값 저장소, `[]` 읽기는 자동 삽입 주의 |
| `sort` | 전체 정렬, random access iterator 필요 |
| `stable_sort` | 같은 기준값을 가진 원소의 기존 상대 순서 유지 |
| `partial_sort` | 앞 N개만 정렬해 상위/하위 일부만 필요할 때 사용 |
| `nth_element` | n번째 위치의 원소만 제자리로 보내며 전체 정렬은 아님 |
| `remove`/`unique` | 실제 삭제가 아니므로 `erase`와 함께 사용 |
| `binary_search` | 정렬된 범위에서만 올바르게 동작 |
| `accumulate` | 초기값에서 시작해 범위를 하나의 값으로 누적 |
| `max_element`/`minmax_element` | 값이 아니라 iterator를 반환 |
| 람다 | 알고리즘에 조건과 동작을 즉석에서 전달하는 문법 |

## Study Guide

이 자료는 API를 전부 암기하는 방식보다 **선택 기준과 반복 패턴**을 먼저 잡는 것이 좋다.

1. 먼저 `vector`, `list`, `array`의 메모리 구조와 시간 복잡도를 비교한다.
2. 그다음 `begin()`과 `end()`가 `[first, last)` 범위를 만든다는 점을 익힌다.
3. `find`, `sort`, `count_if`, `transform`, `accumulate`처럼 자주 쓰는 알고리즘을 같은 iterator 범위 패턴으로 읽는다.
4. `sort`/`stable_sort`/`partial_sort`/`nth_element`의 결과 차이를 예제로 구분한다.
5. `set::find`와 `std::find`의 차이, `map["key"]`의 자동 삽입, `remove`가 실제 삭제가 아니라는 점을 따로 표시해 둔다.
6. `accumulate`의 초기값, `binary_search`의 정렬 전제, `copy_if`와 `back_inserter`의 조합은 시험에 바로 나오기 좋은 부분이다.

## 복습 질문

<details>
<summary>1. STL의 네 가지 구성 요소는 무엇인가?</summary>

답변: 컨테이너, 이터레이터, 알고리즘, 함수 객체/람다다. 컨테이너는 데이터를 저장하고, 이터레이터는 범위를 표현하며, 알고리즘은 그 범위에 연산을 적용한다. 함수 객체와 람다는 알고리즘에 정렬 기준이나 검색 조건 같은 동작을 전달한다.

</details>

<details>
<summary>2. 특별한 이유가 없을 때 `vector`를 먼저 선택하는 이유는 무엇인가?</summary>

답변: <code>vector</code>는 연속 메모리를 사용하므로 임의 접근이 O(1)이고 캐시 효율이 좋다. 뒤쪽 추가도 평균 O(1)이어서 대부분의 순차 데이터 처리에 적합하다. 중간 삽입과 삭제가 잦은 경우가 아니라면 기본 선택지로 충분하다.

</details>

<details>
<summary>3. `reserve()`와 `resize()`의 차이는 무엇인가?</summary>

답변: <code>reserve()</code>는 capacity만 미리 확보하고 실제 원소 개수인 size는 바꾸지 않는다. <code>resize()</code>는 실제 원소 개수를 바꾸며, 크기를 늘리면 새 원소를 생성하고 줄이면 뒤쪽 원소를 제거한다.

</details>

<details>
<summary>4. `end()`는 왜 마지막 원소가 아닌가?</summary>

답변: STL 범위는 <code>[begin, end)</code> 형태로 표현된다. <code>begin()</code>은 첫 원소를 가리키고, <code>end()</code>는 마지막 원소의 다음 위치를 가리킨다. 따라서 반복문은 <code>it != end()</code>까지 순회하고, <code>*end()</code>는 미정의 동작이다.

</details>

<details>
<summary>5. `list`의 중간 삽입이 O(1)이라는 말은 항상 맞는가?</summary>

답변: 위치를 이미 알고 있을 때만 맞다. <code>list</code>에서 iterator 위치가 주어지면 노드 포인터만 바꾸면 되므로 삽입과 삭제가 O(1)이다. 그러나 그 위치를 찾기 위해 처음부터 탐색해야 한다면 탐색 비용 O(n)이 추가된다.

</details>

<details>
<summary>6. 왜 `std::sort`를 `list`에 직접 사용할 수 없는가?</summary>

답변: <code>std::sort</code>는 random access iterator가 필요하다. <code>vector</code>와 <code>array</code>는 random access iterator를 제공하지만, <code>list</code>는 bidirectional iterator만 제공한다. 그래서 <code>list</code>는 전용 멤버 함수인 <code>lst.sort()</code>를 사용한다.

</details>

<details>
<summary>7. `set::find`와 `std::find`의 차이는 무엇인가?</summary>

답변: <code>std::find</code>는 iterator 범위를 앞에서부터 선형 탐색하므로 O(n)이다. 반면 <code>set::find</code>는 set 내부의 정렬 트리 구조를 이용하므로 O(log n)에 검색한다. set에서 특정 원소를 찾을 때는 보통 멤버 함수 <code>find</code>가 더 적절하다.

</details>

<details>
<summary>8. `map["Nobody"]`처럼 없는 키를 읽으면 어떤 일이 생기는가?</summary>

답변: <code>operator[]</code>는 없는 키에 접근하면 해당 키를 기본값으로 삽입한다. 예를 들어 <code>std::map&lt;std::string, int&gt;</code>에서 없는 키를 읽으면 값 0이 들어간 원소가 새로 생길 수 있다. 읽기만 할 때는 <code>at()</code> 또는 <code>find()</code>를 사용하는 것이 안전하다.

</details>

<details>
<summary>9. `remove`를 호출했는데 왜 vector 크기가 줄지 않는가?</summary>

답변: <code>std::remove</code>는 원소를 실제로 삭제하지 않고, 남길 원소들을 앞쪽으로 모은 뒤 유효 범위의 끝 iterator를 반환한다. 컨테이너 크기를 줄이려면 반환된 iterator부터 <code>end()</code>까지 <code>erase</code>해야 한다. 이것이 erase-remove 관용구다.

</details>

<details>
<summary>10. `binary_search`와 `lower_bound`를 쓰기 전에 필요한 조건은 무엇인가?</summary>

답변: 범위가 정렬되어 있어야 한다. 이진 검색 계열 알고리즘은 정렬된 범위를 전제로 O(log n)에 동작한다. 정렬되지 않은 데이터에 사용하면 결과가 올바르지 않을 수 있다.

</details>

<details>
<summary>11. 람다의 캡처 리스트는 왜 필요한가?</summary>

답변: 람다 본문에서 바깥 지역 변수를 사용하려면 캡처 리스트에 명시해야 한다. <code>[x]</code>는 값을 복사하고, <code>[&x]</code>는 참조로 접근한다. 값 캡처는 람다 생성 시점의 값을 기억하고, 참조 캡처는 원본 변수의 현재 값을 사용하거나 수정할 수 있다.

</details>

<details>
<summary>12. `copy_if`에서 `back_inserter`를 쓰는 이유는 무엇인가?</summary>

답변: 조건을 만족하는 원소 개수를 미리 모를 때 결과 vector의 크기를 정확히 준비하기 어렵다. <code>std::back_inserter</code>를 사용하면 알고리즘이 결과를 쓸 때마다 내부적으로 <code>push_back</code>을 호출하므로, 빈 vector에도 안전하게 원소를 추가할 수 있다.

</details>

<details>
<summary>13. `sort`와 `stable_sort`의 차이는 무엇인가?</summary>

답변: 둘 다 전체 범위를 정렬하지만, <code>sort</code>는 같은 기준값을 가진 원소들의 기존 상대 순서를 보장하지 않는다. <code>stable_sort</code>는 같은 기준값을 가진 원소들의 기존 상대 순서를 유지한다. 예를 들어 점수 90점인 A, B가 원래 A 다음 B 순서였다면, 점수 기준 안정 정렬 후에도 A, B 순서가 유지된다.

</details>

<details>
<summary>14. `partial_sort`와 `nth_element`는 전체 정렬과 어떻게 다른가?</summary>

답변: <code>partial_sort</code>는 앞 N개만 정렬된 상태로 만들고, 뒤쪽 나머지 순서는 보장하지 않는다. <code>nth_element</code>는 n번째 위치에 들어갈 원소만 제자리로 보내며, 그 왼쪽은 n번째 원소 이하, 오른쪽은 n번째 원소 이상이 되게 한다. 둘 다 전체 정렬이 필요 없는 상황에서 비용을 줄이기 위해 사용한다.

</details>

<details>
<summary>15. `accumulate`에서 초기값이 중요한 이유는 무엇인가?</summary>

답변: <code>accumulate</code>는 세 번째 인자인 초기값에서 누적을 시작한다. 합계는 0에서 시작하는 것이 자연스럽지만, 곱은 1에서 시작해야 한다. 곱셈 누적의 초기값을 0으로 두면 이후 어떤 값을 곱해도 결과가 계속 0이 된다.

</details>

<details>
<summary>16. `transform`, `fill`, `generate`는 각각 언제 쓰는가?</summary>

답변: <code>transform</code>은 각 원소에 함수를 적용해 변환 결과를 저장할 때 쓴다. <code>fill</code>은 이미 존재하는 범위를 같은 값으로 채울 때 쓴다. <code>generate</code>는 함수를 매번 호출한 결과로 범위를 채울 때 쓰며, 람다 캡처를 이용해 0, 1, 2처럼 상태가 변하는 값을 만들 수 있다.

</details>

<details>
<summary>17. `binary_search`, `lower_bound`, `upper_bound`의 공통 전제는 무엇인가?</summary>

답변: 세 함수 모두 정렬된 범위에서만 올바르게 동작한다. <code>binary_search</code>는 값의 존재 여부를 bool로 반환하고, <code>lower_bound</code>는 key 이상인 첫 위치, <code>upper_bound</code>는 key 초과인 첫 위치를 iterator로 반환한다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/cpp/C++ STL.pdf" | relative_url }}" target="_blank" rel="noopener">C++ STL.pdf</a></li>
</ul>
