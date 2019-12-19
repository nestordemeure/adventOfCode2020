#---------------------------------------------------------------------------------------
# MAP

WALL = '#'
SPACE = '.'
YOU = '@'

YOU1 = '1'
YOU2 = '2'
YOU3 = '3'
YOU4 = '4'

function isYou(c)
  (c == YOU) || (c == YOU1) || (c == YOU2) || (c == YOU3) || (c == YOU4)
end

# is c a key ?
function isKey(c)
  (c != SPACE) && (c != WALL) && (islowercase(c) || isYou(c))
end

# is c a door ?
function isDoor(c)
  (c != SPACE) && (c != WALL) && (!isYou(c)) && isuppercase(c)
end

# is c walkable ? (doors are considered walkable)
function isWalkable(c)
  c != WALL
end

# returns the distance between the two positions plus a list of doors that needs to be unlocked
function distanceto(caveMap,(h1,w1),(h2,w2))
  currentPositions = Vector()
  push!(currentPositions, (h1, w1, 0, Vector()))
  costMap = fill(typemax(Int), (size(caveMap,1), size(caveMap,2)))
  doorsMap = fill(Vector(), (size(caveMap,1), size(caveMap,2)))
  targetReached = false
  while (!isempty(currentPositions)) && (!targetReached)
    newPositions = Vector()
    for (h,w,steps,doors) in currentPositions
      c = caveMap[h,w]
      previoussteps = costMap[h,w]
      if isDoor(c)
        doors = copy(doors)
        push!(doors, lowercase(c))
      end
      if isWalkable(c) && (steps < previoussteps)
        costMap[h,w] = steps
        doorsMap[h,w] = doors
        push!(newPositions, (h+1,w,steps+1,doors))
        push!(newPositions, (h-1,w,steps+1,doors))
        push!(newPositions, (h,w+1,steps+1,doors))
        push!(newPositions, (h,w-1,steps+1,doors))
      end
      if (h,w) == (h2,w2)
        targetReached = true
      end
    end
    currentPositions = newPositions
  end
  if targetReached
    (costMap[h2,w2], doorsMap[h2,w2])
  else
    nothing
  end
end

# produce a dictionnary of key->position
function locateKeys(caveMap)
  keyPositions = Dict()
  height = size(caveMap,1)
  width = size(caveMap,2)
  for h in 1:height
    for w in 1:width
      c = caveMap[h,w]
      if isKey(c)
        keyPositions[c] = (h,w)
      end
    end
  end
  keyPositions
end

function makeDistanceMatrix(caveMap, keyPositions)
  distanceMatrix = Dict()
  for (key1, position1) in keyPositions
    for (key2, position2) in keyPositions
      if key1 == key2
        distanceMatrix[(key1,key2)] = (0,Vector())
      elseif haskey(distanceMatrix,(key2,key1))
        distanceMatrix[(key1,key2)] = distanceMatrix[(key2,key1)]
      else
        distanceMatrix[(key1,key2)] = distanceto(caveMap,position1,position2)
      end
    end
  end
  distanceMatrix
end

# produces a map and a dictionary of the key->position
function parseMap(str)
  lines = filter(l -> !isempty(l), split(str, '\n'))
  height = length(lines)
  width = length(lines[1])
  cavemap = Array{Char,2}(undef, height, width)
  for h in 1:height, w in 1:width
    cavemap[h,w] = lines[h][w]
  end
  cavemap
end

function printMap(caveMap)
  height = size(caveMap,1)
  width = size(caveMap,2)
  for h in 1:height
    for w in 1:width
      print(caveMap[h,w])
    end
    print('\n')
  end
  print('\n')
end

#---------------------------------------------------------------------------------------
# PART1

function getReachableKeys(distanceMatrix, currentKey, keysLeft, allKeysLeft=keysLeft)
  reachableKeys = Vector()
  for key in keysLeft
    (distance, doors) = distanceMatrix[currentKey,key]
    if isempty(intersect(doors,allKeysLeft))
      push!(reachableKeys, (key,distance))
    end
  end
  reachableKeys
end

function findMin(distanceMatrix, currentKey, nodesLeft, cache)
  if haskey(cache, (currentKey, nodesLeft))
    return cache[currentKey, nodesLeft]
  elseif isempty(nodesLeft)
    cache[currentKey, nodesLeft] = 0
    return 0
  else
    bestScore = typemax(Int)
    for (key,distance) in getReachableKeys(distanceMatrix,currentKey,nodesLeft)
      distance = distance + findMin(distanceMatrix, key, setdiff(nodesLeft,[key]), cache)
      if distance < bestScore
        bestScore = distance
      end
    end
    cache[currentKey, nodesLeft] = bestScore
    bestScore
  end
end

function unlockMap(distanceMatrix, keys)
  nodesLeft = setdiff(Set(keys), YOU)
  cache = Dict()
  findMin(distanceMatrix, YOU, nodesLeft, cache)
end

#---------------------------------------------------------------------------------------
# PART2

# returns the location of a given char in the map
function locateChar(caveMap, target)
  height = size(caveMap,1)
  width = size(caveMap,2)
  for h in 1:height, w in 1:width
    if caveMap[h,w] == target
      return (h,w)
    end
  end
  throw("char was not in map!")
end

# split a map around YOU
function splitMap(caveMap)
  (hYou,wYou) = locateChar(caveMap, YOU)
  caveMap = copy(caveMap)
  caveMap[hYou,wYou] = WALL
  caveMap[hYou+1,wYou] = WALL
  caveMap[hYou-1,wYou] = WALL
  caveMap[hYou,wYou+1] = WALL
  caveMap[hYou,wYou-1] = WALL
  caveMap[hYou+1,wYou+1] = YOU1
  caveMap[hYou+1,wYou-1] = YOU2
  caveMap[hYou-1,wYou+1] = YOU3
  caveMap[hYou-1,wYou-1] = YOU4
  caveMap
