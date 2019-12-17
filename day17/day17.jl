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
  if (isnothing(program.index)) throw("tried to start program at nothing!") end
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
# CAMERA

# elements of the picture
const SCAFOLD = convert(Int,'#')
const SPACE = convert(Int,'.')
const ROBOT_UP = convert(Int,'^')
const ROBOT_DOWN = convert(Int,'v')
const ROBOT_RIGHT = convert(Int,'>')
const ROBOT_LEFT = convert(Int,'<')
const ROBOT_LOST = convert(Int,'X')
const NEWLINE = convert(Int,'\n')

# takes an output and interprets it as a picture
function getPicture(outputs)
  width = findfirst(c -> c == NEWLINE, outputs) - 1
  height = length(outputs) ÷ (width+1)
  picture = zeros(Int, height, width)
  for h in 1:height
    for w in 1:width
      picture[h,w] = outputs[(h-1)*(width+1) + w]
    end
  end
  picture
end

# displays a picture on screen
function displayPicture(picture)
  height = size(picture, 1)
  width= size(picture, 2)
  for h in 1:height
    for w in 1:width
      print(convert(Char, picture[h,w]))
    end
    print('\n')
  end
end

# is the given position an intersection ?
function isIntersection(picture,h,w)
  (picture[h,w] == SCAFOLD) &&
  (picture[h+1,w] == SCAFOLD) &&
  (picture[h-1,w] == SCAFOLD) &&
  (picture[h,w+1] == SCAFOLD) &&
  (picture[h,w-1] == SCAFOLD)
end

# computes the alignement parameter for the given position
function alignementParameter(h,w)
  (h-1) * (w-1)
end

# computes the alignement parameter score for the given picture
function findIntersectionsAlignementParam(picture)
  score = 0
  height = size(picture, 1)
  width= size(picture, 2)
  for h in 2:(height-1)
    for w in 2:(width-1)
      if isIntersection(picture,h,w)
        score += alignementParameter(h,w)
      end
    end
  end
  score
end

#---------------------------------------------------------------
# VACUUM

struct Robot 
  position
  direction
end

# instructions
const COMA = convert(Int,',')
const A = convert(Int,'A')
const B = convert(Int,'B')
const C = convert(Int,'C')
const TURN_LEFT = convert(Int,'L')
const TURN_RIGHT = convert(Int,'R')
const YES = convert(Int,'y')
const NO = convert(Int,'n')

# takes a program and modifies the memory to wake the robot up
function wakeRobot(program)
  program = deepcopy(program)
  program.memory[1] = 2
  program
end

# is a value cell a robot ?
function isRobot(c)
  (c == ROBOT_UP)    ||
  (c == ROBOT_DOWN)  ||
  (c == ROBOT_RIGHT) ||
  (c == ROBOT_LEFT)  ||
  (c == ROBOT_LOST)
end

# finds the robot in the picture
function findRobot(picture)
  picture = copy(picture)
  height = size(picture, 1)
  width= size(picture, 2)
  for h in 1:height
    for w in 1:width
      c = picture[h,w]
      if isRobot(c)
        return Robot((h,w), c)
      end
    end
  end
  throw("unable to find robot!")
end

# gets a cell (illegal coordinates are converted into SPACE)
function getValue(picture, (h,w))
  height = size(picture, 1)
  width= size(picture, 2)
  if (h > height) || (h <= 0) || (w > width) || (w <= 0)
    SPACE
  else
    picture[h,w]
  end
end

# takes a robot and moves it forward
function moveForward(robot)
  (h,w) = robot.position
  position = if robot.direction == ROBOT_UP
    (h-1,w)
  elseif robot.direction == ROBOT_DOWN
    (h+1,w)
  elseif robot.direction == ROBOT_RIGHT 
    (h,w+1)
  elseif robot.direction == ROBOT_LEFT 
    (h,w-1)
  else # robot.direction == ROBOT_LOST
    throw("robot is lost!")
  end
  Robot(position, robot.direction)
end

# takes a robot and changes its orientation to the right
function turnRight(robot)
  direction = if robot.direction == ROBOT_UP
    ROBOT_RIGHT
  elseif robot.direction == ROBOT_DOWN
    ROBOT_LEFT
  elseif robot.direction == ROBOT_RIGHT 
    ROBOT_DOWN
  elseif robot.direction == ROBOT_LEFT 
    ROBOT_UP
  else # robot.direction == ROBOT_LOST
    throw("robot is lost!")
  end
  Robot(robot.position, direction)
end

