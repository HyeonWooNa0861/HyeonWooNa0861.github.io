---
layout: default
title: "Labidus"
topic: "RISC-V overlay with streaming asynchronous custom instructions"
order: 5
major_topic: "Computer Systems & Architecture"
keywords:
  - "RISC-V"
  - "Custom instructions"
  - "Streaming execution"
  - "Overlay architecture"
---

# Labidus: RISC-V Overlay with Streaming Asynchronous Custom Instructions

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Labidus: RISC-V Overlay with Streaming Asynchronous Custom Instructions |
| 저자 | Gongjin Sun, Seongyoung Kang, Jane He, Se-Min Lim, Sang-Woo Jun |
| 학회 | 2025 IEEE 36th International Conference on Application-specific Systems, Architectures and Processors (ASAP) |
| DOI | `10.1109/ASAP65064.2025.00018` |
| 키워드 | FPGA, Overlay, RISC-V |

## 한 줄 요약

Labidus는 FPGA를 순수 C software처럼 쉽게 프로그래밍하면서도 custom accelerator에 가까운 성능을 얻기 위해, RISC-V soft processor tile에 자동 생성 custom instruction, asynchronous completion queue, stream-semantic memory access, shared operator pool을 결합한 FPGA overlay architecture다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 FPGA는 강력하지만 사용하기 어려운가? |
| 2 | Overlay 접근 | soft processor overlay는 생산성을 높이지만 왜 느린가? |
| 3 | Labidus 모델 | C kernel을 어떻게 custom instruction 기반 accelerator로 바꾸는가? |
| 4 | Async execution | completion queue가 긴 operator latency를 어떻게 숨기는가? |
| 5 | Stream memory | stream-semantic cache와 register가 memory instruction overhead를 어떻게 줄이는가? |
| 6 | Operator pool | custom operator를 네 core가 공유하고 trimming하는 이유는 무엇인가? |
| 7 | 평가 | RTL/HLS/soft processor와 비교해 어떤 위치에 있는가? |
| 8 | 한계 | 어떤 workload에서 Labidus가 특히 유리하거나 불리한가? |

## 1. 문제 배경

FPGA는 application-specific hardware acceleration에 강력하다. 하지만 높은 성능을 얻으려면 RTL이나 HLS에서 pipeline, latency, resource, memory access를 직접 신경 써야 한다.

| 접근 | 장점 | 단점 |
|---|---|---|
| RTL | 최고 성능과 세밀한 제어 | 개발 난이도와 시간이 큼 |
| HLS | C/C++에서 hardware 생성 | irregular control에서는 많은 pragma와 hardware 지식 필요 |
| Soft processor overlay | software처럼 개발 가능 | 일반 softcore는 resource 대비 성능이 낮음 |

Labidus의 목표는 이 trade-off 사이에서 software productivity를 유지하면서 성능 격차를 줄이는 것이다.

```text
pure C kernel
-> static analysis
-> RISC-V overlay + custom operator pool
-> FPGA accelerator
```

## 2. Labidus의 핵심 아이디어

Labidus는 RISC-V soft processor를 FPGA 위에 여러 개 올리고, 각 processor가 custom operator pool을 비동기적으로 호출하게 한다.

| 구성 | 역할 |
|---|---|
| RV32I soft cores | control flow와 software execution 담당 |
| Custom operator pool | application-specific fused operation 수행 |
| Completion queue | long-latency operator 결과를 비동기적으로 수용 |
| Stream-semantic cache | burst memory I/O를 낮은 instruction overhead로 처리 |
| Static analysis tool | software kernel에서 operator fusion과 hardware configuration 생성 |

즉, Labidus는 soft processor의 쉬운 programming model을 유지하면서, 계산이 무거운 부분은 custom instruction 형태로 FPGA datapath에 올린다.

## 3. Programming Model

개발자는 kernel software를 C로 작성하고, Labidus static analysis tool이 compute-heavy region을 분석한다.

분석 결과는 두 가지다.

| 산출물 | 설명 |
|---|---|
| HDL | Labidus tile, RISC-V cores, operator pool, custom instructions |
| Modified kernel software | custom instruction call과 Labidus internal function이 들어간 kernel code |

