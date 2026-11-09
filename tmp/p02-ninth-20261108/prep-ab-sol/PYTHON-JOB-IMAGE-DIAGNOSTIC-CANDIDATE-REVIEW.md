# Python 소유 이미지 단일 normal 진단 실행 후보

이 문서는 독립 심사 전 review-only다. 기존 승인 one-shot의 exit 1 및 0/6을 보존한다. 허용 목록 확대, 파일 복구, 실제 재실행은 하지 않았다. 그때 누락된 image 값은 현재도 미확인이다.

## 한 사례와 예산

별도의 비제품 Python 진단 시도 상한을 K=3으로 제안한다. 기존 실패 1회를 포함하며 이번 후보는 normal 한 사례에 한해 다음 2번째 시도다. Independent 승인 후에도 한 번만 실행한다. 실패·미관측·출력 누락·중단 시 자동 재시도하지 않는다. 마지막 3번째 기회는 이번 manifest에 없으며 신규 근거와 독립 심사가 있을 때만 검토한다. 이 진단 예산은 제품 K6과 별개다.

variant-abi-review/PYTHON-JOB-IMAGE-DIAGNOSTIC-MANIFEST.json은 기존 신뢰 Python, V5 broker, bounded 외부 watchdog 및 새 diagnostic Owner/supervisor의 SHA, exact argv templates/env, 단일 normal 예상과 fresh scratch를 고정한다. Prior one-shot 승인 SHA 및 결과 evidence SHA도 별도로 기록한다. Candidate status로 CLI를 실행하면 scratch·자식/Job 생성 전 거부함을 확인했다. 독립 승인된 새 bytes와 digest 없이는 실행할 수 없다.

## 판정과 원인 분리

DiagnosticOwner는 기존 실제 allow 판정의 os.path.normcase(str(Path(path).resolve()))를 유지하고 동일 Python executable 하나만 허용한다. ntpath lexical 값은 설명용 별도 필드다. Lexical match가 original resolver의 mismatch를 뒤집지 않는다. 정상 spelling·별칭·중간 경로 변경이 동일 실행 이미지 bytes임을 추정하지 않는다.

정확한 owned Job list에서 얻은 retained HANDLE의 membership·alive·PID·creation을 확인한 뒤 OS raw image를 읽고 동일 identity/membership을 재검사한다. Mismatch 시 stage, PID, creation time, membership, full raw image path, lexical 및 original resolved path, allowlist를 한 bounded diagnostic frame에 기록한다. 경합·단명·Win32 거부 또는 누락 시 성공하지 않으며 타 프로세스로 재조회하지 않는다. 분기 내에서 예상 밖 이미지 파일의 내용을 읽거나 해당 path를 자동으로 허용하지 않는다. argv/env 또는 process contents는 수집하지 않는다.

개별 path pre-cap 768자와 JSON escape를 포함한 사전 상계, serialized frame 14,000 bytes를 적용한다. 이상한 길이 또는 field shape는 불완전 진단으로 표시하고 primary mismatch를 성공으로 바꾸지 않는다. Controller/global diagnostics는 각각 합계 32KiB이며 old payload cap 256KiB와 별개다. 최초 observation을 기록한 뒤 cleanup의 missing payload/receipt 오류와 별도 failure-separation을 남긴다. Pipe 및 journal 손실, output cap, Job drain이 검증되지 않으면 실패다. 진단에 raw path가 있더라도 일반 사용자 응답에는 해당 raw 값 대신 판정만 적는다.

## 운영 및 완료 조건

Default managed sandbox만 사용한다. 새 source/manifest 및 기존 6개 보호 SHA, resolved HEAD/ref, scratch/guard/diagnostics의 부재를 실행 직전 재확인한다. Existing V5 inert broker, exact Job HANDLE pre-release, case Job 밖의 소유 sentinel, bounded global watchdog 25초와 bootstrap/barrier 3초, normal inner 3초·outer 10초, drain 및 journal 2초를 유지한다. 예상 밖 process나 미관측 HANDLE은 원인 기록 후 소유 Job만 정리한다. 사용자의 기존 앱·프로세스는 관찰하거나 종료하지 않는다. 실제 Windows HANDLE 수명·경합·pipe flush는 이 코드만으로 보증하지 않는다.

판정은 다음 중 하나다. 정상 payload/ownership/cleanup 성공 시 재현 실패로 남긴다. 동일 종류 mismatch가 재발해 identity·path·원인·cleanup이 각각 기록되면 진단 자료를 확보한 실패다. 관측이 없거나 전달·cleanup 증거가 없으면 미확인 실패다. 모두 이전 실패의 원인을 소급 입증하지 않으며 allowlist 확대를 승인하지 않는다. 후속 ABI/Godot/GUI/제품 실행은 별도다.

합성에서는 lexical 값이 일치해도 original resolver의 다른 경로를 허용하지 않았고, path 및 encoded bytes의 사전 cap과 primary/cleanup 분리를 확인했다. Python compile 및 review-only guard 외 실제 child·Windows Job·Godot·GUI·제품 실행은 0회다. K6 한 회가 남아 있다.
