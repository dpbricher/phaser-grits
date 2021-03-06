define ["grid_mapper", "path_finder", "path_follower", "path_drawer"],
  (GridMapper, PathFinder, Follower, PathDrawer)->
    class MoveAi
      constructor:(@_player, areaRect, obstacleList...)->
        @_gridMap     = new GridMapper(@_player.body.width,
          @_player.body.height, areaRect, obstacleList...)

        @_follower    = new Follower(@_player)

        @_pathFinder  = new PathFinder(@_gridMap)
        @_pathFinder.setXyOffset(@_player.body.width / 2,
          @_player.body.height / 2)

        @_debugDraw   = new PathDrawer(@_player.game, 0, 0)
        @_player.game.add.existing(@_debugDraw)

      seekRandomCell:->
        randList  = @_gridMap.getPassable()
        randDest  = @_gridMap.toXy(
          randList[randList.length * Math.random() | 0]...
        )
        @seekPos(randDest...)

      seekPos:(x, y)->
        @_pathFinder.findXy(@_player.body.center.x, @_player.body.center.y, x,
          y, (r)=>@_onSeekDone(r))

      stop:->
        @_follower.setPath([])

      update:->
        if @_follower.hasNext()
          newVel  = @_follower.getMoveVec()

          @_player.body.velocity
          .set(newVel.x, newVel.y)
          .multiply(@_player.moveSpeed, @_player.moveSpeed)
        else
          @seekRandomCell()

      setGridAreasTo:(rectList..., newValue)->
        @_gridMap.setAreasTo(rectList..., newValue)


      _onSeekDone:(results)->
          if results?
            @_follower.setPath(results)

            @_debugDraw.drawPathXy(results, @_player.body.width)
