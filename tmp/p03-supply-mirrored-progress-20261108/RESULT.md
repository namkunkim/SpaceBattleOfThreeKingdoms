# P03 보급 진행량 두 표현의 혼합 관측

2026-11-08 KST. **ACCEPTED_EARLY_COMPLETION.** 실제 tick599 A의 완료 전 진행량을 tick600 B의 손님 `fleet.sup_prog`와 `service.sup_prog` 두 표현에만 동시에 넣은 D가 활성 교체에 수용됐다. 다음 tick601에 두 번째 수리가 바로 실행돼 누계 1→2, 공급 물자 7→6, `healed_mod` 2, 손상 배열 [2,2,0,0,0]과 supply 사건 한 개가 관측됐다. 정상 B의 같은 step은 추가 수리 없이 진행만 쌓여 누계 1·물자 7을 유지했다. [독립 5-b](REVIEW-5B-attempt-01.md)

직전 한 표현 변경은 재관측 불일치로 거부됐다. 이번 D는 두 값이 일치하지만 다른 시점의 상태를 섞은 **직접 조작 packet**이다. 실제 producer가 자연스럽게 이런 혼합을 만들 수 있는지, 외부 오염 packet을 어디서 어떤 정책으로 거부해야 하는지는 미검증·미결이다. 전체 지급 원자성이나 외부 저장 계약을 확정하지 않는다.

attempt-01/K6 actual Godot exit0, 명명4·1238 단언(반복 advance/drain 포함). 정본 console/본체·실제 Script와 46개 입력 전후 SHA 동일, 엔진 오류/경고/누수0. 시작 dirty 20701 재해시 누락0/P02 로그 변화2, 실행입력 drift0. 신규 외부 경로 16은 P02 작업 경로 15와 소유 미확인 이미지 1로 분리했다. status는 동시 변경이 있어 원자 스냅샷으로 표현하지 않는다. [실행](attempt-01/run.json) · [보존](preservation.json)

신규 공백 검사에서 실행 원문 180행의 빈 줄에 들여쓰기 한 건을 기록했다. 실행 시 동결한 runner와 실제 배포 원문이 일치하도록 해당 바이트를 보존했다. [공백 감사](new-file-whitespace.json)

전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. Dictionary 정확 context 불일치와 Detection 접촉 사건의 공개 정책은 별도다.
