---
layout: default
date: 2026-05-20 15:35:29 +0900
title: "Bancroft"
topic: "Genomics acceleration beyond on-device memory"
order: 4
major_topic: "Computer Systems & Architecture"
keywords:
  - "Bancroft"
  - "Genomics acceleration"
  - "On-device memory"
  - "Memory hierarchy"
---

# Bancroft: Genomics Acceleration Beyond On-Device Memory

## 논문 정보

| 항목 | 내용 |
|---|---|
| 제목 | Bancroft: Genomics Acceleration Beyond On-Device Memory |
| 저자 | Se-Min Lim, Seongyoung Kang, Sang-Woo Jun |
| 학회 | 2025 34th International Conference on Parallel Architectures and Compilation Techniques (PACT) |
| DOI | `10.1109/PACT65351.2025.00036` |
| 키워드 | Genomics, Acceleration, Compression, HBM |
| 코드 | `https://github.com/SeMinLim/bancroft` |

## 한 줄 요약

Bancroft는 FPGA accelerator의 on-device HBM 용량을 넘어서는 대규모 유전체 데이터를 host에 압축 저장하고, PCIe로 가져온 compressed data를 accelerator 내부에서 즉시 decompress하여 DRAM급 effective bandwidth를 제공하는 genomics acceleration platform이다.

## 핵심 내용

이 절은 Bancroft 논문 원문을 그대로 번역한 것이 아니라, 논문의 전체 전개를 한국어로 다시 읽을 수 있게 만든 번역형 해설이다. 논문에서 쓰는 FASTA, FASTQ, HBM, PCIe, reference-based compression 같은 핵심 용어는 원문 표현을 유지했다.

논문은 genomics accelerator에서 계산 성능보다 memory capacity와 data movement가 먼저 병목이 된다는 문제에서 출발한다. FPGA나 GPU는 높은 throughput을 제공할 수 있지만, on-device HBM은 대규모 genomic dataset 전체를 담기에 충분하지 않다. Host에서 raw data를 계속 가져오면 PCIe bandwidth가 병목이 되므로, accelerator의 내부 계산 성능이 충분해도 end-to-end 처리량은 낮아질 수 있다.

Bancroft의 핵심 아이디어는 host에 genomic data를 압축된 형태로 두고, FPGA가 필요한 compressed page를 가져온 뒤 내부에서 즉시 decompress하여 user kernel에 공급하는 것이다. 여기서 compression은 단순 저장공간 절약이 아니라 bandwidth amplification 수단이다. 압축률이 높을수록 PCIe로 이동하는 byte 수가 줄고, accelerator 입장에서는 더 높은 effective bandwidth를 얻는다.

압축 포맷은 hardware decoder가 빠르게 처리할 수 있도록 설계된다. Base read는 reference-based lossless compression을 사용하고, K-mer가 reference에 exact match되면 offset만 저장한다. Quality score는 분포가 특정 값에 몰리는 특성을 이용해 반복, 직전 값 반복, 두 frequent score 조합 등을 header로 표현한다. Grouped header와 fixed 32-bit payload는 variable-length parsing을 줄여 decompressor 구현을 단순하게 만든다.

Compression 과정에서는 큰 cuckoo hash table을 FPGA에 모두 넣기 어렵기 때문에 host software와 accelerator가 역할을 나눈다. FPGA는 parsing, binary encoding, hash 계산, probabilistic filter를 담당하고, host는 큰 reference table과 exact comparison을 처리한다. 반면 decompression은 user kernel 앞단의 성능 경로이므로 FPGA 내부에서 높은 throughput으로 수행된다.

실험 결과는 Bancroft가 FASTA와 FASTQ 모두에서 높은 compression ratio를 얻고, compressed transfer와 on-FPGA decompression을 통해 PCIe 병목을 줄일 수 있음을 보여준다. 특히 pre-alignment filtering case study는 단순 microbenchmark가 아니라 실제 genomics workload에서 효과가 있음을 보여준다. 다만 species별 reference 필요, exact K-mer 의존성, host software 의존, 플랫폼별 HBM/PCIe 특성에 따른 성능 변화는 배포 시 고려해야 할 조건이다.

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | 문제 배경 | 왜 genomics workload는 accelerator memory capacity에 막히는가? |
| 2 | 핵심 접근 | 압축과 on-demand decompression이 PCIe 병목을 어떻게 줄이는가? |
| 3 | 압축 포맷 | FASTA base read와 FASTQ quality score를 어떻게 hardware-friendly하게 encoding하는가? |
| 4 | Compression hardware | 왜 host software와 accelerator가 일을 나눠 갖는가? |
| 5 | Decompression hardware | grouped header와 fixed payload가 왜 빠른 decoder를 만드는가? |
| 6 | Software manager | compressed data에서 random access를 어떻게 지원하는가? |
| 7 | 평가 | compression ratio, bandwidth, resource, real workload에서 어떤 결과를 보이는가? |
| 8 | 한계 | 어떤 workload와 조건에서 Bancroft의 가정이 중요해지는가? |

