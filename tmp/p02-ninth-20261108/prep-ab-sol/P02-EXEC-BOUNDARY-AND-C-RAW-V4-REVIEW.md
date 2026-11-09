# P02 실행 경계 단순화 및 C raw v4 계약

독립 검토 전 자료다. Python 진단 K=3의 실패를 보존하고 같은 Python/V5 계층을 반복 실행하지 않는다. 제품, Python Job, Godot, GUI를 실행하지 않았다. 최초 제품 import/검증 spawn에 해당하는 K6 한 회는 남아 있다.

| 경로 | 근거와 현재 판정 |
|---|---|
| 기존 exec_command 세션만 사용 | 반환 exit/session ID와 foreground 결과는 제공된다. yield_time_ms는 제어 반환 시점, max_output_tokens는 출력 전달 제한이다. 프로세스 hard timeout, raw disk cap과 자손 종료를 증명하지 않는다. functions.wait의 cell 종료와 shell signal도 retained tree 종료 receipt가 아니다. 현재 K6 Job 계약 대체 불가다. |
| 실제 managed 실행 경계에서 Job API 생략 | Tool이 외부 hard deadline, owned tree identity/drain, bounded raw output을 같은 launch receipt로 제공한다면 운영 구조를 줄일 수 있다. 현재 tool에서 그 receipt나 실제 backend 특성이 확인되지 않았다. 독립 설계 수용 없이는 대체하지 않는다. |
| 단순 Win32 direct spawn | STARTUPINFOEX의 explicit Job·stdio HANDLE 목록과 returned exact process/thread HANDLE을 사용한다. Python broker 계층을 제거해 creation에서 소유권을 설정하는 실제 다른 구조다. 구현·실측·승인되지 않았다. |

OpenAI Docs는 Windows sandbox가 활성 파일/네트워크 권한을 자식에 적용한다고 설명한다. MXC의 경우 foreground 명령 종료 시 남은 자식의 종료를 설명한다. 이 turn에서 MXC 사용은 확인되지 않았다. [OpenAI Docs Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox#configure-the-windows-sandbox)

## 유한한 적합성 선택

명시 tool receipt가 없으면 Job-less 경로를 실행하지 않는다. Direct Win32를 선택하면 검증 질문은 지정 Job·stdio HANDLE로 단일 native child를 시작해 같은 HANDLE로 정상/강제 종료를 입증할 수 있는가다. 기존 Python→inert broker→Python worker console-host 정책을 재시험하지 않는다. 동일 Python broker와 같은 동작의 경로 이름만 바꾼 실행은 제외한다.

- 제품 코드·fixture·cache·Godot·GUI를 쓰지 않는 native literal 하나를 normal과 timeout 두 분기로 한 번의 적합성 묶음에서 관측한다. 이 실제 다른 계약의 상한은 K=1이고 독립 수용 전 0회다. 기존 세 실패는 그대로 유지한다. Compiler/build·binary·exact argv/env·source hashes, 의도된 native stdin/stdout/stderr handles와 OS ownership/cleanup 계약을 동결하지 못하면 실행 자체가 없다.
- Child 생성 시 Job 설정 실패는 정상 body 진입 전에 종료한다. Actual process HANDLE/PID/creation/image, explicit membership, 양쪽 pipe markers/EOF, timeout 후 active zero 및 retained HANDLE signals를 확인한다. 5초 normal, 2초 timeout, 2초 drain, 총 15초 global을 제안하며 실제 launcher에서 각각 강제 가능해야 한다. 예상 외 이미지나 HANDLE·output·cleanup 누락은 실패다. 실패 후 반복하지 않는다. Native payload와 독립 승인 pin은 아직 없다. [Microsoft UpdateProcThreadAttribute](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute)
- Tool이나 launcher가 이 경계를 수용해도 실제 제품 21행, GUI per-request 출처, 175/320, immutable engine/fixture/overlay·원본 동결은 별도다. 제품 실행은 최종 manifest 독립 수용 후 한 번만 한다. Staged/HEAD/ref/P03 활성 +9·worker +2를 보호한다. HEAD lane은 활성 P03 결합 검증이 아니다.

## C v4 source-only 보강

c-producer-overlay-review-v4는 side 1 gated observer와 다섯 실제 restore wrapper를 유지한다. Request/result에서 직접 var_to_bytes(packet)을 읽고 HashingContext를 원시 바이트에 적용한다. Raw hex 및 해당 바이트의 SHA를 구분한다. Outer timestamp는 원래 microsecond이며 scoped live receipt만 microsecond×1000으로 v9 ns schema를 만든다. 동률은 유지하고 ordinal로 정렬한다. Request ID, _all pre/post와 scoped live raw bytes가 같은 event에서 나온다.

c_raw_v4_semantic_adapter.py는 launcher whole-file hash와 v2의 5,080행/20 segments per lane 원본 순서를 먼저 검증한다. 각 segment의 5 calls/20 boundaries를 연결하고 packet bytes→SHA→decoded typed packet, source _all, target outside, repeat no-op 및 actual result를 확인한다. Actual source roster에서 선택한 ID와 original scoped live bytes를 독립 pinned v9 case에 전달한다. 한 lane 100 calls이며 양쪽 모두 검증해야 200 calls다. 양쪽 integration runner는 없다.

합성 검증은 원시 바이트 SHA의 양성과 hex text hash, altered bytes, 비정규/odd hex 반례 4개다. 실제 _eval geometry와 v7 causal 전체, v9에 필요한 독립 pin 원문, alias/detach/suffix, parser 및 actual output budget은 미검증이다. 200 calls의 실제 실행이나 전체 합성 통합 통과를 주장하지 않는다. 제품 소스에 오버레이를 적용하지 않았다.
