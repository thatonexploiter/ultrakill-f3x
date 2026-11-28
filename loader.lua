-- ULTRAKILL // SmileOS 2.0 LOADER
-- Repo: https://github.com/thatonexploiter/ultrakill-f3x

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
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
-- PALETTES: SMILEOS 2.0 CHROME (LOADER) + SHARED THEME (ANTIGRIEF BRIDGE)
-- ============================================================================
local SMILE = {
	-- Classic SmileOS 2.0 light-gray / crimson / CRT-inset palette
	WinFace = Color3.fromRGB(214, 210, 204),
	WinFaceAlt = Color3.fromRGB(198, 193, 186),
	BevelLight = Color3.fromRGB(250, 248, 244),
	BevelMid = Color3.fromRGB(162, 157, 150),
	BevelDark = Color3.fromRGB(78, 74, 72),
	BorderOuter = Color3.fromRGB(32, 28, 28),

	HeaderTop = Color3.fromRGB(204, 36, 36),
	HeaderBot = Color3.fromRGB(122, 16, 16),
	HeaderInactive = Color3.fromRGB(126, 122, 120),

	BtnFace = Color3.fromRGB(224, 220, 214),
	BtnHover = Color3.fromRGB(238, 234, 228),
	BtnPressedRed = Color3.fromRGB(182, 28, 28),
	BtnPressedRedDark = Color3.fromRGB(132, 18, 18),
	BtnLocked = Color3.fromRGB(184, 179, 173),

	InsetDark = Color3.fromRGB(16, 14, 16),
	InsetMid = Color3.fromRGB(28, 24, 26),
	InsetLight = Color3.fromRGB(244, 241, 236),

	TextDark = Color3.fromRGB(24, 22, 22),
	TextMutedDark = Color3.fromRGB(98, 92, 88),
	TextLight = Color3.fromRGB(245, 242, 236),
	TextMutedLight = Color3.fromRGB(152, 142, 140),

	AccentRed = Color3.fromRGB(218, 38, 38),
	AccentGold = Color3.fromRGB(235, 178, 48),
	SuccessGreen = Color3.fromRGB(78, 204, 96),
	InfoBlue = Color3.fromRGB(72, 148, 232),
	TaskbarBg = Color3.fromRGB(190, 185, 178),
}

-- Shared dark-well theme passed to Antigrief.lua so its dark panels remain legible
local THEME = {
	Bg = Color3.fromRGB(14, 13, 15),
	Panel = Color3.fromRGB(22, 20, 22),
	HeaderRed = Color3.fromRGB(180, 26, 26),
	AccentRed = Color3.fromRGB(220, 38, 38),
	AccentGold = Color3.fromRGB(235, 178, 48),
	SuccessGreen = Color3.fromRGB(68, 195, 88),
	InfoBlue = Color3.fromRGB(72, 148, 230),
	BorderWhite = Color3.fromRGB(230, 226, 220),
	BorderDim = Color3.fromRGB(82, 68, 68),
	TextMain = Color3.fromRGB(240, 235, 230),
	TextMuted = Color3.fromRGB(150, 138, 136),
	BtnIdle = Color3.fromRGB(28, 26, 28),
	BtnHover = Color3.fromRGB(145, 24, 24),
	BtnLocked = Color3.fromRGB(32, 26, 26),
}

local TIPS = {
	"PARRYING YOUR OWN SHOTGUN PELLETS MAKES THEM EXPLODE.",
	"AIRBORNE COINS CAN BE SHOT WITH ANY HITSCAN WEAPON.",
	"F3X PARTS MUST STAY ANCHORED & NON-COLLIDABLE TO PREVENT FLINGING.",
	"MANKIND IS DEAD. BLOOD IS FUEL. HELL IS FULL.",
	"USE [REBUILD] IF YOUR CHARACTER RESPAWNS OR DESYNCS.",
	"PRESS [X] AS MINOS PRIME TO UNLEASH PHASE 2.",
}

