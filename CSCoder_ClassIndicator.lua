-- CS.Coder - Class Indicator
-- The game's official class icon (and the class name) above enemy players' nameplates, so the
-- class reads at a glance without relying on colour. Anchored to the game's own nameplate frame,
-- so it works with the default UI and with nameplate addons (Plater, Kui, ThreatPlates, ElvUI...).

local ADDON, ns = ...
local TITLE = "CS.Coder - Class Indicator"
local SUBTITLE = "Class Indicator"
local PARENT_NAME = "CS.Coder"
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\media\\"
local CIRCLE = MEDIA .. "circle"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CLASS_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local CLASS_CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"
local ENEMY_RED = { 0.9, 0.1, 0.1, 1 }

---------------------------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------------------------

local DEFAULTS = {
	enabled = true,
	friends = false,       -- also on friendly players
	minimap = true,        -- the shared CS.Coder minimap button
	shape = "round",       -- round | rounded (rounded square) | square | hex | diamond | shield
	size = 28,
	alpha = 1,
	anchor = "top",        -- side of the nameplate: top | bottom | left | right
	offsetX = 0,
	offsetY = 14,
	border = true,         -- draw a border
	borderMode = "class",  -- class | enemy | custom
	borderColor = { 1, 0.82, 0, 1 },
	borderSize = 2,
	borderStyle = "frame", -- frame (thin rim + soft dark outline) | soft (ring + soft glow) | flat | metal
	innerShade = true,     -- soft dark edge inside the icon (depth)
	iconSheen = true,      -- soft glass reflection on the top half of the icon
	iconShadow = false,    -- soft dark shadow under the icon
	spellIcons = false,    -- the spellbook class icons (richer art) instead of the character-creation ones
	textBg = "none",       -- name background: none | badge (pointed, coloured edge) | plate | ribbon
	textBgMode = "gold",   -- badge/plate edge, ribbon colour: gold | class | enemy | dark | custom
	textFont = "default",  -- key in FONTS
	textBgColor = { 0.6, 0.1, 0.1, 1 },
	showText = true,
	textPos = "below",     -- side of the icon: below | above | left | right
	textX = 0,
	textY = 0,
	textSize = 11,
	textMode = "class",    -- class | white | enemy | custom
	textColor = { 1, 1, 1, 1 },
	textUpper = false,
	textFormat = "full",   -- full (class name) | short (HUN, MAG...)
	textOutline = "OUTLINE", -- "" | OUTLINE | THICKOUTLINE
	textShadow = true,
	healerMark = true,     -- green cross on classes that can heal
	healerOutline = true,   -- dark outline around the healer cross
	healerSize = 0.42,      -- cross size, share of the icon
	healerPos = "topright", -- topright | topleft | bottomright | bottomleft | center
	healerX = 0,
	healerY = 0,
	targetBigger = true,   -- your current target's icon is bigger
	targetScale = 1.3,
	bigClasses = {},       -- class -> true: shown bigger (the ones you fear most)
	bigScale = 1.3,
	targetGlow = true,     -- pulsing glow around your target's icon
	glowColor = { 1, 0.74, 0.28, 1 }, -- warm gold
}
local SETTINGS_VERSION = 2

local db
local function CopyValue(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = v end
	return copy
end
-- Saved layout: CSCoderClassIndicatorDB = { version, profiles = { name = settings },
-- chars = { "Name - Realm" = profile name } }. db = the active profile.
local root
local function FillDefaults(profile)
	if profile.borderMode == "none" then profile.border, profile.borderMode = false, "class" end -- old "No border"
	profile.targetArrows, profile.arrowColor, profile.clickTarget, profile.version, profile.clickable, profile.clickArea, profile.fixedScale = nil, nil, nil, nil, nil, nil, nil -- removed
	for key, value in pairs(DEFAULTS) do
		if type(profile[key]) ~= type(value) then profile[key] = CopyValue(value) end
	end
	return profile
end
local function CharKey()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end
local function LoadSettings()
	root = type(CSCoderClassIndicatorDB) == "table" and CSCoderClassIndicatorDB or {}
	CSCoderClassIndicatorDB = root
	if type(root.profiles) ~= "table" then
		-- Version 1 kept one flat table: it becomes the "Default" profile.
		local old = {}
		for key, value in pairs(root) do old[key] = value end
		for key in pairs(old) do root[key] = nil end
		root.profiles = { Default = old }
	end
	root.chars = type(root.chars) == "table" and root.chars or {}
	root.profiles.Default = type(root.profiles.Default) == "table" and root.profiles.Default or {}
	root.version = SETTINGS_VERSION
	local name = root.chars[CharKey()]
	if type(root.profiles[name]) ~= "table" then name = "Default" end
	root.chars[CharKey()] = name
	db = FillDefaults(root.profiles[name])
end
local function ResetSettings()
	for key, value in pairs(DEFAULTS) do db[key] = CopyValue(value) end
end

-- Profiles (one per character by default "Default"; shared between characters on purpose).
local Profiles = {}
function Profiles.Current() return root.chars[CharKey()] end
function Profiles.Names()
	local names = {}
	for name in pairs(root.profiles) do names[#names + 1] = name end
	table.sort(names, function(a, b)
		if a == "Default" then return true elseif b == "Default" then return false end
		return a:lower() < b:lower()
	end)
	return names
end
function Profiles.Use(name)
	if type(root.profiles[name]) ~= "table" then root.profiles[name] = {} end
	root.chars[CharKey()] = name
	db = FillDefaults(root.profiles[name])
end
function Profiles.CopyFrom(name)
	local source = root.profiles[name]
	if type(source) ~= "table" or source == db then return end
	FillDefaults(source)
	for key in pairs(DEFAULTS) do db[key] = CopyValue(source[key]) end
end
function Profiles.Delete(name)
	if name == "Default" or name == Profiles.Current() or not root.profiles[name] then return false end
	root.profiles[name] = nil
	for char, profile in pairs(root.chars) do
		if profile == name then root.chars[char] = "Default" end
	end
	return true
end

---------------------------------------------------------------------------------------------
-- Translations: the English text is the key; Locales.lua holds the other languages
-- (ns.LOCALES[code][english] = translation). Missing text falls back to English.
---------------------------------------------------------------------------------------------

local Translations = { lang = {} }
local function T(text) return Translations.lang[text] or text end
function Translations.Load()
	local code = root and root.language
	if not code or code == "auto" then code = GetLocale() end
	if code == "esMX" then code = "esES" elseif code == "ptPT" then code = "ptBR" end
	Translations.lang = (ns and ns.LOCALES and ns.LOCALES[code]) or {}
end
function Translations.Choices()
	return { { "auto", T("Game language") }, { "enUS", "English" }, { "ptBR", "Português" }, { "esES", "Español" },
		{ "deDE", "Deutsch" }, { "frFR", "Français" }, { "itIT", "Italiano" } }
end

---------------------------------------------------------------------------------------------
-- Classes: icon coordinates, colours, names (the game's tables when it has them)
---------------------------------------------------------------------------------------------

local OWN_COORDS = {
	WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.49609375, 0, 0.25 },
	ROGUE = { 0.49609375, 0.7421875, 0, 0.25 }, DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
	HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.49609375, 0.25, 0.5 },
	PRIEST = { 0.49609375, 0.7421875, 0.25, 0.5 }, WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
	PALADIN = { 0, 0.25, 0.5, 0.75 }, DEATHKNIGHT = { 0.25, 0.49609375, 0.5, 0.75 },
	MONK = { 0.49609375, 0.7421875, 0.5, 0.75 }, DEMONHUNTER = { 0.7421875, 0.98828125, 0.5, 0.75 },
	EVOKER = { 0, 0.25, 0.75, 1 },
}
local OWN_COLORS = {
	WARRIOR = { 0.78, 0.61, 0.43 }, MAGE = { 0.25, 0.78, 0.92 }, ROGUE = { 1, 0.96, 0.41 },
	DRUID = { 1, 0.49, 0.04 }, HUNTER = { 0.67, 0.83, 0.45 }, SHAMAN = { 0, 0.44, 0.87 },
	PRIEST = { 1, 1, 1 }, WARLOCK = { 0.53, 0.53, 0.93 }, PALADIN = { 0.96, 0.55, 0.73 },
	DEATHKNIGHT = { 0.77, 0.12, 0.23 }, MONK = { 0, 1, 0.6 }, DEMONHUNTER = { 0.64, 0.19, 0.79 },
	EVOKER = { 0.2, 0.58, 0.5 },
}
local OWN_NAMES = {
	WARRIOR = "Warrior", MAGE = "Mage", ROGUE = "Rogue", DRUID = "Druid", HUNTER = "Hunter",
	SHAMAN = "Shaman", PRIEST = "Priest", WARLOCK = "Warlock", PALADIN = "Paladin",
	DEATHKNIGHT = "Death Knight", MONK = "Monk", DEMONHUNTER = "Demon Hunter", EVOKER = "Evoker",
}
local SHORT_NAMES = {
	WARRIOR = "WAR", MAGE = "MAG", ROGUE = "ROG", DRUID = "DRU", HUNTER = "HUN", SHAMAN = "SHA",
	PRIEST = "PRI", WARLOCK = "LCK", PALADIN = "PAL", DEATHKNIGHT = "DK", MONK = "MNK",
	DEMONHUNTER = "DH", EVOKER = "EVO",
}
-- Fonts for the class name (the game's own files).
local FONTS = {
	default = STANDARD_TEXT_FONT,
	serif = "Fonts\\MORPHEUS.TTF",
	friz = "Fonts\\FRIZQT__.TTF",
	narrow = "Fonts\\ARIALN.TTF",
	skurri = "Fonts\\SKURRI.TTF",
}
-- Classes that can heal (no spec info needed: the class alone is the warning).
local HEALER_CLASSES = { PRIEST = true, DRUID = true, PALADIN = true, SHAMAN = true, MONK = true, EVOKER = true }
-- Preview and test mode: the nine classes of the classic game, in this order.
local SAMPLE_CLASSES = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST", "WARLOCK", "PALADIN", "DRUID", "SHAMAN" }

local function ClassCoords(class)
	local coords = (CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]) or OWN_COORDS[class]
	return coords
end
-- The icon art: the character-creation sheet (frame cut off) or the spellbook class icon
-- (Interface\Icons\ClassIcon_<Class>, its built-in edge cut off).
local SPELL_ICON_NAMES = {
	WARRIOR = "Warrior", MAGE = "Mage", ROGUE = "Rogue", DRUID = "Druid", HUNTER = "Hunter", SHAMAN = "Shaman",
	PRIEST = "Priest", WARLOCK = "Warlock", PALADIN = "Paladin", DEATHKNIGHT = "DeathKnight", MONK = "Monk",
	DEMONHUNTER = "DemonHunter", EVOKER = "Evoker",
}
local function ClassArt(class)
	if db and db.spellIcons and SPELL_ICON_NAMES[class] then
		return "Interface\\Icons\\ClassIcon_" .. SPELL_ICON_NAMES[class], 0.08, 0.92, 0.08, 0.92
	end
	local c = ClassCoords(class) or { 0, 1, 0, 1 }
	local cutX, cutY = (c[2] - c[1]) * 0.07, (c[4] - c[3]) * 0.07
	return CLASS_TEXTURE, c[1] + cutX, c[2] - cutX, c[3] + cutY, c[4] - cutY
end
local function ClassColor(class)
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if c then return c.r, c.g, c.b end
	c = OWN_COLORS[class] or { 1, 1, 1 }
	return c[1], c[2], c[3]
end
local function ClassName(class)
	return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class]) or OWN_NAMES[class] or class
end
local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

---------------------------------------------------------------------------------------------
-- The indicator: one frame type for real nameplates and the preview
---------------------------------------------------------------------------------------------

local Indicator = { version = 1 } -- version goes up when options change (indicators redraw)
-- Textures use the game's default filtering. (Trilinear filtering was tried for smoother edges:
-- with the nameplate changing size all the time it switched resolution and the art shimmered.)
local function SetTex(t, path, wrap)
	t:SetTexture(path, wrap, wrap)
end

-- Shapes (textures made by tools/make_shapes.lua): the icon's mask, the "hole" that cuts the
-- border into a ring (so a lower opacity never shows the border through the icon), a metal
-- version of the shape for the metal border, and the soft glow.
local function Shape(mask, glow)
	return { mask = MEDIA .. mask, hole = MEDIA .. mask .. "_hole", metal = MEDIA .. mask .. "_metal",
		shade = MEDIA .. mask .. "_shade", sheen = MEDIA .. mask .. "_sheen", glow = MEDIA .. "glow_" .. glow }
