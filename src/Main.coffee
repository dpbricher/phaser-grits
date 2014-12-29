Main	= ->
	PLAYER_SPEED	= 1000
	# provides the data necessary to render a tiled image
	tileMap		= null
	# renders an image using tile map data
	tileLayer	= null

	player		= null

	cursors		= null

	game	= new Phaser.Game(800, 600, Phaser.AUTO, "content-main"
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
			# this works but runs slow :(
			tileMap.createLayer("floor_blend")
			tileMap.createLayer("walls")
			tileMap.createLayer("lights")
			tileMap.createLayer("decor_02")

			# sprite sheet image
			player		= game.add.sprite(0, 0, "anims")

			# new id, array of frames, framerate, loop
			player.animations.add("walk_anim",
				# file name prefix, start num, end num, postfix, num padding
				Phaser.Animation.generateFrameNames("walk_down_", 0, 29,
					".png", 4), 25, true)
			player.animations
			.play("walk_anim")
			.stop()

			game.physics.arcade.enable(player)

			player.body.collideWorldBounds	= true

			# input
			cursors	= game.input.keyboard.createCursorKeys()

			# camera
			game.camera.follow(player)
			
		update:->
			velocity	= player.body.velocity.set(0, 0)			

			if cursors.right.isDown
				velocity.x	+= 1

			if cursors.left.isDown
				velocity.x	-= 1
			
			if cursors.up.isDown
				velocity.y	-= 1
			
			if cursors.down.isDown
				velocity.y	+= 1

			velocity
			.normalize()
			.multiply(PLAYER_SPEED, PLAYER_SPEED)
	)