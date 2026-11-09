# P03 같은 틱 suffix 독립 5-b — attempt-04/05

2026-11-07. 판정: **제한 fixture 수용**. 심사자는 구현에 참여하지 않았다. 구현 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델명 확인은 아니다.

attempt-04는 실제 3초 timeout probe에서 launcher 실제 exit124, gate 실패, 별도 probe PASS를 기록했다. 전용 Job 총 두 프로세스·active 0, launcher 종료 및 본체 PID 부재를 확인했으며 약 3.19초였다. taskkill 실패 attempt-03은 보존된다. attempt-05 정상 실행은 실제 exit0, 6명명/91 assertions, context 거부 4·구조 거부 2, 오류·경고 0, Job 총 2·active 0이다. 각 실행의 console과 본체를 포함한 입력 51개가 전후 동일하고 현재 SHA의 독립 재계산 차이도 0이다. 전용 job 코드는 suspended launcher를 배정한 뒤 resume하며 다른 프로세스 이름이나 전체 트리를 대상으로 하지 않는다. 이는 해당 Windows 환경의 probe 결과이며 모든 OS 실패 조건에 대한 보증은 아니다.

정상 fixture는 독립 raw twin·수기 값으로 T=2의 Q/Q/S 대기와 I 적용, 같은 T B/R, 실제 두 번 전진 후 같은 handle 복원 및 같은 suffix 재실행의 단계별 상태와 ordered 사건을 비교한다. tick 양방향 절단 및 Q 내용 dedup 반례, malformed issue/queue와 context mismatch의 활성 상태 불변, 후속 정상 진행을 구분한다. exact Variant 타입/값, Dictionary 키 타입·삽입순서, Array 순서·typed metadata, script property/binding을 비교한다. class map 및 실제 runtime script identity guard와 엔진 본체/console 해시가 포함된다.

수용은 제한 POC fixture의 메모리 owner 범위다. 외부 저장 schema, 글로벌 cursor/commit, host/worker 실패 원자성, 외부 사건 exactly-once, 모든 활성 모듈 및 비어 있지 않은 typed class/script 배열을 입증하지 않는다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지. 최종 5162 원분모 보존 및 산출물 manifest/ZIP은 별도 closeout이다.
