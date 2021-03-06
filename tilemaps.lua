Tile = class()

function Tile:init(x, y)
	self.x = x
	self.y = y
end


TileMap = class()

function TileMap:init(width, height, offsetX, offsetY)
	self.width = width
	self.height = height
	self.offsetX = offsetX or 0
	self.offsetY = offsetY or 0
	self.map = {}
end

function TileMap.fromBlob(blob, downscaleFactor)
	local minx = blob.pos.x
	local maxx = blob.pos.x
	local miny = blob.pos.y
	local maxy = blob.pos.y

	for i = 1, #blob.vertices do
		local angle = i * math.pi * 2 / #blob.vertices
		local x = math.cos(angle)*blob.vertices[i] + blob.pos.x
		local y = math.sin(angle)*blob.vertices[i] + blob.pos.y
		minx = math.min(minx, x)
		maxx = math.max(maxx, x)
		miny = math.min(miny, y)
		maxy = math.max(maxy, y)
	end

	minx = math.floor(minx/downscaleFactor)
	maxx = math.ceil(maxx/downscaleFactor)
	miny = math.floor(miny/downscaleFactor)
	maxy = math.ceil(maxy/downscaleFactor)

	local width = maxx - minx
	local height = maxy - miny
	local offsetX =	minx
	local offsetY = miny
	local tile = TileMap.new(width, height, offsetX, offsetY)
	tile.blob = blob

	for x = 1, width do
		for y = 1, height do
			local ox = x + offsetX - blob.pos.x/downscaleFactor
			local oy = y + offsetY - blob.pos.y/downscaleFactor
			local oh = math.sqrt(ox^2 + oy^2)
			local otheta = math.atan2(oy, ox) % (math.pi*2)
			local low = (math.floor((otheta/(math.pi*2)) * #tile.blob.vertices) - 1) % #tile.blob.vertices + 1
			local high = (math.ceil((otheta/(math.pi*2)) * #tile.blob.vertices) - 1) % #tile.blob.vertices + 1
			local d1 = math.abs(((otheta/(math.pi*2)) * #tile.blob.vertices) - low)
			local d2 = math.abs(((otheta/(math.pi*2)) * #tile.blob.vertices) - high)
			local max = 0
			if d1 < d2 then
				max = d1 * blob.vertices[high] + (1-d1)*blob.vertices[low]
			else
				max = d2 * blob.vertices[low] + (1-d2)*blob.vertices[high]
			end

			if oh*downscaleFactor < max then
				tile:add(x, y)
			end
		end
	end
	return tile
end

function TileMap:draw(offset, upscaleFactor)
	--love.graphics.setLineWidth(1)
	--love.graphics.setColor(self.blob.color and self.blob.color/2 or 0, self.blob.color or 0, self.blob.color or 0, 150)
	--love.graphics.rectangle("line", self.offsetX*upscaleFactor + offset.x, self.offsetY*upscaleFactor + offset.y, self.width*upscaleFactor, self.height*upscaleFactor)

	for x, col in pairs(self.map) do
		for y, t in pairs(col) do
			love.graphics.setPointSize(1.5)
			love.graphics.point(t.x * upscaleFactor + offset.x, t.y * upscaleFactor + offset.y)
		end
	end
end

function TileMap:add(x, y)
	if x < 1 or x > self.width or y < 1 or y > self.height then
		return nil
	end
	local t = Tile.new(x + self.offsetX, y + self.offsetY)
	if not self.map[x] then
		self.map[x] = {}
	end
	self.map[x][y] = t
	return t
end

function TileMap:get(x, y)
	if not self.map[x] then
		return nil
	else
		return self.map[x][y]
	end
end


SuperMap = class(TileMap)

function SuperMap:init()
	TileMap.init(self, 0,0,0,0)
	self.tilemaps = {}
end

function SuperMap:addMap(tilemap)
	table.insert(self.tilemaps, tilemap)
	for x, col in pairs(tilemap.map) do
		for y, tile in pairs(col) do
			--If a tile exists, replace current reference to the existing tile.
			--Otherwise, add the current tile to the supermap and retain original reference.
			if self:get(tile.x, tile.y) then
				col[y] = nil
			else
				self:addTile(tile)
			end
		end
	end
end

function SuperMap:addTile(tile)
	if not self.map[tile.x] then
		self.map[tile.x] = {}
	end
	self.map[tile.x][tile.y] = tile
	return tile
end