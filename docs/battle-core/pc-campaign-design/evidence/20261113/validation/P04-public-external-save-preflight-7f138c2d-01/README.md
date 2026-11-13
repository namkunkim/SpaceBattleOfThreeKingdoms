# P04 공개 외부 저장 인수 준비

기준 커밋은 `7f138c2df7f1a55118bf9a5b7e251703049d5bb6`이다. [세션 체크리스트 19행](../../../../SESSION-REQUIREMENTS-CHECKLIST-20261031.md)의 공개 외부 저장이 대상이다. 이 기록은 코드 근거와 향후 판정 조건을 동결한다. 공개 인수 실적은 미부여다. 차단된 기존 다중 호스트 시험은 체크리스트 지시에 따라 재실행 금지다.

## 기준선에서 확인한 경로

- 공개 진입은 준비 완료 화면의 출격에서 제품 작전을 선택한다. Windows 제품 내부 저장은 `user://pc-first-operation-product-v1.save`를 사용하고, 이어하기는 제품 결산 원장에서 이미 결산한 작전 ID를 거부한다. [공개 진입 62–69행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/entry/entry_boot.gd#L62-L69) · [제품 내부 저장 69–88행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L69-L88)
- 공개 제품 전투는 외부 가져오기·내보내기 버튼을 비활성화한다. 개발 전투는 Godot 내장 파일 선택기를 열고, 외부 코덱은 `pc/first-operation-dev/1` 요청만 허용한다. 기존 외부 v1 계약의 지원 범위는 같은 승인 규칙·입력·엔진의 Windows E 개발 전투다. [호스트 171–174행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L171-L174) · [호스트 224–228행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L224-L228) · [선택기 463–475행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L463-L475) · [개발 코덱 13–20행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_external_save.gd#L13-L20) · [외부 v1 계약](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/docs/battle-core/pc-campaign-design/FIRST-OPERATION-EXTERNAL-SAVE-V1.md)
- 제품 체크포인트 복원은 기존 Adapter에 있다. 호스트의 공용 복원 함수는 패킷 capability로 대상 작전을 선택하므로, 공개 외부 가져오기를 연결할 때 현재 공개 호스트와 파일의 권한 일치 및 이미 결산한 ID 거부를 후보 게시 전에 적용해야 한다. [Adapter 85–95행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_adapter.gd#L85-L95) · [호스트 120–132행](https://github.com/namkunkim/SpaceBattleOfThreeKingdoms/blob/7f138c2df7f1a55118bf9a5b7e251703049d5bb6/scripts/first_operation_host.gd#L120-L132)

## 재개 조건

제품 담당이 공개 외부 저장의 대상 Windows 빌드, 승인 작전·권한 지문, 외부 파일 버전 및 개발 파일 호환 정책을 결정한다. 그 계약이 적용된 후보에서 공개 호스트의 두 버튼과 코덱이 연결되고, 가져오기에서 제품 권한·결산 검사 후 기존 복원 Adapter로 들어가는 것을 독립 검토한다. 계약과 구현이 확인되면 아래 자료를 동결하고 실제 입력 인수로 이어간다. 배포 PCK·다른 플랫폼은 기존 문서에서 O07에 배정되어 있다.

## 향후 인수 자료와 판정

Windows 1600×900에서 후보 커밋, 실행 빌드·엔진 해시와 격리 프로필을 기록한다. 일반 공개 출격으로 시작한다. 격리 프로필에 제품 내부 슬롯과 결산 원장의 현재·이전 세대를 준비한다. 공개 계약 적용 후 제품에서 만든 정상 진행 파일을 사용하며, 적용 명령·대기 명령·이벤트 커서가 있는 틱을 선택한다. 같은 형식에서 무결성 검사를 통과하되 복원 권한 검증에서 거부되는 파일, 결산 원장에 이미 기록된 작전 ID의 파일, 내보내기 실패를 유도할 격리 목적지도 준비한다. 구체적인 파일 구조와 오류 값은 확정된 계약에서 정한다.

| 실제 Windows 입력 | 합격 판정 |
| --- | --- |
| 공개 전투에서 가져오기·내보내기 선택기 열기와 취소 | 공개 전투의 버튼으로 해당 열기·저장 모드와 확장자 필터를 확인한다. 실제 마우스·키보드로 취소하고 전투 조작이 복구된다. |
| 내보내기 실패 후 같은 호스트에서 정상 재시도 | 선택기가 경로를 넘긴 뒤 제품 쓰기 실패가 표시된다. 예를 들어 선택기가 허용하는 경우 파일 쓰기를 거부하는 격리 목적지를 사용한다. 기존 파일과 네 보호 파일을 보존하고 잔류 임시 파일이 없다. 동일 목적지의 실패 원인만 해소한 뒤 정상 파일 하나가 만들어지며, 파일 무결성과 원본 체크포인트가 일치한다. |
| 잘못된 파일 가져오기 또는 복원 취소 후 정상 파일 재시도 | 권한 불일치 또는 취소에서 후보가 게시되지 않는다. 정상 파일 재시도는 같은 작전 ID·틱·커서의 후보를 한 번 게시하고 이어하기로 돌아온다. 이후 대기 명령이 한 번 적용되며 이미 소비한 이벤트는 재발행되지 않는다. |
| 이미 결산한 작전 가져오기 | 공개 호스트가 후보 게시 전에 거부한다. 결산 재지급이나 원장 항목 중복 없이 네 보호 파일이 유지된다. |

취소·실패는 owner·프레임·논리 틱·대기 명령·이벤트 커서와 조작 상태를 전후 비교한다. 동작 중 자연 진행은 선택기와 복원 작업이 정지시킨 구간의 증거로 구분한다. 각 단계에서 제품 슬롯 및 제품 결산 원장의 현재·이전 세대의 SHA-256과 존재 여부, 외부 파일 및 임시 파일 목록을 비교한다. 성공한 외부 가져오기·내보내기도 같은 네 보호 파일을 보존해야 한다. 화면 녹화 또는 캡처, 입력 기록, 원시 로그와 해시를 한 인계로 묶는다.

## 동결한 기존 증거

- 개발 내보내기 23/23. 개발 호스트의 내장 선택기를 열고 합성 선택 신호를 보냈다. 쓰기 실패와 동일 경로 재시도에서 개발 슬롯·결산 원장 세대를 보호했다. [결과](../P04-external-export-failure-7f138c2d-01/RESULTS.md) · [인계](../P04-external-export-failure-7f138c2d-01/REVIEW-HANDOFF.json)
- 개발 가져오기 25/25. 유효 입력 지문 불일치와 같은 개발 호스트 재시도에 대한 격리 검증이며 인계에 `public_credit: false`로 기록되어 있다. [결과](../P04-external-effective-authority-b2ba73ff-01/RESULTS.md) · [인계](../P04-external-effective-authority-b2ba73ff-01/REVIEW-HANDOFF.json)
- 기존 상세 기록도 공개 제품 가져오기·실제 파일 선택기 입력과 독립 두 번째 호스트의 무게시 복귀·원장 및 슬롯 보존을 열린 항목으로 둔다. 이 준비에서 실제 UI, 다중 호스트 또는 사용자 저장을 사용하지 않았다. [상세 기록 247행](../../../../P02-PROGRESS-CHECKLIST.md)

| 증거 파일 | SHA-256 |
| --- | --- |
| 세션 체크리스트 | `42547de3243ffa39536b8bc780b322c03a8bd8b04d1e3d7442754c09eb06206e` |
| 개발 내보내기 결과 | `57fa3a7d0d3f99d6a4beb6c7926e18cf75dba44fd5472a4528f92111a90f22fc` |
| 개발 내보내기 인계 | `f11c442be7131b4b273821c5dc9dd98bce746e875a81dcd46176150718dae0bc` |
| 개발 가져오기 결과 | `f6207aae28b6a244ed907d36dfc83327eaee1414fab91a0ad274cb6764a1baf7` |
| 개발 가져오기 인계 | `6be1af0b6ac7d0704b5c83a5a5c8600b1550ccd7d7bb8b15c1b9ad7ff4ffd8a5` |
