# raw 시각 증원 조각 5b

판정: **PASS — raw BattleSim의 단일 시각 증원 경계**. 보존 기록과 runner를 검독했으며 독립 재실행은 하지 않았다.

- 본시험 실제 exit 0, 세 명명 사례·31개 확인과 실패 0, 강제 타입 실패 실제 exit 1 및 의도된 marker를 확인했다. stderr는 각각 비고 두 Job은 active 0, timeout·진단 0으로 기록됐다.
- runner는 100ms에서 증원 부재, 두 번째 step 종료 시 시각 200ms와 기록된 발생 시각 150ms, roster·ID·속성·사건 순서, warm by_id 재연결 및 300ms 재발동 부재를 확인한다. 적 기함 생존을 각 경계에서 검사해 전멸 분기와 구분한다.
- manifest SHA `dfb23ec66dadea147a6a72275677268073620a5259e157ea509dbaa219471b88`, 전후 목록 및 47개 현재 입력 SHA가 일치하고 runner 사본도 일치한다. 기록 HEAD는 `fb660cea69207fd332e26128643007694910a253`이다.
- Git 상태 차이 87행 중 전용 경로 8행과 cursor 임시 경로 79행이 기록됐다. 외부 변화의 작성 주체는 이 심사만으로 입증하지 않았으며 Git 상태는 전체 dirty/무시 파일의 바이트 불변을 보증하지 않는다.

제한 owner, C0/Cn 복원, 전멸 증원 및 운영 host는 범위 밖이다. P03 NOT_READY 등 기존 상태를 유지한다.
