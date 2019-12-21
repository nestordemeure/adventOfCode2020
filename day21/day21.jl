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

# writable registers
const T = 'T' # temporary register
const J = 'J' # jump register (jumps if true)
# readable registers
const A = 'A' # ground 1 away ?
const B = 'B' # ground 2 away ?
const C = 'C' # ground 3 away ?
const D = 'D' # ground 4 away ?
# run-mode readable registers
const E = 'E' # ground 5 away ?
const F = 'F' # ground 6 away ?
const G = 'G' # ground 7 away ?
const H = 'H' # ground 8 away ?
const I = 'I' # ground 9 away ?

# Y = X && Y
function AND(x,y)
  ['A', 'N', 'D', ' ', x, ' ', y, '\n']
end

# Y = X || Y
function OR(x,y)
  ['O', 'R', ' ', x, ' ', y, '\n']
end

# Y = -X
function NOT(x,y)
  ['N', 'O', 'T', ' ', x, ' ', y, '\n']
end

# Y = X
function GET(x,y)
  vcat(NOT(x,y), NOT(y,y))
end

# end with this command in default mode
const WALK = ['W', 'A', 'L', 'K', '\n']

# end with this command to get further sensors
const RUN = ['R', 'U', 'N', '\n']

# takes a list of instructions and produces an ascii input
# use the RUN() mode to unlock the corresponding instructions
function inputOfInstructions(instructions, mode = WALK)
  if (length(instructions) > 15) throw("you have too many instructions!") end
  result = Vector()
  for instruction in instructions
    for c in instruction
      n = convert(BigInt, c)
      push!(result, c)
    end
  end
  for c in mode
    n = convert(BigInt, c)
    push!(result, c)
  end
  result
end

# runs the springDroid and either prints the result of a failure
# ends with the RUN mode to unlock the corresponding instructions
function runSpringDroid(program, instructions, mode = WALK)
  inputs = inputOfInstructions(instructions, mode)
  (program, outputs) = interpret(program, inputs)
  # print situtation
  for n in outputs
    try
      c = convert(Char,n)
      print(c)
    catch
      print(n)
    end
  end
end

#---------------------------------------------------------------
# PROBLEM

# asks the spring droid to jump into the nearest hole
dieInstructions = [
  NOT(D,J) # no ground at 4, jump into it
]

# asks the springDroid to jump over size 3 holes but nothing else
jump3 = [
  NOT(A,J), # hole 1 away
  NOT(B,T), # hole 2 away
  AND(T,J), # hole 1and2
  NOT(C,T), # hole 3
  AND(T,J), # hole 1,2and3
  AND(D,J)  # floor 4 away
]

# solution to problem 1
solution1 = [
  NOT(A,J), # hole 1 away
  NOT(C,T), OR(T,J), # or hole 3 away
  AND(D,J),  # and floor 4 away
]

# solution to problem 2
solution2 = [
  # solution 1
  GET(A, J),
  AND(C, J),
  # solution 2
  GET(B, T),
  #AND(D, T),
  OR(E, T),
  AND(T, J),
  # not
  NOT(J, J),
  # solutin 3
  GET(E, T),
  OR(H, T),
  AND(T, J),
  # resuired to jump
  AND(D,J),  # floor 4 away
]

inputStr = read("day21/input.txt", String)
program = programOfString(inputStr)

println("problem1")
runSpringDroid(program, solution1) # 19357761

println("problem2")
runSpringDroid(program, solution2, RUN) # 1142249706

# 1
# #.####
# #.#..#
# #...##
# 2
#     @ X
# #...##.##.#
#   @X
# #.#.#..#

# J1 = (-A || -C) = -(A && C)

# J1+ = -(B && D)
# J2 = J1+ && -E # next J1 will detect but be unable to jump
# J2 = -(B && D) && -E = -( (B && D) || E )

# J = J1 || J2
# J = -(A && C) || -( (B && D) || E )
# J = -( A && C && ( (B && D) || E) )
# J && D

# do not jump if 5 and 8 are hole
# -(-E && -H) = E || H
