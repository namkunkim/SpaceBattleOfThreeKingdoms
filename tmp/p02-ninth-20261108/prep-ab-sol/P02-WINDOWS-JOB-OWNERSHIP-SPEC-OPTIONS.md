# P02 Windows 프로세스 소유·이미지 정책 재설계

상태는 독립 검토 전 비실행 설계다. 비제품 Python K=3의 세 실패는 종료됐고 재시도나 새 Python 진단 예산을 제안하지 않는다. #1은 첫 normal에서 종료해 0/6, #2와 #3은 각각 normal 0/1이다. 나머지 다섯 qualification 케이스는 실행된 적이 없다. 실제 제품/Godot/GUI/Job을 이번 작업에서 시작하지 않았다.

## 지금 증거가 말하는 범위

#2/#3의 retained-process 조회 시점에 같은 Windows console-host 경로가 정상 케이스 outer Job 소속으로 관측됐다. #3의 broker가 CREATE_NO_WINDOW를 사용한 것은 원문으로 확인됐지만, 정확히 어느 spawn edge의 helper인지와 이 플래그가 해당 helper의 생성에 직접 적용됐는지는 확인되지 않았다. #1 이미지, 실행 당시 binary/hash/signature/parent는 미확정이다. #3 case Job의 drain 기록은 false이며 global drain true를 해당 HANDLE 종료 근거로 대신할 수 없다. 이력의 원본 경로는 전용 증거에만 두었다.

Windows의 Job membership은 프로세스 그룹의 소유·제한·정리 범위다. 별도 breakaway가 없으면 일반적으로 CreateProcess 자손에 상속되지만, 같은 Job이라는 사실로 특정 spawn의 부모, 코드의 신뢰 또는 제품 결과를 결정할 수 없다. QueryFullProcessImageNameW의 반환도 실행 파일 이름이며 로드된 이미지 bytes나 서명에 대한 증명은 아니다. [Microsoft Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects), [Microsoft QueryFullProcessImageNameW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-queryfullprocessimagenamew)

## 다음 구현 선택지

| 선택지 | 유지되는 계약 | 추가로 증명할 항목 |
|---|---|---|
| 기존 런처에 범위가 명시된 시스템 helper 정책 | Job membership, Python/엔진 승인 경로와 원시 cleanup 요구 | 동일 시스템 파일의 identity·SHA·인증, 허용된 launch lineage 및 정확 소유 HANDLE, 단계/수량 상한, 정리 실측이 모두 필요하다. 현재 증거로 활성화할 수 없다. |
| 단순 네이티브 direct launch | 하나의 소유 execution Job과 정확 engine HANDLE, dedicated pipes, deadline 및 cleanup | Python nested broker를 제거할 경우 사용 runner와 기존 inert barrier 경계가 달라진다. 새로운 승인 manifest에서 실제 engine/fixture/cleanup의 독립 수용이 필요하다. |
| 기존 로컬 Godot 환경에서 승인된 단일 K6 | 이미 사용한 엔진과 local sandbox를 재사용 가능 | Godot을 기존 경로에서 열 수 있다는 사실은 Job/GUI 출처 또는 21행 manifest가 아니다. 별도 scratch/user/cache와 실제 Job 소유, 동일 21행 oracle·P03 보호를 충족하는 경우에만 최종 K6에서 실행한다. |

