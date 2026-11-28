-- F3X / FORK3X ULTRAKILL CORE ENGINE (R6 + R15 | PC + MOBILE)
-- Motor completo compartilhado (F3X Sync com seq/ack, HUD autentico estilo ULTRAKILL, Controles Mobile, Abate F3X por remocao de Torso & Movimento Aereo)

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

local USER_ID_NUM = plr and plr.UserId or 0
local USER_TAG_PREFIX = "UKF3X_" .. tostring(USER_ID_NUM) .. "_"

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

local function sanitizeTagLabel(label)
	local raw = tostring(label or "PART"):gsub("[^%w_%-]", "_")
	if raw == "" then raw = "PART" end
	if #raw > 28 then raw = raw:sub(1, 28) end
	return raw
end

local function makeUserPartName(label)
	return USER_TAG_PREFIX .. sanitizeTagLabel(label)
end

local function parseUserTag(name)
	if type(name) ~= "string" then return nil, nil end
	local uidStr, label = name:match("^UKF3X_(%-?%d+)_(.+)$")
	if not uidStr then return nil, nil end
	return tonumber(uidStr), label
end

local Core = {
	C = C,
	V = V,
	ID_CF = ID_CF,
	PARK_CF = PARK_CF,
	USER_TAG_PREFIX = USER_TAG_PREFIX,
	rad = rad,
	clamp = clamp,
	lerp = lerp,
	easeOutQuad = easeOutQuad,
	easeOutBack = easeOutBack,
	angles = angles,
	mirrorRelCF = mirrorRelCF,
	makeUserPartName = makeUserPartName,
	parseUserTag = parseUserTag,
}

function Core.getUserTagPrefix()
	return USER_TAG_PREFIX
end

-- ============================================================================
-- PONTE DE PROTECAO PARA O ANTIGRIEF.LUA (SEM DEPENDER DO LOADER.LUA)
-- ============================================================================
local function getAG()
	local ag = env.ULTRAKILL_ANTIGRIEF or _G.ULTRAKILL_ANTIGRIEF
	if type(ag) == "table" then
		return ag
	end
	return nil
end

local function agMarkGrace(seconds)
	local ag = getAG()
	if ag and type(ag.markRigDeployGrace) == "function" then
		pcall(ag.markRigDeployGrace, seconds)
	end
end

local function agEndGrace()
	local ag = getAG()
	if ag and type(ag.endRigDeployGrace) == "function" then
		pcall(ag.endRigDeployGrace)
	end
end

local function agProtect(target)
	local ag = getAG()
	if not (ag and type(ag.protectInstance) == "function" and target) then return end
	if typeof(target) == "Instance" then
		pcall(ag.protectInstance, target)
	elseif type(target) == "table" then
		for _, item in pairs(target) do
			if typeof(item) == "Instance" then
				pcall(ag.protectInstance, item)
			end
		end
	end
end

local function agUnprotect(target)
	local ag = getAG()
	if not (ag and type(ag.unprotectInstance) == "function" and target) then return end
	if typeof(target) == "Instance" then
		pcall(ag.unprotectInstance, target)
	elseif type(target) == "table" then
		for _, item in pairs(target) do
			if typeof(item) == "Instance" then
				pcall(ag.unprotectInstance, item)
			end
		end
	end
end

local function agClearProtected()
	local ag = getAG()
	if ag and type(ag.clearProtectedRig) == "function" then
		pcall(ag.clearProtectedRig)
	end
end

function Core.protectInstance(inst)
	agProtect(inst)
end

-- ============================================================================
-- CONFIGURACAO PADRAO DO MOTOR
-- ============================================================================
local DEFAULT_CONFIG = {
	RENDER_NAME = "F3X_Ultrakill_Reanim",
	HUD_RENDER_NAME = "F3X_Ultrakill_3DHUD",
	FIRST_PERSON_HIDE_DIST = 1.95,
	HIDE_ALL_AVATAR_ACCESSORIES = true,
	SCALE = 1.0,
	SOLE_DEPTH = 3.66,

	ENABLE_SPRINT = true,
	WALK_SPEED = 18,
	SPRINT_SPEED = 34,

	ENABLE_AIR_MOVEMENT = true,
	JUMP_POWER = 54,
	AIR_GRAVITY_CANCEL = 0.42,
	GLIDE_GRAVITY_CANCEL = 0.74,
	GLIDE_MAX_FALL = 16,
	AIR_STRAFE_ACCEL = 52,
	AIR_DRAG = 0.28,
	DASH_JUMP_MULT = 0.94,
	WALL_JUMP_ENABLED = true,
	MAX_WALL_JUMPS = 3,
	WALL_JUMP_UP = 58,
	WALL_JUMP_PUSH = 44,
	WALL_DETECT_DIST = 3.8,
	SLAM_STORAGE_WINDOW = 0.20,
	SLAM_STORAGE_JUMP = 108,

	ENABLE_DASH = true,
	DASH_COOLDOWN = 0.25,
	DASH_DURATION = 0.22,
	DASH_SPEED = 72,
	MAX_STAMINA = 3,
	STAMINA_REGEN_TIME = 1.25,

	ENABLE_SLIDE_SLAM = true,
	SLIDE_SPEED = 46,
	SLIDE_DURATION = 0.55,
	SLIDE_COOLDOWN = 0.55,
	SLAM_SPEED = 105,
	SLAM_MIN_HEIGHT = 6,
	SLAM_RANGE = 13.5,

	ENABLE_FOV_KICK = true,
	BASE_FOV = 70,

	YELLOW_NEON = Color3.fromRGB(255, 224, 61),
	MARKSMAN_GREEN = Color3.fromRGB(68, 255, 68),
	COIN_GOLD = Color3.fromRGB(255, 224, 61),
	BEAM_CYAN = Color3.fromRGB(63, 232, 255),
	BEAM_CORE = Color3.fromRGB(255, 255, 255),
	PARRY_FLASH = Color3.fromRGB(255, 245, 175),
	BLOOD_RED = Color3.fromRGB(210, 18, 24),

	ENABLE_HEAD_AIM_TRACKING = true,
	FOOTSTEP_SFX = true,
	ENABLE_BGM = true,
	BGM_URL = "",
	BGM_FILE = "ultrakill_bgm.mp3",
	BGM_FALLBACK_ID = "",
	BGM_VOLUME = 0.40,
	BGM_PITCH = 1.0,
	BGM_MUTED = false,
	ENABLE_HUD = true,
	HUD_BG_TRANSPARENCY = 0.48,
	SHOW_SPEEDOMETER = true,

	HUD_UNIT_HEADER = "V1",
	HUD_WEAPON_TITLE = "MARKSMAN",
	HUD_WEAPON_COLOR = Color3.fromRGB(68, 255, 68),
	HUD_ARM_COLOR = Color3.fromRGB(48, 170, 255),
	HUD_KEY_HINT = "[Q] DASH  [C] SLAM/SLIDE  [E] COIN  [F] PARRY",
	HUD_PIP_COLOR = Color3.fromRGB(255, 224, 61),
	MOBILE_PRIMARY_LABEL = "COIN",
	MOBILE_PRIMARY_COLOR = Color3.fromRGB(255, 224, 61),
	MOBILE_SECONDARY_LABEL = "PARRY",
	MOBILE_SECONDARY_COLOR = Color3.fromRGB(255, 245, 175),
	MOBILE_TERTIARY_LABEL = "SWAP",
	MOBILE_TERTIARY_COLOR = Color3.fromRGB(255, 185, 65),

	SOUNDS = {
		PARRY     = { id = "rbxassetid://98660468032974",  fallbackId = "rbxasset://sounds/electronicpingshort.wav",    volume = 0.95, pitch = 1.00 },
		COIN_FLIP = { id = "rbxassetid://132653076390131", fallbackId = "rbxasset://sounds/electronicpingshort.wav",    volume = 0.75, pitch = 1.55 },
		SHATTER   = { id = "rbxassetid://17405655409",     fallbackId = "rbxasset://sounds/snap.mp3",                   volume = 0.80, pitch = 1.15 },
		PUNCH     = { id = "rbxassetid://140626490819228", fallbackId = "rbxasset://sounds/hit.wav",                    volume = 0.78, pitch = 1.05 },
		DASH      = { id = "rbxassetid://6870002465",      fallbackId = "rbxasset://sounds/action_jump.mp3",            volume = 0.58, pitch = 1.15 },
		LAND      = { id = "rbxassetid://6870001600",      fallbackId = "rbxasset://sounds/action_jump_land.mp3",       volume = 0.45, pitch = 1.10 },
		STEP      = { id = "rbxassetid://6870002623",      fallbackId = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 0.16, pitch = 1.65 },
	},

	MAX_CREATE_WORKERS = 20,
	MAX_IN_FLIGHT = 1,
	SEND_INTERVAL = 0.055,
	POS_EPS = 0.055,
	ROT_EPS_DEG = 2.2,
	SYNC_CHUNK = 120,
	DISABLE_FALLING_DOWN = true,
	IDLE_TILT_GUARD = true,

	-- Mantidos por compatibilidade com modulos de personagem; acoes usam abate direto por remocao de torso
	ENABLE_KNOCKBACK = true,
	ENABLE_TORSO_KILL = true,
	KILL_DEBOUNCE = 0.45,
	MULTIKILL_WINDOW = 1.25,
	PARRY_KNOCKBACK_POWER = { speed = 68, up = 32, spin = 12.0 },
	SLAM_KNOCKBACK_POWER = { speed = 42, up = 44, spin = 11.0 },
	ENABLE_DAMAGE_FLASH = true,
	DAMAGE_FLASH_PULSE_COLOR = Color3.fromRGB(255, 145, 145),
	DAMAGE_FLASH_COLOR = Color3.fromRGB(255, 30, 30),
	DAMAGE_FLASH_DURATION = 0.24,
}

-- Cores oficiais do HUD do ULTRAKILL
local UK_COLOR = {
	Health = Color3.fromRGB(255, 0, 0),
	HealthBack = Color3.fromRGB(48, 8, 10),
	HealthNum = Color3.fromRGB(255, 255, 255),
	SoftDamage = Color3.fromRGB(255, 99, 0),
	HardDamage = Color3.fromRGB(89, 89, 89),
	Overheal = Color3.fromRGB(0, 255, 0),
	StaminaFull = Color3.fromRGB(13, 223, 240),
	StaminaCharge = Color3.fromRGB(3, 137, 156),
	StaminaEmpty = Color3.fromRGB(255, 0, 0),
	RailFull = Color3.fromRGB(63, 232, 255),
	RailCharge = Color3.fromRGB(255, 0, 0),
	PanelBg = Color3.new(0, 0, 0),
	TrackBg = Color3.fromRGB(20, 20, 22),
	TextMain = Color3.fromRGB(245, 245, 245),
	TextDim = Color3.fromRGB(165, 170, 178),
}

-- Ranks oficiais de estilo (limites, decaimento por segundo e acelerador de Hard Damage)
local STYLE_RANKS = {
	{ min = 0,    max = 200,  prefix = "D",         rest = "ESTRUCTIVE", decay = 15.0,  hdRate = 1.0, color = Color3.fromRGB(38, 155, 255) },
	{ min = 200,  max = 500,  prefix = "C",         rest = "HAOTIC",     decay = 18.75, hdRate = 1.0, color = Color3.fromRGB(68, 255, 68) },
	{ min = 500,  max = 900,  prefix = "B",         rest = "RUTAL",      decay = 22.5,  hdRate = 1.0, color = Color3.fromRGB(255, 224, 61) },
	{ min = 900,  max = 1400, prefix = "A",         rest = "NARCHIC",    decay = 30.0,  hdRate = 1.0, color = Color3.fromRGB(255, 138, 34) },
	{ min = 1400, max = 2100, prefix = "S",         rest = "UPREME",     decay = 45.0,  hdRate = 2.0, color = Color3.fromRGB(255, 48, 48) },
	{ min = 2100, max = 2950, prefix = "SS",        rest = "ADISTIC",    decay = 60.0,  hdRate = 2.5, color = Color3.fromRGB(255, 34, 34) },
	{ min = 2950, max = 3950, prefix = "SSS",       rest = "HITSTORM",   decay = 90.0,  hdRate = 3.0, color = Color3.fromRGB(255, 18, 24) },
	{ min = 3950, max = 5450, prefix = "ULTRAKILL", rest = "",           decay = 120.0, hdRate = 99,  color = Color3.fromRGB(255, 232, 64) },
}

