# P03/O07 Windows child-process cutpoint diagnostic

Exact runtime source: b2ba73ff5b3c18a7ab0885d00cebf0c25be7fed1. The standalone F project copies first_operation_save_store.gd as the exact Git blob a74141839389df693940f77f1417c61a000f83f3, without touching product files or original profiles. Three input saves are read-only copies of real public P03 saves, pinned in run-1/RESULT.json. Only the harness creates new files inside its isolated F profiles.

## Actual termination and recovery

| Cutpoint | Writer PID / exit | Slot when terminated | Fresh read | Default retry and fresh reopen |
| --- | --- | --- | --- | --- |
| Existing publisher callback, after real write, flush, close and verification | 27428 / 1 | Primary B, previous A, staged C | B; bytes unchanged | C in primary, B in previous, original staged C unchanged |
| After the callback performs the same primary-to-previous DirAccess rename as the default branch | 20568 / 1 | Primary missing, previous B, staged C | B; no primary created and bytes unchanged | C in primary, B in previous, original staged C unchanged |

The parent validates the marker PID, exact phase, profile and file hashes while its own Popen child is still alive, calls kill on that child only, and verifies the pre/post layouts. There are two terminated writer processes plus seven fresh successful processes, including the exact default-write oracle. All captured logs were free of engine errors and warnings.

The first harness attempt (sibling p03-store-child-cutpoint-b2ba73ff-01) stopped after observing the first marker because it incorrectly compared the staged bytes to the original fixture C envelope. Godot parses and reserializes numeric values from the fixture, which changes lexical bytes while preserving the payload. The first attempt's stage, marker, runner and logs remain in that sibling. The successful attempt pins the exact output of a fresh product default-write C oracle (SHA-256 09fc3b6510dfd038123ac36ad60943decbc1c22d21721fcd8fedcafd944ebbeb) before either cutpoint. Both observed stage files and both final primaries match those exact bytes. Original A/B/C file hashes remained unchanged.

## Scope

The product Store's staging, read selection, default retry, and reopen ran unchanged. The after-rotate cutpoint uses the existing publisher injection to reproduce the default branch's one rename, so this is not a process interruption inside the uninstrumented branch. This test does not repeat the prior native terminal/supply cutpoints. It does not establish operating-system power-loss durability, native release DLL, UI or cross-operation/global-cursor acceptance. There is no product patch or push candidate.

Raw receipt: run-1/RESULT.json (SHA-256 6b666a1ebc5ca1599ad7251d43900d4789ce27acc474fb8392aca4b3e2d8675b). Rerun by copying the standalone project and runner into a new versioned sibling folder; the runner intentionally refuses to overwrite its run-1 evidence.
