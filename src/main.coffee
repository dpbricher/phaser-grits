require ["preload", "game", "lib/phaser.min"], (sp, sg)->
	game	= new Phaser.Game(800, 600, Phaser.AUTO, "content-main")

	game.state.add("Game", sg.Game)
	game.state.add("Preload", sp.Preload)

	game.state.start("Preload")
