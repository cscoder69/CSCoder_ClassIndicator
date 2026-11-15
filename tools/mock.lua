-- Runs the addon on a tiny mocked WoW API and clicks through the options window.
-- luajit tools/mock.lua <addon dir>
local dir = arg[1] or "."
local errors = 0
local function try(what, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then errors = errors + 1; print("ERROR", what, err) end
	return ok
end

-- Catch-all widget: unknown methods do nothing; Create*/Get* of objects return new widgets.
local Widget = {}
local NUMBERS = { GetStringHeight = 12, GetEffectiveScale = 0.64, GetFrameLevel = 1, GetStringWidth = 50, GetValue = 0, GetWidth = 100, GetHeight = 20, GetAlpha = 1 }
local function NewWidget(kind)
	local w = { _kind = kind, _scripts = {}, _shown = true, _points = 0 }
	return setmetatable(w, Widget)
end
Widget.__index = function(self, key)
	if NUMBERS[key] then return function() return NUMBERS[key] end end
	if key == "SetScript" then return function(s, name, fn) s._scripts[name] = fn end end
	if key == "HookScript" then return function(s, name, fn) local old = s._scripts[name]; s._scripts[name] = function(...) if old then old(...) end fn(...) end end end
	if key == "GetScript" then return function(s, name) return s._scripts[name] end end
	if key == "Show" then return function(s) s._shown = true; if s._scripts.OnShow then s._scripts.OnShow(s) end end end
	if key == "Hide" then return function(s) s._shown = false; if s._scripts.OnHide then s._scripts.OnHide(s) end end end
	if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
	if key == "IsShown" or key == "IsVisible" then return function(s) return s._shown end end
	if key == "SetPoint" then return function(s) s._points = s._points + 1 end end
	if key == "ClearAllPoints" then return function(s) s._points = 0 end end
	if key == "SetChecked" then return function(s, v) s._checked = v end end
	if key == "GetChecked" then return function(s) return s._checked end end
	if key == "SetText" then return function(s, v) s._text = v end end
	if key == "GetText" then return function(s) return s._text or "" end end
	if key == "GetFrameStrata" then return function() return "MEDIUM" end end
	if key == "GetRect" then return function() return 100, 100, 120, 12 end end
	if key == "IsForbidden" then return function() return false end end
	if key == "GetName" then return function(s) return s._name end end
	if key == "SetValue" then return function(s, v) s._value = v; if s._scripts.OnValueChanged then s._scripts.OnValueChanged(s, v) end end end
	if key == "GetColorRGB" then return function() return 0.2, 0.4, 0.6 end end
	if type(key) == "string" and (key:find("^Create") or key:find("^Get")) then
		return function() return NewWidget(key) end
	end
	if type(key) == "string" and key:find("^[A-Z]") then return function() end end
	return nil
end

local env = setmetatable({}, { __index = _G })
local nilGlobals = {}
setmetatable(env, { __index = function(_, k)
	local v = _G[k]
	if v == nil then nilGlobals[k] = true end
	return v
end })
env._G = env
env.CreateFrame = function(kind, name, parent, template) local w = NewWidget(kind); w._name = name; w._template = template; if name then env[name] = w end return w end
env.UIParent = NewWidget("Frame")
env.GameTooltip = NewWidget("GameTooltip")
env.ColorPickerFrame = NewWidget("ColorPickerFrame")
env.ColorPickerFrame.SetupColorPickerAndShow = function(self, info) self._info = info end
env.UISpecialFrames = {}
env.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
env.SlashCmdList = {}
env.C_Timer = { After = function(_, fn) fn() end }
env.C_AddOns = { GetAddOnMetadata = function() return "0.0.0-mock" end } -- like a release (no dev test mode)
env.Settings = {
	RegisterCanvasLayoutCategory = function() return {} end, RegisterAddOnCategory = function() end,
	RegisterCanvasLayoutSubcategory = function() return {} end,
}
env.HideUIPanel = function() end
env.GetPhysicalScreenSize = function() return 2560, 1440 end
env.StaticPopupDialogs = {}
env.StaticPopup_Show = function(name, a, b, data) env._popup = { name = name, data = data } end
env.OKAY, env.CANCEL, env.YES, env.NO = "OK", "Cancel", "Yes", "No"
env.UnitName = function() return "Tester" end
env.GetRealmName = function() return "Realm" end
local inCombat = false
env.InCombatLockdown = function() return inCombat end
env.issecretvalue = function() return false end
env.print = function(...) print("  [chat]", ...) end

-- Units: nameplate1 enemy mage, nameplate2 friendly hunter, nameplate3 NPC.
local units = {
	nameplate1 = { player = true, enemy = true, name = "Mage", class = "MAGE" },
	nameplate2 = { player = true, enemy = false, name = "Hunter", class = "HUNTER" },
	nameplate3 = { player = false, enemy = true, name = "Warrior", class = "WARRIOR" },
}
local plates = {}
for unit in pairs(units) do
	local p = NewWidget("NamePlate")
	p.namePlateUnitToken = unit
	p.unitFrame = NewWidget("Frame")
	p.unitFrame.healthBar = NewWidget("StatusBar")
	plates[unit] = p
end
env.C_NamePlate = {
	GetNamePlateForUnit = function(unit) return plates[unit] end,
	GetNamePlates = function() local t = {} for _, p in pairs(plates) do t[#t + 1] = p end return t end,
	GetNamePlateEnemySize = function() return 110, 45 end,
	GetNamePlateFriendlySize = function() return 110, 45 end,
	SetNamePlateEnemySize = function(w, h) env._enemySize = { w, h } end,
	SetNamePlateFriendlySize = function(w, h) env._friendlySize = { w, h } end,
}
env.hooksecurefunc = function(t, name, fn)
	local old = t[name]
	t[name] = function(...) local r = { old(...) } fn(...) return unpack(r) end
end
env.UnitIsPlayer = function(u) return units[u] and units[u].player or false end
env.UnitIsUnit = function(a, b) return a == b end
env.UnitCanAttack = function(_, u) return units[u] and units[u].enemy or false end
env.UnitIsEnemy = env.UnitCanAttack
env.UnitClass = function(u) local d = units[u]; if d then return d.name, d.class end end

env.Minimap = NewWidget("Minimap")
env.GetCursorPosition = function() return 0, 0 end
local shared = assert(loadfile(dir .. "/CSCoderMinimap.lua")); setfenv(shared, env); try("shared minimap", shared)
local chunk = assert(loadfile(dir .. "/CSCoder_ClassIndicator.lua"))
setfenv(chunk, env)
try("load", chunk, "CSCoder_ClassIndicator")
local events
-- The events frame is the last CreateFrame with an OnEvent script: find it through ADDON_LOADED.
for k, v in pairs(env) do end
local function FindEvents()
	-- the addon keeps its frame local; capture via CreateFrame wrapper below instead
end

-- Re-run with a CreateFrame wrapper that remembers frames with OnEvent.
local frames = {}
local create = env.CreateFrame
env.CreateFrame = function(...) local w = create(...); frames[#frames + 1] = w; return w end
env.CSCoderClassIndicatorDB = nil
chunk = assert(loadfile(dir .. "/CSCoder_ClassIndicator.lua"))
setfenv(chunk, env)
try("load", chunk, "CSCoder_ClassIndicator")
for _, f in ipairs(frames) do if f._scripts.OnEvent then events = f end end
local function Fire(event, ...) try(event, events._scripts.OnEvent, events, event, ...) end

Fire("ADDON_LOADED", "CSCoder_ClassIndicator")
Fire("PLAYER_ENTERING_WORLD")
for unit in pairs(units) do Fire("NAME_PLATE_UNIT_ADDED", unit) end
local function Shown(unit) local f = plates[unit].cciIndicator; return f ~= nil and f._shown end
print("enemy player gets the icon", Shown("nameplate1"))
print("friendly player: none by default", not Shown("nameplate2"))
print("NPC: none", not Shown("nameplate3"))
print("text is the class name", plates.nameplate1.cciIndicator and plates.nameplate1.cciIndicator.text._text)

-- db = the active profile (looked up on every access: profiles can switch).
local function Active() local r = env.CSCoderClassIndicatorDB; return r.profiles[r.chars["Tester - Realm"]] end
local db = setmetatable({}, { __index = function(_, k) return Active()[k] end, __newindex = function(_, k, v) Active()[k] = v end })
db.friends = true
Fire("PLAYER_ENTERING_WORLD")
print("friends on -> friendly player gets it", Shown("nameplate2"))

try("slash test on", env.SlashCmdList.CSCODERCLASSINDICATOR, "test")
print("test mode -> NPC gets a sample", Shown("nameplate3"))
try("slash test off", env.SlashCmdList.CSCODERCLASSINDICATOR, "test")
print("test off -> NPC hidden", not Shown("nameplate3"))

-- Options window: open, then click / change every control found.
try("open options", env.SlashCmdList.CSCODERCLASSINDICATOR, "")
local clicked, slid = 0, 0
for _, f in ipairs(frames) do
	if f._scripts.OnClick and f._kind ~= "NamePlate" then
		if try("click", f._scripts.OnClick, f) then clicked = clicked + 1 end
		-- a drop-down opened its list: click every row too
		for _, g in ipairs(frames) do
			if g._scripts.OnClick and g ~= f and g._listRowTried == nil and g._kind == "Button" and g._shown then end
		end
	end
	if f._kind == "Slider" and f._scripts.OnValueChanged then
		try("slide", f._scripts.OnValueChanged, f, 5); slid = slid + 1
		if f._scripts.OnMouseWheel then try("wheel", f._scripts.OnMouseWheel, f, 1) end
	end
	if f._kind == "EditBox" and f._scripts.OnEnterPressed then
		f._text = "3"; try("type", f._scripts.OnEnterPressed, f)
	end
end
-- Colour picker callbacks.
local info = env.ColorPickerFrame._info
if info then try("color apply", info.swatchFunc); try("color cancel", info.cancelFunc) end
-- Every shape / mode combination draws.
for _, shape in ipairs({ "round", "rounded", "square", "hex", "diamond", "shield" }) do
	for _, border in ipairs({ "class", "enemy", "custom", "off" }) do
		for _, pos in ipairs({ "below", "above", "left", "right" }) do
			for _, anchor in ipairs({ "top", "bottom", "left", "right" }) do
				db.shape, db.textPos, db.anchor = shape, pos, anchor
				db.textBg = ({ "none", "plate", "ribbon", "badge" })[(#pos + #anchor) % 4 + 1]
				db.borderStyle, db.iconShadow = ({ "soft", "flat", "metal" })[#shape % 3 + 1], #pos % 2 == 0
				db.border = border ~= "off"; if db.border then db.borderMode = border end
				Fire("PLAYER_ENTERING_WORLD")
			end
		end
	end
end
-- PvP extras (the click loop above turned test mode on: turn it off).
try("slash test off", env.SlashCmdList.CSCODERCLASSINDICATOR, "test")
db.enabled = true
local ind = plates.nameplate1.cciIndicator
db.size, db.bigScale, db.targetScale, db.targetBigger, db.bigClasses = 20, 1.5, 2, true, {}
db.textFormat, db.textOutline, db.textShadow, db.showText, db.healerMark = "short", "", false, true, true
Fire("PLAYER_ENTERING_WORLD")
print("short text -> MAG", ind.text._text == "MAG")
print("mage: no healer cross", not ind.healer._shown)
units.nameplate1.class, units.nameplate1.name = "PRIEST", "Priest"
Fire("PLAYER_ENTERING_WORLD")
print("priest: healer cross", ind.healer._shown)
for _, p in ipairs({ "topright", "topleft", "bottomright", "bottomleft", "center" }) do db.healerPos = p; Fire("PLAYER_ENTERING_WORLD") end
print("healer positions drawn", ind.healer._shown)
local sizes = {}
local setSize = ind.SetSize
ind.SetSize = function(self, w) sizes[#sizes + 1] = w end
db.bigClasses.PRIEST = true
Fire("PLAYER_ENTERING_WORLD")
env.UnitIsUnit = function(a, b) return a == b or (a == "nameplate1" and b == "target") end
Fire("PLAYER_TARGET_CHANGED")
print("sizes: big class 30, big + target 60", sizes[1], sizes[#sizes])
print("target glow shown", ind.glow._shown)
print("glow animation made", ind.glowAnim ~= nil)
ind.SetSize = setSize
Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
print("removed -> hidden", not Shown("nameplate1"))
print("controls clicked", clicked, "sliders", slid)
local names = {}
for k in pairs(nilGlobals) do names[#names + 1] = k end
table.sort(names)
print("unexpected nil globals:", #names == 0 and "none" or table.concat(names, ", "))
print("errors:", errors)

-- Profiles.
local root = env.CSCoderClassIndicatorDB
print("profiles layout", type(root.profiles) == "table" and root.chars["Tester - Realm"] ~= nil)
local input
for _, f in ipairs(frames) do if f._template == "InputBoxTemplate" then input = f end end
input._text = "  BG  "
try("new profile", input._scripts.OnEnterPressed, input)
print("new profile 'BG' in use", root.chars["Tester - Realm"] == "BG" and type(root.profiles.BG) == "table")
-- Export, change, import back.
db.size = 37
local share
for _, f in ipairs(frames) do if f._name == "CSCoder_ClassIndicatorShare" then share = f end end
local exportButton, importButton
for _, f in ipairs(frames) do
	if f.label and f.label._text == "Export profile" then exportButton = f end
	if f.label and f.label._text == "Import profile" then importButton = f end
end
try("export", exportButton._scripts.OnClick, exportButton)
for _, f in ipairs(frames) do if f._name == "CSCoder_ClassIndicatorShare" then share = f end end
local text = share.box._text
print("export text", type(text) == "string" and text:sub(1, 5) == "CCI1:", text and #text)
db.size = 20
try("import open", importButton._scripts.OnClick, importButton)
share.box._text = text
try("import", share.import._scripts.OnClick, share.import)
print("import restores size 37", db.size == 37)
share.box._text = "garbage"
try("import garbage", share.import._scripts.OnClick, share.import)
print("garbage refused, size kept", db.size == 37)
-- Old flat save migrates into Default.
env.CSCoderClassIndicatorDB = { enabled = true, size = 40, shape = "square", version = 1 }
frames = {}
chunk = assert(loadfile(dir .. "/CSCoder_ClassIndicator.lua")); setfenv(chunk, env); try("reload", chunk, "CSCoder_ClassIndicator")
for _, f in ipairs(frames) do if f._scripts.OnEvent then events = f end end
Fire("ADDON_LOADED", "CSCoder_ClassIndicator")
local r2 = env.CSCoderClassIndicatorDB
print("old save -> Default keeps size 40 / square", r2.profiles and r2.profiles.Default.size == 40 and r2.profiles.Default.shape == "square")
print("errors after profiles:", errors)

-- Shared minimap button.
local lib = env.CSCoderMinimap
print("minimap: one button, one addon", lib and lib.button ~= nil and #lib.addons == 1)
local opened = 0
lib.Register({ name = "Another addon", open = function() opened = opened + 1 end, active = function() return true end })
try("minimap click (2 addons)", lib.button._scripts.OnClick, lib.button, "LeftButton")
print("minimap: 2 addons -> menu", lib.menu ~= nil and lib.menu._shown)
try("menu row", lib.menu.rows[1]._scripts.OnClick, lib.menu.rows[1], "LeftButton")
print("minimap: menu row opens that addon", opened == 1)
try("minimap tooltip", lib.button._scripts.OnEnter, lib.button)
print("errors after minimap:", errors)

-- Visual pickers: every "Pick..." button opens the picker; clicking a tile applies it.
try("open options again", env.SlashCmdList.CSCODERCLASSINDICATOR, "")
local picks = 0
for _, f in ipairs(frames) do
	if f.label and f.label._text == "Pick..." and f._scripts.OnClick then
		try("pick open", f._scripts.OnClick, f); picks = picks + 1
		local p = env.CSCoder_ClassIndicatorPicker
		if p and p.tiles and p.tiles[2] then try("pick tile", p.tiles[2]._scripts.OnClick, p.tiles[2]) end
	end
end
print("pick buttons", picks, "errors after pickers:", errors)

-- Pixel lock driver (every frame's OnUpdate runs once).
local updates = 0
for _, f in ipairs(frames) do
	if f._scripts.OnUpdate then try("OnUpdate", f._scripts.OnUpdate, f, 0.016); updates = updates + 1 end
end
print("OnUpdate scripts run", updates, "errors after lock:", errors)