-- ============================================================================
-- CHARACTER ROSTER
-- ============================================================================
local CHARACTERS = {
	{
		id = "v1",
		name = "V1",
		code = "MCH-V1",
		subtitle = "SUPREME MACHINE // MODEL V1",
		path = "characters/v1.lua",
		unlocked = true,
		desc = "Blue combat chassis with 8 articulated wings, camera head, and backpack core. Supports R6 & R15.",
	},
	{
		id = "v2",
		name = "V2",
		code = "MCH-V2",
		subtitle = "SUPREME MACHINE // MODEL V2",
		path = "characters/v2.lua",
		unlocked = true,
		desc = "Crimson-plated prototype built for durability. Full F3X rig reanimation.",
	},
	{
		id = "gabriel",
		name = "GABRIEL",
		code = "ANG-01",
		subtitle = "JUDGE OF HELL",
		path = nil,
		unlocked = false,
		desc = "[LOCKED] Awaiting module deployment in characters/gabriel.lua.",
	},
	{
		id = "minos",
		name = "MINOS PRIME",
		code = "PRM-P1",
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
-- LIFECYCLE & UI HELPERS (AUTHENTIC 3D BEVELS, GRADIENTS & SMILEY GLYPH)
-- ============================================================================
local terminalAlive = true
local connections = {}
local function trackConn(conn)
	table.insert(connections, conn)
	return conn
end

local function createBevel(parent, inset, thickness)
	local t = thickness or 2
	local function edge(name, size, pos)
		local f = Instance.new("Frame")
		f.Name = name
		f.BorderSizePixel = 0
		f.Size = size
		f.Position = pos
		f.ZIndex = parent.ZIndex + 2
		f.Parent = parent
		return f
	end

	local top = edge("BevelTop", UDim2.new(1, 0, 0, t), UDim2.fromOffset(0, 0))
	local left = edge("BevelLeft", UDim2.new(0, t, 1, 0), UDim2.fromOffset(0, 0))
	local bottom = edge("BevelBottom", UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 1, -t))
	local right = edge("BevelRight", UDim2.new(0, t, 1, 0), UDim2.new(1, -t, 0, 0))

	local function setPressed(isPressed)
		if isPressed then
			top.BackgroundColor3 = SMILE.BevelDark
			left.BackgroundColor3 = SMILE.BevelDark
			bottom.BackgroundColor3 = SMILE.BevelLight
			right.BackgroundColor3 = SMILE.BevelLight
		else
			top.BackgroundColor3 = SMILE.BevelLight
			left.BackgroundColor3 = SMILE.BevelLight
			bottom.BackgroundColor3 = SMILE.BevelDark
			right.BackgroundColor3 = SMILE.BevelDark
		end
	end

	setPressed(inset == true)
	return {
		setPressed = setPressed,
		setColors = function(tlCol, brCol)
			top.BackgroundColor3 = tlCol
			left.BackgroundColor3 = tlCol
			bottom.BackgroundColor3 = brCol
			right.BackgroundColor3 = brCol
		end,
	}
end

local function addOutline(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or SMILE.BorderOuter
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- Pixel-built SmileOS ":)" face icon so no external asset IDs can break
local function createSmileyIcon(parent, sizePx, pos, bgCol, faceCol)
	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(sizePx, sizePx)
	box.Position = pos
	box.BackgroundColor3 = bgCol or SMILE.InsetLight
	box.BorderSizePixel = 0
	box.ZIndex = parent.ZIndex + 2
	box.Parent = parent
	addOutline(box, SMILE.BorderOuter, 1)

	local eyeSize = math.max(2, math.floor(sizePx * 0.14))
	local eyeL = Instance.new("Frame")
	eyeL.Size = UDim2.fromOffset(eyeSize, eyeSize + 1)
	eyeL.Position = UDim2.fromScale(0.27, 0.28)
	eyeL.BackgroundColor3 = faceCol or SMILE.TextDark
	eyeL.BorderSizePixel = 0
	eyeL.ZIndex = box.ZIndex + 1
	eyeL.Parent = box

	local eyeR = Instance.new("Frame")
	eyeR.Size = UDim2.fromOffset(eyeSize, eyeSize + 1)
	eyeR.Position = UDim2.fromScale(0.60, 0.28)
	eyeR.BackgroundColor3 = faceCol or SMILE.TextDark
	eyeR.BorderSizePixel = 0
	eyeR.ZIndex = box.ZIndex + 1
	eyeR.Parent = box

	local mouthMid = Instance.new("Frame")
	mouthMid.Size = UDim2.new(0.42, 0, 0, eyeSize)
	mouthMid.Position = UDim2.fromScale(0.29, 0.66)
	mouthMid.BackgroundColor3 = faceCol or SMILE.TextDark
	mouthMid.BorderSizePixel = 0
	mouthMid.ZIndex = box.ZIndex + 1
	mouthMid.Parent = box

	local mouthL = Instance.new("Frame")
	mouthL.Size = UDim2.fromOffset(eyeSize, eyeSize)
	mouthL.Position = UDim2.fromScale(0.20, 0.58)
	mouthL.BackgroundColor3 = faceCol or SMILE.TextDark
	mouthL.BorderSizePixel = 0
	mouthL.ZIndex = box.ZIndex + 1
	mouthL.Parent = box

	local mouthR = Instance.new("Frame")
	mouthR.Size = UDim2.fromOffset(eyeSize, eyeSize)
	mouthR.Position = UDim2.fromScale(0.68, 0.58)
	mouthR.BackgroundColor3 = faceCol or SMILE.TextDark
	mouthR.BorderSizePixel = 0
	mouthR.ZIndex = box.ZIndex + 1
	mouthR.Parent = box

	return box
end

local function getScreenSize(gui)
	if gui and gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0 then
		return gui.AbsoluteSize
	end
	local cam = workspace.CurrentCamera
	return (cam and cam.ViewportSize) or Vector2.new(1280, 720)
end

local function clampWindowToScreen(window, gui)
	local vp = getScreenSize(gui)
	local absW, absH = window.AbsoluteSize.X, window.AbsoluteSize.Y
	local curX = window.Position.X.Scale * vp.X + window.Position.X.Offset
	local curY = window.Position.Y.Scale * vp.Y + window.Position.Y.Offset
	local maxX = math.max(0, vp.X - absW)
	local maxY = math.max(0, vp.Y - absH)
	window.Position = UDim2.fromOffset(math.clamp(curX, 0, maxX), math.clamp(curY, 0, maxY))
end

local function makeDraggable(handle, window, gui)
	local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
	trackConn(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
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
	trackConn(UserInputService.InputEnded:Connect(function(input)
		if input == dragInput then
			dragging = false
		end
	end))
	trackConn(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragInput or (dragInput and dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			local delta = input.Position - dragStart
			local vp = getScreenSize(gui)
			local absW, absH = window.AbsoluteSize.X, window.AbsoluteSize.Y
			local baseX = startPos.X.Scale * vp.X + startPos.X.Offset + delta.X
			local baseY = startPos.Y.Scale * vp.Y + startPos.Y.Offset + delta.Y
			local clampedX = math.clamp(baseX, 0, math.max(0, vp.X - absW))
			local clampedY = math.clamp(baseY, 0, math.max(0, vp.Y - absH))
			window.Position = UDim2.fromOffset(clampedX, clampedY)
		end
	end))
end

-- ============================================================================
-- BUILD MAIN SMILEOS 2.0 WINDOW
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ULTRAKILL_F3X_TERMINAL"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local FULL_WIDTH, FULL_HEIGHT = 560, 412
local COLLAPSED_HEIGHT = 30

local function computeWindowScale()
	local vp = getScreenSize(ScreenGui)
	local isCompact = UserInputService.TouchEnabled or vp.X < 760 or vp.Y < 540
	local fitScale = math.min((vp.X - 24) / FULL_WIDTH, (vp.Y - 24) / FULL_HEIGHT)
	if isCompact then
		return math.clamp(fitScale, 0.48, 0.80)
	end
	return math.clamp(fitScale, 0.65, 1.0)
end

local initialScale = computeWindowScale()
local initialVp = getScreenSize(ScreenGui)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "TerminalWindow"
MainFrame.Size = UDim2.fromOffset(FULL_WIDTH, 16)
MainFrame.Position = UDim2.fromOffset(
	math.max(0, math.floor((initialVp.X - FULL_WIDTH * initialScale) * 0.5)),
	math.max(0, math.floor((initialVp.Y - FULL_HEIGHT * initialScale) * 0.5))
)
MainFrame.BackgroundColor3 = SMILE.WinFace
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainScale = Instance.new("UIScale")
MainScale.Scale = initialScale
MainScale.Parent = MainFrame

local mainBevel = createBevel(MainFrame, false, 2)
addOutline(MainFrame, SMILE.BorderOuter, 1)

trackConn(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if not terminalAlive or not MainScale or not MainScale.Parent then return end
	MainScale.Scale = computeWindowScale()
	task.defer(function()
		if terminalAlive and MainFrame and MainFrame.Parent then
			clampWindowToScreen(MainFrame, ScreenGui)
		end
	end)
end))

-- Title Bar (XP-style SmileOS 2.0 Crimson Gradient)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, -4, 0, 26)
TitleBar.Position = UDim2.fromOffset(2, 2)
TitleBar.BackgroundColor3 = SMILE.HeaderTop
TitleBar.BorderSizePixel = 0
TitleBar.Active = true
TitleBar.ZIndex = 3
TitleBar.Parent = MainFrame

local titleGrad = Instance.new("UIGradient")
titleGrad.Rotation = 90
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 58, 58)),
	ColorSequenceKeypoint.new(0.18, SMILE.HeaderTop),
	ColorSequenceKeypoint.new(1, SMILE.HeaderBot),
})
titleGrad.Parent = TitleBar

