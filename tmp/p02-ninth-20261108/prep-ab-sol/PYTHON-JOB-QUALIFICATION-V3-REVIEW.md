# 비제품 Python Job qualification v3 독립 실행 계약

이전 manifest와 심사를 보존했다. v3는 독립 심사 전 review-only다. 실제 Windows Job, Python 자손, Godot, 제품·GUI는 시작하지 않았다.

## 정확 입력 및 승인

variant-abi-review/PYTHON-JOB-QUALIFICATION-MANIFEST-v3.json은 watchdog/supervisor/controller/payload, V5 broker/Owner, Python 및 의존 코드 SHA, absolute argv templates와 exact env, scratch·output paths, 시간과 byte cap, 기존 raw .git/HEAD/현재 resolved ref/index/P03/worker/project hashes를 고정한다. 승인 기록에서 직접 가져온 exact manifest SHA로만 진입한다. 실행 status 변경은 승인 후보 bytes를 새로 동결하고 별도 심사해야 한다. 이 review-only 파일을 받은 CLI는 실제 Popen/Job/scratch 전에 거부함을 확인했다. Default managed sandbox에서만 실행하며 권한 상승·저장 설정 변경을 하지 않는다.

## 외부 watchdog 및 최상위 경계

python_job_external_watchdog_v3.py는 case supervisor 밖에서 그 전체 소유 트리를 global private Job에 넣는다. Boot worker가 3초 안에 inert broker의 Popen·정확 HANDLE attach·membership을 확보해야 하며, 그 전에는 payload barrier를 해제하지 않는다. Bootstrap timeout은 stdin EOF로 닫을 대기 broker만 있을 수 있다. Broker가 시작되지 않았거나 HANDLE 관측이 끝나지 않은 경우 성공을 주장하지 않고 외부 receipt에 barrier_released=false를 기록한다.

Barrier write도 별도 3초 worker이며, 완성된 payload가 전달되더라도 이미 global Job에 소유된다. Global 90초는 bootstrap 전 monotonic부터 계산한다. Controller startup, case-level barrier, pipe, fsync stall이 상한을 넘으면 global Job만 종료한다. Global owned drain은 별도 2초 대기와 active 0 / retained signalled를 요구한다. Drain worker가 붙잡히면 소유 Job을 해제했다고 기록하지 않는다. Python process 종료에서 비상으로 비상속 Job handle을 닫는 kill-on-close 경계가 적용되지만 실제 잔존 확인이 없으면 시험 실패다. 마지막 외부 journal은 소유 정리 뒤 별도 2초 worker로 기록한다. Flush가 막히면 무한 대기 대신 실패한다. 실제 Windows API 또는 호스트 스케줄러 전체가 붙잡힌 상황의 절대 종료 보장은 아직 관측되지 않았다.

이 v3는 기존 90초 guard를 바깥 watchdog으로 대체한다. 중첩 깊이를 추가하지 않고 같은 V5 broker로 supervisor/inner controller/payload의 private Job을 사용한다. Outer-stall은 의도적으로 기다리는 controller를 검증하며 Windows fsync hang이 실제 발생했다고 분류하지 않는다. 별도 소유 sentinel은 각 case Job 밖에서 정상 생존 후 종료를 요구한다. 다른 프로세스의 PID를 찾아 종료하지 않는다.

## stderr 및 외부 실패 근거

Case supervisor는 controller stdout/stderr를 별도 bounded memory stream으로 수집한다. 두 stream의 합계 cap은 16KiB이며 engine payload cap 256KiB와 구분한다. 밖의 case journal에는 시작 stage, owned drain outcome, missing inner receipt, payload PID/retained membership, diagnostics EOF와 파일 SHA를 각각 기록한다. Missing inner receipt를 성공으로 바꾸지 않는다. Controlled journal-negative는 의도한 쓰기 실패와 expected exit 1을 요구하고, outer-stall은 실제로 stall-start marker에 도달했는지 별도 확인한다. 가드의 supervisor diagnostics도 별도 16KiB로 제한한다. 합성에서 bounded stage의 4 timeout, controller stderr 보존 및 combined overflow를 검증했다. 실제 Windows pipe/EOF 및 hard cleanup은 미측정이다.

Scratch 목록과 보호 파일 전후 해시의 관측 범위는 v2와 같다. 전용 OS read-deny를 추가 보편 조건으로 요구하지 않는다. 이 Python 시험의 성공은 Godot의 child tree나 ABI, 제품 경계, GUI 또는 21행의 증거가 아니다. 최초 제품 import/fixture 실행 전에는 K6 한 회가 남는다.
