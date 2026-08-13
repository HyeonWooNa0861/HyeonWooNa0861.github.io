---
layout: default
title: "Robotics 2"
course: "AIX"
topic: "VLA, World Models, Physical RL"
order: 10
major_topic: "Artificial Intelligence"
keywords:
  - "Physical AI"
  - "VLA"
  - "World Models"
  - "Action Fine-Tuning"
  - "Physical RL"
---

# Robotics 2

Source PDF: `Robotics_2.pdf`

## 전체 흐름

| 순서 | 주제 | 핵심 질문 |
|---|---|---|
| 1 | LLM에서 Robots로 | 로보틱스는 왜 LLM 이후의 scaling frontier로 설명되는가? |
| 2 | Three-Phase Recipe | pre-training, supervised alignment, RL은 robotics에서 무엇에 대응되는가? |
| 3 | Foundation Model과 Data | 왜 model strategy와 data strategy가 함께 진화해야 하는가? |
| 4 | VLA | vision-language 이해를 action 출력으로 연결한다는 말은 무엇인가? |
| 5 | Video Pre-training | internet video와 ego-video는 physical regularity를 어떻게 제공하는가? |
| 6 | World Model과 WAM | VLA에서 World Action Model로 강조점이 이동하는 이유는 무엇인가? |
| 7 | Data Engine | teleoperation, sensorized human data, autonomous rollout은 어떻게 다른가? |
| 8 | Physical RL | 왜 physical RL은 robotics의 surpassing phase인가? |
| 9 | Real2Sim2Real | digital twins와 digital cousins는 training scale을 어떻게 키우는가? |
| 10 | Robotics Endgame | near-term milestone인 physical Turing test는 무엇을 뜻하는가? |

Robotics 2는 LLM scaling의 성공 공식이 로보틱스로 확장될 수 있다는 thesis를 다룬다. 핵심은 VLA 하나로 끝나지 않는다. Broad world model을 만들고, robot embodiment에 맞춰 action fine-tuning을 하고, physical RL과 simulation ecosystem으로 human demonstration을 넘어서는 방향까지 이어진다.

## 1. Physical AI와 New Robotics Thesis

강의는 로보틱스를 LLM race 이후의 next frontier로 본다. LLM에서 대규모 model, data, compute가 성능을 밀어 올렸듯이, robotics도 scale 가능한 architecture와 data engine이 결합될 때 크게 발전할 수 있다는 주장이다.

| LLM scaling | Robotics scaling |
|---|---|
| internet-scale text | internet video, ego-video, robot trajectories |
| next-token pre-training | world modeling, video prediction, embodied representation |
| instruction tuning | action fine-tuning |
| reasoning RL | physical RL |
| language output | motor action, manipulation, navigation |

DGX-1과 OpenAI의 early scaling anecdote는 modern deep learning의 compute era를 떠올리게 한다. Robotics 2의 중심 관점은 이 scaling mindset이 physical AI로 이동한다는 것이다.

## 2. Pre-training as Simulation

강의는 GPT-style pre-training을 internet-scale text 위의 simulation처럼 해석한다. Text pre-training은 넓은 world knowledge와 pattern을 학습하지만, 그 자체로 instruction following이나 task execution을 완성하지는 않는다.

LLM의 canonical recipe는 다음 세 단계로 정리된다.

| 단계 | LLM에서의 의미 | Robotics 대응 |
|---|---|---|
| pre-training | 거대한 text로 broad world model 학습 | video/world data로 physical world model 학습 |
| supervised alignment | instruction following, human preference에 맞춤 | action fine-tuning으로 robot body와 task에 맞춤 |
| reinforcement learning | reasoning RL로 imitation을 넘어섬 | physical RL로 demonstration을 넘어 개선 |

이 parallel이 Robotics 2 전체를 관통한다.

## 3. Foundation Models and Data Strategy

Robot foundation model에는 두 가지가 함께 필요하다.

| 전략 | 의미 |
|---|---|
| model strategy | 다양한 embodiment와 task를 흡수할 수 있는 scalable architecture |
| data strategy | 충분히 많고, 다양하고, action과 정렬된 embodied data engine |

좋은 model도 약한 data 위에서는 실패하고, 많은 data도 model이 활용할 수 없으면 낭비된다. 그래서 model strategy와 data strategy는 함께 진화해야 한다.

## 4. VLA as Robotics Backbone

