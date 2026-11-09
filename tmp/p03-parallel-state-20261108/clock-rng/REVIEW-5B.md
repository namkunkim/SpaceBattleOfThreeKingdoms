# 제한 clock·RNG 조각 5b

판정: **PASS — 명시된 POC 정상 복원 한 사례**. 보존 기록을 검독했으며 독립 재실행은 하지 않았다.

- 본시험 로그는 3개 명명 사례, 57개 확인 및 실패 0을 기록하고 실제 exit는 0이다. 강제 오류는 기대된 실패 marker와 실제 exit 1을 기록한다. 두 stderr는 비었고 Job 기록은 active 0, timeout 및 진단 0이다.
- runner는 생성·1·5·복원 직후·6틱의 시간과 event ID, 미소비 사건 순서, 새 RNG identity, 세 해시 주소와 u32/bp, 복원 전후 및 다음 전진의 exact capture를 확인한다. 비교기는 Variant 타입과 컨테이너 메타데이터를 구분한다. RNG 주소 값은 계획 심사에서 별도 hashlib로 확인했다.
- manifest SHA `3f1d3ea751035daa8761e5a99baf28ab9b7279e401895080367fcd022ee698f3`, 보존 manifest 및 전후 입력 목록이 일치하며 현재 기록된 47개 파일의 SHA 불일치는 0이다. 보존 runner 사본도 동결본과 일치한다. 기록 HEAD는 `fb660cea69207fd332e26128643007694910a253`이다.
- Git 상태 비교는 433행 변화 중 전용 조각 8행 외 P02 candidate-k1 415행, 병렬 cursor 10행을 기록한다. 경로로 구분할 수 있으나 이 심사만으로 외부 변화의 작성 주체나 모든 부수효과를 단정할 수 없다. Git 상태는 기존 dirty 파일 및 무시된 파일의 바이트 불변을 보증하지 않는다.

host TickClock, 다른 hz, terminal 하위 걸음, 외부 cursor, 실제 확률 무기·활성 모듈과 전체 상태 원장은 범위 밖이다. 기존 광역 런타임 반려와 P03 NOT_READY는 유지한다.
