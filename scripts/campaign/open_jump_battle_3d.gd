extends "res://scripts/FleetBattle3D.gd"
## Presentation bridge only: Session/Runtime own every command and simulation tick.
const Session = preload("res://core/campaign/open_jump_session.gd")
const RestoreWorker := preload("res://scripts/campaign/open_jump_restore_worker.gd")
const RestoreOverlay := preload("res://scripts/campaign/open_jump_restore_overlay.gd")
signal restore_finished(result: Dictionary)

const RESTORED_PAUSE := "restored_pause"

const OBJECTIVES = {
 "rendezvous": "유비 또는 관우로 황개와 합류하세요 (400, 650).",
 "escort": "황개를 대기시키고 차단군을 제압한 뒤 기지 (850, 430)로 호위하세요.",
 "capture": "황개와 유비·관우 중 한 함대를 기지 안에 유지하고 수비대를 제거하세요.",
 "clash": "조조 본대 접근! 황개를 도약 지점 (1100, 650)으로 호위하세요.",
 "extraction": "황개와 생존한 유비·관우 함대를 출구 (1400, 750)에 모은 뒤 공동 도약하세요."
}
var session
var operation_panel: PanelContainer
var operation_label: Label
var operation_notice: Label
var guidance_label: Label
var escort_status: Label
var guidance_toggle: CheckButton
var _guidance_phase := "rendezvous"
var _phase_start_tick := 0
var _phase_resumed := false
var operation_buttons := {}
var last_command_result := {}
var region_markers := {}
var _restore_job: RefCounted
var _restore_overlay: ColorRect
var _restore_previous_state := ""

func _ready() -> void:
 move_mul = 1.0
 turn_mul = 1.0
 vsize = get_viewport().get_visible_rect().size
 rig.vsize = vsize
 view3d.setup(self, rig)
 _build_canvas()
 cmds = BattleCommands.new(self)
 input_node = BattleInput.new()
 add_child(input_node)
 input_node.setup(self, cmds)
 if not init_game().ok:
  set_process(false)
  return
 presentation = load(PRESENTATION).new()
 add_child(presentation)
 presentation.setup(self)
 presentation.hud.show_screen("")
 presentation.hud.objectives.hide()
 presentation.hud.log_box.clip_contents = true
 presentation.hud.undo_bar.set_process(false)
 presentation.hud.undo_bar.hide()
 presentation.hud.decision_card.set_process(false)
 presentation.hud.decision_card.hide()
 for i in range(3, presentation.hud.cmd_tabs.size()):
  presentation.hud.cmd_tabs[i].hide()
 _build_operation_ui()
 _build_regions()
 _pump()
 _filter_commands()

func init_game(proposed_org: Variant = null) -> Dictionary:
 if _restore_job != null:
  return {"ok": false, "error": "checkpoint_busy"}
 if proposed_org != null:
  return {"ok": false, "error": "campaign_fixed_organization"}
 var result: Dictionary = Session.fresh(208)
 if result.ok:
  _install_session(result.session)
 return {"ok": result.ok, "error": result.get("error", "")}

func _install_session(next_session) -> void:
 if session != null:
  session.runtime.close()
 sim = null
 session = next_session
 var profile: Dictionary = session.runtime.definition.initial_profile
 _publish_game({"seed": session.runtime.seed, "sim": session.runtime.sim,
  "difficulty": "normal", "ally": profile.ally.map(_with_portrait),
  "foe": profile.foe.map(_with_portrait), "errors": [], "message": "",
  "fallback": false, "scenario": true}, {})
 _guidance_phase = session.runtime.policy.snapshot().phase
 _phase_start_tick = session.runtime.sim.st.tick
 _phase_resumed = session.runtime.sim.st.tick > 0
 _had_move.clear()
 _last_dest.clear()
 salvo_fx.clear()
 rig.update()
 if presentation != null and presentation.hud != null:
  presentation.hud._clear_log()
 if operation_notice != null:
  operation_notice.text = "황개 필수 생존 · 유비·관우가 모두 전멸하면 실패합니다."

