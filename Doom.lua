
-- Made by Xella

-- Ugly old code
-- Couldn't be bothered to fix everything when updating to the new Pine3D
-- Don't mod this mess. Please just make your own game which has readable code

local path = "/"..fs.getDir(shell.getRunningProgram())
local Pine3D = require("Pine3D-minified")
os.loadAPI(path.."/blittle")

local objects = {}

local gun = paintutils.loadImage(path.."/images/gun")
local gunf = paintutils.loadImage(path.."/images/gunf")
local bgun = paintutils.loadImage(path.."/images/bgun")
local bgunf = paintutils.loadImage(path.."/images/bgunf")

local heart = paintutils.loadImage(path.."/images/heart")
local bheart = paintutils.loadImage(path.."/images/bheart")
local hearts = 5

local fire = paintutils.loadImage(path.."/images/fire")
local bfire = paintutils.loadImage(path.."/images/bfire")
local shootCooldown = 3 / 16
local lastShot = os.clock() - shootCooldown
local resetGame = false

local playerX = 0
local playerY = 0
local playerZ = -2

local playerSpeed = 3
local playerTurnSpeed = 100
local keysDown = {}

local gunbobX, gunbobY = 0, 0

local username = "Unnamed"
local submitScore = true
local graphics = "Good"
local score = 0
local scoreTime = 0
local endGame = false
local levelCount = 0
local reloadedLevel = false

local xDoor = true
local endless = false

local enemySpeed = 2.5

local FoV = 90

local playerDirectionHor = 0
local playerDirectionVer = 0

local finishMode

local termWidth, termHeight = term.getSize()

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local ThreeDFrame = Pine3D.newFrame()
local blittleOn = true
ThreeDFrame:highResMode(blittleOn)
ThreeDFrame:setBackgroundColor(colors.lightGray)

local environmentObjects = {
	ThreeDFrame:newObject(Pine3D.models:plane({size = 100, y = -0.1, color = colors.orange}))
}

local latestScore = {}

local function min(a, b)
	if (a <= b) then
		return a
	end
	return b
end

local function loadSettings()
	if (fs.exists(path.."/settings") == false) then
		local file = fs.open(path.."/settings", "w")
		file.writeLine("Unnamed")
		file.writeLine("true")
		file.writeLine("Good")
		file.close()
	end

	local file = fs.open(path.."/settings", "r")
	username = file.readLine()
	submitScore = file.readLine()
	graphics = file.readLine()
	file.close()

	if (graphics == "Good") then
		blittleOn = true
	else
		blittleOn = false
	end
	ThreeDFrame:highResMode(blittleOn)
end

local function saveSettings()
	local file = fs.open(path.."/settings", "w")
	file.writeLine(username)
	file.writeLine(submitScore)
	file.writeLine(graphics)
	file.close()
end

