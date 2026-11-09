"""Strict JSON world product assessment, independent historical K4 oracle plus lifecycle."""
from decimal import Decimal
import json
from pathlib import Path

BRIEF = {"scenario_id":"RED-CLIFFS-208-RT","seed":350157,"difficulty":"표준","mode":"auto",
         "whatif_cards":[],"anchor":{"system":"SYS-13","region":"RGN-04","body":"BODY-RGN-04-01"},
         "edge_labels":{"alliance_exit":"강하","alliance_side":"적벽","cao_exit":"장강 대항로","cao_side":"오림"}}
OUTCOME = {"kind":"cao_win","win":False,"limited":False,"reason":"alliance_morale_collapse",
           "grade":"패배","cao_status":"unhurt","liu_status":"unhurt","t_s":Decimal("1054.95"),
           "loss_pct":{"alliance":39,"foe":10},"ending":"J-D7","line":"E11","seed":350157,
           "fingerprint":"3028c9c61eadaa2fb1c7a6ea2934f6d2c6b6d079491b4cd0aa1cc1f17e3835c8",
           "mode":"auto","difficulty":"표준"}
CANCEL = {"thread_joined":True,"cancelled":True,"poll":[False,False],"resolver_released":True,
          "screen_outcome":None,"resolver_outcome":None,"state":"browse","card_visible":True,
          "result_visible":False,"resolve_visible":False,"show_count":0}
POST_RESULT = {"thread_joined":True,"resolver_released":True,"state":"result","result_visible":True,
               "resolve_visible":False,"poll":[True,True],"show_count":1}

def pairs(entries):
    result = {}
    for key,value in entries:
        if key in result:
            raise ValueError(f"duplicate JSON member: {key}")
        result[key] = value
    return result

def read_rows(path):
    source = Path(path).read_text(encoding="utf-8-sig")
    payload = json.loads(source,parse_float=Decimal,object_pairs_hook=pairs)
    if not isinstance(payload,list):
        raise ValueError("expected array of assertion rows")
    if any(not isinstance(row,dict) or set(row) != {"assertion","ok","details"}
           or type(row["ok"]) is not bool or not isinstance(row["assertion"],str)
           or not isinstance(row["details"],dict) for row in payload):
        raise ValueError("invalid assertion row schema")
    return pairs((row["assertion"],row) for row in payload)

def mismatches(actual, expected, name):
    if type(actual) is not type(expected):
        return [f"{name}: expected {type(expected).__name__}, got {type(actual).__name__}"]
    if isinstance(expected,dict):
        if actual.keys() != expected.keys():
            return [f"{name}: keys differ"]
        return [e for key in expected for e in mismatches(actual[key],expected[key],f"{name}.{key}")]
    if isinstance(expected,list):
        if len(actual) != len(expected):
            return [f"{name}: list length differs"]
        return [e for index,(a,b) in enumerate(zip(actual,expected)) for e in mismatches(a,b,f"{name}[{index}]")]
    return [] if actual == expected else [f"{name}: expected {expected!r}, got {actual!r}"]

def assess(paths, cancel, expected_ids):
    rows = [read_rows(p) for p in paths]
    errors = []
    for lane, data in zip(("before","after"), rows):
        if set(data) != set(expected_ids):
            errors.append(f"{lane}: unexpected assertion ID set")
            continue
        if not all(r["ok"] for r in data.values()):
            errors.append(f"{lane}: false lifecycle assertion")
        errors += mismatches(data["sortie-brief"]["details"],{"brief":BRIEF},f"{lane}.brief")
        errors += mismatches(data["resolver-start"]["details"],{"resolve_visible":True},f"{lane}.start")
        if cancel:
            errors += mismatches(data["cancel-join"]["details"],CANCEL,f"{lane}.cancel")
        else:
            expect = {"fingerprint":OUTCOME["fingerprint"],"outcome":OUTCOME,"show_count":1}
            errors += mismatches(data["result-join"]["details"],expect,f"{lane}.terminal")
            errors += mismatches(data["poll-idempotent"]["details"],POST_RESULT,f"{lane}.poll")
    if len(rows) != 2:
        return ["expected before/after pair"]
    return errors + mismatches(list(rows[0].values()),list(rows[1].values()),"B/A lifecycle raw")

