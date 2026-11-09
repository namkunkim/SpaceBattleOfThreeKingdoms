# 확인 사실의 체크리스트 동기화 — 문서 1~3

2026-11-04 KST. 사용자 요청은 이미 확인된 진행 사실의 체크리스트 갱신이다.

1. **의도:** 상위·통합 MD·P2c·활성교체 전용 체크리스트의 오래된 P01 계획 미착수 설명과 빠진 독립 closeout 수용 근거를 실제 원문에 맞춘다. 코드/검사/기능·새 정책은 추가하지 않는다.
2. **스펙:** 대상 MD4개만 수정. 기존 통합 요구 ID41개 유지, P01만 미완료→완료. P02~P09와 전체 NOT_READY/UNCLASSIFIED는 유지. P2c70/11553/45, 활성20/20099/8이름9호출, 각 독립5b·closeout·ZIP/manifest 분모를 구분하여 링크한다. 기존 diff-check exit2 진단 및 상위P2c행 CRLF를 보존한다. HTML·브라우저/localStorage·두 기존 압축본은 바꾸지 않는다.
3. **분해:** 수정 전3945dirty SHA/대상 원문 사본 동결 → MD4개 최소 갱신 → ID/상태·원문 수치/링크·허용 diff·코드/HTML/zip SHA 보존 문서5a → 작성 비참여 다른 모델의 독립 문서 대조 요청. 문서 K3, 최초검사1회부터 기록한다. 코드/Godot 검사는 재실행하지 않는다. 기존 ZIP/manifest는 해당 시점 증거로 보존하고 이번 갱신 증거는 이 별도 폴더에 남긴다.

근거: 각 정본 RESULT/REVIEW와 `tmp/i01b-p2c-20261101/REVIEW-CLOSEOUT-20261102.md`, `tmp/i01b-active-replace-20261102/REVIEW-CLOSEOUT-20261104.md`, 두 INDEPENDENT-CLOSEOUT JSON. 이번 체크리스트 수정 자체의 독립 수용은 위 과거 closeout과 별도다. 커밋·푸시·병합·새worktree·HTML/editor import 없음.
