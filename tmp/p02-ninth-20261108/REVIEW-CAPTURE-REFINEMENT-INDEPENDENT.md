# Q/C 보강과 W4 시간 정정 독립 심사

판정: **정적 보강 수용, 실행·완전 oracle 판정은 보류.** `CAPTURE-REFINEMENT-REVIEW.md` SHA `1e09855b5fdbc4e4b07be3263bc6a1c778ff6196412f8a0311d0b39e86d5ead9`, `capture-refinement-review/SHA.json` `581782c93a06c0df2cadc269e236d04aad9d8a2261e90e04909333f86da0786a`, `independent_qc_oracle.py` `593926aeb37b2294cc2c57befab2fd6ebb644d32f9211e7054cc14c7aa758717`, `WATCHDOG-W4-TIMING-REVISION.md` `7757e9dff44b2a025f67f0e0590201d64e938a8423befbfaa28df262fc8ae97b`를 확인했다. 심사 turn 모델 gpt-6.1-terra. 제품, Godot, GUI, Job 및 K6 실행은 없다.

Q Python은 roster projection에서 별도 policy 구현으로 기대 command를 계산하며 제품 정책 함수를 재호출하지 않는다. 다만 원 projection·좌표와 historical tick 벡터의 정합성은 입력 가정이고, 공통 캡처의 fields/typed bytes가 서로 모순되어도 각 경로가 반드시 거부하는지 별도 검증해야 한다. float32 거리와 동률의 실제 Godot 빌드 의미를 고정된 경계/tie 반례로 대조해야 하며 현재 실측 주장은 불가하다. 별도 함수라는 이유만으로 fixture, BattleSim 공통 오류, event·alias 의미까지 검증했다고 볼 수 없다. 사건·alias는 기존 별도 행의 실제 callback, 사후 변경 및 증원 비교에 남는다.

C는 restore 성공 receipt와 양측 typed bytes를 요구하고 side 0 역사 20건 비교를 추가해 범위를 넓혔다. Side 1은 `[]`와 `[1]` 양쪽을 허용하므로 정확 presence·payload의 독립 기대는 아직 없다. 양측이 똑같이 record를 누락하는 반례를 side 1에서 반드시 잡는다고 주장할 수 없다. 동일 encoder의 오류·source fixture의 잘못된 contact도 공통 모드다. 역사 case 키의 중복·누락 및 records/fields/typed bytes 상호 일관성을 명시적으로 거부하고, restore 전후 identity detach·원본 불변과 별도의 사건 판정을 유지한다. Python 처리·합성 결과는 엔진 parsing과 실제 typed payload의 검증이 아니다.

B가 동적 이름으로 static 절대 NodePath 동결에 실패했음을 솔직히 남긴 판단은 타당하다. constructor 참조와 child index는 보조 증거이며 109는 미측정이다. 실제 요구의 독립적인 구조/의미 oracle을 만들지 못하면 B는 미완료로 유지한다. 제품 세 파일 외에 안정 이름 추가는 별도 범위 결정 없이는 하지 않는다.

W4의 5+30+5+8+7=55초 산술은 맞고 이전 8초 총량과 충돌하는 문제를 해소한다. 이는 worst-case 가정일 뿐 실측이 아니다. 각 단계 cap의 강제 수단과 monotonic 기준, POSTVERIFY_BEGIN 영속 receipt 수신 손실·지연, local/global 동시 만료의 우선순위, 7초 reserve에서 drain 5초 및 journal flush 실패를 명세해야 한다. 엔진 정상 종료·inner active 0이 확인되지 않으면 W4 postverify 성공이 아니다. supervisor/controller, outer/inner membership 및 filesystem confinement가 없어 여전히 실행 명세가 아니다.

다음은 Q/C 필드와 typed bytes의 독립 일관성·동일 누락/tie 반례, C side 1 oracle 및 B 대안 확정과 watchdog 실행 코드·소유/파일시스템 경계의 별도 독립 심사다. 독립 기대를 얻을 수 없다면 해당 항목을 미완료로 남긴다. GUI Sky 요청 귀속이 해결되지 않아 전체 K6을 개시하지 않는다. K1~K5 및 K4/K5 이력, 제품 import부터 소진되는 K6 잔여 1회, P03 현재 변경과 원본 보호를 유지한다. HEAD lane은 P03 결합을 증명하지 않는다.