논문 예시는 K-means의 Haversine distance다. Loop body의 operation tree를 분석해 다음 같은 fused operator를 만든다.

| Operator | 의미 |
|---|---|
| `sinsq(a, b)` | \\(\sin^{2}((x-y)/2)\\) |
| `coscos(a, b)` | \\(\cos(a)\cos(b)\\) |
| `arcsrt(a)` | \\(2R\arcsin(\sqrt{a})\\) |

이런 fused operator는 latency가 수십 cycle일 수 있지만, pipeline되어 매 cycle 새 input을 받을 수 있다. 따라서 문제는 "latency 자체"가 아니라 "어떻게 계속 input을 공급하고 결과를 기다리느냐"다.

## 4. Asynchronous Completion Queue

Labidus의 핵심은 completion queue다. Custom operator 호출 시 RISC-V core는 queue tail에 slot을 예약하고, operator 결과는 준비되는 즉시 해당 slot에 비동기적으로 채워진다.

```text
issue custom instruction
-> reserve completion queue slot
-> continue issuing other operations
-> result arrives asynchronously
-> read queue head when needed
```

Completion queue의 장점은 두 가지다.

| 장점 | 설명 |
|---|---|
| latency hiding | 긴 operator latency가 있어도 여러 operation을 동시에 in-flight로 둘 수 있음 |
| out-of-order completion 정리 | operator별 latency 차이로 결과 순서가 달라도 queue가 순서를 맞춤 |

전통적인 deep pipeline이나 reorder buffer를 FPGA soft processor에 넣으면 LUT overhead가 크다. Labidus는 FPGA에서 BRAM이 programmable logic보다 dense하다는 점을 이용해 큰 queue를 BRAM으로 구현한다.

논문은 1024-slot reorder buffer식 deep pipeline이 80K LUT 이상을 쓰는 반면, 1024-size completion queue를 가진 tile baseline은 operator pool 제외 약 38K LUT로 더 효율적이라고 설명한다.

## 5. Stream-Semantic Memory

Labidus는 memory access도 stream으로 본다. 일반 load/store처럼 word 단위로 계속 instruction을 내는 대신, burst 단위 memory request를 발행하고, stream register를 반복적으로 읽거나 쓴다.

Stream semantics는 세 register에만 적용된다.

| Register | 역할 |
|---|---|
| `x29`, `x30`, `x31` | stream-semantic read/write register |

Memory request instruction은 burst length, repeat count, uncached flag를 포함한다.

| 필드 | 의미 |
|---|---|
| burst length | 한 번에 가져올 data stream 길이 |
| repeat count | 같은 memory region 반복 접근 |
| uncached flag | cache에 넣지 않고 bypass queue로 처리 |

Completion queue와 stream-semantic cache는 operator pool, off-chip memory, core 사이의 data movement 중심이 된다. 이 구조는 operator가 계산을 기다리지 않도록 input stream을 계속 공급하는 데 중요하다.

## 6. Operator Pool과 Trimming

각 Labidus tile은 4개의 RISC-V core를 가진다. Custom operator는 core마다 완전히 복제하지 않고 tile 단위 shared operator pool로 둔다.

| 설계 | 이유 |
|---|---|
| shared operator pool | operator utilization을 높이고 resource 낭비를 줄임 |
| repeat field | RISC-V가 매번 instruction을 발행하지 않아도 operator 반복 실행 |
| static trimming | 덜 쓰는 operator instance를 줄여 LUT 사용량 절감 |
| up to 64 active opcodes | 실제 design에 필요한 operator만 opcode에 배정 |

Static analysis tool은 각 operator의 상대적 사용 빈도를 보수적으로 추정해, operator instance 수를 1개에서 4개 사이로 정한다. 논문은 trimming이 성능 손실 없이 operator utilization을 평균 100%p 이상 높였다고 보고한다.

## 7. System Architecture

Labidus accelerator는 PCIe로 host와 연결된 FPGA 위에 구성된다.

