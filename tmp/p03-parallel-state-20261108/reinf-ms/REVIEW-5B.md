# 단일 증원 시각 조각 5b

판정: **PASS — 이 단일 제한 owner 거부 사례에 한함**. 독립 재실행은 하지 않았고 보존된 실행 기록과 runner, 입력을 대조했다.

- attempt-02의 기록상 본시험 실제 exit 0, 3개 명명 사례 및 45개 확인 통과, 강제 실패 실제 exit 1과 의도한 단일 실패 marker를 확인했다. stdout과 빈 stderr를 직접 읽었고 두 Job 기록은 active 0, timeout 없음이다.
- runner는 P에서 정수 `reinf_ms` -1→0의 정확한 한 경로 차이, 구조 검사 통과와 `unsupported_reinforcement`, 양성 복원 시 새 객체 연결, 실패 후 활성 객체·warm 캐시·packet·queue·events 보존 및 다음 틱의 수기 기대와 대조 owner 일치를 확인한다. 선언된 exact 비교는 Variant 및 container 메타데이터와 순서를 확인한다.
- 별도 SHA 계산으로 attempt-02 manifest와 별도 SHA가 일치하고, manifest·전후 입력 목록이 동일하며 현재 기록된 47개 파일의 SHA가 일치함을 확인했다. runner 보존 사본도 현재 동결본과 일치한다. HEAD 기록은 `fb660cea69207fd332e26128643007694910a253`이다.
- 전후 Git 상태 기록의 차이는 전용 폴더 항목 8개다. 이는 Git에 표시되지 않는 부수효과나 기존 dirty 파일의 바이트 불변을 입증하지 않는다.
- attempt-01은 실패했으며 다섯 불일치가 기록됐다. attempt-02의 typed 배열 보정과 재실행은 RESULT에 설명돼 있고, 첫 실패를 통과로 합산하지 않았다.

이 결과는 `reinf=false`와 시각 -1을 0으로 위조한 한 경우다. raw 증원, 다른 위조, 활성 서비스, 제품/P02, 전체 clock/RNG 및 원장 완전성을 증명하지 않는다. 기존 광역 런타임 계획 REJECT와 P03 NOT_READY는 유지한다.
