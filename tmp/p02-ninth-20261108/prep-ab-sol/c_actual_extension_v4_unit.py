"""Wire-level local smoke. No independent dynamic case data are fabricated."""
from c_actual_extension_raw_v4 import original_variant, strict
from c_actual_extension_wire_v4 import decode_wire

assert decode_wire("02000000ffffff7f")[2] == 2147483647
assert decode_wire("020001000000008000000000")[2] == 2147483648
assert decode_wire("02000100ffffffff00000000")[2] == 4294967295
assert decode_wire("030001009a9999999999b93f")[1] == (1,)
assert not strict(decode_wire("050000000000000000000000"),
                  decode_wire("0500010000000000000000000000000000000000"))
assert not strict(decode_wire("1c00000000000000"), decode_wire("1c0001000200000000000000"))
assert not strict(
    decode_wire("1b00000002000000020000000100000000000000020000000200000000000000"),
    decode_wire("1b00000002000000020000000200000000000000020000000100000000000000"),
)
for wire, reason in (
    ("020001000100000000000000", "noncanonical Variant integer width"),
    ("03000100000000000000f03f", "noncanonical Variant float width"),
    ("0200020001000000", "unsupported Variant tag/flags 2/2"),
):
    try:
        decode_wire(wire)
    except ValueError as error:
        assert str(error) == reason
    else:
        raise AssertionError(reason)

row = dict(event="restore-request", actor="restore-target", phase="estimated/primary",
           payload_hex="1b00000000000000")
assert original_variant([row], row["event"], row["actor"], row["phase"]) == {}
try:
    original_variant([row, dict(row)], row["event"], row["actor"], row["phase"])
except ValueError as error:
    assert str(error) == "base typed boundary"
else:
    raise AssertionError("duplicate phase accepted")
print("wire unit smoke passed; independent dynamic control and 11 integrated cases not run")
