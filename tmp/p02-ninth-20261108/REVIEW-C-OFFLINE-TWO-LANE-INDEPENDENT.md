# C 두 lane 오프라인 rehearsal 독립 심사

판정: **두 lane의 합성 join 조각은 제한 수용한다. 실제 C·P02 완료 또는 제품 실행 수용이 아니다.** `C-OFFLINE-TWO-LANE-ACCEPTANCE.md` SHA `b8074fc1f2e181d8262d0013fb04fbab82e86294184e6d27d08757cafa4cc11b`, 목록 `2ba8035ec05f247f0f9b393cfb38600629eb00c018cc0a86e2bf1ac8149cfaff`, verifier `c2dca4c8e42dede9b19365242c95972ce269f23d197593c404c2cbae9511c037`, 합성 log `88bb2c8fde94977be24201345973e9d56366ea3f25e855be7c5a2f5f2cf61047` 직접 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

코드상 승인 bytes/fixture source hash, 두 lane의 서로 다른 run ID, whole-lane raw 순서, `_eval` payload에서 유도한 geometry 및 20개 pin에 대한 다섯 restore의 v9 scoped 의미 검사를 순차 결합한다. `live_stages`의 최초 세 단계 합은 `Salvo.present_of` 원문과 일치한다. 기존 raw는 바꾸지 않고 v4가 요구하는 actor별 view만 정렬한다. 보존된 합성 로그의 10,160 rows·8,960 eval·200 calls 및 approval/pin/geometry/request/run ID 5종 거부는 이 한정 조합에 대한 근거다. 실제 engine 또는 fixture의 관측 수가 아니다.

이 통합은 **독립 원천의 보증이 아니라 입력·승인 기록의 신뢰를 전제로 한 결합**이다. raw payload와 expected geometry가 같은 합성 generator에서 나올 수 있으며 공통으로 조작된 position/config·정확하지만 잘못된 독립 pin·같은 producer의 허위 _eval 기록은 이 join만으로 배제할 수 없다. 해당 engine/fixture context 및 approved pin이 후보 외부에서 만들어졌는지, launcher PID/HANDLE·engine/source/overlay closure와 raw SHA가 같은 실제 run에 연결되는지 별도 증거가 필요하다. 각 config의 수치 동등성 검사와 typed context 전체의 실제 의미/형식, engine Variant decoder·float 연산 및 producer의 side effect·output/time은 미실측이다.

`evidence`는 alias 사건의 순서만 요구하며 payload 의미·실제 identity detach·원본 packet 변경 후 source/target 불변·suffix event/command 전체를 검사하지 않는다. `collect_case`의 scoped outside 비교도 원래 `_all`, 모든 오류 분기 및 실제 요청의 호출 증거를 독립적으로 대체하지 않는다. missing/duplicate/order·phase 교체 외에도 두 lane의 동일 잘못된 config/fixture와 pin 의존성, raw event↔geometry·packet 상호 불일치, alias payload 변조, restore false·external state 변조와 output 누락 반례를 전체 통합 경로에서 별도로 추가해야 한다. 후속 실제 수용은 실패/timeout을 통과로 바꾸지 않는다.

Python K3 세 실패는 유지하고 다른 이름의 새 시험 예산으로 초기화하지 않는다. 실제 producer·source identity, Q/B, Sky GUI provenance, Job·최종 manifest는 아직 미완성이다. 현재 P02 NOT_READY이며 최초 제품 import/검증 spawn에 소진되는 K6 한 회가 남는다. HEAD lane은 활성 P03 변경과의 결합을 증명하지 않고 P03·worker·기존 원문 및 Git 상태를 보존한다.
