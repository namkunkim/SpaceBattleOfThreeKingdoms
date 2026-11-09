"""Nonproduct Python payload for owned-job qualification."""
import os
import sys
import time

mode=sys.argv[1]
print(f"OWNED_TEST {mode} {os.getpid()}",flush=True)
if mode=="sentinel":
    raise SystemExit(0 if sys.stdin.buffer.read(1)==b"x" else 7)
if mode=="normal":
    time.sleep(.8)
elif mode in ("timeout","outer-stall"):
    time.sleep(30)
elif mode=="output-cap":
    time.sleep(.6)
    sys.stdout.buffer.write(b"x"*300000)
    sys.stdout.buffer.flush()
elif mode in ("observation-negative","journal-negative"):
    time.sleep(.8)
else:
    raise SystemExit(8)
