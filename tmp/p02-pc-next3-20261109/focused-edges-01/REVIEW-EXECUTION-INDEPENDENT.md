# 난이도 변경 경계 검사 실행 독립 심사

판정: manifest baf65a8b7e7280b602de7518a51870eaf404d74ba310c1ba64da8f202f66cfa6에 고정된 격리 headless 12개 프로세스 단일 세트를 수용한다. 엔진 실행과 제품 수정은 본 심사에서 하지 않았다. 기존 14개 결과·실패 및 타입 진단을 보존하며 이 실행으로 재분류하지 않는다.

각 before/after import 및 D05/D08/D11/D12/D13, timeout 합계 1440초다. before는 D05 지정 네 ID, D08 retry.rules, D11 두 fallback ID, D13 세 invalid ID만 red·exit1, D12와 after는 exit0을 요구한다. 실제 파싱·fixture·진단은 실행 전 가설이며 다른 오류·ID 누락·timeout은 실패다. D05 전대 해제가 실제 편성 유효성 검사를 지나는지 실측해야 한다. D11의 brief 화면 설정은 테스트 fixture이며 제품 입력이나 별도 데이터 손상 fallback 검증이 아니다.

D08 추가 단언은 독립 oracle의 변경된 극한 AI·scenario/host 난이도 및 seed를 검사한다. 초기 retry sim/오류 화면 확인도 유지하나 실제 roster 별도 재대조는 하지 않는다. D12는 빈 POC, D13은 invalid brief를 시험하며 5-b에서 raw 검사와 변경 범위를 한정한다. 물리 Windows 입력·자연 전투 종료는 수행하지 않는다.

동결 파일과 source 1480은 검토 시점에 일치, 새 attempt 부재, free 약 8.94GB다. 2.9GB 시작/1.5GB 운행 바닥은 공간 예약이 아니고 시간 합도 OS 호출 절대 보장은 아니다. 새 격리 project cache만 검증된 경로·junction 검사 후 재import를 위해 정리한다. 원본·기존 실행 로그 및 P03 자료는 건드리지 않는다. 최종 원본 반영은 실제 결과와 별도 독립 5-b 및 P03 소유·대상 SHA 재확인 이후에만 판단한다. PC0와 별도 K6을 변경하지 않는다.
