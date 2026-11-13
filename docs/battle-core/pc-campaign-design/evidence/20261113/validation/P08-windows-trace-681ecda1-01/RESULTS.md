# Windows TRACE release candidate — 681ecda1

The P08 release build and one packaged Windows headless startup passed for commit 681ecda17567979edfe693a7c9230ed6786f8c4f. The original checkout was clean before and after. The isolated build copied and pinned all tracked bytes and reused 2,338 validated P08 cache inputs, the two relay texture pins, the Godot 4.7.2 release template, and the pinned production O07 DLL.

| Candidate file | Bytes | SHA-256 |
| --- | ---: | --- |
| SpaceBattleOfThreeKingdoms.exe | 497298152 | 57a664fc5a82801e14d3492f95b981b642fe868af4232c145b4ba3ee2eaddf09 |
| o07_win32.dll | 108032 | a9e45eed91cbe8721469359160bbcb3716675a575537acf716a2da782a75b6e8 |

- The x64 release EXE embeds 1,732 PCK v4 entries, including the compiled First Operation host and TRACE scripts and their remaps. TRACE tests are excluded. The committed verifier passed the embedded checkpoint and replay fingerprints. The preset was restored byte-for-byte. Export logs have the same ignored nested-project warning as P08.
- An offline byte comparison with the prior P08 PCK found two added TRACE entries, zero removed entries, and ten shared entries with changed payloads. These were the compiled host, seven generated scene payloads, and two generated cache records. The corresponding tracked scene sources match the parent commit. The generated payload differences are recorded in PACK-DELTA.json. Their exact cause was outside this smoke.
- One owned job ran the exact release EXE with the packaged DLL, a fresh redirected profile, no input, and --headless --verbose --resolution 1600x900 --fixed-fps 60 --quit-after 120 --log-file <isolated log> -- --first-operation-trace. All nine checks passed. EntryBoot and NewEntry loaded, exit was 0, active descendants were 0, logs had zero diagnostics, and the redirected profile contained zero files. Original and copied package SHA-256 values matched before and after the smoke.
- This covers candidate packaging and startup with the TRACE flag. Actual TRACE JSONL creation remains to be exercised by public sortie or resume. The build runner's first banner displays the parent commit by inheritance. PRELAUNCH.json, TRACKED-SOURCE.json, and RESULT.json record the actual 681ecda1 build provenance.

Build evidence is in PRELAUNCH.json, TRACKED-SOURCE.json, RESULT.json, PACK-DELTA.json, and candidate/_build. Smoke evidence is in smoke/PRELAUNCH.json, smoke/RESULT.json, and smoke/engine.log.