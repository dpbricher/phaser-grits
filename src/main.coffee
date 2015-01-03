require ["lib/phaser.min"], ->
	PLAYER_SPEED		= 500
	PROJECTILE_SPEED	= 1000
	RELOAD_TIME			= 0.2

	# provides the data necessary to render a tiled image
	tileMap			= null
	# renders an image using tile map data
	tileLayer		= null
	wallLayer		= null

	musicLoop		= null
	sfx				= null

	# groups
	groupProj		= null
	groupWall		= null
	# group for player but not proj collision objects
	groupHole		= null
	groupSpawn		= null
	groupTeleport	= null
	# player body visual elements
	groupBody		= null
	# group for visual effects that have no physics
	groupVisual		= null

	player			= null
	lastFireTime	= 0

	playerBody	 	= null
	playerArmLeft 	= null
	playerArmRight 	= null

	# Phaser.Point player spawn location
	playerSpawn		= null

	moveKeys		= null
	cursors			= null

	game			= new Phaser.Game(800, 600, Phaser.AUTO, "content-main"
		preload:->
			# tiled bg
			game.load.tilemap("map", "data/map1.json", null,
				Phaser.Tilemap.TILED_JSON)
			game.load.image("map_tiles", "images/grits_master.png")

			# anims atlas
			game.load.atlas("anims", "images/grits_effects.png",
				"data/grits_effects.json", null,
				Phaser.Loader.TEXTURE_ATLAS_JSON_HASH)

			# audio
			game.load.audio("music", "sounds/bg_game.ogg", true)
			game.load.audio("mach_fire", "sounds/machine_shoot0.ogg", true)
			game.load.audio("bounce", "sounds/bounce0.ogg", true)
			game.load.audio("energy", "sounds/energy_pickup.ogg", true)
			game.load.audio("item", "sounds/item_pickup0.ogg", true)
			game.load.audio("quad", "sounds/quad_pickup.ogg", true)

		create:->
			# physics system
			game.physics.startSystem(Phaser.Physics.ARCADE)

			# audio
			# key, volume, loop
			musicLoop	= game.add.audio("music", 0.5, true)
			musicLoop.play()

			sfx			=
				bounce:game.add.audio("bounce")
				energy:game.add.audio("energy")
				item:game.add.audio("item")
				quad:game.add.audio("quad")
				fire:game.add.audio("mach_fire")

			# tiled bg
			tileMap		= game.add.tilemap("map")

			# console.log tileMap.objects
			# tileset name (from json), image id
			tileMap.addTilesetImage("grits_master", "map_tiles")
			# layer name (from json)
			tileLayer	= tileMap.createLayer("floor")
			# make game world size of camera
			tileLayer.resizeWorld()

			# add some extra layers
			tileMap.createLayer("floor_blend")
			wallLayer	= tileMap.createLayer("walls")
			tileMap.createLayer("lights")
			tileMap.createLayer("decor_02")

			# don't know if this actually helps or not; need to look into it
			tileMap.cacheAsBitmap	= true

			# create collision on walls
			# tileMap.setCollisionByExclusion([], true, "walls")

			# create groups
			groupProj		= game.add.group()
			groupWall		= game.add.group()
			groupHole		= game.add.group()
			groupSpawn		= game.add.group()
			groupTeleport	= game.add.group()

			# create sprites with null images for each collision area
			for obj in tileMap.objects.collision
				group	=
					if obj.properties.collisionFlags
					then groupHole
					else groupWall

				wall	= group.create(obj.x, obj.y, null)
				game.physics.arcade.enable(wall)
				# this doesn't work...
				# wall.body.setSize(0, 0, obj.width, obj.height)
				wall.body.width		= obj.width
				wall.body.height	= obj.height

				wall.body.immovable	= true

			# create spawners from tile map
			createCanister			= (animName, animFramePrefix, audio)->
				item	= groupSpawn.create(obj.x, obj.y, "anims")
				item.anchor.set(0.5, 0.5)

				item.animations.add(animName,
					Phaser.Animation.generateFrameNames(animFramePrefix, 0, 15,
						".png", 4), 25, true)
				item.animations.play(animName)

				item.audio				= audio

				item.lastCollectTime	= 0

				game.physics.arcade.enable(item)

				item.body.immovable		= true

			for obj in tileMap.objects.environment
				switch obj.name
					when "HealthSpawner"
						createCanister("canister_health",
							"energy_canister_red_", sfx.item)

					when "EnergySpawner"
						createCanister("canister_energy",
							"energy_canister_blue_", sfx.energy)

					when "QuadDamageSpawner"
						createCanister("quad_damage", "quad_damage_", sfx.quad)

					when "Team0Spawn0"
						playerSpawn	= new Phaser.Point(obj.x + obj.width / 2,
							obj.y + obj.height / 2)

					when "TP"
						teleporter	= groupTeleport.create(obj.x, obj.y,
							"anims")
						teleporter.anchor.set(0.5, 0.5)

						teleporter.animations.add("teleporter",
							Phaser.Animation.generateFrameNames(
								"teleporter_idle_", 0, 15, ".png", 4), 25,
								true)
						teleporter.animations.play("teleporter")

						game.physics.arcade.enable(teleporter)

						teleDest	= /([\d\.]*)\s*,\s*([\d\.]*)/
							.exec(obj.properties.destination)

						teleporter.destX	= parseFloat(teleDest[1] || 0);
						teleporter.destY	= parseFloat(teleDest[2] || 0);

			# sprite sheet image
			player		= game.add.sprite(playerSpawn.x, playerSpawn.y,
				"anims")
			player.anchor.set(0.5, 0.5)

			# new id, array of frames, framerate, loop
			player.animations.add("walk_anim",
				# file name prefix, start num, end num, postfix, num padding
				Phaser.Animation.generateFrameNames("walk_left_", 0, 29,
					".png", 4), 25, true)
			player.animations
			.play("walk_anim")
			.stop()

			game.physics.arcade.enable(player)

			player.body.collideWorldBounds	= true
			# shrink player physical dimensions
			player.body.setSize(player.body.width / 2, player.body.height / 2)

			groupBody		= game.add.group()
			groupVisual		= game.add.group()

			playerBody		= groupBody.create(0, 0, "anims")
			playerBody.anchor.set(0.5, 0.5)

			playerBody.animations.add("turret", ["turret.png"], 25, true)
			playerBody.animations.play("turret")

			playerArmLeft	= groupBody.create(0, 0, "anims")
			playerArmLeft.anchor.set(0.5, 0.5)

			playerArmLeft.animations.add("machinegun", ["machinegun.png"], 25,
				true)
			playerArmLeft.animations.play("machinegun")

			playerArmRight	= groupBody.create(0, 0, "anims")
			playerArmRight.anchor.set(0.5, 0.5)
			playerArmRight.scale.set(1.0, -1.0)

			playerArmRight.animations.add("machinegun", ["machinegun.png"], 25,
				true)
			playerArmRight.animations.play("machinegun")

			lastFireTime	= game.time.totalElapsedSeconds()

			# input
			keyboard	= game.input.keyboard

			# create input object for arrow keys
			cursors		= keyboard.createCursorKeys()

			# do similar thing manually for other keys
			moveKeys	=
				up:keyboard.addKey(Phaser.Keyboard.W)
				down:keyboard.addKey(Phaser.Keyboard.S)
				left:keyboard.addKey(Phaser.Keyboard.A)
				right:keyboard.addKey(Phaser.Keyboard.D)

			# camera
			game.camera.follow(player)

		update:->
			# movement
			velocity	= player.body.velocity.set(0, 0)

			if moveKeys.right.isDown
				velocity.x	+= 1

			if moveKeys.left.isDown
				velocity.x	-= 1

			if moveKeys.up.isDown
				velocity.y	-= 1

			if moveKeys.down.isDown
				velocity.y	+= 1

			velocity
			.normalize()
			.multiply(PLAYER_SPEED, PLAYER_SPEED)

			# if player is moving then advance walk animation
			if !velocity.isZero()
				player.rotation	= velocity.angle(new Phaser.Point())
				player.animations.next(1)

			bodyCentreX		= player.body.x + player.body.width / 2
			bodyCentreY		= player.body.y + player.body.height / 2

			# player body and arms
			groupBody.x		= bodyCentreX
			groupBody.y		= bodyCentreY

			# fire projectiles
			velocity	= new Phaser.Point()

			if cursors.right.isDown
				velocity.x	+= 1

			if cursors.left.isDown
				velocity.x	-= 1

			if cursors.up.isDown
				velocity.y	-= 1

			if cursors.down.isDown
				velocity.y	+= 1

			if !velocity.isZero() and
			game.time.totalElapsedSeconds() - lastFireTime >= RELOAD_TIME
				bullet	= groupProj.create(
					player.body.position.x + player.body.width / 2,
					player.body.position.y + player.body.height / 2, "anims")
				bullet.anchor.set(0.5, 0.5)

				bullet.animations.add("bullet",
					Phaser.Animation.generateFrameNames(
						"machinegun_projectile_", 0, 7, ".png", 4),
					25, true)
				bullet.animations.play("bullet")

				game.physics.arcade.enable(bullet)

				bullet.body.setSize(10, 10)

				velocity.normalize()

				groupBody.rotation	=
				bullet.rotation		= velocity.angle(new Phaser.Point())

				bullet.body.velocity	= velocity
				.multiply(PROJECTILE_SPEED, PROJECTILE_SPEED)

				# left and right weapon muzzle animations
				for i in [0, 1]
					muzzle	= groupBody.create(0, 0, "anims")
					muzzle.anchor.set(0.5, 0.5)

					muzzle.animations.add("muzzle",
						Phaser.Animation.generateFrameNames(
							"machinegun_muzzle_", 0, 7, ".png", 4),
						25, true)
					muzzle.play("muzzle", null, false, true)

				muzzle.scale.set(1.0, -1.0)

				sfx.fire.play()

				lastFireTime			= game.time.totalElapsedSeconds()

			# collision
			game.physics.arcade.collide(player, groupWall)
			game.physics.arcade.collide(player, groupHole)

			game.physics.arcade.overlap(player, groupTeleport,
				(p, t)->
					player.body.x	= game.world.width * (t.destX / 100)
					player.body.y	= game.world.height * (t.destY / 100)
					sfx.bounce.play()
			)

			game.physics.arcade.overlap(player, groupSpawn,
				(p, s)->
					if s.visible
						s.visible			= false
						s.lastCollectTime	= game.time.totalElapsedSeconds()
						s.audio.play()
			)

			now		= game.time.totalElapsedSeconds()

			# bullet collision here; group on group collision doesn't seem to
			# work
			groupWall.forEach(
				(wall)->
					groupProj.forEachAlive(
						(proj)->
							if wall.body.hitTest(proj.x, proj.y)
								proj.kill()

								# create bullet death anim
								anim	= groupVisual.create(proj.x, proj.y
									"anims")
								anim.anchor.set(0.5, 0.5)

								anim.animations.add("impact",
									Phaser.Animation.generateFrameNames(
										"machinegun_impact_", 0, 7, ".png", 4),
									25, true
								)
								anim.play("impact", null, false, true)
					)
			)

			# spawn item generation
			groupSpawn.forEach(
				(s)->
					if now >= s.lastCollectTime + 3.0
						s.visible	= true
			)

		render:->
			game.debug.body(player, "rgba(0, 255, 255, 0.4)")

			groupProj.forEach(
				(proj)->
					game.debug.body(proj, "rgba(255, 0, 255, 0.4)")
				@
			)
			groupSpawn.forEach(
				(proj)->
					game.debug.body(proj, "rgba(255, 255, 0, 0.4)")
				@
			)
			groupTeleport.forEach(
				(proj)->
					game.debug.body(proj, "rgba(255, 0, 0, 0.4)")
				@
			)
			groupWall.forEach(
				(proj)->
					game.debug.body(proj)
				@
			)
			groupHole.forEach(
				(proj)->
					game.debug.body(proj, "rgba(0, 0, 255, 0.4)")
				@
			)
	)
