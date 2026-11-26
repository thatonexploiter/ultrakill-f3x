-- ULTRAKILL // F3X TERMINAL LOADER (SmileOS 2.0 Style)
-- Repo: https://github.com/thatonexploiter/ultrakill-f3x

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local BASE_URL = "https://raw.githubusercontent.com/thatonexploiter/ultrakill-f3x/main/"

-- ============================================================================
-- THEME: ULTRAKILL TERMINAL / SMILEOS 2.0
-- ============================================================================
local THEME = {
	Bg = Color3.fromRGB(8, 8, 10),
	Panel = Color3.fromRGB(14, 14, 16),
	HeaderRed = Color3.fromRGB(175, 22, 22),
	AccentRed = Color3.fromRGB(220, 35, 35),
	AccentGold = Color3.fromRGB(235, 175, 45),
	SuccessGreen = Color3.fromRGB(68, 190, 85),
	BorderWhite = Color3.fromRGB(225, 225, 225),
	BorderDim = Color3.fromRGB(70, 50, 50),
	TextMain = Color3.fromRGB(240, 235, 230),
	TextMuted = Color3.fromRGB(145, 130, 130),
	BtnIdle = Color3.fromRGB(18, 18, 20),
	BtnHover = Color3.fromRGB(140, 20, 20),
	BtnLocked = Color3.fromRGB(24, 20, 20),
}

local TIPS = {
	"TIP OF THE DAY: PARRYING YOUR OWN SHOTGUN PELLETS MAKES THEM EXPLODE.",
	"TIP OF THE DAY: F3X PARTS MUST STAY ANCHORED & NON-COLLIDABLE TO PREVENT FLINGING.",
	"TIP OF THE DAY: THROW A COIN AND SHOOT IT FOR AN INSTANT RICOCHET.",
	"TIP OF THE DAY: MANKIND IS DEAD. BLOOD IS FUEL. HELL IS FULL.",
	"TIP OF THE DAY: USE [REBUILD RIG] IF YOUR CHARACTER RESPAWNS OR DESYNCS.",
}

-- ============================================================================
-- CHARACTER ROSTER
-- ============================================================================
local CHARACTERS = {
	{
		id = "v1",
		name = "V1",
		subtitle = "SUPREME MACHINE // MODEL V1",
		path = "characters/v1.lua",
		unlocked = true,
		desc = "Blue combat chassis with 8 articulated wings, camera head, and backpack core. Supports R6 & R15.",
	},
	{
		id = "v2",
		name = "V2",
		subtitle = "SUPREME MACHINE // MODEL V2",
		path = "characters/v2.lua",
		unlocked = true,
		desc = "Crimson-plated prototype built for durability. Full F3X rig reanimation.",
	},
	{
		id = "gabriel",
		name = "GABRIEL",
		subtitle = "JUDGE OF HELL",
		path = nil,
		unlocked = false,
		desc = "[LOCKED] Awaiting module deployment in characters/gabriel.lua.",
	},
	{
		id = "minos",
		name = "MINOS PRIME",
		subtitle = "KING OF LUST // PRIME SOUL",
		path = nil,
		unlocked = false,
		desc = "[LOCKED] Awaiting module deployment in characters/minos.lua.",
	},
}

-- ============================================================================
-- GLOBAL CONTROLLER & CLEANUP
-- ============================================================================
local LEGACY_CLEANUP_GLOBALS = {
	"F3XV1ReanimCleanup",
	"F3XV2ReanimCleanup",
	"F3XR6ReanimCleanup",
	"F3XMayhemIdleCleanup",
}

local LEGACY_REBUILD_GLOBALS = {
	"F3XV1ReanimRebuild",
	"F3XV2ReanimRebuild",
	"F3XR6ReanimRebuild",
}

local function getGuiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local okCore = pcall(function()
		local _ = CoreGui.Name
	end)
	if okCore then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- Destroy previous loader instance if re-executed
local guiParent = getGuiParent()
local existing = guiParent:FindFirstChild("ULTRAKILL_F3X_TERMINAL")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- BUILD UI (SMILEOS 2.0 TERMINAL)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ULTRAKILL_F3X_TERMINAL"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.BorderWhite
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- Main Terminal Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "TerminalWindow"
MainFrame.Size = UDim2.fromOffset(540, 380)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -190)
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
addStroke(MainFrame, THEME.BorderWhite, 2)

