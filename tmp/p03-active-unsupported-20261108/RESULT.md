# 활성 DecisionBoard 교체 경계 관측

K6 두 호출. attempt-01은 preload 상수의 resource_path 접근에서 파싱 실패, 실제 exit1 및 명명 결과 없음. attempt-02는 런타임 객체 script 경로를 확인하도록 수정해 실제 exit0, 3명명/15 확인, 엔진 진단 0. 각 시도의 runner 원문과 stdout/stderr 및 실행 전후 입력 SHA를 별도로 보존했다.

지원되는 두 owner의 C0 복원과 동일 suffix를 대조했다. 별도 실제 tick1 owner에 정본 DecisionBoard를 붙이고 _seq 47을 표시했다. capture는 정확한 unsupported_active_decisions를 반환했다. 현재 활성 sim과 모듈 identity·역참조·marker, observe 및 ready/busy와 C0 입력이 유지됐다. 같은 입력의 C0 후보는 별도 준비에 성공했다.

활성 restore는 ok:true와 함께 sim을 교체했다. 새 활성 sim에서 decisions는 null이며, 이전 sim에만 원래 모듈·marker가 남았다. fixture가 retired 순환 참조를 정리했다. 새 활성 C0 관측과 동일 명령 queue→advance→drain suffix는 후보와 일치했다. 결과 분류는 **ACCEPTED_DROPS_ACTIVE_MODULE**이다. 동일 컨텍스트 제품 경로에서 해당 활성 상태에 도달할 수 있는지, 허용/거부 정책 및 기타 모듈은 미검증이다.

공유 owner 및 host/제품 코드는 수정하지 않았다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
