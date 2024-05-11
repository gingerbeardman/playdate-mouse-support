import "CoreLibs/sprites"

local gfx = playdate.graphics

local backgroundImage = gfx.image.new(400,240)
gfx.pushContext(backgroundImage)
	gfx.setDitherPattern(0.5)
	gfx.fillRect(0,0,400,240)
gfx.popContext()

gfx.sprite.setBackgroundDrawingCallback(
	function( x, y, width, height )
		backgroundImage:draw( 0, 0 )
	end
)

local image = gfx.image.new("pointer")
local sprite = gfx.sprite.new(image)
sprite:moveTo(100, 100)
sprite:add()

function playdate.serialMessageReceived(message, manual)
	local params = {}
	
	local n1,n2 = message:match("(-?%d+),(-?%d+)")
	if n1 == nil or n2 == nil then return end
	
	local x = tonumber(n1)
	local y = tonumber(n2)
	
	sprite:moveTo(200+x,120+y)
end

function playdate.update()
	gfx.sprite.update()
end