## 1. 문제 배경

Genome sequencing 비용은 빠르게 낮아지고, 수집되는 genomic data 크기는 폭발적으로 증가한다. 문제는 accelerator의 계산 성능보다 memory capacity와 data movement가 먼저 병목이 된다는 점이다.

FPGA나 GPU accelerator는 높은 throughput과 power efficiency를 제공하지만, 보통 on-board memory는 수십 GB 수준이다. 반면 실제 genomic dataset은 수백 GB에서 TB 규모까지 커질 수 있다.

| 병목 | 설명 |
|---|---|
| HBM capacity | 빠르지만 작다. 큰 dataset 전체를 accelerator에 올리기 어렵다. |
| PCIe bandwidth | host memory나 storage에서 매번 raw data를 가져오면 bandwidth가 낮다. |
| Random access | alignment, filtering, graph construction은 read 단위 접근이 필요하다. |
| Genomic format | FASTA는 base sequence, FASTQ는 base와 quality score를 함께 가진다. |

Bancroft의 질문은 단순하다.

```text
TB-scale genomic data를 accelerator memory에 다 올리지 않고도
HBM/DRAM에 가까운 속도로 처리할 수 있는가?
```

## 2. Bancroft의 핵심 아이디어

Bancroft는 raw genomic data를 host side에 압축된 형태로 저장한다. Accelerator는 필요한 compressed page를 PCIe로 가져오고, 내부 decompressor가 user kernel에 raw genomic stream을 공급한다.

```text
compressed genomic database on host
-> PCIe transfer
-> on-FPGA decompression
-> user accelerator kernel
```

중요한 관점은 compression을 단순 storage saving으로만 보지 않는 것이다. Compression ratio가 충분히 높으면 PCIe로 이동해야 하는 byte 수가 줄어들고, 그 결과 effective bandwidth가 커진다.

| 구성 | 역할 |
|---|---|
| Hardware-friendly compression format | 압축률과 hardware decoder 단순성을 동시에 확보 |
| Decompressor channels | compressed stream을 FPGA 내부에서 raw base stream으로 변환 |
| Host software manager | compressed database, B+tree random access, reference lookup 관리 |
| User kernel interface | decompressed genomic data를 기존 accelerator kernel에 공급 |

## 3. 압축 대상과 포맷

논문은 두 가지 대표 genomic format을 다룬다.

| Format | 내용 | Bancroft 처리 |
|---|---|---|
| FASTA | nucleotide base sequence, `a/c/g/t` | reference-based lossless compression |
| FASTQ | base sequence와 base별 quality score | base compression + quality score lossless compression |

Bancroft encoding은 hardware 구현을 쉽게 하기 위해 공통 구조를 사용한다.

| 설계 선택 | 이유 |
|---|---|
| 2-bit grouped header | 16개 header를 묶어 parsing 단순화 |
| 32-bit fixed payload | variable-length decode를 피하고 datapath를 단순화 |
| exact K-mer matching | approximate matching보다 hardware가 단순함 |
| fixed match length $$K$$ | match length를 따로 encoding하지 않아도 됨 |
| fixed stride $$S$$ | mismatch/verbatim 처리와 payload 폭을 일정하게 유지 |

기본 설정은 base read에서 $$K = 64$$, $$S = 16$$이다. $$S = 16$$이면 2-bit base 16개가 정확히 32-bit payload에 들어간다.

## 4. Base Read Compression

Bancroft는 reference-based compression을 사용한다. Target genome stream의 K-mer가 compression reference에 exact match되면, 그 위치 offset만 저장한다.

```text
target K-mer
-> cuckoo hash lookup
-> reference offset
-> exact match이면 32-bit offset encoding
-> match 실패이면 S bases verbatim encoding
```

Base read header는 다음 의미를 가진다.

| Header | 의미 |
|---|---|
| `00` | $$S$$ bases verbatim encoding |
| `01` | 32-bit forward match offset |
| `10` | 32-bit reverse complement match offset |
| `11` | continuation |

Continuation은 이전 match 바로 다음 reference 위치가 이어진다는 뜻이다. 따라서 offset payload가 필요 없다. 긴 연속 match가 많을수록 compression ratio가 좋아진다.

Reverse complement를 별도 header로 둔 것도 중요하다. DNA read는 forward strand뿐 아니라 reverse complement 방향으로도 나올 수 있기 때문이다.

