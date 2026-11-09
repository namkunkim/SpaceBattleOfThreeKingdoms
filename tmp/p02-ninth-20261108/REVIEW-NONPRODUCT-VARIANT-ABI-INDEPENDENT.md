# 비제품 Variant ABI 계획 독립 심사

판정: **비제품 시험 목적과 제한적 분모는 수용, 현재 실행 명세는 반려. 실행 금지.** `NONPRODUCT-VARIANT-ABI-PLAN.md` SHA `6fc12dabc9d3165295745a9f387e0d90d151476d5fe501ea95a35541f2fb4662`, `ABI-DRAFT-MANIFEST.json` `7c0cdbec725a06d293bc454f637a537893e7b711d83312bda8236fb54dc54dc2` 확인. engine console 및 Python 실제 파일 SHA도 제시값과 일치했다. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job을 실행하지 않았다.

최소 project.godot/probe.gd는 정적 코드상 제품 project·fixture·cache를 참조하지 않고 10가지 작은 Variant를 직접 만든다. 이 독립 엔진 ABI 시험이 실제로 승인된 격리 경계에서 해당 두 파일만 사용하면 최초 **제품** import/검증 spawn으로 정의된 K6 소진에 해당하지 않으며 제품 통과 분모에도 포함하지 않는다. 실제 실행 중 제품 경로·fixture·cache 접근이 발생하거나 이를 배제할 수 없으면 결과를 비제품으로 단정하지 않고 중단·재심한다. engine의 내장 resource와 OS 라이브러리 읽기는 별도 dependency로 명시해야 한다.

Probe의 literal과 Python 기대값은 별도로 작성됐고 기존 v8 decoder를 실제 engine 출력과 대조하는 구조다. 10행·int/float width·typed array/dictionary 및 ordered contact, 거리 동률 비교는 한정된 ABI 적합성에 유용하다. 다만 동일 source로 만든 synthetic 직렬화가 기대를 자기 검증하는 것을 방지하고, engine 출력의 raw bytes·banner/version·SHA와 Python comparator/decoder 전체 closure를 별도로 동결해야 한다. 실제 engine float precision 및 Godot typed container ABI가 다르면 실패다. 이 결과는 전체 서비스 packet이나 제품 정책의 올바름을 증명하지 않는다.

실행 전 필수 보완:

1. 환경 whitelist, Windows system/DLL 및 Python dependency closure, project copy·user://·cache/log/TEMP의 실제 resolved path와 예외 처리를 고정한다. 환경 변수와 경로 점검만으로 OS-backed filesystem read/write confinement를 입증하지 못한다. 승인된 격리 수단의 허용 읽기·쓰기·reparse/TOCTOU 및 네트워크 경계를 확인하고 기존 사용자 데이터와 다른 프로세스에 쓰거나 활성화하지 않아야 한다. headless `--script`라도 실제 자동 생성 cache/log 위치를 사전 차단 또는 격리하고 사후 관측한다.
2. Job runner와 정확한 launcher/comparator argv, owned HANDLE·creation time·engine tree·exit/drain, output 256KiB를 스트리밍 중 강제하는 방법, 20초의 시작·종료 및 5초 cleanup·별도 failure journal을 고정한다. 무한 출력으로 pipe가 막히거나 timeout 중 기록이 소실되면 실패다. 기존 Godot은 종료 대상에서 제외한다. 해당 runner 및 containment의 비제품 사전 검증은 미완성이다.
3. 현재 `abi_oracle.check`는 `P02_ABI ` 이외 stdout 줄을 모두 무시한다. exit 0/stderr 빈 상태에서도 stdout의 SCRIPT ERROR·ERROR 또는 기타 진단을 허용할 수 있으므로 명시된 정상 banner 외의 예상치 못한 진단을 실패시키고 반례를 둔다. 10행의 duplicate·순서·누락, malformed hex, wrong header/type, 과다 출력 및 timeout을 거부하는 독립 합성 검사를 보존한다. 로그 파일 및 stdout/stderr flush/hash와 누락 시 실패를 명시한다.

승인된 독립 실행 명세와 실제 OS 격리·소유 runner가 준비되기 전에는 이 시험도 시작하지 않는다. GUI Sky provenance·watchdog·최종 21행은 별개이며 K1~K5와 마지막 K6 한 회, P03 현재 변경과 원본을 보호한다.
