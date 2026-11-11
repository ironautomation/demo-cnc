# 명령줄 빌드 (BR.AS.Build.exe)

Automation Studio 화면을 열지 않고 PLC 프로젝트를 빌드하는 방법입니다. Claude Code 같은 AI 도구가 코드를 고친 뒤 스스로 빌드 결과를 확인할 때 씁니다.

## 1. 빌드 도구 위치

Automation Studio 6 를 설치하면 같이 들어 있습니다.

```
C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe
```

옵션은 인수 없이 실행하면 나옵니다(`-c` 구성 이름, `-t` 임시 폴더, `-all` 다시 빌드 등).

## 2. 짧은 Temp 경로 만들기

AS 빌드는 `Temp\Objects\...` 아래에 깊은 폴더를 만듭니다. 저장소를 긴 경로에 두면 Windows 경로 길이(260자) 제한에 걸려 엉뚱한 오류가 날 수 있으므로, 임시 폴더를 짧은 경로로 따로 줍니다.

```bat
mkdir D:\asb\tmp
```

## 3. 다시 빌드(Rebuild)

프로젝트 파일(`.apj`)은 **전체 경로**로 줍니다. `src\PLC\DemoCNC.apj` 처럼 상대 경로를 주면 빌드하지 않고 사용법(`Usage: BR.AS.Build.exe file... [options]`)만 출력합니다. 아래 명령은 모두 저장소 루트에서 실행하며, 현재 폴더로 전체 경로를 만듭니다.

명령 프롬프트(cmd):

```bat
"C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "%CD%\src\PLC\DemoCNC.apj" -c Config1 -all -t D:\asb\tmp
```

PowerShell:

```powershell
& "C:\Program Files (x86)\BRAutomation\AS6\bin-en\BR.AS.Build.exe" "$PWD\src\PLC\DemoCNC.apj" -c Config1 -all -t D:\asb\tmp
```

Git Bash:

```bash
"/c/Program Files (x86)/BRAutomation/AS6/bin-en/BR.AS.Build.exe" "$(pwd -W)/src/PLC/DemoCNC.apj" -c Config1 -all -t 'D:\asb\tmp'
```

- `-c Config1` : 이 프로젝트의 구성 이름 (`src/PLC/Physical/Config1`)
- `-all` : 이전 산출물을 지우고 처음부터 다시 빌드
- 산출물은 `src/PLC/Binaries`, `Diagnosis` 에 생깁니다 (`.gitignore` 로 제외).

## 4. 결과 읽기

마지막 줄에 요약이 나옵니다.

```
Build: 3 error(s), 3 security risk(s), 2 warning(s)
```

ST 코드 오류는 `파일경로: (Ln: 줄, Col: 칸) error 번호:내용` 꼴로 나옵니다. **ST 파일(`.st` · `.var` · `.typ`)에서 나온 error 가 0 이면 Main 을 포함한 PLC 프로그램은 정상**입니다.

이 저장소를 확인한 결과(Automation Studio 6.5.1, 2026-11-07):

| 구분 | 결과 |
|---|---|
| ST 코드 (Main · OpMode · PrgShare · AxisManual · Handwheel · RingBuffer · Dispenser · Laser) | **오류 0** |
| 경고 | 2 건 (`AxisManual` 의 DINT → REAL 암시적 변환) |
| 남은 오류 | mappView 웹 화면 빌드의 grunt 관련 2 건 — 아래 설명 |

### mappView grunt 오류 2건은 ST와 무관합니다

```
error :'grunt'은(는) 내부 또는 외부 명령, 실행할 수 있는 프로그램, 또는 배치 파일이 아닙니다.
error :Could not find file '...\mappView\Widgets\temp\buildReport.json'.
```

(첫 번째 메시지는 콘솔 코드 페이지에 따라 두 줄로 찍혀 요약에서는 3건으로 셀 수 있습니다.)

명령줄로 실행하면 Automation Studio 화면이 잡아 주던 mappView 위젯 빌드 도구(grunt, node)의 경로가 PATH 에 없어서 생기는 오류입니다. 첫 오류 때문에 두 번째(빌드 보고서 파일 없음)가 따라 나옵니다. ST 코드를 바꾸지 않아도 똑같이 나오며, PLC 프로그램(ST)의 컴파일 결과와는 관계가 없습니다. 웹 화면(mappView)까지 빌드해서 전송하려면 Automation Studio 에서 빌드하세요.

## 5. Automation Studio 에서 빌드

`src/PLC/DemoCNC.apj` 를 열고 Project › Rebuild All. 출력 창의 Main 오류가 0 이면 됩니다. 장비가 없으면 ARsim(시뮬레이션)으로 전송해 IronHMI 3D 트윈과 함께 확인할 수 있습니다.