```text
Host
-> PCIe
-> Labidus accelerator
   -> tiles
      -> 4 RISC-V cores
      -> stream-semantic caches
      -> completion queues
      -> shared operator pool
-> DRAM controller
```

Tile 내부 core들은 ring network로 연결되고, tile과 memory/PCIe controller는 2D mesh network로 연결된다. 논문 실험의 기본 tile은 4-core 구성이며, 전체 tile 수와 operator 구성은 target application에 맞게 바뀔 수 있다.

## 8. 실험 설정

Labidus는 Amazon AWS F1 환경의 Xilinx Virtex Ultrascale FPGA에서 250MHz로 평가된다.

| 항목 | 설정 |
|---|---|
| ISA | RV32I |
| Tile 구성 | 4 RISC-V cores |
| Clock | 250MHz |
| Tile LUT utilization | application에 따라 약 3.4%-4.2% |
| Cache/processor BRAM | 160 BRAM blocks, 약 7% |

비교 대상은 published RTL, HLS, Microblaze, soft GPU 계열이다. 논문은 FPGA vendor와 clock 차이를 보정하기 위해 LUT input 수와 250MHz 기준으로 normalize한다.

## 9. 평가 workload

Labidus는 매우 규칙적인 matrix multiplication보다, control이 복잡하고 rapid prototyping이 중요한 scientific workload를 주요 대상으로 둔다.

| Workload | 특징 |
|---|---|
| Cholesky decomposition | complex control, HPC kernel |
| FIR filter | signal processing stream |
| FFT | parallel 256-point FFT |
| K-means with Haversine | trigonometric fused operator와 distance comparison |

논문은 matrix multiplication과 DNN은 주요 target에서 제외한다. 이런 dense regular kernel은 expert RTL이 Labidus보다 평균 4-7배 빠를 수 있기 때문이다.

## 10. 주요 결과

| 결과 | 의미 |
|---|---|
| RTL/HLS 대비 competitive | hardware 전문 지식 없이도 published optimized accelerator와 유사한 efficiency |
| irregular computation에서 강함 | Cholesky처럼 control이 복잡한 경우 RTL보다 나은 경우도 있음 |
| Microblaze 대비 50x+ performance per resource | 일반 softcore보다 훨씬 높은 resource efficiency |
| soft GPU 대비 약 10x | published soft GPU보다 높은 performance efficiency |
| operator utilization 80% 이상 | 평가 application에서 operator pool 활용도가 높음 |
| trimming으로 resource 절감 | 성능 손실 없이 operator instance를 줄임 |

핵심 해석은 Labidus가 "FPGA를 software처럼 쓰되, 일반 softcore처럼 느리지는 않게" 만드는 시도라는 점이다. 성능 최고점은 expert RTL일 수 있지만, 개발 생산성과 성능 효율의 균형이 Labidus의 주된 기여다.

## 11. 논문의 핵심 기여

| 기여 | 해석 포인트 |
|---|---|
| RISC-V overlay architecture | pure software programming model을 FPGA accelerator로 연결 |
| Static custom instruction generation | kernel 분석으로 fused operator와 instruction을 자동 생성 |
| Asynchronous semantics | completion queue로 long-latency operator를 overlap |
| Stream-semantic memory | burst memory access와 repeat execution으로 instruction overhead 감소 |
| Shared operator pool | 4-core tile에서 operator를 공유해 utilization 향상 |
| Operator trimming | application별 operator 빈도에 맞춰 resource 낭비 제거 |

## 12. 읽을 때 잡아야 할 관점

이 논문은 "soft processor가 custom accelerator를 이긴다"는 단순 주장보다, FPGA 개발의 productivity-performance trade-off를 재설계하는 논문으로 읽는 것이 좋다.

| 관점 | 질문 |
|---|---|
| Productivity | 개발자는 RTL/HLS 세부 최적화를 얼마나 피할 수 있는가? |
| Latency hiding | BRAM completion queue가 deep pipeline보다 FPGA에 왜 적합한가? |
| Streaming | memory access가 word load/store에서 burst stream으로 바뀌면 무엇이 줄어드는가? |
| Operator sharing | core마다 operator를 복제하지 않을 때 utilization과 contention은 어떻게 변하는가? |
| Workload fit | irregular scientific kernel과 dense regular kernel 중 어디에 더 적합한가? |