-- SmileOS 2.0 Top Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = THEME.HeaderRed
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleAccent = Instance.new("Frame")
TitleAccent.Size = UDim2.new(1, 0, 0, 2)
TitleAccent.Position = UDim2.new(0, 0, 1, -2)
TitleAccent.BackgroundColor3 = THEME.BorderWhite
TitleAccent.BorderSizePixel = 0
TitleAccent.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -76, 1, 0)
TitleText.Position = UDim2.fromOffset(8, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.Code
TitleText.TextSize = 14
TitleText.TextColor3 = THEME.TextMain
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Text = "SmileOS 2.0  //  ULTRAKILL_F3X.EXE"
TitleText.Parent = TitleBar

-- Window Buttons: [-] and [X]
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(26, 22)
MinBtn.Position = UDim2.new(1, -56, 0, 3)
MinBtn.BackgroundColor3 = THEME.Bg
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.Code
MinBtn.TextSize = 14
MinBtn.TextColor3 = THEME.TextMain
MinBtn.Text = "-"
MinBtn.Parent = TitleBar
addStroke(MinBtn, THEME.BorderWhite, 1)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(26, 22)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.BackgroundColor3 = THEME.Bg
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.Code
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = THEME.AccentRed
CloseBtn.Text = "X"
CloseBtn.Parent = TitleBar
addStroke(CloseBtn, THEME.BorderWhite, 1)

-- Body Container (hidden when minimized)
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -28)
Body.Position = UDim2.fromOffset(0, 28)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

-- Left Sidebar: --MACHINES--
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 165, 1, -42)
Sidebar.Position = UDim2.fromOffset(10, 10)
Sidebar.BackgroundColor3 = THEME.Panel
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Body
addStroke(Sidebar, THEME.BorderDim, 1.5)

local SideHeader = Instance.new("TextLabel")
SideHeader.Size = UDim2.new(1, 0, 0, 24)
SideHeader.BackgroundColor3 = THEME.Bg
SideHeader.BorderSizePixel = 0
SideHeader.Font = Enum.Font.Code
SideHeader.TextSize = 13
SideHeader.TextColor3 = THEME.AccentGold
SideHeader.Text = "--MACHINES--"
SideHeader.Parent = Sidebar

local SideList = Instance.new("ScrollingFrame")
SideList.Size = UDim2.new(1, -8, 1, -30)
SideList.Position = UDim2.fromOffset(4, 28)
SideList.BackgroundTransparency = 1
SideList.BorderSizePixel = 0
SideList.ScrollBarThickness = 3
SideList.ScrollBarImageColor3 = THEME.AccentRed
SideList.CanvasSize = UDim2.new(0, 0, 0, 0)
SideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideList.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 5)
SideLayout.Parent = SideList

-- Right Main Panel: --TERMINAL DATA--
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -195, 1, -42)
ContentPanel.Position = UDim2.fromOffset(185, 10)
ContentPanel.BackgroundColor3 = THEME.Panel
ContentPanel.BorderSizePixel = 0
ContentPanel.Parent = Body
addStroke(ContentPanel, THEME.BorderDim, 1.5)

local SelectedTitle = Instance.new("TextLabel")
SelectedTitle.Size = UDim2.new(1, -16, 0, 26)
SelectedTitle.Position = UDim2.fromOffset(8, 6)
SelectedTitle.BackgroundTransparency = 1
SelectedTitle.Font = Enum.Font.Code
SelectedTitle.TextSize = 18
SelectedTitle.TextColor3 = THEME.AccentRed
SelectedTitle.TextXAlignment = Enum.TextXAlignment.Left
SelectedTitle.Text = "-- V1 --"
SelectedTitle.Parent = ContentPanel

local SelectedSub = Instance.new("TextLabel")
SelectedSub.Size = UDim2.new(1, -16, 0, 16)
SelectedSub.Position = UDim2.fromOffset(8, 30)
SelectedSub.BackgroundTransparency = 1
SelectedSub.Font = Enum.Font.Code
SelectedSub.TextSize = 12
SelectedSub.TextColor3 = THEME.AccentGold
SelectedSub.TextXAlignment = Enum.TextXAlignment.Left
SelectedSub.Text = "SUPREME MACHINE // MODEL V1"
SelectedSub.Parent = ContentPanel

