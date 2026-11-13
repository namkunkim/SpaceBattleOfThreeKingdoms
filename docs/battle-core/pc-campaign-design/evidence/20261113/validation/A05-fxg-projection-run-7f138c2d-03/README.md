# A05 FX-G projection 준비 실험

기준 커밋 `7f138c2df7f1a55118bf9a5b7e251703049d5bb6`에서 Godot 4.7.2.stable.official.ed1daf0bf로 실행했다. 검토 설계 SHA-256은 `C2FF6278229C71414E81D49598BC91232A86439DBD0A11010084E3558368D4EB`다. P06의 projection 인수 범위 결정, 실제 제품 속도 제어 및 배포 화면 검증, 종결 이후 상태 복원은 실험 범위 밖이다.

## 계측 전 원본 진입점

1. `fixture-freeze.json`을 작성하고 SHA-256을 확인한 후 호스트 장면을 headless로 인스턴스화했다. 실제 `load_runtime_file → prepare → Adapter.create`를 거쳐 `host.advance`를 호출했다. `base-host-first-natural.json`의 원시 시계는 (0,0), (1,100), (2,150)이다. 최종 상태는 `over=true, win=true, reason=annihilation, end_ms=150`이며 종료 이벤트는 한 번이다. 실제 호스트 Clock 라벨 문자열도 보존했다.
2. 소스 계측을 추가하기 전 실제 `tests/autoresolve.gd --operation-input` 및 `--operation-replay`로 기준과 J=210을 실행했다. 두 경로의 summary, 이벤트 및 입력 해시가 각각 일치하고 기준은 최초 호스트 실행과도 일치한다.
3. J 원본 x만 200에서 210으로 바꾸자 유효 A/B x는 400/450에서 420/470으로 이동했다. 세 경로의 입력 해시와 결과 fingerprint가 함께 바뀌었다. 섬멸 종료 시간은 150ms였다.

## 격리 계측

`schedule-probe.diff`는 scratch의 CLI와 replay 실제 루프에서 첫 summary, owner advance 직전 허가, 후속 summary, 루프 종료 관측만 추가한다. `a05_host_schedule.gd`는 같은 probe로 실제 호스트의 수동 advance를 구동한다. 각 프로세스마다 APPDATA를 별도 폴더로 설정했다. `matrix-r2`의 기준 18개와 J 대조 3개 모두 종료 코드 0이며, 각 원시 행·summary·이벤트·입력 해시를 `verify-evidence.py`로 검사했다. 배속은 테스트가 실제 TickClock에 전달한 합성 wall delta에 적용된다. 첫 틱에서 250ms 두 번 정지했을 때 허가가 0이고 시계는 100ms였다. 원래 속도로 재개하면 150ms에서 종결됐다. 종결 후 정지 및 재개에서는 owner.advance가 추가 호출되지 않았다. 원래 summary 사본에서 clock_ms/end_ms를 200으로 치환하면 같은 판정기가 거부한다.

입력 동결 폴더 -01 및 -02에서는 동결 검사에서 정수/실수 표현 차이로 종료했다. 비교만 조정했고, -03에서 최초 자연 종료가 기록됐다. 이전 트레이스의 Godot class/UID/import 캐시를 복사했다. 해당 복사본의 확장 목록에 설치되지 않은 선택적 Windows 네이티브 DLL 항목이 있어 scratch 캐시 목록을 보관용 이름으로 이동했다. 원본 장면·owner·실행 입력의 DLL 의존 경로는 사용되지 않았다. 첫 행렬은 Callable 호출 표기 오류에서 중단됐다. r2에서 호출 표기만 고치고 진단 종료 상한을 추가했으며 계측 전 입력·결과는 그대로 보존했다.

## 주요 증거 SHA-256

| 파일 | SHA-256 |
| --- | --- |
| fixture-freeze.json | C6182174EC8ACD5154DBA27ADCF1270A25EA28309653881954DC91A2A388C578 |
| base-host-first-natural.json | 14D61C93A5247844F8C63C609D44A6A6854FE31A378EEE5163DBDAEB0AA6E8DE |
| base-headless-result.json | 0F37ED4497A6BE09437FBE08A7320120F5935CF22C051A03B3BD1FCD7F8FDB10 |
| base-replay-result.json | 44C66D7F0C7480361DE63D7D5AFCA13F3185C063280D8A7FDB7EAE7A0538D6B8 |
| schedule-probe.diff | C97FCAF38BCD50A9DF9F91094EFF2F635DCD124BD1031C0B8C6C294ACE7AD12B |
| evidence-verdict.json | EBC18B0E5DD41F722DD0A7F5E83770E51810F1C8227C072E4CED3B81BF7E7F6E |

