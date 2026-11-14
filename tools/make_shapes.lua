-- Makes every shape texture (128 px, 32-bit uncompressed TGA) from one signed-distance function
-- per shape (negative inside, in pixels):
--   <mask>.tga        white shape, antialiased alpha (icon mask, plain border ring)
--   <mask>_hole.tga   the inverse (cuts the ring out of the border)
--   <mask>_metal.tga  the shape with a vertical metal shine (light-dark-light), for a metal border
--   glow_<key>.tga    a soft glow; the shape takes the middle 1/1.6 of the texture
--   ribbon_end.tga    the notched end of the class-name ribbon
-- luajit tools/make_shapes.lua <media dir>
local dir = arg[1] or "media"
local N = 128
local function write(name, pixelAt)
	local f = assert(io.open(dir .. "/" .. name .. ".tga", "wb"))
	f:write(string.char(0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, N % 256, math.floor(N / 256), N % 256, math.floor(N / 256), 32, 8))
	local px = {}
	-- TGA rows go bottom-up: y here is measured from the top.
	for row = N - 1, 0, -1 do
		for x = 0, N - 1 do
			local grey, a = pixelAt(x + 0.5, row + 0.5)
			a = math.max(0, math.min(1, a))
			local g = math.floor(math.max(0, math.min(1, grey)) * 255 + 0.5)
			px[#px + 1] = string.char(g, g, g, math.floor(a * 255 + 0.5))
		end
	end
	f:write(table.concat(px))
	f:close()
end

local C = N / 2
-- Convex polygon distance (max of the edges' half-planes): exact inside, close enough outside.
-- Points go clockwise on screen (y down).
local function polygon(points, px, py)
	local d = -math.huge
	for i = 1, #points do
		local a, b = points[i], points[i % #points + 1]
		local ex, ey = b[1] - a[1], b[2] - a[2]
		local len = math.sqrt(ex * ex + ey * ey)
		local nx, ny = ey / len, -ex / len -- outward normal
		d = math.max(d, (px - a[1]) * nx + (py - a[2]) * ny)
	end
	return d
end
local function box(px, py, h, radius)
	local qx, qy = math.abs(px) - (h - radius), math.abs(py) - (h - radius)
	local ox, oy = math.max(qx, 0), math.max(qy, 0)
	return math.sqrt(ox * ox + oy * oy) + math.min(math.max(qx, qy), 0) - radius
end
-- Each shape: sdf(px, py, h) with (px, py) from the centre (y down) and h = half size.
local SHAPES = {
	{ key = "round", mask = "circle", sdf = function(px, py, h) return math.sqrt(px * px + py * py) - h end },
	{ key = "rounded", mask = "rsquare", sdf = function(px, py, h) return box(px, py, h, h * 0.447) end },
	{ key = "square", mask = "square", sdf = function(px, py, h) return box(px, py, h, 0) end },
	{ key = "hex", mask = "hex", sdf = function(px, py, h)
		local pts = {}
		for i = 0, 5 do
			local angle = math.rad(-90 + i * 60) -- pointy top, clockwise on screen
			pts[#pts + 1] = { h * math.cos(angle), h * math.sin(angle) }
		end
		return polygon(pts, px, py)
	end },
	{ key = "diamond", mask = "diamond", sdf = function(px, py, h)
		return polygon({ { 0, -h }, { h, 0 }, { 0, h }, { -h, 0 } }, px, py)
	end },
	{ key = "shield", mask = "shield", sdf = function(px, py, h)
		-- flat top, straight sides down to 30%, then a curve to the bottom point
		local w, top, bend = h * 0.9, -h, -h * 0.3
		local pts = { { -w, top }, { w, top }, { w, bend } }
		for i = 1, 7 do
			pts[#pts + 1] = { w * (1 - (i / 8) ^ 2), bend + (h - bend) * (i / 8) }
		end
		pts[#pts + 1] = { 0, h }
		for i = 7, 1, -1 do
			pts[#pts + 1] = { -w * (1 - (i / 8) ^ 2), bend + (h - bend) * (i / 8) }
		end
		pts[#pts + 1] = { -w, bend }
		return polygon(pts, px, py)
	end },
}

local R = N / 2 - 1         -- masks fill the texture
local GLOW_H = N / 2 / 1.6  -- glows: the shape in the middle
local GLOW_W = N * 0.11
for _, s in ipairs(SHAPES) do
	local function inside(x, y) return 0.5 - s.sdf(x - C, y - C, R) end
	write(s.mask, function(x, y) return 1, inside(x, y) end)
	write(s.mask .. "_hole", function(x, y) return 1, 1 - inside(x, y) end)
	write(s.mask .. "_metal", function(x, y)
		local t = y / N -- light at the top, a dark band, light again lower down
		return 0.55 + 0.45 * math.abs(math.cos(t * math.pi * 1.6)), inside(x, y)
	end)
	write("glow_" .. s.key, function(x, y)
		local d = s.sdf(x - C, y - C, GLOW_H)
		if d < 0 then return 1, math.max(0, 1 + d / 3) end
		return 1, math.exp(-(d / GLOW_W) ^ 2)
	end)
end
-- Ribbon end: a square with a V notch cut into its right side.
write("ribbon_end", function(x, y)
	local notch = N * 0.45 * (1 - math.abs(y - C) / C) -- deepest in the middle
	return 1, (N - notch) - x + 0.5
end)
print("shapes ok")
