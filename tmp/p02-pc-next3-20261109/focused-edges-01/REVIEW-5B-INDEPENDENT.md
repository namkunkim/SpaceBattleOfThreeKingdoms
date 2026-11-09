# 난이도 후보 경계 검사 독립 5-b

판정: 기존 14 lane과 이번 12 lane의 한정된 격리 headless 결과를 함께 수용한다. 같은 후보 FleetBattle3D SHA 0be6a03729a0906b6170169e607c0d26cb08ae046f9e31785c8862f372b10e81의 원본 반영은 별도 적용 단계에서 직전 원본 SHA·HEAD/index 및 P03 공동 소유 경계를 확인한 뒤 심사된 hunk만 허용한다. 이 심사에서 제품 파일을 쓰지 않았다. GUI·첫 PC 전체 수용은 아니다.

이번 12개 실제 command/exit·root signal 및 Job active 0, 보유 자손 signal을 대조했다. before D05 네 개, D08 retry.rules 하나, D11 두 개, D13 세 개의 지정 red와 D12 PASS가 정확했고 after는 모든 ID PASS였다. 실제 진단은 의도된 invalid_candidate_profile 두 건과 후보 invalid_brief_difficulty 한 건이다. results.jsonl SHA e0661e8933e7b826c08d8e534e4b36584652c2326102b45de7a5e42f206558c1. inputs와 source 1480 및 HEAD/빈 staged는 확인 시점 일치한다. 기존 14 lane의 results SHA 5733a70fb1ca7ee2d1273ace99b9642fe745879d7f0f90971211d5d3888b8d65과 같은 후보 SHA를 확인했다.

D05는 해당 비기함 편성 제외, D11은 손상된 편성 적용 거절과 자동 편성 fallback·시작 차단을 검사한다. D08은 실패 원자성 뒤 실제 재준비에서 극한 host/scenario/AI와 seed를 검사한다. D12는 standalone 빈 POC, D13은 invalid routed 기본 적벽의 초기 거절·안내·결과 없는 복귀다. 데이터 파일 자체 손상 fallback, routed POC, 재시도 후 전체 roster, Windows 물리 입력·다른 display 및 자연 전투 종료는 이 결과로 확인되지 않는다. UI signal과 강제 종료는 실제 사용자 입력·자연 종결이 아니다.

이 범위의 난이도 적용은 WorldMap brief 선택과 실제 legacy 적벽 host/profiles를 맞춘다. P03 제품 운영 복원, 신규 operation, PC0 및 P02 전체 완료를 뜻하지 않는다. 기존 별도 K6 기록과 이전 실패를 보존한다. 모델 실제 ID는 이 런타임에서 독립 확인하지 못했다.
