-- oeed's Ultimate Door Lock
-- http://www.computercraft.info/forums2/index.php?/topic/17614-ultimate-door-lock-pda-opened-doors/

tArgs = {...}

if OneOS then
	--running under OneOS
	OneOS.ToolBarColour = colours.white
	OneOS.ToolBarTextColour = colours.grey
end

local _w, _h = term.getSize()

local round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

InterfaceElements = {}

Drawing = {
	
	Screen = {
		Width = _w,
		Height = _h
	},

	DrawCharacters = function (x, y, characters, textColour,bgColour)
		Drawing.WriteStringToBuffer(x, y, characters, textColour, bgColour)
	end,
	
	DrawBlankArea = function (x, y, w, h, colour)
		Drawing.DrawArea (x, y, w, h, " ", 1, colour)
	end,

	DrawArea = function (x, y, w, h, character, textColour, bgColour)
		--width must be greater than 1, other wise we get a stack overflow
		if w < 0 then
			w = w * -1
		elseif w == 0 then
			w = 1
		end

		for ix = 1, w do
			local currX = x + ix - 1
			for iy = 1, h do
				local currY = y + iy - 1
				Drawing.WriteToBuffer(currX, currY, character, textColour, bgColour)
			end
		end
	end,

	DrawImage = function(_x,_y,tImage, w, h)
		if tImage then
			for y = 1, h do
				if not tImage[y] then
					break
				end
				for x = 1, w do
					if not tImage[y][x] then
						break
					end
					local bgColour = tImage[y][x]
		            local textColour = tImage.textcol[y][x] or colours.white
		            local char = tImage.text[y][x]
		            Drawing.WriteToBuffer(x+_x-1, y+_y-1, char, textColour, bgColour)
				end
			end
		elseif w and h then
			Drawing.DrawBlankArea(x, y, w, h, colours.green)
		end
	end,
	--using .nft
	LoadImage = function(path)
		local image = {
			text = {},
			textcol = {}
		}
		local fs = fs
		if OneOS then
			fs = OneOS.FS
		end
		if fs.exists(path) then
			local _open = io.open
			if OneOS then
				_open = OneOS.IO.open
			end
	        local file = _open(path, "r")
	        local sLine = file:read()
	        local num = 1
	        while sLine do  
	                table.insert(image, num, {})
	                table.insert(image.text, num, {})
	                table.insert(image.textcol, num, {})
	                                            
	                --As we're no longer 1-1, we keep track of what index to write to
	                local writeIndex = 1
	                --Tells us if we've hit a 30 or 31 (BG and FG respectively)- next char specifies the curr colour
	                local bgNext, fgNext = false, false
	                --The current background and foreground colours
	                local currBG, currFG = nil,nil
	                for i=1,#sLine do
	                        local nextChar = string.sub(sLine, i, i)
	                        if nextChar:byte() == 30 then
                                bgNext = true
	                        elseif nextChar:byte() == 31 then
                                fgNext = true
	                        elseif bgNext then
                                currBG = Drawing.GetColour(nextChar)
                                bgNext = false
	                        elseif fgNext then
                                currFG = Drawing.GetColour(nextChar)
                                fgNext = false
	                        else
                                if nextChar ~= " " and currFG == nil then
                                       currFG = colours.white
                                end
                                image[num][writeIndex] = currBG
                                image.textcol[num][writeIndex] = currFG
                                image.text[num][writeIndex] = nextChar
                                writeIndex = writeIndex + 1
	                        end
	                end
	                num = num+1
	                sLine = file:read()
	        end
	        file:close()
		end
	 	return image
	end,

	DrawCharactersCenter = function(x, y, w, h, characters, textColour,bgColour)
		w = w or Drawing.Screen.Width
		h = h or Drawing.Screen.Height
		x = x or 0
		y = y or 0
		x = math.ceil((w - #characters) / 2) + x
		y = math.floor(h / 2) + y

		Drawing.DrawCharacters(x, y, characters, textColour, bgColour)
	end,

	GetColour = function(hex)
		if hex == ' ' then
			return colours.transparent
		end
	    local value = tonumber(hex, 16)
	    if not value then return nil end
	    value = math.pow(2,value)
	    return value
	end,

	Clear = function (_colour)
		_colour = _colour or colours.black
		Drawing.ClearBuffer()
		Drawing.DrawBlankArea(1, 1, Drawing.Screen.Width, Drawing.Screen.Height, _colour)
	end,

	Buffer = {},
	BackBuffer = {},

	DrawBuffer = function()
		for y,row in pairs(Drawing.Buffer) do
			for x,pixel in pairs(row) do
				local shouldDraw = true
				local hasBackBuffer = true
				if Drawing.BackBuffer[y] == nil or Drawing.BackBuffer[y][x] == nil or #Drawing.BackBuffer[y][x] ~= 3 then
					hasBackBuffer = false
				end
				if hasBackBuffer and Drawing.BackBuffer[y][x][1] == Drawing.Buffer[y][x][1] and Drawing.BackBuffer[y][x][2] == Drawing.Buffer[y][x][2] and Drawing.BackBuffer[y][x][3] == Drawing.Buffer[y][x][3] then
					shouldDraw = false
				end
				if shouldDraw then
					term.setBackgroundColour(pixel[3])
					term.setTextColour(pixel[2])
					term.setCursorPos(x, y)
					term.write(pixel[1])
				end
			end
		end
		Drawing.BackBuffer = Drawing.Buffer
		Drawing.Buffer = {}
		term.setCursorPos(1,1)
	end,

	ClearBuffer = function()
		Drawing.Buffer = {}
	end,

	WriteStringToBuffer = function (x, y, characters, textColour,bgColour)
		for i = 1, #characters do
   			local character = characters:sub(i,i)
   			Drawing.WriteToBuffer(x + i - 1, y, character, textColour, bgColour)
		end
	end,

	WriteToBuffer = function(x, y, character, textColour,bgColour)
		x = round(x)
		y = round(y)
		if bgColour == colours.transparent then
			Drawing.Buffer[y] = Drawing.Buffer[y] or {}
			Drawing.Buffer[y][x] = Drawing.Buffer[y][x] or {"", colours.white, colours.black}
			Drawing.Buffer[y][x][1] = character
			Drawing.Buffer[y][x][2] = textColour
		else
			Drawing.Buffer[y] = Drawing.Buffer[y] or {}
			Drawing.Buffer[y][x] = {character, textColour, bgColour}
		end
	end,
}

Current = {
	Document = nil,
	TextInput = nil,
	CursorPos = {1,1},
	CursorColour = colours.black,
	Selection = {8, 36},
	Window = nil,
	HeaderText = '',
	StatusText = '',
	StatusColour = colours.grey,
	StatusScreen = true,
	ButtonOne = nil,
	ButtonTwo = nil,
	Locked = false,
	Page = '',
	PageControls = {}
}

isRunning = true

Events = {}

Button = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	BackgroundColour = colours.lightGrey,
	TextColour = colours.white,
	ActiveBackgroundColour = colours.lightGrey,
	Text = "",
	Parent = nil,
	_Click = nil,
	Toggle = nil,

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)
		local bg = self.BackgroundColour
		local tc = self.TextColour
		if type(bg) == 'function' then
			bg = bg()
		end

		if self.Toggle then
			tc = colours.white
			bg = self.ActiveBackgroundColour
		end

		local pos = GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, bg)
		Drawing.DrawCharactersCenter(pos.X, pos.Y, self.Width, self.Height, self.Text, tc, bg)
	end,

	Initialise = function(self, x, y, width, height, backgroundColour, parent, click, text, textColour, toggle, activeBackgroundColour)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.white
		new.ActiveBackgroundColour = activeBackgroundColour or colours.lightBlue
		new.Parent = parent
		new._Click = click
		new.Toggle = toggle
		return new
	end,

	Click = function(self, side, x, y)
		if self._Click then
			if self:_Click(side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = not self.Toggle
				Draw()
			end
			return true
		else
			return false
		end
	end
}

