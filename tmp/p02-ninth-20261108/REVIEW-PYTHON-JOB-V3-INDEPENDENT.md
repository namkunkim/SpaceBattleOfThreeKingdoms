# Python 비제품 Job qualification v3 독립 최종 심사

판정: **명시된 Python 전용 6-case 일회성 시험을 수용한다.** 제품·Godot·GUI·ABI 및 K6 실행은 승인하지 않는다. 심사 모델 gpt-6.1-terra. 이 심사에서는 실제 프로세스/Job을 시작하지 않았다.

검토 원문 `PYTHON-JOB-QUALIFICATION-V3-REVIEW.md` SHA `911a7a91d451e2d7bdf178b7a40b67009e5b36f3e29f299d22a4154820b24433`, review-only manifest SHA `c21667f759e34191b7b71f44ba436850deaec040ad8d6984cf8ee908325bcf42`, 목록 SHA `7bbc50f9257f31a02e2e89730328c88d3e6ba1cc45b57b83845d168bddbd1bc4`을 확인했다. 원문 14개 입력과 6개 보호 파일의 현재 bytes/SHA가 모두 일치하고 HEAD `0be09755b70378286105972f35ac5b7031715664`, symbolic ref도 일치한다. scratch 및 외부 journal은 현재 없다. 이는 관측 시점의 결과이며 병행 변경이 불가능하다는 의미가 아니다.

승인 manifest는 review-only 원문에서 status 값만 `INDEPENDENTLY_APPROVED_NONPRODUCT_PYTHON_JOB`으로 바꾼 새 파일 `variant-abi-review/PYTHON-JOB-QUALIFICATION-MANIFEST-v3-APPROVED.json`, 정확 SHA-256 **`85f4c4ad6cb8b3eed3ef8554716224b4619e9bd5cdc3b386e6781a3d0a94e8c5`**다. 독립 실행자는 이 승인 digest와 해당 bytes를 그대로 사용하고 실행 직전 전 source/protected SHA, resolved HEAD/ref, 새 scratch·journal 부재를 다시 확인한다. drift 시 중단하고 기존 파일을 복구·삭제하거나 덮어쓰지 않는다. Default managed sandbox만 사용하며 권한 상승이나 설정 변경은 없다.

정확 실행 argv는 manifest의 `outer_watchdog_argv_template`에 승인 manifest 절대경로와 위 digest를 치환한 `C:\Python314\python.exe -I -B C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p02-ninth-20261108\prep-ab-sol\variant-abi-review\python_job_external_watchdog_v3.py <승인 manifest 절대경로> <위 SHA>`다. 한 번만 시작하고 결과 원문·외부 journal·각 case stdout/stderr·handle evidence·전후 보호 SHA를 보존한다. 사용자 또는 비소유 프로세스를 찾거나 종료하지 않는다. 제한된 Python payload는 제품 코드/fixture/cache를 읽지 않으며 K6 소진점이 아니다.

코드상 boot worker 3초 내 broker 정확 HANDLE 할당·membership 후 barrier, 별도 barrier 3초, 시작부터 90초 global, 2초 owned drain 및 2초 journal worker를 적용하고, case Job 외 sentinel은 해당 Job 비구성원·생존 후 자신의 Popen으로 정상 종료한다. timeout/assignment failure/handle 미관측/receipt 또는 journal 누락·unexpected file/exit는 실패다. 외부 watchdog 및 Windows 자체의 무한 지연을 절대 배제한 보증은 아니며, 관측되지 않은 cleanup은 성공으로 주장하지 않는다. 결과는 실제 Python Job 6 case의 원문에 한정하고 Godot wrapper·ABI·GUI·제품·K6의 증거로 대체하지 않는다. 외부 watchdog 정상/실패 및 독립 결과 심사 전 후속 시험을 시작하지 않는다.
