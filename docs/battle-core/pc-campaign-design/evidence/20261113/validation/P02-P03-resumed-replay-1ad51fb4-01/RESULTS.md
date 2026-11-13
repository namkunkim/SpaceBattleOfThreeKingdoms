# P02/P03 public resumed replay continuity

- Exact parent `1ad51fb456cd1bc3bebb2bdc573aa9ba275c4521`; test-only candidate `02ffda964c35ebc3404ad4d3880425741da0829a`.
- Three distinct, isolated Windows Godot headless processes passed 47/47 (checkpoint 19/19 (PID 25180), resume 14/14 (PID 28152), replay 14/14 (PID 16744)), exit 0 with no diagnostic lines.
- Product EntryBoot selected the approved Red Cliffs operation. At tick 1, the actual public Save button captured applied Withdraw (tick 0) and pending Finalize withdrawal (tick 1). The uninterrupted host exported its tick-2 result through the public picker.
- A fresh process opened the public Atlas Resume action with the exact saved packet, advanced its pending command once, and exported a byte-identical replay. Live terminal events and full projections matched; both replay exports and the save slot remained unchanged through a third process.
- The third process loaded the resumed export through public Atlas Watch Replay, verified it asynchronously, and stepped from zero through the same tick-2 terminal settlement, events and projection. Closing restored the Atlas and focus.
- The first attempt is preserved. Its harness compared a six-field recording settlement to the live 13-field settlement. The fix checks exactly the declared recording fields while preserving the full live and replay comparisons.
- Generated import metadata was copied and SHA-bound from the earlier reviewed F evidence; the source checkout's ignored runtime cache was copied by value and hash-listed without reimport. The new checkout was restored clean after archiving its status. It retains only ignored runtime cache files.
- Scope: headless UI signals in 1600x900 configuration, one supported two-tick operation and one restore boundary. No physical Windows input, cross-operation cursor, release or formal K6 credit.