VLA는 Vision-Language-Action이다. 이미지를 보고, 언어 지시를 이해하고, robot action을 출력하는 구조다.

| 구성 | 역할 |
|---|---|
| Vision | 장면, object, geometry를 인식 |
| Language | 자연어 instruction과 task intent를 이해 |
| Action | motor command, manipulation, navigation으로 연결 |

RT-2는 internet-scale VLM pre-training의 semantic knowledge가 manipulation으로 transfer될 수 있음을 보여주는 예시로 소개된다. Robot-only training에서 보지 못한 concept도 language/vision pre-training을 통해 grounding될 수 있다.

중요한 점은 VLA가 older task-specific robot policies의 modern successor라는 것이다. 각 task마다 좁은 policy를 만드는 대신, vision-language understanding을 action으로 연결하는 broad backbone을 만든다.

## 5. Video Is a Second Pre-Training Paradigm

Robotics에서 video는 text만큼 중요한 pre-training substrate가 될 수 있다. 특히 internet-scale video와 ego-video는 physical interaction, dynamics, affordance를 담고 있다.

| video data가 주는 정보 | 설명 |
|---|---|
| geometry | 물체와 공간 구조 |
| motion | 시간이 지나며 object가 어떻게 움직이는지 |
| contact | 손, 도구, object가 접촉할 때의 변화 |
| affordance | 어떤 object가 어떤 action을 가능하게 하는지 |

Physics-aware video generation은 모델이 geometry, motion, contact statistics를 internalize할 수 있다는 가능성을 보여준다. 다만 short-term physical realism과 long-horizon decision making은 다르다. 비디오를 그럴듯하게 만드는 것만으로 긴 horizon의 task planning이 자동 해결되지는 않는다.

## 6. Action Fine-Tuning

Action fine-tuning은 robotics analog of instruction tuning이다. Broad world model을 특정 robot body와 concrete motor output에 맞춘다.

```text
general world model
-> action fine-tuning
-> embodiment-specific robot policy
```

DreamZero와 Franka demos는 action fine-tuning이 unseen tasks에 대한 zero-shot 또는 one-shot skill transfer를 만들 수 있음을 보여주는 사례로 나온다. 핵심은 특정 demo 하나가 아니라, reusable control competence가 생기기 시작했다는 점이다.

## 7. World Models와 WAM

강의는 단순한 VLA보다 World Action Model, 즉 WAM 관점을 강조한다.

| 모델 관점 | 핵심 |
|---|---|
| VLA | vision과 language를 action으로 mapping |
| world model | action 이전에 world dynamics를 internal simulation |
| WAM | world modeling과 action generation을 함께 다루는 full robotics recipe |

World model은 robot이 direct reflex만 하는 것이 아니라 internal rollout을 통해 plan할 수 있게 한다.

```text
current observation
-> internal world rollout
-> evaluate possible actions
-> choose motor action
```

따라서 "VLA is dead, long live WAM"이라는 표현은 action output만으로 충분하지 않고, world modeling을 first-class로 둬야 한다는 주장으로 이해하면 된다.

## 8. Data Engines

Robot foundation model에서 data engine은 병목이다. Teleoperation은 오랫동안 default data engine이었다.

| data source | 장점 | 한계 |
|---|---|---|
| teleoperation | embodiment-aligned action traces, task labels | human labor, robot access, operator fatigue로 throughput 제한 |
| handheld tools/data gloves | action alignment를 유지하면서 collection friction 감소 | 여전히 interface와 hardware 제약 존재 |
| autonomous rollouts | policy가 스스로 새 trajectories를 빠르게 생성 | 초기 policy competence가 필요 |
| ego-video | abundant하고 behaviorally rich | robot actuation과 직접 정렬되지 않음 |
| sensorized human data | human behavior와 action alignment 사이의 중간지대 | 수집 장비와 표준화가 필요 |

강의에서 중요한 metric은 human-level demonstration speed다. Data interface가 사람의 자연스러운 속도를 크게 늦추면 scale이 무너진다.

## 9. Autonomous Rollouts와 EgoVerse

Policy가 어느 정도 competent해지면 robot은 teleoperation보다 훨씬 빠르게 새 trajectories를 생산할 수 있다. 이때 flywheel이 생긴다.

```text
trained policy
-> autonomous data
-> better dataset
-> improved policy
-> more autonomous data
```

