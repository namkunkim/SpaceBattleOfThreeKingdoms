# I01a 구현 독립 검토

2026-10-27 / i01a_review / **조건부 수용: 신규 설정 코드 수용, 승인된 두 검사 전체 gate는 미통과.**

검토자는 구현4파일 작성·수정에 참여하지 않았다. [플레이북](../../../워크플로우-플레이북.md), [승인 기록](I01A-DECISION-20261026.md), [I01a 계약 §7.1](I01-READINESS-DECISION-20261026.md), [인수 사전등록](I01-ACCEPTANCE-PREREG-20261026.md), [준비 독립 검토](REVIEW-I01-READINESS-20261026.md)를 기준으로 target/staging 코드·fixture·manifest·실제 로그를 직접 대조했다. 실행 전 preflight는 실제 5b PASS로 간주하지 않았다.

## 대상·무결성

대상은 detached 관리 작업트리 `C:/Users/nk782/.codex/worktrees/i01a-operation-config/SpaceBattleOfThreeKingdoms`, 로컬 HEAD `93e60e6a957ffdb002a1cb06bc796c4c46496736`의 승인된 신규4파일이다. 원격 최신성은 확인하지 않았다. 아래 SHA-256은 검토자가 target/staging/manifest 일치를 직접 확인했다.

| 파일 | SHA-256 |
|---|---|
| core/battle/operation_profile.gd | 4963f178877f3657a6def8580ed2deaf2f612960e1198c2ee04e7a7309722f0e |
| tests/i01_operation_config.gd | daf611b6568b20f76bd9784f34b2eddb767251a6f02df43507b289cc3cd4cdd4 |
| tests/fixtures/i01/valid_definition.json | 15c8849e51b0f81f3d6103c04a5e7c9a6cc62593fcf56bf01ed9dc4d064dbe17 |
| tests/fixtures/i01/invalid_definitions.json | ce434ffbba64137e33de05e7df343c8bac100bb8943dc6cd4629b40e03120cda |

검토자 직접 Git status/diff는 sandbox 오류로 완료하지 못했다. 이후 조율자의 정식 감사 산출물 [최종 변경 감사](../evidence/i01a-20261027/final-change-audit.json)을 직접 읽어 tracked 변경0·정확 신규4파일만 남은 결과를 확인했다. Godot 생성 metadata44개는 파일별 SHA-256·백업 경로가 있는 `metadata-cleanup.json`과 별도 백업에 보존한 뒤 조율자가 정리했다. metadata probe의 raw HEAD 일치도 true다. 이 절차는 기존 코드 수정이나 외부 dirty 채택을 포함하지 않는다.

## 실제 검사와 남은 실패

Godot `v4.7.2.stable.official.ed1daf0bf`의 보존 로그 [I01a 최종 로그](../evidence/i01a-20261027/i01a-run-3.log), [data_rules 로그](../evidence/i01a-20261027/i01a-data-rules-3.log)를 검토자가 직접 읽었고 종료코드는 조율자의 기계 gate 출력으로 전달받았다. 검토자가 추가 Godot/GUI/게임 검사를 실행하지는 않았다.

- I01a config: 종료코드0, `I01A_OPERATION_CONFIG_PASS a01 a02 a03 a04 a05 a06`, 설정60·명명거부24·추가회귀17·CHECKS326.
- 기존 data_rules: 종료코드1, `battle_sim.gd:1019`의 `range_band_hold.engagement_distance` 기본값 `170.0`이 숫자 리터럴 스캔에 걸렸다. 전체 core 스캔의 보고 항목은 이 기존 한 건이며 신규 module의 위반은 보고되지 않았다.
- 앞선 config 실행 두 번의 종료코드1 이력은 보존한다. 단순 60/24/17 횟수는 PASS 증거로 쓰지 않는다.

검토자가 target 파일과 HEAD Git blob을 직접 비교했다. battle_sim은 둘 다 `3995e13d706603ff2a26c7a68bbc1ef6da0eb20f`, data_rules는 둘 다 `0f516fdfdbd13770b061b8cdb539a5886403dc84`, TestCheck는 둘 다 `5fe2428b7927779a76edc51ba5495d2e066a7ce2`다. HEAD 원문에도 동일 `170.0`이 존재한다. 따라서 이번 실패 원인은 기준선에 이미 존재하는 동일 코드/검사로 설명된다. 변경 전 baseline을 실제 실행했다는 주장은 하지 않는다.

