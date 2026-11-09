# P03 Dictionary value-only context 결함 재현

2026-11-08 KST. **정확 context 계약 MISMATCH.** 활성 owner의 `Dictionary[String,int]`와 후보 `Dictionary[String,Variant]`에 같은 String 키 `"k"`와 실제 int 값 7을 넣었다. key 컨테이너와 파생 `keys()` Array metadata도 같았다. 입력·capture·독립 prepare에서 유일한 Dictionary value builtin 차이 int→Variant가 유지됐으나 `restore_completed`가 ok:true를 반환하고 같은 handle의 sim을 교체했다. 활성 owner의 원 context metadata는 int로 남았고 packet은 변경되지 않았다. [독립 판정](REVIEW-5B-attempt-01.md)

동일 typed context의 성공 대조군과 key metadata 차이의 거부 대조군은 기대한 결과였다. attempt-01/K6 실제 Godot exit0은 **관측 절차 완료**이며 제품 계약 PASS가 아니다. 명명3·48 단언, 오류/경고/누수 진단0, 실제 console/본체·class map 및 입력45 전후 일치. [실행](attempt-01/run.json)

원 dirty/untracked 13313 전수 재해시는 누락0·변경0, 정본 실행입력45의 사후 drift0이다. status는 동시 변화가 있어 원자 스냅샷이 아니다. 별도 신규 경로 3341개는 P02 작업 폴더에 있다. 전체 diff-check exit2 기존 P2c 공백 진단과 새 파일 검사를 분리했다. [보존 감사](preservation.json)

공통 owner와 제품 파일은 수정하지 않았다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. 역방향 및 Dictionary value class/script identity는 이 재현 분모 밖이다.
