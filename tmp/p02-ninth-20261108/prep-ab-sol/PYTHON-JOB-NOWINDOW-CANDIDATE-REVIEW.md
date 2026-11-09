# Python 비제품 3회차 콘솔 분리 진단 후보

상태는 review-only다. 기존 Python 비제품 진단 K=3의 실패 1·2회차를 보존한다. 이 후보는 마지막 3회차로 normal 한 케이스만 제안한다. 실패, 미관측 또는 중단 뒤 반복하지 않는다. 제품 K6과 별도이며 Godot·GUI·제품을 사용하지 않는다.

## 좁은 가설과 플래그

2회차에서 확인한 예상 밖 프로세스 이미지는 Windows console host였다. 당시 image bytes·서명·parent와 최초 1회차 이미지의 동일성은 미확인이다. Outer/supervisor와 inner를 시작하는 Popen broker 및 sentinel은 이미 CREATE_NO_WINDOW를 넘기지만 기존 V5 broker가 자신의 실제 argv를 시작하는 subprocess.call에는 플래그가 없다. 이 차이 때문에 console 없는 broker가 Python console 앱을 만들 때 console host가 생길 수 있다는 가설을 검증한다. 어느 특정 spawn edge가 앞선 실패를 만들었다는 증거는 아직 없다.

Microsoft Win32 문서에서 CREATE_NO_WINDOW는 console application을 console handle 없이 시작하는 플래그다. DETACHED_PROCESS는 console 상속을 막지만 이후 AllocConsole이 가능하며 CREATE_NO_WINDOW와 함께 쓰면 후자가 무시된다. 이 후보는 CREATE_NO_WINDOW 하나만 추가한다. 이 문서가 모든 Windows backend에서 host helper의 부재를 보증하지는 않는다. [Microsoft Process Creation Flags](https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags), [Microsoft Creation of a Console](https://learn.microsoft.com/en-us/windows/console/creation-of-a-console)

기존 broker의 stdin=DEVNULL은 유지하고 stdout/stderr override를 새로 넣지 않는다. Installed C:/Python314/Lib/subprocess.py의 Windows handle setup은 redirect된 stdin과 함께 inherited stdout/stderr standard handles를 전달하는 경로를 사용한다. Console handle과 standard pipe handles는 별개지만 실제 출력과 EOF, short exit 처리, 정상 및 timeout의 동작은 별도 Windows 관측이 필요하다. 이 normal 시험은 stdout marker/EOF와 stderr EOF를 확인한다. 별도의 비어 있지 않은 stderr positive나 timeout/출력초과는 이 범위에 없다. [Microsoft Redirected Input and Output](https://learn.microsoft.com/en-us/windows/win32/procthread/creating-a-child-process-with-redirected-input-and-output)

새 broker에는 breakaway 플래그를 추가하지 않는다. Windows Job의 기본 child membership이 유지되는지 보유 HANDLE로 실제 확인한다. 같은 Windows host의 결과를 Godot wrapper나 다른 platform에 일반화하지 않는다. [Microsoft Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects)

## 실행 후보와 한정 완료

- 기존 원문을 보존하고 새 broker 사본의 호출 한 줄만 수정했다. 기존 observer allowlist는 동일 Python image 하나다. 실제 ownership이 양성으로 확인된 mismatch HANDLE은 이번 후보에서 drain 검증이 끝날 때까지 보유한다. 발견된 다른 image는 계속 실패다. Cleanup이 실패하거나 retained handle signalled를 읽지 못하면 종료 검증에 실패했다는 자료로 남긴다. Job 밖 프로세스를 조회·정리하지 않는다.
- PYTHON-JOB-NOWINDOW-MANIFEST.json은 동일 Python payload와 기존 case/outer watchdog, exact new broker/controller/supervisor argv, env와 scratch, protected/source SHA를 고정했다. Prior #2 evidence digest도 포함했다. 재심 승인된 bytes와 외부 승인 SHA 없이는 시작하지 않는다. Default managed sandbox에서만 실행한다. 기존 원본/P03/worker/index 및 HEAD/ref를 전후 확인한다.
- 25초 global, 3초 bootstrap/barrier, 3초 normal inner·10초 case outer, 2초 drain 및 separate journal cap과 별도 owned sentinel은 기존 normal 진단 계약대로다. Positive 판정은 Python payload marker, 실제 observed owned members, exact Job active 0/retained HANDLE signals, exit/EOF 및 sentinel의 정상 종료와 원문 보존을 요구한다. Console host를 더 이상 관측하지 않아도 해당 시험에서의 결과일 뿐, 과거 실패를 소급 확정하거나 정상·timeout 전체를 통과한 것으로 확장하지 않는다.
- Mismatch가 다시 나오면 raw PID/path/creation/membership, retained signal 및 최초/cleanup 오류를 로컬에 보존하고 실패 종료한다. 원본 path는 사용자 응답에 노출하지 않는다. 추후 OS helper 허용을 별도로 검토한다면 승인된 Windows binary의 exact canonical path·SHA·Authenticode, 실행 당시 owned lineage와 retained HANDLE evidence, 비승인 helper 거부 테스트가 필요하다. 이번 후보에는 helper 허용이 없다.

Mock-only 시험에서 한 flag와 stdin/EOF의 기존 계약, mismatched retained HANDLE의 drain 검증을 확인했다. Python compile 및 review-only CLI가 실제 child 생성 전에 차단되는 것도 확인했다. Native Windows 플래그 동작, 출력·Job cleanup은 미실측이다. 기존 실패 2회 기록을 유지하며 독립 심사 전에는 마지막 비제품 실행을 하지 않는다. K6 한 회 보존.
