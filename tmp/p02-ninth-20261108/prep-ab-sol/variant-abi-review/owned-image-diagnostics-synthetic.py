"""Synthetic diagnostics tests. No native API, files from other apps, or processes."""
import json
from owned_image_diagnostics_review import Failures,observe

class Fake:
    def __init__(self,image="C:/Python314/python.exe",pid=42,created=123,owned=(True,True),signals=(False,False)):
        self.path=image
        self.pid_value=pid
        self.created=created
        self.owned=iter(owned)
        self.signals=iter(signals)
        self.image_reads=0
    def in_job(self,_):return next(self.owned)
    def signalled(self,_):return next(self.signals)
    def pid(self,_):return self.pid_value
    def creation_time(self,_):return self.created
    def image(self,_):
        self.image_reads+=1
        return self.path

def inspect(api,prior=None):
    return observe(api,object(),42,"normal/outer",("C:/Python314/python.exe",),prior)

assert inspect(Fake(image="c:\\python314\\PYTHON.EXE")).outcome=="allowed"
bad=inspect(Fake(image="C:/Synthetic/unexpected.exe"))
assert bad.outcome=="unexpected-owned-image" and bad.image_raw=="C:/Synthetic/unexpected.exe"
assert bad.image_normalized==r"c:\synthetic\unexpected.exe" and bad.member_after is True
assert bad.creation_time==123 and bad.pid==42
print("preserved full synthetic mismatched image; unchanged allowlist; accepted only equivalent spelling")

unowned=Fake(owned=(False,))
assert inspect(unowned).outcome=="not-owned" and unowned.image_reads==0
short=Fake(signals=(True,))
assert inspect(short).outcome=="short-lived-before-inspection" and short.image_reads==0
reused=Fake(created=789)
assert inspect(reused,123).outcome=="pid-reuse" and reused.image_reads==0
lost=inspect(Fake(owned=(True,False)))
assert lost.outcome=="membership-lost" and lost.image_raw is None
missing=inspect(Fake(image=None))
assert missing.outcome=="image-unavailable" and missing.image_raw is None
print("rejected nonowned, short-lived, reused PID, lost ownership and missing image")

fail=Failures()
fail.set_first("unexpected-owned-image",bad)
fail.set_first("missing-payload")
fail.set_cleanup("payload-unobserved",True)
value=json.loads(fail.serialize())
assert value["first"]["code"]=="unexpected-owned-image"
assert value["cleanup"]=={"code":"payload-unobserved","drained":True}
try:Failures(first={"code":"unknown"}).serialize()
except ValueError as error:print("rejected missing cleanup receipt",str(error))
else:raise AssertionError("missing receipt")
print("preserved primary and cleanup failures separately; synthetic only")
