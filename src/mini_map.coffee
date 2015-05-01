define ["phaser"],
  (Phaser)->
    # class MiniMap extends Phaser.Graphics
    class MiniMap extends Phaser.Group
      constructor:(game, x, y, @mapWidth, @mapHeight, @bgColour = 0xffffff,
      @wallColour = 0x0, @holeColour = 0x666666)->
        super(game)

        [@x, @y]    = [x, y]

        @_bgLayer   = new Phaser.Graphics(game, 0, 0)
        @_wallLayer = new Phaser.Graphics(game, 0, 0)
        @_posLayer  = new Phaser.Graphics(game, 0, 0)

        @_bgLayer
        .beginFill(@bgColour)
        .drawRect(0, 0, @mapWidth, @mapHeight)
        .endFill()

        @scaleF  = new Phaser.Point(
          @mapWidth / game.world.width,
          @mapHeight / game.world.height
        )

        @add(obj) for obj in [@_bgLayer, @_wallLayer, @_posLayer]

        game.add.existing(this)

      addWall:(obj)->
        @addObstacle(obj, @wallColour)

      addHole:(obj)->
        @addObstacle(obj, @holeColour)

      addObstacle:(obj, colour)->
        b = obj.body
        @_wallLayer.beginFill(colour)
        .drawRect(b.x * @scaleF.x, b.y * @scaleF.y, b.width * @scaleF.x,
          b.height * @scaleF.y)
        .endFill()

      redraw:(playerList...)->
        @_posLayer.clear()

        for p in playerList
          pos     = p.body.center.clone().multiply(@scaleF.x, @scaleF.y)
          colour  = p.mapColour || 0x0

          @_posLayer
          .beginFill(colour)
          .drawCircle(pos.x, pos.y, 4)
          .endFill()
