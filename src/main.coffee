require ["lib/phaser.min"], ->
	PLAYER_SPEED		= 500
	PROJECTILE_SPEED	= 1000
	RELOAD_TIME			= 0.2

	# provides the data necessary to render a tiled image
	tileMap			= null
	# renders an image using tile map data
	tileLayer		= null
	wallLayer		= null

	# groups
	groupProj		= null

	player			= null
	lastFireTime	= 0

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

		create:->
			# physics system
			game.physics.startSystem(Phaser.Physics.ARCADE)

			# tiled bg
			tileMap		= game.add.tilemap("map")
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

			# create collision on walls
			tileMap.setCollisionByExclusion([], true, "walls")

			# create groups
			groupProj	= game.add.group()

			# sprite sheet image
			player		= game.add.sprite(1284, 1284, "anims")
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

				velocity.normalize()

				bullet.rotation	= velocity.angle(new Phaser.Point())

				bullet.body.velocity	= velocity
				.multiply(PROJECTILE_SPEED, PROJECTILE_SPEED)

				lastFireTime			= game.time.totalElapsedSeconds()

			# collision
			game.physics.arcade.collide(player, wallLayer)

		render:->
			game.debug.body(player)

	)