func _exit_tree() -> void:
 if _restore_job != null:
  _restore_job.cancel_and_join()
  _restore_job = null
 if session != null:
  session.runtime.close()
 session = null
 sim = null

func routed() -> bool:
 return true

func back_to_world() -> Error:
 return get_tree().change_scene_to_file("res://scenes/campaign/OpenJumpMenu.tscn")

func _start() -> void:
 if _restore_job != null:
  return
 var resumed_restore: bool = G.state == RESTORED_PAUSE
 _show_operation("play")
 if resumed_restore:
  operation_notice.text = "저장한 전장을 불러왔습니다."
  _refresh_operation_ui()

func _show_operation(state: String) -> void:
 if operation_panel != null:
  operation_panel.show()
 hud.brief_ov.hide()
 hud.end_ov.hide()
 hud.menu_ov.hide()
 G.state = state
 placing = false
 place_mode = false
 selected.assign(my_sel())
 for alias in ["liu", "guan"]:
  if not selected.is_empty():
   break
  var candidate = by_id(session.runtime.fleet(alias).id)
  if candidate != null and not candidate.dead:
   selected.append(candidate)
   break
 refresh_panel()

func _assign_default_groups() -> void:
 groups = {1: [session.runtime.fleet("liu").id], 2: [session.runtime.fleet("guan").id]}

func player_alias(id: int) -> String:
 for alias in ["liu", "guan"]:
  if session.runtime.fleet(alias).id == id:
   return alias
 return ""

func my_sel() -> Array:
 return selected.filter(func(f): return not f.dead and player_alias(f.id) != "")

func issue(cmd: Dictionary) -> void:
 if _restore_job != null:
  last_command_result = {"ok": false, "error": "checkpoint_busy"}
  return
 if G.state == RESTORED_PAUSE:
  last_command_result = {"ok": false, "error": "checkpoint_paused"}
  return
 last_command_result = {"ok": false, "error": "not_player_fleet"}
 var kind: String = cmd.get("kind", "")
 if kind not in session.runtime.NATIVE_COMMANDS:
  last_command_result = {"ok": false, "error": "unsupported_campaign_command"}
  toast("이 작전에서 지원하지 않는 명령입니다: " + kind)
  return
 var args: Dictionary = cmd.get("args", {})
 if kind == "move" and (args.get("strafe", false) or args.has("facing_deg") or not args.get("via", []).is_empty()):
  last_command_result = {"ok": false, "error": "unsupported_move_modifier"}
  toast("이 작전에서는 일반 이동 명령을 사용하세요.")
  return
 for id in cmd.get("ids", []):
  var alias := player_alias(int(id))
  if alias.is_empty():
   continue
  var order := {"kind": kind, "fleet": alias}
  if kind == "move":
   var point: Vector2 = cmd.get("point", Vector2.ZERO)
   order.point = [point.x, point.y]
  elif kind == "formation":
   order.formation = str(args.get("id", ""))
  elif kind == "skill":
   order.slot = int(args.get("slot", -1))
   if int(cmd.get("target_id", -1)) > 0:
    order.target_id = int(cmd.target_id)
  elif kind in ["attack", "missile", "fighter", "volley"]:
   order.target_id = int(cmd.get("target_id", -1))
   if order.target_id < 1:
    order.target_id = _visible_target(alias)
  last_command_result = session.runtime.queue(order)
  if not last_command_result.ok:
   toast("명령 거부: " + str(last_command_result.error))

func _visible_target(alias: String) -> int:
 var own = session.runtime.fleet(alias)
 var result := -1
 var distance := INF
 for contact in sim.projection(0).squadrons:
  if int(contact.side) == 0:
   continue
  var enemy = sim.st.by_id(int(contact.id))
  if enemy != null and sim.sees(own, enemy) and not enemy.dead:
   var d: float = own.pos.distance_squared_to(sim.known_pos(own, enemy))
   if d < distance:
    distance = d
    result = enemy.id
 return result

