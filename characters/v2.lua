-- ULTRAKILL V2 MODULE (CLAIR DE LUNE - ESCALA 1.16x + KNUCKLEBLASTER + PIERCER / SHOTGUN + AERIAL MOVEMENT)
-- Carregado dinamicamente pelo loader.lua recebendo Core

return function(Core)
	local C, V = Core.C, Core.V
	local ID_CF, PARK_CF = Core.ID_CF, Core.PARK_CF
	local clamp, lerp, easeOutQuad, easeOutBack = Core.clamp, Core.lerp, Core.easeOutQuad, Core.easeOutBack
	local angles, mirrorRelCF = Core.angles, Core.mirrorRelCF

	local S = 1.16 -- Escala oficial V2 (~16% maior que V1)

	local PALETTE = {
		RED_ARMOR = Color3.fromRGB(168, 28, 34),
		LIGHT_RED_ARMOR = Color3.fromRGB(205, 44, 50),
		DEEP_RED_ARMOR = Color3.fromRGB(115, 18, 24),
		DARK_METAL = Color3.fromRGB(28, 30, 36),
		GUN_STEEL = Color3.fromRGB(72, 78, 92),
		SILVER_TRIM = Color3.fromRGB(175, 184, 198),
		BLACK_TRIM = Color3.fromRGB(14, 15, 19),
		YELLOW_NEON = Color3.fromRGB(255, 208, 30),
		GOLD_WING = Color3.fromRGB(255, 205, 35),
		BLUE_WING = Color3.fromRGB(70, 175, 255),
		GREEN_WING = Color3.fromRGB(75, 255, 130),
		RED_WING = Color3.fromRGB(255, 42, 48),
		PIERCER_BLUE = Color3.fromRGB(80, 215, 255),
		SHOTGUN_ORANGE = Color3.fromRGB(255, 145, 45),
		KNUCKLE_BLAST = Color3.fromRGB(255, 75, 35),
		BEAM_CORE = Color3.fromRGB(255, 255, 255),
		BLOOD_RED = Color3.fromRGB(185, 26, 32),
	}

	local V2_CHEST_OFFSET = 0.56 * S
	local V2_ABDOMEN_OFFSET = -0.22 * S
	local V2_PELVIS_OFFSET = -0.80 * S
	local V2_HIP_Y = -0.14 * S
	local V2_THIGH_LEN = 1.18 * S
	local V2_SHIN_LEN = 1.16 * S
	local V2_SOLE_DEPTH_FROM_ANKLE = 0.38 * S
	local V2_SOLE_DEPTH = math.abs(V2_PELVIS_OFFSET) + math.abs(V2_HIP_Y) + V2_THIGH_LEN + V2_SHIN_LEN + V2_SOLE_DEPTH_FROM_ANKLE
	local V2_UPPER_ARM_LEN = 1.04 * S
	local V2_FOREARM_LEN = 1.00 * S

	local GUN_MOUNT_REL = ID_CF
	local PIERCER_MUZZLE_LOCAL = C(0, -1.62 * S, -0.29 * S)
	local SHOTGUN_MUZZLE_LOCAL = C(0, -1.86 * S, -0.28 * S)

	local PIERCER_COOLDOWN = 0.55
	local SHOTGUN_COOLDOWN = 0.72
	local KNUCKLE_COOLDOWN = 0.65
	local PIERCER_RANGE = 110
	local SHOTGUN_RANGE = 42
	local KNUCKLE_RANGE = 14.5

	local PIERCER_KB = { speed = 58, up = 26, spin = 10.0 }
	local SHOTGUN_KB = { speed = 78, up = 34, spin = 13.0 }
	local KNUCKLE_DIRECT_KB = { speed = 98, up = 44, spin = 16.0 }
	local KNUCKLE_AOE_KB = { speed = 64, up = 38, spin = 12.0 }

	-------------------------------------------------------------------
	-- BLUEPRINTS DO MODELO V2 (ESCALA 1.16x + KNUCKLEBLASTER + SELO V2)
	-------------------------------------------------------------------
	local function getV2HeadSpecs()
		return {
			{ partType = "Cylinder", size = V(0.38, 0.30, 0.30) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.36 * S, 0.06 * S) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.38, 0.13, 0.13) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(-0.15 * S, -0.34 * S, -0.02 * S) * angles(10, 0, 82) },
			{ partType = "Cylinder", size = V(0.38, 0.13, 0.13) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.15 * S, -0.34 * S, -0.02 * S) * angles(10, 0, 98) },
			{ partType = "Normal",   size = V(0.80, 0.65, 1.16) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.04 * S, 0.05 * S) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.88, 0.22, 1.32) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.44 * S, -0.02 * S) * angles(-5, 0, 0) },
			{ partType = "Normal",   size = V(0.90, 0.11, 0.44) * S, color = PALETTE.LIGHT_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.37 * S, -0.58 * S) * angles(-12, 0, 0) },
			{ partType = "Wedge",    size = V(0.16, 0.16, 0.98) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.55 * S, 0.12 * S) * angles(-4, 0, 0) },
			{ partType = "Wedge",    size = V(0.16, 0.56, 1.00) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.44 * S, 0, 0.02 * S) * angles(-6, -10, 6) },
			{ partType = "Wedge",    size = V(0.16, 0.56, 1.00) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.44 * S, 0, 0.02 * S) * angles(-6, 10, -6) },
			{ partType = "Cylinder", size = V(0.96, 0.20, 0.20) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.04 * S, 0.08 * S) },
			{ partType = "Normal",   size = V(0.64, 0.50, 0.28) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.06 * S, 0.67 * S) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.46, 0.24, 0.12) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.16 * S, 0.80 * S) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.64, 0.22, 0.76) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.27 * S, -0.14 * S) * angles(174, 0, 0) },
			{ partType = "Normal",   size = V(0.68, 0.50, 0.14) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.03 * S, -0.51 * S) * angles(-6, 0, 0) },
			{ partType = "Cylinder", size = V(0.13, 0.46, 0.46) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.03 * S, -0.56 * S) * angles(-6, 0, 0) * angles(0, 90, 0) },
			{ partType = "Cylinder", size = V(0.15, 0.36, 0.36) * S, color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.03 * S, -0.58 * S) * angles(-6, 0, 0) * angles(0, 90, 0), light = true, lightColor = PALETTE.YELLOW_NEON },
		}
	end

	local function getV2ChestSpecs()
		return {
			{ partType = "Normal",   size = V(1.88, 0.84, 0.84) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.12 * S, 0.02 * S) },
			{ partType = "Wedge",    size = V(0.84, 0.66, 0.34) * S, color = PALETTE.LIGHT_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.48 * S, 0.16 * S, -0.49 * S) * angles(0, 12, 180) },
			{ partType = "Wedge",    size = V(0.84, 0.66, 0.34) * S, color = PALETTE.LIGHT_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.48 * S, 0.16 * S, -0.49 * S) * angles(0, -12, 180) },
			{ partType = "Normal",   size = V(0.36, 0.80, 0.26) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.10 * S, -0.41 * S) },
			{ partType = "Normal",   size = V(0.11, 0.42, 0.09) * S, color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.16 * S, -0.51 * S), light = true, lightColor = PALETTE.YELLOW_NEON },
			{ partType = "Normal",   size = V(0.44, 0.19, 0.13) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.55 * S, -0.06 * S, -0.48 * S) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.44, 0.19, 0.13) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.55 * S, -0.06 * S, -0.48 * S) * angles(-10, -12, 0) },
			{ partType = "Normal",   size = V(0.34, 0.07, 0.09) * S, color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.55 * S, -0.06 * S, -0.52 * S) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.34, 0.07, 0.09) * S, color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0.55 * S, -0.06 * S, -0.52 * S) * angles(-10, -12, 0) },
			{ partType = "Normal",   size = V(0.36, 0.24, 0.05) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.48 * S, 0.26 * S, -0.56 * S) * angles(-6, -12, 0) },
			{ partType = "Normal",   size = V(0.04, 0.16, 0.04) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.38 * S, 0.26 * S, -0.58 * S) * angles(-6, -12, 16) },
			{ partType = "Normal",   size = V(0.04, 0.16, 0.04) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.44 * S, 0.26 * S, -0.58 * S) * angles(-6, -12, -16) },
			{ partType = "Normal",   size = V(0.11, 0.035, 0.04) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.55 * S, 0.32 * S, -0.58 * S) * angles(-6, -12, 0) },
			{ partType = "Normal",   size = V(0.11, 0.035, 0.04) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.55 * S, 0.26 * S, -0.58 * S) * angles(-6, -12, 0) },
			{ partType = "Normal",   size = V(0.11, 0.035, 0.04) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.55 * S, 0.20 * S, -0.58 * S) * angles(-6, -12, 0) },
			{ partType = "Wedge",    size = V(0.34, 0.38, 0.84) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.66 * S, 0.64 * S, 0.02 * S) * angles(0, 0, -18) },
			{ partType = "Wedge",    size = V(0.34, 0.38, 0.84) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.66 * S, 0.64 * S, 0.02 * S) * angles(0, 0, 18) },
			{ partType = "Normal",   size = V(0.92, 0.20, 0.74) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.58 * S, 0.04 * S) },
			{ partType = "Normal",   size = V(1.26, 0.34, 0.70) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.34 * S, 0.02 * S) },
			{ partType = "Cylinder", size = V(2.08, 0.38, 0.38) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0, 0.24 * S, 0.02 * S) },
		}
	end

	local function getV2AbdomenSpecs()
		return {
			{ partType = "Cylinder", size = V(0.88, 0.40, 0.40) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0.04 * S) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.76, 0.76, 0.52) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.84, 0.18, 0.56) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.14 * S, 0) },
			{ partType = "Normal",   size = V(0.80, 0.18, 0.54) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.14 * S, 0) },
			{ partType = "Cylinder", size = V(0.80, 0.16, 0.16) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(-0.30 * S, 0, -0.20 * S) * angles(0, 0, 84) },
			{ partType = "Cylinder", size = V(0.80, 0.16, 0.16) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.30 * S, 0, -0.20 * S) * angles(0, 0, 96) },
			{ partType = "Normal",   size = V(0.09, 0.58, 0.09) * S, color = PALETTE.DEEP_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.44 * S, 0, -0.13 * S) * angles(0, 0, 10) },
			{ partType = "Normal",   size = V(0.09, 0.58, 0.09) * S, color = PALETTE.DEEP_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.44 * S, 0, -0.13 * S) * angles(0, 0, -10) },
		}
	end

	local function getV2PelvisSpecs()
		return {
			{ partType = "Normal",   size = V(1.22, 0.36, 0.64) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.02 * S, 0) },
			{ partType = "Wedge",    size = V(0.64, 0.38, 0.40) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.06 * S, -0.28 * S) * angles(180, 0, 0) },
			{ partType = "Normal",   size = V(0.18, 0.40, 0.50) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(-0.67 * S, -0.06 * S, 0.02 * S) * angles(0, 0, 12) },
			{ partType = "Normal",   size = V(0.18, 0.40, 0.50) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0.67 * S, -0.06 * S, 0.02 * S) * angles(0, 0, -12) },
			{ partType = "Cylinder", size = V(1.18, 0.30, 0.30) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.14 * S, 0) },
		}
	end

	local function getV2CoreSpecs()
		return {
			{ partType = "Normal",   size = V(0.94, 0.92, 0.42) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.14 * S, 0.58 * S) },
			{ partType = "Wedge",    size = V(0.82, 0.30, 0.42) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.66 * S, 0.56 * S) * angles(16, 0, 0) },
			{ partType = "Normal",   size = V(0.56, 0.98, 0.28) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.12 * S, 0.72 * S) },
			{ partType = "Normal",   size = V(0.24, 0.90, 0.26) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(-0.38 * S, 0.18 * S, 0.76 * S) * angles(0, 0, 16) },
			{ partType = "Normal",   size = V(0.24, 0.90, 0.26) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0.38 * S, 0.18 * S, 0.76 * S) * angles(0, 0, -16) },
			{ partType = "Normal",   size = V(0.18, 0.64, 0.14) * S, color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.14 * S, 0.84 * S), light = true, lightColor = PALETTE.YELLOW_NEON },
			{ partType = "Normal",   size = V(0.48, 0.24, 0.32) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0, -0.35 * S, 0.66 * S) * angles(-18, 0, 0) },
		}
	end

	local function getV2SingleWingParts()
		return {
			{ partType = "Cylinder", size = V(0.19, 0.24, 0.24) * S, color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0.05 * S, 0, 0) * angles(0, 90, 0) },
			{ partType = "Normal",   size = V(0.74, 0.13, 0.15) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0.43 * S, 0, 0) },
			{ partType = "Wedge",    size = V(0.20, 0.28, 0.94) * S, color = PALETTE.RED_ARMOR,  mat = Enum.Material.SmoothPlastic, relCF = C(0.94 * S, 0.08 * S, 0) * angles(0, -90, 0) },
			{ partType = "Normal",   size = V(0.98, 0.12, 0.13) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(1.24 * S, -0.04 * S, 0) },
			{ partType = "Normal",   size = V(0.44, 0.24, 0.15) * S, color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(1.70 * S, 0.01 * S, 0) },
			{ partType = "Normal",   size = V(2.60, 0.30, 0.07) * S, color = PALETTE.GOLD_WING,  mat = Enum.Material.Neon, relCF = C(3.00 * S, 0.01 * S, 0), wingNeon = true },
			{ partType = "Wedge",    size = V(0.07, 0.30, 1.35) * S, color = PALETTE.GOLD_WING,  mat = Enum.Material.Neon, relCF = C(4.975 * S, 0.01 * S, 0) * angles(0, -90, 0), wingNeon = true },
		}
	end

	local function getV2UpperArmSpecs(isKnuckle)
		if isKnuckle then
			return {
				{ partType = "Ball",     size = V(0.48, 0.48, 0.48) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
				{ partType = "Wedge",    size = V(0.68, 0.42, 0.66) * S, color = PALETTE.DEEP_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.04 * S, -0.08 * S, 0) * angles(0, 0, -18) },
				{ partType = "Normal",   size = V(0.50, 0.76, 0.52) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.50 * S, 0) },
				{ partType = "Normal",   size = V(0.22, 0.56, 0.26) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(-0.18 * S, -0.54 * S, -0.14 * S) },
				{ partType = "Cylinder", size = V(0.40, 0.30, 0.30) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -V2_UPPER_ARM_LEN, 0) },
			}
		end
		return {
			{ partType = "Ball",     size = V(0.44, 0.44, 0.44) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Wedge",    size = V(0.60, 0.36, 0.60) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.10 * S, 0) * angles(0, 0, 16) },
			{ partType = "Normal",   size = V(0.46, 0.74, 0.48) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.50 * S, 0) },
			{ partType = "Normal",   size = V(0.20, 0.56, 0.24) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.54 * S, -0.20 * S) },
			{ partType = "Cylinder", size = V(0.36, 0.28, 0.28) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -V2_UPPER_ARM_LEN, 0) },
		}
	end

	local function getV2ForearmSpecs(isKnuckle)
		if isKnuckle then
			return {
				{ partType = "Ball",     size = V(0.36, 0.36, 0.36) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
				{ partType = "Normal",   size = V(0.60, 0.88, 0.62) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.48 * S, 0) },
				{ partType = "Normal",   size = V(0.64, 0.32, 0.66) * S, color = PALETTE.DEEP_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.78 * S, -0.02 * S) },
				{ partType = "Normal",   size = V(0.26, 0.42, 0.14) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.44 * S, -0.28 * S) },
				{ partType = "Cylinder", size = V(0.34, 0.12, 0.12) * S, color = PALETTE.SHOTGUN_ORANGE, mat = Enum.Material.Neon, relCF = C(0, -0.44 * S, -0.32 * S) * angles(0, 0, 90), knuckleShell = true },
				{ partType = "Cylinder", size = V(0.56, 0.16, 0.16) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(-0.14 * S, -0.18 * S, 0.38 * S) * angles(52, 0, 0) },
				{ partType = "Cylinder", size = V(0.56, 0.16, 0.16) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0.14 * S, -0.18 * S, 0.38 * S) * angles(52, 0, 0) },
				{ partType = "Cylinder", size = V(0.12, 0.12, 0.12) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(-0.14 * S, -0.02 * S, 0.56 * S) * angles(52, 0, 0) },
				{ partType = "Cylinder", size = V(0.12, 0.12, 0.12) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0.14 * S, -0.02 * S, 0.56 * S) * angles(52, 0, 0) },
			}
		end
		return {
			{ partType = "Ball",     size = V(0.30, 0.30, 0.30) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.44, 0.80, 0.46) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.48 * S, 0) },
			{ partType = "Normal",   size = V(0.48, 0.22, 0.50) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.84 * S, 0) },
			{ partType = "Cylinder", size = V(0.48, 0.15, 0.15) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.46 * S, 0.22 * S) * angles(0, 0, 90) },
		}
	end

	local function getV2HandSpecs(isKnuckle)
		if isKnuckle then
			return {
				{ partType = "Normal",   size = V(0.52, 0.38, 0.54) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.18 * S, 0) },
				{ partType = "Normal",   size = V(0.58, 0.24, 0.58) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.34 * S, -0.02 * S) },
				{ partType = "Cylinder", size = V(0.34, 0.16, 0.16) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(-0.15 * S, -0.34 * S, -0.32 * S) * angles(0, 90, 0) },
				{ partType = "Cylinder", size = V(0.34, 0.16, 0.16) * S, color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.15 * S, -0.34 * S, -0.32 * S) * angles(0, 90, 0) },
				{ partType = "Normal",   size = V(0.24, 0.12, 0.10) * S, color = PALETTE.KNUCKLE_BLAST, mat = Enum.Material.Neon, relCF = C(0, -0.34 * S, -0.38 * S), knuckleGlow = true },
				{ partType = "Wedge",    size = V(0.13, 0.44, 0.22) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(-0.18 * S, -0.60 * S, -0.08 * S) * angles(165, 0, 0) },
				{ partType = "Wedge",    size = V(0.14, 0.48, 0.22) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.62 * S, -0.10 * S) * angles(165, 0, 0) },
				{ partType = "Wedge",    size = V(0.13, 0.44, 0.22) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0.18 * S, -0.60 * S, -0.08 * S) * angles(165, 0, 0) },
				{ partType = "Wedge",    size = V(0.14, 0.34, 0.18) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0.28 * S, -0.42 * S, -0.14 * S) * angles(140, 0, -24) },
			}
		end
		return {
			{ partType = "Normal", size = V(0.38, 0.36, 0.42) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.18 * S, 0) },
			{ partType = "Normal", size = V(0.44, 0.22, 0.46) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.35 * S, -0.02 * S) },
			{ partType = "Normal", size = V(0.18, 0.28, 0.20) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.12 * S, -0.43 * S, -0.06 * S) },
		}
	end

	local function getV2ThighSpecs()
		return {
			{ partType = "Ball",     size = V(0.45, 0.45, 0.45) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.64, 0.96, 0.64) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56 * S, 0) },
			{ partType = "Wedge",    size = V(0.56, 0.40, 0.24) * S, color = PALETTE.LIGHT_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.42 * S, -0.35 * S) * angles(8, 0, 0) },
			{ partType = "Normal",   size = V(0.18, 0.62, 0.11) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.60 * S, -0.31 * S) },
			{ partType = "Cylinder", size = V(0.40, 0.32, 0.32) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -V2_THIGH_LEN, 0) },
		}
	end

	local function getV2ShinSpecs()
		return {
			{ partType = "Ball",     size = V(0.35, 0.35, 0.35) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.54, 0.98, 0.54) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56 * S, 0) },
			{ partType = "Wedge",    size = V(0.44, 0.50, 0.30) * S, color = PALETTE.LIGHT_RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.14 * S, -0.28 * S) * angles(-14, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.72, 0.11) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.62 * S, -0.25 * S) },
			{ partType = "Cylinder", size = V(0.62, 0.15, 0.15) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.54 * S, 0.28 * S) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.30, 0.26, 0.26) * S, color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -V2_SHIN_LEN, 0) },
		}
	end

	local function getV2FootSpecs()
		return {
			{ partType = "Normal", size = V(0.42, 0.20, 0.52) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.10 * S, -0.06 * S) },
			{ partType = "Normal", size = V(0.48, 0.18, 0.74) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.25 * S, -0.18 * S) },
			{ partType = "Wedge",  size = V(0.44, 0.18, 0.38) * S, color = PALETTE.RED_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24 * S, -0.58 * S) },
			{ partType = "Normal", size = V(0.42, 0.08, 0.76) * S, color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.34 * S, -0.26 * S) },
			{ partType = "Normal", size = V(0.32, 0.20, 0.30) * S, color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.23 * S, 0.22 * S) * angles(20, 0, 0) },
		}
	end

	local function getPiercerGunSpecs()
		return {
			{ partType = "Normal",   size = V(0.19, 0.25, 0.50) * S, color = PALETTE.BLACK_TRIM,   mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24 * S, 0.04 * S) * angles(-16, 0, 0) },
			{ partType = "Normal",   size = V(0.22, 0.28, 0.10) * S, color = PALETTE.SILVER_TRIM,  mat = Enum.Material.Metal,         relCF = C(0, -0.16 * S, 0.28 * S) * angles(-16, 0, 0) },
			{ partType = "Normal",   size = V(0.23, 0.60, 0.21) * S, color = PALETTE.DARK_METAL,   mat = Enum.Material.Metal,         relCF = C(0, -0.46 * S, -0.14 * S) },
			{ partType = "Cylinder", size = V(0.34, 0.32, 0.32) * S, color = PALETTE.GUN_STEEL,    mat = Enum.Material.Metal,         relCF = C(0, -0.54 * S, -0.28 * S) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.23, 0.88, 0.25) * S, color = PALETTE.GUN_STEEL,    mat = Enum.Material.Metal,         relCF = C(0, -1.12 * S, -0.29 * S) },
			{ partType = "Normal",   size = V(0.17, 0.82, 0.10) * S, color = PALETTE.RED_ARMOR,    mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.10 * S, -0.44 * S) },
			{ partType = "Normal",   size = V(0.16, 0.70, 0.13) * S, color = PALETTE.BLACK_TRIM,   mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.06 * S, -0.14 * S) },
			{ partType = "Cylinder", size = V(0.15, 0.17, 0.17) * S, color = PALETTE.BLACK_TRIM,   mat = Enum.Material.Metal,         relCF = C(0, -1.60 * S, -0.29 * S) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.26, 0.68, 0.06) * S, color = PALETTE.PIERCER_BLUE, mat = Enum.Material.Neon,          relCF = C(0, -1.12 * S, -0.29 * S), gunNeon = true },
			{ partType = "Normal",   size = V(0.15, 0.05, 0.12) * S, color = PALETTE.PIERCER_BLUE, mat = Enum.Material.Neon,          relCF = C(0, -0.17 * S, -0.34 * S), gunNeon = true },
		}
	end

	local function getShotgunSpecs()
		return {
			{ partType = "Normal",   size = V(0.20, 0.26, 0.50) * S, color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24 * S, 0.04 * S) * angles(-14, 0, 0) },
			{ partType = "Normal",   size = V(0.32, 0.74, 0.36) * S, color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal,         relCF = C(0, -0.58 * S, -0.16 * S) },
			{ partType = "Normal",   size = V(0.35, 0.42, 0.18) * S, color = PALETTE.RED_ARMOR,      mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.62 * S, -0.36 * S) },
			{ partType = "Cylinder", size = V(0.96, 0.16, 0.16) * S, color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal,         relCF = C(-0.09 * S, -1.36 * S, -0.28 * S) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.96, 0.16, 0.16) * S, color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal,         relCF = C(0.09 * S, -1.36 * S, -0.28 * S) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.28, 0.62, 0.16) * S, color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.24 * S, -0.12 * S) },
			{ partType = "Normal",   size = V(0.36, 0.50, 0.10) * S, color = PALETTE.SHOTGUN_ORANGE, mat = Enum.Material.Neon,          relCF = C(0, -1.20 * S, -0.28 * S), gunNeon = true },
			{ partType = "Normal",   size = V(0.16, 0.10, 0.08) * S, color = PALETTE.SHOTGUN_ORANGE, mat = Enum.Material.Neon,          relCF = C(0, -0.32 * S, -0.40 * S), gunNeon = true },
		}
	end

	-------------------------------------------------------------------
	-- TARGETING & COR DINÂMICA DAS ASAS (CLAIR DE LUNE)
	-------------------------------------------------------------------
	local function findAimTarget(c, originPos, aimDir, maxRange)
		local bestPos, bestChar, bestDist = nil, nil, maxRange
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tPart = model.Parent:FindFirstChild("Head") or Core.getTargetRoot(model.Parent)
			if tPart and tPart:IsA("BasePart") then
				local diff = tPart.Position - originPos
				local d = diff.Magnitude
				if d > 1.5 and d < bestDist and diff.Unit:Dot(aimDir) > 0.72 then
					bestDist, bestPos, bestChar = d, tPart.Position, model.Parent
				end
			end
		end
		if bestPos then return bestPos, bestChar end

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local ignore = { c }
		local st = Core.getState()
		for _, p in ipairs(st.proxyParts) do if p and p.Parent then ignore[#ignore + 1] = p end end
		rp.FilterDescendantsInstances = ignore
		local res = workspace:Raycast(originPos, aimDir * maxRange, rp)
		if res then return res.Position, nil end
		return originPos + aimDir * maxRange, nil
	end

	local function findNearestMeleeTargets(c, originPos, radius)
		local hits = {}
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tHRP = Core.getTargetRoot(model.Parent)
			if tHRP and tHRP:IsA("BasePart") then
				local diff = tHRP.Position - originPos
				if diff.Magnitude <= radius then
					hits[#hits + 1] = { char = model.Parent, hrp = tHRP, dist = diff.Magnitude, dir = diff }
				end
			end
		end
		table.sort(hits, function(a, b) return a.dist < b.dist end)
		return hits
	end

	-------------------------------------------------------------------
	-- MÓDULO EXPORTADO PARA O CORE (V2 = MAIS PESADO E PUNCHY NO AR)
	-------------------------------------------------------------------
	Core.start({
		id = "v2",
		name = "V2",
		config = {
			RENDER_NAME = "F3X_V2_Reanim",
			HUD_RENDER_NAME = "F3X_V2_3DHUD",
			SCALE = S,
			SOLE_DEPTH = V2_SOLE_DEPTH,
			WALK_SPEED = 17,
			SPRINT_SPEED = 35,
			ENABLE_AIR_MOVEMENT = true,
			JUMP_POWER = 52,
			AIR_GRAVITY_CANCEL = 0.30,
			GLIDE_GRAVITY_CANCEL = 0.56,
			GLIDE_MAX_FALL = 20,
			AIR_STRAFE_ACCEL = 44,
			AIR_DRAG = 0.36,
			DASH_JUMP_MULT = 0.96,
			WALL_JUMP_ENABLED = true,
			MAX_WALL_JUMPS = 3,
			WALL_JUMP_UP = 56,
			WALL_JUMP_PUSH = 48,
			SLAM_SPEED = 114,
			SLAM_STORAGE_JUMP = 116,
			HUD_UNIT_HEADER = "V2 // CLAIR DE LUNE UNIT",
			HUD_WEAPON_TITLE = "PIERCER REVOLVER",
			HUD_WEAPON_COLOR = PALETTE.PIERCER_BLUE,
			HUD_KEY_HINT = "[E] FIRE  [F] KNUCKLEBLASTER  [R] SWAP WEAPON",
			HUD_PIP_COLOR = PALETTE.PIERCER_BLUE,
			MOBILE_PRIMARY_LABEL = "FIRE",
			MOBILE_PRIMARY_COLOR = PALETTE.PIERCER_BLUE,
			MOBILE_SECONDARY_LABEL = "BLAST",
			MOBILE_SECONDARY_COLOR = PALETTE.KNUCKLE_BLAST,
			MOBILE_TERTIARY_LABEL = "SWAP",
			MOBILE_TERTIARY_COLOR = PALETTE.SHOTGUN_ORANGE,
		},

		initState = function()
			local STATE = Core.getState()
			STATE.custom.weapon = "piercer"
			STATE.custom.fireAttack = { active = false, lastUsed = 0, startTime = 0, weapon = "piercer" }
			STATE.custom.knuckleAttack = { active = false, lastUsed = 0, startTime = 0, hitTriggered = false, blastTriggered = false }
			STATE.custom.enragedUntil = 0
			STATE.custom.wingColorKey = "GOLD"
			STATE.custom.lastWingSyncAt = 0
		end,

		buildModel = function(_, _, _, _, torsoInitCF)
			local specs = {}
			local chestCF = torsoInitCF * C(0, V2_CHEST_OFFSET, 0)
			local abdomenCF = torsoInitCF * C(0, V2_ABDOMEN_OFFSET, 0)
			local pelvisCF = torsoInitCF * C(0, V2_PELVIS_OFFSET, 0)
			local headInitCF = chestCF * C(0, 1.06 * S, -0.06 * S)

			for _, hp in ipairs(getV2HeadSpecs()) do
				specs[#specs + 1] = {
					kind = "v2head", partType = hp.partType, relCF = hp.relCF, origCF = headInitCF * hp.relCF,
					origSize = hp.size, origColor = hp.color, origMaterial = hp.mat, origTrans = 0, origReflectance = 0,
					light = hp.light, lightColor = hp.lightColor,
				}
			end

			local function addV2(kind, list, parentCF, key)
				for _, sp in ipairs(list) do
					specs[#specs + 1] = {
						kind = kind, key = key, partType = sp.partType, relCF = sp.relCF, origCF = parentCF * sp.relCF,
						origSize = sp.size, origColor = sp.color, origMaterial = sp.mat, origTrans = 0, origReflectance = 0,
						light = sp.light, lightColor = sp.lightColor, gunNeon = sp.gunNeon,
						tag = sp.wingNeon and "wingNeon" or (sp.knuckleGlow and "knuckleGlow" or nil),
					}
				end
			end

			addV2("v2chest", getV2ChestSpecs(), chestCF, "chest")
			addV2("v2chest", getV2AbdomenSpecs(), abdomenCF, "abdomen")
			addV2("v2chest", getV2PelvisSpecs(), pelvisCF, "pelvis")

			local shoulderL = chestCF * C(-1.12 * S, 0.24 * S, 0)
			local shoulderR = chestCF * C(1.12 * S, 0.24 * S, 0)
			local elbowL, elbowR = shoulderL * C(0, -V2_UPPER_ARM_LEN, 0), shoulderR * C(0, -V2_UPPER_ARM_LEN, 0)
			local wristL, wristR = elbowL * C(0, -V2_FOREARM_LEN, 0), elbowR * C(0, -V2_FOREARM_LEN, 0)

			addV2("v2upperArm", getV2UpperArmSpecs(true), shoulderL, "lUpperArm")
			addV2("v2upperArm", getV2UpperArmSpecs(false), shoulderR, "rUpperArm")
			addV2("v2forearm", getV2ForearmSpecs(true), elbowL, "lForearm")
			addV2("v2forearm", getV2ForearmSpecs(false), elbowR, "rForearm")
			addV2("v2hand", getV2HandSpecs(true), wristL, "lHand")
			addV2("v2hand", getV2HandSpecs(false), wristR, "rHand")

			local hipL = pelvisCF * C(-0.48 * S, V2_HIP_Y, 0)
			local hipR = pelvisCF * C(0.48 * S, V2_HIP_Y, 0)
			local kneeL, kneeR = hipL * C(0, -V2_THIGH_LEN, 0), hipR * C(0, -V2_THIGH_LEN, 0)
			local ankleL, ankleR = kneeL * C(0, -V2_SHIN_LEN, 0), kneeR * C(0, -V2_SHIN_LEN, 0)

			addV2("v2thigh", getV2ThighSpecs(), hipL, "lThigh")
			addV2("v2thigh", getV2ThighSpecs(), hipR, "rThigh")
			addV2("v2shin", getV2ShinSpecs(), kneeL, "lShin")
			addV2("v2shin", getV2ShinSpecs(), kneeR, "rShin")
			addV2("v2foot", getV2FootSpecs(), ankleL, "lFoot")
			addV2("v2foot", getV2FootSpecs(), ankleR, "rFoot")

			for _, cp in ipairs(getV2CoreSpecs()) do
				specs[#specs + 1] = {
					kind = "v2core", partType = cp.partType, relCF = cp.relCF, origCF = chestCF * cp.relCF,
					origSize = cp.size, origColor = cp.color, origMaterial = cp.mat, origTrans = 0, origReflectance = 0,
					light = cp.light, lightColor = cp.lightColor,
				}
			end

			local singleWing = getV2SingleWingParts()
			for _, side in ipairs({ -1, 1 }) do
				for wingIdx = 1, 4 do
					for _, wp in ipairs(singleWing) do
						local relCF = (side == -1) and mirrorRelCF(wp.relCF) or wp.relCF
						specs[#specs + 1] = {
							kind = "v2wing", side = side, wingIdx = wingIdx, partType = wp.partType, relCF = relCF,
							origCF = chestCF * relCF, origSize = wp.size, origColor = wp.color, origMaterial = wp.mat, origTrans = 0, origReflectance = 0,
							tag = wp.wingNeon and "wingNeon" or nil,
						}
					end
				end
			end

			for _, gp in ipairs(getPiercerGunSpecs()) do
				specs[#specs + 1] = {
					kind = "v2piercer", partType = gp.partType, relCF = gp.relCF, origCF = wristR * GUN_MOUNT_REL * gp.relCF,
					origSize = gp.size, origColor = gp.color, origMaterial = gp.mat, origTrans = 0, origReflectance = 0, gunNeon = gp.gunNeon,
				}
			end

			for _, gp in ipairs(getShotgunSpecs()) do
				specs[#specs + 1] = {
					kind = "v2shotgun", partType = gp.partType, relCF = gp.relCF, origCF = PARK_CF,
					origSize = gp.size, origColor = gp.color, origMaterial = gp.mat, origTrans = 0, origReflectance = 0, gunNeon = gp.gunNeon,
				}
			end

			return specs
		end,

		onPrimary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local fa = STATE.custom.fireAttack
			local wpn = STATE.custom.weapon
			local cd = (wpn == "shotgun") and SHOTGUN_COOLDOWN or PIERCER_COOLDOWN
			local now = os.clock()
			if fa.active or (now - fa.lastUsed) < cd then return end

			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			fa.active, fa.lastUsed, fa.startTime, fa.weapon = true, now, now, wpn

			local cam = workspace.CurrentCamera
			local headReal = c:FindFirstChild("Head")
			local inFP = cam and headReal and ((cam.CFrame.Position - headReal.Position).Magnitude < Core.getConfig().FIRST_PERSON_HIDE_DIST) or false
			local aimDir = (inFP and cam) and cam.CFrame.LookVector or ((cam and cam.CFrame.LookVector) or hrp.CFrame.LookVector)
			local origin = hrp.Position + V(0, 0.8 * S, 0) + aimDir * (1.8 * S)

			local gunRoot = STATE.custom.lastGunRoot
			if gunRoot then
				local muz = (wpn == "shotgun") and SHOTGUN_MUZZLE_LOCAL or PIERCER_MUZZLE_LOCAL
				origin = (gunRoot * muz).Position
			end

			if wpn == "piercer" then
				local targetPos, targetChar = findAimTarget(c, origin, aimDir, PIERCER_RANGE)
				local mid = origin:Lerp(targetPos, 0.5)
				Core.fireDualBeams(origin, mid, targetPos, PALETTE.PIERCER_BLUE, PALETTE.PIERCER_BLUE, 0.28, 0.34, false, 0.24)
				Core.playSFX("SHATTER", 1.05, 0.95, "PARRY")
				Core.spawnFlash(origin, PALETTE.PIERCER_BLUE, 0.9, 3.4, 0.16)
				Core.spawnImpactFlash(targetPos, PALETTE.PIERCER_BLUE, 1.0, 4.8, 0.22)
				STATE.camShake = math.max(STATE.camShake, 0.35)
				STATE.fovKick = math.max(STATE.fovKick, 6)
				if targetChar then
					Core.addStyleBonus("PIERCER BEAM", 210, PALETTE.PIERCER_BLUE)
					Core.applyF3XKnockback(targetChar, targetPos - origin, PIERCER_KB)
				end
			else
				local targetPos, targetChar = findAimTarget(c, origin, aimDir, SHOTGUN_RANGE)
				local pelletLeft = targetPos + (hrp.CFrame.RightVector * -2.2)
				local pelletRight = targetPos + (hrp.CFrame.RightVector * 2.2)
				Core.fireDualBeams(origin, pelletLeft, pelletRight, PALETTE.SHOTGUN_ORANGE, PALETTE.YELLOW_NEON, 0.42, 0.24, false, 0.22)
				Core.playSFX("PUNCH", 0.72, 1.15, "PARRY")
				Core.spawnFlash(origin, PALETTE.SHOTGUN_ORANGE, 1.3, 4.6, 0.18)
				Core.spawnImpactFlash(targetPos, PALETTE.SHOTGUN_ORANGE, 1.4, 6.2, 0.24)
				STATE.camShake = math.max(STATE.camShake, 0.58)
				STATE.fovKick = math.max(STATE.fovKick, 9)
				if targetChar then
					Core.addStyleBonus("CORE BUCKSHOT", 240, PALETTE.SHOTGUN_ORANGE)
					Core.applyF3XKnockback(targetChar, targetPos - origin, SHOTGUN_KB)
				else
					for _, hit in ipairs(findNearestMeleeTargets(c, targetPos, 8.5)) do
						Core.addStyleBonus("CORE SPLASH", 160, PALETTE.SHOTGUN_ORANGE)
						Core.applyF3XKnockback(hit.char, hit.hrp.Position - origin, SHOTGUN_KB)
					end
				end
			end
		end,

		onSecondary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local ka = STATE.custom.knuckleAttack
			local now = os.clock()
			if ka.active or (now - ka.lastUsed) < KNUCKLE_COOLDOWN then return end
			ka.active, ka.lastUsed, ka.startTime = true, now, now
			ka.hitTriggered, ka.blastTriggered = false, false
		end,

		onTertiary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			STATE.custom.weapon = (STATE.custom.weapon == "piercer") and "shotgun" or "piercer"
			Core.playSFX("COIN_FLIP", 0.9, 0.8, "PARRY")
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
			local groundOffsetY = V2_SOLE_DEPTH - realSoleDepth

			local camPitch, camYawLocal = 0, 0
			if CONFIG.ENABLE_HEAD_AIM_TRACKING and cam then
				local camLocalLook = hrp.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)
				camPitch = clamp(math.asin(clamp(camLocalLook.Y, -0.85, 0.85)) * 180 / math.pi, -45, 55)
				camYawLocal = clamp(math.atan2(-camLocalLook.X, -camLocalLook.Z) * 180 / math.pi, -35, 35)
			end

			local torsoY = groundOffsetY + math.sin(t * 2.5) * 0.05 * idleWeight + math.abs(sinW) * 0.16 * STATE.walkBlend * (1 + STATE.sprintBlend * 0.4) - STATE.landRecover * 0.30
			local idleYaw = 14 * idleWeight
			local walkTwist = cosW * (6 + STATE.sprintBlend * 7) * STATE.walkBlend
			local torsoPitch = -STATE.localFwd * (8 + STATE.sprintBlend * 11) + (STATE.landRecover * -12) + STATE.airBlend * clamp(-STATE.vertVel * 0.35, -14, 16)
			local torsoRoll = -STATE.localStrafe * 9 - STATE.turnRate * 1.4

			if STATE.slide.active and not isAir then
				torsoY -= 1.50
				torsoPitch = 38
			elseif STATE.slam.active and isAir then
				torsoPitch = -24
				torsoRoll = 0
			elseif STATE.isGliding and isAir then
				torsoPitch -= 8
			end

			local dashTilt, dashRoll = 0, 0
			if STATE.dash.active then
				local dEl = now - STATE.dash.startTime
				if dEl < CONFIG.DASH_DURATION then
					local envD = math.sin((dEl / CONFIG.DASH_DURATION) * math.pi)
					dashTilt, dashRoll = STATE.dash.localDir.Z * 26 * envD, -STATE.dash.localDir.X * 26 * envD
					torsoY -= 0.22 * envD
				end
			end

			local headRX = math.sin(t * 2.5 - 0.6) * 2.5 * idleWeight + camPitch * 0.65 - torsoPitch * 0.5
			local headRY = math.sin(t * 0.9) * 6.0 * idleWeight + camYawLocal * 0.65 - idleYaw * 0.5
			local headRZ = -torsoRoll * 0.4

			local lHipRX = (12 * idleWeight) + (sinW * (34 + STATE.sprintBlend * 22) * STATE.walkBlend * clamp(STATE.localFwd, -1, 1.4))
			local rHipRX = (-14 * idleWeight) - (sinW * (34 + STATE.sprintBlend * 22) * STATE.walkBlend * clamp(STATE.localFwd, -1, 1.4))
			local lHipRZ = (-5 * idleWeight) + (sinW * 24 * STATE.walkBlend * STATE.localStrafe)
			local rHipRZ = (5 * idleWeight) - (sinW * 24 * STATE.walkBlend * STATE.localStrafe)
			local lHipRY, rHipRY = 8 * idleWeight, -8 * idleWeight

			local lKneeRX = -8 - math.max(0, sinW) * (36 + STATE.sprintBlend * 20) * STATE.walkBlend
			local rKneeRX = -8 - math.max(0, -sinW) * (36 + STATE.sprintBlend * 20) * STATE.walkBlend
			local lAnkleRX = 4 + (sinW * 14 * STATE.walkBlend)
			local rAnkleRX = 4 - (sinW * 14 * STATE.walkBlend)

			if STATE.slide.active and not isAir then
				lHipRX, rHipRX = 64, -18
				lHipRZ, rHipRZ = -8, 12
				lKneeRX, rKneeRX = -18, -74
				lAnkleRX, rAnkleRX = -24, 18
			elseif STATE.airBlend > 0.01 then
				if STATE.slam.active then
					lHipRX = lerp(lHipRX, 64, STATE.airBlend)
					rHipRX = lerp(rHipRX, 70, STATE.airBlend)
					lHipRZ, rHipRZ = lerp(lHipRZ, -6, STATE.airBlend), lerp(rHipRZ, 6, STATE.airBlend)
					lKneeRX = lerp(lKneeRX, -98, STATE.airBlend)
					rKneeRX = lerp(rKneeRX, -106, STATE.airBlend)
					lAnkleRX, rAnkleRX = lerp(lAnkleRX, 28, STATE.airBlend), lerp(rAnkleRX, 28, STATE.airBlend)
				elseif STATE.isGliding then
					lHipRX = lerp(lHipRX, 16, STATE.airBlend)
					rHipRX = lerp(rHipRX, 26, STATE.airBlend)
					lHipRZ, rHipRZ = lerp(lHipRZ, -10, STATE.airBlend), lerp(rHipRZ, 10, STATE.airBlend)
					lKneeRX = lerp(lKneeRX, -26, STATE.airBlend)
					rKneeRX = lerp(rKneeRX, -44, STATE.airBlend)
					lAnkleRX, rAnkleRX = lerp(lAnkleRX, 22, STATE.airBlend), lerp(rAnkleRX, 22, STATE.airBlend)
				else
					local riseT = clamp((STATE.vertVel + 16) / 40, 0, 1)
					lHipRX = lerp(lHipRX, lerp(22, 42, riseT), STATE.airBlend)
					rHipRX = lerp(rHipRX, lerp(-16, -28, riseT), STATE.airBlend)
					lHipRZ, rHipRZ = lerp(lHipRZ, -8, STATE.airBlend), lerp(rHipRZ, 8, STATE.airBlend)
					lKneeRX = lerp(lKneeRX, lerp(-32, -74, riseT), STATE.airBlend)
					rKneeRX = lerp(rKneeRX, lerp(-20, -48, riseT), STATE.airBlend)
					lAnkleRX, rAnkleRX = lerp(lAnkleRX, 24, STATE.airBlend), lerp(rAnkleRX, 18, STATE.airBlend)
				end
			end

			local lArmRX = (-14 + math.sin(t * 2.5 + 0.5) * 3.5) * idleWeight - (sinW * (26 + STATE.sprintBlend * 24) * STATE.walkBlend)
			local lArmRY = 10 * idleWeight
			local lArmRZ = (-11 - math.sin(t * 1.8) * 1.5) * idleWeight - STATE.airBlend * 28

			local rArmRX = (74 + math.sin(t * 2.5) * 2.5) * idleWeight + (34 + cosW * 8) * STATE.walkBlend + (STATE.sprintBlend * 14) + camPitch * 0.7
			local rArmRY = (-12 * idleWeight) + camYawLocal * 0.35
			local rArmRZ = 6 * idleWeight + STATE.airBlend * 16
			local lElbowRX, rElbowRX = 26, 18
			local lWristRX, lWristRY, lWristRZ = 0, 0, 0
			local rWristRX, rWristRY, rWristRZ = 0, 0, 0
			local torsoYawMod = 0

			if STATE.isGliding and isAir then
				lArmRX, lArmRZ, lElbowRX = -16, -42, 16
			elseif STATE.slam.active and isAir then
				lArmRX, lArmRZ, lElbowRX = 48, -12, 64
				rArmRX, rElbowRX = 54 + camPitch * 0.4, 58
			end

			local ka = STATE.custom.knuckleAttack
			if ka.active then
				local el = now - ka.startTime
				if el < 0.11 then
					local k = easeOutQuad(el / 0.11)
					lArmRX, lArmRY, lArmRZ = lerp(lArmRX, -46, k), lerp(lArmRY, 28, k), lerp(lArmRZ, -26, k)
					torsoYawMod -= 26 * k
				elseif el < 0.30 then
					local k = easeOutBack((el - 0.11) / 0.14)
					lArmRX, lArmRY, lArmRZ = lerp(-46, 102, k), lerp(28, -16, k), lerp(-26, 8, k)
					lElbowRX = lerp(lElbowRX, 6, k)
					lWristRX = lerp(lWristRX, 14, k)
					rArmRX = lerp(rArmRX, 14, k)
					torsoYawMod += 36 * k
					torsoPitch -= 14 * k

					if not ka.hitTriggered and el >= 0.14 then
						ka.hitTriggered = true
						local fistWorld = (hrp.CFrame * C(-1.1 * S, 0.5 * S, -2.6 * S)).Position
						local hits = findNearestMeleeTargets(c, fistWorld, KNUCKLE_RANGE)
						if #hits > 0 then
							STATE.custom.enragedUntil = now + 4.5
							Core.playSFX("PARRY", 0.78, 1.15)
							Core.triggerHitstop(0.13, PALETTE.KNUCKLE_BLAST)
							Core.spawnImpactFlash(fistWorld, PALETTE.KNUCKLE_BLAST, 1.8, 9.0, 0.30)
							Core.spawnShockwaveRing(fistWorld, hrp.CFrame.LookVector, PALETTE.KNUCKLE_BLAST, 1.4, 12.0, 0.32)
							Core.addStyleBonus("KNUCKLEBLASTER", 300, PALETTE.KNUCKLE_BLAST)
							for i, h in ipairs(hits) do
								local kbPower = (i == 1) and KNUCKLE_DIRECT_KB or KNUCKLE_AOE_KB
								Core.applyF3XKnockback(h.char, h.hrp.Position - hrp.Position, kbPower)
							end
						else
							Core.playSFX("PUNCH", 0.75, 1.1, "PARRY")
							Core.spawnImpactFlash(fistWorld, PALETTE.KNUCKLE_BLAST, 1.2, 6.5, 0.24)
							Core.spawnShockwaveRing(fistWorld, hrp.CFrame.LookVector, PALETTE.KNUCKLE_BLAST, 1.0, 8.5, 0.26)
						end
					end
				elseif el < 0.56 then
					local k = easeOutQuad((el - 0.30) / 0.26)
					lArmRX, lArmRY, lArmRZ = lerp(102, lArmRX, k), lerp(-16, lArmRY, k), lerp(8, lArmRZ, k)
					torsoYawMod += 36 * (1 - k)
					if not ka.blastTriggered and el >= 0.36 then
						ka.blastTriggered = true
						Core.playSFX("SHATTER", 0.85, 0.65, "COIN_FLIP")
					end
				else
					ka.active = false
				end
			end

			local fa = STATE.custom.fireAttack
			if fa.active then
				local el = now - fa.startTime
				local totalDur = (fa.weapon == "shotgun") and 0.32 or 0.22
				if el < totalDur then
					local k = el / totalDur
					local peak = (fa.weapon == "shotgun") and 42 or 26
					local rec = (k < 0.35) and (peak * easeOutQuad(k / 0.35)) or (peak * (1 - easeOutQuad((k - 0.35) / 0.65)))
					rArmRX = 92 + camPitch * 0.65 + rec
					rElbowRX = 16 + rec * 0.4
				else
					fa.active = false
				end
			end

			local torsoCF = hrp.CFrame * C(0, torsoY, 0) * angles(torsoPitch + dashTilt, idleYaw + walkTwist + torsoYawMod, torsoRoll + dashRoll)
			local chestCF = torsoCF * C(0, V2_CHEST_OFFSET, 0)
			local abdomenCF = torsoCF * C(0, V2_ABDOMEN_OFFSET, 0) * angles(torsoPitch * 0.3, -walkTwist * 0.35, torsoRoll * 0.25)
			local pelvisCF = torsoCF * C(0, V2_PELVIS_OFFSET, 0) * angles(-torsoPitch * 0.18, 0, -torsoRoll * 0.35)

			local shoulderLCF = chestCF * C(-1.12 * S, 0.24 * S, 0) * angles(lArmRX, lArmRY, lArmRZ)
			local shoulderRCF = chestCF * C(1.12 * S, 0.24 * S, 0) * angles(rArmRX, rArmRY, rArmRZ)
			local elbowLCF = shoulderLCF * C(0, -V2_UPPER_ARM_LEN, 0) * angles(lElbowRX, 0, 0)
			local elbowRCF = shoulderRCF * C(0, -V2_UPPER_ARM_LEN, 0) * angles(rElbowRX, 0, 0)
			local wristLCF = elbowLCF * C(0, -V2_FOREARM_LEN, 0) * angles(lWristRX, lWristRY, lWristRZ)
			local wristRCF = elbowRCF * C(0, -V2_FOREARM_LEN, 0) * angles(rWristRX, rWristRY, rWristRZ)

			local hipLCF = pelvisCF * C(-0.48 * S, V2_HIP_Y, 0) * angles(lHipRX, lHipRY, lHipRZ)
			local hipRCF = pelvisCF * C(0.48 * S, V2_HIP_Y, 0) * angles(rHipRX, rHipRY, rHipRZ)
			local kneeLCF = hipLCF * C(0, -V2_THIGH_LEN, 0) * angles(lKneeRX, 0, 0)
			local kneeRCF = hipRCF * C(0, -V2_THIGH_LEN, 0) * angles(rKneeRX, 0, 0)
			local ankleLCF = kneeLCF * C(0, -V2_SHIN_LEN, 0) * angles(lAnkleRX, 0, 0)
			local ankleRCF = kneeRCF * C(0, -V2_SHIN_LEN, 0) * angles(rAnkleRX, 0, 0)

			if inFP and cam and STATE.fpArms then
				local bobX = cosW * 0.03 * STATE.walkBlend
				local bobY = math.abs(sinW) * 0.04 * STATE.walkBlend
				local fpRecoil = 0
				if fa.active then
					local el = now - fa.startTime
					local dur = (fa.weapon == "shotgun") and 0.30 or 0.20
					if el < dur then
						local k = el / dur
						fpRecoil = (k < 0.35) and (28 * easeOutQuad(k / 0.35)) or (28 * (1 - easeOutQuad((k - 0.35) / 0.65)))
					end
				end
				local punchReach = ka.active and math.sin(clamp((now - ka.startTime) / 0.32, 0, 1) * math.pi) * 1.25 or 0

				local camBase = cam.CFrame * C(0, -0.98 * S, 0.12)
				shoulderRCF = camBase * C(0.44 * S + bobX, 0.12 - bobY, 0.22) * angles(58 + fpRecoil * 0.5, 26, -14)
				elbowRCF = shoulderRCF * C(0, -V2_UPPER_ARM_LEN, 0) * angles(52 + fpRecoil, 0, 6)
				wristRCF = elbowRCF * C(0, -V2_FOREARM_LEN, 0) * angles(-46 + fpRecoil * 0.4, 8, -10)

				shoulderLCF = camBase * C(-0.44 * S - bobX, 0.10 - bobY, 0.18) * angles(62 - punchReach * 24, -24, 14)
				elbowLCF = shoulderLCF * C(0, -V2_UPPER_ARM_LEN, 0) * angles(46 - punchReach * 32, 0, -8)
				wristLCF = elbowLCF * C(0, -V2_FOREARM_LEN, 0) * angles(-38, -6, 10)
			end

			local J = {
				lUpperArm = shoulderLCF, rUpperArm = shoulderRCF,
				lForearm = elbowLCF, rForearm = elbowRCF,
				lHand = wristLCF, rHand = wristRCF,
				lThigh = hipLCF, rThigh = hipRCF,
				lShin = kneeLCF, rShin = kneeRCF,
				lFoot = ankleLCF, rFoot = ankleRCF,
			}

			local cfs = {
				chest = chestCF, abdomen = abdomenCF, pelvis = pelvisCF,
				["Torso"] = torsoCF,
				["Head"] = chestCF * C(0, 1.06 * S, -0.06 * S) * angles(headRX, headRY, headRZ),
				["Left Arm"] = wristLCF,
				["Right Arm"] = wristRCF,
				["Left Leg"] = ankleLCF,
				["Right Leg"] = ankleRCF,
			}

			local B = STATE.buckets
			local fpBodyHide = inFP and 1 or 0

			for _, hp in ipairs(B.v2head or {}) do
				if hp.part and hp.part.Parent then
					hp.targetCF = cfs["Head"] * hp.relCF
					hp.part.CFrame = hp.targetCF
					hp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			for _, cp in ipairs(B.v2chest or {}) do
				if cp.part and cp.part.Parent and cfs[cp.key] then
					cp.targetCF = cfs[cp.key] * cp.relCF
					cp.part.CFrame = cp.targetCF
					cp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			for _, kind in ipairs({ "v2upperArm", "v2forearm", "v2hand", "v2thigh", "v2shin", "v2foot" }) do
				for _, jp in ipairs(B[kind] or {}) do
					if jp.part and jp.part.Parent and J[jp.key] then
						jp.targetCF = J[jp.key] * jp.relCF
						jp.part.CFrame = jp.targetCF
						local hide = false
						if inFP then
							if STATE.fpArms then
								local isArm = (jp.key == "rUpperArm" or jp.key == "rForearm" or jp.key == "rHand"
									or jp.key == "lUpperArm" or jp.key == "lForearm" or jp.key == "lHand")
								hide = not isArm
							else
								hide = true
							end
						end
						jp.part.LocalTransparencyModifier = hide and 1 or 0
					end
				end
			end

			local gunRoot = wristRCF * GUN_MOUNT_REL
			STATE.custom.lastGunRoot = gunRoot
			local gunHide = (inFP and not STATE.fpArms) and 1 or 0
			local useShotgun = (STATE.custom.weapon == "shotgun")

			for _, gp in ipairs(B.v2piercer or {}) do
				if gp.part and gp.part.Parent then
					if useShotgun then
						gp.targetCF = PARK_CF
						gp.part.CFrame = PARK_CF
					else
						gp.targetCF = gunRoot * gp.relCF
						gp.part.CFrame = gp.targetCF
						gp.part.LocalTransparencyModifier = gunHide
					end
				end
			end

			for _, gp in ipairs(B.v2shotgun or {}) do
				if gp.part and gp.part.Parent then
					if useShotgun then
						gp.targetCF = gunRoot * gp.relCF
						gp.part.CFrame = gp.targetCF
						gp.part.LocalTransparencyModifier = gunHide
					else
						gp.targetCF = PARK_CF
						gp.part.CFrame = PARK_CF
					end
				end
			end

			for _, cp in ipairs(B.v2core or {}) do
				if cp.part and cp.part.Parent then
					cp.targetCF = chestCF * cp.relCF
					cp.part.CFrame = cp.targetCF
					cp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			local wantedKey, wantedCol = "GOLD", PALETTE.GOLD_WING
			if now < STATE.custom.enragedUntil or (STATE.slam.active and isAir) then
				wantedKey, wantedCol = "RED", PALETTE.RED_WING
			elseif STATE.dash.active or STATE.slide.active or STATE.isGliding or isAir then
				wantedKey, wantedCol = "GREEN", PALETTE.GREEN_WING
			elseif math.abs(STATE.localStrafe) > 0.45 then
				wantedKey, wantedCol = "BLUE", PALETTE.BLUE_WING
			end

			if wantedKey ~= STATE.custom.wingColorKey and (now - STATE.custom.lastWingSyncAt) >= 0.14 then
				STATE.custom.wingColorKey = wantedKey
				STATE.custom.lastWingSyncAt = now
				local colorPayload = {}
				for _, wp in ipairs(B.v2wing or {}) do
					if wp.tag == "wingNeon" and wp.part and wp.part.Parent then
						wp.part.Color = wantedCol
						colorPayload[#colorPayload + 1] = { Part = wp.part, Color = wantedCol, UnionColoring = true }
					end
				end
				if #colorPayload > 0 then Core.syncPartColor(colorPayload) end
			end

			local baseFan = { 48, 18, -14, -46 }
			local glideFlare = (STATE.isGliding and isAir) and 26 or 0
			local slamFold = (STATE.slam.active and isAir) and -18 or 0
			local flare = STATE.sprintBlend * 16 + STATE.airBlend * 22 + glideFlare + slamFold + (ka.active and 16 or 0) + (fa.active and 10 or 0)
			local sweepBack = 24 + STATE.walkBlend * 10 + STATE.sprintBlend * 24 + STATE.airBlend * 12 + (STATE.dash.active and 32 or 0) + ((STATE.isGliding and isAir) and -12 or 0) + ((STATE.slam.active and isAir) and 22 or 0)
			local wingRoots = {}
			for _, side in ipairs({ -1, 1 }) do
				wingRoots[side] = {}
				for idx = 1, 4 do
					local breath = (STATE.isGliding and isAir)
						and (math.sin(STATE.time * 22 - idx * 0.45) * 4.5)
						or (math.sin(STATE.time * 2.8 - idx * 0.45) * (3.0 + STATE.walkBlend * 2.5))
					wingRoots[side][idx] = chestCF * C(side * 0.38 * S, (0.50 - (idx - 1) * 0.21) * S, 0.78 * S) * angles(0, -sweepBack * side, (baseFan[idx] + flare + breath) * side)
				end
			end
			for _, wp in ipairs(B.v2wing or {}) do
				if wp.part and wp.part.Parent then
					wp.targetCF = wingRoots[wp.side][wp.wingIdx] * wp.relCF
					wp.part.CFrame = wp.targetCF
					wp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			local curCD = useShotgun and SHOTGUN_COOLDOWN or PIERCER_COOLDOWN
			return {
				weaponTitle = useShotgun and "CORE EJECT SHOTGUN" or "PIERCER REVOLVER",
				weaponColor = useShotgun and PALETTE.SHOTGUN_ORANGE or PALETTE.PIERCER_BLUE,
				chargeFrac = clamp((now - fa.lastUsed) / curCD, 0, 1),
				pipColor = useShotgun and PALETTE.SHOTGUN_ORANGE or PALETTE.PIERCER_BLUE,
				pipDimColor = useShotgun and Color3.fromRGB(130, 68, 22) or Color3.fromRGB(32, 95, 125),
			}, cfs
		end,
	})
end