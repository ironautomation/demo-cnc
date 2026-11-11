# ① 모션 연결 — EtherCAT 3축

> 영상: 공개 예정 · 다음 편 [② AI에게 PLC 코드 맡기기](../02-ai-plc/)

X20CP1684 PLC 에서 EtherCAT 으로 Yaskawa Σ-X 3축 서보팩을 붙이고, mapp Motion 축 그룹(`MpCnc3Axis`)으로 X·Y·Z 를 움직이기까지의 구성입니다. 이 편에서 쓰는 파일은 모두 [`src/PLC`](../../src/PLC) 에 있습니다.

## 구성 한눈에

```
X20CP1684 ── X20IF10G1-1 (EtherCAT 마스터, IF1)
                 └─ Yaskawa SGDXT 3축 서보팩 (CoE, DS402 CSP) ── X · Y · Z 모터
X20DI9372   ── 축 리밋 · 원점 센서 9점 (축마다 −리밋 · 원점 · +리밋)
```

| 단계 | 파일 | 하는 일 |
|---|---|---|
| 1. 하드웨어 | [`Physical/Config1/Hardware.hw`](../../src/PLC/Physical/Config1/Hardware.hw) | 모듈 배치, EtherCAT 마스터(X20IF10G1-1) 아래 서보팩 연결 |
| 2. 드라이브 설정 | [`X20CP1684/DTM/`](../../src/PLC/Physical/Config1/X20CP1684/DTM/) | 서보팩 ESI(DTM) — 축 A·B·C 의 2nd PDO 매핑(제어 워드 · 목표 위치 / 상태 워드 · 실제 위치) |
| 3. 드라이브 어댑터 변수 | [`Logical/Global.var`](../../src/PLC/Logical/Global.var) 맨 위 `gDS402_X/Y/Z` | `McPureVAxDS402CspAdapterPvType` — 드라이브와 mapp 사이 PDO 값 |
| 4. I/O 매핑 | [`X20CP1684/IoMap.iom`](../../src/PLC/Physical/Config1/X20CP1684/IoMap.iom) | PDO 채널 → `gDS402_*` · 리밋/원점 센서 → `gDS402_*.DigitalInputs` |
| 5. 축 · 축 그룹 | [`X20CP1684/mappMotion/3AxesCNCXYZ/`](../../src/PLC/Physical/Config1/X20CP1684/mappMotion/3AxesCNCXYZ/) | `Config_5.purevaxcfg`(DS402 CSP 축 3개) · `Config_1.axesgroup` · `Config_3.mechanicalsystem`(3축 직교) · `Config_2.axis` |
| 6. 프로그램 | [`Logical/Cnc/Main`](../../src/PLC/Logical/Cnc/Main) · [`Logical/Motion/AxisManual`](../../src/PLC/Logical/Motion/AxisManual) | 축 그룹 `gCncXYZ` 를 `MpCnc3Axis` 로 운전, 축마다 조그 · 위치 이동 |

## 축 설정 값 (`Config_5.purevaxcfg`)

| 항목 | 값 |
|---|---|
| 축 인터페이스 | DS402 CSP (Cyclic Synchronous Position) |
| 엔코더 | 1 048 576 inc/rev (20 bit), 증분형 — 전원을 켤 때마다 원점을 다시 잡음 |
| 1 회전당 이동 | 10 mm |
| 원점 방식 | SwitchGate, 음(−) 방향 시작, 음(−) 에지 |
| 리밋 센서 | B접점(NC), Level Low = 동작 |
| 원점 순서 | Z 먼저, 그다음 X · Y (축 그룹 기능 HomingOrder) |

모터나 드라이브를 바꿀 때는 3·4·5단계(`gDS402_*` 블록, `IoMap.iom`, `mappMotion` 축 설정, `DTM/`)만 바뀌고, 프로그램은 mapp 축 참조(`gAxis_X/Y/Z`, `gCncXYZ`)만 쓰므로 그대로입니다.

## 확인 순서

1. 빌드 — [`docs/build-cli.md`](../../docs/build-cli.md) (Main 오류 0)
2. 전송 후 Automation Studio 의 mapp Cockpit 이나 Watch 에서 `gDS402_X.StatusWord` 가 바뀌는지 — EtherCAT 통신 확인
3. 서보 ON → 원점 복귀(Z → X · Y) → 축마다 조그

> EtherCAT 구성은 데모 장비 기준입니다. 실제 장비에 쓸 때는 Automation Studio 에서 EtherCAT 네트워크(마스터 DTM)를 한 번 다시 확인하세요.
