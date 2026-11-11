# 진행 중 작업 인계

기존 후보와 증거의 대조 기준은 `c9338f2c739af6bdcd362c39bf4a54cd9471c28a`이다. 아래 검증은 각 기록의 당시 입력과 실행본에 귀속된다. [원본 경로·크기·SHA-256](sources.json)

## K6

17행은 이전 최신 지도 이동장에서 11,350틱·1,134,950ms·연합군 승리, 역사 이동장에서 10,550틱·조조군 승리를 각각 재현했다. P02의 두 우선 체크리스트에 입력 차이와 지문을 기록했다. REVIEW-15는 이전 입력 범위에서 독립 ACCEPT 후 정식 FAIL(관측 1/58, 통과 0/58, 완료 0/21, 비교 실행 0/27)이었다. 15-before의 Sky act 응답 형식 불일치에서 중단됐다. revision 02는 무입력 모의 독립 PASS로, 당시 원본 및 검증 SHA는 두 체크리스트에서 확인할 수 있다. 새 EntryBoot 및 15·16행의 입력 경로를 포함한 동결과 독립 재심이 남아 있다. 이 인계에서 정식 실행과 실제 입력을 수행하지 않았다.

- REVIEW-15 manifest SHA-256 `19991b5b473e9185303dfdf3b900cbfb52968390238320b74d5dcc27b87054f4`.
- REVIEW-15 실행 독립 검토 SHA-256 `4fe0668dd94fab5fcb09ab55d83643fda49bc5f7bd647b76f0b4f454c8d55365`.
- revision 02 독립 검토 SHA-256 `3111cf2ea9eba1b150ec03456c2f294d3280c9d4080285133ffc96cbc8733d17`.
- 최신 K6 담당의 정적 인계 SHA-256 `f25f4309c0ab8663b014c8dd3814cf71009bbad648346472a2e26ca63a8c74f4`.

## P09

main의 flow replay 소유권 수정과 P09 종료 차단은 이미 체크리스트에 있다. flow/group 기능과 TRACE는 확인됐으나 종료 잔류는 flow 54/18 → 59/20, group 2/1 → 0/0으로 반복 결과가 달랐다. 제품 없는 WAV/AudioStreamPlayer 최소 재현에서 owner 소멸 뒤 오디오 6개가 남았다. 참조 소멸을 관찰한 대조에서는 15프레임·84ms 뒤 해제됐다. 고정 대기 시간을 제품 수정으로 채택한 기록은 없다. [진단 패치](p09-playback-capture-gap.patch)는 한 프레임의 play→stop→play→stop에서 이전 playback 두 개가 생존하고 finished가 0회였던 반례를 재현한다. 해당 조사들의 담당 범위는 마감됐으며 전체 playback 수집과 종료 검증은 P09 후속 범위다.

## I01 및 P02/P03

- I01 역사 문서 5건은 main에 이미 있었으며 로컬 사용자 폴더 표기만 치환했다. 치수·r5 코덱 소스도 main에 있다. 정적 게이트 잔여표, I01 승인 원본 지문 대조, 해당 패치 및 P02 기준선 기록은 [원본 목록](sources.json)에 해시를 남겼다.
- 별도 I01 후보는 `.gitattributes`와 `data/scenarios/red_cliffs_208_realtime.json`, `data/profiles/combat_m3.json`을 다뤘다. 양쪽 autocrlf 설정에서 핀 4개와 정책 로더가 통과한 증거는 필요한 소스만 갖춘 fixture에서 얻었다. 후속 main 커밋 `d8ef8313278f26d0c1fe4f9e6c9783c3875d19d8`은 체크아웃 규칙으로 승인 입력과 규칙 스크립트 바이트를 보존한다. 배포 저장 호환성은 별도 검증 범위다.
- P02/P03 신규 진입 전 기준선에서 승인 입력 4개와 core 40개 SHA가 일치했고 제품 경로 12/12 및 준비·전환 실패 회귀를 확인했다(실제 엔진 PID 23404, exit 0). [제품 탐침](entry_product_baseline.gd.txt)과 [실패 탐침](entry_failure_baseline.gd.txt)은 당시 기준선 자료다. 별도 승인 적벽 v1 회귀에서는 0틱 시작, 첫 명령 1회 적용, 5틱 복원, 결산 1건, 완료 슬롯 거부를 확인했다.

## 플랫폼 후속

이전 격리 후보 `0a6abf9d478969b05a2076af9640d08b5daa89f7`의 변경 424개 중 동일 140개, 줄끝만 상이 203개, 양측 내용 상이 5개, 후보에만 있는 변경 76개다. [나머지 81개 경로와 처리 근거](candidate-delta.json)를 기록했다. 후보에서 검증한 일반 출격 카드 간격, 출격 중 범례 숨김 및 타이틀·일시정지 배치 차이는 [UI WIP 패치](platform-ui.patch)에 있다. 실제 제품 지도 연결 작업은 01a1c9b5 담당이며, 패치를 적용할 때 같은 지도 화면 변경을 대조해야 한다.

- Windows에서 기존 검증 EXE·DLL의 SHA가 일치했다. 480×270 전경의 시작·서사·항로도에서 본문·진행 버튼·지도 표식의 가독성이 미통과였고 준비 화면까지의 전체 흐름은 미확인이다.
- Android arm64 디버그 APK SHA-256은 `a96652652914db6ef4125c577ab64d7c3e393f2b62ce1b836e8ed613b4b19d41`이다. 테스트 서명 v2/v3, ZIP CRC, 16 KiB 정렬, 런처, minSdk 24·targetSdk 36, 진입 씬·도감·항로도 자산을 확인했다. Windows 전용 O07 확장 등록이 남아 Android 라이브러리 경고가 발생했다. Android 설치·시작과 실제 Windows 터치·패드 입력은 장치 미검증이다.
- O07의 [Windows 빌드·운영 인계](../../../entry/o07-windows-release-and-operations-ko.md)는 배포 문서다. 실제 운영 슬롯 전환과 외부 지급 검증은 남아 있다.

## 적벽·오림 시안

[적벽 상세 HTML](red-cliffs-detail.html)은 지도 구현에 참고할 당시 시안이다. 강릉–동정호 항로 위 적벽 `(852.5, 510)`과 북서쪽 오림 `(834, 487)`을 담았다. 제품 상세 및 출격 연결과 새 맵의 태양계권·구지 경로 제거는 01a1c9b5 채팅에서 진행 중이다. HTML은 Codex 시각화 환경의 CSS 변수와 테마를 사용한다.
