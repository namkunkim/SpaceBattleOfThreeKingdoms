# Python 소유 이미지 진단 후보 독립 심사

판정: **비제품 Python normal 진단 2번째 시도 한 번을 수용한다.** 실제 실행은 이 심사에서 하지 않았다. 제품/Godot/GUI·ABI 및 K6 실행은 승인하지 않는다. 계획 SHA `54d2ecd9e35715725c01740b9415944c1cea7ca77cfb7999a8456b0088c58dac`, SHA 목록 `4fb4ba2b468e26d1de9ee4eda95b49b9280edc3e11bdb10b3aa56a60d7204868`, review-only manifest `35b75ad6c43bf3d8f42a7a11cc2027e11c6641ea2cc15e47ab9f4183edd7e9f6`를 검토했다. 심사 모델 gpt-6.1-terra.

승인 manifest는 review-only 원본의 status만 `INDEPENDENTLY_APPROVED_NONPRODUCT_PYTHON_IMAGE_DIAGNOSTIC`으로 바꾼 새 `variant-abi-review/PYTHON-JOB-IMAGE-DIAGNOSTIC-MANIFEST-APPROVED.json`, SHA-256 **`a7647cca76be8cd5f46681b817765d4816ae1c94f3b7676244cfb949d8fdb375`**다. 현재 입력 21개 및 보호 파일 6개의 SHA가 일치하고 HEAD `0be09755b70378286105972f35ac5b7031715664`, symbolic ref가 기대와 일치하며 새 scratch/guard journal은 존재하지 않는다. 실행 직전에 승인 manifest bytes와 전체 input/protected SHA, HEAD/ref, scratch와 diagnostics 경로 부재를 다시 확인하고 drift 시 중단한다. 이전 실패 자료를 변경·삭제하지 않는다.

정확 argv는 manifest의 `outer_watchdog_argv_template`에 승인 manifest 절대경로와 위 digest를 치환한 `C:\Python314\python.exe -I -B C:\WorkSpace\SpaceBattleOfThreeKingdoms\tmp\p02-ninth-20261108\prep-ab-sol\variant-abi-review\python_job_image_external_candidate.py <승인 manifest 절대경로> <위 SHA>`다. Default managed sandbox에서 한 번만 실행하고 권한 상승·설정 변경·기존 사용자 프로세스의 열람/종료를 하지 않는다. Python 진단 K=3 중 기존 실패가 1회이고 이 실행이 2회째다. 중단·실패·미관측·증거 누락도 시도에 포함하며 자동 재시도하지 않는다. 이 예산은 제품 K6과 별개다.

정적 코드상 기존 `Path.resolve`+`normcase`의 Python 1개 allowlist를 유지하고 보유한 Job process HANDLE에서 membership·PID/creation·alive를 앞뒤 확인한다. 예기치 않은 image의 raw·lexical·resolved 경로를 bounded frame에 남기고 최초 오류와 cleanup 오류를 분리한다. 원시 경로는 전용 증거에만 보관하고 사용자 보고에는 노출하지 않는다. 다만 관측 경합 또는 출력 손실이면 미확인 실패이며, identity/path가 기록돼도 과거 실패의 원인이나 image bytes 동일성을 소급 증명하지 않는다. 소유 Job만 drain하고 별도 소유 sentinel은 해당 case Job 밖에서 확인 후 자기 Popen으로 정상 종료한다.

25초 global, bootstrap/barrier 3초, case inner 3초·outer 10초, drain/journal 2초 및 제한된 진단 출력을 적용한다. Python thread/OS 전체 정지에 대한 절대 hard-stop은 증명되지 않았고 journal·drain 미관측은 실패다. 첫 오류·cleanup·exit·실제 HANDLE/Job 및 전후 보호 결과를 원문으로 독립 심사하기 전 후속 ABI/Godot 또는 제품 시험을 시작하지 않는다. 예상 밖 image를 자동 허용하거나 기존 allowlist를 확대하지 않는다. K1~K5와 최초 제품 import/검증 시 소진되는 마지막 K6을 보존한다.