end
local SHAPES = {
	round = Shape("circle", "round"),
	rounded = Shape("rsquare", "rounded"),
	square = Shape("square", "square"),
	hex = Shape("hex", "hex"),
	diamond = Shape("diamond", "diamond"),
	shield = Shape("shield", "shield"),
}

function Indicator.New(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(28, 28)
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.ring = f:CreateTexture(nil, "BORDER")
	f.ring:SetAllPoints()
	f.edges = {} -- square border without mask support
	for i = 1, 4 do f.edges[i] = f:CreateTexture(nil, "BORDER") end
	f.canMask = f.icon.AddMaskTexture and f.CreateMaskTexture and true or false
	if f.canMask then
		f.iconMask = f:CreateMaskTexture()
		f.iconMask:SetAllPoints(f.icon)
		f.icon:AddMaskTexture(f.iconMask)
		f.holeMask = f:CreateMaskTexture()
		f.holeMask:SetAllPoints(f.icon)
		f.ring:AddMaskTexture(f.holeMask)
	end
	-- Drop shadow: the shape's soft glow in black, a little down and right.
	f.shadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	f.shadow:Hide()
	-- The text on its own layer above, so the nameplate addon never covers it, with its
	-- optional background (dark plate or coloured ribbon) right under it.
	f.textHolder = CreateFrame("Frame", nil, f)
	f.textHolder:SetAllPoints()
	f.textHolder:SetFrameLevel(f:GetFrameLevel() + 5)
	f.text = f.textHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	local bg = {}
	bg.fill = f.textHolder:CreateTexture(nil, "BACKGROUND")
	bg.fill:SetTexture(WHITE)
	bg.tip = f.textHolder:CreateTexture(nil, "BACKGROUND")
	bg.tip:SetTexture(MEDIA .. "ribbon_end")
	bg.edges = {}
	for i = 1, 4 do bg.edges[i] = f.textHolder:CreateTexture(nil, "BORDER") end
	f.textBg = bg
	-- Badge: its own frame BELOW the indicator, so it starts behind the icon.
	local badge = CreateFrame("Frame", nil, f)
	badge:SetAllPoints()
	badge.pieces = {}
	for key, file in pairs({ midFill = "badge_mid_fill", midEdge = "badge_mid_edge", rFill = "badge_cap_fill",
		rEdge = "badge_cap_edge", lFill = "badge_cap_fill", lEdge = "badge_cap_edge", midSheen = "badge_mid_sheen",
		rSheen = "badge_cap_sheen", lSheen = "badge_cap_sheen" }) do
		local layer = key:find("Edge") and "BORDER" or key:find("Sheen") and "ARTWORK" or "BACKGROUND"
		local t = badge:CreateTexture(nil, layer)
		t:SetTexture(MEDIA .. file)
		if key:find("Sheen") then t:SetBlendMode("ADD"); t:SetVertexColor(1, 1, 1, 0.22) end
		badge.pieces[key] = t
	end
	badge:Hide()
	f.badge = badge
	-- Healer mark: a green cross with a dark outline at the icon's top-right corner.
	local healer = CreateFrame("Frame", nil, f)
	healer:SetFrameLevel(f:GetFrameLevel() + 6)
	healer.parts = {}
	for i, part in ipairs({ { 0, 0, 0, 1, "BACKGROUND" }, { 0, 0, 0, 1, "BACKGROUND" },
		{ 0.15, 1, 0.3, 1, "ARTWORK" }, { 0.15, 1, 0.3, 1, "ARTWORK" } }) do
		local t = healer:CreateTexture(nil, part[5])
		t:SetColorTexture(part[1], part[2], part[3], part[4])
		t:SetPoint("CENTER")
		healer.parts[i] = t
	end
	f.healer = healer
	-- Target glow: a soft halo of the icon's shape behind it, pulsing (only around the icon).
	f.glow = f:CreateTexture(nil, "BACKGROUND", nil, -7)
	f.glow:SetPoint("CENTER")
	f.glow:SetBlendMode("ADD")
	f.glow:Hide()
	-- A smooth pulse driven by the game's animation system (eased, no per-frame Lua).
	if f.glow.CreateAnimationGroup then
		local anim = f.glow:CreateAnimationGroup()
		local fade = anim:CreateAnimation("Alpha")
		fade:SetFromAlpha(1)
		fade:SetToAlpha(0.4)
		fade:SetDuration(0.9)
		if fade.SetSmoothing then fade:SetSmoothing("IN_OUT") end
		anim:SetLooping("BOUNCE")
		f.glowAnim = anim
	end
	-- Inner shade (over the icon) and the soft border glow (behind it).
	f.shade = f:CreateTexture(nil, "ARTWORK", nil, 2)
	f.shade:SetAllPoints(f.icon)
	f.shade:Hide()
	-- Glass sheen: a soft white reflection on the top half of the icon.
	f.sheen = f:CreateTexture(nil, "ARTWORK", nil, 3)
	f.sheen:SetAllPoints(f.icon)
	f.sheen:SetBlendMode("ADD")
	f.sheen:Hide()
	f.borderGlow = f:CreateTexture(nil, "BACKGROUND", nil, -6)
	f.borderGlow:SetPoint("CENTER")
	f.borderGlow:SetBlendMode("ADD")
	f.borderGlow:Hide()
	-- Every drawn piece, for Indicator.SetSnapping.
	local regions = { f.icon, f.iconMask, f.ring, f.holeMask, f.shade, f.sheen, f.shadow, f.glow, f.borderGlow, f.text, bg.fill, bg.tip }
	for _, list in ipairs({ f.edges, bg.edges, healer.parts }) do
		for _, region in ipairs(list) do regions[#regions + 1] = region end
	end
	for _, piece in pairs(badge.pieces) do regions[#regions + 1] = piece end
	f.regions = regions
	f:Hide()
	return f
end

-- Pixel snapping on or off for every piece. Off when the indicator rides on a nameplate that
-- moves by fractions of a pixel (each edge of a thin line would round on its own: flicker);
-- on when Lock keeps it on whole pixels (crisp and stable).
function Indicator.SetSnapping(f, on)
	if f.snapping == on then return end
	f.snapping = on
	for _, region in ipairs(f.regions) do
		if region.SetSnapToPixelGrid then pcall(region.SetSnapToPixelGrid, region, on) end
		if region.SetTexelSnappingBias then pcall(region.SetTexelSnappingBias, region, on and 0.5 or 0) end
	end
end

local function ModeColor(mode, custom, class)
	if mode == "class" then return ClassColor(class) end
	if mode == "enemy" then return ENEMY_RED[1], ENEMY_RED[2], ENEMY_RED[3] end
	if mode == "white" then return 1, 1, 1 end
	if mode == "dark" then return 0.08, 0.07, 0.06 end
	if mode == "gold" then return 1, 0.78, 0.25 end
	return custom[1], custom[2], custom[3]
end

-- Four 1 px lines around a region (or hidden).
local function PlaceEdges(edges, region, show, r, g, b)
	for i, e in ipairs(edges) do
		e:ClearAllPoints()
		if show then
			e:SetColorTexture(r, g, b, 1)
			if i == 1 then e:SetPoint("TOPLEFT", region); e:SetPoint("TOPRIGHT", region); e:SetHeight(1)
			elseif i == 2 then e:SetPoint("BOTTOMLEFT", region); e:SetPoint("BOTTOMRIGHT", region); e:SetHeight(1)
			elseif i == 3 then e:SetPoint("TOPLEFT", region); e:SetPoint("BOTTOMLEFT", region); e:SetWidth(1)
			else e:SetPoint("TOPRIGHT", region); e:SetPoint("BOTTOMRIGHT", region); e:SetWidth(1) end
		end
		e:SetShown(show)
	end
end

-- Draw the indicator for a class (class = "MAGE", name = the text to show; isTarget = it is
-- your current target).
function Indicator.Style(f, class, name, isTarget)
	local coords = ClassCoords(class)
	if not coords then f:Hide() return false end
	local mult = 1
	if db.bigClasses[class] then mult = mult * db.bigScale end
	if isTarget and db.targetBigger then mult = mult * db.targetScale end
	local size = math.floor(db.size * mult + 0.5)
	f:SetSize(size, size)
	f:SetAlpha(db.alpha)
	f.textHolder:SetFrameLevel(f:GetFrameLevel() + 5)

	local shape = SHAPES[db.shape] and db.shape or "round"
	-- Without mask support only round (the game's round icons) and square can be drawn.
	if not f.canMask and shape ~= "round" then shape = "square" end
	local info = SHAPES[shape]
	local border = db.border and db.borderSize or 0
	f.icon:ClearAllPoints()
	f.icon:SetPoint("TOPLEFT", border, -border)
	f.icon:SetPoint("BOTTOMRIGHT", -border, border)

	if shape == "round" and not f.canMask then
		local l, r, t, b = coords[1], coords[2], coords[3], coords[4]
		f.icon:SetTexture(CLASS_CIRCLES)
		f.icon:SetTexCoord(l, r, t, b)
	else
		local texture, l, r, t, b = ClassArt(class)
		SetTex(f.icon, texture)
		f.icon:SetTexCoord(l, r, t, b)
	end
	if f.canMask then
		SetTex(f.iconMask, info.mask, "CLAMPTOBLACKADDITIVE")
	end
	-- Inner shade: a soft dark edge inside the icon, for depth.
	if db.innerShade and f.canMask then
		SetTex(f.shade, info.shade)
		f.shade:Show()
	else
		f.shade:Hide()
	end
	-- Glass sheen.
	if db.iconSheen and f.canMask then
		SetTex(f.sheen, info.sheen)
		f.sheen:SetVertexColor(1, 1, 1, 0.2)
		f.sheen:Show()
	else
		f.sheen:Hide()
	end

	-- Border: a ring of the shape: flat colour, the metal shine tinted with that colour, or
	-- "soft" (the flat ring plus a soft glow of the same colour around it).
	local cr, cg, cb = ModeColor(db.borderMode, db.borderColor, class)
	local ring = border > 0 and f.canMask
	if ring then
		SetTex(f.ring, db.borderStyle == "metal" and info.metal or info.mask)
		f.ring:SetVertexColor(cr, cg, cb, 1)
		SetTex(f.holeMask, info.hole, "CLAMPTOWHITE")
	end
	f.ring:SetShown(ring)
	if ring and db.borderStyle == "soft" then
		SetTex(f.borderGlow, info.glow)
		f.borderGlow:SetBlendMode("ADD")
		f.borderGlow:SetSize(size * 1.75, size * 1.75)
		f.borderGlow:SetVertexColor(cr, cg, cb, 0.55)
		f.borderGlow:Show()
	elseif ring and db.borderStyle == "frame" then
		-- "Soft frame": a soft dark outline around a thin, slightly see-through rim.
		f.ring:SetVertexColor(cr, cg, cb, 0.85)
		SetTex(f.borderGlow, info.glow)
		f.borderGlow:SetBlendMode("BLEND")
		f.borderGlow:SetSize(size * 1.5, size * 1.5)
		f.borderGlow:SetVertexColor(0, 0, 0, 0.9)
		f.borderGlow:Show()
	else
		f.borderGlow:Hide()
	end
	local square = border > 0 and not f.canMask
	for i, e in ipairs(f.edges) do
		e:ClearAllPoints()
		if square then
			e:SetColorTexture(cr, cg, cb, 1)
			if i == 1 then e:SetPoint("TOPLEFT"); e:SetPoint("TOPRIGHT"); e:SetHeight(border)
			elseif i == 2 then e:SetPoint("BOTTOMLEFT"); e:SetPoint("BOTTOMRIGHT"); e:SetHeight(border)
			elseif i == 3 then e:SetPoint("TOPLEFT", 0, -border); e:SetPoint("BOTTOMLEFT", 0, border); e:SetWidth(border)
			else e:SetPoint("TOPRIGHT", 0, -border); e:SetPoint("BOTTOMRIGHT", 0, border); e:SetWidth(border) end
		end
		e:SetShown(square)
	end

	-- Drop shadow.
	if db.iconShadow then
		SetTex(f.shadow, info.glow)
		f.shadow:SetVertexColor(0, 0, 0, 1)
		f.shadow:SetSize(size * 1.8, size * 1.8)
		f.shadow:ClearAllPoints()
		f.shadow:SetPoint("CENTER", f, "CENTER", 2, -2)
		f.shadow:Show()
	else
		f.shadow:Hide()
	end

	-- Healer mark: a cross about 40% of the icon, outlined.
	local healer = f.healer
	if db.healerMark and HEALER_CLASSES[class] then
		local s = math.max(6, math.floor(size * db.healerSize))
		local bar = math.max(2, math.floor(s / 3))
		healer:SetSize(s + 4, s + 4)
		healer:ClearAllPoints()
		local pos = db.healerPos
		local inX = pos:find("left") and 1 or -1
		local inY = pos:find("top") and -1 or 1
		if pos == "center" then healer:SetPoint("CENTER", f, "CENTER", db.healerX, db.healerY)
		else healer:SetPoint("CENTER", f, string.upper(pos), math.floor(inX * s * 0.2 + 0.5) + db.healerX, math.floor(inY * s * 0.2 + 0.5) + db.healerY) end
		local p = healer.parts
		p[1]:SetSize(s + 4, bar + 4); p[2]:SetSize(bar + 4, s + 4)
		p[3]:SetSize(s, bar); p[4]:SetSize(bar, s)
		p[1]:SetShown(db.healerOutline); p[2]:SetShown(db.healerOutline)
		healer:Show()
	else
		healer:Hide()
	end

	local text, bg = f.text, f.textBg
	local plate, ribbon, badgeOn = false, false, false
	local textGap, textW = 0, 0 -- beside the icon: whole pixels from the icon's edge to the text, text width
	local textH, textTop = 0, 0 -- text height (whole pixels) and its top, down from the icon's top
	if db.showText and name then
		if db.textFormat == "short" then name = SHORT_NAMES[class] or name end
		local outline = db.textOutline
		local font = FONTS[db.textFont] or STANDARD_TEXT_FONT
		if not pcall(text.SetFont, text, font, db.textSize, outline) or not text:GetFont() then
			if not pcall(text.SetFont, text, STANDARD_TEXT_FONT, db.textSize, outline) then
				text:SetFontObject("GameFontNormal")
			end
		end
		if db.textShadow then
			text:SetShadowColor(0, 0, 0, 1); text:SetShadowOffset(1, -1)
		else
			text:SetShadowOffset(0, 0)
		end
		text:SetText(db.textUpper and string.upper(name) or name)
		text:SetTextColor(ModeColor(db.textMode, db.textColor, class))
		text:ClearAllPoints()
		local pos, x, y = db.textPos, db.textX, db.textY
		textH = math.ceil(text:GetStringHeight() or db.textSize)
		textTop = math.floor((size - textH) / 2)
		-- With a background the text sits a little further out, so the plate clears the icon.
		local pad = db.textBg ~= "none" and 4 or 0
		if db.textBg == "badge" then pad = 3 end
		if pos == "above" then text:SetPoint("BOTTOM", f, "TOP", x, 2 + pad * 2 + y)
		-- Beside the icon: placed by its top corner at whole pixels (centring on the icon gave
		-- half pixels, and the text rounded differently from its plate at some camera angles).
		elseif pos == "left" then text:SetPoint("TOPRIGHT", f, "TOPLEFT", -3 - pad * 2 + x, -textTop + y)
		elseif pos == "right" then text:SetPoint("TOPLEFT", f, "TOPRIGHT", 3 + pad * 2 + x, -textTop + y)
		else text:SetPoint("TOP", f, "BOTTOM", x, -2 - pad * 2 + y) end
		text:Show()
		textGap = 3 + pad * 2 + (pos == "left" and -x or x)
		textW = math.ceil(text:GetStringWidth() or 0)
		plate, ribbon, badgeOn = db.textBg == "plate", db.textBg == "ribbon", db.textBg == "badge"
	else
		text:Hide()
	end

	-- Name background: a dark plate with a thin edge, or a coloured ribbon with a notched end
	-- (pointing away from the icon).
	local br, bgc, bb = ModeColor(db.textBgMode, db.textBgColor, class)
	local padX, padY = 6, 3
	bg.fill:ClearAllPoints()
	bg.tip:ClearAllPoints()
	if plate or ribbon then
		-- Beside the icon the background always starts at the icon's edge; above or below it
		-- just wraps the text.
		local pos = db.textPos
		-- Whole-pixel widths (the text width rounded up), so every piece sits a whole number of
		-- pixels from the icon and they all round the same way.
		local plateH = db.textSize + padY * 2
		local plateTop = textTop + math.floor((textH - plateH) / 2)
		if pos == "right" then
			bg.fill:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, -plateTop + db.textY)
			bg.fill:SetSize(textGap + textW + padX, plateH)
		elseif pos == "left" then
			bg.fill:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, -plateTop + db.textY)
			bg.fill:SetSize(textGap + textW + padX, plateH)
		else
			bg.fill:SetPoint("TOPLEFT", text, "TOPLEFT", -padX, padY)
			bg.fill:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", padX, -padY)
		end
	end
	if plate then
		bg.fill:SetVertexColor(0, 0, 0, 0.7)
	elseif ribbon then
		bg.fill:SetVertexColor(br, bgc, bb, 0.9)
		local h = db.textSize + padY * 2
		local flip = db.textPos == "left"
		bg.tip:SetSize(h * 0.6, h)
		bg.tip:SetVertexColor(br, bgc, bb, 0.9)
		if flip then
			bg.tip:SetTexCoord(1, 0, 0, 1)
			bg.tip:SetPoint("RIGHT", bg.fill, "LEFT")
		else
			bg.tip:SetTexCoord(0, 1, 0, 1)
			bg.tip:SetPoint("LEFT", bg.fill, "RIGHT")
		end
	end
	bg.fill:SetShown(plate or ribbon)
	bg.tip:SetShown(ribbon)
	PlaceEdges(bg.edges, bg.fill, plate, br, bgc, bb)

	-- Badge: a dark plate with a coloured edge and pointed end(s). Beside the icon it starts
	-- behind the icon's centre (one point, away from the icon); above or below it is centred
	-- with a point on both sides.
	local badge = f.badge
	if badgeOn then
		local h = math.max(db.textSize + 10, math.floor(size * 0.62))
		local capW = math.floor(h * 0.5)
		local pos = db.textPos
		badge:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
		for _, piece in pairs(badge.pieces) do
			piece:ClearAllPoints()
			piece:SetHeight(h)
		end
		local p = badge.pieces
		local function Cap(fill, edge, side, anchor, mirror)
			for _, t in ipairs({ fill, edge }) do
				t:SetWidth(capW)
				t:SetTexCoord(mirror and 1 or 0, mirror and 0 or 1, 0, 1)
				t:SetPoint(side, anchor, side == "LEFT" and "RIGHT" or "LEFT")
				t:Show()
			end
		end
		for _, t in ipairs({ p.midFill, p.midEdge }) do
			local half = math.floor(size / 2)
			local top = textTop + math.floor((textH - h) / 2)
			if pos == "right" then
				t:SetPoint("TOPLEFT", f, "TOPLEFT", half, -top + db.textY)
				t:SetWidth(size - half + textGap + textW + 4)
			elseif pos == "left" then
				t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -half, -top + db.textY)
				t:SetWidth(size - half + textGap + textW + 4)
			else
				t:SetPoint("LEFT", text, "LEFT", -4, 0)
				t:SetPoint("RIGHT", text, "RIGHT", 4, 0)
			end
			t:Show()
		end
		local rightCap = pos ~= "left"
		local leftCap = pos ~= "right"
		if rightCap then Cap(p.rFill, p.rEdge, "LEFT", p.midFill, false)
		else p.rFill:Hide(); p.rEdge:Hide() end
		if leftCap then Cap(p.lFill, p.lEdge, "RIGHT", p.midFill, true)
		else p.lFill:Hide(); p.lEdge:Hide() end
		for _, t in ipairs({ p.midEdge, p.rEdge, p.lEdge }) do t:SetVertexColor(br, bgc, bb, 1) end
		-- Sheen over each piece (same place and mirroring as its fill).
		for fill, sheen in pairs({ [p.midFill] = p.midSheen, [p.rFill] = p.rSheen, [p.lFill] = p.lSheen }) do
			sheen:ClearAllPoints()
			sheen:SetAllPoints(fill)
			sheen:SetTexCoord(fill:GetTexCoord())
			sheen:SetShown(fill:IsShown())
		end
		badge:Show()
	else
		badge:Hide()
	end

	-- Target glow: same shape as the icon; the glow texture is 2x its shape and fades to zero before its edge (make_shapes.lua).
	if isTarget and db.targetGlow then
		local c = db.glowColor
		SetTex(f.glow, info.glow)
		f.glow:SetSize(size * 2, size * 2)
		f.glow:SetVertexColor(c[1], c[2], c[3], 0.85)
		f.glow:Show()
		if f.glowAnim and not f.glowAnim:IsPlaying() then f.glowAnim:Play() end
	else
		f.glow:Hide()
		if f.glowAnim then f.glowAnim:Stop() end
	end
	return true
end

-- Place the indicator against a target region (a health bar or the plate itself).
function Indicator.Place(f, target)
	f:ClearAllPoints()
	local side, x, y = db.anchor, db.offsetX, db.offsetY
	if side == "bottom" then f:SetPoint("TOP", target, "BOTTOM", x, -y)
	elseif side == "left" then f:SetPoint("RIGHT", target, "LEFT", -y + x, 0)
	elseif side == "right" then f:SetPoint("LEFT", target, "RIGHT", y + x, 0)
	else f:SetPoint("BOTTOM", target, "TOP", x, y) end
end

-- Pixel lock: the nameplate moves by fractions of a pixel, a different fraction every frame,
-- and thin lines (border, badge edge, text outline) rounded differently each time: flicker.
-- Instead of hanging the indicator on the bar, its spot is measured every frame and rounded
-- to a WHOLE screen pixel, so its pieces land on exactly the same pixels while it moves.
-- Falls back to plain anchoring (with snapping off) when the bar can't be measured.
local Lock = { frames = {} }
local function PixelSize()
	local _, height = GetPhysicalScreenSize()
	return (height and height > 0) and (768 / height) or 1
end
function Lock.Snap(value, current, px)
	if current and math.abs(value - current) < px * 0.8 then return current end
	return math.floor(value / px + 0.5) * px
end
-- The indicator's anchor point and offsets from the screen's bottom-left, or nil.
function Lock.Spot(f)
	local target = f.lockTarget
	if not target or Lock.refused then return nil end
	local ok, left, bottom, width, height = pcall(target.GetRect, target)
	if not ok or type(left) ~= "number" or type(width) ~= "number" then
		-- The game restricts nameplates (WoW Forever): stop asking for this session.
		Lock.refused = true
		return nil
	end
	local s, fs = target:GetEffectiveScale(), f:GetEffectiveScale()
	local side, x, y = db.anchor, db.offsetX, db.offsetY
	local point, ax, ay
	if side == "bottom" then point, ax, ay = "TOP", (left + width / 2) * s + x * fs, bottom * s - y * fs
	elseif side == "left" then point, ax, ay = "RIGHT", left * s + (x - y) * fs, (bottom + height / 2) * s
	elseif side == "right" then point, ax, ay = "LEFT", (left + width) * s + (x + y) * fs, (bottom + height / 2) * s
	else point, ax, ay = "BOTTOM", (left + width / 2) * s + x * fs, (bottom + height) * s + y * fs end
	local px = PixelSize()
	-- Hysteresis: a unit standing still still bobs a little, and right between two pixels plain
	-- rounding flipped the indicator 1 px back and forth. It moves to a new pixel only once the
	-- bar has moved most of a pixel away from where the indicator sits.
	ax = Lock.Snap(ax, f.lockAX, px)
	ay = Lock.Snap(ay, f.lockAY, px)
	f.lockAX, f.lockAY = ax, ay
	return point, ax / fs, ay / fs
end
function Lock.Apply(f)
	local point, x, y = Lock.Spot(f)
	if not point then return false end
	if f.lockPoint ~= point or f.lockX ~= x or f.lockY ~= y then
		f.lockPoint, f.lockX, f.lockY = point, x, y
		f:ClearAllPoints()
		f:SetPoint(point, UIParent, "BOTTOMLEFT", x, y)
	end
	return true
end
-- Hang the indicator on its bar: locked to whole pixels when possible.
function Lock.Attach(f, target)
	f.lockTarget = target
	f.lockPoint, f.lockAX, f.lockAY = nil, nil, nil
	if Lock.Apply(f) then
		Lock.frames[f] = true
		Indicator.SetSnapping(f, true)
	else
		-- Can't be measured (the game restricts nameplates): every piece rounds the SAME way
		-- instead. A pixel-perfect scale (1 unit = whole screen pixels), whole-pixel offsets
		-- inside, snapping on everywhere: the set moves as one block.
		Lock.frames[f] = nil
		if f.SetIgnoreParentScale then
			f:SetIgnoreParentScale(true)
			local _, height = GetPhysicalScreenSize()
			local pixel = (height and height > 0) and (768 / height) or 1
			f:SetScale(pixel * math.max(1, math.floor(UIParent:GetEffectiveScale() / pixel + 0.5)))
		end
		Indicator.Place(f, target)
		Indicator.SetSnapping(f, true)
	end
end
function Lock.Detach(f) Lock.frames[f] = nil end
Lock.driver = CreateFrame("Frame")
Lock.driver:SetScript("OnUpdate", function()
	for f in pairs(Lock.frames) do
		if f:IsVisible() and not Lock.Apply(f) then
			-- Can't be measured any more: back to plain anchoring.
			Lock.frames[f] = nil
			Indicator.Place(f, f.lockTarget)
			Indicator.SetSnapping(f, true)
		end
	end
end)

---------------------------------------------------------------------------------------------
-- Real nameplates
---------------------------------------------------------------------------------------------

local testMode = false
local UpdatePreview -- set by the options window

-- The health bar the nameplate addon draws (Plater, the default UI), or the plate itself.
local function PlateTarget(plate)
	for _, frame in ipairs({ plate.unitFrame, plate.UnitFrame }) do
		local bar = frame and (frame.healthBar or frame.HealthBar)
		local ok, visible = pcall(function() return bar:IsVisible() end)
		if bar and ok and visible then return bar end
	end
	return plate
end

-- Battleground scoreboard: inside instances the game can hide a unit's class (a "secret"
-- value); the scoreboard still lists every player's name, faction and class. Name -> entry.
local Score = { byName = {} }
local CLASS_TOKENS = {}
for class in pairs(OWN_COORDS) do CLASS_TOKENS[class] = true end
function Score.Refresh()
	if not (GetNumBattlefieldScores and GetBattlefieldScore) then return end
	wipe(Score.byName)
	for i = 1, GetNumBattlefieldScores() do
		local results = { pcall(GetBattlefieldScore, i) }
		local name = results[2]
		if results[1] and type(name) == "string" and not IsSecret(name) then
			local entry = {}
			-- The return order differs between clients: take the faction (0 Horde, 1 Alliance)
			-- and the class token wherever they are.
			for j = 3, #results do
				local v = results[j]
				if not IsSecret(v) then
					if j == 7 and (v == 0 or v == 1) then entry.faction = v end
					if type(v) == "string" and CLASS_TOKENS[v] then entry.class = v end
				end
			end
			if entry.class then
				Score.byName[name] = entry
				Score.byName[string.match(name, "^[^%-]+") or name] = entry -- without the realm
			end
		end
	end
