extends RefCounted
# Pure session state. No save, battle, coordinate or WorldLink dependency.
enum State { SELECT, STORY, MAP, CONFIRM, LOADING, READY, ERROR, EXIT, BYPASS }
var state := State.SELECT
var revision := 0
var page := 0
var notified := false
var error := ""
var retry_state := State.SELECT
var origin := "new"
const Prologue := preload("res://hud/ui_kit/prologue_text.gd")
const REGION := "red_cliffs"
const SCENARIO := "RED-CLIFFS-208-RT"

func begin(source: String) -> bool:
	if revision != 0 or state != State.SELECT:
		return false
	origin = source
	if source in ["resume", "settlement"]:
		state = State.BYPASS
	elif source != "new":
		error = "알 수 없는 진입 경로"
		state = State.ERROR
		retry_state = State.SELECT
	revision += 1
	return true

func act(action: String, token: int, region := REGION) -> bool:
	if token != revision:
		return false
	if action == "back":
		match state:
			State.STORY:
				if page > 0:
					page -= 1
				else:
					state = State.SELECT
			State.CONFIRM:
				state = State.MAP
				notified = false
			State.MAP, State.READY, State.ERROR:
				state = State.SELECT
				page = 0
				notified = false
			_: return false
		revision += 1
		return true
	match state:
		State.SELECT:
			if action != "start" or region != REGION: return false
			state = State.STORY
		State.STORY:
			if action == "skip": state = State.LOADING
			elif action == "next":
				page += 1
				if page >= Prologue.PAGES.size(): state = State.LOADING
			else: return false
		State.MAP:
			if region != REGION: return false
			if action == "inspect":
				state = State.LOADING
			elif action == "enter" and not notified:
				notified = true
				state = State.CONFIRM
			else:
				return false
		State.CONFIRM:
			if region != REGION: return false
			if action == "yes": state = State.LOADING
			elif action == "no": state = State.EXIT
			else: return false
		State.ERROR:
			if action == "retry": state = retry_state
			elif action == "exit": state = State.EXIT
			else: return false
		State.READY:
			if action == "map":
				state = State.MAP
			elif action == "exit":
				state = State.EXIT
			else:
				return false
		State.BYPASS:
			if action != "exit": return false
			state = State.EXIT
		_: return false
	revision += 1
	return true

func loaded(token: int, success: bool, message := "") -> bool:
	if state != State.LOADING or token != revision: return false
	state = State.READY if success else State.ERROR
	error = message
	retry_state = State.LOADING
	revision += 1
	return true

