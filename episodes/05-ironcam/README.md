# ⑤ 이미지 한 장을 레이저 G코드로, IronCAM

> 영상: 공개 예정 · 앞 편 [④ 3D 디지털 트윈](../04-twin/) · 시리즈 마지막 편

IronCAM 으로 사진을 레이저 각인 G코드로, 도면 선을 윤곽 G코드로 만들고, 출력 전에 진단으로 막습니다. 만든 G코드는 [③](../03-ironhmi/) IronHMI 에서 고르고 [④](../04-twin/) 트윈으로 판정한 뒤 실기로 갑니다.

## 이 장비에 맞춘 출력

| 항목 | 값 |
|---|---|
| 레이저 켜기 · 끄기 | `M61` · `M62` |
| 레이저 출력 | S 대신 G코드 변수 줄 `LaserPower = n` (%, 0~100 — PLC 가 100 % 로 자름) |
| 출력 형식 | B&R (mapp CNC) |
| 영상에서 쓴 값 | 줄 간격 0.5 mm · 회색 단계 · 세기 0~100 % · 이송 1000 mm/min |

## 명령 모음 (`ironcam` CLI)

화면에서 하는 일은 명령줄로도 할 수 있습니다. 결과(G코드)는 표준 출력 또는 `-o` 파일, 진단은 표준 오류로 나옵니다.

```bat
:: 사진 → 래스터 각인 G코드 (폭은 꼭 줘야 함 — 없으면 CNC3029)
ironcam engrave photo.jpg --width 110 --interval 0.5 --mode gray --power-code LaserPower --on M61 --off M62 --feed 1000 -o photo.nc

:: 디더링으로 (fs · atkinson · jarvis · stucki · sierra)
ironcam engrave photo.jpg --width 110 --mode dither --dither atkinson -o photo_dither.nc

:: 그림의 윤곽 → DXF (contour 에 그대로 넣음)
ironcam trace logo.png --width 80 --mode outline --dxf logo.dxf

:: 도면 선 → 레이저 윤곽 G코드 (색 · 레이어로 선 고르기, 원점 9칸)
ironcam contour samples\LID-260x360.dxf --layer OUTLINE --origin bl --laser --power 80 --power-code LaserPower -o lid.nc

:: 진단 코드 뜻 · 목록
ironcam explain CNC3029
ironcam list codes

:: 메시지 언어
ironcam --lang ko|en|system ...
```

종료 코드: `0` 성공(경고 포함) · `1` 검증 오류 · `2` 사용법/입력 오류 · `70` 내부 오류.

## 진단 코드 표 (이 영상에 나오는 것)

진단에 **오류**가 하나라도 있으면 G코드를 쓰지 않습니다. 전체 목록은 `ironcam list codes`.

| 코드 | 뜻 | 고치는 법 |
|---|---|---|
| CNC1202 | DXF 에서 선분을 하나도 읽지 못함 | ASCII DXF 로 다시 저장 |
| CNC1203 | DWG 를 읽지 못함 | DXF 로 저장해서 열기 |
| CNC1207 | 타원 · 스플라인 등 G02/G03 으로 낼 수 없는 곡선을 건너뜀 | CAD 에서 호 · 선으로 바꾸기 |
| CNC1208 | 고른 색 · 레이어에 선이 없음 | 색 · 레이어 선택 확인 |
| CNC1209 | 이미지 윤곽의 폭이 없음 | 폭(mm) 입력 |
| CNC3017 | 닫히지 않은 윤곽 경로가 있음 | 끊긴 선 · T 자 접합 확인 |
| CNC3024 | 레이저 파워가 없음 | 파워 칸 또는 켜기 지령의 S |
| CNC3029 | 래스터 각인 폭이 없음 | 폭(mm) 입력 — 이미지에는 물리 크기가 없음 |
| CNC3030 | 각인 값(줄 간격 · 파워 범위 · 오버스캔 · 이송 · 흰색 기준)이 범위를 벗어남 | 값 확인 |
| CNC3031 | 태울 점이 하나도 없음 | 흰색 기준을 낮추기 |
| CNC3032 | 이미지 파일을 읽지 못함 | PNG · JPG · BMP 로 저장 |
| CNC3037 | 각인 격자가 너무 큼 | 폭을 줄이거나 줄 간격을 늘리기 |
| CNC3044 | 파워 변수(%)인데 최대 파워가 100 초과 | 최대 파워 100 이하로 |
| CNC3045 | 이미지 각인 공정인데 이미지가 없음 | 이미지 가져오기 |
| CNC3046 | 선을 따라가는 공정인데 도면 선이 없음 | 도면 가져오기 |

## 예제 파일

- [`samples/LID-260x360.dxf`](samples/LID-260x360.dxf) — 모서리가 둥근 260 × 360 외곽 뚜껑 도면(Iron Automation 작성). 레이어: `OUTLINE` · `GROOVE` · `DISPENSE` · `HOLE` …
- 각인 사진과 그 G코드, 프로젝트 파일(`.ironcam`) — 이 편을 공개할 때 추가합니다

IronCAM 프로젝트 파일(`.ironcam`)은 JSON 텍스트입니다. G코드까지 담고, 출력(Ctrl E)하면 프로젝트도 저장됩니다.

## 사용 환경

IronCAM (net8.0, 한국어·영어) · ironcam CLI · B&R X20CP1684 · IronHMI · 레이저 헤드(출력 LaserPower %)
