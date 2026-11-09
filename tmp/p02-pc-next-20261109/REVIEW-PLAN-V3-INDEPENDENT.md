# V3 정적 준비 독립 심사

판정: 정적 준비로만 수용, 엔진 실행·제품 적용 불가. 제품 후보 두 파일은 아직 없고 실행 manifest도 없다. 이 Python broker는 기존 K3에서 예상 밖 console host 문제를 실제로 해결한 증거가 없고 Godot 자손 HANDLE/exit를 직접 관찰하지 않는다. K3을 다른 명칭으로 재실행하거나 broker 종료를 엔진 종료로 주장할 수 없다.

prepared 테스트는 실제 WorldMap 객체와 버튼 signal, 네 WorldLink 이전 값, 결과 객체·레이블·owners, 사운드 이력을 사용하고 45개 F/R/A/BS/BN ID를 작성했다. 오류 주입은 fixture 프로젝트의 씬 파일 누락이며 오류값 stub이 아니다. 현재 GDScript 파싱·fixture 경로·실제 loader 오류·결과 전체 행 실행은 미검증이다. before는 복구가 없으므로 각 WorldMap 독립 생성과 실패에도 나머지 case 진행이 필요하고 조기 fixture 실패시 누락을 PASS로 세지 않는다. 성공 C는 scene_changed 사전 연결 및 신호 호출을 포함하나 문법·수명·정확한 1회 관측은 실측이 필요하다. 신호 발화는 OS 입력이 아니다. 전환 후 결과 UI의 label/owners 일부만 관측하므로 사운드 및 timer diff 검사와 함께 범위를 설명한다.

현실적 대안은 이미 PC0에서 소유 Job 할당·실제 root exit 및 active 0을 관측한 C# 직접 실행기를 바탕으로 GUI Godot exe에 --headless를 직접 전달하고 engine --log-file을 사용해 engine 종료 및 로그를 확인하는 것이다. stdout/stderr를 필수로 유지하려면 명시적 파일 HANDLE 상속·기록과 닫힘을 구현해 독립 정적 심사한다. GUI exe의 stdout 경로가 실제로 유효하지 않다면 해당 스트림을 증명했다고 말하지 않고 로그/종료를 검증 기준으로 재명세한다. timeout은 기존 감독 루프 조건 아래의 제한이고 OS 호출의 절대 시간 보장이 아니다. 이는 다른 직접 실행 계약이며 Python 콘솔 broker 실패를 지우지 않는다. 합리적 원문 진단과 가시적 종료·정리 여부가 핵심이며 절대 OS 격리 가정을 요구하지 않는다. 구체 candidate/runner/manifest 및 현재 P03 bytes를 동결하고 심사 전 제품 실행을 하지 않는다.

PC0 2/2 소진, 별도 K6 미사용, 이 조각 0/6을 유지한다. source-only 검토는 제품 통과나 작업 완료가 아니다.
