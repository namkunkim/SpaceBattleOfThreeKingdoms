# Attempt2 test oracle correction

11/7 actual exit1, SCRIPT ERROR0, assertion ERROR2 (T01/T02 timeout raw one step). No CLI/regressions started. All source/log/exit/observations preserved. Strict same() correctly distinguishes Array typing. The consumer helper accumulates drained events into an untyped Array; the timeout test compared that DTO directly to typed raw.drain_events Array[Dictionary]. The independent raw event values must first be accumulated into the same result-container representation, as already done in the normal matrix.

Root authorized this bounded test-oracle correction after attempt2 exit. Added explicit untyped expected_events array and append_array(raw.drain_events()), preserving strict type/order/value equality; no production code change and no allowlist/skip adjustment. Attempt3 is a distinct K6 execution with fresh code/fixture/engine/cache SHA.