local function loadLevel(levelname)
	if (reloadedLevel == false) then
		objects = {}
	end
	local level = paintutils.loadImage(path.."/levels/"..levelname)

	for z, row in pairs(level) do
		for x, value in pairs(row) do
			if (value ~= nil and value > 0) then
				if (value == 1) then
					playerX = x
					playerY = 0
					playerZ = z
				end
				if (reloadedLevel == false) then
					local object = nil
					if (value == colors.orange) then
						object = ThreeDFrame:newObject("models/wallz", x, 0, z)
						object.solid = true
					elseif (value == colors.magenta) then
						object = ThreeDFrame:newObject("models/wallx", x, 0, z)
						object.solid = true
					elseif (value == colors.lightBlue) then
						object = ThreeDFrame:newObject("models/wallxz", x, 0, z)
						object.solid = true
					elseif (value == colors.red) then
						object = ThreeDFrame:newObject("models/doorz", x, 0, z)
						object.model = "doorz"
					elseif (value == colors.green) then
						object = ThreeDFrame:newObject("models/doorx", x, 0, z)
						object.model = "doorx"
					elseif (value == colors.yellow) then
						object = ThreeDFrame:newObject("models/enemy1", x, 0, z)
						object.model = "enemy1"
						object.lastHit = os.clock()
					elseif (value == colors.lime) then
						object = ThreeDFrame:newObject("models/enemy2", x, 0, z)
						object.model = "enemy2"
						object.lastHit = os.clock() - 1/20
					elseif (value == colors.pink) then
						object = ThreeDFrame:newObject("models/emerald", x, 0, z, 0, 45, 0)
						object.solid = true
					end

					if object then
						objects[#objects+1] = object
					end
				end
			end
		end
	end
end

local function loadRandomLevel(xDoor)
	if (xDoor == false) then
		local levels = {"level3", "level5", "level7"}
		loadedLevel = levels[math.random(1, table.getn(levels))]
	else
		local levels = {"level2", "level4", "level6", "level8"}
		loadedLevel = levels[math.random(1, table.getn(levels))]
	end

	loadLevel(loadedLevel)
end

local function free(x, y, z)
	for objectNr, object in pairs(objects) do
		if object.solid then
			if (x >= object[1] - 0.5 and x <= object[1] + 0.5) then
				if (y >= object[2] and y <= object[2] + 1) then
					if (z >= object[3] - 0.5 and z <= object[3] + 0.5) then
						return false
					end
				end
			end
		end
	end
	return true
end

local function rendering()
	ThreeDFrame:setCamera(playerX, playerY + 0.5, playerZ, 0, playerDirectionHor, playerDirectionVer)

	while true do
		--ThreeDFrame:loadGround(backgroundColor1)
		--ThreeDFrame:loadSky(backgroundColor2)
		ThreeDFrame:drawObjects(environmentObjects)
		ThreeDFrame:drawObjects(objects)
		if (blittleOn) then
			if (lastShot > os.clock() - shootCooldown) then
				ThreeDFrame.buffer:image(29+gunbobX+(termWidth-51), 8+gunbobY+(termHeight-19), bfire, true)
				ThreeDFrame.buffer:image(32+gunbobX+(termWidth-51), 10+gunbobY+(termHeight-19), bgunf, true)
			else
				ThreeDFrame.buffer:image(32+gunbobX+(termWidth-51), 10+gunbobY+(termHeight-19), bgun, true)
			end

			for i = 1, hearts do
				ThreeDFrame.buffer:image(2 + (i-1) * 6, 2, bheart, true)
			end
		else
			if (lastShot > os.clock() - shootCooldown) then
				ThreeDFrame.buffer:image(29+gunbobX+(termWidth-51), 8+gunbobY+(termHeight-19), fire, false)
				ThreeDFrame.buffer:image(32+gunbobX+(termWidth-51), 10+gunbobY+(termHeight-19), gunf, false)
			else
				ThreeDFrame.buffer:image(32+gunbobX+(termWidth-51), 10+gunbobY+(termHeight-19), gun, false)
			end

			for i = 1, hearts do
				ThreeDFrame.buffer:image(2 + (i-1) * 6, 2, heart, false)
			end
		end
		ThreeDFrame:drawBuffer()

		os.queueEvent("FakeEvent")
		os.pullEvent("FakeEvent")
	end
end

local function shoot()
	local bulletDirHor = playerDirectionHor
	local bulletX = playerX
	local bulletZ = playerZ

	local step = 0.15

	local hit = false
	for i = 1, 10 / step do
		bulletX = bulletX + math.cos(math.rad(playerDirectionHor)) * step
		bulletZ = bulletZ + math.sin(math.rad(playerDirectionHor)) * step

		if (free(bulletX, 0, bulletZ) == false) then
			hit = true
			break
		end

		for objectNr, object in pairs(objects) do
			if (object.model == "enemy1" or object.model == "enemy2") then
				if ((math.abs(bulletX - object[1])^2 + math.abs(bulletZ - object[3]))^0.5 <= 0.5) then
					object:setModel("models/corpse")
					object.model = "models/corpse"
					hit = true
					score = score + 10
					break
				end
			end
		end

		if (hit) then
			break
		end
	end
end

local gunbobby = -1

local function inputPlayer(time)
	local playerXvel = 0
	local playerZvel = 0
	local isMoving

	if (keysDown[keys.left]) then
		playerDirectionHor = playerDirectionHor - playerTurnSpeed * time
		if (playerDirectionHor <= -180) then
			playerDirectionHor = playerDirectionHor + 360
		end
	end
	if (keysDown[keys.right]) then
		playerDirectionHor = playerDirectionHor + playerTurnSpeed * time
		if (playerDirectionHor >= 180) then
			playerDirectionHor = playerDirectionHor - 360
		end
	end
	if (keysDown[keys.down]) then
		playerDirectionVer = playerDirectionVer - playerTurnSpeed * time
		if (playerDirectionVer < -80) then
			playerDirectionVer = -80
		end
	end
	if (keysDown[keys.up]) then
		playerDirectionVer = playerDirectionVer + playerTurnSpeed * time
		if (playerDirectionVer > 80) then
			playerDirectionVer = 80
		end
	end
	if (keysDown[keys.w]) then
		playerXvel = playerSpeed * math.cos(math.rad(playerDirectionHor)) + playerXvel
		playerZvel = playerSpeed * math.sin(math.rad(playerDirectionHor)) + playerZvel
	end
	if (keysDown[keys.s]) then
		playerXvel = -playerSpeed * math.cos(math.rad(playerDirectionHor)) + playerXvel
		playerZvel = -playerSpeed * math.sin(math.rad(playerDirectionHor)) + playerZvel
	end
	if (keysDown[keys.a]) then
		playerXvel = playerSpeed * math.cos(math.rad(playerDirectionHor - 90)) + playerXvel
		playerZvel = playerSpeed * math.sin(math.rad(playerDirectionHor - 90)) + playerZvel
	end
	if (keysDown[keys.d]) then
		playerXvel = playerSpeed * math.cos(math.rad(playerDirectionHor + 90)) + playerXvel
		playerZvel = playerSpeed * math.sin(math.rad(playerDirectionHor + 90)) + playerZvel
	end

	if (keysDown[keys.space]) then
		if (lastShot < os.clock() - shootCooldown) then
			lastShot = os.clock()
			shoot()
		end
	end

	if (math.abs(playerXvel) > 0.5) or (math.abs(playerZvel) > 0.5) then
		if gunbobby == -1 then gunbobby = 1 end
		gunbobby = (gunbobby + (math.abs(playerXvel*time) + math.abs(playerZvel*time)) * 2) % 360
	else
		gunbobby = -1
	end
	if gunbobby == -1 then
		gunbobX = 0
		gunbobY = 0
	else
		gunbobX = round(math.sin(gunbobby),1)
		gunbobY = round(math.abs(math.cos(gunbobby)),1)
	end

	if (free(playerX + playerXvel * time, playerY, playerZ)) then
		playerX = playerX + playerXvel * time
	end
	if (free(playerX, playerY, playerZ + playerZvel * time)) then
		playerZ = playerZ + playerZvel * time
	end

	for _, object in pairs(objects) do
		if (object.model == "doorx" or object.model == "doorz") then
			local dx = object[1] - playerX
			local dz = object[3] - playerZ
			local distance = math.sqrt(dx^2 + dz^2)

			if (distance < 0.5) then
				if (endless == false) then
					reloadedLevel = true
					if (loadedLevel == "level1") then
						loadedLevel = "level2"
						reloadedLevel = false
					elseif (loadedLevel == "level2" and object.model == "doorx") then
						loadedLevel = "level3"
						reloadedLevel = false
					elseif (loadedLevel == "level3" and object.model == "doorz") then
						loadedLevel = "level4"
						reloadedLevel = false
					elseif (loadedLevel == "level4" and object.model == "doorx") then
						loadedLevel = "level5"
						reloadedLevel = false
					elseif (loadedLevel == "level5" and object.model == "doorz") then
						loadedLevel = "level6"
						reloadedLevel = false
					elseif (loadedLevel == "level6" and object.model == "doorx") then
						loadedLevel = "level7"
						reloadedLevel = false
					elseif (loadedLevel == "level7" and object.model == "doorz") then
						loadedLevel = "level8"
						reloadedLevel = false
					elseif (loadedLevel == "level8" and object.model == "doorx") then
						loadedLevel = "level9"
						reloadedLevel = false

						backgroundColor1 = colors.lime
						backgroundColor2 = colors.lightBlue

						playerDirectionHor = 270
						playerDirectionVer = 0

						endGame = true
						score = score + hearts * 16 + 400 - 8*min(50, scoreTime)
					end

					loadLevel(loadedLevel)
				else
					if (object.model == "doorx" and xDoor) then
						xDoor = false
						loadRandomLevel(xDoor)
						levelCount = levelCount + 1
					elseif (object.model == "doorz" and xDoor == false) then
						xDoor = true
						loadRandomLevel(xDoor)
						levelCount = levelCount + 1
					else
						reloadedLevel = true
						loadLevel(loadedLevel)
						reloadedLevel = false
					end
				end
			end
		end
	end

	ThreeDFrame:setCamera(playerX, playerY + 0.5, playerZ, 0, playerDirectionHor, playerDirectionVer)
end

local function smoothKeyInput()
	--keysDown = {}
	while true do
		local sEvent, key = os.pullEvent()
		if sEvent == "key" then
			keysDown[key] = true
			if (key == keys.g) then
				loadSettings()
				if (blittleOn == false) then
					blittleOn = true
					graphics = "Good"
					ThreeDFrame:highResMode(true)
				else
					blittleOn = false
					graphics = "Bad"
					ThreeDFrame:highResMode(false)
				end
				saveSettings()
			elseif (key == keys.q) then
				playerDirectionHor = playerDirectionHor + 180
				playerDirectionVer = -playerDirectionVer
			elseif key == keys.leftCtrl then
				resetGame = true
			end
		elseif sEvent == "key_up" then
			keysDown[key] = nil
		elseif sEvent == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
		end
	end
end

local function lineOfSight(x, z)
	local dx = x - playerX
	local dz = z - playerZ
	local lineDir = math.atan(dx / dz)
	local distance = math.sqrt(dx^2 + dz^2)

	local curX = x
	local curZ = z

	local step = 0.15

	local sight = true
	for i = 1, distance / step do
		curX = curX + math.cos(lineDir) * step
		curZ = curZ + math.sin(lineDir) * step

		if (free(curX, 0, curZ) == false) then
			sight = false
			break
		end
	end

	return sight
end

local function updateGame(time)
	if (endGame == false) then
		scoreTime = scoreTime + time
	end

	for objectNr, object in pairs(objects) do
		if (object.model == "enemy1") then
			local dx = object[1] - playerX
			local dz = object[3] - playerZ

			if (dz == 0) then
				dz = 0.00001
			end

			local playerDir = math.deg(math.atan(dx/dz))
			if (dz < 0) then
				if (dx < 0) then
					playerDir = playerDir - 180
				else
					playerDir = playerDir + 180
				end
			else
				if (dx < 0) then
					playerDir = playerDir
				else
					playerDir = playerDir
				end
			end

			object:setRot(nil, math.rad(playerDir + 90), nil)

			if (object.lastHit < os.clock() - 3) then
				if (lineOfSight(object[1], object[3])) then
					object.lastHit = os.clock()
					hearts = hearts - 1
				end
			end
		elseif (object.model == "enemy2") then
			local dx = object[1] - playerX
			local dz = object[3] - playerZ

			if (dz == 0) then
				dz = 0.00001
			end

			local playerDir = math.deg(math.atan(dx/dz))
			if (dz < 0) then
				if (dx < 0) then
					playerDir = playerDir - 180
				else
					playerDir = playerDir + 180
				end
			else
				if (dx < 0) then
					playerDir = playerDir
				else
					playerDir = playerDir
				end
			end

			object:setRot(nil, math.rad(playerDir + 90), nil)
			local playerDistance = math.sqrt(dx^2 + dz^2)

			if (playerDistance >= 0.5) then
				local edX = -enemySpeed * math.sin(math.rad(playerDir)) * time
				local edZ = -enemySpeed * math.cos(math.rad(playerDir)) * time
				if (free(object[1] + edX, object[2], object[3])) then
					object[1] = object[1] + edX
				end
				if (free(object[1], object[2], object[3] + edZ)) then
					object[3] = object[3] + edZ
				end
			end

			if (object.lastHit < os.clock() - 3) then
				if (playerDistance < 1) then
					object.lastHit = os.clock()
					hearts = hearts - 1
				end
			end
		end
	end
end

local function deathAnimation()
	local blood = {{16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384},{16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,0,0,0,0,16384,16384,16384,16384,16384,16384,0,0,0,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,0,16384},{16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,16384,1,16384,16384,16384,16384,16384,16384,16384,0,0,0,0,0,0,16384,16384,16384,16384,0,0,0,0,16384,16384,1,16384,16384,0,0,0,0,16384,16384,16384,16384,16384,0,0,0},{16384,16384,16384,16384,16384,1,16384,16384,0,16384,16384,16384,1,1,16384,16384,0,0,16384,16384,0,0,0,0,0,0,0,16384,1,16384,16384,0,0,0,0,16384,16384,16384,16384,0,0,0,0,16384,16384,16384,16384,16384,0,0,0},{0,16384,16384,16384,1,1,16384,16384,0,0,0,16384,16384,16384,16384,16384,0,0,0,0,0,0,0,0,0,0,0,16384,1,16384,16384,0,0,0,0,16384,16384,16384,0,0,0,0,0,0,16384,16384,16384,16384,0,0,0},{0,0,0,16384,16384,16384,16384,0,0,0,0,0,0,16384,16384,0,0,0,0,0,0,0,0,0,0,0,0,16384,16384,16384,16384,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,1,1,16384,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,16384,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,16384,1,16384,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,16384,16384,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,16384,16384,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16384,0,0,0,0}}
	local scr_x, scr_y = term.getSize()
	local function fade(col1, col2, delay)
		local oldeTXT, oldeBG = term.getTextColor(), term.getBackgroundColor()
		term.setBackgroundColor(col1)
		term.setTextColor(col2)
		term.clear()
		sleep(delay or 0)
		for a = 1, 2 do
			for y = 1, scr_y do
				term.setCursorPos((y%2),y)
				term.write(("\127 "):rep(math.ceil(scr_x/2)+1))
			end
			sleep(delay or 0)
			if a == 1 then
				for y = 1, scr_y do
					term.setCursorPos(1,y)
					term.write(("\127"):rep(scr_x))
				end
			else
				term.clear()
			end
			sleep(delay or 0)
			term.setBackgroundColor(col2)
			term.setTextColor(col1)
		end
		sleep(0 or delay)
		term.setTextColor(oldeTXT)
		term.setBackgroundColor(oldeBG)
	end

	local topcenterwrite = function(txt)
		term.setCursorPos((scr_x/2)-(#txt/2) + 1,1)
		term.write(txt)
	end

	if scr_x == 51 then
		for y = 1, #blood do
			paintutils.drawImage(blood,1,y-#blood)
			sleep(0.1)
		end
	end
	term.setBackgroundColor(colors.red)
	term.setTextColor(colors.white)
	local script = {
		"You feel the last of",
		"your life drain away",
		"as your body succumbs to",
		"the deeply inflicted wounds",
		"you failed to prevent.",
		"",
		"Your lungs collapse.",
		"",
		"GAME OVER"
	}
	local skip = false
	for y = scr_y, 1, -1 do
		term.scroll(-1)
		if script[y-4] then
			topcenterwrite(script[y-4])
		end
		if (skip) then
			sleep(0)
			skip = false
		else
			skip = true
		end
	end
	--sleep(0.5)
	os.pullEvent("char")
	term.clear()
	sleep(0.1)
	fade(colors.red,colors.black,0.1)
	sleep(0.2)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()
end

local function gameUpdate()
	local timeFromLastUpdate = os.clock()
	--local avgUpdateSpeed = 0
	--local updateCount = 0
	--local timeOff = 0

	while true do
		local currentTime = os.clock()
		--[[if (currentTime > timeFromLastUpdate) then
			updateGame(currentTime - timeFromLastUpdate - timeOff)
			inputPlayer(currentTime - timeFromLastUpdate - timeOff)
			avgUpdateSpeed = (currentTime - timeFromLastUpdate) / (updateCount + 1)
			updateCount = 0
			timeOff = 0
		else
			updateGame(avgUpdateSpeed)
			newTimeOff = timeOff + avgUpdateSpeed
			newUpdateCount = updateCount + 1
		end]]--
		local dt = currentTime - timeFromLastUpdate
		updateGame(dt)
		inputPlayer(dt)
		timeFromLastUpdate = currentTime

		if resetGame then
			finishMode = "reset"
			break
		end

		--sleep(0)
		os.queueEvent("gameupdate")
		os.pullEvent("gameupdate")

		if (hearts <= 0) then
			finishMode = "death"
			break
		end
		if (endGame) then
			finishMode = "finish"
			break
		end
	end
end

local function viewHighscores(endless)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()

	term.setCursorPos(12+(termWidth-51)/2, 10)
	write("Connecting to the database...")

	local rawData = {}
	if (endless == false) then
		rawData = http.get("https://doom.pine3d.cc/api/highscores")
	else
		rawData = http.get("https://doom.pine3d.cc/api/highscoresendless")
	end

	if (rawData == nil) then
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.red)
		term.clear()
		term.setCursorPos(2, 2)
		write("Server is not reachable.")
	else
		local rawData2 = rawData.readAll()

		term.clear()
		term.setCursorPos(2+(termWidth-51)/2, 2)
		write("Online Highscores:")

		term.setTextColor(colors.red)
		term.setCursorPos(2+(termWidth-51)/2, 4)
		if (endless == false) then
			write("#  Nickname             Score  Time    Date")
		else
			write("#  Nickname             Score  Levels  Date")
		end
		term.setTextColor(colors.orange)
		local recordNr = 0
		for record in rawData2:gmatch("[^~]*~") do
			record = record:gsub("~", "")

			local values = {}
			for recordField in record:gmatch("[^;]*;") do
				values[#values+1] = recordField
			end

			local val2 = values[2]:gsub(";", "")
			local val3 = values[3]:gsub(";", "")

			if values[1]:gsub(";", "") == latestScore[1] and tonumber(val2) == math.floor(latestScore[2]*10 + 0.5)/10 and tonumber(val3) == math.floor(latestScore[3]*100 + 0.5)/100 then
				term.setTextColor(colors.white)
			else
				term.setTextColor(colors.orange)
			end

			term.setCursorPos(2+(termWidth-51)/2, 6 + recordNr)
			write(recordNr + 1)

			for i = 1, #values do
				local value = values[i]
				if (i == 1) then
					term.setCursorPos(5+(termWidth-51)/2, 6 + recordNr)
				elseif (i == 2) then
					term.setCursorPos(26+(termWidth-51)/2, 6 + recordNr)
				elseif (i == 3) then
					term.setCursorPos(33+(termWidth-51)/2, 6 + recordNr)
				elseif (i == 4) then
					term.setCursorPos(41+(termWidth-51)/2, 6 + recordNr)
					local year = ""
					local month = ""
					local day = ""

					local partNr = 0
					for part in value:gmatch("[^-]*") do
						if (partNr == 0) then
							year = part
						elseif (partNr == 2) then
							month = part
						elseif (partNr == 4) then
							day = part
						end

						partNr = partNr + 1
					end

					value = day.."-"..month.."-"..year
				end

				write(value:gsub(";", ""))
			end
			recordNr = recordNr + 1

			if (recordNr >= 11 + (termHeight-19)) then
				break
			end
		end
	end

	sleep(1)

	term.setTextColor(colors.yellow)
	term.setCursorPos(2+(termWidth-51)/2, termHeight-1)
	write("Press any key to close...")
	sleep(0.5)
	while true do
		local event, key = os.pullEvent()
		if event == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
			return viewHighscores(endless)
		elseif event == "key" and key ~= keys.leftAlt and key ~= keys.f2 then
			return
		end
	end
end

local function startGame()
	loadSettings()
	resetGame = false
	ThreeDFrame:highResMode(blittleOn)
	parallel.waitForAny(smoothKeyInput, rendering, gameUpdate)
end

local function newGameNormal()
	score = 0
	scoreTime = 0
	hearts = 5
	endGame = false
	playerDirectionHor = 0
	playerDirectionVer = 0
	reloadedLevel = false

	loadedLevel = "level1"
	loadLevel(loadedLevel)
	endless = false
	backgroundColor1 = colors.orange
	backgroundColor2 = colors.lightGray

	startGame()

	if finishMode == "reset" then
		return newGameNormal()
	end

	if (hearts > 0) then
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.red)
		term.clear()

		term.setCursorPos(2, 2)
		write("You have survived!")

		term.setTextColor(colors.orange)
		term.setCursorPos(2, 4)
		write("Score: "..(math.floor(score*10+0.5)/10))
		term.setCursorPos(2, 5)
		write("Time: "..(math.floor(scoreTime*100+0.5)/100))

		if (submitScore == "true") then
			latestScore = {username, score, scoreTime}
			local result = http.get("https://doom.pine3d.cc/api/newscore?name="..textutils.urlEncode(username).."&score="..score.."&time="..scoreTime)
			if (result == nil) then
				term.setBackgroundColor(colors.black)
				term.setTextColor(colors.red)
				term.clear()
				term.setCursorPos(2, 2)
				write("Server is not reachable. Score has not been submitted.")
			end
		end
		sleep(2)
		term.setTextColor(colors.yellow)
		term.setCursorPos(2, termHeight-1)
		write("Press any key to close...")
		os.pullEvent("key")

		if (submitScore == "true") then
			viewHighscores(false)
		end
	else
		deathAnimation()
	end
end

local function newGameEndless()
	score = 0
	time = 0
	hearts = 8
	endGame = false
	playerDirectionHor = 0
	playerDirectionVer = 0
	reloadedLevel = false

	xDoor = false
	loadRandomLevel(xDoor)
	endless = true
	levelCount = 0
	backgroundColor1 = colors.orange
	backgroundColor2 = colors.lightGray

	startGame()

	if finishMode == "reset" then
		return newGameNormal()
	end

	score = score + levelCount * 22
	deathAnimation()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.red)
	term.clear()

	term.setCursorPos(2, 2)
	write("You died!")

	term.setTextColor(colors.orange)
	term.setCursorPos(2, 4)
	write("Score: "..(math.floor(score*10+0.5)/10))
	term.setCursorPos(2, 5)
	write("Levels: "..levelCount)

	if (submitScore == "true") then
		latestScore = {username, score, levelCount}
		local result = http.get("https://doom.pine3d.cc/api/newscoreendless?name="..textutils.urlEncode(username).."&score="..score.."&levels="..levelCount)
		if (result == nil) then
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.red)
			term.clear()
			term.setCursorPos(2, 2)
			write("Server is not reachable. Score has not been submitted.")
		end
	end
	sleep(2)
	term.setTextColor(colors.yellow)
	term.setCursorPos(2, termHeight-1)
	write("Press any key to close...")
	os.pullEvent("key")

	if (submitScore == "true") then
		viewHighscores(true)
	end
end

local function newGame()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.red)
	term.clear()

	term.setCursorPos(21+(termWidth-51)/2, 8)
	write("Normal Mode")

	term.setCursorPos(20+(termWidth-51)/2, 10)
	write("Endless Mode")

	term.setCursorPos(24+(termWidth-51)/2, 12)
	write("Back")

	local selected2 = 0
	while true do
		term.setTextColor(colors.yellow)
		term.setCursorPos(19+(termWidth-51)/2, 8)
		if (selected2 == 0) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(18+(termWidth-51)/2, 10)
		if (selected2 == 1) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(22+(termWidth-51)/2, 12)
		if (selected2 == 2) then
			write(">")
		else
			write(" ")
		end

		local event, key = os.pullEvent()
		if event == "key" then
			if (key == keys.w or key == keys.up) then
				selected2 = (selected2 - 1 + 3) % 3
			elseif (key == keys.s or key == keys.down) then
				selected2 = (selected2 + 1) % 3
			elseif (key == keys.space or key == keys.enter) then
				if (selected2 == 0) then
					newGameNormal()
				elseif (selected2 == 1) then
					newGameEndless()
				end
				break
			end
		elseif event == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.red)
			term.clear()

			term.setCursorPos(21+(termWidth-51)/2, 8)
			write("Normal Mode")

			term.setCursorPos(20+(termWidth-51)/2, 10)
			write("Endless Mode")

			term.setCursorPos(24+(termWidth-51)/2, 12)
			write("Back")
		end
	end
