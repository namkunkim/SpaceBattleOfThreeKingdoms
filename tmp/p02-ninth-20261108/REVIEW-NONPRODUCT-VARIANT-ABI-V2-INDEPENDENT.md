# 비제품 Variant ABI v2 독립 심사

판정: **엄격 비교기 및 합성 cap 조각은 한정 수용. 실제 engine 시험은 반려·실행 금지.** `NONPRODUCT-VARIANT-ABI-PLAN-v2.md` SHA `0bd3f293e854cd2da213f2a760bfcd869ddb0c616c3a0f51bf0797fe0c5fd0d0`, manifest `68980995a3a4c1429c5a0693b2e3dd9f02e2753616f4cd6e9d21bd92607bbe81`, monitor `de8431d055f5036a249586ac8cd8fc95aa588829f1448bfcc099c8263ee7cc89`, 합성 로그 `e235455590f1cc9a5fa5f4bfc0b795785e3a517fc30afa6f29bda61367fae784` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

`abi_oracle_v2.verify`는 정확 banner 뒤 공백 최대 1행과 ABI 10행만 허용하고 stderr bytes, 비정상 exit·중단·마지막 개행 누락을 거부한다. v1이 임의 stdout 진단을 무시한 결함은 합성 범위에서 수정됐다. 보존 로그의 정상 1/거부 16 및 공유 cap 경계는 engine 실측이 아니다. 정확 banner·stderr 요구는 실제 환경과 다르면 안전하게 실패할 수 있으며, 실제 엔진 포맷의 성공 보장은 아니다.

monitor는 두 pipe를 공유 잠금 cap으로 제한하고 finally에서 소유 Job drain을 요청하는 초안이다. 실제 owner adapter, engine HANDLE/membership, reader/EOF/timeout 경합 및 durable external watchdog은 미검증이다. `atomic_journal`의 fsync 또는 `drain_and_confirm` 자체가 막힐 경우 이 함수 단독으로 전역 종료를 보장하지 않으므로 별도 supervisor hard deadline·journal 실패·bounded cleanup을 검증해야 한다. 읽기 thread의 예외·cap 초과·비소유 프로세스 생존과 짧은 엔진의 PID/HANDLE 관측 실패 반례는 OS 실행계에서 별도다.

현재 managed workspace 경계나 env whitelist만으로 해당 자식의 제품 read 차단·read-only source·OS 쓰기/네트워크 격리가 증명됐다고 결론낼 수 없다. DLL/Windows runtime·Python stdlib/runner closure와 실제 confinement adapter도 미확정이다. 실현 가능한 다음 단계는 현 환경의 제공된 OS 실행 경계가 자식까지 상속되는지 read-only capability 문서 및 무해한 비제품 probe로 확인하고, 충족 시 최소 두 source·engine/runtime read-only와 전용 scratch만 허용하는 명세와 소유 Job adapter를 독립 심사하는 것이다. 제공 불가하면 별도 격리 Windows 환경에서 같은 고정 입력·증거 계약을 사용하고 현재 시험은 미실행으로 남긴다. OS 보안 설정을 임의 변경하거나 제3자 프로세스를 종료하지 않는다.

제품 코드·fixture·cache를 참조하지 않는 실제 격리 ABI run은 기존 최초 제품 import/검증 spawn의 K6 소진점이 아니며, ABI 통과는 제품·GUI·W1~W5 통과가 아니다. 제품 접근 또는 격리 증명이 불가능하면 비제품 성공으로 분류하지 않는다. 독립 실행 명세·실제 adapter·전체 closure·시간 예산을 수용하기 전 engine을 시작하지 않는다. K1~K5, K6 잔여 1회, P03 및 기존 파일을 보존한다.
