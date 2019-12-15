#---------------------------------------------------------------
# INSTRUCTIONS

# list of existing instructions
const STOP = 99
const INPUT = 3
const OUTPUT = 4
const ADD = 1
const MULT = 2
const JUMPTRUE = 5
const JUMPFALSE = 6
const LESS = 7
const EQUAL = 8
const OFFSET = 9

# list of existing parameter modes
const POSITION = 0
const IMMEDIATE = 1
const RELATIVE = 2

# does the given code equal the given instruction
function isInstruction(code, instruction)
  code%100 == instruction
end

# how many inputs does this instruction take
function argNumber(code)
  if isInstruction(code, STOP)
    0
  elseif isInstruction(code, INPUT) || isInstruction(code, OUTPUT) || isInstruction(code, OFFSET)
    1
  elseif isInstruction(code, JUMPTRUE) || isInstruction(code, JUMPFALSE)
    2
  elseif isInstruction(code, ADD)  || isInstruction(code, MULT) ||
         isInstruction(code, LESS) || isInstruction(code, EQUAL)
    3
  else
    throw("argNumber: unknown instruction code!")
  end
end

# safely gets a memory zone
function getMemory(memory, index)
  if index > length(memory)
    previousLength = length(memory)
    resize!(memory, index)
    for i in (previousLength+1):index
      memory[i] = 0
    end
  end
  if index <= 0
    throw("WARNING: negativ index : ", index)
  end
  memory[index]
end

# safely sets a memory zone
function setMemory(memory, index, value)
  if index > length(memory)
    previousLength = length(memory)
    resize!(memory, index)
    for i in (previousLength+1):index
      memory[i] = 0
    end
  end
  memory[index] = value
end

# gets the argument at the given index
# (taking parameter mode into account)
function getArg(memory, relativeBase, codeIndex, argIndex)
  code = memory[codeIndex]
  mode = (code ÷ (10^(argIndex+1))) % 10
  argCode = memory[codeIndex + argIndex]
  if mode == IMMEDIATE
    argCode
  elseif mode == POSITION
    argPosition = argCode+1
    getMemory(memory,argPosition)
  elseif mode == RELATIVE
    argPosition = argCode+1+relativeBase
    getMemory(memory,argPosition)
  else
    throw("getArg: unknown parameter mode!")
  end
end

# stores the result of an operation
# (under the hypothesis that the last parameter
# will be the index where the result should be stored)
function setResult(memory, relativeBase, codeIndex, result)
  code = memory[codeIndex]
  argIndex = argNumber(code)
  mode = (code ÷ (10^(argIndex+1))) % 10
  argCode = memory[codeIndex + argIndex]
  if mode == IMMEDIATE
    throw("setResult: cannot set result in immediate mode!")
  elseif mode == POSITION
    argPosition = argCode+1
    setMemory(memory,argPosition,result)
  elseif mode == RELATIVE
    argPosition = argCode+1+relativeBase
    setMemory(memory,argPosition,result)
  else
    throw("setResult: unknown parameter mode!")
  end
end

#---------------------------------------------------------------
# INTERPRETER

struct Program
  memory
  index
  relativeBase
end

# takes an input string and produces a program (as an array of integers)
function programOfString(str)
    memory = map(x -> parse(BigInt,x), split(str, ','))
    index = 1
    relativeBase = 0
    Program(memory, index, relativeBase)
end

# returns true if a program has finished running
function isFinished(program)
  isnothing(program.index)
end