end

local function showHighscores()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.red)
	term.clear()

	term.setCursorPos(21+(termWidth-51)/2, 8)
	write("Normal Mode")

	term.setCursorPos(20+(termWidth-51)/2, 10)
	write("Endless Mode")

	term.setCursorPos(24+(termWidth-51)/2, 12)
	write("Back")

	local selected2 = 0
	while true do
		term.setTextColor(colors.yellow)
		term.setCursorPos(19+(termWidth-51)/2, 8)
		if (selected2 == 0) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(18+(termWidth-51)/2, 10)
		if (selected2 == 1) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(22+(termWidth-51)/2, 12)
		if (selected2 == 2) then
			write(">")
		else
			write(" ")
		end

		local event, key = os.pullEvent()
		if event == "key" then
			if (key == keys.w or key == keys.up) then
				selected2 = (selected2 - 1 + 3) % 3
			elseif (key == keys.s or key == keys.down) then
				selected2 = (selected2 + 1) % 3
			elseif (key == keys.space or key == keys.enter) then
				if (selected2 == 0) then
					viewHighscores(false)
				elseif (selected2 == 1) then
					viewHighscores(true)
				end
				break
			end
		elseif event == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.red)
			term.clear()

			term.setCursorPos(21+(termWidth-51)/2, 8)
			write("Normal Mode")

			term.setCursorPos(20+(termWidth-51)/2, 10)
			write("Endless Mode")

			term.setCursorPos(24+(termWidth-51)/2, 12)
			write("Back")
		end
	end
