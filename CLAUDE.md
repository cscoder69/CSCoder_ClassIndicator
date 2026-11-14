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
  Shapes: round (circle mask), rounded square, square (`SHAPES`; masks made by `tools/make_shapes.lua`).
  The border is a RING (shape texture cut by the `*_hole` mask with CLAMPTOWHITE) or 4 edges for square, so opacity never shows it through the icon. No mask support -> `UI-Classes-Circles`. Text on its own child frame above.
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

## User notes (2026-11-14, after the first test)
- Done: rounded square shape, separate "Show a border" switch, ring border (opacity was a mess
  because the border was a full shape behind the icon), text on its own layer.
- Open: the class name didn't show in the first screenshot (Plater, test mode) - check again.
- Open: "o fundo ta preto" (black background) - not clear yet which background; ask for a print.

## PvP extras (2026-11-14, user: "taca-le o pau"; backup before: git tag `backup-before-pvp-extras`
## and `../Backups/ClassIndicator_<ts>`)
- `healerMark` (on): green outlined cross at the icon's top-right for classes that CAN heal
  (`HEALER_CLASSES`: Priest, Druid, Paladin, Shaman, Monk, Evoker). No spec info needed.
- `targetBigger` (on) + `targetScale` 1.3: your target's icon is bigger (PLAYER_TARGET_CHANGED).
- `bigClasses` (class -> true) + `bigScale` 1.3: a row of 9 class icons in the options to pick
  the classes you fear most. Multipliers stack (big class + target).
- Text: `textFormat` full | short (`SHORT_NAMES`: WAR, HUN, MAG...), `textOutline` none/outline/
  thick, `textShadow`.
- Window is now 1060x720 with 3 columns: Display + Icon | Class name | Border + PvP. The preview
  has 5 plates: the 3rd is "the target", the 5th a Priest (healer cross).
- Suggested and not done yet: spec icon (from BG info), distance limit, profiles, minimap button,
  translations, setup guide, preview class choice.
- Target highlight = pulsing GLOW of the icon shape (`media/glow_*.tga`, 1.6x the icon, ADD blend); the user rejected the ">> <<" arrows (they ran over the name). Healer cross has a 2 px outline (`healerOutline`).
- Click to target: REMOVED. WoW Forever forbids targeting for addons ("only for the Blizzard UI" popup on TargetUnit) and the secure button never targeted (left clicks didn't even reach it). The way to click the icon is the nameplate addon's own click area: Plater > Advanced > Click Space height (enemy and friendly), "always show" to see it. Preview background is dark teal (user's "fundo preto").

## Clickable icon + profiles (2026-11-14)
- `clickable` (on): `ClickArea` enlarges the GAME's nameplate click box (C_NamePlate.Set*Size,
  enemy; friendly too when `friends`/test mode) to cover the icon. Whoever else sets the size
  (game, Plater) is hooked (hooksecurefunc at file load, before Plater caches it) and becomes the
  base; ours only adds on top. Out of combat only (pending -> PLAYER_REGEN_ENABLED). The target's
  bigger size isn't counted. NOT tested in game yet; prints once if the game refuses.
- Profiles (SETTINGS_VERSION 2): `CSCoderClassIndicatorDB = { version, profiles, chars }`, v1 flat
  save -> "Default". `Profiles.Use/CopyFrom/Delete/Names/Current`. Bar at the bottom of the window:
  Profile (this character) | New profile (StaticPopup with edit box) | Copy from | Delete (confirm).
  Dropdowns accept { get, set } and option functions; `holder.openUp` opens lists upwards.
- Audit for r/wowaddons (Ketho's extension rules): globals = DB, 2 slash vars, shared
  CSCoderOptionsParent, config frame; no deprecated API (old ColorPickerFrame fallback removed).
