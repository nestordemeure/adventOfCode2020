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
# BEAM

# possible return code
const STATIONARY = 0
const PULLED = 1

# runs a coordinate and returns the associated code
function testCoordinate(program,x,y)
  inputs = BigInt[x,y]
  (newProgram,outputs) = interpret(program, inputs)
  outputs[1]
end

# runs the beam on a square of size 50
function testBeam(program, size=50)
  result = 0
  for x in 0:(size-1), y in 0:(size-1)
    println("x:", x, " y:", y)
    result += testCoordinate(program,x,y)
  end
  result
end

# prints the beam on a square
function printBeam(program, size=10)
  for x in 0:size
    for y in 0:size
      c = testCoordinate(program,x,y)
      if c == PULLED
        print('#')
      else 
        print('.')
      end
    end
    print('\n')
  end
end

#---------------------------------------------------------------
# SHIP

# hash a possition to produce a validation code
function hashPosition((x,y))
  x*10000 + y
end

# takes a bottom corner and returns the coordinates of the associated top corner 
# to have a perfect fir for a square of the given size
function topOfBottomCorner((x,y), squaresize=100)
  (x-squaresize+1, y+squaresize-1)
end

# takes a bottom corner and returns the coordinates of the top left corner
# for a square of the given size
function squareOfBottomCorner((x,y), squaresize=100)
  (x-squaresize+1, y)
end

# first corner after which there is always a potential next corner
# found by hand
const startCorner = (3,4)

# givens corners at a given x, finds their coordinate at the next x
function findCornersRay(program, previousX, previousBottomY, previousTopY)
  x = previousX + 1
  # finds bottom
  by = previousBottomY+1
  status = testCoordinate(program,x,by)
  while status != PULLED
    by += 1
    status = testCoordinate(program,x,by)
  end
  # finds top
  ty = max(previousTopY, by)
  status = testCoordinate(program,x,ty+1)
  while status == PULLED
    ty += 1
    status = testCoordinate(program,x,ty+1)
  end
  (x, by, ty)
end

# finds a good first pair of corners to start search
function findStartCorners(program)
  (x,y) = startCorner
  by = ty = y
  while abs(ty - by) < 100
    (x,by,ty) = findCornersRay(program, x, by, ty)
  end
  (x,by,ty)
end

# finds the top left corner of the first size 100 square that fits inside the ray
function findSquare(program)
  (x,bottomCornerY,topCornerY) = findStartCorners(program)
  corners = Set([(x,topCornerY), (x,bottomCornerY)])
  while !in(topOfBottomCorner((x,bottomCornerY)), corners)
    (x,bottomCornerY,topCornerY) = findCornersRay(program, x,bottomCornerY,topCornerY)
    push!(corners, (x,topCornerY))
    push!(corners, (x,bottomCornerY))
  end
  squareOfBottomCorner((x,bottomCornerY))
end

#---------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
program = programOfString(inputStr)
printBeam(program)

println("problem1")
score = testBeam(program)
println("score: ", score)

println("problem2")
position = findSquare(program) # 9791328
println("position: ", position, " -> ", hashPosition(position))

