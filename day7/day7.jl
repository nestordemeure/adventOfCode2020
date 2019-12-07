
using Combinatorics

#---------------------------------------------------------------------------
# INSTRUCTIONS

# list of existing instructions
STOP = 99
INPUT = 3
OUTPUT = 4
ADD = 1
MULT = 2
JUMPTRUE = 5
JUMPFALSE = 6
LESS = 7
EQUAL = 8

# list of existing parameter modes
POSITION = 0
IMMEDIATE = 1

# does the given code equal the given instruction
function isInstruction(code, instruction)
  code%100 == instruction
end

# how many inputs does this instruction take
function argNumber(code)
  if isInstruction(code, STOP)
    0
  elseif isInstruction(code, INPUT) || isInstruction(code, OUTPUT)
    1
  elseif isInstruction(code, JUMPTRUE) || isInstruction(code, JUMPFALSE)
    2
  elseif isInstruction(code, ADD)  || isInstruction(code, MULT) ||
         isInstruction(code, LESS) || isInstruction(code, EQUAL)
    3
  else
    throw("unknown instruction code!")
  end
end

# gets the argument at the given index
# (taking parameter mode into account)
function getArg(memory, codeIndex, argIndex)
  code = memory[codeIndex]
  mode = (code ÷ (10^(argIndex+1))) % 10
  argCode = memory[codeIndex + argIndex]
  if mode == IMMEDIATE
    argCode
  elseif mode == POSITION
    argPosition = argCode+1
    memory[argPosition]
  else
    throw("unknown parameter mode!")
  end
end

# stores the result of an operation
# (under the hypothesis that the last parameter
# will be the index where the result should be stored)
function setResult(memory, codeIndex, result)
  code = memory[codeIndex]
  resultIndex = memory[codeIndex + argNumber(code)] + 1 # one based indexing
  memory[resultIndex] = result
end

#---------------------------------------------------------------------------
# INTERPRETER

# takes an input string and produces a program (as an array of integers)
function programOfString(str)
    map(x -> parse(Int64,x), split(str, ','))
end

