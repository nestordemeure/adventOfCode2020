
#--------------------------------------------------
# MAP

struct Portal
  name # pair of letter identifying the portal
  destination # coordinates of the other portal
  level # goes up or down one level
end

const WALL = '#'
const SPACE = '.'

# produces a map of the labyrinth
function parseMap(str)
  lines = filter(l -> !isempty(l), split(str, '\n'))
  height = length(lines)
  width = length(lines[1])
  labyrinth = Array{Any,2}(undef, height, width)
  for h in 1:height, w in 1:width
    labyrinth[h,w] = lines[h][w]
  end
  labyrinth
end

# takes a portal position and returns the corresponding number of level up/down
function levelOfPosition(labyrinth, (h,w))
  height = size(labyrinth,1)
  width = size(labyrinth,2)
  if (h == 3) || (w == 3) || (h+2 == height) || (w+2 == width)
    # outer level 
    -1
  else 
    # inner level 
    +1
  end
end

# adds a pair of portal if we have the needed information
# or store the name and position of the portal
# while waiting for the second part of the pair being found
function addPortal(labyrinth, portals, name, position)
  # normalize name
  (c1,c2) = name
  name = min(c1,c2), max(c1,c2)
  # do we know the other end of this portal ?
  if haskey(portals, name)
    (h,w) = position
    destination = (dh,dw) = portals[name]
    labyrinth[h,w] = Portal(name,destination,levelOfPosition(labyrinth,position))
    labyrinth[dh,dw] = Portal(name,position,levelOfPosition(labyrinth,destination))
  else 
    portals[name] = position
  end
end

# is a char a raw portal (raw meaning not yet parsed properly)
function isRawPortal(c)
  !(c isa Portal) && isuppercase(c)
end

# takes a labyrinth and places proper portals in front of the letters
function parsePortals(labyrinth)
  height = size(labyrinth,1)
  width = size(labyrinth,2)
  portals = Dict()
  for h in 2:(height-1),w in 2:(width-1)
    c = labyrinth[h,w]
    if isRawPortal(c)
      ctop = labyrinth[h+1,w]
      cbottom = labyrinth[h-1,w]
      cright = labyrinth[h,w+1]
      cleft = labyrinth[h,w-1]
      if isRawPortal(ctop) && (cbottom == SPACE)
        addPortal(labyrinth, portals, (c,ctop), (h-1,w))
      elseif isRawPortal(cbottom) && (ctop == SPACE)
        addPortal(labyrinth, portals, (c,cbottom), (h+1,w))
      elseif isRawPortal(cright) && (cleft == SPACE)
        addPortal(labyrinth, portals, (c,cright), (h,w-1))
      elseif isRawPortal(cleft) && (cright == SPACE)
        addPortal(labyrinth, portals, (c,cleft), (h,w+1))
      end
    end
  end
  startingPoint = portals['A','A']
  endPoint = portals['Z','Z']
  (labyrinth, startingPoint, endPoint)
end

# is a tile walkable
function iswalkable(c)
  (c == SPACE) || (c isa Portal)
end

# displays the map on screen
function printMap(labyrinth)
  height = size(labyrinth,1)
  width = size(labyrinth,2)
  for h in 1:height
    for w in 1:width
      c = labyrinth[h,w]
      if c isa Portal
        if c.level > 0 
          print('+')
        else 
          print('-')
        end
      else 
        print(c)
      end
    end 
    print('\n')
  end 
end

# finds the length of the shortest path between two points
function findPath(labyrinth, startingPoint, endPoint)
  currentPositions = Vector()
  push!(currentPositions, (startingPoint, 0))
  costMap = fill(typemax(Int), (size(labyrinth,1), size(labyrinth,2)))
  targetReached = false
  # fills the labyrinth until we reach the target
  while (!isempty(currentPositions)) && (!targetReached)
    newPositions = Vector()
    for ((h,w),steps) in currentPositions
      c = labyrinth[h,w]
      previoussteps = costMap[h,w]
      if iswalkable(c) && (steps < previoussteps)
        costMap[h,w] = steps
        push!(newPositions, ((h+1,w),steps+1))
        push!(newPositions, ((h-1,w),steps+1))
        push!(newPositions, ((h,w+1),steps+1))
        push!(newPositions, ((h,w-1),steps+1))
        if c isa Portal 
          push!(newPositions, (c.destination,steps+1))
        end
        if (h,w) == endPoint
          targetReached = true
        end
      end
    end
    currentPositions = newPositions
  end
  # have we found a path to our target ?
  if targetReached
    (hend,wend) = endPoint
    costMap[hend,wend]
  else
    throw("unable to find path!")
  end
end

# finds the length of the shortest path between the begining and end of the labyrinth
function labyrinthLength(labyrinth)
  (labyrinth, startingPoint, endPoint) = parsePortals(labyrinth)
  #printMap(labyrinth)
  findPath(labyrinth, startingPoint, endPoint)
end

#--------------------------------------------------
# LEVEL

