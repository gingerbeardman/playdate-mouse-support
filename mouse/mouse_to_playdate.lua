-- Forwards mouse events to Playdate serial connection
--
-- Save this in a file named something like `mouse_to_playdate.lua` in the Hammerspoon config folder (`~/.hammerspoon`),
-- then import it from your Hammerspoon `init.lua` file:
--
-- ```lua
-- mouse_to_playdate = dofile('mouse_to_playdate.lua')
-- ```

local hsSerial = hs.serial
local pdPort = nil
local maxCanvas = nil
local drawing = false

hs.hotkey.bind({}, "F13", function()
	local serialPorts = hsSerial.availablePortNames()
	local pdPortName = nil
	for p=1,#serialPorts do
		if string.find(serialPorts[p], "usbmodemPD.") then
			print(serialPorts[p])
			pdPortName = serialPorts[p]
		end
	end
	print(hs.inspect(pdPortName))

	pdPort = hsSerial.newFromName(pdPortName)
	pdPort:open()
	if pdPort:isOpen() then
		-- 300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400
		pdPort:baudRate(115200)
		pdPort:parity("none")
		pdPort:dataBits(8)
		pdPort:dtr(true)
		pdPort:sendData("msg mouse on\n")
		pdPort:sendData("msg 0,0\n")
	else
		print("-- mouse_fwd", "port not open")
		hs.osascript.applescript("beep")
	end

	local startingMousePosition = hs.mouse.absolutePosition()
	local max = hs.screen.mainScreen():fullFrame()

	if drawing == true then
		maxCanvas:hide()
	else
		drawing = true
	end

	maxCanvas = hs.canvas.new{x=max.x, y=max.y, h=max.h, w=max.w}
	maxCanvas:appendElements({
	{
	type = "rectangle",
	action = "fill",
	frame = { x=startingMousePosition.x-200, y=startingMousePosition.y-120, w=400, h=240 },
		fillColor = { red = 0.647, green = 0.640, blue = 0.610, alpha = 1 },
		}
	})
	maxCanvas:clickActivating(false)
	maxCanvas:canvasMouseEvents(true, true, false, true)
	maxCanvas:mouseCallback(function(_, event, id, x, y)
		local currentMousePosition = hs.mouse.absolutePosition()
		if event == "mouseMove" then
			local dx = (currentMousePosition.x-startingMousePosition.x)
			local dy = (currentMousePosition.y-startingMousePosition.y)
			if pdPort:isOpen() and (odx ~= dx or ody ~= dy) then
				local mouse_event = string.format("msg %d,%d\n", dx//1,dy//1)
				pdPort:sendData(mouse_event)
			else
				print("-- mouse_fwd", "port not open")
			end
			odx = dx
			ody = dy
		elseif event == "mouseUp" then
			maxCanvas:hide()
			pdPort:sendData("msg mouse off\n")
			pdPort:close()
		end
	end)
	maxCanvas:level("dragging")
	maxCanvas:show()
	if pdPort:isOpen() == false then
		maxCanvas:hide()
	end
end)
