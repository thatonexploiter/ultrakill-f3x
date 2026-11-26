-- F3X / FORK3X ULTRAKILL LOADER GUI (PC + MOBILE)
-- Select characters (V1, V2 and future modules) straight from GitHub with anti-cache

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

-- Clean up previous Loader instance if already open
if env.F3XUltrakillLoaderCleanup then
	pcall(env.F3XUltrakillLoaderCleanup)
end

-------------------------------------------------------------------
-- REPOSITORY CONFIG
-------------------------------------------------------------------
local REPO_BASE = "https://raw.githubusercontent.com/thatonexploiter/ultrakill-f3x/main/"
local CORE_PATH = "core.lua"

local CHARACTERS = {
	{
		id = "v1",
		code = "V1",
		name = "V1 // SUPREME MACHINE",
		desc = "1.0x scale • Feedbacker (Parry) • Marksman Revolver (Coins) • Yellow Wings",
		tag = "1-0 / BASE",
		accent = Color3.fromRGB(68, 128, 255),
		path = "characters/v1.lua",
	},
	{
		id = "v2",
		code = "V2",
		name = "V2 // RECONSTRUCTED",
		desc = "1.16x scale • Knuckleblaster (AoE Blast) • Piercer & Core Eject • Dynamic Wings",
		tag = "1-4 / LIMBO",
		accent = Color3.fromRGB(220, 48, 54),
		path = "characters/v2.lua",
	},
	-- To add new characters later, just copy a block above:
	-- {
	-- 	id = "gabriel",
	-- 	code = "GB",
	-- 	name = "GABRIEL // APOSTATE",
	-- 	desc = "Weapon and ability description",
	-- 	tag = "3-2",
	-- 	accent = Color3.fromRGB(255, 205, 65),
	-- 	path = "characters/gabriel.lua",
	-- },

    -- Characters to make soon: Minos Prime, Gabriel, Sisyphus and Earthmover
}

-------------------------------------------------------------------
-- STATE & UTILITIES
-------------------------------------------------------------------
local isLoading = false
local activeCharId = nil
local isMinimized = false
local connections = {}
local cardButtons = {}

local function cleanupActiveRig()
	local hooks = {
		"F3XUltrakillCleanup",
		"F3XV1ReanimCleanup",
		"F3XV2ReanimCleanup",
		"F3XR6ReanimCleanup",
		"F3XMayhemIdleCleanup",
	}
	for _, key in ipairs(hooks) do
		if type(env[key]) == "function" then
			pcall(env[key])
		end
	end
	activeCharId = nil
end

local function triggerRebuild()
	local rebuildHooks = {
		"F3XUltrakillRebuild",
		"F3XV1ReanimRebuild",
		"F3XV2ReanimRebuild",
	}
	for _, key in ipairs(rebuildHooks) do
		if type(env[key]) == "function" then
			task.spawn(function()
				pcall(env[key])
			end)
			return true
		end
	end
	return false
end

local function fetchAndCompile(relativePath)
	local nonce = tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
	local url = REPO_BASE .. relativePath .. "?t=" .. nonce

	local okHttp, source = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not okHttp or type(source) ~= "string" or #source == 0 then
		return nil, "HttpGet failed (" .. relativePath .. "): " .. tostring(source)
	end

	-- Check if GitHub returned a plain-text 404
	if source:sub(1, 15) == "404: Not Found" then
		return nil, "404 Not Found on GitHub: " .. relativePath
	end

	local fn, compileErr = loadstring(source, "@" .. relativePath)
	if not fn then
		return nil, "Syntax error in " .. relativePath .. ": " .. tostring(compileErr)
	end

	return fn, nil
end

local function getGuiParent()
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local okCore = pcall(function()
		return CoreGui.Name
	end)
	if okCore then return CoreGui end
	return plr:WaitForChild("PlayerGui")
end

-------------------------------------------------------------------
-- INTERFACE BUILD (ULTRAKILL TERMINAL STYLE)
-------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "F3X_Ultrakill_Loader"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getGuiParent()

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.fromOffset(390, 340)
main.Position = UDim2.new(0, 24, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(190, 34, 42)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Top bar (draggable)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
topBar.BorderSizePixel = 0
topBar.Parent = main

local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.Position = UDim2.new(0, 0, 1, -2)
topAccent.BackgroundColor3 = Color3.fromRGB(200, 35, 42)
topAccent.BorderSizePixel = 0
topAccent.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.fromOffset(14, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "ULTRAKILL // F3X LOADER"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 248)
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local function makeHeaderBtn(text, posX, bgColor)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(28, 26)
	btn.Position = UDim2.new(1, posX, 0.5, -13)
	btn.BackgroundColor3 = bgColor
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 240, 245)
	btn.TextSize = 13
	btn.AutoButtonColor = true
	btn.Parent = topBar

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn
	return btn
