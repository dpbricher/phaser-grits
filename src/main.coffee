requirejs.config
	paths:
		"phaser":"lib/phaser.min"
	shim:
		"phaser":
			exports:"Phaser"

require ["preload", "game", "phaser"],
	(Preload, Game, Phaser)->
		game	= new Phaser.Game(800, 600, Phaser.AUTO, "content-main")

		game.state.add("Game", Game)
		game.state.add("Preload", Preload)

		game.state.start("Preload")
