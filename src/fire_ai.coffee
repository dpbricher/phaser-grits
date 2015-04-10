define ["phaser"],
  (Phaser)->
    class FireAi
      constructor:(@_player, @searchFunc, @clampAngle = Math.PI / 4)->

      getFireVec:(targetPoint)->
        vec     = new Phaser.Point()

        centre  = @_player.body.center.clone()

        if @searchFunc(@_player, targetPoint)
          angle   = centre.angle(targetPoint)

          # snap to closest clamp angle increment
          angle   += if angle > 0 then @clampAngle / 2 else -@clampAngle / 2
          angle   -= angle % @clampAngle

          vec     = new Phaser.Point(1, 0).rotate(0, 0, angle)

        vec


      @makeRectSearch:(rect)->
        rect  = rect.clone()

        (player, targetPoint)->
          centre  = player.body.center

          rect.centerOn(centre.x, centre.y)
          rect.contains(targetPoint.x, targetPoint.y)
