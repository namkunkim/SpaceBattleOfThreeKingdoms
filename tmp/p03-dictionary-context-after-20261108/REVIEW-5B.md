# P03 Dictionary context 수정 독립 5-b

2026-11-08. **승인된 hunk 및 제한 회귀 수용**. 사용자가 해당 수정·검증을 명시 승인했다. 구현 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인이 아니다. 심사자는 구현에 참여하지 않았다.

untracked owner의 before `c5550999…9a6e`와 after `ac59a754…8c1c6` 및 현재 바이트를 독립 대조했다. 차이는 Dictionary 분기의 426-byte 삽입 하나로 key/value 각각 builtin·class 비교와 script identity를 추가한다. 기존 keys/값 재귀 및 Array 분기는 바이트상 그대로다.

Dictionary actual exit0은 7명명/22 입력/314 checks다. 독립 원 before 13행과 비교해 동일 metadata 유지하에 기존 value builtin/class/script 양방향 6개는 `ok:true`에서 정확한 `replacement_context_mismatch`로 바뀌었고 다른 7개는 결과가 같다. key metadata의 세 축 양방향, 빈 같은 typed 대조, 완전 typed/untyped 양방향 및 controls 차이를 포함하며 거부 후 sim/context/packet/busy 보존과 정상 pending 소비를 검사한다. 비어 있지 않은 객체 값이나 외부 schema는 별도다.

fresh 실제 exit0 70/11553/45, active 실제 exit0 20/20099/8명명·9호출, viewer 4/47, suffix 6/91을 확인했다. fresh 30초 timeout/exit124는 실패 이력이며 180초 재실행이 약46초에 통과했다. legacy 두 runner는 출력 경로 한 줄만 바꾼 복사본이며 자체 engine PID self-report는 없다. 신규 JSON runner의 실제 body 경로/PID guard 및 각 실행의 console/body·class map 포함 입력 전후/현재 SHA 독립 대조는 모두 일치했다. 다섯 성공 실행 입력 분모는 각각 47/50/48/47/47이다.

이 결과는 해당 Dictionary context 비교와 지정 회귀에 한정한다. 지원 밖 활성 모듈 교체, host/외부 ack, contact 공개 및 일반 운영 Cn/저장 schema는 해결하지 않는다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED 유지. dirty 전수와 ZIP은 별도 closeout이다.
