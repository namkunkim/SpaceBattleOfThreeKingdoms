# Q/C/B 및 watchdog 부분 보완 독립 심사

판정: **검토용 정적 보완으로 수용; 실행 및 oracle 완성은 반려.** `CAPTURE-AND-WATCHDOG-PREP.md` SHA `adde051ae7a58155c82daa6b7be95a362058f6c6e8573d9aa6e06dc050f965b0`, Q/C SHA 문서 `1b8dd0802741d1e05f11fac2feabb89a8f689b0c5bc6a2aad44f28d9ef984294`, B SHA 문서 `a035e50dbea9d822dcea3d92015641ec4bb0c61c1a57706a14e0921b20c9f39d`, watchdog 입력 `2aa1bd9100ce2ef049f7d26086bab2351e1fa3cdec53f4b37236f6e53ca11949` 직접 확인. 이 심사에서 제품·Godot·GUI·Job을 실행하지 않았다. 심사 모델 gpt-6.1-terra.

Q diff는 기존 product policy와 reference_commands 호출을 한 번씩 변수에 담아 각 queue 전에 캡처한다. 두 함수는 별개지만 같은 BattleSim 규칙과 해당 tick의 원문 test fixture에 의존하므로 독립성은 그 경계 안에만 있다. 2,164 키는 지정된 과거 terminal tick vector와 fixture 일치가 전제다. 동일 누락을 거부하는 합성 사례는 유용하나 tick vector 자체 및 reference source/기대 command의 오류를 증명하지 못한다. typed hex 문자열 유효성은 Godot Variant 역직렬화·원래 타입 의미 보증이 아니다.

C diff는 source를 restore 전에, target을 restore 직후 캡처하며 원래 detach 검사는 남긴다. 80 키는 10×2×2×2의 정상 분기 전제이며 actual source IDs/records를 현재 확정하지 않는다. 두 관측의 공통 encoder와 동일 fixture의 한계, 양쪽 side 및 record ID 순서·값의 외부 기준을 보존해야 한다. restore 실패 후에도 capture를 시도하므로 null/예외·누락이 무조건 실패인지 판정기에 연결해야 한다. Q/C의 GDScript parse, side effect·동기화, 전체 suite ordinal과 최종 oracle 재검토는 미완료다.

B의 constructor 직접 참조와 실제 재귀 탐색은 서로 다른 열거 방식이어서 비교 가치는 있다. 하지만 기대 목록도 같은 런타임 객체의 필드·child index를 사용하며 가시성 검사도 동일 객체에서 이루어진다. 따라서 동시 누락이나 잘못된 constructor 구조를 항상 검출하는 사전 고정 NodePath oracle은 아니다. 4/10/2/6과 109는 정적 가정이다. source constructor/scene·visibility·child 순서 및 예상 stable path를 별도로 근거화하고 null/인덱스·visibility·동시 누락 반례를 검증해야 한다. WorldLink actual parsing/버튼과 109는 미측정이다.

watchdog JSON은 엔진 argv, 해시, 격리 환경 변수와 각 timer를 구체화한 review-only 입력으로 진전이다. controller/supervisor argv 및 실제 outer/inner HANDLE·membership·cleanup·filesystem confinement가 없으므로 실행 가능 계획이 아니다. W4의 8초 전역/6초 엔진 제한과 5초 cleanup은 staging 및 정상 종료 변동에 취약할 수 있어 timeout 분류와 outside journal 기록을 구현·비제품 실측해야 한다. 예상 user data 경로와 환경 변수만으로 OS 전역 쓰기 차단을 증명할 수 없다. W5는 실제 거부가 없으면 미검증이다.

Sky per-request provenance는 여전히 증명되지 않았으며 문서에 receipt가 없다는 관찰은 현재 확인 범위에 한정한다. GUI 15/16과 전체 K6은 차단이다. HEAD 기반 lane은 활성 P03 결합 미검증이며 P03 +9/worker +2 및 원본·index 보호를 유지한다. K1~K5와 마지막 K6 한 회 및 제품 import 시 소진 정의를 보존한다. 다음 작업은 oracle 독립 근거와 계측/판정기 반례를 완성하고, 제품 없는 supervisor 및 파일시스템 격리 명세를 구현해 독립 재심하는 것이다. 이 심사는 어떤 실행도 승인하지 않는다.
