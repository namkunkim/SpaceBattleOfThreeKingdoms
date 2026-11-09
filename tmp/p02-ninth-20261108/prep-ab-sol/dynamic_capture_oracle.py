"""Validate independently produced K6 Q/C/B capture pairs. Never launches Godot."""
import argparse
from pathlib import Path

from legacy_autoresolve_oracle import load, need, same

SCHEMAS = {
    "q": (("case", "seed", "tick"), "commands"),
    "c": (("case", "seed", "phase", "side"), "records"),
    "b": (("stage",), "buttons"),
}
STAGES = ("Z0", "card", "battle-result", "world-result")

def fields(item, names, where):
    need(type(item) is dict and item.keys() == set(names), f"{where}: fields")

def integer(value, where):
    need(type(value) is int, f"{where}: integer token")

def rows(kind, data):
    key_fields, items = SCHEMAS[kind]
    need(type(data) is list and data, f"{kind}: capture array")
    seen = set()
    for i, item in enumerate(data):
        where = f"{kind}[{i}]"
        fields(item, (*key_fields, items), where)
        for k in key_fields:
            if k in {"seed", "tick", "side"}:
                integer(item[k], f"{where}.{k}")
            else:
                need(type(item[k]) is str and item[k], f"{where}.{k}: text")
        key = tuple(item[k] for k in key_fields)
        need(key not in seen, f"{where}: duplicate capture key")
        seen.add(key)
        need(type(item[items]) is list, f"{where}.{items}: array")
        if kind == "q":
            need(0 <= item["tick"] < 1200, f"{where}: tick range")
        if kind == "c":
            need(item["side"] in (0, 1), f"{where}: side")
        entity_ids = set()
        for j, entity in enumerate(item[items]):
            pos = f"{where}.{items}[{j}]"
            if kind == "q":
                fields(entity, ("ordinal", "typed_tuple"), pos)
                integer(entity["ordinal"], pos)
                need(entity["ordinal"] == j, f"{pos}: command ordinal")
                need(type(entity["typed_tuple"]) is str and entity["typed_tuple"], f"{pos}: typed payload")
                continue
            if kind == "c":
                fields(entity, ("id", "typed_payload"), pos)
                integer(entity["id"], pos)
                need(type(entity["typed_payload"]) is str and entity["typed_payload"], f"{pos}: typed payload")
                identity = entity["id"]
            else:
                fields(entity, ("path", "device"), pos)
                integer(entity["device"], pos)
                need(entity["device"] in (0, 1, 2), f"{pos}: device range")
                need(type(entity["path"]) is str and entity["path"].startswith("/"), f"{pos}: NodePath")
                identity = (entity["path"], entity["device"])
            need(identity not in entity_ids, f"{pos}: duplicate identity")
            entity_ids.add(identity)
        if kind == "b":
            paths = [entity["path"] for entity in item[items] if entity["device"] == 0]
            order = [(path, device) for device in range(3) for path in paths]
            need([(e["path"], e["device"]) for e in item[items]] == order, f"{where}: device/path order")
    if kind == "b":
        need(tuple(item["stage"] for item in data) == STAGES, "B: all stage IDs in order")

def compare(kind, expected, actual):
    rows(kind, expected)
    rows(kind, actual)
    same(expected, actual)

def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("kind", choices=SCHEMAS)
    cli.add_argument("expected", type=Path)
    cli.add_argument("actual", type=Path)
    args = cli.parse_args()
    compare(args.kind, load(args.expected), load(args.actual))

if __name__ == "__main__":
    main()
