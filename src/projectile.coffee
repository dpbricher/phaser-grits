define ["phaser"],
	(Phaser)->
		class Projectile extends Phaser.Sprite
			constructor:(game, x, y, @_owner, @_damage)->
				super(game, x, y, "anims")

				game.physics.arcade.enable(this)

				@body.setSize(10, 10)

				@anchor.set(0.5, 0.5)

				@animations.add("bullet",
					Phaser.Animation.generateFrameNames(
						"machinegun_projectile_", 0, 7, ".png", 4),
					25, true)
				@animations.play("bullet")

			getOwner:->
				@_owner

			getDamage:->
				@_damage
