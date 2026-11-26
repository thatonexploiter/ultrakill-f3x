-- F3X / FORK3X ULTRAKILL CORE ENGINE (R6 + R15 | PC + MOBILE)
-- Motor completo compartilhado (F3X Sync com seq/ack, HUD 3D, Controles Mobile originais, Knockback 3 camadas & FE Ragdoll)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local C, V = CFrame.new, Vector3.new
local ID_CF = C()
local PARK_CF = C(0, 25000, 0)

local function rad(x) return math.rad(x) end
local function clamp(x, a, b) return (x < a and a) or (x > b and b) or x end
local function lerp(a, b, t) return a + (b - a) * t end
local function easeOutQuad(t) t = clamp(t, 0, 1); return 1 - (1 - t) * (1 - t) end
local function easeOutBack(t)
	t = clamp(t, 0, 1)
	local c1 = 1.70158
	return 1 + (c1 + 1) * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
end
local function angles(rx, ry, rz)
	return CFrame.Angles(rad(rx or 0), rad(ry or 0), rad(rz or 0))
end

local function mirrorRelCF(cf)
	local p = cf.Position
	local u = cf.UpVector
	local l = cf.LookVector
	local newUp = V(-u.X, u.Y, u.Z)
	local newZ = V(l.X, -l.Y, -l.Z)
	local newRight = newUp:Cross(newZ)
	if newRight.Magnitude < 1e-4 then
		return C(-p.X, p.Y, p.Z)
	end
	newRight = newRight.Unit
	newUp = newZ:Cross(newRight).Unit
	return CFrame.fromMatrix(V(-p.X, p.Y, p.Z), newRight, newUp, newZ)
end

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local o = {}
	for k, v in pairs(t) do o[k] = deepCopy(v) end
	return o
end

local function mergeTables(base, over)
	local o = deepCopy(base)
	if type(over) == "table" then
		for k, v in pairs(over) do
			if type(v) == "table" and type(o[k]) == "table" and getmetatable(v) == nil then
				o[k] = mergeTables(o[k], v)
			else
				o[k] = v
			end
		end
	end
	return o
end

local Core = {
	C = C,
	V = V,
	ID_CF = ID_CF,
	PARK_CF = PARK_CF,
	rad = rad,
	clamp = clamp,
	lerp = lerp,
	easeOutQuad = easeOutQuad,
	easeOutBack = easeOutBack,
	angles = angles,
	mirrorRelCF = mirrorRelCF,
}

local DEFAULT_CONFIG = {
	RENDER_NAME = "F3X_Ultrakill_Reanim",
	HUD_RENDER_NAME = "F3X_Ultrakill_3DHUD",
	FIRST_PERSON_HIDE_DIST = 1.95,
	HIDE_ALL_AVATAR_ACCESSORIES = true,
	SCALE = 1.0,
	SOLE_DEPTH = 3.66,

	ENABLE_SPRINT = true,
	WALK_SPEED = 16,
	SPRINT_SPEED = 32,

	ENABLE_DASH = true,
	DASH_COOLDOWN = 0.25,
	DASH_DURATION = 0.22,
	DASH_SPEED = 72,
	MAX_STAMINA = 3,
	STAMINA_REGEN_TIME = 1.25,

	ENABLE_SLIDE_SLAM = true,
	SLIDE_SPEED = 44,
	SLIDE_DURATION = 0.55,
	SLIDE_COOLDOWN = 0.55,
	SLAM_SPEED = 96,
	SLAM_MIN_HEIGHT = 6,
	SLAM_RANGE = 13.5,

	ENABLE_FOV_KICK = true,
	BASE_FOV = 70,

	YELLOW_NEON = Color3.fromRGB(255, 208, 30),
	MARKSMAN_GREEN = Color3.fromRGB(75, 255, 130),
	COIN_GOLD = Color3.fromRGB(255, 215, 45),
	BEAM_CYAN = Color3.fromRGB(115, 235, 255),
	BEAM_CORE = Color3.fromRGB(255, 255, 255),
	PARRY_FLASH = Color3.fromRGB(255, 245, 175),
	BLOOD_RED = Color3.fromRGB(185, 26, 32),

	ENABLE_HEAD_AIM_TRACKING = true,
	FOOTSTEP_SFX = true,
	ENABLE_HUD = true,

	HUD_UNIT_HEADER = "V1 // BLOOD FUEL SYSTEM",
	HUD_WEAPON_TITLE = "MARKSMAN REVOLVER",
	HUD_WEAPON_COLOR = Color3.fromRGB(75, 255, 130),
	HUD_KEY_HINT = "[Q] DASH  [C] SLAM/SLIDE  [E] COIN  [F] PARRY",
	HUD_PIP_COLOR = Color3.fromRGB(255, 215, 45),
	MOBILE_PRIMARY_LABEL = "COIN",
	MOBILE_PRIMARY_COLOR = Color3.fromRGB(255, 215, 45),
	MOBILE_SECONDARY_LABEL = "PARRY",
	MOBILE_SECONDARY_COLOR = Color3.fromRGB(255, 245, 175),
	MOBILE_TERTIARY_LABEL = "SWAP",
	MOBILE_TERTIARY_COLOR = Color3.fromRGB(255, 185, 65),

	SOUNDS = {
		PARRY     = { id = "rbxassetid://98660468032974",  fallbackId = "rbxasset://sounds/electronicpingshort.wav",   volume = 0.95, pitch = 1.00 },
		COIN_FLIP = { id = "rbxassetid://132653076390131", fallbackId = "rbxasset://sounds/electronicpingshort.wav",   volume = 0.75, pitch = 1.55 },
		SHATTER   = { id = "rbxassetid://17405655409",     fallbackId = "rbxasset://sounds/snap.mp3",                  volume = 0.80, pitch = 1.15 },
		PUNCH     = { id = "rbxassetid://140626490819228", fallbackId = "rbxasset://sounds/hit.wav",                   volume = 0.78, pitch = 1.05 },
		DASH      = { id = "rbxassetid://6870002465",      fallbackId = "rbxasset://sounds/action_jump.mp3",           volume = 0.58, pitch = 1.15 },
		LAND      = { id = "rbxassetid://6870001600",      fallbackId = "rbxasset://sounds/action_jump_land.mp3",      volume = 0.45, pitch = 1.10 },
		STEP      = { id = "rbxassetid://6870002623",      fallbackId = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 0.16, pitch = 1.65 },
	},

	MAX_CREATE_WORKERS = 18,
	MAX_IN_FLIGHT = 1,
	SEND_INTERVAL = 0.055,
	POS_EPS = 0.055,
	ROT_EPS_DEG = 2.2,
	SYNC_CHUNK = 100,
	DISABLE_FALLING_DOWN = true,
	IDLE_TILT_GUARD = true,

	ENABLE_KNOCKBACK = true,
	ENABLE_SEAT_CAPTURE = true,
	PARRY_KNOCKBACK_POWER = { speed = 68, up = 32, spin = 12.0 },
	SLAM_KNOCKBACK_POWER = { speed = 42, up = 44, spin = 11.0 },
	WALL_SLAM_ENABLED = true,

	ENABLE_DAMAGE_FLASH = true,
	DAMAGE_FLASH_PULSE_COLOR = Color3.fromRGB(255, 145, 145),
	DAMAGE_FLASH_COLOR = Color3.fromRGB(255, 30, 30),
	DAMAGE_FLASH_DURATION = 0.24,

	ENABLE_TARGET_RAGDOLL = true,
	ENABLE_FE_PROXY_RAGDOLL = true,
	RAGDOLL_DURATION = 1.75,
	RAGDOLL_GRAVITY = 94,
}

local STYLE_RANKS = {
	{ min = 0,    max = 150,  name = "D",   title = "DESTRUCTIVE", color = Color3.fromRGB(70, 175, 255) },
	{ min = 150,  max = 350,  name = "C",   title = "CHAOTIC",     color = Color3.fromRGB(75, 255, 130) },
	{ min = 350,  max = 600,  name = "B",   title = "BRUTAL",      color = Color3.fromRGB(255, 215, 45) },
	{ min = 600,  max = 950,  name = "A",   title = "ANARCHIC",    color = Color3.fromRGB(255, 140, 35) },
	{ min = 950,  max = 1350, name = "S",   title = "SUPREME",     color = Color3.fromRGB(255, 65, 65) },
	{ min = 1350, max = 1850, name = "SS",  title = "SSADISTIC",   color = Color3.fromRGB(255, 40, 110) },
	{ min = 1850, max = 2450, name = "SSS", title = "SSSHITSTORM", color = Color3.fromRGB(255, 24, 24) },
	{ min = 2450, max = 3200, name = "U",   title = "ULTRAKILL",   color = Color3.fromRGB(255, 238, 95) },
}

local STATE, CONFIG, CHAR_DEF = nil, nil, nil
local cleanup, forceRebuild, setupRig, restoreTargetRagdoll, trackTargetMove, driveTargetMove, buildTargetRayParams

local function getChar() return plr.Character end

local function getF3XEndpoint()
	local c, bp = getChar(), plr:FindFirstChild("Backpack")
	local t = (c and c:FindFirstChild("Building Tools+"))
		or (bp and bp:FindFirstChild("Building Tools+"))
		or (c and c:FindFirstChild("Building Tools"))
		or (bp and bp:FindFirstChild("Building Tools"))
	local api = t and t:FindFirstChild("SyncAPI")
	return api and api:FindFirstChild("ServerEndpoint")
end

local function f3x(ep, cmd, ...)
	if not (ep and ep.Parent) then return false, nil end
	return pcall(ep.InvokeServer, ep, cmd, ...)
end

local function invokeWithTimeout(ep, timeoutSec, cmd, ...)
	if not (ep and ep.Parent) then return false, nil end
	local args = { ... }
	local thread = coroutine.running()
	local settled = false
	local ok, res = false, nil

	local timer = task.delay(timeoutSec or 1.5, function()
		if not settled then
			settled = true
			task.spawn(thread, false, nil)
		end
	end)

	task.spawn(function()
		local callOk, callRes = pcall(ep.InvokeServer, ep, cmd, table.unpack(args))
		if not settled then
			settled = true
			pcall(task.cancel, timer)
			ok, res = callOk, callRes
			task.spawn(thread, ok, res)
		end
	end)

	return coroutine.yield()
end

