define ["phaser"],
  (Phaser)->
    class PathFollower
      constructor:(@_player)->
        @_nextIndex = 0

      setPath:(@_pathList)->
        @_nextIndex = 0

      getMoveVec:()->
        vec = new Phaser.Point()

        if @hasNext()
          target  = @_getNextNode()

          if @_player.body.center.distance({ x:target[0], y:target[1] }) <
          @_player.body.width / 4
            ++@_nextIndex
          else
            dest  = new Phaser.Point(target...)

            vec   = dest
              .subtract(@_player.body.center.x, @_player.body.center.y)
              .normalize()

        vec

      hasNext:->
        @_nextIndex < @_pathList.length


      _getNextNode:->
        @_pathList[@_nextIndex]