end

local function drawMenu()
	local logo = paintutils.loadImage(path.."/images/logo")
	local blogo = blittle.shrink(logo)
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.red)
	term.clear()
	blittle.draw(blogo, 12+(termWidth-51)/2, 3)

	term.setCursorPos(21+(termWidth-51)/2, 10)
	write("Start Game")

	term.setCursorPos(17+(termWidth-51)/2, 12)
	write("Online Highscores")

	term.setCursorPos(22+(termWidth-51)/2, 14)
	write("Settings")

	term.setCursorPos(24+(termWidth-51)/2, 16)
	write("Exit")

	term.setTextColor(colors.yellow)
	term.setCursorPos(1, termHeight)
	write("Copyright (c) 2022 Xella")
end

local function drawSettings()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()

	term.setCursorPos(2, 2)
	write("Settings:")

	term.setCursorPos(4, 4)
	write("Change name | ")
	term.setTextColor(colors.orange)
	write(username)

	term.setCursorPos(4, 6)
	term.setTextColor(colors.yellow)
	write("Submit score | ")
	if (submitScore == "true") then
		term.setTextColor(colors.lime)
		write("Enabled")
	else
		term.setTextColor(colors.red)
		write("Disabled")
	end

	term.setCursorPos(4, 8)
	term.setTextColor(colors.yellow)
	write("Graphics | ")
	if (graphics == "Good") then
		term.setTextColor(colors.lime)
	else
		term.setTextColor(colors.red)
	end
	write(graphics.."   ")
	term.setTextColor(colors.yellow)
	write("(Toggle in-game using \"G\")")

	term.setTextColor(colors.orange)
	term.setCursorPos(4, 10)
	write("Save and close")
