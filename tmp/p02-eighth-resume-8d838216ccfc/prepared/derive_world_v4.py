from pathlib import Path
p=Path(__file__).resolve().parent
source=p.parents[1]/"p02-seventh-20261108/k5-world-product.gd"
s=source.read_text(encoding="utf-8-sig")
s=s.replace('''	if args[0] == "cancel":
''','''	var visible_count := [0]
	w._result.visibility_changed.connect(func():
		if w._result.visible:
			visible_count[0] += 1)
	if args[0] == "cancel":
''')
old='''		check("cancel-join", resolver._thread == null and resolver._cancel and not resolver.poll() and w.resolver == null and w.outcome == null and resolver.outcome == null and w.state == "browse" and w._card.visible and not w._result.visible and not w._resolve.visible)'''
new='''		var poll := [resolver.poll(), resolver.poll()]
		check("cancel-join", resolver._thread == null and resolver._cancel and poll == [false, false] and w.resolver == null and w.outcome == null and resolver.outcome == null and w.state == "browse" and w._card.visible and not w._result.visible and not w._resolve.visible and visible_count[0] == 0,
			{"thread_joined":resolver._thread == null, "cancelled":resolver._cancel, "poll":poll, "resolver_released":w.resolver == null,
			"screen_outcome":w.outcome.to_dict() if w.outcome else null, "resolver_outcome":resolver.outcome.to_dict() if resolver.outcome else null,
			"state":w.state, "card_visible":w._card.visible, "result_visible":w._result.visible, "resolve_visible":w._resolve.visible, "show_count":visible_count[0]})'''
assert s.count(old)==1
s=s.replace(old,new)
s=s.replace('''	else:
		var visible_count := [0]
		w._result.visibility_changed.connect(func():
			if w._result.visible:
				visible_count[0] += 1)
''','''	else:
''')
old='''		check("poll-idempotent", resolver.poll() and resolver.poll() and resolver.outcome == result and w.outcome == result and visible_count[0] == 1)'''
new='''		var poll := [resolver.poll(), resolver.poll()]
		check("poll-idempotent", poll == [true,true] and resolver.outcome == result and w.outcome == result and visible_count[0] == 1,
			{"thread_joined":resolver._thread == null, "resolver_released":w.resolver == null, "state":w.state,
			"result_visible":w._result.visible, "resolve_visible":w._resolve.visible, "poll":poll, "show_count":visible_count[0]})'''
assert s.count(old)==1
s=s.replace(old,new)
with (p/"world-product-v4.gd").open("x",encoding="utf-8") as f:
    f.write(s)
