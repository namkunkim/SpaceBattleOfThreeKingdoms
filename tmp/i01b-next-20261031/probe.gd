extends SceneTree
const Service = preload("res://core/battle/operation_service_state.gd")
func walk(v: Variant, path: String, ancestors: Array = []) -> void:
	if v is Dictionary or v is Array:
		for a in ancestors:
			if is_same(v,a): print("CYCLE ",path); return
		var next := ancestors.duplicate()
		next.append(v)
		if v is Dictionary:
			for k in v:
				if typeof(k) not in [TYPE_INT,TYPE_STRING]: print("KEY ",path," ",type_string(typeof(k))," ",k)
				walk(v[k],path+"/"+str(k),next)
		else:
			for i in v.size(): walk(v[i],path+"/"+str(i),next)
	elif not Service._data(v): print("BAD ",path," ",type_string(typeof(v))," ",str(v))
func _initialize() -> void:
	var full = SalvoFixture.combat()
	var s = SalvoFixture.sim([SalvoFixture.def("A",400,450,[["SHP-01",10]],true)],[SalvoFixture.def("B",500,450,[["SHP-02",4]],true)],1,"",func(cb):cb.detection=full.detection)
	walk(Service._context(s),"context")
	print("context valid=", Service._data(Service._context(s)))
	quit()