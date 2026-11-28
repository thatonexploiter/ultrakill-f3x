-- ULTRAKILL V1 MODULE (REWORKED MODEL + FULL ARTICULATED ANIMATIONS + MARKSMAN 4-COIN CHAIN + FEEDBACKER)
-- Carregado dinamicamente pelo loader.lua recebendo Core

return function(Core)
	local C, V = Core.C, Core.V
	local ID_CF, PARK_CF = Core.ID_CF, Core.PARK_CF
	local clamp, lerp, easeOutQuad, easeOutBack = Core.clamp, Core.lerp, Core.easeOutQuad, Core.easeOutBack
	local angles, mirrorRelCF = Core.angles, Core.mirrorRelCF

	local PALETTE = {
		BLUE_ARMOR = Color3.fromRGB(34, 72, 158),
		LIGHT_BLUE_ARMOR = Color3.fromRGB(64, 112, 212),
		DARK_BLUE_TRIM = Color3.fromRGB(22, 46, 108),
		DARK_METAL = Color3.fromRGB(28, 31, 38),
		GUN_STEEL = Color3.fromRGB(72, 80, 96),
		SILVER_TRIM = Color3.fromRGB(178, 188, 204),
		BLACK_TRIM = Color3.fromRGB(14, 16, 20),
		BARCODE_WHITE = Color3.fromRGB(215, 222, 232),
		YELLOW_NEON = Color3.fromRGB(255, 204, 28),
		EYE_CORE = Color3.fromRGB(255, 244, 165),
		WING_TIP_GOLD = Color3.fromRGB(255, 224, 88),
		MARKSMAN_GREEN = Color3.fromRGB(70, 255, 132),
		COIN_GOLD = Color3.fromRGB(255, 214, 48),
		BEAM_CYAN = Color3.fromRGB(110, 238, 255),
		PARRY_FLASH = Color3.fromRGB(255, 245, 175),
		BLOOD_RED = Color3.fromRGB(172, 22, 30),
	}

	-------------------------------------------------------------------
	-- PROPORÇÕES BIOMECÂNICAS DO V1
	-------------------------------------------------------------------
	local V1_PELVIS_OFFSET = -0.78
	local V1_ABDOMEN_FROM_PELVIS = 0.56 -- -0.22 relativo ao centro
	local V1_CHEST_FROM_ABDOMEN = 0.76  -- +0.54 relativo ao centro
	local V1_HIP_Y = -0.14
	local V1_THIGH_LEN = 1.22
	local V1_SHIN_LEN = 1.18
	local V1_SOLE_DEPTH_FROM_ANKLE = 0.36
	local V1_SOLE_DEPTH = math.abs(V1_PELVIS_OFFSET) + math.abs(V1_HIP_Y) + V1_THIGH_LEN + V1_SHIN_LEN + V1_SOLE_DEPTH_FROM_ANKLE -- 3.68
	local V1_UPPER_ARM_LEN = 1.04
	local V1_FOREARM_LEN = 1.00
	local GUN_MOUNT_REL = ID_CF
	local GUN_MUZZLE_LOCAL = C(0, -1.66, -0.29)

	-------------------------------------------------------------------
	-- PARÂMETROS DE COMBATE ULTRAKILL
	-------------------------------------------------------------------
	local MAX_COINS = 4
	local COIN_RECHARGE_TIME = 2.60
	local COIN_TOSS_DEBOUNCE = 0.14
	local COIN_AUTO_SHOT_DELAY = 0.42
	local COIN_SPLIT_MIN = 0.25
	local COIN_SPLIT_MAX = 0.46
	local COIN_LIFETIME = 2.60
	local COIN_RANGE = 95

	local PARRY_COOLDOWN = 0.38
	local PARRY_RANGE = 12.5
	local COIN_PUNCH_RANGE = 14.5

	local PARRY_KNOCKBACK_POWER = { speed = 72, up = 34, spin = 12.5 }
	local COIN_KNOCKBACK_POWER = { speed = 52, up = 26, spin = 9.5 }
	local SPLIT_KNOCKBACK_POWER = { speed = 64, up = 30, spin = 11.5 }
	local COIN_PUNCH_KNOCKBACK_POWER = { speed = 102, up = 48, spin = 17.0 }

	-------------------------------------------------------------------
	-- HELPERS MATEMÁTICOS & ANIMAÇÃO
	-------------------------------------------------------------------
	local function damp(cur, target, speed, dt)
		return lerp(cur, target, 1 - math.exp(-speed * dt))
	end

	local function dampAngle(cur, target, speed, dt)
		local diff = ((target - cur + 180) % 360) - 180
		return cur + diff * (1 - math.exp(-speed * dt))
	end

	local function evalStrideLeg(phase, sprint, walkBlend)
		local s = math.sin(phase)
		local c = math.cos(phase)
		local swingLift = math.max(0, s)
		local passTuck = math.max(0, -c) * clamp(s * 0.8 + 0.65, 0, 1)

		local fwdAngle = 36 + sprint * 22
		local backAngle = 30 + sprint * 18
		local thighP = (s >= 0) and (s * fwdAngle) or (s * backAngle)

		-- Joelho: dobra forte na passagem para frente e fica atlético na fase de apoio
		local swingKnee = -passTuck * (54 + sprint * 34) - swingLift * 14
		local stanceKnee = -10 - math.max(0, -s) * (12 + sprint * 8)
		local shinP = (s >= 0) and swingKnee or stanceKnee

		-- Pé: dorsiflexão antes do contato e impulso na ponta ao empurrar para trás
		local heelPrep = math.max(0, c) * swingLift * 18
		local toePush = -math.max(0, -s) * (18 + sprint * 14)
		local footP = (heelPrep + toePush) * walkBlend

		return thighP, shinP, footP
	end

	-------------------------------------------------------------------
	-- BLUEPRINTS DO V1 (MODELO REWORKED FIEL AO ULTRAKILL)
	-------------------------------------------------------------------
	local function getV1HeadSpecs()
		return {
			-- Pescoço articulado com pistões laterais e colarinho
			{ partType = "Cylinder", size = V(0.38, 0.24, 0.24), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.36, 0.06) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.38, 0.10, 0.10), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.20, relCF = C(-0.15, -0.35, -0.01) * angles(10, 0, 82) },
			{ partType = "Cylinder", size = V(0.38, 0.10, 0.10), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.20, relCF = C(0.15, -0.35, -0.01) * angles(10, 0, 98) },
			{ partType = "Normal",   size = V(0.46, 0.10, 0.42), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, -0.24, 0.04) },

			-- Corpo principal da cabeça estilo câmera
			{ partType = "Normal",   size = V(0.74, 0.56, 1.14), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.05, 0.05) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.84, 0.19, 1.32), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.42, -0.03) * angles(-5, 0, 0) },
			{ partType = "Normal",   size = V(0.86, 0.09, 0.44), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.35, -0.58) * angles(-13, 0, 0) },
			{ partType = "Wedge",    size = V(0.14, 0.14, 1.02), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0.52, 0.10) * angles(-4, 0, 0) },

			-- Bochechas chanfradas
			{ partType = "Wedge",    size = V(0.14, 0.50, 1.00), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.41, 0.02, 0.02) * angles(-6, -10, 6) },
			{ partType = "Wedge",    size = V(0.14, 0.50, 1.00), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.41, 0.02, 0.02) * angles(-6, 10, -6) },
			{ partType = "Cylinder", size = V(0.90, 0.18, 0.18), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, 0.04, 0.08) },

			-- Barcode / stencil no lado esquerdo da cabeça (-X, fiel à referência)
			{ partType = "Normal",   size = V(0.03, 0.16, 0.28), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.41, 0.12, -0.14) * angles(-6, -10, 6) },
			{ partType = "Normal",   size = V(0.035, 0.12, 0.04), color = PALETTE.BARCODE_WHITE, mat = Enum.Material.SmoothPlastic, relCF = C(-0.415, 0.12, -0.21) * angles(-6, -10, 6) },
			{ partType = "Normal",   size = V(0.035, 0.12, 0.03), color = PALETTE.BARCODE_WHITE, mat = Enum.Material.SmoothPlastic, relCF = C(-0.415, 0.12, -0.13) * angles(-6, -10, 6) },
			{ partType = "Normal",   size = V(0.035, 0.12, 0.05), color = PALETTE.BARCODE_WHITE, mat = Enum.Material.SmoothPlastic, relCF = C(-0.415, 0.12, -0.05) * angles(-6, -10, 6) },

			-- Bateria / carcaça traseira e queixo
			{ partType = "Normal",   size = V(0.58, 0.46, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, 0.06, 0.66) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.40, 0.20, 0.12), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, ref = 0.15, relCF = C(0, 0.17, 0.79) * angles(-6, 0, 0) },
			{ partType = "Normal",   size = V(0.10, 0.06, 0.05), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.14, 0.02, 0.80) * angles(-6, 0, 0) },
			{ partType = "Wedge",    size = V(0.58, 0.18, 0.74), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, -0.24, -0.12) * angles(174, 0, 0) },

			-- Visor frontal + lente de câmera em camadas (aro, lente amarela, núcleo óptico)
			{ partType = "Normal",   size = V(0.64, 0.46, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.04, -0.51) * angles(-6, 0, 0) },
			{ partType = "Cylinder", size = V(0.11, 0.46, 0.46), color = PALETTE.GUN_STEEL,   mat = Enum.Material.Metal, ref = 0.20, relCF = C(0, 0.04, -0.56) * angles(-6, 0, 0) * angles(0, 90, 0) },
			{ partType = "Cylinder", size = V(0.13, 0.36, 0.36), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon,  relCF = C(0, 0.04, -0.58) * angles(-6, 0, 0) * angles(0, 90, 0), light = true },
			{ partType = "Cylinder", size = V(0.14, 0.16, 0.16), color = PALETTE.EYE_CORE,    mat = Enum.Material.Neon,  relCF = C(0, 0.04, -0.59) * angles(-6, 0, 0) * angles(0, 90, 0) },
		}
	end

	local function getV1ChestSpecs()
		return {
			-- Chassi principal com V-taper
			{ partType = "Normal",   size = V(1.66, 0.74, 0.72), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.12, 0.02) },
			{ partType = "Wedge",    size = V(0.74, 0.60, 0.26), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.46, 0.16, -0.43) * angles(0, 12, 180) },
			{ partType = "Wedge",    size = V(0.74, 0.60, 0.26), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.46, 0.16, -0.43) * angles(0, -12, 180) },

			-- Canal central do esterno e núcleo frontal
			{ partType = "Normal",   size = V(0.30, 0.74, 0.22), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, 0.10, -0.35) },
			{ partType = "Normal",   size = V(0.10, 0.42, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.15, -0.44), light = true },

			-- Entradas de ar inferiores + LEDs âmbar
			{ partType = "Normal",   size = V(0.42, 0.17, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.50, -0.08, -0.42) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.42, 0.17, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.50, -0.08, -0.42) * angles(-10, -12, 0) },
			{ partType = "Normal",   size = V(0.32, 0.06, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.50, -0.08, -0.46) * angles(-10, 12, 0) },
			{ partType = "Normal",   size = V(0.32, 0.06, 0.08), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0.50, -0.08, -0.46) * angles(-10, -12, 0) },

			-- Stencil "V1" no peito esquerdo (-X, leitura correta visto de frente)
			{ partType = "Normal",   size = V(0.035, 0.17, 0.04), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.37, 0.22, -0.50) * angles(-10, 12, -16) },
			{ partType = "Normal",   size = V(0.035, 0.17, 0.04), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.44, 0.22, -0.485) * angles(-10, 12, 16) },
			{ partType = "Normal",   size = V(0.035, 0.17, 0.04), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(-0.55, 0.22, -0.46) * angles(-10, 12, 0) },

			-- Colarinho e ombreiras chanfradas do tórax
			{ partType = "Wedge",    size = V(0.30, 0.34, 0.76), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.62, 0.60, 0.02) * angles(0, 0, -18) },
			{ partType = "Wedge",    size = V(0.30, 0.34, 0.76), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.62, 0.60, 0.02) * angles(0, 0, 18) },
			{ partType = "Normal",   size = V(0.82, 0.18, 0.66), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, 0.54, 0.04) },
			{ partType = "Normal",   size = V(1.10, 0.30, 0.60), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, -0.32, 0.02) },
			{ partType = "Cylinder", size = V(1.94, 0.34, 0.34), color = PALETTE.BLACK_TRIM, mat = Enum.Material.Metal, relCF = C(0, 0.24, 0.02) },
		}
	end

	local function getV1AbdomenSpecs()
		return {
			{ partType = "Cylinder", size = V(0.86, 0.36, 0.36), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.08, relCF = C(0, 0.0, 0.04) * angles(0, 0, 90) },
			{ partType = "Normal",   size = V(0.64, 0.72, 0.44), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.0, 0.0) },
			{ partType = "Normal",   size = V(0.74, 0.15, 0.48), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.14, relCF = C(0, 0.14, 0.0) },
			{ partType = "Normal",   size = V(0.70, 0.15, 0.46), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.14, relCF = C(0, -0.14, 0.0) },
			{ partType = "Cylinder", size = V(0.76, 0.12, 0.12), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(-0.27, 0.0, -0.18) * angles(0, 0, 84) },
			{ partType = "Cylinder", size = V(0.76, 0.12, 0.12), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(0.27, 0.0, -0.18) * angles(0, 0, 96) },
			-- Tubos externos de combustível sanguíneo
			{ partType = "Cylinder", size = V(0.62, 0.09, 0.09), color = PALETTE.BLOOD_RED, mat = Enum.Material.SmoothPlastic, relCF = C(-0.39, 0.0, -0.10) * angles(0, 0, 80) },
			{ partType = "Cylinder", size = V(0.62, 0.09, 0.09), color = PALETTE.BLOOD_RED, mat = Enum.Material.SmoothPlastic, relCF = C(0.39, 0.0, -0.10) * angles(0, 0, 100) },
		}
	end

	local function getV1PelvisSpecs()
		return {
			{ partType = "Normal",   size = V(1.06, 0.34, 0.56), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.02, 0) },
			{ partType = "Wedge",    size = V(0.56, 0.34, 0.36), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.07, -0.26) * angles(180, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.36, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(-0.58, -0.06, 0.02) * angles(0, 0, 14) },
			{ partType = "Normal",   size = V(0.16, 0.36, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0.58, -0.06, 0.02) * angles(0, 0, -14) },
			{ partType = "Normal",   size = V(0.12, 0.28, 0.40), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(-0.63, -0.06, 0.00) * angles(0, 0, 14) },
			{ partType = "Normal",   size = V(0.12, 0.28, 0.40), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.63, -0.06, 0.00) * angles(0, 0, -14) },
			{ partType = "Cylinder", size = V(1.08, 0.28, 0.28), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -0.14, 0) },
		}
	end

	local function getV1CoreSpecs()
		return {
			-- Carcaça dorsal V-pack das asas + propulsores
			{ partType = "Normal",   size = V(0.84, 0.86, 0.38), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, 0.14, 0.52) },
			{ partType = "Wedge",    size = V(0.74, 0.28, 0.38), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0.62, 0.50) * angles(16, 0, 0) },
			{ partType = "Normal",   size = V(0.48, 0.92, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0.12, 0.66) },
			{ partType = "Normal",   size = V(0.24, 0.82, 0.26), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(-0.36, 0.18, 0.70) * angles(0, 0, 16) },
			{ partType = "Normal",   size = V(0.24, 0.82, 0.26), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0.36, 0.18, 0.70) * angles(0, 0, -16) },
			{ partType = "Normal",   size = V(0.16, 0.56, 0.12), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(0, 0.14, 0.78), light = true },
			{ partType = "Normal",   size = V(0.44, 0.22, 0.30), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.34, 0.60) * angles(-18, 0, 0) },
		}
	end

	local function getV1SingleWingParts(wingIdx)
		-- Escala elegante por asa (superior longa, inferiores afuniladas como no conceito do V1)
		local lenScale = ({ 1.04, 0.96, 0.88, 0.78 })[wingIdx] or 0.92
		local bladeLen = 1.92 * lenScale
		local tipLen = 0.94 * lenScale
		local bladeCenterX = 1.10 + bladeLen * 0.5
		local tipCenterX = 1.10 + bladeLen + tipLen * 0.5
		return {
			{ partType = "Cylinder", size = V(0.18, 0.20, 0.20), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0.06, 0, 0) * angles(0, 90, 0) },
			{ partType = "Normal",   size = V(0.68, 0.12, 0.14), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0.42, 0, 0) },
			{ partType = "Wedge",    size = V(0.16, 0.26, 0.86), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0.84, 0.08, 0) * angles(0, -90, 0) },
			{ partType = "Normal",   size = V(0.86, 0.10, 0.12), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(1.06, -0.04, 0) },
			{ partType = "Normal",   size = V(bladeLen, 0.24, 0.06), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(bladeCenterX, 0.01, 0) },
			{ partType = "Wedge",    size = V(0.06, 0.24, tipLen), color = PALETTE.WING_TIP_GOLD, mat = Enum.Material.Neon, relCF = C(tipCenterX, 0.01, 0) * angles(0, -90, 0) },
		}
	end

	local function getV1UpperArmSpecs(isFeedbacker)
		-- Referência do Wiki: bíceps com maquinário preto exposto + ombreira azul arredondada + pistão
		local pauldronColor = isFeedbacker and PALETTE.BLUE_ARMOR or PALETTE.DARK_METAL
		return {
			{ partType = "Ball",     size = V(0.40, 0.40, 0.40), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0, 0) },
			{ partType = "Wedge",    size = V(0.56, 0.34, 0.56), color = pauldronColor, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.08, 0) * angles(0, 0, isFeedbacker and -16 or 16) },
			{ partType = "Normal",   size = V(0.32, 0.70, 0.34), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.48, 0) },
			{ partType = "Normal",   size = V(0.36, 0.28, 0.38), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.32, 0) },
			{ partType = "Cylinder", size = V(0.62, 0.10, 0.10), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(isFeedbacker and -0.18 or 0.18, -0.52, -0.10) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.34, 0.26, 0.26), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -V1_UPPER_ARM_LEN, 0) },
		}
	end

	local function getV1ForearmSpecs(isFeedbacker)
		if isFeedbacker then
			-- Feedbacker oficial: manga azul, chassi prata, tubo hidráulico lateral e cabo vermelho traseiro
			return {
				{ partType = "Ball",     size = V(0.30, 0.30, 0.30), color = PALETTE.DARK_METAL,  mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0, 0) },
				{ partType = "Normal",   size = V(0.42, 0.78, 0.44), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(0, -0.46, 0) },
				{ partType = "Normal",   size = V(0.48, 0.54, 0.48), color = PALETTE.BLUE_ARMOR,  mat = Enum.Material.SmoothPlastic, relCF = C(-0.02, -0.58, -0.03) },
				{ partType = "Cylinder", size = V(0.68, 0.11, 0.11), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.25, relCF = C(-0.26, -0.46, 0.02) * angles(0, 0, 90) },
				{ partType = "Cylinder", size = V(0.74, 0.09, 0.09), color = PALETTE.BLOOD_RED,   mat = Enum.Material.SmoothPlastic, relCF = C(0.06, -0.48, 0.25) * angles(0, 0, 90) },
				{ partType = "Normal",   size = V(0.10, 0.42, 0.10), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.24, -0.54, -0.16) },
				{ partType = "Cylinder", size = V(0.50, 0.14, 0.14), color = PALETTE.GUN_STEEL,   mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -0.46, 0.22) * angles(0, 0, 90) },
			}
		end
		return {
			{ partType = "Ball",     size = V(0.28, 0.28, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.38, 0.78, 0.40), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.48, 0) },
			{ partType = "Normal",   size = V(0.42, 0.20, 0.44), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.84, 0) },
			{ partType = "Cylinder", size = V(0.64, 0.08, 0.08), color = PALETTE.BLOOD_RED,  mat = Enum.Material.SmoothPlastic, relCF = C(0.14, -0.46, 0.18) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.46, 0.14, 0.14), color = PALETTE.GUN_STEEL,  mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -0.46, 0.19) * angles(0, 0, 90) },
		}
	end

	local function getV1HandSpecs(isFist)
		if isFist then
			return {
				-- Palma e barra de juntas do Feedbacker
				{ partType = "Normal", size = V(0.38, 0.30, 0.42), color = PALETTE.DARK_METAL,  mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.16, 0) },
				{ partType = "Normal", size = V(0.44, 0.16, 0.48), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(0, -0.28, -0.02) },
				{ partType = "Normal", size = V(0.10, 0.08, 0.08), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.25, relCF = C(-0.13, -0.32, -0.26) },
				{ partType = "Normal", size = V(0.10, 0.08, 0.08), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.25, relCF = C(0.00, -0.32, -0.27) },
				{ partType = "Normal", size = V(0.10, 0.08, 0.08), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.25, relCF = C(0.13, -0.32, -0.26) },
				{ partType = "Normal", size = V(0.14, 0.14, 0.10), color = PALETTE.YELLOW_NEON, mat = Enum.Material.Neon, relCF = C(-0.16, -0.22, -0.18), light = true },
				-- Dedos articulados (gira em torno do nó das juntas!)
				{ partType = "Normal", size = V(0.40, 0.22, 0.18), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.11, -0.06), subKey = "lFingers" },
			}
		end
		return {
			{ partType = "Normal", size = V(0.36, 0.32, 0.38), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.17, 0) },
			{ partType = "Normal", size = V(0.40, 0.18, 0.42), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.32, -0.02) },
			{ partType = "Normal", size = V(0.16, 0.24, 0.16), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0.12, -0.40, -0.06) },
		}
	end

	local function getV1ThighSpecs(side)
		return {
			{ partType = "Ball",     size = V(0.42, 0.42, 0.42), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.56, 0.96, 0.56), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56, 0) },
			{ partType = "Wedge",    size = V(0.48, 0.42, 0.22), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.44, -0.32) * angles(8, 0, 0) },
			{ partType = "Normal",   size = V(0.16, 0.62, 0.10), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.60, -0.28) },
			-- Tubo de sangue externo nas coxas
			{ partType = "Cylinder", size = V(0.76, 0.08, 0.08), color = PALETTE.BLOOD_RED, mat = Enum.Material.SmoothPlastic, relCF = C(side * 0.29, -0.56, 0.06) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.38, 0.30, 0.30), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -V1_THIGH_LEN, 0) },
		}
	end

	local function getV1ShinSpecs()
		return {
			{ partType = "Ball",     size = V(0.32, 0.32, 0.32), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, 0, 0) },
			{ partType = "Normal",   size = V(0.46, 0.96, 0.46), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.56, 0) },
			-- Joelheira angulada pontuda
			{ partType = "Wedge",    size = V(0.38, 0.48, 0.28), color = PALETTE.LIGHT_BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.14, -0.26) * angles(-14, 0, 0) },
			{ partType = "Normal",   size = V(0.14, 0.72, 0.10), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.62, -0.22) },
			{ partType = "Cylinder", size = V(0.60, 0.12, 0.12), color = PALETTE.SILVER_TRIM, mat = Enum.Material.Metal, ref = 0.22, relCF = C(0, -0.54, 0.25) * angles(0, 0, 90) },
			{ partType = "Cylinder", size = V(0.28, 0.24, 0.24), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.16, relCF = C(0, -V1_SHIN_LEN, 0) },
		}
	end

	local function getV1FootSpecs()
		return {
			{ partType = "Normal", size = V(0.36, 0.18, 0.46), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.10, -0.05) },
			{ partType = "Normal", size = V(0.44, 0.15, 0.68), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.23, -0.18) },
			{ partType = "Wedge",  size = V(0.40, 0.18, 0.36), color = PALETTE.BLUE_ARMOR, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.22, -0.58) },
			{ partType = "Normal", size = V(0.38, 0.08, 0.72), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.32, -0.26) },
			{ partType = "Normal", size = V(0.28, 0.20, 0.28), color = PALETTE.DARK_METAL, mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.21, 0.22) * angles(22, 0, 0) },
		}
	end

	local function getV1GunSpecs()
		return {
			-- Cabo ergonômico e guarda-mato
			{ partType = "Normal",   size = V(0.18, 0.26, 0.50), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.24, 0.04) * angles(-18, 0, 0) },
			{ partType = "Normal",   size = V(0.21, 0.28, 0.10), color = PALETTE.SILVER_TRIM,    mat = Enum.Material.Metal, ref = 0.22, relCF = C(0, -0.16, 0.29) * angles(-18, 0, 0) },
			{ partType = "Normal",   size = V(0.07, 0.26, 0.06), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.45, 0.06) },
			{ partType = "Normal",   size = V(0.07, 0.06, 0.18), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.57, -0.02) },
			-- Armação inferior e moldura do tambor
			{ partType = "Normal",   size = V(0.22, 0.62, 0.20), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.48, -0.14) },
			{ partType = "Normal",   size = V(0.18, 0.44, 0.07), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal, ref = 0.10, relCF = C(0, -0.56, -0.44) },
			-- Cano slab ventilado estilo ULTRAKILL ACT 2 Remake
			{ partType = "Normal",   size = V(0.22, 0.90, 0.24), color = PALETTE.GUN_STEEL,      mat = Enum.Material.Metal, ref = 0.18, relCF = C(0, -1.16, -0.29) },
			{ partType = "Normal",   size = V(0.16, 0.84, 0.10), color = PALETTE.BLUE_ARMOR,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.14, -0.44) },
			{ partType = "Normal",   size = V(0.15, 0.70, 0.12), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.08, -0.14) },
			{ partType = "Cylinder", size = V(0.14, 0.16, 0.16), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -1.62, -0.29) * angles(0, 0, 90) },
			-- Moldura da tela traseira das 4 moedas + mira frontal
			{ partType = "Normal",   size = V(0.24, 0.18, 0.20), color = PALETTE.DARK_METAL,     mat = Enum.Material.Metal, ref = 0.12, relCF = C(0, -0.20, -0.34) * angles(22, 0, 0) },
			{ partType = "Normal",   size = V(0.22, 0.04, 0.15), color = PALETTE.BLACK_TRIM,     mat = Enum.Material.SmoothPlastic, relCF = C(0, -0.14, -0.355) * angles(22, 0, 0) },
			{ partType = "Normal",   size = V(0.05, 0.10, 0.09), color = PALETTE.MARKSMAN_GREEN, mat = Enum.Material.Neon, relCF = C(0, -1.52, -0.50), gunNeon = true },
			-- Trilhos laterais neon verde Marksman
			{ partType = "Normal",   size = V(0.245, 0.68, 0.055), color = PALETTE.MARKSMAN_GREEN, mat = Enum.Material.Neon, relCF = C(0, -1.16, -0.29), gunNeon = true },
		}
	end

	-------------------------------------------------------------------
	-- TARGETING DO V1 (MELEE PARRY + COIN RICOCHET + SPLITSHOT)
	-------------------------------------------------------------------
	local function findNearestMeleeTarget(c, hrp)
		local bestChar, bestHRP, bestDist = nil, nil, PARRY_RANGE
		local myPos, look = hrp.Position, hrp.CFrame.LookVector
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local char = model and model.Parent
			local tHRP = char and Core.getTargetRoot(char)
			if tHRP and tHRP:IsA("BasePart") then
				local diff = tHRP.Position - myPos
				local d = diff.Magnitude
				if d > 0.1 and d < bestDist and (diff.Unit:Dot(look) > -0.30 or d < 5.5) then
					bestDist, bestChar, bestHRP = d, char, tHRP
				end
			end
		end
		return bestChar, bestHRP
	end

	local function findCoinTargets(c, originPos, aimDir, fallbackAimPos)
		local scored = {}
		for _, model in ipairs(Core.getActiveTargetHumanoids(c)) do
			local char = model and model.Parent
			local tHead = char and (char:FindFirstChild("Head") or Core.getTargetRoot(char))
			if tHead and tHead:IsA("BasePart") then
				local diff = tHead.Position - originPos
				local d = diff.Magnitude
				if d > 1.5 and d < COIN_RANGE then
					local aimBias = aimDir and (diff.Unit:Dot(aimDir) * 14) or 0
					scored[#scored + 1] = { pos = tHead.Position, char = char, score = d - aimBias }
				end
			end
		end
		table.sort(scored, function(a, b) return a.score < b.score end)
		if #scored == 0 then
			return fallbackAimPos, nil, nil, nil
		elseif #scored == 1 then
			return scored[1].pos, scored[1].char, nil, nil
		else
			return scored[1].pos, scored[1].char, scored[2].pos, scored[2].char
		end
	end

	local function fireRicochetBeams(STATE, originPos, bouncePos, targetPos, isHeavy, color1, color2)
		if (targetPos - bouncePos).Magnitude < 0.08 then
			targetPos = bouncePos + V(0, 1, 0)
		end
		local c1 = color1 or PALETTE.YELLOW_NEON
		local c2 = color2 or (isHeavy and PALETTE.COIN_GOLD or PALETTE.BEAM_CYAN)
		local w1 = isHeavy and 0.16 or 0.24
		local w2 = isHeavy and 0.54 or 0.40
		STATE.camShake = math.max(STATE.camShake, isHeavy and 0.68 or 0.38)
		STATE.fovKick = math.max(STATE.fovKick, isHeavy and 9 or 5.5)
		Core.fireDualBeams(originPos, bouncePos, targetPos, c1, c2, w1, w2, isHeavy, 0.28)
		Core.spawnImpactFlash(bouncePos, PALETTE.COIN_GOLD, 0.45, 2.6, 0.16)
		Core.spawnImpactFlash(targetPos, c2, 1.1, isHeavy and 6.2 or 4.6, 0.26)
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

			-- V1 Light, Snappy & Floaty Aerial Tuning
			WALK_SPEED = 20,
			SPRINT_SPEED = 38,
			JUMP_POWER = 58,
			AIR_GRAVITY_CANCEL = 0.46,
			GLIDE_GRAVITY_CANCEL = 0.78,
			GLIDE_MAX_FALL = 13,
			AIR_STRAFE_ACCEL = 58,
			AIR_DRAG = 0.22,
			SLAM_STORAGE_JUMP = 112,

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
			STATE.custom = STATE.custom or {}
			STATE.custom.coins = {}
			STATE.custom.coinAmmo = MAX_COINS
			STATE.custom.lastCoinToss = 0
			STATE.custom.shotScheduleAt = 0
			STATE.custom.chainQueue = nil
			STATE.custom.parryAttack = { active = false, lastUsed = 0, startTime = 0, hitTriggered = false }
			STATE.custom.lastMuzzlePos = nil
			STATE.custom.anim = {
				lastNow = nil,
				slide = 0,
				slam = 0,
				glide = 0,
				dash = 0,
				walk = 0,
				sprint = 0,
				air = 0,
				gunRecoil = 0,
				shotAnimUntil = 0,
				cylAngle = 0,
				cylTarget = 0,
				hammerKick = 0,
				triggerPull = 0,
				muzzleEnd = 0,
				muzzleRoll = 0,
				wingPulse = 0,
				landCrush = 0,
				wasAir = false,
				wasSlam = false,
				maxFallVel = 0,
				idleTime = 0,
				spinT = 0,
				spinning = false,
				nextSpinAt = 4.2,
				tossAnimUntil = 0,
				tossAnimStart = 0,
				camPitchS = 0,
				camYawS = 0,
				prevCamLook = nil,
				fpSwayX = 0,
				fpSwayY = 0,
				fpTilt = 0,
				coin1Visible = false,
			}
		end,

		buildModel = function(_, _, _, _, torsoInitCF)
			local specs = {}
			local pelvisCF = torsoInitCF * C(0, V1_PELVIS_OFFSET, 0)
			local abdomenCF = pelvisCF * C(0, V1_ABDOMEN_FROM_PELVIS, 0)
			local chestCF = abdomenCF * C(0, V1_CHEST_FROM_ABDOMEN, 0)
			local headInitCF = chestCF * C(0, 1.06, -0.06)

			for _, hp in ipairs(getV1HeadSpecs()) do
				specs[#specs + 1] = {
					kind = "v1head", partType = hp.partType, relCF = hp.relCF, origCF = headInitCF * hp.relCF,
					origSize = hp.size, origColor = hp.color, origMaterial = hp.mat, origTrans = 0,
					origReflectance = hp.ref or 0, light = hp.light,
				}
			end

			local function addV1(kind, list, parentCF, key)
				for _, sp in ipairs(list) do
					local baseCF = parentCF
					if sp.subKey == "lFingers" then
						baseCF = parentCF * C(0, -0.28, -0.18)
					end
					specs[#specs + 1] = {
						kind = kind, key = sp.subKey or key, partType = sp.partType, relCF = sp.relCF, origCF = baseCF * sp.relCF,
						origSize = sp.size, origColor = sp.color, origMaterial = sp.mat, origTrans = 0,
						origReflectance = sp.ref or 0, light = sp.light, gunNeon = sp.gunNeon,
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

			addV1("v1thigh", getV1ThighSpecs(-1), hipL, "lThigh")
			addV1("v1thigh", getV1ThighSpecs(1), hipR, "rThigh")
			addV1("v1shin", getV1ShinSpecs(), kneeL, "lShin")
			addV1("v1shin", getV1ShinSpecs(), kneeR, "rShin")
			addV1("v1foot", getV1FootSpecs(), ankleL, "lFoot")
			addV1("v1foot", getV1FootSpecs(), ankleR, "rFoot")

			for _, cp in ipairs(getV1CoreSpecs()) do
				specs[#specs + 1] = {
					kind = "v1core", partType = cp.partType, relCF = cp.relCF, origCF = chestCF * cp.relCF,
					origSize = cp.size, origColor = cp.color, origMaterial = cp.mat, origTrans = 0,
					origReflectance = cp.ref or 0, light = cp.light,
				}
			end

			for _, side in ipairs({ -1, 1 }) do
				for wingIdx = 1, 4 do
					for _, wp in ipairs(getV1SingleWingParts(wingIdx)) do
						local relCF = (side == -1) and mirrorRelCF(wp.relCF) or wp.relCF
						specs[#specs + 1] = {
							kind = "v1wing", side = side, wingIdx = wingIdx, partType = wp.partType, relCF = relCF,
							origCF = chestCF * relCF, origSize = wp.size, origColor = wp.color, origMaterial = wp.mat, origTrans = 0,
							origReflectance = wp.ref or 0,
						}
					end
				end
			end

			local gunInitCF = wristR * GUN_MOUNT_REL
			for _, gp in ipairs(getV1GunSpecs()) do
				specs[#specs + 1] = {
					kind = "v1gun", partType = gp.partType, relCF = gp.relCF, origCF = gunInitCF * gp.relCF,
					origSize = gp.size, origColor = gp.color, origMaterial = gp.mat, origTrans = 0,
					origReflectance = gp.ref or 0, gunNeon = gp.gunNeon,
				}
			end

			-- Tambor rotativo do revólver (6 câmaras estilizadas)
			local cylRelList = {
				{ partType = "Cylinder", size = V(0.32, 0.30, 0.30), color = PALETTE.GUN_STEEL, mat = Enum.Material.Metal, ref = 0.20, relCF = angles(0, 0, 90) },
				{ partType = "Normal",   size = V(0.32, 0.28, 0.07), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = ID_CF },
				{ partType = "Normal",   size = V(0.07, 0.28, 0.32), color = PALETTE.BLACK_TRIM, mat = Enum.Material.SmoothPlastic, relCF = ID_CF },
			}
			for _, cr in ipairs(cylRelList) do
				specs[#specs + 1] = {
					kind = "v1gunCyl", partType = cr.partType, relCF = cr.relCF,
					origCF = gunInitCF * C(0, -0.55, -0.28) * cr.relCF,
					origSize = cr.size, origColor = cr.color, origMaterial = cr.mat, origTrans = 0,
					origReflectance = cr.ref or 0,
				}
			end

			-- Cão (Hammer) & Gatilho animados
			specs[#specs + 1] = {
				kind = "v1gunHammer", partType = "Normal", origSize = V(0.06, 0.08, 0.14),
				origColor = PALETTE.SILVER_TRIM, origMaterial = Enum.Material.Metal,
				relCF = C(0, 0.03, -0.05), origCF = gunInitCF * C(0, -0.26, -0.22) * angles(18, 0, 0) * C(0, 0.03, -0.05), origTrans = 0, origReflectance = 0.25,
			}
			specs[#specs + 1] = {
				kind = "v1gunTrigger", partType = "Normal", origSize = V(0.04, 0.05, 0.12),
				origColor = PALETTE.GUN_STEEL, origMaterial = Enum.Material.Metal,
				relCF = C(0, -0.02, -0.04), origCF = gunInitCF * C(0, -0.39, -0.03) * angles(-20, 0, 0) * C(0, -0.02, -0.04), origTrans = 0, origReflectance = 0.20,
			}

			-- Tela diegética de 4 barras verdes (carga de moedas no revólver!)
			for pipIdx = 1, MAX_COINS do
				local xOff = -0.0675 + (pipIdx - 1) * 0.045
				specs[#specs + 1] = {
					kind = "v1gunPip", pipIdx = pipIdx, partType = "Normal", origSize = V(0.032, 0.018, 0.09),
					origColor = PALETTE.MARKSMAN_GREEN, origMaterial = Enum.Material.Neon,
					relCF = C(xOff, 0.018, 0), origCF = gunInitCF * C(0, -0.14, -0.355) * angles(22, 0, 0) * C(xOff, 0.018, 0), origTrans = 0, origReflectance = 0, gunNeon = true,
				}
			end

			-- Muzzle Flash estrela (fica estacionado em PARK_CF fora dos disparos)
			local muzzleRel = {
				{ size = V(0.64, 0.06, 0.06), relCF = angles(0, 0, 0) },
				{ size = V(0.06, 0.06, 0.64), relCF = angles(0, 0, 0) },
				{ size = V(0.48, 0.05, 0.05), relCF = angles(0, 45, 0) },
				{ size = V(0.05, 0.05, 0.48), relCF = angles(0, 45, 0) },
				{ size = V(0.08, 0.50, 0.08), relCF = C(0, -0.20, 0) },
			}
			for _, mf in ipairs(muzzleRel) do
				specs[#specs + 1] = {
					kind = "v1gunMuzzle", partType = "Normal", origSize = mf.size,
					origColor = PALETTE.EYE_CORE, origMaterial = Enum.Material.Neon,
					relCF = mf.relCF, origCF = PARK_CF, origTrans = 0, origReflectance = 0,
				}
			end

			-- 3 moedas extras para suportar até 4 moedas simultâneas no ar
			for coinIdx = 2, MAX_COINS do
				specs[#specs + 1] = {
					kind = "v1coin", coinIdx = coinIdx, partType = "Cylinder", origSize = V(0.08, 0.48, 0.48),
					origColor = PALETTE.COIN_GOLD, origMaterial = Enum.Material.Metal,
					relCF = ID_CF, origCF = PARK_CF, origTrans = 0, origReflectance = 0.42,
				}
			end

			return specs
		end,

		onPrimary = function()
			local STATE = Core.getState()
			if not (STATE and STATE.alive) or STATE.isSettingUp then return end
			local cs = STATE.custom
			local now = os.clock()
			if (now - (cs.lastCoinToss or 0)) < COIN_TOSS_DEBOUNCE then return end
			if (cs.coinAmmo or 0) < 1 then
				Core.playSFX("PUNCH", 1.55, 0.35)
				return
			end
			local c = Core.getChar()
			local hrp = c and c:FindFirstChild("HumanoidRootPart")
			if not hrp then return end

			-- Escolhe slot livre (1 = coinPart do Core, 2..4 = v1coin)
			local usedSlots = {}
			for _, coin in ipairs(cs.coins) do
				usedSlots[coin.slot] = true
			end
			local freeSlot = nil
			for s = 1, MAX_COINS do
				if not usedSlots[s] then
					freeSlot = s
					break
				end
			end
			if not freeSlot then return end

			cs.coinAmmo = clamp(cs.coinAmmo - 1, 0, MAX_COINS)
			cs.lastCoinToss = now
			cs.anim.tossAnimStart = now
			cs.anim.tossAnimUntil = now + 0.24
			cs.anim.spinning = false

			local cam = workspace.CurrentCamera
			local headReal = c:FindFirstChild("Head")
			local inFP = cam and headReal and ((cam.CFrame.Position - headReal.Position).Magnitude < Core.getConfig().FIRST_PERSON_HIDE_DIST) or false
			local aimCF = (inFP and cam) and cam.CFrame or hrp.CFrame

			local flatLook = V(aimCF.LookVector.X, 0, aimCF.LookVector.Z)
			flatLook = (flatLook.Magnitude < 0.01) and hrp.CFrame.LookVector or flatLook.Unit

			-- Herança real de velocidade ULTRAKILL (andar p/ trás joga alto; andar p/ frente lança adiante)
			local hrpVel = hrp.AssemblyLinearVelocity
			local fwdInput = STATE.localFwd or 0
			local fwdBoost = 15 + fwdInput * 5.5
			local upBoost = 16 - fwdInput * 3.5 + clamp(hrpVel.Y * 0.25, -4, 6)
			local spawnPos = (aimCF * C(-0.56, 0.48, -1.65)).Position
			local coinVel = V(hrpVel.X * 0.74, math.max(hrpVel.Y * 0.35, 0), hrpVel.Z * 0.74) + flatLook * fwdBoost + V(0, upBoost, 0)

			cs.coins[#cs.coins + 1] = {
				slot = freeSlot,
				pos = spawnPos,
				vel = coinVel,
				born = now,
				cf = C(spawnPos),
				glinted = false,
			}

			-- Agenda disparo em cadeia após a última moeda subir (permite malabarismo rápido!)
			cs.shotScheduleAt = now + COIN_AUTO_SHOT_DELAY

			Core.playSFX("COIN_FLIP", 0.98 + freeSlot * 0.06, 1.0, "PARRY")
			if freeSlot == 1 and STATE.coinPart and STATE.coinPart.part and not cs.anim.coin1Visible then
				cs.anim.coin1Visible = true
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
			STATE.custom.anim.spinning = false
		end,

		stepCharacter = function(_, c, hrp, hum, _, ctx)
			local STATE = Core.getState()
			local CONFIG = Core.getConfig()
			local cs = STATE.custom
			local anim = cs.anim
			local now = ctx.now
			local inFP = ctx.inFP
			local cam = ctx.cam
			local isAir = ctx.isAir
			local sinW, cosW = ctx.sinW, ctx.cosW

			local prevNow = anim.lastNow or now
			local dt = clamp(now - prevNow, 1 / 240, 0.05)
			anim.lastNow = now

			-- Recarga contínua das 4 moedas do Marksman
			if cs.coinAmmo < MAX_COINS then
				local prevWhole = math.floor(cs.coinAmmo)
				cs.coinAmmo = clamp(cs.coinAmmo + dt / COIN_RECHARGE_TIME, 0, MAX_COINS)
				local newWhole = math.floor(cs.coinAmmo)
				if newWhole > prevWhole then
					Core.playSFX("COIN_FLIP", 0.92 + newWhole * 0.14, 0.35, "PARRY")
				end
			end

			-- Atualiza suavizações de estado
			local targetSlide = (STATE.slide.active and not isAir) and 1 or 0
			local targetSlam = (STATE.slam.active and isAir) and 1 or 0
			local targetGlide = (STATE.isGliding and isAir and not STATE.slam.active) and 1 or 0
			local targetDash = STATE.dash.active and 1 or 0

			anim.slide = damp(anim.slide, targetSlide, targetSlide > anim.slide and 20 or 14, dt)
			anim.slam = damp(anim.slam, targetSlam, 22, dt)
			anim.glide = damp(anim.glide, targetGlide, 11, dt)
			anim.dash = damp(anim.dash, targetDash, targetDash > anim.dash and 28 or 16, dt)
			anim.walk = damp(anim.walk, STATE.walkBlend or 0, 14, dt)
			anim.sprint = damp(anim.sprint, STATE.sprintBlend or 0, 12, dt)
			anim.air = damp(anim.air, STATE.airBlend or 0, 14, dt)
			anim.gunRecoil = damp(anim.gunRecoil, 0, 16, dt)
			anim.cylAngle = damp(anim.cylAngle, anim.cylTarget, 22, dt)
			anim.hammerKick = damp(anim.hammerKick, 0, 18, dt)
			anim.triggerPull = damp(anim.triggerPull, 0, 22, dt)
			anim.wingPulse = damp(anim.wingPulse, 0, 8, dt)

			-- Detecção de aterrissagem pesada (Slam / queda alta) para squash & recovery
			if isAir then
				anim.wasAir = true
				anim.wasSlam = anim.wasSlam or STATE.slam.active
				anim.maxFallVel = math.min(anim.maxFallVel, STATE.vertVel or 0)
			elseif anim.wasAir then
				local impact = clamp((-anim.maxFallVel) / 75, 0.25, 1.0)
				if anim.wasSlam then
					impact = 1.15
					anim.wingPulse = 1.0
				end
				anim.landCrush = math.max(anim.landCrush, impact)
				anim.wasAir = false
				anim.wasSlam = false
				anim.maxFallVel = 0
			end
			anim.landCrush = damp(anim.landCrush, 0, 11, dt)

			local t = STATE.time
			local idleWeight = clamp(1 - anim.walk, 0, 1) * (1 - anim.air) * (1 - anim.slide)

			-- Giro estiloso do revólver quando parado em idle
			local isBusy = anim.walk > 0.12 or isAir or STATE.slide.active or STATE.dash.active
				or #cs.coins > 0 or cs.parryAttack.active or now < anim.shotAnimUntil
			if isBusy then
				anim.idleTime = 0
				anim.spinning = false
				anim.spinT = 0
			else
				anim.idleTime = anim.idleTime + dt
				if not anim.spinning and anim.idleTime >= anim.nextSpinAt then
					anim.spinning = true
					anim.spinT = 0
					anim.nextSpinAt = anim.idleTime + 6.5
				end
				if anim.spinning then
					anim.spinT = anim.spinT + dt / 0.62
					if anim.spinT >= 1 then
						anim.spinning = false
						anim.spinT = 0
					end
				end
			end

			local realSoleDepth = (STATE.rigType == "R15") and (hum.HipHeight + hrp.Size.Y * 0.5) or 3.0
			local groundOffsetY = V1_SOLE_DEPTH - realSoleDepth

			-- Aim tracking suave para cabeça e braço
			local rawCamPitch, rawCamYaw = 0, 0
			if CONFIG.ENABLE_HEAD_AIM_TRACKING and cam then
				local camLocalLook = hrp.CFrame:VectorToObjectSpace(cam.CFrame.LookVector)
				rawCamPitch = clamp(math.asin(clamp(camLocalLook.Y, -0.85, 0.85)) * 180 / math.pi, -48, 56)
				rawCamYaw = clamp(math.atan2(-camLocalLook.X, -camLocalLook.Z) * 180 / math.pi, -40, 40)
			end
			anim.camPitchS = damp(anim.camPitchS, rawCamPitch, 18, dt)
			anim.camYawS = damp(anim.camYawS, rawCamYaw, 18, dt)
			local camPitch, camYawLocal = anim.camPitchS, anim.camYawS

			-- Cálculo do ciclo contínuo da passada
			local phase = math.atan2(sinW, cosW)
			local backpedalSign = (STATE.localFwd or 0) < -0.25 and -1 or 1
			local stridePhaseL = phase * backpedalSign
			local stridePhaseR = (phase + math.pi) * backpedalSign
			local strideBounce = (1 - math.abs(cosW)) * 0.12 * anim.walk * (1 + anim.sprint * 0.45)

			-- Hierarquia da coluna: Pélvis -> Abdômen -> Peito
			local crouchDrop = anim.landCrush * 0.44 + anim.slide * 1.48
			local breatheY = math.sin(t * 2.5) * 0.035 * idleWeight
			local rootMidY = groundOffsetY + breatheY + strideBounce - crouchDrop

			local pelvisPitch = anim.slide * 34 - anim.slam * 14 - anim.landCrush * 8 - (STATE.localFwd or 0) * (3 + anim.sprint * 5)
			local pelvisYaw = (10 * idleWeight) - sinW * (6 + anim.sprint * 7) * anim.walk
			local pelvisRoll = -(STATE.localStrafe or 0) * 6 - (STATE.turnRate or 0) * 1.4 - cosW * 3.5 * anim.walk

			local waistPitch = -anim.landCrush * 10 - anim.slam * 10 - (STATE.localFwd or 0) * (3 + anim.sprint * 4)
			local waistYaw = sinW * (4 + anim.sprint * 5) * anim.walk
			local waistRoll = -(STATE.localStrafe or 0) * 3

			local chestPitch = -anim.landCrush * 12 - anim.slam * 14 - anim.glide * 10 - (STATE.localFwd or 0) * (4 + anim.sprint * 6) + anim.air * clamp(-(STATE.vertVel or 0) * 0.30, -14, 14)
			local chestYaw = (4 * idleWeight) + sinW * (9 + anim.sprint * 9) * anim.walk + anim.slide * 16
			local chestRoll = -(STATE.localStrafe or 0) * 5 - (STATE.turnRate or 0) * 1.6

			if anim.dash > 0.01 then
				local ld = STATE.dash.localDir or V(0, 0, -1)
				pelvisPitch = pelvisPitch + ld.Z * 12 * anim.dash
				chestPitch = chestPitch + ld.Z * 18 * anim.dash
				chestRoll = chestRoll - ld.X * 22 * anim.dash
			end

			-- Torção dinâmica do tronco durante soco Feedbacker e disparo
			local pa = cs.parryAttack
			local parryChestTwist = 0
			local parryChestPitch = 0
			if pa.active then
				local pEl = now - pa.startTime
				if pEl < 0.05 then
					local k = easeOutQuad(pEl / 0.05)
					parryChestTwist = -18 * k
					parryChestPitch = 6 * k
				elseif pEl < 0.16 then
					local k = easeOutBack((pEl - 0.05) / 0.11)
					parryChestTwist = lerp(-18, 28, k)
					parryChestPitch = lerp(6, -12, k)
				elseif pEl < 0.36 then
					local k = easeOutQuad((pEl - 0.16) / 0.20)
					parryChestTwist = lerp(28, 0, k)
					parryChestPitch = lerp(-12, 0, k)
				end
			end
			waistYaw = waistYaw + parryChestTwist * 0.40
			chestYaw = chestYaw + parryChestTwist * 0.60
			chestPitch = chestPitch + parryChestPitch

			local rootMidCF = hrp.CFrame * C(0, rootMidY, 0)
			local pelvisCF = rootMidCF * C(0, V1_PELVIS_OFFSET, 0) * angles(pelvisPitch, pelvisYaw, pelvisRoll)
			local abdomenCF = pelvisCF * C(0, V1_ABDOMEN_FROM_PELVIS, 0) * angles(waistPitch, waistYaw, waistRoll)
			local chestCF = abdomenCF * C(0, V1_CHEST_FROM_ABDOMEN, 0) * angles(chestPitch, chestYaw, chestRoll)

			-- Cabeça com micro-scan idle e compensação firme da câmera
			local totalSpinePitch = pelvisPitch + waistPitch + chestPitch
			local totalSpineYaw = pelvisYaw + waistYaw + chestYaw
			local totalSpineRoll = pelvisRoll + waistRoll + chestRoll
			local idleScanYaw = (anim.idleTime > 1.8) and (math.sin((anim.idleTime - 1.8) * 1.1) * 14 * idleWeight) or 0
			local headPitch = camPitch * 0.88 - totalSpinePitch * 0.65 + math.sin(t * 2.5 + 0.4) * 2.0 * idleWeight
			local headYaw = camYawLocal * 0.78 - totalSpineYaw * 0.55 + idleScanYaw
			local headRoll = -totalSpineRoll * 0.45 + idleScanYaw * 0.15
			local headCF = chestCF * C(0, 1.06, -0.06) * angles(headPitch, headYaw, headRoll)

			-------------------------------------------------------------------
			-- ATUALIZAÇÃO DE MOEDAS E TIROS EM CADEIA (RICOSHOT / SPLITSHOT)
			-------------------------------------------------------------------
			-- Dispara cadeia automática se o timer vencer
			if #cs.coins > 0 and cs.shotScheduleAt > 0 and now >= cs.shotScheduleAt then
				cs.shotScheduleAt = 0
				-- Ordena da mais antiga para a mais nova para fazer o encadeamento em série
				table.sort(cs.coins, function(a, b) return a.born < b.born end)
				local queue = {}
				for _, coin in ipairs(cs.coins) do
					queue[#queue + 1] = { slot = coin.slot, pos = coin.pos, born = coin.born }
				end
				cs.chainQueue = {
					items = queue,
					index = 1,
					nextHopAt = now,
					totalCoins = #queue,
					lastOrigin = cs.lastMuzzlePos or (chestCF * C(1.05, 0.25, -1.65)).Position,
				}
				cs.coins = {}
				anim.gunRecoil = 1.0
				anim.shotAnimUntil = now + 0.28
				anim.cylTarget = anim.cylTarget + 60
				anim.hammerKick = 1.0
				anim.triggerPull = 1.0
				anim.muzzleEnd = now + 0.055
				anim.muzzleRoll = (now * 733) % 360
				anim.wingPulse = math.max(anim.wingPulse, 0.55)
			end

			-- Executa passos sequenciais da cadeia de moedas (0.05s por salto para o pool de beams do Core!)
			if cs.chainQueue then
				local cq = cs.chainQueue
				if now >= cq.nextHopAt then
					local hop = cq.items[cq.index]
					if hop then
						local isLast = (cq.index == #cq.items)
						local age = now - hop.born
						local isSplit = (age >= COIN_SPLIT_MIN and age <= COIN_SPLIT_MAX)
						if isLast then
							local aimDir = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
							local fallbackPos = (cam and (cam.CFrame.Position + cam.CFrame.LookVector * 85)) or (hrp.Position + hrp.CFrame.LookVector * 85)
							local p1, c1, p2, c2 = findCoinTargets(c, hop.pos, aimDir, fallbackPos)

							Core.playSFX("SHATTER", 1.12 + cq.totalCoins * 0.06, 0.95, "PARRY")
							fireRicochetBeams(STATE, cq.lastOrigin, hop.pos, p1, cq.totalCoins >= 2 or isSplit)

							if c1 then
								if cq.totalCoins >= 2 then
									Core.addStyleBonus("+ULTRARICOSHOT x" .. tostring(cq.totalCoins), 180 * cq.totalCoins, PALETTE.COIN_GOLD)
									Core.triggerHitstop(0.06, PALETTE.COIN_GOLD)
									Core.applyF3XKnockback(c1, p1 - hop.pos, SPLIT_KNOCKBACK_POWER)
								elseif isSplit then
									Core.addStyleBonus("+SPLITSHOT", 160, PALETTE.COIN_GOLD)
									Core.applyF3XKnockback(c1, p1 - hop.pos, SPLIT_KNOCKBACK_POWER)
								else
									Core.addStyleBonus("+RICOSHOT", 115, PALETTE.COIN_GOLD)
									Core.applyF3XKnockback(c1, p1 - hop.pos, COIN_KNOCKBACK_POWER)
								end
								if (isSplit or cq.totalCoins >= 2) and c2 and p2 then
									Core.spawnImpactFlash(p2, PALETTE.BEAM_CYAN, 1.0, 5.0, 0.25)
									Core.applyF3XKnockback(c2, p2 - hop.pos, SPLIT_KNOCKBACK_POWER)
								end
							else
								Core.addStyleBonus("+RICOSHOT", 85, PALETTE.COIN_GOLD)
							end
						else
							local nextHop = cq.items[cq.index + 1]
							Core.playSFX("SHATTER", 1.25 + cq.index * 0.12, 0.75, "PARRY")
							fireRicochetBeams(STATE, cq.lastOrigin, hop.pos, nextHop.pos, false, PALETTE.YELLOW_NEON, PALETTE.COIN_GOLD)
							cq.lastOrigin = hop.pos
						end

						if hop.slot == 1 and STATE.coinPart and STATE.coinPart.part and anim.coin1Visible then
							anim.coin1Visible = false
							Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
						end
						cq.index = cq.index + 1
						cq.nextHopAt = now + 0.055
					else
						cs.chainQueue = nil
					end
				end
			end

			-- Atualiza física das moedas vivas
			local activeBySlot = {}
			for i = #cs.coins, 1, -1 do
				local coin = cs.coins[i]
				local age = now - coin.born
				coin.vel = coin.vel + V(0, -48 * dt, 0)
				coin.pos = coin.pos + coin.vel * dt
				coin.cf = C(coin.pos) * angles(age * 1020, age * 460, age * 340)

				-- Brilho sutil na janela de Splitshot!
				if not coin.glinted and age >= COIN_SPLIT_MIN then
					coin.glinted = true
					Core.spawnFlash(coin.pos, PALETTE.EYE_CORE, 0.25, 1.35, 0.14)
				end

				if age >= COIN_LIFETIME or coin.pos.Y < hrp.Position.Y - 40 then
					if coin.slot == 1 and STATE.coinPart and STATE.coinPart.part and anim.coin1Visible then
						anim.coin1Visible = false
						Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
					end
					table.remove(cs.coins, i)
				else
					activeBySlot[coin.slot] = coin
				end
			end

			if STATE.coinPart and STATE.coinPart.part then
				local c1 = activeBySlot[1]
				STATE.coinPart.targetCF = c1 and c1.cf or PARK_CF
				STATE.coinPart.part.CFrame = STATE.coinPart.targetCF
			end
			if STATE.buckets.v1coin then
				for _, e in ipairs(STATE.buckets.v1coin) do
					local ck = activeBySlot[e.coinIdx]
					e.targetCF = ck and ck.cf or PARK_CF
					e.part.CFrame = e.targetCF
				end
			end

			-------------------------------------------------------------------
			-- BRAÇOS: VIEWMODEL 1P VS POSE DE COMBATE 3P
			-------------------------------------------------------------------
			local fpViewmodel = inFP and STATE.fpArms and cam ~= nil
			local shoulderL, shoulderR
			local lUpperPitch, lUpperYaw, lUpperRoll, lForePitch
			local rUpperPitch, rUpperYaw, rUpperRoll, rForePitch, rHandRoll
			local fingerCurl = 0.28

			if fpViewmodel then
				-- Sway suave da câmera no viewmodel 1P (sem dupla rotação de camPitch!)
				local lookVec = cam.CFrame.LookVector
				local prevLook = anim.prevCamLook or lookVec
				local rightDelta = lookVec:Dot(cam.CFrame.RightVector) - prevLook:Dot(cam.CFrame.RightVector)
				local upDelta = lookVec:Dot(cam.CFrame.UpVector) - prevLook:Dot(cam.CFrame.UpVector)
				anim.prevCamLook = lookVec

				anim.fpSwayX = damp(anim.fpSwayX, clamp(-rightDelta * 2.2, -0.14, 0.14), 14, dt)
				anim.fpSwayY = damp(anim.fpSwayY, clamp(-upDelta * 2.0, -0.14, 0.14), 14, dt)
				anim.fpTilt = damp(anim.fpTilt, (STATE.localStrafe or 0) * -6 + anim.slide * 13, 14, dt)

				local bobX = math.sin(phase) * 0.035 * anim.walk * (1 + anim.sprint * 0.4)
				local bobY = math.abs(math.cos(phase)) * -0.040 * anim.walk * (1 + anim.sprint * 0.4)
				local airLagY = clamp(-(STATE.vertVel or 0) * 0.0022, -0.08, 0.08) * anim.air
				local spinAngle = anim.spinning and (easeOutQuad(anim.spinT) * -360) or 0

				local recoilKick = anim.gunRecoil
				shoulderR = cam.CFrame * C(
					0.88 + anim.fpSwayX + bobX,
					-0.44 + anim.fpSwayY + bobY + airLagY - anim.landCrush * 0.08,
					-0.44 + recoilKick * 0.16
				)
				rUpperPitch = 70 + recoilKick * 18
				rUpperYaw = 7 + anim.fpSwayX * 26
				rUpperRoll = -4 + anim.fpTilt
				rForePitch = 20 + recoilKick * 14 + spinAngle
				rHandRoll = 0

				-- Feedbacker 1P fica escondido abaixo do quadro quando ocioso e entra no soco / moeda
				local lShow = 0
				if pa.active then
					lShow = 1
				elseif now < anim.tossAnimUntil then
					lShow = 1 - clamp((now - anim.tossAnimStart - 0.16) / 0.08, 0, 1)
				end
				shoulderL = cam.CFrame * C(
					lerp(-0.98, -0.78, lShow),
					lerp(-1.42, -0.58, lShow),
					lerp(-0.28, -0.46, lShow)
				)
				lUpperPitch = lerp(38, 66, lShow)
				lUpperYaw = lerp(8, -14, lShow)
				lUpperRoll = lerp(12, -8, lShow)
				lForePitch = lerp(42, 18, lShow)
			else
				anim.prevCamLook = nil
				local recoilKick = anim.gunRecoil
				local spinAngle = anim.spinning and (easeOutQuad(anim.spinT) * -360) or 0
				local armAimAlpha = clamp(math.max((now < anim.shotAnimUntil) and 1 or 0, recoilKick), 0, 1)

				-- Braço direito (Marksman Revolver): pronto de combate -> mira alta ao disparar
				local rReadyUpperP = 34 + math.sin(t * 2.5) * 2.0 * idleWeight - sinW * (12 * (1 - anim.sprint * 0.4)) * anim.walk - anim.landCrush * 10
				local rAimUpperP = 74
				rUpperPitch = lerp(rReadyUpperP, rAimUpperP, armAimAlpha * 0.65) + camPitch * 0.72 - totalSpinePitch * 0.55 + recoilKick * 20
				rUpperYaw = -8 + camYawLocal * 0.45 - totalSpineYaw * 0.40
				rUpperRoll = -8 - anim.slide * 8
				rForePitch = lerp(46, 16, armAimAlpha * 0.65) + camPitch * 0.16 + recoilKick * 12 + spinAngle
				rHandRoll = 0

				-- Braço esquerdo (Feedbacker): postura atlética com atraso natural de cotovelo na corrida
				local elbowLag = math.sin(phase - 0.55)
				lUpperPitch = -14 * idleWeight + sinW * (26 + anim.sprint * 20) * anim.walk - anim.landCrush * 14
				lUpperYaw = 12 * idleWeight
				lUpperRoll = 12 + anim.air * 16 + anim.glide * 24 + anim.slide * 18
				lForePitch = 28 + math.max(0, elbowLag) * (24 + anim.sprint * 14) * anim.walk + anim.air * 14 - anim.glide * 10

				if anim.slam > 0.1 then
					lUpperPitch = lerp(lUpperPitch, 48, anim.slam)
					lUpperRoll = lerp(lUpperRoll, 12, anim.slam)
					lForePitch = lerp(lForePitch, 68, anim.slam)
					rUpperPitch = lerp(rUpperPitch, 54 + camPitch * 0.35, anim.slam)
					rForePitch = lerp(rForePitch, 58, anim.slam)
				end

				shoulderL = chestCF * C(-1.06, 0.24, 0)
				shoulderR = chestCF * C(1.06, 0.24, 0)
			end

			-- Animação do toss da moeda (polegar / pulso lançando)
			if now < anim.tossAnimUntil then
				local cEl = now - anim.tossAnimStart
				if cEl < 0.12 then
					local k = easeOutQuad(cEl / 0.12)
					lUpperPitch = lerp(lUpperPitch, 78, k)
					lUpperYaw = lerp(lUpperYaw, -12, k)
					lForePitch = lerp(lForePitch, 22, k)
					fingerCurl = lerp(0.28, 0.05, k)
				else
					local k = easeOutQuad((cEl - 0.12) / 0.12)
					lUpperPitch = lerp(78, lUpperPitch, k)
					lForePitch = lerp(22, lForePitch, k)
				end
			end

			-- Animação de Soco / Parry do Feedbacker (3 fases: Coil -> Explosão -> Recuperação)
			if pa.active then
				local pEl = now - pa.startTime
				local aimBias = fpViewmodel and 0 or (camPitch * 0.72)
				if pEl < 0.05 then
					local k = easeOutQuad(pEl / 0.05)
					lUpperPitch = lerp(lUpperPitch, -24, k)
					lUpperYaw = lerp(lUpperYaw, 18, k)
					lForePitch = lerp(lForePitch, 98, k)
					fingerCurl = lerp(0.28, 1.0, k)
				elseif pEl < 0.15 then
					local k = easeOutBack((pEl - 0.05) / 0.10)
					lUpperPitch = lerp(-24, 96 + aimBias, k)
					lUpperYaw = lerp(18, -20, k)
					lUpperRoll = lerp(lUpperRoll, -12, k)
					lForePitch = lerp(98, 4, k)
					fingerCurl = 1.0
				elseif pEl < 0.36 then
					local k = easeOutQuad((pEl - 0.15) / 0.21)
					lUpperPitch = lerp(96 + aimBias, lUpperPitch, k)
					lUpperYaw = lerp(-20, lUpperYaw, k)
					lUpperRoll = lerp(-12, lUpperRoll, k)
					lForePitch = lerp(4, lForePitch, k)
					fingerCurl = lerp(1.0, 0.28, k)
				else
					pa.active = false
				end

				if not pa.hitTriggered and pEl >= 0.055 then
					pa.hitTriggered = true
					-- 1) Tenta acertar a moeda mais próxima primeiro (+FISTFUL OF DOLLAR)
					local punchedCoin, punchedIdx, bestCoinDist = nil, nil, COIN_PUNCH_RANGE
					for idx, coin in ipairs(cs.coins) do
						local d = (coin.pos - hrp.Position).Magnitude
						if d < bestCoinDist then
							bestCoinDist, punchedCoin, punchedIdx = d, coin, idx
						end
					end

					if punchedCoin then
						table.remove(cs.coins, punchedIdx)
						if #cs.coins == 0 then cs.shotScheduleAt = 0 end
						local aimDir = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
						local fallbackPos = (cam and (cam.CFrame.Position + cam.CFrame.LookVector * 90)) or (hrp.Position + hrp.CFrame.LookVector * 90)
						local p1, c1 = findCoinTargets(c, punchedCoin.pos, aimDir, fallbackPos)

						Core.playSFX("PARRY", 1.15, 1.0)
						Core.triggerHitstop(0.11, PALETTE.PARRY_FLASH)
						Core.spawnFlash(punchedCoin.pos, PALETTE.PARRY_FLASH, 1.0, 4.8, 0.22)
						Core.spawnRing(punchedCoin.pos, PALETTE.COIN_GOLD, 0.8, 5.6, 0.24)
						fireRicochetBeams(STATE, hrp.Position, punchedCoin.pos, p1, true, PALETTE.PARRY_FLASH, PALETTE.COIN_GOLD)
						Core.addStyleBonus("+FISTFUL OF DOLLAR", 250, PALETTE.COIN_GOLD)
						anim.wingPulse = 1.0

						if c1 then
							Core.applyF3XKnockback(c1, p1 - hrp.Position, COIN_PUNCH_KNOCKBACK_POWER)
						end
						if punchedCoin.slot == 1 and STATE.coinPart and STATE.coinPart.part and anim.coin1Visible then
							anim.coin1Visible = false
							Core.syncPartMaterial({ { Part = STATE.coinPart.part, Transparency = 1 } })
						end
					else
						-- 2) Tenta dar Parry em alvo corpo-a-corpo (+PARRY)
						local meleeChar, meleeHRP = findNearestMeleeTarget(c, hrp)
						if meleeChar and meleeHRP then
							Core.playSFX("PARRY", 1.0, 1.0)
							Core.triggerHitstop(0.10, PALETTE.PARRY_FLASH)
							Core.spawnFlash(meleeHRP.Position, PALETTE.PARRY_FLASH, 1.2, 5.6, 0.24)
							Core.spawnRing(meleeHRP.Position, PALETTE.PARRY_FLASH, 0.9, 6.4, 0.26)
							Core.addStyleBonus("+PARRY", 200, PALETTE.PARRY_FLASH)
							Core.applyF3XKnockback(meleeChar, meleeHRP.Position - hrp.Position, PARRY_KNOCKBACK_POWER)
							anim.wingPulse = 1.0
						else
							Core.playSFX("PUNCH", 1.08, 0.75, "PARRY")
						end
					end
				end
			end

			local lUpperCF = shoulderL * angles(lUpperPitch, lUpperYaw, lUpperRoll)
			local lForeCF = lUpperCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(lForePitch, 0, 0)
			local lHandCF = lForeCF * C(0, -V1_FOREARM_LEN, 0)
			local lFingersCF = lHandCF * C(0, -0.28, -0.18) * angles(-18 - fingerCurl * 92, 0, 0)

			local rUpperCF = shoulderR * angles(rUpperPitch, rUpperYaw, rUpperRoll)
			local rForeCF = rUpperCF * C(0, -V1_UPPER_ARM_LEN, 0) * angles(rForePitch, 0, 0)
			local rHandCF = rForeCF * C(0, -V1_FOREARM_LEN, 0) * angles(0, 0, rHandRoll)
			local gunCF = rHandCF * GUN_MOUNT_REL
			cs.lastMuzzlePos = (gunCF * GUN_MUZZLE_LOCAL).Position

			-------------------------------------------------------------------
			-- PERNAS (STRIDE BIOMECÂNICO + SLIDE + SLAM + POUSO)
			-------------------------------------------------------------------
			-- Postura idle assimétrica (esquerdo ligeiramente à frente, joelhos atléticos)
			local lThighP = 9 * idleWeight
			local rThighP = -8 * idleWeight
			local lShinP = (-14 - anim.landCrush * 34) * idleWeight
			local rShinP = (-10 - anim.landCrush * 34) * idleWeight
			local lFootP = (5 + anim.landCrush * 20) * idleWeight
			local rFootP = (14 + anim.landCrush * 20) * idleWeight

			if anim.walk > 0.01 then
				local wLT, wLS, wLF = evalStrideLeg(stridePhaseL, anim.sprint, anim.walk)
				local wRT, wRS, wRF = evalStrideLeg(stridePhaseR, anim.sprint, anim.walk)
				lThighP = lerp(lThighP, wLT - anim.landCrush * 18, anim.walk)
				rThighP = lerp(rThighP, wRT - anim.landCrush * 18, anim.walk)
				lShinP = lerp(lShinP, wLS - anim.landCrush * 24, anim.walk)
				rShinP = lerp(rShinP, wRS - anim.landCrush * 24, anim.walk)
				lFootP = lerp(lFootP, wLF + anim.landCrush * 14, anim.walk)
				rFootP = lerp(rFootP, wRF + anim.landCrush * 14, anim.walk)
			end

			if anim.air > 0.01 then
				local airTuckL = lerp(24, 14, anim.glide)
				local airTuckR = lerp(46, 30, anim.glide)
				local shinTuckL = lerp(-38, -22, anim.glide)
				local shinTuckR = lerp(-72, -48, anim.glide)
				local footAirL = lerp(-18, -26, anim.glide)
				local footAirR = lerp(-24, -32, anim.glide)

				if anim.slam > 0.01 then
					airTuckL = lerp(airTuckL, 66, anim.slam)
					airTuckR = lerp(airTuckR, 28, anim.slam)
					shinTuckL = lerp(shinTuckL, -104, anim.slam)
					shinTuckR = lerp(shinTuckR, -38, anim.slam)
					footAirL = lerp(footAirL, -20, anim.slam)
					footAirR = lerp(footAirR, 14, anim.slam)
				elseif anim.dash > 0.01 then
					local ld = STATE.dash.localDir or V(0, 0, -1)
					if ld.Z < -0.2 then
						airTuckL = lerp(airTuckL, 42, anim.dash)
						airTuckR = lerp(airTuckR, -28, anim.dash)
						shinTuckL = lerp(shinTuckL, -72, anim.dash)
						shinTuckR = lerp(shinTuckR, -18, anim.dash)
					end
				end

				lThighP = lerp(lThighP, airTuckL, anim.air)
				rThighP = lerp(rThighP, airTuckR, anim.air)
				lShinP = lerp(lShinP, shinTuckL, anim.air)
				rShinP = lerp(rShinP, shinTuckR, anim.air)
				lFootP = lerp(lFootP, footAirL, anim.air)
				rFootP = lerp(rFootP, footAirR, anim.air)
			end

			if anim.slide > 0.01 then
				lThighP = lerp(lThighP, 68, anim.slide)
				rThighP = lerp(rThighP, -24, anim.slide)
				lShinP = lerp(lShinP, -10, anim.slide)
				rShinP = lerp(rShinP, -78, anim.slide)
				lFootP = lerp(lFootP, -26, anim.slide)
				rFootP = lerp(rFootP, 20, anim.slide)
			end

			local hipL = pelvisCF * C(-0.46, V1_HIP_Y, 0)
			local hipR = pelvisCF * C(0.46, V1_HIP_Y, 0)
			local lThighCF = hipL * angles(lThighP, 8 * idleWeight, -4 - (STATE.localStrafe or 0) * 5)
			local rThighCF = hipR * angles(rThighP, -6 * idleWeight, 4 - (STATE.localStrafe or 0) * 5)
			local lShinCF = lThighCF * C(0, -V1_THIGH_LEN, 0) * angles(lShinP, 0, 0)
			local rShinCF = rThighCF * C(0, -V1_THIGH_LEN, 0) * angles(rShinP, 0, 0)
			local lFootCF = lShinCF * C(0, -V1_SHIN_LEN, 0) * angles(lFootP, 0, 0)
			local rFootCF = rShinCF * C(0, -V1_SHIN_LEN, 0) * angles(rFootP, 0, 0)

			-------------------------------------------------------------------
			-- ASAS DO V1: LEQUE ESCALONADO, PROPULSÃO, DASH & PLANAGEM
			-------------------------------------------------------------------
			local baseFan = { 46, 16, -15, -46 }
			local wingSpread = 1.0 + anim.air * 0.14 + anim.glide * 0.34 + anim.wingPulse * 0.24 - anim.slam * 0.56 + anim.slide * 0.12
			local wingSweep = -24 - anim.sprint * 14 - anim.dash * 26 - anim.slide * 20 + anim.glide * 14 + anim.slam * 62

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
			applyBucket("v1hand", { lHand = lHandCF, lFingers = lFingersCF, rHand = rHandCF }, not STATE.fpArms)
			applyBucket("v1thigh", { lThigh = lThighCF, rThigh = rThighCF }, true)
			applyBucket("v1shin", { lShin = lShinCF, rShin = rShinCF }, true)
			applyBucket("v1foot", { lFoot = lFootCF, rFoot = rFootCF }, true)
			applyBucket("v1gun", gunCF, not STATE.fpArms)

			-- Partes mecânicas animadas do Marksman Revolver
			local cylCF = gunCF * C(0, -0.55, -0.28) * angles(0, anim.cylAngle, 0)
			applyBucket("v1gunCyl", cylCF, not STATE.fpArms)

			local hammerCF = gunCF * C(0, -0.26, -0.22) * angles(18 - anim.hammerKick * 32, 0, 0)
			applyBucket("v1gunHammer", hammerCF, not STATE.fpArms)

			local triggerCF = gunCF * C(0, -0.39, -0.03) * angles(-20 + anim.triggerPull * 28, 0, 0)
			applyBucket("v1gunTrigger", triggerCF, not STATE.fpArms)

			-- 4 Pips diegéticos de carga de moedas na traseira do revólver
			if STATE.buckets.v1gunPip then
				local screenBaseCF = gunCF * C(0, -0.14, -0.355) * angles(22, 0, 0)
				for _, e in ipairs(STATE.buckets.v1gunPip) do
					local idx = e.pipIdx or 1
					if cs.coinAmmo >= idx then
						e.targetCF = screenBaseCF * e.relCF
						e.part.LocalTransparencyModifier = (not STATE.fpArms and inFP) and 1 or 0
					else
						e.targetCF = PARK_CF
					end
					e.part.CFrame = e.targetCF
				end
			end

			-- Muzzle flash instantâneo nos disparos
			if STATE.buckets.v1gunMuzzle then
				local flashActive = now < anim.muzzleEnd
				local flashCF = flashActive and (gunCF * GUN_MUZZLE_LOCAL * angles(0, anim.muzzleRoll, 0)) or nil
				for _, e in ipairs(STATE.buckets.v1gunMuzzle) do
					e.targetCF = flashCF and (flashCF * e.relCF) or PARK_CF
					e.part.CFrame = e.targetCF
					e.part.LocalTransparencyModifier = (not STATE.fpArms and inFP) and 1 or 0
				end
			end

			-- Asas com leve deslocamento em Z e onda por índice
			if STATE.buckets.v1wing then
				local flutterSpeed = (anim.glide > 0.2 or anim.dash > 0.2) and 26 or 3.4
				local flutterAmp = (anim.glide > 0.2) and 5.2 or (2.0 + anim.sprint * 1.4)
				for _, e in ipairs(STATE.buckets.v1wing) do
					local idx = e.wingIdx or 1
					local wave = math.sin(now * flutterSpeed - idx * 0.65) * flutterAmp
					local fanAng = baseFan[idx] * wingSpread + wave
					local zStagger = (idx - 1) * 0.045
					local yOffset = 0.28 - (idx - 1) * 0.055
					local mountCF = chestCF * C(e.side * 0.46, yOffset, 0.66 + zStagger) * angles(0, e.side * wingSweep, e.side * fanAng)
					e.targetCF = mountCF * e.relCF
					e.part.CFrame = e.targetCF
					e.part.LocalTransparencyModifier = inFP and 1 or 0
				end
			end

			local hudStatus = {
				weaponTitle = "MARKSMAN REVOLVER",
				weaponColor = PALETTE.MARKSMAN_GREEN,
				chargeFrac = clamp(cs.coinAmmo / MAX_COINS, 0, 1),
				pipColor = PALETTE.COIN_GOLD,
				pipDimColor = Color3.fromRGB(165, 130, 32),
			}

			local cfs = {
				["Head"] = headCF,
				["Torso"] = abdomenCF * C(0, 0.22, 0),
				["Left Arm"] = lForeCF,
				["Right Arm"] = rForeCF,
				["Left Leg"] = lShinCF,
				["Right Leg"] = rShinCF,
			}

			return hudStatus, cfs
		end,
	})
end