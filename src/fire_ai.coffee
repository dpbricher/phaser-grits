define ["phaser"],
  (Phaser)->
    class FireAi
      constructor:(@_player, @maxRange = @_player.body.width * 10,
      @clampAngle = Math.PI / 4)->

      getFireVec:(target)->
        vec     = new Phaser.Point()

        centre  = @_player.body.center.clone()

        if centre.distance(target) <= @maxRange
          angle   = centre.angle(target)

          # snap to closest clamp angle increment
          angle   += if angle > 0 then @clampAngle / 2 else -@clampAngle / 2
          angle   -= angle % @clampAngle

          vec     = new Phaser.Point(1, 0).rotate(0, 0, angle)

        vec