Ego-video는 internet-scale substrate로 중요하다. First-person human video는 사람이 실제 물리 세계와 상호작용하는 장면을 담고 있어 embodied pre-training에 유용하다.

EgoVerse는 raw ego-video를 dense language annotation과 temporal grounding으로 더 structured하게 만드는 방향으로 이해할 수 있다.

## 10. Physical RL과 Simulation

Physical RL은 robotics pipeline의 surpassing phase다. LLM에서 reasoning RL이 human response imitation을 넘어서는 단계로 설명되듯, robotics에서는 physical RL이 teleoperated trajectories를 넘어서는 단계로 제시된다.

| 단계 | 역할 |
|---|---|
| pre-training | broad physical/world representation 학습 |
| action fine-tuning | robot body와 task에 맞춤 |
| physical RL | 실제 환경 또는 simulation에서 반복 개선 |

Physical RL은 fine motor behavior처럼 반복 개선이 필요한 작업에 강력하다. 하지만 real-world training은 expensive, slow, physically constrained하다.

그래서 Real2Sim2Real이 중요해진다.

| 개념 | 의미 |
|---|---|
| digital twin | 실제 환경을 가깝게 복제한 simulation |
| digital cousin | exact replica가 아니라 변형된 유사 환경 |
| Real2Sim2Real | real data를 sim으로 확장하고, 다시 real에 transfer |

Digital cousins는 robustness를 키운다. Exact replica만으로는 variation이 부족할 수 있기 때문이다.

## 11. World Models Become Simulators

강의 후반은 world model이 hand-authored simulator를 대체하거나 보완하는 interactive simulator가 될 가능성을 말한다.

Massive parallel RL에는 하나의 simulator만 필요한 것이 아니다. 강의의 summary diagram은 세 가지 input을 결합하는 scaling vision을 제시한다.

| 입력 | 역할 |
|---|---|
| real-world data | 실제 물리 분포와 실패 사례 |
| scanned worlds | 실제 공간을 simulation으로 가져온 환경 |
| model-generated worlds | world model이 만든 다양한 training variants |

이 blended training ecosystem이 robot RL의 scale을 키울 수 있다.

## 12. Robotics Endgame

강의는 robotics progress를 civilization-style tech tree로 비유한다. 현재 model은 endpoint가 아니라 unlockable capabilities의 중간 기술이다.

Near-term milestone은 모든 환경의 general-purpose autonomy가 아니다. 더 현실적인 첫 milestone은 bounded tasks에서 human-comparable labor를 달성하는 것이다. 강의는 이를 physical Turing test에 가깝게 설명한다.

| 구분 | 의미 |
|---|---|
| physical Turing test | 제한된 물리 task에서 인간 수준 노동을 수행할 수 있는가 |
| current limitation | 오늘날 시스템은 아직 failure demo가 보여주듯 threshold에서 멀다 |
| 2040 robotics horizon | 지금의 robotics를 초기 deep learning breakout 시점처럼 보는 장기 관점 |

## 마지막 핵심 정리

| 핵심 개념 | 정리 |
|---|---|
| robotics scaling thesis | LLM의 scaling recipe가 robotics에도 적용될 수 있다는 주장 |
| three-phase recipe | pre-training, action fine-tuning, physical RL |
| VLA | vision-language understanding을 action으로 연결하는 backbone |
| video pre-training | physical regularities, dynamics, affordances를 학습하는 substrate |
| WAM | world modeling과 action generation을 함께 다루는 World Action Model |
| teleoperation | aligned data를 주지만 human throughput ceiling이 있음 |
| autonomous rollout | policy가 자기 data를 생성하며 flywheel을 만들 수 있음 |
| ego-video | abundant한 embodied pre-training data |
| physical RL | demonstration을 넘어 actual performance를 개선하는 surpassing phase |
| digital cousins | exact replica보다 variation을 만들어 robustness를 높임 |

## Study Guide

Robotics 2는 LLM과 robotics의 parallel을 먼저 외우면 훨씬 쉽다. Pre-training은 world model, instruction tuning은 action fine-tuning, reasoning RL은 physical RL에 대응된다.

두 번째로 VLA와 WAM의 차이를 잡아야 한다. VLA는 vision-language-action mapping이고, WAM은 world modeling을 더 중심에 둔 full robotics recipe다.

세 번째로 data engine의 trade-off를 외운다. Teleoperation은 aligned하지만 느리고, ego-video는 abundant하지만 robot action과 덜 aligned하다. Sensorized human data와 autonomous rollout은 그 사이의 scale 문제를 해결하려는 방향이다.

