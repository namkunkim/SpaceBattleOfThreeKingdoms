# 소유 이미지 진단 후속안 독립 심사

판정: **source-only 진단 설계 및 합성 seam을 제한 수용한다. 실제 재시도는 아직 승인하지 않는다.** 계획 SHA `ff592a7504efb4230561a13df11a36f2b1bfd319df17375f39f027b035281b9b`, 목록 SHA `cd97584c69d600ae96990ab974279a7208f2b276040d3eda36597bfe932d42ec`, `owned_image_diagnostics_review.py` `50fcd4bfb7c7e6e83af2c09f4154ac8bd1b0557cd53538c6ebce3e514239fc2f`, `retained_job_queries_review.py` `5faf965c20c54e1d60d6e934f20ccec702109b7f93faec795d89033ce8f6c8d3` 확인. 심사 모델 gpt-6.1-terra. 실제 Python child·Job·Godot·제품은 실행하지 않았다.

정확한 retained process HANDLE에 대해 Job membership 양성→생존/PID/creation→raw image→membership·생존·identity 재검사하는 순서는 무관 프로세스를 조회하지 않고 이미지 누락 문제를 다루는 타당한 설계다. ID가 바뀌거나 소속이 없어지면 raw image를 버리고 첫 오류와 cleanup을 분리하는 것도 적절하다. 실패 시 image 경로·PID·creation·단계·membership을 실제로 보존하면 재발한 동일 종류 실패의 원인 후보를 좁힐 수 있다. 그러나 기존 실패의 누락된 값을 소급 복원하거나 단명/조회 실패가 재현될 때 원인을 반드시 식별하지는 못한다. Win32 API 자체는 미실측이며 합성 결과만으로 관측 성공을 주장하지 않는다.

기존 실행기는 `Path.resolve()` 후 `normcase`, 이 seam은 파일을 열지 않는 `ntpath.normcase(normpath())`를 사용한다. 둘은 junction/symlink·경로 별칭에서 동등하지 않을 수 있으므로 seam의 `allowed`를 기존 실제 allowlist 판정의 대체 승인으로 취급하지 않는다. raw path와 두 비교 경로의 차이·에러를 명확히 기록하고, 다른 spelling이라는 이유만으로 image bytes나 신뢰를 추정하지 않는다. 허용 목록은 변경하지 않는다. 단명 프로세스, membership 상실, HANDLE 취득 전 PID 재사용·조회 실패는 미확인/실패이지 다른 프로세스로 재조회할 이유가 아니다. 실제 caller가 exact Job list에서 HANDLE을 취득·보유하고 Job 밖 프로세스 및 민감한 argv/env/content를 수집하지 않음을 증명해야 한다.

현재 seam은 독립 실행기·bounded 외부 전송에 연결되지 않았다. 256KiB 제한은 serialize 이후 검사이므로 외부 pipe·journal의 스트리밍 cap, 통신 실패/초과·원래 오류를 덮는 cleanup 오류, observer 중 종료와 worker/handle lifetime, kill-on-close·hard deadline 및 해당 Job만 drain하는 구현을 통합·검토해야 한다. 최초 오류 기록 전에 프로세스가 사라지거나 원문 전송이 실패하면 실패로 남긴다. 실제 Windows `QueryFullProcessImageNameW` 접근 권한, 반환 길이·WinError 및 정상/실패 결과는 비제품 소유 child에서 실측이 필요하다. 합성 통과를 실제 소유 Job 성공으로 기록하지 않는다.

다음 실제 진단은 기존 1회 실패를 Python 시험 시도 이력에 포함하고 별도 K 상한·잔여 횟수, 필요한 최소 case, 새 scratch 및 승인된 exact manifest/argv/hash·source/P03/index 보호와 owned cleanup을 구체화해 독립 재심한 뒤 한 번만 한다. 이는 반복 요청이나 사용자 추가 확인을 요구한다는 뜻이 아니라 기존 승인의 범위를 넘지 않는 실행 계약을 먼저 확정한다는 뜻이다. 현재 초안만으로 재실행하거나 allowlist를 확대하지 않는다. 사용자·타 세션 프로세스는 건드리지 않는다. 비제품 진단은 K6이 아니며 제품 최초 import/검증 spawn 시 마지막 K6이 소진된다. GUI provenance와 실제 Godot Job 적합성은 별도 미해결이다.
