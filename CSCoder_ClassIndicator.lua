-- CS.Coder - Class Indicator
-- The game's official class icon (and the class name) above enemy players' nameplates, so the
-- class reads at a glance without relying on colour. Anchored to the game's own nameplate frame,
-- so it works with the default UI and with nameplate addons (Plater, Kui, ThreatPlates, ElvUI...).

local ADDON = ...
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
	shape = "round",       -- "round" | "rounded" (rounded square) | "square"
	size = 28,
	alpha = 1,
	anchor = "top",        -- side of the nameplate: top | bottom | left | right
	offsetX = 0,
	offsetY = 14,
	border = true,         -- draw a border
	borderMode = "class",  -- class | enemy | custom
	borderColor = { 1, 0.82, 0, 1 },
	borderSize = 2,
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
	glowColor = { 1, 0.82, 0, 1 },
}
local SETTINGS_VERSION = 1

local db
local function CopyValue(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = v end
	return copy
end
local function LoadSettings()
	CSCoderClassIndicatorDB = type(CSCoderClassIndicatorDB) == "table" and CSCoderClassIndicatorDB or {}
	db = CSCoderClassIndicatorDB
	if db.borderMode == "none" then db.border, db.borderMode = false, "class" end -- old "No border" choice
	db.targetArrows, db.arrowColor, db.clickTarget = nil, nil, nil -- removed options
	for key, value in pairs(DEFAULTS) do
		if type(db[key]) ~= type(value) then db[key] = CopyValue(value) end
	end
	db.version = SETTINGS_VERSION
end
local function ResetSettings()
	for key, value in pairs(DEFAULTS) do db[key] = CopyValue(value) end
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
-- Classes that can heal (no spec info needed: the class alone is the warning).
local HEALER_CLASSES = { PRIEST = true, DRUID = true, PALADIN = true, SHAMAN = true, MONK = true, EVOKER = true }
-- Preview and test mode: the nine classes of the classic game, in this order.
local SAMPLE_CLASSES = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST", "WARLOCK", "PALADIN", "DRUID", "SHAMAN" }

local function ClassCoords(class)
	local coords = (CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]) or OWN_COORDS[class]
	return coords
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

local Indicator = {}

-- Shapes: the icon's mask and the matching "hole" that cuts the border into a ring (so a
-- lower opacity never shows the border through the icon). Square uses four edge lines.
local SHAPES = {
	round = { mask = MEDIA .. "circle", hole = MEDIA .. "circle_hole" },
	rounded = { mask = MEDIA .. "rsquare", hole = MEDIA .. "rsquare_hole" },
	square = {},
}

