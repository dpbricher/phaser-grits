#
# Class for creating and working with a grid representation of the game map
# The grid is represented as a two-dimensional column-major array
#
define ["phaser"],
  (Phaser)->
    class GridMapper
      constructor:(gridX, gridY, @_area, @_obstacleList...)->
        # if total area is not an exact multiple of grid width and height then
        # round down to nearest multiple
        @_area.width      -= @_area.width % gridX
        @_area.height     -= @_area.height % gridY

        @_cellDim         = new Phaser.Point(gridX, gridY)

        # create cellX by cellY two dimensional array:
        @_gridList        = null

        # also create transposed version of this array
        @_gridTransposed  = null

        # list of i j indexes of cells that are passable
        @_passableList    = null

        # enum constants for grid
        @EMPTY      = 0
        @BLOCKED    = 1

        @_parseMap()
        @_parseTransposed()
        @_parsePassables()

      getGridList:->
        @_gridList[..]

      getGridTransposed:->
        @_gridTransposed[..]

      getPassable:->
        @_passableList[..]

      getCellDim:->
        @_cellDim.clone()

      #
      # finds all grid spaces that are covered by the supplied area
      # rectangle(s) and changes their value to newValue
      #
      setAreasTo:(rectList..., newValue)->
        cellRect  = new Phaser.Rectangle(0, 0, @_cellDim.x, @_cellDim.y)

        for areaRect in rectList
          for col, i in @_gridList
            for value, j in col
              [cellRect.x, cellRect.y]  = @toXy(i, j)

              col[j]  = newValue if areaRect.intersects(cellRect)

        @_parseTransposed()

        # now have to re-evaluate which areas are passable
        @_parsePassables()

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


      _parseMap:->
        cellArea    = new Phaser.Rectangle(0, 0, @_cellDim.x, @_cellDim.y)
        obArea      = new Phaser.Rectangle()

        @_gridList  = ([] for x in [0...@_area.width / @_cellDim.x])

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

            @_gridList[i][j]        = cellValue

      _parseTransposed:->
          @_gridTransposed  = ([] for i in [0...@_gridList[0].length])

          for col, i in @_gridList
            for cell, j in col
              @_gridTransposed[j][i]  = cell

      _parsePassables:->
        @_passableList  = []

        for col, i in @_gridList
          for cell, j in col
            @_passableList.push([i, j]) if cell == @EMPTY
