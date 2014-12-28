Main	= ->
	# provides the data necessary to render a tiled image
	tileMap		= null
	# renders an image using tile map data
	tileLayer	= null

	animsAtlas	= null

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
			# tiled bg
			tileMap		= game.add.tilemap("map")
			# tileset name (from json), image id
			tileMap.addTilesetImage("grits_master", "map_tiles")
			# layer name (from json)
			tileLayer	= tileMap.createLayer("floor")
			# make game world size of camera
			tileLayer.resizeWorld()

			# sprite sheet image
			animsAtlas	= game.add.sprite(0, 0, "anims")
			# new id, array of frames, framerate, loop
			animsAtlas.animations.add("large_explosion",
				# file name prefix, start num, end num, postfix, num padding
				Phaser.Animation.generateFrameNames(
					"landmine_explosion_large_", 0, 29, ".png", 4
				), 25, true
			)
			animsAtlas.animations.play("large_explosion")

			# and another one
			legAnim		= game.add.sprite(400, 0, "anims")

			legAnim.animations.add("walk_anim",
				Phaser.Animation.generateFrameNames("walk_down_", 0, 29,
					".png", 4), 25, true)
			legAnim.animations.play("walk_anim")

		update:->
	)