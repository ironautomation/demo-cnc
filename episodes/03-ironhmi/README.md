# ③ IronHMI로 장비 조작 화면 만들기

> 영상: 공개 예정 · 앞 편 [② AI에게 PLC 코드 맡기기](../02-ai-plc/) · 다음 편 [④ 3D 디지털 트윈](../04-twin/)

**IronHMI로 장비 조작 화면을 만드는 여덟 단계 — 화면 파일(텍스트) → PLC 연결(OPC UA) → AI 요청 → 검사·미리보기 → 실행·연결 → IronStudio로 다듬기 → 조그 안전 → 배포**

쇼케이스 녹화에서 AI에게 "축 위치, 서보 상태, 조그 버튼이 있는 화면을 만들어줘"라고 요청한 뒤 연결까지 4분 30초가 걸렸습니다(조그 버튼 컨트롤 15:04:53 → 화면 XAML 15:05:30 → 빌드 15:05:56 → 연결 15:07:42).

## 프로젝트 파일 구조

IronHMI 런타임은 아래 텍스트 파일을 **빌드 없이** 읽어 화면을 띄웁니다. 그래서 AI가 읽고 쓰기 쉽고, IronStudio 에서 손으로 고쳐도 같은 파일이 바뀝니다.

| 파일 · 폴더 | 하는 일 |
|---|---|
| `project.manifest.json` | 프로젝트 정보와 PLC 연결(`communication` — OPC UA 주소 · Namespace · 보안). IronStudio 의 Manifest › OPC UA Clients 표가 이 값을 고칩니다 |
| `Frame.xaml` | 화면 틀 — 네비 영역과 콘텐츠 영역 |
| `Screen/Layout/LayoutRail.xaml` | 오른쪽 레일 — 장비 · 운전 상태 · 알람 · 탭 네비 · 시계 · 로그인 · 종료 |
| `Screen/Panel/*.xaml` | 탭 화면 5개: 작업현황 · I/O 확인 · 구성설정 · 작업기록 · 작업이력 |
| `Config/*.xml` | 3D 카메라(`View3D`), 프로그램 폴더(`CncFolder`), I/O 목록(`IOInfo`), 헤드 · 장비 값 |
| `alarms.json` | 알람 조건(PLC 변수 → 메시지 · 원인 · 조치) |
| `Controls/*.dll` · `Plugins/` | 커스텀 컨트롤 팩 · 헤드 플러그인 (빌드된 DLL) |
| `Models/cnc_gantry.glb` | 3D 트윈 모델 ([④](../04-twin/)) |
| `tools/make-config.ps1` | 구성설정 패널(`Panel_Config.xaml`)을 만드는 생성 스크립트 — 이 패널은 XAML 이 아니라 스크립트를 고칩니다 |
| `Database/` · `Logs/` | 런타임이 만드는 폴더(계정 정보 포함) — git 에 넣지 않음 |

- 영상에서 쓴 가로판 [`src/HMI`](../../src/HMI) 1920×1080 과 영상 9-1 의 세로판 [`src/HMI_Vertical`](../../src/HMI_Vertical) 1080×1920 을 공개합니다. 두 화면은 태그 · 컨트롤 · 3D 모델이 같고 배치만 다릅니다.
- PLC 변수 노드 키: 전역 변수는 `::AsGlobalPV:<변수 경로>`, 태스크 변수는 `::<태스크>:<변수>` (예: `::RingBuffer:BufferX`).
- 기본 연결 주소는 같은 PC 의 ARsim(`opc.tcp://127.0.0.1:4840`)입니다. 실제 장비에서는 `project.manifest.json` 의 주소를 바꿉니다.

## 검사 · 미리보기

```bat
ironhmi-cli check src\HMI --engine-root <IronHMI 설치 경로>\bin
ironhmi-cli render src\HMI --engine-root <IronHMI 설치 경로>\bin
```

`ironhmi-cli` 는 IronStudio 의 `bin` 폴더에 들어 있습니다. `check` 는 화면 파일을 검사하고(틀린 속성 이름 · 없는 태그), `render` 는 장비 없이 화면 그림을 그립니다.

## 조그 감시 (`gJogAlive`)

조그는 "누르는 동안만" 움직여야 합니다. 그런데 HMI 창이 갑자기 닫히거나 PC 가 멈추면, 조그 버튼을 뗐다는 신호가 PLC 에 가지 않습니다. 그래서 PLC 가 HMI 의 생존 신호를 따로 봅니다.

| 쪽 | 하는 일 |
|---|---|
| HMI | 조그하는 동안 `gJogAlive`(UINT, `Global.var`)를 **0.1초마다** 바꿔 씀 |
| PLC (`Motion/AxisManual`) | `gJogAlive` 가 **0.5초** 동안 그대로면 모든 조그를 멈춤 |
| 예외 | 이 값을 한 번도 바꾸지 않는 HMI(예: 다른 화면)는 감시하지 않음 |

영상 8-3 처럼 조그 중에 창을 Alt+F4 로 닫아도 축이 0.5초 안에 섭니다. 이 감시는 소프트웨어 보조 장치이며 비상정지 회로를 대신하지 않습니다.

## 막혔을 때

1. **값이 안 보임(BadResourceUnavailable)** — 코드가 한 번도 쓰지 않는 전역 변수는 PLC 에 만들어지지 않습니다. 태스크에서 한 번 참조하세요(예: `Main/Init.st` 의 `teachSum`).
2. **창이 잘림** — 고정 크기 화면이라 Windows 화면 배율이 100% 여야 합니다.
3. **컨트롤 DLL 오류** — 컨트롤 DLL 은 런타임과 같은 구성으로 빌드합니다(Windows 7 장비는 Net48 = .NET Framework 4.8, x86).

## 자료

- [`prompts.md`](prompts.md) — 화면 초안을 AI와 만들 때 쓴 프롬프트 모음 (설계 → 계획 → 작업 → 마무리)

## 사용 환경

IronHMI 런타임(net8.0-windows / Windows 7 은 Net48) · IronStudio · ironhmi-cli · OPC UA · B&R X20CP1684 · Automation Studio 6.5.1