local STATE, CONFIG, CHAR_DEF = nil, nil, nil
local cleanup, forceRebuild, setupRig, buildExcludeRayParams

local function getChar() return plr.Character end

local function getF3XEndpoint()
	local c, bp = getChar(), plr:FindFirstChild("Backpack")
	local t = (c and c:FindFirstChild("Building Tools+"))
		or (bp and bp:FindFirstChild("Building Tools+"))
		or (c and c:FindFirstChild("Building Tools"))
		or (bp and bp:FindFirstChild("Building Tools"))
	local api = t and (t:FindFirstChild("SyncAPI") or t:FindFirstChild("SyncApi"))
	return api and (api:FindFirstChild("ServerEndpoint") or api:FindFirstChild("ServerControl"))
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
	size = math.max(1, math.floor(size or 120))
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
	local workers = math.min(maxWorkers or (CONFIG and CONFIG.MAX_CREATE_WORKERS) or 20, total)
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

-- Marca partes criadas com o identificador multiusuario UKF3X_<UserId>_<Label>
function Core.tagPart(target, label)
	if not target then return end
	local nameList = {}
	local defaultTag = makeUserPartName(label or "PART")

	if typeof(target) == "Instance" then
		if target:IsA("BasePart") then
			local uid = parseUserTag(target.Name)
			if uid ~= USER_ID_NUM then
				pcall(function() target.Name = defaultTag end)
				nameList[#nameList + 1] = { Part = target, Name = defaultTag }
			end
		end
	elseif type(target) == "table" then
		for _, item in pairs(target) do
			if typeof(item) == "Instance" and item:IsA("BasePart") then
				local uid = parseUserTag(item.Name)
				if uid ~= USER_ID_NUM then
					local tagName = label and defaultTag or makeUserPartName(item.Name)
					pcall(function() item.Name = tagName end)
					nameList[#nameList + 1] = { Part = item, Name = tagName }
				end
			end
		end
	end

	if #nameList == 0 then return end
	local ep = Core.getEndpoint()
	if not ep then return end

	task.spawn(function()
		local chunkSize = (CONFIG and CONFIG.SYNC_CHUNK) or 120
		for _, ch in ipairs(chunked(nameList, chunkSize)) do
			if ep and ep.Parent then
				f3x(ep, "SetName", ch)
			end
		end
	end)
end

-- Protege e etiqueta automaticamente qualquer part/clone criado por scripts de personagem via Core.f3x
function Core.f3x(cmd, ...)
	local isSpawnCmd = (cmd == "CreatePart" or cmd == "Clone")
	if isSpawnCmd then
		agMarkGrace(1.5)
	end
	local ok, res = f3x(Core.getEndpoint(), cmd, ...)
	if isSpawnCmd and ok and res then
		agProtect(res)
		Core.tagPart(res, (cmd == "Clone") and "CLONE" or "FX")
	end
	return ok, res
end

-- ============================================================================
-- RASTREADOR DE ALVOS (PLAYERS E NPCS)
-- ============================================================================
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
		or char:FindFirstChild("LowerTorso")
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

buildExcludeRayParams = function(extraChar)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	local c = getChar()
	if c then ignore[#ignore + 1] = c end
	if extraChar and extraChar ~= c then ignore[#ignore + 1] = extraChar end
	if STATE then
		for _, pp in ipairs(STATE.proxyParts) do
			if pp and pp.Parent then ignore[#ignore + 1] = pp end
		end
	end
	rp.FilterDescendantsInstances = ignore
	rp.IgnoreWater = true
	return rp
end

-- ============================================================================
-- SISTEMA DE AUDIO E BGM (COM FALLBACK NATIVO)
-- ============================================================================
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
		if hrp then
			parentTarget = hrp
			agProtect(snd)
		end
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

local activeBGM = nil
local getAssetFn = getcustomasset or getsynasset

local function stopBGM()
	if activeBGM then
		pcall(function()
			activeBGM:Stop()
			activeBGM:Destroy()
		end)
		activeBGM = nil
	end
end

local function loadCustomAudioAsset(url, fileName, fallbackId)
	if url and url ~= "" and getAssetFn and writefile and isfile then
		local folder = "ultrakill_f3x_audio"
		if makefolder and isfolder and not isfolder(folder) then
			pcall(makefolder, folder)
		end
		local path = folder .. "/" .. (fileName or "bgm.mp3")

		if not isfile(path) then
			local ok, raw = pcall(function()
				return game:HttpGet(url, true)
			end)
			if ok and type(raw) == "string" and #raw > 1024 then
				pcall(writefile, path, raw)
			end
		end

		if isfile(path) then
			local okAsset, assetId = pcall(getAssetFn, path)
			if okAsset and type(assetId) == "string" and assetId ~= "" then
				return assetId
			end
		end
	end
	return fallbackId
end

local function startBGM(url, fileName, fallbackId, vol, pitch)
	stopBGM()
	if not CONFIG.ENABLE_BGM then return end

	task.spawn(function()
		local soundId = loadCustomAudioAsset(url, fileName, fallbackId)
		if not soundId or soundId == "" or not STATE or not STATE.alive then return end

		local snd = Instance.new("Sound")
		snd.Name = "F3X_Ultrakill_BGM"
		snd.SoundId = soundId
		snd.Looped = true
		snd.Volume = CONFIG.BGM_MUTED and 0 or (vol or CONFIG.BGM_VOLUME or 0.40)
		snd.PlaybackSpeed = pitch or CONFIG.BGM_PITCH or 1.0
		snd.Parent = SoundService
		activeBGM = snd

		pcall(function() ContentProvider:PreloadAsync({ snd }) end)
		if activeBGM == snd and STATE and STATE.alive then
			snd:Play()
		end
	end)
end

local function toggleBGMMute()
	CONFIG.BGM_MUTED = not CONFIG.BGM_MUTED
	if activeBGM then
		activeBGM.Volume = CONFIG.BGM_MUTED and 0 or (CONFIG.BGM_VOLUME or 0.40)
	end
end

Core.startBGM = startBGM
Core.stopBGM = stopBGM
Core.toggleBGMMute = toggleBGMMute

-- ============================================================================
-- HUD AUTENTICO ESTILO ULTRAKILL (PAINEIS 3D + CROSSHAIR HUD + MOBILE)
-- ============================================================================
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
		STATE.hud.hpFill, STATE.hud.softDmgFill, STATE.hud.hardDmgFill, STATE.hud.overhealFill, STATE.hud.hpText = nil, nil, nil, nil, nil
		STATE.hud.speedBox, STATE.hud.speedLabel = nil, nil
		STATE.hud.stamBars, STATE.hud.coinPips = {}, {}
		STATE.hud.railFill, STATE.hud.armBarFill, STATE.hud.armIconWrap, STATE.hud.armAccent = nil, nil, nil, nil
		STATE.hud.rankLabel, STATE.hud.rankBarFill, STATE.hud.multLabel, STATE.hud.multBarFill, STATE.hud.freshLabel = nil, nil, nil, nil, nil
		STATE.hud.styleFeed, STATE.hud.rightFrame, STATE.hud.hitmarker, STATE.hud.hint = nil, nil, nil, nil
		STATE.hud.wpnTitle, STATE.hud.wpnAccent, STATE.hud.wpnBox, STATE.hud.helpPanel = nil, nil, nil, nil
		STATE.hud.crossHpFill, STATE.hud.crossSoftFill, STATE.hud.crossHardFill, STATE.hud.crossStamBars = nil, nil, nil, {}
		STATE.hud.crossHudLeft, STATE.hud.crossHudRight = nil, nil
		STATE.hud.styleFeedEntries = {}
	end
end

local function triggerHUDArmPulse()
	if not STATE then return end
	STATE.hud.armPulseUntil = os.clock() + 0.36
	STATE.hud.crossHudActiveUntil = os.clock() + 1.15
end

local function triggerHUDWeaponPulse()
	if not STATE then return end
	STATE.hud.wpnPulseUntil = os.clock() + 0.16
	STATE.hud.crossHudActiveUntil = os.clock() + 1.15
end

local function addStyleBonus(label, pts, color)
	if not (STATE and CONFIG and CONFIG.ENABLE_HUD) then return end
	local h = STATE.hud
	local gained = math.floor((pts or 100) * h.styleMult)
	h.stylePoints = clamp(h.stylePoints + gained, 0, STYLE_RANKS[#STYLE_RANKS].max)
	h.stylePop = 1.0
	h.hitmarkerUntil = os.clock() + 0.15

	local cleanLabel = tostring(label):gsub("^%+*%s*", "")
	table.insert(h.styleFeedEntries, 1, {
		text = "+ " .. cleanLabel,
		color = color or UK_COLOR.TextMain,
		expires = os.clock() + 3.2,
	})
	if #h.styleFeedEntries > 7 then table.remove(h.styleFeedEntries) end
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

local function makeUKBox(parent, size, pos, bgTrans)
	local box = Instance.new("Frame")
	box.Size = size
	box.Position = pos
	box.BackgroundColor3 = UK_COLOR.PanelBg
	box.BackgroundTransparency = bgTrans or CONFIG.HUD_BG_TRANSPARENCY or 0.48
	box.BorderSizePixel = 0
	box.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box
	return box
end

local function buildWeaponGlyph(parent, accentCol)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(78, 36)
	wrap.Position = UDim2.new(1, -88, 0, 12)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parent

	local parts = {
		{ UDim2.fromOffset(44, 10), UDim2.fromOffset(18, 4),  0, accentCol },
		{ UDim2.fromOffset(22, 12), UDim2.fromOffset(18, 12), 0, Color3.fromRGB(228, 232, 238) },
		{ UDim2.fromOffset(14, 10), UDim2.fromOffset(6, 8),   0, Color3.fromRGB(195, 200, 210) },
		{ UDim2.fromOffset(10, 18), UDim2.fromOffset(4, 14), 16, Color3.fromRGB(180, 185, 195) },
		{ UDim2.fromOffset(16, 4),  UDim2.fromOffset(44, 13), 0, accentCol },
	}
	for _, p in ipairs(parts) do
		local f = Instance.new("Frame")
		f.Size = p[1]
		f.Position = p[2]
		f.Rotation = p[3]
		f.BackgroundColor3 = p[4]
		f.BorderSizePixel = 0
		f.Parent = wrap
	end
	return wrap
end

local function buildArmGlyph(parent, armCol)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(58, 76)
	wrap.Position = UDim2.new(0.5, -29, 0, 22)
	wrap.BackgroundTransparency = 1
	wrap.Parent = parent

	local segs = {
		{ UDim2.fromOffset(22, 12), UDim2.fromOffset(18, 52), 0, Color3.fromRGB(45, 72, 128) },
		{ UDim2.fromOffset(28, 28), UDim2.fromOffset(15, 26), 0, armCol },
		{ UDim2.fromOffset(8, 18),  UDim2.fromOffset(12, 8), -8, Color3.fromRGB(125, 215, 255) },
		{ UDim2.fromOffset(8, 22),  UDim2.fromOffset(22, 4),  0, Color3.fromRGB(125, 215, 255) },
		{ UDim2.fromOffset(8, 20),  UDim2.fromOffset(32, 6),  4, Color3.fromRGB(125, 215, 255) },
		{ UDim2.fromOffset(12, 8),  UDim2.fromOffset(40, 28), -22, Color3.fromRGB(95, 190, 255) },
	}
	for _, s in ipairs(segs) do
		local f = Instance.new("Frame")
		f.Size = s[1]
		f.Position = s[2]
		f.Rotation = s[3]
		f.BackgroundColor3 = s[4]
		f.BorderSizePixel = 0
		f.Parent = wrap
	end
	return wrap
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

	local leftPart = makeHUDPanelPart(folder, "V1_HUD_Left", V(2.26, 1.32, 0.05))
	local rightPart = makeHUDPanelPart(folder, "V1_HUD_Right", V(1.92, 1.72, 0.05))
	STATE.hud.leftPart, STATE.hud.rightPart = leftPart, rightPart

	local leftGui = Instance.new("SurfaceGui")
	leftGui.Name = "F3XV1_3DHUD_Left"
	leftGui.Adornee = leftPart
	leftGui.Face = Enum.NormalId.Front
	leftGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	leftGui.CanvasSize = Vector2.new(620, 362)
	leftGui.AlwaysOnTop = true
	leftGui.LightInfluence = 0
	leftGui.ResetOnSpawn = false
	leftGui.Parent = pg
	STATE.hud.leftGui = leftGui

	local lFrame = Instance.new("Frame")
	lFrame.Size = UDim2.fromScale(1, 1)
	lFrame.BackgroundTransparency = 1
	lFrame.BorderSizePixel = 0
	lFrame.Parent = leftGui

	local hpBox = makeUKBox(lFrame, UDim2.fromOffset(620, 68), UDim2.fromOffset(0, 0))

	local hpTrack = Instance.new("Frame")
	hpTrack.Size = UDim2.new(1, -12, 1, -12)
	hpTrack.Position = UDim2.fromOffset(6, 6)
	hpTrack.BackgroundColor3 = UK_COLOR.HealthBack
	hpTrack.BorderSizePixel = 0
	hpTrack.ClipsDescendants = true
	hpTrack.Parent = hpBox

	local softDmgFill = Instance.new("Frame")
	softDmgFill.Size = UDim2.fromScale(1, 1)
	softDmgFill.BackgroundColor3 = UK_COLOR.SoftDamage
	softDmgFill.BorderSizePixel = 0
	softDmgFill.ZIndex = 2
	softDmgFill.Parent = hpTrack
	STATE.hud.softDmgFill = softDmgFill

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = UK_COLOR.Health
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 3
	hpFill.Parent = hpTrack
	STATE.hud.hpFill = hpFill

	local overhealFill = Instance.new("Frame")
	overhealFill.Size = UDim2.fromScale(0, 1)
	overhealFill.BackgroundColor3 = UK_COLOR.Overheal
	overhealFill.BorderSizePixel = 0
	overhealFill.Visible = false
	overhealFill.ZIndex = 4
	overhealFill.Parent = hpTrack
	STATE.hud.overhealFill = overhealFill

	local hardDmgFill = Instance.new("Frame")
	hardDmgFill.AnchorPoint = Vector2.new(1, 0)
	hardDmgFill.Position = UDim2.fromScale(1, 0)
	hardDmgFill.Size = UDim2.fromScale(0, 1)
	hardDmgFill.BackgroundColor3 = UK_COLOR.HardDamage
	hardDmgFill.BorderSizePixel = 0
	hardDmgFill.ZIndex = 5
	hardDmgFill.Parent = hpTrack
	STATE.hud.hardDmgFill = hardDmgFill

	local hdEdge = Instance.new("Frame")
	hdEdge.Size = UDim2.new(0, 3, 1, 0)
	hdEdge.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
	hdEdge.BorderSizePixel = 0
	hdEdge.ZIndex = 6
	hdEdge.Parent = hardDmgFill

	local crossH = Instance.new("Frame")
	crossH.Size = UDim2.fromOffset(22, 6)
	crossH.Position = UDim2.fromOffset(14, 25)
	crossH.BackgroundColor3 = UK_COLOR.HealthNum
	crossH.BorderSizePixel = 0
	crossH.ZIndex = 7
	crossH.Parent = hpTrack

	local crossV = Instance.new("Frame")
	crossV.Size = UDim2.fromOffset(6, 22)
	crossV.Position = UDim2.fromOffset(22, 17)
	crossV.BackgroundColor3 = UK_COLOR.HealthNum
	crossV.BorderSizePixel = 0
	crossV.ZIndex = 7
	crossV.Parent = hpTrack

	local hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.new(1, -56, 1, 0)
	hpText.Position = UDim2.fromOffset(48, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBlack
	hpText.TextSize = 48
	hpText.TextXAlignment = Enum.TextXAlignment.Left
	hpText.TextColor3 = UK_COLOR.HealthNum
	hpText.TextStrokeTransparency = 0.65
	hpText.TextStrokeColor3 = Color3.new(0, 0, 0)
	hpText.Text = "100"
	hpText.ZIndex = 7
	hpText.Parent = hpTrack
	STATE.hud.hpText = hpText

	local stamBox = makeUKBox(lFrame, UDim2.fromOffset(620, 32), UDim2.fromOffset(0, 76))
	local segCount = math.max(1, CONFIG.MAX_STAMINA)
	local gap = 6
	local innerW = 620 - 12
	local segW = (innerW - (segCount - 1) * gap) / segCount

	for i = 1, segCount do
		local segTrack = Instance.new("Frame")
		segTrack.Size = UDim2.fromOffset(math.floor(segW), 20)
		segTrack.Position = UDim2.fromOffset(6 + math.floor((i - 1) * (segW + gap)), 6)
		segTrack.BackgroundColor3 = Color3.fromRGB(26, 14, 16)
		segTrack.BorderSizePixel = 0
		segTrack.Parent = stamBox

		local segFill = Instance.new("Frame")
		segFill.Size = UDim2.fromScale(1, 1)
		segFill.BackgroundColor3 = UK_COLOR.StaminaFull
		segFill.BorderSizePixel = 0
		segFill.Parent = segTrack
		STATE.hud.stamBars[i] = segFill
	end

	local wpnBox = makeUKBox(lFrame, UDim2.fromOffset(446, 164), UDim2.fromOffset(0, 116))
	STATE.hud.wpnBox = wpnBox

	local wpnAccent = Instance.new("Frame")
	wpnAccent.Size = UDim2.new(1, 0, 0, 5)
	wpnAccent.BackgroundColor3 = CONFIG.HUD_WEAPON_COLOR
	wpnAccent.BorderSizePixel = 0
	wpnAccent.Parent = wpnBox
	STATE.hud.wpnAccent = wpnAccent

	buildWeaponGlyph(wpnBox, CONFIG.HUD_WEAPON_COLOR)

	local wpnTitle = Instance.new("TextLabel")
	wpnTitle.Size = UDim2.new(1, -110, 0, 36)
	wpnTitle.Position = UDim2.fromOffset(14, 12)
	wpnTitle.BackgroundTransparency = 1
	wpnTitle.Font = Enum.Font.GothamBlack
	wpnTitle.TextSize = 24
	wpnTitle.TextXAlignment = Enum.TextXAlignment.Left
	wpnTitle.TextColor3 = CONFIG.HUD_WEAPON_COLOR
	wpnTitle.Text = CONFIG.HUD_WEAPON_TITLE
	wpnTitle.Parent = wpnBox
	STATE.hud.wpnTitle = wpnTitle

	for i = 1, 4 do
		local pipTrack = Instance.new("Frame")
		pipTrack.Size = UDim2.fromOffset(98, 28)
		pipTrack.Position = UDim2.fromOffset(14 + (i - 1) * 106, 62)
		pipTrack.BackgroundColor3 = UK_COLOR.TrackBg
		pipTrack.BorderSizePixel = 0
		pipTrack.Parent = wpnBox

		local pipFill = Instance.new("Frame")
		pipFill.Size = UDim2.fromScale(1, 1)
		pipFill.BackgroundColor3 = CONFIG.HUD_PIP_COLOR
		pipFill.BorderSizePixel = 0
		pipFill.Parent = pipTrack
		STATE.hud.coinPips[i] = pipFill
	end

	local railLabel = Instance.new("TextLabel")
	railLabel.Size = UDim2.new(1, -28, 0, 18)
	railLabel.Position = UDim2.fromOffset(14, 102)
	railLabel.BackgroundTransparency = 1
	railLabel.Font = Enum.Font.Code
	railLabel.TextSize = 14
	railLabel.TextXAlignment = Enum.TextXAlignment.Left
	railLabel.TextColor3 = UK_COLOR.TextDim
	railLabel.Text = "CHARGE"
	railLabel.Parent = wpnBox

	local railTrack = Instance.new("Frame")
	railTrack.Size = UDim2.new(1, -28, 0, 20)
	railTrack.Position = UDim2.fromOffset(14, 124)
	railTrack.BackgroundColor3 = UK_COLOR.TrackBg
	railTrack.BorderSizePixel = 0
	railTrack.Parent = wpnBox

	local railFill = Instance.new("Frame")
	railFill.Size = UDim2.fromScale(1, 1)
	railFill.BackgroundColor3 = UK_COLOR.RailFull
	railFill.BorderSizePixel = 0
	railFill.Parent = railTrack
	STATE.hud.railFill = railFill

	local armBox = makeUKBox(lFrame, UDim2.fromOffset(166, 164), UDim2.fromOffset(454, 116))
	local armAccent = Instance.new("Frame")
	armAccent.Size = UDim2.new(1, 0, 0, 5)
	armAccent.BackgroundColor3 = CONFIG.HUD_ARM_COLOR
	armAccent.BorderSizePixel = 0
	armAccent.Parent = armBox
	STATE.hud.armAccent = armAccent

	STATE.hud.armIconWrap = buildArmGlyph(armBox, CONFIG.HUD_ARM_COLOR)

	local armBarTrack = Instance.new("Frame")
	armBarTrack.Size = UDim2.new(1, -20, 0, 14)
	armBarTrack.Position = UDim2.new(0, 10, 1, -24)
	armBarTrack.BackgroundColor3 = UK_COLOR.TrackBg
	armBarTrack.BorderSizePixel = 0
	armBarTrack.Parent = armBox

	local armBarFill = Instance.new("Frame")
	armBarFill.Size = UDim2.fromScale(1, 1)
	armBarFill.BackgroundColor3 = CONFIG.HUD_ARM_COLOR
	armBarFill.BorderSizePixel = 0
	armBarFill.Parent = armBarTrack
	STATE.hud.armBarFill = armBarFill

	if CONFIG.SHOW_SPEEDOMETER then
		local spdBox = makeUKBox(lFrame, UDim2.fromOffset(156, 36), UDim2.fromOffset(0, 288))
		STATE.hud.speedBox = spdBox
		local spdLbl = Instance.new("TextLabel")
		spdLbl.Size = UDim2.fromScale(1, 1)
		spdLbl.BackgroundTransparency = 1
		spdLbl.Font = Enum.Font.Code
		spdLbl.TextSize = 20
		spdLbl.TextColor3 = UK_COLOR.TextMain
		spdLbl.Text = "0.00 u/s"
		spdLbl.Parent = spdBox
		STATE.hud.speedLabel = spdLbl
	end

	local armsTagBox = makeUKBox(lFrame, UDim2.fromOffset(170, 36), UDim2.fromOffset(164, 288))
	local hintLbl = Instance.new("TextLabel")
	hintLbl.Size = UDim2.fromScale(1, 1)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Font = Enum.Font.Code
	hintLbl.TextSize = 15
	hintLbl.TextColor3 = STATE.fpHideArms and UK_COLOR.RailFull or UK_COLOR.TextDim
	hintLbl.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
	hintLbl.Parent = armsTagBox
	STATE.hud.hint = hintLbl

	local rightGui = Instance.new("SurfaceGui")
	rightGui.Name = "F3XV1_3DHUD_Right"
	rightGui.Adornee = rightPart
	rightGui.Face = Enum.NormalId.Front
	rightGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	rightGui.CanvasSize = Vector2.new(520, 466)
	rightGui.AlwaysOnTop = true
	rightGui.LightInfluence = 0
	rightGui.ResetOnSpawn = false
	rightGui.Parent = pg
	STATE.hud.rightGui = rightGui

	local rFrame = Instance.new("Frame")
	rFrame.Size = UDim2.fromScale(1, 1)
	rFrame.BackgroundTransparency = 1
	rFrame.BorderSizePixel = 0
	rFrame.Parent = rightGui
	STATE.hud.rightFrame = rFrame

	local rankBox = makeUKBox(rFrame, UDim2.fromOffset(520, 108), UDim2.fromOffset(0, 0))

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, -24, 0, 74)
	rankLabel.Position = UDim2.fromOffset(14, 8)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.GothamBlack
	rankLabel.TextSize = 42
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.TextYAlignment = Enum.TextYAlignment.Center
	rankLabel.RichText = true
	rankLabel.TextColor3 = STYLE_RANKS[1].color
	rankLabel.Text = '<font size="68">D</font><font size="34">ESTRUCTIVE</font>'
	rankLabel.Parent = rankBox
	STATE.hud.rankLabel = rankLabel

	local rankBarBack = Instance.new("Frame")
	rankBarBack.Size = UDim2.new(1, -28, 0, 10)
	rankBarBack.Position = UDim2.new(0, 14, 1, -20)
	rankBarBack.BackgroundColor3 = UK_COLOR.TrackBg
	rankBarBack.BorderSizePixel = 0
	rankBarBack.Parent = rankBox

	local rankBarFill = Instance.new("Frame")
	rankBarFill.Size = UDim2.fromScale(0, 1)
	rankBarFill.BackgroundColor3 = STYLE_RANKS[1].color
	rankBarFill.BorderSizePixel = 0
	rankBarFill.Parent = rankBarBack
	STATE.hud.rankBarFill = rankBarFill

	local feedBox = makeUKBox(rFrame, UDim2.fromOffset(520, 250), UDim2.fromOffset(0, 116))

	local feed = Instance.new("TextLabel")
	feed.Size = UDim2.new(1, -28, 1, -20)
	feed.Position = UDim2.fromOffset(14, 10)
	feed.BackgroundTransparency = 1
	feed.Font = Enum.Font.GothamBold
	feed.TextSize = 25
	feed.TextYAlignment = Enum.TextYAlignment.Top
	feed.TextXAlignment = Enum.TextXAlignment.Left
	feed.RichText = true
	feed.TextWrapped = true
	feed.Text = ""
	feed.Parent = feedBox
	STATE.hud.styleFeed = feed

	local multBox = makeUKBox(rFrame, UDim2.fromOffset(520, 74), UDim2.fromOffset(0, 374))

	local multTitle = Instance.new("TextLabel")
	multTitle.Size = UDim2.new(0.55, 0, 0, 28)
	multTitle.Position = UDim2.fromOffset(14, 8)
	multTitle.BackgroundTransparency = 1
	multTitle.Font = Enum.Font.GothamBold
	multTitle.TextSize = 18
	multTitle.TextXAlignment = Enum.TextXAlignment.Left
	multTitle.TextColor3 = UK_COLOR.TextDim
	multTitle.Text = "MULTIPLIER"
	multTitle.Parent = multBox

	local multLabel = Instance.new("TextLabel")
	multLabel.Size = UDim2.new(0.45, -14, 0, 32)
	multLabel.Position = UDim2.new(0.55, 0, 0, 6)
	multLabel.BackgroundTransparency = 1
	multLabel.Font = Enum.Font.GothamBlack
	multLabel.TextSize = 28
	multLabel.TextXAlignment = Enum.TextXAlignment.Right
	multLabel.TextColor3 = UK_COLOR.TextMain
	multLabel.Text = "1.00x"
	multLabel.Parent = multBox
	STATE.hud.multLabel = multLabel

	local multTrack = Instance.new("Frame")
	multTrack.Size = UDim2.new(1, -28, 0, 14)
	multTrack.Position = UDim2.fromOffset(14, 44)
	multTrack.BackgroundColor3 = UK_COLOR.TrackBg
	multTrack.BorderSizePixel = 0
	multTrack.Parent = multBox

	local multBarFill = Instance.new("Frame")
	multBarFill.Size = UDim2.fromScale(0, 1)
	multBarFill.BackgroundColor3 = UK_COLOR.RailFull
	multBarFill.BorderSizePixel = 0
	multBarFill.Parent = multTrack
	STATE.hud.multBarFill = multBarFill

	local crossGui = Instance.new("ScreenGui")
	crossGui.Name = "F3XV1_Crosshair"
	crossGui.ResetOnSpawn = false
	crossGui.IgnoreGuiInset = true
	crossGui.DisplayOrder = 25
	crossGui.Parent = pg
	STATE.hud.crossGui = crossGui

	local cross = Instance.new("Frame")
	cross.Size = UDim2.fromOffset(110, 80)
	cross.Position = UDim2.new(0.5, -55, 0.5, -40)
	cross.BackgroundTransparency = 1
	cross.Parent = crossGui

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(3, 3)
	dot.Position = UDim2.new(0.5, -1, 0.5, -1)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = cross

	for _, tCfg in ipairs({
		{ UDim2.new(0.5, -10, 0.5, -1), UDim2.fromOffset(5, 2) },
		{ UDim2.new(0.5, 5, 0.5, -1),   UDim2.fromOffset(5, 2) },
		{ UDim2.new(0.5, -1, 0.5, -10), UDim2.fromOffset(2, 5) },
		{ UDim2.new(0.5, -1, 0.5, 5),   UDim2.fromOffset(2, 5) },
	}) do
		local tick = Instance.new("Frame")
		tick.Position = tCfg[1]
		tick.Size = tCfg[2]
		tick.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		tick.BackgroundTransparency = 0.15
		tick.BorderSizePixel = 0
		tick.Parent = cross
	end

	local cLeft = Instance.new("Frame")
	cLeft.Size = UDim2.fromOffset(5, 48)
	cLeft.Position = UDim2.new(0.5, -34, 0.5, -24)
	cLeft.BackgroundColor3 = UK_COLOR.HealthBack
	cLeft.BackgroundTransparency = 0.25
	cLeft.BorderSizePixel = 0
	cLeft.ClipsDescendants = true
	cLeft.Parent = cross
	STATE.hud.crossHudLeft = cLeft

	local cSoft = Instance.new("Frame")
	cSoft.AnchorPoint = Vector2.new(0, 1)
	cSoft.Position = UDim2.fromScale(0, 1)
	cSoft.Size = UDim2.fromScale(1, 1)
	cSoft.BackgroundColor3 = UK_COLOR.SoftDamage
	cSoft.BorderSizePixel = 0
	cSoft.Parent = cLeft
	STATE.hud.crossSoftFill = cSoft

	local cHp = Instance.new("Frame")
	cHp.AnchorPoint = Vector2.new(0, 1)
	cHp.Position = UDim2.fromScale(0, 1)
	cHp.Size = UDim2.fromScale(1, 1)
	cHp.BackgroundColor3 = UK_COLOR.Health
	cHp.BorderSizePixel = 0
	cHp.ZIndex = 2
	cHp.Parent = cLeft
	STATE.hud.crossHpFill = cHp

	local cHard = Instance.new("Frame")
	cHard.Size = UDim2.fromScale(1, 0)
	cHard.BackgroundColor3 = UK_COLOR.HardDamage
	cHard.BorderSizePixel = 0
	cHard.ZIndex = 3
	cHard.Parent = cLeft
	STATE.hud.crossHardFill = cHard

	local cRight = Instance.new("Frame")
	cRight.Size = UDim2.fromOffset(5, 48)
	cRight.Position = UDim2.new(0.5, 29, 0.5, -24)
	cRight.BackgroundTransparency = 1
	cRight.Parent = cross
	STATE.hud.crossHudRight = cRight

	for i = 1, 3 do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(5, 14)
		slot.Position = UDim2.fromOffset(0, (3 - i) * 17)
		slot.BackgroundColor3 = Color3.fromRGB(20, 14, 16)
		slot.BackgroundTransparency = 0.25
		slot.BorderSizePixel = 0
		slot.Parent = cRight

		local fill = Instance.new("Frame")
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.Position = UDim2.fromScale(0, 1)
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = UK_COLOR.StaminaFull
		fill.BorderSizePixel = 0
		fill.Parent = slot
		STATE.hud.crossStamBars[i] = fill
	end

	local hitm = Instance.new("TextLabel")
	hitm.Size = UDim2.fromOffset(30, 30)
	hitm.Position = UDim2.new(0.5, -15, 0.5, -15)
	hitm.BackgroundTransparency = 1
	hitm.Font = Enum.Font.GothamBlack
	hitm.TextSize = 22
	hitm.TextColor3 = UK_COLOR.TextMain
	hitm.Text = "X"
	hitm.Visible = false
	hitm.Parent = cross
	STATE.hud.hitmarker = hitm

	if not UIS.TouchEnabled then
		local helpHint = makeUKBox(crossGui, UDim2.fromOffset(118, 22), UDim2.new(1, -130, 1, -34), 0.55)
		local helpHintTxt = Instance.new("TextLabel")
		helpHintTxt.Size = UDim2.fromScale(1, 1)
		helpHintTxt.BackgroundTransparency = 1
		helpHintTxt.Font = Enum.Font.Code
		helpHintTxt.TextSize = 12
		helpHintTxt.TextColor3 = UK_COLOR.TextDim
		helpHintTxt.Text = "[H] CONTROLS"
		helpHintTxt.Parent = helpHint

		local helpPanel = makeUKBox(crossGui, UDim2.fromOffset(252, 168), UDim2.new(1, -264, 1, -208), 0.28)
		helpPanel.Visible = false
		local helpTxt = Instance.new("TextLabel")
		helpTxt.Size = UDim2.new(1, -16, 1, -14)
		helpTxt.Position = UDim2.fromOffset(8, 7)
		helpTxt.BackgroundTransparency = 1
		helpTxt.Font = Enum.Font.Code
		helpTxt.TextSize = 12
		helpTxt.TextXAlignment = Enum.TextXAlignment.Left
		helpTxt.TextYAlignment = Enum.TextYAlignment.Top
		helpTxt.TextColor3 = UK_COLOR.TextMain
		helpTxt.Text = table.concat({
			CONFIG.HUD_KEY_HINT,
			"[SHIFT] SPRINT   [R] SWAP",
			"[SPACE] WALL-KICK / GLIDE",
			"[X] 1P ARMS      [M] MUTE BGM",
			"[F7] REBUILD     [F6] STOP",
		}, "\n")
		helpTxt.Parent = helpPanel
		STATE.hud.helpPanel = helpPanel
	end

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
			h.swayYaw = clamp(lerp(h.swayYaw, -locD.X * 135, clamp(dt * 12, 0, 1)), -10, 10)
			h.swayPitch = clamp(lerp(h.swayPitch, locD.Y * 135, clamp(dt * 12, 0, 1)), -8, 8)
		end
		h.prevCamLook = look

		if hrp then
			local locV = curCam.CFrame:VectorToObjectSpace(hrp.AssemblyLinearVelocity)
			h.swayX = clamp(lerp(h.swayX, -locV.X * 0.004, clamp(dt * 10, 0, 1)), -0.20, 0.20)
			h.swayY = clamp(lerp(h.swayY, -locV.Y * 0.0036, clamp(dt * 10, 0, 1)), -0.18, 0.18)
		end

		local vp = curCam.ViewportSize
		local aspect = (vp.Y > 0) and (vp.X / vp.Y) or 1.77
		local aspectScale = clamp(aspect / 1.45, 0.48, 1.0)
		local fovScale = math.tan(rad(curCam.FieldOfView * 0.5)) / math.tan(rad(35))
		local dist = 5.4
		local halfH = dist * math.tan(rad(curCam.FieldOfView * 0.5))
		local halfW = halfH * aspect

		local popScale = 1 + h.stylePop * 0.10
		h.leftPart.Size = V(2.26, 1.32, 0.05) * fovScale * aspectScale
		h.rightPart.Size = V(1.92 * popScale, 1.72 * popScale, 0.05) * fovScale * aspectScale

		local leftPos = V(-halfW * 0.67 + h.swayX, -halfH * 0.56 + h.swayY, -dist)
		local rightPos = V(halfW * 0.68 + h.swayX, halfH * 0.44 + h.swayY, -dist)

		h.leftPart.CFrame = curCam.CFrame * C(leftPos) * angles(6 + h.swayPitch, 180 + 16 + h.swayYaw, -1.5)
		h.rightPart.CFrame = curCam.CFrame * C(rightPos) * angles(-5 + h.swayPitch, 180 - 16 + h.swayYaw, 1.5)
	end)

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
			btn.BackgroundColor3 = UK_COLOR.PanelBg
			btn.BackgroundTransparency = 0.42
			btn.BorderSizePixel = 0
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 13
			btn.TextColor3 = UK_COLOR.TextMain
			btn.Text = text
			btn.Active = true
			btn.Selectable = false
			btn.AutoButtonColor = true
			btn.Parent = mobGui

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 3)
			corner.Parent = btn

			local bar = Instance.new("Frame")
			bar.Name = "AccentStrip"
			bar.Size = UDim2.new(1, 0, 0, 3)
			bar.BackgroundColor3 = color
			bar.BorderSizePixel = 0
			bar.Parent = btn

			local st = Instance.new("UIStroke")
			st.Color = color
			st.Thickness = 1
			st.Transparency = 0.65
			st.Parent = btn

			btn.Activated:Connect(function()
				if STATE and STATE.alive then onPress(btn, st, bar) end
			end)
			return btn
		end

		makeMobBtn("ParryBtn", CONFIG.MOBILE_SECONDARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -172, 1, -168), CONFIG.MOBILE_SECONDARY_COLOR, function()
			triggerHUDArmPulse()
			if CHAR_DEF and CHAR_DEF.onSecondary then CHAR_DEF.onSecondary(Core) end
		end)
		makeMobBtn("CoinBtn", CONFIG.MOBILE_PRIMARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -90, 1, -168), CONFIG.MOBILE_PRIMARY_COLOR, function()
			triggerHUDWeaponPulse()
			if CHAR_DEF and CHAR_DEF.onPrimary then CHAR_DEF.onPrimary(Core) end
		end)
		makeMobBtn("DashBtn", "DASH", UDim2.fromOffset(72, 54), UDim2.new(1, -172, 1, -104), UK_COLOR.StaminaFull, function()
			Core.triggerDash()
		end)
		makeMobBtn("SlideBtn", "SLIDE", UDim2.fromOffset(72, 54), UDim2.new(1, -90, 1, -104), Color3.fromRGB(205, 225, 240), function()
			Core.triggerSlideOrSlam()
		end)
		makeMobBtn("SprintBtn", "SPRINT", UDim2.fromOffset(154, 36), UDim2.new(1, -172, 1, -214), Color3.fromRGB(160, 175, 190), function(btn, st, bar)
			STATE.mobileSprint = not STATE.mobileSprint
			local col = STATE.mobileSprint and CONFIG.MARKSMAN_GREEN or Color3.fromRGB(160, 175, 190)
			btn.TextColor3 = STATE.mobileSprint and col or UK_COLOR.TextMain
			st.Color = col
			bar.BackgroundColor3 = col
			btn.Text = STATE.mobileSprint and "SPRINT: ON" or "SPRINT"
		end)

		if CHAR_DEF and CHAR_DEF.onTertiary then
			makeMobBtn("SwapBtn", CONFIG.MOBILE_TERTIARY_LABEL, UDim2.fromOffset(72, 54), UDim2.new(1, -254, 1, -168), CONFIG.MOBILE_TERTIARY_COLOR, function()
				triggerHUDWeaponPulse()
				CHAR_DEF.onTertiary(Core)
			end)
		end

		makeMobBtn("ArmsBtn", "1P ARMS", UDim2.fromOffset(82, 32), UDim2.new(0.5, -132, 0, 12), CONFIG.MARKSMAN_GREEN, function(btn, st, bar)
			STATE.fpHideArms = not STATE.fpHideArms
			local col = STATE.fpHideArms and UK_COLOR.RailFull or CONFIG.MARKSMAN_GREEN
			btn.TextColor3 = col
			st.Color = col
			bar.BackgroundColor3 = col
			btn.Text = STATE.fpHideArms and "ARMS: OFF" or "1P ARMS"
			if STATE.hud.hint then
				STATE.hud.hint.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
				STATE.hud.hint.TextColor3 = STATE.fpHideArms and UK_COLOR.RailFull or UK_COLOR.TextDim
			end
		end)
		makeMobBtn("RebuildBtn", "REBUILD", UDim2.fromOffset(82, 32), UDim2.new(0.5, -41, 0, 12), CONFIG.YELLOW_NEON, function()
			forceRebuild()
		end)
		makeMobBtn("StopBtn", "STOP", UDim2.fromOffset(72, 32), UDim2.new(0.5, 50, 0, 12), UK_COLOR.Health, function()
			cleanup()
		end)
	end
end

local function updateHUD(hum, hrp, dt, isAir, hudStatus)
	local h = STATE and STATE.hud
	if not (CONFIG.ENABLE_HUD and h and h.leftPart and h.leftPart.Parent) then return end
	local now = os.clock()

	local rank = STYLE_RANKS[1]
	for _, r in ipairs(STYLE_RANKS) do
		if h.stylePoints >= r.min then rank = r end
	end

	local hpFrac, softFrac, hardFrac = 1, 1, 0
	if hum then
		local hp = math.max(0, hum.Health)
		local maxHp = math.max(1, hum.MaxHealth)
		if hp < STATE.lastHealth then
			local dmg = STATE.lastHealth - hp
			STATE.softDamage = math.min(maxHp, math.max(STATE.softDamage, STATE.lastHealth))
			STATE.hardDamageAmt = clamp(STATE.hardDamageAmt + dmg * 0.35, 0, maxHp * 0.65)
			STATE.hardDamageHoldUntil = now + 0.65 / math.max(1, rank.hdRate)
			STATE.camShake = math.max(STATE.camShake, 0.25)
			h.crossHudActiveUntil = now + 1.2
		elseif hp > STATE.lastHealth then
			STATE.hardDamageAmt = math.max(0, STATE.hardDamageAmt - (hp - STATE.lastHealth) * 0.4)
		end
		STATE.lastHealth = hp
		STATE.softDamage = math.max(hp, STATE.softDamage - dt * 36)

		if rank.hdRate >= 99 then
			STATE.hardDamageAmt = 0
		elseif now >= STATE.hardDamageHoldUntil then
			STATE.hardDamageAmt = math.max(0, STATE.hardDamageAmt - dt * 16 * rank.hdRate)
		end

		hpFrac = clamp(hp / maxHp, 0, 1)
		softFrac = clamp(STATE.softDamage / maxHp, 0, 1)
		hardFrac = clamp(STATE.hardDamageAmt / maxHp, 0, 0.75)

		if h.hpFill and h.softDmgFill and h.hardDmgFill and h.overhealFill and h.hpText then
			h.hpFill.Size = UDim2.fromScale(hpFrac, 1)
			h.softDmgFill.Size = UDim2.fromScale(softFrac, 1)
			h.hardDmgFill.Size = UDim2.fromScale(hardFrac, 1)
			local overFrac = clamp((hp - maxHp) / maxHp, 0, 1)
			h.overhealFill.Visible = overFrac > 0.005
			h.overhealFill.Size = UDim2.fromScale(overFrac, 1)

			h.hpText.Text = tostring(math.ceil(hp))
			h.hpText.TextColor3 = (hp <= maxHp * 0.30) and Color3.fromRGB(255, 110, 110) or UK_COLOR.HealthNum
		end
	end

	if hrp and h.speedLabel then
		local spd = V(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
		h.speedLabel.Text = string.format("%.2f u/s", spd)
	end

	local prevStam = STATE.dash.stamina
	if STATE.dash.stamina < CONFIG.MAX_STAMINA then
		STATE.dash.stamina = math.min(CONFIG.MAX_STAMINA, STATE.dash.stamina + dt / CONFIG.STAMINA_REGEN_TIME)
		if math.floor(STATE.dash.stamina) > math.floor(prevStam) then
			h.crossHudActiveUntil = now + 1.0
		end
	end
	for i = 1, CONFIG.MAX_STAMINA do
		local bar = h.stamBars[i]
		local cBar = h.crossStamBars[i]
		local segVal = clamp(STATE.dash.stamina - (i - 1), 0, 1)
		local col = (segVal >= 0.999) and UK_COLOR.StaminaFull
			or ((segVal <= 0.02) and UK_COLOR.StaminaEmpty or UK_COLOR.StaminaCharge)

		if bar then
			bar.Size = UDim2.fromScale(segVal, 1)
			bar.BackgroundColor3 = col
		end
		if cBar then
			cBar.Size = UDim2.fromScale(1, segVal)
			cBar.BackgroundColor3 = col
		end
	end

	if hudStatus then
		if h.wpnTitle and hudStatus.weaponTitle then h.wpnTitle.Text = hudStatus.weaponTitle end
		if hudStatus.weaponColor then
			if h.wpnTitle then h.wpnTitle.TextColor3 = hudStatus.weaponColor end
			if h.wpnAccent then h.wpnAccent.BackgroundColor3 = hudStatus.weaponColor end
		end
		local pipFrac = clamp(hudStatus.chargeFrac or 1, 0, 1)
		local pipFull = hudStatus.pipColor or CONFIG.HUD_PIP_COLOR
		local pipDim = hudStatus.pipDimColor or Color3.fromRGB(130, 102, 24)
		for i = 1, 4 do
			local pip = h.coinPips[i]
			if pip then
				local fill = clamp((pipFrac * 4) - (i - 1), 0, 1)
				pip.Size = UDim2.fromScale(fill, 1)
				pip.BackgroundColor3 = (fill >= 0.999) and pipFull or pipDim
			end
		end
		if h.railFill then
			h.railFill.Size = UDim2.fromScale(pipFrac, 1)
			h.railFill.BackgroundColor3 = (pipFrac >= 0.999) and UK_COLOR.RailFull or UK_COLOR.RailCharge
		end
	end

	if h.armBarFill and h.armIconWrap then
		local rem = clamp((h.armPulseUntil - now) / 0.36, 0, 1)
		local readyFrac = 1 - rem
		h.armBarFill.Size = UDim2.fromScale(readyFrac, 1)
		h.armBarFill.BackgroundColor3 = (rem > 0.05) and Color3.fromRGB(255, 224, 61) or CONFIG.HUD_ARM_COLOR
		h.armIconWrap.Position = UDim2.new(0.5, -29, 0, 22 - math.floor(rem * 10))
	end

	if isAir or STATE.slide.active or STATE.dash.active then
		h.styleMult = clamp(h.styleMult + dt * 2.0, 1.0, 3.0)
	else
		h.styleMult = clamp(h.styleMult - dt * 10.0, 1.0, 3.0)
	end

	h.stylePoints = math.max(0, h.stylePoints - dt * rank.decay)
	h.stylePop = math.max(0, h.stylePop - dt * 6.5)

	rank = STYLE_RANKS[1]
	for _, r in ipairs(STYLE_RANKS) do
		if h.stylePoints >= r.min then rank = r end
	end

	if h.rankLabel and h.rankBarFill and h.multLabel and h.multBarFill then
		if rank.rest == "" then
			h.rankLabel.Text = '<font size="48">ULTRAKILL</font>'
		else
			local bigSz = (#rank.prefix >= 3 and "56") or (#rank.prefix == 2 and "62") or "68"
			local smallSz = (#rank.prefix >= 3 and "28") or "33"
			h.rankLabel.Text = string.format('<font size="%s">%s</font><font size="%s">%s</font>', bigSz, rank.prefix, smallSz, rank.rest)
		end
		h.rankLabel.TextColor3 = rank.color

		local pct = clamp((h.stylePoints - rank.min) / math.max(1, rank.max - rank.min), 0, 1)
		h.rankBarFill.Size = UDim2.fromScale(pct, 1)
		h.rankBarFill.BackgroundColor3 = rank.color

		h.multLabel.Text = string.format("%.2fx", h.styleMult)
		h.multLabel.TextColor3 = (h.styleMult >= 2.5) and UK_COLOR.RailFull or ((h.styleMult >= 1.5) and CONFIG.YELLOW_NEON or UK_COLOR.TextMain)
		h.multBarFill.Size = UDim2.fromScale(clamp((h.styleMult - 1.0) / 2.0, 0, 1), 1)
		h.multBarFill.BackgroundColor3 = h.multLabel.TextColor3
	end

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

	if h.crossHpFill and h.crossSoftFill and h.crossHardFill then
		h.crossHpFill.Size = UDim2.fromScale(1, hpFrac)
		h.crossSoftFill.Size = UDim2.fromScale(1, softFrac)
		h.crossHardFill.Size = UDim2.fromScale(1, hardFrac)

		local active = (now < h.crossHudActiveUntil) or (STATE.dash.stamina < CONFIG.MAX_STAMINA - 0.05) or (hpFrac < 0.99)
		local targetVis = active and 0.15 or 0.78
		h.crossHudAlpha = lerp(h.crossHudAlpha, targetVis, clamp(dt * 8, 0, 1))
		if h.crossHudLeft then h.crossHudLeft.BackgroundTransparency = clamp(h.crossHudAlpha + 0.15, 0, 0.92) end
		h.crossHpFill.BackgroundTransparency = h.crossHudAlpha
		h.crossSoftFill.BackgroundTransparency = h.crossHudAlpha
		h.crossHardFill.BackgroundTransparency = h.crossHudAlpha
		for _, cBar in ipairs(h.crossStamBars) do
			cBar.BackgroundTransparency = h.crossHudAlpha
		end
	end
end

-- ============================================================================
-- HELPERS DE FISICA, NO-COLLISION, MESH E ACESSORIOS
-- ============================================================================
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

local function attachNoColToCharacter(p, c)
	if c then
		for _, limb in ipairs(c:GetDescendants()) do
			if limb:IsA("BasePart") then addNoColPair(limb, p) end
		end
	end
	table.insert(STATE.proxyConnections, p:GetPropertyChangedSignal("CanCollide"):Connect(function()
		if p.CanCollide then p.CanCollide = false end
	end))
	table.insert(STATE.proxyConnections, p:GetPropertyChangedSignal("Anchored"):Connect(function()
		if not p.Anchored then p.Anchored = true end
	end))
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

-- ============================================================================
-- FX VISUAIS, HITSTOP E ABATE F3X POR REMOCAO DE TORSO
-- ============================================================================
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
	STATE.hitstopCC.Brightness = 0.24
	STATE.hitstopCC.Contrast = 0.30
	STATE.hitstopCC.TintColor = tintColor or CONFIG.PARRY_FLASH
end

local function resolveTargetModel(targetOrPart)
	if not targetOrPart then return nil end
	if typeof(targetOrPart) ~= "Instance" then return nil end
	if targetOrPart:IsA("Model") then return targetOrPart end
	local cur = targetOrPart.Parent
	while cur and cur ~= workspace do
		if cur:IsA("Model") and (cur:FindFirstChildOfClass("Humanoid") or cur:FindFirstChild("Torso") or cur:FindFirstChild("UpperTorso")) then
			return cur
		end
		cur = cur.Parent
	end
	return nil
end

function Core.applyF3XKnockback(targetChar, _dir, _power)
	if not (STATE and STATE.alive and CONFIG.ENABLE_TORSO_KILL) then return end
	targetChar = resolveTargetModel(targetChar)
	if not (targetChar and targetChar.Parent) then return end

	local myChar = getChar()
	if targetChar == myChar then return end

	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if targetHum and targetHum.Health <= 0 then return end

	local now = os.clock()
	local lastKill = STATE.killedTargets[targetChar]
	if lastKill and (now - lastKill) < (CONFIG.KILL_DEBOUNCE or 0.45) then
		return
	end

	local torsoParts = {}
	for _, partName in ipairs({ "Torso", "UpperTorso", "LowerTorso" }) do
		local p = targetChar:FindFirstChild(partName)
		if p and p:IsA("BasePart") then
			torsoParts[#torsoParts + 1] = p
		end
	end
	if #torsoParts == 0 then return end

	local ep = Core.getEndpoint()
	if not ep then return end

	STATE.killedTargets[targetChar] = now
	for kChar, tAt in pairs(STATE.killedTargets) do
		if not kChar.Parent or (now - tAt) > 5.0 then
			STATE.killedTargets[kChar] = nil
		end
	end

	local killPos = torsoParts[1].Position
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local closeKill = myHRP and ((killPos - myHRP.Position).Magnitude <= 26) or false

	task.spawn(function()
		local ok = f3x(ep, "Remove", torsoParts)
		if not ok then
			for _, tp in ipairs(torsoParts) do
				if tp and tp.Parent then
					pcall(f3x, ep, "Remove", { tp })
				end
			end
		end
	end)

	if closeKill then
		spawnFlash(killPos, CONFIG.BLOOD_RED, 1.0, 4.4, 0.22)
		if (now - STATE.lastSlamImpactAt) > 0.08 then
			spawnImpactFlash(killPos, CONFIG.BLOOD_RED, 0.9, 3.6, 0.20)
		end
		STATE.camShake = math.max(STATE.camShake, 0.35)
	end

	if (now - STATE.lastKillAt) <= (CONFIG.MULTIKILL_WINDOW or 1.25) then
		STATE.killStreak += 1
	else
		STATE.killStreak = 1
	end
	STATE.lastKillAt = now

	if STATE.killStreak == 1 then
		addStyleBonus("KILL", 60, UK_COLOR.TextMain)
	elseif STATE.killStreak == 2 then
		addStyleBonus("DOUBLE KILL", 120, Color3.fromRGB(255, 165, 55))
	elseif STATE.killStreak == 3 then
		addStyleBonus("TRIPLE KILL", 180, CONFIG.YELLOW_NEON)
	else
		addStyleBonus("MULTIKILL x" .. tostring(STATE.killStreak), 220, Color3.fromRGB(255, 65, 65))
	end
end

Core.removeTargetTorso = Core.applyF3XKnockback

-- ============================================================================
-- DASH / SLIDE / SLAM / SALTO NA PAREDE E PLANAGEM
-- ============================================================================
local function isHumInAir(hum)
	if not hum then return false end
	local hState = hum:GetState()
	return (hState == Enum.HumanoidStateType.Freefall or hState == Enum.HumanoidStateType.Jumping)
		or (hum.FloorMaterial == Enum.Material.Air and hState ~= Enum.HumanoidStateType.Climbing and hState ~= Enum.HumanoidStateType.Swimming and hState ~= Enum.HumanoidStateType.Seated)
end

local function findNearbyWallNormal(c, hrp)
	local rp = buildExcludeRayParams(c)
	local look = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector
	local dirs = {
		look, -look, right, -right,
		(look + right).Unit, (look - right).Unit,
		(-look + right).Unit, (-look - right).Unit,
	}
	for _, d in ipairs(dirs) do
		local res = workspace:Raycast(hrp.Position, d * CONFIG.WALL_DETECT_DIST, rp)
		if res and res.Instance and res.Instance.CanCollide then
			return res.Normal, res.Position
		end
	end
	return nil, nil
end

local function handleJumpAction()
	if not (STATE and STATE.alive and CONFIG.ENABLE_AIR_MOVEMENT) or STATE.isSettingUp then return end
	local c = getChar()
	local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and hum.Health > 0) then return end

	local now = os.clock()
	local isAir = isHumInAir(hum)

	if STATE.slamStored and (now - STATE.lastSlamLand <= CONFIG.SLAM_STORAGE_WINDOW) then
		STATE.slamStored = false
		STATE.slam.active = false
		STATE.slamJumpUntil = now + 0.45
		local vel = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = V(vel.X, CONFIG.SLAM_STORAGE_JUMP, vel.Z)
		STATE.fovKick = math.max(STATE.fovKick, 12)
		playSFX("DASH", 1.35, 1.0, "PARRY")
		spawnRing(hrp.Position - V(0, 2.0, 0), CONFIG.BEAM_CYAN, 0.9, 6.2, 0.24)
		addStyleBonus("SLAM STORAGE", 120, CONFIG.BEAM_CYAN)
		return
	end

	if not isAir and (STATE.dash.active or STATE.slide.active) then
		local boostDir = (hum.MoveDirection.Magnitude > 0.1) and V(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit or (STATE.dash.active and STATE.dash.dir or STATE.slide.dir)
		local boostSpd = math.max(STATE.airVelXZ.Magnitude, CONFIG.DASH_SPEED * CONFIG.DASH_JUMP_MULT)
		STATE.dash.active = false
		STATE.slide.active = false
		STATE.airVelXZ = boostDir * boostSpd
		hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, CONFIG.JUMP_POWER * 1.08, STATE.airVelXZ.Z)
		STATE.fovKick = math.max(STATE.fovKick, 9)
		playSFX("DASH", 1.25, 0.85, "PARRY")
		return
	end

	if isAir and CONFIG.WALL_JUMP_ENABLED and STATE.wallJumpsLeft > 0 and (now - STATE.lastWallJumpAt) > 0.14 then
		local wallNormal, hitPos = findNearbyWallNormal(c, hrp)
		if wallNormal then
			STATE.lastWallJumpAt = now
			STATE.wallJumpsLeft -= 1
			STATE.slam.active = false
			STATE.dash.active = false
			local flatNorm = V(wallNormal.X, 0, wallNormal.Z)
			flatNorm = (flatNorm.Magnitude > 0.01) and flatNorm.Unit or -hrp.CFrame.LookVector
			local wish = (hum.MoveDirection.Magnitude > 0.1) and V(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit or V(0, 0, 0)
			STATE.airVelXZ = flatNorm * CONFIG.WALL_JUMP_PUSH + wish * 18
			hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, CONFIG.WALL_JUMP_UP, STATE.airVelXZ.Z)
			STATE.fovKick = math.max(STATE.fovKick, 7)
			playSFX("DASH", 1.38, 0.9, "PARRY")
			if hitPos then spawnFlash(hitPos, CONFIG.BEAM_CYAN, 0.7, 2.8, 0.16) end
			addStyleBonus("WALL KICK", 50, CONFIG.BEAM_CYAN)
		end
	end
end

function Core.triggerDash()
	if not (STATE and CONFIG.ENABLE_DASH) or STATE.isSettingUp then return end
	local now = os.clock()
	if STATE.dash.active or (now - STATE.dash.lastUsed) < CONFIG.DASH_COOLDOWN or STATE.dash.stamina < 1.0 then return end
	local c = getChar()
	local hrp, hum = c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end

	STATE.dash.stamina = math.max(0, STATE.dash.stamina - 1.0)
	STATE.hud.crossHudActiveUntil = now + 1.15
	local cam = workspace.CurrentCamera
	local refCF = (cam and (cam.CFrame.Position - hrp.Position).Magnitude < 3.0) and cam.CFrame or hrp.CFrame
	local flatLook = V(refCF.LookVector.X, 0, refCF.LookVector.Z)
	flatLook = (flatLook.Magnitude < 0.01) and V(0, 0, -1) or flatLook.Unit

	local dashDir = (hum.MoveDirection.Magnitude > 0.1) and V(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit or flatLook
	STATE.dash.active, STATE.dash.lastUsed, STATE.dash.startTime = true, now, now
	STATE.dash.dir = dashDir
	STATE.dash.localDir = hrp.CFrame:VectorToObjectSpace(dashDir)
	STATE.airVelXZ = dashDir * CONFIG.DASH_SPEED
	STATE.slide.active = false
	STATE.slam.active = false
	STATE.isGliding = false

	STATE.fovKick = 12
	if cam then cam.FieldOfView = cam.FieldOfView + 6 end

	local yVel = isHumInAir(hum) and 2 or hrp.AssemblyLinearVelocity.Y
	hrp.AssemblyLinearVelocity = V(dashDir.X * CONFIG.DASH_SPEED, yVel, dashDir.Z * CONFIG.DASH_SPEED)
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

	local isAir = isHumInAir(hum)

	if isAir then
		local floorRes = workspace:Raycast(hrp.Position, V(0, -400, 0), buildExcludeRayParams(c))
		local dropHeight = floorRes and (hrp.Position.Y - floorRes.Position.Y) or 60
		STATE.slide.active, STATE.slide.startTime = true, now
		STATE.slam.active, STATE.slam.startTime = true, now
		STATE.isGliding = false
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
	STATE.airVelXZ = moveDir * CONFIG.SLIDE_SPEED
	hrp.AssemblyLinearVelocity = V(moveDir.X * CONFIG.SLIDE_SPEED, hrp.AssemblyLinearVelocity.Y, moveDir.Z * CONFIG.SLIDE_SPEED)
	STATE.fovKick = math.max(STATE.fovKick, 9)
	playSFX("STEP", 0.62, 1.0, "DASH")
end

-- ============================================================================
-- DISPATCH F3X DO RIG COM SEQUENCIAMENTO (seq/ack)
-- ============================================================================
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

-- ============================================================================
-- SETUP, VERIFICACAO E CLEANUP DO RIG
-- ============================================================================
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

local function destroyAirPhysics()
	if not STATE then return end
	if STATE.antiGravForce then
		agUnprotect(STATE.antiGravForce)
		pcall(function() STATE.antiGravForce:Destroy() end)
		STATE.antiGravForce = nil
	end
	if STATE.antiGravAtt then
		agUnprotect(STATE.antiGravAtt)
		pcall(function() STATE.antiGravAtt:Destroy() end)
		STATE.antiGravAtt = nil
	end
	STATE.isGliding = false
	STATE.slamStored = false
end

local function cleanupRigParts(ep)
	if not STATE then return end
	if not ep or not ep.Parent then ep = getF3XEndpoint() end

	destroyAirPhysics()
	for _, ncc in ipairs(STATE.noColConstraints) do pcall(function() ncc:Destroy() end) end
	STATE.noColConstraints = {}
	clearProxyConnections()

	local c = getChar()
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum.CameraOffset = V(0, 0, 0) end)
		if STATE.touchedWalkSpeed then
			pcall(function() hum.WalkSpeed = CONFIG.WALK_SPEED end)
			pcall(function() hum.JumpPower = 50 end)
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
	agUnprotect(toDel)
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
	if #remaining == 0 then
		agClearProtected()
	end
	STATE.proxyAccessories = {}
	STATE.modelEntries = {}
	STATE.buckets = {}
	STATE.coinPart, STATE.beam1Part, STATE.beam2Part, STATE.beamCore1Part, STATE.beamCore2Part = nil, nil, nil, nil, nil
	STATE.flashPart, STATE.impactPart, STATE.ringPart = nil, nil, nil
	STATE.killedTargets = {}
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

	agMarkGrace(12)

	local okMain, errMain = xpcall(function()
		local function finishAbort(ep, createdParts)
			agUnprotect(createdParts)
			agEndGrace()
			if createdParts and #createdParts > 0 and ep and ep.Parent then
				for _, ch in ipairs(chunked(createdParts, 40)) do invokeWithTimeout(ep, 1.5, "Remove", ch) end
			end
		end

		local c = getChar() or plr.CharacterAdded:Wait()
		if not waitForCharacterReady(c, mySetupId) then agEndGrace(); return end

		local ep = waitForEndpoint(8, mySetupId)
		if not ep then
			agEndGrace()
			warn("[F3X Ultrakill] 'Building Tools+' / 'Building Tools' nao encontrado!")
			return
		end
		STATE.ep = ep
		STATE.inFlight, STATE.lastSendAt = 0, 0

		cleanupRigParts(ep)
		agMarkGrace(12)
		setupSounds()
		setupHUD()
		if not (STATE and STATE.alive and STATE.setupId == mySetupId) then agEndGrace(); return end

		local hrp, hum = c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then agEndGrace(); return end

		STATE.rigType = (hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
		local _, initYaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
		STATE.lastYaw = initYaw
		STATE.lastHealth = hum.Health
		STATE.softDamage = hum.Health
		STATE.hardDamageAmt = 0
		STATE.dash.stamina = CONFIG.MAX_STAMINA
		STATE.wallJumpsLeft = CONFIG.MAX_WALL_JUMPS
		STATE.airVelXZ = V(0, 0, 0)

		if CONFIG.ENABLE_AIR_MOVEMENT then
			STATE.touchedWalkSpeed = true
			pcall(function()
				hum.UseJumpPower = true
				hum.JumpPower = CONFIG.JUMP_POWER
			end)
			local att = Instance.new("Attachment")
			att.Name = "UK_MoveAtt"
			agProtect(att)
			att.Parent = hrp
			local vf = Instance.new("VectorForce")
			vf.Name = "UK_AntiGrav"
			vf.Attachment0 = att
			vf.RelativeTo = Enum.ActuatorRelativeTo.World
			vf.ApplyAtCenterOfMass = true
			vf.Force = V(0, 0, 0)
			agProtect(vf)
			vf.Parent = hrp
			STATE.antiGravAtt = att
			STATE.antiGravForce = vf
		end

		if CONFIG.DISABLE_FALLING_DOWN then
			STATE.touchedWalkSpeed = true
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			end)
		end

		local resizeItems, colorItems, matItems, anchorItems, colItems, nameItems = {}, {}, {}, {}, {}, {}
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

		for i, spec in ipairs(specs) do
			local suffix = spec.tag or spec.limbName or spec.kind or tostring(i)
			spec.userPartName = makeUserPartName(suffix)
		end

		local function spawnSpecsBatch(specList)
			agMarkGrace(12)
			local tasks = {}
			for _, spec in ipairs(specList) do
				tasks[#tasks + 1] = function()
					if not (STATE and STATE.alive and STATE.setupId == mySetupId) or spec.newPart then return end
					local ok, p = f3x(ep, "CreatePart", spec.partType or "Normal", PARK_CF, workspace)
					if ok and typeof(p) == "Instance" and p:IsA("BasePart") then
						agProtect(p)
						lockProxyPhysics(p)
						attachNoColToCharacter(p, c)
						pcall(function() p.Name = spec.userPartName end)
						createdThisSetup[#createdThisSetup + 1] = p
						STATE.proxyParts[#STATE.proxyParts + 1] = p
						spec.newPart = p

						-- Etiqueta imediatamente em background para outros Anti-Griefs reconhecerem antes mesmo do setup acabar
						task.spawn(function()
							if p and p.Parent and ep and ep.Parent then
								local okName = f3x(ep, "SetName", { { Part = p, Name = spec.userPartName } })
								if okName then
									spec.namedOnServer = true
								end
							end
						end)
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
			task.wait(0.10)
			spawnSpecsBatch(missingSpecs)
		end

		if not (STATE and STATE.alive and STATE.setupId == mySetupId) then
			finishAbort(ep, createdThisSetup)
			return
		end

		-- Garante que todas as partes e filhos futuros criados no setup fiquem protegidos antes de encerrar a janela de grace
		agProtect(STATE.proxyParts)
		agEndGrace()

		local pendingEntries = {}
		for _, spec in ipairs(specs) do
			local p = spec.newPart
			if p and p.Parent then
				agProtect(p)
				lockProxyPhysics(p)
				pcall(function() p.Name = spec.userPartName end)
				if not spec.namedOnServer then
					nameItems[#nameItems + 1] = { Part = p, Name = spec.userPartName }
				end
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
		for _, ch in ipairs(chunked(nameItems, CONFIG.SYNC_CHUNK)) do lockTasks[#lockTasks + 1] = function() f3x(ep, "SetName", ch) end end
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

		local fixAnchors, fixCols, verifiedCount = {}, {}, 0
		for _, entry in ipairs(pendingEntries) do
			local p = entry.part
			if p and p.Parent then
				p.CFrame = entry.targetCF
				entry.serverCF = entry.targetCF
				entry.pendingCF = entry.targetCF
				if not p.Anchored then
					p.Anchored = true
					fixAnchors[#fixAnchors + 1] = { Part = p, Anchored = true }
				end
				if p.CanCollide then
					p.CanCollide = false
					fixCols[#fixCols + 1] = { Part = p, CanCollide = false }
				end
				if p.Anchored and not p.CanCollide then
					verifiedCount += 1
				end
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
			else
				STATE.modelEntries[#STATE.modelEntries + 1] = entry
				STATE.buckets[entry.kind] = STATE.buckets[entry.kind] or {}
				STATE.buckets[entry.kind][#STATE.buckets[entry.kind] + 1] = entry
			end
		end

		if #fixAnchors > 0 or #fixCols > 0 then
			runParallelBatched({
				function() if #fixAnchors > 0 then f3x(ep, "SyncAnchor", fixAnchors) end end,
				function() if #fixCols > 0 then f3x(ep, "SyncCollision", fixCols) end end,
			}, 2, 4)
		end

		if CHAR_DEF.onSetupComplete then CHAR_DEF.onSetupComplete(Core) end
		startBGM(CONFIG.BGM_URL, CONFIG.BGM_FILE, CONFIG.BGM_FALLBACK_ID, CONFIG.BGM_VOLUME, CONFIG.BGM_PITCH)
		print(string.format("[F3X Ultrakill - %s] Ready (%s): %d/%d parts | Verified=%d | Tag=%s | Mode=TorsoKill",
			tostring(CHAR_DEF.name or CHAR_DEF.id), STATE.rigType, #STATE.proxyParts, #specs, verifiedCount, USER_TAG_PREFIX))

		clearCharConnections()
		table.insert(STATE.charConnections, hum.Died:Connect(function()
			if STATE and STATE.alive then
				local curEp = Core.getEndpoint()
				task.spawn(function()
					destroyAirPhysics()
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
		agEndGrace()
		warn("[F3X Ultrakill] setupRig error: " .. tostring(errMain))
	end
	if STATE then STATE.isSettingUp = false end
end

forceRebuild = function()
	if not (STATE and STATE.alive) then return end
	print("[F3X Ultrakill] F7 Force Rebuild triggered.")
	agMarkGrace(12)
	STATE.setupId += 1
	STATE.isSettingUp = false
	STATE.inFlight, STATE.lastSendAt = 0, 0
	STATE.killedTargets = {}
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
	stopBGM()
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
	if type(env.ULTRAKILL_F3X) == "table" and env.ULTRAKILL_F3X.cleanup == cleanup then
		env.ULTRAKILL_F3X = nil
	end
end

-- ============================================================================
-- INICIALIZACAO DO MODULO DE PERSONAGEM
-- ============================================================================
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
		softDamage = 100, hardDamageAmt = 0, hardDamageHoldUntil = 0, lastHealth = 100, camShake = 0, fovKick = 0,

		isGliding = false,
		airVelXZ = V(0, 0, 0),
		wallJumpsLeft = CONFIG.MAX_WALL_JUMPS,
		lastWallJumpAt = 0,
		lastSlamLand = 0,
		lastSlamImpactAt = 0,
		slamStored = false,
		slamJumpUntil = 0,
		antiGravAtt = nil,
		antiGravForce = nil,

		modelEntries = {}, buckets = {}, proxyAccessories = {}, proxyParts = {},
		noColConstraints = {}, hiddenRealParts = {}, hiddenRealDecals = {},
		sfxFolder = nil, soundTemplates = {}, activeSounds = {},

		coinPart = nil, beam1Part = nil, beam2Part = nil, beamCore1Part = nil, beamCore2Part = nil,
		flashPart = nil, impactPart = nil, ringPart = nil,

		knownHumanoids = {},
		killedTargets = {},
		killStreak = 0,
		lastKillAt = 0,

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
			crossGui = nil, mobGui = nil, hitmarker = nil, hint = nil, wpnTitle = nil, wpnAccent = nil, wpnBox = nil,
			hpFill = nil, softDmgFill = nil, hardDmgFill = nil, overhealFill = nil, hpText = nil, speedBox = nil, speedLabel = nil,
			stamBars = {}, coinPips = {}, railFill = nil, armBarFill = nil, armIconWrap = nil, armAccent = nil,
			rankLabel = nil, rankBarFill = nil, multLabel = nil, multBarFill = nil, freshLabel = nil,
			styleFeed = nil, rightFrame = nil, helpPanel = nil,
			crossHpFill = nil, crossSoftFill = nil, crossHardFill = nil, crossStamBars = {},
			crossHudLeft = nil, crossHudRight = nil, crossHudAlpha = 0.78, crossHudActiveUntil = 0,
			armPulseUntil = 0, wpnPulseUntil = 0,
			stylePoints = 0, styleMult = 1.0, stylePop = 0, styleFeedEntries = {}, hitmarkerUntil = 0,
			swayYaw = 0, swayPitch = 0, swayX = 0, swayY = 0, prevCamLook = nil,
		},

		inFlight = 0, inFlightSince = 0, lastSendAt = 0, avgRTT = 0, seqCounter = 0,
		hitstopUntil = 0, hitstopDur = 0.10, hitstopCC = nil,
		connections = {}, charConnections = {}, proxyConnections = {},
		custom = {},
	}

	if CHAR_DEF.initState then CHAR_DEF.initState(Core) end

	env.F3XUltrakillCleanup = cleanup
	env.F3XUltrakillRebuild = forceRebuild
	env.F3XV1ReanimCleanup = cleanup
	env.F3XV1ReanimRebuild = forceRebuild
	env.ULTRAKILL_F3X = {
		cleanup = cleanup,
		rebuild = forceRebuild,
		userTagPrefix = USER_TAG_PREFIX,
		tagPart = Core.tagPart,
		parseUserTag = parseUserTag,
		getProtectedParts = function()
			local out = {}
			if STATE and STATE.alive then
				for _, p in ipairs(STATE.proxyParts) do
					out[#out + 1] = p
				end
				if STATE.antiGravForce then out[#out + 1] = STATE.antiGravForce end
				if STATE.antiGravAtt then out[#out + 1] = STATE.antiGravAtt end
			end
			return out
		end,
		isHighSpeedAction = function()
			if not (STATE and STATE.alive) then return false end
			return STATE.dash.active or STATE.slam.active or STATE.slamStored or (os.clock() < (STATE.slamJumpUntil or 0))
		end,
	}

	initTargetTracker()
	task.spawn(setupRig)

	table.insert(STATE.connections, RunService.Stepped:Connect(function()
		if not (STATE and STATE.alive) then return end
		for _, p in ipairs(STATE.proxyParts) do
			if p and p.Parent then
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
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
				STATE.hitstopCC.Brightness = 0.24 * rem
				STATE.hitstopCC.Contrast = 0.30 * rem
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
		local isAir = isHumInAir(hum)

		if STATE.slam.active then
			if isAir then
				hrp.AssemblyLinearVelocity = V(vel.X * 0.92, -CONFIG.SLAM_SPEED, vel.Z * 0.92)
			else
				STATE.slam.active = false
				STATE.slamArmed = false
				STATE.lastSlamLand = nowClock
				STATE.lastSlamImpactAt = nowClock
				STATE.slamStored = true
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

		if STATE.wasAir and not isAir then
			STATE.wallJumpsLeft = CONFIG.MAX_WALL_JUMPS
			STATE.isGliding = false
			if STATE.vertVel < -14 and not STATE.slam.active then
				STATE.landRecover = 1.0
				playSFX("LAND", 1.1, clamp(math.abs(STATE.vertVel) / 60, 0.35, 1.0), "PARRY")
			end
		elseif not isAir and (nowClock - STATE.lastSlamLand > CONFIG.SLAM_STORAGE_WINDOW) then
			STATE.slamStored = false
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
			local targetFOV = CONFIG.BASE_FOV + STATE.sprintBlend * 6 + (STATE.slide.active and 5 or 0) + (STATE.isGliding and 3 or 0) + STATE.fovKick
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
				STATE.airVelXZ = STATE.dash.dir * curDashSpd
				local yVel = isAir and 2 or vel.Y
				hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, yVel, STATE.airVelXZ.Z)
			else
				STATE.dash.active = false
				local endSpd = isAir and math.max(CONFIG.SPRINT_SPEED, STATE.airVelXZ.Magnitude) or CONFIG.SPRINT_SPEED
				STATE.airVelXZ = STATE.dash.dir * endSpd
				hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, vel.Y, STATE.airVelXZ.Z)
			end
		end

		if STATE.slide.active then
			local sEl = nowClock - STATE.slide.startTime
			if sEl < CONFIG.SLIDE_DURATION and not isAir then
				STATE.airVelXZ = STATE.slide.dir * CONFIG.SLIDE_SPEED
				hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, vel.Y, STATE.airVelXZ.Z)
			else
				STATE.slide.active = false
			end
		end

		if CONFIG.ENABLE_AIR_MOVEMENT and STATE.antiGravForce and STATE.antiGravForce.Parent then
			if isAir and not STATE.slam.active and not STATE.dash.active then
				local holdingJump = (not typing) and (UIS:IsKeyDown(Enum.KeyCode.Space) or hum.Jump)
				STATE.isGliding = holdingJump and vel.Y < 4

				local cancel = STATE.isGliding and CONFIG.GLIDE_GRAVITY_CANCEL or CONFIG.AIR_GRAVITY_CANCEL
				STATE.antiGravForce.Force = V(0, hrp.AssemblyMass * workspace.Gravity * cancel, 0)

				if flatVel.Magnitude > STATE.airVelXZ.Magnitude then
					STATE.airVelXZ = flatVel
				end

				local wishDir = hum.MoveDirection
				if wishDir.Magnitude > 0.05 then
					local wishXZ = V(wishDir.X, 0, wishDir.Z).Unit
					local targetSpd = math.max(hum.WalkSpeed, STATE.airVelXZ.Magnitude)
					STATE.airVelXZ = STATE.airVelXZ:Lerp(wishXZ * targetSpd, clamp(dt * (CONFIG.AIR_STRAFE_ACCEL / 10), 0, 1))
				else
					STATE.airVelXZ = STATE.airVelXZ * math.max(0, 1 - CONFIG.AIR_DRAG * dt)
				end

				local nextY = STATE.isGliding and math.max(vel.Y, -CONFIG.GLIDE_MAX_FALL) or vel.Y
				hrp.AssemblyLinearVelocity = V(STATE.airVelXZ.X, nextY, STATE.airVelXZ.Z)
			else
				STATE.isGliding = false
				STATE.antiGravForce.Force = V(0, 0, 0)
				if not STATE.dash.active and not STATE.slide.active then
					STATE.airVelXZ = flatVel
				end
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

		updateHUD(hum, hrp, dt, isAir, hudStatus)
		dispatchF3X(os.clock())
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
		if inp.KeyCode == Enum.KeyCode.Space then
			handleJumpAction()
		elseif inp.KeyCode == Enum.KeyCode.Q then
			Core.triggerDash()
		elseif inp.KeyCode == Enum.KeyCode.C or inp.KeyCode == Enum.KeyCode.LeftControl then
			Core.triggerSlideOrSlam()
		elseif inp.KeyCode == Enum.KeyCode.E then
			triggerHUDWeaponPulse()
			if CHAR_DEF and CHAR_DEF.onPrimary then CHAR_DEF.onPrimary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.F then
			triggerHUDArmPulse()
			if CHAR_DEF and CHAR_DEF.onSecondary then CHAR_DEF.onSecondary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.R then
			triggerHUDWeaponPulse()
			if CHAR_DEF and CHAR_DEF.onTertiary then CHAR_DEF.onTertiary(Core) end
		elseif inp.KeyCode == Enum.KeyCode.H then
			if STATE.hud.helpPanel then
				STATE.hud.helpPanel.Visible = not STATE.hud.helpPanel.Visible
			end
			return
		elseif inp.KeyCode == Enum.KeyCode.M then
			toggleBGMMute()
			return
		elseif inp.KeyCode == Enum.KeyCode.X then
			STATE.fpHideArms = not STATE.fpHideArms
			local hint = STATE.hud.hint
			if hint then
				hint.Text = STATE.fpHideArms and "[X] 1P ARMS: OFF" or "[X] 1P ARMS: ON"
				hint.TextColor3 = STATE.fpHideArms and UK_COLOR.RailFull or UK_COLOR.TextDim
			end
			return
		end
	end))

	table.insert(STATE.connections, UIS.JumpRequest:Connect(function()
		if UIS.TouchEnabled and STATE and STATE.alive then
			handleJumpAction()
		end
	end))

	table.insert(STATE.connections, plr.CharacterAdded:Connect(function()
		if not STATE then return end
		agMarkGrace(12)
		STATE.setupId += 1
		STATE.isSettingUp = false
		STATE.inFlight, STATE.lastSendAt = 0, 0
		STATE.walkBlend, STATE.sprintBlend, STATE.airBlend = 0, 0, 0
		STATE.slide.active, STATE.slam.active = false, false
		STATE.isGliding, STATE.slamStored = false, false
		STATE.airVelXZ = V(0, 0, 0)
		STATE.killedTargets = {}
		destroyAirPhysics()
		clearCharConnections()
		clearProxyConnections()
		if STATE.alive then task.spawn(setupRig) end
	end))
end

return Core