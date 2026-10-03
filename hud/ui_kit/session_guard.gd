extends Node

# 중단 처리(결정 Q53): 앱이 백그라운드로 가거나 창이 포커스를 잃으면 즉시 일시정지한다.
# 저장(초기 상태 + 명령 기록 + 틱)과 국면별 체크포인트는 코어가 생긴 뒤 suspend_requested에 붙인다.

signal suspend_requested(reason: String)

var deck: Control
var auto_paused := false   # 마지막 일시정지가 자동이었는가(일시정지 화면 안내 문구)
var enabled := true        # 캡처처럼 창 포커스와 무관하게 돌려야 할 때 끈다

func setup(d: Control) -> void:
	deck = d

func _notification(what: int) -> void:
	if not enabled:
		return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			suspend("background")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			suspend("focus")

func suspend(reason: String) -> void:
	if deck == null or deck.battle.G.get("state", "") != "play":
		return
	deck.pacing.cancel_skip()
	deck.open_pause()
	auto_paused = true
	suspend_requested.emit(reason)

# 일시정지를 플레이어가 직접 열면 안내 문구를 지운다.
func clear() -> void:
	auto_paused = false
