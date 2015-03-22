define ["phaser"],
  (Phaser)->
    class PathFollower
      constructor:(@_player)->
        @_nextIndex = 0

      setPath:(@_pathList)->
        @_nextIndex = 0

      getMoveVec:()->
        vec = new Phaser.Point()

        if @_nextIndex < @_pathList.length
          t = @_getNextNode()

          if @_player.body.position.distance({ x:t[0], y:t[1] }) <
          @_player.body.width / 4
            ++@_nextIndex
          else
        # if @_nextIndex < @_pathList.length
            dest  = new Phaser.Point(@_getNextNode()...)


            vec   = dest
              .subtract(@_player.body.position.x, @_player.body.position.y)
              .normalize()

        vec


      _getNextNode:->
        @_pathList[@_nextIndex]