Label = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	BackgroundColour = colours.lightGrey,
	TextColour = colours.white,
	Text = "",
	Parent = nil,

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)
		local bg = self.BackgroundColour
		local tc = self.TextColour

		if self.Toggle then
			tc = UIColours.MenuBarActive
			bg = self.ActiveBackgroundColour
		end

		local pos = GetAbsolutePosition(self)
		Drawing.DrawCharacters(pos.X, pos.Y, self.Text, self.TextColour, self.BackgroundColour)
	end,

	Initialise = function(self, x, y, text, textColour, backgroundColour, parent)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or colours.white
		new.TextColour = textColour or colours.black
		new.Parent = parent
		return new
	end,

	Click = function(self, side, x, y)
		return false
	end
}

TextBox = {
	X = 1,
	Y = 1,
	Width = 0,
	Height = 0,
	BackgroundColour = colours.lightGrey,
	TextColour = colours.black,
	Parent = nil,
	TextInput = nil,
	Placeholder = '',

	AbsolutePosition = function(self)
		return self.Parent:AbsolutePosition()
	end,

	Draw = function(self)		
		local pos = GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
		local text = self.TextInput.Value
		if #tostring(text) > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			if Current.TextInput == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.Width-2, pos.Y}
			end
		else
			if Current.TextInput == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.TextInput.CursorPos, pos.Y}
			end
		end
		
		if #tostring(text) == 0 then
			Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Placeholder, colours.lightGrey, self.BackgroundColour)
		else
			Drawing.DrawCharacters(pos.X + 1, pos.Y, text, self.TextColour, self.BackgroundColour)
		end

		term.setCursorBlink(true)
		
		Current.CursorColour = self.TextColour
	end,

	Initialise = function(self, x, y, width, height, parent, text, backgroundColour, textColour, done, numerical)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.TextInput = TextInput:Initialise(text or '', function(key)
			if done then
				done(key)
			end
			Draw()
		end, numerical)
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.black
		new.Parent = parent
		return new
	end,

	Click = function(self, side, x, y)
		Current.Input = self.TextInput
		self:Draw()
	end
}

