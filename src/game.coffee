define ["phaser"],
	(Phaser)->
		class Game extends Phaser.State
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
			# group for newly created projectiles, hack for a collision issue
			groupWall		= null
			# group for player but not proj collision objects
			groupHole		= null
			groupSpawn		= null
			groupTeleport	= null
			# player legs
			groupLegs		= null
			# player body visual elements
			groupBody		= null
			groupBody2		= null
			# group for visual effects that have no physics
			groupVisual		= null
			groupText		= null

			player1			= null
			player2			= null

			# Phaser.Point player spawn location
			playerSpawn		= null
			playerSpawn2	= null

			moveKeys		= null
			cursors			= null

			game			= null

			preload:->
				game		= @game

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
				game.load.audio("explode", "sounds/explode0.ogg", true)

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
				groupLegs		= game.add.group()
				groupBody		= game.add.group()
				groupBody2		= game.add.group()
				groupVisual		= game.add.group()
				groupText		= game.add.group()

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

						when "Team1Spawn0"
							playerSpawn2	= new Phaser.Point(
								obj.x + obj.width / 2, obj.y + obj.height / 2)

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

				# players
				createPlayer	= (x, y, bodyGroup)->
					player			=
						legs:groupLegs.create(x, y, "anims")
						body:bodyGroup.create(0, 0, "anims")
						armLeft:bodyGroup.create(0, 0, "anims")
						armRight:bodyGroup.create(0, 0, "anims")
						lastFireTime:game.time.totalElapsedSeconds()
						healthDisplay:game.add.text(x, y, "")

					for key, sprite of player
						if typeof(sprite) is "object"
							sprite.anchor?.set?(0.5, 0.5)

					player.legs.animations.add("walk_anim",
						# file name prefix, start num, end num, postfix, num padding
						Phaser.Animation.generateFrameNames("walk_left_", 0, 29,
							".png", 4), 25, true)
					player.legs
					.play("walk_anim")
					.stop()

					player.legs.health		= 100

					player.legs.bodyGroup	= bodyGroup

					game.physics.arcade.enable(player.legs)

					player.legs.body.setSize(player.legs.body.width / 2,
						player.legs.body.height / 2)

					player.body.animations.add("turret", ["turret.png"], 25, true)
					player.body.play("turret")

					player.armLeft.animations.add("machinegun", ["machinegun.png"],
						25, true)
					player.armLeft.play("machinegun")

					player.armRight.animations.add("machinegun", ["machinegun.png"],
						25, true)
					player.armRight.play("machinegun")
					player.armRight.scale.set(1.0, -1.0)

					return player

				player1		= createPlayer(playerSpawn.x + 100, playerSpawn.y,
					groupBody)
				player2		= createPlayer(playerSpawn.x, playerSpawn.y,
					groupBody2)
				# player2		= createPlayer(playerSpawn2.x, playerSpawn2.y,
					# groupBody2)

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
				game.camera.follow(player1.legs)

			update:->
				# collision
				game.physics.arcade.collide(player1.legs, groupWall)
				game.physics.arcade.collide(player1.legs, groupHole)

				detonateProj	= (proj)->
					proj.kill()

					# create bullet death anim
					anim	= groupVisual.create(proj.x, proj.y, "anims")
					anim.anchor.set(0.5, 0.5)

					anim.animations.add("impact",
						Phaser.Animation.generateFrameNames("machinegun_impact_",
							0, 7, ".png", 4), 25, true)
					anim.play("impact", null, false, true)

				detonatePlayer	= (legs, bodyGroup)->
					legs.kill()
					bodyGroup.forEach(
						(sprite)->
							sprite.kill()
						@
					)

					anim	= groupVisual.create(legs.body.center.x,
						legs.body.center.y, "anims")
					anim.anchor.set(0.5, 0.5)

					anim.animations.add("death",
						Phaser.Animation.generateFrameNames(
							"landmine_explosion_large_", 0, 29, ".png", 4), 25,
						true)
					anim.play("death", null, false, true)

					game.add
					.audio("explode")
					.play()

				game.physics.arcade.overlap(groupLegs, groupProj,
					(legs, proj)->
						legs.health	-= 10

						detonateProj(proj)

						if legs.health <= 0
							detonatePlayer(legs, legs.bodyGroup)
				)

				game.physics.arcade.overlap(groupLegs, groupTeleport,
					(p, t)->
						p.body.x	= game.world.width * (t.destX / 100)
						p.body.y	= game.world.height * (t.destY / 100)
						sfx.bounce.play()
				)

				game.physics.arcade.overlap(groupLegs, groupSpawn,
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
									detonateProj(proj)
						)
				)

				# spawn item generation
				groupSpawn.forEach(
					(s)->
						if now >= s.lastCollectTime + 3.0
							s.visible	= true
				)

				# movement
				velocity	= player1.legs.body.velocity.set(0, 0)

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
					player1.legs.rotation	= velocity.angle(new Phaser.Point())
					player1.legs.animations.next(1)

				# player body and arms
				groupBody.x		= player1.legs.body.x + player1.legs.body.width / 2
				groupBody.y		= player1.legs.body.y +
					player1.legs.body.height / 2

				player1.healthDisplay.x	= player1.legs.body.center.x
				player1.healthDisplay.y	= player1.legs.body.y

				player1.healthDisplay.text	= player1.legs.health.toString()

				player2.healthDisplay.x	= player2.legs.body.center.x
				player2.healthDisplay.y	= player2.legs.body.y

				player2.healthDisplay.text	= player2.legs.health.toString()

				groupBody2.x	= player2.legs.body.center.x
				groupBody2.y	= player2.legs.body.center.y

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
				game.time.totalElapsedSeconds() - player1.lastFireTime >=
				RELOAD_TIME
					bullet	= groupProj.create(player1.legs.body.center.x,
						player1.legs.body.center.y, "anims")
					bullet.anchor.set(0.5, 0.5)

					bullet.animations.add("bullet",
						Phaser.Animation.generateFrameNames(
							"machinegun_projectile_", 0, 7, ".png", 4),
						25, true)
					bullet.animations.play("bullet")

					game.physics.arcade.enable(bullet)

					bullet.body.setSize(10, 10)

					velocity.normalize()
					offset				= velocity.clone()

					groupBody.rotation	=
					bullet.rotation		= velocity.angle(new Phaser.Point())

					bullet.body.velocity	= velocity
					.multiply(PROJECTILE_SPEED, PROJECTILE_SPEED)

					offset.multiply(player1.legs.body.width,
						player1.legs.body.width)

					bullet.body.x		+= offset.x
					bullet.body.y		+= offset.y
					bullet.brandNew	= true

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

					player1.lastFireTime	= game.time.totalElapsedSeconds()

			# render:->
