-- ULTRAKILL V1 MODULE (100% MODELO ORIGINAL + MARKSMAN COIN + FEEDBACKER PARRY)
-- Carregado dinamicamente pelo loader.lua recebendo Core

return function(Core)
	local C, V = Core.C, Core.V
	local ID_CF, PARK_CF = Core.ID_CF, Core.PARK_CF
	local clamp, lerp, easeOutQuad, easeOutBack = Core.clamp, Core.lerp, Core.easeOutQuad, Core.easeOutBack
	local angles, mirrorRelCF = Core.angles, Core.mirrorRelCF

	local PALETTE = {
		BLUE_ARMOR = Color3.fromRGB(42, 82, 168),
		LIGHT_BLUE_ARMOR = Color3.fromRGB(68, 114, 212),
		DARK_METAL = Color3.fromRGB(32, 35, 43),
		GUN_STEEL = Color3.fromRGB(76, 84, 98),
		SILVER_TRIM = Color3.fromRGB(178, 188, 202),
		BLACK_TRIM = Color3.fromRGB(15, 17, 21),
		YELLOW_NEON = Color3.fromRGB(255, 208, 30),
		MARKSMAN_GREEN = Color3.fromRGB(75, 255, 130),
		COIN_GOLD = Color3.fromRGB(255, 215, 45),
		BEAM_CYAN = Color3.fromRGB(115, 235, 255),
		PARRY_FLASH = Color3.fromRGB(255, 245, 175),
		BLOOD_RED = Color3.fromRGB(185, 26, 32),
	}

	local V1_CHEST_OFFSET = 0.56
	local V1_ABDOMEN_OFFSET = -0.22
	local V1_PELVIS_OFFSET = -0.80
	local V1_HIP_Y = -0.14
	local V1_THIGH_LEN = 1.18
	local V1_SHIN_LEN = 1.16
	local V1_SOLE_DEPTH_FROM_ANKLE = 0.38
	local V1_SOLE_DEPTH = math.abs(V1_PELVIS_OFFSET) + math.abs(V1_HIP_Y) + V1_THIGH_LEN + V1_SHIN_LEN + V1_SOLE_DEPTH_FROM_ANKLE -- 3.66
	local V1_UPPER_ARM_LEN = 1.04
	local V1_FOREARM_LEN = 1.00
	local GUN_MOUNT_REL = ID_CF
	local GUN_MUZZLE_LOCAL = C(0, -1.60, -0.27)

	local COIN_COOLDOWN = 0.78
	local COIN_RANGE = 85
	local PARRY_COOLDOWN = 0.42
	local PARRY_RANGE = 11.5
	local PARRY_KNOCKBACK_POWER = { speed = 68, up = 32, spin = 12.0 }
	local COIN_KNOCKBACK_POWER = { speed = 50, up = 25, spin = 9.0 }
	local COIN_PUNCH_KNOCKBACK_POWER = { speed = 96, up = 46, spin = 16.0 }

	-------------------------------------------------------------------
	-- BLUEPRINTS EXATOS DO V1 ORIGINAL
	-------------------------------------------------------------------
	local function getV1HeadSpecs()
		return {
			{ partType = "Cylinder", size = V(0.36, 0.28, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.36, 0.06) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.36, 0.12, 0.12), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(-0.14, -0.34, -0.02) * angles(10, 0, 82) },
			{ partType = "Cylinder", size = V(0.36, 0.12, 0.12), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.14, -0.34, -0.02) * angles(10, 0, 98) },
			{ partType = "Normal",   size = V(0.76, 0.62, 1.14), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.04, 0.05) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.84, 0.20, 1.30), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.43, -0.02) * angles(-5, 0, 0) },
			{ partType = "Normal",   size = V(0.86, 0.10, 0.42), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.36, -0.58) * angles(-12, 0, 0) },
			{ partType = "Wedge",    size = V(0.14, 0.14, 0.96), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.54, 0.12) * angles(-4, 0, 0) },
			{ partType = "Wedge",    size = V(0.14, 0.54, 0.98), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.42, 0.00, 0.02) * angles(-6, -10, 6) },
			{ partType = "Wedge",    size = V(0.14, 0.54, 0.98), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.42, 0.00, 0.02) * angles(-6, 10, -6) },
			{ partType = "Cylinder", size = V(0.92, 0.18, 0.18), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.04, 0.08) },
			{ partType = "Normal",   size = V(0.60, 0.48, 0.26), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.06, 0.66) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.42, 0.22, 0.12), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, 0.16, 0.78) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.60, 0.20, 0.74), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.26, -0.14) * angles(174, 0, 0) },
			{ partType = "Normal",   size = V(0.66, 0.48, 0.14), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.03, -0.50) * angles(-6, 0, 0) },
			{ partType = "Cylinder", size = V(0.12, 0.44, 0.44), color = PALETTE.GUN_STEEL,   mat = Enum.Material.Metal, relCF = C(0, 0.03, -0.55) * angles(-6, 0, 0) * angles(0, 90, 0) },
			{ partType = "Cylinder", size = V(0.14, 0.34, 0.34), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon,  relCF = C(0, 0.03, -0.57) * angles(-6, 0, 0) * angles(0, 90, 0), light = true },
		}
	end

	local function getV1ChestSpecs()
		return {
			{ partType = "Normal",   size = V(1.74, 0.78, 0.74), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.12, 0.02) },
			{ partType = "Wedge",    size = V(0.76, 0.62, 0.28), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.46, 0.16, -0.44) * angles(0, 12, 180) },
			{ partType = "Wedge",    size = V(0.76, 0.62, 0.28), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.46, 0.16, -0.44) * angles(0, -12, 180) },
			{ partType = "Normal",   size = V(0.32, 0.76, 0.22), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.10, -0.36) },
			{ partType = "Normal",   size = V(0.10, 0.40, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.16, -0.45), light = true },
			{ partType = "Normal",   size = V(0.40, 0.18, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.52, -0.06, -0.42) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.40, 0.18, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.52, -0.06, -0.42) * angles(-10, -12, 0) },
			{ partType = "Normal",   size = V(0.30, 0.06, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.52, -0.06, -0.46) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.30, 0.06, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0.52, -0.06, -0.46) * angles(-10, -12, 0) },
			{ partType = "Wedge",    size = V(0.30, 0.34, 0.78), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.62, 0.62, 0.02) * angles(0, 0, -18) },
			{ partType = "Wedge",    size = V(0.30, 0.34, 0.78), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.62, 0.62, 0.02) * angles(0, 0, 18) },
			{ partType = "Normal",   size = V(0.84, 0.18, 0.68), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.56, 0.04) },
			{ partType = "Normal",   size = V(1.16, 0.32, 0.64), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.34, 0.02) },
			{ partType = "Cylinder", size = V(1.94, 0.34, 0.34), color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0, 0.24, 0.02) },
		}
	end

	local function getV1AbdomenSpecs()
		return {
			{ partType = "Cylinder", size = V(0.84, 0.36, 0.36), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.0, 0.04) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.68, 0.74, 0.46), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.0, 0.0) },
			{ partType = "Normal",   size = V(0.76, 0.16, 0.50), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, 0.14, 0.0) },
			{ partType = "Normal",   size = V(0.72, 0.16, 0.48), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.14, 0.0) },
			{ partType = "Cylinder", size = V(0.78, 0.14, 0.14), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(-0.28, 0.0, -0.18) * angles(0, 0, 84) },
			{ partType = "Cylinder", size = V(0.78, 0.14, 0.14), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0.28, 0.0, -0.18) * angles(0, 0, 96) },
			{ partType = "Normal",   size = V(0.08, 0.56, 0.08), color = PALETTE.BLOOD_RED, mat = Enum.Material.SmoothPlastic, relCF = C(-0.40, 0.0, -0.12) * angles(0, 0, 10) },
			{ partType = "Normal",   size = V(0.08, 0.56, 0.08), color = PALETTE.BLOOD_RED, mat = Enum.Material.SmoothPlastic, relCF = C(0.40, 0.0, -0.12) * angles(0, 0, -10) },
		}
	end

	local function getV1PelvisSpecs()
		return {
			{ partType = "Normal",   size = V(1.12, 0.34, 0.58), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.02, 0) },
			{ partType = "Wedge",    size = V(0.58, 0.36, 0.36), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.06, -0.26) * angles(180, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.38, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(-0.62, -0.06, 0.02) * angles(0, 0, 12) },
			{ partType = "Normal",   size = V(0.16, 0.38, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0.62, -0.06, 0.02) * angles(0, 0, -12) },
			{ partType = "Cylinder", size = V(1.10, 0.28, 0.28), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0, -0.14, 0) },
		}
	end

	local function getV1CoreSpecs()
		return {
			{ partType = "Normal",   size = V(0.88, 0.88, 0.38), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.14, 0.54) },
			{ partType = "Wedge",    size = V(0.76, 0.28, 0.38), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.64, 0.52) * angles(16, 0, 0) },
			{ partType = "Normal",   size = V(0.52, 0.94, 0.26), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0.12, 0.68) },
			{ partType = "Normal",   size = V(0.22, 0.86, 0.24), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(-0.36, 0.18, 0.72) * angles(0, 0, 16) },
			{ partType = "Normal",   size = V(0.22, 0.86, 0.24), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, relCF = C(0.36, 0.18, 0.72) * angles(0, 0, -16) },
			{ partType = "Normal",   size = V(0.16, 0.60, 0.12), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.14, 0.79), light = true },
			{ partType = "Normal",   size = V(0.44, 0.22, 0.30), color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0, -0.34, 0.62) * angles(-18, 0, 0) },
		}
	end

	local function getV1SingleWingParts()
		return {
			{ partType = "Cylinder", size = V(0.18, 0.22, 0.22), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0.05, 0, 0) * angles(0, 90, 0) },
			{ partType = "Normal",   size = V(0.72, 0.12, 0.14), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0.42, 0, 0) },
			{ partType = "Wedge",    size = V(0.18, 0.26, 0.90), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.92, 0.08, 0) * angles(0, -90, 0) },
			{ partType = "Normal",   size = V(0.96, 0.11, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(1.22, -0.04, 0) },
			{ partType = "Normal",   size = V(0.42, 0.22, 0.14), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(1.68, 0.01, 0) },
			{ partType = "Normal",   size = V(2.55, 0.28, 0.06), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(2.96, 0.01, 0) },
			{ partType = "Wedge",    size = V(0.06, 0.28, 1.30), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(4.885, 0.01, 0) * angles(0, -90, 0) },
		}
	end

	local function getV1UpperArmSpecs(isFeedbacker)
		local accent = isFeedbacker and PALETTE.SILVER_TRIM or PALETTE.DARK_METAL
		return {
			{ partType = "Ball",     size = V(0.42, 0.42, 0.42), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Wedge",    size = V(0.56, 0.34, 0.56), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.10, 0) * angles(0, 0, isFeedbacker and -16 or 16) },
			{ partType = "Normal",   size = V(0.42, 0.72, 0.44), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.50, 0) },
			{ partType = "Normal",   size = V(0.18, 0.54, 0.22), color = accent,             mat = Enum.Material.Metal, relCF = C(0, -0.54, -0.18) },
			{ partType = "Cylinder", size = V(0.34, 0.26, 0.26), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, -V1_UPPER_ARM_LEN, 0) },
		}
	end

	local function getV1ForearmSpecs(isFeedbacker)
		if isFeedbacker then
			return {
				{ partType = "Ball",     size = V(0.30, 0.30, 0.30), color = PALETTE.DARK_METAL,  mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
				{ partType = "Normal",   size = V(0.46, 0.80, 0.48), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0, -0.48, 0) },
				{ partType = "Normal",   size = V(0.52, 0.34, 0.54), color = PALETTE.BLUE_ARMOR,  mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.74, -0.02) },
				{ partType = "Normal",   size = V(0.12, 0.46, 0.12), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.24, -0.50, -0.14) },
				{ partType = "Cylinder", size = V(0.52, 0.14, 0.14), color = PALETTE.GUN_STEEL,   mat = Enum.Material.Metal, relCF = C(0, -0.46, 0.24) * angles(0, 0, 90) },
			}
		end
		return {
			{ partType = "Ball",     size = V(0.28, 0.28, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.40, 0.78, 0.42), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.48, 0) },
			{ partType = "Normal",   size = V(0.44, 0.20, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.84, 0) },
			{ partType = "Cylinder", size = V(0.46, 0.14, 0.14), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, -0.46, 0.20) * angles(0, 0, 90) },
		}
	end

	local function getV1HandSpecs(isFist)
		if isFist then
			return {
				{ partType = "Normal", size = V(0.40, 0.34, 0.44), color = PALETTE.DARK_METAL,  mat = Enum.Material.Metal, relCF = C(0, -0.18, 0) },
				{ partType = "Normal", size = V(0.46, 0.22, 0.50), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, relCF = C(0, -0.34, -0.02) },
				{ partType = "Normal", size = V(0.44, 0.14, 0.44), color = PALETTE.BLUE_ARMOR,  mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.46, -0.02) },
				{ partType = "Normal", size = V(0.16, 0.16, 0.14), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, -0.30, -0.24), light = true },
			}
		end
		return {
			{ partType = "Normal", size = V(0.36, 0.34, 0.40), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.18, 0) },
			{ partType = "Normal", size = V(0.40, 0.20, 0.44), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.34, -0.02) },
			{ partType = "Normal", size = V(0.16, 0.26, 0.18), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.12, -0.42, -0.06) },
		}
	end

	local function getV1ThighSpecs()
		return {
			{ partType = "Ball",     size = V(0.42, 0.42, 0.42), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.58, 0.94, 0.58), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56, 0) },
			{ partType = "Wedge",    size = V(0.52, 0.38, 0.22), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.42, -0.32) * angles(8, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.60, 0.10), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.60, -0.28) },
			{ partType = "Cylinder", size = V(0.38, 0.30, 0.30), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, -V1_THIGH_LEN, 0) },
		}
	end

	local function getV1ShinSpecs()
		return {
			{ partType = "Ball",     size = V(0.32, 0.32, 0.32), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.48, 0.96, 0.48), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56, 0) },
			{ partType = "Wedge",    size = V(0.40, 0.48, 0.28), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.14, -0.26) * angles(-14, 0, 0) },
			{ partType = "Normal",   size = V(0.14, 0.70, 0.10), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.62, -0.23) },
			{ partType = "Cylinder", size = V(0.58, 0.14, 0.14), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, -0.54, 0.26) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.28, 0.24, 0.24), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, relCF = C(0, -V1_SHIN_LEN, 0) },
		}
	end

	local function getV1FootSpecs()
		return {
			{ partType = "Normal", size = V(0.38, 0.18, 0.48), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.10, -0.06) },
			{ partType = "Normal", size = V(0.44, 0.16, 0.70), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.25, -0.18) },
			{ partType = "Wedge",  size = V(0.40, 0.18, 0.36), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24, -0.58) },
			{ partType = "Normal", size = V(0.38, 0.08, 0.72), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.34, -0.26) },
			{ partType = "Normal", size = V(0.30, 0.20, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, relCF = C(0, -0.23, 0.22) * angles(20, 0, 0) },
		}
	end

	local function getV1GunSpecs()
		return {
			{ partType = "Normal",   size = V(0.18, 0.24, 0.48), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24, 0.04) * angles(-16, 0, 0) },
			{ partType = "Normal",   size = V(0.21, 0.27, 0.10), color = PALETTE.SILVER_TRIM,    mat = Enum.Material.Metal,         relCF = C(0, -0.16, 0.28) * angles(-16, 0, 0) },
			{ partType = "Normal",   size = V(0.07, 0.26, 0.06), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.44, 0.06) },
			{ partType = "Normal",   size = V(0.07, 0.06, 0.18), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56, -0.02) },
			{ partType = "Normal",   size = V(0.04, 0.05, 0.12), color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal,         relCF = C(0, -0.39, -0.03) * angles(-20, 0, 0) },
			{ partType = "Normal",   size = V(0.22, 0.58, 0.20), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal,         relCF = C(0, -0.46, -0.14) },
			{ partType = "Normal",   size = V(0.18, 0.14, 0.18), color = PALETTE.SILVER_TRIM,    mat = Enum.Material.Metal,         relCF = C(0, -0.16, -0.22) * angles(22, 0, 0) },
			{ partType = "Cylinder", size = V(0.32, 0.30, 0.30), color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal,         relCF = C(0, -0.54, -0.28) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.18, 0.42, 0.07), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal,         relCF = C(0, -0.54, -0.44) },
			{ partType = "Normal",   size = V(0.22, 0.86, 0.24), color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal,         relCF = C(0, -1.12, -0.29) },
			{ partType = "Normal",   size = V(0.16, 0.80, 0.09), color = PALETTE.BLUE_ARMOR,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.10, -0.43) },
			{ partType = "Normal",   size = V(0.16, 0.08, 0.08), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal,         relCF = C(0, -0.28, -0.46) },
			{ partType = "Normal",   size = V(0.05, 0.09, 0.09), color = PALETTE.MARKSMAN_GREEN, mat = Enum.Material.Neon,          relCF = C(0, -1.48, -0.48), gunNeon = true },
			{ partType = "Normal",   size = V(0.15, 0.68, 0.12), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.06, -0.14) },
			{ partType = "Cylinder", size = V(0.14, 0.16, 0.16), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.Metal,         relCF = C(0, -1.58, -0.29) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.245, 0.66, 0.055), color = PALETTE.MARKSMAN_GREEN, mat = Enum.Material.Neon,        relCF = C(0, -1.12, -0.29), gunNeon = true },
			{ partType = "Normal",   size = V(0.14, 0.04, 0.11),   color = PALETTE.MARKSMAN_GREEN, mat = Enum.Material.Neon,        relCF = C(0, -0.17, -0.34), gunNeon = true },
		}
	end

	-------------------------------------------------------------------
	-- TARGETING DO V1 (MELEE PARRY + COIN RICOCHET)
	-------------------------------------------------------------------
	local function findNearestMeleeTarget(c, hrp)
		local bestChar, bestHRP, bestDist = nil, nil, PARRY_RANGE
		local myPos, look = hrp.Position, hrp.CFrame.LookVector
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tHRP = Core.getTargetRoot(model.Parent)
			if tHRP and tHRP:IsA("BasePart") then
				local diff = tHRP.Position - myPos
				local d = diff.Magnitude
				if d > 0.1 and d < bestDist and (diff.Unit:Dot(look) > -0.25 or d < 5.0) then
					bestDist, bestChar, bestHRP = d, model.Parent, tHRP
				end
			end
		end
		return bestChar, bestHRP
	end

	local function findNearestCoinTarget(c, originPos, fallbackAimPos)
		local bestPos, bestChar, bestDist = nil, nil, COIN_RANGE
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local tHead = model.Parent:FindFirstChild("Head") or Core.getTargetRoot(model.Parent)
			if tHead and tHead:IsA("BasePart") then
				local d = (tHead.Position - originPos).Magnitude
				if d > 2 and d < bestDist then
					bestDist, bestPos, bestChar = d, tHead.Position, model.Parent
				end
			end
		end
		return bestPos or fallbackAimPos, bestChar
	end

	local function fireRicochetBeams(STATE, originPos, coinPos, targetPos, isCoinPunch)
		local beam2Color = isCoinPunch and PALETTE.COIN_GOLD or PALETTE.BEAM_CYAN
		local w1 = isCoinPunch and 0.10 or 0.24
		local w2 = isCoinPunch and 0.52 or 0.38
		STATE.camShake = math.max(STATE.camShake, isCoinPunch and 0.65 or 0.35)
		STATE.fovKick = math.max(STATE.fovKick, isCoinPunch and 8 or 5)
		Core.fireDualBeams(originPos, coinPos, targetPos, PALETTE.YELLOW_NEON, beam2Color, w1, w2, isCoinPunch, 0.28)
		Core.spawnImpactFlash(targetPos, beam2Color, 1.1, isCoinPunch and 6.0 or 4.5, 0.26)
	end

	-------------------------------------------------------------------
	-- MÓDULO EXPORTADO PARA O CORE
	-------------------------------------------------------------------
	Core.start({
		id = "v1",
		name = "V1",
		config = {
			RENDER_NAME = "F3X_V1_Reanim",
			HUD_RENDER_NAME = "F3X_V1_3DHUD",
			SCALE = 1.0,
			SOLE_DEPTH = V1_SOLE_DEPTH,
			HUD_UNIT_HEADER = "V1 // BLOOD FUEL SYSTEM",
			HUD_WEAPON_TITLE = "MARKSMAN REVOLVER",
			HUD_WEAPON_COLOR = PALETTE.MARKSMAN_GREEN,
			HUD_KEY_HINT = "[Q] DASH  [C] SLAM/SLIDE  [E] COIN  [F] PARRY",
			HUD_PIP_COLOR = PALETTE.COIN_GOLD,
			MOBILE_PRIMARY_LABEL = "COIN",
			MOBILE_PRIMARY_COLOR = PALETTE.COIN_GOLD,
			MOBILE_SECONDARY_LABEL = "PARRY",
			MOBILE_SECONDARY_COLOR = PALETTE.PARRY_FLASH,
		},

		initState = function()
			local STATE = Core.getState()
			STATE.custom.coinAttack = {
				active = false, lastUsed = 0, startTime = 0, shotFired = false, punched = false, beamsHidden = false,
				tossPos = V(0, 0, 0), tossVel = V(0, 0, 0), coinCF = PARK_CF,
			}
			STATE.custom.parryAttack = { active = false, lastUsed = 0, startTime = 0, hitTriggered = false }
		end,

		buildModel = function(_, _, _, _, torsoInitCF)
			local specs = {}
			local chestCF = torsoInitCF * C(0, V1_CHEST_OFFSET, 0)
			local abdomenCF = torsoInitCF * C(0, V1_ABDOMEN_OFFSET, 0)
			local pelvisCF = torsoInitCF * C(0, V1_PELVIS_OFFSET, 0)
			local headInitCF = chestCF * C(0, 1.06, -0.06)

			for _, hp in ipairs(getV1HeadSpecs()) do
				specs[#specs + 1] = {
					kind = "v1head", partType = hp.partType, relCF = hp.relCF, origCF = headInitCF * hp.relCF,
					origSize = hp.size, origColor = hp.color, origMaterial = hp.mat, origTrans = 0, origReflectance = 0, light = hp.light,
				}
			end

			local function addV1(kind, list, parentCF, key)
				for _, sp in ipairs(list) do
					specs[#specs + 1] = {
						kind = kind, key = key, partType = sp.partType, relCF = sp.relCF, origCF = parentCF * sp.relCF,
						origSize = sp.size, origColor = sp.color, origMaterial = sp.mat, origTrans = 0, origReflectance = 0,
						light = sp.light, gunNeon = sp.gunNeon,
					}
				end
			end

			addV1("v1chest", getV1ChestSpecs(), chestCF, "chest")
			addV1("v1chest", getV1AbdomenSpecs(), abdomenCF, "abdomen")
			addV1("v1chest", getV1PelvisSpecs(), pelvisCF, "pelvis")

			local shoulderL = chestCF * C(-1.06, 0.24, 0)
			local shoulderR = chestCF * C(1.06, 0.24, 0)
			local elbowL, elbowR = shoulderL * C(0, -V1_UPPER_ARM_LEN, 0), shoulderR * C(0, -V1_UPPER_ARM_LEN, 0)
			local wristL, wristR = elbowL * C(0, -V1_FOREARM_LEN, 0), elbowR * C(0, -V1_FOREARM_LEN, 0)

			addV1("v1upperArm", getV1UpperArmSpecs(true), shoulderL, "lUpperArm")
			addV1("v1upperArm", getV1UpperArmSpecs(false), shoulderR, "rUpperArm")
			addV1("v1forearm", getV1ForearmSpecs(true), elbowL, "lForearm")
			addV1("v1forearm", getV1ForearmSpecs(false), elbowR, "rForearm")
			addV1("v1hand", getV1HandSpecs(true), wristL, "lHand")
			addV1("v1hand", getV1HandSpecs(false), wristR, "rHand")

			local hipL = pelvisCF * C(-0.46, V1_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, V1_HIP_Y, 0)
			local kneeL, kneeR = hipL * C(0, -V1_THIGH_LEN, 0), hipR * C(0, -V1_THIGH_LEN, 0)
			local ankleL, ankleR = kneeL * C(0, -V1_SHIN_LEN, 0), kneeR * C(0, -V1_SHIN_LEN, 0)

			addV1("v1thigh", getV1ThighSpecs(), hipL, "lThigh")
			addV1("v1thigh", getV1ThighSpecs(), hipR, "rThigh")
			addV1("v1shin", getV1ShinSpecs(), kneeL, "lShin")
			addV1("v1shin", getV1ShinSpecs(), kneeR, "rShin")
			addV1("v1foot", getV1FootSpecs(), ankleL, "lFoot")
			addV1("v1foot", getV1FootSpecs(), ankleR, "rFoot")

			for _, cp in ipairs(getV1CoreSpecs()) do
				specs[#specs + 1] = {
					kind = "v1core", partType = cp.partType, relCF = cp.relCF, origCF = chestCF * cp.relCF,
					origSize = cp.size, origColor = cp.color, origMaterial = cp.mat, origTrans = 0, origReflectance = 0, light = cp.light,
				}
			end

			local singleWing = getV1SingleWingParts()
			for _, side in ipairs({ -1, 1 }) do
				for wingIdx = 1, 4 do
					for _, wp in ipairs(singleWing) do
						local relCF = (side == -1) and mirrorRelCF(wp.relCF) or wp.relCF
						specs[#specs + 1] = {
							kind = "v1wing", side = side, wingIdx = wingIdx, partType = wp.partType, relCF = relCF,
							origCF = chestCF * relCF, origSize = wp.size, origColor = wp.color, origMaterial = wp.mat, origTrans = 0, origReflectance = 0,
						}
					end
				end
			end

			for _, gp in ipairs(getV1GunSpecs()) do
				specs[#specs + 1] = {
					kind = "v1gun", partType = gp.partType, relCF = gp.relCF, origCF = wristR * GUN_MOUNT_REL * gp.relCF,
					origSize = gp.size, origColor = gp.color, origMaterial = gp.mat, origTrans = 0, origReflectance = 0, gunNeon = gp.gunNeon,
				}
			end

			return specs
		end,

		onPrimary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local ca = STATE.custom.coinAttack
			local now = os.clock()
			if ca.active or (now - ca.lastUsed) < COIN_COOLDOWN then return end
			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			ca.active, ca.lastUsed, ca.startTime = true, now, now
			ca.shotFired, ca.punched, ca.beamsHidden = false, false, false

			local cam = workspace.CurrentCamera
			local headReal = c:FindFirstChild("Head")
			local inFP = cam and headReal and ((cam.CFrame.Position - headReal.Position).Magnitude < Core.getConfig().FIRST_PERSON_HIDE_DIST) or false
			local aimCF = (inFP and cam) and cam.CFrame or hrp.CFrame

			local flatLook = V(aimCF.LookVector.X, 0, aimCF.LookVector.Z)
			flatLook = (flatLook.Magnitude < 0.01) and hrp.CFrame.LookVector or flatLook.Unit
			local hrpVel = hrp.AssemblyLinearVelocity
			ca.tossPos = (aimCF * C(-0.55, 0.55, -1.8)).Position
			ca.tossVel = V(hrpVel.X * 0.72, math.max(hrpVel.Y * 0.35, 0), hrpVel.Z * 0.72) + flatLook * 15 + V(0, 14, 0)
			ca.coinCF = C(ca.tossPos)

			Core.playSFX("COIN_FLIP", 1.05, 1.0, "PARRY")
			if STATE.coinPart and STATE.coinPart.part then
				Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 0 } })
			end
		end,

		onSecondary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local pa = STATE.custom.parryAttack
			local now = os.clock()
			if pa.active or (now - pa.lastUsed) < PARRY_COOLDOWN then return end
			pa.active, pa.lastUsed, pa.startTime, pa.hitTriggered = true, now, now, false
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
			local groundOffsetY = V1_SOLE_DEPTH - realSoleDepth

			local camPitch, camYawLocal = 0, 0
			if CONFIG.ENABLE_HEAD_AIM_TRACKING and cam then
				local camLocalLook = hrp.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)
				camPitch = clamp(math.asin(clamp(camLocalLook.Y, -0.85, 0.85)) * 180 / math.pi, -45, 55)
				camYawLocal = clamp(math.atan2(-camLocalLook.X, -camLocalLook.Z) * 180 / math.pi, -35, 35)
			end

			local torsoY = groundOffsetY + math.sin(t * 2.6) * 0.045 * idleWeight + math.abs(sinW) * 0.14 * STATE.walkBlend * (1 + STATE.sprintBlend * 0.4) - STATE.landRecover * 0.28
			local idleYaw = 12 * idleWeight
			local walkTwist = cosW * (6 + STATE.sprintBlend * 7) * STATE.walkBlend
			local torsoPitch = -STATE.localFwd * (8 + STATE.sprintBlend * 11) + (STATE.landRecover * -12) + STATE.airBlend * clamp(-STATE.vertVel * 0.35, -14, 16)
			local torsoRoll = -STATE.localStrafe * 9 - STATE.turnRate * 1.4

			if STATE.slide.active and not isAir then
				torsoY -= 1.35
				torsoPitch = 38
			end

			local dashTilt, dashRoll = 0, 0
			if STATE.dash.active then
				local dEl = now - STATE.dash.startTime
				if dEl < CONFIG.DASH_DURATION then
					local envD = math.sin((dEl / CONFIG.DASH_DURATION) * math.pi)
					dashTilt, dashRoll = STATE.dash.localDir.Z * 26 * envD, -STATE.dash.localDir.X * 26 * envD
					torsoY -= 0.20 * envD
				end
			end

			local headRX = math.sin(t * 2.6 - 0.6) * 2.5 * idleWeight + camPitch * 0.65 - torsoPitch * 0.5
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

			if STATE.slide.active then
				lHipRX, rHipRX = 64, -18
				lHipRZ, rHipRZ = -8, 12
				lKneeRX, rKneeRX = -18, -74
				lAnkleRX, rAnkleRX = -24, 18
			elseif STATE.airBlend > 0.01 then
				local riseT = clamp((STATE.vertVel + 16) / 40, 0, 1)
				lHipRX = lerp(lHipRX, lerp(22, 42, riseT), STATE.airBlend)
				rHipRX = lerp(rHipRX, lerp(-16, -28, riseT), STATE.airBlend)
				lHipRZ, rHipRZ = lerp(lHipRZ, -8, STATE.airBlend), lerp(rHipRZ, 8, STATE.airBlend)
				lKneeRX = lerp(lKneeRX, lerp(-32, -74, riseT), STATE.airBlend)
				rKneeRX = lerp(rKneeRX, lerp(-20, -48, riseT), STATE.airBlend)
				lAnkleRX, rAnkleRX = lerp(lAnkleRX, 24, STATE.airBlend), lerp(rAnkleRX, 18, STATE.airBlend)
			end

			local lArmRX = (-12 + math.sin(t * 2.6 + 0.5) * 3.5) * idleWeight - (sinW * (28 + STATE.sprintBlend * 26) * STATE.walkBlend)
			local lArmRY = 10 * idleWeight
			local lArmRZ = (-9 - math.sin(t * 1.8) * 1.5) * idleWeight - STATE.airBlend * 28

			local rArmRX = (72 + math.sin(t * 2.6) * 2.5) * idleWeight + (34 + cosW * 8) * STATE.walkBlend + (STATE.sprintBlend * 14) + camPitch * 0.7
			local rArmRY = (-12 * idleWeight) + camYawLocal * 0.35
			local rArmRZ = 6 * idleWeight + STATE.airBlend * 16
			local lElbowRX, rElbowRX = 24, 18
			local lWristRX, lWristRY, lWristRZ = 0, 0, 0
			local rWristRX, rWristRY, rWristRZ = 0, 0, 0
			local torsoYawMod = 0

			local pa = STATE.custom.parryAttack
			local ca = STATE.custom.coinAttack

			if pa.active then
				local el = now - pa.startTime
				if el < 0.08 then
					local k = easeOutQuad(el / 0.08)
					lArmRX, lArmRY, lArmRZ = lerp(lArmRX, -38, k), lerp(lArmRY, 25, k), lerp(lArmRZ, -22, k)
					torsoYawMod -= 22 * k
				elseif el < 0.24 then
					local k = easeOutBack((el - 0.08) / 0.12)
					lArmRX, lArmRY, lArmRZ = lerp(-38, 96, k), lerp(25, -14, k), lerp(-22, 6, k)
					lElbowRX = lerp(lElbowRX, 8, k)
					lWristRX = lerp(lWristRX, 16, k)
					rArmRX = lerp(rArmRX, 18, k)
					torsoYawMod += 32 * k
					torsoPitch -= 12 * k

					if not pa.hitTriggered and el >= 0.10 then
						pa.hitTriggered = true
						local fistWorld = (hrp.CFrame * C(-1.0, 0.5, -2.4)).Position
						if ca.active and not ca.shotFired and not ca.punched then
							ca.punched, ca.shotFired = true, true
							local cPos = ca.coinCF.Position
							local targetPos, targetChar = findNearestCoinTarget(c, cPos, (hrp.CFrame * C(0, 0.6, -COIN_RANGE)).Position)
							fireRicochetBeams(STATE, fistWorld, cPos, targetPos, true)
							Core.playSFX("PARRY", 1.0, 1.0)
							Core.spawnFlash(cPos, PALETTE.COIN_GOLD, 1.2, 5.4, 0.24)
							Core.triggerHitstop(0.13, PALETTE.COIN_GOLD)
							Core.addStyleBonus("FISTFUL OF DOLLAR", 320, PALETTE.COIN_GOLD)
							if targetChar then Core.applyF3XKnockback(targetChar, targetPos - cPos, COIN_PUNCH_KNOCKBACK_POWER) end
						else
							local targetChar, targetHRP = findNearestMeleeTarget(c, hrp)
							if targetChar and targetHRP then
								Core.playSFX("PARRY", 1.0, 1.0)
								Core.triggerHitstop(0.10, PALETTE.PARRY_FLASH)
								Core.spawnFlash(targetHRP.Position, PALETTE.PARRY_FLASH, 1.0, 4.8, 0.22)
								Core.spawnShockwaveRing(targetHRP.Position, (targetHRP.Position - hrp.Position), PALETTE.PARRY_FLASH, 1.0, 6.5, 0.24)
								Core.addStyleBonus("PARRY", 250, PALETTE.PARRY_FLASH)
								Core.applyF3XKnockback(targetChar, targetHRP.Position - hrp.Position, PARRY_KNOCKBACK_POWER)
							else
								Core.playSFX("PUNCH", 1.05, 1.0, "PARRY")
								Core.spawnFlash(fistWorld, PALETTE.PARRY_FLASH, 0.8, 3.6, 0.20)
							end
						end
					end
				elseif el < 0.36 then
					local k = easeOutQuad((el - 0.24) / 0.12)
					lArmRX, lArmRY, lArmRZ = lerp(96, lArmRX, k), lerp(-14, lArmRY, k), lerp(6, lArmRZ, k)
					torsoYawMod += 32 * (1 - k)
				else
					pa.active = false
				end
			end

			if ca.active and not ca.punched then
				local el = now - ca.startTime
				if el < 0.16 then
					local k = easeOutQuad(el / 0.16)
					lArmRX, lArmRZ = lerp(lArmRX, 72, k), lerp(lArmRZ, 14, k)
				elseif el < 0.30 then
					local k = easeOutQuad((el - 0.16) / 0.14)
					lArmRX, lArmRZ = lerp(72, lArmRX, k), lerp(14, lArmRZ, k)
				end
				if el < 0.48 then
					local aimK = easeOutQuad(el / 0.28)
					rArmRX, rArmRY, rArmRZ = lerp(rArmRX, 102 + camPitch * 0.65, aimK), lerp(rArmRY, 12, aimK), lerp(rArmRZ, -6, aimK)
					rElbowRX = lerp(rElbowRX, 12, aimK)
					rWristRX = lerp(rWristRX, 18, aimK)
				elseif el < 0.68 then
					local rec = (el < 0.58) and (32 * easeOutQuad((el - 0.48) / 0.10)) or (32 * (1 - easeOutQuad((el - 0.58) / 0.10)))
					rArmRX, rArmRY = 102 + camPitch * 0.65 + rec, 12
				end
			end

			local torsoCF = hrp.CFrame * C(0, torsoY, 0) * angles(torsoPitch + dashTilt, idleYaw + walkTwist + torsoYawMod, torsoRoll + dashRoll)
			local chestCF = torsoCF * C(0, V1_CHEST_OFFSET, 0)
			local abdomenCF = torsoCF * C(0, V1_ABDOMEN_OFFSET, 0) * angles(torsoPitch * 0.3, -walkTwist * 0.35, torsoRoll * 0.25)
			local pelvisCF = torsoCF * C(0, V1_PELVIS_OFFSET, 0) * angles(-torsoPitch * 0.18, 0, -torsoRoll * 0.35)

			local shoulderLCF = chestCF * C(-1.06, 0.24, 0) * angles(lArmRX, lArmRY, lArmRZ)
			local shoulderRCF = chestCF * C(1.06, 0.24, 0) * angles(rArmRX, rArmRY, rArmRZ)
			local elbowLCF = shoulderLCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(lElbowRX, 0, 0)
			local elbowRCF = shoulderRCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(rElbowRX, 0, 0)
			local wristLCF = elbowLCF * C(0, -V1_FOREARM_LEN, 0) * angles(lWristRX, lWristRY, lWristRZ)
			local wristRCF = elbowRCF * C(0, -V1_FOREARM_LEN, 0) * angles(rWristRX, rWristRY, rWristRZ)

			local hipLCF = pelvisCF * C(-0.46, V1_HIP_Y, 0) * angles(lHipRX, lHipRY, lHipRZ)
			local hipRCF = pelvisCF * C(0.46, V1_HIP_Y, 0) * angles(rHipRX, rHipRY, rHipRZ)
			local kneeLCF = hipLCF * C(0, -V1_THIGH_LEN, 0) * angles(lKneeRX, 0, 0)
			local kneeRCF = hipRCF * C(0, -V1_THIGH_LEN, 0) * angles(rKneeRX, 0, 0)
			local ankleLCF = kneeLCF * C(0, -V1_SHIN_LEN, 0) * angles(lAnkleRX, 0, 0)
			local ankleRCF = kneeRCF * C(0, -V1_SHIN_LEN, 0) * angles(rAnkleRX, 0, 0)

			if inFP and cam and STATE.fpArms then
				local bobX = cosW * 0.03 * STATE.walkBlend
				local bobY = math.abs(sinW) * 0.04 * STATE.walkBlend
				local fpRecoil = 0
				if ca.active and not ca.punched then
					local el = now - ca.startTime
					if el >= 0.48 and el < 0.68 then
						fpRecoil = (el < 0.58) and (30 * easeOutQuad((el - 0.48) / 0.10)) or (30 * (1 - easeOutQuad((el - 0.58) / 0.10)))
					end
				end
				local punchReach = pa.active and math.sin(clamp((now - pa.startTime) / 0.24, 0, 1) * math.pi) * 1.15 or 0

				local camBase = cam.CFrame * C(0, -0.92, 0.12)
				shoulderRCF = camBase * C(0.42 + bobX, 0.12 - bobY, 0.22) * angles(58 + fpRecoil * 0.5, 26, -14)
				elbowRCF = shoulderRCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(52 + fpRecoil, 0, 6)
				wristRCF = elbowRCF * C(0, -V1_FOREARM_LEN, 0) * angles(-46 + fpRecoil * 0.4, 8, -10)

				shoulderLCF = camBase * C(-0.40 - bobX, 0.10 - bobY, 0.18) * angles(62 - punchReach * 22, -24, 14)
				elbowLCF = shoulderLCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(46 - punchReach * 30, 0, -8)
				wristLCF = elbowLCF * C(0, -V1_FOREARM_LEN, 0) * angles(-38, -6, 10)
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
				["Head"] = chestCF * C(0, 1.06, -0.06) * angles(headRX, headRY, headRZ),
				["Left Arm"] = wristLCF,
				["Right Arm"] = wristRCF,
				["Left Leg"] = ankleLCF,
				["Right Leg"] = ankleRCF,
			}

			local B = STATE.buckets
			local fpBodyHide = inFP and 1 or 0

			for _, hp in ipairs(B.v1head or {}) do
				if hp.part and hp.part.Parent then
					hp.targetCF = cfs["Head"] * hp.relCF
					hp.part.CFrame = hp.targetCF
					hp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			for _, cp in ipairs(B.v1chest or {}) do
				if cp.part and cp.part.Parent and cfs[cp.key] then
					cp.targetCF = cfs[cp.key] * cp.relCF
					cp.part.CFrame = cp.targetCF
					cp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			for _, kind in ipairs({ "v1upperArm", "v1forearm", "v1hand", "v1thigh", "v1shin", "v1foot" }) do
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
			local coinReady = (now - ca.lastUsed) >= COIN_COOLDOWN
			local neonCol = coinReady and PALETTE.MARKSMAN_GREEN or Color3.fromRGB(28, 70, 42)
			local gunHide = (inFP and not STATE.fpArms) and 1 or 0
			for _, gp in ipairs(B.v1gun or {}) do
				if gp.part and gp.part.Parent then
					if gp.gunNeon then gp.part.Color = neonCol end
					gp.targetCF = gunRoot * gp.relCF
					gp.part.CFrame = gp.targetCF
					gp.part.LocalTransparencyModifier = gunHide
				end
			end

			for _, cp in ipairs(B.v1core or {}) do
				if cp.part and cp.part.Parent then
					cp.targetCF = chestCF * cp.relCF
					cp.part.CFrame = cp.targetCF
					cp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			local baseFan = { 48, 18, -14, -46 }
			local flare = STATE.sprintBlend * 16 + STATE.airBlend * 22 + (pa.active and 14 or 0) + (ca.shotFired and not ca.beamsHidden and 10 or 0)
			local sweepBack = 24 + STATE.walkBlend * 10 + STATE.sprintBlend * 24 + STATE.airBlend * 12 + (STATE.dash.active and 32 or 0)
			local wingRoots = {}
			for _, side in ipairs({ -1, 1 }) do
				wingRoots[side] = {}
				for idx = 1, 4 do
					local breath = math.sin(STATE.time * 2.8 - idx * 0.45) * (3.0 + STATE.walkBlend * 2.5)
					wingRoots[side][idx] = chestCF * C(side * 0.36, 0.50 - (idx - 1) * 0.21, 0.76) * angles(0, -sweepBack * side, (baseFan[idx] + flare + breath) * side)
				end
			end
			for _, wp in ipairs(B.v1wing or {}) do
				if wp.part and wp.part.Parent then
					wp.targetCF = wingRoots[wp.side][wp.wingIdx] * wp.relCF
					wp.part.CFrame = wp.targetCF
					wp.part.LocalTransparencyModifier = fpBodyHide
				end
			end

			if ca.active then
				local elapsed = now - ca.startTime
				if STATE.coinPart and STATE.coinPart.part and STATE.coinPart.part.Parent then
					if not ca.shotFired then
						local coinPos = ca.tossPos + ca.tossVel * elapsed + V(0, -18 * elapsed * elapsed, 0)
						ca.coinCF = C(coinPos) * CFrame.Angles(elapsed * 26, elapsed * 16, 0)
						STATE.coinPart.targetCF, STATE.coinPart.part.CFrame = ca.coinCF, ca.coinCF
					end
					if elapsed >= 0.48 and not ca.shotFired and not ca.punched then
						ca.shotFired = true
						local gunTip = (gunRoot * GUN_MUZZLE_LOCAL).Position
						local cPos = ca.coinCF.Position
						local targetPos, targetChar = findNearestCoinTarget(c, cPos, (hrp.CFrame * C(0, 0.6, -COIN_RANGE)).Position)
						fireRicochetBeams(STATE, gunTip, cPos, targetPos, false)
						Core.playSFX("SHATTER", 1.2, 0.9, "PARRY")
						Core.spawnFlash(gunTip, PALETTE.YELLOW_NEON, 0.8, 3.0, 0.16)
						Core.spawnShockwaveRing(cPos, (targetPos - cPos), PALETTE.COIN_GOLD, 0.6, 3.8, 0.20)
						if targetChar then
							Core.addStyleBonus("RICOSHOT", 200, PALETTE.BEAM_CYAN)
							Core.applyF3XKnockback(targetChar, targetPos - cPos, COIN_KNOCKBACK_POWER)
						end
					end
				end
				if elapsed >= 0.66 and not ca.beamsHidden then
					ca.beamsHidden = true
					if STATE.coinPart and STATE.coinPart.part then
						STATE.coinPart.targetCF, STATE.coinPart.part.CFrame = PARK_CF, PARK_CF
						Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
					end
				end
				if elapsed >= 0.78 then ca.active = false end
			end

			return {
				weaponTitle = "MARKSMAN REVOLVER",
				weaponColor = PALETTE.MARKSMAN_GREEN,
				chargeFrac = clamp((now - ca.lastUsed) / COIN_COOLDOWN, 0, 1),
				pipColor = PALETTE.COIN_GOLD,
				pipDimColor = Color3.fromRGB(165, 130, 32),
			}, cfs
		end,
	})
end