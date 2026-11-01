# Spotify Glass · v0.1.0 preview

Windows Spotify 데스크톱 앱용 Spicetify 커스텀 감상 화면입니다. 유리 느낌의 팝업 감상 화면, Lyrics Plus 가사, 작은 라이브러리/검색 패널, 기본 대기열 연결, 볼륨 조절을 제공합니다.

Spotify 또는 Spicetify 공식 프로젝트가 아닙니다. 첫 공개용 미리보기 버전이며 다른 PC에서의 실제 설치 검증은 아직 필요합니다.

## 2026-11-01 업데이트

발매일을 앨범 커버 바로 아래 오른쪽에 작은 글자로 표시합니다. 배경·테두리 없이 글자 불투명도는 56%입니다. 버전은 v0.1.0으로 유지하며, 이전 ZIP을 받은 사용자는 다시 다운로드해야 합니다. 기존 설치를 제거한 뒤 새 ZIP으로 재설치하세요.

## 준비

- Windows의 Spotify 데스크톱 앱과 Spicetify가 먼저 설치되어 있어야 합니다.
- 확인한 기준: Spotify `1.2.94.583.g60394bd5`, Spicetify `2.46.4`.
- 다른 버전의 자동 호환은 보장하지 않습니다. Spotify 프로그램이나 Spicetify 실행 파일은 배포본에 들어 있지 않습니다.
- Spicetify 초기 설정과 Spotify 원본 백업을 먼저 완료하세요. 설치 안내: https://spicetify.app/docs/getting-started

## 처음이라면: Spicetify 설치부터

처음 사용하는 분은 [Windows 설치 가이드](docs/WINDOWS_SETUP.md)를 순서대로 따라 하세요. Spotify 설치 → Spicetify 설치 → 원본 백업 → Spotify Glass 적용까지 안내합니다.

