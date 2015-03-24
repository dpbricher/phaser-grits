define ["phaser", "easystar"],
  (Phaser, EasyStar)->
    class PathFinder
      constructor:(gridMap, acceptList = [0])->
        @_easyStar  = new EasyStar.js()

        # x and y offset to apply to lists of xy positions that get returned
        @_xyOffset  = new Phaser.Point()

        @_xyCall    = null

        @setGridMap(gridMap, acceptList) if gridMap?

      setGridMap:(@_gridMap, acceptList = [0])->
        @_easyStar.setGrid(@_gridMap.getGridTransposed())
        @_easyStar.setAcceptableTiles(acceptList)

      setXyOffset:(x, y)->
        @_xyOffset.set(x, y)

      findXy:(sX, sY, eX, eY, call)->
        @_xyCall  = call

        @findIj(@_gridMap.toIj(sX, sY)..., @_gridMap.toIj(eX, eY)...,
          @_onXyFound.bind(this))

      findIj:(sI, sJ, eI, eJ, call)->
        @_easyStar.findPath(sI, sJ, eI, eJ, call)
        @_easyStar.calculate()


      _onXyFound:(ijList)->
        if ijList?
          xyList  = (@_gridMap.toXy(x, y) for { x, y } in ijList)
          xyList  = ([x + @_xyOffset.x, y + @_xyOffset.y] for [x, y] in xyList)

          @_xyCall(xyList)
        else
          @_xyCall()
