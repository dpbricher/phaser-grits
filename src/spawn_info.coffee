define [],
  ->
    class SpawnInfo
      constructor:(@player, @spawnTime, @spawnX, @spawnY, @health = 100,
        @shield = 0)->
