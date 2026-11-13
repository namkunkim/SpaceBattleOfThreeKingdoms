# P02 검증 근거 위치

P02 결과·인계 문서의 기존 링크는 당시 작업 폴더의 경로를 가리킨다. 아래 원본 근거와 전달 ZIP은 검증이 이루어진 작업 폴더에 보관되어 있다. 새 Git 복제본에는 아래 파일이 없으므로 원본 작업 폴더에서 별도로 확보해야 한다.

상위 세션 요구사항 체크리스트는 P02 외 요구사항과 P03 이력을 함께 관리하는 작업 폴더의 별도 문서다. P02 범위와 남은 인수는 [P02 진행 체크리스트](P02-PROGRESS-CHECKLIST.md)에 기록되어 있다.

## 별도 관리 문서

- `docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md`

## 별도 테스트 실행 준비

- `tests/p02_headless_adapter.gd`는 `tmp/p02-first-integration-20261105/`에 관측 JSON을 쓴다. 격리 복제본에 이 빈 디렉터리를 먼저 만들면 원본 관측 파일을 보존할 수 있다.
- `tests/p02_replay_adapter.gd`는 로컬 `tmp/p02-third-20261108/oracle.native`와 같은 디렉터리의 `matrix/`에서 commands, reordered, removed, defaults, one-tick, natural, direct, delegate, late, order, policy, limit, rows, commands-shape JSON을 읽는다. 원본 입력을 같은 상대경로에 복제한 뒤 실행한다.
- CLI의 `--operation-input`, `--operation-worker`, `--operation-replay`는 커밋에 포함된 `tests/fixtures/p02/`의 입력으로 실행할 수 있다.

## 로컬 실행 근거와 전달 ZIP

