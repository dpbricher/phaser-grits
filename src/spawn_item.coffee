define ["phaser"],
	(Phaser)->
		class SpawnItem extends Phaser.Sprite
			@DEFAULT_MIN	= 15.0
			@DEFAULT_MAX	= 60.0

			#
			# collision function should take the following format:
			#
			# (collidingPlayer)->
			# 	[logic that affects the player]
			#
			constructor:(game, x, y, animName, animFramePrefix, @audio,
			@collisionFunction = (->), minTime = SpawnItem.DEFAULT_MIN,
			maxTime = SpawnItem.DEFAULT_MAX)->
				super(game, x, y, "anims")

				@game.physics.arcade.enable(this)

				@anchor.set(0.5, 0.5)
				@body.immovable		= true

				@lastCollectTime	= 0

				@visible					= false

				@animations.add(animName,
					Phaser.Animation.generateFrameNames(animFramePrefix, 0,
						15, ".png", 4), 25, true)
				@animations.play(animName)

				@setSpawnRange(minTime, maxTime)

			setSpawnRange:(@minTime, @maxTime = @minTime)->
				@setNextSpawnTime()

			setNextSpawnTime:->
				@nextSpawnTime	= @game.time.totalElapsedSeconds() + @minTime +
					(@maxTime - @minTime) * Math.random()

			update:->
				if @game.time.totalElapsedSeconds() >= @nextSpawnTime
					@nextSpawnTime	= Infinity
					@visible				= true

			onCollision:(player)->
				@collisionTime		= @game.time.totalElapsedSeconds()
				@visible					= false

				@audio.play()

				@collisionFunction(player)
				@setNextSpawnTime()