func _process(delta: float) -> void:
 if session == null:
  return
 if _restore_job != null:
  _update_restore()
  return
 now_t += delta
 var dt := minf(delta, 0.05)
 if G.state == "play":
  input_node.poll_camera(dt)
  clock.set_speed(float(G.speed) * G.slow)
  var n := clock.advance(delta)
  for i in n:
   if sim.st.over:
    break
   if i > 0 and i == n - 1:
    _sync()
   var phase_before: String = session.runtime.policy.snapshot().phase
   session.runtime.advance()
   if guidance_toggle.button_pressed and session.runtime.policy.snapshot().phase != phase_before:
    break
  if n > 0:
   _pump()
  vm.interpolate(1.0 if sim.st.over else clock.alpha())
  _tick_view(dt * G.speed * G.slow)
  if G.over and G.end_t > 0:
   G.end_t -= dt
   if G.end_t <= 0:
    _show_end()
 rig.update()
 fx.queue_redraw()
 ui.queue_redraw()
 radar.queue_redraw()
 _refresh_operation_ui()
 _filter_commands()

func _filter_commands() -> void:
 for button in presentation.hud.cmd_buttons:
  if button.get_property_list().any(func(property): return property.name == "cmd"):
   button.visible = button.cmd.id in ["stop", "all", "missile", "fighter"]

func update_sim(dt: float) -> void:
 if G.state in ["guidance", RESTORED_PAUSE] or _restore_job != null:
  return
 for i in _sim_acc_clock.advance(dt):
  if sim.st.over:
   break
  var phase_before: String = session.runtime.policy.snapshot().phase
  session.runtime.advance()
  if guidance_toggle.button_pressed and session.runtime.policy.snapshot().phase != phase_before:
   break
 _pump()
 vm.interpolate(1.0)

func _pump() -> void:
 var entered_phase := ""
 _sync()
 _note_arrivals()
 for event in session.runtime.drain_events():
  if event.kind == "mission_started":
   entered_phase = str(event.phase)
  if event.kind == "battle_end":
   var outcome: String = session.runtime.policy.snapshot().outcome
   end_game(outcome == "success", _result_text())
  elif event.has("sq"):
   _on_event(event)
  elif event.has("text"):
   add_log(str(event.text), "sys", null)
   if operation_notice != null:
    operation_notice.text = str(event.text)
    if event.kind == "recon_report":
     operation_notice.text += " 접근: %s / 출구: %s" % [event.cao_approach, event.exit.center]
 if not entered_phase.is_empty():
  _guidance_phase = entered_phase
  _phase_start_tick = sim.st.tick
  _phase_resumed = false
  if guidance_toggle != null and guidance_toggle.button_pressed and not sim.st.over:
   G.state = "guidance"
   clock.acc = 0.0
   operation_notice.text = "새 임무 안내를 확인하세요. ‘출격 / 계속’을 누르면 재개합니다."
 _refresh_operation_ui()

func campaign_order(kind: String) -> Dictionary:
 if _restore_job != null:
  return {"ok": false, "error": "checkpoint_busy"}
 if G.state == RESTORED_PAUSE:
  return {"ok": false, "error": "checkpoint_paused"}
 var result: Dictionary = session.runtime.queue({"kind": kind})
 if not result.ok:
  operation_notice.text = "명령 거부: " + str(result.error)
 return result

func save_campaign(path: String = Session.SLOT) -> Dictionary:
 if _restore_job != null:
  return {"ok": false, "error": "checkpoint_busy"}
 var result: Dictionary = session.save_to(path)
 if operation_notice != null:
  operation_notice.text = "작전 저장 완료" if result.ok else "저장 실패: " + str(result.get("error", ""))
 return result

func load_campaign(path: String = Session.SLOT) -> Dictionary:
 if _restore_job != null:
  return {"ok": false, "error": "checkpoint_busy"}
 return _finish_load(Session.load_from(path))

func begin_campaign_restore(path: String = Session.SLOT) -> bool:
 if _restore_job != null:
  return false
 _restore_previous_state = G.state
 G.state = "restoring"
 _restore_job = RestoreWorker.new(path)
 _restore_overlay.begin()
 return true

func _update_restore() -> void:
 var result: Dictionary = _restore_job.poll()
 if result.ok and not result.done:
  if result.cancelling:
   _restore_overlay.show_cancelling()
  else:
   _restore_overlay.update_progress(result.tick, result.total)
  return
 _close_restore()
 restore_finished.emit(_finish_load(result))

