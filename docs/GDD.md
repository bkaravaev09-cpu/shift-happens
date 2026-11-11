# Shift Happens — GDD (1 page)

**Pitch.** Cozy voxel puzzle-platformer through *Alice's Adventures in Wonderland*
(Lewis Carroll, 1865 — public domain). You are a letter living inside the book. Levels are
built from real lines of the text. Alice keeps changing size — so do you (Shift).

**Story arc (one chapter per level, one story line restored per level):**
1. Down the Rabbit-Hole — follow the White Rabbit, fall down the hole (movement).
2. EAT ME — eat the cake, grow BIG, break through (Shift → UPPERCASE).
3. Advice from a Caterpillar — "Who are YOU?", shrink through smoke rings (Shift back).
4. The Queen's Croquet-Ground — the Queen SHOUTS, world turns UPPERCASE (Caps Lock).
5+. Ideas: Pool of Tears (rising water of letters), Cheshire Cat (text fades, only grin
   left), Mad Tea-Party ("Move down!" — shift seats), Trial ("a pack of cards!"), wake up.
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
