-- ULTRAKILL // F3X TERMINAL LOADER (SmileOS 2.0 Style) + INTEGRATED ANTI-GRIEF
-- Repo: https://github.com/thatonexploiter/ultrakill-f3x

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
local BASE_URL = "https://raw.githubusercontent.com/thatonexploiter/ultrakill-f3x/main/"

-- ============================================================================
-- CLEANUP PREVIOUS TERMINAL INSTANCE IF RE-EXECUTED
-- ============================================================================
if type(env.ULTRAKILL_TERMINAL_CLEANUP) == "function" then
	pcall(env.ULTRAKILL_TERMINAL_CLEANUP)
elseif type(_G.ULTRAKILL_TERMINAL_CLEANUP) == "function" then
	pcall(_G.ULTRAKILL_TERMINAL_CLEANUP)
end

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
	InfoBlue = Color3.fromRGB(70, 145, 225),
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
	"TIP OF THE DAY: USE [ REBUILD ] IF YOUR CHARACTER RESPAWNS OR DESYNCS.",
	"TIP OF THE DAY: PREPARE THYSELF — PRESS [X] AS MINOS PRIME TO UNLEASH PHASE 2.",
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
		path = "characters/minos.lua",
		unlocked = true,
		desc = "Translucent Prime Soul with exposed red heart, circulatory veins, hollow face void, prism crown, forearm serpents, and full P-1 moveset.",
	},
}

-- ============================================================================
-- GLOBAL CONTROLLER & CLEANUP HOOKS (matches core.lua env)
-- ============================================================================
local LEGACY_CLEANUP_GLOBALS = {
	"F3XV1ReanimCleanup",
	"F3XV2ReanimCleanup",
	"F3XR6ReanimCleanup",
	"F3XMinosReanimCleanup",
	"F3XMayhemIdleCleanup",
}

local LEGACY_REBUILD_GLOBALS = {
	"F3XV1ReanimRebuild",
	"F3XV2ReanimRebuild",
	"F3XR6ReanimRebuild",
	"F3XMinosReanimRebuild",
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

local guiParent = getGuiParent()
local existing = guiParent:FindFirstChild("ULTRAKILL_F3X_TERMINAL")
if existing then
	existing:Destroy()
end

-- ============================================================================
-- LIFECYCLE & SHARED CONNECTIONS
-- ============================================================================
local terminalAlive = true
local connections = {}
local function trackConn(conn)
	table.insert(connections, conn)
	return conn
end

-- ============================================================================
-- BUILD MAIN UI (SMILEOS 2.0 TERMINAL)
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

local function makeDraggable(handle, window)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	trackConn(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end))
	trackConn(handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	trackConn(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			local absW, absH = window.AbsoluteSize.X, window.AbsoluteSize.Y
			local baseX = startPos.X.Scale * vp.X + startPos.X.Offset + delta.X
			local baseY = startPos.Y.Scale * vp.Y + startPos.Y.Offset + delta.Y
			local clampedX = math.clamp(baseX, 4, math.max(4, vp.X - absW - 4))
			local clampedY = math.clamp(baseY, 4, math.max(4, vp.Y - absH - 4))
			window.Position = UDim2.fromOffset(clampedX, clampedY)
		end
	end))
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "TerminalWindow"
MainFrame.Size = UDim2.fromOffset(540, 380)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -190)
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
addStroke(MainFrame, THEME.BorderWhite, 2)

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

local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -28)
Body.Position = UDim2.fromOffset(0, 28)
Body.BackgroundTransparency = 1
Body.Parent = MainFrame

-- Left Sidebar: --MACHINES-- + Anti-Grief option at bottom
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
SideList.Size = UDim2.new(1, -8, 1, -68)
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

local SideDivider = Instance.new("Frame")
SideDivider.Size = UDim2.new(1, -12, 0, 1)
SideDivider.Position = UDim2.new(0, 6, 1, -36)
SideDivider.BackgroundColor3 = THEME.BorderDim
SideDivider.BorderSizePixel = 0
SideDivider.Parent = Sidebar

local AntiGriefBtn = Instance.new("TextButton")
AntiGriefBtn.Name = "AntiGriefOption"
AntiGriefBtn.Size = UDim2.new(1, -8, 0, 28)
AntiGriefBtn.Position = UDim2.new(0, 4, 1, -32)
AntiGriefBtn.BackgroundColor3 = THEME.BtnIdle
AntiGriefBtn.BorderSizePixel = 0
AntiGriefBtn.Font = Enum.Font.Code
AntiGriefBtn.TextSize = 12
AntiGriefBtn.TextColor3 = THEME.TextMuted
AntiGriefBtn.Text = "Anti-Grief"
AntiGriefBtn.AutoButtonColor = false
AntiGriefBtn.Parent = Sidebar
local agBtnStroke = addStroke(AntiGriefBtn, THEME.BorderDim, 1)

-- Right Main Panel
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

local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -16, 0, 34)
ActionRow.Position = UDim2.fromOffset(8, 108)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = ContentPanel

local function makeTerminalButton(parent, text, size, pos, accentColor, textSize)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = THEME.BtnIdle
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = textSize or 13
	btn.TextColor3 = accentColor or THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.Parent = parent
	local stroke = addStroke(btn, accentColor or THEME.BorderWhite, 1.5)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnHover }):Play()
		stroke.Color = THEME.BorderWhite
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnIdle }):Play()
		stroke.Color = accentColor or THEME.BorderWhite
	end)
	return btn, stroke
end

local DeployBtn = makeTerminalButton(ActionRow, "[ DEPLOY ]", UDim2.new(0.38, -4, 1, 0), UDim2.fromScale(0, 0), THEME.AccentRed)
local RebuildBtn = makeTerminalButton(ActionRow, "[ REBUILD ]", UDim2.new(0.32, -4, 1, 0), UDim2.new(0.38, 2, 0, 0), THEME.AccentGold)
local UnloadBtn = makeTerminalButton(ActionRow, "[ UNLOAD ]", UDim2.new(0.30, 0, 1, 0), UDim2.new(0.70, 4, 0, 0), THEME.TextMuted)

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
-- TERMINAL LOGGING & MAIN WINDOW CONTROLS
-- ============================================================================
local function logLine(msg, color)
	if not LogBox or not LogBox.Parent then return end
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

	task.defer(function()
		if LogBox and LogBox.Parent then
			LogBox.CanvasPosition = Vector2.new(0, LogBox.AbsoluteCanvasSize.Y)
		end
	end)
end

makeDraggable(TitleBar, MainFrame)

local minimized = false
MinBtn.Activated:Connect(function()
	minimized = not minimized
	Body.Visible = not minimized
	TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = minimized and UDim2.fromOffset(540, 28) or UDim2.fromOffset(540, 380),
	}):Play()
	MinBtn.Text = minimized and "+" or "-"
end)

-- ============================================================================
-- INTEGRATED ANTI-GRIEF ENGINE (SENTINEL PRO + CHARACTER/RIG GUARD)
-- ============================================================================
local AG_CONFIG = {
	BatchSize = 75,
	WorkerInterval = 0.18,
	TamperSliceSize = 220,
	TamperInterval = 0.06,
	GiantSizeThreshold = 120,
	FloodRateWindow = 1.0,
	FloodRateThreshold = 8,
	VoidThresholdY = -120,
	FlingVelocityThreshold = 145,
	ClearRadius = 45,
	MaxLogEntries = 80,
}

local FILTER_MODES = { "Effects Only", "Smart Threats", "Strict Lockdown" }

local agState = {
	windowOpen = false,
	windowMinimized = false,
	activeSlot = 1,
	snapshots = { [1] = nil, [2] = nil, [3] = nil },
	whitelist = { [LocalPlayer.UserId] = true },
	liveGuard = false,
	autoClean = true,
	filterModeIndex = 2,
	antiFling = true,
	antiVoid = true,
	charShield = true,
	autoLockAfterRestore = false,
	isBusy = false,
	threatsBlocked = 0,
	restoresPerformed = 0,
	scanCursor = 1,
	lastSafeCFrame = nil,
	f3xRequestedThisLife = false,
	rigDeployGraceUntil = 0,
}

local cachedEndpoint = nil
local selfRestoringDepth = 0
local scriptManagedParts = setmetatable({}, { __mode = "k" })
local protectedRigInstances = setmetatable({}, { __mode = "k" })
local cagedPartsByUserId = {}
local recentSpawnTimestamps = {}

local pendingRemove = {}
local pendingDeleted = {}
local pendingTampered = {}
local pendingCharUndo = {}
local agLogs = {}

local SPAM_EFFECT_CLASSES = {
	Decal = true,
	Texture = true,
	Fire = true,
	Smoke = true,
	Sparkles = true,
	ParticleEmitter = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	Beam = true,
	Trail = true,
	Explosion = true,
	Sound = true,
	Highlight = true,
	SelectionBox = true,
	SelectionSphere = true,
	ForceField = true,
}

local EXTRA_DECOR_CLASSES = {
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	SurfaceGui = true,
	BillboardGui = true,
	SurfaceAppearance = true,
	Shirt = true,
	Pants = true,
	ShirtGraphic = true,
}

local STANDARD_CHAR_PART_NAMES = {
	HumanoidRootPart = true,
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,
	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
	Handle = true,
}

local CRITICAL_CHAR_PART_NAMES = {
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	HumanoidRootPart = true,
}

local CRITICAL_JOINT_NAMES = {
	Neck = true,
	RootJoint = true,
	Waist = true,
	["Left Shoulder"] = true,
	["Right Shoulder"] = true,
	["Left Hip"] = true,
	["Right Hip"] = true,
}

local agLogEvent
local agUpdateTelemetry
local agUpdateStatus
local agRefreshRadar

local function getActiveSnapshot()
	return agState.snapshots[agState.activeSlot]
end

local function getFilterMode()
	return FILTER_MODES[agState.filterModeIndex]
end

local function isRigDeployGraceActive()
	return os.clock() < agState.rigDeployGraceUntil
end

local function markRigDeployGrace(seconds)
	agState.rigDeployGraceUntil = math.max(agState.rigDeployGraceUntil, os.clock() + (seconds or 3.0))
end

local function cframeDiffers(a, b)
	if (a.Position - b.Position).Magnitude > 0.04 then return true end
	if (a.LookVector - b.LookVector).Magnitude > 0.015 then return true end
	if (a.UpVector - b.UpVector).Magnitude > 0.015 then return true end
	return false
