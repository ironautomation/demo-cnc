# ② AI에게 PLC 코드 맡기기

> 영상: 공개 예정 · 앞 편 [① 모션 연결](../01-motion/) · 다음 편 [③ IronHMI 조작 화면](../03-ironhmi/)

> 폴더 · 태스크 이름: 영상 촬영 뒤 PLC 프로그램을 역할별 패키지로 묶었습니다. 영상의 `Logical/Main` = 지금 `Logical/Cnc/Main`, `AxisMgr` = `Motion/AxisManual`, `McMPG` = `Motion/Handwheel`, `IO` = `Cnc/OpMode`, `File` = `Cnc/PrgShare`, `Dispenser` · `Laser` = `Heads/` 아래입니다.

**AI에게 PLC 코드를 맡기는 여섯 단계 — 설명서 → 작은 일 Copilot → 큰 일 Claude → 안전장치 → 엔지니어 검토 → 빌드·실기**

## 영상 장면 ↔ 파일

| 장면 | 파일 | 내용 |
|---|---|---|
| 2-2 · 8-3 설명서 | [`CLAUDE.md`](../../CLAUDE.md) | 장비 구성 · 폴더 구조 · 이름 규칙 · 하면 안 되는 것 · 빌드·시험 방법 |
| 2-3 안전장치 | [`.claude/hooks/git-guard.sh`](../../.claude/hooks/git-guard.sh) | main 직접 커밋 · 강제 푸시 · 빌드 산출물 커밋 차단 ([규칙](../../.claude/rules/git-workflow.md)) |
| 4-4 · 6-1 · 7-1 코드 | [`src/PLC/Logical/Cnc/Main/Cyclic.st`](../../src/PLC/Logical/Cnc/Main/Cyclic.st) | CNC 시퀀서 — 명령 검사(`cmdAllowed`, `DI_Auto`), `commandStep` 100 완료 / 200 실패 |
| 5-1 · 5-2 백업 · 되돌리기 | [`home_and_run/`](home_and_run/) | 수정 전 백업(`original_Main`), AI 초안(`draft`), 되돌리는 방법 |
| 5-3 · 5-4 · 8-3 명령줄 빌드 | [`docs/build-cli.md`](../../docs/build-cli.md) | `BR.AS.Build.exe` — Main 오류 0, 남은 오류 2건(mappView grunt, ST와 무관) |
| 7-5 시험 G코드 | [`gcode/HOME_RUN_TEST.cnc`](../../gcode/HOME_RUN_TEST.cnc) | 11줄 · 100 mm 사각형 · Z45 · 헤드 꺼짐 |

AI 초안 작성은 3분, 엔지니어 검토는 2분이 걸렸습니다.

## 요청 문장 (원문)

> mappCNC 3축 그룹으로 원점 복귀 후 G코드를 실행하는 프로그램을 프로젝트에 추가해줘

AI는 새 프로그램 대신 `Main` 의 `Cyclic.st` 를 고쳤습니다. 축 그룹 `gCncXYZ` 하나에 `MpCnc3Axis` 는 하나만 붙을 수 있기 때문입니다. 바뀐 파일은 `Cyclic.st` · `Variables.var` 두 개(변수 `cmdHomeAndRun` · `chainStart`)이고, 엔지니어는 검토에서 `cmdHomeAndRun` 수락 조건에 `AND DI_Auto` 를 넣었습니다(수동 모드에서 실행 막기). 초안과 백업은 [`home_and_run/`](home_and_run/) 에 있습니다.

## 실패 신호 읽기

| 보이는 것 | 뜻 | 볼 곳 |
|---|---|---|
| `gEquipment.Output.Status.Rejected = 2` | START 가 거절됨 (서보 ON · 원점 · 자동 모드 중 하나가 안 됨) | `Main/Cyclic.st` 의 `cmdAllowed` |
| `commandStep = 200` | 동작이 실패로 끝남 | `gEquipment.Output.Status.StatusID` (MpCnc3Axis 오류 번호) |
| `commandStep` 이 10 에 머묾 | 원점 복귀가 끝나지 않음 | 원점 센서 · 리밋 센서 배선과 신호 |

## 돌리기 전 확인 다섯 가지

1. 비상정지 버튼이 눌리면 축이 멈추고 서보가 꺼지는지 먼저 확인합니다.
2. 헤드(디스펜서·레이저)를 끈 상태로 시험합니다 — 시험 G코드에는 헤드 켜기 코드가 없습니다.
3. 원점 복귀 순서(Z 먼저, 그다음 X·Y)와 원점 센서를 확인합니다.
4. 이송 속도(Feedrate override)를 낮춰 두고, 축 소프트 리밋 안에서 움직이는지 봅니다.
5. 처음엔 ARsim · 3D 트윈으로 경로를 본 뒤 실기로 넘어갑니다.

## AI에게 맡기지 않는 것

- 안전 회로와 비상정지 관련 코드 — 사람이 설계하고 사람이 고칩니다.
- main 브랜치 직접 반영 — AI는 브랜치에서만 작업하고, 엔지니어가 검토한 뒤 병합합니다.
- 실기 운전 판단 — 빌드 결과와 시험 결과는 엔지니어가 확인합니다.
- 하드웨어·I/O 구성, `RETAIN` 구조 변경 — 바꾸기 전에 사람이 정합니다.

## 사용 환경

Automation Studio 6.5.1 · mapp Motion 6.7.2 · X20CP1684 · AS Code Copilot · Claude Code