# takes a program and runs it with the given inputs
# returns (program, outputs) where index==-1 if the program is finished
function interpret(program, inputs = BigInt[], displayOutputs = false, displayInstructions = false)
  memory = copy(program.memory)
  index = program.index
  relativeBase = program.relativeBase
  code = memory[index]
  outputs = BigInt[]
  while !isInstruction(code, STOP)
    # jump instructions
    if isInstruction(code, JUMPTRUE)
      x = getArg(memory, relativeBase, index, 1)
      if x != 0
        index = getArg(memory, relativeBase, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
      if (displayInstructions) println("jump to ", index) end
    elseif isInstruction(code, JUMPFALSE)
      x = getArg(memory, relativeBase, index, 1)
      if x == 0
        index = getArg(memory, relativeBase, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
      if (displayInstructions) println("jump to ", index) end
    else
      # non jump instructions
      if isInstruction(code, INPUT)
        if isempty(inputs)
          return (Program(memory, index, relativeBase), outputs)
        else
          input = popfirst!(inputs)
          setResult(memory, relativeBase, index, input)
          if (displayInstructions) println("input: ", input) end
        end
      elseif isInstruction(code, OUTPUT)
        value = getArg(memory, relativeBase, index, 1)
        push!(outputs, value)
        if (displayOutputs || displayInstructions) println("output: ", value) end
      elseif isInstruction(code, ADD)
        x = getArg(memory, relativeBase, index, 1)
        y = getArg(memory, relativeBase, index, 2)
        setResult(memory, relativeBase, index, x + y)
        if (displayInstructions) println("add ", x, " + ", y) end
      elseif isInstruction(code, MULT)
        x = getArg(memory, relativeBase, index, 1)
        y = getArg(memory, relativeBase, index, 2)
        setResult(memory, relativeBase, index, x * y)
        if (displayInstructions) println("mult ", x, " * ", y) end
      elseif isInstruction(code, LESS)
        x = getArg(memory, relativeBase, index, 1)
        y = getArg(memory, relativeBase, index, 2)
        z = if (x < y) 1 else 0 end
        setResult(memory, relativeBase, index, z)
        if (displayInstructions) println("less ", x, " < ", y) end
      elseif isInstruction(code, EQUAL)
        x = getArg(memory, relativeBase, index, 1)
        y = getArg(memory, relativeBase, index, 2)
        z = if (x == y) 1 else 0 end
        setResult(memory, relativeBase, index, z)
        if (displayInstructions) println("equal ", x, " == ", y) end
      elseif isInstruction(code, OFFSET)
        relativeBase += getArg(memory, relativeBase, index, 1)
        if (displayInstructions) println("offset to ", relativeBase) end
      else
        throw("interpret: unknown code!")
      end
      index += 1 + argNumber(code)
    end
    code = memory[index]
  end
  (Program(memory, nothing, relativeBase), outputs)
end

#---------------------------------------------------------------
# PATH

# status
const WALL = 0
const SPACE = 1
const OXYGEN = 2
const UNKNOWN = 3

# movement
const NORTH = 1
const SOUTH = 2
const EAST = 3
const WEST = 4

# updates a position with a movement
function movePosition((x,y), movement)
  if movement == NORTH
    (x,y+1)
  elseif movement == SOUTH
    (x,y-1)
  elseif movement == EAST
    (x+1,y)
  else # movement == WEST
    (x-1,y)
  end
end

# adds a move to a path
function addMove(path, move)
  path = copy(path)
  push!(path, move)
  path
end

# updates the paths if we have a better path
# returns true is if it better than all known paths
function registerPath(paths, position, path)
  if haskey(paths, position)
    oldPath = paths[position]
    if length(oldPath) <= length(path)
      false
    else
      paths[position] = path
      true
    end
  else
    paths[position] = path
    true
  end
end

# finds a, possibly non optimal, path to an unknown cell that is reachable
# returns nothing if no unknown cell is reachable
function findReachableUnknown(shipMap, startPosition)
  paths = Dict(startPosition => [])
  positions = [startPosition]
  while !isempty(positions)
    newPositions = []
    for position in positions
      path = paths[position]
      for move in [NORTH, SOUTH, EAST, WEST]
        nextPosition = movePosition(position, move)
        nextStatus = get(shipMap, nextPosition, UNKNOWN)
        if nextStatus != WALL
          nextPath = addMove(path, move)
          if nextStatus == UNKNOWN
            return nextPath
          else
            isImprovement = registerPath(paths, nextPosition, nextPath)
            if isImprovement
              push!(newPositions, nextPosition)
            end
          end
        end
      end
    end
    positions = newPositions
  end
  # no more reachable unknown
  nothing
end

# finds the shortest path, that might cross unknown cells, from a position to another
function findPath(shipMap, startPosition, endPosition)
  paths = Dict(startPosition => [])
  positions = [startPosition]
  while !haskey(paths, endPosition) && !isempty(positions)
    newPositions = []
    for position in positions
      path = paths[position]
      for move in [NORTH, SOUTH, EAST, WEST]
        nextPosition = movePosition(position, move)
        if get(shipMap, nextPosition, UNKNOWN) != WALL
          nextPath = addMove(path, move)
          isImprovement = registerPath(paths, nextPosition, nextPath)
          if isImprovement
            push!(newPositions, nextPosition)
          end
        end
      end
    end
    positions = newPositions
  end
  if isempty(positions)
    nothing
  else
    paths[endPosition]
  end
end

# returns all paths from a given position
# WARNING: this will go into an infinite loop if the space is not enclosed
function findAllPath(shipMap, startPosition)
  paths = Dict(startPosition => [])
  positions = [startPosition]
  while !isempty(positions)
    newPositions = []
    for position in positions
      path = paths[position]
      for move in [NORTH, SOUTH, EAST, WEST]
        nextPosition = movePosition(position, move)
        nextStatus = get(shipMap, nextPosition, UNKNOWN)
        if nextStatus != WALL
          nextPath = addMove(path, move)
          isImprovement = registerPath(paths, nextPosition, nextPath)
          if isImprovement
            push!(newPositions, nextPosition)
          end
        end
      end
    end
    positions = newPositions
  end
  paths
end

#---------------------------------------------------------------
# ROBOT

# moves a robot by one step (if possible)
function moveRobot(program, shipMap, position, movement)
  # run robot
  (program, outputs) = interpret(program, BigInt[movement])
  status = outputs[1]
  # updates map
  nextPosition = movePosition(position, movement)
  shipMap[nextPosition] = status
  # return informations
  if status == WALL
    (program, position)
  else
    (program, nextPosition)
  end
end

# produces a map by visiting all reachable UNKNOWN cells
function explore(program)
  shipMap = Dict()
  position = (0,0)
  path = findReachableUnknown(shipMap, position)
  while !isnothing(path)
    for move in path
      (program, newPosition) = moveRobot(program, shipMap, position, move)
      if newPosition == position
        break
      else
        position = newPosition
      end
    end
    path = findReachableUnknown(shipMap, position)
  end
  shipMap
end

# gets the position of the oxygen from the map
function findOxygen(shipMap)
  for (position,status) in shipMap
    if status == OXYGEN
      return position
    end
  end
  throw("no oxygen as detected !")
end

# finds the largest distance from a point to any othe rpoint on the map
function furthestDistance(shipMap, position)
  paths = findAllPath(shipMap, position)
  maxDistance = 0
  for (_,path) in paths
    distance = length(path)
    if distance > maxDistance
      maxDistance = distance
    end
  end
  maxDistance
end

#---------------------------------------------------------------
# PROBLEM

inputStr = read("day15/input.txt", String)
program = programOfString(inputStr)

println("problem1")
shipMap = explore(program)
oxygenPosition = findOxygen(shipMap)
oxygenPath = findPath(shipMap, (0,0), oxygenPosition)
println("optimal path length: ", length(oxygenPath))

println("problem2")
maxDistance = furthestDistance(shipMap, oxygenPosition)
println("time to fill room: ", maxDistance)
