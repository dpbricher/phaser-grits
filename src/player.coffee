#
# player object
# the player's legs are used as the main sprite for the player
# the player's body elements are added to a seperate group and need to be added
# to the game seperately
#
define ["phaser"],
	(Phaser)->
		class Player extends Phaser.Sprite
			constructor:(game, x, y)->
				super(game, x, y, "anims")

				game.add.existing(this)
				game.physics.arcade.enable(this)

				@anchor.set(0.5, 0.5)
				@body.setSize(@body.width / 2, @body.height / 2)

				# left and right arm projectile fire points
				@_muzzleLeft	= new Phaser.Point(-@body.width * 0.5,
					@body.height * -0.25)
				@_muzzleRight	= new Phaser.Point(-@body.width * 0.5,
					@body.height * 0.25)

				@health			= 100
				@lastFireTime	= game.time.totalElapsedSeconds()

				@healthDisplay	= game.add.text(0, 0, "")
				@bodyGroup		= @_createBody(game.make.group())
				@_addLegAnim()

			moveTo:(x, y)->
				@body.x	= x
				@body.y	= y

			rotateLegs:(rot)->
				@rotation	= rot

			rotateBody:(rot)->
				@bodyGroup.rotation	= rot

			getBodyRotation:->
				@bodyGroup.rotation

			getMuzzleLeft:->
				@_getTransformedMuzzle(@_muzzleLeft)

			getMuzzleRight:->
				@_getTransformedMuzzle(@_muzzleRight)

			update:->
				@bodyGroup.x		= @body.x + @body.width / 2
				@bodyGroup.y		= @body.y + @body.height / 2

				# @healthDisplay.x	= @body.center.x
				@healthDisplay.x	= @body.x
				@healthDisplay.y	= @body.y

				@healthDisplay.text	= @health.toString()


			# make the animation of this sprite the player's legs
			_addLegAnim:->
				@animations.add("walk_anim",
					# file name prefix, start num, end num, postfix,
					# num padding
					Phaser.Animation.generateFrameNames("walk_left_", 0, 29,
						".png", 4), 25, true)

				@play("walk_anim").stop()

			# create torso and arm sprites
			_createBody:(group)->
				@torso			= group.create(0, 0, "anims")
				@armLeft		= group.create(0, 0, "anims")
				@armRight		= group.create(0, 0, "anims")

				for sprite in [@torso, @armLeft, @armRight]
					sprite.anchor.set(0.5, 0.5)

				@torso.animations.add("turret", ["turret.png"], 25, true)
				@torso.play("turret")

				@armLeft.animations.add("machinegun", ["machinegun.png"],
					25, true)
				@armLeft.play("machinegun")

				@armRight.animations.add("machinegun", ["machinegun.png"],
					25, true)
				@armRight.play("machinegun")
				@armRight.scale.set(1.0, -1.0)

				group

			_getTransformedMuzzle:(muzzleOffset)->
				muzzleOffset
				.clone()
				.add(@body.center.x, @body.center.y)
				.rotate(@body.center.x, @body.center.y, @bodyGroup.rotation)
