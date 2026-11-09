# P03 탐지 모듈 상태 책임 원장 계획

2026-11-08 KST. **독립 계획 심사 대기. 읽기 조사 후보이며 코드/Godot 미착수.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. P02 최신 revision5는 제품 자동결산 전달물의 독립 마감 단계다. 공통 owner 쓰기 소유 인계 근거는 확인되지 않았다.

[기존 상태 조사](../p03-state-checkpoint-20261105/STATE-AUDIT.md)는 ST14를 모듈 행 하나로 다뤘다. 새 산출물은 **Detection 6개 선언과 동적 접촉 records를 항목별로** 현재 초기화·갱신·소비·참조 결합 경로에 연결한다. 새 runtime 변경이나 복원 호환 승인 없이 capture/rebuild/rebind/recompute의 근거와 미검증 책임을 구분한다. 쓰기 범위는 이 전용 문서 폴더뿐이다. P02 공통 owner/adapter/viewer/replay/공유 문서는 읽기 전용이다.

## 5-a 사전등록

- `Detection`의 `sim/D/terr/contacts/_period/_conf0` 6개에 타입·소유·수명·초기화/갱신/소비 source:line 및 현재 또는 후보 capture/rebuild/rebind/recompute 분류를 붙인다. 초기화 때 terrain absent이면 만든 별도 객체와 shared terrain 참조를 구분한다. runtime alias/derived 비교 증거는 실제 한정 검사 근거가 있을 때만 표현한다.
- `contacts` 외부 side Array, int target ID Dictionary와 record 필드 `seen/pos/state/conf_bp/err_r` 5개, 입력 정책/config 및 평가 주기, 해당 tick·순서·키 추가/삭제, last known/현재 위치를 구분한다. P2b capture/restore 사전 검증과 P2c private owner의 위임·exactness 범위를 원문과 대조한다. contact record를 일반 JSON schema로 새로 정하지 않는다.
- 독립 후속 반례는 세 가지다. **(a)** 사용자가 보는 projection의 ID 정렬과 raw Dictionary 삽입순서가 다를 수 있음. **(b)** 관측 전후 재평가로 기억을 실제 위치로 덮거나 키가 남은 lost contact를 확정 표적으로 잘못 해석할 위험. **(c)** `Detection._store`가 제거 시 빈 `nr`의 position fallback으로 현재 `t.pos`를 전달하고 side0의 contact 사건은 filtered drain의 일반 마스킹을 타지 않는 경로. 후자의 실제 노출과 D05 공개 허용 여부는 가설·정책 미결로 따로 두고 기존 viewer 성공의 결론으로 덮지 않는다.
- `Detection.rec`/contacts 반환의 mutable alias, 참조 ID validation, 지문/투영/사격/AI/이벤트 소비 위치를 구분한다. 소스와 기존 시험이 증명한 점 및 신규 실제 fixture가 필요한 점을 각 행에 적는다.

정본 core/consumer와 H2·D04·D05·P2b/P2c·P02 viewer 근거 SHA를 문서 작성 전후 비교한다. 6선언/5record 필드와 세 반례, 링크, Git refs/index 상태를 기계 점검하고 독립 심사가 원문과 해석을 대조한다. 문서 K3, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
