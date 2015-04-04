define ["phaser"],
  (Phaser)->
    class PathDrawer extends Phaser.Graphics
      drawPathXy:(pathList, radius = 5, colour = 0xff0000)->
        @clear()

        @beginFill(colour, 0.5)

        for [x, y] in pathList
          @drawCircle(x, y, radius)

        @endFill()
