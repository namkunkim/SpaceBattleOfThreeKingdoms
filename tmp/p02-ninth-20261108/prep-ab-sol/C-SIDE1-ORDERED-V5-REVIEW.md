# C side 1 v5 순서와 provenance 보강

v4 및 독립 심사 원문은 보존했다. v4의 실제 구현은 capture 집합을 확인했으므로 문서가 주장한 capture 순서를 검증하지 못했다. v5는 canonical lane→instance→seed→case→phase 목록을 별도로 만들고 각 위치의 exact key와 side 1 빈 records를 검사한다. Canonical phase는 원 case 다음 repaired다. 비교 순서를 맞추려고 raw 로그를 임의 정렬하지 않는다. Raw stream이 process 간 병렬로 전달된다면 manifest의 고정 file order 및 각 file의 원래 event ordinal로 assemble하고 raw 원문을 보존해야 한다.

`verified_sources`는 심사된 fixture source manifest의 상대 경로를 지정된 root 안에서 읽고 각 SHA-256을 다시 계산한다. 이전에 합의한 canonical JSON key sort 및 compact encoding의 digest도 확인한 뒤 v4 proof 검증에 전달한다. 현재 manifest는 6개 파일로 한정된 정적 부분이다. 제품 실행용 full source closure나 input manifest로 사용하지 않는다. 이 검사는 호출 시점의 바이트 비교이며 execution 시점을 직접 증명하지 않는다.

실제 실행 전에 아래 결합 구조가 필요하다.

1. Launcher는 별도 review-approved SHA의 전체 source/overlay/fixture/engine/cache manifest 및 lane ID를 읽는다. 현재 root가 아닌 읽기 전용 격리 복제본에서 각 파일의 bytes를 시작 직전과 종료 직후 확인한다. Reparse와 경로 우회 방지는 실행기/격리 경계에서 확인한다. 두 시점 사이 교체 부재를 샘플만으로 주장하지 않는다.
2. 실제 producer는 `Detection._eval` 진입 직전에 raw fixture inputs 및 상태를 캡처한다. Each stream header는 run UUID, lane, exact argv/engine SHA, source/overlay SHA, owned process creation time·PID, and clock baseline을 포함한다. 각 receipt는 해당 stream의 single-writer sequence, simulation instance ID, seed/case, phase 및 authoritative tick과 monotonic stamp를 포함한다. User 입력 또는 restore route의 상태를 producer가 추측해 채우지 않는다.
3. 초기 빈 상태 → 평가 snapshots → restore request/result receipt → source/target capture의 경계를 sequence·identity로 결합한다. 동일 identity에 first and repaired의 올바른 source/output 연결을 요구한다. Original output 파일의 해시를 launcher가 종료 직후 기록하며, 병합 문서는 각 원본 line offset과 hash를 보존한다. Stream에 누락·중복·phase 변경·binding 불일치가 있으면 거부한다. Hash는 바이트의 무결성을 확인한다. Producer의 실제 평가 시점 및 기능을 검토하고 외부 lifecycle evidence와 대조해야 한다.
4. 현재 실제 producer, receipt chain과 full closure의 독립 검증은 미구현이다. File bytes와 단순 입력 문자열만 바뀌지 않았다는 사실은 실제 `_eval` 시점·실제 Godot capture 증거가 아니다. Restore receipt·typed bytes·detach는 계속 별도 검증이다.

합성 검사는 canonical 160 및 unchanged bytes 정상 2건과 역순, phase 교체, lane block 교체, 중복, 누락, stale bytes, missing source 등 반례 8건을 검사했다. 첫 합성 파일 입력의 임시 디렉터리 쓰기 권한 오류를 확인한 뒤 workspace evidence 폴더에 임시 폴더를 지정해 동일 검사를 완료했다. 엔진·제품·GUI·Job은 실행하지 않았다. K6 한 회는 남아 있다.
