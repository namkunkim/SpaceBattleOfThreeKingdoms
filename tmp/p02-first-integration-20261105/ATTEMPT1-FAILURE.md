# P02 attempt1 failure — spec return required

Actual exit1. New stage1/6 only; prior P2c/active attempts unchanged. No CLI subprocess or regressions yet. Canonical resource guard empty and class-cache SHA unchanged. Full code snapshot/input SHA/logs/observations preserved.

1. Services public projection carries redacted contact rows with `contact`, `id`, `side`, `pos` but no `dead`. Reusing existing `policy_commands` directly throws SCRIPT ERROR on s.dead. BattleProjection.contact and Detection targetability must inform a dedicated opt-in policy boundary; changing legacy policy body or disabling Detection is not allowed. This requires specification supplement and independent acceptance before new production edits.
2. Short max_ticks=1 is not an unconditional timeout oracle: explicit POC seed7/attack5 actually terminates at tick1. The short-run test must use an explicitly authored distant fleet fixture for guaranteed timeout or check actual end independently. Do not change max tick/end_ms to fake timeout.

Raw state/event comparison and32 named API refusals reached, but overall FAIL and script errors invalidate success acceptance. Cases/check counts are observations only.
