#!/usr/bin/env bash
# PreToolUse(Bash|PowerShell) 훅 — 이 저장소의 규칙(.claude/rules/git-workflow.md) 중 "금지 사항"을 강제한다.
#
# CLAUDE.md와 스킬은 지침일 뿐 강제되지 않는다. 이 훅은 Claude가 규칙을 어기는
# 셸 명령을 실행하려 할 때 exit 2로 차단하고, 이유를 Claude에게 돌려준다.
#
# 등록: .claude/settings.json 의 hooks.PreToolUse (matcher: "Bash|PowerShell")
# 실행 권한: chmod +x .claude/hooks/git-guard.sh

raw=$(cat)
# 훅에는 JSON이 들어오므로 명령 안의 따옴표가 \" 로 이스케이프되어 있다.
# 패턴 매칭을 단순하게 하기 위해 역슬래시를 제거한 사본으로 검사한다.
input=$(printf '%s' "$raw" | tr -d '\\')

block() {
  echo "[이 저장소의 규칙 위반] $1" >&2
  exit 2
}

current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# ---------------------------------------------------------------------------
# 1. main / master 브랜치에 직접 commit 또는 push 금지
# ---------------------------------------------------------------------------
case "$input" in
  *"git commit"*|*"git push"*)
    br=$(current_branch)
    if [ "$br" = "main" ] || [ "$br" = "master" ]; then
      block "현재 브랜치가 '$br' 입니다. main에 직접 commit/push할 수 없습니다.
작업 성격에 맞는 브랜치(feature/ fix/ hotfix/ refactor/)를 만들어 옮긴 뒤,
Pull Request로 main에 반영하세요."
    fi
    ;;
esac

# main을 직접 지정한 push (다른 브랜치에 있더라도 차단)
case "$input" in
  *"git push"*"origin main"*|*"git push"*"origin master"*|\
  *"git push"*"HEAD:main"*|*"git push"*"HEAD:master"*)
    block "main/master로 직접 push할 수 없습니다. Pull Request를 사용하세요."
    ;;
esac

# ---------------------------------------------------------------------------
# 2. 강제 푸시 금지
# ---------------------------------------------------------------------------
case "$input" in
  *"git push"*" --force"*|*"git push"*" -f "*|*"git push --force-with-lease"*)
    block "강제 푸시(force push)는 허용되지 않습니다. 이력을 덮어쓰면 다른 개발자의 작업이 사라질 수 있습니다."
    ;;
esac

# ---------------------------------------------------------------------------
# 3. 빌드 산출물 / 개인 설정 commit 금지 (B&R Automation Studio)
# ---------------------------------------------------------------------------
case "$input" in
  *"git add"*)
    case "$input" in
      *"PLC/Temp/"*|*"PLC/Binaries/"*|*"PLC/Diagnosis/"*|*".isopen"*|*"PLC/"*".set"*)
        block "Temp / Binaries / Diagnosis 폴더와 *.set, *.isopen 파일은 commit할 수 없습니다. .gitignore로 제외되어 있는지 확인하세요."
        ;;
      *"git add ."*|*"git add -A"*|*"git add --all"*)
        # 전체 추가 자체는 허용하되, .gitignore가 없으면 경고 후 차단
        if [ ! -f .gitignore ]; then
          block "리포지토리에 .gitignore가 없습니다. 빌드 산출물 및 비밀정보가 통째로 커밋될 수 있습니다.
먼저 .gitignore를 추가하세요."
        fi
        ;;
    esac
    ;;
esac

# ---------------------------------------------------------------------------
# 4. 비밀정보로 보이는 파일 commit 금지
# ---------------------------------------------------------------------------
case "$input" in
  *"git add"*)
    case "$input" in
      *".pfx"*|*".pem"*|*".key"*|*"id_rsa"*|*"secrets."*|*".env"*)
        block "인증서·키·비밀정보 파일은 commit할 수 없습니다.
필요하다면 example 또는 template 파일(appsettings.example.json 등)로 관리하세요."
        ;;
    esac
    ;;
esac

# ---------------------------------------------------------------------------
# 5. 의미 없는 commit 메시지 금지
# ---------------------------------------------------------------------------
case "$input" in
  *"git commit"*)
    case "$input" in
      *'-m "수정"'*|*'-m "작업중"'*|*'-m "최종"'*|*'-m "진짜최종"'*|*'-m "이것저것 수정"'*|\
      *'-m "wip"'*|*'-m "WIP"'*|*'-m "update"'*|*'-m "fix"'*|*'-m "temp"'*)
        block "의미 없는 commit 메시지입니다. 나중에 봐도 어떤 작업인지 알 수 있게,
한국어로 무엇을 했는지 구체적으로 쓰세요. 예: 'CNC 원점복귀 순서 Z→XY 설정'"
        ;;
    esac
    ;;
esac

exit 0