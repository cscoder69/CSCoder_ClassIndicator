# CS.Coder - Class Indicator — notes for Claude (and any dev)

Fourth CS.Coder addon (started 2026-11-14). Same user and rules as
`../CSCoder_QuestIndicator/CLAUDE.md` (pt-BR chat, English code and in-game text, publish only
when the user says so, Reddit audit rules: no deprecated API, few globals, AI disclaimer).

## Why (user's pain)
In PvP the user can't tell enemy classes apart by colour: they want the game's OFFICIAL class
icon (image, plus the class name as text) above every enemy player's nameplate, working with the
default UI and the popular nameplate addons (Plater first).

## What it does
- `Indicator.New/Style/Place`: one frame type for real plates and the preview. Icon =
  `UI-CHARACTERCREATE-CLASSES` + `CLASS_ICON_TCOORDS` (own copy as fallback), 7% cut off the edges.
  Round = circle mask (`media/circle.tga`, copied from Quest Indicator); without mask support it
  falls back to `UI-Classes-Circles`. Border = circle/white square behind the icon.
- Parented to the game's nameplate frame, anchored to the visible health bar
  (`plate.unitFrame.healthBar` = Plater, `plate.UnitFrame.healthBar` = default UI) or the plate.
  Forbidden plates and secret values are skipped (instances on WoW Forever: BG/arena untested).
- Settings (flat, `CSCoderClassIndicatorDB`): enabled, friends, shape, size, alpha, anchor
  (top/bottom/left/right of the bar), offsetX/Y, borderMode (class/enemy/custom/none) + colour +
  thickness, showText, textPos (below/above/left/right of the icon), textX/Y, textSize, textMode
  (class/white/enemy/custom) + colour, textUpper.
- Options: own window (`CSCoder_ClassIndicatorConfig`, 760x690, dark/gold), live preview of 4
  fake enemy plates at the top, two columns (Display + Icon | Border + Class name), gates.
  Landing page under the shared "CS.Coder" settings parent (`CSCoderOptionsParent`).
- **Test mode** (`/ci test` or the button, session only): every nameplate (mobs, NPCs, allies)
  gets a sample class, so the user can tune it on real plates (real enemy players are hard to find).
- `/ci` options, `/ci test`, `/ci toggle`. Globals: `CSCoderClassIndicatorDB`,
  `SLASH_CSCODERCLASSINDICATOR1/2`, `CSCoderOptionsParent` (shared), the config frame.

## Checks
`luajit tools/mock.lua .` -> expect `errors: 0`. The "nil globals" listed are game tables the
mock doesn't have (CLASS_ICON_TCOORDS, RAID_CLASS_COLORS...).

## State
v0 written 2026-11-14, waiting for the user's first in-game test. English only (translate after
the layout is approved). Junction already in AddOns. Local git only (ask before GitHub/CurseForge).
