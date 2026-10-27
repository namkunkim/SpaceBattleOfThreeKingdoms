# I01a 구현 결과 — 2026-10-27

현재 판정은 **I01a 전용 runner PASS / 기존 data_rules FAIL / 독립 5-b 조건부 수용**이다. 두 검사가 모두 통과했다고 판정하지 않는다. 원 I01과 I01b, 원 A04/A05/A06는 NOT_READY다.

## 승인·역할·범위

사용자의 최신 지시 **“내 컨펌 없어도 계속 진행”**은 합의된 범위의 구현·검증·수정을 단계별 추가 확인 대기 없이 진행하라는 뜻으로 기록한다. 커밋·병합·푸시, 기존 공유 코드 수정, 실제 host/runtime/save 연결까지 범위를 자동 확대하지 않는다. [선택 기록](I01A-DECISION-20261026.md)과 [플레이북](../../../워크플로우-플레이북.md)을 따른다.

기준은 로컬 `93e60e6a957ffdb002a1cb06bc796c4c46496736`, 작업트리는 `C:/Users/nk782/.codex/worktrees/i01a-operation-config/SpaceBattleOfThreeKingdoms`다. 최신 원격 상태를 확인했다는 뜻은 아니다. 구현 인계 후 코드 보강·기록 실행자는 `i01a_delivery`, 작성 비참여 독립 심판은 `i01a_review`, 실제 권한 승인에 따른 배치·Godot 기계 gate 및 최종 변경 감사는 부모 조율자가 수행했다. 이 문서 작성자는 독립 수용 판정을 대신 내리지 않는다.

순수 Dictionary 검증·깊은 복제·변환·manifest 및 고정 FX-G fixture만 구현했다. host/headless/replay는 입력 envelope 형식 비교이며 실제 어댑터 통합이 아니다. 설정 seed/hz/clock/cursor metadata는 실제 C0 runtime이나 논리시계 재생 검증이 아니다.

## 정확한 신규 4파일

아래 SHA-256와 바이트는 최종 target 파일을 읽어 staging manifest와 일치함을 확인했다.

| 경로 | SHA-256 | bytes |
|---|---|---:|
| core/battle/operation_profile.gd | 4963f178877f3657a6def8580ed2deaf2f612960e1198c2ee04e7a7309722f0e | 15669 |
| tests/i01_operation_config.gd | daf611b6568b20f76bd9784f34b2eddb767251a6f02df43507b289cc3cd4cdd4 | 9176 |
| tests/fixtures/i01/valid_definition.json | 15c8849e51b0f81f3d6103c04a5e7c9a6cc62593fcf56bf01ed9dc4d064dbe17 | 2529 |
| tests/fixtures/i01/invalid_definitions.json | ce434ffbba64137e33de05e7df343c8bac100bb8943dc6cd4629b40e03120cda | 750 |

