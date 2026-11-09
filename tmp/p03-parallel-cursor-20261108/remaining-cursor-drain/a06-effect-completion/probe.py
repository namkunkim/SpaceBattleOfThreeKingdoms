import json
from pathlib import Path
import sys

from receiver import observe


def encode(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


expectations = json.loads(Path(__file__).with_name("expected.json").read_text(encoding="utf-8-sig"))
failures = 0
for case, expected in expectations.items():
    print(f"CASE_START {case}")
    actual = observe(case)
    for index, (got, want) in enumerate(zip(actual, expected, strict=True), 1):
        passed = encode(got) == encode(want)
        failures += not passed
        print(f"CHECK {case}:{index} {'PASS' if passed else 'FAIL'} {encode(got)}")
    print(f"CASE_END {case}")
sys.exit(bool(failures))
