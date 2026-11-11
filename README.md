# demo-cnc

**3축 데모 CNC 하나로 보는 PLC · HMI · 3D 트윈 · CAM — 유튜브 「Iron Automation CNC 기술 쇼케이스」 상세편 예제 저장소**

디스펜서 · 레이저 헤드를 단 3축 데모 CNC(B&R X20CP1684, Yaskawa Σ-X, EtherCAT)의 PLC 프로젝트와 IronHMI 화면, 그리고 상세편마다 영상에 나온 자료를 담았습니다. 코드는 모든 편이 같고(상세편 촬영 시점 기준), 편마다 `episodes/` 폴더와 릴리스 태그가 하나씩 늘어납니다.

- ▶ 쇼케이스 본편 — [youtu.be/Dotccp900lI](https://youtu.be/Dotccp900lI)
- 채널: [@IronAutomation-Inc](https://www.youtube.com/@IronAutomation-Inc)

## 편 목록

| 편 | 주제 | 자료 폴더 | 태그 | 영상 |
|---|---|---|---|---|
| ① | 모션 연결 — EtherCAT 3축 | [`episodes/01-motion`](episodes/01-motion/) | `ep01-motion` | 공개 예정 |
| ② | AI에게 PLC 코드 맡기기 | [`episodes/02-ai-plc`](episodes/02-ai-plc/) | `ep02-ai-plc` | 공개 예정 |
| ③ | IronHMI로 장비 조작 화면 만들기 | [`episodes/03-ironhmi`](episodes/03-ironhmi/) | `ep03-ironhmi` | 공개 예정 |
| ④ | 장비 없이 먼저 돌리는 3D 디지털 트윈 | [`episodes/04-twin`](episodes/04-twin/) | `ep04-twin` | 공개 예정 |
| ⑤ | 이미지 한 장을 레이저 G코드로, IronCAM | [`episodes/05-ironcam`](episodes/05-ironcam/) | `ep05-ironcam` | 공개 예정 |

영상 설명란의 "▶ 자료" 링크는 그 편의 태그(예: `…/tree/ep02-ai-plc/episodes/02-ai-plc`)를 가리킵니다. 태그는 영상을 공개하는 날 만들고, 그 뒤로는 바꾸지 않습니다.

## 저장소 구조

```
CLAUDE.md · .claude/           AI 도구가 읽는 설명서 · 규칙 · 훅 (②)
src/PLC/                       Automation Studio 프로젝트 DemoCNC.apj (①②④)
src/HMI/                       IronHMI 가로 화면(영상에서 쓴 화면), 3D 모델 (③④)
gcode/                         시험 G코드 (②④)
docs/build-cli.md              명령줄 빌드 (②)
episodes/NN-*/                 편마다 영상 장면 ↔ 파일, 표, 예제
```

## 직접 해 보기

### 사용 환경

- B&R Automation Studio 6.5.1 · mapp Motion 6.7.2 · PLC X20CP1684
- (③④) IronHMI 런타임 · IronStudio — [IronTools v2 무료체험](https://www.ironautomation.com/trial)
- (②) AS Code Copilot · Claude Code
- (⑤) IronCAM

### 순서

1. 저장소를 받습니다.
   ```bash
   git clone https://github.com/ironautomation/demo-cnc.git
   ```
2. Automation Studio 에서 `src/PLC/DemoCNC.apj` 를 열고 빌드합니다(AS 의 Rebuild All 또는 [`docs/build-cli.md`](docs/build-cli.md)). Main 오류 0 이면 됩니다.
3. 장비가 없으면 ARsim(시뮬레이션)으로 전송하고, IronHMI 로 `src/HMI` 을 열어 3D 트윈에서 `gcode/` 의 시험 파일을 돌려 봅니다. HMI 는 기본으로 `opc.tcp://127.0.0.1:4840` 에 붙습니다.
4. 실제 장비에서는 PLC IP(`Hardware.hw`, 예시 값 `192.0.2.10`)와 G코드 공유 폴더 주소 · 계정(`Logical/Cnc/PrgShare/Variables.var` 의 `shareParam`, 예시 값)을 현장에 맞게 바꿉니다.

## 주의

- 이 프로젝트는 **데모 장비 기준**입니다. 그대로 다른 장비에 쓰지 마세요.
- PLC 의 OPC UA 는 데모용으로 익명 접속을 허용하고, HMI 는 보안 없이(`useSecurity: false`) 연결합니다. 실제 장비에서는 OPC UA 보안과 계정을 설정하세요.
- 안전 회로는 별도로 설계해야 합니다. 이 코드의 비상정지 처리는 소프트웨어 반응일 뿐 안전 회로가 아닙니다.
- 실기 운전 전 비상정지를 반드시 확인하세요. 레이저를 쓸 때는 보호 안경 등 레이저 안전 수칙을 지키세요.

## IronTools

- IronTools v2 무료체험: [ironautomation.com/trial](https://www.ironautomation.com/trial)
- 문의: ironauto@ironautomation.com · 02-6447-2886

## 라이선스

- PLC ST 코드 · 훅 · 스크립트 · 문서 · 예제: [MIT](LICENSE)
- IronHMI 프로젝트(`src/HMI`): [LICENSE-HMI.md](LICENSE-HMI.md)
- `src/PLC/Logical/Libraries/` 는 B&R 이 배포하는 라이브러리이며 MIT 대상이 아닙니다.
- 함께 들어 있는 오픈소스 · 제조사 파일: [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)

## 상표

Claude 는 Anthropic 의 상표입니다. B&R, Automation Studio, mappCNC, mapp Motion 은 B&R Industrial Automation 의 상표입니다. YASKAWA 와 Σ-X 는 YASKAWA Electric Corporation 의 상표입니다. EtherCAT 은 Beckhoff Automation GmbH 의 등록 상표입니다. GitHub Copilot 은 GitHub, Inc. 의 상표입니다. 그 밖의 이름은 각 소유자의 상표입니다.
