#
# player object
# the player's legs are used as the main sprite for the player
# the player's body elements are added to a seperate group and need to be added
# to the game seperately
#
define ["phaser", "quad_damage_mod"],
	(Phaser, QuadDamageModifier)->
		class Player extends Phaser.Sprite
			constructor:(game, x, y, @moveSpeed, mapColour)->
				super(game, x, y, "anims")

				@mapColour	= mapColour || (Math.random() * (0xffffff + 1)) | 0

				game.add.existing(this)
				game.physics.arcade.enable(this)

				@anchor.set(0.5, 0.5)
				@body.setSize(@body.width / 2, @body.height / 2)

				# left and right arm projectile fire points
				@_muzzleLeft	= new Phaser.Point(-@body.width * 0.5,
					@body.height * -0.25)
				@_muzzleRight	= new Phaser.Point(-@body.width * 0.5,
					@body.height * 0.25)

				@fireVelocity	= new Phaser.Point()

				@_maxShield		=
				@_maxHealth		=
				@health				= 100

				@shield				= 0

				@_baseDamage	= 1

				@_modifierList	= []

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

			getDamageModifier:->
				if @_hasModifier(QuadDamageModifier)
					@_baseDamage * 4
				else
					@_baseDamage

			_hasModifier:(ModClass)->
				@_modifierList.some((i)->
					i.constructor == ModClass::constructor
				)

			gainHealth:(amount)->
				@health	= Math.min(@health + amount, @_maxHealth)

			loseHealth:(amount)->
				@health	= Math.max(@health - amount, 0)

			gainShield:(amount)->
				@shield	= Math.min(@shield + amount, @_maxShield)

			loseShield:(amount)->
				@shield	= Math.max(@shield - amount, 0)

			addModifier:(modifier)->
				@_modifierList.push(modifier)

			# reduces shield by amount argument and if shield is less then this value
			# then reduces health by the difference
			damage:(amount)->
				excess	= amount - @shield

				@loseShield(amount)
				@loseHealth(excess) if excess > 0

			update:->
				@bodyGroup.x		= @body.x + @body.width / 2
				@bodyGroup.y		= @body.y + @body.height / 2

				@healthDisplay.x	= @body.x
				@healthDisplay.y	= @body.y

				@healthDisplay.text	= "#{@health}+#{@shield}"

				# purge elasped modifiers
				for i in [@_modifierList.length - 1..0] by -1
					if @game.time.totalElapsedSeconds() >= @_modifierList[i].endTime
						@_modifierList.splice(i, 1)

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