end
-- The class token for a unit, from the scoreboard (nil when unknown).
function Score.Find(unit)
	local ok, name, second = pcall(UnitName, unit)
	if not ok or type(name) ~= "string" or IsSecret(name) then return nil end
	-- WoW Forever names have a surname: UnitName gives "Mr", "Brigg" while the scoreboard says
	-- "Mr Brigg". (On other clients the second value is the realm: "Name-Realm".)
	if type(second) == "string" and second ~= "" and not IsSecret(second) then
		local entry = Score.byName[name .. " " .. second] or Score.byName[name .. "-" .. second]
		if entry then return entry end
	end
	return Score.byName[name]
end
-- Ask the game for a fresh scoreboard now (an unknown player just showed up), at most once a
-- second; UPDATE_BATTLEFIELD_SCORE then draws the indicators that were waiting.
function Score.Request()
	local now = GetTime()
	if Score.asked and now - Score.asked < 1 then return end
	Score.asked = now
	if RequestBattlefieldScoreData then pcall(RequestBattlefieldScoreData) end
end
function Score.MyFaction()
	local faction = UnitFactionGroup("player")
	return faction == "Horde" and 0 or faction == "Alliance" and 1 or nil
end

-- A unit test that can't be read (secret, or an error) gives nil instead of breaking.
local function Ask(fn, ...)
	local ok, value = pcall(fn, ...)
	if not ok or IsSecret(value) then return nil end
	return value