end

local function sizeDiffers(a, b)
	return (a - b).Magnitude > 0.03
end

local function colorDiffers(a, b)
	return math.abs(a.R - b.R) > 0.008 or math.abs(a.G - b.G) > 0.008 or math.abs(a.B - b.B) > 0.008
end

local function getPartTypeName(part)
	if part:IsA("TrussPart") then
		return "Truss"
	elseif part:IsA("VehicleSeat") then
		return "Vehicle Seat"
	elseif part:IsA("Seat") then
		return "Seat"
	elseif part:IsA("SpawnLocation") then
		return "Spawn"
	elseif part:IsA("WedgePart") then
		return "Wedge"
	elseif part:IsA("CornerWedgePart") then
		return "Corner"
	elseif part:IsA("Part") then
		local ok, shape = pcall(function() return part.Shape end)
		if ok and shape then
			if shape.Name == "Ball" then return "Ball" end
			if shape.Name == "Cylinder" then return "Cylinder" end
			if shape.Name == "Wedge" then return "Wedge" end
			if shape.Name == "CornerWedge" then return "Corner" end
		end
	end
	return "Normal"
end

local function isPlayerCharacterDescendant(inst)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and (inst == plr.Character or inst:IsDescendantOf(plr.Character)) then
			return true, plr
		end
	end
	return false, nil
end

local function isProtectedWorldSystem(inst)
	if inst:IsA("Terrain") or inst:IsA("Camera") then
		return true
	end
	if workspace.CurrentCamera and (inst == workspace.CurrentCamera or inst:IsDescendantOf(workspace.CurrentCamera)) then
		return true
	end
	return false
end

local function isOwnRigPart(inst)
	if protectedRigInstances[inst] then return true end
	local anc = inst.Parent
	while anc and anc ~= workspace do
		if protectedRigInstances[anc] then
			return true
		end
		anc = anc.Parent
	end
	return false
end

local function isWhitelistedPlayerNearby(pos, radius)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and agState.whitelist[plr.UserId] and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - pos).Magnitude <= (radius or 26) then
				return true
			end
		end
	end
	return false
end

local function getRecentSpawnRate()
	local now = os.clock()
	local kept = {}
	for _, t in ipairs(recentSpawnTimestamps) do
		if now - t <= AG_CONFIG.FloodRateWindow then
			table.insert(kept, t)
		end
	end
	recentSpawnTimestamps = kept
	return #kept
end

local function findF3XInContainer(container)
	if not container then return nil, nil end
	for _, item in ipairs(container:GetChildren()) do
		local syncAPI = item:FindFirstChild("SyncAPI") or item:FindFirstChild("SyncApi")
		if syncAPI then
			local endpoint = syncAPI:FindFirstChild("ServerEndpoint") or syncAPI:FindFirstChild("ServerControl")
			if endpoint and endpoint:IsA("RemoteFunction") then
				return endpoint, item
			end
		end
	end
	for _, desc in ipairs(container:GetDescendants()) do
		if desc.Name == "SyncAPI" or desc.Name == "SyncApi" then
			local endpoint = desc:FindFirstChild("ServerEndpoint") or desc:FindFirstChild("ServerControl")
			if endpoint and endpoint:IsA("RemoteFunction") then
				return endpoint, desc.Parent
			end
		end
	end
	return nil, nil
end

local function getF3XEndpoint(allowAutoRequest)
	if cachedEndpoint and cachedEndpoint.Parent and cachedEndpoint:IsDescendantOf(game) then
		return cachedEndpoint
	end
	cachedEndpoint = nil

	local containers = {
		LocalPlayer.Character,
		LocalPlayer:FindFirstChild("Backpack"),
		LocalPlayer:FindFirstChild("PlayerGui"),
		LocalPlayer:FindFirstChild("StarterGear"),
		ReplicatedStorage,
	}

	for _, c in ipairs(containers) do
		local ep = findF3XInContainer(c)
		if ep then
			cachedEndpoint = ep
			return ep
		end
	end

	if allowAutoRequest and not agState.f3xRequestedThisLife then
		agState.f3xRequestedThisLife = true
		pcall(function()
			Players:Chat(":f3x")
		end)
	end

	return nil
end

local function playerHasF3X(plr)
	if not plr then return false, false end
	local equipped = findF3XInContainer(plr.Character) ~= nil
	local inPack = findF3XInContainer(plr:FindFirstChild("Backpack")) ~= nil
	return (equipped or inPack), equipped
end

local function batchInvoke(endpoint, action, list, chunkSize)
	if not endpoint or not list or #list == 0 then return true end
	local step = chunkSize or AG_CONFIG.BatchSize
	local allOk = true
	for i = 1, #list, step do
		if not terminalAlive then break end
		local chunk = {}
		for j = i, math.min(i + step - 1, #list) do
			table.insert(chunk, list[j])
		end
		local ok = pcall(function()
			endpoint:InvokeServer(action, chunk)
		end)
		if not ok then allOk = false end
		if #list > step * 3 then
			task.wait()
		end
	end
	return allOk
end

local function batchRemove(endpoint, objects)
	if not endpoint or not objects or #objects == 0 then return 0 end
	local valid = {}
	for _, obj in ipairs(objects) do
		if obj and obj.Parent ~= nil and not isProtectedWorldSystem(obj) and not isOwnRigPart(obj) then
			table.insert(valid, obj)
		end
	end
	if #valid == 0 then return 0 end
	batchInvoke(endpoint, "Remove", valid, AG_CONFIG.BatchSize)
	return #valid
end

local function batchLockParts(endpoint, partsList, locked)
	if not endpoint or #partsList == 0 then return false end
	local step = AG_CONFIG.BatchSize
	for i = 1, #partsList, step do
		local chunk = {}
		for j = i, math.min(i + step - 1, #partsList) do
			if partsList[j] and partsList[j].Parent ~= nil then
				table.insert(chunk, partsList[j])
			end
		end
		if #chunk > 0 then
			pcall(function()
				endpoint:InvokeServer("SetLocked", chunk, locked)
			end)
		end
	end
	return true
end

local function beginSelfRestoring()
	selfRestoringDepth += 1
end

local function endSelfRestoring()
	task.delay(0.35, function()
		selfRestoringDepth = math.max(0, selfRestoringDepth - 1)
	end)
end

local function capturePartData(part)
	return {
		CFrame = part.CFrame,
		Size = part.Size,
		Color = part.Color,
		Material = part.Material,
		Transparency = part.Transparency,
		Reflectance = part.Reflectance,
		Anchored = part.Anchored,
		CanCollide = part.CanCollide,
		Locked = part.Locked,
		Name = part.Name,
		Parent = part.Parent,
		ShapeType = getPartTypeName(part),
	}
end

local function rebuildPartList(snap)
	local list = {}
	for part in pairs(snap.parts) do
		table.insert(list, part)
	end
	snap.partList = list
	agState.scanCursor = 1
end

local function takeSnapshot(slotIndex)
	local idx = slotIndex or agState.activeSlot
	local parts = {}
	local partList = {}
	local effects = {}
	local count = 0

	for _, desc in ipairs(workspace:GetDescendants()) do
		if not isProtectedWorldSystem(desc) and not scriptManagedParts[desc] and not isOwnRigPart(desc) then
			local isChar = isPlayerCharacterDescendant(desc)
			if not isChar then
				if desc:IsA("BasePart") then
					parts[desc] = capturePartData(desc)
					table.insert(partList, desc)
					count += 1
				elseif SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName] then
					effects[desc] = true
				end
			end
		end
	end

	agState.snapshots[idx] = {
		parts = parts,
		partList = partList,
		effects = effects,
		count = count,
		timestamp = os.date("%H:%M:%S"),
	}
	agState.scanCursor = 1

	agLogEvent("Snapshot Slot " .. idx .. " saved (" .. count .. " parts)", "INFO")
	if agUpdateTelemetry then agUpdateTelemetry() end
	return count
end

local function adoptNewPartsIntoSnapshot()
	local snap = getActiveSnapshot()
	if not snap then
		return takeSnapshot(agState.activeSlot), 0
	end

	local addedParts, addedEffects = 0, 0
	for _, desc in ipairs(workspace:GetDescendants()) do
		if not isProtectedWorldSystem(desc) and not scriptManagedParts[desc] and not isOwnRigPart(desc) then
			local isChar = isPlayerCharacterDescendant(desc)
			if not isChar then
				if desc:IsA("BasePart") and not snap.parts[desc] then
					snap.parts[desc] = capturePartData(desc)
					table.insert(snap.partList, desc)
					snap.count += 1
					addedParts += 1
				elseif (SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName]) and not snap.effects[desc] then
					snap.effects[desc] = true
					addedEffects += 1
				end
			end
		end
	end
	snap.timestamp = os.date("%H:%M:%S")
	agLogEvent("Adopted +" .. addedParts .. " parts, +" .. addedEffects .. " fx into S" .. agState.activeSlot, "INFO")
	if agUpdateTelemetry then agUpdateTelemetry() end
	return addedParts, addedEffects
end

local function computeMapDiff(snap)
	if not snap then return nil end

	local diff = {
		moved = {},
		resized = {},
		recolored = {},
		rematerialed = {},
		reanchored = {},
		recollided = {},
		deleted = {},
		foreignParts = {},
		foreignEffects = {},
	}

	for part, data in pairs(snap.parts) do
		if not part or part.Parent == nil or not part:IsDescendantOf(workspace) then
			table.insert(diff.deleted, part)
		else
			if cframeDiffers(part.CFrame, data.CFrame) then
				table.insert(diff.moved, { Part = part, CFrame = data.CFrame })
			end
			if sizeDiffers(part.Size, data.Size) then
				table.insert(diff.resized, { Part = part, Size = data.Size, CFrame = data.CFrame })
			end
			if colorDiffers(part.Color, data.Color) then
				table.insert(diff.recolored, { Part = part, Color = data.Color })
			end
			if part.Material ~= data.Material
				or math.abs(part.Transparency - data.Transparency) > 0.01
				or math.abs(part.Reflectance - data.Reflectance) > 0.01 then
				table.insert(diff.rematerialed, {
					Part = part,
					Material = data.Material,
					Transparency = data.Transparency,
					Reflectance = data.Reflectance,
				})
			end
			if part.Anchored ~= data.Anchored then
				table.insert(diff.reanchored, { Part = part, Anchored = data.Anchored })
			end
			if part.CanCollide ~= data.CanCollide then
				table.insert(diff.recollided, { Part = part, CanCollide = data.CanCollide })
			end
		end
	end

	for _, desc in ipairs(workspace:GetDescendants()) do
		if not isProtectedWorldSystem(desc) and not scriptManagedParts[desc] and not isOwnRigPart(desc) then
			local isChar = isPlayerCharacterDescendant(desc)
			if not isChar then
				if desc:IsA("BasePart") and not snap.parts[desc] then
					table.insert(diff.foreignParts, desc)
				elseif (SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName]) and not snap.effects[desc] then
					table.insert(diff.foreignEffects, desc)
				end
			end
		end
	end

	return diff
