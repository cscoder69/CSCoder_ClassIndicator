-- Checks the translations: every T("...") text of the main file must exist in every language
-- of Locales.lua (missing), and every translated text must still be used (unused).
-- luajit tools/check_translations.lua <addon dir>   -> exits with 1 when something is wrong.
local dir = arg[1] or "."
local f = assert(io.open(dir .. "/CSCoder_ClassIndicator.lua", "rb"))
local source = f:read("*a")
f:close()

-- The texts used: T("...") with Lua escapes (\" and \\).
local used, count = {}, 0
for literal in source:gmatch('T%("(.-[^\\])"%)') do
	local text = literal:gsub('\\"', '"'):gsub("\\\\", "\\")
	if not used[text] then used[text] = true; count = count + 1 end
end

local ns = {}
assert(loadfile(dir .. "/Locales.lua"))("CSCoder_ClassIndicator", ns)
local problems = 0
local codes = {}
for code in pairs(ns.LOCALES) do codes[#codes + 1] = code end
table.sort(codes)
for _, code in ipairs(codes) do
	local lang = ns.LOCALES[code]
	local missing, unused = {}, {}
	for text in pairs(used) do if not lang[text] then missing[#missing + 1] = text end end
	for text in pairs(lang) do if not used[text] then unused[#unused + 1] = text end end
	table.sort(missing)
	table.sort(unused)
	for _, text in ipairs(missing) do print(code, "MISSING", text) end
	for _, text in ipairs(unused) do print(code, "UNUSED", text) end
	-- Same %s / %d placeholders as the English text.
	for text, translated in pairs(lang) do
		local a = select(2, text:gsub("%%[sd]", ""))
		local b = select(2, translated:gsub("%%[sd]", ""))
		if a ~= b then print(code, "PLACEHOLDERS", text); problems = problems + 1 end
	end
	problems = problems + #missing + #unused
	print(code, #missing == 0 and #unused == 0 and "complete" or (#missing .. " missing, " .. #unused .. " unused"))
end
print("texts used:", count, "languages:", #codes, "problems:", problems)
if problems > 0 then os.exit(1) end
