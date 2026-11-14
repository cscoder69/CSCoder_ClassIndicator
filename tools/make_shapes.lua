-- Makes the shape masks (128 px, 32-bit uncompressed TGA, white with an antialiased alpha):
-- circle / rsquare = the shape; *_hole = the inverse (transparent inside), used to cut a ring.
-- luajit tools/make_shapes.lua <media dir>
local dir = arg[1] or "media"
local N = 128
local function write(name, alphaAt)
	local f = assert(io.open(dir .. "/" .. name .. ".tga", "wb"))
	f:write(string.char(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, N % 256, math.floor(N / 256), N % 256, math.floor(N / 256), 32, 8))
	local px = {}
	for y = 0, N - 1 do
		for x = 0, N - 1 do
			local a = math.max(0, math.min(1, alphaAt(x + 0.5, y + 0.5)))
			px[#px + 1] = string.char(255, 255, 255, math.floor(a * 255 + 0.5))
		end
	end
	f:write(table.concat(px))
	f:close()
end
local c, r = N / 2, N / 2 - 1
local function circle(x, y) return r - math.sqrt((x - c) ^ 2 + (y - c) ^ 2) + 0.5 end
local R = N * 0.22 -- corner radius
local function rsquare(x, y)
	local dx = math.max(math.abs(x - c) - (r - R), 0)
	local dy = math.max(math.abs(y - c) - (r - R), 0)
	return R - math.sqrt(dx * dx + dy * dy) + 0.5
end
write("circle", circle)
write("circle_hole", function(x, y) return 1 - circle(x, y) end)
write("rsquare", rsquare)
write("rsquare_hole", function(x, y) return 1 - rsquare(x, y) end)
print("ok")