# finds the length of the shortest path between two points
# in a multi level labyrinth where portals can get you one level up or down
function findPathMultilevel(labyrinth, startingPoint, endPoint)
  currentPositions = Vector()
  push!(currentPositions, (startingPoint, 0))
  costMap = Dict()
  targetReached = false
  # fills the labyrinth until we reach the target
  while (!isempty(currentPositions)) && (!targetReached)
    newPositions = Vector()
    for ((h,w,l),steps) in currentPositions
      c = labyrinth[h,w]
      previoussteps = get(costMap,(h,w,l), typemax(Int))
      if iswalkable(c) && (steps < previoussteps)
        costMap[h,w,l] = steps
        push!(newPositions, ((h+1,w,l),steps+1))
        push!(newPositions, ((h-1,w,l),steps+1))
        push!(newPositions, ((h,w+1,l),steps+1))
        push!(newPositions, ((h,w-1,l),steps+1))
        if c isa Portal 
          nextLevel = l + c.level
          if nextLevel >= 0
            (nexth,nextw) = c.destination
            push!(newPositions, ((nexth,nextw,nextLevel),steps+1))
          end
        end
        if (h,w,l) == endPoint
          targetReached = true
        end
      end
    end
    currentPositions = newPositions
  end
  # have we found a path to our target ?
  if targetReached
    costMap[endPoint]
  else
    throw("unable to find path!")
  end
end

# finds the length of the shortest path between the begining and end of the labyrinth
# in a multi level labyrinth where portals can get you one level up or down
function labyrinthLengthLevel(labyrinth)
  (labyrinth, (sh,sw), (eh,ew)) = parsePortals(labyrinth)
  #printMap(labyrinth)
  findPathMultilevel(labyrinth, (sh,sw,0), (eh,ew,0))
end

#--------------------------------------------------
# TEST

println("test 1")
map1 = parseMap("         A           
         A           
  #######.#########  
  #######.........#  
  #######.#######.#  
  #######.#######.#  
  #######.#######.#  
  #####  B    ###.#  
BC...##  C    ###.#  
  ##.##       ###.#  
  ##...DE  F  ###.#  
  #####    G  ###.#  
  #########.#####.#  
DE..#######...###.#  
  #.#########.###.#  
FG..#########.....#  
  ###########.#####  
             Z       
             Z       ")
score1 = labyrinthLength(map1)
println("cost: ", score1, " == 23")

println("test 2")
map2 = parseMap("                   A               
                   A               
  #################.#############  
  #.#...#...................#.#.#  
  #.#.#.###.###.###.#########.#.#  
  #.#.#.......#...#.....#.#.#...#  
  #.#########.###.#####.#.#.###.#  
  #.............#.#.....#.......#  
  ###.###########.###.#####.#.#.#  
  #.....#        A   C    #.#.#.#  
  #######        S   P    #####.#  
  #.#...#                 #......VT
  #.#.#.#                 #.#####  
  #...#.#               YN....#.#  
  #.###.#                 #####.#  
DI....#.#                 #.....#  
  #####.#                 #.###.#  
ZZ......#               QG....#..AS
  ###.###                 #######  
JO..#.#.#                 #.....#  
  #.#.#.#                 ###.#.#  
  #...#..DI             BU....#..LF
  #####.#                 #.#####  
YN......#               VT..#....QG
  #.###.#                 #.###.#  
  #.#...#                 #.....#  
  ###.###    J L     J    #.#.###  
  #.....#    O F     P    #.#...#  
  #.###.#####.#.#####.#####.###.#  
  #...#.#.#...#.....#.....#.#...#  
  #.#####.###.###.#.#.#########.#  
  #...#.#.....#...#.#.#.#.....#.#  
  #.###.#####.###.###.#.#.#######  
  #.#.........#...#.............#  
  #########.###.###.#############  
           B   J   C               
           U   P   P               ")
score2 = labyrinthLength(map2)
println("cost: ", score2, " == 58")

println("test 3")
score3 = labyrinthLengthLevel(map1)
println("cost: ", score3, " == 26")

println("test 4")
map4 = parseMap("             Z L X W       C                 
             Z P Q B       K                 
  ###########.#.#.#.#######.###############  
  #...#.......#.#.......#.#.......#.#.#...#  
  ###.#.#.#.#.#.#.#.###.#.#.#######.#.#.###  
  #.#...#.#.#...#.#.#...#...#...#.#.......#  
  #.###.#######.###.###.#.###.###.#.#######  
  #...#.......#.#...#...#.............#...#  
  #.#########.#######.#.#######.#######.###  
  #...#.#    F       R I       Z    #.#.#.#  
  #.###.#    D       E C       H    #.#.#.#  
  #.#...#                           #...#.#  
  #.###.#                           #.###.#  
  #.#....OA                       WB..#.#..ZH
  #.###.#                           #.#.#.#  
CJ......#                           #.....#  
  #######                           #######  
  #.#....CK                         #......IC
  #.###.#                           #.###.#  
  #.....#                           #...#.#  
  ###.###                           #.#.#.#  
XF....#.#                         RF..#.#.#  
  #####.#                           #######  
  #......CJ                       NM..#...#  
  ###.#.#                           #.###.#  
RE....#.#                           #......RF
  ###.###        X   X       L      #.#.#.#  
  #.....#        F   Q       P      #.#.#.#  
  ###.###########.###.#######.#########.###  
  #.....#...#.....#.......#...#.....#.#...#  
  #####.#.###.#######.#######.###.###.#.#.#  
  #.......#.......#.#.#.#.#...#...#...#.#.#  
  #####.###.#####.#.#.#.#.###.###.#.###.###  
  #.......#.....#.#...#...............#...#  
  #############.#.#.###.###################  
               A O F   N                     
               A A D   M                     ")
score4 = labyrinthLengthLevel(map4)
println("cost: ", score4, " == 396")

#--------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
labyrinth = parseMap(inputStr)

println("problem 1")
cost = labyrinthLength(labyrinth)
println("cost: ", cost)

println("problem 2")
cost = labyrinthLengthLevel(labyrinth)
println("cost: ", cost)
