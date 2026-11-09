# 비제품 Job 전역 watchdog 시험 계획

상태는 실행 전 독립 심사용이다. K6, 원본 제품과 제품 fixture는 범위 밖이다. 새 전용 디렉터리와 최소 프로젝트만 쓴다. 실제 user desktop에 창을 전면화하거나 입력을 보내지 않는다.

## 정확한 경계

- 엔진 경로 C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe SHA c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643. GUI exe SHA ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424. 호출 직전 검증한다. Python exe와 V5 owned_job_v3.py도 SHA를 고정한다.
- Outer supervisor는 V5와 동일한 inert broker 생성 및 attach/barrier 방식을 사용해 별도의 Python controller를 outer Job에 넣는다. Controller는 기존 V5 broker로 각 payload를 inner Job에 넣는다. Outer process의 시간은 stage 이전부터 monotonic으로 시작한다. Job handle 및 child handles는 생성 시 확보한다. 보유 handle과 creation time/image path/hash로 PID 재사용을 배제한다. Outer/inner membership은 각 프로세스에서 실제 확인한다.
- 새 전용 경로 아래 project, APPDATA/LOCALAPPDATA/XDG, TEMP, cwd, 출력을 전부 별도 지정한다. 상대경로와 reparse point·escape를 거부한다. source 접근은 엔진/runner 읽기와 소유 project만 계획한다. Job의 소유 증거는 filesystem 쓰기 차단과 별개다. 원본/P03 SHA와 index를 전후 비교한다.
- 최소 Godot project 스크립트는 stdout heartbeat 및 PID를 기록한 뒤 빠르게 종료하는 정상 모드와 기다리는 모드만 갖는다. 실제 wrapper가 어떤 child를 생성하는지는 추정하지 않는다. Engine tree가 single process면 그대로 기록한다. 별도 의도적 child 생성 시험은 runtime wrapper 결과와 구분한다. GUI renderer 관측이 필요하면 비공유 격리 desktop 접근성부터 확인하고 승인된 desktop이 없으면 미측정이다.

## 유한 판정 5행

| 사례 | 절차 및 실패 경계 |
|---|---|
| W1 | 최소 headless Godot normal. stage→preverify→engine→postverify→flush의 durable markers, 실제 PIDs/creation time/hash/outer+inner membership, engine exit 0 및 outer·inner drain 확인. |
| W2 | 최소 headless Godot wait. 내부 timeout이 발동해 해당 inner tree만 정리되고 controller는 실패 원문을 쓰고 종료. Outer/inner Job active=0과 대상 HANDLE signalled. |
| W3 | controller의 staging 단계에서 의도적 blocking. 제품 없는 synthetic. Outer cap으로 controller/broker 종료, outside journal에 last stage=staging·hard-timeout·정리 결과. Engine 시작 0. |
| W4 | controller의 postverify 단계 blocking. W1과 동일 정상 engine 뒤 별도 synthetic wait. Outer가 stage timeout을 기록하고 controller만 남았는지/정리했는지 HANDLE로 확인. |
| W5 | 실제 nested policy assign refusal가 관측된 경우만 Win32 code 및 barrier release 0, EOF 이후 inert broker 종료와 child 0을 판정. 관측할 수 없으면 미검증. 다른 실패 또는 모의 반환으로 대체하지 않는다. |

W1~W4 각각 별도 비소유 sentinel은 시작과 종료의 동일 HANDLE로 생존을 확인하고 정상적으로 종료시킨다. 정상 30초, 내부 timeout 15초 및 cleanup 5초, 외부 hard cap 40초·drain 확인 5초를 초기 상한으로 심사한다. Blocking stage 시험은 hard cap 8초·cleanup 5초로 별도 고정한다. 예약·중단 오류는 실패 1회로 닫고 제품 K6와 재시도로 섞지 않는다. watchdog supervisor는 outer Job 밖에서 timeout과 drain 기록을 남긴다. Flush는 main result sink와 다른 supervisor journal 경로를 쓴다.

K6의 약 5시간 38분 V5 산술은 stage/import/closure copy/검증/GUI 관측·사용자 desktop 독점성과 raw 증거 처리 시간이 불확실하다. 이 짧은 실험 결과를 6시간 경과율이나 제품 175초 안정성의 추정치로 승격하지 않는다. 제품 manifest에 실제 비용을 담을 별도 시간이 필요하다.