end

local minBtn = makeHeaderBtn("-", -68, Color3.fromRGB(40, 44, 56))
local closeBtn = makeHeaderBtn("X", -36, Color3.fromRGB(145, 32, 38))

-- Body with character list
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -42)
body.Position = UDim2.fromOffset(0, 42)
body.BackgroundTransparency = 1
body.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -96)
scroll.Position = UDim2.fromOffset(12, 12)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(190, 34, 42)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = body

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

-- Footer (status + quick controls)
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, -24, 0, 72)
footer.Position = UDim2.new(0, 12, 1, -80)
footer.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
footer.BorderSizePixel = 0
footer.Parent = body

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 6)
footerCorner.Parent = footer

local footerStroke = Instance.new("UIStroke")
footerStroke.Color = Color3.fromRGB(42, 46, 58)
footerStroke.Thickness = 1
footerStroke.Parent = footer

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 24)
statusLabel.Position = UDim2.fromOffset(8, 6)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Code
statusLabel.Text = "READY // Select a machine to deploy."
statusLabel.TextColor3 = Color3.fromRGB(180, 190, 205)
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Parent = footer

local function setStatus(msg, color)
	statusLabel.Text = msg
	statusLabel.TextColor3 = color or Color3.fromRGB(180, 190, 205)
end

local function makeFooterBtn(text, xScale, xOffset, color)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, -10, 0, 28)
	btn.Position = UDim2.new(xScale, xOffset, 0, 36)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(245, 245, 248)
	btn.TextSize = 11
	btn.Parent = footer

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = btn
	return btn
end

local resyncBtn = makeFooterBtn("RE-SYNC RIG (F7)", 0, 6, Color3.fromRGB(45, 90, 170))
local stopBtn = makeFooterBtn("STOP / CLEANUP (F6)", 0.5, 4, Color3.fromRGB(155, 36, 44))

-------------------------------------------------------------------
-- CARD VISUAL REFRESH
-------------------------------------------------------------------
local function refreshCardHighlights()
	for id, info in pairs(cardButtons) do
		local isActive = (id == activeCharId)
		info.stroke.Color = isActive and info.accent or Color3.fromRGB(45, 49, 62)
		info.stroke.Thickness = isActive and 2 or 1
		info.badge.Text = isActive and "ACTIVE" or info.tag
		info.badge.BackgroundColor3 = isActive and info.accent or Color3.fromRGB(32, 35, 45)
		info.badge.TextColor3 = isActive and Color3.fromRGB(12, 13, 17) or Color3.fromRGB(210, 215, 225)
	end
end

-------------------------------------------------------------------
-- LOAD FLOW (CLEANUP -> CORE -> MODULE)
-------------------------------------------------------------------
local function loadCharacter(entry)
	if isLoading then
		setStatus("WAIT // A load is already in progress...", Color3.fromRGB(255, 205, 65))
		return
	end
	isLoading = true

	task.spawn(function()
		setStatus("1/3 Cleaning previous rig and connections...", Color3.fromRGB(255, 205, 65))
		cleanupActiveRig()
		refreshCardHighlights()
		task.wait(0.08)

		setStatus("2/3 Downloading core.lua (anti-cache)...", Color3.fromRGB(115, 220, 255))
		local coreFn, coreErr = fetchAndCompile(CORE_PATH)
		if not coreFn then
			setStatus("ERROR: " .. tostring(coreErr), Color3.fromRGB(255, 85, 95))
			isLoading = false
			return
		end

		local okCoreRun, Core = pcall(coreFn)
		if not okCoreRun or type(Core) ~= "table" then
			setStatus("ERROR starting Core: " .. tostring(Core), Color3.fromRGB(255, 85, 95))
			isLoading = false
			return
		end

		setStatus("3/3 Downloading " .. entry.code .. " (" .. entry.path .. ")...", entry.accent)
		local charFn, charErr = fetchAndCompile(entry.path)
		if not charFn then
			setStatus("ERROR: " .. tostring(charErr), Color3.fromRGB(255, 85, 95))
			isLoading = false
			return
		end

		local okCharRun, initChar = pcall(charFn)
		if not okCharRun or type(initChar) ~= "function" then
			setStatus("ERROR in module " .. entry.code .. ": " .. tostring(initChar), Color3.fromRGB(255, 85, 95))
			isLoading = false
			return
		end

		local okInit, initErr = pcall(initChar, Core)
		if not okInit then
			setStatus("ERROR building " .. entry.code .. ": " .. tostring(initErr), Color3.fromRGB(255, 85, 95))
			isLoading = false
			return
		end

		activeCharId = entry.id
		refreshCardHighlights()
		setStatus("ONLINE // " .. entry.name .. " loaded!", Color3.fromRGB(85, 245, 145))
		isLoading = false
	end)
