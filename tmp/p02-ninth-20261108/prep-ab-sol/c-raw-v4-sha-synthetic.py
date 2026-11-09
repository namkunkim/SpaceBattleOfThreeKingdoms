"""Synthetic raw-byte/text-hash distinction, never invokes Godot."""
import hashlib
from c_raw_v4_semantic_adapter import packet_bytes

value=bytes.fromhex("0200000001000000")
raw=value.hex()
raw_hash=hashlib.sha256(value).hexdigest()
assert packet_bytes(raw,raw_hash)==raw
print("accepted independent SHA over actual byte sequence")
for name,hex_value,digest in (
    ("hex text hash",raw,hashlib.sha256(raw.encode()).hexdigest()),
    ("same claimed SHA over modified bytes",value[:-1].hex()+"01",raw_hash),
    ("noncanonical upper-case hex","aaAA"+raw[4:],raw_hash),
    ("odd hex",raw[:-1],raw_hash),
):
    try:packet_bytes(hex_value,digest)
    except ValueError as e:print("rejected",name,str(e))
    else:raise AssertionError(name)
print("synthetic only")
