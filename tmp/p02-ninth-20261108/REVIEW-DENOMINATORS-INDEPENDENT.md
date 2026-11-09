# 행 19~21 분모 보강 독립 심사

판정: **유한한 실행 계약 작성에 유용한 정적 보강으로 수용; 분모 동결 및 제품 실행 승인은 아니다.** `DENOMINATORS-AND-LEGACY.md` SHA-256 `4e71586eda057908031de3eda44ac56d098d15ce15c17f137f2e4a833c7121ac`, `denominator-sources.json` `1df4f46773bf8c7ccc98a54f467acf5b80be89dd1e0b08a22b5766e687015d21`을 직접 확인했다. 심사 turn 메타데이터는 gpt-6.1-terra / low다. 정적 원문 대조만 수행했고 제품·GUI·Job 및 K6는 실행하지 않았다.

서비스 원문 `_restore`는 각 target fleet identity, detection 양쪽 side dictionary 및 각 record의 identity를 검사하고 supply와 repeated apply 검사를 포함한다. 20개 detection segment의 양쪽 record 수가 변수라는 식의 구조는 원문과 양립한다. 문서의 `2122+2Σ(C0+C1)`은 정해진 정상 fixture 및 분기·fleet 수를 전제한 계산이며 그 전제와 개별 실행의 record ID를 별도 입증해야 한다. 과거 총합 2202에서 양쪽 수를 역산하지 않는 판단은 타당하다. WorldLink의 `_buttons`는 visible·enabled BaseButton을 재귀 수집하고 세 device를 순회하므로 stage별 실제 목록이 없는 현재 고정 분모로 간주할 수 없다. headless Q 역시 최종 command log에서 추정하지 않는 것이 옳다. 이 대조는 모든 수식의 독립적 재계산이나 실행 결과 검증은 아니다.

BattleFlow의 조기 반환은 필수 단언 누락을 실패로 처리해야 한다. 기존 진단의 구체 문구·위치 및 정상화 규칙은 역사적 비교 계약으로만 활용하고, 무관한 새 오류를 허용하지 않는다. AutoResolve의 600개는 현재 명령의 세 정책·200회 계약이며 --baseline 비교 분기와 혼동하지 않는다. JSON만으로 Godot 원래 int/float provenance가 증명되지 않으므로 typed source 원문과 JSON 값·row 순서의 대응을 별도로 확정한다. WorldLink clean의 기존 실패는 PASS가 아닌 명시적 편차이고 returning 설정 SHA와 raw stderr를 각각 유지한다. 계측으로 source 위치가 바뀌면 변환 전후 매핑을 별도로 심사한다.

미정값 확보는 다음처럼 유한하게 닫는다. 우선 기존 수용 원문과 고정 fixture에서 seed·tick별 Q, seed·양쪽 C의 ID/typed payload, stage별 버튼 NodePath/device 목록을 추출 가능한지 한 번 대조한다. 자료가 없으면 **미확정**으로 둔다. 제품 경로 또는 제품 fixture를 실제 실행하여 값을 수집하는 것은 이름을 preflight로 바꾼다고 비제품 작업이 되지 않는다. 기존 계약상 최초 제품 검증 프로세스가 K6를 소진하는지 실행 전에 독립 심사하여 명확히 하고, 소진되는 작업은 최종 manifest의 단일 K6 내부 관측으로 편입한다. K6 전에 실행할 수 있는 것은 제품 코드·fixture를 사용하지 않는 최소 격리 Job/GUI 관측성 시험과 정적 원문 분석에 한정하며, 그 결과가 제품 분모를 채우지는 않는다. K6 안에서 동적 수량을 관측할 경우 동일 구현의 결과 자체만 기준으로 삼지 말고 독립 native/reference 및 필수 ID·순서·type oracle과 반례를 미리 준비한다. 기대값을 독립적으로 얻을 수 없으면 그 항목은 미완료다.

계측 overlay의 정확한 전후 diff/SHA 및 assert 순서·누락·중복·false와 output-open 실패 반례를 준비한다. 동적 범위는 fixture·seed별 유한 한도와 terminal/timeout 실패 규칙을 명시하고 예상 성공 외 조기 반환을 금지한다. 이렇게 문서·fixture·oracle·검증기 계약을 한 차례 완성하면 독립 검토 후 나아가며, 이전 총합을 되풀이하거나 문서화만 무기한 반복하지 않는다.

GUI 창 소유·연속 foreground·요청별 입력 귀속과 실제 Godot broker/자손 Job 소유·종료는 별도 사전 적합성 명세 및 실제 관측이 여전히 필요하다. GUI hook의 관측 및 cleanup 한계, injected flag만으로 주체를 특정할 수 없다는 제약, Job assign 거부 미재현 시 미검증 처리를 유지한다. 사전 비제품 시험과 21행의 제품 실행, 외부 독립 5-b는 서로 대체할 수 없다. K1~K5 및 K4/K5 실패 기록, 마지막 K6 한 회와 P03·기존 source는 보존한다.
