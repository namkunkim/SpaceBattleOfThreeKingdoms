# 호스트 최종 시도 계획 개정 독립 심사 — GPT-6 Sol

판정: **조건부 수용**. `PLAN-AMENDMENT-ATTEMPT-06.md` SHA-256 `2bb8508b6677e2bb82a7875412b125bc2988964819a505ff9a4c627ae1faf45d` 기준이다. 기존 2회와 개정 시도 03~05를 포함해 K6 중 5회를 사용했다. 03~05의 자체 4개 단언 및 actual exit 0을 최종 PASS로 승격하지 않는다. 03의 Job active 1은 당시 gate의 즉시 accounting 값이며, 04·05는 최대 5초 관측 후 active 0이다. 04·05의 verbose 로그는 `stars_stripes.ogg` Ogg 객체 4개·resource 2개의 종료 누수를 확인한다.

실행 직전 개정 확인: 계획 문서에 정확한 두 캐시 파일명과 `approved-source-copy-differences.json` 및 ResourceLoader 부재 guard가 추가됐다. 최종 SHA-256은 `8107787dfb19b23acf32e8e005b8444300e698de4bfb12ee1ade93582c57bbe5`다. 아래 조건과 결론 범위는 그대로다.

마지막 06에서 선택적 BGM 파일 `assets/audio/music/stars_stripes.ogg`와 그 `.import`, 해당 import 캐시만 **격리 사본**에서 생략하는 범위는 수용한다. `hud/ui_kit/ui_sound.gd`가 음악 자산에 `ResourceLoader.exists(path)`를 적용하므로 자산 부재 분기는 원문에 있다. 실행 전 계획 개정과 실제 복사 차집합을 보존하고, 제외 파일은 원본 동결·전후 해시 대상에 남겨야 한다. 격리 사본의 두 파일과 대응 import 캐시 부재를 명시적으로 검사하고, 그 외 정본 소스 및 의존 파일은 바이트와 canonical resource_path를 유지해야 한다.

네 이름의 동일 초기 상태·실제 첫 프레임·실패 보존과 다음 프레임·정리 단언, actual exit 0, 예상 `invalid_candidate_profile at profile.ally` 정확히 두 건, 기타 진단·누수 0, Job active 0, 입력 및 격리 사본 해시 안정성 기준을 유지한다. 마지막 시도가 실패하면 K6 소진으로 멈춘다. 성공 시에도 결론은 **선택적 BGM이 없는 격리 호스트**의 clock/게시 경계에 한정하며 완전한 자산 환경의 깨끗한 종료와 음향 경로는 미검증이다. 구현과 최종 5b는 별도다.
