# H1 parameterized boundary implementation contract

Approved sources: H1-EVENT-DECISION.md H1-E01/E02 and H1-POLICY-DECISION.md H1-P02. Current user work authorization allows implementing these already chosen semantics in isolated development. No prior document's example quantities are promoted to product policy.

Implement a pure GDScript module with no active product callers, persistence, global state, resource writes, RNG, or new defaults. `propose_authorized_delay` handles one externally authorized delay: activation completion <= original departure allows it (same exact timestamp included); completion after departure contributes zero. Add the same effective duration to departure and public deadline. Reject invalid integer domains and arithmetic overflow. The caller owns authorization, complete simultaneous event aggregation, exactly-once commit and any repeated-delay policy; this helper must not decide those.

`assess_achievement_boundary` reports inclusive deadline eligibility and only the approved constraints: objective+command loss at the identical logical timestamp has failure priority; explicit withdrawal disallows objective success. Escape timing at the deadline is inclusive. Loss at another time, and command loss in an escape case, are explicitly flagged for a separate policy. No full settlement award or global event ordering is inferred.

All timestamp/duration inputs are integer logical milliseconds, with signed 64-bit representability as a technical domain limit. Synthetic test quantities (e.g. departure 7300ms, delay 401ms, deadline 12000ms) are arithmetic fixtures, not Cross Counter/product settings. The oracle is frozen in tests/h1_boundary_oracle.gd before the implementation. Boundary tests include same outer tick but different milliseconds, overflow, zero, bad types, extra/missing inputs, and detached result mutation.

Q67: no combat, AI, movement, rule constants, RNG stream, or active product call site changes. This pure inactive event-time helper is not a balance change and no 1000-seed balance claim is made. Future activation must re-assess Q67 and supply its manifest.

Remaining product inputs: original departure logical time, completed activation logical time (produced by authoritative capture/activation policy), authorized single delay duration, base public deadline, valid goal/escape timestamp, commander-loss timestamp if present. Eligibility, repeat-delay authorization, ownership/event precedence outside H1, scenario quantities, exact-once commit, persistence and UI integration stay outside this isolated module.
