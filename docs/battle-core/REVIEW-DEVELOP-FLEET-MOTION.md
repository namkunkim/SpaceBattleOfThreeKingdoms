# develop 기동·지형 이식 독립 5-b 리뷰

- 날짜: 2026-10-17
- 대상: `worktrees/develop-fleet-motion`, `develop`의 기동·지형 선별 이식
- 구현: gpt-6.1-sol / 독립 리뷰: gpt-6-astra
- 최종 판정: **PC 범위 수용 — 차단 수정 요구 0건**. K3 영향 회귀와 PC 화면 증거까지 확인했다. develop 선별 커밋·푸시의 5-b 조건을 충족하며, 최종 변경 소유/원격 확인은 Git 담당 절차로 남는다. main 병합은 사용자 거부 상태다. 아래 대기/반려 항목은 당시 기록이며 마지막 최종 판정이 우선한다.

## 기준과 범위

`PLAN-DEVELOP-FLEET-MOTION.md`, `PLAN-REFERENCE-MOTION-ONLY.md`와 BATTLE_DECISIONS의 2026-10-15 최신 기동 결정에 따른다. 원본 K3의 후속 native 화면 검증은 완료되었으나 develop 이식본의 실행 증거를 대신하지 않는다. 원본 K3와 함수 수준으로 대조하며 develop의 기존 API·편성 표현을 보존하는 선별 이식을 검토했다.

## 정적 검토 결과

1. `fleet_renderer.gd`: 모든 생존 슬롯 yaw는 공유 함대 heading만 보간한다. 위치 복귀 벡터·피격·사격·시계가 yaw 목표를 바꾸지 않는다. rest 종료 조건에 yaw 오차를 포함한다. 이동 흔들림, 난수 높이, 격침 후 빈자리 연쇄 이동 경로를 제거했다. 기존 위치 추종·명시적 배치 변경 경로는 유지한다.
2. 제거된 로컬 난수 3회/슬롯은 엔진광 위상 전에 동일 횟수 소비하므로 외관 RNG 순서를 보존한다. 전투 RNG 호출이나 코어·시나리오 수정은 제품 diff에 없다.
3. `battle_view_model.gd`는 기존 공개 투영에 이미 존재하던 formation·route·strafe를 전달한다. 적 접촉은 기존 `_apply_contact` 경계를 유지한다. main의 실제 편성 함종 매핑·특기·정찰 코어를 이식하지 않았다.
4. `battle_source.gd`는 기존 세 종류의 공개 정적 지형만 선별한다. 효과 계산은 복제된 목록을 기존 BattleTerrain에 전달하므로 이동 max·센서 clamp·은폐 합·사격선 사거리 곱·각도 합을 재사용한다. 화공 임시 구역은 범례·지도·효과에서 제외한다. 사격선 끝점은 공개 FleetView를 사용한다.
5. 미니맵은 동일 확대 좌표의 지형·탈출점·아군 경유점을 사용하고, 카메라 바닥 투영 다각형을 전장 사각형으로 자른다. 적 경로는 `fleet_route`에서 차단한다. 지형 버튼·HoldTip 클릭 토글 및 기존 길게 누르기 경로를 검토했다.
6. 원본 K3의 진형 전환 시간 보간 및 실제 함종 편성은 develop에 없는 후속 기능이므로 가져오지 않았다. 기존 develop의 명시적 formation 변경 감지/위치 추종을 유지하는 선택은 이번 범위에 부합한다.

## 검증 대기

- import와 develop 일반 순차 테스트 전체 결과, boundary 기존 실패 대비 신규 여부.
- 복구 중인 `fleet_follow`, `reference_motion_only`, 교전 fixture 및 캡처 도구 최종 diff와 실행 증거.
- develop PC 기동·교전·지형·팝업 화면 증거. 최신 사용자 지시에 따라 Android/태블릿 검증은 이번 실행 및 완료 대기조건에서 제외한다.
- import sidecar 등 자동 생성 변경의 소유 정리와 최종 커밋 대상 목록.

최종 증거가 도착하면 이 문서에 실행 결과 및 판정을 추가한다. 현재 구체적인 제품 코드 수정 요구는 0건이다.

## 추가 증거: boundary 정적 기준선 대조

`out/develop-motion-20261017/boundary-comparison.json` 확인. develop 기준 커밋 `46e0533999ecf358012f5becd1f9b140d0e024db`와 현재 작업본을 `boundary.gd`의 동일 패턴·문자열 제거 규칙으로 대조한 결과 기존 위반 1건, 신규 0건이다. 기존 `view/fleet_render/battle_source.gd`의 `var bp := float(BattleRules.BP)`가 163행에서 219행으로 이동했으며 내용은 같다. 원본 main의 기존 3건 기준선을 이 develop 판정에 사용하지 않는다.

이는 소스 정적 대조 증거이며 Godot으로 실행한 boundary baseline 결과가 아니다. 실제 순차 게이트의 boundary 결과와 최종 검증은 계속 대기한다.


## 최종 도구 정적 검토와 PC 범위 정정

- 최신 사용자 지시 “테스트는 pc로만 합니다”와 갱신된 PLAN을 적용한다. Android 빌드·서명 및 태블릿 검증은 이번 5-b 대기조건이 아니다.
- 최종 `fleet_follow.gd`, `reference_motion_only.gd`, `lib/reference_motion_fixture.gd`, `capture_fleet_motion_terrain.gd`를 정적으로 검토했다. 새 차단 사항은 없다. 리뷰 과정에서 Godot을 별도 실행하지 않았다.
- 복구된 테스트는 삭제 API를 참조하지 않고, 생존 슬롯의 정체성·home·pos·yaw, VM 마지막 틱 보간, 실제 core stop/자연 도착을 검사한다. 프레임/배속 조합, 비어 있는 함대의 허위 통과 방지, 코어 지문 불변 검사를 유지한다.
- 실제 교전 fixture는 양쪽 core `fire_id`가 상대 함대를 가리킬 때만 활성으로 센다. fake 사전의 `under_fire` 키는 실제 VM 필드 접근이 아니다. 실제 검사 메시지의 `under_fire` 표현은 양방향 자동 사격으로 정정 권고하며, 검사 자체의 차단 결함은 아니다.
- PC 캡처는 실제 명령 수락·위치/방향 변화·생존·비교전 분리를 확인한다. 180도 선회는 최대 15초 안에 실제 코어 종료와 위치/yaw 정돈을 확인한다. 평행 후퇴는 기존 임계값을 유지한 채 제한된 추가 시간으로 수렴을 기다린다. 기존 develop 진형 표현에 없는 main의 시간 보간을 검사 조건으로 강요하지 않는다.
- `fleet_follow.log`와 `reference_motion_only.log`의 PASS를 직접 확인했다. 종료 시 resources 경고는 각각 19/17건이며 PASS와 별도로 기록한다. 최종 전체 게이트 상태는 아직 대기한다.

## boundary 실제 로그 대조

root `tmp/develop-boundary-baseline.engine.log`와 대상 worktree `out/develop-motion-20261017/logs/boundary.log`를 직접 읽었다. 두 로그 모두 동일한 `BattleRules.BP` 참조 1건만 보고하며 baseline 163행, 현재 219행이다. 정적 대조와 실행 로그가 일치하므로 기존 1건·신규 0건으로 판단한다. baseline 종료 코드 1은 담당자 보고이며 이 리뷰는 로그 내용을 직접 확인했다. 위 정적 증거만 존재하던 시점의 대기 기록은 이 추가 실행 증거로 보완된다.

## K1 PC 교전 실패와 K2 수정 기준

`out/develop-motion-20261017/combat-1600/stages.json`, `process.log`, `combat-12-seconds.png`를 직접 검토했다. 실패 12건, 양방향 사격 활성 228프레임, 생존 슬롯 위치/yaw drift 0이다. 마지막 기록은 11.95초에 fixture false·선택 0·오차 INF이며 화면에서도 유비 기함 생존 목표 실패와 선택 해제를 확인했다. 따라서 drift 0을 근거로 이 실행을 통과 처리할 수 없다. 실패 증거는 보존한다.

원인은 `ReferenceMotionFixture.prepare`의 손책 이름 우선 및 첫 아군 fallback이다. develop 시나리오에 손책이 없어 유비 기함이 선택되어 12초 시험의 양측 생존·전투 비종료 전제를 깨뜨렸다. 기존 develop의 비기함 전열 함대를 명시적으로 선택하는 K2 도구 수정은 스펙을 유지하는 fixture 교정으로 타당하다. 실제 함대 선택·검증 외에 코어·편성·피해·난이도·기동 수치, 12초 시간, 생존 조건 및 drift 허용치를 바꾸면 안 된다.

수정 후 선택 함대와 초기/최종 생존 슬롯을 기록한 새 PC 교전 캡처, 공용 fixture를 쓰는 `reference_motion_only` 재검증이 필요하다. 현재 최종 수용 불가이며 전체 게이트 및 수정 후 PC 교전 증거를 대기한다.

## PC 기동 화면 20장 및 일반 게이트 검토

`native-1600`과 `native-1280`의 01~10 PNG 총 20장을 리뷰어가 모두 직접 열어 확인했다. 직진, 공유 선회, 정지 정돈, 진형 전환 대기/취소, 함수 방향 유지 후퇴, 180도 선회 화면이 캡처 단계와 일치한다. 09~10에서 공개 지형 3종, 경유 경로, 미니맵 카메라 윤곽, 펼침 정보와 범례가 두 해상도 모두 화면 안에 표시된다. 새 정보·범례에 잘림이나 차단 수준 중첩은 없다. 기존 선택/명령 마커 일부 겹침은 보이나 이번 제품 변경의 신규 차단 사항으로 판정하지 않는다. 두 stages.json 모두 실패 0·10단계다. 정지 이미지의 관찰 한계는 회귀와 단계 측정으로 보완하며, 연속 영상 검증으로 주장하지 않는다.

`logs/gate-status.json`을 직접 확인했다. import 종료 0, 일반 35종 중 34종 종료 0, boundary만 기존 위반 1건으로 종료 1이다. salvo_compare 종료 0 및 SALVO_COMPARE_DONE을 확인했다. 이 게이트의 reference_motion_only 통과는 K2 fixture 이전 결과이므로 후속 실패를 덮지 않는다.

## K2 교전 fixture 실패 보존

`logs/reference_motion_only-k2.log`를 직접 확인했다. 30/60fps × 1/4배속 네 조합 모두 양방향 자동 사격 조건 실패, 위치/yaw drift는 0이다. 생존·정지 조건 실패가 없더라도 실제 교전 활성이 없는 결과는 이 검증의 통과가 아니다. K2 native 교전은 이 실패 뒤 실행하지 않았다.

K3는 현행 develop의 실제 투입된 비기함 후보에서 자연 탐지·실제 사거리 조건을 만족하는 쌍을 선택해야 한다. 탐지 상태 강제 공개·피해/사거리/센서 수치 변경·12초 단축·오차 허용치 완화는 수정 범위가 아니다. 최종 판정은 K3 영향 회귀와 두 해상도 PC 교전 증거를 받은 뒤 확정한다.


## K3 최종 판정: PC 범위 수용

K3 fixture는 현행 편성의 비기함 전열 후보를 기존 탐지 계산과 사거리로 필터링한다. 임시 배치로 계산한 후보 위치는 즉시 복구하며, 접촉을 강제 공개하거나 센서/피해/사거리 수치를 바꾸지 않는다. 조건을 만족하는 쌍이 없으면 빈 결과를 반환하고 각 호출자가 명시적으로 실패한다. 주유/서황 선택, 초기 14000/16000 milli-ships, 양측 사거리 260, 탐지 점수 48/16을 실제 실행 로그로 확인했다. 12초·생존·정지·오차 기준은 유지되었다.

- `logs/reference_motion_only-k3.log`: REFERENCE_MOTION_ONLY_PASS 직접 확인. 담당 실행 결과 종료 0. 네 fps/배속 조합의 실제 교전 및 VM/코어 종료 경계를 재검증했다.
- `native-status-k3.json`: combat-1600-k3와 combat-1280-k3 각각 종료 0, timeout false.
- 두 교전 폴더의 stages.json/process.log 및 0/3/6/12초 PNG 총 8장을 직접 확인했다. 각각 실패 0, 양측 core fire_id 활성 239프레임, 위치/yaw drift 0, 매 기록 fixture true, 마지막 12초에 살아 있는 표시 슬롯 12개다. 화면에서도 선택·함대 배열·함수 방향이 유지된다.
- core fire_id 활성은 상호 교전 표적 상태의 증거다. 이 캡처에서 실제 격침이 발생했다고 주장하지 않는다. 격침 후 생존 슬롯 유지 경로는 별도 reference_motion_only 및 fleet_follow 회귀로 확인한다.
- PC 기동·정보·범례 20장과 K3 교전 8장, 일반 35종(34 통과 + boundary 기존 1건/신규 0), K3 영향 회귀를 종합해 이번 선별 이식을 수용한다. K3는 fixture/검증 도구 변경으로 제품 수정이 없으므로 일반 35종을 다시 돌릴 추가 근거는 없다.

남는 제한은 종료 시 ObjectDB/resources 정리 경고(교전 캡처 각각 48/17, 영향 회귀 132/17)와 이번 범위에서 제외된 Android/태블릿·HTML 브라우저 검증이다. K1/K2 실패 증거는 그대로 보존하며 통과로 소급하지 않는다. 최종 제품 수정 요구는 0건이다. main 또는 다른 feature 작업 병합을 승인한 판정이 아니다.
