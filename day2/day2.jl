
# takes an input string and produces a program (as an array of integers)
function programOfString(str)
    map(x -> parse(Int64,x), split(str, ','))
end

# applies an addition opcode
function add(array, indexX, indexY, indexResult)
    array[indexResult+1] = array[indexX+1] + array[indexY+1]
end

# applies a multiplication opcode
function mult(array, indexX, indexY, indexResult)
    array[indexResult+1] = array[indexX+1] * array[indexY+1]
end

# reads the codes one after the other and modifies the array in place
# return true if no problems appended and false otherwise
function applyCodes(codes, currentIndex)
    code = codes[currentIndex]
    if code == 99 # halting code
        true
    else
        indexX = codes[currentIndex + 1]
        indexY = codes[currentIndex + 2]
        indexResult = codes[currentIndex + 3]
        if code == 1 # addition code
            add(codes, indexX, indexY, indexResult)
        elseif code == 2 # multiplication code
            mult(codes, indexX, indexY, indexResult)
        else # illegal code
            return false
        end
        applyCodes(codes, currentIndex+4)
    end
end

# takes a string and outputs the final, ran, program
function runProgram(str)
    codes = programOfString(str)
    sucess = applyCodes(codes, 1)
    if sucess
        codes
    else
        throw("Illegal code!")
    end
end

#------------------------------------------------------------------------------
# TEST

test1 = runProgram("1,0,0,0,99")
test2 = runProgram("2,3,0,3,99")
test3 = runProgram("2,4,4,5,99,0")
test4 = runProgram("1,1,1,4,99,5,6,0,99")

#------------------------------------------------------------------------------
# PROBLEM 1

inputCodes = open("inputs/input.txt") do file
    str = read(file, String)
    programOfString(str)
end

# test a noun/verb pair without modifying the memory
function runInput(noun, verb, memory)
    memory = copy(memory)
    memory[2] = noun
    memory[3] = verb
    sucess = applyCodes(memory, 1)
    if sucess
        memory[1]
    else
        -1
    end
end

result2 = runInput(12, 2, inputCodes)

#------------------------------------------------------------------------------
# PROBLEM 2

# finds the (noun,verb) combinaison that produces the given output
function findNounVerb(target, memory)
    for noun = 0:99
        for verb = 0:99
            if runInput(noun, verb, memory) == targetOutput
                return (noun, verb)
            end
        end
    end
end

targetOutput = 19690720
(noun,verb) = findNounVerb(targetOutput, inputCodes)
code = 100*noun + verb