- `tmp/P02-REPLAY-DELIVERY-20261108.zip`
- `tmp/P02-VIEWER-EVENTS-DELIVERY-20261108.zip`
- `tmp/p02-eighth-20261108/IMPLEMENTATION-EVIDENCE.md`
- `tmp/p02-eighth-20261108/SESSION-HANDOFF-INCOMPLETE.md`
- `tmp/p02-eighth-20261108/candidate-product.patch`
- `tmp/p02-eighth-resume-8d838216ccfc/REVIEW-PREPARED-V5-INDEPENDENT.md`
- `tmp/p02-eighth-resume-8d838216ccfc/SESSION-HANDOFF-INCOMPLETE.md`
- `tmp/p02-fifth-20261108/IMPLEMENTATION-EVIDENCE.md`
- `tmp/p02-fifth-20261108/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-fifth-20261108/REVIEW-CONCURRENT-FILES-INDEPENDENT.md`
- `tmp/p02-fifth-20261108/before-attempt-01/processes.json`
- `tmp/p02-fifth-20261108/closeout/P02-LEGACY-OUTCOME-DELIVERY-20261108.zip`
- `tmp/p02-fifth-20261108/closeout/REVIEW-CLOSEOUT-RECHECK-INDEPENDENT.md`
- `tmp/p02-fifth-20261108/closeout/post-zip-preservation-audit.json`
- `tmp/p02-fifth-20261108/v3-after-attempt-01/processes.json`
- `tmp/p02-fifth-20261108/v3-before-attempt-02/processes.json`
- `tmp/p02-fifth-20261108/v3/gate-verdict.json`
- `tmp/p02-fifth-20261108/v3/oracle-freeze.json`
- `tmp/p02-fifth-20261108/v3/original-outcome-oracle.json`
- `tmp/p02-first-headless-delivery-20261107-correction.zip`
- `tmp/p02-first-integration-20261105/FIXTURE-PROVENANCE.md`
- `tmp/p02-first-integration-20261105/PLAN-ATTEMPT1-REVISION.md`
- `tmp/p02-first-integration-20261105/PLAN.md`
- `tmp/p02-first-integration-20261105/REVIEW-5B-ACCEPT-20261107.md`
- `tmp/p02-first-integration-20261105/REVIEW-5B-NON-ASTRA-20261107.md`
- `tmp/p02-first-integration-20261105/REVIEW-CLOSEOUT-NON-ASTRA-20261107.md`
- `tmp/p02-first-integration-20261105/REVIEW-PLAN-ATTEMPT1-ACCEPT.md`
- `tmp/p02-first-integration-20261105/closeout-correction/archive-verification.json`
- `tmp/p02-first-integration-20261105/closeout-correction/audit.json`
- `tmp/p02-first-integration-20261105/closeout-correction/manifest.json`
- `tmp/p02-first-integration-20261105/model-independence-evidence.json`
- `tmp/p02-fourth-20261108/IMPLEMENTATION-5A-NOTES.md`
- `tmp/p02-fourth-20261108/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-fourth-20261108/REVIEW-5B-REBASELINE-INDEPENDENT.md`
- `tmp/p02-fourth-20261108/attempt1/viewer.stdout`
- `tmp/p02-fourth-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md`
- `tmp/p02-fourth-20261108/negative-oracle/results.json`
- `tmp/p02-fourth-20261108/rebaseline-1/REBASELINE-NOTES.md`
- `tmp/p02-fourth-20261108/rebaseline-1/additional-protection.json`
- `tmp/p02-fourth-20261108/rebaseline-1/verdict.json`
- `tmp/p02-next-20261107`
- `tmp/p02-next-20261107/IMPLEMENTATION-5A-NOTES.md`
- `tmp/p02-next-20261107/PLAN.md`
- `tmp/p02-next-20261107/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-next-20261107/REVIEW-PLAN-INDEPENDENT.md`
- `tmp/p02-next-20261107/attempt3/results.json`
- `tmp/p02-next-20261107/closeout/REVIEW-CLOSEOUT-INDEPENDENT-20261108.md`
- `tmp/p02-next-20261107/closeout/preservation.json`
- `tmp/p02-next-20261107/fixture-provenance.json`
- `tmp/p02-next-20261107/implementation-manifest.json`
- `tmp/p02-next-20261107/owned-diff-proof.json`
- `tmp/p02-seventh-20261108/GUI-RESUME-EVIDENCE.md`
- `tmp/p02-seventh-20261108/K4-K5-EVIDENCE.md`
- `tmp/p02-seventh-20261108/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-seventh-20261108/closeout/P02-PREP-ERROR-DELIVERY-20261108.zip`
- `tmp/p02-seventh-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md`
- `tmp/p02-sixth-20261108/IMPLEMENTATION-EVIDENCE.md`
- `tmp/p02-sixth-20261108/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-sixth-20261108/after-attempt-02/atomic/trace-compare.json`
- `tmp/p02-sixth-20261108/closeout-v2/P02-HOST-PREP-DELIVERY-20261108.zip`
- `tmp/p02-sixth-20261108/closeout-v2/REVIEW-CLOSEOUT-INDEPENDENT.md`
- `tmp/p02-sixth-20261108/closeout-v2/preservation-before.json`
- `tmp/p02-sixth-20261108/closeout/session-models.json`
- `tmp/p02-third-20261108/IMPLEMENTATION-5A-NOTES.md`
- `tmp/p02-third-20261108/PLAN.md`
- `tmp/p02-third-20261108/REVIEW-5B-INDEPENDENT.md`
- `tmp/p02-third-20261108/REVIEW-PLAN-CONTROLS-CLARIFICATION.md`
- `tmp/p02-third-20261108/REVIEW-PLAN-INDEPENDENT.md`
- `tmp/p02-third-20261108/attempt1/results.json`
- `tmp/p02-third-20261108/attempt2/results.json`
- `tmp/p02-third-20261108/attempt3/results.json`
- `tmp/p02-third-20261108/baseline-context.json`
- `tmp/p02-third-20261108/closeout/REVIEW-CLOSEOUT-INDEPENDENT.md`
- `tmp/p02-third-20261108/legacy-mixed/results.json`
- `tmp/p02-third-20261108/oracle-freeze.json`
- `tmp/p02-third-20261108/preservation.json`