## 5. Quality Score Compression

FASTQ quality score는 base마다 붙는 score다. Bancroft는 correctness를 우선해 quality score도 lossless로 압축한다.

Quality score는 6-bit 값으로 보고, $$S = 5$$개 score를 32-bit payload에 넣는다. 남는 bit는 p1/p2 mask에 활용한다.

| Header | 의미 |
|---|---|
| `00` | $$S$$개 score verbatim |
| `01` | 직전 $$S$$개 score 반복 |
| `10` | 직전 score 하나를 $$S$$번 반복 |
| `11` | 가장 빈번한 두 score `p1`, `p2`만으로 이루어진 string |

논문 실험에서 `p1`, `p2`는 여러 dataset에서 안정적으로 `I`, `D`였고, HG002에서는 각각 81%, 10%를 차지한다. 즉 quality score의 분포 특성을 매우 단순한 hardware-friendly format으로 이용한다.

## 6. Compression Accelerator

Base read compression은 모든 작업을 FPGA에 넣지 않는다. Human genome용 cuckoo hash table은 최소 16GB 수준이라 U50 같은 중급 FPGA HBM에 넣기 어렵기 때문이다.

그래서 Bancroft는 compression을 host software와 accelerator가 나눠 처리한다.

| 구성 | 역할 |
|---|---|
| FPGA compressor | ASCII parsing, binary encoding, K-mer hash 계산, probabilistic filter |
| Host software | 큰 cuckoo hash table 유지, reference comparison, compressed data encoding |

Probabilistic filter는 작은 cuckoo hash를 HBM에 두고, reference offset의 앞 4-bit만 비교해 host가 검사해야 할 후보를 줄인다. 논문은 이 최적화가 host CPU와 memory pressure를 크게 낮춰 compression throughput을 끌어올린다고 설명한다.

## 7. Decompression Accelerator

Decompression은 Bancroft의 핵심 성능 경로다. User kernel은 compressed data가 아니라 decompressed stream을 받아야 하므로, decoder가 충분히 빨라야 한다.

Bancroft decompressor는 grouped header와 32-bit fixed payload 덕분에 단순하게 설계된다.

| 구성 | 역할 |
|---|---|
| 4-slot window parser | 연속 verbatim 또는 continuation을 한꺼번에 인식 |
| index router | reference lookup 요청을 HBM pseudo-channel로 보냄 |
| 512-bit shuffler | reference response와 verbatim data를 gap-free stream으로 정렬 |
| quality decoder | 동일한 payload extraction과 shuffler 구조를 재사용 |

연속 verbatim이나 continuation이 나오면 여러 element를 한 cycle에 처리하거나, 512-bit bus를 채우는 큰 memory request로 묶을 수 있다. 이 효율은 fixed-width encoding 덕분에 가능하다.

## 8. Random Access와 Software Manager

압축 데이터는 sequential scan만 빠르면 부족하다. Genome alignment나 filtering은 read 단위 random access가 필요하다.

Bancroft는 compressed data를 4KB page 단위로 관리하고, original file offset을 key로 하는 B+tree를 만든다.

| 기능 | 설명 |
|---|---|
| B+tree index | 원본 offset에서 compressed page 위치를 찾음 |
| 4KB compressed page | NVMe 같은 secondary storage와도 잘 맞는 단위 |
| long read padding | read boundary를 유지해 read 단위 I/O를 쉽게 함 |
| shifted reference copies | 2-bit packed reference의 bit alignment overhead를 줄임 |

Reference comparison에서 $$\mathrm{offset}\bmod 4$$에 따라 미리 shift해 둔 reference copy를 고르면, 비트 shift를 반복하지 않고 byte-aligned `memcmp`를 사용할 수 있다. 논문은 이 최적화가 encoding performance를 평균 4배 높인다고 보고한다.

## 9. 실험 설정

평가는 Xilinx Alveo U50 FPGA card에서 수행된다.

| 항목 | 설정 |
|---|---|
| FPGA | Xilinx Alveo U50 |
| Memory | 8GB 3D-stacked HBM |
| Host link | PCIe Gen3 x16 |
| Sustained PCIe download/upload | 9.1GB/s download, 8.4GB/s upload |
| Compressor LUT | 36K, 4.14% |
| Decompressor LUT | 26K, 2.99% |

Dataset은 human, mouse, maize reference와 long-read FASTQ를 포함한다. HG002, HG003, HG004, mouse replicate, maize B73 등이 사용된다.

## 10. 주요 결과