local SelectedDesc = Instance.new("TextLabel")
SelectedDesc.Size = UDim2.new(1, -16, 0, 52)
SelectedDesc.Position = UDim2.fromOffset(8, 50)
SelectedDesc.BackgroundTransparency = 1
SelectedDesc.Font = Enum.Font.Code
SelectedDesc.TextSize = 12
SelectedDesc.TextColor3 = THEME.TextMain
SelectedDesc.TextXAlignment = Enum.TextXAlignment.Left
SelectedDesc.TextYAlignment = Enum.TextYAlignment.Top
SelectedDesc.TextWrapped = true
SelectedDesc.Text = ""
SelectedDesc.Parent = ContentPanel

-- Action Buttons Row
local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -16, 0, 34)
ActionRow.Position = UDim2.fromOffset(8, 108)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = ContentPanel

local function makeTerminalButton(text, size, pos, accentColor)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = THEME.BtnIdle
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = 13
	btn.TextColor3 = accentColor or THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.Parent = ActionRow
	local stroke = addStroke(btn, accentColor or THEME.BorderWhite, 1.5)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnHover }):Play()
		stroke.Color = THEME.BorderWhite
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnIdle }):Play()
		stroke.Color = accentColor or THEME.BorderWhite
	end)
	return btn
end

local DeployBtn = makeTerminalButton("[ DEPLOY ]", UDim2.new(0.38, -4, 1, 0), UDim2.fromScale(0, 0), THEME.AccentRed)
local RebuildBtn = makeTerminalButton("[ REBUILD ]", UDim2.new(0.32, -4, 1, 0), UDim2.new(0.38, 2, 0, 0), THEME.AccentGold)
local UnloadBtn = makeTerminalButton("[ UNLOAD ]", UDim2.new(0.30, 0, 1, 0), UDim2.new(0.70, 4, 0, 0), THEME.TextMuted)

-- Console / Verification Log Box
local LogHeader = Instance.new("TextLabel")
LogHeader.Size = UDim2.new(1, -16, 0, 18)
LogHeader.Position = UDim2.fromOffset(8, 150)
LogHeader.BackgroundTransparency = 1
LogHeader.Font = Enum.Font.Code
LogHeader.TextSize = 11
LogHeader.TextColor3 = THEME.TextMuted
LogHeader.TextXAlignment = Enum.TextXAlignment.Left
LogHeader.Text = "-- TERMINAL OUTPUT & VERIFICATION --"
LogHeader.Parent = ContentPanel

local LogBox = Instance.new("ScrollingFrame")
LogBox.Size = UDim2.new(1, -16, 1, -176)
LogBox.Position = UDim2.fromOffset(8, 168)
LogBox.BackgroundColor3 = THEME.Bg
LogBox.BorderSizePixel = 0
LogBox.ScrollBarThickness = 3
LogBox.ScrollBarImageColor3 = THEME.AccentRed
LogBox.CanvasSize = UDim2.new(0, 0, 0, 0)
LogBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogBox.Parent = ContentPanel
addStroke(LogBox, THEME.BorderDim, 1)

local LogLayout = Instance.new("UIListLayout")
LogLayout.Padding = UDim.new(0, 2)
LogLayout.Parent = LogBox

local LogPad = Instance.new("UIPadding")
LogPad.PaddingTop = UDim.new(0, 4)
LogPad.PaddingLeft = UDim.new(0, 6)
LogPad.PaddingRight = UDim.new(0, 6)
LogPad.Parent = LogBox

