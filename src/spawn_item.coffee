define ["phaser"],
	(Phaser)->
		class SpawnItem extends Phaser.Sprite
			#
			# collision function should take the following format:
			#
			# (collidingPlayer)->
			# 	[logic that affects the player]
			#
			constructor:(game, x, y, animName, animFramePrefix, @audio,
				@collisionFunction = ->)->
				super(game, x, y, "anims")

				game.physics.arcade.enable(this)

				@anchor.set(0.5, 0.5)
				@body.immovable		= true

				@lastCollectTime	= 0

				@animations.add(animName,
					Phaser.Animation.generateFrameNames(animFramePrefix, 0,
						15, ".png", 4), 25, true)
				@animations.play(animName)
