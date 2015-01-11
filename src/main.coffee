require ["game", "lib/phaser.min"], ->
	game	= new Phaser.Game(800, 600, Phaser.AUTO, "content-main")

	game.state.add("Game", Game)
	game.state.start("Game")
