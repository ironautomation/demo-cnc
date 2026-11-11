---
name: release-tag
description: |
  영상 편(에피소드)을 공개하면서 릴리스 태그와 GitHub Release 를 만들 때 사용한다. 이 저장소의
  태그 규칙(epNN-이름)과 생성 기준을 따른다. "릴리스 만들어줘", "태그 만들어줘", "ep03 공개",
  "영상 나갔으니 자료 올려줘", "릴리스 정리" 같은 요청에 사용한다.
---

# 편별 릴리스 절차

이 저장소는 유튜브 상세편 시리즈의 예제 저장소다. **영상 한 편 = 태그 하나 = GitHub Release 하나.**
코드(`src/`)는 모든 편이 같고, 편마다 `episodes/NN-*/` 폴더가 늘어난다.

## 태그 이름

| 편 | 폴더 | 태그 |
|---|---|---|
| ① 모션 연결 | `episodes/01-motion` | `ep01-motion` |
| ② AI에게 PLC 코드 맡기기 | `episodes/02-ai-plc` | `ep02-ai-plc` |
| ③ IronHMI 조작 화면 | `episodes/03-ironhmi` | `ep03-ironhmi` |
| ④ 3D 디지털 트윈 | `episodes/04-twin` | `ep04-twin` |
| ⑤ IronCAM | `episodes/05-ironcam` | `ep05-ironcam` |

새 편이 생기면 `epNN-짧은영문이름` 을 이 표와 루트 README 의 편 목록에 함께 추가한다.

## 태그를 만들기 전 — 전부 만족해야 한다

- [ ] 그 편 폴더가 PR 로 main 에 병합됐다 (main 직접 커밋 금지)
- [ ] main 기준 빌드가 된다 — Main 오류 0 (`docs/build-cli.md`)
- [ ] 그 편 README 와 루트 README 편 목록에 "공개 예정" · `TODO` 가 남아 있지 않다 (영상 링크, 이 편에 넣기로 한 파일 포함)
- [ ] 민감 정보 검사 0 건 — 고객사 이름 · 개인 경로 · 내부 IP · 이메일(문의처 제외)
- [ ] 영상이 공개됐거나 공개 당일이다 — **사용자에게 확인받는다** (Claude 가 판단하지 않는다)

하나라도 아니면 태그를 만들지 말고 무엇이 남았는지 사용자에게 알린다.

## 만들기

```bash
git switch main && git pull
git tag -a ep03-ironhmi -m "③ IronHMI로 장비 조작 화면 만들기 — 영상 자료"
git push origin ep03-ironhmi
gh release create ep03-ironhmi --title "③ IronHMI로 장비 조작 화면 만들기" --notes-file <본문.md>
```

Release 본문: 영상 링크 · 그 편 폴더 링크 · 이 편에서 새로 들어온 파일 · 사용 환경.

그 뒤 루트 README 편 목록의 영상 칸을 채우는 PR 을 올린다.

## 하지 않는 것

- 공개된 태그를 옮기거나 지우지 않는다. 설명란 링크가 깨진다.
  고칠 것이 있으면 main 에 PR 로 고치고, 필요하면 `ep03-ironhmi.1` 처럼 새 태그를 만든다.
- 영상 공개 전에 태그를 push 하지 않는다 (저장소가 Public 이면 미리 보인다).