end

local function changeName()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()

	term.setCursorPos(2, 2)
	write("Enter a username (3-20 characters):")

	while true do
		term.setCursorPos(2, 4)
		term.clearLine()
		term.setCursorPos(2, 4)
		term.setTextColor(colors.red)
		write("Username: ")
		term.setTextColor(colors.orange)
		local usernameCandidate = read()
		if (string.len(usernameCandidate) >= 3 and string.len(usernameCandidate) <= 20) then
			username = usernameCandidate
			break
		else
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.red)
			term.setCursorPos(2, 6)
			write("Your new username must be at least 3 and at most\n 20 characters long!")
		end
	end

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.yellow)
	term.clear()

	term.setCursorPos(2, 2)
	write("Your new username is: ")

	term.setTextColor(colors.orange)
	write(username)
end

local function settingsMenu()
	loadSettings()

	drawSettings()
	local selected2 = 0
	while true do
		term.setTextColor(colors.yellow)
		term.setCursorPos(2, 4)
		if (selected2 == 0) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(2, 6)
		if (selected2 == 1) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(2, 8)
		if (selected2 == 2) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(2, 10)
		if (selected2 == 3) then
			write(">")
		else
			write(" ")
		end

		local event, key = os.pullEvent()
		if event == "key" then
			if (key == keys.w or key == keys.up) then
				selected2 = (selected2 - 1 + 4) % 4
			elseif (key == keys.s or key == keys.down) then
				selected2 = (selected2 + 1) % 4
			elseif (key == keys.space or key == keys.enter) then
				if (selected2 == 0) then
					changeName()
					drawSettings()
				elseif (selected2 == 1) then
					if (submitScore == "true") then
						submitScore = "false"
					else
						submitScore = "true"
					end

					term.setCursorPos(4, 6)
					term.setTextColor(colors.yellow)
					write("Submit score | ")
					if (submitScore == "true") then
						term.setTextColor(colors.lime)
						write("Enabled ")
					else
						term.setTextColor(colors.red)
						write("Disabled")
					end
				elseif (selected2 == 2) then
					if (graphics == "Good") then
						graphics = "Bad"
						blittleOn = false
						ThreeDFrame:highResMode(blittleOn)
					else
						graphics = "Good"
						blittleOn = true
						ThreeDFrame:highResMode(blittleOn)
					end

					term.setCursorPos(4, 8)
					term.setTextColor(colors.yellow)
					write("Graphics | ")
					if (graphics == "Good") then
						term.setTextColor(colors.lime)
					else
						term.setTextColor(colors.red)
					end
					write(graphics.." ")
				elseif (selected2 == 3) then
					break
				end
			end
		elseif event == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
			drawSettings()
		end
	end

	saveSettings()
