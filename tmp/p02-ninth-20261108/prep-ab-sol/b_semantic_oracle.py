"""Source-derived ordered semantic labels for WorldLink B, independent of runtime expected objects."""
from legacy_autoresolve_oracle import need, same

HEADER = ("천하","형주","구지")
STAGES = {
    "Z0": HEADER + ("적벽으로",),
    "card": HEADER + ("입문","표준","상급","극한","직접 지휘","자동 해결","출  격"),
    "battle-result": ("천하로","다시 출격"),
    "world-result": HEADER + ("천하 보기","같은 판 다시","새 판"),
}

def check(rows):
    expected=[(stage,device,ordinal,label) for stage,labels in STAGES.items()
              for device in range(3) for ordinal,label in enumerate(labels)]
    observed=[]
    paths={}
    for item in rows:
        need(item.keys()=={"stage","device","ordinal","path","label","visible","enabled"},"B semantic row schema")
        need(item["visible"] is True and item["enabled"] is True,"B hidden or disabled button")
        need(type(item["device"]) is int and type(item["ordinal"]) is int,"B ordinal type")
        path=item["path"]
        need(type(path) is str and path.startswith("/"),"B actual path")
        stage_paths=paths.setdefault(item["stage"],{})
        slot=item["ordinal"]
        if slot in stage_paths:
            need(stage_paths[slot]==path,"B device path drift")
        else:
            need(path not in stage_paths.values(),"B path aliased across semantic slots")
            stage_paths[slot]=path
        observed.append((item["stage"],item["device"],slot,item["label"]))
    need(observed==expected,"B frozen semantic stage and order")
