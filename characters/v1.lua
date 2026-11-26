-- characters/v1.lua
-- ULTRAKILL V1 // SUPREME MACHINE (Módulo para Core Compartilhado)

return function(Core)
	local V3 = Core.V3
	local CF = Core.CF
	local ANG = Core.ANG
	local ID_CF = Core.ID_CF
	local mirrorCF = Core.mirrorCF
	local lerpNum = Core.lerpNum
	local lerpCF = Core.lerpCF

	local COLORS = {
		BLUE_ARMOR = Color3.fromRGB(42, 82, 168),
		LIGHT_BLUE_ARMOR = Color3.fromRGB(68, 114, 212),
		DEEP_BLUE_ARMOR = Color3.fromRGB(28, 52, 112),
		DARK_METAL = Color3.fromRGB(32, 35, 43),
		GUN_STEEL = Color3.fromRGB(76, 84, 98),
		SILVER_TRIM = Color3.fromRGB(178, 188, 202),
		BLACK_TRIM = Color3.fromRGB(15, 17, 21),
		YELLOW_NEON = Color3.fromRGB(255, 208, 30),
		YELLOW_CORE = Color3.fromRGB(255, 240, 140),
		MARKSMAN_GREEN = Color3.fromRGB(75, 255, 130),
		COIN_GOLD = Color3.fromRGB(255, 215, 45),
		BEAM_CYAN = Color3.fromRGB(115, 235, 255),
		BEAM_CORE = Color3.fromRGB(255, 255, 255),
		PARRY_FLASH = Color3.fromRGB(255, 245, 175),
		BLOOD_RED = Color3.fromRGB(185, 26, 32),
	}

	local V1_DEF = {
		id = "v1",
		config = {
			RENDER_NAME = "F3X_V1_Reanim",
			SCALE = 1.0,
			SOLE_DEPTH = 3.66,
			HUD_TITLE = "MARKSMAN // FEEDBACKER",
			PRIMARY_KEY_LABEL = "[E] COIN",
			SECONDARY_KEY_LABEL = "[F] PARRY",
			TERTIARY_KEY_LABEL = "[X] 1P ARMS",
			PARRY_COOLDOWN = 0.42,
			PARRY_RANGE = 11.5,
			COIN_COOLDOWN = 0.78,
			COIN_RANGE = 85,
			PARRY_KNOCKBACK_POWER = { speed = 68, up = 32, spin = 12.0 },
			COIN_KNOCKBACK_POWER = { speed = 50, up = 25, spin = 9.0 },
			COIN_PUNCH_KNOCKBACK_POWER = { speed = 96, up = 46, spin = 16.0 },
			COLORS = COLORS,
		},
	}

	-- Estado exclusivo do V1 (Moeda + Animações de braço + Mira)
	local v1State = {
		coinActive = false,
		coinPos = V3(),
		coinVel = V3(),
		coinSpin = 0,
		coinExpiresAt = 0,
		coinCooldownEnd = 0,
		parryCooldownEnd = 0,
		punchAnimEnd = 0,
		shootAnimEnd = 0,
		wingBoost = 0,
		lastWalkPhase = 0,
	}

	local BASE_FAN = { 48, 18, -14, -46 }

	-------------------------------------------------------------------
	-- CONSTRUÇÃO DE PEÇAS DO MODELO V1
	-------------------------------------------------------------------
	function V1_DEF.buildModel(ctx)
		local specs = {}
		local function add(id, size, color, mat, shape, kind, tr)
			table.insert(specs, {
				id = id,
				size = size,
				color = color,
				mat = mat or Enum.Material.SmoothPlastic,
				shape = shape,
				kind = kind or "Normal",
				transparency = tr or 0,
				canCollide = false,
			})
		end

		-- CABEÇA (Estilo câmera + sunshade + lente circular amarela + heatsink traseiro)
		add("head_housing", V3(1.06, 0.92, 1.24), COLORS.BLUE_ARMOR, Enum.Material.Metal)
		add("head_brow", V3(1.16, 0.16, 1.48), COLORS.LIGHT_BLUE_ARMOR, Enum.Material.Metal)
		add("head_cheek_l", V3(0.18, 0.68, 1.18), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)
		add("head_cheek_r", V3(0.18, 0.68, 1.18), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)
		add("head_visor", V3(0.84, 0.64, 0.10), COLORS.BLACK_TRIM, Enum.Material.SmoothPlastic)
		add("head_bezel", V3(0.12, 0.56, 0.56), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("head_lens", V3(0.14, 0.44, 0.44), COLORS.YELLOW_NEON, Enum.Material.Neon, Enum.MeshType.Cylinder)
		add("head_lens_core", V3(0.15, 0.22, 0.22), COLORS.YELLOW_CORE, Enum.Material.Neon, Enum.MeshType.Cylinder)
		add("head_rear_sink", V3(0.76, 0.62, 0.24), COLORS.DARK_METAL, Enum.Material.Metal)
		add("neck_col", V3(0.36, 0.42, 0.36), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("neck_piston_l", V3(0.12, 0.42, 0.12), COLORS.SILVER_TRIM, Enum.Material.Metal)
		add("neck_piston_r", V3(0.12, 0.42, 0.12), COLORS.SILVER_TRIM, Enum.Material.Metal)

		-- TORSO / PEITO / CINTURA HIDRÁULICA / QUADRIL
		add("chest_core", V3(1.52, 0.96, 0.92), COLORS.BLUE_ARMOR, Enum.Material.Metal)
		add("chest_pec_l", V3(0.72, 0.68, 0.34), COLORS.LIGHT_BLUE_ARMOR, Enum.Material.Metal, nil, "Wedge")
		add("chest_pec_r", V3(0.72, 0.68, 0.34), COLORS.LIGHT_BLUE_ARMOR, Enum.Material.Metal, nil, "Wedge")
		add("chest_slit", V3(0.24, 0.54, 0.10), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("chest_vent_l", V3(0.42, 0.14, 0.12), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("chest_vent_r", V3(0.42, 0.14, 0.12), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("collar_l", V3(0.38, 0.28, 0.78), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)
		add("collar_r", V3(0.38, 0.28, 0.78), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)

		add("abdomen_spine", V3(0.74, 0.76, 0.64), COLORS.DARK_METAL, Enum.Material.Metal)
		add("abdomen_tube_l", V3(0.14, 0.72, 0.14), COLORS.BLOOD_RED, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("abdomen_tube_r", V3(0.14, 0.72, 0.14), COLORS.BLOOD_RED, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("pelvis_core", V3(1.18, 0.46, 0.78), COLORS.BLUE_ARMOR, Enum.Material.Metal)
		add("pelvis_plate", V3(0.56, 0.44, 0.86), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)

		-- MOCHILA EM V (Suporte das asas)
		add("pack_spine", V3(0.84, 1.05, 0.46), COLORS.DARK_METAL, Enum.Material.Metal)
		add("pack_fin_l", V3(0.34, 0.86, 0.48), COLORS.BLUE_ARMOR, Enum.Material.Metal)
		add("pack_fin_r", V3(0.34, 0.86, 0.48), COLORS.BLUE_ARMOR, Enum.Material.Metal)
		add("pack_core", V3(0.34, 0.48, 0.18), COLORS.YELLOW_NEON, Enum.Material.Neon)

		-- 8 ASAS (4 por lado, cada asa = 6 partes + 1 ponta wedge = 7 partes)
		for side = 1, 2 do
			local sTag = (side == 1) and "L" or "R"
			for w = 1, 4 do
				local prefix = "wing_" .. sTag .. w .. "_"
				add(prefix .. "hinge", V3(0.24, 0.26, 0.24), COLORS.DARK_METAL, Enum.Material.Metal)
				add(prefix .. "cowl",  V3(0.46, 0.34, 0.18), COLORS.BLUE_ARMOR, Enum.Material.Metal)
				add(prefix .. "rail",  V3(0.95, 0.16, 0.14), COLORS.GUN_STEEL, Enum.Material.Metal)
				add(prefix .. "glow1", V3(0.88, 0.24, 0.08), COLORS.YELLOW_NEON, Enum.Material.Neon)
				add(prefix .. "glow2", V3(0.92, 0.22, 0.08), COLORS.YELLOW_NEON, Enum.Material.Neon)
				add(prefix .. "glow3", V3(0.86, 0.18, 0.08), COLORS.YELLOW_CORE, Enum.Material.Neon)
				add(prefix .. "tip",   V3(0.08, 0.22, 0.64), COLORS.YELLOW_NEON, Enum.Material.Neon, nil, "Wedge")
			end
		end

		-- BRAÇOS (Esquerdo = Feedbacker azul/prata | Direito = Arma Marksman)
		for _, side in ipairs({ "L", "R" }) do
			add("sh_guard_" .. side, V3(0.56, 0.48, 0.64), COLORS.LIGHT_BLUE_ARMOR, Enum.Material.Metal)
			add("uarm_plate_" .. side, V3(0.46, 0.86, 0.46), COLORS.BLUE_ARMOR, Enum.Material.Metal)
			add("elbow_" .. side, V3(0.38, 0.32, 0.38), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Sphere)
			add("farm_plate_" .. side, V3(0.42, 0.84, 0.42), (side == "L") and COLORS.LIGHT_BLUE_ARMOR or COLORS.BLUE_ARMOR, Enum.Material.Metal)
			add("hand_" .. side, V3(0.34, 0.32, 0.36), (side == "L") and COLORS.SILVER_TRIM or COLORS.DARK_METAL, Enum.Material.Metal)
		end
		-- Detalhe Feedbacker no antebraço esquerdo
		add("feedbacker_knuckle", V3(0.38, 0.18, 0.40), COLORS.SILVER_TRIM, Enum.Material.Metal)
		add("feedbacker_trim", V3(0.14, 0.66, 0.46), COLORS.YELLOW_NEON, Enum.Material.Neon)

		-- REVÓLVER MARKSMAN (Mão Direita)
		add("gun_grip",   V3(0.18, 0.44, 0.24), COLORS.DARK_METAL, Enum.Material.Metal)
		add("gun_frame",  V3(0.22, 0.30, 0.72), COLORS.GUN_STEEL, Enum.Material.Metal)
		add("gun_barrel", V3(0.18, 0.20, 0.88), COLORS.BLACK_TRIM, Enum.Material.Metal)
		add("gun_drum",   V3(0.26, 0.26, 0.30), COLORS.SILVER_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("gun_screen", V3(0.16, 0.14, 0.28), COLORS.MARKSMAN_GREEN, Enum.Material.Neon)

		-- PERNAS (Coxa + Joelheira + Canela afilada + Pé + Esporão de calcanhar)
		for _, side in ipairs({ "L", "R" }) do
			add("thigh_" .. side, V3(0.56, 1.06, 0.58), COLORS.BLUE_ARMOR, Enum.Material.Metal)
			add("thigh_trim_" .. side, V3(0.60, 0.34, 0.30), COLORS.DARK_METAL, Enum.Material.Metal)
			add("knee_" .. side, V3(0.46, 0.44, 0.48), COLORS.SILVER_TRIM, Enum.Material.Metal)
			add("shin_" .. side, V3(0.44, 1.08, 0.48), COLORS.DEEP_BLUE_ARMOR, Enum.Material.Metal)
			add("foot_" .. side, V3(0.48, 0.28, 0.86), COLORS.DARK_METAL, Enum.Material.Metal)
			add("sole_" .. side, V3(0.50, 0.10, 0.88), COLORS.BLACK_TRIM, Enum.Material.SmoothPlastic)
			add("heel_spur_" .. side, V3(0.26, 0.24, 0.34), COLORS.SILVER_TRIM, Enum.Material.Metal)
		end

		return specs
	end

	-------------------------------------------------------------------
	-- HABILIDADES DO V1: MOEDA MARKSMAN [E] + FEEDBACKER PARRY [F]
	-------------------------------------------------------------------
	local function fireMarksmanRicochet(ctx, coinOrigin)
		local targets = ctx.Core.getTargetsInRadius(coinOrigin, V1_DEF.config.COIN_RANGE)
		local hitTarget = targets[1]

		local muzzleWorld = ctx.parts.gun_barrel and (ctx.parts.gun_barrel.CFrame * CF(0, 0, -0.45)).Position
			or (ctx.root.Position + V3(0.9, 1.3, 0))

		ctx.Core.spawnFXBeam(muzzleWorld, coinOrigin, COLORS.COIN_GOLD, COLORS.BEAM_CORE, 0.28, 0.18, 1)
		ctx.Core.spawnFXExplosion(coinOrigin, COLORS.COIN_GOLD, 3.6, 0.18)

		if hitTarget then
			ctx.Core.spawnFXBeam(coinOrigin, hitTarget.hrp.Position, COLORS.BEAM_CYAN, COLORS.BEAM_CORE, 0.38, 0.24, 2)
			ctx.Core.spawnFXExplosion(hitTarget.hrp.Position, COLORS.BEAM_CYAN, 5.5, 0.22)
			ctx.Core.addStyleBonus("RICOSHOT", 200, COLORS.BEAM_CYAN)
			ctx.Core.playSFX("SHATTER", 1.2, 0.85)
			ctx.Core.triggerHitstop(0.075, 0.22, 0.3)
			local dir = (hitTarget.hrp.Position - coinOrigin)
			ctx.Core.applyF3XKnockback(hitTarget.char, dir, V1_DEF.config.COIN_KNOCKBACK_POWER, hitTarget.hrp.Position, COLORS.BEAM_CYAN)
		else
			local cam = workspace.CurrentCamera
			local look = cam and cam.CFrame.LookVector or ctx.root.CFrame.LookVector
			ctx.Core.spawnFXBeam(coinOrigin, coinOrigin + look * 45, COLORS.BEAM_CYAN, COLORS.BEAM_CORE, 0.24, 0.18, 2)
		end
	end

	function V1_DEF.onPrimaryAction(ctx)
		local now = os.clock()
		if now < v1State.coinCooldownEnd or not ctx.root then return end

		if v1State.coinActive and now < v1State.coinExpiresAt then
			-- Segundo aperto de E (ou tiro automático): atira na moeda ativa!
			v1State.coinActive = false
			ctx.Core.clearFXPart("fx_coin")
			v1State.shootAnimEnd = now + 0.22
			ctx.Core.playSFX("SHOT", 1.35, 0.85)
			fireMarksmanRicochet(ctx, v1State.coinPos)
			return
		end

		v1State.coinCooldownEnd = now + V1_DEF.config.COIN_COOLDOWN
		v1State.coinActive = true
		v1State.coinExpiresAt = now + 1.55

		local cam = workspace.CurrentCamera
		local aimDir = cam and cam.CFrame.LookVector or ctx.root.CFrame.LookVector
		local flatVel = V3(ctx.root.AssemblyLinearVelocity.X, 0, ctx.root.AssemblyLinearVelocity.Z)
		v1State.coinPos = ctx.root.Position + V3(0, 2.0, 0) + aimDir * 2.2
		v1State.coinVel = aimDir * 28 + flatVel * 0.65 + V3(0, 28, 0)
		ctx.Core.playSFX("COIN_FLIP", 1.5, 0.8)
		ctx.Core.addStyleBonus("COIN TOSS", 25, COLORS.COIN_GOLD)

		-- Disparo automático rápido se o jogador não socar antes
		task.delay(0.38, function()
			if v1State.coinActive and ctx.state and ctx.state.running then
				v1State.coinActive = false
				ctx.Core.clearFXPart("fx_coin")
				v1State.shootAnimEnd = os.clock() + 0.22
				ctx.Core.playSFX("SHOT", 1.35, 0.85)
				fireMarksmanRicochet(ctx, v1State.coinPos)
			end
		end)
	end

	function V1_DEF.onSecondaryAction(ctx)
		local now = os.clock()
		if now < v1State.parryCooldownEnd or not ctx.root then return end
		v1State.parryCooldownEnd = now + V1_DEF.config.PARRY_COOLDOWN
		v1State.punchAnimEnd = now + 0.26

		local cam = workspace.CurrentCamera
		local aimDir = cam and cam.CFrame.LookVector or ctx.root.CFrame.LookVector
		local punchOrigin = ctx.root.Position + aimDir * 2.5

		-- Coin Punch ("FISTFUL OF DOLLAR") se a moeda estiver no ar perto
		if v1State.coinActive and (v1State.coinPos - punchOrigin).Magnitude <= 14 then
			v1State.coinActive = false
			ctx.Core.clearFXPart("fx_coin")
			local targets = ctx.Core.getTargetsInRadius(v1State.coinPos, V1_DEF.config.COIN_RANGE)
			ctx.Core.playSFX("PARRY", 1.1, 0.95)
			ctx.Core.triggerHitstop(0.11, 0.3, 0.38)
			ctx.Core.spawnFXExplosion(v1State.coinPos, COLORS.COIN_GOLD, 6.5, 0.24)
			ctx.Core.addStyleBonus("FISTFUL OF DOLLAR", 320, COLORS.COIN_GOLD)

			if targets[1] then
				local t = targets[1]
				ctx.Core.spawnFXBeam(v1State.coinPos, t.hrp.Position, COLORS.COIN_GOLD, COLORS.BEAM_CORE, 0.48, 0.26, 1)
				ctx.Core.applyF3XKnockback(t.char, t.hrp.Position - v1State.coinPos, V1_DEF.config.COIN_PUNCH_KNOCKBACK_POWER, t.hrp.Position, COLORS.COIN_GOLD)
			end
			return
		end

		-- Feedbacker Parry / Soco normal
		ctx.Core.playSFX("PUNCH")
		local hits = ctx.Core.getTargetsInRadius(punchOrigin, V1_DEF.config.PARRY_RANGE)
		if #hits > 0 then
			ctx.Core.playSFX("PARRY")
			ctx.Core.triggerHitstop(0.095, 0.26, 0.34)
			ctx.Core.spawnFXExplosion(hits[1].hrp.Position, COLORS.PARRY_FLASH, 5.2, 0.20)
			ctx.Core.addStyleBonus("PARRY", 250, COLORS.PARRY_FLASH)
			for _, t in ipairs(hits) do
				ctx.Core.applyF3XKnockback(t.char, aimDir, V1_DEF.config.PARRY_KNOCKBACK_POWER, t.hrp.Position, COLORS.PARRY_FLASH)
			end
		end
	end

	function V1_DEF.onDash()
		v1State.wingBoost = 1.0
	end

	-------------------------------------------------------------------
	-- POSE PROCEDURAL DO RIG V1
	-------------------------------------------------------------------
	function V1_DEF.poseRig(ctx, dt, motion)
		local now = motion.now
		local root = ctx.root
		local hum = ctx.hum
		if not root or not hum then return nil end

		-- Física da moeda ativa
		if v1State.coinActive then
			if now >= v1State.coinExpiresAt then
				v1State.coinActive = false
				ctx.Core.clearFXPart("fx_coin")
			else
				v1State.coinVel = v1State.coinVel - V3(0, 54 * dt, 0)
				v1State.coinPos = v1State.coinPos + v1State.coinVel * dt
				v1State.coinSpin += dt * 16
				ctx.Core.setFXPartState("fx_coin", CF(v1State.coinPos) * ANG(v1State.coinSpin, v1State.coinSpin * 0.5, math.rad(90)))
			end
		end

		v1State.wingBoost = math.max(0, v1State.wingBoost - dt * 3.5)

		local vel = root.AssemblyLinearVelocity
		local horiz = V3(vel.X, 0, vel.Z)
		local speed = horiz.Magnitude
		local grounded = (hum.FloorMaterial ~= Enum.Material.Air)

		local rootCF = root.CFrame
		local localVel = rootCF:VectorToObjectSpace(horiz)
		local leanZ = math.clamp(-localVel.Z / 36, -0.35, 0.35)
		local leanX = math.clamp(localVel.X / 40, -0.25, 0.25)

		local pelvisOffset = -0.80
		local baseRootCF = CF(rootCF.Position) * (rootCF - rootCF.Position)
		if motion.isSliding then
			baseRootCF = baseRootCF * CF(0, -1.35, 0.3) * ANG(math.rad(55), 0, 0)
		elseif motion.isSlamming then
			baseRootCF = baseRootCF * ANG(math.rad(-25), 0, 0)
		else
			baseRootCF = baseRootCF * ANG(leanZ * 0.35, 0, -leanX * 0.35)
		end

		-- Balanço de caminhada/corrida e Idle visível (respiração mecânica + asas vivas)
		local breath = math.sin(now * 2.6) * 0.055
		local walkFreq = motion.isSprinting and 13 or 9
		if grounded and speed > 1.5 and not motion.isSliding then
			v1State.lastWalkPhase += dt * walkFreq * math.clamp(speed / 16, 0.5, 2.0)
		end
		local wp = v1State.lastWalkPhase
		local moveAlpha = grounded and math.clamp(speed / 14, 0, 1) or 0

		local pelvisCF = baseRootCF * CF(0, pelvisOffset + breath * 0.5, 0)
		local abdomenCF = pelvisCF * CF(0, 0.58, 0) * ANG(math.rad(3) + leanZ * 0.18, 0, 0)
		local chestCF = abdomenCF * CF(0, 0.78 + breath * 0.4, 0) * ANG(math.rad(4) + leanZ * 0.2, math.sin(wp) * 0.08 * moveAlpha, 0)

		-- Head Aim Tracking
		local cam = workspace.CurrentCamera
		local headRot = ID_CF
		if cam then
			local relLook = chestCF:VectorToObjectSpace(cam.CFrame.LookVector)
			local yaw = math.clamp(math.atan2(-relLook.X, -relLook.Z), -0.65, 0.65)
			local pitch = math.clamp(math.asin(math.clamp(relLook.Y, -0.8, 0.8)), -0.45, 0.45)
			headRot = ANG(pitch, yaw, 0)
		end
		local headCF = chestCF * CF(0, 0.92, -0.04) * headRot

		local T = {}
		local hideSelfArms = motion.isFirstPerson and motion.fpHideArms
		local hideHead = motion.isFirstPerson

		local function setP(id, cf)
			T[id] = cf
		end

		-- Cabeça (oculta apenas se estiver em 1ª pessoa)
		local hBase = hideHead and CF(0, 25000, 0) or headCF
		setP("head_housing", hBase)
		setP("head_brow", hBase * CF(0, 0.44, -0.14))
		setP("head_cheek_l", hBase * CF(-0.56, -0.06, -0.04))
		setP("head_cheek_r", hBase * CF(0.56, -0.06, -0.04))
		setP("head_visor", hBase * CF(0, -0.02, -0.62))
		setP("head_bezel", hBase * CF(0, 0.02, -0.65) * ANG(0, math.rad(90), 0))
		setP("head_lens", hBase * CF(0, 0.02, -0.68) * ANG(0, math.rad(90), 0))
		setP("head_lens_core", hBase * CF(0, 0.02, -0.70) * ANG(0, math.rad(90), 0))
		setP("head_rear_sink", hBase * CF(0, 0.02, 0.64))
		setP("neck_col", (hideHead and CF(0, 25000, 0) or chestCF * CF(0, 0.56, 0)))
		setP("neck_piston_l", (hideHead and CF(0, 25000, 0) or chestCF * CF(-0.22, 0.56, 0.08) * ANG(0, 0, math.rad(-10))))
		setP("neck_piston_r", (hideHead and CF(0, 25000, 0) or chestCF * CF(0.22, 0.56, 0.08) * ANG(0, 0, math.rad(10))))

		-- Torso
		setP("chest_core", chestCF)
		setP("chest_pec_l", chestCF * CF(-0.38, 0.08, -0.44) * ANG(math.rad(165), math.rad(10), 0))
		setP("chest_pec_r", chestCF * CF(0.38, 0.08, -0.44) * ANG(math.rad(165), math.rad(-10), 0))
		setP("chest_slit", chestCF * CF(0, 0.05, -0.58))
		setP("chest_vent_l", chestCF * CF(-0.36, -0.22, -0.50) * ANG(0, 0, math.rad(-8)))
		setP("chest_vent_r", chestCF * CF(0.36, -0.22, -0.50) * ANG(0, 0, math.rad(8)))
		setP("collar_l", chestCF * CF(-0.56, 0.44, 0) * ANG(0, 0, math.rad(-14)))
		setP("collar_r", chestCF * CF(0.56, 0.44, 0) * ANG(0, 0, math.rad(14)))

		setP("abdomen_spine", abdomenCF)
		setP("abdomen_tube_l", abdomenCF * CF(-0.42, 0, -0.05))
		setP("abdomen_tube_r", abdomenCF * CF(0.42, 0, -0.05))
		setP("pelvis_core", pelvisCF)
		setP("pelvis_plate", pelvisCF * CF(0, -0.04, -0.06))

		-- Mochila + 8 Asas (espelho matricial perfeito)
		local packCF = chestCF * CF(0, 0.05, 0.56)
		setP("pack_spine", packCF)
		setP("pack_fin_l", packCF * CF(-0.42, 0.14, 0.10) * ANG(0, math.rad(18), math.rad(14)))
		setP("pack_fin_r", packCF * CF(0.42, 0.14, 0.10) * ANG(0, math.rad(-18), math.rad(-14)))
		setP("pack_core", packCF * CF(0, 0.10, 0.22))

		local wingFlare = (motion.isDashing and -18 or 0) + (motion.isSprinting and 10 or 0) + v1State.wingBoost * 16
		local sweepBack = motion.isDashing and 38 or (motion.isSprinting and 26 or 18)

		for side = 1, 2 do
			local isLeft = (side == 1)
			local sTag = isLeft and "L" or "R"
			for w = 1, 4 do
				local prefix = "wing_" .. sTag .. w .. "_"
				local bob = math.sin(now * 3.1 + w * 0.7 + side) * 2.5
				local fanAngle = BASE_FAN[w] + (w <= 2 and wingFlare or -wingFlare * 0.4) + bob
				local relRoot = CF(0.46, 0.24 - (w - 1) * 0.14, 0.14)
					* ANG(0, math.rad(sweepBack), math.rad(fanAngle))
				if isLeft then
					relRoot = mirrorCF(relRoot)
				end
				local wBase = packCF * relRoot

				local function wPart(rel)
					return wBase * (isLeft and mirrorCF(rel) or rel)
				end

				setP(prefix .. "hinge", wPart(CF(0.10, 0, 0)))
				setP(prefix .. "cowl",  wPart(CF(0.42, 0, 0.02)))
				setP(prefix .. "rail",  wPart(CF(0.86, 0.02, 0.05)))
				setP(prefix .. "glow1", wPart(CF(0.82, 0, 0)))
				setP(prefix .. "glow2", wPart(CF(1.66, 0, 0)))
				setP(prefix .. "glow3", wPart(CF(2.44, 0, 0)))
				setP(prefix .. "tip",   wPart(CF(3.16, 0, 0) * ANG(0, math.rad(-90), math.rad(90))))
			end
		end

		-- Braços (Feedbacker Esquerdo + Marksman Direito)
		local punchProg = (now < v1State.punchAnimEnd) and (1 - (v1State.punchAnimEnd - now) / 0.26) or 0
		local shootRecoil = (now < v1State.shootAnimEnd) and ((v1State.shootAnimEnd - now) / 0.22) or 0

		local armSwingL = math.sin(wp) * 0.55 * moveAlpha
		local armSwingR = -math.sin(wp) * 0.35 * moveAlpha

		local lShoulder = chestCF * CF(-1.02, 0.30, 0)
		if punchProg > 0 then
			local thrust = math.sin(punchProg * math.pi)
			lShoulder = lShoulder * ANG(math.rad(88 * thrust), math.rad(-18 * thrust), math.rad(12))
		else
			lShoulder = lShoulder * ANG(armSwingL, 0, math.rad(10 + breath * 15))
		end

		local rShoulder = chestCF * CF(1.02, 0.30, 0)
		if cam then
			local aimLocal = chestCF:VectorToObjectSpace(cam.CFrame.LookVector)
			local pitch = math.clamp(math.asin(math.clamp(aimLocal.Y, -0.85, 0.85)), -0.8, 0.8)
			rShoulder = rShoulder * ANG(math.rad(76) + pitch + shootRecoil * 0.38, math.rad(-6), math.rad(-6))
		else
			rShoulder = rShoulder * ANG(math.rad(68) + armSwingR, 0, math.rad(-8))
		end

		local function placeArm(side, shCF, elbowBend)
			if hideSelfArms then shCF = CF(0, 25000, 0) end
			local uArm = shCF * CF(0, -0.46, 0)
			local elb = shCF * CF(0, -0.94, 0)
			local fArm = elb * ANG(elbowBend, 0, 0) * CF(0, -0.44, 0)
			local hand = fArm * CF(0, -0.52, 0)
			setP("sh_guard_" .. side, shCF * CF((side == "L") and -0.08 or 0.08, 0.08, 0))
			setP("uarm_plate_" .. side, uArm)
			setP("elbow_" .. side, elb)
			setP("farm_plate_" .. side, fArm)
			setP("hand_" .. side, hand)
			return fArm, hand
		end

		local lFArm, lHand = placeArm("L", lShoulder, (punchProg > 0) and math.rad(14) or math.rad(28))
		setP("feedbacker_knuckle", lHand * CF(0, -0.06, -0.04))
		setP("feedbacker_trim", lFArm * CF(-0.20, 0, 0))

		local _, rHand = placeArm("R", rShoulder, math.rad(18))
		local gunRoot = rHand * CF(0, -0.24, -0.18) * ANG(math.rad(-90), 0, 0)
		if hideSelfArms then gunRoot = CF(0, 25000, 0) end
		setP("gun_grip",   gunRoot * CF(0, -0.14, 0.14) * ANG(math.rad(18), 0, 0))
		setP("gun_frame",  gunRoot * CF(0, 0.10, -0.10))
		setP("gun_barrel", gunRoot * CF(0, 0.14, -0.78))
		setP("gun_drum",   gunRoot * CF(0, 0.12, -0.06) * ANG(0, math.rad(90), 0))
		setP("gun_screen", gunRoot * CF(0, 0.27, 0.08))

		-- Pernas (Joelhos dobrando corretamente para trás com -rx)
		local legSwingL = math.sin(wp) * 0.72 * moveAlpha
		local legSwingR = -math.sin(wp) * 0.72 * moveAlpha
		local airRise = not grounded and math.clamp(vel.Y / 32, -1, 1) or 0

		local function placeLeg(side, xOff, hipPitch)
			local hip = pelvisCF * CF(xOff, -0.14, 0)
			local kneeAngle = grounded and (-math.max(0, math.sin(wp + ((side == "L") and 0.4 or 3.54)) * 0.85 * moveAlpha)) or math.rad(-28 - airRise * 18)
			if motion.isSliding then
				hipPitch = math.rad(42)
				kneeAngle = math.rad(-25)
			end
			local thighCF = hip * ANG(hipPitch, 0, 0) * CF(0, -0.58, 0)
			local kneeCF = hip * ANG(hipPitch, 0, 0) * CF(0, -1.16, 0)
			local shinCF = kneeCF * ANG(kneeAngle, 0, 0) * CF(0, -0.58, 0)
			local footCF = shinCF * CF(0, -0.62, -0.18) * ANG(-hipPitch - kneeAngle, 0, 0)

			setP("thigh_" .. side, thighCF)
			setP("thigh_trim_" .. side, thighCF * CF(0, 0.08, -0.22))
			setP("knee_" .. side, kneeCF * CF(0, 0, -0.12))
			setP("shin_" .. side, shinCF)
			setP("foot_" .. side, footCF)
			setP("sole_" .. side, footCF * CF(0, -0.16, 0))
			setP("heel_spur_" .. side, footCF * CF(0, 0.06, 0.50))
		end

		placeLeg("L", -0.36, legSwingL + (not grounded and math.rad(24) or 0))
		placeLeg("R",  0.36, legSwingR + (not grounded and math.rad(14) or 0))

		return T, {
			title = v1State.coinActive and "MARKSMAN // COIN AIRBORNE" or "MARKSMAN // FEEDBACKER",
			hint = "[E] COIN | [F] PARRY | [Q] DASH | [C] SLIDE/SLAM",
		}
	end

	Core.start(V1_DEF)
end