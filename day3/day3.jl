
# modelise a move
struct Move
   direction::Char
   length::Int64
end

# takes a string ("U64") and returns the corresponding move ({U, 64})
function parseMove(move)
   direction = move[1]
   length = parse(Int64, move[2:end])
   Move(direction, length)
end

# takes a string and outputs an array of moves
function parseLine(line)
   moves = split(line, ',')
   map(parseMove, moves)
end

#------------------------------------------------------------------------------
# APPLY MOVE

# goes up from a given position for a given length
# pushes all the steps into a vector
# returns the final position
function moveUp(path, (startX, startY), length)
   for x = (startX+1):(startX+length)
      push!(path, (x, startY))
   end
   (startX + length, startY)
end

# goes down from a given position for a given length
# pushes all the steps into a vector
# returns the final position
function moveDown(path, (startX, startY), length)
   for x = (startX - 1):-1:(startX - length)
      push!(path, (x, startY))
   end
   (startX - length, startY)
end

# goes right from a given position for a given length
# pushes all the steps into a vector
# returns the final position
function moveRight(path, (startX, startY), length)
   for y = (startY+1):(startY+length)
      push!(path, (startX, y))
   end
   (startX, startY + length)
end

# goes left from a given position for a given length
# pushes all the steps into a vector
# returns the final position
function moveLeft(path, (startX, startY), length)
   for y = (startY - 1):-1:(startY - length)
      push!(path, (startX, y))
   end
   (startX, startY - length)
end

# takes an array of moves and returns a vector of coordinates with all the steps in order
# exept for the origin
function developPath(path)
   result = Tuple{Int,Int}[]
   position = (0, 0)
   for move in path
      if move.direction == 'U'
         position = moveUp(result, position, move.length)
      elseif move.direction == 'D'
         position = moveDown(result, position, move.length)
      elseif move.direction == 'R'
         position = moveRight(result, position, move.length)
      elseif move.direction == 'L'
         position = moveLeft(result, position, move.length)
      else
         throw("Unrecognised direction !")
      end
   end
   result
end

#------------------------------------------------------------------------------
# FIND CLOSEST

# manhattan distance to the origin
function manhattanToOrigin((x, y))
   abs(x) + abs(y)
end

# finds the intersection that is closest to the origin for the manhattan distance
function findClosestIntersection(path1, path2)
   intersect!(Set(path1), Set(path2)) |> collect |> # all intersection between both paths
   i -> map(manhattanToOrigin, i) |> minimum # intersection at minimum distance
end

#------------------------------------------------------------------------------
# STEP

# computes the number of steps needed to reach a point following a given path
function computeSteps(path, destination)
   findfirst(x -> x == destination, path)
end

# finds the intersection that is closest to the origin in number of steps
function findStepClosestIntersection(path1, path2)
   intersect!(Set(path1), Set(path2)) |> collect |> # all intersection between both paths
   i -> map(p -> computeSteps(path1, p) + computeSteps(path2, p), i) |> minimum # intersection at minimum distance
end

#------------------------------------------------------------------------------
# TEST

t1l1 = "R8,U5,L5,D3" |> parseLine |> developPath
t1l2 = "U7,R6,D4,L4" |> parseLine |> developPath
t1 = findClosestIntersection(t1l1, t1l2)
s1 = findStepClosestIntersection(t1l1, t1l2)

t2l1 = "R75,D30,R83,U83,L12,D49,R71,U7,L72" |> parseLine |> developPath
t2l2 = "U62,R66,U55,R34,D71,R55,D58,R83" |> parseLine |> developPath
t2 = findClosestIntersection(t2l1, t2l2)
s2 = findStepClosestIntersection(t2l1, t2l2)

t3l1 = "R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51" |> parseLine |> developPath
t3l2 = "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7" |> parseLine |> developPath
t3 = findClosestIntersection(t3l1, t3l2)
s3 = findStepClosestIntersection(t3l1, t3l2)

#------------------------------------------------------------------------------
# PROBLEM

lines = readlines("day3/inputs/input.txt")
path1 = lines[1] |> parseLine |> developPath
path2 = lines[2] |> parseLine |> developPath
intersection = findClosestIntersection(path1, path2)
stepIntersection = findStepClosestIntersection(path1, path2)
