"""Local unit smoke. This is not the independent case transcript."""
import hashlib

from c_actual_extension_raw_v3 import split_stdout, strict

nil = (0, (), None)
first = ((4, (), "a"), nil)
second = ((4, (), "b"), nil)
assert not strict((27, (None, None), (first, second)), (27, (None, None), (second, first)))
assert not strict((28, (None,), ()), (28, (2,), ()))
assert not strict((4, (), "x"), (21, (), "x"))
assert not strict((2, (), 1), (3, (), 1.0))
assert not strict((3, (), 0.0), (3, (), -0.0))
receipt = dict(lane="before", pid=1, created=2, run_id="smoke", raw_sha="unit")
base_line = b"K6_C_PRODUCER {}\n"
supp_line = (b'K6_C_EXTENSION {"version":1,"ordinal":0,"base_ordinal_next":1,'
             b'"case":{},"event":"identity","payload_hex":"1b00000000000000"}\n')
base, supplement = split_stdout(base_line + supp_line, receipt)
assert base == [(0, hashlib.sha256(base_line).hexdigest())]
assert supplement[0]["provenance"]["offset"] == len(base_line)
assert supplement[0]["provenance"]["line_sha"] == hashlib.sha256(supp_line).hexdigest()
for data, reason in (
    (supp_line + base_line, "mixed stream ordinal"),
    (base_line + supp_line + supp_line, "supplement global ordinal"),
    (base_line + supp_line[:-1], "unterminated supplement record"),
    (base_line + b"X K6_C_EXTENSION {}\n", "unexpected C record prefix"),
):
    try:
        split_stdout(data, receipt)
    except ValueError as error:
        assert str(error) == reason, error
    else:
        raise AssertionError(reason)
print("typed negatives 5, splitter positive 1, splitter negatives 4")
