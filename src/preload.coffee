define ["phaser"],
	(Phaser)->
		class Preload extends Phaser.State
			preload:->
				###
				@game.load.tilemap("map", "data/map1.json", null,
					Phaser.Tilemap.TILED_JSON)
				@game.load.image("map_tiles", "images/grits_master.png")

				# anims atlas
				@game.load.atlas("anims", "images/grits_effects.png",
					"data/grits_effects.json", null,
					Phaser.Loader.TEXTURE_ATLAS_JSON_HASH)

				# audio
				@game.load.audio("music", "sounds/bg_game.ogg", true)
				@game.load.audio("mach_fire", "sounds/machine_shoot0.ogg", true)
				@game.load.audio("bounce", "sounds/bounce0.ogg", true)
				@game.load.audio("energy", "sounds/energy_pickup.ogg", true)
				@game.load.audio("item", "sounds/item_pickup0.ogg", true)
				@game.load.audio("quad", "sounds/quad_pickup.ogg", true)
				@game.load.audio("explode", "sounds/explode0.ogg", true)
				###

			create:->
				setTimeout(
					=>
						@game.state.start("Game")
					0
				)