staging은 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01a-stage-20261027-implementation-spec`다. [manifest](../evidence/i01a-20261027/manifest.json), [최종 변경 감사](../evidence/i01a-20261027/final-change-audit.json)에 따르면 tracked 변경은 없고 untracked는 위 4파일이다. import로 생긴 `.uid`/`.import` 44개는 해시를 기록해 staging의 `generated-metadata-backup-2e8641a264014c24bf47a61c8f9ec506`에 보존한 뒤 target 변경 목록에서 정리됐다. 정리 목록 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01a-stage-20261027-implementation-spec/metadata-cleanup.json`, import 직후 감사 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01a-stage-20261027-implementation-spec/post-import-audit.json`를 함께 보존한다. metadata probe 원문 일치는 최종 감사에 true로 기록됐다.

## 실제 5-a 결과

engine은 `C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe`, 실제 버전 표식은 `4.7.2.stable.official.ed1daf0bf`다. 부모 gate에서 headless editor import 종료 0 및 runner 파싱 성공을 확인했다. import 성공은 게임 기능 검증이 아니다.

| 검사 | 실제 결과 | 근거 |
|---|---|---|
| tests/i01_operation_config.gd | exit 0, PASS a01~a06 | 설정 구축 60, 명명 거부 24, 추가 반례 17, CHECKS=326 |
| tests/data_rules.gd | exit 1, TEST_FAIL | 기존 battle_sim.gd:1019의 170.0 규칙 리터럴 |

[I01a 최종 실행 로그](../evidence/i01a-20261027/i01a-run-3.log)는 `I01A_OPERATION_CONFIG_PASS a01 a02 a03 a04 a05 a06` 및 `ORIGINAL_I01_A04_A05_A06=NOT_READY; no host/runtime/save/gameplay validation`을 출력한다. [data_rules 로그](../evidence/i01a-20261027/i01a-data-rules-3.log)의 지목 줄은 `chase_r = maxf(chase_r, float(rs.rt("range_band_hold.engagement_distance", 170.0)))`다. 이 기존 파일은 허용 목록 밖이므로 수정하지 않았다. 해당 코드가 최종 신규 변경에 포함되지 않았다는 정적 사실과 별개로, 별도 baseline 실행은 하지 않았으므로 전후 실행에서 같은 실패가 재현됐다고 주장하지 않는다. 이 리터럴의 후속 수정·재검사는 미수행이다.

첫 기계 gate는 파싱 후 유효 입력 거부로 실패했고, 두 번째 진단 실행에서 `NONFINITE_EFFECTIVE_VALUE`를 확인했다. 새 Dictionary 키를 dot 문법으로 넣을 때 생기는 StringName 키가 String 전용 JSON 검증에 걸린 것이 원인이었다. 문자열 bracket 키 삽입으로 수정한 세 번째 실행이 위 PASS다. 유한성 검사나 거부 oracle는 제거하지 않았다. 진단 로그 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01a-stage-20261027-implementation-spec/i01a-run-2.log`를 보존한다. 코드 재시도 상한 K=6 안에서 진행했다.

## 실패 패턴과 다음 경계

- 긴 apply_patch 호출이 중단돼 저장 증거가 남지 않았다. 이후에는 작은 PowerShell UTF-8 무 BOM 치환으로 저장하고 각 호출에서 해시를 확인했다.
- 자식 실행자의 target 쓰기 권한 대기가 길어졌다. 승인된 staging artifact와 manifest를 먼저 완성하고, 부모의 정식 한정 copy·기계 gate로 배치했다. 권한을 우회하지 않았다.
- JSON 원본 String 키와 새 StringName 키의 차이가 유한성 오류로 보였다. 새 키는 문자열 bracket 삽입으로 유지하고, 실제 errors 진단으로 원인을 좁혔다.
- 유한 입력의 곱셈 overflow, 중첩 미지원 키·효과, envelope 내부 adapter, 반복별 legacy/operation 순서, 서비스 교집합 음성례를 같은 builder/runner 안에서 보강했다. 추가 반례 17개는 기존 60/24 지표와 분리했다.

[독립 5-b 검토](REVIEW-I01A-IMPLEMENTATION-20261027.md)는 신규 4파일에 잔여 반려 없이 **조건부 수용**했다. target/HEAD 코드·검사 blob 대조로 기존 170.0 실패 원인이 기준선에도 있음을 확인했으나 변경 전 baseline 실행을 뜻하지 않는다. data_rules는 첫 리터럴 검사 실패 후 반환하므로 후속 프로필 키·편성·시뮬레이션 검사는 미실행이다. 승인된 두 검사 전체 gate는 아직 미통과다. 실제 BattleSim/OperationState 생성·C0/운영 snapshot·저장/suffix·제품 통행·정지/배속/재생·실게임·성능·플랫폼 회귀는 미검증이다. I01b와 원 A04/A05/A06의 공간·논리시계·지속 상태 게이트를 그대로 남긴다. 신규 지형/공유 경로 미활성 범위의 Q67 비적용 근거는 별도 최종 판정 대상이며, I01b에서 활성화할 때 다시 검토한다. 커밋·병합·푸시는 수행하지 않았다.

## 릴리스 준비 승인 — 2026-10-27

사용자가 **"커밋 푸시 합니다."**라고 명시 승인했다. 이번 과제 코드·설계/결정/검토 문서와 사용자 제공 절차 원본을 한정하여 커밋하고, 작업 브랜치 코드를 main에 병합한 뒤 main을 푸시할 예정이다. 최종 로그 2개와 manifest·변경 감사는 `docs/battle-core/evidence/i01a-20261027/`에 원본 바이트 그대로 보존했다. 위 검사 결과와 I01b 미완료 경계는 유지하며, 실제 커밋·푸시 완료 여부와 커밋 해시는 후속 Git 증거로 기록한다.