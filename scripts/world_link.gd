extends Node

# 천하 지도 ↔ 전장 장면 전환(autoload "WorldLink", docs/battle-core/WORLD-MAP-LINK.md §3).
# 두 장면은 서로의 내부를 모른다. 넘기는 것은 BattleBrief(가는 길)와 BattleOutcome(오는 길)뿐이다.
# 천하 지도에는 저장할 상태가 없다. 여기 남는 것은 카드에서 고른 값(난이도·지휘 방식)과 직전 결과뿐이다.

const WORLD_SCENE := "res://scenes/WorldMap.tscn"
const BATTLE_SCENE := "res://scenes/FleetBattle3D.tscn"

var brief: BattleBrief = null       # 진행 중인 전투의 명세. 천하 지도에서 들어오지 않은 전투면 null
var outcome: BattleOutcome = null   # 천하 지도가 아직 보여 주지 않은 결과
var last_difficulty := "표준"
var last_mode := "direct"

func routed() -> bool:
	return brief != null

func go_battle(b: BattleBrief) -> void:
	brief = b
	outcome = null
	last_difficulty = b.difficulty
	last_mode = b.mode
	get_tree().change_scene_to_file(BATTLE_SCENE)

# 전장에서 천하로 돌아온다. o가 null이면 전투를 끝내지 않고 나온 것이다.
func back_to_world(o: BattleOutcome) -> void:
	outcome = o
	brief = null
	get_tree().change_scene_to_file(WORLD_SCENE)

# 천하 지도가 결과를 한 번 가져간다.
func take_outcome() -> BattleOutcome:
	var o := outcome
	outcome = null
	return o