createSmileyIcon(TitleBar, 18, UDim2.fromOffset(5, 4), SMILE.InsetLight, SMILE.TextDark)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -110, 1, 0)
TitleText.Position = UDim2.fromOffset(28, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 13
TitleText.TextColor3 = SMILE.TextLight
TitleText.TextStrokeTransparency = 0.65
TitleText.TextStrokeColor3 = Color3.new(0, 0, 0)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Text = "SmileOS 2.0  -  TERMINAL"
TitleText.ZIndex = 4
TitleText.Parent = TitleBar

-- Classic OS Caption Buttons (_, X)
local function makeCaptionButton(text, posOffset, isClose)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(24, 20)
	btn.Position = UDim2.new(1, posOffset, 0, 3)
	btn.BackgroundColor3 = isClose and Color3.fromRGB(215, 60, 56) or SMILE.BtnFace
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = isClose and SMILE.TextLight or SMILE.TextDark
	btn.Text = text
	btn.AutoButtonColor = false
	btn.ZIndex = 4
	btn.Parent = TitleBar
	local bev = createBevel(btn, false, 1)
	addOutline(btn, SMILE.BorderOuter, 1)

	btn.MouseButton1Down:Connect(function()
		bev.setPressed(true)
	end)
	btn.MouseButton1Up:Connect(function()
		bev.setPressed(false)
	end)
	btn.MouseLeave:Connect(function()
		bev.setPressed(false)
	end)
	return btn
end

local MinBtn = makeCaptionButton("_", -54, false)
local CloseBtn = makeCaptionButton("X", -27, true)

-- Body Container
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -8, 1, -60)
Body.Position = UDim2.fromOffset(4, 30)
Body.BackgroundTransparency = 1
Body.ZIndex = 2
Body.Parent = MainFrame

-- ============================================================================
-- BOOT SPLASH OVERLAY (PLAYS BRIEFLY ON STARTUP)
-- ============================================================================
local BootSplash = Instance.new("Frame")
BootSplash.Name = "BootSplash"
BootSplash.Size = UDim2.new(1, -4, 1, -30)
BootSplash.Position = UDim2.fromOffset(2, 28)
BootSplash.BackgroundColor3 = SMILE.InsetDark
BootSplash.BorderSizePixel = 0
BootSplash.ZIndex = 30
BootSplash.Parent = MainFrame

local bootLogo = createSmileyIcon(BootSplash, 44, UDim2.new(0.5, -22, 0.28, -22), SMILE.WinFace, SMILE.AccentRed)
bootLogo.ZIndex = 31

local BootTitle = Instance.new("TextLabel")
BootTitle.Size = UDim2.new(1, -40, 0, 26)
BootTitle.Position = UDim2.new(0, 20, 0.48, 0)
BootTitle.BackgroundTransparency = 1
BootTitle.Font = Enum.Font.GothamBold
BootTitle.TextSize = 20
BootTitle.TextColor3 = SMILE.TextLight
BootTitle.Text = "SmileOS 2.0"
BootTitle.ZIndex = 31
BootTitle.Parent = BootSplash

local BootSub = Instance.new("TextLabel")
BootSub.Size = UDim2.new(1, -40, 0, 16)
BootSub.Position = UDim2.new(0, 20, 0.56, 2)
BootSub.BackgroundTransparency = 1
BootSub.Font = Enum.Font.Code
BootSub.TextSize = 11
BootSub.TextColor3 = SMILE.AccentGold
BootSub.Text = "INITIALIZING F3X TERMINAL INTERFACE..."
BootSub.ZIndex = 31
BootSub.Parent = BootSplash

local BootBarTrack = Instance.new("Frame")
BootBarTrack.Size = UDim2.fromOffset(240, 14)
BootBarTrack.Position = UDim2.new(0.5, -120, 0.67, 0)
BootBarTrack.BackgroundColor3 = SMILE.WinFace
BootBarTrack.BorderSizePixel = 0
BootBarTrack.ZIndex = 31
BootBarTrack.Parent = BootSplash
createBevel(BootBarTrack, true, 2)

local BootBarFill = Instance.new("Frame")
BootBarFill.Size = UDim2.new(0, 0, 1, -4)
BootBarFill.Position = UDim2.fromOffset(2, 2)
BootBarFill.BackgroundColor3 = SMILE.AccentRed
BootBarFill.BorderSizePixel = 0
BootBarFill.ZIndex = 32
BootBarFill.Parent = BootBarTrack

-- ============================================================================
-- LEFT SIDEBAR: SMILEOS TERMINAL MENU LIST
-- ============================================================================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 174, 1, -8)
Sidebar.Position = UDim2.fromOffset(4, 4)
Sidebar.BackgroundColor3 = SMILE.WinFaceAlt
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = Body
createBevel(Sidebar, true, 2)

local SideBanner = Instance.new("Frame")
SideBanner.Size = UDim2.new(1, -8, 0, 24)
SideBanner.Position = UDim2.fromOffset(4, 4)
SideBanner.BackgroundColor3 = SMILE.HeaderBot
SideBanner.BorderSizePixel = 0
SideBanner.ZIndex = 4
SideBanner.Parent = Sidebar
createBevel(SideBanner, false, 1)

local SideHeader = Instance.new("TextLabel")
SideHeader.Size = UDim2.new(1, -10, 1, 0)
SideHeader.Position = UDim2.fromOffset(6, 0)
SideHeader.BackgroundTransparency = 1
SideHeader.Font = Enum.Font.GothamBold
SideHeader.TextSize = 12
SideHeader.TextColor3 = SMILE.TextLight
SideHeader.TextXAlignment = Enum.TextXAlignment.Left
SideHeader.Text = "MACHINES"
SideHeader.ZIndex = 5
SideHeader.Parent = SideBanner

local SideCountLbl = Instance.new("TextLabel")
SideCountLbl.Size = UDim2.new(1, -8, 1, 0)
SideCountLbl.BackgroundTransparency = 1
SideCountLbl.Font = Enum.Font.Code
SideCountLbl.TextSize = 11
SideCountLbl.TextColor3 = SMILE.AccentGold
SideCountLbl.TextXAlignment = Enum.TextXAlignment.Right
SideCountLbl.Text = "4 MODS"
SideCountLbl.ZIndex = 5
SideCountLbl.Parent = SideBanner

local SideList = Instance.new("ScrollingFrame")
SideList.Size = UDim2.new(1, -10, 1, -78)
SideList.Position = UDim2.fromOffset(5, 32)
SideList.BackgroundTransparency = 1
SideList.BorderSizePixel = 0
SideList.ScrollBarThickness = 4
SideList.ScrollBarImageColor3 = SMILE.BevelDark
SideList.CanvasSize = UDim2.new(0, 0, 0, 0)
SideList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideList.ZIndex = 4
SideList.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 5)
SideLayout.Parent = SideList

