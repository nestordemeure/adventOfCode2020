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

# takes a memory and runs the associated program with the given input
function interpret(input, memory)
  memory = copy(memory)
  index = 1
  code = memory[index]
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
        setResult(memory, index, input)
      elseif isInstruction(code, OUTPUT)
        value = getArg(memory, index, 1)
        println("output: ", value)
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
end

#---------------------------------------------------------------------------
# TESTS

println("test1 equal 8")
memory = programOfString("3,9,8,9,10,9,4,9,99,-1,8")
interpret(8, memory) # 1
interpret(9, memory) # 0

println("test2 less than 8")
memory = programOfString("3,9,7,9,10,9,4,9,99,-1,8")
interpret(7, memory) # 1
interpret(8, memory) # 0
interpret(9, memory) # 0

println("test3 equal 8")
memory = programOfString("3,3,1108,-1,8,3,4,3,99")
interpret(8, memory) # 1
interpret(9, memory) # 0

println("test4 less than 8")
memory = programOfString("3,3,1107,-1,8,3,4,3,99")
interpret(7, memory) # 1
interpret(8, memory) # 0
interpret(9, memory) # 0

println("test5 equal 0")
memory = programOfString("3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9")
interpret(0, memory) # 0
interpret(15, memory) # 1

println("test6 equal 0")
memory = programOfString("3,3,1105,-1,9,1101,0,0,12,4,12,99,1")
interpret(0, memory) # 0
interpret(15, memory) # 1

#---------------------------------------------------------------------------
# PROBLEM

memory = programOfString("3,225,1,225,6,6,1100,1,238,225,104,0,1101,9,90,224,1001,224,-99,224,4,224,102,8,223,223,1001,224,6,224,1,223,224,223,1102,26,62,225,1101,11,75,225,1101,90,43,225,2,70,35,224,101,-1716,224,224,4,224,1002,223,8,223,101,4,224,224,1,223,224,223,1101,94,66,225,1102,65,89,225,101,53,144,224,101,-134,224,224,4,224,1002,223,8,223,1001,224,5,224,1,224,223,223,1102,16,32,224,101,-512,224,224,4,224,102,8,223,223,101,5,224,224,1,224,223,223,1001,43,57,224,101,-147,224,224,4,224,102,8,223,223,101,4,224,224,1,223,224,223,1101,36,81,225,1002,39,9,224,1001,224,-99,224,4,224,1002,223,8,223,101,2,224,224,1,223,224,223,1,213,218,224,1001,224,-98,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,102,21,74,224,101,-1869,224,224,4,224,102,8,223,223,1001,224,7,224,1,224,223,223,1101,25,15,225,1101,64,73,225,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,1008,226,677,224,1002,223,2,223,1005,224,329,1001,223,1,223,1007,677,677,224,102,2,223,223,1005,224,344,101,1,223,223,108,226,677,224,102,2,223,223,1006,224,359,101,1,223,223,108,226,226,224,1002,223,2,223,1005,224,374,1001,223,1,223,7,226,226,224,1002,223,2,223,1006,224,389,1001,223,1,223,8,226,677,224,1002,223,2,223,1006,224,404,1001,223,1,223,107,677,677,224,1002,223,2,223,1006,224,419,101,1,223,223,1008,677,677,224,102,2,223,223,1006,224,434,101,1,223,223,1107,226,677,224,102,2,223,223,1005,224,449,1001,223,1,223,107,226,226,224,102,2,223,223,1006,224,464,101,1,223,223,107,226,677,224,102,2,223,223,1005,224,479,1001,223,1,223,8,677,226,224,102,2,223,223,1005,224,494,1001,223,1,223,1108,226,677,224,102,2,223,223,1006,224,509,101,1,223,223,1107,677,226,224,1002,223,2,223,1005,224,524,101,1,223,223,1008,226,226,224,1002,223,2,223,1005,224,539,101,1,223,223,7,226,677,224,1002,223,2,223,1005,224,554,101,1,223,223,1107,677,677,224,1002,223,2,223,1006,224,569,1001,223,1,223,8,226,226,224,1002,223,2,223,1006,224,584,101,1,223,223,1108,677,677,224,102,2,223,223,1005,224,599,101,1,223,223,108,677,677,224,1002,223,2,223,1006,224,614,101,1,223,223,1007,226,226,224,102,2,223,223,1005,224,629,1001,223,1,223,7,677,226,224,1002,223,2,223,1005,224,644,101,1,223,223,1007,226,677,224,102,2,223,223,1005,224,659,1001,223,1,223,1108,677,226,224,102,2,223,223,1006,224,674,101,1,223,223,4,223,99,226")

println("question1")
interpret(1, memory)

println("question2")
interpret(5, memory)

println("Done.")

