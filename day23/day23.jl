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
# NETWORK

function runNetwork(program)
  # initialisation
  nbNodes = 50
  programs = [ deepcopy(program) for _ in 1:nbNodes ]
  inputs = [ fill(n-1, 1) for n in 1:nbNodes]
  # runs the program forever
  while true 
    # runs all program once
    for n in 1:nbNodes
      # loads program
      program = programs[n]
      if !isnothing(program.index)
        # loads input
        input = inputs[n]
        if isempty(input)
          input = [-1]
        end
        # runs program
        (program,output) = interpret(program, input)
        # update program and input
        programs[n] = program
        inputs[n] = Vector()
        # send packets
        for i in 1:3:length(output)
          target = output[i]
          x = output[i+1]
          y = output[i+2]
          if target == 255
            # final packet
            println("y: ", y)
            return y
          else
            # normal packet
            push!(inputs[target+1], x) # converts to base 1
            push!(inputs[target+1], y)
          end
        end
      end
    end
  end
end

# are all the inputs empty ?
function isIddle(inputs)
  for input in inputs 
    if !isempty(input)
      return false
    end
  end
  true
end

function runNetworkNAT(program)
  # initialisation
  nbNodes = 50
  programs = [ deepcopy(program) for _ in 1:nbNodes ]
  inputs = [ fill(n-1, 1) for n in 1:nbNodes]
  # NAT 
  natX = nothing 
  natY = nothing
  previousNatY = nothing
  previouslyIddle = false
  # runs the program forever
  while true 
    # runs all program once
    for n in 1:nbNodes
      # loads program
      program = programs[n]
      if !isnothing(program.index)
        # loads input
        input = inputs[n]
        if isempty(input)
          input = [-1]
        end
        # runs program
        (program,output) = interpret(program, input)
        # update program and input
        programs[n] = program
        inputs[n] = Vector()
        # send packets
        for i in 1:3:length(output)
          target = output[i]
          x = output[i+1]
          y = output[i+2]
          if target == 255
            # send to the NAT
            natX = x 
            natY = y
          else
            # normal packet
            push!(inputs[target+1], x) # converts to base 1
            push!(inputs[target+1], y)
          end
        end
      end
    end
    # check for iddle network 
    iddle = isIddle(inputs)
    if iddle && previouslyIddle
      if isnothing(natX)
        throw("NAT does not have packet!")
      end
      push!(inputs[1], natX)
      push!(inputs[1], natY)
      if natY == previousNatY
        # this y was sent twice
        println("natY: ", natY)
        return natY
      else
        # keeps a memory of the previous y sent
        previousNatY = natY
      end
    end
    previouslyIddle = iddle
  end
end

#---------------------------------------------------------------
# PROBLEM

inputStr = read("day23/input.txt", String)
program = programOfString(inputStr)

println("problem1")
runNetwork(program)

println("problem2")
runNetworkNAT(program)
