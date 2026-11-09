# P03 typed Dictionary context 관측 결과

2026-11-08 KST. `Dictionary[String,int]`를 가진 활성 owner에 같은 값의 untyped 후보 packet을 복원했을 때 `replacement_context_mismatch`가 반환됐다. metadata 차이는 입력·capture·prepare 전 경로에서 유지됐고 active sim/상태·packet·busy를 보존한 다음 정상 advance가 가능했다. 이 **한 방향의 dictionary_contract는 MATCH**다. 독립 오라클에서 Godot의 `Dictionary.keys()`가 typed key 배열을 반환하는 것도 확인했다. 현재 owner가 이 키 배열을 typed Array 분기로 비교하므로 Dictionary metadata의 직접 비교가 없어도 이 방향은 거부할 수 있다. 값 metadata만 다른 경우와 역방향은 미검증이다. [독립 5-b](REVIEW-5B-attempt-03.md)

같은 typed context는 복원됐고 Array의 builtin, native class, script identity만 다른 세 대조군은 정확히 거부됐다. 정본 attempt-03/K6 실제 Godot exit0, 명명5·76 단언, SCRIPT ERROR/ERROR/WARNING/누수0. 실제 console/본체·정본 class map과 입력46 전후 SHA가 일치했다. attempt-01은 줄연결 패치의 파싱 오류, attempt-02는 null script/파생 keys Array를 독립 오라클에서 잘못 비교한 사전조건 실패였다. 둘 다 actual exit1이며 결과 분모에서 제외하고 원문을 보존했다. [실행](attempt-03/run.json)

원 dirty/untracked 13241개 재해시, 누락0 및 P02 작업 폴더 변경3. 입력46 현재 drift0. 새 외부 14개는 P02 자동결산 변환 작업에 속한다. 기존 전체 diff-check exit2를 신규 소유 파일 검사와 분리했다. [보존 감사](preservation.json)

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED다. 제품 코드나 공유 체크리스트에는 변경이 없다.
