-- ULTRAKILL // F3X ANTI-GRIEF SUBSYSTEM (SmileOS 2.0 — SENTINEL ULTRA)
-- Module for loader.lua (also supports standalone execution)

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local DEFAULT_SMILE = {
	WinFace = Color3.fromRGB(214, 210, 204),
	WinFaceAlt = Color3.fromRGB(198, 193, 186),
	BevelLight = Color3.fromRGB(250, 248, 244),
	BevelMid = Color3.fromRGB(162, 157, 150),
	BevelDark = Color3.fromRGB(78, 74, 72),
	BorderOuter = Color3.fromRGB(32, 28, 28),

	HeaderTop = Color3.fromRGB(204, 36, 36),
	HeaderBot = Color3.fromRGB(122, 16, 16),

	BtnFace = Color3.fromRGB(224, 220, 214),
	BtnHover = Color3.fromRGB(238, 234, 228),
	BtnPressedRed = Color3.fromRGB(182, 28, 28),
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

local DEFAULT_THEME = {
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

local HOSTILE_JOINT_OR_MOVER_CLASSES = {
	Weld = true,
	WeldConstraint = true,
	ManualWeld = true,
	Snap = true,
	Glue = true,
	Motor = true,
	Motor6D = true,
	BodyForce = true,
	BodyVelocity = true,
	BodyPosition = true,
	BodyGyro = true,
	BodyAngularVelocity = true,
	BodyThrust = true,
	RocketPropulsion = true,
	LinearVelocity = true,
	AngularVelocity = true,
	AlignPosition = true,
	AlignOrientation = true,
	Torque = true,
	VectorForce = true,
	RopeConstraint = true,
	SpringConstraint = true,
	HingeConstraint = true,
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
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
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

local TRACKED_PART_PROPS = {
	CFrame = true,
	Size = true,
	Anchored = true,
	CanCollide = true,
	Transparency = true,
	Color = true,
	Material = true,
	Reflectance = true,
	Locked = true,
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

local function vectorDiffers(a, b)
	return (a - b).Magnitude > 0.03
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

local function isProtectedWorldSystem(inst)
	if inst:IsA("Terrain") or inst:IsA("Camera") then
		return true
	end
	local cam = workspace.CurrentCamera
	if cam and (inst == cam or inst:IsDescendantOf(cam)) then
		return true
	end
	return false
end

local function findF3XInContainer(container, directOnly)
	if not container then return nil, nil end
	for _, item in ipairs(container:GetChildren()) do
		if item.Name ~= "StarterGear" then
			local syncAPI = item:FindFirstChild("SyncAPI") or item:FindFirstChild("SyncApi")
			if syncAPI then
				local endpoint = syncAPI:FindFirstChild("ServerEndpoint") or syncAPI:FindFirstChild("ServerControl")
				if endpoint and endpoint:IsA("RemoteFunction") then
					return endpoint, item
				end
			end
		end
	end
	if not directOnly then
		for _, desc in ipairs(container:GetDescendants()) do
			if desc.Name == "SyncAPI" or desc.Name == "SyncApi" then
				local endpoint = desc:FindFirstChild("ServerEndpoint") or desc:FindFirstChild("ServerControl")
				if endpoint and endpoint:IsA("RemoteFunction") then
					return endpoint, desc.Parent
				end
			end
		end
	end
	return nil, nil
end

local function runParallel(count, maxWorkers, workerFn)
	if count <= 0 then return end
	local workers = math.min(maxWorkers or 10, count)
	local nextIndex = 0
	local activeWorkers = workers
	local doneEvent = Instance.new("BindableEvent")
	for _ = 1, workers do
		task.spawn(function()
			while true do
				nextIndex += 1
				local idx = nextIndex
				if idx > count then break end
				pcall(workerFn, idx)
			end
			activeWorkers -= 1
			if activeWorkers <= 0 then
				doneEvent:Fire()
			end
		end)
	end
	if activeWorkers > 0 then
		doneEvent.Event:Wait()
	end
	doneEvent:Destroy()
end

return function(ctx)
	ctx = ctx or {}
	local SMILE = ctx.SMILE or DEFAULT_SMILE
	local THEME = ctx.THEME or DEFAULT_THEME
	local MainFrame = ctx.MainFrame
	local onStateChanged = ctx.onStateChanged

	local createdOwnGui = false
	local ScreenGui = ctx.ScreenGui
	if not ScreenGui or not ScreenGui.Parent then
		local guiParent = getGuiParent()
		local existing = guiParent:FindFirstChild("ULTRAKILL_ANTIGRIEF_SYS")
		if existing then
			existing:Destroy()
		end
		ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "ULTRAKILL_ANTIGRIEF_SYS"
		ScreenGui.ResetOnSpawn = false
		ScreenGui.IgnoreGuiInset = true
		pcall(function()
			ScreenGui.ScreenInsets = Enum.ScreenInsets.None
		end)
		ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ScreenGui.Parent = guiParent
		createdOwnGui = true
	end

	local agAlive = true
	local agConnections = {}
	local function trackConn(conn)
		table.insert(agConnections, conn)
		return conn
	end

	-- ========================================================================
	-- SMILEOS 2.0 CHROME UI HELPERS (MATCHING LOADER.LUA)
	-- ========================================================================
	local function addOutline(parent, color, thickness)
		local s = Instance.new("UIStroke")
		s.Color = color or SMILE.BorderOuter
		s.Thickness = thickness or 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = parent
		return s
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
		}
	end

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

	local function makeDraggable(handle, window)
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
				local vp = getScreenSize(ScreenGui)
				local absW, absH = window.AbsoluteSize.X, window.AbsoluteSize.Y
				local baseX = startPos.X.Scale * vp.X + startPos.X.Offset + delta.X
				local baseY = startPos.Y.Scale * vp.Y + startPos.Y.Offset + delta.Y
				local clampedX = math.clamp(baseX, 0, math.max(0, vp.X - absW))
				local clampedY = math.clamp(baseY, 0, math.max(0, vp.Y - absH))
				window.Position = UDim2.fromOffset(clampedX, clampedY)
			end
		end))
	end

	-- ========================================================================
	-- SENTINEL ULTRA ENGINE CONFIG & STATE
	-- ========================================================================
	local AG_CONFIG = {
		BatchSize = 80,
		MaxConcurrentInvokes = 10,
		MaxConcurrentBatches = 4,
		WorkerInterval = 0.08,
		TamperSliceSize = 700,
		TamperInterval = 0.04,
		MaxDirectPartWatchers = 3500,
		GiantSizeThreshold = 95,
		FlashNeonSizeThreshold = 12,
		TrapCheckRadius = 18,
		FloodRateWindow = 1.0,
		FloodRateThreshold = 7,
		VoidThresholdY = -120,
		FlingVelocityThreshold = 170,
		ClearRadius = 45,
		MaxLogEntries = 80,
		AutoCounterThreshold = 14,
		AutoCounterCooldown = 15,
		AutoSnapshotOnInit = true,
	}

	local FILTER_MODES = { "Effects Only", "Smart Threats", "Strict Lockdown" }

	local agState = {
		windowOpen = false,
		windowMinimized = false,
		activeSlot = 1,
		snapshots = { [1] = nil, [2] = nil, [3] = nil },
		whitelist = { [LocalPlayer.UserId] = true },
		blacklist = {},
		threatScores = {},
		lastCounterTime = {},
		liveGuard = false,
		autoClean = true,
		localQuarantine = true,
		filterModeIndex = 2,
		antiFling = true,
		antiVoid = true,
		charShield = true,
		autoLockSelf = true,
		autoLockAfterRestore = true,
		autoEquipF3X = false,
		autoCounter = false,
		isBusy = false,
		threatsBlocked = 0,
		restoresPerformed = 0,
		scanCursor = 1,
		lastSafeCFrame = nil,
		f3xRequestedThisLife = false,
		rigDeployGraceUntil = 0,
	}

	local Runtime = {
		cachedEndpoint = nil,
		cachedTool = nil,
		selfRestoringDepth = 0,
		restoreInFlight = false,
		nextLogOrder = 0,
		charRootSet = {},
		scriptManagedParts = setmetatable({}, { __mode = "k" }),
		protectedRigInstances = setmetatable({}, { __mode = "k" }),
		cagedPartsByUserId = {},
		recentForeignBuffer = {},
		tamperHits = setmetatable({}, { __mode = "k" }),
		partWatchConns = {},
		charWatchConns = {},
		charPartBaselineSizes = {},
		pendingRemove = {},
		pendingDeleted = {},
		pendingTampered = {},
		pendingCharUndo = {},
		agLogs = {},
		lastFlingSweep = 0,
	}

	local UI = {}
	local Engine = {}

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

	local function endRigDeployGrace()
		agState.rigDeployGraceUntil = math.min(agState.rigDeployGraceUntil, os.clock() + 0.25)
	end

	local function isCoreHighSpeedAction()
		for _, store in ipairs({ env, _G }) do
			local coreMod = store.ULTRAKILL_F3X
			if type(coreMod) == "table" and type(coreMod.isHighSpeedAction) == "function" then
				local ok, active = pcall(coreMod.isHighSpeedAction)
				if ok and active then
					return true
				end
			end
		end
		return false
	end

	local function importExistingCoreRigParts()
		for _, store in ipairs({ env, _G }) do
			local coreMod = store.ULTRAKILL_F3X
			if type(coreMod) == "table" and type(coreMod.getProtectedParts) == "function" then
				local ok, list = pcall(coreMod.getProtectedParts)
				if ok and type(list) == "table" then
					for _, inst in ipairs(list) do
						if typeof(inst) == "Instance" then
							Runtime.protectedRigInstances[inst] = true
						end
					end
				end
			end
		end
	end

	local function registerCharacter(plr, char)
		for c, p in pairs(Runtime.charRootSet) do
			if p == plr then
				Runtime.charRootSet[c] = nil
			end
		end
		if char then
			Runtime.charRootSet[char] = plr
		end
	end

	local function isPlayerCharacterDescendant(inst)
		if not inst then return false, nil end
		local cur = inst
		while cur and cur ~= workspace and cur ~= game do
			local plr = Runtime.charRootSet[cur]
			if plr then
				return true, plr
			end
			cur = cur.Parent
		end
		return false, nil
	end

	local function isOwnRigPart(inst)
		if not inst then return false end
		local cur = inst
		while cur and cur ~= workspace and cur ~= game do
			if Runtime.protectedRigInstances[cur] then
				return true
			end
			cur = cur.Parent
		end
		return false
	end

	local function isOwnCoreCharacterHelper(inst)
		if not inst then return false end
		if inst.Name == "UK_AntiGrav" or inst.Name == "UK_MoveAtt" or inst.Name == "F3XUK_NoCol" then
			return true
		end
		if inst:IsA("Sound") and inst.Name:sub(1, 3) == "UK_" and (env.ULTRAKILL_F3X ~= nil or _G.ULTRAKILL_F3X ~= nil) then
			return true
		end
		return false
	end

	local function isWhitelistedPlayerNearby(pos, radius)
		local r = radius or 26
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and agState.whitelist[plr.UserId] and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - pos).Magnitude <= r then
					return true
				end
			end
		end
		return false
	end

	local function isBlacklistedPlayerNearby(pos, radius)
		local r = radius or 45
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and agState.blacklist[plr.UserId] and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - pos).Magnitude <= r then
					return true, plr
				end
			end
		end
		return false, nil
	end

	-- ========================================================================
	-- F3X TOOL RESOLUTION & PARALLEL SYNCAPI HELPERS
	-- ========================================================================
	local function playerHasF3X(plr)
		if not plr then return false, false, nil end
		local epChar, toolChar = findF3XInContainer(plr.Character, false)
		if epChar then
			return true, true, toolChar
		end
		local epPack, toolPack = findF3XInContainer(plr:FindFirstChild("Backpack"), false)
		if epPack then
			return true, false, toolPack
		end
		return false, false, nil
	end

	local function getF3XEndpoint(allowAutoRequest)
		local cEp, cTool = Runtime.cachedEndpoint, Runtime.cachedTool
		if cEp and cEp.Parent and cTool and cTool.Parent then
			if cTool:IsDescendantOf(LocalPlayer) or (LocalPlayer.Character and cTool:IsDescendantOf(LocalPlayer.Character)) then
				return cEp, cTool
			end
		end
		Runtime.cachedEndpoint = nil
		Runtime.cachedTool = nil

		local containers = {
			{ c = LocalPlayer.Character, direct = false },
			{ c = LocalPlayer:FindFirstChild("Backpack"), direct = false },
			{ c = LocalPlayer:FindFirstChild("PlayerGui"), direct = false },
			{ c = LocalPlayer, direct = true },
		}

		for _, entry in ipairs(containers) do
			local ep, tool = findF3XInContainer(entry.c, entry.direct)
			if ep then
				Runtime.cachedEndpoint = ep
				Runtime.cachedTool = tool
				return ep, tool
			end
		end

		if allowAutoRequest and not agState.f3xRequestedThisLife then
			agState.f3xRequestedThisLife = true
			pcall(function()
				Players:Chat(":f3x")
			end)
		end

		return nil, nil
	end

	local function withF3X(allowAutoRequest, isAction, fn)
		local ep, tool = getF3XEndpoint(allowAutoRequest)
		if not ep then return nil, "F3X not found" end

		local prevEquipped = nil
		local didEquip = false
		if isAction and agState.autoEquipF3X and tool and tool:IsA("Tool") then
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hum and tool.Parent ~= char then
				prevEquipped = char:FindFirstChildOfClass("Tool")
				pcall(function()
					hum:EquipTool(tool)
				end)
				didEquip = true
			end
		end

		local ok, r1, r2, r3 = pcall(fn, ep, tool)

		if didEquip then
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				pcall(function()
					if prevEquipped and prevEquipped.Parent == LocalPlayer:FindFirstChild("Backpack") then
						hum:EquipTool(prevEquipped)
					elseif tool.Parent == char then
						hum:UnequipTools()
					end
				end)
			end
		end

		if not ok then
			return nil, tostring(r1)
		end
		return r1, r2, r3
	end

	local function batchInvoke(endpoint, action, list, chunkSize)
		if not endpoint or not list or #list == 0 then return true end
		local step = chunkSize or AG_CONFIG.BatchSize
		local chunks = {}
		for i = 1, #list, step do
			local chunk = {}
			for j = i, math.min(i + step - 1, #list) do
				table.insert(chunk, list[j])
			end
			table.insert(chunks, chunk)
		end

		local allOk = true
		runParallel(#chunks, AG_CONFIG.MaxConcurrentBatches, function(idx)
			if not agAlive then return end
			local ok = pcall(function()
				endpoint:InvokeServer(action, chunks[idx])
			end)
			if not ok then allOk = false end
		end)
		return allOk
	end

	local function batchRemove(endpoint, objects)
		if not endpoint or not objects or #objects == 0 then return 0 end
		local valid = {}
		local seen = {}
		for _, obj in ipairs(objects) do
			if obj and not seen[obj] and obj.Parent ~= nil and not isProtectedWorldSystem(obj) and not isOwnRigPart(obj) and not isOwnCoreCharacterHelper(obj) then
				seen[obj] = true
				table.insert(valid, obj)
			end
		end
		if #valid == 0 then return 0 end
		batchInvoke(endpoint, "Remove", valid, AG_CONFIG.BatchSize)
		return #valid
	end

	local function batchLockParts(endpoint, partsList, locked)
		if not endpoint or #partsList == 0 then return false end
		local chunks = {}
		local step = AG_CONFIG.BatchSize
		for i = 1, #partsList, step do
			local chunk = {}
			for j = i, math.min(i + step - 1, #partsList) do
				local p = partsList[j]
				if p and p.Parent ~= nil then
					table.insert(chunk, p)
				end
			end
			if #chunk > 0 then
				table.insert(chunks, chunk)
			end
		end
		runParallel(#chunks, AG_CONFIG.MaxConcurrentBatches, function(idx)
			if not agAlive then return end
			pcall(function()
				endpoint:InvokeServer("SetLocked", chunks[idx], locked)
			end)
		end)
		return true
	end

	local function beginSelfRestoring()
		Runtime.selfRestoringDepth += 1
	end

	local function endSelfRestoring()
		task.delay(0.25, function()
			Runtime.selfRestoringDepth = math.max(0, Runtime.selfRestoringDepth - 1)
		end)
	end

	-- ========================================================================
	-- QUARANTINE & THREAT ATTRIBUTION
	-- ========================================================================
	local function quarantineInstanceLocally(inst)
		if not agState.localQuarantine or not inst or not inst.Parent then return end
		if isProtectedWorldSystem(inst) or isOwnRigPart(inst) or isOwnCoreCharacterHelper(inst) or Runtime.scriptManagedParts[inst] then return end

		if inst:IsA("Sound") then
			pcall(function()
				inst.Volume = 0
				inst.Playing = false
				inst:Stop()
			end)
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Fire") or inst:IsA("Smoke")
			or inst:IsA("Sparkles") or inst:IsA("Beam") or inst:IsA("Trail")
			or inst:IsA("Highlight") or inst:IsA("Light")
			or inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
			pcall(function()
				inst.Enabled = false
			end)
		elseif inst:IsA("Explosion") then
			pcall(function()
				inst.Visible = false
				inst.BlastPressure = 0
			end)
		elseif inst:IsA("Seat") or inst:IsA("VehicleSeat") then
			pcall(function()
				inst.Disabled = true
				inst.CanCollide = false
				inst.LocalTransparencyModifier = 1
			end)
		elseif inst:IsA("BasePart") then
			pcall(function()
				inst.CanCollide = false
				inst.LocalTransparencyModifier = 1
				inst.AssemblyLinearVelocity = Vector3.zero
				inst.AssemblyAngularVelocity = Vector3.zero
			end)
		elseif inst:IsA("DataModelMesh") then
			pcall(function()
				if math.max(inst.Scale.X, inst.Scale.Y, inst.Scale.Z) > 35 then
					inst.Scale = Vector3.new(1, 1, 1)
				end
			end)
		end
	end

	local function attributeThreat(pos, weight, reason)
		local nonWLHolders = {}
		local bestPlr, bestDist = nil, math.huge

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and not agState.whitelist[plr.UserId] then
				local hasF3X, equipped = playerHasF3X(plr)
				if hasF3X or agState.blacklist[plr.UserId] then
					table.insert(nonWLHolders, { plr = plr, equipped = equipped })
					if pos and plr.Character then
						local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local d = (hrp.Position - pos).Magnitude
							if d < bestDist then
								bestDist = d
								bestPlr = plr
							end
						end
					end
				end
			end
		end

		local suspect = nil
		if bestPlr and bestDist <= 90 then
			suspect = bestPlr
		elseif #nonWLHolders == 1 then
			suspect = nonWLHolders[1].plr
		end

		if suspect then
			local uid = suspect.UserId
			local newScore = (agState.threatScores[uid] or 0) + (weight or 1)
			agState.threatScores[uid] = newScore

			if agState.autoCounter and newScore >= AG_CONFIG.AutoCounterThreshold then
				local now = os.clock()
				local last = agState.lastCounterTime[uid] or 0
				if now - last >= AG_CONFIG.AutoCounterCooldown then
					agState.lastCounterTime[uid] = now
					task.spawn(function()
						withF3X(false, true, function(ep)
							Engine.stripPlayerF3X(ep, suspect)
							Engine.cagePlayer(ep, suspect)
							if suspect.Character and suspect.Character:FindFirstChild("HumanoidRootPart") then
								Engine.clearAroundPosition(ep, suspect.Character.HumanoidRootPart.Position, AG_CONFIG.ClearRadius)
							end
						end)
						Engine.logEvent(("AUTO-COUNTER [%s] -> %s (T:%d)"):format(tostring(reason or "GRIEF"), suspect.Name, newScore), "COUNTER")
						if agState.windowOpen and UI.refreshRadar then
							task.defer(UI.refreshRadar)
						end
					end)
				end
			end
		end
	end

	-- ========================================================================
	-- SNAPSHOT & HYBRID INTEGRITY ENGINE
	-- ========================================================================
	local function clearPartWatchers()
		for _, c in ipairs(Runtime.partWatchConns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(Runtime.partWatchConns)
	end

	local function attachPartWatcher(part, data, snap)
		local conn = part.Changed:Connect(function(prop)
			if not agAlive or not agState.liveGuard then return end
			if Runtime.selfRestoringDepth > 0 or isRigDeployGraceActive() then return end
			if not TRACKED_PART_PROPS[prop] then return end
			if getActiveSnapshot() ~= snap then return end

			if prop == "Locked" then
				if part.Locked == false and (data.Locked or agState.autoLockAfterRestore) then
					Runtime.pendingTampered[part] = true
				end
				return
			end

			if (prop == "Anchored" and part.Anchored ~= data.Anchored)
				or (prop == "CanCollide" and part.CanCollide ~= data.CanCollide)
				or (prop == "CFrame" and cframeDiffers(part.CFrame, data.CFrame))
				or (prop == "Size" and sizeDiffers(part.Size, data.Size))
				or (prop == "Color" and colorDiffers(part.Color, data.Color))
				or (prop == "Material" and part.Material ~= data.Material)
				or (prop == "Transparency" and math.abs(part.Transparency - data.Transparency) > 0.01)
				or (prop == "Reflectance" and math.abs(part.Reflectance - data.Reflectance) > 0.01) then
				Runtime.pendingTampered[part] = true
			end
		end)
		table.insert(Runtime.partWatchConns, conn)
	end

	local function syncPartWatchersToActiveSlot()
		clearPartWatchers()
		if not agState.liveGuard then return end
		local snap = getActiveSnapshot()
		if not snap then return end

		local count = 0
		for _, part in ipairs(snap.partList) do
			if count >= AG_CONFIG.MaxDirectPartWatchers then break end
			local data = snap.parts[part]
			if data and part.Parent ~= nil and data.Anchored then
				attachPartWatcher(part, data, snap)
				count += 1
			end
		end
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

	function Engine.takeSnapshot(slotIndex, silent)
		importExistingCoreRigParts()
		local idx = slotIndex or agState.activeSlot
		local parts = {}
		local partList = {}
		local effects = {}
		local meshes = {}
		local joints = {}
		local containers = {}
		local count = 0

		for _, desc in ipairs(workspace:GetDescendants()) do
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) then
				local isChar = isPlayerCharacterDescendant(desc)
				if not isChar then
					if desc:IsA("BasePart") then
						parts[desc] = capturePartData(desc)
						table.insert(partList, desc)
						count += 1
						local anc = desc.Parent
						while anc and anc ~= workspace and not containers[anc] do
							containers[anc] = { Parent = anc.Parent, Name = anc.Name }
							anc = anc.Parent
						end
					elseif desc:IsA("SpecialMesh") then
						effects[desc] = true
						meshes[desc] = {
							Parent = desc.Parent,
							MeshType = desc.MeshType,
							Scale = desc.Scale,
							Offset = desc.Offset,
							MeshId = desc.MeshId,
							TextureId = desc.TextureId,
						}
					elseif SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName] then
						effects[desc] = true
					elseif HOSTILE_JOINT_OR_MOVER_CLASSES[desc.ClassName] then
						joints[desc] = { Parent = desc.Parent }
					end
				end
			end
		end

		agState.snapshots[idx] = {
			parts = parts,
			partList = partList,
			effects = effects,
			meshes = meshes,
			joints = joints,
			containers = containers,
			count = count,
			timestamp = os.date("%H:%M:%S"),
		}
		agState.scanCursor = 1

		if idx == agState.activeSlot then
			syncPartWatchersToActiveSlot()
		end

		if not silent then
			Engine.logEvent("Snapshot Slot " .. idx .. " saved (" .. count .. " parts)", "INFO")
		end
		if UI.updateTelemetry then UI.updateTelemetry() end
		if UI.refreshSlotButtons then UI.refreshSlotButtons() end
		return count
	end

	function Engine.adoptNewPartsIntoSnapshot()
		importExistingCoreRigParts()
		local snap = getActiveSnapshot()
		if not snap then
			return Engine.takeSnapshot(agState.activeSlot), 0
		end

		local addedParts, addedEffects = 0, 0
		for _, desc in ipairs(workspace:GetDescendants()) do
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) then
				local isChar = isPlayerCharacterDescendant(desc)
				if not isChar then
					if desc:IsA("BasePart") and not snap.parts[desc] then
						local data = capturePartData(desc)
						snap.parts[desc] = data
						table.insert(snap.partList, desc)
						snap.count += 1
						addedParts += 1
						local anc = desc.Parent
						while anc and anc ~= workspace and not snap.containers[anc] do
							snap.containers[anc] = { Parent = anc.Parent, Name = anc.Name }
							anc = anc.Parent
						end
						if agState.liveGuard and #Runtime.partWatchConns < AG_CONFIG.MaxDirectPartWatchers and data.Anchored then
							attachPartWatcher(desc, data, snap)
						end
					elseif desc:IsA("SpecialMesh") and not snap.meshes[desc] then
						snap.effects[desc] = true
						snap.meshes[desc] = {
							Parent = desc.Parent,
							MeshType = desc.MeshType,
							Scale = desc.Scale,
							Offset = desc.Offset,
							MeshId = desc.MeshId,
							TextureId = desc.TextureId,
						}
						addedEffects += 1
					elseif (SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName]) and not snap.effects[desc] then
						snap.effects[desc] = true
						addedEffects += 1
					elseif HOSTILE_JOINT_OR_MOVER_CLASSES[desc.ClassName] and not snap.joints[desc] then
						snap.joints[desc] = { Parent = desc.Parent }
					end
				end
			end
		end
		snap.timestamp = os.date("%H:%M:%S")
		Engine.logEvent("Adopted +" .. addedParts .. " parts, +" .. addedEffects .. " fx into S" .. agState.activeSlot, "INFO")
		if UI.updateTelemetry then UI.updateTelemetry() end
		if UI.refreshSlotButtons then UI.refreshSlotButtons() end
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
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) then
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

	local function getFloodBurstAndPrune()
		local now = os.clock()
		local kept = {}
		for _, entry in ipairs(Runtime.recentForeignBuffer) do
			if now - entry.t <= AG_CONFIG.FloodRateWindow then
				table.insert(kept, entry)
			end
		end
		Runtime.recentForeignBuffer = kept
		return #kept, kept
	end

	local function isSuspiciousPart(part, strictMode)
		if not part or not part:IsA("BasePart") then return false, nil end
		if isProtectedWorldSystem(part) or Runtime.scriptManagedParts[part] or isOwnRigPart(part) or isOwnCoreCharacterHelper(part) then return false, nil end

		local isChar, charPlr = isPlayerCharacterDescendant(part)
		if isChar then
			if charPlr == LocalPlayer and agState.charShield and not isRigDeployGraceActive() then
				if not STANDARD_CHAR_PART_NAMES[part.Name] and not part:FindFirstAncestorOfClass("Accessory") and not part:FindFirstAncestorOfClass("Tool") then
					return true, "Attached to Self"
				end
			end
			return false, nil
		end

		local snap = getActiveSnapshot()
		if snap and snap.parts[part] then
			return false, nil
		end

		if strictMode and snap then
			return true, "Strict Lockdown"
		end

		local pos = part.Position
		if isBlacklistedPlayerNearby(pos, 50) then
			return true, "Blacklisted Spawn"
		end

		if part:IsA("Seat") or part:IsA("VehicleSeat") then
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (pos - hrp.Position).Magnitude <= AG_CONFIG.TrapCheckRadius and not isWhitelistedPlayerNearby(pos, 22) then
				return true, "Seat Trap"
			end
		end

		local sz = part.Size
		local maxAxis = math.max(sz.X, sz.Y, sz.Z)
		if maxAxis >= AG_CONFIG.GiantSizeThreshold then
			if not isWhitelistedPlayerNearby(pos, 65) then
				return true, "Oversized Block"
			end
		end

		if part.Material == Enum.Material.Neon and maxAxis >= AG_CONFIG.FlashNeonSizeThreshold then
			if not isWhitelistedPlayerNearby(pos, 25) then
				return true, "Neon Flashbang"
			end
		end

		if not part.Anchored then
			local rate = getFloodBurstAndPrune()
			if rate >= AG_CONFIG.FloodRateThreshold and not isWhitelistedPlayerNearby(pos, 32) then
				return true, "Unanchored Flood"
			end
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (pos - hrp.Position).Magnitude < 22 and part.AssemblyLinearVelocity.Magnitude > 28 then
				return true, "Fling Projectile"
			end
		else
			local rate = getFloodBurstAndPrune()
			if rate >= AG_CONFIG.FloodRateThreshold + 3 and not isWhitelistedPlayerNearby(pos, 32) then
				return true, "Anchored Spam Flood"
			end
		end

		if part.Transparency >= 0.8 and part.CanCollide and maxAxis >= 6 then
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (pos - hrp.Position).Magnitude < 28 and not isWhitelistedPlayerNearby(pos, 20) then
				return true, "Invisible Trap"
			end
		end

		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (pos - hrp.Position).Magnitude <= 11 and maxAxis >= 5 and not isWhitelistedPlayerNearby(pos, 22) then
			return true, "Close Encasement"
		end

		return false, nil
	end

	local function isSpamEffect(inst)
		if not inst or not inst.Parent then return false end
		if isProtectedWorldSystem(inst) or Runtime.scriptManagedParts[inst] or isOwnRigPart(inst) or isOwnCoreCharacterHelper(inst) then return false end

		local isChar, charPlr = isPlayerCharacterDescendant(inst)
		if isChar then
			if charPlr == LocalPlayer and agState.charShield and not isRigDeployGraceActive() then
				if SPAM_EFFECT_CLASSES[inst.ClassName] or HOSTILE_JOINT_OR_MOVER_CLASSES[inst.ClassName] then
					return true
				end
			end
			return false
		end

		local snap = getActiveSnapshot()
		if snap then
			if snap.effects[inst] or snap.joints[inst] then return false end
			if HOSTILE_JOINT_OR_MOVER_CLASSES[inst.ClassName] then
				local parentPart = inst.Parent
				if parentPart and parentPart:IsA("BasePart") and snap.parts[parentPart] then
					return true
				end
				return false
			end
			return SPAM_EFFECT_CLASSES[inst.ClassName] or EXTRA_DECOR_CLASSES[inst.ClassName] or false
		end

		return SPAM_EFFECT_CLASSES[inst.ClassName] or false
	end

	local function createFallbackBaseplate(endpoint, position)
		if not endpoint or not position then return false end
		beginSelfRestoring()
		local okRes, success = pcall(function()
			local cf = CFrame.new(position.X, position.Y - 8, position.Z)
			local ok, plate = pcall(function()
				return endpoint:InvokeServer("CreatePart", "Normal", cf, workspace)
			end)
			if ok and plate and typeof(plate) == "Instance" then
				Runtime.scriptManagedParts[plate] = true
				pcall(function()
					endpoint:InvokeServer("SyncAnchor", { { Part = plate, Anchored = true } })
					endpoint:InvokeServer("SyncResize", { { Part = plate, Size = Vector3.new(256, 8, 256), CFrame = cf } })
					endpoint:InvokeServer("SyncColor", { { Part = plate, Color = Color3.fromRGB(45, 45, 50) } })
					endpoint:InvokeServer("SyncMaterial", { { Part = plate, Material = Enum.Material.SmoothPlastic, Transparency = 0.15, Reflectance = 0 } })
					endpoint:InvokeServer("SetName", { plate }, "SentinelRescuePad")
				end)
				return true
			end
			return false
		end)
		endSelfRestoring()
		return okRes and success
	end

	function Engine.purgeSpam(endpoint, includeForeignParts)
		if not endpoint then return 0, "F3X not found" end
		importExistingCoreRigParts()
		local toRemove = {}
		local mode = getFilterMode()
		local strict = (mode == "Strict Lockdown") or includeForeignParts
		local checkParts = (mode ~= "Effects Only") or includeForeignParts

		for _, desc in ipairs(workspace:GetDescendants()) do
			if isSpamEffect(desc) then
				quarantineInstanceLocally(desc)
				table.insert(toRemove, desc)
			elseif checkParts and desc:IsA("BasePart") then
				local bad = isSuspiciousPart(desc, strict)
				if bad then
					quarantineInstanceLocally(desc)
					table.insert(toRemove, desc)
				end
			end
		end

		local removed = batchRemove(endpoint, toRemove)
		if removed > 0 then
			agState.threatsBlocked += removed
			Engine.logEvent("Purged " .. removed .. " grief instances", "BLOCK")
			if UI.updateTelemetry then UI.updateTelemetry() end
		end
		return removed, "Purged " .. removed .. " items"
	end

	function Engine.clearAroundPosition(endpoint, centerPos, radius)
		if not endpoint or not centerPos then return 0, "Missing target" end
		importExistingCoreRigParts()
		local snap = getActiveSnapshot()
		local toRemove = {}
		local r = radius or AG_CONFIG.ClearRadius

		for _, desc in ipairs(workspace:GetDescendants()) do
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) then
				local isChar = isPlayerCharacterDescendant(desc)
				if not isChar then
					local inSnap = snap and (snap.parts[desc] or snap.effects[desc] or snap.meshes[desc] or snap.joints[desc])
					if not inSnap then
						if desc:IsA("BasePart") then
							if (desc.Position - centerPos).Magnitude <= r then
								quarantineInstanceLocally(desc)
								table.insert(toRemove, desc)
							end
						elseif SPAM_EFFECT_CLASSES[desc.ClassName] or EXTRA_DECOR_CLASSES[desc.ClassName] then
							local p = desc:FindFirstAncestorWhichIsA("BasePart")
							if p and (p.Position - centerPos).Magnitude <= r then
								quarantineInstanceLocally(desc)
								table.insert(toRemove, desc)
							end
						end
					end
				end
			end
		end

		local removed = batchRemove(endpoint, toRemove)
		if removed > 0 then
			agState.threatsBlocked += removed
			Engine.logEvent("Area sweep cleared " .. removed .. " foreign items", "BLOCK")
			if UI.updateTelemetry then UI.updateTelemetry() end
		end
		return removed, "Cleared " .. removed .. " nearby items"
	end

	function Engine.restoreMap(endpoint)
		if not endpoint then return "F3X not found" end
		local snap = getActiveSnapshot()
		if not snap then return "No snapshot in Slot " .. agState.activeSlot end
		if Runtime.restoreInFlight then return "Restore already running" end

		Runtime.restoreInFlight = true
		agState.isBusy = true
		beginSelfRestoring()

		local okRun, summary = pcall(function()
			local diff = computeMapDiff(snap)
			if not diff then return "Snapshot missing" end

			local lockUndoList = {}
			if agState.autoLockAfterRestore then
				for part, data in pairs(snap.parts) do
					if part and part.Parent ~= nil and not part.Locked then
						table.insert(lockUndoList, part)
						data.Locked = true
					end
				end
			end

			-- 1. Recover missing containers, meshes, joints, and deleted parts via UndoRemove first
			local undoTargets = {}
			local missingParts = {}
			for anc in pairs(snap.containers) do
				if anc and anc.Parent == nil then
					table.insert(undoTargets, anc)
				end
			end
			for _, part in ipairs(diff.deleted) do
				if part then
					table.insert(undoTargets, part)
					table.insert(missingParts, part)
				end
			end
			for mesh in pairs(snap.meshes) do
				if mesh and mesh.Parent == nil then
					table.insert(undoTargets, mesh)
				end
			end
			for joint in pairs(snap.joints) do
				if joint and joint.Parent == nil then
					table.insert(undoTargets, joint)
				end
			end

			if #undoTargets > 0 then
				batchInvoke(endpoint, "UndoRemove", undoTargets, AG_CONFIG.BatchSize)
			end

			-- 2. Rebuild any parts that failed UndoRemove via CreatePart
			local rebuiltMap = {}
			local rebuildQueue = {}
			for _, oldPart in ipairs(missingParts) do
				if not oldPart or oldPart.Parent == nil or not oldPart:IsDescendantOf(workspace) then
					local data = snap.parts[oldPart]
					if data then
						table.insert(rebuildQueue, { oldPart = oldPart, data = data })
					end
				end
			end

			local rebuiltCount = 0
			if #rebuildQueue > 0 then
				local newlyCreated = {}
				runParallel(#rebuildQueue, AG_CONFIG.MaxConcurrentInvokes, function(idx)
					if not agAlive then return end
					local item = rebuildQueue[idx]
					local d = item.data
					local parentTarget = (d.Parent and d.Parent:IsDescendantOf(game)) and d.Parent or workspace
					local ok, newPart = pcall(function()
						return endpoint:InvokeServer("CreatePart", d.ShapeType or "Normal", d.CFrame, parentTarget)
					end)
					if ok and typeof(newPart) == "Instance" and newPart:IsA("BasePart") then
						rebuiltMap[item.oldPart] = newPart
						newlyCreated[idx] = { newPart = newPart, data = d }
						rebuiltCount += 1
					end
				end)

				local anchorBatch, resizeBatch, colorBatch, matBatch, colBatch, lockBatch, renameGroups = {}, {}, {}, {}, {}, {}, {}
				for _, entry in pairs(newlyCreated) do
					local np, d = entry.newPart, entry.data
					table.insert(anchorBatch, { Part = np, Anchored = d.Anchored })
					table.insert(resizeBatch, { Part = np, Size = d.Size, CFrame = d.CFrame })
					table.insert(colorBatch, { Part = np, Color = d.Color, UnionColoring = true })
					table.insert(matBatch, { Part = np, Material = d.Material, Transparency = d.Transparency, Reflectance = d.Reflectance })
					table.insert(colBatch, { Part = np, CanCollide = d.CanCollide })
					if d.Locked or agState.autoLockAfterRestore then
						table.insert(lockBatch, np)
					end
					renameGroups[d.Name] = renameGroups[d.Name] or {}
					table.insert(renameGroups[d.Name], np)
				end

				batchInvoke(endpoint, "SyncAnchor", anchorBatch)
				runParallel(5, 5, function(stepIdx)
					if stepIdx == 1 then
						batchInvoke(endpoint, "SyncResize", resizeBatch)
					elseif stepIdx == 2 then
						batchInvoke(endpoint, "SyncColor", colorBatch)
					elseif stepIdx == 3 then
						batchInvoke(endpoint, "SyncMaterial", matBatch)
					elseif stepIdx == 4 then
						batchInvoke(endpoint, "SyncCollision", colBatch)
					elseif stepIdx == 5 then
						if #lockBatch > 0 then
							batchLockParts(endpoint, lockBatch, true)
						end
					end
				end)
				for nameStr, groupParts in pairs(renameGroups) do
					pcall(function()
						endpoint:InvokeServer("SetName", groupParts, nameStr)
					end)
				end

				-- Re-map snapshot entries to rebuilt parts
				local updated = false
				for oldPart, newPart in pairs(rebuiltMap) do
					local d = snap.parts[oldPart]
					if d then
						d.Locked = d.Locked or agState.autoLockAfterRestore
						snap.parts[oldPart] = nil
						snap.parts[newPart] = d
						updated = true
						if agState.liveGuard and #Runtime.partWatchConns < AG_CONFIG.MaxDirectPartWatchers and d.Anchored then
							attachPartWatcher(newPart, d, snap)
						end
					end
				end
				if updated then
					rebuildPartList(snap)
				end
			end

			-- 3. Sync remaining tampered parts (SyncAnchor first, then Sync* in parallel)
			if #diff.reanchored > 0 then
				batchInvoke(endpoint, "SyncAnchor", diff.reanchored)
			end
			runParallel(5, 5, function(stepIdx)
				if stepIdx == 1 and #diff.moved > 0 then
					batchInvoke(endpoint, "SyncMove", diff.moved)
				elseif stepIdx == 2 and #diff.resized > 0 then
					batchInvoke(endpoint, "SyncResize", diff.resized)
				elseif stepIdx == 3 and #diff.recolored > 0 then
					for _, item in ipairs(diff.recolored) do
						item.UnionColoring = true
					end
					batchInvoke(endpoint, "SyncColor", diff.recolored)
				elseif stepIdx == 4 and #diff.rematerialed > 0 then
					batchInvoke(endpoint, "SyncMaterial", diff.rematerialed)
				elseif stepIdx == 5 and #diff.recollided > 0 then
					batchInvoke(endpoint, "SyncCollision", diff.recollided)
				end
			end)

			if #lockUndoList > 0 then
				batchLockParts(endpoint, lockUndoList, true)
			end

			-- 4. Remove foreign spam / grief objects
			local removeQueue = {}
			local mode = getFilterMode()
			for _, fx in ipairs(diff.foreignEffects) do
				table.insert(removeQueue, fx)
			end
			if mode == "Strict Lockdown" then
				for _, fp in ipairs(diff.foreignParts) do
					table.insert(removeQueue, fp)
				end
			elseif mode == "Smart Threats" then
				for _, fp in ipairs(diff.foreignParts) do
					if isSuspiciousPart(fp, false) then
						table.insert(removeQueue, fp)
					end
				end
			end
			local removed = batchRemove(endpoint, removeQueue)

			local fixed = #diff.moved + #diff.resized + #diff.recolored + #diff.rematerialed + #diff.reanchored + #diff.recollided + rebuiltCount
			if fixed > 0 then agState.restoresPerformed += fixed end
			if removed > 0 then agState.threatsBlocked += removed end

			return ("Restored %d props (%d rebuilt) | Purged %d"):format(fixed, rebuiltCount, removed)
		end)

		endSelfRestoring()
		agState.isBusy = false
		Runtime.restoreInFlight = false

		local msg = okRun and summary or ("Restore error: " .. tostring(summary))
		Engine.logEvent(msg, okRun and "RESTORE" or "WARN")
		if UI.updateTelemetry then UI.updateTelemetry() end
		return msg
	end

	function Engine.stripPlayerF3X(endpoint, targetPlr)
		if not endpoint or not targetPlr or targetPlr == LocalPlayer then return 0, "Invalid target" end
		local targets = {}
		local function collectTools(container)
			if not container then return end
			for _, item in ipairs(container:GetChildren()) do
				if item:FindFirstChild("SyncAPI") or item:FindFirstChild("SyncApi") then
					table.insert(targets, item)
				end
			end
		end
		collectTools(targetPlr.Character)
		collectTools(targetPlr:FindFirstChild("Backpack"))
		if #targets == 0 then
			return 0, targetPlr.Name .. " has no F3X"
		end
		local removed = batchRemove(endpoint, targets)
		if removed > 0 then
			agState.threatsBlocked += removed
			Engine.logEvent("Stripped F3X from " .. targetPlr.Name, "COUNTER")
			if UI.updateTelemetry then UI.updateTelemetry() end
			if agState.windowOpen and UI.refreshRadar then task.defer(UI.refreshRadar) end
		end
		return removed, "Stripped F3X from " .. targetPlr.Name
	end

	function Engine.cagePlayer(endpoint, targetPlr)
		if not endpoint or not targetPlr or targetPlr == LocalPlayer then return false, "Invalid target" end
		local char = targetPlr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return false, targetPlr.Name .. " has no character" end

		Engine.uncagePlayer(endpoint, targetPlr)
		beginSelfRestoring()

		local center = hrp.Position
		local wallSpecs = {
			{ cf = CFrame.new(center + Vector3.new(0, -4.5, 0)), size = Vector3.new(10, 1, 10) },
			{ cf = CFrame.new(center + Vector3.new(0, 5.5, 0)), size = Vector3.new(10, 1, 10) },
			{ cf = CFrame.new(center + Vector3.new(4.5, 0.5, 0)), size = Vector3.new(1, 9, 10) },
			{ cf = CFrame.new(center + Vector3.new(-4.5, 0.5, 0)), size = Vector3.new(1, 9, 10) },
			{ cf = CFrame.new(center + Vector3.new(0, 0.5, 4.5)), size = Vector3.new(8, 9, 1) },
			{ cf = CFrame.new(center + Vector3.new(0, 0.5, -4.5)), size = Vector3.new(8, 9, 1) },
		}

		local created = {}
		runParallel(#wallSpecs, 6, function(idx)
			local spec = wallSpecs[idx]
			local ok, part = pcall(function()
				return endpoint:InvokeServer("CreatePart", "Normal", spec.cf, workspace)
			end)
			if ok and typeof(part) == "Instance" and part:IsA("BasePart") then
				Runtime.scriptManagedParts[part] = true
				created[idx] = { part = part, spec = spec }
			end
		end)

		local anchorBatch, resizeBatch, colorBatch, matBatch, colBatch, lockBatch, renameList = {}, {}, {}, {}, {}, {}, {}
		for _, entry in pairs(created) do
			local p, s = entry.part, entry.spec
			table.insert(anchorBatch, { Part = p, Anchored = true })
			table.insert(resizeBatch, { Part = p, Size = s.size, CFrame = s.cf })
			table.insert(colorBatch, { Part = p, Color = Color3.fromRGB(204, 36, 36), UnionColoring = true })
			table.insert(matBatch, { Part = p, Material = Enum.Material.ForceField, Transparency = 0.35, Reflectance = 0 })
			table.insert(colBatch, { Part = p, CanCollide = true })
			table.insert(lockBatch, p)
			table.insert(renameList, p)
		end

		if #renameList > 0 then
			Runtime.cagedPartsByUserId[targetPlr.UserId] = renameList
			batchInvoke(endpoint, "SyncAnchor", anchorBatch)
			runParallel(5, 5, function(stepIdx)
				if stepIdx == 1 then batchInvoke(endpoint, "SyncResize", resizeBatch)
				elseif stepIdx == 2 then batchInvoke(endpoint, "SyncColor", colorBatch)
				elseif stepIdx == 3 then batchInvoke(endpoint, "SyncMaterial", matBatch)
				elseif stepIdx == 4 then batchInvoke(endpoint, "SyncCollision", colBatch)
				elseif stepIdx == 5 then batchLockParts(endpoint, lockBatch, true) end
			end)
			pcall(function()
				endpoint:InvokeServer("SetName", renameList, "SentinelCage_" .. targetPlr.Name)
			end)
		end

		endSelfRestoring()
		Engine.logEvent("Caged " .. targetPlr.Name .. " (" .. #renameList .. " walls)", "COUNTER")
		return #renameList > 0, "Caged " .. targetPlr.Name
	end

	function Engine.uncagePlayer(endpoint, targetPlr)
		if not targetPlr then return 0 end
		local list = Runtime.cagedPartsByUserId[targetPlr.UserId]
		if not list or #list == 0 then return 0 end
		Runtime.cagedPartsByUserId[targetPlr.UserId] = nil
		local removed = endpoint and batchRemove(endpoint, list) or 0
		return removed
	end

	function Engine.nukePlayerBuilds(endpoint, targetPlr)
		if not endpoint or not targetPlr then return 0, "Invalid target" end
		local char = targetPlr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return 0, targetPlr.Name .. " has no character" end
		return Engine.clearAroundPosition(endpoint, hrp.Position, 55)
	end

	-- ========================================================================
	-- CHARACTER SHIELD (INSTANT UNDO + LOCK + NO-SIT + SIZE GUARD)
	-- ========================================================================
	local function setupCharacterShield(char)
		for _, c in ipairs(Runtime.charWatchConns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(Runtime.charWatchConns)
		table.clear(Runtime.charPartBaselineSizes)

		if not char then return end
		registerCharacter(LocalPlayer, char)
		agState.f3xRequestedThisLife = false

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") and STANDARD_CHAR_PART_NAMES[desc.Name] then
				Runtime.charPartBaselineSizes[desc] = desc.Size
			end
		end

		if agState.autoLockSelf then
			task.delay(0.35, function()
				if not agAlive or LocalPlayer.Character ~= char then return end
				withF3X(false, false, function(ep)
					local parts = {}
					for _, d in ipairs(char:GetDescendants()) do
						if d:IsA("BasePart") then
							table.insert(parts, d)
						end
					end
					if #parts > 0 then
						batchLockParts(ep, parts, true)
					end
				end)
			end)
		end

		table.insert(Runtime.charWatchConns, char.DescendantRemoving:Connect(function(desc)
			if not agAlive or not agState.charShield then return end
			if isRigDeployGraceActive() or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end

			local isCritical = desc:IsA("Humanoid")
				or (desc:IsA("BasePart") and CRITICAL_CHAR_PART_NAMES[desc.Name])
				or (desc:IsA("JointInstance") and CRITICAL_JOINT_NAMES[desc.Name])

			if isCritical then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health <= 0 then return end
				Runtime.pendingCharUndo[desc] = true
				agState.threatsBlocked += 1
				Engine.logEvent("Blocked removal of self " .. desc.Name, "BLOCK")
				attributeThreat(char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position, 6, "CHAR_DELETE")
				task.spawn(function()
					withF3X(false, false, function(ep)
						pcall(function()
							ep:InvokeServer("UndoRemove", { desc })
						end)
						if agState.autoLockSelf and desc:IsA("BasePart") then
							batchLockParts(ep, { desc }, true)
						end
					end)
				end)
			end
		end))

		table.insert(Runtime.charWatchConns, char.DescendantAdded:Connect(function(desc)
			if not agAlive or not agState.charShield then return end
			if isRigDeployGraceActive() or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end

			if desc:IsA("BasePart") and not STANDARD_CHAR_PART_NAMES[desc.Name] and not desc:FindFirstAncestorOfClass("Accessory") and not desc:FindFirstAncestorOfClass("Tool") then
				quarantineInstanceLocally(desc)
				Runtime.pendingRemove[desc] = true
				agState.threatsBlocked += 1
				attributeThreat(desc.Position, 4, "CHAR_ATTACH")
			elseif SPAM_EFFECT_CLASSES[desc.ClassName] or HOSTILE_JOINT_OR_MOVER_CLASSES[desc.ClassName] then
				if desc:IsA("JointInstance") and CRITICAL_JOINT_NAMES[desc.Name] then return end
				if desc:IsA("Sound") and desc.Parent and (desc.Parent.Name == "Head" or desc.Parent.Name == "HumanoidRootPart") then
					return
				end
				quarantineInstanceLocally(desc)
				Runtime.pendingRemove[desc] = true
			elseif desc:IsA("BasePart") and STANDARD_CHAR_PART_NAMES[desc.Name] then
				Runtime.charPartBaselineSizes[desc] = desc.Size
			end
		end))

		local hum = char:WaitForChild("Humanoid", 4)
		if hum then
			table.insert(Runtime.charWatchConns, hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
				if not agAlive or not agState.charShield then return end
				local seat = hum.SeatPart
				if seat then
					local snap = getActiveSnapshot()
					if not snap or not snap.parts[seat] then
						quarantineInstanceLocally(seat)
						hum.Sit = false
						hum:ChangeState(Enum.HumanoidStateType.GettingUp)
						Runtime.pendingRemove[seat] = true
						agState.threatsBlocked += 1
						attributeThreat(seat.Position, 5, "SEAT_TRAP")
						Engine.logEvent("Ejected from foreign seat trap!", "BLOCK")
					end
				end
			end))
		end

		local hrp = char:WaitForChild("HumanoidRootPart", 4)
		if hrp then
			table.insert(Runtime.charWatchConns, hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
				if not agAlive or not agState.charShield or isRigDeployGraceActive() then return end
				if hrp.Anchored and hum and hum.MoveDirection.Magnitude > 0.05 then
					withF3X(false, false, function(ep)
						pcall(function()
							ep:InvokeServer("SyncAnchor", { { Part = hrp, Anchored = false } })
						end)
					end)
					Engine.logEvent("Unanchored self HRP from freeze attempt", "BLOCK")
				end
			end))
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(Runtime.charWatchConns, desc:GetPropertyChangedSignal("Locked"):Connect(function()
					if not agAlive or not agState.charShield or not agState.autoLockSelf then return end
					if desc.Locked == false then
						withF3X(false, false, function(ep)
							batchLockParts(ep, { desc }, true)
						end)
					end
				end))
				table.insert(Runtime.charWatchConns, desc:GetPropertyChangedSignal("Size"):Connect(function()
					if not agAlive or not agState.charShield or isRigDeployGraceActive() then return end
					local baseSize = Runtime.charPartBaselineSizes[desc]
					if baseSize and math.max(desc.Size.X, desc.Size.Y, desc.Size.Z) > 9 then
						withF3X(false, false, function(ep)
							pcall(function()
								ep:InvokeServer("SyncResize", { { Part = desc, Size = baseSize, CFrame = desc.CFrame } })
							end)
						end)
						Engine.logEvent("Reverted giant limb grief on " .. desc.Name, "BLOCK")
					end
				end))
			end
		end
	end

	-- ========================================================================
	-- LIVE GUARD WORKER LOOP (BUFFERED PURGE + TAMPER SLICE + FLING + VOID)
	-- ========================================================================
	local function setLiveGuard(enabled)
		agState.liveGuard = enabled
		if enabled then
			if not getActiveSnapshot() then
				Engine.takeSnapshot(agState.activeSlot)
			else
				syncPartWatchersToActiveSlot()
			end
			Engine.logEvent("LIVE GUARD ENGAGED (Slot " .. agState.activeSlot .. " | " .. getFilterMode() .. ")", "INFO")
		else
			clearPartWatchers()
			table.clear(Runtime.pendingRemove)
			table.clear(Runtime.pendingDeleted)
			table.clear(Runtime.pendingTampered)
			table.clear(Runtime.pendingCharUndo)
			Engine.logEvent("Live Guard disengaged", "WARN")
		end
		if UI.updateTelemetry then UI.updateTelemetry() end
		if UI.refreshShieldToggles then UI.refreshShieldToggles() end
	end

	trackConn(workspace.DescendantAdded:Connect(function(desc)
		if not agAlive or not agState.liveGuard then return end
		if Runtime.selfRestoringDepth > 0 or isRigDeployGraceActive() then return end
		if isProtectedWorldSystem(desc) or Runtime.scriptManagedParts[desc] or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end

		local isChar = isPlayerCharacterDescendant(desc)
		if isChar then return end

		local snap = getActiveSnapshot()
		if snap and (snap.parts[desc] or snap.effects[desc] or snap.meshes[desc] or snap.joints[desc] or snap.containers[desc]) then
			return
		end

		if desc:IsA("BasePart") then
			table.insert(Runtime.recentForeignBuffer, { t = os.clock(), inst = desc })
			local burstCount, burstEntries = getFloodBurstAndPrune()
			if burstCount >= AG_CONFIG.FloodRateThreshold then
				for _, entry in ipairs(burstEntries) do
					if entry.inst and entry.inst.Parent ~= nil and not isOwnRigPart(entry.inst) then
						quarantineInstanceLocally(entry.inst)
						Runtime.pendingRemove[entry.inst] = true
					end
				end
			end

			local mode = getFilterMode()
			if mode == "Strict Lockdown" then
				quarantineInstanceLocally(desc)
				Runtime.pendingRemove[desc] = true
				attributeThreat(desc.Position, 1, "STRICT_SPAWN")
			elseif mode == "Smart Threats" then
				local bad, reason = isSuspiciousPart(desc, false)
				if bad then
					quarantineInstanceLocally(desc)
					Runtime.pendingRemove[desc] = true
					attributeThreat(desc.Position, 2, reason)
				end
			end
		elseif isSpamEffect(desc) then
			quarantineInstanceLocally(desc)
			Runtime.pendingRemove[desc] = true
			local anchorPart = desc:FindFirstAncestorWhichIsA("BasePart")
			attributeThreat(anchorPart and anchorPart.Position, 1, "FX_SPAM")
		end
	end))

	trackConn(workspace.DescendantRemoving:Connect(function(desc)
		if not agAlive or not agState.liveGuard then return end
		if Runtime.selfRestoringDepth > 0 or isRigDeployGraceActive() then return end
		if isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end

		local snap = getActiveSnapshot()
		if not snap then return end
		if snap.parts[desc] or snap.meshes[desc] or snap.joints[desc] or snap.containers[desc] then
			Runtime.pendingDeleted[desc] = true
			if desc:IsA("BasePart") and snap.parts[desc] then
				attributeThreat(snap.parts[desc].CFrame.Position, 3, "MAP_DELETE")
			end
		end
	end))

	-- Live Guard worker coroutine
	task.spawn(function()
		while agAlive do
			task.wait(AG_CONFIG.WorkerInterval)
			if agState.liveGuard and not Runtime.restoreInFlight then
				local endpoint = getF3XEndpoint(false)

				if agState.autoClean and next(Runtime.pendingRemove) ~= nil then
					local removeList = {}
					for inst in pairs(Runtime.pendingRemove) do
						Runtime.pendingRemove[inst] = nil
						if inst and inst.Parent ~= nil and not isProtectedWorldSystem(inst) and not isOwnRigPart(inst) and not isOwnCoreCharacterHelper(inst) then
							table.insert(removeList, inst)
						end
					end
					if #removeList > 0 then
						if endpoint then
							local removed = batchRemove(endpoint, removeList)
							agState.threatsBlocked += removed
							if removed > 0 and UI.updateTelemetry then UI.updateTelemetry() end
						else
							for _, inst in ipairs(removeList) do
								quarantineInstanceLocally(inst)
							end
						end
					end
				else
					table.clear(Runtime.pendingRemove)
				end

				if endpoint and (next(Runtime.pendingDeleted) ~= nil or next(Runtime.pendingTampered) ~= nil) then
					local snap = getActiveSnapshot()
					if snap then
						beginSelfRestoring()
						local deletedList = {}
						for inst in pairs(Runtime.pendingDeleted) do
							Runtime.pendingDeleted[inst] = nil
							if inst and inst.Parent == nil then
								table.insert(deletedList, inst)
							end
						end

						if #deletedList > 0 then
							batchInvoke(endpoint, "UndoRemove", deletedList, AG_CONFIG.BatchSize)
							local stillMissing = {}
							for _, inst in ipairs(deletedList) do
								if inst:IsA("BasePart") and snap.parts[inst] and (inst.Parent == nil or not inst:IsDescendantOf(workspace)) then
									table.insert(stillMissing, inst)
								end
							end
							if #stillMissing > 0 then
								task.spawn(function()
									Engine.restoreMap(endpoint)
								end)
							else
								agState.restoresPerformed += #deletedList
							end
						end

						local reanchorList, moveList, resizeList, colorList, matList, colList, lockList = {}, {}, {}, {}, {}, {}, {}
						local fixedCount = 0
						for part in pairs(Runtime.pendingTampered) do
							Runtime.pendingTampered[part] = nil
							local d = snap.parts[part]
							if d and part and part.Parent ~= nil and part:IsDescendantOf(workspace) then
								local hits = (Runtime.tamperHits[part] or 0) + 1
								Runtime.tamperHits[part] = hits
								if part.Anchored ~= d.Anchored then
									table.insert(reanchorList, { Part = part, Anchored = d.Anchored })
								end
								if cframeDiffers(part.CFrame, d.CFrame) then
									table.insert(moveList, { Part = part, CFrame = d.CFrame })
								end
								if sizeDiffers(part.Size, d.Size) then
									table.insert(resizeList, { Part = part, Size = d.Size, CFrame = d.CFrame })
								end
								if colorDiffers(part.Color, d.Color) then
									table.insert(colorList, { Part = part, Color = d.Color, UnionColoring = true })
								end
								if part.Material ~= d.Material or math.abs(part.Transparency - d.Transparency) > 0.01 or math.abs(part.Reflectance - d.Reflectance) > 0.01 then
									table.insert(matList, { Part = part, Material = d.Material, Transparency = d.Transparency, Reflectance = d.Reflectance })
								end
								if part.CanCollide ~= d.CanCollide then
									table.insert(colList, { Part = part, CanCollide = d.CanCollide })
								end
								if (d.Locked or agState.autoLockAfterRestore) and not part.Locked then
									table.insert(lockList, part)
									d.Locked = true
								end
								fixedCount += 1
							end
						end

						if fixedCount > 0 then
							if #reanchorList > 0 then batchInvoke(endpoint, "SyncAnchor", reanchorList) end
							runParallel(5, 5, function(stepIdx)
								if stepIdx == 1 and #moveList > 0 then batchInvoke(endpoint, "SyncMove", moveList)
								elseif stepIdx == 2 and #resizeList > 0 then batchInvoke(endpoint, "SyncResize", resizeList)
								elseif stepIdx == 3 and #colorList > 0 then batchInvoke(endpoint, "SyncColor", colorList)
								elseif stepIdx == 4 and #matList > 0 then batchInvoke(endpoint, "SyncMaterial", matList)
								elseif stepIdx == 5 and #colList > 0 then batchInvoke(endpoint, "SyncCollision", colList) end
							end)
							if #lockList > 0 then
								batchLockParts(endpoint, lockList, true)
							end
							agState.restoresPerformed += fixedCount
							if UI.updateTelemetry then UI.updateTelemetry() end
						end
						endSelfRestoring()
					end
				end
			end
		end
	end)

	-- Tamper cyclic sweep (catches any property drifts on unlocked/watched parts)
	task.spawn(function()
		while agAlive do
			task.wait(AG_CONFIG.TamperInterval)
			if agState.liveGuard and not Runtime.restoreInFlight and Runtime.selfRestoringDepth == 0 and not isRigDeployGraceActive() then
				local snap = getActiveSnapshot()
				if snap and #snap.partList > 0 then
					local total = #snap.partList
					local startIdx = agState.scanCursor
					local endIdx = math.min(total, startIdx + AG_CONFIG.TamperSliceSize - 1)
					for i = startIdx, endIdx do
						local part = snap.partList[i]
						local data = part and snap.parts[part]
						if part and data then
							if part.Parent == nil or not part:IsDescendantOf(workspace) then
								Runtime.pendingDeleted[part] = true
							else
								if cframeDiffers(part.CFrame, data.CFrame)
									or sizeDiffers(part.Size, data.Size)
									or part.Anchored ~= data.Anchored
									or part.CanCollide ~= data.CanCollide
									or colorDiffers(part.Color, data.Color)
									or part.Material ~= data.Material
									or math.abs(part.Transparency - data.Transparency) > 0.01
									or (not part.Locked and (data.Locked or agState.autoLockAfterRestore)) then
									Runtime.pendingTampered[part] = true
								end
							end
						end
					end
					agState.scanCursor = (endIdx >= total) and 1 or (endIdx + 1)
				end
			end
		end
	end)

	-- Anti-Fling & Anti-Void Heartbeat
	local flingOverlapParams = OverlapParams.new()
	flingOverlapParams.FilterType = Enum.RaycastFilterType.Exclude
	trackConn(RunService.Heartbeat:Connect(function()
		if not agAlive or not agState.liveGuard then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		if agState.antiVoid then
			if hrp.Position.Y > AG_CONFIG.VoidThresholdY + 25 and hum.FloorMaterial ~= Enum.Material.Air then
				agState.lastSafeCFrame = hrp.CFrame
			elseif hrp.Position.Y < AG_CONFIG.VoidThresholdY then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				if agState.lastSafeCFrame then
					hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 4, 0)
					Engine.logEvent("Anti-Void rescued character to safe ground", "BLOCK")
				else
					local rescuePos = Vector3.new(hrp.Position.X, 15, hrp.Position.Z)
					hrp.CFrame = CFrame.new(rescuePos)
					withF3X(false, false, function(ep)
						createFallbackBaseplate(ep, rescuePos)
					end)
					Engine.logEvent("Anti-Void deployed rescue platform", "BLOCK")
				end
			end
		end

		if agState.antiFling then
			local highSpeedSelf = isCoreHighSpeedAction() or isRigDeployGraceActive()
			if not highSpeedSelf then
				local vel = hrp.AssemblyLinearVelocity
				local ang = hrp.AssemblyAngularVelocity
				if vel.Magnitude > AG_CONFIG.FlingVelocityThreshold or ang.Magnitude > 55 then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					if agState.lastSafeCFrame and vel.Magnitude > 260 then
						hrp.CFrame = agState.lastSafeCFrame
					end
					agState.threatsBlocked += 1
				end
			end

			local now = os.clock()
			if now - Runtime.lastFlingSweep >= 0.12 then
				Runtime.lastFlingSweep = now
				flingOverlapParams.FilterDescendantsInstances = { char }
				local nearby = workspace:GetPartBoundsInRadius(hrp.Position, 24, flingOverlapParams)
				for _, p in ipairs(nearby) do
					if p:IsA("BasePart") and not p.Anchored and not isOwnRigPart(p) and not isOwnCoreCharacterHelper(p) then
						local isChar, pOwner = isPlayerCharacterDescendant(p)
						if isChar and pOwner ~= LocalPlayer and not agState.whitelist[pOwner.UserId] then
							if p.AssemblyLinearVelocity.Magnitude > 85 or p.AssemblyAngularVelocity.Magnitude > 35 then
								p.AssemblyLinearVelocity = Vector3.zero
								p.AssemblyAngularVelocity = Vector3.zero
								p.CanCollide = false
								attributeThreat(p.Position, 2, "FLING_BODY")
							end
						elseif not isChar then
							local snap = getActiveSnapshot()
							if (not snap or not snap.parts[p]) and (p.AssemblyLinearVelocity.Magnitude > 65 or p.AssemblyAngularVelocity.Magnitude > 30) then
								quarantineInstanceLocally(p)
								Runtime.pendingRemove[p] = true
							end
						end
					end
				end
			end
		end
	end))

	-- Player & Character registration
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			registerCharacter(plr, plr.Character)
		end
		trackConn(plr.CharacterAdded:Connect(function(c)
			if not agAlive then return end
			registerCharacter(plr, c)
			if plr == LocalPlayer then
				setupCharacterShield(c)
			end
		end))
	end
	if LocalPlayer.Character then
		setupCharacterShield(LocalPlayer.Character)
	end
	trackConn(Players.PlayerAdded:Connect(function(plr)
		if not agAlive then return end
		trackConn(plr.CharacterAdded:Connect(function(c)
			if agAlive then registerCharacter(plr, c) end
		end))
		if agState.windowOpen and UI.refreshRadar then
			task.defer(UI.refreshRadar)
		end
	end))
	trackConn(Players.PlayerRemoving:Connect(function(plr)
		if not agAlive then return end
		registerCharacter(plr, nil)
		Runtime.cagedPartsByUserId[plr.UserId] = nil
		if agState.windowOpen and UI.refreshRadar then
			task.defer(UI.refreshRadar)
		end
	end))

	-- ========================================================================
	-- SMILEOS 2.0 WINDOW & CHROME LAYOUT (MATCHING LOADER.LUA)
	-- ========================================================================
	local AG_FULL_W = 356
	local AG_FULL_H = 412
	local AG_COLLAPSED_H = 30

	local function computeAGScale()
		local vp = getScreenSize(ScreenGui)
		local isCompact = UserInputService.TouchEnabled or vp.X < 760 or vp.Y < 540
		local rawScale = math.min((vp.X - 24) / (AG_FULL_W + 40), (vp.Y - 24) / AG_FULL_H)
		if isCompact then
			return math.clamp(rawScale, 0.48, 0.80)
		end
		return math.clamp(rawScale, 0.65, 1.0)
	end

	local AGWindow = Instance.new("Frame")
	AGWindow.Name = "AGWindow"
	AGWindow.Size = UDim2.fromOffset(AG_FULL_W, AG_FULL_H)
	AGWindow.Position = UDim2.fromOffset(600, 60)
	AGWindow.BackgroundColor3 = SMILE.WinFace
	AGWindow.BorderSizePixel = 0
	AGWindow.ClipsDescendants = true
	AGWindow.Visible = false
	AGWindow.ZIndex = 40
	AGWindow.Parent = ScreenGui
	addOutline(AGWindow, SMILE.BorderOuter, 1)
	local agWindowBevel = createBevel(AGWindow, false, 2)

	local AGScale = Instance.new("UIScale")
	AGScale.Scale = computeAGScale()
	AGScale.Parent = AGWindow

	trackConn(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not agAlive then return end
		AGScale.Scale = computeAGScale()
		if AGWindow.Visible then
			clampWindowToScreen(AGWindow, ScreenGui)
		end
	end))

	-- 26px Crimson TitleBar
	local AGTitleBar = Instance.new("Frame")
	AGTitleBar.Name = "AGTitleBar"
	AGTitleBar.Size = UDim2.new(1, -6, 0, 26)
	AGTitleBar.Position = UDim2.fromOffset(3, 3)
	AGTitleBar.BackgroundColor3 = SMILE.HeaderTop
	AGTitleBar.BorderSizePixel = 0
	AGTitleBar.ZIndex = AGWindow.ZIndex + 2
	AGTitleBar.Parent = AGWindow

	local agTitleGrad = Instance.new("UIGradient")
	agTitleGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, SMILE.HeaderTop),
		ColorSequenceKeypoint.new(1, SMILE.HeaderBot),
	})
	agTitleGrad.Rotation = 90
	agTitleGrad.Parent = AGTitleBar

	createSmileyIcon(AGTitleBar, 18, UDim2.fromOffset(5, 4), SMILE.InsetLight, SMILE.TextDark)

	local AGTitleLabel = Instance.new("TextLabel")
	AGTitleLabel.Size = UDim2.new(1, -82, 1, 0)
	AGTitleLabel.Position = UDim2.fromOffset(29, 0)
	AGTitleLabel.BackgroundTransparency = 1
	AGTitleLabel.Font = Enum.Font.GothamBlack
	AGTitleLabel.TextSize = 12
	AGTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	AGTitleLabel.TextColor3 = SMILE.TextLight
	AGTitleLabel.TextStrokeTransparency = 0.72
	AGTitleLabel.TextStrokeColor3 = SMILE.BorderOuter
	AGTitleLabel.Text = "SENTINEL ULTRA // ANTI-GRIEF"
	AGTitleLabel.ZIndex = AGTitleBar.ZIndex + 1
	AGTitleLabel.Parent = AGTitleBar

	local function makeCaptionBtn(text, xOffset)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(20, 18)
		btn.Position = UDim2.new(1, xOffset, 0, 4)
		btn.BackgroundColor3 = SMILE.BtnFace
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 11
		btn.TextColor3 = SMILE.TextDark
		btn.Text = text
		btn.AutoButtonColor = false
		btn.ZIndex = AGTitleBar.ZIndex + 3
		btn.Parent = AGTitleBar
		addOutline(btn, SMILE.BorderOuter, 1)
		local bv = createBevel(btn, false, 1)

		trackConn(btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = SMILE.BtnHover
		end))
		trackConn(btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = SMILE.BtnFace
			bv.setPressed(false)
		end))
		trackConn(btn.MouseButton1Down:Connect(function()
			bv.setPressed(true)
		end))
		trackConn(btn.MouseButton1Up:Connect(function()
			bv.setPressed(false)
		end))
		return btn
	end

	local AGMinBtn = makeCaptionBtn("_", -45)
	local AGCloseBtn = makeCaptionBtn("X", -23)
	makeDraggable(AGTitleBar, AGWindow)

	-- Inner Container
	local AGBody = Instance.new("Frame")
	AGBody.Name = "AGBody"
	AGBody.Size = UDim2.new(1, -12, 1, -60)
	AGBody.Position = UDim2.fromOffset(6, 32)
	AGBody.BackgroundTransparency = 1
	AGBody.ZIndex = AGWindow.ZIndex + 1
	AGBody.Parent = AGWindow

	-- CRT Telemetry Well
	local AGTelemetryBox = Instance.new("Frame")
	AGTelemetryBox.Size = UDim2.new(1, 0, 0, 26)
	AGTelemetryBox.BackgroundColor3 = SMILE.InsetDark
	AGTelemetryBox.BorderSizePixel = 0
	AGTelemetryBox.ZIndex = AGBody.ZIndex + 1
	AGTelemetryBox.Parent = AGBody
	addOutline(AGTelemetryBox, SMILE.BevelDark, 1)
	createBevel(AGTelemetryBox, true, 1)

	local AGTelemetry = Instance.new("TextLabel")
	AGTelemetry.Size = UDim2.new(1, -14, 1, 0)
	AGTelemetry.Position = UDim2.fromOffset(7, 0)
	AGTelemetry.BackgroundTransparency = 1
	AGTelemetry.Font = Enum.Font.Code
	AGTelemetry.TextSize = 11
	AGTelemetry.TextXAlignment = Enum.TextXAlignment.Left
	AGTelemetry.TextColor3 = SMILE.TextMutedLight
	AGTelemetry.Text = "GUARD: OFF | SLOT 1: NONE | BLK: 0 | FIX: 0"
	AGTelemetry.ZIndex = AGTelemetryBox.ZIndex + 2
	AGTelemetry.Parent = AGTelemetryBox

	-- Tab Bar
	local AGTabBar = Instance.new("Frame")
	AGTabBar.Size = UDim2.new(1, 0, 0, 26)
	AGTabBar.Position = UDim2.fromOffset(0, 30)
	AGTabBar.BackgroundTransparency = 1
	AGTabBar.ZIndex = AGBody.ZIndex + 1
	AGTabBar.Parent = AGBody

	local agTabLayout = Instance.new("UIListLayout")
	agTabLayout.FillDirection = Enum.FillDirection.Horizontal
	agTabLayout.Padding = UDim.new(0, 4)
	agTabLayout.Parent = AGTabBar

	-- Dark CRT Pages Well
	local AGPagesHolder = Instance.new("Frame")
	AGPagesHolder.Size = UDim2.new(1, 0, 1, -58)
	AGPagesHolder.Position = UDim2.fromOffset(0, 58)
	AGPagesHolder.BackgroundColor3 = SMILE.InsetDark
	AGPagesHolder.BorderSizePixel = 0
	AGPagesHolder.ZIndex = AGBody.ZIndex + 1
	AGPagesHolder.Parent = AGBody
	addOutline(AGPagesHolder, SMILE.BevelDark, 1)
	createBevel(AGPagesHolder, true, 1)

	-- 26px Bottom Taskbar
	local AGTaskbar = Instance.new("Frame")
	AGTaskbar.Name = "AGTaskbar"
	AGTaskbar.Size = UDim2.new(1, -6, 0, 24)
	AGTaskbar.Position = UDim2.new(0, 3, 1, -27)
	AGTaskbar.BackgroundColor3 = SMILE.TaskbarBg
	AGTaskbar.BorderSizePixel = 0
	AGTaskbar.ZIndex = AGWindow.ZIndex + 2
	AGTaskbar.Parent = AGWindow
	createBevel(AGTaskbar, false, 1)

	local AGStartChip = Instance.new("Frame")
	AGStartChip.Size = UDim2.fromOffset(92, 18)
	AGStartChip.Position = UDim2.fromOffset(4, 3)
	AGStartChip.BackgroundColor3 = SMILE.BtnFace
	AGStartChip.BorderSizePixel = 0
	AGStartChip.ZIndex = AGTaskbar.ZIndex + 1
	AGStartChip.Parent = AGTaskbar
	addOutline(AGStartChip, SMILE.BorderOuter, 1)
	createBevel(AGStartChip, false, 1)

	local AGStartChipTxt = Instance.new("TextLabel")
	AGStartChipTxt.Size = UDim2.fromScale(1, 1)
	AGStartChipTxt.BackgroundTransparency = 1
	AGStartChipTxt.Font = Enum.Font.GothamBlack
	AGStartChipTxt.TextSize = 9
	AGStartChipTxt.TextColor3 = SMILE.TextDark
	AGStartChipTxt.Text = "SENTINEL.SYS"
	AGStartChipTxt.ZIndex = AGStartChip.ZIndex + 2
	AGStartChipTxt.Parent = AGStartChip

	local AGStatusTray = Instance.new("Frame")
	AGStatusTray.Size = UDim2.new(1, -170, 0, 18)
	AGStatusTray.Position = UDim2.fromOffset(100, 3)
	AGStatusTray.BackgroundColor3 = SMILE.WinFaceAlt
	AGStatusTray.BorderSizePixel = 0
	AGStatusTray.ZIndex = AGTaskbar.ZIndex + 1
	AGStatusTray.Parent = AGTaskbar
	createBevel(AGStatusTray, true, 1)

	local AGStatus = Instance.new("TextLabel")
	AGStatus.Size = UDim2.new(1, -10, 1, 0)
	AGStatus.Position = UDim2.fromOffset(5, 0)
	AGStatus.BackgroundTransparency = 1
	AGStatus.Font = Enum.Font.Code
	AGStatus.TextSize = 10
	AGStatus.TextXAlignment = Enum.TextXAlignment.Left
	AGStatus.TextColor3 = SMILE.TextDark
	AGStatus.TextTruncate = Enum.TextTruncate.AtEnd
	AGStatus.Text = "STANDBY"
	AGStatus.ZIndex = AGStatusTray.ZIndex + 2
	AGStatus.Parent = AGStatusTray

	local AGF3XTray = Instance.new("Frame")
	AGF3XTray.Size = UDim2.fromOffset(64, 18)
	AGF3XTray.Position = UDim2.new(1, -67, 0, 3)
	AGF3XTray.BackgroundColor3 = SMILE.InsetDark
	AGF3XTray.BorderSizePixel = 0
	AGF3XTray.ZIndex = AGTaskbar.ZIndex + 1
	AGF3XTray.Parent = AGTaskbar
	createBevel(AGF3XTray, true, 1)

	local AGF3XBadge = Instance.new("TextLabel")
	AGF3XBadge.Size = UDim2.fromScale(1, 1)
	AGF3XBadge.BackgroundTransparency = 1
	AGF3XBadge.Font = Enum.Font.Code
	AGF3XBadge.TextSize = 10
	AGF3XBadge.TextColor3 = SMILE.AccentRed
	AGF3XBadge.Text = "NO F3X"
	AGF3XBadge.ZIndex = AGF3XTray.ZIndex + 2
	AGF3XBadge.Parent = AGF3XTray

	-- Tab Pages & SmileOS Button Helpers
	local tabPages = {}
	local tabButtons = {}

	local function createTabButton(id, label)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.25, -3, 1, 0)
		btn.BackgroundColor3 = SMILE.BtnFace
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 11
		btn.TextColor3 = SMILE.TextDark
		btn.Text = label
		btn.AutoButtonColor = false
		btn.ZIndex = AGTabBar.ZIndex + 1
		btn.Parent = AGTabBar
		addOutline(btn, SMILE.BorderOuter, 1)
		local bv = createBevel(btn, false, 1)

		local page = Instance.new("ScrollingFrame")
		page.Name = "Page_" .. id
		page.Size = UDim2.new(1, -12, 1, -12)
		page.Position = UDim2.fromOffset(6, 6)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 4
		page.ScrollBarImageColor3 = SMILE.AccentRed
		page.CanvasSize = UDim2.fromOffset(0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.ZIndex = AGPagesHolder.ZIndex + 2
		page.Parent = AGPagesHolder

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = page

		tabButtons[id] = { btn = btn, bv = bv }
		tabPages[id] = page

		trackConn(btn.MouseButton1Click:Connect(function()
			UI.setTab(id)
		end))
		return page
	end

	local function makeActionBtn(parent, order, text, accentColor, heightPx, onClick)
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = order
		btn.Size = UDim2.new(1, -4, 0, heightPx or 28)
		btn.BackgroundColor3 = SMILE.BtnFace
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = SMILE.TextDark
		btn.Text = text
		btn.AutoButtonColor = false
		btn.ZIndex = parent.ZIndex + 1
		btn.Parent = parent
		addOutline(btn, SMILE.BorderOuter, 1)
		local bv = createBevel(btn, false, 1)

		local strip = Instance.new("Frame")
		strip.Size = UDim2.fromOffset(4, (heightPx or 28) - 4)
		strip.Position = UDim2.fromOffset(2, 2)
		strip.BackgroundColor3 = accentColor or SMILE.AccentRed
		strip.BorderSizePixel = 0
		strip.ZIndex = btn.ZIndex + 2
		strip.Parent = btn

		trackConn(btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = SMILE.BtnHover
		end))
		trackConn(btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = SMILE.BtnFace
			bv.setPressed(false)
		end))
		trackConn(btn.MouseButton1Down:Connect(function()
			bv.setPressed(true)
		end))
		trackConn(btn.MouseButton1Up:Connect(function()
			bv.setPressed(false)
		end))
		trackConn(btn.MouseButton1Click:Connect(function()
			if onClick then onClick(btn, strip) end
		end))
		return btn, strip, bv
	end

	local function makeSectionHeader(parent, order, text)
		local lbl = Instance.new("TextLabel")
		lbl.LayoutOrder = order
		lbl.Size = UDim2.new(1, -4, 0, 18)
		lbl.BackgroundColor3 = SMILE.InsetMid
		lbl.BorderSizePixel = 0
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextSize = 10
		lbl.TextColor3 = SMILE.AccentGold
		lbl.Text = " // " .. text
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = parent.ZIndex + 1
		lbl.Parent = parent
		return lbl
	end

	local function setStatus(text, col)
		AGStatus.Text = tostring(text)
		AGStatus.TextColor3 = col or SMILE.TextDark
	end

	local pageShield = createTabButton("SHIELD", "SHIELD")
	local pageMap = createTabButton("MAP", "MAP")
	local pageRadar = createTabButton("RADAR", "RADAR")
	local pageLogs = createTabButton("LOGS", "LOGS")

	function UI.setTab(tabId)
		for id, pair in pairs(tabButtons) do
			local active = (id == tabId)
			tabPages[id].Visible = active
			pair.btn.BackgroundColor3 = active and SMILE.BtnPressedRed or SMILE.BtnFace
			pair.btn.TextColor3 = active and SMILE.TextLight or SMILE.TextDark
			pair.bv.setPressed(active)
		end
		if tabId == "RADAR" and UI.refreshRadar then
			UI.refreshRadar()
		end
	end

	-- ========================================================================
	-- PAGE 1: SHIELD
	-- ========================================================================
	makeSectionHeader(pageShield, 1, "CORE PROTECTION")

	local liveBtn, liveStrip, liveBv = makeActionBtn(pageShield, 2, "LIVE GUARD: OFF", SMILE.AccentRed, 32, function()
		setLiveGuard(not agState.liveGuard)
	end)

	local filterBtn = makeActionBtn(pageShield, 3, "FILTER: Smart Threats", SMILE.AccentGold, 26, function(b)
		agState.filterModeIndex = (agState.filterModeIndex % #FILTER_MODES) + 1
		b.Text = "FILTER: " .. getFilterMode()
		Engine.logEvent("Filter mode -> " .. getFilterMode(), "INFO")
		UI.updateTelemetry()
	end)

	local autoCleanBtn, autoCleanStrip = makeActionBtn(pageShield, 4, "AUTO-PURGE FOREIGN: ON", SMILE.SuccessGreen, 24, function(b, s)
		agState.autoClean = not agState.autoClean
		b.Text = "AUTO-PURGE FOREIGN: " .. (agState.autoClean and "ON" or "OFF")
		s.BackgroundColor3 = agState.autoClean and SMILE.SuccessGreen or SMILE.BevelMid
	end)

	local charShieldBtn, charShieldStrip = makeActionBtn(pageShield, 5, "CHARACTER SHIELD: ON", SMILE.SuccessGreen, 24, function(b, s)
		agState.charShield = not agState.charShield
		b.Text = "CHARACTER SHIELD: " .. (agState.charShield and "ON" or "OFF")
		s.BackgroundColor3 = agState.charShield and SMILE.SuccessGreen or SMILE.BevelMid
	end)

	local autoLockBtn, autoLockStrip = makeActionBtn(pageShield, 6, "AUTO-LOCK RESTORED & SELF: ON", SMILE.SuccessGreen, 24, function(b, s)
		agState.autoLockAfterRestore = not agState.autoLockAfterRestore
		agState.autoLockSelf = agState.autoLockAfterRestore
		b.Text = "AUTO-LOCK RESTORED & SELF: " .. (agState.autoLockAfterRestore and "ON" or "OFF")
		s.BackgroundColor3 = agState.autoLockAfterRestore and SMILE.SuccessGreen or SMILE.BevelMid
	end)

	local antiFlingBtn, antiFlingStrip = makeActionBtn(pageShield, 7, "ANTI-FLING & ANTI-VOID: ON", SMILE.SuccessGreen, 24, function(b, s)
		local nxt = not agState.antiFling
		agState.antiFling = nxt
		agState.antiVoid = nxt
		b.Text = "ANTI-FLING & ANTI-VOID: " .. (nxt and "ON" or "OFF")
		s.BackgroundColor3 = nxt and SMILE.SuccessGreen or SMILE.BevelMid
	end)

	local localQBtn, localQStrip = makeActionBtn(pageShield, 8, "LOCAL QUARANTINE (NO F3X OK): ON", SMILE.InfoBlue, 24, function(b, s)
		agState.localQuarantine = not agState.localQuarantine
		b.Text = "LOCAL QUARANTINE (NO F3X OK): " .. (agState.localQuarantine and "ON" or "OFF")
		s.BackgroundColor3 = agState.localQuarantine and SMILE.InfoBlue or SMILE.BevelMid
	end)

	local autoCounterBtn, autoCounterStrip = makeActionBtn(pageShield, 9, "AUTO-COUNTER (STRIP + CAGE): OFF", SMILE.BevelMid, 24, function(b, s)
		agState.autoCounter = not agState.autoCounter
		b.Text = "AUTO-COUNTER (STRIP + CAGE): " .. (agState.autoCounter and "ON" or "OFF")
		s.BackgroundColor3 = agState.autoCounter and SMILE.AccentRed or SMILE.BevelMid
	end)

	local autoEquipBtn, autoEquipStrip = makeActionBtn(pageShield, 10, "AUTO-EQUIP F3X FOR ACTIONS: OFF", SMILE.BevelMid, 24, function(b, s)
		agState.autoEquipF3X = not agState.autoEquipF3X
		b.Text = "AUTO-EQUIP F3X FOR ACTIONS: " .. (agState.autoEquipF3X and "ON" or "OFF")
		s.BackgroundColor3 = agState.autoEquipF3X and SMILE.AccentGold or SMILE.BevelMid
	end)

	function UI.refreshShieldToggles()
		if agState.liveGuard then
			liveBtn.Text = "LIVE GUARD: ON [ACTIVE]"
			liveBtn.BackgroundColor3 = SMILE.BtnPressedRed
			liveBtn.TextColor3 = SMILE.TextLight
			liveStrip.BackgroundColor3 = SMILE.SuccessGreen
			liveBv.setPressed(true)
		else
			liveBtn.Text = "LIVE GUARD: OFF"
			liveBtn.BackgroundColor3 = SMILE.BtnFace
			liveBtn.TextColor3 = SMILE.TextDark
			liveStrip.BackgroundColor3 = SMILE.AccentRed
			liveBv.setPressed(false)
		end
	end

	-- ========================================================================
	-- PAGE 2: MAP (SNAPSHOT SLOTS + RESTORE + SWEEP)
	-- ========================================================================
	makeSectionHeader(pageMap, 1, "SNAPSHOT SLOTS")

	local slotRow = Instance.new("Frame")
	slotRow.LayoutOrder = 2
	slotRow.Size = UDim2.new(1, -4, 0, 26)
	slotRow.BackgroundTransparency = 1
	slotRow.ZIndex = pageMap.ZIndex + 1
	slotRow.Parent = pageMap

	local slotLayout = Instance.new("UIListLayout")
	slotLayout.FillDirection = Enum.FillDirection.Horizontal
	slotLayout.Padding = UDim.new(0, 4)
	slotLayout.Parent = slotRow

	local slotBtns = {}
	for i = 1, 3 do
		local sBtn = Instance.new("TextButton")
		sBtn.Size = UDim2.new(1 / 3, -3, 1, 0)
		sBtn.BackgroundColor3 = SMILE.BtnFace
		sBtn.BorderSizePixel = 0
		sBtn.Font = Enum.Font.GothamBlack
		sBtn.TextSize = 10
		sBtn.TextColor3 = SMILE.TextDark
		sBtn.Text = "S" .. i .. ": EMPTY"
		sBtn.AutoButtonColor = false
		sBtn.ZIndex = slotRow.ZIndex + 1
		sBtn.Parent = slotRow
		addOutline(sBtn, SMILE.BorderOuter, 1)
		local sBv = createBevel(sBtn, false, 1)
		slotBtns[i] = { btn = sBtn, bv = sBv }

		trackConn(sBtn.MouseButton1Click:Connect(function()
			agState.activeSlot = i
			agState.scanCursor = 1
			syncPartWatchersToActiveSlot()
			UI.refreshSlotButtons()
			UI.updateTelemetry()
			setStatus("SELECTED SLOT " .. i, SMILE.TextDark)
		end))
	end

	function UI.refreshSlotButtons()
		for i = 1, 3 do
			local pair = slotBtns[i]
			local snap = agState.snapshots[i]
			local selected = (agState.activeSlot == i)
			pair.btn.Text = snap and ("S" .. i .. ": " .. snap.count .. "P") or ("S" .. i .. ": EMPTY")
			pair.btn.BackgroundColor3 = selected and SMILE.BtnPressedRed or SMILE.BtnFace
			pair.btn.TextColor3 = selected and SMILE.TextLight or SMILE.TextDark
			pair.bv.setPressed(selected)
		end
	end

	makeSectionHeader(pageMap, 3, "MAP ACTIONS")

	makeActionBtn(pageMap, 4, "SAVE SNAPSHOT TO ACTIVE SLOT", SMILE.InfoBlue, 28, function()
		local count = Engine.takeSnapshot(agState.activeSlot)
		setStatus("SAVED " .. count .. " PARTS -> S" .. agState.activeSlot, SMILE.TextDark)
	end)

	makeActionBtn(pageMap, 5, "ADOPT LEGIT NEW PARTS INTO SLOT", SMILE.AccentGold, 26, function()
		local addedP, addedFx = Engine.adoptNewPartsIntoSnapshot()
		setStatus(("ADOPTED +%d PARTS, +%d FX"):format(addedP, addedFx), SMILE.TextDark)
	end)

	makeActionBtn(pageMap, 6, "RESTORE MAP FROM SNAPSHOT", SMILE.SuccessGreen, 32, function()
		setStatus("RESTORING MAP...", SMILE.TextDark)
		task.spawn(function()
			local _, res = withF3X(true, true, function(ep)
				return Engine.restoreMap(ep)
			end)
			setStatus(tostring(res or "F3X MISSING"), SMILE.TextDark)
		end)
	end)

	makeActionBtn(pageMap, 7, "PURGE GRIEF & SPAM EFFECTS", SMILE.AccentRed, 28, function()
		task.spawn(function()
			local _, msg = withF3X(true, true, function(ep)
				local _, m = Engine.purgeSpam(ep, false)
				return m
			end)
			setStatus(tostring(msg or "F3X MISSING"), SMILE.TextDark)
		end)
	end)

	makeActionBtn(pageMap, 8, "CLEAR FOREIGN BUILDS NEAR ME (45 STUDS)", SMILE.AccentRed, 26, function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			setStatus("NO CHARACTER", SMILE.AccentRed)
			return
		end
		task.spawn(function()
			local _, msg = withF3X(true, true, function(ep)
				local _, m = Engine.clearAroundPosition(ep, hrp.Position, AG_CONFIG.ClearRadius)
				return m
			end)
			setStatus(tostring(msg or "F3X MISSING"), SMILE.TextDark)
		end)
	end)

	makeActionBtn(pageMap, 9, "LOCK ALL SNAPSHOT PARTS", SMILE.AccentGold, 26, function()
		local snap = getActiveSnapshot()
		if not snap then
			setStatus("NO SNAPSHOT IN SLOT", SMILE.AccentRed)
			return
		end
		task.spawn(function()
			local ok = withF3X(true, true, function(ep)
				local list = {}
				for p, d in pairs(snap.parts) do
					if p and p.Parent ~= nil then
						table.insert(list, p)
						d.Locked = true
					end
				end
				return batchLockParts(ep, list, true)
			end)
			setStatus(ok and "LOCKED SNAPSHOT PARTS" or "F3X MISSING", SMILE.TextDark)
		end)
	end)

	-- ========================================================================
	-- PAGE 3: RADAR (THREAT SCORING + WHITELIST/BLACKLIST + COUNTER ACTIONS)
	-- ========================================================================
	makeSectionHeader(pageRadar, 1, "SERVER THREAT RADAR")

	local radarSummary = Instance.new("TextLabel")
	radarSummary.LayoutOrder = 2
	radarSummary.Size = UDim2.new(1, -4, 0, 20)
	radarSummary.BackgroundTransparency = 1
	radarSummary.Font = Enum.Font.Code
	radarSummary.TextSize = 10
	radarSummary.TextXAlignment = Enum.TextXAlignment.Left
	radarSummary.TextColor3 = SMILE.TextMutedLight
	radarSummary.Text = "Scanning server..."
	radarSummary.ZIndex = pageRadar.ZIndex + 1
	radarSummary.Parent = pageRadar

	local radarList = Instance.new("Frame")
	radarList.LayoutOrder = 3
	radarList.Size = UDim2.new(1, -4, 0, 0)
	radarList.AutomaticSize = Enum.AutomaticSize.Y
	radarList.BackgroundTransparency = 1
	radarList.ZIndex = pageRadar.ZIndex + 1
	radarList.Parent = pageRadar

	local radarListLayout = Instance.new("UIListLayout")
	radarListLayout.Padding = UDim.new(0, 5)
	radarListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	radarListLayout.Parent = radarList

	function UI.refreshRadar()
		for _, child in ipairs(radarList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local entries = {}
		local f3xCount = 0
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local hasF3X, equipped = playerHasF3X(plr)
				if hasF3X then f3xCount += 1 end
				local score = agState.threatScores[plr.UserId] or 0
				local wl = agState.whitelist[plr.UserId] == true
				local bl = agState.blacklist[plr.UserId] == true
				local prio = (bl and 10000 or 0) + score * 20 + (equipped and 40 or (hasF3X and 20 or 0)) - (wl and 500 or 0)
				table.insert(entries, {
					plr = plr,
					hasF3X = hasF3X,
					equipped = equipped,
					score = score,
					wl = wl,
					bl = bl,
					prio = prio,
				})
			end
		end

		table.sort(entries, function(a, b)
			if a.prio ~= b.prio then return a.prio > b.prio end
			return a.plr.Name < b.plr.Name
		end)

		radarSummary.Text = ("PLAYERS: %d | F3X DETECTED: %d | WL: %d"):format(#entries, f3xCount, (function()
			local n = 0
			for _ in pairs(agState.whitelist) do n += 1 end
			return math.max(0, n - 1)
		end)())

		for idx, item in ipairs(entries) do
			local p = item.plr
			local card = Instance.new("Frame")
			card.LayoutOrder = idx
			card.Size = UDim2.new(1, 0, 0, 54)
			card.BackgroundColor3 = SMILE.InsetMid
			card.BorderSizePixel = 0
			card.ZIndex = radarList.ZIndex + 1
			card.Parent = radarList
			addOutline(card, item.bl and SMILE.AccentRed or (item.wl and SMILE.SuccessGreen or SMILE.BevelDark), 1)

			local tagText = item.bl and "[BL]" or (item.wl and "[WL]" or (item.equipped and "[F3X!]" or (item.hasF3X and "[F3X]" or "[OK]")))
			local tagCol = item.bl and SMILE.AccentRed or (item.wl and SMILE.SuccessGreen or (item.hasF3X and SMILE.AccentGold or SMILE.TextMutedLight))

			local infoLbl = Instance.new("TextLabel")
			infoLbl.Size = UDim2.new(1, -10, 0, 20)
			infoLbl.Position = UDim2.fromOffset(6, 3)
			infoLbl.BackgroundTransparency = 1
			infoLbl.Font = Enum.Font.Code
			infoLbl.TextSize = 11
			infoLbl.TextXAlignment = Enum.TextXAlignment.Left
			infoLbl.TextColor3 = tagCol
			infoLbl.Text = ("%s %s  | T:%d"):format(tagText, p.Name, item.score)
			infoLbl.ZIndex = card.ZIndex + 1
			infoLbl.Parent = card

			local btnRow = Instance.new("Frame")
			btnRow.Size = UDim2.new(1, -10, 0, 22)
			btnRow.Position = UDim2.fromOffset(5, 27)
			btnRow.BackgroundTransparency = 1
			btnRow.ZIndex = card.ZIndex + 1
			btnRow.Parent = card

			local bLay = Instance.new("UIListLayout")
			bLay.FillDirection = Enum.FillDirection.Horizontal
			bLay.Padding = UDim.new(0, 4)
			bLay.Parent = btnRow

			local function makeMiniBtn(label, wFrac, onClick)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(wFrac, -3, 1, 0)
				b.BackgroundColor3 = SMILE.BtnFace
				b.BorderSizePixel = 0
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 9
				b.TextColor3 = SMILE.TextDark
				b.Text = label
				b.AutoButtonColor = false
				b.ZIndex = btnRow.ZIndex + 1
				b.Parent = btnRow
				addOutline(b, SMILE.BorderOuter, 1)
				createBevel(b, false, 1)
				trackConn(b.MouseButton1Click:Connect(onClick))
				return b
			end

			makeMiniBtn(item.wl and "UN-WL" or "WL", 0.16, function()
				agState.whitelist[p.UserId] = not item.wl or nil
				if agState.whitelist[p.UserId] then agState.blacklist[p.UserId] = nil end
				UI.refreshRadar()
			end)

			makeMiniBtn(item.bl and "UN-BL" or "BL", 0.16, function()
				agState.blacklist[p.UserId] = not item.bl or nil
				if agState.blacklist[p.UserId] then agState.whitelist[p.UserId] = nil end
				UI.refreshRadar()
			end)

			makeMiniBtn("STRIP", 0.22, function()
				task.spawn(function()
					local _, msg = withF3X(true, true, function(ep)
						local _, m = Engine.stripPlayerF3X(ep, p)
						return m
					end)
					setStatus(tostring(msg or "F3X MISSING"), SMILE.TextDark)
				end)
			end)

			local caged = Runtime.cagedPartsByUserId[p.UserId] ~= nil
			makeMiniBtn(caged and "UNCAGE" or "CAGE", 0.23, function()
				task.spawn(function()
					local _, msg = withF3X(true, true, function(ep)
						if Runtime.cagedPartsByUserId[p.UserId] then
							Engine.uncagePlayer(ep, p)
							return "Uncaged " .. p.Name
						else
							local _, m = Engine.cagePlayer(ep, p)
							return m
						end
					end)
					setStatus(tostring(msg or "F3X MISSING"), SMILE.TextDark)
					task.defer(UI.refreshRadar)
				end)
			end)

			makeMiniBtn("PURGE", 0.23, function()
				task.spawn(function()
					local _, msg = withF3X(true, true, function(ep)
						local _, m = Engine.nukePlayerBuilds(ep, p)
						return m
					end)
					setStatus(tostring(msg or "F3X MISSING"), SMILE.TextDark)
				end)
			end)
		end
	end

	-- ========================================================================
	-- PAGE 4: LOGS
	-- ========================================================================
	makeSectionHeader(pageLogs, 1, "ACTIVITY LOG")

	makeActionBtn(pageLogs, 2, "CLEAR LOGS", SMILE.AccentGold, 22, function()
		for _, entry in ipairs(Runtime.agLogs) do
			if entry and entry.Parent then entry:Destroy() end
		end
		table.clear(Runtime.agLogs)
	end)

	local AGLogContainer = Instance.new("Frame")
	AGLogContainer.LayoutOrder = 3
	AGLogContainer.Size = UDim2.new(1, -4, 0, 0)
	AGLogContainer.AutomaticSize = Enum.AutomaticSize.Y
	AGLogContainer.BackgroundTransparency = 1
	AGLogContainer.ZIndex = pageLogs.ZIndex + 1
	AGLogContainer.Parent = pageLogs

	local logLayout = Instance.new("UIListLayout")
	logLayout.Padding = UDim.new(0, 3)
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logLayout.Parent = AGLogContainer

	function Engine.logEvent(msg, level)
		Runtime.nextLogOrder -= 1
		local col = SMILE.TextLight
		if level == "BLOCK" or level == "COUNTER" then
			col = SMILE.AccentRed
		elseif level == "RESTORE" then
			col = SMILE.SuccessGreen
		elseif level == "WARN" then
			col = SMILE.AccentGold
		elseif level == "INFO" then
			col = SMILE.InfoBlue
		end

		local lbl = Instance.new("TextLabel")
		lbl.LayoutOrder = Runtime.nextLogOrder
		lbl.Size = UDim2.new(1, 0, 0, 0)
		lbl.AutomaticSize = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 10
		lbl.TextWrapped = true
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = col
		lbl.Text = ("[%s] %s"):format(os.date("%H:%M:%S"), tostring(msg))
		lbl.ZIndex = AGLogContainer.ZIndex + 1
		lbl.Parent = AGLogContainer

		table.insert(Runtime.agLogs, 1, lbl)
		while #Runtime.agLogs > AG_CONFIG.MaxLogEntries do
			local old = table.remove(Runtime.agLogs)
			if old and old.Parent then
				old:Destroy()
			end
		end
	end

	function UI.updateTelemetry()
		local snap = getActiveSnapshot()
		local guardStr = agState.liveGuard and "ON" or "OFF"
		local slotStr = snap and (snap.count .. "P") or "NONE"
		AGTelemetry.Text = ("GUARD: %s | S%d: %s | BLK: %d | FIX: %d"):format(
			guardStr,
			agState.activeSlot,
			slotStr,
			agState.threatsBlocked,
			agState.restoresPerformed
		)
		AGTelemetry.TextColor3 = agState.liveGuard and SMILE.SuccessGreen or SMILE.TextMutedLight
	end

	-- ========================================================================
	-- WINDOW OPEN / CLOSE / MINIMIZE + F3X BADGE POLLING
	-- ========================================================================
	local function positionWindowBesideMain()
		local vp = getScreenSize(ScreenGui)
		if MainFrame and MainFrame.Parent and MainFrame.Visible then
			local mPos = MainFrame.AbsolutePosition
			local mSize = MainFrame.AbsoluteSize
			local scaledW = AG_FULL_W * AGScale.Scale
			local x = mPos.X + mSize.X + 8
			if x + scaledW > vp.X - 4 then
				x = math.max(4, mPos.X - scaledW - 8)
			end
			local y = math.clamp(mPos.Y, 4, math.max(4, vp.Y - AG_FULL_H * AGScale.Scale - 4))
			AGWindow.Position = UDim2.fromOffset(x, y)
		else
			AGWindow.Position = UDim2.fromOffset(math.max(8, vp.X - AG_FULL_W - 24), 48)
		end
		clampWindowToScreen(AGWindow, ScreenGui)
	end

	local function setOpen(open)
		agState.windowOpen = open == true
		if agState.windowOpen then
			agState.windowMinimized = false
			AGBody.Visible = true
			AGTaskbar.Visible = true
			AGMinBtn.Text = "_"
			positionWindowBesideMain()
			AGWindow.Size = UDim2.fromOffset(AG_FULL_W, AG_COLLAPSED_H)
			AGWindow.Visible = true
			TweenService:Create(
				AGWindow,
				TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Size = UDim2.fromOffset(AG_FULL_W, AG_FULL_H) }
			):Play()
			UI.refreshRadar()
			UI.updateTelemetry()
		else
			local tw = TweenService:Create(
				AGWindow,
				TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{ Size = UDim2.fromOffset(AG_FULL_W, AG_COLLAPSED_H) }
			)
			tw:Play()
			task.delay(0.18, function()
				if agAlive and not agState.windowOpen then
					AGWindow.Visible = false
				end
			end)
		end
		if type(onStateChanged) == "function" then
			pcall(onStateChanged, agState.windowOpen)
		end
	end

	local function toggle()
		setOpen(not agState.windowOpen)
	end

	local function toggleMinimize()
		if not agState.windowOpen then return end
		agState.windowMinimized = not agState.windowMinimized
		if agState.windowMinimized then
			AGBody.Visible = false
			AGTaskbar.Visible = false
			AGMinBtn.Text = "+"
			AGWindow.Size = UDim2.fromOffset(AG_FULL_W, AG_COLLAPSED_H)
		else
			AGBody.Visible = true
			AGTaskbar.Visible = true
			AGMinBtn.Text = "_"
			AGWindow.Size = UDim2.fromOffset(AG_FULL_W, AG_FULL_H)
			clampWindowToScreen(AGWindow, ScreenGui)
		end
		agWindowBevel.setPressed(false)
	end

	trackConn(AGMinBtn.MouseButton1Click:Connect(toggleMinimize))
	trackConn(AGCloseBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end))

	task.spawn(function()
		while agAlive do
			local ep, tool = getF3XEndpoint(false)
			if ep and tool then
				local inChar = LocalPlayer.Character and tool:IsDescendantOf(LocalPlayer.Character)
				AGF3XBadge.Text = inChar and "F3X OK" or "IN PACK"
				AGF3XBadge.TextColor3 = inChar and SMILE.SuccessGreen or SMILE.AccentGold
			else
				AGF3XBadge.Text = "NO F3X"
				AGF3XBadge.TextColor3 = SMILE.AccentRed
			end
			task.wait(0.8)
		end
	end)

	UI.setTab("SHIELD")
	UI.refreshSlotButtons()
	UI.refreshShieldToggles()
	UI.updateTelemetry()

	importExistingCoreRigParts()
	if AG_CONFIG.AutoSnapshotOnInit then
		task.delay(0.4, function()
			if agAlive and not agState.snapshots[1] then
				importExistingCoreRigParts()
				Engine.takeSnapshot(1, true)
			end
		end)
	end

	local controller

	local function cleanup()
		if not agAlive then return end
		agAlive = false
		agState.liveGuard = false
		clearPartWatchers()
		for _, c in ipairs(Runtime.charWatchConns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(Runtime.charWatchConns)
		for _, c in ipairs(agConnections) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(agConnections)
		if createdOwnGui and ScreenGui and ScreenGui.Parent then
			ScreenGui:Destroy()
		elseif AGWindow and AGWindow.Parent then
			AGWindow:Destroy()
		end
		if env.ULTRAKILL_ANTIGRIEF == controller then
			env.ULTRAKILL_ANTIGRIEF = nil
		end
		if _G.ULTRAKILL_ANTIGRIEF == controller then
			_G.ULTRAKILL_ANTIGRIEF = nil
		end
	end

	controller = {
		toggle = toggle,
		setOpen = setOpen,
		isOpen = function()
			return agState.windowOpen
		end,
		markRigDeployGrace = markRigDeployGrace,
		endRigDeployGrace = endRigDeployGrace,
		protectInstance = function(inst)
			if inst then
				Runtime.protectedRigInstances[inst] = true
			end
		end,
		unprotectInstance = function(inst)
			if inst then
				Runtime.protectedRigInstances[inst] = nil
			end
		end,
		clearProtectedRig = function()
			Runtime.protectedRigInstances = setmetatable({}, { __mode = "k" })
		end,
		takeSnapshot = Engine.takeSnapshot,
		setLiveGuard = setLiveGuard,
		cleanup = cleanup,
	}

	env.ULTRAKILL_ANTIGRIEF = controller
	_G.ULTRAKILL_ANTIGRIEF = controller

	return controller
end