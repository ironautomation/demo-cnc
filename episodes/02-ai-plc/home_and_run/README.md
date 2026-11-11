# 원점 복귀 후 G코드 실행 — 백업과 되돌리기 (영상 5-1 · 5-2)

AI에게 `Main` 프로그램을 고치게 하기 **전에** 지금 상태를 백업해 두고, 결과가 마음에 들지 않으면 그 백업으로 되돌립니다.

> 영상에 나온 수정 전 `original_Main/`(Main 파일 + `Cpu.sw`)과 AI 초안 `draft/`는 이 편을 공개할 때 이 폴더에 추가합니다.

## 1. 백업 (수정 전)

저장소 루트에서:

```bash
mkdir -p episodes/02-ai-plc/home_and_run/original_Main
cp src/PLC/Logical/Cnc/Main/* episodes/02-ai-plc/home_and_run/original_Main/
cp src/PLC/Physical/Config1/X20CP1684/Cpu.sw episodes/02-ai-plc/home_and_run/original_Main/
```

## 2. AI 초안 보관 (선택)

AI가 고친 결과를 비교용으로 남겨 둡니다.

```bash
mkdir -p episodes/02-ai-plc/home_and_run/draft
cp src/PLC/Logical/Cnc/Main/* episodes/02-ai-plc/home_and_run/draft/
```

## 3. 되돌리기

```bash
cp episodes/02-ai-plc/home_and_run/original_Main/*.st episodes/02-ai-plc/home_and_run/original_Main/*.var episodes/02-ai-plc/home_and_run/original_Main/IEC.prg src/PLC/Logical/Cnc/Main/
```

되돌린 뒤 다시 빌드해서(Main 오류 0) 원래대로 돌아왔는지 확인합니다 — [`docs/build-cli.md`](../../../docs/build-cli.md).

Git 을 쓰면 브랜치에서 작업하는 것만으로도 되돌릴 수 있습니다(`git restore src/PLC/Logical/Cnc/Main`). 폴더 백업은 Git 을 모르는 사람도 바로 따라 할 수 있는 방법입니다.
