"""Synthetic only. No native handles, process launches, or existing file changes."""
from diagnostic_owner_candidate import MAX_PATH_CHARS,diagnostic_record,encode_record
from owned_image_diagnostics_review import Failures

allow=("c:\\python314\\python.exe",)
raw=r"C:\Python314\PYTHON.EXE"
row=diagnostic_record("normal/outer",42,123,raw,allow,"unexpected-owned-image",
                      resolve=lambda _:r"c:\other\python.exe")
assert row["image_lexical"]==allow[0] and row["image_resolved"]!=allow[0]
assert row["image_raw"]==raw and b"unexpected-owned-image" in encode_record(row)
print("lexical match does not override distinct original resolver result")

def reject(name,callback):
    try:callback()
    except ValueError as error:print("rejected",name,str(error))
    else:raise AssertionError(name)
reject("pre-serialization path overflow",lambda:diagnostic_record(
       "normal/outer",42,123,"C:/"+("x"*MAX_PATH_CHARS),allow,"unexpected-owned-image"))
reject("encoded frame overflow",lambda:encode_record({"raw":"\u2028"*3000}))
fail=Failures()
fail.set_first("unexpected-owned-image")
fail.set_first("payload-unobserved")
fail.set_cleanup("payload-unobserved",True)
assert b'"first":{"code":"unexpected-owned-image"' in fail.serialize()
assert b'"cleanup":{"code":"payload-unobserved"' in fail.serialize()
print("primary and cleanup separately preserved")
print("synthetic only")