end

local function isSuspiciousPart(part, strictMode)
	if not part or not part:IsA("BasePart") then return false end
	if isProtectedWorldSystem(part) or scriptManagedParts[part] or isOwnRigPart(part) then return false end

	local isChar, charPlr = isPlayerCharacterDescendant(part)
	if isChar then
		if charPlr == LocalPlayer and agState.charShield and not isRigDeployGraceActive() then
			if not STANDARD_CHAR_PART_NAMES[part.Name] and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool") then
				return true, "Attached to Self"
			end
		end
		return false
	end

	local snap = getActiveSnapshot()
	if snap and snap.parts[part] then
		return false
	end

	if strictMode and snap then
		return true, "Strict Lockdown"
	end

	local sz = part.Size
	local maxAxis = math.max(sz.X, sz.Y, sz.Z)
	if maxAxis >= AG_CONFIG.GiantSizeThreshold then
		if not isWhitelistedPlayerNearby(part.Position, 65) then
			return true, "Oversized Block"
		end
	end

	if not part.Anchored then
		local rate = getRecentSpawnRate()
		if rate >= AG_CONFIG.FloodRateThreshold and not isWhitelistedPlayerNearby(part.Position, 30) then
			return true, "Unanchored Flood"
		end
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (part.Position - hrp.Position).Magnitude < 16 and part.AssemblyLinearVelocity.Magnitude > 35 then
			return true, "Fling Projectile"
		end
	end

	if part.Transparency >= 0.85 and part.CanCollide and maxAxis >= 8 then
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (part.Position - hrp.Position).Magnitude < 25 and not isWhitelistedPlayerNearby(part.Position, 20) then
			return true, "Invisible Trap"
		end
	end

	return false
end

local function isSpamEffect(inst)
	if not inst or not inst.Parent then return false end
	if isProtectedWorldSystem(inst) or scriptManagedParts[inst] or isOwnRigPart(inst) then return false end

	local isChar, charPlr = isPlayerCharacterDescendant(inst)
	if isChar then
		if charPlr == LocalPlayer and agState.charShield and not isRigDeployGraceActive() and SPAM_EFFECT_CLASSES[inst.ClassName] then
			return true
		end
		return false
	end

	local snap = getActiveSnapshot()
	if snap then
		if snap.effects[inst] then return false end
		return SPAM_EFFECT_CLASSES[inst.ClassName] or EXTRA_DECOR_CLASSES[inst.ClassName] or false
	end

	return SPAM_EFFECT_CLASSES[inst.ClassName] or false
end

local function createFallbackBaseplate(endpoint, position)
	if not endpoint or not position then return false end
	beginSelfRestoring()
	local cf = CFrame.new(position.X, position.Y - 8, position.Z)
	local ok, plate = pcall(function()
		return endpoint:InvokeServer("CreatePart", "Normal", cf, workspace)
	end)
	if ok and plate and typeof(plate) == "Instance" then
		scriptManagedParts[plate] = true
		pcall(function()
			endpoint:InvokeServer("SyncAnchor", { { Part = plate, Anchored = true } })
			endpoint:InvokeServer("SyncResize", { { Part = plate, Size = Vector3.new(256, 8, 256), CFrame = cf } })
			endpoint:InvokeServer("SyncColor", { { Part = plate, Color = Color3.fromRGB(45, 45, 50) } })
			endpoint:InvokeServer("SyncMaterial", { { Part = plate, Material = Enum.Material.SmoothPlastic, Transparency = 0.15, Reflectance = 0 } })
			endpoint:InvokeServer("SetName", { plate }, "SentinelRescuePad")
		end)
		endSelfRestoring()
		return true
	end
	endSelfRestoring()
	return false
end

local function purgeSpam(endpoint, includeForeignParts)
	if not endpoint then return 0, "F3X not found" end
	local toRemove = {}
	local mode = getFilterMode()
	local strict = (mode == "Strict Lockdown") or includeForeignParts
	local checkParts = (mode ~= "Effects Only") or includeForeignParts

	for _, desc in ipairs(workspace:GetDescendants()) do
		if isSpamEffect(desc) then
			table.insert(toRemove, desc)
		elseif checkParts and desc:IsA("BasePart") then
			if isSuspiciousPart(desc, strict) then
				table.insert(toRemove, desc)
			end
		end
	end

	local removed = batchRemove(endpoint, toRemove)
	if removed > 0 then
		agState.threatsBlocked += removed
		agLogEvent("Purged " .. removed .. " grief instances", "BLOCK")
		if agUpdateTelemetry then agUpdateTelemetry() end
	end
	return removed, "Purged " .. removed .. " items"
end

local function clearAroundPosition(endpoint, centerPos, radius)
	if not endpoint or not centerPos then return 0, "Missing target" end
	local snap = getActiveSnapshot()
	local toRemove = {}
	local r = radius or AG_CONFIG.ClearRadius

	for _, desc in ipairs(workspace:GetDescendants()) do
		if not isProtectedWorldSystem(desc) and not scriptManagedParts[desc] and not isOwnRigPart(desc) then
			local isChar = isPlayerCharacterDescendant(desc)
			if not isChar then
				if desc:IsA("BasePart") then
					if (not snap or not snap.parts[desc]) and (desc.Position - centerPos).Magnitude <= r then
						table.insert(toRemove, desc)
					end
				elseif SPAM_EFFECT_CLASSES[desc.ClassName] then
					local parentPart = desc:FindFirstAncestorWhichIsA("BasePart")
					if parentPart and (parentPart.Position - centerPos).Magnitude <= r then
						if not snap or not snap.effects[desc] then
							table.insert(toRemove, desc)
						end
					end
				end
			end
		end
	end

	local removed = batchRemove(endpoint, toRemove)
	agState.threatsBlocked += removed
	agLogEvent("Cleared " .. removed .. " items within " .. r .. " studs", "BLOCK")
	if agUpdateTelemetry then agUpdateTelemetry() end
	return removed, "Cleared " .. removed .. " items"
end

local function restorePartsList(endpoint, snap, targetParts)
	if not endpoint or not snap then return 0, 0 end
	beginSelfRestoring()

	local missing = {}
	local anchorBatch, resizeBatch, moveBatch, colorBatch, materialBatch, collideBatch = {}, {}, {}, {}, {}, {}
	local recreated = 0
	local undone = 0

	for _, part in ipairs(targetParts) do
		local data = snap.parts[part]
		if data then
			if not part or part.Parent == nil or not part:IsDescendantOf(workspace) then
				table.insert(missing, { oldPart = part, data = data })
			else
				if part.Anchored ~= data.Anchored then
					table.insert(anchorBatch, { Part = part, Anchored = data.Anchored })
				end
				if sizeDiffers(part.Size, data.Size) then
					table.insert(resizeBatch, { Part = part, Size = data.Size, CFrame = data.CFrame })
				elseif cframeDiffers(part.CFrame, data.CFrame) then
					table.insert(moveBatch, { Part = part, CFrame = data.CFrame })
				end
				if colorDiffers(part.Color, data.Color) then
					table.insert(colorBatch, { Part = part, Color = data.Color })
				end
				if part.Material ~= data.Material
					or math.abs(part.Transparency - data.Transparency) > 0.01
					or math.abs(part.Reflectance - data.Reflectance) > 0.01 then
					table.insert(materialBatch, {
						Part = part,
						Material = data.Material,
						Transparency = data.Transparency,
						Reflectance = data.Reflectance,
					})
				end
				if part.CanCollide ~= data.CanCollide then
					table.insert(collideBatch, { Part = part, CanCollide = data.CanCollide })
				end
			end
		end
	end

	if #missing > 0 then
		local undoCandidates = {}
		for _, entry in ipairs(missing) do
			if typeof(entry.oldPart) == "Instance" then
				table.insert(undoCandidates, entry.oldPart)
			end
		end
		if #undoCandidates > 0 then
			batchInvoke(endpoint, "UndoRemove", undoCandidates, AG_CONFIG.BatchSize)
		end

		for _, entry in ipairs(missing) do
			local oldPart = entry.oldPart
			local data = entry.data
			if oldPart and oldPart.Parent ~= nil and oldPart:IsDescendantOf(workspace) then
				undone += 1
				table.insert(anchorBatch, { Part = oldPart, Anchored = data.Anchored })
				table.insert(resizeBatch, { Part = oldPart, Size = data.Size, CFrame = data.CFrame })
				table.insert(moveBatch, { Part = oldPart, CFrame = data.CFrame })
				table.insert(colorBatch, { Part = oldPart, Color = data.Color })
				table.insert(materialBatch, {
					Part = oldPart,
					Material = data.Material,
					Transparency = data.Transparency,
					Reflectance = data.Reflectance,
				})
				table.insert(collideBatch, { Part = oldPart, CanCollide = data.CanCollide })
			else
				local safeParent = (data.Parent and data.Parent.Parent and data.Parent:IsDescendantOf(workspace)) and data.Parent or workspace
				local ok, newPart = pcall(function()
					return endpoint:InvokeServer("CreatePart", data.ShapeType or "Normal", data.CFrame, safeParent)
				end)
				if ok and newPart and typeof(newPart) == "Instance" then
					recreated += 1
					snap.parts[oldPart] = nil
					snap.parts[newPart] = data

					table.insert(anchorBatch, { Part = newPart, Anchored = data.Anchored })
					table.insert(resizeBatch, { Part = newPart, Size = data.Size, CFrame = data.CFrame })
					table.insert(colorBatch, { Part = newPart, Color = data.Color })
					table.insert(materialBatch, {
						Part = newPart,
						Material = data.Material,
						Transparency = data.Transparency,
						Reflectance = data.Reflectance,
					})
					table.insert(collideBatch, { Part = newPart, CanCollide = data.CanCollide })
					if data.Name and data.Name ~= "Part" then
						pcall(function()
							endpoint:InvokeServer("SetName", { newPart }, data.Name)
						end)
					end
				end
			end
		end
	end

	batchInvoke(endpoint, "SyncAnchor", anchorBatch)
	batchInvoke(endpoint, "SyncResize", resizeBatch)
	batchInvoke(endpoint, "SyncMove", moveBatch)
	batchInvoke(endpoint, "SyncColor", colorBatch)
	batchInvoke(endpoint, "SyncMaterial", materialBatch)
	batchInvoke(endpoint, "SyncCollision", collideBatch)

	if recreated > 0 then
		rebuildPartList(snap)
	end

	if agState.autoLockAfterRestore then
		local toLock = {}
		for part in pairs(snap.parts) do
			if part and part.Parent ~= nil and not part.Locked then
				table.insert(toLock, part)
			end
		end
		batchLockParts(endpoint, toLock, true)
	end

	endSelfRestoring()
	return undone, recreated