TextInput = {
	Value = "",
	Change = nil,
	CursorPos = nil,
	Numerical = false,
	IsDocument = nil,

	Initialise = function(self, value, change, numerical, isDocument)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Value = tostring(value)
		new.Change = change
		new.CursorPos = #tostring(value)
		new.Numerical = numerical
		new.IsDocument = isDocument or false
		return new
	end,

	Insert = function(self, str)
		if self.Numerical then
			str = tostring(tonumber(str))
		end

		local selection = OrderSelection()

		if self.IsDocument and selection then
			self.Value = string.sub(self.Value, 1, selection[1]-1) .. str .. string.sub( self.Value, selection[2]+2)
			self.CursorPos = selection[1]
			Current.Selection = nil
		else
			local _, newLineAdjust = string.gsub(self.Value:sub(1, self.CursorPos), '\n','')

			self.Value = string.sub(self.Value, 1, self.CursorPos + newLineAdjust) .. str .. string.sub( self.Value, self.CursorPos + 1  + newLineAdjust)
			self.CursorPos = self.CursorPos + 1
		end
		
		self.Change(key)
	end,

	Extract = function(self, remove)
		local selection = OrderSelection()
		if self.IsDocument and selection then
			local _, newLineAdjust = string.gsub(self.Value:sub(selection[1], selection[2]), '\n','')
			local str = string.sub(self.Value, selection[1], selection[2]+1+newLineAdjust)
			if remove then
				self.Value = string.sub(self.Value, 1, selection[1]-1) .. string.sub( self.Value, selection[2]+2+newLineAdjust)
				self.CursorPos = selection[1] - 1
				Current.Selection = nil
			end
			return str
		end
	end,

	Char = function(self, char)
		if char == 'nil' then
			return
		end
		self:Insert(char)
	end,

	Key = function(self, key)
		if key == keys.enter then
			if self.IsDocument then
				self.Value = string.sub(self.Value, 1, self.CursorPos ) .. '\n' .. string.sub( self.Value, self.CursorPos + 1 )
				self.CursorPos = self.CursorPos + 1
			end
			self.Change(key)		
		elseif key == keys.left then
			-- Left
			if self.CursorPos > 0 then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos, self.CursorPos))
				self.CursorPos = self.CursorPos - 1 - colShift
				self.Change(key)
			end
			
		elseif key == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Value) then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos+1, self.CursorPos+1))
				self.CursorPos = self.CursorPos + 1 + colShift
				self.Change(key)
			end
		
		elseif key == keys.backspace then
			-- Backspace
			if self.IsDocument and Current.Selection then
				self:Extract(true)
				self.Change(key)
			elseif self.CursorPos > 0 then
				local colShift = FindColours(string.sub( self.Value, self.CursorPos, self.CursorPos))
				local _, newLineAdjust = string.gsub(self.Value:sub(1, self.CursorPos), '\n','')

				self.Value = string.sub( self.Value, 1, self.CursorPos - 1 - colShift + newLineAdjust) .. string.sub( self.Value, self.CursorPos + 1 - colShift + newLineAdjust)
				self.CursorPos = self.CursorPos - 1 - colShift
				self.Change(key)
			end
		elseif key == keys.home then
			-- Home
			self.CursorPos = 0
			self.Change(key)
		elseif key == keys.delete then
			if self.IsDocument and Current.Selection then
				self:Extract(true)
				self.Change(key)
			elseif self.CursorPos < string.len(self.Value) then
				self.Value = string.sub( self.Value, 1, self.CursorPos ) .. string.sub( self.Value, self.CursorPos + 2 )				
				self.Change(key)
			end
		elseif key == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Value)
			self.Change(key)
		elseif key == keys.up and self.IsDocument then
			-- Up
			if Current.Document.CursorPos then
				local page = Current.Document.Pages[Current.Document.CursorPos.Page]
				self.CursorPos = page:GetCursorPosFromPoint(Current.Document.CursorPos.Collum + page.MarginX, Current.Document.CursorPos.Line - page.MarginY - 1 + Current.Document.ScrollBar.Scroll, true)
				self.Change(key)
			end
		elseif key == keys.down and self.IsDocument then
			-- Down
			if Current.Document.CursorPos then
				local page = Current.Document.Pages[Current.Document.CursorPos.Page]
				self.CursorPos = page:GetCursorPosFromPoint(Current.Document.CursorPos.Collum + page.MarginX, Current.Document.CursorPos.Line - page.MarginY + 1 + Current.Document.ScrollBar.Scroll, true)
				self.Change(key)
			end
		end
	end
}

local Capitalise = function(str)
	return str:sub(1, 1):upper() .. str:sub(2, -1)
end


