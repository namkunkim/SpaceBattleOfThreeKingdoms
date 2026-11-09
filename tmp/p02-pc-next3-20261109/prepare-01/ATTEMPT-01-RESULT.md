# 독립 승인 실행 1차 결과

판정은 준비된 프로브의 파서 오류로 중단이다. 승인된 28개 프로세스 중 2개를 시작했다.

| 행 | Job root PID | 엔진 종료 | 정리 잔여 | 판정 |
|---|---:|---:|---:|---|
| before import | 37220 | 0 | 0 | 감독기 및 runner 통과 |
| before D01 | 23300 | 1 | 0 | GDScript 파서 오류. 예상 baseline red로 인정하지 않음 |

D01 엔진은 p02_difficulty_probe.gd 441행에서 Variant 식에 대한 var ok := 타입 추론을 거부했다. 헤드리스 프로브의 전체 파일이 컴파일되므로 물리 관측 함수도 파싱 대상이었다. raw.json 및 P02_DIFFICULTY_DONE 표지는 생성되지 않았다. 다음 후보 준비 시 명시 bool 선언 또는 관측 스크립트 분리를 독립 검토한다.

before D02–D13, after import 및 after D01–D13은 시작하지 않았다. 물리 Windows 행 및 OS 입력은 0건이다. PC0 2/2는 기존 결과다. 제품 원본, index와 프로젝트 설정 SHA는 실행 전후 동일했다. 새 격리 캐시는 보존했고 recycle 단계는 실행하지 않았다. 정지 직후 가용 공간 2,246,172,672 B는 승인 시작 기준 2.90 GB 미만이었다.

감독 원문은 attempt-01/before/{import,D01}/engine.os.tsv와 engine.log에 있다. 실행 승인 SHA 8c7d1012f2fa1ffd3e8b08197df676299300f77d89ab1040dbe6499ca3d01a9d. 독립 재승인 없이 추가 실행은 하지 않았다.
