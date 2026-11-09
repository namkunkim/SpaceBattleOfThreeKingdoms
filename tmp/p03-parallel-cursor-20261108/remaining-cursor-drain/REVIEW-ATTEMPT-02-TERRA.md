# attempt-02 hard stop 독립 판정

판정: 기존 실패는 보존하고, 아래 조건에서 새 시도로 재개 가능. attempt-02 자체는 실패이며 PASS로 전환하지 않는다. 심사에서 엔진을 실행하거나 기존 산출물을 수정하지 않았다.

- `input-before.json`과 `input-after.json`의 135개 항목은 키·SHA·크기가 모두 동일하며, 심사 시 현재 파일도 종료 해시와 일치했다. `input_stable=false`는 해시 차이가 아니라 launcher가 외부 status delta를 안정성에 함께 포함한 결과다. HEAD 일치와 `input_after_errors=[]`, Job active 0, timeout 없음도 기록돼 있다. 이것은 실행 중 변했다가 복원된 내용을 배제하거나 전체 트리 불변을 증명하지 않는다.
- delta 6개는 모두 별도 `tmp/p03-product-resume-20261108/detection-ui/`의 결과·로그·격리 appdata 경로다. 같은 폴더의 `exits.txt`는 SIDE 0/1 완료, `run-input-audit.txt`는 해당 별도 프로젝트의 입력 목록을 기록한다. 그 내용과 경로는 동시 UI 작업 출처라는 판단을 뒷받침한다. 이 파일들은 보존한다. status 경고로 전체 트리의 완전한 변경 감시는 불가능하다.
- stdout은 32개 검사 중 각 케이스의 8번만 FAIL, 실제 exit 1이다. `probe.gd`의 `_closed`는 `summary()` 오류를 두 키만 있는 Dictionary와 정확 비교하지만 실제 `summary()` 가드는 `path: owner`를 추가한다. 이는 코드에 의해 확인되는 검사 기대값 결함이다. close는 void이며 close 이후 summary의 정확 반환을 올바르게 비교하도록 runner만 수정하는 것은 계획의 분모·가설 변경이 아니다. 수정 전·후 차이와 기존 원문은 보존하고 K=6 안에서 센다. 나머지 PASS도 이 실패 시도의 관측일 뿐 최종 수용 증거가 아니다.

재개 조건: 외부 UI 작업 종료 또는 해당 작업의 독립 증거에 근거한 안정된 새 시작 상태를 기록하고, 기존 delta 파일은 건드리지 않는다. runner 수정 후 승인된 계획 SHA를 재확인하고, 새 시도에서 전체 동결 대상 및 경로를 재열거·해시하고 preflight를 다시 통과해야 한다. 동시 status delta나 입력 해시 변동 등이 다시 나타나면 계획대로 중단·보고·재심사한다. 종료 시 새 전후 해시와 원문·실제 종료 코드, 외부 상태 차이를 5-b에서 독립 대조한다. 장기 실행이 종료되었다는 사실은 이 심사에서 확정하지 않았으므로 재개 직전 별도로 확인한다.
