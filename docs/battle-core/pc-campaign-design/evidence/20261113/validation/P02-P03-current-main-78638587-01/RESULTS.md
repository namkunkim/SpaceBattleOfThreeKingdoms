# P02·P03 current-main resume and public replay

The two missing phases ran against the exact GitHub main `78638587803c5ec096be5200dcf1a7e72389f516` in a new detached F worktree. The remote SHA was checked before staging, before the two phases and afterward.

| Phase | Source | Checks | PID | Exit |
| --- | --- | ---: | ---: | ---: |
| Checkpoint and uninterrupted oracle | Preserved, independently reviewed `e7c5fde6` evidence | 19/19 | 30796 | 0 |
| Public Atlas resume | New run on `78638587` | 14/14 | 1000 | 0 |
| Public Atlas replay | New run on `78638587` | 14/14 | 3360 | 0 |

The checkpoint and runner source blobs match the reviewed checkpoint build. The nine intervening paths are Atlas artwork and legacy P09 fire audio plus tests. The copied save, oracle and uninterrupted export matched the earlier receipt and remained byte-identical. Resume exported the same two-tick replay, SHA-256 `a11a94d89d8861b9b6f31a287e9249cbe09ac5241ee56715e21f7288fd710e4d`. The replay reached the matching terminal frame, ordered events and settlement without modifying the four artifacts. The two new processes returned exit 0 with no errors or warnings.

Staging bound 792 copied generated metadata entries and 1,549 cache files; preexisting satellite cache entries were skipped. Editor import rebuilt both satellite textures, observed all eight prologue textures and returned exit 0 with the known nested-project warning. The runtime runner was the committed two-phase logic with only the phase list and isolated seed-copy call changed in the evidence copy.

The new worktree retains only generated import and UID metadata and the pinned O07 DLL. No tracked product or test source changed, no physical input was used, and K6 formal, release and cross-operation acceptance are outside this evidence.

