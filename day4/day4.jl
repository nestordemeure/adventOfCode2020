minCode = 272091
maxCode = 815432

function setdigit(number, digit, indexDigit)
  number + digit * (10 ^ (6 - indexDigit))
end

function countNumbers(minCode, maxCode)
  # counts number of password that are legal
  function count(hasAdjascent, indexDigit, previousdigit, currentNumber)
    if indexDigit > 6 # we have finished constructing our number
      if hasAdjascent && (currentNumber <= maxCode) && (currentNumber >= minCode)
        # it is a legal password
        1
      else 
        # it is not legal
        0
      end
    else
      # we are still constructing the number
      number = setdigit(currentNumber, previousdigit, indexDigit)
      result = count(hasAdjascent || (indexDigit!=1), indexDigit+1, previousdigit, number)
      for digit in (previousdigit+1):9
        number = setdigit(currentNumber, digit, indexDigit)
        result += count(hasAdjascent, indexDigit+1, digit, number)
      end
      result
    end
  end
  firstDigit = minCode ÷ 100000
  count(false, 1, firstDigit, 0)
end

count = countNumbers(minCode, maxCode)
println("count: ", count)

function countNumbers2(minCode, maxCode)
  # counts number of password that are legal
  function count(hasAdjascent, adjascentLength, indexDigit, previousdigit, currentNumber)
    if indexDigit > 6 # we have finished constructing our number
      hasAdjascent = hasAdjascent || (adjascentLength==1)
      if hasAdjascent && (currentNumber <= maxCode) && (currentNumber >= minCode)
        # it is a legal password
        1
      else 
        # it is not legal
        0
      end
    else
      # we are still constructing the number
      number = setdigit(currentNumber, previousdigit, indexDigit)
      newAdjascentLength = if (indexDigit==1) 0 else (adjascentLength+1) end
      result = count(hasAdjascent, newAdjascentLength, indexDigit+1, previousdigit, number)

      hasAdjascent = hasAdjascent || (adjascentLength==1)
      for digit in (previousdigit+1):9
        number = setdigit(currentNumber, digit, indexDigit)
        result += count(hasAdjascent, 0, indexDigit+1, digit, number)
      end
      result
    end
  end
  firstDigit = minCode ÷ 100000
  count(false, false, 1, firstDigit, 0)
end

count2 = countNumbers2(minCode, maxCode)
println("count2: ", count2)

