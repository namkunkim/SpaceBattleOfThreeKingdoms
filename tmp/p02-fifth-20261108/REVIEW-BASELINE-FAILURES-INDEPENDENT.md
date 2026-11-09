# P02 실행 전 실패와 검사 개정 독립 판정

2026-11-08. 판정: **계획 개정 필요; 제안된 수정은 아래 조건에서 타당**. 독립 심사 세션 `/root/p02_fifth_review`; 실제 모델은 세션에서 독립 확인 불가. 구현이나 테스트를 실행하지 않았다.

`before-attempt-01` 원본 로그에서 common은 99단언 중 2실패(exit 1): A03 `native briefing`, A06 실제 `{ok:false,error:unsupported_scenario,path:profile}`이다. `world_link`는 exit 1, `WORLD_LINK_FAIL 1`, stderr의 실패는 `천하에서 오면 브리핑부터 (prologue)`다. 두 adapter 검사는 exit 0이다. 이 기록은 실패로 보존하며 소급 성공 처리하지 않는다. A03은 실패 후 직접 `begin_battle`을 호출했으므로 이 실행의 후속 결과를 정상 서막 UI를 통한 직접 경로의 기준 결과로 삼을 수 없다.

`command_deck.gd`는 `prologue_seen`이 거짓이면 prologue를 열고, `deck_screens.gd`의 실제 서막 건너뛰기 버튼은 `finish`를 거쳐 설정을 기록하고 brief로 간다. 깨끗한 별도 user 디렉터리에서 A03이 prologue 및 실제 버튼→brief→시작→결과까지 확인하도록 common probe를 고치는 것은 타당하다. 기대 결과를 새 코드가 없는 원본으로 다시 생성·고정하고, 입력·runner SHA와 새 사전 시도의 분모·실패를 별도로 기록한 다음 사후에 동일 입력과 비교해야 한다. 설정 저장 등 user:// 부작용은 격리하고 사전·사후 초기 상태를 동일하게 해야 한다.

owner의 `_profile_error`는 reinforcement를 scenario보다 먼저 검사한다. 이번 실제 제품 입력의 관측은 `unsupported_scenario/profile`이므로 A06의 구체 기대를 해당 값으로 정정하는 것이 타당하다. 이는 모든 지원 밖 항목을 각각 검사했다는 뜻이 아니며, 같은 원본 프로필과 SHA를 새 사전 기준에서 고정해야 한다.

변경 금지인 `tests/world_link.gd`는 깨끗한 user://에서의 기존 실패를 계속 공개해야 한다. `GameSettings.load_cfg`는 `user://settings.cfg`의 `[progress] prologue_seen`을 읽으므로 별도 returning-player 환경에 최소 설정을 미리 제공하여 같은 테스트를 **추가** 실행하는 것은 유효하다. 설정 파일의 실제 바이트/SHA와 사용자 경로를 고정하고 사전·사후 동일한 초기 복사본으로 독립 실행하며, 사전 실패 환경과 분리 보고하라. 그 결과가 성공해도 깨끗한 환경의 기존 실패를 통과로 바꾸거나 전체 테스트 무조건 통과라고 주장해서는 안 된다. 이전 WORLD_LINK_PASS의 사용자 설정은 확인되지 않았으므로 원인을 추정으로만 남긴다.

수정된 runner·fixture·프로세스 분모 및 사전 고정 oracle은 계획 v2 대비 변경이므로 개정 계획과 재심을 거친 뒤 적용한다. 기존 실패 로그, 원본 제품·테스트 및 P03을 보존하고 기존 이탈/리소스 종료 진단도 보고한다. 이 판정은 제품 변경·사후 실행의 수용이 아니다.
