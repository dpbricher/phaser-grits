define ["phaser"],
  (Phaser)->
    class MiniMap extends Phaser.Graphics
      constructor:(game, x, y, @mapWidth, @mapHeight, @_mapAlpha = 0.5)->
        super(game, x, y)

        @scaleF  = new Phaser.Point(
          @mapWidth / game.world.width,
          @mapHeight / game.world.height
        )

        game.add.existing(this)

        @beginFill(0xff)
        .drawRect(0, 0, @mapWidth, @mapHeight)
        .endFill()

      redraw:(playerList...)->
        @clear()

        @beginFill(0xffffff, @_mapAlpha)
        .drawRect(0, 0, @mapWidth, @mapHeight)
        .endFill()

        @beginFill(0xff, @_mapAlpha)
        for p in playerList
          pos = p.body.center.clone().multiply(@scaleF.x, @scaleF.y)
          @drawCircle(pos.x, pos.y, 4)
        @endFill()
