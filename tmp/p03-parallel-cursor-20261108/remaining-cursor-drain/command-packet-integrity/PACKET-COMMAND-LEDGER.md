# 제한 checkpoint 명령 이력의 검증 범위

원장 표의 P는 operation_private_state.gd, S는 operation_service_state.gd, B는 battle_sim.gd, R은 operation_replay.gd다. H2/D04의 외부 계약과 구분되는 내부 in-memory 후보 검사다.

| ID | 대상 | 실제 코어 생성 | 후보 검사와 정확 거부 또는 확인 범위 |
|---|---|---|---|
| C01 | log 명령 구조 | B142–146 및 B172–179가 명령 사본에 현재 tick을 넣어 log에 append한다. 논리 거부 전에 log가 기록될 수 있다. | P189–204의 데이터·정확 키·타입·side·고유 비음수 ids·종류와 args 검사를 P310–311이 각 행에 호출하며 실패를 log_command로 반환한다. 그 전에 P296의 전체 데이터 검사 및 P306–307의 배열 검사에서 unsupported_value 또는 sim_container로 실패할 수 있다. |
| C02 | log 시간 | B145 및 B178의 append는 실제 당시 tick을 기록한다. | P455–456은 각 log tick에 0 ≤ tick ≤ state.tick을 요구하고 위반 시 log_time을 반환한다. 인접 행의 단조 순서를 비교하지 않는다. P189–204의 구조 검사가 별도로 선행한다. |
| C03 | pending 구조와 입력 tick | P212–221은 입력을 깊게 복사하고 B95–96은 append만 한다. B172–179가 step에서 pending을 순서대로 빼고 tick을 현재 값으로 덮는다. | P312–313은 P189–204의 구조 검사 실패를 pending_command로 반환한다. 각 입력 tick은 int이며 -1 이상이어야 하나 이 경로에서는 state.tick 상한을 검사하지 않는다. P455–456의 시간 루프 대상은 log다. |
| C04 | event 구조와 시간 | B214–215는 현재 tick·kind·sq·other·pos·value를 사건 배열에 append한다. B98–101의 drain은 배열을 꺼낸다. | P453–454는 정확 필드와 tick의 int 및 0..state.tick, kind String, sq/other int, pos Vector2를 요구해 event_fields를 반환한다. value는 P296 및 S77–93의 일반 안전 데이터 검사를 거치며 여기서는 kind별 payload나 명령 참조를 대조하지 않는다. |
| C05 | 컨테이너 복사와 관측 일치 | P44–48은 _take/_put에서 컨테이너를 복사하며 SIM_DATA(P14)에 세 이력 배열을 포함한다. | P472–476은 sim 상태를 후보에 복사하고 서비스 복원 및 bindings를 확인한다. P330–332은 후보 observe와 입력 view가 S62–74의 _same에 일치하지 않으면 restored_state_mismatch로 거부한다. 배열 길이와 위치별 값, Dictionary keys()와 값의 재귀 비교로 배열 및 키 순서를 검사하지만 container의 typed metadata를 별도 조회하지 않는다. 이는 입력과 후보 결과의 대조이며 독립 원본의 이력을 검증하지 않는다. P337–357의 _context_same은 별도 교체 context 비교다. |
| C06 | 행 순서와 이력·state 상호 대조 | B142–180의 log append, B214–215의 emit, R117–142의 fresh 지역 소비는 서로 다른 경계다. | P310–313, P453–456은 위 구조·시간 검사에 한정된다. P472–476 및 P330–332은 후보가 주어진 배열을 보존하는지 확인하는 흐름이다. 각 배열이 지정 순서로 복원되어도 log 재실행의 state 일치, pending의 외부 접수 이력, 사건의 log 대응 또는 durable cursor를 이 검사들이 도출하지 않는다. |

## 교차 반례 3개

1. **유효한 두 log 행의 역순**. 서로 다른 두 유효 tick이 모두 0..state.tick이면 순서를 바꿔도 P310–311과 P455–456의 각 행 조건은 유지된다. S62–74는 같은 입력과 후보 간 위치별 비교를 하므로 원래 순서를 외부에서 알 수 있는 검사로 해석할 수 없다. 해당 guard의 정적 결론이며 전체 후보 수용은 미실행이다.
2. **미래 입력 tick의 pending**. state.tick 2에서 구조가 유효한 pending 명령의 입력 tick 77은 P189–204 및 P312–313의 각 검사에서 허용되는 정수 범위다. B172–179는 적용 때 실제 tick을 다시 쓰는 경로다. 과거 suffix에는 동일한 종류의 입력 tick 77이 포함됐지만 이 원장의 독립 변조 후보 수용 실험으로 계산하지 않는다.
3. **형식과 시간이 맞는 사건**. state.tick 2에서 tick 2, kind say, sq 1, other -1, 유한 Vector2와 String value를 가진 사건이 대응 log의 변경 없이 있다면 P453–454와 S77–93의 명시 형식·시간 조건만으로는 해당 log와의 인과를 구별할 수 없다. 사건은 명령 외 코어 경로에서도 생길 수 있다. 이 사실로 후보 전체 수용이나 제품 결함을 판정하지 않는다.

## 선행 증거와 인수 경계

- 기존 command suffix는 실제 same-tick 전진·복원·동일 suffix, 구조 거부와 명령 순서를 시험했다. 여기서는 해당 결과를 구조와 시간 검사에 관한 겹치는 근거로 인용한다.
- 기존 fresh replay 독립 재심사는 내부 owner의 A 처리와 terminal 이후 B 미소비, raw 사건 및 지역 소비량을 확인했다. R88–89의 commands_consumed는 이 fresh 실행의 처리량이며 운영 cursor의 증거로 사용하지 않는다.
- cursor/drain attempt-03은 Godot exit0과 32 PASS 관측 뒤 외부 쓰기 범위로 종합 5-a가 실패했다. lifecycle의 가드/DTO 11행은 구조·시간과 다른 책임이다. 신규 Godot 실행은 없다.
- D04 ST02/ST18과 I01 K05~K07은 논리 시간, 예정·적용 순서와 향후 적용·커밋·효과 책임을 구분한다. 정책·외부 schema는 미결이다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED를 유지한다.
