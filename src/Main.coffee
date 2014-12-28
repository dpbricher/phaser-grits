Main	= ->
	# provides the data necessary to render a tiled image
	tileMap		= null
	# renders an image using tile map data
	tileLayer	= null

	game	= new Phaser.Game(800, 600, Phaser.AUTO, "content-main"
		preload:->
			game.load.tilemap("map", "data/map1.json", null, Phaser.Tilemap.TILED_JSON)
			game.load.image("map_tiles", "images/grits_master.png")
			# tileMap		= game.load.tilemap("map", "data/map1.json", null, Phaser.Tilemap.TILED_JSON)

		create:->
			tileMap		= game.add.tilemap("map")
			# tileset name (from json), image id
			tileMap.addTilesetImage("grits_master", "map_tiles")
			# layer name (from json)
			tileLayer	= tileMap.createLayer("floor")
			# make game world size of camera
			tileLayer.resizeWorld()

		update:->
			game.camera.setPosition(game.camera.x + 5, game.camera.y + 5)
	)