end

local function fullRestoreMap(endpoint)
	if not endpoint then return "F3X not found" end
	local snap = getActiveSnapshot()
	if not snap then
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and createFallbackBaseplate(endpoint, hrp.Position) then
			return "No snapshot: spawned rescue pad"
		end
		return "No snapshot in Slot " .. agState.activeSlot
	end

	local allParts = {}
	for part in pairs(snap.parts) do
		table.insert(allParts, part)
	end

	local undone, recreated = restorePartsList(endpoint, snap, allParts)
	agState.restoresPerformed += 1
	local msg = ("Restored (Undone: %d, Rebuilt: %d)"):format(undone, recreated)
	agLogEvent(msg, "RESTORE")
	if agUpdateTelemetry then agUpdateTelemetry() end
	return msg
end

local function lockMap(endpoint, locked)
	if not endpoint then return "F3X not found" end
	local snap = getActiveSnapshot()
	local targets = {}
	if snap then
		for part in pairs(snap.parts) do
			if part and part.Parent ~= nil then
				table.insert(targets, part)
			end
		end
	else
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc:IsA("BasePart") and not isProtectedWorldSystem(desc) and not isPlayerCharacterDescendant(desc) then
				table.insert(targets, desc)
			end
		end
	end
	batchLockParts(endpoint, targets, locked)
	local verb = locked and "Locked " or "Unlocked "
	agLogEvent(verb .. #targets .. " parts", "INFO")
	return verb .. #targets .. " parts"
end

local function lockSelfCharacterParts(endpoint, locked)
	if not endpoint then return "F3X not found" end
	local char = LocalPlayer.Character
	if not char then return "No character" end
	local parts = {}
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end
	batchLockParts(endpoint, parts, locked)
	local msg = (locked and "Locked " or "Unlocked ") .. #parts .. " self parts"
	agLogEvent(msg, "SHIELD")
	return msg
end

local function rescueCharacter(endpoint)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return "No character" end

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	if agState.lastSafeCFrame then
		hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 4, 0)
		agLogEvent("Rescued to last safe position", "SHIELD")
		return "Teleported to safe spot"
	elseif endpoint then
		createFallbackBaseplate(endpoint, hrp.Position)
		hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 4, hrp.Position.Z)
		agLogEvent("Spawned emergency rescue pad", "SHIELD")
		return "Spawned rescue pad"
	end
	return "No safe spot or F3X"
end

local function cagePlayer(endpoint, targetPlayer)
	if not endpoint or not targetPlayer or not targetPlayer.Character then return "Target unavailable" end
	local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return "No target root" end

	if cagedPartsByUserId[targetPlayer.UserId] then
		batchRemove(endpoint, cagedPartsByUserId[targetPlayer.UserId])
		cagedPartsByUserId[targetPlayer.UserId] = nil
		agLogEvent("Uncaged " .. targetPlayer.Name, "INFO")
		return "Uncaged " .. targetPlayer.Name
	end

	beginSelfRestoring()
	local pos = hrp.Position
	local offsets = {
		{ cf = CFrame.new(pos + Vector3.new(0, 5.5, 0)), sz = Vector3.new(10, 1, 10) },
		{ cf = CFrame.new(pos + Vector3.new(0, -4.5, 0)), sz = Vector3.new(10, 1, 10) },
		{ cf = CFrame.new(pos + Vector3.new(5, 0.5, 0)), sz = Vector3.new(1, 10, 10) },
		{ cf = CFrame.new(pos + Vector3.new(-5, 0.5, 0)), sz = Vector3.new(1, 10, 10) },
		{ cf = CFrame.new(pos + Vector3.new(0, 0.5, 5)), sz = Vector3.new(10, 10, 1) },
		{ cf = CFrame.new(pos + Vector3.new(0, 0.5, -5)), sz = Vector3.new(10, 10, 1) },
	}

	local created = {}
	local anchorB, resizeB, colorB, matB = {}, {}, {}, {}

	for _, wall in ipairs(offsets) do
		local ok, p = pcall(function()
			return endpoint:InvokeServer("CreatePart", "Normal", wall.cf, workspace)
		end)
		if ok and p and typeof(p) == "Instance" then
			scriptManagedParts[p] = true
			table.insert(created, p)
			table.insert(anchorB, { Part = p, Anchored = true })
			table.insert(resizeB, { Part = p, Size = wall.sz, CFrame = wall.cf })
			table.insert(colorB, { Part = p, Color = Color3.fromRGB(220, 35, 35) })
			table.insert(matB, { Part = p, Material = Enum.Material.ForceField, Transparency = 0.45, Reflectance = 0 })
		end
	end

	batchInvoke(endpoint, "SyncAnchor", anchorB)
	batchInvoke(endpoint, "SyncResize", resizeB)
	batchInvoke(endpoint, "SyncColor", colorB)
	batchInvoke(endpoint, "SyncMaterial", matB)
	batchLockParts(endpoint, created, true)

	cagedPartsByUserId[targetPlayer.UserId] = created
	endSelfRestoring()
	agLogEvent("Caged " .. targetPlayer.Name, "BLOCK")
	return "Caged " .. targetPlayer.Name
end

local function destroyManagedArtifacts(endpoint)
	if not endpoint then return 0 end
	local toDel = {}
	for part in pairs(scriptManagedParts) do
		if part and part.Parent ~= nil then
			table.insert(toDel, part)
		end
	end
	table.clear(cagedPartsByUserId)
	return batchRemove(endpoint, toDel)
end

--// Character Part & Neck Motor6D Protection
local charWatchConns = {}
local function clearCharWatchConns()
	for _, c in ipairs(charWatchConns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(charWatchConns)
end

local function watchOwnCharacter(char)
	clearCharWatchConns()
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	table.insert(charWatchConns, char.DescendantRemoving:Connect(function(desc)
		if not terminalAlive or not agState.charShield then return end
		if isRigDeployGraceActive() or selfRestoringDepth > 0 then return end
		if hum and hum.Health <= 0 then return end
		if not char.Parent then return end

		if (desc:IsA("BasePart") and CRITICAL_CHAR_PART_NAMES[desc.Name])
			or (desc:IsA("Motor6D") and CRITICAL_JOINT_NAMES[desc.Name]) then
			pendingCharUndo[desc] = true
		end
	end))
end

if LocalPlayer.Character then
	watchOwnCharacter(LocalPlayer.Character)
end

trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
	agState.f3xRequestedThisLife = false
	cachedEndpoint = nil
	markRigDeployGrace(2.5)
	watchOwnCharacter(char)

	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end

	if agState.antiVoid and not getActiveSnapshot() then
		task.wait(0.35)
		local ep = getF3XEndpoint(true)
		if ep and hrp.Position.Y < -20 then
			createFallbackBaseplate(ep, hrp.Position)
		end
	end
end))

trackConn(workspace.DescendantAdded:Connect(function(desc)
	if not terminalAlive then return end

	if isRigDeployGraceActive() then
		if not isProtectedWorldSystem(desc) and not isPlayerCharacterDescendant(desc) then
			protectedRigInstances[desc] = true
		end
		return
	end

	if selfRestoringDepth > 0 or scriptManagedParts[desc] or isOwnRigPart(desc) then return end
	if isProtectedWorldSystem(desc) then return end

	if desc:IsA("BasePart") then
		table.insert(recentSpawnTimestamps, os.clock())
	end

	if not agState.autoClean then return end

	if isSpamEffect(desc) then
		pendingRemove[desc] = true
	elseif getFilterMode() ~= "Effects Only" and desc:IsA("BasePart") then
		if isSuspiciousPart(desc, getFilterMode() == "Strict Lockdown") then
			pendingRemove[desc] = true
		end
	end
end))

trackConn(workspace.DescendantRemoving:Connect(function(desc)
	if not terminalAlive or not agState.liveGuard or selfRestoringDepth > 0 or isRigDeployGraceActive() then return end
	local snap = getActiveSnapshot()
	if snap and snap.parts[desc] then
		pendingDeleted[desc] = true
	end
end))

local function hookPlayerTools(plr)
	local function watchContainer(c)
		if not c then return end
		trackConn(c.ChildAdded:Connect(function(child)
			if not terminalAlive then return end
			if child:FindFirstChild("SyncAPI") or child:FindFirstChild("SyncApi") then
				if plr ~= LocalPlayer then
					agLogEvent(plr.Name .. " equipped/received F3X", "WARN")
				end
				if agRefreshRadar and agState.windowOpen then task.defer(agRefreshRadar) end
			end
		end))
	end
	watchContainer(plr:FindFirstChild("Backpack"))
	if plr.Character then watchContainer(plr.Character) end
	trackConn(plr.CharacterAdded:Connect(function()
		watchContainer(plr.Character)
		watchContainer(plr:FindFirstChild("Backpack"))
	end))
end

for _, p in ipairs(Players:GetPlayers()) do
	hookPlayerTools(p)
end
trackConn(Players.PlayerAdded:Connect(function(p)
	hookPlayerTools(p)
	if agRefreshRadar and agState.windowOpen then task.defer(agRefreshRadar) end
end))
trackConn(Players.PlayerRemoving:Connect(function(p)
	cagedPartsByUserId[p.UserId] = nil
	if agRefreshRadar and agState.windowOpen then task.defer(agRefreshRadar) end
end))

