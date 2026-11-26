-- ULTRAKILL MINOS PRIME MODULE (KING OF LUST // PRIME SOUL — SCULPTED EDITION)
-- Carregado dinamicamente pelo loader.lua recebendo Core

return function(Core)
	local UserInputService = game:GetService("UserInputService")
	local SoundService = game:GetService("SoundService")
	local ContentProvider = game:GetService("ContentProvider")

	local C, V = Core.C, Core.V
	local ID_CF, PARK_CF = Core.ID_CF, Core.PARK_CF
	local clamp, lerp, easeOutQuad, easeOutBack = Core.clamp, Core.lerp, Core.easeOutQuad, Core.easeOutBack
	local angles = Core.angles

	local PALETTE = {
		FLESH_GLASS    = Color3.fromRGB(168, 226, 255), -- Translucent Prime Soul outer shell
		FLESH_INNER    = Color3.fromRGB(210, 244, 255), -- Sculpted inner muscle definition
		FLESH_DEEP     = Color3.fromRGB(132, 198, 238), -- Deeper muscle shadow contours
		VEIN_CYAN      = Color3.fromRGB(80, 226, 255),  -- Major glowing arterial trunks & spine
		VEIN_THIN      = Color3.fromRGB(52, 182, 235),  -- Secondary branching vessels
		PRIME_CYAN     = Color3.fromRGB(125, 242, 255), -- Shockwave / Phase 2 flame aura cyan
		AURA_WHITE     = Color3.fromRGB(228, 250, 255), -- Hot core of Prime Soul flames
		HEART_RED      = Color3.fromRGB(220, 20, 36),   -- Exposed anatomical Prime Heart
		HEART_DARK     = Color3.fromRGB(135, 14, 26),   -- Dark chamber / aorta shadow
		HEART_CORE     = Color3.fromRGB(255, 108, 122), -- Heart glowing pulse core
		FACE_VOID      = Color3.fromRGB(4, 4, 7),       -- Deep hollow pitch-black face abyss
		CROWN_ICE      = Color3.fromRGB(190, 236, 255), -- Jagged architectural crown prisms
		SNAKE_SHELL    = Color3.fromRGB(232, 246, 255), -- Pale coiled forearm serpents
		SNAKE_BELLY    = Color3.fromRGB(95, 232, 255),  -- Serpent glowing scales & belly ridge
		SERPENT_GOLD   = Color3.fromRGB(255, 204, 48),  -- Homing golden Serpent projectile
		JUDGEMENT_GOLD = Color3.fromRGB(255, 236, 125), -- Parry-flash & Judgement explosion
	}

	-- Exact Proportions Aligned to V1/Core Rig Grounding (MINOS_SOLE_DEPTH = 3.66)
	local MINOS_CHEST_OFFSET = 0.56
	local MINOS_ABDOMEN_OFFSET = -0.22
	local MINOS_PELVIS_OFFSET = -0.80
	local MINOS_HIP_Y = -0.14
	local MINOS_THIGH_LEN = 1.18
	local MINOS_SHIN_LEN = 1.16
	local MINOS_SOLE_DEPTH_FROM_ANKLE = 0.38
	local MINOS_SOLE_DEPTH = math.abs(MINOS_PELVIS_OFFSET) + math.abs(MINOS_HIP_Y) + MINOS_THIGH_LEN + MINOS_SHIN_LEN + MINOS_SOLE_DEPTH_FROM_ANKLE -- 3.66
	local MINOS_UPPER_ARM_LEN = 1.04
	local MINOS_FOREARM_LEN = 1.00

	-- Combat Tuning
	local SERPENT_COOLDOWN = 0.92
	local SERPENT_RANGE = 105
	local SERPENT_SPEED = 90
	local JUDGEMENT_COOLDOWN = 1.40
	local JUDGEMENT_RANGE = 82
	local BLITZ_COOLDOWN = 1.35
	local BLITZ_RANGE = 52
	local COMBO_COOLDOWN = 0.20
	local COMBO_RANGE = 12.5

	local PUNCH_KNOCKBACK     = { speed = 58,  up = 22, spin = 9.5 }
	local UPPERCUT_KNOCKBACK  = { speed = 40,  up = 72, spin = 13.0 }
	local OVERHEAD_KNOCKBACK  = { speed = 64,  up = -34, spin = 12.5 }
	local FINISHER_KNOCKBACK  = { speed = 96,  up = 38, spin = 16.0 }
	local SERPENT_KNOCKBACK   = { speed = 84,  up = 32, spin = 14.5 }
	local JUDGEMENT_KNOCKBACK = { speed = 118, up = 52, spin = 19.0 }
	local DIE_KNOCKBACK       = { speed = 92,  up = 30, spin = 15.0 }
	local CRUSH_KNOCKBACK     = { speed = 82,  up = 54, spin = 16.0 }

	-------------------------------------------------------------------
	-- VERIFIED ROBLOX AUDIO IDS + OPTIONAL LOCAL EXECUTOR CLIP HOOKS
	-------------------------------------------------------------------
	local MINOS_AUDIO = {
		INTRO = {
			ids = { "rbxassetid://74387685521172" },
			file = "minos_intro.mp3",
			vol = 0.88,
			pitch = 1.0,
		},
		PREPARE = {
			ids = { "rbxassetid://86759992415245", "rbxassetid://18553892205" },
			file = "minos_prepare.mp3",
			vol = 0.95,
			pitch = 1.0,
		},
		THY_END = {
			ids = { "rbxassetid://90848906338273" },
			file = "minos_thyend.mp3",
			vol = 0.96,
			pitch = 1.0,
		},
		JUDGEMENT = {
			ids = { "rbxassetid://114139913020561" },
			file = "minos_judgement.mp3",
			vol = 1.0,
			pitch = 1.0,
		},
		CRUSH = {
			ids = { "rbxassetid://90837584182299", "rbxassetid://18964229069" },
			file = "minos_crush.mp3",
			vol = 0.96,
			pitch = 1.0,
		},
		DEATH = {
			ids = { "rbxassetid://9057860385" },
			file = "minos_death.mp3",
			vol = 0.92,
			pitch = 1.0,
		},
		-- Optional local executor files if supplied in workspace (no unverified IDs guessed)
		DIE = {
			ids = {},
			file = "minos_die.mp3",
			vol = 0.95,
			pitch = 1.0,
		},
		WEAK = {
			ids = {},
			file = "minos_weak.mp3",
			vol = 0.98,
			pitch = 1.0,
		},
		USELESS = {
			ids = {},
			file = "minos_useless.mp3",
			vol = 0.95,
			pitch = 1.0,
		},
	}

	local function resolveExecutorAudio(filename)
		if not filename or filename == "" then return nil end
		if type(isfile) == "function" and type(getcustomasset) == "function" then
			local okExists, exists = pcall(isfile, filename)
			if okExists and exists then
				local okAsset, asset = pcall(getcustomasset, filename)
				if okAsset and asset and asset ~= "" then
					return asset
				end
			end
		end
		return nil
	end

	local function createAudioPlayer(STATE)
		local preloaded = {}
		local activeSounds = {}

		-- Preload verified Roblox sound IDs silently
		task.spawn(function()
			local instances = {}
			for key, def in pairs(MINOS_AUDIO) do
				preloaded[key] = {}
				for _, assetId in ipairs(def.ids) do
					local ok, snd = pcall(function()
						local s = Instance.new("Sound")
						s.SoundId = assetId
						s.Volume = 0
						s.Parent = SoundService
						return s
					end)
					if ok and snd then
						preloaded[key][#preloaded[key] + 1] = snd
						instances[#instances + 1] = snd
					end
				end
			end
			if #instances > 0 then
				pcall(function()
					ContentProvider:PreloadAsync(instances)
				end)
			end
		end)

		local function pickAssetId(key)
			local custom = resolveExecutorAudio(MINOS_AUDIO[key] and MINOS_AUDIO[key].file)
			if custom then return custom end
			local list = preloaded[key]
			if list then
				for _, s in ipairs(list) do
					if s and s.Parent and (s.TimeLength > 0 or s.IsLoaded) then
						return s.SoundId
					end
				end
			end
			local def = MINOS_AUDIO[key]
			return (def and def.ids and def.ids[1]) or nil
		end

		local function playVoice(key, pitchMul, volMul)
			local def = MINOS_AUDIO[key]
			if not def then return false end
			local assetId = pickAssetId(key)
			if not assetId then return false end

			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			local ok, snd = pcall(function()
				local s = Instance.new("Sound")
				s.SoundId = assetId
				s.Volume = (def.vol or 0.9) * (volMul or 1.0)
				s.PlaybackSpeed = (def.pitch or 1.0) * (pitchMul or 1.0)
				s.RollOffMode = Enum.RollOffMode.InverseTapered
				s.RollOffMinDistance = 14
				s.RollOffMaxDistance = 140
				s.Parent = hrp or SoundService
				s:Play()
				return s
			end)
			if ok and snd then
				activeSounds[snd] = true
				task.delay(6.5, function()
					activeSounds[snd] = nil
					pcall(function() snd:Destroy() end)
				end)
				return true
			end
			return false
		end

		local function cleanup()
			for _, list in pairs(preloaded) do
				for _, s in ipairs(list) do
					pcall(function() s:Destroy() end)
				end
			end
			for s in pairs(activeSounds) do
				pcall(function() s:Destroy() end)
			end
			table.clear(preloaded)
			table.clear(activeSounds)
		end

		STATE.custom.audioCleanup = cleanup
		return playVoice
	end

	-------------------------------------------------------------------
	-- SCULPTED MINOS PRIME BLUEPRINTS (1000X ANATOMICAL & PRIME DETAIL)
	-------------------------------------------------------------------
	local function getMinosHeadSpecs()
		local specs = {
			-- Sculpted Neck Column + Tendons + Pulsing Carotid Arteries
			{ partType = "Cylinder", size = V(0.50, 0.34, 0.34), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, -0.44, 0.06) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.48, 0.16, 0.16), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.10, relCF = C(0, -0.44, 0.12) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.11, 0.38, 0.11), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-0.11, -0.40, -0.02) * angles(-18, 0, -16) },
			{ partType = "Normal",   size = V(0.11, 0.38, 0.11), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0.11, -0.40, -0.02) * angles(-18, 0, 16) },
			{ partType = "Normal",   size = V(0.06, 0.40, 0.06), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-0.14, -0.40, 0.04) * angles(-8, 0, -10) },
			{ partType = "Normal",   size = V(0.06, 0.40, 0.06), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(0.14, -0.40, 0.04) * angles(-8, 0, 10) },

			-- True Recessed Hollow Pitch-Black Face Abyss (cannot see out the sides or back!)
			{ partType = "Cylinder", size = V(0.46, 0.54, 0.54), color = PALETTE.FACE_VOID, mat = Enum.Material.SmoothPlastic, trans = 0, relCF = C(0, 0.03, -0.10) * angles(0, 90, 0) },
			{ partType = "Normal",   size = V(0.50, 0.58, 0.16), color = PALETTE.FACE_VOID, mat = Enum.Material.SmoothPlastic, trans = 0, relCF = C(0, 0.03, 0.04) },
			{ partType = "Normal",   size = V(0.46, 0.56, 0.24), color = PALETTE.FACE_VOID, mat = Enum.Material.SmoothPlastic, trans = 0, relCF = C(0, 0.03, -0.22) },

			-- Sculpted Skull Dome, Zygomatic Cheekbones, Brow Ridge & Chiseled Jaw
			{ partType = "Normal",   size = V(0.84, 0.78, 0.36), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, 0.06, 0.24) },
			{ partType = "Ball",     size = V(0.82, 0.72, 0.68), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.36, relCF = C(0, 0.08, 0.14) },
			-- Cheek & Temple Side Walls Framing the Void
			{ partType = "Normal",   size = V(0.18, 0.72, 0.58), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(-0.34, 0.04, -0.06) },
			{ partType = "Normal",   size = V(0.18, 0.72, 0.58), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0.34, 0.04, -0.06) },
			{ partType = "Wedge",    size = V(0.22, 0.24, 0.26), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(-0.27, -0.10, -0.32) * angles(0, 22, -16) },
			{ partType = "Wedge",    size = V(0.22, 0.24, 0.26), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(0.27, -0.10, -0.32) * angles(0, -22, 16) },
			-- Overhanging Aggressive Brow Ridge
			{ partType = "Normal",   size = V(0.86, 0.16, 0.52), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.18, relCF = C(0, 0.37, -0.10) },
			{ partType = "Wedge",    size = V(0.80, 0.16, 0.22), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.26, relCF = C(0, 0.37, -0.34) },
			-- Chiseled Jawline & Chin
			{ partType = "Normal",   size = V(0.60, 0.15, 0.44), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(0, -0.28, -0.12) },
			{ partType = "Wedge",    size = V(0.56, 0.16, 0.22), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.26, relCF = C(0, -0.29, -0.33) * angles(180, 0, 0) },
			-- Glowing Neural Brainstem Inside Translucent Rear Skull
			{ partType = "Ball",     size = V(0.28, 0.34, 0.28), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.08, relCF = C(0, 0.08, 0.24), light = true },

			-- 2-Tier Architectural Crown Collar + 13 Uneven Fortress Prisms + Inner Energy Seams
			{ partType = "Normal",   size = V(0.90, 0.14, 0.88), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(0, 0.47, 0.04) },
			{ partType = "Normal",   size = V(0.80, 0.11, 0.78), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, 0.54, 0.04) },
			-- Front Crown Battlements
			{ partType = "Normal",   size = V(0.16, 0.88, 0.16), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.20, relCF = C(0.00, 0.94, -0.34) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.14, 0.62, 0.16), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(-0.18, 0.82, -0.33) * angles(-5, 8, 3) },
			{ partType = "Normal",   size = V(0.14, 0.68, 0.16), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(0.18, 0.85, -0.33) * angles(-5, -8, -3) },
			{ partType = "Normal",   size = V(0.17, 1.06, 0.17), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.20, relCF = C(-0.34, 1.02, -0.24) * angles(-4, 20, 6) },
			{ partType = "Normal",   size = V(0.17, 0.98, 0.17), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.20, relCF = C(0.34, 0.98, -0.24) * angles(-4, -20, -6) },
			-- Side Crown Towers
			{ partType = "Normal",   size = V(0.16, 0.72, 0.18), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(-0.38, 0.86, 0.04) * angles(0, 0, 7) },
			{ partType = "Normal",   size = V(0.16, 0.78, 0.18), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(0.38, 0.89, 0.04) * angles(0, 0, -7) },
			{ partType = "Normal",   size = V(0.16, 0.86, 0.18), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(-0.35, 0.94, 0.26) * angles(6, -14, 6) },
			{ partType = "Normal",   size = V(0.16, 0.92, 0.18), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(0.35, 0.97, 0.26) * angles(6, 14, -6) },
			-- Tall Rear Crown Spires
			{ partType = "Normal",   size = V(0.19, 1.14, 0.19), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.20, relCF = C(-0.18, 1.06, 0.36) * angles(8, 0, 3) },
			{ partType = "Normal",   size = V(0.19, 0.98, 0.19), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.20, relCF = C(0.18, 0.98, 0.36) * angles(8, 0, -3) },
			{ partType = "Normal",   size = V(0.15, 0.74, 0.17), color = PALETTE.CROWN_ICE,   mat = Enum.Material.Glass,         trans = 0.22, relCF = C(0.00, 0.86, 0.38) * angles(9, 0, 0) },
			-- Inner Cyan Refraction Cores Inside Primary Crown Spires
			{ partType = "Normal",   size = V(0.05, 0.64, 0.05), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.16, relCF = C(0.00, 0.90, -0.34) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.05, 0.78, 0.05), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.16, relCF = C(-0.34, 0.96, -0.24) * angles(-4, 20, 6) },
			{ partType = "Normal",   size = V(0.05, 0.74, 0.05), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.16, relCF = C(0.34, 0.94, -0.24) * angles(-4, -20, -6) },
			{ partType = "Normal",   size = V(0.06, 0.84, 0.06), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.16, relCF = C(-0.18, 1.00, 0.36) * angles(8, 0, 3) },
		}
		return specs
	end

	local function getMinosChestSpecs()
		return {
			-- Translucent Outer Thoracic Shell + V-Taper Lats + Back Scapulae
			{ partType = "Normal",   size = V(1.74, 0.88, 0.76), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.38, relCF = C(0, 0.12, 0.02) },
			{ partType = "Wedge",    size = V(0.38, 0.76, 0.66), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.36, relCF = C(-0.84, 0.06, 0.04) * angles(180, 90, 0) },
			{ partType = "Wedge",    size = V(0.38, 0.76, 0.66), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.36, relCF = C(0.84, 0.06, 0.04) * angles(180, -90, 0) },
			{ partType = "Wedge",    size = V(0.68, 0.68, 0.24), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.46, 0.14, 0.36) * angles(0, 168, 180) },
			{ partType = "Wedge",    size = V(0.68, 0.68, 0.24), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.46, 0.14, 0.36) * angles(0, -168, 180) },

			-- Sculpted Pectoralis Major Plates (Upper + Lower Pec Bevels)
			{ partType = "Normal",   size = V(0.76, 0.44, 0.20), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-0.44, 0.22, -0.34) * angles(-6, 10, 0) },
			{ partType = "Normal",   size = V(0.76, 0.44, 0.20), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0.44, 0.22, -0.34) * angles(-6, -10, 0) },
			{ partType = "Wedge",    size = V(0.74, 0.20, 0.24), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(-0.44, -0.04, -0.34) * angles(180, 10, 0) },
			{ partType = "Wedge",    size = V(0.74, 0.20, 0.24), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(0.44, -0.04, -0.34) * angles(180, -10, 0) },

			-- Clavicles & Trapezius Slope
			{ partType = "Cylinder", size = V(0.84, 0.14, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(-0.48, 0.48, -0.22) * angles(0, 12, -10) },
			{ partType = "Cylinder", size = V(0.84, 0.14, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0.48, 0.48, -0.22) * angles(0, -12, 10) },
			{ partType = "Wedge",    size = V(0.48, 0.36, 0.68), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.52, 0.62, 0.08) * angles(0, 90, -14) },
			{ partType = "Wedge",    size = V(0.48, 0.36, 0.68), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.52, 0.62, 0.08) * angles(0, -90, 14) },

			-- Sculpted Multi-Part Deltoid Caps
			{ partType = "Ball",     size = V(0.64, 0.64, 0.64), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.32, relCF = C(-1.02, 0.24, 0.02) },
			{ partType = "Ball",     size = V(0.64, 0.64, 0.64), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.32, relCF = C(1.02, 0.24, 0.02) },
			{ partType = "Ball",     size = V(0.48, 0.54, 0.50), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-1.04, 0.22, 0.00) },
			{ partType = "Ball",     size = V(0.48, 0.54, 0.50), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(1.04, 0.22, 0.00) },

			-- Oversized Anatomical Exposed Prime Heart (Ventricle + Atrium + Aortic Arch + Pulse Core)
			{ partType = "Ball",     size = V(0.46, 0.58, 0.42), color = PALETTE.HEART_RED,   mat = Enum.Material.Neon,          trans = 0.02, relCF = C(-0.18, 0.12, -0.06) * angles(8, 0, -14), light = true },
			{ partType = "Ball",     size = V(0.32, 0.36, 0.30), color = PALETTE.HEART_DARK,  mat = Enum.Material.SmoothPlastic, trans = 0.04, relCF = C(0.02, 0.22, -0.04) },
			{ partType = "Ball",     size = V(0.28, 0.38, 0.26), color = PALETTE.HEART_CORE,  mat = Enum.Material.Neon,          trans = 0.00, relCF = C(-0.20, 0.10, -0.10) * angles(8, 0, -14) },
			{ partType = "Cylinder", size = V(0.30, 0.14, 0.14), color = PALETTE.HEART_RED,   mat = Enum.Material.Neon,          trans = 0.02, relCF = C(-0.08, 0.40, -0.04) * angles(0, 0, 68) },
			{ partType = "Cylinder", size = V(0.22, 0.11, 0.11), color = PALETTE.HEART_DARK,  mat = Enum.Material.SmoothPlastic, trans = 0.02, relCF = C(0.06, 0.38, -0.02) * angles(0, 0, 112) },

			-- Branching Circulatory System (Aortic Trunk, Subclavian Arms, Rib Branches & Dorsal Spine)
			{ partType = "Normal",   size = V(0.10, 0.62, 0.10), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-0.02, 0.00, -0.06) * angles(0, 0, -16), light = true },
			{ partType = "Normal",   size = V(0.08, 0.68, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.05, relCF = C(0.32, 0.30, -0.06) * angles(0, 0, 66) },
			{ partType = "Normal",   size = V(0.08, 0.66, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.05, relCF = C(-0.42, 0.28, -0.04) * angles(0, 0, -64) },
			{ partType = "Normal",   size = V(0.07, 0.48, 0.07), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0.76, 0.26, -0.02) * angles(0, 0, 82) },
			{ partType = "Normal",   size = V(0.07, 0.48, 0.07), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(-0.82, 0.26, -0.02) * angles(0, 0, -82) },
			{ partType = "Normal",   size = V(0.05, 0.48, 0.05), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0.38, -0.02, -0.10) * angles(0, 0, 46) },
			{ partType = "Normal",   size = V(0.05, 0.48, 0.05), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(-0.44, -0.06, -0.10) * angles(0, 0, -44) },
			{ partType = "Normal",   size = V(0.05, 0.46, 0.05), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0.08, 0.36, 0.08) * angles(12, 0, 14) },
			-- Glowing Segmented Dorsal Spine Column
			{ partType = "Cylinder", size = V(0.86, 0.16, 0.16), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.08, relCF = C(0, 0.12, 0.18) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.24, 0.10, 0.18), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, 0.42, 0.24) },
			{ partType = "Normal",   size = V(0.24, 0.10, 0.18), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, 0.20, 0.24) },
			{ partType = "Normal",   size = V(0.22, 0.10, 0.18), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, -0.02, 0.24) },
			{ partType = "Normal",   size = V(0.20, 0.10, 0.18), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, -0.24, 0.24) },
		}
	end

	local function getMinosAbdomenSpecs()
		return {
			-- Tapered Core Shell + Sculpted 6-Pack Abs + External Obliques
			{ partType = "Normal",   size = V(1.22, 0.86, 0.62), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.38, relCF = ID_CF },
			{ partType = "Normal",   size = V(0.34, 0.20, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-0.20, 0.26, -0.28) * angles(-4, 6, 0) },
			{ partType = "Normal",   size = V(0.34, 0.20, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0.20, 0.26, -0.28) * angles(-4, -6, 0) },
			{ partType = "Normal",   size = V(0.32, 0.20, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-0.19, 0.02, -0.28) * angles(0, 6, 0) },
			{ partType = "Normal",   size = V(0.32, 0.20, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0.19, 0.02, -0.28) * angles(0, -6, 0) },
			{ partType = "Normal",   size = V(0.30, 0.22, 0.14), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.17, -0.22, -0.26) * angles(6, 6, 0) },
			{ partType = "Normal",   size = V(0.30, 0.22, 0.14), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.17, -0.22, -0.26) * angles(6, -6, 0) },
			-- Angled External Obliques
			{ partType = "Wedge",    size = V(0.24, 0.68, 0.44), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(-0.56, 0.00, 0.00) * angles(180, 90, 0) },
			{ partType = "Wedge",    size = V(0.24, 0.68, 0.44), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(0.56, 0.00, 0.00) * angles(180, -90, 0) },
			-- Descending Aorta + Iliac Bifurcation + Lower Spine
			{ partType = "Normal",   size = V(0.10, 0.82, 0.10), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(0, 0.04, -0.06) },
			{ partType = "Normal",   size = V(0.06, 0.56, 0.06), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(-0.16, -0.18, -0.08) * angles(0, 0, -24) },
			{ partType = "Normal",   size = V(0.06, 0.56, 0.06), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0.16, -0.18, -0.08) * angles(0, 0, 24) },
			{ partType = "Cylinder", size = V(0.84, 0.14, 0.14), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.08, relCF = C(0, 0.02, 0.18) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.18, 0.10, 0.16), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, 0.18, 0.22) },
			{ partType = "Normal",   size = V(0.18, 0.10, 0.16), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, -0.08, 0.22) },
		}
	end

	local function getMinosPelvisSpecs()
		return {
			{ partType = "Normal",   size = V(1.26, 0.44, 0.62), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, 0.00, 0) },
			{ partType = "Wedge",    size = V(0.68, 0.38, 0.30), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -0.06, -0.24) * angles(180, 0, 0) },
			-- Iliac Crest & Glute Contours
			{ partType = "Wedge",    size = V(0.24, 0.34, 0.54), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.56, 0.06, 0.02) * angles(0, 90, 0) },
			{ partType = "Wedge",    size = V(0.24, 0.34, 0.54), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.56, 0.06, 0.02) * angles(0, -90, 0) },
			{ partType = "Ball",     size = V(0.56, 0.44, 0.46), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.32, -0.06, 0.18) },
			{ partType = "Ball",     size = V(0.56, 0.44, 0.46), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.32, -0.06, 0.18) },
			-- Femoral Vein Bifurcation & Hip Axle
			{ partType = "Cylinder", size = V(1.06, 0.18, 0.18), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(0, -0.10, -0.04) },
			{ partType = "Normal",   size = V(0.07, 0.38, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.05, relCF = C(-0.24, -0.04, -0.06) * angles(0, 0, -48) },
			{ partType = "Normal",   size = V(0.07, 0.38, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.05, relCF = C(0.24, -0.04, -0.06) * angles(0, 0, 48) },
		}
	end

	local function getMinosUpperArmSpecs(side)
		return {
			{ partType = "Normal", size = V(0.50, 0.96, 0.50), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, -0.50, 0) },
			-- Biceps Peak (front) & Triceps Horseshoe (rear)
			{ partType = "Ball",   size = V(0.42, 0.62, 0.40), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -0.46, -0.08) },
			{ partType = "Ball",   size = V(0.40, 0.58, 0.38), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.44, 0.10) },
			-- Branching Brachial Artery
			{ partType = "Normal", size = V(0.08, 0.86, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-side * 0.06, -0.48, -0.06) },
			{ partType = "Normal", size = V(0.05, 0.42, 0.05), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(side * 0.06, -0.64, -0.08) * angles(0, 0, side * 18) },
			-- Sculpted Elbow Joint
			{ partType = "Ball",   size = V(0.36, 0.36, 0.36), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -MINOS_UPPER_ARM_LEN, 0) },
			{ partType = "Ball",   size = V(0.22, 0.22, 0.22), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -MINOS_UPPER_ARM_LEN, 0.06) },
		}
	end

	local function getMinosForearmSpecs(side)
		local specs = {
			-- Tapered Forearm Shell + Brachioradialis Muscle + Ulnar Vein
			{ partType = "Normal", size = V(0.42, 0.94, 0.42), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, -0.48, 0) },
			{ partType = "Wedge",  size = V(0.34, 0.62, 0.22), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(side * 0.06, -0.36, -0.10) * angles(180, 0, side * 8) },
			{ partType = "Normal", size = V(0.07, 0.84, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.05, relCF = C(-side * 0.04, -0.48, -0.04) },
		}

		-- True Parametric 3D Helical Coiled Serpent (12 Smooth Tangent Segments + Glowing Belly)
		local coils = 12
		local turns = 2.65
		local rBase = 0.265
		local lastPos = nil
		for i = 1, coils do
			local frac0 = (i - 1) / coils
			local frac1 = i / coils
			local fracMid = (frac0 + frac1) * 0.5
			local y0 = lerp(-0.14, -0.84, frac0)
			local y1 = lerp(-0.14, -0.84, frac1)
			local th0 = frac0 * turns * math.pi * 2 * side + (side == 1 and 0 or math.pi)
			local th1 = frac1 * turns * math.pi * 2 * side + (side == 1 and 0 or math.pi)
			local r0 = rBase - frac0 * 0.025
			local r1 = rBase - frac1 * 0.025
			local p0 = V(math.cos(th0) * r0, y0, math.sin(th0) * r0)
			local p1 = V(math.cos(th1) * r1, y1, math.sin(th1) * r1)
			local pMid = (p0 + p1) * 0.5
			local segLen = (p1 - p0).Magnitude * 1.18
			local thickness = lerp(0.11, 0.16, math.sin(fracMid * math.pi * 0.82))
			local segCF = C(pMid, p1)

			specs[#specs + 1] = {
				partType = "Normal",
				size = V(thickness, thickness * 0.90, segLen),
				color = PALETTE.SNAKE_SHELL,
				mat = Enum.Material.SmoothPlastic,
				trans = 0.04,
				relCF = segCF,
			}
			specs[#specs + 1] = {
				partType = "Normal",
				size = V(thickness * 0.60, thickness * 0.52, segLen * 0.88),
				color = PALETTE.SNAKE_BELLY,
				mat = Enum.Material.Neon,
				trans = 0.06,
				relCF = C(pMid * 0.88 + V(0, -0.02, 0), p1 * 0.88 + V(0, -0.02, 0)),
			}
			lastPos = p1
		end

		-- Tapered Serpent Tail Tip Near Elbow
		local tailAng = (side == 1 and 0 or math.pi)
		local tailP0 = V(math.cos(tailAng) * rBase, -0.14, math.sin(tailAng) * rBase)
		local tailP1 = V(math.cos(tailAng - 0.45 * side) * (rBase * 0.88), -0.02, math.sin(tailAng - 0.45 * side) * (rBase * 0.88))
		specs[#specs + 1] = {
			partType = "Wedge",
			size = V(0.09, 0.09, 0.24),
			color = PALETTE.SNAKE_SHELL,
			mat = Enum.Material.SmoothPlastic,
			trans = 0.05,
			relCF = C((tailP0 + tailP1) * 0.5, tailP1),
		}

		-- Sculpted Open-Jawed Viper Head Perched at the Outer Wrist
		local headOrigin = lastPos or V(side * 0.24, -0.84, -0.14)
		local headLook = headOrigin + V(side * 0.16, -0.22, -0.62)
		local headBaseCF = C(headOrigin + V(side * 0.04, 0.00, -0.12), headLook)
		specs[#specs + 1] = { partType = "Wedge",  size = V(0.24, 0.16, 0.44), color = PALETTE.SNAKE_SHELL,  mat = Enum.Material.SmoothPlastic, trans = 0.02, relCF = headBaseCF * C(0, 0.06, -0.06) }
		specs[#specs + 1] = { partType = "Wedge",  size = V(0.18, 0.10, 0.36), color = PALETTE.SNAKE_BELLY,  mat = Enum.Material.Neon,          trans = 0.04, relCF = headBaseCF * C(0, -0.07, -0.06) * angles(198, 0, 0) }
		specs[#specs + 1] = { partType = "Normal", size = V(0.26, 0.07, 0.14), color = PALETTE.SNAKE_SHELL,  mat = Enum.Material.SmoothPlastic, trans = 0.02, relCF = headBaseCF * C(0, 0.10, 0.06) }
		specs[#specs + 1] = { partType = "Normal", size = V(0.25, 0.06, 0.08), color = PALETTE.SERPENT_GOLD, mat = Enum.Material.Neon,          trans = 0.00, relCF = headBaseCF * C(0, 0.08, -0.10), light = true }

		return specs
	end

	local function getMinosHandSpecs(side)
		return {
			-- Wrist Collar + Contoured Palm + Glowing Energy Node
			{ partType = "Cylinder", size = V(0.16, 0.34, 0.34), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -0.04, 0) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.36, 0.26, 0.40), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -0.16, 0) },
			{ partType = "Normal",   size = V(0.38, 0.10, 0.42), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(0, -0.26, -0.02) },
			{ partType = "Ball",     size = V(0.14, 0.14, 0.14), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-side * 0.04, -0.18, -0.10) },
			-- Curled Boxer Fingers & Opposable Thumb
			{ partType = "Normal",   size = V(0.36, 0.14, 0.24), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(0, -0.34, -0.14) * angles(-26, 0, 0) },
			{ partType = "Normal",   size = V(0.34, 0.12, 0.20), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.28, relCF = C(0, -0.37, -0.02) * angles(-78, 0, 0) },
			{ partType = "Normal",   size = V(0.13, 0.22, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(-side * 0.20, -0.24, -0.16) * angles(-38, 0, side * -28) },
		}
	end

	local function getMinosThighSpecs(side)
		return {
			{ partType = "Ball",     size = V(0.46, 0.46, 0.46), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = ID_CF },
			{ partType = "Normal",   size = V(0.58, 1.06, 0.58), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, -0.58, 0) },
			-- Sculpted Quadriceps (Vastus Lateralis Sweep, Rectus Femoris, Vastus Medialis) + Hamstring
			{ partType = "Wedge",    size = V(0.30, 0.72, 0.26), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(side * 0.14, -0.48, -0.22) * angles(8, side * -12, 0) },
			{ partType = "Ball",     size = V(0.42, 0.72, 0.36), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.46, -0.10) },
			{ partType = "Ball",     size = V(0.30, 0.36, 0.28), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(-side * 0.14, -0.82, -0.16) },
			{ partType = "Ball",     size = V(0.44, 0.68, 0.38), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.54, 0.12) },
			-- Femoral Artery & Knee Joint + Patella
			{ partType = "Normal",   size = V(0.09, 1.00, 0.09), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-side * 0.08, -0.58, -0.06) },
			{ partType = "Normal",   size = V(0.05, 0.56, 0.05), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(side * 0.10, -0.72, -0.08) * angles(0, 0, side * 14) },
			{ partType = "Cylinder", size = V(0.38, 0.30, 0.30), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -MINOS_THIGH_LEN, 0) },
			{ partType = "Normal",   size = V(0.22, 0.20, 0.14), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0, -MINOS_THIGH_LEN + 0.04, -0.18) },
		}
	end

	local function getMinosShinSpecs(side)
		return {
			{ partType = "Ball",     size = V(0.36, 0.36, 0.36), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = ID_CF },
			{ partType = "Normal",   size = V(0.46, 1.04, 0.46), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.34, relCF = C(0, -0.58, 0) },
			-- Sharp Tibia Ridge + Double-Headed Gastrocnemius Calf + Achilles Taper
			{ partType = "Wedge",    size = V(0.24, 0.88, 0.18), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -0.58, -0.20) * angles(180, 0, 0) },
			{ partType = "Ball",     size = V(0.44, 0.56, 0.42), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -0.38, 0.14) },
			{ partType = "Wedge",    size = V(0.24, 0.54, 0.20), color = PALETTE.FLESH_DEEP,  mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.82, 0.14) * angles(180, 180, 0) },
			-- Tibial Artery & Ankle Joint
			{ partType = "Normal",   size = V(0.08, 0.96, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.04, relCF = C(-side * 0.04, -0.58, -0.04) },
			{ partType = "Normal",   size = V(0.05, 0.46, 0.05), color = PALETTE.VEIN_THIN,   mat = Enum.Material.Neon,          trans = 0.06, relCF = C(side * 0.06, -0.44, 0.06) * angles(0, 0, side * -14) },
			{ partType = "Cylinder", size = V(0.30, 0.26, 0.26), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -MINOS_SHIN_LEN, 0) },
		}
	end

	local function getMinosFootSpecs()
		return {
			{ partType = "Normal", size = V(0.36, 0.18, 0.44), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -0.10, -0.02) },
			{ partType = "Normal", size = V(0.40, 0.14, 0.68), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass,         trans = 0.30, relCF = C(0, -0.29, -0.18) },
			{ partType = "Wedge",  size = V(0.36, 0.18, 0.40), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0, -0.16, -0.32) },
			{ partType = "Wedge",  size = V(0.38, 0.14, 0.30), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0, -0.29, -0.58) },
			{ partType = "Normal", size = V(0.34, 0.04, 0.56), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,          trans = 0.14, relCF = C(0, -0.35, -0.24) },
		}
	end

	local function getSerpentProjectileSpecs()
		local specs = {
			-- Seg 0: Articulated Golden Viper Head + Flaring Hood Fins + Glowing Eyes
			{ key = "seg0", partType = "Wedge",  size = V(0.54, 0.34, 0.98), color = PALETTE.SERPENT_GOLD,   mat = Enum.Material.Neon, trans = 0.00, relCF = C(0, 0.10, -0.18) * angles(6, 0, 0), light = true },
			{ key = "seg0", partType = "Wedge",  size = V(0.42, 0.20, 0.80), color = PALETTE.JUDGEMENT_GOLD, mat = Enum.Material.Neon, trans = 0.00, relCF = C(0, -0.14, -0.14) * angles(196, 0, 0) },
			{ key = "seg0", partType = "Wedge",  size = V(0.18, 0.42, 0.66), color = PALETTE.PRIME_CYAN,     mat = Enum.Material.Neon, trans = 0.10, relCF = C(-0.34, 0.08, 0.18) * angles(-8, -22, 34) },
			{ key = "seg0", partType = "Wedge",  size = V(0.18, 0.42, 0.66), color = PALETTE.PRIME_CYAN,     mat = Enum.Material.Neon, trans = 0.10, relCF = C(0.34, 0.08, 0.18) * angles(-8, 22, -34) },
			{ key = "seg0", partType = "Normal", size = V(0.58, 0.10, 0.16), color = PALETTE.AURA_WHITE,     mat = Enum.Material.Neon, trans = 0.00, relCF = C(0, 0.16, -0.24) },
		}
		-- Seg 1..7: Undulating Tapering Golden Spine + Cyan Dorsal Ridge
		for i = 1, 7 do
			local frac = i / 7
			local w = lerp(0.46, 0.18, frac)
			local key = "seg" .. i
			specs[#specs + 1] = {
				key = key,
				partType = "Normal",
				size = V(w, w * 0.86, 0.96),
				color = (i % 2 == 1) and PALETTE.SERPENT_GOLD or PALETTE.JUDGEMENT_GOLD,
				mat = Enum.Material.Neon,
				trans = lerp(0.00, 0.14, frac),
				relCF = ID_CF,
			}
			specs[#specs + 1] = {
				key = key,
				partType = "Wedge",
				size = V(w * 0.36, w * 0.56, 0.68),
				color = PALETTE.PRIME_CYAN,
				mat = Enum.Material.Neon,
				trans = lerp(0.06, 0.22, frac),
				relCF = C(0, w * 0.52, 0.08) * angles(0, 180, 0),
			}
		end
		-- Seg 8: Forked Tail Fin
		specs[#specs + 1] = { key = "seg8", partType = "Wedge", size = V(0.14, 0.34, 0.82), color = PALETTE.PRIME_CYAN,   mat = Enum.Material.Neon, trans = 0.16, relCF = C(-0.10, 0, 0) * angles(0, 180, 24) }
		specs[#specs + 1] = { key = "seg8", partType = "Wedge", size = V(0.14, 0.34, 0.82), color = PALETTE.SERPENT_GOLD, mat = Enum.Material.Neon, trans = 0.16, relCF = C(0.10, 0, 0) * angles(0, 180, -24) }
		return specs
	end

	local function getMinosAuraSpecs()
		local specs = {}
		local sizes = {
			V(0.28, 0.95, 0.14), V(0.24, 0.85, 0.14),
			V(0.22, 0.78, 0.12), V(0.22, 0.78, 0.12),
			V(0.26, 0.90, 0.14), V(0.26, 0.90, 0.14),
			V(0.20, 0.72, 0.12), V(0.20, 0.72, 0.12),
			V(0.22, 0.82, 0.12), V(0.22, 0.82, 0.12),
			V(0.18, 0.68, 0.12), V(0.18, 0.68, 0.12),
		}
		for i, sz in ipairs(sizes) do
			specs[#specs + 1] = {
				key = "aura" .. i,
				partType = "Wedge",
				size = sz,
				color = (i % 3 == 0) and PALETTE.AURA_WHITE or PALETTE.PRIME_CYAN,
				mat = Enum.Material.Neon,
				trans = 0.24,
				relCF = ID_CF,
				light = (i == 1),
			}
		end
		return specs
	end

	-------------------------------------------------------------------
	-- TARGETING & FACING HELPERS
	-------------------------------------------------------------------
	local function findTargetsInRadius(c, originPos, radius)
		local hits = {}
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tHRP = Core.getTargetRoot(model.Parent)
			if tHRP and tHRP:IsA("BasePart") then
				local d = (tHRP.Position - originPos).Magnitude
				if d <= radius then
					hits[#hits + 1] = { char = model.Parent, hrp = tHRP, dist = d }
				end
			end
		end
		table.sort(hits, function(a, b) return a.dist < b.dist end)
		return hits
	end

	local function findNearestTarget(c, originPos, maxDist, forwardLook)
		local bestChar, bestHRP, bestDist = nil, nil, maxDist
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tHRP = Core.getTargetRoot(model.Parent)
			if tHRP and tHRP:IsA("BasePart") then
				local diff = tHRP.Position - originPos
				local d = diff.Magnitude
				if d > 0.2 and d < bestDist then
					if not forwardLook or diff.Unit:Dot(forwardLook) > -0.45 or d < 8.0 then
						bestDist, bestChar, bestHRP = d, model.Parent, tHRP
					end
				end
			end
		end
		return bestChar, bestHRP, bestDist
	end

	local function getLookAimPos(cam, hrp, range)
		if cam then
			return cam.CFrame.Position + cam.CFrame.LookVector * range
		end
		return hrp.Position + hrp.CFrame.LookVector * range
	end

	local function snapTurnTowards(hrp, targetPos, inFP)
		if inFP or not hrp or not targetPos then return end
		local flat = V(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z)
		if flat.Magnitude > 0.25 then
			hrp.CFrame = C(hrp.Position, hrp.Position + flat.Unit)
		end
	end

	-------------------------------------------------------------------
	-- EXPORTED MODULE FOR CORE
	-------------------------------------------------------------------
	Core.start({
		id = "minos",
		name = "MINOS PRIME",
		config = {
			RENDER_NAME = "F3X_Minos_Reanim",
			HUD_RENDER_NAME = "F3X_Minos_3DHUD",
			SCALE = 1.08,
			SOLE_DEPTH = MINOS_SOLE_DEPTH,

			-- Fast, aggressive Prime Soul movement tuning
			WALK_SPEED = 22,
			SPRINT_SPEED = 42,
			JUMP_POWER = 62,
			AIR_GRAVITY_CANCEL = 0.28,
			GLIDE_GRAVITY_CANCEL = 0.54,
			GLIDE_MAX_FALL = 20,
			AIR_STRAFE_ACCEL = 66,
			AIR_DRAG = 0.20,
			SLAM_STORAGE_JUMP = 116,

			HUD_UNIT_HEADER = "P-1 // KING OF LUST",
			HUD_WEAPON_TITLE = "JUDGEMENT // SERPENT",
			HUD_WEAPON_COLOR = PALETTE.PRIME_CYAN,
			HUD_KEY_HINT = "[LMB] BOXING  [R] THY END/OVERHEAD  [E] SERPENT  [F] JUDGEMENT  [C] DIE/CRUSH  [G] PHASE II",
			BGM_URL = "https://raw.githubusercontent.com/thatonexploiter/ultrakill-f3x/main/audio/order.mp3",
			BGM_FILE = "minos_order.mp3",
			BGM_FALLBACK_ID = "rbxassetid://15081073002",
			BGM_VOLUME = 0.46,
			HUD_PIP_COLOR = PALETTE.SERPENT_GOLD,
			MOBILE_PRIMARY_LABEL = "SERPENT",
			MOBILE_PRIMARY_COLOR = PALETTE.SERPENT_GOLD,
			MOBILE_SECONDARY_LABEL = "JUDGE",
			MOBILE_SECONDARY_COLOR = PALETTE.PRIME_CYAN,
		},

		initState = function()
			local STATE = Core.getState()
			local playVoice = createAudioPlayer(STATE)

			STATE.custom.playVoice = playVoice
			STATE.custom.lastStepNow = os.clock()
			STATE.custom.phase2 = false
			STATE.custom.phase2FlashTime = -10
			STATE.custom.autoPhase2Triggered = false
			STATE.custom.wasSlamming = false
			STATE.custom.slamKind = "CRUSH"
			STATE.custom.slamDir = V(0, -1, 0)

			STATE.custom.serpent = {
				active = false,
				kickPhase = false,
				projectileActive = false,
				lastUsed = 0,
				startTime = 0,
				kickHit1 = false,
				kickHit2 = false,
				launched = false,
				pos = V(0, 0, 0),
				vel = V(0, 0, 0),
				originPos = V(0, 0, 0),
				targetChar = nil,
				cf = PARK_CF,
				trailTick = 0,
				history = {},
			}

			STATE.custom.judgement = {
				active = false,
				lastUsed = 0,
				startTime = 0,
				teleported = false,
				exploded = false,
				flashDone = false,
				targetChar = nil,
				aimDir = V(0, 0, -1),
			}

			STATE.custom.combo = {
				active = false,
				step = 0,
				lastUsed = 0,
				startTime = 0,
				hitDone = false,
				uppercut = false,
				followup = false,
				lungeDone = false,
			}

			STATE.custom.blitz = {
				active = false,
				overheadOnly = false,
				lastUsed = 0,
				startTime = 0,
				phase = 0,
				targetChar = nil,
			}

			local function triggerPhase2(manual)
				if STATE.custom.phase2 and not manual then return end
				STATE.custom.phase2 = not STATE.custom.phase2
				if STATE.custom.phase2 then
					STATE.custom.phase2FlashTime = os.clock()
					local c = Core.getChar()
					local hrp = c and c:FindFirstChild("HumanoidRootPart")
					playVoice("WEAK", 1.0, 1.0)
					Core.playSFX("PARRY", 0.65, 1.0)
					Core.playSFX("SHATTER", 0.70, 0.95, "PARRY")
					Core.addStyleBonus("+WEAK // PHASE II", 300, PALETTE.PRIME_CYAN)
					STATE.camShake = math.max(STATE.camShake, 0.72)
					STATE.fovKick = math.max(STATE.fovKick, 10)
					if hrp then
						Core.spawnRing(hrp.Position, PALETTE.PRIME_CYAN, 1.4, 15.0, 0.36)
						Core.spawnFlash(hrp.Position, PALETTE.AURA_WHITE, 1.4, 7.5, 0.28)
					end
				else
					Core.playSFX("COIN_FLIP", 0.75, 0.75, "PARRY")
				end
			end
			STATE.custom.triggerPhase2 = triggerPhase2

			-- Clean previous connections if reloaded
			if STATE.custom.lmbConn then pcall(function() STATE.custom.lmbConn:Disconnect() end) end
			if STATE.custom.keyConn then pcall(function() STATE.custom.keyConn:Disconnect() end) end
			if STATE.custom.diedConn then pcall(function() STATE.custom.diedConn:Disconnect() end) end

			local function isAliveState()
				local cur = Core.getState()
				if cur ~= STATE or not cur.alive then
					if STATE.custom.lmbConn then pcall(function() STATE.custom.lmbConn:Disconnect() end) STATE.custom.lmbConn = nil end
					if STATE.custom.keyConn then pcall(function() STATE.custom.keyConn:Disconnect() end) STATE.custom.keyConn = nil end
					if STATE.custom.diedConn then pcall(function() STATE.custom.diedConn:Disconnect() end) STATE.custom.diedConn = nil end
					if STATE.custom.audioCleanup then STATE.custom.audioCleanup() end
					return false
				end
				return true
			end

			-- Intro cue
			task.delay(0.18, function()
				if isAliveState() then
					playVoice("INTRO", 1.0, 0.92)
				end
			end)

			-- Death cue
			local initChar = Core.getChar()
			local initHum = initChar and initChar:FindFirstChildOfClass("Humanoid")
			if initHum then
				STATE.custom.diedConn = initHum.Died:Connect(function()
					playVoice("DEATH", 1.0, 1.0)
					local hrp = initChar:FindFirstChild("HumanoidRootPart")
					if hrp then
						Core.spawnRing(hrp.Position, PALETTE.PRIME_CYAN, 1.5, 18.0, 0.45)
						Core.spawnFlash(hrp.Position, PALETTE.AURA_WHITE, 2.0, 9.0, 0.35)
					end
				end)
			end

			-- LMB Boxing Combo + Auto-Uppercut
			STATE.custom.lmbConn = UserInputService.InputBegan:Connect(function(input, gp)
				if not isAliveState() or gp or STATE.isSettingUp then return end
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

				local ja = STATE.custom.judgement
				local bz = STATE.custom.blitz
				local cb = STATE.custom.combo
				local now = os.clock()
				local cdMult = STATE.custom.phase2 and 0.72 or 1.0

				if ja.active or bz.active then return end
				if cb.active and (now - cb.startTime) < (0.14 * cdMult) then return end
				if (now - cb.lastUsed) < (COMBO_COOLDOWN * cdMult) then return end

				local resetChain = (now - cb.lastUsed) > 1.05
				cb.step = resetChain and 1 or ((cb.step % 4) + 1)
				cb.active = true
				cb.lastUsed = now
				cb.startTime = now
				cb.hitDone = false
				cb.lungeDone = false
				cb.uppercut = false
				cb.followup = false

				local c = Core.getChar()
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				if hrp then
					local _, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 5, hrp.CFrame.LookVector)
					if tHRP and (tHRP.Position.Y - hrp.Position.Y) > 3.6 then
						cb.uppercut = true
					end
				end

				if cb.step == 4 and not cb.uppercut then
					playVoice("THY_END", 1.04, 0.90)
					Core.playSFX("COIN_FLIP", 0.92, 0.9, "PARRY")
				end
				Core.playSFX("PUNCH", cb.step == 4 and 0.80 or (0.98 + cb.step * 0.07), 0.92, "PARRY")
			end)

			-- [R] Full "THY END IS NOW!" 4-Hit Teleport Blitz / Aerial Overhead & [G] Phase 2 Overdrive
			STATE.custom.keyConn = UserInputService.InputBegan:Connect(function(input, gp)
				if not isAliveState() or gp or STATE.isSettingUp then return end
				local now = os.clock()
				local cdMult = STATE.custom.phase2 and 0.72 or 1.0

				if input.KeyCode == Enum.KeyCode.G then
					triggerPhase2(true)
					return
				end

				if input.KeyCode == Enum.KeyCode.R then
					local ja = STATE.custom.judgement
					local sa = STATE.custom.serpent
					local bz = STATE.custom.blitz
					if ja.active or sa.kickPhase or bz.active then return end
					if (now - bz.lastUsed) < (BLITZ_COOLDOWN * cdMult) then return end

					local c = Core.getChar()
					local hrp = c and c:FindFirstChild("HumanoidRootPart")
					local hum = c and c:FindFirstChildOfClass("Humanoid")
					if not (hrp and hum) then return end

					local isAir = (hum.FloorMaterial == Enum.Material.Air) or (STATE.airBlend > 0.35)
					local tChar = findNearestTarget(c, hrp.Position, BLITZ_RANGE, nil)

					bz.active = true
					bz.overheadOnly = isAir
					bz.lastUsed = now
					bz.startTime = now
					bz.phase = 0
					bz.targetChar = tChar
					STATE.custom.combo.active = false

					if isAir then
						playVoice("USELESS", 1.0, 0.95)
						Core.playSFX("COIN_FLIP", 0.90, 0.95, "PARRY")
						Core.spawnFlash(hrp.Position, PALETTE.PRIME_CYAN, 0.7, 3.4, 0.16)
					else
						playVoice("THY_END", 1.0, 1.0)
						Core.playSFX("COIN_FLIP", 0.84, 1.0, "PARRY")
						Core.spawnFlash(hrp.Position + V(0, 0.6, 0), PALETTE.JUDGEMENT_GOLD, 0.8, 3.8, 0.18)
					end
				end
			end)
		end,

		buildModel = function(_, _, _, _, torsoInitCF)
			local specs = {}
			local chestCF = torsoInitCF * C(0, MINOS_CHEST_OFFSET, 0)
			local abdomenCF = torsoInitCF * C(0, MINOS_ABDOMEN_OFFSET, 0)
			local pelvisCF = torsoInitCF * C(0, MINOS_PELVIS_OFFSET, 0)
			local headInitCF = chestCF * C(0, 1.06, -0.04)

			local function addMinos(kind, list, parentCF, key)
				for _, sp in ipairs(list) do
					specs[#specs + 1] = {
						kind = kind,
						key = sp.key or key,
						partType = sp.partType,
						relCF = sp.relCF,
						origCF = (parentCF == PARK_CF) and PARK_CF or (parentCF * sp.relCF),
						origSize = sp.size,
						origColor = sp.color,
						origMaterial = sp.mat,
						origTrans = sp.trans or 0,
						origReflectance = 0,
						light = sp.light,
					}
				end
			end

			addMinos("minosHead", getMinosHeadSpecs(), headInitCF)
			addMinos("minosBody", getMinosChestSpecs(), chestCF, "chest")
			addMinos("minosBody", getMinosAbdomenSpecs(), abdomenCF, "abdomen")
			addMinos("minosBody", getMinosPelvisSpecs(), pelvisCF, "pelvis")

			local shoulderL = chestCF * C(-1.06, 0.24, 0)
			local shoulderR = chestCF * C(1.06, 0.24, 0)
			local elbowL, elbowR = shoulderL * C(0, -MINOS_UPPER_ARM_LEN, 0), shoulderR * C(0, -MINOS_UPPER_ARM_LEN, 0)
			local wristL, wristR = elbowL * C(0, -MINOS_FOREARM_LEN, 0), elbowR * C(0, -MINOS_FOREARM_LEN, 0)

			addMinos("minosUpperArm", getMinosUpperArmSpecs(-1), shoulderL, "lUpperArm")
			addMinos("minosUpperArm", getMinosUpperArmSpecs(1), shoulderR, "rUpperArm")
			addMinos("minosForearm", getMinosForearmSpecs(-1), elbowL, "lForearm")
			addMinos("minosForearm", getMinosForearmSpecs(1), elbowR, "rForearm")
			addMinos("minosHand", getMinosHandSpecs(-1), wristL, "lHand")
			addMinos("minosHand", getMinosHandSpecs(1), wristR, "rHand")

			local hipL = pelvisCF * C(-0.46, MINOS_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, MINOS_HIP_Y, 0)
			local kneeL, kneeR = hipL * C(0, -MINOS_THIGH_LEN, 0), hipR * C(0, -MINOS_THIGH_LEN, 0)
			local ankleL, ankleR = kneeL * C(0, -MINOS_SHIN_LEN, 0), kneeR * C(0, -MINOS_SHIN_LEN, 0)

			addMinos("minosThigh", getMinosThighSpecs(-1), hipL, "lThigh")
			addMinos("minosThigh", getMinosThighSpecs(1), hipR, "rThigh")
			addMinos("minosShin", getMinosShinSpecs(-1), kneeL, "lShin")
			addMinos("minosShin", getMinosShinSpecs(1), kneeR, "rShin")
			addMinos("minosFoot", getMinosFootSpecs(), ankleL, "lFoot")
			addMinos("minosFoot", getMinosFootSpecs(), ankleR, "rFoot")

			-- Articulated 10-Segment Undulating Golden Serpent & Phase 2 Flame Aura
			addMinos("minosSerpent", getSerpentProjectileSpecs(), PARK_CF)
			addMinos("minosAura", getMinosAuraSpecs(), PARK_CF)

			return specs
		end,

		-- [E] / SERPENT: "PREPARE THYSELF!" (2-Kick Crescent Sweep + Homing Slithering Serpent)
		onPrimary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local sa = STATE.custom.serpent
			local ja = STATE.custom.judgement
			local bz = STATE.custom.blitz
			local now = os.clock()
			local cdMult = STATE.custom.phase2 and 0.72 or 1.0
			if ja.active or bz.active or sa.kickPhase or (now - sa.lastUsed) < (SERPENT_COOLDOWN * cdMult) then return end

			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			STATE.custom.combo.active = false
			sa.active = true
			sa.kickPhase = true
			sa.lastUsed = now
			sa.startTime = now
			sa.kickHit1 = false
			sa.kickHit2 = false
			sa.launched = false

			STATE.custom.playVoice("PREPARE", STATE.custom.phase2 and 1.05 or 1.0, 1.0)
			Core.playSFX("PUNCH", 0.90, 0.95, "PARRY")
		end,

		-- [F] / JUDGEMENT: "JUDGEMENT!" (Parry-Glint Telegraph -> Teleport -> Explosive Dropkick)
		onSecondary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local ja = STATE.custom.judgement
			local bz = STATE.custom.blitz
			local now = os.clock()
			local cdMult = STATE.custom.phase2 and 0.72 or 1.0
			if ja.active or bz.active or (now - ja.lastUsed) < (JUDGEMENT_COOLDOWN * cdMult) then return end

			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			STATE.custom.combo.active = false
			STATE.custom.serpent.kickPhase = false
			ja.active = true
			ja.lastUsed = now
			ja.startTime = now
			ja.teleported = false
			ja.exploded = false
			ja.flashDone = false

			local tChar, tHRP = findNearestTarget(c, hrp.Position, JUDGEMENT_RANGE, nil)
			ja.targetChar = tChar
			if tHRP then
				local flat = V(tHRP.Position.X - hrp.Position.X, 0, tHRP.Position.Z - hrp.Position.Z)
				ja.aimDir = (flat.Magnitude > 0.1) and flat.Unit or hrp.CFrame.LookVector
			else
				ja.aimDir = hrp.CFrame.LookVector
			end

			STATE.custom.playVoice("JUDGEMENT", STATE.custom.phase2 and 1.06 or 1.0, 1.0)
			Core.playSFX("COIN_FLIP", 0.72, 1.0, "PARRY")
			Core.spawnFlash(hrp.Position + V(0, 0.8, 0), PALETTE.JUDGEMENT_GOLD, 0.9, 4.2, 0.24)
		end,

		stepCharacter = function(_, c, hrp, hum, _, ctx)
			local STATE = Core.getState()
			local CONFIG = Core.getConfig()
			local now = ctx.now
			local inFP = ctx.inFP
			local cam = ctx.cam
			local isAir = ctx.isAir
			local sinW, cosW = ctx.sinW, ctx.cosW

			local dtStep = clamp(now - (STATE.custom.lastStepNow or now), 1 / 240, 0.05)
			STATE.custom.lastStepNow = now

			-- Auto-trigger Phase 2 below 50% HP
			if hum and hum.MaxHealth > 0 and hum.Health > 0 and (hum.Health / hum.MaxHealth) <= 0.50 then
				if not STATE.custom.autoPhase2Triggered then
					STATE.custom.autoPhase2Triggered = true
					if not STATE.custom.phase2 then
						STATE.custom.triggerPhase2(false)
					end
				end
			end

			local p2 = STATE.custom.phase2
			local speedScale = p2 and 1.24 or 1.0
			local t = STATE.time
			local idleWeight = clamp(1 - STATE.walkBlend, 0, 1) * (1 - STATE.airBlend)
			local realSoleDepth = (STATE.rigType == "R15") and (hum.HipHeight + hrp.Size.Y * 0.5) or 3.0
			local groundOffsetY = MINOS_SOLE_DEPTH - realSoleDepth

			local camPitch, camYawLocal = 0, 0
			if CONFIG.ENABLE_HEAD_AIM_TRACKING and cam then
				local camLocalLook = hrp.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)
				camPitch = clamp(math.asin(clamp(camLocalLook.Y, -0.85, 0.85)) * 180 / math.pi, -45, 55)
				camYawLocal = clamp(math.atan2(-camLocalLook.X, -camLocalLook.Z) * 180 / math.pi, -38, 38)
			end

			-- Boxer Peek-a-Boo Breathing & Spine Articulation Offsets
			local breathe = math.sin(t * (p2 and 4.2 or 3.1))
			local guardBobL = math.sin(t * 3.8)
			local guardBobR = math.cos(t * 3.8)

			local torsoY = groundOffsetY
				+ breathe * 0.055 * idleWeight
				+ math.abs(sinW) * 0.16 * STATE.walkBlend * (1 + STATE.sprintBlend * 0.45)
				- STATE.landRecover * 0.34

			-- Multi-segment spine angles: Pelvis (hips), Abdomen (waist), Chest (upper torso)
			local pelvisPitch = -STATE.localFwd * (4 + STATE.sprintBlend * 6) - STATE.landRecover * 8
			local pelvisYaw   = 26 * idleWeight - cosW * (6 + STATE.sprintBlend * 8) * STATE.walkBlend
			local pelvisRoll  = -STATE.localStrafe * 8 - STATE.turnRate * 1.8

			local torsoPitch  = -STATE.localFwd * (8 + STATE.sprintBlend * 11) - STATE.landRecover * 10 + STATE.airBlend * clamp(-STATE.vertVel * 0.32, -16, 16)
			local torsoYaw    = -6 * idleWeight + cosW * (12 + STATE.sprintBlend * 11) * STATE.walkBlend
			local torsoRoll   = -STATE.localStrafe * 6 - STATE.turnRate * 1.5

			-- Arm base poses (Bladed Boxer Stance + Driving Sprint Pump)
			local lShoulderOff = V(0, 0, 0)
			local rShoulderOff = V(0, 0, 0)

			local lUpperPitch = lerp(-10, 52 + guardBobL * 5, idleWeight) + sinW * (34 + STATE.sprintBlend * 24) * STATE.walkBlend
			local lUpperYaw   = -18 * idleWeight
			local lUpperRoll  = 14 + STATE.airBlend * 16
			local lForePitch  = lerp(34, 96 + guardBobR * 6, idleWeight) + math.max(0, sinW) * 24 * STATE.walkBlend
			local lHandPitch, lHandYaw, lHandRoll = -8 * idleWeight, 14 * idleWeight, -12 * idleWeight

			local rUpperPitch = lerp(-12, 42 + guardBobR * 5, idleWeight) - sinW * (34 + STATE.sprintBlend * 24) * STATE.walkBlend
			local rUpperYaw   = 16 * idleWeight
			local rUpperRoll  = -14 - STATE.airBlend * 16
			local rForePitch  = lerp(32, 88 + guardBobL * 6, idleWeight) + math.max(0, -sinW) * 24 * STATE.walkBlend
			local rHandPitch, rHandYaw, rHandRoll = -8 * idleWeight, -14 * idleWeight, 12 * idleWeight

			-- Leg base poses (Grounded Martial Stance + Deep Sprint Knee Drive)
			local lThighP, rThighP = 14 * idleWeight, -16 * idleWeight
			local lThighY, rThighY = 10 * idleWeight, -10 * idleWeight
			local lShinP, rShinP = -20 * idleWeight, -14 * idleWeight
			local lFootP, rFootP = 6 * idleWeight, 26 * idleWeight

			if STATE.walkBlend > 0.01 then
				local stride = 42 + STATE.sprintBlend * 24
				lThighP = lerp(lThighP, sinW * stride, STATE.walkBlend)
				rThighP = lerp(rThighP, -sinW * stride, STATE.walkBlend)
				lShinP = lerp(lShinP, -math.max(0, -cosW) * (54 + STATE.sprintBlend * 26) - 8, STATE.walkBlend)
				rShinP = lerp(rShinP, -math.max(0, cosW) * (54 + STATE.sprintBlend * 26) - 8, STATE.walkBlend)
				lFootP = lerp(lFootP, cosW * 20, STATE.walkBlend)
				rFootP = lerp(rFootP, -cosW * 20, STATE.walkBlend)
			end

			if STATE.airBlend > 0.01 then
				local airTuckL, airTuckR = 26, 48
				local shinTuckL, shinTuckR = -38, -74
				if STATE.slam.active then
					if STATE.custom.slamKind == "DIE" then
						-- "DIE!" Diagonal Flying Rider Kick
						pelvisPitch = 28
						torsoPitch = 16
						pelvisYaw = -22
						torsoYaw = 18
						airTuckL, airTuckR = -20, 66
						shinTuckL, shinTuckR = -92, -6
						lUpperPitch, lUpperRoll, lForePitch = -32, 42, 18
						rUpperPitch, rUpperRoll, rForePitch = 64, -14, 42
					else
						-- "CRUSH!" Vertical Meteor Stomp
						pelvisPitch = -14
						torsoPitch = -22
						airTuckL, airTuckR = 54, 46
						shinTuckL, shinTuckR = -78, -66
						lUpperPitch, lUpperRoll, lForePitch = -38, 48, 28
						rUpperPitch, rUpperRoll, rForePitch = -38, -48, 28
					end
				elseif STATE.isGliding then
					airTuckL, airTuckR = 14, 30
					shinTuckL, shinTuckR = -24, -52
					lUpperRoll, rUpperRoll = 28, -28
				end
				lThighP = lerp(lThighP, airTuckL, STATE.airBlend)
				rThighP = lerp(rThighP, airTuckR, STATE.airBlend)
				lShinP = lerp(lShinP, shinTuckL, STATE.airBlend)
				rShinP = lerp(rShinP, shinTuckR, STATE.airBlend)
			end

			if STATE.slide.active and not isAir then
				torsoY -= 1.38
				pelvisPitch = 40
				torsoPitch = 8
				pelvisYaw = 22
				torsoRoll = -STATE.localStrafe * 12
				lThighP, rThighP = 42, -30
				lShinP, rShinP = -10, -84
				lFootP, rFootP = -20, 22
				lUpperPitch, lUpperRoll, lForePitch = -24, 34, 16
				rUpperPitch, rUpperRoll, rForePitch = 32, -18, 72
			end

			if STATE.dash.active then
				local dK = 1 - clamp((now - STATE.dash.startTime) / math.max(0.01, CONFIG.DASH_DURATION), 0, 1)
				local ld = STATE.dash.localDir
				pelvisPitch += ld.Z * 18 * dK
				torsoPitch += ld.Z * 20 * dK
				pelvisRoll -= ld.X * 16 * dK
				torsoRoll -= ld.X * 16 * dK
				lUpperPitch = lerp(lUpperPitch, -38, dK * 0.8)
				rUpperPitch = lerp(rUpperPitch, -38, dK * 0.8)
				lUpperRoll = lerp(lUpperRoll, 34, dK * 0.8)
				rUpperRoll = lerp(rUpperRoll, -34, dK * 0.8)
			end

			-------------------------------------------------------------------
			-- [C] SLAM TRACKING: "DIE!" (RIDER KICK) & "CRUSH!" (VERTICAL SLAM)
			-------------------------------------------------------------------
			if STATE.slam.active and not STATE.custom.wasSlamming then
				-- Rising edge of Slam: determine DIE! vs CRUSH!
				local tChar, tHRP = findNearestTarget(c, hrp.Position, 65, nil)
				local isDie = false
				if tHRP then
					local flatDist = V(tHRP.Position.X - hrp.Position.X, 0, tHRP.Position.Z - hrp.Position.Z).Magnitude
					if flatDist > 7.5 and (hrp.Position.Y - tHRP.Position.Y) > 2.0 then
						isDie = true
						local dir = (tHRP.Position - hrp.Position).Unit
						STATE.custom.slamDir = dir
						snapTurnTowards(hrp, tHRP.Position, inFP)
						hrp.AssemblyLinearVelocity = dir * 88
					end
				end
				STATE.custom.slamKind = isDie and "DIE" or "CRUSH"
				if isDie then
					STATE.custom.playVoice("DIE", 1.0, 1.0)
					Core.playSFX("COIN_FLIP", 1.15, 0.95, "PARRY")
				else
					STATE.custom.playVoice("CRUSH", 1.0, 1.0)
					Core.playSFX("PARRY", 0.62, 0.85)
				end
				Core.spawnFlash(hrp.Position, PALETTE.PRIME_CYAN, 0.9, 4.6, 0.18)
				Core.spawnRing(hrp.Position, PALETTE.PRIME_CYAN, 0.6, 4.2, 0.20)
			elseif STATE.slam.active and STATE.custom.slamKind == "DIE" then
				if math.random() < 0.45 then
					Core.fireDualBeams(hrp.Position, hrp.Position - STATE.custom.slamDir * 2.5, hrp.Position - STATE.custom.slamDir * 5.0, PALETTE.PRIME_CYAN, PALETTE.AURA_WHITE, 0.12, 0.06, false, 0.10)
				end
			elseif STATE.custom.wasSlamming and not STATE.slam.active and not isAir then
				local wasDie = (STATE.custom.slamKind == "DIE")
				Core.playSFX("PARRY", wasDie and 0.82 or 0.66, 1.0)
				Core.playSFX("SHATTER", 0.74, 0.95, "PARRY")
				Core.spawnRing(hrp.Position - V(0, 2.2, 0), PALETTE.PRIME_CYAN, 1.8, wasDie and 15.0 or 18.5, 0.36)
				Core.spawnRing(hrp.Position - V(0, 2.1, 0), PALETTE.AURA_WHITE, 1.2, wasDie and 11.0 or 13.5, 0.28)
				Core.spawnFlash(hrp.Position - V(0, 2.0, 0), PALETTE.PRIME_CYAN, 1.4, 8.0, 0.26)
				Core.addStyleBonus(wasDie and "+DIE!" or "+CRUSH!", wasDie and 190 or 220, PALETTE.PRIME_CYAN)
				STATE.camShake = math.max(STATE.camShake, wasDie and 0.75 or 0.95)
				STATE.fovKick = math.max(STATE.fovKick, 10)
				local radius = wasDie and 14.5 or 17.0
				local kb = wasDie and DIE_KNOCKBACK or CRUSH_KNOCKBACK
				for _, hit in ipairs(findTargetsInRadius(c, hrp.Position, radius)) do
					Core.applyF3XKnockback(hit.char, hit.hrp.Position - hrp.Position, kb)
				end
			end
			STATE.custom.wasSlamming = STATE.slam.active

			-------------------------------------------------------------------
			-- HELPER: SPAWN HOMING GOLDEN SERPENT
			-------------------------------------------------------------------
			local sa = STATE.custom.serpent
			local function launchSerpentProjectile(originOffset)
				sa.active = true
				sa.projectileActive = true
				sa.startTime = now
				sa.trailTick = 0
				sa.history = {}

				local launchPos = (hrp.CFrame * originOffset).Position
				local aimTargetPos = getLookAimPos(cam, hrp, SERPENT_RANGE)
				local tChar, tHRP = findNearestTarget(c, launchPos, SERPENT_RANGE, nil)
				local dir = ((tHRP and tHRP.Position or aimTargetPos) - launchPos)
				dir = (dir.Magnitude > 0.1) and dir.Unit or hrp.CFrame.LookVector
				sa.originPos = launchPos
				sa.pos = launchPos
				sa.vel = dir * SERPENT_SPEED
				sa.targetChar = tChar
				sa.cf = C(sa.pos, sa.pos + dir)
				for idx = 1, 24 do
					sa.history[idx] = sa.pos - dir * ((idx - 1) * 0.45)
				end
				Core.playSFX("COIN_FLIP", 0.92, 1.0, "PARRY")
				Core.spawnRing(launchPos, PALETTE.SERPENT_GOLD, 0.7, 4.2, 0.22)
				Core.spawnFlash(launchPos, PALETTE.JUDGEMENT_GOLD, 0.8, 3.6, 0.16)
			end

			-------------------------------------------------------------------
			-- MOVE 1: [LMB] BOXING COMBO + UPPERCUT + GROUND-PIN FINISHER
			-------------------------------------------------------------------
			local cb = STATE.custom.combo
			if cb.active then
				local cEl = (now - cb.startTime) * speedScale
				local dur = (cb.step == 4 and not cb.uppercut) and 0.56 or 0.30
				if cEl < dur then
					if cb.uppercut then
						-- Deep crouch windup -> explosive skyward Uppercut
						local w = clamp(cEl / 0.08, 0, 1)
						local k = easeOutBack(clamp((cEl - 0.06) / 0.16, 0, 1))
						torsoY -= 0.42 * (1 - k) * w
						pelvisPitch = lerp(pelvisPitch, -18 * (1 - k) + 12 * k, w)
						torsoPitch = lerp(torsoPitch, 18 * (1 - k) - 24 * k, w)
						pelvisYaw = lerp(pelvisYaw, -26, k)
						torsoYaw = lerp(torsoYaw, -38, k)
						rShoulderOff = V(0, 0.16 * k, -0.28 * k)
						rUpperPitch = lerp(rUpperPitch, 152, k)
						rUpperYaw = lerp(rUpperYaw, -14, k)
						rForePitch = lerp(rForePitch, 26, k)
						rHandPitch, rHandRoll = 18 * k, -28 * k
						lUpperPitch, lForePitch = lerp(lUpperPitch, -28, k), lerp(lForePitch, 48, k)
					elseif cb.step == 1 then
						-- Snap Left Jab with Hip-Shoulder Whip
						local w = clamp(cEl / 0.05, 0, 1)
						local k = easeOutBack(clamp(cEl / 0.12, 0, 1))
						local rec = clamp((cEl - 0.16) / 0.14, 0, 1)
						local a = k * (1 - rec * 0.45)
						pelvisYaw = lerp(pelvisYaw, -26, a)
						torsoYaw = lerp(torsoYaw, -38, a)
						torsoPitch = lerp(torsoPitch, -12, a)
						lShoulderOff = V(0, 0.04 * a, -0.34 * a)
						lUpperPitch = lerp(lUpperPitch, 96 + camPitch * 0.65, a)
						lUpperYaw = lerp(lUpperYaw, -16, a)
						lForePitch = lerp(lForePitch, 6, a)
						lHandRoll = lerp(lHandRoll, -90, a)
						rUpperPitch = lerp(rUpperPitch, 56, w)
						rForePitch = lerp(rForePitch, 108, w)
					elseif cb.step == 2 then
						-- Heavy Right Cross
						local w = clamp(cEl / 0.05, 0, 1)
						local k = easeOutBack(clamp(cEl / 0.12, 0, 1))
						local rec = clamp((cEl - 0.16) / 0.14, 0, 1)
						local a = k * (1 - rec * 0.45)
						pelvisYaw = lerp(pelvisYaw, 30, a)
						torsoYaw = lerp(torsoYaw, 44, a)
						torsoPitch = lerp(torsoPitch, -14, a)
						rShoulderOff = V(0, 0.04 * a, -0.38 * a)
						rUpperPitch = lerp(rUpperPitch, 98 + camPitch * 0.65, a)
						rUpperYaw = lerp(rUpperYaw, 18, a)
						rForePitch = lerp(rForePitch, 6, a)
						rHandRoll = lerp(rHandRoll, 90, a)
						lUpperPitch = lerp(lUpperPitch, 52, w)
						lForePitch = lerp(lForePitch, 108, w)
					elseif cb.step == 3 then
						-- Spinning Left Haymaker Hook
						local k = easeOutBack(clamp(cEl / 0.14, 0, 1))
						pelvisYaw = lerp(pelvisYaw, -36, k)
						torsoYaw = lerp(torsoYaw, -56, k)
						torsoRoll = lerp(torsoRoll, 16, k)
						lShoulderOff = V(-0.12 * k, 0.08 * k, -0.26 * k)
						lUpperPitch = lerp(lUpperPitch, 88, k)
						lUpperYaw = lerp(lUpperYaw, -62, k)
						lUpperRoll = lerp(lUpperRoll, 24, k)
						lForePitch = lerp(lForePitch, 64, k)
						lHandRoll = lerp(lHandRoll, -45, k)
					else
						-- Step 4 Finisher: Wind-Up Overhead -> Ground-Pin Slam -> Fist Dislodge Recovery
						if cEl < 0.14 then
							local w = easeOutQuad(cEl / 0.14)
							torsoY += 0.24 * w
							pelvisPitch = lerp(pelvisPitch, 14, w)
							torsoPitch = lerp(torsoPitch, 20, w)
							rUpperPitch = lerp(rUpperPitch, 162, w)
							lUpperPitch = lerp(lUpperPitch, 68, w)
							rForePitch = lerp(rForePitch, 32, w)
						elseif cEl < 0.40 then
							local k = easeOutBack(clamp((cEl - 0.14) / 0.10, 0, 1))
							torsoY -= 0.72 * k
							pelvisPitch = lerp(pelvisPitch, -24, k)
							torsoPitch = lerp(torsoPitch, -34, k)
							torsoYaw = lerp(torsoYaw, 32, k)
							lThighP, rThighP = lerp(lThighP, 54, k), lerp(rThighP, -36, k)
							lShinP, rShinP = lerp(lShinP, -68, k), lerp(rShinP, -44, k)
							rShoulderOff = V(0, -0.14 * k, -0.32 * k)
							rUpperPitch = lerp(rUpperPitch, 62, k)
							rForePitch = lerp(rForePitch, 12, k)
							lUpperPitch = lerp(lUpperPitch, -36, k)
							lForePitch = lerp(lForePitch, 44, k)
						else
							local rec = easeOutQuad(clamp((cEl - 0.40) / 0.16, 0, 1))
							torsoY -= 0.72 * (1 - rec)
							torsoPitch = lerp(-34, 0, rec)
							rUpperPitch = lerp(62, 42, rec)
						end
					end

					if not cb.lungeDone and cEl >= 0.03 then
						cb.lungeDone = true
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 8, nil)
						if tHRP then
							snapTurnTowards(hrp, tHRP.Position, inFP)
							local d = (tHRP.Position - hrp.Position).Magnitude
							if d > 4.0 and d < 18.0 then
								local stepDir = V(tHRP.Position.X - hrp.Position.X, 0, tHRP.Position.Z - hrp.Position.Z).Unit
								hrp.AssemblyLinearVelocity = stepDir * (cb.step == 4 and 46 or 32)
							end
						else
							hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + hrp.CFrame.LookVector * 16
						end
					end

					local hitFrame = (cb.step == 4 and not cb.uppercut) and 0.19 or 0.07
					if not cb.hitDone and cEl >= hitFrame then
						cb.hitDone = true
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE, hrp.CFrame.LookVector)
						if tChar and tHRP then
							local isFinisher = (cb.step == 4 and not cb.uppercut)
							Core.playSFX("PARRY", isFinisher and 0.78 or 1.06, 0.96)
							if isFinisher then
								Core.playSFX("SHATTER", 0.85, 0.95, "PARRY")
							end
							Core.triggerHitstop(isFinisher and 0.10 or 0.05, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN)
							Core.spawnFlash(tHRP.Position, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN, 1.0, isFinisher and 6.4 or 4.0, 0.22)
							if isFinisher or cb.uppercut then
								Core.spawnRing(tHRP.Position, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN, 1.1, isFinisher and 9.5 or 6.5, 0.26)
								Core.fireDualBeams(hrp.Position + V(0, 0.5, 0), (hrp.Position + tHRP.Position) * 0.5, tHRP.Position, PALETTE.PRIME_CYAN, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.AURA_WHITE, 0.18, 0.30, true, 0.18)
							end
							if cb.uppercut then
								hrp.AssemblyLinearVelocity = V(hrp.AssemblyLinearVelocity.X * 0.4, 58, hrp.AssemblyLinearVelocity.Z * 0.4)
							end
							local kb = cb.uppercut and UPPERCUT_KNOCKBACK or (isFinisher and FINISHER_KNOCKBACK or PUNCH_KNOCKBACK)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, kb)
							Core.addStyleBonus(cb.uppercut and "+UPPERCUT!" or (isFinisher and "+THY END IS NOW!" or "+PRIME PUNCH"), isFinisher and 210 or 85, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN)

							if isFinisher and p2 and not cb.followup and not sa.projectileActive then
								cb.followup = true
								launchSerpentProjectile(C(1.3, 0.8, -2.0))
							end
						elseif cb.step == 4 and not cb.uppercut then
							local slamPos = (hrp.CFrame * C(0.6, -2.5, -2.2)).Position
							Core.playSFX("PARRY", 0.72, 0.9)
							Core.spawnRing(slamPos, PALETTE.PRIME_CYAN, 0.9, 7.5, 0.26)
							Core.spawnFlash(slamPos, PALETTE.JUDGEMENT_GOLD, 0.9, 4.8, 0.20)
						end
					end
				else
					cb.active = false
				end
			end

			-------------------------------------------------------------------
			-- MOVE 2: [R] FULL "THY END IS NOW!" 4-HIT BLITZ / AERIAL OVERHEAD
			-------------------------------------------------------------------
			local bz = STATE.custom.blitz
			if bz.active then
				local bEl = (now - bz.startTime) * speedScale
				if bz.overheadOnly then
					-- Aerial Teleport Overhead Spike
					if bEl < 0.14 then
						if bz.phase == 0 then
							bz.phase = 1
							local tChar, tHRP = findNearestTarget(c, hrp.Position, BLITZ_RANGE, nil)
							bz.targetChar = tChar
							if tHRP then
								local originPos = hrp.Position
								local flat = V(tHRP.Position.X - originPos.X, 0, tHRP.Position.Z - originPos.Z)
								local dir = (flat.Magnitude > 0.1) and flat.Unit or hrp.CFrame.LookVector
								local destPos = tHRP.Position - dir * 3.8 + V(0, 3.6, 0)
								hrp.AssemblyLinearVelocity = Vector3.zero
								hrp.CFrame = C(destPos, V(tHRP.Position.X, destPos.Y, tHRP.Position.Z))
								Core.fireDualBeams(originPos, (originPos + destPos) * 0.5, destPos, PALETTE.PRIME_CYAN, PALETTE.AURA_WHITE, 0.22, 0.14, true, 0.18)
							end
						end
						local k = easeOutQuad(bEl / 0.14)
						torsoPitch = lerp(torsoPitch, 22, k)
						lUpperPitch, rUpperPitch = lerp(lUpperPitch, 158, k), lerp(rUpperPitch, 158, k)
						lForePitch, rForePitch = lerp(lForePitch, 44, k), lerp(rForePitch, 44, k)
					elseif bEl < 0.40 then
						local k = easeOutBack(clamp((bEl - 0.14) / 0.10, 0, 1))
						pelvisPitch = lerp(pelvisPitch, -22, k)
						torsoPitch = lerp(torsoPitch, -36, k)
						lUpperPitch, rUpperPitch = lerp(lUpperPitch, 26, k), lerp(rUpperPitch, 26, k)
						lForePitch, rForePitch = lerp(lForePitch, 18, k), lerp(rForePitch, 18, k)
						if bz.phase == 1 and bEl >= 0.20 then
							bz.phase = 2
							local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 3, nil)
							if tChar and tHRP then
								Core.playSFX("PARRY", 0.80, 1.0)
								Core.playSFX("SHATTER", 0.86, 0.95, "PARRY")
								Core.triggerHitstop(0.09, PALETTE.PRIME_CYAN)
								Core.spawnRing(tHRP.Position, PALETTE.PRIME_CYAN, 1.0, 9.0, 0.26)
								Core.spawnFlash(tHRP.Position, PALETTE.AURA_WHITE, 1.2, 6.2, 0.22)
								Core.applyF3XKnockback(tChar, (tHRP.Position - hrp.Position) + V(0, -18, 0), OVERHEAD_KNOCKBACK)
								Core.addStyleBonus("+OVERHEAD SPIKE", 195, PALETTE.PRIME_CYAN)
							else
								Core.playSFX("PUNCH", 0.85, 0.95, "PARRY")
							end
						end
					else
						bz.active = false
					end
				else
					-- Grounded 4-Punch Teleport Blitz ("THY END IS NOW!")
					local stepDur = 0.16
					local totalDur = 0.82
					if bEl < totalDur then
						local curBeat = math.min(4, math.floor(bEl / stepDur) + 1)
						local localEl = (bEl - (curBeat - 1) * stepDur) / stepDur
						if bz.phase < curBeat then
							bz.phase = curBeat
							local tChar, tHRP = findNearestTarget(c, hrp.Position, BLITZ_RANGE, nil)
							bz.targetChar = tChar
							if tHRP then
								local originPos = hrp.Position
								local flat = V(tHRP.Position.X - originPos.X, 0, tHRP.Position.Z - originPos.Z)
								local dir = (flat.Magnitude > 0.1) and flat.Unit or hrp.CFrame.LookVector
								local sideStep = (curBeat == 1 and -1.6) or (curBeat == 2 and 1.6) or 0
								local rightVec = dir:Cross(V(0, 1, 0))
								local destPos = tHRP.Position - dir * (curBeat == 4 and 4.0 or 4.6) + rightVec * sideStep
								destPos = V(destPos.X, math.max(destPos.Y, originPos.Y - 2), destPos.Z)
								if (destPos - originPos).Magnitude > 5.5 then
									hrp.CFrame = C(destPos, V(tHRP.Position.X, destPos.Y, tHRP.Position.Z))
									Core.fireDualBeams(originPos, (originPos + destPos) * 0.5 + V(0, 1, 0), destPos, PALETTE.PRIME_CYAN, curBeat == 4 and PALETTE.JUDGEMENT_GOLD or PALETTE.AURA_WHITE, 0.22, 0.14, true, 0.16)
								else
									snapTurnTowards(hrp, tHRP.Position, inFP)
								end
								hrp.AssemblyLinearVelocity = Vector3.zero
							else
								hrp.AssemblyLinearVelocity = hrp.CFrame.LookVector * 36
							end

							local isLast = (curBeat == 4)
							Core.playSFX("PUNCH", isLast and 0.78 or (1.02 + curBeat * 0.05), 0.96, "PARRY")
							if isLast then
								Core.playSFX("PARRY", 0.78, 1.0)
								Core.playSFX("SHATTER", 0.84, 0.98, "PARRY")
							end

							local hitChar, hitHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 1.5, nil)
							if hitChar and hitHRP then
								Core.triggerHitstop(isLast and 0.10 or 0.035, isLast and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN)
								Core.spawnFlash(hitHRP.Position, isLast and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN, 0.9, isLast and 7.2 or 4.2, 0.20)
								if isLast then
									Core.spawnRing(hitHRP.Position, PALETTE.JUDGEMENT_GOLD, 1.2, 11.5, 0.30)
									Core.addStyleBonus("+THY END IS NOW!!", 280, PALETTE.JUDGEMENT_GOLD)
									STATE.camShake = math.max(STATE.camShake, 0.72)
								else
									Core.spawnRing(hitHRP.Position, PALETTE.PRIME_CYAN, 0.7, 4.6, 0.16)
								end
								Core.applyF3XKnockback(hitChar, hitHRP.Position - hrp.Position, isLast and FINISHER_KNOCKBACK or PUNCH_KNOCKBACK)
							end
						end

						-- Blitz Animations Per Beat
						local k = easeOutBack(clamp(localEl * 1.4, 0, 1))
						if curBeat == 1 or curBeat == 3 then
							pelvisYaw = lerp(pelvisYaw, -32, k)
							torsoYaw = lerp(torsoYaw, -48, k)
							torsoPitch = lerp(torsoPitch, -14, k)
							lShoulderOff = V(0, 0.04 * k, -0.36 * k)
							lUpperPitch = lerp(lUpperPitch, 96, k)
							lForePitch = lerp(lForePitch, 8, k)
							rUpperPitch = lerp(rUpperPitch, 48, k)
							rForePitch = lerp(rForePitch, 108, k)
						elseif curBeat == 2 then
							pelvisYaw = lerp(pelvisYaw, 34, k)
							torsoYaw = lerp(torsoYaw, 50, k)
							torsoPitch = lerp(torsoPitch, -14, k)
							rShoulderOff = V(0, 0.04 * k, -0.36 * k)
							rUpperPitch = lerp(rUpperPitch, 96, k)
							rForePitch = lerp(rForePitch, 8, k)
							lUpperPitch = lerp(lUpperPitch, 48, k)
							lForePitch = lerp(lForePitch, 108, k)
						else
							-- Beat 4: Heavy Fist-Pin Ground Slam Hold!
							local slamK = easeOutBack(clamp((bEl - 0.48) / 0.12, 0, 1))
							torsoY -= 0.76 * slamK
							pelvisPitch = lerp(pelvisPitch, -24, slamK)
							torsoPitch = lerp(torsoPitch, -36, slamK)
							torsoYaw = lerp(torsoYaw, 34, slamK)
							lThighP, rThighP = lerp(lThighP, 58, slamK), lerp(rThighP, -36, slamK)
							lShinP, rShinP = lerp(lShinP, -74, slamK), lerp(rShinP, -44, slamK)
							rShoulderOff = V(0, -0.14 * slamK, -0.34 * slamK)
							rUpperPitch = lerp(rUpperPitch, 62, slamK)
							rForePitch = lerp(rForePitch, 10, slamK)
							lUpperPitch = lerp(lUpperPitch, -42, slamK)
							lForePitch = lerp(lForePitch, 44, slamK)
						end
					else
						bz.active = false
					end
				end
			end

			-------------------------------------------------------------------
			-- MOVE 3: [E] "PREPARE THYSELF!" (2-KICK SWEEP + HOMING SERPENT)
			-------------------------------------------------------------------
			if sa.kickPhase then
				local sEl = (now - sa.startTime) * speedScale
				if sEl < 0.22 then
					-- Kick 1: Spinning Right Roundhouse Kick
					local k = easeOutBack(clamp(sEl / 0.14, 0, 1))
					torsoY += 0.16 * k
					pelvisPitch = lerp(pelvisPitch, 22, k)
					torsoPitch = lerp(torsoPitch, 12, k)
					pelvisYaw = lerp(pelvisYaw, -56, k)
					torsoYaw = lerp(torsoYaw, -42, k)
					pelvisRoll = lerp(pelvisRoll, 18, k)
					rThighP = lerp(rThighP, 88, k)
					rThighY = lerp(rThighY, -24, k)
					rShinP = lerp(rShinP, -8, k)
					lThighP = lerp(lThighP, -12, k)
					lShinP = lerp(lShinP, -22, k)
					lUpperPitch, rUpperPitch = lerp(lUpperPitch, -26, k), lerp(rUpperPitch, 52, k)
					lUpperRoll, rUpperRoll = lerp(lUpperRoll, 28, k), lerp(rUpperRoll, -22, k)

					if not sa.kickHit1 and sEl >= 0.08 then
						sa.kickHit1 = true
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 3.5, nil)
						if tChar and tHRP then
							snapTurnTowards(hrp, tHRP.Position, inFP)
							hrp.AssemblyLinearVelocity = (tHRP.Position - hrp.Position).Unit * 28
							Core.playSFX("PARRY", 1.04, 0.94)
							Core.spawnFlash(tHRP.Position, PALETTE.PRIME_CYAN, 0.9, 4.6, 0.20)
							Core.fireDualBeams((hrp.CFrame * C(1.2, 0.2, -0.5)).Position, (hrp.Position + tHRP.Position) * 0.5 + V(0, 1.2, 0), tHRP.Position, PALETTE.PRIME_CYAN, PALETTE.AURA_WHITE, 0.18, 0.10, true, 0.16)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, PUNCH_KNOCKBACK)
						end
					end
				elseif sEl < 0.44 then
					-- Kick 2: Counter-Rotating Left High Crescent Kick
					local k = easeOutBack(clamp((sEl - 0.22) / 0.14, 0, 1))
					torsoY += 0.22 * k
					pelvisPitch = lerp(pelvisPitch, 26, k)
					torsoPitch = lerp(torsoPitch, 14, k)
					pelvisYaw = lerp(pelvisYaw, 58, k)
					torsoYaw = lerp(torsoYaw, 44, k)
					pelvisRoll = lerp(pelvisRoll, -18, k)
					lThighP = lerp(lThighP, 96, k)
					lThighY = lerp(lThighY, 22, k)
					lShinP = lerp(lShinP, -6, k)
					rThighP = lerp(rThighP, -14, k)
					rShinP = lerp(rShinP, -20, k)
					rUpperPitch = lerp(rUpperPitch, -38, k)
					rForePitch = lerp(rForePitch, 48, k)
					lUpperPitch = lerp(lUpperPitch, 44, k)

					if not sa.kickHit2 and sEl >= 0.28 then
						sa.kickHit2 = true
						Core.playSFX("PUNCH", 0.98, 0.96, "PARRY")
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 3.5, nil)
						if tChar and tHRP then
							snapTurnTowards(hrp, tHRP.Position, inFP)
							Core.playSFX("PARRY", 1.10, 0.96)
							Core.spawnFlash(tHRP.Position, PALETTE.SERPENT_GOLD, 1.0, 5.0, 0.22)
							Core.fireDualBeams((hrp.CFrame * C(-1.2, 0.4, -0.5)).Position, (hrp.Position + tHRP.Position) * 0.5 + V(0, 1.4, 0), tHRP.Position, PALETTE.SERPENT_GOLD, PALETTE.PRIME_CYAN, 0.20, 0.12, true, 0.18)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, PUNCH_KNOCKBACK)
						end
					end
				elseif sEl < 0.68 then
					-- Step 3: Dramatic Right Arm Whip -> Launch Undulating Golden Serpent
					local w = clamp((sEl - 0.44) / 0.12, 0, 1)
					local k = easeOutBack(clamp((sEl - 0.50) / 0.14, 0, 1))
					pelvisYaw = lerp(pelvisYaw, 38 * (1 - k) - 24 * k, w)
					torsoYaw = lerp(torsoYaw, 52 * (1 - k) - 34 * k, w)
					torsoPitch = lerp(torsoPitch, -14 * k, w)
					rShoulderOff = V(0, 0.08 * k, -0.34 * k)
					rUpperPitch = lerp(rUpperPitch, 102 + camPitch * 0.7, k)
					rUpperYaw = lerp(rUpperYaw, 18, k)
					rForePitch = lerp(rForePitch, 6, k)
					rHandPitch = lerp(rHandPitch, -24, k)
					lUpperPitch = lerp(lUpperPitch, -28, k)
					lForePitch = lerp(lForePitch, 54, k)

					if not sa.launched and sEl >= 0.52 then
						sa.launched = true
						local tChar, tHRP = findNearestTarget(c, hrp.Position, SERPENT_RANGE, nil)
						if tHRP then snapTurnTowards(hrp, tHRP.Position, inFP) end
						launchSerpentProjectile(C(1.25, 0.85, -2.3))
					end
				else
					sa.kickPhase = false
				end
			end

			-- Update 10-Segment Undulating Homing Golden Serpent Projectile
			local segCFs = {}
			if sa.projectileActive then
				local pEl = now - sa.startTime
				local targetHRP = sa.targetChar and Core.getTargetRoot(sa.targetChar)
				if not targetHRP then
					local newChar, newHRP = findNearestTarget(c, sa.pos, 68, nil)
					sa.targetChar = newChar
					targetHRP = newHRP
				end

				-- Tightening homing curve (classic ULTRAKILL Serpent tracking!)
				if targetHRP and targetHRP:IsA("BasePart") then
					local desired = (targetHRP.Position - sa.pos)
					if desired.Magnitude > 0.1 then
						local curDir = sa.vel.Unit
						local turnStrength = clamp(0.06 + pEl * 0.14, 0.06, 0.24)
						local newDir = curDir:Lerp(desired.Unit, turnStrength).Unit
						sa.vel = newDir * (SERPENT_SPEED + clamp(pEl * 16, 0, 26))
					end
				end

				sa.pos = sa.pos + sa.vel * dtStep
				local dir = (sa.vel.Magnitude > 0.01) and sa.vel.Unit or V(0, 0, -1)
				local rightAxis = dir:Cross(V(0, 1, 0))
				if rightAxis.Magnitude < 0.05 then rightAxis = V(1, 0, 0) else rightAxis = rightAxis.Unit end
				local upAxis = rightAxis:Cross(dir).Unit

				-- Record spine path history
				table.insert(sa.history, 1, sa.pos)
				if #sa.history > 36 then table.remove(sa.history) end

				-- Compute sinusoidal slithering CFrames for seg0..seg8
				for i = 0, 8 do
					local histIdx = math.min(#sa.history, 1 + i * 2)
					local nextIdx = math.max(1, histIdx - 1)
					local basePos = sa.history[histIdx] or (sa.pos - dir * (i * 0.85))
					local prevPos = sa.history[nextIdx] or (basePos + dir * 0.85)

					local waveSide = math.sin(pEl * 18 - i * 0.88) * (0.14 + i * 0.055)
					local waveUp   = math.cos(pEl * 14 - i * 0.88) * (0.08 + i * 0.025)
					local segPos = basePos + rightAxis * waveSide + upAxis * waveUp

					local lookPos = (i == 0) and (segPos + dir * 2.0) or (prevPos + rightAxis * (math.sin(pEl * 18 - (i - 1) * 0.88) * (0.14 + (i - 1) * 0.055)))
					if (lookPos - segPos).Magnitude < 0.05 then lookPos = segPos + dir end
					segCFs["seg" .. i] = C(segPos, lookPos)
				end

				sa.trailTick += dtStep
				if sa.trailTick >= 0.14 then
					sa.trailTick = 0
					Core.spawnRing(sa.pos, PALETTE.SERPENT_GOLD, 0.45, 2.2, 0.16)
				end

				local hitDetected = false
				local hitPos = sa.pos
				local hitChar = nil
				for _, hit in ipairs(findTargetsInRadius(c, sa.pos, 6.4)) do
					hitDetected = true
					hitPos = hit.hrp.Position
					hitChar = hit.char
					break
				end

				if hitDetected or pEl >= 1.85 then
					sa.projectileActive = false
					sa.active = false
					Core.playSFX("SHATTER", 0.94, 1.0, "PARRY")
					Core.spawnRing(hitPos, PALETTE.SERPENT_GOLD, 1.2, 10.5, 0.30)
					Core.spawnRing(hitPos, PALETTE.PRIME_CYAN, 0.9, 7.6, 0.24)
					Core.spawnFlash(hitPos, PALETTE.SERPENT_GOLD, 1.5, 7.2, 0.26)
					if hitChar then
						Core.playSFX("PARRY", 1.12, 0.96)
						Core.triggerHitstop(0.09, PALETTE.SERPENT_GOLD)
						Core.fireDualBeams(sa.originPos, (sa.originPos + hitPos) * 0.5 + V(0, 2.5, 0), hitPos, PALETTE.PRIME_CYAN, PALETTE.SERPENT_GOLD, 0.20, 0.44, true, 0.24)
						Core.addStyleBonus("+PREPARE THYSELF!", 210, PALETTE.SERPENT_GOLD)
						Core.applyF3XKnockback(hitChar, sa.vel, SERPENT_KNOCKBACK)
					end
				end
			end

			if STATE.buckets.minosSerpent then
				for _, e in ipairs(STATE.buckets.minosSerpent) do
					local segCF = sa.projectileActive and segCFs[e.key] or PARK_CF
					e.targetCF = (not segCF or segCF == PARK_CF) and PARK_CF or (segCF * e.relCF)
					e.part.CFrame = e.targetCF
				end
			end

			-------------------------------------------------------------------
			-- MOVE 4: [F] "JUDGEMENT!" (CROUCH GLINT -> TELEPORT -> DROPKICK)
			-------------------------------------------------------------------
			local ja = STATE.custom.judgement
			if ja.active then
				local jEl = (now - ja.startTime) * speedScale
				if jEl < 0.30 then
					-- Coiled Predator Sprinter Crouch + Gold Parry Glint
					local k = easeOutQuad(jEl / 0.30)
					local tHRP = ja.targetChar and Core.getTargetRoot(ja.targetChar)
					if tHRP then snapTurnTowards(hrp, tHRP.Position, inFP) end

					torsoY -= 0.92 * k
					pelvisPitch = lerp(pelvisPitch, -34, k)
					torsoPitch = lerp(torsoPitch, -24, k)
					lThighP, rThighP = lerp(lThighP, 68, k), lerp(rThighP, 62, k)
					lShinP, rShinP = lerp(lShinP, -104, k), lerp(rShinP, -98, k)
					lFootP, rFootP = lerp(lFootP, 34, k), lerp(rFootP, 34, k)
					lUpperPitch, rUpperPitch = lerp(lUpperPitch, -58, k), lerp(rUpperPitch, -58, k)
					lUpperRoll, rUpperRoll = lerp(lUpperRoll, 28, k), lerp(rUpperRoll, -28, k)
					lForePitch, rForePitch = lerp(lForePitch, 48, k), lerp(rForePitch, 48, k)

					if not ja.flashDone and jEl >= 0.14 then
						ja.flashDone = true
						Core.spawnRing(hrp.Position + V(0, 0.5, 0), PALETTE.JUDGEMENT_GOLD, 0.8, 6.0, 0.18)
						Core.spawnFlash(hrp.Position + V(0, 0.8, 0), PALETTE.AURA_WHITE, 0.6, 3.8, 0.14)
					end
				elseif jEl < 0.64 then
					-- Instant Teleport to Target + Horizontal Twin-Leg Dropkick
					if not ja.teleported then
						ja.teleported = true
						local originPos = hrp.Position
						local tChar, tHRP = findNearestTarget(c, originPos, JUDGEMENT_RANGE, nil)
						local destPos, faceDir
						if tHRP then
							local toTarget = (tHRP.Position - originPos)
							local flatDir = V(toTarget.X, 0, toTarget.Z)
							faceDir = (flatDir.Magnitude > 0.1) and flatDir.Unit or ja.aimDir
							destPos = tHRP.Position - faceDir * 4.4 + V(0, 1.4, 0)
						else
							local look = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
							local flatLook = V(look.X, 0, look.Z)
							faceDir = (flatLook.Magnitude > 0.1) and flatLook.Unit or hrp.CFrame.LookVector
							destPos = originPos + faceDir * 40 + V(0, 1.2, 0)
						end

						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = C(destPos, destPos + faceDir)
						Core.fireDualBeams(originPos, (originPos + destPos) * 0.5 + V(0, 2.0, 0), destPos, PALETTE.PRIME_CYAN, PALETTE.JUDGEMENT_GOLD, 0.34, 0.42, true, 0.28)
					end

					if jEl < 0.50 then
						-- Horizontal Dropkick Pose (pelvisPitch = +68 leans torso horizontal back, legs straight forward!)
						local k = easeOutBack(clamp((jEl - 0.30) / 0.10, 0, 1))
						torsoY += 0.24 * k
						pelvisPitch = lerp(pelvisPitch, 68, k)
						torsoPitch = lerp(torsoPitch, 14, k)
						pelvisYaw, torsoYaw = 0, 0
						lThighP, rThighP = lerp(lThighP, 20, k), lerp(rThighP, 24, k)
						lShinP, rShinP = lerp(lShinP, -4, k), lerp(rShinP, -4, k)
						lFootP, rFootP = lerp(lFootP, -18, k), lerp(rFootP, -18, k)
						lUpperPitch, rUpperPitch = lerp(lUpperPitch, -44, k), lerp(rUpperPitch, -44, k)
						lUpperRoll, rUpperRoll = lerp(lUpperRoll, 42, k), lerp(rUpperRoll, -42, k)
						lForePitch, rForePitch = lerp(lForePitch, 18, k), lerp(rForePitch, 18, k)
					else
						-- Stylish Backflip / Recovery Pose
						local rec = easeOutQuad(clamp((jEl - 0.50) / 0.14, 0, 1))
						pelvisPitch = lerp(68, 0, rec)
						torsoPitch = lerp(14, -8, rec)
						lThighP, rThighP = lerp(20, 44, rec), lerp(24, -18, rec)
						lShinP, rShinP = lerp(-4, -56, rec), lerp(-4, -16, rec)
					end

					if not ja.exploded and jEl >= 0.33 then
						ja.exploded = true
						local blastPos = (hrp.CFrame * C(0, 0, -2.8)).Position
						Core.playSFX("PARRY", 0.78, 1.0)
						Core.playSFX("SHATTER", 0.74, 1.0, "PARRY")
						Core.triggerHitstop(0.12, PALETTE.JUDGEMENT_GOLD)
						Core.spawnRing(blastPos, PALETTE.JUDGEMENT_GOLD, 2.0, 16.5, 0.36)
						Core.spawnRing(blastPos + V(0, 0.4, 0), PALETTE.PRIME_CYAN, 1.4, 12.0, 0.30)
						Core.spawnFlash(blastPos, PALETTE.JUDGEMENT_GOLD, 1.8, 9.2, 0.30)
						STATE.camShake = math.max(STATE.camShake, 0.95)
						STATE.fovKick = math.max(STATE.fovKick, 14)

						local hits = findTargetsInRadius(c, blastPos, 15.0)
						if #hits > 0 then
							Core.addStyleBonus("+JUDGEMENT!!", 320, PALETTE.JUDGEMENT_GOLD)
							for _, hit in ipairs(hits) do
								Core.applyF3XKnockback(hit.char, hit.hrp.Position - hrp.Position + hrp.CFrame.LookVector * 4, JUDGEMENT_KNOCKBACK)
							end
						else
							Core.addStyleBonus("+JUDGEMENT", 120, PALETTE.PRIME_CYAN)
						end

						if p2 and not sa.projectileActive then
							launchSerpentProjectile(C(1.2, 0.9, -2.0))
						end
					end
				else
					ja.active = false
				end
			end

			-------------------------------------------------------------------
			-- BUILD FINAL HIERARCHICAL CFRAMES & APPLY TO BUCKETS
			-------------------------------------------------------------------
			local rootCenterCF = hrp.CFrame * C(0, torsoY, 0)
			-- Pelvis sits at MINOS_PELVIS_OFFSET (-0.80) below root; orient pelvis first so hips drive the spine!
			local pelvisBaseCF = rootCenterCF * C(0, MINOS_PELVIS_OFFSET, 0) * angles(pelvisPitch, pelvisYaw, pelvisRoll)
			local abdomenCF = pelvisBaseCF * C(0, MINOS_ABDOMEN_OFFSET - MINOS_PELVIS_OFFSET, 0) * angles(torsoPitch * 0.45, torsoYaw * 0.45, torsoRoll * 0.45)
			local chestCF = abdomenCF * C(0, MINOS_CHEST_OFFSET - MINOS_ABDOMEN_OFFSET, 0) * angles(torsoPitch * 0.55, torsoYaw * 0.55, torsoRoll * 0.55)
			local torsoCF = abdomenCF

			local headPitch = camPitch * 0.85 - (pelvisPitch + torsoPitch) * 0.42 + breathe * 2.2 * idleWeight
			local headYaw = camYawLocal * 0.78 - (pelvisYaw + torsoYaw) * 0.32
			local headCF = chestCF * C(0, 1.06, -0.04) * angles(headPitch, headYaw, -(pelvisRoll + torsoRoll) * 0.35)

			local shoulderL = chestCF * C(-1.06, 0.24, 0) * C(lShoulderOff)
			local shoulderR = chestCF * C(1.06, 0.24, 0) * C(rShoulderOff)
			if STATE.fpArms and cam then
				shoulderL = cam.CFrame * C(-1.05, -0.78, -0.82) * angles(-camPitch * 0.2, 0, 0) * C(lShoulderOff)
				shoulderR = cam.CFrame * C(1.02, -0.78, -0.85) * angles(-camPitch * 0.2, 0, 0) * C(rShoulderOff)
			end

			local lUpperCF = shoulderL * angles(lUpperPitch, lUpperYaw, lUpperRoll)
			local lForeCF = lUpperCF * C(0, -MINOS_UPPER_ARM_LEN, 0) * angles(lForePitch, 0, 0)
			local lHandCF = lForeCF * C(0, -MINOS_FOREARM_LEN, 0) * angles(lHandPitch, lHandYaw, lHandRoll)

			local rUpperCF = shoulderR * angles(rUpperPitch, rUpperYaw, rUpperRoll)
			local rForeCF = rUpperCF * C(0, -MINOS_UPPER_ARM_LEN, 0) * angles(rForePitch, 0, 0)
			local rHandCF = rForeCF * C(0, -MINOS_FOREARM_LEN, 0) * angles(rHandPitch, rHandYaw, rHandRoll)

			local hipL = pelvisBaseCF * C(-0.46, MINOS_HIP_Y, 0)
			local hipR = pelvisBaseCF * C(0.46, MINOS_HIP_Y, 0)
			local lThighCF = hipL * angles(lThighP, lThighY, -4)
			local rThighCF = hipR * angles(rThighP, rThighY, 4)
			local lShinCF = lThighCF * C(0, -MINOS_THIGH_LEN, 0) * angles(lShinP, 0, 0)
			local rShinCF = rThighCF * C(0, -MINOS_THIGH_LEN, 0) * angles(rShinP, 0, 0)
			local lFootCF = lShinCF * C(0, -MINOS_SHIN_LEN, 0) * angles(lFootP, 0, 0)
			local rFootCF = rShinCF * C(0, -MINOS_SHIN_LEN, 0) * angles(rFootP, 0, 0)

			local function applyBucket(bucketName, parentMap, hideInFP)
				local list = STATE.buckets[bucketName]
				if not list then return end
				for _, e in ipairs(list) do
					local baseCF = e.key and parentMap[e.key] or parentMap
					if baseCF == PARK_CF then
						e.targetCF = PARK_CF
					elseif baseCF then
						e.targetCF = baseCF * e.relCF
					end
					e.part.CFrame = e.targetCF
					e.part.LocalTransparencyModifier = (hideInFP and inFP) and 1 or 0
				end
			end

			applyBucket("minosHead", headCF, true)
			applyBucket("minosBody", { chest = chestCF, abdomen = abdomenCF, pelvis = pelvisBaseCF }, true)
			applyBucket("minosUpperArm", { lUpperArm = lUpperCF, rUpperArm = rUpperCF }, not STATE.fpArms)
			applyBucket("minosForearm", { lForearm = lForeCF, rForearm = rForeCF }, not STATE.fpArms)
			applyBucket("minosHand", { lHand = lHandCF, rHand = rHandCF }, not STATE.fpArms)
			applyBucket("minosThigh", { lThigh = lThighCF, rThigh = rThighCF }, true)
			applyBucket("minosShin", { lShin = lShinCF, rShin = rShinCF }, true)
			applyBucket("minosFoot", { lFoot = lFootCF, rFoot = rFootCF }, true)

			-------------------------------------------------------------------
			-- PHASE 2 FIERY PRIME SOUL AURA ("WEAK.") + ACTION FLARE
			-------------------------------------------------------------------
			local showAura = p2 or STATE.dash.active or ja.active or bz.active or STATE.slam.active
			local auraMap = {}
			if showAura then
				local anchors = {
					chestCF, chestCF,
					lUpperCF, rUpperCF,
					lForeCF * C(0, -0.5, 0), rForeCF * C(0, -0.5, 0),
					headCF * C(0, 0.7, 0), headCF * C(0, 0.7, 0),
					lThighCF * C(0, -0.5, 0), rThighCF * C(0, -0.5, 0),
					abdomenCF, pelvisBaseCF,
				}
				for i = 1, 12 do
					local anchor = anchors[i] or chestCF
					local ph = t * 9.5 + i * 1.17
					local orbitR = (i <= 2 or i >= 11) and 0.92 or 0.42
					local ox = math.cos(ph) * orbitR
					local oz = math.sin(ph) * orbitR
					local oy = (math.sin(t * 14 + i * 1.9) * 0.24) + ((t * 2.2 + i * 0.37) % 0.65) - 0.15
					auraMap["aura" .. i] = anchor * C(ox, oy, oz) * angles(math.sin(ph) * 22, -math.deg(ph), math.cos(ph) * 18)
				end
			else
				for i = 1, 12 do
					auraMap["aura" .. i] = PARK_CF
				end
			end
			applyBucket("minosAura", auraMap, true)

			-------------------------------------------------------------------
			-- HUD STATUS & CORE CFRAME EXPORT
			-------------------------------------------------------------------
			local cdMult = p2 and 0.72 or 1.0
			local judgeCharge = clamp((now - ja.lastUsed) / (JUDGEMENT_COOLDOWN * cdMult), 0, 1)
			local serpentCharge = clamp((now - sa.lastUsed) / (SERPENT_COOLDOWN * cdMult), 0, 1)
			local hudCharge = math.min(judgeCharge, serpentCharge)

			local titleText = p2 and "WEAK. // PHASE II" or "JUDGEMENT // SERPENT"
			local titleColor = p2 and PALETTE.AURA_WHITE or PALETTE.PRIME_CYAN
			if ja.active then
				titleText = "!! JUDGEMENT !!"
				titleColor = PALETTE.JUDGEMENT_GOLD
			elseif bz.active then
				titleText = bz.overheadOnly and "USELESS! // OVERHEAD" or "THY END IS NOW!"
				titleColor = PALETTE.JUDGEMENT_GOLD
			elseif sa.kickPhase then
				titleText = "PREPARE THYSELF!"
				titleColor = PALETTE.SERPENT_GOLD
			elseif STATE.slam.active then
				titleText = (STATE.custom.slamKind == "DIE") and "!! DIE !!" or "!! CRUSH !!"
				titleColor = PALETTE.PRIME_CYAN
			elseif cb.active then
				titleText = cb.uppercut and "UPPERCUT!" or (cb.step == 4 and "THY END IS NOW!" or "PRIME COMBO")
				titleColor = cb.step == 4 and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN
			end

			local hudStatus = {
				weaponTitle = titleText,
				weaponColor = titleColor,
				chargeFrac = hudCharge,
				pipColor = p2 and PALETTE.PRIME_CYAN or PALETTE.SERPENT_GOLD,
				pipDimColor = Color3.fromRGB(115, 95, 30),
			}

			local cfs = {
				["Head"] = headCF,
				["Torso"] = torsoCF,
				["Left Arm"] = lForeCF,
				["Right Arm"] = rForeCF,
				["Left Leg"] = lShinCF,
				["Right Leg"] = rShinCF,
			}

			return hudStatus, cfs
		end,
	})
end