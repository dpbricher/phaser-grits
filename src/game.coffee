define ["phaser", "player", "projectile", "spawn_item", "move_ai", "fire_ai",
"mini_map", "quad_damage_mod", "spawn_info"],
	(Phaser, Player, Projectile, SpawnItem, MoveAi, FireAi, MiniMap,
	QuadDamageModifier, SpawnInfo)->
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

			player2MoveAi	= null
			player2FireAi	= null

			miniMap				= null

			moveKeys		= null
			cursors			= null

			spawnInfoList	= []

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
							createCanister(obj, "canister_energy",
								"energy_canister_blue_", sfx.energy,
								(player)->
									player.gainShield(20)
							)

						when "QuadDamageSpawner"
							createCanister(obj, "quad_damage", "quad_damage_",
								sfx.quad,
								(player)->
									player.addModifier(
										new QuadDamageModifier(player,
											game.time.totalElapsedSeconds() + 10)
									)
							)

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
				createPlayer	= (x, y, mapColour)->
					player	= new Player(game, x, y, PLAYER_SPEED, mapColour)

					groupPlayer.add(player)
					groupBody.add(player.bodyGroup)

					player

				player1		= createPlayer(playerSpawn.x, playerSpawn.y, 0xff)
				player2		= createPlayer(playerSpawn2.x, playerSpawn2.y, 0xff0000)

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

				# player 2 pathfinding ai
				areaRect		= new Phaser.Rectangle(1070, 1070, 5237 - 1070,
					5265 - 1070)
				# this is *a* way of aligning the grid with the map
				areaRect.x	-= areaRect.x % player1.body.width
				areaRect.y	-= areaRect.y % player1.body.height

				areaRect.offset(player2.body.width, player2.body.height)

				player2MoveAi = new MoveAi(player2, areaRect, groupWall, groupHole)

				# set the unreachable areas to impassable (for now)
				player2MoveAi.setGridAreasTo(
					new Phaser.Rectangle(4630, 1163, 583, 559),
					new Phaser.Rectangle(1123, 4589, 453, 578),
					1
				)

				# set teleporters off limits too
				tpList	= []
				groupTeleport.forEach(
					(t)->
						# the anchor point offset doesn't get applied until first update,
						# so manually offsetting it here
						area	= new Phaser.Rectangle(t.x, t.y, t.width, t.height)
						.offset(-t.width / 2, -t.height / 2)

						tpList.push(area)
				)

				player2MoveAi.setGridAreasTo(tpList..., 1)

				# start random movement
				player2MoveAi.seekRandomCell()

				# player 2 fire ai
				player2FireAi	= new FireAi(player2, FireAi.makeRectSearch(
					game.camera.view))

				# mini map
				miniW			= 200
				miniH			= miniW * game.world.height / game.world.width

				miniMap		= new MiniMap(game, game.camera.view.width - miniW, 0, miniW,
					miniH)

				miniMap.alpha					= 0.5
				miniMap.fixedToCamera	= true

				groupWall.forEach((w)-> miniMap.addWall(w))
				groupHole.forEach((w)-> miniMap.addHole(w))

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
					legs.hideBody()

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

							player.damage(proj.getDamage())

							if player.health <= 0
								detonatePlayer(player, player.bodyGroup)

								switch player
									when player1
										spawnPoint	= playerSpawn

									else
										spawnPoint	= playerSpawn2
										player2MoveAi.stop()

								spawnInfoList.push(new SpawnInfo(player,
									game.time.totalElapsedSeconds() + 2, spawnPoint.x,
									spawnPoint.y))
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
							s.onCollision(p)
				)

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
						s.update()
				)

				# mini map
				miniMap.redraw(player1, player2)

				# movement
				velocity	= player1.body.velocity.set(0, 0)

				velocity.x += 1 if moveKeys.right.isDown
				velocity.x -= 1 if moveKeys.left.isDown
				velocity.y -= 1 if moveKeys.up.isDown
				velocity.y += 1 if moveKeys.down.isDown

				velocity
				.normalize()
				.multiply(player1.moveSpeed, player1.moveSpeed)

				player2MoveAi.update()

				# if player is moving then advance walk animation
				groupPlayer.forEach(
					(p)->
						if !p.body.velocity.isZero()
							p.rotateLegs(p.body.velocity.angle(new Phaser.Point()))
							p.animations.next(1)
				)

				player1.update()
				player2.update()

				# fire projectiles
				velocity	= player1.fireVelocity

				velocity.x += 1 if cursors.right.isDown
				velocity.x -= 1 if cursors.left.isDown
				velocity.y -= 1 if cursors.up.isDown
				velocity.y += 1 if cursors.down.isDown

				player2.fireVelocity	= player2FireAi.getFireVec(player1.body.center.clone())

				groupPlayer.forEach(
					(p)->
						velocity	= p.fireVelocity
						if !velocity.isZero() and
						game.time.totalElapsedSeconds() - p.lastFireTime >= RELOAD_TIME
							velocity.normalize()

							fireAngle	= velocity.angle(new Phaser.Point())

							# set body rotation to match firing angle
							p.rotateBody(fireAngle)

							# left and right projectiles
							for fireOrigin in [p.getMuzzleLeft(),
							p.getMuzzleRight()]
								bullet	= new Projectile(game, fireOrigin.x,
									fireOrigin.y, p, 5 * p.getDamageModifier())

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

							p.lastFireTime	= game.time.totalElapsedSeconds()

						p.fireVelocity.set(0, 0)
				)

				for i in [spawnInfoList.length - 1..0] by -1
					info	= spawnInfoList[i]

					if game.time.totalElapsedSeconds() >= info.spawnTime
						@spawnPlayer(info)
						spawnInfoList.splice(i, 1)

			# render:->
			# 	groupTeleport.forEach(
			# 		(t)->
			# 			game.debug.body(t)
			# 	)

			spawnPlayer:(spawnInfo)->
				p	= spawnInfo.player

				p.revive(spawnInfo.health)
				p.showBody()

				p.shield	= spawnInfo.shield
				p.moveTo(spawnInfo.spawnX, spawnInfo.spawnY)

				# restart move ai if npc
				setTimeout(
					->player2MoveAi.seekRandomCell()
				, 0) if p == player2
