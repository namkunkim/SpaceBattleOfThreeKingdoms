# attempt-03 독립 보존 감사 및 인계

판정: 관측 보존, 5-a 미통과. 별도 세션과 실행 창을 명시적으로 조율하기 전 반복 금지. 이 감사에서 엔진을 실행하지 않았다.

attempt-03의 stdout은 등록된 순서의 32 PASS, 결과 ok=true이고 실제 exit 0, timeout 없음, Job active 0, 진단 오류·경고·누수 0, 엔진 본체 경로 일치다. 그러나 `run.json`은 외부 status delta 3건으로 `hard_stop=true`, `gate_passed=false`다. 세 경로는 별도 `tmp/p03-parallel-state-20261108/clock-rng/`의 attempt-01.exit, git-after.z, suite.json이다. 이들을 보존하며 이 시도를 5-a PASS 또는 독립 5-b 수용으로 재분류하지 않는다.

135개 입력의 시작/종료 목록·SHA·크기가 동일했고 두 HEAD는 fb660cea69207fd332e26128643007694910a253이다. 그 사실은 status 감시가 잡은 별도 파일 생성이나 일시적 변경을 부정하지 않고 전체 트리 불변을 증명하지 않는다. 긴 경로 status 경고 및 기존 dirty 파일의 내용 미감시 제한도 남는다. attempt-01/02/03의 원문, runner, 계획 및 외부 작업 산출물은 삭제·덮어쓰지 않는다.

다음 독립 작업은 별도 세션과 공유 저장소의 쓰기·실행 창을 조율하고, 각 참여자가 해당 창 동안 상태 변경을 중지한다는 확인을 확보하는 것이다. 프로세스가 현재 보이지 않는다는 일회성 확인만으로 조율을 대신하지 않는다. 그 후에만 새 preflight에서 승인 계획과 runner, 전체 입력 집합, 실제 실행 파일·canonical class mapping과 SHA/크기, 시작 HEAD/status/경고를 다시 기록하고 새 시도로 실행한다. 종료 후 입력·범위·원문·실제 종료 및 Job을 비교하고, 이상이 있으면 즉시 중단·보고하고 재심사한다. 정식 5-a 통과 후 별도 5-b에서 oracle·fixture·분모·로그·동결 및 범위를 독립 심사한다. 조율이 이뤄지지 않으면 실행 없이 인계한다.

이 기록은 제품의 외부 저장·ack·idempotency를 입증하지 않는다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED 유지.
