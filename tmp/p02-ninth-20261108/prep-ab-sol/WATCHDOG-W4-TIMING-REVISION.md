# Watchdog W4 정정

이 문서는 앞선 watchdog JSON을 수정하지 않는다. 그 입력의 W4 8초 전역과 6초 inner·5초 cleanup 조합은 실행 명세에서 폐기한다.

W4는 stage 시작 전부터 global hard 55초를 사용한다. staging/preverify 5초, normal engine 실행 30초, engine inner cleanup 최대 5초, postverify local 8초, 외부 reserve 7초의 합이다. Postverify blocker는 정상 엔진 종료와 owned Job active 0의 동기 기록을 확인한 뒤 시작한다. Outside supervisor는 durable POSTVERIFY_BEGIN receipt의 monotonic tick을 받고 그 시점부터 8초의 stage watchdog과 원래 55초 global을 각각 확인한다. Local cutoff가 발동하면 stage-timeout을 outside journal에 먼저 쓰고 controller를 outer Job으로 종료하며 drain 확인 5초를 reserve에 배치한다. 이전 단계가 실패하거나 55초 global을 먼저 넘으면 W4 postverify 성공 관측으로 기록하지 않는다.

W3의 기존 8초는 엔진이 없는 blocking staging case다. 그 경계와 W4의 local 8초는 별도다. Exact supervisor/controller argv, Windows Job handle/member collector와 filesystem confinement 구현이 없어 전체 watchdog 실측은 미실행 상태다. Godot 및 제품 프로세스를 실행하지 않았다.