function Indicator.New(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(28, 28)
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.ring = f:CreateTexture(nil, "BORDER")
	f.ring:SetAllPoints()
	f.edges = {}
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
	-- The text on its own layer above, so the nameplate addon never covers it.
	f.textHolder = CreateFrame("Frame", nil, f)
	f.textHolder:SetAllPoints()
	f.textHolder:SetFrameLevel(f:GetFrameLevel() + 5)
	f.text = f.textHolder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
	f.glowPulse = CreateFrame("Frame", nil, f)
	f.glowPulse:Hide()
	f.glowPulse:SetScript("OnUpdate", function(self, elapsed)
		self.t = (self.t or 0) + elapsed
		f.glow:SetAlpha(0.55 + 0.45 * math.abs(math.sin(self.t * 3)))
	end)
	f:Hide()
	return f
end

local function ModeColor(mode, custom, class)
	if mode == "class" then return ClassColor(class) end
	if mode == "enemy" then return ENEMY_RED[1], ENEMY_RED[2], ENEMY_RED[3] end
	if mode == "white" then return 1, 1, 1 end
	return custom[1], custom[2], custom[3]
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
	local info = SHAPES[shape]
	local border = db.border and db.borderSize or 0
	f.icon:ClearAllPoints()
	f.icon:SetPoint("TOPLEFT", border, -border)
	f.icon:SetPoint("BOTTOMRIGHT", -border, border)

	local l, r, t, b = coords[1], coords[2], coords[3], coords[4]
	if shape ~= "square" and not f.canMask then
		-- No mask support on this client: the game's own round class icons.
		f.icon:SetTexture(CLASS_CIRCLES)
		f.icon:SetTexCoord(l, r, t, b)
	else
		-- Cut the thin frame of the character-creation icon off.
		local cutX, cutY = (r - l) * 0.07, (b - t) * 0.07
		f.icon:SetTexture(CLASS_TEXTURE)
		f.icon:SetTexCoord(l + cutX, r - cutX, t + cutY, b - cutY)
	end
	if f.canMask then
		f.iconMask:SetTexture(info.mask or WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	end

	local cr, cg, cb = ModeColor(db.borderMode, db.borderColor, class)
	local ring = border > 0 and shape ~= "square" and f.canMask
	if ring then
		f.ring:SetTexture(info.mask)
		f.ring:SetVertexColor(cr, cg, cb, 1)
		f.holeMask:SetTexture(info.hole, "CLAMPTOWHITE", "CLAMPTOWHITE")
	end
	f.ring:SetShown(ring)
	local square = border > 0 and (shape == "square" or not f.canMask)
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
		else healer:SetPoint("CENTER", f, string.upper(pos), inX * s * 0.2 + db.healerX, inY * s * 0.2 + db.healerY) end
		local p = healer.parts
		p[1]:SetSize(s + 4, bar + 4); p[2]:SetSize(bar + 4, s + 4)
		p[3]:SetSize(s, bar); p[4]:SetSize(bar, s)
		p[1]:SetShown(db.healerOutline); p[2]:SetShown(db.healerOutline)
		healer:Show()
	else
		healer:Hide()
	end

	local text = f.text
	if db.showText and name then
		if db.textFormat == "short" then name = SHORT_NAMES[class] or name end
		local outline = db.textOutline
		if not pcall(text.SetFont, text, STANDARD_TEXT_FONT, db.textSize, outline) then
			text:SetFontObject("GameFontNormal")
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
		if pos == "above" then text:SetPoint("BOTTOM", f, "TOP", x, 2 + y)
		elseif pos == "left" then text:SetPoint("RIGHT", f, "LEFT", -3 + x, y)
		elseif pos == "right" then text:SetPoint("LEFT", f, "RIGHT", 3 + x, y)
		else text:SetPoint("TOP", f, "BOTTOM", x, -2 + y) end
		text:Show()
	else
		text:Hide()
	end

	-- Target glow: same shape as the icon, the texture is 1.6x the icon (make_shapes.lua).
	if isTarget and db.targetGlow then
		local c = db.glowColor
		local glowShape = shape == "square" and "square" or (f.canMask and shape or "round")
		f.glow:SetTexture(MEDIA .. "glow_" .. glowShape)
		f.glow:SetSize(size * 1.6, size * 1.6)
		f.glow:SetVertexColor(c[1], c[2], c[3], 1)
		f.glow:Show()
		f.glowPulse:Show()
	else
		f.glow:Hide()
		f.glowPulse:Hide()
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

local function UnitWanted(unit)
	if testMode then return not UnitIsUnit(unit, "player") end
	if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return false end
	if UnitCanAttack("player", unit) or UnitIsEnemy("player", unit) then return true end
	return db.friends
end

local function HidePlate(plate)
	if plate and plate.cciIndicator then plate.cciIndicator:Hide() end
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
		name, class = UnitClass(unit)
		if IsSecret(class) or IsSecret(name) or not class then HidePlate(plate) return end
	end

	local f = plate.cciIndicator
	if not f then
		f = Indicator.New(plate)
		plate.cciIndicator = f
	end
	pcall(function()
		f:SetFrameStrata(plate:GetFrameStrata())
		f:SetFrameLevel(plate:GetFrameLevel() + 50)
	end)
	if Indicator.Style(f, class, name, UnitIsUnit(unit, "target")) then
		Indicator.Place(f, PlateTarget(plate))
		f:Show()
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
	RefreshAll()
	if UpdatePreview then UpdatePreview() end
end

local function SetTestMode(on)
	testMode = on
	print(string.format("|cffffd200%s|r: test mode %s", TITLE,
		on and "|cff00ff00ON|r (every nameplate gets a sample class)" or "|cffff4040OFF|r"))
	Changed()
end

---------------------------------------------------------------------------------------------
-- Options window (own window, dark and gold, live preview)
---------------------------------------------------------------------------------------------

local OpenOptions
do
	local GOLD = { 1, 0.82, 0 }
	local window, refreshers, list = nil, {}, nil
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
			s:SetValue(math.max(low, math.min(high, db[key] + delta * step)))
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
		local function TextOf(value)
			for _, option in ipairs(options) do if option[1] == value then return option[2] end end
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
			list:ClearAllPoints()
			list:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
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
					db[key] = option[1]
					CloseList()
					Changed()
				end)
				row:Show()
			end
			for i = #options + 1, #list.rows do list.rows[i]:Hide() end
			list:Show()
		end)
		Tooltip(b, tip)
		refreshers[#refreshers + 1] = function() b.label:SetText(TextOf(db[key])) end
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
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
				swatchFunc = Apply, cancelFunc = Cancel })
		else
			ColorPickerFrame.func, ColorPickerFrame.cancelFunc = Apply, Cancel
			ColorPickerFrame.hasOpacity = false
			ColorPickerFrame.previousValues = { r, g, b }
			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame:Hide()
			ColorPickerFrame:Show()
		end
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
		hint:SetText("Preview - /ci test shows it on real nameplates")
		local samples = { "WARRIOR", "HUNTER", "MAGE", "ROGUE", "PRIEST" }
		local names = { "Grommash", "Thornshot", "Aetheris (target)", "Shade", "Lightwell" }
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
			local c = ClassCoords(class)
			local cx, cy = (c[2] - c[1]) * 0.07, (c[4] - c[3]) * 0.07
			icon:SetTexture(CLASS_TEXTURE)
			icon:SetTexCoord(c[1] + cx, c[2] - cx, c[3] + cy, c[4] - cy)
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

	local function Refresh()
		for _, refresh in ipairs(refreshers) do refresh() end
		if UpdatePreview then UpdatePreview() end
	end

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

		UpdatePreview = BuildPreview(window)

		local page = CreateFrame("Frame", nil, window)
		page:SetPoint("TOPLEFT", 0, -224)
		page:SetPoint("BOTTOMRIGHT")
		page:EnableMouse(true)
		page:SetScript("OnMouseDown", CloseList)

		local function On() return db.enabled end
		local function TextOn() return db.enabled and db.showText end
		local function BorderOn() return db.enabled and db.border end

		-- Column 1: Display + Icon.
		local y = 0
		Heading(page, "Display", COL1, y)
		AddCheck(page, "Enable", "enabled", COL1, y - 24, "Show class icons on nameplates.")
		Gate(AddCheck(page, "Also on friendly players", "friends", COL1, y - 50, "Show the icon on allies too (enemies always get it)."), On)
		local test = Button(page, "Test mode", 120)
		test:SetPoint("TOPLEFT", COL1 + 200, y - 22)
		Tooltip(test, "Puts a sample class on EVERY nameplate around you (mobs, NPCs, allies), so you can adjust it on real nameplates. Same as /ci test.")
		test:SetScript("OnClick", function() SetTestMode(not testMode) end)
		refreshers[#refreshers + 1] = function() test.label:SetText(testMode and "Test mode: ON" or "Test mode") end

		y = y - 86
		Heading(page, "Icon", COL1, y)
		Gate(AddDropdown(page, "Shape", "shape", { { "round", "Round" }, { "rounded", "Rounded square" }, { "square", "Square" } }, COL1, y - 22).button, On)
		Gate(AddSlider(page, "Size", "size", 12, 64, 1, COL1, y - 70).slider, On)
		Gate(AddDropdown(page, "Position on the nameplate", "anchor", { { "top", "Top" }, { "bottom", "Bottom" },
			{ "left", "Left" }, { "right", "Right" } }, COL1, y - 114,
			"Which side of the nameplate's health bar the icon sits on.").button, On)
		Gate(AddSlider(page, "X (sideways)", "offsetX", -150, 150, 1, COL1, y - 162).slider, On)
		Gate(AddSlider(page, "Y (distance)", "offsetY", -150, 150, 1, COL1, y - 206,
			"Distance from the health bar. Raise it to clear the name text.").slider, On)
		Gate(AddSlider(page, "Opacity", "alpha", 0.2, 1, 0.05, COL1, y - 250).slider, On)

		-- Column 2: Class name.
		y = 0
		Heading(page, "Class name", COL2, y)
		Gate(AddCheck(page, "Show the class name", "showText", COL2, y - 24), On)
		Gate(AddCheck(page, "Capital letters", "textUpper", COL2 + 180, y - 24), TextOn)
		Gate(AddDropdown(page, "Text", "textFormat", { { "full", "Full name (Hunter)" }, { "short", "Short (HUN)" } },
			COL2, y - 50, "Short names take less room when many players are close together.").button, TextOn)
		Gate(AddDropdown(page, "Text position", "textPos", { { "below", "Below the icon" }, { "above", "Above the icon" },
			{ "left", "Left of the icon" }, { "right", "Right of the icon" } }, COL2, y - 98).button, TextOn)
		Gate(AddSlider(page, "Text X", "textX", -100, 100, 1, COL2, y - 146).slider, TextOn)
		Gate(AddSlider(page, "Text Y", "textY", -100, 100, 1, COL2, y - 190).slider, TextOn)
		Gate(AddSlider(page, "Text size", "textSize", 6, 24, 1, COL2, y - 234).slider, TextOn)
		Gate(AddDropdown(page, "Text color", "textMode", { { "class", "Class color" }, { "white", "White" },
			{ "enemy", "Enemy red" }, { "custom", "Custom color" } }, COL2, y - 278).button, TextOn)
		Gate(AddSwatch(page, "Custom color", "textColor", COL2 + 214, y - 296),
			function() return TextOn() and db.textMode == "custom" end)
		Gate(AddDropdown(page, "Outline", "textOutline", { { "", "None" }, { "OUTLINE", "Outline" },
			{ "THICKOUTLINE", "Thick outline" } }, COL2, y - 326).button, TextOn)
		Gate(AddCheck(page, "Shadow", "textShadow", COL2 + 214, y - 344), TextOn)

		-- Healer cross: where and how big (the switch and outline are in PvP).
		local function HealerOn() return db.enabled and db.healerMark end
		Heading(page, "Healer cross", COL2, y - 384)
		Gate(AddDropdown(page, "Position", "healerPos", { { "topright", "Top right" }, { "topleft", "Top left" },
			{ "bottomright", "Bottom right" }, { "bottomleft", "Bottom left" }, { "center", "Center" } }, COL2, y - 406).button, HealerOn)
		Gate(AddSlider(page, "Size", "healerSize", 0.2, 1, 0.02, COL2 + 214, y - 406, nil, 70).slider, HealerOn)
		Gate(AddSlider(page, "X", "healerX", -30, 30, 1, COL2, y - 454, nil, 110).slider, HealerOn)
		Gate(AddSlider(page, "Y", "healerY", -30, 30, 1, COL2 + 180, y - 454, nil, 110).slider, HealerOn)

		-- Column 3: Border + PvP.
		y = 0
		Heading(page, "Border", COL3, y)
		Gate(AddCheck(page, "Show a border", "border", COL3, y - 24), On)
		Gate(AddDropdown(page, "Border color", "borderMode", { { "class", "Class color" }, { "enemy", "Enemy red" },
			{ "custom", "Custom color" } }, COL3, y - 50).button, BorderOn)
		Gate(AddSwatch(page, "Custom color", "borderColor", COL3 + 214, y - 68),
			function() return BorderOn() and db.borderMode == "custom" end)
		Gate(AddSlider(page, "Border thickness", "borderSize", 1, 8, 1, COL3, y - 98).slider, BorderOn)

		y = y - 160
		Heading(page, "PvP", COL3, y)
		Gate(AddCheck(page, "Mark healer classes", "healerMark", COL3, y - 24,
			"A green cross on classes that can heal (Priest, Druid, Paladin, Shaman...). Usually the first one to kill."), On)
		Gate(AddCheck(page, "Cross outline", "healerOutline", COL3 + 190, y - 24), function() return db.enabled and db.healerMark end)
		Gate(AddCheck(page, "Bigger icon on your target", "targetBigger", COL3, y - 50), On)
		Gate(AddSlider(page, "Target size", "targetScale", 1, 2, 0.05, COL3, y - 74).slider,
			function() return db.enabled and db.targetBigger end)
		for _, b in ipairs(AddClassPicker(page, "Classes shown bigger (click to pick)", COL3, y - 124,
			"Click to show this class bigger.")) do
			Gate(b, On)
		end
		Gate(AddSlider(page, "Bigger classes size", "bigScale", 1, 2, 0.05, COL3, y - 176).slider, On)
		Gate(AddCheck(page, "Glow on your target", "targetGlow", COL3, y - 226,
			"A pulsing glow around your current target's icon (only the icon, not the name)."), On)
		Gate(AddSwatch(page, "Glow color", "glowColor", COL3 + 214, y - 226),
			function() return db.enabled and db.targetGlow end)

		local reset = Button(page, "Reset all", 110)
		reset:SetPoint("BOTTOMLEFT", COL1, 16)
		reset:SetScript("OnClick", function() ResetSettings(); Refresh(); Changed() end)
		local hint = page:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		hint:SetPoint("BOTTOMRIGHT", -18, 20)
		hint:SetText("Mouse wheel on a slider steps it. Type a value and press Enter.")

		-- Every change refreshes the controls too (gates follow the switches).
		local changed = Changed
		Changed = function() changed(); for _, refresh in ipairs(refreshers) do refresh() end end
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
	sub:SetText("Addons by CS.Coder. Pick one in the list on the left to change its settings.")
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
	text:SetText("The official class icon and the class name above enemy players' nameplates. The settings open in their own window, with a live preview.")
	local open = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
	open:SetSize(160, 24)
	open:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -16)
	open:SetText("Open settings")
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
		pcall(BuildLanding)
		for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
			"UNIT_FACTION", "UNIT_FLAGS", "DUEL_FINISHED", "PLAYER_TARGET_CHANGED" }) do
			pcall(self.RegisterEvent, self, e)
		end
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
	elseif msg == "toggle" then
		db.enabled = not db.enabled
		print(string.format("|cffffd200%s|r: %s", TITLE, db.enabled and "on" or "off"))
		Changed()
	else
		OpenOptions(true)
	end
end
