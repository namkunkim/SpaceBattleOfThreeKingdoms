# PC0 소유 Job 개정 v2 독립 계획 심사

판정: **준비 범위에 한해 수용한다. 실제 runner/manifest와 run02는 별도 독립 심사 전 미승인이다.** `PLAN-PC0-OWNED-JOB-REVISION-V2.md` SHA `db787a14eca03e789bcbb175eaf84fe54855c336c14f63fe0137c5741de28080` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job은 실행하지 않았다.

V2는 기존 PC0 상한을 최초 1회+추가 최대 1회로 바로잡고 run01을 1/2로 산입한다. 마지막 run02는 관측된 단일 member 가드를 다루는 수정·준비물 독립 수용 후 한 번만 검토하며, 실패·중단 뒤 반복하지 않는다. 기존 Python-only K3 세 실패를 별도지만 관련 위험의 이력으로 보존하고, 여덟째 후보 K6 한 회를 새 PC0 성공에 합산하지 않는다.

root의 정확한 suspended process/thread HANDLE·고정 실행 파일·Job 회원 확인 후 resume, 입력은 해당 root의 검증된 HWND로만 제한하는 경계는 적절하다. 여러 member가 있는 전용 Job을 ownership/cleanup 단위로 취급하면서 이미지 신뢰나 GUI 입력 대상으로 자동 승인하지 않는 구분도 타당하다. Job HANDLE 비상속, breakaway 미허용 및 기존 사용자 프로세스 검색/assign/종료 금지가 실제 구현에 반영돼야 한다. 현재 파일 경로 SHA는 실행 중 적재 이미지 자체의 완전한 신원 보장이 아님을 유지한다.

구현 재심에서는 root exit code와 root HANDLE signal·Job active 0·실제로 보유한 member HANDLE signal·flush를 각각 기록하고, 미관측 단명 member의 개별 identity/exit를 만들지 않는지 확인한다. PID 재사용, Job list 열람/퇴장 경합, access 거부, 버퍼 한도·notification 누락, assign 실패의 resume 0, timeout/abort 및 drain 오류에 대한 합성 반례를 둔다. Root가 정상 종료한 뒤에도 자손이 남으면 단계 deadline의 남은 시간 안에서 최대 10초만 대기하고, 이후 소유 Job만 정리하되 초과/정리 불능은 실패다. 관측 불가능한 member의 image가 있다는 이유만으로 임의 프로세스를 신뢰·GUI 대상으로 삼지 않는다. 완전한 자손 이름/종료 시각을 보장한다고 주장하지 않는다.

run02는 새 복제·user/cache/log로 시작하고 run01의 `.recovery_mode_lock` 및 부분 import를 건드리지 않는다. 원본 HEAD/index·P03 +9·worker·사용자 cache의 전후 관측을 수행하며 동시 drift를 복구하거나 stage하지 않는다. 승인된 source/overlay/oracle, import 성공·cache 확인 후 GUI, 실제 입력·자연 종결·결산 1회, 1,920초와 별도 cleanup 예산을 유지한다. 1,470파일 등 숫자만으로 closure가 실제 일치했다고 판정하지 않고 정확 manifest SHA 및 기존 PC0 검증기에 연결한다.

다음 유한 작업은 Job/감독 코드와 synthetic·review-only manifest를 준비하고 exact argv/env·source SHA·보호 범위·시간·결과 원문을 독립 재심하는 것이다. 이 수용은 제품 실행을 포함하지 않는다. PC0은 legacy 기준선이며 활성 P03 결합, 실제 operation/P07 목표·철수, 사람 플레이 및 전체 P02 완료가 아니다.