local SideSep = Instance.new("Frame")
SideSep.Size = UDim2.new(1, -12, 0, 2)
SideSep.Position = UDim2.new(0, 6, 1, -40)
SideSep.BackgroundColor3 = SMILE.BevelDark
SideSep.BorderSizePixel = 0
SideSep.ZIndex = 4
SideSep.Parent = Sidebar

local SideSepLight = Instance.new("Frame")
SideSepLight.Size = UDim2.new(1, 0, 0, 1)
SideSepLight.Position = UDim2.fromOffset(0, 1)
SideSepLight.BackgroundColor3 = SMILE.BevelLight
SideSepLight.BorderSizePixel = 0
SideSepLight.ZIndex = 4
SideSepLight.Parent = SideSep

-- Anti-Grief Module Toggle Button (classic beveled OS button)
local AntiGriefBtn = Instance.new("TextButton")
AntiGriefBtn.Name = "AntiGriefOption"
AntiGriefBtn.Size = UDim2.new(1, -10, 0, 28)
AntiGriefBtn.Position = UDim2.new(0, 5, 1, -33)
AntiGriefBtn.BackgroundColor3 = SMILE.BtnFace
AntiGriefBtn.BorderSizePixel = 0
AntiGriefBtn.Font = Enum.Font.GothamBold
AntiGriefBtn.TextSize = 12
AntiGriefBtn.TextColor3 = SMILE.TextDark
AntiGriefBtn.Text = "  ANTI-GRIEF.SYS"
AntiGriefBtn.TextXAlignment = Enum.TextXAlignment.Left
AntiGriefBtn.AutoButtonColor = false
AntiGriefBtn.ZIndex = 4
AntiGriefBtn.Parent = Sidebar
local agBtnBevel = createBevel(AntiGriefBtn, false, 2)
addOutline(AntiGriefBtn, SMILE.BevelMid, 1)

local agDot = Instance.new("Frame")
agDot.Size = UDim2.fromOffset(8, 8)
agDot.Position = UDim2.new(1, -15, 0.5, -4)
agDot.BackgroundColor3 = SMILE.BevelDark
agDot.BorderSizePixel = 0
agDot.ZIndex = 6
agDot.Parent = AntiGriefBtn
addOutline(agDot, SMILE.BorderOuter, 1)

-- ============================================================================
-- RIGHT WORKSPACE: MACHINE INSPECTOR + CONSOLE + TIP OF THE DAY
-- ============================================================================
local RightArea = Instance.new("Frame")
RightArea.Size = UDim2.new(1, -186, 1, -8)
RightArea.Position = UDim2.fromOffset(182, 4)
RightArea.BackgroundTransparency = 1
RightArea.ZIndex = 3
RightArea.Parent = Body

-- Machine Info Card (Sub-panel with crimson SmileOS header strip)
local InfoWindow = Instance.new("Frame")
InfoWindow.Size = UDim2.new(1, 0, 0, 146)
InfoWindow.BackgroundColor3 = SMILE.InsetDark
InfoWindow.BorderSizePixel = 0
InfoWindow.ZIndex = 4
InfoWindow.Parent = RightArea
createBevel(InfoWindow, true, 2)

local InfoHeader = Instance.new("Frame")
InfoHeader.Size = UDim2.new(1, -4, 0, 22)
InfoHeader.Position = UDim2.fromOffset(2, 2)
InfoHeader.BackgroundColor3 = SMILE.HeaderTop
InfoHeader.BorderSizePixel = 0
InfoHeader.ZIndex = 5
InfoHeader.Parent = InfoWindow

local infoGrad = Instance.new("UIGradient")
infoGrad.Rotation = 90
infoGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, SMILE.HeaderTop),
	ColorSequenceKeypoint.new(1, SMILE.HeaderBot),
})
infoGrad.Parent = InfoHeader

local SelectedTitle = Instance.new("TextLabel")
SelectedTitle.Size = UDim2.new(1, -86, 1, 0)
SelectedTitle.Position = UDim2.fromOffset(8, 0)
SelectedTitle.BackgroundTransparency = 1
SelectedTitle.Font = Enum.Font.GothamBold
SelectedTitle.TextSize = 13
SelectedTitle.TextColor3 = SMILE.TextLight
SelectedTitle.TextXAlignment = Enum.TextXAlignment.Left
SelectedTitle.Text = "V1"
SelectedTitle.ZIndex = 6
SelectedTitle.Parent = InfoHeader

local CodeBadge = Instance.new("TextLabel")
CodeBadge.Size = UDim2.fromOffset(66, 16)
CodeBadge.Position = UDim2.new(1, -70, 0, 3)
CodeBadge.BackgroundColor3 = SMILE.InsetDark
CodeBadge.BorderSizePixel = 0
CodeBadge.Font = Enum.Font.Code
CodeBadge.TextSize = 10
CodeBadge.TextColor3 = SMILE.AccentGold
CodeBadge.Text = "MCH-V1"
CodeBadge.ZIndex = 6
CodeBadge.Parent = InfoHeader

local SelectedSub = Instance.new("TextLabel")
SelectedSub.Size = UDim2.new(1, -16, 0, 16)
SelectedSub.Position = UDim2.fromOffset(8, 28)
SelectedSub.BackgroundTransparency = 1
SelectedSub.Font = Enum.Font.Code
SelectedSub.TextSize = 11
SelectedSub.TextColor3 = SMILE.AccentGold
SelectedSub.TextXAlignment = Enum.TextXAlignment.Left
SelectedSub.Text = "SUPREME MACHINE // MODEL V1"
SelectedSub.ZIndex = 5
SelectedSub.Parent = InfoWindow

local SelectedDesc = Instance.new("TextLabel")
SelectedDesc.Size = UDim2.new(1, -16, 0, 46)
SelectedDesc.Position = UDim2.fromOffset(8, 46)
SelectedDesc.BackgroundTransparency = 1
SelectedDesc.Font = Enum.Font.Code
SelectedDesc.TextSize = 11
SelectedDesc.TextColor3 = SMILE.TextLight
SelectedDesc.TextXAlignment = Enum.TextXAlignment.Left
SelectedDesc.TextYAlignment = Enum.TextYAlignment.Top
SelectedDesc.TextWrapped = true
SelectedDesc.Text = ""
SelectedDesc.ZIndex = 5
SelectedDesc.Parent = InfoWindow

-- Scanline flash overlay for smooth selection feedback
local SelectFlash = Instance.new("Frame")
SelectFlash.Size = UDim2.new(1, -4, 1, -26)
SelectFlash.Position = UDim2.fromOffset(2, 24)
SelectFlash.BackgroundColor3 = SMILE.AccentRed
SelectFlash.BackgroundTransparency = 1
SelectFlash.BorderSizePixel = 0
SelectFlash.ZIndex = 7
SelectFlash.Parent = InfoWindow