local getNames = peripheral.getNames or function()
    local tResults = {}
    for n,sSide in ipairs( rs.getSides() ) do
        if peripheral.isPresent( sSide ) then
            table.insert( tResults, sSide )
            local isWireless = false
            if not pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
                isWireless = true
            end     
            if peripheral.getType( sSide ) == "modem" and not isWireless then
                local tRemote = peripheral.call( sSide, "getNamesRemote" )
                for n,sName in ipairs( tRemote ) do
                    table.insert( tResults, sName )
                end
            end
        end
    end
    return tResults
end

Peripheral = {
    GetPeripheral = function(_type)
        for i, p in ipairs(Peripheral.GetPeripherals()) do
            if p.Type == _type then
                return p
            end
        end
    end,

    Call = function(type, ...)
        local tArgs = {...}
        local p = Peripheral.GetPeripheral(type)
        peripheral.call(p.Side, unpack(tArgs))
    end,

    GetPeripherals = function(filterType)
        local peripherals = {}
        for i, side in ipairs(getNames()) do
            local name = peripheral.getType(side):gsub("^%l", string.upper)
            local code = string.upper(side:sub(1,1))
            if side:find('_') then
                code = side:sub(side:find('_')+1)
            end

            local dupe = false
            for i, v in ipairs(peripherals) do
                if v[1] == name .. ' ' .. code then
                    dupe = true
                end
            end

            if not dupe then
                local _type = peripheral.getType(side)
                local isWireless = false
                if _type == 'modem' then
                    if not pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
                        isWireless = true
                    end     
                    if isWireless then
                        _type = 'wireless_modem'
                        name = 'W '..name
                    end
                end
                if not filterType or _type == filterType then
                    table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Fullname = name .. ' ('..side:sub(1, 1):upper() .. side:sub(2, -1)..')', Side = side, Type = _type, Wireless = isWireless})
                end
            end
        end
        return peripherals
    end,

    PresentNamed = function(name)
        return peripheral.isPresent(name)
    end,

    CallType = function(type, ...)
        local tArgs = {...}
        local p = Peripheral.GetPeripheral(type)
        return peripheral.call(p.Side, unpack(tArgs))
    end,

    CallNamed = function(name, ...)
        local tArgs = {...}
        return peripheral.call(name, unpack(tArgs))
    end
}

Wireless = {
	Channels = {
		UltimateDoorlockPing = 4210,
		UltimateDoorlockRequest = 4211,
		UltimateDoorlockRequestReply = 4212,
	},

	isOpen = function(channel)
		return Peripheral.CallType('wireless_modem', 'isOpen', channel)
	end,

	Open = function(channel)
		if not Wireless.isOpen(channel) then
			Peripheral.CallType('wireless_modem', 'open', channel)
		end
	end,

	close = function(channel)
		Peripheral.CallType('wireless_modem', 'close', channel)
	end,

	closeAll = function()
		Peripheral.CallType('wireless_modem', 'closeAll')
	end,

	transmit = function(channel, replyChannel, message)
		Peripheral.CallType('wireless_modem', 'transmit', channel, replyChannel, textutils.serialize(message))
	end,

	Present = function()
		if Peripheral.GetPeripheral('wireless_modem') == nil then
			return false
		else
			return true
		end
	end,

	FormatMessage = function(message, messageID, destinationID)
		return {
			content = textutils.serialize(message),
			senderID = os.getComputerID(),
			senderName = os.getComputerLabel(),
			channel = channel,
			replyChannel = reply,
			messageID = messageID or math.random(10000),
			destinationID = destinationID
		}
	end,

	Timeout = function(func, time)
		time = time or 1
		parallel.waitForAny(func, function()
			sleep(time)
			--log('Timeout!'..time)
		end)
	end,

	RecieveMessage = function(_channel, messageID, timeout)
		open(_channel)
		local done = false
		local event, side, channel, replyChannel, message = nil
		Timeout(function()
			while not done do
				event, side, channel, replyChannel, message = os.pullEvent('modem_message')
				if channel ~= _channel then
					event, side, channel, replyChannel, message = nil
				else
					message = textutils.unserialize(message)
					message.content = textutils.unserialize(message.content)
					if messageID and messageID ~= message.messageID or (message.destinationID ~= nil and message.destinationID ~= os.getComputerID()) then
						event, side, channel, replyChannel, message = nil
					else
						done = true
					end
				end
			end
		end,
		timeout)
		return event, side, channel, replyChannel, message
	end,

	Initialise = function()
		if Wireless.Present() then
			for i, c in pairs(Wireless.Channels) do
				Wireless.Open(c)
			end
		end
	end,

	HandleMessage = function(event, side, channel, replyChannel, message, distance)
		message = textutils.unserialize(message)
		message.content = textutils.unserialize(message.content)

		if channel == Wireless.Channels.Ping then
			if message.content == 'Ping!' then
				SendMessage(replyChannel, 'Pong!', nil, message.messageID)
			end
		elseif message.destinationID ~= nil and message.destinationID ~= os.getComputerID() then
		elseif Wireless.Responder then
			Wireless.Responder(event, side, channel, replyChannel, message, distance)
		end
	end,

	SendMessage = function(channel, message, reply, messageID, destinationID)
		reply = reply or channel + 1
		Wireless.Open(channel)
		Wireless.Open(reply)
		local _message = Wireless.FormatMessage(message, messageID, destinationID)
		Wireless.transmit(channel, reply, _message)
		return _message
	end,

	Ping = function()
		local message = SendMessage(Channels.Ping, 'Ping!', Channels.PingReply)
		RecieveMessage(Channels.PingReply, message.messageID)
	end
}

