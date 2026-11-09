# 제한 활성 owner 교체 — 6 마감 독립 확인

검토일: 2026-11-04. 판정: **제한 범위의 6 기록·보존·압축 인계를 수용한다.** 구현 비참여 심사자 `/root/independent_review` (`gpt-6-astra`)가 수행했다. 코드 5b 수용을 재실행하지 않았고 생산 코드·검사·정본 압축본·manifest를 변경하지 않았다.

## 문서와 판정의 일치

정본 [REVIEW](../../docs/battle-core/pc-campaign-design/REVIEW-I01B-ACTIVE-REPLACE-20261104.md), [RESULT](../../docs/battle-core/pc-campaign-design/I01B-ACTIVE-REPLACE-RESULT-20261104.md), [CHECKLIST](../../docs/battle-core/pc-campaign-design/I01B-ACTIVE-REPLACE-CHECKLIST-20261104.md), [HANDOFF](../../docs/battle-core/pc-campaign-design/SESSION-HANDOFF-I01B-ACTIVE-REPLACE-20261104.md)를 기존 [5b 수용](REVIEW-5B-ACCEPT-20261104.md) 및 실행 증거와 대조했다. 정상 20사례/20099체크, 명명 8개/실제 거부 호출 9개, attempt1 ParseError와 attempt2 성공, P2c/core/data 3회귀 및 data의 기존 종료 진단이 구분되어 있다.

동일 owner handle의 제한 내부 runtime 교체만 수용하며 실제 게임 host/UI/스레드 통합 완료를 뜻하지 않는다. 사건 복원은 packet 시점의 pending/drain 상태 복원이고 외부 소비자의 전역 중복 억제가 아니다. 전체 I01/I01b/A04~A06은 **NOT_READY**, 외부 저장 schema는 **UNCLASSIFIED**를 유지한다.

## 직접 확인한 마감 증거

실행자 요약을 인용하는 데 그치지 않고 [독립 원자료](INDEPENDENT-CLOSEOUT-20261104.json)에 실제 바이트 재해시와 ZIP 검사를 기록했다.

- 최종 ZIP `tmp/i01b-active-replace-delivery-20261104.zip`: **1,601,850 bytes / 105 entries**, SHA256 `87a090a8d891391473fd9dfa9627dcd4430af234359e06d0b78e9e7b5f005eae`. CRC 불량 0, 중복 entry 0, 포함목록 순서까지 일치, entry SHA/크기 및 현재 디스크 바이트 불일치 0.
- `record-manifest.json`의 104항 모두 현재 파일 SHA와 일치한다. manifest 자체를 포함한 ZIP 105항과 수가 구분된다.
- 내부 포함된 이전 P2c ZIP은 현재 디스크와 동일하며 SHA256 `99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971`이다. 내부 254항 CRC 불량·중복 0이며 복구 자료를 보존한다.
- baseline 3879경로 누락 0. 변경은 승인 helper와 상위 CHECKLIST 추가 행뿐이다. source35 변경·누락 0, attempt2 입력42 SHA 일치, 격리77 SHA 일치 및 원경로 부재를 재확인했다. 이전 P2c payload254와 현재 디스크의 차이도 동일한 승인 2경로뿐이다.
- 상위 CHECKLIST의 이번 추가 행 1개를 바이트로 제거하면 baseline SHA `dda7386c426ebd3a5804e2f5309489a6175f387be827369c781875a8cceabe7b`로 정확히 돌아간다. 이전 P2c 33행 CRLF는 보존되어 있다.
- 최종 helper/test는 5b 입력 SHA와 동일하다. branch/HEAD는 동결값과 같고 index는 비어 있다.

## 남겨 둔 기존 진단과 기록 경계

직접 실행한 전체 `git diff --check`의 실제 종료값은 **2**이며 유일한 공백 진단은 기존 상위 CHECKLIST 33행이다. 이를 전체 gate PASS로 해석하지 않는다. 기존 CRLF 및 stderr의 줄바꿈 경고를 원자료에 보존했으며 진단을 없애려고 다른 소유 파일을 수정하지 않았다.

이 보고서와 독립 JSON은 압축본 생성 이후의 **외부 보충 기록**이다. 기존 압축본과 manifest를 다시 작성하지 않으며 자신의 SHA를 그 안에 소급 포함하지 않는다. 추가 코드 변경이나 검사 반복 없이 6단계 마감을 수용한다.
