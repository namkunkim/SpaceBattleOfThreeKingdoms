# K6 준비 V2 독립 심사

판정: **준비 자료로 보존, 실행 반려**. `MANIFEST-V2-REVIEW-ONLY.json` SHA-256 `94c160b317f7ead068c5b6bde357dd2799efe443d72f721d1d66b138f0b34579`. 실제 심사 turn metadata: gpt-6.1-terra / low. K6이나 GUI 입력은 수행하지 않았다.

58개 process의 timeout 18490초 + cleanup 580초 + reserve 1200초 = 20270초로 6시간 이하이다. 모든 명시 probe 경로가 현재 존재하며 행 9에는 무계측 after 및 계측 lane이 분리됐다. native_v2의 기준은 adapter를 호출하지 않고 BattleSim.new와 원래 지휘 정책 및 별도 변환 계산을 사용한다. 행 5 viewer capture, 행 6 실제 init_game 게시, suite 출력 관측 등 보완은 정적으로 확인했으나, 실행하지 않은 코드의 동작·전체 단언과 독립 비교가 충족됐다는 증거는 아니다.

실행을 막는 구체 항목:

1. runner_v2는 GUI 포함 목록 전체를 명시적으로 거절하고, timeout 때 console wrapper만 kill한다. Windows 자식 Godot 프로세스까지 소유·종료·join 확인하는 검증된 containment가 없다. STOP과 실패·예외에서도 같은 보장이 필요하다. 다른 프로세스나 사용자 앱을 종료해서는 안 된다.
2. `index_assertions`는 결과를 수집할 뿐 false, 누락, 중복과 예상 분모를 판정하지 않는다. 원문 B/A/I 비교 및 clean 단일 편차를 자동 또는 독립 검증할 구체 oracle/index가 필요하다. exit만으로 성공을 선언할 수 없다. 명령별 기대·원문·관측과 행별 전체 분모 및 실행 전후 프로젝트/Git 보호 검사도 완성본으로 대조해야 한다.
3. manifest dependencies에 수용된 `K6-EXECUTION-CONTRACT-v2.md`가 포함되지 않았다. 해당 계약과 모든 runner/overlay/probe/fixture, 실행 엔진과 4개 lane 입력 및 승인 차이를 최종 SHA에 묶고 복사 후 및 전후 무결성을 입증해야 한다. 변경 시 재심이 필요하다. `compare_workspace`만으로 Git branch/index나 전체 비실행 P03 경로의 불변을 증명했다고 볼 수 없다.
4. Sky click/press_key 공개 결과는 Promise<void>이고 OS 이벤트 출처 토큰이 없다. HWND/PID와 전후 foreground, 시각적 상관 및 injected flag만으로 연속 전경이나 해당 호출의 입력임을 증명할 수 없다. 현재 문서도 이 공백을 인정한다. 승인된 입력 도구로 출처와 혼재 배제를 독립 검증할 수 없다면 행 15·16 미충족이며 K6을 시작하지 않는다. 사용자/다른 프로세스의 입력이나 앱을 조작하는 우회는 허용하지 않는다. 더 낮은 근거 수준으로 인수 조건을 조용히 낮출 수 없다.

실제 제품 시작 전 완성된 전체 manifest와 독립 재심이 필요하다. 부분 headless 실행으로 GUI를 생략하는 것은 고정 분모·단일 잔여 K6 계약에 맞지 않는다. K1~K5 원문과 실패, 원본 checkout·Git·HTML·P03을 보존한다. 본 판정은 제품 적용 또는 5-b 인수가 아니다.
