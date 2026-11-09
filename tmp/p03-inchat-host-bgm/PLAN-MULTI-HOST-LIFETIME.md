# BGM 포함 다중 호스트 종료 최소 차이 대조

새 K6는 4회 사용, 잔여 2회다. 최소 01/02는 valid CLEAN이며 단일 03은 disable 뒤 playing을 읽은 오라클 결함으로 exit1/FAIL이다. 독립 수용 뒤 관측 위치만 바꾼 04는 actual exit0/valid CLEAN으로, disable 직전 실제 BGM playing/playback 모두 참이었다. 단일 호스트에서 정확한 누수가 나오지 않아 ordered 단일은 실행하지 않았다.

이전 확정 실패는 단일 호스트가 아닌 4개 호스트의 동기 반복이다. 당시 두 phase마다 malformed 후보 1개와 정상 새 전장 게시 대조 1개를 포함했고 실제 SceneTree의 다음 프레임은 모든 장면 해제 뒤였다. 단일 04에서 재현되지 않았으므로 이 구성을 source/canonical 및 같은 실제 엔진·driver로 되돌려 누수를 재현한다. K6 마지막 두 호출을 여기에만 요청한다.

## 고정 비교

- **05 multi-legacy**. `p03-inchat-host-clock/attempt-05/project/host_clock_probe.gd`의 BGM 포함 4인스턴스, 동일 seed·phase·manual frame·오류 후보·정상 게시·retire를 유지한다. 각 `add_child` 직후 disable 전에 BGM canonical Ogg·playing/playback true를 반드시 기록한다. 단일 시험의 검증된 관측 순서다. 원래 네 호스트 시계·게시 단언을 그대로 검사한다. 정본 BGM·설명자·캐시를 모두 포함하고 원본과 격리 복사 SHA·HEAD/index·status 및 엔진 본체/console과 Job을 앞뒤 고정한다.
- **06 multi-ordered**. 05에서 actual exit0, 네 기능 단언과 음악 시작 4/4, 예상 profile.ally 오류 2개와 알려진 정확한 Ogg 4객체/2resource만 있고 Job active0이면 실행한다. 동일 runner·동일 사본·seed로 실행하고 유일한 모드 차이는 각 host retire의 stop 뒤 clear 전 대기다. host process disabled와 tree 부착 유지 상태에서 실제 12 process_frame 및 250ms를 기다린다. 그 사이 sim tick/clock 및 phase 불변, 음악 player attached, stop→wait→clear→free 순서를 출력한다. 나머지 외부 조건과 최종 대기는 동일하다.

05가 깨끗하거나 관측이 무효이면 06을 자동 실행하지 않는다. 06에 누수가 남으면 같은 정확 진단으로 실패 근거를 보존하고 K6 소진으로 멈춘다. 06이 깨끗하면 **BGM 포함 격리 다중 호스트 fixture의 종료 순서 회귀 수용 후보**다. 기존 옵션 BGM 생략 결과와 분리한다. 같은 scene에서 자연스럽게 재생되거나 실제 제품 사용자의 종료·전환이 통과했다는 뜻은 아니다. 호스트·엔진의 일반 원인 귀속이나 제품 코드 수정 hunk는 이 결과와 실제 lifecycle 차이 근거 없이 확정하지 않는다.

두 실제 실행은 새 전용 격리 경로와 고유 appdata에서만 수행한다. 외부 변경과 P02 원문은 읽기 관측·SHA 동결만 한다. 출처와 판정은 실제 종료 코드, raw 진단, 사본 manifest, 사용자 작업 보존 및 별도 독립 5b/closeout에 연결한다. 기존 K6, 01~04, shared UI/엔진/음악을 변경하지 않는다.