end

function enumerateReachableKeys(distanceMatrix, existingKeys, startingKey)
  result = Set()
  for key in existingKeys
    if (key != startingKey) && !isnothing(distanceMatrix[key,startingKey])
      union!(result, key)
    end
  end
  result
end

function makeId(currentKeys, keysLeft)
  defaultKey = [YOU1,YOU2,YOU3,YOU4]
  current = Set()
  done = Set()
  for i in 1:length(currentKeys)
    if isempty(keysLeft[i])
      union!(current, defaultKey[i])
    else
      union!(current, currentKeys[i])
      union!(done, keysLeft[i])
    end
  end
  (current, done)
end

function findMinSplit(distanceMatrix, currentKeys, keysLeft, cache)
  (_,allKeysLeft) = id = makeId(currentKeys, keysLeft)
  # potential shortcuts
  if haskey(cache, id)
    return cache[id]
  elseif isempty(allKeysLeft)
    cache[id] = 0
    return 0
  end
  # enumerate all possible branch and recurse
  minSteps = typemax(Int)
  for i in 1:length(currentKeys)
    newCurrentKeys = copy(currentKeys)
    newKeysLeft = deepcopy(keysLeft)
    for (key,dist) in getReachableKeys(distanceMatrix,currentKeys[i],keysLeft[i],allKeysLeft)
      newCurrentKeys[i] = key
      newKeysLeft[i] = setdiff(keysLeft[i], key)
      steps = dist + findMinSplit(distanceMatrix, newCurrentKeys, newKeysLeft, cache)
      if steps < minSteps
        minSteps = steps
      end
    end
  end
  # memorize result
  cache[id] = minSteps
  minSteps
end

function unlockSplitMap(caveMap)
  caveMap = splitMap(caveMap)
  keysPosition = locateKeys(caveMap)
  distanceMatrix = makeDistanceMatrix(caveMap, keysPosition)
  startingKeys = [YOU1,YOU2,YOU3,YOU4]
  keysLeft = map(k -> enumerateReachableKeys(distanceMatrix, keys(keysPosition), k), startingKeys)
  cache = Dict()
  findMinSplit(distanceMatrix, startingKeys, keysLeft, cache)
end

#---------------------------------------------------------------------------------------
# TEST1

println("test 1")
map1 = parseMap("#########
#b.A.@.a#
#########")
keys1 = locateKeys(map1)
dist1 = makeDistanceMatrix(map1, keys1)
score1 = unlockMap(dist1,keys(keys1))
println("cost: ", score1, " == 8")

println("test 2")
map2 = parseMap("########################
#f.D.E.e.C.b.A.@.a.B.c.#
######################.#
#d.....................#
########################")
keys2 = locateKeys(map2)
dist2 = makeDistanceMatrix(map2, keys2)
score2 = unlockMap(dist2,keys(keys2))
println("cost: ", score2, " == 86")

println("test 3")
map3 = parseMap("########################
#...............b.C.D.f#
#.######################
#.....@.a.B.c.d.A.e.F.g#
########################")
keys3 = locateKeys(map3)
dist3 = makeDistanceMatrix(map3, keys3)
score3 = unlockMap(dist3,keys(keys3))
println("cost: ", score3, " == 132")

println("test 5")
map5 = parseMap("########################
#@..............ac.GI.b#
###d#e#f################
###A#B#C################
###g#h#i################
########################")
keys5 = locateKeys(map5)
dist5 = makeDistanceMatrix(map5, keys5)
score5 = unlockMap(dist5,keys(keys5))
println("cost: ", score5, " == 81")

println("test 4")
map4 = parseMap("#################
#i.G..c...e..H.p#
########.########
#j.A..b...f..D.o#
########@########
#k.E..a...g..B.n#
########.########
#l.F..d...h..C.m#
#################")
keys4 = locateKeys(map4)
dist4 = makeDistanceMatrix(map4, keys4)
score4 = unlockMap(dist4,keys(keys4))
println("cost: ", score4, " == 136")

#---------------------------------------------------------------------------------------
# TEST2

println("test 6")
map6 = parseMap("#######
#a.#Cd#
##...##
##.@.##
##...##
#cB#Ab#
#######")
score6 = unlockSplitMap(map6)
println("cost: ", score6, " == 8 ")

println("test 7")
map7 = parseMap("###############
#d.ABC.#.....a#
######...######
######.@.######
######...######
#b.....#.....c#
###############")
score7 = unlockSplitMap(map7)
println("cost: ", score7, " == 24 ")

println("test 8")
map8 = parseMap("#############
#DcBa.#.GhKl#
#.###...#I###
#e#d#.@.#j#k#
###C#...###J#
#fEbA.#.FgHi#
#############")
score8 = unlockSplitMap(map8)
println("cost: ", score8, " == 32 ")

println("test 9")
map9 = parseMap("#############
#g#f.D#..h#l#
#F###e#E###.#
#dCba...BcIJ#
#####.@.#####
#nK.L...G...#
#M###N#H###.#
#o#m..#i#jk.#
#############")
score9 = unlockSplitMap(map9)
println("cost: ", score9, " == 72 ")

#--------------------------------------------------------------------------------------------------
# PROBLEM

inputStr = read("./day18/input.txt", String)
caveMap = parseMap(inputStr)

println("problem 1")
keyPositions = locateKeys(caveMap)
distanceMatrix = makeDistanceMatrix(caveMap, keyPositions)
score = unlockMap(distanceMatrix,keys(keyPositions))
println("cost: ", score) # 3962

println("problem 2")
score = unlockSplitMap(caveMap)
println("cost: ", score)
