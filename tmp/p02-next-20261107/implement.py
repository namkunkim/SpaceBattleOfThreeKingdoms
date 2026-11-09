from pathlib import Path
p=Path("scripts/world/auto_resolver.gd")
b=p.read_bytes()
nl=b"\r\n" if b"\r\n" in b else b"\n"
s=b.decode().replace("\r\n","\n")
s=s.replace("const MAX_S",'''const OperationAdapter := preload("res://core/battle/operation_runtime_adapter.gd")
const OperationData := preload("res://core/battle/operation_service_state.gd")
const OPERATION_MAX_TICKS := 18000

const MAX_S''',1)
s=s.replace("func _init",'''var _operation_thread: Thread
var _operation_mutex := Mutex.new()
var _operation_cancelled := false
var _operation_result: Dictionary = {}

func _init''',1)
for signature, fallback in [("run_blocking() -> BattleOutcome", "null"),("start() -> bool","false")]:
 s=s.replace(f"func {signature}:\n",f"func {signature}:\n\tif _operation_thread != null:\n\t\treturn {fallback}\n",1)
s+='''
# The starting main-thread caller must finish with poll or cancel.
func start_operation(input: Variant) -> Dictionary:
	if _thread != null or _operation_thread != null:
		return OperationAdapter.fail("busy", "worker")
	if not OperationData._data(input):
		return OperationAdapter.fail("invalid_worker_input", "input")
	var snapshot: Variant = input.duplicate(true) if input is Array or input is Dictionary else input
	var thread := Thread.new()
	_operation_mutex.lock()
	_operation_cancelled = false
	_operation_mutex.unlock()
	var code := thread.start(_run_operation.bind(snapshot))
	if code != OK:
		var failure := OperationAdapter.fail("worker_start_failed", "worker")
		failure["godot_error"] = code
		return failure
	_operation_thread = thread
	_operation_result = {}
	return {"ok": true, "status": "running"}

func poll_operation() -> Dictionary:
	if _operation_thread != null:
		if _operation_thread.is_alive():
			return {"ok": true, "status": "running"}
		_operation_result = _operation_thread.wait_to_finish()
		_operation_thread = null
	if _operation_result.is_empty():
		return {"ok": true, "status": "idle"}
	return _operation_result.duplicate(true)

func cancel_operation() -> void:
	if _operation_thread == null:
		return
	_operation_mutex.lock()
	_operation_cancelled = true
	_operation_mutex.unlock()
	_operation_thread.wait_to_finish()
	_operation_thread = null

func _operation_should_cancel() -> bool:
	_operation_mutex.lock()
	var cancelled := _operation_cancelled
	_operation_mutex.unlock()
	return cancelled

func _run_operation(snapshot: Variant) -> Dictionary:
	if _operation_should_cancel():
		return OperationAdapter.fail("cancelled", "worker")
	var created := OperationAdapter.create(snapshot)
	if not created.ok:
		return created
	var owner: OperationPrivateState = created.owner
	var result := _advance_operation(owner, snapshot.initial_controls, created.policy, created.max_ticks)
	owner.close()
	if _operation_should_cancel():
		return OperationAdapter.fail("cancelled", "worker")
	if result.ok:
		result["meta"] = created.meta
		result.meta["executor"] = "worker"
	return result

func _advance_operation(owner: OperationPrivateState, controls: Array, policy: String, max_ticks: int) -> Dictionary:
	if policy != "none":
		return OperationAdapter.fail("unsupported_worker_policy", "policy")
	if controls.is_empty() or controls.count("delegate") != controls.size():
		return OperationAdapter.fail("worker_requires_delegate", "initial_controls")
	if max_ticks > OPERATION_MAX_TICKS:
		return OperationAdapter.fail("worker_tick_limit", "max_ticks")
	var events: Array = []
	var read := owner.summary()
	if not read.ok:
		return read
	while not read.summary.over and read.summary.tick < max_ticks:
		if _operation_should_cancel():
			return OperationAdapter.fail("cancelled", "worker")
		var advanced := owner.advance()
		if not advanced.ok:
			return advanced
		var drained := owner.drain_events()
		if not drained.ok:
			return drained
		events.append_array(drained.events)
		read = owner.summary()
		if not read.ok:
			return read
	return {"ok": true, "summary": read.summary, "events": events, "event_count": events.size()}
'''
p.write_bytes(s.encode().replace(b"\n",nl))
p=Path("tests/autoresolve.gd")
b=p.read_bytes()
nl=b"\r\n" if b"\r\n" in b else b"\n"
s=b.decode().replace("\r\n","\n")
s=s.replace('if "--operation-input" in OS.get_cmdline_user_args():','''if "--operation-worker" in OS.get_cmdline_user_args():
		_run_operation_worker_cli()
		return
	if "--operation-input" in OS.get_cmdline_user_args():''',1)
s=s.replace('func _operation_options(args: PackedStringArray)', 'func _operation_options(args: PackedStringArray, input_option := "--operation-input")')
s=s.replace('var values := {}\n\tvar legacy', '''if "--operation-input" in args and "--operation-worker" in args:
		return adapter.fail("conflicting_option", "--operation-input")
	var values := {}
	var legacy''',1)
s=s.replace('["--operation-input", "--out"]','[input_option, "--out"]').replace('values["--operation-input"]','values[input_option]')
marker='\t# Recheck before WRITE.'
pos=s.index(marker)
s=s[:pos]+'''	_write_operation_result(result, options.out)

func _run_operation_worker_cli() -> void:
	var adapter := preload("res://core/battle/operation_runtime_adapter.gd")
	var options := _operation_options(OS.get_cmdline_user_args(), "--operation-worker")
	if not options.ok:
		_operation_reject(options)
		return
	var input_file := FileAccess.open(options.input, FileAccess.READ)
	if input_file == null:
		_operation_reject(adapter.fail("input_read_failed", "input"))
		return
	var length := input_file.get_length()
	var bytes := input_file.get_buffer(length)
	var read_error := input_file.get_error()
	input_file.close()
	if bytes.size() != length or read_error not in [OK, ERR_FILE_EOF]:
		_operation_reject(adapter.fail("input_read_failed", "input"))
		return
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		hash.update(bytes)
	var input_sha := hash.finish().hex_encode()
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK:
		_operation_reject(adapter.fail("invalid_json", "input"))
		return
	var output_error := _operation_output_error(options.out)
	if output_error != "":
		_operation_reject(adapter.fail(output_error, "out"))
		return
	var resolver := AutoResolver.new(null)
	var result := resolver.start_operation(parser.data)
	while result.get("status") == "running":
		await process_frame
		result = resolver.poll_operation()
	if not result.ok:
		_operation_reject(result)
		return
	result.meta["input_file_sha256"] = input_sha
	_write_operation_result(result, options.out)

func _write_operation_result(result: Dictionary, out_path: String) -> void:
	var adapter := preload("res://core/battle/operation_runtime_adapter.gd")
'''+s[pos:]
pos=s.index('func _write_operation_result')
end=s.index('# 정책은 공개',pos)
s=s[:pos]+s[pos:end].replace('output_error = _operation_output_error(options.out)','var output_error := _operation_output_error(out_path)').replace('options.out','out_path')+s[end:]
p.write_bytes(s.encode().replace(b"\n",nl))
