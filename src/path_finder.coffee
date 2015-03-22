define ["easystar"],
  (EasyStar)->
    class PathFinder
      constructor:(gridMap, acceptList = [0])->
        @_easyStar  = new EasyStar.js()

        @_xyCall    = null

        @setGridMap(gridMap, acceptList) if gridMap?

      setGridMap:(@_gridMap, acceptList = [0])->
        @_easyStar.setGrid(@_gridMap.getGridTransposed())
        @_easyStar.setAcceptableTiles(acceptList)

      findXy:(sX, sY, eX, eY, call)->
        @_xyCall  = call

        @findIj(@_gridMap.toIj(sX, sY)..., @_gridMap.toIj(eX, eY)...,
          @_onXyFound.bind(this))

      findIj:(sI, sJ, eI, eJ, call)->
        @_easyStar.findPath(sI, sJ, eI, eJ, call)
        @_easyStar.calculate()


      _onXyFound:(ijList)->
        @_xyCall(@_gridMap.toXy(x, y) for { x, y } in ijList)
