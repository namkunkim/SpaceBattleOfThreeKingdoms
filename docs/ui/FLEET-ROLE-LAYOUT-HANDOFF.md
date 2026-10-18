# 함종별 진형 배치 작업 완료 인계

완료일: 2026-10-18. 사용자 확인: 전투 화면 캡처 확인 후 수용, 세션 작업 완료 요청.

## 완료 내용

- 함종별 역할을 유지하는 초기 배치와 진형 전환 배치 구현. 요격함·고속정은 같은 모델을 쓰더라도 함종 ID로 역할 구분.
- 실행 정본 [data/fleet-role-layout.md](../../data/fleet-role-layout.md)를 Godot 렌더러 생성 시 읽도록 연결. 잘못된 설정은 경고 후 내장 기본값 사용.
- Android 내보내기 설정에 실행 정본 문서 포함. APK 빌드는 이번 세션에서 실행하지 않음.
- [7종 배치도 HTML](fleet-formations.html)과 [편집용 원본](fleet-formations.fragment.html) 보관. HTML은 2026-10-18 설정의 기록이며, 문서 설정 변경 시 다시 생성해야 함.
- [진형 탭 스펙](FORMATION-TAB-SPEC.md), [함종별 배치 스펙](FLEET-ROLE-LAYOUT.md), 플레이 조작법에 사용 경로 추가.
- Godot 타이틀의 **진형 배치도**, 전투 중 **진형 → 배치도 보기** 연결. 예시 56척 또는 아군 실제 편성으로 7종 진형 열람. 적 편성은 비공개. 열람 중 전투 정지, 돌아가기·Esc로 이전 화면과 진행 상태 복원.

## 검증 결과

- `tests/formation_role_layout.gd`: 문서 로딩·설정 변경 반영·오류 대체·좌표 보존·결정성 통과.
- `tests/fleet_follow.gd`: 역할별 진형 전환·이동 추종·격침 빈자리 유지 통과.
- `tests/formation_display.gd`: 진형 전환 표시·적 정보 경계 통과.
- `tests/formation_ui.gd`: 기존 진형 카드·명령 동작 회귀 통과.
- `tests/formation_guide_ui.gd`: 진입·7종 이미지·아군 편성·열람 중 정지·Esc 및 이전 상태 복원 통과. 실제 GPU 실행에서 가로·세로 화면 확인.
- HTML의 7종 진형·392개 함선 이미지 표시 요소·8종 범례·진형 선택 갱신·내장 이미지·스펙 링크 검증 통과.
- 종료 시 ObjectDB·리소스 누수 경고는 기존 테스트에서도 발생하며 이번 세션의 수정 범위에 포함하지 않음.

## 화면 증거

- [Godot 배치도 가로 화면](evidence/fleet-role-layout/formation-guide.png)
- [Godot 배치도 세로 화면](evidence/fleet-role-layout/formation-guide-portrait.png)
- [전투 전체 화면](evidence/fleet-role-layout/formation-battle-overview.png)
- [전투 확대 화면](evidence/fleet-role-layout/formation-battle-close.png)

## 작업 보존 상태

사용자의 main 푸시 요청에 따라 이번 세션의 구현·테스트·MD·HTML 스펙·화면 증거를 main 반영 대상으로 정리했다. 같은 폴더에 있는 다른 작업의 변경 사항은 커밋에서 제외한다.
