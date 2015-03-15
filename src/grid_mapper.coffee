#
# Class for creating and working with a grid representation of the game map
# The grid is represented as a two-dimensional column-major array
#
define ["phaser"],
  (Phaser)->
    class GridMapper
      constructor:(gridX, gridY, @_area, @_obstacleList...)->
        if @_area.width % gridX || @_area.height % gridY
          throw new Error("@_area width/height must be multiples of gridX/Y")

        @_cellDim         = new Phaser.Point(gridX, gridY)

        # create cellX by cellY two dimensional array:
        @_gridList        = ([] for x in [0...@_area.width / @_cellDim.x])

        # also create transposed version of this array
        @_gridTransposed  = ([] for y in [0...@_area.height / @_cellDim.y])

        # enum constants for grid
        @EMPTY      = 0
        @BLOCKED    = 1

        @_parseMap()

      getGridList:->
        @_gridList[..]

      getGridTransposed:->
        @_gridTransposed[..]

      #
      # convert xy coordinates to ij grid list indexes
      #
      toIj:(x, y)->
        [((x - @_area.x) / @_cellDim.x) | 0,
          ((y - @_area.y) / @_cellDim.y) | 0]

      #
      # convert ij indexes to xy coordinates
      #
      toXy:(i, j)->
        [@_area.x + i * @_cellDim.x, @_area.y + j * @_cellDim.y]

      _parseMap:()->
        cellArea  = new Phaser.Rectangle(0, 0, @_cellDim.x, @_cellDim.y)
        obArea    = new Phaser.Rectangle()

        for i in [0...@_area.width / @_cellDim.x]
          for j in [0...@_area.height / @_cellDim.y]
            [cellArea.x, cellArea.y]  = @toXy(i, j)

            cellValue   = @EMPTY

            for group in @_obstacleList
              for sprite in group.children
                obArea.setTo(sprite.body.x, sprite.body.y, sprite.body.width,
                  sprite.body.height)

                if cellArea.intersects(obArea)
                  cellValue = @BLOCKED
                  break

            @_gridTransposed[j][i]  =
            @_gridList[i][j]        = cellValue
