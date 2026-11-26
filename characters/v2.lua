-- characters/v2.lua
-- ULTRAKILL V2 // RECONSTRUCTED (1-4 LIMBO) - Módulo para Core Compartilhado

return function(Core)
	local Players = game:GetService("Players")
	local plr = Players.LocalPlayer

	local V3 = Core.V3
	local CF = Core.CF
	local ANG = Core.ANG
	local ID_CF = Core.ID_CF
	local mirrorCF = Core.mirrorCF

	local S = 1.16 -- Escala 1.16x maior que o V1

	local COLORS = {
		CRIMSON_ARMOR = Color3.fromRGB(168, 28, 34),
		LIGHT_CRIMSON = Color3.fromRGB(202, 46, 52),
		DEEP_CRIMSON = Color3.fromRGB(108, 16, 22),
		DARK_METAL = Color3.fromRGB(28, 30, 36),
		GUN_STEEL = Color3.fromRGB(72, 76, 86),
		SHOTGUN_BROWN = Color3.fromRGB(92, 68, 56),
		SILVER_TRIM = Color3.fromRGB(175, 182, 195),
		BLACK_TRIM = Color3.fromRGB(14, 15, 18),
		YELLOW_NEON = Color3.fromRGB(255, 196, 32),
		YELLOW_CORE = Color3.fromRGB(255, 240, 145),
		PIERCER_BLUE = Color3.fromRGB(70, 210, 255),
		CORE_ORANGE = Color3.fromRGB(255, 130, 40),
		ENRAGED_RED = Color3.fromRGB(255, 45, 55),
		RETREAT_GREEN = Color3.fromRGB(65, 255, 130),
		BEAM_CYAN = Color3.fromRGB(95, 220, 255),
		BEAM_CORE = Color3.fromRGB(255, 255, 255),
		PARRY_FLASH = Color3.fromRGB(255, 165, 70),
		BLOOD_RED = Color3.fromRGB(190, 24, 30),
	}

	local V2_DEF = {
		id = "v2",
		config = {
			RENDER_NAME = "F3X_V2_Reanim",
			SCALE = S,
			SOLE_DEPTH = 3.66 * S,
			WALK_SPEED = 17,
			SPRINT_SPEED = 34,
			HUD_TITLE = "PIERCER // KNUCKLEBLASTER",
			PRIMARY_KEY_LABEL = "[E] FIRE WEAPON",
			SECONDARY_KEY_LABEL = "[F] KNUCKLEBLASTER",
			TERTIARY_KEY_LABEL = "[R] SWAP GUN",

			KNUCKLE_COOLDOWN = 0.65,
			KNUCKLE_RANGE = 14.5,
			PIERCER_COOLDOWN = 0.55,
			SHOTGUN_COOLDOWN = 0.72,

			KNUCKLE_KNOCKBACK = { speed = 88, up = 40, spin = 15.0 },
			PIERCER_KNOCKBACK = { speed = 64, up = 26, spin = 10.0 },
			SHOTGUN_KNOCKBACK = { speed = 76, up = 34, spin = 13.0 },

			COLORS = COLORS,
		},
	}

	local v2State = {
		weaponMode = "PIERCER", -- "PIERCER" | "SHOTGUN"
		primaryCooldownEnd = 0,
		knuckleCooldownEnd = 0,
		punchAnimEnd = 0,
		shootAnimEnd = 0,
		enragedUntil = 0,
		wingBoost = 0,
		lastWalkPhase = 0,
		currentWingState = "GOLD",
		lastWingColorSync = 0,
	}

	local BASE_FAN = { 50, 19, -13, -45 }

	-- Sync leve de cor nas asas apenas quando o estado de movimento do V2 muda
	local function getF3XEndpointLocal()
		for _, cont in ipairs({ plr.Backpack, plr.Character, workspace }) do
			if cont then
				for _, n in ipairs({ "Building Tools+", "Building Tools" }) do
					local t = cont:FindFirstChild(n)
					local ep = t and t:FindFirstChild("SyncAPI") and t.SyncAPI:FindFirstChild("ServerEndpoint")
					if ep and ep:IsA("RemoteFunction") then return ep end
				end
			end
		end
		return nil
	end

	local function updateDynamicWingColors(ctx, targetState)
		local now = os.clock()
		if targetState == v2State.currentWingState or (now - v2State.lastWingColorSync) < 0.18 then
			return
		end
		v2State.currentWingState = targetState
		v2State.lastWingColorSync = now

		local col = COLORS.YELLOW_NEON
		if targetState == "BLUE" then
			col = COLORS.PIERCER_BLUE
		elseif targetState == "RED" then
			col = COLORS.ENRAGED_RED
		elseif targetState == "GREEN" then
			col = COLORS.RETREAT_GREEN
		end

		local batch = {}
		for side = 1, 2 do
			local sTag = (side == 1) and "L" or "R"
			for w = 1, 4 do
				local prefix = "wing_" .. sTag .. w .. "_"
				for _, seg in ipairs({ "glow1", "glow2", "glow3", "tip" }) do
					local p = ctx.parts[prefix .. seg]
					if p and p.Parent then
						table.insert(batch, { Part = p, Color = col, UnionColoring = true })
					end
				end
			end
		end
		if #batch == 0 then return end

		task.spawn(function()
			local ep = getF3XEndpointLocal()
			if ep then
				pcall(function() ep:InvokeServer("SyncColor", batch) end)
			end
		end)
	end

	-------------------------------------------------------------------
	-- CONSTRUÇÃO DE PEÇAS DO MODELO V2 (ESCALADO 1.16x + KNUCKLEBLASTER)
	-------------------------------------------------------------------
	function V2_DEF.buildModel()
		local specs = {}
		local function add(id, size, color, mat, shape, kind, tr)
			table.insert(specs, {
				id = id,
				size = size * S,
				color = color,
				mat = mat or Enum.Material.SmoothPlastic,
				shape = shape,
				kind = kind or "Normal",
				transparency = tr or 0,
				canCollide = false,
			})
		end

		-- CABEÇA (Estilo câmera mais robusta, sunshade espesso + lente âmbar)
		add("head_housing", V3(1.12, 0.96, 1.30), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("head_brow", V3(1.24, 0.18, 1.54), COLORS.LIGHT_CRIMSON, Enum.Material.Metal)
		add("head_cheek_l", V3(0.22, 0.72, 1.24), COLORS.DEEP_CRIMSON, Enum.Material.Metal)
		add("head_cheek_r", V3(0.22, 0.72, 1.24), COLORS.DEEP_CRIMSON, Enum.Material.Metal)
		add("head_visor", V3(0.86, 0.66, 0.10), COLORS.BLACK_TRIM, Enum.Material.SmoothPlastic)
		add("head_bezel", V3(0.12, 0.58, 0.58), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("head_lens", V3(0.14, 0.45, 0.45), COLORS.YELLOW_NEON, Enum.Material.Neon, Enum.MeshType.Cylinder)
		add("head_lens_core", V3(0.15, 0.22, 0.22), COLORS.YELLOW_CORE, Enum.Material.Neon, Enum.MeshType.Cylinder)
		add("head_rear_sink", V3(0.80, 0.66, 0.26), COLORS.DARK_METAL, Enum.Material.Metal)
		add("neck_col", V3(0.40, 0.44, 0.40), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Cylinder)

		-- TORSO REFORÇADO + SELO "V2" NO PEITO + CINTURA
		add("chest_core", V3(1.68, 1.02, 1.02), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("chest_pec_l", V3(0.80, 0.72, 0.38), COLORS.LIGHT_CRIMSON, Enum.Material.Metal, nil, "Wedge")
		add("chest_pec_r", V3(0.80, 0.72, 0.38), COLORS.LIGHT_CRIMSON, Enum.Material.Metal, nil, "Wedge")
		add("chest_slit", V3(0.26, 0.56, 0.12), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("chest_vent_l", V3(0.46, 0.15, 0.14), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("chest_vent_r", V3(0.46, 0.15, 0.14), COLORS.YELLOW_NEON, Enum.Material.Neon)
		add("chest_v2_badge", V3(0.32, 0.18, 0.08), COLORS.YELLOW_CORE, Enum.Material.Neon)
		add("collar_l", V3(0.44, 0.32, 0.86), COLORS.DEEP_CRIMSON, Enum.Material.Metal)
		add("collar_r", V3(0.44, 0.32, 0.86), COLORS.DEEP_CRIMSON, Enum.Material.Metal)

		add("abdomen_spine", V3(0.84, 0.76, 0.72), COLORS.DARK_METAL, Enum.Material.Metal)
		add("abdomen_tube_l", V3(0.16, 0.72, 0.16), COLORS.SILVER_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("abdomen_tube_r", V3(0.16, 0.72, 0.16), COLORS.SILVER_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("pelvis_core", V3(1.28, 0.48, 0.84), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("pelvis_plate", V3(0.62, 0.46, 0.92), COLORS.DEEP_CRIMSON, Enum.Material.Metal)

		-- MOCHILA + 8 ASAS (6 segmentos + wedge tip cada)
		add("pack_spine", V3(0.92, 1.12, 0.50), COLORS.DARK_METAL, Enum.Material.Metal)
		add("pack_fin_l", V3(0.38, 0.92, 0.52), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("pack_fin_r", V3(0.38, 0.92, 0.52), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("pack_core", V3(0.36, 0.50, 0.18), COLORS.YELLOW_NEON, Enum.Material.Neon)

		for side = 1, 2 do
			local sTag = (side == 1) and "L" or "R"
			for w = 1, 4 do
				local prefix = "wing_" .. sTag .. w .. "_"
				add(prefix .. "hinge", V3(0.26, 0.28, 0.26), COLORS.DARK_METAL, Enum.Material.Metal)
				add(prefix .. "cowl",  V3(0.50, 0.38, 0.20), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
				add(prefix .. "rail",  V3(0.98, 0.18, 0.16), COLORS.GUN_STEEL, Enum.Material.Metal)
				add(prefix .. "glow1", V3(0.92, 0.26, 0.08), COLORS.YELLOW_NEON, Enum.Material.Neon)
				add(prefix .. "glow2", V3(0.96, 0.24, 0.08), COLORS.YELLOW_NEON, Enum.Material.Neon)
				add(prefix .. "glow3", V3(0.90, 0.20, 0.08), COLORS.YELLOW_CORE, Enum.Material.Neon)
				add(prefix .. "tip",   V3(0.08, 0.24, 0.68), COLORS.YELLOW_NEON, Enum.Material.Neon, nil, "Wedge")
			end
		end

		-- BRAÇO ESQUERDO: KNUCKLEBLASTER (pesado, exaustores duplos, pistão e 3 garras cinzas)
		add("sh_guard_L", V3(0.68, 0.56, 0.74), COLORS.LIGHT_CRIMSON, Enum.Material.Metal)
		add("uarm_plate_L", V3(0.54, 0.88, 0.56), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("elbow_L", V3(0.46, 0.38, 0.46), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Sphere)
		add("kb_exhaust_1", V3(0.18, 0.18, 0.52), COLORS.GUN_STEEL, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("kb_exhaust_2", V3(0.18, 0.18, 0.52), COLORS.GUN_STEEL, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("farm_plate_L", V3(0.58, 0.90, 0.62), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("kb_piston_core", V3(0.24, 0.56, 0.26), COLORS.CORE_ORANGE, Enum.Material.Neon)
		add("kb_mount_plate", V3(0.52, 0.38, 0.44), COLORS.SILVER_TRIM, Enum.Material.Metal)
		add("hand_L", V3(0.50, 0.36, 0.50), COLORS.DARK_METAL, Enum.Material.Metal)
		add("kb_barrel_1", V3(0.16, 0.24, 0.16), COLORS.BLACK_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("kb_barrel_2", V3(0.16, 0.24, 0.16), COLORS.BLACK_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("kb_claw_1", V3(0.14, 0.44, 0.18), COLORS.GUN_STEEL, Enum.Material.Metal, nil, "Wedge")
		add("kb_claw_2", V3(0.14, 0.48, 0.18), COLORS.GUN_STEEL, Enum.Material.Metal, nil, "Wedge")
		add("kb_claw_3", V3(0.14, 0.44, 0.18), COLORS.GUN_STEEL, Enum.Material.Metal, nil, "Wedge")

		-- BRAÇO DIREITO + ARMAS (Piercer Revolver + Core Eject Shotgun)
		add("sh_guard_R", V3(0.62, 0.52, 0.68), COLORS.LIGHT_CRIMSON, Enum.Material.Metal)
		add("uarm_plate_R", V3(0.48, 0.86, 0.48), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("elbow_R", V3(0.40, 0.34, 0.40), COLORS.DARK_METAL, Enum.Material.Metal, Enum.MeshType.Sphere)
		add("farm_plate_R", V3(0.45, 0.84, 0.45), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
		add("hand_R", V3(0.36, 0.32, 0.38), COLORS.DARK_METAL, Enum.Material.Metal)

		-- Piercer Revolver (Azul)
		add("piercer_grip",   V3(0.18, 0.44, 0.24), COLORS.DARK_METAL, Enum.Material.Metal)
		add("piercer_frame",  V3(0.24, 0.32, 0.76), COLORS.GUN_STEEL, Enum.Material.Metal)
		add("piercer_barrel", V3(0.18, 0.22, 0.94), COLORS.BLACK_TRIM, Enum.Material.Metal)
		add("piercer_screen", V3(0.18, 0.16, 0.34), COLORS.PIERCER_BLUE, Enum.Material.Neon)

		-- Core Eject Shotgun (Cano duplo prateado + 2 núcleos laranja)
		add("sg_body",     V3(0.34, 0.40, 1.05), COLORS.SHOTGUN_BROWN, Enum.Material.Metal)
		add("sg_barrel_l", V3(0.16, 0.16, 0.96), COLORS.SILVER_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("sg_barrel_r", V3(0.16, 0.16, 0.96), COLORS.SILVER_TRIM, Enum.Material.Metal, Enum.MeshType.Cylinder)
		add("sg_core_1",   V3(0.14, 0.14, 0.24), COLORS.PIERCER_BLUE, Enum.Material.Neon, Enum.MeshType.Cylinder)
		add("sg_core_2",   V3(0.14, 0.14, 0.24), COLORS.CORE_ORANGE, Enum.Material.Neon, Enum.MeshType.Cylinder)

		-- PERNAS (Mais robustas, mantendo a silhueta fina abaixo do joelho da foto)
		for _, side in ipairs({ "L", "R" }) do
			add("thigh_" .. side, V3(0.62, 1.08, 0.64), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
			add("thigh_trim_" .. side, V3(0.66, 0.36, 0.32), COLORS.DARK_METAL, Enum.Material.Metal)
			add("knee_" .. side, V3(0.50, 0.46, 0.52), COLORS.DEEP_CRIMSON, Enum.Material.Metal)
			add("shin_" .. side, V3(0.46, 1.10, 0.50), COLORS.CRIMSON_ARMOR, Enum.Material.Metal)
			add("foot_" .. side, V3(0.50, 0.28, 0.88), COLORS.DARK_METAL, Enum.Material.Metal)
			add("sole_" .. side, V3(0.52, 0.10, 0.90), COLORS.BLACK_TRIM, Enum.Material.SmoothPlastic)
			add("heel_spur_" .. side, V3(0.28, 0.24, 0.36), COLORS.SILVER_TRIM, Enum.Material.Metal)
		end

		return specs
	end

	-------------------------------------------------------------------
	-- HABILIDADES DO V2: PIERCER / SHOTGUN [E], KNUCKLEBLASTER [F], TROCA [R]
	-------------------------------------------------------------------
	function V2_DEF.onTertiaryAction(ctx)
		v2State.weaponMode = (v2State.weaponMode == "PIERCER") and "SHOTGUN" or "PIERCER"
		ctx.Core.playSFX("COIN_FLIP", 0.9, 0.65)
	end

	function V2_DEF.onPrimaryAction(ctx)
		local now = os.clock()
		if now < v2State.primaryCooldownEnd or not ctx.root then return end

		local cam = workspace.CurrentCamera
		local aimOrigin = cam and cam.CFrame.Position or (ctx.root.Position + V3(0, 1.8 * S, 0))
		local aimDir = cam and cam.CFrame.LookVector or ctx.root.CFrame.LookVector
		local muzzle = (v2State.weaponMode == "PIERCER" and ctx.parts.piercer_barrel and (ctx.parts.piercer_barrel.CFrame * CF(0, 0, -0.5 * S)).Position)
			or (ctx.parts.sg_barrel_l and (ctx.parts.sg_barrel_l.CFrame * CF(0, 0, -0.5 * S)).Position)
			or (ctx.root.Position + V3(1.0 * S, 1.5 * S, 0))

		v2State.shootAnimEnd = now + 0.26
		v2State.enragedUntil = now + 0.75

		if v2State.weaponMode == "PIERCER" then
			v2State.primaryCooldownEnd = now + V2_DEF.config.PIERCER_COOLDOWN
			ctx.Core.playSFX("SHOT", 0.95, 0.9)
			local ray = ctx.Core.raycastTargets(aimOrigin, aimDir, 120)
			ctx.Core.spawnFXBeam(muzzle, ray.position, COLORS.PIERCER_BLUE, COLORS.BEAM_CORE, 0.44, 0.24, 1)
			ctx.Core.spawnFXExplosion(ray.position, COLORS.PIERCER_BLUE, 5.0, 0.20)
			if ray.target then
				ctx.Core.addStyleBonus("PIERCER BEAM", 210, COLORS.PIERCER_BLUE)
				ctx.Core.triggerHitstop(0.08, 0.22, 0.30)
				ctx.Core.applyF3XKnockback(ray.target.char, aimDir, V2_DEF.config.PIERCER_KNOCKBACK, ray.position, COLORS.PIERCER_BLUE)
			end
		else
			v2State.primaryCooldownEnd = now + V2_DEF.config.SHOTGUN_COOLDOWN
			ctx.Core.playSFX("EXPLOSION", 1.25, 0.9)
			local ray = ctx.Core.raycastTargets(aimOrigin, aimDir, 45)
			ctx.Core.spawnFXBeam(muzzle, ray.position, COLORS.CORE_ORANGE, COLORS.YELLOW_CORE, 0.62, 0.16, 2)
			ctx.Core.spawnFXExplosion(ray.position, COLORS.CORE_ORANGE, 7.2, 0.25)

			local blastTargets = ctx.Core.getTargetsInRadius(ray.position, 11)
			if #blastTargets > 0 then
				ctx.Core.addStyleBonus("CORE EJECT BLAST", 260, COLORS.CORE_ORANGE)
				ctx.Core.triggerHitstop(0.095, 0.26, 0.35)
				for _, t in ipairs(blastTargets) do
					local dir = (t.hrp.Position - ctx.root.Position)
					ctx.Core.applyF3XKnockback(t.char, dir, V2_DEF.config.SHOTGUN_KNOCKBACK, t.hrp.Position, COLORS.CORE_ORANGE)
				end
			end
		end
	end

	function V2_DEF.onSecondaryAction(ctx)
		local now = os.clock()
		if now < v2State.knuckleCooldownEnd or not ctx.root then return end
		v2State.knuckleCooldownEnd = now + V2_DEF.config.KNUCKLE_COOLDOWN
		v2State.punchAnimEnd = now + 0.32
		v2State.enragedUntil = now + 1.0

		local cam = workspace.CurrentCamera
		local aimDir = cam and cam.CFrame.LookVector or ctx.root.CFrame.LookVector
		local blastOrigin = ctx.root.Position + aimDir * (3.2 * S)

		ctx.Core.playSFX("PUNCH", 0.78, 0.95)
		task.delay(0.08, function()
			if not ctx.state or not ctx.state.running then return end
			ctx.Core.playSFX("EXPLOSION", 1.05, 0.95)
			ctx.Core.spawnFXExplosion(blastOrigin, COLORS.ENRAGED_RED, 8.5, 0.28)
			local hits = ctx.Core.getTargetsInRadius(blastOrigin, V2_DEF.config.KNUCKLE_RANGE)
			if #hits > 0 then
				ctx.Core.triggerHitstop(0.11, 0.30, 0.38)
				ctx.Core.addStyleBonus("KNUCKLEBLASTER", 300, COLORS.ENRAGED_RED)
				for _, t in ipairs(hits) do
					local out = (t.hrp.Position - ctx.root.Position) + aimDir * 4
					ctx.Core.applyF3XKnockback(t.char, out, V2_DEF.config.KNUCKLE_KNOCKBACK, t.hrp.Position, COLORS.ENRAGED_RED)
				end
			end
		end)
	end

	function V2_DEF.onDash()
		v2State.wingBoost = 1.0
	end

	-------------------------------------------------------------------
	-- POSE PROCEDURAL DO RIG V2
	-------------------------------------------------------------------
	function V2_DEF.poseRig(ctx, dt, motion)
		local now = motion.now
		local root = ctx.root
		local hum = ctx.hum
		if not root or not hum then return nil end

		v2State.wingBoost = math.max(0, v2State.wingBoost - dt * 3.5)

		-- Seleção da cor dinâmica das asas do V2
		local wingState = "GOLD"
		if now < v2State.enragedUntil or motion.isSlamming then
			wingState = "RED"
		elseif motion.isDashing or motion.isSliding or hum.FloorMaterial == Enum.Material.Air then
			wingState = "GREEN"
		elseif motion.isSprinting then
			wingState = "BLUE"
		end
		updateDynamicWingColors(ctx, wingState)

		local vel = root.AssemblyLinearVelocity
		local horiz = V3(vel.X, 0, vel.Z)
		local speed = horiz.Magnitude
		local grounded = (hum.FloorMaterial ~= Enum.Material.Air)

		local rootCF = root.CFrame
		local localVel = rootCF:VectorToObjectSpace(horiz)
		local leanZ = math.clamp(-localVel.Z / 38, -0.32, 0.32)
		local leanX = math.clamp(localVel.X / 42, -0.22, 0.22)

		local baseRootCF = CF(rootCF.Position) * (rootCF - rootCF.Position)
		if motion.isSliding then
			baseRootCF = baseRootCF * CF(0, -1.45 * S, 0.3 * S) * ANG(math.rad(55), 0, 0)
		elseif motion.isSlamming then
			baseRootCF = baseRootCF * ANG(math.rad(-25), 0, 0)
		else
			baseRootCF = baseRootCF * ANG(leanZ * 0.32, 0, -leanX * 0.32)
		end

		local breath = math.sin(now * 2.4) * 0.055 * S
		local walkFreq = motion.isSprinting and 12.5 or 8.5
		if grounded and speed > 1.5 and not motion.isSliding then
			v2State.lastWalkPhase += dt * walkFreq * math.clamp(speed / 17, 0.5, 2.0)
		end
		local wp = v2State.lastWalkPhase
		local moveAlpha = grounded and math.clamp(speed / 15, 0, 1) or 0

		local pelvisCF = baseRootCF * CF(0, -0.80 * S + breath * 0.5, 0)
		local abdomenCF = pelvisCF * CF(0, 0.58 * S, 0) * ANG(math.rad(3) + leanZ * 0.16, 0, 0)
		local chestCF = abdomenCF * CF(0, 0.78 * S + breath * 0.4, 0) * ANG(math.rad(4) + leanZ * 0.18, math.sin(wp) * 0.08 * moveAlpha, 0)

		local cam = workspace.CurrentCamera
		local headRot = ID_CF
		if cam then
			local relLook = chestCF:VectorToObjectSpace(cam.CFrame.LookVector)
			local yaw = math.clamp(math.atan2(-relLook.X, -relLook.Z), -0.65, 0.65)
			local pitch = math.clamp(math.asin(math.clamp(relLook.Y, -0.8, 0.8)), -0.45, 0.45)
			headRot = ANG(pitch, yaw, 0)
		end
		local headCF = chestCF * CF(0, 0.94 * S, -0.04 * S) * headRot

		local T = {}
		local hideSelfArms = motion.isFirstPerson and motion.fpHideArms
		local hideHead = motion.isFirstPerson
		local function setP(id, cf) T[id] = cf end

		local hBase = hideHead and CF(0, 25000, 0) or headCF
		setP("head_housing", hBase)
		setP("head_brow", hBase * CF(0, 0.46 * S, -0.14 * S))
		setP("head_cheek_l", hBase * CF(-0.60 * S, -0.06 * S, -0.04 * S))
		setP("head_cheek_r", hBase * CF(0.60 * S, -0.06 * S, -0.04 * S))
		setP("head_visor", hBase * CF(0, -0.02 * S, -0.65 * S))
		setP("head_bezel", hBase * CF(0, 0.02 * S, -0.68 * S) * ANG(0, math.rad(90), 0))
		setP("head_lens", hBase * CF(0, 0.02 * S, -0.71 * S) * ANG(0, math.rad(90), 0))
		setP("head_lens_core", hBase * CF(0, 0.02 * S, -0.73 * S) * ANG(0, math.rad(90), 0))
		setP("head_rear_sink", hBase * CF(0, 0.02 * S, 0.67 * S))
		setP("neck_col", (hideHead and CF(0, 25000, 0) or chestCF * CF(0, 0.58 * S, 0)))

		-- Torso V2 + Selo V2
		setP("chest_core", chestCF)
		setP("chest_pec_l", chestCF * CF(-0.42 * S, 0.08 * S, -0.48 * S) * ANG(math.rad(165), math.rad(10), 0))
		setP("chest_pec_r", chestCF * CF(0.42 * S, 0.08 * S, -0.48 * S) * ANG(math.rad(165), math.rad(-10), 0))
		setP("chest_slit", chestCF * CF(0, 0.05 * S, -0.62 * S))
		setP("chest_vent_l", chestCF * CF(-0.38 * S, -0.22 * S, -0.54 * S) * ANG(0, 0, math.rad(-8)))
		setP("chest_vent_r", chestCF * CF(0.38 * S, -0.22 * S, -0.54 * S) * ANG(0, 0, math.rad(8)))
		setP("chest_v2_badge", chestCF * CF(0.44 * S, 0.24 * S, -0.56 * S))
		setP("collar_l", chestCF * CF(-0.62 * S, 0.46 * S, 0) * ANG(0, 0, math.rad(-14)))
		setP("collar_r", chestCF * CF(0.62 * S, 0.46 * S, 0) * ANG(0, 0, math.rad(14)))

		setP("abdomen_spine", abdomenCF)
		setP("abdomen_tube_l", abdomenCF * CF(-0.46 * S, 0, -0.05 * S))
		setP("abdomen_tube_r", abdomenCF * CF(0.46 * S, 0, -0.05 * S))
		setP("pelvis_core", pelvisCF)
		setP("pelvis_plate", pelvisCF * CF(0, -0.04 * S, -0.06 * S))

		-- Mochila + 8 Asas
		local packCF = chestCF * CF(0, 0.06 * S, 0.60 * S)
		setP("pack_spine", packCF)
		setP("pack_fin_l", packCF * CF(-0.46 * S, 0.14 * S, 0.10 * S) * ANG(0, math.rad(18), math.rad(14)))
		setP("pack_fin_r", packCF * CF(0.46 * S, 0.14 * S, 0.10 * S) * ANG(0, math.rad(-18), math.rad(-14)))
		setP("pack_core", packCF * CF(0, 0.10 * S, 0.24 * S))

		local wingFlare = (motion.isDashing and -18 or 0) + (motion.isSprinting and 12 or 0) + v2State.wingBoost * 16
		local sweepBack = motion.isDashing and 38 or (motion.isSprinting and 26 or 18)

		for side = 1, 2 do
			local isLeft = (side == 1)
			local sTag = isLeft and "L" or "R"
			for w = 1, 4 do
				local prefix = "wing_" .. sTag .. w .. "_"
				local bob = math.sin(now * 3.0 + w * 0.7 + side) * 2.5
				local fanAngle = BASE_FAN[w] + (w <= 2 and wingFlare or -wingFlare * 0.4) + bob
				local relRoot = CF(0.50 * S, (0.24 - (w - 1) * 0.14) * S, 0.14 * S)
					* ANG(0, math.rad(sweepBack), math.rad(fanAngle))
				if isLeft then relRoot = mirrorCF(relRoot) end
				local wBase = packCF * relRoot
				local function wPart(rel) return wBase * (isLeft and mirrorCF(rel) or rel) end

				setP(prefix .. "hinge", wPart(CF(0.10 * S, 0, 0)))
				setP(prefix .. "cowl",  wPart(CF(0.44 * S, 0, 0.02 * S)))
				setP(prefix .. "rail",  wPart(CF(0.90 * S, 0.02 * S, 0.05 * S)))
				setP(prefix .. "glow1", wPart(CF(0.86 * S, 0, 0)))
				setP(prefix .. "glow2", wPart(CF(1.74 * S, 0, 0)))
				setP(prefix .. "glow3", wPart(CF(2.56 * S, 0, 0)))
				setP(prefix .. "tip",   wPart(CF(3.32 * S, 0, 0) * ANG(0, math.rad(-90), math.rad(90))))
			end
		end

		-- Braços: Knuckleblaster (Esq) + Piercer/Shotgun (Dir)
		local punchProg = (now < v2State.punchAnimEnd) and (1 - (v2State.punchAnimEnd - now) / 0.32) or 0
		local shootRecoil = (now < v2State.shootAnimEnd) and ((v2State.shootAnimEnd - now) / 0.26) or 0

		local armSwingL = math.sin(wp) * 0.50 * moveAlpha
		local armSwingR = -math.sin(wp) * 0.30 * moveAlpha

		local lShoulder = chestCF * CF(-1.14 * S, 0.30 * S, 0)
		if punchProg > 0 then
			local thrust = math.sin(punchProg * math.pi)
			lShoulder = lShoulder * ANG(math.rad(94 * thrust), math.rad(-14 * thrust), math.rad(14))
		else
			lShoulder = lShoulder * ANG(armSwingL, 0, math.rad(12 + breath * 14))
		end
		if hideSelfArms then lShoulder = CF(0, 25000, 0) end

		local lUArm = lShoulder * CF(0, -0.46 * S, 0)
		local lElb = lShoulder * CF(0, -0.94 * S, 0)
		local lFArm = lElb * ANG((punchProg > 0) and math.rad(12) or math.rad(28), 0, 0) * CF(0, -0.46 * S, 0)
		local lHand = lFArm * CF(0, -0.54 * S, 0)

		setP("sh_guard_L", lShoulder * CF(-0.10 * S, 0.08 * S, 0))
		setP("uarm_plate_L", lUArm)
		setP("elbow_L", lElb)
		setP("kb_exhaust_1", lElb * CF(-0.22 * S, 0.14 * S, 0.30 * S) * ANG(math.rad(-25), 0, math.rad(12)))
		setP("kb_exhaust_2", lElb * CF(0.06 * S, 0.18 * S, 0.34 * S) * ANG(math.rad(-25), 0, math.rad(6)))
		setP("farm_plate_L", lFArm)
		setP("kb_piston_core", lFArm * CF(0, 0, -0.22 * S))
		setP("kb_mount_plate", lHand * CF(0, 0.16 * S, -0.14 * S))
		setP("hand_L", lHand)
		setP("kb_barrel_1", lHand * CF(-0.12 * S, -0.18 * S, -0.20 * S))
		setP("kb_barrel_2", lHand * CF(0.12 * S, -0.18 * S, -0.20 * S))
		setP("kb_claw_1", lHand * CF(-0.16 * S, -0.32 * S, -0.06 * S) * ANG(math.rad(165), 0, 0))
		setP("kb_claw_2", lHand * CF(0.00 * S, -0.36 * S, -0.08 * S) * ANG(math.rad(170), 0, 0))
		setP("kb_claw_3", lHand * CF(0.16 * S, -0.32 * S, -0.06 * S) * ANG(math.rad(165), 0, 0))

		-- Braço direito + arma selecionada
		local rShoulder = chestCF * CF(1.10 * S, 0.30 * S, 0)
		if cam then
			local aimLocal = chestCF:VectorToObjectSpace(cam.CFrame.LookVector)
			local pitch = math.clamp(math.asin(math.clamp(aimLocal.Y, -0.85, 0.85)), -0.8, 0.8)
			rShoulder = rShoulder * ANG(math.rad(76) + pitch + shootRecoil * 0.42, math.rad(-6), math.rad(-6))
		else
			rShoulder = rShoulder * ANG(math.rad(68) + armSwingR, 0, math.rad(-8))
		end
		if hideSelfArms then rShoulder = CF(0, 25000, 0) end

		local rUArm = rShoulder * CF(0, -0.46 * S, 0)
		local rElb = rShoulder * CF(0, -0.94 * S, 0)
		local rFArm = rElb * ANG(math.rad(18), 0, 0) * CF(0, -0.44 * S, 0)
		local rHand = rFArm * CF(0, -0.52 * S, 0)
		setP("sh_guard_R", rShoulder * CF(0.10 * S, 0.08 * S, 0))
		setP("uarm_plate_R", rUArm)
		setP("elbow_R", rElb)
		setP("farm_plate_R", rFArm)
		setP("hand_R", rHand)

		local gunRoot = rHand * CF(0, -0.24 * S, -0.18 * S) * ANG(math.rad(-90), 0, 0)
		local piercerCF = (v2State.weaponMode == "PIERCER" and not hideSelfArms) and gunRoot or CF(0, 25000, 0)
		local shotgunCF = (v2State.weaponMode == "SHOTGUN" and not hideSelfArms) and gunRoot or CF(0, 25000, 0)

		setP("piercer_grip",   piercerCF * CF(0, -0.14 * S, 0.14 * S) * ANG(math.rad(18), 0, 0))
		setP("piercer_frame",  piercerCF * CF(0, 0.10 * S, -0.10 * S))
		setP("piercer_barrel", piercerCF * CF(0, 0.14 * S, -0.82 * S))
		setP("piercer_screen", piercerCF * CF(0, 0.28 * S, 0.08 * S))

		setP("sg_body",     shotgunCF * CF(0, 0.10 * S, -0.22 * S))
		setP("sg_barrel_l", shotgunCF * CF(-0.10 * S, 0.16 * S, -0.78 * S) * ANG(0, math.rad(90), 0))
		setP("sg_barrel_r", shotgunCF * CF(0.10 * S, 0.16 * S, -0.78 * S) * ANG(0, math.rad(90), 0))
		setP("sg_core_1",   shotgunCF * CF(-0.10 * S, 0.30 * S, -0.14 * S) * ANG(0, math.rad(90), 0))
		setP("sg_core_2",   shotgunCF * CF(0.10 * S, 0.30 * S, -0.14 * S) * ANG(0, math.rad(90), 0))

		-- Pernas (escaladas 1.16x)
		local legSwingL = math.sin(wp) * 0.70 * moveAlpha
		local legSwingR = -math.sin(wp) * 0.70 * moveAlpha
		local airRise = not grounded and math.clamp(vel.Y / 32, -1, 1) or 0

		local function placeLeg(side, xOff, hipPitch)
			local hip = pelvisCF * CF(xOff * S, -0.14 * S, 0)
			local kneeAngle = grounded and (-math.max(0, math.sin(wp + ((side == "L") and 0.4 or 3.54)) * 0.85 * moveAlpha)) or math.rad(-26 - airRise * 18)
			if motion.isSliding then
				hipPitch = math.rad(42)
				kneeAngle = math.rad(-25)
			end
			local thighCF = hip * ANG(hipPitch, 0, 0) * CF(0, -0.58 * S, 0)
			local kneeCF = hip * ANG(hipPitch, 0, 0) * CF(0, -1.16 * S, 0)
			local shinCF = kneeCF * ANG(kneeAngle, 0, 0) * CF(0, -0.58 * S, 0)
			local footCF = shinCF * CF(0, -0.62 * S, -0.18 * S) * ANG(-hipPitch - kneeAngle, 0, 0)

			setP("thigh_" .. side, thighCF)
			setP("thigh_trim_" .. side, thighCF * CF(0, 0.08 * S, -0.24 * S))
			setP("knee_" .. side, kneeCF * CF(0, 0, -0.14 * S))
			setP("shin_" .. side, shinCF)
			setP("foot_" .. side, footCF)
			setP("sole_" .. side, footCF * CF(0, -0.16 * S, 0))
			setP("heel_spur_" .. side, footCF * CF(0, 0.06 * S, 0.52 * S))
		end

		placeLeg("L", -0.39, legSwingL + (not grounded and math.rad(24) or 0))
		placeLeg("R",  0.39, legSwingR + (not grounded and math.rad(14) or 0))

		return T, {
			title = v2State.weaponMode .. " // KNUCKLEBLASTER",
			hint = "[E] ATIRAR | [F] KNUCKLE | [R] TROCAR ARMA",
		}
	end

	Core.start(V2_DEF)
end