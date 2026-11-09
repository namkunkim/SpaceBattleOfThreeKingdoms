# PC0 run-02 독립 결과 심사

판정: PC0 불합격/미완료. 예약된 2회 중 2회가 소진되어 재실행하지 않는다. 별도 여덟째 후보 K6은 이 PC0 실행과 별개이며 미소진이다. 제품의 전투 또는 자연 종료 실패로 판정할 근거도 없다.

실제 원문에서 isolation root exit 0, Job active 0, PC0_USER는 격리된 run-02 APPDATA를 가리켰다. import root exit 0 및 Job active 0, 관찰하여 보유한 두 자식 HANDLE은 각 signaled 상태다. 제품 root PID 10612는 시작했고 로그에는 clock_anchor와 빈 큐의 초기 consume만 있다. 이는 결과 publish/consume이나 전투 진입을 뜻하지 않는다. 감독기는 brief 180초 단계에서 TimeoutException을 기록하고 자신의 Job 종료를 요청했으며 root signaled, exit 125, active 0을 기록했다. 정상 게임 종료는 아니다. 제품 창 표본은 foreground HWND와 소유 HWND가 다른 상태를 보여준다.

화면 디렉터리는 비어 있고 actions.jsonl이 없으며 생성된 전투 trace는 발견하지 못했다. 운영자 인계에 따르면 최초 CUA 창 조회/캡처 호출이 약 710초 동안 막혔고 감독기 종료 후 상위 작업자가 도구를 중단했다. 해당 중단을 물리적 ESC 입력이나 사용자 취소로 해석할 수 없다. 입력·활성화가 없었다는 것은 운영자 인계와 화면/액션 산출물 부재에 근거하며, 원문 로그만으로 모든 OS 입력 부재를 독립 증명하는 것은 아니다. 그 원인은 확정되지 않았다.

original-before/after JSON SHA는 모두 05c4a1f0c083795536c4b39724bc85758e29b7d71a9499985fd06ba192745f1b, project-before/after는 모두 5e9d3303edd11dbdc2de0142b2f762bd3382b38f01cce6ac04683eb6aab61835, protected-before/after는 모두 d8cc839b5efebfd2f23047a8f5d970fd5f76c6db2a2aba8c3b82960bd52b62f7이다. 이는 각 기록된 해시 목록의 전후 일치이며 모든 사용자 데이터에 대한 전역 보증은 아니다. import-generated 기록은 1,341개 항목이다. 1,470개 source 복제의 전체 원문 재계산은 이 결과 심사에서 하지 않았다. run-01 기존 증거와 lock은 보존한다.

제품 log SHA ee5bab8a6abef3ec62888fa26988520a13a99e898a383776adbfddeecf81d518, product OS log SHA d3c0fd5be8887c3c1111dcbe27944a88297c3e33290df96fe73945a8e406ac46. 모델 식별은 이 리뷰 런타임에서 독립 검증할 수 없으며 임의로 기재하지 않는다.
