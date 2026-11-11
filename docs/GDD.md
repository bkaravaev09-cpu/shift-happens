# Shift Happens — GDD (1 page)

**Pitch.** Cozy voxel puzzle-platformer through *Alice's Adventures in Wonderland*
(Lewis Carroll, 1865 — public domain). You are a letter living inside the book. Levels are
built from real lines of the text. Alice keeps changing size — so do you (Shift).

**Story arc (10 levels, one chapter each, one story line restored per level):**
1. Down the Rabbit-Hole — movement, pits, fall down the hole.
2. EAT ME — Shift → UPPERCASE, heavy letters break `=` planks.
3. Advice from a Caterpillar — Shift back, slip through smoke rings (tunnel).
4. The Queen's Croquet-Ground — Caps Lock raises the world to reach a ledge.
5. The Pool of Tears — water `~`: lowercase floats/swims.
6. I Wish I Hadn't Cried So Much — UPPERCASE sinks: dive under a wall, shrink to float up.
7. The Cheshire Cat — grins `%` `$` fade in turns: rhythm jumps.
8. A Mad Tea-Party — tea trays `>` ride along `:` tracks.
9. Who Stole the Tarts? — cards `+` fall after you step on them.
10. Alice's Evidence — finale: Caps up, card run, Caps down, grow to break through.
Final screen: all restored lines + "...and then Alice woke up."

**Text rules:** quote only the original 1865 book text (public domain). No art, names or
designs from film/game adaptations (Disney etc.).

**Theme SHIFT, two keys:**
- **Shift** — toggle the hero's case.
  - lowercase: 5 tall, light, jump 11, fits 5-voxel tunnels.
  - UPPERCASE: 7 tall, heavy, jump 6.5, breaks `=` planks when standing on them.
- **Caps Lock / Tab** — toggle the WORLD's case. All text letters become uppercase:
  lowercase tops rise by 2 voxels, descenders (g p q y j) disappear, shapes change.
  Fixed things (`#` blocks, existing capitals) don't change.

**Key geometry (cell = 6x10 voxels, measured from the cell top, y down):**
- x-height lowercase top = 2, capitals/ascenders/`#` top = 0, baseline bottom = 7.
- Floor of lowercase under a `#`/text ceiling one row above → gap 5 (lowercase hero fits;
  with Caps on gap 3 → blocked).
- From lowercase floor to a capital ledge one row up = 12 (too high); with Caps on = 10 (ok).
- Single space between letters = `_` bridge (walkable). Two+ spaces = pit (death → respawn).

**Controls:** A/D or arrows, Space/W jump, Shift, Caps Lock or Tab, R restart.

**Look:** 3D voxels rendered at 480x270 and upscaled with nearest filter (pixel look),
orthographic camera tilted slightly, ink-blue letters on paper, warm red hero, gold goal.

**Audio (to do):** typewriter clicks for steps/shift, "clack" for Caps, soft piano loop.

**Scope for the jam:** 8–10 levels, title screen, final letter screen, sound, web build.