function GetAbsolutePosition(object)
	local obj = object
	local i = 0
	local x = 1
	local y = 1
	while true do
		x = x + obj.X - 1
		y = y + obj.Y - 1

		if not obj.Parent then
			return {X = x, Y = y}
		end

		obj = obj.Parent

		if i > 32 then
			return {X = 1, Y = 1}
		end

		i = i + 1
	end

end

function Draw()
	Drawing.Clear(colours.white)

	if Current.StatusScreen then
		Drawing.DrawCharactersCenter(1, -2, nil, nil, Current.HeaderText, colours.blue, colours.white)
		Drawing.DrawCharactersCenter(1, -1, nil, nil, 'by oeed', colours.lightGrey, colours.white)
		Drawing.DrawCharactersCenter(1, 1, nil, nil, Current.StatusText, Current.StatusColour, colours.white)
	end

	if Current.ButtonOne then
		Current.ButtonOne:Draw()
	end

	if Current.ButtonTwo then
		Current.ButtonTwo:Draw()
	end

	for i, v in ipairs(Current.PageControls) do
		v:Draw()
	end

	Drawing.DrawBuffer()

	if Current.TextInput and Current.CursorPos and not Current.Menu and not(Current.Window and Current.Document and Current.TextInput == Current.Document.TextInput) and Current.CursorPos[2] > 1 then
		term.setCursorPos(Current.CursorPos[1], Current.CursorPos[2])
		term.setCursorBlink(true)
		term.setTextColour(Current.CursorColour)
	else
		term.setCursorBlink(false)
	end
end
MainDraw = Draw

function GenerateFingerprint()
    local str = ""
    for _ = 1, 256 do
        local char = math.random(32, 126)
        --if char == 96 then char = math.random(32, 95) end
        str = str .. string.char(char)
    end
    return str
end

function MakeFingerprint()
	local h = fs.open('.fingerprint', 'w')
	if h then
		h.write(GenerateFingerprint())
	end
	h.close()
	Current.Fingerprint = str
end

local drawTimer = nil
function SetText(header, status, colour, isReset)
	if header then
		Current.HeaderText = header
	end
	if status then
		Current.StatusText = status
	end
	if colour then
		Current.StatusColour = colour
	end
	Draw()
	if not isReset then
		statusResetTimer = os.startTimer(2)
	end
end

function ResetStatus()
	if pocket then
		if Current.Locked then
			SetText('Ultimate Door Lock', 'Add Wireless Modem to PDA', colours.red, true)
		else
			SetText('Ultimate Door Lock', 'Ready', colours.grey, true)
		end
	else
		if Current.Locked then
			SetText('Ultimate Door Lock', ' Attach a Wireless Modem then reboot', colours.red, true)
		else
			SetText('Ultimate Door Lock', 'Ready', colours.grey, true)
		end
	end
end

function ResetPage()
	Wireless.Responder = function()end
	pingTimer = nil
	Current.PageControls = nil
	Current.StatusScreen = false
	Current.ButtonOne = nil
	Current.ButtonTwo = nil
	Current.PageControls = {}
	CloseDoor()
end

function PocketInitialise()
	Current.ButtonOne = Button:Initialise(Drawing.Screen.Width - 6, Drawing.Screen.Height - 1, nil, nil, nil, nil, Quit, 'Quit', colours.black)
	if not Wireless.Present() then
		Current.Locked = true
		ResetStatus()
		return
	end
	Wireless.Initialise()
	ResetStatus()
	if fs.exists('.fingerprint') then
		local h = fs.open('.fingerprint', 'r')
		if h then
			Current.Fingerprint = h.readAll()
		else
			MakeFingerprint()
		end
		h.close()
	else
		MakeFingerprint()
	end

	Wireless.Responder = function(event, side, channel, replyChannel, message, distance)
		if channel == Wireless.Channels.UltimateDoorlockPing then
			Wireless.SendMessage(Wireless.Channels.UltimateDoorlockRequest, Current.Fingerprint, Wireless.Channels.UltimateDoorlockRequestReply, nil, message.senderID)
		elseif channel == Wireless.Channels.UltimateDoorlockRequestReply then
			if message.content == true then
				SetText(nil, 'Opening Door', colours.green)
			else
				SetText(nil, ' Access Denied', colours.red)
			end
		end
	end
