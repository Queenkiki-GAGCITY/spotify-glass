# GitHub에 올리기

GitHub는 필수가 아닙니다. 친구에게 ZIP을 보내는 것부터 시작해도 됩니다. GitHub는 소스·버전·사용자 문제 제보를 한곳에서 관리할 때 편합니다.

1. GitHub 계정에 로그인한 뒤 새 저장소를 만듭니다. 이름 예: `spotify-glass`. 외부 공개가 목적이면 Public을 선택하세요.
2. 이 폴더의 README, 설치/제거 스크립트, assets, source, tests, manifest, LICENSE와 출처 문서를 저장소 루트에 올립니다. 개인 백업 ZIP·진단 결과·GlassUI-install.json·실제 AppData 폴더는 올리지 마세요.
3. 첫 공개는 `v0.1.0` 태그의 **pre-release**로 만드는 것을 권합니다. 본인 PC 외 다른 Windows PC에서 설치·제거·재생 기능을 먼저 확인하세요.
4. 저장소 오른쪽 Releases → Draft a new release에서 태그와 설명을 작성하고 `dist/Spotify-Glass-v0.1.0.zip`을 첨부합니다. 모든 내용과 공개 범위를 확인한 뒤 Publish release를 누릅니다.
5. 지인에게 해당 릴리스 주소를 공유합니다. 오류 제보에는 Spotify/Spicetify 버전과 재현 방법을 적어 달라고 안내하세요. 계정 토큰이나 개인 설정 전체를 요구하지 마세요.

아직 이 패키지는 GitHub에 업로드하거나 공개하지 않았습니다.

공식 안내:
- https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository
