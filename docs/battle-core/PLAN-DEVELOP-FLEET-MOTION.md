# develop 기동·지형 선별 이식

2026-10-16 사용자 지시: 기존 develop 구조를 유지하고 이번 기동·지형 기능만 별도로 이식한다.

## 소유와 범위

- 대상 `worktrees/develop-fleet-motion`, 로컬 develop, 시작 원격 `46e0533`.
- 원본 `worktrees/fleet-motion-terrain` K3를 참조하되 전체 병합/cherry-pick으로 최신 main의 편성·특기 등을 가져오지 않는다.
- 구현 gpt-6.1-sol, 독립 리뷰 gpt-6-astra. 부모는 조율·문서·검증·Git 담당. 이식 작업 K1/6.
- 함선 공유 방향 유지·미확인 흔들림/높이 잡음/격침 빈자리 메우기 제거·기존 명령/진형 호환, 공개 지형과 효과 정보·미니맵을 기존 develop API로 적용한다.
- 코어/밸런스/시나리오·편성·특기·정찰 변경은 제외한다. develop에 없는 후속 기능을 함께 도입하지 않는다.
- main 및 다른 세션의 미커밋 변경, 원본 K3 제품 코드는 보존한다. 사용자 요청 대상은 develop이며 main 병합 거부는 유지한다.

## 완료 기준

- [x] develop용 제품/회귀/화면 도구 작성 및 이식 내역 기록
- [x] import·기존 일반 순차 게이트·추가 기동/지형 회귀 통과, boundary 기존/신규 구분
- [x] PC 화면 확인(최신 사용자 지시: 검증은 PC만, Android/태블릿은 이번 범위 제외)
- [ ] 독립 5-b 검토·수정 완료 후 develop 커밋·원격 반영, 다른 작업 미포함 확인

원본 K3의 자동검사/화면 통과는 develop 이식본의 검증을 대신하지 않는다.

## 2026-10-17 누락 테스트 복구

클로드 정적 리뷰를 인계받았다. develop의 fleet_follow는 삭제된 `_target` 인자·`_close_ranks`·`phase`를 참조하고 reference_motion_only/fixture가 누락되어 있다. 구현 gpt-6.1-sol이 기존 develop worktree에서 복구하고, 독립 gpt-6-astra가 제품/테스트와 실행 증거를 검토한다. 일반 게이트는 단독·순차 실행하며 capture/audit/bench/autoresolve 도구는 분리한다. salvo_compare는 runs10을 사용한다. 코드 재시도 상한6.

기존 제품7파일과 지형 테스트는 종료된 이전 채팅의 이식 작업으로 확인했다. import118개·pause_button uid 및 원본 K3 미커밋 변경은 이번 복구와 구분한다. 최종 검증·리뷰 뒤 코드/관련 문서만 선별해 develop에 커밋한다. main 병합 거부는 계속 유효하다. 태블릿 실기·최신 HTML 브라우저 검증은 이번 PC/APK 검증으로 대체하지 않는다.

최신 사용자 지시(다른 담당 채팅에서 전달): “테스트는 pc로만 합니다”. 이번 완료 조건은 PC 일반/기동/지형 게이트·PC 화면·독립5-b이며 Android 빌드/서명·태블릿 검사는 실행하지 않는다. 앞 문단의 PC/APK 예정 범위는 이 지시로 정정한다. 아직 Android 검사를 시작하지 않았다.

## 최종 PC 검증 및 독립 판정

일반35종34PASS/종료0, boundary는 develop기준 기존1건/신규0·종료1. import 종료0, salvo_compare runs10 종료0·825.9초. fixture K3후 영향회귀 종료0·PASS. PC1600×900/1280×720 기동 각10단계·실패0, 최종 교전 각4화면·실패0·양방향 교전표적 활성239프레임·생존슬롯 위치/yaw drift0. 기계 근거는 develop의 docs/battle-core/evidence/develop-fleet-motion-20261017/, 전체 로그/PNG는 out/develop-motion-20261017/에 보존한다.

독립 gpt-6-astra가 코드·로그·최종 화면28장을 직접 대조해 PC범위 수용, 수정요구0으로 판정했다. K1 유비 fallback 격침 실패와 K2 자연접촉 없는 쌍의 사격0 실패는 보존했고 K3에서 기존 탐지/사거리로 상호 접촉 가능한 비기함을 선택하도록 검증도구만 교정했다. 제품·피해·12초·오차기준 불변. 종료 ObjectDB/resources 경고와 기존 stratagem_rules 문자열 포맷 경고는 남는다. develop Git 반영 상태는 완료 후 추가한다.
