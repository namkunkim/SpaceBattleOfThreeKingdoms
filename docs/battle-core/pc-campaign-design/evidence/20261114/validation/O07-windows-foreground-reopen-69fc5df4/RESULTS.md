# O07 Windows 릴리스 단일 PC 전경 슬롯 재개

Windows 릴리스 소스는 `69fc5df4bcc434ba0c6b3e661fd0c96cc7128ad7`이다. 독립 검토에서 릴리스 파일 5종의 SHA-256과 소스 지문 18/18·40/40을 확인했다.

- EXE SHA-256 `e555be3f85d44c337c6b5070d30e9623b0292cc293cff909dd9442379ad116a4`
- DLL SHA-256 `3866b1c2120b2501afcef6ca613aa527b06640e46e4530f9b43c5fbb939edd4d`

격리한 APPDATA·LOCALAPPDATA에 첫 프로세스 PID 30728로 슬롯을 만들고 2틱·150ms에서 결산했다. 새 PID 4500은 시험 입력 없이 같은 슬롯을 열었다. 두 프로세스 모두 종료 코드 0이었고, 엔진 로그에는 시작 정보만 남았다. 슬롯은 generation 2와 같은 결산 영수증 및 SHA-256을 유지했다. [초기 기동](launch.json) · [첫 종료](exit.json) · [재개 기동](reopen-launch.json) · [두 번째 종료](reopen-exit.json) · [결과](foreground-result.json)

실행 담당자는 재개 화면에서 원래 결산 키와 2틱을, 지도 복귀 화면에서 ‘연합 승리’와 `annihilation`을 직접 확인했다. 보존한 화면 이미지가 없어 독립 검토는 실행 담당자 관찰, 기동·종료 기록과 슬롯을 대조했다. 기동 기록에는 실행 파일의 절대 경로가 빠져 있어 파일 선택은 실행 담당자의 도구 기록을 근거로 했다. 이번 검증은 격리 슬롯의 단일 PC 전경 재개에 한정한다.