task.spawn(function()
	while terminalAlive do
		if agState.liveGuard and not agState.isBusy then
			local snap = getActiveSnapshot()
			if snap and #snap.partList > 0 then
				local list = snap.partList
				local total = #list
				local checked = 0
				while checked < AG_CONFIG.TamperSliceSize and checked < total do
					if agState.scanCursor > total then
						agState.scanCursor = 1
					end
					local part = list[agState.scanCursor]
					agState.scanCursor += 1
					checked += 1

					if part then
						local data = snap.parts[part]
						if data then
							if part.Parent == nil or not part:IsDescendantOf(workspace) then
								pendingDeleted[part] = true
							elseif cframeDiffers(part.CFrame, data.CFrame)
								or sizeDiffers(part.Size, data.Size)
								or colorDiffers(part.Color, data.Color)
								or part.Material ~= data.Material
								or math.abs(part.Transparency - data.Transparency) > 0.01
								or math.abs(part.Reflectance - data.Reflectance) > 0.01
								or part.Anchored ~= data.Anchored
								or part.CanCollide ~= data.CanCollide then
								pendingTampered[part] = true
							end
						end
					end
				end
			end
		end
		task.wait(AG_CONFIG.TamperInterval)
	end
end)

task.spawn(function()
	while terminalAlive do
		if not agState.isBusy then
			local ep = getF3XEndpoint(false)
			if ep then
				if agState.charShield and next(pendingCharUndo) ~= nil then
					local undoList = {}
					for inst in pairs(pendingCharUndo) do
						pendingCharUndo[inst] = nil
						if typeof(inst) == "Instance" then
							table.insert(undoList, inst)
						end
					end
					if #undoList > 0 then
						beginSelfRestoring()
						batchInvoke(ep, "UndoRemove", undoList, AG_CONFIG.BatchSize)
						endSelfRestoring()
						agState.threatsBlocked += #undoList
						agLogEvent("Recovered " .. #undoList .. " char part/joint(s)", "SHIELD")
						if agUpdateTelemetry then agUpdateTelemetry() end
					end
				end

				if agState.autoClean and next(pendingRemove) ~= nil then
					local batch = {}
					for inst in pairs(pendingRemove) do
						pendingRemove[inst] = nil
						if inst and inst.Parent ~= nil then
							table.insert(batch, inst)
						end
					end
					if #batch > 0 then
						local removed = batchRemove(ep, batch)
						if removed > 0 then
							agState.threatsBlocked += removed
							agLogEvent("Auto-blocked " .. removed .. " spam item(s)", "BLOCK")
							if agUpdateTelemetry then agUpdateTelemetry() end
						end
					end
				elseif next(pendingRemove) ~= nil then
					table.clear(pendingRemove)
				end

				if agState.liveGuard and (next(pendingDeleted) ~= nil or next(pendingTampered) ~= nil) then
					local snap = getActiveSnapshot()
					if snap then
						local targets = {}
						for p in pairs(pendingDeleted) do
							pendingDeleted[p] = nil
							table.insert(targets, p)
						end
						for p in pairs(pendingTampered) do
							pendingTampered[p] = nil
							table.insert(targets, p)
						end
						if #targets > 0 then
							local undone, rebuilt = restorePartsList(ep, snap, targets)
							agState.restoresPerformed += 1
							agState.threatsBlocked += #targets
							agLogEvent(("Guard reverted %d (Undo:%d Rebuilt:%d)"):format(#targets, undone, rebuilt), "RESTORE")
							if agUpdateTelemetry then agUpdateTelemetry() end
						end
					else
						table.clear(pendingDeleted)
						table.clear(pendingTampered)
					end
				end
			end
		end
		task.wait(AG_CONFIG.WorkerInterval)
	end
end)

trackConn(RunService.Heartbeat:Connect(function()
	if not terminalAlive then return end
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end

	if hum.FloorMaterial ~= Enum.Material.Air and hrp.Position.Y > AG_CONFIG.VoidThresholdY + 20 and hrp.AssemblyLinearVelocity.Magnitude < 65 then
		agState.lastSafeCFrame = hrp.CFrame
	end

	if agState.antiFling then
		local vel = hrp.AssemblyLinearVelocity
		local rot = hrp.AssemblyAngularVelocity
		if vel.Magnitude > AG_CONFIG.FlingVelocityThreshold or rot.Magnitude > 55 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			if agState.lastSafeCFrame then
				hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 2, 0)
			end
			local snap = getActiveSnapshot()
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc:IsA("BasePart") and not desc.Anchored and not isPlayerCharacterDescendant(desc) and not isOwnRigPart(desc) then
					if (not snap or not snap.parts[desc]) and (desc.Position - hrp.Position).Magnitude < 25 then
						desc.CanCollide = false
						if agState.autoClean then
							pendingRemove[desc] = true
						end
					end
				end
			end
		end
	end

	if agState.antiVoid and hrp.Position.Y < AG_CONFIG.VoidThresholdY then
		rescueCharacter(getF3XEndpoint(false))
	end
end))

-- ============================================================================
-- SMILEOS 2.0 ANTI-GRIEF WINDOW (SMOOTH TWEEN POPOUT)
-- ============================================================================
local AG_FULL_SIZE = UDim2.fromOffset(330, 380)
local AG_COLLAPSED_SIZE = UDim2.fromOffset(330, 0)
local AG_MIN_SIZE = UDim2.fromOffset(330, 28)

local AGWindow = Instance.new("Frame")
AGWindow.Name = "AntiGriefWindow"
AGWindow.Size = AG_COLLAPSED_SIZE
AGWindow.Position = UDim2.new(0.5, 280, 0.5, -190)
AGWindow.BackgroundColor3 = THEME.Bg
AGWindow.BorderSizePixel = 0
AGWindow.Active = true
AGWindow.Visible = false
AGWindow.ClipsDescendants = true
AGWindow.Parent = ScreenGui
addStroke(AGWindow, THEME.BorderWhite, 2)

local AGTitleBar = Instance.new("Frame")
AGTitleBar.Size = UDim2.new(1, 0, 0, 28)
AGTitleBar.BackgroundColor3 = THEME.HeaderRed
AGTitleBar.BorderSizePixel = 0
AGTitleBar.Parent = AGWindow

local AGTitleAccent = Instance.new("Frame")
AGTitleAccent.Size = UDim2.new(1, 0, 0, 2)
AGTitleAccent.Position = UDim2.new(0, 0, 1, -2)
AGTitleAccent.BackgroundColor3 = THEME.BorderWhite
AGTitleAccent.BorderSizePixel = 0
AGTitleAccent.Parent = AGTitleBar

local AGTitleText = Instance.new("TextLabel")
AGTitleText.Size = UDim2.new(1, -124, 1, 0)
AGTitleText.Position = UDim2.fromOffset(8, 0)
AGTitleText.BackgroundTransparency = 1
AGTitleText.Font = Enum.Font.Code
AGTitleText.TextSize = 13
AGTitleText.TextColor3 = THEME.TextMain
AGTitleText.TextXAlignment = Enum.TextXAlignment.Left
AGTitleText.Text = "SmileOS 2.0  //  ANTI-GRIEF.SYS"
AGTitleText.Parent = AGTitleBar

local AGF3XBadge = Instance.new("TextLabel")
AGF3XBadge.Size = UDim2.fromOffset(54, 18)
AGF3XBadge.Position = UDim2.new(1, -114, 0, 5)
AGF3XBadge.BackgroundColor3 = THEME.Bg
AGF3XBadge.BorderSizePixel = 0
AGF3XBadge.Font = Enum.Font.Code
AGF3XBadge.TextSize = 10
AGF3XBadge.TextColor3 = THEME.AccentRed
AGF3XBadge.Text = "NO F3X"
AGF3XBadge.Parent = AGTitleBar
local agBadgeStroke = addStroke(AGF3XBadge, THEME.AccentRed, 1)

local AGMinBtn = Instance.new("TextButton")
AGMinBtn.Size = UDim2.fromOffset(24, 20)
AGMinBtn.Position = UDim2.new(1, -54, 0, 4)
AGMinBtn.BackgroundColor3 = THEME.Bg
AGMinBtn.BorderSizePixel = 0
AGMinBtn.Font = Enum.Font.Code
AGMinBtn.TextSize = 14
AGMinBtn.TextColor3 = THEME.TextMain
AGMinBtn.Text = "-"
AGMinBtn.Parent = AGTitleBar
addStroke(AGMinBtn, THEME.BorderWhite, 1)

local AGCloseBtn = Instance.new("TextButton")
AGCloseBtn.Size = UDim2.fromOffset(24, 20)
AGCloseBtn.Position = UDim2.new(1, -27, 0, 4)
AGCloseBtn.BackgroundColor3 = THEME.Bg
AGCloseBtn.BorderSizePixel = 0
AGCloseBtn.Font = Enum.Font.Code
AGCloseBtn.TextSize = 13
AGCloseBtn.TextColor3 = THEME.AccentRed
AGCloseBtn.Text = "X"
AGCloseBtn.Parent = AGTitleBar
addStroke(AGCloseBtn, THEME.BorderWhite, 1)

makeDraggable(AGTitleBar, AGWindow)

local AGBody = Instance.new("Frame")
AGBody.Size = UDim2.new(1, 0, 1, -28)
AGBody.Position = UDim2.fromOffset(0, 28)
AGBody.BackgroundTransparency = 1
AGBody.Parent = AGWindow

local AGTelemetry = Instance.new("TextLabel")
AGTelemetry.Size = UDim2.new(1, -16, 0, 20)
AGTelemetry.Position = UDim2.fromOffset(8, 6)
AGTelemetry.BackgroundColor3 = THEME.Panel
AGTelemetry.BorderSizePixel = 0
AGTelemetry.Font = Enum.Font.Code
AGTelemetry.TextSize = 11
AGTelemetry.TextColor3 = THEME.AccentGold
AGTelemetry.TextXAlignment = Enum.TextXAlignment.Left
AGTelemetry.Text = " S1: EMPTY | BLK:0 | SMART"
AGTelemetry.Parent = AGBody
addStroke(AGTelemetry, THEME.BorderDim, 1)

local AGStatus = Instance.new("TextLabel")
AGStatus.Size = UDim2.new(1, -16, 0, 16)
AGStatus.Position = UDim2.fromOffset(8, 29)
AGStatus.BackgroundTransparency = 1
AGStatus.Font = Enum.Font.Code
AGStatus.TextSize = 11
AGStatus.TextColor3 = THEME.TextMuted
AGStatus.TextXAlignment = Enum.TextXAlignment.Left
AGStatus.TextTruncate = Enum.TextTruncate.AtEnd
AGStatus.Text = "> STATUS: STANDBY"
AGStatus.Parent = AGBody

local AGTabBar = Instance.new("Frame")
AGTabBar.Size = UDim2.new(1, -16, 0, 26)
AGTabBar.Position = UDim2.fromOffset(8, 48)
AGTabBar.BackgroundTransparency = 1
AGTabBar.Parent = AGBody

local AGTabLayout = Instance.new("UIListLayout")
AGTabLayout.FillDirection = Enum.FillDirection.Horizontal
AGTabLayout.Padding = UDim.new(0, 4)
AGTabLayout.Parent = AGTabBar

local AGPagesHolder = Instance.new("Frame")
AGPagesHolder.Size = UDim2.new(1, -16, 1, -86)
AGPagesHolder.Position = UDim2.fromOffset(8, 78)
AGPagesHolder.BackgroundColor3 = THEME.Panel
AGPagesHolder.BorderSizePixel = 0
AGPagesHolder.Parent = AGBody
addStroke(AGPagesHolder, THEME.BorderDim, 1.5)

local agPages = {}
local agTabBtns = {}

local function createAGTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, -3, 1, 0)
	btn.BackgroundColor3 = THEME.BtnIdle
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = 11
	btn.TextColor3 = THEME.TextMuted
	btn.Text = "[" .. name .. "]"
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = AGTabBar
	local st = addStroke(btn, THEME.BorderDim, 1)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, -8, 1, -8)
	page.Position = UDim2.fromOffset(4, 4)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = THEME.AccentRed
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = AGPagesHolder

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 3)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = page

	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 5)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = page

	agPages[name] = page
	agTabBtns[name] = { btn = btn, stroke = st }

	btn.Activated:Connect(function()
		for k, p in pairs(agPages) do
			local active = (k == name)
			p.Visible = active
			agTabBtns[k].btn.BackgroundColor3 = active and THEME.HeaderRed or THEME.BtnIdle
			agTabBtns[k].btn.TextColor3 = active and THEME.TextMain or THEME.TextMuted
			agTabBtns[k].stroke.Color = active and THEME.BorderWhite or THEME.BorderDim
		end
		if name == "RADAR" and agRefreshRadar then
			agRefreshRadar()
		end
	end)

	return page
