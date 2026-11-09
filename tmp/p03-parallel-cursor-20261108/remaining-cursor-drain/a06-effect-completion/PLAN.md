# A06 가상 효과 완료와 처리 표식의 반례 계획

새 Terra 계획 심사 전 구현·실행 없음. 이 조각은 Python 표준 라이브러리의 독립 가상 수신기와 수기 기대표를 전용 폴더에만 두는 후보이며 Godot/공유 코드/P02를 사용하거나 변경하지 않는다. A06 처리 키만 존재하고 효과가 누락된 경우 실패, 적용 명령 1/2와 대기 3 경계를 배경 요구로 삼되 이 모델은 seq 적용 자체를 구현하지 않는다. D04 ST18의 UI 수신과 실제 효과 완료 구분을 하나의 가상 재화 +1 효과에서 관측한다. 기존 cursor/drain은 외부 Array 재수신, outcome 원장은 결과 전달/표시 순서를 다뤘다. 이번 조각은 둘을 지급이나 durable 상태로 승격하지 않는다.

## 모델과 기계 관측

상태는 활성 context A, effect key K의 처리 표식 boolean M, 독립적으로 읽는 반영량 int E다. 합성 입력은 모두 같은 의도인 A/K에 +1이다. 완료 관측의 수기 기준은 M=true, E=1이다. 부분 실패를 임의로 주입하는 별도 모델로, 실제 storage commit이나 회복을 모사했다고 주장하지 않는다. reset 후 시작 상태는 매 케이스 M=false/E=0이며 이전 케이스를 참조하지 않는다. M과 E는 별도 값으로 관측하며 key 존재만으로 판정하지 않는다.

6개 명명 × 3 단언을 고정한다. 각 케이스는 ① 명시 주입 시점의 정확한 (context,M,E) ② 재시도 또는 guard 뒤 정확한 최종 (context,M,E) ③ 수기 완료 기준 및 명시 오류/결과와 일치, 총 18개다.

1. nominal: 둘을 반영한 (A,true,1), 동일 key의 시험 재수신 뒤 그대로, 완료. 이 fixture는 단일 실행에서 성공 표식을 본 경우 skip하는 정책 가정이다.
2. marker_first_interruption: 표식 뒤 실패하여 (A,true,0), 같은 key의 marker-only skip 재시도 뒤 그대로, 효과 누락으로 미완료.
3. effect_first_interruption: 효과 뒤 실패하여 (A,false,1), marker-only 재적용이 E를 다시 증가시켜 (A,true,2), 중복으로 미완료.
4. projection_only: UI 관측 신호만 켠 가상 중단에서 (A,false,0), UI 신호를 다시 전달해도 동일, 미완료. UI 신호는 모델 외 보조 기록이며 완료의 대체 기준이 아니다.
5. wrong_context: (A,false,0)인 활성 대상에 context B의 같은 K를 제출, 가상 context 비교에서 거절하고 (A,false,0) 보존, context_mismatch 및 미완료. 운영 epoch 발급 정책을 채택하지 않는다.
6. rollback_countermodel: 실패 주입 전 (A,false,0), 두 값 반영 시도 중 하나의 실패가 외부에 보이기 전에 둘 다 이전 상태로 되돌아간 것으로 가정, 재시도 뒤 (A,true,1), 완료. ①은 실패 후 격리된 관측의 이전 상태, ②는 재시도 후 상태다. 이 케이스의 rollback은 가정으로 제공하는 모델 동작이며 저장 원자성의 구현 또는 입증이 아니다.

## 게이트와 범위

별도 수기 기대표와 모델을 분리한다. 5-a는 고유 이름 6 및 18개 번호의 정확 순서·모두 일치, 원문 stdout/stderr·실제 종료 코드, PLAN/정본 H2·D04·I01 A06/기존 cursor 5-b/outcome 원장과 모델/runner/기대표/실제 Python 실행 파일의 SHA·크기 전후 고정, 전용 쓰기 범위만 요구한다. 입력 누락·변동·진단·분모 불일치 또는 실행 환경 한도는 실패 원문 보존 후 중단한다. 코드 수정 가능 실패는 최대 K=3, 사용량 제한은 즉시 보고하고 반복하지 않는다. 실패 가설·분모 변경 시 새 심사. 5-b는 별도 Terra가 수기 기대표·실패 주입 및 관측을 독립 대조한다.

marker-first/effect-first/rollback은 비교할 가상 대안이다. 실제 실행 순서, 저장소, 키/epoch, ACK, 운영 재시도 및 커밋은 선택하지 않는다. 효과가 여러 개이거나 외부 결산을 복구하는 계약도 미결이다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
