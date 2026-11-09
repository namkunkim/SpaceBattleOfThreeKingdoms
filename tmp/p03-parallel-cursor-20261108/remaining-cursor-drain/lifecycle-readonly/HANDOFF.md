# lifecycle 읽기 조사 인계

독립 수용된 PLAN.md v2에 따라 11개 공개 owner 진입점과 교차 반례 3개를 정적 원장에 정리했다. 5-a의 명명 분모, 원문 함수 위치, 시작·종료 14개 입력의 SHA/크기 대조가 통과했다. 기존 viewer E13, P02 read DTO 및 active replace의 검사 원문과 결과는 겹치는 역사 근거로 표시했다. 이번 조사에서 새 Godot 실행은 없었다.

가드 우선순위는 busy → unprepared_owner → 개별 입력 검사 순서이며, issue/queue/advance/raw drain/observe/capture/restore의 최초 가드 실패는 두 키, filtered drain/read_projection/summary는 path:owner를 포함한 세 키다. close는 guard 없이 void로 종료한다. 이 결론은 조사 시점의 정적 소스 경로에 한정한다. 별도 Terra 5-b가 원장 및 근거를 대조해야 한다.

공유 구현 및 P02 파일은 읽기만 했다. 이번 정적 5-a는 이전 cursor/drain 실행의 3/K6 및 종합 5-a 미통과를 변경하지 않는다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
