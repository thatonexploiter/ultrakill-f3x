-- F3X / FORK3X ULTRAKILL CORE ENGINE (R6 + R15 | PC + MOBILE)
-- Motor compartilhado para V1, V2 e futuros personagens modulares

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local plr = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local Core = {}

-------------------------------------------------------------------
-- ATALHOS MATEMÁTICOS & HELPERS
-------------------------------------------------------------------
local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local ID_CF = CFrame.new()

Core.V3 = V3
Core.CF = CF
Core.ANG = ANG
Core.ID_CF = ID_CF

function Core.lerpNum(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

function Core.lerpCF(a, b, t)
	return a:Lerp(b, math.clamp(t, 0, 1))
end

-- Espelha um CFrame local no eixo X preservando rotação correta (usado nas asas e braços)
function Core.mirrorCF(cf)
	local p = cf.Position
	local rx, ry, rz = cf:ToEulerAnglesXYZ()
	return CF(-p.X, p.Y, p.Z) * ANG(rx, -ry, -rz)
end

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = deepCopy(v)
	end
	return out
end

local function mergeTables(base, override)
	local out = deepCopy(base)
	if type(override) == "table" then
		for k, v in pairs(override) do
			if type(v) == "table" and type(out[k]) == "table" and getmetatable(v) == nil then
				out[k] = mergeTables(out[k], v)
			else
				out[k] = v
			end
		end
	end
	return out
end

-------------------------------------------------------------------
-- CONFIGURAÇÃO PADRÃO (SOBRESCRITA PELO PERSONAGEM)
-------------------------------------------------------------------
local DEFAULT_CONFIG = {
	RENDER_NAME = "F3X_Ultrakill_Core",
	HUD_RENDER_NAME = "F3X_Ultrakill_3DHUD",
	SCALE = 1.0,
	SOLE_DEPTH = 3.66,

	FIRST_PERSON_HIDE_DIST = 1.95,
	HIDE_ALL_AVATAR_ACCESSORIES = true,
	BASE_FOV = 70,
	ENABLE_FOV_KICK = true,
	ENABLE_HEAD_AIM_TRACKING = true,

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
	SLAM_IMPULSE = 96,
	SLAM_MIN_HEIGHT = 6,
	SLAM_RANGE = 13.5,

	ENABLE_HUD = true,
	FOOTSTEP_SFX = true,

	MAX_CREATE_WORKERS = 6,
	MAX_IN_FLIGHT = 1,
	SEND_INTERVAL = 0.055,
	TARGET_SEND_INTERVAL = 0.04,
	POS_EPS = 0.055,
	ROT_EPS_DEG = 2.2,
	SYNC_CHUNK = 30,
	PARK_CF = CF(0, 25000, 0),

	DISABLE_FALLING_DOWN = true,
	IDLE_TILT_GUARD = true,

	ENABLE_KNOCKBACK = true,
	ENABLE_SEAT_CAPTURE = true,
	WALL_SLAM_ENABLED = true,
	ENABLE_DAMAGE_FLASH = true,
	DAMAGE_FLASH_PULSE_COLOR = Color3.fromRGB(255, 145, 145),
	DAMAGE_FLASH_COLOR = Color3.fromRGB(255, 30, 30),
	DAMAGE_FLASH_DURATION = 0.24,

	ENABLE_TARGET_RAGDOLL = true,
	RAGDOLL_DURATION = 1.75,
	RAGDOLL_GRAVITY = 94,

	SLAM_KNOCKBACK_POWER = { speed = 42, up = 44, spin = 11.0 },

	HUD_TITLE = "ULTRAKILL",
	PRIMARY_KEY_LABEL = "[E] PRIMARY",
	SECONDARY_KEY_LABEL = "[F] SECONDARY",
	TERTIARY_KEY_LABEL = "[R] ALT",

	COLORS = {
		BEAM_CYAN = Color3.fromRGB(115, 235, 255),
		BEAM_CORE = Color3.fromRGB(255, 255, 255),
		PARRY_FLASH = Color3.fromRGB(255, 245, 175),
		BLOOD_RED = Color3.fromRGB(185, 26, 32),
		YELLOW_NEON = Color3.fromRGB(255, 208, 30),
	},

	SOUNDS = {
		PARRY = { id = "rbxassetid://98660468032974", fallback = "rbxasset://sounds/electronicpingshort.wav", volume = 0.95, pitch = 1.00 },
		COIN_FLIP = { id = "rbxassetid://132653076390131", fallback = "rbxasset://sounds/electronicpingshort.wav", volume = 0.75, pitch = 1.55 },
		SHATTER = { id = "rbxassetid://17405655409", fallback = "rbxasset://sounds/snap.mp3", volume = 0.80, pitch = 1.15 },
		PUNCH = { id = "rbxassetid://140626490819228", fallback = "rbxasset://sounds/hit.wav", volume = 0.78, pitch = 1.05 },
		DASH = { id = "rbxassetid://6870002465", fallback = "rbxasset://sounds/action_jump.mp3", volume = 0.58, pitch = 1.15 },
		LAND = { id = "rbxassetid://6870001600", fallback = "rbxasset://sounds/action_jump_land.mp3", volume = 0.45, pitch = 1.10 },
		STEP = { id = "rbxassetid://6870002623", fallback = "rbxasset://sounds/action_footsteps_plastic.mp3", volume = 0.16, pitch = 1.65 },
		SHOT = { id = "rbxassetid://138083993", fallback = "rbxasset://sounds/Rocket shot.wav", volume = 0.72, pitch = 1.25 },
		EXPLOSION = { id = "rbxassetid://165969964", fallback = "rbxasset://sounds/collide.wav", volume = 0.85, pitch = 0.95 },
	},
}

local STYLE_RANKS = {
	{ min = 0,    code = "D", title = "DESTRUCTIVE",   color = Color3.fromRGB(70, 155, 255) },
	{ min = 150,  code = "C", title = "CHAOTIC",       color = Color3.fromRGB(85, 235, 130) },
	{ min = 400,  code = "B", title = "BRUTAL",        color = Color3.fromRGB(255, 215, 55) },
	{ min = 800,  code = "A", title = "ANARCHIC",      color = Color3.fromRGB(255, 130, 45) },
	{ min = 1350, code = "S", title = "SUPREME",       color = Color3.fromRGB(255, 55, 70) },
	{ min = 1900, code = "SS", title = "SADISTIC",     color = Color3.fromRGB(255, 45, 125) },
	{ min = 2450, code = "U", title = "ULTRAKILL",     color = Color3.fromRGB(255, 240, 120) },
}

-------------------------------------------------------------------
-- ESTADO GLOBAL DA SESSÃO ATIVA
-------------------------------------------------------------------
local STATE = nil

local function resetState()
	STATE = {
		running = true,
		building = false,
		charDef = nil,
		cfg = nil,
		endpoint = nil,
		rigFolder = nil,

		char = nil,
		hum = nil,
		root = nil,
		isR15 = false,

		parts = {},       -- [id] = BasePart
		partSpecs = {},   -- [id] = spec
		proxyParts = {},  -- list of BaseParts para NoCollision / Stepped
		fxParts = {},     -- [name] = BasePart (pool FX compartilhado)
		fxTweens = {},    -- animações temporárias das peças FX
		noColConns = {},
		origVis = {},     -- transparência original do avatar local

		-- F3X Sync queues
		lastSentCF = {},
		lastSendTime = 0,
		inFlight = 0,
		inFlightStart = 0,
		avgRTT = 0.05,

		activeTargetMoves = {}, -- [BasePart] = CFrame
		lastTargetSend = 0,
		targetInFlight = 0,
		targetInFlightStart = 0,

		-- Movimento e Combate
		stamina = 3,
		dashEnd = 0,
		dashCooldownEnd = 0,
		dashDir = V3(0, 0, -1),
		slideEnd = 0,
		slideCooldownEnd = 0,
		slideDir = V3(0, 0, -1),
		isSlamming = false,
		slamStartY = 0,
		wasGrounded = true,
		walkPhase = 0,
		lastStepHalf = -1,
		fpHideArms = false,
		isFirstPerson = false,

		-- Alvos / Ragdolls / Damage Flash
		trackedHumanoids = {},
		activeRagdolls = {},
		ramActiveUntil = 0,
		ramPartBusy = false,

		-- Style / HUD / Áudio
		styleScore = 0,
		styleFeed = {},
		hitstopUntil = 0,
		hitstopCC = nil,
		soundFolder = nil,
		soundFailed = {},
		hud = nil,
		mobileGui = nil,
		crosshairGui = nil,
		connections = {},
	}
end

-------------------------------------------------------------------
-- F3X ENDPOINT & INVOCAÇÕES SEGURAS
-------------------------------------------------------------------
local function getF3XEndpoint()
	local containers = { plr.Backpack, plr.Character, workspace }
	for _, container in ipairs(containers) do
		if container then
			for _, name in ipairs({ "Building Tools+", "Building Tools" }) do
				local tool = container:FindFirstChild(name)
				if tool then
					local sync = tool:FindFirstChild("SyncAPI")
					local ep = sync and sync:FindFirstChild("ServerEndpoint")
					if ep and ep:IsA("RemoteFunction") then
						return ep
					end
				end
			end
		end
	end
	return nil
end

local function invokeF3X(action, ...)
	local ep = STATE and STATE.endpoint
	if not ep or not ep.Parent then
		ep = getF3XEndpoint()
		if STATE then STATE.endpoint = ep end
	end
	if not ep then return false, "Sem F3X ServerEndpoint" end
	local args = { ... }
	return pcall(function()
		return ep:InvokeServer(action, table.unpack(args))
	end)
end

local function syncPartsResize(list)
	if #list == 0 then return end
	local chunk = STATE.cfg.SYNC_CHUNK
	for i = 1, #list, chunk do
		local batch = {}
		for j = i, math.min(i + chunk - 1, #list) do
			table.insert(batch, list[j])
		end
		invokeF3X("SyncResize", batch)
	end
end

local function syncPartsColor(list)
	if #list == 0 then return end
	local chunk = STATE.cfg.SYNC_CHUNK
	for i = 1, #list, chunk do
		local batch = {}
		for j = i, math.min(i + chunk - 1, #list) do
			table.insert(batch, list[j])
		end
		invokeF3X("SyncColor", batch)
	end
end

local function syncPartsMaterial(list)
	if #list == 0 then return end
	local chunk = STATE.cfg.SYNC_CHUNK
	for i = 1, #list, chunk do
		local batch = {}
		for j = i, math.min(i + chunk - 1, #list) do
			table.insert(batch, list[j])
		end
		invokeF3X("SyncMaterial", batch)
	end
end

local function syncPartsCollision(list)
	if #list == 0 then return end
	invokeF3X("SyncCollision", list)
end

local function syncPartsAnchor(list)
	if #list == 0 then return end
	invokeF3X("SyncAnchor", list)
end

-------------------------------------------------------------------
-- ÁUDIO COM FALLBACK NATIVO (rbxasset://sounds)
-------------------------------------------------------------------
function Core.playSFX(soundKeyOrDef, overridePitch, overrideVol)
	if not STATE or not STATE.running then return end
	local def = type(soundKeyOrDef) == "string" and STATE.cfg.SOUNDS[soundKeyOrDef] or soundKeyOrDef
	if not def then return end

	local folder = STATE.soundFolder
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "F3X_Ultrakill_SFX"
		folder.Parent = SoundService
		STATE.soundFolder = folder
	end

	local chosenId = def.id
	if (not chosenId) or STATE.soundFailed[chosenId] then
		chosenId = def.fallback or "rbxasset://sounds/electronicpingshort.wav"
	end

	local s = Instance.new("Sound")
	s.SoundId = chosenId
	s.Volume = overrideVol or def.volume or 0.7
	s.PlaybackSpeed = overridePitch or def.pitch or 1.0
	s.Parent = folder

	local started = false
	task.spawn(function()
		if not s.IsLoaded and def.id and not STATE.soundFailed[def.id] then
			local t0 = os.clock()
			while not s.IsLoaded and os.clock() - t0 < 0.35 do
				task.wait(0.03)
			end
			if not s.IsLoaded or s.TimeLength == 0 then
				STATE.soundFailed[def.id] = true
				if def.fallback then
					s.SoundId = def.fallback
				end
			end
		end
		if not started and s.Parent then
			started = true
			s:Play()
		end
	end)

	task.delay(2.5, function()
		if s and s.Parent then s:Destroy() end
	end)
end

-------------------------------------------------------------------
-- HITSTOP & STYLE METER
-------------------------------------------------------------------
function Core.triggerHitstop(duration, brightness, contrast)
	if not STATE or not STATE.running then return end
	local dur = duration or 0.085
	STATE.hitstopUntil = math.max(STATE.hitstopUntil, os.clock() + dur)

	local cc = STATE.hitstopCC
	if not cc or not cc.Parent then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "F3XUltrakill_HitstopCC"
		cc.Parent = Lighting
		STATE.hitstopCC = cc
	end
	cc.Brightness = brightness or 0.24
	cc.Contrast = contrast or 0.32
	cc.Enabled = true
end

function Core.addStyleBonus(label, points, color)
	if not STATE or not STATE.running then return end
	STATE.styleScore = math.clamp(STATE.styleScore + (points or 0), 0, 3200)
	table.insert(STATE.styleFeed, 1, {
		text = "+ " .. tostring(label),
		color = color or STATE.cfg.COLORS.BEAM_CYAN,
		expiresAt = os.clock() + 3.2,
	})
	if #STATE.styleFeed > 5 then
		table.remove(STATE.styleFeed, #STATE.styleFeed)
	end
end

local function getCurrentStyleRank(score)
	local best = STYLE_RANKS[1]
	for _, r in ipairs(STYLE_RANKS) do
		if score >= r.min then
			best = r
		end
	end
	return best
end

-------------------------------------------------------------------
-- TRACKER DE HUMANOIDS (SEM VARRER WORKSPACE TODO FRAME)
-------------------------------------------------------------------
local function registerHumanoid(hum)
	if not STATE or not hum or not hum:IsA("Humanoid") then return end
	local model = hum.Parent
	if not model or model == STATE.char then return end
	STATE.trackedHumanoids[hum] = model
end

local function initTargetTracker()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("Humanoid") then
			registerHumanoid(desc)
		end
	end
	table.insert(STATE.connections, workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("Humanoid") then
			registerHumanoid(desc)
		end
	end))
	table.insert(STATE.connections, workspace.DescendantRemoving:Connect(function(desc)
		if desc:IsA("Humanoid") then
			STATE.trackedHumanoids[desc] = nil
		end
	end))
end

local function getActiveTargetHumanoids()
	local out = {}
	for hum, model in pairs(STATE.trackedHumanoids) do
		if hum and hum.Parent and model and model.Parent and model ~= STATE.char and hum.Health > 0 then
			local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
			if hrp and hrp:IsA("BasePart") then
				table.insert(out, { hum = hum, char = model, hrp = hrp })
			end
		else
			STATE.trackedHumanoids[hum] = nil
		end
	end
	return out
end

function Core.getTargetsInRadius(origin, radius)
	local hits = {}
	for _, entry in ipairs(getActiveTargetHumanoids()) do
		local d = (entry.hrp.Position - origin).Magnitude
		if d <= radius then
			entry.distance = d
			table.insert(hits, entry)
		end
	end
	table.sort(hits, function(a, b) return a.distance < b.distance end)
	return hits
end

function Core.raycastTargets(origin, direction, maxDist)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { STATE.rigFolder, STATE.char }
	params.FilterDescendantsInstances = ignore

	local dirUnit = direction.Unit
	local res = workspace:Raycast(origin, dirUnit * maxDist, params)
	if res and res.Instance then
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		local hum = m and m:FindFirstChildOfClass("Humanoid")
		if hum and m ~= STATE.char and hum.Health > 0 then
			local hrp = m:FindFirstChild("HumanoidRootPart") or res.Instance
			return {
				hit = true,
				position = res.Position,
				normal = res.Normal,
				instance = res.Instance,
				target = { hum = hum, char = m, hrp = hrp },
			}
		end
		return {
			hit = true,
			position = res.Position,
			normal = res.Normal,
			instance = res.Instance,
			target = nil,
		}
	end
	return {
		hit = false,
		position = origin + dirUnit * maxDist,
		normal = -dirUnit,
		instance = nil,
		target = nil,
	}
end

-------------------------------------------------------------------
-- NO-COLLISION & VISIBILIDADE DO AVATAR LOCAL
-------------------------------------------------------------------
local function clearNoColConstraints()
	for _, c in ipairs(STATE.noColConns) do
		if c and c.Parent then c:Destroy() end
	end
	table.clear(STATE.noColConns)
end

local function attachNoColToCharacter(char)
	clearNoColConstraints()
	if not char then return end
	local charParts = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(charParts, d)
		end
	end
	for _, p in ipairs(STATE.proxyParts) do
		if p and p.Parent then
			for _, cp in ipairs(charParts) do
				local ncc = Instance.new("NoCollisionConstraint")
				ncc.Part0 = p
				ncc.Part1 = cp
				ncc.Parent = p
				table.insert(STATE.noColConns, ncc)
			end
		end
	end
end

local function hideLocalAvatar(char)
	table.clear(STATE.origVis)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			STATE.origVis[d] = d.LocalTransparencyModifier
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if STATE.cfg.HIDE_ALL_AVATAR_ACCESSORIES or d.Parent:IsA("BasePart") then
				STATE.origVis[d] = d.Transparency
				d.Transparency = 1
			end
		end
	end
end

local function restoreLocalAvatar()
	for obj, val in pairs(STATE.origVis) do
		if obj and obj.Parent then
			if obj:IsA("BasePart") then
				obj.LocalTransparencyModifier = val
			elseif obj:IsA("Decal") or obj:IsA("Texture") then
				obj.Transparency = val
			end
		end
	end
	table.clear(STATE.origVis)
end

-------------------------------------------------------------------
-- POOL DE FX COMPARTILHADO (FEIXES, EXPLOSÕES, MOEDA/GRANADA, SEAT, RAM)
-------------------------------------------------------------------
local FX_SPECS = {
	{ id = "fx_coin",   kind = "Normal", shape = Enum.MeshType.Cylinder, size = V3(0.14, 0.56, 0.56), color = Color3.fromRGB(255, 215, 45),  mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_beam1",  kind = "Normal", shape = nil,                    size = V3(0.28, 0.28, 1),    color = Color3.fromRGB(115, 235, 255), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_beam2",  kind = "Normal", shape = nil,                    size = V3(0.28, 0.28, 1),    color = Color3.fromRGB(115, 235, 255), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_bcore1", kind = "Normal", shape = nil,                    size = V3(0.12, 0.12, 1),    color = Color3.fromRGB(255, 255, 255), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_bcore2", kind = "Normal", shape = nil,                    size = V3(0.12, 0.12, 1),    color = Color3.fromRGB(255, 255, 255), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_flash",  kind = "Normal", shape = Enum.MeshType.Sphere,   size = V3(2.2, 2.2, 2.2),    color = Color3.fromRGB(255, 245, 175), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_impact", kind = "Normal", shape = Enum.MeshType.Sphere,   size = V3(3.2, 3.2, 3.2),    color = Color3.fromRGB(255, 195, 70),  mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_ring",   kind = "Normal", shape = Enum.MeshType.Cylinder, size = V3(0.25, 5.5, 5.5),   color = Color3.fromRGB(115, 235, 255), mat = Enum.Material.Neon, canCollide = false },
	{ id = "fx_seat",   kind = "Seat",   shape = nil,                    size = V3(4.8, 3.2, 4.8),    color = Color3.fromRGB(30, 30, 35),    mat = Enum.Material.SmoothPlastic, canCollide = false },
	{ id = "fx_ram",    kind = "Normal", shape = nil,                    size = V3(6.5, 6.5, 6.5),    color = Color3.fromRGB(255, 60, 60),   mat = Enum.Material.Neon, canCollide = false, allowTouch = true },
}

function Core.getActiveFXPart(name)
	return STATE and STATE.fxParts[name]
end

function Core.setFXPartState(name, cf, size, color, transparency)
	if not STATE or not STATE.running then return end
	local p = STATE.fxParts[name]
	if not p or not p.Parent then return end
	STATE.fxTweens[name] = {
		cf = cf or STATE.cfg.PARK_CF,
		size = size,
		color = color,
		transparency = transparency or 0,
		expiresAt = os.clock() + 60,
	}
end

function Core.clearFXPart(name)
	if not STATE then return end
	STATE.fxTweens[name] = nil
	local p = STATE.fxParts[name]
	if p and p.Parent then
		task.spawn(function()
			invokeF3X("SyncMove", { { Part = p, CFrame = STATE.cfg.PARK_CF } })
		end)
	end
end

function Core.spawnFXBeam(p1, p2, outerColor, coreColor, thickness, duration, slot)
	if not STATE or not STATE.running then return end
	local dist = (p2 - p1).Magnitude
	if dist < 0.05 then return end

	local mid = (p1 + p2) * 0.5
	local look = CFrame.lookAt(mid, p2)
	local w = thickness or 0.34
	local dur = duration or 0.16

	local outerName = (slot == 2) and "fx_beam2" or "fx_beam1"
	local coreName = (slot == 2) and "fx_bcore2" or "fx_bcore1"

	local bOuter = STATE.fxParts[outerName]
	local bCore = STATE.fxParts[coreName]
	task.spawn(function()
		local resizeBatch, colorBatch, matBatch = {}, {}, {}
		if bOuter and bOuter.Parent then
			table.insert(resizeBatch, { Part = bOuter, CFrame = look, Size = V3(w, w, dist) })
			table.insert(colorBatch, { Part = bOuter, Color = outerColor or STATE.cfg.COLORS.BEAM_CYAN, UnionColoring = true })
			table.insert(matBatch, { Part = bOuter, Material = Enum.Material.Neon, Transparency = 0.15, Reflectance = 0 })
		end
		if bCore and bCore.Parent then
			table.insert(resizeBatch, { Part = bCore, CFrame = look, Size = V3(w * 0.42, w * 0.42, dist) })
			table.insert(colorBatch, { Part = bCore, Color = coreColor or STATE.cfg.COLORS.BEAM_CORE, UnionColoring = true })
			table.insert(matBatch, { Part = bCore, Material = Enum.Material.Neon, Transparency = 0, Reflectance = 0 })
		end
		syncPartsColor(colorBatch)
		syncPartsMaterial(matBatch)
		syncPartsResize(resizeBatch)

		task.wait(dur)
		if not STATE or not STATE.running then return end
		local hideBatch = {}
		if bOuter and bOuter.Parent then table.insert(hideBatch, { Part = bOuter, CFrame = STATE.cfg.PARK_CF }) end
		if bCore and bCore.Parent then table.insert(hideBatch, { Part = bCore, CFrame = STATE.cfg.PARK_CF }) end
		if #hideBatch > 0 then
			invokeF3X("SyncMove", hideBatch)
		end
	end)
end

function Core.spawnFXExplosion(pos, color, endRadius, duration)
	if not STATE or not STATE.running then return end
	local flash = STATE.fxParts["fx_flash"]
	local impact = STATE.fxParts["fx_impact"]
	local ring = STATE.fxParts["fx_ring"]
	local r = endRadius or 6.5
	local dur = duration or 0.24

	task.spawn(function()
		local col = color or STATE.cfg.COLORS.PARRY_FLASH
		if flash and flash.Parent then
			syncPartsColor({ { Part = flash, Color = Color3.fromRGB(255, 250, 210), UnionColoring = true } })
			syncPartsMaterial({ { Part = flash, Material = Enum.Material.Neon, Transparency = 0.1, Reflectance = 0 } })
			syncPartsResize({ { Part = flash, CFrame = CF(pos), Size = V3(r * 0.65, r * 0.65, r * 0.65) } })
		end
		if impact and impact.Parent then
			syncPartsColor({ { Part = impact, Color = col, UnionColoring = true } })
			syncPartsMaterial({ { Part = impact, Material = Enum.Material.Neon, Transparency = 0.35, Reflectance = 0 } })
			syncPartsResize({ { Part = impact, CFrame = CF(pos), Size = V3(r * 1.4, r * 1.4, r * 1.4) } })
		end
		if ring and ring.Parent then
			syncPartsColor({ { Part = ring, Color = col, UnionColoring = true } })
			syncPartsMaterial({ { Part = ring, Material = Enum.Material.Neon, Transparency = 0.25, Reflectance = 0 } })
			syncPartsResize({ { Part = ring, CFrame = CF(pos) * ANG(0, 0, math.rad(90)), Size = V3(0.28, r * 2.1, r * 2.1) } })
		end

		task.wait(dur)
		if not STATE or not STATE.running then return end
		local hideBatch = {}
		for _, p in ipairs({ flash, impact, ring }) do
			if p and p.Parent then
				table.insert(hideBatch, { Part = p, CFrame = STATE.cfg.PARK_CF })
			end
		end
		if #hideBatch > 0 then
			invokeF3X("SyncMove", hideBatch)
		end
	end)
end

-------------------------------------------------------------------
-- SISTEMA DE KNOCKBACK (3 CAMADAS) + RAGDOLL R6/R15 + DAMAGE FLASH
-------------------------------------------------------------------
local function triggerDamageFlash(targetChar, flashColor)
	if not STATE.cfg.ENABLE_DAMAGE_FLASH or not targetChar then return end
	local orig = {}
	local batch1, batch2, batchRestore = {}, {}, {}

	for _, d in ipairs(targetChar:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 then
			orig[d] = { color = d.Color, mat = d.Material, tr = d.Transparency, ref = d.Reflectance }
			table.insert(batch1, { Part = d, Color = STATE.cfg.DAMAGE_FLASH_PULSE_COLOR, UnionColoring = true })
			table.insert(batch2, { Part = d, Color = flashColor or STATE.cfg.DAMAGE_FLASH_COLOR, UnionColoring = true })
			table.insert(batchRestore, { Part = d, Color = d.Color, UnionColoring = true })
		end
	end
	if #batch1 == 0 then return end

	task.spawn(function()
		syncPartsColor(batch1)
		task.wait(0.06)
		if targetChar.Parent then syncPartsColor(batch2) end
		task.wait(STATE.cfg.DAMAGE_FLASH_DURATION)
		if targetChar.Parent then syncPartsColor(batchRestore) end
	end)
end

local function restoreTargetRagdoll(rag)
	if not rag or rag.restored then return end
	rag.restored = true
	STATE.activeRagdolls[rag.char] = nil
	if rag.hrp then
		STATE.activeTargetMoves[rag.hrp] = nil
	end

	if rag.char and rag.char.Parent then
		if rag.hum and rag.hum.Parent then
			pcall(function()
				rag.hum.PlatformStand = false
				rag.hum.Sit = false
				rag.hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		if rag.anchoredByUs and rag.hrp and rag.hrp.Parent then
			invokeF3X("SyncAnchor", { { Part = rag.hrp, Anchored = false } })
		end
		if rag.jointsDisabled then
			for _, j in ipairs(rag.jointsDisabled) do
				if j and j.Parent then j.Enabled = true end
			end
		end
		if rag.ragSockets then
			for _, s in ipairs(rag.ragSockets) do
				if s and s.Parent then s:Destroy() end
			end
		end
		if rag.hrp and rag.hrp.Parent then
			local uprightCF = CF(rag.hrp.Position + V3(0, 1.2, 0))
			invokeF3X("SyncMove", { { Part = rag.hrp, CFrame = uprightCF } })
		end
	end
end

local function applyRagdollSockets(targetChar, rag)
	local joints = {}
	local sockets = {}
	for _, d in ipairs(targetChar:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name ~= "RootJoint" and d.Name ~= "Root" and d.Part0 and d.Part1 then
			local a0 = Instance.new("Attachment")
			a0.CFrame = d.C0
			a0.Parent = d.Part0
			local a1 = Instance.new("Attachment")
			a1.CFrame = d.C1
			a1.Parent = d.Part1

			local bsc = Instance.new("BallSocketConstraint")
			bsc.Attachment0 = a0
			bsc.Attachment1 = a1
			bsc.LimitsEnabled = true
			bsc.UpperAngle = 75
			bsc.TwistLimitsEnabled = true
			bsc.TwistLowerAngle = -45
			bsc.TwistUpperAngle = 45
			bsc.Parent = d.Part0

			d.Enabled = false
			table.insert(joints, d)
			table.insert(sockets, a0)
			table.insert(sockets, a1)
			table.insert(sockets, bsc)
		end
	end
	rag.jointsDisabled = joints
	rag.ragSockets = sockets
end

local function triggerPhysicsRamBurst(targetHRP, flatDir, power)
	local ram = STATE.fxParts["fx_ram"]
	if not ram or not ram.Parent or STATE.ramPartBusy then return end
	STATE.ramPartBusy = true
	STATE.ramActiveUntil = os.clock() + 0.30

	task.spawn(function()
		ram.CustomPhysicalProperties = PhysicalProperties.new(100, 0.2, 1, 1, 1)
		local startPos = targetHRP.Position - flatDir * 3.8
		local look = CFrame.lookAt(startPos, targetHRP.Position)

		invokeF3X("SyncMove", { { Part = ram, CFrame = look } })
		invokeF3X("SyncCollision", { { Part = ram, CanCollide = true } })
		invokeF3X("SyncAnchor", { { Part = ram, Anchored = false } })

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = V3(1e7, 1e7, 1e7)
		bv.Velocity = flatDir * (power.speed * 2.5) + V3(0, math.max(power.up * 1.4, 28), 0)
		bv.Parent = ram

		task.wait(0.26)
		if bv and bv.Parent then bv:Destroy() end

		if STATE and STATE.running and ram.Parent then
			invokeF3X("SyncAnchor", { { Part = ram, Anchored = true } })
			invokeF3X("SyncCollision", { { Part = ram, CanCollide = false } })
			invokeF3X("SyncMove", { { Part = ram, CFrame = STATE.cfg.PARK_CF } })
		end
		if STATE then STATE.ramPartBusy = false end
	end)
end

local function runPhysicsRamAndSeat(targetChar, targetHRP, flatDir, power, rag)
	if not targetHRP or not targetHRP.Parent then return end

	-- Tentativa local imediata (funciona em NPCs sem dono de rede ou cliente dono)
	pcall(function()
		targetHRP.AssemblyLinearVelocity = flatDir * power.speed + V3(0, power.up, 0)
		targetHRP.AssemblyAngularVelocity = V3(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6))
	end)

	-- Camada 2: Seat Capture
	local seat = STATE.fxParts["fx_seat"]
	if STATE.cfg.ENABLE_SEAT_CAPTURE and seat and seat.Parent and rag.hum then
		task.spawn(function()
			local velLead = targetHRP.AssemblyLinearVelocity * 0.05
			if velLead.Magnitude > 4 then velLead = velLead.Unit * 4 end
			local capCF = CF(targetHRP.Position + velLead)
			invokeF3X("SyncMove", { { Part = seat, CFrame = capCF } })
			task.wait(0.045)

			local weld = seat:FindFirstChild("SeatWeld")
			if weld and STATE.running then
				rag.mode = "seat"
				rag.hrpDrive = seat
				rag.pos = capCF.Position
				rag.vel = flatDir * power.speed + V3(0, power.up, 0)
				return
			end

			if seat and seat.Parent and STATE and STATE.running then
				invokeF3X("SyncMove", { { Part = seat, CFrame = STATE.cfg.PARK_CF } })
			end
			-- Camada 3: Physics Ram Burst
			triggerPhysicsRamBurst(targetHRP, flatDir, power)
		end)
	else
		triggerPhysicsRamBurst(targetHRP, flatDir, power)
	end
end

function Core.applyF3XKnockback(targetChar, dirVec, powerTable, hitPoint, flashColor)
	if not STATE or not STATE.running or not targetChar or targetChar == STATE.char then return end
	local hum = targetChar:FindFirstChildOfClass("Humanoid")
	local hrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
	if not hum or not hrp or hum.Health <= 0 then return end

	local power = powerTable or { speed = 55, up = 28, spin = 10 }
	local flat = V3(dirVec.X, 0, dirVec.Z)
	if flat.Magnitude < 0.01 then flat = V3(0, 0, -1) end
	flat = flat.Unit

	if flashColor ~= false then
		triggerDamageFlash(targetChar, flashColor)
	end

	if not STATE.cfg.ENABLE_KNOCKBACK then return end

	local rag = STATE.activeRagdolls[targetChar]
	if not rag then
		rag = {
			char = targetChar,
			hum = hum,
			hrp = hrp,
			mode = "direct",
			hrpDrive = hrp,
			pos = hrp.Position,
			rot = hrp.CFrame - hrp.Position,
			vel = flat * power.speed + V3(0, power.up, 0),
			angVel = V3((math.random() - 0.5) * power.spin, (math.random() - 0.5) * power.spin, (math.random() - 0.5) * power.spin),
			flatDir = flat,
			expiresAt = os.clock() + STATE.cfg.RAGDOLL_DURATION,
			noDirect = false,
			anchoredByUs = false,
			restored = false,
			wallSplatted = false,
		}
		STATE.activeRagdolls[targetChar] = rag

		pcall(function()
			hum.PlatformStand = true
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		end)
		if STATE.cfg.ENABLE_TARGET_RAGDOLL then
			applyRagdollSockets(targetChar, rag)
		end

		-- Tenta ancorar o HRP via F3X para condução direta limpa
		task.spawn(function()
			local ok = invokeF3X("SyncAnchor", { { Part = hrp, Anchored = true } })
			if ok and STATE and STATE.running and not rag.restored then
				rag.anchoredByUs = true
			else
				rag.noDirect = true
				rag.hrpDrive = nil
				runPhysicsRamAndSeat(targetChar, hrp, flat, power, rag)
			end
		end)
	else
		rag.vel = flat * power.speed + V3(0, power.up, 0)
		rag.flatDir = flat
		rag.expiresAt = os.clock() + STATE.cfg.RAGDOLL_DURATION
		rag.wallSplatted = false
		if rag.noDirect then
			runPhysicsRamAndSeat(targetChar, hrp, flat, power, rag)
		end
	end
end

local function stepTargetRagdolls(dt)
	if not STATE then return end
	local now = os.clock()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	for targetChar, rag in pairs(STATE.activeRagdolls) do
		if (not targetChar.Parent) or (not rag.hrp or not rag.hrp.Parent) or now >= rag.expiresAt then
			task.spawn(restoreTargetRagdoll, rag)
		elseif rag.hrpDrive and rag.hrpDrive.Parent then
			rag.vel = rag.vel - V3(0, STATE.cfg.RAGDOLL_GRAVITY * dt, 0)
			local stepVec = rag.vel * dt

			params.FilterDescendantsInstances = { STATE.rigFolder, STATE.char, targetChar }
			local wallHit = STATE.cfg.WALL_SLAM_ENABLED and workspace:Raycast(rag.pos, stepVec, params)
			if wallHit then
				local impact = rag.vel.Magnitude
				rag.pos = wallHit.Position + wallHit.Normal * 1.45
				rag.vel = (rag.vel - 2 * rag.vel:Dot(wallHit.Normal) * wallHit.Normal) * 0.45
				if impact > 18 and not rag.wallSplatted then
					rag.wallSplatted = true
					Core.addStyleBonus("WALL SPLAT", 150, STATE.cfg.COLORS.BEAM_CYAN)
					Core.playSFX("SHATTER", 1.1, 0.8)
					Core.spawnFXExplosion(wallHit.Position, STATE.cfg.COLORS.BLOOD_RED, 5.2, 0.2)
				end
			else
				rag.pos = rag.pos + stepVec
			end

			local floorHit = workspace:Raycast(rag.pos + V3(0, 2, 0), V3(0, -14, 0), params)
			if floorHit then
				local minY = floorHit.Position.Y + 0.95
				if rag.pos.Y < minY then
					rag.pos = V3(rag.pos.X, minY, rag.pos.Z)
					if rag.vel.Y < -14 then
						rag.vel = V3(rag.vel.X * 0.65, -rag.vel.Y * 0.35, rag.vel.Z * 0.65)
					else
						rag.vel = V3(rag.vel.X * 0.82, 0, rag.vel.Z * 0.82)
					end
				end
			end

			rag.rot = rag.rot * ANG(rag.angVel.X * dt, rag.angVel.Y * dt, rag.angVel.Z * dt)
			local nextCF = CF(rag.pos) * rag.rot
			STATE.activeTargetMoves[rag.hrpDrive] = nextCF
		end
	end
end

-------------------------------------------------------------------
-- F3X DISPATCH (RIG PRINCIPAL E ALVOS ISOLADOS)
-------------------------------------------------------------------
local function cfChangedEnough(a, b, posEps, rotEpsDeg)
	if not a then return true end
	if (a.Position - b.Position).Magnitude > posEps then return true end
	local dot = math.clamp(a.LookVector:Dot(b.LookVector), -1, 1)
	local angDeg = math.deg(math.acos(dot))
	if angDeg > rotEpsDeg then return true end
	local upDot = math.clamp(a.UpVector:Dot(b.UpVector), -1, 1)
	if math.deg(math.acos(upDot)) > rotEpsDeg then return true end
	return false
end

local function dispatchF3X(now, desiredTransforms)
	if not STATE or not STATE.running or STATE.building then return end
	if STATE.inFlight >= STATE.cfg.MAX_IN_FLIGHT then
		if now - STATE.inFlightStart < 2.0 then return end
		STATE.inFlight = 0
	end

	local interval = (STATE.avgRTT > 0.18) and 0.085 or STATE.cfg.SEND_INTERVAL
	if now - STATE.lastSendTime < interval then return end

	local moves = {}
	for id, cf in pairs(desiredTransforms) do
		local part = STATE.parts[id]
		if part and part.Parent then
			if cfChangedEnough(STATE.lastSentCF[part], cf, STATE.cfg.POS_EPS, STATE.cfg.ROT_EPS_DEG) then
				table.insert(moves, { Part = part, CFrame = cf })
				STATE.lastSentCF[part] = cf
			end
		end
	end

	for name, fx in pairs(STATE.fxTweens) do
		local p = STATE.fxParts[name]
		if p and p.Parent then
			if now >= fx.expiresAt then
				STATE.fxTweens[name] = nil
				table.insert(moves, { Part = p, CFrame = STATE.cfg.PARK_CF })
				STATE.lastSentCF[p] = STATE.cfg.PARK_CF
			elseif fx.cf and cfChangedEnough(STATE.lastSentCF[p], fx.cf, STATE.cfg.POS_EPS, STATE.cfg.ROT_EPS_DEG) then
				table.insert(moves, { Part = p, CFrame = fx.cf })
				STATE.lastSentCF[p] = fx.cf
			end
		end
	end

	if #moves == 0 then return end
	STATE.lastSendTime = now
	STATE.inFlight += 1
	STATE.inFlightStart = now

	task.spawn(function()
		local t0 = os.clock()
		local chunk = STATE.cfg.SYNC_CHUNK
		for i = 1, #moves, chunk do
			local batch = {}
			for j = i, math.min(i + chunk - 1, #moves) do
				table.insert(batch, moves[j])
			end
			invokeF3X("SyncMove", batch)
		end
		if STATE then
			local rtt = os.clock() - t0
			STATE.avgRTT = STATE.avgRTT * 0.7 + rtt * 0.3
			STATE.inFlight = math.max(0, STATE.inFlight - 1)
		end
	end)
end

local function dispatchTargetF3X(now)
	if not STATE or not STATE.running then return end
	if STATE.targetInFlight >= 1 then
		if now - STATE.targetInFlightStart < 1.5 then return end
		STATE.targetInFlight = 0
	end
	if now - STATE.lastTargetSend < STATE.cfg.TARGET_SEND_INTERVAL then return end

	local moves = {}
	for part, cf in pairs(STATE.activeTargetMoves) do
		if part and part.Parent then
			table.insert(moves, { Part = part, CFrame = cf })
		end
	end
	if #moves == 0 then return end

	STATE.lastTargetSend = now
	STATE.targetInFlight += 1
	STATE.targetInFlightStart = now

	task.spawn(function()
		local ok = invokeF3X("SyncMove", moves)
		if STATE then
			STATE.targetInFlight = math.max(0, STATE.targetInFlight - 1)
			if not ok then
				for _, rag in pairs(STATE.activeRagdolls) do
					if rag.mode == "direct" and not rag.noDirect then
						rag.noDirect = true
						rag.hrpDrive = nil
						if rag.hrp then STATE.activeTargetMoves[rag.hrp] = nil end
						runPhysicsRamAndSeat(rag.char, rag.hrp, rag.flatDir, STATE.cfg.SLAM_KNOCKBACK_POWER, rag)
					end
				end
			end
		end
	end)
end

-------------------------------------------------------------------
-- DADOS DE RIG R6 / R15 PARA OS MÓDULOS DE PERSONAGEM
-------------------------------------------------------------------
function Core.getRigData(char)
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return nil end

	local isR15 = (hum.RigType == Enum.HumanoidRigType.R15)
	local head = char:FindFirstChild("Head")
	local torso = isR15 and char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	local lArm = isR15 and char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
	local rArm = isR15 and char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
	local lLeg = isR15 and char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
	local rLeg = isR15 and char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")

	return {
		hum = hum,
		root = root,
		isR15 = isR15,
		head = head,
		torso = torso,
		leftArm = lArm,
		rightArm = rArm,
		leftLeg = lLeg,
		rightLeg = rLeg,
	}
end

-------------------------------------------------------------------
-- HUD 3D EM PERSPECTIVA + MIRA + CONTROLES MOBILE
-------------------------------------------------------------------
local function getGuiParent()
	if type(gethui) == "function" then
		local ok, hui = pcall(gethui)
		if ok and hui then return hui end
	end
	local okCore = pcall(function() return CoreGui.Name end)
	if okCore then return CoreGui end
	return plr:WaitForChild("PlayerGui")
end

local function buildHUD(charDef, cfg)
	if not cfg.ENABLE_HUD then return end

	local folder = Instance.new("Folder")
	folder.Name = "F3XUltrakill_3DHUD_Folder"
	folder.Parent = workspace

	local function createPanel(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Parent = folder

		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 120
		sg.AlwaysOnTop = true
		sg.LightInfluence = 0
		sg.Parent = p
		return p, sg
	end

	local leftP, leftSG = createPanel("HUD_Left", V3(2.4, 1.35, 0.05))
	local rightP, rightSG = createPanel("HUD_Right", V3(2.4, 1.55, 0.05))

	-- Painel Esquerdo: HP + Stamina + Estado da Arma
	local lBg = Instance.new("Frame")
	lBg.Size = UDim2.fromScale(1, 1)
	lBg.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	lBg.BackgroundTransparency = 0.25
	lBg.BorderSizePixel = 0
	lBg.Parent = leftSG
	Instance.new("UICorner", lBg).CornerRadius = UDim.new(0, 10)
	local lStroke = Instance.new("UIStroke", lBg)
	lStroke.Color = cfg.COLORS.YELLOW_NEON or Color3.fromRGB(255, 208, 30)
	lStroke.Thickness = 2

	local hpLbl = Instance.new("TextLabel", lBg)
	hpLbl.Size = UDim2.new(1, -20, 0, 42)
	hpLbl.Position = UDim2.fromOffset(10, 8)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Font = Enum.Font.GothamBlack
	hpLbl.Text = "HP 100"
	hpLbl.TextColor3 = Color3.fromRGB(255, 70, 80)
	hpLbl.TextSize = 30
	hpLbl.TextXAlignment = Enum.TextXAlignment.Left

	local stamContainer = Instance.new("Frame", lBg)
	stamContainer.Size = UDim2.new(1, -20, 0, 16)
	stamContainer.Position = UDim2.fromOffset(10, 56)
	stamContainer.BackgroundTransparency = 1

	local stamBars = {}
	for i = 1, cfg.MAX_STAMINA do
		local bar = Instance.new("Frame", stamContainer)
		bar.Size = UDim2.new(1 / cfg.MAX_STAMINA, -6, 1, 0)
		bar.Position = UDim2.new((i - 1) / cfg.MAX_STAMINA, 0, 0, 0)
		bar.BackgroundColor3 = Color3.fromRGB(55, 195, 255)
		bar.BorderSizePixel = 0
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
		stamBars[i] = bar
	end

	local weaponLbl = Instance.new("TextLabel", lBg)
	weaponLbl.Size = UDim2.new(1, -20, 0, 26)
	weaponLbl.Position = UDim2.fromOffset(10, 84)
	weaponLbl.BackgroundTransparency = 1
	weaponLbl.Font = Enum.Font.GothamBold
	weaponLbl.Text = cfg.HUD_TITLE
	weaponLbl.TextColor3 = Color3.fromRGB(235, 240, 250)
	weaponLbl.TextSize = 18
	weaponLbl.TextXAlignment = Enum.TextXAlignment.Left

	local hintLbl = Instance.new("TextLabel", lBg)
	hintLbl.Size = UDim2.new(1, -20, 0, 32)
	hintLbl.Position = UDim2.fromOffset(10, 114)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Font = Enum.Font.Code
	hintLbl.Text = cfg.PRIMARY_KEY_LABEL .. " | " .. cfg.SECONDARY_KEY_LABEL
	hintLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
	hintLbl.TextSize = 13
	hintLbl.TextXAlignment = Enum.TextXAlignment.Left

	-- Painel Direito: Style Rank + Feed
	local rBg = Instance.new("Frame", rightSG)
	rBg.Size = UDim2.fromScale(1, 1)
	rBg.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	rBg.BackgroundTransparency = 0.25
	rBg.BorderSizePixel = 0
	Instance.new("UICorner", rBg).CornerRadius = UDim.new(0, 10)
	local rStroke = Instance.new("UIStroke", rBg)
	rStroke.Color = Color3.fromRGB(255, 215, 55)
	rStroke.Thickness = 2

	local rankLbl = Instance.new("TextLabel", rBg)
	rankLbl.Size = UDim2.new(1, -20, 0, 46)
	rankLbl.Position = UDim2.fromOffset(10, 8)
	rankLbl.BackgroundTransparency = 1
	rankLbl.Font = Enum.Font.GothamBlack
	rankLbl.Text = "D  DESTRUCTIVE"
	rankLbl.TextColor3 = Color3.fromRGB(70, 155, 255)
	rankLbl.TextSize = 26
	rankLbl.TextXAlignment = Enum.TextXAlignment.Left

	local feedLbl = Instance.new("TextLabel", rBg)
	feedLbl.Size = UDim2.new(1, -20, 1, -64)
	feedLbl.Position = UDim2.fromOffset(10, 56)
	feedLbl.BackgroundTransparency = 1
	feedLbl.Font = Enum.Font.Code
	feedLbl.Text = ""
	feedLbl.TextColor3 = Color3.fromRGB(235, 240, 248)
	feedLbl.TextSize = 16
	feedLbl.TextXAlignment = Enum.TextXAlignment.Left
	feedLbl.TextYAlignment = Enum.TextYAlignment.Top

	-- Crosshair central 2D
	local chGui = Instance.new("ScreenGui")
	chGui.Name = "F3XUltrakill_Crosshair"
	chGui.ResetOnSpawn = false
	chGui.Parent = getGuiParent()

	local dot = Instance.new("Frame", chGui)
	dot.Size = UDim2.fromOffset(6, 6)
	dot.Position = UDim2.new(0.5, -3, 0.5, -3)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

	STATE.crosshairGui = chGui
	STATE.hud = {
		folder = folder,
		leftP = leftP,
		rightP = rightP,
		hpLbl = hpLbl,
		stamBars = stamBars,
		weaponLbl = weaponLbl,
		hintLbl = hintLbl,
		rankLbl = rankLbl,
		rStroke = rStroke,
		feedLbl = feedLbl,
	}
end

local function buildMobileControls(cfg)
	if not UIS.TouchEnabled then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "F3XUltrakill_MobileControls"
	gui.ResetOnSpawn = false
	gui.Parent = getGuiParent()

	local function makeTouchBtn(text, pos, size, bg, callback)
		local b = Instance.new("TextButton", gui)
		b.Size = size
		b.Position = pos
		b.BackgroundColor3 = bg
		b.BackgroundTransparency = 0.25
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamBlack
		b.Text = text
		b.TextColor3 = Color3.fromRGB(245, 245, 248)
		b.TextSize = 12
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke", b)
		st.Color = Color3.fromRGB(220, 225, 235)
		st.Thickness = 1.2
		table.insert(STATE.connections, b.MouseButton1Click:Connect(callback))
		return b
	end

	makeTouchBtn("DASH", UDim2.new(1, -155, 1, -210), UDim2.fromOffset(66, 46), Color3.fromRGB(35, 120, 210), function()
		Core.triggerDash()
	end)
	makeTouchBtn("SLAM/SLIDE", UDim2.new(1, -82, 1, -210), UDim2.fromOffset(72, 46), Color3.fromRGB(210, 115, 35), function()
		Core.triggerSlideOrSlam()
	end)
	makeTouchBtn("PRIMARY", UDim2.new(1, -155, 1, -155), UDim2.fromOffset(66, 50), Color3.fromRGB(45, 175, 95), function()
		if STATE and STATE.charDef and STATE.charDef.onPrimaryAction then
			STATE.charDef.onPrimaryAction(Core.getContext())
		end
	end)
	makeTouchBtn("PUNCH", UDim2.new(1, -82, 1, -155), UDim2.fromOffset(72, 50), Color3.fromRGB(205, 45, 55), function()
		if STATE and STATE.charDef and STATE.charDef.onSecondaryAction then
			STATE.charDef.onSecondaryAction(Core.getContext())
		end
	end)
	makeTouchBtn("ALT [R]", UDim2.new(1, -155, 1, -96), UDim2.fromOffset(66, 40), Color3.fromRGB(95, 75, 185), function()
		if STATE and STATE.charDef and STATE.charDef.onTertiaryAction then
			STATE.charDef.onTertiaryAction(Core.getContext())
		end
	end)
	makeTouchBtn("1P [X]", UDim2.new(1, -82, 1, -96), UDim2.fromOffset(72, 40), Color3.fromRGB(55, 60, 75), function()
		if STATE then STATE.fpHideArms = not STATE.fpHideArms end
	end)

	STATE.mobileGui = gui
end

local function stepHUD(dt, hudInfo)
	if not STATE or not STATE.hud then return end
	local cam = workspace.CurrentCamera
	if not cam then return end

	local h = STATE.hud
	local camCF = cam.CFrame
	h.leftP.CFrame = camCF * CF(-2.35, -0.75, -3.6) * ANG(0, math.rad(22), 0)
	h.rightP.CFrame = camCF * CF(2.35, 0.35, -3.7) * ANG(0, math.rad(-22), 0)

	if STATE.hum then
		h.hpLbl.Text = "HP " .. tostring(math.floor(math.max(0, STATE.hum.Health)))
	end

	for i, bar in ipairs(h.stamBars) do
		local fill = math.clamp(STATE.stamina - (i - 1), 0, 1)
		bar.BackgroundColor3 = (fill >= 1) and Color3.fromRGB(60, 210, 255) or Color3.fromRGB(35, 70, 95)
	end

	if hudInfo then
		h.weaponLbl.Text = hudInfo.title or STATE.cfg.HUD_TITLE
		h.hintLbl.Text = (hudInfo.hint or (STATE.cfg.PRIMARY_KEY_LABEL .. " | " .. STATE.cfg.SECONDARY_KEY_LABEL))
			.. (STATE.fpHideArms and " | [X] 1P:OFF" or " | [X] 1P:ON")
	end

	STATE.styleScore = math.max(0, STATE.styleScore - 55 * dt)
	local rank = getCurrentStyleRank(STATE.styleScore)
	h.rankLbl.Text = rank.code .. "  " .. rank.title
	h.rankLbl.TextColor3 = rank.color
	h.rStroke.Color = rank.color

	local now = os.clock()
	local lines = {}
	for i = #STATE.styleFeed, 1, -1 do
		if now >= STATE.styleFeed[i].expiresAt then
			table.remove(STATE.styleFeed, i)
		end
	end
	for _, item in ipairs(STATE.styleFeed) do
		table.insert(lines, item.text)
	end
	h.feedLbl.Text = table.concat(lines, "\n")
end

-------------------------------------------------------------------
-- AÇÕES DE MOVIMENTO COMPARTILHADAS (DASH / SLIDE / SLAM)
-------------------------------------------------------------------
function Core.triggerDash()
	if not STATE or not STATE.running or not STATE.cfg.ENABLE_DASH then return end
	local now = os.clock()
	if now < STATE.dashCooldownEnd or STATE.stamina < 1 or not STATE.root then return end

	STATE.stamina -= 1
	STATE.dashEnd = now + STATE.cfg.DASH_DURATION
	STATE.dashCooldownEnd = now + STATE.cfg.DASH_COOLDOWN

	local cam = workspace.CurrentCamera
	local look = cam and cam.CFrame.LookVector or STATE.root.CFrame.LookVector
	local flatLook = V3(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then flatLook = V3(0, 0, -1) end
	flatLook = flatLook.Unit

	local moveDir = STATE.hum and STATE.hum.MoveDirection or V3()
	if moveDir.Magnitude > 0.1 then
		STATE.dashDir = V3(moveDir.X, 0, moveDir.Z).Unit
	else
		STATE.dashDir = flatLook
	end

	Core.playSFX("DASH")
	if STATE.charDef and STATE.charDef.onDash then
		STATE.charDef.onDash(Core.getContext())
	end
end

function Core.triggerSlideOrSlam()
	if not STATE or not STATE.running or not STATE.cfg.ENABLE_SLIDE_SLAM then return end
	if not STATE.hum or not STATE.root then return end
	local now = os.clock()
	local grounded = (STATE.hum.FloorMaterial ~= Enum.Material.Air)

	if grounded then
		if now < STATE.slideCooldownEnd then return end
		STATE.slideEnd = now + STATE.cfg.SLIDE_DURATION
		STATE.slideCooldownEnd = now + STATE.cfg.SLIDE_COOLDOWN
		local moveDir = STATE.hum.MoveDirection
		if moveDir.Magnitude > 0.1 then
			STATE.slideDir = V3(moveDir.X, 0, moveDir.Z).Unit
		else
			local look = STATE.root.CFrame.LookVector
			STATE.slideDir = V3(look.X, 0, look.Z).Unit
		end
		Core.playSFX("STEP", 0.9, 0.4)
	else
		if STATE.isSlamming then return end
		STATE.isSlamming = true
		STATE.slamStartY = STATE.root.Position.Y
		STATE.root.AssemblyLinearVelocity = V3(0, -STATE.cfg.SLAM_SPEED, 0)
		Core.playSFX("DASH", 0.72, 0.7)
	end
end

function Core.getContext()
	return {
		Core = Core,
		state = STATE,
		cfg = STATE and STATE.cfg,
		char = STATE and STATE.char,
		hum = STATE and STATE.hum,
		root = STATE and STATE.root,
		parts = STATE and STATE.parts,
		scale = (STATE and STATE.cfg and STATE.cfg.SCALE) or 1.0,
	}
end

-------------------------------------------------------------------
-- BUILD PARALELO DAS PARTES F3X
-------------------------------------------------------------------
local function buildAllParts(charDef, cfg)
	STATE.building = true
	STATE.endpoint = getF3XEndpoint()
	if not STATE.endpoint then
		STATE.building = false
		warn("[ULTRAKILL CORE] Building Tools (F3X) não encontrado!")
		return false
	end

	if STATE.rigFolder and STATE.rigFolder.Parent then
		STATE.rigFolder:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "F3X_Ultrakill_Rig_" .. tostring(charDef.id or "char")
	folder.Parent = workspace
	STATE.rigFolder = folder

	local modelSpecs = charDef.buildModel(Core.getContext())
	local allSpecs = {}
	for _, s in ipairs(modelSpecs) do
		table.insert(allSpecs, s)
	end
	for _, fx in ipairs(FX_SPECS) do
		table.insert(allSpecs, fx)
	end

	local queue = {}
	for i, spec in ipairs(allSpecs) do
		queue[i] = spec
	end
	local cursor = 1
	local createdParts = {}
	local lockDone = 0
	local workerCount = math.min(cfg.MAX_CREATE_WORKERS, #queue)

	for _ = 1, workerCount do
		task.spawn(function()
			while STATE and STATE.running do
				local idx = cursor
				cursor += 1
				local spec = queue[idx]
				if not spec then break end

				local ok, part = invokeF3X("CreatePart", spec.kind or "Normal", cfg.PARK_CF, folder)
				if ok and typeof(part) == "Instance" and part:IsA("BasePart") then
					part.Name = spec.id
					createdParts[spec.id] = { part = part, spec = spec }
				end
			end
			lockDone += 1
		end)
	end

	while lockDone < workerCount and STATE and STATE.running do
		task.wait(0.03)
	end
	if not STATE or not STATE.running then
		STATE.building = false
		return false
	end

	local resizeB, colorB, matB, colB, ancB, meshB = {}, {}, {}, {}, {}, {}
	for id, entry in pairs(createdParts) do
		local p, sp = entry.part, entry.spec
		if id:sub(1, 3) == "fx_" then
			STATE.fxParts[id] = p
		else
			STATE.parts[id] = p
			STATE.partSpecs[id] = sp
		end
		table.insert(STATE.proxyParts, p)

		table.insert(resizeB, { Part = p, CFrame = cfg.PARK_CF, Size = sp.size })
		table.insert(colorB, { Part = p, Color = sp.color, UnionColoring = true })
		table.insert(matB, { Part = p, Material = sp.mat or Enum.Material.SmoothPlastic, Transparency = sp.transparency or 0, Reflectance = sp.reflectance or 0 })
		table.insert(colB, { Part = p, CanCollide = (sp.canCollide == true) })
		table.insert(ancB, { Part = p, Anchored = true })
		if sp.shape then
			table.insert(meshB, { Part = p, MeshType = sp.shape })
		end
	end

	if #meshB > 0 then invokeF3X("CreateMeshes", meshB) end
	syncPartsColor(colorB)
	syncPartsMaterial(matB)
	syncPartsCollision(colB)
	syncPartsAnchor(ancB)
	syncPartsResize(resizeB)

	if STATE.char then
		attachNoColToCharacter(STATE.char)
	end
	STATE.building = false
	return true
end

-------------------------------------------------------------------
-- CLEANUP GLOBAL & REBUILD
-------------------------------------------------------------------
local function cleanup()
	if not STATE then return end
	STATE.running = false

	pcall(function() RunService:UnbindFromRenderStep(STATE.cfg.RENDER_NAME) end)
	for _, conn in ipairs(STATE.connections) do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(STATE.connections)

	for _, rag in pairs(STATE.activeRagdolls) do
		pcall(restoreTargetRagdoll, rag)
	end
	table.clear(STATE.activeRagdolls)

	clearNoColConstraints()
	restoreLocalAvatar()

	if STATE.hum and STATE.hum.Parent then
		pcall(function()
			STATE.hum.CameraOffset = V3(0, 0, 0)
			STATE.hum.WalkSpeed = 16
			if STATE.cfg.DISABLE_FALLING_DOWN then
				STATE.hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				STATE.hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			end
		end)
	end

	local cam = workspace.CurrentCamera
	if cam then cam.FieldOfView = STATE.cfg.BASE_FOV end

	local toRemove = {}
	for _, p in pairs(STATE.parts) do
		if p and p.Parent then table.insert(toRemove, p) end
	end
	for _, p in pairs(STATE.fxParts) do
		if p and p.Parent then table.insert(toRemove, p) end
	end
	if #toRemove > 0 then
		task.spawn(function()
			invokeF3X("Remove", toRemove)
		end)
	end

	if STATE.rigFolder and STATE.rigFolder.Parent then STATE.rigFolder:Destroy() end
	if STATE.hud and STATE.hud.folder and STATE.hud.folder.Parent then STATE.hud.folder:Destroy() end
	if STATE.crosshairGui and STATE.crosshairGui.Parent then STATE.crosshairGui:Destroy() end
	if STATE.mobileGui and STATE.mobileGui.Parent then STATE.mobileGui:Destroy() end
	if STATE.hitstopCC and STATE.hitstopCC.Parent then STATE.hitstopCC:Destroy() end
	if STATE.soundFolder and STATE.soundFolder.Parent then STATE.soundFolder:Destroy() end

	STATE = nil
end

local function forceRebuild()
	if not STATE or not STATE.charDef then return end
	local savedDef = STATE.charDef
	cleanup()
	Core.start(savedDef)
end

-------------------------------------------------------------------
-- INICIALIZAÇÃO PRINCIPAL DO PERSONAGEM
-------------------------------------------------------------------
function Core.start(charDef)
	-- Limpa qualquer instância anterior (V1, V2 ou legado)
	for _, key in ipairs({ "F3XUltrakillCleanup", "F3XV1ReanimCleanup", "F3XV2ReanimCleanup", "F3XR6ReanimCleanup", "F3XMayhemIdleCleanup" }) do
		if type(env[key]) == "function" then
			pcall(env[key])
		end
	end

	resetState()
	STATE.charDef = charDef
	STATE.cfg = mergeTables(DEFAULT_CONFIG, charDef.config)
	STATE.stamina = STATE.cfg.MAX_STAMINA

	local cfg = STATE.cfg
	env.F3XUltrakillCleanup = cleanup
	env.F3XUltrakillRebuild = forceRebuild

	local function bindCharacter(char)
		if not STATE or not STATE.running or not char then return end
		STATE.char = char
		STATE.hum = char:WaitForChild("Humanoid", 5)
		STATE.root = char:WaitForChild("HumanoidRootPart", 5)
		if not STATE.hum or not STATE.root then return end

		STATE.isR15 = (STATE.hum.RigType == Enum.HumanoidRigType.R15)
		if cfg.DISABLE_FALLING_DOWN then
			pcall(function()
				STATE.hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				STATE.hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			end)
		end

		hideLocalAvatar(char)
		attachNoColToCharacter(char)

		if next(STATE.parts) == nil then
			task.spawn(buildAllParts, charDef, cfg)
		end
	end

	initTargetTracker()
	buildHUD(charDef, cfg)
	buildMobileControls(cfg)

	if plr.Character then
		bindCharacter(plr.Character)
	end

	table.insert(STATE.connections, plr.CharacterAdded:Connect(function(newChar)
		if STATE and STATE.running then
			task.wait(0.25)
			bindCharacter(newChar)
		end
	end))

	-- Input teclado (PC)
	table.insert(STATE.connections, UIS.InputBegan:Connect(function(input, gp)
		if gp or not STATE or not STATE.running then return end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.Q then
			Core.triggerDash()
		elseif kc == Enum.KeyCode.C or kc == Enum.KeyCode.LeftControl then
			Core.triggerSlideOrSlam()
		elseif kc == Enum.KeyCode.E then
			if charDef.onPrimaryAction then charDef.onPrimaryAction(Core.getContext()) end
		elseif kc == Enum.KeyCode.F then
			if charDef.onSecondaryAction then charDef.onSecondaryAction(Core.getContext()) end
		elseif kc == Enum.KeyCode.R then
			if charDef.onTertiaryAction then charDef.onTertiaryAction(Core.getContext()) end
		elseif kc == Enum.KeyCode.X then
			STATE.fpHideArms = not STATE.fpHideArms
		elseif kc == Enum.KeyCode.F6 then
			cleanup()
		elseif kc == Enum.KeyCode.F7 then
			forceRebuild()
		end
	end))

	-- Física / Estabilidade / NoCollision contínua
	table.insert(STATE.connections, RunService.Stepped:Connect(function()
		if not STATE or not STATE.running then return end
		local ramActive = (os.clock() < STATE.ramActiveUntil)
		for _, p in ipairs(STATE.proxyParts) do
			if p and p.Parent then
				if p.Name == "fx_ram" then
					p.CanCollide = ramActive
				elseif p.Name == "fx_seat" then
					p.CanCollide = false
				else
					p.CanCollide = false
				end
			end
		end

		if cfg.IDLE_TILT_GUARD and STATE.root and STATE.hum and STATE.hum.FloorMaterial ~= Enum.Material.Air then
			local pos = STATE.root.Position
			local look = STATE.root.CFrame.LookVector
			local flatLook = V3(look.X, 0, look.Z)
			if flatLook.Magnitude > 0.01 then
				local targetUp = V3(0, 1, 0)
				if STATE.root.CFrame.UpVector:Dot(targetUp) < 0.92 then
					STATE.root.CFrame = CFrame.lookAt(pos, pos + flatLook.Unit)
					STATE.root.AssemblyAngularVelocity = V3(0, 0, 0)
				end
			end
		end
	end))

	-- Loop principal pós-câmera
	RunService:BindToRenderStep(cfg.RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not STATE or not STATE.running then return end
		local now = os.clock()

		-- Hitstop CC fade
		if STATE.hitstopCC and STATE.hitstopCC.Enabled and now >= STATE.hitstopUntil then
			STATE.hitstopCC.Enabled = false
		end

		-- Verifica avatar local e câmera 1P
		local cam = workspace.CurrentCamera
		if cam and STATE.char and STATE.hum and STATE.root then
			local head = STATE.char:FindFirstChild("Head")
			local headPos = head and head.Position or (STATE.root.Position + V3(0, 1.5, 0))
			local dist = (cam.CFrame.Position - headPos).Magnitude
			STATE.isFirstPerson = (dist <= cfg.FIRST_PERSON_HIDE_DIST)

			if cfg.SCALE ~= 1.0 then
				local extraH = (cfg.SCALE - 1.0) * 1.45
				STATE.hum.CameraOffset = V3(0, extraH, 0)
			end

			-- Stamina regen
			if STATE.stamina < cfg.MAX_STAMINA and now >= STATE.dashEnd then
				STATE.stamina = math.min(cfg.MAX_STAMINA, STATE.stamina + dt / cfg.STAMINA_REGEN_TIME)
			end

			-- Dash / Slide / Slam velocidade + FOV
			local sprinting = cfg.ENABLE_SPRINT and UIS:IsKeyDown(Enum.KeyCode.LeftShift)
			if now < STATE.dashEnd then
				STATE.root.AssemblyLinearVelocity = STATE.dashDir * cfg.DASH_SPEED + V3(0, 1.5, 0)
			elseif now < STATE.slideEnd then
				STATE.root.AssemblyLinearVelocity = STATE.slideDir * cfg.SLIDE_SPEED + V3(0, STATE.root.AssemblyLinearVelocity.Y, 0)
			elseif STATE.isSlamming then
				STATE.root.AssemblyLinearVelocity = V3(0, -cfg.SLAM_SPEED, 0)
			else
				STATE.hum.WalkSpeed = sprinting and cfg.SPRINT_SPEED or cfg.WALK_SPEED
			end

			local grounded = (STATE.hum.FloorMaterial ~= Enum.Material.Air)
			if STATE.isSlamming and grounded then
				STATE.isSlamming = false
				local dropDist = STATE.slamStartY - STATE.root.Position.Y
				Core.playSFX("LAND", 0.85, 0.85)
				if dropDist >= cfg.SLAM_MIN_HEIGHT then
					Core.playSFX("EXPLOSION", 1.15, 0.85)
					Core.spawnFXExplosion(STATE.root.Position - V3(0, 2, 0), cfg.COLORS.BEAM_CYAN, cfg.SLAM_RANGE * 0.6, 0.25)
					local hits = Core.getTargetsInRadius(STATE.root.Position, cfg.SLAM_RANGE)
					if #hits > 0 then
						Core.addStyleBonus("GROUND SLAM", 180, cfg.COLORS.BEAM_CYAN)
						for _, t in ipairs(hits) do
							local outDir = (t.hrp.Position - STATE.root.Position)
							Core.applyF3XKnockback(t.char, outDir, cfg.SLAM_KNOCKBACK_POWER, t.hrp.Position, cfg.COLORS.BEAM_CYAN)
						end
					else
						Core.addStyleBonus("SLAM", 60, cfg.COLORS.BEAM_CYAN)
					end
					if charDef.onSlamImpact then
						charDef.onSlamImpact(Core.getContext(), STATE.root.Position, hits)
					end
				end
			elseif not STATE.wasGrounded and grounded then
				Core.playSFX("LAND")
			end
			STATE.wasGrounded = grounded

			-- Passos
			if cfg.FOOTSTEP_SFX and grounded and now >= STATE.slideEnd and now >= STATE.dashEnd then
				local horizSpeed = V3(STATE.root.AssemblyLinearVelocity.X, 0, STATE.root.AssemblyLinearVelocity.Z).Magnitude
				if horizSpeed > 4 then
					STATE.walkPhase += dt * (horizSpeed * 0.42)
					local half = math.floor(STATE.walkPhase / math.pi)
					if half ~= STATE.lastStepHalf then
						STATE.lastStepHalf = half
						Core.playSFX("STEP", sprinting and 1.9 or 1.6)
					end
				end
			end

			if cfg.ENABLE_FOV_KICK then
				local targetFOV = cfg.BASE_FOV
				if now < STATE.dashEnd or now < STATE.slideEnd then
					targetFOV = cfg.BASE_FOV + 14
				elseif sprinting and STATE.hum.MoveDirection.Magnitude > 0.1 then
					targetFOV = cfg.BASE_FOV + 7
				end
				cam.FieldOfView = Core.lerpNum(cam.FieldOfView, targetFOV, dt * 12)
			end
		end

		-- Animação e posicionamento do personagem ativo
		if STATE.char and STATE.root and not STATE.building then
			local transforms, hudInfo = charDef.poseRig(Core.getContext(), dt, {
				now = now,
				isFirstPerson = STATE.isFirstPerson,
				fpHideArms = STATE.fpHideArms,
				isDashing = (now < STATE.dashEnd),
				isSliding = (now < STATE.slideEnd),
				isSlamming = STATE.isSlamming,
				isSprinting = (cfg.ENABLE_SPRINT and UIS:IsKeyDown(Enum.KeyCode.LeftShift)),
			})
			if transforms then
				dispatchF3X(now, transforms)
			end
			stepHUD(dt, hudInfo)
		end

		-- Física dos alvos em ragdoll + SyncMove isolado
		stepTargetRagdolls(dt)
		dispatchTargetF3X(now)
	end)
end

return Core