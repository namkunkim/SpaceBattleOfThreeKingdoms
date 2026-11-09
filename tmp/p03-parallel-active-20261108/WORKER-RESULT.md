# P03 활성 DecisionBoard 제품 경계 결과

2026-11-08 KST. Sol 작업 및 Terra 계획 승인. 아래는 5-a 관측이며 독립 5-b와 마감은 별도 기록이다.

| 명명 검사 | 관측 |
|---|---|
| production_constructor_decision_board | 3D 호스트 기본 인자 red_cliffs_rt.json·표준으로 Organization.load_auto에서 대체 없이 정본 프로필을 얻었다. 시나리오 원본의 결정 카드 8개와 프로필 데이터가 일치했다. 직접 만든 BattleSim에 정본 DecisionBoard가 활성화됐고 역참조가 같은 sim이었다. |
| restricted_adapter_baseline_restore | 제한 adapter가 owner를 만들었다. DecisionBoard 없이 C0를 capture하고 tick 1로 전진한 뒤 같은 context를 복원했다. sim이 교체됐고 tick 0·DecisionBoard null·ready·busy false였다. |
| restricted_adapter_decision_scenario_rejection | 정상 입력에 적벽 카드가 든 scenario만 추가하자 `{"ok":false,"error":"unsupported_scenario","path":"profile"}`를 반환했다. owner가 없었고 입력 직렬화 바이트를 보존했다. |

제품 3D 경로는 실제 호스트 기본 자동 편성 입력과 직접 BattleSim 생성 경계를 재현했다. UI 준비·게시·조작은 실행하지 않았다. 정적 추적에서 3D 호스트가 자체 sim을 게시하고, 제한 자동결산은 adapter owner를 전진하며, fresh replay는 새 owner를 만드는 경로를 확인했다. 조사한 생산 GDScript에서 restore_completed의 직접 호출은 발견되지 않았다. 동적 호출 및 향후 배선은 이 조사 범위 밖이다.

선행 강제 주입의 capture 거부 및 restore 후 활성 모듈 소실은 기존 결과와 독립 마감 범위 그대로다. 이번 실행은 정상 제품 생성에서 활성 DecisionBoard를, 제한 adapter에서 그 상태를 요구하는 단일 입력 변이 거부를 각각 관측했다. 정상 제품에서 제한 owner의 활성 DecisionBoard에 도달하거나 restore가 이를 폐기하는 경로, 그 경우 운영 거부/수용 계약, UI 보존과 외부 효과 원자성은 미입증이다. 전체 적벽 프로필의 최초 adapter 거부 이유도 시험 범위 밖이다.

## 실행과 보존

- K=3 중 2회. `python -B tmp/p03-parallel-active-20261108/worker_gate.py 1`은 실제 Godot exit 0, 명명 3개/24 단언, 54 ObjectDB와 18 리소스 종료 누수, 5-a exit 1. 테스트가 만든 sim 역참조의 해제 목록을 보완하고 로드된 난이도 동등성도 명시했다.
- 같은 명령의 attempt 2는 실제 Godot·5-a exit 0, 명명 3개/24 단언, SCRIPT ERROR/ERROR/WARNING/누수 0, 전용 Windows Job 프로세스 총 2개·종료 후 활성 0. 각 시도의 run.json, runner.gd.txt, stdout.bin, stderr.bin, 전후 input JSON에 원문이 있다.
- 두 실행 각각 HEAD 불변 및 70개 동결 입력 SHA 일치. 엔진 본체 SHA-256 `ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424`, console `c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643`.
- 초기 핵심 입력 18개는 종료 시 모두 동일하다. WORKER-CONCURRENT-STATUS.json의 외부 추가 표시는 P02 205개, 다른 P03 조각 8개이며 제거 표시는 없다. 시작 status의 Windows shader cache 경로 길이 경고 후 종료에서는 core.longpaths를 사용했으므로 P02의 205개를 모두 새로 생성된 파일로 해석할 수 없다. 기존 전체 dirty 바이트를 비교한 감사 범위도 아니다.
- 공유 Git diff --check exit 2는 기존 CHECKLIST-OPEN.md:33 P2c 라인이다. 전용 probe, gate, Job helper, 작업 계획의 줄 끝 공백 검사 각각 0. 쓰기 범위는 전용 폴더였다.

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