end

local function selectAGTab(name)
	for k, p in pairs(agPages) do
		local active = (k == name)
		p.Visible = active
		agTabBtns[k].btn.BackgroundColor3 = active and THEME.HeaderRed or THEME.BtnIdle
		agTabBtns[k].btn.TextColor3 = active and THEME.TextMain or THEME.TextMuted
		agTabBtns[k].stroke.Color = active and THEME.BorderWhite or THEME.BorderDim
	end
end

local function makeAGButton(parent, text, accentColor, order, height)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, height or 32)
	btn.BackgroundColor3 = THEME.BtnIdle
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.TextSize = 12
	btn.TextColor3 = accentColor or THEME.TextMain
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = parent
	local st = addStroke(btn, accentColor or THEME.BorderDim, 1)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnHover }):Play()
		st.Color = THEME.BorderWhite
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnIdle }):Play()
		st.Color = accentColor or THEME.BorderDim
	end)
	return btn
end

local function makeAGToggle(parent, label, initial, order, onToggle)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = THEME.Bg
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = parent
	addStroke(btn, THEME.BorderDim, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.fromOffset(8, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 11
	lbl.TextColor3 = THEME.TextMain
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = btn

	local pill = Instance.new("TextLabel")
	pill.Size = UDim2.fromOffset(44, 18)
	pill.Position = UDim2.new(1, -50, 0.5, -9)
	pill.BackgroundColor3 = THEME.BtnIdle
	pill.BorderSizePixel = 0
	pill.Font = Enum.Font.Code
	pill.TextSize = 10
	pill.Text = initial and "[ON]" or "[OFF]"
	pill.TextColor3 = initial and THEME.SuccessGreen or THEME.TextMuted
	pill.Parent = btn
	local pillStroke = addStroke(pill, initial and THEME.SuccessGreen or THEME.BorderDim, 1)

	local current = initial
	local function setVisual(v)
		current = v
		pill.Text = v and "[ON]" or "[OFF]"
		pill.TextColor3 = v and THEME.SuccessGreen or THEME.TextMuted
		pillStroke.Color = v and THEME.SuccessGreen or THEME.BorderDim
	end

	btn.Activated:Connect(function()
		setVisual(not current)
		onToggle(current, setVisual)
	end)

	return btn, setVisual
end

local agShieldPage = createAGTab("SHIELD", 1)
local agMapPage = createAGTab("MAP", 2)
local agRadarPage = createAGTab("RADAR", 3)
local agLogsPage = createAGTab("LOGS", 4)
selectAGTab("SHIELD")

--// SHIELD TAB
local PanicBtn = makeAGButton(agShieldPage, "[ PANIC: PURGE + RESTORE MAP ]", THEME.AccentRed, 1, 34)
PanicBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	agUpdateStatus("Running panic recovery...", THEME.AccentGold)
	local ep = getF3XEndpoint(true)
	if not ep then
		agUpdateStatus("F3X tool not found!", THEME.AccentRed)
		agState.isBusy = false
		return
	end
	local purged = purgeSpam(ep, true)
	local resMsg = fullRestoreMap(ep)
	agUpdateStatus("Panic: -" .. purged .. " | " .. resMsg, THEME.SuccessGreen)
	agState.isBusy = false
end)

makeAGToggle(agShieldPage, "Live Anti-Grief Guard", agState.liveGuard, 2, function(on)
	if on and not getActiveSnapshot() then
		local count = takeSnapshot(agState.activeSlot)
		agUpdateStatus("Auto-snapshotted " .. count .. " parts", THEME.SuccessGreen)
	end
	agState.liveGuard = on
	agLogEvent("Live Guard " .. (on and "ENABLED" or "DISABLED"), "INFO")
	agUpdateTelemetry()
end)

makeAGToggle(agShieldPage, "Auto-Clean Spam Queue", agState.autoClean, 3, function(on)
	agState.autoClean = on
	agLogEvent("Auto-Clean " .. (on and "ENABLED" or "DISABLED"), "INFO")
end)

local ModeBtn = makeAGButton(agShieldPage, "[ FILTER: " .. getFilterMode():upper() .. " ]", THEME.InfoBlue, 4, 30)
ModeBtn.Activated:Connect(function()
	agState.filterModeIndex = (agState.filterModeIndex % #FILTER_MODES) + 1
	local mode = getFilterMode()
	ModeBtn.Text = "[ FILTER: " .. mode:upper() .. " ]"
	agLogEvent("Filter -> " .. mode, "INFO")
	agUpdateTelemetry()
end)

makeAGToggle(agShieldPage, "Char + Neck Motor6D Shield", agState.charShield, 5, function(on)
	agState.charShield = on
end)

makeAGToggle(agShieldPage, "Anti-Fling & Velocity Clamp", agState.antiFling, 6, function(on)
	agState.antiFling = on
end)

makeAGToggle(agShieldPage, "Anti-Void + Rescue Pad", agState.antiVoid, 7, function(on)
	agState.antiVoid = on
end)

local LockSelfRow = Instance.new("Frame")
LockSelfRow.Size = UDim2.new(1, 0, 0, 30)
LockSelfRow.BackgroundTransparency = 1
LockSelfRow.LayoutOrder = 8
LockSelfRow.Parent = agShieldPage

local LockSelfBtn = makeAGButton(LockSelfRow, "[ LOCK SELF ]", THEME.AccentGold, 1, 30)
LockSelfBtn.Size = UDim2.new(0.5, -2, 1, 0)
LockSelfBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	agUpdateStatus(lockSelfCharacterParts(getF3XEndpoint(true), true), THEME.SuccessGreen)
	agState.isBusy = false
end)

local ClearMeBtn = makeAGButton(LockSelfRow, "[ CLEAR 45 STUDS ]", THEME.AccentRed, 2, 30)
ClearMeBtn.Size = UDim2.new(0.5, -2, 1, 0)
ClearMeBtn.Position = UDim2.new(0.5, 4, 0, 0)
ClearMeBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local ep = getF3XEndpoint(true)
	if hrp and ep then
		local _, msg = clearAroundPosition(ep, hrp.Position, AG_CONFIG.ClearRadius)
		agUpdateStatus(msg, THEME.SuccessGreen)
	else
		agUpdateStatus("Need character & F3X", THEME.AccentRed)
	end
	agState.isBusy = false
end)

local PadBtn = makeAGButton(agShieldPage, "[ SPAWN RESCUE BASEPLATE ]", THEME.TextMain, 9, 30)
PadBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local ep = getF3XEndpoint(true)
	if hrp and ep and createFallbackBaseplate(ep, hrp.Position) then
		agUpdateStatus("Spawned 256x256 rescue pad", THEME.SuccessGreen)
		agLogEvent("Spawned rescue baseplate", "INFO")
	else
		agUpdateStatus("Failed: F3X or Root missing", THEME.AccentRed)
	end
	agState.isBusy = false
end)

--// MAP TAB
local SlotRow = Instance.new("Frame")
SlotRow.Size = UDim2.new(1, 0, 0, 28)
SlotRow.BackgroundTransparency = 1
SlotRow.LayoutOrder = 1
SlotRow.Parent = agMapPage

local SlotLayout = Instance.new("UIListLayout")
SlotLayout.FillDirection = Enum.FillDirection.Horizontal
SlotLayout.Padding = UDim.new(0, 4)
SlotLayout.Parent = SlotRow

local slotButtons = {}
local function refreshSlotButtons()
	for i = 1, 3 do
		local snap = agState.snapshots[i]
		local b = slotButtons[i]
		local active = (i == agState.activeSlot)
		b.btn.BackgroundColor3 = active and THEME.HeaderRed or THEME.BtnIdle
		b.btn.TextColor3 = active and THEME.TextMain or THEME.TextMuted
		b.stroke.Color = active and THEME.BorderWhite or THEME.BorderDim
		b.btn.Text = snap and ("S" .. i .. ":" .. snap.count) or ("SLOT " .. i)
	end
end