end

local function UnitWanted(unit)
	if testMode then return not UnitIsUnit(unit, "player") end
	if Ask(UnitIsUnit, unit, "player") then return false end
	local isPlayer = Ask(UnitIsPlayer, unit)
	local enemy = Ask(UnitCanAttack, "player", unit) or Ask(UnitIsEnemy, "player", unit)
	if isPlayer == nil or enemy == nil then
		-- Hidden by the game: the scoreboard says if it is a player and on which side.
		local entry = Score.Find(unit)
		if not entry then Score.Request(); return false end
		if entry.faction and Score.MyFaction() then return entry.faction ~= Score.MyFaction() or db.friends end
		return true
	end
	if not isPlayer then return false end
	return enemy or db.friends
end

local function HidePlate(plate)
	if plate and plate.cciIndicator then plate.cciIndicator:Hide(); Lock.Detach(plate.cciIndicator) end
end

local function UpdateUnit(unit)
	if not (unit and C_NamePlate) then return end
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
	if not (db.enabled or testMode) or not UnitWanted(unit) then HidePlate(plate) return end

	local name, class
	if testMode then
		local index = tonumber(string.match(unit, "%d+")) or 1
		class = SAMPLE_CLASSES[(index - 1) % #SAMPLE_CLASSES + 1]
		name = ClassName(class)
	else
		local ok, n, c = pcall(UnitClass, unit)
		if ok and c and not IsSecret(c) and not IsSecret(n) then
			name, class = n, c
		else
			-- Hidden by the game (battlegrounds): the class from the scoreboard.
			local entry = Score.Find(unit)
			if not entry then Score.Request(); HidePlate(plate) return end
			class, name = entry.class, ClassName(entry.class)
		end
	end

	local f = plate.cciIndicator
	if not f then
		f = Indicator.New(plate)
		plate.cciIndicator = f
	end
	-- Redraw only when something changed (class, target, options, the bar it sits on): the game
	-- sends unit events all the time, and restyling on each one made the name flicker.
	local isTarget = UnitIsUnit(unit, "target")
	local target = PlateTarget(plate)
	-- The indicator lives INSIDE the bar it sits on (Plater's or the game's): same scale and the
	-- same pixel rounding, so it moves glued to the bar like the unit's own name. (Kept on the
	-- plate, it rounded its position on its own and wobbled 1-2 px against the bar.)
	if f:GetParent() ~= target then f:SetParent(target) end
	if f.lastClass == class and f.lastName == name and f.lastTarget == isTarget and f.lastVersion == Indicator.version
		and f.lastAnchor == target and f:IsShown() then
		return
	end
	pcall(function()
		f:SetFrameStrata(target:GetFrameStrata())
		f:SetFrameLevel(target:GetFrameLevel() + 20)
	end)
	if Indicator.Style(f, class, name, isTarget) then
		Lock.Attach(f, target)
		f:Show()
		f.lastClass, f.lastName, f.lastTarget, f.lastVersion, f.lastAnchor = class, name, isTarget, Indicator.version, target
	end
end

local function RefreshAll()
	if not C_NamePlate then return end
	for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit then UpdateUnit(unit) else HidePlate(plate) end
	end
end

local function Changed()
	Indicator.version = Indicator.version + 1 -- options changed: every indicator redraws
	RefreshAll()
	if CSCoderMinimap then CSCoderMinimap.Update() end
	if UpdatePreview then UpdatePreview() end
end

local function SetTestMode(on)
	testMode = on
	print(string.format("|cffffd200%s|r: %s", TITLE, on and ("|cff00ff00" .. T("Test mode ON") .. "|r " .. T("(every nameplate gets a sample class)"))
		or ("|cffff4040" .. T("Test mode OFF") .. "|r")))
	Changed()
end

---------------------------------------------------------------------------------------------
-- Options window (own window, dark and gold, live preview)
---------------------------------------------------------------------------------------------