# takes a memory and runs the associated program with the given inputs
# returns an array of outputs
function interpret(memory, inputs, displayOutputs = false)
  memory = copy(memory)
  index = 1
  code = memory[index]
  outputs = Int[]
  while !isInstruction(code, STOP)
    # jump instructions
    if isInstruction(code, JUMPTRUE)
      x = getArg(memory, index, 1)
      if x != 0
        index = getArg(memory, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
    elseif isInstruction(code, JUMPFALSE)
      x = getArg(memory, index, 1)
      if x == 0
        index = getArg(memory, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
    else
      # non jump instructions
      if isInstruction(code, INPUT)
        input = popfirst!(inputs)
        setResult(memory, index, input)
      elseif isInstruction(code, OUTPUT)
        value = getArg(memory, index, 1)
        push!(outputs, value)
        if (displayOutputs) println("output: ", value) end
      elseif isInstruction(code, ADD)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        setResult(memory, index, x + y)
      elseif isInstruction(code, MULT)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        setResult(memory, index, x * y)
      elseif isInstruction(code, LESS)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        z = if (x < y) 1 else 0 end
        setResult(memory, index, z)
      elseif isInstruction(code, EQUAL)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        z = if (x == y) 1 else 0 end
        setResult(memory, index, z)
      else
        throw("unknown code!")
      end
      index += 1 + argNumber(code)
    end
    code = memory[index]
  end
  outputs
end

# takes an input, runs until we have an output
# outputs nothing if we stopped
function interpretUntil(memory, input, index = 1)
  code = memory[index]
  hasInput = true
  while !isInstruction(code, STOP)
    # jump instructions
    if isInstruction(code, JUMPTRUE)
      x = getArg(memory, index, 1)
      if x != 0
        index = getArg(memory, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
    elseif isInstruction(code, JUMPFALSE)
      x = getArg(memory, index, 1)
      if x == 0
        index = getArg(memory, index, 2) + 1 # one based indexing
      else
        index += 1 + argNumber(code)
      end
    else
      # non jump instructions
      if isInstruction(code, INPUT)
        if hasInput
          setResult(memory, index, input)
          hasInput = false
        else
          return (index, 0)
        end
      elseif isInstruction(code, OUTPUT)
        output = getArg(memory, index, 1)
        index += 1 + argNumber(code)
        return (index, output)
      elseif isInstruction(code, ADD)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        setResult(memory, index, x + y)
      elseif isInstruction(code, MULT)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        setResult(memory, index, x * y)
      elseif isInstruction(code, LESS)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        z = if (x < y) 1 else 0 end
        setResult(memory, index, z)
      elseif isInstruction(code, EQUAL)
        x = getArg(memory, index, 1)
        y = getArg(memory, index, 2)
        z = if (x == y) 1 else 0 end
        setResult(memory, index, z)
      else
        throw("unknown code!")
      end
      index += 1 + argNumber(code)
    end
    code = memory[index]
  end
  (1, nothing)
end

#---------------------------------------------------------------------------
# AMPLIFIER

# runs the amplifiers for a given sequence and returns the corresponding result
function runAmplifier(memory, sequence)
  input = 0
  for ampl in 1:5
    amplSetting = sequence[ampl]
    amplInputs = Int[amplSetting, input]
    outputs = interpret(memory, amplInputs)
    input = outputs[1]
  end
  input
end

function bestSequence(memory)
  initialSequence = Int[0,1,2,3,4]
  bestSequence = copy(initialSequence)
  bestScore = 0
  for sequence in permutations(initialSequence)
    score = runAmplifier(memory, sequence)
    if score > bestScore
      bestScore = score
      bestSequence = copy(sequence)
    end
  end
  (bestSequence, bestScore)
end

function runFeedbackAmplifier(memory, sequence)
  memories = Array{Int}[copy(memory), copy(memory), copy(memory), copy(memory), copy(memory)]
  inputs = zeros(Int, 5)
  indexes = ones(Int, 5)
  # feeds the sequence to each amplifier
  for ampl in 1:5
    (index,output) = interpretUntil(memories[ampl], sequence[ampl])
    nextAmpl = (ampl % 5) + 1
    indexes[ampl] = index
    inputs[nextAmpl] = output
  end
  # feeds their inputs to each amplifier
  ampl = 1
  while true
    println(ampl, " ", inputs[ampl], " ", indexes[ampl])
    (index,output) = interpretUntil(memories[ampl], inputs[ampl], indexes[ampl])
    nextAmpl = (ampl % 5) + 1
    indexes[ampl] = index
    if isnothing(output)
      if ampl == 5
        return inputs[1]
      end
    else
      inputs[nextAmpl] = output
    end
    ampl = nextAmpl
  end
end

function bestFeedbackSequence(memory)
  initialSequence = Int[5,6,7,8,9]
  bestSequence = copy(initialSequence)
  bestScore = -1
  for sequence in permutations(initialSequence)
    score = runFeedbackAmplifier(memory, sequence)
    if score > bestScore
      bestScore = score
      bestSequence = copy(sequence)
    end
  end
  (bestSequence, bestScore)
end

#---------------------------------------------------------------------------
# TESTS

println("test1")
ampl1 = programOfString("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0")
(seq1, res1) = bestSequence(ampl1)

println("test2")
ampl2 = programOfString("3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0")
(seq2, res2) = bestSequence(ampl2)

println("test3")
ampl3 = programOfString("3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0")
(seq3, res3) = bestSequence(ampl3)

println("test4")
ampl4 = programOfString("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5")
(seq4, res4) = bestFeedbackSequence(ampl4)

println("test5")
ampl5 = programOfString("3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10")
(seq5, res5) = bestFeedbackSequence(ampl5)

#---------------------------------------------------------------------------
# PROBLEM

ampl = read("day7/inputs/input.txt", String) |> programOfString

println("question1")
(sequence, result) = bestSequence(ampl)

println("question2")
(sequence2, result2) = bestFeedbackSequence(ampl)

println("Done.")
