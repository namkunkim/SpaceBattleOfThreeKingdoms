"""Source-order regression check and pure timeout JSON counterexamples."""
import ast
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from world_product_v4 import assess, read_rows, POST_RESULT

here = Path(__file__).resolve().parent
v5 = (here / "world-product-v5.gd").read_text(encoding="utf-8")
v4 = (here / "world-product-v4.gd").read_text(encoding="utf-8-sig")
base = here / "v5-synthetic"
base.mkdir()

def static_order(s):
    run = s.split("func _run() -> void:",1)[-1]
    prefix = run.split("resolver.sim.fingerprint()",1)[0]
    guard = 'if Time.get_ticks_msec() >= deadline:\n\t\t\tfail_complete(resolver, visible_count[0], "deadline-175000ms")\n\t\t\treturn'
    terminal = 'if resolver._thread != null or resolver.sim == null:\n\t\t\tfail_complete(resolver, visible_count[0], "terminal-worker-or-sim-invalid")\n\t\t\treturn'
    if "func fail_complete" not in s or guard not in prefix or terminal not in prefix:
        return False
    helper = s.split("func fail_complete",1)[1].split("func _run",1)[0]
    return ("resolver.sim" not in helper and "175000" in prefix and
            helper.index('check("complete-aborted", false') < helper.index("w._cancel_resolve()") <
            helper.index('check("abort-joined-without-result"') < helper.index("quit(1)"))

checks = {"v5-static-guard-and-abort-order":static_order(v5),
          "v4-live-read-counterexample-rejected":not static_order(v4),
          "deleted-deadline-return-rejected":not static_order(v5.replace('"deadline-175000ms")\n\t\t\treturn','"deadline-175000ms")')),
          "added-live-sim-read-rejected":not static_order(v5.replace('var joined :=','resolver.sim.fingerprint()\n\tvar joined :='))}
history = here.parents[1]/"p02-eighth-20261108/gate-k4/before-world-complete/result.json"
rows = read_rows(history)
expected = list(rows)
rows["poll-idempotent"]["details"] = POST_RESULT
def save(name, payload):
    path = base/name
    path.write_text(json.dumps(payload,ensure_ascii=False,default=float),encoding="utf-8")
    return path

good = save("complete-synthetic.json",list(rows.values()))
prior = [row for key,row in rows.items() if key not in ("result-join","poll-idempotent")]
failed = {"assertion":"complete-aborted","ok":False,"details":{"reason":"deadline-175000ms","state":"resolve","worker_present":True,"result_visible":False,"show_count":0}}
joined = {"assertion":"abort-joined-without-result","ok":True,"details":{"thread_joined":True,"cancelled":True,"state":"browse","resolver_released":True,"resolve_visible":False,"result_visible":False,"show_count":0,"screen_outcome_absent":True,"resolver_outcome_absent":True}}
for name,payload in (("joined-timeout",prior+[failed,joined]),("interrupted-join",prior+[failed]),
                     ("terminal-plus-timeout",list(rows.values())+[failed,joined])):
    path = save(name+".json",payload)
    checks[name+"-cannot-pass"] = bool(assess([good,path],False,expected))
assert all(checks.values()), checks
save("results.json",checks)
print(json.dumps(checks))