local OpenOptions
do
	local GOLD = { 1, 0.82, 0 }
	local window, refreshers, list = nil, {}, nil
	local scrollFrame -- the Settings page (sliders pass the plain mouse wheel to it)
	local COL1, COL2, COL3, CONTROL_W = 24, 370, 716, 200

	local function Edges(frame, r, g, b, a)
		for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
			local e = frame:CreateTexture(nil, "BORDER")
			e:SetColorTexture(r, g, b, a or 1)
			if side == "TOP" or side == "BOTTOM" then
				e:SetPoint(side .. "LEFT"); e:SetPoint(side .. "RIGHT"); e:SetHeight(1)
			else
				e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(1)
			end
		end
	end
	local function Fill(frame, r, g, b, a)
		local t = frame:CreateTexture(nil, "BACKGROUND")
		t:SetAllPoints()
		t:SetColorTexture(r, g, b, a or 1)
		return t
	end
	local function Label(parent, text, x, y, font)
		local s = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormalSmall")
		s:SetPoint("TOPLEFT", x, y)
		s:SetText(text)
		return s
	end
	local function Heading(parent, text, x, y)
		local s = Label(parent, text, x, y, "GameFontNormal")
		local line = parent:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
		line:SetHeight(1)
		line:SetPoint("LEFT", s, "RIGHT", 8, 0)
		line:SetWidth(300 - s:GetStringWidth())
		return s
	end
	local function Tooltip(frame, text)
		if not text then return end
		frame:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(text, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	-- A control that depends on something: faded and locked while that is off.
	local function Gate(frame, condition)
		refreshers[#refreshers + 1] = function()
			local on = condition()
			frame:SetAlpha(on and 1 or 0.35)
			if frame.SetEnabled then frame:SetEnabled(on) end
			if frame.EnableMouse then frame:EnableMouse(on) end
		end
	end

	local function Button(parent, text, width)
		local b = CreateFrame("Button", nil, parent)
		b:SetSize(width or 120, 22)
		Fill(b, 0.16, 0.13, 0.09, 1)
		Edges(b, GOLD[1], GOLD[2], GOLD[3], 0.6)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 0.82, 0, 0.12)
		b.label = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		b.label:SetPoint("CENTER")
		b.label:SetText(text)
		return b
	end

	local function AddCheck(parent, text, key, x, y, tip)
		local c = CreateFrame("CheckButton", nil, parent)
		c:SetSize(18, 18)
		c:SetPoint("TOPLEFT", x, y)
		Fill(c, 0.08, 0.07, 0.05, 1)
		Edges(c, GOLD[1], GOLD[2], GOLD[3], 0.6)
		local mark = c:CreateTexture(nil, "ARTWORK")
		mark:SetPoint("TOPLEFT", 4, -4); mark:SetPoint("BOTTOMRIGHT", -4, 4)
		mark:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
		c:SetCheckedTexture(mark)
		local label = c:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		label:SetPoint("LEFT", c, "RIGHT", 8, 0)
		label:SetText(text)
		c:SetHitRectInsets(0, -(label:GetStringWidth() + 12), 0, 0)
		c:SetScript("OnClick", function(self) db[key] = self:GetChecked() and true or false; Changed() end)
		Tooltip(c, tip)
		refreshers[#refreshers + 1] = function() c:SetChecked(db[key]) end
		return c
	end

	local function Round(value, step)
		return math.floor(value / step + 0.5) * step
	end
	local function AddSlider(parent, text, key, low, high, step, x, y, tip, width)
		width = width or CONTROL_W
		local holder = CreateFrame("Frame", nil, parent)
		holder:SetSize(width + 70, 40)
		holder:SetPoint("TOPLEFT", x, y)
		Label(holder, text, 0, 0)
		local s = CreateFrame("Slider", nil, holder)
		s:SetOrientation("HORIZONTAL")
		s:SetSize(width, 14)
		s:SetPoint("TOPLEFT", 0, -18)
		local track = s:CreateTexture(nil, "BACKGROUND")
		track:SetColorTexture(0.2, 0.17, 0.12, 1)
		track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
		s:SetThumbTexture(WHITE)
		local thumb = s:GetThumbTexture()
		thumb:SetSize(8, 14)
		thumb:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
		s:SetMinMaxValues(low, high)
		s:SetValueStep(step)
		if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
		local box = CreateFrame("EditBox", nil, holder)
		box:SetSize(48, 18)
		box:SetPoint("LEFT", s, "RIGHT", 12, 0)
		box:SetAutoFocus(false)
		box:SetFontObject("GameFontHighlightSmall")
		box:SetJustifyH("CENTER")
		Fill(box, 0.08, 0.07, 0.05, 1)
		Edges(box, GOLD[1], GOLD[2], GOLD[3], 0.4)
		local function Show(value)
			box:SetText(step < 1 and string.format("%.2f", value) or tostring(math.floor(value + 0.5)))
		end
		local lock = false
		s:SetScript("OnValueChanged", function(_, value)
			if lock then return end
			value = Round(value, step)
			db[key] = value
			Show(value)
			Changed()
		end)
		box:SetScript("OnEnterPressed", function(self)
			local value = tonumber(self:GetText())
			if value then s:SetValue(math.max(low, math.min(high, value))) end
			Show(db[key])
			self:ClearFocus()
		end)
		box:SetScript("OnEscapePressed", function(self) Show(db[key]); self:ClearFocus() end)
		s:EnableMouseWheel(true)
		s:SetScript("OnMouseWheel", function(_, delta)
			-- Shift + wheel steps the slider; the plain wheel scrolls the page (like Quest Indicator).
			if IsShiftKeyDown() or not scrollFrame then
				s:SetValue(math.max(low, math.min(high, db[key] + delta * step)))
			else
				local range = scrollFrame:GetVerticalScrollRange()
				scrollFrame:SetVerticalScroll(math.max(0, math.min(range, scrollFrame:GetVerticalScroll() - delta * 40)))
			end
		end)
		Tooltip(s, tip)
		refreshers[#refreshers + 1] = function()
			lock = true
			s:SetValue(db[key])
			lock = false
			Show(db[key])
		end
		holder.slider = s
		return holder
	end

	-- Drop-down: options = { { value, text }, ... }. One shared list frame.
	local function CloseList() if list then list:Hide() end end
	local function AddDropdown(parent, text, key, options, x, y, tip)
		local holder = CreateFrame("Frame", nil, parent)
		holder:SetSize(CONTROL_W, 42)
		holder:SetPoint("TOPLEFT", x, y)
		Label(holder, text, 0, 0)
		local b = Button(holder, "", CONTROL_W)
		b:SetPoint("TOPLEFT", 0, -16)
		b.label:ClearAllPoints()
		b.label:SetPoint("LEFT", 8, 0)
		b.label:SetFontObject("GameFontHighlightSmall")
		local arrow = b:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		arrow:SetPoint("RIGHT", -8, 0)
		arrow:SetText("v")
		-- key can be { get = fn, set = fn } and options a function (lists that change).
		local function Get() if type(key) == "table" then return key.get() end return db[key] end
		local function Set(value) if type(key) == "table" then key.set(value) else db[key] = value end end
		local function Options() if type(options) == "function" then return options() end return options end
		local function TextOf(value)
			for _, option in ipairs(Options()) do if option[1] == value then return option[2] end end
			return tostring(value)
		end
		b:SetScript("OnClick", function()
			if list and list:IsShown() and list.owner == b then CloseList() return end
			if not list then
				list = CreateFrame("Frame", nil, window)
				list:SetFrameStrata("FULLSCREEN_DIALOG")
				Fill(list, 0.07, 0.06, 0.04, 0.98)
				Edges(list, GOLD[1], GOLD[2], GOLD[3], 0.8)
				list.rows = {}
			end
			list.owner = b
			local options = Options()
			list:ClearAllPoints()
			if holder.openUp then list:SetPoint("BOTTOMLEFT", b, "TOPLEFT", 0, 2) else list:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2) end
			list:SetSize(CONTROL_W, #options * 20 + 6)
			for i, option in ipairs(options) do
				local row = list.rows[i]
				if not row then
					row = CreateFrame("Button", nil, list)
					row:SetSize(CONTROL_W - 6, 20)
					row:SetPoint("TOPLEFT", 3, -3 - (i - 1) * 20)
					local hl = row:CreateTexture(nil, "HIGHLIGHT")
					hl:SetAllPoints()
					hl:SetColorTexture(1, 0.82, 0, 0.15)
					row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
					row.text:SetPoint("LEFT", 6, 0)
					list.rows[i] = row
				end
				row.text:SetText(option[2])
				row:SetScript("OnClick", function()
					CloseList()
					Set(option[1])
					Changed()
				end)
				row:Show()
			end
			for i = #options + 1, #list.rows do list.rows[i]:Hide() end
			list:Show()
		end)
		Tooltip(b, tip)
		refreshers[#refreshers + 1] = function() b.label:SetText(TextOf(Get())) end
		holder.button = b
		return holder
	end

	local function PickColor(key)
		local c = db[key]
		local r, g, b = c[1], c[2], c[3]
		local function Apply()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			db[key] = { nr, ng, nb, 1 }
			Changed()
		end
		local function Cancel()
			db[key] = { r, g, b, 1 }
			Changed()
		end
		ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
			swatchFunc = Apply, cancelFunc = Cancel })
	end
	local function AddSwatch(parent, text, key, x, y)
		local b = CreateFrame("Button", nil, parent)
		b:SetSize(18, 18)
		b:SetPoint("TOPLEFT", x, y)
		Edges(b, 1, 1, 1, 0.8)
		local color = b:CreateTexture(nil, "ARTWORK")
		color:SetPoint("TOPLEFT", 2, -2); color:SetPoint("BOTTOMRIGHT", -2, 2)
		local label = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		label:SetPoint("LEFT", b, "RIGHT", 8, 0)
		label:SetText(text)
		b:SetHitRectInsets(0, -(label:GetStringWidth() + 12), 0, 0)
		b:SetScript("OnClick", function() PickColor(key) end)
		refreshers[#refreshers + 1] = function()
			local c = db[key]
			color:SetColorTexture(c[1], c[2], c[3], 1)
		end
		return b
	end

	-- Preview: fake enemy nameplates (bar + name) carrying the same indicator as in the world.
	local function BuildPreview(parent)
		local box = CreateFrame("Frame", nil, parent)
		box:SetPoint("TOPLEFT", 16, -44)
		box:SetPoint("TOPRIGHT", -16, -44)
		box:SetHeight(170)
		-- A dark teal like an outdoor scene, so the preview reads like the world.
		Fill(box, 0.05, 0.13, 0.15, 1)
		local shade = box:CreateTexture(nil, "BACKGROUND", nil, 1)
		shade:SetPoint("BOTTOMLEFT"); shade:SetPoint("BOTTOMRIGHT")
		shade:SetHeight(70)
		shade:SetColorTexture(0.04, 0.09, 0.06, 0.8)
		Edges(box, GOLD[1], GOLD[2], GOLD[3], 0.35)
		local hint = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		hint:SetPoint("BOTTOMRIGHT", -8, 6)
		hint:SetText(T("Preview - /ci test shows it on real nameplates"))
		local samples = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST" }
		local names = { "Grommash", "Thornshot", T("Aetheris (target)"), "Shade", "Lightwell" }
		local plates = {}
		for i, class in ipairs(samples) do
			local bar = CreateFrame("Frame", nil, box)
			bar:SetSize(118, 12)
			bar:SetPoint("BOTTOMLEFT", 50 + (i - 1) * 196, 40)
			local fill = Fill(bar, 0.75, 0.08, 0.08, 1)
			fill:ClearAllPoints()
			fill:SetPoint("TOPLEFT"); fill:SetPoint("BOTTOMLEFT")
			fill:SetWidth(118 * (1 - (i - 1) * 0.15))
			local back = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
			back:SetAllPoints()
			back:SetColorTexture(0.15, 0.02, 0.02, 1)
			Edges(bar, 0, 0, 0, 1)
			local name = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			name:SetPoint("BOTTOM", bar, "TOP", 0, 2)
			name:SetTextColor(1, 0.2, 0.2)
			name:SetText(names[i])
			local f = Indicator.New(bar)
			f:SetFrameLevel(bar:GetFrameLevel() + 5)
			plates[i] = { bar = bar, indicator = f, class = class, target = i == 3 }
		end
		return function()
			for _, p in ipairs(plates) do
				if Indicator.Style(p.indicator, p.class, ClassName(p.class), p.target) then
					Indicator.Place(p.indicator, p.bar)
					p.indicator:SetShown(db.enabled)
				end
			end
		end
	end

	-- A row of class icons: click to mark a class as "shown bigger".
	local function AddClassPicker(parent, text, x, y, tip)
		Label(parent, text, x, y)
		local buttons = {}
		for i, class in ipairs(SAMPLE_CLASSES) do
			local b = CreateFrame("Button", nil, parent)
			b:SetSize(28, 28)
			b:SetPoint("TOPLEFT", x + (i - 1) * 32, y - 16)
			local icon = b:CreateTexture(nil, "ARTWORK")
			icon:SetPoint("TOPLEFT", 2, -2); icon:SetPoint("BOTTOMRIGHT", -2, 2)
			local function Art()
				local texture, l, r, t, b = ClassArt(class)
				icon:SetTexture(texture)
				icon:SetTexCoord(l, r, t, b)
			end
			Art()
			refreshers[#refreshers + 1] = Art
			local edge = CreateFrame("Frame", nil, b)
			edge:SetAllPoints()
			Edges(edge, GOLD[1], GOLD[2], GOLD[3], 1)
			b:SetScript("OnClick", function()
				db.bigClasses[class] = not db.bigClasses[class] or nil
				Changed()
			end)
			Tooltip(b, ClassName(class) .. "\n" .. (tip or ""))
			refreshers[#refreshers + 1] = function()
				local on = db.bigClasses[class] and true or false
				icon:SetDesaturated(not on)
				icon:SetAlpha(on and 1 or 0.45)
				edge:SetShown(on)
			end
			buttons[i] = b
		end
		return buttons
	end

	-- Profile sharing: the active profile as one line ("CCI1:key=value;..."), to copy to a friend
	-- or another PC and back. Values: b1/b0, nNUM, sTEXT, cR,G,B,A (colour), lCLASS,CLASS (list).
	-- Only known settings of the right type are read back.
	local Share = {}
	local function Escape(text) return (tostring(text):gsub("[%%;=:,]", function(c) return string.format("%%%02X", c:byte()) end)) end
	local function Unescape(text) return (text:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) end
	function Share.Encode()
		local keys = {}
		for key in pairs(DEFAULTS) do keys[#keys + 1] = key end
		table.sort(keys)
		local parts = {}
		for _, key in ipairs(keys) do
			local v, kind = db[key], type(DEFAULTS[key])
			local text
			if kind == "boolean" then text = v and "b1" or "b0"
			elseif kind == "number" then text = "n" .. tostring(v)
			elseif kind == "string" then text = "s" .. Escape(v)
			elseif key == "bigClasses" then
				local list = {}
				for class in pairs(v) do list[#list + 1] = class end
				table.sort(list)
				text = "l" .. table.concat(list, ",")
			else
				text = string.format("c%.3f,%.3f,%.3f,%.3f", v[1] or 1, v[2] or 1, v[3] or 1, v[4] or 1)
			end
			parts[#parts + 1] = key .. "=" .. text
		end
		return "CCI1:" .. table.concat(parts, ";")
	end
	-- Returns how many settings were taken, or nil when the text isn't a profile.
	function Share.Decode(text)
		text = (text or ""):match("^%s*(.-)%s*$")
		local body = text:match("^CCI1:(.*)$")
		if not body then return nil end
		local count = 0
		for key, value in body:gmatch("([%w_]+)=([^;]*)") do
			local default = DEFAULTS[key]
			local tag, rest = value:sub(1, 1), value:sub(2)
			if type(default) == "boolean" and tag == "b" then
				db[key] = rest == "1"; count = count + 1
			elseif type(default) == "number" and tag == "n" and tonumber(rest) then
				db[key] = tonumber(rest); count = count + 1
			elseif type(default) == "string" and tag == "s" then
				db[key] = Unescape(rest); count = count + 1
			elseif key == "bigClasses" and tag == "l" then
				local list = {}
				for class in rest:gmatch("[%u]+") do if OWN_COORDS[class] then list[class] = true end end
				db[key] = list; count = count + 1
			elseif type(default) == "table" and tag == "c" then
				local r, g, b, a = rest:match("^([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+)$")
				if r then db[key] = { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }; count = count + 1 end
			end
		end
		return count
	end

	local shareWindow
	local function OpenShare(mode)
		if not shareWindow then
			local s = CreateFrame("Frame", "CSCoder_ClassIndicatorShare", UIParent)
			s:SetSize(520, 260)
			s:SetPoint("CENTER")
			s:SetFrameStrata("FULLSCREEN_DIALOG")
			s:EnableMouse(true)
			s:SetMovable(true)
			s:RegisterForDrag("LeftButton")
			s:SetScript("OnDragStart", s.StartMoving)
			s:SetScript("OnDragStop", s.StopMovingOrSizing)
			Fill(s, 0.09, 0.08, 0.06, 0.98)
			Edges(s, GOLD[1], GOLD[2], GOLD[3], 0.8)
			table.insert(UISpecialFrames, s:GetName())
			s.title = s:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			s.title:SetPoint("TOPLEFT", 16, -14)
			s.hint = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			s.hint:SetPoint("TOPLEFT", 16, -40)
			s.hint:SetWidth(488)
			s.hint:SetJustifyH("LEFT")
			local scroll = CreateFrame("ScrollFrame", nil, s, "UIPanelScrollFrameTemplate")
			scroll:SetPoint("TOPLEFT", 16, -64)
			scroll:SetPoint("BOTTOMRIGHT", -36, 48)
			local box = CreateFrame("EditBox", nil, scroll)
			box:SetMultiLine(true)
			box:SetAutoFocus(false)
			box:SetFontObject("ChatFontSmall")
			box:SetWidth(460)
			box:SetScript("OnEscapePressed", function() s:Hide() end)
			scroll:SetScrollChild(box)
			s.box = box
			local close = Button(s, T("Close"), 100)
			close:SetPoint("BOTTOMRIGHT", -16, 14)
			close:SetScript("OnClick", function() s:Hide() end)
			s.import = Button(s, T("Import"), 100)
			s.import:SetPoint("RIGHT", close, "LEFT", -8, 0)
			s.import:SetScript("OnClick", function()
				local count = Share.Decode(box:GetText())
				if count then
					FillDefaults(db)
					Changed()
					print(string.format("|cffffd200%s|r: " .. T("%d settings imported into \"%s\"."), TITLE, count, Profiles.Current()))
					s:Hide()
				else
					s.hint:SetText(T("|cffff5050That text isn't a Class Indicator profile (it starts with CCI1:).|r"))
				end
			end)
			shareWindow = s
		end
		local s = shareWindow
		if mode == "export" then
			s.title:SetText(T("Export profile"))
			s.hint:SetText(T("Press Ctrl+C to copy this text, then send it to a friend or paste it on another PC."))
			s.box:SetText(Share.Encode())
			s.import:Hide()
		else
			s.title:SetText(T("Import profile"))
			s.hint:SetText(T("Paste a profile text (Ctrl+V) and click Import. It replaces the current profile's settings."))
			s.box:SetText("")
			s.import:Show()
		end
		s:Show()
		s.box:SetFocus()
		if mode == "export" then s.box:HighlightText() end
	end

	-- Profiles tab, laid out like Quest Indicator's (Ace3 style).
	local function BuildProfilesTab(tab)
		local LEFT, TOP, WIDTH = 40, -64, 620
		local function Desc(text, y)
			local fs = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			fs:SetPoint("TOPLEFT", LEFT, y)
			fs:SetWidth(WIDTH)
			fs:SetJustifyH("LEFT")
			fs:SetText(text)
			return fs
		end
		local function Others()
			local list = {}
			for _, name in ipairs(Profiles.Names()) do
				if name ~= Profiles.Current() then list[#list + 1] = { name, name } end
			end
			if #list == 0 then list[1] = { "", T("(no other profile)") } end
			return list
		end
		local function All()
			local list = {}
			for _, name in ipairs(Profiles.Names()) do list[#list + 1] = { name, name } end
			return list
		end
		local function Nothing() return "" end

		Desc(T("Profiles let each character have its own settings."), TOP)

		Desc(T("Put the current profile back to its default settings."), TOP - 24)
		local reset = Button(tab, T("Reset Profile"), 160)
		reset:SetPoint("TOPLEFT", LEFT, TOP - 42)
		reset:SetScript("OnClick", function() ResetSettings(); Changed() end)

		local current = tab:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		current:SetPoint("TOPLEFT", LEFT, TOP - 80)

		Desc(T("Create a new profile by typing a name, or pick an existing one."), TOP - 106)
		Label(tab, T("New"), LEFT, TOP - 126)
		local input = CreateFrame("EditBox", nil, tab, "InputBoxTemplate")
		input:SetSize(200, 22)
		input:SetPoint("TOPLEFT", LEFT + 6, TOP - 144)
		input:SetAutoFocus(false)
		input:SetMaxLetters(32)
		input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		input:SetScript("OnEnterPressed", function(self)
			local name = (self:GetText() or ""):match("^%s*(.-)%s*$")
			self:SetText("")
			self:ClearFocus()
			if name == "" then return end
			Profiles.Use(name)
			Changed()
		end)
		AddDropdown(tab, T("Existing Profiles"), { get = Profiles.Current, set = function(name) Profiles.Use(name) end },
			All, LEFT + 294, TOP - 126)

		Desc(T("Copy the settings of another profile into the current one."), TOP - 186)
		AddDropdown(tab, T("Copy From"), { get = Nothing, set = function(name)
			if name ~= "" then Profiles.CopyFrom(name) end
		end }, Others, LEFT + 4, TOP - 206)

		Desc(T("Delete profiles you no longer use."), TOP - 266)
		AddDropdown(tab, T("Delete a Profile"), { get = Nothing, set = function(name)
			if name == "" then return end
			StaticPopupDialogs.CSCODER_CI_DELETE_PROFILE = {
				text = T("Delete the profile \"%s\"?"), button1 = YES, button2 = NO,
				OnAccept = function(_, data) Profiles.Delete(data); Changed() end,
				timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
			}
			StaticPopup_Show("CSCODER_CI_DELETE_PROFILE", name, nil, name)
		end }, function()
			local list = {}
			for _, option in ipairs(Others()) do if option[1] ~= "Default" then list[#list + 1] = option end end
			if #list == 0 then list[1] = { "", T("(nothing to delete)") } end
			return list
		end, LEFT + 4, TOP - 286)

		Desc(T("Share the current profile: export it as text, or import a text someone sent you."), TOP - 346)
		local export = Button(tab, T("Export profile"), 160)
		export:SetPoint("TOPLEFT", LEFT, TOP - 366)
		export:SetScript("OnClick", function() OpenShare("export") end)
		local import = Button(tab, T("Import profile"), 160)
		import:SetPoint("LEFT", export, "RIGHT", 8, 0)
		import:SetScript("OnClick", function() OpenShare("import") end)

		local function Sync()
			current:SetText(T("Current Profile:") .. " |cffffffff" .. tostring(Profiles.Current()) .. "|r")
		end
		refreshers[#refreshers + 1] = Sync
		tab:HookScript("OnShow", Sync)
	end

	-- Visual picker (like Quest Indicator's icon window): every choice drawn for real with the
	-- current settings, click one to use it.
	-- choices = { { value, label, overrides }, ... }: overrides = the settings that choice sets
	-- (drawn in the tile); isCurrent(choice) says which tile is selected; apply(choice) uses it.
	local picker
	local function OpenPicker(title, choices, isCurrent, apply)
		if not picker then
			local p = CreateFrame("Frame", "CSCoder_ClassIndicatorPicker", window)
			p:SetFrameStrata("FULLSCREEN_DIALOG")
			p:EnableMouse(true)
			p:SetMovable(true)
			p:RegisterForDrag("LeftButton")
			p:SetScript("OnDragStart", p.StartMoving)
			p:SetScript("OnDragStop", p.StopMovingOrSizing)
			Fill(p, 0.08, 0.07, 0.05, 0.98)
			Edges(p, GOLD[1], GOLD[2], GOLD[3], 0.8)
			p.title = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			p.title:SetPoint("TOPLEFT", 16, -14)
			local close = Button(p, "x", 22)
			close:SetPoint("TOPRIGHT", -10, -10)
			close:SetScript("OnClick", function() p:Hide() end)
			table.insert(UISpecialFrames, p:GetName())
			p.tiles = {}
			picker = p
		end
		local p = picker
		local TILE_W, TILE_H, COLS, GAP = 240, 96, 3, 10
		p.title:SetText(title)
		local rows = math.ceil(#choices / COLS)
		p:SetSize(COLS * TILE_W + (COLS + 1) * GAP, 52 + rows * (TILE_H + GAP))
		p:ClearAllPoints()
		p:SetPoint("CENTER", window, "CENTER")

		local function Draw()
			for i, choice in ipairs(choices) do
				local tile = p.tiles[i]
				if not tile then
					tile = CreateFrame("Button", nil, p)
					tile:SetSize(TILE_W, TILE_H)
					tile.bg = Fill(tile, 0.05, 0.13, 0.15, 1)
					local hl = tile:CreateTexture(nil, "HIGHLIGHT")
					hl:SetAllPoints()
					hl:SetColorTexture(1, 0.82, 0, 0.10)
					tile.edge = CreateFrame("Frame", nil, tile)
					tile.edge:SetAllPoints()
					Edges(tile.edge, GOLD[1], GOLD[2], GOLD[3], 1)
					tile.label = tile:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
					tile.label:SetPoint("BOTTOMLEFT", 8, 6)
					tile.indicator = Indicator.New(tile)
					tile.indicator:SetFrameLevel(tile:GetFrameLevel() + 3)
					p.tiles[i] = tile
				end
				tile:ClearAllPoints()
				tile:SetPoint("TOPLEFT", GAP + ((i - 1) % COLS) * (TILE_W + GAP), -44 - math.floor((i - 1) / COLS) * (TILE_H + GAP))
				tile.label:SetText(choice[2])
				tile.edge:SetShown(isCurrent(choice))
				-- Draw with the choice's settings on top of the current ones, then put them back.
				local saved = {}
				for k, v in pairs(choice[3]) do saved[k] = db[k]; db[k] = v end
				local savedShow = db.showText
				db.showText = true
				local f = tile.indicator
				if Indicator.Style(f, "WARRIOR", ClassName("WARRIOR"), false) then
					f:ClearAllPoints()
					local pos = db.textPos
					if pos == "right" then f:SetPoint("LEFT", tile, "LEFT", 24, 8)
					elseif pos == "left" then f:SetPoint("RIGHT", tile, "RIGHT", -24, 8)
					elseif pos == "above" then f:SetPoint("BOTTOM", tile, "BOTTOM", 0, 26)
					else f:SetPoint("TOP", tile, "TOP", 0, -10) end
					f:Show()
				end
				db.showText = savedShow
				for k, v in pairs(saved) do db[k] = v end
				tile:SetScript("OnClick", function()
					apply(choice)
					Changed()
					Draw()
				end)
				tile:Show()
			end
			for i = #choices + 1, #p.tiles do p.tiles[i]:Hide() end
		end
		Draw()
		p:Show()
	end
	-- A small "Pick..." button beside a control.
	local function PickButton(parent, x, y, onClick)
		local b = Button(parent, T("Pick..."), 64)
		b:SetPoint("TOPLEFT", x, y)
		b:SetScript("OnClick", onClick)
		return b
	end

	local function Refresh()
		for _, refresh in ipairs(refreshers) do refresh() end
		if UpdatePreview then UpdatePreview() end
	end

	-- Quick styles: one click sets the look (shape, border, name background, font). Size,
	-- position and the PvP options stay as they are.
	local LOOK = { shape = "round", border = true, borderStyle = "frame", iconSheen = true, innerShade = true, borderMode = "class", borderSize = 2,
		iconShadow = false, textBg = "none", textBgMode = "gold", textFont = "default", textUpper = false,
		textMode = "class", textPos = "below", textShadow = true }
	local function With(base, extra)
		local t = {}
		for k, v in pairs(base) do t[k] = v end
		for k, v in pairs(extra) do t[k] = v end
		return t
	end
	local BADGE = { textBg = "badge", textPos = "right", textMode = "white", textUpper = true, textFont = "serif" }
	local function QuickStyles()
		return {
			{ "classic", T("Classic (round, name below)"), With(LOOK, {}) },
			{ "ring", T("Ring + gold badge"), With(LOOK, With(BADGE, { borderSize = 2 })) },
			{ "glow", T("Rounded + class badge"), With(LOOK, With(BADGE, { shape = "rounded", textBgMode = "class", iconShadow = true })) },
			{ "hex", T("Gold hexagon"), With(LOOK, With(BADGE, { shape = "hex", borderStyle = "metal", borderMode = "gold", borderSize = 3 })) },
			{ "shield", T("Shield + red badge"), With(LOOK, With(BADGE, { shape = "shield", borderStyle = "metal", borderMode = "gold", borderSize = 3, textBgMode = "enemy" })) },
			{ "ribbon", T("Ribbon"), With(LOOK, With(BADGE, { textBg = "ribbon", textBgMode = "class", borderSize = 3 })) },
			{ "minimal", T("Minimal (icon + shadow)"), With(LOOK, With(BADGE, { border = false, iconShadow = true, textBg = "none" })) },
			{ "diamond", T("Gold diamond"), With(LOOK, With(BADGE, { shape = "diamond", borderStyle = "metal", borderMode = "gold", borderSize = 3, textBgMode = "class" })) },
		}
	end

	-- Option lists (built when the window is built, so they follow the language).
	local function Shapes()
		return { { "round", T("Round") }, { "rounded", T("Rounded square") }, { "square", T("Square") },
			{ "hex", T("Hexagon") }, { "diamond", T("Diamond") }, { "shield", T("Shield") } }
	end
	local function BackgroundStyles()
		return { { "none", T("None") }, { "badge", T("Badge (pointed)") }, { "plate", T("Dark plate") }, { "ribbon", T("Ribbon") } }
	end

	local RebuildWindow -- defined after Build (a language change builds the window again)
	local function Build()
		window = CreateFrame("Frame", "CSCoder_ClassIndicatorConfig", UIParent)
		window:SetSize(1060, 760)
		window:SetPoint("CENTER")
		window:SetFrameStrata("DIALOG")
		window:SetMovable(true)
		window:EnableMouse(true)
		window:RegisterForDrag("LeftButton")
		window:SetScript("OnDragStart", window.StartMoving)
		window:SetScript("OnDragStop", window.StopMovingOrSizing)
		window:SetClampedToScreen(true)
		Fill(window, 0.09, 0.08, 0.06, 0.97)
		Edges(window, GOLD[1], GOLD[2], GOLD[3], 0.7)
		table.insert(UISpecialFrames, window:GetName())
		window:SetScript("OnHide", CloseList)

		local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 18, -14)
		title:SetText(TITLE)
		local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")
		if not version or version:find("@") then version = "dev" end
		local ver = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		ver:SetPoint("LEFT", title, "RIGHT", 8, -1)
		ver:SetText(version)
		local close = Button(window, "x", 22)
		close:SetPoint("TOPRIGHT", -10, -10)
		close:SetScript("OnClick", function() window:Hide() end)

		-- Two tabs, like Quest Indicator: Settings (preview + options) and Profiles.
		local settingsTab = CreateFrame("Frame", nil, window)
		settingsTab:SetAllPoints()
		local profilesTab = CreateFrame("Frame", nil, window)
		profilesTab:SetAllPoints()
		local tabButtons = {}
		local function SelectTab(index)
			CloseList()
			settingsTab:SetShown(index == 1)
			profilesTab:SetShown(index == 2)
			for i, b in ipairs(tabButtons) do
				local on = i == index
				b.selected:SetShown(on)
				b.label:SetTextColor(on and 1 or 0.75, on and 0.9 or 0.7, on and 0.6 or 0.6)
			end
		end
		for i, text in ipairs({ T("Settings"), T("Profiles") }) do
			local b = Button(window, text, 110)
			b:SetPoint("TOPLEFT", 330 + (i - 1) * 116, -12)
			b.selected = b:CreateTexture(nil, "ARTWORK", nil, -1)
			b.selected:SetAllPoints()
			b.selected:SetColorTexture(1, 0.82, 0, 0.22)
			b:SetScript("OnClick", function() SelectTab(i) end)
			tabButtons[i] = b
		end
		-- Test mode sits in the title bar: it is an action, not a setting.
		local test = Button(window, T("Test mode"), 140)
		test:SetPoint("TOPLEFT", 572, -12)
		Tooltip(test, T("Puts a sample class on EVERY nameplate around you (mobs, NPCs, allies), so you can adjust it on real nameplates. Same as /ci test."))
		test:SetScript("OnClick", function() SetTestMode(not testMode) end)
		refreshers[#refreshers + 1] = function() test.label:SetText(testMode and T("Test mode: ON") or T("Test mode")) end

		UpdatePreview = BuildPreview(settingsTab)
		BuildProfilesTab(profilesTab)
		SelectTab(1)

		-- One scrolling page of sections (like Quest Indicator), under the fixed preview.
		local scroll = CreateFrame("ScrollFrame", nil, settingsTab, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 16, -224)
		scroll:SetPoint("BOTTOMRIGHT", -38, 34)
		local page = CreateFrame("Frame", nil, scroll)
		page:SetSize(990, 10)
		scroll:SetScrollChild(page)
		page:EnableMouse(true)
		page:SetScript("OnMouseDown", CloseList)
		scroll:HookScript("OnVerticalScroll", CloseList)
		scrollFrame = scroll
		local hint = settingsTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		hint:SetPoint("BOTTOMRIGHT", -40, 12)
		hint:SetText(T("Mouse wheel scrolls the page. Shift + wheel steps a slider. Type a value and press Enter."))

		local A, B = 12, 510 -- the two columns
		local y = 0
		-- A section: its heading across the page and a "Reset section" button for its keys.
		local function Section(name, keys)
			y = y - 14
			local heading = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			heading:SetPoint("TOPLEFT", A, y)
			heading:SetText(name)
			local line = page:CreateTexture(nil, "ARTWORK")
			line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.3)
			line:SetHeight(1)
			line:SetPoint("LEFT", heading, "RIGHT", 10, 0)
			line:SetPoint("RIGHT", page, "RIGHT", -130, 0)
			local reset = Button(page, T("Reset section"), 116)
			reset:SetPoint("RIGHT", page, "TOPRIGHT", -4, y - 9)
			reset:SetScript("OnClick", function()
				for _, key in ipairs(keys) do db[key] = CopyValue(DEFAULTS[key]) end
				Changed()
			end)
			y = y - 34
		end
		local function Row(height) local top = y; y = y - height; return top end

		local function On() return db.enabled end
		local function TextOn() return db.enabled and db.showText end
		local function BorderOn() return db.enabled and db.border end
		local function BgOn() return TextOn() and db.textBg ~= "none" end
		local function HealerOn() return db.enabled and db.healerMark end
		local COLOR_MODES = { { "class", T("Class color") }, { "gold", T("Gold") }, { "enemy", T("Enemy red") }, { "custom", T("Custom color") } }

		-- 1. General.
		Section(T("General"), { "enabled", "friends", "minimap" })
		local top = Row(30)
		AddCheck(page, T("Enable"), "enabled", A, top, T("Show class icons on nameplates."))
		AddCheck(page, T("Minimap button"), "minimap", B, top, T("The CS.Coder button on the minimap (shared by every CS.Coder addon)."))
		top = Row(52)
		Gate(AddCheck(page, T("Also on friendly players"), "friends", A, top, T("Show the icon on allies too (enemies always get it).")), On)
		AddDropdown(page, T("Language"), { get = function() return root.language or "auto" end, set = function(code)
			root.language = code
			Translations.Load()
			RebuildWindow()
		end }, Translations.Choices(), B, top + 4, T("The language of this window. Class names follow the game's language."))

		-- 2. Icon.
		Section(T("Icon"), { "shape", "spellIcons", "size", "alpha", "anchor", "offsetX", "offsetY", "iconShadow" })
		top = Row(52)
		local quick = QuickStyles()
		local quickOptions = {}
		for i, q in ipairs(quick) do quickOptions[i] = { q[1], q[2] } end
		Gate(AddDropdown(page, T("Quick style"), { get = function() return "" end, set = function(key)
			for _, q in ipairs(quick) do if q[1] == key then for k, v in pairs(q[3]) do db[k] = CopyValue(v) end end end
		end }, quickOptions, A, top, T("Sets the whole look in one click (shape, border, name background, font). Size, position and PvP options are kept.")).button, On)
		Gate(PickButton(page, A + 206, top - 16, function()
			OpenPicker(T("Quick style"), quick, function() return false end,
				function(choice) for k, v in pairs(choice[3]) do db[k] = CopyValue(v) end end)
		end), On)
		Gate(AddDropdown(page, T("Shape"), "shape", Shapes(), B, top).button, On)
		Gate(PickButton(page, B + 206, top - 16, function()
			local choices = {}
			for i, o in ipairs(Shapes()) do choices[i] = { o[1], o[2], { shape = o[1] } } end
			OpenPicker(T("Icon shape"), choices, function(c) return db.shape == c[1] end, function(c) db.shape = c[1] end)
		end), On)
		top = Row(48)
		Gate(AddSlider(page, T("Size"), "size", 12, 128, 1, A, top).slider, On)
		Gate(AddSlider(page, T("Opacity"), "alpha", 0.2, 1, 0.05, B, top).slider, On)
		top = Row(52)
		Gate(AddDropdown(page, T("Position on the nameplate"), "anchor", { { "top", T("Top") }, { "bottom", T("Bottom") },
			{ "left", T("Left") }, { "right", T("Right") } }, A, top, T("Which side of the nameplate's health bar the icon sits on.")).button, On)
		top = Row(48)
		Gate(AddSlider(page, T("X (sideways)"), "offsetX", -150, 150, 1, A, top).slider, On)
		Gate(AddSlider(page, T("Y (distance)"), "offsetY", -150, 150, 1, B, top, T("Distance from the health bar. Raise it to clear the name text.")).slider, On)
		top = Row(30)
		Gate(AddCheck(page, T("Shadow under the icon"), "iconShadow", A, top), On)
		Gate(AddCheck(page, T("Spellbook icon art"), "spellIcons", B, top,
			T("Uses the class icons of the spellbook (richer art) instead of the character-creation ones.")), On)

		-- 3. Border.
		Section(T("Border"), { "border", "innerShade", "borderStyle", "borderMode", "borderColor", "borderSize", "iconSheen" })
		top = Row(30)
		Gate(AddCheck(page, T("Show a border"), "border", A, top), On)
		Gate(AddCheck(page, T("Inner shade"), "innerShade", B, top, T("A soft dark edge inside the icon that gives it depth.")), On)
		top = Row(52)
		Gate(AddDropdown(page, T("Border style"), "borderStyle", { { "frame", T("Soft frame") }, { "soft", T("Soft glow") },
			{ "flat", T("Flat color") }, { "metal", T("Metal shine") } }, A, top,
			T("Soft frame: a thin rim with a soft dark outline (the smoothest). Soft glow: the border plus a soft glow of its color. Flat: a plain line. Metal shine: a light-dark-light shine tinted with the border color.")).button, BorderOn)
		Gate(AddDropdown(page, T("Border color"), "borderMode", COLOR_MODES, B, top).button, BorderOn)
		Gate(AddSwatch(page, T("Custom color"), "borderColor", B + 214, top - 18),
			function() return BorderOn() and db.borderMode == "custom" end)
		top = Row(48)
		Gate(AddSlider(page, T("Border thickness"), "borderSize", 1, 8, 1, A, top).slider, BorderOn)
		Gate(AddCheck(page, T("Glass shine"), "iconSheen", B, top - 16, T("A soft glass reflection on the top half of the icon.")), On)

		-- 4. Class name.
		Section(T("Class name"), { "showText", "textUpper", "textFormat", "textFont", "textSize", "textOutline", "textShadow",
			"textMode", "textColor", "textPos", "textX", "textY" })
		top = Row(30)
		Gate(AddCheck(page, T("Show the class name"), "showText", A, top), On)
		Gate(AddCheck(page, T("Capital letters"), "textUpper", B, top), TextOn)
		top = Row(52)
		Gate(AddDropdown(page, T("Text"), "textFormat", { { "full", T("Full name (Hunter)") }, { "short", T("Short (HUN)") } },
			A, top, T("Short names take less room when many players are close together.")).button, TextOn)
		Gate(AddDropdown(page, T("Font"), "textFont", { { "default", T("Game default") }, { "serif", T("Serif (quest text)") },
			{ "friz", "Friz Quadrata" }, { "narrow", "Arial Narrow" }, { "skurri", "Skurri" } }, B, top).button, TextOn)
		top = Row(52)
		Gate(AddSlider(page, T("Text size"), "textSize", 6, 40, 1, A, top).slider, TextOn)
		Gate(AddDropdown(page, T("Outline"), "textOutline", { { "", T("None") }, { "OUTLINE", T("Outline") },
			{ "THICKOUTLINE", T("Thick outline") } }, B, top).button, TextOn)
		Gate(AddCheck(page, T("Shadow"), "textShadow", B + 214, top - 18), TextOn)
		top = Row(52)
		Gate(AddDropdown(page, T("Text color"), "textMode", { { "class", T("Class color") }, { "white", T("White") },
			{ "enemy", T("Enemy red") }, { "custom", T("Custom color") } }, A, top).button, TextOn)
		Gate(AddSwatch(page, T("Custom color"), "textColor", A + 214, top - 18),
			function() return TextOn() and db.textMode == "custom" end)
		Gate(AddDropdown(page, T("Text position"), "textPos", { { "below", T("Below the icon") }, { "above", T("Above the icon") },
			{ "left", T("Left of the icon") }, { "right", T("Right of the icon") } }, B, top).button, TextOn)
		top = Row(48)
		Gate(AddSlider(page, T("Text X"), "textX", -100, 100, 1, A, top).slider, TextOn)
		Gate(AddSlider(page, T("Text Y"), "textY", -100, 100, 1, B, top).slider, TextOn)

		-- 5. Name background.
		Section(T("Name background"), { "textBg", "textBgMode", "textBgColor" })
		top = Row(52)
		Gate(AddDropdown(page, T("Style"), "textBg", BackgroundStyles(), A, top,
			T("Badge: a dark plate with a colored edge and a pointed end, starting behind the icon. Plate: a simple dark box. Ribbon: a colored band with a notched end.")).button, TextOn)
		Gate(PickButton(page, A + 206, top - 16, function()
			local choices = {}
			for i, o in ipairs(BackgroundStyles()) do choices[i] = { o[1], o[2], { textBg = o[1] } } end
			OpenPicker(T("Name background"), choices, function(c) return db.textBg == c[1] end, function(c) db.textBg = c[1] end)
		end), TextOn)
		Gate(AddDropdown(page, T("Edge / ribbon color"), "textBgMode", { { "gold", T("Gold") }, { "class", T("Class color") },
			{ "enemy", T("Enemy red") }, { "dark", T("Dark") }, { "custom", T("Custom color") } }, B, top).button, BgOn)
		Gate(AddSwatch(page, T("Custom color"), "textBgColor", B + 214, top - 18),
			function() return BgOn() and db.textBgMode == "custom" end)

		-- 6. PvP.
		Section(T("PvP"), { "healerMark", "healerOutline", "healerPos", "healerSize", "healerX", "healerY",
			"targetBigger", "targetScale", "targetGlow", "glowColor", "bigClasses", "bigScale" })
		top = Row(30)
		Gate(AddCheck(page, T("Mark healer classes"), "healerMark", A, top,
			T("A green cross on classes that can heal (Priest, Druid, Paladin, Shaman...). Usually the first one to kill.")), On)
		Gate(AddCheck(page, T("Cross outline"), "healerOutline", B, top), HealerOn)
		top = Row(52)
		Gate(AddDropdown(page, T("Cross position"), "healerPos", { { "topright", T("Top right") }, { "topleft", T("Top left") },
			{ "bottomright", T("Bottom right") }, { "bottomleft", T("Bottom left") }, { "center", T("Center") } }, A, top).button, HealerOn)
		Gate(AddSlider(page, T("Cross size"), "healerSize", 0.2, 1, 0.02, B, top).slider, HealerOn)
		top = Row(48)
		Gate(AddSlider(page, T("Cross X"), "healerX", -30, 30, 1, A, top).slider, HealerOn)
		Gate(AddSlider(page, T("Cross Y"), "healerY", -30, 30, 1, B, top).slider, HealerOn)
		top = Row(30)
		Gate(AddCheck(page, T("Bigger icon on your target"), "targetBigger", A, top), On)
		Gate(AddCheck(page, T("Glow on your target"), "targetGlow", B, top,
			T("A pulsing glow around your current target's icon (only the icon, not the name).")), On)
		Gate(AddSwatch(page, T("Glow color"), "glowColor", B + 214, top), function() return db.enabled and db.targetGlow end)
		top = Row(48)
		Gate(AddSlider(page, T("Target size"), "targetScale", 1, 2, 0.05, A, top).slider,
			function() return db.enabled and db.targetBigger end)
		top = Row(56)
		for _, b in ipairs(AddClassPicker(page, T("Classes shown bigger (click to pick)"), A, top, T("Click to show this class bigger."))) do
			Gate(b, On)
		end
		Gate(AddSlider(page, T("Bigger classes size"), "bigScale", 1, 2, 0.05, B, top).slider, On)

		page:SetHeight(-y + 20)

		-- Every change refreshes the controls too (gates follow the switches).
		if not Indicator.changedWrapped then
			Indicator.changedWrapped = true
			local changed = Changed
			Changed = function() changed(); for _, refresh in ipairs(refreshers) do refresh() end end
		end
	end

	-- A new language: build the window again with the new texts (frames can't be destroyed,
	-- the old one is hidden and dropped).
	RebuildWindow = function()
		local shown = window and window:IsShown()
		if window then window:Hide() end
		CloseList()
		if list then list:Hide(); list = nil end
		if picker then picker:Hide(); picker = nil end
		wipe(refreshers)
		window = nil
		UpdatePreview = nil
		Build()
		window:Hide()
		if shown then Refresh(); window:Show() end
	end

	function OpenOptions(toggle)
		if not window then Build(); window:Hide() end -- a new frame starts shown: the first toggle closed it
		if toggle and window:IsShown() then window:Hide() return end
		Refresh()
		window:Show()
	end
end

---------------------------------------------------------------------------------------------
-- Settings entry (under the shared "CS.Coder" parent, like the other CS.Coder addons)
---------------------------------------------------------------------------------------------

local function GetCSCoderParent()
	local parent = _G.CSCoderOptionsParent
	if parent then return parent end
	parent = { name = PARENT_NAME }
	local frame = CreateFrame("Frame")
	frame.name = PARENT_NAME
	local header = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 16, -16)
	header:SetText(PARENT_NAME)
	local sub = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
	sub:SetText(T("Addons by CS.Coder. Pick one in the list on the left to change its settings."))
	parent.frame = frame
	if Settings and Settings.RegisterCanvasLayoutCategory then
		parent.category = Settings.RegisterCanvasLayoutCategory(frame, PARENT_NAME)
		Settings.RegisterAddOnCategory(parent.category)
	end
	_G.CSCoderOptionsParent = parent
	return parent
end

local function BuildLanding()
	local parent = GetCSCoderParent()
	local page = CreateFrame("Frame")
	page.name = SUBTITLE
	local header = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 16, -16)
	header:SetText(TITLE)
	local text = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
	text:SetWidth(560)
	text:SetJustifyH("LEFT")
	text:SetText(T("The official class icon and the class name above enemy players' nameplates. The settings open in their own window, with a live preview."))
	local open = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	open:SetSize(160, 24)
	open:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -16)
	open:SetText(T("Open settings"))
	open:SetScript("OnClick", function()
		if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
		OpenOptions()
	end)
	if Settings and Settings.RegisterCanvasLayoutSubcategory and parent.category then
		Settings.RegisterCanvasLayoutSubcategory(parent.category, page, SUBTITLE)
	end
end

---------------------------------------------------------------------------------------------
-- Events and slash command
---------------------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON then return end
		self:UnregisterEvent("ADDON_LOADED")
		LoadSettings()
		Translations.Load()
		pcall(BuildLanding)
		if CSCoderMinimap then
			CSCoderMinimap.Register({
				name = SUBTITLE,
				open = function() OpenOptions(true) end,
				icon = CLASS_TEXTURE, iconCoords = { 0.0175, 0.2325, 0.0175, 0.2325 }, -- the Warrior shield
				rightClick = function()
					db.enabled = not db.enabled
					print(string.format("|cffffd200%s|r: %s", TITLE, db.enabled and T("on") or T("off")))
					Changed()
				end,
				leftHint = T("Left-click: options"), rightHint = T("Right-click: turn on / off"),
				shown = function() return db.minimap end,
				active = function() return db.enabled end,
				getAngle = function() return root.minimapAngle end,
				setAngle = function(angle) root.minimapAngle = angle end,
			})
		end
		for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
			"UNIT_FACTION", "UNIT_FLAGS", "DUEL_FINISHED", "PLAYER_TARGET_CHANGED", "UI_SCALE_CHANGED", "UPDATE_BATTLEFIELD_SCORE" }) do
			pcall(self.RegisterEvent, self, e)
		end
		-- In a battleground or arena, ask the game for the scoreboard every few seconds (it is
		-- where the hidden classes are read from; UPDATE_BATTLEFIELD_SCORE answers).
		if C_Timer.NewTicker then
			C_Timer.NewTicker(5, function()
				local _, kind = IsInInstance()
				if (kind == "pvp" or kind == "arena") and RequestBattlefieldScoreData then RequestBattlefieldScoreData() end
			end)
		end
	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		Score.Refresh()
		RefreshAll() -- (no full redraw: only plates not shown yet get drawn)
	elseif event == "PLAYER_ENTERING_WORLD" then
		Indicator.version = Indicator.version + 1 -- a full redraw when entering the world
		C_Timer.After(0.1, function() RefreshAll() end)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		UpdateUnit(arg1)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		HidePlate(C_NamePlate.GetNamePlateForUnit(arg1))
	elseif event == "UNIT_FACTION" or event == "UNIT_FLAGS" then
		if arg1 and string.find(arg1, "^nameplate") then UpdateUnit(arg1) end
	else
		-- Entering the world, a duel ending (hostility changes), a new target (plate bars move).
		C_Timer.After(0.1, RefreshAll)
	end
end)

SLASH_CSCODERCLASSINDICATOR1 = "/ci"
SLASH_CSCODERCLASSINDICATOR2 = "/classindicator"
SlashCmdList.CSCODERCLASSINDICATOR = function(msg)
	msg = string.lower(msg or "")
	if msg == "test" then
		SetTestMode(not testMode)
	elseif msg == "why" then
		-- What the game tells this addon about your target (some values are hidden in instances).
		local unit = "target"
		local function Show(label, fn, ...)
			local results = { pcall(fn, ...) }
			local parts = {}
			if not results[1] then
				parts[1] = "ERROR " .. tostring(results[2])
			else
				for i = 2, #results do parts[#parts + 1] = IsSecret(results[i]) and "<secret>" or tostring(results[i]) end
				if #results == 1 then parts[1] = "nil" end
			end
			print("  " .. label .. ": " .. table.concat(parts, ", "))
		end
		print("|cffffd200" .. TITLE .. "|r why (target):")
		Show("IsInInstance", IsInInstance)
		Show("UnitExists", UnitExists, unit)
		Show("UnitIsPlayer", UnitIsPlayer, unit)
		Show("UnitCanAttack", UnitCanAttack, "player", unit)
		Show("UnitIsEnemy", UnitIsEnemy, "player", unit)
		Show("UnitClass", UnitClass, unit)
		if UnitClassBase then Show("UnitClassBase", UnitClassBase, unit) end
		Show("UnitGUID", UnitGUID, unit)
		Show("UnitName", UnitName, unit)
		Show("nameplate", function() local p = C_NamePlate.GetNamePlateForUnit(unit); return p ~= nil, p and p.IsForbidden and p:IsForbidden() end)
		Show("concat secret", function() local _, c = UnitClass(unit); return "x" .. c end)
		if GetNumBattlefieldScores then Show("scores", GetNumBattlefieldScores) end
		if GetBattlefieldScore then Show("score 1", GetBattlefieldScore, 1) end
		Score.Refresh()
		local known = 0
		for _ in pairs(Score.byName) do known = known + 1 end
		Show("scoreboard names known", function() return known end)
		Show("found for target", function() local e = Score.Find(unit); return e and e.class, e and e.faction end)
		Show("wanted", function() return UnitWanted(unit) end)
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		Show("our indicator", function() local f = plate and plate.cciIndicator; return f ~= nil, f and f:IsShown(), f and f.lastClass end)
	elseif msg == "toggle" then
		db.enabled = not db.enabled
		print(string.format("|cffffd200%s|r: %s", TITLE, db.enabled and T("on") or T("off")))
		Changed()
	else
		OpenOptions(true)
	end
end
