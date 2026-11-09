# 비제품 Python 소유 Job 시험과 C raw v2 보강

이 자료는 실행 전 독립 심사용이다. Python 코드의 compile과 review-only guard, C 오프라인 합성만 확인했다. 실제 child, Windows Job, Godot, 제품 및 GUI는 시작하지 않았다.

## 무해한 Job 자손 시험

variant-abi-review/PYTHON-JOB-QUALIFICATION-MANIFEST.json은 현재 Python과 ABI v3 Owner/release, 기존 V5 inert broker, 새 controller/payload, exact argv templates와 env, sandbox scratch, 보호 SHA를 고정했다. Resolved HEAD와 symbolic ref 및 raw index/P03/worker를 기록했다. Manifest status가 review-only이므로 Python guard 호출은 scratch 생성 전에 거부한다. 별도 독립 수용 전 status를 바꾸거나 실제 Job을 생성하지 않는다.

Guard는 default managed exec_command 안에서만 실행한다. 90초 watchdog private Job은 supervisor 및 아래 test Job을 소유한다. Supervisor는 normal/timeout/output-cap/outer-stall/observation-negative/journal-negative 각각의 private Job 밖에서 감시하고 controller는 기존 V5 inert broker로 실제 Python payload를 inner Job에 놓는다. Guard 추가 계층은 supervisor의 blocking 실패를 정리하는 자손이며 ABI v3의 2개 안쪽 계층과 코드를 공유한다. 추가 계층 자체의 nested 환경 적합성은 미검증이다. Top-level guard 초기 local setup/첫 process creation 및 최종 journal fsync는 바깥 runtime에서 직접 중단할 수 있는 별도 경계가 확인돼야 한다. Gate 미충족 시 실행하지 않는다. 이미 생성한 소유 Job은 kill-on-close를 유지하고, 최종 journal 누락은 결과 실패다.

- **normal**은 exact payload PID marker와 별도 broker PID, inner/outer 실제 HANDLE, creation time, membership, 정상 exit, EOF/hash, active 0 및 HANDLE signalled를 요구한다.
- **timeout**은 marker를 먼저 출력한 뒤 기다리는 child가 inner 3초에서 잘리고 2초 cleanup, outer 정상 판단 및 원문 결과가 남아야 한다.
- **output-cap**은 marker 후 300,000개 payload byte를 출력한다. 총 256KiB retained, owned stop, 두 관측층에서 payload HANDLE 확인과 cleanup을 요구한다.
- **outer-stall**은 nested child가 살아 있는 중 controller가 durable stall-start receipt 이후 기다린다. Outer 4초에서 125 종료 및 실제 child HANDLE drain을 요구한다. API의 실제 fsync가 멈췄다고 분류하지 않는다.
- **observation-negative**는 실제 짧은 child를 실행한 뒤 관측 실패 경로를 명시적으로 주입한다. 정상 통과 대신 exit 1과 failure receipt를 요구한다. 진짜 Windows API 관측 실패나 nested assign 거부를 증명하지 않는다.
- **journal-negative**는 소유 scratch의 inner journal 경로를 사전에 directory로 만들어 쓰기 실패를 유도한다. 소유 child가 drain된 뒤 exit 1과 outer evidence를 요구한다. 정상 durable journal이 생겼다고 집계하지 않는다. 실제 nested assign 거부는 환경에서 자연 발생한 API 오류에 한해 별도로 기록하고, 재현하지 못하면 미검증이다.

별도 Python sentinel은 각 case의 test Job과 그 inner Job 밖에 있다. Supervisor의 동일 Popen HANDLE이 시작·종료 전후 해당 case Job의 비구성원이며 살아 있음을 확인하고, 전체 실행이 끝난 뒤 단일 stdin marker로 정상 종료한다. Sentinel은 자신도 이 시험이 시작한 소유 프로세스다. 다른 사용자 프로세스는 사용하지 않는다. 외부 global cutoff는 같은 시험의 sentinel까지 포함해 guard 소유 Job만 정리한다. Scratch whitelist 및 보호 파일 전후 SHA는 관측 범위 안의 검증이며 모든 host writes/reads 또는 중간 변경 부재를 증명하지 않는다.

## C raw 판정 v2

c_raw_overlay_mapping_v2.py는 20 segments의 initial/앞뒤 eval/relocation/alias, 복원 다섯 번과 scope end를 원문 순서대로 5,080 rows per lane에서 대조한다. Seed/tick/sim ID exact int와 actor/lane/case/phase/type, unique instance IDs, raw stream ordinal, clock의 nondecreasing 마이크로초와 ns 변환을 확인한다. Restore pairs만 호출해도 bool/float seed나 tick/ID 위장을 필터링 전에 거부한다. 합성 정상 1세트와 반례 15건을 검증했다. 원본 v1 매핑과 오버레이는 보존했다.

실제 producer의 raw packet bytes sub-slice, v4 geometry와 v7 process/request causality, v9 pre/post와 독립 fixture closure, detach/alias/suffix 전체 원문이 같은 run에 연결된 것은 아니다. Godot parser 및 실제 evidence size/time은 미확정이다. 최초 제품 fixture 또는 import를 실행할 때 마지막 K6이 소진된다. 이 Python 시험과 별도 ABI는 제품 코드·fixture·cache를 읽지 않는 범위에서만 비제품이다. K1~K5 및 P03 현재 변경을 보존한다.
