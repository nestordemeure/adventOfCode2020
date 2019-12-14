#---------------------------------------------------------------------------
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

#---------------------------------------------------------------------------
# INTERPRETER

# takes an input string and produces a program (as an array of integers)
function programOfString(str)
    map(x -> parse(BigInt,x), split(str, ','))
end

# takes a memory and runs the associated program with the given inputs
# returns (memory, index, outputs) where index==-1 if the program is finished
function interpret(memory, inputs = BigInt[], index = 1, relativeBase = 0, displayOutputs = false, displayInstructions = false)
  memory = copy(memory)
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
          return (memory, index, relativeBase, outputs)
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
  return (memory, nothing, relativeBase, outputs)
end

#---------------------------------------------------------------------------
# LOGIC

# tile id
const EMPTY = 0
const WALL = 1
const BLOCK = 2
const HPADDLE = 3
const BALL = 4

function updateScreen(outputs, screen, score=0)
  for i in 1:3:length(outputs)
    x = outputs[i]
    y = outputs[i+1]
    id = outputs[i+2]
    if (x==-1) && (y==0)
      score = id
    else
      screen[(x,y)] = id 
    end
  end
  score
end

# runs the game and outputs the end screen
function runGame(memory)
  (memory, index, relativeBase, outputs) = interpret(memory)
  screen = Dict()
  updateScreen(outputs, screen)
  screen
end

# counts the number of block tiles on screen
function countBlocks(screen)
  result = 0
  for (_,id) in screen
    if id == BLOCK
      result += 1
    end
  end
  result
end

#---------------------------------------------------------------------------
# JOYSTICK

# Joystick position 
const NEUTRAL = 0
const RIGHT = 1
const LEFT = -1

# puts a quarter in the machine by setting the memory manually
function addQuarter(memory)
  memory = copy(memory)
  memory[1] = 2
  memory
end

# finds the direction in which the joystick should go to follow the ball
function moveJoystick((xball,yball),(xpaddle,ypaddle))
  if (xball > xpaddle)
    return RIGHT
  elseif (xball < xpaddle)
    LEFT
  else 
    NEUTRAL
  end
end

# returns (score,ball,paddle) where 
# - score is the latest score, 
# - ball is the latest position for the ball
# - paddle is the latest position for the paddle
function extractInfo(outputs, score=0, ball=(0,0), paddle=(0,0))
  for i in 1:3:length(outputs)
    x = outputs[i]
    y = outputs[i+1]
    id = outputs[i+2]
    if (x==-1) && (y==0)
      score = id
    elseif id == BALL
      ball = (x,y)
    elseif id == HPADDLE
      paddle = (x,y)
    end
  end
  (score, ball, paddle)
end

# runs the game and wins it
function playGame(memory)
  screen = Dict()
  memory = addQuarter(memory)
  (memory, index, relativeBase, outputs) = interpret(memory)
  (score, ball, paddle) = extractInfo(outputs)
  while !isnothing(index)
    movement = moveJoystick(ball,paddle)
    inputs = BigInt[movement]
    (memory, index, relativeBase, outputs) = interpret(memory, inputs, index, relativeBase)
    (score, ball, paddle) = extractInfo(outputs, score)
  end
  score
end

#---------------------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
memory = programOfString(inputStr)

println("problem1")
screen = runGame(memory)
nbBlocks = countBlocks(screen)
println("nbBlocks:", nbBlocks)

println("problem2")
score = playGame(memory)
println("score:", score)
