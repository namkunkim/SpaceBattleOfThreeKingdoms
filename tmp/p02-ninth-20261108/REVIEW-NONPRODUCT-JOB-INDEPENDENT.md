# 비제품 Job watchdog 계획 독립 심사

판정: **시험 구조는 조건부 수용하나 실행 명세로는 반려한다. 재심 전 실행 금지.** `NONPRODUCT-JOB-WATCHDOG-PLAN.md` SHA-256 `d331016794e5e1aefaf147d3c155840671dca799bea822a9efb43f7017c959c7` 확인. 심사 모델은 앞선 turn metadata에서 확인한 gpt-6.1-terra다. 제품·Godot·Job·GUI를 실행하지 않았다.

W1 정상, W2 inner timeout, W3/W4 blocking stage, W5 실제 nested assign 거부 또는 미검증이라는 분리는 유용하다. V5 inert broker/barrier와 같은 계층으로 실제 engine tree를 관측하고, synthetic 자손과 실제 wrapper 결과를 구별하며, 별도 sentinel을 보유 HANDLE로 확인하는 방향은 타당하다. 제품 code·fixture를 전혀 사용하지 않는 독립 최소 프로젝트의 시험은 제품 검증 결과가 아니며 제안된 K6 최초 제품 import/검증 소진점에도 해당하지 않는다. 실제 시험 중 제품 파일을 import하거나 제품 fixture를 사용하면 이 분류를 재평가하고 시작하지 않아야 한다.

실행 전 다음을 구체화해 재심해야 한다.

1. 현재는 정확 argv·cwd·environment·각 W별 고유 경로, engine/Python/runner 실제 SHA, 최소 프로젝트 파일 내용과 SHA, controller/supervisor 소스·버전이 없다. 제안된 30/15/40/8초가 시작 시각·stage·cleanup·외부 journal에 어떻게 적용되는지도 명령과 타임라인으로 명시한다. 정상 30초와 hard cap 40초, W2 내부 15초+cleanup 5초, W3/W4 8초를 별도 케이스로 확인하고 timeout·관측 누락은 모두 실패다. stage 기록을 동기 flush하고 crash·write 실패도 실패로 남긴다.
2. Outer supervisor가 outer Job 밖에 남아 기록하되 controller 및 inner broker가 barrier 전 정확한 HANDLE로 소유되고, 각 실제 engine/child의 creation time·image SHA·양 Job membership·종료 후 signalled 및 두 Job active 0을 확인하는 구현이 필요하다. V5의 `active_at_join: 0` 리터럴은 증거가 아니다. nested assign 실패 또는 supervisor 예외에서 barrier release 0, broker EOF, 자기 소유 handle만의 cleanup을 증명한다. W5 실제 거부가 재현 불가능하면 미검증으로 보존한다.
3. Sentinel은 사용자 프로세스가 아닌 이 시험 전용 프로세스로 outer/inner Job 밖에 생성해 시작 시 membership과 동일 handle 생존을 확인하고 정상 종료한다. 기존 사용자 프로세스에 열거 기반 종료·활성화·입력을 하지 않는다. PID만으로 cleanup하지 않고 소유 handle/Job만 종료한다. 이미 존재하는 Godot과 구별할 증거와 외부 프로세스 비침범 판정 범위를 명시한다.
4. 새로운 전용 경로의 canonical 절대경로와 reparse 검증 시점, user://·APPDATA·LOCALAPPDATA·XDG·TEMP·cwd·logs 및 engine 자동 import/cache 위치를 확정한다. 경로 검사만으로 임의 외부 쓰기 차단을 입증하지 못하므로 filesystem 격리 수단과 실패 시 fail-closed를 별도로 명세한다. P03 및 원본 watched bytes와 HEAD/index 전후 결과를 기록하되 샘플 사이 불변은 주장하지 않는다. 별도 desktop 부재 시 GUI는 시험하지 않는다.

실제 engine SHA 확인과 harness·명령·source/output closure, 외부 Job의 접근 가능성 및 운영 환경에 맞는 권한을 고정한 후 독립 재심을 받는다. 이 시험의 성공은 K6 시간 예측이나 GUI 귀속·제품 PASS가 아니다. 마지막 K6 한 회 및 K1~K5 이력은 보존한다.
