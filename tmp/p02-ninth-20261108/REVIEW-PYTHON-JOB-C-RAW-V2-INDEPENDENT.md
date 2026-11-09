# Python 소유 Job 시험 및 C raw v2 독립 심사

판정: **C 합성 매핑 정정과 Python 비제품 시험 설계는 제한 수용; 제시된 review-only manifest의 실제 실행은 보류.** `PYTHON-JOB-QUALIFICATION-AND-C-RAW-V2-REVIEW.md` SHA `109344da11a9e801a32b7e5f2694d7de2b037bdc3aecf84ede1abebfb7edc480`, SHA 목록 `6dfae5606706f4136aa9759c9db7f9e17689a89a20c1f5490257f1524499f20a`, manifest `b8ce16488e16ccb18b61475526e0f6d6f1094c693bdb58295ca9e8cce08bca6f` 확인. 심사 모델 gpt-6.1-terra. Python child·Job·Godot·제품·GUI를 실행하지 않았다.

C v2는 lane 전체의 source-derived ordered events와 seed/tick/sim ID의 정확한 Python int를 검사하고 `restore_pairs`에서도 필터 전에 검사한다. v1의 bool/int 혼동 지적은 코드에서 해결됐으며 합성 5,080 rows 정상 및 15 거부는 보존 로그에 있다. 다만 원본 raw 생산기와 실제 schema/순서, v4 geometry 및 v7/v9 packet·context·alias/suffix 결합은 미실측이다. 이 합성 수는 20 detection segment의 해당 lane 사건이며 실제 제품 결과가 아니다.

Python payload는 정적으로 제품/fixture/cache를 사용하지 않고 단순 marker·sleep·유한 출력만 수행한다. 정확 Popen broker HANDLE을 각 private Job에 할당하고 해당 Job만 drain하며 별도 sentinel을 case Job 비구성원으로 확인한다. 계획된 낮은 위험의 시험은 product 검증이 아니므로, 실제 제품 import/fixture 실행이 없다면 K6 최초 제품 spawn을 소진하지 않는다. 전체 6 case의 cap과 90초 guard, 2초 drain 및 전후 protected SHA는 유한 경계로 적절하나, **아직 실행 실측 증거는 아니다.**

실행 수용을 위한 남은 최소 조건은 새 제약의 무한 추가가 아니라 다음 구체 항목이다.

1. 독립 심사 후 exact source·manifest SHA/status와 guard argv/env·fresh scratch를 고정한다. Guard가 사용하는 외부 tool의 종료 시점에서 guard와 owned Job이 정리되는 방법을 확인한다. 현재 90초는 guard 진입 후 시작되므로 최초 Job 생성/barrier 및 최종 fsync의 영구 차단을 단독으로 다루지 않는다. 외부 bounded stop이 사용 불가능하거나 owned tree 종료를 입증할 수 없으면 미완료로 닫는다. OS 권한 확대 없이 현재 default sandbox에서 실행한다.
2. 종료 전에 sentinel이 정확히 해당 case Job 밖이고 살아 있는 것과 시험 소유 Popen HANDLE을 확인한다. 어느 경로에서도 PID 검색으로 타 프로세스를 종료하지 않는다. 실제 nested Job 거부 또는 빠른 child HANDLE 미관측은 실패/미검증이며 주입된 observation-negative를 실제 API 거부로 기록하지 않는다. output-cap은 256KiB 공유 retained 및 EOF/drain을 확인한다.
3. 현재 supervisor가 controller stdout/stderr를 DEVNULL로 넘기므로 실패 시 원인이 상실될 수 있다. 최소한 각 case의 종료·failure stage, missing receipt와 owned drain을 outside journal에서 구분할 수 있도록 구체적으로 고정하고, journal/fsync 실패 자체를 실패로 남긴다. `outer-stall`은 synthetic stall이며 실제 fsync hang 근거가 아니다. scratch 및 protected HEAD/index/P03/worker 전후 bytes와 예상 밖 쓰기 검사의 범위를 기록하되 샘플 사이 변화를 부정하지 않는다.

위 조건을 반영한 구체 실행 문서와 코드가 독립 수용되면 일회성 Python 시험을 진행할 수 있다. 별도 OS read-deny를 임의의 보편 선행 조건으로 추가하지 않는다. 실제 engine ABI, GUI 요청별 귀속 및 21행은 별도이며 이 시험의 성공을 대체 증거로 쓰지 않는다. 기존 실패·K1~K5와 마지막 K6 한 회, P03 작업 및 기존 source를 보호한다.
