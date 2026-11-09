# D02 Variant 타입 단일 진단

별도 독립 승인은 scope type-proof-d02-only와 이 매니페스트의 정확한 SHA를 요구한다. 새 attempt-01에 총 두 headless 프로세스만 시작한다. before import 제한 240초와 기대 종료 0, before D02 제한 120초와 진단 기대 종료 1이다. Job root 및 자식 정리를 확인한다.

진단 D02는 기존 12개 단언을 그대로 수행한다. raw와 sentinel은 roster.full과 roster.wait만 거짓이어야 한다. 예상 종료 1은 타입 가설에 대한 진단 결과로만 분류한다. 양측 원시 피연산자의 ID, 진영, 대기, 시작 사기는 독립 JSON에 배열 순서까지 일치해야 하며 actual 대기·사기는 int, expected 대기·사기는 float, 문자열 필드는 양측 String이어야 한다. 구문 오류나 raw, 타입, 종료, sentinel, 경고·오류 진단 불일치가 있으면 중단한다.

기존 focused-01 실행은 소진됐으며 D02는 실패로 보존한다. 기존 예상 기준선 적색 정책은 유지한다. 이번 진단은 타입이 관측되더라도 원래 D02 또는 후보를 통과로 판정하지 않는다. 정규화 프로브는 실행 대상이 아니다.

가용 2.90 GB를 시작 직전에 확인하고, 진행 중 1.50 GB 미만이면 Job을 중단한다. 프로젝트·기존 attempt/cache는 수정 또는 삭제하지 않는다. Windows GUI는 미검증, PC0 재실행 0이다.
