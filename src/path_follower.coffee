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
          target  = @_getNextNode()

          if @_player.body.position.distance({ x:target[0], y:target[1] }) <
          @_player.body.width / 4
            ++@_nextIndex
          else
            dest  = new Phaser.Point(target...)

            vec   = dest
              .subtract(@_player.body.position.x, @_player.body.position.y)
              .normalize()

        vec


      _getNextNode:->
        @_pathList[@_nextIndex]
