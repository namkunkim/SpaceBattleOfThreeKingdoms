"""Additional row 18 reclick contract on top of strict V4 world assessment."""
from world_product_v4 import BRIEF, CANCEL, assess as assess_v4, mismatches, read_rows

RECLICK = {
    "reclick-sortie-control": None, "reclick-sortie-pressed-once": {},
    "reclick-brief": {"brief":BRIEF},
    "reclick-skip-control": None, "reclick-skip-pressed-once": {},
    "reclick-resolver-start": {"resolve_visible":True},
    "reclick-stop-control": None, "reclick-stop-pressed-once": {},
    "reclick-cancel-join": CANCEL,
}

def assess(paths, cancel, expected_ids):
    errors = assess_v4(paths,cancel,expected_ids)
    if cancel:
        for lane,path in zip(("before","after"),paths):
            rows = read_rows(path)
            for key, expected in RECLICK.items():
                if key not in rows:
                    errors.append(f"{lane}.{key}: missing reclick action")
                elif expected is None:
                    details = rows[key]["details"]
                    if set(details) != {"path","rect"} or not all(isinstance(x,str) and x for x in details.values()):
                        errors.append(f"{lane}.{key}: missing control identity")
                else:
                    errors += mismatches(rows[key]["details"],expected,f"{lane}.{key}")
    return errors
