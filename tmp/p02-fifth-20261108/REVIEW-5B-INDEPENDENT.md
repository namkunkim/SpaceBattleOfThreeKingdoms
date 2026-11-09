# P02 다섯 번째 조각 구현 독립 5-b

2026-11-08. 판정: **한정 수용**. 심사 세션 `/root/p02_fifth_review`, 요청 모델 gpt-6.1-terra; 실제 모델은 독립적으로 확인할 수 없어 미확인. 이 심사는 코드와 저장된 실행 근거를 검토하고 결과를 별도 재비교했다. 테스트를 새로 실행하지 않았다.

변경 전 원문과 현재 `battle_outcome.gd`, `auto_resolver.gd`를 대조했다. legacy worker가 `_loop` 후 facts 사본을 반환하고 poll이 join·취소 확인 후 결산한다. null/형태 오류 fallback은 legacy의 join된 sim에만 적용되며 operation worker는 그 경로를 호출하지 않는다. 직접 지휘와 blocking은 `from_sim`을 계속 사용한다. 중첩 자료는 추출 시 깊이 복사된다. 외부 동시 sim 접근·진행값 동기화는 계약 밖이고 일반적 스레드 안전성을 입증하지 않는다.

v3 사전 고정 원본 결과 SHA `07c709c0c9bcb33b9acc5ddb453f09ffd5487bee7dbddc5f1444ac528f2f3165`를 재계산하고 사후 결과와 18행 전체 동등, 각 106단언·0실패를 독립 확인했다. probe 원문에서 A01 실제 WorldMap 자동 시작/자연 종료·poll/결과 카드, A03 서막 skip·자동 편성 시작·10 tick 강제 종료·결과 버튼/1회 인계, A04 실제 취소와 A05 씬 종료 join을 확인했다. A03은 자연 종료가 아니다. 원본 실패 시도 A03의 서막 우회 결과는 정본에서 제외됐다. B01–B03 실제 worker 대역의 null·상위/중첩 오류와 join 후 legacy fallback, B04/B05 순서별 취소, B06/B07 양방향 중첩 사본은 7행 33단언·0실패로 기록됐고 검사 원문과 대조했다. 해당 순서 실험은 동시 호출 경합 증명이 아니다.

사전 5/사후 6 프로세스의 exit/timeout을 기록과 대조했다. returning WorldLink 및 두 adapter는 양쪽 exit 0이며 clean-user WorldLink는 양쪽 exit 1, 동일 `tests/world_link.gd:239` prologue 기대 실패다. 이는 통과로 세지 않는다. common과 두 WorldLink의 ObjectDB/리소스 종료 진단도 남는다. 원본·사후 4,209개 입력 목록과 엔진·캐시 동결은 제출된 manifest/검증 근거에 의존하며, 제품 클래스 경로는 probe 출력으로 확인된다. 5-a PASS는 이 기존 단일 실패를 별도 기준선으로 한 한정 의미다.

기존 기준선 12,281개는 별도 독립 재해시에서 소유 두 파일만 변화했고 누락·읽는 중 변경이 없었다. 신규 미귀속 파일은 독립 목록과 제출된 158개 관측의 경로·크기·SHA 및 관측 시점 이후 변화 없음으로만 다룬다. 첫 관측 이전의 내용과 소유권은 확인하지 못했다. P03 신규 경로를 삭제·변경하거나 본 작업에 귀속하지 않는다. 마감 시 다시 변화 여부를 확인해야 한다.

이 판정은 기존 legacy 결산 경계와 해당 실측 경로만 수용한다. 실제 1800초 상한, OS Thread.start 실패, 엔진 예외, 동시 writer, 손상 sim, 수동 GUI·Android·성능은 미검증이다. 제한 owner는 적벽 Victory 결산을 지원하지 않으며 제품 operation 입력·진행·결산, FleetBattle3D operation 소유권 및 replay는 미완료다. P02/I01/I01b/A04~A06은 NOT_READY, 외부 save schema는 UNCLASSIFIED다. 전달물과 마감 문서의 사실·보존 검증은 별도다.