-- Action Row inside InfoWindow
local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -16, 0, 32)
ActionRow.Position = UDim2.new(0, 8, 1, -40)
ActionRow.BackgroundTransparency = 1
ActionRow.ZIndex = 6
ActionRow.Parent = InfoWindow

local function makeSmileActionButton(parent, text, size, pos, isPrimary, accentTextColor)
	local baseCol = isPrimary and SMILE.BtnPressedRed or SMILE.BtnFace
	local hoverCol = isPrimary and Color3.fromRGB(205, 40, 40) or SMILE.BtnHover
	local txtCol = isPrimary and SMILE.TextLight or (accentTextColor or SMILE.TextDark)

	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = baseCol
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = txtCol
	btn.Text = text
	btn.AutoButtonColor = false
	btn.ZIndex = 6
	btn.Parent = parent

	local bev = createBevel(btn, false, 2)
	addOutline(btn, SMILE.BorderOuter, 1)

	local textLabelPos = UDim2.fromOffset(0, 0)
	local inner = Instance.new("TextLabel")
	inner.Size = UDim2.fromScale(1, 1)
	inner.Position = textLabelPos
	inner.BackgroundTransparency = 1
	inner.Font = Enum.Font.GothamBold
	inner.TextSize = 12
	inner.TextColor3 = txtCol
	inner.Text = text
	inner.ZIndex = 8
	inner.Parent = btn
	btn.Text = ""

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = hoverCol }):Play()
	end)
	btn.MouseLeave:Connect(function()
		bev.setPressed(false)
		inner.Position = textLabelPos
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = baseCol }):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		bev.setPressed(true)
		inner.Position = UDim2.fromOffset(1, 1)
	end)
	btn.MouseButton1Up:Connect(function()
		bev.setPressed(false)
		inner.Position = textLabelPos
	end)

	return btn
end

local DeployBtn = makeSmileActionButton(ActionRow, "DEPLOY", UDim2.new(0.40, -4, 1, 0), UDim2.fromScale(0, 0), true)
local RebuildBtn = makeSmileActionButton(ActionRow, "REBUILD", UDim2.new(0.32, -4, 1, 0), UDim2.new(0.40, 2, 0, 0), false)
local UnloadBtn = makeSmileActionButton(ActionRow, "UNLOAD", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.72, 4, 0, 0), false, SMILE.TextMutedDark)

-- Terminal Output Box (Inset OS Log Well)
local LogHeaderBar = Instance.new("Frame")
LogHeaderBar.Size = UDim2.new(1, 0, 0, 18)
LogHeaderBar.Position = UDim2.fromOffset(0, 152)
LogHeaderBar.BackgroundColor3 = SMILE.WinFaceAlt
LogHeaderBar.BorderSizePixel = 0
LogHeaderBar.ZIndex = 4
LogHeaderBar.Parent = RightArea
createBevel(LogHeaderBar, false, 1)

local LogHeader = Instance.new("TextLabel")
LogHeader.Size = UDim2.new(1, -10, 1, 0)
LogHeader.Position = UDim2.fromOffset(6, 0)
LogHeader.BackgroundTransparency = 1
LogHeader.Font = Enum.Font.GothamBold
LogHeader.TextSize = 10
LogHeader.TextColor3 = SMILE.TextDark
LogHeader.TextXAlignment = Enum.TextXAlignment.Left
LogHeader.Text = "SYSTEM OUTPUT"
LogHeader.ZIndex = 5
LogHeader.Parent = LogHeaderBar

local LogBox = Instance.new("ScrollingFrame")
LogBox.Size = UDim2.new(1, 0, 1, -228)
LogBox.Position = UDim2.fromOffset(0, 171)
LogBox.BackgroundColor3 = SMILE.InsetDark
LogBox.BorderSizePixel = 0
LogBox.ScrollBarThickness = 4
LogBox.ScrollBarImageColor3 = SMILE.WinFace
LogBox.CanvasSize = UDim2.new(0, 0, 0, 0)
LogBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogBox.ZIndex = 4
LogBox.Parent = RightArea
createBevel(LogBox, true, 2)

local LogLayout = Instance.new("UIListLayout")
LogLayout.Padding = UDim.new(0, 2)
LogLayout.Parent = LogBox

local LogPad = Instance.new("UIPadding")
LogPad.PaddingTop = UDim.new(0, 5)
LogPad.PaddingBottom = UDim.new(0, 5)
LogPad.PaddingLeft = UDim.new(0, 7)
LogPad.PaddingRight = UDim.new(0, 7)
LogPad.Parent = LogBox

-- Signature SmileOS 2.0 "Tip of the Day" Inset Box
local TipPanel = Instance.new("Frame")
TipPanel.Size = UDim2.new(1, 0, 0, 52)
TipPanel.Position = UDim2.new(0, 0, 1, -52)
TipPanel.BackgroundColor3 = SMILE.InsetLight
TipPanel.BorderSizePixel = 0
TipPanel.ZIndex = 4
TipPanel.Parent = RightArea
createBevel(TipPanel, true, 2)

local TipMiniHeader = Instance.new("Frame")
TipMiniHeader.Size = UDim2.new(1, -4, 0, 16)
TipMiniHeader.Position = UDim2.fromOffset(2, 2)
TipMiniHeader.BackgroundColor3 = SMILE.HeaderBot
TipMiniHeader.BorderSizePixel = 0
TipMiniHeader.ZIndex = 5
TipMiniHeader.Parent = TipPanel

local TipBadge = Instance.new("TextLabel")
TipBadge.Size = UDim2.fromOffset(14, 12)
TipBadge.Position = UDim2.fromOffset(3, 2)
TipBadge.BackgroundColor3 = SMILE.AccentGold
TipBadge.BorderSizePixel = 0
TipBadge.Font = Enum.Font.GothamBold
TipBadge.TextSize = 10
TipBadge.TextColor3 = SMILE.TextDark
TipBadge.Text = "!"
TipBadge.ZIndex = 6
TipBadge.Parent = TipMiniHeader

local TipTitle = Instance.new("TextLabel")
TipTitle.Size = UDim2.new(1, -24, 1, 0)
TipTitle.Position = UDim2.fromOffset(21, 0)
TipTitle.BackgroundTransparency = 1
TipTitle.Font = Enum.Font.GothamBold
TipTitle.TextSize = 10
TipTitle.TextColor3 = SMILE.TextLight
TipTitle.TextXAlignment = Enum.TextXAlignment.Left
TipTitle.Text = "TIP OF THE DAY"
TipTitle.ZIndex = 6
TipTitle.Parent = TipMiniHeader

