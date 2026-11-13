# 캠페인 통합 헤드리스 검증 기록 (2026-11-13)

Windows에서 Godot `4.7.2.stable.official.ed1daf0bf`로 실행한 세 묶음의 기록이다. 결과 시각은 한국 표준시다. 로그의 수정 시각과 통합 워크트리의 Git 리플로그를 대조해 실행 당시의 커밋을 추정했다. 로그에 커밋 SHA나 작업 트리 상태를 기록한 실행 매니페스트는 없다.

| 원본 실행 폴더 | 결과 로그 시각 | 추정 실행 기준 |
| --- | --- | --- |
| `campaign-main-compain-validation-20261113` | 14:53:22–14:54:28 | `7ce20fb786e3eab39651b7e642f8262047d2edfa` |
| `campaign-main-final-verification-20261113` | 15:07:08–15:07:30 | `57b809eec8b53e4db0e3a597864f6ce9aaef40db` |
| `campaign-main-final-verification-20261113-r2` | 15:10:08–15:10:18 | `08461239d09eb4b5f823feaf9e60d99440999301` |

`-r2` 추정 기준의 Git 트리 `6b66e1a4c92c026e4ee5e00476fe03ec30288876`는 캠페인 통합 시점 원격 `main` 커밋 `3a9d40a8af8faa51a65a8cdd3e5f5e7ffab47d8c`와 일치한다.

## 결과

| 검증 | 통합 후보 | 최종 확인 | 최종 확인 r2 |
| --- | --- | --- | --- |
| [P02 공개 호스트 C0 비교](../../../../../tests/first_operation_consumer_host.gd) | 19/19 | 19/19 | 19/19 |
| [P03 공개 저장 명령 커서](../../../../../tests/first_operation_public_cursor.gd) | 초기 21/21, 교체 25/25, 재열기 14/14 | — | — |
| [P04 공개 외부 저장 회귀](../../../../../tests/first_operation_public_external_save.gd) | 36/36 | 36/36 | 36/36 |
| [P05 진형 전환 연속 검사](../../../../../tests/p05_formation_transition.gd) | 214/214 | — | — |
| [P05 FleetRenderer 후보 이동](../../../../../tests/p05_formation_renderer.gd) | 26/26 | 26/26 | — |
| [첫 작전 TRACE](../../../../../tests/first_operation_trace.gd) | 활성 51/51 | 활성 51/51 | — |
| [O07 사건 참조](../../../../../tests/o07_event_reference.gd) | 정상 1건 수락, 잘못된 참조 3건 거부 | — | — |
| [그룹 진형](../../../../../tests/group_formation.gd) · [월드 연결](../../../../../tests/world_link.gd) | `GROUP_FORMATION_PASS`, `WORLD_LINK_PASS` | — | — |

- P05 연속 검사에는 원래 배치의 선체 겹침을 감지해 기각하는 대조군이 포함된다. FleetRenderer 시험에서 30/60/120Hz와 60Hz에서의 0.35초 갱신 공백은 양방향 5초 완료를 기록했다. 60Hz에서 5초 갱신 공백을 주면 39척은 6.283초, 21척은 5.667초에 완료됐다. 가속도 측정값은 관찰치이며 상한 판정은 남아 있다.
- 월드 연결 로그는 잘못된 난이도 입력과 월드 반환 거부 경로를 실행한 뒤 `WORLD_LINK_PASS`를 기록했다.
- 이 기록의 범위는 헤드리스 실행이다. Windows 1600×900 실제 입력, P04 Godot FileDialog 왕복, K6 15~18행 정식 비교의 근거는 [캠페인 적용 체크리스트](../../SESSION-REQUIREMENTS-CHECKLIST-20261031.md)에 연결한다.

## 원본 로그 SHA-256

| 실행 | 로그 | SHA-256 |
| --- | --- | --- |
| 통합 후보 | `p02.log` | `8264c0c42fbf57fa0bfe029066c6b7dbf8561ff2dbdc422d86eb7deb6102ac11` |
| 통합 후보 | `p03-seed.log` | `941a9bcf2ff2b2516fea9bfd70d0c4fdbeaca9e57f0585146fe43d0e656c309e` |
| 통합 후보 | `p03-rotate.log` | `cc29dab73e1ef9848490d91d259e7838552da3f68a956701fe16bfa0e97e0167` |
| 통합 후보 | `p03-reopen.log` | `fbd86c8ddcbf754626640520887d86f1043a1a20920f943dfdf9c696d8194a7e` |
| 세 실행 공통 | `p04.log` | `3318467c94e9f981bd145cb488ab429e3f8a238135319aa4370656eabb04725e` |
| 통합 후보 | `p05-transition.log` | `e086e833ed62e8210e55c65d6e1d9ab49fbca1c42ad8435d721d7aed053cf26e` |
| 통합 후보 · 최종 확인 | `p05-renderer.log` · `p05.log` | `a3b29b5d4984803959ce5856a82652220ceea73d4b01f6046446b3a4914c6f2b` |
| 통합 후보 | `trace.log` | `585f19d190d2f23fd85ab0a1368b0f76a92b12987fa871eeebb89a4c482917c7` |
| 통합 후보 | `o07-verify.log` | `31b2dde2530927c0797a7dca2d6f221b739c905eacef5207782f7dcc7702f2ce` |
| 통합 후보 | `group.log` | `4c4fbe7a5ad2a1d5c14708f2d8589953c2993fc66ef3d7adcba9a38bfb599cec` |
| 통합 후보 | `world.log` | `f81ff605648d09e577931b4418193c6f160aa981ccf5e0c026d3cd55a525fc2c` |
| 최종 확인 | `p02.log` | `2b2ead3b862532412c3c5237963536a443707c3a8217bfc9c99834a4ccb22b2f` |
| 최종 확인 | `trace.log` | `a7bf3a15e469055fdce1e6895b7caca09b1d4e83b08a8da007d14c0edcb60e2b` |
| 최종 확인 r2 | `p02.log` | `d0eab276f9d22dc88024ffe0992e62858fd8ba3fcab59f399590d16dbc739d69` |