func _cancel_restore() -> void:
 if _restore_job != null:
  _restore_job.request_cancel()

func _close_restore() -> void:
 _restore_job = null
 _restore_overlay.hide()
 G.state = _restore_previous_state

func _finish_load(result: Dictionary) -> Dictionary:
 if not result.ok:
  if operation_notice != null:
   operation_notice.text = "불러오기를 취소했습니다." if result.error == "checkpoint_cancelled" else "불러오기 실패: " + str(result.error)
  return result
 _install_session(result.session)
 var terminal := sim.st.over
 _show_operation("play" if terminal else RESTORED_PAUSE)
 presentation.hud.show_screen("")
 _pump()
 operation_notice.text = ("저장한 전장을 불러왔습니다." if terminal
  else "저장한 전장을 불러왔습니다. ‘출격 / 계속’을 누르면 재개합니다.")
 if terminal:
  var won: bool = session.runtime.policy.snapshot().outcome == "success"
  end_game(won, _result_text())
 return {"ok": true}

func _build_operation_ui() -> void:
 var layer := CanvasLayer.new()
 layer.layer = 12
 add_child(layer)
 var panel := PanelContainer.new()
 operation_panel = panel
 panel.position = Vector2(12, 144)
 panel.custom_minimum_size = Vector2(700, 100)
 panel.add_theme_stylebox_override("panel", UiTheme.ornate())
 layer.add_child(panel)
 var box := VBoxContainer.new()
 panel.add_child(box)
 operation_label = Label.new()
 operation_label.custom_minimum_size.x = 680
 operation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(operation_label)
 operation_notice = Label.new()
 operation_notice.custom_minimum_size.x = 680
 operation_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 operation_notice.text = "황개 필수 생존 · 유비·관우 모두 전멸하면 실패\n정찰 확인 후 황개와 생존 함대를 출구에 모아 공동 도약하세요."
 box.add_child(operation_notice)
 guidance_label = Label.new()
 guidance_label.custom_minimum_size.x = 680
 guidance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 box.add_child(guidance_label)
 escort_status = Label.new()
 escort_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 escort_status.custom_minimum_size.x = 680
 box.add_child(escort_status)
 guidance_toggle = CheckButton.new()
 guidance_toggle.text = "초보 안내 · 새 임무에서 일시정지"
 guidance_toggle.custom_minimum_size.y = 40
 guidance_toggle.button_pressed = true
 guidance_toggle.tooltip_text = "단계가 바뀌면 전투를 정지합니다. ‘출격 / 계속’으로 재개하세요. 저장 재생 중에는 적용하지 않습니다."
 box.add_child(guidance_toggle)
 var row := HFlowContainer.new()
 box.add_child(row)
 for item in [["start", "출격 / 계속"], ["huang_wait", "황개 대기"], ["huang_advance", "황개 전진"], ["confirm_jump", "공동 도약"], ["save", "저장"], ["load", "불러오기"], ["menu", "메인 메뉴"]]:
  var button := Button.new()
  button.text = item[1]
  button.custom_minimum_size = Vector2(88, 58)
  row.add_child(button)
  operation_buttons[item[0]] = button
  if item[0] == "huang_wait": button.tooltip_text = "황개를 멈춥니다. 적과 전투 시간은 계속 진행됩니다. 유비가 길목을 정리한 뒤 전진시키세요."
  if item[0] == "huang_advance": button.tooltip_text = "황개가 현재 임무의 목표로 이동합니다. 유비가 앞에서 호위할 준비가 됐는지 확인하세요."
  if item[0] == "confirm_jump": button.tooltip_text = "황개와 생존한 유비·관우 한 함대 이상이 출구 안에 함께 있어야 완료됩니다."
  match item[0]:
   "start": button.pressed.connect(func():
    _start()
    presentation.hud.show_screen(""))
   "save": button.pressed.connect(func(): save_campaign())
   "load": button.pressed.connect(func(): begin_campaign_restore())
   "menu": button.pressed.connect(func(): back_to_world())
   _: button.pressed.connect(campaign_order.bind(item[0]))
 _restore_overlay = RestoreOverlay.new()
 _restore_overlay.theme = presentation.hud.theme
 layer.add_child(_restore_overlay)
 _restore_overlay.cancelled.connect(_cancel_restore)
 _refresh_operation_ui()

