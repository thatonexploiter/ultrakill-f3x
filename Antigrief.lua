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

local FOREIGN_UK_ALLOWED_CHILD_CLASSES = {
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	PointLight = true,
	SpotLight = true,
	Attachment = true,
	NoCollisionConstraint = true,
	Weld = true,
	WeldConstraint = true,
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

local function parseUKUserTag(name)
	if type(name) ~= "string" then return nil, nil end
	local uidStr, label = name:match("^UKF3X_(%-?%d+)_(.+)$")
	if not uidStr then return nil, nil end
	return tonumber(uidStr), label
end

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
		ForeignUKMaxSize = 18,
		ForeignUKMaxBeamLength = 250,
		ForeignUKMaxPartsPerPlayer = 260,
		ForeignUKVerifyGrace = 0.28,
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
		trustOtherUKRigs = true,
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
		foreignUKPartsByUid = {},
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

	local function getForeignUKPartCount(uid)
		local bucket = Runtime.foreignUKPartsByUid[uid]
		if not bucket then return 0 end
		local count = 0
		for p in pairs(bucket) do
			if p and p.Parent ~= nil and p:IsDescendantOf(workspace) then
				count += 1
			else
				bucket[p] = nil
			end
		end
		return count
	end

	local function isVerifiedForeignUKPart(inst)
		if not agState.trustOtherUKRigs or not inst or not inst.Parent then
			return false, nil
		end

		local basePart = nil
		if inst:IsA("BasePart") then
			basePart = inst
		elseif FOREIGN_UK_ALLOWED_CHILD_CLASSES[inst.ClassName] then
			basePart = inst:FindFirstAncestorWhichIsA("BasePart")
		else
			return false, nil
		end

		if not basePart or not basePart.Parent then
			return false, nil
		end

		local uid, label = parseUKUserTag(basePart.Name)
		if not uid or uid == LocalPlayer.UserId then
			return false, nil
		end

		local owner = Players:GetPlayerByUserId(uid)
		if not owner or agState.blacklist[uid] then
			return false, nil
		end

		if basePart:IsA("Seat") or basePart:IsA("VehicleSeat") or basePart:IsA("SpawnLocation") then
			return false, nil
		end

		local sz = basePart.Size
		local maxAxis = math.max(sz.X, sz.Y, sz.Z)
		local isBeam = (label == "fx_beam1" or label == "fx_beam2" or label == "fx_bcore1" or label == "fx_bcore2")
		if isBeam then
			if math.max(sz.X, sz.Y) > 1.5 or sz.Z > AG_CONFIG.ForeignUKMaxBeamLength then
				return false, nil
			end
		elseif maxAxis > AG_CONFIG.ForeignUKMaxSize then
			return false, nil
		end

		if not basePart.Anchored or basePart.AssemblyLinearVelocity.Magnitude > 25 then
			return false, nil
		end
		if basePart.CanCollide and basePart.Position.Y <= 10000 then
			return false, nil
		end

		local bucket = Runtime.foreignUKPartsByUid[uid]
		if not bucket then
			bucket = setmetatable({}, { __mode = "k" })
			Runtime.foreignUKPartsByUid[uid] = bucket
		end

		if not bucket[basePart] then
			if getForeignUKPartCount(uid) >= AG_CONFIG.ForeignUKMaxPartsPerPlayer then
				return false, nil
			end
			bucket[basePart] = true
		end

		return true, owner
	end

	local function hasActiveForeignUKParts(uid)
		return getForeignUKPartCount(uid) > 0
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
			if obj and not seen[obj] and obj.Parent ~= nil
				and not isProtectedWorldSystem(obj)
				and not isOwnRigPart(obj)
				and not isOwnCoreCharacterHelper(obj)
				and not isVerifiedForeignUKPart(obj) then
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
		if isProtectedWorldSystem(inst) or isOwnRigPart(inst) or isOwnCoreCharacterHelper(inst) or Runtime.scriptManagedParts[inst] or isVerifiedForeignUKPart(inst) then return end

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
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) and not isVerifiedForeignUKPart(desc) then
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
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) and not isVerifiedForeignUKPart(desc) then
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
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) and not isVerifiedForeignUKPart(desc) then
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
		if isProtectedWorldSystem(part) or Runtime.scriptManagedParts[part] or isOwnRigPart(part) or isOwnCoreCharacterHelper(part) or isVerifiedForeignUKPart(part) then return false, nil end

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
		if isProtectedWorldSystem(inst) or Runtime.scriptManagedParts[inst] or isOwnRigPart(inst) or isOwnCoreCharacterHelper(inst) or isVerifiedForeignUKPart(inst) then return false end

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
			if not isVerifiedForeignUKPart(desc) then
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
			if not isProtectedWorldSystem(desc) and not Runtime.scriptManagedParts[desc] and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) and not isVerifiedForeignUKPart(desc) then
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
			Engine.logEvent("Cleared " .. removed .. " items within " .. r .. " studs", "BLOCK")
			if UI.updateTelemetry then UI.updateTelemetry() end
		end
		return removed, "Cleared " .. removed .. " items"
	end

	function Engine.restoreMap(endpoint)
		if not endpoint then return "F3X not found" end
		local snap = getActiveSnapshot()
		if not snap then
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp and createFallbackBaseplate(endpoint, hrp.Position) then
				return "No snapshot: spawned rescue pad"
			end
			return "No snapshot in Slot " .. agState.activeSlot
		end
		while Runtime.restoreInFlight and agAlive do
			task.wait(0.03)
		end
		if not agAlive then return "Aborted" end

		Runtime.restoreInFlight = true
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

			local rebuiltMap = {}
			local rebuildQueue = {}
			local undoneCount = 0
			for _, oldPart in ipairs(missingParts) do
				if oldPart and oldPart.Parent ~= nil and oldPart:IsDescendantOf(workspace) then
					undoneCount += 1
				else
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

			agState.restoresPerformed += 1
			if removed > 0 then agState.threatsBlocked += removed end

			return ("Restored (Undone: %d, Rebuilt: %d)"):format(undoneCount, rebuiltCount)
		end)

		endSelfRestoring()
		Runtime.restoreInFlight = false

		local msg = okRun and summary or ("Restore error: " .. tostring(summary))
		Engine.logEvent(msg, okRun and "RESTORE" or "WARN")
		if UI.updateTelemetry then UI.updateTelemetry() end
		if UI.refreshSlotButtons then UI.refreshSlotButtons() end
		return msg
	end
	Engine.fullRestoreMap = Engine.restoreMap

	function Engine.lockMap(endpoint, locked)
		if not endpoint then return "F3X not found" end
		local snap = getActiveSnapshot()
		local targets = {}
		if snap then
			for part, data in pairs(snap.parts) do
				if part and part.Parent ~= nil then
					table.insert(targets, part)
					data.Locked = locked
				end
			end
		else
			for _, desc in ipairs(workspace:GetDescendants()) do
				if desc:IsA("BasePart") and not isProtectedWorldSystem(desc) and not isPlayerCharacterDescendant(desc) and not isOwnRigPart(desc) and not isVerifiedForeignUKPart(desc) then
					table.insert(targets, desc)
				end
			end
		end
		batchLockParts(endpoint, targets, locked)
		local verb = locked and "Locked " or "Unlocked "
		Engine.logEvent(verb .. #targets .. " parts", "INFO")
		return verb .. #targets .. " parts"
	end

	function Engine.lockSelfCharacterParts(endpoint, locked)
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
		Engine.logEvent(msg, "SHIELD")
		return msg
	end

	function Engine.rescueCharacter(endpoint)
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return "No character" end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		if agState.lastSafeCFrame then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = { char }
			local origin = agState.lastSafeCFrame.Position + Vector3.new(0, 3, 0)
			local hit = workspace:Raycast(origin, Vector3.new(0, -24, 0), rayParams)
			if hit and hit.Instance and hit.Instance.CanCollide then
				hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 4, 0)
				Engine.logEvent("Rescued to verified safe spot", "SHIELD")
				return "Teleported to safe spot"
			end
		end

		if endpoint then
			local safeY = math.max(hrp.Position.Y, 12)
			local padPos = Vector3.new(hrp.Position.X, safeY, hrp.Position.Z)
			createFallbackBaseplate(endpoint, padPos)
			hrp.CFrame = CFrame.new(padPos.X, padPos.Y + 4, padPos.Z)
			Engine.logEvent("Floor missing: spawned emergency pad", "SHIELD")
			return "Spawned rescue pad"
		end

		if agState.lastSafeCFrame then
			hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 4, 0)
			return "Teleported (no F3X)"
		end
		return "No safe spot or F3X"
	end

	function Engine.stripPlayerF3X(endpoint, targetPlr)
		if not endpoint or not targetPlr or targetPlr == LocalPlayer then return "Target unavailable" end
		local targets = {}
		local function collectTools(container)
			if not container then return end
			for _, item in ipairs(container:GetChildren()) do
				if item:FindFirstChild("SyncAPI") or item:FindFirstChild("SyncApi") then
					table.insert(targets, item)
					local handle = item:FindFirstChild("Handle")
					if handle then table.insert(targets, handle) end
				end
			end
		end
		collectTools(targetPlr.Character)
		collectTools(targetPlr:FindFirstChild("Backpack"))
		if #targets == 0 then
			return targetPlr.Name .. " has no F3X"
		end
		local removed = batchRemove(endpoint, targets)
		if removed > 0 then
			agState.threatsBlocked += removed
			if UI.updateTelemetry then UI.updateTelemetry() end
		end
		Engine.logEvent("Disarm attempt on " .. targetPlr.Name, "COUNTER")
		return "Attempted disarm on " .. targetPlr.Name
	end

	function Engine.uncagePlayer(endpoint, targetPlr)
		if not targetPlr then return 0, "Invalid target" end
		local list = Runtime.cagedPartsByUserId[targetPlr.UserId]
		if not list or #list == 0 then return 0, targetPlr.Name .. " not caged" end
		Runtime.cagedPartsByUserId[targetPlr.UserId] = nil
		local removed = endpoint and batchRemove(endpoint, list) or 0
		Engine.logEvent("Uncaged " .. targetPlr.Name, "INFO")
		return removed, "Uncaged " .. targetPlr.Name
	end

	function Engine.cagePlayer(endpoint, targetPlr)
		if not endpoint or not targetPlr or targetPlr == LocalPlayer then return "Target unavailable" end
		local char = targetPlr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return "No target root" end

		Engine.uncagePlayer(endpoint, targetPlr)
		beginSelfRestoring()

		local center = hrp.Position
		local wallSpecs = {
			{ cf = CFrame.new(center + Vector3.new(0, -4.5, 0)), size = Vector3.new(11, 1.5, 11) },
			{ cf = CFrame.new(center + Vector3.new(0, 5.5, 0)), size = Vector3.new(11, 1.5, 11) },
			{ cf = CFrame.new(center + Vector3.new(5, 0.5, 0)), size = Vector3.new(1.5, 11, 11) },
			{ cf = CFrame.new(center + Vector3.new(-5, 0.5, 0)), size = Vector3.new(1.5, 11, 11) },
			{ cf = CFrame.new(center + Vector3.new(0, 0.5, 5)), size = Vector3.new(11, 11, 1.5) },
			{ cf = CFrame.new(center + Vector3.new(0, 0.5, -5)), size = Vector3.new(11, 11, 1.5) },
		}

		local created = {}
		runParallel(#wallSpecs, 6, function(idx)
			if not agAlive then return end
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
			table.insert(colorBatch, { Part = p, Color = Color3.fromRGB(220, 35, 35), UnionColoring = true })
			table.insert(matBatch, { Part = p, Material = Enum.Material.ForceField, Transparency = 0.4, Reflectance = 0 })
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
		Engine.logEvent("Caged " .. targetPlr.Name .. " (" .. #renameList .. " walls)", "BLOCK")
		return "Caged " .. targetPlr.Name
	end

	function Engine.destroyManagedArtifacts(endpoint)
		if not endpoint then return 0 end
		local toDel = {}
		for part in pairs(Runtime.scriptManagedParts) do
			if part and part.Parent ~= nil then
				table.insert(toDel, part)
			end
		end
		table.clear(Runtime.cagedPartsByUserId)
		return batchRemove(endpoint, toDel)
	end

	-- ========================================================================
	-- CHARACTER SHIELD (INSTANT UNDO + LOCK + NO-SIT + SIZE GUARD)
	-- ========================================================================
	local function clearCharWatchConns()
		for _, c in ipairs(Runtime.charWatchConns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(Runtime.charWatchConns)
		table.clear(Runtime.charPartBaselineSizes)
	end

	local function watchOwnCharacter(char)
		clearCharWatchConns()
		if not char then return end
		registerCharacter(LocalPlayer, char)

		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") and STANDARD_CHAR_PART_NAMES[desc.Name] then
				Runtime.charPartBaselineSizes[desc] = desc.Size
			end
		end

		table.insert(Runtime.charWatchConns, char.DescendantRemoving:Connect(function(desc)
			if not agAlive or not agState.charShield then return end
			if isRigDeployGraceActive() or Runtime.selfRestoringDepth > 0 or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end
			if not char.Parent then return end
			if hum and hum.Health <= 0 and desc ~= hum then return end

			if desc:IsA("Humanoid")
				or (desc:IsA("BasePart") and CRITICAL_CHAR_PART_NAMES[desc.Name])
				or (desc:IsA("JointInstance") and CRITICAL_JOINT_NAMES[desc.Name]) then
				Runtime.pendingCharUndo[desc] = true
				attributeThreat(hrp and hrp.Position, 6, "CHAR_DELETE")
				task.spawn(function()
					local okRes = withF3X(false, true, function(ep)
						beginSelfRestoring()
						pcall(function()
							ep:InvokeServer("UndoRemove", { desc })
						end)
						if agState.autoLockSelf and desc:IsA("BasePart") then
							batchLockParts(ep, { desc }, true)
						end
						endSelfRestoring()
						return true
					end)
					if okRes then
						Runtime.pendingCharUndo[desc] = nil
						agState.threatsBlocked += 1
						Engine.logEvent("Instant char recovery: " .. desc.Name, "SHIELD")
						if UI.updateTelemetry then UI.updateTelemetry() end
					end
				end)
			end
		end))

		table.insert(Runtime.charWatchConns, char.DescendantAdded:Connect(function(desc)
			if not agAlive or not agState.charShield then return end
			if isRigDeployGraceActive() or Runtime.selfRestoringDepth > 0 or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end

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

		if hum then
			table.insert(Runtime.charWatchConns, hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
				if not agAlive or not agState.charShield then return end
				local seat = hum.SeatPart
				if not seat then return end
				if isOwnRigPart(seat) then return end
				local snap = getActiveSnapshot()
				if snap and snap.parts[seat] then return end
				if isWhitelistedPlayerNearby(seat.Position, 20) then return end

				hum.Sit = false
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
				quarantineInstanceLocally(seat)
				if agState.autoClean then
					Runtime.pendingRemove[seat] = true
				end
				attributeThreat(seat.Position, 6, "Seat Kidnap")
				agState.threatsBlocked += 1
				Engine.logEvent("Blocked foreign Seat trap!", "SHIELD")
				if agState.lastSafeCFrame and hrp then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 3, 0)
				end
				if UI.updateTelemetry then UI.updateTelemetry() end
			end))
		end

		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") then
				table.insert(Runtime.charWatchConns, desc.Changed:Connect(function(prop)
					if not agAlive or not agState.charShield or isRigDeployGraceActive() or Runtime.selfRestoringDepth > 0 then return end
					if prop == "Locked" and desc.Locked == false and agState.autoLockSelf then
						task.spawn(function()
							withF3X(false, false, function(ep)
								batchLockParts(ep, { desc }, true)
							end)
						end)
					elseif prop == "Size" and CRITICAL_CHAR_PART_NAMES[desc.Name] then
						local origSz = Runtime.charPartBaselineSizes[desc]
						if origSz and math.max(desc.Size.X, desc.Size.Y, desc.Size.Z) > 9 then
							task.spawn(function()
								withF3X(false, true, function(ep)
									beginSelfRestoring()
									pcall(function()
										ep:InvokeServer("SyncResize", { { Part = desc, Size = origSz, CFrame = desc.CFrame } })
									end)
									endSelfRestoring()
								end)
								Engine.logEvent("Reverted char resize on " .. desc.Name, "SHIELD")
							end)
						end
					elseif prop == "Anchored" and desc == hrp and desc.Anchored == true then
						if hum and hum.MoveDirection.Magnitude > 0.05 and not hum.SeatPart then
							desc.Anchored = false
							task.spawn(function()
								withF3X(false, true, function(ep)
									beginSelfRestoring()
									pcall(function()
										ep:InvokeServer("SyncAnchor", { { Part = hrp, Anchored = false } })
									end)
									endSelfRestoring()
								end)
								Engine.logEvent("Unfroze anchored HRP", "SHIELD")
							end)
						end
					end
				end))
			end
		end

		local function watchBackpackForLock(c)
			if not c then return end
			table.insert(Runtime.charWatchConns, c.ChildAdded:Connect(function(child)
				if not agAlive then return end
				if child:FindFirstChild("SyncAPI") or child:FindFirstChild("SyncApi") then
					Runtime.cachedEndpoint = nil
					Runtime.cachedTool = nil
					if agState.autoLockSelf then
						task.delay(0.15, function()
							if agAlive and LocalPlayer.Character == char then
								withF3X(false, false, function(ep)
									Engine.lockSelfCharacterParts(ep, true)
								end)
							end
						end)
					end
				end
			end))
		end
		watchBackpackForLock(char)
		watchBackpackForLock(LocalPlayer:FindFirstChild("Backpack"))

		if agState.autoLockSelf then
			task.spawn(function()
				for _ = 1, 15 do
					if not agAlive or LocalPlayer.Character ~= char then return end
					local ep = getF3XEndpoint(false)
					if ep then
						Engine.lockSelfCharacterParts(ep, true)
						return
					end
					task.wait(0.3)
				end
			end)
		end
	end

	if LocalPlayer.Character then
		watchOwnCharacter(LocalPlayer.Character)
	end

	trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
		if not agAlive then return end
		agState.f3xRequestedThisLife = false
		Runtime.cachedEndpoint = nil
		Runtime.cachedTool = nil
		markRigDeployGrace(2.5)
		watchOwnCharacter(char)

		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if not hrp or not agAlive then return end

		if agState.antiVoid and not getActiveSnapshot() then
			task.wait(0.35)
			if not agAlive then return end
			local ep = getF3XEndpoint(true)
			if ep and hrp.Position.Y < -20 then
				createFallbackBaseplate(ep, hrp.Position)
			end
		end
	end))

	-- ========================================================================
	-- WORKSPACE & PLAYER MONITORING
	-- ========================================================================
	local function isImmediateDangerPart(part)
		if not (part and part:IsA("BasePart") and part.Parent) then return false end
		local sz = part.Size
		local maxAxis = math.max(sz.X, sz.Y, sz.Z)
		if maxAxis >= AG_CONFIG.GiantSizeThreshold then return true end
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = (part.Position - hrp.Position).Magnitude
			if (part:IsA("Seat") or part:IsA("VehicleSeat")) and dist <= AG_CONFIG.TrapCheckRadius then
				return true
			end
			if dist <= 16 and part.CanCollide and part.Position.Y <= 10000 then
				return true
			end
			if not part.Anchored and dist <= 22 and part.AssemblyLinearVelocity.Magnitude > 28 then
				return true
			end
		end
		return false
	end

	local function handleForeignSpawnCheck(desc)
		if not agAlive or not desc or not desc.Parent then return end
		if Runtime.selfRestoringDepth > 0 or Runtime.scriptManagedParts[desc] or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end
		if isProtectedWorldSystem(desc) or isVerifiedForeignUKPart(desc) then return end

		local isForeignPart = desc:IsA("BasePart")
		local snap = getActiveSnapshot()

		if isForeignPart and not isPlayerCharacterDescendant(desc) and (not snap or not snap.parts[desc]) then
			table.insert(Runtime.recentForeignBuffer, { t = os.clock(), part = desc })
			local rate, burst = getFloodBurstAndPrune()
			if agState.autoClean and getFilterMode() ~= "Effects Only" and rate >= AG_CONFIG.FloodRateThreshold then
				if not isWhitelistedPlayerNearby(desc.Position, 32) then
					for _, bEntry in ipairs(burst) do
						local bp = bEntry.part
						if bp and bp.Parent ~= nil and not Runtime.pendingRemove[bp]
							and (not snap or not snap.parts[bp])
							and not isOwnRigPart(bp)
							and not isVerifiedForeignUKPart(bp) then
							if not isWhitelistedPlayerNearby(bp.Position, 32) then
								quarantineInstanceLocally(bp)
								Runtime.pendingRemove[bp] = true
							end
						end
					end
					attributeThreat(desc.Position, 3, "Part Flood")
				end
			end
		end

		if not agState.autoClean then return end

		if isSpamEffect(desc) then
			quarantineInstanceLocally(desc)
			Runtime.pendingRemove[desc] = true
			local pPart = desc:IsA("BasePart") and desc or desc:FindFirstAncestorWhichIsA("BasePart")
			attributeThreat(pPart and pPart.Position, 1, desc.ClassName)
		elseif getFilterMode() ~= "Effects Only" and isForeignPart then
			local bad, reason = isSuspiciousPart(desc, getFilterMode() == "Strict Lockdown")
			if bad then
				quarantineInstanceLocally(desc)
				Runtime.pendingRemove[desc] = true
				attributeThreat(desc.Position, (reason == "Seat Trap" or reason == "Oversized Block") and 4 or 2, reason)
			end
		end
	end

	trackConn(workspace.DescendantAdded:Connect(function(desc)
		if not agAlive then return end

		if isRigDeployGraceActive() then
			if not isProtectedWorldSystem(desc) and not isPlayerCharacterDescendant(desc) then
				Runtime.protectedRigInstances[desc] = true
			end
			return
		end

		if Runtime.selfRestoringDepth > 0 or Runtime.scriptManagedParts[desc] or isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) then return end
		if isProtectedWorldSystem(desc) then return end

		-- Aguarda janela curta de replicacao para SetName/SyncCollision de outros usuarios ULTRAKILL, exceto ameacas imediatas
		if agState.trustOtherUKRigs and not isVerifiedForeignUKPart(desc) then
			local shouldDefer = false
			if desc:IsA("BasePart") then
				if not isPlayerCharacterDescendant(desc) and not isImmediateDangerPart(desc) then
					shouldDefer = true
				end
			elseif FOREIGN_UK_ALLOWED_CHILD_CLASSES[desc.ClassName] then
				local parentPart = desc:FindFirstAncestorWhichIsA("BasePart")
				if parentPart and not isPlayerCharacterDescendant(parentPart) then
					shouldDefer = true
				end
			end

			if shouldDefer then
				task.delay(AG_CONFIG.ForeignUKVerifyGrace, function()
					if agAlive and desc and desc.Parent and not isVerifiedForeignUKPart(desc) then
						handleForeignSpawnCheck(desc)
					end
				end)
				return
			end
		end

		handleForeignSpawnCheck(desc)
	end))

	trackConn(workspace.DescendantRemoving:Connect(function(desc)
		if not agAlive or not agState.liveGuard or Runtime.selfRestoringDepth > 0 or isRigDeployGraceActive() then return end
		if isOwnRigPart(desc) or isOwnCoreCharacterHelper(desc) or isVerifiedForeignUKPart(desc) then return end
		local snap = getActiveSnapshot()
		if not snap then return end
		if snap.parts[desc] then
			Runtime.pendingDeleted[desc] = true
			attributeThreat(desc.Position, 2, "Map Deletion")
		elseif (snap.containers and snap.containers[desc]) or (snap.joints and snap.joints[desc]) or (snap.effects and snap.effects[desc]) or (snap.meshes and snap.meshes[desc]) then
			for part in pairs(snap.parts) do
				if part and (part == desc or part:IsDescendantOf(desc) or not part:IsDescendantOf(workspace)) then
					Runtime.pendingDeleted[part] = true
				end
			end
			attributeThreat(nil, 4, "Container/Joint Delete")
		end
	end))

	local function hookPlayerTools(plr)
		if plr.Character then
			registerCharacter(plr, plr.Character)
		end

		local function watchContainer(c)
			if not c then return end
			trackConn(c.ChildAdded:Connect(function(child)
				if not agAlive then return end
				if child:FindFirstChild("SyncAPI") or child:FindFirstChild("SyncApi") then
					if plr ~= LocalPlayer then
						Engine.logEvent(plr.Name .. " equipped/received F3X", "WARN")
					else
						Runtime.cachedEndpoint = nil
						Runtime.cachedTool = nil
					end
					if UI.refreshRadar and agState.windowOpen then task.defer(UI.refreshRadar) end
				end
			end))
		end

		watchContainer(plr:FindFirstChild("Backpack"))
		if plr.Character then watchContainer(plr.Character) end

		trackConn(plr.ChildAdded:Connect(function(child)
			if not agAlive then return end
			if child:IsA("Backpack") or child.Name == "Backpack" then
				watchContainer(child)
			end
		end))

		trackConn(plr.CharacterAdded:Connect(function(char)
			if not agAlive then return end
			registerCharacter(plr, char)
			watchContainer(char)
			if UI.refreshRadar and agState.windowOpen then task.defer(UI.refreshRadar) end
		end))

		trackConn(plr.CharacterRemoving:Connect(function()
			registerCharacter(plr, nil)
		end))
	end

	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayerTools(p)
	end
	trackConn(Players.PlayerAdded:Connect(function(p)
		if not agAlive then return end
		hookPlayerTools(p)
		if UI.refreshRadar and agState.windowOpen then task.defer(UI.refreshRadar) end
	end))
	trackConn(Players.PlayerRemoving:Connect(function(p)
		registerCharacter(p, nil)
		Runtime.cagedPartsByUserId[p.UserId] = nil
		Runtime.foreignUKPartsByUid[p.UserId] = nil
		agState.threatScores[p.UserId] = nil
		agState.lastCounterTime[p.UserId] = nil
		if UI.refreshRadar and agState.windowOpen then task.defer(UI.refreshRadar) end
	end))

	-- Tamper cyclic sweep
	task.spawn(function()
		while agAlive do
			if agState.liveGuard and not agState.isBusy and not Runtime.restoreInFlight and Runtime.selfRestoringDepth == 0 and not isRigDeployGraceActive() then
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
									Runtime.pendingDeleted[part] = true
								elseif cframeDiffers(part.CFrame, data.CFrame)
									or sizeDiffers(part.Size, data.Size)
									or colorDiffers(part.Color, data.Color)
									or part.Material ~= data.Material
									or math.abs(part.Transparency - data.Transparency) > 0.01
									or math.abs(part.Reflectance - data.Reflectance) > 0.01
									or part.Anchored ~= data.Anchored
									or part.CanCollide ~= data.CanCollide
									or (not part.Locked and (data.Locked or agState.autoLockAfterRestore)) then
									Runtime.pendingTampered[part] = true
								end
							end
						end
					end
				end
			end
			task.wait(AG_CONFIG.TamperInterval)
		end
	end)

	-- Live Guard worker coroutine
	task.spawn(function()
		while agAlive do
			if not agState.isBusy and not Runtime.restoreInFlight then
				local hasCharUndo = agState.charShield and next(Runtime.pendingCharUndo) ~= nil
				local hasRemove = (agState.autoClean or agState.charShield) and next(Runtime.pendingRemove) ~= nil
				local hasGuardWork = agState.liveGuard and (next(Runtime.pendingDeleted) ~= nil or next(Runtime.pendingTampered) ~= nil)

				if not agState.autoClean and not agState.charShield and next(Runtime.pendingRemove) ~= nil then
					table.clear(Runtime.pendingRemove)
				end

				if hasCharUndo or hasRemove or hasGuardWork then
					withF3X(false, true, function(ep)
						if hasCharUndo then
							local undoList = {}
							for inst in pairs(Runtime.pendingCharUndo) do
								Runtime.pendingCharUndo[inst] = nil
								if typeof(inst) == "Instance" then
									table.insert(undoList, inst)
								end
							end
							if #undoList > 0 then
								beginSelfRestoring()
								batchInvoke(ep, "UndoRemove", undoList, AG_CONFIG.BatchSize)
								endSelfRestoring()
								agState.threatsBlocked += #undoList
								Engine.logEvent("Recovered " .. #undoList .. " char part/joint(s)", "SHIELD")
								if UI.updateTelemetry then UI.updateTelemetry() end
							end
						end

						if hasRemove then
							local batch = {}
							for inst in pairs(Runtime.pendingRemove) do
								Runtime.pendingRemove[inst] = nil
								if inst and inst.Parent ~= nil and not isOwnRigPart(inst) and not isOwnCoreCharacterHelper(inst) and not isVerifiedForeignUKPart(inst) then
									table.insert(batch, inst)
								end
							end
							if #batch > 0 then
								local removed = batchRemove(ep, batch)
								if removed > 0 then
									agState.threatsBlocked += removed
									Engine.logEvent("Auto-blocked " .. removed .. " spam item(s)", "BLOCK")
									if UI.updateTelemetry then UI.updateTelemetry() end
								end
							end
						end

						if hasGuardWork then
							local snap = getActiveSnapshot()
							if snap then
								beginSelfRestoring()
								local deletedList = {}
								for p in pairs(Runtime.pendingDeleted) do
									Runtime.pendingDeleted[p] = nil
									if p and (p.Parent == nil or not p:IsDescendantOf(workspace)) then
										table.insert(deletedList, p)
									end
								end

								local needsFullRebuild = false
								if #deletedList > 0 then
									batchInvoke(ep, "UndoRemove", deletedList, AG_CONFIG.BatchSize)
									for _, inst in ipairs(deletedList) do
										if inst:IsA("BasePart") and snap.parts[inst] and (inst.Parent == nil or not inst:IsDescendantOf(workspace)) then
											needsFullRebuild = true
											break
										end
									end
									if needsFullRebuild then
										task.spawn(function()
											Engine.restoreMap(ep)
										end)
									else
										agState.restoresPerformed += 1
										agState.threatsBlocked += #deletedList
										Engine.logEvent("Guard undid " .. #deletedList .. " deletion(s)", "RESTORE")
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
									if #reanchorList > 0 then batchInvoke(ep, "SyncAnchor", reanchorList) end
									runParallel(5, 5, function(stepIdx)
										if stepIdx == 1 and #moveList > 0 then batchInvoke(ep, "SyncMove", moveList)
										elseif stepIdx == 2 and #resizeList > 0 then batchInvoke(ep, "SyncResize", resizeList)
										elseif stepIdx == 3 and #colorList > 0 then batchInvoke(ep, "SyncColor", colorList)
										elseif stepIdx == 4 and #matList > 0 then batchInvoke(ep, "SyncMaterial", matList)
										elseif stepIdx == 5 and #colList > 0 then batchInvoke(ep, "SyncCollision", colList) end
									end)
									if #lockList > 0 then
										batchLockParts(ep, lockList, true)
									end
									agState.restoresPerformed += 1
									agState.threatsBlocked += fixedCount
									Engine.logEvent("Guard reverted " .. fixedCount .. " tampered part(s)", "RESTORE")
								end
								endSelfRestoring()
								if UI.updateTelemetry then UI.updateTelemetry() end
							else
								table.clear(Runtime.pendingDeleted)
								table.clear(Runtime.pendingTampered)
							end
						end
					end)
				end
			end
			task.wait(AG_CONFIG.WorkerInterval)
		end
	end)

	local flingOverlapParams = OverlapParams.new()
	flingOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

	trackConn(RunService.Heartbeat:Connect(function()
		if not agAlive then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end

		if hum.FloorMaterial ~= Enum.Material.Air and hrp.Position.Y > AG_CONFIG.VoidThresholdY + 20 and hrp.AssemblyLinearVelocity.Magnitude < 55 then
			agState.lastSafeCFrame = hrp.CFrame
		end

		if agState.antiFling then
			local highSpeedSelf = isCoreHighSpeedAction() or isRigDeployGraceActive()
			local triggered = false
			local now = os.clock()

			if not highSpeedSelf then
				local vel = hrp.AssemblyLinearVelocity
				local rot = hrp.AssemblyAngularVelocity
				triggered = (vel.Magnitude > AG_CONFIG.FlingVelocityThreshold or rot.Magnitude > 55)
				if triggered then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					if agState.lastSafeCFrame and vel.Magnitude > 260 then
						hrp.CFrame = agState.lastSafeCFrame + Vector3.new(0, 2, 0)
					end
					agState.threatsBlocked += 1
				end
			end

			if triggered or (now - Runtime.lastFlingSweep >= 0.12) then
				Runtime.lastFlingSweep = now
				local snap = getActiveSnapshot()
				flingOverlapParams.FilterDescendantsInstances = { char }
				local okSpatial, nearby = pcall(function()
					return workspace:GetPartBoundsInRadius(hrp.Position, 24, flingOverlapParams)
				end)
				if okSpatial and nearby then
					for _, desc in ipairs(nearby) do
						if desc:IsA("BasePart") and not desc.Anchored and not isOwnRigPart(desc) and not isOwnCoreCharacterHelper(desc) and not Runtime.scriptManagedParts[desc] and not isVerifiedForeignUKPart(desc) then
							local isChar, pOwner = isPlayerCharacterDescendant(desc)
							if isChar and pOwner and pOwner ~= LocalPlayer and not agState.whitelist[pOwner.UserId] then
								if desc.AssemblyLinearVelocity.Magnitude > 85 or desc.AssemblyAngularVelocity.Magnitude > 35 then
									desc.AssemblyLinearVelocity = Vector3.zero
									desc.AssemblyAngularVelocity = Vector3.zero
									desc.CanCollide = false
									attributeThreat(desc.Position, 2, "FLING_BODY")
								end
							elseif not isChar and (not snap or not snap.parts[desc]) then
								if desc.AssemblyLinearVelocity.Magnitude > 22 or desc.AssemblyAngularVelocity.Magnitude > 15 or triggered then
									desc.CanCollide = false
									if agState.autoClean then
										Runtime.pendingRemove[desc] = true
									end
								end
							end
						end
					end
				end
			end
		end

		if agState.antiVoid and hrp.Position.Y < AG_CONFIG.VoidThresholdY then
			withF3X(false, true, function(ep)
				Engine.rescueCharacter(ep)
			end)
		end
	end))

	-- ========================================================================
	-- SMILEOS 2.0 CHROME ANTI-GRIEF WINDOW (MATCHES LOADER.LUA)
	-- ========================================================================
	local AG_FULL_W, AG_FULL_H = 356, 412
	local AG_COLLAPSED_H = 30
	local AG_FULL_SIZE = UDim2.fromOffset(AG_FULL_W, AG_FULL_H)
	local AG_COLLAPSED_SIZE = UDim2.fromOffset(AG_FULL_W, 0)
	local AG_MIN_SIZE = UDim2.fromOffset(AG_FULL_W, AG_COLLAPSED_H)

	local function computeWindowScale()
		local vp = getScreenSize(ScreenGui)
		local isCompact = UserInputService.TouchEnabled or vp.X < 760 or vp.Y < 540
		local fitScale = math.min((vp.X - 24) / AG_FULL_W, (vp.Y - 24) / AG_FULL_H)
		if isCompact then
			return math.clamp(fitScale, 0.48, 0.80)
		end
		return math.clamp(fitScale, 0.65, 1.0)
	end

	local initScale = computeWindowScale()
	local initVp = getScreenSize(ScreenGui)

	local AGWindow = Instance.new("Frame")
	AGWindow.Name = "AntiGriefWindow"
	AGWindow.Size = createdOwnGui and AG_FULL_SIZE or AG_COLLAPSED_SIZE
	AGWindow.Position = createdOwnGui
		and UDim2.fromOffset(
			math.max(0, math.floor((initVp.X - AG_FULL_W * initScale) * 0.5)),
			math.max(0, math.floor((initVp.Y - AG_FULL_H * initScale) * 0.5))
		)
		or UDim2.fromOffset(math.max(0, math.floor(initVp.X * 0.5 + 160)), math.max(0, math.floor((initVp.Y - AG_FULL_H * initScale) * 0.5)))
	AGWindow.BackgroundColor3 = SMILE.WinFace
	AGWindow.BorderSizePixel = 0
	AGWindow.Active = true
	AGWindow.Visible = createdOwnGui
	AGWindow.ClipsDescendants = true
	AGWindow.ZIndex = 2
	AGWindow.Parent = ScreenGui

	local AGScale = Instance.new("UIScale")
	AGScale.Scale = initScale
	AGScale.Parent = AGWindow

	createBevel(AGWindow, false, 2)
	addOutline(AGWindow, SMILE.BorderOuter, 1)

	trackConn(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if not agAlive or not AGScale or not AGScale.Parent then return end
		AGScale.Scale = computeWindowScale()
		task.defer(function()
			if agAlive and AGWindow and AGWindow.Parent and AGWindow.Visible then
				clampWindowToScreen(AGWindow, ScreenGui)
			end
		end)
	end))

	-- Title Bar (XP-style SmileOS 2.0 Crimson Gradient + Pixel Smiley)
	local AGTitleBar = Instance.new("Frame")
	AGTitleBar.Name = "TitleBar"
	AGTitleBar.Size = UDim2.new(1, -4, 0, 26)
	AGTitleBar.Position = UDim2.fromOffset(2, 2)
	AGTitleBar.BackgroundColor3 = SMILE.HeaderTop
	AGTitleBar.BorderSizePixel = 0
	AGTitleBar.Active = true
	AGTitleBar.ZIndex = 3
	AGTitleBar.Parent = AGWindow

	local titleGrad = Instance.new("UIGradient")
	titleGrad.Rotation = 90
	titleGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(224, 58, 58)),
		ColorSequenceKeypoint.new(0.18, SMILE.HeaderTop),
		ColorSequenceKeypoint.new(1, SMILE.HeaderBot),
	})
	titleGrad.Parent = AGTitleBar

	createSmileyIcon(AGTitleBar, 18, UDim2.fromOffset(5, 4), SMILE.InsetLight, SMILE.TextDark)

	local AGTitleText = Instance.new("TextLabel")
	AGTitleText.Size = UDim2.new(1, -92, 1, 0)
	AGTitleText.Position = UDim2.fromOffset(28, 0)
	AGTitleText.BackgroundTransparency = 1
	AGTitleText.Font = Enum.Font.GothamBold
	AGTitleText.TextSize = 12
	AGTitleText.TextColor3 = SMILE.TextLight
	AGTitleText.TextStrokeTransparency = 0.65
	AGTitleText.TextStrokeColor3 = Color3.new(0, 0, 0)
	AGTitleText.TextXAlignment = Enum.TextXAlignment.Left
	AGTitleText.TextTruncate = Enum.TextTruncate.AtEnd
	AGTitleText.Text = "SmileOS 2.0  -  ANTI-GRIEF.SYS"
	AGTitleText.ZIndex = 4
	AGTitleText.Parent = AGTitleBar

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
		btn.Parent = AGTitleBar
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

	local AGMinBtn = makeCaptionButton("_", -54, false)
	local AGCloseBtn = makeCaptionButton("X", -27, true)

	makeDraggable(AGTitleBar, AGWindow)

	-- Body Container
	local AGBody = Instance.new("Frame")
	AGBody.Name = "Body"
	AGBody.Size = UDim2.new(1, -8, 1, -60)
	AGBody.Position = UDim2.fromOffset(4, 30)
	AGBody.BackgroundTransparency = 1
	AGBody.ZIndex = 2
	AGBody.Parent = AGWindow

	-- Recessed CRT Telemetry Header Well
	local AGTelemetryBox = Instance.new("Frame")
	AGTelemetryBox.Size = UDim2.new(1, -8, 0, 22)
	AGTelemetryBox.Position = UDim2.fromOffset(4, 4)
	AGTelemetryBox.BackgroundColor3 = SMILE.InsetDark
	AGTelemetryBox.BorderSizePixel = 0
	AGTelemetryBox.ZIndex = 3
	AGTelemetryBox.Parent = AGBody
	createBevel(AGTelemetryBox, true, 2)

	local AGTelemetry = Instance.new("TextLabel")
	AGTelemetry.Size = UDim2.new(1, -10, 1, 0)
	AGTelemetry.Position = UDim2.fromOffset(6, 0)
	AGTelemetry.BackgroundTransparency = 1
	AGTelemetry.Font = Enum.Font.Code
	AGTelemetry.TextSize = 11
	AGTelemetry.TextColor3 = SMILE.AccentGold
	AGTelemetry.TextXAlignment = Enum.TextXAlignment.Left
	AGTelemetry.TextTruncate = Enum.TextTruncate.AtEnd
	AGTelemetry.Text = "S1: EMPTY | BLK:0 | SMART"
	AGTelemetry.ZIndex = 4
	AGTelemetry.Parent = AGTelemetryBox

	-- Beveled OS Tab Strip
	local AGTabBar = Instance.new("Frame")
	AGTabBar.Size = UDim2.new(1, -8, 0, 26)
	AGTabBar.Position = UDim2.fromOffset(4, 30)
	AGTabBar.BackgroundTransparency = 1
	AGTabBar.ZIndex = 3
	AGTabBar.Parent = AGBody

	local AGTabLayout = Instance.new("UIListLayout")
	AGTabLayout.FillDirection = Enum.FillDirection.Horizontal
	AGTabLayout.Padding = UDim.new(0, 4)
	AGTabLayout.Parent = AGTabBar

	-- Recessed CRT Pages Well (Matches LogBox / InfoWindow)
	local AGPagesHolder = Instance.new("Frame")
	AGPagesHolder.Size = UDim2.new(1, -8, 1, -64)
	AGPagesHolder.Position = UDim2.fromOffset(4, 60)
	AGPagesHolder.BackgroundColor3 = SMILE.InsetDark
	AGPagesHolder.BorderSizePixel = 0
	AGPagesHolder.ZIndex = 3
	AGPagesHolder.Parent = AGBody
	createBevel(AGPagesHolder, true, 2)

	-- Bottom SmileOS 2.0 Taskbar
	local AGTaskbar = Instance.new("Frame")
	AGTaskbar.Name = "Taskbar"
	AGTaskbar.Size = UDim2.new(1, -4, 0, 26)
	AGTaskbar.Position = UDim2.new(0, 2, 1, -28)
	AGTaskbar.BackgroundColor3 = SMILE.TaskbarBg
	AGTaskbar.BorderSizePixel = 0
	AGTaskbar.ZIndex = 5
	AGTaskbar.Parent = AGWindow
	createBevel(AGTaskbar, false, 1)

	local TaskSysPill = Instance.new("Frame")
	TaskSysPill.Size = UDim2.fromOffset(88, 20)
	TaskSysPill.Position = UDim2.fromOffset(3, 3)
	TaskSysPill.BackgroundColor3 = SMILE.WinFaceAlt
	TaskSysPill.BorderSizePixel = 0
	TaskSysPill.ZIndex = 6
	TaskSysPill.Parent = AGTaskbar
	createBevel(TaskSysPill, true, 1)

	local TaskSysLabel = Instance.new("TextLabel")
	TaskSysLabel.Size = UDim2.new(1, -8, 1, 0)
	TaskSysLabel.Position = UDim2.fromOffset(4, 0)
	TaskSysLabel.BackgroundTransparency = 1
	TaskSysLabel.Font = Enum.Font.Code
	TaskSysLabel.TextSize = 10
	TaskSysLabel.TextColor3 = SMILE.TextDark
	TaskSysLabel.Text = "SENTINEL.SYS"
	TaskSysLabel.ZIndex = 7
	TaskSysLabel.Parent = TaskSysPill

	local AGStatus = Instance.new("TextLabel")
	AGStatus.Size = UDim2.new(1, -162, 0, 20)
	AGStatus.Position = UDim2.fromOffset(96, 3)
	AGStatus.BackgroundTransparency = 1
	AGStatus.Font = Enum.Font.Code
	AGStatus.TextSize = 10
	AGStatus.TextColor3 = SMILE.TextMutedDark
	AGStatus.TextXAlignment = Enum.TextXAlignment.Left
	AGStatus.TextTruncate = Enum.TextTruncate.AtEnd
	AGStatus.Text = "STATUS: STANDBY"
	AGStatus.ZIndex = 6
	AGStatus.Parent = AGTaskbar

	local F3XTray = Instance.new("Frame")
	F3XTray.Size = UDim2.fromOffset(58, 20)
	F3XTray.Position = UDim2.new(1, -61, 0, 3)
	F3XTray.BackgroundColor3 = SMILE.InsetDark
	F3XTray.BorderSizePixel = 0
	F3XTray.ZIndex = 6
	F3XTray.Parent = AGTaskbar
	createBevel(F3XTray, true, 1)

	local AGF3XBadge = Instance.new("TextLabel")
	AGF3XBadge.Size = UDim2.fromScale(1, 1)
	AGF3XBadge.BackgroundTransparency = 1
	AGF3XBadge.Font = Enum.Font.Code
	AGF3XBadge.TextSize = 10
	AGF3XBadge.TextColor3 = SMILE.AccentRed
	AGF3XBadge.Text = "NO F3X"
	AGF3XBadge.ZIndex = 7
	AGF3XBadge.Parent = F3XTray

	local agPages = {}
	local agTabBtns = {}

	local function selectAGTab(name)
		for k, p in pairs(agPages) do
			local active = (k == name)
			p.Visible = active
			local tb = agTabBtns[k]
			tb.bevel.setPressed(active)
			tb.btn.BackgroundColor3 = active and SMILE.BtnPressedRed or SMILE.BtnFace
			tb.lbl.TextColor3 = active and SMILE.TextLight or SMILE.TextDark
		end
	end

	local function createAGTab(name, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.25, -3, 1, 0)
		btn.BackgroundColor3 = SMILE.BtnFace
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 4
		btn.Parent = AGTabBar
		local bev = createBevel(btn, false, 2)
		addOutline(btn, SMILE.BevelMid, 1)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextColor3 = SMILE.TextDark
		lbl.Text = name
		lbl.ZIndex = 6
		lbl.Parent = btn

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, -10, 1, -10)
		page.Position = UDim2.fromOffset(5, 5)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 4
		page.ScrollBarImageColor3 = SMILE.WinFace
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.ZIndex = 4
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
		agTabBtns[name] = { btn = btn, lbl = lbl, bevel = bev }

		btn.MouseEnter:Connect(function()
			if not page.Visible then
				TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnHover }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if not page.Visible then
				TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnFace }):Play()
			end
		end)
		btn.Activated:Connect(function()
			selectAGTab(name)
			if name == "RADAR" and UI.refreshRadar then
				UI.refreshRadar()
			end
		end)

		return page
	end

	local function makeAGButton(parent, text, isPrimary, stripeColor, order, height)
		local baseCol = isPrimary and SMILE.BtnPressedRed or SMILE.BtnFace
		local hoverCol = isPrimary and Color3.fromRGB(205, 40, 40) or SMILE.BtnHover
		local txtCol = isPrimary and SMILE.TextLight or SMILE.TextDark

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, height or 28)
		btn.BackgroundColor3 = baseCol
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 5
		btn.Parent = parent

		local bev = createBevel(btn, false, 2)
		addOutline(btn, SMILE.BorderOuter, 1)

		if stripeColor then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 4, 1, -6)
			bar.Position = UDim2.fromOffset(4, 3)
			bar.BackgroundColor3 = stripeColor
			bar.BorderSizePixel = 0
			bar.ZIndex = 7
			bar.Parent = btn
		end

		local inner = Instance.new("TextLabel")
		inner.Size = UDim2.new(1, stripeColor and -12 or 0, 1, 0)
		inner.Position = UDim2.fromOffset(stripeColor and 8 or 0, 0)
		inner.BackgroundTransparency = 1
		inner.Font = Enum.Font.GothamBold
		inner.TextSize = 11
		inner.TextColor3 = txtCol
		inner.Text = text
		inner.ZIndex = 7
		inner.Parent = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = hoverCol }):Play()
		end)
		btn.MouseLeave:Connect(function()
			bev.setPressed(false)
			inner.Position = UDim2.fromOffset(stripeColor and 8 or 0, 0)
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = baseCol }):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			bev.setPressed(true)
			inner.Position = UDim2.fromOffset((stripeColor and 8 or 0) + 1, 1)
		end)
		btn.MouseButton1Up:Connect(function()
			bev.setPressed(false)
			inner.Position = UDim2.fromOffset(stripeColor and 8 or 0, 0)
		end)

		return btn, inner
	end

	local function makeAGToggle(parent, label, initial, order, onToggle)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 27)
		btn.BackgroundColor3 = SMILE.BtnFace
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.LayoutOrder = order
		btn.ZIndex = 5
		btn.Parent = parent
		local bev = createBevel(btn, false, 2)
		addOutline(btn, SMILE.BorderOuter, 1)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -58, 1, 0)
		lbl.Position = UDim2.fromOffset(8, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextColor3 = SMILE.TextDark
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Text = label
		lbl.ZIndex = 7
		lbl.Parent = btn

		local pill = Instance.new("Frame")
		pill.Size = UDim2.fromOffset(42, 17)
		pill.Position = UDim2.new(1, -48, 0.5, -8)
		pill.BackgroundColor3 = SMILE.InsetDark
		pill.BorderSizePixel = 0
		pill.ZIndex = 7
		pill.Parent = btn
		createBevel(pill, true, 1)

		local pillTxt = Instance.new("TextLabel")
		pillTxt.Size = UDim2.fromScale(1, 1)
		pillTxt.BackgroundTransparency = 1
		pillTxt.Font = Enum.Font.Code
		pillTxt.TextSize = 10
		pillTxt.Text = initial and "ON" or "OFF"
		pillTxt.TextColor3 = initial and SMILE.SuccessGreen or SMILE.TextMutedLight
		pillTxt.ZIndex = 8
		pillTxt.Parent = pill

		local current = initial
		local function setVisual(v)
			current = v
			pillTxt.Text = v and "ON" or "OFF"
			pillTxt.TextColor3 = v and SMILE.SuccessGreen or SMILE.TextMutedLight
		end

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnHover }):Play()
		end)
		btn.MouseLeave:Connect(function()
			bev.setPressed(false)
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = SMILE.BtnFace }):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			bev.setPressed(true)
		end)
		btn.MouseButton1Up:Connect(function()
			bev.setPressed(false)
		end)
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

	local setLiveGuardVisual
	local function setLiveGuard(on)
		agState.liveGuard = on == true
		if agState.liveGuard then
			if not getActiveSnapshot() then
				local count = Engine.takeSnapshot(agState.activeSlot)
				if UI.updateStatus then
					UI.updateStatus("Auto-snapshotted " .. count .. " parts", Color3.fromRGB(28, 128, 44))
				end
			else
				syncPartWatchersToActiveSlot()
			end
			Engine.logEvent("Live Guard ENABLED", "INFO")
		else
			clearPartWatchers()
			table.clear(Runtime.pendingDeleted)
			table.clear(Runtime.pendingTampered)
			Engine.logEvent("Live Guard DISABLED", "INFO")
		end
		if setLiveGuardVisual then
			setLiveGuardVisual(agState.liveGuard)
		end
		if UI.updateTelemetry then
			UI.updateTelemetry()
		end
	end

	--// SHIELD TAB
	local PanicBtn = makeAGButton(agShieldPage, "PANIC: PURGE + RESTORE MAP", true, SMILE.AccentGold, 1, 32)
	PanicBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		UI.updateStatus("Running panic recovery...", SMILE.HeaderBot)
		local resOk, resErr = withF3X(true, true, function(ep)
			local purged = Engine.purgeSpam(ep, true)
			local resMsg = Engine.restoreMap(ep)
			UI.updateStatus("Panic: -" .. purged .. " | " .. resMsg, Color3.fromRGB(28, 128, 44))
			return true
		end)
		if not resOk then
			UI.updateStatus("F3X error: " .. tostring(resErr), SMILE.AccentRed)
		end
		agState.isBusy = false
	end)

	_, setLiveGuardVisual = makeAGToggle(agShieldPage, "Live Anti-Grief Guard", agState.liveGuard, 2, function(on)
		setLiveGuard(on)
	end)

	makeAGToggle(agShieldPage, "Auto-Clean Spam Queue", agState.autoClean, 3, function(on)
		agState.autoClean = on
		Engine.logEvent("Auto-Clean " .. (on and "ENABLED" or "DISABLED"), "INFO")
	end)

	makeAGToggle(agShieldPage, "Trust Other ULTRAKILL Rigs", agState.trustOtherUKRigs, 4, function(on)
		agState.trustOtherUKRigs = on
		Engine.logEvent("Other UK Rigs " .. (on and "TRUSTED" or "BLOCKED"), "INFO")
		if agState.windowOpen and UI.refreshRadar then
			UI.refreshRadar()
		end
	end)

	makeAGToggle(agShieldPage, "Local Anti-Lag / Quarantine", agState.localQuarantine, 5, function(on)
		agState.localQuarantine = on
	end)

	local ModeBtn, ModeLbl = makeAGButton(agShieldPage, "FILTER: " .. getFilterMode():upper(), false, SMILE.InfoBlue, 6, 28)
	ModeBtn.Activated:Connect(function()
		agState.filterModeIndex = (agState.filterModeIndex % #FILTER_MODES) + 1
		local mode = getFilterMode()
		ModeLbl.Text = "FILTER: " .. mode:upper()
		Engine.logEvent("Filter -> " .. mode, "INFO")
		UI.updateTelemetry()
	end)

	makeAGToggle(agShieldPage, "Char + Joint + Seat Shield", agState.charShield, 7, function(on)
		agState.charShield = on
	end)

	makeAGToggle(agShieldPage, "Auto-Lock Self on Spawn", agState.autoLockSelf, 8, function(on)
		agState.autoLockSelf = on
		if on then
			task.spawn(function()
				withF3X(false, false, function(ep)
					Engine.lockSelfCharacterParts(ep, true)
				end)
			end)
		end
	end)

	makeAGToggle(agShieldPage, "Anti-Fling & Velocity Clamp", agState.antiFling, 9, function(on)
		agState.antiFling = on
	end)

	makeAGToggle(agShieldPage, "Anti-Void + Smart Rescue", agState.antiVoid, 10, function(on)
		agState.antiVoid = on
	end)

	makeAGToggle(agShieldPage, "Auto-Equip F3X on Action", agState.autoEquipF3X, 11, function(on)
		agState.autoEquipF3X = on
	end)

	makeAGToggle(agShieldPage, "Auto-Counter Repeat Griefers", agState.autoCounter, 12, function(on)
		agState.autoCounter = on
		Engine.logEvent("Auto-Counter " .. (on and "ARMED" or "OFF"), on and "COUNTER" or "INFO")
	end)

	local LockSelfRow = Instance.new("Frame")
	LockSelfRow.Size = UDim2.new(1, 0, 0, 28)
	LockSelfRow.BackgroundTransparency = 1
	LockSelfRow.LayoutOrder = 13
	LockSelfRow.ZIndex = 4
	LockSelfRow.Parent = agShieldPage

	local LockSelfBtn = makeAGButton(LockSelfRow, "LOCK SELF", false, SMILE.AccentGold, 1, 28)
	LockSelfBtn.Size = UDim2.new(0.5, -2, 1, 0)
	LockSelfBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local res, err = withF3X(true, false, function(ep)
			return Engine.lockSelfCharacterParts(ep, true)
		end)
		UI.updateStatus(res or err, res and Color3.fromRGB(28, 128, 44) or SMILE.AccentRed)
		agState.isBusy = false
	end)

	local ClearMeBtn = makeAGButton(LockSelfRow, "CLEAR 45 STUDS", false, SMILE.AccentRed, 2, 28)
	ClearMeBtn.Size = UDim2.new(0.5, -2, 1, 0)
	ClearMeBtn.Position = UDim2.new(0.5, 4, 0, 0)
	ClearMeBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local _, msg = withF3X(true, true, function(ep)
				local _, m = Engine.clearAroundPosition(ep, hrp.Position, AG_CONFIG.ClearRadius)
				return m
			end)
			UI.updateStatus(msg or "F3X missing", Color3.fromRGB(28, 128, 44))
		else
			UI.updateStatus("Need character", SMILE.AccentRed)
		end
		agState.isBusy = false
	end)

	local PadBtn = makeAGButton(agShieldPage, "SPAWN RESCUE BASEPLATE", false, SMILE.BevelDark, 14, 28)
	PadBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local ok = withF3X(true, true, function(ep)
				return createFallbackBaseplate(ep, hrp.Position)
			end)
			if ok then
				UI.updateStatus("Spawned 256x256 rescue pad", Color3.fromRGB(28, 128, 44))
				Engine.logEvent("Spawned rescue baseplate", "INFO")
			else
				UI.updateStatus("Failed: F3X missing", SMILE.AccentRed)
			end
		else
			UI.updateStatus("Failed: Root missing", SMILE.AccentRed)
		end
		agState.isBusy = false
	end)

	--// MAP TAB
	local SlotRow = Instance.new("Frame")
	SlotRow.Size = UDim2.new(1, 0, 0, 28)
	SlotRow.BackgroundTransparency = 1
	SlotRow.LayoutOrder = 1
	SlotRow.ZIndex = 4
	SlotRow.Parent = agMapPage

	local SlotLayout = Instance.new("UIListLayout")
	SlotLayout.FillDirection = Enum.FillDirection.Horizontal
	SlotLayout.Padding = UDim.new(0, 4)
	SlotLayout.Parent = SlotRow

	local slotButtons = {}
	function UI.refreshSlotButtons()
		for i = 1, 3 do
			local snap = agState.snapshots[i]
			local b = slotButtons[i]
			local active = (i == agState.activeSlot)
			b.bevel.setPressed(active)
			b.btn.BackgroundColor3 = active and SMILE.BtnPressedRed or SMILE.BtnFace
			b.lbl.TextColor3 = active and SMILE.TextLight or SMILE.TextDark
			b.lbl.Text = snap and ("S" .. i .. ":" .. snap.count) or ("SLOT " .. i)
		end
	end

	for i = 1, 3 do
		local sb = Instance.new("TextButton")
		sb.Size = UDim2.new(0.333, -3, 1, 0)
		sb.BackgroundColor3 = SMILE.BtnFace
		sb.BorderSizePixel = 0
		sb.Text = ""
		sb.AutoButtonColor = false
		sb.ZIndex = 5
		sb.Parent = SlotRow
		local bev = createBevel(sb, false, 2)
		addOutline(sb, SMILE.BorderOuter, 1)

		local slbl = Instance.new("TextLabel")
		slbl.Size = UDim2.fromScale(1, 1)
		slbl.BackgroundTransparency = 1
		slbl.Font = Enum.Font.GothamBold
		slbl.TextSize = 11
		slbl.TextColor3 = SMILE.TextDark
		slbl.Text = "SLOT " .. i
		slbl.ZIndex = 7
		slbl.Parent = sb

		slotButtons[i] = { btn = sb, lbl = slbl, bevel = bev }
		sb.Activated:Connect(function()
			agState.activeSlot = i
			syncPartWatchersToActiveSlot()
			UI.refreshSlotButtons()
			UI.updateTelemetry()
			UI.updateStatus("Selected Snapshot Slot " .. i, SMILE.TextDark)
		end)
	end
	UI.refreshSlotButtons()

	local SnapBtn = makeAGButton(agMapPage, "TAKE / OVERWRITE SNAPSHOT", false, SMILE.InfoBlue, 2, 28)
	SnapBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local count = Engine.takeSnapshot(agState.activeSlot)
		UI.updateStatus("Saved " .. count .. " parts to S" .. agState.activeSlot, Color3.fromRGB(28, 128, 44))
		agState.isBusy = false
	end)

	local AdoptBtn = makeAGButton(agMapPage, "ADOPT NEW PARTS INTO SNAP", false, SMILE.AccentGold, 3, 28)
	AdoptBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local pAdded, eAdded = Engine.adoptNewPartsIntoSnapshot()
		UI.updateStatus("Adopted +" .. pAdded .. "p / +" .. eAdded .. "fx", Color3.fromRGB(28, 128, 44))
		agState.isBusy = false
	end)

	local DiffBtn = makeAGButton(agMapPage, "SCAN MAP INTEGRITY (DIFF)", false, SMILE.BevelDark, 4, 28)
	DiffBtn.Activated:Connect(function()
		local snap = getActiveSnapshot()
		if not snap then
			UI.updateStatus("No snapshot in active slot", SMILE.AccentRed)
			return
		end
		local d = computeMapDiff(snap)
		local msg = ("Del:%d Mov:%d Sz:%d Anc:%d Foreign:%d Fx:%d"):format(
			#d.deleted, #d.moved, #d.resized, #d.reanchored, #d.foreignParts, #d.foreignEffects
		)
		UI.updateStatus(msg, SMILE.HeaderBot)
		Engine.logEvent("Scan -> " .. msg, "INFO")
	end)

	local RestoreBtn = makeAGButton(agMapPage, "SMART RESTORE MAP", true, SMILE.SuccessGreen, 5, 30)
	RestoreBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		UI.updateStatus("Restoring snapshot...", SMILE.HeaderBot)
		local msg, err = withF3X(true, true, function(ep)
			return Engine.restoreMap(ep)
		end)
		UI.updateStatus(msg or err, msg and Color3.fromRGB(28, 128, 44) or SMILE.AccentRed)
		agState.isBusy = false
	end)

	local PurgeBtn = makeAGButton(agMapPage, "PURGE FOREIGN PARTS & FX", false, SMILE.AccentRed, 6, 28)
	PurgeBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local _, msg = withF3X(true, true, function(ep)
			local _, m = Engine.purgeSpam(ep, true)
			return m
		end)
		UI.updateStatus(msg or "F3X missing", SMILE.HeaderBot)
		agState.isBusy = false
	end)

	local LockRow = Instance.new("Frame")
	LockRow.Size = UDim2.new(1, 0, 0, 28)
	LockRow.BackgroundTransparency = 1
	LockRow.LayoutOrder = 7
	LockRow.ZIndex = 4
	LockRow.Parent = agMapPage

	local LockBtn = makeAGButton(LockRow, "LOCK MAP", false, SMILE.AccentGold, 1, 28)
	LockBtn.Size = UDim2.new(0.5, -2, 1, 0)
	LockBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local msg, err = withF3X(true, false, function(ep)
			return Engine.lockMap(ep, true)
		end)
		UI.updateStatus(msg or err, SMILE.HeaderBot)
		agState.isBusy = false
	end)

	local UnlockBtn = makeAGButton(LockRow, "UNLOCK MAP", false, SMILE.BevelMid, 2, 28)
	UnlockBtn.Size = UDim2.new(0.5, -2, 1, 0)
	UnlockBtn.Position = UDim2.new(0.5, 4, 0, 0)
	UnlockBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local msg, err = withF3X(true, false, function(ep)
			return Engine.lockMap(ep, false)
		end)
		UI.updateStatus(msg or err, SMILE.TextDark)
		agState.isBusy = false
	end)

	makeAGToggle(agMapPage, "Auto-Lock On Tamper / Restore", agState.autoLockAfterRestore, 8, function(on)
		agState.autoLockAfterRestore = on
	end)

	local CleanManagedBtn = makeAGButton(agMapPage, "CLEAR PADS & CAGES", false, SMILE.BevelMid, 9, 28)
	CleanManagedBtn.Activated:Connect(function()
		if agState.isBusy then return end
		agState.isBusy = true
		local removed = withF3X(true, true, function(ep)
			return Engine.destroyManagedArtifacts(ep)
		end)
		UI.updateStatus("Removed " .. tostring(removed or 0) .. " sentinel objects", SMILE.TextDark)
		agState.isBusy = false
	end)

	--// RADAR TAB
	local RadarActionRow = Instance.new("Frame")
	RadarActionRow.Size = UDim2.new(1, 0, 0, 28)
	RadarActionRow.BackgroundTransparency = 1
	RadarActionRow.LayoutOrder = 1
	RadarActionRow.ZIndex = 4
	RadarActionRow.Parent = agRadarPage

	local RefreshRadarBtn = makeAGButton(RadarActionRow, "REFRESH RADAR", false, SMILE.InfoBlue, 1, 28)
	RefreshRadarBtn.Size = UDim2.new(0.55, -2, 1, 0)

	local ResetThreatsBtn = makeAGButton(RadarActionRow, "RESET THREATS", false, SMILE.BevelMid, 2, 28)
	ResetThreatsBtn.Size = UDim2.new(0.45, -2, 1, 0)
	ResetThreatsBtn.Position = UDim2.new(0.55, 4, 0, 0)

	local radarCards = {}

	function UI.refreshRadar()
		for _, card in ipairs(radarCards) do
			if card and card.Parent then card:Destroy() end
		end
		table.clear(radarCards)

		local entries = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local hasF3X, equipped = playerHasF3X(plr)
				local hasUK = hasActiveForeignUKParts(plr.UserId)
				local score = agState.threatScores[plr.UserId] or 0
				local priority = (agState.blacklist[plr.UserId] and 10000 or 0)
					+ (score * 10)
					+ (equipped and 500 or (hasF3X and 100 or 0))
					+ (hasUK and 50 or 0)
				table.insert(entries, {
					plr = plr,
					hasF3X = hasF3X,
					equipped = equipped,
					hasUK = hasUK,
					score = score,
					priority = priority,
				})
			end
		end

		table.sort(entries, function(a, b)
			if a.priority ~= b.priority then
				return a.priority > b.priority
			end
			return a.plr.Name:lower() < b.plr.Name:lower()
		end)

		local order = 2
		for _, entry in ipairs(entries) do
			local plr = entry.plr
			local hasF3X, equipped, hasUK, score = entry.hasF3X, entry.equipped, entry.hasUK, entry.score
			local isWL = agState.whitelist[plr.UserId] == true
			local isBL = agState.blacklist[plr.UserId] == true
			local isCaged = Runtime.cagedPartsByUserId[plr.UserId] ~= nil

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 74)
			card.BackgroundColor3 = SMILE.WinFaceAlt
			card.BorderSizePixel = 0
			card.LayoutOrder = order
			card.ZIndex = 5
			card.Parent = agRadarPage
			createBevel(card, false, 2)
			addOutline(card, isBL and SMILE.AccentRed or SMILE.BorderOuter, 1)
			table.insert(radarCards, card)
			order += 1

			local nameStrip = Instance.new("Frame")
			nameStrip.Size = UDim2.new(1, -6, 0, 20)
			nameStrip.Position = UDim2.fromOffset(3, 3)
			nameStrip.BackgroundColor3 = (isBL or equipped) and SMILE.HeaderBot or SMILE.InsetDark
			nameStrip.BorderSizePixel = 0
			nameStrip.ZIndex = 6
			nameStrip.Parent = card

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -8, 1, 0)
			nameLbl.Position = UDim2.fromOffset(5, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.Code
			nameLbl.TextSize = 10
			local tag = equipped and " [F3X HELD]" or (hasF3X and " [F3X]" or "")
			if hasUK then tag ..= " [UK]" end
			if score > 0 then tag ..= (" [T:%d]"):format(score) end
			if isWL then tag ..= " [WL]" end
			if isBL then tag ..= " [BL]" end
			nameLbl.Text = plr.DisplayName .. " (@" .. plr.Name .. ")" .. tag
			nameLbl.TextColor3 = (isBL or equipped) and SMILE.TextLight or (hasUK and SMILE.InfoBlue or (hasF3X and SMILE.AccentGold or SMILE.TextLight))
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.ZIndex = 7
			nameLbl.Parent = nameStrip

			local function makeMiniRow(yOffset)
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, -10, 0, 21)
				row.Position = UDim2.fromOffset(5, yOffset)
				row.BackgroundTransparency = 1
				row.ZIndex = 6
				row.Parent = card
				local lay = Instance.new("UIListLayout")
				lay.FillDirection = Enum.FillDirection.Horizontal
				lay.Padding = UDim.new(0, 4)
				lay.Parent = row
				return row
			end

			local function miniBtn(parent, widthScale, txt, isRed, col, cb)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(widthScale, -3, 1, 0)
				b.BackgroundColor3 = isRed and SMILE.BtnPressedRed or SMILE.BtnFace
				b.BorderSizePixel = 0
				b.Text = ""
				b.AutoButtonColor = false
				b.ZIndex = 7
				b.Parent = parent
				local bev = createBevel(b, false, 1)
				addOutline(b, SMILE.BorderOuter, 1)

				local l = Instance.new("TextLabel")
				l.Size = UDim2.fromScale(1, 1)
				l.BackgroundTransparency = 1
				l.Font = Enum.Font.GothamBold
				l.TextSize = 10
				l.TextColor3 = isRed and SMILE.TextLight or (col or SMILE.TextDark)
				l.Text = txt
				l.ZIndex = 9
				l.Parent = b

				b.MouseButton1Down:Connect(function() bev.setPressed(true) end)
				b.MouseButton1Up:Connect(function() bev.setPressed(false) end)
				b.MouseLeave:Connect(function() bev.setPressed(false) end)
				b.Activated:Connect(cb)
			end

			local row1 = makeMiniRow(26)
			miniBtn(row1, 0.25, isWL and "UN-WL" or "WL", false, isWL and Color3.fromRGB(28, 128, 44) or SMILE.TextDark, function()
				agState.whitelist[plr.UserId] = not agState.whitelist[plr.UserId]
				if agState.whitelist[plr.UserId] then
					agState.blacklist[plr.UserId] = nil
					agState.threatScores[plr.UserId] = 0
				end
				Engine.logEvent((agState.whitelist[plr.UserId] and "Whitelisted " or "Removed WL ") .. plr.Name, "INFO")
				UI.refreshRadar()
			end)

			miniBtn(row1, 0.25, isBL and "UN-BL" or "BL", isBL, SMILE.AccentRed, function()
				agState.blacklist[plr.UserId] = not agState.blacklist[plr.UserId]
				if agState.blacklist[plr.UserId] then
					agState.whitelist[plr.UserId] = nil
				end
				Engine.logEvent((agState.blacklist[plr.UserId] and "Blacklisted " or "Unblacklisted ") .. plr.Name, "WARN")
				UI.refreshRadar()
			end)

			miniBtn(row1, 0.25, "TP", false, SMILE.InfoBlue, function()
				local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if myHrp and tHrp then
					myHrp.AssemblyLinearVelocity = Vector3.zero
					myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 4, 4)
				end
			end)

			miniBtn(row1, 0.25, "CLR 45", false, SMILE.TextDark, function()
				if agState.isBusy then return end
				agState.isBusy = true
				local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if tHrp then
					local msg = withF3X(true, true, function(ep)
						local _, m = Engine.clearAroundPosition(ep, tHrp.Position, AG_CONFIG.ClearRadius)
						return m
					end)
					UI.updateStatus(plr.Name .. ": " .. tostring(msg), SMILE.HeaderBot)
				end
				agState.isBusy = false
			end)

			local row2 = makeMiniRow(50)
			miniBtn(row2, 0.333, isCaged and "UNCAGE" or "CAGE", not isCaged, isCaged and Color3.fromRGB(28, 128, 44) or SMILE.AccentRed, function()
				if agState.isBusy then return end
				agState.isBusy = true
				local msg, err = withF3X(true, true, function(ep)
					if Runtime.cagedPartsByUserId[plr.UserId] then
						local _, m = Engine.uncagePlayer(ep, plr)
						return m
					else
						return Engine.cagePlayer(ep, plr)
					end
				end)
				UI.updateStatus(msg or err, SMILE.HeaderBot)
				agState.isBusy = false
				UI.refreshRadar()
			end)

			miniBtn(row2, 0.333, "STRIP F3X", false, SMILE.AccentRed, function()
				if agState.isBusy then return end
				agState.isBusy = true
				local msg, err = withF3X(true, true, function(ep)
					return Engine.stripPlayerF3X(ep, plr)
				end)
				UI.updateStatus(msg or err, SMILE.HeaderBot)
				agState.isBusy = false
				UI.refreshRadar()
			end)

			miniBtn(row2, 0.333, "CLR T", false, SMILE.TextMutedDark, function()
				agState.threatScores[plr.UserId] = 0
				UI.refreshRadar()
			end)
		end
	end

	RefreshRadarBtn.Activated:Connect(UI.refreshRadar)
	ResetThreatsBtn.Activated:Connect(function()
		table.clear(agState.threatScores)
		UI.refreshRadar()
		UI.updateStatus("Cleared all threat scores", SMILE.TextDark)
	end)

	--// LOGS TAB (CRT Terminal Output matching loader.lua LogBox)
	local LogHeaderRow = Instance.new("Frame")
	LogHeaderRow.Size = UDim2.new(1, 0, 0, 28)
	LogHeaderRow.BackgroundTransparency = 1
	LogHeaderRow.LayoutOrder = 1
	LogHeaderRow.ZIndex = 4
	LogHeaderRow.Parent = agLogsPage

	local ClearLogsBtn = makeAGButton(LogHeaderRow, "CLEAR LOG", false, SMILE.BevelMid, 1, 28)
	ClearLogsBtn.Size = UDim2.new(0.5, -2, 1, 0)

	local ResetStatsBtn = makeAGButton(LogHeaderRow, "RESET COUNTERS", false, SMILE.AccentGold, 2, 28)
	ResetStatsBtn.Size = UDim2.new(0.5, -2, 1, 0)
	ResetStatsBtn.Position = UDim2.new(0.5, 4, 0, 0)

	local AGLogContainer = Instance.new("Frame")
	AGLogContainer.Size = UDim2.new(1, 0, 0, 0)
	AGLogContainer.AutomaticSize = Enum.AutomaticSize.Y
	AGLogContainer.BackgroundTransparency = 1
	AGLogContainer.LayoutOrder = 2
	AGLogContainer.ZIndex = 5
	AGLogContainer.Parent = agLogsPage

	local AGLogLayout = Instance.new("UIListLayout")
	AGLogLayout.Padding = UDim.new(0, 2)
	AGLogLayout.SortOrder = Enum.SortOrder.LayoutOrder
	AGLogLayout.Parent = AGLogContainer

	local agLogLabels = {}
	local LOG_COLORS = {
		INFO = SMILE.TextMutedLight,
		BLOCK = SMILE.AccentRed,
		RESTORE = SMILE.SuccessGreen,
		WARN = SMILE.AccentGold,
		SHIELD = SMILE.InfoBlue,
		COUNTER = SMILE.AccentRed,
	}

	function Engine.logEvent(message, level)
		local stamp = os.date("%H:%M:%S")
		local line = ("[%s] %s"):format(stamp, tostring(message))
		table.insert(Runtime.agLogs, 1, { text = line, level = level or "INFO" })
		if #Runtime.agLogs > AG_CONFIG.MaxLogEntries then
			table.remove(Runtime.agLogs)
		end

		if AGLogContainer and AGLogContainer.Parent then
			Runtime.nextLogOrder -= 1
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, 0, 0, 0)
			l.AutomaticSize = Enum.AutomaticSize.Y
			l.BackgroundTransparency = 1
			l.Text = "> " .. line
			l.TextColor3 = LOG_COLORS[level] or THEME.TextMain
			l.Font = Enum.Font.Code
			l.TextSize = 10
			l.TextWrapped = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.LayoutOrder = Runtime.nextLogOrder
			l.ZIndex = 5
			l.Parent = AGLogContainer

			table.insert(agLogLabels, 1, l)
			if #agLogLabels > AG_CONFIG.MaxLogEntries then
				local oldest = table.remove(agLogLabels)
				if oldest then oldest:Destroy() end
			end
		end
	end

	ClearLogsBtn.Activated:Connect(function()
		table.clear(Runtime.agLogs)
		for _, lbl in ipairs(agLogLabels) do lbl:Destroy() end
		table.clear(agLogLabels)
	end)

	ResetStatsBtn.Activated:Connect(function()
		agState.threatsBlocked = 0
		agState.restoresPerformed = 0
		UI.updateTelemetry()
		UI.updateStatus("Counters reset", SMILE.TextDark)
	end)

	function UI.updateTelemetry()
		local snap = getActiveSnapshot()
		local snapStr = snap and ("S" .. agState.activeSlot .. ":" .. snap.count .. "p") or ("S" .. agState.activeSlot .. ":EMPTY")
		local guardStr = agState.liveGuard and " | GUARD" or ""
		AGTelemetry.Text = ("%s | BLK:%d | %s%s"):format(snapStr, agState.threatsBlocked, getFilterMode():upper(), guardStr)
	end

	function UI.updateStatus(msg, color)
		AGStatus.Text = "STATUS: " .. tostring(msg)
		AGStatus.TextColor3 = color or SMILE.TextMutedDark
	end

	--// Smooth Open / Close / Minimize (matching loader.lua)
	local agPositionedOnce = false
	local function setAntiGriefOpen(open)
		agState.windowOpen = open == true

		if agState.windowOpen then
			AGBody.Visible = not agState.windowMinimized
			AGTaskbar.Visible = not agState.windowMinimized
			if not agPositionedOnce and MainFrame and MainFrame.Parent then
				agPositionedOnce = true
				local vp = getScreenSize(ScreenGui)
				local sc = AGScale.Scale
				local desiredX = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X + 8
				if desiredX + AG_FULL_W * sc > vp.X then
					desiredX = math.max(4, vp.X - AG_FULL_W * sc - 4)
				end
				local desiredY = math.clamp(MainFrame.AbsolutePosition.Y, 4, math.max(4, vp.Y - AG_FULL_H * sc - 4))
				AGWindow.Position = UDim2.fromOffset(desiredX, desiredY)
			end

			AGWindow.Size = AG_COLLAPSED_SIZE
			AGWindow.Visible = true
			TweenService:Create(AGWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = agState.windowMinimized and AG_MIN_SIZE or AG_FULL_SIZE,
			}):Play()

			UI.refreshRadar()
			UI.updateTelemetry()
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
		end

		if type(onStateChanged) == "function" then
			pcall(onStateChanged, agState.windowOpen)
		end
	end

	AGCloseBtn.Activated:Connect(function()
		setAntiGriefOpen(false)
	end)

	AGMinBtn.Activated:Connect(function()
		agState.windowMinimized = not agState.windowMinimized
		if not agState.windowMinimized then
			AGBody.Visible = true
			AGTaskbar.Visible = true
		end
		local tw = TweenService:Create(AGWindow, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = agState.windowMinimized and AG_MIN_SIZE or AG_FULL_SIZE,
		})
		tw.Completed:Connect(function()
			if agState.windowMinimized and AGWindow and AGWindow.Parent then
				AGBody.Visible = false
				AGTaskbar.Visible = false
			end
			if AGWindow and AGWindow.Parent then
				clampWindowToScreen(AGWindow, ScreenGui)
			end
		end)
		tw:Play()
		AGMinBtn.Text = agState.windowMinimized and "+" or "_"
	end)

	-- F3X Badge monitor
	task.spawn(function()
		while agAlive do
			local ep, tool = getF3XEndpoint(false)
			if ep then
				local inChar = LocalPlayer.Character and tool and tool:IsDescendantOf(LocalPlayer.Character)
				AGF3XBadge.Text = inChar and "F3X OK" or "IN PACK"
				AGF3XBadge.TextColor3 = inChar and SMILE.SuccessGreen or SMILE.AccentGold
			else
				AGF3XBadge.Text = "NO F3X"
				AGF3XBadge.TextColor3 = SMILE.AccentRed
			end
			task.wait(0.8)
		end
	end)

	Engine.logEvent("Sentinel Ultra subsystem online", "INFO")
	UI.updateTelemetry()

	importExistingCoreRigParts()
	if AG_CONFIG.AutoSnapshotOnInit then
		task.delay(0.4, function()
			if not agAlive or agState.snapshots[1] then return end
			importExistingCoreRigParts()
			local count = Engine.takeSnapshot(1, true)
			if count > 0 then
				Engine.logEvent("Auto-baseline S1 (" .. count .. " parts)", "INFO")
				UI.updateStatus("Auto-backed up " .. count .. "p to S1", Color3.fromRGB(28, 128, 44))
			end
		end)
	end

	if createdOwnGui then
		agState.windowOpen = true
		UI.refreshRadar()
	end

	local controller

	local function cleanup()
		agAlive = false
		agState.liveGuard = false
		if env.ULTRAKILL_ANTIGRIEF == controller then
			env.ULTRAKILL_ANTIGRIEF = nil
		end
		if _G.ULTRAKILL_ANTIGRIEF == controller then
			_G.ULTRAKILL_ANTIGRIEF = nil
		end
		clearCharWatchConns()
		clearPartWatchers()
		for _, conn in ipairs(agConnections) do
			pcall(function() conn:Disconnect() end)
		end
		table.clear(agConnections)
		table.clear(Runtime.protectedRigInstances)
		table.clear(Runtime.foreignUKPartsByUid)
		table.clear(Runtime.cagedPartsByUserId)
		table.clear(Runtime.charRootSet)
		if AGWindow and AGWindow.Parent then
			AGWindow:Destroy()
		end
		if createdOwnGui and ScreenGui and ScreenGui.Parent then
			ScreenGui:Destroy()
		end
	end

	controller = {
		toggle = function()
			setAntiGriefOpen(not agState.windowOpen)
		end,
		setOpen = setAntiGriefOpen,
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
		takeSnapshot = function(slot)
			return Engine.takeSnapshot(slot or agState.activeSlot)
		end,
		setLiveGuard = setLiveGuard,
		cleanup = cleanup,
	}

	env.ULTRAKILL_ANTIGRIEF = controller
	_G.ULTRAKILL_ANTIGRIEF = controller

	return controller
end