local function chunked(items, size)
	if #items == 0 then return {} end
	size = math.max(1, math.floor(size or 100))
	if #items <= size then return { items } end

	local out = {}
	for i = 1, #items, size do
		local sub = {}
		for j = i, math.min(i + size - 1, #items) do
			sub[#sub + 1] = items[j]
		end
		out[#out + 1] = sub
	end
	return out
end

local function runParallelBatched(fns, maxWorkers, timeoutSec)
	local total = #fns
	if total == 0 then return end
	local workers = math.min(maxWorkers or (CONFIG and CONFIG.MAX_CREATE_WORKERS) or 18, total)
	local nextIdx, finished = 0, 0
	local thread = coroutine.running()
	local resumed = false

	local timer = task.delay(timeoutSec or 10, function()
		if not resumed then
			resumed = true
			task.spawn(thread)
		end
	end)

	for _ = 1, workers do
		task.spawn(function()
			while true do
				nextIdx += 1
				local idx = nextIdx
				if idx > total or resumed then break end
				pcall(fns[idx])
			end
			finished += 1
			if finished >= workers and not resumed then
				resumed = true
				pcall(task.cancel, timer)
				task.spawn(thread)
			end
		end)
	end

	coroutine.yield()
end

function Core.getState() return STATE end
function Core.getConfig() return CONFIG end
function Core.getChar() return getChar() end
function Core.getEndpoint() return (STATE and STATE.ep and STATE.ep.Parent and STATE.ep) or getF3XEndpoint() end
function Core.f3x(cmd, ...) return f3x(Core.getEndpoint(), cmd, ...) end

-------------------------------------------------------------------
-- TARGET TRACKER
-------------------------------------------------------------------
local function initTargetTracker()
	STATE.knownHumanoids = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Humanoid") then STATE.knownHumanoids[d] = true end
	end
	table.insert(STATE.connections, workspace.DescendantAdded:Connect(function(d)
		if STATE and STATE.alive and d:IsA("Humanoid") then STATE.knownHumanoids[d] = true end
	end))
	table.insert(STATE.connections, workspace.DescendantRemoving:Connect(function(d)
		if STATE and STATE.knownHumanoids[d] then STATE.knownHumanoids[d] = nil end
	end))
end

local function getTargetRoot(char)
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
		or char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("Head")
end

local function getActiveTargetHumanoids(myChar)
	local list = {}
	for h in pairs(STATE.knownHumanoids) do
		if h and h.Parent and h.Parent ~= myChar and h.Health > 0 then
			list[#list + 1] = h
		elseif not (h and h.Parent) then
			STATE.knownHumanoids[h] = nil
		end
	end
	return list
end

Core.getTargetRoot = getTargetRoot
Core.getActiveTargetHumanoids = getActiveTargetHumanoids

-------------------------------------------------------------------
-- SONS (COM FALLBACK NATIVO rbxasset://sounds)
-------------------------------------------------------------------
local function destroySounds()
	if not STATE then return end
	for _, s in ipairs(STATE.activeSounds) do
		pcall(function() s:Stop(); s:Destroy() end)
	end
	STATE.activeSounds = {}
	STATE.soundTemplates = {}
	if STATE.sfxFolder then
		pcall(function() STATE.sfxFolder:Destroy() end)
		STATE.sfxFolder = nil
	end
end

local function setupSounds()
	destroySounds()
	local folder = Instance.new("Folder")
	folder.Name = "F3XUltrakill_SFX"
	folder.Parent = SoundService
	STATE.sfxFolder = folder

	local toPreload = {}
	for key, cfg in pairs(CONFIG.SOUNDS) do
		local s = Instance.new("Sound")
		s.Name = "UK_" .. key
		s.SoundId = cfg.id
		s.Volume = cfg.volume
		s.PlaybackSpeed = cfg.pitch
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = 90
		s.Parent = folder
		STATE.soundTemplates[key] = s
		toPreload[#toPreload + 1] = s

		if cfg.fallbackId then
			local fb = Instance.new("Sound")
			fb.Name = "UK_" .. key .. "_FB"
			fb.SoundId = cfg.fallbackId
			fb.Volume = cfg.volume * 0.9
			fb.PlaybackSpeed = cfg.pitch
			fb.RollOffMinDistance = 12
			fb.RollOffMaxDistance = 90
			fb.Parent = folder
			STATE.soundTemplates[key .. "_FB"] = fb
			toPreload[#toPreload + 1] = fb
		end
	end

	task.spawn(function()
		pcall(function() ContentProvider:PreloadAsync(toPreload) end)
	end)
end

local function playSFX(key, pitchOverride, volumeScale, fallbackKey)
	if not (STATE and STATE.alive and STATE.sfxFolder) then return end
	local tpl = STATE.soundTemplates[key]
	if not tpl then return end

	local chosen = tpl
	if not tpl.IsLoaded or tpl.TimeLength <= 0 then
		local fbDirect = STATE.soundTemplates[key .. "_FB"]
		local fbAlt = fallbackKey and STATE.soundTemplates[fallbackKey]
		if fbAlt and fbAlt.IsLoaded and fbAlt.TimeLength > 0 then
			chosen = fbAlt
		elseif fbDirect then
			chosen = fbDirect
		end
	end

	local snd = chosen:Clone()
	snd.Volume = chosen.Volume * (volumeScale or 1)
	snd.PlaybackSpeed = pitchOverride or chosen.PlaybackSpeed

	local parentTarget = STATE.sfxFolder
	if not SoundService.RespectFilteringEnabled then
		local c = getChar()
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if hrp then parentTarget = hrp end
	end
	snd.Parent = parentTarget
	STATE.activeSounds[#STATE.activeSounds + 1] = snd
	snd:Play()

	local conn
	conn = snd.Ended:Connect(function()
		if conn then conn:Disconnect(); conn = nil end
		pcall(function() snd:Destroy() end)
	end)
	task.delay(4, function()
		if conn then pcall(function() conn:Disconnect() end); conn = nil end
		if snd and snd.Parent then pcall(function() snd:Destroy() end) end
	end)
end

Core.playSFX = playSFX

-------------------------------------------------------------------
-- HUD 3D DE VISOR + CONTROLES MOBILE NA FORMAÇÃO ORIGINAL
-------------------------------------------------------------------
local function destroyHUD()
	if CONFIG and CONFIG.HUD_RENDER_NAME then
		pcall(function() RunService:UnbindFromRenderStep(CONFIG.HUD_RENDER_NAME) end)
	end
	pcall(function() RunService:UnbindFromRenderStep("F3X_V1_3DHUD") end)
	if STATE then
		if STATE.hud.folder then pcall(function() STATE.hud.folder:Destroy() end) end
		if STATE.hud.crossGui then pcall(function() STATE.hud.crossGui:Destroy() end) end
		if STATE.hud.mobGui then pcall(function() STATE.hud.mobGui:Destroy() end) end
	end

	local cam = workspace.CurrentCamera
	for _, fname in ipairs({ "F3XV1_3DHUD_Folder", "F3XUltrakill_3DHUD_Folder" }) do
		local f = cam and cam:FindFirstChild(fname)
		if f then pcall(function() f:Destroy() end) end
	end

	local pg = plr:FindFirstChildOfClass("PlayerGui")
	if pg then
		for _, gName in ipairs({
			"F3XV1_HUD", "F3XV1_Crosshair", "F3XV1_3DHUD_Guis", "F3XV1_3DHUD_Left", "F3XV1_3DHUD_Right", "F3XV1_MobileControls",
			"F3XUltrakill_3DHUD_Left", "F3XUltrakill_3DHUD_Right", "F3XUltrakill_Crosshair", "F3XUltrakill_MobileControls"
		}) do
			local g = pg:FindFirstChild(gName)
			if g then pcall(function() g:Destroy() end) end
		end
	end

	if STATE then
		STATE.hud.folder, STATE.hud.leftPart, STATE.hud.rightPart = nil, nil, nil
		STATE.hud.leftGui, STATE.hud.rightGui, STATE.hud.crossGui, STATE.hud.mobGui = nil, nil, nil, nil
		STATE.hud.hpFill, STATE.hud.hardDmgFill, STATE.hud.hpText, STATE.hud.speedLabel = nil, nil, nil, nil
		STATE.hud.stamBars, STATE.hud.coinPips = {}, {}
		STATE.hud.rankBadge, STATE.hud.rankTitle, STATE.hud.rankBarFill, STATE.hud.multLabel = nil, nil, nil, nil
		STATE.hud.styleFeed, STATE.hud.rightFrame, STATE.hud.hitmarker, STATE.hud.hint = nil, nil, nil, nil
		STATE.hud.wpnTitle, STATE.hud.wpnStroke, STATE.hud.keyHint = nil, nil, nil
		STATE.hud.styleFeedEntries = {}
	end
end

local function addStyleBonus(label, pts, color)
	if not (STATE and CONFIG and CONFIG.ENABLE_HUD) then return end
	local h = STATE.hud
	local gained = math.floor((pts or 100) * h.styleMult)
	h.stylePoints = clamp(h.stylePoints + gained, 0, 3200)
	h.styleMult = clamp(h.styleMult + 0.15, 1.0, 3.0)
	h.stylePop = 1.0
	h.hitmarkerUntil = os.clock() + 0.15
	table.insert(h.styleFeedEntries, 1, {
		text = "+ " .. label,
		color = color or CONFIG.YELLOW_NEON,
		expires = os.clock() + 3.4,
	})
	if #h.styleFeedEntries > 6 then table.remove(h.styleFeedEntries) end
end

Core.addStyleBonus = addStyleBonus

local function makeHUDPanelPart(folder, name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.Transparency = 1
	p.Parent = folder
	return p
end

local function addCornerBrackets(parent, color, sizePx, thick)
	for _, cfg in ipairs({
		{ UDim2.fromOffset(0, 0), UDim2.fromOffset(sizePx, thick) },
		{ UDim2.fromOffset(0, 0), UDim2.fromOffset(thick, sizePx) },
		{ UDim2.new(1, -sizePx, 0, 0), UDim2.fromOffset(sizePx, thick) },
		{ UDim2.new(1, -thick, 0, 0), UDim2.fromOffset(thick, sizePx) },
		{ UDim2.new(0, 0, 1, -thick), UDim2.fromOffset(sizePx, thick) },
		{ UDim2.new(0, 0, 1, -sizePx), UDim2.fromOffset(thick, sizePx) },
		{ UDim2.new(1, -sizePx, 1, -thick), UDim2.fromOffset(sizePx, thick) },
		{ UDim2.new(1, -thick, 1, -sizePx), UDim2.fromOffset(thick, sizePx) },
	}) do
		local bar = Instance.new("Frame")
		bar.Position = cfg[1]
		bar.Size = cfg[2]
		bar.BackgroundColor3 = color
		bar.BorderSizePixel = 0
		bar.ZIndex = 5
		bar.Parent = parent
	end
end

local function setupHUD()
	destroyHUD()
	if not CONFIG.ENABLE_HUD then return end
	local cam = workspace.CurrentCamera
	local pg = plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui", 4)
	if not (cam and pg) then return end

	local folder = Instance.new("Folder")
	folder.Name = "F3XV1_3DHUD_Folder"
	folder.Parent = cam
	STATE.hud.folder = folder

	local leftPart = makeHUDPanelPart(folder, "V1_HUD_Left", V(2.35, 1.24, 0.05))
	local rightPart = makeHUDPanelPart(folder, "V1_HUD_Right", V(2.00, 1.70, 0.05))
	STATE.hud.leftPart, STATE.hud.rightPart = leftPart, rightPart

	local leftGui = Instance.new("SurfaceGui")
	leftGui.Name = "F3XV1_3DHUD_Left"
	leftGui.Adornee = leftPart
	leftGui.Face = Enum.NormalId.Front
	leftGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	leftGui.CanvasSize = Vector2.new(640, 338)
	leftGui.AlwaysOnTop = true
	leftGui.LightInfluence = 0
	leftGui.ResetOnSpawn = false
	leftGui.Parent = pg
	STATE.hud.leftGui = leftGui

	local lFrame = Instance.new("Frame")
	lFrame.Size = UDim2.fromScale(1, 1)
	lFrame.BackgroundColor3 = Color3.fromRGB(7, 10, 15)
	lFrame.BackgroundTransparency = 0.24
	lFrame.BorderSizePixel = 0
	lFrame.Parent = leftGui

	local lStroke = Instance.new("UIStroke")
	lStroke.Color = Color3.fromRGB(165, 225, 255)
	lStroke.Thickness = 3
	lStroke.Transparency = 0.35
	lStroke.Parent = lFrame
	addCornerBrackets(lFrame, Color3.fromRGB(255, 255, 255), 26, 4)

	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, -24, 0, 26)
	hdr.Position = UDim2.fromOffset(12, 10)
	hdr.BackgroundColor3 = Color3.fromRGB(18, 28, 42)
	hdr.BackgroundTransparency = 0.2
	hdr.BorderSizePixel = 0
	hdr.Parent = lFrame

	local hdrTxt = Instance.new("TextLabel")
	hdrTxt.Size = UDim2.new(0.65, 0, 1, 0)
	hdrTxt.Position = UDim2.fromOffset(10, 0)
	hdrTxt.BackgroundTransparency = 1
	hdrTxt.Font = Enum.Font.Code
	hdrTxt.TextSize = 18
	hdrTxt.TextXAlignment = Enum.TextXAlignment.Left
	hdrTxt.TextColor3 = Color3.fromRGB(185, 225, 255)
	hdrTxt.Text = CONFIG.HUD_UNIT_HEADER
	hdrTxt.Parent = hdr

	local spdLbl = Instance.new("TextLabel")
	spdLbl.Size = UDim2.new(0.35, -10, 1, 0)
	spdLbl.Position = UDim2.new(0.65, 0, 0, 0)
	spdLbl.BackgroundTransparency = 1
	spdLbl.Font = Enum.Font.Code
	spdLbl.TextSize = 18
	spdLbl.TextXAlignment = Enum.TextXAlignment.Right
	spdLbl.TextColor3 = CONFIG.YELLOW_NEON
	spdLbl.Text = "00 u/s"
	spdLbl.Parent = hdr
	STATE.hud.speedLabel = spdLbl

	local hpBack = Instance.new("Frame")
	hpBack.Size = UDim2.new(1, -24, 0, 68)
	hpBack.Position = UDim2.fromOffset(12, 44)
	hpBack.BackgroundColor3 = Color3.fromRGB(32, 10, 12)
	hpBack.BorderSizePixel = 0
	hpBack.Parent = lFrame

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = Color3.fromRGB(255, 80, 80)
	hpStroke.Thickness = 2
	hpStroke.Transparency = 0.3
	hpStroke.Parent = hpBack

	local hardDmgFill = Instance.new("Frame")
	hardDmgFill.Size = UDim2.fromScale(1, 1)
	hardDmgFill.BackgroundColor3 = Color3.fromRGB(140, 145, 155)
	hardDmgFill.BorderSizePixel = 0
	hardDmgFill.ZIndex = 2
	hardDmgFill.Parent = hpBack
	STATE.hud.hardDmgFill = hardDmgFill

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(235, 32, 40)
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 3
	hpFill.Parent = hpBack
	STATE.hud.hpFill = hpFill

	local hpCross = Instance.new("TextLabel")
	hpCross.Size = UDim2.fromOffset(58, 68)
	hpCross.Position = UDim2.fromOffset(10, 0)
	hpCross.BackgroundTransparency = 1
	hpCross.Font = Enum.Font.GothamBlack
	hpCross.TextSize = 44
	hpCross.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpCross.Text = "+"
	hpCross.ZIndex = 4
	hpCross.Parent = hpBack

	local hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.new(1, -80, 1, 0)
	hpText.Position = UDim2.fromOffset(64, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBlack
	hpText.TextSize = 50
	hpText.TextXAlignment = Enum.TextXAlignment.Left
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextStrokeTransparency = 0.35
	hpText.Text = "100"
	hpText.ZIndex = 4
	hpText.Parent = hpBack
	STATE.hud.hpText = hpText

	local stamRow = Instance.new("Frame")
	stamRow.Size = UDim2.new(1, -24, 0, 28)
	stamRow.Position = UDim2.fromOffset(12, 120)
	stamRow.BackgroundTransparency = 1
	stamRow.Parent = lFrame

	for i = 1, CONFIG.MAX_STAMINA do
		local segBack = Instance.new("Frame")
		segBack.Size = UDim2.new(1 / CONFIG.MAX_STAMINA, -6, 1, 0)
		segBack.Position = UDim2.new((i - 1) / CONFIG.MAX_STAMINA, (i - 1) * 3, 0, 0)
		segBack.BackgroundColor3 = Color3.fromRGB(16, 30, 44)
		segBack.BorderSizePixel = 0
		segBack.Parent = stamRow

		local segStroke = Instance.new("UIStroke")
		segStroke.Color = Color3.fromRGB(70, 210, 255)
		segStroke.Thickness = 2
		segStroke.Transparency = 0.45
		segStroke.Parent = segBack

		local segFill = Instance.new("Frame")
		segFill.Size = UDim2.fromScale(1, 1)
		segFill.BackgroundColor3 = Color3.fromRGB(45, 215, 255)
		segFill.BorderSizePixel = 0
		segFill.Parent = segBack
		STATE.hud.stamBars[i] = segFill
	end

	local wpnBox = Instance.new("Frame")
	wpnBox.Size = UDim2.new(1, -24, 0, 134)
	wpnBox.Position = UDim2.fromOffset(12, 156)
	wpnBox.BackgroundColor3 = Color3.fromRGB(12, 22, 20)
	wpnBox.BackgroundTransparency = 0.2
	wpnBox.BorderSizePixel = 0
	wpnBox.Parent = lFrame

	local wpnStroke = Instance.new("UIStroke")
	wpnStroke.Color = CONFIG.HUD_WEAPON_COLOR
	wpnStroke.Thickness = 2
	wpnStroke.Transparency = 0.3
	wpnStroke.Parent = wpnBox
	STATE.hud.wpnStroke = wpnStroke

	local wpnTitle = Instance.new("TextLabel")
	wpnTitle.Size = UDim2.new(0.66, -12, 0, 34)
	wpnTitle.Position = UDim2.fromOffset(12, 6)
	wpnTitle.BackgroundTransparency = 1
	wpnTitle.Font = Enum.Font.GothamBlack
	wpnTitle.TextSize = 25
	wpnTitle.TextXAlignment = Enum.TextXAlignment.Left
	wpnTitle.TextColor3 = CONFIG.HUD_WEAPON_COLOR
	wpnTitle.Text = CONFIG.HUD_WEAPON_TITLE
	wpnTitle.Parent = wpnBox
	STATE.hud.wpnTitle = wpnTitle

	local hintLbl = Instance.new("TextLabel")
	hintLbl.Size = UDim2.new(0.34, -12, 0, 34)
	hintLbl.Position = UDim2.new(0.66, 0, 0, 6)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Font = Enum.Font.Code
	hintLbl.TextSize = 16
	hintLbl.TextXAlignment = Enum.TextXAlignment.Right
	hintLbl.TextColor3 = STATE.fpHideArms and CONFIG.BEAM_CYAN or CONFIG.HUD_WEAPON_COLOR
	hintLbl.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
	hintLbl.Parent = wpnBox
	STATE.hud.hint = hintLbl

	for i = 1, 4 do
		local coinSlot = Instance.new("Frame")
		coinSlot.Size = UDim2.new(0.25, -10, 0, 38)
		coinSlot.Position = UDim2.new((i - 1) * 0.25, 10, 0, 46)
		coinSlot.BackgroundColor3 = Color3.fromRGB(36, 32, 16)
		coinSlot.BorderSizePixel = 0
		coinSlot.Parent = wpnBox

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = CONFIG.HUD_PIP_COLOR
		cStroke.Thickness = 2
		cStroke.Transparency = 0.4
		cStroke.Parent = coinSlot

		local coinFill = Instance.new("Frame")
		coinFill.Size = UDim2.fromScale(1, 1)
		coinFill.BackgroundColor3 = CONFIG.HUD_PIP_COLOR
		coinFill.BorderSizePixel = 0
		coinFill.Parent = coinSlot
		STATE.hud.coinPips[i] = coinFill
	end

	local keyHint = Instance.new("TextLabel")
	keyHint.Size = UDim2.new(1, -20, 0, 34)
	keyHint.Position = UDim2.fromOffset(12, 92)
	keyHint.BackgroundTransparency = 1
	keyHint.Font = Enum.Font.Code
	keyHint.TextSize = 18
	keyHint.TextXAlignment = Enum.TextXAlignment.Left
	keyHint.TextColor3 = Color3.fromRGB(205, 225, 235)
	keyHint.Text = CONFIG.HUD_KEY_HINT
	keyHint.Parent = wpnBox
	STATE.hud.keyHint = keyHint

	local footerHint = Instance.new("TextLabel")
	footerHint.Size = UDim2.new(1, -24, 0, 26)
	footerHint.Position = UDim2.fromOffset(12, 298)
	footerHint.BackgroundTransparency = 1
	footerHint.Font = Enum.Font.Code
	footerHint.TextSize = 16
	footerHint.TextXAlignment = Enum.TextXAlignment.Left
	footerHint.TextColor3 = Color3.fromRGB(145, 175, 200)
	footerHint.Text = "[SHIFT] SPRINT   [F7] REBUILD   [F6] STOP"
	footerHint.Parent = lFrame

	local rightGui = Instance.new("SurfaceGui")
	rightGui.Name = "F3XV1_3DHUD_Right"
	rightGui.Adornee = rightPart
	rightGui.Face = Enum.NormalId.Front
	rightGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	rightGui.CanvasSize = Vector2.new(540, 460)
	rightGui.AlwaysOnTop = true
	rightGui.LightInfluence = 0
	rightGui.ResetOnSpawn = false
	rightGui.Parent = pg
	STATE.hud.rightGui = rightGui

	local rFrame = Instance.new("Frame")
	rFrame.Size = UDim2.fromScale(1, 1)
	rFrame.BackgroundColor3 = Color3.fromRGB(7, 10, 15)
	rFrame.BackgroundTransparency = 0.24
	rFrame.BorderSizePixel = 0
	rFrame.Parent = rightGui
	STATE.hud.rightFrame = rFrame

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(255, 255, 255)
	rStroke.Thickness = 3
	rStroke.Transparency = 0.35
	rStroke.Parent = rFrame
	addCornerBrackets(rFrame, CONFIG.YELLOW_NEON, 24, 4)

	local rankBadge = Instance.new("TextLabel")
	rankBadge.Size = UDim2.fromOffset(125, 110)
	rankBadge.Position = UDim2.fromOffset(14, 12)
	rankBadge.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
	rankBadge.BorderSizePixel = 0
	rankBadge.Font = Enum.Font.GothamBlack
	rankBadge.TextSize = 72
	rankBadge.TextColor3 = STYLE_RANKS[1].color
	rankBadge.Text = "D"
	rankBadge.Parent = rFrame
	STATE.hud.rankBadge = rankBadge

	local rbStroke = Instance.new("UIStroke")
	rbStroke.Color = STYLE_RANKS[1].color
	rbStroke.Thickness = 3
	rbStroke.Parent = rankBadge

	local rankTitle = Instance.new("TextLabel")
	rankTitle.Size = UDim2.new(1, -158, 0, 52)
	rankTitle.Position = UDim2.fromOffset(150, 14)
	rankTitle.BackgroundTransparency = 1
	rankTitle.Font = Enum.Font.GothamBlack
	rankTitle.TextSize = 34
	rankTitle.TextXAlignment = Enum.TextXAlignment.Left
	rankTitle.TextColor3 = STYLE_RANKS[1].color
	rankTitle.Text = "DESTRUCTIVE"
	rankTitle.Parent = rFrame
	STATE.hud.rankTitle = rankTitle

	local multLabel = Instance.new("TextLabel")
	multLabel.Size = UDim2.new(1, -158, 0, 32)
	multLabel.Position = UDim2.fromOffset(150, 66)
	multLabel.BackgroundTransparency = 1
	multLabel.Font = Enum.Font.Code
	multLabel.TextSize = 24
	multLabel.TextXAlignment = Enum.TextXAlignment.Left
	multLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
	multLabel.Text = "MULTIPLIER: x1.00"
	multLabel.Parent = rFrame
	STATE.hud.multLabel = multLabel

	local rankBarBack = Instance.new("Frame")
	rankBarBack.Size = UDim2.new(1, -28, 0, 16)
	rankBarBack.Position = UDim2.fromOffset(14, 134)
	rankBarBack.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	rankBarBack.BorderSizePixel = 0
	rankBarBack.Parent = rFrame

	local rankBarFill = Instance.new("Frame")
	rankBarFill.Size = UDim2.fromScale(0, 1)
	rankBarFill.BackgroundColor3 = STYLE_RANKS[1].color
	rankBarFill.BorderSizePixel = 0
	rankBarFill.Parent = rankBarBack
	STATE.hud.rankBarFill = rankBarFill

	local feed = Instance.new("TextLabel")
	feed.Size = UDim2.new(1, -28, 1, -172)
	feed.Position = UDim2.fromOffset(14, 160)
	feed.BackgroundTransparency = 1
	feed.Font = Enum.Font.GothamBold
	feed.TextSize = 26
	feed.TextYAlignment = Enum.TextYAlignment.Top
	feed.TextXAlignment = Enum.TextXAlignment.Right
	feed.RichText = true
	feed.TextWrapped = true
	feed.Text = ""
	feed.Parent = rFrame
	STATE.hud.styleFeed = feed

	local crossGui = Instance.new("ScreenGui")
	crossGui.Name = "F3XV1_Crosshair"
	crossGui.ResetOnSpawn = false
	crossGui.IgnoreGuiInset = true
	crossGui.DisplayOrder = 25
	crossGui.Parent = pg
	STATE.hud.crossGui = crossGui

	local cross = Instance.new("Frame")
	cross.Size = UDim2.fromOffset(44, 44)
	cross.Position = UDim2.new(0.5, -22, 0.5, -22)
	cross.BackgroundTransparency = 1
	cross.Parent = crossGui

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(4, 4)
	dot.Position = UDim2.new(0.5, -2, 0.5, -2)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = cross

	for _, tCfg in ipairs({
		{ UDim2.new(0.5, -12, 0.5, -1), UDim2.fromOffset(6, 2) },
		{ UDim2.new(0.5, 6, 0.5, -1),   UDim2.fromOffset(6, 2) },
		{ UDim2.new(0.5, -1, 0.5, -12), UDim2.fromOffset(2, 6) },
		{ UDim2.new(0.5, -1, 0.5, 6),   UDim2.fromOffset(2, 6) },
	}) do
		local tick = Instance.new("Frame")
		tick.Position = tCfg[1]
		tick.Size = tCfg[2]
		tick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tick.BackgroundTransparency = 0.25
		tick.BorderSizePixel = 0
		tick.Parent = cross
	end

	local hitm = Instance.new("TextLabel")
	hitm.Size = UDim2.fromOffset(36, 36)
	hitm.Position = UDim2.new(0.5, -18, 0.5, -18)
	hitm.BackgroundTransparency = 1
	hitm.Font = Enum.Font.GothamBlack
	hitm.TextSize = 26
	hitm.TextColor3 = CONFIG.YELLOW_NEON
	hitm.Text = "X"
	hitm.Visible = false
	hitm.Parent = cross
	STATE.hud.hitmarker = hitm

	RunService:BindToRenderStep(CONFIG.HUD_RENDER_NAME, Enum.RenderPriority.Camera.Value + 5, function(dt)
		local curCam = workspace.CurrentCamera
		local h = STATE and STATE.hud
		if not (STATE and STATE.alive and curCam and h.leftPart and h.rightPart) then return end

		local c = getChar()
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local look = curCam.CFrame.LookVector
		if h.prevCamLook then
			local dLook = look - h.prevCamLook
			local locD = curCam.CFrame:VectorToObjectSpace(dLook)
			h.swayYaw = clamp(lerp(h.swayYaw, -locD.X * 140, clamp(dt * 12, 0, 1)), -12, 12)
			h.swayPitch = clamp(lerp(h.swayPitch, locD.Y * 140, clamp(dt * 12, 0, 1)), -10, 10)
		end
		h.prevCamLook = look

		if hrp then
			local locV = curCam.CFrame:VectorToObjectSpace(hrp.AssemblyLinearVelocity)
			h.swayX = clamp(lerp(h.swayX, -locV.X * 0.0045, clamp(dt * 10, 0, 1)), -0.22, 0.22)
			h.swayY = clamp(lerp(h.swayY, -locV.Y * 0.0040, clamp(dt * 10, 0, 1)), -0.20, 0.20)
		end

		local vp = curCam.ViewportSize
		local aspect = (vp.Y > 0) and (vp.X / vp.Y) or 1.77
		local aspectScale = clamp(aspect / 1.45, 0.48, 1.0)
		local fovScale = math.tan(rad(curCam.FieldOfView * 0.5)) / math.tan(rad(35))
		local dist = 5.4
		local halfH = dist * math.tan(rad(curCam.FieldOfView * 0.5))
		local halfW = halfH * aspect

		local popScale = 1 + h.stylePop * 0.14
		h.leftPart.Size = V(2.35, 1.24, 0.05) * fovScale * aspectScale
		h.rightPart.Size = V(2.00 * popScale, 1.70 * popScale, 0.05) * fovScale * aspectScale

		local leftPos = V(-halfW * 0.66 + h.swayX, -halfH * 0.58 + h.swayY, -dist)
		local rightPos = V(halfW * 0.68 + h.swayX, halfH * 0.44 + h.swayY, -dist)

		h.leftPart.CFrame = curCam.CFrame * C(leftPos) * angles(8 + h.swayPitch, 180 + 18 + h.swayYaw, -2)
		h.rightPart.CFrame = curCam.CFrame * C(rightPos) * angles(-6 + h.swayPitch, 180 - 18 + h.swayYaw, 2)
	end)

	-- Controles Mobile na formação exata original
	if UIS.TouchEnabled then
		local mobGui = Instance.new("ScreenGui")
		mobGui.Name = "F3XV1_MobileControls"
		mobGui.ResetOnSpawn = false
		mobGui.IgnoreGuiInset = true
		mobGui.DisplayOrder = 25
		mobGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		mobGui.Parent = pg
		STATE.hud.mobGui = mobGui

		local function makeMobBtn(name, text, size, pos, color, onPress)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = size
			btn.Position = pos
			btn.BackgroundColor3 = Color3.fromRGB(10, 14, 20)
			btn.BackgroundTransparency = 0.25
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.Code
			btn.TextSize = 14
			btn.TextColor3 = color
			btn.Text = text
			btn.Active = true
			btn.Selectable = false
			btn.AutoButtonColor = true
			btn.Parent = mobGui

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = btn

			local st = Instance.new("UIStroke")
			st.Color = color
			st.Thickness = 1.6
			st.Transparency = 0.2
			st.Parent = btn

			btn.Activated:Connect(function()
				if STATE and STATE.alive then onPress(btn, st) end
			end)
			return btn
		end

		makeMobBtn("ParryBtn", CONFIG.MOBILE_SECONDARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -172, 1, -168), CONFIG.MOBILE_SECONDARY_COLOR, function()
			if CHAR_DEF and CHAR_DEF.onSecondary then CHAR_DEF.onSecondary(Core) end
		end)
		makeMobBtn("CoinBtn", CONFIG.MOBILE_PRIMARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -90, 1, -168), CONFIG.MOBILE_PRIMARY_COLOR, function()
			if CHAR_DEF and CHAR_DEF.onPrimary then CHAR_DEF.onPrimary(Core) end
		end)
		makeMobBtn("DashBtn", "DASH", UDim2.fromOffset(72, 54), UDim2.new(1, -172, 1, -104), CONFIG.BEAM_CYAN, function()
			Core.triggerDash()
		end)
		makeMobBtn("SlideBtn", "SLIDE", UDim2.fromOffset(72, 54), UDim2.new(1, -90, 1, -104), Color3.fromRGB(185, 225, 255), function()
			Core.triggerSlideOrSlam()
		end)
		makeMobBtn("SprintBtn", "SPRINT", UDim2.fromOffset(154, 36), UDim2.new(1, -172, 1, -214), Color3.fromRGB(160, 185, 210), function(btn, st)
			STATE.mobileSprint = not STATE.mobileSprint
			local col = STATE.mobileSprint and CONFIG.MARKSMAN_GREEN or Color3.fromRGB(160, 185, 210)
			btn.TextColor3 = col
			st.Color = col
			btn.Text = STATE.mobileSprint and "SPRINT: ON" or "SPRINT"
		end)

		if CHAR_DEF and CHAR_DEF.onTertiary then
			makeMobBtn("SwapBtn", CONFIG.MOBILE_TERTIARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -254, 1, -168), CONFIG.MOBILE_TERTIARY_COLOR, function()
				CHAR_DEF.onTertiary(Core)
			end)
		end

		makeMobBtn("ArmsBtn", "1P ARMS", UDim2.fromOffset(82, 32), UDim2.new(0.5, -132, 0, 12), CONFIG.MARKSMAN_GREEN, function(btn, st)
			STATE.fpHideArms = not STATE.fpHideArms
			local col = STATE.fpHideArms and CONFIG.BEAM_CYAN or CONFIG.MARKSMAN_GREEN
			btn.TextColor3 = col
			st.Color = col
			btn.Text = STATE.fpHideArms and "ARMS: OFF" or "1P ARMS"
			if STATE.hud.hint then
				STATE.hud.hint.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
				STATE.hud.hint.TextColor3 = col
			end
		end)
		makeMobBtn("RebuildBtn", "REBUILD", UDim2.fromOffset(82, 32), UDim2.new(0.5, -41, 0, 12), CONFIG.YELLOW_NEON, function()
			forceRebuild()
		end)
		makeMobBtn("StopBtn", "STOP", UDim2.fromOffset(72, 32), UDim2.new(0.5, 50, 0, 12), CONFIG.DAMAGE_FLASH_COLOR, function()
			cleanup()
		end)
	end
end

local function updateHUD(hum, hrp, dt, hudStatus)
	local h = STATE and STATE.hud
	if not (CONFIG.ENABLE_HUD and h and h.leftPart and h.leftPart.Parent) then return end

	if hum then
		local hp = hum.Health
		local maxHp = math.max(1, hum.MaxHealth)
		if hp < STATE.lastHealth then
			STATE.hardDamage = math.min(maxHp, math.max(STATE.hardDamage, STATE.lastHealth))
			STATE.camShake = math.max(STATE.camShake, 0.25)
		end
		STATE.lastHealth = hp
		STATE.hardDamage = math.max(hp, STATE.hardDamage - dt * 16)

		if h.hpFill and h.hardDmgFill and h.hpText then
			h.hpFill.Size = UDim2.fromScale(clamp(hp / maxHp, 0, 1), 1)
			h.hardDmgFill.Size = UDim2.fromScale(clamp(STATE.hardDamage / maxHp, 0, 1), 1)
			h.hpText.Text = tostring(math.ceil(hp))
		end
	end

	if hrp and h.speedLabel then
		local spd = math.floor(V(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude + 0.5)
		h.speedLabel.Text = string.format("%02d u/s", spd)
	end

	if STATE.dash.stamina < CONFIG.MAX_STAMINA then
		STATE.dash.stamina = math.min(CONFIG.MAX_STAMINA, STATE.dash.stamina + dt / CONFIG.STAMINA_REGEN_TIME)
	end
	for i = 1, CONFIG.MAX_STAMINA do
		local bar = h.stamBars[i]
		if bar then
			local segVal = clamp(STATE.dash.stamina - (i - 1), 0, 1)
			bar.Size = UDim2.fromScale(segVal, 1)
			bar.BackgroundColor3 = (segVal >= 0.999) and Color3.fromRGB(55, 225, 255) or Color3.fromRGB(28, 120, 175)
		end
	end

	if hudStatus then
		if h.wpnTitle and hudStatus.weaponTitle then h.wpnTitle.Text = hudStatus.weaponTitle end
		if h.wpnTitle and hudStatus.weaponColor then
			h.wpnTitle.TextColor3 = hudStatus.weaponColor
			if h.wpnStroke then h.wpnStroke.Color = hudStatus.weaponColor end
		end
		local pipFrac = clamp(hudStatus.chargeFrac or 1, 0, 1)
		local pipFull = hudStatus.pipColor or CONFIG.HUD_PIP_COLOR
		local pipDim = hudStatus.pipDimColor or Color3.fromRGB(165, 130, 32)
		for i = 1, 4 do
			local pip = h.coinPips[i]
			if pip then
				local fill = clamp((pipFrac * 4) - (i - 1), 0, 1)
				pip.Size = UDim2.fromScale(fill, 1)
				pip.BackgroundColor3 = (fill >= 0.999) and pipFull or pipDim
			end
		end
	end

	h.stylePoints = math.max(0, h.stylePoints - dt * 62)
	h.styleMult = math.max(1.0, h.styleMult - dt * 0.14)
	h.stylePop = math.max(0, h.stylePop - dt * 6.5)

	local rank = STYLE_RANKS[1]
	for _, r in ipairs(STYLE_RANKS) do
		if h.stylePoints >= r.min then rank = r end
	end
	if h.rankBadge and h.rankTitle and h.rankBarFill and h.multLabel then
		h.rankBadge.Text = rank.name
		h.rankBadge.TextColor3 = rank.color
		local stroke = h.rankBadge:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = rank.color end
		h.rankTitle.Text = rank.title
		h.rankTitle.TextColor3 = rank.color
		local pct = clamp((h.stylePoints - rank.min) / math.max(1, rank.max - rank.min), 0, 1)
		h.rankBarFill.Size = UDim2.fromScale(pct, 1)
		h.rankBarFill.BackgroundColor3 = rank.color
		h.multLabel.Text = string.format("MULTIPLIER: x%.2f", h.styleMult)
	end

	local now = os.clock()
	local lines = {}
	for i = #h.styleFeedEntries, 1, -1 do
		if now >= h.styleFeedEntries[i].expires then
			table.remove(h.styleFeedEntries, i)
		end
	end
	for _, entry in ipairs(h.styleFeedEntries) do
		local c3 = entry.color
		local hex = string.format("#%02X%02X%02X", math.floor(c3.R * 255), math.floor(c3.G * 255), math.floor(c3.B * 255))
		lines[#lines + 1] = string.format('<font color="%s">%s</font>', hex, entry.text)
	end
	if h.styleFeed then h.styleFeed.Text = table.concat(lines, "\n") end
	if h.hitmarker then h.hitmarker.Visible = now < h.hitmarkerUntil end
end

-------------------------------------------------------------------
-- HELPERS DE FÍSICA, NO-COLLISION, MESH E ACESSÓRIOS
-------------------------------------------------------------------
local function isCombatPhysicsActive(p)
	if not STATE then return nil end
	if STATE.ramBusy and STATE.ramPart and p == STATE.ramPart.part then return "ram" end
	if STATE.seatBusy and STATE.seatPart and p == STATE.seatPart.part then return "seat" end
	for _, rag in pairs(STATE.ragdollingTargets) do
		if rag.active and rag.seatDrivePart == p then return "seat" end
	end
	return nil
end

local function lockProxyPhysics(p)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.AssemblyLinearVelocity = V(0, 0, 0)
	p.AssemblyAngularVelocity = V(0, 0, 0)
end

local function addNoColPair(limb, p)
	if not (limb and limb:IsA("BasePart") and p and p:IsA("BasePart")) then return end
	local ncc = Instance.new("NoCollisionConstraint")
	ncc.Name = "F3XUK_NoCol"
	ncc.Part0 = limb
	ncc.Part1 = p
	ncc.Parent = p
	STATE.noColConstraints[#STATE.noColConstraints + 1] = ncc
end

local function attachNoColToCharacter(p, c, allowTouch)
	if c then
		for _, limb in ipairs(c:GetDescendants()) do
			if limb:IsA("BasePart") then addNoColPair(limb, p) end
		end
	end
	table.insert(STATE.proxyConnections, p:GetPropertyChangedSignal("CanCollide"):Connect(function()
		if isCombatPhysicsActive(p) == "ram" then return end
		if p.CanCollide then p.CanCollide = false end
	end))
	table.insert(STATE.proxyConnections, p:GetPropertyChangedSignal("Anchored"):Connect(function()
		if isCombatPhysicsActive(p) then return end
		if not p.Anchored then p.Anchored = true end
	end))
	if allowTouch then p.CanTouch = true end
end

local function clearProxyConnections()
	if not STATE then return end
	for _, conn in ipairs(STATE.proxyConnections) do pcall(function() conn:Disconnect() end) end
	STATE.proxyConnections = {}
end

local function clearCharConnections()
	if not STATE then return end
	for _, conn in ipairs(STATE.charConnections) do pcall(function() conn:Disconnect() end) end
	STATE.charConnections = {}
end

local BODYPART_BY_LIMB = {
	["Torso"] = Enum.BodyPart.Torso, ["Left Arm"] = Enum.BodyPart.LeftArm, ["Right Arm"] = Enum.BodyPart.RightArm,
	["Left Leg"] = Enum.BodyPart.LeftLeg, ["Right Leg"] = Enum.BodyPart.RightLeg,
}

local R15_TO_R6_LIMB = {
	["Head"] = "Head", ["UpperTorso"] = "Torso", ["LowerTorso"] = "Torso",
	["LeftUpperArm"] = "Left Arm", ["LeftLowerArm"] = "Left Arm", ["LeftHand"] = "Left Arm",
	["RightUpperArm"] = "Right Arm", ["RightLowerArm"] = "Right Arm", ["RightHand"] = "Right Arm",
	["LeftUpperLeg"] = "Left Leg", ["LeftLowerLeg"] = "Left Leg", ["LeftFoot"] = "Left Leg",
	["RightUpperLeg"] = "Right Leg", ["RightLowerLeg"] = "Right Leg", ["RightFoot"] = "Right Leg",
}

local function getMeshSpecForPart(realPart, c, limbName)
	local sm = realPart:FindFirstChildOfClass("SpecialMesh")
	if sm then
		return { MeshType = sm.MeshType, MeshId = sm.MeshId, TextureId = sm.TextureId, Scale = sm.Scale, Offset = sm.Offset, VertexColor = sm.VertexColor }
	end
	if realPart:IsA("MeshPart") and realPart.MeshId ~= "" then
		local ms = realPart.MeshSize
		return {
			MeshType = Enum.MeshType.FileMesh, MeshId = realPart.MeshId, TextureId = realPart.TextureID, Offset = V(0, 0, 0),
			Scale = V(ms.X > 0.001 and realPart.Size.X / ms.X or 1, ms.Y > 0.001 and realPart.Size.Y / ms.Y or 1, ms.Z > 0.001 and realPart.Size.Z / ms.Z or 1),
		}
	end
	if c and limbName and BODYPART_BY_LIMB[limbName] then
		local targetBP = BODYPART_BY_LIMB[limbName]
		for _, child in ipairs(c:GetChildren()) do
			if child:IsA("CharacterMesh") and child.BodyPart == targetBP and child.MeshId ~= 0 then
				return {
					MeshType = Enum.MeshType.FileMesh, MeshId = "rbxassetid://" .. tostring(child.MeshId),
					TextureId = (child.BaseTextureId ~= 0) and ("rbxassetid://" .. tostring(child.BaseTextureId)) or "",
					Scale = V(1, 1, 1), Offset = V(0, 0, 0),
				}
			end
		end
	end
	return nil
end

local function getAccessoryAttachment(handle, c, rigType, keepExactPartName)
	local attachedPart = nil
	for _, d in ipairs(handle:GetChildren()) do
		if d:IsA("Weld") or d:IsA("WeldConstraint") then
			local other = (d.Part0 == handle) and d.Part1 or ((d.Part1 == handle) and d.Part0 or nil)
			if other and other:IsA("BasePart") and other.Parent == c then attachedPart = other; break end
		end
	end
	if not attachedPart then
		local hAtt = handle:FindFirstChildOfClass("Attachment")
		if hAtt then
			for _, p in ipairs(c:GetChildren()) do
				if p:IsA("BasePart") and p:FindFirstChild(hAtt.Name) then attachedPart = p; break end
			end
		end
	end
	attachedPart = attachedPart or c:FindFirstChild("Head")
	if keepExactPartName then
		return (attachedPart and attachedPart.Name or "Head"), (attachedPart and attachedPart.CFrame:ToObjectSpace(handle.CFrame) or ID_CF)
	end
	local r6Name = attachedPart and (rigType == "R15" and (R15_TO_R6_LIMB[attachedPart.Name] or "Head") or attachedPart.Name) or "Head"
	return r6Name, (attachedPart and attachedPart.CFrame:ToObjectSpace(handle.CFrame) or ID_CF)
end

-------------------------------------------------------------------
-- FX VISUAIS, HITSTOP, DAMAGE FLASH, KNOCKBACK & FE PROXY RAGDOLL
-------------------------------------------------------------------
local function syncPartMaterial(items)
	local ep = Core.getEndpoint()
	if not ep or #items == 0 then return end
	task.spawn(function() f3x(ep, "SyncMaterial", items) end)
end
Core.syncPartMaterial = syncPartMaterial

local function syncPartColor(items)
	local ep = Core.getEndpoint()
	if not ep or #items == 0 then return end
	task.spawn(function() f3x(ep, "SyncColor", items) end)
end
Core.syncPartColor = syncPartColor

local function spawnFlash(pos, color, startSize, endSize, duration)
	local fp = STATE and STATE.flashPart
	if not (fp and fp.part and fp.part.Parent) then return end
	local fa = STATE.flashAnim
	fa.active, fa.startTime, fa.duration = true, os.clock(), duration or 0.22
	fa.startSize, fa.endSize, fa.pos = startSize or 0.8, endSize or 3.2, pos

	local cf = C(pos)
	fp.targetCF, fp.part.CFrame = cf, cf
	fp.part.Size = V(fa.startSize, fa.startSize, fa.startSize)
	fp.part.Color = color or CONFIG.PARRY_FLASH

	local ep = Core.getEndpoint()
	if ep then
		task.spawn(function()
			f3x(ep, "SyncColor", { { Part = fp.part, Color = fp.part.Color, UnionColoring = true } })
			f3x(ep, "SyncMaterial", { { Part = fp.part, Transparency = 0.05 } })
		end)
	end
end
Core.spawnFlash = spawnFlash

local function spawnShockwaveRing(pos, normalOrUp, color, startR, endR, duration)
	local rp = STATE and STATE.ringPart
	if not (rp and rp.part and rp.part.Parent) then return end

	local n = (normalOrUp and normalOrUp.Magnitude > 0.05) and normalOrUp.Unit or V(0, 1, 0)
	local lookRef = (math.abs(n.Y) > 0.95) and V(0, 0, -1) or V(0, 1, 0)
	local rightAxis = n:Cross(lookRef).Unit
	local backAxis = rightAxis:Cross(n).Unit
	local ringCF = CFrame.fromMatrix(pos, n, rightAxis, backAxis)

	local ra = STATE.ringAnim
	ra.active, ra.startTime, ra.duration = true, os.clock(), duration or 0.28
	ra.startRadius, ra.endRadius, ra.cf = startR or 0.9, endR or 7.0, ringCF

	rp.targetCF, rp.part.CFrame = ra.cf, ra.cf
	rp.part.Size = V(0.16, ra.startRadius, ra.startRadius)
	rp.part.Color = color or CONFIG.BEAM_CYAN

	local ep = Core.getEndpoint()
	if ep then
		task.spawn(function()
			f3x(ep, "SyncColor", { { Part = rp.part, Color = rp.part.Color, UnionColoring = true } })
			f3x(ep, "SyncMaterial", { { Part = rp.part, Transparency = 0.1 } })
		end)
	end
end
Core.spawnShockwaveRing = spawnShockwaveRing

local function spawnRing(pos, color, startR, endR, duration)
	return spawnShockwaveRing(pos, V(0, 1, 0), color, startR, endR, duration)
end
Core.spawnRing = spawnRing

local function spawnImpactFlash(pos, color, startSize, endSize, duration)
	local ip = STATE and STATE.impactPart
	if not (ip and ip.part and ip.part.Parent) then return end

	local ia = STATE.impactAnim
	ia.active, ia.startTime, ia.duration = true, os.clock(), duration or 0.24
	ia.startSize, ia.endSize, ia.pos = startSize or 1.0, endSize or 4.6, pos

	local cf = C(pos)
	ip.targetCF, ip.part.CFrame = cf, cf
	ip.part.Size = V(ia.startSize, ia.startSize, ia.startSize)
	ip.part.Color = color or CONFIG.BEAM_CYAN

	local ep = Core.getEndpoint()
	if ep then
		task.spawn(function()
			f3x(ep, "SyncColor", { { Part = ip.part, Color = ip.part.Color, UnionColoring = true } })
			f3x(ep, "SyncMaterial", { { Part = ip.part, Transparency = 0.05 } })
		end)
	end
	spawnShockwaveRing(pos, V(0, 1, 0), color or CONFIG.BEAM_CYAN, startSize * 0.9, endSize * 1.35, duration)
end
Core.spawnImpactFlash = spawnImpactFlash

function Core.fireDualBeams(originPos, midPos, targetPos, color1, color2, w1, w2, hideBeam1, duration)
	local ep = Core.getEndpoint()
	local b1, b2 = STATE.beam1Part, STATE.beam2Part
	local bc1, bc2 = STATE.beamCore1Part, STATE.beamCore2Part
	if not (ep and b1 and b1.part and b1.part.Parent and b2 and b2.part and b2.part.Parent) then return end

	local d1 = math.max(0.2, (midPos - originPos).Magnitude)
	local d2 = math.max(0.2, (targetPos - midPos).Magnitude)
	local cf1 = C(originPos:Lerp(midPos, 0.5), midPos)
	local cf2 = C(midPos:Lerp(targetPos, 0.5), targetPos)

	local ba = STATE.beamAnim
	ba.active, ba.startTime, ba.duration = true, os.clock(), duration or 0.28
	ba.hideBeam1 = hideBeam1 == true
	ba.cf1, ba.cf2, ba.len1, ba.len2, ba.w1, ba.w2 = cf1, cf2, d1, d2, w1 or 0.24, w2 or 0.38

	b1.targetCF, b1.part.CFrame, b1.part.Size = cf1, cf1, V(ba.w1, ba.w1, d1)
	b2.targetCF, b2.part.CFrame, b2.part.Size = cf2, cf2, V(ba.w2, ba.w2, d2)
	b1.part.Transparency = ba.hideBeam1 and 1 or 0.15
	b2.part.Transparency = 0.22
	if color1 then b1.part.Color = color1 end
	if color2 then b2.part.Color = color2 end

	local resizeList = {
		{ Part = b1.part, Size = b1.part.Size, CFrame = cf1 },
		{ Part = b2.part, Size = b2.part.Size, CFrame = cf2 },
	}
	local matList = {
		{ Part = b1.part, Transparency = ba.hideBeam1 and 1 or 0.15 },
		{ Part = b2.part, Transparency = 0.22 },
	}
	local colorList = {}
	if color1 then colorList[#colorList + 1] = { Part = b1.part, Color = color1, UnionColoring = true } end
	if color2 then colorList[#colorList + 1] = { Part = b2.part, Color = color2, UnionColoring = true } end

	if bc1 and bc1.part and bc1.part.Parent then
		bc1.targetCF, bc1.part.CFrame, bc1.part.Size = cf1, cf1, V(ba.w1 * 0.42, ba.w1 * 0.42, d1)
		bc1.part.Transparency = ba.hideBeam1 and 1 or 0
		resizeList[#resizeList + 1] = { Part = bc1.part, Size = bc1.part.Size, CFrame = cf1 }
		matList[#matList + 1] = { Part = bc1.part, Transparency = ba.hideBeam1 and 1 or 0 }
	end
	if bc2 and bc2.part and bc2.part.Parent then
		bc2.targetCF, bc2.part.CFrame, bc2.part.Size = cf2, cf2, V(ba.w2 * 0.42, ba.w2 * 0.42, d2)
		bc2.part.Transparency = 0
		resizeList[#resizeList + 1] = { Part = bc2.part, Size = bc2.part.Size, CFrame = cf2 }
		matList[#matList + 1] = { Part = bc2.part, Transparency = 0 }
	end

	task.spawn(function()
		if #colorList > 0 then f3x(ep, "SyncColor", colorList) end
		f3x(ep, "SyncResize", resizeList)
		f3x(ep, "SyncMaterial", matList)
	end)
end

function Core.triggerHitstop(duration, tintColor)
	if not STATE then return end
	local dur = duration or 0.10
	STATE.hitstopDur = dur
	STATE.hitstopUntil = math.max(STATE.hitstopUntil, os.clock() + dur)
	STATE.camShake = math.max(STATE.camShake, 0.72)
	STATE.fovKick = math.max(STATE.fovKick, 9)

	if not (STATE.hitstopCC and STATE.hitstopCC.Parent) then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "F3XUltrakill_HitstopCC"
		cc.Parent = Lighting
		STATE.hitstopCC = cc
	end
	STATE.hitstopCC.Enabled = true
	STATE.hitstopCC.Brightness = 0.28
	STATE.hitstopCC.Contrast = 0.35
	STATE.hitstopCC.TintColor = tintColor or CONFIG.PARRY_FLASH
end

buildTargetRayParams = function(targetChar, rag)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	local c = getChar()
	if c then ignore[#ignore + 1] = c end
	if targetChar then ignore[#ignore + 1] = targetChar end
	for _, pp in ipairs(STATE.proxyParts) do
		if pp and pp.Parent then ignore[#ignore + 1] = pp end
	end
	if rag and rag.clones then
		for _, cl in ipairs(rag.clones) do
			if cl.part and cl.part.Parent then ignore[#ignore + 1] = cl.part end
		end
	end
	rp.FilterDescendantsInstances = ignore
	rp.IgnoreWater = true
	return rp
end

local function sampleFloorY(pos, targetChar, rp)
	local res = workspace:Raycast(pos + V(0, 3.5, 0), V(0, -65, 0), rp or buildTargetRayParams(targetChar))
	return res and res.Position.Y or (pos.Y - 3.0)
end

trackTargetMove = function(part, cf)
	if not (part and part.Parent) then return nil end
	local cur = cf or part.CFrame
	local entry = STATE.activeTargetMoves[part]
	if not entry then
		entry = { part = part, serverCF = cur, pendingCF = cur, targetCF = cur, sendSeq = 0, ackSeq = 0 }
		STATE.activeTargetMoves[part] = entry
	else
		entry.serverCF, entry.pendingCF, entry.targetCF = cur, cur, cur
	end
	return entry
end

driveTargetMove = function(part, cf, skipLocalCF)
	if not (part and part.Parent and cf) then return end
	local entry = STATE.activeTargetMoves[part] or trackTargetMove(part, part.CFrame)
	if not entry then return end
	entry.targetCF = cf
	if not skipLocalCF then part.CFrame = cf end
end

local function flashTargetDamage(targetChar, extraParts)
	if not CONFIG.ENABLE_DAMAGE_FLASH or not targetChar or not targetChar.Parent then return end
	local ep = Core.getEndpoint()
	if not ep then return end

	if not STATE.flashOriginals[targetChar] then
		local saved = {}
		for _, d in ipairs(targetChar:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 and not d.Locked then
				if d.Parent == targetChar or (d.Parent and d.Parent:IsA("Accessory")) then
					saved[#saved + 1] = { part = d, color = d.Color, mat = d.Material }
				end
			end
		end
		STATE.flashOriginals[targetChar] = saved
	end

	local token = (STATE.flashTokens[targetChar] or 0) + 1
	STATE.flashTokens[targetChar] = token

	local allTargets = {}
	for _, entry in ipairs(STATE.flashOriginals[targetChar] or {}) do allTargets[#allTargets + 1] = entry end
	for _, epItem in ipairs(extraParts or {}) do allTargets[#allTargets + 1] = epItem end
	if #allTargets == 0 then return end

	local p1Colors, p2Colors, fMats = {}, {}, {}
	for _, entry in ipairs(allTargets) do
		if entry.part and entry.part.Parent then
			p1Colors[#p1Colors + 1] = { Part = entry.part, Color = CONFIG.DAMAGE_FLASH_PULSE_COLOR, UnionColoring = true }
			p2Colors[#p2Colors + 1] = { Part = entry.part, Color = CONFIG.DAMAGE_FLASH_COLOR, UnionColoring = true }
			fMats[#fMats + 1] = { Part = entry.part, Material = Enum.Material.Neon }
		end
	end

	task.spawn(function()
		f3x(ep, "SyncColor", p1Colors)
		f3x(ep, "SyncMaterial", fMats)
		task.wait(math.min(0.08, CONFIG.DAMAGE_FLASH_DURATION * 0.35))
		if not STATE or STATE.flashTokens[targetChar] ~= token then return end
		f3x(ep, "SyncColor", p2Colors)
		task.wait(math.max(0.08, CONFIG.DAMAGE_FLASH_DURATION * 0.65))
		if not STATE or STATE.flashTokens[targetChar] ~= token then return end

		local rColors, rMats = {}, {}
		for _, entry in ipairs(allTargets) do
			if entry.part and entry.part.Parent then
				rColors[#rColors + 1] = { Part = entry.part, Color = entry.color, UnionColoring = true }
				rMats[#rMats + 1] = { Part = entry.part, Material = entry.mat }
			end
		end
		if #rColors > 0 then
			f3x(ep, "SyncColor", rColors)
			f3x(ep, "SyncMaterial", rMats)
		end
		STATE.flashOriginals[targetChar] = nil
	end)
end

local function driveTargetHRP(rag, torsoCF)
	local targetHRP = rag.hrp
	if not (targetHRP and targetHRP.Parent) then return end
	if rag.hrpDrive == "direct" or rag.hrpDrive == "syncmove" then
		local desiredHRP = torsoCF * (rag.rootRestCF and rag.rootRestCF:Inverse() or ID_CF)
		driveTargetMove(targetHRP, desiredHRP, rag.hrpDrive == "syncmove")
	elseif rag.hrpDrive == "seat" and rag.seatDrivePart and rag.seatDrivePart.Parent and rag.seatRel then
		local desiredHRP = torsoCF * (rag.rootRestCF and rag.rootRestCF:Inverse() or ID_CF)
		driveTargetMove(rag.seatDrivePart, desiredHRP * rag.seatRel:Inverse())
	end
end

local function buildTargetProxyRig(ep, targetChar, torso, upperTorso, isR15, rag)
	if not (ep and ep.Parent and targetChar and targetChar.Parent and torso) then return false end
	local origTorsoTrans = torso.Transparency
	local okProbe = f3x(ep, "SyncMaterial", { { Part = torso, Transparency = 1 } })
	if okProbe and torso.Transparency < 0.9 then task.wait(0.04) end
	if not okProbe or torso.Transparency < 0.9 then return false end

	local bodySpecs = {}
	local function addBodySpec(realPart, parentKey, role)
		if not (realPart and realPart:IsA("BasePart") and realPart.Transparency < 1) then return end
		local parentReal = (parentKey == "upper" and upperTorso) or torso
		local relCF = (realPart == torso) and ID_CF or parentReal.CFrame:ToObjectSpace(realPart.CFrame)
		bodySpecs[#bodySpecs + 1] = {
			real = realPart, parentKey = parentKey, role = role, relCF = relCF,
			size = realPart.Size, color = realPart.Color, mat = realPart.Material,
			trans = (realPart == torso) and origTorsoTrans or realPart.Transparency,
			mesh = getMeshSpecForPart(realPart, targetChar, (not isR15) and realPart.Name or nil),
		}
	end

	addBodySpec(torso, "root", "torso")
	addBodySpec(targetChar:FindFirstChild("Head"), isR15 and "upper" or "torso", "head")

	if isR15 then
		addBodySpec(upperTorso, "torso", "upper")
		addBodySpec(targetChar:FindFirstChild("LeftUpperArm"), "upper", "lArm")
		addBodySpec(targetChar:FindFirstChild("LeftLowerArm"), "lArm", "lLowerArm")
		addBodySpec(targetChar:FindFirstChild("LeftHand"), "lLowerArm", "lHand")
		addBodySpec(targetChar:FindFirstChild("RightUpperArm"), "upper", "rArm")
		addBodySpec(targetChar:FindFirstChild("RightLowerArm"), "rArm", "rLowerArm")
		addBodySpec(targetChar:FindFirstChild("RightHand"), "rLowerArm", "rHand")
		addBodySpec(targetChar:FindFirstChild("LeftUpperLeg"), "torso", "lLeg")
		addBodySpec(targetChar:FindFirstChild("LeftLowerLeg"), "lLeg", "lLowerLeg")
		addBodySpec(targetChar:FindFirstChild("LeftFoot"), "lLowerLeg", "lFoot")
		addBodySpec(targetChar:FindFirstChild("RightUpperLeg"), "torso", "rLeg")
		addBodySpec(targetChar:FindFirstChild("RightLowerLeg"), "rLeg", "rLowerLeg")
		addBodySpec(targetChar:FindFirstChild("RightFoot"), "rLowerLeg", "rFoot")
	else
		addBodySpec(targetChar:FindFirstChild("Left Arm"), "torso", "lArm")
		addBodySpec(targetChar:FindFirstChild("Right Arm"), "torso", "rArm")
		addBodySpec(targetChar:FindFirstChild("Left Leg"), "torso", "lLeg")
		addBodySpec(targetChar:FindFirstChild("Right Leg"), "torso", "rLeg")
	end

	local roleByPart = {}
	for _, sp in ipairs(bodySpecs) do roleByPart[sp.real] = sp.role end
	for _, acc in ipairs(targetChar:GetChildren()) do
		if acc:IsA("Accessory") then
			local h = acc:FindFirstChild("Handle")
			if h and h:IsA("BasePart") and h.Transparency < 1 then
				local pName, relCF = getAccessoryAttachment(h, targetChar, isR15 and "R15" or "R6", true)
				local pPart = targetChar:FindFirstChild(pName)
				local pRole = (pPart and roleByPart[pPart]) or "head"
				bodySpecs[#bodySpecs + 1] = {
					real = h, parentKey = pRole, role = "acc", relCF = relCF,
					size = h.Size, color = h.Color, mat = h.Material, trans = h.Transparency,
					mesh = getMeshSpecForPart(h, targetChar, nil),
				}
			end
		end
	end

	if #bodySpecs < 4 then
		f3x(ep, "SyncMaterial", { { Part = torso, Transparency = origTorsoTrans } })
		return false
	end

	local createFns = {}
	for _, sp in ipairs(bodySpecs) do
		createFns[#createFns + 1] = function()
			local ok, np = f3x(ep, "CreatePart", "Normal", sp.real.CFrame, workspace)
			if ok and typeof(np) == "Instance" and np:IsA("BasePart") then
				lockProxyPhysics(np)
				sp.proxy = np
			end
		end
	end
	runParallelBatched(createFns, CONFIG.MAX_CREATE_WORKERS, 8)

	if not rag.active or rag.restoring then
		local abortDel = {}
		for _, sp in ipairs(bodySpecs) do if sp.proxy and sp.proxy.Parent then abortDel[#abortDel + 1] = sp.proxy end end
		if #abortDel > 0 then f3x(ep, "Remove", abortDel) end
		f3x(ep, "SyncMaterial", { { Part = torso, Transparency = origTorsoTrans } })
		return false
	end

	local resizeQ, colorQ, matQ, anchorQ, colQ, meshCreateQ, meshSyncQ = {}, {}, {}, {}, {}, {}, {}
	local hideMatQ, hideTexQ = {}, {}
	local proxyByRole = {}

	for _, sp in ipairs(bodySpecs) do
		local np = sp.proxy
		if np and np.Parent then
			np.Size, np.Color, np.Material, np.Transparency = sp.size, sp.color, sp.mat, sp.trans
			resizeQ[#resizeQ + 1] = { Part = np, Size = sp.size, CFrame = sp.real.CFrame }
			colorQ[#colorQ + 1] = { Part = np, Color = sp.color, UnionColoring = true }
			matQ[#matQ + 1] = { Part = np, Material = sp.mat, Transparency = sp.trans }
			anchorQ[#anchorQ + 1] = { Part = np, Anchored = true }
			colQ[#colQ + 1] = { Part = np, CanCollide = false }

			if sp.mesh then
				local ms = sp.mesh
				meshCreateQ[#meshCreateQ + 1] = { Part = np }
				local mS = { Part = np, MeshType = ms.MeshType, Scale = ms.Scale, Offset = ms.Offset }
				if ms.MeshId and ms.MeshId ~= "" then mS.MeshId = ms.MeshId end
				if ms.TextureId and ms.TextureId ~= "" then mS.TextureId = ms.TextureId end
				if ms.VertexColor then mS.VertexColor = ms.VertexColor end
				meshSyncQ[#meshSyncQ + 1] = mS
			end

			rag.clones[#rag.clones + 1] = { part = np, role = sp.role, parentKey = sp.parentKey, relCF = sp.relCF, rx = 0, ry = 0, rz = 0 }
			rag.cloneFlashSaved[#rag.cloneFlashSaved + 1] = { part = np, color = sp.color, mat = sp.mat }
			if sp.role ~= "acc" then proxyByRole[sp.role] = np end
			trackTargetMove(np, sp.real.CFrame)

			rag.hiddenParts[#rag.hiddenParts + 1] = { part = sp.real, origTrans = sp.trans }
			if sp.real ~= torso then hideMatQ[#hideMatQ + 1] = { Part = sp.real, Transparency = 1 } end
			local decal = (sp.real.Name == "Head") and (sp.real:FindFirstChild("face") or sp.real:FindFirstChildOfClass("Decal")) or nil
			if decal then
				rag.hiddenDecals[#rag.hiddenDecals + 1] = { part = sp.real, decal = decal, face = decal.Face, origTrans = decal.Transparency }
				hideTexQ[#hideTexQ + 1] = { Part = sp.real, Face = decal.Face, TextureType = "Decal", Transparency = 1 }
			end
		end
	end

	rag.proxyByRole = proxyByRole
	rag.cloneTorso = proxyByRole["torso"]

	runParallelBatched({
		function() if #anchorQ > 0 then f3x(ep, "SyncAnchor", anchorQ) end end,
		function() if #colQ > 0 then f3x(ep, "SyncCollision", colQ) end end,
		function() if #resizeQ > 0 then f3x(ep, "SyncResize", resizeQ) end end,
		function() if #colorQ > 0 then f3x(ep, "SyncColor", colorQ) end end,
		function() if #matQ > 0 then f3x(ep, "SyncMaterial", matQ) end end,
		function() if #hideMatQ > 0 then f3x(ep, "SyncMaterial", hideMatQ) end end,
		function() if #hideTexQ > 0 then f3x(ep, "SyncTexture", hideTexQ) end end,
		function() if #meshCreateQ > 0 then f3x(ep, "CreateMeshes", meshCreateQ) end end,
	}, 6, 8)
	if #meshSyncQ > 0 then f3x(ep, "SyncMesh", meshSyncQ) end

	rag.mode = "clone"
	return true
end

local function triggerPhysicsRamBurst(ep, targetChar, targetHRP, flatDir, power, rag)
	local ramEntry = STATE and STATE.ramPart
	if not (ep and ep.Parent and ramEntry and ramEntry.part and ramEntry.part.Parent) then return end
	if STATE.ramBusy or not (rag and rag.active and not rag.restoring and targetHRP and targetHRP.Parent) then return end

	STATE.ramBusy = true
	local ramPart = ramEntry.part

	task.spawn(function()
		pcall(function()
			local c = getChar()
			local myHRP = c and c:FindFirstChild("HumanoidRootPart")
			local distFromMe = myHRP and (targetHRP.Position - myHRP.Position).Magnitude or 999
			local startPos = (distFromMe <= 16 and myHRP)
				and myHRP.Position:Lerp(targetHRP.Position, 0.45)
				or (targetHRP.Position - flatDir * 3.2)
			local spawnCF = C(startPos, targetHRP.Position)

			ramPart.CFrame = spawnCF
			ramPart.CanCollide = true
			ramPart.CustomPhysicalProperties = PhysicalProperties.new(100, 0.2, 1, 1, 1)

			f3x(ep, "SyncMove", { { Part = ramPart, CFrame = spawnCF } })
			f3x(ep, "SyncCollision", { { Part = ramPart, CanCollide = true } })
			f3x(ep, "SyncAnchor", { { Part = ramPart, Anchored = false } })

			local waitStart = os.clock()
			while ramPart.Parent and ramPart.Anchored and (os.clock() - waitStart) < 0.25 do
				RunService.Heartbeat:Wait()
			end
			if not (ramPart.Parent and not ramPart.Anchored and STATE and STATE.alive) then return end

			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = V(1e8, 1e8, 1e8)
			bv.P = 1e6
			local launchVel = flatDir * (power.speed * 2.5) + V(0, math.max(power.up * 1.4, 28), 0)
			bv.Velocity = launchVel
			bv.Parent = ramPart

			ramPart.CanCollide = true
			ramPart.AssemblyLinearVelocity = launchVel
			ramPart.AssemblyAngularVelocity = V(32, 24, 32)

			local ramEnd = os.clock() + 0.26
			while os.clock() < ramEnd and STATE and STATE.alive and ramPart.Parent and targetHRP.Parent and rag.active and not rag.restoring do
				local toTarg = targetHRP.Position - ramPart.Position
				local flatTo = V(toTarg.X, 0, toTarg.Z)
				local steerDir = (flatTo.Magnitude > 0.35 and flatTo.Magnitude < 16) and flatTo.Unit or flatDir
				local curVel = steerDir * (power.speed * 2.5) + V(0, math.max(power.up * 1.4, 28), 0)
				bv.Velocity = curVel
				ramPart.AssemblyLinearVelocity = curVel
				ramPart.AssemblyAngularVelocity = V(32, 24, 32)
				RunService.Heartbeat:Wait()
			end

			bv:Destroy()
			ramPart.AssemblyLinearVelocity = V(0, 0, 0)
			ramPart.AssemblyAngularVelocity = V(0, 0, 0)
		end)

		if ramPart and ramPart.Parent and ep and ep.Parent then
			ramPart.Anchored = true
			ramPart.CanCollide = false
			ramPart.CFrame = PARK_CF
			f3x(ep, "SyncAnchor", { { Part = ramPart, Anchored = true } })
			f3x(ep, "SyncCollision", { { Part = ramPart, CanCollide = false } })
			f3x(ep, "SyncMove", { { Part = ramPart, CFrame = PARK_CF } })
		end
		if STATE then STATE.ramBusy = false end
	end)
end

local function runPhysicsRamAndSeat(targetChar, targetHRP, flatDir, power, rag)
	if not (rag and rag.active and not rag.restoring) then return end
	if rag.drivingSetup then return end
	rag.drivingSetup = true

	task.spawn(function()
		local ep = Core.getEndpoint()
		if not (ep and targetHRP and targetHRP.Parent and rag.active and not rag.restoring) then
			rag.drivingSetup = false
			return
		end

		if not rag.hrpDrive and not rag.noDirect and not targetHRP.Locked then
			local origAnchor = targetHRP.Anchored
			local okA = f3x(ep, "SyncAnchor", { { Part = targetHRP, Anchored = true } })
			if okA and not targetHRP.Anchored then task.wait(0.035) end
			if okA and targetHRP.Anchored and rag.active and not rag.restoring then
				rag.hrpDrive = "direct"
				rag.hrpOrigAnchored = origAnchor
				local curTorso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("LowerTorso") or targetHRP
				if rag.mode ~= "clone" then
					rag.pos = curTorso.Position
					rag.rootRestCF = targetHRP.CFrame:ToObjectSpace(curTorso.CFrame)
				end
				trackTargetMove(targetHRP, targetHRP.CFrame)
				rag.drivingSetup = false
				return
			end
		end

		local seatEntry = STATE and STATE.seatPart
		if not rag.hrpDrive and CONFIG.ENABLE_SEAT_CAPTURE and seatEntry and seatEntry.part and seatEntry.part.Parent and not STATE.seatBusy then
			STATE.seatBusy = true
			rag.capturedSeat = true
			local sPart = seatEntry.part
			sPart.CanCollide, sPart.CanTouch = false, true

			for _ = 1, 6 do
				if not (sPart.Parent and targetHRP.Parent and rag.active and not rag.restoring) then break end
				local velLead = targetHRP.AssemblyLinearVelocity * 0.05
				if velLead.Magnitude > 4 then velLead = velLead.Unit * 4 end
				local catchCF = C(targetHRP.Position + velLead) * targetHRP.CFrame.Rotation
				sPart.CFrame = catchCF
				f3x(ep, "SyncMove", { { Part = sPart, CFrame = catchCF } })
				task.wait(0.045)
				local welded = sPart:FindFirstChild("SeatWeld") ~= nil or (rag.hum and rag.hum.SeatPart == sPart)
				if welded then
					rag.hrpDrive = "seat"
					rag.seatDrivePart = sPart
					local rel = sPart.CFrame:ToObjectSpace(targetHRP.CFrame)
					if rel.Position.Magnitude > 5 then rel = C(0, 1.5, 0) end
					rag.seatRel = rel
					local curTorso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("LowerTorso") or targetHRP
					if rag.mode ~= "clone" then
						rag.pos = curTorso.Position
						rag.rootRestCF = targetHRP.CFrame:ToObjectSpace(curTorso.CFrame)
					end
					trackTargetMove(sPart, sPart.CFrame)
					rag.drivingSetup = false
					return
				end
			end

			sPart.CanTouch = false
			sPart.CFrame = PARK_CF
			f3x(ep, "SyncMove", { { Part = sPart, CFrame = PARK_CF } })
			rag.capturedSeat = false
			STATE.seatBusy = false
		end

		if not rag.hrpDrive and rag.active and not rag.restoring then
			triggerPhysicsRamBurst(ep, targetChar, targetHRP, flatDir, power, rag)
		end
		rag.drivingSetup = false
	end)
end

restoreTargetRagdoll = function(rag)
	if not rag or rag.restoring then return end
	rag.restoring = true
	rag.active = false
	if STATE and rag.char and STATE.ragdollingTargets[rag.char] == rag then
		STATE.ragdollingTargets[rag.char] = nil
	end

	local ep = Core.getEndpoint()
	local floorY = rag.pos and sampleFloorY(rag.pos, rag.char, buildTargetRayParams(rag.char, rag)) or 0

	if rag.hrp and rag.hrp.Parent then
		if STATE then STATE.activeTargetMoves[rag.hrp] = nil end
		if rag.hrpDrive == "direct" or rag.hrpDrive == "syncmove" then
			pcall(function()
				rag.hrp.AssemblyLinearVelocity = V(0, 0, 0)
				rag.hrp.AssemblyAngularVelocity = V(0, 0, 0)
			end)
			if ep then
				local rx, ry, rz = rag.hrp.CFrame:ToOrientation()
				local standY = math.max(rag.hrp.Position.Y, floorY + (rag.standHeight or 3.0))
				if math.abs(rx) > 0.35 or math.abs(rz) > 0.35 or rag.hrp.Position.Y < floorY + 1.5 then
					local uprightCF = C(rag.hrp.Position.X, standY, rag.hrp.Position.Z) * CFrame.Angles(0, ry, 0)
					rag.hrp.CFrame = uprightCF
					f3x(ep, "SyncMove", { { Part = rag.hrp, CFrame = uprightCF } })
				end
				f3x(ep, "SyncAnchor", { { Part = rag.hrp, Anchored = rag.hrpOrigAnchored == true } })
			end
		end
	end

	if rag.hrpDrive == "seat" and rag.seatDrivePart then
		local sPart = rag.seatDrivePart
		if STATE then STATE.activeTargetMoves[sPart] = nil end
		if sPart.Parent and ep then
			local safePos = V((rag.pos and rag.pos.X) or sPart.Position.X, floorY + 2.2, (rag.pos and rag.pos.Z) or sPart.Position.Z)
			local safeCF = C(safePos)
			sPart.CFrame = safeCF
			f3x(ep, "SyncMove", { { Part = sPart, CFrame = safeCF } })
			task.wait(0.03)

			local stillWelded = sPart:FindFirstChild("SeatWeld") ~= nil or (rag.hum and rag.hum.SeatPart == sPart)
			if stillWelded then
				if STATE and STATE.seatPart and STATE.seatPart.part == sPart then STATE.seatPart = nil end
				f3x(ep, "Remove", { sPart })
				if STATE and STATE.alive then
					local okNew, newSeat = f3x(ep, "CreatePart", "Seat", PARK_CF, workspace)
					if okNew and typeof(newSeat) == "Instance" and newSeat:IsA("BasePart") then
						lockProxyPhysics(newSeat)
						local c = getChar()
						if c then attachNoColToCharacter(newSeat, c, false) end
						STATE.proxyParts[#STATE.proxyParts + 1] = newSeat
						runParallelBatched({
							function() f3x(ep, "SyncAnchor", { { Part = newSeat, Anchored = true } }) end,
							function() f3x(ep, "SyncCollision", { { Part = newSeat, CanCollide = false } }) end,
							function() f3x(ep, "SyncResize", { { Part = newSeat, Size = V(4.8, 3.2, 4.8), CFrame = PARK_CF } }) end,
							function() f3x(ep, "SyncMaterial", { { Part = newSeat, Material = Enum.Material.SmoothPlastic, Transparency = 1, Reflectance = 0 } }) end,
						}, 4, 4)
						STATE.seatPart = { part = newSeat, serverCF = PARK_CF, pendingCF = PARK_CF, targetCF = PARK_CF, sendSeq = 0, ackSeq = 0, kind = "fx_seat" }
					end
				end
			else
				sPart.CanTouch = false
				sPart.CFrame = PARK_CF
				f3x(ep, "SyncMove", { { Part = sPart, CFrame = PARK_CF } })
			end
		end
		if STATE then STATE.seatBusy = false end
	end

	if rag.mode == "npc" then
		for _, mInfo in ipairs(rag.localMotors or {}) do
			if mInfo.motor and mInfo.motor.Parent then mInfo.motor.Enabled = mInfo.enabled end
		end
		for _, cInfo in ipairs(rag.localColOrig or {}) do
			if cInfo.part and cInfo.part.Parent then cInfo.part.CanCollide = cInfo.col end
		end
		for _, inst in ipairs(rag.localTemp or {}) do
			if inst and inst.Parent then pcall(function() inst:Destroy() end) end
		end
		if rag.hum and rag.hum.Parent and rag.hum.Health > 0 then
			pcall(function()
				rag.hum.PlatformStand = false
				rag.hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
	end

	if rag.hiddenParts and #rag.hiddenParts > 0 and ep then
		local restoreMats = {}
		for _, hp in ipairs(rag.hiddenParts) do
			if hp.part and hp.part.Parent then
				restoreMats[#restoreMats + 1] = { Part = hp.part, Transparency = hp.origTrans }
			end
		end
		if #restoreMats > 0 then f3x(ep, "SyncMaterial", restoreMats) end
	end

	if rag.hiddenDecals and #rag.hiddenDecals > 0 and ep then
		local restoreTex = {}
		for _, hd in ipairs(rag.hiddenDecals) do
			if hd.part and hd.part.Parent then
				restoreTex[#restoreTex + 1] = { Part = hd.part, Face = hd.face, TextureType = "Decal", Transparency = hd.origTrans }
			end
		end
		if #restoreTex > 0 then f3x(ep, "SyncTexture", restoreTex) end
	end

	if rag.clones and #rag.clones > 0 then
		local remList = {}
		for _, cl in ipairs(rag.clones) do
			if cl.part then
				if STATE then STATE.activeTargetMoves[cl.part] = nil end
				if cl.part.Parent then remList[#remList + 1] = cl.part end
			end
		end
		if #remList > 0 and ep then
			for _, ch in ipairs(chunked(remList, 40)) do f3x(ep, "Remove", ch) end
		end
	end
end

local function restoreAllRagdolls()
	if not STATE then return end
	local list = {}
	for _, rag in pairs(STATE.ragdollingTargets) do list[#list + 1] = rag end
	for _, rag in ipairs(list) do pcall(restoreTargetRagdoll, rag) end
	STATE.ragdollingTargets = {}
	STATE.activeTargetMoves = {}
end

local function startNPCRagdoll(targetChar, targetHum, targetHRP, flatDir, power)
	local isR15 = (targetHum and targetHum.RigType == Enum.HumanoidRigType.R15) or (targetChar:FindFirstChild("UpperTorso") ~= nil)
	local torso = isR15 and targetChar:FindFirstChild("LowerTorso") or targetChar:FindFirstChild("Torso")

	local rag = {
		char = targetChar, hum = targetHum, hrp = targetHRP, mode = "npc", active = true, restoring = false,
		isR15 = isR15, startTime = os.clock(), endTime = os.clock() + CONFIG.RAGDOLL_DURATION,
		flatDir = flatDir, pos = (torso and torso.Position) or targetHRP.Position,
		vel = flatDir * power.speed + V(0, power.up, 0),
		rot = (torso and torso.CFrame.Rotation) or targetHRP.CFrame.Rotation,
		angVel = V(-power.spin, (math.random() - 0.5) * 6, (math.random() - 0.5) * 6),
		rootRestCF = torso and targetHRP.CFrame:ToObjectSpace(torso.CFrame) or ID_CF,
		standHeight = targetHum and (isR15 and (targetHum.HipHeight + targetHRP.Size.Y * 0.5) or 3.0) or 3.0,
		localTemp = {}, localMotors = {}, localColOrig = {},
	}
	STATE.ragdollingTargets[targetChar] = rag

	pcall(function()
		targetHum.PlatformStand = true
		targetHum:ChangeState(Enum.HumanoidStateType.Physics)
	end)

	for _, d in ipairs(targetChar:GetDescendants()) do
		if d:IsA("BasePart") and d.Parent == targetChar and d ~= targetHRP then
			rag.localColOrig[#rag.localColOrig + 1] = { part = d, col = d.CanCollide }
			d.CanCollide = true
			if torso and d ~= torso then
				local ncc = Instance.new("NoCollisionConstraint")
				ncc.Part0, ncc.Part1, ncc.Parent = torso, d, torso
				rag.localTemp[#rag.localTemp + 1] = ncc
			end
		elseif d:IsA("Motor6D") and d.Part0 and d.Part1 and d.Name ~= "RootJoint" and d.Name ~= "Root" then
			rag.localMotors[#rag.localMotors + 1] = { motor = d, enabled = d.Enabled }
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame, a1.CFrame = d.C0, d.C1
			a0.Parent, a1.Parent = d.Part0, d.Part1
			local bs = Instance.new("BallSocketConstraint")
			bs.Attachment0, bs.Attachment1 = a0, a1
			bs.LimitsEnabled, bs.UpperAngle = true, (d.Name == "Neck") and 40 or 75
			bs.TwistLimitsEnabled, bs.TwistLowerAngle, bs.TwistUpperAngle = true, -45, 45
			bs.Parent = d.Part0
			d.Enabled = false
			rag.localTemp[#rag.localTemp + 1] = a0
			rag.localTemp[#rag.localTemp + 1] = a1
			rag.localTemp[#rag.localTemp + 1] = bs
		end
	end

	local impulse = flatDir * power.speed + V(0, power.up, 0)
	local spin = V(-power.spin, (math.random() - 0.5) * 10, (math.random() - 0.5) * 10)
	pcall(function()
		targetHRP.AssemblyLinearVelocity, targetHRP.AssemblyAngularVelocity = impulse, spin
		if torso then torso.AssemblyLinearVelocity, torso.AssemblyAngularVelocity = impulse * 1.05, spin end
	end)

	flashTargetDamage(targetChar)
	if CONFIG.ENABLE_KNOCKBACK then runPhysicsRamAndSeat(targetChar, targetHRP, flatDir, power, rag) end
end

function Core.applyF3XKnockback(targetChar, dir, power)
	if not (STATE and targetChar and targetChar.Parent) then return end
	power = power or CONFIG.PARRY_KNOCKBACK_POWER

	local flatDir = V(dir.X, 0, dir.Z)
	flatDir = (flatDir.Magnitude < 0.01) and V(0, 0, -1) or flatDir.Unit

	local targetHRP = getTargetRoot(targetChar)
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not (targetHRP and targetHRP:IsA("BasePart")) then return end

	local existing = STATE.ragdollingTargets[targetChar]
	if existing and existing.active then
		existing.endTime = os.clock() + CONFIG.RAGDOLL_DURATION
		existing.wallSlammed = false
		existing.vel = flatDir * power.speed + V(0, math.max(power.up, 26), 0)
		existing.flatDir = flatDir
		existing.angVel = V(-power.spin, (math.random() - 0.5) * 7, (math.random() - 0.5) * 7)
		existing.pos = (existing.pos or targetHRP.Position) + V(0, 0.9, 0)
		if existing.mode == "npc" and not existing.hrpDrive then
			pcall(function()
				targetHRP.AssemblyLinearVelocity = existing.vel
				targetHRP.AssemblyAngularVelocity = V(-power.spin, (math.random() - 0.5) * 10, (math.random() - 0.5) * 10)
			end)
		end
		flashTargetDamage(targetChar, existing.cloneFlashSaved)
		if CONFIG.ENABLE_KNOCKBACK and not existing.hrpDrive then
			runPhysicsRamAndSeat(targetChar, targetHRP, flatDir, power, existing)
		end
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
	if not targetPlayer and targetHum and CONFIG.ENABLE_TARGET_RAGDOLL then
		startNPCRagdoll(targetChar, targetHum, targetHRP, flatDir, power)
		return
	end

	local ep = Core.getEndpoint()
	local isR15 = (targetHum and targetHum.RigType == Enum.HumanoidRigType.R15) or (targetChar:FindFirstChild("UpperTorso") ~= nil)
	local torso = isR15 and targetChar:FindFirstChild("LowerTorso") or targetChar:FindFirstChild("Torso")
	local upperTorso = isR15 and targetChar:FindFirstChild("UpperTorso") or nil

	local rag = {
		char = targetChar, hum = targetHum, hrp = targetHRP, mode = "ram", active = true, restoring = false,
		isR15 = isR15, startTime = os.clock(), endTime = os.clock() + CONFIG.RAGDOLL_DURATION,
		flatDir = flatDir, pos = (torso and torso.Position) or targetHRP.Position,
		vel = flatDir * power.speed + V(0, power.up, 0),
		rot = (torso and torso.CFrame.Rotation) or targetHRP.CFrame.Rotation,
		angVel = V(-power.spin, (math.random() - 0.5) * 6, (math.random() - 0.5) * 6),
		rootRestCF = torso and targetHRP.CFrame:ToObjectSpace(torso.CFrame) or ID_CF,
		standHeight = targetHum and (isR15 and (targetHum.HipHeight + targetHRP.Size.Y * 0.5) or 3.0) or 3.0,
		clones = {}, cloneFlashSaved = {}, hiddenParts = {}, hiddenDecals = {}, proxyByRole = {},
	}
	STATE.ragdollingTargets[targetChar] = rag

	if CONFIG.ENABLE_KNOCKBACK then
		runPhysicsRamAndSeat(targetChar, targetHRP, flatDir, power, rag)
	end

	if CONFIG.ENABLE_TARGET_RAGDOLL and CONFIG.ENABLE_FE_PROXY_RAGDOLL and ep and torso and not torso.Locked then
		task.spawn(function()
			local built = buildTargetProxyRig(ep, targetChar, torso, upperTorso, isR15, rag)
			if built then flashTargetDamage(targetChar, rag.cloneFlashSaved) else flashTargetDamage(targetChar) end
		end)
	else
		flashTargetDamage(targetChar)
	end
end

local function stepTargetRagdolls(dt)
	local now = os.clock()
	local toRestore = {}

	for targetChar, rag in pairs(STATE.ragdollingTargets) do
		if rag.active and not rag.restoring then
			local targetHum = rag.hum
			local hasClone = (rag.mode == "clone" and rag.cloneTorso and rag.cloneTorso.Parent)
			local hasDrive = (rag.hrpDrive == "direct" or rag.hrpDrive == "syncmove" or rag.hrpDrive == "seat")

			if not targetChar.Parent or not rag.hrp.Parent or (targetHum and targetHum.Health <= 0) or now >= rag.endTime then
				toRestore[#toRestore + 1] = rag
			elseif hasClone or hasDrive then
				local rp = buildTargetRayParams(targetChar, rag)
				rag.vel = rag.vel + V(0, -CONFIG.RAGDOLL_GRAVITY * dt, 0)
				local disp = rag.vel * dt
				if disp.Magnitude > 0.05 then
					local wallHit = workspace:Raycast(rag.pos, disp + disp.Unit * 1.35, rp)
					if wallHit then
						local n = wallHit.Normal
						local impact = -rag.vel:Dot(n)
						rag.vel = (rag.vel - 2 * rag.vel:Dot(n) * n) * 0.45
						rag.pos = wallHit.Position + n * 1.45
						rag.angVel = rag.angVel + V((math.random() - 0.5) * 9, (math.random() - 0.5) * 8, (math.random() - 0.5) * 9)
						if CONFIG.WALL_SLAM_ENABLED and not rag.wallSlammed and impact > 18 then
							rag.wallSlammed = true
							spawnImpactFlash(wallHit.Position, CONFIG.BEAM_CYAN, 1.0, 4.4, 0.22)
							playSFX("PUNCH", 0.85, 0.9, "PARRY")
							addStyleBonus("WALL SPLAT", 150, CONFIG.BEAM_CYAN)
						end
					else
						rag.pos = rag.pos + disp
					end
				end

				local floorY = sampleFloorY(rag.pos, targetChar, rp)
				local minY = floorY + 0.95
				local grounded = false
				if rag.pos.Y <= minY then
					rag.pos = V(rag.pos.X, minY, rag.pos.Z)
					grounded = true
					if rag.vel.Y < -14 then
						rag.vel = V(rag.vel.X * 0.65, math.abs(rag.vel.Y) * 0.34, rag.vel.Z * 0.65)
						rag.angVel = rag.angVel * 0.62
						playSFX("LAND", 0.95, 0.55, "PARRY")
					else
						local damp = math.max(0, 1 - dt * 8.0)
						rag.vel = V(rag.vel.X * damp, 0, rag.vel.Z * damp)
						rag.angVel = rag.angVel * math.max(0, 1 - dt * 8.5)
					end
				end

				local dAng = rag.angVel * dt
				rag.rot = rag.rot * CFrame.Angles(dAng.X, dAng.Y, dAng.Z)
				if grounded and math.abs(rag.vel.Y) < 4 then
					local fDir = V(rag.rot.LookVector.X, 0, rag.rot.LookVector.Z)
					if fDir.Magnitude < 0.05 then fDir = rag.flatDir end
					rag.rot = rag.rot:Lerp(C(V(0, 0, 0), fDir.Unit) * angles(-84, 0, 0), clamp(dt * 8, 0, 1))
				end

				local torsoCF = C(rag.pos) * rag.rot
				if hasDrive then driveTargetHRP(rag, torsoCF) end

				if hasClone then
					driveTargetMove(rag.cloneTorso, torsoCF)
					local cfByRole = { torso = torsoCF }
					local airF = grounded and 0 or clamp(rag.vel.Magnitude / 36, 0.25, 1)
					local sm = clamp(dt * (grounded and 10 or 16), 0, 1)

					for _, cl in ipairs(rag.clones) do
						if cl.role ~= "torso" and cl.role ~= "acc" and cl.part and cl.part.Parent then
							local parentCF = cfByRole[cl.parentKey] or torsoCF
							local tRX, tRY, tRZ = 0, 0, 0
							if cl.role == "upper" then
								tRX, tRY, tRZ = grounded and -12 or 14, 0, math.sin(now * 9) * 8 * airF
							elseif cl.role == "head" then
								tRX, tRY, tRZ = grounded and -22 or math.sin(now * 10) * 18, math.cos(now * 8) * 14, 0
							elseif cl.role == "lArm" then
								tRX, tRY, tRZ = grounded and -28 or (math.sin(now * 14 + 0.5) * 48 * airF + 65), grounded and 18 or (math.cos(now * 11) * 24), grounded and -68 or (-55 - math.sin(now * 12) * 32 * airF)
							elseif cl.role == "rArm" then
								tRX, tRY, tRZ = grounded and 34 or (math.cos(now * 13 + 1.2) * 52 * airF + 70), grounded and -22 or (-math.sin(now * 10) * 24), grounded and 72 or (58 + math.cos(now * 11) * 32 * airF)
							elseif cl.role == "lLeg" then
								tRX, tRY, tRZ = grounded and -18 or (math.sin(now * 12 + 2.0) * 42 * airF - 24), grounded and -14 or 0, grounded and -24 or (-18 - math.sin(now * 9) * 18 * airF)
							elseif cl.role == "rLeg" then
								tRX, tRY, tRZ = grounded and 14 or (-math.sin(now * 12 + 2.4) * 42 * airF + 18), grounded and 16 or 0, grounded and 28 or (20 + math.cos(now * 9) * 18 * airF)
							elseif cl.role == "lLowerArm" or cl.role == "rLowerArm" then
								tRX = grounded and 18 or (28 + math.sin(now * 13) * 20 * airF)
							elseif cl.role == "lLowerLeg" or cl.role == "rLowerLeg" then
								tRX = grounded and -16 or (-32 - math.cos(now * 11) * 22 * airF)
							end
							cl.rx, cl.ry, cl.rz = lerp(cl.rx, tRX, sm), lerp(cl.ry, tRY, sm), lerp(cl.rz, tRZ, sm)
							local partCF = parentCF * cl.relCF * angles(cl.rx, cl.ry, cl.rz)
							if partCF.Position.Y < floorY + 0.45 then
								partCF = C(partCF.Position.X, floorY + 0.45, partCF.Position.Z) * partCF.Rotation
							end
							cfByRole[cl.role] = partCF
							driveTargetMove(cl.part, partCF)
						end
					end
					for _, cl in ipairs(rag.clones) do
						if cl.role == "acc" and cl.part and cl.part.Parent then
							driveTargetMove(cl.part, (cfByRole[cl.parentKey] or torsoCF) * cl.relCF)
						end
					end
				end
			end
		end
	end

	for _, rag in ipairs(toRestore) do task.spawn(restoreTargetRagdoll, rag) end
end

-------------------------------------------------------------------
-- DASH / SLIDE / SLAM
-------------------------------------------------------------------
function Core.triggerDash()
	if not (STATE and CONFIG.ENABLE_DASH) or STATE.isSettingUp then return end
	local now = os.clock()
	if STATE.dash.active or (now - STATE.dash.lastUsed) < CONFIG.DASH_COOLDOWN or STATE.dash.stamina < 1.0 then return end
	local c = getChar()
	local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end

	STATE.dash.stamina = math.max(0, STATE.dash.stamina - 1.0)
	local cam = workspace.CurrentCamera
	local refCF = (cam and (cam.CFrame.Position - hrp.Position).Magnitude < 3.0) and cam.CFrame or hrp.CFrame
	local flatLook = V(refCF.LookVector.X, 0, refCF.LookVector.Z)
	flatLook = (flatLook.Magnitude < 0.01) and V(0, 0, -1) or flatLook.Unit

	local dashDir = (hum.MoveDirection.Magnitude > 0.1) and V(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit or flatLook
	STATE.dash.active, STATE.dash.lastUsed, STATE.dash.startTime = true, now, now
	STATE.dash.dir = dashDir
	STATE.dash.localDir = hrp.CFrame:VectorToObjectSpace(dashDir)
	STATE.slide.active = false
	STATE.slam.active = false

	STATE.fovKick = 12
	if cam then cam.FieldOfView = cam.FieldOfView + 6 end

	hrp.AssemblyLinearVelocity = V(dashDir.X * CONFIG.DASH_SPEED, 2, dashDir.Z * CONFIG.DASH_SPEED)
	playSFX("DASH", 1.15 + (CONFIG.MAX_STAMINA - STATE.dash.stamina) * 0.06, 1.0, "PARRY")
	spawnFlash(hrp.Position, CONFIG.BEAM_CYAN, 1.1, 4.8, 0.18)
	spawnRing(hrp.Position, CONFIG.BEAM_CYAN, 0.8, 5.2, 0.20)
	if CHAR_DEF and CHAR_DEF.onDash then CHAR_DEF.onDash(Core) end
end

function Core.triggerSlideOrSlam()
	if not STATE then return end
	local now = os.clock()
	local c = getChar()
	local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or STATE.isSettingUp then return end

	local hState = hum:GetState()
	local isAir = (hState == Enum.HumanoidStateType.Freefall or hState == Enum.HumanoidStateType.Jumping)
		or (hum.FloorMaterial == Enum.Material.Air and hState ~= Enum.HumanoidStateType.Climbing and hState ~= Enum.HumanoidStateType.Swimming and hState ~= Enum.HumanoidStateType.Seated)

	if isAir then
		local floorRes = workspace:Raycast(hrp.Position, V(0, -400, 0), buildTargetRayParams(c))
		local dropHeight = floorRes and (hrp.Position.Y - floorRes.Position.Y) or 60
		STATE.slide.active, STATE.slide.startTime = true, now
		STATE.slam.active, STATE.slam.startTime = true, now
		STATE.slamArmed = true
		hrp.AssemblyLinearVelocity = V(hrp.AssemblyLinearVelocity.X * 0.25, -CONFIG.SLAM_SPEED, hrp.AssemblyLinearVelocity.Z * 0.25)
		STATE.fovKick = math.max(STATE.fovKick, 14)
		STATE.camShake = math.max(STATE.camShake, 0.85)
		playSFX("DASH", 0.82, 1.0, "PARRY")
		spawnFlash(hrp.Position - V(0, 2.4, 0), CONFIG.BEAM_CYAN, 1.4, 0.4, 0.30)
		if dropHeight > CONFIG.SLAM_MIN_HEIGHT then addStyleBonus("SLAM", 60, CONFIG.BEAM_CYAN) end
		return
	end

	if STATE.slide.active or (now - STATE.slide.lastUsed) < CONFIG.SLIDE_COOLDOWN then return end
	STATE.slide.active, STATE.slide.lastUsed, STATE.slide.startTime = true, now, now
	local flatLook = V(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	flatLook = (flatLook.Magnitude < 0.01) and V(0, 0, -1) or flatLook.Unit
	local moveDir = (hum.MoveDirection.Magnitude > 0.1) and V(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit or flatLook
	STATE.slide.dir = moveDir
	hrp.AssemblyLinearVelocity = V(moveDir.X * CONFIG.SLIDE_SPEED, hrp.AssemblyLinearVelocity.Y, moveDir.Z * CONFIG.SLIDE_SPEED)
	STATE.fovKick = math.max(STATE.fovKick, 9)
	playSFX("STEP", 0.62, 1.0, "DASH")
end

-------------------------------------------------------------------
-- DISPATCH F3X COM SEQUENCIAMENTO (RIG + ALVOS ISOLADOS)
-------------------------------------------------------------------
local function cfDiffExceeds(a, b, posEps, rotEpsDeg)
	if (a.Position - b.Position).Magnitude >= posEps then return true end
	if math.acos(clamp(a.LookVector:Dot(b.LookVector), -1, 1)) >= rad(rotEpsDeg) then return true end
	return math.acos(clamp(a.RightVector:Dot(b.RightVector), -1, 1)) >= rad(rotEpsDeg)
end

local function isDirty(b)
	if not (b and b.part and b.part.Parent and b.targetCF) then return false end
	local refCF = (b.sendSeq > b.ackSeq and b.pendingCF) or b.serverCF
	return cfDiffExceeds(b.targetCF, refCF, CONFIG.POS_EPS, CONFIG.ROT_EPS_DEG)
end

local function dispatchF3X(now)
	if not STATE then return end
	if STATE.inFlight > 0 and (now - STATE.inFlightSince) > 2.0 then STATE.inFlight = 0 end
	local effInterval = (STATE.avgRTT > 0.18) and math.max(CONFIG.SEND_INTERVAL, 0.085) or CONFIG.SEND_INTERVAL
	if (now - STATE.lastSendAt) < effInterval or STATE.inFlight >= CONFIG.MAX_IN_FLIGHT then return end

	local ep = Core.getEndpoint()
	if not ep then return end
	STATE.ep = ep

	local payload, sent = {}, {}
	local function collectOne(b)
		if isDirty(b) then
			STATE.seqCounter += 1
			b.sendSeq = STATE.seqCounter
			b.pendingCF = b.targetCF
			payload[#payload + 1] = { Part = b.part, CFrame = b.targetCF }
			sent[#sent + 1] = { block = b, cf = b.targetCF, seq = b.sendSeq }
		end
	end

	for _, b in ipairs(STATE.modelEntries) do collectOne(b) end
	for _, b in ipairs(STATE.proxyAccessories) do collectOne(b) end
	for _, fx in ipairs({ STATE.coinPart, STATE.flashPart, STATE.impactPart, STATE.ringPart }) do
		if fx then collectOne(fx) end
	end
	if #payload == 0 then return end

	STATE.lastSendAt = now
	STATE.inFlight += 1
	STATE.inFlightSince = now
	local sAt = now

	task.spawn(function()
		local ok, res = pcall(function() return ep:InvokeServer("SyncMove", payload) end)
		if not STATE then return end
		STATE.inFlight = math.max(0, STATE.inFlight - 1)
		local rtt = os.clock() - sAt
		STATE.avgRTT = (STATE.avgRTT == 0) and rtt or (STATE.avgRTT * 0.8 + rtt * 0.2)
		if ok and res ~= false then
			for _, e in ipairs(sent) do
				if e.seq > e.block.ackSeq then
					e.block.ackSeq, e.block.serverCF = e.seq, e.cf
				end
			end
		end
	end)
end

local function dispatchTargetF3X(now)
	if not STATE then return end
	if STATE.targetInFlight > 0 and (now - STATE.targetInFlightSince) > 1.5 then STATE.targetInFlight = 0 end
	if (now - STATE.targetLastSendAt) < 0.04 or STATE.targetInFlight >= 1 then return end

	local ep = Core.getEndpoint()
	if not ep then return end

	local payload, sent = {}, {}
	for part, b in pairs(STATE.activeTargetMoves) do
		if not (part and part.Parent) then
			STATE.activeTargetMoves[part] = nil
		elseif isDirty(b) then
			STATE.seqCounter += 1
			b.sendSeq = STATE.seqCounter
			b.pendingCF = b.targetCF
			payload[#payload + 1] = { Part = b.part, CFrame = b.targetCF }
			sent[#sent + 1] = { block = b, cf = b.targetCF, seq = b.sendSeq }
		end
	end
	if #payload == 0 then return end

	STATE.targetLastSendAt = now
	STATE.targetInFlight += 1
	STATE.targetInFlightSince = now

	task.spawn(function()
		local ok, res = pcall(function() return ep:InvokeServer("SyncMove", payload) end)
		if not STATE then return end
		STATE.targetInFlight = math.max(0, STATE.targetInFlight - 1)
		if ok and res ~= false then
			for _, e in ipairs(sent) do
				if e.seq > e.block.ackSeq then
					e.block.ackSeq, e.block.serverCF = e.seq, e.cf
				end
			end
		else
			for _, rag in pairs(STATE.ragdollingTargets) do
				if rag.active and rag.hrpDrive == "direct" then
					rag.noDirect = true
					rag.hrpDrive = nil
					if rag.hrp then STATE.activeTargetMoves[rag.hrp] = nil end
					runPhysicsRamAndSeat(rag.char, rag.hrp, rag.flatDir, CONFIG.PARRY_KNOCKBACK_POWER, rag)
				end
			end
		end
	end)
end

-------------------------------------------------------------------
-- SETUP E CLEANUP DO RIG
-------------------------------------------------------------------
local function waitForCharacterReady(c, mySetupId)
	local t0 = os.clock()
	while STATE and STATE.alive and STATE.setupId == mySetupId and not c:IsDescendantOf(workspace) and (os.clock() - t0) < 5.0 do
		task.wait(0.05)
	end
	if not c:IsDescendantOf(workspace) or not STATE or not STATE.alive or STATE.setupId ~= mySetupId then return false end

	local hrp = c:WaitForChild("HumanoidRootPart", 5)
	local hum = c:WaitForChild("Humanoid", 5)
	local head = c:WaitForChild("Head", 5)
	if not (hrp and hum and head) then return false end
	if not plr:HasAppearanceLoaded() then
		local t1 = os.clock()
		while not plr:HasAppearanceLoaded() and (os.clock() - t1) < 3.0 and STATE and STATE.alive and STATE.setupId == mySetupId do
			task.wait(0.05)
		end
	end
	task.wait(0.10)
	return STATE and STATE.alive and STATE.setupId == mySetupId and c.Parent ~= nil and hrp.Parent == c and hum.Health > 0
end

local function waitForEndpoint(timeout, mySetupId)
	local t0 = os.clock()
	while STATE and STATE.alive and STATE.setupId == mySetupId and (os.clock() - t0) < (timeout or 8) do
		local ep = getF3XEndpoint()
		if ep and ep:IsDescendantOf(game) then return ep end
		task.wait(0.15)
	end
	return nil
end

local function cleanupRigParts(ep)
	if not STATE then return end
	if not ep or not ep.Parent then ep = getF3XEndpoint() end

	restoreAllRagdolls()
	for _, ncc in ipairs(STATE.noColConstraints) do pcall(function() ncc:Destroy() end) end
	STATE.noColConstraints = {}
	clearProxyConnections()

	local c = getChar()
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.CameraOffset = V(0, 0, 0) end)
		if STATE.touchedWalkSpeed then
			pcall(function() hum.WalkSpeed = CONFIG.WALK_SPEED end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
			pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
		end
	end
	STATE.touchedWalkSpeed = false

	for _, entry in ipairs(STATE.hiddenRealParts) do
		if entry.part and entry.part.Parent then
			pcall(function()
				entry.part.LocalTransparencyModifier = 0
				entry.part.Transparency = entry.origTrans
			end)
		end
	end
	for _, entry in ipairs(STATE.hiddenRealDecals) do
		if entry.decal and entry.decal.Parent then
			pcall(function() entry.decal.Transparency = entry.origTrans end)
		end
	end

	local tasks = {}
	local toDel = {}
	for _, p in ipairs(STATE.proxyParts) do
		if p and p.Parent then
			p.Transparency = 1
			p.CFrame = PARK_CF
			toDel[#toDel + 1] = p
		end
	end
	if ep and ep.Parent and #toDel > 0 then
		tasks[#tasks + 1] = function()
			for _, ch in ipairs(chunked(toDel, 40)) do invokeWithTimeout(ep, 1.5, "Remove", ch) end
		end
	end

	local remaining = {}
	if not (ep and ep.Parent) then
		for _, p in ipairs(toDel) do if p and p.Parent then remaining[#remaining + 1] = p end end
	end
	STATE.proxyParts = remaining
	STATE.proxyAccessories = {}
	STATE.modelEntries = {}
	STATE.buckets = {}
	STATE.coinPart, STATE.beam1Part, STATE.beam2Part, STATE.beamCore1Part, STATE.beamCore2Part = nil, nil, nil, nil, nil
	STATE.flashPart, STATE.impactPart, STATE.ringPart, STATE.seatPart, STATE.ramPart = nil, nil, nil, nil, nil
	STATE.seatBusy, STATE.ramBusy = false, false
	STATE.flashTokens, STATE.flashOriginals = {}, {}
	STATE.dash.active, STATE.slide.active, STATE.slam.active = false, false, false
	STATE.flashAnim.active, STATE.impactAnim.active, STATE.ringAnim.active, STATE.beamAnim.active = false, false, false, false

	if ep and ep.Parent and #STATE.hiddenRealParts > 0 then
		local matItems = {}
		for _, entry in ipairs(STATE.hiddenRealParts) do
			if entry.part and entry.part:IsDescendantOf(workspace) then
				matItems[#matItems + 1] = { Part = entry.part, Transparency = entry.origTrans }
			end
		end
		if #matItems > 0 then tasks[#tasks + 1] = function() invokeWithTimeout(ep, 1.5, "SyncMaterial", matItems) end end
	end
	STATE.hiddenRealParts = {}

	if ep and ep.Parent and #STATE.hiddenRealDecals > 0 then
		local texItems = {}
		for _, entry in ipairs(STATE.hiddenRealDecals) do
			if entry.part and entry.part:IsDescendantOf(workspace) then
				texItems[#texItems + 1] = { Part = entry.part, Face = entry.face, TextureType = "Decal", Transparency = entry.origTrans }
			end
		end
		if #texItems > 0 then tasks[#tasks + 1] = function() invokeWithTimeout(ep, 1.5, "SyncTexture", texItems) end end
	end
	STATE.hiddenRealDecals = {}

	runParallelBatched(tasks, 4, 2.2)
end

setupRig = function()
	if not STATE then return end
	while STATE and STATE.isSettingUp and STATE.alive do task.wait(0.05) end
	if not (STATE and STATE.alive) then return end

	STATE.isSettingUp = true
	STATE.setupId += 1
	local mySetupId = STATE.setupId

	local okMain, errMain = xpcall(function()
		local function finishAbort(ep, createdParts)
			if createdParts and #createdParts > 0 and ep and ep.Parent then
				for _, ch in ipairs(chunked(createdParts, 40)) do invokeWithTimeout(ep, 1.5, "Remove", ch) end
			end
		end

		local c = getChar() or plr.CharacterAdded:Wait()
		if not waitForCharacterReady(c, mySetupId) then return end

		local ep = waitForEndpoint(8, mySetupId)
		if not ep then
			warn("[F3X Ultrakill] 'Building Tools+' / 'Building Tools' nao encontrado!")
			return
		end
		STATE.ep = ep
		STATE.inFlight, STATE.lastSendAt = 0, 0
		STATE.targetInFlight, STATE.targetInFlightSince, STATE.targetLastSendAt = 0, 0, 0
		STATE.ramPart, STATE.ramBusy, STATE.seatBusy = nil, false, false

		cleanupRigParts(ep)
		setupSounds()
		setupHUD()
		if not (STATE and STATE.alive and STATE.setupId == mySetupId) then return end

		local hrp, hum = c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then return end

		STATE.rigType = (hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
		local _, initYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
		STATE.lastYaw = initYaw
		STATE.lastHealth = hum.Health
		STATE.hardDamage = hum.Health
		STATE.dash.stamina = CONFIG.MAX_STAMINA

		if CONFIG.DISABLE_FALLING_DOWN then
			STATE.touchedWalkSpeed = true
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			end)
		end

		local resizeItems, colorItems, matItems, anchorItems, colItems = {}, {}, {}, {}, {}
		local createMeshItems, syncMeshQueue, createLightItems, syncLightQueue = {}, {}, {}, {}
		local hideMatItems, hideTexItems, createdThisSetup = {}, {}, {}

		local function hideRealPart(realPart)
			STATE.hiddenRealParts[#STATE.hiddenRealParts + 1] = { part = realPart, origTrans = realPart.Transparency }
			hideMatItems[#hideMatItems + 1] = { Part = realPart, Transparency = 1 }
			local faceDecal = (realPart.Name == "Head") and (realPart:FindFirstChild("face") or realPart:FindFirstChildOfClass("Decal")) or nil
			if faceDecal then
				STATE.hiddenRealDecals[#STATE.hiddenRealDecals + 1] = { part = realPart, decal = faceDecal, face = faceDecal.Face, origTrans = faceDecal.Transparency }
				hideTexItems[#hideTexItems + 1] = { Part = realPart, Face = faceDecal.Face, TextureType = "Decal", Transparency = 1 }
			end
		end

		local accSpecs = {}
		for _, child in ipairs(c:GetChildren()) do
			if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
				hideRealPart(child)
			elseif child:IsA("Accessory") then
				local handle = child:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					hideRealPart(handle)
					if not CONFIG.HIDE_ALL_AVATAR_ACCESSORIES then
						local limbName, relCF = getAccessoryAttachment(handle, c, STATE.rigType)
						if limbName ~= "Head" then
							accSpecs[#accSpecs + 1] = {
								kind = "acc", limbName = limbName, relCF = relCF, partType = "Normal",
								origCF = handle.CFrame, origSize = handle.Size, origColor = handle.Color, origMaterial = handle.Material,
								origTrans = handle.Transparency, origReflectance = handle.Reflectance, meshSpec = getMeshSpecForPart(handle, c, nil),
							}
						end
					end
				end
			end
		end

		local realSoleDepth = (STATE.rigType == "R15") and (hum.HipHeight + hrp.Size.Y * 0.5) or 3.0
		local torsoInitCF = hrp.CFrame * C(0, CONFIG.SOLE_DEPTH - realSoleDepth, 0)
		local specs = CHAR_DEF.buildModel(Core, c, hrp, hum, torsoInitCF) or {}
		for _, asp in ipairs(accSpecs) do specs[#specs + 1] = asp end

		specs[#specs + 1] = { kind = "fx_coin",   partType = "Cylinder", origCF = PARK_CF, origSize = V(0.14, 0.60, 0.60), origColor = CONFIG.COIN_GOLD,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_beam1",  partType = "Normal",   origCF = PARK_CF, origSize = V(0.22, 0.22, 1),    origColor = CONFIG.YELLOW_NEON, origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_beam2",  partType = "Normal",   origCF = PARK_CF, origSize = V(0.38, 0.38, 1),    origColor = CONFIG.BEAM_CYAN,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_bcore1", partType = "Normal",   origCF = PARK_CF, origSize = V(0.09, 0.09, 1),    origColor = CONFIG.BEAM_CORE,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_bcore2", partType = "Normal",   origCF = PARK_CF, origSize = V(0.14, 0.14, 1),    origColor = CONFIG.BEAM_CORE,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_flash",  partType = "Ball",     origCF = PARK_CF, origSize = V(1.2, 1.2, 1.2),    origColor = CONFIG.PARRY_FLASH, origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_impact", partType = "Ball",     origCF = PARK_CF, origSize = V(1.6, 1.6, 1.6),    origColor = CONFIG.BEAM_CYAN,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_ring",   partType = "Cylinder", origCF = PARK_CF, origSize = V(0.14, 1.6, 1.6),   origColor = CONFIG.BEAM_CYAN,   origMaterial = Enum.Material.Neon, origTrans = 1, origReflectance = 0 }
		specs[#specs + 1] = { kind = "fx_seat",   partType = "Seat",     origCF = PARK_CF, origSize = V(4.8, 3.2, 4.8),    origColor = CONFIG.BEAM_CYAN,   origMaterial = Enum.Material.SmoothPlastic, origTrans = 1, origReflectance = 0, allowTouch = false }
		specs[#specs + 1] = { kind = "fx_ram",    partType = "Normal",   origCF = PARK_CF, origSize = V(6.5, 6.5, 6.5),    origColor = CONFIG.BEAM_CYAN,   origMaterial = Enum.Material.SmoothPlastic, origTrans = 1, origReflectance = 0, allowTouch = true }

		local function spawnSpecsBatch(specList)
			local tasks = {}
			for _, spec in ipairs(specList) do
				tasks[#tasks + 1] = function()
					if not (STATE and STATE.alive and STATE.setupId == mySetupId) or spec.newPart then return end
					local ok, p = f3x(ep, "CreatePart", spec.partType or "Normal", PARK_CF, workspace)
					if ok and typeof(p) == "Instance" and p:IsA("BasePart") then
						lockProxyPhysics(p)
						attachNoColToCharacter(p, c, spec.allowTouch)
						createdThisSetup[#createdThisSetup + 1] = p
						STATE.proxyParts[#STATE.proxyParts + 1] = p
						spec.newPart = p
					end
				end
			end
			runParallelBatched(tasks, CONFIG.MAX_CREATE_WORKERS, 14)
		end

		spawnSpecsBatch(specs)
		local missingSpecs = {}
		for _, spec in ipairs(specs) do
			if not spec.newPart then missingSpecs[#missingSpecs + 1] = spec end
		end
		if #missingSpecs > 0 and STATE and STATE.alive and STATE.setupId == mySetupId then
			task.wait(0.12)
			spawnSpecsBatch(missingSpecs)
		end

		if not (STATE and STATE.alive and STATE.setupId == mySetupId) then
			finishAbort(ep, createdThisSetup)
			return
		end

		local pendingEntries = {}
		for _, spec in ipairs(specs) do
			local p = spec.newPart
			if p and p.Parent then
				lockProxyPhysics(p)
				if spec.allowTouch then p.CanTouch = true end
				resizeItems[#resizeItems + 1] = { Part = p, Size = spec.origSize, CFrame = spec.origCF }
				colorItems[#colorItems + 1] = { Part = p, Color = spec.origColor, UnionColoring = true }
				matItems[#matItems + 1] = { Part = p, Material = spec.origMaterial, Transparency = spec.origTrans or 0, Reflectance = spec.origReflectance or 0 }
				anchorItems[#anchorItems + 1] = { Part = p, Anchored = true }
				colItems[#colItems + 1] = { Part = p, CanCollide = false }

				if spec.meshSpec then
					local ms = spec.meshSpec
					createMeshItems[#createMeshItems + 1] = { Part = p }
					local mSync = { Part = p, MeshType = ms.MeshType, Scale = ms.Scale, Offset = ms.Offset }
					if ms.MeshId and ms.MeshId ~= "" then mSync.MeshId = ms.MeshId end
					if ms.TextureId and ms.TextureId ~= "" then mSync.TextureId = ms.TextureId end
					if ms.VertexColor then mSync.VertexColor = ms.VertexColor end
					syncMeshQueue[#syncMeshQueue + 1] = mSync
				end

				if spec.light then
					createLightItems[#createLightItems + 1] = { Part = p, LightType = "PointLight" }
					syncLightQueue[#syncLightQueue + 1] = { Part = p, LightType = "PointLight", Color = spec.lightColor or CONFIG.YELLOW_NEON, Range = 9, Brightness = 1.6 }
				end

				pendingEntries[#pendingEntries + 1] = {
					part = p, serverCF = PARK_CF, pendingCF = PARK_CF, targetCF = spec.origCF,
					sendSeq = 0, ackSeq = 0, kind = spec.kind, name = spec.limbName, limbName = spec.limbName,
					relCF = spec.relCF, side = spec.side, wingIdx = spec.wingIdx, gunNeon = spec.gunNeon, key = spec.key,
					tag = spec.tag,
				}
			end
		end

		local lockTasks = {}
		for _, ch in ipairs(chunked(anchorItems, CONFIG.SYNC_CHUNK)) do lockTasks[#lockTasks + 1] = function() f3x(ep, "SyncAnchor", ch) end end
		for _, ch in ipairs(chunked(colItems, CONFIG.SYNC_CHUNK)) do lockTasks[#lockTasks + 1] = function() f3x(ep, "SyncCollision", ch) end end
		runParallelBatched(lockTasks, CONFIG.MAX_CREATE_WORKERS, 6)

		local syncTasks = {}
		for _, ch in ipairs(chunked(resizeItems, CONFIG.SYNC_CHUNK)) do syncTasks[#syncTasks + 1] = function() f3x(ep, "SyncResize", ch) end end
		for _, ch in ipairs(chunked(colorItems, CONFIG.SYNC_CHUNK)) do syncTasks[#syncTasks + 1] = function() f3x(ep, "SyncColor", ch) end end
		for _, ch in ipairs(chunked(matItems, CONFIG.SYNC_CHUNK)) do syncTasks[#syncTasks + 1] = function() f3x(ep, "SyncMaterial", ch) end end
		if #hideMatItems > 0 then syncTasks[#syncTasks + 1] = function() f3x(ep, "SyncMaterial", hideMatItems) end end
		if #hideTexItems > 0 then syncTasks[#syncTasks + 1] = function() f3x(ep, "SyncTexture", hideTexItems) end end
		if #createMeshItems > 0 then syncTasks[#syncTasks + 1] = function() f3x(ep, "CreateMeshes", createMeshItems) end end
		if #createLightItems > 0 then syncTasks[#syncTasks + 1] = function() f3x(ep, "CreateLights", createLightItems) end end
		runParallelBatched(syncTasks, CONFIG.MAX_CREATE_WORKERS, 10)

		if not (STATE and STATE.alive and STATE.setupId == mySetupId) then
			finishAbort(ep, createdThisSetup)
			return
		end

		runParallelBatched({
			function() if #syncMeshQueue > 0 then f3x(ep, "SyncMesh", syncMeshQueue) end end,
			function() if #syncLightQueue > 0 then f3x(ep, "SyncLighting", syncLightQueue) end end,
		}, 2, 6)

		for _, entry in ipairs(pendingEntries) do
			if entry.part and entry.part.Parent then
				entry.part.CFrame = entry.targetCF
				entry.serverCF = entry.targetCF
				entry.pendingCF = entry.targetCF
			end
			if entry.kind == "acc" then
				STATE.proxyAccessories[#STATE.proxyAccessories + 1] = entry
			elseif entry.kind == "fx_coin" then STATE.coinPart = entry
			elseif entry.kind == "fx_beam1" then STATE.beam1Part = entry
			elseif entry.kind == "fx_beam2" then STATE.beam2Part = entry
			elseif entry.kind == "fx_bcore1" then STATE.beamCore1Part = entry
			elseif entry.kind == "fx_bcore2" then STATE.beamCore2Part = entry
			elseif entry.kind == "fx_flash" then STATE.flashPart = entry
			elseif entry.kind == "fx_impact" then STATE.impactPart = entry
			elseif entry.kind == "fx_ring" then STATE.ringPart = entry
			elseif entry.kind == "fx_seat" then STATE.seatPart = entry
			elseif entry.kind == "fx_ram" then STATE.ramPart = entry
			else
				STATE.modelEntries[#STATE.modelEntries + 1] = entry
				STATE.buckets[entry.kind] = STATE.buckets[entry.kind] or {}
				STATE.buckets[entry.kind][#STATE.buckets[entry.kind] + 1] = entry
			end
		end

		if CHAR_DEF.onSetupComplete then CHAR_DEF.onSetupComplete(Core) end
		print(string.format("[F3X Ultrakill - %s] Ready (%s): %d/%d parts | KB+Seat+Ram=%s",
			tostring(CHAR_DEF.name or CHAR_DEF.id), STATE.rigType, #STATE.proxyParts, #specs, tostring(STATE.seatPart ~= nil and STATE.ramPart ~= nil)))

		clearCharConnections()
		table.insert(STATE.charConnections, hum.Died:Connect(function()
			if STATE and STATE.alive then
				local curEp = Core.getEndpoint()
				task.spawn(function()
					restoreAllRagdolls()
					cleanupRigParts(curEp)
				end)
			end
		end))
		table.insert(STATE.charConnections, c.DescendantAdded:Connect(function(desc)
			if STATE and STATE.alive and desc:IsA("BasePart") then
				for _, pp in ipairs(STATE.proxyParts) do
					if pp and pp.Parent then addNoColPair(desc, pp) end
				end
			end
		end))
		table.insert(STATE.charConnections, c.ChildAdded:Connect(function(child)
			if STATE and STATE.alive and child:IsA("Accessory") then
				task.wait(0.25)
				if STATE and STATE.alive and child.Parent == c and not STATE.isSettingUp then setupRig() end
			end
		end))
	end, debug.traceback)

	if not okMain then
		warn("[F3X Ultrakill] setupRig error: " .. tostring(errMain))
	end
	if STATE then STATE.isSettingUp = false end
end

forceRebuild = function()
	if not (STATE and STATE.alive) then return end
	print("[F3X Ultrakill] F7 Force Rebuild triggered.")
	STATE.setupId += 1
	STATE.isSettingUp = false
	STATE.inFlight, STATE.lastSendAt = 0, 0
	STATE.targetInFlight, STATE.targetLastSendAt = 0, 0
	STATE.ramBusy, STATE.seatBusy = false, false
	restoreAllRagdolls()
	task.spawn(setupRig)
end

cleanup = function()
	if not (STATE and STATE.alive) then return end
	print("[F3X Ultrakill] F6 Stop & Cleanup triggered.")
	local oldState = STATE
	oldState.alive = false
	oldState.setupId += 1
	oldState.isSettingUp = false

	pcall(function() RunService:UnbindFromRenderStep(CONFIG.RENDER_NAME) end)
	clearCharConnections()
	for _, conn in ipairs(oldState.connections) do pcall(function() conn:Disconnect() end) end
	oldState.connections = {}

	local cam = workspace.CurrentCamera
	if cam then pcall(function() cam.FieldOfView = CONFIG.BASE_FOV end) end
	destroySounds()
	destroyHUD()
	if oldState.hitstopCC then
		pcall(function() oldState.hitstopCC:Destroy() end)
		oldState.hitstopCC = nil
	end

	task.spawn(function()
		cleanupRigParts()
		if STATE == oldState then STATE = nil end
	end)
	for _, key in ipairs({ "F3XUltrakillCleanup", "F3XV1ReanimCleanup", "F3XV2ReanimCleanup" }) do
		if env[key] == cleanup then env[key] = nil end
	end
end

-------------------------------------------------------------------
-- INITIALIZE CHARACTER MODULE
-------------------------------------------------------------------
function Core.start(charDef)
	for _, key in ipairs({ "F3XUltrakillCleanup", "F3XV1ReanimCleanup", "F3XV2ReanimCleanup", "F3XR6ReanimCleanup", "F3XMayhemIdleCleanup" }) do
		if type(env[key]) == "function" then pcall(env[key]) end
	end

	CHAR_DEF = charDef
	CONFIG = mergeTables(DEFAULT_CONFIG, charDef.config)

	STATE = {
		alive = true,
		rigType = "R6",
		setupId = 0,
		isSettingUp = false,
		ep = nil,
		time = 0,

		walkCycle = 0, prevWalkSin = 0, walkBlend = 0, sprintBlend = 0, airBlend = 0,
		airTime = 0, wasAir = false, landRecover = 0, localFwd = 0, localStrafe = 0,
		vertVel = 0, lastYaw = 0, turnRate = 0, touchedWalkSpeed = false,
		hardDamage = 0, lastHealth = 100, camShake = 0, fovKick = 0,

		modelEntries = {}, buckets = {}, proxyAccessories = {}, proxyParts = {},
		noColConstraints = {}, hiddenRealParts = {}, hiddenRealDecals = {},
		sfxFolder = nil, soundTemplates = {}, activeSounds = {},

		coinPart = nil, beam1Part = nil, beam2Part = nil, beamCore1Part = nil, beamCore2Part = nil,
		flashPart = nil, impactPart = nil, ringPart = nil, seatPart = nil, ramPart = nil,
		seatBusy = false, ramBusy = false,

		knownHumanoids = {}, flashTokens = {}, flashOriginals = {},
		ragdollingTargets = {}, activeTargetMoves = {},

		fpArms = false, fpHideArms = false, mobileSprint = false,
		dash = { active = false, lastUsed = 0, startTime = 0, dir = V(0, 0, -1), localDir = V(0, 0, -1), stamina = CONFIG.MAX_STAMINA },
		slide = { active = false, lastUsed = 0, startTime = 0, dir = V(0, 0, -1) },
		slam = { active = false, startTime = 0 },
		slamArmed = false,

		flashAnim = { active = false, startTime = 0, duration = 0.22, startSize = 0.6, endSize = 3.0, pos = PARK_CF.Position },
		impactAnim = { active = false, startTime = 0, duration = 0.26, startSize = 0.9, endSize = 4.8, pos = PARK_CF.Position },
		ringAnim = { active = false, startTime = 0, duration = 0.28, startRadius = 0.8, endRadius = 6.5, cf = PARK_CF },
		beamAnim = { active = false, startTime = 0, duration = 0.26, hideBeam1 = false, cf1 = PARK_CF, cf2 = PARK_CF, len1 = 1, len2 = 1, w1 = 0.18, w2 = 0.34 },

		hud = {
			folder = nil, leftPart = nil, rightPart = nil, leftGui = nil, rightGui = nil,
			crossGui = nil, mobGui = nil, hitmarker = nil, hint = nil, wpnTitle = nil, wpnStroke = nil, keyHint = nil,
			hpFill = nil, hardDmgFill = nil, hpText = nil, speedLabel = nil,
			stamBars = {}, coinPips = {},
			rankBadge = nil, rankTitle = nil, rankBarFill = nil, multLabel = nil,
			styleFeed = nil, rightFrame = nil,
			stylePoints = 0, styleMult = 1.0, stylePop = 0, styleFeedEntries = {}, hitmarkerUntil = 0,
			swayYaw = 0, swayPitch = 0, swayX = 0, swayY = 0, prevCamLook = nil,
		},

		inFlight = 0, inFlightSince = 0, lastSendAt = 0, avgRTT = 0, seqCounter = 0,
		targetInFlight = 0, targetInFlightSince = 0, targetLastSendAt = 0,
		hitstopUntil = 0, hitstopDur = 0.10, hitstopCC = nil,
		connections = {}, charConnections = {}, proxyConnections = {},
		custom = {},
	}

	if CHAR_DEF.initState then CHAR_DEF.initState(Core) end

	env.F3XUltrakillCleanup = cleanup
	env.F3XUltrakillRebuild = forceRebuild
	env.F3XV1ReanimCleanup = cleanup
	env.F3XV1ReanimRebuild = forceRebuild

	initTargetTracker()
	task.spawn(setupRig)

	table.insert(STATE.connections, RunService.Stepped:Connect(function()
		if not (STATE and STATE.alive) then return end
		for _, p in ipairs(STATE.proxyParts) do
			if p and p.Parent then
				local mode = isCombatPhysicsActive(p)
				if not mode then
					p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
				elseif mode == "seat" then
					p.CanCollide, p.CanTouch, p.CanQuery = false, true, false
				elseif mode == "ram" then
					p.CanCollide, p.CanTouch, p.CanQuery = true, true, false
				end
			end
		end

		if CONFIG.IDLE_TILT_GUARD and not STATE.dash.active and not STATE.slide.active then
			local c = getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local hState = hum:GetState()
				if hState ~= Enum.HumanoidStateType.Swimming and hState ~= Enum.HumanoidStateType.Seated and hState ~= Enum.HumanoidStateType.Physics then
					local rx, ry, rz = hrp.CFrame:ToOrientation()
					if math.abs(rx) > 0.05 or math.abs(rz) > 0.05 then
						hrp.CFrame = C(hrp.Position) * CFrame.Angles(0, ry, 0)
					end
					local ang = hrp.AssemblyAngularVelocity
					if math.abs(ang.X) > 0.5 or math.abs(ang.Z) > 0.5 or (hum.MoveDirection.Magnitude < 0.01 and math.abs(ang.Y) > 0.5) then
						hrp.AssemblyAngularVelocity = V(0, ang.Y * 0.25, 0)
					end
				end
			end
		end
	end))

	RunService:BindToRenderStep(CONFIG.RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not (STATE and STATE.alive) then return end
		local c = getChar()
		local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
		if not (c and hrp and hum and hum.Health > 0) then return end

		dt = math.min(dt, 0.05)
		local nowClock = os.clock()
		local inHitstop = nowClock < STATE.hitstopUntil
		if STATE.hitstopCC and STATE.hitstopCC.Parent then
			if inHitstop then
				local rem = clamp((STATE.hitstopUntil - nowClock) / math.max(0.01, STATE.hitstopDur), 0, 1)
				STATE.hitstopCC.Brightness = 0.28 * rem
				STATE.hitstopCC.Contrast = 0.35 * rem
				STATE.hitstopCC.TintColor = Color3.new(1, 1, 1):Lerp(STATE.hitstopCC.TintColor, rem)
			elseif STATE.hitstopCC.Enabled then
				STATE.hitstopCC.Brightness = 0
				STATE.hitstopCC.Contrast = 0
				STATE.hitstopCC.TintColor = Color3.new(1, 1, 1)
				STATE.hitstopCC.Enabled = false
			end
		end
		if not inHitstop then STATE.time += dt end

		local typing = UIS:GetFocusedTextBox() ~= nil or GuiService.MenuIsOpen
		local sprinting = CONFIG.ENABLE_SPRINT and (not typing) and (UIS:IsKeyDown(Enum.KeyCode.LeftShift) or STATE.mobileSprint)
		if CONFIG.ENABLE_SPRINT and not STATE.slide.active then
			hum.WalkSpeed = sprinting and CONFIG.SPRINT_SPEED or CONFIG.WALK_SPEED
			STATE.touchedWalkSpeed = true
		end

		local vel = hrp.AssemblyLinearVelocity
		local flatVel = V(vel.X, 0, vel.Z)
		local speed = flatVel.Magnitude
		local hState = hum:GetState()
		local isAir = (hState == Enum.HumanoidStateType.Freefall or hState == Enum.HumanoidStateType.Jumping)
			or (hum.FloorMaterial == Enum.Material.Air and hState ~= Enum.HumanoidStateType.Climbing and hState ~= Enum.HumanoidStateType.Swimming and hState ~= Enum.HumanoidStateType.Seated)

		if STATE.slam.active then
			if isAir then
				hrp.AssemblyLinearVelocity = V(vel.X * 0.92, -CONFIG.SLAM_SPEED, vel.Z * 0.92)
			else
				STATE.slam.active = false
				STATE.slamArmed = false
				STATE.landRecover = 1.4
				STATE.camShake = math.max(STATE.camShake, 0.75)
				playSFX("LAND", 0.65, 1.4, "PARRY")
				spawnImpactFlash(hrp.Position - V(0, 2.5, 0), CONFIG.BEAM_CYAN, 1.5, 8.5, 0.30)
				spawnRing(hrp.Position - V(0, 2.7, 0), CONFIG.BEAM_CYAN, 0.8, 6.5, 0.34)
				addStyleBonus("GROUND SLAM", 180, CONFIG.BEAM_CYAN)
				for _, model in ipairs(getActiveTargetHumanoids(c)) do
					local tHRP = getTargetRoot(model.Parent)
					if tHRP and tHRP:IsA("BasePart") then
						local diff = tHRP.Position - hrp.Position
						if diff.Magnitude > 0.1 and diff.Magnitude <= CONFIG.SLAM_RANGE then
							Core.applyF3XKnockback(model.Parent, diff, CONFIG.SLAM_KNOCKBACK_POWER)
						end
					end
				end
			end
		end

		if STATE.wasAir and not isAir and STATE.vertVel < -14 and not STATE.slam.active then
			STATE.landRecover = 1.0
			playSFX("LAND", 1.1, clamp(math.abs(STATE.vertVel) / 60, 0.35, 1.0), "PARRY")
		end
		STATE.airTime = isAir and (STATE.airTime + dt) or 0
		STATE.wasAir = isAir
		STATE.vertVel = lerp(STATE.vertVel, vel.Y, clamp(dt * 18, 0, 1))
		STATE.landRecover = math.max(0, STATE.landRecover - dt * 6.0)

		local localV = hrp.CFrame:VectorToObjectSpace(flatVel)
		STATE.localFwd = lerp(STATE.localFwd, clamp(-localV.Z / CONFIG.WALK_SPEED, -1.6, 2.2), clamp(dt * 12, 0, 1))
		STATE.localStrafe = lerp(STATE.localStrafe, clamp(localV.X / CONFIG.WALK_SPEED, -1.6, 1.6), clamp(dt * 12, 0, 1))

		local _, curYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
		local dyaw = (curYaw - STATE.lastYaw + math.pi) % (2 * math.pi) - math.pi
		STATE.lastYaw = curYaw
		STATE.turnRate = lerp(STATE.turnRate, clamp(dyaw / math.max(dt, 0.01), -8, 8), clamp(dt * 10, 0, 1))

		STATE.walkBlend = lerp(STATE.walkBlend, clamp(speed / CONFIG.WALK_SPEED, 0, 1) * (isAir and 0 or 1), clamp(dt * 11, 0, 1))
		STATE.sprintBlend = lerp(STATE.sprintBlend, (sprinting and speed > CONFIG.WALK_SPEED + 1 and not isAir) and clamp((speed - CONFIG.WALK_SPEED) / math.max(1, CONFIG.SPRINT_SPEED - CONFIG.WALK_SPEED), 0, 1) or 0, clamp(dt * 10, 0, 1))
		STATE.airBlend = lerp(STATE.airBlend, isAir and 1 or 0, clamp(dt * 12, 0, 1))

		local moveWeight = clamp(speed / CONFIG.WALK_SPEED, 0, 1) * (isAir and 0 or 1)
		if moveWeight > 0.05 and not STATE.slide.active then
			STATE.walkCycle += dt * (8.8 + STATE.sprintBlend * 5.2) * clamp(speed / CONFIG.WALK_SPEED, 0.4, 1.8)
		end
		local sinW, cosW = math.sin(STATE.walkCycle), math.cos(STATE.walkCycle)

		if CONFIG.FOOTSTEP_SFX and moveWeight > 0.35 and not isAir and not STATE.slide.active and ((STATE.prevWalkSin < 0 and sinW >= 0) or (STATE.prevWalkSin > 0 and sinW <= 0)) then
			playSFX("STEP", 1.55 + STATE.sprintBlend * 0.25 + (math.random() * 0.1 - 0.05), 0.75)
		end
		STATE.prevWalkSin = sinW

		local cam = workspace.CurrentCamera
		local headReal = c:FindFirstChild("Head")
		local inFP = cam and headReal and ((cam.CFrame.Position - headReal.Position).Magnitude < CONFIG.FIRST_PERSON_HIDE_DIST) or false

		if CONFIG.ENABLE_FOV_KICK and cam then
			STATE.fovKick = math.max(0, STATE.fovKick - dt * 26)
			STATE.camShake = math.max(0, STATE.camShake - dt * 3.5)
			local targetFOV = CONFIG.BASE_FOV + STATE.sprintBlend * 6 + (STATE.slide.active and 5 or 0) + STATE.fovKick
			cam.FieldOfView = lerp(cam.FieldOfView, targetFOV, clamp(dt * 14, 0, 1))
			if STATE.camShake > 0.01 then
				hum.CameraOffset = V((math.random() - 0.5) * STATE.camShake * 0.45, (math.random() - 0.5) * STATE.camShake * 0.45, 0)
			elseif math.abs(hum.CameraOffset.Y - (CONFIG.SCALE - 1.0) * 1.45) > 0.01 then
				hum.CameraOffset = V(0, (CONFIG.SCALE - 1.0) * 1.45, 0)
			end
		end

		if STATE.dash.active then
			local dEl = nowClock - STATE.dash.startTime
			if dEl < CONFIG.DASH_DURATION then
				local t = dEl / CONFIG.DASH_DURATION
				local curDashSpd = lerp(CONFIG.DASH_SPEED, CONFIG.SPRINT_SPEED, t * t)
				hrp.AssemblyLinearVelocity = V(STATE.dash.dir.X * curDashSpd, math.max(hrp.AssemblyLinearVelocity.Y * 0.15, 0), STATE.dash.dir.Z * curDashSpd)
			else
				STATE.dash.active = false
				hrp.AssemblyLinearVelocity = V(STATE.dash.dir.X * CONFIG.SPRINT_SPEED, hrp.AssemblyLinearVelocity.Y, STATE.dash.dir.Z * CONFIG.SPRINT_SPEED)
			end
		end

		if STATE.slide.active then
			local sEl = nowClock - STATE.slide.startTime
			if sEl < CONFIG.SLIDE_DURATION and not isAir then
				hrp.AssemblyLinearVelocity = V(STATE.slide.dir.X * CONFIG.SLIDE_SPEED, vel.Y, STATE.slide.dir.Z * CONFIG.SLIDE_SPEED)
			else
				STATE.slide.active = false
			end
		end

		STATE.fpArms = inFP and (not STATE.fpHideArms)
		for _, entry in ipairs(STATE.hiddenRealParts) do
			if entry.part and entry.part.Parent then entry.part.LocalTransparencyModifier = 1 end
		end

		local hudStatus, cfs = CHAR_DEF.stepCharacter(Core, c, hrp, hum, dt, {
			now = nowClock, inFP = inFP, cam = cam, isAir = isAir, sinW = sinW, cosW = cosW, sprinting = sprinting,
		})

		if cfs then
			for _, acc in ipairs(STATE.proxyAccessories) do
				local limbCF = cfs[acc.limbName]
				if acc.part and acc.part.Parent and limbCF then
					acc.targetCF = limbCF * acc.relCF
					acc.part.CFrame = acc.targetCF
					acc.part.LocalTransparencyModifier = inFP and 1 or 0
				end
			end
		end

		-- Animação dos feixes e efeitos compartilhados
		local ba = STATE.beamAnim
		if ba.active and STATE.beam1Part and STATE.beam2Part then
			local bEl = nowClock - ba.startTime
			if bEl < ba.duration then
				local k = easeOutQuad(bEl / ba.duration)
				local s1 = lerp(ba.w1, 0.02, k)
				local s2 = lerp(ba.w2, 0.03, k)
				if STATE.beam1Part.part and STATE.beam1Part.part.Parent then
					STATE.beam1Part.part.Size = V(s1, s1, ba.len1)
					STATE.beam1Part.part.CFrame = ba.cf1
					STATE.beam1Part.part.Transparency = ba.hideBeam1 and 1 or lerp(0.15, 0.96, k)
				end
				if STATE.beam2Part.part and STATE.beam2Part.part.Parent then
					STATE.beam2Part.part.Size = V(s2, s2, ba.len2)
					STATE.beam2Part.part.CFrame = ba.cf2
					STATE.beam2Part.part.Transparency = lerp(0.20, 0.96, k)
				end
				if STATE.beamCore1Part and STATE.beamCore1Part.part and STATE.beamCore1Part.part.Parent then
					STATE.beamCore1Part.part.Size = V(s1 * 0.42, s1 * 0.42, ba.len1)
					STATE.beamCore1Part.part.CFrame = ba.cf1
					STATE.beamCore1Part.part.Transparency = ba.hideBeam1 and 1 or lerp(0, 0.98, k)
				end
				if STATE.beamCore2Part and STATE.beamCore2Part.part and STATE.beamCore2Part.part.Parent then
					STATE.beamCore2Part.part.Size = V(s2 * 0.42, s2 * 0.42, ba.len2)
					STATE.beamCore2Part.part.CFrame = ba.cf2
					STATE.beamCore2Part.part.Transparency = lerp(0, 0.98, k)
				end
			else
				ba.active = false
				local hideList = {}
				for _, fx in ipairs({ STATE.beam1Part, STATE.beam2Part, STATE.beamCore1Part, STATE.beamCore2Part }) do
					if fx and fx.part then
						fx.targetCF, fx.part.CFrame = PARK_CF, PARK_CF
						hideList[#hideList + 1] = { Part = fx.part, Transparency = 1 }
					end
				end
				syncPartMaterial(hideList)
			end
		end

		local fa = STATE.flashAnim
		if fa.active and STATE.flashPart and STATE.flashPart.part and STATE.flashPart.part.Parent then
			local fEl = nowClock - fa.startTime
			if fEl < fa.duration then
				local k = easeOutQuad(fEl / fa.duration)
				local sz = lerp(fa.startSize, fa.endSize, k)
				STATE.flashPart.part.Size = V(sz, sz, sz)
				STATE.flashPart.part.Transparency = lerp(0.1, 0.95, k)
				STATE.flashPart.part.CFrame = C(fa.pos)
			else
				fa.active = false
				STATE.flashPart.targetCF, STATE.flashPart.part.CFrame = PARK_CF, PARK_CF
				syncPartMaterial({ { Part = STATE.flashPart.part, Transparency = 1 } })
			end
		end

		local ia = STATE.impactAnim
		if ia.active and STATE.impactPart and STATE.impactPart.part and STATE.impactPart.part.Parent then
			local iEl = nowClock - ia.startTime
			if iEl < ia.duration then
				local k = easeOutQuad(iEl / ia.duration)
				local sz = lerp(ia.startSize, ia.endSize, k)
				STATE.impactPart.part.Size = V(sz, sz, sz)
				STATE.impactPart.part.Transparency = lerp(0.05, 0.95, k)
				STATE.impactPart.part.CFrame = C(ia.pos)
			else
				ia.active = false
				STATE.impactPart.targetCF, STATE.impactPart.part.CFrame = PARK_CF, PARK_CF
				syncPartMaterial({ { Part = STATE.impactPart.part, Transparency = 1 } })
			end
		end

		local ra = STATE.ringAnim
		if ra.active and STATE.ringPart and STATE.ringPart.part and STATE.ringPart.part.Parent then
			local rEl = nowClock - ra.startTime
			if rEl < ra.duration then
				local k = easeOutQuad(rEl / ra.duration)
				local radSz = lerp(ra.startRadius, ra.endRadius, k)
				STATE.ringPart.part.Size = V(0.14, radSz, radSz)
				STATE.ringPart.part.Transparency = lerp(0.1, 0.96, k)
				STATE.ringPart.part.CFrame = ra.cf
			else
				ra.active = false
				STATE.ringPart.targetCF, STATE.ringPart.part.CFrame = PARK_CF, PARK_CF
				syncPartMaterial({ { Part = STATE.ringPart.part, Transparency = 1 } })
			end
		end

		updateHUD(hum, hrp, dt, hudStatus)
		if not inHitstop then stepTargetRagdolls(dt) end
		local syncNow = os.clock()
		dispatchF3X(syncNow)
		dispatchTargetF3X(syncNow)
	end)

	table.insert(STATE.connections, UIS.InputBegan:Connect(function(inp, gp)
		if UIS:GetFocusedTextBox() then return end
		if inp.KeyCode == Enum.KeyCode.F6 then
			cleanup()
			return
		elseif inp.KeyCode == Enum.KeyCode.F7 then
			forceRebuild()
			return
		end

		if gp or GuiService.MenuIsOpen or not (STATE and STATE.alive) then return end
		if inp.KeyCode == Enum.KeyCode.Q then
			Core.triggerDash()
		elseif inp.KeyCode == Enum.KeyCode.C or inp.KeyCode == Enum.KeyCode.LeftControl then
			Core.triggerSlideOrSlam()
		elseif inp.KeyCode == Enum.KeyCode.E then
			if CHAR_DEF and CHAR_DEF.onPrimary then CHAR_DEF.onPrimary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.F then
			if CHAR_DEF and CHAR_DEF.onSecondary then CHAR_DEF.onSecondary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.R then
			if CHAR_DEF and CHAR_DEF.onTertiary then CHAR_DEF.onTertiary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.X then
			STATE.fpHideArms = not STATE.fpHideArms
			local hint = STATE.hud.hint
			if hint then
				hint.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
				hint.TextColor3 = STATE.fpHideArms and CONFIG.BEAM_CYAN or CONFIG.HUD_WEAPON_COLOR
			end
		end
	end))

	table.insert(STATE.connections, plr.CharacterAdded:Connect(function()
		if not STATE then return end
		STATE.setupId += 1
		STATE.isSettingUp = false
		STATE.inFlight, STATE.lastSendAt = 0, 0
		STATE.targetInFlight, STATE.targetLastSendAt = 0, 0
		STATE.ramBusy, STATE.seatBusy = false, false
		STATE.walkBlend, STATE.sprintBlend, STATE.airBlend = 0, 0, 0
		STATE.slide.active, STATE.slam.active = false, false
		clearCharConnections()
		clearProxyConnections()
		restoreAllRagdolls()
		if STATE.alive then task.spawn(setupRig) end
	end))
end

return Core