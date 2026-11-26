-- ULTRAKILL // MINOS PRIME (P-1: SOUL SURVIVOR) F3X CHARACTER MODULE
-- Path: characters/minos.lua
-- Architecture: return function(Core) -> { cleanup = fn, rebuild = fn, ... }
-- Features:
--   * Authentic Minos Prime F3X Rig (translucent bluish-white body, glowing red heart,
--     branching circulatory veins, sunken black face void, uneven rectangular prism crown,
--     and twin segmented serpents coiled around both forearms)
--   * Full P-1 Moveset (Thy End Is Now 4-hit + Uppercut cancel, Prepare Thyself 2-kick +
--     homing Golden Serpent, Judgement teleport dropkick with gold parry flash, Die! midair
--     rider kick + shockwave, Crush! ground slam, Phase 2 "WEAK." enrage)
--   * PC + Mobile Touch HUD in SmileOS 2.0 / ULTRAKILL style
--   * Zero unanchored / colliding F3X rig parts (anti-fling safe)

return function(Core)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local CoreGui = game:GetService("CoreGui")

	local LocalPlayer = Players.LocalPlayer
	local env = (getgenv and getgenv()) or _G

	--// Cleanup any previous Minos instance before booting
	for _, store in ipairs({ env, _G }) do
		if type(store.F3XMinosReanimCleanup) == "function" then
			pcall(store.F3XMinosReanimCleanup)
		end
	end

	--// Core Math & Utility Helpers (with safe standalone fallbacks)
	local C = (Core and Core.C) or CFrame.new
	local V = (Core and Core.V) or Vector3.new
	local ID_CF = (Core and Core.ID_CF) or CFrame.new()
	local PARK_CF = (Core and Core.PARK_CF) or CFrame.new(0, -5000, 0)

	local clamp = (Core and Core.clamp) or function(x, a, b)
		if x < a then return a end
		if x > b then return b end
		return x
	end

	local lerp = (Core and Core.lerp) or function(a, b, t)
		return a + (b - a) * t
	end

	local easeOutQuad = (Core and Core.easeOutQuad) or function(t)
		return 1 - (1 - t) * (1 - t)
	end

	local easeOutBack = (Core and Core.easeOutBack) or function(t)
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
	end

	local angles = (Core and Core.angles) or function(rx, ry, rz)
		return CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	end

	local mirrorRelCF = (Core and Core.mirrorRelCF) or function(cf)
		local p = cf.Position
		local rx, ry, rz = cf:ToOrientation()
		return CFrame.new(-p.X, p.Y, p.Z) * CFrame.Angles(rx, -ry, -rz)
	end

	--// Authentic Minos Prime Palette
	local PALETTE = {
		BODY_SHELL   = Color3.fromRGB(185, 232, 255), -- Pale bluish-white translucent flesh
		BODY_HIGHLIGHT = Color3.fromRGB(220, 245, 255), -- Bright highlights
		CROWN_PRISM  = Color3.fromRGB(195, 238, 255), -- Crown rectangular prisms
		FACE_VOID    = Color3.fromRGB(6, 6, 9),       -- Hollow pitch-black face cavity
		HEART_RED    = Color3.fromRGB(225, 28, 45),   -- Exposed glowing red heart
		HEART_CORE   = Color3.fromRGB(255, 75, 90),   -- Pulsing inner heart highlight
		VEIN_CYAN    = Color3.fromRGB(80, 225, 255),  -- Glowing circulatory veins
		SERPENT_BODY = Color3.fromRGB(130, 235, 255), -- Coiled forearm snakes
		SERPENT_EYE  = Color3.fromRGB(255, 215, 75),  -- Snake / parry gold accent
		GOLD_FLASH   = Color3.fromRGB(255, 210, 65),  -- Parryable Judgement/Serpent flash
		PHASE2_AURA  = Color3.fromRGB(55, 195, 255),  -- "WEAK!" Phase 2 blue flame
		SHOCKWAVE    = Color3.fromRGB(115, 235, 255),
	}

	local CONFIG = {
		SCALE = 1.12,
		SOLE_DEPTH = 3.66,
		CHEST_OFFSET = 0.56,
		ABDOMEN_OFFSET = -0.22,
		PELVIS_OFFSET = -0.80,
		SHOULDER_X = 1.28,
		SHOULDER_Y = 0.24,
		UPPER_ARM_LEN = 1.02,
		HIP_X = 0.48,
		HIP_Y = -0.18,
		THIGH_LEN = 1.18,
		WALK_SPEED = 20,
		SPRINT_SPEED = 36,
		DASH_SPEED = 88,
		MAX_STAMINA = 3,
		STAMINA_REGEN_SEC = 1.15,
		SYNC_BATCH_SIZE = 80,
		MAX_FX_PARTS = 14,
	}

	--// Runtime State
	local alive = true
	local isBuilding = false
	local state = {
		mode = "IDLE", -- IDLE, BOXING, KICK_COMBO, JUDGEMENT, DIE_DIVE, CRUSH, DASH
		phase2 = false,
		stamina = CONFIG.MAX_STAMINA,
		staminaAccum = 0,
		comboStep = 0,
		comboResetAt = 0,
		actionStartedAt = 0,
		actionDuration = 0,
		cooldowns = {
			punch = 0,
			snake = 0,
			judgement = 0,
			drop = 0,
			dash = 0,
		},
		walkCycle = 0,
		calloutText = "AWAITING PREY",
		calloutUntil = 0,
		parryFlashUntil = 0,
		lastVisualTintState = "BASE", -- BASE, PARRY, PHASE2
		aimPoint = nil,
		diveStartPos = nil,
		diveTargetPos = nil,
	}

	local connections = {}
	local function trackConn(c)
		table.insert(connections, c)
		return c
	end

	local rigParts = {}      -- { { part = Instance, limb = string, relCF = CFrame, baseColor = Color3, baseMat = Enum.Material, baseTrans = number, role = string } }
	local allOwnedParts = {} -- { Instance }
	local activeProjectiles = {} -- homing serpent projectiles
	local activeShockwaves = {}  -- expanding shockwave rings
	local cachedEndpoint = nil
	local rigModelName = "ULTRAKILL_MINOS_RIG_" .. LocalPlayer.UserId

	--// =====================================================================
	--// F3X ENDPOINT & BATCHING
	--// =====================================================================
	local function findEndpointIn(container)
		if not container then return nil end
		for _, item in ipairs(container:GetChildren()) do
			local api = item:FindFirstChild("SyncAPI") or item:FindFirstChild("SyncApi")
			if api then
				local ep = api:FindFirstChild("ServerEndpoint") or api:FindFirstChild("ServerControl")
				if ep and ep:IsA("RemoteFunction") then
					return ep
				end
			end
		end
		return nil
	end

	local function getF3XEndpoint(autoRequest)
		if cachedEndpoint and cachedEndpoint.Parent and cachedEndpoint:IsDescendantOf(game) then
			return cachedEndpoint
		end
		cachedEndpoint = nil
		for _, cont in ipairs({
			LocalPlayer.Character,
			LocalPlayer:FindFirstChild("Backpack"),
			LocalPlayer:FindFirstChild("PlayerGui"),
			ReplicatedStorage,
		}) do
			local ep = findEndpointIn(cont)
			if ep then
				cachedEndpoint = ep
				return ep
			end
		end
		if autoRequest then
			pcall(function() Players:Chat(":f3x") end)
			task.wait(0.45)
			for _, cont in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
				local ep = findEndpointIn(cont)
				if ep then
					cachedEndpoint = ep
					return ep
				end
			end
		end
		return nil
	end

	local function invokeBatched(endpoint, action, list)
		if not endpoint or not list or #list == 0 then return end
		for i = 1, #list, CONFIG.SYNC_BATCH_SIZE do
			if not alive then break end
			local chunk = {}
			for j = i, math.min(i + CONFIG.SYNC_BATCH_SIZE - 1, #list) do
				table.insert(chunk, list[j])
			end
			pcall(function()
				endpoint:InvokeServer(action, chunk)
			end)
		end
	end

	local function removeParts(endpoint, parts)
		if not endpoint or not parts or #parts == 0 then return end
		local valid = {}
		for _, p in ipairs(parts) do
			if p and p.Parent ~= nil then
				table.insert(valid, p)
			end
		end
		if #valid > 0 then
			invokeBatched(endpoint, "Remove", valid)
		end
	end

	--// =====================================================================
	--// AUTHENTIC MINOS PRIME F3X BLUEPRINT
	--// =====================================================================
	-- Roles: "shell", "void", "heart", "vein", "snake", "crown", "aura"
	local function addSpec(list, partType, size, color, mat, trans, relCF, role, lightColor)
		table.insert(list, {
			partType = partType,
			size = size,
			color = color,
			mat = mat,
			trans = trans,
			relCF = relCF,
			role = role or "shell",
			lightColor = lightColor,
		})
	end

	local function getHeadSpecs()
		local s = {}
		-- Back & side translucent cranium framing the hollow face cavity
		addSpec(s, "Normal", V(0.84, 0.86, 0.38), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.34, C(0, 0.04, 0.24), "shell", PALETTE.VEIN_CYAN)
		addSpec(s, "Normal", V(0.18, 0.82, 0.62), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.34, C(-0.36, 0.04, -0.06), "shell")
		addSpec(s, "Normal", V(0.18, 0.82, 0.62), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.34, C(0.36, 0.04, -0.06), "shell")
		addSpec(s, "Normal", V(0.76, 0.18, 0.62), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.34, C(0, 0.40, -0.06), "shell")
		addSpec(s, "Normal", V(0.68, 0.20, 0.56), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.34, C(0, -0.34, -0.04), "shell")

		-- Sunken pitch-black facial void (signature hollow face hole)
		addSpec(s, "Cylinder", V(0.46, 0.54, 0.54), PALETTE.FACE_VOID, Enum.Material.SmoothPlastic, 0, C(0, 0.02, -0.08) * angles(0, 0, 90), "void")
		addSpec(s, "Normal", V(0.50, 0.56, 0.34), PALETTE.FACE_VOID, Enum.Material.SmoothPlastic, 0, C(0, 0.02, -0.18), "void")

		-- Glowing neck column & cranial spine vein
		addSpec(s, "Cylinder", V(0.42, 0.36, 0.36), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.36, C(0, -0.48, 0.04) * angles(0, 0, 90), "shell")
		addSpec(s, "Normal", V(0.10, 0.68, 0.10), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.05, C(0, -0.02, 0.18), "vein")

		-- Crown base collar
		addSpec(s, "Normal", V(0.84, 0.20, 0.82), PALETTE.CROWN_PRISM, Enum.Material.Glass, 0.30, C(0, 0.48, 0.02), "crown")

		-- Jagged crown of uneven vertical rectangular prisms fused to skull
		local prisms = {
			{ x =  0.00, z = -0.32, w = 0.16, h = 0.92, d = 0.16, rx = -6, rz =  0 }, -- Tall front spire
			{ x = -0.26, z = -0.26, w = 0.15, h = 0.68, d = 0.15, rx = -4, rz =  7 },
			{ x =  0.26, z = -0.26, w = 0.15, h = 0.74, d = 0.15, rx = -4, rz = -7 },
			{ x = -0.34, z =  0.04, w = 0.15, h = 0.56, d = 0.16, rx =  0, rz =  9 },
			{ x =  0.34, z =  0.04, w = 0.15, h = 0.62, d = 0.16, rx =  0, rz = -9 },
			{ x = -0.22, z =  0.30, w = 0.16, h = 0.82, d = 0.16, rx =  6, rz =  5 },
			{ x =  0.22, z =  0.30, w = 0.16, h = 0.78, d = 0.16, rx =  6, rz = -5 },
			{ x =  0.00, z =  0.34, w = 0.18, h = 0.96, d = 0.16, rx =  8, rz =  0 }, -- Tall rear spire
		}
		for _, p in ipairs(prisms) do
			addSpec(
				s,
				"Normal",
				V(p.w, p.h, p.d),
				PALETTE.CROWN_PRISM,
				Enum.Material.Glass,
				0.28,
				C(p.x, 0.52 + p.h * 0.5, p.z) * angles(p.rx, 0, p.rz),
				"crown"
			)
			-- Faint vertical vein inside tall crown spires
			if p.h >= 0.80 then
				addSpec(
					s,
					"Normal",
					V(0.05, p.h * 0.68, 0.05),
					PALETTE.VEIN_CYAN,
					Enum.Material.Neon,
					0.18,
					C(p.x, 0.52 + p.h * 0.44, p.z) * angles(p.rx, 0, p.rz),
					"vein"
				)
			end
		end
		return s
	end

	local function getChestSpecs()
		local s = {}
		-- Translucent muscular upper torso shell
		addSpec(s, "Normal", V(1.66, 0.84, 0.74), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, C(0, 0.08, 0.02), "shell", PALETTE.VEIN_CYAN)
		addSpec(s, "Wedge", V(0.76, 0.54, 0.24), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.42, C(-0.42, 0.16, -0.36) * angles(0, 12, 180), "shell")
		addSpec(s, "Wedge", V(0.76, 0.54, 0.24), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.42, C(0.42, 0.16, -0.36) * angles(0, -12, 180), "shell")

		-- Sculpted deltoid shoulder caps
		addSpec(s, "Ball", V(0.66, 0.66, 0.66), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.36, C(-0.96, 0.24, 0.02), "shell")
		addSpec(s, "Ball", V(0.66, 0.66, 0.66), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.36, C(0.96, 0.24, 0.02), "shell")

		-- OVERSIZED EXPOSED RED HEART + INNER PULSE CORE (offset anatomically left)
		addSpec(s, "Ball", V(0.46, 0.54, 0.40), PALETTE.HEART_RED, Enum.Material.Neon, 0.05, C(-0.22, 0.10, -0.14), "heart", PALETTE.HEART_RED)
		addSpec(s, "Ball", V(0.30, 0.36, 0.26), PALETTE.HEART_CORE, Enum.Material.Neon, 0.0, C(-0.20, 0.12, -0.18), "heart")
		-- Aorta arch rising out of the heart
		addSpec(s, "Cylinder", V(0.24, 0.16, 0.16), PALETTE.HEART_RED, Enum.Material.Neon, 0.08, C(-0.10, 0.34, -0.10) * angles(0, 0, -25), "heart")

		-- Branching circulatory veins visible inside translucent chest
		addSpec(s, "Normal", V(0.08, 0.78, 0.08), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.10, C(0.02, 0.06, -0.06) * angles(0, 0, -14), "vein")
		addSpec(s, "Normal", V(0.07, 0.62, 0.07), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(0.36, 0.18, -0.12) * angles(0, 0, 36), "vein")
		addSpec(s, "Normal", V(0.07, 0.56, 0.07), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(-0.52, 0.20, -0.10) * angles(0, 0, -40), "vein")
		addSpec(s, "Normal", V(0.06, 0.44, 0.06), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.15, C(0.56, 0.26, 0.02) * angles(0, 0, 58), "vein")
		addSpec(s, "Normal", V(0.06, 0.44, 0.06), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.15, C(-0.58, 0.26, 0.02) * angles(0, 0, -58), "vein")
		-- Spine column
		addSpec(s, "Cylinder", V(0.86, 0.22, 0.22), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(0, 0.04, 0.18) * angles(0, 0, 90), "vein")
		return s
	end

	local function getAbdomenSpecs()
		local s = {}
		addSpec(s, "Normal", V(1.16, 0.76, 0.60), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, ID_CF, "shell")
		-- Sculpted translucent ab plates
		for row = 0, 1 do
			local y = 0.14 - row * 0.26
			addSpec(s, "Normal", V(0.42, 0.20, 0.16), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.42, C(-0.24, y, -0.28), "shell")
			addSpec(s, "Normal", V(0.42, 0.20, 0.16), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.42, C(0.24, y, -0.28), "shell")
		end
		-- Abdominal arteries
		addSpec(s, "Normal", V(0.09, 0.74, 0.09), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(-0.16, 0, -0.08) * angles(0, 0, 8), "vein")
		addSpec(s, "Normal", V(0.09, 0.74, 0.09), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(0.16, 0, -0.08) * angles(0, 0, -8), "vein")
		return s
	end

	local function getPelvisSpecs()
		local s = {}
		addSpec(s, "Normal", V(1.24, 0.44, 0.62), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, ID_CF, "shell")
		addSpec(s, "Normal", V(0.26, 0.36, 0.66), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.34, C(0, -0.04, 0), "shell")
		addSpec(s, "Normal", V(0.08, 0.42, 0.08), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.15, C(-0.26, -0.04, -0.08) * angles(0, 0, 26), "vein")
		addSpec(s, "Normal", V(0.08, 0.42, 0.08), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.15, C(0.26, -0.04, -0.08) * angles(0, 0, -26), "vein")
		return s
	end

	local function getUpperArmSpecs()
		local s = {}
		addSpec(s, "Normal", V(0.46, 1.02, 0.46), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, C(0, -0.51, 0), "shell")
		addSpec(s, "Normal", V(0.08, 0.92, 0.08), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(0.06, -0.51, -0.06), "vein")
		return s
	end

	local function getForearmSpecs()
		local s = {}
		addSpec(s, "Normal", V(0.42, 0.96, 0.42), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, C(0, -0.48, 0), "shell")
		-- Fist cap
		addSpec(s, "Normal", V(0.46, 0.24, 0.46), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.32, C(0, -0.92, 0), "shell")

		-- TWIN COILED FOREARM SERPENT (4 angled ring segments + distinct head near wrist)
		local coils = {
			{ y = -0.20, yaw =   0, pitch =  14, roll =  16 },
			{ y = -0.40, yaw =  90, pitch = -14, roll =  16 },
			{ y = -0.60, yaw = 180, pitch =  14, roll =  16 },
			{ y = -0.78, yaw = 270, pitch = -14, roll =  16 },
		}
		for _, coil in ipairs(coils) do
			addSpec(
				s,
				"Normal",
				V(0.54, 0.12, 0.54),
				PALETTE.SERPENT_BODY,
				Enum.Material.SmoothPlastic,
				0.08,
				C(0, coil.y, 0) * angles(coil.pitch, coil.yaw, coil.roll),
				"snake"
			)
		end
		-- Serpent head + glowing gold eye accent resting on outer wrist
		addSpec(s, "Wedge", V(0.20, 0.18, 0.34), PALETTE.SERPENT_BODY, Enum.Material.Neon, 0.05, C(0.24, -0.84, -0.14) * angles(35, -18, 0), "snake")
		addSpec(s, "Normal", V(0.22, 0.06, 0.08), PALETTE.SERPENT_EYE, Enum.Material.Neon, 0, C(0.24, -0.80, -0.22) * angles(35, -18, 0), "snake")
		return s
	end

	local function getThighSpecs()
		local s = {}
		addSpec(s, "Normal", V(0.58, 1.18, 0.58), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, C(0, -0.59, 0), "shell")
		-- Femoral circulatory veins
		addSpec(s, "Normal", V(0.09, 1.06, 0.09), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.12, C(0.08, -0.59, -0.08), "vein")
		addSpec(s, "Normal", V(0.07, 0.90, 0.07), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.18, C(-0.10, -0.55, 0.06) * angles(0, 0, 8), "vein")
		return s
	end

	local function getShinSpecs()
		local s = {}
		addSpec(s, "Normal", V(0.48, 1.14, 0.48), PALETTE.BODY_SHELL, Enum.Material.Glass, 0.38, C(0, -0.57, 0), "shell")
		addSpec(s, "Normal", V(0.07, 0.98, 0.07), PALETTE.VEIN_CYAN, Enum.Material.Neon, 0.16, C(0.04, -0.56, -0.05), "vein")
		-- Foot base flush with SOLE_DEPTH
		addSpec(s, "Normal", V(0.50, 0.22, 0.72), PALETTE.BODY_HIGHLIGHT, Enum.Material.Glass, 0.34, C(0, -1.16, -0.12), "shell")
		return s
	end

	local function mirrorSpecs(specs)
		local out = {}
		for _, item in ipairs(specs) do
			table.insert(out, {
				partType = item.partType,
				size = item.size,
				color = item.color,
				mat = item.mat,
				trans = item.trans,
				relCF = mirrorRelCF(item.relCF),
				role = item.role,
				lightColor = item.lightColor,
			})
		end
		return out
	end

	--// =====================================================================
	--// F3X RIG SPAWNER & CLEANUP
	--// =====================================================================
	local function scaleRelCF(cf)
		local p = cf.Position * CONFIG.SCALE
		local rot = cf - cf.Position
		return C(p.X, p.Y, p.Z) * rot
	end

	local function buildRig()
		if isBuilding then return end
		isBuilding = true

		local ep = getF3XEndpoint(true)
		if not ep then
			isBuilding = false
			return false, "F3X tool not found"
		end

		-- Clean previous rig parts
		if #allOwnedParts > 0 then
			removeParts(ep, allOwnedParts)
			table.clear(allOwnedParts)
			table.clear(rigParts)
		end

		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local originCF = hrp and hrp.CFrame or C(0, 20, 0)

		local upperArmR = getUpperArmSpecs()
		local forearmR = getForearmSpecs()
		local thighR = getThighSpecs()
		local shinR = getShinSpecs()

		local limbSpecs = {
			Head = getHeadSpecs(),
			Chest = getChestSpecs(),
			Abdomen = getAbdomenSpecs(),
			Pelvis = getPelvisSpecs(),
			RightUpperArm = upperArmR,
			LeftUpperArm = mirrorSpecs(upperArmR),
			RightForearm = forearmR,
			LeftForearm = mirrorSpecs(forearmR),
			RightThigh = thighR,
			LeftThigh = mirrorSpecs(thighR),
			RightShin = shinR,
			LeftShin = mirrorSpecs(shinR),
		}

		local anchorB, collideB, resizeB, colorB, matB, lockB = {}, {}, {}, {}, {}, {}

		for limbName, specs in pairs(limbSpecs) do
			for _, spec in ipairs(specs) do
				if not alive then break end
				local ok, part = pcall(function()
					return ep:InvokeServer("CreatePart", spec.partType or "Normal", originCF, workspace)
				end)
				if ok and part and typeof(part) == "Instance" then
					local scaledSize = spec.size * CONFIG.SCALE
					local scaledRel = scaleRelCF(spec.relCF)

					table.insert(allOwnedParts, part)
					table.insert(rigParts, {
						part = part,
						limb = limbName,
						relCF = scaledRel,
						baseColor = spec.color,
						baseMat = spec.mat,
						baseTrans = spec.trans,
						role = spec.role,
					})

					table.insert(anchorB, { Part = part, Anchored = true })
					table.insert(collideB, { Part = part, CanCollide = false })
					table.insert(resizeB, { Part = part, Size = scaledSize, CFrame = originCF })
					table.insert(colorB, { Part = part, Color = spec.color })
					table.insert(matB, {
						Part = part,
						Material = spec.mat,
						Transparency = spec.trans,
						Reflectance = 0,
					})
					table.insert(lockB, part)

					if spec.lightColor then
						pcall(function()
							ep:InvokeServer("CreateLights", { { Part = part, LightType = "PointLight" } })
							ep:InvokeServer("SyncLighting", { {
								Part = part,
								LightType = "PointLight",
								Color = spec.lightColor,
								Range = 14,
								Brightness = 1.8,
							} })
						end)
					end
				end
			end
		end

		-- Apply all initial F3X properties in chunks (anchored + non-collidable prevents flinging)
		invokeBatched(ep, "SyncAnchor", anchorB)
		invokeBatched(ep, "SyncCollision", collideB)
		invokeBatched(ep, "SyncResize", resizeB)
		invokeBatched(ep, "SyncColor", colorB)
		invokeBatched(ep, "SyncMaterial", matB)
		if #lockB > 0 then
			pcall(function() ep:InvokeServer("SetLocked", lockB, true) end)
		end

		-- Hide real character parts locally so the F3X Minos Prime shell takes over cleanly
		local char = LocalPlayer.Character
		if char then
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
					desc.LocalTransparencyModifier = 1
				elseif desc:IsA("Decal") then
					desc.Transparency = 1
				end
			end
		end

		isBuilding = false
		return true, #rigParts
	end

	--// =====================================================================
	--// COMBAT HELPERS: TARGETING, IMPULSE & F3X VFX
	--// =====================================================================
	local function setCallout(text, dur, sfxKey)
		state.calloutText = text
		state.calloutUntil = os.clock() + (dur or 1.4)
		if Core and type(Core.playCue) == "function" and sfxKey then
			pcall(Core.playCue, sfxKey)
		end
	end

	local function getAimPosition(maxDist)
		local cam = workspace.CurrentCamera
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not cam or not hrp then return Vector3.zero end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local exclude = { char }
		for _, p in ipairs(allOwnedParts) do table.insert(exclude, p) end
		params.FilterDescendantsInstances = exclude

		local dist = maxDist or 180
		local res = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * dist, params)
		if res then
			return res.Position
		end
		return cam.CFrame.Position + cam.CFrame.LookVector * dist
	end

	local function findNearestTarget(centerPos, maxRange)
		local bestPlr, bestRoot, bestDist = nil, nil, maxRange or 90
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and root then
					local d = (root.Position - centerPos).Magnitude
					if d < bestDist then
						bestDist = d
						bestPlr = plr
						bestRoot = root
					end
				end
			end
		end
		return bestPlr, bestRoot, bestDist
	end

	local function isTargetAirborne(pos, selfPos)
		if (pos.Y - selfPos.Y) > 4.5 then return true end
		local _, root = findNearestTarget(pos, 18)
		if root and (root.Position.Y - selfPos.Y) > 4.5 then
			return true
		end
		return false
	end

	local function applyAreaHit(centerPos, radius, knockPower, upwardLift)
		local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not myHrp then return 0 end
		local hits = 0

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - centerPos).Magnitude <= radius then
					hits += 1
					local dir = (root.Position - centerPos)
					if dir.Magnitude < 0.1 then
						dir = myHrp.CFrame.LookVector
					end
					dir = Vector3.new(dir.X, 0, dir.Z).Unit
					-- Visual / local knock impulse (FE server damage depends on game tools)
					pcall(function()
						root.AssemblyLinearVelocity = dir * (knockPower or 65) + Vector3.new(0, upwardLift or 35, 0)
					end)
				end
			end
		end

		if Core and type(Core.onHit) == "function" then
			pcall(Core.onHit, centerPos, radius, knockPower)
		end
		return hits
	end

	local function spawnShockwave(centerPos, maxRadius, color)
		local ep = getF3XEndpoint(false)
		if not ep or #activeShockwaves >= 4 then return end
		task.spawn(function()
			local cf = C(centerPos.X, centerPos.Y, centerPos.Z)
			local ok, ring = pcall(function()
				return ep:InvokeServer("CreatePart", "Cylinder", cf * angles(0, 0, 90), workspace)
			end)
			if not ok or not ring or typeof(ring) ~= "Instance" then return end

			pcall(function()
				ep:InvokeServer("SyncAnchor", { { Part = ring, Anchored = true } })
				ep:InvokeServer("SyncCollision", { { Part = ring, CanCollide = false } })
				ep:InvokeServer("SyncColor", { { Part = ring, Color = color or PALETTE.SHOCKWAVE } })
				ep:InvokeServer("SyncMaterial", { { Part = ring, Material = Enum.Material.Neon, Transparency = 0.2, Reflectance = 0 } })
			end)

			table.insert(activeShockwaves, {
				part = ring,
				centerCF = cf * angles(0, 0, 90),
				startAt = os.clock(),
				duration = 0.45,
				maxRadius = maxRadius or 24,
			})
		end)
	end

	local function spawnGoldenSerpent(startPos, targetPos)
		local ep = getF3XEndpoint(false)
		if not ep or #activeProjectiles >= 3 then return end
		task.spawn(function()
			local dir = (targetPos - startPos)
			dir = (dir.Magnitude > 0.1) and dir.Unit or Vector3.new(0, 0, -1)
			local cf = CFrame.lookAt(startPos, startPos + dir)

			local ok, proj = pcall(function()
				return ep:InvokeServer("CreatePart", "Cylinder", cf * angles(90, 0, 0), workspace)
			end)
			if not ok or not proj or typeof(proj) ~= "Instance" then return end

			pcall(function()
				ep:InvokeServer("SyncAnchor", { { Part = proj, Anchored = true } })
				ep:InvokeServer("SyncCollision", { { Part = proj, CanCollide = false } })
				ep:InvokeServer("SyncResize", { { Part = proj, Size = V(1.6, 5.2, 1.6), CFrame = cf * angles(90, 0, 0) } })
				ep:InvokeServer("SyncColor", { { Part = proj, Color = PALETTE.GOLD_FLASH } })
				ep:InvokeServer("SyncMaterial", { { Part = proj, Material = Enum.Material.Neon, Transparency = 0.05, Reflectance = 0 } })
				ep:InvokeServer("CreateLights", { { Part = proj, LightType = "PointLight" } })
				ep:InvokeServer("SyncLighting", { { Part = proj, LightType = "PointLight", Color = PALETTE.GOLD_FLASH, Range = 16, Brightness = 2.5 } })
			end)

			table.insert(activeProjectiles, {
				part = proj,
				pos = startPos,
				dir = dir,
				speed = state.phase2 and 92 or 72,
				spawnAt = os.clock(),
				life = 2.4,
			})
		end)
	end

	--// =====================================================================
	--// P-1 MOVESET ACTIONS
	--// =====================================================================
	local function canAct()
		return alive and not isBuilding and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	end

	local function triggerBoxingCombo()
		if not canAct() then return end
		local now = os.clock()
		if now < state.cooldowns.punch then return end

		local hrp = LocalPlayer.Character.HumanoidRootPart
		local aim = getAimPosition(45)

		if now > state.comboResetAt then
			state.comboStep = 0
		end
		state.comboStep = (state.comboStep % 4) + 1
		state.comboResetAt = now + 1.15
		state.mode = "BOXING"
		state.actionStartedAt = now
		state.actionDuration = state.phase2 and 0.28 or 0.36
		state.cooldowns.punch = now + (state.phase2 and 0.22 or 0.30)

		-- Cancel mid-combo into Uppercut if target is airborne
		if state.comboStep >= 2 and isTargetAirborne(aim, hrp.Position) then
			state.comboStep = 5 -- Uppercut variant
			setCallout("THY END IS NOW! (UPPERCUT)", 1.3, "uppercut")
			hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 36 + Vector3.new(0, 42, 0)
			applyAreaHit(hrp.Position + hrp.CFrame.LookVector * 5, 11, 55, 68)
			return
		end

		if state.comboStep == 1 then
			setCallout("THY END IS NOW!", 1.5, "thy_end")
		elseif state.comboStep == 4 then
			state.parryFlashUntil = now + 0.35
			state.actionDuration = state.phase2 and 0.44 or 0.58 -- Ground-stuck fist recovery window
		end

		-- Dash forward on each strike
		local flatAim = Vector3.new(aim.X - hrp.Position.X, 0, aim.Z - hrp.Position.Z)
		local dashDir = (flatAim.Magnitude > 0.5) and flatAim.Unit or hrp.CFrame.LookVector
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dashDir)
		hrp.AssemblyLinearVelocity = dashDir * (state.phase2 and 46 or 36) + Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)

		local reach = (state.comboStep == 4) and 13 or 9.5
		local knock = (state.comboStep == 4) and 85 or 42
		applyAreaHit(hrp.Position + dashDir * 5.5, reach, knock, (state.comboStep == 4) and 40 or 16)
		if state.comboStep == 4 then
			spawnShockwave(hrp.Position + dashDir * 5 - Vector3.new(0, 2.5, 0), 16, PALETTE.SHOCKWAVE)
		end
	end

	local function triggerPrepareThyself()
		if not canAct() then return end
		local now = os.clock()
		if now < state.cooldowns.snake then return end

		local hrp = LocalPlayer.Character.HumanoidRootPart
		local aim = getAimPosition(160)
		local flatAim = Vector3.new(aim.X - hrp.Position.X, 0, aim.Z - hrp.Position.Z)
		local dashDir = (flatAim.Magnitude > 0.5) and flatAim.Unit or hrp.CFrame.LookVector

		state.mode = "KICK_COMBO"
		state.actionStartedAt = now
		state.actionDuration = state.phase2 and 0.68 or 0.86
		state.cooldowns.snake = now + (state.phase2 and 1.25 or 1.65)
		state.parryFlashUntil = now + 0.45
		setCallout("PREPARE THYSELF!", 1.5, "prepare")

		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dashDir)
		hrp.AssemblyLinearVelocity = dashDir * 44 + Vector3.new(0, 12, 0)
		applyAreaHit(hrp.Position + dashDir * 5, 11, 55, 25)

		-- Second sweeping kick + homing Golden Serpent projectile
		task.delay(state.phase2 and 0.24 or 0.34, function()
			if not alive or not LocalPlayer.Character then return end
			local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not root then return end
			applyAreaHit(root.Position + root.CFrame.LookVector * 5.5, 11, 60, 28)
			local targetPos = getAimPosition(160)
			spawnGoldenSerpent(root.Position + root.CFrame.RightVector * 1.4 + Vector3.new(0, 0.8, 0), targetPos)
		end)
	end

	local function triggerJudgement()
		if not canAct() then return end
		local now = os.clock()
		if now < state.cooldowns.judgement then return end

		local hrp = LocalPlayer.Character.HumanoidRootPart
		state.mode = "JUDGEMENT"
		state.actionStartedAt = now
		state.actionDuration = state.phase2 and 0.78 or 0.95
		state.cooldowns.judgement = now + (state.phase2 and 2.4 or 3.1)
		state.parryFlashUntil = now + 0.50
		setCallout("JUDGEMENT!", 1.7, "judgement")

		-- Telegraph crouch, then teleport dropkick + explosive shockwave
		task.delay(state.phase2 and 0.26 or 0.36, function()
			if not alive or not LocalPlayer.Character then return end
			local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local _, targetRoot = findNearestTarget(root.Position, 75)
			local destPos
			if targetRoot then
				local toTarget = (targetRoot.Position - root.Position)
				local dir = (toTarget.Magnitude > 0.5) and toTarget.Unit or root.CFrame.LookVector
				destPos = targetRoot.Position - dir * 5.0 + Vector3.new(0, 1.5, 0)
				root.CFrame = CFrame.lookAt(destPos, targetRoot.Position)
			else
				local aim = getAimPosition(65)
				local dir = (aim - root.Position)
				local dist = math.min(dir.Magnitude, 65)
				local unitDir = (dir.Magnitude > 0.5) and dir.Unit or root.CFrame.LookVector
				destPos = root.Position + unitDir * math.max(8, dist - 4)
				root.CFrame = CFrame.lookAt(destPos, destPos + unitDir)
			end

			root.AssemblyLinearVelocity = root.CFrame.LookVector * 52 + Vector3.new(0, 18, 0)
			applyAreaHit(root.Position + root.CFrame.LookVector * 4, 16, 110, 52)
			spawnShockwave(root.Position - Vector3.new(0, 2.2, 0), 26, PALETTE.GOLD_FLASH)
			if state.phase2 then
				spawnGoldenSerpent(root.Position + Vector3.new(0, 1.5, 0), getAimPosition(140))
			end
		end)
	end

	local function triggerDieOrCrush()
		if not canAct() then return end
		local now = os.clock()
		if now < state.cooldowns.drop then return end

		local hrp = LocalPlayer.Character.HumanoidRootPart
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		local airborne = hum and (hum.FloorMaterial == Enum.Material.Air)

		state.actionStartedAt = now
		state.cooldowns.drop = now + (state.phase2 and 1.6 or 2.1)

		if airborne then
			-- DIE! Midair Rider Kick
			local aim = getAimPosition(110)
			state.mode = "DIE_DIVE"
			state.actionDuration = 0.68
			state.diveStartPos = hrp.Position
			state.diveTargetPos = aim
			setCallout("DIE!", 1.4, "die")

			local diveDir = (aim - hrp.Position)
			local u = (diveDir.Magnitude > 0.5) and diveDir.Unit or hrp.CFrame.LookVector
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + Vector3.new(u.X, 0, u.Z))
			hrp.AssemblyLinearVelocity = u * 105

			task.delay(0.42, function()
				if not alive or not LocalPlayer.Character then return end
				local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not root then return end
				applyAreaHit(root.Position, 16, 88, 42)
				spawnShockwave(root.Position - Vector3.new(0, 2.5, 0), 24, PALETTE.SHOCKWAVE)
			end)
		else
			-- CRUSH! Ground Slam
			state.mode = "CRUSH"
			state.actionDuration = 0.75
			setCallout("CRUSH!", 1.4, "crush")
			hrp.AssemblyLinearVelocity = Vector3.new(0, 52, 0) + hrp.CFrame.LookVector * 14

			task.delay(0.38, function()
				if not alive or not LocalPlayer.Character then return end
				local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if not root then return end
				root.AssemblyLinearVelocity = Vector3.new(0, -110, 0)
				task.wait(0.14)
				if root and root.Parent then
					applyAreaHit(root.Position, 20, 100, 56)
					spawnShockwave(root.Position - Vector3.new(0, 2.6, 0), 30, PALETTE.SHOCKWAVE)
				end
			end)
		end
	end

	local function triggerDash()
		if not canAct() then return end
		local now = os.clock()
		if now < state.cooldowns.dash or state.stamina < 1 then return end

		state.stamina -= 1
		state.cooldowns.dash = now + 0.25
		state.mode = "DASH"
		state.actionStartedAt = now
		state.actionDuration = 0.22

		local hrp = LocalPlayer.Character.HumanoidRootPart
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		local moveDir = (hum and hum.MoveDirection.Magnitude > 0.1) and hum.MoveDirection.Unit or hrp.CFrame.LookVector
		hrp.AssemblyLinearVelocity = moveDir * CONFIG.DASH_SPEED + Vector3.new(0, 8, 0)
	end

	local function togglePhase2()
		state.phase2 = not state.phase2
		if state.phase2 then
			setCallout("WEAK.", 2.0, "weak")
			local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				spawnShockwave(hrp.Position - Vector3.new(0, 2.5, 0), 22, PALETTE.PHASE2_AURA)
			end
		else
			setCallout("PHASE 1 RESTORED", 1.2)
		end
	end

	--// =====================================================================
	--// PROCEDURAL POSE & RIG SYNC LOOP
	--// =====================================================================
	local lastSyncAt = 0
	local function computeLimbTransforms(hrp, hum, now)
		local rootPos = hrp.Position
		local _, yaw, _ = hrp.CFrame:ToOrientation()
		local baseRoot = C(rootPos) * CFrame.Angles(0, yaw, 0)

		local vel = hrp.AssemblyLinearVelocity
		local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		local airborne = hum and hum.FloorMaterial == Enum.Material.Air

		if horizSpeed > 2 and not airborne then
			state.walkCycle += (horizSpeed * 0.018)
		else
			state.walkCycle += 0.03
		end

		local t = state.walkCycle
		local walkAmp = clamp(horizSpeed / 22, 0, 1)

		-- Default Idle / Walk Poses
		local chestBob = math.sin(t * 2) * (0.04 + walkAmp * 0.05)
		local chestPitch = walkAmp * -8
		local headPitch, headYaw = 0, 0
		local rArmX, rArmY, rArmZ = math.sin(t) * 28 * walkAmp, 0, -10
		local lArmX, lArmY, lArmZ = -math.sin(t) * 28 * walkAmp, 0, 10
		local rForeX, lForeX = 18 + math.cos(t) * 14 * walkAmp, 18 - math.cos(t) * 14 * walkAmp
		local rLegX, lLegX = -math.sin(t) * 32 * walkAmp, math.sin(t) * 32 * walkAmp
		local rShinX, lShinX = -math.max(0, math.cos(t)) * 34 * walkAmp, -math.max(0, -math.cos(t)) * 34 * walkAmp

		if state.mode ~= "IDLE" then
			local elapsed = now - state.actionStartedAt
			local p = clamp(elapsed / math.max(0.05, state.actionDuration), 0, 1)
			if p >= 1 then
				state.mode = "IDLE"
			elseif state.mode == "BOXING" then
				local swing = math.sin(p * math.pi)
				if state.comboStep == 5 then
					-- Uppercut
					chestPitch = 14 * swing
					rArmX, rArmZ = 145 * swing, -12
					rForeX = 35
					lArmX = -25 * swing
				elseif state.comboStep % 2 == 1 then
					-- Left punch
					chestPitch = -18 * swing
					lArmX, lArmY = 98 * swing, -22 * swing
					lForeX = 10
					rArmX = -24 * swing
				else
					-- Right punch / heavy finisher with ground-stuck fist recovery
					if state.comboStep == 4 then
						local swing = (p < 0.45) and math.sin((p / 0.45) * math.pi * 0.5) or (1 - (p - 0.45) / 0.55)
						chestPitch = -32 * swing
						chestBob = -0.35 * swing
						rArmX, rArmY = 112 * swing, 16 * swing
						rForeX = 6
						lArmX = -28 * swing
					else
						local swing = math.sin(p * math.pi)
						chestPitch = -22 * swing
						rArmX, rArmY = 102 * swing, 22 * swing
						rForeX = 8
						lArmX = -26 * swing
					end
				end
			elseif state.mode == "KICK_COMBO" then
				if p < 0.5 then
					local swing = math.sin((p / 0.5) * math.pi)
					chestPitch = 14 * swing
					lLegX = 92 * swing
					lShinX = -15 * swing
					rLegX = -20 * swing
					lArmX = 55 * swing
				else
					local swing = math.sin(((p - 0.5) / 0.5) * math.pi)
					chestPitch = 18 * swing
					rLegX = 100 * swing
					rShinX = -12 * swing
					lLegX = -24 * swing
					rArmX = 72 * swing
					lArmX = -45 * swing
				end
			elseif state.mode == "JUDGEMENT" then
				if p < 0.38 then
					-- Telegraph crouch
					chestBob = -0.55 * easeOutQuad(p / 0.38)
					chestPitch = -28
					rArmX, lArmX = -40, -40
					rLegX, lLegX = 50, 50
					rShinX, lShinX = -75, -75
				else
					-- Explosive dropkick pose
					local kp = (p - 0.38) / 0.62
					local swing = math.sin(kp * math.pi)
					chestPitch = 45 * swing
					rLegX = 112 * swing
					lLegX = 85 * swing
					rShinX, lShinX = -5, -35
					rArmX, lArmX = -55 * swing, -55 * swing
				end
			elseif state.mode == "DIE_DIVE" then
				chestPitch = -35
				rLegX, lLegX = 88, -28
				rShinX, lShinX = -10, -45
				rArmX, lArmX = -45, 45
			elseif state.mode == "CRUSH" then
				local swing = math.sin(p * math.pi)
				chestPitch = -30 * swing
				rArmX, lArmX = 140 * swing, 140 * swing
				rLegX, lLegX = 38 * swing, 38 * swing
				rShinX, lShinX = -55 * swing, -55 * swing
			elseif state.mode == "DASH" then
				chestPitch = -26
				rArmX, lArmX = -48, -48
			end
		elseif airborne then
			chestPitch = -10
			rLegX, lLegX = 24, -16
			rShinX, lShinX = -32, -18
			rArmX, lArmX = -22, -22
		end

		local sc = CONFIG.SCALE
		local rootOffset = baseRoot * C(0, chestBob, 0)
		local chestCF = rootOffset * C(0, CONFIG.CHEST_OFFSET * sc, 0) * angles(chestPitch, 0, 0)
		local headCF = chestCF * C(0, 0.84 * sc, 0) * angles(headPitch, headYaw, 0)
		local abdomenCF = rootOffset * C(0, CONFIG.ABDOMEN_OFFSET * sc, 0) * angles(chestPitch * 0.5, 0, 0)
		local pelvisCF = rootOffset * C(0, CONFIG.PELVIS_OFFSET * sc, 0)

		local rShoulderCF = chestCF * C(CONFIG.SHOULDER_X * sc, CONFIG.SHOULDER_Y * sc, 0) * angles(rArmX, rArmY, rArmZ)
		local lShoulderCF = chestCF * C(-CONFIG.SHOULDER_X * sc, CONFIG.SHOULDER_Y * sc, 0) * angles(lArmX, lArmY, lArmZ)
		local rForeCF = rShoulderCF * C(0, -CONFIG.UPPER_ARM_LEN * sc, 0) * angles(rForeX, 0, 0)
		local lForeCF = lShoulderCF * C(0, -CONFIG.UPPER_ARM_LEN * sc, 0) * angles(lForeX, 0, 0)

		local rThighCF = pelvisCF * C(CONFIG.HIP_X * sc, CONFIG.HIP_Y * sc, 0) * angles(rLegX, 0, 0)
		local lThighCF = pelvisCF * C(-CONFIG.HIP_X * sc, CONFIG.HIP_Y * sc, 0) * angles(lLegX, 0, 0)
		local rShinCF = rThighCF * C(0, -CONFIG.THIGH_LEN * sc, 0) * angles(rShinX, 0, 0)
		local lShinCF = lThighCF * C(0, -CONFIG.THIGH_LEN * sc, 0) * angles(lShinX, 0, 0)

		return {
			Head = headCF,
			Chest = chestCF,
			Abdomen = abdomenCF,
			Pelvis = pelvisCF,
			RightUpperArm = rShoulderCF,
			LeftUpperArm = lShoulderCF,
			RightForearm = rForeCF,
			LeftForearm = lForeCF,
			RightThigh = rThighCF,
			LeftThigh = lThighCF,
			RightShin = rShinCF,
			LeftShin = lShinCF,
		}
	end

	--// =====================================================================
	--// SMILEOS 2.0 / MINOS PRIME HUD (PC + MOBILE)
	--// =====================================================================
	local function getGuiParent()
		local ok, hui = pcall(function() return gethui and gethui() end)
		if ok and hui then return hui end
		local okC = pcall(function() return CoreGui.Name end)
		if okC then return CoreGui end
		return LocalPlayer:WaitForChild("PlayerGui")
	end

	local hudParent = getGuiParent()
	local oldHud = hudParent:FindFirstChild("ULTRAKILL_MINOS_HUD")
	if oldHud then oldHud:Destroy() end

	local HudGui = Instance.new("ScreenGui")
	HudGui.Name = "ULTRAKILL_MINOS_HUD"
	HudGui.ResetOnSpawn = false
	HudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	HudGui.Parent = hudParent

	local HudFrame = Instance.new("Frame")
	HudFrame.Size = UDim2.fromOffset(310, 74)
	HudFrame.Position = UDim2.new(0.5, -155, 1, -92)
	HudFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	HudFrame.BorderSizePixel = 0
	HudFrame.Parent = HudGui

	local hudStroke = Instance.new("UIStroke")
	hudStroke.Color = PALETTE.VEIN_CYAN
	hudStroke.Thickness = 1.6
	hudStroke.Parent = HudFrame

	local HudHeader = Instance.new("TextLabel")
	HudHeader.Size = UDim2.new(1, -12, 0, 18)
	HudHeader.Position = UDim2.fromOffset(6, 4)
	HudHeader.BackgroundTransparency = 1
	HudHeader.Font = Enum.Font.Code
	HudHeader.TextSize = 12
	HudHeader.TextColor3 = PALETTE.VEIN_CYAN
	HudHeader.TextXAlignment = Enum.TextXAlignment.Left
	HudHeader.Text = "P-1 // KING OF LUST (PRIME SOUL)"
	HudHeader.Parent = HudFrame

	local HudCallout = Instance.new("TextLabel")
	HudCallout.Size = UDim2.new(1, -12, 0, 18)
	HudCallout.Position = UDim2.fromOffset(6, 22)
	HudCallout.BackgroundTransparency = 1
	HudCallout.Font = Enum.Font.Code
	HudCallout.TextSize = 13
	HudCallout.TextColor3 = Color3.fromRGB(240, 245, 255)
	HudCallout.TextXAlignment = Enum.TextXAlignment.Left
	HudCallout.Text = "> AWAITING PREY"
	HudCallout.Parent = HudFrame

	local StaminaRow = Instance.new("Frame")
	StaminaRow.Size = UDim2.new(1, -12, 0, 8)
	StaminaRow.Position = UDim2.fromOffset(6, 43)
	StaminaRow.BackgroundTransparency = 1
	StaminaRow.Parent = HudFrame

	local stamBars = {}
	for i = 1, CONFIG.MAX_STAMINA do
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1 / CONFIG.MAX_STAMINA, -4, 1, 0)
		bar.Position = UDim2.new((i - 1) / CONFIG.MAX_STAMINA, 0, 0, 0)
		bar.BackgroundColor3 = PALETTE.VEIN_CYAN
		bar.BorderSizePixel = 0
		bar.Parent = StaminaRow
		stamBars[i] = bar
	end

	local HudKeys = Instance.new("TextLabel")
	HudKeys.Size = UDim2.new(1, -12, 0, 16)
	HudKeys.Position = UDim2.fromOffset(6, 54)
	HudKeys.BackgroundTransparency = 1
	HudKeys.Font = Enum.Font.Code
	HudKeys.TextSize = 10
	HudKeys.TextColor3 = Color3.fromRGB(165, 180, 195)
	HudKeys.TextXAlignment = Enum.TextXAlignment.Left
	HudKeys.Text = "[LMB] COMBO [E] SNAKE [F] JUDGE [C] DIE/CRUSH [X] WEAK"
	HudKeys.Parent = HudFrame

	-- Touch-Friendly Mobile Buttons (always accessible on TouchEnabled, or bottom-right cluster)
	local MobileCluster = Instance.new("Frame")
	MobileCluster.Size = UDim2.fromOffset(216, 118)
	MobileCluster.Position = UDim2.new(1, -228, 1, -142)
	MobileCluster.BackgroundTransparency = 1
	MobileCluster.Visible = UserInputService.TouchEnabled
	MobileCluster.Parent = HudGui

	local function makeMobBtn(txt, col, gx, gy, fn)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(68, 36)
		b.Position = UDim2.fromOffset(gx * 72, gy * 40)
		b.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
		b.BorderSizePixel = 0
		b.Font = Enum.Font.Code
		b.TextSize = 11
		b.TextColor3 = col
		b.Text = txt
		b.Parent = MobileCluster
		local st = Instance.new("UIStroke")
		st.Color = col
		st.Thickness = 1.4
		st.Parent = b
		b.Activated:Connect(fn)
		return b
	end

	makeMobBtn("PUNCH", PALETTE.BODY_HIGHLIGHT, 0, 0, triggerBoxingCombo)
	makeMobBtn("SNAKE", PALETTE.GOLD_FLASH, 1, 0, triggerPrepareThyself)
	makeMobBtn("JUDGE", PALETTE.GOLD_FLASH, 2, 0, triggerJudgement)
	makeMobBtn("DROP", PALETTE.SHOCKWAVE, 0, 1, triggerDieOrCrush)
	makeMobBtn("DASH", PALETTE.VEIN_CYAN, 1, 1, triggerDash)
	makeMobBtn("WEAK", PALETTE.HEART_RED, 2, 1, togglePhase2)

	--// =====================================================================
	--// INPUT & HEARTBEAT LOOP
	--// =====================================================================
	trackConn(UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not alive then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			triggerBoxingCombo()
		elseif input.KeyCode == Enum.KeyCode.E then
			triggerPrepareThyself()
		elseif input.KeyCode == Enum.KeyCode.F then
			triggerJudgement()
		elseif input.KeyCode == Enum.KeyCode.C then
			triggerDieOrCrush()
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftShift then
			triggerDash()
		elseif input.KeyCode == Enum.KeyCode.X then
			togglePhase2()
		end
	end))

	trackConn(RunService.Heartbeat:Connect(function(dt)
		if not alive then return end
		local now = os.clock()

		-- Stamina regen
		if state.stamina < CONFIG.MAX_STAMINA then
			state.staminaAccum += dt
			local rate = state.phase2 and (CONFIG.STAMINA_REGEN_SEC * 0.65) or CONFIG.STAMINA_REGEN_SEC
			if state.staminaAccum >= rate then
				state.staminaAccum -= rate
				state.stamina = math.min(CONFIG.MAX_STAMINA, state.stamina + 1)
			end
		end

		-- Update HUD
		for i = 1, CONFIG.MAX_STAMINA do
			stamBars[i].BackgroundColor3 = (i <= state.stamina) and (state.phase2 and PALETTE.PHASE2_AURA or PALETTE.VEIN_CYAN) or Color3.fromRGB(30, 35, 45)
		end
		if now < state.calloutUntil then
			HudCallout.Text = "> " .. state.calloutText .. (state.phase2 and " [PHASE 2]" or "")
			HudCallout.TextColor3 = (now < state.parryFlashUntil) and PALETTE.GOLD_FLASH or PALETTE.BODY_HIGHLIGHT
		else
			HudCallout.Text = state.phase2 and "> WEAK. (PHASE 2 ENRAGE)" or "> SOUL SURVIVOR READY"
			HudCallout.TextColor3 = state.phase2 and PALETTE.PHASE2_AURA or Color3.fromRGB(200, 215, 230)
		end

		local ep = getF3XEndpoint(false)
		if not ep then return end

		-- Transition-only visual tint for Parry Gold Flash & Phase 2 Enrage Aura
		local desiredTint = (now < state.parryFlashUntil) and "PARRY" or (state.phase2 and "PHASE2" or "BASE")
		if desiredTint ~= state.lastVisualTintState and #rigParts > 0 then
			state.lastVisualTintState = desiredTint
			local colorChanges = {}
			for _, item in ipairs(rigParts) do
				if item.part and item.part.Parent ~= nil then
					if desiredTint == "PARRY" and (item.role == "vein" or item.role == "snake" or item.role == "crown") then
						table.insert(colorChanges, { Part = item.part, Color = PALETTE.GOLD_FLASH })
					elseif desiredTint == "PHASE2" and (item.role == "vein" or item.role == "shell") then
						local col = (item.role == "vein") and PALETTE.PHASE2_AURA or Color3.fromRGB(145, 220, 255)
						table.insert(colorChanges, { Part = item.part, Color = col })
					else
						table.insert(colorChanges, { Part = item.part, Color = item.baseColor })
					end
				end
			end
			if #colorChanges > 0 then
				task.spawn(function()
					invokeBatched(ep, "SyncColor", colorChanges)
				end)
			end
		end

		-- Update active projectiles & shockwaves
		local moveList, resizeList, matList, toRemove = {}, {}, {}, {}

		for i = #activeProjectiles, 1, -1 do
			local p = activeProjectiles[i]
			if not p.part or p.part.Parent == nil or (now - p.spawnAt) >= p.life then
				if p.part and p.part.Parent ~= nil then table.insert(toRemove, p.part) end
				table.remove(activeProjectiles, i)
			else
				local _, targetRoot = findNearestTarget(p.pos, 45)
				if targetRoot then
					local desired = (targetRoot.Position - p.pos).Unit
					p.dir = p.dir:Lerp(desired, clamp(dt * 4.5, 0, 1)).Unit
				end
				p.pos = p.pos + p.dir * p.speed * dt
				local cf = CFrame.lookAt(p.pos, p.pos + p.dir) * angles(90, 0, 0)
				table.insert(moveList, { Part = p.part, CFrame = cf })

				if targetRoot and (targetRoot.Position - p.pos).Magnitude < 4.5 then
					applyAreaHit(p.pos, 10, 75, 38)
					spawnShockwave(p.pos, 14, PALETTE.GOLD_FLASH)
					table.insert(toRemove, p.part)
					table.remove(activeProjectiles, i)
				end
			end
		end

		for i = #activeShockwaves, 1, -1 do
			local sw = activeShockwaves[i]
			local prog = (now - sw.startAt) / sw.duration
			if not sw.part or sw.part.Parent == nil or prog >= 1 then
				if sw.part and sw.part.Parent ~= nil then table.insert(toRemove, sw.part) end
				table.remove(activeShockwaves, i)
			else
				local r = lerp(2, sw.maxRadius, easeOutQuad(prog))
				table.insert(resizeList, { Part = sw.part, Size = V(0.4, r * 2, r * 2), CFrame = sw.centerCF })
				table.insert(matList, { Part = sw.part, Material = Enum.Material.Neon, Transparency = lerp(0.15, 0.92, prog), Reflectance = 0 })
			end
		end

		-- Sync Minos Prime F3X Rig Transforms (~30Hz to keep F3X remotes crisp)
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if hrp and hum and #rigParts > 0 and (now - lastSyncAt) >= 0.032 then
			lastSyncAt = now
			hum.WalkSpeed = state.phase2 and CONFIG.SPRINT_SPEED or CONFIG.WALK_SPEED
			local poses = computeLimbTransforms(hrp, hum, now)
			for _, item in ipairs(rigParts) do
				if item.part and item.part.Parent ~= nil then
					local limbCF = poses[item.limb]
					if limbCF then
						table.insert(moveList, { Part = item.part, CFrame = limbCF * item.relCF })
					end
				end
			end
		end

		if #moveList > 0 then invokeBatched(ep, "SyncMove", moveList) end
		if #resizeList > 0 then invokeBatched(ep, "SyncResize", resizeList) end
		if #matList > 0 then invokeBatched(ep, "SyncMaterial", matList) end
		if #toRemove > 0 then removeParts(ep, toRemove) end
	end))

	--// =====================================================================
	--// LIFECYCLE CONTROLLER (CLEANUP & REBUILD)
	--// =====================================================================
	local function rebuild()
		if not alive then return end
		buildRig()
	end

	local function cleanup()
		if not alive then return end
		alive = false

		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(connections)

		local ep = getF3XEndpoint(false)
		if ep then
			local cleanupList = {}
			for _, p in ipairs(allOwnedParts) do table.insert(cleanupList, p) end
			for _, pr in ipairs(activeProjectiles) do if pr.part then table.insert(cleanupList, pr.part) end end
			for _, sw in ipairs(activeShockwaves) do if sw.part then table.insert(cleanupList, sw.part) end end
			removeParts(ep, cleanupList)
		end
		table.clear(allOwnedParts)
		table.clear(rigParts)
		table.clear(activeProjectiles)
		table.clear(activeShockwaves)

		-- Restore character visibility
		local char = LocalPlayer.Character
		if char then
			for _, desc in ipairs(char:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.LocalTransparencyModifier = 0
				elseif desc:IsA("Decal") then
					desc.Transparency = 0
				end
			end
		end

		if HudGui and HudGui.Parent then
			HudGui:Destroy()
		end

		for _, store in ipairs({ env, _G }) do
			if store.F3XMinosReanimCleanup == cleanup then store.F3XMinosReanimCleanup = nil end
			if store.F3XMinosReanimRebuild == rebuild then store.F3XMinosReanimRebuild = nil end
		end
	end

	local controller = {
		id = "minos",
		config = CONFIG,
		cleanup = cleanup,
		rebuild = rebuild,
	}

	env.F3XMinosReanimCleanup = cleanup
	_G.F3XMinosReanimCleanup = cleanup
	env.F3XMinosReanimRebuild = rebuild
	_G.F3XMinosReanimRebuild = rebuild
	env.ULTRAKILL_F3X = controller
	_G.ULTRAKILL_F3X = controller

	-- Auto-rebuild on respawn
	trackConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
		newChar:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.35)
		if alive then
			buildRig()
		end
	end))

	-- Initial F3X Rig Build
	buildRig()
	return controller
end