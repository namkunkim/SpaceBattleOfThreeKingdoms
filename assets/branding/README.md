# Game icon

Created on 2026-10-24 with the built-in ImageGen tool.

- `game-icon-source.png`: original generated artwork.
- `game-icon.png`: 1024 × 1024 project/window icon.
- `game-icon-192.png`: 192 × 192 Android launcher icon.
- `game-icon.ico`: Windows native icon with 16, 24, 32, 48, 64, 128, and 256 px entries.

Regenerate the packaged sizes with `powershell -File tools/build-game-icon.ps1` from the project root. This only resizes and packages the original artwork.

## Generation prompt

Use case: logo-brand. Asset type: finished square game application icon for SpaceBattleOfThreeKingdoms, a space fleet strategy game inspired by the Three Kingdoms. Create a polished, striking icon: one bold sculpted gold heraldic crest with three upward spear-like points, the center point subtly forming the prow of a powerful futuristic battleship, two sweeping wing-like armored sides enclosing a small brilliant cyan star/reactor. Dark midnight navy space background, very subtle nebula, restrained cyan glow and warm gold metal. Symmetric centered composition, large simple readable silhouette at 32px, richly finished but uncluttered, serious premium PC strategy aesthetic. Emblem entirely inside central 64% of square with generous dark margins so Android circular masks keep it intact. Square full bleed opaque background, no rounded square border, no text, no letters, no numbers, no watermarks. One single icon, no mockup, no multiple tiles.
