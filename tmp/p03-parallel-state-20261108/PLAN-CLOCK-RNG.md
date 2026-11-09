# P03 제한 논리 시계와 RNG 주소 복원 계획

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. POC 제한 owner의 정상 복원 한 건을 테스트한다. host TickClock, 일반 hz, terminal 하위 걸음, 외부 cursor, 실제 확률 무기 결과와 활성 모듈은 별도 범위다. 사전 독립 수용까지 runner/실행은 보류한다.

## 입력과 수기 oracle

승인된 reinf-ms fixture의 두 전대, 좌표·seed 41·hz 10·controls [] 및 rules를 그대로 쓴다. profile_id만 `p03-clock-rng`로 변경한다. queue는 비어 있으며 명령 발행과 사건 drain을 하지 않는다. 두 기함의 거리는 750과 일반 사격 범위를 넘는다. POC AI는 평가마다 살아 있는 적측 기함 하나에 새 event ID를 배정하지만 `ai_target -1`만 적용하고 사건을 내지 않는다.

| 관측 | tick | clock_ms | sub_ms | ai_timer | next_event_id | 미소비 사건 |
|---|---:|---:|---:|---:|---:|---|
| 생성 | 0 | 0 | 0 | 0 | 1 | spawn(1), spawn(2), 둘 다 tick 0 |
| 원본 첫 advance | 1 | 100 | 50 | 450 | 2 | 동일 |
| 원본 5회 advance 후 P | 5 | 500 | 50 | 50 | 2 | 동일 |
| 동일 context 새 owner에 P를 복원한 직후 | 5 | 500 | 50 | 50 | 2 | 동일 |
| 원본·복원 owner 각 1회 advance | 6 | 600 | 50 | 500 | 3 | 동일 |

근거는 dt 1/10을 50ms 하위 걸음 두 개로 분할하고 매 걸음 ai_timer를 50만큼 줄이는 것이다. 첫 50ms에 0→-50→500, 550ms에 50→0→550이 된다. 각 AI 평가가 카운터를 하나 늘린다. 이 표의 수치·사건은 실행 결과에서 생성하지 않는다. `battle_sim.gd:923–989`, `ai/poc_enemy_ai.gd:25–46`, `poc_corridor.json`의 550ms 설정에 근거한다.

RNG의 profile_id는 `p03-clock-rng|41`. 아래 기대값은 외부 Python hashlib로 입력의 UTF-8 SHA256 앞 8자리의 정수와 mod 10000을 계산한 값이다. P와 다음 틱에서 owner의 실제 `st.tick,st.next_event_id`를 읽어 `u32,bp`에 전달하고 이벤트 ID는 소비하지 않는다. 복원 직후 RNG 객체 identity가 새 후보의 객체인지 확인한다. 표는 순수 난수 주소 비교이며 POC AI의 실제 확률 분기 도달로 집계하지 않는다.

| 입력 | u32 | bp |
|---|---:|---:|
| p03-clock-rng\|41\|5\|2 | 3600336925 | 6925 |
| p03-clock-rng\|41\|5\|2:1 | 2671758521 | 8521 |
| p03-clock-rng\|41\|6\|3 | 3339876617 | 6617 |

분모는 정상 restore 1회, 수기 시간 표 5행(마지막 행은 두 owner 각 1회 대조), RNG 주소 3개(앞 2개는 원본/복원 직후, 마지막은 두 owner의 다음 tick), 미소비 ordered 사건 2개다. 복원 직후 P 전체와 다음 틱의 원본/복원 capture를 독립 exact comparator로 비교한다. Variant 타입, typed 컨테이너 메타데이터, 키와 배열 순서를 확인한다. 정수와 float는 동일 값으로 비교한다. 이 fixture의 정수 좌표와 dt는 허용오차를 추가하지 않는다.

## 5a와 5b

전용 `clock-rng/`에만 쓴다. 승인 후 기존 reinf-ms의 비교·launcher Job·manifest 방식에서 필요한 부분만 재사용한다. 본시험 `clock_boundary`, `restored_rng_address`, `next_ai_evaluation` 3개와 독립 강제 오류 프로세스 1개. 정상/강제 오류 실제 exit 0/1 및 각각 성공/실패 marker 정확 1개를 요구한다. parser 오류는 실패 대조 통과로 세지 않는다. 실제 engine PID와 본체 경로, canonical 클래스 경로, 60초 timeout과 해당 Job active=0, SCRIPT ERROR/ERROR/WARNING/누수를 따로 확인한다.

수용 후 runner와 호출기 작성, 최초 실행 직전 repo/HEAD/status, 실제 console/본체·Python/PowerShell·class map·project·전체 core/battle GDScript·POC/bundle JSON·승인 계획과 리뷰·실제 입력 및 실행 파일 SHA를 동결한다. manifest 경로 정규화 및 중복/누락 거부, 별도 manifest SHA, 실행 전후 입력/HEAD/status 대조를 요구한다. 프로젝트 import/cache 쓰기 없이 headless 단독 실행하고 동결 입력 변경 시 결과를 무효화한다. 승인 이후 명령은 `python clock-rng/run_gate.py --manifest-sha256 <sha> --attempt 1`이며 저장소 루트에서 실제 경로를 지정한다. PowerShell ErrorActionPreference Stop과 LASTEXITCODE 전달을 사용한다. 재시도 K=3, 이전 증거 유지. 사용량 제한이면 즉시 보고하고 반복을 중단한다. 사후 5b는 구현과 독립된 비-Astra 모델이 수기값과 실제 결과를 대조한다.
