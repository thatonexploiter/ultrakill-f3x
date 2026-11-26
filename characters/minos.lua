-- ULTRAKILL MINOS PRIME MODULE (KING OF LUST // PRIME SOUL)
-- Carregado dinamicamente pelo loader.lua recebendo Core

return function(Core)
	local UserInputService = game:GetService("UserInputService")

	local C, V = Core.C, Core.V
	local ID_CF, PARK_CF = Core.ID_CF, Core.PARK_CF
	local clamp, lerp, easeOutQuad, easeOutBack = Core.clamp, Core.lerp, Core.easeOutQuad, Core.easeOutBack
	local angles, mirrorRelCF = Core.angles, Core.mirrorRelCF

	local PALETTE = {
		FLESH_GLASS   = Color3.fromRGB(165, 224, 255), -- Translucent Prime Soul outer shell
		FLESH_INNER   = Color3.fromRGB(205, 240, 255), -- Sculpted inner muscle definition
		VEIN_CYAN     = Color3.fromRGB(85, 225, 255),  -- Glowing circulatory veins & spine
		PRIME_CYAN    = Color3.fromRGB(115, 238, 255), -- Shockwave / aura cyan
		HEART_RED     = Color3.fromRGB(215, 24, 38),   -- Exposed Prime Heart
		HEART_CORE    = Color3.fromRGB(255, 95, 110),  -- Heart inner glow
		FACE_VOID     = Color3.fromRGB(7, 7, 10),      -- Hollow pitch-black face cavity
		CROWN_ICE     = Color3.fromRGB(185, 234, 255), -- Jagged rectangular prism crown
		SNAKE_SHELL   = Color3.fromRGB(220, 242, 255), -- Coiled forearm serpents
		SNAKE_BELLY   = Color3.fromRGB(100, 228, 255), -- Serpent glowing underbelly/eyes
		SERPENT_GOLD  = Color3.fromRGB(255, 212, 60),  -- Homing golden Serpent projectile
		JUDGEMENT_GOLD = Color3.fromRGB(255, 235, 130), -- Parry-flash & Judgement explosion
	}

	-- Exact Proportions Aligned to V1/Core Rig Grounding
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
	local SERPENT_COOLDOWN = 0.95
	local SERPENT_RANGE = 95
	local SERPENT_SPEED = 86
	local JUDGEMENT_COOLDOWN = 1.45
	local JUDGEMENT_RANGE = 76
	local COMBO_COOLDOWN = 0.24
	local COMBO_RANGE = 11.5

	local PUNCH_KNOCKBACK = { speed = 56, up = 22, spin = 9.0 }
	local UPPERCUT_KNOCKBACK = { speed = 42, up = 64, spin = 12.0 }
	local FINISHER_KNOCKBACK = { speed = 88, up = 34, spin = 15.0 }
	local SERPENT_KNOCKBACK = { speed = 78, up = 30, spin = 13.5 }
	local JUDGEMENT_KNOCKBACK = { speed = 108, up = 48, spin = 18.0 }
	local CRUSH_KNOCKBACK = { speed = 76, up = 44, spin = 14.0 }

	-------------------------------------------------------------------
	-- SCULPTED MINOS PRIME BLUEPRINTS (TRANSLUCENT SHELL + RED HEART + VEINS + CROWN + SNAKES)
	-------------------------------------------------------------------
	local function getMinosHeadSpecs()
		local specs = {
			-- Neck + sternocleidomastoid tendons
			{ partType = "Cylinder", size = V(0.42, 0.34, 0.34), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.32, relCF = C(0, -0.36, 0.06) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.10, 0.34, 0.10), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,  trans = 0.05, relCF = C(-0.12, -0.34, 0.02) * angles(0, 0, -14) },
			{ partType = "Normal",   size = V(0.10, 0.34, 0.10), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,  trans = 0.05, relCF = C(0.12, -0.34, 0.02) * angles(0, 0, 14) },

			-- Hollow pitch-black face void (deep recessed core)
			{ partType = "Cylinder", size = V(0.56, 0.62, 0.62), color = PALETTE.FACE_VOID, mat = Enum.Material.SmoothPlastic, trans = 0, relCF = C(0, 0.03, -0.14) * angles(0, 90, 0) },
			{ partType = "Normal",   size = V(0.56, 0.64, 0.36), color = PALETTE.FACE_VOID, mat = Enum.Material.SmoothPlastic, trans = 0, relCF = C(0, 0.03, -0.22) },

			-- Translucent skull sides, jaw, brow & solid rear cranium framing the face hole
			{ partType = "Normal",   size = V(0.84, 0.78, 0.44), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.30, relCF = C(0, 0.05, 0.22) },
			{ partType = "Normal",   size = V(0.16, 0.76, 0.66), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(-0.36, 0.04, -0.06) },
			{ partType = "Normal",   size = V(0.16, 0.76, 0.66), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0.36, 0.04, -0.06) },
			{ partType = "Normal",   size = V(0.86, 0.16, 0.68), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.20, relCF = C(0, 0.38, -0.06) },
			{ partType = "Wedge",    size = V(0.74, 0.18, 0.64), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.28, relCF = C(0, -0.32, -0.08) * angles(180, 0, 0) },

			-- Glowing neural/spine core inside skull
			{ partType = "Ball",     size = V(0.30, 0.34, 0.30), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.08, relCF = C(0, 0.08, 0.14), light = true },

			-- Jagged Crown of Minos (base collar + 7 uneven rectangular prisms)
			{ partType = "Normal",   size = V(0.88, 0.16, 0.88), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.24, relCF = C(0, 0.48, 0.04) },
			{ partType = "Normal",   size = V(0.15, 0.78, 0.17), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(0.00, 0.86, -0.34) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.96, 0.16), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(-0.30, 0.94, -0.22) * angles(-4, 18, 5) },
			{ partType = "Normal",   size = V(0.16, 0.88, 0.16), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(0.30, 0.90, -0.22) * angles(-4, -18, -5) },
			{ partType = "Normal",   size = V(0.17, 0.66, 0.18), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(-0.36, 0.80, 0.14) * angles(4, 0, 7) },
			{ partType = "Normal",   size = V(0.17, 0.72, 0.18), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(0.36, 0.83, 0.14) * angles(4, 0, -7) },
			{ partType = "Normal",   size = V(0.18, 1.02, 0.18), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(-0.16, 0.96, 0.34) * angles(7, 0, 3) },
			{ partType = "Normal",   size = V(0.18, 0.84, 0.18), color = PALETTE.CROWN_ICE, mat = Enum.Material.Glass, trans = 0.22, relCF = C(0.18, 0.88, 0.34) * angles(7, 0, -3) },
		}
		return specs
	end

	local function getMinosChestSpecs()
		return {
			-- Outer translucent muscular torso + contoured pec/trap wedges
			{ partType = "Normal",   size = V(1.78, 0.86, 0.78), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.36, relCF = C(0, 0.12, 0.02) },
			{ partType = "Wedge",    size = V(0.80, 0.60, 0.26), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.44, 0.18, -0.38) * angles(0, 10, 180) },
			{ partType = "Wedge",    size = V(0.80, 0.60, 0.26), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.44, 0.18, -0.38) * angles(0, -10, 180) },
			{ partType = "Wedge",    size = V(0.42, 0.34, 0.74), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(-0.56, 0.60, 0.04) * angles(0, 0, -22) },
			{ partType = "Wedge",    size = V(0.42, 0.34, 0.74), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.28, relCF = C(0.56, 0.60, 0.04) * angles(0, 0, 22) },
			-- Clavicle & shoulder deltoid musculature
			{ partType = "Ball",     size = V(0.64, 0.64, 0.64), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(-1.02, 0.24, 0.02) },
			{ partType = "Ball",     size = V(0.64, 0.64, 0.64), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(1.02, 0.24, 0.02) },

			-- Oversized Exposed Red Prime Heart + Inner Pulse Core + Aorta
			{ partType = "Ball",     size = V(0.46, 0.54, 0.40), color = PALETTE.HEART_RED,  mat = Enum.Material.Neon, trans = 0.04, relCF = C(-0.18, 0.14, -0.10), light = true },
			{ partType = "Ball",     size = V(0.28, 0.34, 0.26), color = PALETTE.HEART_CORE, mat = Enum.Material.Neon, trans = 0.00, relCF = C(-0.18, 0.14, -0.14) },
			{ partType = "Cylinder", size = V(0.26, 0.14, 0.14), color = PALETTE.HEART_RED,  mat = Enum.Material.Neon, trans = 0.02, relCF = C(-0.08, 0.42, -0.06) * angles(0, 0, 72) },

			-- Glowing Circulatory System (veins branching across ribcage + glowing spine)
			{ partType = "Normal",   size = V(0.08, 0.74, 0.08), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.04, 0.06, -0.10) * angles(0, 0, -14), light = true },
			{ partType = "Normal",   size = V(0.07, 0.60, 0.07), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.36, 0.18, -0.12) * angles(0, 0, 38) },
			{ partType = "Normal",   size = V(0.07, 0.56, 0.07), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.05, relCF = C(-0.48, 0.18, -0.10) * angles(0, 0, -40) },
			{ partType = "Normal",   size = V(0.06, 0.44, 0.06), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.68, 0.24, -0.04) * angles(0, 0, 56) },
			{ partType = "Cylinder", size = V(0.88, 0.22, 0.22), color = PALETTE.VEIN_CYAN, mat = Enum.Material.Neon, trans = 0.08, relCF = C(0, 0.08, 0.16) * angles(0, 0, 90) },
		}
	end

	local function getMinosAbdomenSpecs()
		return {
			{ partType = "Normal",   size = V(1.18, 0.78, 0.60), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.36, relCF = ID_CF },
			-- Sculpted 6-pack abs + central glowing artery + iliac veins
			{ partType = "Normal",   size = V(0.40, 0.18, 0.12), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.22, 0.18, -0.28) },
			{ partType = "Normal",   size = V(0.40, 0.18, 0.12), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.22, 0.18, -0.28) },
			{ partType = "Normal",   size = V(0.36, 0.18, 0.12), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(-0.20, -0.06, -0.28) },
			{ partType = "Normal",   size = V(0.36, 0.18, 0.12), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0.20, -0.06, -0.28) },
			{ partType = "Normal",   size = V(0.10, 0.74, 0.10), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(0, 0, -0.08) },
			{ partType = "Normal",   size = V(0.07, 0.70, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(-0.22, -0.02, -0.10) * angles(0, 0, 12) },
			{ partType = "Normal",   size = V(0.07, 0.70, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.22, -0.02, -0.10) * angles(0, 0, -12) },
		}
	end

	local function getMinosPelvisSpecs()
		return {
			{ partType = "Normal",   size = V(1.26, 0.40, 0.62), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(0, -0.02, 0) },
			{ partType = "Wedge",    size = V(0.62, 0.34, 0.32), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.06, -0.24) * angles(180, 0, 0) },
			{ partType = "Cylinder", size = V(1.06, 0.22, 0.22), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.08, relCF = C(0, -0.12, 0) },
		}
	end

	local function getMinosUpperArmSpecs()
		return {
			{ partType = "Normal", size = V(0.48, 0.96, 0.48), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(0, -0.50, 0) },
			{ partType = "Ball",   size = V(0.46, 0.62, 0.46), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.46, -0.04) },
			{ partType = "Normal", size = V(0.08, 0.88, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.04, -0.50, -0.08) },
			{ partType = "Ball",   size = V(0.32, 0.32, 0.32), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.32, relCF = C(0, -MINOS_UPPER_ARM_LEN, 0) },
		}
	end

	local function getMinosForearmSpecs(side)
		-- Coiled Twin Forearm Serpent wrapped tightly around each forearm!
		return {
			{ partType = "Normal", size = V(0.42, 0.94, 0.42), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(0, -0.48, 0) },
			{ partType = "Normal", size = V(0.07, 0.82, 0.07), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon,  trans = 0.05, relCF = C(0, -0.48, -0.05) },
			-- 4 diagonal serpent coils wrapping the forearm
			{ partType = "Normal", size = V(0.54, 0.14, 0.54), color = PALETTE.SNAKE_SHELL, mat = Enum.Material.SmoothPlastic, trans = 0.08, relCF = C(0, -0.20, 0) * angles(12, 0, side * 14) },
			{ partType = "Normal", size = V(0.56, 0.14, 0.56), color = PALETTE.SNAKE_BELLY, mat = Enum.Material.Neon,          trans = 0.10, relCF = C(0, -0.40, 0) * angles(-10, 0, side * -14) },
			{ partType = "Normal", size = V(0.56, 0.15, 0.56), color = PALETTE.SNAKE_SHELL, mat = Enum.Material.SmoothPlastic, trans = 0.08, relCF = C(0, -0.60, 0) * angles(12, 0, side * 14) },
			{ partType = "Normal", size = V(0.54, 0.14, 0.54), color = PALETTE.SNAKE_BELLY, mat = Enum.Material.Neon,          trans = 0.10, relCF = C(0, -0.80, 0) * angles(-10, 0, side * -14) },
			-- Serpent head perched near the wrist facing forward
			{ partType = "Wedge",  size = V(0.24, 0.22, 0.44), color = PALETTE.SNAKE_SHELL, mat = Enum.Material.SmoothPlastic, trans = 0.05, relCF = C(side * 0.24, -0.88, -0.18) * angles(68, side * 14, 0) },
			{ partType = "Normal", size = V(0.26, 0.08, 0.10), color = PALETTE.SERPENT_GOLD, mat = Enum.Material.Neon,         trans = 0.00, relCF = C(side * 0.26, -0.84, -0.26) * angles(68, side * 14, 0), light = true },
		}
	end

	local function getMinosHandSpecs()
		return {
			{ partType = "Normal", size = V(0.38, 0.36, 0.42), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.30, relCF = C(0, -0.18, 0) },
			{ partType = "Normal", size = V(0.42, 0.18, 0.44), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.22, relCF = C(0, -0.34, -0.02) },
			{ partType = "Normal", size = V(0.14, 0.14, 0.14), color = PALETTE.PRIME_CYAN,  mat = Enum.Material.Neon, trans = 0.05, relCF = C(0, -0.32, -0.18) },
		}
	end

	local function getMinosThighSpecs()
		return {
			{ partType = "Ball",     size = V(0.44, 0.44, 0.44), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = ID_CF },
			{ partType = "Normal",   size = V(0.60, 1.04, 0.60), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(0, -0.58, 0) },
			{ partType = "Wedge",    size = V(0.50, 0.56, 0.24), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.44, -0.28) * angles(6, 0, 0) },
			{ partType = "Normal",   size = V(0.09, 0.98, 0.09), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(0.06, -0.58, -0.08) },
			{ partType = "Cylinder", size = V(0.36, 0.28, 0.28), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.32, relCF = C(0, -MINOS_THIGH_LEN, 0) },
		}
	end

	local function getMinosShinSpecs()
		return {
			{ partType = "Ball",     size = V(0.34, 0.34, 0.34), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = ID_CF },
			{ partType = "Normal",   size = V(0.48, 1.04, 0.48), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.34, relCF = C(0, -0.58, 0) },
			{ partType = "Ball",     size = V(0.46, 0.58, 0.42), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.26, relCF = C(0, -0.42, 0.14) },
			{ partType = "Normal",   size = V(0.08, 0.94, 0.08), color = PALETTE.VEIN_CYAN,   mat = Enum.Material.Neon, trans = 0.05, relCF = C(0, -0.58, -0.06) },
			{ partType = "Cylinder", size = V(0.28, 0.24, 0.24), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.32, relCF = C(0, -MINOS_SHIN_LEN, 0) },
		}
	end

	local function getMinosFootSpecs()
		return {
			{ partType = "Normal", size = V(0.38, 0.18, 0.50), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.30, relCF = C(0, -0.10, -0.06) },
			{ partType = "Normal", size = V(0.42, 0.16, 0.72), color = PALETTE.FLESH_GLASS, mat = Enum.Material.Glass, trans = 0.30, relCF = C(0, -0.25, -0.20) },
			{ partType = "Wedge",  size = V(0.38, 0.16, 0.32), color = PALETTE.FLESH_INNER, mat = Enum.Material.SmoothPlastic, trans = 0.24, relCF = C(0, -0.25, -0.56) },
		}
	end

	local function getSerpentProjectileSpecs()
		return {
			{ partType = "Wedge",  size = V(0.48, 0.42, 0.92), color = PALETTE.SERPENT_GOLD,  mat = Enum.Material.Neon, trans = 0, relCF = C(0, 0.08, -0.55) * angles(14, 0, 0), light = true },
			{ partType = "Normal", size = V(0.42, 0.36, 1.15), color = PALETTE.SERPENT_GOLD,  mat = Enum.Material.Neon, trans = 0, relCF = C(0, 0, 0.35) },
			{ partType = "Normal", size = V(0.30, 0.26, 1.05), color = PALETTE.PRIME_CYAN,    mat = Enum.Material.Neon, trans = 0.15, relCF = C(0, -0.04, 1.35) },
			{ partType = "Wedge",  size = V(0.22, 0.22, 0.85), color = PALETTE.JUDGEMENT_GOLD, mat = Enum.Material.Neon, trans = 0.20, relCF = C(0, -0.04, 2.20) * angles(0, 180, 0) },
		}
	end

	-------------------------------------------------------------------
	-- TARGETING HELPERS
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
					if not forwardLook or diff.Unit:Dot(forwardLook) > -0.35 or d < 6.0 then
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

	-------------------------------------------------------------------
	-- EXPORTED MODULE FOR CORE
	-------------------------------------------------------------------
	Core.start({
		id = "minos",
		name = "MINOS PRIME",
		config = {
			RENDER_NAME = "F3X_Minos_Reanim",
			HUD_RENDER_NAME = "F3X_Minos_3DHUD",
			SCALE = 1.06,
			SOLE_DEPTH = MINOS_SOLE_DEPTH,

			-- Aggressive, fast Prime Soul movement tuning
			WALK_SPEED = 20,
			SPRINT_SPEED = 40,
			JUMP_POWER = 60,
			AIR_GRAVITY_CANCEL = 0.28,
			GLIDE_GRAVITY_CANCEL = 0.52,
			GLIDE_MAX_FALL = 20,
			AIR_STRAFE_ACCEL = 62,
			AIR_DRAG = 0.22,
			SLAM_STORAGE_JUMP = 114,

			HUD_UNIT_HEADER = "P-1 // KING OF LUST",
			HUD_WEAPON_TITLE = "JUDGEMENT // SERPENT",
			HUD_WEAPON_COLOR = PALETTE.PRIME_CYAN,
			HUD_KEY_HINT = "[LMB] BOXING  [E] SERPENT  [F] JUDGEMENT  [C] DIE/CRUSH",
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
			}
			STATE.custom.judgement = {
				active = false,
				lastUsed = 0,
				startTime = 0,
				teleported = false,
				exploded = false,
				flashDone = false,
				destCF = nil,
			}
			STATE.custom.combo = {
				active = false,
				step = 0,
				lastUsed = 0,
				startTime = 0,
				hitDone = false,
				uppercut = false,
			}
			STATE.custom.wasSlamming = false

			-- Bind LMB Boxing Combo ("THY END IS NOW!") cleanly, self-disconnecting when unloaded
			if STATE.custom.lmbConn then
				pcall(function() STATE.custom.lmbConn:Disconnect() end)
			end
			STATE.custom.lmbConn = UserInputService.InputBegan:Connect(function(input, gp)
				local curState = Core.getState()
				if curState ~= STATE or not curState.alive then
					if STATE.custom.lmbConn then
						pcall(function() STATE.custom.lmbConn:Disconnect() end)
						STATE.custom.lmbConn = nil
					end
					return
				end
				if gp or curState.isSettingUp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local cb = curState.custom.combo
					local now = os.clock()
					if curState.custom.judgement.active then return end
					if cb.active and (now - cb.startTime) < 0.16 then return end
					if (now - cb.lastUsed) < COMBO_COOLDOWN then return end

					local resetChain = (now - cb.lastUsed) > 1.05
					cb.step = resetChain and 1 or ((cb.step % 4) + 1)
					cb.active = true
					cb.lastUsed = now
					cb.startTime = now
					cb.hitDone = false
					cb.uppercut = false

					-- Cancel into Uppercut if target is airborne mid-combo
					local c = Core.getChar()
					local hrp = c and c:FindFirstChild("HumanoidRootPart")
					if hrp and cb.step >= 2 then
						local _, tHRP = findNearestTarget(c, hrp, COMBO_RANGE + 3, hrp.CFrame.LookVector)
						if tHRP and (tHRP.Position.Y - hrp.Position.Y) > 4.2 then
							cb.uppercut = true
						end
					end

					Core.playSFX("PUNCH", cb.step == 4 and 0.85 or (0.98 + cb.step * 0.06), 0.9, "PARRY")
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
						key = key,
						partType = sp.partType,
						relCF = sp.relCF,
						origCF = parentCF * sp.relCF,
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

			addMinos("minosUpperArm", getMinosUpperArmSpecs(), shoulderL, "lUpperArm")
			addMinos("minosUpperArm", getMinosUpperArmSpecs(), shoulderR, "rUpperArm")
			addMinos("minosForearm", getMinosForearmSpecs(-1), elbowL, "lForearm")
			addMinos("minosForearm", getMinosForearmSpecs(1), elbowR, "rForearm")
			addMinos("minosHand", getMinosHandSpecs(), wristL, "lHand")
			addMinos("minosHand", getMinosHandSpecs(), wristR, "rHand")

			local hipL = pelvisCF * C(-0.46, MINOS_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, MINOS_HIP_Y, 0)
			local kneeL, kneeR = hipL * C(0, -MINOS_THIGH_LEN, 0), hipR * C(0, -MINOS_THIGH_LEN, 0)
			local ankleL, ankleR = kneeL * C(0, -MINOS_SHIN_LEN, 0), kneeR * C(0, -MINOS_SHIN_LEN, 0)

			addMinos("minosThigh", getMinosThighSpecs(), hipL, "lThigh")
			addMinos("minosThigh", getMinosThighSpecs(), hipR, "rThigh")
			addMinos("minosShin", getMinosShinSpecs(), kneeL, "lShin")
			addMinos("minosShin", getMinosShinSpecs(), kneeR, "rShin")
			addMinos("minosFoot", getMinosFootSpecs(), ankleL, "lFoot")
			addMinos("minosFoot", getMinosFootSpecs(), ankleR, "rFoot")

			-- Homing Golden Serpent Projectile Bucket (parked when inactive)
			for _, sp in ipairs(getSerpentProjectileSpecs()) do
				specs[#specs + 1] = {
					kind = "minosSerpent",
					partType = sp.partType,
					relCF = sp.relCF,
					origCF = PARK_CF,
					origSize = sp.size,
					origColor = sp.color,
					origMaterial = sp.mat,
					origTrans = sp.trans or 0,
					origReflectance = 0,
					light = sp.light,
				}
			end

			return specs
		end,

		-- [E] / SERPENT: "PREPARE THYSELF!" (2-Kick Sweep + Homing Serpent Throw)
		onPrimary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local sa = STATE.custom.serpent
			local now = os.clock()
			if sa.kickPhase or (now - sa.lastUsed) < SERPENT_COOLDOWN then return end
			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			sa.active = true
			sa.kickPhase = true
			sa.lastUsed = now
			sa.startTime = now
			sa.kickHit1 = false
			sa.kickHit2 = false
			sa.launched = false

			Core.playSFX("PUNCH", 0.90, 0.95, "PARRY")
		end,

		-- [F] / JUDGEMENT: "JUDGEMENT!" (Parry-Flash Telegraph -> Teleport Dropkick Explosion)
		onSecondary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local ja = STATE.custom.judgement
			local now = os.clock()
			if ja.active or (now - ja.lastUsed) < JUDGEMENT_COOLDOWN then return end
			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			ja.active = true
			ja.lastUsed = now
			ja.startTime = now
			ja.teleported = false
			ja.exploded = false
			ja.flashDone = false
			ja.destCF = nil

			-- High-tension gold parry glint telegraph
			Core.playSFX("COIN_FLIP", 0.72, 1.0, "PARRY")
			Core.spawnFlash(hrp.Position + V(0, 1.0, 0), PALETTE.JUDGEMENT_GOLD, 0.8, 3.6, 0.20)
		end,

		stepCharacter = function(_, c, hrp, hum, _, ctx)
			local STATE = Core.getState()
			local CONFIG = Core.getConfig()
			local now = ctx.now
			local inFP = ctx.inFP
			local cam = ctx.cam
			local isAir = ctx.isAir
			local sinW, cosW = ctx.sinW, ctx.cosW

			local t = STATE.time
			local idleWeight = clamp(1 - STATE.walkBlend, 0, 1) * (1 - STATE.airBlend)
			local realSoleDepth = (STATE.rigType == "R15") and (hum.HipHeight + hrp.Size.Y * 0.5) or 3.0
			local groundOffsetY = MINOS_SOLE_DEPTH - realSoleDepth

			local camPitch, camYawLocal = 0, 0
			if CONFIG.ENABLE_HEAD_AIM_TRACKING and cam then
				local camLocalLook = hrp.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)
				camPitch = clamp(math.asin(clamp(camLocalLook.Y, -0.85, 0.85)) * 180 / math.pi, -45, 55)
				camYawLocal = clamp(math.atan2(-camLocalLook.X, -camLocalLook.Z) * 180 / math.pi, -35, 35)
			end

			-- Base Minos Prime Boxer Stance (hands raised, weight shifted, subtle heart pulse)
			local torsoY = groundOffsetY + math.sin(t * 3.0) * 0.05 * idleWeight + math.abs(sinW) * 0.14 * STATE.walkBlend * (1 + STATE.sprintBlend * 0.4) - STATE.landRecover * 0.30
			local idleYaw = 24 * idleWeight
			local walkTwist = cosW * (7 + STATE.sprintBlend * 8) * STATE.walkBlend
			local torsoPitch = -STATE.localFwd * (9 + STATE.sprintBlend * 12) + (STATE.landRecover * -14) + STATE.airBlend * clamp(-STATE.vertVel * 0.35, -14, 14)
			local torsoRoll = -STATE.localStrafe * 10 - STATE.turnRate * 2.4
			local torsoYaw = idleYaw + walkTwist

			if STATE.slide.active and not isAir then
				torsoY -= 1.35
				torsoPitch = 36
				torsoRoll = -STATE.localStrafe * 12
				torsoYaw = 18
			elseif STATE.slam.active and isAir then
				-- "DIE!" Midair Rider Kick Pose
				torsoPitch = -34
				torsoRoll = -8
				torsoYaw = -16
			elseif STATE.isGliding and isAir then
				torsoPitch -= 12
			end

			if STATE.dash.active then
				local dK = 1 - clamp((now - STATE.dash.startTime) / math.max(0.01, CONFIG.DASH_DURATION), 0, 1)
				local ld = STATE.dash.localDir
				torsoPitch += ld.Z * 28 * dK
				torsoRoll -= ld.X * 26 * dK
			end

			-- Default Boxer Guard Arms
			local lUpperPitch = lerp(-12, 46, idleWeight) + sinW * (28 + STATE.sprintBlend * 18) * STATE.walkBlend
			local lUpperYaw = -16 * idleWeight
			local lUpperRoll = 12 + STATE.airBlend * 14
			local lForePitch = lerp(30, 86, idleWeight) + math.max(0, sinW) * 20 * STATE.walkBlend

			local rUpperPitch = lerp(-14, 38, idleWeight) - sinW * (28 + STATE.sprintBlend * 18) * STATE.walkBlend
			local rUpperYaw = 14 * idleWeight
			local rUpperRoll = -12 - STATE.airBlend * 14
			local rForePitch = lerp(28, 78, idleWeight) + math.max(0, -sinW) * 20 * STATE.walkBlend

			-- Default Legs
			local lThighP, rThighP = 12 * idleWeight, -14 * idleWeight
			local lShinP, rShinP = -18 * idleWeight, -12 * idleWeight
			local lFootP, rFootP = 6 * idleWeight, 22 * idleWeight

			if STATE.walkBlend > 0.01 then
				local stride = 38 + STATE.sprintBlend * 22
				lThighP = lerp(lThighP, sinW * stride, STATE.walkBlend)
				rThighP = lerp(rThighP, -sinW * stride, STATE.walkBlend)
				lShinP = lerp(lShinP, -math.max(0, -cosW) * (48 + STATE.sprintBlend * 22) - 8, STATE.walkBlend)
				rShinP = lerp(rShinP, -math.max(0, cosW) * (48 + STATE.sprintBlend * 22) - 8, STATE.walkBlend)
				lFootP = lerp(lFootP, cosW * 16, STATE.walkBlend)
				rFootP = lerp(rFootP, -cosW * 16, STATE.walkBlend)
			end

			if STATE.airBlend > 0.01 then
				local airTuckL, airTuckR = 24, 46
				local shinTuckL, shinTuckR = -36, -70
				if STATE.slam.active then
					-- Rider Kick ("DIE!") leg silhouette
					airTuckL, airTuckR = 72, -16
					shinTuckL, shinTuckR = -105, -8
					lUpperPitch, lUpperRoll, lForePitch = -24, 38, 22
					rUpperPitch, rUpperRoll, rForePitch = 56, -12, 48
				elseif STATE.isGliding then
					airTuckL, airTuckR = 14, 28
					shinTuckL, shinTuckR = -24, -48
				end
				lThighP = lerp(lThighP, airTuckL, STATE.airBlend)
				rThighP = lerp(rThighP, airTuckR, STATE.airBlend)
				lShinP = lerp(lShinP, shinTuckL, STATE.airBlend)
				rShinP = lerp(rShinP, shinTuckR, STATE.airBlend)
			end

			if STATE.slide.active and not isAir then
				lThighP, rThighP = 68, -22
				lShinP, rShinP = -12, -74
				lFootP, rFootP = -24, 18
			end

			-- Track Slam Impact for "CRUSH!" shockwave
			if STATE.wasSlamming and not STATE.slam.active and not isAir then
				Core.playSFX("PARRY", 0.72, 0.92)
				Core.spawnRing(hrp.Position - V(0, 2.2, 0), PALETTE.PRIME_CYAN, 1.6, 12.5, 0.34)
				Core.spawnFlash(hrp.Position - V(0, 2.0, 0), PALETTE.PRIME_CYAN, 1.2, 6.8, 0.25)
				Core.addStyleBonus("+CRUSH", 150, PALETTE.PRIME_CYAN)
				STATE.camShake = math.max(STATE.camShake, 0.65)
				for _, hit in ipairs(findTargetsInRadius(c, hrp.Position, 13.5)) do
					Core.applyF3XKnockback(hit.char, hit.hrp.Position - hrp.Position, CRUSH_KNOCKBACK)
				end
			end
			STATE.wasSlamming = STATE.slam.active

			-------------------------------------------------------------------
			-- MOVE 1: LMB BOXING COMBO ("THY END IS NOW!" / UPPERCUT)
			-------------------------------------------------------------------
			local cb = STATE.custom.combo
			if cb.active then
				local cEl = now - cb.startTime
				local dur = (cb.step == 4) and 0.42 or 0.26
				if cEl < dur then
					if cb.uppercut then
						local k = easeOutBack(clamp(cEl / 0.16, 0, 1))
						torsoPitch = lerp(torsoPitch, -18, k)
						torsoYaw = lerp(torsoYaw, -28, k)
						rUpperPitch = lerp(rUpperPitch, 138, k)
						rUpperYaw = lerp(rUpperYaw, -12, k)
						rForePitch = lerp(rForePitch, 22, k)
					elseif cb.step == 1 then
						-- Left Jab
						local k = easeOutBack(clamp(cEl / 0.12, 0, 1))
						torsoYaw = lerp(torsoYaw, -36, k)
						lUpperPitch = lerp(lUpperPitch, 94 + camPitch * 0.6, k)
						lUpperYaw = lerp(lUpperYaw, -18, k)
						lForePitch = lerp(lForePitch, 8, k)
					elseif cb.step == 2 then
						-- Right Cross
						local k = easeOutBack(clamp(cEl / 0.12, 0, 1))
						torsoYaw = lerp(torsoYaw, 38, k)
						rUpperPitch = lerp(rUpperPitch, 96 + camPitch * 0.6, k)
						rUpperYaw = lerp(rUpperYaw, 18, k)
						rForePitch = lerp(rForePitch, 8, k)
					elseif cb.step == 3 then
						-- Left Hook
						local k = easeOutBack(clamp(cEl / 0.13, 0, 1))
						torsoYaw = lerp(torsoYaw, -52, k)
						lUpperPitch = lerp(lUpperPitch, 84, k)
						lUpperYaw = lerp(lUpperYaw, -54, k)
						lForePitch = lerp(lForePitch, 68, k)
					else
						-- Step 4 Finisher Overhead Slam
						local k = easeOutQuad(clamp(cEl / 0.18, 0, 1))
						torsoY -= 0.42 * k
						torsoPitch = lerp(torsoPitch, 32, k)
						rUpperPitch = lerp(rUpperPitch, 56, k)
						lUpperPitch = lerp(lUpperPitch, 56, k)
						rForePitch = lerp(rForePitch, 14, k)
						lForePitch = lerp(lForePitch, 14, k)
					end

					if not cb.hitDone and cEl >= 0.06 then
						cb.hitDone = true
						-- Forward micro-step on punch
						hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + hrp.CFrame.LookVector * (cb.step == 4 and 24 or 14)
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE, hrp.CFrame.LookVector)
						if tChar and tHRP then
							local isFinisher = (cb.step == 4)
							Core.playSFX("PARRY", isFinisher and 0.85 or 1.05, 0.9)
							Core.triggerHitstop(isFinisher and 0.09 or 0.05, PALETTE.PRIME_CYAN)
							Core.spawnFlash(tHRP.Position, isFinisher and PALETTE.JUDGEMENT_GOLD or PALETTE.PRIME_CYAN, 0.9, isFinisher and 5.5 or 3.8, 0.22)
							if isFinisher or cb.uppercut then
								Core.spawnRing(tHRP.Position, PALETTE.PRIME_CYAN, 1.0, 6.2, 0.24)
							end
							local kb = cb.uppercut and UPPERCUT_KNOCKBACK or (isFinisher and FINISHER_KNOCKBACK or PUNCH_KNOCKBACK)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, kb)
							Core.addStyleBonus(cb.uppercut and "+UPPERCUT" or (isFinisher and "+THY END IS NOW" or "+PRIME PUNCH"), isFinisher and 175 or 75, PALETTE.PRIME_CYAN)
						end
					end
				else
					cb.active = false
				end
			end

			-------------------------------------------------------------------
			-- MOVE 2: [E] SERPENT ("PREPARE THYSELF!" 2-KICK + HOMING SERPENT)
			-------------------------------------------------------------------
			local sa = STATE.custom.serpent
			if sa.kickPhase then
				local sEl = now - sa.startTime
				if sEl < 0.18 then
					-- Kick 1: Right Roundhouse Sweep
					local k = easeOutBack(clamp(sEl / 0.14, 0, 1))
					torsoPitch = lerp(torsoPitch, -24, k)
					torsoYaw = lerp(torsoYaw, -48, k)
					rThighP = lerp(rThighP, 88, k)
					rShinP = lerp(rShinP, -10, k)
					lUpperPitch, rUpperPitch = lerp(lUpperPitch, -24, k), lerp(rUpperPitch, 48, k)

					if not sa.kickHit1 and sEl >= 0.07 then
						sa.kickHit1 = true
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 1.5, hrp.CFrame.LookVector)
						if tChar and tHRP then
							Core.playSFX("PARRY", 1.02, 0.9)
							Core.spawnFlash(tHRP.Position, PALETTE.PRIME_CYAN, 0.9, 4.2, 0.20)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, PUNCH_KNOCKBACK)
						end
					end
				elseif sEl < 0.36 then
					-- Kick 2: Left High Kick + Forearm Serpent Launch Pose
					local k = easeOutBack(clamp((sEl - 0.18) / 0.14, 0, 1))
					torsoPitch = lerp(torsoPitch, -26, k)
					torsoYaw = lerp(torsoYaw, 46, k)
					lThighP = lerp(lThighP, 94, k)
					lShinP = lerp(lShinP, -8, k)
					rUpperPitch = lerp(rUpperPitch, 96 + camPitch * 0.7, k)
					rForePitch = lerp(rForePitch, 8, k)

					if not sa.kickHit2 and sEl >= 0.22 then
						sa.kickHit2 = true
						Core.playSFX("PUNCH", 0.96, 0.95, "PARRY")
						local tChar, tHRP = findNearestTarget(c, hrp.Position, COMBO_RANGE + 1.5, hrp.CFrame.LookVector)
						if tChar and tHRP then
							Core.playSFX("PARRY", 1.06, 0.95)
							Core.spawnFlash(tHRP.Position, PALETTE.SERPENT_GOLD, 1.0, 4.6, 0.22)
							Core.applyF3XKnockback(tChar, tHRP.Position - hrp.Position, PUNCH_KNOCKBACK)
						end
					end

					if not sa.launched and sEl >= 0.26 then
						sa.launched = true
						sa.projectileActive = true
						local launchPos = (hrp.CFrame * C(1.2, 0.8, -2.4)).Position
						local aimTargetPos = getLookAimPos(cam, hrp, SERPENT_RANGE)
						local tChar, tHRP = findNearestTarget(c, launchPos, SERPENT_RANGE, nil)
						local dir = ((tHRP and tHRP.Position or aimTargetPos) - launchPos)
						dir = (dir.Magnitude > 0.1) and dir.Unit or hrp.CFrame.LookVector
						sa.originPos = launchPos
						sa.pos = launchPos
						sa.vel = dir * SERPENT_SPEED
						sa.targetChar = tChar
						sa.cf = C(sa.pos, sa.pos + dir)
						Core.playSFX("COIN_FLIP", 0.88, 1.0, "PARRY")
						Core.spawnRing(launchPos, PALETTE.SERPENT_GOLD, 0.7, 3.8, 0.20)
					end
				else
					sa.kickPhase = false
				end
			end

			-- Update Homing Golden Serpent Projectile
			if sa.projectileActive then
				local pEl = now - sa.startTime
				local dtStep = 1 / 60

				local targetHRP = sa.targetChar and Core.getTargetRoot(sa.targetChar)
				if not targetHRP then
					local newChar, newHRP = findNearestTarget(c, sa.pos, 55, nil)
					sa.targetChar = newChar
					targetHRP = newHRP
				end

				if targetHRP and targetHRP:IsA("BasePart") then
					local desired = (targetHRP.Position - sa.pos)
					if desired.Magnitude > 0.1 then
						local curDir = sa.vel.Unit
						local newDir = curDir:Lerp(desired.Unit, 0.11).Unit
						sa.vel = newDir * SERPENT_SPEED
					end
				end

				sa.pos = sa.pos + sa.vel * dtStep
				sa.cf = C(sa.pos, sa.pos + sa.vel) * angles(0, 0, pEl * 540)

				local hitDetected = false
				local hitPos = sa.pos
				local hitChar = nil
				for _, hit in ipairs(findTargetsInRadius(c, sa.pos, 6.0)) do
					hitDetected = true
					hitPos = hit.hrp.Position
					hitChar = hit.char
					break
				end

				if hitDetected or pEl >= 1.65 then
					sa.projectileActive = false
					sa.active = false
					sa.cf = PARK_CF
					Core.playSFX("SHATTER", 0.94, 1.0, "PARRY")
					Core.spawnRing(hitPos, PALETTE.SERPENT_GOLD, 1.1, 8.5, 0.28)
					Core.spawnFlash(hitPos, PALETTE.SERPENT_GOLD, 1.3, 6.4, 0.24)
					if hitChar then
						Core.playSFX("PARRY", 1.10, 0.9)
						Core.triggerHitstop(0.08, PALETTE.SERPENT_GOLD)
						Core.fireDualBeams(sa.originPos, (sa.originPos + hitPos) * 0.5 + V(0, 2, 0), hitPos, PALETTE.PRIME_CYAN, PALETTE.SERPENT_GOLD, 0.18, 0.42, true, 0.22)
						Core.addStyleBonus("+PREPARE THYSELF", 180, PALETTE.SERPENT_GOLD)
						Core.applyF3XKnockback(hitChar, sa.vel, SERPENT_KNOCKBACK)
					end
				end
			else
				sa.cf = PARK_CF
			end

			if STATE.buckets.minosSerpent then
				local parentCF = sa.projectileActive and sa.cf or PARK_CF
				for _, e in ipairs(STATE.buckets.minosSerpent) do
					e.targetCF = (parentCF == PARK_CF) and PARK_CF or (parentCF * e.relCF)
					e.part.CFrame = e.targetCF
				end
			end

			-------------------------------------------------------------------
			-- MOVE 3: [F] JUDGEMENT ("JUDGEMENT!" TELEPORT DROPKICK + EXPLOSION)
			-------------------------------------------------------------------
			local ja = STATE.custom.judgement
			if ja.active then
				local jEl = now - ja.startTime
				if jEl < 0.22 then
					-- Telegraph Crouch + Gold Parry Flash
					local k = easeOutQuad(jEl / 0.22)
					torsoY -= 0.78 * k
					torsoPitch = lerp(torsoPitch, 38, k)
					lThighP, rThighP = lerp(lThighP, 62, k), lerp(rThighP, 58, k)
					lShinP, rShinP = lerp(lShinP, -96, k), lerp(rShinP, -92, k)
					lUpperPitch, rUpperPitch = lerp(lUpperPitch, -48, k), lerp(rUpperPitch, -48, k)
					lUpperRoll, rUpperRoll = 26, -26
					if not ja.flashDone and jEl >= 0.10 then
						ja.flashDone = true
						Core.spawnRing(hrp.Position, PALETTE.JUDGEMENT_GOLD, 0.8, 5.2, 0.18)
					end
				elseif jEl < 0.50 then
					-- Teleport Dropkick Strike
					if not ja.teleported then
						ja.teleported = true
						local originPos = hrp.Position
						local tChar, tHRP = findNearestTarget(c, originPos, JUDGEMENT_RANGE, nil)
						local destPos
						local faceDir
						if tHRP then
							local toTarget = (tHRP.Position - originPos)
							local flatDir = V(toTarget.X, 0, toTarget.Z)
							faceDir = (flatDir.Magnitude > 0.1) and flatDir.Unit or hrp.CFrame.LookVector
							destPos = tHRP.Position - faceDir * 4.2 + V(0, 1.2, 0)
						else
							local look = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
							faceDir = V(look.X, 0, look.Z)
							faceDir = (faceDir.Magnitude > 0.1) and faceDir.Unit or hrp.CFrame.LookVector
							destPos = originPos + faceDir * 36 + V(0, 1.0, 0)
						end

						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = C(destPos, destPos + faceDir)
						Core.fireDualBeams(originPos, (originPos + destPos) * 0.5 + V(0, 1.5, 0), destPos, PALETTE.PRIME_CYAN, PALETTE.JUDGEMENT_GOLD, 0.28, 0.36, true, 0.24)
					end

					-- Full horizontal Dropkick Pose
					local k = easeOutBack(clamp((jEl - 0.22) / 0.10, 0, 1))
					torsoY += 0.35 * k
					torsoPitch = lerp(torsoPitch, -58, k)
					torsoYaw = 0
					lThighP, rThighP = lerp(lThighP, 82, k), lerp(rThighP, 88, k)
					lShinP, rShinP = lerp(lShinP, -6, k), lerp(rShinP, -4, k)
					lUpperPitch, rUpperPitch = lerp(lUpperPitch, -38, k), lerp(rUpperPitch, -38, k)
					lUpperRoll, rUpperRoll = 36, -36

					if not ja.exploded and jEl >= 0.25 then
						ja.exploded = true
						local blastPos = (hrp.CFrame * C(0, 0, -2.5)).Position
						Core.playSFX("PARRY", 0.80, 1.0)
						Core.playSFX("SHATTER", 0.76, 1.0, "PARRY")
						Core.triggerHitstop(0.11, PALETTE.JUDGEMENT_GOLD)
						Core.spawnRing(blastPos, PALETTE.JUDGEMENT_GOLD, 1.8, 14.0, 0.34)
						Core.spawnRing(blastPos + V(0, 0.4, 0), PALETTE.PRIME_CYAN, 1.2, 10.5, 0.28)
						Core.spawnFlash(blastPos, PALETTE.JUDGEMENT_GOLD, 1.6, 8.2, 0.28)
						STATE.camShake = math.max(STATE.camShake, 0.85)
						STATE.fovKick = math.max(STATE.fovKick, 12)

						local hits = findTargetsInRadius(c, blastPos, 13.5)
						if #hits > 0 then
							Core.addStyleBonus("+JUDGEMENT", 260, PALETTE.JUDGEMENT_GOLD)
							for _, hit in ipairs(hits) do
								Core.applyF3XKnockback(hit.char, hit.hrp.Position - hrp.Position + hrp.CFrame.LookVector * 3, JUDGEMENT_KNOCKBACK)
							end
						else
							Core.addStyleBonus("+JUDGEMENT", 120, PALETTE.PRIME_CYAN)
						end
					end
				else
					ja.active = false
				end
			end

			-------------------------------------------------------------------
			-- BUILD FINAL CFRAMES & APPLY TO BUCKETS
			-------------------------------------------------------------------
			local torsoCF = hrp.CFrame * C(0, torsoY, 0) * angles(torsoPitch, torsoYaw, torsoRoll)
			local chestCF = torsoCF * C(0, MINOS_CHEST_OFFSET, 0)
			local abdomenCF = torsoCF * C(0, MINOS_ABDOMEN_OFFSET, 0)
			local pelvisCF = torsoCF * C(0, MINOS_PELVIS_OFFSET, 0)

			local headPitch = camPitch * 0.85 - torsoPitch * 0.45 + math.sin(t * 3.0 + 0.5) * 2.5 * idleWeight
			local headYaw = camYawLocal * 0.75 - torsoYaw * 0.35
			local headCF = chestCF * C(0, 1.06, -0.04) * angles(headPitch, headYaw, -torsoRoll * 0.4)

			local shoulderL = chestCF * C(-1.06, 0.24, 0)
			local shoulderR = chestCF * C(1.06, 0.24, 0)
			if STATE.fpArms and cam then
				shoulderL = cam.CFrame * C(-1.05, -0.78, -0.82) * angles(-camPitch * 0.2, 0, 0)
				shoulderR = cam.CFrame * C(1.02, -0.78, -0.85) * angles(-camPitch * 0.2, 0, 0)
			end

			local lUpperCF = shoulderL * angles(lUpperPitch, lUpperYaw, lUpperRoll)
			local lForeCF = lUpperCF * C(0, -MINOS_UPPER_ARM_LEN, 0) * angles(lForePitch, 0, 0)
			local lHandCF = lForeCF * C(0, -MINOS_FOREARM_LEN, 0)

			local rUpperCF = shoulderR * angles(rUpperPitch, rUpperYaw, rUpperRoll)
			local rForeCF = rUpperCF * C(0, -MINOS_UPPER_ARM_LEN, 0) * angles(rForePitch, 0, 0)
			local rHandCF = rForeCF * C(0, -MINOS_FOREARM_LEN, 0)

			local hipL = pelvisCF * C(-0.46, MINOS_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, MINOS_HIP_Y, 0)
			local lThighCF = hipL * angles(lThighP, 8 * idleWeight, -4)
			local rThighCF = hipR * angles(rThighP, -6 * idleWeight, 4)
			local lShinCF = lThighCF * C(0, -MINOS_THIGH_LEN, 0) * angles(lShinP, 0, 0)
			local rShinCF = rThighCF * C(0, -MINOS_THIGH_LEN, 0) * angles(rShinP, 0, 0)
			local lFootCF = lShinCF * C(0, -MINOS_SHIN_LEN, 0) * angles(lFootP, 0, 0)
			local rFootCF = rShinCF * C(0, -MINOS_SHIN_LEN, 0) * angles(rFootP, 0, 0)

			local function applyBucket(bucketName, parentMap, hideInFP)
				local list = STATE.buckets[bucketName]
				if not list then return end
				for _, e in ipairs(list) do
					local baseCF = e.key and parentMap[e.key] or parentMap
					if baseCF then
						e.targetCF = baseCF * e.relCF
						e.part.CFrame = e.targetCF
						e.part.LocalTransparencyModifier = (hideInFP and inFP) and 1 or 0
					end
				end
			end

			applyBucket("minosHead", headCF, true)
			applyBucket("minosBody", { chest = chestCF, abdomen = abdomenCF, pelvis = pelvisCF }, true)
			applyBucket("minosUpperArm", { lUpperArm = lUpperCF, rUpperArm = rUpperCF }, not STATE.fpArms)
			applyBucket("minosForearm", { lForearm = lForeCF, rForearm = rForeCF }, not STATE.fpArms)
			applyBucket("minosHand", { lHand = lHandCF, rHand = rHandCF }, not STATE.fpArms)
			applyBucket("minosThigh", { lThigh = lThighCF, rThigh = rThighCF }, true)
			applyBucket("minosShin", { lShin = lShinCF, rShin = rShinCF }, true)
			applyBucket("minosFoot", { lFoot = lFootCF, rFoot = rFootCF }, true)

			local judgeCharge = clamp((now - ja.lastUsed) / JUDGEMENT_COOLDOWN, 0, 1)
			local serpentCharge = clamp((now - sa.lastUsed) / SERPENT_COOLDOWN, 0, 1)
			local hudCharge = math.min(judgeCharge, serpentCharge)

			local titleText = "JUDGEMENT // SERPENT"
			local titleColor = PALETTE.PRIME_CYAN
			if ja.active then
				titleText = "!! JUDGEMENT !!"
				titleColor = PALETTE.JUDGEMENT_GOLD
			elseif sa.active then
				titleText = "PREPARE THYSELF!"
				titleColor = PALETTE.SERPENT_GOLD
			elseif cb.active then
				titleText = cb.uppercut and "UPPERCUT!" or "THY END IS NOW!"
				titleColor = PALETTE.PRIME_CYAN
			end

			local hudStatus = {
				weaponTitle = titleText,
				weaponColor = titleColor,
				chargeFrac = hudCharge,
				pipColor = PALETTE.SERPENT_GOLD,
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