local TipBar = Instance.new("TextLabel")
TipBar.Size = UDim2.new(1, -14, 1, -22)
TipBar.Position = UDim2.fromOffset(7, 20)
TipBar.BackgroundTransparency = 1
TipBar.Font = Enum.Font.Code
TipBar.TextSize = 11
TipBar.TextColor3 = SMILE.TextDark
TipBar.TextXAlignment = Enum.TextXAlignment.Left
TipBar.TextYAlignment = Enum.TextYAlignment.Center
TipBar.TextWrapped = true
TipBar.Text = TIPS[math.random(1, #TIPS)]
TipBar.ZIndex = 5
TipBar.Parent = TipPanel

-- ============================================================================
-- BOTTOM SMILEOS 2.0 TASKBAR
-- ============================================================================
local Taskbar = Instance.new("Frame")
Taskbar.Name = "Taskbar"
Taskbar.Size = UDim2.new(1, -4, 0, 26)
Taskbar.Position = UDim2.new(0, 2, 1, -28)
Taskbar.BackgroundColor3 = SMILE.TaskbarBg
Taskbar.BorderSizePixel = 0
Taskbar.ZIndex = 5
Taskbar.Parent = MainFrame
createBevel(Taskbar, false, 1)

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.fromOffset(96, 20)
StartBtn.Position = UDim2.fromOffset(3, 3)
StartBtn.BackgroundColor3 = SMILE.BtnPressedRed
StartBtn.BorderSizePixel = 0
StartBtn.Text = ""
StartBtn.AutoButtonColor = false
StartBtn.ZIndex = 6
StartBtn.Parent = Taskbar
local startBevel = createBevel(StartBtn, false, 1)
addOutline(StartBtn, SMILE.BorderOuter, 1)

createSmileyIcon(StartBtn, 14, UDim2.fromOffset(4, 3), SMILE.InsetLight, SMILE.TextDark)

local StartLabel = Instance.new("TextLabel")
StartLabel.Size = UDim2.new(1, -22, 1, 0)
StartLabel.Position = UDim2.fromOffset(22, 0)
StartLabel.BackgroundTransparency = 1
StartLabel.Font = Enum.Font.GothamBold
StartLabel.TextSize = 11
StartLabel.TextColor3 = SMILE.TextLight
StartLabel.TextXAlignment = Enum.TextXAlignment.Left
StartLabel.Text = "SmileOS"
StartLabel.ZIndex = 7
StartLabel.Parent = StartBtn

local TaskTermPill = Instance.new("Frame")
TaskTermPill.Size = UDim2.fromOffset(128, 20)
TaskTermPill.Position = UDim2.fromOffset(104, 3)
TaskTermPill.BackgroundColor3 = SMILE.WinFaceAlt
TaskTermPill.BorderSizePixel = 0
TaskTermPill.ZIndex = 6
TaskTermPill.Parent = Taskbar
createBevel(TaskTermPill, true, 1)

local TaskTermLabel = Instance.new("TextLabel")
TaskTermLabel.Size = UDim2.new(1, -10, 1, 0)
TaskTermLabel.Position = UDim2.fromOffset(6, 0)
TaskTermLabel.BackgroundTransparency = 1
TaskTermLabel.Font = Enum.Font.Code
TaskTermLabel.TextSize = 11
TaskTermLabel.TextColor3 = SMILE.TextDark
TaskTermLabel.TextXAlignment = Enum.TextXAlignment.Left
TaskTermLabel.Text = "TERMINAL.EXE"
TaskTermLabel.ZIndex = 7
TaskTermLabel.Parent = TaskTermPill

local TaskStatusLabel = Instance.new("TextLabel")
TaskStatusLabel.Size = UDim2.new(1, -310, 0, 20)
TaskStatusLabel.Position = UDim2.fromOffset(238, 3)
TaskStatusLabel.BackgroundTransparency = 1
TaskStatusLabel.Font = Enum.Font.Code
TaskStatusLabel.TextSize = 10
TaskStatusLabel.TextColor3 = SMILE.TextMutedDark
TaskStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
TaskStatusLabel.Text = "STATUS: READY"
TaskStatusLabel.ZIndex = 6
TaskStatusLabel.Parent = Taskbar

local ClockTray = Instance.new("Frame")
ClockTray.Size = UDim2.fromOffset(66, 20)
ClockTray.Position = UDim2.new(1, -69, 0, 3)
ClockTray.BackgroundColor3 = SMILE.WinFaceAlt
ClockTray.BorderSizePixel = 0
ClockTray.ZIndex = 6
ClockTray.Parent = Taskbar
createBevel(ClockTray, true, 1)

local ClockText = Instance.new("TextLabel")
ClockText.Size = UDim2.fromScale(1, 1)
ClockText.BackgroundTransparency = 1
ClockText.Font = Enum.Font.Code
ClockText.TextSize = 11
ClockText.TextColor3 = SMILE.TextDark
ClockText.Text = os.date("%H:%M")
ClockText.ZIndex = 7
ClockText.Parent = ClockTray

StartBtn.MouseButton1Down:Connect(function()
	startBevel.setPressed(true)
end)
StartBtn.MouseButton1Up:Connect(function()
	startBevel.setPressed(false)
end)
StartBtn.MouseLeave:Connect(function()
	startBevel.setPressed(false)
end)
StartBtn.Activated:Connect(function()
	TipBar.Text = TIPS[math.random(1, #TIPS)]
end)

-- ============================================================================
-- TERMINAL LOGGING & WINDOW CONTROLS
-- ============================================================================
local function setStatus(text, color)
	if TaskStatusLabel and TaskStatusLabel.Parent then
		TaskStatusLabel.Text = "STATUS: " .. tostring(text)
		TaskStatusLabel.TextColor3 = color or SMILE.TextMutedDark
	end
end

local function logLine(msg, color)
	if not LogBox or not LogBox.Parent then return end
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 11
	lbl.TextColor3 = color or SMILE.TextLight
	lbl.TextTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Text = "> " .. tostring(msg)
	lbl.ZIndex = 5
	lbl.Parent = LogBox

	TweenService:Create(lbl, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	}):Play()

	task.defer(function()
		if LogBox and LogBox.Parent then
			LogBox.CanvasPosition = Vector2.new(0, LogBox.AbsoluteCanvasSize.Y)
		end
	end)
end

makeDraggable(TitleBar, MainFrame, ScreenGui)

local minimized = false
MinBtn.Activated:Connect(function()
	minimized = not minimized
	if not minimized then
		Body.Visible = true
		Taskbar.Visible = true
	end
	local tw = TweenService:Create(MainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = minimized and UDim2.fromOffset(FULL_WIDTH, COLLAPSED_HEIGHT) or UDim2.fromOffset(FULL_WIDTH, FULL_HEIGHT),
	})
	tw.Completed:Connect(function()
		if minimized and MainFrame and MainFrame.Parent then
			Body.Visible = false
			Taskbar.Visible = false
		end
		if MainFrame and MainFrame.Parent then
			clampWindowToScreen(MainFrame, ScreenGui)
		end
	end)
	tw:Play()
	MinBtn.Text = minimized and "+" or "_"
end)

-- ============================================================================
-- REMOTE MODULE FETCHER & ANTI-GRIEF BRIDGE
-- ============================================================================
local activeController = nil
local agController = nil
local agLoading = false
local agWindowOpen = false
local isBusy = false
local selectedChar = CHARACTERS[1]

local function fetchAndCompile(relPath)
	local cacheBuster = HttpService:GenerateGUID(false) .. "_" .. tostring(math.floor(os.clock() * 1000))
	local url = BASE_URL .. relPath .. "?t=" .. cacheBuster
	logLine("GET " .. relPath .. " ...", SMILE.TextMutedLight)

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

local function updateAntiGriefButtonVisual(isOpen)
	agWindowOpen = isOpen
	if not AntiGriefBtn or not AntiGriefBtn.Parent then return end
	agBtnBevel.setPressed(isOpen)
	if isOpen then
		AntiGriefBtn.BackgroundColor3 = SMILE.BtnPressedRed
		AntiGriefBtn.TextColor3 = SMILE.TextLight
		agDot.BackgroundColor3 = SMILE.SuccessGreen
	else
		AntiGriefBtn.BackgroundColor3 = SMILE.BtnFace
		AntiGriefBtn.TextColor3 = SMILE.TextDark
		agDot.BackgroundColor3 = SMILE.BevelDark
	end
end

local function loadAntiGrief(openAfterLoad)
	if agController or agLoading or not terminalAlive then
		return agController ~= nil
	end
	agLoading = true

	local agFn, agErr = fetchAndCompile("Antigrief.lua")
	if not terminalAlive then
		agLoading = false
		return false
	end
	if not agFn then
		logLine("Antigrief.lua warning: " .. tostring(agErr), SMILE.AccentGold)
		agLoading = false
		return false
	end

	local okMod, agModule = pcall(agFn)
	if not okMod then
		logLine("Error loading Antigrief.lua: " .. tostring(agModule), SMILE.AccentRed)
		agLoading = false
		return false
	end

	local ctx = {
		THEME = THEME,
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		onStateChanged = updateAntiGriefButtonVisual,
	}

	local ctrl = agModule
	if type(agModule) == "function" then
		local okInit, initRes = pcall(agModule, ctx)
		if not okInit then
			logLine("Runtime error in Antigrief.lua: " .. tostring(initRes), SMILE.AccentRed)
			agLoading = false
			return false
		end
		ctrl = initRes
	elseif type(agModule) == "table" and type(agModule.init) == "function" then
		local okInit, initRes = pcall(agModule.init, ctx)
		if not okInit then
			logLine("Init error in Antigrief.lua: " .. tostring(initRes), SMILE.AccentRed)
			agLoading = false
			return false
		end
		ctrl = initRes or agModule
	end

	if not terminalAlive then
		if type(ctrl) == "table" and type(ctrl.cleanup) == "function" then
			pcall(ctrl.cleanup)
		end
		agLoading = false
		return false
	end

	agController = ctrl
	agLoading = false
	logLine("Antigrief.lua online.", SMILE.SuccessGreen)

	if openAfterLoad and type(agController) == "table" and type(agController.setOpen) == "function" then
		agController.setOpen(true)
	end
	return true
end

local function markRigDeployGrace(seconds)
	if type(agController) == "table" and type(agController.markRigDeployGrace) == "function" then
		pcall(agController.markRigDeployGrace, seconds)
	end
end

local function clearProtectedRig()
	if type(agController) == "table" and type(agController.clearProtectedRig) == "function" then
		pcall(agController.clearProtectedRig)
	end
end

AntiGriefBtn.MouseEnter:Connect(function()
	if not agWindowOpen then
		TweenService:Create(AntiGriefBtn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnHover }):Play()
	end
end)

AntiGriefBtn.MouseLeave:Connect(function()
	if not agWindowOpen then
		TweenService:Create(AntiGriefBtn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnFace }):Play()
	end
end)