-- Bottom Tip of the Day Footer
local TipBar = Instance.new("TextLabel")
TipBar.Size = UDim2.new(1, -20, 0, 22)
TipBar.Position = UDim2.new(0, 10, 1, -26)
TipBar.BackgroundColor3 = THEME.Bg
TipBar.BorderSizePixel = 0
TipBar.Font = Enum.Font.Code
TipBar.TextSize = 11
TipBar.TextColor3 = THEME.AccentGold
TipBar.TextXAlignment = Enum.TextXAlignment.Left
TipBar.TextTruncate = Enum.TextTruncate.AtEnd
TipBar.Text = " " .. TIPS[math.random(1, #TIPS)]
TipBar.Parent = Body
addStroke(TipBar, THEME.BorderDim, 1)

-- ============================================================================
-- LOGGING & VERIFICATION HELPERS
-- ============================================================================
local function logLine(msg, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 11
	lbl.TextColor3 = color or THEME.TextMain
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Text = "> " .. tostring(msg)
	lbl.Parent = LogBox

	-- Auto-scroll to bottom
	task.defer(function()
		LogBox.CanvasPosition = Vector2.new(0, LogBox.AbsoluteCanvasSize.Y)
	end)
end

-- ============================================================================
-- DRAGGING & MINIMIZE
-- ============================================================================
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TitleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Body.Visible = not minimized
	MainFrame.Size = minimized and UDim2.fromOffset(540, 28) or UDim2.fromOffset(540, 380)
	MinBtn.Text = minimized and "+" or "-"
end)

-- ============================================================================
-- LOADER ENGINE (HTTP, COMPILE, CLEANUP, REBUILD)
-- ============================================================================
local activeController = nil
local isBusy = false
local selectedChar = CHARACTERS[1]

local function cleanupActiveRig()
	local cleaned = 0

	if type(activeController) == "table" and type(activeController.cleanup) == "function" then
		local ok, err = pcall(activeController.cleanup)
		if ok then
			cleaned += 1
		else
			logLine("Controller cleanup error: " .. tostring(err), THEME.AccentRed)
		end
	elseif type(activeController) == "function" then
		pcall(activeController)
		cleaned += 1
	end
	activeController = nil

	if type(_G.ULTRAKILL_F3X) == "table" and type(_G.ULTRAKILL_F3X.cleanup) == "function" then
		pcall(_G.ULTRAKILL_F3X.cleanup)
		_G.ULTRAKILL_F3X = nil
		cleaned += 1
	end

	for _, globalName in ipairs(LEGACY_CLEANUP_GLOBALS) do
		local fn = _G[globalName]
		if type(fn) == "function" then
			local ok, err = pcall(fn)
			if ok then
				cleaned += 1
			else
				logLine(globalName .. " error: " .. tostring(err), THEME.AccentRed)
			end
			_G[globalName] = nil
		end
	end

	for _, globalName in ipairs(LEGACY_REBUILD_GLOBALS) do
		_G[globalName] = nil
	end

	if cleaned > 0 then
		logLine("Cleaned up previous rig (" .. cleaned .. " hook(s)).", THEME.TextMuted)
	end
end

local function fetchAndCompile(relPath)
	local cacheBuster = HttpService:GenerateGUID(false) .. "_" .. tostring(math.floor(os.clock() * 1000))
	local url = BASE_URL .. relPath .. "?t=" .. cacheBuster
	logLine("GET " .. relPath .. " ...", THEME.TextMuted)

	local okHttp, source = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not okHttp or type(source) ~= "string" or #source == 0 then
		return nil, "HTTP fetch failed: " .. tostring(source)
	end

	local head = source:sub(1, 32)
	if head:find("404: Not Found", 1, true) or head:find("400: Invalid", 1, true) then
		return nil, "Remote returned error: " .. head
	end

	local fn, compileErr = loadstring(source, "@" .. relPath)
	if not fn then
		return nil, "Compile error: " .. tostring(compileErr)
	end

	return fn, nil
end

local function deployCharacter(charData)
	if isBusy then
		logLine("Terminal busy. Wait for current operation.", THEME.AccentGold)
		return
	end
	if not charData.unlocked or not charData.path then
		logLine(charData.name .. " is locked / not yet deployed.", THEME.AccentGold)
		return
	end

	isBusy = true
	cleanupActiveRig()

	-- 1. Load core.lua if present
	local coreFn, coreErr = fetchAndCompile("core.lua")
	if coreFn then
		local okCore, coreRes = pcall(coreFn)
		if not okCore then
			logLine("core.lua runtime error: " .. tostring(coreRes), THEME.AccentRed)
			isBusy = false
			return
		end
		logLine("core.lua initialized.", THEME.SuccessGreen)
	else
		logLine("core.lua skipped (" .. tostring(coreErr) .. ")", THEME.AccentGold)
	end

	-- 2. Load character module
	local charFn, charErr = fetchAndCompile(charData.path)
	if not charFn then
		logLine(tostring(charErr), THEME.AccentRed)
		isBusy = false
		return
	end

	local okRun, result = pcall(charFn)
	if not okRun then
		logLine("Runtime error in " .. charData.path .. ": " .. tostring(result), THEME.AccentRed)
		isBusy = false
		return
	end

	activeController = result
	logLine("DEPLOYED: " .. charData.name .. " ACTIVE.", THEME.SuccessGreen)
	isBusy = false
end

local function triggerRebuild()
	if type(activeController) == "table" and type(activeController.rebuild) == "function" then
		local ok, err = pcall(activeController.rebuild)
		logLine(ok and "Rebuild triggered via controller." or ("Rebuild error: " .. tostring(err)), ok and THEME.SuccessGreen or THEME.AccentRed)
		return
	end

	if type(_G.ULTRAKILL_F3X) == "table" and type(_G.ULTRAKILL_F3X.rebuild) == "function" then
		local ok, err = pcall(_G.ULTRAKILL_F3X.rebuild)
		logLine(ok and "Rebuild triggered via _G.ULTRAKILL_F3X." or ("Rebuild error: " .. tostring(err)), ok and THEME.SuccessGreen or THEME.AccentRed)
		return
	end

	for _, globalName in ipairs(LEGACY_REBUILD_GLOBALS) do
		local fn = _G[globalName]
		if type(fn) == "function" then
			local ok, err = pcall(fn)
			logLine(ok and ("Rebuild triggered (" .. globalName .. ").") or ("Rebuild error: " .. tostring(err)), ok and THEME.SuccessGreen or THEME.AccentRed)
			return
		end
	end

	logLine("No active rebuild hook found. Redeploying " .. selectedChar.name .. "...", THEME.AccentGold)
	task.spawn(function()
		deployCharacter(selectedChar)
	end)
end

-- ============================================================================
-- POPULATE SIDEBAR & WIRE BUTTONS
-- ============================================================================
local sideButtons = {}

local function selectCharacter(charData)
	selectedChar = charData
	SelectedTitle.Text = "-- " .. charData.name .. " --"
	SelectedSub.Text = charData.subtitle
	SelectedDesc.Text = charData.desc

	for _, entry in ipairs(sideButtons) do
		local isSel = (entry.data.id == charData.id)
		entry.btn.BackgroundColor3 = isSel and THEME.AccentRed or (entry.data.unlocked and THEME.BtnIdle or THEME.BtnLocked)
		entry.btn.TextColor3 = isSel and THEME.TextMain or (entry.data.unlocked and THEME.TextMain or THEME.TextMuted)
	end
end

for _, charData in ipairs(CHARACTERS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = charData.unlocked and THEME.BtnIdle or THEME.BtnLocked
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = 13
	btn.TextColor3 = charData.unlocked and THEME.TextMain or THEME.TextMuted
	btn.Text = charData.unlocked and (" " .. charData.name) or (" [X] " .. charData.name)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Parent = SideList
	addStroke(btn, THEME.BorderDim, 1)

	table.insert(sideButtons, { data = charData, btn = btn })
	btn.MouseButton1Click:Connect(function()
		selectCharacter(charData)
	end)
end

DeployBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		deployCharacter(selectedChar)
	end)
end)

RebuildBtn.MouseButton1Click:Connect(function()
	task.spawn(triggerRebuild)
end)

UnloadBtn.MouseButton1Click:Connect(function()
	cleanupActiveRig()
	logLine("All active rigs unloaded.", THEME.AccentGold)
end)

CloseBtn.MouseButton1Click:Connect(function()
	cleanupActiveRig()
	ScreenGui:Destroy()
end)

-- Initialize view
selectCharacter(CHARACTERS[1])
logLine("SmileOS 2.0 Terminal ready.", THEME.SuccessGreen)
logLine("Select a machine and press [ DEPLOY ].", THEME.TextMuted)