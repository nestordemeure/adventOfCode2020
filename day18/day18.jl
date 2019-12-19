#import Pkg; Pkg.add("DataStructures")
using DataStructures

#---------------------------------------------------------------------------------------
# MAP

WALL = '#'
SPACE = '.'
YOU = '@'

# is c a key ?
function isKey(c)
  (c != SPACE) && (c != WALL) && (islowercase(c) || (c == YOU))
end

# is c a door ?
function isDoor(c)
  (c != SPACE) && (c != WALL) && (c != YOU) && isuppercase(c)
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
  (costMap[h2,w2], doorsMap[h2,w2])
end

function makeDistanceMatrix(caveMap, keys)
  distanceMatrix = Dict()
  for (key1, position1) in keys 
    for (key2, position2) in keys
      if key1 == key2
        distanceMatrix[(key1,key2)] = (0,Vector())
      elseif haskey(distanceMatrix,(key2,key1))
        distanceMatrix[(key1,key2)] = distanceMatrix[(key2,key1)]
      else
        (steps, doors) = distanceto(caveMap,position1,position2)
        distanceMatrix[(key1,key2)] = (steps, doors)
      end
    end
  end
  distanceMatrix
end

# produces a map and a dictionary of the key->position
function parseMap(str)
  lines = split(str, '\n')
  height = length(lines)
  width = length(lines[1])
  cavemap = Array{Char,2}(undef, height, width)
  keyPositions = Dict()
  for h in 1:height
    for w in 1:width
      c = lines[h][w]
      cavemap[h,w] = c
      if isKey(c) 
        keyPositions[c] = (h,w)
      end
    end
  end
  (makeDistanceMatrix(cavemap, keyPositions), keys(keyPositions))
end

#---------------------------------------------------------------------------------------
# A*

struct Node 
  key::Char 
  keysDone
  keysLeft
  distance
end

# optimistic heuristic used by A*
function minimumDistanceLeft(distanceMatrix,node)
  doorsDone = copy(node.keysDone)
  keysDone = Set(node.key)
  keysLeft = copy(node.keysLeft)
  totalDistance = 0
  while !isempty(keysLeft)
    bestTarget = nothing
    bestDistance = typemax(Int)
    for key1 in keysDone
      for key2 in keysLeft
        (distance,doors) = distanceMatrix[(key1,key2)]
        if (distance < bestDistance) && (doors ⊆ doorsDone)
          bestDistance = distance
          bestTarget = key2
        end
      end
    end
    if isnothing(bestTarget)
      throw("unable to go forward!")
    end
    totalDistance += bestDistance
    delete!(keysLeft, bestTarget)
    push!(keysDone, bestTarget)
    push!(doorsDone, bestTarget)
  end
  totalDistance
end

function getReachableNodes(distanceMatrix,node)
  nodes = Vector()
  for key in node.keysLeft
    (distance, doors) = distanceMatrix[(node.key,key)]
    if doors ⊆ node.keysDone
      keysDone = union(node.keysDone, [key])
      keysLeft = setdiff(node.keysLeft, [key])
      distance = node.distance + distance
      child = Node(key, keysDone, keysLeft, distance)
      push!(nodes, child)
    end
  end
  nodes
end

#---------------------------------------------------------------------------------------

# A*
function unlockMap_old(distanceMatrix, keys, shouldPrint=false)
  initialNode = Node(YOU, Set(YOU), setdiff(keys, [YOU]), 0)
  nodes = PriorityQueue(initialNode => (0,0))
  while true 
    (node, (minDistance,_))  = dequeue_pair!(nodes)
    
    if false# shouldPrint
      println("pq size:", length(nodes), " key:", node.key, " distance:", node.distance, " minDistance:", minDistance, " left:", length(node.keysLeft))
    end
    
    if isempty(node.keysLeft)
      return node.distance
    else 
      for child in getReachableNodes(distanceMatrix,node)
        score = child.distance + minimumDistanceLeft(distanceMatrix,child)
        nodes[child] = (score, length(child.keysLeft)) # child.distance)
      end
    end
  end
end