| 시험 포인트 | 확인할 내용 |
|---|---|
| LLM-to-robotics parallel | pre-training, action fine-tuning, physical RL 대응 |
| VLA 정의 | vision, language, action 연결 |
| RT-2 의미 | VLM semantic knowledge가 manipulation으로 transfer |
| video pre-training | dynamics, affordance, physics-like structure 학습 |
| WAM | action mapping보다 world model을 first-class로 둠 |
| teleop 한계 | human labor, robot access, operator fatigue |
| physical RL | teleoperation을 넘어서는 surpassing phase |
| Real2Sim2Real | digital twins/cousins로 training universe 확장 |

## 복습 질문

<details>
<summary>1. Robotics를 LLM 이후의 scaling frontier로 보는 이유는 무엇인가?</summary>

답변: LLM에서 대규모 data, model, compute, pre-training, alignment, RL이 성능을 크게 끌어올렸듯이, robotics도 video/world data, action fine-tuning, physical RL을 결합하면 비슷한 scaling 구조를 따를 수 있다고 보기 때문이다.

</details>

<details>
<summary>2. LLM의 three-phase recipe는 robotics에서 무엇에 대응되는가?</summary>

답변: LLM의 pre-training은 robotics의 world/video pre-training에, supervised alignment는 action fine-tuning에, reasoning RL은 physical RL에 대응된다.

</details>

<details>
<summary>3. VLA는 무엇인가?</summary>

답변: Vision-Language-Action의 약자다. 장면을 보고, 언어 지시를 이해하고, 실제 robot action을 출력하는 robot foundation model backbone이다.

</details>

<details>
<summary>4. Video pre-training이 robotics에 중요한 이유는 무엇인가?</summary>

답변: Internet video와 ego-video는 물체의 움직임, 접촉, geometry, affordance 같은 physical regularities를 많이 담고 있기 때문이다. 이는 robot world model의 pre-training substrate가 될 수 있다.

</details>

<details>
<summary>5. VLA와 WAM은 어떻게 다른가?</summary>

답변: VLA는 vision-language understanding을 action으로 연결하는 mapping에 초점이 있다. WAM은 World Action Model로, world dynamics를 예측하고 internal rollout을 통해 action을 선택하는 world modeling을 더 중심에 둔다.

</details>

<details>
<summary>6. Teleoperation이 default data engine이 되었지만 한계가 있는 이유는 무엇인가?</summary>

답변: Teleoperation은 robot embodiment와 action trace가 잘 정렬된 데이터를 제공하지만, human labor, robot access, operator fatigue 때문에 throughput ceiling이 있다. 그래서 foundation model scale에는 부족할 수 있다.

</details>

<details>
<summary>7. Ego-video는 왜 embodied AI에 유용한가?</summary>

답변: First-person video는 사람이 물리 세계와 상호작용하는 장면을 많이 담고 있어 dynamics와 affordance를 관찰할 수 있다. 완벽한 robot action label은 아니지만 pre-training data로 매우 풍부하다.

</details>

<details>
<summary>8. Physical RL이 robotics의 surpassing phase인 이유는 무엇인가?</summary>

답변: Teleoperation이나 imitation은 human demonstration을 따라 하는 데 강하지만, physical RL은 실제 환경이나 simulation에서 반복 개선을 통해 demonstration을 넘어서는 성능을 추구한다.

</details>

<details>
<summary>9. Digital twin과 digital cousin의 차이는 무엇인가?</summary>

답변: Digital twin은 실제 환경을 가깝게 복제한 simulation이고, digital cousin은 exact replica가 아니라 유사하지만 변형된 환경이다. Digital cousin은 variation을 만들어 robustness를 높이는 데 중요하다.

</details>

<details>
<summary>10. Near-term physical Turing test는 무엇을 뜻하는가?</summary>

답변: 모든 환경에서 완전한 general-purpose autonomy를 달성하는 것이 아니라, bounded physical tasks에서 인간과 비교 가능한 노동 수행 능력을 보여주는 것을 첫 milestone으로 보는 관점이다.

</details>

## PDF

<ul>
  <li><a href="{{ "/assets/pdfs/study/aix/Robotics_2.pdf" | relative_url }}" target="_blank" rel="noopener">Robotics_2.pdf</a></li>
</ul>