func _refresh_operation_ui() -> void:
 if operation_label == null:
  return
 var state: Dictionary = session.runtime.policy.snapshot()
 operation_buttons.start.visible = G.state != "play" and state.outcome == "active"
 for name in region_markers:
  region_markers[name].visible = name in ["rendezvous", "base"] or state.recon_reported
 operation_label.text = "%s\n황개: %s | 기지 점령 %d/%d | %s" % [OBJECTIVES[state.phase],
  "대기" if state.huang_order == "wait" else "전진", session.runtime.capture_progress,
  session.runtime.definition.operation.capture_ticks, state.outcome]
 _refresh_guidance(state)
 for kind in ["huang_wait", "huang_advance", "confirm_jump"]:
  operation_buttons[kind].disabled = G.state == RESTORED_PAUSE or state.outcome != "active" or state.phase == "rendezvous" or (kind == "confirm_jump" and state.phase != "extraction")

# Legacy debug helpers are deliberately inert in this product host.
func apply_dmg(_src, _tgt, _amt: float) -> void:
 pass
func fire_missiles(f, tgt) -> void:
 issue({"kind":"missile", "ids":[f.id], "target_id":tgt.id})
func launch_fighters(f, tgt) -> void:
 issue({"kind":"fighter", "ids":[f.id], "target_id":tgt.id})
func spawn_reinf() -> void:
 pass

func _build_regions() -> void:
 var labels := {"rendezvous":"황개 합류", "base":"보급 기지", "jump":"도약 개방", "exit":"공동 철수"}
 for key in session.runtime.definition.operation.regions:
  var region: Dictionary = session.runtime.definition.operation.regions[key]
  var node := Node3D.new()
  add_child(node)
  region_markers[key] = node
  var center := Vector2(float(region.center[0]), float(region.center[1]))
  var mesh := ImmediateMesh.new()
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = Color(0.3, 0.9, 1.0)
  mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
  for i in 64:
   var a := float(i) * TAU / 64.0
   var b := float(i + 1) * TAU / 64.0
   mesh.surface_add_vertex(w3(center + Vector2(cos(a), sin(a)) * float(region.radius), 0.3))
   mesh.surface_add_vertex(w3(center + Vector2(cos(b), sin(b)) * float(region.radius), 0.3))
  mesh.surface_end()
  var visual := MeshInstance3D.new()
  visual.mesh = mesh
  node.add_child(visual)
  var label := Label3D.new()
  label.text = labels.get(key, key)
  label.position = w3(center, 1.5)
  label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  label.font_size = 32
  label.pixel_size = 0.02
  node.add_child(label)

func _result_text() -> String:
 var state: Dictionary = session.runtime.policy.snapshot()
 var text := "공동 도약 완료" if state.outcome == "success" else "황개 호위 작전 실패"
 var names := {"liu":"유비", "guan":"관우", "huang":"황개"}
 if state.outcome == "success":
  var escaped: Array = state.evacuated.map(func(alias): return names[alias])
  text += " · 귀환: 황개, " + ", ".join(escaped)
 var rows := PackedStringArray()
 for alias in ["liu", "guan", "huang"]:
  var loss: Dictionary = sim.st.result.get("losses", {}).get(alias, {})
  if not loss.is_empty():
   rows.append("%s %.1f/%.0f척" % [names[alias], float(loss.remaining)/1000.0, float(loss.initial)/1000.0])
 return text + " · 잔존 환산전력: " + " / ".join(rows)

func campaign_menu_label() -> String:
 return "메인 메뉴"

func _show_end() -> void:
 # Reserve fleets count only once deployed; early failures retain the initial denominator.
 ALLY_DEF = session.runtime.definition.profile.ally.filter(func(row):
  return sim.st.fleets.any(func(f): return f.side == 0 and f.sq_id == row.squadron_id))
 if operation_panel != null:
  operation_panel.hide()
 super._show_end()