for i = 1, 3 do
	local sb = Instance.new("TextButton")
	sb.Size = UDim2.new(0.333, -3, 1, 0)
	sb.BackgroundColor3 = THEME.BtnIdle
	sb.BorderSizePixel = 0
	sb.Font = Enum.Font.Code
	sb.TextSize = 11
	sb.Text = "SLOT " .. i
	sb.AutoButtonColor = false
	sb.Parent = SlotRow
	local st = addStroke(sb, THEME.BorderDim, 1)
	slotButtons[i] = { btn = sb, stroke = st }
	sb.Activated:Connect(function()
		agState.activeSlot = i
		refreshSlotButtons()
		agUpdateTelemetry()
		agUpdateStatus("Selected Snapshot Slot " .. i, THEME.TextMain)
	end)
end
refreshSlotButtons()

local SnapBtn = makeAGButton(agMapPage, "[ TAKE / OVERWRITE SNAPSHOT ]", THEME.InfoBlue, 2, 32)
SnapBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local count = takeSnapshot(agState.activeSlot)
	refreshSlotButtons()
	agUpdateStatus("Saved " .. count .. " parts to S" .. agState.activeSlot, THEME.SuccessGreen)
	agState.isBusy = false
end)

local AdoptBtn = makeAGButton(agMapPage, "[ ADOPT NEW PARTS INTO SNAP ]", THEME.AccentGold, 3, 30)
AdoptBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local pAdded, eAdded = adoptNewPartsIntoSnapshot()
	refreshSlotButtons()
	agUpdateStatus("Adopted +" .. pAdded .. "p / +" .. eAdded .. "fx", THEME.SuccessGreen)
	agState.isBusy = false
end)

local DiffBtn = makeAGButton(agMapPage, "[ SCAN MAP INTEGRITY (DIFF) ]", THEME.TextMain, 4, 30)
DiffBtn.Activated:Connect(function()
	local snap = getActiveSnapshot()
	if not snap then
		agUpdateStatus("No snapshot in active slot", THEME.AccentRed)
		return
	end
	local d = computeMapDiff(snap)
	local msg = ("Del:%d Mov:%d Sz:%d Foreign:%d Fx:%d"):format(
		#d.deleted, #d.moved, #d.resized, #d.foreignParts, #d.foreignEffects
	)
	agUpdateStatus(msg, THEME.AccentGold)
	agLogEvent("Scan -> " .. msg, "INFO")
end)

local RestoreBtn = makeAGButton(agMapPage, "[ SMART RESTORE MAP ]", THEME.SuccessGreen, 5, 32)
RestoreBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	agUpdateStatus("Restoring snapshot...", THEME.AccentGold)
	local ep = getF3XEndpoint(true)
	local msg = fullRestoreMap(ep)
	refreshSlotButtons()
	agUpdateStatus(msg, ep and THEME.SuccessGreen or THEME.AccentRed)
	agState.isBusy = false
end)

local PurgeBtn = makeAGButton(agMapPage, "[ PURGE FOREIGN PARTS & FX ]", THEME.AccentRed, 6, 30)
PurgeBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local _, msg = purgeSpam(getF3XEndpoint(true), true)
	agUpdateStatus(msg, THEME.AccentGold)
	agState.isBusy = false
end)

local LockRow = Instance.new("Frame")
LockRow.Size = UDim2.new(1, 0, 0, 30)
LockRow.BackgroundTransparency = 1
LockRow.LayoutOrder = 7
LockRow.Parent = agMapPage

local LockBtn = makeAGButton(LockRow, "[ LOCK MAP ]", THEME.AccentGold, 1, 30)
LockBtn.Size = UDim2.new(0.5, -2, 1, 0)
LockBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	agUpdateStatus(lockMap(getF3XEndpoint(true), true), THEME.AccentGold)
	agState.isBusy = false
end)

local UnlockBtn = makeAGButton(LockRow, "[ UNLOCK MAP ]", THEME.TextMuted, 2, 30)
UnlockBtn.Size = UDim2.new(0.5, -2, 1, 0)
UnlockBtn.Position = UDim2.new(0.5, 4, 0, 0)
UnlockBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	agUpdateStatus(lockMap(getF3XEndpoint(true), false), THEME.TextMain)
	agState.isBusy = false
end)

makeAGToggle(agMapPage, "Auto-Lock After Restore", agState.autoLockAfterRestore, 8, function(on)
	agState.autoLockAfterRestore = on
end)

local CleanManagedBtn = makeAGButton(agMapPage, "[ CLEAR PADS & CAGES ]", THEME.TextMuted, 9, 28)
CleanManagedBtn.Activated:Connect(function()
	if agState.isBusy then return end
	agState.isBusy = true
	local removed = destroyManagedArtifacts(getF3XEndpoint(true))
	agUpdateStatus("Removed " .. removed .. " sentinel objects", THEME.TextMain)
	agState.isBusy = false
end)

--// RADAR TAB
local RefreshRadarBtn = makeAGButton(agRadarPage, "[ REFRESH PLAYER RADAR ]", THEME.InfoBlue, 1, 28)
local radarCards = {}

agRefreshRadar = function()
	for _, card in ipairs(radarCards) do
		if card and card.Parent then card:Destroy() end
	end
	table.clear(radarCards)

	local order = 2
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local hasF3X, equipped = playerHasF3X(plr)
			local isWL = agState.whitelist[plr.UserId] == true
			local isCaged = cagedPartsByUserId[plr.UserId] ~= nil

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 52)
			card.BackgroundColor3 = THEME.Bg
			card.BorderSizePixel = 0
			card.LayoutOrder = order
			card.Parent = agRadarPage
			addStroke(card, equipped and THEME.AccentRed or (hasF3X and THEME.AccentGold or THEME.BorderDim), 1)
			table.insert(radarCards, card)
			order += 1

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -10, 0, 18)
			nameLbl.Position = UDim2.fromOffset(6, 3)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.Code
			nameLbl.TextSize = 11
			local tag = equipped and " [F3X HELD]" or (hasF3X and " [F3X]" or "")
			if isWL then tag ..= " [WL]" end
			nameLbl.Text = plr.DisplayName .. " (@" .. plr.Name .. ")" .. tag
			nameLbl.TextColor3 = equipped and THEME.AccentRed or (hasF3X and THEME.AccentGold or THEME.TextMain)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.Parent = card

			local btnRow = Instance.new("Frame")
			btnRow.Size = UDim2.new(1, -12, 0, 22)
			btnRow.Position = UDim2.fromOffset(6, 25)
			btnRow.BackgroundTransparency = 1
			btnRow.Parent = card

			local rowLayout = Instance.new("UIListLayout")
			rowLayout.FillDirection = Enum.FillDirection.Horizontal
			rowLayout.Padding = UDim.new(0, 4)
			rowLayout.Parent = btnRow

			local function miniBtn(txt, col, cb)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0.25, -3, 1, 0)
				b.BackgroundColor3 = THEME.BtnIdle
				b.BorderSizePixel = 0
				b.Font = Enum.Font.Code
				b.TextSize = 10
				b.TextColor3 = col
				b.Text = txt
				b.AutoButtonColor = false
				b.Parent = btnRow
				addStroke(b, col, 1)
				b.Activated:Connect(cb)
			end

			miniBtn(isWL and "UN-WL" or "WL", isWL and THEME.SuccessGreen or THEME.TextMuted, function()
				agState.whitelist[plr.UserId] = not agState.whitelist[plr.UserId]
				agLogEvent((agState.whitelist[plr.UserId] and "Whitelisted " or "Removed WL ") .. plr.Name, "INFO")
				agRefreshRadar()
			end)

			miniBtn("TP", THEME.InfoBlue, function()
				local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if myHrp and tHrp then
					myHrp.AssemblyLinearVelocity = Vector3.zero
					myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 4, 4)
				end
			end)

			miniBtn("CLEAR", THEME.AccentGold, function()
				if agState.isBusy then return end
				agState.isBusy = true
				local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				local ep = getF3XEndpoint(true)
				if tHrp and ep then
					local _, msg = clearAroundPosition(ep, tHrp.Position, AG_CONFIG.ClearRadius)
					agUpdateStatus(plr.Name .. ": " .. msg, THEME.AccentGold)
				end
				agState.isBusy = false
			end)

			miniBtn(isCaged and "UNCAGE" or "CAGE", isCaged and THEME.SuccessGreen or THEME.AccentRed, function()
				if agState.isBusy then return end
				agState.isBusy = true
				local msg = cagePlayer(getF3XEndpoint(true), plr)
				agUpdateStatus(msg, THEME.AccentGold)
				agState.isBusy = false
				agRefreshRadar()
			end)
		end
	end
end

RefreshRadarBtn.Activated:Connect(agRefreshRadar)

--// LOGS TAB
local ClearLogsBtn = makeAGButton(agLogsPage, "[ CLEAR EVENT LOG ]", THEME.TextMuted, 1, 28)
local AGLogContainer = Instance.new("Frame")
AGLogContainer.Size = UDim2.new(1, 0, 0, 0)
AGLogContainer.AutomaticSize = Enum.AutomaticSize.Y
AGLogContainer.BackgroundTransparency = 1
AGLogContainer.LayoutOrder = 2
AGLogContainer.Parent = agLogsPage

local AGLogLayout = Instance.new("UIListLayout")
AGLogLayout.Padding = UDim.new(0, 2)
AGLogLayout.SortOrder = Enum.SortOrder.LayoutOrder
AGLogLayout.Parent = AGLogContainer

local agLogLabels = {}
local LOG_COLORS = {
	INFO = THEME.TextMuted,
	BLOCK = THEME.AccentRed,
	RESTORE = THEME.SuccessGreen,
	WARN = THEME.AccentGold,
	SHIELD = THEME.InfoBlue,
}

agLogEvent = function(message, level)
	local stamp = os.date("%H:%M:%S")
	local line = ("[%s] %s"):format(stamp, tostring(message))
	table.insert(agLogs, 1, { text = line, level = level or "INFO" })
	if #agLogs > AG_CONFIG.MaxLogEntries then
		table.remove(agLogs)
	end

	if AGLogContainer and AGLogContainer.Parent then
		for _, lbl in ipairs(agLogLabels) do
			lbl:Destroy()
		end
		table.clear(agLogLabels)

		for idx, entry in ipairs(agLogs) do
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, 0, 0, 0)
			l.AutomaticSize = Enum.AutomaticSize.Y
			l.BackgroundColor3 = THEME.Bg
			l.BorderSizePixel = 0
			l.Text = " > " .. entry.text
			l.TextColor3 = LOG_COLORS[entry.level] or THEME.TextMain
			l.Font = Enum.Font.Code
			l.TextSize = 10
			l.TextWrapped = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.LayoutOrder = idx
			l.Parent = AGLogContainer
			table.insert(agLogLabels, l)
		end
	end