## 13. 한계와 향후 과제

| 한계 | 설명 |
|---|---|
| Dense regular kernel에는 불리 | matrix multiplication, DNN처럼 control overhead가 낮은 kernel은 expert RTL이 더 빠르다. |
| Offload region 지정 필요 | 현재는 programmer가 operator pool으로 offload할 code region을 명시해야 한다. |
| Static analysis 의존 | fused operator와 trimming 품질이 분석 도구에 좌우된다. |
| RISC-V softcore overhead | 아무리 줄여도 pure custom datapath 대비 control overhead가 남는다. |
| Legacy code 자동 추출은 future work | 논문은 legacy software에서 custom kernel을 자동 추출하는 방향을 향후 과제로 제시한다. |

## 핵심 내용

이 절은 Labidus 논문을 축어적으로 번역한 것이 아니라, 논문의 전체 구조를 한국어로 재구성한 번역형 해설이다. RISC-V overlay, custom instruction, completion queue, stream-semantic memory 같은 핵심 용어는 원문의 의미를 유지했다.

논문은 FPGA의 productivity-performance trade-off를 문제로 제기한다. RTL은 최고 성능을 낼 수 있지만 개발 난도가 높고, HLS는 C/C++ 기반 개발을 돕지만 irregular control이 많은 경우 많은 최적화 지식이 필요하다. Soft processor overlay는 software처럼 프로그래밍할 수 있지만 일반 softcore는 resource 대비 성능이 낮다. Labidus는 이 중간 지점에서 software programming model을 유지하면서 성능 격차를 줄이는 것을 목표로 한다.

Labidus의 구조는 RV32I soft core 여러 개와 application-specific custom operator pool을 결합한다. 개발자는 C kernel을 작성하고, static analysis tool은 compute-heavy region을 찾아 fused operator와 custom instruction을 생성한다. 이 방식은 pure software code를 FPGA overlay 위의 custom datapath와 연결하는 흐름으로 볼 수 있다.

긴 latency를 가진 custom operator를 효율적으로 쓰기 위해 Labidus는 asynchronous completion queue를 사용한다. Core는 custom instruction을 발행하고 queue slot을 예약한 뒤 다른 작업을 계속 진행할 수 있다. 결과가 준비되면 queue에 채워지고, 필요한 시점에 순서대로 읽힌다. FPGA에서 BRAM이 LUT보다 density가 높다는 점을 이용해 deep reorder buffer보다 비용이 낮은 latency hiding 구조를 만든 것이 핵심이다.

Memory access도 일반 load/store 반복이 아니라 stream-semantic access로 재정의된다. Burst request와 stream register를 통해 instruction overhead를 줄이고, operator pool에 계속 input을 공급한다. 또한 custom operator를 core마다 복제하지 않고 tile 단위 shared operator pool로 두어 utilization을 높이며, static trimming으로 덜 쓰는 operator instance를 줄인다.

평가 결과 Labidus는 irregular scientific workload에서 RTL/HLS와 경쟁 가능한 효율을 보였고, Microblaze나 soft GPU 계열보다 높은 performance per resource를 보였다. 그러나 dense matrix multiplication이나 DNN처럼 expert RTL이 이미 잘 맞는 regular kernel에서는 불리할 수 있다. 따라서 Labidus는 FPGA 최고 성능을 대체하는 구조라기보다, 빠른 prototyping과 충분한 성능 효율을 동시에 원하는 영역에 적합한 overlay architecture로 해석하는 것이 정확하다.

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/labidus-risc-v-overlay-with-streaming-asynchronous-custom-instructions/labidus-risc-v-overlay-with-streaming-asynchronous-custom-instructions.pdf" | relative_url }}" target="_blank" rel="noopener">labidus-risc-v-overlay-with-streaming-asynchronous-custom-instructions.pdf</a></li>
  <li><a href="https://doi.org/10.1109/ASAP65064.2025.00018" target="_blank" rel="noopener">DOI: 10.1109/ASAP65064.2025.00018</a></li>
</ul>
