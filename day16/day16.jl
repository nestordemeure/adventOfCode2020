using SparseArrays

#------------------------------------------------------------------------
# FFT

# takes a string and produces a signal (array of integers)
function signalOfString(str)
  map(c -> parse(Int,c), collect(str))
end

# gets the last digit of n
function lastdigit(n)
  abs(n) % 10
end

# returns the value of the pattern used when we compute the element at indexElementComputed by, currently, multiplying indexElementMultiplied
function getPattern(indexElementComputed, indexElementMultiplied)
  indexElementComputed = BigInt(indexElementComputed)
  indexElementMultiplied = BigInt(indexElementMultiplied)
  magnitude = (indexElementMultiplied ÷ indexElementComputed) % 2
  signParity = (indexElementMultiplied ÷ (2*indexElementComputed)) % 2
  sign = 1 - 2*signParity
  Int(magnitude * sign)
end

# makes a, sparse, matrix of patterns
function makePatternMatrix(signalLength)
  patternMat = spzeros(Int, signalLength, signalLength)
  for indexElementComputed in 1:signalLength
    indexElementMultiplied = 0
    while indexElementMultiplied <= signalLength
      # 0
      indexElementMultiplied += indexElementComputed
      # 1
      for i in 1:indexElementComputed
        if (indexElementMultiplied > signalLength) break end
        patternMat[indexElementMultiplied, indexElementComputed] = 1
        indexElementMultiplied += 1
      end
      # 0
      indexElementMultiplied += indexElementComputed
      # -1
      for i in 1:indexElementComputed
        if (indexElementMultiplied > signalLength) break end
        patternMat[indexElementMultiplied, indexElementComputed] = -1
        indexElementMultiplied += 1
      end
    end
  end
  patternMat
end

# applies several phase one after the other
function computeSeveralPhases(signal, nbPhases, display=false)
  signal = transpose(signal) # turn signal ito a row vector
  patterns = makePatternMatrix(length(signal))
  for i in 1:nbPhases
    signal = map(lastdigit, signal*patterns)
  end
  signal
end

# displays a signal as a continuous string
function printSignal(signal, endLine=true)
  for c in signal 
    print(c)
  end 
  if (endLine) print('\n') end
end

#------------------------------------------------------------------------
# LARGE MAT

# the ofset is given in the initial signal 
# a value above the midpoint is just the sum of all value from him onward
# a value is its previous value plus the new value of the next value giving us an o(n) algorithm to compute a phase

# gets the offset for a signal
function getOffset(signal)
  result = 0
  for i in 1:7
    result = 10*result + signal[i]
  end 
  result + 1 # adds one for 1 based indexing
end

# repeats a signal a given number of times and offsets it
function offsetSignal(signal, nbRepeat=10000)
  offset = getOffset(signal)
  if offset < length(signal)*(nbRepeat÷2)
    throw("offset is too short for algorithm")
  elseif offset > length(signal)*nbRepeat
    throw("offset is too large for signal")
  end
  signal = repeat(signal, nbRepeat)
  signal[offset:end]
end

# computes one phase using a fast algorithm that works under the assumption
# that we are using a signal offset by a value larger that the midpoint of the signal
function quickPhase(signal)
  newSignal = copy(signal)
  for i in (length(signal)-1):-1:1
    newSignal[i] += newSignal[i+1]
  end
  map(lastdigit, newSignal)
end

# computes sevral quick phases one after the other
function severalquickPhases(signal, nbPhases)
  for i in 1:nbPhases
    signal = quickPhase(signal)
  end
  signal
end

# offsets a signal and runs several phases
function computeOffsetPhases(signal, nbPhases)
  signal = offsetSignal(signal)
  signal = severalquickPhases(signal, nbPhases)
  signal
end

#------------------------------------------------------------------------
# TEST

println("test1")
signal1 = signalOfString("12345678")
finalSignal1 = computeSeveralPhases(signal1, 4, false)
printSignal(finalSignal1, false)
println(" == 01029498")

println("test2")
signal2 = signalOfString("80871224585914546619083218645595")
finalSignal2 = computeSeveralPhases(signal2, 100, false)
printSignal(finalSignal2[1:8], false)
println(" == 24176176")

println("test3")
signal3 = signalOfString("19617804207202209144916044189917")
finalSignal3 = computeSeveralPhases(signal3, 100, false)
printSignal(finalSignal3[1:8], false)
println(" == 73745418")

println("test4")
signal4 = signalOfString("69317163492948606335995924319873")
finalSignal4 = computeSeveralPhases(signal4, 100, false)
printSignal(finalSignal4[1:8], false)
println(" == 52432133")

println("test5")
signal5 = signalOfString("03036732577212944063491565474664")
finalSignal5 = computeOffsetPhases(signal5, 100)
printSignal(finalSignal5[1:8], false)
println(" == 84462026")

println("test6")
signal6 = signalOfString("02935109699940807407585447034323")
finalSignal6 = computeOffsetPhases(signal6, 100)
printSignal(finalSignal6[1:8], false)
println(" == 78725270")

println("test7")
signal7 = signalOfString("03081770884921959731165446850517")
finalSignal7 = computeOffsetPhases(signal7, 100)
printSignal(finalSignal7[1:8], false)
println(" == 53553731")

#------------------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
signal = signalOfString(inputStr)

println("problem1")
finalSignal = computeSeveralPhases(signal, 100, false)
printSignal(finalSignal[1:8])

println("problem2")
finalLargeSignal = computeOffsetPhases(signal, 100)
printSignal(finalLargeSignal[1:8])

