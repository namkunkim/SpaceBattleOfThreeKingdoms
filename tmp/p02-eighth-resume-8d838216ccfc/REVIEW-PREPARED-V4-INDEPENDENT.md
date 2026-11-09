# K6 준비 V4 독립 심사

판정: **실행 반려**. `MANIFEST-V4-REVIEW-ONLY.json` SHA-256 `437446d9fd409895bf87b64042be9aba491a6fb82c996e25da0367f3451b8899` 직접 확인. 현재 명시 dependency 183개 bytes/SHA 일치, 58 jobs 및 20270초 확인. 심사 turn metadata gpt-6.1-terra / low. 제품 실행이나 OS 입력은 하지 않았다.

K3/K4의 회귀 suite 미실행과 과거 marker를 이력으로만 분리하고 7종 분모 미동결을 명시한 점은 타당하다. 행 17/18 판정기는 중복 JSON 키, 타입·필드 및 원문 B/A 차이를 검사하고 K4 before에서 동결한 full outcome을 기준으로 사용한다. 합성 로그에서 과거 원문이 새 lifecycle 조건을 충족하지 못함, 보강된 합성 데이터와 변조 거부를 확인했다. 이는 새 GDScript의 실제 파싱·결과나 JSON에서 엔진 내부 타입 전부를 증명하지 않는다. 취소 후 재클릭 조건도 미해결이다.

추가 반증: `world-product-v4.gd`의 complete 분기는 175초 deadline에서 여전히 `resolve`여도 `resolver.sim.fingerprint()`를 읽고 quit한다. worker가 살아 있으면 live sim 동시 접근이며 명시적 cancel/join이 없다. timeout을 별도 실패로 기록하고 sim 접근 전에 해당 worker를 취소·join했는지 확인하도록 고친 뒤 재심해야 한다. 완료 경로 역시 join 검증 전 live 상태 읽기가 일어나지 않아야 한다.

합성 원문의 비정상 broker와 살아남은 소유 자손은 Job 종료 후 active 0 및 표식 부재를 확인했다. 중첩 Job 거부는 mock이며 실제 Godot wrapper 및 OS 거부는 미관측이다. 비소유 프로세스는 종료하지 않는 원칙과 fail-closed를 유지한다.

GUI의 연속 foreground·독점 입력 귀속은 미해결이며 7종 suite 분모, 제품 probe 실제 형식, 행 18 재클릭 및 위 timeout 문제가 남아 있다. 현재 상태와 runner의 실행 차단을 유지한다. 실제 K6 시작 전 전체 21행과 명령·원문·expectation·SHA·시간·소유권을 재동결하고 별도 독립 심사해야 한다. 과거 K1~K5/실패 및 원본 checkout·Git·HTML·P03을 보존한다. 본 판정은 제품 적용 또는 5-b가 아니다.
