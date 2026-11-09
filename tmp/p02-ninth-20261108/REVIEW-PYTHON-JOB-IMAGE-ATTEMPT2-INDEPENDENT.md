# Python 이미지 진단 2회차 독립 결과 심사

판정: **2회차 실패, normal 0/1. 원인은 관측된 이미지와 Python-only allowlist의 실제 불일치까지 확인됐다.** `PYTHON-JOB-IMAGE-DIAGNOSTIC-ATTEMPT2-RESULT.md` SHA `eb36a04df185ab0663ce2d0edcb04cb8c017320cea0fb6efdfddd6633f83bbb3`, evidence JSON `888c5244cb276a53aebc3018c2e490a86a69ae46d3f4a5a8f bdd8cb9a86b7b66`의 정확 값은 공백 없이 `888c5244cb276a53aebc3018c2e490a86a69ae46d3f4a5a8fbdd8cb9a86b7b66`다. 심사 모델 gpt-6.1-terra. 추가 실행은 하지 않았다.

로컬 원문 `never-run-image-diagnostic-until-independent-approval.stderr.txt` SHA `4d20a15c87f9c4d475ee8e2a3963d807c99abe56644b0a643c9ad8c92a9df9f7`에는 PID 6540의 raw/resolved image가 `C:\Windows\System32\conhost.exe`, 예상 allowlist는 `C:\Python314\python.exe`, 조회 전후 Job membership true로 기록돼 있다. 현재 디스크의 해당 경로 file description은 Windows console host, 버전 `10.0.26100.9949`다. 이는 현재 파일 메타데이터이며 실행 당시 image의 바이트·서명이나 부모/생성 경로를 증명하지 않는다. 관측 경로는 Python 또는 명시된 V5 Python broker argv의 image와 다르다. 실제 왜 생성됐는지, 1회차의 미기록 image와 동일한지는 확인되지 않았다. 원시 경로는 로컬 증거에만 둔다.

정리 기록은 case Job drained=true, broker PID 12464 retained HANDLE signalled, exit 125, inner receipt/payload marker 없음이다. external watchdog은 owned_drained/output_complete true 및 supervisor exit 1, 별도 소유 sentinel은 exit 0이다. 불일치 image의 HANDLE은 예외 경로에서 닫혔으므로 그 HANDLE의 종료 신호를 독립적으로 기록하지 않았다. Job active 0/owned drain 기록을 보유 image HANDLE signalled 근거로 바꿔 말하지 않는다. 21 source/6 protected 파일과 HEAD/ref 전후 일치는 전달 기록의 관측이다. 최초 mismatch와 후속 cleanup ValueError는 분리돼 있다.

최소한의 후속 설계는 관측된 OS console host가 이 환경에서 어떤 소유 process tree에 나타나는지와 image 경로·identity·실행 당시 검증 근거, retained HANDLE과 종료 후 signalled, 기존 Python payload·sentinel 보호를 독립적으로 정하는 것이다. 그 결과에 따라 명시적으로 식별된 시스템 helper에 한정한 정책 또는 불필요한 helper 생성을 줄이는 방식을 검토할 수 있다. 이름만 보고 신뢰·서명·부모를 추정하거나 현 allowlist를 즉시 확대하지 않는다. helper의 허용/거부 및 다른 image·단명/PID 재사용·Job 밖 프로세스의 반례, 별도 source/manifest/시간·cleanup과 승인 pin을 갖춘 계획을 먼저 독립 심사한다. 필요 없는 추가 실제 시험은 하지 않고, 기존 실패 #1/#2를 보존한 비제품 K=3의 남은 1회를 임의 재실행하지 않는다.

실제 Godot·ABI·GUI·제품은 미실행이며 해당 결과와 K6을 집계하지 않는다. 최초 제품 import/검증 spawn에서 소진되는 마지막 K6 한 회, P03 활성 변경과 기존 원문은 유지한다.
