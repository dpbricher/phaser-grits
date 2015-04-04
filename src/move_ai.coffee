define ["grid_mapper", "path_finder", "path_follower"],
  (GridMapper, PathFinder, Follower)->
    class MoveAi
      constructor:(@_player, areaRect, obstacleList...)->
        @_gridMap     = new GridMapper(@_player.body.width,
          @_player.body.height, areaRect, obstacleList...)

        @_follower    = new Follower(@_player)

        @_pathFinder  = new PathFinder(@_gridMap)

      seekRandomCell:->
        randList  = @_gridMap.getPassable()
        randDest  = @_gridMap.toXy(
          randList[randList.length * Math.random() | 0]...
        )
        @seekPos(randDest...)

      seekPos:(x, y)->
        @_pathFinder.findXy(@_player.body.x, @_player.body.y, x, y,
          (r)=>@_onSeekDone(r))

      update:->
        if @_follower.hasNext()
          newVel  = @_follower.getMoveVec()

          @_player.body.velocity
          .set(newVel.x, newVel.y)
          .multiply(@_player.moveSpeed, @_player.moveSpeed)
        else
          @seekRandomCell()

      getGridMap:->
        @_gridMap


      _onSeekDone:(results)->
          if results?
            @_follower.setPath(results)
