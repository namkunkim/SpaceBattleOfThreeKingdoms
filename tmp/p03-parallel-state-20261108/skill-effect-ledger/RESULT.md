# 적벽 기술 효과 원장 결과

동결한 적벽 JSON 하나와 생산 GDScript 93개를 읽었다. [효과 값·순서](attempt-01/effect-records.json)에 기술 19개, 최상위 효과 항목 33개, 고유 키 24개가 있다. 별도 하위 경로는 4개다. [호출 후보](attempt-01/lexical-rows.json)는 31행·31개 접근 문자열이다. [정적 원장](TRACE.md)은 직접 모듈 접근 28개와 투영 Dictionary 접근 3개, 생성·슬롯·UI/AI 진입·만료·사건·지문을 구분한다. 설명 문자열 note는 소비 근거 미발견으로 UNCLASSIFIED다.

| 사례 | 실제 exit | 관측 |
|---|---:|---|
| normal | 0 | 값·타입·순서와 경로/행 집합 차이 0 |
| effect_omission | 1 | SK-U-GUANYU/assault_bp 1개 누락, 나머지 차이 0 |
| caller_omission | 1 | core/battle/detection.gd:94 1행 누락, 나머지 차이 0 |
| missing_input | 2 | absent.json 입력 오류, 비교 결과 미발행 |

[실제 suite](attempt-01/suite.json) exit 0, 4/4 일치. 원본 복제 JSON은 구조적 변이 하나를 적용한 뒤 직렬화해 들여쓰기가 달라졌으며 전체 바이트 일치 비교는 하지 않았다. 호출 누락 후보는 탐지 소스 자체 대신 원문의 일치 행 목록 사본에서 한 행을 제거했다. 각 자식 stdout/stderr와 argv/exit를 전용 attempt-01에 보존했다.

동결 manifest SHA256 248ded1f7c15b49fd3bae8a3199a76403c183595eafbb9fcf70167a46a83113f. 동결 입력 103개와 HEAD fb660cea69207fd332e26128643007694910a253가 전후 일치했다. [Git 상태 비교](attempt-01/git-comparison.json)의 전용 경로 변화 12행과 동시 P02의 gate-k4 임시 경로 3행을 분리했다. 상태 출력의 비교는 전체 dirty 파일 바이트 감사와 별개다.

고정 소스의 읽기 검증이다. 반사 호출, 범위 밖 호스트/앱, 실제 런타임 경로, 활성 SkillCore 복원, 모든 P03 상태의 완전성은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. 독립 사후 5b 대기.