data_rules는 전체 core 리터럴 검사 후 실패 시 즉시 반환하므로 그 뒤 프로필 키·편성·시뮬레이션 검사는 **미실행/미검증**이다. 신규 코드를 잠시 제거해 알려진 동일 실패를 반복할 실질 필요는 발견하지 못했다. 기존 실패를 자동 면제하거나 기존 파일 수정 권한으로 해석하지 않는다. 두 검사 모두 종료코드0이라는 완료 조건은 아직 충족하지 않았다.

## 코드와 oracle 대조

- a01: 공개 POC/적벽 profile 결과와 legacy wrapper의 canonical 동일성·깊은 복제를 비교하며 legacy→operation / operation→legacy 순서를 유지한다. 실제 호스트·게임 결과 회귀와 구분한다.
- a02: 버전·타입·유한 숫자·정수 seed 범위·hz10·ID/참조·미지원 기능을 검증한다. 8invalid×3입력은 기대 오류코드, effective=null, 원본불변을 함께 검사한다.
- a03: 원본 복제 후 등방2배 한 번. E=(100,600), C=(1600,600), 효과rect=[600,100,200,100], 서비스60→120, envelope20/5→40/10, 속도20·선회27·회피4·face-turn36이 동결 산술 oracle와 일치한다. effective 재입력은 거부하고 배열 순서는 보존한다.
- a04: 가짜 원형/장애물 없는 FX-G 자유중심 [50,50,1950,1150], 그래프 연결·서비스 교집합만 검사한다. E-J 단절, A-C 제거 후 A-B 우회 유지, 잘못된 중심·교집합 부재 음성례가 있다. 실제 최대진형 통행으로 승격하지 않는다.
- a05: seed10×envelope3×fresh2의 effective hash와 초기 clock/명령 cursor metadata를 비교한다. host/replay는 입력 형식 이름이며 실제 adapter 연결은 없다.
- a06: builder에 runtime 생성·save·파일쓰기·네트워크 호출이 없고 runner는 fixture/소스 읽기 및 자식 노드 수 불변을 검사한다. manifest/출력은 원 I01 NOT_READY와 host_activation=false를 유지한다.

초기 정적 발견인 변환 후 overflow·중첩 unknown key 통과, 내부 adapter 삭제, legacy 순서/서비스 음성례 누락은 실행자가 동일4파일에서 보강했다. 추가17항은 nested suffix7, 곱셈/나눗셈/scale overflow5, 내부 adapter2, request/root suffix2, 서비스 음성1로 명명24거부와 별도 표기된다. 변환 후 effective 전체 유한성·scale 양수·반경/rect 크기를 재검증한다.

실기계에서 드러난 dot 삽입 StringName key 문제는 새 key를 명시 String bracket으로 생성해 해결했다. 최종본은 유한성/지원키 검사를 유지하며 임의 타입 허용이나 기대 oracle 약화로 통과시키지 않았다. 최종 신규4파일 안에 추가 실질 반려사항은 발견하지 못했다.

## 최종 판단·후속 제약

**설정/fixture 코드 검토는 조건부 수용한다. 전체 5-a gate는 data_rules 기존 실패 때문에 미통과다.** 남은 정확한 차단은 기존 `170.0` 리터럴 실패와 그 때문에 실행되지 않은 data_rules 후속 항목이다. 조율자가 별도 범위에서 처리해야 하며 본 리뷰가 기존 battle_sim/test 수정·커밋·병합·푸시 승인은 아니다.

원 전체 I01/I01b 및 원 A04/A05/A06의 실제 공간·논리시계·운영 snapshot/save/suffix·게임 회귀는 NOT_READY/미검증 그대로다. 설정60/추가17은 승률·완주·성능·사람 표본 또는 원 게이트의 대체가 아니다. Q67은 이번 미연결 신규4파일 범위에서 신규 지형/공유 실행경로 활성화가 없다는 비적용 근거만 있으며 후속 본체 연결 시 적용 판단과 해당 B항/1000seed 게이트는 보존한다. 검토자는 이 리뷰 문서만 작성했다.