func _refresh_guidance(state: Dictionary) -> void:
 if guidance_label == null:
  return
 var instructions := {
  "rendezvous": "1 유비 선택 → 합류 원 안의 빈 곳을 짧게 우클릭하세요. 2 관우는 후위 지원. 방향키로 화면을 이동하며, 우클릭은 끌지 마세요.",
  "escort": "먼저 ‘황개 대기’를 누르세요. 유비를 앞세워 차단군과 기지 수비대를 제압한 뒤 ‘황개 전진’을 누르세요. 관우를 혼자 먼저 보내면 피해가 집중됩니다.",
  "capture": "황개와 유비·관우 중 한 함대를 기지 원 안에 유지하세요. 적이 남거나 호위가 벗어나면 점령이 중단됩니다. 확보 시간은 3초입니다.",
  "clash": "주유·정보가 본대를 엄호합니다. 황개가 앞서면 대기시키고 유비와 함께 도약 지점으로 이동하세요. 이동 중 ×4, 교전 중 ×1을 사용할 수 있습니다.",
  "extraction": "황개와 생존 유비·관우를 공동 철수 원 안에 모으세요. 황개는 먼저 도착하면 기다립니다. 함께 도착한 뒤 ‘공동 도약’을 직접 누르세요."
 }
 var elapsed: int = maxi(0, sim.st.tick - _phase_start_tick) / BattleRules.TICK_HZ
 var phase_time := "재개 후" if _phase_resumed else "임무 경과"
 guidance_label.text = instructions[state.phase] + "\n%s %d:%02d · 전체 %d:%02d · 현재 ×%s" % [phase_time, elapsed / 60, elapsed % 60, int(G.t) / 60, int(G.t) % 60, str(G.speed)]
 var liu = session.runtime.fleet("liu")
 var guan = session.runtime.fleet("guan")
 var huang = session.runtime.fleet("huang")
 var remaining := []
 for pair in [["황개", huang], ["유비", liu], ["관우", guan]]:
  var fleet = pair[1]
  if fleet.dead or fleet.out == "sunk":
   remaining.append("%s 격침" % pair[0])
  elif fleet.out != "":
   remaining.append("%s 이탈" % pair[0])
  else:
   remaining.append("%s 선체 %d%%" % [pair[0], roundi(100.0 * float(fleet.hull) / maxi(1, fleet.max_hull))])
 escort_status.text = " · ".join(remaining)
 if G.state == "brief":
  escort_status.text += "\n기존 검증 게임 28~40분 · 이동에 ×4를 사용한 실제 실행은 약 8~11분입니다."
 elif state.outcome == "active" and not guan.dead and guan.out == "":
  var goal := "rendezvous" if state.phase == "rendezvous" else ("base" if state.phase in ["escort", "capture"] else ("jump" if state.phase == "clash" else "exit"))
  var point: Array = session.runtime.definition.operation.regions[goal].center
  var center := Vector2(point[0], point[1])
  if not liu.dead and liu.out == "" and guan.pos.distance_to(center) + 80.0 < liu.pos.distance_to(center):
   escort_status.text += "\n관우가 선행 중입니다. 2 → S로 멈추고 유비가 앞서면 이동시키세요."
  elif guan.hull * 100 < guan.max_hull * 65:
   escort_status.text += "\n관우의 피해가 큽니다. 2로 선택해 유비 뒤쪽으로 이동시키세요."
 if state.outcome == "active" and int(liu.wch.get("artillery", 0)) == 0:
  escort_status.text += "\n유비의 한정 포격 소진 · 일반 사격과 남은 함재기로 교전을 이어가세요."
 for selected_fleet in my_sel():
  for slot in selected_fleet.skills.get("slots", []):
   if slot.get("block", "") == "skill_requires_has_ship_type":
    escort_status.text += "\n%s: 필요한 함종이 없어 사용할 수 없습니다. 일반 사격과 지원 무장을 활용하세요." % slot.get("name", "특기")
    break


func _toggle_menu() -> void:
 if G.state == "guidance":
  _start()
  presentation.hud.show_screen("")
 else:
  super._toggle_menu()
