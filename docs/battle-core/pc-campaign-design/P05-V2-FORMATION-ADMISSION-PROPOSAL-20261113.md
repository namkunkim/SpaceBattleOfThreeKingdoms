# P05 적벽 작전 v2 진형 명령 결정안

상태는 제안이며 제품 정책 승인을 기다린다.

검토 기준은 원격 main `9be4eaab506e433e0fa255c826ed48b6a6d81b80`이다. 승인 v1은 공개 진형 명령을 거부한다. 작전 정의의 `allowed_formations`는 이동 제안의 함대 자세를 검증할 때 사용된다. 공개 진형 명령을 허용하는 계약은 확인되지 않았다. [v1 명령 접수](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/9be4eaab506e433e0fa255c826ed48b6a6d81b80/core/battle/first_operation_dev_runtime.gd#L92) · [이동 자세 검사](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/9be4eaab506e433e0fa255c826ed48b6a6d81b80/core/battle/p05_p07_first_operation.gd#L74)

## 제안하는 첫 범위

새 capability와 저장·재생 버전으로 명시적으로 선택한다. 초기 범위는 직접 지휘의 `RC-LIU-SQ-01` 또는 `RC-LIU-SQ-02` 한 함대와 `FRM-01↔FRM-03`이다. 기록은 `{kind: "formation", squadron_id, formation_id}`와 적용 틱·배치 순서를 담는다. 문자열 식별자를 동결 편성과 현재 소유자에서 정확히 한 번 해석하고 런타임 숫자 ID는 저장하지 않는다. 사망·이탈·비아군·불일치 편성, 이미 종결되거나 철수 중인 작전은 접수를 거부한다. 현재 인증을 사용하는 동안에는 손실·원점 이동·방향 변경으로 인증 조건이 깨지는 경우도 거부한다.

**정지 우선 정책 제안.** 이동 중에는 `stop`을 먼저 적용하고 실제 정지 자세가 확인된 다음 틱부터 진형 명령을 허용한다. 동일 틱 배치에서 `formation`과 `move`·철수 전이를 섞는 입력은 제출 순서에 따라 일부가 적용되는 일을 막기 위해 충돌 명령을 접수 단계에서 거부한다. 전환 중에는 이동·철수 진입 요청을 거부하고, `stop`은 진형 전환을 유지한다. 같은 목표 재지정은 타이머를 유지하고, 현재 진형 재지정과 다른 목표 교체는 첫 범위에서 거부한다. 안전한 중단 자세와 시각 복귀가 검증되면 취소 및 즉시 철수를 별도 범위로 검토한다. 자동 보급·목표 효과와 자연 종결은 기존 작전 정책의 동일 틱 순서를 유지한다.

## 저장·재생과 원자성

새 형식에서 대기 명령과 적용 배치 순서를 저장한다. 같은 승인 입력과 규칙에서 초기 상태부터 재구성하고, 대기 명령은 체크포인트에서 되살려 이후 동일 틱에 한 번 적용한다. 원본 v1은 기존 allowlist와 기존 형식으로 유지한다. v2 입력을 v1로 해석하거나 v1 슬롯을 자동 변환하는 동작은 적용 범위 밖이다. CLI·호스트·공개 재생기는 capability 및 형식 불일치를 명시적으로 거부한다.

구현 전 원자성 경계를 수정해야 한다. `FirstOperationDevRuntime.advance`는 정책 제안·효과·확정 실패 때 `NativeTick.rollback_tick`으로 복구한다. 현재 `NativeTick.checkpoint_tick`은 함대와 사건을 보관하지만 `command_log`는 보관하지 않는다. `BattleSim.issue`가 즉시 로그를 추가하고 `replay_witness`에 그 로그가 포함되므로, 정책 확정 전에 명령을 발행하면 롤백 뒤 로그가 남는다. v2 명령 처리에서 로그 길이를 체크포인트에 함께 담아 실패 시 잘라내거나, 확정 전에는 별도 임시 기록에 보관한다. 최종 명령 이력, 공개 사건, 원장, 대기 배치의 변경은 같은 성공 경계에 둔다. 정상 명령 소비와 재시도는 한 번씩만 일어나도록 한다. 이 누출은 v2에서 확정 전에 네이티브 발행을 추가할 경우의 위험이다. 현행 v1 작전 경로는 진형 명령을 거부하며 이 발행을 하지 않는다. [틱 확정 및 롤백](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/9be4eaab506e433e0fa255c826ed48b6a6d81b80/core/battle/first_operation_dev_runtime.gd#L56) · [네이티브 명령 기록](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/9be4eaab506e433e0fa255c826ed48b6a6d81b80/core/battle/battle_sim.gd#L142) · [체크포인트·재생 증명·롤백](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/9be4eaab506e433e0fa255c826ed48b6a6d81b80/core/battle/first_operation_native_tick.gd#L39)

## 승인 후 첫 인수 시험

- 두 편성의 허용 진형과 안정 ID, 잘못된 상대·숫자 ID·손실·이동·선회 및 같은 틱 충돌 거부를 확인한다.
- 진행 중 저장, 새 Windows 프로세스 재개, 남은 50틱 타이머와 대기 명령, 공개 리플레이의 동일 사건·다이제스트를 비교한다.
- 정책 제안·효과·확정 실패 직후 상태·원장·네이티브 로그·대기 명령이 보존되고 재시도에서 한 번만 반영되는지 검증한다.
- v1의 기존 슬롯·리플레이를 읽고 v1에서 진형 명령을 계속 거부하는지 확인한다.
- 권위 투영을 표시 어댑터에 연결하는 단계에서 원점·방향·편성 조건, 취소·종료와 지연·가속도 정책을 따로 검증한다.

기존 코어와 제품 코드는 변경하지 않았다. 실행 구현은 정지·철수·취소 정책과 v2 호환 경계 승인 뒤 진행할 수 있다.