| 결과 | 의미 |
|---|---|
| FASTA compression 24x-100+x | reference-based base compression이 높은 ratio 달성 |
| FASTQ compression 4.7x-7.4x | quality score까지 포함한 lossless compression에서도 경쟁력 있음 |
| single decompressor 약 16GB/s | 한 channel이 512-bit output bus를 거의 포화 |
| 10 decompressor projection 160GB/s | PCIe 한계를 넘어 31% peak HBM, 약 2x DDR4급 effective bandwidth |
| U50 power-throttled setting 약 70GB/s | 전력 제한이 있는 실제 U50에서도 HBM sustained bandwidth의 약 34% |
| compression up to 3.7GB/s per channel | 기존 FPGA genome compression accelerator보다 큰 폭으로 빠름 |
| pre-alignment filtering over 7x | PCIe-limited conventional accelerator 대비 실제 workload에서 큰 개선 |

핵심 해석은 Bancroft가 raw data transfer를 줄여 PCIe 병목을 완화한다는 것이다. 기존 accelerator는 내부 kernel throughput이 높아도 host-device data movement 때문에 실제 end-to-end utilization이 3-4% 수준으로 떨어질 수 있다. Bancroft는 compressed transfer와 on-FPGA decompression으로 이 간극을 줄인다.

## 11. Pre-Alignment Filtering Case Study

논문은 Shifted Hamming Distance(SHD) 계열 pre-alignment filter를 case study로 사용한다.

Seed-and-extend alignment에서는 seeding 단계가 많은 후보 match를 만든다. 이 중 상당수는 실제 alignment에서 의미가 없으므로, pre-alignment filtering으로 미리 제거하면 전체 alignment 비용을 줄일 수 있다.

하지만 filtering도 결국 read sequence와 reference segment를 accelerator로 보내야 하므로 memory-bound가 되기 쉽다. Bancroft는 read/reference stream을 압축 상태로 이동시킨 뒤 FPGA 내부에서 풀어 공급함으로써 실제 system-level throughput을 높인다.

## 12. 논문의 핵심 기여

| 기여 | 해석 포인트 |
|---|---|
| Capacity 문제 재정의 | HBM 용량 부족을 compression과 streaming decompression 문제로 바꿈 |
| Hardware-friendly format | fixed header, fixed payload, fixed K-mer로 decoder를 단순화 |
| FASTA/FASTQ 통합 | base read와 quality score를 모두 hardware-friendly하게 처리 |
| Host-FPGA co-design | 큰 cuckoo table은 host, 빠른 hash/filter는 FPGA가 담당 |
| Random access 지원 | B+tree page index로 compressed data에서도 read 단위 접근 가능 |
| Real workload 검증 | pre-alignment filtering에서 PCIe 병목 완화 효과를 보여줌 |

## 13. 읽을 때 잡아야 할 관점

이 논문은 "압축률만 좋은 compressor"가 아니라 "압축을 bandwidth 확장 장치로 쓰는 accelerator platform"으로 읽는 것이 좋다.

| 관점 | 질문 |
|---|---|
| Bandwidth amplification | compression ratio가 PCIe effective bandwidth를 얼마나 키우는가? |
| Hardware simplicity | variable-length encoding을 버린 대신 어떤 이득을 얻는가? |
| Reference dependency | species별 compression reference가 필요한 것이 deployment에 어떤 의미인가? |
| Workload fit | sequential streaming과 random access가 섞인 genomics workload에 얼마나 잘 맞는가? |
| Memory trade-off | HBM을 reference와 filter에 쓰는 비용이 channel 수를 어떻게 제한하는가? |

## 14. 한계와 주의점

| 한계 | 설명 |
|---|---|
| Species별 reference 필요 | compression reference를 종마다 준비해야 한다. |
| Exact K-mer 중심 | hardware 단순성을 위해 exact match를 사용하므로 error pattern에 따라 match rate가 달라질 수 있다. |
| Host software 의존 | compression에서는 큰 cuckoo table과 reference comparison을 host가 담당한다. |
| Platform sensitivity | HBM power throttling, HBM channel 수, PCIe 세대에 따라 성능이 달라진다. |
| Domain specificity | FASTA/FASTQ genomics format에 최적화된 설계다. |

## 참고자료

<ul>
  <li><a href="{{ "/assets/pdfs/research/bancroft-genomics-acceleration-beyond-on-device-memory/bancroft-genomics-acceleration-beyond-on-device-memory.pdf" | relative_url }}" target="_blank" rel="noopener">bancroft-genomics-acceleration-beyond-on-device-memory.pdf</a></li>
  <li><a href="https://doi.org/10.1109/PACT65351.2025.00036" target="_blank" rel="noopener">DOI: 10.1109/PACT65351.2025.00036</a></li>
  <li><a href="https://github.com/SeMinLim/bancroft" target="_blank" rel="noopener">Bancroft reference implementation</a></li>
</ul>