# takes a robot and changes its orientation to the left
function turnLeft(robot)
  direction = if robot.direction == ROBOT_UP
    ROBOT_LEFT
  elseif robot.direction == ROBOT_DOWN
    ROBOT_RIGHT
  elseif robot.direction == ROBOT_RIGHT 
    ROBOT_UP
  elseif robot.direction == ROBOT_LEFT 
    ROBOT_DOWN
  else # robot.direction == ROBOT_LOST
    throw("robot is lost!")
  end
  Robot(robot.position, direction)
end

# takes a path and fuse the forward moves
function compressPath(path)
  newPath = Vector()
  counter = 0
  for c in path 
    if 0 < c < 10
      counter += c
    else 
      if (counter != 0) push!(newPath, counter) end
      push!(newPath, c)
      counter = 0
    end
  end
  if (counter != 0) push!(newPath, counter) end
  newPath
end

# takes a picture and finds a winning path
function makePath(picture)
  robot = findRobot(picture)
  path = Vector()
  while true 
    robotforward = moveForward(robot)
    if getValue(picture, robotforward.position) == SCAFOLD
      robot = robotforward
      push!(path, 1)
    else
      robotRight = moveForward(turnRight(robot))
      robotLeft = moveForward(turnLeft(robot))
      if getValue(picture, robotRight.position) == SCAFOLD
        robot = robotRight
        push!(path, TURN_RIGHT)
      elseif getValue(picture, robotLeft.position) == SCAFOLD
        robot = robotLeft
        push!(path, TURN_LEFT)
      else 
        break
      end
      push!(path, 1)
    end
  end
  compressPath(path)
end

# print a given path in a human readable format
function printPath(path)
  for c in path 
    if c == TURN_LEFT
      print('L')
    elseif c == TURN_RIGHT
      print('R')
    else 
      print(c)
    end
  end
  print('\n')
end

#---------------------------------------------------------------
# PATTERN

#L10L6R10R6R8R8L6R8L10L6R10L10R8R8L10R6R8R8L6R8L10R8R8L10R6R8R8L6R8L10L6R10L10R8R8L10R6R8R8L6R8

#L10L6R10R6R8R8L6R8L10L6R10L10R8R8L10R6R8R8L6R8L10R8R8L10R6R8R8L6R8L10L6R10L10R8R8L10R6R8R8L6R8

# ABACBCBACB
#A L10L6R10
#B R6R8R8L6R8
#A L10L6R10
#C L10R8R8L10
#B R6R8R8L6R8
#C L10R8R8L10
#B R6R8R8L6R8
#A L10L6R10
#C L10R8R8L10
#B R6R8R8L6R8

# the solution (found by hand)
const seqABC = [A,B,A,C,B,C,B,A,C,B]
const functionA = [TURN_LEFT,10,TURN_LEFT,6,TURN_RIGHT,10]
const functionB = [TURN_RIGHT,6,TURN_RIGHT,8,TURN_RIGHT,8,TURN_LEFT,6,TURN_RIGHT,8]
const functionC = [TURN_LEFT,10,TURN_RIGHT,8,TURN_RIGHT,8,TURN_LEFT,10]
const shouldDisplay = [NO]

# takes an int and returns the corresponding caracter
function charOfInt(n)
  chars = ['1', '2', '3', '4', '5', '6', '7', '8', '9']
  convert(Int, chars[n])
end

# takes some instructions and produces a proper inputs
function formatLine(instruction)
  newInstruction = Vector()
  for c in instruction
    if c == NEWLINE # deal with distance that could also be interpreted as a newline
      push!(newInstruction, charOfInt(5))
      push!(newInstruction, COMA)
      push!(newInstruction, charOfInt(5))
    elseif 0 < c < 10
      push!(newInstruction, charOfInt(c))
    else
      push!(newInstruction, c)
    end
    push!(newInstruction, COMA)
  end
  newInstruction[end] = NEWLINE
  if (length(newInstruction) > 20) throw("instruction sequence is too long !") end
  newInstruction
end

# runs a solution that has been manually found
function runSolution(program)
  program = wakeRobot(program)
  (program, _) = interpret(program)
  (program, _) = interpret(program,formatLine(seqABC))
  (program, _) = interpret(program,formatLine(functionA))
  (program, _) = interpret(program,formatLine(functionB))
  (program, _) = interpret(program,formatLine(functionC))
  (program, outputs) = interpret(program,formatLine(shouldDisplay))
  outputs[end]
end

#---------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
program = programOfString(inputStr)
(_, outputs) = interpret(program)
picture = getPicture(outputs)
displayPicture(picture)

println("problem1")
alignement = findIntersectionsAlignementParam(picture)
println("alignement: ", alignement)

println("problem2")
path = makePath(picture)
printPath(path)
score = runSolution(program)
println("score: ", score)
