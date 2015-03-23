define ["phaser", "player", "projectile", "spawn_item", "grid_mapper",
	"path_finder", "path_follower"],
	(Phaser, Player, Projectile, SpawnItem, GridMapper, PathFinder, Follower)->
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
			groupPlayer		= null
			# player body visual elements
			groupBody		= null
			# group for visual effects that have no physics
			groupVisual		= null
			groupText		= null

			player1			= null
			player2			= null

			# Phaser.Point player spawn location
			playerSpawn		= null
			playerSpawn2	= null

			# grid model of map
			gridMap			= null

			follower		= null

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
				groupPlayer		= game.add.group()
				groupBody		= game.add.group()
				groupVisual		= game.add.group()
				groupText		= game.add.group()

				# create sprites with null images for each collision area
				for obj in tileMap.objects.collision
					# some objects have an undefined width and height for some reason;
					# skip those objects
					if !obj.width?
						continue

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
				createCanister			= (posObj, animName, animFramePrefix,
					audio, collisionFunction)->
					item	= new SpawnItem(game, posObj.x, posObj.y, animName,
						animFramePrefix, audio, collisionFunction)
					groupSpawn.add(item)

				for obj in tileMap.objects.environment
					switch obj.name
						when "HealthSpawner"
							createCanister(obj, "canister_health",
								"energy_canister_red_", sfx.item,
								(player)->
									player.gainHealth(20)
							)

						when "EnergySpawner"
							""
							# createCanister(obj, "canister_energy",
								# "energy_canister_blue_", sfx.energy)

						when "QuadDamageSpawner"
							createCanister(obj, "quad_damage", "quad_damage_",
								sfx.quad)

						when "Team0Spawn0"
							playerSpawn	= new Phaser.Point(
								obj.x + obj.width / 2, obj.y + obj.height / 2)

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

							teleporter.destX	= parseFloat(teleDest[1] || 0)
							teleporter.destY	= parseFloat(teleDest[2] || 0)

				# players
				createPlayer	= (x, y)->
					player	= new Player(game, x, y)

					groupPlayer.add(player)
					groupBody.add(player.bodyGroup)

					player

				player1		= createPlayer(playerSpawn.x + 100, playerSpawn.y)
				# player2		= createPlayer(playerSpawn.x, playerSpawn.y)
				player2		= createPlayer(playerSpawn2.x, playerSpawn2.y)

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

				# grid map
				gridMap				= new GridMapper(player2.body.width, player2.body.height,
					new Phaser.Rectangle(0, 0, game.world.width, game.world.height),
					groupWall, groupHole)

				# set the unreachable areas to impassable (for now)
				gridMap.setArea(new Phaser.Rectangle(4630, 1163, 583, 559), 1)
				gridMap.setArea(new Phaser.Rectangle(1123, 4589, 453, 578), 1)

				follower		= new Follower(player2)

				pathFinder	= new PathFinder(gridMap)

				setP2Path		= (results)=>
					follower.setPath(results)

				pathFinder.findXy(playerSpawn2.x, playerSpawn2.y, playerSpawn.x,
					playerSpawn.y, setP2Path)

				# camera
				game.camera.follow(player1)

			update:->
				# collision
				game.physics.arcade.collide(player1, groupWall)
				game.physics.arcade.collide(player1, groupHole)

				detonateProj	= (proj)->
					proj.kill()

					# create bullet death anim
					anim	= groupVisual.create(proj.x, proj.y, "anims")
					anim.anchor.set(0.5, 0.5)

					anim.animations.add("impact",
						Phaser.Animation.generateFrameNames(
							"machinegun_impact_", 0, 7, ".png", 4), 25, true)
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

				game.physics.arcade.overlap(groupPlayer, groupProj,
					(player, proj)->
						if proj.getOwner() != player
							detonateProj(proj)

							player.loseHealth(proj.getDamage())

							if player.health <= 0
								detonatePlayer(player, player.bodyGroup)
				)

				game.physics.arcade.overlap(groupPlayer, groupTeleport,
					(p, t)->
						p.moveTo(game.world.width * (t.destX / 100),
							game.world.height * (t.destY / 100))
						sfx.bounce.play()
				)

				game.physics.arcade.overlap(groupPlayer, groupSpawn,
					(p, s)->
						if s.visible
							s.collisionFunction(p)

							s.visible			= false
							s.lastCollectTime	=
								game.time.totalElapsedSeconds()
							s.audio.play()
				)

				now		= game.time.totalElapsedSeconds()

				# bullet collision here; group on group collision won't catch
				# those spawned inside a wall (e.g. due to offset)
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
				velocity	= player1.body.velocity.set(0, 0)

				velocity.x += 1 if moveKeys.right.isDown
				velocity.x -= 1 if moveKeys.left.isDown
				velocity.y -= 1 if moveKeys.up.isDown
				velocity.y += 1 if moveKeys.down.isDown

				velocity
				.normalize()
				.multiply(PLAYER_SPEED, PLAYER_SPEED)

				newVel	= follower.getMoveVec()

				player2.body.velocity
				.set(newVel.x, newVel.y)
				.multiply(PLAYER_SPEED, PLAYER_SPEED)

				# if player is moving then advance walk animation
				for p in [player1, player2]
					if !p.body.velocity.isZero()
						p.rotateLegs(velocity.angle(new Phaser.Point))
						p.animations.next(1)

				player1.update()
				player2.update()

				# fire projectiles
				velocity	= new Phaser.Point()

				velocity.x += 1 if cursors.right.isDown
				velocity.x -= 1 if cursors.left.isDown
				velocity.y -= 1 if cursors.up.isDown
				velocity.y += 1 if cursors.down.isDown

				if !velocity.isZero() and
				game.time.totalElapsedSeconds() - player1.lastFireTime >=
				RELOAD_TIME
					velocity.normalize()
					console.log(player1.body.x, player1.body.y)

					fireAngle	= velocity.angle(new Phaser.Point())

					# set body rotation to match firing angle
					player1.rotateBody(fireAngle)

					# left and right projectiles
					for fireOrigin in [player1.getMuzzleLeft(),
					player1.getMuzzleRight()]
						bullet	= new Projectile(game, fireOrigin.x,
							fireOrigin.y, player1, 5)
						groupProj.add(bullet)

						bullet.rotation			= fireAngle

						bullet.body.velocity	= velocity
						.clone()
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

					player1.lastFireTime	= game.time.totalElapsedSeconds()

			# render:->
