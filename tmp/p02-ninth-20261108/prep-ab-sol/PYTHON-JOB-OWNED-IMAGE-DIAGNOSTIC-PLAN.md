# 소유 이미지 실패 진단 후속안

기존 Python v3 one-shot은 첫 normal 실패, 0/6이다. 원문·scratch·승인 manifest는 보존했다. 현재 Job의 unexpected owned image 값은 원문에 없으므로 어느 이미지가 관측됐는지 판단할 수 없다. 경로 spelling, Windows 리다이렉션, 실제 다른 자손 및 조회 경합을 모두 미확정으로 남긴다. 허용 목록을 늘리지 않았고 실제 재실행도 하지 않았다.

## 코드에서 확인된 손실과 새 기록

기존 abi_owned_runner_v3.py의 observe_owned_engine_handles는 QueryFullProcessImageNameW 결과를 받아 Path.resolve와 normcase를 적용한 다음 허용 목록을 검사한다. 실패 메시지는 고정 문자열이라 raw path, 관측 PID, creation time을 잃는다. 이어 python_job_qualification_v3.py의 finally에서 marker와 payload HANDLE을 검사하다 다른 예외가 발생해 최초 실패가 종료 이유에 덮일 수 있다. 두 오류가 있었음을 실제 stderr traceback으로 확인했고 후자의 오류를 최초 원인으로 분류하지 않는다.

variant-abi-review/owned_image_diagnostics_review.py는 보유한 정확 Job HANDLE만 입력받는 새 diagnostics seam이다. IsProcessInJob 양성을 먼저 확인한다. WaitForSingleObject, GetProcessId, GetProcessTimes로 조회 시작 시점과 끝에서 identity를 확인한다. QueryFullProcessImageNameW의 raw Windows path와 비교용 정규화 spelling을 모두 보존한다. PID 재사용, 짧은 프로세스, 조회 사이 membership 상실 및 실패는 별도 원인이고, Job 밖이거나 identity가 변한 경우 image 값을 버린다. 예상 밖 이미지 파일을 열거나 다른 프로세스를 찾거나 그 이미지로부터 allowlist를 다시 만들지 않는다. 정규화는 pathname spelling 비교일 뿐 파일 바이트·reparse·실제 executable identity 보증이 아니다.

RetainedJobQueries는 이 흐름의 Win32 조회 adapter 초안이다. Popen, OpenProcess 또는 PID enumeration을 실행하지 않는다. 실제 호출자에서 Job process list 및 즉시 얻은 retained HANDLE의 소유권을 먼저 확인해 전달해야 한다. 조회 전후 짧은 경합은 실패로 남기고 다른 프로세스의 이름을 대신 붙이지 않는다. Native API 실측은 없다.

## 원문 분리 및 안전 경계

새 실행기가 채택된다면 owner가 첫 exception 이전에 생성한 최초 관측 record를 outside supervisor에 전달한다. Bounded diagnostic 전용 JSONL 또는 별도 slot의 raw path는 exact allowlist와 해당 owned PID/creation/phase/membership만 가진다. 환경변수, argv 외부 값, token, unrelated paths 및 process contents는 수집하지 않는다. Path는 JSON escape하여 단일 record로 보관하고 일반 보고서는 PID/단계/판정만 요약한다. 256KiB record cap, 기존 stage/outer Job deadline과 separate journal flush를 유지한다. 전용 scratch를 새로 만든 승인 run에서만 파일을 쓴다. Cap 또는 전용 receipt 누락은 실패이며 짧게 잘라 허용 판정하지 않는다.

Failures의 first 및 cleanup slot은 각각 한 번만 채워진다. Cleanup의 payload-unobserved 또는 drain 실패는 최초 unexpected-owned-image를 덮지 않는다. Native query exception은 운영 코드에서 stage와 API/WinError 숫자로 제한해 별도 기록하고, 임의 exception 인자 및 경로를 stdout에 출력하지 않는다. 실제 runner에 연결할 때는 외부 journal이 worker 종료 이후에도 살아 있고 소유 Job drain과 출력 flush를 각각 검증하는지 독립 심사가 필요하다. 기존 시험과 현재 코드에는 이 연결을 적용하지 않았다.

## 이번 작업과 재개 조건

합성에서 정규화로 동일한 경로를 수용하고 실제 다른 문자열의 full raw path를 보존했다. Nonmember, 짧은 수명, PID 재사용, membership 상실, image 누락, cleanup receipt 누락을 거부했다. 최초와 후속 원인이 분리됨을 확인했다. 정적 Python compile 외에는 실제 API/Job/Python 자손/Godot/GUI/제품을 시작하지 않았다.

이 자료는 source-only 진단 제안이다. 기존 허용 목록, 승인 one-shot 및 원본 소스는 그대로다. 추가 실제 진단이 필요하더라도 최초 실패는 시도 1회로 유지한다. 원인 가설·새 scratch·exact immutable argv/manifest·owned cleanup·별도 잔여 예산을 먼저 정의하고 독립 심사를 받아야 한다. 이 초안만으로 재실행하지 않는다. K6 한 회가 남아 있다.