end

local function mainMenu()
	drawMenu()
	selected = 0
	while true do
		term.setTextColor(colors.yellow)
		term.setCursorPos(19+(termWidth-51)/2, 10)
		if (selected == 0) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(15+(termWidth-51)/2, 12)
		if (selected == 1) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(20+(termWidth-51)/2, 14)
		if (selected == 2) then
			write(">")
		else
			write(" ")
		end
		term.setCursorPos(22+(termWidth-51)/2, 16)
		if (selected == 3) then
			write(">")
		else
			write(" ")
		end

		local event, key = os.pullEvent()
		if event == "key" then
			if (key == keys.w or key == keys.up) then
				selected = (selected - 1 + 4) % 4
			elseif (key == keys.s or key == keys.down) then
				selected = (selected + 1) % 4
			elseif (key == keys.space or key == keys.enter) then
				if (selected == 0) then
					newGame()
				elseif (selected == 1) then
					showHighscores()
				elseif (selected == 2) then
					settingsMenu()
				elseif (selected == 3) then
					term.setBackgroundColor(colors.black)
					term.setTextColor(colors.yellow)
					term.clear()
					term.setCursorPos(14+(termWidth-51)/2, 10)
					write("Thanks for playing Doom!")
					sleep(1)
					term.clear()
					term.setCursorPos(1, 1)
					break
				end
				drawMenu()
			end
		elseif event == "term_resize" then
			termWidth, termHeight = term.getSize()
			ThreeDFrame:setSize(1, 1, termWidth, termHeight)
			drawMenu()
		end
	end
end

local function resizing()
	while true do
		os.pullEvent("term_resize")
		termWidth, termHeight = term.getSize()
		ThreeDFrame:setSize(1, 1, termWidth, termHeight)
	end
end

parallel.waitForAny(mainMenu, resizing)