AntiGriefBtn.Activated:Connect(function()
	if type(agController) == "table" and type(agController.toggle) == "function" then
		agController.toggle()
	elseif agLoading then
		logLine("Antigrief.lua is still loading...", SMILE.AccentGold)
	else
		task.spawn(function()
			loadAntiGrief(true)
		end)
	end
end)

-- ============================================================================
-- LOADER ENGINE (CORE -> CHARACTER(CORE) HANDOFF)
-- ============================================================================
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
			logLine("Controller cleanup error: " .. tostring(err), SMILE.AccentRed)
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
				logLine(globalName .. " error: " .. tostring(err), SMILE.AccentRed)
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

	clearProtectedRig()

	if cleaned > 0 then
		logLine("Cleaned previous rig (" .. cleaned .. " hook(s)).", SMILE.TextMutedLight)
	end
end

local function deployCharacter(charData)
	if isBusy then
		logLine("Terminal busy. Wait for current operation.", SMILE.AccentGold)
		return
	end
	if not charData.unlocked or not charData.path then
		logLine(charData.name .. " is locked / not yet deployed.", SMILE.AccentGold)
		return
	end

	isBusy = true
	setStatus("DEPLOYING " .. charData.name, SMILE.HeaderBot)
	markRigDeployGrace(4.5)
	cleanupActiveRig()

	local Core = {}
	local coreFn, coreErr = fetchAndCompile("core.lua")
	if coreFn then
		local okCore, loadedCore = pcall(coreFn)
		if okCore and type(loadedCore) == "table" then
			Core = loadedCore
			logLine("core.lua loaded.", SMILE.SuccessGreen)
		else
			logLine("core.lua invalid return; using fallback Core.", SMILE.AccentGold)
		end
	else
		logLine("core.lua warning: " .. tostring(coreErr) .. " (using fallback Core)", SMILE.AccentGold)
	end

	local charFn, charErr = fetchAndCompile(charData.path)
	if not charFn then
		logLine(tostring(charErr), SMILE.AccentRed)
		setStatus("FETCH ERROR", SMILE.AccentRed)
		isBusy = false
		return
	end

	local okMod, charModule = pcall(charFn)
	if not okMod then
		logLine("Error loading " .. charData.path .. ": " .. tostring(charModule), SMILE.AccentRed)
		setStatus("LOAD ERROR", SMILE.AccentRed)
		isBusy = false
		return
	end

	local result = charModule
	markRigDeployGrace(4.0)
	if type(charModule) == "function" then
		logLine("Initializing " .. charData.name .. "(Core)...", SMILE.TextMutedLight)
		local okInit, initRes = pcall(charModule, Core)
		if not okInit then
			logLine("Runtime error in " .. charData.path .. ": " .. tostring(initRes), SMILE.AccentRed)
			setStatus("RUNTIME ERROR", SMILE.AccentRed)
			isBusy = false
			return
		end
		result = initRes
	elseif type(charModule) == "table" and type(charModule.init) == "function" then
		local okInit, initRes = pcall(charModule.init, Core)
		if not okInit then
			logLine("Init error in " .. charData.path .. ": " .. tostring(initRes), SMILE.AccentRed)
			setStatus("INIT ERROR", SMILE.AccentRed)
			isBusy = false
			return
		end
		result = initRes or charModule
	end

	activeController = result
	logLine("DEPLOYED: " .. charData.name .. " ACTIVE.", SMILE.SuccessGreen)
	setStatus(charData.name .. " ACTIVE", Color3.fromRGB(28, 128, 44))
	isBusy = false
