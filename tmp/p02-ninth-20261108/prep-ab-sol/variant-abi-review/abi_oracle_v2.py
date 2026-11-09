"""Strict stderr/stdout/exit and shared streaming output cap for the ABI probe."""
from pathlib import Path
import sys
import threading

from abi_oracle import check as check_values
from legacy_autoresolve_oracle import need

BANNER="Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org"
LIMIT=262144

class OutputLimit:
    def __init__(self,cap=LIMIT):
        self.cap=cap
        self.total=0
        self.exceeded=threading.Event()
        self.lock=threading.Lock()

    def accept(self,chunk):
        with self.lock:
            remaining=max(0,self.cap-self.total)
            kept=chunk[:remaining]
            self.total+=len(kept)
            if len(kept)!=len(chunk):
                self.exceeded.set()
            return kept

def verify(stdout,stderr,exit_code,interruption):
    need(type(exit_code) is int and exit_code==0,"engine exit")
    need(interruption is None,"interrupted engine")
    need(len(stdout)+len(stderr)<=LIMIT,"output exceeds combined cap")
    need(not stderr,"unexpected stderr bytes")
    need(stdout.endswith(b"\n"),"stdout final line not flushed")
    lines=stdout.decode("utf-8",errors="strict").splitlines()
    need(bool(lines) and lines[0]==BANNER,"unexpected engine banner")
    body=lines[1:]
    if body and not body[0]:
        body=body[1:]
    need(len(body)==10,"exactly ten ABI lines after banner")
    need(all(line.startswith("P02_ABI ") for line in body),"unexpected engine stdout diagnostic")
    check_values("\n".join(body),"")
