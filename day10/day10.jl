#-----------------------------------------------------------------
# CODE

SPACE = 0
ASTEROID = 1
HIDDEN = 2

function parseMap(str)
  lines = split(str, '\n')
  height = length(lines)
  width = length(lines[1])
  result = zeros(Int, height, width)
  for r in 1:height
    for c in 1:width
      if lines[r][c] == '#'
        result[r,c] = ASTEROID
      end
    end
  end
  result
end

function listAsteroids(map)
  height = size(map, 1)
  width = size(map, 2)
  result = Tuple{Int,Int}[]
  for r in 1:height
    for c in 1:width
      if map[r,c] == ASTEROID
        push!(result, (r,c))
      end
    end
  end
  result
end

function countAsteroids(map)
  height = size(map, 1)
  width = size(map, 2)
  result = 0
  for r in 1:height
    for c in 1:width
      if map[r,c] == ASTEROID
        result += 1
      end
    end
  end
  result
end

function nextHidden((fromx, fromy), (tox,toy))
  if fromx == tox
    nextx = fromx
    nexty = if (toy > fromy) toy+1 else toy-1 end
    (nextx, nexty)
  elseif fromy == toy
    nextx = if (tox > fromx) tox+1 else tox-1 end
    nexty = fromy
    (nextx, nexty)
  elseif abs(fromx-tox) == abs(fromy - toy)
    nextx = if (tox > fromx) tox+1 else tox-1 end
    nexty = if (toy > fromy) toy+1 else toy-1 end
    (nextx, nexty)
  else
    deltax = tox - fromx
    deltay = toy - fromy
    step = gcd(deltax, deltay)
    nextx = tox + deltax÷step
    nexty = toy + deltay÷step
    (nextx, nexty)
  end
end

function hideAsteroids(map, (fromx, fromy), (tox,toy))
  height = size(map, 1)
  width = size(map, 2)
  (nextx,nexty) = nextHidden((fromx, fromy), (tox,toy))
  if (nextx <= height) && (nexty <= width) && (nextx > 0) && (nexty > 0)
    map[nextx,nexty] = HIDDEN
    hideAsteroids(map, (tox,toy), (nextx,nexty))    
  end
end

function hideAllAsteroids(map, station, asteroids)
  map = copy(map)
  for asteroid in asteroids
    if asteroid != station
      hideAsteroids(map, station, asteroid)
    end
  end
  map
end

function bestStation(map)
  asteroids = listAsteroids(map)
  station = (0,0)
  bestScore = 0
  for asteroid in asteroids
    hiddenMap = hideAllAsteroids(map, asteroid, asteroids)
    score = countAsteroids(hiddenMap) - 1 # minus himself
    if score > bestScore
      station = asteroid
      bestScore = score
    end
  end
  (station, bestScore)
end

function conv((y,x))
  (x-1, y-1)
end

function printMap(map, (x,y))
  height = size(map, 1)
  width = size(map, 2)
  for r in 1:height
    for c in 1:width
      if (r==x) && (c==y)
        print('o')
      elseif map[r,c] == ASTEROID
        print('#')
      elseif map[r,c] == HIDDEN
        print('+')
      else
        print('.')
      end
    end
    print('\n')
  end
end

#-----------------------------------------------------------------
# LASER 

function getAngle((stationx,stationy), (astrx,atry))
  -atan(atry - stationy, astrx - stationx)
end

function orderTargets(station, asteroids)
  sort(asteroids, by=a -> getAngle(station,a))
end

# updates the map map and the list of vaporised asteroids in order
function getVaporisedOneTurn(map ,station)
  asteroids = listAsteroids(map)
  hiddenMap = hideAllAsteroids(map, station, asteroids)
  vaporisedAsteroids = listAsteroids(hiddenMap)
  for (x,y) in vaporisedAsteroids
    map[x,y] = SPACE
  end
  orderTargets(station, vaporisedAsteroids)
end

function getVaporised(map, station)
  map = copy(map)
  newVaporised = getVaporisedOneTurn(map ,station)
  vaporised = newVaporised
  while length(newVaporised) > 0
    vaporised = vcat(vaporised, newVaporised)
    newVaporised = getVaporisedOneTurn(map ,station)
  end
  vaporised
end

function hashAsteroid(asteroid)
  (x,y) = conv(asteroid)
  100*x + y
end

#-----------------------------------------------------------------
# TEST

println("test0")
map0 = parseMap(".#..#
.....
#####
....#
...##")
(station0,score0) = bestStation(map0)
println("station: ", conv(station0), " score: ", score0)

println("test1")
map1 = parseMap("......#.#.
#..#.#....
..#######.
.#.#.###..
.#..#.....
..#....#.#
#..#....#.
.##.#..###
##...#..#.
.#....####")
(station1,score1) = bestStation(map1)
println("station: ", conv(station1), " score: ", score1)

println("test2")
map2 = parseMap("#.#...#.#.
.###....#.
.#....#...
##.#.#.#.#
....#.#.#.
.##..###.#
..#...##..
..##....##
......#...
.####.###.")
(station2,score2) = bestStation(map2)
println("station: ", conv(station2), " score: ", score2)

println("test3")
map3 = parseMap(".#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..")
(station3,score3) = bestStation(map3)
println("station: ", conv(station3), " score: ", score3)
#printMap(map3, station3)
#println("hidden:")
#printMap(hideAllAsteroids(map3, station3, listAsteroids(map3)), station3)

println("test4")
map4 = parseMap(".#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##")
(station4,score4) = bestStation(map4)
println("station: ", conv(station4), " score: ", score4)
vaporised4 = getVaporised(map4, station4)
println("200th vaporized: ", conv(vaporised4[201]))
#printMap(map4, station4)
#println("hidden:")
#printMap(hideAllAsteroids(map4, station4, listAsteroids(map4)), station4)

println("test02")
map0 = parseMap("#.........
...#......
...#..#...
.####....#
..#.#.#...
.....#....
..###.#.##
.......#..
....#...#.
...#..#..#")
station0 = (1,1)
#printMap(map0, station0)
#println("hidden:")
#printMap(hideAllAsteroids(map0, station0, listAsteroids(map0)), station0)

println("test5")
map5 = parseMap(".#....#####...#..
##...##.#####..##
##...#...#.#####.
..#.....#...###..
..#.#.....#....##")
station5 = (4, 9)
vaporised5 = getVaporised(map5, station5)
#println("vaporized: ", vaporised5)

#-----------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
mapP = parseMap(inputStr)
(station,score) = bestStation(mapP)
println("station: ", conv(station), " score: ", score)

vaporised = getVaporised(mapP, station)
println("200th vaporized: ", conv(vaporised[201]), " (", hashAsteroid(vaporised[201]), ")")
