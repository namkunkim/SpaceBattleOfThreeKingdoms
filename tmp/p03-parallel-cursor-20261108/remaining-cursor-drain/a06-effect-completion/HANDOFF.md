# A06 가상 효과 완료 인계

Terra 승인 PLAN.md SHA 9F55C39E6A98EC7DA41B3B940474D44CF2AD4F6CCFDBE5BCD8DC4F539BBAB607을 확인했다. 모델은 receiver.py, 별도 수기 기대는 expected.json, 실제 결과 비교는 probe.py에 있다. gate.py의 attempt-01은 Python actual exit0, 사전등록 순서대로 6개 명명과 18개 PASS, stderr 0, 실행 전후 11개 입력의 경로·SHA/크기 동일이다. Godot 실행은 없었다.

표식 선행 실패는 표식이 있는 상태에서 재수신을 건너뛰어 E=0으로 남았다. 효과 선행 실패는 동일 효과가 재적용되어 E=2가 됐다. 표시 반례는 notify(K)를 실제 두 번 호출해 수신 기록 [K,K]를 남겼지만, 최초와 재수신 뒤 모두 (A,false,0)이었다. 문맥 B의 제출은 거부됐으며 A를 유지했다. rollback 대조는 부분 시도 후 두 값을 이전 상태로 돌린다고 가정한 가상 모델이다. 운영 저장이나 실제 복구 실행으로 해석하지 않는다.

다음 독립 조각은 A06 FX-S 입력·관측 분모의 읽기 대조다. 기존 명령 1/2 적용과 3 pending, 이 가상 효과 반례, 기존 owner epoch 및 active projectile 참조 증거를 각각 출처와 함께 매핑하고 어떤 승인 전제가 부족한지 구분할 수 있다. 운영 실행 착수에는 제품 효과 소유자와 완료 원장, 실제 epoch와 durable commit/복구 정책, 공유 경로 소유권 및 외부 증거가 필요하다. 이 작업에서 정책을 채택하지 않았다.

5-a PASS, 별도 Terra 5-b 대기. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED. 공유 생산 코드와 P02는 읽기만 했다.
