-- ULTRAKILL V1 MODULE (100% MODELO ORIGINAL + MARKSMAN COIN + FEEDBACKER PARRY + FLOATY AIR)
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

			-- V1 Light & Floaty Aerial Tuning
			WALK_SPEED = 18,
			SPRINT_SPEED = 35,
			JUMP_POWER = 56,
			AIR_GRAVITY_CANCEL = 0.44,
			GLIDE_GRAVITY_CANCEL = 0.76,
			GLIDE_MAX_FALL = 14,
			AIR_STRAFE_ACCEL = 54,
			AIR_DRAG = 0.24,
			SLAM_STORAGE_JUMP = 108,

			HUD_UNIT_HEADER = "V1 // BLOOD FUEL SYSTEM",
			HUD_WEAPON_TITLE = "MARKSMAN REVOLVER",
			HUD_WEAPON_COLOR = PALETTE.MARKSMAN_GREEN,
			HUD_KEY_HINT = "[Q] DASH  [C] SLAM/SLIDE  [E] COIN  [F] PARRY",
			BGM_URL = "https://raw.githubusercontent.com/thatonexploiter/ultrakill-f3x/main/audio/the_cyber_grind.mp3",
			BGM_FILE = "v1_into_the_fire.mp3",
			BGM_FALLBACK_ID = "rbxassetid://15081073002",
			BGM_VOLUME = 0.42,
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
			local torsoPitch = -STATE.localFwd * (8 + STATE.sprintBlend * 11) + (STATE.landRecover * -12) + STATE.airBlend * clamp(-STATE.vertVel * 0.35, -14, 14)
			local torsoRoll = -STATE.localStrafe * 9 - STATE.turnRate * 2.2
			local torsoYaw = idleYaw + walkTwist

			if STATE.slide.active and not isAir then
				torsoY -= 1.35
				torsoPitch = 36
				torsoRoll = -STATE.localStrafe * 12
				torsoYaw = 18
			elseif STATE.slam.active and isAir then
				torsoPitch = -22
				torsoRoll = 0
			elseif STATE.isGliding and isAir then
				torsoPitch -= 10
			end

			if STATE.dash.active then
				local dK = 1 - clamp((now - STATE.dash.startTime) / math.max(0.01, CONFIG.DASH_DURATION), 0, 1)
				local ld = STATE.dash.localDir
				torsoPitch += ld.Z * 26 * dK
				torsoRoll -= ld.X * 24 * dK
			end

			local torsoCF = hrp.CFrame * C(0, torsoY, 0) * angles(torsoPitch, torsoYaw, torsoRoll)
			local chestCF = torsoCF * C(0, V1_CHEST_OFFSET, 0)
			local abdomenCF = torsoCF * C(0, V1_ABDOMEN_OFFSET, 0)
			local pelvisCF = torsoCF * C(0, V1_PELVIS_OFFSET, 0)

			local headPitch = camPitch * 0.85 - torsoPitch * 0.45 + math.sin(t * 2.6 + 0.5) * 2.5 * idleWeight
			local headYaw = camYawLocal * 0.75 - torsoYaw * 0.35
			local headCF = chestCF * C(0, 1.06, -0.06) * angles(headPitch, headYaw, -torsoRoll * 0.4)

			-- Arms (Right = Marksman Revolver, Left = Feedbacker Parry / Coin Toss)
			local rUpperPitch = 38 + camPitch * 0.72 + math.sin(t * 2.6) * 2.0 * idleWeight - sinW * 14 * STATE.walkBlend * (1 - STATE.sprintBlend * 0.5)
			local rUpperYaw = -10 + camYawLocal * 0.45
			local rUpperRoll = -8
			local rForePitch = 42 + camPitch * 0.18

			local lUpperPitch = -16 * idleWeight + sinW * (28 + STATE.sprintBlend * 18) * STATE.walkBlend
			local lUpperYaw = 10 * idleWeight
			local lUpperRoll = 12 + STATE.airBlend * 16
			local lForePitch = 28 + math.max(0, sinW) * 22 * STATE.walkBlend + STATE.airBlend * 14

			if STATE.isGliding and isAir then
				lUpperPitch, lUpperRoll, lForePitch = -14, 38, 18
			elseif STATE.slam.active and isAir then
				lUpperPitch, lUpperRoll, lForePitch = 45, 10, 62
				rUpperPitch, rForePitch = 52 + camPitch * 0.4, 58
			end

			-- Coin Toss & Ricochet / Coin-Punch Logic
			local ca = STATE.custom.coinAttack
			if ca.active then
				local cEl = now - ca.startTime
				local dtCoin = 1 / 60
				ca.tossVel = ca.tossVel + V(0, -48 * dtCoin, 0)
				ca.tossPos = ca.tossPos + ca.tossVel * dtCoin
				ca.coinCF = C(ca.tossPos) * angles(cEl * 980, cEl * 420, cEl * 310)

				if cEl < 0.24 then
					local k = easeOutQuad(cEl / 0.24)
					lUpperPitch = lerp(lUpperPitch, 86, k)
					lForePitch = lerp(lForePitch, 18, k)
				elseif cEl < 0.52 and not ca.shotFired then
					ca.shotFired = true
					local muzzleCF = (STATE.buckets.v1gun and STATE.buckets.v1gun[1] and STATE.buckets.v1gun[1].targetCF) or (chestCF * C(1.1, 0.2, -1.6))
					local originPos = (inFP and cam) and (cam.CFrame * C(0.65, -0.35, -1.5)).Position or muzzleCF.Position
					local fallbackPos = (cam and (cam.CFrame.Position + cam.CFrame.LookVector * 65)) or (hrp.Position + hrp.CFrame.LookVector * 65)
					local targetPos, targetChar = findNearestCoinTarget(c, ca.tossPos, fallbackPos)

					Core.playSFX("SHATTER", 1.15, 0.9, "PARRY")
					fireRicochetBeams(STATE, originPos, ca.tossPos, targetPos, false)
					Core.addStyleBonus("+RICOSHOT", 125, PALETTE.COIN_GOLD)

					if targetChar then
						Core.applyF3XKnockback(targetChar, targetPos - ca.tossPos, COIN_KNOCKBACK_POWER)
					end
					if STATE.coinPart and STATE.coinPart.part then
						Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
					end
					ca.coinCF = PARK_CF
				elseif cEl >= 0.72 then
					ca.active = false
					ca.coinCF = PARK_CF
				end

				if ca.shotFired and (now - ca.startTime) < 0.44 then
					rUpperPitch += 24
					rForePitch += 14
				end
			end

			if STATE.coinPart and STATE.coinPart.part then
				STATE.coinPart.targetCF = ca.active and not ca.shotFired and ca.coinCF or PARK_CF
				STATE.coinPart.part.CFrame = STATE.coinPart.targetCF
			end

			-- Feedbacker Parry / Coin-Punch Logic
			local pa = STATE.custom.parryAttack
			if pa.active then
				local pEl = now - pa.startTime
				if pEl < 0.14 then
					local k = easeOutBack(pEl / 0.14)
					lUpperPitch = lerp(-12, 92 + camPitch * 0.75, k)
					lUpperYaw = lerp(12, -18, k)
					lUpperRoll = lerp(14, -10, k)
					lForePitch = lerp(42, 8, k)
				elseif pEl < 0.38 then
					local k = easeOutQuad((pEl - 0.14) / 0.24)
					lUpperPitch = lerp(92 + camPitch * 0.75, -12, k)
					lForePitch = lerp(8, 28, k)
				else
					pa.active = false
				end

				if not pa.hitTriggered and pEl >= 0.05 then
					pa.hitTriggered = true
					if ca.active and not ca.shotFired and (ca.tossPos - hrp.Position).Magnitude < 12 then
						ca.shotFired = true
						ca.punched = true
						local fallbackPos = (cam and (cam.CFrame.Position + cam.CFrame.LookVector * 80)) or (hrp.Position + hrp.CFrame.LookVector * 80)
						local targetPos, targetChar = findNearestCoinTarget(c, ca.tossPos, fallbackPos)
						Core.playSFX("PARRY", 1.15, 1.0)
						Core.triggerHitstop(0.11, PALETTE.PARRY_FLASH)
						fireRicochetBeams(STATE, hrp.Position, ca.tossPos, targetPos, true)
						Core.addStyleBonus("+FISTFUL OF DOLLAR", 240, PALETTE.COIN_GOLD)
						if targetChar then
							Core.applyF3XKnockback(targetChar, targetPos - hrp.Position, COIN_PUNCH_KNOCKBACK_POWER)
						end
						if STATE.coinPart and STATE.coinPart.part then
							Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
						end
						ca.coinCF = PARK_CF
					else
						local meleeChar, meleeHRP = findNearestMeleeTarget(c, hrp)
						if meleeChar and meleeHRP then
							Core.playSFX("PARRY", 1.0, 1.0)
							Core.triggerHitstop(0.10, PALETTE.PARRY_FLASH)
							Core.spawnFlash(meleeHRP.Position, PALETTE.PARRY_FLASH, 1.2, 5.4, 0.24)
							Core.spawnRing(meleeHRP.Position, PALETTE.PARRY_FLASH, 0.9, 6.2, 0.26)
							Core.addStyleBonus("+PARRY", 200, PALETTE.PARRY_FLASH)
							Core.applyF3XKnockback(meleeChar, meleeHRP.Position - hrp.Position, PARRY_KNOCKBACK_POWER)
						else
							Core.playSFX("PUNCH", 1.08, 0.75, "PARRY")
						end
					end
				end
			end

			local shoulderL = chestCF * C(-1.06, 0.24, 0)
			local shoulderR = chestCF * C(1.06, 0.24, 0)
			if STATE.fpArms and cam then
				shoulderL = cam.CFrame * C(-1.05, -0.78, -0.82) * angles(-camPitch * 0.2, 0, 0)
				shoulderR = cam.CFrame * C(1.02, -0.78, -0.85) * angles(-camPitch * 0.2, 0, 0)
			end

			local lUpperCF = shoulderL * angles(lUpperPitch, lUpperYaw, lUpperRoll)
			local lForeCF = lUpperCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(lForePitch, 0, 0)
			local lHandCF = lForeCF * C(0, -V1_FOREARM_LEN, 0)

			local rUpperCF = shoulderR * angles(rUpperPitch, rUpperYaw, rUpperRoll)
			local rForeCF = rUpperCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(rForePitch, 0, 0)
			local rHandCF = rForeCF * C(0, -V1_FOREARM_LEN, 0)
			local gunCF = rHandCF * GUN_MOUNT_REL

			-- Legs (Walk/Sprint/Slide/Air/Glide/Slam)
			local lThighP, rThighP = 8 * idleWeight, -6 * idleWeight
			local lShinP, rShinP = -12 * idleWeight, -8 * idleWeight
			local lFootP, rFootP = 4 * idleWeight, 14 * idleWeight

			if STATE.walkBlend > 0.01 then
				local stride = 36 + STATE.sprintBlend * 22
				lThighP = lerp(lThighP, sinW * stride, STATE.walkBlend)
				rThighP = lerp(rThighP, -sinW * stride, STATE.walkBlend)
				lShinP = lerp(lShinP, -math.max(0, -cosW) * (46 + STATE.sprintBlend * 22) - 8, STATE.walkBlend)
				rShinP = lerp(rShinP, -math.max(0, cosW) * (46 + STATE.sprintBlend * 22) - 8, STATE.walkBlend)
				lFootP = lerp(lFootP, cosW * 16, STATE.walkBlend)
				rFootP = lerp(rFootP, -cosW * 16, STATE.walkBlend)
			end

			if STATE.airBlend > 0.01 then
				local airTuckL, airTuckR = 26, 44
				local shinTuckL, shinTuckR = -38, -68
				if STATE.slam.active then
					airTuckL, airTuckR = 62, 68
					shinTuckL, shinTuckR = -96, -104
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

			local hipL = pelvisCF * C(-0.46, V1_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, V1_HIP_Y, 0)
			local lThighCF = hipL * angles(lThighP, 8 * idleWeight, -4)
			local rThighCF = hipR * angles(rThighP, -6 * idleWeight, 4)
			local lShinCF = lThighCF * C(0, -V1_THIGH_LEN, 0) * angles(lShinP, 0, 0)
			local rShinCF = rThighCF * C(0, -V1_THIGH_LEN, 0) * angles(rShinP, 0, 0)
			local lFootCF = lShinCF * C(0, -V1_SHIN_LEN, 0) * angles(lFootP, 0, 0)
			local rFootCF = rShinCF * C(0, -V1_SHIN_LEN, 0) * angles(rFootP, 0, 0)

			-- Wings (Spread & Flutter on Glide, Folded on Slam)
			local baseFan = { 48, 18, -14, -46 }
			local wingSpread = STATE.isGliding and 1.28 or (STATE.slam.active and 0.45 or (1.0 + STATE.airBlend * 0.14 + STATE.sprintBlend * 0.10))
			local wingSweep = STATE.isGliding and -14 or (STATE.slam.active and 36 or (-24 - STATE.sprintBlend * 14))
			local wingFlutter = STATE.isGliding and (math.sin(now * 24) * 5.5) or (math.sin(t * 3.2) * 2.2)

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

			applyBucket("v1head", headCF, true)
			applyBucket("v1chest", { chest = chestCF, abdomen = abdomenCF, pelvis = pelvisCF }, true)
			applyBucket("v1core", chestCF, true)
			applyBucket("v1upperArm", { lUpperArm = lUpperCF, rUpperArm = rUpperCF }, not STATE.fpArms)
			applyBucket("v1forearm", { lForearm = lForeCF, rForearm = rForeCF }, not STATE.fpArms)
			applyBucket("v1hand", { lHand = lHandCF, rHand = rHandCF }, not STATE.fpArms)
			applyBucket("v1thigh", { lThigh = lThighCF, rThigh = rThighCF }, true)
			applyBucket("v1shin", { lShin = lShinCF, rShin = rShinCF }, true)
			applyBucket("v1foot", { lFoot = lFootCF, rFoot = rFootCF }, true)
			applyBucket("v1gun", gunCF, not STATE.fpArms)

			if STATE.buckets.v1wing then
				for _, e in ipairs(STATE.buckets.v1wing) do
					local idx = e.wingIdx or 1
					local fanAng = baseFan[idx] * wingSpread + wingFlutter * (idx % 2 == 0 and 1 or -1)
					local mountCF = chestCF * C(e.side * 0.48, 0.24, 0.72) * angles(0, e.side * wingSweep, e.side * fanAng)
					e.targetCF = mountCF * e.relCF
					e.part.CFrame = e.targetCF
					e.part.LocalTransparencyModifier = inFP and 1 or 0
				end
			end

			local coinCharge = clamp((now - ca.lastUsed) / COIN_COOLDOWN, 0, 1)
			local hudStatus = {
				weaponTitle = "MARKSMAN REVOLVER",
				weaponColor = PALETTE.MARKSMAN_GREEN,
				chargeFrac = coinCharge,
				pipColor = PALETTE.COIN_GOLD,
				pipDimColor = Color3.fromRGB(165, 130, 32),
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