# deep first
function unlockMap_old2(distanceMatrix, keys, shouldPrint=false)
  initialNode = Node(YOU, Set(YOU), setdiff(keys, [YOU]), 0)
  nodes = PriorityQueue(initialNode => (0,0))

  bestNode = nothing 
  bestDist = typemax(Int)

  while !isempty(nodes) 
    (node,(_,score))  = dequeue_pair!(nodes)
    
    if false#shouldPrint
      println("pq size:", length(nodes), " key:", node.key, " distance:", node.distance, " minDistance:", node.distance+minimumDistanceLeft(distanceMatrix,node), " left:", length(node.keysLeft))
    end
    
    if score < bestDist
      if isempty(node.keysLeft)
        println("found: ", node.distance)
        bestDist = node.distance
        bestNode = node
      else
        for child in getReachableNodes(distanceMatrix,node)
          scoreChild = child.distance + minimumDistanceLeft(distanceMatrix,child)
          nodes[child] = (length(child.keysLeft), scoreChild)
        end
      end
    end
  end

  bestDist
end

#---------------------------------------------------------------------------------------

struct Node2
  key::Char 
  keysDone
  keysLeft
end

function getReachableNodes2(distanceMatrix,node,nodeDistance)
  nodes = Vector()
  for key in node.keysLeft
    (distance, doors) = distanceMatrix[(node.key,key)]
    if doors ⊆ node.keysDone
      keysDone = union(node.keysDone, [key])
      keysLeft = setdiff(node.keysLeft, [key])
      distance = nodeDistance + distance
      child = Node2(key, keysDone, keysLeft)
      push!(nodes, (child,distance))
    end
  end
  nodes
end

function unlockMap_old(distanceMatrix, keys, shouldPrint=false)
  initialNode = Node2(YOU, Set(YOU), setdiff(Set(keys), [YOU]))
  nodes = PriorityQueue(initialNode => 0)
  while true 
    (node, distance)  = dequeue_pair!(nodes)
    if isempty(node.keysLeft)
      return distance
    else 
      for (child,dist) in getReachableNodes2(distanceMatrix,node,distance)
        if (!haskey(nodes, child)) || (nodes[child] > dist)
          nodes[child] = dist
        end
      end
    end
  end
end

#---------------------------------------------------------------------------------------

function getReachableKeys(distanceMatrix,startKey,nodesLeft)
  nodes = Vector()
  for key in nodesLeft
    (distance, doors) = distanceMatrix[(startKey,key)]
    if isempty(intersect(doors,nodesLeft))
      push!(nodes, (key,distance))
    end
  end
  nodes
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

function unlockMap(distanceMatrix, keys, shouldPrint=false)
  nodesLeft = setdiff(Set(keys), YOU)
  cache = Dict()
  findMin(distanceMatrix, YOU, nodesLeft, cache)
end

#---------------------------------------------------------------------------------------
# TEST

println("test 1")
(map1,keys1) = parseMap("#########
#b.A.@.a#
#########")
score1 = unlockMap(map1,keys1)
println("cost: ", score1, " == 8")

println("test 2")
(map2,keys2) = parseMap("########################
#f.D.E.e.C.b.A.@.a.B.c.#
######################.#
#d.....................#
########################")
score2 = unlockMap(map2,keys2)
println("cost: ", score2, " == 86")

println("test 3")
(map3,keys3) = parseMap("########################
#...............b.C.D.f#
#.######################
#.....@.a.B.c.d.A.e.F.g#
########################")
score3 = unlockMap(map3,keys3)
println("cost: ", score3, " == 132")

println("test 5")
(map5,keys5) = parseMap("########################
#@..............ac.GI.b#
###d#e#f################
###A#B#C################
###g#h#i################
########################")
score5 = unlockMap(map5,keys5)
println("cost: ", score5, " == 81")

println("test 4")
(map4,keys4) = parseMap("#################
#i.G..c...e..H.p#
########.########
#j.A..b...f..D.o#
########@########
#k.E..a...g..B.n#
########.########
#l.F..d...h..C.m#
#################")
score4 = unlockMap(map4,keys4,true)
println("cost: ", score4, " == 136")

#--------------------------------------------------------------------------------------------------
# PROBLEM

println("import problem")
inputStr = read("input.txt", String)
(cavemap,keysProb) = parseMap(inputStr)

println("problem 1")
score = unlockMap(cavemap,keysProb)
println("cost: ", score)