end

function FingerprintIsOnWhitelist(fingerprint)
	if Current.Settings.Whitelist then
		for i, f in ipairs(Current.Settings.Whitelist) do
			if f == fingerprint then
				return true
			end
		end
	end
	return false
end

function SaveSettings()
	Current.Settings = Current.Settings or {}
	local h = fs.open('.settings', 'w')
	if h then
		h.write(textutils.serialize(Current.Settings))
	end
	h.close()	
end

local closeDoorTimer = nil
function OpenDoor()
	if Current.Settings and Current.Settings.RedstoneSide then
		SetText(nil, 'Opening Door', colours.green)
		redstone.setOutput(Current.Settings.RedstoneSide, true)
		closeDoorTimer = os.startTimer(0.6)
	end
end

function CloseDoor()
	if Current.Settings and Current.Settings.RedstoneSide then
		if redstone.getOutput(Current.Settings.RedstoneSide) then
			SetText(nil, 'Closing Door', colours.orange)
			redstone.setOutput(Current.Settings.RedstoneSide, false)
		end
	end
end

DefaultSettings = {
	Whitelist = {},
	RedstoneSide = 'back',
	Distance = 10
}

function RegisterPDA(event, drive)
	if disk.hasData(drive) then
		local _fs = fs
		if OneOS then
			_fs = OneOS.FS
		end
		local path = disk.getMountPath(drive)
		local addStartup = true
		if _fs.exists(path..'/System/') then
			path = path..'/System/'
			addStartup = false
		end
		local fingerprint = nil
		if _fs.exists(path..'/.fingerprint') then
			local h = _fs.open(path..'/.fingerprint', 'r')
			if h then
				local str = h.readAll()
				if #str == 256 then
					fingerprint = str
				end
			end
			h.close()
		end
		if not fingerprint then
			fingerprint = GenerateFingerprint()
			local h = _fs.open(path..'/.fingerprint', 'w')
			h.write(fingerprint)
			h.close()
			if addStartup then
				local h = fs.open(shell.getRunningProgram(), 'r')
				local startup = h.readAll()
				h.close()
				local h = _fs.open(path..'/startup', 'w')
				h.write(startup)
				h.close()
			end
		end
		if not FingerprintIsOnWhitelist(fingerprint) then
			table.insert(Current.Settings.Whitelist, fingerprint)
			SaveSettings()
		end
		disk.eject(drive)
		SetText(nil, 'Registered Pocket Computer', colours.green)
	end
end