end

-------------------------------------------------------------------
-- BUILD CARDS IN THE GUI
-------------------------------------------------------------------
for idx, entry in ipairs(CHARACTERS) do
	local card = Instance.new("TextButton")
	card.Name = "Card_" .. entry.id
	card.LayoutOrder = idx
	card.Size = UDim2.new(1, -4, 0, 78)
	card.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(45, 49, 62)
	stroke.Thickness = 1
	stroke.Parent = card

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 5, 1, -12)
	bar.Position = UDim2.fromOffset(6, 6)
	bar.BackgroundColor3 = entry.accent
	bar.BorderSizePixel = 0
	bar.Parent = card

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 3)
	barCorner.Parent = bar

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -110, 0, 22)
	nameLbl.Position = UDim2.fromOffset(20, 10)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.Text = entry.name
	nameLbl.TextColor3 = Color3.fromRGB(242, 244, 248)
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = card

	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(82, 20)
	badge.Position = UDim2.new(1, -92, 0, 10)
	badge.BackgroundColor3 = Color3.fromRGB(32, 35, 45)
	badge.BorderSizePixel = 0
	badge.Font = Enum.Font.GothamBold
	badge.Text = entry.tag
	badge.TextColor3 = Color3.fromRGB(210, 215, 225)
	badge.TextSize = 10
	badge.Parent = card

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = badge

	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, -30, 0, 34)
	descLbl.Position = UDim2.fromOffset(20, 34)
	descLbl.BackgroundTransparency = 1
	descLbl.Font = Enum.Font.Gotham
	descLbl.Text = entry.desc
	descLbl.TextColor3 = Color3.fromRGB(165, 172, 188)
	descLbl.TextSize = 11
	descLbl.TextWrapped = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.Parent = card

	cardButtons[entry.id] = {
		card = card,
		stroke = stroke,
		badge = badge,
		accent = entry.accent,
		tag = entry.tag,
	}

	table.insert(connections, card.MouseEnter:Connect(function()
		card.BackgroundColor3 = Color3.fromRGB(27, 30, 40)
	end))
	table.insert(connections, card.MouseLeave:Connect(function()
		card.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
	end))
	table.insert(connections, card.MouseButton1Click:Connect(function()
		loadCharacter(entry)
	end))
end

-------------------------------------------------------------------
-- DRAG (MOUSE + TOUCH) & GUI BUTTONS
-------------------------------------------------------------------
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

table.insert(connections, topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end))

table.insert(connections, topBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end))

table.insert(connections, UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput and dragStart and startPos then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end))

table.insert(connections, minBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	body.Visible = not isMinimized
	main.Size = isMinimized and UDim2.fromOffset(390, 42) or UDim2.fromOffset(390, 340)
	minBtn.Text = isMinimized and "+" or "-"
end))

table.insert(connections, resyncBtn.MouseButton1Click:Connect(function()
	if triggerRebuild() then
		setStatus("RE-SYNC // Rebuilding current rig...", Color3.fromRGB(115, 220, 255))
	else
		setStatus("WARN // No active character to re-sync.", Color3.fromRGB(255, 205, 65))
	end
end))

table.insert(connections, stopBtn.MouseButton1Click:Connect(function()
	cleanupActiveRig()
	refreshCardHighlights()
	setStatus("STOPPED // Rig removed and character restored.", Color3.fromRGB(255, 130, 130))
end))

local function destroyLoader()
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(connections)
	if gui and gui.Parent then
		gui:Destroy()
	end
end

table.insert(connections, closeBtn.MouseButton1Click:Connect(destroyLoader))
env.F3XUltrakillLoaderCleanup = destroyLoader