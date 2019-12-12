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
    println("WARNING: negativ index : ", index)
    #return 0
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
    #println("RELATIV index: ", argPosition, " code:", argCode, " base:", relativeBase)
    getMemory(memory,argPosition)
  else
    throw("getArg: unknown parameter mode!")
  end
end

# stores the result of an operation
# (under the hypothesis that the last parameter
# will be the index where the result should be stored)
function setResult(memory, relativeBase, codeIndex, result)
  #code = memory[codeIndex]
  #resultIndex = memory[codeIndex + argNumber(code)] + 1 # one based indexing
  #setMemory(memory,resultIndex,result)
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
function interpret(memory, inputs, index = 1, relativeBase = 0, displayOutputs = false, displayInstructions = false)
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
          #println("blocked input, base:", relativeBase, " index:", index)
          return (memory, index, relativeBase, outputs)
        else
          input = popfirst!(inputs)
          setResult(memory, relativeBase, index, input)
          if (displayInstructions) println("input: ", input) end
        end
      elseif isInstruction(code, OUTPUT)
        # TODO problem here !
        #println("try output, base:", relativeBase, " index:", index)
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
# TURTLE

const BLACK = convert(BigInt, 0)
const WHITE = convert(BigInt, 1)

const TURNLEFT = 0
const TURNRIGHT = 1

const UP = (0,1)
const DOWN = (0,-1)
const RIGHT = (1,0)
const LEFT = (-1,0)

# updates the current direction with a turn left or right
function updateDirection(direction, turn)
  if turn == TURNLEFT
    if direction == UP
      return LEFT
    elseif direction == DOWN
      return RIGHT
    elseif direction == RIGHT
      return UP
    else # direction == LEFT
      return DOWN
    end
  else # turn == TURNRIGHT
    if direction == UP
      return RIGHT
    elseif direction == DOWN
      return LEFT
    elseif direction == RIGHT
      return DOWN
    else # direction == LEFT
      return UP
    end
  end
end

# applies a direction to a position
function move((positionX,positionY), (directionX,directionY))
  (positionX+directionX, positionY+directionY)
end

# runs the painting robot and returns the painted panels
function paintingRobot(memory, startingColor=BLACK)
  panels = Dict{Tuple{BigInt,BigInt},BigInt}()
  position = (0,0)
  direction = UP
  index = 1
  relativeBase = 0
  panels[position] = startingColor
  while index != nothing
    currentColor = get(panels, position, BLACK)
    (new_memory,new_index,new_relativeBase,outputs) = interpret(memory, BigInt[currentColor], index, relativeBase, false, false)
    memory = new_memory
    index = new_index
    relativeBase = new_relativeBase
    # paint current position
    color = outputs[1]
    panels[position] = color
    # move robot
    turn = outputs[2]
    direction = updateDirection(direction, turn)
    position = move(position, direction)
  end
  panels
end

function printPanels(panels)
  # gets dimensions of picture
  minx = nothing
  maxx = nothing
  miny = nothing
  maxy = nothing
  for ((x,y),color) in panels
    if color == WHITE
      if ((minx == nothing) || (x < minx)) minx = x end
      if ((maxx == nothing) || (x > maxx)) maxx = x end
      if ((miny == nothing) || (y < miny)) miny = y end
      if ((maxy == nothing) || (y > maxy)) maxy = y end
    end
  end
  # prints picture
  height = maxx - minx
  width = maxy - miny
  for w in 0:width
    for h in 0:height
      x = h + minx
      y = (width-w) + miny
      color = get(panels, (x,y), BLACK)
      if color == BLACK
        print(' ')
      else
        print('█')
      end
    end
    print('\n')
  end
end

#---------------------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
memory = programOfString(inputStr)

#println("problem1")
panels = paintingRobot(memory)
score = length(panels)
println("score: ", score)

println("problem2")
panels = paintingRobot(memory, WHITE)
printPanels(panels)