function HostSetup()
	ResetPage()
	Current.Page = 'HostSetup'
	Current.ButtonTwo = Button:Initialise(Drawing.Screen.Width - 6, Drawing.Screen.Height - 1, nil, nil, nil, nil, HostStatusPage, 'Save', colours.black)
	if not Current.Settings then
		Current.Settings = DefaultSettings
	end

	local sideButtons = {}
	local function resetSideToggle(self)
		for i, v in ipairs(sideButtons) do
			if v.Toggle ~= nil then
				v.Toggle = false
			end
		end
		Current.Settings.RedstoneSide = self.Text:lower()
		SaveSettings()
	end

	table.insert(Current.PageControls, Label:Initialise(2, 2, 'Redstone Side'))
	sideButtons = {
		Button:Initialise(2, 4, nil, nil, nil, nil, resetSideToggle, 'Back', colours.black, false, colours.green),
		Button:Initialise(9, 4, nil, nil, nil, nil, resetSideToggle, 'Front', colours.black, false, colours.green),
		Button:Initialise(2, 6, nil, nil, nil, nil, resetSideToggle, 'Left', colours.black, false, colours.green),
		Button:Initialise(9, 6, nil, nil, nil, nil, resetSideToggle, 'Right', colours.black, false, colours.green),
		Button:Initialise(2, 8, nil, nil, nil, nil, resetSideToggle, 'Top', colours.black, false, colours.green),
		Button:Initialise(8, 8, nil, nil, nil, nil, resetSideToggle, 'Bottom', colours.black, false, colours.green)
	}
  	for i, v in ipairs(sideButtons) do
  		if v.Text:lower() == Current.Settings.RedstoneSide then
  			v.Toggle = true
  		end
  		table.insert(Current.PageControls, v)
  	end

	local distanceButtons = {}
	local function resetDistanceToggle(self)
		for i, v in ipairs(distanceButtons) do
			if v.Toggle ~= nil then
				v.Toggle = false
			end
		end
  		if self.Text == 'Small' then
  			Current.Settings.Distance = 5
  		elseif self.Text == 'Normal' then
  			Current.Settings.Distance = 10
  		elseif self.Text == 'Far' then
  			Current.Settings.Distance = 15
  		end
		SaveSettings()
	end

	table.insert(Current.PageControls, Label:Initialise(23, 2, 'Opening Distance'))
	distanceButtons = {
		Button:Initialise(23, 4, nil, nil, nil, nil, resetDistanceToggle, 'Small', colours.black, false, colours.green),
		Button:Initialise(31, 4, nil, nil, nil, nil, resetDistanceToggle, 'Normal', colours.black, false, colours.green),
		Button:Initialise(40, 4, nil, nil, nil, nil, resetDistanceToggle, 'Far', colours.black, false, colours.green)
	}
  	for i, v in ipairs(distanceButtons) do
  		if v.Text == 'Small' and Current.Settings.Distance == 5 then
  			v.Toggle = true
  		elseif v.Text == 'Normal' and Current.Settings.Distance == 10 then
  			v.Toggle = true
  		elseif v.Text == 'Far' and Current.Settings.Distance == 15 then
  			v.Toggle = true
  		end
  		table.insert(Current.PageControls, v)
  	end

	table.insert(Current.PageControls, Label:Initialise(2, 10, 'Registered PDAs: '..#Current.Settings.Whitelist))
	table.insert(Current.PageControls, Button:Initialise(2, 12, nil, nil, nil, nil, function()Current.Settings.Whitelist = {}HostSetup()end, 'Unregister All', colours.black))

  	
  	table.insert(Current.PageControls, Label:Initialise(23, 6, 'Help', colours.black))
  	local helpLines = {
  		Label:Initialise(23, 8, 'To register a new PDA simply', colours.black),
  		Label:Initialise(23, 9, 'place a Disk Drive next to', colours.black),
  		Label:Initialise(23, 10, 'the computer, then put the', colours.black),
  		Label:Initialise(23, 11, 'PDA in the Drive, it will', colours.black),
  		Label:Initialise(23, 12, 'register automatically. If', colours.black),
  		Label:Initialise(23, 13, 'it worked it will eject.', colours.black),
  		Label:Initialise(23, 15, 'Make sure you hide this', colours.red),
  		Label:Initialise(23, 16, 'computer away from the', colours.red),
  		Label:Initialise(23, 17, 'door! (other people)', colours.red)
  	}
  	for i, v in ipairs(helpLines) do
  		table.insert(Current.PageControls, v)
  	end


	table.insert(Current.PageControls, Button:Initialise(2, 14, nil, nil, nil, nil, function()
	  	for i = 1, 6 do
	  		helpLines[i].TextColour = colours.green
	  	end
	end, 'Register New PDA', colours.black))

end

function HostStatusPage()
	ResetPage()
	Current.Page = 'HostStatus'
	Current.StatusScreen = true
	Current.ButtonOne = Button:Initialise(Drawing.Screen.Width - 6, Drawing.Screen.Height - 1, nil, nil, nil, nil, Quit, 'Quit', colours.black)
	Current.ButtonTwo = Button:Initialise(2, Drawing.Screen.Height - 1, nil, nil, nil, nil, HostSetup, 'Settings/Help', colours.black)

	Wireless.Responder = function(event, side, channel, replyChannel, message, distance)
		if channel == Wireless.Channels.UltimateDoorlockRequest and distance < Current.Settings.Distance then
			if FingerprintIsOnWhitelist(message.content) then
				OpenDoor()
				Wireless.SendMessage(Wireless.Channels.UltimateDoorlockRequestReply, true)
			else
				Wireless.SendMessage(Wireless.Channels.UltimateDoorlockRequestReply, false)
			end
		end
	end

	PingPocketComputers()
end

function HostInitialise()
	if not Wireless.Present() then
		Current.Locked = true
		Current.ButtonOne = Button:Initialise(Drawing.Screen.Width - 6, Drawing.Screen.Height - 1, nil, nil, nil, nil, Quit, 'Quit', colours.black)
		Current.ButtonTwo = Button:Initialise(2, Drawing.Screen.Height - 1, nil, nil, nil, nil, function()os.reboot()end, 'Reboot', colours.black)
		ResetStatus()
		return
	end
	Wireless.Initialise()
	ResetStatus()
	if fs.exists('.settings') then
		local h = fs.open('.settings', 'r')
		if h then
			Current.Settings = textutils.unserialize(h.readAll())
		end
		h.close()
		HostStatusPage()		
	else
		HostSetup()
	end
	if OneOS then
		OneOS.CanClose = function()
			CloseDoor()
			return true
		end
	end
end

local pingTimer = nil
function PingPocketComputers()
	Wireless.SendMessage(Wireless.Channels.UltimateDoorlockPing, 'Ping!', Wireless.Channels.UltimateDoorlockRequest)
	pingTimer = os.startTimer(0.5)
end

function Initialise(arg)
	EventRegister('mouse_click', TryClick)
	EventRegister('mouse_drag', function(event, side, x, y)TryClick(event, side, x, y, true)end)
	EventRegister('mouse_scroll', Scroll)
	EventRegister('key', HandleKey)
	EventRegister('char', HandleKey)
	EventRegister('timer', Timer)
	EventRegister('terminate', function(event) if Close() then error( "Terminated", 0 ) end end)
	EventRegister('modem_message', Wireless.HandleMessage)
	EventRegister('disk', RegisterPDA)

	if OneOS then
		OneOS.RequestRunAtStartup()
	end

	if pocket then
		PocketInitialise()
	else
		HostInitialise()
	end


	Draw()

	EventHandler()
end

function Timer(event, timer)
	if timer == pingTimer then
		PingPocketComputers()
	elseif timer == closeDoorTimer then
		CloseDoor()
	elseif timer == statusResetTimer then
		ResetStatus()
	end
end

local ignoreNextChar = false
function HandleKey(...)
	local args = {...}
	local event = args[1]
	local keychar = args[2]
	--[[
																							--Mac left command character
	if event == 'key' and keychar == keys.leftCtrl or keychar == keys.rightCtrl or keychar == 219 then
		isControlPushed = true
		controlPushedTimer = os.startTimer(0.5)
	elseif isControlPushed then
		if event == 'key' then
			if CheckKeyboardShortcut(keychar) then
				isControlPushed = false
				ignoreNextChar = true
			end
		end
	elseif ignoreNextChar then
		ignoreNextChar = false
	elseif Current.TextInput then
		if event == 'char' then
			Current.TextInput:Char(keychar)
		elseif event == 'key' then
			Current.TextInput:Key(keychar)
		end
	end
	]]--
end

--[[
	Check if the given object falls under the click coordinates
]]--
function CheckClick(object, x, y)
	if object.X <= x and object.Y <= y and object.X + object.Width > x and object.Y + object.Height > y then
		return true
	end
end

--[[
	Attempt to clicka given object
]]--
function DoClick(object, side, x, y, drag)
	local obj = GetAbsolutePosition(object)
	obj.Width = object.Width
	obj.Height = object.Height
	if object and CheckClick(obj, x, y) then
		return object:Click(side, x - object.X + 1, y - object.Y + 1, drag)
	end	
end

--[[
	Try to click at the given coordinates
]]--
function TryClick(event, side, x, y, drag)
	if Current.ButtonOne then
		if DoClick(Current.ButtonOne, side, x, y, drag) then
			Draw()
			return
		end
	end

	if Current.ButtonTwo then
		if DoClick(Current.ButtonTwo, side, x, y, drag) then
			Draw()
			return
		end
	end

	for i, v in ipairs(Current.PageControls) do
		if DoClick(v, side, x, y, drag) then
			Draw()
			return
		end
	end

	Draw()
end

function Scroll(event, direction, x, y)
	if Current.Window and Current.Window.OpenButton then
		Current.Document.Scroll = Current.Document.Scroll + direction
		if Current.Window.Scroll < 0 then
			Current.Window.Scroll = 0
		elseif Current.Window.Scroll > Current.Window.MaxScroll then
			Current.Window.Scroll = Current.Window.MaxScroll
		end
		Draw()
	elseif Current.ScrollBar then
		if Current.ScrollBar:DoScroll(direction*2) then
			Draw()
		end
	end
end

--[[
	Registers functions to run on certain events
]]--
function EventRegister(event, func)
	if not Events[event] then
		Events[event] = {}
	end

	table.insert(Events[event], func)
end

--[[
	The main loop event handler, runs registered event functinos
]]--
function EventHandler()
	while isRunning do
		local event, arg1, arg2, arg3, arg4, arg5, arg6 = os.pullEventRaw()
		if Events[event] then
			for i, e in ipairs(Events[event]) do
				e(event, arg1, arg2, arg3, arg4, arg5, arg6)
			end
		end
	end
end

function Quit()
	isRunning = false
	term.setCursorPos(1,1)
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.clear()
	if OneOS then
		OneOS.Close()
	end
end

if not term.current then -- if not 1.6
	print('Because it requires pocket computers, Ultimate Door Lock requires ComputerCraft 1.6. Please update to 1.6 to use Ultimate Door Lock.')
elseif not (OneOS and pocket) and term.isColor and term.isColor() then
	-- If the program crashes close the door and reboot
	local _, err = pcall(Initialise)
	if err then
		CloseDoor()
		term.setCursorPos(1,1)
		term.setBackgroundColour(colours.black)
		term.setTextColour(colours.white)
		term.clear()
		print('Ultimate Door Lock has crashed')
		print('To maintain security, the computer will reboot.')
		print('If you are seeing this alot try turning off all Pocket Computers or reinstall.')
		print()
		print('Error:')
		printError(err)
		sleep(5)
		os.reboot()
	end
elseif OneOS and pocket then
	term.setCursorPos(1,3)
	term.setBackgroundColour(colours.white)
	term.setTextColour(colours.blue)
	term.clear()
	print('OneOS already acts as a door key. Simply place your PDA in the door\'s disk drive to register it.')
	print()
	print('To setup a door, run this program on an advanced computer (non-pocket).')
	print()
	print('Click anywhere to quit')
	os.pullEvent('mouse_click')
	Quit()
else
	print('Ultimate Door Lock requires an advanced (gold) computer or pocket computer.')
end