# P10b 검증 근거 (2026-10-16)

- 구현 커밋: c471ee2be6c4851df3927ddbc0c87937118e5560. 기준선: 2a77229, archive 696파일 SHA-256 대조 일치.
- 최종 시험은 final-suite.json을 따른다. organization_rules는 보강 후 단독 재실행으로 대체했다. 19종 PASS/OK·종료0, boundary는 전후 같은3건·신규0. suite.json은 처음20종의 원자료이며 final-suite가 보강 재시험을 반영한다.
- ai-before/after.json: 표준 auto, seed0~3, none/attack 각4판. ai-comparison.json은 시드별 지문·승패·길이·종료 대조다. n4로 승률 결론을 내리지 않는다.
- m2-probe.json은 최종 프로필 고정, RECON 예약 입력 off/on·다른15함대 동일·정책2×seed4×각120초. m2_probe.gd.txt는 실행 소스 보존본이다. 1초 관측 시각과 정확한 최초 탐지 틱을 구분한다.
- platform-results.json의 Android authorized export0·PC 캡처2종0을 따른다. APK는 대용량 바이너리라 여기 복사하지 않았고 apk-integrity.json에 위치·크기·SHA-256을 기록했다. export 최초 sandbox 실패와 후속 승인 성공을 구분한다.
- PC 이미지는 실제 장면의 시작 직후 편성·레이더 렌더 증거다. pc-recon의 시계는00:00이며 헤드리스1초 관측과 동일 조건이라고 주장하지 않는다. PC 자동 캡처는 태블릿 실기기 확인을 대체하지 않는다.
- 전체 원문 로그와 실행 스크립트는 구현 worktree의 output/p10b/ 아래 보존한다. APK 서명 도구의 전체 로그는 여기 복사하지 않는다. 최종 판정은 ../../REVIEW-P10b.md.

최초 Android 실패 stderr의 복사본은 Git 공백 검사에 맞춰 줄 끝 공백만 정리했다. 수정하지 않은 원문은 output/p10b/final-20261016/android-export.err.log에 남아 있다.
