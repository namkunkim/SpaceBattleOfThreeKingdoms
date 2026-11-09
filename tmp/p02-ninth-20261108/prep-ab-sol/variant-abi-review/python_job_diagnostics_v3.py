"""Bounded in-memory diagnostic streams for the Python Job qualification."""
import threading
from abi_oracle_v2 import OutputLimit

class BoundedDiagnostics:
    def __init__(self,cap):
        self.limit=OutputLimit(cap)
        self.errors=[]
        self.output=[bytearray(),bytearray()]
        self.readers=[]

    def attach(self,proc):
        for slot,pipe in enumerate((proc.stdout,proc.stderr)):
            thread=threading.Thread(target=self.read,args=(slot,pipe),daemon=True)
            thread.start()
            self.readers.append(thread)

    def read(self,slot,pipe):
        try:
            while not self.limit.exceeded.is_set():
                data=pipe.read1(4096)
                if not data:
                    break
                self.output[slot].extend(self.limit.accept(data))
        except OSError as exc:
            self.errors.append(type(exc).__name__)
        finally:
            pipe.close()

    def finish(self,deadline):
        import time
        for thread in self.readers:
            thread.join(max(0,deadline-time.monotonic()))
        return not self.errors and not self.limit.exceeded.is_set() and not any(t.is_alive() for t in self.readers)
