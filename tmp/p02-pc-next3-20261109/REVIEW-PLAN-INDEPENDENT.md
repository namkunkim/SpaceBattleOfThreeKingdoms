# 직접 출격 난이도 정합 독립 계획 심사

판정: 결함과 11행 목표의 준비는 수용한다. 현재 문서는 구현 및 엔진/GUI 실행 계획으로는 반려한다. 네 난이도 규칙·roster 기대값의 실제 독립 계산 방법, 행별 명령·fixture·정확한 판정 ID/timeout/예상 진단·before 실패 분모, GUI 실제 입력 및 창 ownership, source closure·disk peak·재시도 예산이 아직 정해지지 않았다. 사용자 확인이 아닌 구체 후보와 실행 명세를 마련해 재심한다.

시나리오 데이터 원문에서 cao_fleets 9/10/14/14 및 AI suspicion_per_s 0.4/0.8/1.5/2.0은 확인된다. 같은 수의 상급/극한을 구분할 규칙값이 필요하다. 다만 이 숫자는 프로필 원문의 한도와 AI 설정이며 자동으로 실제 초기/지연 roster라는 뜻은 아니다. 독립 오라클은 원본 구성·출전 순서·배치 지연 및 선택 규칙을 정적으로 명시하고 실제 sim에서 전체/즉시 roster와 유효 AI 설정의 적용 경로를 확인해야 한다. 프로덕션 Organization/ScenarioProfile을 그대로 기대값 생성에 재사용하면 자기검증이다. 난이도 라벨만 일치시킨 결과도 규칙 일치 증거가 아니다.

후보 난이도는 auto load·수동 organization 기본 profile·apply 거절 fallback·프로필 재로드 등 모두에서 동일하게 사용하고 성공 publish 전 host difficulty·active sim/seed/G/clock/선택과 기존 결과가 바뀌지 않아야 한다. 재시작·동일 brief, 초기 실패와 기존 전투 재준비 실패를 분리한다. profile_def 빈 POC 및 invalid brief의 기존 의미를 조사해 변화를 유발하는 정책을 미리 확정해야 하며 데이터 실패를 조용히 표준 성공으로 포장하지 않는다. auto의 원문 validate/profile 및 standalone/title은 별도 회귀다.

11행 중 Windows 행은 이전 PC0의 사용된 2/2 회차를 재명명해 반복하지 않는다. 기존 도구의 창 조회 지연·전경 불일치 원인은 미확정이므로 소유 root HWND, 실제 입력 및 시간·화면 증거를 어떻게 확보할지 구체적으로 밝히고 불가하면 해당 행 미검증으로 남긴다. signal 또는 viewport 합성으로 대체해 물리 입력 PASS로 부르지 않는다. 사용자에게 사람 참여를 가정하지 않는다.

FleetBattle3D는 P03과 공유 경계며 과거 별도 K6 후보 hunk와 충돌할 수 있다. 현재 코드·P03 실제 최신 소유 상태와 후보 diff를 적용 전 다시 대조하고 무단 병합하지 않는다. 3.26GB는 표본이며 cache/fixture peak·정리 가능 범위를 입증하기 전 실행하지 않는다. P02/PC0/K6/첫 PC 전체 완료 주장은 금지한다.