1. [Spotify Windows 앱](https://www.spotify.com/download/windows/)을 설치하고 로그인한 상태로 1분 이상 실행한 뒤 완전히 종료합니다. Spicetify는 공식 설치판을 권장하며 Microsoft Store판은 부분 지원입니다.
2. **관리자 권한이 아닌 PowerShell**에서 다음 명령을 실행합니다.

   ```powershell
   winget install --id Spicetify.Spicetify --exact
   ```

3. PowerShell을 닫았다가 새로 열고, 아래 명령을 **한 줄씩** 실행합니다.

   ```powershell
   spicetify --version
   spicetify backup apply
   ```

4. Spotify가 다시 실행됐다면 종료하고, [배포 페이지](https://github.com/Queenkiki-GAGCITY/spotify-glass/releases/tag/v0.1.0)의 **Spotify-Glass-v0.1.0.zip**을 받아 전체 압축 해제합니다. 압축을 푼 폴더의 PowerShell에서 실행하세요.

   ```powershell
   .\Install.ps1
   spicetify auto
   ```

Marketplace는 이 패치에 필수가 아닙니다. 명령어를 찾지 못하거나 Store판 경고가 표시되면 [상세 가이드의 문제 해결](docs/WINDOWS_SETUP.md#문제-해결)을 확인하세요. 최신 Spicetify가 설치돼도 이 미리보기 패치가 최신 Spotify와 자동으로 호환되는 것은 아닙니다.

## 설치

ZIP 전체를 압축 해제하고 Spotify를 완전히 종료합니다. 압축 해제한 폴더에서 관리자 권한이 아닌 PowerShell을 열어 실행합니다.

```powershell
.\Install.ps1
spicetify auto
```

Windows가 다운로드 파일을 차단한다면 내용을 확인한 후 해당 폴더의 PowerShell 파일만 `Unblock-File`로 해제하세요. 실행 정책을 컴퓨터 전체에 대해 변경할 필요는 없습니다. 조직이 스크립트를 제한하는 PC에서는 조직 정책을 따라야 합니다.

설치기는 현재 사용자 AppData의 Spicetify 폴더를 사용합니다. 별도 설정 경로라면 `-ConfigRoot '실제 설정 폴더'`를 지정하세요. 기존 Spotify 설치 경로·다른 확장 목록은 유지하고, 테마는 QuietLyrics로 바꿉니다. 같은 이름의 파일과 변경 전 설정은 `GlassUI-backups`에 백업합니다. 이미 이 배포본이 설치되어 있으면 제거 후 재설치하세요.

## 제거

Spotify를 종료하고 같은 폴더에서 실행합니다.

```powershell
.\Uninstall.ps1
spicetify auto
```

기존 테마와 덮어썼던 파일을 복원하며, 설치 후 사용자가 수정한 파일은 덮어쓰지 않고 경고합니다. 이후 추가한 다른 확장도 유지합니다. 백업은 자동 삭제하지 않습니다. `spicetify apply`가 실패하면 오류를 먼저 해결한 뒤 다시 실행하세요.

## 사용

- 상단 Full App Display 아이콘: 감상 화면 열기/닫기. F11도 사용 가능합니다.
- 왼쪽 위 책: 작은 라이브러리와 곡 목록. 검색·더블클릭 재생·우클릭 대기열 추가.
- 아래 Spotify 기본 대기열 버튼: 기본 대기열 표시.
- 오른쪽 아래 Lyrics Plus 옵션 옆: 볼륨·음소거.
- 오른쪽 위 톱니바퀴: 감상 화면 설정과 Lyrics Plus 설정.
- 검색창을 여는 동안에는 감상 화면 유지, 다른 페이지로 이동하면 최소화.

개인 Spotify 설정·좋아요 목록·로그인 정보·가사 캐시는 포함하지 않습니다. 이미 저장된 Full App Display 옵션은 유지하므로 기존 사용자의 초기 화면은 다를 수 있습니다.

## 개발·호환 수정

실제 배포되는 수정 가능한 소스는 `assets/`에 있습니다. `manifest.json`은 배포 파일의 해시입니다. 에셋을 수정한 뒤 `Build.ps1`을 실행하면 해시와 배포 ZIP이 갱신됩니다. 원래 작업에 사용한 패치 생성기와 모의 테스트는 `source/`에 보관했습니다. 배포 에셋을 직접 변경했다면 생성기에도 해당 변경을 반영한 뒤 다음 릴리스를 만드세요.

검증:

```powershell
.\tests\Install-Uninstall.ps1
```

이 테스트는 별도 임시 폴더에 설치·제거하며 실제 Spotify를 변경하지 않습니다. 개발 테스트 옵션인 `-SkipApply`는 파일 동작만 검사하며 앱에 적용하지 않습니다. Node가 있으면 `source` 폴더에서 `node work/test-fad-queue.cjs`와 `node work/test-fad-return.cjs`도 실행할 수 있습니다.

업데이트 후 확인할 연결: `control-button-queue`, `fullscreen-mode-button`, `Desktop_PanelContainer_Id`, 검색 listbox의 ID/표시 클래스, Spotify Platform API. 기능 변경 뒤 실제 앱 검증도 필요합니다. 업데이트 시 Spotify 파일을 구버전으로 덮어쓰지 말고 Spicetify의 해당 버전 지원부터 확인하세요.

## 공유

ZIP 파일만 전달해도 설치할 수 있습니다. GitHub에 올리려면 `PUBLISHING.md`를 참고하세요. 개인 복원용 ZIP과 이 공개 배포본을 혼동하지 마세요.

## 라이선스·출처

Spicetify의 Full App Display 및 Lyrics Plus를 수정/포함합니다. 원저작자 표기와 소스를 보존하며 LGPL 2.1 라이선스 전문을 `LICENSE`에 포함했습니다. 세부 출처·변경 범위는 `THIRD_PARTY_NOTICES.md`를 참고하세요.