우선 설계 검토 대상으로 **direct launch**를 제안한다. 미확인 helper의 허용 규칙부터 늘릴 필요를 줄이고, 제품 executable HANDLE의 생성 시점과 소유 경계를 줄일 수 있기 때문이다. Win32의 STARTUPINFOEX에서 PROC_THREAD_ATTRIBUTE_JOB_LIST와 명시된 std handle 목록을 사용하는 방법을 검토한다. Job을 할당하지 못하면 제품 스레드가 실행되지 않는 경로를 독립적으로 확인한다. 대안으로 CREATE_SUSPENDED 뒤 정확한 process HANDLE을 Job에 할당하고 membership 양성일 때만 primary thread를 resume하는 계약이 있다. 둘 다 현재 환경에서 구현·실측되지 않았다. Native direct launch도 console helper가 생기지 않음을 보증하지 않는다. Nested Job 제약, 초기 launcher 신원 및 stdout/stderr 상속·flush·timeout 경계가 기존 runner와 동등한지 확인해야 한다. [Microsoft UpdateProcThreadAttribute](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute), [Microsoft Process Creation Flags](https://learn.microsoft.com/en-us/windows/win32/procthread/process-creation-flags)

### 제한된 helper 정책을 택할 때

1. 원본 이름, 위치 또는 Microsoft 문자열만으로 승인하지 않는다. Candidate 파일의 시스템 경로는 해당 OS build에서 사전 확정하고, 승인된 exact SHA-256, file identity 및 로컬 Authenticode policy를 manifest에 넣는다. Embedded signature 및 catalog member를 구분하고 사용한 확인 정책, chain/publisher 및 trust result를 보존한다. WinVerifyTrust는 Authenticode 정책의 결과로 성공 코드를 확인할 수 있고, catalog hash는 열린 파일 HANDLE에 연결할 수 있다. 파일명에서 다시 연 현재 파일과 로드된 이미지가 동일하다는 별도 연결이 없으면 실행 이미지 검증 완료로 취급하지 않는다. [Microsoft WinVerifyTrust](https://learn.microsoft.com/en-us/windows/win32/api/wintrust/nf-wintrust-winverifytrust), [Microsoft WINTRUST_FILE_INFO](https://learn.microsoft.com/en-us/windows/win32/api/wintrust/ns-wintrust-wintrust_file_info), [Microsoft catalog hash API](https://learn.microsoft.com/en-us/windows/win32/api/mscat/nf-mscat-cryptcatadmincalchashfromfilehandle2)
2. 승인된 launch의 PID, creation time 및 retained HANDLE을 parent/child-start receipt와 연결한다. Parent PID만으로 소유된 lineage를 판정하지 않는다. PID는 재사용될 수 있고 Windows process creation은 caller와 다른 지정 parent를 허용한다. OS helper가 system service를 거쳐 생성된다면 단순 parent equality를 적용하거나 생략하지 않는다. 해당 helper와 console launch를 독립적으로 연결할 수 있는 출처가 실제 제공돼야 한다. PID/creation time만 비교하거나 broad tracing에서 unrelated argv를 수집하지 않는다. Ownership/lineage/identity 어느 하나가 없으면 허용하지 않는다. [Microsoft Process ETW fields](https://learn.microsoft.com/en-us/windows/win32/etw/process-v2-typegroup1), [Microsoft UpdateProcThreadAttribute](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute)
3. 허용된 role, 최대 생성 수, 단계·시간과 expected image closure를 명시한다. 경로 변경, 서명 실패, 다른 Microsoft-signed 파일, PID 재사용, membership 변동, 누락된 birth receipt는 모두 실패다. Current verified list를 벗어난 helper라도 **이미 같은 전용 Job의 소유 HANDLE**이라면 진단용으로 해당 HANDLE만 유지하고 실패 종료한다. Job 바깥 프로세스의 이름을 검색해 종료 대상으로 보충하지 않는다.

### 어느 경로든 공통

- 실행 전부터 정확한 전용 Job과 소유 process HANDLE의 membership을 확인하고, 정상 종료와 timeout 모두 bounded deadline 이후 active count 0 및 각 retained HANDLE signalled를 각각 기록한다. 실패 시 TerminateJobObject의 결과와 실제 drain을 분리한다. Completion-port 메시지는 관측 보조다. Microsoft 문서상 일반 Job 알림은 일부 예외를 빼면 전달을 보장하지 않으므로 메시지 부재를 자손 부재로 바꾸지 않는다. 소유자와 무관한 sentinel 또는 사용자 프로세스의 실행을 건드리지 않는다. [Microsoft Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects), [Microsoft TerminateJobObject](https://learn.microsoft.com/en-us/windows/win32/api/jobapi2/nf-jobapi2-terminatejobobject)
- 21행의 기존 제품 요구, 175/320, argv/env, immutable engine/fixture/overlay/project 및 독립 oracle을 유지한다. 실행기 변경으로 동적 분모나 실제 OS input을 합성·과거 PASS로 치환하지 않는다. Sky per-request GUI 귀속은 Job 소유·helper 서명과 별도이며 계속 미입증이다. Native product/GUI를 확인하려면 이 게이트와 현재 미완성 C/Q/B producer·독립 oracle을 먼저 최종 manifest에 고정하고 별도 심사를 통과해야 한다.
- HEAD와 index/ref, P03 private state 활성 +9와 worker test +2의 보호 SHA를 다시 확인한다. HEAD lane을 선택하면 P03 활성본과 결합된 제품을 검증했다고 하지 않는다. 새 설계는 K=3을 다시 시작하거나 과거 Python 실패를 지우는 근거가 아니다. 제품 최초 import/검증 spawn부터 남은 K6 한 회가 소진된다. 지금 어느 선택지도 실행 승인되지 않았다.

## C source-only 증거 보강

c-producer-overlay-review-v3는 이전 metadata-gated pre-eval과 원문 복원 5회 wrapper를 보존했다. 두 review 사본에서 각 restore의 scoped live snapshot과 run-local target-scope/phase request ID, 동일한 actual packet의 직접 var_to_bytes hex를 기록하는 필드를 추가했다. Before/after 실제 packet을 각각 읽으므로 같은 hash를 복사해 무변이라고 주장하지 않는다. packet_hex_sha256은 명시적으로 lowercase hex 텍스트에 대한 SHA다. v7의 raw-byte SHA와 동일하다고 취급하지 않으며 verifier가 원문 hex를 decode해 독립적으로 raw hash를 산출해야 한다. 추가 receipt metadata의 단위는 microsecond 그대로이며 기존 v9 snapshot shape로의 단위·구조 변환, full _all/detach/suffix와 v4/v7/v9 실행 통합, GDScript parser 및 bytes/output/time budget은 미검증이다.

기존 제품/테스트/P03/HTML/Git 파일에는 overlay를 적용하지 않았다. 해당 source, review copies와 diff SHA는 c-producer-overlay-review-v3/SHA.json에 있다. Source-only 자료의 생성은 K6 실행이 아니다.
