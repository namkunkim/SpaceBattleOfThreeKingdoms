from pathlib import Path
p=Path(__file__).resolve().parent
f=p/"world-product-v5.gd"
s=f.read_text(encoding="utf-8-sig")
a=s.index('\tif args[0] == "cancel":')
b=s.index('\n\telse:',a)
old=s[a:b]
cancel=old.split('\n',1)[1].replace('await click(button_named(w._resolve, "중단하고 돌아가기"), "stop")','await click(button_named(w._resolve, "중단하고 돌아가기"), prefix + "stop")').replace('check("cancel-join",','check(prefix + "cancel-join",')
cancel=cancel.replace('var poll := [resolver.poll(), resolver.poll()]', 'if resolver._thread != null:\n\t\t\tfail_complete(resolver, visible_count[0], prefix + "cancel-button-did-not-join")\n\t\t\treturn\n\t\tvar poll := [resolver.poll(), resolver.poll()]')
cancel='\n'.join(line[1:] for line in cancel.split('\n'))
helper='func cancel_cycle(resolver: AutoResolver, visible_count: Array, prefix: String) -> void:\n'+cancel+'\n\n'
s=s[:a]+'''	if args[0] == "cancel":
		await cancel_cycle(resolver, visible_count, "")
		if failures != 0:
			quit(1)
			return
		await click(button_named(w._card, "출  격"), "reclick-sortie", true)
		check("reclick-brief", w.state == "sortie" and w.brief != null and w.brief.seed == expected_seed,
			{"brief":w.brief.to_dict() if w.brief else {}})
		await click(w._skip, "reclick-skip")
		var again: AutoResolver = w.resolver
		check("reclick-resolver-start", w.state == "resolve" and again != null and again != resolver and again._thread != null and again._thread.is_started(),
			{"resolve_visible":w._resolve.visible})
		if again != null:
			await cancel_cycle(again, visible_count, "reclick-")'''+s[b:]
s=s.replace('func _run() -> void:',helper+'func _run() -> void:')
f.write_text(s,encoding="utf-8")