end

ClearLogsBtn.Activated:Connect(function()
	table.clear(agLogs)
	for _, lbl in ipairs(agLogLabels) do lbl:Destroy() end
	table.clear(agLogLabels)
end)

agUpdateTelemetry = function()
	local snap = getActiveSnapshot()
	local snapStr = snap and ("S" .. agState.activeSlot .. ":" .. snap.count .. "p") or ("S" .. agState.activeSlot .. ":EMPTY")
	local guardStr = agState.liveGuard and " | GUARD" or ""
	AGTelemetry.Text = (" %s | BLK:%d | %s%s"):format(snapStr, agState.threatsBlocked, getFilterMode():upper(), guardStr)
end

agUpdateStatus = function(msg, color)
	AGStatus.Text = "> " .. tostring(msg)
	AGStatus.TextColor3 = color or THEME.TextMain
end

--// Smooth Open / Close / Minimize for Anti-Grief Panel
local agPositionedOnce = false
local function setAntiGriefOpen(open)
	agState.windowOpen = open

	if open then
		AGBody.Visible = not agState.windowMinimized
		if not agPositionedOnce then
			agPositionedOnce = true
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			local desiredX = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X + 8
			if desiredX + 334 > vp.X then
				desiredX = math.max(8, vp.X - 338)
			end
			local desiredY = math.clamp(MainFrame.AbsolutePosition.Y, 4, math.max(4, vp.Y - 384))
			AGWindow.Position = UDim2.fromOffset(desiredX, desiredY)
		end

		AGWindow.Size = AG_COLLAPSED_SIZE
		AGWindow.Visible = true
		TweenService:Create(AGWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = agState.windowMinimized and AG_MIN_SIZE or AG_FULL_SIZE,
		}):Play()

		AntiGriefBtn.BackgroundColor3 = THEME.HeaderRed
		AntiGriefBtn.TextColor3 = THEME.TextMain
		agBtnStroke.Color = THEME.BorderWhite
		agRefreshRadar()
	else
		local tw = TweenService:Create(AGWindow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Size = AG_COLLAPSED_SIZE,
		})
		tw.Completed:Connect(function()
			if not agState.windowOpen and AGWindow then
				AGWindow.Visible = false
			end
		end)
		tw:Play()

		AntiGriefBtn.BackgroundColor3 = THEME.BtnIdle
		AntiGriefBtn.TextColor3 = THEME.TextMuted
		agBtnStroke.Color = THEME.BorderDim
	end
end

AntiGriefBtn.MouseEnter:Connect(function()
	if not agState.windowOpen then
		TweenService:Create(AntiGriefBtn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnHover }):Play()
		AntiGriefBtn.TextColor3 = THEME.TextMain
		agBtnStroke.Color = THEME.BorderWhite
	end
end)
AntiGriefBtn.MouseLeave:Connect(function()
	if not agState.windowOpen then
		TweenService:Create(AntiGriefBtn, TweenInfo.new(0.1), { BackgroundColor3 = THEME.BtnIdle }):Play()
		AntiGriefBtn.TextColor3 = THEME.TextMuted
		agBtnStroke.Color = THEME.BorderDim
	end
end)

AntiGriefBtn.Activated:Connect(function()
	setAntiGriefOpen(not agState.windowOpen)
end)

AGCloseBtn.Activated:Connect(function()
	setAntiGriefOpen(false)
end)

AGMinBtn.Activated:Connect(function()
	agState.windowMinimized = not agState.windowMinimized
	AGBody.Visible = not agState.windowMinimized
	TweenService:Create(AGWindow, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = agState.windowMinimized and AG_MIN_SIZE or AG_FULL_SIZE,
	}):Play()
	AGMinBtn.Text = agState.windowMinimized and "+" or "-"
end)

task.spawn(function()
	while terminalAlive do
		local ep = getF3XEndpoint(false)
		if ep then
			AGF3XBadge.Text = "F3X OK"
			AGF3XBadge.TextColor3 = THEME.SuccessGreen
			agBadgeStroke.Color = THEME.SuccessGreen
		else
			AGF3XBadge.Text = "NO F3X"
			AGF3XBadge.TextColor3 = THEME.AccentRed
			agBadgeStroke.Color = THEME.AccentRed
		end
		task.wait(1.0)
	end
end)

agLogEvent("Anti-Grief subsystem online", "INFO")
agUpdateTelemetry()

-- ============================================================================
-- LOADER ENGINE (CORE -> CHARACTER(CORE) HANDOFF)
-- ============================================================================
local activeController = nil
local isBusy = false
local selectedChar = CHARACTERS[1]

local function getGlobalFn(name)
	if type(env[name]) == "function" then
		return env[name], env
	end
	if type(_G[name]) == "function" then
		return _G[name], _G
	end
	return nil, nil
end

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

	for _, store in ipairs({ env, _G }) do
		if type(store.ULTRAKILL_F3X) == "table" and type(store.ULTRAKILL_F3X.cleanup) == "function" then
			pcall(store.ULTRAKILL_F3X.cleanup)
			store.ULTRAKILL_F3X = nil
			cleaned += 1
		end
	end

	for _, globalName in ipairs(LEGACY_CLEANUP_GLOBALS) do
		local fn, store = getGlobalFn(globalName)
		if fn then
			local ok, err = pcall(fn)
			if ok then
				cleaned += 1
			else
				logLine(globalName .. " error: " .. tostring(err), THEME.AccentRed)
			end
			if store then
				store[globalName] = nil
			end
		end
	end

	for _, globalName in ipairs(LEGACY_REBUILD_GLOBALS) do
		env[globalName] = nil
		_G[globalName] = nil
	end

	table.clear(protectedRigInstances)

	if cleaned > 0 then
		logLine("Cleaned previous rig (" .. cleaned .. " hook(s)).", THEME.TextMuted)
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

	local fn, compileErr = loadstring(source)
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
	markRigDeployGrace(4.5)
	cleanupActiveRig()

	-- 1. Fetch & load core.lua (graceful fallback table if core.lua is unreachable)
	local Core = {}
	local coreFn, coreErr = fetchAndCompile("core.lua")
	if coreFn then
		local okCore, loadedCore = pcall(coreFn)
		if okCore and type(loadedCore) == "table" then
			Core = loadedCore
			logLine("core.lua loaded.", THEME.SuccessGreen)
		else
			logLine("core.lua invalid return; using fallback Core.", THEME.AccentGold)
		end
	else
		logLine("core.lua warning: " .. tostring(coreErr) .. " (using fallback Core)", THEME.AccentGold)
	end

	-- 2. Fetch & load character module
	local charFn, charErr = fetchAndCompile(charData.path)
	if not charFn then
		logLine(tostring(charErr), THEME.AccentRed)
		isBusy = false
		return
	end

	local okMod, charModule = pcall(charFn)
	if not okMod then
		logLine("Error loading " .. charData.path .. ": " .. tostring(charModule), THEME.AccentRed)
		isBusy = false
		return
	end

	-- 3. Invoke the character factory with Core: return function(Core) ... end
	local result = charModule
	markRigDeployGrace(4.0)
	if type(charModule) == "function" then
		logLine("Initializing " .. charData.name .. "(Core)...", THEME.TextMuted)
		local okInit, initRes = pcall(charModule, Core)
		if not okInit then
			logLine("Runtime error in " .. charData.path .. ": " .. tostring(initRes), THEME.AccentRed)
			isBusy = false
			return
		end
		result = initRes
	elseif type(charModule) == "table" and type(charModule.init) == "function" then
		local okInit, initRes = pcall(charModule.init, Core)
		if not okInit then
			logLine("Init error in " .. charData.path .. ": " .. tostring(initRes), THEME.AccentRed)
			isBusy = false
			return
		end
		result = initRes or charModule
	end

	activeController = result
	logLine("DEPLOYED: " .. charData.name .. " ACTIVE.", THEME.SuccessGreen)
	isBusy = false
end

local function triggerRebuild()
	markRigDeployGrace(3.5)
	if type(activeController) == "table" and type(activeController.rebuild) == "function" then
		local ok, err = pcall(activeController.rebuild)
		logLine(ok and "Rebuild triggered via controller." or ("Rebuild error: " .. tostring(err)), ok and THEME.SuccessGreen or THEME.AccentRed)
		return
	end

	for _, store in ipairs({ env, _G }) do
		if type(store.ULTRAKILL_F3X) == "table" and type(store.ULTRAKILL_F3X.rebuild) == "function" then
			local ok, err = pcall(store.ULTRAKILL_F3X.rebuild)
			logLine(ok and "Rebuild triggered via ULTRAKILL_F3X." or ("Rebuild error: " .. tostring(err)), ok and THEME.SuccessGreen or THEME.AccentRed)
			return
		end
	end

	for _, globalName in ipairs(LEGACY_REBUILD_GLOBALS) do
		local fn = getGlobalFn(globalName)
		if fn then
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
	btn.Activated:Connect(function()
		selectCharacter(charData)
	end)
end

DeployBtn.Activated:Connect(function()
	task.spawn(function()
		deployCharacter(selectedChar)
	end)
end)

RebuildBtn.Activated:Connect(function()
	task.spawn(triggerRebuild)
end)

UnloadBtn.Activated:Connect(function()
	cleanupActiveRig()
	logLine("All active rigs unloaded.", THEME.AccentGold)
end)

local function fullTerminalCleanup()
	terminalAlive = false
	clearCharWatchConns()
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(connections)
	cleanupActiveRig()
	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
end

env.ULTRAKILL_TERMINAL_CLEANUP = fullTerminalCleanup
_G.ULTRAKILL_TERMINAL_CLEANUP = fullTerminalCleanup

CloseBtn.Activated:Connect(fullTerminalCleanup)

selectCharacter(CHARACTERS[1])
logLine("SmileOS 2.0 Terminal ready.", THEME.SuccessGreen)
logLine("Select a machine and press [ DEPLOY ].", THEME.TextMuted)