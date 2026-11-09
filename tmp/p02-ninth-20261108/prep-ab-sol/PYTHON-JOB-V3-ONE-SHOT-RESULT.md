# 승인된 비제품 Python Job v3 일회 실행 결과

판정은 실패다. 독립 승인 manifest SHA 85f4c4ad6cb8b3eed3ef8554716224b4619e9bd5cdc3b386e6781a3d0a94e8c5와 manifest에 명시된 argv를 사용해 default managed sandbox에서 watchdog을 한 번 시작했다. 재실행하지 않았다. 실행 도구의 경과 시간은 2.04초였고 launcher는 2026-11-08 16:09:11 UTC에 시작·종료, exit 1을 기록했다.

- 직전 승인 14개 입력 및 6개 보호 파일 SHA, resolved HEAD 0be09755b70378286105972f35ac5b7031715664와 symbolic ref가 일치했다. 지정 scratch·guard journal·외부 diagnostics와 launcher stdout/stderr 파일은 모두 존재하지 않았다. 종료 직후 같은 14/6개와 HEAD/ref가 다시 일치했다.
- 첫 normal case는 outer Job member 관측에서 unexpected owned image로 실패했다. 원문 오류에 그 image path가 없어 실제 이미지 이름은 미확인이다. 후속 정리 진단은 payload not observed in outer Job이다. Normal case raw journal의 inner_receipt=false, payload_pid=null 및 payload_observed=false를 보존했다. 실제 payload가 시작됐는지는 원문으로 입증할 수 없다. 이후 timeout/output-cap/outer-stall/observation-negative/journal-negative 5개는 시작되지 않았고 통과 0/6이다.
- Normal case outer journal은 drained=true, controller-side broker exit 125와 확인된 Python member PID 21620의 retained_signalled=true를 기록했다. Global watchdog은 owned_drained=true, output_complete=true 및 supervisor-side exit 1을 기록했다. Separate owned sentinel은 PID 40360 및 정상 exit 0을 기록했다. 이는 launcher의 소유 범위와 남아 있는 HANDLE 기록이며 관측하지 못한 payload의 정상 종료나 다른 Job 조건의 성공을 의미하지 않는다.
- 제품 코드·fixture·Godot·GUI·ABI 엔진은 실행하지 않았다. K6 한 회가 남아 있다. 실제 nested ownership과 image compatibility는 미검증이며 이 결과를 후속 엔진 실행 승인 근거로 사용하지 않는다. 이후 조치는 독립 결과 심사에 맡긴다.

원문은 variant-abi-review의 qualification-v3-exec stdout/stderr, 같은 이름의 guard/outside diagnostics, scratch normal/outer.jsonl 및 sentinel.jsonl이다. 개별 SHA와 길이는 python-job-v3-actual-evidence.json에 있다.
