# 비제품 Variant ABI v2 실행 계약 초안

v1과 독립 심사를 보존했다. 현재 상태는 실행 차단이다. 제품·Godot·GUI·Job은 이번 작업에서 실행하지 않았다.

## 비교기와 harness

abi_oracle_v2.py는 실제 bytes를 strict UTF-8로 읽고 고정 engine banner 1개, 선택적 공백 1행, canonical ABI 10행만 받는다. stdout의 SCRIPT ERROR, ERROR, WARNING 및 임의 diagnostic은 위치와 상관없이 거부한다. Exit 0, interruption 없음, stderr 0 bytes, 마지막 줄 종료를 각각 요구한다. abi-oracle-v2-synthetic.py는 정상 1세트, 16개 거부와 공유 스트리밍 cap 경계의 양성을 재현한다. 합성 자료는 engine 출력 증거가 아니다.

abi_bounded_monitor_v2.py는 OS에서 승인된 소유 launcher가 제공할 process stdout/stderr pipe를 두 스레드에서 drain한다. 고정 최대 16KiB 단위 read와 lock으로 양쪽 합쳐 256KiB만 보존하고, 초과가 있으면 Stop/Job drain을 요청한다. 남은 데드라인·오류·exit와 output EOF를 구분하고 sync flush 없는 결과는 실패다. 예외 때에도 owner.drain_and_confirm을 호출하도록 작성했다. 이 모듈 자체는 adapter를 제공하지 않으며 CLI로 실행하면 즉시 차단한다. 실패 journal의 fsync 지연·controller가 붙잡힌 경우의 hard cutoff는 외부 watchdog이 보장해야 한다. 실제 프로세스 및 OS buffer 실측은 미완료다.

## argv와 경계

ABI-DRAFT-MANIFEST-v2.json은 engine/Python/probe 및 comparator imports의 SHA, 정확한 candidate engine/monitor argv, 절대 경로, environment allowlist와 staging roots를 기록한다. Job adapter가 없으므로 monitor argv는 실행 금지 상태를 보고하며 engine을 호출하지 않는다. Engine은 headless 20초에만 승인되고, 5초 이내 owned Job drain·HANDLE signalled를 요구한다. engine fixture v2는 file logging을 껐고 명령에서 log-file을 제거했다. 자동 파일 로그/cache/crash file이 생성되지 않는다는 실제 증거는 아직 없다. launcher가 source/cwd는 read-only, user/cache/temp/output은 별도 scratch로 제한하고 예상 경로 밖 쓰기 또는 제3 출력 채널이 생기면 실패시켜야 한다.

현재 WindowsSandbox 실행 파일의 일반 위치 두 개 및 docker/podman/WindowsSandbox 명령 조회에서 사용할 adapter를 확인하지 못했다. 이는 host capability의 전수 조사가 아니다. 승인된 OS-backed adapter 또는 별도 격리 Windows 환경이 제공되면 같은 frozen inputs/argv와 아래 계약으로 독립 심사한다. Env whitelist나 process Job만으로 파일시스템 read/write 차단을 주장하지 않는다.

- 승인된 read-only engine executable 및 실제 DLL/Windows runtime closure, Python+stdlib+runner closure, 최소 두 source와 scratch root만 노출한다. 기존 제품 프로젝트/사용자 app data를 mount하지 않는다. 경로 정규화·reparse 거부를 stage 전후 확인하고, 실행 중 쓰기/교체는 OS capability로 제한한다. 네트워크·기존 프로세스 활성화 및 취급은 금지한다. 실제 runtime 라이브러리 closure는 이 초안에서 미확정이다.
- 기존 V5 inert broker Job을 쓸 경우 exact broker handle assign/membership 양성을 확인한 뒤 pipe barrier를 해제한다. 실제 engine descendants는 Job membership과 retained HANDLE/creation time/image SHA를 별도 관측한다. OS sandbox adapter가 이 증거를 제공하지 않으면 spawn하지 않는다. 반환의 0 literal만으로 Job active zero를 판단하지 않는다. Engine stdout/stderr cap, outer hard deadline, termination/drain journal을 같은 adapter로 비제품에서 검증한 뒤 사용한다.
- Launcher는 approved manifest SHA 및 reviewed adapter SHA를 후보 밖에서 가져온다. staging 20초 밖의 작업 및 final verification을 포함할 outer global cap과 watcher를 확정한다. Timer는 engine barrier 전부터 재고, output-limiter Stop은 소유 Job만 정리한다. Job membership/engine HANDLE을 관측하지 못한 짧은 실행도 실패다. 현재 실제 adapter, closure, timings는 미제공이므로 승인·실행하지 않는다.

승인된 비제품 ABI run은 제품 최초 import가 아니다. Products/fixtures/cache를 읽는다면 비제품으로 처리하지 않는다. ABI 성공은 실제 C/Q 또는 전체 21행 합격이 아니며 GUI Sky provenance와 W1~W5의 별도 시험을 대신하지 않는다. K6 한 회는 남아 있다.
