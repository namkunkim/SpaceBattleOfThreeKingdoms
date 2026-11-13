extends SceneTree
func _initialize():
 run.call_deferred()
func run():
 var map = load("res://scenes/WorldMap.tscn").instantiate()
 root.add_child(map)
 await process_frame
 await process_frame
 var result := BattleOutcome.new()
 result.win = true
 result.kind = "alliance_win"
 map._show_result(result, false)
 await process_frame
 if not map._res_labels.epilogue.text.contains("연합함대") or map._result.find_child("ScoresWei", true, false) != null or not map._res_labels.art.visible or map._res_labels.art.texture.resource_path != "res://assets/backgrounds/allied-fleet-review-final-4k.png":
  printerr("FAIL victory screen")
  quit(1)
  return
 for name in ["ResultRetry", "WatchReplay", "ResultQuit"]:
  if map._result.find_child(name, true, false) == null:
   printerr("FAIL result button ", name)
   quit(1)
   return
 result.win = false
 result.kind = "cao_win"
 map._show_result(result, false)
 if not map._res_labels.epilogue.text.contains("조조의 함대") or map._res_labels.art.texture.resource_path != "res://assets/backgrounds/wei-fleet-review-v4-underway.png":
  printerr("FAIL defeat epilogue")
  quit(1)
  return
 print("PASS victory and defeat epilogues, image and result buttons")
 quit(0)
