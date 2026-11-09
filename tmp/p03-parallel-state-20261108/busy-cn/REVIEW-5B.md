# 비초기 Cn busy 우선순위 독립 5b

판정: **PASS — 직접 설정한 busy와 단일 비지원 후보**. 보존 runner·기록 검독이며 독립 재실행은 하지 않았다.

- 같은 구조 유효 M의 `reinf_ms` 단일 정수 변이에 대해 busy 상태에서 정확 `busy`, 해제 후 정확 `unsupported_reinforcement`를 확인한다. 두 호출의 기존 sim/state/fleet 및 warm cache identity, 입력·pending·사건 보존과 후속 대조 owner의 전체 capture 일치를 runner에서 확인했다. 정본 조건과 다른 활성 DecisionBoard는 null로 검사한다.
- 본시험 실제 exit 0, 3명명·37확인·실패 0, 타입 강제 실패 exit 1과 의도 marker를 확인했다. 두 stderr는 비고 Job active 0, timeout 및 진단 0이다. 실제 busy 경합은 만들지 않았고 정상 P 양성 restore는 이 조각에서 실행하지 않았다.
- manifest SHA `d4bd7f17e51d10da1187c0cc57657b081e5e0e8d13d559ba98227f52ff5bdc66`, 전후 목록과 현재 47개 SHA가 일치한다. 기록 HEAD는 `0be09755b70378286105972f35ac5b7031715664`, Git 상태 변화 8행은 전용 경로다. 상태 비교는 기존 dirty·무시 파일의 바이트 불변을 증명하지 않는다.

자연 thread/callback 경쟁, 제품 UI와 운영 오류 정책·외부 저장은 범위 밖이다. P03 NOT_READY 등 기존 상태를 유지한다.