end

local function triggerRebuild()
	markRigDeployGrace(3.5)
	setStatus("REBUILDING...", SMILE.HeaderBot)
	if type(activeController) == "table" and type(activeController.rebuild) == "function" then
		local ok, err = pcall(activeController.rebuild)
		logLine(ok and "Rebuild triggered via controller." or ("Rebuild error: " .. tostring(err)), ok and SMILE.SuccessGreen or SMILE.AccentRed)
		setStatus(ok and (selectedChar.name .. " ACTIVE") or "REBUILD ERROR", ok and Color3.fromRGB(28, 128, 44) or SMILE.AccentRed)
		return
	end

	for _, store in ipairs({ env, _G }) do
		if type(store.ULTRAKILL_F3X) == "table" and type(store.ULTRAKILL_F3X.rebuild) == "function" then
			local ok, err = pcall(store.ULTRAKILL_F3X.rebuild)
			logLine(ok and "Rebuild triggered via ULTRAKILL_F3X." or ("Rebuild error: " .. tostring(err)), ok and SMILE.SuccessGreen or SMILE.AccentRed)
			return
		end
	end

	for _, globalName in ipairs(LEGACY_REBUILD_GLOBALS) do
		local fn = getGlobalFn(globalName)
		if fn then
			local ok, err = pcall(fn)
			logLine(ok and ("Rebuild triggered (" .. globalName .. ").") or ("Rebuild error: " .. tostring(err)), ok and SMILE.SuccessGreen or SMILE.AccentRed)
			return
		end
	end

	logLine("No active rebuild hook found. Redeploying " .. selectedChar.name .. "...", SMILE.AccentGold)
	task.spawn(function()
		deployCharacter(selectedChar)
	end)
end

-- ============================================================================
-- POPULATE SIDEBAR & WIRE BUTTONS
-- ============================================================================
local sideButtons = {}

local function selectCharacter(charData, skipFlash)
	selectedChar = charData
	SelectedTitle.Text = charData.name
	CodeBadge.Text = charData.code or "MCH"
	SelectedSub.Text = charData.subtitle
	SelectedDesc.Text = charData.desc

	if not skipFlash then
		SelectFlash.BackgroundTransparency = 0.72
		TweenService:Create(SelectFlash, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end

	for _, entry in ipairs(sideButtons) do
		local isSel = (entry.data.id == charData.id)
		entry.bevel.setPressed(isSel)
		entry.arrow.Visible = isSel

		local targetBg
		if isSel then
			targetBg = SMILE.BtnPressedRed
		elseif entry.data.unlocked then
			targetBg = SMILE.BtnFace
		else
			targetBg = SMILE.BtnLocked
		end

		TweenService:Create(entry.btn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = targetBg,
		}):Play()

		entry.label.TextColor3 = isSel and SMILE.TextLight or (entry.data.unlocked and SMILE.TextDark or SMILE.TextMutedDark)
	end
end

for _, charData in ipairs(CHARACTERS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = charData.unlocked and SMILE.BtnFace or SMILE.BtnLocked
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 5
	btn.Parent = SideList
	local bev = createBevel(btn, false, 2)
	addOutline(btn, SMILE.BevelMid, 1)

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromOffset(14, 32)
	arrow.Position = UDim2.fromOffset(5, 0)
	arrow.BackgroundTransparency = 1
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 12
	arrow.TextColor3 = SMILE.AccentGold
	arrow.Text = ">"
	arrow.Visible = false
	arrow.ZIndex = 6
	arrow.Parent = btn

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -24, 1, 0)
	lbl.Position = UDim2.fromOffset(19, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextColor3 = charData.unlocked and SMILE.TextDark or SMILE.TextMutedDark
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = charData.unlocked and charData.name or (charData.name .. " [LOCK]")
	lbl.ZIndex = 6
	lbl.Parent = btn

	table.insert(sideButtons, { data = charData, btn = btn, bevel = bev, arrow = arrow, label = lbl })

	btn.MouseEnter:Connect(function()
		if selectedChar.id ~= charData.id and charData.unlocked then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnHover }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if selectedChar.id ~= charData.id then
			TweenService:Create(btn, TweenInfo.new(0.1), {
				BackgroundColor3 = charData.unlocked and SMILE.BtnFace or SMILE.BtnLocked,
			}):Play()
		end
	end)
	btn.Activated:Connect(function()
		selectCharacter(charData, false)
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
	setStatus("STANDBY", SMILE.TextMutedDark)
	logLine("All active rigs unloaded.", SMILE.AccentGold)
end)

local function fullTerminalCleanup()
	terminalAlive = false
	if type(agController) == "table" and type(agController.cleanup) == "function" then
		pcall(agController.cleanup)
	end
	agController = nil

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

CloseBtn.Activated:Connect(function()
	local tw = TweenService:Create(MainFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(FULL_WIDTH, 0),
	})
	tw.Completed:Connect(fullTerminalCleanup)
	tw:Play()
end)

-- Live taskbar clock loop
task.spawn(function()
	while terminalAlive do
		if ClockText and ClockText.Parent then
			ClockText.Text = os.date("%H:%M")
		end
		task.wait(5)
	end
end)

-- ============================================================================
-- BOOT ANIMATION & INITIALIZATION
-- ============================================================================
selectCharacter(CHARACTERS[1], true)

task.spawn(function()
	TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(FULL_WIDTH, FULL_HEIGHT),
	}):Play()

	TweenService:Create(BootBarFill, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, -4, 1, -4),
	}):Play()

	task.wait(0.72)
	if not terminalAlive then return end

	local fadeSplash = TweenService:Create(BootSplash, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	})
	for _, d in ipairs(BootSplash:GetDescendants()) do
		if d:IsA("TextLabel") then
			TweenService:Create(d, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		end
	end
	fadeSplash.Completed:Connect(function()
		if BootSplash and BootSplash.Parent then
			BootSplash:Destroy()
		end
	end)
	fadeSplash:Play()

	logLine("SmileOS 2.0 Terminal ready.", SMILE.SuccessGreen)
	logLine("Select a machine and press DEPLOY.", SMILE.TextMutedLight)

	loadAntiGrief(false)
end)