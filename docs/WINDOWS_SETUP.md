# Windows: Spicetify와 Spotify Glass 처음 설치하기

이 가이드는 Windows 데스크톱 Spotify용입니다. 휴대폰·웹 플레이어용 설치법이 아닙니다. Spotify Glass는 Spotify/Spicetify 공식 제품이 아닙니다.

## 1. Spotify 준비

[Spotify 공식 Windows 다운로드](https://www.spotify.com/download/windows/)에서 설치합니다. 처음 설치했다면 로그인한 채 최소 1분 실행해 필요한 파일이 생성되도록 한 뒤 종료하세요. 창만 닫아도 트레이에서 실행 중일 수 있으므로 완전히 종료합니다.

Spicetify는 일반 설치판을 권장합니다. Microsoft Store판은 부분 지원되며, 수정 후에는 기존 Spotify 시작 메뉴 아이콘 대신 `spicetify auto`로 실행해야 할 수 있습니다. 이미 Store판을 사용한다면 설치 유형을 임의로 바꾸거나 삭제할 필요는 없습니다. 먼저 표시되는 경고와 공식 안내를 확인하세요.

## 2. Spicetify 설치

시작 메뉴에서 PowerShell을 검색하고 **일반 실행**합니다. 관리자 권한으로 실행하지 마세요.

```powershell
winget install --id Spicetify.Spicetify --exact
```

설치 프로그램이 약관을 표시하면 직접 읽고 동의 여부를 선택합니다. 완료되면 PowerShell을 닫았다가 새로 열어 확인합니다.

```powershell
spicetify --version
```

`winget`을 사용할 수 없다면 [Spicetify 공식 설치 문서](https://spicetify.app/docs/getting-started)의 Windows 설치 방법을 따르세요. 이 저장소에서 Spicetify 실행 파일을 재배포하거나 대신 설치하지는 않습니다.

## 3. 원본 백업과 초기 적용

Spotify가 완전히 종료된 상태에서 실행합니다.

```powershell
spicetify backup apply
```

Store판에 대한 경고가 나오면 부분 지원 내용을 먼저 확인합니다. Store판을 계속 사용하려는 경우에만 안내에 따라 진행하세요. 성공 메시지를 확인한 뒤 Spotify가 다시 실행되었다면 패치 설치 전에 다시 종료합니다.

## 4. Spotify Glass 적용

1. [v0.1.0 미리보기 다운로드](https://github.com/Queenkiki-GAGCITY/spotify-glass/releases/tag/v0.1.0)에서 **Spotify-Glass-v0.1.0.zip**을 받습니다. 자동 생성된 Source code ZIP과 구분하세요.
2. ZIP을 전체 압축 해제합니다. ZIP 안에서 스크립트를 바로 실행하지 마세요.
3. `Install.ps1`, `assets` 폴더가 함께 있는 폴더에서 PowerShell을 엽니다. 탐색기 주소창에 `powershell`을 입력하면 그 폴더에서 열 수 있습니다.
4. 아래 명령을 한 줄씩 실행합니다.

```powershell
.\Install.ps1
spicetify auto
```

기존 설정과 같은 이름의 파일은 설치 전 백업됩니다. 기본 테마는 QuietLyrics로 바뀌며 다른 확장 목록은 유지합니다. Marketplace는 별도 설치하지 않아도 됩니다.

## 5. 감상 화면 사용

Spotify 상단의 Full App Display 아이콘 또는 F11로 감상 화면을 엽니다. 다시 누르면 닫힙니다. 오른쪽 위 톱니바퀴에서 감상 화면 및 Lyrics Plus 설정을 열 수 있습니다. 기본 Lyrics Plus 바로가기 아이콘은 디자인상 숨겨져 있습니다.

## 문제 해결

### spicetify 명령을 찾을 수 없음

설치 직후에는 이전 PowerShell 창이 새 경로를 반영하지 못할 수 있습니다. 모든 PowerShell 창을 닫고 새로 열어 다시 확인하세요.

### 관리자 권한 경고

현재 창을 닫고 일반 PowerShell에서 다시 실행하세요. `--bypass-admin`으로 우회하지 마세요.

### 스크립트가 다운로드 파일로 차단됨

파일을 확인한 뒤 다음 명령으로 해당 배포 폴더의 PowerShell 파일만 차단 해제할 수 있습니다.

```powershell
Get-ChildItem -LiteralPath . -Filter '*.ps1' -Recurse | Unblock-File
```

이는 실행 정책 자체를 변경하는 명령이 아닙니다. 실행 정책/조직 정책으로 여전히 실행이 금지되면 조직 안내나 PowerShell 공식 안내를 따르세요. 컴퓨터 전체의 보안 정책을 일괄 해제하지 마세요.

### Spotify 업데이트 후 수정이 사라짐

우선 현재 Spotify 버전에 대한 Spicetify 지원 여부를 확인하고, 공식 안내에 따라 실행합니다.

```powershell
spicetify backup apply
```

Spicetify 자체 업데이트가 필요하면:

```powershell
spicetify update
```

Spicetify가 동작하더라도 이 패치의 화면 선택자/API는 별도 호환 수정이 필요할 수 있습니다. 새 버전에서 문제가 나면 Spotify/Spicetify 버전과 재현 방법을 Issues에 알려주세요. 비밀번호·토큰·개인 설정 전체는 올리지 마세요.

### 가사가 나오지 않음

Lyrics Plus 설정에서 제공자를 확인하세요. 모든 곡에 가사가 있는 것은 아니며 Spotify 기본 가사와 외부 가사 제공자의 결과도 다를 수 있습니다.

## 제거

Spotify를 종료하고 배포 폴더에서 실행합니다.

```powershell
.\Uninstall.ps1
spicetify auto
```

Spotify Glass만 제거하며 Spicetify 자체를 삭제하지 않습니다. 설치 후 수정한 파일은 보존될 수 있고 원본 백업은 남습니다.

## 공식 자료 및 버전

- [Spicetify 설치·업데이트 공식 문서](https://spicetify.app/docs/getting-started)
- [Spicetify FAQ](https://spicetify.app/docs/faq)
- [Spotify 공식 Windows 다운로드](https://www.spotify.com/download/windows/)

가이드 확인: 2026-11-01. 패치의 기존 확인 기준은 Spotify 1.2.94.583.g60394bd5 / Spicetify 2.46.4입니다. 새 버전이나 다른 PC에서의 호환을 보장하지 않습니다.
